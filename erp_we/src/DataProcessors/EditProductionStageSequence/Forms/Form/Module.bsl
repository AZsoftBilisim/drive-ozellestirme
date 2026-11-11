
#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	EmbeddingParameters = DataProcessors.EditProductionStageSequence.AvailableRemainingEmbeddingOptions();
	ProvisionInDocumentsServer.AvailableBalancesWhenCreatedOnServer(ThisObject, EmbeddingParameters);
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Not ValueIsFilled(Parameters.ReferenceOrder) Then
		Raise NStr("vi = 'Để mở biểu mẫu, cần truyền các tham số.';
					|ru = 'Для открытия формы необходимо передать параметры.';
					|en = 'To open the form, pass the parameters.'; fa = 'To open the form, pass the parameters.';
					|it = 'Per l''apertura del modulo è necessario trasferire i parametri.';
					|pl = 'Aby otworzyć formularz, musisz przekazać parametry.';
					|tr = 'Formun açılması için parametreleri transfer etmeniz gerekmektedir.'");
	EndIf;
	
	If Not ValueIsFilled(Parameters.ProductionLot) Then
		If Parameters.Property("Purpose") And Not ValueIsFilled(Parameters.AssignmentProducts) Then
			IsolationScheme = Documents.ProductionOrder2_2.IsolationScheme(
				Parameters.ReferenceOrder,
				Parameters.Purpose);
			Parameters.AssignmentProducts = IsolationScheme.AssignmentProducts;
		EndIf;
	Else
		Parameters.AssignmentProducts = Common.ObjectAttributeValue(Parameters.ProductionLot, "Purpose");
		ProductionBatchBeforeChanging = Parameters.ProductionLot;
	EndIf;
	
	OnReadCreateAtServer();
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisForm);
	
	ItemsAndDimensionsSelectionParameters = DataProcessors.EditProductionStageSequence.ItemsAndDimensionsSelectionParameters(Object);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	SetupParameters = DataProcessors.EditProductionStageSequence.AccountingAccountSettings_();
	GLAccountSettingsServer.OnCreateAtServer(ThisObject, SetupParameters);
	
	BeginningOfAccountingOfLaborCostsForEmployees = Date(1,1,1);
	
	SetAvailabilityOfClipboardCommands(ThisForm, ProcessingOfTabularForms.ThereAreLinesInClipboard());
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	UpdateCachedValuesToAccountForBatchesOfFINISHEDProductBeingRepaired();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Modified Then
		
		SaveAndCloseNotification = New CallbackDescription(
			"BeforeCloseCompletion", ThisObject);
	
		CommonClient.ShowFormClosingConfirmation(
			SaveAndCloseNotification,
			Cancel,
			Exit,
			NStr("vi = 'Dữ liệu đã được thay đổi. Ghi nhận thay đổi?';
				|ru = 'Данные были изменены. Записать изменения?';
				|en = 'Data has changed. Save the changes?'; fa = 'Data has changed. Save the changes?';
				|it = 'I dati sono stati modificati. Registrare le modifiche?';
				|pl = 'Dane zostały zmienione. Zapisać zmiany?';
				|tr = 'Veriler değiştirildi. Değişiklikler kaydedilsin mi?'"));
		
	EndIf;

EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	WriteData(True);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	CheckHeaderDetails_(Cancel);
	CheckProductionProcess(NotCheckedAttributeArray, Cancel);
	
	CheckOutputProducts(NotCheckedAttributeArray, Cancel);
	CheckByProducts(NotCheckedAttributeArray, Cancel);
	
	CheckProvisionOfMaterialsAndWorks(NotCheckedAttributeArray, Cancel);
	
	CheckConsumptionOfMaterialsAndWorks(NotCheckedAttributeArray, Cancel);
	CheckSavingMaterials(NotCheckedAttributeArray, Cancel);
	
	CheckLaborCosts(NotCheckedAttributeArray, Cancel);
	
	If Not Cancel And Not FormAttributeToValue("Object").CheckFilling() Then
		Cancel = True;
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.ProductionStage2_2.Form.DocumentForm.Event.ChoiceProcessing");
	
	If ChoiceSource.FormName = "CommonForm.EnterCostShare" Then
		
		ProcessingInputOfFractionOfCost(CurrentItem.CurrentData, ValueSelected);
		
	ElsIf ChoiceSource.FormName = "Document.EngineeringChangeOrder.Form.SubstitutionOfMaterialsWithAlternativeMaterials" Then
		
		Replace_With_Analogues(ValueSelected.AddressInStorage);
		
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters[ValueSelected.TSName], ValueSelected);
		
	ElsIf ChoiceSource.FormName = "Catalog.BillsOfMaterials.Form.SelectMaterialsByBOM" Then
		
		StartProcessingSelectionResult(ValueSelected, "SelectMaterialsByBOM");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "CopyingLinesToClipboard" Then
		
		SetAvailabilityOfClipboardCommands(ThisForm, True);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	// Output items - canceling lines
	FinishedProductsHideCanceledLines =  Settings.Get("FinishedProductsHideCanceledLines");
	
	If FinishedProductsHideCanceledLines Then
		Items.ManufacturedProducts.RowFilter = New FixedStructure("Canceled", False);
	Else
		Items.ManufacturedProducts.RowFilter = Undefined;
	EndIf;
	
	Items.OutputItemsHideCanceledLines.Check = FinishedProductsHideCanceledLines;
	
	// By-products - cancellation of lines
	SideProductsHideCanceledLines =  Settings.Get("SideProductsHideCanceledLines");
	
	If SideProductsHideCanceledLines Then
		Items.SideAndIntermediateRelease.RowFilter = New FixedStructure("Canceled", False);
	Else
		Items.SideAndIntermediateRelease.RowFilter = Undefined;
	EndIf;
	
	Items.SideItemsHideCanceledLines.Check = SideProductsHideCanceledLines;
	
	// Provision of materials and works - cancellation of lines
	FulfillmentHideCanceledLines =  Settings.Get("FulfillmentHideCanceledLines");
	
	If FulfillmentHideCanceledLines Then
		Items.SupplyWithMaterialsAndWorks.RowFilter = New FixedStructure("Canceled", False);
	Else
		Items.SupplyWithMaterialsAndWorks.RowFilter = Undefined;
	EndIf;
	
	Items.SoftwareToHideCancelledLines.Check = FulfillmentHideCanceledLines;
	
	// Labor costs - cancellation of lines
	LaborCostsHideCanceledLines =  Settings.Get("LaborCostsHideCanceledLines");
	
	If LaborCostsHideCanceledLines Then
		Items.LaborCosts.RowFilter = New FixedStructure("Canceled", False);
	Else
		Items.LaborCosts.RowFilter = Undefined;
	EndIf;
	
	Items.LaborCosts_HideCanceledRows.Check = LaborCostsHideCanceledLines;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	If Object.BillOfMaterials.IsEmpty() Then
		If ShowStandardsMaterials Then
			ShowStandardsMaterials = False;
		EndIf;
		If ShowStandardsLaborCosts Then
			ShowStandardsLaborCosts = False;
		EndIf;
	EndIf;
	
	AttributesList = "";
	
	If ShowStandardsMaterials Or ShowStandardsLaborCosts Then
		If ShowStandardsMaterials
				And Object.SupplyWithMaterialsAndWorks.Count() > 0
			Or ShowStandardsLaborCosts
				And Object.LaborCosts.Count() > 0 Then
			ShowStandardsWhenChangingOnServer();
		Else
			AttributesList = 
				AttributesList + ?(ValueIsFilled(AttributesList), ",", "") + "ShowStandards";
		EndIf;
	EndIf;
	
	If RightToReadSubstitutes And ShowAnalogues Then
		
		AttributesList = 
			AttributesList + ?(ValueIsFilled(AttributesList), ",", "") + "ShowAnalogues";
			
		NotePresenceOfAnalogues();
		
	EndIf;
	
	If ValueIsFilled(AttributesList) Then
		ConfigureDependentFormElements(ThisForm, AttributesList);	
	EndIf;	
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ProductsOnChange(Item)
	
	WhenChangingMainProduct();
	
EndProcedure

&AtClient
Procedure CharacteristicOnChange(Item)
	
	WhenChangingMainProduct();
	
EndProcedure

&AtClient
Procedure HelpTextMainProductURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "GoToRelease" Then
		
		Items.Pages.CurrentPage = Items.OutputProductsPage;
		
		Rows = Object.ManufacturedProducts.FindRows(New Structure("Products", Object.MainProductProducts));
		If Rows.Count() > 0 Then
			Items.ManufacturedProducts.CurrentRow = Rows[0].GetID();
		EndIf;
		
		Return;
		
	EndIf;
	
	If FormattedStringURL = "GoToSupply" Then
		
		Items.Pages.CurrentPage = Items.PageProvidingMaterialsAndWorks;
		
		Rows = Object.SupplyWithMaterialsAndWorks.FindRows(New Structure("Products", Object.MainProductProducts));
		If Rows.Count() > 0 Then
			Items.SupplyWithMaterialsAndWorks.CurrentRow = Rows[0].GetID();
		EndIf;
		
		Return;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure HyperlinkLabelProductsClick(Item)
	
	ProductsCollapsed = Not ProductsCollapsed;
	
	SetPropertiesOfCollapsibleGroup(
		Items.GroupFinishedProducts,
		Items.HyperlinkLabelProducts, 
		ProductsCollapsed);
	
EndProcedure

&AtClient
Procedure HyperLinkLabelSideProductsClick(Item)
	
	SideProductsAreCollapsed = Not SideProductsAreCollapsed;
	
	SetPropertiesOfCollapsibleGroup(
		Items.SideAndIntermediateRelease, 
		Items.HyperLinkLabelSideProducts, 
		SideProductsAreCollapsed);
	
EndProcedure

&AtClient
Procedure HyperLinkLabelConsumptionOfMaterialsAndWorksClick(Item)
	
	ConsumedMaterialsAreCollapsed = Not ConsumedMaterialsAreCollapsed;
	
	SetPropertiesOfCollapsibleGroup(
		Items.MaterialsAndWorksConsumption, 
		Items.HyperLinkLabelConsumptionOfMaterialsAndWorks, 
		ConsumedMaterialsAreCollapsed);
	
EndProcedure

&AtClient
Procedure HyperLinkLabelPSavingMaterialsClick(Item)
	
	UnspentMaterialsAreCollapsed = Not UnspentMaterialsAreCollapsed;
	
	SetPropertiesOfCollapsibleGroup(
		Items.UnusedMaterials, 
		Items.HyperLinkLabelPSavingMaterials, 
		UnspentMaterialsAreCollapsed);
	
EndProcedure

&AtClient
Procedure MethodOfAllocatingFinishedProductCostsOnChange(Item)
	
	WhenChangingMethodOfDistributionOfCostsForOutputProducts();
	
EndProcedure

&AtClient
Procedure UnderRepairProductOnChange(Item)
	
	FinishedProductToBeRepairedItemOnChangeATServer(CachedValues);
	UpdateCachedValuesToAccountForBatchesOfFINISHEDProductBeingRepaired();
	
EndProcedure

&AtClient
Procedure UnderRepairVariantOnChange(Item)
	
	DataStructureOfFinishedProductBeingRepaired = ProductionManagementClientServer.DataOfFinishedProductBeingRepairedByStructure(Object);
	
	If ProductsClient.YouNeedToUpdateStatusOfSeriesInHeader(
			DataStructureOfFinishedProductBeingRepaired, CachedValues, SeriesSpecificationParameters.FinishedProductBeingRepaired) Then
		FillInBatchIndicationStatusesONChangesOfFinishedProductBeingRepaired(CachedValues, DataStructureOfFinishedProductBeingRepaired);
		UpdateCachedValuesToAccountForBatchesOfFINISHEDProductBeingRepaired(DataStructureOfFinishedProductBeingRepaired);
	EndIf;
	
EndProcedure

&AtClient
Procedure UnderRepairBatchOnChange(Item)
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	ValueSelected.Value = Object.UnderRepairBatch;
	
	ProcessIndicationOfBatchOfFINISHEDProductBeingRepaired(ValueSelected);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersStages

&AtClient
Procedure StagesSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.Stages.CurrentData;
	
	If CurrentData.IsNew Then
		Return;
	EndIf;
	
	If (Field.Name = Items.StagesStageNumber.Name
		Or Field.Name = Items.StagesNextStageNo.Name) Then
		Return;
	EndIf;
	
	If CurrentData.UseOperationManagement
		And (Field.Name = Items.StagesRouteSheet.Name
		Or Field.Name = Items.StagesRouteSheetFactor.Name) Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	ShowValue(, CurrentData.Ref);
	
EndProcedure

&AtClient
Procedure StagesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	If Copy Then
		Cancel = True;
		Return;
	EndIf;
	
	CheckBlockDocuments(Cancel);
	
EndProcedure

&AtClient
Procedure StagesBeforeRowChange(Item, Cancel)
	
	CheckBlockDocuments(Cancel);
	
EndProcedure

&AtClient
Procedure StagesBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	If Not CheckBlockDocuments(Cancel) Then
		Return;
	EndIf;
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.Stages);
	
	If SelectedRows.UBound() = -1 Then
		Return;
	EndIf;
	
	If ItIsRequiredToAskQuestionBeforeDeletingStages(SelectedRows) Then
		
		AskQuestionBeforeDeletingStages(SelectedRows);
		Return;
		
	EndIf;
	
	RemoveStagesFromList(SelectedRows);
	
EndProcedure

&AtClient
Procedure StagesOnStartEdit(Item, NewRow, Copy)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Stages, ThisObject);
	
	If NewRow Then
		
		AddNewDocument(Items.Stages.CurrentRow);
		
	EndIf;
	
	ConfigureDependentFormElements(ThisForm, "ManufacturingProcess");
	
EndProcedure
 
&AtClient
Procedure StagesOnEditEnd(Item, NewRow, CancelEdit)
	
	If CancelEdit Then
		Return;
	EndIf;
	
	CurrentData = Items.Stages.CurrentData;
	LineCache = ProcessingOfTabularFormsClientServer.LineCache(Items.Stages, ThisObject);
	
	If (LineCache.Department <> CurrentData.Department
			Or LineCache.NameEdit <> CurrentData.NameEdit
			Or NewRow) Then
		FillInServiceDetailsWhenChangingProductionProcess(CurrentData.Ref);
	EndIf;
	
	FillInDefaultLink();
	
EndProcedure

&AtClient
Procedure StagesRouteSheetOnChange(Item)
	
	CurrentData = Items.Stages.CurrentData;
	
	If CurrentData.TechnologicalProcess.IsEmpty() Then
		
		CurrentData.TechnologicalProcessFactor = 0;
		
	ElsIf CurrentData.TechnologicalProcessFactor = 0 Then
		
		CurrentData.TechnologicalProcessFactor = 1;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure StagesPackagePlanOnChange(Item)
	
	CurrentData = Items.Stages.CurrentData;
	
	If CurrentData.IsNew Then
		CurrentData.PackageActualData = CurrentData.PackagePlan;
		CurrentData.PackageCanceled = CurrentData.PackagePlan;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersManufacturedProducts

&AtClient
Procedure ManufacturedProductsOnChange(Item)
	
	ConfigureDependentFormElements(ThisForm, "ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure ManufacturedProductsSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	
	If ReadOnly Or CurrentData.ReadOnly Then
		StandardProcessing = False;
		Return;
	EndIf;
	
	If Not CheckBlockDocuments() Then
		StandardProcessing = False;
		Return;
	EndIf;
	
	If (Field = Items.ManufacturedProductsCostSharePercentage
			Or Field = Items.ManufacturedProductsThereAreErrorsOfFillingInCostShare)
		And MethodOfAllocatingFinishedProductCosts <> PredefinedValue("Enum.MethodsOfCostAllocatingOnProductCosts.ByCostShares") Then
		StandardProcessing = False;
		OpenCostShareEntryForm(CurrentData);
	EndIf;
	
	If (Field = Items.ManufacturedProductsSeries 
			Or Field = Items.ManufacturedProductsBatchesIndicationStatus)
		And CurrentData.BatchesIndicationStatus > 0
		And CurrentData.BatchesIndicationStatus <= 11 Then
		OpenSelectionOfSeries("ManufacturedProducts");
	EndIf;
	
	GLAccountSettingsClient.OnClick(ThisObject, Field, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	If Not CheckBlockDocuments(Cancel) Then
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure ManufacturedProductsBeforeRowChange(Item, Cancel)
	
	If Not CheckBlockDocuments(Cancel) Then
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure ManufacturedProductsBeforeDeleteRow(Item, Cancel)
	
	If Not CheckRowsOfTablePartBeforeDeleting("ManufacturedProducts", Cancel) Then
		Return;
	EndIf;
	If Not CheckBlockDocuments(Cancel) Then
		Return;
	EndIf;
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters.ManufacturedProducts);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	
	ProcessingLineAtBeginningOfEditing("ManufacturedProducts", NewRow, Copy);
	
	If NewRow Then
		CurrentData.Manufactured = False;
		FillInProductionDateInLine(CurrentData);
		
		If Copy Then
			// Setting up accounting accounts.
			GLAccountSettingsClient.WhenCopyingString(ThisObject, Item);
		EndIf;
	EndIf;
	
	ProductionManagementClient.OutputProductsOfStageAtBeginningOfEditing(
				ThisForm, CurrentData, "ManufacturedProducts", NewRow, Copy); 
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.ManufacturedProducts, ThisObject);
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(
				Item,CachedValues,SeriesSpecificationParameters.ManufacturedProducts, Copy);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsOnEditEnd(Item, NewRow, CancelEdit)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	
	UpdateSeriesStatuses = ProductsClient.SeriesStatusesNeedToBeUpdated(
		Item,
		CachedValues,
		SeriesSpecificationParameters.ManufacturedProducts);
	
	CalculatePercentageOfCostAllocation = ProductionClient.ItIsNecessaryToCalculatePercentageOfDistributionOfCostsForOutputProducts(
		Item,
		CostAllocationParameters,
		ProcessingOfTabularFormsClientServer.LineCache(Items.ManufacturedProducts, ThisObject),
		NewRow);
	
	UpdateAppointmentSettings = ProductionSupplyClientServer.ItIsNecessaryToUpdateParametersForFillingAssignmentsWhenChangingProducts(
		ObjectIsCreatedByReference(ThisForm, CurrentData.Ref),
		CurrentData,
		ProcessingOfTabularFormsClientServer.LineCache(Items.ManufacturedProducts, ThisObject));
	
	If UpdateSeriesStatuses
		Or CalculatePercentageOfCostAllocation
		Or UpdateAppointmentSettings Then
			
		OutputItemsAtEndOfEditingOnServer(
			CurrentData.GetID(),
			CachedValues,
			UpdateSeriesStatuses,
			CalculatePercentageOfCostAllocation,
			UpdateAppointmentSettings);
		
	EndIf;
	
	If UpdateSeriesStatuses Then
		ProductsClient.UpdateCachedValuesToAccountForSeries(
			Item,
			CachedValues,
			SeriesSpecificationParameters.ManufacturedProducts);
	EndIf;
	
	If NewRow And CancelEdit Then
		ConfigureDependentFormElements(ThisForm, "ManufacturedProducts");
	EndIf;
	
EndProcedure

&AtServer
Procedure OutputItemsAtEndOfEditingOnServer(RowID, CachedValues, UpdateSeriesStatuses, CalculatePercentageOfCostAllocation, UpdateAppointmentSettings)
	
	If UpdateSeriesStatuses Then
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(
			"ManufacturedProducts",
			RowID,
			CachedValues);
	EndIf;
	
	If CalculatePercentageOfCostAllocation Then
		CalculatePercentageOfCostAllocationForOutputProducts();
	EndIf;
	
	If UpdateAppointmentSettings Then
		FillInAssignmentSelectionParameters();
	EndIf;
	
EndProcedure

&AtClient
Procedure ManufacturedProductsAfterDeleteRow(Item)
	
	AfterRemovingTSRowsForWhichThereIsSeries("ManufacturedProducts", Item);
	OutputProductsAfterDeletionOnServer();
	
EndProcedure

&AtServer
Procedure OutputProductsAfterDeletionOnServer()
	
	CalculatePercentageOfCostAllocationForOutputProducts();
	FillInAssignmentSelectionParameters();
	
EndProcedure

&AtClient
Procedure ManufacturedProductsProductsOnChange(Item)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	WhenChangingProducts(CurrentData, "ManufacturedProducts");

EndProcedure

&AtClient
Procedure ManufacturedProductsCharacteristicOnChange(Item)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	WhenChangingCharacteristics(CurrentData, "ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure ManufacturedProductsSeriesOnChange(Item)
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value            		 = Items.ManufacturedProducts.CurrentData.Series;
	ValueSelected.CurrentRowID = Items.ManufacturedProducts.CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters.ManufacturedProducts, ValueSelected);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenSelectionOfSeries("ManufacturedProducts", Item.EditText);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsNumberOfPackagesOnChange(Item)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	StructureOfActions.Insert("RecalculateCostShare", CostAllocationParameters);
	If CurrentData.UseTargetCost Then
		StructureOfActions.Insert("RecalculateAmount");
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsPriceOnChange(Item)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	ProductionManagementClient.ProductsOfStagePriceWhenChanging(CurrentData, CachedValues);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsSumOnChange(Item)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	ProductionManagementClient.ItemsOfAmountStageWhenChanged(CurrentData, CachedValues);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsPackageOnChange(Item)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	
	StructureOfActions = New Structure;
	
	If CurrentData.UseTargetCost Then
		
		If CurrentData.Count > 0 Then
			StructureOfActions.Insert("RecalculatePricePerPackage", CurrentData.Count);
		Else
			StructureOfActions.Insert("CheckFillIssuePrice", ParametersForFillingIssuePrices(ThisForm));
		EndIf;
		
		StructureOfActions.Insert("RecalculateAmount");
	
	EndIf;
	
	StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	StructureOfActions.Insert("RecalculateCostShare", CostAllocationParameters);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsManufacturedOnChange(Item)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	
	ObjectStage = ObjectIsCreatedByReference(ThisForm, CurrentData.Ref);
	CheckHandleChangeOfProgressMark(ObjectStage, CurrentData.Manufactured);
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("SetFlagForUsingPlannedCost",
		New Structure("Organization", Object.Organization));
	StructureOfActions.Insert("CheckFillIssuePrice", ParametersForFillingIssuePrices(ObjectStage));
	StructureOfActions.Insert("RecalculateAmount");
	
	AddActionFillProductionDate(CurrentData, StructureOfActions);
	
	SeriesVerificationParameters = New Structure;
	SeriesVerificationParameters.Insert("Warehouse", CurrentData.Recipient);
	SeriesVerificationParameters.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters.ManufacturedProducts);
	
	StructureOfActions.Insert("CheckSeriesCalculateStatus", SeriesVerificationParameters);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsProductionDateOnChange(Item)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	
	ObjectStage = ObjectIsCreatedByReference(ThisForm, CurrentData.Ref);

	StructureOfActions = New Structure;
	StructureOfActions.Insert("SetFlagForUsingPlannedCost",
		New Structure("Organization", Object.Organization));
	StructureOfActions.Insert("CheckFillIssuePrice", ParametersForFillingIssuePrices(ObjectStage));
	StructureOfActions.Insert("RecalculateAmount");
	AddQualityControlActionsToStructure("ManufacturedProducts", StructureOfActions, CacheQualityControl);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsDirectionOfProductionIssueOnChange(Item)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	WhenChangingDirectionOfRelease(CurrentData, "ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure ManufacturedProductsRecipientOnChange(Item)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	WhenChangingRecipient(CurrentData, "ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure ManufacturedProductsExpenseItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsDimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsProcessByBOMOnChange(Item)
	
	ProcessBySpecificationWhenModified("ManufacturedProducts", Items.ManufacturedProducts.CurrentData);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsStageConsumerStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	ConsumerStageBeginningOfChoice(CurrentData, "ManufacturedProducts")
	
EndProcedure

&AtClient
Procedure ManufacturedProductsToControlQualityOnChange(Item)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	If Not CurrentData.ToControlQuality Then
		CurrentData.QualityConfirmationDate = '00010101';
	EndIf;
	
EndProcedure

&AtClient
Procedure ManufacturedProductsQualityConfirmationDateOnChange(Item)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	If Not CurrentData.ToControlQuality Then
		CurrentData.QualityConfirmationDate = '00010101';
	EndIf;
	
EndProcedure

&AtClient
Procedure ManufacturedProductsCanceledOnChange(Item)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	ItemsCanceledWhenModified("ManufacturedProducts", CurrentData);
	
EndProcedure

&AtClient
Procedure TheOutputProductsIsTheLinkToTheEditStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	ProcessStartOfProductionStageSelectionInLine("ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure TheOutputProductsIsTheLinkToTheEditClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	ClearProductionStageInLine("ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure ManufacturedProductsPurposeOnChange(Item)
	
	StructureOfActions = New Structure;
	
	
	If ValueIsFilled(StructureOfActions) Then
	
		CurrentData = Items.ManufacturedProducts.CurrentData;
			
		ValuesInCache = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, ValuesInCache);
		
	EndIf;	
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSideAndIntermediateRelease

&AtClient
Procedure SideAndIntermediateReleaseOnChange(Item)
	
	ConfigureDependentFormElements(ThisForm, "SideAndIntermediateRelease");
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.SideAndIntermediateRelease.CurrentData;
	
	If ReadOnly Or CurrentData.ReadOnly Then
		StandardProcessing = False;
		Return;
	EndIf;
	
	If Not CheckBlockDocuments() Then
		StandardProcessing = False;
		Return;
	EndIf;
	
	If (Field = Items.SideAndIntermediateReleaseSeries 
			Or Field = Items.SideAndIntermediateReleaseBatchesIndicationStatus)
		And CurrentData.BatchesIndicationStatus > 0
		And CurrentData.BatchesIndicationStatus <= 11 Then
		OpenSelectionOfSeries("SideAndIntermediateRelease");
	EndIf;
	
	GLAccountSettingsClient.OnClick(ThisObject, Field, StandardProcessing);
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	If Not CheckBlockDocuments(Cancel) Then
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseBeforeRowChange(Item, Cancel)
	
	If Not CheckBlockDocuments(Cancel) Then
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseBeforeDeleteRow(Item, Cancel)
	
	If Not CheckRowsOfTablePartBeforeDeleting("SideAndIntermediateRelease", Cancel) Then
		Return;
	EndIf;
	If Not CheckBlockDocuments(Cancel) Then
		Return;
	EndIf;
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(Item,CachedValues,SeriesSpecificationParameters.SideAndIntermediateRelease);
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.SideAndIntermediateRelease.CurrentData;
	
	ProcessingLineAtBeginningOfEditing("SideAndIntermediateRelease", NewRow, Copy);
	
	If NewRow Then
		
		CurrentData.Manufactured = False;
		FillInProductionDateInLine(CurrentData);
		
		If Copy Then
			// Setting up accounting accounts.
			GLAccountSettingsClient.WhenCopyingString(ThisObject, Item);
		EndIf;
		
		StructureOfActions = New Structure;
		InternalSubcontractingClientServer.AddActionFillInItemOwnerIsAvailable(ThisObject, StructureOfActions);
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
		
	EndIf;
	
	ProductionManagementClient.OutputProductsOfStageAtBeginningOfEditing(
				ThisObject, CurrentData, "SideAndIntermediateRelease", NewRow, Copy); 
	
	FillInSelectionListOfProductOwners(ThisObject);
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.SideAndIntermediateRelease, ThisObject);
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(
				Item,CachedValues,SeriesSpecificationParameters.SideAndIntermediateRelease, Copy);
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseOnEditEnd(Item, NewRow, CancelEdit)
	
	CurrentData = Items.SideAndIntermediateRelease.CurrentData;
	
	If ProductsClient.SeriesStatusesNeedToBeUpdated(
		Item,CachedValues,SeriesSpecificationParameters.SideAndIntermediateRelease) Then
		
		IDCurrentRow = CurrentData.GetID();
		
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS("SideAndIntermediateRelease", IDCurrentRow, CachedValues);
		ProductsClient.UpdateCachedValuesToAccountForSeries(Item,CachedValues,SeriesSpecificationParameters.SideAndIntermediateRelease);
		
	EndIf;
	
	If NewRow And CancelEdit Then
		ConfigureDependentFormElements(ThisForm, "SideAndIntermediateRelease");
	EndIf;
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseAfterDeleteRow(Item)
	
	AfterRemovingTSRowsForWhichThereIsSeries("SideAndIntermediateRelease", Item);
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseProductsOnChange(Item)
	
	CurrentData = Items.SideAndIntermediateRelease.CurrentData;
	WhenChangingProducts(CurrentData, "SideAndIntermediateRelease");

EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseCharacteristicOnChange(Item)
	
	CurrentData = Items.SideAndIntermediateRelease.CurrentData;
	WhenChangingCharacteristics(CurrentData, "SideAndIntermediateRelease");
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseSeriesOnChange(Item)
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value            		 = Items.SideAndIntermediateRelease.CurrentData.Series;
	ValueSelected.CurrentRowID = Items.SideAndIntermediateRelease.CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters.SideAndIntermediateRelease, ValueSelected);
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenSelectionOfSeries("SideAndIntermediateRelease", Item.EditText);
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseNumberOfPackagesOnChange(Item)
	
	CurrentData = Items.SideAndIntermediateRelease.CurrentData;
	WhenChangingNumberOfPackages(CurrentData, "SideAndIntermediateRelease");
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleasePackageOnChange(Item)
	
	CurrentData = Items.SideAndIntermediateRelease.CurrentData;
	
	ObjectStage = ObjectIsCreatedByReference(ThisForm, CurrentData.Ref);
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	
	If CurrentData.Count > 0 Then
		StructureOfActions.Insert("RecalculatePricePerPackage", CurrentData.Count);
	Else
		StructureOfActions.Insert("CheckFillIssuePrice", ParametersForFillingIssuePrices(ObjectStage));
	EndIf;
	
	StructureOfActions.Insert("RecalculateAmount");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseManufacturedOnChange(Item)
	
	CurrentData = Items.SideAndIntermediateRelease.CurrentData;
	
	ObjectStage = ObjectIsCreatedByReference(ThisForm, CurrentData.Ref);
	CheckHandleChangeOfProgressMark(ObjectStage, CurrentData.Manufactured);
	
	StructureOfActions = New Structure;
	
	AddActionFillProductionDate(CurrentData, StructureOfActions);
	
	SeriesVerificationParameters = New Structure;
	SeriesVerificationParameters.Insert("Warehouse", CurrentData.Recipient);
	SeriesVerificationParameters.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters.SideAndIntermediateRelease);
	StructureOfActions.Insert("CheckSeriesCalculateStatus", SeriesVerificationParameters);
	
	StructureOfActions.Insert("CheckFillIssuePrice", ParametersForFillingIssuePrices(ObjectStage));
	StructureOfActions.Insert("RecalculateAmount");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleasePriceOnChange(Item)
	
	CurrentData = Items.SideAndIntermediateRelease.CurrentData;
	ProductionManagementClient.ProductsOfStagePriceWhenChanging(CurrentData, CachedValues);
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseSumOnChange(Item)
	
	CurrentData = Items.SideAndIntermediateRelease.CurrentData;
	ProductionManagementClient.ItemsOfAmountStageWhenChanged(CurrentData, CachedValues);
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseProductionDateOnChange(Item)
	
	CurrentData = Items.SideAndIntermediateRelease.CurrentData;
	
	StructureOfActions = New Structure;
	AddQualityControlActionsToStructure("SideAndIntermediateRelease", StructureOfActions, CacheQualityControl);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseDirectionOfProductionIssueOnChange(Item)
	
	CurrentData = Items.SideAndIntermediateRelease.CurrentData;
	WhenChangingDirectionOfRelease(CurrentData, "SideAndIntermediateRelease");
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseRecipientOnChange(Item)
	
	CurrentData = Items.SideAndIntermediateRelease.CurrentData;
	WhenChangingRecipient(CurrentData, "SideAndIntermediateRelease");
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseExpenseItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseDimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseProcessByBOMOnChange(Item)
	
	ProcessBySpecificationWhenModified("SideAndIntermediateRelease", Items.SideAndIntermediateRelease.CurrentData);
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseStageConsumerStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.SideAndIntermediateRelease.CurrentData;
	ConsumerStageBeginningOfChoice(CurrentData, "SideAndIntermediateRelease")
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseToControlQualityOnChange(Item)
	
	CurrentData = Items.SideAndIntermediateRelease.CurrentData;
	If Not CurrentData.ToControlQuality Then
		CurrentData.QualityConfirmationDate = '00010101';
	EndIf;
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseQualityConfirmationDateOnChange(Item)
	
	CurrentData = Items.SideAndIntermediateRelease.CurrentData;
	If Not CurrentData.ToControlQuality Then
		CurrentData.QualityConfirmationDate = '00010101';
	EndIf;
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseCanceledOnChange(Item)
	
	CurrentData = Items.SideAndIntermediateRelease.CurrentData;
	ItemsCanceledWhenModified("SideAndIntermediateRelease", CurrentData);
	
EndProcedure

&AtClient
Procedure SideOfTheProductLinkTheEditStartChoice(Item, ChoiceData, StandardProcessing)

	StandardProcessing = False;
	ProcessStartOfProductionStageSelectionInLine("SideAndIntermediateRelease");
	
EndProcedure

&AtClient
Procedure SideOfTheProductLinkTheEditClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	ClearProductionStageInLine("SideAndIntermediateRelease");
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleasePurposeOnChange(Item)

	StructureOfActions = New Structure;
	
	
	InternalSubcontractingClientServer.AddActionFillInItemOwnerIsAvailable(ThisObject, StructureOfActions);
	
	If ValueIsFilled(StructureOfActions) Then
	
		CurrentData = Items.SideAndIntermediateRelease.CurrentData;
			
		ValuesInCache = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, ValuesInCache);
		
	EndIf;	
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSupplyWithMaterialsAndWorks

&AtClient
Procedure SupplyWithMaterialsAndWorksSelection(Item, RowSelected, Field, StandardProcessing)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(
		True, "Document.ProductionStage2_2.Form.DocumentForm.Items.SupplyWithMaterialsAndWorks.Selection");
	
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	
	If Field = Items.SupplyWithMaterialsAndWorksAvailable And Not ReadOnly And Not CurrentData.ReadOnly Then
		
		StandardProcessing = False;
		ProvidingMaterialsAndWorksSelectionIsAvailable(CurrentData);
		
	ElsIf Field = Items.SupplyWithMaterialsAndWorksThereAreSubstituteMaterials 
			And Not ReadOnly And Not CurrentData.ReadOnly And Not CurrentData.WorkPlanning Then
		
		StandardProcessing = False;
		
		If Not CheckBlockDocuments() Then
			Return;
		EndIf;
		
		OpenSelectionOfAnalogues();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksOnChange(Item)
	
	ConfigureDependentFormElements(ThisForm, "SupplyWithMaterialsAndWorks")
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	If Not CheckBlockDocuments(Cancel) Then
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksBeforeRowChange(Item, Cancel)
	
	If Not CheckBlockDocuments(Cancel) Then
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksOnStartEdit(Item, NewRow, Copy)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.SupplyWithMaterialsAndWorks, ThisObject);
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	
	ProcessingLineAtBeginningOfEditing("SupplyWithMaterialsAndWorks", NewRow, Copy);
	
	ProductionManagementClient.ProvisionOfMaterialsAndWorksOfStageAtBeginningOfEditing(
		ThisForm,
		CurrentData,
		NewRow,
		Copy);
	
	WarehousesClient.UpdateCachedValues(
		Item, 
		CachedValues, 
		SeriesSpecificationParameters.SupplyWithMaterialsAndWorks, 
		Copy);
	
	StructureOfActions = New Structure();
	
	ProvisionInDocumentsClientServer.AddCollateralActions(
		StructureOfActions,
		"Available",
		DocumentParametersForSoftwareActions(ThisObject));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	If NewRow Then
		ProductDataManagementClient.ClearSetDetailsInLine(CurrentData);
	EndIf;
	
	FillInListOfSelectedSecurityAppointments();
	SetSelectionByTypeOfSupplyItem();
	UpdateSupplyBillofMaterialsItemSelectionParameters();
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksOnEditEnd(Item, NewRow, CancelEdit)
	
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	
	If ShowStandardsMaterials And CurrentData <> Undefined Then
		
		DataArray = New Array;
		RowData = New Structure("Stage,Products,Characteristic,ItemVariantsAreUsed,Package");
		FillPropertyValues(RowData, CurrentData);
		DataArray.Add(RowData);
		Standards = GetStandardsWhenChangingRows("SupplyWithMaterialsAndWorks", DataArray, StorageAddressStandards);
		CurrentData.NormativeStandard = Standards[0];
		
	EndIf;
	
	If NewRow And CancelEdit Then
		ConfigureDependentFormElements(ThisForm, "SupplyWithMaterialsAndWorks");
	EndIf;
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksBeforeDeleteRow(Item, Cancel)
	
	If Not CheckRowsOfTablePartBeforeDeleting("SupplyWithMaterialsAndWorks", Cancel) Then
		Return;
	EndIf;
	If Not CheckBlockDocuments(Cancel) Then
		Return;
	EndIf;
	
	BeforeDeletingRowsIncludedInSets();
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(Item,CachedValues,SeriesSpecificationParameters.SupplyWithMaterialsAndWorks);

EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksAfterDeleteRow(Item)
	
	ProvisionInDocumentsClientServer.FillInServiceDetails(
			Object.SupplyWithMaterialsAndWorks, 
			DateOfShipmentRequired_, 
			WarehouseIsRequired);
			
	SupplyWithMaterialsAndWorksAfterDeleteRowServer();
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksOnActivateRow(Item)
	
	AttachIdleHandler("ProcessActivationOfSupplyLine", 0.1, True)
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksProductsOnChange(Item)
	
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	WhenChangingProducts(CurrentData, "SupplyWithMaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksCharacteristicOnChange(Item)
	
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	WhenChangingCharacteristics(CurrentData, "SupplyWithMaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksPackageOnChange(Item)
	
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	
	ProvisionInDocumentsClientServer.AddCollateralActions(
		StructureOfActions,
		"AvailableInOtherLines",
		DocumentParametersForSoftwareActions(ThisObject));
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksNumberOfPackagesOnChange(Item)
	
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	WhenChangingNumberOfPackages(CurrentData, "SupplyWithMaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksSeriesOnChange(Item)
	
	CurrentRow = Items.SupplyWithMaterialsAndWorks.CurrentData;
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	ValueSelected.Value                   = CurrentRow.Series;
	ValueSelected.CurrentRowID = CurrentRow.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters.SupplyWithMaterialsAndWorks, ValueSelected);
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenSelectionOfSeries("SupplyWithMaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksWarehouseOnChange(Item)
	
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	
	StructureOfActions = ProductionManagementClient.ProvisionOfMaterialsAndWorksForWarehouseStageInCaseOfChanges(
		ThisObject,
		CurrentData,
		SeriesSpecificationParameters.SupplyWithMaterialsAndWorks,
		CachedValues);
		
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
		
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksProducedOnChange(Item)
	
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	CurrentData.BillOfMaterials = Undefined;
	
	ObjectStage = ObjectIsCreatedByReference(ThisObject, CurrentData.Ref);
	
	StructureOfActions = New Structure();
	
	AddCheckActionFillInSpecification(ThisObject, StructureOfActions, CurrentData);
	
	StructureOfActions.Insert(
		"FillInPurposeOfProvisionInProductionPhase",
		ObjectStage.ParametersForFillingAssignments);
		
	MethodParameters = New Structure();
	MethodParameters.Insert("ProductionOrder",    ObjectStage.ReferenceOrder);
	MethodParameters.Insert("Department",          ObjectStage.Department);
	MethodParameters.Insert("Ref",                 ObjectStage.Ref);
	MethodParameters.Insert("Status",                 ObjectStage.Status);
	MethodParameters.Insert("SubcontractOrder",     ObjectStage.SubcontractOrder);
	MethodParameters.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters.SupplyWithMaterialsAndWorks);
	MethodParameters.Insert("Form",                  ThisObject);
	
	ProductionManagementClientServer.AddToStructureActionsCheckSoftwareInProductionPhase(
		StructureOfActions,
		MethodParameters);
	
	ProvisionInDocumentsClientServer.AddCollateralActions(
		StructureOfActions,
		"AvailableInOtherLines",
		DocumentParametersForSoftwareActions(ThisObject));
		
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	
	FillInSecurityAssignmentEdit(CurrentData);
	
EndProcedure

&AtClient
Procedure ProvidingMaterialsAndWorksLinkEditingStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	ProcessStartOfProductionStageSelectionInLine("SupplyWithMaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure ProvidingMaterialsAndWorksLinkEditingClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	ClearProductionStageInLine("SupplyWithMaterialsAndWorks");
	
	FillInListOfSelectedSecurityAppointments();
	SetSelectionByTypeOfSupplyItem();
	UpdateSupplyBillofMaterialsItemSelectionParameters();
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksCanceledOnChange(Item)
	
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	
	If Not CurrentData.Canceled Then
		CurrentData.CancellationReason = PredefinedValue("Catalog.ReasonsForProductionCancellation.EmptyRef");
	EndIf;
	
	SeriesVerificationParameters = New Structure;
	SeriesVerificationParameters.Insert("Warehouse", CurrentData.Warehouse);
	SeriesVerificationParameters.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters.SupplyWithMaterialsAndWorks);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckSeriesCalculateStatus", SeriesVerificationParameters);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksSupplyOptionChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	ProvisionInDocumentsClient.SupplyOptionChoiceProcessing(
		ThisObject,
		Items.SupplyWithMaterialsAndWorks.CurrentData,
		ValueSelected);
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksSupplyOptionOnChange(Item)
	
	Var FormParameters;
	If ProvisionInDocumentsClient.OpenWarehouseAndSeriesSelectionForm(ThisObject) Then
		OptionForGettingParameters = ProvisionInDocumentsClientServer.ActionSelectionMode();
		FormParameters = ParametersOfQuantityAndSeriesRequestForm(OptionForGettingParameters); // A call to the server
	EndIf;
	
	ProvisionInDocumentsClient.SupplyOptionOnChange(
		ThisObject,
		FormParameters,
		"ProcessWarehouseAndBatchSelection",
		False,
		"ProvisionOfMaterialsAndWorksOptionOfProvidingForChangesOnClient");
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksSupplyOptionClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksWithAssignmentOnChange(Item)
	
	String = Items.SupplyWithMaterialsAndWorks.CurrentData;
	
	ProvisionInDocumentsClient.WithAssignmentOnChange(String);
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInAssignmentInProductionPhase");
	
	ProvisionInDocumentsClientServer.AddCollateralActions(
		StructureOfActions,
		"AvailableInOtherLines",
		DocumentParametersForSoftwareActions(ThisObject));
	
	BatchProcessingOfTablePartClient.ProcessTSString(String, StructureOfActions, Undefined);
	
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksSupplyAssignmentOnChange(Item)
	
	String = Items.SupplyWithMaterialsAndWorks.CurrentData;
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInAssignmentInProductionPhase");
	
	ProvisionInDocumentsClientServer.AddCollateralActions(
		StructureOfActions,
		"AvailableInOtherLines",
		DocumentParametersForSoftwareActions(ThisObject));
	
	BatchProcessingOfTablePartClient.ProcessTSString(String, StructureOfActions, Undefined);
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksWarehouseStartChoice(Item, ChoiceData, StandardProcessing)
	
	FormParameters = ParametersOfQuantityAndSeriesRequestForm(ProvisionInDocumentsClientServer.WarehouseSelectionMode());
	
	If TypeOf(FormParameters) = Type("Structure") Then
		
		StandardProcessing = False;
		OpenForm(
			"DataProcessor.QuantityAndBatchRequest.Form",
			FormParameters,
			ThisObject,
			,
			,
			,
			New CallbackDescription("ProcessWarehouseAndBatchSelection", ThisObject, FormParameters));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksSupplyOptionStartChoice(Item, ChoiceData, StandardProcessing)
	
	NewArray = New Array();
	
	NewParameter1 = New ChoiceParameter("MultipleWarehouses", True);
	NewArray.Add(NewParameter1);
	
	// The provision option Reserve as received is not available
	If Object.DynamicStructure Then
		ActionsArray = ProvisionInDocumentsClientServer.AvailableActionsForSelectingCollateralInDefaultRow();
		IndexOf = ActionsArray.Find(PredefinedValue("Enum.SupplyOptions.ReserveAsReceived"));
		If IndexOf <> Undefined Then
			ActionsArray.Delete(IndexOf);
		EndIf;
		
		AllowedActions = New FixedArray(ActionsArray);
		NewParameter1 = New ChoiceParameter("AllowedActions", AllowedActions);
		
		NewArray.Add(NewParameter1);
	EndIf;
	
	Item.ChoiceParameters = New FixedArray(NewArray);
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksSupplyAssignmentEditingChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	
	If ValueSelected = Undefined
			Or ValueSelected = CurrentData.ValueRef Then
		StandardProcessing = False;
		
		CurrentData.SupplyAssignment = CurrentData.ValueRef;
		CurrentData.SupplyAssignmentEditing = CurrentData.StageName;
	Else
		CurrentData.SupplyAssignment = ValueSelected;
	EndIf;
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInAssignmentInProductionPhase");
	
	ProvisionInDocumentsClientServer.AddCollateralActions(
		StructureOfActions,
		"AvailableInOtherLines",
		DocumentParametersForSoftwareActions(ThisObject));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, Undefined);
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksSupplyAssignmentEditingClearing(Item, StandardProcessing)
	
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	CurrentData.SupplyAssignment = PredefinedValue("Catalog.Assignments.EmptyRef");
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInAssignmentInProductionPhase");
	
	ProvisionInDocumentsClientServer.AddCollateralActions(
		StructureOfActions,
		"AvailableInOtherLines",
		DocumentParametersForSoftwareActions(ThisObject));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, Undefined);
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksSupplyAssignmentEditingOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	
	If Not CurrentData.SupplyAssignment.IsEmpty() Then
		If AssignmentExists(CurrentData.SupplyAssignment) Then
			ShowValue(, CurrentData.SupplyAssignment);
		Else
			ClearMessages();
			CommonClientServer.MessageToUser(NStr("vi = 'Còn chưa ghi lại mục đích.';
													|ru = 'Назначение еще не записано.';
													|en = 'Assignment is not saved.'; fa = 'Assignment is not saved.';
													|it = 'Назначение еще не записано.';
													|pl = 'Assignment is not saved.';
													|tr = 'Atama henüz kaydedilmedi.'"));
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksSupplyAssignmentEditingStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	For Each Parameter In Items.SupplyWithMaterialsAndWorksSupplyAssignment.ChoiceParameters Do
		FormParameters.Insert(Parameter.Name, Parameter.Value);
	EndDo;
	For Each Link In Items.SupplyWithMaterialsAndWorksSupplyAssignment.ChoiceParameterLinks Do
		Value = ThisObject;
		For Each Field In StrSplit(Link.DataPath, ".") Do
			Value = Value[Field];
		EndDo;
		FormParameters.Insert(Link.Name, Value);
	EndDo;
	
	OpenForm("Catalog.Assignments.Form.AssignmentChoiceForm", FormParameters, Item, UUID);
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksUnderRepairProductOnChange(Item)
	
	CurrentData          = Items.SupplyWithMaterialsAndWorks.CurrentData;
	CurDataStructure = ProductionManagementClientServer.TheseLinesSupplyOfMaterialsAndWorksStructure(CurrentData);

	// redefining to use standard actions
	CurDataStructure.Insert("Products", CurrentData.UnderRepairProduct);
	CurDataStructure.Insert("Characteristic", CurrentData.UnderRepairVariant);
	CurDataStructure.Insert("ItemVariantsAreUsed", CurrentData.FinishedProductBeingRepairedCharacteristicsAreUsed);
	CurDataStructure.Insert("ItemsType", CurrentData.RepairedFinishedProductTypeOfItem);
	CurDataStructure.Insert("Status", CurrentData.Status);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentData.UnderRepairVariant);
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("UnderRepairProduct", "RepairedFinishedProductTypeOfItem"));
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", Undefined, SeriesSpecificationParameters.SupplyWithMaterialsAndWorks));

	BatchProcessingOfTablePartClient.ProcessTSString(CurDataStructure, StructureOfActions, CachedValues);
	
	CurrentData.UnderRepairVariant             = CurDataStructure.Characteristic;
	CurrentData.FinishedProductBeingRepairedCharacteristicsAreUsed = CurDataStructure.ItemVariantsAreUsed;
	CurrentData.UnderRepairBatch                      = CurDataStructure.UnderRepairBatch;
	CurrentData.UnderRepairBatchSpecificationStatus        = CurDataStructure.UnderRepairBatchSpecificationStatus;
	CurrentData.RepairedFinishedProductTypeOfItem            = CurDataStructure.RepairedFinishedProductTypeOfItem;
	
	StructureOfActions = New Structure;
	AddCheckActionFillInSpecification(ThisObject, StructureOfActions, CurrentData);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksUnderRepairVariantOnChange(Item)
	
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	
	StructureOfActions = New Structure;
	
	AddCheckActionFillInSpecification(ThisObject, StructureOfActions, CurrentData);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksUnderRepairBatchOnChange(Item)
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	
	ValueSelected.Value                   = CurrentData.UnderRepairBatch;
	ValueSelected.CurrentRowID = CurrentData.GetID();
	
	CurrentRow = New Structure;
	CurrentRow.Insert("SupplyOption", PredefinedValue("Enum.SupplyOptions.NotRequired"));
	CurrentRow.Insert("Canceled", CurrentData.Canceled);
	CurrentRow.Insert("Series", CurrentData.UnderRepairBatch);
	CurrentRow.Insert("BatchesIndicationStatus", CurrentData.UnderRepairBatchSpecificationStatus);
	CurrentRow.Insert("Status", CurrentData.Status);
	
	ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters.SupplyWithMaterialsAndWorks, ValueSelected, CurrentRow);
	
	CurrentData.UnderRepairBatch               = CurrentRow.Series;
	CurrentData.UnderRepairBatchSpecificationStatus = CurrentRow.BatchesIndicationStatus;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersMaterialsAndWorksConsumption

&AtClient
Procedure MaterialsAndWorksConsumptionOnChange(Item)
	
	ConfigureDependentFormElements(ThisForm, "MaterialsAndWorksConsumption");
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksConsumptionBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	If Not CheckBlockDocuments(Cancel) Then
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksConsumptionBeforeRowChange(Item, Cancel)
	
	If Not CheckBlockDocuments(Cancel) Then
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksConsumptionBeforeDeleteRow(Item, Cancel)
	
	If Not CheckRowsOfTablePartBeforeDeleting("MaterialsAndWorksConsumption", Cancel) Then
		Return;
	EndIf;
	If Not CheckBlockDocuments(Cancel) Then
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksConsumptionOnStartEdit(Item, NewRow, Copy)
	
	ProcessingLineAtBeginningOfEditing("MaterialsAndWorksConsumption", NewRow, Copy);
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksConsumptionOnEditEnd(Item, NewRow, CancelEdit)
	
	CurrentData = Items.MaterialsAndWorksConsumption.CurrentData;
	
	If Not CancelEdit Then
		CheckHandleChangeOfProgressMark(ObjectIsCreatedByReference(ThisForm, CurrentData.Ref), True);
	EndIf;
	
	If NewRow And CancelEdit Then
		ConfigureDependentFormElements(ThisForm, "MaterialsAndWorksConsumption");
	EndIf;
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksConsumptionProductsOnChange(Item)
	
	CurrentData = Items.MaterialsAndWorksConsumption.CurrentData;
	WhenChangingProducts(CurrentData, "MaterialsAndWorksConsumption");
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksConsumptionCharacteristicOnChange(Item)
	
	CurrentData = Items.MaterialsAndWorksConsumption.CurrentData;
	WhenChangingCharacteristics(CurrentData, "MaterialsAndWorksConsumption");
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksConsumptionPackageOnChange(Item)
	
	CurrentData = Items.MaterialsAndWorksConsumption.CurrentData;
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksConsumptionNumberOfPackagesOnChange(Item)
	
	CurrentData = Items.MaterialsAndWorksConsumption.CurrentData;
	WhenChangingNumberOfPackages(CurrentData, "MaterialsAndWorksConsumption");
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksConsumptionSeriesOnChange(Item)
	
	CurrentData = Items.MaterialsAndWorksConsumption.CurrentData;
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value            		 = CurrentData.Series;
	ValueSelected.CurrentRowID = CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters.MaterialsAndWorksConsumption, ValueSelected);
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksConsumptionSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenSelectionOfSeries("MaterialsAndWorksConsumption", Item.EditText);
	
EndProcedure

&AtClient
Procedure ConsumptionOfMaterialsAndWorksLinkEditStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	ProcessStartOfProductionStageSelectionInLine("MaterialsAndWorksConsumption");
	
EndProcedure

&AtClient
Procedure ConsumptionOfMaterialsAndWorksLinkEditClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	ClearProductionStageInLine("MaterialsAndWorksConsumption");
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersUnusedMaterials

&AtClient
Procedure UnusedMaterialsOnChange(Item)
	
	ConfigureDependentFormElements(ThisForm, "UnusedMaterials");
	
EndProcedure

&AtClient
Procedure UnusedMaterialsSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.UnusedMaterials.CurrentData;
	
	If ReadOnly Or CurrentData.ReadOnly Then
		StandardProcessing = False;
		Return;
	EndIf;
	
	If Not CheckBlockDocuments() Then
		StandardProcessing = False;
		Return;
	EndIf;
	
	GLAccountSettingsClient.OnClick(ThisObject, Field, StandardProcessing);
	
EndProcedure

&AtClient
Procedure UnusedMaterialsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	If Not CheckBlockDocuments(Cancel) Then
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure UnusedMaterialsBeforeRowChange(Item, Cancel)
	
	If Not CheckBlockDocuments(Cancel) Then
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure UnusedMaterialsBeforeDeleteRow(Item, Cancel)
	
	If Not CheckRowsOfTablePartBeforeDeleting("UnusedMaterials", Cancel) Then
		Return;
	EndIf;
	If Not CheckBlockDocuments(Cancel) Then
		Return;
	EndIf;
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(Item,CachedValues,SeriesSpecificationParameters.UnusedMaterials);
	
EndProcedure

&AtClient
Procedure UnusedMaterialsOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.UnusedMaterials.CurrentData;
	
	ProcessingLineAtBeginningOfEditing("UnusedMaterials", NewRow, Copy);
	ObjectStage = ObjectIsCreatedByReference(ThisForm, CurrentData.Ref);
	
	ProductionManagementClient.UnusedMaterialsOnStartEdit(
		ThisForm,
		ObjectStage,
		CurrentData,
		NewRow,
		Copy);
	
	WarehousesClient.UpdateCachedValues(Item, CachedValues, SeriesSpecificationParameters.UnusedMaterials, Copy);
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(
		Item,CachedValues,SeriesSpecificationParameters.UnusedMaterials, Copy);
	
EndProcedure

&AtClient
Procedure UnusedMaterialsOnEditEnd(Item, NewRow, CancelEdit)
	
	CurrentData = Items.UnusedMaterials.CurrentData;
	
	If ProductsClient.SeriesStatusesNeedToBeUpdated(
		Item,CachedValues,SeriesSpecificationParameters.UnusedMaterials) Then
		
		IDCurrentRow = CurrentData.GetID();
		
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(
			"UnusedMaterials", IDCurrentRow, CachedValues);
		
		ProductsClient.UpdateCachedValuesToAccountForSeries(
			Item, CachedValues, SeriesSpecificationParameters.UnusedMaterials);
		
	EndIf;
	
	If Not CancelEdit Then
		CheckHandleChangeOfProgressMark(ObjectIsCreatedByReference(ThisForm, CurrentData.Ref), True);
	EndIf;
	
	If NewRow And CancelEdit Then
		ConfigureDependentFormElements(ThisForm, "UnusedMaterials");
	EndIf;
	
EndProcedure

&AtClient
Procedure UnusedMaterialsAfterDeleteRow(Item)
	
	AfterRemovingTSRowsForWhichThereIsSeries("UnusedMaterials", Item);
	
EndProcedure

&AtClient
Procedure UnusedMaterialsProductsOnChange(Item)
	
	CurrentData = Items.UnusedMaterials.CurrentData;
	WhenChangingProducts(CurrentData, "UnusedMaterials");
	
EndProcedure

&AtClient
Procedure UnusedMaterialsCharacteristicOnChange(Item)
	
	CurrentData = Items.UnusedMaterials.CurrentData;
	WhenChangingCharacteristics(CurrentData, "UnusedMaterials");
	
EndProcedure

&AtClient
Procedure UnusedMaterialsPackageOnChange(Item)
	
	CurrentData = Items.UnusedMaterials.CurrentData;
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure UnusedMaterialsNumberOfPackagesOnChange(Item)
	
	CurrentData = Items.UnusedMaterials.CurrentData;
	WhenChangingNumberOfPackages(CurrentData, "UnusedMaterials");
	
EndProcedure

&AtClient
Procedure UnusedMaterialsSeriesOnChange(Item)
	
	CurrentRow = Items.UnusedMaterials.CurrentData;
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	ValueSelected.Value                   = CurrentRow.Series;
	ValueSelected.CurrentRowID = CurrentRow.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters.UnusedMaterials, ValueSelected);
	
EndProcedure

&AtClient
Procedure UnusedMaterialsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenSelectionOfSeries("UnusedMaterials", Item.EditText);
	
EndProcedure

&AtClient
Procedure UnusedMaterialsActionsOnChange(Item)
	
	CurrentData = Items.UnusedMaterials.CurrentData;
	SavingMaterialsActionWhenChanging(CurrentData);
	
EndProcedure

&AtClient
Procedure UnusedMaterialsRecipientOnChange(LineOfATabularSection)
	
	CurrentData = Items.UnusedMaterials.CurrentData;
	WhenChangingRecipient(CurrentData, "UnusedMaterials");
	
EndProcedure

&AtClient
Procedure UnusedMaterialsExpenseItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure UnusedMaterialsExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure UnusedMaterialsDimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure UnusedMaterialsDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure UnusedMaterialsDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure SaveMaterialsLinkEditStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	ProcessStartOfProductionStageSelectionInLine("UnusedMaterials");
	
EndProcedure

&AtClient
Procedure SaveMaterialsLinkEditClearing(Item, StandardProcessing)

	StandardProcessing = False;
	ClearProductionStageInLine("UnusedMaterials");
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersLaborCosts

&AtClient
Procedure LaborCostsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	CheckBlockDocuments(Cancel);
	
EndProcedure

&AtClient
Procedure LaborCostsBeforeRowChange(Item, Cancel)
	
	CheckBlockDocuments(Cancel);
	
EndProcedure

&AtClient
Procedure LaborCostsBeforeDeleteRow(Item, Cancel)
	
	If Not CheckRowsOfTablePartBeforeDeleting("LaborCosts", Cancel) Then
		Return;
	EndIf;
	If Not CheckBlockDocuments(Cancel) Then
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure LaborCostsOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.LaborCosts.CurrentData;
	
	ProcessingLineAtBeginningOfEditing("LaborCosts", NewRow, Copy);
	ObjectStage = ObjectIsCreatedByReference(ThisForm, CurrentData.Ref);
	
	If Copy Then
		CurrentData.RowCode = 0;
		CurrentData.KeyWorkType = Undefined;
	EndIf;
	
	If NewRow Then
		CurrentData.Completed2 = False;
		CurrentData.ExecutionDate = '000101010000';
	EndIf;
	
	AccountingOfLaborCostsInContextOfEmployeesIsUsed = ValueIsFilled(BeginningOfAccountingOfLaborCostsForEmployees)
		And (CurrentData.ExecutionDate >= BeginningOfAccountingOfLaborCostsForEmployees
		Or ?(ValueIsFilled(ObjectStage.ActualStageStart), ObjectStage.ActualStageStart,
								ObjectStage.Date) >= BeginningOfAccountingOfLaborCostsForEmployees);
	
	ProductionManagementClientServer.SetArtistType(
		CurrentData.Performer,
		ObjectStage.UseTeamWorkOrders,
		AccountingOfLaborCostsInContextOfEmployeesIsUsed);
	
EndProcedure

&AtClient
Procedure LaborCostsOnEditEnd(Item, NewRow, CancelEdit)
	
	CurrentData = Items.LaborCosts.CurrentData;
	
	If ShowStandardsLaborCosts And CurrentData <> Undefined Then
		
		DataArray = New Array;
		RowData = New Structure("Stage,WorkKind");
		FillPropertyValues(RowData, CurrentData);
		DataArray.Add(RowData);
		Standards = GetStandardsWhenChangingRows("LaborCosts", DataArray, StorageAddressStandards);
		CurrentData.NormativeStandard = Standards[0];
		
	EndIf;
	
EndProcedure

&AtClient
Procedure LaborCostsPerformerStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.LaborCosts.CurrentData;
	
	ObjectStage = ObjectIsCreatedByReference(ThisForm, CurrentData.Ref);
	CallbackDescription = New CallbackDescription("PerformerStartChoiceCompletion", ThisObject);

	ProductionClient.OpenArtistSelectionForm(
		ObjectStage.Organization,
		CurrentData.Department,
		CurrentData.Performer,
		CurrentData.ExecutionDate,
		,
		CallbackDescription);
	
EndProcedure

&AtClient
Procedure LaborCostsPerformerAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	CurrentData = Items.LaborCosts.CurrentData;
	
	If ValueIsFilled(Text) Then
		
		StandardProcessing = False;
		ObjectStage = ObjectIsCreatedByReference(ThisForm, CurrentData.Ref);
		
		Date = ?(ValueIsFilled(CurrentData.ExecutionDate), CurrentData.ExecutionDate,
										Max(ObjectStage.ActualStageStart, ObjectStage.Date));
		
		PerformerGettingSelectionData(ChoiceData, Text, CurrentData.Department, ObjectStage.Organization, Date);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure LaborCostsPerformerTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	CurrentData = Items.LaborCosts.CurrentData;
	
	If ValueIsFilled(Text) Then
		
		StandardProcessing = False;
		ObjectStage = ObjectIsCreatedByReference(ThisForm, CurrentData.Ref);
		
		Date = ?(ValueIsFilled(CurrentData.ExecutionDate), CurrentData.ExecutionDate,
										Max(ObjectStage.ActualStageStart, ObjectStage.Date));
		
		PerformerGettingSelectionData(ChoiceData, Text, CurrentData.Department, ObjectStage.Organization, Date);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure LaborCostsCompleted2OnChange(Item)
	
	CurrentData = Items.LaborCosts.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	Id = CurrentData.GetID();
	LaborPerformedWhenChangingOnServer(Id);
	
EndProcedure

&AtServer
Procedure LaborPerformedWhenChangingOnServer(Id)
	
	CurrentData = Object.LaborCosts.FindByID(Id);
	
	ObjectStage = ObjectIsCreatedByReference(ThisForm, CurrentData.Ref);
	
	If CurrentData.Completed2 And ValueIsFilled(ObjectStage.Performer) Then
		CurrentData.Performer = ObjectStage.Performer;
	EndIf;
	
	CheckProcessChangeOfExecutionMarkOnServer(ObjectStage, CurrentData.Completed2);

	ProductionManagement.SetDateOfCompletionOfLaborCosts(CurrentData, ObjectStage.ActualProductionDate);
	
EndProcedure

&AtClient
Procedure LaborCostsLinkEditStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	ProcessStartOfProductionStageSelectionInLine("LaborCosts");
	
EndProcedure

&AtClient
Procedure LaborCostsLinkEditClearing(Item, StandardProcessing)

	StandardProcessing = False;
	ClearProductionStageInLine("LaborCosts");
	
EndProcedure

&AtClient
Procedure LaborCostsCanceledOnChange(Item)
	
	CurrentData = Items.LaborCosts.CurrentData;
	
	If CurrentData.Canceled
		And CurrentData.Completed2 Then
		CurrentData.Completed2 = False;
		LaborPerformedWhenChangingOnServer(CurrentData.GetID());
	EndIf;
	
	If Not CurrentData.Canceled Then
		CurrentData.CancellationReason = PredefinedValue("Catalog.ReasonsForProductionCancellation.EmptyRef");
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

#Region IsMain

&AtClient
Procedure CheckFillInCommand(Command)
	
	ClearMessages();
	
	If CheckFilling() Then
		
		MessageText = NStr("vi = 'Không tìm thấy lỗi điền.';
							|ru = 'Ошибок заполнения не обнаружено.';
							|en = 'No filling errors were detected.'; fa = 'No filling errors were detected.';
							|it = 'Errori di compilazione non sono stati rilevati.';
							|pl = 'Błędów wypełnienia nie stwierdzono.';
							|tr = 'Doldurma hatası tespit edilmedi.'");
		CommonClientServer.MessageToUser(MessageText);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CommandWrite(Command)
	
	If Not CheckBlockDocuments() Then
		Return;
	EndIf;
	
	WriteData();
	
EndProcedure

&AtClient
Procedure TheCommandToRead(Command)
	
	Reread();
	
EndProcedure

#EndRegion

#Region ManufacturedProducts

&AtClient
Procedure OutputItemsSplitLine_3(Command)
	
	BreakTSString("ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure ManufacturedProducts_PickUpProducts(Command)
	
	If Not CheckBlockDocuments() Then
		Return;
	EndIf;
	
	OpensGoodsSelection("ManufacturedProducts");
	
EndProcedure
 
&AtClient
Procedure OutputProductsSpecifyTheSeries_3(Command)
	
	OpenSelectionOfSeries("ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure OutputItemsFillInTheRecipient(Command)
	
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.EditProductionStageSequence.Form.Form.Command.OutputItemsFillInTheRecipient");	
	
	TSParameters = New Structure;
	TSParameters.Insert("NameTSForm"      , "ManufacturedProducts");
	TSParameters.Insert("NameTsObject"     , "ManufacturedProducts");
	TSParameters.Insert("PresentationOfTS" , NStr("vi = 'Sản phẩm giá trị ước tính';
													|ru = 'Изделия по рассчитываемой стоимости';
													|en = 'Products by calculated cost'; fa = 'محصولات بر اساس بهای محاسبه‌شده';
													|it = 'Prodotti in base al valore calcolato';
													|pl = 'Wyroby po szacowanej cenie';
													|tr = 'Hesaplanan maliyete göre nihai ürünler'"));
	
	CallbackDescription = New CallbackDescription("FillInRecipientCompletion", 
												   ThisObject, New Structure("TSParameters", TSParameters));
	
	ProductionClient.OpenRecipientSelectionForm(ThisForm, Object, TSParameters,, CallbackDescription); 
	
EndProcedure

&AtClient
Procedure OutputProductsChangeQuality(Command)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	If CurrentData = Undefined Then
		Return;
	ElsIf CurrentData.ReadOnly Then
		ShowMessageBox(, NStr("vi = 'Lệnh không thể được thực thi cho dòng đã chọn!';
								|ru = 'Команда не может быть выполнена для выбранной строки!';
								|en = 'Command cannot be executed for the selected line.'; fa = 'Command cannot be executed for the selected line.';
								|it = 'Il comando non può essere eseguito per la riga selezionata!';
								|pl = 'Polecenie nie może być wykonane dla wybranego wiersza!';
								|tr = 'Seçili satır için komut gerçekleştirilemez!'"));
		Return;
	EndIf;
	If Not CheckBlockDocuments() Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("ChangeQuality");
	
	If ValueIsFilled(CurrentData.Characteristic) Then
		StructureOfActions.Insert("FillInDescriptionOfPoorQualityProduct", CurrentData.Characteristic);
	EndIf;
	If ValueIsFilled(CurrentData.Package) Then
		StructureOfActions.Insert("FillInPackagingOfLowQualityGoods", CurrentData.Package);
	EndIf;
	
	AddActionsToStructureWhenChangingProducts(
			ObjectIsCreatedByReference(ThisObject, CurrentData.Ref),
			"ManufacturedProducts",
			ThisObject,
			StructureOfActions);
			
	CallbackDescription = New CallbackDescription("ChangeQualityCompletion", ThisObject, CallbackDescription);		
	
	WarehousesClient.ChangeQuality(CurrentData, StructureOfActions, CachedValues, CallbackDescription);
	
EndProcedure

&AtClient
Procedure ManufacturedProducts_InsertRows(Command)
	
	If Not CheckBlockDocuments() Then
		Return;
	EndIf;
	
	GetLinesFromClipboard("ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure ManufacturedProducts_CopyLines(Command)
	
	CopyTSLines("ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure WeekendItemsToCancelTheSelectedRow(Command)
	
	If Not CheckBlockDocuments() Then
		Return;
	EndIf;
	
	CancelSelectedLines("ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure OutputItemsHideCanceledLines(Command)
	
	FinishedProductsHideCanceledLines = Not FinishedProductsHideCanceledLines;
	
	If FinishedProductsHideCanceledLines Then
		Items.ManufacturedProducts.RowFilter = New FixedStructure("Canceled", False);
	Else
		Items.ManufacturedProducts.RowFilter = Undefined;
	EndIf;
	
	Items.OutputItemsHideCanceledLines.Check = FinishedProductsHideCanceledLines;
	
EndProcedure

&AtClient
Procedure OutputItemsChangeQualityCancelLine(Command)
	
	CurrentRow = Items.ManufacturedProducts.CurrentData;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.ManufacturedProducts, ThisObject);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("ChangeQuality");
	
	If ValueIsFilled(CurrentRow.Characteristic) Then
		StructureOfActions.Insert("FillInDescriptionOfPoorQualityProduct", CurrentRow.Characteristic);
	EndIf;
	If ValueIsFilled(CurrentRow.Package) Then
		StructureOfActions.Insert("FillInPackagingOfLowQualityGoods", CurrentRow.Package);
	EndIf;
	
	AddActionsToStructureWhenChangingProducts(
			ObjectIsCreatedByReference(ThisObject, CurrentRow.Ref),
			"ManufacturedProducts", 
			ThisObject,
			StructureOfActions);
			
	AdditionalParameters = New Structure("TSName", "ManufacturedProducts");
	CallbackDescription = New CallbackDescription(
		"Products_ChangeQualityCancelLineCompletion",
		ThisObject,
		AdditionalParameters);
	
	WarehousesClient.ChangeQuality(CurrentRow, StructureOfActions, CachedValues, CallbackDescription);
	
EndProcedure

&AtClient
Procedure OutputProductsFillInPrices(Command)
	
	FillInPricesByPriceKind("ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure OutputProductsFillInThePricesAccordingToTheCalculation_3(Command)

	SelectedRows = GetSelectedRowsInList("ManufacturedProducts");
	If Not ValueIsFilled(SelectedRows) Then
		Return;
	EndIf;
	If Not CheckBlockDocuments() Then
		Return;
	EndIf;
	
	ReferencesArrray = New Array;
	IDs = New Array;
	For Each String In SelectedRows Do
		
		RowData = Object.ManufacturedProducts.FindByID(String);
		If (RowData.Manufactured Or RowData.Price <> 0) 
			And RowData.UseTargetCost Then
			
			ReferencesArrray.Add(RowData.Ref);
			IDs.Add(String);
			
		EndIf;
		
	EndDo;
	
	If IDs.Count() = 0 Then
		
		MessageText = NStr("vi = 'Các dòng được chọn không có bất kỳ mục nào có sẵn để điền bằng cách tính chi phí.';
							|ru = 'В выделенных строках отсутствуют позиции, доступные для заполнения по калькуляции.';
							|en = 'There are no items available for population by costing in the selected lines.'; fa = 'There are no items available for population by costing in the selected lines.';
							|it = 'Nelle righe selezionate non ci sono posizioni disponibili per la compilazione per calcolo.';
							|pl = 'W wybranych wierszach nie ma pozycji, dostępnych dla wypełnienia dotyczących kalkulacji.';
							|tr = 'Seçilen satırlarda, maliyetlendirmeye göre doldurulabilecek pozisyon bulunmamaktadır.'");
		ShowMessageBox( , MessageText);
		
		Return;
	EndIf;
	
	Currency = Undefined;
	For Each Ref In ReferencesArrray Do
		
		ObjectStage = ObjectIsCreatedByReference(ThisForm, Ref);
		
		If Currency = Undefined Then
			Currency = ObjectStage.Currency;
			Continue;
		EndIf;
		
		If Currency <> ObjectStage.Currency Then
			
			MessageText = NStr("vi = 'Các dòng được chọn sử dụng các loại tiền tệ khác nhau, điền vào là không thể.';
								|ru = 'В выделенных строках используются различные валюты, заполнение не возможно.';
								|en = 'Selected lines use different currencies, filling is not possible.'; fa = 'Selected lines use different currencies, filling is not possible.';
								|it = 'Nelle righe evidenziate sono usate valute diverse, impossibile compilare.';
								|pl = 'W wybranych wierszach są używane różne waluty wypełnienie nie jest możliwe.';
								|tr = 'Seçilen satırlarda farklı para birimleri kullanılmaktadır, doldurma mümkün değildir.'");
			ShowMessageBox( , MessageText);
			
			Return;
		EndIf;
		
	EndDo;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("RowsIDs", IDs);
	AdditionalParameters.Insert("Currency", Currency);

	FormParameters = New Structure;
	FormParameters.Insert("Organization", Object.Organization);
	FormParameters.Insert("State", 
		PredefinedValue("Enum.StatesOfStandardCostEstimateCalculation.Calculated"));
	
	OpenForm("Document.StandardCosting2_2.Form.ChoiceForm", FormParameters,,,,, 
		New CallbackDescription("CompletionOfPlanningCalculationSelection", ThisObject, AdditionalParameters),
		FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

#EndRegion

#Region SideAndIntermediateRelease

&AtClient
Procedure SideProductsSplitTheLine(Command)
	
	BreakTSString("SideAndIntermediateRelease");
	
EndProcedure

&AtClient
Procedure SideOfTheProductToPickUpTheGoods(Command)
	
	If Not CheckBlockDocuments() Then
		Return;
	EndIf;
	
	OpensGoodsSelection("SideAndIntermediateRelease");
	
EndProcedure
 
&AtClient
Procedure SideOfTheProductToSpecifySeries(Command)
	
	OpenSelectionOfSeries("SideAndIntermediateRelease");
	
EndProcedure

&AtClient
Procedure ByProductsFillInTheRecipient(Command)
	
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.EditProductionStageSequence.Form.Form.Command.ByProductsFillInTheRecipient");	
	
	TSParameters = New Structure;
	TSParameters.Insert("NameTSForm"      , "SideAndIntermediateRelease");
	TSParameters.Insert("NameTsObject"     , "SideAndIntermediateRelease");
	TSParameters.Insert("PresentationOfTS" , NStr("vi = 'Sản phẩm phụ và xuất xưởng trung gian với giá trị cố định';
													|ru = 'Побочный и промежуточный выход по фиксированной стоимости';
													|en = 'Side and intermediate product at fixed cost'; fa = 'محصول فرعی و میانی با بهای ثابت';
													|it = 'Uscita collaterale e intermedia ad un costo fisso';
													|pl = 'Produkcja poboczna i pośrednia po stałej cenie';
													|tr = 'Sabit maliyetle yan ve ara ürün çıkışı'"));
	
	CallbackDescription = New CallbackDescription("FillInRecipientCompletion", 
												   ThisObject, New Structure("TSParameters", TSParameters));
	
	ProductionClient.OpenRecipientSelectionForm(ThisForm, Object, TSParameters,, CallbackDescription); 
	
EndProcedure

&AtClient
Procedure ByProductsChangeQuality(Command)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	If CurrentData = Undefined Then
		Return;
	ElsIf CurrentData.ReadOnly Then
		ShowMessageBox(, NStr("vi = 'Lệnh không thể được thực thi cho dòng đã chọn!';
								|ru = 'Команда не может быть выполнена для выбранной строки!';
								|en = 'Command cannot be executed for the selected line.'; fa = 'Command cannot be executed for the selected line.';
								|it = 'Il comando non può essere eseguito per la riga selezionata!';
								|pl = 'Polecenie nie może być wykonane dla wybranego wiersza!';
								|tr = 'Seçili satır için komut gerçekleştirilemez!'"));
		Return;
	EndIf;
	If Not CheckBlockDocuments() Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("ChangeQuality");
	
	If ValueIsFilled(CurrentData.Characteristic) Then
		StructureOfActions.Insert("FillInDescriptionOfPoorQualityProduct", CurrentData.Characteristic);
	EndIf;
	If ValueIsFilled(CurrentData.Package) Then
		StructureOfActions.Insert("FillInPackagingOfLowQualityGoods", CurrentData.Package);
	EndIf;
	
	AddActionsToStructureWhenChangingProducts(
			ObjectIsCreatedByReference(ThisObject, CurrentData.Ref),
			"SideAndIntermediateRelease", 
			ThisObject,
			StructureOfActions);
			
	CallbackDescription = New CallbackDescription("ChangeQualityCompletion", ThisObject, CallbackDescription);		
	
	WarehousesClient.ChangeQuality(CurrentData, StructureOfActions, CachedValues, CallbackDescription);
	
EndProcedure

&AtClient
Procedure ByProductsFillInPrices(Command)
	
	FillInPricesByPriceKind("SideAndIntermediateRelease");
	
EndProcedure

&AtClient
Procedure SideItemsCopyLines(Command)
	
	CopyTSLines("SideAndIntermediateRelease");
	
EndProcedure

&AtClient
Procedure ByProductsInsertRows_3(Command)
	
	If Not CheckBlockDocuments() Then
		Return;
	EndIf;
	
	GetLinesFromClipboard("SideAndIntermediateRelease");
	
EndProcedure

&AtClient
Procedure ByProductsCancelSelectedRows(Command)
	
	If Not CheckBlockDocuments() Then
		Return;
	EndIf;
	
	CancelSelectedLines("SideAndIntermediateRelease");
	
EndProcedure

&AtClient
Procedure SideItemsHideCanceledLines(Command)
	
	SideProductsHideCanceledLines = Not SideProductsHideCanceledLines;
	
	If SideProductsHideCanceledLines Then
		Items.SideAndIntermediateRelease.RowFilter = New FixedStructure("Canceled", False);
	Else
		Items.SideAndIntermediateRelease.RowFilter = Undefined;
	EndIf;
	
	Items.SideItemsHideCanceledLines.Check = SideProductsHideCanceledLines;
	
EndProcedure

&AtClient
Procedure ByProductsChangeQualityCancelLine(Command)
	
	CurrentRow = Items.SideAndIntermediateRelease.CurrentData;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.SideAndIntermediateRelease, ThisObject);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("ChangeQuality");
	
	If ValueIsFilled(CurrentRow.Characteristic) Then
		StructureOfActions.Insert("FillInDescriptionOfPoorQualityProduct", CurrentRow.Characteristic);
	EndIf;
	If ValueIsFilled(CurrentRow.Package) Then
		StructureOfActions.Insert("FillInPackagingOfLowQualityGoods", CurrentRow.Package);
	EndIf;
	
	AddActionsToStructureWhenChangingProducts(
			ObjectIsCreatedByReference(ThisObject, CurrentRow.Ref),
			"SideAndIntermediateRelease", 
			ThisObject,
			StructureOfActions);
			
	AdditionalParameters = New Structure("TSName", "SideAndIntermediateRelease");
	CallbackDescription = New CallbackDescription(
		"Products_ChangeQualityCancelLineCompletion",
		ThisObject,
		AdditionalParameters);
	
	WarehousesClient.ChangeQuality(CurrentRow, StructureOfActions, CachedValues, CallbackDescription);
	
EndProcedure

&AtClient
Procedure SideProductsPopulateCostingItem(Command)
	
	FillInTheCostingItem("SideAndIntermediateRelease");
	
EndProcedure

#EndRegion

#Region Supply

&AtClient
Procedure ProvidingACopyOfTheString(Command)
	
	CopyTSLines("SupplyWithMaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure SoftwareInsertRows(Command)
	
	If Not CheckBlockDocuments() Then
		Return;
	EndIf;
	
	GetLinesFromClipboard("SupplyWithMaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure TheProvisionToSplitTheString(Command)
	
	BreakTSString("SupplyWithMaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure SoftwareFillInAccordingToSpecification(Command)

	If Not CheckBlockDocuments() Then
		Return;
	EndIf;
	
	If Object.SupplyWithMaterialsAndWorks.Count() <> 0 Then
		QueryText = NStr("vi = 'Điền phần bảng theo bảng kê chi tiết các nguồn lực sản xuất?';
						|ru = 'Перезаполнить табличную часть по спецификации?';
						|en = 'Refill the table according to BOM?'; fa = 'Refill the table according to BOM?';
						|it = 'Ricompilare la parte tabulare secondo la specifica?';
						|pl = 'Wypełnić ponownie tabelaryczną część według specyfikacji?';
						|tr = 'Tablo bölümü ürün reçetesine göre yeniden doldurulsun mu?'");
		CallbackDescription = New CallbackDescription("SoftwareFillInAccordingToSpecificationCompletion", ThisObject);
		ButtonsList = New ValueList;
		ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Điền';
													|ru = 'Заполнить';
													|en = 'Fill'; fa = 'پرکردن';
													|it = 'Compilare';
													|pl = 'Wypełnij';
													|tr = 'Doldur'"));
		ButtonsList.Add(DialogReturnCode.Cancel);
		ShowQueryBox(CallbackDescription, QueryText, ButtonsList); 
	Else
		SoftwareFillInAccordingToSpecificationCompletion(DialogReturnCode.Yes, Undefined);
	EndIf; 
	
EndProcedure

&AtClient
Procedure SoftwareFillInAccordingToSpecificationCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		SoftwareSpecificationsOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure SupplyFillInTheWarehouseInTheSelectedLines(Command)

	SelectedRows = GetSelectedRowsInList("SupplyWithMaterialsAndWorks");
	If Not ValueIsFilled(SelectedRows) Then
		Return;
	EndIf;
	If Not CheckBlockDocuments() Then
		Return;
	EndIf;
	
	If WarehousesClient.CheckPossibilityOfFillingWarehousesInTablePart(
								New Structure("Ref", PredefinedValue("Document.ProductionStage2_2.EmptyRef")),
								Object.SupplyWithMaterialsAndWorks,
								NStr("vi = 'Đảm bảo';
									|ru = 'Обеспечение';
									|en = 'Supply'; fa = 'Supply';
									|it = 'Approvvigionamento';
									|pl = 'Zaopatrzenie';
									|tr = 'Tedarik'"),
								SelectedRows) Then
		
		Filter = New Structure("IsFolder", False);
		ParametersStructure = New Structure("Filter, ChoiceFoldersAndItems", Filter, FoldersAndItemsUse.Items);
		
		CallbackDescription = New CallbackDescription("SupplyFillInTheWarehouseInTheSelectedLinesCompletion", ThisObject, New Structure("SelectedRows", SelectedRows));
		
		OpenForm("Catalog.Warehouses.ChoiceForm",
			ParametersStructure,
			ThisForm,
			,
			,
			,
			CallbackDescription,
			FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SupplyFillInTheWarehouseInTheSelectedLinesCompletion(SelectedWarehouse, AdditionalParameters) Export
	
	SelectedRows = AdditionalParameters.SelectedRows;
	
	If ValueIsFilled(SelectedWarehouse) Then
		
		FilledWithRows = FillWarehouseInSelectedLinesOnServer(SelectedRows, SelectedWarehouse);
		WarehousesClient.ShowNotificationAboutFillingOfWarehouseInTablePart(SelectedWarehouse, FilledWithRows, SelectedRows.Count());
		
	EndIf;

EndProcedure

&AtClient
Procedure EnsureToPickUpTheGoods(Command)

	If Not CheckBlockDocuments() Then
		Return;
	EndIf;
	
	OpensGoodsSelection("SupplyWithMaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure SoftwareToChooseAccordingToSpecification(Command)

	If Not CheckBlockDocuments() Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	
	ItemData_3 = ProductData_4();
		
	FillPropertyValues(ItemData_3, ProductionBatchData,
		"ReferenceOrder, ProductionStart, ProductionDispatcherBusinessUnit, LineOfBusiness, BillOfMaterials, Products, Characteristic, Count");
	
	FormParameters.Insert("ItemData_3", ItemData_3);
	
	FormParameters.Insert("ShowQuantityMatched", True);
	FormParameters.Insert("ColumnTitleQuantitySelected", NStr("vi = 'Trong công đoạn';
																|ru = 'В этапе';
																|en = 'In stage'; fa = 'In stage';
																|it = 'Nella fase';
																|pl = 'Na etapie';
																|tr = 'Aşamada'"));
	FormParameters.Insert("SearchStructureSelectedMaterials", New Structure("Stage,Products,Characteristic"));
	FormParameters.Insert("AddressSelectedMaterials", PlaceMaterialsForSelectionAccordingToSpecificationInRepository());
	FormParameters.Insert("UUID", UUID);
	FormParameters.Insert("UseProductionAccordingToSpecification", Not ProductionBatchData.DynamicStructure);
	FormParameters.Insert("GetDataSets", False);
	FormParameters.Insert("Basis", PredefinedValue("Document.ProductionStage2_2.EmptyRef"));
	FormParameters.Insert("IntermediateSemiFinishedProducts", ProductDataManagementClientServer.IntermediateSemiFinishedProductsGet());
	
	OpenForm("Catalog.BillsOfMaterials.Form.SelectMaterialsByBOM",
			FormParameters,
			ThisObject, 
			UUID,,,, 
			FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SecurityShowStandards(Command)
	
	SavedInSettingsDataModified = True;
	
	ShowStandardsMaterials = Not ShowStandardsMaterials;
	ShowStandardsWhenChangingOnServer("SupplyWithMaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure ProvisionShowAnalogues(Command)
	
	ShowAnalogues = Not ShowAnalogues;
	If RightToReadSubstitutes And ShowAnalogues Then
		NotePresenceOfAnalogues();
	EndIf;
	
	ConfigureDependentFormElements(ThisForm, "ShowAnalogues");
	
EndProcedure

&AtClient
Procedure SoftwareToPickUpAnalogs(Command)
	
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.EditProductionStageSequence.Form.Form.Command.SoftwareToPickUpAnalogs");

	If Not CheckBlockDocuments() Then
		Return;
	EndIf;
	
	OpenSelectionOfAnalogues();
	
EndProcedure

&AtClient
Procedure ReplaceProvisionsWithAnalogues(Command)
	
	If Not CheckBlockDocuments() Then
		Return;
	EndIf;
	
	Replace_With_Analogues();
	
EndProcedure

&AtClient
Procedure SoftwareForCompletingTheFEFOSeries(Command)
	
	If ThereAreFilledSeriesByFEFO() Then
		
		ProductsClient.AskQuestionAboutReFillingSeriesByFEFO(
			New CallbackDescription("CompleteSeriesOnFEFOCompletion", ThisObject));
		
		Return;
		
	EndIf;
	
	If Not FillInSeriesByFEFOServer() Then
		
		ProductsClient.WarnAboutAbsenceOfLinesFilledByFEFO();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CompleteSeriesOnFEFOCompletion(Result, AdditionalParameters) Export 
	
	If Not Result Then
		
		Return;
		
	EndIf;
	
	If Not FillInSeriesByFEFOServer() Then
		
		ProductsClient.WarnAboutAbsenceOfLinesFilledByFEFO();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure HowToFillInTheCalculationArticle(Command)
	
	FillInTheCostingItem("SupplyWithMaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure ProvisionToCancelTheSelectedRow(Command)
	
	CancelSelectedLines("SupplyWithMaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure SoftwareToHideCancelledLines(Command)
	
	FulfillmentHideCanceledLines =  Not FulfillmentHideCanceledLines;
	
	If FulfillmentHideCanceledLines Then
		Items.SupplyWithMaterialsAndWorks.RowFilter = New FixedStructure("Canceled", False);
	Else
		Items.SupplyWithMaterialsAndWorks.RowFilter = Undefined;
	EndIf;
	
	Items.SoftwareToHideCancelledLines.Check = FulfillmentHideCanceledLines;
	
EndProcedure

&AtClient
Procedure ProvisionOfMaterialsAndWorksIncludeSeparateProvision(Command)
	
	ProvidingSetAction("FLAG_UNITED");
	
EndProcedure

&AtClient
Procedure ProvisionOfMaterialsAndWorksTurnOffSeparateProvision(Command)
	
	ProvidingSetAction("FLAG_NOTABLE");
	
EndProcedure

&AtClient
Procedure ProvisionOfMaterialsAndWorksToEnsure(Command)
	
	ProvidingSetActionWithQuestion("ACTION_COOPERATION");
	
EndProcedure

&AtClient
Procedure ReserveCollateralAsItBecomesAvailable(Command)
	
	ProvidingSetAction("ACTION_RESERVATION_REFERENCES");
	
EndProcedure

&AtClient
Procedure ProvisionOfMaterialsAndWorksShouldNotBeProvided(Command)
	
	ProvidingSetActionWithQuestion("ACTION_NOTABLE");
	
EndProcedure

&AtClient
Procedure ProvisionOfMaterialsAndWorksShip(Command)
	
	ProvidingSetActionWithQuestion("Action_Ship_PRIORITY_WithAssignment");
	
EndProcedure

&AtClient
Procedure ProvisionOfMaterialsAndWorksReserve(Command)
	
	ProvidingSetActionWithQuestion("Action_ToReserve__PRIORITY_WithAssignment");
	
EndProcedure

#EndRegion

#Region MaterialsAndWorksConsumption

&AtClient
Procedure MaterialAndWorkConsumptionCopyLines(Command)
	
	CopyTSLines("MaterialsAndWorksConsumption");
	
EndProcedure

&AtClient
Procedure MaterialAndWorkConsumptionInsertLines(Command)
	
	If Not CheckBlockDocuments() Then
		Return;
	EndIf;
	
	GetLinesFromClipboard("MaterialsAndWorksConsumption");
	
EndProcedure

&AtClient
Procedure ConsumptionOfMaterialsAndWorksFillInAccordingToTheDataProvidedByTheSoftware(Command)
	
	If Not CheckBlockDocuments() Then
		Return;
	EndIf;
	
	If Object.MaterialsAndWorksConsumption.Count() <> 0 Then
		QueryText = NStr("vi = 'Điền lại phần bảng theo dữ liệu đảm bảo
									|có tính đến nguyên vật liệu không tiêu hao?';
									|ru = 'Перезаполнить табличную часть по данным обеспечения
									|с учетом неизрасходованных материалов?';
									|en = 'Refill the table according to supply data 
									|considering unused materials?'; fa = 'Refill the table according to supply data 
									|considering unused materials?';
									|it = 'Ricompilare la parte tabulare secondo i dati di approvvigionamento
									|tenendo conto dei materiali non utilizzati?';
									|pl = 'Wypełnić ponownie tabelaryczną część wg danych zaopatrzenia
									|z uwzględnieniem niezużytych materiałów?';
									|tr = 'Sarf edilmeyen malzemeler dikkate alınarak
									|temin verilerine göre tablo bölümü yeniden doldurulsun mu?'");
		CallbackDescription = New CallbackDescription("ConsumptionOfMaterialsAndWorksFillInAccordingToTheDataProvidedByTheSoftwareCompletion", ThisObject);
		ButtonsList = New ValueList;
		ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Điền';
													|ru = 'Заполнить';
													|en = 'Fill'; fa = 'پرکردن';
													|it = 'Compilare';
													|pl = 'Fill';
													|tr = 'Doldur'"));
		ButtonsList.Add(DialogReturnCode.Cancel);
		ShowQueryBox(CallbackDescription, QueryText, ButtonsList); 
	Else
		ConsumptionOfMaterialsAndWorksFillInAccordingToTheDataProvidedByTheSoftwareCompletion(DialogReturnCode.Yes, Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure ConsumptionOfMaterialsAndWorksFillInAccordingToTheDataProvidedByTheSoftwareCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		FillInConsumptionOfMaterialsAndWorkOnProvisionDataOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure MaterialAndWorkConsumptionSplitLine_3(Command)
	
	BreakTSString("MaterialsAndWorksConsumption");
	
EndProcedure

&AtClient
Procedure MaterialAndWorkConsumptionFillInTheExpenseDate(Command)
	
	SelectedRows = GetSelectedRowsInList("MaterialsAndWorksConsumption");
	If Not ValueIsFilled(SelectedRows) Then
		Return;
	EndIf;
	If Not CheckBlockDocuments() Then
		Return;
	EndIf;
	
	Notification = New CallbackDescription("MaterialAndWorkConsumptionFillInTheExpenseDateCompletion", ThisObject, SelectedRows);
	TMCommonUseClient.EnterDateWithControlOfEmptyValue(
			StartOfDayCurSessionDate(), 
			NStr("vi = 'Nhập ngày tiêu thụ nguyên vật liệu (nhân công)';
				|ru = 'Введите дату расхода материалов (работ)';
				|en = 'Enter the material (work) consumption date'; fa = 'Enter the material (work) consumption date';
				|it = 'Inserite la data di consumo materiali (lavori)';
				|pl = 'Wprowadź datę wydatkowania materiałów (pracy)';
				|tr = 'Malzemelerin (işlerin) sarfiyat tarihini girin'"), 
			DateFractions.Date, Notification);
	
EndProcedure

&AtClient
Procedure MaterialAndWorkConsumptionFillInTheExpenseDateCompletion(SelectedDate, SelectedRows) Export
	
	If ValueIsFilled(SelectedDate) Then
		For Each RowID In SelectedRows Do
			TableRow = Object.MaterialsAndWorksConsumption.FindByID(RowID);
			TableRow.DateOfMaterialWorkConsumption = SelectedDate;
		EndDo;
	EndIf; 
	
EndProcedure

&AtClient
Procedure ConsumptionOfMaterialsAndWorksPickUpGoods(Command)
	
	If Not CheckBlockDocuments() Then
		Return;
	EndIf;
	
	OpensGoodsSelection("MaterialsAndWorksConsumption");
	
EndProcedure

&AtClient
Procedure ConsumptionOfMaterialsAndWorksFillInTheCalculationArticle(Command)
	
	FillInTheCostingItem("MaterialsAndWorksConsumption");
	
EndProcedure

&AtClient
Procedure TheConsumptionOfMaterialsAndWorksShouldBeSupplementedAccordingToTheDataProvidedByTheSoftware(Command)
	
	If Not CheckBlockDocuments() Then
		Return;
	EndIf;
	
	FillInConsumptionOfMaterialsAndWorkOnProvisionDataOnServer(1);
	
EndProcedure


#EndRegion

#Region UnusedMaterials

&AtClient
Procedure SavingMaterialsCopyLines(Command)

	CopyTSLines("UnusedMaterials");
	
EndProcedure

&AtClient
Procedure SaveMaterialsInsertLines(Command)
	
	If Not CheckBlockDocuments() Then
		Return;
	EndIf;
	
	GetLinesFromClipboard("UnusedMaterials");
	
EndProcedure

&AtClient
Procedure SavingMaterialsSplitALine(Command)
	
	BreakTSString("UnusedMaterials");
	
EndProcedure

&AtClient
Procedure SavingMaterialsFillInUnspent(Command)
	
	If Not CheckBlockDocuments() Then
		Return;
	EndIf;
	
	If Object.UnusedMaterials.Count() <> 0 Then
		QueryText = NStr("vi = 'Điền lại phần bảng?';
						|ru = 'Перезаполнить табличную часть?';
						|en = 'Refill the table?'; fa = 'Refill the table?';
						|it = 'Ricompilare la parte tabulare?';
						|pl = 'Wypełnić ponownie część tabelaryczną?';
						|tr = 'Tablo bölümü yeniden doldurulsun mu?'");
		CallbackDescription = New CallbackDescription("SavingMaterials_FillWithUnspentMaterials_", ThisObject);
		ButtonsList = New ValueList;
		ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Điền';
													|ru = 'Заполнить';
													|en = 'Fill'; fa = 'پرکردن';
													|it = 'Compilare';
													|pl = 'Fill';
													|tr = 'Doldur'"));
		ButtonsList.Add(DialogReturnCode.Cancel);
		ShowQueryBox(CallbackDescription, QueryText, ButtonsList); 
	Else
		SavingMaterials_FillWithUnspentMaterials_(DialogReturnCode.Yes, Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure SavingMaterials_FillWithUnspentMaterials_(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		FillWithUnspentMaterialsOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure MaterialSavingFillInExpenseItem(Command)
	
	SelectedRows = GetSelectedRowsInList("UnusedMaterials");
	If Not ValueIsFilled(SelectedRows) Then
		Return;
	EndIf;
	If Not CheckBlockDocuments() Then
		Return;
	EndIf;
	
	If Items.UnusedMaterials.SelectedRows.Count() = 0 Then
		WarningText = NStr("vi = 'Cần chọn các chứng từ mà bạn muốn điền vào một mục chi phí.';
							|ru = 'Необходимо выбрать материалы, для которых требуется заполнить статью расходов.';
							|en = 'Select materials to fill in the expense item for.'; fa = 'Select materials to fill in the expense item for.';
							|it = 'È necessario scegliere i materiali per i quali è necessario compilare una voce di spesa.';
							|pl = 'Należy wybrać materiały, dla których trzeba wypełnić pozycję wydatków.';
							|tr = 'Gider kaleminin doldurulması gereken malzemeleri seçmeniz gerekmektedir.'");
		ShowMessageBox(,WarningText);
		Return;
	EndIf;
	
	IDs = New Array;
	For Each RowID In SelectedRows Do
		RowData = Object.UnusedMaterials.FindByID(RowID);
		If RowData.ToExpenseAs Then
			IDs.Add(RowID);
		EndIf;
	EndDo;
	
	If IDs.Count() = 0 Then
		WarningText = NStr("vi = 'Trong các dòng được chọn không có nguyên vật liệu mà cần điền dạng chi phí.';
							|ru = 'В выделенных строках отсутствуют материалы, для которых требуется заполнить статью расходов.';
							|en = 'There are no materials in the selected lines for which expense item population is required.'; fa = 'There are no materials in the selected lines for which expense item population is required.';
							|it = 'Nelle linee selezionate non ci sono materiali per i quali è necessario compilare una voce di spesa.';
							|pl = 'W zaznaczonych wierszach brak materiałów, dla których trzeba wypełnić pozycję wydatków.';
							|tr = 'Belirtilen satırlarda, gider kaleminin doldurulması gereken malzemeler bulunmamaktadır.'");
		ShowMessageBox(,WarningText);
		Return;
	EndIf;
	
	IncomeAndExpensesClient.FillInArticleAndAnalyticsInSelectedLines(ThisObject, Items.UnusedMaterialsExpenseItem, SelectedRows);
	
	IDs = New Array;
	For Each RowID In SelectedRows Do
		RowData = Object.UnusedMaterials.FindByID(RowID);
		If RowData.ToExpenseAs Then
			IDs.Add(RowID);
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure MaterialSavingFillInDate(Command)
	
	SelectedRows = GetSelectedRowsInList("UnusedMaterials");
	If Not ValueIsFilled(SelectedRows) Then
		Return;
	EndIf;
	If Not CheckBlockDocuments() Then
		Return;
	EndIf;
	
	Notification = New CallbackDescription("MaterialSavingFillInDateCompletion", ThisObject, SelectedRows);
	TMCommonUseClient.EnterDateWithControlOfEmptyValue(
			StartOfDayCurSessionDate(), 
			NStr("vi = 'Nhập ngày chuyển (ghi giảm)';
				|ru = 'Введите дату передачи (списания)';
				|en = 'Enter transfer (write-off) date'; fa = 'Enter transfer (write-off) date';
				|it = 'Inserire data di trasferimento (cancellazione)';
				|pl = 'Wybierz datę przekazana (wyksięgowania)';
				|tr = 'Transfer (gider yazma) tarihini girin'"),
			DateFractions.Date, Notification);
	
EndProcedure

&AtClient
Procedure MaterialSavingFillInDateCompletion(SelectedDate, ArrayOfSelectedRows) Export

	If ValueIsFilled(SelectedDate) Then
		For Each RowID In ArrayOfSelectedRows Do
			TableRow = Object.UnusedMaterials.FindByID(RowID);
			TableRow.DateOfTransaction = SelectedDate;
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Procedure SavingMaterialsSpecifyTheSeries(Command)
	
	OpenSelectionOfSeries("UnusedMaterials");
	
EndProcedure

#EndRegion

#Region LaborCosts

&AtClient
Procedure TheEffortToSplitTheString(Command)
	
	BreakTSString("LaborCosts");
	
EndProcedure

&AtClient
Procedure LaborCostsInsertLines(Command)
	
	If Not CheckBlockDocuments() Then
		Return;
	EndIf;
	
	GetLinesFromClipboard("LaborCosts");
	
EndProcedure

&AtClient
Procedure TheEffortToCopyRows(Command)
	
	CopyTSLines("LaborCosts");
	
EndProcedure

&AtClient
Procedure LaborCostsFillInThePerformersInTheHighlightedLines(Command)
	
	SelectedRows = GetSelectedRowsInList("LaborCosts");
	If Not ValueIsFilled(SelectedRows) Then
		Return;
	EndIf;
	If Not CheckBlockDocuments() Then
		Return;
	EndIf;
	
	RowData = Object.LaborCosts.FindByID(SelectedRows[0]);
	
	ObjectStage = ObjectIsCreatedByReference(ThisForm, RowData.Ref);
	CallbackDescription = New CallbackDescription("LaborCostsFillInThePerformersInTheHighlightedLinesCompletion", ThisObject, New Structure("IDs", SelectedRows));
	
	ProductionClient.OpenArtistSelectionForm(
		ObjectStage.Organization,
		RowData.Department,
		RowData.Performer,
		RowData.ExecutionDate,
		,
		CallbackDescription);
	
EndProcedure

&AtClient
Procedure LaborCostsFillInThePerformersInTheHighlightedLinesCompletion(ValueSelected, AdditionalParameters) Export
	
	If ValueIsFilled(ValueSelected) Then
		
		For Each RowID In AdditionalParameters.IDs Do
			
			RowData = Object.LaborCosts.FindByID(RowID);
			RowData.Performer = ValueSelected;
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure LaborCostsFillInTheCalculationArticleInTheHighlightedLines(Command)
	
	FillInTheCostingItem("LaborCosts");
	
EndProcedure

&AtClient
Procedure LaborCostsFillInAccordingToTheSpecification(Command)

	If Not CheckBlockDocuments() Then
		Return;
	EndIf;
	
	If Object.LaborCosts.Count() <> 0 Then
		QueryText = NStr("vi = 'Điền phần bảng theo bảng kê chi tiết các nguồn lực sản xuất?';
						|ru = 'Перезаполнить табличную часть по спецификации?';
						|en = 'Refill the table according to BOM?'; fa = 'Refill the table according to BOM?';
						|it = 'Ricompilare la parte tabulare secondo la specifica?';
						|pl = 'Wypełnić ponownie tabelaryczną część według specyfikacji?';
						|tr = 'Tablo bölümü ürün reçetesine göre yeniden doldurulsun mu?'");
		CallbackDescription = New CallbackDescription("LaborCostsFillInAccordingToTheSpecificationCompletion", ThisObject);
		ButtonsList = New ValueList;
		ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Điền';
													|ru = 'Заполнить';
													|en = 'Fill'; fa = 'پرکردن';
													|it = 'Compilare';
													|pl = 'Wypełnij';
													|tr = 'Doldur'"));
		ButtonsList.Add(DialogReturnCode.Cancel);
		ShowQueryBox(CallbackDescription, QueryText, ButtonsList); 
	Else
		LaborCostsFillInAccordingToTheSpecificationCompletion(DialogReturnCode.Yes, Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure LaborCostsFillInAccordingToTheSpecificationCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		FillInLaborCostsAccordingToSpecificationOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure LaborCostsShowStandards(Command)
	
	SavedInSettingsDataModified = True;
	
	ShowStandardsLaborCosts = Not ShowStandardsLaborCosts;
	ShowStandardsWhenChangingOnServer("LaborCosts");
	
EndProcedure

&AtClient
Procedure LaborCostsCancelSelectedLines(Command)
	
	CancelSelectedLines("LaborCosts");
	
EndProcedure

&AtClient
Procedure LaborCosts_HideCanceledRows(Command)
	
	LaborCostsHideCanceledLines =  Not LaborCostsHideCanceledLines;
	
	If LaborCostsHideCanceledLines Then
		Items.LaborCosts.RowFilter = New FixedStructure("Canceled", False);
	Else
		Items.LaborCosts.RowFilter = Undefined;
	EndIf;
	
	Items.LaborCosts_HideCanceledRows.Check = LaborCostsHideCanceledLines;
	
EndProcedure

#EndRegion

#Region ManufacturingProcess

&AtClient
Procedure Stages_AddProductionStage(Command)
	
	If Not CheckBlockDocuments() Then
		Return;
	EndIf;
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Stages, ThisObject);
		
	AddNewDocument();
	
	ConfigureDependentFormElements(ThisObject, "ManufacturingProcess");
	
EndProcedure

&AtClient
Procedure Stages_AddWorkPlanningStage(Command)
	
	If Not CheckBlockDocuments() Then
		Return;
	EndIf;
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Stages, ThisObject);
		
	AddNewDocument(, New Structure("WorkPlanning", True));
	
	ConfigureDependentFormElements(ThisObject, "ManufacturingProcess");
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region Stages

&AtClient
Procedure AddNewDocument(RowID = Undefined, FillingData = Undefined)
	
	If RowID = Undefined Then
		RowData = Object.Stages.Add();
	Else
		RowData = Object.Stages.FindByID(RowID);
	EndIf;
	
	RowData.IsNew = True;
	RowData.Ref = GetNewDocumentLink();
	RowData.MainProductProducts = Object.MainProductProducts;
	If FillingData <> Undefined Then
		FillPropertyValues(RowData, FillingData);
	EndIf;
	
	WhenAddingNewDocument(RowData.Ref);
	
	Modified = True;
	
EndProcedure

&AtServer
Procedure WhenAddingNewDocument(RefToNew)
	
	NewStageFillValues = ProductionManagementServerCall.ValuesForFillingNewProductionStage(
		Object.ReferenceOrder,
		Object.AssignmentProducts,
		Object.ProductionLot,
		Object.ProductionProcessType,
		Object.BillOfMaterials);
	
	ObjectStage = ObjectIsCreatedByReference(ThisForm, RefToNew);
	FillPropertyValues(ObjectStage, NewStageFillValues);
	
	ObjectStage.Status = PredefinedValue("Enum.StatusesOfProductionStages2_2.Generated1");
	ObjectStage.MethodOfAllocatingFinishedProductCosts = MethodOfAllocatingFinishedProductCosts;
	ObjectStage.UnitOfMeasureOfStageDuration = Enums.TimeMeasureUnits.Day;
	ObjectStage.Purpose = Catalogs.Assignments.GetRef();
	
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("Products", Object.MainProductProducts);
	TheStructureOfTheSearch.Insert("Characteristic", Object.MainProductCharacteristic);
	TheStructureOfTheSearch.Insert("Canceled", False);
	
	FoundRows = New Array;
	If Object.ProductionProcessType = Enums.ProductionProcessTypes.Assembly
			Or Object.ProductionProcessType = Enums.ProductionProcessTypes.Repair
			Or Object.ProductionProcessType = Enums.ProductionProcessTypes.PerformRM
			Or Object.ProductionProcessType = Enums.ProductionProcessTypes.WithoutBillsOfMaterials Then
		FoundRows = Object.ManufacturedProducts.FindRows(TheStructureOfTheSearch);
	ElsIf Object.ProductionProcessType = Enums.ProductionProcessTypes.Disassembly Then
		FoundRows = Object.SupplyWithMaterialsAndWorks.FindRows(TheStructureOfTheSearch);
	EndIf;
	
	If FoundRows.UBound() <> -1 Then
		
		Package = Undefined;
		Count = 0;
		NumberOfPackages = 0;
		
		For Each String In FoundRows Do
			
			If Count = 0 Then
				Package = String.Package;
			ElsIf Package <> Undefined
				And Package <> String.Package Then
				Package = Undefined;
			EndIf;
			
			Count = Count + String.Count;
			NumberOfPackages = NumberOfPackages + String.NumberOfPackages;
			
		EndDo;
		
		ObjectStage.NumberOfPackagesPlan = ?(Package = Undefined, Count, NumberOfPackages);
		ObjectStage.PackagePlan = Package;
		ObjectStage.PackageActualData = Package;
		ObjectStage.PackageCanceled = Package;
		
	EndIf;
	
	RenumberStepsWhenAddingNewLine(
		ObjectStage,
		Object.Stages);
	
	ObjectStage.ParametersForFillingAssignments = ProductionSupply.ActionParametersFillInPurposeOfProvisionInProductionPhase(
		ObjectStage, Object.ManufacturedProducts);
	ProductionSupply.FillInListOfSelectedAssignmentsInProductionPhase(
		ObjectStage, Object.ManufacturedProducts, ObjectStage.AppointmentSelectionList);
	
EndProcedure

&AtClientAtServerNoContext
Procedure RenumberStepsWhenAddingNewLine(NewRow, StageList)
	
	NewNumber = 1;
	For Each String In StageList Do
		NewNumber = Max(NewNumber, String.StageNumber + 1);
	EndDo;
	
	NewRow.StageNumber           = NewNumber;
	NewRow.NextStageNo = ?(NewNumber > 1, NewNumber + 1, 0);
	
	If NewNumber = 2 And StageList.Count() = 2 Then
		For Each String In StageList Do
			If String.StageNumber = 1 And String.NextStageNo = 0 Then
				String.NextStageNo = NewNumber;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function PictureIndex(String)
	
	Return ?(String.IsNew, 0, 1);
	
EndFunction

&AtServer
Function ItIsRequiredToAskQuestionBeforeDeletingStages(SelectedRows)
	
	ListOfTS = ListOfNestedTableParts(False);
	
	For Each Id In SelectedRows Do
		
		RowData = Object.Stages.FindByID(Id);
		
		Filter = New Structure("Ref", RowData.Ref);
		
		For Each TSName In ListOfTS Do
			
			If Object[TSName].FindRows(Filter).UBound() <> -1 Then
				Return True;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	Return False;
	
EndFunction

&AtClient
Procedure AskQuestionBeforeDeletingStages(SelectedRows)
	
	CallbackDescription = New CallbackDescription("AnswerQuestionBeforeDeletingStages", ThisObject, SelectedRows);
	
	If SelectedRows.Count() > 1 Then
		QueryText = NStr("vi = 'Chọn bước sử dụng, tiếp tục?';
						|ru = 'Выбранные этапы используются, продолжить?';
						|en = 'Selected stages are used. Continue?'; fa = 'Selected stages are used. Continue?';
						|it = 'Le fasi selezionate vengono utilizzate, continuare?';
						|pl = 'Wybrane etapy są używane, kontynuować?';
						|tr = 'Seçilen aşamalar kullanılmaktadır, devam edilsin mi?'");
	Else
		QueryText = NStr("vi = 'Các công đoạn được chọn được sử dụng, tiếp tục?';
						|ru = 'Выбранный этап используется, продолжить?';
						|en = 'The selected stage is in use. Continue?'; fa = 'The selected stage is in use. Continue?';
						|it = 'La fase selezionata viene utilizzata, continuare?';
						|pl = 'Wybrany etap jest używany, kontynuować?';
						|tr = 'Seçilen aşama kullanılmaktadır, devam edilsin mi?'");
	EndIf;
	
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure AnswerQuestionBeforeDeletingStages(TheUserResponse, SelectedRows) Export
	
	If TheUserResponse = DialogReturnCode.Yes Then
		
		RemoveStagesFromList(SelectedRows);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure RemoveStagesFromList(SelectedRows)
	
	Modified = True;
	ListOfTS = ListOfNestedTableParts();
	
	For Each Id In SelectedRows Do
		
		RowData = Object.Stages.FindByID(Id);
		
		Filter = New Structure("Ref", RowData.Ref);
		
		For Each TSName In ListOfTS Do
			
			FoundRows = Object[TSName].FindRows(Filter);
			
			For Each String In FoundRows Do
				Object[TSName].Delete(String);
			EndDo;
			
		EndDo;
		
		If RowData.IsNew Then
			Object.Stages.Delete(RowData);
			Continue;
		EndIf;
		
		RowData.DeletionMark = True;
		
	EndDo;
	
	FillInDefaultLink();
	
	ConfigureDependentFormElements(ThisForm);

EndProcedure

#EndRegion

#Region FillChecking

&AtServer
Procedure CheckHeaderDetails_(Cancel)
	
	If Not ValueIsFilled(Object.MainProductCharacteristic)
		And DataStructureMainProduct.ItemVariantsAreUsed Then
		
		MessageText = CommonClientServer.FillingErrorText("Field", "FillType", NStr("vi = 'Đặc tính';
																					|ru = 'Характеристика';
																					|en = 'Variant'; fa = 'گونه';
																					|it = 'Caratteristica';
																					|pl = 'Charakterystyka';
																					|tr = 'Varyant'"));
		
		CommonClientServer.MessageToUser(
			MessageText,,
			"MainProductCharacteristic",
			"Object",
			Cancel);
		
	EndIf;
	
	If Not ValueIsFilled(Object.UnderRepairVariant)
		And FinishedProductBeingRepairedCharacteristicsAreUsed Then
		
		MessageText = CommonClientServer.FillingErrorText("Field", "FillType", NStr("vi = 'Đặc tính (sản phẩm được sửa chữa)';
																					|ru = 'Характеристика (ремонтируемое изделие)';
																					|en = 'Variant (product under R&M)'; fa = 'گونه (محصول تحت تعمیر و نگهداری)';
																					|it = 'Variant (product under R&M)';
																					|pl = 'Variant (product under R&M)';
																					|tr = 'Özellik (Bakım onarımı yapılan ürün)'"));
		
		CommonClientServer.MessageToUser(
			MessageText,,
			"UnderRepairVariant",
			"Object",
			Cancel);
		
	EndIf;
	
	If Not ValueIsFilled(MethodOfAllocatingFinishedProductCosts) Then
		
		MessageText = CommonClientServer.FillingErrorText("Field", "FillType", NStr("vi = 'Phương pháp phân bổ chi phí';
																					|ru = 'Способ распределения затрат';
																					|en = 'Costs allocation method'; fa = 'روش تسهیم هزینه‌ها';
																					|it = 'Modalità allocazione dei costi';
																					|pl = 'Sposób podziału kosztów';
																					|tr = 'Maliyet dağıtım yöntemi'"));
		
		CommonClientServer.MessageToUser(
			MessageText,,
			"MethodOfAllocatingFinishedProductCosts",,
			Cancel);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure CheckProductionProcess(NotCheckedAttributeArray, Cancel)
	
	NotCheckedAttributeArray.Add("Department");
	
	ListName = NStr("vi = 'Quy trình sản xuất';
					|ru = 'Производственный процесс';
					|en = 'Production process'; fa = 'فرایند تولید';
					|it = 'Processo industriale';
					|pl = 'Proces produkcyjny';
					|tr = 'Üretim süreci'");
	
	Rows = Object.Stages.FindRows(New Structure("DeletionMark", False));
	
	For Each String In Rows Do
		
		If Not ValueIsFilled(String.StageNumber) Then
			
			MessageText = CommonClientServer.FillingErrorText("Column", "FillType", NStr("vi = 'Số công đoạn';
																						|ru = 'Номер этапа';
																						|en = 'Stage number'; fa = 'شماره مرحله';
																						|it = 'Numero della fase';
																						|pl = 'Numer etapu';
																						|tr = 'Aşama numarası'"), String.LineNumber, ListName);
			Field = PathToTabularSection("Stages", String.LineNumber, "StageNumber");
			
			CommonClientServer.MessageToUser(
				MessageText,,
				Field,,
				Cancel);
			
		EndIf;
		
		If String.NextStageNo <> 0 And String.StageNumber >= String.NextStageNo Then
			
			MessageText = NStr("vi = 'Số công đoạn tiếp theo phải lớn hơn số công đoạn.';
								|ru = 'Номер следующего этапа должен быть больше номера этапа.';
								|en = 'Next stage number should be more than the stage number.'; fa = 'Next stage number should be more than the stage number.';
								|it = 'Il numero della fase successiva deve essere superiore al numero della fase.';
								|pl = 'Numer kolejnego etapu musi być większy niż numer etapu.';
								|tr = 'Sonraki işlem numarası, aşama numarasından büyük olmalıdır.'");
			Field = PathToTabularSection("Stages", String.LineNumber, "NextStageNo");
			
			CommonClientServer.MessageToUser(
				MessageText,,
				Field,,
				Cancel);
			
		EndIf;
		
		If Not ValueIsFilled(String.NameEdit) Then
			
			MessageText = CommonClientServer.FillingErrorText("Column", "FillType", NStr("vi = 'Tên gọi';
																						|ru = 'Наименование';
																						|en = 'Description'; fa = 'شرح';
																						|it = 'Nome';
																						|pl = 'Nazwa';
																						|tr = 'Tanım'"), String.LineNumber, ListName);
			Field = PathToTabularSection("Stages", String.LineNumber, "NameEdit");
			
			CommonClientServer.MessageToUser(
				MessageText,,
				Field,,
				Cancel);
			
		EndIf;
		
		If Not ValueIsFilled(String.Department) Then
			
			MessageText = CommonClientServer.FillingErrorText("Column", "FillType", NStr("vi = 'Bộ phận';
																						|ru = 'Подразделение';
																						|en = 'Business unit'; fa = 'Business unit';
																						|it = 'Reparto';
																						|pl = 'Dział';
																						|tr = 'Departman'"), String.LineNumber, ListName);
			Field = PathToTabularSection("Stages", String.LineNumber, "Department");
			
			CommonClientServer.MessageToUser(
				MessageText,,
				Field,,
				Cancel);
			
		EndIf;
		
		If String.UseOperationManagement Then
			
			If Not ValueIsFilled(String.TechnologicalProcessFactor)
				And Not String.TechnologicalProcess.IsEmpty() Then
			
				MessageText = CommonClientServer.FillingErrorText("Column", "FillType", NStr("vi = 'Hệ số';
																							|ru = 'Коэффициент';
																							|en = 'Coefficient'; fa = 'ضریب';
																							|it = 'Coefficiente';
																							|pl = 'Współczynnik';
																							|tr = 'Katsayı'"), String.LineNumber, ListName);
				Field = PathToTabularSection("Stages", String.LineNumber, "TechnologicalProcessFactor");
				
				CommonClientServer.MessageToUser(
					MessageText,,
					Field,,
					Cancel);
				
			EndIf;
			
		EndIf;
		
		If String.NumberOfPackagesPlan = 0
			And Object.ProductionProcessType <> Enums.ProductionProcessTypes.WithoutBillsOfMaterials Then
			
			MessageText = CommonClientServer.FillingErrorText("Column", "FillType", NStr("vi = 'Dự tính';
																						|ru = 'Запланировано';
																						|en = 'Scheduled'; fa = 'برنامه‌ریزی‌شده';
																						|it = 'Pianificato';
																						|pl = 'Zaplanowano';
																						|tr = 'Planlandı'"), String.LineNumber, ListName);
			Field = PathToTabularSection("Stages", String.LineNumber, "NumberOfPackagesPlan");
			
			CommonClientServer.MessageToUser(
				MessageText,,
				Field,,
				Cancel);
				
		EndIf;
		
	EndDo;
	
	If Object.ProductionProcessType = Enums.ProductionProcessTypes.Disassembly
		And Rows.Count() > 1
		And GetFunctionalOption("DynamicStructureOfProductionOrders") Then
		
		MessageText = NStr("vi = 'Không hỗ trợ quy trình sản xuất phân rã theo nhiều công đoạn.';
							|ru = 'Не поддерживаются многоэтапные разборочные производственные процессы.';
							|en = 'Multi-stage disassembly production processes are not supported.'; fa = 'Multi-stage disassembly production processes are not supported.';
							|it = 'Multi-stage disassembly production processes are not supported.';
							|pl = 'Multi-stage disassembly production processes are not supported.';
							|tr = 'Çok aşamalı demontaj üretim süreçleri desteklenmemektedir.'");
		Common.MessageToUser(MessageText,,,,Cancel);
		
	EndIf;
	
	CheckSequenceOfSteps(Cancel);
	
	CheckOrderOfReleaseOfIntermediateSemiFinishedProducts(Cancel);
	
EndProcedure

&AtServer
Procedure CheckSequenceOfSteps(Cancel)
	
	ColumnsNames = "StageNumber,NextStageNo,NameEdit";
	NewColumnNames = New Structure(ColumnsNames, "OperationNumber", "NextOperation", "Presentation");
	NewColumns = New Structure("Operation, ThereIsNoNextOperation, NextOperationNumberField",,False,"");
	ColumnsNames = ColumnsNames+",WorkPlanning";
	
	StructureOfChecks = New Structure;
	StructureOfChecks.Insert("NoLastOperation", NStr("vi = 'Không có công đoạn cuối.';
													|ru = 'Отсутствует последний этап.';
													|en = 'The last stage is missing.'; fa = 'The last stage is missing.';
													|it = 'Ultima fase mancante.';
													|pl = 'Brak ostatniego etapu.';
													|tr = 'Son aşama eksik.'"));
	StructureOfChecks.Insert("ThereIsNoNextOperation", NStr("vi = 'Công đoạn ""%1"" chỉ một công đoạn không tồn tại.';
															|ru = 'Этап ""%1"" ссылается на несуществующий этап.';
															|en = 'Stage ""%1"" refers to a non-existing stage.'; fa = 'Stage ""%1"" refers to a non-existing stage.';
															|it = 'La fase ""%1"" rimanda ad una fase non esistente.';
															|pl = 'Etap ""%1"" odwołuje się do nieistniejącego etapu.';
															|tr = '""%1"" aşaması, var olmayan bir işlemi ifade etmektedir.'"));
	
	If Object.ProductionProcessType = Enums.ProductionProcessTypes.Assembly
		Or Object.ProductionProcessType = Enums.ProductionProcessTypes.Repair Then
		StructureOfChecks.Insert("FewRecentOperations", NStr("vi = 'Không thể có nhiều công đoạn cuối.';
															|ru = 'Не может быть несколько последних этапов.';
															|en = 'There cannot be more than one last stage.'; fa = 'There cannot be more than one last stage.';
															|it = 'Non vi possono essere più fasi finali.';
															|pl = 'Nie może być kilku ostatnich etapów.';
															|tr = 'Birden fazla son aşama olamaz.'"));
	ElsIf Object.ProductionProcessType = Enums.ProductionProcessTypes.PerformRM Then
		StructureOfChecks.Insert("WorkPlanningStageIsLast", NStr("vi = 'Công đoạn lập kế hoạch công việc ""%1"" không phải là công đoạn cuối cùng.';
																|ru = 'Этап планирования работ ""%1"" не может быть последним.';
																|en = 'The ""%1"" work planning stage cannot be the last one.'; fa = 'The ""%1"" work planning stage cannot be the last one.';
																|it = 'The ""%1"" work planning stage cannot be the last one.';
																|pl = 'The ""%1"" work planning stage cannot be the last one.';
																|tr = 'İş planlama aşaması ""%1"" son aşama olamaz.'"));
		NewColumns.Insert("WorkPlanningStageIsLast", False);
	EndIf;
	
	Filter = New Structure("DeletionMark", False);
	TransactionList = TMCommonUse.ExportValuesTable(Object.Stages, Filter, ColumnsNames, NewColumns, NewColumnNames);
	
	Filter = New Structure("OperationNumber");
	
	For Each String In TransactionList Do
		
		If ValueIsFilled(String.NextOperation) Then
			
			Filter.OperationNumber = String.NextOperation;
			
			If TransactionList.FindRows(Filter).UBound() = -1 Then
				
				String.ThereIsNoNextOperation = True;
				String.NextOperationNumberField = "ChainOfStages[" + TransactionList.IndexOf(String) + "].NextStageNo";
				
			EndIf;
			
		EndIf;
		
		If String.NextOperation = 0 And String.WorkPlanning Then
			String.WorkPlanningStageIsLast = True;
		EndIf;
		
	EndDo;
	
	HasErrors = Not ProductionProcessEditor.SequenceOfListOfOperationsIsCorrect(TransactionList, StructureOfChecks);
	If HasErrors Then
		Cancel = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure CheckOrderOfReleaseOfIntermediateSemiFinishedProducts(Cancel)
	
	Query = New Query(
	"SELECT
	|	Stages.Ref AS Ref,
	|	Stages.StageNumber AS StageNumber
	|
	|INTO TTStages
	|FROM
	|	&Stages AS Stages
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	IntermediateSemiFinishedProducts.Ref AS CurrentStep,
	|	StagesOfDevelopment.Ref           AS NextStage
	|
	|INTO TTCommunication
	|FROM
	|	Document.ProductionStage2_2.SideAndIntermediateRelease AS IntermediateSemiFinishedProducts
	|
	|		INNER JOIN Document.ProductionStage2_2 AS StagesOfDevelopment
	|			ON IntermediateSemiFinishedProducts.Purpose = StagesOfDevelopment.Purpose
	|
	|WHERE
	|	IntermediateSemiFinishedProducts.Ref.Posted
	|	
	|	AND (IntermediateSemiFinishedProducts.Ref, StagesOfDevelopment.Ref) IN
	|		(SELECT
	|			T.Ref,
	|			T.Ref
	|		FROM
	|			TTStages AS T)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TTCommunication.CurrentStep AS Ref
	|FROM
	|	TTCommunication AS TTCommunication
	|		INNER JOIN TTStages AS StageNumbers
	|			ON TTCommunication.CurrentStep = StageNumbers.Ref
	|		INNER JOIN TTStages AS NextStageNumbers
	|			ON TTCommunication.NextStage = NextStageNumbers.Ref
	|WHERE
	|	NextStageNumbers.StageNumber < StageNumbers.StageNumber");
	
	StageList = Object.Stages.Unload(New Structure("IsNew,DeletionMark",False,False), "Ref,StageNumber");
	Query.SetParameter("Stages", StageList);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		String = Object.Stages.FindRows(New Structure("Ref", Selection.Ref))[0];
		
		MessageText = NStr("vi = 'Đã vi phạm thứ tự của các công đoạn. Công đoạn xuất xưởng bán thành phẩm được đặt sau công đoạn tiêu dùng.';
							|ru = 'Нарушен порядок этапов. Этап, выпускающий полуфабрикаты, расположен после этапа-потребителя.';
							|en = 'Stage sequence is violated. Stage that releases semi-finished products is positioned after the consumer stage.'; fa = 'Stage sequence is violated. Stage that releases semi-finished products is positioned after the consumer stage.';
							|it = 'L''ordine delle fasi è violato. La fase della produzione dei semilavorati è collocata dopo la fase-consumatore.';
							|pl = 'Kolejność etapów jest naruszona. Etap produkcji półproduktów znajduje się po etapie-konsumencie.';
							|tr = 'Aşamaların sırası bozuldu. Yarı mamul ürün üreten aşama, tüketici aşamasından sonra yer almaktadır.'");
		Field = StrTemplate("Object.Stages[%1].NextStageNo", Object.Stages.IndexOf(String));
		
		CommonClientServer.MessageToUser(
			MessageText,,
			Field,,
			Cancel);
			
	EndDo;
	
EndProcedure

&AtServer
Procedure CheckOutputProducts(NotCheckedAttributeArray, Cancel)
	
	ListName = Metadata.DataProcessors.EditProductionStageSequence.TabularSections.ManufacturedProducts.Synonym;
	
	If (Object.ProductionProcessType = Enums.ProductionProcessTypes.Assembly
			Or Object.ProductionProcessType = Enums.ProductionProcessTypes.Repair
			Or Object.ProductionProcessType = Enums.ProductionProcessTypes.Disassembly)
		And Object.ManufacturedProducts.FindRows(New Structure("Canceled", False)).Count() = 0 Then
		
		Template = NStr("vi = 'Chưa nhập dòng nào trong danh sách ""%1""';
						|ru = 'Не введено ни одной строки в список ""%1""';
						|en = 'No line is entered into the ""%1"" list'; fa = 'No line is entered into the ""%1"" list';
						|it = 'Non è immessa alcuna riga nell''elenco ""%1""';
						|pl = 'Nie wprowadzono żadnego wiersza do listy ""%1""';
						|tr = '""%1"" listesine herhangi satır girilmedi'");
		MessageText = StrTemplate(Template, ListName);
		
		CommonClientServer.MessageToUser(
			MessageText,,
			"Object.ManufacturedProducts",,
			Cancel);
			
		Return;
	EndIf;
	
	ReleasingStages = New Array;
	
	Template = NStr("vi = 'Không có một dòng nào được nhập vào danh sách ""%1"" ở bước ""%2""';
					|ru = 'Не введено ни одной строки в список ""%1"" по этапу ""%2""';
					|en = 'No lines entered into the ""%1"" list by the ""%2"" stage'; fa = 'No lines entered into the ""%1"" list by the ""%2"" stage';
					|it = 'Non è immessa alcuna riga nell''elenco ""%1"" per la fase ""%2""';
					|pl = 'Nie wprowadzono żadnego wiersza do listy ""%1"" dla etapu ""%2""';
					|tr = '""%2"" aşamasına göre ""%1"" listesine herhangi bir satır girilmedi'");
	For Each String In Object.Stages Do
		
		If String.DeletionMark Then
			Continue;
		EndIf;
		
		If String.NextStageNo <> 0 Then
			Continue;
		EndIf;
		
		RowFilter = New Structure("Ref, Canceled", String.Ref, False);
		
		If Not Object.ProductionProcessType = Enums.ProductionProcessTypes.WithoutBillsOfMaterials
			And Object.ManufacturedProducts.FindRows(RowFilter).UBound() = -1 Then
			
			MessageText = StrTemplate(Template, ListName, String.NameEdit);
			
			CommonClientServer.MessageToUser(
				MessageText,,
				"Object.ManufacturedProducts",,
				Cancel);
			
		EndIf;
		
		ReleasingStages.Add(String.Ref);
		
	EndDo;
	
	For Each String In Object.ManufacturedProducts Do
		
		If Not ValueIsFilled(String.Ref) Then
			
			MessageText = CommonClientServer.FillingErrorText("Column", "FillType", NStr("vi = 'Công đoạn sản xuất';
																						|ru = 'Этап производства';
																						|en = 'Production stage'; fa = 'مرحله تولید';
																						|it = 'Fase di produzione';
																						|pl = 'Etap produkcji';
																						|tr = 'Üretim aşaması'"), String.LineNumber, ListName);
			Field = PathToTabularSection("ManufacturedProducts", String.LineNumber, "Ref");
			
			CommonClientServer.MessageToUser(
				MessageText,,
				Field,,
				Cancel);
			
		EndIf;
		
		If ValueIsFilled(String.Ref) And ReleasingStages.Find(String.Ref) = Undefined Then
			
			MessageText = CommonClientServer.FillingErrorText("Column", "Correctness", NStr("vi = 'Công đoạn sản xuất';
																							|ru = 'Этап производства';
																							|en = 'Production stage'; fa = 'مرحله تولید';
																							|it = 'Fase di produzione';
																							|pl = 'Etap produkcji';
																							|tr = 'Üretim aşaması'"), String.LineNumber, ListName);
			Field = PathToTabularSection("ManufacturedProducts", String.LineNumber, "StageName");
			
			CommonClientServer.MessageToUser(
				MessageText,,
				Field,,
				Cancel);
			
		EndIf;
		
	EndDo;
	
	CheckSharesOfCostOfOutputProducts(Cancel);
	
EndProcedure

&AtServer
Procedure CheckByProducts(NotCheckedAttributeArray, Cancel)
	
	ListName = Metadata.DataProcessors.EditProductionStageSequence.TabularSections.SideAndIntermediateRelease.Synonym;
	
	For Each String In Object.SideAndIntermediateRelease Do
		
		If Not ValueIsFilled(String.Ref) Then
			
			MessageText = CommonClientServer.FillingErrorText("Column", "FillType", NStr("vi = 'Công đoạn sản xuất';
																						|ru = 'Этап производства';
																						|en = 'Production stage'; fa = 'مرحله تولید';
																						|it = 'Fase di produzione';
																						|pl = 'Etap produkcji';
																						|tr = 'Üretim aşaması'"), String.LineNumber, ListName);
			Field = PathToTabularSection("SideAndIntermediateRelease", String.LineNumber, "StageName");
			
			CommonClientServer.MessageToUser(
				MessageText,,
				Field,,
				Cancel);
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure CheckProvisionOfMaterialsAndWorks(NotCheckedAttributeArray, Cancel)
	
	ListName = Metadata.DataProcessors.EditProductionStageSequence.TabularSections.SupplyWithMaterialsAndWorks.Synonym;

	If (Object.ProductionProcessType = Enums.ProductionProcessTypes.Disassembly
			And Object.SupplyWithMaterialsAndWorks.Count() = 0) Then
		
		Template = NStr("vi = 'Không có hàng nào được nhập trong danh sách ""%1""';
						|ru = 'Не введено ни одной строки в список ""%1""';
						|en = 'No line is entered into the ""%1"" list'; fa = 'No line is entered into the ""%1"" list';
						|it = 'Non è immessa alcuna riga nell''elenco ""%1""';
						|pl = 'Nie wprowadzono żadnego wiersza do listy ""%1""';
						|tr = '""%1"" listesine herhangi satır girilmedi'");
		MessageText = StrTemplate(Template, ListName);
		
		CommonClientServer.MessageToUser(
			MessageText,,
			"Object.SupplyWithMaterialsAndWorks",,
			Cancel);
			
		Return;
	EndIf;
	
	For Each String In Object.SupplyWithMaterialsAndWorks Do
		
		If Not ValueIsFilled(String.Ref) Then
			
			MessageText = CommonClientServer.FillingErrorText("Column", "FillType", NStr("vi = 'Công đoạn sản xuất';
																						|ru = 'Этап производства';
																						|en = 'Production stage'; fa = 'مرحله تولید';
																						|it = 'Fase di produzione';
																						|pl = 'Etap produkcji';
																						|tr = 'Üretim aşaması'"), String.LineNumber, ListName);
			Field = PathToTabularSection("SupplyWithMaterialsAndWorks", String.LineNumber, "StageName");
			
			CommonClientServer.MessageToUser(
				MessageText,,
				Field,,
				Cancel);
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure CheckConsumptionOfMaterialsAndWorks(NotCheckedAttributeArray, Cancel)
	
	ListName = Metadata.DataProcessors.EditProductionStageSequence.TabularSections.MaterialsAndWorksConsumption.Synonym;
	
	For Each String In Object.MaterialsAndWorksConsumption Do
		
		If Not ValueIsFilled(String.Ref) Then
			
			MessageText = CommonClientServer.FillingErrorText("Column", "FillType", NStr("vi = 'Công đoạn sản xuất';
																						|ru = 'Этап производства';
																						|en = 'Production stage'; fa = 'مرحله تولید';
																						|it = 'Fase di produzione';
																						|pl = 'Etap produkcji';
																						|tr = 'Üretim aşaması'"), String.LineNumber, ListName);
			Field = PathToTabularSection("MaterialsAndWorksConsumption", String.LineNumber, "StageName");
			
			CommonClientServer.MessageToUser(
				MessageText,,
				Field,,
				Cancel);
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure CheckSavingMaterials(NotCheckedAttributeArray, Cancel)
	
	ListName = Metadata.DataProcessors.EditProductionStageSequence.TabularSections.UnusedMaterials.Synonym;
	
	For Each String In Object.UnusedMaterials Do
		
		If Not ValueIsFilled(String.Ref) Then
			
			MessageText = CommonClientServer.FillingErrorText("Column", "FillType", NStr("vi = 'Công đoạn sản xuất';
																						|ru = 'Этап производства';
																						|en = 'Production stage'; fa = 'مرحله تولید';
																						|it = 'Fase di produzione';
																						|pl = 'Etap produkcji';
																						|tr = 'Üretim aşaması'"), String.LineNumber, ListName);
			Field = PathToTabularSection("UnusedMaterials", String.LineNumber, "StageName");
			
			CommonClientServer.MessageToUser(
				MessageText,,
				Field,,
				Cancel);
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure CheckLaborCosts(NotCheckedAttributeArray, Cancel)
	
	ListName = Metadata.DataProcessors.EditProductionStageSequence.TabularSections.LaborCosts.Synonym;
	
	For Each String In Object.LaborCosts Do
		
		If Not ValueIsFilled(String.Ref) Then
			
			MessageText = CommonClientServer.FillingErrorText("Column", "FillType", NStr("vi = 'Công đoạn sản xuất';
																						|ru = 'Этап производства';
																						|en = 'Production stage'; fa = 'مرحله تولید';
																						|it = 'Fase di produzione';
																						|pl = 'Etap produkcji';
																						|tr = 'Üretim aşaması'"), String.LineNumber, ListName);
			Field = PathToTabularSection("LaborCosts", String.LineNumber, "StageName");
			
			CommonClientServer.MessageToUser(
				MessageText,,
				Field,,
				Cancel);
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure CheckSharesOfCostOfOutputProducts(Cancel)
	
	If MethodOfAllocatingFinishedProductCosts <> Enums.MethodsOfCostAllocatingOnProductCosts.ByCostShares Then
		Return;
	EndIf;
	
	ListName = Items.ManufacturedProducts.Title;
	
	Query = New Query(
	"SELECT
	|	Table.Ref AS Ref,
	|	Table.LineNumber AS LineNumber,
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.CostShare AS CostShare
	|INTO TabularSection
	|FROM
	|	&ManufacturedProducts AS Table
	|WHERE
	|	NOT Table.Canceled
	|;
	|////////////////////////////////////////////////////////////////
	|" + ProductionServer.QueryTextCheckSharesOfCostOfOutputProducts(CostAllocationParameters.LinkFields) + "
	|");
	Query.SetParameter("ManufacturedProducts", Object.ManufacturedProducts.Unload());
	
	Result = Query.Execute();
	
	If Not Result.IsEmpty() Then
		
		Selection = Result.Select();
		While Selection.Next() Do
			
			MessageText = CommonClientServer.FillingErrorText("Column", "FillType", NStr("vi = 'Tỷ lệ giá trị';
																						|ru = 'Доля стоимости';
																						|en = 'Cost share'; fa = 'سهم بها';
																						|it = 'Quota del costo';
																						|pl = 'Udział kosztów';
																						|tr = 'Maliyet payı'"), Selection.LineNumber, ListName);
			Field = PathToTabularSection("ManufacturedProducts", Selection.LineNumber, "CostShare");
			
			CommonClientServer.MessageToUser(
				MessageText,,
				Field,,
				Cancel);
			
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Read

&AtServer
Procedure Reread()
	
	Modified = False;
	
	OnReadCreateAtServer();
	
EndProcedure

&AtServer
Procedure ReadData()
	
	DataProcessorObject = DataProcessors.EditProductionStageSequence.Create();
	
	DataProcessorObject.Read(Parameters);
	
	If Parameters.Property("ManufacturedProduct") And Not Parameters.ManufacturedProduct = Undefined Then
		ReadProducts_(DataProcessorObject, Parameters);
	EndIf;
	
	FillingValues = New Structure;
	FillingValues.Insert("ProductionInOneDay", False);
	FillingValues.Insert("ProductionDate", '00010101');
	FillingValues.Insert("ConsumptionInOneDay", False);
	FillingValues.Insert("DateOfMaterialWorkConsumption", '00010101');
	FillingValues.Insert("NotShipInInstallments", False);
	FillingValues.Insert("DateOfShipment", '00010101');
	For Each String In DataProcessorObject.Stages Do
		If String.Status = Enums.StatusesOfProductionStages2_2.BeingGenerated Then
			TheGeneratingStatusIsUsed = True;
			String.Status = Enums.StatusesOfProductionStages2_2.Generated1;
		EndIf;
		FillPropertyValues(String, FillingValues);
	EndDo;
	
	ValueToFormAttribute(DataProcessorObject, "Object");
	
	If Parameters.Property("ManufacturedProduct")
		And Not Parameters.ManufacturedProduct = Undefined Then
		FillInStatusesForSpecifyingSeriesServer("ManufacturedProducts,SupplyWithMaterialsAndWorks");
	EndIf;
	
EndProcedure

&AtServer
Procedure ReadProducts_(DataProcessorObject, FormParameters)
	
	DataSource = FormParameters.ManufacturedProduct;
	
	If (DataProcessorObject.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.Assembly")
			Or DataProcessorObject.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.Repair")
			Or DataProcessorObject.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.WithoutBillsOfMaterials")) Then
		For Each String In DataSource Do
			FillPropertyValues(DataProcessorObject.ManufacturedProducts.Add(), String);
		EndDo;
	ElsIf DataProcessorObject.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.Disassembly") Then
		For Each String In DataSource Do
			FillPropertyValues(DataProcessorObject.SupplyWithMaterialsAndWorks.Add(), String);
		EndDo;
	EndIf;
	
	If Not ValueIsFilled(DataProcessorObject.MainProductProducts)
		And DataSource.Count() > 0 Then
		DataProcessorObject.MainProductProducts = DataSource[0].Products;
		DataProcessorObject.MainProductCharacteristic = DataSource[0].Characteristic;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInMethodOfAllocatingCostsForOutputProducts()
	
	Query = New Query(
	"SELECT
	|	MAX(Table.MethodOfAllocatingFinishedProductCosts) AS MethodOfAllocatingFinishedProductCosts
	|FROM
	|	Document.ProductionStage2_2 AS Table
	|WHERE
	|	Table.ProductionLot = &ProductionLot
	|	AND NOT Table.DeletionMark
	|	AND Table.NextStageNo = 0 //This is the issuing step()
	|
	|HAVING
	|	COUNT(DISTINCT Table.MethodOfAllocatingFinishedProductCosts) = 1
	|");
	Query.SetParameter("ProductionLot", Parameters.ProductionLot);
	
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		MethodOfAllocatingFinishedProductCosts = Enums.MethodsOfCostAllocatingOnProductCosts.ByCostShares;
	Else
		Selection = Result.Select();
		Selection.Next();
		MethodOfAllocatingFinishedProductCosts = Selection.MethodOfAllocatingFinishedProductCosts;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInAssignmentSelectionParameters()
	
	Cached_Values1 = New Structure;
	Cached_Values2 = New Structure;
	For Each Stage In Object.Stages Do
		Stage.ParametersForFillingAssignments = ProductionSupply.ActionParametersFillInPurposeOfProvisionInProductionPhase(
			Stage,
			Object.ManufacturedProducts,
			Cached_Values1);
		ProductionSupply.FillInListOfSelectedAssignmentsInProductionPhase(
			Stage,
			Object.ManufacturedProducts,
			Stage.AppointmentSelectionList,
			Cached_Values2);
	EndDo;
	
EndProcedure

#EndRegion

#Region Record

&AtClient
Procedure WriteData(WriteAndClose = False)
	
	ClearMessages();
	WriteBeforeClosing = WriteAndClose;
	
	Result = CheckAndRecord();
	
	If Result.CheckCompleted Then
		
		If Result.JobCompleted Then
			
			NoErrors_ = CheckReportTaskErrors();
			
			If NoErrors_ Then
				
				If WriteBeforeClosing Then
					Modified = False;
					Close();
				EndIf;
				
				AfterRecordingInBackground();
				NotifyAboutChangesInSequenceOfStages();
				
			EndIf;
			
			Return;
			
		EndIf;
		
		If WriteBeforeClosing Then
			AttachIdleHandler("StartWaitingForBackgroundOperation", 0.1, True);
		Else
			StartWaitingForBackgroundOperation();
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Function CheckAndRecord()
	
	ExecutionResult = New Structure("CheckCompleted,JobCompleted", False, False);
	
	If CheckFilling() Then
		
		If Object.ProductionLot.IsEmpty() Then
			Object.ProductionLot = Catalogs.ProductionLots.GetRef();
		EndIf;
		
		Actions = Actions();
		
		// Setting up accounting accounts.
		GLAccountSettingsServer.RecordFormSInvoiceSettings(ThisObject);
		
		StartupParameters = New Structure("ReferenceOrder,ProductionLot,Actions",
			Object.ReferenceOrder,
			Object.ProductionLot, // initial production batch
			Actions);
		StartupParameters.Insert("BatchFields", BatchFields());
		StartupParameters.Insert("PostWithoutControlOfCompanyStockBalance",
									SessionParameters.PostWithoutControlOfCompanyStockBalance);
		
		ExportProcedureName = "Documents.ProductionStage2_2.EditingProductionStageChain";
		JobDescription = NStr("vi = 'Chỉnh sửa các công đoạn sản xuất';
								|ru = 'Редактирование этапов партии производства';
								|en = 'Edit production lot stages'; fa = 'Edit production lot stages';
								|it = 'Modifica delle fasi di un lotto di produzione';
								|pl = 'Edycja etapów partii produkcji';
								|tr = 'Üretim lotu aşamalarının düzenlenmesi'");
		
		ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
		ExecutionParameters.RunInBackground = True;
		ExecutionParameters.WaitCompletion = 0;
		ExecutionParameters.BackgroundJobDescription = JobDescription;
		
		BackgroundOperationResult = TimeConsumingOperations.ExecuteInBackground(
			ExportProcedureName,
			StartupParameters,
			ExecutionParameters);
		
		JobID = BackgroundOperationResult.JobID;
		StorageAddressBackgroundOperation = BackgroundOperationResult.ResultAddress;
		
		ExecutionResult.JobCompleted = BackgroundOperationResult.Status = "Completed2";
		ExecutionResult.CheckCompleted = True;
		
	EndIf;
	
	Return ExecutionResult;
	
EndFunction

&AtServer
Function Actions()
	
	Data = UploadDataToTransferToDocuments();
	
	// Define the modified stages
	ModifiedStages = New Array;
	
	StageList = Object.Stages.Unload(New Structure("DeletionMark, IsNew", False, False)).UnloadColumn("Ref");
	TableDataBeforeChanges = TemporaryObjectDataTables(StageList);
	
	ListOfTS = ListOfNestedTableParts(True, False);
	ListOfTS.Add("Stages");
	
	For Each	TSName In ListOfTS Do 
		DataBeforeChanges = TableDataBeforeChanges.Tables[TSName].GetData().Unload();
		Result = TMCommonUse.CompareValueTables(Data.TabularSections[TSName], DataBeforeChanges, False);
		If Result.Count()>0 Then
			For Each TSRow In Result Do
				ModifiedStages.Add(TSRow.Ref);
			EndDo;
		EndIf;
	EndDo;
	
	ModifiedStages = CommonClientServer.CollapseArray(ModifiedStages);

	// Let's define the composition of actions with documents
	Actions = New Array;
	For Each String In Object.Stages Do
		
		Ref = String.Ref;
		
		If String.IsNew Then
			Type = "Create";
		ElsIf String.DeletionMark Then
			Type = "Delete";
		ElsIf Not ModifiedStages.Find(Ref) = Undefined Then
			Type = "Change";
		Else
			Continue;
		EndIf;
		
		FillingValues = Undefined;
		If Not Type = "Delete" Then 
			FillingValues = FillingValuesByProductionStage(String, Data);
		EndIf;
		
		NewAction = New Structure("Ref,Type,FillingValues", Ref, Type, FillingValues);
		Actions.Add(NewAction);
		
	EndDo;
	
	Return Actions;
	
EndFunction

&AtServer
Function StageList()
	
	StageList = Object.Stages.Unload(New Structure("DeletionMark", False));
	
	TypeDetails = New TypeDescription("Number", New NumberQualifiers(14, 4, AllowedSign.Nonnegative));
	StageList.Columns.Add("DurationInSeconds", TypeDetails);
	StageList.Columns.Add("DurationBeforeProductionIssue", TypeDetails);
	
	For Each String In StageList Do
		String.DurationInSeconds = ProductionPlanningClientServer.GetTimeInSeconds(String.StageDuration, String.UnitOfMeasureOfStageDuration);
	EndDo;
	
	StageList.Indexes.Add("Ref");
	StageList.Indexes.Add("StageNumber");
	StageList.Indexes.Add("NextStageNo");
	
	Documents.ProductionStage2_2.CalculateShifts(StageList);

	Return StageList;
	
EndFunction

&AtServer
Function UploadDataToTransferToDocuments()
	
	// Attributes
	ListOfCommonBankingDetails = StrConcat(Documents.ProductionStage2_2.GeneralDetailsOfChainOfStages(True), ",");
	Attributes = New Structure(ListOfCommonBankingDetails);
	FillPropertyValues(Attributes, Object);
	
	// Table parts
	TabularSections = New Structure();
	TabularSections.Insert("Stages", StageList());
	ListOfTS = ListOfNestedTableParts();
	For Each TSName In ListOfTS Do
		TabularSection = Object[TSName].Unload();// ValueTable - 
		TabularSection.Indexes.Add("Ref");
		TabularSections.Insert(TSName, TabularSection);
	EndDo;
	
	Result = New Structure("Attributes,TabularSections",Attributes,TabularSections);
	Return Result;
	
EndFunction

&AtServer
Function BatchFields()
	
	MainProduct = New Structure;
	MainProduct.Insert("Products", DataStructureMainProduct.Products);
	MainProduct.Insert("Characteristic", DataStructureMainProduct.Characteristic);
	MainProduct.Insert("UnderRepairProduct", Object.UnderRepairProduct);
	MainProduct.Insert("UnderRepairVariant", Object.UnderRepairVariant);
	MainProduct.Insert("UnderRepairBatch", Object.UnderRepairBatch);
	
	Lot = Documents.ProductionStage2_2.BatchFields(Object, MainProduct, False);
	Return Lot;
	
EndFunction

&AtServer
Function CalculateDetailsValuesBasedOnEditingData(Ref, DataProcessorData)
	
	Filter = New Structure("Ref", Ref);
	FillingValues = New Structure;
	
#Region ProductionInOneDay
	ProductionInOneDay = True;
	ProductionDate = Undefined;
	FoundRows = DataProcessorData.TabularSections["ManufacturedProducts"].FindRows(Filter);
	For Each String In FoundRows Do
		If ProductionDate = Undefined Then
			ProductionDate = String.ProductionDate;
			Continue;
		EndIf;
		If ProductionDate <> String.ProductionDate Then
			ProductionInOneDay = False;
			Break;
		EndIf;
	EndDo;
	If ProductionInOneDay Then
		FoundRows = DataProcessorData.TabularSections["SideAndIntermediateRelease"].FindRows(Filter);
		For Each String In FoundRows Do
			If ProductionDate = Undefined Then
				ProductionDate = String.ProductionDate;
				Continue;
			EndIf;
			If ProductionDate <> String.ProductionDate Then
				ProductionInOneDay = False;
				Break;
			EndIf;
		EndDo;
	EndIf;
	If ProductionInOneDay And ValueIsFilled(ProductionDate) Then
		FillingValues.Insert("ProductionInOneDay", True);
		FillingValues.Insert("ProductionDate", ProductionDate);
	Else
		FillingValues.Insert("ProductionInOneDay", False);
		FillingValues.Insert("ProductionDate", '00010101');
	EndIf;
#EndRegion
	
	#Region NotShipInInstallments
	NotShipInInstallments = True;
	DateOfShipment = Undefined;
	FoundRows = DataProcessorData.TabularSections["SupplyWithMaterialsAndWorks"].FindRows(Filter);
	For Each String In FoundRows Do
		If DateOfShipment = Undefined Then
			DateOfShipment = String.DateOfShipment;
			Continue;
		EndIf;
		If DateOfShipment <> String.DateOfShipment Then
			NotShipInInstallments = False;
			Break;
		EndIf;
	EndDo;
	If NotShipInInstallments And ValueIsFilled(DateOfShipment) Then
		FillingValues.Insert("NotShipInInstallments", True);
		FillingValues.Insert("DateOfShipment", DateOfShipment);
	Else
		FillingValues.Insert("NotShipInInstallments", False);
		FillingValues.Insert("DateOfShipment", '00010101');
	EndIf;
	#EndRegion
	
	#Region ConsumptionInOneDay
	ConsumptionInOneDay = True;
	DateOfMaterialWorkConsumption = Undefined;
	FoundRows = DataProcessorData.TabularSections["MaterialsAndWorksConsumption"].FindRows(Filter);
	For Each String In FoundRows Do
		If DateOfMaterialWorkConsumption = Undefined Then
			DateOfMaterialWorkConsumption = String.DateOfMaterialWorkConsumption;
			Continue;
		EndIf;
		If DateOfMaterialWorkConsumption <> String.DateOfMaterialWorkConsumption Then
			ConsumptionInOneDay = False;
			Break;
		EndIf;
	EndDo;
	If ConsumptionInOneDay Then
		FoundRows = DataProcessorData.TabularSections["UnusedMaterials"].FindRows(Filter);
		For Each String In FoundRows Do
			If DateOfMaterialWorkConsumption = Undefined Then
				DateOfMaterialWorkConsumption = String.DateOfTransaction;
				Continue;
			EndIf;
			If DateOfMaterialWorkConsumption <> String.DateOfTransaction Then
				ConsumptionInOneDay = False;
				Break;
			EndIf;
		EndDo;
	EndIf;
	If ConsumptionInOneDay And ValueIsFilled(DateOfMaterialWorkConsumption) Then
		FillingValues.Insert("ConsumptionInOneDay", True);
		FillingValues.Insert("DateOfMaterialWorkConsumption", DateOfMaterialWorkConsumption);
	Else
		FillingValues.Insert("ConsumptionInOneDay", False);
		FillingValues.Insert("DateOfMaterialWorkConsumption", '00010101');
	EndIf;
	#EndRegion
	
	Return FillingValues;
	
EndFunction

&AtServer
Function FillingValuesByProductionStage(String, DataProcessorData)
	
	ThisIsAProductionIssueStage = ProductionManagementClientServer.ThisIsAProductionIssueStage(String);
	
	Result = New Structure;
	
	// Details of the caps
	ListOfCommonBankingDetails = StrConcat(Documents.ProductionStage2_2.GeneralDetailsOfChainOfStages(True), ",");
	Attributes = New Structure(ListOfCommonBankingDetails);
	
	// - the general Attributes of the batch must be stored in the processing header
	FillPropertyValues(Attributes, DataProcessorData.Attributes);
	
	// - editable Attributes
	Attributes.Insert("StageNumber", String.StageNumber);
	Attributes.Insert("NextStageNo", String.NextStageNo);
	Attributes.Insert("StageName", String.NameEdit);
	If Not String.ReadOnly Then
		Attributes.Insert("Status", String.Status);
		Attributes.Insert("NumberOfPackagesPlan", String.NumberOfPackagesPlan);
		Attributes.Insert("PackagePlan", String.PackagePlan);
		Attributes.Insert("PackageActualData", String.PackageActualData);
		Attributes.Insert("PackageCanceled", String.PackageCanceled);
		Attributes.Insert("ActualStageStart", String.ActualStageStart);
		Attributes.Insert("ActualStageEnd", String.ActualStageEnd);
		Attributes.Insert("Department", String.Department);
		Attributes.Insert("TechnologicalProcess", String.TechnologicalProcess);
		Attributes.Insert("TechnologicalProcessFactor", String.TechnologicalProcessFactor);
	EndIf;
	
	// - Attributes are not edited, they are filled in for the form to work
	Attributes.Insert("PriceKind", String.PriceKind);
	Attributes.Insert("Currency", String.Currency);
	Attributes.Insert("Organization", String.Organization);
	Attributes.Insert("ProductionIssueForActivity", String.ProductionIssueForActivity);
	
	If ThisIsAProductionIssueStage Then
		Attributes.Insert("MethodOfAllocatingFinishedProductCosts", MethodOfAllocatingFinishedProductCosts);
	EndIf;
	
	// - Attributes filled in automatically 
	Attributes.Insert("DurationBeforeProductionIssue",  DataProcessorData.TabularSections.Stages.Find(String.Ref).DurationBeforeProductionIssue);
	FillingValues = CalculateDetailsValuesBasedOnEditingData(String.Ref, DataProcessorData);
	Attributes.Insert("ProductionInOneDay", FillingValues.ProductionInOneDay);
	Attributes.Insert("ProductionDate",       FillingValues.ProductionDate);
	Attributes.Insert("NotShipInInstallments",     FillingValues.NotShipInInstallments);
	Attributes.Insert("DateOfShipment",           FillingValues.DateOfShipment);
	Attributes.Insert("ConsumptionInOneDay",       FillingValues.ConsumptionInOneDay);
	Attributes.Insert("DateOfMaterialWorkConsumption",            FillingValues.DateOfMaterialWorkConsumption);
	Attributes.Insert("Purpose",             String.Purpose);
	Attributes.Insert("WorkPlanning",      String.WorkPlanning);
	
	Result.Insert("HeaderAttributes", Attributes);
	
	// Table parts
	If Not String.ReadOnly Then
		Filter = New Structure("Ref", String.Ref);
		ListOfTS = ListOfNestedTableParts();
		For Each TSName In ListOfTS Do
			TabularSection = DataProcessorData.TabularSections[TSName].Copy(Filter);
			Result.Insert(TSName, TabularSection);
		EndDo;
	EndIf;
	
	// Successors
	Successors = DataProcessorData.TabularSections.Stages.Copy(
		New Structure("StageNumber",String.NextStageNo),
		"Ref").UnloadColumn(0);
	Result.Insert("Successors", Successors);
	
	// Process Parameters
	If Items.StagesGroupRouteMap.Visible
		And String.TechnologicalProcessType <> Enums.TechnologicalProcessTypesOfStage.Individual_ Then
		TechProcessParameters = ProductionProcessEditorServerCall.StandardStageProcessTechnology(String.Ref);
		If String.TechnologicalProcess <> TechProcessParameters.TechnologicalProcess
			Or String.TechnologicalProcessFactor <> TechProcessParameters.TechnologicalProcessFactor Then
			TechProcessParameters.TechnologicalProcessType         = Enums.TechnologicalProcessTypesOfStage.AlternateType;
			TechProcessParameters.TechnologicalProcess              = String.TechnologicalProcess;
			TechProcessParameters.TechnologicalProcessFactor = String.TechnologicalProcessFactor;
		EndIf;
		Result.Insert("TechProcessParameters", TechProcessParameters);
	EndIf;
	
	Return Result;
	
EndFunction

&AtClient
Procedure EndOfBackgroundOfOperationNotification(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		NoErrors_ = CheckReportTaskErrors();
					
		If NoErrors_ Then
			
			If WriteBeforeClosing Then
				Modified = False;
				Close();
			EndIf;
			
			AfterRecordingInBackground();
			NotifyAboutChangesInSequenceOfStages();
			
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure StartWaitingForBackgroundOperation()
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	CallbackOnCompletion = New CallbackDescription("EndOfBackgroundOfOperationNotification", ThisObject);

	TimeConsumingOperationsClient.WaitCompletion(BackgroundOperationResult, CallbackOnCompletion, IdleParameters);
	
EndProcedure

&AtServer
Function CheckReportTaskErrors()
	
	Result = GetFromTempStorage(StorageAddressBackgroundOperation);
	
	If Result = Undefined Then
		Return False;
	EndIf;
	
	If Result.HasErrors Then
		If ValueIsFilled(Result.Messages) Then
			For Each Message In Result.Messages Do
				Message.TargetID = UUID;
				Message.Message();
			EndDo;
		Else
			MessageText = NStr("vi = 'Không thể ghi lại các thay đổi, xem nhật ký sự kiện để biết chi tiết.';
								|ru = 'Не удалось записать изменения, подробную информацию см. в журнале регистрации.';
								|en = 'Cannot save changes. For more information, see the event log.'; fa = 'Cannot save changes. For more information, see the event log.';
								|it = 'Impossibile registrare le modifiche, vedere il registro per i dettagli.';
								|pl = 'Nie udało się zapisać zmiany, szczegółowe informacje można znaleźć w dzienniku rejestracji.';
								|tr = 'Değişiklikler kaydedilemedi, ayrıntılı bilgi için olay günlüğüne bakın.'");
			Common.MessageToUser(MessageText);
		EndIf;
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

&AtServer
Procedure AfterRecordingInBackground()
	
	If ValueIsFilled(Object.ProductionLot) Then
		ProductionBatchBeforeChanging = Object.ProductionLot;
		Parameters.ProductionLot = Object.ProductionLot;
	EndIf;
	
	Reread();
	
EndProcedure

#EndRegion

#Region OnDataChange

&AtClient
Procedure WhenChangingProducts(LineOfATabularSection, TSName)
	
	ObjectStage = ObjectIsCreatedByReference(ThisObject, LineOfATabularSection.Ref);
	StructureOfActions = New Structure;
	
	If TSName = "ManufacturedProducts" Or TSName = "SideAndIntermediateRelease" Then
		LineOfATabularSection.Manufactured = False;
		StructureOfActions.Insert("CheckFillAssignment", PurposeOfTollRelease);
	EndIf;
	If TSName = "SupplyWithMaterialsAndWorks" Then
		StructureOfActions.Insert("CheckFillCommunicationKeySpecifications");
		AddCheckActionFillInSpecification(ThisObject, StructureOfActions, LineOfATabularSection);
		ProvisionInDocumentsClientServer.AddCollateralActions(
			StructureOfActions,
			"AvailableInOtherLines",
			DocumentParametersForSoftwareActions(ThisObject));
		StructureOfActions.Insert(
			"FillInPurposeOfProvisionInProductionPhase",
			ObjectStage.ParametersForFillingAssignments);
	EndIf;
	
	If TSName = "ManufacturedProducts" Or TSName = "SideAndIntermediateRelease" Then
		WarehouseForSeries = LineOfATabularSection.Recipient;
	ElsIf TSName = "UnusedMaterials" Then
		WarehouseForSeries = LineOfATabularSection.Recipient;
	ElsIf TSName = "MaterialsAndWorksConsumption" Then
		WarehouseForSeries = LineOfATabularSection.Department;
	ElsIf TSName = "SupplyWithMaterialsAndWorks" Then
		WarehouseForSeries = LineOfATabularSection.Warehouse;
	EndIf;
	SeriesVerificationParameters = New Structure;
	SeriesVerificationParameters.Insert("Warehouse", WarehouseForSeries);
	SeriesVerificationParameters.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters[TSName]);
	StructureOfActions.Insert("CheckSeriesCalculateStatus", SeriesVerificationParameters);
	
	ProductionManagementClientServer.AddActionsToStructureWhenChangingProducts(
			TSName,
			ThisObject,
			ObjectStage,
			StructureOfActions);
	
	ProductionManagementClientServer.AddQualityControlActionsToStructure(
		TSName,
		StructureOfActions,
		CacheQualityControl);
	
	If TSName = "ManufacturedProducts" Or TSName = "SideAndIntermediateRelease" Then
		AddActionFillProductionDate(LineOfATabularSection, StructureOfActions);
		ProductionClientServer.AddToStructureActionsCheckFillProductionWarehouse(
			LineOfATabularSection.Department, StructureOfActions, "Recipient");
	EndIf;
	
	If TSName = "ManufacturedProducts" Or TSName = "SideAndIntermediateRelease" Or TSName = "UnusedMaterials" Then
		IncomeAndExpensesClientServer.InsertActionClearItemAndExpenseAnalytics(
			StructureOfActions,
			ThisObject,
			"Object." + TSName);
	EndIf;
	
	If TSName = "ManufacturedProducts" Then
		StructureOfActions.Insert("CheckFillInCostShare", CostAllocationParameters);
	EndIf;
	
	If TSName = "SideAndIntermediateRelease" Then
		InternalSubcontractingClientServer.AddActionFillInItemOwnerIsAvailable(ThisObject, StructureOfActions);
		StructureOfActions.Insert("CheckFillIssuePrice", ParametersForFillingIssuePrices(ObjectStage));
		StructureOfActions.Insert("RecalculateAmount");
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(LineOfATabularSection, StructureOfActions, CachedValues);
	
	If TSName = "ManufacturedProducts" Or TSName = "SideAndIntermediateRelease" Then
		
		FillReleaseDirectionSelectionList(LineOfATabularSection, TSName);
		
	ElsIf TSName = "SupplyWithMaterialsAndWorks" Then
		
		ProvisionInDocumentsClientServer.FillInServiceDetails(
				Object.SupplyWithMaterialsAndWorks, 
				DateOfShipmentRequired_, 
				WarehouseIsRequired);
				
		If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions)
				Or RightToReadSubstitutes
					And ShowAnalogues Then
					
					ProvisionOfMaterialsAndWorksInCaseOfChangesInProductRange(Items.SupplyWithMaterialsAndWorks.CurrentRow);
					
		EndIf;
		
		WhenChangingNomenclatureOfCharacteristicInLineIncludedInSet();
		
		FillInSecurityAssignmentEdit(LineOfATabularSection);
		
	ElsIf TSName = "UnusedMaterials" Then
		
		ProductionManagementClient.SavingMaterialsFillInFeatureSeparately(LineOfATabularSection, Object.SupplyWithMaterialsAndWorks);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WhenChangingCharacteristics(LineOfATabularSection, TSName)
	
	ObjectStage = ObjectIsCreatedByReference(ThisObject, LineOfATabularSection.Ref);
	StructureOfActions = New Structure;
	
	If TSName = "ManufacturedProducts" Or TSName = "SideAndIntermediateRelease" Then
		LineOfATabularSection.Manufactured = False;
		StructureOfActions.Insert("CheckFillAssignment", PurposeOfTollRelease);
	EndIf;
	If TSName = "SupplyWithMaterialsAndWorks" Then
		StructureOfActions.Insert("CheckFillCommunicationKeySpecifications");
		AddCheckActionFillInSpecification(ThisObject, StructureOfActions, LineOfATabularSection);
		ProvisionInDocumentsClientServer.AddCollateralActions(
			StructureOfActions,
			"AvailableInOtherLines",
			DocumentParametersForSoftwareActions(ThisObject));
	EndIf;
	
	If TSName = "ManufacturedProducts" Then
		StructureOfActions.Insert("CheckFillInCostShare", CostAllocationParameters);
	EndIf;
	If TSName = "SideAndIntermediateRelease" Then
		StructureOfActions.Insert("CheckFillIssuePrice", ParametersForFillingIssuePrices(ObjectStage));
		StructureOfActions.Insert("RecalculateAmount");
	EndIf;
		
	If TSName = "ManufacturedProducts" Or TSName = "SideAndIntermediateRelease" Then
		AddActionFillProductionDate(LineOfATabularSection, StructureOfActions);
	EndIf;
	
	If TSName = "SupplyWithMaterialsAndWorks" Then
		ProductionClientServer.AddToStructureActionsCheckFillProductionWarehouse(
			LineOfATabularSection.Department, StructureOfActions);
		StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	EndIf;
	
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, TSName));

	BatchProcessingOfTablePartClient.ProcessTSString(LineOfATabularSection, StructureOfActions, CachedValues);
	
	If TSName = "SupplyWithMaterialsAndWorks" Then
		
		If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions)
				Or RightToReadSubstitutes
					And ShowAnalogues Then
					
					ProvisionOfMaterialsAndWorksInCaseOfChangesInCharacteristics(Items.SupplyWithMaterialsAndWorks.CurrentRow);
					
		EndIf;
		
		WhenChangingNomenclatureOfCharacteristicInLineIncludedInSet();
		
	ElsIf TSName = "UnusedMaterials" Then
		
		ProductionManagementClient.SavingMaterialsFillInFeatureSeparately(LineOfATabularSection, Object.SupplyWithMaterialsAndWorks);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WhenChangingNumberOfPackages(LineOfATabularSection, TSName)

	StructureOfActions = New Structure;
	
	AddActionsToStructureWhenChangingPackagesNumber(TSName, ThisForm, StructureOfActions);
	
	If TSName = "SupplyWithMaterialsAndWorks" Then
		ProvisionInDocumentsClientServer.AddCollateralActions(
			StructureOfActions,
			"AvailableInOtherLines",
			DocumentParametersForSoftwareActions(ThisObject));
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(LineOfATabularSection, StructureOfActions, CachedValues);
	
	If TSName = "SupplyWithMaterialsAndWorks" Then
		If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
			UpdateColumnAvailableServer();
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure WhenChangingRecipient(LineOfATabularSection, TSName)
	
	ObjectStage = ObjectIsCreatedByReference(ThisForm, LineOfATabularSection.Ref);
	
	ProductionManagementClient.RecipientOnChange(
		LineOfATabularSection,
		TSName,
		ThisForm,
		ObjectStage,
		CachedValues);
	
EndProcedure

&AtClient
Procedure WhenChangingDirectionOfRelease(LineOfATabularSection, TSName)
	
	ObjectStage = ObjectIsCreatedByReference(ThisForm, LineOfATabularSection.Ref);
	
	ProductionManagementClient.OutputProductsOfStageOfDirectionOfReleaseWhenChanging(
		LineOfATabularSection,
		TSName,
		ThisForm,
		ObjectStage,
		CachedValues);
	
EndProcedure

&AtClient
Procedure FillReleaseDirectionSelectionList(LineOfATabularSection, TSName)
	
	ItemSelectionList = ProductionManagementClient.FillReleaseDirectionSelectionList(
		LineOfATabularSection,
		TSName,
		ThisForm);
	
	If ItemSelectionList.FindByValue(LineOfATabularSection.DirectionOfProductionIssue) = Undefined Then
		LineOfATabularSection.DirectionOfProductionIssue = ItemSelectionList[0].Value;
		WhenChangingDirectionOfRelease(LineOfATabularSection, TSName);
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessBySpecificationWhenModified(TSName, CurrentData)
	
	If Not CurrentData.ProcessByBOM Then
		CurrentData.BillOfMaterials = Undefined;
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	
	FillParameters = ProductDataManagementClientServer.ActionParametersCheckFillSpecification(
		Object,
		CurrentData,
		TSSpecificationSelectionParameters(ThisObject, "ManufacturedProducts", CurrentData),
		New Structure("KeyOfDataPaths", "Object."+TSName));
	
	StructureOfActions.Insert("CheckFillSpecification", FillParameters);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure ItemsCanceledWhenModified(TSName, CurrentData)
	
	If CurrentData.Canceled Then
		CurrentData.Manufactured = False;
	Else
		CurrentData.CancellationReason = PredefinedValue("Catalog.ReasonsForProductionCancellation.EmptyRef");
	EndIf;
	
	StructureOfActions = New Structure;
	
	AddActionFillProductionDate(CurrentData, StructureOfActions);
	AddQualityControlActionsToStructure(TSName, StructureOfActions, CacheQualityControl);
	
	SeriesVerificationParameters = New Structure;
	SeriesVerificationParameters.Insert("Warehouse", CurrentData.Recipient);
	SeriesVerificationParameters.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters[TSName]);
	StructureOfActions.Insert("CheckSeriesCalculateStatus", SeriesVerificationParameters);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingProducts(ObjectStage, TSName, Form, StructureOfActions, AdditionalParameters = Undefined)
	
	If Not StructureOfActions.Property("CheckSeriesCalculateStatus")
		And (TSName = "ManufacturedProducts" Or TSName = "SideAndIntermediateRelease" Or TSName = "UnusedMaterials") Then
		
		SeriesVerificationParameters = New Structure("SeriesSpecificationParameters", Form.SeriesSpecificationParameters[TSName]);
		StructureOfActions.Insert("CheckSeriesCalculateStatus", SeriesVerificationParameters);
		
	EndIf;
	
	If TSName = "ManufacturedProducts" Or TSName = "SideAndIntermediateRelease" Or TSName = "UnusedMaterials" Then
		IncomeAndExpensesClientServer.InsertActionClearItemAndExpenseAnalytics(
			StructureOfActions,
			Form,
			"Object." + TSName);
	EndIf;
	
	
	If TSName = "ManufacturedProducts" Then
		StructureOfActions.Insert("CheckFillInCostShare", Form.CostAllocationParameters);
	EndIf;
	
	If TSName = "SideAndIntermediateRelease" Then
		InternalSubcontractingClientServer.AddActionFillInItemOwnerIsAvailable(Form, StructureOfActions);
		StructureOfActions.Insert("CheckFillIssuePrice", ParametersForFillingIssuePrices(ObjectStage));
		StructureOfActions.Insert("RecalculateAmount");
	EndIf;
	
	If TSName = "SupplyWithMaterialsAndWorks" Then
		StructureOfActions.Insert(
			"FillInPurposeOfProvisionInProductionPhase",
			ObjectStage.ParametersForFillingAssignments);
	EndIf;
	
	ProductionManagementClientServer.AddActionsToStructureWhenChangingProducts(
		TSName,
		Form,
		ObjectStage,
		StructureOfActions,
		AdditionalParameters);
	
	ProductionManagementClientServer.AddQualityControlActionsToStructure(
		TSName,
		StructureOfActions,
		Form.CacheQualityControl);
	
EndProcedure

&AtServer
Procedure AfterChangingTSStringsProgrammaticallyOnServer(TSName, ArrayOfRowIDs_ = Undefined, StructureOfPreviouslyPerformedActions = Undefined)

	RowsArray = Undefined;
	RowsCollection = ObjectTableByName(Object, TSName);
	If ArrayOfRowIDs_ <> Undefined Then
		RowsArray = New Array;
		For Each RowID In ArrayOfRowIDs_ Do
			RowsArray.Add(Object[TSName].FindByID(RowID));
		EndDo; 
		RowsCollection = RowsArray;
	EndIf;
	
	If StructureOfPreviouslyPerformedActions = Undefined Then
		StructureOfPreviouslyPerformedActions = New Structure;
	EndIf;
	
	If TSName = "SupplyWithMaterialsAndWorks" Then
		
		WarehousesClientServer.FillDefaultWarehouse(
				UseSeveralWarehouses,
				DefaultWarehouse,
				RowsCollection);
				
		ProvisionInDocumentsClientServer.FillInServiceDetails(
				Object.SupplyWithMaterialsAndWorks,
				DateOfShipmentRequired_,
				WarehouseIsRequired);
		UpdateColumnAvailableServer();
		
	EndIf;
	
	For Each CurrentData In RowsCollection Do
		
		If CurrentData.Ref.IsEmpty()
			And Not DefaultReference.IsEmpty() Then
			CurrentData.Ref = DefaultReference;
			FillInServiceDetailsForTheseStagesInLine(
					CurrentData,
					TSName,
					ObjectIsCreatedByReference(ThisForm, CurrentData.Ref));
		EndIf;
		
		If TSName = "UnusedMaterials"
			And Not CurrentData.ToExpenseAs Then
			WarehousesClientServer.FillDefaultWarehouse(
					UseSeveralWarehouses, 
					DefaultWarehouse, 
					CurrentData,
					"Recipient");
		EndIf;
		
	EndDo;
	
	FillInServiceDetailsOfTableParts(TSName, RowsArray);
	
	If (TSName = "SupplyWithMaterialsAndWorks"
			Or TSName = "ManufacturedProducts"
			Or TSName = "SideAndIntermediateRelease"
			Or TSName = "MaterialsAndWorksConsumption"
			Or TSName = "UnusedMaterials")
		And Not StructureOfPreviouslyPerformedActions.Property("CheckSeriesCalculateStatus") Then
		FillInStatusesForSpecifyingSeriesServer(TSName);
	EndIf; 
	
	If (TSName = "ManufacturedProducts"
			Or TSName = "SideAndIntermediateRelease"
			Or TSName = "UnusedMaterials"
			Or TSName = "SupplyWithMaterialsAndWorks")
		And Not StructureOfPreviouslyPerformedActions.Property("RecalculateNumberOfUnits") Then
			
		ValuesInCache = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();	 
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
		
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			RowsCollection,
			StructureOfActions,
			ObjectTableByName(Object, TSName),
			ValuesInCache);
			
	EndIf;	
	
	If TSName = "ManufacturedProducts" Then
		FillInAssignmentSelectionParameters();
	EndIf;
	
	ConfigureDependentFormElements(ThisForm, TSName);
	
EndProcedure

&AtServer
Function StageStatuses()
	
	StageStatuses = New Map;
	
	For Each String In Object.Stages Do
		If String.DeletionMark Then
			Continue;
		EndIf;
		StageStatuses.Insert(String.Ref, String.Status);
	EndDo;
	
	Return StageStatuses;
	
EndFunction

&AtServer
Procedure ProcessStatusChangeOnServer(InitialStatuses)
	
	StatusStarted    = Enums.StatusesOfProductionStages2_2.Initiated;
	StatusCompleted_1 = Enums.StatusesOfProductionStages2_2.Completed;
	
	ProductTableNames = ProductionManagementClientServer.ProductTableNames();
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("Manufactured", False);
	FilterStructure1.Insert("Ref");
	
	For Each ObjectStage In Object.Stages Do
		
		If InitialStatuses[ObjectStage.Ref] = Undefined
			Or InitialStatuses[ObjectStage.Ref] = ObjectStage.Status Then
			Continue;
		EndIf;
		
		ObjectStage.StageExecutionIsStarted    = (ObjectStage.Status = StatusStarted Or ObjectStage.Status = StatusCompleted_1);
		ObjectStage.StageIsCompleted = (ObjectStage.Status = StatusCompleted_1);
		
		ProductionManagement.SetDateByMark(
					ObjectStage.StageExecutionIsStarted,
					ObjectStage.ActualStageStart);
		
		ProductionManagement.SetDateByMark(
					ObjectStage.StageIsCompleted,
					ObjectStage.ActualStageEnd,
					,
					ObjectStage.StageIsCompleted);
		
		If ObjectStage.Status = StatusStarted Then
			
			FillingData = ProductionManagement.FillInDataWhenStatusChanges(ObjectStage);
			PlannedDateOfReceipt = FillingData.PlannedDateOfReceipt;
			
			If ObjectStage.ProductionInOneDay Then
			
				ProductionManagement.SetDateByMark(
					True, 
					ObjectStage.ProductionDate,
					PlannedDateOfReceipt);
				
			EndIf;
			
			FilterStructure1.Ref = ObjectStage.Ref;
			
			For Each TableName In ProductTableNames Do
				
				For Each String In Object[TableName].FindRows(FilterStructure1) Do
					
					ProductionManagement.SetDateByMark(
						True, 
						String.ProductionDate,
						PlannedDateOfReceipt);
					
				EndDo;
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
	AfterChangingStatusOnServer();
	
EndProcedure

&AtClient
Procedure CheckHandleChangeOfProgressMark(ObjectStage, MarkOfCompletion)
	
	If ValueIsFilled(ObjectStage.Ref) Then
		If MarkOfCompletion Then
			If Not ObjectStage.StageExecutionIsStarted Then
				ObjectStage.StageExecutionIsStarted = True;
				ProcessStartOfStageExecution(ObjectStage.Ref);
			EndIf;
		Else
			If ObjectStage.StageIsCompleted Then
				ObjectStage.StageIsCompleted = False;
				ProcessStageCompletion(ObjectStage.Ref);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure CheckProcessChangeOfExecutionMarkOnServer(ObjectStage, MarkOfCompletion)
	
	If ValueIsFilled(ObjectStage.Ref) Then
		If MarkOfCompletion Then
			If Not ObjectStage.StageExecutionIsStarted Then
				ObjectStage.StageExecutionIsStarted = True;
				ProcessStartOfStageExecution(ObjectStage.Ref);
			EndIf;
		Else
			If ObjectStage.StageIsCompleted Then
				ObjectStage.StageIsCompleted = False;
				ProcessStageCompletion(ObjectStage.Ref);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessStartOfStageExecution(Ref)
	
	ObjectStage = ObjectIsCreatedByReference(ThisForm, Ref);
	
	ProductionManagement.SetDateByMark(
				ObjectStage.StageExecutionIsStarted,
				ObjectStage.ActualStageStart);
	
	// there are no other actions provided for in this processing
	
	HandleChangeOfProgressMark(ObjectStage);
	
EndProcedure

&AtServer
Procedure ProcessStageCompletion(Ref)
	
	ObjectStage = ObjectIsCreatedByReference(ThisForm, Ref);
	
	ProductionManagement.SetDateByMark(
				ObjectStage.StageIsCompleted, 
				ObjectStage.ActualStageEnd,
				,
				True);
	
	// there are no other actions provided for in this processing
	
	HandleChangeOfProgressMark(ObjectStage);
	
EndProcedure

&AtServer
Procedure HandleChangeOfProgressMark(ObjectStage)
	
	ObjectStage.Status = StatusStarted();
	
	// there are no other actions provided for in this processing
	
	AfterChangingStatusOnServer();
	
EndProcedure

&AtServer
Procedure AfterChangingStatusOnServer()

	SeriesSpecificationParameters = New FixedStructure(
			ProductsServer.SeriesSpecificationParameters(Object, DataProcessors.EditProductionStageSequence));
	
	SetVisibilityOfSeriesElements();
	
	FillInServiceDetails();
	
	ConfigureDependentFormElements(ThisForm);
	
EndProcedure

&AtServer
Procedure WhenChangingMethodOfDistributionOfCostsForOutputProducts()
	
	For Each String In Object.Stages Do
		String.MethodOfAllocatingFinishedProductCosts = MethodOfAllocatingFinishedProductCosts;
	EndDo;
	
	CostAllocationParametersStructure = DataProcessors.EditProductionStageSequence.CostAllocationParameters(MethodOfAllocatingFinishedProductCosts);
	CostAllocationParameters = New FixedStructure(CostAllocationParametersStructure);
	
	ProductionServer.CalculateFractionOfCost(Object, CostAllocationParameters);
	CalculatePercentageOfCostAllocationForOutputProducts();
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInSecurityAssignmentEdit(String, Presentations = Undefined)
	
	If String.SupplyAssignment.IsEmpty() Then
		String.SupplyAssignmentEditing = "";
	ElsIf String.SupplyAssignment = String.ValueRef Then
		String.SupplyAssignmentEditing = String.StageName;
	ElsIf Presentations <> Undefined Then
		String.SupplyAssignmentEditing = Presentations[String.SupplyAssignment];
	Else
		String.SupplyAssignmentEditing = String.SupplyAssignment;
	EndIf;
	
EndProcedure

&AtServer
Procedure FinishedProductToBeRepairedItemOnChangeATServer(CachedValues)
	
	CheckResult = Catalogs.Products.CharacteristicAndPackagingBelongToOwner(
		Object.UnderRepairProduct, Object.UnderRepairVariant, Undefined);
	
	Object.UnderRepairVariant = CheckResult.Characteristic;
	FinishedProductBeingRepairedCharacteristicsAreUsed = CheckResult.ItemVariantsAreUsed;
	
	If SeriesSpecificationParameters.FinishedProductBeingRepaired.UseItemsBatch Then
		FillInBatchIndicationStatusesONChangesOfFinishedProductBeingRepaired(CachedValues);
	EndIf;
	
	ConfigureDependentFormElements(ThisObject, "UnderRepairProduct");
	
EndProcedure

#EndRegion

#Region ManufacturedProducts

&AtClient
Procedure AddActionFillProductionDate(CurrentData, StructureOfActions)
	
	ObjectStage = ObjectIsCreatedByReference(ThisForm, CurrentData.Ref);
	
	If ObjectStage.Status = StatusStarted() Or ObjectStage.Status = StatusCompleted_1() Or ObjectStage.DynamicStructure Then
		ActionParameters = ProductionManagementClientServer.ActionParametersFillProductionDate(
									ObjectStage.ActualProductionDate,
									ObjectStage.PlannedProductionDate);
	Else
		ActionParameters = ProductionManagementClientServer.ActionParametersFillProductionDate();
	EndIf;
	
	StructureOfActions.Insert("FillInProductionDate", ActionParameters);
	
EndProcedure

&AtClient
Procedure FillInProductionDateInLine(CurrentRow)
	
	StructureOfActions = New Structure;
	
	AddActionFillProductionDate(CurrentRow, StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure Products_ChangeQualityCancelLineCompletion(ValueSelected, AdditionalParameters) Export
	
	TSName = AdditionalParameters.TSName;
	OldRow = Items[TSName].CurrentData;
	ObjectTable = Object[TSName];// FormDataCollection - 
	
	NewRow = ObjectTable.Insert(ObjectTable.IndexOf(OldRow) + 1);
	FillPropertyValues(NewRow, OldRow,, "RowCode,KeyProducts");
	
	FillPropertyValues(OldRow, ProcessingOfTabularFormsClientServer.LineCache(Items[TSName], ThisObject));
	OldRow.Canceled = True;
	ItemsCanceledWhenModified(TSName, OldRow);
	
	AfterChangingQualityAndCancelingRow(
		TSName, NewRow.GetID(), OldRow.GetID());
	
	Items[TSName].CurrentRow  = NewRow.GetID();
	
EndProcedure

&AtClient
Procedure FillInRecipientCompletion(ValueSelected, AdditionalParameters) Export
	
	If Not ValueIsFilled(ValueSelected) Then
		Return;
	EndIf;	
	
	TSParameters      = AdditionalParameters.TSParameters;
	SelectedRows = Items[TSParameters.NameTSForm].SelectedRows;
	
	FillInRecipientOnServer(TSParameters, SelectedRows, ValueSelected);
	
EndProcedure

&AtServer
Procedure FillInRecipientOnServer(TSParameters, SelectedRows, Recipient)
	
	NameTsObject = TSParameters.NameTsObject;
	NameTSForm  = TSParameters.NameTSForm;
	
	ValuesInCache = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActions = New Structure;
	
	SeriesSpecificationParameters = ThisForm[ThisForm.StageEditingParameters.PropsNameParametersForSpecifyingSeries];
	
	SeriesVerificationParameters = New Structure;
	SeriesVerificationParameters.Insert("Warehouse"                    , Recipient);
	SeriesVerificationParameters.Insert("SeriesSpecificationParameters"   , SeriesSpecificationParameters[NameTSForm]);

	RowsToProcess = New Array();
	
	For Each RowID In SelectedRows Do
		
		RowData = Object[NameTsObject].FindByID(RowID);
		RowData.Recipient = Recipient;
		RowsToProcess.Add(RowData);
		
	EndDo;
	
	StructureOfActions.Insert("CheckSeriesCalculateStatus", SeriesVerificationParameters);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object[NameTsObject],
		ValuesInCache);
	
	AfterChangingTSStringsProgrammaticallyOnServer(NameTSForm, SelectedRows, StructureOfActions);
	
EndProcedure

&AtClient
Procedure ChangeQualityCompletion(CurrentRow, AdditionalParameters) Export

	StructureOfActions = New Structure;
	
	ProductionClientServer.AddToStructureActionsCheckFillProductionWarehouse(
		CurrentRow.Department, StructureOfActions, "Recipient");		
	
	StructureOfActions.Insert("FillInShopPantryAttribute");
	StructureOfActions.Insert(
		"RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	
	ValuesInCache = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
		
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, ValuesInCache);
	
EndProcedure	

&AtServer
Procedure AfterChangingQualityAndCancelingRow(TSName, NewlineIds, IdsOfOldLine)
	
	TableRow = Object[TSName].FindByID(NewlineIds);
	
	StructureOfActions = New Structure;
	
	ProductionClientServer.AddToStructureActionsCheckFillProductionWarehouse(
		TableRow.Department, StructureOfActions, "Recipient");	
		
	ValuesInCache = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
		
	BatchProcessingOfTablePartServer.ProcessTSString(TableRow, StructureOfActions, ValuesInCache);
	
	RowsArray = New Array;
	RowsArray.Add(NewlineIds);
	RowsArray.Add(IdsOfOldLine);
	
	AfterChangingTSStringsProgrammaticallyOnServer(TSName, RowsArray);	
	
EndProcedure		

#EndRegion

#Region Supply

&AtClient
Procedure ProvisionOfMaterialsAndWorksOptionOfProvidingForChangesOnClient(Result, AdditionalParameters) Export
	
	ProvisionOfMaterialsAndWorksSoftwareOptionWhenChangedOnServer();
	
EndProcedure

&AtServer
Function SoftwareSelectionParameters(Mode)
	
	FormParameters = ProvisionInDocumentsServer.SoftwareSelectionParameters(
		ThisObject,
		Items.SupplyWithMaterialsAndWorks.CurrentRow,
		Mode);
	
	Return FormParameters;
	
EndFunction

&AtServer
Function ProvidingSetAction(ActionCode)
	
	Result = ProvisionInDocumentsServer.ProvidingSetActionResultStructure();
	
	If ActionCode = "FLAG_UNITED" Or ActionCode = "FLAG_NOTABLE" Then
		
		// Restriction of the choice of actions for semi-finished products produced.
		IDs = New Array();
		For Each Id In Items.SupplyWithMaterialsAndWorks.SelectedRows Do
			LineProducts_ = Object.SupplyWithMaterialsAndWorks.FindByID(Id);
			If ActionCode = "FLAG_NOTABLE" And LineProducts_.Produced Then
				Continue;
			EndIf;
			IDs.Add(Id);
		EndDo;
		
		Changes = ProvisionInDocumentsServer.SetActionApart(
			ActionCode,
			ThisObject,
			IDs);
			
		ModifiedRows = New Array();
		For Each Update In Changes.ChangesTable Do
			ModifiedRows.Add(Update.String);
		EndDo;
		
		CollectionOnForm = ProvisionInDocumentsClientServer.CollectionOnForm(
			ThisObject, AvailableRemainingEmbeddingOptions);
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInAssignmentInProductionPhase");
		CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
		
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			ModifiedRows,
			StructureOfActions,
			CollectionOnForm,
			CachedValues);
		
		UpdateColumnAvailableServer();
		
	Else
		
		InitialStatuses = StageStatuses();
		
		Changes = ProvisionInDocumentsServer.SetAction(
			ActionCode,
			ThisObject,
			Items.SupplyWithMaterialsAndWorks.SelectedRows);
		
		FillPropertyValues(Result, Changes);
		
		If Changes.ChangesTable <> Undefined Then
			AfterFillingOutCollateral(
				Changes.ChangesTable,
				ProvisionInDocumentsClientServer.ActionSelectionMode(),
				Result);
			ProcessStatusChangeOnServer(InitialStatuses);
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Function ProcessWarehouseAndBatchSelectionOnServer(ValueSelected, FormParameters)

	Modified = True;
	InitialStatuses = StageStatuses();
	
	Changes = ProvisionInDocumentsServer.WhenChoosingWarehouse(
		ValueSelected,
		ThisObject,
		Items.SupplyWithMaterialsAndWorks.CurrentRow,
		FormParameters.FieldsToFillIn);
		
	AfterFillingOutCollateral(Changes, FormParameters.Mode);
	ProcessStatusChangeOnServer(InitialStatuses);
	
	TextProcessedLines = ProvisionInDocumentsServer.TextProcessedLines(Changes.Count());
	Return TextProcessedLines;
	
EndFunction

&AtServer
Procedure ProcessChangeOfProductionStageInLines(SelectedRows, TSName, StageLink)
	
	CachedValues = Undefined;
	TabularSection       = Object[TSName];
	ObjectStage           = ObjectIsCreatedByReference(ThisForm, StageLink);
	
	If TSName = "SupplyWithMaterialsAndWorks" Then
		CheckSelectStageInSetLines(StageLink, SelectedRows);
	EndIf;
	
	For Each RowID In SelectedRows Do
		CurrentData = TabularSection.FindByID(RowID);
		ProcessProductionStageChangeInLine(CurrentData, TSName, ObjectStage, CachedValues);
	EndDo;
	
	If TSName = "SupplyWithMaterialsAndWorks" Then
		UpdateColumnAvailableServer();
		If RightToReadSubstitutes And ShowAnalogues Then
			NotePresenceOfAnalogues();
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Function ProcessProductionStageChangeInLine(String, TSName, ObjectStage, CachedValues)
	
	StructureOfActions = New Structure();
	
	FillInServiceDetailsForTheseStagesInLine(
		String,
		TSName,
		ObjectStage);
	
	If TSName = "ManufacturedProducts" Or TSName = "SideAndIntermediateRelease" Then
		String.Manufactured = False;
		String.ProductionDate = '00010101';
	EndIf;
	
	If TSName = "LaborCosts" Then
		String.Completed2 = False;
		String.ExecutionDate = '00010101';
	EndIf;
	
	If StrFind("ManufacturedProducts,SideAndIntermediateRelease,UnusedMaterials,MaterialsAndWorksConsumption,SupplyWithMaterialsAndWorks", TSName) > 0 Then
		If TSName = "ManufacturedProducts" Or TSName = "SideAndIntermediateRelease" Then
			WarehouseForSeries = String.Recipient;
		ElsIf TSName = "UnusedMaterials" Then
			WarehouseForSeries = String.Recipient;
		ElsIf TSName = "MaterialsAndWorksConsumption" Then
			WarehouseForSeries = String.Department;
		ElsIf TSName = "SupplyWithMaterialsAndWorks" Then
			WarehouseForSeries = String.Warehouse;
		EndIf;
		SeriesVerificationParameters = New Structure;
		SeriesVerificationParameters.Insert("Warehouse", WarehouseForSeries);
		SeriesVerificationParameters.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters[TSName]);
		StructureOfActions.Insert("CheckSeriesCalculateStatus", SeriesVerificationParameters);
	EndIf;
	
	If TSName = "SupplyWithMaterialsAndWorks" Then
		
		MethodParameters = New Structure();
		MethodParameters.Insert("ProductionOrder",    ObjectStage.ReferenceOrder);
		MethodParameters.Insert("Department",          ObjectStage.Department);
		MethodParameters.Insert("Ref",                 ObjectStage.Ref);
		MethodParameters.Insert("Status",                 ObjectStage.Status);
		MethodParameters.Insert("SubcontractOrder",     ObjectStage.SubcontractOrder);
		MethodParameters.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters[TSName]);
		MethodParameters.Insert("Form",                  ThisObject);
		
		ProductionManagementClientServer.AddToStructureActionsCheckSoftwareInProductionPhase(
			StructureOfActions,
			MethodParameters);
		
		StructureOfActions.Insert(
			"FillInPurposeOfProvisionInProductionPhase",
			ObjectStage.ParametersForFillingAssignments);
			
	EndIf;
	
	BatchProcessingOfTablePartServer.ProcessTSString(String, StructureOfActions, CachedValues);
	
	If TSName = "SupplyWithMaterialsAndWorks" Then
		FillInSecurityAssignmentEdit(String);
	EndIf;
	
	Return StructureOfActions;
	
EndFunction

&AtClient
Procedure ClearProductionStageInLine(TSName)
	
	CurrentData = Items[TSName].CurrentData;
	StageLink = PredefinedValue("Document.ProductionStage2_2.EmptyRef");
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	SelectedRows = CommonClientServer.ValueInArray(Items[TSName].CurrentRow);
	
	ProcessChangeOfProductionStageInLines(SelectedRows, TSName, StageLink);
	
EndProcedure

&AtClientAtServerNoContext
Function DocumentParametersForSoftwareActions(Form)
	
	DocumentParameters = New Structure();
	DocumentParameters.Insert("Form",                              Form);
	DocumentParameters.Insert("Collection",                          Form.Object.SupplyWithMaterialsAndWorks);
	DocumentParameters.Insert("SecurityOptionAndFlagSeparately", Undefined);
	
	Return DocumentParameters;
	
EndFunction

&AtServer
Procedure ProvisionOfMaterialsAndWorksSoftwareOptionWhenChangedOnServer()
	
	InitialStatuses = StageStatuses();
	
	Changes = ProvisionInDocumentsServer.SupplyOptionOnChange(
		ThisObject,
		Items.SupplyWithMaterialsAndWorks.CurrentRow);
		
	Mode = ProvisionInDocumentsClientServer.ModeSelectActionDirectly();
	AfterFillingOutCollateral(Changes, Mode, Undefined);
	ProcessStatusChangeOnServer(InitialStatuses);
	
EndProcedure

&AtClient
Procedure ProvidingMaterialsAndWorksSelectionIsAvailable(CurrentData)
	
	FormParameters = ParametersOfQuantityAndSeriesRequestForm(Undefined);
	
	If FormParameters <> Undefined Then
		OpenForm("DataProcessor.QuantityAndBatchRequest.Form", FormParameters, ThisObject);
	EndIf;
	
EndProcedure

&AtServer
Procedure SupplyWithMaterialsAndWorksAfterDeleteRowServer()
	
	If RightToReadSubstitutes And ShowAnalogues Then
		NotePresenceOfAnalogues();
	EndIf;
	UpdateColumnAvailableServer();
	
EndProcedure

&AtServer
Procedure ProvisionOfMaterialsAndWorksInCaseOfChangesInProductRange(CurrentRow)
	
	LineOfATabularSection = Object.SupplyWithMaterialsAndWorks.FindByID(CurrentRow);
	UpdateColumnAvailableServer();
	
	If RightToReadSubstitutes And ShowAnalogues Then
		NotePresenceOfAnalogues();
	EndIf;
	
EndProcedure

&AtServer
Procedure ProvisionOfMaterialsAndWorksInCaseOfChangesInCharacteristics(CurrentRow)
	
	LineOfATabularSection = Object.SupplyWithMaterialsAndWorks.FindByID(CurrentRow);
	UpdateColumnAvailableServer();
	
	If RightToReadSubstitutes And ShowAnalogues Then
		NotePresenceOfAnalogues();
	EndIf;
	
EndProcedure

&AtServer
Procedure EnsuringToSetActionAfterQuestion(Response, Result)
	
	InitialStatuses = StageStatuses();
	
	ResultStructure1 = ProvisionInDocumentsServer.SetActionAfterQuestion(Response, Result, ThisObject);
	AfterFillingOutCollateral(
		ResultStructure1.ChangesTable,
		ProvisionInDocumentsClientServer.ActionSelectionMode(),
		ResultStructure1);
		
	ProcessStatusChangeOnServer(InitialStatuses);
	
EndProcedure

&AtClient
Procedure ProvidingSetActionWithQuestion(ActionCode)
	
	Result = ProvidingSetAction(ActionCode);
	
	QuestionAsked = ProvisionInDocumentsClient.ShowIssueOfFillingSoftwareWithWholePackages(
		ThisObject,
		Object.SupplyWithMaterialsAndWorks,
		Result,
		"AfterQuestionOfFillingPackageWithWholePackages");
	
	If Not QuestionAsked Then
		
		ProvisionInDocumentsClient.ShowQuestionUncheckShipByOneDate(
			ThisObject,
			Object.SupplyWithMaterialsAndWorks,
			Result,
			"AfterQuestionRemoveFlagShipByOneDate");
			
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateColumnAvailableServer()
	
	ProvisionInDocumentsServer.UpdateColumnAvailable(ThisObject);
	
EndProcedure

&AtClient
Procedure ProcessWarehouseAndBatchSelection(ValueSelected, FormParameters) Export
	
	If Not ProvisionInDocumentsClient.ThereAreSelectedProducts(ValueSelected) Then
		Return;
	EndIf;
	
	// no additional actions are required (single date shipment is not available)
	
	Notification = ProcessWarehouseAndBatchSelectionOnServer(ValueSelected, FormParameters);
	NotificationText1 = ProvisionInDocumentsClient.TextProcessingAlertsWarehouseAndBatchSelection(FormParameters.Mode);
	ShowUserNotification(NotificationText1, , Notification);
	
EndProcedure

&AtClient
Procedure AfterQuestionOfFillingPackageWithWholePackages(Response, Result) Export
	
	QuestionAsked = ProvisionInDocumentsClient.ShowQuestionUncheckShipOneDateAfterQuestion(
		ThisObject,
		Object.SupplyWithMaterialsAndWorks,
		Result,
		Response,
		"AfterQuestionRemoveFlagShipByOneDate");
		
	If Not QuestionAsked Then
		
		EnsuringToSetActionAfterQuestion(Response, Result);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterQuestionRemoveFlagShipByOneDate(Response, Result) Export
	
	EnsuringToSetActionAfterQuestion(Response, Result);
	
EndProcedure

&AtServer
Procedure AfterFillingOutCollateral(Changes, Mode = Undefined, FillParameters = Undefined)
	
	ProvisionInDocumentsServer.UpdateShipmentDate(
		FillParameters,
		Object.NotShipInInstallments,
		Object.DateOfShipment,
		Object.SupplyWithMaterialsAndWorks,
		"DateOfShipment");
	
	ReadyForProcessing_ = Changes.UnloadColumn("String");
	
	If ProvisionInDocumentsClientServer.YouNeedToCheckFillInShipmentDateForShipLines(Mode) Then
		
		ProvisionInDocumentsServer.CheckFillInShipmentDateForShipLines(
			ReadyForProcessing_,
			"DateOfShipment",
			Object.NotShipInInstallments,
			Object.DateOfShipment);
			
	EndIf;
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("RecalculateNumberOfUnits",
		ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	ProvisionInDocumentsClientServer.AddCollateralActions(
		StructureOfActions,
		"WarehouseIsRequired,DateOfShipmentRequired_",
		DocumentParametersForSoftwareActions(ThisObject));
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ReadyForProcessing_,
		StructureOfActions,
		Object.SupplyWithMaterialsAndWorks,
		CachedValues);
	
	FoundStages = New Map;
	ThisIsSoftwareChange = Changes.Columns.Find("SupplyOption") <> Undefined;
	For Each Update In Changes Do
		
		Software_1 = Object.SupplyWithMaterialsAndWorks.FindByID(Update.Id);
		If Not ValueIsFilled(Software_1.Ref) Then
			Continue;
		EndIf;
		
		ObjectStage = FoundStages.Get(Software_1.Ref);
		If ObjectStage = Undefined Then
			ObjectStage = ObjectIsCreatedByReference(ThisForm, Software_1.Ref);
			FoundStages.Insert(Software_1.Ref, ObjectStage);
		EndIf;
		
		// Taking into account the limitations of specifying security options in the stage - if there is a ship, then the status of the document changes.
		If ThisIsSoftwareChange
			And Update.SupplyOption = PredefinedValue("Enum.SupplyOptions.Ship")
			And (ObjectStage.Status = PredefinedValue("Enum.StatusesOfProductionStages2_2.BeingGenerated")
				Or ObjectStage.Status = PredefinedValue("Enum.StatusesOfProductionStages2_2.Generated1")
				Or ObjectStage.Status = PredefinedValue("Enum.StatusesOfProductionStages2_2.ForCompletion")) Then
			
			ObjectStage.Status = PredefinedValue("Enum.StatusesOfProductionStages2_2.Initiated");
			
		EndIf;
		
	EndDo;
	
	FillInStatusesForSpecifyingSeriesServer("SupplyWithMaterialsAndWorks");
	
	UpdateColumnAvailableServer();
	
EndProcedure

&AtClient
Procedure FillInListOfSelectedSecurityAppointments()
	
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	
	Items.SupplyWithMaterialsAndWorksSupplyAssignmentEditing.ChoiceList.Clear();
	RefsFilterInSelectionOfAssignmentsForm.Clear();
	
	ObjectStage = ObjectIsCreatedByReference(ThisForm, CurrentData.Ref);
	For Each ListItem In ObjectStage.AppointmentSelectionList Do
		If ListItem.Value = CurrentData.ValueRef Then
			Items.SupplyWithMaterialsAndWorksSupplyAssignmentEditing.ChoiceList.Add(
				Undefined, CurrentData.StageName);
		Else
			Items.SupplyWithMaterialsAndWorksSupplyAssignmentEditing.ChoiceList.Add(
				ListItem.Value);
		EndIf;
		RefsFilterInSelectionOfAssignmentsForm.Add(ListItem.Value);
	EndDo;
	
EndProcedure

&AtClient
Procedure SetSelectionByTypeOfSupplyItem()
	
	If Not Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.PerformRM") Then
		Return;
	EndIf;
	
	AvailableProductTypes = AvailableProductTypes(
		ThisObject,
		"SupplyWithMaterialsAndWorks",
		Items.SupplyWithMaterialsAndWorks.CurrentData);
	
	ProductDataManagementClientServer.SetSelectionByItemType(
		Items.SupplyWithMaterialsAndWorksProducts,
		AvailableProductTypes);
	
EndProcedure

&AtClient
Procedure UpdateSupplyBillofMaterialsItemSelectionParameters()
	
	If Not Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.PerformRM") Then
		Return;
	EndIf;
	
	TSSpecificationSelectionParameters = TSSpecificationSelectionParameters(
		ThisObject, "SupplyWithMaterialsAndWorks", Items.SupplyWithMaterialsAndWorks.CurrentData);
	Items.SupplyWithMaterialsAndWorksBillOfMaterials.ChoiceParameters =
		New FixedArray(ProductDataManagementClientServer.BillOfMaterialsItemSelectionParameters(TSSpecificationSelectionParameters));
	
EndProcedure

&AtClient
Procedure ProcessActivationOfSupplyLine()
	
	ConfigureDependentFormElements(ThisObject, "ShowDependentCommands");
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddCheckActionFillInSpecification(Form, StructureOfActions, LineOfATabularSection)
	
	If Not LineOfATabularSection.Produced Then
		Return;
	EndIf;
	
	FillParameters = ProductDataManagementClientServer.ActionParametersCheckFillSpecification(
		Form.Object,
		LineOfATabularSection,
		TSSpecificationSelectionParameters(Form, "SupplyWithMaterialsAndWorks", LineOfATabularSection));
	StructureOfActions.Insert("CheckFillSpecification", FillParameters);
	
EndProcedure

#EndRegion

#Region MaterialsAndWorksConsumption

// Fills in the expense of materials and works according to the security data
//
// Parameters:
//  Mode - See Documents.ProductionStage2_2.FillInConsumptionOfMaterialsAndWorksAccordingToProvisionData.Mode
//
&AtServer
Procedure FillInConsumptionOfMaterialsAndWorkOnProvisionDataOnServer(Mode = 0)
	
	ReferencesArrray = New Array;
	For Each String In Object.Stages Do
		If String.ProductionByThirdParty Or String.ReadOnly Then
			Continue;
		EndIf;
		ReferencesArrray.Add(String.Ref);
	EndDo;
	
	DataProcessors.EditProductionStageSequence.FillInConsumptionOfMaterialsAndWorksAccordingToProvisionData(Object, ReferencesArrray, Mode);
	AfterChangingTSStringsProgrammaticallyOnServer("MaterialsAndWorksConsumption");
	
EndProcedure

#EndRegion

#Region Savings

&AtClient
Procedure SavingMaterialsActionWhenChanging(LineOfATabularSection)
	
	ObjectStage = ObjectIsCreatedByReference(ThisForm, LineOfATabularSection.Ref);
	
	ProductionManagementClient.SavingMaterialsOfStageActionWhenChanging(
		LineOfATabularSection,
		ThisForm,
		ObjectStage,
		CachedValues);
	
EndProcedure

&AtServer
Procedure FillWithUnspentMaterialsOnServer()
	
	ReferencesArrray = New Array;
	For Each String In Object.Stages Do
		If String.ProductionByThirdParty Or String.ReadOnly Then
			Continue;
		EndIf;
		ReferencesArrray.Add(String.Ref);
	EndDo;
	DataProcessors.EditProductionStageSequence.FillInUnspentMaterials(Object, ReferencesArrray);
	AfterChangingTSStringsProgrammaticallyOnServer("UnusedMaterials");
	
EndProcedure

#EndRegion

#Region LaborCosts

&AtServerNoContext
Procedure PerformerGettingSelectionData(ChoiceData, Text, Department, Organization, Date)
	
	ChoiceData = New ValueList;
	
	ChoiceParameters = New Structure;
	ChoiceParameters.Insert("Department", Department);
	ChoiceParameters.Insert("Organization", Organization);
	ChoiceParameters.Insert("Date", Date);
	
	ProductionServer.FillInSelectionDataWhenEnteringArtist(ChoiceData, Text, ChoiceParameters);
	
EndProcedure

&AtClient
Procedure PerformerStartChoiceCompletion(Result, AdditionalParameters) Export
	
	CurrentData = Items.LaborCosts.CurrentData;
	If CurrentData <> Undefined And ValueIsFilled(Result) Then
		
		CurrentData.Performer = Result;
		Modified = True;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Standards

&AtServer
Function GetStandardsForSpecifications(ReceiveMaterialsOnDemand, ListOfData = Undefined)
	
	Return Documents.ProductionStage2_2.GetStandardsForSpecifications(
		ProductionBatchData,
		ReceiveMaterialsOnDemand,
		ListOfData);
	
EndFunction

&AtServer
Procedure ShowStandardsWhenChangingOnServer(ListOfTS = Undefined)
	
	If (ListOfTS = Undefined Or Find(ListOfTS, "SupplyWithMaterialsAndWorks") > 0) Then
		
		FillInStandards("SupplyWithMaterialsAndWorks");
	EndIf;
	
	If (ListOfTS = Undefined Or Find(ListOfTS, "LaborCosts") > 0) Then
		
		FillInStandards("LaborCosts");
	EndIf;
	
	ConfigureDependentFormElements(ThisForm, "ShowStandards");
	
EndProcedure

&AtServer
Procedure FillInStandards(TSName, FillInLines = Undefined)
	
	RequiredToFillIn = False;
	
	If FillInLines <> Undefined Then
		RowsArray = FillInLines;
	Else
		RowsArray = Object[TSName];
	EndIf;
	
	If TSName = "SupplyWithMaterialsAndWorks"
		And ShowStandardsMaterials Then
	
		DataArray = New Array;
		For Each CurrentData In RowsArray Do
			RowData = New Structure("Stage,Products,Characteristic,ItemVariantsAreUsed,Package");
			FillPropertyValues(RowData, CurrentData);
			DataArray.Add(RowData);
		EndDo;
		RequiredToFillIn = True;
		
	ElsIf TSName = "LaborCosts"
		And ShowStandardsLaborCosts Then
		
		DataArray = New Array;
		For Each CurrentData In RowsArray Do
			RowData = New Structure("Stage,WorkKind");
			FillPropertyValues(RowData, CurrentData);
			DataArray.Add(RowData);
		EndDo;
		RequiredToFillIn = True;
		
	EndIf;
	
	If RequiredToFillIn Then
		
		StandardsFromRepository = GetStandardsFromTemporaryStorage();
		
		Standards = GetStandardsWhenChangingRows(TSName, DataArray, StandardsFromRepository);
		For Cnt = 0 To RowsArray.Count() - 1 Do
			RowsArray[Cnt].NormativeStandard = Standards[Cnt];
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServer
Function GetStandardsFromTemporaryStorage()
	
	If IsTempStorageURL(StorageAddressStandards) Then
		
		Result = GetFromTempStorage(StorageAddressStandards);
		Return Result;
		
	EndIf;
	
	Result = New Structure();
	
	SpecificationData = GetStandardsForSpecifications(True, "MaterialsAndServices,IncomingProducts,LaborCosts");
	
	If SpecificationData <> Undefined Then
		
		Table = SpecificationData.MaterialsAndServices.Copy(, "Stage,Products,Characteristic,Package,PackageData,NumberOfPackages"); // ValueTable
		Table.GroupBy("Stage,Products,Characteristic,Package,PackageData", "NumberOfPackages");
		Result.Insert("SupplyWithMaterialsAndWorks", Table);
		
		Table = SpecificationData.LaborCosts.Copy(, "Stage,WorkKind,Count");// ValueTable - 
		Table.GroupBy("Stage,WorkKind", "Count");
		Result.Insert("LaborCosts", Table);
	
	EndIf;
	
	StorageAddressStandards = PutToTempStorage(Result, UUID);
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function GetStandardsWhenChangingRows(Val TSName, Val DataArray, Val AddressOrRegulations)
	
	If IsTempStorageURL(AddressOrRegulations) Then
		StandardsFromRepository = GetFromTempStorage(AddressOrRegulations);
	Else
		StandardsFromRepository = AddressOrRegulations;
	EndIf;
	
	If ValueIsFilled(StandardsFromRepository) And StandardsFromRepository.Property(TSName) Then
		Standards = StandardsFromRepository[TSName];
	Else
		Standards = Undefined;
	EndIf;
	
	If TSName = "SupplyWithMaterialsAndWorks" Then
		
		TheStructureOfTheSearch = New Structure("Stage,Products,Characteristic");
		
		Result = ProductionManagement.GetStandards(
			Standards,
			DataArray,
			TheStructureOfTheSearch,
			True);
		
	ElsIf TSName = "LaborCosts" Then
		
		TheStructureOfTheSearch = New Structure("Stage,WorkKind");
		
		Result = ProductionManagement.GetStandards(
			Standards,
			DataArray,
			TheStructureOfTheSearch,
			False);
	
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Procedure SoftwareSpecificationsOnServer()
	
	ClearRowsOfTablePart("SupplyWithMaterialsAndWorks");
	
	SpecificationData = GetStandardsForSpecifications(False, "MaterialsAndServices,IncomingProducts");
	If SpecificationData = Undefined Then
		Return;
	EndIf;
	
	MatchingStages = ComplianceOfSpecificationStagesWithDocuments();
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInShopPantryAttribute");
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	ReadyForProcessing_ = New Map;
	
	For Each String In SpecificationData.MaterialsAndServices Do
		
		ObjectStage = ObjectIsCreatedByReference(ThisObject, MatchingStages[String.Stage]);
		
		If ObjectStage.ReadOnly Then
			Continue;
		EndIf;
		
		NewRow = Object.SupplyWithMaterialsAndWorks.Add();
		FillPropertyValues(NewRow, String);
		NewRow.Department = String.StageSubdivision; 
		NewRow.Ref        = ObjectStage.Ref;
		
		NewRow.LinkKeyBOM = String.ConnectionKey;
		NewRow.DateOfShipment = CurrentSessionDate();
		
		If ReadyForProcessing_[ObjectStage] = Undefined Then
			ReadyForProcessing_.Insert(ObjectStage, New Array);
		EndIf;
		ReadyForProcessing_[ObjectStage].Add(NewRow);
		
	EndDo;
	
	For Each ReadyForProcessing In ReadyForProcessing_ Do
		
		StructureOfActions.Insert(
			"FillInPurposeOfProvisionInProductionPhase",
			ReadyForProcessing.Key.ParametersForFillingAssignments);
			
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			ReadyForProcessing.Value,
			StructureOfActions,
			Object.SupplyWithMaterialsAndWorks,
			CachedValues);
			
	EndDo;
	
	If SpecificationData.Property("MaterialsAndWorksSets") Then
		For Each String In SpecificationData.MaterialsAndWorksSets Do
			
			ObjectStage = ObjectIsCreatedByReference(ThisForm, MatchingStages[String.Stage]);
			
			If ObjectStage.ReadOnly Then
				Continue;
			EndIf;
			
			NewRow = Object.MaterialsAndWorksSets.Add();
			FillPropertyValues(NewRow, String);
			NewRow.Ref = ObjectStage.Ref;
			
		EndDo;
	EndIf;
	
	If RightToReadSubstitutes And ShowAnalogues Then
		NotePresenceOfAnalogues();
	EndIf;
	
	AfterChangingTSStringsProgrammaticallyOnServer("SupplyWithMaterialsAndWorks");
	
EndProcedure

&AtServer
Procedure FillInLaborCostsAccordingToSpecificationOnServer()
	
	ClearRowsOfTablePart("LaborCosts");
	
	SpecificationData = GetStandardsForSpecifications(False, "LaborCosts");
	If SpecificationData = Undefined Then
		Return;
	EndIf;
	
	MatchingStages = ComplianceOfSpecificationStagesWithDocuments();
	
	For Each String In SpecificationData.LaborCosts Do
		
		ObjectStage = ObjectIsCreatedByReference(ThisForm, MatchingStages[String.Stage]);
		
		If ObjectStage.ReadOnly Then
			Continue;
		EndIf;
		
		NewRow = Object.LaborCosts.Add();
		FillPropertyValues(NewRow, String);
		NewRow.Department = String.StageSubdivision;
		NewRow.Ref        = ObjectStage.Ref;
		
	EndDo;
	
	AfterChangingTSStringsProgrammaticallyOnServer("LaborCosts");
	
EndProcedure

#EndRegion

#Region Substitutes

&AtServer
Procedure NotePresenceOfAnalogues()

	TableName = "SupplyWithMaterialsAndWorks";
	AlternativeMaterials.NotePresenceOfAnalogues(Object[TableName], AnalogSelectionParameters(TableName, 0));
	
EndProcedure

&AtClient
Procedure OpenSelectionOfAnalogues()
	
	TableName = "SupplyWithMaterialsAndWorks";
	WarningText = "";
	
	SelectedRows = Items[TableName].SelectedRows;
	If SelectedRows.Count() = 0 Then
		WarningText = NStr("vi = 'Cần chọn (các) dòng';
							|ru = 'Необходимо выделить строку(и)';
							|en = 'Highlight the line(s)'; fa = 'Highlight the line(s)';
							|it = 'È necessario evidenziare la riga (le righe)';
							|pl = 'Należy zaznaczyć wiersz(e)';
							|tr = 'Satır(lar) vurgulanmalıdır'");
	Else
		
		HighlightedLinks = New Array;
		
		For Each RowID In SelectedRows Do
			
			TableRow = Object.SupplyWithMaterialsAndWorks.FindByID(RowID);
			
			If Not ValueIsFilled(TableRow.Ref) Then
				WarningText = NStr("vi = 'Cần chọn các hàng với một bước sản xuất hoàn thành';
									|ru = 'Необходимо выбрать строки с заполненным этапом производства';
									|en = 'Select lines with the filled production stage'; fa = 'Select lines with the filled production stage';
									|it = 'È necessario selezionare le righe con la fase di produzione completata.';
									|pl = 'Należy wybrać wiersze z wypełnionym etapem produkcji';
									|tr = 'Tamamlanmış üretim aşaması olan satırları seçmeniz gerekmektedir'");
				Break;
			ElsIf HighlightedLinks.Count() = 0 Then
				HighlightedLinks.Add(TableRow.Ref);
			ElsIf HighlightedLinks.Find(TableRow.Ref) = Undefined Then
				WarningText = NStr("vi = 'Cần chọn các dòng của một chứng từ';
									|ru = 'Необходимо выбрать строки одного документа';
									|en = 'Select lines of the same document'; fa = 'Select lines of the same document';
									|it = 'È necessario selezionare le righe di un documento';
									|pl = 'Należy wybrać wiersze jednego dokumentu';
									|tr = 'Aynı belgenin satırlarını seçmeniz gerekmektedir'");
				Break;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	If ValueIsFilled(WarningText) Then
		ShowMessageBox(, WarningText);
		Return;
	EndIf;	
	
	AlternativeMaterialsClient.OpenSelectionOfAnalogues(AnalogSelectionParameters(TableName, 1), ThisForm);
	
EndProcedure

&AtServer
Procedure Replace_With_Analogues(AddressInStorage = Undefined)
	
	TableName = "SupplyWithMaterialsAndWorks";
	AdditionalFields = "ProductCostElement,Ref";
	
	Result = ?(AddressInStorage = Undefined,
		AlternativeMaterials.PerformReplacementWithAnaloguesAutomatically(Object[TableName], AnalogSelectionParameters(TableName, 2), AdditionalFields, "Action_Substitutes_ToReserve_"),
		AlternativeMaterials.PerformReplacementForAnalogues(Object[TableName], AddressInStorage, AdditionalFields, "Action_Substitutes_ToReserve_"));
	
	IndexesOfModifiedRows = Result.IndexesOfModifiedRows;
	IndexesOfNewRows = Result.IndexesOfNewRows;
	
	NumberOfReplacementsMade = IndexesOfModifiedRows.Count() + IndexesOfNewRows.Count();
	MessageText  = StrTemplate(NStr("vi = 'Dòng được thay đổi: %1';
									|ru = 'Измененных строк: %1';
									|en = 'Changed lines: %1'; fa = 'Changed lines: %1';
									|it = 'Измененных строк: %1';
									|pl = 'Changed lines: %1';
									|tr = 'Değiştirilen satırlar: %1'"), NumberOfReplacementsMade);
	Common.MessageToUser(MessageText);

	If NumberOfReplacementsMade = 0 Then
		Return;
	EndIf;
	
	RowsIDs = New Array;
	
	Modified = True;
	
	StructureOfActions = New Structure;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array();
	
	AddActionsToStructureWhenChangingPackagesNumber(TableName, ThisObject, StructureOfActions);
	For Each RowIndex In IndexesOfModifiedRows Do
		TSRow = Object[TableName][RowIndex];
		RowsIDs.Add(TSRow.GetID());
		RowsToProcess.Add(TSRow);
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object[TableName],
		CachedValues);
	
	DateOfShipment = ?(Object.NotShipInInstallments, Object.DateOfShipment, Undefined);
	CurrentSessionDate = CurrentSessionDate();
	SecurityOptionShip = Enums.SupplyOptions.Ship;
	
	ReadyForProcessing_ = New Map;
	
	For Each RowIndex In IndexesOfNewRows Do
		TSRow = Object[TableName][RowIndex]; //FormDataCollectionItem
		TSRow.SupplyAssignment = TSRow.Purpose;
		
		ObjectStage = ObjectIsCreatedByReference(ThisObject, TSRow.Ref);
		TSRow.Department = ObjectStage.Department;
		
		If DateOfShipment <> Undefined Then
			TSRow.DateOfShipment = DateOfShipment;
		ElsIf TSRow.SupplyOption = SecurityOptionShip Then
			TSRow.DateOfShipment = CurrentSessionDate;
		EndIf;
		
		If ReadyForProcessing_[TSRow.Ref] = Undefined Then
			ReadyForProcessing_.Insert(TSRow.Ref, New Array);
		EndIf;
		ReadyForProcessing_[TSRow.Ref].Add(TSRow);
		
		RowsIDs.Add(TSRow.GetID());
	EndDo;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	For Each KeyAndValue In ReadyForProcessing_ Do
		StructureOfActions.Clear();
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("FillInSeparately", False);
		AdditionalParameters.Insert("FillInOnlyEmpty", True);
		
		AddActionsToStructureWhenChangingProducts(
			ObjectIsCreatedByReference(ThisObject, KeyAndValue.Key), TableName, ThisObject, StructureOfActions, AdditionalParameters);
		
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			KeyAndValue.Value,
			StructureOfActions,
			Object[TableName],
			CachedValues);
		
	EndDo;
	
	ProductDataManagement.UpdateSetsOfMaterialsAndWorksTable(Object);
	
	AfterChangingTSStringsProgrammaticallyOnServer(TableName, RowsIDs, StructureOfActions);
	
EndProcedure

// Generates parameters for selecting analogs
//
// Parameters:
//	TableName - String - Name of the table to be processed
//	Mode      - Number  - 0-show analogs
//                        1 - choose the analogues
//                        2-replace with analogs
// 
// Returns:
//  Structure - See AlternativeMaterials.AnalogSelectionParameters
//
&AtServer
Function AnalogSelectionParameters(TableName, Mode)
	
	SourceType = New TypeDescription("DocumentRef.ProductionStage2_2");
	FormParameters = AlternativeMaterials.AnalogSelectionParameters(SourceType);
	
	// GeneralParameters
	FormParameters.GeneralParameters.ShowBalance = True;
	
	// GoodsParameters
	FieldsStructure = AlternativeMaterials.StructureOfTableFieldsToReplaceWithAnalogues();
	FieldsStructure.MainField = "Ref," + Chars.LF + FieldsStructure.MainField;
	FieldsStructure.SpoofFields.Insert("Purpose", "SupplyAssignment");
	
	AdditionalParameters = AlternativeMaterials.AdditionalParameters();
	AdditionalParameters.RowFilter = New Structure("WorkPlanning", CommonClientServer.ValueInArray(False));
	
	ProductData_9 = AlternativeMaterials.GetProductData(
		ThisForm, "Object", TableName, Mode, True, FieldsStructure, AdditionalParameters);
	
	FillPropertyValues(FormParameters.GoodsParameters, ProductData_9);
	
	If Mode = 2
	   And GetFunctionalOption("DynamicStructureOfProductionOrders") Then
	
		SelectionOfPermissions = New Map();
		TMCommonUse.AddSelectionItemToCollection(SelectionOfPermissions, "AlternativeMaterials.UseItForAutocorrectInOrders", "&UseItForAutocorrectInOrders");
		
		PermissionSelectionParameters = New Map();
		PermissionSelectionParameters.Insert("UseItForAutocorrectInOrders", CommonClientServer.ValueInArray(True));
		
		FormParameters.GeneralParameters.SelectionOfPermissions = SelectionOfPermissions;
		FormParameters.GeneralParameters.PermissionSelectionParameters = PermissionSelectionParameters;
	
	EndIf;
	
	// SubstitutesParameters
	Query = New Query;
	Query.Text =
	"SELECT
	|	ProductionStage2_2.Ref AS Ref,
	|	ProductionStage2_2.Department AS Department,
	|	ProductionStage2_2.LineOfBusiness AS LineOfBusiness,
	|	ProductionStage2_2.Stage AS Stage
	|FROM
	|	Document.ProductionStage2_2 AS ProductionStage2_2
	|WHERE
	|	ProductionStage2_2.Ref IN(&ReferencesArrray)";
	
	If Mode = 1 Then// pick up analogs
		SelectedRows = Items[TableName].SelectedRows;
		TableRow = ObjectTableByName(Object, TableName).FindByID(SelectedRows[0]);
		Query.SetParameter("ReferencesArrray", TableRow.Ref);
	Else
		Query.SetParameter("ReferencesArrray", Object[TableName].Unload(, "Ref"));
	EndIf;
	
	Result = Query.Execute();
	
	StructureOfData = New Structure;
	StructureOfData.Insert("PermissionValidityDate", StartOfDayCurSessionDate());
	StructureOfData.Insert("ProductionOrder", ProductionBatchData.ReferenceOrder);
	StructureOfData.Insert("BillOfMaterials", ProductionBatchData.BillOfMaterials);
	StructureOfData.Insert("Product", ProductionBatchData.Products);
	StructureOfData.Insert("ItemVariantOfProduct", ProductionBatchData.Characteristic);
	
	ParametersTable = FormParameters.SubstitutesParameters.ParametersTable;
	
	Selection = Result.Select();
	While Selection.Next() Do
		TableRow = ParametersTable.Add();
		FillPropertyValues(TableRow, Selection);
		FillPropertyValues(TableRow, StructureOfData);
	EndDo;
	
	FormParameters.SubstitutesParameters.ParametersTable = 
		PutToTempStorage(ParametersTable, UUID);
	
	Return FormParameters;
	
EndFunction

#EndRegion

#Region MaterialsAndWorksSets

&AtClient
Procedure BeforeDeletingRowsIncludedInSets()
	
	SelectedRows = Items.SupplyWithMaterialsAndWorks.SelectedRows;
	
	If ProductDataManagementClient.ThereAreLinesIncludedInSet(Object, SelectedRows) Then
		
		ProcessDeletionOfRowsIncludedInSets(SelectedRows);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WhenChangingNomenclatureOfCharacteristicInLineIncludedInSet()
	
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	
	If ValueIsFilled(CurrentData.CommunicationKeySet) Then
		
		RowsIDs = CommonClientServer.ValueInArray(Items.SupplyWithMaterialsAndWorks.CurrentRow);
		ProcessDeletionOfRowsIncludedInSets(RowsIDs);
		
		CurrentData.CommunicationKeySet = Undefined;
		CurrentData.IncludedInSet   = False;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessDeletionOfRowsIncludedInSets(RowsIDs)
	
	ProductDataManagement.ProcessDeletionOfRowsIncludedInSets(Object, RowsIDs);
	
EndProcedure

&AtServer
Function AddSetComposition(StringSelection__, TSName, StageLink)
	
	AddedRows  = New Array;
	
	ContentData = StringSelection__.ContentData;
	If ValueIsFilled(ContentData) Then
		
		For Each String In ContentData.MaterialsAndServices Do
			
			NewRow = ObjectTableByName(Object, TSName).Add();
			FillPropertyValues(NewRow, String);
			
			NewRow.Ref = StageLink;
			
			AddedRows.Add(NewRow);
			
		EndDo;
		
		For Each String In ContentData.MaterialsAndWorksSets Do
			
			NewRow = Object.MaterialsAndWorksSets.Add();
			FillPropertyValues(NewRow, String);
			
			NewRow.Ref = StageLink;
			
		EndDo;
		
	Else
		
		MessageText = StrTemplate(NStr("vi = 'Không thể nhận thành phần bộ sản phẩm: %1';
										|ru = 'Не удалось получить состав набора: %1';
										|en = 'Cannot receive the set content: %1'; fa = 'Cannot receive the set content: %1';
										|it = 'Non è stato possibile ricevere la composizione del kit: %1';
										|pl = 'Nie udało się otrzymać składu zestawu: %1';
										|tr = 'Set kapsamı alınamadı: %1'"),
			ProductsClientServer.ProductPresentation(StringSelection__.Products, StringSelection__.Characteristic));
			
		Common.MessageToUser(
			MessageText,
			Object.Ref);
		
	EndIf;
	
	Return AddedRows;
	
EndFunction

&AtServer
Procedure CheckSelectStageInSetLines(StageLink, SelectedRows)
	
	KeysLinksSet = New Array;
	
	For Each RowID In SelectedRows Do
		CurrentData = Object.SupplyWithMaterialsAndWorks.FindByID(RowID);
		If ValueIsFilled(CurrentData.CommunicationKeySet)
			And KeysLinksSet.Find(CurrentData.CommunicationKeySet) = Undefined Then
				KeysLinksSet.Add(CurrentData.CommunicationKeySet);
		EndIf;
	EndDo;
	
	If KeysLinksSet.Count() > 0 Then
		CheckSelectStageInSetLinesServer(StageLink, KeysLinksSet, SelectedRows)
	EndIf;
	
EndProcedure

&AtServer
Procedure CheckSelectStageInSetLinesServer(StageLink, KeysLinksSet, SelectedRows)
	
	ProductDataManagement.GetSetCommunicationKeysRecursively(Object.MaterialsAndWorksSets, KeysLinksSet);
	
	FilterStructure11 = New Structure("CommunicationKeySet");
	FilterStructure12 = New Structure("ConnectionKey");
	
	For Each ConnectionKey In KeysLinksSet Do
		
		FilterStructure11.CommunicationKeySet = ConnectionKey;
		FoundRows = Object.SupplyWithMaterialsAndWorks.FindRows(FilterStructure11);
		For Each String In FoundRows Do
			RowID = String.GetID();
			If SelectedRows.Find(RowID) = Undefined Then
				String.Ref = StageLink;
				SelectedRows.Add(RowID);
			EndIf;
		EndDo;
		
		FilterStructure12.ConnectionKey = ConnectionKey;
		FoundRows = Object.MaterialsAndWorksSets.FindRows(FilterStructure12);
		For Each String In FoundRows Do
			String.Ref = StageLink;
		EndDo;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure ProcessSplitOfStringIncludedInSet(NewRow)
	
	If ValueIsFilled(NewRow.CommunicationKeySet) Then
		ProcessSplitOfStringIncludedInSetServer(NewRow.CommunicationKeySet);
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessSplitOfStringIncludedInSetServer(CommunicationKeySet)
	
	ProductDataManagement.AdjustTableSetsOfMaterialsAndWorks(
		Object.MaterialsAndWorksSets, CommunicationKeySet, 1);
	
EndProcedure

#EndRegion

#Region SetOfSeries

&AtClient
Procedure OpenSelectionOfSeries(TSName, Text = "")
	
	CurrentData = Items[TSName].CurrentData;
	If CurrentData = Undefined Then
		ShowMessageBox(, NStr("vi = 'Cần chọn một dòng để chỉ ra chuỗi';
								|ru = 'Необходимо выбрать строку для указания серии';
								|en = 'Select a line to specify batch'; fa = 'Select a line to specify batch';
								|it = 'È necessario selezionare una riga per specificare la serie';
								|pl = 'Należy wybrać wiersz dla określenia serii';
								|tr = 'Partinin belirtilmesi için bir satır seçmeniz gerekmektedir'"));
		Return;
	ElsIf CurrentData.ReadOnly Then
		ShowMessageBox(, NStr("vi = 'Không thể thực hiện lệnh cho dòng đã chọn!';
								|ru = 'Команда не может быть выполнена для выбранной строки!';
								|en = 'Command cannot be executed for the selected line.'; fa = 'Command cannot be executed for the selected line.';
								|it = 'Il comando non può essere eseguito per la riga selezionata!';
								|pl = 'Polecenie nie może być wykonane dla wybranego wiersza!';
								|tr = 'Seçili satır için komut gerçekleştirilemez!'"));
		Return;
	EndIf;
	If Not CheckBlockDocuments() Then
		Return;
	EndIf;
	
	If TSName = "SupplyWithMaterialsAndWorks" And CurrentData.BatchesIndicationStatus > 8 Then
		
		FormParameters = ParametersOfQuantityAndSeriesRequestForm(ProvisionInDocumentsClientServer.SeriesSelectionMode());
		If FormParameters <> Undefined Then
			
			OpenForm(
				"DataProcessor.QuantityAndBatchRequest.Form",
				FormParameters,
				ThisObject,
				,
				,
				,
				New CallbackDescription("ProcessWarehouseAndBatchSelection", ThisObject, FormParameters));
				
		EndIf;
		
		Return;
	EndIf;
	
	NeedServerCall = ProductsClient.YouNeedServerCallToSpecifySeries(
							ThisForm, 
							SeriesSpecificationParameters[TSName], 
							Text, 
							CurrentData);
	
	If NeedServerCall Then
		
		ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm(CurrentData.GetID(), TSName);
		AdditionalParameters = New Structure("SeriesSpecificationParameters,ParametersOfSeriesIndicationForm", 
											SeriesSpecificationParameters[TSName], ParametersOfSeriesIndicationForm);
		CallbackDescription = New CallbackDescription("OpenSelectionOfSeriesCompletion", ThisObject, AdditionalParameters);
		
		OpenForm(ParametersOfSeriesIndicationForm.FormName, 
						ParametersOfSeriesIndicationForm, 
						ThisForm,,,,
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
	
	StructureOfActions = New Structure;
	If SeriesSpecificationParameters.NameTSGoods = "ManufacturedProducts"
		Or SeriesSpecificationParameters.NameTSGoods = "SideAndIntermediateRelease"
		Or SeriesSpecificationParameters.NameTSGoods = "UnusedMaterials" Then
		StructureOfActions.Insert("UpdateNumberOfProductsWhenRegistering", True);
		AddActionsToStructureWhenChangingPackagesNumber(SeriesSpecificationParameters.NameTSGoods, ThisForm, StructureOfActions);
	EndIf; 
	
	ProductsServer.ProcessSeriesIndication_(
		Object, 
		SeriesSpecificationParameters, 
		ParametersOfSeriesIndicationForm, 
		StructureOfActions);
		
	AfterChangingTSStringsProgrammaticallyOnServer(SeriesSpecificationParameters.NameTSGoods,, StructureOfActions);
	
EndProcedure

&AtServer
Function ParametersOfSeriesIndicationForm(CurDataId, TSName)
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(
					Object, 
					SeriesSpecificationParameters[TSName], 
					CurDataId, 
					ThisForm);
	
EndFunction

&AtServer
Procedure FillInStatusesForSpecifyingSeriesServer(ListOfTS = Undefined, UpdateParametersForSpecifyingSeries = False)
	
	If UpdateParametersForSpecifyingSeries Then
		SeriesSpecificationParameters = New FixedStructure(
			ProductsServer.SeriesSpecificationParameters(Object, DataProcessors.EditProductionStageSequence));
		SetVisibilityOfSeriesElements();
	EndIf; 
	
	If ListOfTS <> Undefined Then
		ArrayTS = StrSplit(ListOfTS, ",");
		For Each TSName In ArrayTS Do
			ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters[TSName]);
		EndDo; 
	Else
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.ManufacturedProducts);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.SideAndIntermediateRelease);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.SupplyWithMaterialsAndWorks);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.MaterialsAndWorksConsumption);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.UnusedMaterials);
	EndIf; 
	
EndProcedure

&AtServer
Procedure SetVisibilityOfSeriesElements()
	
	Items.SupplyWithMaterialsAndWorksSeries.Visible = SeriesSpecificationParameters.SupplyWithMaterialsAndWorks.UseItemsBatch;
	Items.SoftwareForCompletingTheFEFOSeries.Visible = SeriesSpecificationParameters.SupplyWithMaterialsAndWorks.UseItemsBatch;
	
	Items.UnusedMaterialsSeries.Visible = SeriesSpecificationParameters.UnusedMaterials.UseItemsBatch;
	Items.MaterialsAndWorksConsumptionSeries.Visible = SeriesSpecificationParameters.MaterialsAndWorksConsumption.UseItemsBatch;
	
	Items.ManufacturedProductsSeries.Visible = SeriesSpecificationParameters.ManufacturedProducts.UseItemsBatch;
	Items.ManufacturedProductsBatchesIndicationStatus.Visible = SeriesSpecificationParameters.ManufacturedProducts.UseItemsBatch;
	Items.OutputProductsSpecifyTheSeries_3.Visible = SeriesSpecificationParameters.ManufacturedProducts.UseItemsBatch;
	
	Items.SideAndIntermediateReleaseSeries.Visible = SeriesSpecificationParameters.SideAndIntermediateRelease.UseItemsBatch;
	Items.SideAndIntermediateReleaseBatchesIndicationStatus.Visible = SeriesSpecificationParameters.SideAndIntermediateRelease.UseItemsBatch;
	Items.SideOfTheProductToSpecifySeries.Visible = SeriesSpecificationParameters.SideAndIntermediateRelease.UseItemsBatch;
	
	FillInStatusesOfSpecifyingBatchesOfFINISHEDProductBeingRepaired();
	
EndProcedure

&AtClient
Procedure AfterRemovingTSRowsForWhichThereIsSeries(TSName, Item)

	SeriesStatusesNeedToBeUpdated = ProductsClient.SeriesStatusesNeedToBeUpdated(
		Item, CachedValues, SeriesSpecificationParameters[TSName], True);
	
	If SeriesStatusesNeedToBeUpdated Then

		AfterDeletingTSRowsForWhichThereIsSeriesOnServer(TSName, CachedValues); // server call

		ProductsClient.UpdateCachedValuesToAccountForSeries(
			Item, CachedValues, SeriesSpecificationParameters[TSName]);
			
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterDeletingTSRowsForWhichThereIsSeriesOnServer(TSName, CachedValues)

	FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(TSName, Undefined, CachedValues);

EndProcedure

&AtServer
Procedure FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(TSName, IDCurrentRow, CachedValues)
	
	ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Object, 
				SeriesSpecificationParameters[TSName], IDCurrentRow, CachedValues);
	
EndProcedure

&AtServer
Procedure CalculatePercentageOfCostAllocationForOutputProducts()
	
	ProductionServer.CalculatePercentageOfCostAllocationForOutputProducts(Object, CostAllocationParameters);
	
EndProcedure

&AtServer
Function ParametersOfCostShareEntryForm_(CurDataId)
	
	FormParameters = ProductionServer.ParametersOfCostShareEntryForm(Object, CostAllocationParameters, CurDataId);
	Return FormParameters;
	
EndFunction

&AtServer
Function ThereAreFilledSeriesByFEFO()

	Return ProductsServer.ThereAreLinesWithFEFOFilledSeries(Object.SupplyWithMaterialsAndWorks);

EndFunction

&AtServer
Function FillInSeriesByFEFOServer()
	
	If ProductsServer.ThereAreLinesWithFEFOFilledSeries_(Object.SupplyWithMaterialsAndWorks) Then
		
		ProductsServer.FillInSeriesByFEFO(Object, SeriesSpecificationParameters.SupplyWithMaterialsAndWorks);	
		UpdateColumnAvailableServer();
		
		Return True;
		
	Else
		
		Return False;
		
	EndIf;
	
EndFunction

&AtServer
Procedure FillInStatusesOfSpecifyingBatchesOfFINISHEDProductBeingRepaired()

	DataStructureOfFinishedProductBeingRepaired = ProductionManagementClientServer.DataOfFinishedProductBeingRepairedByStructure(Object);
	
	ProductsServer.FillInStatusesForSpecifyingSeries(DataStructureOfFinishedProductBeingRepaired, SeriesSpecificationParameters.FinishedProductBeingRepaired);
	
	Object.UnderRepairBatch = DataStructureOfFinishedProductBeingRepaired.Series;
	Object.UnderRepairBatchSpecificationStatus = DataStructureOfFinishedProductBeingRepaired.BatchesIndicationStatus;
	
	ProductionClientServer.EstablishAvailabilityOfBatchesOfRepairedFinishedProduct(
		ThisObject, Object.ProductionProcessType, Object.UnderRepairBatchSpecificationStatus);

EndProcedure

&AtServer
Procedure FillInBatchIndicationStatusesONChangesOfFinishedProductBeingRepaired(CachedValues, DataStructureOfFinishedProductBeingRepaired = Undefined)

	If DataStructureOfFinishedProductBeingRepaired = Undefined Then
		DataStructureOfFinishedProductBeingRepaired = ProductionManagementClientServer.DataOfFinishedProductBeingRepairedByStructure(Object);
	EndIf;
	
	ProductsServer.FillInStatusesOfSpecifyingSeriesWhenChangingProductInHeader(
		DataStructureOfFinishedProductBeingRepaired, SeriesSpecificationParameters.FinishedProductBeingRepaired, CachedValues);
	
	Object.UnderRepairBatch = DataStructureOfFinishedProductBeingRepaired.Series;
	Object.UnderRepairBatchSpecificationStatus = DataStructureOfFinishedProductBeingRepaired.BatchesIndicationStatus;

	ProductionClientServer.EstablishAvailabilityOfBatchesOfRepairedFinishedProduct(
		ThisObject, Object.ProductionProcessType, Object.UnderRepairBatchSpecificationStatus);

EndProcedure

&AtClient
Procedure UpdateCachedValuesToAccountForBatchesOfFINISHEDProductBeingRepaired(DataStructureOfFinishedProductBeingRepaired = Undefined)
	
	If DataStructureOfFinishedProductBeingRepaired = Undefined Then
		DataStructureOfFinishedProductBeingRepaired = ProductionManagementClientServer.DataOfFinishedProductBeingRepairedByStructure(Object);
	EndIf;
	
	ProductsClient.UpdateCachedHeaderValuesToAccountForSeries(
		DataStructureOfFinishedProductBeingRepaired, CachedValues, SeriesSpecificationParameters.FinishedProductBeingRepaired);
	
EndProcedure

&AtClient
Procedure ProcessIndicationOfBatchOfFINISHEDProductBeingRepaired(ValueSelected);
	
	DataStructureOfFinishedProductBeingRepaired = ProductionManagementClientServer.DataOfFinishedProductBeingRepairedByStructure(Object);
	
	FormEmulation = New Structure();
	FormEmulation.Insert("Object", DataStructureOfFinishedProductBeingRepaired);
	ProductsClient.ProcessSeriesIndication(FormEmulation, SeriesSpecificationParameters.FinishedProductBeingRepaired, ValueSelected);
	
	Object.UnderRepairBatch = DataStructureOfFinishedProductBeingRepaired.Series;
	Object.UnderRepairBatchSpecificationStatus = DataStructureOfFinishedProductBeingRepaired.BatchesIndicationStatus;
	
	UpdateCachedValuesToAccountForBatchesOfFINISHEDProductBeingRepaired(DataStructureOfFinishedProductBeingRepaired);
	
EndProcedure

#EndRegion

#Region WorkingWithClipboard

&AtClient
Procedure CopyTSLines(TSName)
	
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items[TSName]) Then
		CopyLinesOnServer(TSName);
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(Items[TSName].SelectedRows.Count());
	EndIf;
	
EndProcedure

&AtServer
Procedure CopyLinesOnServer(TSName)
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object[TSName], Items[TSName].SelectedRows);
	
EndProcedure

&AtClient
Procedure GetLinesFromClipboard(TSName)
	
	NumberOfRowsBeforeInsertion = Object[TSName].Count();
	
	GetLinesFromClipboardOnServer(TSName);
	
	NumberOfInserted = Object[TSName].Count() - NumberOfRowsBeforeInsertion;
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboardOnServer(TSName)
	
	Var CompositionOfLines, FilterParameters;
	
	If TSName = "ManufacturedProducts" Or TSName = "SideAndIntermediateRelease" Then
		CompositionOfLines = "Products,Characteristic,Package,NumberOfPackages";
	ElsIf TSName = "SupplyWithMaterialsAndWorks" Or TSName = "MaterialsAndWorksConsumption" Then
		CompositionOfLines = "Products,Characteristic,Package,NumberOfPackages,ProductCostElement";
	ElsIf TSName = "UnusedMaterials" Then
		CompositionOfLines = "Products,Characteristic,Package,NumberOfPackages";
	ElsIf TSName = "LaborCosts" Then
		CompositionOfLines = "WorkKind,Count,ProductCostElement";
	EndIf;
	
	SelectGoods = StrFind("ManufacturedProducts,SideAndIntermediateRelease,SupplyWithMaterialsAndWorks,MaterialsAndWorksConsumption,UnusedMaterials", TSName) > 0;
	If SelectGoods Then
		
		ArrayOfProductTypes = New Array;
		ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
		ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
		If TSName <> "UnusedMaterials" Then
			ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
		EndIf;
		
		FilterParameters = New Map;
		FilterParameters.Insert("Products.ItemsType", ArrayOfProductTypes);
		
	EndIf;
	
	LinesFromBuffer = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, CompositionOfLines);
	
	If Not ValueIsFilled(LinesFromBuffer) Then
		Return;
	EndIf;
	
	ReadyForProcessing_ = New Array;
	RowsIDs = New Array;
	
	StructureOfActions = New Structure;
	If SelectGoods Then 
		AddActionsToStructureWhenChangingProducts(
			ObjectIsCreatedByReference(ThisObject, DefaultReference), TSName, ThisObject, StructureOfActions);
		If TSName = "SideAndIntermediateRelease" Then
			InternalSubcontractingClientServer.AddActionFillInItemOwnerIsAvailable(ThisObject, StructureOfActions);
		EndIf;
	EndIf;
	
	For Each LineFromBuffer In LinesFromBuffer Do
		ObjectTable = Object[TSName];// FormDataCollection - 
		
		CurrentRow = ObjectTable.Add();
		FillPropertyValues(CurrentRow, LineFromBuffer);
		
		If SelectGoods Then
			ReadyForProcessing_.Add(CurrentRow);
		EndIf;
		RowsIDs.Add(CurrentRow.GetID());
	EndDo;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ReadyForProcessing_,
		StructureOfActions,
		Object[TSName],
		CachedValues);
	
	AfterChangingTSStringsProgrammaticallyOnServer(TSName, RowsIDs, StructureOfActions);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetAvailabilityOfClipboardCommands(Form, AttributeAvailability)
	
	Form.Items.ManufacturedProducts_InsertRows.Enabled = AttributeAvailability;
	Form.Items.ContextMenuOutputItemsInsertLines.Enabled = AttributeAvailability;
	
	Form.Items.ByProductsInsertRows_3.Enabled = AttributeAvailability;
	Form.Items.ContextMenuSideItemsInsertLines.Enabled = AttributeAvailability;

	Form.Items.SoftwareInsertRows.Enabled = AttributeAvailability;
	Form.Items.SupplyWithMaterialsAndWorksContextMenuSoftwareInsertRows.Enabled = AttributeAvailability;
	
	Form.Items.MaterialAndWorkConsumptionInsertLines.Enabled = AttributeAvailability;
	Form.Items.MaterialsAndWorksConsumptionContextMenuMaterialAndWorkConsumptionInsertLines.Enabled = AttributeAvailability;
	
	Form.Items.SaveMaterialsInsertLines.Enabled = AttributeAvailability;
	Form.Items.UnusedMaterialsContextMenuSaveMaterialsInsertLines.Enabled = AttributeAvailability;
	
	Form.Items.LaborCostsInsertLines.Enabled = AttributeAvailability;
	Form.Items.ContextMenuLaborCostsInsertLines.Enabled = AttributeAvailability;
	
EndProcedure

#EndRegion

#Region PredefinedValues

&AtClientAtServerNoContext
Function StatusStarted()
	
	Return PredefinedValue("Enum.StatusesOfProductionStages2_2.Initiated");

EndFunction

&AtClientAtServerNoContext
Function StatusCompleted_1()
	
	Return PredefinedValue("Enum.StatusesOfProductionStages2_2.Completed");

EndFunction

#EndRegion

#Region Pickup

&AtClient
Procedure OpensGoodsSelection(TSName)
	
	If TSName = "SupplyWithMaterialsAndWorks" Or TSName = "MaterialsAndWorksConsumption" Then
		HeaderParameter_ = NStr("vi = 'Chọn nguyên vật liệu và công việc';
								|ru = 'Подбор материалов и работ';
								|en = 'Pick materials and works'; fa = 'انتخاب مواد و کارها';
								|it = 'Selezione di materiali e lavori';
								|pl = 'Dobór materiałów i prac';
								|tr = 'Malzeme ve iş seçimi'");
	ElsIf TSName = "ManufacturedProducts" Or TSName = "SideAndIntermediateRelease" Then
		HeaderParameter_ = NStr("vi = 'Chọn sản phẩm';
								|ru = 'Подбор изделий';
								|en = 'Pick finished products'; fa = 'Pick finished products';
								|it = 'Selezione articoli';
								|pl = 'Wybór wyrobów';
								|tr = 'Nihai ürün seçimi'");
	Else
		HeaderParameter_ = NStr("vi = 'Chọn';
								|ru = 'Подбор';
								|en = 'Pick'; fa = 'انتخاب';
								|it = 'Selezione';
								|pl = 'Wybór';
								|tr = 'Seçim'");
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("SelectionModeWithoutAmountParameters", True);
	FormParameters.Insert("HideTheViewPriceColumn",            True);
	FormParameters.Insert("HideTheItemPricesCommand",   True);
	FormParameters.Insert("DoNotSplitSetsByComponents",  True);
	FormParameters.Insert("UseShipmentDates",          False);
	FormParameters.Insert("SelectSupplyOptions",        False);
	FormParameters.Insert("HideCommandRemainingQuantityInWarehouses",   True);
	FormParameters.Insert("Title",               HeaderParameter_);
	FormParameters.Insert("Document",                PredefinedValue("Document.ProductionStage2_2.EmptyRef"));
	
	ItemsTypes = AvailableProductTypes(ThisObject, TSName);
	FormParameters.Insert("FilterByProductType", New FixedArray(ItemsTypes));
	
	Notification = New CallbackDescription("OpensGoodsSelectionCompletion",
		ThisObject,
		TSName);
	
	OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form",
		FormParameters,
		ThisObject,
		UUID,,,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure OpensGoodsSelectionCompletion(ValueSelected, TSName) Export
	
	If Not ValueIsFilled(ValueSelected) Then
		Return;
	EndIf;
	
	StartProcessingSelectionResult(ValueSelected.GoodsAddressInStorage, "SelectGoods", TSName);
	
EndProcedure

&AtClient
Procedure StartProcessingSelectionResult(GoodsAddressInStorage, SelectionOption, TSName = "SupplyWithMaterialsAndWorks")
	
	StartProcessingSelectionResultOnServer(GoodsAddressInStorage, SelectionOption, TSName);
	
	If TimeConsumingOperation <> Undefined Then
		
		CallbackDescription = New CallbackDescription(
			"ProcessingOfSelectionResultCompletion",
			ThisObject);
			
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = True;
			
		TimeConsumingOperationsClient.WaitCompletion(
			TimeConsumingOperation,
			CallbackDescription,
			IdleParameters);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure StartProcessingSelectionResultOnServer(GoodsAddressInStorage, SelectionOption, TSName)
	
	If TimeConsumingOperation <> Undefined Then
		TimeConsumingOperations.CancelJobExecution(TimeConsumingOperation.JobID);
		TimeConsumingOperation = Undefined;
	EndIf;
	
	TableOfGoods = GetFromTempStorage(GoodsAddressInStorage); // ValueTable
	If TableOfGoods.Count() = 0 Then
		Return;
	EndIf;
	
	If TableOfGoods.Find(Enums.ItemsTypes.Set, "ItemsType") <> Undefined Then
		StartAddingCompositionOfSetsToSelectionResult(TableOfGoods, SelectionOption, TSName);
	ElsIf SelectionOption = "SelectGoods" Then
		ProcessingSelectionOfSelectionOnServer(TableOfGoods, TSName);
	ElsIf SelectionOption = "SelectMaterialsByBOM" Then
		UploadResultOfSelectingMaterialsBasedOnSpecifications(TableOfGoods);
	EndIf;
	
EndProcedure

&AtServer
Procedure StartAddingCompositionOfSetsToSelectionResult(TableOfGoods, SelectionOption, TSName = "SupplyWithMaterialsAndWorks")
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.RunInBackground    = True;
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Nhận thành phần bộ sản phẩm khi chọn.';
														|ru = 'Получение состава наборов при подборе.';
														|en = 'Get the set content during picking.'; fa = 'Get the set content during picking.';
														|it = 'Ricezione composizione kit durante la selezione.';
														|pl = 'Otrzymanie składu zestawów podczas wyboru.';
														|tr = 'Seçim sırasında küme içeriğinin alınması.'");
	
	ParametersForObtainingComposition = ProductDataManagement.ParametersForObtainingCompositionOfSetInProduction();
	ParametersForObtainingComposition.ReferenceOrder             = ProductionBatchData.ReferenceOrder;
	ParametersForObtainingComposition.ProductionStart       = ProductionBatchData.ProductionStart;
	ParametersForObtainingComposition.ProductionDispatcherBusinessUnit   = ProductionBatchData.ProductionDispatcherBusinessUnit;
	ParametersForObtainingComposition.LineOfBusiness  = ProductionBatchData.LineOfBusiness;
	ParametersForObtainingComposition.Product                  = ProductionBatchData.MainProductProducts;
	ParametersForObtainingComposition.ItemVariantOfProduct    = ProductionBatchData.MainProductCharacteristic;
	ParametersForObtainingComposition.ProductSpecification      = ProductionBatchData.BillOfMaterials;
	
	If SelectionOption = "SelectMaterialsByBOM" Then
		TableOfGoods.Columns.Department.Name = "AssigneeBusinessUnit";
	EndIf;
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("SelectionOption", SelectionOption);
	ProcedureParameters.Insert("TSName",          TSName);
	ProcedureParameters.Insert("TableOfGoods", TableOfGoods);
	ProcedureParameters.Insert("ParametersForObtainingComposition", ParametersForObtainingComposition);
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(
		"ProductDataManagement.AddCompositionOfSetsToSelectionResultInBackground",
		ProcedureParameters,
		ExecutionParameters);
	
EndProcedure

&AtClient
Procedure ProcessingOfSelectionResultCompletion(Result, AdditionalParameters) Export
	
	TimeConsumingOperation = Undefined;
	
	If Result <> Undefined And Result.Status = "Completed2" Then
		
		ProcessingOfSelectionResultCompletionOnServer(Result);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessingOfSelectionResultCompletionOnServer(TimeConsumingOperation)
	
	Result = GetFromTempStorage(TimeConsumingOperation.ResultAddress);
	
	SelectionOption = Result.SelectionOption;
	TableOfGoods = Result.TableOfGoods;
	TSName = Result.TSName;
	
	If SelectionOption = "SelectGoods" Then
		ProcessingSelectionOfSelectionOnServer(TableOfGoods, TSName);
	ElsIf SelectionOption = "SelectMaterialsByBOM" Then
		UploadResultOfSelectingMaterialsBasedOnSpecifications(TableOfGoods);
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(TableOfGoods, TSName)
	
	ReadyForProcessing_ = New Array;
	RowsIDs = New Array;
	
	DefaultStageObject = ObjectIsCreatedByReference(ThisObject, DefaultReference);
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingProducts(
		DefaultStageObject,
		TSName,
		ThisObject,
		StructureOfActions);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	For Each String In TableOfGoods Do
		If String.ItemsType = Enums.ItemsTypes.Set Then
			AddedRows = AddSetComposition(String, TSName, DefaultReference);
		Else
			NewRow = ObjectTableByName(Object, TSName).Add();
			FillPropertyValues(NewRow, String);
			NewRow.Ref = DefaultReference;
			AddedRows = CommonClientServer.ValueInArray(NewRow);
		EndIf;
		
		For Each CurrentRow In AddedRows Do
			FillInServiceDetailsForTheseStagesInLine(CurrentRow, TSName, DefaultStageObject);
			ReadyForProcessing_.Add(CurrentRow);
			RowsIDs.Add(CurrentRow.GetID());
		EndDo;
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ReadyForProcessing_,
		StructureOfActions,
		ObjectTableByName(Object, TSName),
		CachedValues);
		
	AfterChangingTSStringsProgrammaticallyOnServer(TSName, RowsIDs, StructureOfActions);
	
EndProcedure

&AtServer
Procedure UploadResultOfSelectingMaterialsBasedOnSpecifications(TableOfGoods)
	
	RowsArray = New Array;
	TSName = "SupplyWithMaterialsAndWorks";
	
	StructureOfActions = New Structure;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	MatchingStages = ComplianceOfSpecificationStagesWithDocuments();
	ReadyForProcessing_ = New Map;
	
	For Each String In TableOfGoods Do
		
		ObjectStage = ObjectIsCreatedByReference(ThisObject, MatchingStages[String.Stage]);
		If Not ObjectStage.ReadOnly Then
			StageLink = ObjectStage.Ref;
		Else
			StageLink = Catalogs.ProductionStages.EmptyRef();
		EndIf;
		
		If String.ItemsType = Enums.ItemsTypes.Set Then
			
			AddedRows = AddSetComposition(String, TSName, StageLink);
			
		Else
			
			NewRow = Object.SupplyWithMaterialsAndWorks.Add();
			FillPropertyValues(NewRow, String);
			NewRow.Ref = StageLink;
			
			AddedRows = CommonClientServer.ValueInArray(NewRow);
			
		EndIf;
		
		For Each NewRow In AddedRows Do
			
			NewRow.LinkKeyBOM = String.ConnectionKey;
			NewRow.DateOfShipment = CurrentSessionDate();
			
			If ReadyForProcessing_[ObjectStage] = Undefined Then
				ReadyForProcessing_.Insert(ObjectStage, New Array);
			EndIf;
			ReadyForProcessing_[ObjectStage].Add(NewRow);
			
			RowsArray.Add(NewRow.GetID());
			
		EndDo;
		
	EndDo;
	
	For Each ReadyForProcessing In ReadyForProcessing_ Do
		
		StructureOfActions.Insert(
			"FillInPurposeOfProvisionInProductionPhase",
			ReadyForProcessing.Key.ParametersForFillingAssignments);
			
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			ReadyForProcessing.Value,
			StructureOfActions,
			Object.SupplyWithMaterialsAndWorks,
			CachedValues);
			
	EndDo;
	
	AfterChangingTSStringsProgrammaticallyOnServer(TSName, RowsArray, StructureOfActions);
	
EndProcedure

&AtServer
Function PlaceMaterialsForSelectionAccordingToSpecificationInRepository()
	
	Table = Object.SupplyWithMaterialsAndWorks.Unload(, "Stage,Products,Characteristic,NumberOfPackages,Package");
	
	Return PutToTempStorage(Table, UUID);
	
EndFunction

#EndRegion

#Region Other

#Region ConditionalAppearance

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	SetConditionalDesignStages();
	SetConditionalAppearanceOfFinishedProduct();
	InstallConditionalAppearanceSoftware();
	EstablishConditionalAppearanceConsumptionOfMaterialsAndWorks();
	SetConditionalAppearanceOfBuildingMaterials();
	EstablishConditionalAppearanceOfLaborCosts();
	
EndProcedure

&AtServer
Procedure SetConditionalDesignStages()
	
	// For previously created documents, only the details "Stage number", "Next stage number" are available for editing.
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.StagesNameEdit.Name);
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.StagesDepartment.Name);
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.StagesStatus.Name);
	
	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Stages.IsNew");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Stages.ReadOnly");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// Combining the statuses <Formed> and <Formed>
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.StagesStatus.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Stages.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.StatusesOfProductionStages2_2.Generated1;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TheGeneratingStatusIsUsed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Đã lập / đang lập';
													|ru = 'Сформирован / Формируется';
													|en = 'Active / Created'; fa = 'Active / Created';
													|it = 'Generato / In generazione';
													|pl = 'Sformowany / Formuje się';
													|tr = 'Oluşturuldu / Düzenleniyor'"));
	
	// We support the "Use operational management" setting
	
	Item = ConditionalAppearance.Items.Add();

	Item.Fields.Items.Add().Field = New DataCompositionField(Items.StagesRouteSheet.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Stages.UseOperationManagement");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
													|ru = '<не используется>';
													|en = '<not used>'; fa = '<استفاده نمی‌شود>';
													|it = '<non viene utilizzato>';
													|pl = '<nie używa się>';
													|tr = '<kullanılmayan>'"));
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.StagesRouteSheetFactor.Name);
	
	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Stages.UseOperationManagement");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Stages.TechnologicalProcess");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.StagesRouteSheetFactor.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Stages.TechnologicalProcess");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Enabled", False);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.StagesRouteSheet.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Stages.TechnologicalProcessType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TechnologicalProcessTypesOfStage.Individual_;
	
	Item.Appearance.SetParameterValue("Enabled", False);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
													|ru = '<не используется>';
													|en = '<not used>'; fa = '<استفاده نمی‌شود>';
													|it = '<non viene utilizzato>';
													|pl = '<nie używa się>';
													|tr = '<kullanılmayan>'"));
	
	//
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "StagesMainProductProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.Stages.PackagePlan";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);
	
	// View only 
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Stages.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Stages.ReadOnly");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.GrayTextColor2);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceOfFinishedProduct()
	
	#Region ManufacturedProducts
	
	DataPaths = New Structure;
	DataPaths.Insert("BusinessOperation",                      "Object.BusinessOperation");
	DataPaths.Insert("Status",                                     "Object.ManufacturedProducts.Status");
	DataPaths.Insert("Department",                              "Object.ManufacturedProducts.Department");
	DataPaths.Insert("MethodOfAllocatingFinishedProductCosts", "MethodOfAllocatingFinishedProductCosts");
	DataPaths.Insert("ProductionByThirdParty2_5",                   "Object.ManufacturedProducts.ProductionByThirdParty2_5");
	DataPaths.Insert("LeaveProductsAtSubcontractor",              "Object.ManufacturedProducts.LeaveProductsAtSubcontractor");
	
	ItemNamesOutputItems = New Structure;
	ItemNamesOutputItems.Insert("ProductsUnitOfMeasure", Items.ManufacturedProductsProductsUnitOfMeasure.Name);
	ItemNamesOutputItems.Insert("Characteristic", Items.ManufacturedProductsCharacteristic.Name);
	ItemNamesOutputItems.Insert("Series", Items.ManufacturedProductsSeries.Name);
	ItemNamesOutputItems.Insert("BatchesIndicationStatus", Items.ManufacturedProductsBatchesIndicationStatus.Name);
	ItemNamesOutputItems.Insert("Purpose", Items.ManufacturedProductsPurpose.Name);
	ItemNamesOutputItems.Insert("ProductionDate", Items.ManufacturedProductsProductionDate.Name);
	ItemNamesOutputItems.Insert("DirectionOfProductionIssue", Items.ManufacturedProductsDirectionOfProductionIssue.Name);
	ItemNamesOutputItems.Insert("ExpenseItem", Items.ManufacturedProductsExpenseItem.Name);
	ItemNamesOutputItems.Insert("DimensionOfExpenses", Items.ManufacturedProductsDimensionOfExpenses.Name);
	ItemNamesOutputItems.Insert("AssetsLiabilitiesDimension", Items.ManufacturedProductsAssetsLiabilitiesDimension.Name);
	ItemNamesOutputItems.Insert("TransactionRecordingPresentation", Items.ManufacturedProductsTransactionRecordingPresentation.Name);
	ItemNamesOutputItems.Insert("Manufactured", Items.ManufacturedProductsManufactured.Name);
	ItemNamesOutputItems.Insert("Recipient", Items.ManufacturedProductsRecipient.Name);
	ItemNamesOutputItems.Insert("NumberOfPackages", Items.ManufacturedProductsNumberOfPackages.Name);
	ItemNamesOutputItems.Insert("Canceled", Items.ManufacturedProductsCanceled.Name);
	ItemNamesOutputItems.Insert("CancellationReason", Items.ManufacturedProductsCancellationReason.Name);
	ItemNamesOutputItems.Insert("BillOfMaterials", Items.ManufacturedProductsBillOfMaterials.Name);
	ItemNamesOutputItems.Insert("ProcessByBOM", Items.ManufacturedProductsProcessByBOM.Name);
	
	ProductionManagement.EstablishConditionalAppearanceOfOutputProductsOfProductionStage(
		ThisForm, "Object", "ManufacturedProducts", ItemNamesOutputItems, DataPaths);
	
	ProductionManagement.EstablishConditionalAppearanceOfDestinationOfOutputProductsOfProductionStage(
		ThisForm, DataPaths);
	
	ProductionServer.SetConditionalAppearanceOfShareCostPercentageField(
		ThisForm, "Object", "ManufacturedProducts",, DataPaths);
	
	ProductionServer.SetConditionalAppearanceOfShareOfCostOfCanceledRowsField(
		ThisObject, "Object", "ManufacturedProducts");
	
	ProductionManagement.SetConditionalAppearanceOfStageConsumerOfSemiFinishedProductField(
		ThisForm, "Object", "ManufacturedProducts",, DataPaths);
	
	
	SetConditionalAppearanceOfProductionDateField("ManufacturedProducts");
	
	SetConditionalAppearanceOfFieldMade("ManufacturedProducts");
	
	SetConditionalAppearanceServiceDataOfTableParts("ManufacturedProducts");
	
	#Region TargetCost
	
	// Visibility of planned cost fields.
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ManufacturedProductsPrice.Name);
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ManufacturedProductsSum.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseTargetCost");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	#EndRegion

	#EndRegion
	
	#Region SideAndIntermediateRelease
	DataPaths = New Structure;
	DataPaths.Insert("BusinessOperation",         "Object.BusinessOperation");
	DataPaths.Insert("Status",                        "Object.SideAndIntermediateRelease.Status");
	DataPaths.Insert("Department",                 "Object.SideAndIntermediateRelease.Department");
	DataPaths.Insert("PriceKind",                       "Object.SideAndIntermediateRelease.PriceKind");
	DataPaths.Insert("ProductionByThirdParty",         "Object.SideAndIntermediateRelease.ProductionByThirdParty");
	DataPaths.Insert("ProductionByThirdParty2_5",      "Object.SideAndIntermediateRelease.ProductionByThirdParty2_5");
	DataPaths.Insert("LeaveProductsAtSubcontractor", "Object.SideAndIntermediateRelease.LeaveProductsAtSubcontractor");
	DataPaths.Insert("Organization",                   "Object.SideAndIntermediateRelease.Organization");
	DataPaths.Insert("MaterialProviderCompany",            "Object.SideAndIntermediateRelease.MaterialProviderCompany");
	DataPaths.Insert("TextOwnerGiver",          "Object.SideAndIntermediateRelease.TextOwnerGiver");
	DataPaths.Insert("TextOwnerProcessor",     "Object.SideAndIntermediateRelease.TextOwnerProcessor");
	
	ItemNamesByProducts = New Structure;
	ItemNamesByProducts.Insert("ProductsUnitOfMeasure", Items.SideAndIntermediateReleaseProductsUnitOfMeasure.Name);
	ItemNamesByProducts.Insert("Characteristic", Items.SideAndIntermediateReleaseCharacteristic.Name);
	ItemNamesByProducts.Insert("Series", Items.SideAndIntermediateReleaseSeries.Name);
	ItemNamesByProducts.Insert("BatchesIndicationStatus", Items.SideAndIntermediateReleaseBatchesIndicationStatus.Name);
	ItemNamesByProducts.Insert("Purpose", Items.SideAndIntermediateReleasePurpose.Name);
	ItemNamesByProducts.Insert("ProductionDate", Items.SideAndIntermediateReleaseProductionDate.Name);
	ItemNamesByProducts.Insert("DirectionOfProductionIssue", Items.SideAndIntermediateReleaseDirectionOfProductionIssue.Name);
	ItemNamesByProducts.Insert("ExpenseItem", Items.SideAndIntermediateReleaseExpenseItem.Name);
	ItemNamesByProducts.Insert("DimensionOfExpenses", Items.SideAndIntermediateReleaseDimensionOfExpenses.Name);
	ItemNamesByProducts.Insert("AssetsLiabilitiesDimension", Items.SideAndIntermediateReleaseAssetsLiabilitiesDimension.Name);
	ItemNamesByProducts.Insert("TransactionRecordingPresentation", Items.SideAndIntermediateReleaseTransactionRecordingPresentation.Name);
	ItemNamesByProducts.Insert("Manufactured", Items.SideAndIntermediateReleaseManufactured.Name);
	ItemNamesByProducts.Insert("Recipient", Items.SideAndIntermediateReleaseRecipient.Name);
	ItemNamesByProducts.Insert("NumberOfPackages", Items.SideAndIntermediateReleaseNumberOfPackages.Name);
	ItemNamesByProducts.Insert("Canceled", Items.SideAndIntermediateReleaseCanceled.Name);
	ItemNamesByProducts.Insert("CancellationReason", Items.SideAndIntermediateReleaseCancellationReason.Name);
	ItemNamesByProducts.Insert("BillOfMaterials", Items.SideAndIntermediateReleaseBillOfMaterials.Name);
	ItemNamesByProducts.Insert("ProcessByBOM", Items.SideAndIntermediateReleaseProcessByBOM.Name);
	ItemNamesByProducts.Insert("ProductOwner", Items.SideAndIntermediateReleaseProductOwner.Name);
	
	ProductionManagement.EstablishConditionalAppearanceOfOutputProductsOfProductionStage(
		ThisForm, "Object", "SideAndIntermediateRelease", ItemNamesByProducts, DataPaths);
	
	ProductionManagement.EstablishConditionalAppearanceOfAppointmentOfByProductsOfProductionStage(
		ThisForm, DataPaths);
	
	ProductionFormManagement.SetConditionalAppearanceOfCalculationArticle(
		ThisForm, "Object", "SideAndIntermediateRelease", "SideAndIntermediateReleaseProductCostElement", DataPaths, True);
	
	ProductionManagement.EstablishConditionalAppearanceOfFixedCostOfProductionStage(
		ThisForm, "Object", "SideAndIntermediateRelease",, DataPaths);
		
	ProductionManagement.SetConditionalAppearanceOfStageConsumerOfSemiFinishedProductField(
		ThisForm, "Object", "SideAndIntermediateRelease",, DataPaths);
	
	
	#Region InternalSubcontracting
	
	InternalSubcontractingServer.SetConditionalAppearanceOfProductOwnerField(
		ThisObject,
		"Object",
		"SideAndIntermediateRelease",
		ItemNamesByProducts,
		DataPaths);
	
	// Setting the availability of the "Product Owner" column of a specific stage
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SideAndIntermediateReleaseProductOwner.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SideAndIntermediateRelease.InternalSubcontracting");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly",        True);
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text",                 NStr("vi = '<đối với các công đoạn gia công nội bộ>';
																						|ru = '<для этапов внутренней переработки>';
																						|en = '<for internal subcontracting stages>'; fa = '<for internal subcontracting stages>';
																						|it = '<для этапов внутренней переработки>';
																						|pl = '<for internal subcontracting stages>';
																						|tr = '<dahili geri dönüşüm aşamaları için>'"));
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor",            StyleColors.InaccessibleCellTextColor);
	
	#EndRegion
	
	SetConditionalAppearanceOfProductionDateField("SideAndIntermediateRelease");
	
	SetConditionalAppearanceOfFieldMade("SideAndIntermediateRelease");
	
	SetConditionalAppearanceServiceDataOfTableParts("SideAndIntermediateRelease");
	
	#EndRegion
	
EndProcedure

&AtServer
Procedure InstallConditionalAppearanceSoftware()
	
	DataPaths = New Structure;
	DataPaths.Insert("Status",                   "Object.SupplyWithMaterialsAndWorks.Status");
	DataPaths.Insert("ProductionByThirdParty",    "Object.SupplyWithMaterialsAndWorks.ProductionByThirdParty");
	DataPaths.Insert("ProductionByThirdParty2_5", "Object.SupplyWithMaterialsAndWorks.ProductionByThirdParty2_5");
	DataPaths.Insert("WorkPlanning",        "Object.SupplyWithMaterialsAndWorks.WorkPlanning");
	
	ItemsNames = ProductionFormManagement.NamesOfMaterialAndWorkSupportElements();
	ItemsNames.TSName = Items.SupplyWithMaterialsAndWorks.Name;
	ItemsNames.DateOfShipment = "DateOfShipment";
	ItemsNames.TSDateOfShipment = Items.SupplyWithMaterialsAndWorksDateOfShipment.Name;
	ItemsNames.TSNumberOfPackages = Items.SupplyWithMaterialsAndWorksNumberOfPackages.Name;
	ItemsNames.TSProductsUnitOfMeasure = Items.SupplyWithMaterialsAndWorksProductsUnitOfMeasure.Name;
	ItemsNames.TSWithAssignment = Items.SupplyWithMaterialsAndWorksWithAssignment.Name;
	ItemsNames.TSCanceled = Items.SupplyWithMaterialsAndWorksCanceled.Name;
	ItemsNames.TSCancellationReason = Items.SupplyWithMaterialsAndWorksCancellationReason.Name;
	ItemsNames.TSSeries = Items.SupplyWithMaterialsAndWorksSeries.Name;
	ItemsNames.TSWarehouse = Items.SupplyWithMaterialsAndWorksWarehouse.Name;
	ItemsNames.TSBillOfMaterials = Items.SupplyWithMaterialsAndWorksBillOfMaterials.Name;
	ItemsNames.TSProductCostElement = Items.SupplyWithMaterialsAndWorksProductCostElement.Name;
	ItemsNames.TSCharacteristic = Items.SupplyWithMaterialsAndWorksCharacteristic.Name;
	ItemsNames.TSPurpose = Items.SupplyWithMaterialsAndWorksSupplyAssignmentEditing.Name;
	ItemsNames.TSProduced = Items.SupplyWithMaterialsAndWorksProduced.Name;
	ItemsNames.TSUnderRepairProduct = Items.SupplyWithMaterialsAndWorksUnderRepairProduct.Name;
	ItemsNames.TSUnderRepairVariant = Items.SupplyWithMaterialsAndWorksUnderRepairVariant.Name;
	ItemsNames.TSUnderRepairBatch = Items.SupplyWithMaterialsAndWorksUnderRepairBatch.Name;
	
	ProductionFormManagement.EstablishConditionalAppearanceOfProvisionOfMaterialsAndWorks(
		ThisForm, "Object", "SupplyWithMaterialsAndWorks", ItemsNames, DataPaths);
	
	ProductionFormManagement.SetConditionalAppearanceOfSecurityFields(
		ThisForm, "Object", "SupplyWithMaterialsAndWorks", DataPaths);
	
	ProductionFormManagement.EstablishConditionalAppearanceOfShipmentDate(
		ThisForm, "Object", "SupplyWithMaterialsAndWorks");
	
	SetConditionalAppearanceServiceDataOfTableParts("SupplyWithMaterialsAndWorks");
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SupplyWithMaterialsAndWorksSupplyAssignmentEditing.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SupplyWithMaterialsAndWorks.Ref");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<hãy chọn công đoạn>';
													|ru = '<выберите этап>';
													|en = '<select a step>'; fa = '<select a step>';
													|it = '<выберите этап>';
													|pl = '<select a step>';
													|tr = '<aşama seçin>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// Blank mark at the Bill of Materials
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SupplyWithMaterialsAndWorksBillOfMaterials.Name);
	
	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SupplyWithMaterialsAndWorks.WorkPlanning");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SupplyWithMaterialsAndWorks.Produced");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SupplyWithMaterialsAndWorks.Canceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// No editing in the bill of Materials
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SupplyWithMaterialsAndWorksBillOfMaterials.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SupplyWithMaterialsAndWorks.WorkPlanning");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SupplyWithMaterialsAndWorks.Produced");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chỉ định cho công việc được sản xuất>';
													|ru = '<указывается для производимых работ>';
													|en = '<specified for works performed>'; fa = '<specified for works performed>';
													|it = '<specified for works performed>';
													|pl = '<specified for works performed>';
													|tr = '<yapılan iş için belirtilir>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	// Additional blocking of the "Warehouse" field while the work has not yet been selected
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SupplyWithMaterialsAndWorksWarehouse.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SupplyWithMaterialsAndWorks.WorkPlanning");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// In the repair process Bill of Materials is available only for the Planning Stages of work
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SupplyWithMaterialsAndWorksBillOfMaterials.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SupplyWithMaterialsAndWorksProduced.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ProductionProcessType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ProductionProcessTypes.PerformRM;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SupplyWithMaterialsAndWorks.WorkPlanning");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
													|ru = '<не используется>';
													|en = '<not used>'; fa = '<استفاده نمی‌شود>';
													|it = '<non viene utilizzato>';
													|pl = '<nie używa się>';
													|tr = '<kullanılmayan>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
EndProcedure

&AtServer
Procedure EstablishConditionalAppearanceConsumptionOfMaterialsAndWorks()
	
	DataPaths = New Structure;
	DataPaths.Insert("Status", "Object.MaterialsAndWorksConsumption.Status");

	ItemsNames = ProductionManagement.NamesOfElementsConsumptionOfMaterialsAndWorksOfProductionStage();
	ItemsNames.ProductsUnitOfMeasure = Items.MaterialsAndWorksConsumptionProductsUnitOfMeasure.Name;
	ItemsNames.Characteristic               = Items.MaterialsAndWorksConsumptionCharacteristic.Name;
	ItemsNames.Series                        = Items.MaterialsAndWorksConsumptionSeries.Name;
	ItemsNames.ProductCostElement            = Items.MaterialsAndWorksConsumptionProductCostElement.Name;

	ProductionManagement.EstablishConditionalAppearanceOfConsumptionOfMaterialsAndWorksOfProductionStage(
		ThisForm, "Object", "MaterialsAndWorksConsumption", ItemsNames, DataPaths);
	
	SetConditionalAppearanceServiceDataOfTableParts("MaterialsAndWorksConsumption");

EndProcedure

&AtServer
Procedure SetConditionalAppearanceOfBuildingMaterials()
	
	DataPaths = New Structure;
	DataPaths.Insert("Status",        "Object.UnusedMaterials.Status");
	DataPaths.Insert("Department", "Object.UnusedMaterials.Department");
	
	ProductionManagement.EstablishConditionalAppearanceForMaterialsOfProductionStage(
		ThisForm, "Object", DataPaths);
		
	SetConditionalAppearanceServiceDataOfTableParts("UnusedMaterials");
	
EndProcedure

&AtServer
Procedure EstablishConditionalAppearanceOfLaborCosts()
	
	DataPaths = New Structure;
	DataPaths.Insert("Status", "Object.SupplyWithMaterialsAndWorks.Status");
	
	ProductionManagement.EstablishConditionalAppearanceOfLaborCosts(ThisForm, "Object", "LaborCosts",, DataPaths);
	
	SetConditionalAppearanceServiceDataOfTableParts("LaborCosts");
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceServiceDataOfTableParts(TSName)

	// representation of the reference
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ElementNames(TSName).LinkEdit);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object." + TSName + ".Ref");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object." + TSName + ".StageName");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '...';
													|ru = '...';
													|en = '...'; fa = '...';
													|it = '...';
													|pl = '...';
													|tr = '...'"));
	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	// View only
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items[TSName]["Name"]);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object." + TSName + ".ReadOnly");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.GrayTextColor2);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceOfProductionDateField(TSName)
	
	// View only, Text
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ElementNames(TSName).ProductionDate);
	
	ItemFilter =  Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object." + TSName + ".Canceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Không bắt buộc>';
													|ru = '<не требуется>';
													|en = '<not required>'; fa = '<الزامی نیست>';
													|it = '<non richiesto>';
													|pl = '<nie jest wymagane>';
													|tr = '<gerekli değil>'"));
	
	//Own production - View only, Text
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ElementNames(TSName).ProductionDate);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object." + TSName + ".Canceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object." + TSName + ".ProductionByThirdParty");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	StatusesList = New ValueList;
	StatusesList.Add(Enums.StatusesOfProductionStages2_2.EmptyRef());
	StatusesList.Add(Enums.StatusesOfProductionStages2_2.Initiated);
	StatusesList.Add(Enums.StatusesOfProductionStages2_2.Completed);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object." + TSName + ".Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = StatusesList;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Không bắt buộc>';
													|ru = '<не требуется>';
													|en = '<not required>'; fa = '<الزامی نیست>';
													|it = '<non richiesto>';
													|pl = '<nie jest wymagane>';
													|tr = '<gerekli değil>'"));
	
	
	//Production on the side (the order to the processor is not filled) - View only, Text
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ElementNames(TSName).ProductionDate);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object." + TSName + ".Canceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object." + TSName + ".ProductionByThirdParty");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object." + TSName + ".ReadOnly");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Không bắt buộc>';
													|ru = '<не требуется>';
													|en = '<not required>'; fa = '<الزامی نیست>';
													|it = '<non richiesto>';
													|pl = '<nie jest wymagane>';
													|tr = '<gerekli değil>'"));
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceOfFieldMade(TSName)
	
	//Production on the side (the order to the processor is not filled) - View only
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ElementNames(TSName).Manufactured);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object." + TSName + ".Canceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object." + TSName + ".ProductionByThirdParty");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object." + TSName + ".ReadOnly");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

&AtServer
Function ElementNames(TSName)
	
	ReturnStructure = New Structure("Manufactured, ProductionDate, LinkEdit");
	
	If TSName = "ManufacturedProducts" Then
		ReturnStructure.Manufactured = Items.ManufacturedProductsManufactured.Name;
		ReturnStructure.ProductionDate = Items.ManufacturedProductsProductionDate.Name;
		ReturnStructure.LinkEdit = Items.TheOutputProductsIsTheLinkToTheEdit.Name;
	ElsIf TSName = "SideAndIntermediateRelease" Then
		ReturnStructure.Manufactured = Items.SideAndIntermediateReleaseManufactured.Name;
		ReturnStructure.ProductionDate = Items.SideAndIntermediateReleaseProductionDate.Name;
		ReturnStructure.LinkEdit = Items.SideOfTheProductLinkTheEdit.Name;
	ElsIf TSName = "LaborCosts" Then
		ReturnStructure.LinkEdit = Items.LaborCostsLinkEdit.Name;
	ElsIf TSName = "UnusedMaterials" Then
		ReturnStructure.LinkEdit = Items.SaveMaterialsLinkEdit.Name;
	ElsIf TSName = "MaterialsAndWorksConsumption" Then
		ReturnStructure.LinkEdit = Items.ConsumptionOfMaterialsAndWorksLinkEdit.Name;
	ElsIf TSName = "SupplyWithMaterialsAndWorks" Then
		ReturnStructure.LinkEdit = Items.ProvidingMaterialsAndWorksLinkEditing.Name;
	EndIf;
	
	Return ReturnStructure;
	
EndFunction

#EndRegion

&AtServer
Procedure CustomizeFormElements()
	
	SideProductsAreCollapsed = (Object.SideAndIntermediateRelease.Count() = 0);
	
	SetPropertiesOfCollapsibleGroup(
		Items.SideAndIntermediateRelease, 
		Items.HyperLinkLabelSideProducts, 
		SideProductsAreCollapsed);
	
	UnspentMaterialsAreCollapsed = True;
	
	SetPropertiesOfCollapsibleGroup(
		Items.UnusedMaterials, 
		Items.HyperLinkLabelPSavingMaterials,
		UnspentMaterialsAreCollapsed);
	
	#Region Stages
	
	Items.StagesProductionByThirdParty.Format = StrTemplate("BF=; BT='%1'", NStr("vi = 'sản xuất cho bên khác';
																				|ru = 'производство на стороне';
																				|en = 'production by third party'; fa = 'production by third party';
																				|it = 'produzione esterna';
																				|pl = 'produkcja postronna';
																				|tr = 'fason üretim'"));
	Items.StagesInternalSubcontracting.Format = StrTemplate("BF=; BT='%1'", NStr("vi = 'gia công nội bộ';
																				|ru = 'внутренняя переработка';
																				|en = 'internal subcontracting'; fa = 'internal subcontracting';
																				|it = 'внутренняя переработка';
																				|pl = 'internal subcontracting';
																				|tr = 'dahili geri dönüşüm'"));
	
	RowFilter = New FixedStructure(New Structure("DeletionMark", False));
	Items.Stages.RowFilter = RowFilter;
	
	#EndRegion
	
	If Object.ProductionProcessType = Enums.ProductionProcessTypes.WithoutBillsOfMaterials Then
		Items.StagesNumberOfPackagesPlan.Visible = False;
		Items.StagesGroupUOM.Visible = False;
	ElsIf Object.ProductionProcessType = Enums.ProductionProcessTypes.PerformRM Then
		RowFilter = New FixedStructure(New Structure("WorkPlanning", False));
		Items.MaterialsAndWorksConsumption.RowFilter = RowFilter;
		Items.StagesWorkPlanning.Visible = True;
		Items.StagesGroupAdd.Visible = True;
		Items.StagesAdd.Visible = False;
		Items.SupplyWithMaterialsAndWorksProduced.Title = NStr("vi = 'Sản xuất';
																|ru = 'Произвести';
																|en = 'Produce'; fa = 'تولید';
																|it = 'Produce';
																|pl = 'Produce';
																|tr = 'Üret'");
	EndIf;
	
	If Object.ProductionProcessType = Enums.ProductionProcessTypes.Disassembly Then;
		TheStructureOfTheSearch = New Structure("ProcessByBOM", True);
		Items.OutputProductsGroupSpecification.Visible =
			Object.ManufacturedProducts.FindRows(TheStructureOfTheSearch).Count() Or Not DynamicStructureOfProductionOrders;
		Items.SideProductsGroupBOM.Visible =
			Object.SideAndIntermediateRelease.FindRows(TheStructureOfTheSearch).Count() Or Not DynamicStructureOfProductionOrders;
	Else
		Items.OutputProductsGroupSpecification.Visible = False;
		Items.SideProductsGroupBOM.Visible = False;
	EndIf;
	
	LabelSpecification = FormattedStringSpecificationStage();
	
	Items.ProvisionOfMaterialsAndWorksAnalogsGroup.Visible = RightToReadSubstitutes;
	
	If Object.BillOfMaterials.IsEmpty() Then
		Items.SecurityShowStandards.Visible = False;
		Items.SoftwareFillInAccordingToSpecification.Visible = False;
		Items.SoftwareToChooseAccordingToSpecification.Visible = False;
		Items.LaborCostsShowStandards.Visible = False;
		Items.LaborCostsFillInAccordingToTheSpecification.Visible = False;
	EndIf;
	
	If Not AccessRight("Update", Metadata.Documents.ProductionStage2_2) Then
		Items.Write.Enabled = False;
	EndIf;
	
	Items.SupplyWithMaterialsAndWorksIncludedInSet.Visible = UseOfKitsInProductionIsAvailable;
	
	Items.SupplyWithMaterialsAndWorksProduced.Visible = 
		Object.ProductionProcessType <> Enums.ProductionProcessTypes.WithoutBillsOfMaterials
		And Not Object.DynamicStructure
		Or Object.ProductionProcessType = Enums.ProductionProcessTypes.PerformRM;
	Items.ProvisionOfMaterialsAndWorksShouldBeReservedAsSoonAsTheyAreReceived.Visible = Not Object.DynamicStructure;
	Items.ProvisionOfMaterialsAndWorksToReserveContextMenuAsTheyBecomeAvailable.Visible = Not Object.DynamicStructure;
	Items.SupplyWithMaterialsAndWorksBillOfMaterials.Visible =
		Object.ProductionProcessType = Enums.ProductionProcessTypes.Assembly
		Or Object.ProductionProcessType = Enums.ProductionProcessTypes.PerformRM
		Or Object.ProductionProcessType <> Enums.ProductionProcessTypes.WithoutBillsOfMaterials
			And Not Object.DynamicStructure;
	
	// Visibility Of The FinishedProduct Being Repaired
	Items.SupplyOfMaterialsAndWorksGroupRepairedFINISHEDProduct.Visible =
		Object.ProductionProcessType = Enums.ProductionProcessTypes.PerformRM;
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Object = Form.Object;
	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	ProductionLot = Form.Parameters.ProductionLot;
	ProductionProcessType = Object.ProductionProcessType;
	
	// The header of the form
	#Region FormCaption
	If AttributesStructure1.Property("ProductionProcessType")
		Or AttributesStructure1.Property("ProductionLot")
		Or Initialize Then
		
		If Not ValueIsFilled(ProductionLot) Then
			TitleText = StrTemplate(NStr("vi = 'Tạo các công đoạn sản xuất (%1)';
										|ru = 'Создание этапов производства (%1)';
										|en = 'Create production stages (%1)'; fa = 'Create production stages (%1)';
										|it = 'Generazione delle fasi di produzione (%1)';
										|pl = 'Tworzenie etapów produkcji (%1)';
										|tr = 'Üretim aşamaları oluştur (%1)'"), Lower(ProductionProcessType));
		Else
			TitleText = StrTemplate(NStr("vi = 'Chỉnh sửa các bước sản xuất (%1)';
										|ru = 'Редактирование этапов производства (%1)';
										|en = 'Edit production stages (%1)'; fa = 'Edit production stages (%1)';
										|it = 'Modifica delle fasi di produzione (%1)';
										|pl = 'Edycja etapów produkcji (%1)';
										|tr = 'Üretim aşamalarının düzenlenmesi (%1)'"), Lower(ProductionProcessType));
		EndIf;
	
		Form.AutoTitle = False;
		Form.Title = TitleText;
		
	EndIf;
	#EndRegion
	
	// Main product
	#Region MainProduct
	
	If AttributesStructure1.Property("ProductionProcessType")
		Or Initialize Then
		
		If (Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.Assembly")
				Or Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.WithoutBillsOfMaterials")) Then
			Items.GroupMainProduct.Title = NStr("vi = 'Sản phẩm';
												|ru = 'Продукция';
												|en = 'Manufactured products'; fa = 'محصولات تولیدی';
												|it = 'Prodotti';
												|pl = 'Wiersze pozycji';
												|tr = 'İmal edilen ürünler'");
		ElsIf Object.ProductionProcessType =PredefinedValue("Enum.ProductionProcessTypes.Repair") Then
			Items.GroupMainProduct.Title = NStr("vi = 'Sản phẩm được sửa chữa';
												|ru = 'Ремонтируемое изделие';
												|en = 'Product under R&M'; fa = 'محصول تحت تعمیر و نگهداری';
												|it = 'Prodotto in fase di riparazione';
												|pl = 'Remontowany wyrób';
												|tr = 'Onarılan nihai ürün'");
		ElsIf Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.Disassembly") Then
			Items.GroupMainProduct.Title = NStr("vi = 'Sản phẩm tháo rời';
												|ru = 'Разбираемое изделие';
												|en = 'Product being disassembled'; fa = 'Product being disassembled';
												|it = 'Prodotto in fase di smontaggio';
												|pl = 'Demontowany wyrób';
												|tr = 'Sökülen nihai ürün'");
		ElsIf Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.PerformRM") Then
			Items.GroupMainProduct.Title = NStr("vi = 'Công việc được thực hiện';
												|ru = 'Выполняемая работа';
												|en = 'Work to perform'; fa = 'کار قابل انجام';
												|it = 'Work to perform';
												|pl = 'Work to perform';
												|tr = 'Yapılan iş'");
		EndIf;
		
		Items.GroupRepairedFinishedProduct.Visible = 
			Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.PerformRM");
		
	EndIf;
	
	If AttributesStructure1.Property("ProductionProcessType")
		Or AttributesStructure1.Property("ManufacturedProducts")
		Or AttributesStructure1.Property("SupplyWithMaterialsAndWorks")
		Or AttributesStructure1.Property("MainProduct")
		Or Initialize Then
		
		If Form.DataStructureMainProduct.ItemVariantsAreUsed Then
			Items.MainProductCharacteristic.Enabled = True;
			Items.MainProductCharacteristic.InputHint = "";
			Items.MainProductCharacteristic.AutoMarkIncomplete = True;
		Else
			Items.MainProductCharacteristic.Enabled = False;
			Items.MainProductCharacteristic.InputHint = NStr("vi = '<không sử dụng đặc tính>';
															|ru = '<характеристики не используются>';
															|en = '<variants are not used>'; fa = '<گونه‌ها استفاده نمی‌شوند>';
															|it = '<le caratteristiche non vengono usate>';
															|pl = '<charakterystyki nie dotyczą>';
															|tr = '<varyantlar kullanılmamaktadır>'");
			Items.MainProductCharacteristic.AutoMarkIncomplete = False;
		EndIf;
		
		Form.HelpTextMainProduct = Undefined;
		Items.DecorationPictureIsTheMainProduct.Visible = False;
		If ValueIsFilled(Object.MainProductProducts) Then
			If (ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.Assembly")
					Or ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.Repair")
					Or ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.WithoutBillsOfMaterials")
				) Then
				Items.DecorationPictureIsTheMainProduct.Visible = ( Object.ManufacturedProducts.FindRows(New Structure("Products", Object.MainProductProducts)).Count() = 0 );
				Form.HelpTextMainProduct = New FormattedString(NStr("vi = 'chuyển đến xuất xưởng';
																	|ru = 'перейти к выпуску';
																	|en = 'go to release'; fa = 'go to release';
																	|it = 'passare all''emissione';
																	|pl = 'przejść do produkcji';
																	|tr = 'ürün çıkışına git'"),,,, "GoToRelease");
			ElsIf ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.Disassembly") Then
				Items.DecorationPictureIsTheMainProduct.Visible = ( Object.SupplyWithMaterialsAndWorks.FindRows(New Structure("Products", Object.MainProductProducts)).Count() = 0 );
				Form.HelpTextMainProduct = New FormattedString(NStr("vi = 'chuyển đến đảm bảo';
																	|ru = 'перейти к обеспечению';
																	|en = 'go to supply'; fa = 'go to supply';
																	|it = 'passare all''approvvigionamento';
																	|pl = 'przejdź do zaopatrzenia';
																	|tr = 'temine git'"),,,, "GoToSupply");
			EndIf;
		EndIf;
		
	EndIf;
	#EndRegion
	
	// The Finished Product being Repaired
	#Region FinishedProductBeingRepaired
	
	If AttributesStructure1.Property("UnderRepairProduct")
		Or Initialize Then
		
		If Form.FinishedProductBeingRepairedCharacteristicsAreUsed Then
			Items.UnderRepairVariant.Enabled = True;
			Items.UnderRepairVariant.InputHint = "";
			Items.UnderRepairVariant.AutoMarkIncomplete = True;
		Else
			Items.UnderRepairVariant.Enabled = False;
			Items.UnderRepairVariant.InputHint = NStr("vi = '<không sử dụng đặc tính>';
														|ru = '<характеристики не используются>';
														|en = '<variants are not used>'; fa = '<گونه‌ها استفاده نمی‌شوند>';
														|it = '<le caratteristiche non vengono usate>';
														|pl = '<charakterystyki nie dotyczą>';
														|tr = '<varyantlar kullanılmamaktadır>'");
			Items.UnderRepairVariant.AutoMarkIncomplete = False;
		EndIf;
		
	EndIf;
	
	#EndRegion
	
	// Output items
	#Region OutputProducts_ByProducts
	
	If AttributesStructure1.Property("ManufacturedProducts")
		Or AttributesStructure1.Property("SideAndIntermediateRelease") 
		Or Initialize Then
		
		Form.FinishedProductsQuantity = Form.Object.ManufacturedProducts.Count();
		Form.SideProductsQuantity = Form.Object.SideAndIntermediateRelease.Count();
		
		If AttributesStructure1.Property("ManufacturedProducts") Or Initialize Then
			If Form.FinishedProductsQuantity > 0 Then
				Form.LabelProducts = StrTemplate("%1 (%2)", Items.ManufacturedProducts.Title, Form.FinishedProductsQuantity);
			Else
				Form.LabelProducts = Items.ManufacturedProducts.Title;
			EndIf;
		EndIf;
		
		If AttributesStructure1.Property("SideAndIntermediateRelease") Or Initialize Then
			If Form.SideProductsQuantity > 0 Then
				Form.LabelSideProducts = StrTemplate("%1 (%2)", Items.SideAndIntermediateRelease.Title, Form.SideProductsQuantity);
			Else
				Form.LabelSideProducts = Items.SideAndIntermediateRelease.Title;
			EndIf;
		EndIf;
		
		Form.NumberOfLinesFinishedProducts = Form.FinishedProductsQuantity + Form.SideProductsQuantity;
		
	EndIf;
	
	#EndRegion
	
	// Provision, Expense, Economy
	#Region Provision_ConsumptionOfMaterialsAndWorks_SavingOfMaterials
	
	If AttributesStructure1.Property("MaterialsAndWorksConsumption")
		Or AttributesStructure1.Property("UnusedMaterials") 
		Or Initialize Then
		
		ConsumptionOfMaterialsAndWorksQuantity = Form.Object.MaterialsAndWorksConsumption.Count();
		SavingMaterialsQuantity = Form.Object.UnusedMaterials.Count();
		
		If AttributesStructure1.Property("MaterialsAndWorksConsumption") Or Initialize Then
			If ConsumptionOfMaterialsAndWorksQuantity > 0 Then
				Form.LabelConsumptionOfMaterialsAndWorks = StrTemplate("%1 (%2)", Items.MaterialsAndWorksConsumption.Title, ConsumptionOfMaterialsAndWorksQuantity);
			Else
				Form.LabelConsumptionOfMaterialsAndWorks = Items.MaterialsAndWorksConsumption.Title;
			EndIf;
		EndIf;
		
		If AttributesStructure1.Property("UnusedMaterials") Or Initialize Then
			If SavingMaterialsQuantity > 0 Then
				Form.LabelMaterialSaving = StrTemplate("%1 (%2)", Items.UnusedMaterials.Title, SavingMaterialsQuantity);
			Else
				Form.LabelMaterialSaving = Items.UnusedMaterials.Title;
			EndIf;
		EndIf;
		
		Form.NumberOfConsumptionLines = ConsumptionOfMaterialsAndWorksQuantity + SavingMaterialsQuantity;
		
	EndIf;
	
	#EndRegion
	
	// Standards
	#Region Standards
	If AttributesStructure1.Property("ShowStandards")
		Or Initialize Then
		
		Items.SupplyWithMaterialsAndWorksNormativeStandard.Visible = Form.ShowStandardsMaterials;
		Items.SecurityShowStandards.Check = Form.ShowStandardsMaterials;
		
		Items.LaborCostsNormativeStandard.Visible = Form.ShowStandardsLaborCosts;
		Items.LaborCostsShowStandards.Check = Form.ShowStandardsLaborCosts;
		
	EndIf;
	#EndRegion
	
	// Production process
	#Region ManufacturingProcess
	If AttributesStructure1.Property("ManufacturingProcess")
		Or Initialize Then
		
		Form.NumberOfLinesManufacturingProcess = Object.Stages.FindRows(New Structure("DeletionMark", False)).Count();
		
	EndIf;
	
	If AttributesStructure1.Property("UseOperationManagement")
		Or Initialize Then
		
		Items.StagesGroupRouteMap.Visible =
			Form.UseOperationManagement
			And Form.UseRouteSheets
			And Not Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.WithoutBillsOfMaterials");
		
	EndIf;
	
	#EndRegion
	
	// Substitutes
	#Region Substitutes
	
	If AttributesStructure1.Property("ShowAnalogues")
		Or Initialize Then
		
		Items.ProvisionShowAnalogues.Check = Form.ShowAnalogues;
		Items.SupplyWithMaterialsAndWorksThereAreSubstituteMaterials.Visible = Form.ShowAnalogues And Form.RightToReadSubstitutes;
		
	EndIf;
	
	// Commands that depend on the selected lines
	If AttributesStructure1.Property("ShowDependentCommands")
		Or Initialize Then
		
		WorkPlanning = WorkPlanningLinesAreHighlighted(Form, "SupplyWithMaterialsAndWorks");
		
		Items.SupplyFillInTheWarehouseInTheSelectedLines.Visible = Not WorkPlanning;
		Items.SoftwareToPickUpAnalogs.Visible = Not WorkPlanning;
		Items.ReplaceProvisionsWithAnalogues.Visible = Not WorkPlanning;
		Items.ProvisionOfMaterialsAndWorksReserve.Visible = Not WorkPlanning;
		Items.ProvisionOfMaterialsAndWorksContextMenuReserve.Visible = Not WorkPlanning;
		
	EndIf;
	
	#EndRegion
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElementsBasedOnChangedBankingDetails(Form, ChangedBankingDetails)

	If Not ValueIsFilled(ChangedBankingDetails)Then
		Return;
	EndIf;
	
	AttributesList = StrConcat(ChangedBankingDetails, ",");
	ConfigureDependentFormElements(Form, AttributesList);
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	UnlockDocuments();
	
	RightToReadSubstitutes = GetFunctionalOption("UseAlternativeMaterials")
						  And AccessRight("Read", Metadata.InformationRegisters.AlternativeMaterials);
	
	UseSeveralWarehouses = GetFunctionalOption("UseSeveralWarehouses");
	DefaultWarehouse = TMCommonUse.GetCheckWarehouseByDefault();
	
	FillInMethodOfAllocatingCostsForOutputProducts();
	
	StageEditingParameters = New FixedStructure(DataProcessors.EditProductionStageSequence.StageEditingParameters());
	CostAllocationParameters = New FixedStructure(DataProcessors.EditProductionStageSequence.CostAllocationParameters(MethodOfAllocatingFinishedProductCosts));
	
	UseRouteSheets = GetFunctionalOption("UseRouteSheets");
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, DataProcessors.EditProductionStageSequence));
	
	ReadData();
	
	SetSpecificationSelectionParameters();
	
	UseWriteOffForExpenses =
		(GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities")
			Or GetFunctionalOption("UseAccountingOfOtherIncomeExpenses"))
		And Object.BusinessOperation <> Enums.BusinessTransactions.TollManufacturing2_5;
	
	
	UseInternalSubcontracting = GetFunctionalOption("UseInternalSubcontracting");
	DynamicStructureOfProductionOrders = GetFunctionalOption("DynamicStructureOfProductionOrders");
	
	StorageAddressStandards = "";
	ProductionBatchData = Documents.ProductionStage2_2.ProductionBatchData(Object.ReferenceOrder, Object.AssignmentProducts, Object.ProductionLot);
	
	ItemsAndDimensionsSelectionParameters = DataProcessors.EditProductionStageSequence.ItemsAndDimensionsSelectionParameters(Object);
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	SetupParameters = DataProcessors.EditProductionStageSequence.AccountingAccountSettings_();
	GLAccountSettingsServer.OnReadAtServer(ThisObject, SetupParameters);
	
	ListOfOrderDetails = "EarliestStartDate,Department";
	FillPropertyValues(
		Object,
		Common.ObjectAttributesValues(Object.ReferenceOrder, ListOfOrderDetails),
		ListOfOrderDetails);
	
	FillInServiceDetails();
	ListOfOrders_ = New Array;
	ListOfOrders_.Add(Parameters.ReferenceOrder);
	ProductionManagement.UpdateAttributeYouNeedToFillInStageConsumerField(ThisForm, ListOfOrders_);
	
	If Object.BusinessOperation = Enums.BusinessTransactions.TollManufacturing2_5
		Or False Then
		PurposeOfTollRelease = Documents.ProductionStage2_2.DefaultAssignmentForByProducts(Object.ReferenceOrder);
	EndIf;
	
	EmbeddingParameters = DataProcessors.EditProductionStageSequence.AvailableRemainingEmbeddingOptions();
	ProvisionInDocumentsServer.AvailableBalancesWhenReadingOnServer(ThisObject, EmbeddingParameters);
	
	SetVisibilityOfSeriesElements();
	
	ProcessingOfTabularForms.InitializeRowCache(Items.ManufacturedProducts);
	ProcessingOfTabularForms.InitializeRowCache(Items.SideAndIntermediateRelease);
	ProcessingOfTabularForms.InitializeRowCache(Items.Stages);
	ProcessingOfTabularForms.InitializeRowCache(Items.SupplyWithMaterialsAndWorks);
	
	FillInAssignmentSelectionParameters();
	
	CustomizeFormElements();
	
EndProcedure

&AtServer
Procedure SetSpecificationSelectionParameters()
	
	BOMSelectionParameters = ProductDataManagement.BOMSelectionParameters(
		Object,
		DataProcessors.EditProductionStageSequence);
	
	ProductDataManagement.SetSpecificationSelectionParameters(
								Items.SupplyWithMaterialsAndWorksBillOfMaterials,
								BOMSelectionParameters.SupplyWithMaterialsAndWorks);
	
	ProductDataManagement.SetSpecificationSelectionParameters(
								Items.ManufacturedProductsBillOfMaterials,
								BOMSelectionParameters.ManufacturedProducts);
	
	ProductDataManagement.SetSpecificationSelectionParameters(
								Items.SideAndIntermediateReleaseBillOfMaterials,
								BOMSelectionParameters.ManufacturedProducts);

EndProcedure

&AtClientAtServerNoContext
Function TSSpecificationSelectionParameters(Form, TSName, RowData = Undefined)
	
	If TSName = "SupplyWithMaterialsAndWorks"
		And RowData <> Undefined
		And RowData.WorkPlanning Then
		
		Var_Key = "SupplyOfMaterialsAndWorks_WorkPlanning";
		
	Else
		
		Var_Key = TSName;
		
	EndIf;
	
	Return Form.BOMSelectionParameters[Var_Key];
	
EndFunction

&AtServer
Procedure FillInServiceDetails()
	
	NewStageDataStructure = ProductionManagement.DocumentDetailsProductionStage();
	NewStageDataStructure.Insert("ReadOnly", False);
	NewStageDataStructure.Insert("NameEdit", "");
	NewStageDataStructure.Insert("StageExecutionIsStarted", False);
	NewStageDataStructure.Insert("UseOperationManagement", False);
	NewStageDataStructure.Insert("UseTeamWorkOrders", False);
	NewStageDataStructure.Insert("StageIsCompleted", False);
	NewStageDataStructure.Insert("PlannedProductionDate", '00010101');
	NewStageDataStructure.Insert("ActualProductionDate", '00010101');
	NewStageDataStructure.Insert("ParametersForFillingAssignments", New Structure);
	NewStageDataStructure.Insert("AppointmentSelectionList", New ValueList);
	NewStageDataStructure.Insert("WorkPlanning", False);
	NewStageData = New FixedStructure(NewStageDataStructure);
	
	For Each String In Object.Stages Do
		
		If Not String.IsNew Then
			String.NameEdit = String.StageName;
		EndIf;
		
		If AccessManagement.ProductiveOption() Then
			StageEditingIsProhibited = Not AccessManagement.EditionAllowed(String.Ref);
		Else
			StageEditingIsProhibited = False;
		EndIf;
		
		String.MainProductProducts = Object.MainProductProducts;
		String.ReadOnly = String.ProductionByThirdParty And ValueIsFilled(String.SubcontractOrder) Or StageEditingIsProhibited;
		
		String.StageExecutionIsStarted = (String.Status = StatusStarted())
			Or (String.Status = StatusCompleted_1());
		String.StageIsCompleted = (String.Status = StatusCompleted_1());
		
		If String.StageIsCompleted Then
			String.ActualProductionDate = BegOfDay(String.ActualStageEnd);
		Else
			String.ActualProductionDate = Undefined;
		EndIf;
		String.PlannedProductionDate = Documents.ProductionStage2_2.PlannedDateOfReceipt(String.Ref);

		String.PictureIndex = PictureIndex(String);
		
	EndDo;
	
	UseOfKitsInProductionIsAvailable = ProductDataManagementCached.UseOfKitsInProductionIsAvailable();
	
	FillInDataStructureOfMainProduct();
	FillInServiceDetailsOfTableParts();
	FillInParametersOfProductionUnits();
	
	FinishedProductBeingRepairedCharacteristicsAreUsed = Catalogs.Products.ItemVariantsAreUsed(
		Object.UnderRepairProduct);
	
	CreateLinksOfNewDocuments();
	FillInDefaultLink();
	
	CacheQualityControl = QualityControl.DataCacheOfMechanism(Object, DataProcessors.EditProductionStageSequence);
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsOfTableParts(ListOfTS = "", FillInLines = Undefined)
	
	StructureOfTS = New Structure(ListOfTS);
	AllTS = (StructureOfTS.Count() = 0);
	
	If AllTS Or Not ValueIsFilled(FillInLines) Then
		StageData_1 = DataIsBroughtIntoCompliance();
	Else
		StageData_1 = Undefined;
	EndIf;
	
	If StructureOfTS.Property("ManufacturedProducts") Or AllTS Then
		FillInServiceDetailsAccordingToStages("ManufacturedProducts", FillInLines, StageData_1);
		ProductionManagement.FillInServiceDetailsOfOutputProductsOfProductionStage(Object.ManufacturedProducts, FillInLines);
		ProductionManagement.FillInWHReleaseDirection(?(FillInLines <> Undefined, FillInLines, Object.ManufacturedProducts));
		GLAccountSettingsServer.UpdateSettingsPresentation(ThisForm, "Object.ManufacturedProducts");
		CalculatePercentageOfCostAllocationForOutputProducts();
	EndIf;
	
	If StructureOfTS.Property("SideAndIntermediateRelease") Or AllTS Then
		FillInServiceDetailsAccordingToStages("SideAndIntermediateRelease", FillInLines, StageData_1);
		ProductionManagement.FillInServiceDetailsOfOutputProductsOfProductionStage(Object.SideAndIntermediateRelease, FillInLines);
		ProductionManagement.FillInWHReleaseDirection(?(FillInLines <> Undefined, FillInLines, Object.SideAndIntermediateRelease));
		GLAccountSettingsServer.UpdateSettingsPresentation(ThisObject, "Object.SideAndIntermediateRelease");
		InternalSubcontractingServer.FillInProductOwnerIsAvailableInTable(ThisObject, Object.SideAndIntermediateRelease);
	EndIf;
	
	If StructureOfTS.Property("MaterialsAndWorksConsumption") Or AllTS Then
		
		FillInServiceDetailsAccordingToStages("MaterialsAndWorksConsumption", FillInLines, StageData_1);
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
		StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
		StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
		
		ProductsServer.FillInServiceDetailsForProductInCollection(
			Object.MaterialsAndWorksConsumption,
			StructureOfActions,
			FillInLines);
		
	EndIf;
	
	If StructureOfTS.Property("UnusedMaterials") Or AllTS Then
		
		FillInServiceDetailsAccordingToStages("UnusedMaterials", FillInLines, StageData_1);
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
		StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
		StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
		
		ProductsServer.FillInServiceDetailsForProductInCollection(
			Object.UnusedMaterials,
			StructureOfActions,
			FillInLines);
			
		RowsCollection = ?(FillInLines <> Undefined, FillInLines, Object.UnusedMaterials);
		For Each RowData In RowsCollection Do
			RowData.Actions = ?(RowData.ToExpenseAs, 
										Enums.BusinessTransactions.GoodsConsumptionOnDemand, 
										Enums.BusinessTransactions.ReturnFromProduction);
		EndDo; 
		
		ProductionServer.FillInShopPantryAttributeInTable(Object.UnusedMaterials, "Recipient",, FillInLines);
		GLAccountSettingsServer.UpdateSettingsPresentation(ThisForm, "Object.UnusedMaterials");
		
	EndIf;
	
	If StructureOfTS.Property("SupplyWithMaterialsAndWorks") Or AllTS Then
		
		FillInServiceDetailsAccordingToStages("SupplyWithMaterialsAndWorks", FillInLines, StageData_1);
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
		StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
		StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
		
		If Object.ProductionProcessType = Enums.ProductionProcessTypes.PerformRM Then
			StructureOfActions.FillInFeatureAttribute.Insert("UnderRepairProduct", "FinishedProductBeingRepairedCharacteristicsAreUsed");
			StructureOfActions.FillInProductTypeAttribute_.Insert("UnderRepairProduct", "RepairedFinishedProductTypeOfItem");
		EndIf;
		
		ProductsServer.FillInServiceDetailsForProductInCollection(
			Object.SupplyWithMaterialsAndWorks,
			StructureOfActions,
			FillInLines);
		
		ProductionServer.FillInShopPantryAttributeInTable(Object.SupplyWithMaterialsAndWorks, "Warehouse",, FillInLines);
		
		FillInStandards("SupplyWithMaterialsAndWorks", FillInLines);
		
		If RightToReadSubstitutes And ShowAnalogues Then
			NotePresenceOfAnalogues();
		EndIf;
		
		ProductDataManagement.FillInDetailsIncludedInSet(Object);
		
		PresentationsOfAppointments = Common.ObjectsAttributeValue(
			Object.SupplyWithMaterialsAndWorks.Unload(, "SupplyAssignment").UnloadColumn("SupplyAssignment"),
			"Presentation");
		For Each String In Object.SupplyWithMaterialsAndWorks Do
			FillInSecurityAssignmentEdit(String, PresentationsOfAppointments);
		EndDo;
		
		DocumentParameters = New Structure("Form,Collection", ThisForm, Object.SupplyWithMaterialsAndWorks);
		ProvisionInDocumentsServer.FillInServiceDetailsOfDocumentForm(DocumentParameters);
		
	EndIf;
	
	If StructureOfTS.Property("LaborCosts") Or AllTS Then
		
		FillInServiceDetailsAccordingToStages("LaborCosts", FillInLines, StageData_1);
		
		FillInStandards("LaborCosts", FillInLines);
		
	EndIf; 
	
EndProcedure

// Fills in the service details according to the stages.
//
// Parameters:
//  TSName            - String - name of the table part.
//  FillInLines - Undefined, Array of FormDataCollectionItem - Contains:
//                                              * Ref - DocumentRef.ProductionStage2_2 - 
//  StageData_1     - See DataIsBroughtIntoCompliance
//
&AtServer
Procedure FillInServiceDetailsAccordingToStages(TSName, FillInLines = Undefined, StageData_1 = Undefined)
	
	If FillInLines <> Undefined Then
		RowsArray = FillInLines;
	Else
		RowsArray = Object[TSName];
	EndIf;
	
	For Each String In RowsArray Do
		
		If StageData_1 <> Undefined And StageData_1[String.Ref] <> Undefined Then
			FillInServiceDetailsForTheseStagesInLine(String, TSName, StageData_1[String.Ref]);
		Else
			FillInServiceDetailsForTheseStagesInLine(String, TSName, ObjectIsCreatedByReference(ThisForm, String.Ref));
		EndIf;
		
		If TSName = "ManufacturedProducts" Then
			
			ValidityDate = String.ProductionDate;
			AccountingPolicyParameters = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate(
				"FinancialAccountingPolicy",
				Object.Organization,
				ValidityDate);
			
			If Not AccountingPolicyParameters = Undefined Then
				String.UseTargetCost = AccountingPolicyParameters.ProductCostingByPlannedCost;
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsWhenChangingProductionProcess(Ref)
	
	ChangedBankingDetails = New Array();
	ObjectStage = ObjectIsCreatedByReference(ThisForm, Ref);
	
	FillInParametersOfProductionUnits(ChangedBankingDetails);
	
	Filter = New Structure("Ref", Ref);
	ListOfTS = ListOfNestedTableParts(False, False);
	For Each TSName In ListOfTS Do
		FoundRows = Object[TSName].FindRows(Filter);
		For Each String In FoundRows Do
			FillInServiceDetailsForTheseStagesInLine(String, TSName, ObjectStage);
		EndDo;
	EndDo;
	
	FillInStatusesForSpecifyingSeriesServer(, True);
	
	ConfigureDependentFormElementsBasedOnChangedBankingDetails(ThisForm, ChangedBankingDetails)
	
EndProcedure

// Fills in the service details by following the link.
//
// Parameters:
//  String     - FormDataCollectionItem - Contains:
//                * Ref - DocumentRef.ProductionStage2_2 - 
//  TSName      - String - name of the table part.
//
&AtClient
Procedure FillInServiceDetailsOnLink(String, TSName)
	
	FillInServiceDetailsForTheseStagesInLine(String, TSName, ObjectIsCreatedByReference(ThisForm, String.Ref))
	
EndProcedure

// Fills in the service details according to the stages in the line.
//
// Parameters:
//  String     - FormDataCollectionItem - Contains:
//                * Ref - DocumentRef.ProductionStage2_2 - 
//  TSName      - String - name of the table part.
//  ObjectStage - See ObjectIsCreatedByReference
//
&AtClientAtServerNoContext
Procedure FillInServiceDetailsForTheseStagesInLine(String, TSName, ObjectStage)

	FillPropertyValues(String, ObjectStage,
		"Ref, Department, Stage, Status, ProductionByThirdParty, ProductionByThirdParty2_5, SubcontractOrder, ReadOnly");
	
	String.StageName = ObjectStage.NameEdit;
	
	If TSName = "SideAndIntermediateRelease" Then
		
		String.PriceKind               = ObjectStage.PriceKind;
		String.Organization           = ObjectStage.Organization;
		String.InternalSubcontracting = ObjectStage.InternalSubcontracting;
		String.MaterialProviderCompany    = ObjectStage.MaterialProviderCompany;
		
		If String.InternalSubcontracting
			And ValueIsFilled(String.MaterialProviderCompany) Then
			String.TextOwnerGiver = StrTemplate(NStr("vi = 'Người đặt gia công: %1';
													|ru = 'Давалец: %1';
													|en = 'Material provider: %1'; fa = 'Material provider: %1';
													|it = 'Давалец: %1';
													|pl = 'Material provider: %1';
													|tr = 'Tedarikçi: %1'"), String.MaterialProviderCompany);
		Else
			String.TextOwnerGiver = "";
		EndIf;
		
		If String.InternalSubcontracting
			And ValueIsFilled(String.Organization) Then
			String.TextOwnerProcessor = StrTemplate(NStr("vi = 'Người nhận gia công: %1';
														|ru = 'Переработчик: %1';
														|en = 'Subcontractor: %1'; fa = 'Subcontractor: %1';
														|it = 'Переработчик: %1';
														|pl = 'Subcontractor: %1';
														|tr = 'Fason üretici: %1'"), String.Organization);
		Else
			String.TextOwnerProcessor = "";
		EndIf;
		
	ElsIf TSName = "ManufacturedProducts"
			Or TSName = "SideAndIntermediateRelease" Then
		String.LeaveProductsAtSubcontractor = ObjectStage.LeaveProductsAtSubcontractor;
	ElsIf TSName = "SupplyWithMaterialsAndWorks" Then
		String.WorkPlanning = ObjectStage.WorkPlanning;
		String.ValueRef = ObjectStage.Purpose;
		FillInSecurityAssignmentEdit(String);
	ElsIf TSName = "MaterialsAndWorksConsumption" Then
		String.WorkPlanning = ObjectStage.WorkPlanning;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInSelectionListOfProductOwners(Form)
	
	Items = Form.Items;
	
	ChoiceList = Items.SideAndIntermediateReleaseProductOwner.ChoiceList;
	ChoiceList.Clear();
	
	CurrentData = Items.SideAndIntermediateRelease.CurrentData;
	If Not CurrentData.InternalSubcontracting Then
		Return;
	EndIf;
	
	If ValueIsFilled(CurrentData.TextOwnerGiver) Then
		ChoiceList.Add(CurrentData.MaterialProviderCompany, CurrentData.TextOwnerGiver);
	EndIf;
	
	If ValueIsFilled(CurrentData.TextOwnerProcessor) Then
		ChoiceList.Add(CurrentData.Organization, CurrentData.TextOwnerProcessor);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInDefaultLink()
	
	If Object.Stages.Count() = 1 And (Object.Stages[0].NextStageNo = 0 And Not Object.Stages[0].ProductionByThirdParty) Then
		DefaultReference = Object.Stages[0].Ref;
	Else
		DefaultReference = Undefined;
	EndIf;
	
EndProcedure

// Returns the stage by reference.
//
// Parameters:
//  Form - ClientApplicationForm - shape.
//  Ref - DocumentRef.ProductionStage2_2 - link to the document.
//
// Returns:
//  - FixedStructure - 
//  - FormDataCollectionItem - Contains:
//     * Ref - DocumentRef.ProductionStage2_2 - 
//
&AtClientAtServerNoContext
Function ObjectIsCreatedByReference(Form, Ref)
	
	If ValueIsFilled(Ref) Then
		
		StepsTable = Form.Object.Stages.FindRows(New Structure("Ref", Ref));
		If StepsTable.Count() = 0 Then
			ObjectStage = Form.NewStageData;
		Else
			ObjectStage = StepsTable[0];
		EndIf;
		
	Else
		ObjectStage = Form.NewStageData;
	EndIf;
	
	Return ObjectStage;
	
EndFunction

// Creates a match for quick access to stage details
// 
// Returns:
// 	Map - where the Key is a reference to the stage, the Value is the stage data
//
&AtServer
Function DataIsBroughtIntoCompliance()
	
	Result = New Map;
	
	For Each String In Object.Stages Do
		
		Result.Insert(String.Ref, String);
		
	EndDo;
	
	Return Result;
	
EndFunction

&AtServer
Function ComplianceOfSpecificationStagesWithDocuments()
	
	Result = New Map;
	
	For Each String In Object.Stages Do
		
		If String.DeletionMark Then
			Continue;
		EndIf;
		
		Result.Insert(String.Stage, String.Ref);
		
	EndDo;
	
	Return Result;
	
EndFunction

&AtServer
Procedure FillInParametersOfProductionUnits(ChangedBankingDetails = Undefined)
	
	RowsArray = New Array();
	DepartmentList = New Array();
	
	For Each String In Object.Stages Do
		If String.DeletionMark Or String.ProductionByThirdParty Then
			Continue;
		EndIf;
		DepartmentList.Add(String.Department);
		RowsArray.Add(String);
	EndDo;
	
	UnitParameters = ProductionServer.ParametersOfProductionUnits(DepartmentList);
	
	For Each String In RowsArray Do
		FillPropertyValues(String, UnitParameters[String.Department]);
	EndDo;
	
	UsePostOperationalControlPreviousValue = UseOperationManagement;
	UseOperationManagement = UsePostOperationalControlPreviousValue
		Or Object.Stages.FindRows(New Structure("UseOperationManagement", True)).Count() > 0;
	
	If UsePostOperationalControlPreviousValue <> UseOperationManagement
		And ChangedBankingDetails <> Undefined Then
		ChangedBankingDetails.Add("UseOperationManagement");
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInDataStructureOfMainProduct()
	
	DataStructureMainProduct = New Structure("Products, Characteristic, ItemsType, ItemVariantsAreUsed");
	
	DataStructureMainProduct.Products = Object.MainProductProducts;
	DataStructureMainProduct.Characteristic = Object.MainProductCharacteristic;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_",            New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	
	ProductsServer.FillInServiceDetailsForProductInStructure(DataStructureMainProduct, StructureOfActions);
	
EndProcedure

&AtServer
Procedure WhenChangingMainProduct()
	
	FillInDataStructureOfMainProduct();
	
	For Each String In Object.Stages Do
		
		String.MainProductProducts = Object.MainProductProducts;
		String.PackagePlan = Catalogs.Products.CharacteristicAndPackagingBelongToOwner(
			Object.MainProductProducts,
			Undefined,
			String.PackagePlan).Package;
		String.PackageActualData = Catalogs.Products.CharacteristicAndPackagingBelongToOwner(
			Object.MainProductProducts,
			Undefined,
			String.PackageActualData).Package;
		String.PackageCanceled = Catalogs.Products.CharacteristicAndPackagingBelongToOwner(
			Object.MainProductProducts,
			Undefined,
			String.PackageCanceled).Package;
		
	EndDo;
	
	ConfigureDependentFormElements(ThisForm, "MainProduct");
	
EndProcedure

&AtClient
Procedure NotifyAboutChangesInSequenceOfStages()
	
	If ProductionBatchBeforeChanging <> Undefined Then
		
		Notify("ChangingSequenceOfStages", ProductionBatchBeforeChanging);
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function ListOfNestedTableParts(IncludeSeries = True, IncludeSets = True)
	
	List = New Array;
	
	List.Add("ManufacturedProducts");
	List.Add("SideAndIntermediateRelease");
	
	List.Add("SupplyWithMaterialsAndWorks");
	List.Add("MaterialsAndWorksConsumption");
	List.Add("UnusedMaterials");
	
	List.Add("LaborCosts");
	
	If IncludeSeries Then
		List.Add("BatchFinishedProducts");
		List.Add("BatchSideAndIntermediateRelease");
		List.Add("SavingMaterialsBatch");
	EndIf;
	
	If IncludeSets Then
		List.Add("MaterialsAndWorksSets");
	EndIf;
	
	Return List;
	
EndFunction

&AtClientAtServerNoContext
Function ListOfDocumentsToLockData(Form)
	
	DocumentsList = New Array();
	
	For Each String In Form.Object.Stages Do
		If String.IsNew Then
			Continue;
		EndIf;
		DocumentsList.Add(New Structure("Ref,DataVersion",String.Ref,String.DataVersion));
	EndDo;
	
	Return DocumentsList;

EndFunction

&AtClient
Function CheckBlockDocuments(Cancel = False)
	
	If Not DocumentsAreLocked Then
		
		DocumentsList = ListOfDocumentsToLockData(ThisForm);
		
		ErrorText = "";
		DocumentsAreLocked = BlockDocumentsOnServer(
			DocumentsList,
			UUID,
			ErrorText);
		
		If Not DocumentsAreLocked Then
			Cancel = True;
			ShowMessageBox(, ErrorText);
		EndIf;
		
	EndIf;
	
	Return DocumentsAreLocked;
	
EndFunction

&AtServerNoContext
Function BlockDocumentsOnServer(Val DocumentsList, Val UUID, ErrorText = "")
	
	DocumentsAreLocked = DataProcessors.EditProductionStageSequence.BlockDocuments(
		DocumentsList,
		UUID,
		ErrorText);
	
	Return DocumentsAreLocked;
	
EndFunction

&AtServer
Procedure UnlockDocuments()
	
	If Not DocumentsAreLocked Then
		Return;
	EndIf;
	
	DocumentsList = ListOfDocumentsToLockData(ThisForm);
	DataProcessors.EditProductionStageSequence.UnlockDocuments(DocumentsList, UUID);
	
	DocumentsAreLocked = False;
	
EndProcedure

&AtServer
Procedure CreateLinksOfNewDocuments()
	
	NewDocumentLinks.Clear();
	
	For Cnt = 0 To 10 Do
		NewDocumentLinks.Add(Documents.ProductionStage2_2.GetRef());
	EndDo;
	
EndProcedure

&AtClient
Function GetNewDocumentLink()
	
	If NewDocumentLinks.Count() > 0 Then
		RefToNew = NewDocumentLinks[0].Value;
		NewDocumentLinks.Delete(0);
	Else
		RefToNew = GetNewDocumentLinkOnServer();
	EndIf;
	
	Return RefToNew;
	
EndFunction

&AtServer
Function GetNewDocumentLinkOnServer()
	
	If NewDocumentLinks.Count() = 0 Then
		CreateLinksOfNewDocuments();
	EndIf;
	
	RefToNew = NewDocumentLinks[0].Value;
	NewDocumentLinks.Delete(0);
	
	Return RefToNew;
	
EndFunction

&AtClient
Function ParametersOfQuantityAndSeriesRequestForm(Mode)
	
	CheckParameters = SupplyClientServer.InitializeFillVerificationParameters(
		"SupplyWithMaterialsAndWorks", 
		NStr("vi = 'Đảm bảo';
			|ru = 'Обеспечение';
			|en = 'Supply'; fa = 'Supply';
			|it = 'Approvvigionamento';
			|pl = 'Zaopatrzenie';
			|tr = 'Tedarik'"));
		
	CheckParameters.Fields.Delete("Warehouse");
	
	If Not SupplyClient.CheckFilling(
				Object,
				Object.SupplyWithMaterialsAndWorks,
				Items.SupplyWithMaterialsAndWorks.CurrentRow,
				CheckParameters,
				Undefined,
				Mode) Then
		Return Undefined;
	EndIf;
	
	FormParameters = SoftwareSelectionParameters(Mode);
	FormParameters.SeriesSpecificationParameters = SeriesSpecificationParameters.SupplyWithMaterialsAndWorks;
	
	Return FormParameters;
	
EndFunction

&AtServer
Function FillWarehouseInSelectedLinesOnServer(Val ArrayOfSelectedRows, Warehouse)
	
	FilledWithRows = WarehousesServer.FillInWarehousesInSelectedLines(Object.SupplyWithMaterialsAndWorks, ArrayOfSelectedRows, Warehouse);
	
	If FilledWithRows > 0 Then
		
		AfterChangingTSStringsProgrammaticallyOnServer("SupplyWithMaterialsAndWorks", ArrayOfSelectedRows);
		
	EndIf;
	
	Return FilledWithRows;
	
EndFunction

&AtClient
Procedure CancelSelectedLines(TSName)
	
	SelectedRows = GetSelectedRowsInList(TSName);
	If Not ValueIsFilled(SelectedRows) Then
		Return;
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("TSName", TSName);
	AdditionalParameters.Insert("SelectedRows", SelectedRows);
	
	OpenForm("Catalog.ReasonsForProductionCancellation.ChoiceForm",
		,
		,
		,
		,
		,
		New CallbackDescription("UndoSelectedLinesSelectReasonEnd", ThisObject, AdditionalParameters),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure UndoSelectedLinesSelectReasonEnd(CancellationReason, AdditionalParameters) Export
	
	If CancellationReason = Undefined Then
		Return;
	EndIf;
	
	UndoSelectedRowsOnServer(
		CancellationReason,
		AdditionalParameters.SelectedRows,
		AdditionalParameters.TSName);
		
	ShowUserNotification(NStr("vi = 'Các dòng đã chọn bị hủy bỏ';
								|ru = 'Выделенные строки отменены';
								|en = 'Selected lines are canceled'; fa = 'Selected lines are canceled';
								|it = 'Righe selezionate annullate';
								|pl = 'Zaznaczone wiersze anulowano';
								|tr = 'Belirtilen satırlar iptal edildi'"),,, PictureLib.Information32);
	
EndProcedure

&AtServer
Procedure UndoSelectedRowsOnServer(CancellationReason, SelectedRows, TSName)
	
	If TSName = "ManufacturedProducts" Or TSName = "SideAndIntermediateRelease" Then
		
		ValuesInCache = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
		StructureOfActions = New Structure;
		SeriesVerificationParameters = New Structure;
		SeriesVerificationParameters.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters[TSName]);
		
		RowsToProcess = New Array();
		
		For Each RowID In SelectedRows Do
			
			String = Object[TSName].FindByID(RowID);
			
			String.Canceled = True;
			String.CancellationReason = CancellationReason;
			String.Manufactured = False;
			
			RowsToProcess.Add(String);
			
		EndDo;
		
		StructureOfActions.Insert("CheckSeriesCalculateStatus", SeriesVerificationParameters);
		AddQualityControlActionsToStructure(TSName, StructureOfActions, CacheQualityControl);
		
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			RowsToProcess,
			StructureOfActions,
			Object[TSName],
			ValuesInCache);
		
	ElsIf TSName = "SupplyWithMaterialsAndWorks" Then
		
		For Each RowID In SelectedRows Do
			String = Object.SupplyWithMaterialsAndWorks.FindByID(RowID);
			String.Canceled = True;
			String.CancellationReason = CancellationReason;
		EndDo;
		
		FillInStatusesForSpecifyingSeriesServer("SupplyWithMaterialsAndWorks");
		
	ElsIf TSName = "LaborCosts" Then
		
		For Each RowID In SelectedRows Do
		
			String = Object.LaborCosts.FindByID(RowID);
			String.Canceled = True;
			String.CancellationReason = CancellationReason;
			
			If String.Completed2 Then
				String.Completed2 = False;
				LaborPerformedWhenChangingOnServer(RowID);
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServer
Function FillInPricesOfSelectedRowsByPriceTypeServer(TSName, PriceKind, Currency, IDs)
	
	ReadyForProcessing_ = New Array;
	
	For Each Id In IDs Do
		RowData = Object[TSName].FindByID(Id);
		If RowData.Manufactured Then
			ReadyForProcessing_.Add(RowData);
		EndIf;
		RowData.Price  = 0;
		RowData.Sum = 0;
	EndDo;
	
	FillParameters = ProductionManagementClientServer.ParametersForFillingIssuePrices(
		PriceKind,
		Currency,
		StartOfDayCurSessionDate());
		
	FillParameters.Insert("Organization", Object.Organization);
	
	PricesAreFilledOut = EnterprisePricesFillingServer.FillInPrices(
		Object[TSName], // Table part
		ReadyForProcessing_, // Array of rows or selection structure
		FillParameters, // The fill parameters
		New Structure( // The structure of the action with the changed strings
			"RecalculateAmount",
			"NumberOfPackages"));
	
	Return PricesAreFilledOut;
	
EndFunction

&AtClient
Procedure BreakTSString(TSName)
	
	FormTable  = Items[TSName];
	TableData = Object[TSName];
	
	If Not ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(FormTable) Then
		Return;
	ElsIf FormTable.CurrentData.ReadOnly Then
		ShowMessageBox(, NStr("vi = 'Không thể thực hiện lệnh cho dòng đã chọn!';
								|ru = 'Команда не может быть выполнена для выбранной строки!';
								|en = 'Command cannot be executed for the selected line.'; fa = 'Command cannot be executed for the selected line.';
								|it = 'Il comando non può essere eseguito per la riga selezionata!';
								|pl = 'Polecenie nie może być wykonane dla wybranego wiersza!';
								|tr = 'Seçili satır için komut gerçekleştirilemez!'"));
		Return;
	EndIf;
	If Not CheckBlockDocuments() Then
		Return;
	EndIf;
	
	StringSplittingParameters = ProcessingOfTabularFormsClient.StringSplittingParameters();
	If TSName = "LaborCosts" Then
		StringSplittingParameters.Title = NStr("vi = 'Hãy nhập số lượng trong dòng mới';
												|ru = 'Введите количество в новой строке';
												|en = 'Enter quantity in a new line'; fa = 'Enter quantity in a new line';
												|it = 'Inserire la quantità nella nuova riga';
												|pl = 'Wprowadź ilość w nowym wierszu';
												|tr = 'Miktarı yeni satıra gir'");
		StringSplittingParameters.FieldNameQuantity = "Count";
	EndIf;
	StringSplittingParameters.AllowZeroCount = False;
	
	Notification = New CallbackDescription("BreakTSStringCompletion", ThisObject, TSName);
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, Notification, StringSplittingParameters);
	
EndProcedure

&AtClient
Procedure BreakTSStringCompletion(NewRow, TSName) Export 
	
	If NewRow = Undefined Then
		Return;
	EndIf;
	
	If TSName = "ManufacturedProducts"
		Or TSName = "SideAndIntermediateRelease"
		Or TSName = "SupplyWithMaterialsAndWorks" 
		Or TSName = "UnusedMaterials" Then
		NewRow.RowCode = 0;
	EndIf;
	
	If TSName = "ManufacturedProducts"
		Or TSName = "SideAndIntermediateRelease"
		Or TSName = "SupplyWithMaterialsAndWorks" Then
		NewRow.KeyProducts = Undefined;
	EndIf;
	
	If TSName = "LaborCosts" Then
		NewRow.KeyWorkType = Undefined;
	EndIf;
		
	CurrentData = Items[TSName].CurrentData;
	
	StructureOfActions = New Structure;
	
	If TSName = "ManufacturedProducts"
		Or TSName = "SideAndIntermediateRelease"
		Or TSName = "SupplyWithMaterialsAndWorks"
		Or TSName = "UnusedMaterials"
		Or TSName = "MaterialsAndWorksConsumption" Then
		
		StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
		
		If TSName = "SideAndIntermediateRelease" Then
			StructureOfActions.Insert("RecalculateAmount");
		EndIf;
		
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	If TSName = "SupplyWithMaterialsAndWorks" Then
		
		ProvisionInDocumentsClientServer.AddCollateralActions(
			StructureOfActions,
			"UpdateProductCache_",
			DocumentParametersForSoftwareActions(ThisObject));
			
		ProcessSplitOfStringIncludedInSet(NewRow);
		
	EndIf;
	BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
	
	If TSName = "ManufacturedProducts" Then
		ProductionClientServer.RecalculateFractionOfCostWhenSplittingRow(NewRow, CurrentData, MethodOfAllocatingFinishedProductCosts);
	EndIf;
	
	RowsArray = New Array;
	RowsArray.Add(CurrentData.GetID());
	RowsArray.Add(NewRow.GetID());
	AfterChangingTSStringsProgrammaticallyOnServer(TSName, RowsArray, StructureOfActions);

EndProcedure

&AtClientAtServerNoContext
Procedure SetPropertiesOfCollapsibleGroup(GroupItem1, PictureGroup, GroupCollapsed)

	GroupItem1.Visible = Not GroupCollapsed;
	
	If GroupCollapsed Then
		PictureGroup.Picture = PictureLib.RightArrow;
	Else
		PictureGroup.Picture = PictureLib.DownArrow;
	EndIf; 

EndProcedure

&AtClientAtServerNoContext
Function ParametersForFillingIssuePrices(ObjectStage)
	
	CurrentSessionDate = StartOfDayCurSessionDate();
	
	FillParameters = ProductionManagementClientServer.ParametersForFillingIssuePrices(
		ObjectStage.PriceKind,
		ObjectStage.Currency,
		CurrentSessionDate);
	
	Return FillParameters;
	
EndFunction

&AtClient
Procedure ProcessStartOfProductionStageSelectionInLine(TSName)
	
	SelectedRows = Items[TSName].SelectedRows;
	
	If SelectedRows.Count() = 0 Then
		WarningText = NStr("vi = 'Cần chọn các dòng mà sẽ điền công đoạn sản xuất.';
							|ru = 'Необходимо выбрать строки, для которых будет заполнен этап производства.';
							|en = 'Select lines to fill in a production stage.'; fa = 'Select lines to fill in a production stage.';
							|it = 'È necessario selezionare le righe per le quali sarà compilata la fase di produzione.';
							|pl = 'Należy wybrać wiersze, dla których zostanie wypełniony etap produkcji.';
							|tr = 'Üretim aşamasının doldurulacağı satırları seçmeniz gerekmektedir.'");
		CommonClientServer.MessageToUser(WarningText);
		Return;
	EndIf;
	
	CurrentData = Items[TSName].CurrentData;
	
	RowFilter = New Structure();
	
	If TSName = "ManufacturedProducts" Then
		RowFilter.Insert("NextStageNo", 0);
	EndIf;
	
	If TSName = "LaborCosts"
		Or TSName = "MaterialsAndWorksConsumption"
		Or TSName = "UnusedMaterials" Then
		RowFilter.Insert("ProductionByThirdParty", False);
	EndIf;
	
	If Not TSName = "SupplyWithMaterialsAndWorks"
		Or (CurrentData.ItemsType <> PredefinedValue("Enum.ItemsTypes.EmptyRef")
				And CurrentData.ItemsType <> PredefinedValue("Enum.ItemsTypes.Work_5")) Then
		RowFilter.Insert("WorkPlanning", False);
	EndIf;
	
	FormParameters = New Structure();
	FormParameters.Insert("Filter", RowFilter);
	FormParameters.Insert("AddressListOfStages", ListOfStagesInRepository());
	
	CallbackDescription = New CallbackDescription("ProcessProductionStageSelection", ThisObject, TSName);
	OpenForm("DataProcessor.EditProductionStageSequence.Form.ProductionStageChoiceForm", FormParameters, ThisObject,,,, CallbackDescription);
	
EndProcedure

&AtClient
Procedure ProcessProductionStageSelection(ClosingResult, TSName) Export

	If ClosingResult = Undefined Then
		Return;
	EndIf;
	
	ObjectStage = ObjectIsCreatedByReference(ThisForm, ClosingResult);
	
	SelectedRows = Items[TSName].SelectedRows;
	
	ProcessChangeOfProductionStageInLines(SelectedRows, TSName, ClosingResult);
	
	If TSName = "MaterialsAndWorksConsumption" Or TSName = "UnusedMaterials" Then
		CheckHandleChangeOfProgressMark(ObjectStage, True);
	ElsIf TSName = "SupplyWithMaterialsAndWorks" Then
		FillInListOfSelectedSecurityAppointments();
		SetSelectionByTypeOfSupplyItem();
		UpdateSupplyBillofMaterialsItemSelectionParameters();
	EndIf;
	
EndProcedure

&AtServer
Function ListOfStagesInRepository()
	
	StageList = Object.Stages.Unload(New Structure("ReadOnly, DeletionMark", False, False));
	
	Address = PutToTempStorage(StageList, ThisForm.UUID);
	Return Address;
	
EndFunction

&AtClient
Procedure ProcessingLineAtBeginningOfEditing(TSName, NewRow, Copy)
	
	If NewRow Then
		
		CurrentData = Items[TSName].CurrentData;
		
		StructureOfData = New Structure;
		If Not Copy And ValueIsFilled(DefaultReference)Then
			StructureOfData.Insert("Ref", DefaultReference);
		ElsIf Copy And CurrentData.ReadOnly Then
			StructureOfData.Insert("Ref", Undefined);
		EndIf;
		
		If ValueIsFilled(StructureOfData) Then
			FillPropertyValues(CurrentData, StructureOfData, "Ref");
		EndIf;
		
		FillInServiceDetailsOnLink(CurrentData, TSName);
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function StartOfDayCurSessionDate()
	
	#If Server Then
	Return BegOfDay(CurrentSessionDate());
	#Else
	Return BegOfDay(CommonClient.SessionDate());
	#EndIf
	
EndFunction

&AtClientAtServerNoContext
Function PathToTabularSection(Val TabularSectionName, Val LineNumber, Val AttributeName)

	Return "Object." + TabularSectionName + "[" + Format(LineNumber - 1, "NZ=0; NG=0") + "]." + AttributeName;

EndFunction

&AtClient
Function GetSelectedRowsInList(TSName, DisplayErrorMessages = True)
	
	RowsArray = New Array;
	
	List = Items[TSName];
	If List.SelectedRows.Count() > 0 Then
		For Iterator_SSLy = 0 To List.SelectedRows.Count() - 1 Do
			If TypeOf(List.SelectedRows[Iterator_SSLy]) <> Type("DynamicListGroupRow") Then
				RowData = Object[TSName].FindByID(List.SelectedRows[Iterator_SSLy]);
				If RowData.ReadOnly Then
					Continue;
				EndIf;
				RowsArray.Add(List.SelectedRows[Iterator_SSLy]);
			EndIf;
		EndDo;
		If DisplayErrorMessages And RowsArray.Count() = 0 Then
			If List.SelectedRows.Count() > 1 Then
				ShowMessageBox(, NStr("vi = 'Không thể thực hiện lệnh cho các dòng đã chọn!';
										|ru = 'Команда не может быть выполнена для выделенных строк!';
										|en = 'Cannot execute the command for the selected lines.'; fa = 'Cannot execute the command for the selected lines.';
										|it = 'Il comando non può essere eseguito per le righe selezionate!';
										|pl = 'Komenda nie może być wykonana dla zaznaczonych wierszy!';
										|tr = 'Belirtilen satırlar için komut gerçekleştirilemez!'"));
			Else
				ShowMessageBox(, NStr("vi = 'Lệnh không thể được thực thi cho dòng đã chọn!';
										|ru = 'Команда не может быть выполнена для выделенной строки!';
										|en = 'Cannot execute the command for the selected line.'; fa = 'Cannot execute the command for the selected line.';
										|it = 'Il comando non può essere eseguito per la riga selezionata!';
										|pl = 'Komenda nie może być wykonana dla wybranego wiersza!';
										|tr = 'Belirtilen satır için komut gerçekleştirilemez!'"));
			EndIf;
		EndIf;
	ElsIf DisplayErrorMessages Then
		ShowMessageBox(, NStr("vi = 'Để thực hiện một giao dịch, Cần chọn dòng!';
								|ru = 'Для выполнения действия необходимо выбрать строки!';
								|en = 'Select lines to perform the action.'; fa = 'Select lines to perform the action.';
								|it = 'Per eseguire azione, è necessario selezionare le righe!';
								|pl = 'Dla wykonywania czynności należy wybrać wiersze!';
								|tr = 'Eylemin gerçekleştirilmesi için satır seçmeniz gerekmektedir!'"));
	EndIf;
	
	Return RowsArray;
	
EndFunction

&AtClient
Function CheckRowsOfTablePartBeforeDeleting(TSName, Cancel)
	
	List = Items[TSName];
	For Iterator_SSLy = 0 To List.SelectedRows.Count() - 1 Do
		If TypeOf(List.SelectedRows[Iterator_SSLy]) <> Type("DynamicListGroupRow") Then
			RowData = Object[TSName].FindByID(List.SelectedRows[Iterator_SSLy]);
			If RowData.ReadOnly Then
				Cancel = True;
				If List.SelectedRows.Count() > 1 Then
					ShowMessageBox(, NStr("vi = 'Lệnh không thể được thực thi cho các dòng được chọn!';
											|ru = 'Команда не может быть выполнена для выделенных строк!';
											|en = 'Cannot execute the command for the selected lines.'; fa = 'Cannot execute the command for the selected lines.';
											|it = 'Il comando non può essere eseguito per le righe selezionate!';
											|pl = 'Komenda nie może być wykonana dla zaznaczonych wierszy!';
											|tr = 'Belirtilen satırlar için komut gerçekleştirilemez!'"));
				Else
					ShowMessageBox(, NStr("vi = 'Lệnh không thể được thực thi cho dòng đã chọn!';
											|ru = 'Команда не может быть выполнена для выделенной строки!';
											|en = 'Cannot execute the command for the selected line.'; fa = 'Cannot execute the command for the selected line.';
											|it = 'Il comando non può essere eseguito per la riga selezionata!';
											|pl = 'Komenda nie może być wykonana dla wybranego wiersza!';
											|tr = 'Belirtilen satır için komut gerçekleştirilemez!'"));
				EndIf;
				Return False;
			EndIf;
		EndIf;
	EndDo;
	Return True;
	
EndFunction

&AtServer
Procedure ClearRowsOfTablePart(TSName)
	
	For IndexOf = -Object[TSName].Count() + 1 To 0 Do
		
		String = Object[TSName][-IndexOf];
		
		If String.ReadOnly Then
			Continue;
		EndIf;
		
		Object[TSName].Delete(String);
		
	EndDo;
	
	If TSName = "SupplyWithMaterialsAndWorks" Then
		ProductDataManagement.UpdateSetsOfMaterialsAndWorksTable(Object);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(TSName, Form, StructureOfActions)
	
	StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	
	If TSName = "SideAndIntermediateRelease" Then
		StructureOfActions.Insert("RecalculateAmount");
	EndIf;
	
	If TSName = "ManufacturedProducts" Then
		StructureOfActions.Insert("RecalculateCostShare", Form.CostAllocationParameters);
	EndIf;

EndProcedure

&AtClientAtServerNoContext
Procedure AddQualityControlActionsToStructure(TSName, StructureOfActions, CacheQualityControl)
	
	If TSName = "ManufacturedProducts"
		Or TSName = "SideAndIntermediateRelease" Then
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenCostShareEntryForm(CurrentData)

	NoErrors_ = ProductionClient.CheckFillingBeforeEnteringCostFraction(CurrentData, CostAllocationParameters);
	
	If NoErrors_ Then
		FormParameters = ParametersOfCostShareEntryForm_(CurrentData.GetID());
		OpenForm("CommonForm.EnterCostShare",
			FormParameters,
			ThisForm);
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessingInputOfFractionOfCost(CurrentData, ValueSelected)
	
	If CurrentData.CostShare <> ValueSelected.CostShare Then
		
		ProductionClientServer.FillInCostFractionInLine(
			CurrentData,
			ValueSelected);
		
		CalculatePercentageOfCostAllocationForOutputProducts();
		
		Modified = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ConsumerStageBeginningOfChoice(CurrentData, TSName)
	
	ObjectStage = ObjectIsCreatedByReference(ThisForm, CurrentData.Ref);
	TablePartElement = Items[TSName];//FormTable - 
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("RowID", TablePartElement.CurrentRow);
	AdditionalParameters.Insert("TSName", TSName);
	CallbackDescription = New CallbackDescription("ConsumerStageBeginningOfChoiceCompletion", ThisObject, AdditionalParameters);
	
	ProductionManagementClient.OpenConsumerStageSelectionForm(
		ObjectStage,
		CurrentData,
		ThisForm,
		CallbackDescription);
	
EndProcedure

&AtClient
Procedure ConsumerStageBeginningOfChoiceCompletion(Result, Var_Parameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	String = Object[Var_Parameters.TSName].FindByID(Var_Parameters.RowID);
	String.StageConsumer = Result;
	
	Modified = True;
	
EndProcedure

&AtServerNoContext
Function ProductData_4()
	
	Return Catalogs.BillsOfMaterials.ProductData_5();
	
EndFunction

&AtServer
Function FormattedStringSpecificationStage()
	
	If Not Object.BillOfMaterials.IsEmpty() Then
		StringSpecification = Common.ObjectAttributeValue(Object.BillOfMaterials, "Description");
		Result = New FormattedString(StringSpecification,,,, GetURL(Object.BillOfMaterials));
	Else
		StringSpecification = "<" + NStr("vi = 'không có bảng kê chi tiết các nguồn lực sản xuất';
										|ru = 'нет спецификации';
										|en = 'no BOM'; fa = 'no BOM';
										|it = 'non ci sono specifiche';
										|pl = 'brak specyfikacji';
										|tr = 'ürün reçetesi yok'") + ">";
		Result = New FormattedString(StringSpecification);
	EndIf;
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function AvailableProductTypes(Form, TSName, CurrentData = Undefined)
	
	If TSName = "SupplyWithMaterialsAndWorks"
		And Form.Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.PerformRM")
		And (Not CurrentData = Undefined And CurrentData.WorkPlanning) Then
		
		Result = New Array;
		Result.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
		
	Else
		
		Result = ProductsClientServer.SelectionByProductReusablePackagingWork(
			(TSName = "SupplyWithMaterialsAndWorks") And Form.UseOfKitsInProductionIsAvailable);
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function ObjectTableByName(Object, TableName)
	
	If TableName = "Stage" Then
		ObjectTable = Object.Stages;
	
	ElsIf TableName = "ManufacturedProducts" Then
		ObjectTable = Object.ManufacturedProducts;
	
	ElsIf TableName = "SideAndIntermediateRelease" Then
		ObjectTable = Object.SideAndIntermediateRelease;
	
	ElsIf TableName = "SupplyWithMaterialsAndWorks" Then
		ObjectTable = Object.SupplyWithMaterialsAndWorks;
	
	ElsIf TableName = "LaborCosts" Then
		ObjectTable = Object.LaborCosts;
	
	ElsIf TableName = "MaterialsAndWorksConsumption" Then
		ObjectTable = Object.MaterialsAndWorksConsumption;
	
	ElsIf TableName = "UnusedMaterials" Then
		ObjectTable = Object.UnusedMaterials;
	
	ElsIf TableName = "BatchFinishedProducts" Then
		ObjectTable = Object.BatchFinishedProducts;
	
	ElsIf TableName = "BatchSideAndIntermediateRelease" Then
		ObjectTable = Object.BatchSideAndIntermediateRelease;
	
	ElsIf TableName = "SavingMaterialsBatch" Then
		ObjectTable = Object.SavingMaterialsBatch;
	
	Else
		ObjectTable = Undefined;
	EndIf;
	
	Return ObjectTable;
	
EndFunction

&AtServer
Function TemporaryObjectDataTables(StageList) 
	
	QueryTexts = New Array;
	Query = New Query;

	QueryText = 
	"SELECT
	|	Table.Date AS Date,
	|	Table.Organization AS Organization,
	|	Table.InternalSubcontracting AS InternalSubcontracting,
	|	Table.MaterialProviderCompany AS MaterialProviderCompany,
	|	Table.Department AS Department,
	|	Table.ProductionLot AS ProductionLot,
	|	Table.ReferenceOrder AS ReferenceOrder,
	|	Table.Ref AS Ref,
	|	Table.ProductionIssueForActivity AS ProductionIssueForActivity,
	|	Table.Status AS Status,
	|	Table.PriceKind AS PriceKind,
	|	Table.Currency AS Currency,
	|	Table.StageNumber AS StageNumber,
	|	Table.NextStageNo AS NextStageNo,
	|	Table.StageName AS StageName,
	|
	|	Table.BusinessOperation AS BusinessOperation,
	|
	|	Table.ProductionByThirdParty AS ProductionByThirdParty,
	|	Table.ProductionByThirdParty2_5 AS ProductionByThirdParty2_5,
	|	Table.SubcontractOrder AS SubcontractOrder,
	|	
	|	Table.LeaveProductsAtSubcontractor AS LeaveProductsAtSubcontractor,
	|	Table.ProductionInOneDay AS ProductionInOneDay,
	|	Table.ProductionDate AS ProductionDate,
	|	Table.NotShipInInstallments AS NotShipInInstallments,
	|	Table.DateOfShipment AS DateOfShipment,
	|	Table.ConsumptionInOneDay AS ConsumptionInOneDay,
	|	Table.DateOfMaterialWorkConsumption AS DateOfMaterialWorkConsumption,
	|	Table.WorkPerformanceAsOneDay AS WorkPerformanceAsOneDay,
	|	Table.WorkExecutionDate AS WorkExecutionDate, 
	|	Table.DurationBeforeProductionIssue AS DurationBeforeProductionIssue,	
	|
	|	Table.ActualStageStart AS ActualStageStart,
	|	Table.ActualStageEnd AS ActualStageEnd,
	|
	|	Table.Purpose AS Purpose,
	|
	|	Table.NumberOfPackagesPlan AS NumberOfPackagesPlan,
	|	Table.PackagePlan AS PackagePlan,
	|	Table.PackageActualData AS PackageActualData,
	|	Table.PackageCanceled AS PackageCanceled,
	|
	|	&TechProcessParameters,
	|
	|	Table.MethodOfAllocatingFinishedProductCosts AS MethodOfAllocatingFinishedProductCosts
	|
	|INTO Stages
	|FROM
	|	Document.ProductionStage2_2 AS Table
	|
	|	LEFT JOIN InformationRegister.TechnologicalProcessesOfProductionStages AS TechnicalProcess
	|	ON Table.Ref = TechnicalProcess.Stage
	|
	|WHERE
	|	Table.Ref IN (&ProductionStage)
	|
	|INDEX BY
	|	Table.Ref
	|";
	
	QueryText = StrReplace(QueryText,
		"&TechProcessParameters",
		ProductionProcessEditor.QueryTextParametersOfTechnicalProcessOfStage("Table"));
	
	QueryTexts.Add(QueryText);
	
	QueryText = 
	"SELECT
	|	TabularSection.Ref,
	|	TabularSection.Products,
	|	TabularSection.Characteristic,
	|	TabularSection.Package,
	|	TabularSection.NumberOfPackages,
	|	TabularSection.Count,
	|	TabularSection.ToExpenseAs,
	|	TabularSection.ExpenseItem,
	|	TabularSection.Purpose,
	|	TabularSection.StageConsumer,
	|	TabularSection.Recipient,
	|	TabularSection.ProductionDate,
	|	TabularSection.CostShare,
	|	TabularSection.Manufactured,
	|	TabularSection.Canceled,
	|	TabularSection.CancellationReason,
	|	TabularSection.ProcessByBOM,
	|	TabularSection.BillOfMaterials,
	|	TabularSection.Price AS Price,
	|	TabularSection.Sum,
	|	TabularSection.Series,
	|	TabularSection.Purpose,
	|	TabularSection.ItemsLocationAttributes,
	|	TabularSection.BatchesIndicationStatus,
	|	TabularSection.BatchesIndicationStatusRecipient,
	|	TabularSection.DimensionOfExpenses,
	|	TabularSection.AssetsLiabilitiesDimension,
	|	TabularSection.GLAccountSettings,
	|	TabularSection.RowID,
	|	TabularSection.RowCode,
	|	TabularSection.Department
	|INTO ManufacturedProducts
	|FROM
	|	Document.ProductionStage2_2.ManufacturedProducts AS TabularSection
	|WHERE
	|	TabularSection.Ref IN (&ProductionStage)";
	
	QueryTexts.Add(QueryText);
	
	QueryText = 
	"SELECT
	|	TabularSection.Ref,
	|	TabularSection.Products,
	|	TabularSection.Characteristic,
	|	TabularSection.Package,
	|	TabularSection.NumberOfPackages,
	|	TabularSection.Count,
	|	TabularSection.ToExpenseAs,
	|	TabularSection.ExpenseItem,
	|	TabularSection.Purpose,
	|	TabularSection.StageConsumer,
	|	TabularSection.Recipient,
	|	TabularSection.Manufactured,
	|	TabularSection.ProductionDate,
	|	TabularSection.Canceled,
	|	TabularSection.CancellationReason,
	|	TabularSection.ProcessByBOM,
	|	TabularSection.BillOfMaterials,
	|	TabularSection.Price,
	|	TabularSection.Sum,
	|	TabularSection.ProductCostElement,
	|	TabularSection.Series,
	|	TabularSection.ItemsLocationAttributes,
	|	TabularSection.BatchesIndicationStatus,
	|	TabularSection.BatchesIndicationStatusRecipient,
	|	TabularSection.DimensionOfExpenses,
	|	TabularSection.AssetsLiabilitiesDimension,
	|	TabularSection.GLAccountSettings,
	|	TabularSection.RowID,
	|	TabularSection.RowCode,
	|	TabularSection.Department
	|INTO SideAndIntermediateRelease
	|FROM
	|	Document.ProductionStage2_2.SideAndIntermediateRelease AS TabularSection
	|WHERE
	|	TabularSection.Ref IN (&ProductionStage)";
	
	QueryTexts.Add(QueryText);
	
	QueryText = 
	"SELECT
	|	TabularSection.Ref,
	|	TabularSection.Products,
	|	TabularSection.Characteristic,
	|	TabularSection.Package,
	|	TabularSection.NumberOfPackages,
	|	TabularSection.Count,
	|	TabularSection.Warehouse,
	|	TabularSection.DateOfShipment,
	|	TabularSection.Purpose,
	|	TabularSection.SupplyAssignment,
	|	TabularSection.Produced,
	|	TabularSection.BillOfMaterials,
	|	TabularSection.ProductCostElement,
	|	TabularSection.ItemsLocationAttributes,
	|	TabularSection.CorItemsLocationAttributes,
	|	TabularSection.Canceled,
	|	TabularSection.CancellationReason,
	|	TabularSection.BatchesIndicationStatus,
	|	TabularSection.BatchesIndicationStatusRecipient,
	|	TabularSection.Series,
	|	TabularSection.SupplyOption,
	|	TabularSection.WithAssignment,
	|	TabularSection.RowID,
	|	TabularSection.RowCode,
	|	TabularSection.Department
	|INTO SupplyWithMaterialsAndWorks
	|FROM
	|	Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS TabularSection
	|WHERE
	|	TabularSection.Ref IN (&ProductionStage)";
	
	QueryTexts.Add(QueryText);
	
	QueryText =
	"SELECT
	|	TabularSection.Ref,
	|	TabularSection.Products,
	|	TabularSection.Characteristic,
	|	TabularSection.Package,
	|	TabularSection.NumberOfPackages,
	|	TabularSection.Count,
	|	TabularSection.DateOfMaterialWorkConsumption,
	|	TabularSection.ProductCostElement,
	|	TabularSection.Series,
	|	TabularSection.BatchesIndicationStatus,
	|	TabularSection.ItemsLocationAttributes,
	|	TabularSection.CorItemsLocationAttributes,
	|	TabularSection.RowID,
	|	TabularSection.Department
	|INTO MaterialsAndWorksConsumption
	|FROM
	|	Document.ProductionStage2_2.MaterialsAndWorksConsumption AS TabularSection
	|WHERE
	|	TabularSection.Ref IN (&ProductionStage)";
	
	QueryTexts.Add(QueryText);
	
	QueryText = 
	"SELECT
	|	TabularSection.Ref,
	|	TabularSection.Products,
	|	TabularSection.Characteristic,
	|	TabularSection.Package,
	|	TabularSection.NumberOfPackages,
	|	TabularSection.Count,
	|	TabularSection.Purpose,
	|	TabularSection.ToExpenseAs,
	|	TabularSection.DateOfTransaction,
	|	TabularSection.ExpenseItem,
	|	TabularSection.DimensionOfExpenses,
	|	TabularSection.Recipient,
	|	TabularSection.ItemsLocationAttributes,
	|	TabularSection.CorItemsLocationAttributes,
	|	TabularSection.BatchesIndicationStatus,
	|	TabularSection.BatchesIndicationStatusRecipient,
	|	TabularSection.Series,
	|	TabularSection.ToExpenseAs,
	|	TabularSection.AssetsLiabilitiesDimension,
	|	TabularSection.GLAccountSettings,
	|	TabularSection.RowID,
	|	TabularSection.Department
	|INTO UnusedMaterials
	|FROM
	|	Document.ProductionStage2_2.UnusedMaterials AS TabularSection
	|WHERE
	|	TabularSection.Ref IN (&ProductionStage)";
	
	QueryTexts.Add(QueryText);
	
	QueryText = 
	"SELECT
	|	TabularSection.Ref,
	|	TabularSection.Count,
	|	TabularSection.Performer,
	|	TabularSection.Completed2,
	|	TabularSection.ExecutionDate,
	|	TabularSection.ProductCostElement,
	|	TabularSection.Canceled,
	|	TabularSection.CancellationReason,
	|	TabularSection.RowCode,
	|	TabularSection.Department
	|INTO LaborCosts
	|FROM
	|	Document.ProductionStage2_2.LaborCosts AS TabularSection
	|WHERE
	|	TabularSection.Ref IN (&ProductionStage)";
	
	QueryTexts.Add(QueryText); 
	
	QueryText = 
	"SELECT
	|	TabularSection.Ref,
	|	TabularSection.Series,
	|	TabularSection.Products,
	|	TabularSection.Characteristic,
	|	TabularSection.Recipient,
	|	TabularSection.Purpose,
	|	TabularSection.Manufactured,
	|	TabularSection.Count,
	|	TabularSection.ProductionDate,
	|	TabularSection.Canceled,
	|	TabularSection.Department
	|INTO BatchFinishedProducts
	|FROM
	|	Document.ProductionStage2_2.BatchFinishedProducts AS TabularSection
	|WHERE
	|	TabularSection.Ref IN (&ProductionStage)";
	
	QueryTexts.Add(QueryText);
	
	QueryText = 
	"SELECT
	|	TabularSection.Ref,
	|	TabularSection.Series,
	|	TabularSection.Products,
	|	TabularSection.Characteristic,
	|	TabularSection.Recipient,
	|	TabularSection.Purpose,
	|	TabularSection.Manufactured,
	|	TabularSection.Count,
	|	TabularSection.ProductionDate, 
	|	TabularSection.Canceled,
	|	TabularSection.Department,
	|	TabularSection.ProductOwner
	|INTO BatchSideAndIntermediateRelease
	|FROM
	|	Document.ProductionStage2_2.BatchSideAndIntermediateRelease AS TabularSection
	|WHERE
	|	TabularSection.Ref IN (&ProductionStage)";
	
	QueryTexts.Add(QueryText);
	
	QueryText = 
	"SELECT
	|	TabularSection.Ref,
	|	TabularSection.Series,
	|	TabularSection.Products,
	|	TabularSection.Characteristic,
	|	TabularSection.Count,
	|	TabularSection.Recipient,
	|	TabularSection.DateOfTransaction,
	|	TabularSection.Department, 
	|	TabularSection.Purpose
	|INTO SavingMaterialsBatch
	|FROM
	|	Document.ProductionStage2_2.SavingMaterialsBatch AS TabularSection
	|WHERE
	|	TabularSection.Ref IN (&ProductionStage)";
	
	QueryTexts.Add(QueryText);
	
	TempTablesManager = New TempTablesManager;
	
	QueryText = ProductionManagement.CombineRequestTextsIntoPackage(QueryTexts);
	
	Query.Text = QueryText;
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("ProductionStage", StageList);
	
	Query.Execute();
	
	Return TempTablesManager;
	
EndFunction

&AtServerNoContext
Function AssignmentExists(Ref)
	
	Query = New Query(
		"SELECT
		|	TRUE
		|FROM
		|	Catalog.Assignments AS Assignments
		|WHERE
		|	Assignments.Ref = &Ref");
	Query.SetParameter("Ref", Ref);
	Return Not Query.Execute().IsEmpty();
	
EndFunction

&AtClientAtServerNoContext
Function WorkPlanningLinesAreHighlighted(Form, TSName)
	
	Result = False;
	
	If TSName = "SupplyWithMaterialsAndWorks"
		And Form.Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.PerformRM") Then
		
		Table = ObjectTableByName(Form.Object, TSName);
		
		For Each RowID In Form.Items[TSName].SelectedRows Do
			
			RowData = Table.FindByID(RowID);
			If RowData <> Undefined And RowData.WorkPlanning Then
				Result = True;
				Break;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region FillType

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
	
	FilterParameters = New Structure;
	
	CostTypes = ProductionClient.TypesOfCostsForChoosingCalculationArticle(TSName);
	If CostTypes.UBound() <> -1 Then
		FilterParameters.Insert("ExpenseType", CostTypes);
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", FilterParameters);
	FormParameters.Insert("MultipleChoice", False);
	
	CallbackDescription = New CallbackDescription("FillInTheCostingItemCompletion", ThisObject, TSName);
	
	OpenForm("Catalog.ProductCostElements.ChoiceForm", FormParameters,,,,, CallbackDescription);
	
EndProcedure

&AtClient
Procedure FillInTheCostingItemCompletion(ClosingResult, TSName) Export

	If ClosingResult = Undefined Then
		Return;
	EndIf;
	
	SelectedRows = Items[TSName].SelectedRows;
	TabularSection = Object[TSName];
	
	For Each RowID In SelectedRows Do
		
		CurrentData = TabularSection.FindByID(RowID);
		CurrentData.ProductCostElement = ClosingResult;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure FillInPricesByPriceKind(TSName)
	
	ClearMessages();
	SelectedRows = GetSelectedRowsInList(TSName);
	If Not ValueIsFilled(SelectedRows) Then
		Return;
	EndIf;
	If Not CheckBlockDocuments() Then
		Return;
	EndIf;
	
	ReferencesArrray = New Array;
	IDs = New Array;
	For Each String In SelectedRows Do
		
		RowData = ObjectTableByName(Object, TSName).FindByID(String);
		If (RowData.Manufactured Or RowData.Price <> 0)
			And RowData.UseTargetCost Then
			
			ReferencesArrray.Add(RowData.Ref);
			IDs.Add(String);
			
		EndIf;
		
	EndDo;
	
	If IDs.Count() = 0 Then
		
		MessageText = NStr("vi = 'Trong các dòng được tô sáng, không có vị trí có sẵn để điền theo dạng giá.';
							|ru = 'В выделенных строках отсутствуют позиции, доступные для заполнения по виду цен.';
							|en = 'There are no items available for population by a price type in the selected lines.'; fa = 'There are no items available for population by a price type in the selected lines.';
							|it = 'Nelle righe selezionate non ci sono voci disponibili per la compilazione per tipo di prezzi.';
							|pl = 'W wybranych wierszach brak pozycji, dostępnych do wypełnienia według cen.';
							|tr = 'Seçilen satırlarda, fiyat türüne göre doldurulabilecek pozisyon bulunmamaktadır.'");
		ShowMessageBox( , MessageText);
		
		Return;
	EndIf;
	
	Currency = Undefined;
	PriceKind = Undefined;
	For Each Ref In ReferencesArrray Do
		
		ObjectStage = ObjectIsCreatedByReference(ThisForm, Ref);
		
		If PriceKind = Undefined Or Currency = Undefined Then
			Currency = ObjectStage.Currency;
			PriceKind = ObjectStage.PriceKind;
			Continue;
		EndIf;
		
		If PriceKind <> ObjectStage.PriceKind Or Currency <> ObjectStage.Currency Then
			
			MessageText = NStr("vi = 'Các dòng được tô sáng sử dụng các dạng giá và / hoặc tiền tệ khác nhau, không thể điền.';
								|ru = 'В выделенных строках используются различные виды цен и/или валюты, заполнение не возможно.';
								|en = 'Different price types and/or currency kinds are used in the selected lines. Cannot populate.'; fa = 'Different price types and/or currency kinds are used in the selected lines. Cannot populate.';
								|it = 'Nelle righe selezionate vengono utilizzati diversi tipi di prezzi e/o valute, la compilazione non è possibile.';
								|pl = 'W wybranych wierszach są używane różne rodzaje cen i/lub waluty, wypełnienie nie jest możliwe.';
								|tr = 'Seçilen satırlarda, farklı fiyat türleri ve/veya para birimleri kullanılmaktadır, doldurma mümkün değildir.'");
			ShowMessageBox( , MessageText);
			
			Return;
		EndIf;
		
	EndDo;
	
	If Not ValueIsFilled(PriceKind) Then
		
		MessageText = NStr("vi = 'Trong các dòng được chọn, trường ""Dạng giá"" không được điền';
							|ru = 'В выделенных строках не заполнено поле ""Вид цены""';
							|en = '""Price type"" is required in selected lines'; fa = '""Price type"" is required in selected lines';
							|it = 'Nelle righe selezionate, il campo ""Tipo di prezzo"" non è compilato';
							|pl = 'W wybranych wierszach nie zostało wypełnione pole ""Rodzaj ceny""';
							|tr = 'Seçilen satırlarda ""Fiyat Türü"" alanı doldurulmadı'");
		ShowMessageBox( , MessageText);
		
		Return;
	EndIf;
	
	PricesCalculated = FillInPricesOfSelectedRowsByPriceTypeServer(TSName, PriceKind, Currency, IDs);
	SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, PriceKind);
	
EndProcedure

&AtClient
Procedure CompletionOfPlanningCalculationSelection(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	FillInPlanningCalculationsAndPricesOnServer(AdditionalParameters.RowsIDs, 
		Result,
		AdditionalParameters.Currency);
		
EndProcedure

&AtServer
Procedure FillInPlanningCalculationsAndPricesOnServer(RowsIDs = Undefined, StandardCostEstimate = Undefined, Currency)
	
	If RowsIDs <> Undefined Then
		
		RowsArray = New Array;
		For Each Id In RowsIDs Do
			
			RowOfProduct = Object.ManufacturedProducts.FindByID(Id);
			RowsArray.Add(RowOfProduct);
			
		EndDo;
		
	EndIf;
	
	FillParameters = Documents.StandardCosting2_2.DescriptionOfPriceFillingParameterInCollection();
	FillParameters.DocumentDate = CurrentSessionDate();
	FillParameters.DocumentCurrency = Currency;
	FillParameters.StandardCostEstimate = StandardCostEstimate;
	
	Documents.StandardCosting2_2.FillInPricesByCalculationInCollection(
		Object.ManufacturedProducts,
		RowsArray,
		FillParameters);
	
EndProcedure

#EndRegion

#EndRegion