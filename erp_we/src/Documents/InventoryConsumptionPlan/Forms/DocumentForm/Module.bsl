#Region Variables

&AtClient
Var CachedValues; // used by the mechanism for processing changes in PM details
&AtClient
Var RepeatCallBeforeRecording; // Used for non-modal questions before recording
&AtClient
Var IdleHandlerParameters;
&AtClient
Var TimeConsumingOperationForm;
&AtClient
Var NotificationAfterRecording Export;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	Planning.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	Parameters.Property("CurrentRow", CurrentRowWhenOpening);
	
	If Not ValueIsFilled(Object.Ref) Then
		
		UpdateRule = Object.FillingRule.Count() = 0;
		PlanViewParameters = GetPlanViewParameters(Object.PlanProfile, UpdateRule, 
														FillingRuleAddress, CustomSettingsAddress);
		FillPropertyValues(ThisForm, PlanViewParameters);
		FillPropertyValues(Object, PlanViewParameters,"FillInUsingFormula,Substitutional");
		
		ScriptParameters_ = Common.ObjectAttributesValues(Object.Scenario,
			"Periodicity, BudgetingScenario, DemandForMaterials");
		FillPropertyValues(Object, ScriptParameters_);
		
		If NumberOfPeriods > 0 And Not ValueIsFilled(Parameters.CopyingValue) Then
			PlanningClientServer.SetStartEndOfPlanPeriod(
				Object.Periodicity,
				Object.BeginOfPeriod,
				Object.PeriodEnding,
				CurrentSessionDate(),
				NumberOfPeriods);
		EndIf;
		OnReadCreateAtServer();
		
		SetVisibility1();
		
	EndIf;
	
	SaveNewPeriodServer();
	
	If ValueIsFilled(Object.FillingRule) Then
		For Each Rule In Object.FillingRule Do
			If Rule.FilterFromHeaderIsSet Then
				FilterIs_Specified = True;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	SetConditionalAppearanceOfCrossTable();
	
	AdditionalColumnName = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms().ColumnName;
	SetAvailabilityOfClipboardCommands();
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisForm);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisForm);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	If Object.Substitutional And PlanReplacementControlOnServer(Object.Ref) Then
		SkipPeriodClosingCheck = True;
		ThisObject.Write();
		ThisObject.Read();
		SkipPeriodClosingCheck = False;
	EndIf;
	
	PlanningClient.PositionByLine(ThisForm, "GroupGoods", "Goods", "GoodsByPeriod");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "DataProcessor.SelectGoodsToPurchaseDocument.Form.Form" Then
		
		ProcessingSelectionOfSelectionOnServer(CachedValues, ValueSelected);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	Planning.OnReadAtServer(ThisForm, CurrentObject);
	
	PlanViewParameters = GetPlanViewParameters(Object.PlanProfile, False, FillingRuleAddress, CustomSettingsAddress);
	FillPropertyValues(ThisForm, PlanViewParameters,, "NumberOfPeriods");
	
	OnReadCreateAtServer();
	
	SaveNewPeriodServer();
	
	SetVisibility1();
	
	// StandardSubsystems.PeriodClosingDates
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	// End StandardSubsystems.PeriodClosingDates
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.InventoryConsumptionPlan.DocumentForm.Event.BeforeWrite");
	
	UpdateRelatedItemDetails(Object, ThisForm);
	
	WriteParameters.Insert("CachedValues", CachedValues);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	CopyFromCrossTable(WriteParameters["CachedValues"], CurrentObject);
	
	Planning.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

	If Object.FillInUsingFormula Then
		RecordAdditionalParameters(CurrentObject);
	EndIf;

	If SkipPeriodClosingCheck Then
		CurrentObject.AdditionalProperties.Insert("SkipPeriodClosingCheck");
	EndIf;

	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement

	FillInServiceDetailsForProductInCollection();

	If Object.FillInUsingFormula Then
		ReadMoreParameters(CurrentObject);
	EndIf;

	SetVisibility1();

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

	Planning.CheckExistenceOfAlreadyCreatedPlans(Object, "InventoryConsumptionPlan");
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "CopyingLinesToClipboard" Then
		
		SetAvailabilityOfClipboardCommandsOnClient();
		
	ElsIf EventName = "WorkingWithExcelClient_DownloadFromExcel"
		And Parameter.FormUniqueID = UUID Then

		LoadFromExcelOnClient(Parameter.DownloadData);
		
	EndIf;
	
	// StandardSubsystems.Properties
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If Object.CrossTable Then
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("TablePresentation",NStr("vi = 'Hàng hóa';
															|ru = 'Товары';
															|en = 'Goods'; fa = 'کالاها';
															|it = 'Merci';
															|pl = 'Goods';
															|tr = 'Ürünler'"));
		StructureOfActions.Insert("TablePath","GoodsByPeriod");
		StructureOfActions.Insert("FillInProducts_1");
		StructureOfActions.Insert("FillInWHCharacteristic");
		If FillInWarehouseInTabularForm Then
			StructureOfActions.Insert("FillInWarehouseInTabularForm");
		EndIf;
		
		CheckParameters = New Structure;
		CheckParameters.Insert("TimeIntervals", ThisObject["TimeIntervals"].Unload(New Structure("Active_", True)));
		CheckParameters.Insert("FieldPrefix", "Count_");
		CheckParameters.Insert("FieldName", "NumberOfPackages");
		StructureOfActions.Insert("CheckingQuantityByPeriod", CheckParameters);
		
		StructureOfActions.Insert("GroupFields", "Products, Characteristic, Purpose, Package, Warehouse");
		
		Planning.ProcessingFormFillVerification(GoodsByPeriod, StructureOfActions, Cancel, 
			CheckedAttributes, Object.CrossTable);
		
	Else
		
		NotCheckedAttributeArray.Add("GoodsByPeriod");
		
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_InventoryConsumptionPlan", , Object.Ref);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	If NotificationAfterRecording <> Undefined Then
	
		RunCallback(NotificationAfterRecording, True);
		NotificationAfterRecording = Undefined;
	
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	If Exit Then
		Return;
	EndIf;
	
	If Modified Then
		If PlanReplacementControlOnServer(Object.Ref) Then
			ThisObject.Read();
			ThisObject.Write();
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ScenarioOnChange(Item)
	
	Notification = New CallbackDescription("ScenarioOnChangeCompletion", ThisObject);
	
	PlanningClient.ShowQuestionWhenScriptChanges(ThisForm, Notification);
	
EndProcedure

&AtClient
Procedure PlanProfileOnChange(Item)
	
	Notification = New CallbackDescription("PlanProfileOnChangeCompletion", ThisObject);
	
	PlanningClient.ShowQuestionWhenChangingPlanView(ThisForm, Notification);
	
EndProcedure

&AtClient
Procedure BeginOfPeriodOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	Notification = New CallbackDescription("WhenChangingPeriodsOnClient", ThisObject);
	PlanningClient.WhenChangingPlanPeriod(ThisForm, "GoodsByPeriod", Notification);
	
EndProcedure

&AtClient
Procedure PeriodEndingOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	Notification = New CallbackDescription("WhenChangingPeriodsOnClient", ThisObject);
	PlanningClient.WhenChangingPlanPeriod(ThisForm, "GoodsByPeriod", Notification);
	
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	
	If Object.Substitutional Then
		WhenChangingPeriodsOnServer();
	EndIf;
	UpdateRelatedItemDetails(Object, ThisForm);
	
EndProcedure

&AtClient
Procedure PurposeOnChange(Item)
	
	If Object.Substitutional Then
		WhenChangingPeriodsOnServer();
	EndIf;
	UpdateRelatedItemDetails(Object, ThisForm);
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	If Object.Substitutional Then
		WhenChangingPeriodsOnServer();
	EndIf;
	UpdateRelatedItemDetails(Object, ThisForm);
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	If Object.Substitutional Then
		WhenChangingPeriodsOnServer();
	EndIf;
EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	If Not ValueIsFilled(Object.Status) Then
		Object.Status = PredefinedValue("Enum.PlanStatuses.RolledBack_");
	EndIf;
	If Object.Substitutional Then
		WhenChangingPeriodsOnServer();
	EndIf;
EndProcedure

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If CurrentPage.Name = "GroupAdditionalAttributes"
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	If CurrentPage <> Items.GroupPages.ChildItems.GroupGoods Or Not Object.CrossTable Then
	
		TotalByLineByColumn = "";
	
	EndIf;
	
	If Object.Substitutional 
		And (Object.CrossTable And GoodsByPeriod.Count() = 0
		Or Not Object.CrossTable And Object.Goods.Count() = 0)
		And Items.GroupPages.CurrentPage = Items.GroupGoods Then
		FillInDataForReplacement();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsOnChange(Item)
	
	Object.FilledAutomatically = False;
	
	CalculateNumberOfRows(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	If NewRow Then
	
		UpdateRelatedItemDetails(Object, ThisForm);
	
	EndIf;
	
	CalculateNumberOfRows(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	
	CalculateTotals_(ThisForm, False);
	
EndProcedure

&AtClient
Procedure GoodsChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	If TypeOf(ValueSelected) = Type("CatalogRef.InventoryConsumptionPlanAttachedFiles") Then
		
		DownloadFromExcelOnClient(ValueSelected);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsOnActivateRow(Item)
	If Not Object.FillInUsingFormula And Items.Goods.SelectedRows.Count() > 0 Then
		UBound = Items.Goods.SelectedRows.UBound();
		Details = PlanningClient.GenerateDecryption(Object.Goods.FindByID(Items.Goods.SelectedRows[UBound]));
	Else
		Details = "";
	EndIf;
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure(
		"Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("CheckCharacteristicsByOwner",         CurrentRow.Characteristic);
	StructureOfActions.Insert("FillInArticleAttribute",                    New Structure(
		"Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_",            New Structure(
		"Products", "ItemsType"));
	StructureOfActions.Insert("CheckFillPackageByOwner",      CurrentRow.Package);

	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure(
		"FormName, TabularSectionName", FormName, "Goods"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

	PlanningClientServer.SetFormulaPresentation(ThisObject, CurrentRow);
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;

	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure(
		"FormName, TabularSectionName", FormName, "Goods"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

	CalculateTotals_(ThisForm);
	
	CurrentRow.Details = String(CurrentRow.NumberOfPackages);
	Details = PlanningClient.GenerateDecryption(CurrentRow);
	
	If CurrentRow.Property("Deviation") And ValueIsFilled(CurrentRow.Formula) Then
		CalculationResult = PlanningClient.CalculateByFormula(
			CurrentRow.Formula, CurrentRow, Undefined, Undefined);
		CurrentRow.Deviation = CalculationResult.Result - CurrentRow.NumberOfPackages;
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsCanceledOnChange(Item)
	
	CalculateTotals_(ThisForm, False);
	
EndProcedure

&AtClient
Procedure GoodsDateOfShipmentOnChange(Item)
	If Object.Substitutional
		And Object.Posted
		And SubstitutedPeriods.Count() > 0 Then
		CurrentData = Items.Goods.CurrentData;
		DateOfReceiptBeginningOfPeriod = PlanningClientServerCached.CalculateStartDateOfPeriod(
			CurrentData.DateOfShipment, Object.Periodicity);
		Filter = New Structure("SubstitutedPeriod", DateOfReceiptBeginningOfPeriod);
		SubstitutedStringPeriod = SubstitutedPeriods.FindRows(Filter);
		If SubstitutedStringPeriod.Count() > 0 Then
			CurrentData.Substituted = SubstitutedStringPeriod[0].Substituted;
			CurrentData.SubstitutedToOrder = SubstitutedStringPeriod[0].SubstitutedToOrder;
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoodsByPeriod

&AtClient
Procedure GoodsByPeriodOnChange(Item)
	
	PlanningClientServer.CalculateCrossTableRowNumber(ThisForm, "GoodsByPeriod");

	Object.FilledAutomatically = False;

	TotalNumberOfRowsBeforeChange = GoodsLineQuantity;

	CalculateNumberOfRows(ThisForm);

	If GoodsLineQuantity <> TotalNumberOfRowsBeforeChange Then
		CalculateTotals_(ThisForm, False);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsByPeriodOnEditEnd(Item, NewRow, CancelEdit)
	
	If NewRow Then
	
		UpdateRelatedItemDetails(Object, ThisForm);
	
	EndIf;
	
	CalculateNumberOfRows(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsByPeriodOnActivateCell(Item)
	
	AttachIdleHandler("ProductsByPeriodWhenActivatingCellOnClient", 0.5, True);
	
EndProcedure

&AtClient
Procedure GoodsByPeriodChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	If TypeOf(ValueSelected) = Type("CatalogRef.InventoryConsumptionPlanAttachedFiles") Then
		
		DownloadFromExcelOnClient(ValueSelected);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsByPeriodProductsOnChange(Item)
	
	CurrentRow = Items.GoodsByPeriod.CurrentData;

	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure(
		"Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("CheckCharacteristicsByOwner",         CurrentRow.Characteristic);
	StructureOfActions.Insert("FillInArticleAttribute",                    New Structure(
		"Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_",            New Structure(
		"Products", "ItemsType"));
	StructureOfActions.Insert("CheckFillPackageByOwner",      CurrentRow.Package);

	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure(
		"FormName, TabularSectionName", FormName, "GoodsByPeriod"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	PlanningClientServer.SetFormulaPresentation(ThisObject, CurrentRow);
	
EndProcedure

&AtClient
Procedure GoodsByPeriodPackageOnChange(Item)
	
	CurrentRow = Items.GoodsByPeriod.CurrentData;
	
	StructureOfActions = New Structure;
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

// Attachable when the quantity changes.
// 
// Parameters:
//  Item - FormField
&AtClient
Procedure Attachable_WhenChangingQuantity(Item)
	
	RowOfGoods = Items.GoodsByPeriod.CurrentData;
	
	WhenChangingAmountOfRowSum(Object, ThisForm, RowOfGoods);
	
	If Object.FillInUsingFormula Then
		WhenChangingQuantityDeviation(RowOfGoods);
	EndIf;
	
	If Not Object.FillInUsingFormula Then
		TheCurrentNameOfTheColumn = StringFunctionsClientServer.SplitStringIntoSubstringsArray(Item.Name, "GoodsByPeriod" + "Count_")[1];
		
		RowOfGoods["Details_" + TheCurrentNameOfTheColumn] = String(RowOfGoods["Count_" + TheCurrentNameOfTheColumn]);
		Details = PlanningClient.GenerateDecryption(RowOfGoods, "Details_" + TheCurrentNameOfTheColumn);
	EndIf;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(RowOfGoods, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisForm, False);
	
	GoodsByPeriodOnActivateCell(Items.GoodsByPeriod);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)
	FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)
	FilesOperationsClient.PreviewFieldDrag(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)
	FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure
// End StandardSubsystems.Properties

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(
		Command,
		ThisObject,
		Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure SelectGoods(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.InventoryConsumptionPlan.DocumentForm.Command.SelectGoods");

	If Not CheckHeaderFilling() Then
		Return;
	EndIf;

	FormParameters = New Structure;

	FormParameters.Insert("SelectionModeWithoutAmountParameters", True);
	FormParameters.Insert("HideTheViewPriceColumn",            True);
	FormParameters.Insert("HideTheItemPricesCommand",   True);

	If FillInWarehouse Then
		FormParameters.Insert("Warehouse", Object.Warehouse);
	EndIf;
	If FillInWarehouseInTabularForm Then
		FormParameters.Insert("SelectionModeUseWarehousesInTabularSection", True);
		FormParameters.Insert("AllWarehouseBalance", True);
	EndIf;
	
	FilterByProductType = ProductsClientServer.SelectionByProductMultiTurnContainer(False);
	FilterByProductType.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
	
	FormParameters.Insert("Title",               NStr("vi = 'Chọn hàng hóa';
														|ru = 'Подбор товаров';
														|en = 'Pick goods'; fa = 'انتخاب کالاها';
														|it = 'Selezione delle merci';
														|pl = 'Wybór towarów';
														|tr = 'Ürünlerin seçimi'"));
	FormParameters.Insert("Date",                    Object.Date);
	FormParameters.Insert("Document",                Object.Ref);
	FormParameters.Insert("FilterByProductType", FilterByProductType);
	FormParameters.Insert("HideManualDiscounts",    True);

	OpenForm("DataProcessor.SelectGoodsToPurchaseDocument.Form", FormParameters, ThisForm, UUID);
	
EndProcedure

&AtClient
Procedure ConfigureAndPopulateAccordingToTheFillingRule(Command)
	
	If Not CheckHeaderFilling() Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	
	FormParameters.Insert("UpdateAdd",				Object.UpdateAdd);
	FormParameters.Insert("FillingRuleAddress",			FillingRuleAddress);
	FormParameters.Insert("ChangeResultTo",				Object.ChangeResultTo);
	FormParameters.Insert("RoundingPrecision",				Object.RoundingPrecision);
	FormParameters.Insert("Periodicity",					Object.Periodicity);
	FormParameters.Insert("PlanProfile",							Object.PlanProfile);
	FormParameters.Insert("CustomSettingsAddress",	CustomSettingsAddress);
	If Not Object.CrossTable Then
		FormParameters.Insert("AllocateByWorkdays",	Object.AllocateByWorkdays);
	EndIf;
	FormParameters.Insert("ReadOnly",					ReadOnly);
	FormParameters.Insert("NumberOfPeriods",				NumberOfPeriods);
	FormParameters.Insert("Filter", PlanningClientServer.SelectionForSampling(FilterParameters(ThisObject), PlanViewParameters(ThisObject)));
	FormParameters.Insert("BeginOfPeriod",                    Object.BeginOfPeriod);
	FormParameters.Insert("PeriodEnding",                 Object.PeriodEnding);
	
	Notification = New CallbackDescription("ConfigureAndPopulateAccordingToTheFillingRuleCompletion", ThisObject);
	
	OpenForm("Catalog.PlanningDataSources.Form.FormFilling", 
		FormParameters,
		ThisForm,
		UUID,
		,
		,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure FillInAccordingToTheFillingRule(Command)
	
	If Not CheckHeaderFilling() Then
		Return;
	EndIf;
	
	Settings = New Structure;
	Settings.Insert("FillInRule", True);
	
	FillInDocument(Settings);
	
EndProcedure

&AtClient
Procedure FillInDataForReplacement()
	
	If Not CheckHeaderFilling() Then
		Return;
	EndIf;
	
	Settings = New Structure;
	Settings.Insert("FillInForReplacement");
	
	FillInDocument(Settings);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm);
	
EndProcedure

&AtClient
Procedure SplitRow(Command)
	
	FormTable  = Items.Goods;
	TableData = Object.Goods;
	
	Notification = New CallbackDescription("SplitRowCompletion", ThisObject);
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, Notification);
	
EndProcedure

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export
	
	CurrentRow = Items.Goods.CurrentData;
	
	If NewRow <> Undefined Then
		
		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
		CurrentRow.Details = "";
		NewRow.Details = "";
		
		UpdateRelatedItemDetails(Object, ThisForm);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure InsertRows(Command)
	
	If Object.CrossTable Then
		
		DescriptionOfTheAlert = New CallbackDescription("SwitchPeriodsToRowsCompletion", ThisObject);
		
		ShowQueryBox(
			DescriptionOfTheAlert, 
			NStr("vi = 'Có thể sao chép và dán các dòng trong chế độ ""Kỳ trong dòng"". Chuyển chế độ?';
				|ru = 'Копирование и вставка строк возможны в режиме ""Периоды в строках"". Переключить режим?';
				|en = 'Copying & pasting lines is available in the ""Periods in lines"" mode. Switch modes?'; fa = 'Copying & pasting lines is available in the ""Periods in lines"" mode. Switch modes?';
				|it = 'È possibile copiare e incollare le righe in modalità ""Periodi nelle righe"". Cambiare la modalità?';
				|pl = 'Kopiowanie i wklejanie wierszy są możliwe w trybie ""Okresy w wierszach"". Przełączyć tryb?';
				|tr = 'Satırın kopyalanması ve yapıştırılması işlemi ""Satırlardaki dönemler"" modunda gerçekleştirilebilir. Bu mod açılsın mı?'"), 
			QuestionDialogMode.YesNo);
		
		Return;
		
	Else
		
		NumberOfProductsBeforeInsertion = Object.Goods.Count();
		
		GetLinesFromClipboard();
		
		NumberOfInserted = Object.Goods.Count()-NumberOfProductsBeforeInsertion;
		ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
	
	EndIf;
	
EndProcedure

&AtClient
Procedure CopyRows(Command)
	
	If Object.CrossTable Then
		DescriptionOfTheAlert = New CallbackDescription("SwitchPeriodsToRowsCompletion", ThisObject);
		
		ShowQueryBox(
			DescriptionOfTheAlert, 
			NStr("vi = 'Có thể sao chép và dán các dòng trong chế độ ""Chu kỳ trong dòng"". Chuyển chế độ?';
				|ru = 'Копирование и вставка строк возможны в режиме ""Периоды в строках"". Переключить режим?';
				|en = 'Copying & pasting lines is available in the ""Periods in lines"" mode. Switch modes?'; fa = 'Copying & pasting lines is available in the ""Periods in lines"" mode. Switch modes?';
				|it = 'È possibile copiare e incollare le righe in modalità ""Periodi nelle righe"". Cambiare la modalità?';
				|pl = 'Kopiowanie i wklejanie wierszy są możliwe w trybie ""Okresy w wierszach"". Przełączyć tryb?';
				|tr = 'Satırın kopyalanması ve yapıştırılması işlemi ""Satırlardaki dönemler"" modunda gerçekleştirilebilir. Bu mod açılsın mı?'"), 
			QuestionDialogMode.YesNo);
		
		Return;
	Else
		FormTable = Items.Goods;
	EndIf;
	
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(FormTable) Then
		CopyLinesOnServer();
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(
			FormTable.SelectedRows.Count());
	EndIf;
	
EndProcedure

&AtClient
Procedure SetDateInterval(Command)
	
	Notification = New CallbackDescription(
		"SetDateIntervalCompletion",
		ThisObject);
		
	TMCommonUseClient.EditPeriod(
		Object, 
		New Structure("StartDate, EndDate", "BeginOfPeriod", "PeriodEnding"),
		Notification);
	
EndProcedure

#Region ImportDataFromFile

&AtClient
Procedure LoadFromFile(Command)
	AdditionalParameters = PlanningClient.AdditionalParametersForDownloadingFromFile();
	AdditionalParameters.PlanType               = "InventoryConsumptionPlan";
	AdditionalParameters.AssignmentsAreUsed = FillInAssignmentInTabularForm;
	AdditionalParameters.WarehousesAreUsed     = FillInWarehouseInTabularForm;
	
	AdditionalParameters.AvailableProductTypes = ProductsClientServer.SelectionByProductMultiTurnContainer(False);
	
	If Object.CrossTable Then
		AdditionalParameters.CrossTable = True;
		AdditionalParameters.TimeIntervals = ThisObject["TimeIntervals"];
	EndIf;
	
	ShowUploadFormFromFile(AdditionalParameters);
	
EndProcedure

#EndRegion

&AtClient
Procedure ExportToExcel(Command)
	
	If Not CheckHeaderFilling() Then
		Return;
	EndIf;
	
	ProcessingWithExcelClient.ExportToExcel(ThisForm);
	
EndProcedure

&AtClient
Procedure ImportFromExcel(Command)
	
	If Not CheckHeaderFilling() Then
		Return;
	EndIf;
	
	ProcessingWithExcelClient.SelectAttachedExcelFile(ThisForm, ?(Object.CrossTable, "GoodsByPeriod", "Goods"));
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure SwitchPeriodsToColumns(Command)
	
	If Not Object.CrossTable Then
		Cancel = False;
		CheckParameters = New Structure;
		CheckParameters.Insert("TSName",                    "Goods");
		CheckParameters.Insert("PresentationOfTS",          NStr("vi = 'Hàng hóa';
																|ru = 'Товары';
																|en = 'Goods'; fa = 'کالاها';
																|it = 'Merci';
																|pl = 'Towary';
																|tr = 'Ürünler'"));
		CheckParameters.Insert("Periodicity",            Object.Periodicity);
		CheckParameters.Insert("StartDate",               Object.BeginOfPeriod);
		CheckParameters.Insert("EndDate",            Object.PeriodEnding);
		CheckParameters.Insert("NameOfPeriodDateField",       "DateOfShipment");
		CheckParameters.Insert("PresentationOfPeriodDate", NStr("vi = 'Ngày giao hàng';
																|ru = 'Дата отгрузки';
																|en = 'Shipment date'; fa = 'تاریخ ارسال';
																|it = 'Data di spedizione';
																|pl = 'Data wysyłki';
																|tr = 'Sevkiyat tarihi'"));
		CheckParameters.Insert("KTCHPathPrefix",           "Object.");
		
		PlanningClientServer.CheckDateOfTSPeriod(Object, Cancel, CheckParameters);
		
		If Cancel Then
			Buttons = New ValueList;
			Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Xóa bỏ dòng';
													|ru = 'Удалить строки';
													|en = 'Remove lines'; fa = 'Remove lines';
													|it = 'Cancellare le righe';
													|pl = 'Usuń wiersze';
													|tr = 'Satırları sil'"));
			Buttons.Add(DialogReturnCode.No, NStr("vi = 'Hủy bỏ';
													|ru = 'Отменить';
													|en = 'Cancel'; fa = 'انصراف';
													|it = 'Annullare';
													|pl = 'Cancel';
													|tr = 'İptal et'"));
			QueryText = NStr("vi = 'Tại các dòng của danh sách ""Hàng hóa"" đã chỉ ra ngày ngoài biên lập kế hoạch - các dòng sẽ bị xóa. Xóa dòng?';
							|ru = 'В строках списка ""Товары"" указаны даты за границами планирования - строки будут удалены. Удалить строки?';
							|en = 'Dates outside the planning fences are specified in lines of the Item list. Lines will be deleted. Delete the lines?'; fa = 'Dates outside the planning fences are specified in lines of the Item list. Lines will be deleted. Delete the lines?';
							|it = 'Nelle righe dell''elenco ""Merci"" le date vanno oltre i limiti della pianificazione - le righe verranno eliminate. Eliminare le righe?';
							|pl = 'W wierszach listy ""Towary"" znajdują się daty wykraczające poza granice planowania - wiersze zostaną usunięte. Usunąć wiersze?';
							|tr = '""Ürünler"" listesinin satırlarında planlama sınırları için belirtilen tarihler. Satırlar silinecek. Silinsin mi?'");
			Notification = New CallbackDescription("SwitchPeriodsToColumnsCompletion", ThisObject);
			ShowQueryBox(Notification, QueryText, Buttons);
			Return;
			
		EndIf;
		
		SwitchPeriodsToColumnsOnServer(CachedValues);
		
	EndIf;
	
	SetCrossTableTag(ThisForm);
	
EndProcedure

&AtClient
Procedure SwitchPeriodsToRows(Command)
	
	SwitchPeriodsToRowsOnServer(CachedValues);
	
EndProcedure

&AtServer
Procedure SwitchPeriodsToRowsOnServer(CachedValues)
	
	If Object.CrossTable Then
		CopyFromCrossTable(CachedValues, Object);
		Object.CrossTable = False;
		FillInServiceDetailsForProductInCollection();
	EndIf;
	
	SetCrossTableTag(ThisForm);
	
EndProcedure

&AtClient
Procedure AddGoodsByPicking(Command)
	
	If Not CheckHeaderFilling() Then
		Return;
	EndIf;
	
	AddProductsBySelectionOnClient();
	
EndProcedure

&AtClient
Procedure FillInTheProducts(Command)
	
	If Not CheckHeaderFilling() Then
		Return;
	EndIf;
	
	If DisableEditingOfPopulationSettings Then
		SetUpFormulaAndFillIn(SettingsStructure, Undefined);
		Return;
	EndIf;
	
	PlanType = PredefinedValue("Enum.TypesOfPlans.InventoryConsumptionPlan");
	FilterParameters = FilterParameters(ThisForm);
	PlanViewParameters = PlanViewParameters(ThisForm);
	
	FilterIndicators = PlanningClientServer.SelectionToFillInIndicators(
		PlanType, FilterParameters, PlanViewParameters);
	
	FormParameters = New Structure();
	FormParameters.Insert("PlanType",							PlanType);
	FormParameters.Insert("PeriodStartPlan",				Object.BeginOfPeriod);
	FormParameters.Insert("PeriodEndPlan",				Object.PeriodEnding);
	FormParameters.Insert("Periodicity",					Object.Periodicity);
	FormParameters.Insert("OperatorsTreeStorageAddress",	OperatorsTreeStorageAddress);
	FormParameters.Insert("AdditionalFields",				AdditionalFields);
	FormParameters.Insert("SettingsStructure",				AdditionalSettings(SettingsStructure));
	FormParameters.Insert("Owner",							Object.Ref);
	FormParameters.Insert("Filter",							FilterIndicators);
	
	Notification = New CallbackDescription("SetUpFormulaAndFillIn",ThisObject);
	
	OpenForm("Catalog.PlanProfiles.Form.SettingsForm", 
		New Structure("SettingsStructure",FormParameters), 
		ThisForm,
		UUID,
		,
		,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure FillInIndicators(Command)
	
	If Not CheckHeaderFilling() Then
		Return;
	EndIf;

	FormParameters = New Structure;
	FormParameters.Insert("PeriodStartPlan",    Object.BeginOfPeriod);
	FormParameters.Insert("PeriodEndPlan", Object.PeriodEnding);
	FormParameters.Insert("Periodicity",        Object.Periodicity);
	FormParameters.Insert("SettingsStructure",    AdditionalSettings(SettingsStructure));
	FormParameters.Insert("Owner",             Object.Ref);
	
	If StrFind(FormParameters.SettingsStructure.Formula , "PlannedStartBalance")<>0
		Or StrFind(FormParameters.SettingsStructure.Formula , "PlannedFinalBalances")<>0
		Or StrFind(FormParameters.SettingsStructure.Formula , "PlannedFinalDeficit")<>0 Then
		AdjustOffsetAndFill(FormParameters.SettingsStructure, Undefined);
	Else
		Notification = New CallbackDescription("AdjustOffsetAndFill", ThisObject);
		
		OpenForm("Catalog.PlanProfiles.Form.SettingsFormOfTimeShift", 
			New Structure("SettingsStructure",FormParameters), 
			ThisForm,
			UUID,
			,
			,
			Notification,
			FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeByPercentage(Command)
	
	If Not CheckHeaderFilling() Then
		Return;
	EndIf;
	
	Notification = New CallbackDescription("ChangeByPercentageCompletion", ThisObject);
	
	PlanningClient.ChangeFormulaToPercentage(
		ThisForm, 
		?(Object.CrossTable, GoodsByPeriod, Object.Goods), 
		?(Object.CrossTable, "GoodsByPeriod", "Goods"),
		Notification);
	
EndProcedure

&AtClient
Procedure RoundOffQuantity(Command)
	
	If Not CheckHeaderFilling() Then
		Return;
	EndIf;
	
	Notification = New CallbackDescription("RoundOffQuantityCompletion", ThisObject);
	
	PlanningClient.RoundUpFormula(
		ThisForm, 
		?(Object.CrossTable, GoodsByPeriod, Object.Goods), 
		?(Object.CrossTable, "GoodsByPeriod", "Goods"),
		Notification);
	
EndProcedure

&AtClient
Procedure SpecifyArbitraryFormula(Command)
	
	If Not CheckHeaderFilling() Then
		Return;
	EndIf;
	
	TablePeriods = ThisForm.TimeIntervals; // See Planning.TablePeriods
	ActivePeriods = TablePeriods.FindRows(New Structure("Active_", True));
	
	For Each Period In ActivePeriods Do
		
		AdditionalParameters = New Structure("ColumnName",Period.ColumnName);
		
		If Object.CrossTable And ActivePeriods.Count() > 1 Then
			
			If Items.GoodsByPeriod.CurrentData = Undefined Then
				Return;
			EndIf;
			
			CurElementName = Items.GoodsByPeriod.CurrentItem.Name;
			
			If StrFind(CurElementName, "GoodsByPeriod" + "Count_") = 0 Then
				ShowUserNotification(NStr("vi = 'Hãy kích hoạt cột có kỳ';
											|ru = 'Активируйте колонку с периодом';
											|en = 'Activate column with period'; fa = 'Activate column with period';
											|it = 'Attivavate la colonna del periodo';
											|pl = 'Aktywuj kolumnę okresu';
											|tr = 'Dönemlerle beraber sütunları etkinleştir'"));
				Return;
			EndIf;
			
			If CurElementName = "GoodsByPeriod" + "Count_"+Period.ColumnName Then
				
				QueryText = NStr("vi = 'Đặt công thức đối với tất cả các kỳ?';
								|ru = 'Установить формулу для всех периодов?';
								|en = 'Set the formula for all periods?'; fa = 'Set the formula for all periods?';
								|it = 'Impostare la formula per tutti i periodi?';
								|pl = 'Ustawić ""ТаблицаПериодов"" dla wszystkich okresów?';
								|tr = 'Formül tüm dönemler için kurulsun mu?'");
				
				ButtonsList = New ValueList;
				ButtonsList.Add(DialogReturnCode.Yes,		NStr("vi = 'Có, đối với tất cả';
																	|ru = 'Да, для всех';
																	|en = 'Yes, for all'; fa = 'Yes, for all';
																	|it = 'Si, per tutti';
																	|pl = 'Tak, dla wszystkich';
																	|tr = 'Evet, tümü için'"));
				ButtonsList.Add(DialogReturnCode.No,		NStr("vi = 'Chỉ';
																|ru = 'Только';
																|en = 'Only'; fa = 'Only';
																|it = 'Solo';
																|pl = 'Only';
																|tr = 'Sadece'") + " " + Period.Title);
				ButtonsList.Add(DialogReturnCode.Cancel,	NStr("vi = 'Hủy bỏ';
																|ru = 'Отмена';
																|en = 'Cancel'; fa = 'انصراف';
																|it = 'Annulla';
																|pl = 'Anuluj';
																|tr = 'İptal'"));
				
				CallbackDescription = New CallbackDescription(
					"AfterQuestionSetArbitraryFormula", ThisObject, AdditionalParameters);
				
				ShowQueryBox(CallbackDescription, QueryText, ButtonsList);
				
			EndIf;
			
		Else
			
			If (Object.CrossTable And Items.GoodsByPeriod.CurrentData = Undefined) 
					Or (Not Object.CrossTable And Items.Goods.CurrentData = Undefined) Then
				Return;
			EndIf;
			
			AfterQuestionSetArbitraryFormula(DialogReturnCode.No, AdditionalParameters);
			
			Break;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure DeleteEmptyLines(Command)
	
	DeleteBlankLinesOnServer();
	
EndProcedure

&AtClient
Procedure FillInAWarehouseByTheValue(Command)
	
	SelectedRows = ?(Object.CrossTable, Items.GoodsByPeriod.SelectedRows,Items.Goods.SelectedRows);
	GoodsTable = ?(Object.CrossTable, GoodsByPeriod, Object.Goods);
	
	If WarehousesClient.CheckPossibilityOfFillingWarehousesInTablePart(Object, GoodsTable, NStr("vi = 'Hàng hóa';
																								|ru = 'Товары';
																								|en = 'Goods'; fa = 'کالاها';
																								|it = 'Articoli';
																								|pl = 'Goods';
																								|tr = 'Ürünler'"), SelectedRows) Then
		FilterStructure1 = New Structure("IsFolder", False);
		ParametersStructure = New Structure("Filter, ChoiceFoldersAndItems", FilterStructure1, FoldersAndItemsUse.Items);
		
		OpenForm(
			"Catalog.Warehouses.ChoiceForm", 
			ParametersStructure, 
			ThisForm,
			UUID,
			,
			,
			New CallbackDescription("FillInByCompletionValue",
				PlanningClient,
				New Structure("SelectedRows, GoodsTable, Column", SelectedRows, GoodsTable, "Warehouse")), 
				FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInAssignmentByValue(Command)
	
	SelectedRows = ?(Object.CrossTable, Items.GoodsByPeriod.SelectedRows,Items.Goods.SelectedRows);
	GoodsTable = ?(Object.CrossTable, GoodsByPeriod, Object.Goods);
	
	FilterStructure1 = New Structure("IsFolder", False);
	ParametersStructure = New Structure("Filter, ChoiceFoldersAndItems", FilterStructure1, FoldersAndItemsUse.Items);
	
	OpenForm(
		"Catalog.Assignments.ChoiceForm", 
		ParametersStructure, 
		ThisForm,
		UUID,
		,
		,
		New CallbackDescription("FillInByCompletionValue",
				PlanningClient,
				New Structure("SelectedRows, GoodsTable, Column", SelectedRows, GoodsTable, "Purpose")), 
				FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();

	//

	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm);

	//

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "GoodsByPeriodProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "GoodsByPeriod.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm,
		"GoodsByPeriodCharacteristic", 
		"GoodsByPeriod.ItemVariantsAreUsed");

	//
	
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisForm,
		"GoodsByPeriodPurpose", 
		"GoodsByPeriod.ItemsType", 
		False);
	
	//
	
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisForm,,False);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Goods.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Canceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Goods.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Substituted");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	//
	
	ConditionalDesignParameters = WarehousesServer.ParametersOfConditionalAppearanceOfVHFWarehouseByItemType();
	ConditionalDesignParameters.Form = ThisObject;
	ConditionalDesignParameters.ToCheckWhetherWarehouseIsFull = True;
	WarehousesServer.SetConditionalAppearanceOfVHFWarehouseByTypeOfItem(ConditionalDesignParameters);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsWarehouse.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	ValueList.Add(Enums.ItemsTypes.ReusablePackage);
	ItemFilter.RightValue = ValueList;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Warehouse");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	ConditionalDesignParameters = WarehousesServer.ParametersOfConditionalAppearanceOfVHFWarehouseByItemType();
	ConditionalDesignParameters.Form = ThisObject;
	ConditionalDesignParameters.NameOfWarehouseInputField = Items.GoodsByPeriodWarehouse.Name;
	ConditionalDesignParameters.NameOfItemTypeField = "GoodsByPeriod.ItemsType";
	ConditionalDesignParameters.ToCheckWhetherWarehouseIsFull = True;
	ConditionalDesignParameters.NameOfVTCHWarehouseField = "GoodsByPeriod.Warehouse";

	WarehousesServer.SetConditionalAppearanceOfVHFWarehouseByTypeOfItem(ConditionalDesignParameters);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsByPeriodWarehouse.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("GoodsByPeriod.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	ValueList.Add(Enums.ItemsTypes.ReusablePackage);
	ItemFilter.RightValue = ValueList;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("GoodsByPeriod.Warehouse");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceOfCrossTable()
	
	If Not Object.CrossTable Then
		Return;
	EndIf;
	
	CurrentFont = Items.GoodsByPeriod.Font;
	StrikethroughFont = New Font(CurrentFont,,,,,,True);
	
	ActivePeriods = ThisObject["TimeIntervals"].FindRows(New Structure("Active_", True));
	ThisIsOnePeriod = ActivePeriods.Count() = 1;
	For Each Period In ActivePeriods Do
		If Not Period.Active_ Then
			Continue;
		EndIf;
		
		//
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField("GoodsByPeriod" + "Count_" + Period.ColumnName);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("GoodsByPeriod.Canceled_"+ Period.ColumnName);
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
		Item.Appearance.SetParameterValue("Font", StrikethroughFont);
		
		//
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField("GoodsByPeriod" + "Count_" + Period.ColumnName);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("GoodsByPeriod.Substituted_"+ Period.ColumnName);
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
		
	EndDo;
	
EndProcedure

// StandardSubsystems.Properties
&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	PropertyManager.FillAdditionalAttributesInForm(ThisObject);
EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure
&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
	
EndProcedure
// End StandardSubsystems.Properties

&AtClient
Procedure SetDateIntervalCompletion(Period, AdditionalParameters) Export
	
	Notification = New CallbackDescription("WhenChangingPeriodsOnClient", ThisObject);
	PlanningClient.WhenChangingPlanPeriod(ThisForm, "GoodsByPeriod", Notification);
	
EndProcedure

&AtServer
Procedure SaveNewPeriodServer()
	
	PlanningClientServer.SaveValuesOfVerifiedDetails(Object, ThisForm, "DetailsBeforeChange");
	
	CaptionFrequencyCurrency = NStr("vi = 'Định kỳ: %Periodicity%';
									|ru = 'Периодичность: %Periodicity%';
									|en = 'Time fence: %Periodicity%'; fa = 'Time fence: %Periodicity%';
									|it = 'Periodicità: %Periodicity%';
									|pl = 'Częstotliwość: %Periodicity%';
									|tr = 'Sıklık: %Periodicity%'");
	CaptionFrequencyCurrency = StrReplace(CaptionFrequencyCurrency,"%Periodicity%",String(Object.Periodicity));
	
EndProcedure

&AtClientAtServerNoContext
Procedure WhenChangingAmountOfRowSum(Object, Form, RowOfGoods)
	
	Count = 0;
	For Each PeriodString_ In Form.TimeIntervals Do
		If Not PeriodString_.Active_ Or RowOfGoods["Canceled_" + PeriodString_.ColumnName] Then
			Continue;
		EndIf;
		
		Count = Count + RowOfGoods["Count_" + PeriodString_.ColumnName];
		
	EndDo;
	
	RowOfGoods.NumberOfPackages = Count;
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateTotals_(Form, CountLines = True)
	
	Object = Form.Object;
	
	If Not Object.CrossTable Then
		Return;
	EndIf;
	
	Goods = Form.GoodsByPeriod;
	
	Form["NumberOfPackages"] = 0;
	
	PrefixOfQuantityColumn = "GoodsByPeriod" + "Count_";
	
	For Each PeriodString_ In Form.TimeIntervals Do
		If Not PeriodString_.Active_ Then
			Continue;
		EndIf;
		
		Form[PrefixOfQuantityColumn + PeriodString_.ColumnName] = 0;
		
	EndDo;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	CachedValues = Undefined;
	
	For Each TSRow In Goods Do
		If CountLines Then
			TSRow.NumberOfPackages = 0;
		EndIf;
		
		For Each PeriodString_ In Form.TimeIntervals Do
			If Not PeriodString_.Active_ Then
				Continue;
			EndIf;
			
			TSRow["Substituted_"+ PeriodString_.ColumnName] = PeriodString_.Substituted;
			TSRow["SubstitutedToOrder_"+ PeriodString_.ColumnName] = PeriodString_.SubstitutedToOrder;
			
			If CountLines Then
				
				If TSRow["Canceled_" + PeriodString_.ColumnName] Then
					Continue;
				EndIf;
				
				TSRow.NumberOfPackages = TSRow.NumberOfPackages
					+ TSRow["Count_" + PeriodString_.ColumnName];
				
			EndIf;
			
			If TSRow["Canceled_" + PeriodString_.ColumnName] Then
				Continue;
			EndIf;
			
			Form[PrefixOfQuantityColumn + PeriodString_.ColumnName] = Form[PrefixOfQuantityColumn
				+ PeriodString_.ColumnName] + TSRow["Count_" + PeriodString_.ColumnName];
			
		EndDo;
		
		Form["NumberOfPackages"] = Form["NumberOfPackages"] + TSRow["NumberOfPackages"];
		
		If CountLines Then
			
			#If Client Or ThickClientManagedApplication Then
				BatchProcessingOfTablePartClient.ProcessTSString(TSRow, StructureOfActions, CachedValues);
			#EndIf
		EndIf;
		
		PlanningClientServer.SetFormulaPresentation(Form, TSRow);
		
	EndDo;
	
	#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
		If CountLines Then
			BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions, CachedValues);
		EndIf;
	#EndIf 
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	If Object.FillInUsingFormula Then
		InitializeSettingsWhenReadingOnServer(FormAttributeToValue("Object"));
	Else
		InitializeSettingsStructure(FormAttributeToValue("Object"));
	EndIf;
	
	PlanningByAssignments = Common.ObjectAttributeValue(Object.Scenario,"PlanningByAssignments");
	
	WhenChangingPeriodsOnServer();
	
	CopyToCrossTable(Undefined);
	
	SetCrossTableTag(ThisForm);
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsForProductInCollection()
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute",
				New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_",
				New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute",
				New Structure("Products", "SKU"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(
		?(Object.CrossTable Or PlannedBalanceIsUsed, GoodsByPeriod, Object.Goods),
		StructureOfActions);
	
	If Object.CrossTable Or PlannedBalanceIsUsed Then
		
		For Each TSRow In GoodsByPeriod Do
			For Each Period In ThisObject["TimeIntervals"] Do
				If Not Period.Active_ Then
					Continue;
				EndIf;
				TSRow["PictureComment_"+ Period.ColumnName] = ValueIsFilled(
					TSRow["Comment_"+ Period.ColumnName]);
			EndDo;
		EndDo;
		
	Else
		For Each TSRow In Object.Goods Do
			TSRow.PictureComment = ValueIsFilled(TSRow.Comment);
		EndDo;
	
	EndIf;
	
EndProcedure

// The procedure fills the period table with dates to get the order and forms the fields of the cross-table.
&AtServer
Procedure WhenChangingPeriodsOnServer(AdjustStartEndOfPeriod = False)
	
	If AdjustStartEndOfPeriod Then
		PlanningClientServer.SetStartEndOfPlanPeriod(Object.Periodicity, Object.BeginOfPeriod,
			Object.PeriodEnding, CurrentSessionDate());
	EndIf;
	
	TablePeriods = FormAttributeToValue("TimeIntervals", Type("ValueTable"));
	If Object.Substitutional
		And ValueIsFilled(Object.Periodicity) Then
		FillInSubstitutedPeriods();
		Planning.UpdateReplacementHyperlink(ThisForm);
	Else
		SubstitutedPeriods.Clear();
		SubstitutionFormattedLine = New FormattedString(New Array);
	EndIf;
	Planning.FillInPeriodTable(TablePeriods, Object.Periodicity, Object.BeginOfPeriod,
		Object.PeriodEnding, ShowNumberOfPeriod, SubstitutedPeriods);
	
	UpdateCrossTableStructure(TablePeriods, True);
	
	If Object.CrossTable Then
		
		SaveNewPeriodServer();
		
		Planning.CheckExistenceOfAlreadyCreatedPlans(Object, "InventoryConsumptionPlan");
		
	EndIf;
	
EndProcedure

// Parameters:
// 	TablePeriods See Planning.TablePeriods
// 	RecalculateTotals_ - Boolean - LongDesc
&AtServer
Procedure UpdateCrossTableStructure(TablePeriods, RecalculateTotals_ = True)
	
	NumberOfPeriods = TablePeriods.FindRows(New Structure("Active_", True)).Count();
	ThisIsOnePeriod = NumberOfPeriods = 1;
	
	Items.GoodsDateOfShipment.ChoiceList.Clear();
	For Each Period In TablePeriods Do
		If Not Period.Active_ Then
			Continue;
		EndIf;
		Items.GoodsDateOfShipment.ChoiceList.Add(BegOfDay(Period.StartDate), Period.Title);
	EndDo;
	
	Items.GoodsByPeriodNumberOfPackages.Visible = Not ThisIsOnePeriod;
	
	If Not Object.CrossTable
		Or ThisIsOnePeriod Then
		TotalByLineByColumn = "";
	EndIf;
	
	Items.CellComment.Visible = Object.CrossTable And Not ThisIsOnePeriod;
	Items.CellIsCanceled.Visible = Object.CrossTable And Not ThisIsOnePeriod;
		
	If Not Object.CrossTable 
		And Not PlannedBalanceIsUsed Then
		ValueToFormAttribute(TablePeriods,"TimeIntervals");
		SaveNewPeriodServer();
		UpdateReplacementAttribute();
		Return;
	EndIf;
	
	OutputParameters = New Structure;
	OutputParameters.Insert("NameOfCrossTableProps", "GoodsByPeriod");
	OutputParameters.Insert("CrossTableFormElement", "GoodsByPeriod");
	OutputParameters.Insert("PeriodsTable", TablePeriods);
	OutputParameters.Insert("Periodicity", Object.Periodicity);
	OutputParameters.Insert("Fields", New Array());
	
	If Not ThisIsOnePeriod Then
		Planning.AddCrossTableFieldInCommentWithImage(OutputParameters);
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("OnChange", "Attachable_WhenChangingQuantity");
	Planning.AddQuantityCrossTableField(
		OutputParameters, 
		True, 
		Not ThisIsOnePeriod, 
		ThisIsOnePeriod, 
		StructureOfActions);
		
	StructureOfActions = New Structure;
	StructureOfActions.Insert("OnChange", "Attachable_OnChangeCanceled");
	Planning.AddCrossTableFieldCanceled(OutputParameters, ThisIsOnePeriod, StructureOfActions);
	
	StructureOfActions = New Structure;
	Planning.AddReplacedCrossTableField(OutputParameters, ThisIsOnePeriod And Object.Substitutional, StructureOfActions);
	Planning.AddReplacedToOrderCrossTableField(OutputParameters, False, StructureOfActions);
	
	If ThisIsOnePeriod Then
		Planning.AddCrossTableFieldInCommentWithImage(OutputParameters);
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("OnChange", "Attachable_WhenChangingComment");
	StructureOfActions.Insert("StartChoice", "Attachable_StartOfCommentSelection");
	Planning.AddCrossTableCommentField(OutputParameters, ThisIsOnePeriod, StructureOfActions);
	
	If Object.FillInUsingFormula Then
		AddFieldsFromAdditionalParameters(OutputParameters);
	Else
		Planning.AddTranscriptCrossTableField(OutputParameters);
	EndIf;
	
	Planning.UpdateCrosstabOutputStructure(ThisForm, OutputParameters);
	
	ValueToFormAttribute(TablePeriods,"TimeIntervals");
	
	SetConditionalAppearance();
	SetConditionalAppearanceOfCrossTable();
	
	If RecalculateTotals_ Then
		CalculateTotals_(ThisForm);
	EndIf;
	
EndProcedure

&AtServer
Procedure ScenarioOnChangeServer()
	
	If Object.PlanProfile <> ThisForm["DetailsBeforeChange"].PlanProfile
		Or (Object.Scenario <> ThisForm["DetailsBeforeChange"].Scenario 
			And Not ValueIsFilled(Object.PlanProfile)) Then
	
		UpdatePlanView = True;
	
	Else
	
		UpdatePlanView = False;
	
	EndIf;
	
	Attributes = "Periodicity, ShowNumberOfPeriod, PlanningByAssignments";
	Attributes = Attributes + ", BudgetingScenario";
	ScriptParameters_ = Common.ObjectAttributesValues(Object.Scenario, Attributes);
	FillPropertyValues(Object, ScriptParameters_);
	FillPropertyValues(ThisForm, ScriptParameters_);
	
	If UpdatePlanView Then
		
		Object.PlanProfile = Planning.GetDefaultPlanView(
			Enums.TypesOfPlans.InventoryConsumptionPlan, Object.Scenario);
		
	EndIf;
	
	If PlanningClientServer.YouNeedToUpdateInterface(Object, ThisForm, "DetailsBeforeChange") Then
		WhenChangingPeriodsOnServer(True);
	EndIf;
	
	If UpdatePlanView Then
		PlanProfileOnChangeServer(UpdatePlanView);
		Object.FilledAutomatically = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure PlanProfileOnChangeServer(UpdateRule = False)
	
	UpdateRule = UpdateRule Or Object.PlanProfile <> ThisForm["DetailsBeforeChange"].PlanProfile;
	
	PlanViewParameters = GetPlanViewParameters(Object.PlanProfile, 
		UpdateRule, FillingRuleAddress, CustomSettingsAddress);
	
	FillPropertyValues(ThisForm, PlanViewParameters,, "NumberOfPeriods");
	
	If UpdateRule Then
		FillPropertyValues(ThisForm, PlanViewParameters, "NumberOfPeriods");
		If NumberOfPeriods > 0 Then
			Object.PeriodEnding = Undefined;
			PlanningClientServer.SetStartEndOfPlanPeriod(
				Object.Periodicity, 
				Object.BeginOfPeriod, 
				Object.PeriodEnding,
				CurrentSessionDate(),
				PlanViewParameters.NumberOfPeriods);
		EndIf;
		FillPropertyValues(Object, PlanViewParameters);
		Object.FillingRule.Load(GetFromTempStorage(FillingRuleAddress));
		Object.FilledAutomatically = False;
		Object.FillInUsingFormula = PlanViewParameters.FillInUsingFormula;
		Object.Substitutional = PlanViewParameters.Substitutional;
		Planning.CheckExistenceOfAlreadyCreatedPlans(Object, "InventoryConsumptionPlan");
		InitializeSettingsWhenReadingOnServer(FormAttributeToValue("Object"));
		If PlanViewParameters.Property("SettingsStructure")
			And PlanViewParameters.SettingsStructure <> Undefined Then
			SettingsStructure = PlanViewParameters.SettingsStructure;
		EndIf;
		WhenChangingPeriodsOnServer();
	EndIf;
	
	SaveNewPeriodServer();
	
	If UpdateRule And ValueIsFilled(Object.PlanProfile) Then
		
		UpdateRelatedItemDetails(Object, ThisForm);
		
	EndIf;
	
	SetVisibility1();
	
EndProcedure

&AtServer
Procedure SetVisibility1()
	
	UseOrderSupplyWithAssignment = GetFunctionalOption(
		"UseOrderSupplyWithAssignment");
	
	Items.PlanProfile.Enabled = ValueIsFilled(Object.Scenario);
	
	Items.Department.Visible = FillInBusinessUnit Or ValueIsFilled(Object.Department);
	
	Items.Warehouse.Visible = FillInWarehouse Or ValueIsFilled(Object.Warehouse);
	Items.GoodsWarehouse.Visible = FillInWarehouseInTabularForm;
	Items.GoodsByPeriodWarehouse.Visible = FillInWarehouseInTabularForm;
	Items.GoodsFillInAWarehouseByTheValue.Visible = FillInWarehouseInTabularForm;
	Items.GoodsByPeriodFillInAWarehouseByTheValue.Visible = FillInWarehouseInTabularForm;
	
	Items.GoodsFillInAssignmentByValue.Visible = FillInAssignmentInTabularForm;
	Items.GoodsByPeriodFillInAssignmentByValue.Visible = FillInAssignmentInTabularForm;
	
	Items.ProductsFillColumns.Visible = FillInWarehouseInTabularForm Or FillInAssignmentInTabularForm;
	Items.ProductsByPeriodFillInColumns.Visible = FillInWarehouseInTabularForm Or FillInAssignmentInTabularForm;
	
	Items.GoodsConfigureAndPopulateAccordingToTheFillingRule.Visible = Not DisableEditingOfRule;
	
	Items.GoodsByPeriodConfigureAndPopulateAccordingToTheFillingRule.Visible = Not DisableEditingOfRule;
	
	Items.GoodsFill.Visible = Not Object.FillInUsingFormula;
	Items.GoodsSplitRow.Visible = Not Object.FillInUsingFormula;
	Items.ProductsByPeriodFillIn.Visible = Not Object.FillInUsingFormula;
	Items.GoodsFillInTheProducts.Visible = Object.FillInUsingFormula;
	Items.GoodsByPeriodFillInTheProducts.Visible = Object.FillInUsingFormula;
	Items.GoodsFillInIndicators.Visible = Object.FillInUsingFormula;
	Items.GoodsByPeriodFillInIndicators.Visible = Object.FillInUsingFormula;
	Items.GoodsGroupChangeQuantity.Visible = Object.FillInUsingFormula;
	Items.ProductsGroupByPeriodChangeQuantity.Visible = Object.FillInUsingFormula;
	Items.GoodsAdditionalParametersFormula.Visible = Object.FillInUsingFormula;
	Items.ProductsAdditionalParametersDeviation.Visible = Object.FillInUsingFormula;
	If Items.ProductsByPeriodAdditionalParameters.ChildItems.Find("GoodsByPeriod" + "Deviation") <> Undefined Then
		Items.ProductsByPeriodAdditionalParameters.ChildItems["GoodsByPeriod" + "Deviation"].Visible = Object.FillInUsingFormula;
	EndIf;
	If Items.ProductsByPeriodAdditionalParameters.ChildItems.Find("GoodsByPeriod" + "FormulaCalculation") <> Undefined Then
		Items.ProductsByPeriodAdditionalParameters.ChildItems["GoodsByPeriod" + "FormulaCalculation"].Visible = Object.FillInUsingFormula;
	EndIf;
	Items.GoodsAdditionalParameters.Visible = Object.FillInUsingFormula;
	Items.Details.Visible = Not Object.FillInUsingFormula;
	Items.GoodsByPeriodsContextMenuGroupByFormula.Visible = Object.FillInUsingFormula;
	Items.GoodsContextMenuGroupUsingFormula.Visible = Object.FillInUsingFormula;
	
	Items.Purpose.Visible = PlanningByAssignments 
		And Not FillInAssignmentInTabularForm 
		And UseOrderSupplyWithAssignment;
	Items.GoodsPurpose.Visible = PlanningByAssignments 
		And FillInAssignmentInTabularForm 
		And UseOrderSupplyWithAssignment;
	Items.GoodsByPeriodPurpose.Visible = PlanningByAssignments 
		And FillInAssignmentInTabularForm 
		And UseOrderSupplyWithAssignment;
	
	Items.GoodsSubstituted.Visible = Object.Substitutional;
	
EndProcedure

&AtServerNoContext
Function GetPlanViewParameters(Val PlanProfile, Val UpdateRule, FillingRuleAddress, CustomSettingsAddress)
	
	Attributes = "NumberOfPeriods, FillInBusinessUnit, FillInWarehouse, FillInWarehouseInTabularForm, 
		|DisableEditingOfRule, FillInUsingFormula, Substitutional, 
		|FillInAssignmentInTabularForm, DisableEditingOfPopulationSettings";
	
	PlanViewParameters = Common.ObjectAttributesValues(PlanProfile, Attributes);
	
	If UpdateRule Then
		FillingRuleAddress = Planning.GetAddressOfDefaultFillInRule(
			Enums.TypesOfPlans.InventoryConsumptionPlan, PlanProfile, FillingRuleAddress);
		CustomSettingsAddress = Planning.GetAddressOfUserDefaultSettings(
			Enums.TypesOfPlans.InventoryConsumptionPlan, PlanProfile, CustomSettingsAddress);
		SettingsStructure = Planning.GetDefaultSettings(
			Enums.TypesOfPlans.InventoryConsumptionPlan, PlanProfile);
		If SettingsStructure.Property("Formula") Then
			PlanViewParameters.Insert("SettingsStructure", SettingsStructure);
		EndIf;
		For Each Item In SettingsStructure Do
			PlanViewParameters.Insert(Item.Key, Item.Value);
		EndDo;
	EndIf;
	
	Return PlanViewParameters;
	
EndFunction

&AtClientAtServerNoContext
Procedure UpdateRelatedItemDetails(Object, Form)
	
	If Object.CrossTable 
		Or Form.PlannedBalanceIsUsed Then
		Goods = Form.GoodsByPeriod;
	Else
		Goods = Object.Goods;
	EndIf;
	
	If Not Form.FillInBusinessUnit Then
		Object.Department = Undefined;
	EndIf;
	
	If Not Form.FillInWarehouse Then
		Object.Warehouse = Undefined;
	EndIf;
	
	If Not Form.PlanningByAssignments Then
		Object.Purpose = Undefined;
	EndIf;
	
	For Each TSRow In Goods Do
		
		If Form.FillInWarehouse Then
			TSRow.Warehouse = Object.Warehouse;
		ElsIf Not Form.FillInWarehouseInTabularForm Then
			TSRow.Warehouse = Undefined;
		EndIf;
		
		If Not Form.PlanningByAssignments
			Or TSRow.ItemsType = PredefinedValue("Enum.ItemsTypes.OperationService")
			Or TSRow.ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage") Then
			TSRow.Purpose = Undefined;
		ElsIf Not Form.FillInAssignmentInTabularForm Then
			TSRow.Purpose = Object.Purpose;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure NotifyUserAboutFillingInData()
	
	ShowUserNotification(
		NStr("vi = 'Hoàn thành việc điền dữ liệu vào chứng từ';
			|ru = 'Заполнение данных в документ завершено';
			|en = 'Data population to the document is completed'; fa = 'Data population to the document is completed';
			|it = 'La compilazione dei dati nel documento è completata';
			|pl = 'Wypełnianie danych dokumentu jest zakończone';
			|tr = 'Belgede verileri doldurma bitti'"),
		,
		,
		PictureLib.Information32);
	
EndProcedure

&AtClient
Procedure NotifyUserAboutStartOfFillingInData()
	
	Status(NStr("vi = 'Đang tiến hành điền dữ liệu vào chứng từ';
				|ru = 'Выполняется заполнение данных в документ';
				|en = 'Populating the document with data'; fa = 'Populating the document with data';
				|it = 'La compilazione dei dati nel documento è in esecuzione';
				|pl = 'Wypełnianie danych w dokumencie';
				|tr = 'Belgede verileri doldurma gerçekleştiriliyor'"));
	
EndProcedure

&AtServer
Function GetAddressOfPeriodTable()
	
	Return PutToTempStorage(ThisForm.TimeIntervals.Unload(), UUID);
	
EndFunction

&AtServer
Procedure AddProducts_2(TableOfGoods, CachedValues = Undefined, LoadingFromFile = False)
	
	Modified = True;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	
	RowsToProcess = New Array();
	
	For Each RowOfProduct In TableOfGoods Do
		
		Object.FilledAutomatically = False;
		
		If Object.CrossTable And Not LoadingFromFile Then
			CurrentRow = GoodsByPeriod.Add();
			FillPropertyValues(CurrentRow, RowOfProduct);
			
			CurrentPeriod_ = ThisForm.TimeIntervals.FindRows(New Structure("Active_", True))[0];
			
			If CurrentRow["Count_" + CurrentPeriod_.ColumnName] = 0 
				And CurrentRow.Count <> 0 Then
				CurrentRow["Count_" + CurrentPeriod_.ColumnName] = CurrentRow.NumberOfPackages;
			EndIf;
			If Not Object.FillInUsingFormula And CurrentRow["Details_" + CurrentPeriod_.ColumnName] = ""
				And CurrentRow.Details <> "" Then
				CurrentRow["Details_" + CurrentPeriod_.ColumnName] = CurrentRow.Details;
			EndIf;
		Else
			CurrentRow = Object.Goods.Add();
			FillPropertyValues(CurrentRow, RowOfProduct);
			
			If Not ValueIsFilled(CurrentRow.DateOfShipment) Then
				CurrentRow.DateOfShipment = Object.BeginOfPeriod;
			EndIf;
			
			RowsToProcess.Add(CurrentRow);
		EndIf;
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	If Object.CrossTable Then
		PlanningClientServer.CalculateCrossTableRowNumber(ThisForm, "GoodsByPeriod");
	EndIf;
	
	CalculateNumberOfRows(ThisForm);
	
	FillInServiceDetailsForProductInCollection();
	
	UpdateRelatedItemDetails(Object, ThisForm);
	
	CalculateTotals_(ThisForm);
	
EndProcedure

&AtServer
Procedure GetUploadedProductsFromStorage(GoodsAddressInStorage, CachedValues = Undefined)
	
	ItemsFromStorage = GetFromTempStorage(GoodsAddressInStorage);
	AddProducts_2(ItemsFromStorage, CachedValues);
	
EndProcedure

#Region ProceduresForDynamicFormationOfFormStructure

&AtClient
Procedure WhenChangingPeriodsOnClient(Result, AdditionalParameters) Export
	
	WhenChangingPeriodsOnServer();
	
EndProcedure

#EndRegion

#Region ProceduresForExchangingDataBetweenTablePartAndFormTable

&AtServer
Procedure CopyFromCrossTable(CachedValues, Var_ThisObject)
	
	If Var_ThisObject.CrossTable 
		Or PlannedBalanceIsUsed Then
		
		ConversionParameters = CrossTableConversionParameters();
		
		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
		
		Planning.FillInTableFromCrossTable(Var_ThisObject.Goods, Object.Goods, GoodsByPeriod, ConversionParameters, 
			StructureOfActions, CachedValues);
	EndIf;

	CalculateNumberOfRows(ThisForm);
	
EndProcedure

&AtServer
Procedure CopyToCrossTable(CachedValues)
	
	If Object.CrossTable
		Or PlannedBalanceIsUsed Then
		
		ConversionParameters = CrossTableConversionParameters();
		
		For Each TSRow In Object.Goods Do
			If Not ValueIsFilled(TSRow.DateOfShipment) Then
				TSRow.DateOfShipment = Object.BeginOfPeriod;
			EndIf;
		EndDo;
		
		PlanningClientServer.FillInCrossTableFromTable(GoodsByPeriod, 
			Object.Goods, ConversionParameters);
		
		CalculateTotals_(ThisForm);
		
		PlanningClientServer.CalculateCrossTableRowNumber(ThisForm, "GoodsByPeriod");
		
	EndIf;
	
	CalculateNumberOfRows(ThisForm);
	
	FillInServiceDetailsForProductInCollection();
	
EndProcedure

&AtServer
Function CrossTableConversionParameters()
	
	TablePeriods = FormAttributeToValue("TimeIntervals", Type("ValueTable"));

	StructureOfPeriodDetails = New Structure("StartDate","DateOfShipment");

	AttributesStructure1 = New Structure;
	AttributesStructure1.Insert("Count_","NumberOfPackages");
	AttributesStructure1.Insert("Canceled_","Canceled");
	AttributesStructure1.Insert("Substituted_","Substituted");
	AttributesStructure1.Insert("SubstitutedToOrder_","SubstitutedToOrder");
	AttributesStructure1.Insert("Comment_","Comment");

	If Object.FillInUsingFormula Then
		AddBankingDetailsFromAdditionalParameters(AttributesStructure1);
	Else
		AttributesStructure1.Insert("Details_","Details");
	EndIf;

	GroupFields = "Products, Characteristic, Package";
	
	If FillInWarehouseInTabularForm Then
		GroupFields = GroupFields + ", Warehouse";
	EndIf;
	
	If FillInAssignmentInTabularForm Then
		GroupFields = GroupFields + ", Purpose";
	EndIf;
	
	StructureOfFinalDetails = New Structure;
	StructureOfFinalDetails.Insert("NumberOfPackages", "NumberOfPackages");

	ConversionParameters = New Structure;
	ConversionParameters.Insert("TablePeriods",              TablePeriods);
	ConversionParameters.Insert("Periodicity",               Object.Periodicity);
	ConversionParameters.Insert("StructureOfPeriodDetails",  StructureOfPeriodDetails);
	ConversionParameters.Insert("AttributesStructure1",         AttributesStructure1);
	ConversionParameters.Insert("GroupFields",             GroupFields);
	ConversionParameters.Insert("StructureOfFinalDetails", StructureOfFinalDetails);

	Return ConversionParameters;
	
EndFunction

#EndRegion

#Region OnChangeAttributes

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions)
	
	StructureOfActions.Insert("RecalculateNumberOfUnits", New Structure("MustBeRoundOff", False));
	
EndProcedure

#Region SelectionAndProcessingOfQuantityVerification

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(CachedValues, ValueSelected)
	
	If Not IsTempStorageURL(ValueSelected.GoodsAddressInStorage) Then
		Return;
	EndIf;
	
	GetUploadedProductsFromStorage(ValueSelected.GoodsAddressInStorage, CachedValues);
	
EndProcedure

#EndRegion

#Region ProcessingWithExcel

&AtServer
Function LoadFromExcelOnServer(ArrayOfDataStructures)
	
	If Object.CrossTable Then
		GoodsByPeriod.Clear();
	Else
		Object.Goods.Clear();
	EndIf;

	// ID Processing
	For Each ProductStructure_1 In ArrayOfDataStructures Do
		
		If Not ValueIsFilled(ProductStructure_1.ProductID_) Then
			Continue;
		EndIf;
		
		ProductStructure_1.Insert("Products",   Catalogs.Products.GetRef(
			New UUID(ProductStructure_1.ProductID_)));
		ProductStructure_1.Insert("Characteristic", Catalogs.ItemsCharacteristics.GetRef(
			New UUID(ProductStructure_1.IdentifierCharacteristic)));
		ProductStructure_1.Insert("Package",       Catalogs.PackagesAndUnitsOfMeasure.GetRef(
			New UUID(ProductStructure_1.PackageIdentifier)));
		ProductStructure_1.Insert("Warehouse",          Catalogs.Warehouses.GetRef(
			New UUID(ProductStructure_1.WarehouseID_)));
		ProductStructure_1.Insert("Purpose",     Catalogs.Assignments.GetRef(
			New UUID(ProductStructure_1.DestinationID_)));
		
	EndDo;

	AddProducts_2(ArrayOfDataStructures);
	If Not Object.CrossTable Then
		UpdateReplacementAttribute();
	EndIf;
	
EndFunction

&AtClient
Function DownloadFromExcelOnClient(AttachedFile)
	
	ExcelActionStructure = StructureOfActionsWhenLoadingFromExcel();
	
	ProcessingWithExcelClient.ImportFromExcel(ThisForm, AttachedFile, ExcelActionStructure);
	
EndFunction

&AtClient
Function LoadFromExcelOnClient(DownloadData)
	
	ThereAreLinesAdded = False;
	
	For Each LoadingString In DownloadData Do
	
		If Not ValueIsFilled(LoadingString.ProductID_) Then
			
			ThereAreLinesAdded = True;
			Break;
			
		EndIf;
	
	EndDo;
	
	If ThereAreLinesAdded Then
		
		FilterByProductType = ProductsClientServer.SelectionByProductMultiTurnContainer(False);
		FilterByProductType.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
	
		ImportParameters = ProcessingOfTabularFormsClient.ProductLoadingParametersForPlans();
		ImportParameters.PlanProfile           = Object.PlanProfile;
		ImportParameters.PlanByAmount = False;
		ImportParameters.CrossTable       = Object.CrossTable;
		ImportParameters.AddressOfThePeriodTable = GetAddressOfPeriodTable();
		ImportParameters.GoodsTableAddress  = PutToTempStorage(DownloadData, UUID);
		ImportParameters.FilterParameters.Insert("ItemsType", FilterByProductType);
		
		AddlParameters = New Structure("UpdateAdd", 0); // Always update the plan when downloading from Excel
		Notification = New CallbackDescription("ImportFromExternalFileCompletion", ThisObject, AddlParameters);
		ProcessingOfTabularFormsClient.ShowProductUploadFormForPlans(ImportParameters, Notification);
		
	Else
	
		LoadFromExcelOnServer(DownloadData);
	
	EndIf;
	
EndFunction

&AtClient
Procedure ImportFromExternalFileCompletion(ImportedDataAddress, AdditionalParameters) Export
	
	If ValueIsFilled(ImportedDataAddress) Then
		If AdditionalParameters.UpdateAdd = 0 Then
			GoodsByPeriod.Clear();
			Object.Goods.Clear();
		EndIf;
		GetUploadedProductsFromStorage(ImportedDataAddress, CachedValues);
	EndIf;
	
EndProcedure

&AtClient
Function StructureOfActionsWhenLoadingFromExcel()
	
	ExcelActionStructure = New Structure;
	
	// Defining columns by their headers
	SearchColumns = New ValueList;
	SearchColumns.Add(NStr("vi = 'Mã định danh duy nhất (Mặt hàng)';
							|ru = 'Уникальный идентификатор (Номенклатура)';
							|en = 'UUID (Items)'; fa = 'UUID (اقلام)';
							|it = 'Identificatore unico (Articolo)';
							|pl = 'Indywidualny identyfikator (Produkty)';
							|tr = 'Benzersiz kimlik (Ürün)'"),"ProductID_");
	SearchColumns.Add(NStr("vi = 'Tên duy nhất (Đặc tính)';
							|ru = 'Уникальный идентификатор (Характеристика)';
							|en = 'Unique ID (Variant)'; fa = 'شناسه یکتا (گونه)';
							|it = 'Identificatore unico (Caratteristica)';
							|pl = 'Indywidualny identyfikator (Charakterystyka)';
							|tr = 'Benzersiz kimlik (Varyant)'"),"IdentifierCharacteristic");
	SearchColumns.Add(NStr("vi = 'Mã định danh duy nhất (Bao bì)';
							|ru = 'Уникальный идентификатор (Упаковка)';
							|en = 'Unique ID (Packaging unit)'; fa = 'شناسه یکتا (واحد بسته‌بندی)';
							|it = 'Identificatore unico (Imballaggio)';
							|pl = 'Indywidualny identyfikator (Opakowanie)';
							|tr = 'Benzersiz kimlik (Paketleme ünitesi)'"),"PackageIdentifier");
	SearchColumns.Add(NStr("vi = 'Mã định danh duy nhất (Kho)';
							|ru = 'Уникальный идентификатор (Склад)';
							|en = 'Unique ID (Warehouse)'; fa = 'شناسه یکتا (انبار)';
							|it = 'Identificatore unico (Magazzino)';
							|pl = 'Indywidualny identyfikator (Magazyn)';
							|tr = 'Benzersiz tanımlayıcı (Ambar)'"),"WarehouseID_");
	SearchColumns.Add(NStr("vi = 'Tên duy nhất (Mục đích)';
							|ru = 'Уникальный идентификатор (Назначение)';
							|en = 'Unique ID (Assignment)'; fa = 'شناسه یکتا (تخصیص)';
							|it = 'Identificatore unico (Assegnazione)';
							|pl = 'Indywidualny identyfikator (Przeznaczenie)';
							|tr = 'Benzersiz tanımlayıcı (Atama)'"),"DestinationID_");
	
	If ValueIsFilled(AdditionalColumnName) Then
		SearchColumns.Add(AdditionalColumnName,"DownloadableArticleNumber");
	EndIf;
	SearchColumns.Add(NStr("vi = 'Mặt hàng';
							|ru = 'Номенклатура';
							|en = 'Items'; fa = 'اقلام';
							|it = 'Articolo';
							|pl = 'Produkt';
							|tr = 'Ürün'"),"ImportedProducts");
	SearchColumns.Add(NStr("vi = 'Đặc tính';
							|ru = 'Характеристика';
							|en = 'Variant'; fa = 'گونه';
							|it = 'Caratteristica';
							|pl = 'Charakterystyka';
							|tr = 'Varyant'"),"ImportedCharacteristic");
	
	If FillInWarehouseInTabularForm Then
		SearchColumns.Add(NStr("vi = 'Kho bãi';
								|ru = 'Склад';
								|en = 'Warehouse'; fa = 'Warehouse';
								|it = 'Magazzino';
								|pl = 'Magazyn';
								|tr = 'Ambar'"),"ImportedWarehouse");
	EndIf;
	If FillInAssignmentInTabularForm Then
		SearchColumns.Add(NStr("vi = 'Ấn định';
								|ru = 'Назначение';
								|en = 'Assignment'; fa = 'تخصیص';
								|it = 'Destinazione';
								|pl = 'Przeznaczenie';
								|tr = 'Atama'"),"DownloadableDestination");
	EndIf;
	
	If Object.CrossTable Then
		
		SearchColumns.Add(NStr("vi = 'Đơn vị tính';
								|ru = 'Ед. изм.';
								|en = 'Unit'; fa = 'واحد';
								|it = 'Unità di misura';
								|pl = 'J. m.';
								|tr = 'Ölçü birimi'"),"ImportedPackaging");
		
		TablePeriods = ThisForm.TimeIntervals; // See Planning.TablePeriods
	
		For Each Period In TablePeriods Do
			
			If Not Period.Active_ Or Period.ColumnNumber <=0 Then
				Continue;
			EndIf;
			SearchColumns.Add(Period.Title,"Period_"+Period.ColumnName);
			If Object.Periodicity = PredefinedValue("Enum.Periodicity.Year") Then
				SearchColumns.Add(TrimAll(StrReplace(Period.Title, NStr("vi = 'năm';
																		|ru = 'г.';
																		|en = 'year'; fa = 'سال';
																		|it = 'anno';
																		|pl = 'year';
																		|tr = 'y.'"), "")),
					"Period_"+Period.ColumnName);
			EndIf;
			SearchColumns.Add(
				PlanningClientServer.GeneratePeriodHeader(
					Object.Periodicity, Period.StartDate, Period.EndDate, Not ShowNumberOfPeriod), 
				"Period_"+Period.ColumnName);
			
		EndDo;
		PeriodAttributes = New Array;
		PeriodAttributes.Add("Count_");
		
		ExcelActionStructure.Insert("PeriodAttributes", PeriodAttributes);
		ExcelActionStructure.Insert("TimeIntervals", ThisForm.TimeIntervals);
	Else
		
		SearchColumns.Add(NStr("vi = 'Ngày giao hàng';
								|ru = 'Дата отгрузки';
								|en = 'Shipment date'; fa = 'تاریخ ارسال';
								|it = 'Data di spedizione';
								|pl = 'Data wysyłki';
								|tr = 'Sevkiyat tarihi'"),"DateOfShipment");
		SearchColumns.Add(NStr("vi = 'Số lượng';
								|ru = 'Количество';
								|en = 'Quantity'; fa = 'مقدار';
								|it = 'Quantità';
								|pl = 'Ilość';
								|tr = 'Miktar'"),"NumberOfPackages");
		SearchColumns.Add(NStr("vi = 'Đơn vị tính';
								|ru = 'Ед. изм.';
								|en = 'Unit'; fa = 'واحد';
								|it = 'Unità di misura';
								|pl = 'J. m.';
								|tr = 'Ölçü birimi'"),"ImportedPackaging");
		
	EndIf;
	
	ExcelActionStructure.Insert("SearchColumns", SearchColumns);
	
	TheStructureOfTheSearch = New Structure();
	TheStructureOfTheSearch.Insert("ProductID_",0);
	TheStructureOfTheSearch.Insert("IdentifierCharacteristic",0);
	TheStructureOfTheSearch.Insert("PackageIdentifier",0);
	TheStructureOfTheSearch.Insert("WarehouseID_",0);
	TheStructureOfTheSearch.Insert("DestinationID_",0);
	
	ExcelActionStructure.Insert("TheStructureOfTheSearch", TheStructureOfTheSearch);
	
	ExcelActionStructure.Insert("DataStartLineNumber", 3);
	
	Return ExcelActionStructure;
	
EndFunction

#EndRegion

#Region WorkingWithClipboard

&AtServer
Procedure CopyLinesOnServer()
	
	If Object.CrossTable Then
		ProcessingOfTabularForms.CopyRowsToClipboard(GoodsByPeriod, 
			Items.GoodsByPeriod.SelectedRows);
	Else
		ProcessingOfTabularForms.CopyRowsToClipboard(Object.Goods, Items.Goods.SelectedRows);
	EndIf;
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboard()
	
	FilterByProductType = ProductsClientServer.SelectionByProductMultiTurnContainer(False);
	FilterByProductType.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
	
	FilterParameters = New Map;
	FilterParameters.Insert(
		"Products.ItemsType", FilterByProductType);
	
	Columns = "Products,Characteristic,Package,NumberOfPackages,Count,DateOfShipment,Warehouse";
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If ValueIsFilled(TableOfGoods) Then
		AddProducts_2(TableOfGoods);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfClipboardCommands()
	
	ItemArray = New Array();
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsContextMenuInsertRows");
	ItemArray.Add("GoodsByPeriodInsertRows");
	ItemArray.Add("GoodsByPeriodContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", 
		ProcessingOfTabularForms.ThereAreLinesInClipboard());
	
EndProcedure

&AtClient
Procedure SetAvailabilityOfClipboardCommandsOnClient()
	
	ItemArray = New Array();
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsContextMenuInsertRows");
	ItemArray.Add("GoodsByPeriodInsertRows");
	ItemArray.Add("GoodsByPeriodContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", True);
	
EndProcedure

#EndRegion

&AtClient
Procedure ConfigureAndPopulateAccordingToTheFillingRuleCompletion(Settings, AdditionalParameters) Export
	
	If TypeOf(Settings) <> Type("Structure") Then
		Return;
	EndIf;
	
	Modified = True;
	
	FilterIs_Specified = Settings.FilterIs_Specified;
	
	Settings.Insert("FillInRule", True);
	
	FillPropertyValues(Object, Settings, "UpdateAdd, ChangeResultTo, RoundingPrecision");
	
	FillInDocument(Settings);
	
EndProcedure

#EndRegion

#Region SimpleFilling

&AtServer
Procedure InitializeSettingsWhenReadingOnServer(DocumentObject)
	
	If Not ValueIsFilled(Object.Scenario) Or Not ValueIsFilled(Object.PlanProfile) Then
		Return;
	EndIf;
	
	InitializationParameters = New Structure();
	InitializationParameters.Insert("Form", ThisObject);
	InitializationParameters.Insert("AttributePath1", "Object.Goods");
	InitializationParameters.Insert("TableFormElement_", "Goods");
	InitializationParameters.Insert("PeriodTableFormElement", "GoodsByPeriod");
	
	Planning.InitializeAdditionalParameters(AdditionalGoodsParameters, 
		AdditionalParametersGoodsByPeriods, InitializationParameters);
	
	InitializeOperatorTrees();
	
	InitializeFormulaOperands();
	
	InitializeSettingsStructure(DocumentObject);
	
	UpdateOutputStructureOfAdditionalParameters();
	
	ReadMoreParameters(DocumentObject);
	
EndProcedure

&AtServer
Procedure InitializeSettingsStructure(DocumentObject)
	
	If ValueIsFilled(DocumentObject.Ref) Then
		SettingsStructure = DocumentObject.SettingsStructure.Get();
		If SettingsStructure = Undefined Then
			SetSettingValue("SettingsStructure", SettingsStructure);
		EndIf;
	EndIf;
	
	AdditionalSettings(SettingsStructure, AdditionalFields);
	
EndProcedure

&AtServer
Procedure SetSettingValue(SettingName, Setting)
	
	SettingValueFromStorage = Common.CommonSettingsStorageLoad("UserSettings_" 
		+ PlanType, "SettingsStructure", Setting);
	If SettingValueFromStorage <> Undefined Then
		Setting = SettingValueFromStorage;
	EndIf;
	
EndProcedure

&AtServer
Procedure InitializeFormulaOperands()
	
	ArrayOfOperands = GetOperands(ThisObject);
	
	AdditionalFields.Clear();
	
	For Each Item In ArrayOfOperands Do
		NewRow = AdditionalFields.Add();
		NewRow.Id   = Item.Name;
		NewRow.DeletionMark = False;
		NewRow.Presentation   = Item.OperandHeader;
		Item.Property("IncludedInOperand", NewRow.IncludedInOperand);
	EndDo;
	
EndProcedure

&AtServer
Procedure InitializeOperatorTrees()
	
	Tree = ProcessingOfFormulas.GetEmptyOperatorsTree();
	
	Planning.InitializeOperatorTrees(Tree);
	
	GroupPresentation = NStr("vi = 'Ví dụ công thức';
							|ru = 'Примеры формул';
							|en = 'Formula examples'; fa = 'Formula examples';
							|it = 'Esempi di formula';
							|pl = 'Przykłady wzorów';
							|tr = 'Formül örnekleri'");
	OperatorsGroup = ProcessingOfFormulas.AddOperatorsGroup(Tree, "FormulaExamples", GroupPresentation);
	AddTemplatesForFormulasForCalculatingPlannedQuantity(Tree, OperatorsGroup);
	
	OperatorsTreeStorageAddress = PutToTempStorage(Tree, UUID);
	
EndProcedure

&AtClient
Procedure AfterQuestionSetArbitraryFormula(QuestionResult, AdditionalParameters) Export
	
	StructureOfData = New Structure(
		"Formula,FormulaPresentation,Title,EnableValue,RowsArray,PeriodOfChange");
	
	If Object.CrossTable Then
		
		SelectedRows = Items.GoodsByPeriod.SelectedRows;
		
		If SelectedRows.Count() = 1 Then
			
			CurrentData = GoodsByPeriod.FindByID(SelectedRows[0]);
			
			For Each Operand In AdditionalFields Do
				Operand.Value = ThisObject[Operand.Id];
			EndDo;
			
			StructureOfData.Formula 			 = ThisObject.Formula;
			StructureOfData.FormulaPresentation = ThisObject.FormulaPresentation;
			StructureOfData.Title 			 = "" + CurrentData.Products
				+ ?(ValueIsFilled(CurrentData.Characteristic)," (" + CurrentData.Characteristic + ")","");
			StructureOfData.EnableValue 	 = True;
		Else
			StructureOfData.Formula   			 = "";
			StructureOfData.FormulaPresentation = "";
			StructureOfData.Title	 		 = "";
			StructureOfData.EnableValue 	 = False;
		EndIf;
		
		If QuestionResult = DialogReturnCode.Yes Then
			StructureOfData.PeriodOfChange = "AllPeriods";
		ElsIf QuestionResult = DialogReturnCode.No Then
			StructureOfData.PeriodOfChange = AdditionalParameters.ColumnName;
		Else
			Return;
		EndIf;
		
	Else
		
		SelectedRows = Items.Goods.SelectedRows;
		
		If SelectedRows.Count() = 1 Then
			
			CurrentData = Object.Goods.FindByID(SelectedRows[0]);
			
			For Each Operand In AdditionalFields Do
				If CurrentData.Property(Operand.Id) Then
					Operand.Value = CurrentData[Operand.Id];
				EndIf;
			EndDo;
			
			StructureOfData.Formula 			= CurrentData.Formula;
			StructureOfData.FormulaPresentation= CurrentData.FormulaPresentation;
			StructureOfData.Title 			= "" + CurrentData.Products
				+ ?(ValueIsFilled(CurrentData.Characteristic)," (" + CurrentData.Characteristic + ")","");
			StructureOfData.EnableValue 	= True;
		Else
			StructureOfData.Formula   			 = "";
			StructureOfData.FormulaPresentation = "";
			StructureOfData.Title	 		 = "";
			StructureOfData.EnableValue 	 = False;
		EndIf;
		
	EndIf;
	
	StructureOfData.RowsArray = SelectedRows;
	
	SetDecryptionParameters(StructureOfData);
	
	SetArbitraryFormula(StructureOfData);
	
EndProcedure

&AtClient
Procedure SetArbitraryFormula(StructureOfData)
	
	PlanType = PredefinedValue("Enum.TypesOfPlans.InventoryConsumptionPlan");
	FilterParameters = FilterParameters(ThisForm);
	PlanViewParameters = PlanViewParameters(ThisForm);
	FilterIndicators = PlanningClientServer.SelectionToFillInIndicators(PlanType, 
		FilterParameters, PlanViewParameters);
	
	FormParameters = New Structure();
	FormParameters.Insert("Advanced", True);
	FormParameters.Insert("EnableValue", StructureOfData.EnableValue);
	FormParameters.Insert("ValueHeader", ""+StructureOfData.DetailsParameters.Filter.Products
		+ ?(ValueIsFilled(StructureOfData.DetailsParameters.Filter.Characteristic)," ("
		+ StructureOfData.DetailsParameters.Filter.Characteristic + ")",""));
	FormParameters.Insert("OperationalPlanningExplanationParameters", StructureOfData.DetailsParameters);
	FormParameters.Insert("Formula",
		?(StructureOfData.Formula = PlanningClientServer.TextForSettingNewFormula(),"",
		StructureOfData.Formula));
	FormParameters.Insert("Presentation",
		?(StructureOfData.FormulaPresentation = PlanningClientServer.TextForSettingNewFormula(),"",
		StructureOfData.FormulaPresentation));
	FormParameters.Insert("OperandsTree", PlaceAdditionalFieldsInStorage());
	FormParameters.Insert("Operators", OperatorsTreeStorageAddress);
	FormParameters.Insert("SavedSettingsObjectKey", "UserSettings_" + PlanType);
	FormParameters.Insert("Filter", FilterIndicators);
	FormParameters.Insert("ResultType", New TypeDescription("Number"));
	FormParameters.Insert("FunctionsFromCommonModule", PlanningClient.FunctionsFromCommonModule());
	
	CallbackDescription = New CallbackDescription(
		"AfterOpeningConstructorSetArbitraryFormula", ThisObject, StructureOfData);
	Mode = FormWindowOpeningMode.LockOwnerWindow;
	
	OpenForm("CommonForm.FormulasConstructor", FormParameters, ThisForm,,,,CallbackDescription,Mode);
	
EndProcedure

&AtClient
Procedure Attachable_SetArbitraryFormula(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	StructureOfData = New Structure("Formula,FormulaPresentation,DetailsParameters,
		|EnableValue,RowsArray,PeriodOfChange");
	RowsArray 	= New Array();
	
	If Object.CrossTable Then
		
		CurrentData = Items.GoodsByPeriod.CurrentData;
		RowsArray.Add(CurrentData.GetID());
		
		For Each Operand In AdditionalFields Do
			Operand.Value = ThisObject[Operand.Id];
		EndDo;
		
		CurElementName = Items.GoodsByPeriod.CurrentItem.Name;
		ActivePeriods = ThisForm.TimeIntervals.FindRows(New Structure("Active_", True));
		
		If ActivePeriods.Count() > 1 Then
			
			If StrFind(CurElementName, "GoodsByPeriod" + "Count_") = 0
				And StrFind(CurElementName, "ProductsByPeriodPictureComment_") = 0 Then
				ShowUserNotification(NStr("vi = 'Hãy kích hoạt cột có kỳ';
											|ru = 'Активируйте колонку с периодом';
											|en = 'Activate column with period'; fa = 'Activate column with period';
											|it = 'Attivavate la colonna del periodo';
											|pl = 'Aktywuj kolumnę okresu';
											|tr = 'Dönemlerle beraber sütunları etkinleştir'"));
				Return;
			Else
				For Each Period In ActivePeriods Do
					If CurElementName = "GoodsByPeriod" + "Count_" + Period.ColumnName
						Or CurElementName = "GoodsByPeriod" + "PictureComment_" + Period.ColumnName Then
						StructureOfData.Formula 				= CurrentData["Formula_" + Period.ColumnName];
						StructureOfData.FormulaPresentation 	= CurrentData["FormulaPresentation_" + Period.ColumnName];
						StructureOfData.PeriodOfChange 		= Period.ColumnName;
					EndIf;
				EndDo;
			EndIf;
			
		Else
			
			For Each Period In ActivePeriods Do
				StructureOfData.Formula 				= CurrentData["Formula_" + Period.ColumnName];
				StructureOfData.FormulaPresentation 	= CurrentData["FormulaPresentation_" + Period.ColumnName];
				StructureOfData.PeriodOfChange 		= Period.ColumnName;
			EndDo;
			
		EndIf;
		
	Else
		
		CurrentData = Items.Goods.CurrentData;
		RowsArray.Add(CurrentData.GetID());
		
		For Each Operand In AdditionalFields Do
			If CurrentData.Property(Operand.Id) Then
				Operand.Value = CurrentData[Operand.Id];
			EndIf;
		EndDo;
		
		StructureOfData.Formula 				= CurrentData.Formula;
		StructureOfData.FormulaPresentation 	= CurrentData.FormulaPresentation;
		StructureOfData.PeriodOfChange 		= "AllPeriods";
		
	EndIf;
	
	StructureOfData.EnableValue 	= True;
	StructureOfData.RowsArray 		= RowsArray;
	
	SetDecryptionParameters(StructureOfData);
	
	SetArbitraryFormula(StructureOfData);
	
EndProcedure

&AtClient
Procedure AfterOpeningConstructorSetArbitraryFormula(Result, StructureOfData) Export
	
	RowsArray = StructureOfData.RowsArray;
	
	If Not ValueIsFilled(Result) Then
		Return;
	EndIf;
	
	If Object.CrossTable Then
		
		If StructureOfData.Property("PeriodOfChange") Then
			PeriodName = StructureOfData.PeriodOfChange;
		Else
			PeriodName = "AllPeriods";
		EndIf;
		
		For Each LineID In RowsArray Do
			
			For Each Period In ThisForm.TimeIntervals.FindRows(New Structure("Active_", True)) Do
				
				If PeriodName <> "AllPeriods" Then
					
					RowOfGoods = GoodsByPeriod.FindByID(LineID);
					
					If PeriodName = Period.ColumnName Then
						
						CalculationResult = PlanningClient.CalculateByFormula(Result.Formula, RowOfGoods,
							ThisForm.TimeIntervals, Period, Result.Presentation);
						RowOfGoods["Formula_" + Period.ColumnName] = Result.Formula;
						RowOfGoods["FormulaPresentation_" + Period.ColumnName] = CalculationResult.Presentation;
						RowOfGoods["FormulaCalculation_" + Period.ColumnName] = CalculationResult.Calculation;
						RowOfGoods["Count_" + Period.ColumnName] = CalculationResult.Result;
						RowOfGoods["Deviation_" + Period.ColumnName] = 0;
						
						WhenChangingAmountOfRowSum(Object, ThisForm, RowOfGoods);
						
						PlanningClientServer.DisplayValueOfAdditionalParameters(ThisObject, 
							GetAdditionalBankingDetails(ThisObject), "GoodsByPeriod");
						
					ElsIf ValueIsFilled(RowOfGoods["Formula_" + Period.ColumnName]) 
												And RowOfGoods["Deviation_" + Period.ColumnName] = 0 Then
						
						CalculationResult = PlanningClient.CalculateByFormula(
							RowOfGoods["Formula_" + Period.ColumnName],
							RowOfGoods, ThisForm.TimeIntervals, Period, Result.Presentation);
						RowOfGoods["FormulaPresentation_" + Period.ColumnName] = CalculationResult.Presentation;
						RowOfGoods["FormulaCalculation_" + Period.ColumnName] = CalculationResult.Calculation;
						RowOfGoods["Count_" + Period.ColumnName] = CalculationResult.Result;
						
						WhenChangingAmountOfRowSum(Object, ThisForm, RowOfGoods);
						
					EndIf;
					
				ElsIf PeriodName = "AllPeriods" Then
					
					RowOfGoods = GoodsByPeriod.FindByID(LineID);
					CalculationResult = PlanningClient.CalculateByFormula(Result.Formula, RowOfGoods, 
						ThisForm.TimeIntervals, Period, Result.Presentation);
					RowOfGoods["Formula_" + Period.ColumnName] = Result.Formula;
					RowOfGoods["FormulaPresentation_" + Period.ColumnName] = CalculationResult.Presentation;
					RowOfGoods["FormulaCalculation_" + Period.ColumnName] = CalculationResult.Calculation;
					RowOfGoods["Count_" + Period.ColumnName] = CalculationResult.Result;
					RowOfGoods["Deviation_" + Period.ColumnName] = 0;
					
					WhenChangingAmountOfRowSum(Object, ThisForm, RowOfGoods);
					
					PlanningClientServer.DisplayValueOfAdditionalParameters(ThisObject, 
						GetAdditionalBankingDetails(ThisObject), "GoodsByPeriod");
					
				EndIf;
				
			EndDo;
			
		EndDo;
		
		CalculateTotals_(ThisForm, False);
		
	Else
		
		For Each LineID In RowsArray Do
			
			RowOfGoods = Object.Goods.FindByID(LineID);
			CalculationResult = PlanningClient.CalculateByFormula(Result.Formula, RowOfGoods, Undefined,
				Undefined, Result.Presentation);
			RowOfGoods.Formula = Result.Formula;
			RowOfGoods.FormulaPresentation = CalculationResult.Presentation;
			RowOfGoods.FormulaCalculation = CalculationResult.Calculation;
			RowOfGoods.NumberOfPackages = CalculationResult.Result;
			RowOfGoods.Deviation = 0;
			
			RecalculateNumberOfPackagesAndAmountPerLine(RowOfGoods, CachedValues);
			
		EndDo;
		
		CalculateTotals_(ThisObject);
		
	EndIf;
	
	Modified = True;
	
EndProcedure

// Parameters:
// 	Form - ClientApplicationForm - LongDesc
// Returns:
// 	Array of See Planning.FieldStructure -
&AtClientAtServerNoContext
Function GetAdditionalBankingDetails(Form)
	
	AddAttributes = New Array();

	If Form.AdditionalParametersGoodsByPeriods = Undefined Then
		Return AddAttributes;
	EndIf;

	For Each Field In Form.AdditionalParametersGoodsByPeriods Do
		If Field.Value.CreateProps Then
			AddAttributes.Add(Field.Value);
		EndIf;
	EndDo;

	Return AddAttributes;
	
EndFunction

// Parameters:
// 	Form - ClientApplicationForm - LongDesc
// Returns:
// 	Array of See Planning.FieldStructure - 
&AtClientAtServerNoContext
Function GetOperands(Form)
	
	ArrayOfOperands = New Array();

	If Form.AdditionalParametersGoodsByPeriods = Undefined Then
		Return ArrayOfOperands;
	EndIf;

	For Each Field In Form.AdditionalParametersGoodsByPeriods Do
		If Field.Value.CreateOperand Then
			ArrayOfOperands.Add(Field.Value);
		EndIf;
	EndDo;

	Return ArrayOfOperands;
	
EndFunction

&AtServer
Function PlaceAdditionalFieldsInStorage()
	
	Return Planning.PlaceAdditionalFieldsInStorage(ThisForm, SettingsStructure.PeriodOffset);
	
EndFunction

&AtServer
Procedure AddTemplatesForFormulasForCalculatingPlannedQuantity(Tree, OperatorsGroup)
	
	Scenario = Planning.ScriptParameters_(Object.Scenario);

	UseSalesPlans_ 				= GetFunctionalOption("UseSalesPlans")
		And Scenario.UseInSalesPlanning;
	UseInternalConsumptionPlans 	= GetFunctionalOption("UsePlanningOfInventoryConsumption")
		And Scenario.UseInPlanningOfInternalConsumption;
	UseProduction 				= GetFunctionalOption("UseProduction");
	UseProductionPlanning 	= GetFunctionalOption("UseProductionPlanning")
		And Scenario.UseInProductionPlanning;
	UseForMaterialsPlanning 	= GetFunctionalOption("UseProductionPlanning")
		And Scenario.UseForMaterialsPlanning;
	UseProcurementPlans 				= GetFunctionalOption("UsePurchasePlanning")
		And Scenario.UseInPurchasePlanning;
	UseBuildPlans 				= GetFunctionalOption("UseAssemblyDisassemblyPlanning")
		And Scenario.UseInAssemblyDisassemblyPlanning;
	UseRemainderPlans 				= GetFunctionalOption("UsePlanningOfGoodsStock")
		And Scenario.UseInBalancePlanning;

	StructureToInsert = "[InventoryConsumptionPlans] * 1.15";
	Id = StructureToInsert;
	Presentation = NStr("vi = 'Kế hoạch tiêu dùng nội bộ +15%';
						|ru = 'План внутренних потреблений +15%';
						|en = 'Inventory consumption plan +15%'; fa = 'Inventory consumption plan +15%';
						|it = 'Piano di consumi interni +15%';
						|pl = 'Plan konsumpcji wewnętrznych +15%';
						|tr = 'İç tüketim planı +15%'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation);

	StructureToInsert = "Max([FactsOfDomesticConsumption], [InventoryConsumptionPlans])"
		+ ?(UseRemainderPlans," - [PlansOfGoodsStock]",
			?(PlanningByAssignments," - [ActualStartBalance]"," - [AvailableStock]"));
	Id = StructureToInsert;
	Presentation = NStr("vi = 'Kế hoạch tiêu dùng nội bộ có tính đến điều chỉnh theo thực tế tiêu dùng nội bộ';
						|ru = 'План внутренних потреблений с учетом корректировки по факту внутренних потреблений';
						|en = 'Inventory consumption plan taking into account adjustment on actual inventory consumption'; fa = 'Inventory consumption plan taking into account adjustment on actual inventory consumption';
						|it = 'Piano di consumi interni tenendo conto della correzione basata sui consumi interni di fatto';
						|pl = 'Plan konsumpcji wewnętrznych z uwzględnieniem korekty wg fakut konsumpcji wewnętrznych';
						|tr = 'Yurt içi tüketim bilgisine göre yurt içi tüketim planına dair düzeltmeler'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation);

	StructureToInsert = "[FactsOfDomesticConsumption] / [ShareOfStockAvailabilityDays]";
	Id = StructureToInsert;
	Presentation = NStr("vi = 'Thực tế tiêu thụ nội bộ có tính đến hàng hóa có sẵn trong kho';
						|ru = 'Факт внутренних потреблений с учетом наличия товаров на остатках';
						|en = 'Actual internal consumption, taking into account the presence of goods on the balances'; fa = 'Actual internal consumption, taking into account the presence of goods on the balances';
						|it = 'Fatto di consumi interni tenendo conto di merce presente nelle rimanenze';
						|pl = 'Fakt konsumpcji wewnętrznych, z uwzględnieniem dostępności towarów w pozostałościach';
						|tr = 'Stoklardaki ürünlerin durumuna dair stok tüketim bilgisi'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation);

	StructureToInsert = ?(UseSalesPlans_,"[SalesPlans]","0")
		+ ?(UseProduction And UseForMaterialsPlanning," + [ProductionPlansMaterials]","")
		+ ?(UseBuildPlans," + [BuildPlansComponents]","")
		+ ?(UseBuildPlans," + [DisassemblyPlansKits]","")
		+ ?(UseInternalConsumptionPlans," + [InventoryConsumptionPlans]","");
	Id = StructureToInsert;
	Presentation = NStr("vi = 'Kế hoạch nhu cầu';
						|ru = 'Планы потребностей';
						|en = 'Demand plans'; fa = 'برنامه‌های نیاز';
						|it = 'Piani dei fabbisogni';
						|pl = 'Plany zapotrzebowania';
						|tr = 'Gereksinimlerin planı'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation);
	
	StructureToInsert = ?(UseProcurementPlans,"[PurchasePlans]","0")
		+ ?(UseProduction And UseProductionPlanning," + [ProductionPlans]","")
		+ ?(UseBuildPlans," + [AssemblyPlansKits]","")
		+ ?(UseBuildPlans," + [DisassemblyPlansComponents]","");
	Id = StructureToInsert;
	Presentation = NStr("vi = 'Kế hoạch đảm bảo';
						|ru = 'Планы обеспечения';
						|en = 'Supply plans'; fa = 'برنامه‌های تأمین';
						|it = 'Piani di approvvigionamento';
						|pl = 'Plany zaspokojenia';
						|tr = 'Teminat planı'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation);
	
	StructureToInsert = ?(UseProcurementPlans,"[PurchasePlans]","0")
		+ ?(UseProduction And UseProductionPlanning," + [ProductionPlans]","")
		+ ?(UseProduction And UseForMaterialsPlanning," - [ProductionPlansMaterials]","")
		+ ?(UseBuildPlans," + [AssemblyPlansKits]","")
		+ ?(UseBuildPlans," + [DisassemblyPlansComponents]","")
		+ ?(UseSalesPlans_," - [SalesPlans]","")
		+ ?(UseBuildPlans," - [BuildPlansComponents]","")
		+ ?(UseBuildPlans," - [DisassemblyPlansKits]","")
		+ ?(UseInternalConsumptionPlans," - [InventoryConsumptionPlans]","");
	Id = StructureToInsert;
	Presentation = NStr("vi = 'Chênh lệch giữa các kế hoạch';
						|ru = 'Отклонение планов';
						|en = 'Plan variance'; fa = 'Plan variance';
						|it = 'Scostamento dei piani';
						|pl = 'Odrzucenie planów';
						|tr = 'Fark planı'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation);
	
	StructureToInsert = "ColumnValue(CurrentColumnNumber() - 1)";
	Id = StructureToInsert;
	Presentation = NStr("vi = 'Giá trị cột trước đó';
						|ru = 'Значение предыдущей колонки';
						|en = 'Previous column value'; fa = 'Previous column value';
						|it = 'Valore della colonna precedente';
						|pl = 'Poprzednia wartość kolumny';
						|tr = 'Önceki sütunun anlamı'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation);
	
EndProcedure

&AtClient
Procedure SetUpFormulaAndFillIn(Settings, AdditionalParameters) Export
	
	If TypeOf(Settings) <> Type("Structure") Then
		Return;
	EndIf;
	
	SettingsStructure = Settings;
	
	If SettingsStructure.ContentFillingVariant = "Filter" Then
		
		GoodsByPeriod.Clear();
		Object.Goods.Clear();
		CalculateNumberOfRows(ThisForm);
		
		Notification = New CallbackDescription("SetUpFormulaAndFillInCompletion", ThisObject, Settings);
		AddProductsBySelectionOnClient(Notification);
		Return;
		
	ElsIf SettingsStructure.ContentFillingVariant = "DoNotChange" Then
		
		Settings.Insert("FillInUsingFormula", True);
		Settings.Insert("PopulateOperands", True);
		If Settings.Property("FillingComposition") Then
			Settings.Delete("FillingComposition");
		EndIf;
		
		FillInDocument(Settings);
		
	Else
		
		Settings.Insert("FillInUsingFormula", True);
		Settings.Insert("PopulateOperands", True);
		Settings.Insert("FillingComposition", True);
		
		FillInDocument(Settings);
		
	EndIf;
	
	If Object.CrossTable And Items.GoodsByPeriod.CurrentData = Undefined Then
		PlanningClientServer.ClearFormulaValue(ThisObject);
	EndIf;
	
	CalculateNumberOfRows(ThisForm);
	
EndProcedure

&AtClient
Procedure SetUpFormulaAndFillInCompletion(Result, Settings) Export
	
	If ValueIsFilled(Result) Then
		
		If Not Object.CrossTable Then
			FillInProductCompositionBySelection(CachedValues);
		EndIf;
		
		Settings.Insert("FillInUsingFormula", True);
		Settings.Insert("PopulateOperands", True);
		If Settings.Property("FillingComposition") Then
			Settings.Delete("FillingComposition");
		EndIf;
		
		FillInDocument(Settings);
		
	EndIf;
	
	If Object.CrossTable And Items.GoodsByPeriod.CurrentData = Undefined Then
		PlanningClientServer.ClearFormulaValue(ThisObject);
	EndIf;
	
	CalculateNumberOfRows(ThisForm);
	
EndProcedure

&AtClient
Procedure AdjustOffsetAndFill(Settings, AdditionalParameters) Export
	
	If TypeOf(Settings) <> Type("Structure") Then
		Return;
	EndIf;
	
	SettingsStructure = Settings;
	
	Settings.Insert("FillInUsingFormula", True);
	Settings.Insert("PopulateOperands", True);
	If Settings.Property("FillingComposition") Then
		Settings.Delete("FillingComposition");
	EndIf;
	
	FillInDocument(Settings);
	
EndProcedure

&AtClient
Procedure AddProductsBySelectionOnClient(NotificationOfAddition = Undefined)
	
	FilterByProductType = ProductsClientServer.SelectionByProductMultiTurnContainer(False);
	FilterByProductType.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
	
	FormParameters = New Structure();
	FormParameters.Insert("Title",               NStr("vi = 'Chọn hàng hóa';
														|ru = 'Подбор товаров';
														|en = 'Pick goods'; fa = 'انتخاب کالاها';
														|it = 'Selezione delle merci';
														|pl = 'Wybór towarów';
														|tr = 'Ürünlerin seçimi'"));
	FormParameters.Insert("UUID", UUID);
	FormParameters.Insert("FilterByProductType", FilterByProductType);
	If SettingsStructure.Property("SelectionOfProductsSettings") Then
		FormParameters.Insert("SelectionOfProductsSettings", SettingsStructure.SelectionOfProductsSettings);
	Else
		FormParameters.Insert("SelectionOfProductsSettings", Undefined)
	EndIf;
	
	AdditionalParameters = New Structure("NotificationOfAddition", NotificationOfAddition);
	Notification = New CallbackDescription("AddGoodsByPickingCompletion", ThisObject, AdditionalParameters);
	
	OpenForm(
		"DataProcessor.GoodsSelectionByPicking.Form",
		FormParameters,
		ThisForm,
		UUID,
		,
		,
		Notification, 
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AddGoodsByPickingCompletion(Result, AdditionalParameters) Export
	
	If ValueIsFilled(Result) Then
		
		ProcessingSelectionOfSelectionOnServer(CachedValues, New Structure("GoodsAddressInStorage", Result));
		
		NotifyUserAboutFillingInData();
		
	EndIf;
	
	If AdditionalParameters.NotificationOfAddition <> Undefined Then
	
		RunCallback(AdditionalParameters.NotificationOfAddition, Result);
	
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInProductCompositionBySelection(CachedValues)
	
	TablePeriods = ThisForm.TimeIntervals; // See Planning.TablePeriods
	ActivePeriods = TablePeriods.FindRows(New Structure("Active_", True));
	
	ProductByFilter = Object.Goods.Unload();
	
	Object.Goods.Clear();
	
	For Each Period In ActivePeriods Do
	
		For Each RowOfProduct In ProductByFilter Do
		
			CurrentRow = Object.Goods.Add();
			FillPropertyValues(CurrentRow, RowOfProduct);
			CurrentRow.DateOfShipment = Period.StartDate;
			CurrentRow.Formula = SettingsStructure.Formula;
			CurrentRow.FormulaPresentation = SettingsStructure.FormulaPresentation;
			CurrentRow.FormulaCalculation = SettingsStructure.Formula;
		
		EndDo;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure SetDecryptionParameters(StructureOfData)
	
	If Object.CrossTable Then
		CurrentData = Items.GoodsByPeriod.CurrentData;
	Else
		CurrentData = Items.Goods.CurrentData;
	EndIf;
	
	PlanType = PredefinedValue("Enum.TypesOfPlans.InventoryConsumptionPlan");
	FilterParameters = FilterParameters(ThisForm);
	PlanViewParameters = PlanViewParameters(ThisForm);
	FilterIndicators = PlanningClientServer.SelectionToFillInIndicators(PlanType, 
		FilterParameters, PlanViewParameters);
	FilterIndicators.Insert("Products", 		CurrentData.Products);
	FilterIndicators.Insert("Characteristic", 		CurrentData.Characteristic);
	
	QueryOptions = New Structure();
	QueryOptions.Insert("Ref", 			Object.Ref);
	QueryOptions.Insert("Periodicity", 		Object.Periodicity);
	QueryOptions.Insert("PeriodOffset", 	AdditionalSettings(SettingsStructure).PeriodOffset);
	QueryOptions.Insert("Scenario", 			Object.Scenario);
	QueryOptions.Insert("Fields", 				AdditionalParametersGoodsByPeriods);
	QueryOptions.Insert("Filter", 				FilterIndicators);
	
	SetRequestPeriod(QueryOptions);
	
	StructureOfData.Insert("DetailsParameters", QueryOptions);
	
EndProcedure

&AtClient
Procedure SetRequestPeriod(QueryOptions)
	
	If Object.CrossTable Then
		
		CurElementName = Items.GoodsByPeriod.CurrentItem.Name;
		
		TablePeriods = ThisForm.TimeIntervals; // See Planning.TablePeriods
		For Each Period In TablePeriods.FindRows(New Structure("Active_", True)) Do
			If CurElementName = "GoodsByPeriod" + "Count_" + Period.ColumnName Then
				QueryOptions.Insert("OffsetPeriodStart", Period.StartDate);
				QueryOptions.Insert("OffsetPeriodEnd",  Period.EndDate);
			EndIf;
		EndDo;

	Else
		
		CurrentData = Items.Goods.CurrentData;
		
		TablePeriods = ThisForm.TimeIntervals; // See Planning.TablePeriods
		RowsArray = TablePeriods.FindRows(New Structure("StartDate, Active_", CurrentData.DateOfShipment, True));
		
		If RowsArray.Count() > 0 Then
			QueryOptions.Insert("OffsetPeriodStart", 	RowsArray[0].StartDate);
			QueryOptions.Insert("OffsetPeriodEnd", 	RowsArray[0].EndDate);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function AdditionalSettings(SettingsStructure, AdditionalFields = Undefined)
	
	If Not TypeOf(SettingsStructure) = Type("Structure") Then
		
		SettingsStructure = New Structure();
		SettingsStructure.Insert("ContentFillingVariant", "Filter");
		
		SettingsStructure.Insert("OffsetOption", "PreviousPeriod_");
		SettingsStructure.Insert("PeriodOffset", -1);
		
		SettingsStructure.Insert("Formula","[InventoryConsumptionPlans] * 1.15");
		SettingsStructure.Insert("FormulaPresentation",
			NStr("vi = 'Tăng 15% trong kế hoạch tiêu thụ so với các kỳ trước';
				|ru = 'Увеличение планов внутренних потреблений прошлых периодов на 15%';
				|en = 'Previous period inventory consumption plans increase by 15%'; fa = 'Previous period inventory consumption plans increase by 15%';
				|it = 'Aumento del 15% dei piani di consumi interni per i periodi scorsi';
				|pl = 'Zwiększenie planów konsumpcji wewnętrznych wcześniejszych okresów o 15%';
				|tr = 'Önceki dönemlerin stok tüketim planlarının yüzde 15 artırılması'"));
		
		SettingsStructure.Insert("FilterEmptyLines", False);
		
	Else
		
		If SettingsStructure.Property("Offset") Then
			SettingsStructure.Insert("PeriodOffset", -1 * SettingsStructure.Offset);
			SettingsStructure.Delete("Offset");
		EndIf;
		
		If AdditionalFields <> Undefined Then
			ArrayOfOperands = New Array;
			For Each CurRow In AdditionalFields Do
				
				ArrayOfOperands.Add(CurRow.Id);
				
			EndDo;
			
			ResultType = New TypeDescription("Number");
			#If Client Then
				CheckParameters = ProcessingOfFormulasClient.FormulaValidationParameters();
				CheckParameters.NotOutputMessages = True;
				WorkingWithFormulasCheckFormula = ProcessingOfFormulasClient.CheckFormula(SettingsStructure.Formula,
					ArrayOfOperands, ResultType, CheckParameters);
			#Else
				CheckParameters = ProcessingOfFormulas.FormulaValidationParameters();
				CheckParameters.NotOutputMessages = True;
				WorkingWithFormulasCheckFormula = ProcessingOfFormulas.CheckFormula(SettingsStructure.Formula,
					ArrayOfOperands, ResultType, CheckParameters);
			#EndIf
			
			If Not WorkingWithFormulasCheckFormula Then
				
				SettingsStructure.Insert("Formula","[InventoryConsumptionPlans] * 1.15");
				SettingsStructure.Insert("FormulaPresentation",
					NStr("vi = 'Tăng 15% trong kế hoạch tiêu thụ so với các kỳ trước';
						|ru = 'Увеличение планов внутренних потреблений прошлых периодов на 15%';
						|en = 'Previous period inventory consumption plans increase by 15%'; fa = 'Previous period inventory consumption plans increase by 15%';
						|it = 'Aumento del 15% dei piani di consumi interni per i periodi scorsi';
						|pl = 'Zwiększenie planów konsumpcji wewnętrznych wcześniejszych okresów o 15%';
						|tr = 'Önceki dönemlerin stok tüketim planlarının yüzde 15 artırılması'"));
				SettingsStructure.Insert("FilterEmptyLines", False);
				
			EndIf;
		EndIf;
	
	EndIf;
	
	If Not SettingsStructure.Property("FilterEmptyLines") Then
		SettingsStructure.Insert("FilterEmptyLines", False);
	EndIf;
	
	Return SettingsStructure;
	
EndFunction

&AtServer
Procedure RecordAdditionalParameters(DocumentObject)
	
	AddlAttributesArray = GetAdditionalBankingDetails(ThisObject);
	
	For Each CurrentRow In DocumentObject.Goods Do
		
		CollectionItem = Object.Goods.Get(CurrentRow.LineNumber-1);
		If CollectionItem = Undefined Then
			Continue;
		EndIf;
		
		AddnlParameter_ = CurrentRow.AdditionalParameters.Get();
		
		If TypeOf(AddnlParameter_) <> Type("Structure") Then
			AddnlParameter_ = New Structure();
		EndIf;
		
		For Each AdditionalAttribute5 In AddlAttributesArray Do
			
			Id = AdditionalAttribute5.Name;
			
			If CollectionItem.Property(Id) Then
			
				AddnlParameter_.Insert(Id,CollectionItem[Id]);
			
			EndIf;
			
		EndDo;
		
		CurrentRow.AdditionalParameters = New ValueStorage(AddnlParameter_);
	
	EndDo;
	
EndProcedure

&AtServer
Procedure ReadMoreParameters(DocumentObject)
	
	For Each CurrentRow In DocumentObject.Goods Do
		
		CollectionItem = Object.Goods.Get(CurrentRow.LineNumber-1);
		If CollectionItem = Undefined Then
			Continue;
		EndIf;
		
		AddAttributes = CurrentRow.AdditionalParameters.Get();
		
		If TypeOf(AddAttributes) <> Type("Structure") Then
			Continue;
		EndIf;
		
		For Each AdditionalAttribute5 In AddAttributes Do
		
			Id = AdditionalAttribute5.Key;
			
			If CollectionItem.Property(Id) Then
				CollectionItem[Id] = AdditionalAttribute5.Value;
			EndIf;
		
		EndDo;
		
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure RecalculateNumberOfPackagesAndAmountPerLine(CurrentRow, CachedValues)
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);

	#If Client Then
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	#Else
		BatchProcessingOfTablePartServer.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	#EndIf
	
EndProcedure

&AtClient
Procedure WhenChangingQuantityDeviation(RowOfGoods)
	
	For Each Period In ThisForm.TimeIntervals.FindRows(New Structure("Active_", True)) Do
		
		If Not ValueIsFilled(RowOfGoods["Formula_" + Period.ColumnName]) Then
			Continue;
		EndIf;
		
		CalculationResult = PlanningClient.CalculateByFormula(RowOfGoods["Formula_" + Period.ColumnName],
																	RowOfGoods, ThisForm.TimeIntervals, Period);
		
		If Items.GoodsByPeriod.CurrentItem.Name = "GoodsByPeriod" + "Count_" + Period.ColumnName Then
			RowOfGoods["Deviation_" + Period.ColumnName] = CalculationResult.Result 
				- RowOfGoods["Count_" + Period.ColumnName];
		ElsIf RowOfGoods["Deviation_" + Period.ColumnName] = 0 Then
			RowOfGoods["Count_" + Period.ColumnName] = CalculationResult.Result;
		EndIf;
		
	EndDo;
	
	PlanningClientServer.DisplayValueOfAdditionalParameters(ThisObject, 
		GetAdditionalBankingDetails(ThisObject), "GoodsByPeriod");
	
EndProcedure

&AtServer
Procedure UpdateOutputStructureOfAdditionalParameters()
	
	TableOutputParameters = New Structure("Fields", AdditionalGoodsParameters);
	Planning.UpdateTableOutputStructure(ThisObject, TableOutputParameters);
	
	CrossTableOutputParameters = New Structure("Fields", AdditionalParametersGoodsByPeriods);
	Planning.UpdateTableOutputStructure(ThisObject, CrossTableOutputParameters);
	
EndProcedure

&AtServer
Procedure AddFieldsFromAdditionalParameters(OutputParameters)
	
	AddAttributes = GetAdditionalBankingDetails(ThisObject);
	
	For Each AdditionalAttribute5 In AddAttributes Do
		FieldStructure = New Structure;
		FieldStructure.Insert("ColumnAttributePrefix", AdditionalAttribute5.Name + "_");
		FieldStructure.Insert("DeleteTableDetails", AdditionalAttribute5.DeleteTableDetails);
		FieldStructure.Insert("CreateElement_", False);
		FieldStructure.Insert("ElementType", AdditionalAttribute5.Type);
		FieldStructure.Insert("CreateSummaryDetails", False);
		
		OutputParameters.Fields.Add(FieldStructure);
	EndDo;
	
EndProcedure

&AtServer
Procedure AddBankingDetailsFromAdditionalParameters(AttributesStructure1)
	
	AddAttributes = GetAdditionalBankingDetails(ThisObject);
	
	For Each AdditionalAttribute5 In AddAttributes Do
		AttributesStructure1.Insert(AdditionalAttribute5.Name + "_", AdditionalAttribute5.Name);
	EndDo;
	
EndProcedure

&AtClient
Procedure SwitchPeriodsToColumnsCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		
		ClearMessages();
		
		SwitchPeriodsToColumnsOnServer(CachedValues);
		
	EndIf;
	
	SetCrossTableTag(ThisForm);
	
EndProcedure

&AtClient
Procedure SwitchPeriodsToRowsCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.No Then
		Return;
	EndIf;
	
	SwitchPeriodsToRows(Undefined);
	
EndProcedure

&AtServer
Procedure SwitchPeriodsToColumnsOnServer(CachedValues)
	
	Object.CrossTable = True;
	WhenChangingPeriodsOnServer();
	CopyToCrossTable(CachedValues);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetCrossTableTag(Form)
	
	If Form.Object.CrossTable Then
	
		Form.Items.FormSwitchPeriodsToColumns.Check = True;
		Form.Items.FormSwitchPeriodsToRows.Check = False;
		
		Form.Items.ProductsGroupViews.CurrentPage = Form.Items.ProductsGroupCrossTable;
	
	Else
	
		Form.Items.FormSwitchPeriodsToColumns.Check = False;
		Form.Items.FormSwitchPeriodsToRows.Check = True;
		
		Form.Items.ProductsGroupViews.CurrentPage = Form.Items.GroupProductsTable;
		
		Form.TotalByLineByColumn = "";
	
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateNumberOfRows(Form)
	
	If Form.Object.CrossTable Then
	
		Form.GoodsLineQuantity = Form.GoodsByPeriod.Count();
	
	Else
	
		Form.GoodsLineQuantity = Form.Object.Goods.Count();
	
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function PlanViewParameters(Form)
	
	PlanViewParameters = New Structure("FillInBusinessUnit, FillInWarehouse,
		|PlanningByAssignments, FillInAssignmentInTabularForm, FillInWarehouseInTabularForm");
	FillPropertyValues(PlanViewParameters, Form);
	
	Return PlanViewParameters;
	
EndFunction

&AtClientAtServerNoContext
Function FilterParameters(Form)
	
	FilterParameters = New Structure("Warehouse, Department, PlanningByAssignments, Purpose");
	FillPropertyValues(FilterParameters, Form.Object);
	
	Return FilterParameters;
	
EndFunction

#Region FillingInBackground

&AtClient
Procedure FillInDocument(Settings)
	
	NotifyUserAboutStartOfFillingInData();
	
	TimeConsumingOperation    = FillInDocumentOnServer(Settings, CachedValues);
	CallbackOnCompletion = New CallbackDescription("FillInDocumentCompletion", ThisObject);
	IdleParameters     = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
	If Object.FillInUsingFormula
		And Object.CrossTable Then
		PlanningClientServer.DisplayValueOfAdditionalParameters(ThisObject,
			GetAdditionalBankingDetails(ThisObject), "GoodsByPeriod");
	EndIf;
	
	NotifyUserAboutFillingInData();
	
EndProcedure

&AtClient
Procedure FillInDocumentCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	GetResultOfFillingOnServer(CachedValues, Result.ResultAddress);
	
EndProcedure

&AtServerNoContext
Procedure ProcessFillingResultUsingFormula(Form)
	
	LastPeriod = Form.TimeIntervals[Form.TimeIntervals.Count()-1];
	LinesToDelete = New Array;
	PreviousPeriod_ = Undefined;
	AdjustmentSign = Planning.GetAdjustmentSign(Form);
	If Form.Object.Substitutional Then
		MainOperandOfPlan = Planning.MainOperandOfPlan(Form);
		MainOperandOfPlanWithSelection = Planning.MainOperandOfPlan(Form, True);
	Else
		MainOperandOfPlan = "";
		MainOperandOfPlanWithSelection = "";
	EndIf;
	
	TablePeriods = Form.TimeIntervals; // See Planning.TablePeriods
	For Each Period In TablePeriods Do
		For Each RowOfGoods In Form.GoodsByPeriod Do
			
			If Form.PlannedBalanceIsUsed Then
				NewPlanOfRemnants = Form.BalancePlansPeriods.FindByValue(Period.StartDate) <> Undefined;
				NewResiduePlanWithSelection = Form.BalancePlanPeriodsWithSelection.FindByValue(Period.StartDate) <> Undefined;
				
				Planning.CalculateCalculatedOperands(RowOfGoods, Period, PreviousPeriod_,
					NewPlanOfRemnants, "_", MainOperandOfPlan, AdjustmentSign);
				Planning.CalculateCalculatedOperands(RowOfGoods, Period, PreviousPeriod_,
					NewResiduePlanWithSelection, "WithSelection_", MainOperandOfPlanWithSelection, AdjustmentSign);
			EndIf;
			
			If Period.Active_ Then
				
				CalculationResult = Planning.CalculateByFormula(Form.SettingsStructure.Formula, RowOfGoods,
					Form.TimeIntervals, Period, Form.SettingsStructure.FormulaPresentation);
				
				If Form.PlannedBalanceIsUsed Then
					RowOfGoods["AccumulatedPlannedClosingShortage_"+Period.ColumnName] = RowOfGoods["AccumulatedPlannedClosingShortage_"+Period.ColumnName]
					+ AdjustmentSign * CalculationResult.Result;
					
					If RowOfGoods.Property("AccumulatedPlannedClosingShortageWithSelection_"+Period.ColumnName) Then
						RowOfGoods["AccumulatedPlannedClosingShortageWithSelection_"+Period.ColumnName] = RowOfGoods["AccumulatedPlannedClosingShortageWithSelection_"+Period.ColumnName]
						+ AdjustmentSign * CalculationResult.Result;
					EndIf;
				EndIf;
				
				RowOfGoods["Formula_" + Period.ColumnName] = Form.SettingsStructure.Formula;
				RowOfGoods["FormulaPresentation_" + Period.ColumnName] = CalculationResult.Presentation;
				RowOfGoods["FormulaCalculation_" + Period.ColumnName] = CalculationResult.Calculation;
				RowOfGoods["Count_" + Period.ColumnName] = CalculationResult.Result;
				RowOfGoods["Deviation_" + Period.ColumnName] = 0;
				
				WhenChangingAmountOfRowSum(Form.Object, Form, RowOfGoods);
				
			EndIf;
			
			If Period = LastPeriod
				And RowOfGoods.NumberOfPackages = 0 Then
				LinesToDelete.Add(RowOfGoods);
			EndIf;
				
		EndDo;
		
		PreviousPeriod_ = Period;
		
	EndDo;
	
	If Form.SettingsStructure.ContentFillingVariant = "Formula"
		Or Form.SettingsStructure.FilterEmptyLines Then
		For Each RowToDelete In LinesToDelete Do
			Form.GoodsByPeriod.Delete(RowToDelete);
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Function FillInDocumentOnServer(Val JobParameters, CachedValues)
	
	If JobParameters.Property("FillInUsingFormula") Then
		
		PrepareParametersForFillingInDocumentUsingFormula(JobParameters, CachedValues);
		
	ElsIf JobParameters.Property("FillInRule") Then
		
		PrepareParametersForFillingInDocumentAccordingToFillingRule(JobParameters, CachedValues);
		
	ElsIf JobParameters.Property("FillInForReplacement") Then
		
		PrepareParametersForFillingInReplacementDocument(JobParameters, CachedValues);
		
	EndIf;
	
	JobDescription = NStr("vi = 'Điền chứng từ kế hoạch:';
							|ru = 'Заполнение документа плана:';
							|en = 'Fill in document of payment schedule:'; fa = 'Fill in document of payment schedule:';
							|it = 'Compilazione del documento di piano:';
							|pl = 'Wypełnianie dokumentu planu:';
							|tr = 'Belge doldurma planı:'") + " " + String(Object.Ref);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = JobDescription;
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.RunInBackground = True;
	
	Result = TimeConsumingOperations.ExecuteInBackground(
		"Documents.InventoryConsumptionPlan.FillInDocument",
		JobParameters, ExecutionParameters);
	
	If JobParameters.Property("FillInUsingFormula") Then
		StorageAddressAdditional = Result.AdditionalResultAddress;
	Else 
		StorageAddressAdditional = "";
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Function PrepareParametersForFillingInReplacementDocument(JobParameters, CachedValues)
	
	CopyFromCrossTable(CachedValues, Object);
	
	PlanType = Enums.TypesOfPlans.InventoryConsumptionPlan;
	FillingStatuses = Planning.GetFillInStatuses(Object.Scenario);
	
	JobParameters.Insert("Ref",                  Object.Ref);
	JobParameters.Insert("UUID", UUID);
	JobParameters.Insert("Scenario",                Object.Scenario);
	JobParameters.Insert("PlanProfile",                Object.PlanProfile);
	JobParameters.Insert("CrossTable",            Object.CrossTable);
	JobParameters.Insert("Status",                  Object.Status);
	JobParameters.Insert("Statuses",                 FillingStatuses);
	JobParameters.Insert("Periodicity",           Object.Periodicity);
	JobParameters.Insert("OffsetPeriodStart",   Object.BeginOfPeriod);
	JobParameters.Insert("OffsetPeriodEnd",    Object.PeriodEnding);
	
	JobParameters.Insert("PlanType",                PlanType);
	JobParameters.Insert("Department",           Object.Department);
	JobParameters.Insert("Warehouse",                   Object.Warehouse);
	
	JobParameters.Insert("FillInAssignmentInTabularForm", 
		Common.ObjectAttributeValue(Object.PlanProfile,"FillInAssignmentInTabularForm"));
	JobParameters.Insert("Purpose",              Object.Purpose);
	
	JobParameters.Insert("FillInForReplacement",   True);
	JobParameters.Insert("GeneralSettingsKey",       "Document.InventoryConsumptionPlan");
	JobParameters.Insert("NameOfResultColumn",    "NumberOfPackages");
	
	PopulatedTS = Object.Goods.Unload();
	
	Settings = New Structure;
	Settings.Insert("PopulatedTS", PopulatedTS);
	Settings.Insert("TimeIntervals", ThisForm.TimeIntervals.Unload());
	Common.CommonSettingsStorageSave(JobParameters.GeneralSettingsKey,
		"BackgroundJobSettings_"+JobParameters.UUID, Settings);
	
EndFunction

&AtServer
Procedure PrepareParametersForFillingInDocumentUsingFormula(JobParameters, CachedValues)
	
	CopyFromCrossTable(CachedValues, Object);
	
	PlanType = Enums.TypesOfPlans.InventoryConsumptionPlan;
	
	JobParameters.Insert("Ref",                  Object.Ref);
	JobParameters.Insert("UUID", UUID);
	JobParameters.Insert("Scenario",                Object.Scenario);
	JobParameters.Insert("PlanProfile",                Object.PlanProfile);
	JobParameters.Insert("CrossTable",            Object.CrossTable);
	JobParameters.Insert("Status",                  Object.Status);
	JobParameters.Insert("Periodicity",           Object.Periodicity);
	JobParameters.Insert("ActivePeriodStart",  Object.BeginOfPeriod);
	JobParameters.Insert("OffsetPeriodStart",   Object.BeginOfPeriod);
	JobParameters.Insert("OffsetPeriodEnd",    Object.PeriodEnding);
	JobParameters.Insert("NotOverridden",        True); // To redefine the text of the request skd_dolyadnalichiatovaranostatkah
	
	JobParameters.Insert("PlanType",                PlanType);
	JobParameters.Insert("Department",           Object.Department);
	JobParameters.Insert("Warehouse",                   Object.Warehouse);
	
	JobParameters.Insert("FillInUsingFormula",      True);
	JobParameters.Insert("GeneralSettingsKey",       "Document.InventoryConsumptionPlan");
	JobParameters.Insert("NameOfResultColumn",    "NumberOfPackages");
	
	FilterParameters = FilterParameters(ThisForm);
	PlanViewParameters = PlanViewParameters(ThisForm);
	
	FilterIndicators = PlanningClientServer.SelectionToFillInIndicators(PlanType, 
		FilterParameters, PlanViewParameters);
	
	JobParameters.Insert("Filter", FilterIndicators);
	
	Array_SetNames = New Array();
	If JobParameters.Property("PopulateOperands") Then
		
		ArrayOfOperators = GetOperands(ThisObject);
		
		For Each Item In ArrayOfOperators Do
			Array_SetNames.Add(Item.Name);
		EndDo;
	
	EndIf;
	
	JobParameters.Insert("Array_SetNames", Array_SetNames);
	
	PopulatedTS = Object.Goods.Unload();
	If JobParameters.Property("FillingComposition") Then
		PopulatedTS.Clear();
		Array_SetNames = New Array();
		If JobParameters.ContentFillingVariant = "Formula" Then
			Array_SetNames = PlanningClientServer.OperandsOfTextFormula(JobParameters.Formula);
		Else
			Array_SetNames.Add(JobParameters.ContentFillingVariant);
		EndIf;
		JobParameters.Insert("ArrayOfFillsetNames", Array_SetNames);
	EndIf;
	
	Settings = New Structure;
	Settings.Insert("PopulatedTS", PopulatedTS);
	Settings.Insert("TimeIntervals", ThisForm.TimeIntervals.Unload());
	Common.CommonSettingsStorageSave(JobParameters.GeneralSettingsKey,
		"BackgroundJobSettings_"+JobParameters.UUID, Settings);
	
EndProcedure

&AtServer
Procedure PrepareParametersForFillingInDocumentAccordingToFillingRule(JobParameters, CachedValues)
	
	If Object.UpdateAdd <> 0 Then
		CopyFromCrossTable(CachedValues, Object);
	EndIf;
	
	JobParameters.Insert("Ref",                  Object.Ref);
	JobParameters.Insert("UUID", UUID);
	JobParameters.Insert("Scenario",                Object.Scenario);
	JobParameters.Insert("PlanProfile",                Object.PlanProfile);
	JobParameters.Insert("CrossTable",            Object.CrossTable);
	JobParameters.Insert("ChangeResultTo",     Object.ChangeResultTo);
	JobParameters.Insert("RoundingPrecision",      Object.RoundingPrecision);
	JobParameters.Insert("Status",                  Object.Status);
	JobParameters.Insert("Periodicity",           Object.Periodicity);
	JobParameters.Insert("BeginOfPeriod",           Object.BeginOfPeriod);
	JobParameters.Insert("PeriodEnding",        Object.PeriodEnding);
	
	JobParameters.Insert("AllocateByWorkdays", Object.AllocateByWorkdays);
	
	JobParameters.Insert("Department",           Object.Department);
	JobParameters.Insert("Warehouse",                   Object.Warehouse);
	JobParameters.Insert("Purpose",              Object.Purpose);
	
	JobParameters.Insert("FillInRule",      True);
	JobParameters.Insert("GeneralSettingsKey",       "Document.InventoryConsumptionPlan");
	
	PopulatedTS = Object.Goods.Unload();
	If Object.UpdateAdd = 0 Then
		PopulatedTS.Clear();
	EndIf;
	
	If Not FilterIs_Specified Then
		FilterParameters = FilterParameters(ThisForm);
		PlanViewParameters = PlanViewParameters(ThisForm);	
		FilterValues = PlanningClientServer.SelectionForSampling(FilterParameters, PlanViewParameters);
		JobParameters.Insert("Filter", FilterValues);
	EndIf;
	
	Settings = New Structure;
	Settings.Insert("FillingRule", GetFromTempStorage(FillingRuleAddress));
	Settings.Insert("UserSettings", GetFromTempStorage(CustomSettingsAddress));
	Settings.Insert("PopulatedTS", PopulatedTS);
	Settings.Insert("TimeIntervals", ThisForm.TimeIntervals.Unload());
	Common.CommonSettingsStorageSave(JobParameters.GeneralSettingsKey,
		"BackgroundJobSettings_"+JobParameters.UUID, Settings);
	
EndProcedure

&AtServer
Function GetResultOfFillingOnServer(CachedValues, StorageAddress)
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"Document.InventoryConsumptionPlan.Forms.DocumentForm.GetResultOfFillingOnServer");
	
	Table = GetFromTempStorage(StorageAddress);
	
	ProcessedRowsCount = Table.Count();
	
	Object.Goods.Load(Table);
	
	// Formation of an array of periods in which the remainder plans were introduced
	PlannedBalanceIsUsed = Table.Columns.Find("PlannedStartBalance") <> Undefined;
	PlannedBalancesWithSelectionAreUsed = Table.Columns.Find("PlannedStartBalanceWithSelection") <> Undefined;
	If PlannedBalanceIsUsed Then
		
		BalancePlansPeriods.Clear();
		BalancePlanPeriodsWithSelection.Clear();
		
		For Each String In Table Do
			If String.PlannedStartBalance<>0 Then
				If BalancePlansPeriods.FindByValue(String.DateOfShipment) = Undefined Then
					BalancePlansPeriods.Add(String.DateOfShipment);
				EndIf;
			EndIf;
			
			If PlannedBalancesWithSelectionAreUsed
				And String.PlannedStartBalanceWithSelection<>0 Then
				If BalancePlanPeriodsWithSelection.FindByValue(String.DateOfShipment) = Undefined Then
					BalancePlanPeriodsWithSelection.Add(String.DateOfShipment);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	// Updating the period table to calculate planned balances
	If ValueIsFilled(StorageAddressAdditional)
		And GetFromTempStorage(StorageAddressAdditional) <> Undefined Then
		TablePeriods = GetFromTempStorage(StorageAddressAdditional);
	Else
		TablePeriods = FormAttributeToValue("TimeIntervals", Type("ValueTable"));
	EndIf;
	
	UpdateCrossTableStructure(TablePeriods, False);
	
	PerformanceMonitor.FixTimeConsumingOperationMeasure(Measurement,
		GetAttributes("GoodsByPeriod").Count()/10,
		"UpdateCrossTableStructure");
	
	CopyToCrossTable(CachedValues);
	
	Object.FilledAutomatically = True;
	
	If Object.CrossTable Or PlannedBalanceIsUsed Then
		Goods = GoodsByPeriod;
	Else
		Goods = Object.Goods;
	EndIf;
	
	FilterByProductType = ProductsClientServer.SelectionByProductMultiTurnContainer(False);
	FilterByProductType.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
	
	IndexOf = Goods.Count();
	While IndexOf > 0 Do
		IndexOf = IndexOf -1;
		TSRow = Goods[IndexOf];
		If FilterByProductType.Find(TSRow.ItemsType) = Undefined Then
			Goods.Delete(IndexOf);
		EndIf;
	EndDo;
	
	UpdateRelatedItemDetails(Object, ThisForm);
	
	ValuesHaveBeenRecalculated = False;
	If Object.FillInUsingFormula
		And SettingsStructure <> Undefined
		And (PlannedBalanceIsUsed
		Or (Object.CrossTable 
		And (StrFind(SettingsStructure.Formula,"CurrentColumnNumber") <> 0
		Or StrFind(SettingsStructure.Formula,"ColumnValue") <> 0))) Then
		
		ValuesHaveBeenRecalculated = True;
		ProcessFillingResultUsingFormula(ThisForm);
		
	ElsIf SettingsStructure.FilterEmptyLines Then
		
		LinesToDelete = New Array;
		
		For Each RowOfGoods In Goods Do
			If RowOfGoods.NumberOfPackages = 0 Then
				LinesToDelete.Add(RowOfGoods);
			EndIf;
		EndDo;

		For Each RowToDelete In LinesToDelete Do
			Goods.Delete(RowToDelete);
		EndDo;
		
	EndIf;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	
	CachedValuesStringProcessing = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	If Not Object.CrossTable Then
		If PlannedBalanceIsUsed Then
			CopyFromCrossTable(CachedValues, Object);
		Else
			
			BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValuesStringProcessing);
		EndIf;
	EndIf;
	
	If Not Object.CrossTable Or ValuesHaveBeenRecalculated Then
		CalculateTotals_(ThisForm);
	EndIf;
	
	CalculateNumberOfRows(ThisForm);
	
	PlannedBalanceIsUsed = False;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, ProcessedRowsCount/10);
	
EndFunction

&AtClient
Procedure ScenarioOnChangeCompletion(Result, AdditionalParameters) Export
	
	If Result <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ScenarioOnChangeServer();
	
EndProcedure

&AtClient
Procedure PlanProfileOnChangeCompletion(Result, AdditionalParameters) Export
	
	If Result <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	PlanProfileOnChangeServer(True);
	
EndProcedure

&AtClient
Procedure CellIsCanceledOnChange(Item)
	
	SetCancelAndCommentCells();
	
EndProcedure

&AtClient
Procedure CellCommentOnChange(Item)
	
	SetCancelAndCommentCells();
	
EndProcedure

&AtClient
Procedure CellCommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	Notification = New CallbackDescription("CellCommentStartChoiceCompletion", ThisObject);
	CommonClient.ShowMultilineTextEditingForm(
		Notification, 
		Item.EditText, 
		NStr("vi = 'Ghi chú ô hàng kế hoạch';
			|ru = 'Комментарий ячейки плана';
			|en = 'Plan cell comment'; fa = 'Plan cell comment';
			|it = 'Commento della cella di piano';
			|pl = 'Komentarze na temat komórek planu';
			|tr = 'Hücre planı yorumu'"));
	
EndProcedure

&AtClient
Procedure GoodsCommentOnChange(Item)
	
	Items.Goods.CurrentData.PictureComment = ValueIsFilled(Items.Goods.CurrentData.Comment);
	
EndProcedure

&AtClient
Procedure GoodsCommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	AdditionalParameters = New Structure("CurrentRow", Items.Goods.CurrentRow);
	Notification = New CallbackDescription(
		"GoodsCommentStartChoiceCompletion", ThisObject, AdditionalParameters);
	CommonClient.ShowMultilineTextEditingForm(
		Notification, 
		Item.EditText, 
		NStr("vi = 'Ghi chú ô hàng kế hoạch';
			|ru = 'Комментарий ячейки плана';
			|en = 'Plan cell comment'; fa = 'Plan cell comment';
			|it = 'Commento della cella di piano';
			|pl = 'Komentarze na temat komórek planu';
			|tr = 'Hücre planı yorumu'"));
		
EndProcedure

// Parameters:
// 	EnteredText - String - 
// 	AdditionalParameters - Structure - From:
//		* CurrentRow - Number -
&AtClient
Procedure GoodsCommentStartChoiceCompletion(Val EnteredText, Val AdditionalParameters) Export
	
	If EnteredText = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.Goods.FindByID(AdditionalParameters.CurrentRow);
	CurrentData.Comment = EnteredText;
	CurrentData.PictureComment = ValueIsFilled(EnteredText);
	Modified = True;
	
EndProcedure

&AtClient
Procedure Attachable_OnChangeCanceled(Item)
	
	CalculateTotals_(ThisForm);
	
EndProcedure

&AtClient
Procedure Attachable_WhenChangingComment(Item)
	
	CurrentData = Items.GoodsByPeriod.CurrentData;
	
	If CurrentData <> Undefined And Items.GoodsByPeriod.CurrentItem <> Undefined Then
		For Each Period In ThisForm.TimeIntervals.FindRows(New Structure("Active_", True)) Do
			If Items.GoodsByPeriod.CurrentItem.Name = "GoodsByPeriod" + "Comment_"+Period.ColumnName Then
				
				CellIsCanceled = CurrentData["Canceled_"+ Period.ColumnName];
				CellComment = CurrentData["Comment_"+ Period.ColumnName];
				CurrentData["PictureComment_"+ Period.ColumnName] = ValueIsFilled(CellComment);
				Break;
			EndIf;
		EndDo;
	
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_StartOfCommentSelection(Item, ChoiceData, StandardProcessing)
	
	CurrentData = Items.GoodsByPeriod.CurrentData;
	StandardProcessing = False;
	
	If CurrentData <> Undefined And Items.GoodsByPeriod.CurrentItem <> Undefined Then
		For Each Period In ThisForm.TimeIntervals.FindRows(New Structure("Active_", True)) Do
			If Items.GoodsByPeriod.CurrentItem.Name = "GoodsByPeriod" + "Comment_"+Period.ColumnName Then
				
				CellIsCanceled = CurrentData["Canceled_"+ Period.ColumnName];
				CellComment = CurrentData["Comment_"+ Period.ColumnName];
				
				AdditionalParameters = New Structure("CurrentRow, ColumnName", 
					Items.GoodsByPeriod.CurrentRow,
					Period.ColumnName);
				Notification = New CallbackDescription(
					"Attachable_StartOfCommentSelectionCompletion", ThisObject, AdditionalParameters);
				CommonClient.ShowMultilineTextEditingForm(
					Notification, 
					CellComment, 
					NStr("vi = 'Ghi chú ô hàng kế hoạch';
						|ru = 'Комментарий ячейки плана';
						|en = 'Plan cell comment'; fa = 'Plan cell comment';
						|it = 'Commento della cella di piano';
						|pl = 'Komentarze na temat komórek planu';
						|tr = 'Hücre planı yorumu'"));
				Break;
			EndIf;
		EndDo;
	
	EndIf;
	
EndProcedure

// Parameters:
// 	EnteredText - String - 
// 	AdditionalParameters - Structure - From:
//		* CurrentRow - Number -
&AtClient
Procedure Attachable_StartOfCommentSelectionCompletion(Val EnteredText, Val AdditionalParameters) Export
	
	If EnteredText = Undefined Then
		Return;
	EndIf;
	
	CurrentData = GoodsByPeriod.FindByID(AdditionalParameters.CurrentRow);
	CurrentData["Comment_"+ AdditionalParameters.ColumnName] = EnteredText;
	CurrentData["PictureComment_"+ AdditionalParameters.ColumnName] = ValueIsFilled(
		CurrentData["Comment_"+ AdditionalParameters.ColumnName]);
	Modified = True;
	
EndProcedure

&AtClient
Procedure CancelPlanLines(Command)
	
	Notification = New CallbackDescription("CancelPlanLinesCompletion", ThisObject);
	If Object.CrossTable Then
		PlanningClient.CancelPlanLines(ThisForm, GoodsByPeriod, "GoodsByPeriod", Notification);
	Else
		PlanningClient.CancelPlanLines(ThisForm, Object.Goods, "Goods", Notification);
	EndIf;
	
EndProcedure

#EndRegion

&AtClient
Procedure SetCancelAndCommentCells()
	
	CellFound = False;
	
	CurrentData = Items.GoodsByPeriod.CurrentData;
	If CurrentData = Undefined Then
		CellIsCanceled = False;
		CellComment = "";
		Items.CellIsCanceled.Enabled = CellFound;
		Items.CellComment.Enabled = CellFound;
		Return;
	EndIf;
	
	If Items.GoodsByPeriod.CurrentItem <> Undefined Then
		For Each Period In ThisForm.TimeIntervals.FindRows(New Structure("Active_", True)) Do
			If Items.GoodsByPeriod.CurrentItem.Name = "GoodsByPeriod" + "Count_" + Period.ColumnName Then
				CurrentData["Canceled_"+ Period.ColumnName] = CellIsCanceled;
				CurrentData["Comment_"+ Period.ColumnName] = CellComment;
				CurrentData["PictureComment_"+ Period.ColumnName] = ValueIsFilled(CellComment);
				CellFound = True;
				CalculateTotals_(ThisForm, False);
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	If Not CellFound Then
		CellIsCanceled = False;
		CellComment = "";
	EndIf;
	
	Items.CellIsCanceled.Enabled = CellFound;
	Items.CellComment.Enabled = CellFound;
	
EndProcedure

&AtClient
Procedure CellCommentStartChoiceCompletion(Val EnteredText, Val AdditionalParameters) Export
	
	If EnteredText = Undefined Then
		Return;
	EndIf;
	
	CellComment = EnteredText;
	Modified = True;
	CellCommentOnChange(Items.CellComment);
	
EndProcedure

&AtClient
Procedure CancelPlanLinesCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Or Result = DialogReturnCode.Cancel Then
		Return
	EndIf;
	
	If Object.CrossTable Then
		SelectedRows = Items.GoodsByPeriod.SelectedRows;
	Else
		SelectedRows = Items.Goods.SelectedRows;
	EndIf;
	
	If SelectedRows.Count() > 0 Then
		CalculateTotals_(ThisForm);
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeByPercentageCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined
		Or Result = 0 
		Or Result = DialogReturnCode.Cancel Then
	
		Return;
	EndIf;
	
	If Not Object.CrossTable Then
		SelectedRows = Items.Goods.SelectedRows;
		For Each SelectedRow In SelectedRows Do
			
			TSRow = Object.Goods.FindByID(SelectedRow);
			RecalculateNumberOfPackagesAndAmountPerLine(TSRow, CachedValues);
			
		EndDo;
		
	Else
		If Object.FillInUsingFormula Then
			PlanningClientServer.DisplayValueOfAdditionalParameters(ThisObject,
				GetAdditionalBankingDetails(ThisObject), "GoodsByPeriod");
		EndIf;
	EndIf;
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure RoundOffQuantityCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined
		Or Result = DialogReturnCode.Cancel Then
	
		Return;
	EndIf;
	
	If Not Object.CrossTable Then
		SelectedRows = Items.Goods.SelectedRows;
		For Each SelectedRow In SelectedRows Do
			
			TSRow = Object.Goods.FindByID(SelectedRow);
			RecalculateNumberOfPackagesAndAmountPerLine(TSRow, CachedValues);
			
		EndDo;
		
	Else
		If Object.FillInUsingFormula Then
			PlanningClientServer.DisplayValueOfAdditionalParameters(ThisObject,
				GetAdditionalBankingDetails(ThisObject), "GoodsByPeriod");
		EndIf;
	EndIf;
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Function CheckHeaderFilling()
	
	ClearMessages();
	FilledIn_Correctly = True;
	
	If Not ValueIsFilled(Object.Scenario) Then
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Kịch bản""';
				|ru = 'Поле ""Сценарий"" не заполнено';
				|en = '""Scenario"" is required'; fa = '""Scenario"" is required';
				|it = 'Il campo ""Scenario"" non è compilato';
				|pl = 'Pole ""Scenariusz"" nie wypełnione';
				|tr = '""Senaryo"" alanı doldurulmadı.'"),
			Object.Ref,
			"Object.Scenario");
		FilledIn_Correctly = False;
	EndIf;
	
	If Not ValueIsFilled(Object.PlanProfile) Then
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Dạng thanh toán""';
				|ru = 'Поле ""Вид плана"" не заполнено';
				|en = '""Plan profile"" is required'; fa = '""Plan profile"" is required';
				|it = 'Il campo ""Tipo di piano"" non è compilato';
				|pl = 'Pole ""Rodzaj planu"" nie wypełnione';
				|tr = '""Plan profili"" alanı doldurulmadı'"),
			Object.Ref,
			"Object.PlanProfile");
		FilledIn_Correctly = False;
	EndIf;
	
	If FillInBusinessUnit And Not ValueIsFilled(Object.Department) Then
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Bộ phận""';
				|ru = 'Поле ""Подразделение"" не заполнено';
				|en = '""Business unit"" is required'; fa = '""Business unit"" is required';
				|it = 'Il campo ""Reparto"" non è compilato';
				|pl = 'Nie wypełniono pola ""Dział""';
				|tr = '""Departman"" alanı doldurulmadı'"),
			Object.Ref,
			"Object.Department");
		FilledIn_Correctly = False;
	EndIf;
	
	If FillInWarehouse And Not ValueIsFilled(Object.Warehouse) Then
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Kho bãi""';
				|ru = 'Поле ""Склад"" не заполнено';
				|en = '""Warehouse"" is required'; fa = '""Warehouse"" is required';
				|it = 'Il campo ""Magazzino"" non è compilato';
				|pl = 'Nie wypełniono pola ""Magazyn""';
				|tr = '""Ambar"" alanı doldurulmamış'"),
			Object.Ref,
			"Object.Warehouse");
		FilledIn_Correctly = False;
	EndIf;
	
	If ThisForm.TimeIntervals.FindRows(New Structure("Active_", True)).Count() = 0 Then
		CommonClient.MessageToUser(
			NStr("vi = 'Đã đặt tham số kỳ không đúng. Không thể điền';
				|ru = 'Параметры периода заданы неверно. Заполнение невозможно';
				|en = 'Period parameters are specified incorrectly. Cannot populate the header'; fa = 'Period parameters are specified incorrectly. Cannot populate the header';
				|it = 'I parametri del periodo sono impostati in modo errato. La compilazione non è possibile';
				|pl = 'Ustawienia okresu nieprawidłowe. Wypełnienie jest niemożliwe';
				|tr = 'Dönem parametreleri yanlış ayarlanmış. Doldurma işlemi gerçekleştirilemez'"),
			Object.Ref);
		FilledIn_Correctly = False;
	EndIf;
	
	Return FilledIn_Correctly;
	
EndFunction

#EndRegion

&AtServer
Procedure DeleteBlankLinesOnServer()
	
	ActivePeriods = ThisForm.TimeIntervals.FindRows(New Structure("Active_", True));
	
	ItIsNecessaryToRecalculateResults = False;
	
	IndexOf = GoodsByPeriod.Count() -1;
	
	While IndexOf >= 0 Do
	
		TSRow = GoodsByPeriod[IndexOf];
		
		If TSRow.NumberOfPackages <> 0 Then
			IndexOf = IndexOf - 1;
			Continue;
		EndIf;
		
		IsBlankRow = True;
		
		For Each Period In ActivePeriods Do
		
			If TSRow["Count_"+Period.ColumnName] <> 0 Then
			
				IsBlankRow = False;
				Break;
			
			EndIf;
		
		EndDo;
		
		If IsBlankRow Then
		
			GoodsByPeriod.Delete(IndexOf);
			ItIsNecessaryToRecalculateResults = True;
		
		EndIf;
		
		IndexOf = IndexOf - 1;
		
	EndDo;
	
	If ItIsNecessaryToRecalculateResults Then
	
		CalculateTotals_(ThisForm, False);
	
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductsByPeriodWhenActivatingCellOnClient()
	
	If Object.FillInUsingFormula Then
		PlanningClientServer.DisplayValueOfAdditionalParameters(ThisObject,
			GetAdditionalBankingDetails(ThisObject), "GoodsByPeriod");
	EndIf;
	
	ActivePeriods = ThisForm.TimeIntervals.FindRows(New Structure("Active_", True));
	CurrentData = Items.GoodsByPeriod.CurrentData;
	
	If ActivePeriods.Count() = 1 Then
		If Not Object.FillInUsingFormula And CurrentData <> Undefined Then
			Details = PlanningClient.GenerateDecryption(CurrentData, "Details_" + ActivePeriods[0].ColumnName);
		EndIf;
		Return;
	EndIf;
	
	CellIsCanceled = False;
	CellComment = "";
	CellFound = False;
	
	Item = Items.GoodsByPeriod;
	
	If CurrentData = Undefined Then
		Items.CellIsCanceled.Enabled = CellFound;
		Items.CellComment.Enabled = CellFound;
		Return;
	EndIf;
	
	If Item.CurrentItem <> Undefined Then
		For Each Period In ActivePeriods Do
			If Item.CurrentItem.Name = "GoodsByPeriod" + "Count_" + Period.ColumnName Then
				CellIsCanceled = CurrentData["Canceled_"+ Period.ColumnName];
				CellComment = CurrentData["Comment_"+ Period.ColumnName];
				If Not Object.FillInUsingFormula And CurrentData["Count_"+ Period.ColumnName] <> 0 Then
					Details = PlanningClient.GenerateDecryption(CurrentData, "Details_"+ Period.ColumnName);
				Else
					Details = "";
				EndIf;
				CellFound = True;
				Break;
			Else
				Details = "";
			EndIf;
		EndDo;
	EndIf;
	
	Items.CellIsCanceled.Enabled = CellFound;
	Items.CellComment.Enabled = CellFound;
	
EndProcedure

#Region PlanSubstitution

&AtClientAtServerNoContext
Function ReplaceParameters(Val Object)

	
	ReplaceParameters = New Structure;
	
	ReplaceParameters.Insert("Ref", Object.Ref);
	ReplaceParameters.Insert("PlanProfile", Object.PlanProfile);
	ReplaceParameters.Insert("Status", Object.Status);
	ReplaceParameters.Insert("Date", Object.Date);
	ReplaceParameters.Insert("BeginOfPeriod", Object.BeginOfPeriod);
	ReplaceParameters.Insert("PeriodEnding", Object.PeriodEnding);
	ReplaceParameters.Insert("Periodicity", Object.Periodicity);
	
	ReplaceParameters.Insert("Department", Object.Department);
	ReplaceParameters.Insert("Warehouse", Object.Warehouse);
	ReplaceParameters.Insert("Purpose", Object.Purpose);
	
	
	Return ReplaceParameters
	
EndFunction

&AtServer
Procedure UpdateReplacementAttribute()
	
	For Each String In Object.Goods Do
		String.Substituted = False;
		String.SubstitutedToOrder = False;
	EndDo;
	
	If Not Object.Substitutional Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	SubstitutedPeriods.SubstitutedPeriod AS SubstitutedPeriod,
	|	SubstitutedPeriods.SubstitutedToOrder AS SubstitutedToOrder,
	|	SubstitutedPeriods.Substituted AS Substituted
	|INTO SubstitutedPeriods
	|FROM
	|	&SubstitutedPeriods AS SubstitutedPeriods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	DomesticConsumptionPlanGoods.DateOfShipment,
	|	CASE &Periodicity
	|		WHEN VALUE(Enum.Periodicity.WEEK)
	|			THEN BEGINOFPERIOD(DomesticConsumptionPlanGoods.DateOfShipment, WEEK)
	|		WHEN VALUE(Enum.Periodicity.TENDAYS)
	|			THEN BEGINOFPERIOD(DomesticConsumptionPlanGoods.DateOfShipment, TENDAYS)
	|		WHEN VALUE(Enum.Periodicity.MONTH)
	|			THEN BEGINOFPERIOD(DomesticConsumptionPlanGoods.DateOfShipment, MONTH)
	|		WHEN VALUE(Enum.Periodicity.QUARTER)
	|			THEN BEGINOFPERIOD(DomesticConsumptionPlanGoods.DateOfShipment, QUARTER)
	|		WHEN VALUE(Enum.Periodicity.HALFYEAR)
	|			THEN BEGINOFPERIOD(DomesticConsumptionPlanGoods.DateOfShipment, HALFYEAR)
	|		WHEN VALUE(Enum.Periodicity.YEAR)
	|			THEN BEGINOFPERIOD(DomesticConsumptionPlanGoods.DateOfShipment, YEAR)
	|		ELSE DomesticConsumptionPlanGoods.DateOfShipment
	|	END AS Period
	|INTO DomesticConsumptionPlanGoods
	|FROM
	|	&DomesticConsumptionPlanGoods AS DomesticConsumptionPlanGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	DomesticConsumptionPlanGoods.DateOfShipment,
	|	MAX(SubstitutedPeriods.SubstitutedToOrder) AS SubstitutedToOrder,
	|	MAX(SubstitutedPeriods.Substituted) AS Substituted
	|FROM
	|	SubstitutedPeriods AS SubstitutedPeriods
	|		INNER JOIN DomesticConsumptionPlanGoods AS DomesticConsumptionPlanGoods
	|		ON SubstitutedPeriods.SubstitutedPeriod = DomesticConsumptionPlanGoods.Period
	|
	|GROUP BY
	|	DomesticConsumptionPlanGoods.DateOfShipment";
	
	Query.SetParameter("SubstitutedPeriods", SubstitutedPeriods.Unload());
	Query.SetParameter("DomesticConsumptionPlanGoods", Object.Goods.Unload());
	
	Query.SetParameter("Periodicity", Object.Periodicity);
	
	RequestPackage = Query.ExecuteBatch(); 
	Selection = RequestPackage[2].Select();
	
	While Selection.Next() Do
		
		Filter = New Structure("DateOfShipment", Selection.DateOfShipment);
		ReplacementLines = Object.Goods.FindRows(Filter);
		For Each String In ReplacementLines Do
			String.Substituted = Selection.Substituted;
			String.SubstitutedToOrder = Selection.SubstitutedToOrder;
		EndDo;
		
	EndDo;
	
EndProcedure

&AtServer
Function FillInSubstitutedPeriods()
	
	ReplaceParameters = ReplaceParameters(Object);
	Result = Planning.GetSubstitutedPeriods(ReplaceParameters, "InventoryConsumptionPlan");
	
	SubstitutedPeriods.Load(Result);
	
EndFunction

&AtClient
Procedure SubstitutionFormattedLineURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	FormParameters = ReplaceParameters(Object);
	FormParameters.Insert("FormattedStringURL", FormattedStringURL);
	
	OpenForm("InformationRegister.PlanSubstitution.Form.PlanSubstitution", FormParameters);
EndProcedure

&AtServerNoContext
Function PlanReplacementControlOnServer(Ref)
	
	Return Planning.PlanReplacementControl(Ref);
	
EndFunction

#EndRegion

#Region ImportDataFromFile

&AtClient
Procedure ShowUploadFormFromFile(AdditionalParameters)
	
	ImportParameters = ImportDataFromFileClient.DataImportParameters();
	ImportParameters.FullTabularSectionName = "InventoryConsumptionPlan.Goods";
	ImportParameters.Title               = NStr("vi = 'Kết nhập bảng ''''Hàng hóa'''' từ tệp';
												|ru = 'Загрузка таблицы ""Товары"" из файла';
												|en = 'Import the Goods table from the file'; fa = 'Import the Goods table from the file';
												|it = 'Download della tabella ""Merci"" dal file';
												|pl = 'Wczytywanie tabeli ""Towary"" z pliku';
												|tr = 'Dosyadan ""Ürünler"" tablosunun indirilmesi'");
	ImportParameters.AdditionalParameters = AdditionalParameters;
	
	ImportParameters.TemplateColumns = PlanningClient.DescriptionOfTemplateColumnsForLoadingProducts(AdditionalParameters);
	
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
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	If Object.CrossTable Then
		CopyFromCrossTable(CachedValues, Object);
	EndIf;
	
	AddProducts_2(ImportedData, CachedValues, True);
	
	If Object.CrossTable Then
		
		GoodsByPeriod.Clear();
		
		Cancel = False;
		CheckParameters = New Structure;
		CheckParameters.Insert("TSName",                    "Goods");
		CheckParameters.Insert("PresentationOfTS",          NStr("vi = 'Hàng hóa';
																|ru = 'Товары';
																|en = 'Goods'; fa = 'کالاها';
																|it = 'Merci';
																|pl = 'Towary';
																|tr = 'Ürünler'"));
		CheckParameters.Insert("Periodicity",            Object.Periodicity);
		CheckParameters.Insert("StartDate",               Object.BeginOfPeriod);
		CheckParameters.Insert("EndDate",            Object.PeriodEnding);
		CheckParameters.Insert("NameOfPeriodDateField",       "DateOfShipment");
		CheckParameters.Insert("PresentationOfPeriodDate", NStr("vi = 'Ngày giao hàng';
																|ru = 'Дата отгрузки';
																|en = 'Shipment date'; fa = 'تاریخ ارسال';
																|it = 'Data di spedizione';
																|pl = 'Data wysyłki';
																|tr = 'Sevkiyat tarihi'"));
		CheckParameters.Insert("KTCHPathPrefix",           "Object.");
		
		PlanningClientServer.CheckDateOfTSPeriod(Object, Cancel, CheckParameters);
		
		If Cancel Then
			Common.MessageToUser(NStr("vi = 'Trong các dòng danh sách ""Hàng hóa"" đã chỉ ra ngày ngoài biên lập kế hoạch - sẽ xóa các dòng.';
										|ru = 'В строках списка ""Товары"" указаны даты за границами планирования - строки были удалены.';
										|en = 'Dates outside the planning fences are specified in lines of the Goods list. The lines were removed.'; fa = 'Dates outside the planning fences are specified in lines of the Goods list. The lines were removed.';
										|it = 'Nelle righe dell''elenco ""Merci"" le date vanno oltre i limiti della pianificazione - le righe sono state eliminate.';
										|pl = 'W wierszach listy ""Towary"" są podane daty poza granicami planowania - wiersze zostały usunięte.';
										|tr = '""Ürünler"" listesinin satırlarında planlama sınırları için belirtilen tarihler. Satırlar silindi.'"));
		EndIf;
		
		SwitchPeriodsToColumnsOnServer(CachedValues);
	EndIf;
	
EndProcedure

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
	ElsIf Item.Name = "sh_ShamsiInput_BeginOfPeriod" Then
		BeginOfPeriodOnChange(Items.BeginOfPeriod);
	ElsIf Item.Name = "sh_ShamsiInput_PeriodEnding" Then
		PeriodEndingOnChange(Items.PeriodEnding);
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
