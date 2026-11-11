#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	OnReadCreateAtServer();
	ManagingFormOnServer();

	UpdateDate = CurrentSessionDate();

	SetParametersOfAssetList();
	CompositionOfAssets.Parameters.SetParameterValue("CGU", Object.Ref);
	CompositionOfAssets.Parameters.SetParameterValue("Period", EndOfDay(UpdateDate));
	
	UpdateCostOfCGU();
	
	CurrencyMA = Constants.ManagementAccountingCurrency.Get();
	If ValueIsFilled(CurrencyMA) Then
		Items.CostInManagementAccounting.Title = StrTemplate(NStr("vi = 'KTQT(%1)';
																	|ru = 'УУ(%1)';
																	|en = 'MA(%1)'; fa = 'MA(%1)';
																	|it = 'Contabilità Gestionale (%1)';
																	|pl = 'MA(%1)';
																	|tr = 'Yönetim Muhasebesi (%1)'"), Common.ObjectAttributeValue(CurrencyMA, "Description"));
	EndIf;
	
	ACCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Owner);
	If ValueIsFilled(ACCurrency) Then
		Items.CostInAccounting.Title = StrTemplate(NStr("vi = 'KTDN(%1)';
														|ru = 'БУ(%1)';
														|en = 'LA(%1)'; fa = 'LA(%1)';
														|it = 'Contabilità ordinaria (%1)';
														|pl = 'LA(%1)';
														|tr = 'Genel Muhasebe (%1)'"), Common.ObjectAttributeValue(ACCurrency, "Description"));
	EndIf;
	
	Catalogs.CashGeneratingUnits.RestrictListOfOrganizations(Parameters, Object, Items.Owner);
	
	//Creating a new item from the Catalog list Form opened from the document.
	If Object.Ref = Catalogs.CashGeneratingUnits.EmptyRef() 
			And Parameters.FillingValues.Property("Owner")
			And TypeOf(Parameters.FillingValues.Owner) = Type("ValueList")
			And Parameters.FillingValues.Owner.Count() > 0 Then
				// The owner will be the first of the list, the branch organization specified in the document.
				For Each Owner In Parameters.FillingValues.Owner Do
					Object.Owner = Owner.Value;
					Break;
				EndDo;
	EndIf;
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)

	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)

	// StandardSubsystems.Properties
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	// Let's update the list of assets after recording the parameter change document.
	If EventName =     "Write_ChangeFixedAssetFinancialDetails2_4"
		 Or EventName = "Write_ChangeIntangibleAssetFinancialDetails2_4" Then
			Items.CompositionOfAssets.Refresh();
			UpdateCostOfCGU();
	EndIf;

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	OnReadCreateAtServer();
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)

	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties

EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	If Not ValueIsFilled(Object.Description) Then
		WarningText = NStr("vi = 'Chưa điền tên đơn vị tạo tiền.';
							|ru = 'Наименование ЕГДС не заполнено.';
							|en = 'The name of the cash-generating unit is not filled in.'; fa = 'The name of the cash-generating unit is not filled in.';
							|it = 'Denominazione unità generatrice di cassa non compilata.';
							|pl = 'Nazwa jednostki generującej środki pieniężne nie jest wypełniona.';
							|tr = 'NYB ismi doldurulmamış.'");
		CommonClient.MessageToUser(WarningText);
		Cancel = True;
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UpdateDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi

	CompositionOfAssets.Parameters.SetParameterValue("Period", EndOfDay(UpdateDate));
	UpdateCostOfCGU();

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers
// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined,
	StandardProcessing = Undefined)

	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);

EndProcedure

// End StandardSubsystems.Properties

#Region ChangesInCompositionOfCGUObjects

&AtClient
Procedure AddVEGDSAssets(Command)
	CheckEGDSIChangeComposition(True);
EndProcedure

&AtClient
Procedure ExcludeAssetsFromCGU(Command)
	CheckEGDSIChangeComposition(False);
EndProcedure

#EndRegion

#EndRegion

#Region Private
&AtServer
Procedure SetParametersOfAssetList()
	CompositionOfAssets.Parameters.SetParameterValue("CGU", Object.Ref);
	CompositionOfAssets.Parameters.SetParameterValue("Period", EndOfDay(UpdateDate));
	
	CompaniesList = ImpairmentFAServer.GetOrganizationsForImpairment(Object.Owner);
	
	CompositionOfAssets.Parameters.SetParameterValue("CompaniesList", CompaniesList);
	
EndProcedure

&AtServer
Procedure ManagingFormOnServer()
	
	Items.CompositionOfAssetsDateOfInclusionOfVEGDS.Format = "DLF=D;";
	
EndProcedure

// Check the EGD and change the composition.
// 
// Parameters:
//  Add - Boolean - Add
&AtClient
Procedure CheckEGDSIChangeComposition(Add)
	
	If Not ValueIsFilled(Object.Ref) Then
		QueryText = NStr("vi = 'Để thay đổi thành phần tài sản, cần ghi lại đối tượng. Ghi lại?';
						|ru = 'Для изменения состава активов необходимо записать объект. Записать?';
						|en = 'To change assets, save the object. Do you want to save it?'; fa = 'To change assets, save the object. Do you want to save it?';
						|it = 'Per la modifica della composizione degli attivi è necessario registrare l''oggetto. Registrare?';
						|pl = 'Aby zmienić zestaw aktywów należy zapisać obiekt. Zapisać?';
						|tr = 'Varlıkların bileşimini değiştirmek için nesneyi girmelisiniz. Girilsin mi?'");
		
		ContinuingChangesInAssets = New CallbackDescription("WriteEGDSIChangeComposition", ThisObject, Add);
		
		ShowQueryBox(ContinuingChangesInAssets, QueryText, QuestionDialogMode.YesNo);
		Return;
		
	EndIf;
	
	ChangeCompositionOfCGU(Add);
	
EndProcedure

&AtClient
Procedure WriteEGDSIChangeComposition(QuestionResult, Add) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		Write();
		
		If ValueIsFilled(Object.Ref) Then
			ChangeCompositionOfCGU(Add);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeCompositionOfCGU(Add)
	
	If Add Then
		NameOfFormToOpen_  = "Catalog.CashGeneratingUnits.Form.CGUInclusionForm";
	Else
		NameOfFormToOpen_  = "Catalog.CashGeneratingUnits.Form.CGUExclusionForm";
	EndIf;
	
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("Organization", Object.Owner);
	FormOpenParameters.Insert("CGU", Object.Ref);
	OpenForm(NameOfFormToOpen_, FormOpenParameters);
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	UseMultipleCompanies       = GetFunctionalOption("UseMultipleCompanies");
	
	If Not UseMultipleCompanies Then
		If Not ValueIsFilled(Object.Ref) Then // A new element of the directory.
			Object.Owner = SettingsValueCached.GetDefaultOrganization();
		EndIf;
	EndIf;
	
	Items.Owner.Visible = UseMultipleCompanies;
	
	If Object.Ref <> Catalogs.CashGeneratingUnits.EmptyRef() Then
		Items.Owner.ReadOnly = True;
	EndIf;
	
EndProcedure

// StandardSubsystems.Properties
&AtServer
Procedure UpdateAdditionalAttributesItems()

	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);

EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()

	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);

EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)

	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);

EndProcedure

// End StandardSubsystems.Properties

&AtClient
Procedure UpdateCostOfEGDSByClicking(Command)
	PerformanceMonitorClient.TimeMeasurement(
	"Catalog.CashGeneratingUnits.Form.ItemForm.UpdatingSumFields");
	
	UpdateCostOfCGU();
EndProcedure

// Update the cost of the EGDS.
// Fills in information about the cost of all objects from the Unified State Register of Legal Entities on the date of relevance of the information.
&AtServer
Procedure UpdateCostOfCGU()
	
	// If the EGDS has not been recorded yet, there is no point in counting its cost.
	If Not ValueIsFilled(Object.Ref) Then
		CostInAccounting = 0;
		CostInManagementAccounting = 0;
		Return;
	EndIf;
	
	CompaniesList = ImpairmentFAServer.GetOrganizationsForImpairment(Object.Owner);
	
	// Let's calculate the cost of all objects included in the Unified State Register on the date of relevance.
	Query = New Query();
	Query.Text = 
	"////////////////////////////////////////////////////////////////////////////////
	|// Non-current assets included in the CGU for all companies.
	|SELECT
	|	CGUCompositionSliceLast.NonCurrentAsset AS NonCurrentAsset
	|INTO CGUComposition
	|FROM
	|	InformationRegister.CGUComposition.SliceLast(&DateInformationWasUpdated, Organization IN (&CompaniesList)) AS CGUCompositionSliceLast
	|WHERE
	|	CGUCompositionSliceLast.CGU = &CGU
	|
	|INDEX BY
	|	NonCurrentAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|// Non-current assets and their nodes and components.
	|SELECT
	|	CGUComposition.NonCurrentAsset AS NonCurrentAsset,
	|	VALUETYPE(CGUComposition.NonCurrentAsset) AS AssetType
	|INTO ListOfVNAEGDS
	|FROM
	|	CGUComposition AS CGUComposition
	|
	|UNION ALL
	|
	|SELECT
	|	NodesComponents.SubAssetComponent AS NonCurrentAsset,
	|	VALUETYPE(NodesComponents.SubAssetComponent) AS AssetType
	|FROM
	|	InformationRegister.SubAssetsComponentsOfDepreciation.SliceLast(&DateInformationWasUpdated, FixedAsset IN
	|		(SELECT
	|			CGUComposition.NonCurrentAsset AS NonCurrentAsset
	|		FROM
	|			CGUComposition AS CGUComposition)) AS NodesComponents
	|
	|INDEX BY
	|	NonCurrentAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|// The book cost of everything included in the CGU for all companies.
	|// Cost - Depreciation - Impairment.
	|SELECT
	|	SUM(CostOfCGU.CostInManagementAccounting) AS CostInManagementAccounting,
	|	SUM(CostOfCGU.CostInAccounting) AS CostInAccounting
	|FROM
	|	(
	|// Cost.
	|	SELECT
	|		FACost.CostClosingBalance AS CostInManagementAccounting,
	|		FACost.LocalCostClosingBalance + FACost.CostTargetFinancingClosingBalance AS CostInAccounting
	|	FROM
	|		AccumulationRegister.FACost.BalanceAndTurnovers(&DateInformationWasUpdated, &DateInformationWasUpdated, Period,
	|			RegisterRecordsAndPeriodBoundaries, Organization IN (&CompaniesList)
	|		AND FixedAsset IN
	|			(SELECT
	|				ListOfVNAEGDS.NonCurrentAsset
	|			FROM
	|				ListOfVNAEGDS AS ListOfVNAEGDS
	|			WHERE
	|				ListOfVNAEGDS.AssetType = TYPE(Catalog.Assets))) AS FACost
	|
	|	UNION ALL
	|
	|	SELECT
	|		IACost.CostClosingBalance AS CostInManagementAccounting,
	|		IACost.LocalCostClosingBalance + IACost.CostTargetFinancingClosingBalance AS CostInAccounting
	|	FROM
	|		AccumulationRegister.IACost.BalanceAndTurnovers(&DateInformationWasUpdated, &DateInformationWasUpdated, Period,
	|			RegisterRecordsAndPeriodBoundaries, Organization IN (&CompaniesList)
	|		AND IntangibleAsset IN
	|			(SELECT
	|				ListOfVNAEGDS.NonCurrentAsset
	|			FROM
	|				ListOfVNAEGDS AS ListOfVNAEGDS
	|			WHERE
	|				ListOfVNAEGDS.AssetType = TYPE(Catalog.IntangibleAssets))) AS IACost
	|
	|// Depreciation.
	|	UNION ALL
	|
	|	SELECT
	|		FixedAssetsDepreciationChargeBalanceAndTurnovers.DepreciationClosingBalance AS CostInManagementAccounting,
	|		FixedAssetsDepreciationChargeBalanceAndTurnovers.DepreciationLocalClosingBalance +
	|			FixedAssetsDepreciationChargeBalanceAndTurnovers.FixedAssetDepreciationTargetFinancingClosingBalance AS CostInAccounting
	|	FROM
	|		AccumulationRegister.FixedAssetsDepreciationCharge.BalanceAndTurnovers(&DateInformationWasUpdated, &DateInformationWasUpdated, Period,
	|			RegisterRecordsAndPeriodBoundaries, Organization IN (&CompaniesList)
	|		AND FixedAsset IN
	|			(SELECT
	|				ListOfVNAEGDS.NonCurrentAsset
	|			FROM
	|				ListOfVNAEGDS AS ListOfVNAEGDS
	|			WHERE
	|				ListOfVNAEGDS.AssetType = TYPE(Catalog.Assets))) AS FixedAssetsDepreciationChargeBalanceAndTurnovers
	|
	|	UNION ALL
	|
	|	SELECT
	|		IntangibleAssetsAmortizationChargeBalanceAndTurnovers.DepreciationClosingBalance AS CostInManagementAccounting,
	|		IntangibleAssetsAmortizationChargeBalanceAndTurnovers.DepreciationLocalClosingBalance +
	|			IntangibleAssetsAmortizationChargeBalanceAndTurnovers.FixedAssetDepreciationTargetFinancingClosingBalance AS CostInAccounting
	|	FROM
	|		AccumulationRegister.IntangibleAssetsAmortizationCharge.BalanceAndTurnovers(&DateInformationWasUpdated, &DateInformationWasUpdated, Period,
	|			RegisterRecordsAndPeriodBoundaries, Organization IN (&CompaniesList)
	|		AND IntangibleAsset IN
	|			(SELECT
	|				ListOfVNAEGDS.NonCurrentAsset
	|			FROM
	|				ListOfVNAEGDS AS ListOfVNAEGDS
	|			WHERE
	|				ListOfVNAEGDS.AssetType = TYPE(Catalog.IntangibleAssets))) AS IntangibleAssetsAmortizationChargeBalanceAndTurnovers
	|
	|// Depreciation.
	|	UNION ALL
	|
	|	SELECT
	|		FAImpairment.ImpairmenManClosingBalance AS ImpairmenMan,
	|		FAImpairment.ImpairmentLocalAssetsClosingBalance AS ImpairmentLocalAssets
	|	FROM
	|		AccumulationRegister.ImpairmentFA.BalanceAndTurnovers(&DateInformationWasUpdated, &DateInformationWasUpdated, Period,
	|			RegisterRecordsAndPeriodBoundaries, Organization IN (&CompaniesList)
	|		AND NonCurrentAsset IN
	|			(SELECT
	|				ListOfVNAEGDS.NonCurrentAsset
	|			FROM
	|				ListOfVNAEGDS AS ListOfVNAEGDS
	|			WHERE
	|				ListOfVNAEGDS.AssetType = TYPE(Catalog.Assets))) AS FAImpairment
	|
	|	UNION ALL
	|
	|	SELECT
	|		ImpairmentIA.ImpairmenManClosingBalance AS ImpairmenMan,
	|		ImpairmentIA.ImpairmentLocalAssetsClosingBalance AS ImpairmentLocalAssets
	|	FROM
	|		AccumulationRegister.ImpairmentFA.BalanceAndTurnovers(&DateInformationWasUpdated, &DateInformationWasUpdated, Period,
	|			RegisterRecordsAndPeriodBoundaries, Organization IN (&CompaniesList)
	|		AND NonCurrentAsset IN
	|			(SELECT
	|				ListOfVNAEGDS.NonCurrentAsset
	|			FROM
	|				ListOfVNAEGDS AS ListOfVNAEGDS
	|			WHERE
	|				ListOfVNAEGDS.AssetType = TYPE(Catalog.IntangibleAssets))) AS ImpairmentIA) AS
	|		CostOfCGU";
	
	Query.SetParameter("DateInformationWasUpdated", EndOfDay(UpdateDate));
	Query.SetParameter("CompaniesList", CompaniesList);
	Query.SetParameter("CGU", Object.Ref);
	
	Result = Query.Execute();
	
	Selection = Result.Select();
	
	While Selection.Next() Do
		
		CostInAccounting = Selection.CostInAccounting;
		CostInManagementAccounting = Selection.CostInManagementAccounting;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_F_UpdateDate" Then
		UpdateDateOnChange(Items.UpdateDate);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
