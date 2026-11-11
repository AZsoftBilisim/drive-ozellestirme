#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		
	EndIf;
	
	If Parameters.Property("RowSelected") Then
		
		ActiveLineID = FindStringFromStringData(Parameters.RowSelected)
		
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.ProductionOrder2_2.ItemsAndDimensionsSelectionParameters(Object);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	#Region UniversalMechanisms
	
	// the foundation document
	TMCommonUseClientServer.SetFormItemProperty(
		Items, 
		"DocumentBasis", "Visible", ValueIsFilled(Object.DocumentBasis));

	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisForm);
	
	// Configuring Clipboard Commands
	SetAvailabilityOfClipboardCommands();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// Handler of the subsystem prohibiting editing of object details
	If Transferred_To_Production Then
		ObjectAttributesLock.LockAttributes(ThisObject);
	EndIf;
	
	#EndRegion
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	UpdateCachedValuesToAccountForBatchesOfFINISHEDProductBeingRepaired();
	
	If ActiveLineID <> Undefined Then
		Items.Content.CurrentPage = Items.ProductsPage;
		Items.ManufacturedProduct.CurrentRow = ActiveLineID;
	EndIf;
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
	
	AttachIdleHandler("ControlOfCalculationOfOrderStructure", 0.1, True);

EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	ForceCloseTheForm = True;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "DataProcessor.SelectGoodsToSalesDocument.Form.Form" Then
		
		ProductsSelectionProcessingSelectionOnServer(ValueSelected);
		
	ElsIf ChoiceSource.FormName = "Document.MaterialProviderOrder2_5.Form.OrderChoiceForm"
			Or False Then
		
		ProductsSelectionProcessingSelectionAccordingToGiverSOrdersOnServer(ValueSelected);
		
	ElsIf ChoiceSource.FormName = "CommonForm.EnterCostShare" Then
		
		ProcessingInputOfFractionOfCost(CurrentItem.CurrentData, ValueSelected);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_ProductionOrder" Or EventName = "Write_ProductionOrder2_2" Then
		
		If Parameter = Undefined
			Or TypeOf(Parameter) = Type("DocumentRef.ProductionOrder2_2") And Parameter = Object.Ref
			Or TypeOf(Parameter) = Type("Structure") And Parameter.Property("ProductionOrder") And Parameter.ProductionOrder = Object.Ref
			Or TypeOf(Parameter) = Type("Structure") And Parameter.Property("ProductionOrders") And Parameter.ProductionOrders.Find(Object.Ref) <> Undefined Then
			ControlOfCalculationOfOrderStructure();
		EndIf;
		
	EndIf;
	
	If EventName = "Write_ProductionSchedule" Then
		
		FillInCurrentOrderState();
		ConfigureDependentFormElements(ThisForm, "ProductionSchedule");

	EndIf;
	
	If EventName = "CopyingLinesToClipboard" Then
		
		SetAvailabilityOfClipboardCommandsOnClient();
		
	EndIf;
	
	// Handler of the "Properties" mechanism
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)
	
	FormEventsClient.URLProcessing(ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement	
	
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	
	OnReadCreateAtServer();

	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	// End StandardSubsystems.Properties
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	CheckReportResultOfControl(WriteParameters);
	
	FillInServiceDetails();
	
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	
	ConfigureDependentFormElements(ThisForm);
	
	
	FormEvents.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	// Handler of the subsystem prohibiting editing of object details
	If Transferred_To_Production Then
		ObjectAttributesLock.LockAttributes(ThisObject);
	EndIf;
	
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
		
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisForm, Object, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands

	// Handler of the subsystem prohibiting editing of object details
	If Not Transferred_To_Production Then
		
		LockedAttributes = ListOfBlockedItemAttributes();
		
		If LockedAttributes.Count() > 0 Then
			ObjectAttributesLockClient.SetFormItemEnabled(ThisObject, LockedAttributes);
		EndIf;
		
	EndIf;
	
	Notify("Write_ProductionOrder", Object.Ref);
	
	
	AttachIdleHandler("ControlOfCalculationOfOrderStructure", 0.1, True);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	HideCanceledLines = Settings.Get("HideCanceledLines");
	
	If HideCanceledLines Then
		Items.ManufacturedProduct.RowFilter = New FixedStructure("Canceled", False);
	Else
		Items.ManufacturedProduct.RowFilter = Undefined;
	EndIf;
	
	Items.ProductsHideCanceledLines.Check = HideCanceledLines;

EndProcedure

#EndRegion

#Region EventHandlersForHeaderElements

&AtClient
Procedure ContentOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If CurrentPage.Name = "AdditionalPage"
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
		
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	WhenChangingDateServer();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	WhenOrganizationChangesServer();
	
EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	
	StatusChangedOnServer(CachedValues);
	UpdateCachedValuesToAccountForBatchesOfFINISHEDProductBeingRepaired();
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	BusinessOperationWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure LineOfBusinessOnChange(Item)
	
	DirectionOfActivityWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	PartnerWhenChangesAreMadeOnServer();
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	AgreementWhenModifiedOnServer();
	
EndProcedure

&AtClient
Procedure ProductionProcessTypeOnChange(Item)
	
	If Not TypeOfProductionProcessBeforeTheChange = Object.ProductionProcessType Then 
		
		TypeOfProductionProcessWhenChangedOnServer();
		
		TypeOfProductionProcessBeforeTheChange = Object.ProductionProcessType;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OrderForActivityClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure EarliestStartDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	FillInSpecificationInTablePart(,True);
	
EndProcedure

&AtClient
Procedure DynamicStructureOnChange(Item)
	
	DynamicStructureWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure ErrorsInSelectionOfSpecificationsInProductionOrdersURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	ParametersStructure = New Structure("ProductionOrder", Object.Ref);
	OpenForm("InformationRegister.OrderStructureCalculationProtocol.Form.DisplayErrorsOfSelectingBOMsInProductionOrders", ParametersStructure, Object.Ref);
	
EndProcedure

&AtClient
Procedure ErrorsInFillingInProductDataURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	ParametersStructure = New Structure("ProductionOrder", Object.Ref);
	OpenForm("InformationRegister.OrderStructureCalculationProtocol.Form.DisplayProductStructureExplosionErrors", ParametersStructure, Object.Ref);

EndProcedure

&AtClient
Procedure ErrorsInCalculationOfRegulatoryScheduleURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	ParametersStructure = New Structure("ProductionOrder", Object.Ref);
	OpenForm("InformationRegister.TargetOrderStructureSchedule.Form.ErrorLog", ParametersStructure, Object.Ref);
	
EndProcedure

&AtClient
Procedure DemandDateOnChange(Item)

	Object.DemandDate = DateOfNeedOnForm; // valid only if the date is entered in the header
	FillInDateOfVHFManufacturedProducts(Object.DemandDate);
	ConfigureDependentFormElements(ThisForm, "DemandDate");
	
EndProcedure

&AtClient
Procedure DemandDateChoiceProcessing(Item, ValueSelected, AdditionalData, StandardProcessing)
	
	StandardProcessing = False;
	
	Modified = True;

	If ValueSelected = "SpecifiedInLines" Then
			
		DateOfNeedOnForm = Items.DemandDate.ChoiceList.FindByValue(ValueSelected);
		
		Object.DemandDateIsSpecifiedInLines = True;
		Object.DemandDate = '00010101';
		
		ConfigureDependentFormElements(ThisForm, "DemandDate");
		
	Else
		
		If ValueSelected = "ChooseFromCalendar" Then
		
			FormParameters = New Structure("NoteText, InitialValue", NStr("vi = 'Ngày xuất xưởng mong muốn:';
																			|ru = 'Желаемая дата выпуска:';
																			|en = 'Requested release date:'; fa = 'Requested release date:';
																			|it = 'Желаемая дата выпуска:';
																			|pl = 'Requested release date:';
																			|tr = 'Talep edilen bitiş tarihi:'") + " ", Object.DemandDate);
			Notification = New CallbackDescription("WhenChoosingDateNeedsEnd", ThisObject);
			OpenForm("CommonForm.SelectDate",
				FormParameters, , , , ,
				Notification,
				FormWindowOpeningMode.LockWholeInterface);
			
		Else
			
			If TypeOf(ValueSelected) = Type("Date") Then
				SelectedDate = ValueSelected;
			Else
				
				SelectedDate = '00010101';
				EventDate = BegOfDay(GeneralPurposeTMServerCall.SessionDate());
				
				If ValueSelected = "Today" Then
					SelectedDate = EventDate;
				ElsIf ValueSelected = "Tomorrow" Then
					SelectedDate = EventDate + 86400;
				ElsIf ValueSelected = "InAWeek" Then
					SelectedDate = EventDate + 7*86400;
				Else
					// other actions in the Cur configuration are not provided
				EndIf;
				
			EndIf;
			
			WhenChoosingDateNeedsEnd(SelectedDate);
		
		EndIf;
		
	EndIf;
EndProcedure

&AtClient
Procedure WhenChoosingDateNeedsEnd(SelectedDate, AdditionalParameters = Undefined) Export
	
	If SelectedDate = Undefined Then
		Return;
	EndIf;
	
	DateOfNeedOnForm = SelectedDate;
	Object.DemandDateIsSpecifiedInLines = False;
	Object.DemandDate = SelectedDate;
	FillInDateOfVHFManufacturedProducts(Object.DemandDate);
	
	ConfigureDependentFormElements(ThisForm, "DemandDate");
	
EndProcedure

&AtClient
Procedure DemandDateClearing(Item, StandardProcessing)
	
	StandardProcessing = False; 
	
	DateOfNeedOnForm = '00010101';
	Object.DemandDateIsSpecifiedInLines = False;
	Object.DemandDate = '00010101';
	FillInDateOfVHFManufacturedProducts(Object.DemandDate);
	
	ConfigureDependentFormElements(ThisForm, "DemandDate");
		
EndProcedure

&AtClient
Procedure ProductionSchedulingOnChange(Item)

	SetRequiredDateAttribute(ThisForm);
	
	ConfigureDependentFormElements(ThisForm, "ProductionScheduling");
	
EndProcedure

&AtClient
Procedure UnderRepairProductOnChange(Item)

	UnderRepairProductOnChangeServer(CachedValues);
	UpdateCachedValuesToAccountForBatchesOfFINISHEDProductBeingRepaired();

EndProcedure

&AtServer
Procedure UnderRepairProductOnChangeServer(ValuesCache)
	
	If Not Object.UnderRepairVariant.IsEmpty() Then
		CheckResult = Catalogs.Products.CharacteristicAndPackagingBelongToOwner(Object.UnderRepairProduct, Object.UnderRepairVariant, Undefined);
		Object.UnderRepairVariant = CheckResult.Characteristic;
	EndIf;
	
	EstablishAvailabilityOfFinishedProductBeingRepaired();
	
	If SeriesSpecificationParameters.FinishedProductBeingRepaired.UseItemsBatch Then
		FillInBatchIndicationStatusesONChangesOfFinishedProductBeingRepaired(ValuesCache);
	EndIf;
	
	FillInSpecificationInTablePart(,True);
	
EndProcedure

&AtClient
Procedure UnderRepairVariantOnChange(Item)
	
	DataStructureOfFinishedProductBeingRepaired = ProductionManagementClientServer.DataOfFinishedProductBeingRepairedByStructure(Object);
	
	If ProductsClient.YouNeedToUpdateStatusOfSeriesInHeader(DataStructureOfFinishedProductBeingRepaired, CachedValues, SeriesSpecificationParameters.FinishedProductBeingRepaired) Then
		FillInBatchIndicationStatusesONChangesOfFinishedProductBeingRepaired(CachedValues, DataStructureOfFinishedProductBeingRepaired);
		UpdateCachedValuesToAccountForBatchesOfFINISHEDProductBeingRepaired(DataStructureOfFinishedProductBeingRepaired);
	EndIf;
	
	UnderRepairVariantOnChangeServer(CachedValues);
	
EndProcedure

&AtServer
Procedure UnderRepairVariantOnChangeServer(ValuesCache)
	
	FillInSpecificationInTablePart(,True);
	
EndProcedure

&AtClient
Procedure UnderRepairBatchOnChange(Item)
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	ValueSelected.Value = Object.UnderRepairBatch;
	
	ProcessIndicationOfBatchOfFINISHEDProductBeingRepaired(ValueSelected);
	
EndProcedure

#EndRegion

#Region PageEventHandlers

&AtClient
Procedure ManufacturedProductOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.ManufacturedProduct.CurrentData;
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.ManufacturedProduct, ThisObject);
	
	If NewRow Then
		
		FillInDefaultWarehouseInLine(ThisForm, CurrentData);
		
		If Not Copy Then
			
			IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, CurrentData, "Object.ManufacturedProduct");
			
		EndIf;
		
		CurrentData.KeyProducts = Undefined;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ManufacturedProductOnEditEnd(Item, NewRow, CancelEdit)
	
	CurrentData = Items.ManufacturedProduct.CurrentData;
	
	If CurrentData <> Undefined And Not Object.DemandDateIsSpecifiedInLines Then
		CurrentData.DemandDate = Object.DemandDate;
	EndIf;
	
	If ProductionClient.ItIsNecessaryToCalculatePercentageOfDistributionOfCostsForOutputProducts(
			Item, CostAllocationParameters, ProductsCurrentStringCache, NewRow) Then
		CalculatePercentageOfCostAllocationForOutputProducts();
	EndIf;
	
	CurLineCache_ = ProcessingOfTabularFormsClientServer.LineCache(Items.ManufacturedProduct, ThisObject);
	
EndProcedure

&AtClient
Procedure ManufacturedProductAfterDeleteRow(Item)
	
	CalculatePercentageOfCostAllocationForOutputProducts();
	
EndProcedure

&AtClient
Procedure ManufacturedProductSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.ManufacturedProduct.CurrentData;
	
	If (Field = Items.ManufacturedProductCostSharePercentage
			Or Field = Items.ManufacturedProductThereAreErrorsOfFillingInCostShare)
		And Object.MethodOfAllocatingFinishedProductCosts <> PredefinedValue("Enum.MethodsOfCostAllocatingOnProductCosts.ByCostShares") Then
		StandardProcessing = False;
		OpenCostShareEntryForm(CurrentData);
	EndIf;
	
EndProcedure

&AtClient
Procedure ManufacturedProductProductsOnChange(Item)
	
	CurrentRow = Items.ManufacturedProduct.CurrentData;
	
	StructureOfActions = New Structure;
	
	If CurrentRow.ToExpenseAs
		Or CurrentRow.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5") Then
			
		CurrentRow.Warehouse = PredefinedValue("Catalog.Warehouses.EmptyRef");
		
	Else
		
		CurrentRow.Department = PredefinedValue("Catalog.BusinessStructure.EmptyRef");
		
		If ValueIsFilled(CurrentRow.Warehouse)
			And ObjectAttributeValue(CurrentRow.Products, "ItemsType") = 
											PredefinedValue("Enum.ItemsTypes.Work_5") Then
												
			CurrentRow.Warehouse = PredefinedValue("Catalog.Warehouses.EmptyRef");
			
		EndIf;
			
	EndIf;
	
	FillInDefaultWarehouseInLine(ThisObject, CurrentRow);
	
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	
	AddActionCheckFillInFractionOfCost(StructureOfActions, ThisObject);
	
	StructureOfSpecificationFilling = ProductDataManagementClientServer.ActionParametersCheckFillSpecification(Object, CurrentRow, BOMSelectionParameters);
	StructureOfActions.Insert("CheckFillSpecification", StructureOfSpecificationFilling);
	
	IncomeAndExpensesClientServer.InsertActionClearItemAndExpenseAnalytics(StructureOfActions, ThisObject, "Object.ManufacturedProduct");
	
	If Not DestinationIsIndicatedInHeaderOfDocument(ThisObject) Then
		LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	EndIf;
	
	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		FormName, "ManufacturedProduct"));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure ManufacturedProductCharacteristicOnChange(Item)
	
	CurrentRow = Items.ManufacturedProduct.CurrentData;

	StructureOfActions = New Structure;
	
	If Not DestinationIsIndicatedInHeaderOfDocument(ThisForm) Then
		LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisForm, StructureOfActions);
	EndIf;
	
	StructureOfSpecificationFilling = ProductDataManagementClientServer.ActionParametersCheckFillSpecification(
			Object,
			CurrentRow,
			BOMSelectionParameters);
	StructureOfActions.Insert("CheckFillSpecification", StructureOfSpecificationFilling);
	
	If Object.ProductionProcessType =
		PredefinedValue("Enum.ProductionProcessTypes.WithoutBillsOfMaterials") Then
		StructureOfActions.Insert("CheckFillInCostShare", CostAllocationParameters);
	EndIf;
	
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "ManufacturedProduct"));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure ManufacturedProductNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.ManufacturedProduct.CurrentData;

	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	AddActionCheckFillInFractionOfCost(StructureOfActions, ThisObject);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure ManufacturedProductPackageOnChange(Item)
	
	CurrentRow = Items.ManufacturedProduct.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert(
		"RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	
	If Object.ProductionProcessType =
		PredefinedValue("Enum.ProductionProcessTypes.WithoutBillsOfMaterials") Then
		StructureOfActions.Insert("CheckFillInCostShare", CostAllocationParameters);
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure ManufacturedProductWarehouseOnChange(Item)
	
	CurrentRow = Items.ManufacturedProduct.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert(
		"RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure ManufacturedProductCanceledOnChange(Item)
	
	CurrentRow = Items.ManufacturedProduct.CurrentData;
	
	If Not CurrentRow.Canceled Then
		CurrentRow.CancellationReason = PredefinedValue("Catalog.ReasonsForProductionCancellation.EmptyRef");
	EndIf;

EndProcedure

&AtClient
Procedure ManufacturedProductToExpenseAsOnChange(Item)
	
	CurrentData = Items.ManufacturedProduct.CurrentData;
	
	If CurrentData.ItemsType <> PredefinedValue("Enum.ItemsTypes.Work_5") Then
		
		StructureOfActions = New Structure;
		
		If CurrentData.ToExpenseAs Then
			
			If ValueIsFilled(CurrentData.Warehouse) Then
				CurrentData.Warehouse         = PredefinedValue("Catalog.Warehouses.EmptyRef");
			EndIf;
			
		Else
			
			If ValueIsFilled(CurrentData.Department) Then
				CurrentData.Department = PredefinedValue("Catalog.BusinessStructure.EmptyRef");
			EndIf;
			
			FillInDefaultWarehouseInLine(ThisForm, CurrentData, StructureOfActions);
			
		EndIf;
		
		If ValueIsFilled(StructureOfActions) Then
			BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
		EndIf;	
		
	EndIf;
	
	IncomeAndExpensesClientServer.WhenChangingArticleAvailabilityDetailsInLine(ThisObject, CurrentData, "Object.ManufacturedProduct");
	
EndProcedure

&AtClient
Procedure ManufacturedProductExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ManufacturedProductExpenseItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure ManufacturedProductDimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ManufacturedProductDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, Parameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ManufacturedProductDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, Parameters, StandardProcessing);
	
EndProcedure

#EndRegion

#Region PageEventHandlersAdvanced

&AtClient
Procedure MethodOfAllocatingFinishedProductCostsOnChange(Item)
	
	MethodForAllocatingCostsForOutputProductsWhenChangingOnServer();
	
EndProcedure

&AtServer
Procedure MethodForAllocatingCostsForOutputProductsWhenChangingOnServer()
	
	CostAllocationParametersStructure = Documents.ProductionOrder2_2.CostAllocationParameters(Object);
	CostAllocationParameters = New FixedStructure(CostAllocationParametersStructure);
	
	ProductionServer.CalculateFractionOfCost(Object, CostAllocationParameters);
	CalculatePercentageOfCostAllocationForOutputProducts();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

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


#Region CommandBarForm

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm, True);
	
EndProcedure

&AtClient
Procedure ToOpenTheStructureOfTheOrderAction(Command)
	
	If Not Object.Posted Or Modified Then
		
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Tiến hành và tiếp tục?';
												|ru = 'Провести и продолжить?';
												|en = 'Post and continue?'; fa = 'Post and continue?';
												|it = 'Registrare e continuare?';
												|pl = 'Zatwierdzić i kontynuować?';
												|tr = 'Kaydedilsin ve devam edilsin mi?'"));
		Buttons.Add(DialogReturnCode.Cancel);
		
		QueryText = NStr("vi = 'Để đến nơi làm việc ""Cấu trúc đơn hàng"", cần kết chuyển chứng từ.';
						|ru = 'Для перехода в рабочее место ""Структура заказа"" необходимо провести документ.';
						|en = 'To go to the order structure, post the document.'; fa = 'To go to the order structure, post the document.';
						|it = 'Per passare alla postazione di lavoro ""Struttura dell''ordine"" è necessario registrare il documento.';
						|pl = 'Dla przejścia do miejsca pracy ""Структура заказа"" należy zatwierdzić.';
						|tr = '""Sipariş Yapısı"" çalışma alanına geçmek için belgeyi kaydetmeniz gerekmektedir.'");
		
		CallbackDescription = New CallbackDescription("ToOpenTheStructureOfTheOrderActionCompletion", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, Buttons);
		
	Else
		
		OpenOrderStructure();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ToOpenTheStructureOfTheOrderActionCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ThisForm.ForceCloseTheForm = False;
	
	WriteParameters = New Structure;
	WriteParameters.Insert("WriteMode", DocumentWriteMode.Posting);
	WriteParameters.Insert("PostingMode", DocumentPostingMode.Regular);
	WriteParameters.Insert("ForceCloseTheForm", False);
	WriteParameters.Insert("NewObject", Not ValueIsFilled(Object.Ref));
	
	If Write(WriteParameters) Then
		OpenOrderStructure();
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm, True);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm, True);
	
EndProcedure

&AtClient
Procedure SetDeletionMarkForADocument(Command)
	
	TMCommonUseClient.SetDeletionMarkForADocument(ThisForm);
	
EndProcedure

&AtClient
Procedure RecalculateOrderStructure(Command)
	
	If Object.Posted And Not Modified Then
		
		RunFullCalculationOfOrderStructure();
		
	Else
		
		Notification = New CallbackDescription("ConductAndRecalculateOrderStructureEnd", ThisObject);
		Buttons = New ValueList();
		QueryText = NStr("vi = 'Để tính lại cấu trúc đơn hàng, cần kết chuyển chứng từ. Kết chuyển?';
						|ru = 'Для пересчета структуры заказа документ должен быть проведен. Провести?';
						|en = 'To recalculate the order structure, the document must be posted. Post?'; fa = 'To recalculate the order structure, the document must be posted. Post?';
						|it = 'Для пересчета структуры заказа документ должен быть проведен. Провести?';
						|pl = 'To recalculate the order structure, the document must be posted. Post?';
						|tr = 'Sipariş yapısının yeniden hesaplanması için belgenin kaydedilmesi gerekmektedir. Kaydedilsin mi?'");
		Buttons.Add(DialogReturnCode.Yes,NStr("vi = 'Kết chuyển';
												|ru = 'Провести';
												|en = 'Post'; fa = 'ثبت';
												|it = 'Pubblicare';
												|pl = 'Post';
												|tr = 'Kaydet'"));
		Buttons.Add(DialogReturnCode.Cancel,NStr("vi = 'Hủy bỏ';
												|ru = 'Отмена';
												|en = 'Cancel'; fa = 'انصراف';
												|it = 'Annulla';
												|pl = 'Anuluj';
												|tr = 'İptal'"));
		
		ShowQueryBox(Notification, QueryText, Buttons, , DialogReturnCode.Yes);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ConductAndRecalculateOrderStructureEnd(UserAnswer, AdditionalParameters) Export
	
	If UserAnswer = DialogReturnCode.Yes Then
		
		TMCommonUseClient.Post(ThisForm);
		
		RunFullCalculationOfOrderStructure();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PlanSchedule(Command)
	
	If Object.Posted And Not Modified Then
		
		OpenSchedulePlanning();
		
	Else
		
		Notification = New CallbackDescription("PlanScheduleCompletion", ThisObject);
		Buttons = New ValueList();
		QueryText = NStr("vi = 'Để lập kế hoạch, cần kết chuyển đơn hàng sản xuất. Kết chuyển?';
						|ru = 'Для планирования заказ на производство должен быть проведен. Провести?';
						|en = 'You can only schedule posted production orders. Post the order?'; fa = 'You can only schedule posted production orders. Post the order?';
						|it = 'Для планирования заказ на производство должен быть проведен. Провести?';
						|pl = 'You can only schedule posted production orders. Post the order?';
						|tr = 'Üretim emrinin planlanması için belgenin kaydedilmesi gerekmektedir. Kaydedilsin mi?'");
		Buttons.Add(DialogReturnCode.Yes,NStr("vi = 'Kết chuyển';
												|ru = 'Провести';
												|en = 'Post'; fa = 'ثبت';
												|it = 'Провести';
												|pl = 'Post';
												|tr = 'Kaydet'"));
		Buttons.Add(DialogReturnCode.Cancel,NStr("vi = 'Hủy bỏ';
												|ru = 'Отмена';
												|en = 'Cancel'; fa = 'انصراف';
												|it = 'Отмена';
												|pl = 'Anuluj';
												|tr = 'İptal'"));
		
		ShowQueryBox(Notification, QueryText, Buttons, , DialogReturnCode.Yes);
		
	EndIf;

EndProcedure

&AtClient
Procedure PlanScheduleCompletion(UserAnswer, AdditionalParameters) Export
	
	If UserAnswer = DialogReturnCode.Yes Then
		
		TMCommonUseClient.Post(ThisForm);
		
		If Object.Posted And Not Modified Then
			
			OpenSchedulePlanning();
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormFooter

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure DecorationEditStagesClick(Item)
	
	If Not Object.Status = PredefinedValue("Enum.ProductionOrderStatuses2_2.ToProduce") Then
		
		MessageText = NStr("vi = 'Lập kế hoạch công đoạn chỉ có thể cho các đơn hàng có trạng thái ""%Status%""';
							|ru = 'Планирование этапов возможно только для заказов в статусе ""%Status%""';
							|en = 'You can plan stages only for orders in status ""%Status%"".'; fa = 'You can plan stages only for orders in status ""%Status%"".';
							|it = 'La pianificazione delle fasi è possibile solo per gli ordini nello stato ""%Status%""';
							|pl = 'Planowanie etapów jest możliwe tylko dla zamówień o statusie ""%Status%""';
							|tr = 'Aşama planlaması sadece ""%Status%"" durumundaki siparişler için mümkündür'");
		MessageText = StrReplace(
			MessageText,
			"%Status%",
			PredefinedValue("Enum.ProductionOrderStatuses2_2.ToProduce"));
		
		CommonClientServer.MessageToUser(MessageText,,, "Status");
		
		Return;
		
	EndIf;
	
	If Not Object.Posted Or Modified Then
		
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Tiến hành và tiếp tục?';
												|ru = 'Провести и продолжить?';
												|en = 'Post and continue?'; fa = 'Post and continue?';
												|it = 'Registrare e continuare?';
												|pl = 'Zatwierdzić i kontynuować?';
												|tr = 'Kaydedilsin ve devam edilsin mi?'"));
		Buttons.Add(DialogReturnCode.Cancel);
		
		QueryText = NStr("vi = 'Để chỉnh sửa các công đoạn của lệnh, trước tiên cần kết chuyển chứng từ.';
						|ru = 'Для редактирования этапов заказа необходимо провести документ.';
						|en = 'To edit order stages, post the document.'; fa = 'To edit order stages, post the document.';
						|it = 'Per modificare le fasi dell''ordine, è necessario registrare il documento.';
						|pl = 'W celu edycji etapów zamówienia należy zatwierdzić dokument.';
						|tr = 'Sipariş aşamalarının düzenlenmesi için belgeyi kaydetmeniz gerekmektedir.'");
		
		CallbackDescription = New CallbackDescription("DecorationEditStagesClickCompletion", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, Buttons);
		
	Else
		
		EditStages();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DecorationEditStagesClickCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ThisForm.ForceCloseTheForm = False;
	
	WriteParameters = New Structure;
	WriteParameters.Insert("WriteMode", DocumentWriteMode.Posting);
	WriteParameters.Insert("PostingMode", DocumentPostingMode.Regular);
	WriteParameters.Insert("ForceCloseTheForm", False);
	WriteParameters.Insert("NewObject", Not ValueIsFilled(Object.Ref));
	
	If Write(WriteParameters) Then
		EditStages();
	EndIf;
	
EndProcedure

&AtClient
Procedure DecorationToReflectTheCompletedStageClick(Item)
	
	If Not Object.Status = PredefinedValue("Enum.ProductionOrderStatuses2_2.ToProduce") Then
		
		MessageText = NStr("vi = 'Chỉ có thể phản ánh các công đoạn hoàn thành cho các đơn hàng ở trạng thái ""%Status%""';
							|ru = 'Отражение выполненных этапов возможно только для заказов в статусе ""%Status%""';
							|en = 'Recording of completed stages is available only for orders in the ""%Status%"" status'; fa = 'Recording of completed stages is available only for orders in the ""%Status%"" status';
							|it = 'La visualizzazione delle fasi completate è possibile solo per gli ordini nello stato ""%Status%""';
							|pl = 'Odzwierciedlenie wykonanych etapów jest możliwe tylko dla zamówień ""%Status%""';
							|tr = 'Gerçekleştirilen aşamaların yansıması sadece ""%Status%"" durumundaki siparişler için mümkündür'");
		MessageText = StrReplace(
			MessageText,
			"%Status%",
			PredefinedValue("Enum.ProductionOrderStatuses2_2.ToProduce"));
		
		CommonClientServer.MessageToUser(MessageText,,, "Status");
		
		Return;
		
	EndIf;
	
	If Not Object.Posted Or Modified Then
		
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Tiến hành và tiếp tục?';
												|ru = 'Провести и продолжить?';
												|en = 'Post and continue?'; fa = 'Post and continue?';
												|it = 'Registrare e continuare?';
												|pl = 'Zatwierdzić i kontynuować?';
												|tr = 'Kaydedilsin ve devam edilsin mi?'"));
		Buttons.Add(DialogReturnCode.Cancel);
		
		QueryText = NStr("vi = 'Để phản ánh các bước hoàn thành, một chứng từ phải được đăng.';
						|ru = 'Для отражения выполненных этапов необходимо провести документ.';
						|en = 'Post the document to record completed stages.'; fa = 'Post the document to record completed stages.';
						|it = 'Per riportare le fasi completate è necessario registrare il documento.';
						|pl = 'Dla odzwierciedlenia wykonanych etapów należy zatwierdzić.';
						|tr = 'Gerçekleştirilen aşamaların yansıması için belgenin kaydedilmesi gerekmektedir.'");
		
		CallbackDescription = New CallbackDescription("DecorationToReflectTheCompletedStageClickCompletion", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, Buttons);
		
	Else
		
		DisplayCompletedStage();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DecorationToReflectTheCompletedStageClickCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ThisForm.ForceCloseTheForm = False;
	
	WriteParameters = New Structure;
	WriteParameters.Insert("WriteMode", DocumentWriteMode.Posting);
	WriteParameters.Insert("PostingMode", DocumentPostingMode.Regular);
	WriteParameters.Insert("ForceCloseTheForm", False);
	WriteParameters.Insert("NewObject", Not ValueIsFilled(Object.Ref));
	
	If Write(WriteParameters) Then
		DisplayCompletedStage();
	EndIf;
	
EndProcedure

#EndRegion

#Region ProductsPage

&AtClient
Procedure OpenSelection(Command)
	
	HeaderParameter_ = NStr("vi = 'Chọn hàng hóa vào %Document%';
							|ru = 'Подбор товаров в %Document%';
							|en = 'Pick goods in %Document%'; fa = 'Pick goods in %Document%';
							|it = 'Selezione merci in %Document%';
							|pl = 'Wybór towarów w %Document%';
							|tr = '%Document% içindeki ürünlerin seçimi'");
	
	If ValueIsFilled(Object.Ref) Then
		HeaderParameter_ = StrReplace(HeaderParameter_, "%Document%", Object.Ref);
	Else
		HeaderParameter_ = StrReplace(HeaderParameter_, "%Document%", NStr("vi = 'đơn hàng sản xuất';
																			|ru = 'заказ на производство';
																			|en = 'production order'; fa = 'production order';
																			|it = 'ordine di produzione';
																			|pl = 'zlecenie produkcyjne';
																			|tr = 'üretim emri'"));
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("SelectionModeWithoutAmountParameters",         	 True);
	FormParameters.Insert("SelectionModeUseWarehousesInTabularSection", True);
	FormParameters.Insert("HideTheViewPriceColumn",                    	 True);
	FormParameters.Insert("HideTheItemPricesCommand",          	 True);
	FormParameters.Insert("Title",                                 	 HeaderParameter_);
	FormParameters.Insert("Date",                                     	 Object.Date);
	FormParameters.Insert("Document",                                 	 Object.Ref);
	FormParameters.Insert("FilterByProductType",                       New FixedArray(AvailableProductTypes.UnloadValues()));
	FormParameters.Insert("AllWarehouseBalance",                          True);

	OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form", FormParameters, ThisForm, UUID);
	
EndProcedure

&AtClient
Procedure ProductsToFillOutOnTheOrdersOfTheGiver(Command)
	
	FilterParameters = New Structure("Organization, LineOfBusiness, Partner, Contract, ProductionProcessType");
	FillPropertyValues(FilterParameters, Object);
	FilterParameters.Insert("ProductionManagement2_2", True);
	FormParameters = New Structure("Filter, MultipleChoice", FilterParameters, True);
	
	If Object.BusinessOperation =
			PredefinedValue("Enum.BusinessTransactions.TollManufacturing2_5") Then
		NameOfOrderSelectionForm = "Document.MaterialProviderOrder2_5.Form.OrderChoiceForm";
	EndIf;
	
	OpenForm(NameOfOrderSelectionForm, FormParameters, ThisForm, UUID);
	
EndProcedure

&AtClient
Procedure SplitRow(Command)
	
	StringSplittingParameters = ProcessingOfTabularFormsClient.StringSplittingParameters();
	StringSplittingParameters.AllowZeroCount = False;
	
	Notification = New CallbackDescription("SplitRowCompletion", ThisObject);
	ProcessingOfTabularFormsClient.SplitRow(Object.ManufacturedProduct, Items.ManufacturedProduct, Notification, StringSplittingParameters);
	
EndProcedure

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export
	
	If NewRow = Undefined Then
		Return;
	EndIf;
	
	NewRow.KeyProducts = Undefined;
	
	CurrentData = Items.ManufacturedProduct.CurrentData;
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	AddActionCheckFillInFractionOfCost(StructureOfActions, ThisObject);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
	
	RowsArray = New Array;
	RowsArray.Add(CurrentData.GetID());
	RowsArray.Add(NewRow.GetID());
	
	AfterChangingTSStringsProgrammaticallyOnServer(RowsArray, StructureOfActions);

EndProcedure

&AtClient
Procedure SpecificationsFillIn(Command)
	
	If Items.ManufacturedProduct.SelectedRows.Count() = 0 Then
		
		ShowMessageBox( ,NStr("vi = 'Không có hàng được chọn trong bảng. Chọn các dòng để điền vào thuộc tính ""Bảng kê chi tiết các nguồn lực sản xuất""';
								|ru = 'В таблице отсутствуют выделенные строки. Выделите строки для заполнения реквизита ""Спецификация""';
								|en = 'No lines are selected in the table. Select lines to fill in the BOM attribute'; fa = 'No lines are selected in the table. Select lines to fill in the BOM attribute';
								|it = 'Non ci sono righe selezionate nella tabella. Selezionare le righe per compilare il requisito ""Specifica""';
								|pl = 'Brak wydzielonych wierszy w tabeli. Zaznacz wiersze do wypełnienia atrybutu ""Спецификация""';
								|tr = 'Belirtilen satırlar tabloda bulunmamaktadır. ""Ürün Reçetesi"" özniteliklerinin doldurulması için satırları belirtin'"));
		Return;
		
	EndIf;
	
	FillInSpecificationInTablePart(Items.ManufacturedProduct.SelectedRows);
	
EndProcedure

&AtClient
Procedure ProductsFillInTheRecipient(Command)
	
	If Items.ManufacturedProduct.SelectedRows.Count() = 0 Then
		
		ShowMessageBox( ,NStr("vi = 'Trong bảng không có dòng được chọn. Hãy chọn các dòng để điền mục tin ""Nơi nhận""';
								|ru = 'В таблице отсутствуют выделенные строки. Выделите строки для заполнения реквизита ""Получатель""';
								|en = 'There are no selected rows in the table. Select rows to fill the ""Recipient"" attribute'; fa = 'There are no selected rows in the table. Select rows to fill the ""Recipient"" attribute';
								|it = 'Nella tabella mancano le righe selezionate. Seleziona le righe per compilare il requisito ""Destinatario""';
								|pl = 'W tabeli nie ma wierszy. Wybierz wiersze, aby wypełnić katalog ""Odbiorca""';
								|tr = 'Tabloda belirtilen satır bulunmamaktadır. ""Alıcı"" özniteliklerin doldurulması için satırları belirtin'"));
		Return;
		
	EndIf;
	
	TSParameters = New Structure;
	TSParameters.Insert("NameTSForm", "ManufacturedProduct");
	TSParameters.Insert("NameTsObject", "ManufacturedProduct");
	TSParameters.Insert("PresentationOfTS", NStr("vi = 'Sản phẩm';
												|ru = 'Продукция';
												|en = 'Manufactured products'; fa = 'محصولات تولیدی';
												|it = 'Prodotti';
												|pl = 'Manufactured products';
												|tr = 'İmal edilen ürünler'"));
	
	CallbackDescription = New CallbackDescription("FillInRecipientCompletion", 
													ThisObject, New Structure("TSParameters", TSParameters));
	
	ProductionClient.OpenRecipientSelectionForm(ThisForm, Object, TSParameters, AvailableProductTypes.UnloadValues(), CallbackDescription);
	
EndProcedure

&AtClient
Procedure ProductsFillInExpenseItem(Command)
	
	If Items.ManufacturedProduct.SelectedRows.Count() = 0 Then
		WarningText = NStr("vi = 'Cần chọn sản phẩm mà cần điền dạng chi phí.';
							|ru = 'Необходимо выбрать продукцию, для которой требуется заполнить статью расходов.';
							|en = 'Select manufactured products for which you need to fill the expense item.'; fa = 'Select manufactured products for which you need to fill the expense item.';
							|it = 'Необходимо выбрать продукцию, для которой требуется заполнить статью расходов.';
							|pl = 'Select manufactured products for which you need to fill the expense item.';
							|tr = 'Gider kalemini doldurmanız gereken ürünleri seçmeniz gerekmektedir.'");
		ShowMessageBox(,WarningText);
		Return;
	EndIf;
	
	IDs = New Array();
	For Each RowID In Items.ManufacturedProduct.SelectedRows Do
		RowData = Object.ManufacturedProduct.FindByID(RowID);
		If Not RowData.ToExpenseAs Then
			Continue;
		EndIf;
		IDs.Add(RowID);
	EndDo;
	
	If IDs.Count() = 0 Then
		WarningText = NStr("vi = 'Trong các dòng được chọn không có sản phẩm mà cần điền dạng chi phí.';
							|ru = 'В выделенных строках отсутствует продукция, для которой требуется заполнить статью расходов.';
							|en = 'The selected rows do not contain manufactured products for which you need to fill the expense item.'; fa = 'The selected rows do not contain manufactured products for which you need to fill the expense item.';
							|it = 'В выделенных строках отсутствует продукция, для которой требуется заполнить статью расходов.';
							|pl = 'The selected rows do not contain manufactured products for which you need to fill the expense item.';
							|tr = 'Belirtilen satırlarda, gider kaleminin doldurulması gereken imal edilen ürünler bulunmamaktadır.'");
		ShowMessageBox(,WarningText);
		Return;
	EndIf;
	
	IncomeAndExpensesClient.FillInArticleAndAnalyticsInSelectedLines(ThisObject, Items.ManufacturedProductExpenseItem, IDs);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsFillInNeedDate(Command)
	
	ArrayOfSelectedRows = Items.ManufacturedProduct.SelectedRows;
	If ArrayOfSelectedRows.Count() > 0 Then
		DemandDate = MinimumNeedDate(Object.ManufacturedProduct);
		
		Notification = New CallbackDescription("FillInNeedEndDate", ThisObject, New Structure("ArrayOfSelectedRows", ArrayOfSelectedRows));
		
		TMCommonUseClient.EnterDateWithControlOfEmptyValue(DemandDate, NStr("vi = 'Hãy nhập ngày mong muốn xuất xưởng';
																			|ru = 'Введите желаемую дату выпуска';
																			|en = 'Enter requested release date'; fa = 'Enter requested release date';
																			|it = 'Введите желаемую дату выпуска';
																			|pl = 'Enter requested release date';
																			|tr = 'İstenen çıkış tarihini girin'"), DateFormatOfSchedulePartOfDate, Notification);
		
	Else
		WarningText = NStr("vi = 'Trong chứng từ, chưa chọn dòng để điền. Chưa điền ngày mong muốn.';
							|ru = 'В документе не выбраны строки для заполнения. Желаемая дата не будет заполнена.';
							|en = 'No lines to fill are selected in the document. Requested date will not be filled.'; fa = 'No lines to fill are selected in the document. Requested date will not be filled.';
							|it = 'В документе не выбраны строки для заполнения. Желаемая дата не будет заполнена.';
							|pl = 'No lines to fill are selected in the document. Requested date will not be filled.';
							|tr = 'Belgede doldurulacak herhangi bir satır seçilmedi. İstenen tarih doldurulmayacaktır.'");
		ShowMessageBox(Undefined, WarningText);
	EndIf;

EndProcedure

&AtClient
Procedure ProductsCancelSelectedLines(Command)
	
	If Object.ManufacturedProduct.Count() = 0 Then
		ShowMessageBox(Undefined, NStr("vi = 'Phần bảng chưa điền.';
										|ru = 'Табличная часть не заполнена.';
										|en = 'Table is not filled in.'; fa = 'Table is not filled in.';
										|it = 'Parte tabulare non compilata.';
										|pl = 'Wypełnić ponownie część tabelaryczną?';
										|tr = 'Tablo bölümü doldurulmadı.'"));
		Return;
	ElsIf Items.ManufacturedProduct.SelectedRows.Count() = 0 Then
		ShowMessageBox(Undefined, NStr("vi = 'Không có hàng được tô sáng trong phần bảng.';
										|ru = 'В табличной части отсутствуют выделенные строки.';
										|en = 'No rows are selected in the table.'; fa = 'No rows are selected in the table.';
										|it = 'Nella parte tabulare non ci sono righe selezionate.';
										|pl = 'W części tabelarycznej nie ma zaznaczonych wierszy.';
										|tr = 'Tablo bölümünde belirtilen satırlar bulunmamaktadır.'"));
		Return;
	EndIf;
	
	OpenForm("Catalog.ReasonsForProductionCancellation.ChoiceForm",
		,
		,
		,
		,
		,
		New CallbackDescription("ProductsCancelSelectedLinesCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ProductsCancelSelectedLinesCompletion(CancellationReason, AdditionalParameters) Export
	
	If CancellationReason = Undefined Then
		Return;
	EndIf;
	
	SelectedRows = Items.ManufacturedProduct.SelectedRows;
	ProductsCancelSelectedLinesCompletionServer(SelectedRows, CancellationReason);
	
	ShowUserNotification(
		NStr("vi = 'Các dòng đã chọn bị hủy bỏ';
			|ru = 'Выделенные строки отменены';
			|en = 'Selected lines are canceled'; fa = 'Selected lines are canceled';
			|it = 'Righe selezionate annullate';
			|pl = 'Zaznaczone wiersze anulowano';
			|tr = 'Belirtilen satırlar iptal edildi'"),
		,
		NStr("vi = 'Dòng được chọn trong đơn hàng bị hủy bỏ';
			|ru = 'Выделенные строки заказа отменены.';
			|en = 'Selected order lines are canceled.'; fa = 'Selected order lines are canceled.';
			|it = 'Righe selezionate dell''ordine sono annullate.';
			|pl = 'Wydzielone wiersze zamówienia zamówienia są anulowane.';
			|tr = 'Belirtilen sipariş satırları iptal edildi.'"),
		PictureLib.Information32);
	
EndProcedure

&AtServer
Procedure ProductsCancelSelectedLinesCompletionServer(Val SelectedRows, CancellationReason)
	
	For Each Id In SelectedRows Do
		
		TableRow = Object.ManufacturedProduct.FindByID(Id);
		
		If TableRow <> Undefined Then
			
			TableRow.CancellationReason = CancellationReason;
			
			If Not TableRow.Canceled Then
				TableRow.Canceled = True;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If Object.ProductionProcessType =
		PredefinedValue("Enum.ProductionProcessTypes.WithoutBillsOfMaterials") Then
		CalculatePercentageOfCostAllocationForOutputProducts();
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductsHideCanceledLines(Command)
	
	HideCanceledLines = Not HideCanceledLines;
	
	If HideCanceledLines Then
		Items.ManufacturedProduct.RowFilter = New FixedStructure("Canceled", False);
	Else
		Items.ManufacturedProduct.RowFilter = Undefined;
	EndIf;
	
	Items.ProductsHideCanceledLines.Check = HideCanceledLines;
	
EndProcedure

&AtClient
Procedure ProductsTreeSpecifications(Command)
	
	CurrentData = Items.ManufacturedProduct.CurrentData;
	
	If CurrentData = Undefined Then
		ShowMessageBox(, NStr("vi = 'Trong bảng không có dòng được chọn. Hãy chọn dòng để mở cây bảng kê chi tiết.';
								|ru = 'В таблице отсутствует выделенная строка. Выделите строку для открытия дерева спецификации.';
								|en = 'There is no selected line in the table. Select a line to open a BOM tree.'; fa = 'There is no selected line in the table. Select a line to open a BOM tree.';
								|it = 'Nessuna riga evidenziata nella tabella. Evidenzare una riga per aprire l''albero della specifica.';
								|pl = 'W tabeli nie ma wybranego wiersza. Wybierz wiersz, aby otworzyć drzewo specyfikacji.';
								|tr = 'Tabloda belirtilen satır bulunmamaktadır. Ürün reçetesi ağacının açılması için satır belirtin.'"));
		Return;
	EndIf;
	
	BillOfMaterials = CurrentData.BillOfMaterials;
	Products = CurrentData.Products;
	Characteristic = CurrentData.Characteristic;
	
	If Not ValueIsFilled(BillOfMaterials) And Not ValueIsFilled(Products) Then
		ShowMessageBox(, NStr("vi = 'Trong dòng được chọn cần điền bằng kê chi tiết hoặc mặt hàng.';
								|ru = 'В выбранной строке должна быть заполнена спецификация либо номенклатура.';
								|en = 'The bill of materials or the item must be filled in the selected line.'; fa = 'The bill of materials or the item must be filled in the selected line.';
								|it = 'La riga selezionata deve contenere la specifica o l''articolo.';
								|pl = 'W wybranym wierszu powinna być wypełniona specyfikacja lub produkt.';
								|tr = 'Belirtilen satırda, ürün reçetesi veya öğe doldurulmalıdır.'"));
		Return;
	EndIf;
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("BillOfMaterials", BillOfMaterials);
	OpeningParameters.Insert("Products", Products);
	OpeningParameters.Insert("Characteristic", Characteristic);
	OpeningParameters.Insert("OutputProductQuantity", CurrentData.Count);
	OpeningParameters.Insert("NumberOfPackagesOfOutputProduct", CurrentData.NumberOfPackages);
	OpeningParameters.Insert("OutputProductPackaging", CurrentData.Package);
	OpeningParameters.Insert("Date", Object.EarliestStartDate);
	OpeningParameters.Insert("ProductionDispatcherBusinessUnit", Object.Department);
	OpeningParameters.Insert("LineOfBusiness", Object.LineOfBusiness);
	OpeningParameters.Insert("GenerateOnOpen", True);
	OpeningParameters.Insert("Title", NStr("vi = 'Cây bảng kê chi tiết';
											|ru = 'Дерево спецификации';
											|en = 'BOM tree'; fa = 'درخت فهرست مواد';
											|it = 'Albero della specifica';
											|pl = 'Drzewo specyfikacji';
											|tr = 'Ürün ağacı'")); 
	OpeningParameters.Insert("ViewMode", "BillOfMaterials");
	
	
	OpenForm("DataProcessor.BillsOfMaterialsTree.Form",
		OpeningParameters,
		ThisObject,
		UUID);
	
EndProcedure

#EndRegion

#Region UniversalMechanisms

#Region IntegrationWith1CDocumentManagementSubsystem

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

#Region Other

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)

	ObjectAttributesLockClient.AllowObjectAttributeEdit(ThisObject);
	
EndProcedure

#EndRegion

#Region Clipboard

&AtClient
Procedure InsertRows(Command)
	
	NumberOfProductsBeforeInsertion = Object.ManufacturedProduct.Count();
	
	GetLinesFromClipboard();
	
	NumberOfInserted = Object.ManufacturedProduct.Count() - NumberOfProductsBeforeInsertion;
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
	
EndProcedure

&AtClient
Procedure CopyRows(Command)
	
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items.ManufacturedProduct) Then
		CopyLinesOnServer();
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(Items.ManufacturedProduct.SelectedRows.Count());
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region ImportDataFromFile

&AtClient
Procedure ImportFromExternalFile(Command)
	
	AdditionalParameters = AdditionalParametersForDownloadingFromFile();
	ShowUploadFormFromFile(AdditionalParameters);
	
EndProcedure

#EndRegion

&AtClient
Procedure StageDispatching(Command)
	
	If Not ValueIsFilled(Object.Ref) Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("FiltersStructure", New Structure("ReferenceOrder", Object.Ref));
	
	OpenForm("Document.ProductionStage2_2.Form.ProductionStageDispatching", FormParameters, ThisObject, True);
	
EndProcedure

#EndRegion

#Region Private

#Region ConditionalAppearance

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	// standard design of the nomenclature
#Region ProductsCharacteristic

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "ProductsUnitOfMeasurement_3";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.ManufacturedProduct.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);
		
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm, 
		"ManufacturedProductCharacteristic",
		"Object.ManufacturedProduct.ItemVariantsAreUsed");
		
#EndRegion

	// warehouse and division registration
#Region Recipient

	// disabling the visibility of the warehouse if the work or service or is set to be charged to expenses
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductWarehouse.Name);
	
	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	SelectionGroupAnd = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupAnd.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseSeveralWarehouses");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ManufacturedProduct.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.Work_5;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseSeveralWarehouses");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.ManufacturedProduct.ToExpenseAs");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	// disabling the visibility of the unit if the product or container is either empty or is not selected and is not set to write off for expenses

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductDepartment.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseSeveralWarehouses");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ManufacturedProduct.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	ValueList.Add(Enums.ItemsTypes.ReusablePackage);
	ValueList.Add(Enums.ItemsTypes.EmptyRef());
	
	ItemFilter.RightValue = ValueList;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.ManufacturedProduct.ToExpenseAs");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	// Explanatory inscription for the division, if the full name "Several warehouses" is not used.

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductDepartment.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseSeveralWarehouses");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ManufacturedProduct.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	ValueList.Add(Enums.ItemsTypes.ReusablePackage);
	
	ItemFilter.RightValue = ValueList;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.ManufacturedProduct.ToExpenseAs");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
#EndRegion

	// design of items and cost analytics
#Region ExpenseAs
	
	GivingOperations = New ValueList;
	GivingOperations.Add(Enums.BusinessTransactions.TollManufacturing2_5);
	
	// visibility depends on the type of production process
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductToExpenseAs.Name);
	
	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.BusinessOperation"); 
	ItemFilter.ComparisonType   = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = GivingOperations;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.ProductionProcessType");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.InList;
	
	ListOfProcessTypes = New ValueList;
	ListOfProcessTypes.Add(Enums.ProductionProcessTypes.Disassembly);
	ListOfProcessTypes.Add(Enums.ProductionProcessTypes.Repair);
	
	ItemFilter.RightValue = ListOfProcessTypes;
	
	Item.Appearance.SetParameterValue("Visible" , False);

	// explanatory inscription, if we do not write off work and expenses

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductDimensionOfExpenses.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.ManufacturedProduct.ToExpenseAs");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Text"      , NStr("vi = '<khi ghi giảm vào chi phí>';
														|ru = '<при списании на расходы>';
														|en = '<when writing off as expenses>'; fa = '<when writing off as expenses>';
														|it = '<durante lo storno sulle spese>';
														|pl = '<przy wyksięgowaniu na rozchody>';
														|tr = '<giderlere yazılırken>'"));
	Item.Appearance.SetParameterValue("TextColor" , StyleColors.InaccessibleCellTextColor);
	
	// the purpose is not indicated when writing off expenses
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductPurpose.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.ManufacturedProduct.ToExpenseAs");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor"     , StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text"          , NStr("vi = '<không được sử dụng để khấu trừ chi phí>';
															|ru = '<не используется при списании на расходы>';
															|en = '<not used while writing off as expenses>'; fa = '<not used while writing off as expenses>';
															|it = '<non viene usato durante storno sulle spese>';
															|pl = '<nie używane podczas rozchodu na wydatki>';
															|tr = '<giderlere yazılırken kullanılmamaktadır>'"));
	Item.Appearance.SetParameterValue("ReadOnly" , True);
	
#EndRegion

	// mandatory completion of contracts
#Region Contract
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Contract.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ContractIsNotRequired");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
#EndRegion

	// in the tolling scheme, the assignment is required to be filled in
#Region Purpose

	ProductsServer.SetConditionalAppearanceOfProductAssignment(
		ThisObject, "ManufacturedProductPurpose", "Object.ManufacturedProduct.ItemsType", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AssignmentProducts.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = GivingOperations;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.AssignmentProducts");
	ItemFilter.ComparisonType  = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ManufacturedProduct.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ItemsTypes.ReusablePackage;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductPurpose.Name);
	
	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = GivingOperations;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ManufacturedProduct.Canceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ManufacturedProduct.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.ReusablePackage;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);

#EndRegion

	// Priority
	TMCommonUse.SetConditionalAppearanceOfPriority(ThisForm);
	
	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisForm);
	
	OrdersServer.SetAppearanceOfCanceledLine(ConditionalAppearance, Items.ManufacturedProduct, Items.ManufacturedProductCanceled.Name, Items.ManufacturedProductCancellationReason.Name);

#Region BillOfMaterials
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductBillOfMaterials.Name);
	
	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DynamicStructure");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ProductionOrderStatuses2_2.BeingGenerated;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ManufacturedProduct.Canceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductBillOfMaterials.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ProductionProcessType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ProductionProcessTypes.WithoutBillsOfMaterials;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
#EndRegion

#Region DemandDate
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductDemandDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DemandDateRequired_");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
#EndRegion

#Region CostShares

	ProductionServer.SetConditionalAppearanceOfShareCostPercentageField(
		ThisForm, "Object", "ManufacturedProduct");
		
	ProductionServer.SetConditionalAppearanceOfShareOfCostOfCanceledRowsField(
		ThisForm, "Object", "ManufacturedProduct");
	
#EndRegion
	
EndProcedure

#EndRegion

#Region FormSettingsItem

&AtServer
Procedure CustomizeFormElements()
	
	Items.ProductionProcessType.Visible = TypeOfProductionProcessIsAvailable;

	Items.BusinessOperation.Visible =
		UseTollManufacturing2_5
		Or False;      
	
	FillOperationSelectionList();
	
	Items.DynamicStructure.Visible = Not Transferred_To_Production;
	
	Items.EarliestStartDate.EditFormat = ScheduleDateFormat;
	Items.DemandDate.EditFormat = ScheduleDateFormat;
	Items.ManufacturedProductDemandDate.Format = ScheduleDateFormat;
	Items.ManufacturedProductDemandDate.EditFormat = ScheduleDateFormat;
	
	#Region DateOfNeedOnForm
	
	SeveralNeedDatesAreAvailable = Object.DynamicStructure;
	
	NeedDateSelectionList = Items.DemandDate.ChoiceList;
	NeedDateSelectionList.Clear();
	
	If SeveralNeedDatesAreAvailable Then;
		NeedDateSelectionList.Add("SpecifiedInLines", NStr("vi = 'Được chỉ ra theo từng dòng';
															|ru = 'Указывается построчно';
															|en = 'Specified line by line'; fa = 'Specified line by line';
															|it = 'Указывается построчно';
															|pl = 'Specified line by line';
															|tr = 'Satır başına belirtilmektedir'"));
		NeedDateSelectionList.Add("ChooseFromCalendar", NStr("vi = 'Chọn...';
															|ru = 'Выбрать...';
															|en = 'Select...'; fa = 'انتخاب...';
															|it = 'Выбрать...';
															|pl = 'Select...';
															|tr = 'Seç...'"));
		NeedDateSelectionList.Add("Today", NStr("vi = 'Hôm nay';
												|ru = 'Сегодня';
												|en = 'Today'; fa = 'امروز';
												|it = 'Сегодня';
												|pl = 'Today';
												|tr = 'Bugün'"));
		NeedDateSelectionList.Add("Tomorrow", NStr("vi = 'Ngày mai';
													|ru = 'Завтра';
													|en = 'Tomorrow'; fa = 'Tomorrow';
													|it = 'Завтра';
													|pl = 'Tomorrow';
													|tr = 'Yarın'"));
		NeedDateSelectionList.Add("InAWeek", NStr("vi = 'Trong một tuần';
													|ru = 'Через неделю';
													|en = 'In a week'; fa = 'In a week';
													|it = 'Tra una settimana';
													|pl = 'Za tydzień';
													|tr = 'Bir hafta sonra'"));
	EndIf; 
	
	Items.DemandDate.DropListButton = ?(SeveralNeedDatesAreAvailable, True, Undefined);
	Items.DemandDate.ChoiceButton = ?(SeveralNeedDatesAreAvailable, False, Undefined);
	
	If SeveralNeedDatesAreAvailable And Object.DemandDateIsSpecifiedInLines Then
		DateOfNeedOnForm = Items.DemandDate.ChoiceList.FindByValue("SpecifiedInLines");
	Else
		DateOfNeedOnForm = Object.DemandDate;		
	EndIf;
	
	#EndRegion
	
	#Region AccessManagement
	
	If Not AccessRight("Update", Metadata.Documents.ProductionOrder2_2) Then
		Items.FormQueueOfOrders.Visible             = False;
		Items.FormRecalculateOrderStructure.Visible = False;
		Items.RecalculateOrderStructure.Visible      = False;
		Items.GroupIsDynamicStructure.Enabled   = False;
		Items.PlanSchedule.Enabled             = False;
	EndIf;
	
	If Not AccessRight("Read", Metadata.Catalogs.BillsOfMaterials) Then
		Items.ProductSpecificationsFillIn.Visible = False;
	EndIf;
	
	If Not AccessRight("View", Metadata.Reports.ProductionOrderStructure2_2)
			Or Not AccessRight("View", Metadata.Reports.ProductionOrderStructureDynamic) Then
		Items.FormOrderStructure.Visible = False;
	EndIf;
	
	If Not AccessRight("Use", Metadata.DataProcessors.EditProductionStageSequence) Then
		Items.DecorationEditStages.Enabled = False;
	EndIf;
	
	If Not AccessRight("Update", Metadata.Documents.ProductionStage2_2) Then
		Items.DecorationToReflectTheCompletedStage.Enabled = False;
	EndIf;
	
	If Not AccessRight("View", Metadata.DataProcessors.BillsOfMaterialsTree) Then
		Items.ProductsSpecificationsTreeSpecifications.Visible = False;
	EndIf;
	
	If Not AccessRight("View", Metadata.Catalogs.Warehouses) Then
		Items.ProductsFillInTheRecipient.Visible = False;
	EndIf;
	
	If Not AccessRight("View", Metadata.ChartsOfCharacteristicTypes.ExpenseItems)
		Or Not AccessRight("View", Metadata.ChartsOfCharacteristicTypes.AssetLiabilityItems) Then
		Items.ProductsFillInTheRecipient.Visible = False;
	EndIf;
	
	#EndRegion
	
	ConfigureDependentFormElements(ThisForm);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Items = Form.Items;
	Object = Form.Object;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	// Actions ON changing the type of production process
	//  - setting the item selection parameters
	//  - Setting Bill of Materials selection parameters.
	//  - setting the visibility of the order structure
	//  - setting the visibility of the cost share.
	//  - output to the basement of hyperlinks editing stages
	If AttributesStructure1.Property("ProductionProcessType")
		Or Initialize Then
		
		ProductDataManagementClientServer.SetSelectionByItemType(Items.ManufacturedProductProducts, Form.AvailableProductTypes.UnloadValues());
		
		// Without bill of Materials
		
		Items.MethodOfAllocatingFinishedProductCosts.Visible =
			Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.WithoutBillsOfMaterials");
		Items.ProductsGroupShareOfValue.Visible =
			Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.WithoutBillsOfMaterials");
		Items.DecorationEditStages.Visible =
			Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.WithoutBillsOfMaterials");
		Items.DecorationToReflectTheCompletedStage.Visible =
			Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.WithoutBillsOfMaterials"); 
			
	EndIf;
	
	// Actions on changes of operation
	//  - setting the visibility of the partner/Contract.
	//  - setting partner selection parameters
	If AttributesStructure1.Property("BusinessOperation")
		Or Initialize Then
		
		ValueBoolean =
			Object.BusinessOperation =
				PredefinedValue("Enum.BusinessTransactions.TollManufacturing2_5")
				Or False;
		
		Items.Partner.Visible = ValueBoolean;
		Items.Contract.Visible = ValueBoolean;
		
		// Partner selection parameters
		ChoiceParametersArray = New Array;
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.Client", True));
		
		If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TollManufacturing2_5") Then
			ChoiceParametersArray.Add(New ChoiceParameter("Filter.Vendor", True));
		EndIf;
		
		Items.Partner.ChoiceParameters = New FixedArray(ChoiceParametersArray);
		
	EndIf;
	
	// ManufacturedProduct
	If AttributesStructure1.Property("ProductionProcessType")
		Or AttributesStructure1.Property("Status")
		Or AttributesStructure1.Property("BusinessOperation")
		Or Initialize Then
		
		Items.ProductsPage.Title = ProductionClientServer.TitleOfTablePartByProcessType(Object.ProductionProcessType);
		
		Items.AssignmentProducts.Visible = DestinationIsIndicatedInHeaderOfDocument(Form);
		Items.ManufacturedProductPurpose.Visible = Not Items.AssignmentProducts.Visible;
		
		NumberOfAvailableTypes = Form.AvailableProductTypes.Count();
		If NumberOfAvailableTypes = 1 Then
			If Form.AvailableProductTypes[0].Value = PredefinedValue("Enum.ItemsTypes.Work_5") Then
				Items.ProductsGroupOfTheRecipient.Title = NStr("vi = 'Bộ phận-nơi nhận';
																|ru = 'Подразделение-получатель';
																|en = 'Receiving business unit'; fa = 'واحد تجاری دریافت‌کننده';
																|it = 'Reparto-destinatario';
																|pl = 'Receiving business unit';
																|tr = 'Alıcı departman '");
				Items.ProductsOfOpenRecruitment.Title = NStr("vi = 'Lựa chọn công việc';
															|ru = 'Подобрать работы';
															|en = 'Pick works'; fa = 'Pick works';
															|it = 'Pick works';
															|pl = 'Pick works';
															|tr = 'Подобрать работы'");
			Else
				Items.ProductsGroupOfTheRecipient.Title = NStr("vi = 'Kho bãi';
																|ru = 'Склад';
																|en = 'Warehouse'; fa = 'Warehouse';
																|it = 'Magazzino';
																|pl = 'Warehouse';
																|tr = 'Ambar'");
				Items.ProductsOfOpenRecruitment.Title = NStr("vi = 'Chọn hàng hóa';
															|ru = 'Подобрать товары';
															|en = 'Pick goods'; fa = 'انتخاب کالاها';
															|it = 'Selezionare la merce';
															|pl = 'Dobierz wiersze pozycji';
															|tr = 'Ürünleri seç'");
			EndIf;
		Else
			If Form.UseSeveralWarehouses Then
				Items.ProductsGroupOfTheRecipient.Title = NStr("vi = 'Người nhận';
																|ru = 'Получатель';
																|en = 'Recipient'; fa = 'گیرنده';
																|it = 'Destinatario';
																|pl = 'Recipient';
																|tr = 'Alıcı'");
			Else
				Items.ProductsGroupOfTheRecipient.Title = NStr("vi = 'Bộ phận-nơi nhận';
																|ru = 'Подразделение-получатель';
																|en = 'Receiving business unit'; fa = 'واحد تجاری دریافت‌کننده';
																|it = 'Reparto-destinatario';
																|pl = 'Receiving business unit';
																|tr = 'Alıcı departman '");
			EndIf;
			Items.ProductsOfOpenRecruitment.Title = NStr("vi = 'Chọn hàng hóa và công việc';
														|ru = 'Подобрать товары и работы';
														|en = 'Pick goods and works'; fa = 'انتخاب کالا و کارها';
														|it = 'Pick goods and works';
														|pl = 'Pick goods and works';
														|tr = 'Ürün ve işleri seç'");
		EndIf;
		
		Items.ProductsOfOpenRecruitment.Visible =
			Object.BusinessOperation <> PredefinedValue("Enum.BusinessTransactions.TollManufacturing2_5")
			And True;
		Items.ProductsToFillOutOnTheOrdersOfTheGiver.Visible =
			Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TollManufacturing2_5")
			Or False;
		
		Items.ProductSpecificationsFillIn.Visible =
			Object.ProductionProcessType <> PredefinedValue("Enum.ProductionProcessTypes.WithoutBillsOfMaterials");
		
	EndIf;
	
	// The desired release date is mandatory for dynamic orders and when planning "By the end"
	// For orders with a dynamic structure, it is possible to specify the desired release dates in TS
	If AttributesStructure1.Property("DynamicStructure")
		Or AttributesStructure1.Property("ProductionProcessType")
		Or AttributesStructure1.Property("ProductionScheduling")
		Or AttributesStructure1.Property("DemandDate")
		Or Initialize Then
		
		NeedDateIsUsed = Not 
			Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.Disassembly");
		
		Items.DemandDate.Visible = NeedDateIsUsed;
		Items.ManufacturedProductDemandDate.Visible = NeedDateIsUsed And Object.DemandDateIsSpecifiedInLines;
		Items.ManufacturedProductManufacturedProductsFillInNeedDate.Visible = NeedDateIsUsed And Object.DemandDateIsSpecifiedInLines;
		
		Items.DemandDate.AutoMarkIncomplete = Form.DemandDateRequired_ And Not ValueIsFilled(Object.DemandDate);
		Items.DemandDate.MarkIncomplete = Form.DemandDateRequired_ And Not Object.DemandDateIsSpecifiedInLines And Not ValueIsFilled(Object.DemandDate);
		Items.ManufacturedProductDemandDate.MarkIncomplete = Form.DemandDateRequired_;
		
		Items.DemandDate.TextEdit = Not Object.DemandDateIsSpecifiedInLines;
		Items.DemandDate.BackColor = ?(Object.DemandDateIsSpecifiedInLines, WebColors.PapayaWhip, New Color());
	
	EndIf;
	
	// Production schedule
	If AttributesStructure1.Property("ProductionSchedule")
		Or AttributesStructure1.Property("Status")
		Or AttributesStructure1.Property("DynamicStructure")
		Or Initialize Then
		
		If Object.DynamicStructure And Form.TheProductionScheduleIsPlanned
			And Form.ThereIsRightToCalculateSchedule
			And Object.Status = PredefinedValue("Enum.ProductionOrderStatuses2_2.ToProduce") Then
			Items.PlanSchedule.Visible = True;
			Items.PlanSchedule.TextColor = ?(Form.StatusScheduleNeedsToBeCalculated = PredefinedValue("Enum.ProductionScheduleStatusesInProductionOrder.RequiredToCalculate"),
				Form.HyperlinkColors.B, Form.HyperlinkColors.Gray);
		Else
			Items.PlanSchedule.Visible = False;
		EndIf;
		
	EndIf;
	
	// Issue placement is not used in disassembly orders and in orders with a dynamic structure
	If AttributesStructure1.Property("DynamicStructure") 
		Or AttributesStructure1.Property("ProductionProcessType")
		Or Initialize Then
		
		Items.ProductionScheduling.Visible = Not (Object.DynamicStructure 
														Or Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.Disassembly"));
			
	EndIf;
	
	// Other elements of the dynamic structure structure
	If AttributesStructure1.Property("DynamicStructure")
		Or AttributesStructure1.Property("Status")
		Or Initialize Then

		Items.FormRecalculateOrderStructure.Visible = Object.DynamicStructure;
		Items.ConsolidatedOrderByProductAssignments.Visible = Object.DynamicStructure
			And (Object.OptionOfAssignment = PredefinedValue("Enum.OptionsOfMaterialAssignmentInProduction.AssignmentOfProducts")
				Or Object.OptionOfAssignment.IsEmpty()
				And Form.CurSeparationOption = PredefinedValue("Enum.OptionsOfMaterialAssignmentInProduction.AssignmentOfProducts"));
		Items.SupplyOfAssignedMaterialsAndWorks.Visible = Not Object.DynamicStructure Or Object.SupplyOfAssignedMaterialsAndWorks;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region PageMaintenanceIsBasic

&AtServer
Procedure WhenChangingDateServer()
	
	UpdateOrderForActivity(True);

	MethodForAllocatingCostsForOutputProductsWhenChangingOnServer();
	
EndProcedure

&AtServer
Procedure WhenOrganizationChangesServer()
	
	UpdateOrderForActivity(True);
	
EndProcedure

&AtServer
Procedure DirectionOfActivityWhenChangingOnServer()
	
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	
	UpdateOrderForActivity(True);
	
	CheckUpdateAccountDetails(True, False);
	
EndProcedure

&AtServer
Procedure UpdateOrderForActivity(Fill = True)
	
	FillParameters = Documents.ProductionOrder2_2.ParametersForFillingInVATActivityType(Object);
	
	If Fill Then
		VATAccountingERP.FillInTypeOfActivityVAT(
			Object.OrderForActivity,
			FillParameters,
			VATAccountingCachedParameterValues);
	EndIf;
	
	VATAccountingERP.FillInActivitySelectionList(
		Items.OrderForActivity,
		Object.OrderForActivity,
		FillParameters,
		VATAccountingCachedParameterValues);
	
EndProcedure

&AtServer
Procedure PartnerWhenChangesAreMadeOnServer()
	
	CheckUpdateAccountDetails(True, True);
	
EndProcedure

&AtServer
Procedure AgreementWhenModifiedOnServer()
	
	CheckUpdateAccountDetails(True, True);
	
EndProcedure

&AtServer
Procedure StatusChangedOnServer(ValuesCache)

	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.ProductionOrder2_2));
	FillInStatusesOfSpecifyingBatchesOfFINISHEDProductBeingRepaired();
	
	ConfigureDependentFormElements(ThisForm, "Status");

EndProcedure

&AtServer
Procedure BusinessOperationWhenChangingOnServer()
	
	If Object.BusinessOperation = Enums.BusinessTransactions.OwnProduction Then
		
		Object.Contract = Catalogs.CounterpartyContracts.EmptyRef();
		Object.Partner = Catalogs.Partners.EmptyRef();
		
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.ProductionOrder2_2.ItemsAndDimensionsSelectionParameters(Object);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	CheckUpdateAccountDetails(True, True);
	CheckUpdateBankingDetailsWriteOffForExpensesInTableSection();
	
	ConfigureDependentFormElements(ThisForm, "BusinessOperation");
	
EndProcedure

&AtServer
Procedure FillOperationSelectionList()
	
	ChoiceList = Items.BusinessOperation.ChoiceList;
	ChoiceList.Clear();
	ChoiceList.Add(PredefinedValue("Enum.BusinessTransactions.OwnProduction"));
	
	
	If UseTollManufacturing2_5 Then
		ChoiceList.Add(
			PredefinedValue("Enum.BusinessTransactions.TollManufacturing2_5"));
	EndIf;
	
EndProcedure

&AtServer
Procedure DynamicStructureWhenChangingOnServer() 
	
	ProductionServer.FillInListOfProductionProcessTypes(Items.ProductionProcessType,, Object.DynamicStructure);
	If Object.ProductionProcessType <> Enums.ProductionProcessTypes.Assembly Then
		Object.ProductionProcessType = Enums.ProductionProcessTypes.Assembly;
		TypeOfProductionProcessWhenChangedOnServer();
	EndIf;
	
	SetRequiredDateAttribute(ThisForm);

	CustomizeFormElements();
	
EndProcedure

&AtServer
Procedure TypeOfProductionProcessWhenChangedOnServer()
	
	If Object.ProductionProcessType = Enums.ProductionProcessTypes.WithoutBillsOfMaterials
	   And (TypeOfProductionProcessBeforeTheChange = Enums.ProductionProcessTypes.Assembly
	   Or TypeOfProductionProcessBeforeTheChange = Enums.ProductionProcessTypes.Repair
	   Or TypeOfProductionProcessBeforeTheChange = Enums.ProductionProcessTypes.Disassembly)Then
	
		ProductionServer.FillInDetailsInCollection(Object.ManufacturedProduct, "BillOfMaterials", Catalogs.BillsOfMaterials.EmptyRef());
		
	Else
		
		Object.ManufacturedProduct.Clear();
	
	EndIf;
	
	AvailableProductTypes.LoadValues(ProductDataManagementClientServer.TypesOfItemsByTypeOfProductionProcess(Object.ProductionProcessType));
	BOMSelectionParameters = ProductDataManagement.BOMSelectionParameters(Object, Documents.ProductionOrder2_2);
	ProductDataManagement.SetSpecificationSelectionParameters(Items.ManufacturedProductBillOfMaterials, BOMSelectionParameters);
	
	If Object.ProductionProcessType = Enums.ProductionProcessTypes.Disassembly
		Or Object.ProductionProcessType = Enums.ProductionProcessTypes.WithoutBillsOfMaterials Then

		DateOfNeedOnForm = '00010101';
		Object.DemandDateIsSpecifiedInLines = False;
		Object.DemandDate = '00010101';
		FillInDateOfVHFManufacturedProducts(Object.DemandDate);
		
		Object.ProductionScheduling = Enums.WayOfLinkingProductionOperations.Backward;
		
	EndIf;

	ItemsAndDimensionsSelectionParameters = Documents.ProductionOrder2_2.ItemsAndDimensionsSelectionParameters(Object);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	EstablishAvailabilityOfFinishedProductBeingRepaired();
	
	ConfigureDependentFormElements(ThisForm, "ProductionProcessType");
	
EndProcedure

&AtServer
Procedure CheckUpdateAccountDetails(UpdatePropsInHeader, UpdatePropsInTablePart)
	
	EmptyAssignment = Catalogs.Assignments.EmptyRef();
	
	If UpdatePropsInHeader Then
		
		If Not DestinationIsIndicatedInHeaderOfDocument(ThisForm) Then
			
			Object.AssignmentProducts = EmptyAssignment;
			
		Else
			
			References = New Array;
			References.Add(Object.AssignmentProducts);
			Templates = Catalogs.Assignments.TemplatesFromLinks(References);
			
			If Object.BusinessOperation = Enums.BusinessTransactions.TollManufacturing2_5
				Or False Then
				
				DestinationPattern = New Structure("LineOfBusiness, Partner, Contract, AssignmentTypes");
				If LinesOfBusinessServer.ThisIsLineOfActivityWithSeparationOfGoodsAndWorks(Object.LineOfBusiness) Then
					DestinationPattern.LineOfBusiness = Object.LineOfBusiness;
				EndIf;
				DestinationPattern.Contract = Object.Contract;
				DestinationPattern.Partner = Object.Partner;
				
				DestinationPattern.AssignmentTypes = New Array;
				
				If Object.BusinessOperation = Enums.BusinessTransactions.TollManufacturing2_5 Then
					DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.Giveaway2_5);
					DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.ProvidedMaterialsForStage22);
				EndIf;
				
				Template = Templates.Get(Object.AssignmentProducts);
				If Template = Undefined
					Or ValueIsFilled(DestinationPattern.LineOfBusiness)
					And DestinationPattern.LineOfBusiness <> Template.LineOfBusiness
					Or DestinationPattern.Partner <> Template.Partner
					Or DestinationPattern.Contract <> Template.Contract
					Or DestinationPattern.AssignmentTypes.Find(Template.AssignmentType) = Undefined Then
					
					Object.AssignmentProducts = EmptyAssignment;
					
				EndIf;
				
			Else
				
				PushingAssignment = LinesOfBusinessServer.PushingAssignment(Object.LineOfBusiness);
				
				If ValueIsFilled(PushingAssignment) Then
					
					Object.AssignmentProducts = PushingAssignment;
					
				Else
				
					Template = Templates.Get(Object.AssignmentProducts);
					If Template = Undefined Or Template.AssignmentType <> Enums.AssignmentTypes.Own Then
						
						Object.AssignmentProducts = EmptyAssignment;
						
					EndIf;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If UpdatePropsInTablePart Then
		
		If Not DestinationIsIndicatedInHeaderOfDocument(ThisForm) Then
			
			References = Object.ManufacturedProduct.Unload(, "Purpose").UnloadColumn("Purpose");
			Templates = Catalogs.Assignments.TemplatesFromLinks(References);
			
			If Object.BusinessOperation = Enums.BusinessTransactions.TollManufacturing2_5
				Or False Then
				
				DestinationPattern = New Structure("LineOfBusiness, Partner, Contract, AssignmentType");
				If LinesOfBusinessServer.ThisIsLineOfActivityWithSeparationOfGoodsAndWorks(Object.LineOfBusiness) Then
					DestinationPattern.LineOfBusiness = Object.LineOfBusiness;
				EndIf;
				DestinationPattern.Contract       = Object.Contract;
				DestinationPattern.Partner       = Object.Partner;
				
				If Object.BusinessOperation = Enums.BusinessTransactions.TollManufacturing2_5 Then
					DestinationPattern.AssignmentType = Enums.AssignmentTypes.Giveaway2_5;
				EndIf;
				
				For Each String In Object.ManufacturedProduct Do
					
					Template = Templates.Get(String.Purpose);
					If Template = Undefined
							Or ValueIsFilled(DestinationPattern.LineOfBusiness)
								And DestinationPattern.LineOfBusiness <> Template.LineOfBusiness
							Or DestinationPattern.Partner <> Template.Partner
							Or DestinationPattern.Contract <> Template.Contract
							Or DestinationPattern.AssignmentType <> Template.AssignmentType Then
						
						String.Purpose = EmptyAssignment;
						
					EndIf;
					
				EndDo;
				
			Else
				
				For Each String In Object.ManufacturedProduct Do
					
					Template = Templates.Get(String.Purpose);
					If Template = Undefined Or Template.AssignmentType <> Enums.AssignmentTypes.Own Then
						
						String.Purpose = EmptyAssignment;
						
					EndIf;
					
				EndDo;
				
			EndIf;
			
		Else
			
			For Each String In Object.ManufacturedProduct Do
				
				String.Purpose = EmptyAssignment;
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure CheckUpdateBankingDetailsWriteOffForExpensesInTableSection()
	
	If Object.ProductionProcessType = Enums.ProductionProcessTypes.Assembly
			And Object.BusinessOperation = Enums.BusinessTransactions.OwnProduction Then
		Return;
	EndIf;
	
	ArrayOfFoundStrings = Object.ManufacturedProduct.FindRows(New Structure("ToExpenseAs", True));
	
	If ArrayOfFoundStrings.Count() = 0 Then
		Return;
	EndIf;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array();
	
	StructureOfActions = New Structure();
	
	IncomeAndExpensesClientServer.InsertActionClearItemAndExpenseAnalytics(StructureOfActions, ThisObject, "Object.ManufacturedProduct");

	For Each String In ArrayOfFoundStrings Do
		
		String.ToExpenseAs = False;
		
		If String.ItemsType <> Enums.ItemsTypes.Work_5 Then
			String.Department = PredefinedValue("Catalog.BusinessStructure.EmptyRef");
		EndIf;
		
		RowsToProcess.Add(String);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.ManufacturedProduct,
		CachedValues);
	
EndProcedure

&AtClient
Procedure EditStages()
	
	Cancel = False;
	
	If Not Cancel
		And ValueIsFilled(Object.ProductionLot) Then
		
		ProductionManagementClient.OpenStageChainEditingForm(
			Object.Ref,
			Object.ProductionLot,,
			ThisForm);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DisplayCompletedStage()
	
	ProductionManagementClient.OpenFormForDisplayingCompletedStageFromOrder(Object, ThisForm);
	
EndProcedure

&AtClient
Procedure OpenOrderQueue(Command)
	
	ProductionManagementClient.OpenOrderQueue(, Object.Ref);
	
EndProcedure

&AtServer
Procedure EstablishAvailabilityOfFinishedProductBeingRepaired()

	// The Finished Product being Repaired
	VisibilityOfFinishedProductBeingRepaired =
		Object.ProductionProcessType = Enums.ProductionProcessTypes.PerformRM;
	
	Items.UnderRepairProduct.Visible   = VisibilityOfFinishedProductBeingRepaired;
	Items.UnderRepairVariant.Visible = VisibilityOfFinishedProductBeingRepaired;
	
	If VisibilityOfFinishedProductBeingRepaired Then
		
		If Object.UnderRepairProduct.IsEmpty() Then
			Items.UnderRepairVariant.Enabled = False;
			Items.UnderRepairVariant.InputHint = "";
		Else
			ItemVariantsAreUsed = Catalogs.Products.ItemVariantsAreUsed(Object.UnderRepairProduct);
			If ItemVariantsAreUsed Then
				Items.UnderRepairVariant.Enabled = True;
				Items.UnderRepairVariant.InputHint = "";
			Else
				Items.UnderRepairVariant.Enabled = False;
				Items.UnderRepairVariant.InputHint = NStr("vi = '<không sử dụng đặc tính>';
															|ru = '<характеристики не используются>';
															|en = '<variants are not used>'; fa = '<گونه‌ها استفاده نمی‌شوند>';
															|it = '<le caratteristiche non vengono usate>';
															|pl = '<charakterystyki nie dotyczą>';
															|tr = '<varyantlar kullanılmamaktadır>'");
			EndIf;
		EndIf;

	EndIf;
	
	ProductionClientServer.EstablishAvailabilityOfBatchesOfRepairedFinishedProduct(
		ThisObject, Object.ProductionProcessType, Object.UnderRepairBatchSpecificationStatus);
	
EndProcedure

#EndRegion

#Region MaintenanceAndProduction

&AtServer
Procedure ProductsSelectionProcessingSelectionOnServer(ValueSelected)
	
	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	
	RowsArray = New Array;
	RowsIDs = New Array;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	AddActionCheckFillInFractionOfCost(StructureOfActions, ThisObject);
	IncomeAndExpensesClientServer.InsertActionClearItemAndExpenseAnalytics(StructureOfActions, ThisObject, "Object.ManufacturedProduct");
	If Not DestinationIsIndicatedInHeaderOfDocument(ThisObject) Then
		LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	EndIf;
	
	For Each RowOfProduct In TableOfGoods Do
		CurrentRow = Object.ManufacturedProduct.Add();
		FillPropertyValues(CurrentRow, RowOfProduct, "Products,
															  |Characteristic,
															  |Package,
															  |NumberOfPackages,
															  |Warehouse");
		
		RowsArray.Add(CurrentRow);
		RowsIDs.Add(CurrentRow.GetID());
	EndDo;

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsArray,
		StructureOfActions,
		Object.ManufacturedProduct,
		CachedValues);
	
	FillInSpecificationInTablePart(RowsIDs);
	AfterChangingTSStringsProgrammaticallyOnServer(RowsArray, StructureOfActions);
	
EndProcedure

&AtServer
Procedure ProductsSelectionProcessingSelectionAccordingToGiverSOrdersOnServer(ValueSelected)
	
	TableOfGoods = Documents.ProductionOrder2_2.ProductionResiduesToProvideGiver(
		ValueSelected,
		Object.ProductionProcessType,
		ThisObject);
	
	RowsArray = New Array;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions = New Structure;

	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	AddActionCheckFillInFractionOfCost(StructureOfActions, ThisObject);
	IncomeAndExpensesClientServer.InsertActionInitializeArticleAndAnalyticsAfterAddingLine(StructureOfActions, ThisObject, "Object.ManufacturedProduct");
	
	For Each RowOfProduct In TableOfGoods Do
		CurrentRow = Object.ManufacturedProduct.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);
		RowsArray.Add(CurrentRow);
	EndDo;

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsArray,
		StructureOfActions,
		Object.ManufacturedProduct,
		CachedValues);

	AfterChangingTSStringsProgrammaticallyOnServer(RowsArray, StructureOfActions, CachedValues);
	
EndProcedure

&AtServer
Procedure AfterChangingTSStringsProgrammaticallyOnServer(RowsCollection, StructureOfPreviouslyPerformedActions = Undefined, CachedValues = Undefined)

	StructureOfActions = New Structure;
	
	If CachedValues = Undefined Then
		CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	EndIf;
	
	If StructureOfPreviouslyPerformedActions = Undefined
			Or Not StructureOfPreviouslyPerformedActions.Property("FillInFeatureAttribute") Then
		StructureOfActions.Insert("FillInFeatureAttribute",
									New Structure("Products", "ItemVariantsAreUsed"));
	EndIf;
								
	If StructureOfPreviouslyPerformedActions = Undefined 
			Or Not StructureOfPreviouslyPerformedActions.Property("FillInProductTypeAttribute_") Then
		StructureOfActions.Insert("FillInProductTypeAttribute_",
									New Structure("Products", "ItemsType"));
	EndIf;
	If StructureOfPreviouslyPerformedActions = Undefined 
			Or Not StructureOfPreviouslyPerformedActions.Property("FillInArticleAttribute") Then
		StructureOfActions.Insert("FillInArticleAttribute",
									New Structure("Products", "SKU"));
	EndIf;
	
	If RowsCollection.Count() > 0 And TypeOf(RowsCollection[0]) = Type("FormDataCollectionItem") Then
		RowsArray = RowsCollection;
	Else
		RowsArray = New Array;
		For Each CollectionItem In RowsCollection Do
			RowsArray.Add(Object.ManufacturedProduct.FindByID(CollectionItem));
		EndDo;
	EndIf;
	
	For Each String In RowsArray Do
		
		If Not UseSeveralWarehouses Then
			String.Warehouse = ?(String.ItemsType = Enums.ItemsTypes.Work_5, 
				Catalogs.Warehouses.EmptyRef(),
				DefaultWarehouse);
		EndIf;
		
		If Not Object.DemandDateIsSpecifiedInLines Then
			String.DemandDate = Object.DemandDate;
		EndIf;
		
	EndDo;

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsArray,
		StructureOfActions,
		Object.ManufacturedProduct,
		CachedValues);
		
	CalculatePercentageOfCostAllocationForOutputProducts();
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionCheckFillInFractionOfCost(StructureOfActions, Form)
	
	Object = Form.Object;
	
	If Not Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.WithoutBillsOfMaterials") Then
		Return;
	EndIf;
	
	StructureOfActions.Insert("CheckFillInCostShare", Form.CostAllocationParameters);
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInDefaultWarehouseInLine(Form, String, StructureOfActions = Undefined)
	
	If Form.UseSeveralWarehouses Then
		Return;
	EndIf;
	
	If String.ToExpenseAs
		Or String.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5") Then
		
		String.Warehouse = PredefinedValue("Catalog.Warehouses.EmptyRef");
		
	Else
		String.Warehouse = Form.DefaultWarehouse;
	EndIf;
	
EndProcedure

&AtServer
Function FindStringFromStringData(RowData)
	
	Id = -1;
	
	ThereIsBOM = RowData.Property("BillOfMaterials") And ValueIsFilled(RowData.BillOfMaterials);
	ThereIsWarehouseDepartment = RowData.Property("Warehouse") And ValueIsFilled(RowData.Warehouse)
		Or RowData.Property("Department") And ValueIsFilled(RowData.Department);
	
	For Each String In Object.ManufacturedProduct Do
		
		If String.Products = RowData.Products
			And String.Characteristic = RowData.Characteristic
			
			And String.Purpose = RowData.Purpose
			
			And (ThereIsBOM And String.BillOfMaterials = RowData.BillOfMaterials
				Or Not ThereIsBOM)
			
			And (ThereIsWarehouseDepartment 
				And (String.Warehouse = RowData.Warehouse 
					Or String.Department = RowData.Department)
				Or Not ThereIsWarehouseDepartment) Then
				
			Id = String.GetID();
			Break;
			
		EndIf;
		
	EndDo;
	
	Return Id;
	
EndFunction

&AtServer
Procedure FillInSpecificationInTablePart(Val IDs = Undefined, CheckFillMode = False)
	
	Modified = True;
	RowsArray = New Array;
	
	If IDs <> Undefined Then
		For Each Id In IDs Do
			String = Object.ManufacturedProduct.FindByID(Id);
			RowsArray.Add(String);
		EndDo;
	Else
		For Each String In Object.ManufacturedProduct Do
			RowsArray.Add(String);
		EndDo;
	EndIf;
	
	DataArray = New Array;
	
	For Each CurrentRow In RowsArray Do
		
		ProductData = ProductDataManagementClientServer.CollectProductDataForSpecificationSelection(
			Object, CurrentRow, BOMSelectionParameters);
		If CheckFillMode Then
			ProductData.Insert("CurrentSpecification", CurrentRow.BillOfMaterials);
		EndIf;
		
		DataArray.Add(ProductData);
		
	EndDo;
	
	ProductDataManagement.FillInSpecificationInLines(RowsArray, DataArray, BOMSelectionParameters);
	
EndProcedure

&AtClient
Procedure FillInRecipientCompletion(ValueSelected, AdditionalParameters) Export
	
	If Not ValueIsFilled(ValueSelected) Then
		Return;
	EndIf;
	
	TSParameters		 = AdditionalParameters.TSParameters;
	SelectedRows = Items[TSParameters.NameTSForm].SelectedRows;
	
	FillInRecipientOnServer(TSParameters, SelectedRows, ValueSelected);
	
	ShowUserNotification(
		NStr("vi = 'Đã điền kho bãi/bộ phận';
			|ru = 'Склад/подразделение заполнено';
			|en = 'Warehouse/business unit is filled in'; fa = 'Warehouse/business unit is filled in';
			|it = 'Magazzino/reparto compilato';
			|pl = 'Magazyn/dział jest wypełniony';
			|tr = 'Ambar/departman dolduruldu'"),,
		NStr("vi = 'Đối với các dòng được chọn đã điền kho bãi/bộ phận';
			|ru = 'Для выделенных строк выполнено заполнение склада/подразделения';
			|en = 'Warehouse/business unit is filled in for the selected lines'; fa = 'Warehouse/business unit is filled in for the selected lines';
			|it = 'Per le righe evidenziate è completata la compilazione del magazzino/reparto';
			|pl = 'Dla wybranych wierszy wykonano wypełnienie magazynu/działu';
			|tr = 'Belirtilen satırlar için ambar/departman dolduruldu'"),
		PictureLib.Information32);
	
EndProcedure

&AtServer
Procedure FillInRecipientOnServer(TSParameters, SelectedRows, Recipient)
	
	NameTsObject = TSParameters.NameTsObject;
	
	StructureOfActions = New Structure;
	
	If TypeOf(Recipient) = Type("CatalogRef.Warehouses") Then
		FieldName = "Warehouse";
		StructureOfActions.Insert(
			"RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	Else
		FieldName = "Department";
	EndIf;
		
	RowsToProcess = New Array();
	
	For Each RowID In SelectedRows Do
		
		RowData = Object[NameTsObject].FindByID(RowID);
		
		RowData[FieldName] = Recipient;
		RowsToProcess.Add(RowData);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object[NameTsObject]);

EndProcedure

&AtClient
Procedure FillInNeedEndDate(SelectedDate, AdditionalParameters) Export
	
	If SelectedDate <> Undefined And ValueIsFilled(SelectedDate) Then
		
		DemandDate = SelectedDate;
		ArrayOfSelectedRows = AdditionalParameters.ArrayOfSelectedRows;
		
		FillInDateOfVHFManufacturedProducts(DemandDate, ArrayOfSelectedRows);
		
		ShowUserNotification(
			NStr("vi = 'Đã điền ngày mong muốn xuất xưởng';
				|ru = 'Желаемая дата выпуска заполнена';
				|en = 'Requested release date is filled'; fa = 'Requested release date is filled';
				|it = 'Желаемая дата выпуска заполнена';
				|pl = 'Requested release date is filled';
				|tr = 'Talep edilen bitiş tarihi dolduruldu'"),,
			StrTemplate(NStr("vi = 'Đối với các dòng được chọn, đã thiết lập ngày mong muốn xuất xưởng giao hàng %1';
							|ru = 'Для выделенных строк установлена желаемая дата выпуска отгрузки %1';
							|en = 'Requested shipment release date %1 is set for the selected lines'; fa = 'Requested shipment release date %1 is set for the selected lines';
							|it = 'Для выделенных строк установлена желаемая дата выпуска отгрузки %1';
							|pl = 'Requested shipment release date %1 is set for the selected lines';
							|tr = 'Seçilen satırlar için talep edilen sevkiyat tarihi %1 olarak ayarlandı'"), Format(DemandDate, "DLF=D")),
			PictureLib.Information32);
	
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

&AtServer
Function ParametersOfCostShareEntryForm_(CurDataId)
	
	FormParameters = ProductionServer.ParametersOfCostShareEntryForm(Object, CostAllocationParameters, CurDataId);
	Return FormParameters;
	
EndFunction

&AtServer
Procedure CalculatePercentageOfCostAllocationForOutputProducts()
	
	If Not Object.ProductionProcessType = Enums.ProductionProcessTypes.WithoutBillsOfMaterials Then
		Return;
	EndIf;
	
	ProductionServer.CalculatePercentageOfCostAllocationForOutputProducts(Object, CostAllocationParameters);
	
EndProcedure

#EndRegion

#Region UniversalMechanisms

#Region Properties

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

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

// End StandardSubsystems.Properties

#EndRegion

#Region WorkingWithClipboard

&AtServer
Procedure CopyLinesOnServer()
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object.ManufacturedProduct, Items.ManufacturedProduct.SelectedRows);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboard()
	
	FilterParameters = New Map;
	FilterParameters.Insert("Products.ItemsType", AvailableProductTypes.UnloadValues());
	
	Columns = "Products,Characteristic,Package,NumberOfPackages,BillOfMaterials,Warehouse,Department,DemandDate";
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();

	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	AddActionCheckFillInFractionOfCost(StructureOfActions, ThisObject);
	IncomeAndExpensesClientServer.InsertActionInitializeArticleAndAnalyticsAfterAddingLine(StructureOfActions, ThisObject, "Object.ManufacturedProduct");
	If Not DestinationIsIndicatedInHeaderOfDocument(ThisObject) Then
		LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	EndIf;
	
	RowsArray = New Array;
	RowsIDs = New Array;
	
	For Each RowOfProduct In TableOfGoods Do
		CurrentRow = Object.ManufacturedProduct.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);
		RowsArray.Add(CurrentRow);
		RowsIDs.Add(CurrentRow.GetID());
	EndDo;

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsArray,
		StructureOfActions,
		Object.ManufacturedProduct,
		CachedValues);
	
	FillInSpecificationInTablePart(RowsIDs, True);
	AfterChangingTSStringsProgrammaticallyOnServer(RowsArray, StructureOfActions);
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfClipboardCommands()
	
	ItemArray = New Array();
	ItemArray.Add("ManufacturedProductInsertRows");
	ItemArray.Add("ManufacturedProductContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled",
		ProcessingOfTabularForms.ThereAreLinesInClipboard());
	
EndProcedure

&AtClient
Procedure SetAvailabilityOfClipboardCommandsOnClient()
	
	ItemArray = New Array();
	ItemArray.Add("ManufacturedProductInsertRows");
	ItemArray.Add("ManufacturedProductContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", True);
	
EndProcedure

#EndRegion

#EndRegion

#Region DynamicStructure

&AtClient
Procedure ControlOfCalculationOfOrderStructure()
	
	If Object.Ref.IsEmpty() Or Not Object.DynamicStructure Then
		Return;
	EndIf;
	
	Protocol = OrderStructureCalculationProtocol(Object.Ref);
	
	OrderStructureClientServer.DisplayStateOfStructureCalculation(Items, Protocol);
	
	WaitCompletion = OrderStructureClientServer.ExpectEndOfOrderStructureCalculation(Protocol.State, Protocol.StateCodes);
	
	If WaitCompletion Then
		
		IntervalForCheckingCompletionOfCalculation = ?(IntervalForCheckingCompletionOfCalculation = 0, 1, Min(IntervalForCheckingCompletionOfCalculation * IntervalIncreaseCoefficient(), MaximumIntervalForCheckingEndOfCalculation()));
		
		AttachIdleHandler("ControlOfCalculationOfOrderStructure", IntervalForCheckingCompletionOfCalculation, True);
		Return;
		
	EndIf;
	
	FillInCurrentOrderState();

	IntervalForCheckingCompletionOfCalculation = 0;
	
	ConfigureDependentFormElements(ThisForm, "ProductionSchedule");
	
EndProcedure

&AtClient
Function IntervalIncreaseCoefficient()
	
	Return 1.4;
	
EndFunction

&AtClient
Function MaximumIntervalForCheckingEndOfCalculation()
	
	Return 15;
	
EndFunction

&AtServerNoContext
Function OrderStructureCalculationProtocol(Ref)
	
	Return Documents.ProductionOrder2_2.OrderStructureCalculationProtocol(Ref);
	
EndFunction

&AtClient
Procedure RunFullCalculationOfOrderStructure()
	
	OrderStructureClient.StartRecalculatingOrderStructure(Object.Ref);
	AttachIdleHandler("ControlOfCalculationOfOrderStructure", 0.1, True);
	
EndProcedure

#EndRegion

#Region SetOfSeries

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
	
	StatusOfSpecifyingSeriesBeforeChange = Object.UnderRepairBatchSpecificationStatus;
	
	If DataStructureOfFinishedProductBeingRepaired = Undefined Then
		DataStructureOfFinishedProductBeingRepaired = ProductionManagementClientServer.DataOfFinishedProductBeingRepairedByStructure(Object);
	EndIf;
	
	ProductsServer.FillInStatusesOfSpecifyingSeriesWhenChangingProductInHeader(
		DataStructureOfFinishedProductBeingRepaired, SeriesSpecificationParameters.FinishedProductBeingRepaired, CachedValues);
	
	Object.UnderRepairBatch = DataStructureOfFinishedProductBeingRepaired.Series;
	Object.UnderRepairBatchSpecificationStatus = DataStructureOfFinishedProductBeingRepaired.BatchesIndicationStatus;
	
	If StatusOfSpecifyingSeriesBeforeChange <> Object.UnderRepairBatchSpecificationStatus Then
		
		ProductionClientServer.EstablishAvailabilityOfBatchesOfRepairedFinishedProduct(
			ThisObject, Object.ProductionProcessType, Object.UnderRepairBatchSpecificationStatus);
		
	EndIf;

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

#Region Other

&AtServer
Procedure OnReadCreateAtServer()
	
	ProcessingOfTabularForms.InitializeRowCache(Items.ManufacturedProduct);
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.ProductionOrder2_2));

	FillInServiceDetails();
	
	UpdateOrderForActivity(False);
	
	ItemsAndDimensionsSelectionParameters = Documents.ProductionOrder2_2.ItemsAndDimensionsSelectionParameters(Object);
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);

	EstablishAvailabilityOfFinishedProductBeingRepaired();

	CustomizeFormElements();
	
EndProcedure

&AtServer
Procedure FillInServiceDetails()
	
	SubsystemSettingsProduction = ProductionServer.SubsystemSettingsProduction();
	FillPropertyValues(ThisForm, SubsystemSettingsProduction);
	
	ItemVariantsAreUsed = GetFunctionalOption("UseItemVariants");
	UseSeveralWarehouses = GetFunctionalOption("UseSeveralWarehouses");
	UseTollManufacturing2_5 =
		GetFunctionalOption("UseTollManufacturing2_5");
	HasEditPermission = AccessRight("Update", Metadata.Documents.ProductionOrder2_2);
	ThereIsRightToCalculateSchedule = AccessRight("Use", Metadata.DataProcessors.ProductionSchedulePlanning2_2);
	
	LinesOfBusinessServer.OnReadCreateAtServer(ThisObject);
	
	HyperlinkColors = New Structure;
	HyperlinkColors.Insert("Gray", WebColors.Gray);
	HyperlinkColors.Insert("Red", WebColors.Red);
	HyperlinkColors.Insert("B", StyleColors.HyperlinkColor);

	TypeOfProductionProcessIsAvailable = ProductDataManagement.DescriptionOfManufacturingProcessTypeIsAvailable();
	If TypeOfProductionProcessIsAvailable Then
		ProductionServer.FillInListOfProductionProcessTypes(Items.ProductionProcessType,, Object.DynamicStructure);
	EndIf;
	
	AvailableProductTypes.LoadValues(ProductDataManagementClientServer.TypesOfItemsByTypeOfProductionProcess(Object.ProductionProcessType));
	BOMSelectionParameters = ProductDataManagement.BOMSelectionParameters(Object, Documents.ProductionOrder2_2);
	ProductDataManagement.SetSpecificationSelectionParameters(Items.ManufacturedProductBillOfMaterials, BOMSelectionParameters);
	
	CostAllocationParameters = New FixedStructure(Documents.ProductionOrder2_2.CostAllocationParameters(Object));
	
	TypeOfProductionProcessBeforeTheChange = Object.ProductionProcessType;
	CurSeparationOption = ProductionManagement.OptionOfMaterialAssignmentInProduction();
	FillInCurrentOrderState();
	
	FillInServiceDetailsForProductRange();
	FillDefaultWarehouse();
	
	SetRequiredDateAttribute(ThisForm);
	
	CalculatePercentageOfCostAllocationForOutputProducts();
	
EndProcedure

&AtServer
Procedure FillInCurrentOrderState()
	
	CurrentOrderState = New Structure("Transferred_To_Production,StatusScheduleNeedsToBeCalculated",False,Enums.ProductionScheduleStatusesInProductionOrder.EmptyRef());
	
	If Not Object.Ref.IsEmpty() Then
		
		Query = New Query(
			"SELECT
			|	Table.Status IN (VALUE(Enum.ProductionOrderStatuses2_2.ToProduce), VALUE(Enum.ProductionOrderStatuses2_2.Closed)) AS Transferred_To_Production,
			|	CASE
			|		WHEN &TheProductionScheduleIsPlanned
			|				AND TRUE IN
			|					(SELECT TOP 1
			|						TRUE
			|					FROM
			|						InformationRegister.OrderStructureCalculationJobsProductionSchedule AS DD
			|					WHERE
			|						DD.ProductionOrder = Table.Ref)
			|			THEN VALUE(Enum.ProductionScheduleStatusesInProductionOrder.RequiredToCalculate)
			|		ELSE VALUE(Enum.ProductionScheduleStatusesInProductionOrder.EmptyRef)
			|	END AS StatusScheduleNeedsToBeCalculated
			|FROM
			|	Document.ProductionOrder2_2 AS Table
			|WHERE
			|	Table.Ref = &Ref
			|	AND Table.Posted");
		Query.SetParameter("Ref", Object.Ref);
		Query.SetParameter("TheProductionScheduleIsPlanned", TheProductionScheduleIsPlanned);
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			FillPropertyValues(CurrentOrderState, Selection);
		EndIf;
		
	EndIf;
	
	FillPropertyValues(ThisObject, CurrentOrderState);
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsForProductRange()

	StructureOfActions = New Structure;

	StructureOfActions.Insert("FillInFeatureAttribute",
								New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_",
								New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute",
								New Structure("Products", "SKU"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.ManufacturedProduct, StructureOfActions);
	
EndProcedure

&AtServer
Procedure FillDefaultWarehouse()
	
	If UseSeveralWarehouses Then
		DefaultWarehouse = Catalogs.Warehouses.EmptyRef();
	Else
		DefaultWarehouse = TMCommonUse.GetCheckWarehouseByDefault();
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtClient
Procedure OpenOrderStructure()
	
	ReportForm = ?(Object.DynamicStructure,
		"Report.ProductionOrderStructureDynamic.Form.ReportForm",
		"Report.ProductionOrderStructure2_2.Form.OrderStructure");
	
	OpenForm(
		ReportForm,
		New Structure("OrderDocument", Object.Ref),
		,
		Object.Ref);
	
EndProcedure

&AtClient
Procedure OpenSchedulePlanning()
	
	ParametersStructure = New Structure("ReferenceOrder", Object.Ref);
	OpenForm("DataProcessor.ProductionSchedulePlanning2_2.Form.CreatingProductionOrderSchedule", ParametersStructure,, Object.Ref);
	
EndProcedure

&AtServerNoContext
Function ObjectAttributeValue(Object, AttributeName)
	
	Return Common.ObjectAttributeValue(Object, AttributeName);
	
EndFunction

&AtClientAtServerNoContext
Function DestinationIsIndicatedInHeaderOfDocument(Form)
	
	If Form.Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.Disassembly") Then
		Return True;
	EndIf;
	
	If Form.Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.WithoutBillsOfMaterials") Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

&AtClientAtServerNoContext
Procedure SetRequiredDateAttribute(Form)
	
	Object = Form.Object;
	
	Form.DemandDateRequired_ = Object.DynamicStructure And Not Form.TheProductionScheduleIsPlanned
		Or Not Object.DynamicStructure And Object.ProductionScheduling = PredefinedValue("Enum.WayOfLinkingProductionOperations.ToFinish");
	
EndProcedure

&AtClient
Function ListOfBlockedItemAttributes()
	
	FormPrepared = TMCommonUseClientServer.HasObjectAttribute(ThisObject, "AttributeEditProhibitionParameters");
	
	If FormPrepared Then
		
		LockedAttributes = ObjectAttributesLockClient.Attributes(ThisObject);
		
	Else
		
		LockedAttributes = New Array();
		
	EndIf;
	
	Return LockedAttributes
	
EndFunction

&AtServer
Procedure FillInDateOfVHFManufacturedProducts(Val NewDate, Val SelectedRows = Undefined)

	ProductionServer.FillInDetailsInCollection(Object.ManufacturedProduct, "DemandDate", NewDate, SelectedRows);
	
EndProcedure

&AtServerNoContext
Function MinimumNeedDate(Val TabularSection)
	
	Dates = TabularSection.Unload(New Structure("Canceled", False), "DemandDate");
	Dates.Sort("DemandDate");
	If Dates.Count() > 0 Then
		Return Dates[0].DemandDate;
	Else
		Return '00010101';
	EndIf;
	
EndFunction

&AtServer
Procedure CheckReportResultOfControl(WriteParameters)
	
	If WriteParameters.WriteMode = DocumentWriteMode.UndoPosting
	 Or WriteParameters.WriteMode = DocumentWriteMode.Posting Then
	
		PerformControlOfPlannedStages(WriteParameters.WriteMode = DocumentWriteMode.UndoPosting);
	
	EndIf;
	
EndProcedure

&AtServer
Procedure PerformControlOfPlannedStages(RemovalOfBody = False)
	
	QueryText = "";
	
	If Object.Status = Enums.ProductionOrderStatuses2_2.BeingGenerated
	 Or RemovalOfBody Then
	
		QueryText =
		"SELECT TOP 1
		|	TRUE
		|FROM
		|	Document.ProductionStage2_2 AS Table
		|WHERE
		|	Table.ReferenceOrder = &Ref
		|	AND Table.Posted";
		
	ElsIf Object.Status = Enums.ProductionOrderStatuses2_2.Closed 
			And Not RemovalOfBody Then
		
		QueryText =
		"SELECT TOP 1
		|	TRUE
		|FROM
		|	InformationRegister.ProductionStageStates AS ProductionStageStates
		|WHERE
		|	ProductionStageStates.ReferenceOrder = &Ref
		|	AND ProductionStageStates.StateAtIntershopLevel IN (
		|		VALUE(Enum.StateOfProductionStagesAtIntershopLevel.RequiresClarification),
		|		VALUE(Enum.StateOfProductionStagesAtIntershopLevel.ReadyForFulfillment),
		|		VALUE(Enum.StateOfProductionStagesAtIntershopLevel.PendingPredecessors),
		|		VALUE(Enum.StateOfProductionStagesAtIntershopLevel.PendingStart),
		|		VALUE(Enum.StateOfProductionStagesAtIntershopLevel.PendingCompletion))";
	
	EndIf;
	
	If Not IsBlankString(QueryText) Then
	
		Query = New Query(QueryText);
		Query.SetParameter("Ref", Object.Ref);
			
		QueryResult = Query.Execute();
		
		If Not QueryResult.IsEmpty() Then
			
			If RemovalOfBody Then
				ErrorText = NStr("vi = 'Đã hủy kết chuyển đơn hàng sản xuất';
								|ru = 'Выполнена отмена проведения заказа на производство';
								|en = 'The production order posting is canceled'; fa = 'The production order posting is canceled';
								|it = 'The production order posting is canceled';
								|pl = 'The production order posting is canceled';
								|tr = 'Üretim emrinin onayı iptal edildi'");
			Else
				ErrorText = NStr("vi = 'Đã kết chuyển đơn hàng sản xuất';
								|ru = 'Выполнено проведение заказа на производство';
								|en = 'The production order is posted'; fa = 'The production order is posted';
								|it = 'The production order is posted';
								|pl = 'The production order is posted';
								|tr = 'Üretim emri onaylandı'");
			EndIf;
			
			ErrorText = ErrorText + NStr("vi = ', tuy nhiên, theo đơn hàng vẫn còn các công đoạn.';
										|ru = ', но по заказу остались этапы.';
										|en = 'but there are stages left under the order.'; fa = 'but there are stages left under the order.';
										|it = 'but there are stages left under the order.';
										|pl = 'but there are stages left under the order.';
										|tr = ', ancak siparişe ait aşamalar kaldı.'");
			
			Common.MessageToUser(ErrorText);
			
		EndIf;
	
	EndIf;
	
EndProcedure

#EndRegion

#Region ImportDataFromFile

&AtClient
Function AdditionalParametersForDownloadingFromFile()
	
	AdditionalParameters = New Structure;
	
	SpecificationsAreUsed = Not Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.WithoutBillsOfMaterials");
	AdditionalParameters.Insert("SpecificationsAreUsed", SpecificationsAreUsed);
	
	AdditionalParameters.Insert("AssignmentsAreUsed", Not DestinationIsIndicatedInHeaderOfDocument(ThisObject));
	
	AdditionalParameters.Insert("DateOfNeedIsUsed", Object.DemandDateIsSpecifiedInLines);
	
	AvailableProductTypes = New Array;
	AvailableProductTypes.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
	If Not Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.Disassembly") Then
		AvailableProductTypes.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
		AvailableProductTypes.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
	EndIf;
	AdditionalParameters.Insert("AvailableProductTypes", AvailableProductTypes);
	
	Return AdditionalParameters;
	
EndFunction

&AtClient
Procedure ShowUploadFormFromFile(AdditionalParameters)
	
	ImportParameters = ImportDataFromFileClient.DataImportParameters();
	ImportParameters.FullTabularSectionName = "ProductionOrder2_2.ManufacturedProduct";
	ImportParameters.Title = NStr("vi = 'Kết nhập bảng ""Thành phẩm"" từ tệp';
									|ru = 'Загрузка таблицы ""Продукция"" из файла';
									|en = 'Import the Manufactured products table from the file'; fa = 'Import the Manufactured products table from the file';
									|it = 'Scaricamento della tabella ""Prodotti"" dal file';
									|pl = 'Wczytywanie tabeli ""Produkcja"" z pliku';
									|tr = 'Dosyadan ""İmal edilen ürünler"" tablosunun indirilmesi'");
	ImportParameters.AdditionalParameters = AdditionalParameters;
	
	ImportParameters.TemplateColumns = DescriptionOfTemplateColumnsForLoadingProducts(AdditionalParameters);
	
	Notification = New CallbackDescription("ShowUploadFormFromFileCompletion", ThisObject, AdditionalParameters);
	ImportDataFromFileClient.ShowImportForm(ImportParameters, Notification);
	
EndProcedure

&AtServerNoContext
// Creates an array of columns of the data loading Template
// Parameters:
//	Additional parameters - Structure - regulates the visibility of the columns:
//                         * Use of the assignment - Boolean
//                         * Specializations are used - Boolean
//                         * Uses the needs - Boolean 
// 
// Returns:
//  Array of Structure - Description Of The Template Columns For Loading Products
Function DescriptionOfTemplateColumnsForLoadingProducts(AdditionalParameters) Export
	
	TemplateColumns = New Array;
	
	AddDataLoadingColumn(TemplateColumns, "Barcode", Common.StringTypeDetails(200), NStr("vi = 'Mã vạch';
																						|ru = 'Штрихкод';
																						|en = 'Barcode'; fa = 'بارکد';
																						|it = 'Codice a barre';
																						|pl = 'Kod kreskowy';
																						|tr = 'Barkod'"), 10, "Products");
	AddDataLoadingColumn(TemplateColumns, "SKU", Catalogs.Products.EmptyRef().Metadata().Attributes["SKU"].Type, NStr("vi = 'Mã hiệu';
																														|ru = 'Артикул';
																														|en = 'Item ID'; fa = 'شناسه قلم';
																														|it = 'Articolo';
																														|pl = 'Artykuł';
																														|tr = 'Ürün kodu'"), 10, "Products");
	CodeLength = Catalogs.Products.EmptyRef().Metadata().CodeLength;
	AddDataLoadingColumn(TemplateColumns, "ProductsAndServicesCode", Common.StringTypeDetails(CodeLength), NStr("vi = 'Mã hàng';
																												|ru = 'Код номенклатуры';
																												|en = 'Items code'; fa = 'کد اقلام';
																												|it = 'Codice dell''elenco articoli';
																												|pl = 'Kod towaru';
																												|tr = 'Öğe kodu'"), 15, "Products");
	AddDataLoadingColumn(TemplateColumns, "Products", TypeOfDirectoryName("Products"), NStr("vi = 'Mặt hàng';
																							|ru = 'Номенклатура';
																							|en = 'Items'; fa = 'اقلام';
																							|it = 'Articolo';
																							|pl = 'Pozycja';
																							|tr = 'Öğe'"), 15, "Products");
	AddDataLoadingColumn(TemplateColumns, "Characteristic", TypeOfDirectoryName("ItemsCharacteristics"), NStr("vi = 'Đặc tính';
																												|ru = 'Характеристика';
																												|en = 'Variant'; fa = 'گونه';
																												|it = 'Caratteristica';
																												|pl = 'Charakterystyka';
																												|tr = 'Varyant'"), 15);
	If AdditionalParameters.AssignmentsAreUsed Then
		AddDataLoadingColumn(TemplateColumns, "Purpose", TypeOfDirectoryName("Assignments"), NStr("vi = 'Mục đích';
																									|ru = 'Назначение';
																									|en = 'Assignment'; fa = 'تخصیص';
																									|it = 'Assegnazione';
																									|pl = 'Przeznaczenie';
																									|tr = 'Atama'"), 15);
	EndIf;
	CodeLength = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef().Metadata().CodeLength;
	AddDataLoadingColumn(TemplateColumns, "PackageCode", Common.StringTypeDetails(CodeLength), NStr("vi = 'Mã đóng gói';
																									|ru = 'Код упаковки';
																									|en = 'Packaging unit code'; fa = 'کد واحد بسته‌بندی';
																									|it = 'Codice di imballaggio';
																									|pl = 'Kod opakowania';
																									|tr = 'Paketleme ünitesi kodu'"), 12);
	AddDataLoadingColumn(TemplateColumns, "Package", TypeOfDirectoryName("PackagesAndUnitsOfMeasure"), NStr("vi = 'Đóng gói';
																											|ru = 'Упаковка';
																											|en = 'Packaging unit'; fa = 'واحد بسته‌بندی';
																											|it = 'Упаковка';
																											|pl = 'Opakowanie';
																											|tr = 'Paketleme ünitesi'"), 10);
	AddDataLoadingColumn(TemplateColumns, "Count", Common.TypeDescriptionNumber(10, 2), NStr("vi = 'Số lượng';
																							|ru = 'Количество';
																							|en = 'Quantity'; fa = 'مقدار';
																							|it = 'Количество';
																							|pl = 'Ilość';
																							|tr = 'Miktar'"), 10);
	If AdditionalParameters.SpecificationsAreUsed Then
		AddDataLoadingColumn(TemplateColumns, "BillOfMaterials", TypeOfDirectoryName("BillsOfMaterials"), NStr("vi = 'Bảng kê chi tiết';
																												|ru = 'Спецификация';
																												|en = 'Bill of materials'; fa = 'فهرست مواد (BOM)';
																												|it = 'Bill of materials';
																												|pl = 'Bill of materials';
																												|tr = 'Ürün reçetesi'"), 15);
	EndIf;
	AddDataLoadingColumn(TemplateColumns, "Recipient", TypeOfDirectoryName("BusinessStructure"), NStr("vi = 'Người nhận';
																										|ru = 'Получатель';
																										|en = 'Recipient'; fa = 'گیرنده';
																										|it = 'Recipient';
																										|pl = 'Recipient';
																										|tr = 'Alıcı'"), 15);
	If AdditionalParameters.DateOfNeedIsUsed Then
		AddDataLoadingColumn(TemplateColumns, "DemandDate", New TypeDescription("Date",, New DateQualifiers()), NStr("vi = 'Ngày xuất xưởng mong muốn';
																													|ru = 'Желаемая дата выпуска';
																													|en = 'Requested release date'; fa = 'تاریخ درخواستی تولید';
																													|it = 'Data preferibile di produzione';
																													|pl = 'Planowana data zakończenia';
																													|tr = 'Talep edilen bitiş tarihi'"), 15);
	EndIf;
	AddDataLoadingColumn(TemplateColumns, "Comment", Common.StringTypeDetails(0), NStr("vi = 'Ghi chú';
																						|ru = 'Комментарий';
																						|en = 'Comment'; fa = 'توضیحات';
																						|it = 'Comment';
																						|pl = 'Comment';
																						|tr = 'Yorum'"), 20);
	
	Return TemplateColumns;
	
EndFunction

&AtServerNoContext
Function TypeOfDirectoryName(CatalogName)
	DescriptionLength = Catalogs[CatalogName].EmptyRef().Metadata().DescriptionLength;
	Return New TypeDescription("String",, New StringQualifiers(DescriptionLength));
EndFunction

&AtServerNoContext
Procedure AddDataLoadingColumn(TemplateColumns, Description, ColumnType, Synonym, ColumnWidth, Parent = "")
	Column = ImportDataFromFileClientServer.TemplateColumnDetails(Description, ColumnType, Synonym, ColumnWidth);
	Column.Position = TemplateColumns.UBound() + 1;
	If ValueIsFilled(Parent) Then
		Column.Parent = Parent;
	EndIf;
	TemplateColumns.Add(Column);
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
	UploadDataAddGoods(ImportedData, CachedValues);
	
EndProcedure

&AtServer
Procedure UploadDataAddGoods(TableOfGoods, CachedValues = Undefined)
	
	Modified = True;
	
	StructureOfActions   = New Structure;
	RowsIDs = New Array;
	
	StructureOfActions.Insert("RecalculateNumberOfUnits", New Structure("MustBeRoundOff", False));
	
	CachedValuesStringProcessing = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array();
	
	For Each RowOfProduct In TableOfGoods Do
	
		CurrentRow = Object.ManufacturedProduct.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);

		RowsToProcess.Add(CurrentRow);
		
		RowsIDs.Add(CurrentRow.GetID());
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.ManufacturedProduct,
		CachedValuesStringProcessing);
	
	FillInServiceDetails();
	
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
	ElsIf Item.Name = "sh_ShamsiInput_EarliestStartDate" Then
		EarliestStartDateOnChange(Items.EarliestStartDate);
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
