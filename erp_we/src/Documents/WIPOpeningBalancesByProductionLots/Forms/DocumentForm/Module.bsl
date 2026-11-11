#Region Variables

// used by the mechanism for processing changes in PM details
&AtClient
Var CachedValues;

// used to pass the current line to the wait handler
&AtClient
Var CurDataId;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance(); 
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.WIPOpeningBalancesByProductionLots.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisObject);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	DocumentCorrection.OnCreateAtServer(ThisObject, Items.LineCorrection);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	FillingCommands = New Array();
	FillingCommands.Add(Items.OtherExpensesFillInTheRuleForAttributionToTheIssueOfRegl);
	FillingCommands.Add(Items.OtherExpensesToCompleteTheAssignmentRuleOnTheIssue);
	
	If Object.Patch Then
		For Each FillingCommand In FillingCommands Do
			FillingCommand.Visible = False;
		EndDo;
	EndIf;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	ItemsAndDimensionsSelectionParameters = Documents.WIPOpeningBalancesByProductionLots.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	OnReadCreateAtServer();
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.PeriodClosingDates
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	// End StandardSubsystems.PeriodClosingDates
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisForm, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	DocumentCorrection.OnReadAtServer(ThisForm, Items.LineCorrection);
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(
		Undefined,
		ThisObject,
		"BarcodeScanner");
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.AfterWrite(ThisForm, Object, WriteParameters);
	// End StandardSubsystems.AttachableCommands
	
	DocumentCorrectionClient.AfterWrite(Object);
	
	Notify("Write_WIPOpeningBalancesByProductionLots", WriteParameters, Object.Ref);
	
	// Standard subsystems.Modificationconfiguration
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	// The end of the standard subsystem.Modificationconfiguration
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	
	FillInServiceDetailsOfForm();
	FillIsAcceptedByKNUByDefault("MaterialsAndWorks");
	FillIsAcceptedByKNUByDefault("LaborCosts");
	
	FillInParametersForSpecifyingSeries();
	SetVisibilityOfSeriesElements();
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountTa");
	BatchProcessingOfTablePartServer.TreatTS(Object.MaterialsAndWorks, StructureOfActions, Undefined);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountTa");
	BatchProcessingOfTablePartServer.TreatTS(Object.LaborCosts, StructureOfActions, Undefined);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	DocumentCorrectionClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.Properties
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	// Peripherals
	If IsInputAvailable()
		And Source = "Peripherals" Then
		
		If EventName = "ScanData"
			And EquipmentManagerTMClient.ThereIsRawEvent() Then
			
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToArray(Parameter));
			
		EndIf;
		
	EndIf;
	// End Peripherals
	
	// Unknown barcodes
	If EventName = "UnknownBarcodes"
		And Source = "Peripherals"
		And Parameter.OwnerForm = UUID Then
		
		CachedValues.Barcodes.Clear();
		
		BarcodeData_5 = New Array;
		
		For Each ReceivedBarcode In Parameter.ItemsBarcodes Do
			BarcodeData_5.Add(ReceivedBarcode);
		EndDo;
		
		ProcessBarcodes(BarcodeData_5);
		
	EndIf;
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		CurrentData = Items.MaterialsAndWorks.RowData(ValueSelected.CurrentRowID);
		ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected, CurrentData);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If CurrentPage.Name = "GroupPageMore"
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOfChangeOnServer();
	
EndProcedure

&AtServer
Procedure DateOfChangeOnServer()
	
	UpdateBalancesForActivities();
	SetVisibility1();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationWhenChangedOnServer();
	
EndProcedure

&AtServer
Procedure OrganizationWhenChangedOnServer()
	
	FillInLocalAccountingCurrency();
	
	UpdateBalancesForActivities();
	SetVisibility1();
	SetHeaders();
	
EndProcedure

&AtClient
Procedure LineOfBusinessOnChange(Item)
	
	DirectionOfActivityWhenChangingOnServer();
	
EndProcedure

&AtServer
Procedure DirectionOfActivityWhenChangingOnServer()
	
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	UpdateBalancesForActivities();
	
EndProcedure

&AtClient
Procedure VATActivityTypeClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(
		ThisObject, FormattedStringURL, StandardProcessing);

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlers

#Region FormTableItemsEventHandlersMaterialsAndWorks

&AtClient
Procedure MaterialsAndWorksBeforeDeleteRow(Item, Cancel)
	
	UpdateCachedValuesToAccountForSeries(Item, CachedValues, False);
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.MaterialsAndWorks.CurrentData;
	
	If NewRow Then
		CurrentData.AcceptedByTheKNU = True;
	EndIf;
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.MaterialsAndWorks, ThisObject);
	UpdateCachedValuesToAccountForSeries(Item, CachedValues, Copy);
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksOnEditEnd(Item, NewRow, CancelEdit)
	
	If CancelEdit Then
		Return;
	EndIf;
	
	CurrentData = Items.MaterialsAndWorks.CurrentData;
	
	If ProductsClient.SeriesStatusesNeedToBeUpdated(
			Item, CachedValues, SeriesSpecificationParameters) Then
		
		IDCurrentRow = CurrentData.GetID();
		
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(
			SeriesSpecificationParameters,
			IDCurrentRow,
			CachedValues);
		
		ProductsClient.UpdateCachedValuesToAccountForSeries(
			Item,
			CachedValues,
			SeriesSpecificationParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksProductionLotStartChoice(Item, ChoiceData, StandardProcessing)
	
	BatchProductionStartSelection("MaterialsAndWorks", Items.MaterialsAndWorks, StandardProcessing);
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksProductsOnChange(Item)
	
	CurrentData = Items.MaterialsAndWorks.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingProducts(CurrentData, ThisForm, StructureOfActions);
	AddActionsToStructureWhenChangingPackagesNumber(ThisForm, StructureOfActions);
	AddSeriesActionsToStructure(StructureOfActions, Object.Department, SeriesSpecificationParameters);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksCharacteristicOnChange(Item)
	
	CurrentRow = Items.MaterialsAndWorks.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert(
		"CharacteristicOnChangeOverridable",
		New Structure("FormName", FormName));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksSeriesOnChange(Item)
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value						= Items.MaterialsAndWorks.CurrentData.Series;
	ValueSelected.CurrentRowID	= Items.MaterialsAndWorks.CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenSelectionOfSeries(Item.EditText, Items.MaterialsAndWorks.CurrentData);
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksNumberOfPackagesOnChange(Item)
	
	CurrentData = Items.MaterialsAndWorks.CurrentData;
	CurrentData.AmountExcludingVAT = CurrentData.Sum;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(ThisForm, StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksPackageOnChange(Item)
	
	CurrentData = Items.MaterialsAndWorks.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(ThisForm, StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksPriceOnChange(Item)
	
	CurrentData = Items.MaterialsAndWorks.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithoutVAT");
	StructureOfActions.Insert("RecalculateLocalAmount",	FactorOfConversionFromManCurrencyToRegulCurrency);
	StructureOfActions.Insert("RecalculatePDAmount",	FactorOfConversionFromManCurrencyToRegulCurrency);
	StructureOfActions.Insert("RecalculateAmountTa");
	StructureOfActions.Insert("RecalculateAmountOfTD");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksSumOnChange(Item)
	
	CurrentData = Items.MaterialsAndWorks.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePriceByAmount", "NumberOfPackages");
	StructureOfActions.Insert("RecalculateAmountWithoutVAT");
	StructureOfActions.Insert("RecalculateLocalAmount",	FactorOfConversionFromManCurrencyToRegulCurrency);
	StructureOfActions.Insert("RecalculatePDAmount",	FactorOfConversionFromManCurrencyToRegulCurrency);
	StructureOfActions.Insert("RecalculateAmountTa");
	StructureOfActions.Insert("RecalculateAmountOfTD");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksSumComplOnChange(Item)
	
	CurrentData = Items.MaterialsAndWorks.CurrentData;
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePDAmount", FactorOfConversionFromManCurrencyToRegulCurrency);
	StructureOfActions.Insert("RecalculateAmountTa");
	StructureOfActions.Insert("RecalculateAmountOfTD");
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksAmountFAOnChange(Item)
	
	CurrentData = Items.MaterialsAndWorks.CurrentData;
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountOfTD");
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksAmountPermanentDifferencesOnChange(Item)
	
	CurrentData = Items.MaterialsAndWorks.CurrentData;
	StructureOfActions = New Structure;
	If CurrentData.AcceptedByTheKNU Then
		StructureOfActions.Insert("RecalculateAmountTa");
	EndIf;
	StructureOfActions.Insert("RecalculateAmountOfTD");
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersLaborCosts

&AtClient
Procedure LaborCostsOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.LaborCosts.CurrentData;
	
	If NewRow Then
		CurrentData.AcceptedByTheKNU = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure LaborCostsProductionLotStartChoice(Item, ChoiceData, StandardProcessing)
	
	BatchProductionStartSelection("LaborCosts", Items.LaborCosts, StandardProcessing);
	
EndProcedure

&AtClient
Procedure LaborCostsWorkKindOnChange(Item)
	
	
	CurrentData = Items.LaborCosts.CurrentData;
	LaborCostsTypeOfWorkWhenChangingOnServer(CurrentData.GetID());
	
	CurrentData.StandardAmount	= CurrentData.Count * CurrentData.StandardRate;
	CurrentData.AmountExcludingVAT		= CurrentData.Sum;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenQuantityChanges(ThisForm, StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtServer
Procedure LaborCostsTypeOfWorkWhenChangingOnServer(Id)
	
	CurrentData						= Object.LaborCosts.FindByID(Id);
	CurrentData.StandardRate	= Catalogs.EmployeeWorkKinds.CurrentRateOfTypeOfWork(CurrentData.WorkKind, Object.Date,, Object.Department, Object.Organization);
	
EndProcedure

&AtClient
Procedure LaborCostsCountOnChange(Item)
	
	CurrentData					= Items.LaborCosts.CurrentData;
	CurrentData.StandardAmount	= CurrentData.Count * CurrentData.StandardRate;
	CurrentData.AmountExcludingVAT		= CurrentData.Sum;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenQuantityChanges(ThisForm, StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure LaborCostsStandardRateOnChange(Item)
	
	CurrentData					= Items.LaborCosts.CurrentData;
	CurrentData.StandardAmount	= CurrentData.Count * CurrentData.StandardRate;
	
EndProcedure

&AtClient
Procedure LaborCostsStandardAmountOnChange(Item)
	
	CurrentData = Items.LaborCosts.CurrentData;
	If ValueIsFilled(CurrentData.Count) Then
		CurrentData.StandardRate = Round(CurrentData.StandardAmount / CurrentData.Count, 2);
	Else
		CurrentData.StandardRate = 0;
	EndIf;
	
EndProcedure

&AtClient
Procedure LaborCostsPriceOnChange(Item)
	
	CurrentData = Items.LaborCosts.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount", "Count");
	StructureOfActions.Insert("RecalculateAmountWithoutVAT");
	StructureOfActions.Insert("RecalculateLocalAmount",	FactorOfConversionFromManCurrencyToRegulCurrency);
	StructureOfActions.Insert("RecalculatePDAmount",	FactorOfConversionFromManCurrencyToRegulCurrency);
	StructureOfActions.Insert("RecalculateAmountTa");
	StructureOfActions.Insert("RecalculateAmountOfTD");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure LaborCostsSumOnChange(Item)
	
	CurrentData = Items.LaborCosts.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePriceByAmount", "Count");
	StructureOfActions.Insert("RecalculateAmountWithoutVAT");
	StructureOfActions.Insert("RecalculateLocalAmount",	FactorOfConversionFromManCurrencyToRegulCurrency);
	StructureOfActions.Insert("RecalculatePDAmount",	FactorOfConversionFromManCurrencyToRegulCurrency);
	StructureOfActions.Insert("RecalculateAmountTa");
	StructureOfActions.Insert("RecalculateAmountOfTD");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure LaborCostsSumComplOnChange(Item)
	
	CurrentData = Items.LaborCosts.CurrentData;
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePDAmount", FactorOfConversionFromManCurrencyToRegulCurrency);
	StructureOfActions.Insert("RecalculateAmountTa");
	StructureOfActions.Insert("RecalculateAmountOfTD");
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure LaborCostsAmountFAOnChange(Item)
	
	CurrentData = Items.LaborCosts.CurrentData;
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountOfTD");
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure LaborCostsAmountPermanentDifferencesOnChange(Item)
	
	CurrentData = Items.LaborCosts.CurrentData;
	StructureOfActions = New Structure;
	If CurrentData.AcceptedByTheKNU Then
		StructureOfActions.Insert("RecalculateAmountTa");
	EndIf;
	StructureOfActions.Insert("RecalculateAmountOfTD");
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersOtherExpenses

&AtClient
Procedure OtherExpensesOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.OtherExpenses.CurrentData;
	
	IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, CurrentData, "Object.OtherExpenses");
	
	If NewRow And Not Copy Then
		
		CurrentData.AcceptedByTheKNU = True;
		CurrentData.RuleOfCostAllocatingToProductionLotsMan =
			PredefinedValue("Enum.RulesOfCostAllocationToProductCost.ByMaterialAndLaborCosts");
		CurrentData.RuleOfCostAllocatingToProductionLotsLocal =
			PredefinedValue("Enum.RulesOfCostAllocationToProductCost.ByMaterialAndLaborCosts");
		
	EndIf;
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.OtherExpenses, ThisObject);
	
EndProcedure

&AtClient
Procedure OtherExpensesProductionLotStartChoice(Item, ChoiceData, StandardProcessing)
	
	BatchProductionStartSelection("OtherExpenses", Items.OtherExpenses, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OtherExpensesExpenseItemOnChange(Item)
	
	OtherExpensesExpenseItemOnChangeServer(CachedValues);
	
EndProcedure

&AtServer
Procedure OtherExpensesExpenseItemOnChangeServer(CachedValues)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.OtherExpensesExpenseItem);
	
	FillInOptionsForDistributionOfItemsOfExpenditure(Items.OtherExpenses.CurrentRow);
	
	ArticleDetails_1 = New Structure;
	ArticleDetails_1.Insert("ProductCostElement");
	ArticleDetails_1.Insert("BasisOfDistributionByPartyMen", "CostAllocationRuleManag.BaseOfAllocationByLots");
	ArticleDetails_1.Insert("LocalPartyDistributionBase", "CostAllocationRuleLocal.BaseOfAllocationByLots");
	
	TableRow = Object.OtherExpenses.FindByID(Items.OtherExpenses.CurrentRow);
	ArticleDetails_1 = Common.ObjectAttributesValues(TableRow.ExpenseItem, ArticleDetails_1);
	
	RulesOfCostAllocationToProductCost = RulesOfCostAllocationToProductCost();
	
	TableRow.ProductCostElement			= ArticleDetails_1.ProductCostElement;
	TableRow.RuleOfCostAllocatingToProductionLotsMan	= RulesOfCostAllocationToProductCost[ArticleDetails_1.BasisOfDistributionByPartyMen];
	TableRow.RuleOfCostAllocatingToProductionLotsLocal	= RulesOfCostAllocationToProductCost[ArticleDetails_1.LocalPartyDistributionBase];
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInAttributeAcceptedByCNU");
	BatchProcessingOfTablePartServer.ProcessTSString(TableRow, StructureOfActions, CachedValues);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePDAmount", FactorOfConversionFromManCurrencyToRegulCurrency);
	StructureOfActions.Insert("RecalculateAmountTa");
	StructureOfActions.Insert("RecalculateAmountOfTD");
	BatchProcessingOfTablePartServer.ProcessTSString(TableRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure OtherExpensesExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OtherExpensesDimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OtherExpensesDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OtherExpensesDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OtherExpensesSumOnChange(Item)
	
	CurrentData = Items.OtherExpenses.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountWithoutVAT");
	If CurrentData.CostAllocationOptionLocal = PredefinedValue("Enum.CostAllocationOptions.ToProductionCosts")
		Or CurrentData.CostAllocationOptionLocal = PredefinedValue("Enum.CostAllocationOptions.ToProductionCostDirect") Then
		
		StructureOfActions.Insert("RecalculateLocalAmount",	FactorOfConversionFromManCurrencyToRegulCurrency);
		StructureOfActions.Insert("RecalculatePDAmount",	FactorOfConversionFromManCurrencyToRegulCurrency);
		StructureOfActions.Insert("RecalculateAmountTa");
		StructureOfActions.Insert("RecalculateAmountOfTD");
		
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure OtherExpensesSumComplOnChange(Item)
	
	CurrentData = Items.OtherExpenses.CurrentData;
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePDAmount", FactorOfConversionFromManCurrencyToRegulCurrency);
	StructureOfActions.Insert("RecalculateAmountTa");
	StructureOfActions.Insert("RecalculateAmountOfTD");
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure OtherExpensesAmountFAOnChange(Item)
	
	CurrentData = Items.OtherExpenses.CurrentData;
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountOfTD");
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure OtherExpensesAmountPermanentDifferencesOnChange(Item)
	
	CurrentData = Items.OtherExpenses.CurrentData;
	StructureOfActions = New Structure;
	If CurrentData.AcceptedByTheKNU Then
		StructureOfActions.Insert("RecalculateAmountTa");
	EndIf;
	StructureOfActions.Insert("RecalculateAmountOfTD");
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

#EndRegion

#EndRegion

#Region FormCommandsEventHandlers

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure


&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure


#Region ObjectCommands_

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm);
	
EndProcedure

#EndRegion

#Region CommandsOfTabularPartMaterialsAndWorks

&AtClient
Procedure MaterialsAndWorksFillOutTheCalculationArticle(Command)
	
	FillInTheCostingItem("MaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure RoundUpTheMaterialsAndWorksToTheWholePackage(Command)
	
	RoundToTheWholePackage();
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksSplitLine(Command)
	
	BreakTSString("MaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksSearchByBarcode(Command)
	
	SearchByBarcodeExecute();
	
EndProcedure

&AtClient
Procedure SpecifySeries(Command)

	OpenSelectionOfSeries();

EndProcedure

#EndRegion

#Region CommandsOfTablePartLaborCosts

&AtClient
Procedure LaborCostsSplitLine(Command)
	
	BreakTSString("LaborCosts");
	
EndProcedure

&AtClient
Procedure LaborCostsFillOutTheCalculationArticle(Command)
	
	FillInTheCostingItem("LaborCosts");
	
EndProcedure

#EndRegion

#Region TableCommandsOtherExpenses

&AtClient
Procedure OtherExpensesFillInTheCalculationItem(Command)
	
	FillInTheCostingItem("OtherExpenses");
	
EndProcedure

&AtClient
Procedure OtherExpensesFillInTheRuleForAllocationToTheIssueOfUPR(Command)
	
	FillInIssueAssignmentRule("Man");
	
EndProcedure

&AtClient
Procedure OtherExpensesFillInTheRuleForAttributionToTheIssueOfRegl(Command)
	
	FillInIssueAssignmentRule("Compl");
	
EndProcedure

#EndRegion

#Region CommandsForFillingInTablePartAreCommon

&AtClient
Procedure FillInTheCostingItem(TSName)
	
	SelectedRows = Items[TSName].SelectedRows;
	If SelectedRows.Count() = 0 Then
		WarningText = NStr("vi = 'Cần chọn các dòng để điền dạng tính giá thành.';
							|ru = 'Необходимо выбрать строки, для которых необходимо заполнить статью калькуляции.';
							|en = 'Select the lines for which it is required to populate the product cost element.'; fa = 'Select the lines for which it is required to populate the product cost element.';
							|it = 'È necessario selezionare le righe per le quali si deve compilare la voce di calcolo.';
							|pl = 'Należy wybrać wiersze, dla których trzeba wypełnić pozycję kalkulacji.';
							|tr = 'Ürün maliyet kalemini doldurmanız gereken satırları seçmeniz gerekmektedir.'");
		CommonClient.MessageToUser(WarningText);
		Return;
	EndIf;
	
	CostTypes = New Array;
	If TSName = "MaterialsAndWorks" Then
		CostTypes.Add(PredefinedValue("Enum.CostTypes.Material_"));
		CostTypes.Add(PredefinedValue("Enum.CostTypes.RecyclableWaste"));
	ElsIf TSName = "LaborCosts" Then
		CostTypes.Add(PredefinedValue("Enum.CostTypes.Payroll"));
	ElsIf TSName = "OtherExpenses" Then
		CostTypes.Add(PredefinedValue("Enum.CostTypes.Depreciation"));
		CostTypes.Add(PredefinedValue("Enum.CostTypes.Other"));
	EndIf;
	
	FilterParameters = New Structure;
	FilterParameters.Insert("ExpenseType", New FixedArray(CostTypes));
	
	FormParameters = New Structure;
	FormParameters.Insert("MultipleChoice", False);
	FormParameters.Insert("Filter", FilterParameters);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("TSName",				TSName);
	AdditionalParameters.Insert("SelectedRows",	SelectedRows);
	
	CallbackDescription = New CallbackDescription("FillInTheCostingItemCompletion", ThisObject, AdditionalParameters);
	
	OpenForm(
		"Catalog.ProductCostElements.ChoiceForm",
		FormParameters,,,,,
		CallbackDescription);
	
EndProcedure

&AtClient
Procedure FillInTheCostingItemCompletion(Result, AdditionalParameters) Export
	
	// StandardSubsystems.PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.WIPOpeningBalancesByProductionLots.Form.DocumentForm.FillInTheCostingItemCompletion");
	// End StandardSubsystems.PerformanceMeasurement
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	FillInDetailsOfTSServer("ProductCostElement", Result, AdditionalParameters);
	
EndProcedure

&AtClient
Procedure FillInIssueAssignmentRule(AccountingKind)
	
	AvailableOptionsForAssignmentToIssue = New Array;
	AvailableOptionsForAssignmentToIssue.Add(
		PredefinedValue("Enum.CostAllocationOptions.ToProductionCosts"));
	AvailableOptionsForAssignmentToIssue.Add(
		PredefinedValue("Enum.CostAllocationOptions.DoNotAllocate"));
	
	SelectedRows = New Array;
	For Each RowID In Items.OtherExpenses.SelectedRows Do
		CurRow = Object.OtherExpenses.FindByID(RowID);
		If Not AvailableOptionsForAssignmentToIssue.Find(CurRow["CostAllocationOption" + AccountingKind]) = Undefined Then
			SelectedRows.Add(RowID);
		EndIf;
	EndDo;
	
	If SelectedRows.Count() = 0 Then
		WarningText = NStr("vi = 'Cần chọn các dòng để điền quy tắc đưa vào chi phí xuất xưởng.';
							|ru = 'Необходимо выбрать строки, для которых необходимо заполнить правило отнесения на выпуск.';
							|en = 'Select the lines for which it is required to populate the rule of allocating to release.'; fa = 'Select the lines for which it is required to populate the rule of allocating to release.';
							|it = 'È necessario selezionare le linee per le quali è necessario compilare la regola di allocazione.';
							|pl = 'Konieczne jest wybranie wierszy, dla których konieczne jest wypełnienie reguły alokacji do zakończenia produkcji.';
							|tr = 'Üretim için ilişkilendirme kuralının doldurulması gereken satırları seçilmeli.'");
		CommonClient.MessageToUser(WarningText);
		Return;
	EndIf;
	
	FormParameters = New Structure;
	
	RulesArray = New Array;
	RulesArray.Add(PredefinedValue("Enum.RulesOfCostAllocationToProductCost.ByMaterialCosts"));
	RulesArray.Add(PredefinedValue("Enum.RulesOfCostAllocationToProductCost.ByMaterialAndLaborCosts"));
	RulesArray.Add(PredefinedValue("Enum.RulesOfCostAllocationToProductCost.ByProductsIncludingFutureReleases"));
	RulesArray.Add(PredefinedValue("Enum.RulesOfCostAllocationToProductCost.ByLaborCosts"));
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("Ref", New FixedArray(RulesArray));
	
	FormParameters.Insert("Filter",				FilterStructure1);
	FormParameters.Insert("MultipleChoice",	False);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("TSName",				"OtherExpenses");
	AdditionalParameters.Insert("AccountingKind",			AccountingKind);
	AdditionalParameters.Insert("SelectedRows",	SelectedRows);
	
	CallbackDescription = New CallbackDescription("FillInIssueAssignmentRuleCompletion", ThisObject, AdditionalParameters);
	
	OpenForm(
		"Enum.RulesOfCostAllocationToProductCost.ChoiceForm",
		FormParameters,,,,,
		CallbackDescription);
	
EndProcedure

&AtClient
Procedure FillInIssueAssignmentRuleCompletion(Result, AdditionalParameters) Export
	
	// StandardSubsystems.PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.WIPOpeningBalancesByProductionLots.Form.DocumentForm.FillInIssueAssignmentRuleCompletion");
	// End StandardSubsystems.PerformanceMeasurement
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	FillInDetailsOfTSServer("RuleOfCostAllocatingToProductionLots", Result, AdditionalParameters);
	
EndProcedure

#EndRegion

#Region StandardSubsystems

#Region Properties

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand,
												Var_URL = Undefined,
												StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

#EndRegion

#Region AttachableCommands

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure

#EndRegion

#Region ImportDataFromFile

&AtClient
Procedure DownloadMaterialsAndWorksFromAFile(Command)
	
	LoadFromFile("MaterialsAndWorks", NStr("vi = 'Nguyên vật liệu và công việc';
											|ru = 'Материалы и работы';
											|en = 'Materials and works'; fa = 'Materials and works';
											|it = 'Materiali e lavori';
											|pl = 'Materiały i prace';
											|tr = 'Malzemeler ve işler'"));
	
EndProcedure

&AtClient
Procedure LaborCostsUploadFromFile(Command)
	
	LoadFromFile("LaborCosts", NStr("vi = 'Chi phí nhân công';
									|ru = 'Трудозатраты';
									|en = 'Labor costs'; fa = 'هزینه‌های دستمزد';
									|it = 'Costi di manodopera';
									|pl = 'Nakłady pracy';
									|tr = 'İş gücü maliyetleri'"));
	
EndProcedure

&AtClient
Procedure OtherExpensesUploadFromFile(Command)
	
	LoadFromFile("OtherExpenses", NStr("vi = 'Chi phí khác';
										|ru = 'Прочие расходы';
										|en = 'Other expenses'; fa = 'سایر هزینه‌ها';
										|it = 'Altre spese';
										|pl = 'Inne rozchody';
										|tr = 'Diğer giderler'"));
	
EndProcedure

&AtClient
Procedure LoadFromFile(TSName, TSSynonym)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("TSName",		TSName);
	AdditionalParameters.Insert("TSSynonym",	TSSynonym);
	
	If Not Object[TSName].Count() = 0 Then
		
		QueryText = NStr("vi = 'Bảng %1 sẽ được điền lại. Tiếp tục?';
						|ru = 'Таблица %1 будет перезаполнена. Продолжить?';
						|en = 'The table %1 will be refilled. Continue?'; fa = 'The table %1 will be refilled. Continue?';
						|it = 'La tаbellа %1 verrà precompilata. Continuare?';
						|pl = 'Tabela %1 zostanie uzupełniona ponownie. Kontynuować?';
						|tr = '%1 tablosu yeniden doldurulacaktır. Devam edilsin mi?'");
		QueryText = StrTemplate(QueryText, TSSynonym);
		
		Notification = New CallbackDescription("LoadFromFileCompletion", ThisForm, AdditionalParameters);
		ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo);
		
	Else
		ShowUploadFormFromFile(AdditionalParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure LoadFromFileCompletion(Result, AdditionalParameters) Export
	
	If Not Result = DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ShowUploadFormFromFile(AdditionalParameters);
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion

#Region Private

#Region FormEvents

&AtServer
Procedure OnReadCreateAtServer()
	
	FillInServiceDetailsOfForm();
	
	FillIsAcceptedByKNUByDefault("MaterialsAndWorks");
	FillIsAcceptedByKNUByDefault("LaborCosts");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountTa");
	BatchProcessingOfTablePartServer.TreatTS(Object.MaterialsAndWorks, StructureOfActions, Undefined);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountTa");
	BatchProcessingOfTablePartServer.TreatTS(Object.LaborCosts, StructureOfActions, Undefined);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInAttributeAcceptedByCNU");
	StructureOfActions.Insert("RecalculateAmountTa");
	BatchProcessingOfTablePartServer.TreatTS(Object.OtherExpenses, StructureOfActions, Undefined);
	
	LinesOfBusinessServer.OnReadCreateAtServer(ThisObject);
	
	FillInParametersForSpecifyingSeries();
	FillInStatusesForSpecifyingSeriesServer();
	SetVisibilityOfSeriesElements();
	
	UpdateBalancesForActivities(False);
	SetVisibility1();
	SetAvailability();
	SetHeaders();
	SetArticleSelectionParameters();
	SetParametersForSelectingAssignmentRuleForIssue();
	
EndProcedure

#EndRegion

#Region FormSettings

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	#Region Table_MaterialsAndWorks
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm, 
		"MaterialsAndWorksCharacteristic",
		"Object.MaterialsAndWorks.ItemVariantsAreUsed");
	
	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(
		ThisForm,
		False,
		"MaterialsAndWorksBatchesIndicationStatus",
		"Object.MaterialsAndWorks.BatchesIndicationStatus");
	
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(
		ThisForm,
		False,
		"MaterialsAndWorksSeries",
		"Object.MaterialsAndWorks.BatchesIndicationStatus",
		"Object.MaterialsAndWorks.ItemsType");
	
	ProductsServer.SetConditionalAppearanceOfProductAssignment(
		ThisForm,
		"MaterialsAndWorksPurpose",
		"Object.MaterialsAndWorks.ItemsType",
		False);
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "MaterialsAndWorksProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.MaterialsAndWorks.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);
	
	#EndRegion
	
	#Region Table_OtherExpenses
	
	AvailableOptionsForAssignmentToIssue = New ValueList;
	AvailableOptionsForAssignmentToIssue.Add(Enums.CostAllocationOptions.ToProductionCosts);
	AvailableOptionsForAssignmentToIssue.Add(Enums.CostAllocationOptions.ToProductionCostDirect);
	
	#Region RulesOfCostAllocationToProductCost
	// Availability of the rules for attribution to output by distribution options and cost type.
	// Upr.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OtherExpensesRuleOfCostAllocatingToProductionLotsMan.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OtherExpenses.CostAllocationOptionManag");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = AvailableOptionsForAssignmentToIssue;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không được chỉ định>';
													|ru = '<не указывается>';
													|en = '<not specified>'; fa = '<مشخص نشده>';
													|it = '<non vengono indicati>';
													|pl = '<nie jest wskazywane>';
													|tr = '<belirtilmiyor>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// Regl.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OtherExpensesRuleOfCostAllocatingToProductionLotsLocal.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OtherExpenses.CostAllocationOptionLocal");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = AvailableOptionsForAssignmentToIssue;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không được chỉ định>';
													|ru = '<не указывается>';
													|en = '<not specified>'; fa = '<مشخص نشده>';
													|it = '<non vengono indicati>';
													|pl = '<nie jest wskazywane>';
													|tr = '<belirtilmiyor>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
		
	#EndRegion
	
	// The amount of upr.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OtherExpensesSum.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OtherExpenses.CostAllocationOptionManag");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = AvailableOptionsForAssignmentToIssue;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không được chỉ định>';
													|ru = '<не указывается>';
													|en = '<not specified>'; fa = '<مشخص نشده>';
													|it = '<non vengono indicati>';
													|pl = '<nie jest wskazywane>';
													|tr = '<belirtilmiyor>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// Amounts regl.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OtherExpensesSumCompl.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OtherExpensesAmountFA.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OtherExpensesAmountPermanentDifferences.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OtherExpensesAmountTemporaryDifferences.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OtherExpenses.CostAllocationOptionLocal");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = AvailableOptionsForAssignmentToIssue;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không được chỉ định>';
													|ru = '<не указывается>';
													|en = '<not specified>'; fa = '<مشخص نشده>';
													|it = '<non vengono indicati>';
													|pl = '<nie jest wskazywane>';
													|tr = '<belirtilmiyor>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	#EndRegion
	
EndProcedure

&AtServer
Procedure SetVisibility1()
	
	If Not ValueIsFilled(Object.DocumentBasis) Then
		Items.DocumentBasis.Visible = False;
	EndIf;
	
	PBU18IsApplied = False;
	CalculationOfPermanentAndTemporaryDifferencesIsKept = False;
	
	
	Items.OtherExpensesAmountPermanentDifferences.Visible = CalculationOfPermanentAndTemporaryDifferencesIsKept;
	Items.OtherExpensesAmountTemporaryDifferences.Visible = CalculationOfPermanentAndTemporaryDifferencesIsKept;
	
EndProcedure

&AtServer
Procedure SetAvailability()
	
	If ValueIsFilled(Object.DocumentBasis) Then
		Items.LineOfBusiness.ReadOnly = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetHeaders()
	
	If CurrencyOfActivityKindRates = LocalAccountingCurrency Then
		HeaderAmount = NStr("vi = 'Đơn giá tiêu chuẩn';
							|ru = 'Нормативная расценка';
							|en = 'Standard rate'; fa = 'نرخ استاندارد';
							|it = 'Tariffa normativa';
							|pl = 'Stawka standardowa';
							|tr = 'Standart ücret tarifesi'");
	Else
		TitleText = NStr("vi = 'Đơn giá tiêu chuẩn (%1)';
						|ru = 'Нормативная расценка (%1)';
						|en = 'Standard rate (%1)'; fa = 'Standard rate (%1)';
						|it = 'Tariffa normativa (%1)';
						|pl = 'Stawka standardowa (%1)';
						|tr = 'Standart ücret tarifesi (%1)'");
		HeaderAmount = StrTemplate(TitleText, CurrencyOfActivityKindRates);
	EndIf;
	
	Items.LaborCostsStandardRate.Title = HeaderAmount;
	
	If CurrencyOfActivityKindRates = LocalAccountingCurrency Then
		HeaderAmount = NStr("vi = 'Số tiền tiêu chuẩn';
							|ru = 'Нормативная сумма';
							|en = 'Standard amount'; fa = 'مبلغ استاندارد';
							|it = 'Importo normativo';
							|pl = 'Wartość standardowa';
							|tr = 'Standart tutar'");
	Else
		TitleText = NStr("vi = 'Số tiền tiêu chuẩn (%1)';
						|ru = 'Нормативная сумма (%1)';
						|en = 'Standard amount (%1)'; fa = 'Standard amount (%1)';
						|it = 'Importo normativo (%1)';
						|pl = 'Wartość standardowa (%1)';
						|tr = 'Standart tutar (%1)'");
		HeaderAmount = StrTemplate(TitleText, CurrencyOfActivityKindRates);
	EndIf;
	
	Items.LaborCostsStandardAmount.Title = HeaderAmount;
	
	If ManagementAccountingCurrency = LocalAccountingCurrency Then
		HeaderAmount = NStr("vi = 'Đơn giá';
							|ru = 'Расценка';
							|en = 'Rate'; fa = 'نرخ';
							|it = 'Tariffa';
							|pl = 'Stawki';
							|tr = 'Ücret tarifesi'");
	Else
		TitleText = NStr("vi = 'Đơn giá (%1)';
						|ru = 'Расценка (%1)';
						|en = 'Rate (%1)'; fa = 'Rate (%1)';
						|it = 'Tariffa (%1)';
						|pl = 'Stawka (%1)';
						|tr = 'Ücret tarifesi (%1)'");
		HeaderAmount = StrTemplate(TitleText, ManagementAccountingCurrency);
	EndIf;
	
	Items.LaborCostsPrice.Title = HeaderAmount;
	
	If ManagementAccountingCurrency = LocalAccountingCurrency Then
		HeaderAmount = NStr("vi = 'Số tiền';
							|ru = 'Сумма';
							|en = 'Amount'; fa = 'مبلغ';
							|it = 'Importo';
							|pl = 'Wartość';
							|tr = 'Tutar'");
	Else
		TitleText = NStr("vi = 'Số tiền (%1)';
						|ru = 'Сумма (%1)';
						|en = 'Amount (%1)'; fa = 'Amount (%1)';
						|it = 'Totale (%1)';
						|pl = 'Wartość (%1)';
						|tr = 'Tutar (%1)'");
		HeaderAmount = StrTemplate(TitleText, ManagementAccountingCurrency);
	EndIf;
	
	Items.MaterialsAndWorksSum.Title	= HeaderAmount;
	Items.LaborCostsSum.Title		= HeaderAmount;
	Items.OtherExpensesSum.Title		= HeaderAmount;
	
	If ManagementAccountingCurrency = LocalAccountingCurrency
		Or Not ValueIsFilled(LocalAccountingCurrency) Then
		HeaderAmount = NStr("vi = 'Số tiền tài chính';
							|ru = 'Сумма регл.';
							|en = 'Local amount'; fa = 'مبلغ محلی';
							|it = 'Importo reg.';
							|pl = 'Wartość regl.';
							|tr = 'Tutar (yerel)'");
	Else
		TitleText = NStr("vi = 'Số tiền tài chính (%1)';
						|ru = 'Сумма регл. (%1)';
						|en = 'Local amount (%1)'; fa = 'Local amount (%1)';
						|it = 'Importo regolatorio (%1)';
						|pl = 'Wartość reglam. (%1)';
						|tr = 'Tutar (yerel) (%1)'");
		HeaderAmount = StrTemplate(TitleText, LocalAccountingCurrency);
	EndIf;
	
	Items.MaterialsAndWorksSumCompl.Title	= HeaderAmount;
	Items.LaborCostsSumCompl.Title		= HeaderAmount;
	Items.OtherExpensesSumCompl.Title		= HeaderAmount;
	
	If ManagementAccountingCurrency = LocalAccountingCurrency
		Or Not ValueIsFilled(LocalAccountingCurrency) Then
		HeaderAmount = NStr("vi = 'KTTh';
							|ru = 'НУ';
							|en = 'TA'; fa = 'مالیاتی';
							|it = 'Contabilità fiscale';
							|pl = 'EP';
							|tr = 'Vergi muhasebesi'");
	Else
		TitleText = NStr("vi = 'KTTh (%1)';
						|ru = 'НУ (%1)';
						|en = 'TA (%1)'; fa = 'TA (%1)';
						|it = 'Contabilità fiscale (%1)';
						|pl = 'EP (%1)';
						|tr = 'VM (%1)'");
		HeaderAmount = StrTemplate(TitleText, LocalAccountingCurrency);
	EndIf;
	
	Items.MaterialsAndWorksAmountFA.Title	= HeaderAmount;
	Items.LaborCostsAmountFA.Title		= HeaderAmount;
	Items.OtherExpensesAmountFA.Title		= HeaderAmount;
	
	If ManagementAccountingCurrency = LocalAccountingCurrency
		Or Not ValueIsFilled(LocalAccountingCurrency) Then
		HeaderAmount = NStr("vi = 'CLVV';
							|ru = 'ПР';
							|en = 'PD'; fa = 'تفاوت دائم';
							|it = 'PR (Differenze permanenti)';
							|pl = 'RT';
							|tr = 'Sabit Farklar'");
	Else
		TitleText = NStr("vi = 'CLVV (%1)';
						|ru = 'ПР (%1)';
						|en = 'PD (%1)'; fa = 'PD (%1)';
						|it = 'PR (Differenze permanenti) (%1)';
						|pl = 'RT (%1)';
						|tr = 'SF (%1)'");
		HeaderAmount = StrTemplate(TitleText, LocalAccountingCurrency);
	EndIf;
	
	Items.MaterialsAndWorksAmountPermanentDifferences.Title	= HeaderAmount;
	Items.LaborCostsAmountPermanentDifferences.Title		= HeaderAmount;
	Items.OtherExpensesAmountPermanentDifferences.Title		= HeaderAmount;
	
	If ManagementAccountingCurrency = LocalAccountingCurrency
		Or Not ValueIsFilled(LocalAccountingCurrency) Then
		HeaderAmount = NStr("vi = 'CLTT';
							|ru = 'ВР';
							|en = 'TD'; fa = 'تفاوت موقت';
							|it = 'VR (Differenze temporanee)';
							|pl = 'RP';
							|tr = 'Geçici Farklar'");
	Else
		TitleText = NStr("vi = 'CLTT (%1)';
						|ru = 'ВР (%1)';
						|en = 'TD (%1)'; fa = 'TD (%1)';
						|it = 'VR (Differenze temporanee) (%1)';
						|pl = 'RP (%1)';
						|tr = 'Geçici Farklar (%1)'");
		HeaderAmount = StrTemplate(TitleText, LocalAccountingCurrency);
	EndIf;
	
	Items.MaterialsAndWorksAmountTemporaryDifferences.Title	= HeaderAmount;
	Items.LaborCostsAmountTemporaryDifferences.Title		= HeaderAmount;
	Items.OtherExpensesAmountTemporaryDifferences.Title		= HeaderAmount;
	
EndProcedure

&AtServer
Procedure SetArticleSelectionParameters()
	
	ArticleSelectionParameters = New Array;
	ArticleSelectionParameters.Add(New ChoiceParameter("AddExpenseItems", True));
	ArticleSelectionParameters.Add(
		New ChoiceParameter("Filter.BusinessOperation", Enums.BusinessTransactions.OBEntryProductionLotCosts));
	
	OptionsArray = New Array;
	OptionsArray.Add(Enums.CostAllocationOptions.ToProductionCosts);
	OptionsArray.Add(Enums.CostAllocationOptions.ToProductionCostDirect);
	OptionsArray.Add(Enums.CostAllocationOptions.ToCostCenters);
	OptionsArray.Add(Enums.CostAllocationOptions.DoNotAllocate);
	
	ArticleSelectionParameters.Add(
		New ChoiceParameter("Filter.CostSharingOptionOr", New FixedArray(OptionsArray)));
	
	Items.OtherExpensesExpenseItem.ChoiceParameters = New FixedArray(ArticleSelectionParameters);
	
EndProcedure

&AtServer
Procedure SetParametersForSelectingAssignmentRuleForIssue()
	
	RuleSelectionParameters = New Array;
	
	RulesArray = New Array;
	RulesArray.Add(Enums.RulesOfCostAllocationToProductCost.ByMaterialCosts);
	RulesArray.Add(Enums.RulesOfCostAllocationToProductCost.ByMaterialAndLaborCosts);
	RulesArray.Add(Enums.RulesOfCostAllocationToProductCost.ByProductsIncludingFutureReleases);
	RulesArray.Add(Enums.RulesOfCostAllocationToProductCost.ByLaborCosts);
	
	RuleSelectionParameters.Add(
		New ChoiceParameter("Filter.Ref", New FixedArray(RulesArray)));
	
	Items.OtherExpensesRuleOfCostAllocatingToProductionLotsMan.ChoiceParameters = New FixedArray(RuleSelectionParameters);
	Items.OtherExpensesRuleOfCostAllocatingToProductionLotsLocal.ChoiceParameters = New FixedArray(RuleSelectionParameters);
	
EndProcedure

#EndRegion

#Region FormServiceCommandHandlers

#Region TablePartCommandsAreCommon

&AtClient
Procedure RoundToTheWholePackage()
	
	SelectedRows = Items.MaterialsAndWorks.SelectedRows;
	
	If SelectedRows.Count() = 0 Then
		WarningText = NStr("vi = 'Cần chọn các dòng để làm tròn số lượng.';
							|ru = 'Необходимо выбрать строки, для которых необходимо округлить количество.';
							|en = 'Select the lines for which the quantity should be rounded off.'; fa = 'Select the lines for which the quantity should be rounded off.';
							|it = 'È necessario selezionare le righe per le quali è necessario arrotondare la quantità.';
							|pl = 'Należy wybrać wiersze, dla których trzeba zaokrąglić ilość';
							|tr = 'Miktarı yuvarlamanız gereken satırları seçmeniz gerekmektedir.'");
		CommonClient.MessageToUser(WarningText);
		Return;
	EndIf;
	
	TotalRows = 0;
	For Each Id In SelectedRows Do
		RowData = Object.MaterialsAndWorks.FindByID(Id);
		If Int(RowData.NumberOfPackages) = RowData.NumberOfPackages Then
			Continue;
		EndIf;
		TotalRows = TotalRows + 1;
	EndDo;
	
	If TotalRows = 0 Then
		ShowUserNotification(
			NStr("vi = 'Không cần làm tròn';
				|ru = 'Округление не требуется';
				|en = 'Rounding is not required'; fa = 'Rounding is not required';
				|it = 'L''arrotondamento non è richiesto';
				|pl = 'Zaokrąglenie nie jest potrzebne';
				|tr = 'Yuvarlama gerekmemektedir'"),, 
			NStr("vi = 'Các dòng được chọn đã có số nguyên đơn vị.';
				|ru = 'В выбранных строках уже целое количество единиц.';
				|en = 'There is already a whole number of units in the selected lines.'; fa = 'There is already a whole number of units in the selected lines.';
				|it = 'Nelle righe selezionate è già presente un numero intero di unità.';
				|pl = 'W wybranych wierszach już jest liczba całkowita jednostek.';
				|tr = 'Seçili satırlarda zaten tam sayı birimi mevcut.'"),
			PictureLib.Information32);
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Trong các dòng đã chọn, số lượng sẽ được làm tròn đến hàng đơn vị. 
							|Tiếp tục?';
							|ru = 'В выбранных строках количество будет округлено до целых единиц. 
							|Продолжить?';
							|en = 'The selected lines will be rounded up to integral units.
							|Continue?'; fa = 'The selected lines will be rounded up to integral units.
							|Continue?';
							|it = 'Nelle righe selezionate, la quantità verrà arrotondata a unità intere. 
							|Continuare?';
							|pl = 'W wybranych wierszach ilość zostanie zaokrągloną do liczb całkowitych. 
							|Kontynuować?';
							|tr = 'Seçili satırlardaki miktar, tam sayı birimlerine yuvarlanacaktır. 
							|Devam edilsin mi?'");
							
	CallbackDescription = New CallbackDescription("RoundToTheWholePackageCompletion", ThisObject);
	
	ButtonsList = New ValueList;
	ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Tiếp tục';
												|ru = 'Продолжить';
												|en = 'Continue'; fa = 'ادامه';
												|it = 'Continuare';
												|pl = 'Continue';
												|tr = 'Devam et'"));
	ButtonsList.Add(DialogReturnCode.Cancel);
	
	ShowQueryBox(CallbackDescription, QueryText, ButtonsList); 
	
EndProcedure

&AtClient
Procedure RoundToTheWholePackageCompletion(QuestionResult, AdditionalParameters) Export
	
	// StandardSubsystems.PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.WIPOpeningBalancesByProductionLots.Form.DocumentForm.RoundToTheWholePackageCompletion");
	// End StandardSubsystems.PerformanceMeasurement
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	RoundUpToWholePackageOnServer(CachedValues);
	NotificationText1 = NStr("vi = 'Các dòng đã chọn được làm tròn đến phần nguyên.';
							|ru = 'В выбранных строках выполнено округление до целых единиц.';
							|en = 'The selected lines are rounded up to integral units.'; fa = 'The selected lines are rounded up to integral units.';
							|it = 'Nelle righe selezionate è eseguito arrotondamento a intere unità.';
							|pl = 'W wybranych wierszach wykonano zaokrąglenie do liczb całkowitych.';
							|tr = 'Seçilen satırlarda tam sayı birimlerine yuvarlama gerçekleşti.'");
	ShowUserNotification(NStr("vi = 'Đã làm tròn';
								|ru = 'Выполнено округление';
								|en = 'Rounded'; fa = 'گردشده';
								|it = 'Eseguito arrotondamento';
								|pl = 'Wykonano zaokrąglenie';
								|tr = 'Yuvarlama gerçekleşti'"),, NotificationText1, PictureLib.Success32);
	
EndProcedure

&AtServer
Procedure RoundUpToWholePackageOnServer(CachedValues)
	
	StructureOfActions = New Structure;
	RowsArray = New Array;
	
	AddActionsToStructureWhenChangingPackagesNumber(ThisObject, StructureOfActions);
	RowsToProcess = New Array();
	
	For Each Id In Items.MaterialsAndWorks.SelectedRows Do
		
		RowData = Object.MaterialsAndWorks.FindByID(Id);
		If Int(RowData.NumberOfPackages) = RowData.NumberOfPackages Then
			Continue;
		EndIf;
		
		RowData.NumberOfPackages = Int(RowData.NumberOfPackages) + 1;
		
		RowsToProcess.Add(RowData);
		
		RowsArray.Add(Id);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.MaterialsAndWorks,
		CachedValues);
			
	FillInStatusesForSpecifyingSeriesServer(RowsArray);
	
EndProcedure

&AtClient
Procedure BreakTSString(TSName)
	
	// StandardSubsystems.PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.WIPOpeningBalancesByProductionLots.Form.DocumentForm.BreakTSString");
	// End StandardSubsystems.PerformanceMeasurement
	
	//Filling in parameters
	StringSplittingParameters = ProcessingOfTabularFormsClient.StringSplittingParameters();
	StringSplittingParameters.AllowZeroCount = False;
	If TSName = "LaborCosts" Then
		StringSplittingParameters.FieldNameQuantity = "Count";
	EndIf;
	
	//The description of the alert
	Notification = New CallbackDescription("BreakTSStringCompletion", ThisObject, TSName);
	
	ProcessingOfTabularFormsClient.SplitRow(Object[TSName], Items[TSName], Notification, StringSplittingParameters);
	
EndProcedure

&AtClient
Procedure BreakTSStringCompletion(NewRow, TSName) Export
	
	If NewRow = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Items[TSName].CurrentData;
	StructureOfActions = New Structure;
	
	If TSName = "LaborCosts" Then
		
		CurrentData.StandardAmount	= CurrentData.Count * CurrentData.StandardRate;
		CurrentData.AmountExcludingVAT		= CurrentData.Sum;
		
		NewRow.StandardAmount	= NewRow.Count * NewRow.StandardRate;
		NewRow.AmountExcludingVAT			= NewRow.Sum;
		
		AddActionsToStructureWhenQuantityChanges(ThisForm, StructureOfActions);
		
	Else
		AddActionsToStructureWhenChangingPackagesNumber(ThisForm, StructureOfActions);
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
	
	If TSName = "MaterialsAndWorks" Then
		
		RowsArray = New Array;
		RowsArray.Add(CurrentData.GetID());
		RowsArray.Add(NewRow.GetID());
		FillInStatusesForSpecifyingSeriesServer(RowsArray);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SearchByBarcodeExecute()
	
	ClearMessages();
	Notification = New CallbackDescription("SearchByBarcodeCompletion", ThisObject);
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);
	
EndProcedure

&AtClient
Procedure SearchByBarcodeCompletion(Result, AdditionalParameters) Export
	
	ProcessBarcodes(Result);
	
EndProcedure

&AtClient
Procedure ProcessBarcodes(BarcodeData_5)
	
	// StandardSubsystems.PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.WIPOpeningBalancesByProductionLots.Form.DocumentForm.ProcessBarcodes");
	// End StandardSubsystems.PerformanceMeasurement
	
	ClearMessages();
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
		Return;
	EndIf;
	
	StructureOfActionsAdded = New Structure;
	AddActionsToStructureWhenChangingProducts(Undefined, ThisObject, StructureOfActionsAdded);
	AddActionsToStructureWhenChangingPackagesNumber(ThisObject, StructureOfActionsAdded);
	AddSeriesActionsToStructure(StructureOfActionsAdded, Object.Department, SeriesSpecificationParameters);
	
	ActionStructureChanged = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(ThisObject, ActionStructureChanged);
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.TSName                                  = "MaterialsAndWorks";
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsAdded;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = ActionStructureChanged;
	StructureOfActions.SeriesSpecificationParameters                 = SeriesSpecificationParameters;
	
	ProcessBarcodesServer(StructureOfActions, CachedValues);
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(StructureOfActions, CachedValues, ThisObject);
	
	If BarcodingOfItemsClient.YouNeedToOpenFormForSpecifyingSeriesAfterProcessingBarcodes(StructureOfActions) Then
		CurDataId = StructureOfActions.ArrayOfRowsWithSeries_[0];
		
		AttachIdleHandler("OpenSeriesSelectionWhenScanningProductBarCode", 0.1, True);
	EndIf;
	
	If StructureOfActions.CurrentRow <> Undefined Then
		Items.MaterialsAndWorks.CurrentRow = StructureOfActions.CurrentRow;
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessBarcodesServer(StructureOfActionParameters, CachedValues)
	
	BarcodingOfItemsServer.ProcessBarcodes(
		ThisObject,
		Object,
		StructureOfActionParameters,
		CachedValues);
	
EndProcedure

#EndRegion

#Region CommandsForFillingInTablePartAreCommon

&AtServer
Procedure FillInDetailsOfTSServer(Attribute, Result, AdditionalParameters)

	TabularSection		= Object[AdditionalParameters.TSName];
	SelectedRows	= AdditionalParameters.SelectedRows;
	Modified	= True;
	
	AccountingKind = "";
	If AdditionalParameters.Property("AccountingKind") Then
		AccountingKind = AdditionalParameters.AccountingKind;
	EndIf;
	
	For Each Id In SelectedRows Do
		
		CurrentData = TabularSection.FindByID(Id);
		CurrentData[Attribute + AccountingKind] = Result;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#Region SetOfSeries

&AtServer
Procedure FillInParametersForSpecifyingSeries()
	
	SeriesSpecificationParameters =
		New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.WIPOpeningBalancesByProductionLots));
	
EndProcedure

&AtServer
Function ParametersOfSeriesIndicationForm(CurDataId)
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(
		Object,
		SeriesSpecificationParameters,
		CurDataId,
		ThisForm);
	
EndFunction

&AtServer
Procedure SetVisibilityOfSeriesElements()
	
	Items.MaterialsAndWorksSeries.Visible				=
		SeriesSpecificationParameters.UseItemsBatch;
	Items.MaterialsAndWorksBatchesIndicationStatus.Visible	=
		SeriesSpecificationParameters.UseItemsBatch;
	Items.MaterialsAndWorksSpecifyTheSeries.Visible			=
		SeriesSpecificationParameters.UseItemsBatch;
	
EndProcedure

&AtClient
Procedure UpdateCachedValuesToAccountForSeries(Item, CachedValues, Copy)
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(
		Item,
		CachedValues,
		SeriesSpecificationParameters,
		Copy);
	
EndProcedure

&AtClient
Procedure OpenSelectionOfSeries(Text = "", CurrentData = Undefined)
	
	NeedServerCall =
		ProductsClient.YouNeedServerCallToSpecifySeries(
			ThisObject,
			SeriesSpecificationParameters,
			Text,
			CurrentData);
	
	If NeedServerCall Then
		
		If CurrentData = Undefined Then
			CurDataId = Items.MaterialsAndWorks.CurrentData.GetID();
		Else
			CurDataId = CurrentData.GetID();
		EndIf;
		
		ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm(CurDataId);
		AdditionalParameters =
			New Structure(
				"SeriesSpecificationParameters,ParametersOfSeriesIndicationForm",
				SeriesSpecificationParameters, ParametersOfSeriesIndicationForm);
		
		CallbackDescription = New CallbackDescription("OpenSelectionOfSeriesCompletion", ThisObject, AdditionalParameters);
		
		OpenForm(
			ParametersOfSeriesIndicationForm.FormName,
			ParametersOfSeriesIndicationForm,
			ThisObject,,,,
			CallbackDescription);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenSelectionOfSeriesCompletion(ClosingResult, AdditionalParameters) Export

	If ClosingResult <> Undefined Then
		ProcessSeriesIndication_Server(
			AdditionalParameters.SeriesSpecificationParameters,
			AdditionalParameters.ParametersOfSeriesIndicationForm);
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessSeriesIndication_Server(Val SeriesSpecificationParameters, Val ParametersOfSeriesIndicationForm)
	
	StructureOfActions = Undefined;
	ProductsServer.ProcessSeriesIndication_(
		Object,
		SeriesSpecificationParameters,
		ParametersOfSeriesIndicationForm,
		StructureOfActions);
	
EndProcedure

&AtServer
Procedure FillInStatusesForSpecifyingSeriesServer(RowsOfProductsToProcess = Undefined)
	
	ProductLines_2 = Undefined;
	If TypeOf(RowsOfProductsToProcess) = Type("Array") Then
		ProductLines_2 = New Array;
		For Each Id In RowsOfProductsToProcess Do
			ProductLines_2.Add(Object.MaterialsAndWorks.FindByID(Id));
		EndDo;
	EndIf;
	
	ProductsServer.FillInStatusesForSpecifyingSeries(
		Object,
		SeriesSpecificationParameters,
		ProductLines_2);
	
EndProcedure

&AtServer
Procedure FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Val SeriesSpecificationParameters,
																			IDCurrentRow,
																			CachedValues)
	
	ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(
		Object,
		SeriesSpecificationParameters,
		IDCurrentRow,
		CachedValues);
	
EndProcedure

&AtClient
Procedure OpenSeriesSelectionWhenScanningProductBarCode()
	
	If CurDataId = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.MaterialsAndWorks.FindByID(CurDataId);
	
	OpenSelectionOfSeries(, CurrentData);
	
EndProcedure

#EndRegion

#Region StructureOfActions

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingProducts(CurrentRow, Form, StructureOfActions)

	If Not CurrentRow = Undefined Then
		StructureOfActions.Insert(
			"CheckCharacteristicsByOwner",
			CurrentRow.Characteristic);
	Else
		StructureOfActions.Insert("CheckFillPackageByOwner");
	EndIf;
	
	StructureOfActions.Insert(
		"FillInArticleAttribute",
		New Structure("Products", "SKU"));
	
	StructureOfActions.Insert(
		"FillInFeatureAttribute",
		New Structure("Products", "ItemVariantsAreUsed"));
	
	StructureOfActions.Insert(
		"FillInProductTypeAttribute_",
		New Structure("Products", "ItemsType"));
	
	StructureOfActions.Insert(
		"ProductsOnChangeOverridable",
		New Structure("FormName", Form.FormName));
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(Form, StructureOfActions)
	
	StructureOfActions.Insert("RecalculateNumberOfUnits",	ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithoutVAT");
	StructureOfActions.Insert("RecalculateLocalAmount",			Form.FactorOfConversionFromManCurrencyToRegulCurrency);
	StructureOfActions.Insert("RecalculatePDAmount",			Form.FactorOfConversionFromManCurrencyToRegulCurrency);
	StructureOfActions.Insert("RecalculateAmountTa");
	StructureOfActions.Insert("RecalculateAmountOfTD");
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenQuantityChanges(Form, StructureOfActions)
	
	StructureOfActions.Insert("RecalculateAmount",		"Count");
	StructureOfActions.Insert("RecalculateAmountWithoutVAT");
	StructureOfActions.Insert("RecalculateLocalAmount",	Form.FactorOfConversionFromManCurrencyToRegulCurrency);
	StructureOfActions.Insert("RecalculatePDAmount",	Form.FactorOfConversionFromManCurrencyToRegulCurrency);
	StructureOfActions.Insert("RecalculateAmountTa");
	StructureOfActions.Insert("RecalculateAmountOfTD");
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddSeriesActionsToStructure(StructureOfActions, Warehouse, SeriesSpecificationParameters)
	
	SeriesVerificationParameters = New Structure("Warehouse, SeriesSpecificationParameters", Warehouse, SeriesSpecificationParameters);
	StructureOfActions.Insert("CheckSeriesCalculateStatus", SeriesVerificationParameters);
	
EndProcedure

#EndRegion

#Region FillInAttributes

&AtServer
Procedure FillInServiceDetailsOfForm()
	
	ManagementAccountingCurrency	= Constants.ManagementAccountingCurrency.Get();
	FillInLocalAccountingCurrency();
	CurrencyOfActivityKindRates	= Constants.CurrencyOfActivityKindRates.Get();
	
	FillInServiceDetailsForProductRange();
	
	FillInOptionsForDistributionOfItemsOfExpenditure();
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInAttributeAcceptedByCNU");
	StructureOfActions.Insert("RecalculateAmountTa");
	BatchProcessingOfTablePartServer.TreatTS(Object.OtherExpenses, StructureOfActions, Undefined);
	
	ProcessingOfTabularForms.InitializeRowCache(Items.MaterialsAndWorks);
	ProcessingOfTabularForms.InitializeRowCache(Items.LaborCosts);
	ProcessingOfTabularForms.InitializeRowCache(Items.OtherExpenses);
	
EndProcedure

&AtServer
Procedure FillInLocalAccountingCurrency()
	
	LocalAccountingCurrency			= SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	FactorOfConversionFromManCurrencyToRegulCurrency	= ConversionFactor_();
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsForProductRange()
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert(
		"FillInFeatureAttribute",
		New Structure("Products", "ItemVariantsAreUsed"));
	
	ParametersForFillingInBankingDetails.Insert(
		"FillInArticleAttribute",
		New Structure("Products", "SKU"));
	
	ParametersForFillingInBankingDetails.Insert(
		"FillInProductTypeAttribute_",
		New Structure("Products", "ItemsType"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(
		Object.MaterialsAndWorks,
		ParametersForFillingInBankingDetails);
	
EndProcedure

&AtServer
Procedure FillInOptionsForDistributionOfItemsOfExpenditure(RowID = Undefined)
	
	If RowID = Undefined Then
		ExpenseItems = Object.OtherExpenses.Unload(, "ExpenseItem").UnloadColumn("ExpenseItem");
	Else
		
		CostLine = Object.OtherExpenses.FindByID(RowID);
		ExpenseItems = TMCommonUseClientServer.Array(CostLine.ExpenseItem);
		
	EndIf;
	
	Query = New Query;
	Query.SetParameter("ExpenseItems", ExpenseItems);
	
	Query.Text = 
		"SELECT
		|	ExpenseItems.Ref AS ExpenseItem,
		|	ExpenseItems.CostAllocationOptionLocal AS CostAllocationOptionLocal,
		|	ExpenseItems.CostAllocationOptionManag AS CostAllocationOptionManag
		|FROM
		|	ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
		|WHERE
		|	ExpenseItems.Ref IN(&ExpenseItems)";
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		
		If RowID = Undefined Then
			
			LinesByExpenditureItem_ = Object.OtherExpenses.FindRows(New Structure("ExpenseItem", Selection.ExpenseItem));
			For Each CostLine In LinesByExpenditureItem_ Do
				
				CostLine.CostAllocationOptionManag  = Selection.CostAllocationOptionManag;
				CostLine.CostAllocationOptionLocal = Selection.CostAllocationOptionLocal;
				
			EndDo;
			
		Else
			
			CostLine.CostAllocationOptionManag  = Selection.CostAllocationOptionManag;
			CostLine.CostAllocationOptionLocal = Selection.CostAllocationOptionLocal;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure FillIsAcceptedByKNUByDefault(TSName)
	
	For Each CurRow In Object[TSName] Do
		CurRow.AcceptedByTheKNU = True;
	EndDo;
	
EndProcedure

#EndRegion

#Region Other

#Region SelectProductionLots

&AtClient
Procedure BatchProductionStartSelection(TSName, FormTable, StandardProcessing)
	
	StandardProcessing = False;
	
	FilterStructure1 = New Structure();
	FilterStructure1.Insert("Organization",			Object.Organization);
	FilterStructure1.Insert("Department",		Object.Department);
	FilterStructure1.Insert("Document",			Object.Ref);
	FilterStructure1.Insert("ExcludeProductionByThirdParties", False);
	
	FormParameters = New Structure();
	FormParameters.Insert("BeginOfPeriod",	BegOfMonth(Object.Date));
	FormParameters.Insert("PeriodEnding",	EndOfMonth(Object.Date));
	FormParameters.Insert("FilterStructure1",	FilterStructure1);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("TSName",				TSName);
	AdditionalParameters.Insert("RowID",	FormTable.CurrentRow);
	
	Notification = New CallbackDescription(
		"BatchProductionStartSelectionCompletion",
		ThisForm,
		AdditionalParameters);
	
	OpenForm(
		"CommonForm.SelectProductionLots",
		FormParameters,
		ThisForm,,,,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure BatchProductionStartSelectionCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	BatchProductionStartSelectionCompletionServer(Result, AdditionalParameters);
	
EndProcedure

&AtServer
Procedure BatchProductionStartSelectionCompletionServer(Result, AdditionalParameters)
	
	TSName				= AdditionalParameters.TSName;
	InitialString		= Object[TSName].FindByID(AdditionalParameters.RowID);
	BatchTable_		= GetFromTempStorage(Result);
	Modified	= True;
	
	For Each CurRow In BatchTable_ Do
		
		If BatchTable_.Count() = 1 Then
			NewRow = InitialString;
		Else
			NewRow = Object[TSName].Add();
			FillPropertyValues(NewRow, InitialString);
			
			If TSName = "MaterialsAndWorks" Then
				NewRow.NumberOfPackages	= 0;
				NewRow.AcceptedByTheKNU		= True;
			EndIf;
			
			If TSName = "LaborCosts" Then
				NewRow.StandardAmount = 0;
				NewRow.AcceptedByTheKNU		= True;
			EndIf;
			
			If Not TSName = "OtherExpenses" Then
				NewRow.Count = 0;
			EndIf;
			
			NewRow.Sum		= 0;
			NewRow.SumCompl	= 0;
			NewRow.AmountPermanentDifferences = 0;
			NewRow.AmountTemporaryDifferences = 0;
			NewRow.AmountFA = 0;
			NewRow.AmountExcludingVAT	= 0;
			NewRow.VATAmount	= 0;
			
		EndIf;
		
		NewRow.ProductionLot = CurRow.ProductionLot;
		
	EndDo;
	
	If BatchTable_.Count() > 1 Then
		Object[TSName].Delete(InitialString);
	EndIf;
	
EndProcedure

#EndRegion

&AtServer
Function ConversionFactor_()
	
	Return
		ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
			ManagementAccountingCurrency,
			LocalAccountingCurrency,
			?(Object.Date = Date(1,1,1), CurrentSessionDate(), Object.Date));
	
EndFunction

&AtServer
Procedure UpdateBalancesForActivities(Fill = True)
	
	FillParameters = Documents.WIPOpeningBalancesByProductionLots.ParametersForFillingInVATActivities(Object);
	If Fill Then
		VATAccountingERP.FillInTypeOfActivityVAT(
			Object.VATActivityType,
			FillParameters,
			VATAccountingCachedParameterValues);
	EndIf;
	
	VATAccountingERP.FillInActivitySelectionList(
		Items.VATActivityType,
		Object.VATActivityType,
		FillParameters,
		VATAccountingCachedParameterValues);
	
EndProcedure

&AtServer
Function RulesOfCostAllocationToProductCost()
	
	RulesOfCostAllocationToProductCost = New Map;
	
	// The "Material Costs" rule
	RulesOfCostAllocationToProductCost.Insert(
		Enums.TypesOfCostAllocatingBase.MaterialCostsAmount,
		Enums.RulesOfCostAllocationToProductCost.ByMaterialCosts);
	RulesOfCostAllocationToProductCost.Insert(
		Enums.TypesOfCostAllocatingBase.StandardMaterialConsumption,
		Enums.RulesOfCostAllocationToProductCost.ByMaterialCosts);
	RulesOfCostAllocationToProductCost.Insert(
		Enums.TypesOfCostAllocatingBase.QuantityOfSpecifiedMaterials,
		Enums.RulesOfCostAllocationToProductCost.ByMaterialCosts);
	RulesOfCostAllocationToProductCost.Insert(
		Enums.TypesOfCostAllocatingBase.VolumeOfSpecifiedMaterials,
		Enums.RulesOfCostAllocationToProductCost.ByMaterialCosts);
	RulesOfCostAllocationToProductCost.Insert(
		Enums.TypesOfCostAllocatingBase.WeightOfSpecifiedMaterials,
		Enums.RulesOfCostAllocationToProductCost.ByMaterialCosts);
	
	// The "Labor costs" rule
	RulesOfCostAllocationToProductCost.Insert(
		Enums.TypesOfCostAllocatingBase.TotalPayrollExpenses,
		Enums.RulesOfCostAllocationToProductCost.ByLaborCosts);
	RulesOfCostAllocationToProductCost.Insert(
		Enums.TypesOfCostAllocatingBase.NumberOfWorksOfSpecifiedKinds,
		Enums.RulesOfCostAllocationToProductCost.ByLaborCosts);
	RulesOfCostAllocationToProductCost.Insert(
		Enums.TypesOfCostAllocatingBase.StandardRemunerationLevel,
		Enums.RulesOfCostAllocationToProductCost.ByLaborCosts);
	RulesOfCostAllocationToProductCost.Insert(
		Enums.TypesOfCostAllocatingBase.WorkPerformanceDuration,
		Enums.RulesOfCostAllocationToProductCost.ByLaborCosts);
	
	// The rule "On material labor costs"
	RulesOfCostAllocationToProductCost.Insert(
		Enums.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts,
		Enums.RulesOfCostAllocationToProductCost.ByMaterialAndLaborCosts);
	
	// The rule of "Production accounting of future releases"
	RulesOfCostAllocationToProductCost.Insert(
		Enums.TypesOfCostAllocatingBase.ProductsQuantity,
		Enums.RulesOfCostAllocationToProductCost.ByProductsIncludingFutureReleases);
	RulesOfCostAllocationToProductCost.Insert(
		Enums.TypesOfCostAllocatingBase.ProductsWeight,
		Enums.RulesOfCostAllocationToProductCost.ByProductsIncludingFutureReleases);
	RulesOfCostAllocationToProductCost.Insert(
		Enums.TypesOfCostAllocatingBase.ProductsVolume,
		Enums.RulesOfCostAllocationToProductCost.ByProductsIncludingFutureReleases);
	RulesOfCostAllocationToProductCost.Insert(
		Enums.TypesOfCostAllocatingBase.TargetProductCost,
		Enums.RulesOfCostAllocationToProductCost.ByProductsIncludingFutureReleases);
	RulesOfCostAllocationToProductCost.Insert(
		Enums.TypesOfCostAllocatingBase.ProductsQuantityConsideringFutureReleases,
		Enums.RulesOfCostAllocationToProductCost.ByProductsIncludingFutureReleases);
	RulesOfCostAllocationToProductCost.Insert(
		Enums.TypesOfCostAllocatingBase.ProductsVolumeConsideringFutureReleases,
		Enums.RulesOfCostAllocationToProductCost.ByProductsIncludingFutureReleases);
	RulesOfCostAllocationToProductCost.Insert(
		Enums.TypesOfCostAllocatingBase.ProductsWeightConsideringFutureReleases,
		Enums.RulesOfCostAllocationToProductCost.ByProductsIncludingFutureReleases);
	RulesOfCostAllocationToProductCost.Insert(
		Enums.TypesOfCostAllocatingBase.TargetProductCostConsideringFutureReleases,
		Enums.RulesOfCostAllocationToProductCost.ByProductsIncludingFutureReleases);
	
	Return RulesOfCostAllocationToProductCost;
	
EndFunction

#EndRegion

#Region StandardSubsystems

#Region Properties

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	
	PropertyManager.FillAdditionalAttributesInForm(ThisObject);
	
EndProcedure

#EndRegion

#Region ImportDataFromFile

&AtClient
Procedure ShowUploadFormFromFile(AdditionalParameters)
	
	FullTabularSectionName	= "WIPOpeningBalancesByProductionLots.%1";
	FullTabularSectionName	= StrTemplate(FullTabularSectionName, AdditionalParameters.TSName);
	
	HeaderOfUploadForm	= NStr("vi = 'Kết nhập bảng ''''%1'''' từ tệp';
								|ru = 'Загрузка таблицы ""%1"" из файла';
								|en = 'Download the table ""%1"" from the file'; fa = 'Download the table ""%1"" from the file';
								|it = 'Download della tabella ""%1"" dal file';
								|pl = 'Wczytywanie tabeli „%1” z pliku';
								|tr = 'Dosyadan ""%1"" tablosunun yüklenmesi'");
	HeaderOfUploadForm	= StrTemplate(HeaderOfUploadForm, AdditionalParameters.TSSynonym);
	
	ImportParameters = ImportDataFromFileClient.DataImportParameters();
	ImportParameters.FullTabularSectionName	= FullTabularSectionName;
	ImportParameters.Title					= HeaderOfUploadForm;
	ImportParameters.AdditionalParameters	= AdditionalParameters;
	
	If AdditionalParameters.TSName = "MaterialsAndWorks" Then
		ImportParameters.DataStructureTemplateName = "ImportFromFileMaterialsAndWorks";
	ElsIf AdditionalParameters.TSName = "LaborCosts" Then
		ImportParameters.DataStructureTemplateName = "ImportFromFileLaborCosts";
	Else
		ImportParameters.DataStructureTemplateName = "ImportFromFileOtherExpenses";
	EndIf;
	
	Notification = New CallbackDescription("ShowUploadFormFromFileCompletion", ThisObject, AdditionalParameters);
	ImportDataFromFileClient.ShowImportForm(ImportParameters, Notification);
	
EndProcedure

&AtClient
Procedure ShowUploadFormFromFileCompletion(ImportedDataAddress, AdditionalParameters) Export
	
	If ImportedDataAddress = Undefined Then
		Return;
	EndIf;
	
	UploadFromFileOnServer(ImportedDataAddress, AdditionalParameters);
	
EndProcedure

&AtServer
Procedure UploadFromFileOnServer(ImportedDataAddress, AdditionalParameters)
	
	ImportedData = GetFromTempStorage(ImportedDataAddress);
	Object[AdditionalParameters.TSName].Load(ImportedData);
	
	If AdditionalParameters.TSName = "MaterialsAndWorks"
		Or AdditionalParameters.TSName = "LaborCosts" Then
		FillIsAcceptedByKNUByDefault(AdditionalParameters.TSName);
	ElsIf AdditionalParameters.TSName = "OtherExpenses" Then
		FillInServiceDetailsOfForm();
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountWithoutVAT");
	StructureOfActions.Insert("RecalculateLocalAmount",	FactorOfConversionFromManCurrencyToRegulCurrency);
	
	If AdditionalParameters.TSName = "MaterialsAndWorks" Then
		StructureOfActions.Insert("RecalculateNumberOfUnits",	ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
		StructureOfActions.Insert("RecalculatePriceByAmount",		"NumberOfPackages");
	EndIf;
	
	If AdditionalParameters.TSName = "LaborCosts" Then
		StructureOfActions.Insert("RecalculatePriceByAmount", "Count");
	EndIf;
	
	StructureOfActions.Insert("RecalculatePDAmount",	FactorOfConversionFromManCurrencyToRegulCurrency);
	StructureOfActions.Insert("RecalculateAmountTa");
	StructureOfActions.Insert("RecalculateAmountOfTD");
	
	BatchProcessingOfTablePartServer.TreatTS(Object[AdditionalParameters.TSName], StructureOfActions, Undefined);
	
EndProcedure

#EndRegion

#EndRegion

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
	If Item.Name = "sh_ShamsiInput_Date" Then
		DateOnChange(Items.Date);
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
