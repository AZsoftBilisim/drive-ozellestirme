#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

	InitializingFormWhenCreatingItOnServer();
	
	ConfigureDependentFormElementsOnServer();

	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject,
		Items.List.CommandBar);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure InformationDisplayModeOnChange(Item)
	
	OnChangingDisplayMode();
	
EndProcedure

&AtClient
Procedure SelectionInformationClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	FormParameters.Insert("FormServiceParameters", FormServiceParameters);
	FormParameters.Insert("InformationDisplayMode", InformationDisplayMode);
	
	CallbackDescription = New CallbackDescription("SelectionInformationClickCompletion", ThisObject);
	OpenForm("Catalog.Assets.Form.SetUpChoiceFormFilters", FormParameters,,,,, CallbackDescription);

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	ProcessSelectionOfListLines();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectItems_2(Command)
	
	ProcessSelectionOfListLines();
	
EndProcedure

&AtClient
Procedure CreateGroupFA(Command)
	
	NonCurrentAssetsClient.CreateObjectOfOperationByType(PredefinedValue("Enum.FATypes.GroupFA"));

EndProcedure

&AtClient
Procedure CreateOSNode(Command)
	
	NonCurrentAssetsClient.CreateObjectOfOperationByType(PredefinedValue("Enum.FATypes.Node"));

EndProcedure

&AtClient
Procedure CreateDepreciationComponent(Command)
	
	NonCurrentAssetsClient.CreateObjectOfOperationByType(PredefinedValue("Enum.FATypes.DepreciationComponent"));

EndProcedure

&AtClient
Procedure CreateCapitalInvestment(Command)
	
	NonCurrentAssetsClient.CreateObjectOfOperationByType(PredefinedValue("Enum.FATypes.CapitalExpenditureInLeasedAssets"));

EndProcedure

// IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(
		Command,
		ThisObject,
		Items.List);
	
EndProcedure

// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

#Region Private

&AtServer
Procedure InitializingFormWhenCreatingItOnServer()

	InitializeServiceParametersOfForm();
	
	RestoreFormSettings();
	
	SetDynamicListProperties();
	
	SetListSelections();
	
	FillInSelectionInformation(ThisObject);
	
	SetHeader();

EndProcedure

&AtServer
Procedure RestoreFormSettings()
	
	FormSettings = Common.FormDataSettingsStorageLoad(
		Metadata.Catalogs.Assets.Forms.ChoiceForm2_4.FullName(), "FormSettings");

	InformationDisplayMode = CommonClientServer.StructureProperty(FormSettings, "InformationDisplayMode", "OnDate");
	
EndProcedure

&AtServer
Procedure InitializeServiceParametersOfForm()
	
	NewServiceParametersOfForm = New Structure;
	NewServiceParametersOfForm.Insert("FALocalAccountingIsConductedIndependently", AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently());
	NewServiceParametersOfForm.Insert("RightsSettings", New Structure);
	NewServiceParametersOfForm.Insert("CurDetailsValues", Undefined);
	
	NewServiceParametersOfForm.Insert(
		"UseMultipleCompanies", 
		GetFunctionalOption("UseMultipleCompanies"));

	NewServiceParametersOfForm.Insert(
		"UseBusinessUnits", 
		GetFunctionalOption("UseBusinessUnits"));

	NewServiceParametersOfForm.Insert(
		"UseRMManagement", 
		GetFunctionalOption("UseRMManagement"));

	NewServiceParametersOfForm.Insert(
		"LocalFAAccounting", 
		GetFunctionalOption("LocalFAAccounting"));

	NewServiceParametersOfForm.RightsSettings.Insert(
		"ThereIsRightToRead_LocationOfFA", 
		AccessRight("Read", Metadata.InformationRegisters.FALocation));

	NewServiceParametersOfForm.RightsSettings.Insert(
		"ThereIsRightToRead_OrderOfAccountingOfOSU", 
		AccessRight("Read", Metadata.InformationRegisters.FixedAssetsAccountingProcedureManagementAccounting));

	NewServiceParametersOfForm.RightsSettings.Insert(
		"ThereIsRightToRead_OSBUAccountingProcedure", 
		AccessRight("Read", Metadata.InformationRegisters.AccountingProcedureForOSBU));

	NewServiceParametersOfForm.RightsSettings.Insert(
		"ThereIsRightToRead_FAAccountingProcedure", 
		AccessRight("Read", Metadata.InformationRegisters.FixedAssetsAccountingProcedure));

	NewServiceParametersOfForm.RightsSettings.Insert(
		"ThereIsRightToRead_OSUUDepreciationParameters", 
		AccessRight("Read", Metadata.InformationRegisters.FixedAssetDepreciationParametersManagementAccounting));

	NewServiceParametersOfForm.RightsSettings.Insert(
		"ThereIsRightToRead_OSBUDepreciationParameters", 
		AccessRight("Read", Metadata.InformationRegisters.OSBUDepreciationParameters));

	NewServiceParametersOfForm.RightsSettings.Insert(
		"ThereIsRightToRead_InitialFAInformation", 
		AccessRight("Read", Metadata.InformationRegisters.InitialFixedAssetsInformation));

	NewServiceParametersOfForm.RightsSettings.Insert(
		"ThereIsRightToRead_RentedFA", 
		AccessRight("Read", Metadata.InformationRegisters.LeasedAsset));

	GetChoiceParameters(NewServiceParametersOfForm);

	FormServiceParameters = New FixedStructure(NewServiceParametersOfForm);
	
EndProcedure

&AtServer
Procedure GetChoiceParameters(NewServiceParametersOfForm)
	
	ChoiceParameters = Catalogs.Assets.GetChoiceParameters(Parameters, NewServiceParametersOfForm.RightsSettings);
	
	NewServiceParametersOfForm.Insert("ChoiceParameters", ChoiceParameters);
	
	// Removing custom selections from form parameters
	ListFilter = CommonClientServer.StructureProperty(Parameters, "Filter", New Structure); // Structure
	ItemsToDelete1 = New Array;
	For Each FilterDetails In ListFilter Do
		
		FilterName = Upper(FilterDetails.Key);
		
		If ThisIsCustomizableSelection(FilterName)
			Or Catalogs.Assets.ThisIsSelectionBasedOnInformation(FilterName) Then
				
			ItemsToDelete1.Add(FilterName);

		EndIf; 
		
	EndDo;
	
	For Each TagName In ItemsToDelete1 Do
		Parameters.Filter.Delete(TagName);
	EndDo;
		
EndProcedure

&AtServer
Procedure OnChangingDisplayMode()
	
	FormSettings = New Structure;
	FormSettings.Insert("InformationDisplayMode", InformationDisplayMode);
	
	Common.FormDataSettingsStorageSave(
		Metadata.Catalogs.Assets.Forms.ChoiceForm2_4.FullName(), "FormSettings", FormSettings);
		
	SetDynamicListProperties();
	
	SetListSelections();

	FillInSelectionInformation(ThisObject);
	
	ConfigureDependentFormElementsOnServer("InformationDisplayMode");
		
EndProcedure

&AtServer
Procedure SetDynamicListProperties()

	QueryText = 
	"SELECT
	|	CatalogDataOverridable.Ref AS Ref,
	|	CatalogDataOverridable.DeletionMark AS DeletionMark,
	|	CatalogDataOverridable.Parent AS Parent,
	|	CatalogDataOverridable.IsFolder AS IsFolder,
	|	CatalogDataOverridable.Code AS Code,
	|	CatalogDataOverridable.Description AS Description,
	|	CatalogDataOverridable.OSType AS OSType,
	|	CatalogDataOverridable.AssetID AS AssetID,
	|	CatalogDataOverridable.OSGroup AS OSGroup,
	|	CatalogDataOverridable.FixedAssetsGroupFinancialAccounting AS FixedAssetsGroupFinancialAccounting,
	|	CatalogDataOverridable.CodeByRNCFA AS CodeByRNCFA,
	|	CatalogDataOverridable.CodeByUFADR AS CodeByUFADR,
	|	CatalogDataOverridable.DateOfProduction AS DateOfProduction,
	|	CatalogDataOverridable.DateOfLastEdit AS DateOfLastEdit,
	|	CatalogDataOverridable.ManufaturerNumber AS ManufaturerNumber,
	|	CatalogDataOverridable.Manufacturer_ AS Manufacturer_,
	|	CatalogDataOverridable.Class AS Class,
	|	CatalogDataOverridable.Model AS Model,
	|	CatalogDataOverridable.DescriptionFull AS DescriptionFull,
	|	CatalogDataOverridable.PassportNumber AS PassportNumber,
	|	CatalogDataOverridable.HouseholdObject AS HouseholdObject,
	|	CatalogDataOverridable.Subclass AS Subclass,
	|	CatalogDataOverridable.Placement AS Placement,
	|	CatalogDataOverridable.RMBusinessUnit AS RMBusinessUnit,
	|	CatalogDataOverridable.SerialNumber AS SerialNumber,
	|	CatalogDataOverridable.Status AS Status,
	|	CatalogDataOverridable.ExpenseItem AS ExpenseItem,
	|	CatalogDataOverridable.OperatingBusinessUnit AS OperatingBusinessUnit,
	|	CatalogDataOverridable.PayrollExpensesPostingMethod AS PayrollExpensesPostingMethod,
	|	CatalogDataOverridable.Comment AS Comment,
	|	&LineOfBusiness AS LineOfBusiness,
	|	&DepreciationGroup AS DepreciationGroup,
	|	&BUState AS BUState,
	|	&StateOfTheUU AS StateOfTheUU,
	|	&Organization AS Organization,
	|	&MateriallyResponsiblePerson AS FinanciallyLiablePerson,
	|	&Department AS Department,
	|	&LocationAddress AS LocationAddress,
	|	&FinancialAccountingGroup AS FinancialAccountingGroup,
	|	&UsefulLifeManagementAccounting AS UsefulLifeManagementAccounting,
	|	&UsefulLifeAccounting AS UsefulLifeAccounting,
	|	&UsefulLifeTaxAccounting AS UsefulLifeTaxAccounting,
	|	&ResidualLifetimeMA AS ResidualLifetimeMA,
	|	&ResidualLifetimeAC AS ResidualLifetimeAC,
	|	&ResidualLifetimeTA AS ResidualLifetimeTA,
	|	&VATTaxation AS VATTaxation,
	|	&DateOfRegistrationOfTheRegl AS DateOfRegistrationOfTheRegl,
	|	&DateOfRegistrationOfTheUpr AS DateOfRegistrationOfTheUpr,
	|	&Lessor AS Lessor,
	|	&Leaseholder AS Leaseholder,
	|	&Contract AS Contract,
	|	&RealEstate AS RealEstate
	|
	|FROM
	|	Catalog.Assets AS CatalogDataOverridable
	|";
	
	DescriptionOfSelectionRequest = GenerateListProperties();

	For Each FieldDetails In DescriptionOfSelectionRequest.QueryFields Do
		QueryText = StrReplace(QueryText, "&" + FieldDetails.Key, FieldDetails.Value);
	EndDo;
	
	If ValueIsFilled(DescriptionOfSelectionRequest.JoinText) Then
		QueryText = QueryText + Chars.LF + DescriptionOfSelectionRequest.JoinText;
	EndIf;
	
	If ValueIsFilled(DescriptionOfSelectionRequest.TextSelections) Then
		QueryText = QueryText + Chars.LF + DescriptionOfSelectionRequest.TextSelections;
	EndIf;

	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.QueryText = QueryText;
	Common.SetDynamicListProperties(Items.List, ListProperties);
	
	For Each ParameterDetails In DescriptionOfSelectionRequest.QueryOptions Do
		List.Parameters.SetParameterValue(ParameterDetails.Key, ParameterDetails.Value);
	EndDo;

EndProcedure

&AtServer
Function GenerateListProperties()

	ListProperties = New Structure;
	ListProperties.Insert("JoinText", "");
	ListProperties.Insert("TextSelections", "");
	ListProperties.Insert("QueryOptions", New Structure);
	ListProperties.Insert("QueryFields", New Structure);

	ChoiceParameters = FormServiceParameters.ChoiceParameters; // Structure
	
	Get_Information = 
		InformationDisplayMode = "OnDate"
		Or InformationDisplayMode = "Last";
	
	DescriptionOfSelectionRequest = Catalogs.Assets.DescriptionOfItemSelectionRequest(
		ChoiceParameters, FormServiceParameters.RightsSettings, Get_Information);
	
	NonCurrentAssetsClientServer.CopyStructureProperty(DescriptionOfSelectionRequest, ListProperties, "QueryFields");
	NonCurrentAssetsClientServer.CopyStructureProperty(DescriptionOfSelectionRequest, ListProperties, "QueryOptions");
	
	If Not IsBlankString(DescriptionOfSelectionRequest.TextSelections) Then
		ListProperties.TextSelections = "
		|WHERE
		|" + DescriptionOfSelectionRequest.TextSelections;
	EndIf;

	If InformationDisplayMode = "NotShow" Then
		Return ListProperties;
	EndIf;
	
	If ChoiceParameters.Property("DateOfLastEdit") Then
		DateOfLastEdit = EndOfDay(ChoiceParameters.DateOfLastEdit);
	Else
		DateOfLastEdit = EndOfDay(CurrentSessionDate());
	EndIf;
		
	ListFilter = Common.CopyRecursive(ChoiceParameters.Filter); // Structure
		
	#Region Joins
	
	If DescriptionOfSelectionRequest.RequiredTables.Property("FALocation") Then
		
		ListProperties.JoinText = ListProperties.JoinText + "
		|		LEFT JOIN InformationRegister.FALocation.SliceLast(
		|			&PARAMETERS_AFTERLAST_Period,
		|			&Parameters_SliceOfLAST_CONDITIONS) AS FALocation
		|		ON FALocation.FixedAsset = CatalogDataOverridable.Ref";
		
	EndIf;
	
	If DescriptionOfSelectionRequest.RequiredTables.Property("InitialFixedAssetsInformation") Then
		
		ListProperties.JoinText = ListProperties.JoinText + "
		|		LEFT JOIN InformationRegister.InitialFixedAssetsInformation.SliceLast(
		|			&PARAMETERS_AFTERLAST_Period,
		|			&PARAMETERS_LAST_CorrectionDate
		|				AND &Parameters_SliceOfLAST_CONDITIONS) AS InitialFixedAssetsInformation
		|		ON InitialFixedAssetsInformation.Organization = FALocation.Organization
		|			AND InitialFixedAssetsInformation.FixedAsset = FALocation.FixedAsset";
		
	EndIf;
	
	If DescriptionOfSelectionRequest.RequiredTables.Property("FixedAssetsAccountingProcedureManagementAccounting") Then
		
		ListProperties.JoinText = ListProperties.JoinText + "
		|		LEFT JOIN InformationRegister.FixedAssetsAccountingProcedureManagementAccounting.SliceLast(
		|			&PARAMETERS_AFTERLAST_Period,
		|			&PARAMETERS_LAST_CorrectionDate
		|				AND &Parameters_SliceOfLAST_CONDITIONS) AS FixedAssetsAccountingProcedureManagementAccounting
		|		ON FixedAssetsAccountingProcedureManagementAccounting.Organization = FALocation.Organization
		|			AND FixedAssetsAccountingProcedureManagementAccounting.FixedAsset = FALocation.FixedAsset";
		
	EndIf;
	
	If DescriptionOfSelectionRequest.RequiredTables.Property("FixedAssetDepreciationParametersManagementAccounting") Then
		
		ListProperties.JoinText = ListProperties.JoinText + "
		|		LEFT JOIN InformationRegister.FixedAssetDepreciationParametersManagementAccounting.SliceLast(
		|			&PARAMETERS_AFTERLAST_Period, 
		|			&PARAMETERS_LAST_CorrectionDate 
		|				AND &Parameters_SliceOfLAST_CONDITIONS) AS FixedAssetDepreciationParametersManagementAccounting
		|		ON FixedAssetDepreciationParametersManagementAccounting.Organization = FALocation.Organization
		|			AND FixedAssetDepreciationParametersManagementAccounting.FixedAsset = FALocation.FixedAsset";
		
	EndIf;
	
	If DescriptionOfSelectionRequest.RequiredTables.Property("OSBUDepreciationParameters") Then
		
		ListProperties.JoinText = ListProperties.JoinText + "
		|		LEFT JOIN InformationRegister.OSBUDepreciationParameters.SliceLast(
		|			&PARAMETERS_AFTERLAST_Period, 
		|			&PARAMETERS_LAST_CorrectionDate
		|				AND &Parameters_SliceOfLAST_CONDITIONS) AS OSBUDepreciationParameters
		|		ON OSBUDepreciationParameters.Organization = FALocation.Organization
		|			AND OSBUDepreciationParameters.FixedAsset = FALocation.FixedAsset";
		
	EndIf;
	
	If DescriptionOfSelectionRequest.RequiredTables.Property("LeasedAsset") Then
		
		ListProperties.JoinText = ListProperties.JoinText + "
		|		LEFT JOIN InformationRegister.LeasedAsset.SliceLast(
		|			&PARAMETERS_AFTERLAST_Period) AS LeasedAsset
		|		ON LeasedAsset.FixedAsset = CatalogDataOverridable.Ref";
		
	EndIf;

	If DescriptionOfSelectionRequest.RequiredTables.Property("AccountingProcedureForOSBU") Then
		
		ListProperties.JoinText = ListProperties.JoinText + "
		|		LEFT JOIN InformationRegister.AccountingProcedureForOSBU.SliceLast(
		|			&PARAMETERS_AFTERLAST_Period,
		|			&PARAMETERS_LAST_CorrectionDate
		|				AND &Parameters_SliceOfLAST_CONDITIONS) AS AccountingProcedureForOSBU
		|		ON AccountingProcedureForOSBU.Organization = FALocation.Organization
		|			AND AccountingProcedureForOSBU.FixedAsset = FALocation.FixedAsset";
		
	EndIf;

	If DescriptionOfSelectionRequest.RequiredTables.Property("FixedAssetsAccountingProcedure") Then
		
		ListProperties.JoinText = ListProperties.JoinText + "
		|		LEFT JOIN InformationRegister.FixedAssetsAccountingProcedure.SliceLast(
		|			&PARAMETERS_AFTERLAST_Period, 
		|			&PARAMETERS_LAST_CorrectionDate
		|				AND &Parameters_SliceOfLAST_CONDITIONS) AS FixedAssetsAccountingProcedure
		|		ON FixedAssetsAccountingProcedure.FixedAsset = CatalogDataOverridable.Ref";
		
	EndIf;
	
	SliceParametersOfLast_Period = "";
	ParametersOfRecent_CorrectionDate = "TRUE";
	ParametersOfSliceOfLast_Conditions = "TRUE";
	SliceParameters_Registration = "TRUE";
	
	If InformationDisplayMode = "OnDate" Then
		
		ParametersOfRecent_CorrectionDate = "CorrectionDate = DATETIME(1,1,1)";

		If ChoiceParameters.Property("DateOfLastEdit") Then
			SliceParametersOfLast_Period = "&DateOfLastEdit";
			ListProperties.QueryOptions.Insert("DateOfLastEdit", DateOfLastEdit);
		EndIf; 
		
		If ChoiceParameters.Property("CurrentRegistrar") Then
			ParametersOfSliceOfLast_Conditions = "Recorder <> &CurrentRegistrar";
			ListProperties.QueryOptions.Insert("CurrentRegistrar", ChoiceParameters.CurrentRegistrar);
		EndIf; 
	
		If ChoiceParameters.Property("ThereAreParametersForCalculatingTransportTax")
				And ChoiceParameters.ThereAreParametersForCalculatingTransportTax
			Or ChoiceParameters.Property("ThereAreParametersForCalculatingLandTax")
				And ChoiceParameters.ThereAreParametersForCalculatingLandTax Then
			
			SliceParameters_Registration = ParametersOfSliceOfLast_Conditions;
			
			If ListFilter.Property("Organization") 
				And ValueIsFilled(ListFilter.Organization) Then
					
				SliceParameters_Registration = 
					SliceParameters_Registration 
					+ ?(SliceParameters_Registration <> "", " And ", "")
					+ "Organization = &Organization";
					
				ListProperties.QueryOptions.Insert("Organization", FormServiceParameters.Filter.Organization);
				
			EndIf; 
			
		EndIf;
	
	EndIf;
	
	ListProperties.JoinText = StrReplace(ListProperties.JoinText, "&PARAMETERS_AFTERLAST_Period", SliceParametersOfLast_Period);
	ListProperties.JoinText = StrReplace(ListProperties.JoinText, "&PARAMETERS_LAST_CorrectionDate", ParametersOfRecent_CorrectionDate);
	ListProperties.JoinText = StrReplace(ListProperties.JoinText, "&Parameters_SliceOfLAST_CONDITIONS", ParametersOfSliceOfLast_Conditions);
	ListProperties.JoinText = StrReplace(ListProperties.JoinText, "&PARAMETERS_LAST_REFERENCES", SliceParameters_Registration);
	
	ListProperties.TextSelections = StrReplace(ListProperties.TextSelections, "&PARAMETERS_AFTERLAST_Period", SliceParametersOfLast_Period);
	ListProperties.TextSelections = StrReplace(ListProperties.TextSelections, "&PARAMETERS_LAST_CorrectionDate", ParametersOfRecent_CorrectionDate);
	ListProperties.TextSelections = StrReplace(ListProperties.TextSelections, "&Parameters_SliceOfLAST_CONDITIONS", ParametersOfSliceOfLast_Conditions);
	ListProperties.TextSelections = StrReplace(ListProperties.TextSelections, "&PARAMETERS_LAST_REFERENCES", SliceParameters_Registration);

	#EndRegion	
		
	Return ListProperties;
	
EndFunction

&AtClient
Procedure ProcessSelectionOfListLines()

	If Items.List.SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	SelectedItems = New Array;
	
	If FormServiceParameters.ChoiceParameters.Property("AttributesThatShouldMatch")
		And ValueIsFilled(FormServiceParameters.ChoiceParameters.AttributesThatShouldMatch)
		And (InformationDisplayMode = "OnDate" Or InformationDisplayMode = "Last") Then
			
		CheckBankingDetails = StrSplit(FormServiceParameters.ChoiceParameters.AttributesThatShouldMatch, ",");
		
	Else
		CheckBankingDetails = New Array;
	EndIf;
	
	For Each RowID In Items.List.SelectedRows Do
		
		RowData = Items.List.RowData(RowID);
		
		If RowData = Undefined Then
			Continue;
		EndIf;
		
		If Not ValueIsFilled(RowData.Ref) 
			Or RowData.DeletionMark
			Or RowData.IsFolder 
				And Items.List.ChoiceFoldersAndItems <> FoldersAndItemsUse.Folders
				And Items.List.ChoiceFoldersAndItems <> FoldersAndItemsUse.FoldersAndItems Then
			Continue;
		EndIf;
		
		If CheckBankingDetails.Count() <> 0 Then
			
			If FormServiceParameters.CurDetailsValues = Undefined Then
				CurDetailsValues = New Structure(FormServiceParameters.ChoiceParameters.AttributesThatShouldMatch);
				FillPropertyValues(CurDetailsValues, RowData);
				NonCurrentAssetsClientServer.SetStructureProperty("CurDetailsValues", CurDetailsValues, FormServiceParameters);
			EndIf; 
			
			If Not CheckSelection(RowData, CheckBankingDetails, FormServiceParameters.CurDetailsValues) Then
				
				If Not ItemsSelected Then
					// Clear the current values so that they are not taken into account when selecting them again.
					NonCurrentAssetsClientServer.SetStructureProperty("CurDetailsValues", Undefined, FormServiceParameters);
				EndIf;
				
				Return;
				
			EndIf;
			
		EndIf;
		
		SelectedItems.Add(RowData.Ref);
		
	EndDo;
	
	If SelectedItems.Count() = 0 Then
		Return;
	EndIf; 
		
	ItemsSelected = True;
	
	If Items.List.MultipleChoice Then
		NotifyChoice(SelectedItems);
	Else
		NotifyChoice(SelectedItems[0]);
	EndIf; 
	
EndProcedure

&AtClient
Function CheckSelection(RowData, CheckBankingDetails, CurDetailsValues)

	WarningText = Undefined;
	LocationDoesNotMatch = False;
	OtherDetailsDoNotMatch = False;
	
	For Each AttributeName In CheckBankingDetails Do
		
		If RowData[AttributeName] <> FormServiceParameters.CurDetailsValues[AttributeName] 
			And (ValueIsFilled(FormServiceParameters.CurDetailsValues[AttributeName])
				Or ValueIsFilled(RowData[AttributeName])) Then
			
			If AttributeName = "Organization"
				Or AttributeName = "ListDepartment" 
				Or AttributeName = "FINANCIALLYLIABLEPERSON" Then
					
				LocationDoesNotMatch = True;
			Else
				OtherDetailsDoNotMatch = True;
			EndIf;
			
		EndIf; 
		
	EndDo; 
	
	If LocationDoesNotMatch Then
		
		If CheckBankingDetails.Find("FINANCIALLYLIABLEPERSON") <> Undefined Then
			WarningText = NStr("vi = 'Cần chọn tài sản cố định được liệt kê trong một doanh nghiệp, bộ phận ';
								|ru = 'Необходимо выбрать основные средства, числящиеся в одной организации, подразделении и МОЛ';
								|en = 'Select fixed assets that are registered with the same company, business unit and financially liable person'; fa = 'Select fixed assets that are registered with the same company, business unit and financially liable person';
								|it = 'È necessario selezionare i Capitali fissi appartenenti alla stessa azienda, lo stesso reparto e la stessa Persona Materialmente Responsabile';
								|pl = 'Należy wybrać podstawowe środki, zapisane w jednej firmie, dziale i na osobę materialnie odpowiedzialną';
								|tr = 'Aynı iş yeri, departman ve sorumlu kişi adına kayıtlı sabit kıymetlerin seçilmesi gerekir'");
		Else
			WarningText = NStr("vi = 'Cần chọn tài sản cố định trong cùng một doanh nghiệp và bộ phận';
								|ru = 'Необходимо выбрать основные средства, числящиеся в одной организации и подразделении';
								|en = 'Select fixed assets that are in the same company, business unit'; fa = 'Select fixed assets that are in the same company, business unit';
								|it = 'È necessario selezionare i capitali fissi appartenenti alla stessa azienda e stesso reparto';
								|pl = 'Należy wybrać środki trwałe, zapisane w jednej firmie i dziale';
								|tr = 'Aynı iş yeri ve departman içinde listelenen sabit kıymetlerin seçilmesi gereklidir'");
		EndIf;
		
	ElsIf OtherDetailsDoNotMatch Then
		WarningText = NStr("vi = 'Cần chọn cùng một tài sản cố định';
							|ru = 'Необходимо выбрать однотипные основные средства';
							|en = 'You must select the same type of fixed assets'; fa = 'You must select the same type of fixed assets';
							|it = 'È necessario selezionare capitali fissi dello stesso tipo';
							|pl = 'Należy wybrać środki trwałe tego samego typu';
							|tr = 'Aynı tip sabit kıymetlerin seçilmesi gereklidir'");
	EndIf;

	If WarningText <> Undefined Then
		ShowMessageBox(, WarningText);
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

&AtServer
Procedure ConfigureDependentFormElementsOnServer(ChangedBankingDetails = "")
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	If UpdateAll Then
	
		If Not FormServiceParameters.LocalFAAccounting Then
			Items.ListStateOfTheUU.Title = NStr("vi = 'Trạng thái';
												|ru = 'Состояние';
												|en = 'State'; fa = 'وضعیت';
												|it = 'Stato';
												|pl = 'State';
												|tr = 'Durum'");
			Items.ListDateOfRegistrationOfTheUpr.Title = NStr("vi = 'Đã tiếp nhận vào kế toán';
																|ru = 'Принято к учету';
																|en = 'Recognized'; fa = 'شناسایی‌شده';
																|it = 'Riconoscimento';
																|pl = 'Przyjęto do ewidencji';
																|tr = 'Mali tablolara alındı'");
		EndIf; 
		
		If Not AccessRight("InteractiveInsert", Metadata.Catalogs.Assets) Then
			Items.CreateFAGroupUnitList.Visible = False;
			Items.ListCreateOSNode.Visible = False;
			Items.ListCreateDepreciationComponent.Visible = False;
			Items.ListCreateCapitalInvestment.Visible = False;
		EndIf;

		If Not FormServiceParameters.ChoiceParameters.Context.Property("UR") Then
			
			Items.ListRMBusinessUnit.Visible = False;
			
		EndIf; 

		//
		If FormServiceParameters.RightsSettings.ThereIsRightToRead_LocationOfFA
			And (FormServiceParameters.RightsSettings.ThereIsRightToRead_OrderOfAccountingOfOSU
				Or FormServiceParameters.RightsSettings.ThereIsRightToRead_OSBUAccountingProcedure
				Or FormServiceParameters.RightsSettings.ThereIsRightToRead_FAAccountingProcedure
				Or FormServiceParameters.RightsSettings.ThereIsRightToRead_OSUUDepreciationParameters
				Or FormServiceParameters.RightsSettings.ThereIsRightToRead_OSBUDepreciationParameters
				Or FormServiceParameters.RightsSettings.ThereIsRightToRead_InitialFAInformation) Then
			
			ListItem = Items.InformationDisplayMode.ChoiceList.FindByValue("OnDate");
	
			If FormServiceParameters.ChoiceParameters.Property("DateOfLastEdit")
				And ValueIsFilled(FormServiceParameters.ChoiceParameters.DateOfLastEdit) Then
			
				ListItem.Presentation = 
					StrTemplate(NStr("vi = 'Vào ngày %1';
									|ru = 'На дату %1';
									|en = 'As of %1'; fa = 'As of %1';
									|it = 'На дату %1';
									|pl = 'As of %1';
									|tr = '%1 tarihinde'"), Format(FormServiceParameters.ChoiceParameters.DateOfLastEdit, "DLF=D;"));
					
			Else
				
				If InformationDisplayMode = "OnDate" Then
					InformationDisplayMode = "Last";
				EndIf;
				
				Items.InformationDisplayMode.ChoiceList.Delete(ListItem);
				
			EndIf;
			 
		Else
			
			InformationDisplayMode = "NotShow";
			Items.InformationDisplayMode.Visible = False;
			
		EndIf;

	EndIf;
	
	If StructureOfChangedProps.Property("InformationDisplayMode")
		Or UpdateAll Then
		
		PropertyValue =
			FormServiceParameters.RightsSettings.ThereIsRightToRead_LocationOfFA 
			And (InformationDisplayMode = "OnDate"
				Or InformationDisplayMode = "Last");
			
		Items.ListOrganization.Visible = PropertyValue;
		Items.ListDepartment.Visible = PropertyValue;
		Items.ListFinanciallyLiablePerson.Visible = PropertyValue;
		
		//
		PropertyValue = 
			NonCurrentAssetsInternal.ThereAreRightsToReadStateOfFA()
			And (InformationDisplayMode = "OnDate"
				Or InformationDisplayMode = "Last");

		Items.ListStateOfTheUU.Visible = PropertyValue;
		Items.ListBUState.Visible = PropertyValue;
		
		//
		PropertyValue =
			FormServiceParameters.RightsSettings.ThereIsRightToRead_InitialFAInformation
			And (InformationDisplayMode = "OnDate"
				Or InformationDisplayMode = "Last");
				
		Items.ListDateOfRegistrationOfTheUpr.Visible = PropertyValue;
		Items.ListDateOfRegistrationOfTheRegl.Visible = PropertyValue;
		
		//
		PropertyValue =
			FormServiceParameters.RightsSettings.ThereIsRightToRead_OSBUAccountingProcedure
			And FormServiceParameters.RightsSettings.ThereIsRightToRead_OrderOfAccountingOfOSU 
			And (InformationDisplayMode = "OnDate"
				Or InformationDisplayMode = "Last");
			
		Items.ResidualLifetimeAC.Visible = PropertyValue;
		Items.ResidualLifetimeTA.Visible = PropertyValue And FormServiceParameters.LocalFAAccounting;
		Items.ResidualLifetimeMA.Visible = PropertyValue;

		//
		PropertyValue =
			FormServiceParameters.LocalFAAccounting 
			And (InformationDisplayMode = "OnDate"
				Or InformationDisplayMode = "Last");
		
		Items.ListDepreciationGroup.Visible = PropertyValue;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectionInformationClickCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined 
		Or TypeOf(Result) <> Type("Structure") Then
		Return;
	EndIf;
	
	WhenSelectionChangesOnServer(Result);
	
EndProcedure

&AtServer
Procedure WhenSelectionChangesOnServer(Val ResultOfSelectionSettings)
	
	For Each FilterElement In ResultOfSelectionSettings Do
		
		NonCurrentAssetsClientServer.SetStructureProperty(
			FilterElement.Key, FilterElement.Value, FormServiceParameters.ChoiceParameters.Filter);
		
	EndDo;

	SetListSelections();

	FillInSelectionInformation(ThisObject);

EndProcedure

&AtServer
Procedure SetListSelections()

	ListFilter = FormServiceParameters.ChoiceParameters.Filter;
	
	For Each FilterElement In ListFilter Do
		
		FilterName = Upper(FilterElement.Key);
		
		If Not ThisIsCustomizableSelection(FilterName)
				And Not Catalogs.Assets.ThisIsSelectionBasedOnInformation(FilterName)
			Or FilterName = Upper("State") Then
			
			Continue;
		EndIf;
	
		FilterValue = FilterElement.Value;
		
		
		If FilterName = Upper("ResidualLifetimeAC")
			Or FilterName = Upper("ResidualLifetimeMA") Then
			
			TypeOfSelectionComparison = DataCompositionComparisonType.LessOrEqual;
			
		ElsIf TypeOf(FilterValue) = Type("Array")
			Or TypeOf(FilterValue) = Type("ValueList") Then
				
			TypeOfSelectionComparison = DataCompositionComparisonType.InList;
			
		Else
			TypeOfSelectionComparison = DataCompositionComparisonType.Equal;
		EndIf;
		
		UseFilter1 =
			ValueIsFilled(FilterValue) 
			And (InformationDisplayMode <> "NotShow"
				Or Not Catalogs.Assets.ThisIsSelectionBasedOnInformation(FilterName));
		
		CommonClientServer.SetDynamicListFilterItem(
			List, FilterName, FilterValue, TypeOfSelectionComparison,, UseFilter1);

	EndDo;
	
	If InformationDisplayMode <> "NotShow"
		And FormServiceParameters.RightsSettings.ThereIsRightToRead_OrderOfAccountingOfOSU 
		And FormServiceParameters.RightsSettings.ThereIsRightToRead_OSBUAccountingProcedure Then
		
		If ListFilter.Property("State") Then
			
			FilterValue = Common.CopyRecursive(ListFilter.State);
			
			List.Parameters.SetParameterValue("State", FilterValue);
			List.Parameters.SetParameterValue("DoNotUseStateSelection", Not ValueIsFilled(FilterValue));
			
		Else			
			
			FilterValue = New Array;
			FilterValue.Add(Enums.FixedAssetsStates.EmptyRef());
			
			List.Parameters.SetParameterValue("State", FilterValue);
			List.Parameters.SetParameterValue("DoNotUseStateSelection", True);
			
		EndIf;
	
	EndIf;

EndProcedure

&AtServerNoContext
Procedure FillInSelectionInformation(Form)
	
	FilterPresentation = New Array;
	
	FormServiceParameters = Form.FormServiceParameters; // Structure
	ListFilter = FormServiceParameters.ChoiceParameters.Filter; // Structure
	
	If ListFilter.Property("Status")
		And ValueIsFilled(ListFilter.Status) Then
		
		FilterValue = StringFunctions.FormattedString(NStr("vi = '<b>Trạng thái:</b>%1';
															|ru = '<b>Статус:</b> %1';
															|en = '<b>Status:</b> %1'; fa = '<b>Status:</b> %1';
															|it = '<b>Статус:</b> %1';
															|pl = '<b>Status:</b> %1';
															|tr = '<b>Durum:</b> %1'"), ListFilter.Status);
		FilterPresentation.Add(FilterValue);
		
	EndIf;
	
	If ListFilter.Property("State")
		And ValueIsFilled(ListFilter.State)
		And Form.InformationDisplayMode <> "NotShow" Then
		
		If FilterPresentation.Count() <> 0 Then
			FilterPresentation.Add("; ");
		EndIf;

		If ListFilter.State.Count() = 1 Then

			FilterValue = StringFunctions.FormattedString(NStr("vi = '<b>Trạng thái:</b> %1';
																|ru = '<b>Состояние:</b> %1';
																|en = '<b>State:</b> %1'; fa = '<b>State:</b> %1';
																|it = '<b>Состояние:</b> %1';
																|pl = '<b>State:</b> %1';
																|tr = '<b>Durum:</b> %1'"), ListFilter.State[0]);
			FilterPresentation.Add(FilterValue);
			
		Else
			
			Recognized_ = False;
			NotRecognized_ = False;
			LeasedOut = False;
			Other = False;
			
			For Each Item In ListFilter.State Do
				
				If Item = Enums.FixedAssetsStates.Recognized_
					Or Item = Enums.FixedAssetsStates.EnteredInOffBalanceAccounting Then
					
					Recognized_ = True;
					
				ElsIf Item = Enums.FixedAssetsStates.TakenOffBooks
					Or Item = Enums.FixedAssetsStates.NotRecognized_ Then
						
					NotRecognized_ = True;
					
				ElsIf Item = Enums.FixedAssetsStates.LeasedOut Then
						
					LeasedOut = True;
				
				Else
					
					Other = True;
					
				EndIf;
				
			EndDo;
			
			If Recognized_
				And Not NotRecognized_
				And Not LeasedOut
				And Not Other Then
				
				FilterValue = StringFunctions.FormattedString(NStr("vi = '<b>Trạng thái:</b> Đã nhận vào kế toán';
																	|ru = '<b>Состояние:</b> Принято к учету';
																	|en = '<b>State:</b> Recognized'; fa = '<b>State:</b> Recognized';
																	|it = '<b>Состояние:</b> Принято к учету';
																	|pl = '<b>State:</b> Recognized';
																	|tr = '<b>Durum:</b> Muhasebeleştirilmiş'"));
				FilterPresentation.Add(FilterValue);
				
			ElsIf NotRecognized_
				And Not Recognized_
				And Not LeasedOut
				And Not Other Then
				
				FilterValue = StringFunctions.FormattedString(NStr("vi = '<b>Trạng thái:</b> Không được tiếp nhận';
																	|ru = '<b>Состояние:</b> Не принято к учету';
																	|en = '<b>State:</b> Not recognized'; fa = '<b>State:</b> Not recognized';
																	|it = '<b>Состояние:</b> Не принято к учету';
																	|pl = '<b>State:</b> Not recognized';
																	|tr = '<b>Durum:</b> Muhasebeleştirilmemiş'"));
				FilterPresentation.Add(FilterValue);
					
			ElsIf LeasedOut
				And Not Recognized_
				And Not NotRecognized_
				And Not Other Then
				
				FilterValue = StringFunctions.FormattedString(NStr("vi = '<b>Trạng thái:</b> Chuyển cho thuê';
																	|ru = '<b>Состояние:</b> Передано в аренду';
																	|en = '<b>State:</b> Leased'; fa = '<b>State:</b> Leased';
																	|it = '<b>Состояние:</b> Передано в аренду';
																	|pl = '<b>State:</b> Leased';
																	|tr = '<b>Durum:</b> Kiraya verildi'"));
				FilterPresentation.Add(FilterValue);
					
			Else
				
				FilterValue = StringFunctions.FormattedString(NStr("vi = '<b>Trạng thái:</b> Trong danh sách';
																	|ru = '<b>Состояние:</b> В списке';
																	|en = '<b>State:</b> In list'; fa = '<b>State:</b> In list';
																	|it = '<b>Состояние:</b> В списке';
																	|pl = '<b>State:</b> In list';
																	|tr = '<b>Durum:</b> Listede'"));
				FilterPresentation.Add(FilterValue);
					
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If Form.InformationDisplayMode <> "NotShow" Then
		AddSelectionPresentation(ListFilter, "Organization", NStr("vi = 'Doanh nghiệp';
																	|ru = 'Организация';
																	|en = 'Company'; fa = 'Company';
																	|it = 'Организация';
																	|pl = 'Organizacja';
																	|tr = 'İş yeri'"), FilterPresentation);
		AddSelectionPresentation(ListFilter, "Department", NStr("vi = 'Bộ phận';
																|ru = 'Подразделение';
																|en = 'Business unit'; fa = 'Business unit';
																|it = 'Подразделение';
																|pl = 'Dział';
																|tr = 'Departman'"), FilterPresentation);
		AddSelectionPresentation(ListFilter, "FINANCIALLYLIABLEPERSON", NStr("vi = 'Chịu trách nhiệm';
																			|ru = 'МОЛ';
																			|en = 'Responsible employee'; fa = 'کارمند مسئول';
																			|it = 'МОЛ';
																			|pl = 'Osoba odpowiedzialna materialnie';
																			|tr = 'MASK'"), FilterPresentation);
	EndIf;

	AddSelectionPresentation(ListFilter, "OSGroup", NStr("vi = 'Nhóm TSCĐ hữu hình';
														|ru = 'Группа ОС';
														|en = 'Fixed assets group'; fa = 'گروه دارایی‌های ثابت';
														|it = 'Группа ОС';
														|pl = 'Grupa środków trwałych';
														|tr = 'Sabit kıymet grubu'"), FilterPresentation);
	
	If Form.InformationDisplayMode <> "NotShow" Then
		AddSelectionPresentation(ListFilter, "DepreciationGroup", NStr("vi = 'Nhóm khấu hao';
																		|ru = 'Амортизационная группа';
																		|en = 'Depreciation group'; fa = 'گروه استهلاک';
																		|it = 'Амортизационная группа';
																		|pl = 'Grupa amortyzacji';
																		|tr = 'Amortisman grubu'"), FilterPresentation);
	EndIf;

	AddSelectionPresentation(ListFilter, "OperatingBusinessUnit", NStr("vi = 'Bộ phận vận hành';
																		|ru = 'Эксплуатирующее подразделение';
																		|en = 'Operating business unit'; fa = 'واحد تجاری بهره‌بردار';
																		|it = 'Эксплуатирующее подразделение';
																		|pl = 'Dział eksploatacyjny';
																		|tr = 'İşlem departmanı'"), FilterPresentation);
	AddSelectionPresentation(ListFilter, "RMBusinessUnit", NStr("vi = 'Bộ phận sửa chữa';
																|ru = 'Ремонтирующее подразделение';
																|en = 'R&M business unit'; fa = 'واحد تجاری تعمیر و نگهداری';
																|it = 'Ремонтирующее подразделение';
																|pl = 'Dział remontowy';
																|tr = 'Onarım departmanı'"), FilterPresentation);
	
	If ListFilter.Property("ResidualLifetimeAC")
		And ListFilter.ResidualLifetimeAC <> 0
		And Form.InformationDisplayMode <> "NotShow" Then
		
		If FilterPresentation.Count() <> 0 Then
			FilterPresentation.Add("; ");
		EndIf;

		PropertyValue = StrTemplate(NStr("vi = 'Không vượt quá %1 tháng';
										|ru = 'Не превышает %1 мес';
										|en = 'Does not exceed %1 month'; fa = 'Does not exceed %1 month';
										|it = 'Не превышает %1 мес';
										|pl = 'Does not exceed %1 month';
										|tr = '%1 ay aşılmıyor'"), ListFilter.ResidualLifetimeAC);
		FilterValue = StringFunctions.FormattedString("<b>%1:</b> %2", NStr("vi = 'Thời hạn sử dụng còn lại (KTDN)';
																			|ru = 'Остаточный СПИ (БУ)';
																			|en = 'Remaining useful life (LA)'; fa = 'عمر مفید باقیمانده (محلی)';
																			|it = 'Остаточный СПИ (БУ)';
																			|pl = 'Remaining useful life (LA)';
																			|tr = 'Kalan İşlevsel Kullanım Süresi (Yerel Muhasebe)'"), PropertyValue);
		
		FilterPresentation.Add(FilterValue);

	EndIf;
		
	If ListFilter.Property("ResidualLifetimeMA")
		And ListFilter.ResidualLifetimeMA <> 0
		And Form.InformationDisplayMode <> "NotShow" Then
		
		If FilterPresentation.Count() <> 0 Then
			FilterPresentation.Add("; ");
		EndIf;

		PropertyValue = StrTemplate(NStr("vi = 'Không vượt quá %1 tháng';
										|ru = 'Не превышает %1 мес';
										|en = 'Does not exceed %1 month'; fa = 'Does not exceed %1 month';
										|it = 'Не превышает %1 мес';
										|pl = 'Does not exceed %1 month';
										|tr = '%1 ay aşılmıyor'"), ListFilter.ResidualLifetimeMA);
		
		If FormServiceParameters.FALocalAccountingIsConductedIndependently Then
			FilterValue = StringFunctions.FormattedString("<b>%1:</b> %2", NStr("vi = 'Thời hạn sử dụng còn lại (KTQT)';
																				|ru = 'Остаточный СПИ (УУ)';
																				|en = 'Remaining useful life (MA)'; fa = 'عمر مفید باقیمانده (مدیریت)';
																				|it = 'Остаточный СПИ (УУ)';
																				|pl = 'Remaining useful life (MA)';
																				|tr = 'Kalan İşlevsel Kullanım Süresi (Yönetim Muhasebesi)'"), PropertyValue);
		Else
			FilterValue = StringFunctions.FormattedString("<b>%1:</b> %2", NStr("vi = 'Thời hạn sử dụng còn lại';
																				|ru = 'Остаточный СПИ';
																				|en = 'Remaining useful life'; fa = 'Remaining useful life';
																				|it = 'Остаточный СПИ';
																				|pl = 'Pozostały okres przydatnego użytkowania';
																				|tr = 'Kalan İşlevsel Kullanım Süresi'"), PropertyValue);
		EndIf;
		
		FilterPresentation.Add(FilterValue);

	EndIf;
		
	If FilterPresentation.Count() <> 0 Then
		Form.SelectionInformation = New FormattedString(FilterPresentation);
	Else
		Form.SelectionInformation = New FormattedString(NStr("vi = 'Chưa thiết lập';
															|ru = 'Не установлен';
															|en = 'Not set'; fa = 'تنظیم نشده';
															|it = 'Не установлен';
															|pl = 'Nie ustawiono';
															|tr = 'Ayarlanmadı'"));
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure AddSelectionPresentation(ListFilter, PropertyName, PropertyPresentation, FilterPresentation)
	
	If ListFilter.Property(PropertyName)
		And ValueIsFilled(ListFilter[PropertyName]) Then
		
		If FilterPresentation.Count() <> 0 Then
			FilterPresentation.Add("; ");
		EndIf;

		If (TypeOf(ListFilter[PropertyName]) = Type("Array")
				Or TypeOf(ListFilter[PropertyName]) = Type("FixedArray")) Then
					
			If ListFilter[PropertyName].Count() = 1 Then
				ValuePresentation = String(ListFilter[PropertyName][0]);
			Else	
				ValuePresentation = NStr("vi = 'Trong danh sách';
										|ru = 'В списке';
										|en = 'In list'; fa = 'در فهرست';
										|it = 'В списке';
										|pl = 'W liście';
										|tr = 'Listede'");
			EndIf;
			
		ElsIf TypeOf(ListFilter[PropertyName]) = Type("ValueList") Then
			
			If ListFilter[PropertyName].Count() = 1 Then
				ValuePresentation = String(ListFilter[PropertyName][0].Value);
			Else	
				ValuePresentation = NStr("vi = 'Trong danh sách';
										|ru = 'В списке';
										|en = 'In list'; fa = 'در فهرست';
										|it = 'В списке';
										|pl = 'W liście';
										|tr = 'Listede'");
			EndIf;
					
		Else
			
			ValuePresentation = String(ListFilter[PropertyName]);
			
		EndIf;
		
		FilterValue = StringFunctions.FormattedString("<b>%1:</b> %2", PropertyPresentation, ValuePresentation);
		
		FilterPresentation.Add(FilterValue);

	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function ThisIsCustomizableSelection(FilterName)

	Result =
		FilterName = Upper("Organization")
		Or FilterName = Upper("Department")
		Or FilterName = Upper("FINANCIALLYLIABLEPERSON")
		Or FilterName = Upper("Status")
		Or FilterName = Upper("OSGroup")
		Or FilterName = Upper("DepreciationGroup")
		Or FilterName = Upper("OperatingBusinessUnit")
		Or FilterName = Upper("RMBusinessUnit")
		Or FilterName = Upper("ResidualLifetimeAC")
		Or FilterName = Upper("ResidualLifetimeMA");
			
	Return Result;
	 	
EndFunction

&AtServer
Procedure SetHeader()

	If ValueIsFilled(Parameters.FormCaption) Then
		
		Title = Parameters.FormCaption;
		
	ElsIf FormServiceParameters.ChoiceParameters.Context.Property("UR") Then
		 
		Title = NStr("vi = 'Tài sản đang vận hành';
					|ru = 'Объекты эксплуатации';
					|en = 'Assets'; fa = 'دارایی‌ها';
					|it = 'Объекты эксплуатации';
					|pl = 'Obiekty eksploatacji';
					|tr = 'İşlem nesneleri'");
		
	ElsIf FormServiceParameters.ChoiceParameters.Property("AccountAsGroupFA")
		And FormServiceParameters.ChoiceParameters.AccountAsGroupFA Then
			
		Title = NStr("vi = 'Tài sản cố định theo nhóm';
					|ru = 'Групповые основные средства';
					|en = 'Group fixed assets'; fa = 'گروه دارایی‌های ثابت';
					|it = 'Групповые основные средства';
					|pl = 'Group fixed assets';
					|tr = 'Grup sabit kıymetleri'");


	EndIf;
	
EndProcedure

#EndRegion
