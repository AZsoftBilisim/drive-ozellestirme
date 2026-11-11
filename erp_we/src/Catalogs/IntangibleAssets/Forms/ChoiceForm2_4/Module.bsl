#Region Variables

&AtClient
Var CurDetailsValues;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	InitializingFormWhenCreatingItOnServer();
	
	ConfigureDependentFormElementsOnServer();
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
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
	OpenForm("Catalog.IntangibleAssets.Form.SetUpChoiceFormFilters", FormParameters,,,,, CallbackDescription);

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
	
	SelectedItems = New Array;
	
	If ValueIsFilled(AttributesThatShouldMatch) Then
		CheckBankingDetails = StrSplit(AttributesThatShouldMatch, ",");
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
			
			If CurDetailsValues = Undefined Then
				CurDetailsValues = New Structure(AttributesThatShouldMatch);
				FillPropertyValues(CurDetailsValues, RowData);
			EndIf; 
			
			If Not CheckSelection(RowData, CheckBankingDetails, CurDetailsValues) Then
				If Not ItemsSelected Then
					// Clear the current values so that they are not taken into account when selecting them again.
					CurDetailsValues = Undefined;
				EndIf;
				Return;
			EndIf;
			
		EndIf;
		
		SelectedItems.Add(RowData.Ref);
		
	EndDo;
	
	If SelectedItems.Count() <> 0 Then
		
		ItemsSelected = True;
		
		If Items.List.MultipleChoice Then
			NotifyChoice(SelectedItems);
		Else
			NotifyChoice(SelectedItems[0]);
		EndIf; 
	EndIf; 
	
EndProcedure

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
Procedure ConfigureDependentFormElementsOnServer(ChangedBankingDetails = "")
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	If UpdateAll Then
	
		If Not FormServiceParameters.FALocalAccountingIsConductedIndependently Then
			Items.StateOfTheUU.Title = NStr("vi = 'Trạng thái';
											|ru = 'Состояние';
											|en = 'State'; fa = 'وضعیت';
											|it = 'Stato';
											|pl = 'State';
											|tr = 'Durum'");
			Items.DateOfRegistrationOfTheUpr.Title = NStr("vi = 'Đã tiếp nhận vào kế toán';
															|ru = 'Принято к учету';
															|en = 'Recognized'; fa = 'شناسایی‌شده';
															|it = 'Riconoscimento';
															|pl = 'Przyjęto do ewidencji';
															|tr = 'Muhasebeleştirildi'");
		EndIf; 
		
		//
		If FormServiceParameters.RightsSettings.ThereIsRightToRead_PlaceOfIARegistration
			And (FormServiceParameters.RightsSettings.ThereIsRightToRead_AccountingProcedureNMAUU
				Or FormServiceParameters.RightsSettings.ThereIsRightToRead_NMABUAccountingProcedure
				Or FormServiceParameters.RightsSettings.ThereIsRightToRead_AccountingProcedureForIA
				Or FormServiceParameters.RightsSettings.ThereIsRightReading_DepreciationParametersNMAUU
				Or FormServiceParameters.RightsSettings.ThereIsRightReading_NMABUDepreciationParameters
				Or FormServiceParameters.RightsSettings.ThereIsRightToRead_InitialInformationIA) Then
			
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
			FormServiceParameters.RightsSettings.ThereIsRightToRead_PlaceOfIARegistration 
			And (InformationDisplayMode = "OnDate"
				Or InformationDisplayMode = "Last");
			
		Items.Organization.Visible = PropertyValue;
		Items.Department.Visible = PropertyValue;
		
		//
		PropertyValue = 
			(FormServiceParameters.RightsSettings.ThereIsRightToRead_AccountingProcedureNMAUU 
				Or FormServiceParameters.RightsSettings.ThereIsRightToRead_NMABUAccountingProcedure)
			And (InformationDisplayMode = "OnDate"
				Or InformationDisplayMode = "Last");

		Items.BUState.Visible = PropertyValue;
		Items.StateOfTheUU.Visible = PropertyValue;
		
		//
		PropertyValue =
			FormServiceParameters.RightsSettings.ThereIsRightToRead_InitialInformationIA
			And (InformationDisplayMode = "OnDate"
				Or InformationDisplayMode = "Last");
				
		Items.DateOfRegistrationOfTheRegl.Visible = PropertyValue;
		Items.DateOfRegistrationOfTheUpr.Visible = PropertyValue;
		
		//
		PropertyValue =
			FormServiceParameters.RightsSettings.ThereIsRightToRead_AccountingProcedureForIA 
			And (InformationDisplayMode = "OnDate"
				Or InformationDisplayMode = "Last");
			
		Items.FinancialAccountingGroup.Visible = PropertyValue;
		Items.LineOfBusiness.Visible = PropertyValue;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure RestoreFormSettings()
	
	FormSettings = Common.FormDataSettingsStorageLoad(
		Metadata.Catalogs.IntangibleAssets.Forms.ChoiceForm2_4.FullName(), "FormSettings");

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
		"LocalFAAccounting", 
		GetFunctionalOption("LocalFAAccounting"));

	NewServiceParametersOfForm.RightsSettings.Insert(
		"ThereIsRightToRead_PlaceOfIARegistration", 
		AccessRight("Read", Metadata.InformationRegisters.IntangibleAssetsRegistrationPlace));

	NewServiceParametersOfForm.RightsSettings.Insert(
		"ThereIsRightToRead_AccountingProcedureNMAUU", 
		AccessRight("Read", Metadata.InformationRegisters.IntangibleAssetsAccountingProcedureManagementAccounting));

	NewServiceParametersOfForm.RightsSettings.Insert(
		"ThereIsRightToRead_NMABUAccountingProcedure", 
		AccessRight("Read", Metadata.InformationRegisters.IABookkeepingProcedureBookkeepingAndTaxAccounting));

	NewServiceParametersOfForm.RightsSettings.Insert(
		"ThereIsRightToRead_AccountingProcedureForIA", 
		AccessRight("Read", Metadata.InformationRegisters.IntangibleAssetsAccountingProcedure));

	NewServiceParametersOfForm.RightsSettings.Insert(
		"ThereIsRightReading_DepreciationParametersNMAUU", 
		AccessRight("Read", Metadata.InformationRegisters.IntangibleAssetAmortizationParametersManagementAccounting));

	NewServiceParametersOfForm.RightsSettings.Insert(
		"ThereIsRightReading_NMABUDepreciationParameters", 
		AccessRight("Read", Metadata.InformationRegisters.IADepreciationParametersBookkeepingAndTaxAccounting));

	NewServiceParametersOfForm.RightsSettings.Insert(
		"ThereIsRightToRead_InitialInformationIA", 
		AccessRight("Read", Metadata.InformationRegisters.InitialIntangibleAssetsInformation));

	GetChoiceParameters(NewServiceParametersOfForm);

	FormServiceParameters = New FixedStructure(NewServiceParametersOfForm);
	
EndProcedure

&AtServer
Procedure GetChoiceParameters(NewServiceParametersOfForm)
	
	ChoiceParameters = Catalogs.IntangibleAssets.GetChoiceParameters(Parameters, NewServiceParametersOfForm.RightsSettings);
	
	NewServiceParametersOfForm.Insert("ChoiceParameters", ChoiceParameters);
	
	// Removing custom selections from form parameters
	ListFilter = CommonClientServer.StructureProperty(Parameters, "Filter", New Structure); // Structure
	ItemsToDelete1 = New Array;
	For Each FilterDetails In ListFilter Do
		
		FilterName = Upper(FilterDetails.Key);
		
		If ThisIsCustomizableSelection(FilterName)
			Or Catalogs.IntangibleAssets.ThisIsSelectionBasedOnInformation(FilterName) Then
				
			ItemsToDelete1.Add(FilterName);

		EndIf; 
		
	EndDo;
	
	For Each TagName In ItemsToDelete1 Do
		Parameters.Filter.Delete(TagName);
	EndDo;
		
EndProcedure

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
		
		If RowData[AttributeName] <> CurDetailsValues[AttributeName] 
			And (ValueIsFilled(CurDetailsValues[AttributeName])
				Or ValueIsFilled(RowData[AttributeName])) Then
			
			If AttributeName = "Organization"
				Or AttributeName = "Department" Then
					
				LocationDoesNotMatch = True;
			Else
				OtherDetailsDoNotMatch = True;
			EndIf;
			
		EndIf; 
		
	EndDo; 
	
	If LocationDoesNotMatch Then
		WarningText = NStr("vi = 'Bạn phải chọn các tài sản trong cùng một doanh nghiệp và đơn vị';
							|ru = 'Необходимо выбрать активы, числящиеся в одной организации и подразделении';
							|en = 'Select assets that are in the same company and business unit'; fa = 'Select assets that are in the same company and business unit';
							|it = 'È necessario selezionare gli attivi appartenenti alla stessa azienda e stesso reparto';
							|pl = 'Należy wybrać aktywa, zapisane w jednej firmie i dziale';
							|tr = 'Aynı iş yeri ve departman içinde listelenen varlıkların seçilmesi gereklidir'");
	ElsIf OtherDetailsDoNotMatch Then
		WarningText = NStr("vi = 'Cần phải chọn cùng loại tài sản';
							|ru = 'Необходимо выбрать однотипные активы';
							|en = 'Select similar assets'; fa = 'Select similar assets';
							|it = 'È necessario selezionare gli attivi dello stesso tipo';
							|pl = 'Należy wybrać aktywy tego samego typu';
							|tr = 'Tek tip varlıkların seçilmesi gereklidir'");
	EndIf;

	If WarningText <> Undefined Then
		ShowMessageBox(, WarningText);
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

&AtServer
Procedure OnChangingDisplayMode()
	
	FormSettings = New Structure;
	FormSettings.Insert("InformationDisplayMode", InformationDisplayMode);
	
	Common.FormDataSettingsStorageSave(
		Metadata.Catalogs.IntangibleAssets.Forms.ChoiceForm2_4.FullName(), "FormSettings", FormSettings);
		
	SetDynamicListProperties();
	
	SetListSelections();

	FillInSelectionInformation(ThisObject);
	
	ConfigureDependentFormElementsOnServer("InformationDisplayMode");
		
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
				And Not Catalogs.IntangibleAssets.ThisIsSelectionBasedOnInformation(FilterName)
			Or FilterName = Upper("State") Then
			
			Continue;
		EndIf;
	
		FilterValue = FilterElement.Value;
		
		If TypeOf(FilterValue) = Type("Array")
			Or TypeOf(FilterValue) = Type("ValueList") Then
				
			TypeOfSelectionComparison = DataCompositionComparisonType.InList;
			
		Else
			TypeOfSelectionComparison = DataCompositionComparisonType.Equal;
		EndIf;
		
		UseFilter1 =
			ValueIsFilled(FilterValue) 
			And (InformationDisplayMode <> "NotShow"
				Or Not Catalogs.IntangibleAssets.ThisIsSelectionBasedOnInformation(FilterName));
		
		CommonClientServer.SetDynamicListFilterItem(
			List, FilterName, FilterValue, TypeOfSelectionComparison,, UseFilter1);

	EndDo;
	
	If InformationDisplayMode <> "NotShow"
		And FormServiceParameters.RightsSettings.ThereIsRightToRead_AccountingProcedureNMAUU 
		And FormServiceParameters.RightsSettings.ThereIsRightToRead_NMABUAccountingProcedure Then
		
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
			Other = False;
			
			For Each Item In ListFilter.State Do
				
				If Item = Enums.IntangibleAssetsStates.PostedInFinancialAccounting
					Or Item = Enums.IntangibleAssetsStates.Received Then
					
					Recognized_ = True;
					
				ElsIf Item = Enums.IntangibleAssetsStates.WrittenOff_
					Or Item = Enums.IntangibleAssetsStates.NotPostedInFinancialAccounting Then
						
					NotRecognized_ = True;
					
				Else
					
					Other = True;
					
				EndIf;
				
			EndDo;
			
			If Recognized_
				And Not NotRecognized_
				And Not Other Then
				
				FilterValue = StringFunctions.FormattedString(NStr("vi = '<b>Trạng thái:</b> Đã nhận vào kế toán';
																	|ru = '<b>Состояние:</b> Принято к учету';
																	|en = '<b>State:</b> Recognized'; fa = '<b>State:</b> Recognized';
																	|it = '<b>Состояние:</b> Принято к учету';
																	|pl = '<b>State:</b> Recognized';
																	|tr = '<b>Durum:</b> Muhasebeleştirildi'"));
				FilterPresentation.Add(FilterValue);
				
			ElsIf NotRecognized_
				And Not Recognized_
				And Not Other Then
				
				FilterValue = StringFunctions.FormattedString(NStr("vi = '<b>Trạng thái:</b> Không được tiếp nhận';
																	|ru = '<b>Состояние:</b> Не принято к учету';
																	|en = '<b>State:</b> Not recognized'; fa = '<b>State:</b> Not recognized';
																	|it = '<b>Состояние:</b> Не принято к учету';
																	|pl = '<b>State:</b> Not recognized';
																	|tr = '<b>Durum:</b> Muhasebeleştirilmedi'"));
				FilterPresentation.Add(FilterValue);
					
			Else
				
				FilterValue = StringFunctions.FormattedString(NStr("vi = '<b>Trạng thái:</b> Trong danh sách';
																	|ru = '<b>Состояние:</b> В списке';
																	|en = '<b>State:</b> In list'; fa = '<b>State:</b> In list';
																	|it = '<b>Состояние:</b> В списке';
																	|pl = '<b>State:</b> In list';
																	|tr = '<b>Durum:</b>  Listede'"));
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
																|it = 'Reparto';
																|pl = 'Dział';
																|tr = 'Departman'"), FilterPresentation);
	EndIf;

	AddSelectionPresentation(ListFilter, "KindOfAccountingObject", NStr("vi = 'Dạng đối tượng';
																		|ru = 'Вид объекта';
																		|en = 'Object kind'; fa = 'نوع شیء';
																		|it = 'Tipo di oggetto';
																		|pl = 'Rodzaj obiektu';
																		|tr = 'Nesne türü'"), FilterPresentation);
	
	If FilterPresentation.Count() <> 0 Then
		Form.SelectionInformation = New FormattedString(FilterPresentation);
	Else
		Form.SelectionInformation = New FormattedString(NStr("vi = 'Chưa thiết lập';
															|ru = 'Не установлен';
															|en = 'Not set'; fa = 'تنظیم نشده';
															|it = 'Не установлен';
															|pl = 'Nie ustawiono';
															|tr = 'Ayarlanmamış'"));
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
		Or FilterName = Upper("KindOfAccountingObject");
			
	Return Result;
	 	
EndFunction

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
	|	CatalogDataOverridable.IntangibleAssetsKind AS IntangibleAssetsKind,
	|	CatalogDataOverridable.KindOfAccountingObject AS KindOfAccountingObject,
	|	CatalogDataOverridable.DepreciationGroup AS DepreciationGroup,
	|	CatalogDataOverridable.DescriptionFull AS DescriptionFull,
	|	&LineOfBusiness AS LineOfBusiness,
	|	&BUState AS BUState,
	|	&StateOfTheUU AS StateOfTheUU,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	&FinancialAccountingGroup AS FinancialAccountingGroup,
	|	&UsefulLifeManagementAccounting AS UsefulLifeManagementAccounting,
	|	&UsefulLifeAccounting AS UsefulLifeAccounting,
	|	&UsefulLifeTaxAccounting AS UsefulLifeTaxAccounting,
	|	&VATTaxation AS VATTaxation,
	|	&DateOfRegistrationOfTheRegl AS DateOfRegistrationOfTheRegl,
	|	&DateOfRegistrationOfTheUpr AS DateOfRegistrationOfTheUpr
	|
	|FROM
	|	Catalog.IntangibleAssets AS CatalogDataOverridable
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
	
	DescriptionOfSelectionRequest = Catalogs.IntangibleAssets.DescriptionOfItemSelectionRequest(
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
		
	#Region Joins
	
	If DescriptionOfSelectionRequest.RequiredTables.Property("IntangibleAssetsRegistrationPlace") Then
		
		ListProperties.JoinText = ListProperties.JoinText + "
		|		LEFT JOIN InformationRegister.IntangibleAssetsRegistrationPlace.SliceLast(
		|			&PARAMETERS_AFTERLAST_Period,
		|			&Parameters_SliceOfLAST_CONDITIONS) AS IntangibleAssetsRegistrationPlace
		|		ON IntangibleAssetsRegistrationPlace.IntangibleAsset = CatalogDataOverridable.Ref"; // @query-part-1
		
	EndIf;
	
	If DescriptionOfSelectionRequest.RequiredTables.Property("InitialIntangibleAssetsInformation") Then
		
		ListProperties.JoinText = ListProperties.JoinText + "
		|		LEFT JOIN InformationRegister.InitialIntangibleAssetsInformation.SliceLast(
		|			&PARAMETERS_AFTERLAST_Period,
		|			&Parameters_SliceOfLAST_CONDITIONS) AS InitialIntangibleAssetsInformation
		|		ON InitialIntangibleAssetsInformation.Organization = IntangibleAssetsRegistrationPlace.Organization
		|			AND InitialIntangibleAssetsInformation.IntangibleAsset = IntangibleAssetsRegistrationPlace.IntangibleAsset"; // @query-part-1
		
	EndIf;
	
	If DescriptionOfSelectionRequest.RequiredTables.Property("IntangibleAssetsAccountingProcedureManagementAccounting") Then
		
		ListProperties.JoinText = ListProperties.JoinText + "
		|		LEFT JOIN InformationRegister.IntangibleAssetsAccountingProcedureManagementAccounting.SliceLast(
		|			&PARAMETERS_AFTERLAST_Period,
		|			&Parameters_SliceOfLAST_CONDITIONS) AS IntangibleAssetsAccountingProcedureManagementAccounting
		|		ON IntangibleAssetsAccountingProcedureManagementAccounting.Organization = IntangibleAssetsRegistrationPlace.Organization
		|			AND IntangibleAssetsAccountingProcedureManagementAccounting.IntangibleAsset = IntangibleAssetsRegistrationPlace.IntangibleAsset"; // @query-part-1
		
	EndIf;
	
	If DescriptionOfSelectionRequest.RequiredTables.Property("IntangibleAssetAmortizationParametersManagementAccounting") Then
		
		ListProperties.JoinText = ListProperties.JoinText + "
		|		LEFT JOIN InformationRegister.IntangibleAssetAmortizationParametersManagementAccounting.SliceLast(
		|			&PARAMETERS_AFTERLAST_Period, 
		|			&Parameters_SliceOfLAST_CONDITIONS) AS IntangibleAssetAmortizationParametersManagementAccounting
		|		ON IntangibleAssetAmortizationParametersManagementAccounting.Organization = IntangibleAssetsRegistrationPlace.Organization
		|			AND IntangibleAssetAmortizationParametersManagementAccounting.IntangibleAsset = IntangibleAssetsRegistrationPlace.IntangibleAsset"; // @query-part-1
		
	EndIf;
	
	If DescriptionOfSelectionRequest.RequiredTables.Property("IADepreciationParametersBookkeepingAndTaxAccounting") Then
		
		ListProperties.JoinText = ListProperties.JoinText + "
		|		LEFT JOIN InformationRegister.IADepreciationParametersBookkeepingAndTaxAccounting.SliceLast(
		|			&PARAMETERS_AFTERLAST_Period, 
		|			&Parameters_SliceOfLAST_CONDITIONS) AS IADepreciationParametersBookkeepingAndTaxAccounting
		|		ON IADepreciationParametersBookkeepingAndTaxAccounting.Organization = IntangibleAssetsRegistrationPlace.Organization
		|			AND IADepreciationParametersBookkeepingAndTaxAccounting.IntangibleAsset = IntangibleAssetsRegistrationPlace.IntangibleAsset"; // @query-part-1
		
	EndIf;
	
	If DescriptionOfSelectionRequest.RequiredTables.Property("IABookkeepingProcedureBookkeepingAndTaxAccounting") Then
		
		ListProperties.JoinText = ListProperties.JoinText + "
		|		LEFT JOIN InformationRegister.IABookkeepingProcedureBookkeepingAndTaxAccounting.SliceLast(
		|			&PARAMETERS_AFTERLAST_Period,
		|			&Parameters_SliceOfLAST_CONDITIONS) AS IABookkeepingProcedureBookkeepingAndTaxAccounting
		|		ON IABookkeepingProcedureBookkeepingAndTaxAccounting.Organization = IntangibleAssetsRegistrationPlace.Organization
		|			AND IABookkeepingProcedureBookkeepingAndTaxAccounting.IntangibleAsset = IntangibleAssetsRegistrationPlace.IntangibleAsset"; // @query-part-1
		
	EndIf;

	If DescriptionOfSelectionRequest.RequiredTables.Property("IntangibleAssetsAccountingProcedure") Then
		
		ListProperties.JoinText = ListProperties.JoinText + "
		|		LEFT JOIN InformationRegister.IntangibleAssetsAccountingProcedure.SliceLast(
		|			&PARAMETERS_AFTERLAST_Period, 
		|			&Parameters_SliceOfLAST_CONDITIONS) AS IntangibleAssetsAccountingProcedure
		|		ON IntangibleAssetsAccountingProcedure.Organization = IntangibleAssetsRegistrationPlace.Organization
		|			AND IntangibleAssetsAccountingProcedure.IntangibleAsset = IntangibleAssetsRegistrationPlace.IntangibleAsset"; // @query-part-1
		 
	EndIf;
	
	SliceParametersOfLast_Period = "";
	ParametersOfSliceOfLast_Conditions = "TRUE";
	
	If InformationDisplayMode = "OnDate" Then
		
		If ChoiceParameters.Property("DateOfLastEdit") Then
			SliceParametersOfLast_Period = "&DateOfLastEdit";
			ListProperties.QueryOptions.Insert("DateOfLastEdit", DateOfLastEdit);
		EndIf; 
		
		If ChoiceParameters.Property("CurrentRegistrar") Then
			ParametersOfSliceOfLast_Conditions = "Recorder <> &CurrentRegistrar";
			ListProperties.QueryOptions.Insert("CurrentRegistrar", ChoiceParameters.CurrentRegistrar);
		EndIf; 
	
	EndIf;
	
	ListProperties.JoinText = StrReplace(ListProperties.JoinText, "&PARAMETERS_AFTERLAST_Period", SliceParametersOfLast_Period);
	ListProperties.JoinText = StrReplace(ListProperties.JoinText, "&Parameters_SliceOfLAST_CONDITIONS", ParametersOfSliceOfLast_Conditions);
	
	ListProperties.TextSelections = StrReplace(ListProperties.TextSelections, "&PARAMETERS_AFTERLAST_Period", SliceParametersOfLast_Period);
	ListProperties.TextSelections = StrReplace(ListProperties.TextSelections, "&Parameters_SliceOfLAST_CONDITIONS", ParametersOfSliceOfLast_Conditions);

	#EndRegion	
		
	Return ListProperties;
	
EndFunction

&AtServer
Procedure SetHeader()

	If ValueIsFilled(Parameters.FormCaption) Then
		
		Title = Parameters.FormCaption;
		
	ElsIf FormServiceParameters.ChoiceParameters.Filter.Property("KindOfAccountingObject") Then
			
		Title = ?(FormServiceParameters.ChoiceParameters.Filter.KindOfAccountingObject = Enums.IntangibleAssetsAccountingItemKinds.IntangibleAsset,
						NStr("vi = 'Tài sản cố định vô hình';
							|ru = 'Нематериальные активы';
							|en = 'Intangible assets'; fa = 'دارایی‌های نامشهود';
							|it = 'Beni immateriali';
							|pl = 'Wartości niematerialne';
							|tr = 'Maddi olmayan varlıklar'"),
						NStr("vi = 'Chi phí nghiên cứu, triển khai';
							|ru = 'Расходы на НИОКР';
							|en = 'R&D expenses'; fa = 'هزینه‌های تحقیق و توسعه';
							|it = 'Spese per Ricerca e Sviluppo';
							|pl = 'Wydatki na R&D';
							|tr = 'AR-GE giderleri'"));
	
	EndIf;
	
EndProcedure

#EndRegion
