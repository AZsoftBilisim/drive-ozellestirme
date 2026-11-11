#Region Variables

&AtClient
Var CachedValues;

&AtClient
Var CurDataId;

&AtClient
Var SeriesIsEditedInHeader; //used to determine that the series selection form is called for the series specified in the header

&AtClient
Var ParametersForRecording Export;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisForm);
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
		
		SetSeriesAvailabilityInHeader();
	ElsIf Parameters.FillingValues.Property("FillByWarehouseDocument") Then
		
		RefillByNotes(Parameters.FillingValues.AnArrayOfOrders);
		Modified = True;
		
	EndIf;
	SetConditionalAppearance();
	
	Items.CloseOrder.Enabled = AccessRight("Update",Metadata.Documents.ByAssemblyDisassemblyOrder);
	
	SetAvailabilityOfClipboardCommands();
	
	DocumentCorrection.OnCreateAtServer(ThisForm, Items.LineCorrection);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	OnReadCreateAtServer();
	
	DocumentCorrection.OnReadAtServer(ThisForm, Items.LineCorrection);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands

	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	FillInServiceDetailsForProductRange();
	

	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);

	LinesOfBusinessServer.AfterWriteAtServer(ThisObject);
	
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	
EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)
	
	FormEventsClient.URLProcessing(ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	ProductsClient.UpdateCachedHeaderValuesToAccountForSeries(Object,CachedValues,SeriesSpecificationParameters.Header);
	ProductsClient.UpdateCachedValuesToAccountForSeries(Items.Goods,CachedValues,SeriesSpecificationParameters.TS);
	ReportResults();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties

EndProcedure

&AtClient
Procedure OnClose()

	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);

EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)

	Var CurrentOperation1;
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.AssemblyFromComponents.DocumentForm.Event.ChoiceProcessing");
	
	If TypeOf(ValueSelected) = Type("Structure") And ValueSelected.Property("CurrentOperation1", CurrentOperation1) Then

		If Upper(CurrentOperation1) = Upper("AddItemsFromSalesOrderGoodsIssue") Then

			ProcessingProductSelectionFromOrder(ValueSelected.AddressInStorage);

		EndIf;

	ElsIf ChoiceSource.FormName = "DataProcessor.SelectGoodsToSalesDocument.Form.Form" Then

		ProcessingSelectionOfSelectionOnServer(ValueSelected);
		
	ElsIf ChoiceSource.FormName = "Catalog.InventoryKinds.Form.InventoryOwnerAttributesForm" Then	
		
		GetStockTypesFromStorage(ValueSelected);
		
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		If SeriesIsEditedInHeader Then
			ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters.Header, ValueSelected);
			ProductsClient.UpdateCachedHeaderValuesToAccountForSeries(Object,CachedValues,SeriesSpecificationParameters.Header);
		Else
			ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters.TS, ValueSelected);
		EndIf;
		
	EndIf;

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
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
	
	If EventName = "CopyingLinesToClipboard" Then
		
		SetAvailabilityOfClipboardCommandsOnClient();
		
	EndIf;
	
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	DocumentCorrectionClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	NotifyAboutDocument(WriteParameters);
	
	DocumentCorrectionClient.AfterWrite(Object);
	

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisForm, Object, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);

	If NotExecuteCheck1BeforeWrite Then
		NotExecuteCheck1BeforeWrite = False;
		Return;
	EndIf;
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters, Cancel);
	
EndProcedure

&AtClient
Procedure BeforeRecordingProcessRecordingOfObjectInForm(Result, AdditionalParameters) Export
	
	If Result <> DialogReturnCode.No Then
		
		TMCommonUseClient.ProcessObjectEntryInForm(ThisForm, AdditionalParameters.WriteParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	ForceCloseTheForm = True;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure StatusOnChange(Item)

	PrepareFillSetSeriesVisibility();
	ProductsClient.UpdateCachedHeaderValuesToAccountForSeries(Object,CachedValues,SeriesSpecificationParameters.Header);
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);

EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	WarehouseHasChanged = Warehouse <> Object.Warehouse;
	WarehouseOnChangeServer(True);
	If WarehouseHasChanged Then
		
		ProductsClient.UpdateCachedHeaderValuesToAccountForSeries(Object,CachedValues,SeriesSpecificationParameters.Header);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.AssemblyFromComponents") Then
		OperationBeforeChange = PredefinedValue("Enum.BusinessTransactions.DisassemblyIntoComponents");
	Else
		OperationBeforeChange = PredefinedValue("Enum.BusinessTransactions.AssemblyFromComponents");
	EndIf;
	
	BusinessOperationOnChangeServer();
	ProductsClient.UpdateCachedHeaderValuesToAccountForSeries(Object,CachedValues,SeriesSpecificationParameters.Header);

EndProcedure

&AtClient
Procedure BatchesIndicationStatusClick(Item, StandardProcessing)

	CurDataId = Items.Goods.CurrentData.GetID();
	ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm(CurDataId, True);
	
	ReturnValue_1 = Undefined;

	
	OpenForm(ParametersOfSeriesIndicationForm.FormName,ParametersOfSeriesIndicationForm,ThisForm,,,, New CallbackDescription("BatchesIndicationStatusClickCompletion", ThisObject, New Structure("ParametersOfSeriesIndicationForm", ParametersOfSeriesIndicationForm)), FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure BatchesIndicationStatusClickCompletion(Result, AdditionalParameters) Export
    
    ParametersOfSeriesIndicationForm = AdditionalParameters.ParametersOfSeriesIndicationForm;
    
    
    ReturnValue_1 = Result;
    
    If ReturnValue_1 <> Undefined Then
        ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm, True);
    EndIf;

EndProcedure

&AtClient
Procedure PackageOnChange(Item)

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");

	BatchProcessingOfTablePartClient.ProcessTSString(Object, StructureOfActions, CachedValues);
	
	If ProductsClient.YouNeedToUpdateStatusOfSeriesInHeader(Object,CachedValues,SeriesSpecificationParameters.Header) Then
		FillInStatusesOfSpecifyingSeriesWhenChangingProductInHeader(CachedValues);
		ProductsClient.UpdateCachedHeaderValuesToAccountForSeries(Object,CachedValues,SeriesSpecificationParameters.Header);
	EndIf;

EndProcedure

&AtClient
Procedure NumberOfPackagesOnChange(Item)

	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(Object, StructureOfActions, CachedValues);
	
	If ProductsClient.YouNeedToUpdateStatusOfSeriesInHeader(Object,CachedValues,SeriesSpecificationParameters.Header) Then
		FillInStatusesOfSpecifyingSeriesWhenChangingProductInHeader(CachedValues);
		ProductsClient.UpdateCachedHeaderValuesToAccountForSeries(Object,CachedValues,SeriesSpecificationParameters.Header);
	EndIf;

EndProcedure

&AtClient
Procedure ProductsOnChange(Item)

	ProductsOnChangeServer(CachedValues);
	ProductsClient.UpdateCachedHeaderValuesToAccountForSeries(Object,CachedValues,SeriesSpecificationParameters.Header);

EndProcedure

&AtClient
Procedure CharacteristicOnChange(Item)

	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCompleteConfigurationOptionByOwner", Object.ProductKit);

	StringStructure = New Structure;
	StringStructure.Insert("Products",               Object.Products);
	StringStructure.Insert("Characteristic",             Object.Characteristic);
	StringStructure.Insert("ProductKit",        Object.ProductKit);
	StringStructure.Insert("ItemVariantsAreUsed", True);
	
	StructureOfActions.Insert("CheckFillAssignment");
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Object"));

	BatchProcessingOfTablePartClient.ProcessTSString(StringStructure, StructureOfActions, CachedValues);

	FillPropertyValues(Object, StringStructure, "ProductKit");
	If ProductsClient.YouNeedToUpdateStatusOfSeriesInHeader(Object,CachedValues,SeriesSpecificationParameters.Header) Then
		FillInStatusesOfSpecifyingSeriesWhenChangingProductInHeader(CachedValues);
		ProductsClient.UpdateCachedHeaderValuesToAccountForSeries(Object,CachedValues,SeriesSpecificationParameters.Header);
	EndIf;

EndProcedure

&AtClient
Procedure WithAssignmentOnChange(Item)
	
	SeparateWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	DateOnChangeServer();
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	
EndProcedure

&AtClient
Procedure SeriesStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	OpenSelectionOfSeries(True,Item.EditText);
EndProcedure

&AtClient
Procedure SeriesOnChange(Item)
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value            		 = Object.Series;
	
	ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters.Header, ValueSelected);
	ProductsClient.UpdateCachedHeaderValuesToAccountForSeries(Object,CachedValues,SeriesSpecificationParameters.Header);
EndProcedure

&AtClient
Procedure ProductKitOnChange(Item)
	ConfigureMainComponent();
EndProcedure

&AtClient
Procedure ComponentPresentationClick(Item, StandardProcessing)
	StandardProcessing = False;
	ShowValue(Undefined, Object.ProductsOfMainComponent);
EndProcedure

&AtClient
Procedure LineOfBusinessOnChange(Item)
	
	DirectionOfActivityWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure AssemblyForActivityClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(
		ThisObject, FormattedStringURL, StandardProcessing);
EndProcedure

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	// StandardSubsystems.Properties
	If ThisObject.PropertiesParameters.Property(CurrentPage.Name)
			And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
EndProcedure

&AtClient
Procedure SubjectToExciseOnChange(Item)
	Items.BusinessUnitProduction.ReadOnly = Not Object.SubjectToExcise;
	If Not Object.SubjectToExcise Then
		Object.BusinessUnitProduction = Undefined;
	EndIf;
	Return; // Not used in TM
EndProcedure

&AtClient
Procedure DateOfReceiptOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOfReceiptOnChangeServer();
	
EndProcedure

&AtClient
Procedure ToControlQualityOnChange(Item)
	
	If Not Object.ToControlQuality Then
		Object.QualityConfirmationDate = '00010101';
	EndIf;
	ToControlQualityOnChangeServer();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsProductsOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;
	
	Actions = New Structure;
	Actions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	Actions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	Actions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	Actions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	Actions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	Actions.Insert("RecalculateNumberOfUnits");
	Actions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters.TS));
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisForm, Actions);
	Actions.Insert("FillInCheckQualityDateOfQualityConfirmation",
		QualityControlClientServer.CacheByKey(CacheQualityControl, "Goods"));
	
	Actions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, Actions, CachedValues);

EndProcedure

&AtClient
Procedure GoodsWithAssignmentOnChange(Item)
	
	LinesOfBusinessClient.GoodsWithAssignmentOnChange(ThisObject, Items.Goods.CurrentData);	
	
EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
		
	WhenChangingPackaging(CurrentRow);

EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;
		
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure GoodsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	If ValueIsFilled(Object.ByAssemblyDisassemblyOrder) Then
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	If Copy
		And Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.DisassemblyIntoComponents") Then
		RecalculatePercentageShareOfValue();
	EndIf;
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters.TS, Copy);
	
EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	UpdateSeriesStatuses = ProductsClient.SeriesStatusesNeedToBeUpdated(
		Item, CachedValues, SeriesSpecificationParameters.TS);
	RecalculatePercentageShareOfValue = ValueIsFilled(Object.Goods)
		And Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.DisassemblyIntoComponents");
	
	If UpdateSeriesStatuses Or RecalculatePercentageShareOfValue Then
		
		ProductsAfterEditingOnServer(UpdateSeriesStatuses, RecalculatePercentageShareOfValue,
			Items.Goods.CurrentData.GetID(), CachedValues);
		ProductsClient.UpdateCachedValuesToAccountForSeries(Item,CachedValues,SeriesSpecificationParameters.TS);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)
		
	Component = Item.CurrentData;
	If Component <> Undefined Then
		FillInMainComponent(Component.Products, Component.Characteristic, Component.TheRecordsAreKeptByCCD, True);
	EndIf;

	ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters.TS);
EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	
	UpdateSeriesStatuses = ProductsClient.SeriesStatusesNeedToBeUpdated(
		Item, CachedValues, SeriesSpecificationParameters.TS, True);
	RecalculatePercentageShareOfValue = ValueIsFilled(Object.Goods)
		And Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.DisassemblyIntoComponents");
	
	If UpdateSeriesStatuses Or RecalculatePercentageShareOfValue Then
		
		ProductsAfterEditingOnServer(UpdateSeriesStatuses, RecalculatePercentageShareOfValue,
			Undefined, CachedValues);
		ProductsClient.UpdateCachedValuesToAccountForSeries(Item,CachedValues,SeriesSpecificationParameters.TS);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	OpenSelectionOfSeries(False, Item.EditText);
EndProcedure

&AtClient
Procedure GoodsSeriesOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value            		 = CurrentRow.Series;
	ValueSelected.CurrentRowID = CurrentRow.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters.TS, ValueSelected);
EndProcedure

&AtClient
Procedure GoodsToControlQualityOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	If Not CurrentData.ToControlQuality Then
		CurrentData.QualityConfirmationDate = '00010101';
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsQualityConfirmationDateOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	If Not CurrentData.ToControlQuality Then
		CurrentData.QualityConfirmationDate = '00010101';
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetTheMarkApart(Command)
	
	SetUncheckSeparately(True);
	
EndProcedure

&AtClient
Procedure UncheckTheSeparateBox(Command)
	
	SetUncheckSeparately(False);
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure


&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure


&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm, True);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm, True);
	
EndProcedure

&AtClient
Procedure OpenInventoryKinds(Command)
	
	OptionsForEditingInventoryTypes = PutGoodsAndStockTypesInStorage();
	
	FinancesClient.OpenInventoryKinds(ThisObject, OptionsForEditingInventoryTypes);
	
EndProcedure

&AtClient
Procedure SelectGoods(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.AssemblyFromComponents.DocumentForm.Command.SelectGoods");
	
	FormParameters = New Structure;
	FormParameters.Insert("Warehouse",                             Object.Warehouse);
	FormParameters.Insert("SelectionModeWithoutAmountParameters", True);
	FormParameters.Insert("HideTheViewPriceColumn",            True);
	FormParameters.Insert("HideTheItemPricesCommand",   True);
	FormParameters.Insert("FilterByProductType",           New FixedArray(ProductsClientServer.SelectionByProductMultiTurnContainer(False)));
	FormParameters.Insert("Title",                         NStr("vi = 'Chọn hàng hóa';
																|ru = 'Подбор товаров';
																|en = 'Pick goods'; fa = 'انتخاب کالاها';
																|it = 'Selezione delle merci';
																|pl = 'Wybór towarów';
																|tr = 'Ürünlerin seçimi'"));
	FormParameters.Insert("Date",                              Object.Date);
	FormParameters.Insert("Document",                          Object.Ref);
	DirectionOfActivityForSelection = PredefinedValue("Catalog.LinesOfBusiness.EmptyRef");
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.AssemblyFromComponents") Then
		DirectionOfActivityForSelection = Object.LineOfBusiness;
	EndIf;
	FormParameters.Insert("LineOfBusiness",           DirectionOfActivityForSelection);
	FormParameters.Insert("SeriesSpecificationParameters",            SeriesSpecificationParameters.TS);
	
	OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form", FormParameters, ThisForm, UUID);

EndProcedure

&AtClient
Procedure SearchByBarcodeExecute(Command)
	
	ClearMessages();
	Notification = New CallbackDescription("SearchByBarcodeCompletion", ThisObject);
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);
	
EndProcedure

&AtClient
Procedure SearchByBarcodeCompletion(BarcodeData_2, AdditionalParameters) Export
	
	ProcessBarcodes(BarcodeData_2);
	
EndProcedure

&AtClient
Procedure ImportDataFromPDT(Command)
	
	ClearMessages();
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.AssemblyFromComponents.DocumentForm.Command.ImportDataFromPDT");
	
	EquipmentManagerClient.StartDownloadingDataFromTSD(
		New CallbackDescription("DownloadFromTSDCompletion", ThisObject),
		UUID);
	
EndProcedure

&AtClient
Procedure DownloadFromTSDCompletion(ExecutionResult, Var_Parameters) Export
	
	If ExecutionResult.Result Then
		ProcessBarcodes(ExecutionResult.TableOfGoods);
	Else
		EquipmentManagerTMClient.ReportError(ExecutionResult);
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectGoodsByOrdersNotes(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.AssemblyFromComponents.DocumentForm.Command.SelectGoodsByOrdersNotes");
	
	OpenProductSelectionByOrdersOrders();

EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm, True);
	
EndProcedure

&AtClient
Procedure FillInWithComponents(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.AssemblyFromComponents.DocumentForm.Command.FillInWithComponents");
	
	ClearMessages();
	
	If Not ValueIsFilled(Object.ProductKit) Then

		CommonClientServer.MessageToUser(NStr("vi = 'Chưa chỉ ra trường ""Đóng bộ""';
												|ru = 'Не указано поле ""Комплектация""';
												|en = 'Product kit is not specified'; fa = 'Product kit is not specified';
												|it = 'Il campo ""Completamento"" non è specificato';
												|pl = 'Nie jest podane pole ""Komplektacja""';
												|tr = '""Ürün seti"" alanı belirtilmedi'"),,
				"ProductKit",
				"Object");

		Return;
	EndIf;

	FillInProductsByConfigurationOption();

EndProcedure

&AtClient
Procedure CheckQuantityInTheDocument(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.AssemblyFromComponents.DocumentForm.Command.CheckQuantityInTheDocument");
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("AddressInTempStorage",            PutTablePartOfGoodsInTemporaryStorageToCheckQuantity());
	OpeningParameters.Insert("TabularSectionName",                    "Goods");
	OpeningParameters.Insert("Ref",                               Object.Ref);
	OpeningParameters.Insert("GoodsQuantityExcessIsAllowed", Not ValueIsFilled(Object.ByAssemblyDisassemblyOrder));
	OpeningParameters.Insert("SeriesSpecificationParameters",               New FixedStructure(SeriesSpecificationParameters.TS));
	OpeningParameters.Insert("Warehouse",                                Object.Warehouse);
	OpeningParameters.Insert("ByAssemblyDisassemblyOrder",                        Object.ByAssemblyDisassemblyOrder);
	
	ReturnParameters = Undefined;

	
	OpenForm("CommonForm.CheckDocumentPopulation", OpeningParameters,,,,, New CallbackDescription("CheckQuantityInTheDocumentCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure CheckQuantityInTheDocumentCompletion(Result, AdditionalParameters) Export
	
	ReturnParameters = Result;
	If ReturnParameters <> Undefined Then
		
		ChangeTablePartBasedOnResultsOfCheck(ReturnParameters, ?(CachedValues = Undefined, BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues(), CachedValues));
		Modified = True;
		
		TMCommonUseClient.DisplayMessageExceedingNumber(ReturnParameters, NStr("vi = 'được nhập trên cơ sở lệnh.';
																				|ru = 'введенного на основании распоряжения.';
																				|en = 'entered based on the reference.'; fa = 'entered based on the reference.';
																				|it = 'введенного на основании распоряжения.';
																				|pl = 'entered based on the reference.';
																				|tr = 'sipariş temelinde yansıtılır.'"));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInSeriesByFEFO(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.AssemblyFromComponents.DocumentForm.Command.FillInSeriesByFEFO");
	
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
Procedure SpecifySeries(Command)
	
	OpenSelectionOfSeries(False);
	
EndProcedure

&AtClient
Procedure SpecifySeriesInHeader(Command)

	OpenSelectionOfSeries(True);

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
		
		If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.DisassemblyIntoComponents") Then
			RecalculatePercentageShareOfValue();
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure InsertRows(Command)
	
	NumberOfProductsBeforeInsertion = Object.Goods.Count();
	
	GetLinesFromClipboard();
	
	NumberOfInserted = Object.Goods.Count()-NumberOfProductsBeforeInsertion;
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
EndProcedure

&AtClient
Procedure CopyRows(Command)
	
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items.Goods) Then
		CopyLinesOnServer();
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(Items.Goods.SelectedRows.Count());
	EndIf;
	
EndProcedure

&AtClient
Procedure InstallTheMainComponent(Command)
	Component = Items.Goods.CurrentData;
	If Component <> Undefined Then
		FillInMainComponent(Component.Products, Component.Characteristic, Component.TheRecordsAreKeptByCCD);
	EndIf;
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure


// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure
// End StandardSubsystems.Properties


#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm);

	//

	LinesOfBusinessServer.SetConditionalAppearanceOfFlagSeparately(ThisObject);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsProducts.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCharacteristic.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ByAssemblyDisassemblyOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsRowCode.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ByAssemblyDisassemblyOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCostShare.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.CostSharePercentage");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	Item = ConditionalAppearance.Items.Add();

	Item.Fields.Items.Add().Field = New DataCompositionField(Items.GoodsCostSharePercentage.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.CostSharePercentage");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	Item = ConditionalAppearance.Items.Add();

	Item.Fields.Items.Add().Field = New DataCompositionField(Items.GoodsThereAreErrorsOfFillingInCostShare.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.CostSharePercentage");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Visible", False);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisForm, "SeriesWhenPlanningShipmentWHGoodsAreIndicated");

	//

	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisForm, False);

	//
	
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisForm);
	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisForm);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.BusinessUnitProduction.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SubjectToExcise");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessUnitProduction");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	// Conditional appearance of quality control Attributes.
	// Products.
	Fields = QualityControl.Fields(
		Items.GoodsToControlQuality,
		Items.GoodsQualityConfirmationDate);
	QualityControl.SetupAppearance(ConditionalAppearance, Fields);
	
	// Hat.
	Fields = QualityControl.Fields(
		Items.ToControlQuality,
		Items.QualityConfirmationDate);
	QualityControl.SetupAppearance(ConditionalAppearance, Fields);
	
EndProcedure

#Region FillingByOrderByOrder

&AtServer
Procedure RefillByNotes(AnArrayOfOrders)
	
	FillParameters = Documents.AssemblyFromComponents.DocumentFillingParameters();
	FillParameters.FormIsOpen      = True;
	FillParameters.FillByWarehouseDocument = True;
	
	HeaderAttributes = New Structure("Organization, Department, Warehouse, SalesOpportunity,
		|BusinessOperation, LineOfBusiness, GoodsReceiptOption, Ref");
	FillPropertyValues(HeaderAttributes, Object);
	Documents.AssemblyFromComponents.InitializeFillingParameters(FillParameters, HeaderAttributes, AnArrayOfOrders);
	
	Resources = New Array(1);
	
	FillInUsingSpendingOrder = AnArrayOfOrders.Find(Object.Ref) = Undefined
		Or Not ValueIsFilled(Object.ByAssemblyDisassemblyOrder);
	FillInByReceiptOrder = AnArrayOfOrders.Find(Object.Ref) <> Undefined
		Or Not PurchasesServer.OrderForAcceptanceOfGoodsConsignmentNote(Object.GoodsReceiptOption);
	
	If Object.BusinessOperation = Enums.BusinessTransactions.DisassemblyIntoComponents And FillInUsingSpendingOrder
		Or Object.BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents And FillInByReceiptOrder Then
		
		InvoiceByHeaderTable = Documents.AssemblyFromComponents.TableDataAndDocument(Object.Ref, True);
		
		Resources[0] = "Kit";
		FillParameters.Resources = Resources;
		Documents.AssemblyFromComponents.FillInByOrdersOrders(InvoiceByHeaderTable, Object.Ref, FillParameters, Object.PackageBarcodes);
		
		InvoiceByHeaderTable.Columns.Count.Name        = "QuantityBeforeChange_";
		InvoiceByHeaderTable.Columns.NoteQuantity.Name = "Count";
		
		Documents.AssemblyFromComponents.ResubmitProductsInHeader(Object, InvoiceByHeaderTable, AnArrayOfOrders[0]);
		
	EndIf;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents And FillInUsingSpendingOrder
		Or Object.BusinessOperation = Enums.BusinessTransactions.DisassemblyIntoComponents And FillInByReceiptOrder Then
		
		InvoiceTable = Documents.AssemblyFromComponents.TableDataAndDocument(Object.Ref);
		
		Resources[0] = "Components";
		FillParameters.Resources = Resources;
		Documents.AssemblyFromComponents.FillInByOrdersOrders(InvoiceTable, Object.Ref, FillParameters, Object.PackageBarcodes);
		
		InvoiceTable.Columns.Count.Name               = "QuantityBeforeChange_";
		InvoiceTable.Columns.NoteQuantity.Name        = "Count";
		
		Object.Goods.Load(InvoiceTable);
		
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation",
			QualityControlClientServer.CacheByKey(CacheQualityControl, "Goods"));
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
		Documents.AssemblyFromComponents.UpdateDependentDetailsOfTablePart(Object.Goods, FillParameters);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.TS);
		
		// Filling in the series.
		SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(Object, Documents.AssemblyFromComponents);
		// Updating the series indication statuses.
		ProductsServer.FillInSeriesByFEFO(Object, SeriesSpecificationParameters.TS, False);
		
	EndIf;
	FillInServiceDetailsForProductRange();
	
EndProcedure

&AtClient
Procedure ReportResults()
	
	If FillingResults <> Undefined Then
		
		If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.AssemblyFromComponents") Then
			
			If FillingResults.ThereAreUnassembled Then
				
				ShowUserNotification(
					NStr("vi = 'Điền lại số lượng';
						|ru = 'Количество перезаполнено';
						|en = 'Refilled quantity'; fa = 'Refilled quantity';
						|it = 'La quantità è ricompilata';
						|pl = 'Ponowne wypełnienie ilości.';
						|tr = 'Miktar yeniden dolduruldu'"),,
					NStr("vi = 'Đã điền số lượng bộ và thành phần chi tiết có tính đến thành phần chi tiết được lắp ráp tại kho.';
						|ru = 'Количество комплектов и комплектующих с учетом комплектующих собираемых на складе перезаполнено.';
						|en = 'Number of kits and components was refilled considering components assembled in the warehouse.'; fa = 'Number of kits and components was refilled considering components assembled in the warehouse.';
						|it = 'Il numero dei pacchetti e di componenti tenendo conto dei componenti che vengono assemblati nel magazzino è ricompilato.';
						|pl = 'Ilość kompletów i komponentów z uwzględnieniem komponentów zbieranych w magazynie zostało ponowne wypełnione.';
						|tr = 'Ambarda toplanan bileşenler dikkate alınarak set ve bileşen miktarı yeniden dolduruldu.'"),
					PictureLib.Information32);
				
			Else
				
				ShowUserNotification(
					NStr("vi = 'Điền lại số lượng';
						|ru = 'Количество перезаполнено';
						|en = 'Refilled quantity'; fa = 'Refilled quantity';
						|it = 'La quantità è ricompilata';
						|pl = 'Ponowne wypełnienie ilości.';
						|tr = 'Miktar yeniden dolduruldu'"),,
					NStr("vi = 'Đã điền lại số lượng bộ và thành phần chi tiết.';
						|ru = 'Количество комплектов и комплектующих перезаполнено.';
						|en = 'Quantity of kits and components was refilled.'; fa = 'Quantity of kits and components was refilled.';
						|it = 'Il numero dei pacchetti e dei componenti è ricompilato.';
						|pl = 'Ilość kompletów i komponentów zostało ponowne wypełnione.';
						|tr = 'Set ve bileşenlerin miktarı yeniden dolduruldu.'"),
				PictureLib.Information32);
				
			EndIf;
			
		Else
			
			If FillingResults.ThereAreUnassembled Then
				
				ShowUserNotification(
					NStr("vi = 'Điền lại số lượng';
						|ru = 'Количество перезаполнено';
						|en = 'Refilled quantity'; fa = 'Refilled quantity';
						|it = 'La quantità è ricompilata';
						|pl = 'Ponowne wypełnienie ilości.';
						|tr = 'Miktar yeniden dolduruldu'"),,
					NStr("vi = 'Đã điền lại số lượng bộ và thành phần chi tiết có ghi nhận bộ được lắp ráp tại kho.';
						|ru = 'Количество комплектов и комплектующих с учетом комплектов собираемых на складе перезаполнено.';
						|en = 'Number of kits and components was refilled considering kits assembled in the warehouse.'; fa = 'Number of kits and components was refilled considering kits assembled in the warehouse.';
						|it = 'Il numero dei pacchetti e di componenti tenendo conto dei pacchetti che vengono composti nel magazzino è ricompilato.';
						|pl = 'Ilość kompletów i komponentów z uwzgłędnieniem kompletów zbieranych w magazynie zostało ponowne wypełnione.';
						|tr = 'Ambarda toplanan setler dikkate alınarak set ve bileşen miktarı yeniden dolduruldu.'"),
					PictureLib.Information32);
				
			Else
				
				ShowUserNotification(
					NStr("vi = 'Điền lại số lượng';
						|ru = 'Количество перезаполнено';
						|en = 'Refilled quantity'; fa = 'Refilled quantity';
						|it = 'La quantità è ricompilata';
						|pl = 'Ponowne wypełnienie ilości.';
						|tr = 'Miktar yeniden dolduruldu'"),,
					NStr("vi = 'Đã điền lại số lượng bộ và thành phần chi tiết.';
						|ru = 'Количество комплектов и комплектующих перезаполнено.';
						|en = 'Quantity of kits and components was refilled.'; fa = 'Quantity of kits and components was refilled.';
						|it = 'Il numero dei pacchetti e dei componenti è ricompilato.';
						|pl = 'Ilość kompletów i komponentów zostało ponowne wypełnione.';
						|tr = 'Set ve bileşenlerin miktarı yeniden dolduruldu.'"),
				PictureLib.Information32);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenProductSelectionByOrdersOrders()
	
	HeaderAttributes = New Structure("Organization, Department, Warehouse, SalesOpportunity,
		|BusinessOperation, LineOfBusiness, GoodsReceiptOption, Ref");
	FillPropertyValues(HeaderAttributes, Object);
	FillInResources = New Array;
	FillInResources.Add("Kit");
	FillInResources.Add("Components");
	AdditionalFields = New Structure("SetIndex, DateOfShipment, SalesOpportunity",, NStr("vi = 'Ngày giao hàng/ngày nhận';
																						|ru = 'Дата отгрузки/приемки';
																						|en = 'Date of shipment/receiving'; fa = 'Date of shipment/receiving';
																						|it = 'Data di spedizione/ricezione';
																						|pl = 'Data wysyłki/odbioru';
																						|tr = 'Sevkiyat tarihi/kabulü'"));
	
	FormParameters = New Structure();
	FormParameters.Insert("HeaderAttributes",                           HeaderAttributes);
	FormParameters.Insert("OrderDocument",                                    Object.ByAssemblyDisassemblyOrder);
	FormParameters.Insert("AdvancedWarehousingOnShipment",                 AdvancedWarehousingOnShipment);
	FormParameters.Insert("AdvancedWarehousingOnGoodsReceipt",              AdvancedWarehousingOnGoodsReceipt);
	FormParameters.Insert("InvoiceForOrders",                       ValueIsFilled(Object.ByAssemblyDisassemblyOrder));
	FormParameters.Insert("AddressGoods",                              AddressInvoiceGoods());
	FormParameters.Insert("FillInResources",                        FillInResources);
	FormParameters.Insert("Invoice",                                Object.Ref);
	FormParameters.Insert("UseInvoicesForSeveralOrders", False);
	FormParameters.Insert("OrdersAreUsed",                       ValueIsFilled(Object.ByAssemblyDisassemblyOrder));
	FormParameters.Insert("AdditionalFields",                       AdditionalFields);

	OpenForm("CommonForm.AddItemsFromSalesOrderGoodsIssue",
		FormParameters, ThisForm, UUID,,,,FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtServer
Function AddressInvoiceGoods()
	
	Table = Object.Goods.Unload();
	
	Table.Columns.Add("ByAssemblyDisassemblyOrder", New TypeDescription("DocumentRef.ByAssemblyDisassemblyOrder, DocumentRef.AssemblyFromComponents"));
	Table.Columns.Add("SalesOpportunity",        New TypeDescription("CatalogRef.SalesOpportunitiesToCustomer"));
	Table.Columns.Add("DateOfShipment",  New TypeDescription("Date"));
	Table.Columns.Add("SetIndex",  New TypeDescription("Number"));
	
	CustomAssembly = ValueIsFilled(Object.ByAssemblyDisassemblyOrder);
	
	// For the selection of kits.
	NewRow = Table.Insert(0);
	FillPropertyValues(NewRow, Object);
	NewRow.RowCode    = 1;
	NewRow.LineNumber  = 0;
	NewRow.SetIndex = 1;
	
	Table.FillValues(?(ValueIsFilled(Object.ByAssemblyDisassemblyOrder), Object.ByAssemblyDisassemblyOrder, Object.Ref), "ByAssemblyDisassemblyOrder");
	Table.FillValues(Object.SalesOpportunity,       "SalesOpportunity");
	Table.FillValues(CurrentSessionDate(), "DateOfShipment");
	
	Return PutToTempStorage(Table);
	
EndFunction

#EndRegion

#Region OnChangeAttributes

&AtServer
Procedure UpdateQualityControlAttributes()

	If QualityControl.UpdateActionParameters(
			Documents.AssemblyFromComponents,
			Object,
			QualityControlClientServer.CacheByKey(CacheQualityControl, "Goods")) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation",
			QualityControlClientServer.CacheByKey(CacheQualityControl, "Goods"));
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
	If QualityControl.UpdateActionParameters(
			Documents.AssemblyFromComponents,
			Object,
			QualityControlClientServer.CacheByKey(CacheQualityControl, "Header")) Then
			
		Actions = New Structure();
		Actions.Insert("FillInCheckQualityDateOfQualityConfirmation",
			QualityControlClientServer.CacheByKey(CacheQualityControl, "Header"));
		Header = New Structure(
			"Products,
			|ToControlQuality,
			|QualityConfirmationDate");
		FillPropertyValues(Header, Object);
		BatchProcessingOfTablePartServer.ProcessTSString(Header, Actions, Undefined);
		FillPropertyValues(Object, Header);
		
	EndIf;
	SetDesignOfQualityControlFields();
	
EndProcedure

&AtServer
Procedure BusinessOperationOnChangeServer()
	
	UpdateQualityControlAttributes();
	PrepareFillSetSeriesVisibility();
	ConfigurePickUpByOrdersOrdersCommand();
	
	LinesOfBusinessServer.OnReadCreateAtServer(ThisObject);
	DirectionOfActivityWhenChangingOnServer();
	
EndProcedure

&AtServer
Procedure DirectionOfActivityWhenChangingOnServer()
	
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	
	If Object.BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents Then
		
		If ValueIsFilled(Object.LineOfBusiness) Then
			Object.Purpose = Catalogs.Assignments.EmptyRef();
		EndIf;
		
	EndIf;
	UpdateAssignmentWhenProductNameChanges();
	
	FormItemsManagement();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.TS);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.Header);
	
EndProcedure

&AtClient
Procedure WhenChangingPackaging(CurrentRow)

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtServer
Procedure WarehouseOnChangeServer(DirectModificationOfWarehouseField = False)
	
	If QualityControl.UpdateActionParameters(
			Documents.AssemblyFromComponents,
			Object,
			QualityControlClientServer.CacheByKey(CacheQualityControl, "Goods"),
			DirectModificationOfWarehouseField) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation",
			QualityControlClientServer.CacheByKey(CacheQualityControl, "Goods"));
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
	If QualityControl.UpdateActionParameters(
			Documents.AssemblyFromComponents,
			Object,
			QualityControlClientServer.CacheByKey(CacheQualityControl, "Header"),
			DirectModificationOfWarehouseField) Then
			
		Actions = New Structure();
		Actions.Insert("FillInCheckQualityDateOfQualityConfirmation",
			QualityControlClientServer.CacheByKey(CacheQualityControl, "Header"));
		Header = New Structure(
			"Products,
			|ToControlQuality,
			|QualityConfirmationDate");
		FillPropertyValues(Header, Object);
		BatchProcessingOfTablePartServer.ProcessTSString(Header, Actions, Undefined);
		FillPropertyValues(Object, Header);
		
	EndIf;
	SetDesignOfQualityControlFields();
	
	If Warehouse = Object.Warehouse Then
		
		Return;
		
	EndIf;
	
	PrepareFillSetSeriesVisibility();
	UpdateAssemblyForActivity();
	Warehouse = Object.Warehouse;
	AdvancedWarehousingOnShipment = WarehousesServer.UseWarehouseManagemantSystemForGoodsIssue(Warehouse, Object.Date);
	AdvancedWarehousingOnGoodsReceipt = WarehousesServer.UseWarehouseManagemantSystemForGoodsReceipt(Warehouse, Object.Date);
	ConfigurePickUpByOrdersOrdersCommand();
	
EndProcedure

&AtServer
Procedure ProductsOnChangeServer(ValuesCache)
	
	Actions = New Structure;
	Actions.Insert("CheckCharacteristicsByOwner", Object.Characteristic);
	Actions.Insert("CheckFillPackageByOwner", Object.Package);
	Actions.Insert("CheckCompleteConfigurationOptionByOwner", Object.ProductKit);
	Actions.Insert("RecalculateNumberOfUnits");
	Actions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	
	Actions.Insert("ProductsOnChangeOverridable",
		New Structure("FormName, TabularSectionName", ThisForm.FormName, "Object"));
	Actions.Insert("FillInCheckQualityDateOfQualityConfirmation",
		QualityControlClientServer.CacheByKey(CacheQualityControl, "Header"));
	
	Header = New Structure(
		"Products,
		|Characteristic,
		|Purpose,
		|ProductKit,
		|Package,
		|Count,
		|NumberOfPackages,
		|ItemVariantsAreUsed,
		|ItemsType,
		|ToControlQuality,
		|QualityConfirmationDate");
	FillPropertyValues(Header, Object);
	
	BatchProcessingOfTablePartServer.ProcessTSString(Header, Actions, ValuesCache);
	FillPropertyValues(Object, Header);
	
	SetAvailabilityOfKitItemsInHeader();
	FormItemsManagement(True);
	ConfigureMainComponent();
	
	If SeriesSpecificationParameters.Header.UseItemsBatch Then
		FillInStatusesOfSpecifyingSeriesWhenChangingProductInHeader(ValuesCache);
	EndIf;
	UpdateAssignmentWhenProductNameChanges();
	
EndProcedure

&AtServer
Procedure SeparateWhenChangingOnServer()
	
	Object.Purpose = ?(WithAssignment,
		LinesOfBusinessServer.PushingAssignment(Object.LineOfBusiness), Undefined);

EndProcedure

&AtServer
Procedure UpdateAssignmentWhenProductNameChanges()
	
	If Object.BusinessOperation = Enums.BusinessTransactions.DisassemblyIntoComponents Then
		
		ItemsType = Common.ObjectAttributeValue(Object.Products, "ItemsType");
		If ItemsType = Enums.ItemsTypes.OwnGoods Then
			If ValueIsFilled(Object.ByAssemblyDisassemblyOrder) Then
				Object.Purpose = Common.ObjectAttributeValue(Object.ByAssemblyDisassemblyOrder, "Purpose");
			Else
				Object.Purpose = LinesOfBusinessServer.PushingAssignment(Object.LineOfBusiness);
			EndIf;
		Else
			Object.Purpose = Catalogs.Assignments.EmptyRef();
		EndIf;
		WithAssignment = ValueIsFilled(Object.Purpose);
		
	EndIf;

EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	UpdateAssemblyForActivity();
	UpdateElementsOfAccountingForExcisableItems();
EndProcedure

&AtServer
Procedure DateOnChangeServer()
	
	UpdateQualityControlAttributes();
	
	PrepareFillSetSeriesVisibility();
	UpdateAssemblyForActivity();
	AdvancedWarehousingOnShipment = WarehousesServer.UseWarehouseManagemantSystemForGoodsIssue(Warehouse, Object.Date);
	AdvancedWarehousingOnGoodsReceipt = WarehousesServer.UseWarehouseManagemantSystemForGoodsReceipt(Warehouse, Object.Date);
	UpdateElementsOfAccountingForExcisableItems();
EndProcedure

&AtServer
Procedure DateOfReceiptOnChangeServer()
	
	UpdateQualityControlAttributes();
	
EndProcedure

&AtServer
Procedure ProductsAfterEditingOnServer(UpdateSeriesStatuses, RecalculatePercentageShareOfValue,
											RowID, CachedValues)
	
	If UpdateSeriesStatuses Then
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(RowID, CachedValues);
	EndIf;
	
	If RecalculatePercentageShareOfValue Then
		RecalculatePercentageShareOfValue();
	EndIf;
	
EndProcedure

&AtServer
Procedure ToControlQualityOnChangeServer()
	
	SetDesignOfQualityControlFields();
	
EndProcedure

&AtServer
Procedure RecalculatePercentageShareOfValue()
	
	If Object.Goods.Count() = 1 Then
		Object.Goods[0].CostSharePercentage = 100;
		Object.Goods[0].ThereAreErrorsOfFillingInCostShare = False;
	Else
		TotalCostShare = Object.Goods.Total("CostShare");
		For Each String In Object.Goods Do
			String.CostSharePercentage = ?(TotalCostShare = 0, 0, String.CostShare / TotalCostShare * 100);
			String.ThereAreErrorsOfFillingInCostShare = Not ValueIsFilled(String.CostShare);
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

#Region SelectionAndProcessingOfQuantityVerification

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected)

	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	
	Actions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(Actions);
	Actions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	Actions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	Actions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	Actions.Insert("FillInCheckQualityDateOfQualityConfirmation",
		QualityControlClientServer.CacheByKey(CacheQualityControl, "Goods"));
	RowsToProcess = New Array();
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct, "Products, Characteristic, ItemVariantsAreUsed,
		| Package, NumberOfPackages, Series, WithAssignment");
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		Actions,
		Object.Goods);

	For Each RowOfProduct In TableOfGoods Do
		LinesOfBusinessClientServer.FillAssignmentByFlagSeparately(ThisObject, CurrentRow);
	EndDo;
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.TS);
	
EndProcedure

&AtServer
Procedure ProcessingProductSelectionFromOrder(AddressInStorage)
	
	CalculationResult1 = GetFromTempStorage(AddressInStorage);
	Table = CalculationResult1.Goods; // TabularSection
	
	// Hat.
	FoundRows = Table.FindRows(New Structure("SetIndex", 1));
	If FoundRows.Count() > 0 Then
		
		For Each HeaderString In FoundRows Do
			If HeaderString.NumberOfPackages > 0 Then
				FillPropertyValues(Object, HeaderString,
					"Products, Characteristic, Series, Purpose, Package, Count, NumberOfPackages");
			EndIf;
			Table.Delete(HeaderString);
		EndDo;
		
		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
		BatchProcessingOfTablePartServer.ProcessTSString(Object, StructureOfActions, Undefined);
		
		SetAvailabilityOfKitItemsInHeader();
		
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.Header);
		
	EndIf;
	
	// The tabular part.
	FieldsNames = "LineNumber";
	TheStructureOfTheSearch = New Structure(FieldsNames);
	Table.Sort(FieldsNames + " Desc");
	
	// Grouping a table by row keys.
	StringTree = New Array();
	For Each TableRow In Table Do
		
		If TheStructureOfTheSearch.LineNumber <> TableRow.LineNumber Then
			
			RowsArray = New Array();
			StringTree.Add(RowsArray);
			
			FillPropertyValues(TheStructureOfTheSearch, TableRow);
			
		EndIf;
		
		RowsArray.Add(TableRow);
		
	EndDo;
	
	OrderRelationshipFields = New Structure("RowCode", 0);
	AddedRows = InvoicesServer.FillInProductsSelectedFromOrder(StringTree, FieldsNames, Object.Goods, OrderRelationshipFields);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	
	StructureOfActionsAddedLines = New Structure();
	StructureOfActionsAddedLines.Insert("FillInCheckQualityDateOfQualityConfirmation",
		QualityControlClientServer.CacheByKey(CacheQualityControl, "Goods"));
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		AddedRows,
		StructureOfActionsAddedLines,
		Object.Goods);
	
	FillInServiceDetailsForProductRange();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.TS);
	
	For Each String In Object.Goods Do
		If String.RowCode = 0 Then
			String.Purpose = Catalogs.Assignments.EmptyRef();
		EndIf;
	EndDo;
	LinesOfBusinessServer.SetVisibilityOfElementsSeparately(ThisObject);
	LinesOfBusinessServer.ReFillInServiceDetailsOfTablePart(ThisObject);	
	
	SalesServerLocalization.TransferBarcodesOfPackages(ThisObject, CalculationResult1.PackageBarcodes);
	
EndProcedure

&AtServer
Function PutTablePartOfGoodsInTemporaryStorageToCheckQuantity()
	
	TabularPartProducts = Object.Goods.Unload(,"Products, Characteristic, ItemVariantsAreUsed, Package, NumberOfPackages, Series, BatchesIndicationStatus, ItemsType");
	TabularPartProducts.GroupBy("Products, Characteristic, ItemVariantsAreUsed, Package, Series, BatchesIndicationStatus, ItemsType", "NumberOfPackages");
	AddressInTempStorage = PutToTempStorage(TabularPartProducts, UUID);
	Return AddressInTempStorage;
	
EndFunction

&AtServer
Procedure ChangeTablePartBasedOnResultsOfCheck(ReturnParameters, CachedValues)
	
	GoodsTable = GetFromTempStorage(ReturnParameters.Goods);
	ModifiedRows = New Array();
	AddedRows = New Array();
	LinesToDelete = New Array;
	For Each SourceRow In GoodsTable Do
		
		Filter = New Structure("Products, Characteristic, Series, BatchesIndicationStatus, Package");
		FillPropertyValues(Filter, SourceRow);
		FoundRows = Object.Goods.FindRows(Filter);
		For Each TSRow In FoundRows Do
			
			If SourceRow.NumberOfPackages = 0 Then
				Break;
			EndIf;
			
			If SourceRow.NumberOfPackages >= 0 Then
				
				TSRow.NumberOfPackages = TSRow.NumberOfPackages + SourceRow.NumberOfPackages;
				SourceRow.NumberOfPackages = 0;
				ModifiedRows.Add(TSRow);
				
			Else
				
				QuantityToWriteOff = -SourceRow.NumberOfPackages;
				QuantityPerLine   = TSRow.NumberOfPackages;
				
				If QuantityToWriteOff >= QuantityPerLine Then
					SourceRow.NumberOfPackages = QuantityPerLine - QuantityToWriteOff;
					TSRow.NumberOfPackages       = 0;
				Else
					SourceRow.NumberOfPackages = 0;
					TSRow.NumberOfPackages       = QuantityPerLine - QuantityToWriteOff;
					ModifiedRows.Add(TSRow);
				EndIf;
				
			EndIf;
			
			If TSRow.NumberOfPackages = 0 Then
				LinesToDelete.Add(TSRow);
			Else
				
			EndIf;
			
		EndDo;
		If FoundRows.Count() = 0 Then
			
			TSRow = Object.Goods.Add();
			FillPropertyValues(TSRow, SourceRow);
			AddedRows.Add(TSRow);
			
		EndIf;
		
	EndDo;
	
	ActionStructureModifiedStrings = New Structure();
	ActionStructureModifiedStrings.Insert("FillInArticleAttribute",
		New Structure("Products", "SKU"));
	ActionStructureModifiedStrings.Insert("FillInProductTypeAttribute_",
		New Structure("Products", "ItemsType"));
	ActionStructureModifiedStrings.Insert("FillInCCDTrackingAttribute",
		New Structure("Products", "TheRecordsAreKeptByCCD"));
	AddActionsToStructureWhenChangingPackagesNumber(ActionStructureModifiedStrings);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ModifiedRows,
		ActionStructureModifiedStrings,
		Object.Goods,
		CachedValues);
	
	StructureOfActionsAddedLines = New Structure();
	StructureOfActionsAddedLines.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsAddedLines.Insert("FillInProductTypeAttribute_",
		New Structure("Products", "ItemsType"));
	StructureOfActionsAddedLines.Insert("FillInCCDTrackingAttribute",
		New Structure("Products", "TheRecordsAreKeptByCCD"));
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsAddedLines);
	StructureOfActionsAddedLines.Insert("FillInCheckQualityDateOfQualityConfirmation",
		QualityControlClientServer.CacheByKey(CacheQualityControl, "Goods"));
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		AddedRows,
		StructureOfActionsAddedLines,
		Object.Goods,
		CachedValues);
	
	For Each TSRow In LinesToDelete Do
		Object.Goods.Delete(TSRow);
	EndDo;
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters.TS);
	
	If Object.BusinessOperation = Enums.BusinessTransactions.DisassemblyIntoComponents Then
		RecalculatePercentageShareOfValue();
	EndIf;
	
EndProcedure

#EndRegion

#Region BarcodesAndTradeEquipment

&AtServer
Procedure ProcessBarcodesServer(StructureOfActionParameters, CachedValues)

	BarcodingOfItemsServer.ProcessBarcodes(ThisObject, Object, StructureOfActionParameters, CachedValues);

EndProcedure

&AtClient
Procedure ProcessBarcodes(BarcodeData_5)
	
	ClearMessages();
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
		Return;
	EndIf;
	
	ChangeQuantity = Not ValueIsFilled(Object.ByAssemblyDisassemblyOrder);
	
	StructureOfActionsWithAddedStrings = New Structure;
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsWithAddedStrings.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActionsWithAddedStrings.Insert("FillInCheckQualityDateOfQualityConfirmation",
		QualityControlClientServer.CacheByKey(CacheQualityControl, "Goods"));
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithAddedStrings);
	
	If ChangeQuantity Then
		LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject,
			StructureOfActionsWithAddedStrings);
	EndIf;
	
	StructureOfActionsWithModifiedStrings = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithModifiedStrings);
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	StructureOfActions.SeriesSpecificationParameters                 = SeriesSpecificationParameters.TS;
	StructureOfActions.ChangeQuantity                     = ChangeQuantity;
	StructureOfActions.GoodsOnly                           = True;
	
	ProcessBarcodesServer(StructureOfActions, CachedValues);
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(StructureOfActions, CachedValues, ThisObject);
	
	If BarcodingOfItemsClient.YouNeedToOpenFormForSpecifyingSeriesAfterProcessingBarcodes(StructureOfActions) Then
		CurDataId = StructureOfActions.ArrayOfRowsWithSeries_[0];
		
		AttachIdleHandler("OpenSeriesSelectionWhenScanningProductBarCode", 0.1, True);
	EndIf;
	
	If StructureOfActions.CurrentRow <> Undefined Then
		Items.Goods.CurrentRow = StructureOfActions.CurrentRow;
	EndIf;
	
EndProcedure

#EndRegion

#Region SetOfSeries

&AtServer
Function ParametersOfSeriesIndicationForm(CurDataId, ProductInHeader)
	
	If ProductInHeader Then
		Return ProductsServer.ParametersOfSeriesIndicationForm(Object, SeriesSpecificationParameters.Header, CurDataId, ThisForm);
	Else
		Return ProductsServer.ParametersOfSeriesIndicationForm(Object, SeriesSpecificationParameters.TS, CurDataId, ThisForm);
	EndIf;
	
EndFunction

&AtServer
Procedure FillInStatusesOfSpecifyingSeriesWhenChangingProductInHeader(CachedValues)

	ProductsServer.FillInStatusesOfSpecifyingSeriesWhenChangingProductInHeader(Object, 
				SeriesSpecificationParameters.Header, CachedValues);
    SetSeriesAvailabilityInHeader();

EndProcedure

&AtServer
Procedure ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm, ProductInHeader)
	StructureOfActions = New Structure;
	
	If Not ProductInHeader
		And Object.BusinessOperation = Enums.BusinessTransactions.DisassemblyIntoComponents Then
		
		StructureOfActions.Insert("UpdateNumberOfProductsWhenRegistering", True);
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	EndIf;

	If ProductInHeader Then
		ProductsServer.ProcessSeriesIndication_(Object,SeriesSpecificationParameters.Header,ParametersOfSeriesIndicationForm,StructureOfActions);
	Else
		ProductsServer.ProcessSeriesIndication_(Object,SeriesSpecificationParameters.TS,ParametersOfSeriesIndicationForm,StructureOfActions);
	EndIf;
EndProcedure

&AtServer
Procedure CustomizeSeriesItems()
	
	Items.GoodsBatchesIndicationStatus.Visible   = SeriesSpecificationParameters.TS.UseItemsBatch;
	Items.GoodsSpecifySeries.Visible          = SeriesSpecificationParameters.TS.UseItemsBatch;
	Items.GoodsSeries.Visible                 = SeriesSpecificationParameters.TS.UseItemsBatch;
	
	Items.SpecifySeriesInHeader.Visible          = SeriesSpecificationParameters.Header.UseItemsBatch;
	Items.BatchesIndicationStatus.Visible         = SeriesSpecificationParameters.Header.UseItemsBatch;
	Items.Series.Visible                       = SeriesSpecificationParameters.Header.UseItemsBatch;
	
	Items.GoodsFillInSeriesByFEFO.Visible  = SeriesSpecificationParameters.TS.UseItemsBatch;
	
	SetSeriesAvailabilityInHeader();
	
EndProcedure

&AtServer
Procedure SetSeriesAvailabilityInHeader()
	If Object.BatchesIndicationStatus = 14
		Or Object.BatchesIndicationStatus = 13 Then
		Items.Series.Enabled = True;
		Items.Series.AutoMarkIncomplete = True;
	Else
		Items.Series.Enabled = False;
		Items.Series.AutoMarkIncomplete = False;
	EndIf;
	Items.SpecifySeriesInHeader.Enabled = Object.BatchesIndicationStatus <> 0;
EndProcedure

&AtClient
Procedure OpenSeriesSelectionWhenScanningProductBarCode()
	If CurDataId = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.Goods.FindByID(CurDataId);
	OpenSelectionOfSeries(False,,CurrentData);
EndProcedure

&AtServer
Function FillInSeriesByFEFOServer()

	If ProductsServer.ThereAreLinesWithFEFOFilledSeries_(Object.Goods) Then

		ProductsServer.FillInSeriesByFEFO(Object,SeriesSpecificationParameters.TS);
		Return True;

	Else

		Return False;

	EndIf;

EndFunction

&AtServer
Function ThereAreFilledSeriesByFEFO()

	Return ProductsServer.ThereAreLinesWithFEFOFilledSeries(Object.Goods);

EndFunction

&AtServer
Procedure FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues)

	ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Object, 
				SeriesSpecificationParameters.TS, IDCurrentRow, CachedValues);

EndProcedure

&AtClient
Procedure OpenSelectionOfSeries(ProductInHeader, Text = "", CurrentData = Undefined)
	
	If ProductInHeader Then
		CurParametersForSpecifyingSeries = SeriesSpecificationParameters.Header;
		SeriesIsEditedInHeader      = True;
		
	Else
		CurParametersForSpecifyingSeries = SeriesSpecificationParameters.TS;
		SeriesIsEditedInHeader      = False;
	EndIf;
	
	If ProductsClient.YouNeedServerCallToSpecifySeries(ThisForm,CurParametersForSpecifyingSeries,Text)Then
		If ProductInHeader Then
			CurDataId = Undefined;
		ElsIf CurrentData = Undefined Then
			CurDataId = Items.Goods.CurrentData.GetID();
		Else
			CurDataId = CurrentData.GetID();
		EndIf;
		ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm(CurDataId, ProductInHeader);
		
		ReturnValue_1 = Undefined;

		
		OpenForm(ParametersOfSeriesIndicationForm.FormName,ParametersOfSeriesIndicationForm,ThisForm,,,, New CallbackDescription("OpenSelectionOfSeriesCompletion", ThisObject, New Structure("ParametersOfSeriesIndicationForm, ProductInHeader", ParametersOfSeriesIndicationForm, ProductInHeader)), FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
EndProcedure

&AtClient
Procedure OpenSelectionOfSeriesCompletion(Result, AdditionalParameters) Export
    
    ParametersOfSeriesIndicationForm = AdditionalParameters.ParametersOfSeriesIndicationForm;
    ProductInHeader = AdditionalParameters.ProductInHeader;
    
    
    ReturnValue_1 = Result;
    
    If ReturnValue_1 <> Undefined Then
        ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm, ProductInHeader);
    EndIf;
    If ProductInHeader Then
        ProductsClient.UpdateCachedHeaderValuesToAccountForSeries(Object,CachedValues,SeriesSpecificationParameters.Header);
    EndIf;

EndProcedure

&AtServer
Procedure PrepareFillSetSeriesVisibility()
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.AssemblyFromComponents));
	Items.GroupInformationRequiredStatuses.Visible = DisplayMessageOnUsingStatuses();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters.TS);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters.Header);
	CustomizeSeriesItems();
EndProcedure
	
&AtServer
Function DisplayMessageOnUsingStatuses()

	DisplayMessageOnUsingStatuses = False;
	
	If (SeriesSpecificationParameters.TS.UseItemsBatch
		Or SeriesSpecificationParameters.Header.UseItemsBatch)
		And Not GetFunctionalOption("UseGoodsAssemblyStatuses") Then
		
		BatchAccountingPoliciesWarehouse = WarehousesServer.UseOfSeriesInStockAccordingToAccountingPolicies(Object.Warehouse);
		UseOrderSchemeForAcceptance = WarehousesServer.UseWarehouseManagemantSystemForGoodsReceipt(Object.Warehouse, Object.Date);
		WarehouseSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Warehouse, False);
		
		If UseOrderSchemeForAcceptance Then
			
			If BatchAccountingPoliciesWarehouse.SpecifyWhenPlanningShipment
				And BatchAccountingPoliciesWarehouse.UseCostAccountingByBatches Then
					
					DisplayMessageOnUsingStatuses = True;
					
			EndIf;
				
		EndIf;
			
		If Not WarehouseSeriesParameters.UseItemsBatch
				And BatchAccountingPoliciesWarehouse.UseCostAccountingByBatches Then
				
				DisplayMessageOnUsingStatuses = True;
				
		EndIf;
	
	EndIf;
	
	Return DisplayMessageOnUsingStatuses;
	
EndFunction

#EndRegion

#Region Other

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtServer
Procedure SetUncheckSeparately(Set)
	LinesOfBusinessServer.SetUncheckSeparately(ThisObject, Set);
EndProcedure

&AtServer
Procedure FillInProductsByConfigurationOption()
	
	If Not ValueIsFilled(Object.ByAssemblyDisassemblyOrder) Then
		
		Object.Goods.Load(Catalogs.ProductKitConfigurations.GetProductComponents(
			Object.ProductKit, , Object.Count));
		
		FillInServiceDetailsForProductRange();
		StructureOfActions = New Structure();
		LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisForm, StructureOfActions);
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation",
			QualityControlClientServer.CacheByKey(CacheQualityControl, "Goods"));
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
		
		ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters.TS);
	
	Else // rows will not be added, only quantity updates.
		
		Catalogs.ProductKitConfigurations.UpdateNumberOfComponentsByNumberOfSets(
			Object.Goods, Object.Count, Object.ProductKit);
		
	EndIf;
	
	If ValueIsFilled(Object.ProductKit) Then
		
		Component = Common.ObjectAttributesValues(Object.ProductKit,
			New Structure("Products, Characteristic", "ProductsOfMainComponent", "MainComponentCharacteristic"));
		If ValueIsFilled(Component.Products) And ValueIsFilled(Object.Goods.FindRows(Component)) Then
			Object.ProductsOfMainComponent = Component.Products;
			Object.MainComponentCharacteristic = Component.Characteristic;
			ConfigureMainComponent();
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotifyAboutDocument(WriteParameters)

	NotificationProcessingParameter = CommonClient.CopyRecursive(WriteParameters);
	If TypeOf(FormOwner) = Type("ClientApplicationForm") Then
		IdOfOwnerSForm = FormOwner.UUID;
	Else
		IdOfOwnerSForm = Undefined;
	EndIf;
	NotificationProcessingParameter.Insert("IdOfOwnerSForm", IdOfOwnerSForm);
	NotificationProcessingParameter.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
	Notify("Write_AssemblyFromComponents", NotificationProcessingParameter, Object.Ref);

EndProcedure

&AtServer
Procedure FormItemsManagement(ThereIsChangeInItemList = False)
	
	UseImportedGoods_ = GetFunctionalOption("UseImportedGoods");
	
	ThisIsBuild = (Object.BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents);
	ThisIsDisassembly = (Object.BusinessOperation = Enums.BusinessTransactions.DisassemblyIntoComponents);

	Items.ByAssemblyDisassemblyOrder.Visible = ValueIsFilled(Object.ByAssemblyDisassemblyOrder);
	
	Items.MainComponentGroup.Visible = UseImportedGoods_;

	Items.GoodsInstallTheMainComponent.Visible = ThisIsBuild;
	Items.GoodsContextMenuInstallTheMainComponent.Visible = ThisIsBuild;
	Items.RequestComponent.Visible = ThisIsBuild;
	Items.ComponentPresentation.Visible = ThisIsBuild;
	Items.EmptyComponentComment.Visible = ThisIsBuild;
	Items.CommentWarning.Visible = ThisIsBuild;
	Items.EmptyComponent.Visible = ThisIsBuild;

	// Purpose
	Items.Purpose.Visible = ThisIsBuild;
	Items.Purpose.ReadOnly = ValueIsFilled(Object.ByAssemblyDisassemblyOrder);
	Items.GoodsPurpose.Visible = Not ThisIsBuild;
	
	// WithAssignment
	Items.WithAssignment.Visible = Not ThisIsBuild
		And ValueIsFilled(LinesOfBusinessServer.PushingAssignment(Object.LineOfBusiness));

	ItemsType = Common.ObjectAttributeValue(Object.Products, "ItemsType");
	Items.WithAssignment.Enabled = ItemsType = Enums.ItemsTypes.OwnGoods;
	
	// The "Quantity" field is renamed according to the type of operation.
	If ThisIsDisassembly Then
		Items.NumberOfPackages.Title = NStr("vi = 'Tháo rời';
											|ru = 'Разобрано';
											|en = 'Disassembled'; fa = 'Disassembled';
											|it = 'Scomposto';
											|pl = 'Disassembled';
											|tr = 'Ayrıştırıldı'");
	Else
		Items.NumberOfPackages.Title = NStr("vi = 'Đã lắp ráp';
											|ru = 'Собрано';
											|en = 'Quantity'; fa = 'مقدار';
											|it = 'Composto';
											|pl = 'Quantity';
											|tr = 'Toplandı'");
	EndIf;
	
	If Not ThisIsBuild Then
		Items.ProductsTeamGroupSeparately.Visible = False;
		Items.GoodsWithAssignment.Visible = False;
	EndIf;
	
	Items.GoodsCostShare.Visible = Not ThisIsBuild;
	Items.GoodsCostSharePercentage.Visible = Not ThisIsBuild;
	Items.GoodsThereAreErrorsOfFillingInCostShare.Visible = Not ThisIsBuild;
	
	Items.SubjectToExcise.Visible = UseExcisableGoods;
	Items.BusinessUnitProduction.Visible = UseExcisableGoods;
	UpdateElementsOfAccountingForExcisableItems(ThereIsChangeInItemList);
	
	If ThisIsDisassembly Then
		Items.SubjectToExcise.Title =
			NStr("vi = 'Bộ sản phẩm chịu thuế TTĐB có thể chia tách, do doanh nghiệp sản xuất và chịu thuế TTĐB';
				|ru = 'Подакцизный разбираемый комплект произведен организацией и облагается акцизом';
				|en = 'Excisable disassembled kit is produced by the company and is subject to excise'; fa = 'Excisable disassembled kit is produced by the company and is subject to excise';
				|it = 'Excisable disassembled kit is produced by the company and is subject to excise';
				|pl = 'Excisable disassembled kit is produced by the company and is subject to excise';
				|tr = 'Tüketim vergisine tabi demonte set, iş yeri tarafından üretilir ve tüketim vergisine tabidir'");
	Else
		Items.SubjectToExcise.Title =
			NStr("vi = 'Bộ sản phẩm chịu thuế TTĐB do doanh nghiệp sản xuất và chịu thuế TTĐB';
				|ru = 'Подакцизный комплект произведен организацией и облагается акцизом';
				|en = 'Excisable kit is produced by the company and is subject to excise'; fa = 'کیت مشمول مالیات غیرمستقیم توسط شرکت تولید شده و مشمول مالیات غیرمستقیم است';
				|it = 'Excisable kit is produced by the company and is subject to excise';
				|pl = 'Excisable kit is produced by the company and is subject to excise';
				|tr = 'Tüketim vergisine tabi set, iş yeri tarafından üretilir ve tüketim vergisine tabidir'");
	EndIf;
	SetDesignOfQualityControlFields();

EndProcedure

&AtServer
Procedure SetDesignOfQualityControlFields()
	
	ThisIsBuild = (Object.BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents);
	Items.GoodsToControlQuality.Visible = Not ThisIsBuild;
	Items.GoodsQualityConfirmationDate.Visible = Not ThisIsBuild;
	Items.GoodsGroupCheckQualityBefore.Visible = Not ThisIsBuild;
	Items.ToControlQuality.Visible = ThisIsBuild;
	Items.QualityConfirmationDate.Visible = ThisIsBuild;
	Items.GroupCheckQualityBefore.Visible = ThisIsBuild;
	Items.QualityConfirmationDate.Enabled = Object.ToControlQuality;
	Items.QualityConfirmationDate.AutoMarkIncomplete = Object.ToControlQuality;
	
EndProcedure

&AtServer
Procedure ConfigurePickUpByOrdersOrdersCommand()
	
	ParametersStructure = New Structure("AdvancedWarehousingOnShipment, OrdersUse, UseInvoicesForSeveralOrders",
		AdvancedWarehousingOnShipment Or AdvancedWarehousingOnGoodsReceipt,
		ValueIsFilled(Object.ByAssemblyDisassemblyOrder),
		False);
	
	InvoicesServer.ConfigurePickUpByOrdersOrdersCommand(Items.GoodsSelectGoodsByOrdersNotes, ParametersStructure);
	
	If Object.Patch Then
		Items.GoodsSelectGoodsByOrdersNotes.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfFormElementsByOrder()

	ThereIsOrder = ValueIsFilled(Object.ByAssemblyDisassemblyOrder);

	TMCommonUseClientServer.SetFormItemProperty(Items,
				"SelectGoods", "Visible", Not ThereIsOrder);

	TMCommonUseClientServer.SetFormItemProperty(Items,
				"GoodsImportDataFromPDT", "Visible", Not ThereIsOrder);

	TMCommonUseClientServer.SetFormItemProperty(Items,
				"GoodsSearchByBarcode", "Visible", Not ThereIsOrder);

	If ThereIsOrder Then

		ItemArray = New Array;

		ItemArray.Add("GoodsAdd");
		ItemArray.Add("GoodsCopy");
		ItemArray.Add("ProductsContextMenuAdd");
		ItemArray.Add("ProductItemsContextMenuCopy");
		
		TMCommonUseClientServer.SetPropertyOfFormElements(Items,
				ItemArray, "Enabled", False);

	EndIf;

EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	RestrictGoodsReceiptWithoutCCDNumbers = GetFunctionalOption("RestrictGoodsReceiptWithoutCCDNumbers");
	UseExcisableGoods = GetFunctionalOption("UseExcisableGoods");
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.AssemblyFromComponents));
	Items.GroupInformationRequiredStatuses.Visible = DisplayMessageOnUsingStatuses();
	
	FillInServiceDetailsForProductRange();
	
	UpdateAssemblyForActivity(False);
	
	Warehouse = Object.Warehouse;
	AdvancedWarehousingOnShipment = WarehousesServer.UseWarehouseManagemantSystemForGoodsIssue(Warehouse, Object.Date);
	AdvancedWarehousingOnGoodsReceipt = WarehousesServer.UseWarehouseManagemantSystemForGoodsReceipt(Warehouse, Object.Date);
	If Parameters.Property("CheckResults") And Parameters.CheckResults.ThereAreWarnings Then
		CommonClientServer.MessageToUser(Parameters.CheckResults.WarningText);
	EndIf;
	
	LinesOfBusinessServer.OnReadCreateAtServer(ThisObject);
	CacheQualityControl = QualityControl.DataCacheOfMechanism(Object);
	FormItemsManagement();
	ConfigurePickUpByOrdersOrdersCommand();
	CustomizeSeriesItems();
	SetAvailabilityOfFormElementsByOrder();
	SetAvailabilityOfKitItemsInHeader();
	
	SetVisibilityOfCommandsByOrder();
	
EndProcedure

&AtServer
Function PutGoodsAndStockTypesInStorage()
	
	OptionsForEditingInventoryTypes = InventoriesServer.OptionsForEditingInventoryTypes();
	OptionsForEditingInventoryTypes.ProductInHeader = Object.BusinessOperation = Enums.BusinessTransactions.DisassemblyIntoComponents;
	OptionsForEditingInventoryTypes.NameTSTypesOfStocks = "InventoryOwnerAttributesConsumption";
	If Documents.AssemblyFromComponents.ExcisableGoodsAreUsed(Object) Then
		OptionsForEditingInventoryTypes.UseExcisableGoods = True;
	EndIf;
	Return InventoriesServer.PutGoodsAndStockTypesInStorage(ThisObject, OptionsForEditingInventoryTypes);
	
EndFunction

&AtServer
Procedure GetStockTypesFromStorage(ValueSelected)
	
	InventoriesServer.ProcessInputOfInventoryTypesManually(ValueSelected, ThisForm);
	
EndProcedure

&AtClientAtServerNoContext
Function AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions)

	StructureOfActions.Insert("RecalculateNumberOfUnits");

EndFunction

&AtServer
Procedure UpdateAssemblyForActivity(Fill = True)
	
	FillParameters = Documents.AssemblyFromComponents.ParametersForFillingInVATActivityType(Object);
	
	If Fill Then
		
		VATAccountingERP.FillInTypeOfActivityVAT(
			Object.AssemblyForActivity,
			FillParameters,
			VATAccountingCachedParameterValues);
		
	EndIf;
	
	VATAccountingERP.FillInActivitySelectionList(
		Items.AssemblyForActivity,
		Object.AssemblyForActivity,
		FillParameters,
		VATAccountingCachedParameterValues);
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsForProductRange()
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute",
											New Structure("Products", "ItemVariantsAreUsed"));
	ParametersForFillingInBankingDetails.Insert("FillInArticleAttribute",
											New Structure("Products", "SKU"));
	ParametersForFillingInBankingDetails.Insert("FillInCCDTrackingAttribute",
											New Structure("Products", "TheRecordsAreKeptByCCD"));
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_",
											New Structure("Products", "ItemsType"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods,ParametersForFillingInBankingDetails);
	
	RecalculatePercentageShareOfValue();
	
EndProcedure

&AtClient
Procedure FillInMainComponent(ComponentProducts, ComponentCharacteristics, CCDAccounting, Delete = False)
	ClearComponent = (ComponentProducts = Object.ProductsOfMainComponent)
		And (ComponentCharacteristics = Object.MainComponentCharacteristic);
	If ClearComponent Then
		Object.ProductsOfMainComponent = Undefined;
		Object.MainComponentCharacteristic = Undefined;
		TheMainComponentIsAccountedForByTheGasTurbineEngine = False;
	ElsIf Not Delete Then
		Object.ProductsOfMainComponent = ComponentProducts;
		Object.MainComponentCharacteristic = ComponentCharacteristics;
		TheMainComponentIsAccountedForByTheGasTurbineEngine = CCDAccounting;
	EndIf;
	ViewOfTheMainComponent = ProductsClientServer.ProductPresentation(
		Object.ProductsOfMainComponent, Object.MainComponentCharacteristic);
		
	Items.MainComponentGroup.CurrentPage = 
		?(TraceableKit, Items.GroupIsTraceableSet,
		?(ValueIsFilled(Object.ProductsOfMainComponent), Items.ComponentViewGroup,
		?(TheRecordsAreKeptByCCD, Items.ComponentRequirementGroup, Items.EmptyComponentGroup)));
	Items.ComponentCommentGroup.CurrentPage =
		?(TheRecordsAreKeptByCCD And Not TheMainComponentIsAccountedForByTheGasTurbineEngine, Items.TheCommentGroupWillNotBeAGTD,
		Items.GroupWithoutComment);
	
EndProcedure

&AtServer
Procedure ConfigureMainComponent()
	
	TheMainComponentIsAccountedForByTheGasTurbineEngine =
		TMCommonUse.DefaultValuesForItemDetails(Object.ProductsOfMainComponent, "KeepRecordsByCCD").KeepRecordsByCCD;
	
	ViewOfTheMainComponent = ProductsClientServer.ProductPresentation(
		Object.ProductsOfMainComponent,
		Object.MainComponentCharacteristic);
		
	If ValueIsFilled(Object.Products) Then
		If TraceableKit Then
			Page = Items.GroupIsTraceableSet;
		ElsIf ValueIsFilled(Object.ProductsOfMainComponent) Then
			Page = Items.ComponentViewGroup;
		Else
			If TheRecordsAreKeptByCCD Then
				Page = Items.ComponentRequirementGroup;
			Else
				Page = Items.EmptyComponentGroup;
			EndIf;
		EndIf;
	Else
		Page = Items.GroupNotFilledSet;
	EndIf;
	
	Items.MainComponentGroup.CurrentPage = Page;
	
	If TheRecordsAreKeptByCCD And Not TheMainComponentIsAccountedForByTheGasTurbineEngine Then
		Items.ComponentCommentGroup.CurrentPage = Items.TheCommentGroupWillNotBeAGTD;
	Else
		Items.ComponentCommentGroup.CurrentPage = Items.GroupWithoutComment;
	EndIf;
	
	Catalogs.PackagesAndUnitsOfMeasure.DisplayInformationAboutStorageUnit(Object.Products, Items.Package);
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfKitItemsInHeader()
	
	StructureOfData = New Structure("Products, ItemsType, ItemVariantsAreUsed, TheRecordsAreKeptByCCD");
	StructureOfData.Products = Object.Products;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_",            New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInCCDTrackingAttribute",           New Structure("Products", "TheRecordsAreKeptByCCD"));
	
	ProductsServer.FillInServiceDetailsForProductInStructure(StructureOfData, StructureOfActions);
	
	If StructureOfData.ItemsType = Enums.ItemsTypes.OwnGoods Then
		Items.Purpose.Enabled = True;
		Items.Purpose.InputHint = NStr("vi = '<không mục đích>';
										|ru = '<без назначения>';
										|en = '<without assignment>'; fa = '<بدون تخصیص>';
										|it = '<senza assegnazione>';
										|pl = '<bez przeznaczenia>';
										|tr = '<atama olmadan>'");
	Else
		Items.Purpose.Enabled = False;
		Items.Purpose.InputHint = NStr("vi = '<cho hàng hóa>';
										|ru = '<для товаров>';
										|en = '<for goods>'; fa = '<for goods>';
										|it = '<per le merci>';
										|pl = '<dla towarów>';
										|tr = '<ürünler için>'");
	EndIf;
	
	If StructureOfData.ItemVariantsAreUsed Then
		Items.Characteristic.Enabled = True;
		Items.Characteristic.InputHint = "";
	Else
		Items.Characteristic.Enabled = False;
		Items.Characteristic.InputHint = NStr("vi = '<không sử dụng đặc tính>';
												|ru = '<характеристики не используются>';
												|en = '<variants are not used>'; fa = '<گونه‌ها استفاده نمی‌شوند>';
												|it = '<le caratteristiche non vengono usate>';
												|pl = '<charakterystyki nie dotyczą>';
												|tr = '<varyantlar kullanılmamaktadır>'");
	EndIf;
	
	TheRecordsAreKeptByCCD = StructureOfData.TheRecordsAreKeptByCCD;
	Items.GoodsTheRecordsAreKeptByCCD.Visible = TheRecordsAreKeptByCCD
		Or Object.BusinessOperation = Enums.BusinessTransactions.DisassemblyIntoComponents;
	
	TraceableKit =
			TMCommonUse.DefaultValuesForItemDetails(Object.Products, "TracedGoods").TracedGoods;
	
	ConfigureMainComponent();
	
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

&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	PropertyManager.FillAdditionalAttributesInForm(ThisObject);
EndProcedure
// End StandardSubsystems.Properties

&AtServer
Procedure UpdateElementsOfAccountingForExcisableItems(ToUpdateData = True)
	
	ExciseInventoryIsAvailable =
		ExcisableGoodsAccounting.ThisIsExcisableProduct(Object.Products, Object.Organization, Object.Date)
		And ExcisableGoodsAccounting.ProductionOfExcisableItemsIsUsed(Object.Organization, Object.Date);
	Items.SubjectToExcise.ReadOnly = Not ExciseInventoryIsAvailable;
	Items.BusinessUnitProduction.ReadOnly = Not ExciseInventoryIsAvailable
		Or Not Object.SubjectToExcise;
	
	If ToUpdateData And Not ExciseInventoryIsAvailable Then
		Object.SubjectToExcise = False;
		Object.BusinessUnitProduction = Undefined;
	EndIf;
	
EndProcedure

#EndRegion

#Region WorkingWithClipboard

&AtServer
Procedure CopyLinesOnServer()
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object.Goods, Items.Goods.SelectedRows);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboard()
	
	FilterParameters = New Map;
	FilterParameters.Insert("Products.ItemsType", ProductsClientServer.SelectionByProductMultiTurnContainer(False));
	
	Columns = "Products,Characteristic,Package,NumberOfPackages";
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation",
		QualityControlClientServer.CacheByKey(CacheQualityControl, "Goods"));
	
	AddedProducts = New Array();
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		AddedProducts.Add(CurrentRow);
		FillPropertyValues(CurrentRow, RowOfProduct);

	EndDo;

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		AddedProducts,
		StructureOfActions,
		Object.Goods);
	
	FillInServiceDetailsForProductRange();

	StructureOfActions = New Structure;
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		AddedProducts,
		StructureOfActions,
		Object.Goods);
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters.TS);
EndProcedure

&AtServer
Procedure SetAvailabilityOfClipboardCommands()
	
	ItemArray = New Array();
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled",
		ProcessingOfTabularForms.ThereAreLinesInClipboard() And Not ValueIsFilled(Object.ByAssemblyDisassemblyOrder));
	
EndProcedure

&AtClient
Procedure SetAvailabilityOfClipboardCommandsOnClient()
	
	ItemArray = New Array();
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled",
		Not ValueIsFilled(Object.ByAssemblyDisassemblyOrder));
	
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
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure CloseOrder(Command)
	
	If Modified Or Not Object.Posted Then
		Response = Undefined;
		ShowQueryBox(New CallbackDescription("CloseOrderCompletion", ThisObject),
			NStr("vi = 'Cần kết chuyển chứng từ để thực hiện giao dịch. Kết chuyển chứng từ?';
				|ru = 'Необходимо провести документ для выполнения операции. Провести документ?';
				|en = 'To proceed, you need to post the document. Do you want to post the document?'; fa = 'To proceed, you need to post the document. Do you want to post the document?';
				|it = 'È necessario registrare il documento per eseguire operazione. Registrare documento?';
				|pl = 'Należy zaksięgować dokument aby wykonać operację. Zaksięgować dokument?';
				|tr = 'Bir işlemin gerçekleştirilmesi için belgenin kaydedilmesi gerekir. Belge kaydedilsin?'"), QuestionDialogMode.YesNo);
		Return;
	EndIf;
	
	CloseOrderFragment();

EndProcedure

&AtClient
Procedure CloseOrderFragment()
	
	ListOfOrdersToClose = New ValueList;
	ListOfOrdersToClose.Add(Object.ByAssemblyDisassemblyOrder);
	
	ClosureStructure = New Structure;
	ClosureStructure.Insert("Orders",                       ListOfOrdersToClose);
	ClosureStructure.Insert("DocumentInitiator",            Object.Ref);
	ClosureStructure.Insert("CancelUnprocessedLines", True);
	ClosureStructure.Insert("CloseOrders",              True);
	
	OpenForm("DataProcessor.OrderClosureWizard.Form.ClosureForm",
		ClosureStructure, ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure CloseOrderCompletion(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	If Response = DialogReturnCode.No Then
		Return;
	ElsIf Not Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
		Return;
	EndIf;
	
	CloseOrderFragment();
	
EndProcedure

&AtServer
Procedure SetVisibilityOfCommandsByOrder()
	
	Items.CloseOrder.Visible = ValueIsFilled(Object.ByAssemblyDisassemblyOrder);
	
EndProcedure

#EndRegion

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
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
	If Item.Name = "sh_ShamsiInput_Date" Then
		DateOnChange(Items.Date);
	ElsIf Item.Name = "sh_ShamsiInput_DateOfReceipt" Then
		DateOfReceiptOnChange(Items.DateOfReceipt);
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
