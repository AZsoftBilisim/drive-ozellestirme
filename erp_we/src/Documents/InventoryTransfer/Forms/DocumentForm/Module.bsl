#Region Variables

&AtClient
Var CachedValues;

&AtClient
Var CurDataId; //used to pass the current line to the wait handler

&AtClient
Var PreviousRowDetails; //used to unlink the transfer line from the order line

&AtClient
Var ParametersForRecording Export;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisForm);
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	Items.BaseGroup_.Visible = ValueIsFilled(Object.DocumentBasis);
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
		Items.PictureDiscrepancyOrder.Picture = New Picture();
		Items.PictureDiscrepancyOrders.Picture = New Picture();
		
	ElsIf Parameters.FillingValues.Property("FillByWarehouseDocument") Then
		
		RefillByNotes(Parameters.FillingValues.AnArrayOfOrders);
		Modified = True;
		
	EndIf;
	
	FillOperationSelectionList();
	
	Items.CloseOrder.Enabled = AccessRight("Update",Metadata.Documents.TransferOrder);
	
	SetAvailabilityOfClipboardCommands();
	
	ElementsToFillIn = New Array;
	ElementsToFillIn.Add(Items.DeliveryTimeFrom);
	ElementsToFillIn.Add(Items.DeliveryTimeTo);
	ElementsToFillIn.Add(Items.DeliveryTimeFrom1);
	ElementsToFillIn.Add(Items.DeliveryTimeTo1);
	GoodsDeliveryClientServer.FillTimeFieldSelectionList(ElementsToFillIn);
	
	DocumentCorrection.OnCreateAtServer(ThisForm, Items.LineCorrection);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	Items.EPDStateGroup.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// Standard subsystems.Accounting of the originals of the first documents
	SourceDocumentsOriginalsRecording.OnCreateAtServerDocumentForm(ThisObject);
	// The end of the standard subsystem.Accounting of the originals of the first documents 

	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	ControlledLotReferenceLinkNew = Catalogs.ControlledLots.GetRef();
	DocumentCorrection.OnReadAtServer(ThisForm, Items.LineCorrection);
	
	FormItemsManagement();
	EstablishVisibilityOfQualityControlGroup();
	CacheQualityControl = QualityControl.DataCacheOfMechanism(Object);
	
	// Caching the values of functional options.
	UseTransferAgainstSeveralOrders = GetFunctionalOption("UseTransferAgainstSeveralOrders");
	UseTransferOrders = GetFunctionalOption("UseTransferOrders");
	UseMultipleCompanies = GetFunctionalOption("UseMultipleCompanies");
	UseBusinessUnits = GetFunctionalOption("UseBusinessUnits");
	UseTransportationJobsForDeliveryAccountingByCarriers = GetFunctionalOption("UseTransportationJobsForDeliveryAccountingByCarriers");
	
	SetPrivilegedMode(True);
	
	AdvancedWarehousingOnShipment = WarehousesServer.UseWarehouseManagemantSystemForGoodsIssue(Object.SourceWarehouse, Object.Date);
	
	SetPrivilegedMode(False);
	
	ThisIsAReferenceInvoice = ThisIsAReferenceInvoice(Object.Ref, AdvancedWarehousingOnShipment);
	If Parameters.Property("CheckResults") And Parameters.CheckResults.ThereAreWarnings Then
		CommonClientServer.MessageToUser(Parameters.CheckResults.WarningText);
	EndIf;

	FillInServiceDetailsForProductRange();
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.InventoryTransfer));
	Items.GroupInformationRequiredStatuses.Visible = DisplayMessageOnUsingStatuses();
	SetVisibilityOfSeriesElements();
	
	UpdateOrderInformation();
	UpdateOrderDeviations();
	
	Items.PictureDiscrepancyOrder.Picture = New Picture();
	Items.PictureDiscrepancyOrders.Picture = New Picture();
	
	If Not UseTransferOrders Then
		Items.PictureDiscrepancyOrder.Visible = False;
		Items.PictureDiscrepancyOrders.Visible = False;
	EndIf;
	
	Items.SalesOpportunity.Visible = Not (UseTransferAgainstSeveralOrders And Object.TransferAgainstOrders);
	Items.GoodsSalesOpportunity.Visible = UseTransferAgainstSeveralOrders And Object.TransferAgainstOrders;
	ConfigurePickUpByOrdersOrdersCommand();
	
	SetVisibilityOfItemsOverOrder(Items, Object.TransferAgainstOrders);
	
	SourceWarehouse = Object.SourceWarehouse;
	DestinationWarehouse  = Object.DestinationWarehouse;
	
	GoodsDelivery.WhenReadingCreatingOrdersOnServer(Items,Object, Object.TransferAgainstOrders);
	
	CurrentDeliveryMethod = Object.DeliveryMethod;
	
	UpdateTextDocumentsBasedOn();
	
	UpdateDependentDetailsOfServerByOrderForm();
	SetVisibilityOfCommandsByOrder();
	
	UpdateMovementUnderActivity(False);
	ProcessingOfTabularForms.InitializeRowCache(Items.Goods);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement

	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	OnReadCreateAtServer();

	// Subsystem "Properties"
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	Var CurrentOperation1;
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.InventoryTransfer.DocumentForm.Event.ChoiceProcessing");
	
	If TypeOf(ValueSelected) = Type("Structure") And ValueSelected.Property("CurrentOperation1", CurrentOperation1) Then

		If Upper(CurrentOperation1) = Upper("AddItemsFromSalesOrderGoodsIssue") Then

			ProcessingProductSelectionFromOrder(ValueSelected.AddressInStorage);

		EndIf;

	ElsIf ChoiceSource.FormName = "DataProcessor.SelectGoodsToSalesDocument.Form.Form" Then

		ProcessingSelectionOfSelectionOnServer(ValueSelected);

	ElsIf ChoiceSource.FormName = "CommonForm.PrintingDetailsOfSales" Then
		
		If ValueSelected <> Undefined Then
			FillPropertyValues(Object, ValueSelected);
		EndIf;
		
	ElsIf ChoiceSource.FormName = "Catalog.InventoryKinds.Form.InventoryOwnerAttributesForm" Then	
		
		GetStockTypesFromStorage(ValueSelected);
		
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectReusablePackage.Form.Form" Then
		
		FillMultiTurnContainersFromStorageServer(ValueSelected.AddressOfReusableContainerInStorage);
		ReusablePackageClient.NotifyUserAboutFillingMultiTurnContainers();
		
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);
		
	EndIf;

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	ReportResults();
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	PreviousRowDetails = New Structure(
		"Products,
		|Characteristic,
		|Package,
		|Count,
		|NumberOfPackages,
		|Warehouse,
		|ItemsType,
		|ItemVariantsAreUsed,
		|SKU,
		|TransferOrder,
		|RowCode");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	

EndProcedure

&AtClient
Procedure OnClose()
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	UpdateOrderDeviations();
	
	FillInServiceDetailsForProductRange();
	
	CurrentDeliveryMethod = CurrentObject.DeliveryMethod;
	

	FormEvents.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Subsystem "Properties"
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
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
	
	If EventName = "Write_GoodsIssueNote" Then
		ThisIsAReferenceInvoice = ThisIsAReferenceInvoice(Object.Ref, AdvancedWarehousingOnShipment);
	EndIf;
	
	If EventName = "Closing_EditingSet"
		And Parameter.OwnerForm = UUID Then
		AtEndOfEditingSet(Parameter.AddressInTempStorage);
	EndIf;
	
	If EventName = "EditSet"
		And Parameter.OwnerForm = UUID Then
		
		SetParameters = New Structure;
		SetParameters.Insert("ProductsInSet", Parameter.ProductsInSet);
		SetParameters.Insert("ItemVariantOfSet", Parameter.ItemVariantOfSet);
		SetParameters.Insert("ExceedingOrder", True);
		SetParameters.Insert("DialColumns", DialColumns(ThisObject));
		
		SetAddressInTemporaryStorage = SetAddressInTemporaryStorage(SetParameters);
		
		OpeningParameters = New Structure;
		OpeningParameters.Insert("AddressInTempStorage", SetAddressInTemporaryStorage);
		OpeningParameters.Insert("ProductsInSet",   Parameter.ProductsInSet);
		OpeningParameters.Insert("ItemVariantOfSet", Parameter.ItemVariantOfSet);
		OpeningParameters.Insert("Date", Object.Date);
		OpeningParameters.Insert("Ref", Object.Ref);
		OpeningParameters.Insert("Warehouse", Object.SourceWarehouse);
		OpeningParameters.Insert("HideCommandRemainingQuantityInWarehouses", False);
		OpeningParameters.Insert("Organization", Object.Organization);
		OpeningParameters.Insert("ProhibitPriceEditing", True);
		OpeningParameters.Insert("HideSetPrice", True);
		
		OpenForm("DataProcessor.EditSet.Form.Form", OpeningParameters, ThisObject, UUID);
		
	EndIf;
	
	DocumentCorrectionClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);

	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	NotificationProcessingLocalization(EventName, Parameter, Source);	
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording	
	SourceDocumentsOriginalsRecordingClient.NotificationHandlerDocumentForm(EventName,ThisObject);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)
	
	FormEventsClient.URLProcessing(ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	NotifyAboutDocument(WriteParameters);
	
	FormEventsClient.AfterWrite(ThisObject, WriteParameters);
	

	DocumentCorrectionClient.AfterWrite(Object);
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisForm, Object, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
	If NotExecuteCheck1BeforeWrite Then
		NotExecuteCheck1BeforeWrite = False;
		Return;
	EndIf;
	
	If WriteParameters.WriteMode = DocumentWriteMode.Posting 
		And Not Object.TransferAgainstOrders Then
		
		Cancel = True;
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("WriteParameters", WriteParameters);
		
		ReusablePackageClient.OfferToPickUpMultiTurnContainer(
			ThisForm,
			"Goods",
			"Products,Characteristic,Count",
			New CallbackDescription("BeforeRecordingOfferToPickUpMultiTurnContainer", ThisObject, AdditionalParameters));
		Return;
	EndIf;
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters, Cancel);
	
EndProcedure

&AtClient
Procedure BeforeRecordingOfferToPickUpMultiTurnContainer(Result, AdditionalParameters) Export
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, AdditionalParameters.WriteParameters,,True);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	// Handler of the "Properties" mechanism
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
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
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If CurrentPage.Name = "AdvancedGroup"
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure DestinationWarehouseOnChange(Item)
	
	ClearLines_ = False;
	UntieAllLinesFromOrder = False;
	
	If DestinationWarehouse <> Object.DestinationWarehouse Then
		
		If Object.TransferAgainstOrders
			And Object.Goods.Count() > 0 Then
			
			ButtonsList = New ValueList();
			
			ButtonsList.Add("Continue", NStr("vi = 'Xóa hàng hóa';
											|ru = 'Очистить товары';
											|en = 'Clear goods'; fa = 'Clear goods';
											|it = 'Cancellare le merci';
											|pl = 'Oczyść wiersze pozycji';
											|tr = 'Ürünleri temizle'"));
			ButtonsList.Add("Unlink", NStr("vi = 'Bỏ khỏi đơn hàng';
											|ru = 'Отвязать от заказа';
											|en = 'Unlink from order'; fa = 'جدا کردن از سفارش';
											|it = 'Scollegare dall''ordine';
											|pl = 'Odłącz od zamówienia';
											|tr = 'Siparişten ayır'"));
			QueryText = NStr("vi = 'Khi thay đổi kho, cần xóa danh sách ""Hàng hóa"" hoặc bỏ liên kết dòng với đơn hàng. Tiếp tục?';
							|ru = 'При изменении склада список ""Товары"" необходимо очистить, либо отвязать строки от заказа. Продолжить?';
							|en = 'It is required to clear the Item list or unlink lines from the order while changing the warehouse. Continue?'; fa = 'It is required to clear the Item list or unlink lines from the order while changing the warehouse. Continue?';
							|it = 'Al cambio del magazzino, l''elenco ""Merci"" deve essere cancellato o le righe devono essere scollegate dall''ordine. Continuare?';
							|pl = 'Po zmianie magazynu lista ""Wiersze pozycji"" musi zostać wyczyszczona lub należy odłączyć wiersze od zamówienia. Kontynuować?';
							|tr = 'Ambar değiştiğinde, ""Ürünler"" listesinin temizlenmesi veya satırların siparişten ayrılması gerekir. Devam edilsin mi?'");
			
			ButtonsList.Add("Cancel", NStr("vi = 'Hủy bỏ';
											|ru = 'Отмена';
											|en = 'Cancel'; fa = 'انصراف';
											|it = 'Annulla';
											|pl = 'Cancel';
											|tr = 'İptal'"));
			
			ShowQueryBox(New CallbackDescription("DestinationWarehouseOnChangeCompletion", ThisObject, New Structure("UntieAllLinesFromOrder", UntieAllLinesFromOrder)), QueryText, ButtonsList);
			
		Else
			DestinationWarehouseOnChangeServer(UntieAllLinesFromOrder, ClearLines_, CachedValues, True);
		EndIf;
		
	EndIf;

EndProcedure

&AtClient
Procedure DestinationWarehouseOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	UntieAllLinesFromOrder = AdditionalParameters.UntieAllLinesFromOrder;
	Response = QuestionResult;
	If Response = "Cancel" Then
		Object.DestinationWarehouse = DestinationWarehouse;
		Return;
	ElsIf Response = "Unlink" Then
		UntieAllLinesFromOrder = True;
		ClearLines_ = False;
	Else
		ClearLines_ = True;
	EndIf;
	
	DestinationWarehouseOnChangeServer(UntieAllLinesFromOrder, ClearLines_, CachedValues, True);
	
EndProcedure

&AtClient
Procedure SourceWarehouseOnChange(Item)
	
	ClearLines_ = False;
	UntieAllLinesFromOrder = False;
	
	If SourceWarehouse <> Object.SourceWarehouse Then
		
		If Object.TransferAgainstOrders
			And Object.Goods.Count() > 0 Then
			
			ButtonsList = New ValueList();
			
			ButtonsList.Add("Continue", NStr("vi = 'Xóa hàng hóa';
											|ru = 'Очистить товары';
											|en = 'Clear goods'; fa = 'Clear goods';
											|it = 'Cancellare le merci';
											|pl = 'Oczyść wiersze pozycji';
											|tr = 'Ürünleri temizle'"));
			ButtonsList.Add("Unlink", NStr("vi = 'Bỏ khỏi đơn hàng';
											|ru = 'Отвязать от заказа';
											|en = 'Unlink from order'; fa = 'جدا کردن از سفارش';
											|it = 'Scollegare dall''ordine';
											|pl = 'Odłącz od zamówienia';
											|tr = 'Siparişten ayır'"));
			QueryText = NStr("vi = 'Khi thay đổi kho, cần xóa danh sách ""Hàng hóa"" hoặc bỏ liên kết dòng với đơn hàng. Tiếp tục?';
							|ru = 'При изменении склада список ""Товары"" необходимо очистить, либо отвязать строки от заказа. Продолжить?';
							|en = 'It is required to clear the Item list or unlink lines from the order while changing the warehouse. Continue?'; fa = 'It is required to clear the Item list or unlink lines from the order while changing the warehouse. Continue?';
							|it = 'Al cambio del magazzino, l''elenco ""Merci"" deve essere cancellato o le righe devono essere scollegate dall''ordine. Continuare?';
							|pl = 'Po zmianie magazynu lista ""Wiersze pozycji"" musi zostać wyczyszczona lub należy odłączyć wiersze od zamówienia. Kontynuować?';
							|tr = 'Ambar değiştiğinde, ""Ürünler"" listesinin temizlenmesi veya satırların siparişten ayrılması gerekir. Devam edilsin mi?'");
			
			ButtonsList.Add("Cancel", NStr("vi = 'Hủy bỏ';
											|ru = 'Отмена';
											|en = 'Cancel'; fa = 'انصراف';
											|it = 'Annulla';
											|pl = 'Cancel';
											|tr = 'İptal'"));
			
			ShowQueryBox(New CallbackDescription("SourceWarehouseOnChangeCompletion", ThisObject, New Structure("UntieAllLinesFromOrder", UntieAllLinesFromOrder)), QueryText, ButtonsList);
			
		Else
			SourceWarehouseOnChangeServer(UntieAllLinesFromOrder, ClearLines_, CachedValues);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SourceWarehouseOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	UntieAllLinesFromOrder = AdditionalParameters.UntieAllLinesFromOrder;
	Response = QuestionResult;
	If Response = "Cancel" Then
		Object.SourceWarehouse = SourceWarehouse;
		Return;
	ElsIf Response = "Unlink" Then
		UntieAllLinesFromOrder = True;
		ClearLines_ = False;
	Else
		ClearLines_ = True;
	EndIf;
	
	SourceWarehouseOnChangeServer(UntieAllLinesFromOrder, ClearLines_, CachedValues);
	
EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	
	If SeriesSpecificationParameters.UseItemsBatch Then
		FillInShippingInstructions = False;
		
		If YouCanPopulateSeriesByShipment
			And Object.Status = PredefinedValue("Enum.GoodsTransferStatuses.Accepted") Then
			
			CallbackDescription = New CallbackDescription("StatusOnChangeCompletion", ThisObject);
			QueryText = NStr("vi = 'Điền sê-ri theo dữ liệu phiếu xuất kho?';
							|ru = 'Заполнить серии по данным расходных ордеров?';
							|en = 'Fill in batch according to goods issue note data?'; fa = 'Fill in batch according to goods issue note data?';
							|it = 'Compilare le serie in base ai dati dei mandati di pagamento?';
							|pl = 'Uzupełnij serię zgodnie z danymi zestawień wydatków?';
							|tr = 'Ambar çıkış fişlerine göre partiler doldurulsun mu?'");
			
			ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
			
			Return;
			
		EndIf;
		
		If CachedValues <> Undefined Then
			CachedValues.Barcodes.Clear();
		EndIf;
		
		StatusOnChangeServer(FillInShippingInstructions);
	EndIf;
	
EndProcedure

&AtClient
Procedure StatusOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	FillInShippingInstructions = False;
	
	If QuestionResult = DialogReturnCode.Yes Then
		FillInShippingInstructions = True;
	EndIf;
	
	If CachedValues <> Undefined Then
		CachedValues.Barcodes.Clear();
	EndIf;
	
	StatusOnChangeServer(FillInShippingInstructions);
	
EndProcedure

&AtClient
Procedure HeaderOrdersTextClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	OpenForm(
		"CommonForm.ViewingListOfDocuments",
		New Structure("DocumentsList, Title",
			OrderList,
			NStr("vi = 'Đơn hàng điều chuyển nội bộ (%DocumentsCount%)';
				|ru = 'Заказы на перемещение (%DocumentsCount%)';
				|en = 'Transfer orders (%DocumentsCount%)'; fa = 'Transfer orders (%DocumentsCount%)';
				|it = 'Ordini di trasferimento (%DocumentsCount%)';
				|pl = 'Zamówienia na przesunięcie (%DocumentsCount%)';
				|tr = 'Transfer siparişleri (%DocumentsCount%)'")
		),
		ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure MovingAnOrderWhenItChanges(Item)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.InventoryTransfer.DocumentForm.Item.OrderInvoice_3.OnChange");
	
	SetAvailabilityOfClipboardCommandsOnClient();
	
	If Object.TransferAgainstOrders And ThisIsAReferenceInvoice Then
		
		WarningText = NStr("vi = 'Việc chuyển từ kho xuất đã bắt đầu. Không thể thiết lập dấu hiệu.';
							|ru = 'Перемещение со склада-отправителя уже начато. Установка признака невозможна.';
							|en = 'Transfer from the origin warehouse already started. Cannot set the flag.'; fa = 'Transfer from the origin warehouse already started. Cannot set the flag.';
							|it = 'Il trasferimento dal magazzino-mittente è già iniziato. Impossibile impostare un criterio.';
							|pl = 'Przeniesienie z magazynu nadawcy już rozpoczęte. Ustawianie znaku nie jest możliwe.';
							|tr = 'Çıkış ambarından transfer artık başladı. Bayrağı ayarlamak mümkün değil.'");
		ShowMessageBox(, WarningText);
		Object.TransferAgainstOrders = False;
		Return;
		
	EndIf;
	
	If Object.TransferAgainstOrders Then
		
		If UseTransferAgainstSeveralOrders Then
			
			If Object.Goods.Count() = 0 Then
				QueryText = NStr("vi = 'Danh sách Hàng hóa sẽ được điền lại bằng số dư hàng hóa chưa lập theo đơn hàng. Tiếp tục?';
								|ru = 'Список Товары будет перезаполнен остатками неоформленных товаров по заказам. Продолжить?';
								|en = 'The Item list will be refilled by remaining unregistered goods against orders. Continue?'; fa = 'The Item list will be refilled by remaining unregistered goods against orders. Continue?';
								|it = 'L''elenco Merci sarà ricompilato con giacenze delle merci non formalizzate per ordini. Continuare?';
								|pl = 'Lista Wiersze pozycji zostanie ponownie wypełniona przez resztki nieodebranych towarów z zamówień. Kontynuować?';
								|tr = 'Ürünler listesi siparişe ilişkin düzenlenmemiş ürünlerin bakiyeleri ile yeniden doldurulacaktır. Devam edilsin mi?'");
			Else
				QueryText = NStr("vi = 'Dòng trong danh sách Hàng hóa sẽ được gắn với dòng của đơn hàng. Tiếp tục?';
								|ru = 'Строки в списке Товары будут привязаны к строкам заказов. Продолжить?';
								|en = 'The Item list lines will be linked with the order lines. Continue?'; fa = 'The Item list lines will be linked with the order lines. Continue?';
								|it = 'Le righe nell''elenco ""Merci"" saranno associate alle righe degli ordini. Continuare?';
								|pl = 'Wiersze na liście Wiersze pozycji będą powiązane z wierszami zamówień. Kontynuować?';
								|tr = 'Ürünler listesindeki satırlar sipariş satırlarına bağlanacaktır. Devam edilsin mi?'");
			EndIf;
			
		Else
			
			FilterParameters = New Structure();
			FilterParameters.Insert("Organization",      Object.Organization);
			FilterParameters.Insert("Department",    Object.Department);
			FilterParameters.Insert("SourceWarehouse", Object.SourceWarehouse);
			FilterParameters.Insert("DestinationWarehouse",  Object.DestinationWarehouse);
			
			FormParameters = New Structure("Filter, Recorder", FilterParameters, Object.Ref);
			CallbackDescription = New CallbackDescription("MoveByOrderSetOrderSelected", ThisObject); //fills in the "Products" list
			OpenForm("Document.InventoryTransfer.Form.ReferenceChoiceForm",
				FormParameters, ThisForm, UUID,,, CallbackDescription);
			Return;
			
		EndIf;
		
	Else
		
		If Object.Goods.Count() > 0 Then
			If UseTransferAgainstSeveralOrders Then
				QueryText = NStr("vi = 'Dòng trong danh sách Hàng hóa không còn liên kết với dòng trong đơn hàng. Tiếp tục?';
								|ru = 'Строки в списке Товары перестанут быть связанными со строками заказов. Продолжить?';
								|en = 'The Item list lines will be unlinked from the lines in the orders. Continue?'; fa = 'The Item list lines will be unlinked from the lines in the orders. Continue?';
								|it = 'Le righe nell''elenco Merci non saranno più associate alle righe degli ordini. Continuare?';
								|pl = 'Wiersze na liście Wiersze pozycji nie będą więcej powiązane z wierszami zamówień. Kontynuować?';
								|tr = 'Ürünler listesindeki satırlar artık sipariş satırlarına ilişkilendirilmeyecektir. Devam edilsin mi?'");
			Else
				QueryText = NStr("vi = 'Dòng trong danh sách Hàng hóa không còn liên kết với dòng trong đơn hàng. Tiếp tục?';
								|ru = 'Строки в списке Товары перестанут быть связанными со строками заказа. Продолжить?';
								|en = 'The Item list lines will be unlinked from the order lines. Continue?'; fa = 'The Item list lines will be unlinked from the order lines. Continue?';
								|it = 'Le righe nell''elenco Merci non saranno più associate alle righe dell''ordine. Continuare?';
								|pl = 'Wiersze na liście Wiersze pozycji nie będą więcej powiązane z wierszami zamówienia. Kontynuować?';
								|tr = 'Ürünler listesindeki satırlar artık sipariş satırlarına ilişkilendirilmeyecektir. Devam edilsin mi?'");
			EndIf;
		Else
			
			WhenYouChangeMovementForMultipleOrders(CachedValues);
			Return;
			
		EndIf;
		
	EndIf;
	
	ShowQueryBox(New CallbackDescription("MovingAnOrderWhenItChangesCompletion", ThisObject), QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure LockedGoodsTransferOnChange(Item)
	
	LockedGoodsTransferOnChangeServer();
	
EndProcedure

&AtClient
Procedure ControlledLotOfTheSenderOnChange(Item)
	
	ControlledLotOfTheSenderOnChangeServer();
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	BusinessOperationOnChangeServer();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	If CurrentCompany <> Object.Organization Then
		
		OrganizationOnChangeServer();
		CurrentCompany = Object.Organization;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CompanyRecipientOnChange(Item)
	RecipientOrganizationWhenModifiedOnServer();
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOnChangeServer();
	
EndProcedure

&AtClient
Procedure DecorationDeliveryServiceCreateClick(Item)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure DecorationDeliveryServiceOrderListClick(Item)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure DecorationDeliveryServiceAddToDeliveryOrderClick(Item)
	
	
EndProcedure


&AtClient
Procedure MethodPlaceOfDeliveryCarrierIfChanged(Item)
	
	MethodPlaceOfDeliveryCarrierIfChangedServer(Item.Name);
	
EndProcedure

&AtClient
Procedure DeliveryAddressOnChange(Item)
	
	ProcessAddressChange(Item, "DeliveryAddress");
	
EndProcedure

&AtClient
Procedure DeliveryAddressClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	NamesOfDetailsOfDeliveryAddresses = GoodsDeliveryClientServer.NamesOfDetailsOfDeliveryAddresses("DeliveryAddress");
	
	GoodsDeliveryClient.ClearAddressPresentation(
		Object[NamesOfDetailsOfDeliveryAddresses.NameOfDetailsOfDeliveryAddress],
		Object[NamesOfDetailsOfDeliveryAddresses.AttributeNameOfDeliveryAddressFieldValues],
		Object[NamesOfDetailsOfDeliveryAddresses.NameOfAttributeOfDeliveryAddressValue]);
	
EndProcedure

&AtClient
Procedure DeliveryAddressStartChoice(Item, ChoiceData, StandardProcessing)
	
	NamesOfDetailsOfDeliveryAddresses = GoodsDeliveryClientServer.NamesOfDetailsOfDeliveryAddresses("DeliveryAddress");
	
	GoodsDeliveryClient.OpenAddressSelectionFormAndProcessResult(
		Item,
		Object,
		NamesOfDetailsOfDeliveryAddresses,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure DeliveryAddressChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	GoodsDeliveryClient.DeliveryAddressChoiceProcessing(Items, Object, Item.Name, ValueSelected);
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure DeliveryAddressOfCarrierOnChange(Item)
	
	ProcessAddressChange(Item, "DeliveryAddressOfCarrier");
	
EndProcedure

&AtClient
Procedure DeliveryAddressOfCarrierClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	NamesOfDetailsOfDeliveryAddresses = GoodsDeliveryClientServer.NamesOfDetailsOfDeliveryAddresses("DeliveryAddressOfCarrier");
	
	GoodsDeliveryClient.ClearAddressPresentation(
		Object[NamesOfDetailsOfDeliveryAddresses.NameOfDetailsOfDeliveryAddress],
		Object[NamesOfDetailsOfDeliveryAddresses.AttributeNameOfDeliveryAddressFieldValues],
		Object[NamesOfDetailsOfDeliveryAddresses.NameOfAttributeOfDeliveryAddressValue]);
	
EndProcedure

&AtClient
Procedure DeliveryAddressOfCarrierStartChoice(Item, ChoiceData, StandardProcessing)
	
	NamesOfDetailsOfDeliveryAddresses = GoodsDeliveryClientServer.NamesOfDetailsOfDeliveryAddresses("DeliveryAddressOfCarrier");
	
	GoodsDeliveryClient.OpenAddressSelectionFormAndProcessResult(
		Item,
		Object,
		NamesOfDetailsOfDeliveryAddresses,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure DeliveryAddressOfCarrierChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	GoodsDeliveryClient.DeliveryAddressChoiceProcessing(Items, Object, Item.Name, ValueSelected);
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure TransferForActivityClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure TextDocumentsBasedOnURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	ClearMessages();
	TextDocumentsBasedOnURLProcessingLocalization(FormattedStringURL, StandardProcessing);
	
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
Procedure Attachable_OriginalStateDecorationClick()
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecordingClient.OpenStateSelectionMenu(ThisObject,Items.OriginalStateDecoration);
	//End StandardSubsystems.SourceDocumentsOriginalsRecording
	
EndProcedure

&AtClient
Procedure DecorationOfEPDClick(Item)
	
	
EndProcedure

&AtClient
Procedure DecorationToIssueEPDClick(Item, StandardProcessing)
	
	
EndProcedure

&AtClient
Procedure DateOfReceiptOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOfReceiptOnChangeServer();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure PackageOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure GoodsBeforeRowChange(Item, Cancel)
	FillPropertyValues(PreviousRowDetails, Items.Goods.CurrentData);
EndProcedure

&AtClient
Procedure GoodsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	If Object.TransferAgainstOrders 
		And CurrentRow <> Undefined Then 
		UpdateOrderDeviationsInLine(CurrentRow, Object.TransferAgainstOrders);
		
		UpdateDependentDetailsOfOrderForm_(
			Object.Goods,
			DiscrepancyOrderText,
			Items);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsPurposeOnChange(Item)

	UpdateSenderDestination();

EndProcedure

&AtClient
Procedure GoodsPurposeClearing(Item, StandardProcessing)

	UpdateSenderDestination();

EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("CurrentRow", CurrentRow);
	QuestionUserWhenChangingRowDetails(
		New CallbackDescription("GoodsNomenclatureWhenChangingQuestionToUserCompletion", ThisObject, AdditionalParameters),
		CurrentRow);
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("CurrentRow", CurrentRow);
	QuestionUserWhenChangingRowDetails(
		New CallbackDescription("GoodsCharacteristicWhenChangingQuestionToUserCompletion", ThisObject, AdditionalParameters),
		CurrentRow);
	
EndProcedure

&AtClient
Procedure NumberOfPackagesOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
	ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters, Copy);
	
EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	CurrentData = Items.Goods.CurrentData;
	
	If ProductsClient.SeriesStatusesNeedToBeUpdated(
		Item,CachedValues,SeriesSpecificationParameters) Then
		
		IDCurrentRow = CurrentData.GetID();
		
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues);	
		ProductsClient.UpdateCachedValuesToAccountForSeries(Item,CachedValues,SeriesSpecificationParameters);
		
	EndIf;
	
	ReusablePackageClient.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
	UpdateDependentDetailsOfOrderForm_(
		Object.Goods,
		DiscrepancyOrderText,
		Items);
		
	AdditionalParameters = New Structure;
	FormEventsClient.WhenChangingElement(ThisObject, Items.Goods, AdditionalParameters);
	If AdditionalParameters.Property("ServerCallRequired__") Then
		AttachIdleHandler("GoodsAtEndOfEditingForServerCall", 0.5, True);
	EndIf;

EndProcedure

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)

	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
	ProductsClient.UpdateCachedValuesToAccountForSeries(
				Item,CachedValues,SeriesSpecificationParameters);
	
	SetsClient.BeforeDeletingRowOfTablePart(ThisForm, "Goods", Cancel);
EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	
	If ProductsClient.SeriesStatusesNeedToBeUpdated(
		Item,CachedValues,SeriesSpecificationParameters,True) Then
		
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Undefined, CachedValues);
		ProductsClient.UpdateCachedValuesToAccountForSeries(
					Item,CachedValues,SeriesSpecificationParameters);
		
	EndIf;
	
	ReusablePackageClient.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
	UpdateDependentDetailsOfServerByOrderForm();
	
	GoodsAfterDeleteRowServer();

EndProcedure

&AtClient
Procedure GoodsBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	If Copy Then
		SetsClient.BeforeDeletingRowOfTablePart(ThisForm, "Goods", Cancel, True);
	EndIf;
EndProcedure

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	If Field = Items.GoodsTransferOrder Then
		If ValueIsFilled(Items.Goods.CurrentData.TransferOrder) Then
			ShowValue(Undefined, Items.Goods.CurrentData.TransferOrder);
		EndIf;
	ElsIf Field = Items.GoodsSalesOpportunity Then
		If ValueIsFilled(Items.Goods.CurrentData.SalesOpportunity) Then
			ShowValue(Undefined, Items.Goods.CurrentData.SalesOpportunity);
		EndIf;
	ElsIf SetsClient.ItemToLock(Field) Then
		
		CurrentRow = Object.Goods.FindByID(RowSelected);
		If ValueIsFilled(CurrentRow.ProductsInSet) Then
			
			NotificationParameter1 = New Structure;
			NotificationParameter1.Insert("ProductsInSet",   CurrentRow.ProductsInSet);
			NotificationParameter1.Insert("ItemVariantOfSet", CurrentRow.ItemVariantOfSet);
			NotificationParameter1.Insert("OwnerForm",        UUID);
			
			Notify("EditSet", NotificationParameter1, ThisForm);
			
		EndIf;
		
	ElsIf Field = Items.GoodsProductsInSet Then
		ShowValue(Undefined, Items.Goods.CurrentData.ProductsInSet);
	EndIf;
EndProcedure

&AtClient
Procedure GoodsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenSelectionOfSeries(Item.EditText);

EndProcedure

&AtClient
Procedure GoodsSeriesOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value            		 = CurrentRow.Series;
	ValueSelected.CurrentRowID = CurrentRow.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);

EndProcedure

&AtClient
Procedure GoodsTransferOrderStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData <> Undefined Then
		
		FilterParameters = New Structure();
		FilterParameters.Insert("Organization",      Object.Organization);
		FilterParameters.Insert("Department",    Object.Department);
		FilterParameters.Insert("SourceWarehouse", Object.SourceWarehouse);
		FilterParameters.Insert("DestinationWarehouse",  Object.DestinationWarehouse);
		
		FormParameters = New Structure("Filter, Recorder", FilterParameters, Object.Ref);
		CallbackDescription = New CallbackDescription("GoodsTransferOrderStartChoiceCompletion", ThisObject); //fills in the "Products" list
		OpenForm("Document.InventoryTransfer.Form.ReferenceChoiceForm",
			FormParameters, ThisForm, UUID,,, CallbackDescription, FormWindowOpeningMode.LockOwnerWindow);

		Return;
		
	EndIf;
	
	UpdateOrderInformation();
	
EndProcedure

&AtClient
Procedure GoodsTransferOrderStartChoiceCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	OrderSelectionProcessingOnServer(Result);
	
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

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure


&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

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

&AtClient
Procedure SpecifySeries(Command)
	
	OpenSelectionOfSeries();
	
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
		
	EndIf;
	
	UpdateDependentDetailsOfOrderForm_(
		Object.Goods,
		DiscrepancyOrderText,
		Items);
	
EndProcedure

&AtClient
Procedure OpenInventoryKinds(Command)
	
	OptionsForEditingInventoryTypes = PutGoodsAndStockTypesInStorage();
	FinancesClient.OpenInventoryKinds(ThisObject,OptionsForEditingInventoryTypes);
	
EndProcedure

&AtClient
Procedure SelectGoods(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.InventoryTransfer.DocumentForm.Command.SelectGoods");
	
	If Not ValueIsFilled(Object.SourceWarehouse) Then
		
		ClearMessages();
		CommonClientServer.MessageToUser(NStr("vi = 'Chưa điền trường ""Kho bãi""';
												|ru = 'Поле ""Склад"" не заполнено';
												|en = '""Warehouse"" is required'; fa = '""Warehouse"" is required';
												|it = 'Il campo ""Magazzino"" non è compilato';
												|pl = 'Nie wypełniono pola ""Magazyn""';
												|tr = '""Ambar"" alanı doldurulmadı'"), Object.Ref, "Object.SourceWarehouse");
		Return;
		
	EndIf;
	
	OpensGoodsSelection();
	
EndProcedure

&AtClient
Procedure SelectGoodsByOrdersNotes(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.InventoryTransfer.DocumentForm.Command.SelectGoodsByOrdersNotes");
	
	OpenProductSelectionByOrdersOrders();
	
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
Procedure GetWeight(Command)
	
	CurrentRow = EquipmentManagerTMClient.CurrentRow(ThisForm);
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	EquipmentManagerClient.StartGettingWeightWithElectronicScales(
		New CallbackDescription("GetWeightCompletion", ThisObject, CurrentRow),
		UUID);
	
EndProcedure

&AtClient
Procedure GetWeightCompletion(ExecutionResult, CurrentRow) Export
	
	If ExecutionResult.Result Then
		CurrentRow.NumberOfPackages = ExecutionResult.Weight;
	Else
		EquipmentManagerTMClient.ReportError(ExecutionResult);
	EndIf;
	
EndProcedure

&AtClient
Procedure ImportDataFromPDT(Command)
	
	ClearMessages();
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.InventoryTransfer.DocumentForm.Command.ImportDataFromPDT");
	
	EquipmentManagerClient.StartDownloadingDataFromTSD(
		New CallbackDescription("DownloadFromTSDCompletion", ThisObject),
		UUID);
	
EndProcedure

&AtClient
Procedure DownloadFromTSDCompletion(Result, Var_Parameters) Export
	
	If Result.Result Then
		ProcessBarcodes(Result.TableOfGoods);
	Else
		EquipmentManagerTMClient.ReportError(Result);
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
Procedure AddReusablePackage(Command)
	
	ReusablePackageClient.SelectReusablePackage(
		ThisForm,
		"Goods",
		"Products,Characteristic,Count");
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm, True);
	
EndProcedure

&AtClient
Procedure FillInSeriesByFEFO(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.InventoryTransfer.DocumentForm.Command.FillInSeriesByFEFO");
	
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
Procedure SetComposition(Command)
	
	RowSelected = Items.Goods.CurrentRow;
	
	If RowSelected = Undefined Then
		Return;
	EndIf;
	
	CurrentRow = Object.Goods.FindByID(RowSelected);
	
	If Not ValueIsFilled(CurrentRow.ProductsInSet) Then
		ShowMessageBox(,NStr("vi = 'Chỉ có thể mở thành phần bộ sản phẩm đối với bộ sản phẩm.';
							|ru = 'Открытие состава набора возможно только для набора.';
							|en = 'You can open a set only for the set.'; fa = 'You can open a set only for the set.';
							|it = 'L''apertura della composizione del kit è possibile solo per il kit.';
							|pl = 'Otwarcie składu zestawu jest możliwe tylko dla zestawu.';
							|tr = 'Set kompozisyonunun açılması sadece bir set için mümkündür.'"));
		Return;
	EndIf;
	
	KitParameters = New Structure;
	KitParameters.Insert("ProductsInSet",   CurrentRow.ProductsInSet);
	KitParameters.Insert("ItemVariantOfSet", CurrentRow.ItemVariantOfSet);
	KitParameters.Insert("ExceedingOrder",          True);
	KitParameters.Insert("DialColumns",        DialColumns(ThisForm));
	
	SetAddressInTemporaryStorage = SetAddressInTemporaryStorage(KitParameters);
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("AddressInTempStorage", SetAddressInTemporaryStorage);
	OpeningParameters.Insert("ProductsInSet", CurrentRow.ProductsInSet);
	OpeningParameters.Insert("ItemVariantOfSet", CurrentRow.ItemVariantOfSet);
	OpeningParameters.Insert("Partner", Object.CarrierPartner);
	OpeningParameters.Insert("Ref", Object.Ref);
	OpeningParameters.Insert("Date", Object.Date);
	OpeningParameters.Insert("Warehouse", Object.SourceWarehouse);
	OpeningParameters.Insert("HideCommandRemainingQuantityInWarehouses", False);
	OpeningParameters.Insert("Organization", Object.Organization);
	OpeningParameters.Insert("HideSetPrice", True);
	
	OpenForm("DataProcessor.EditSet.Form.Form", OpeningParameters, ThisForm, UUID);
	
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
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm, True);
	
EndProcedure

&AtClient
Procedure UnlinkFromOrder(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.InventoryTransfer.DocumentForm.Command.UnlinkFromOrder");
	
	SelectedRows = Items.Goods.SelectedRows;
	If SelectedRows.Count()>0 Then
		UnlinkFromOrderServer(CachedValues, False);
		NotifyAboutEndOfUnbindingLines(SelectedRows.Count());
	Else
		WarningText = NStr("vi = 'Hãy chọn dòng cần hủy liên kết với đơn hàng.';
							|ru = 'Выберите строки, которые необходимо отвязать от заказа.';
							|en = 'Select lines to remove from the order.'; fa = 'Select lines to remove from the order.';
							|it = 'Selezionare le righe da dissociare dall''ordine.';
							|pl = 'Wybierz wierze, które należy odłączyć od zamówienia.';
							|tr = 'Siparişten çıkarılacak satırları seçin.'");
		ShowMessageBox(,WarningText);
	EndIf; 
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#Region ImportDataFromFile

&AtClient
Procedure LoadFromFile(Command)
	
	If Not Object.Goods.Count() = 0 Then
		
		QueryText = NStr("vi = 'Bảng %1 sẽ được điền lại. Tiếp tục?';
						|ru = 'Таблица %1 будет перезаполнена. Продолжить?';
						|en = 'The table %1 will be refilled. Continue?'; fa = 'The table %1 will be refilled. Continue?';
						|it = 'La tаbellа %1 verrà precompilata. Continuare?';
						|pl = 'Tabela %1 zostanie uzupełniona ponownie. Kontynuować?';
						|tr = '%1 tablosu yeniden doldurulacaktır. Devam edilsin mi?'");
		QueryText = StrTemplate(QueryText, NStr("vi = 'Hàng hóa';
												|ru = 'Товары';
												|en = 'Goods'; fa = 'کالاها';
												|it = 'Товары';
												|pl = 'Goods';
												|tr = 'Mallar'"));
		
		Notification = New CallbackDescription("LoadFromFileCompletion", ThisForm);
		ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo);
		
	Else
		ShowUploadFormFromFile();
	EndIf;
	
EndProcedure

&AtClient
Procedure LoadFromFileCompletion(Result, AdditionalParameters) Export
	
	If Not Result = DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ShowUploadFormFromFile();
	
EndProcedure

#EndRegion

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure


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
Procedure CloseOrderCompletion(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	If Response = DialogReturnCode.No Then
		Return;
	ElsIf Not Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
		Return;
	EndIf;
	
	CloseOrderFragment();
	
EndProcedure

&AtClient
Procedure CloseOrderFragment()
	
	ListOfOrdersToClose = New ValueList;
	If ValueIsFilled(Object.TransferOrder) Then
		ListOfOrdersToClose.Add(Object.TransferOrder)
	Else
		ListOfOrdersToClose.LoadValues(OrderList.UnloadValues())
	EndIf;
	
	ClosureStructure = New Structure;
	ClosureStructure.Insert("Orders",                       ListOfOrdersToClose);
	ClosureStructure.Insert("DocumentInitiator",            Object.Ref);
	ClosureStructure.Insert("CancelUnprocessedLines", True);
	ClosureStructure.Insert("CloseOrders",              True);
	
	OpenForm("DataProcessor.OrderClosureWizard.Form.ClosureForm", ClosureStructure
				,,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region Private

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
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

// End StandardSubsystems.Properties

&AtServer
Procedure FillInSubordinatePropertiesForStatistics(ParentPropsName)
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, ParentPropsName);
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsRowCode.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.TransferAgainstOrders");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsTransferOrder.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.TransferOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSalesOpportunity.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.SalesOpportunity");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NoteText);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSalesOpportunity.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseTransferAgainstSeveralOrders");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Visible", False);

	// only view the Destination if the string code is full

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPurpose.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsTransferOrder.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.TransferOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsTransferOrder.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.TransferOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("ReadOnly", False);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsRowCode.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.TransferOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsTransferOrder.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.TransferOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.TransferAgainstOrders");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsTransferOrder.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.TransferOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.TransferOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ErrorNoteText);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Vượt quá trên đơn hàng, chưa chọn đơn hàng';
													|ru = 'Сверх заказа, заказ не выбран';
													|en = 'In excess of the order, the order is not selected'; fa = 'In excess of the order, the order is not selected';
													|it = 'Oltre all''ordine, l''ordine non è selezionato';
													|pl = 'Przewyższa zamówienie, zamówienie nie wybrane';
													|tr = 'Sipariş fazlası, sipariş seçilmedi'"));

	//

	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisForm, False);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisForm, "SeriesWhenPlanningShipmentWHGoodsAreIndicated");

	//

	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisForm);	
		
	//
	
	SetsServer.SetConditionalAppearance(ThisForm, "Goods");
	
	// Conditional appearance of quality control Attributes.
	Fields = QualityControl.Fields(
		Items.GoodsToControlQuality,
		Items.GoodsQualityConfirmationDate);
	FlagDisabled = New Array();
	EmptyBatch = Catalogs.ControlledLots.EmptyRef();
	NotEqual = DataCompositionComparisonType.NotEqual;
	QualityControl.AddFilter(FlagDisabled, "Object.Goods.ControlledLotOfTheSender", EmptyBatch, NotEqual);
	QualityControl.SetupAppearance(ConditionalAppearance, Fields, FlagDisabled);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsQualityConfirmationDate.Name);
	
	AndGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.SubjectToUnlocking");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ControlledLotOfTheSender");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ToControlQuality");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chỉ dành cho các lô hàng cần được mở khóa>';
													|ru = '<только для партий подлежащих разблокировке>';
													|en = '<only for lots to be unlocked>'; fa = '<only for lots to be unlocked>';
													|it = '<only for lots to be unlocked>';
													|pl = '<only for lots to be unlocked>';
													|tr = '<yalnızca kilidi kaldırılacak lotlar için>'"));
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
EndProcedure

#Region OnChangeAttributes

&AtServer
Procedure SourceWarehouseOnChangeServer(UntieAllLinesFromOrder, ClearLines_, CachedValues)
	
	SetPrivilegedMode(True);
	
	AdvancedWarehousingOnShipment = WarehousesServer.UseWarehouseManagemantSystemForGoodsIssue(Object.SourceWarehouse, Object.Date);
	FillSetVisibilityAndReFillAvailabilityByShipment();
	
	Object.PriceKind = Catalogs.Warehouses.AccountingPriceType(Object.SourceWarehouse);
	
	SourceWarehouse = Object.SourceWarehouse;
	
	ClearProductsTabularPartWhenWarehouseChanges(UntieAllLinesFromOrder, ClearLines_, CachedValues);
	
	If QualityControl.UpdateActionParameters(
			Documents.InventoryTransfer,
			Object,
			CacheQualityControl) Then
		
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInSenderSControlledLotReference", CacheQualityControl);
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
		
	EndIf;
	
	SetPrivilegedMode(False);
	
EndProcedure

&AtServer
Procedure DestinationWarehouseOnChangeServer(UntieAllLinesFromOrder, ClearLines_, CachedValues, DirectModificationOfWarehouseField = False)
	
	FillSetVisibilityAndReFillAvailabilityByShipment();
	
	DestinationWarehouse = Object.DestinationWarehouse;
	
	ClearProductsTabularPartWhenWarehouseChanges(UntieAllLinesFromOrder, ClearLines_, CachedValues);
	
	GoodsDelivery.FillInDeliveryDetails(Items, "DestinationWarehouse", Object);
	
	UpdateMovementUnderActivity();
	
	If QualityControl.UpdateActionParameters(
			Documents.InventoryTransfer,
			Object,
			CacheQualityControl,
			DirectModificationOfWarehouseField) Then
		
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInSenderSControlledLotReference", CacheQualityControl);
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure StatusOnChangeServer(FillInShippingInstructions)

	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.InventoryTransfer));
	Items.GroupInformationRequiredStatuses.Visible = DisplayMessageOnUsingStatuses();
	
	If FillInShippingInstructions Then
		Documents.InventoryTransfer.FillInShippingInstructions(Object);
	EndIf;

	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Object.Organization);
	Object.CompanyBankAccount =
		CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount);
	
	FillInSubordinatePropertiesForStatistics("Organization");
	
	FillInSubordinatePropertiesForStatistics("BusinessOperation");
	
	Documents.TransferOrder.CheckAndClearOrganization(Object, Object.CompanyRecipient);
	
	FormItemsManagement();
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	UpdateMovementUnderActivity();
	UpdateTextDocumentsBasedOn();
	
	If QualityControl.UpdateActionParameters(
			Documents.InventoryTransfer,
			Object,
			CacheQualityControl) Then
		
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInSenderSControlledLotReference", CacheQualityControl);
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure RecipientOrganizationWhenModifiedOnServer()
	
	UpdateTextDocumentsBasedOn();
	
EndProcedure

&AtServer
Procedure BusinessOperationOnChangeServer()
	
	FillInSubordinatePropertiesForStatistics("BusinessOperation");
	
	Documents.TransferOrder.CheckAndClearOrganization(Object, Object.CompanyRecipient);
	Documents.TransferOrder.CheckAndClearOrganization(Object, Object.Organization);
	
	If Object.Organization.IsEmpty() Then
		CompanyBankAccount = Undefined;
	EndIf;
	
	If QualityControl.UpdateActionParameters(
			Documents.InventoryTransfer,
			Object,
			CacheQualityControl) Then
		
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInSenderSControlledLotReference", CacheQualityControl);
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
		
	EndIf;
	
	FormItemsManagement();
	
EndProcedure

&AtServer
Procedure DateOnChangeServer()
	
	SetPrivilegedMode(True);
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	AdvancedWarehousingOnShipment = WarehousesServer.UseWarehouseManagemantSystemForGoodsIssue(Object.SourceWarehouse, Object.Date);
	FillSetVisibilityAndReFillAvailabilityByShipment();
	
	UpdateMovementUnderActivity();
	
	SetPrivilegedMode(False);
	
	If QualityControl.UpdateActionParameters(
			Documents.InventoryTransfer,
			Object,
			CacheQualityControl) Then
		
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInSenderSControlledLotReference", CacheQualityControl);
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure DateOfReceiptOnChangeServer()
	
	If QualityControl.UpdateActionParameters(
			Documents.InventoryTransfer,
			Object,
			CacheQualityControl) Then
		
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInSenderSControlledLotReference", CacheQualityControl);
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateMovementUnderActivity(Fill = True)
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATActivityType();
	FillParameters.Organization = Object.Organization;
	FillParameters.Date = Object.Date;
	FillParameters.Warehouse = Object.DestinationWarehouse;
	FillParameters.MovementOfGoodsInWarehouses = True;
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferOfGoodsBetweenBranchOffices Then
		FillParameters.MovementBetweenBranches = True;
	EndIf;
	
	If Fill Then
		
		VATAccountingERP.FillInTypeOfActivityVAT(
			Object.TransferForActivity, 
			FillParameters,
			VATAccountingCachedParameterValues);
		
	EndIf;
	
	VATAccountingERP.FillInActivitySelectionList(
		Items.TransferForActivity, 
		Object.TransferForActivity, 
		FillParameters, 
		VATAccountingCachedParameterValues);
	
EndProcedure

&AtServer
Procedure EstablishVisibilityOfQualityControlGroup()
	
	Items.GroupQualityControlIndentation.Visible = Not Object.TransferAgainstOrders
		And Object.LockedGoodsTransfer;
	Items.LockedGoodsTransfer.Visible = Not Object.TransferAgainstOrders;
	
EndProcedure

#EndRegion

#Region Goods

&AtClient
Procedure GoodsAtEndOfEditingForServerCall()
	
	GoodsAtEndOfEditingOnServer();
	
EndProcedure

&AtServer
Procedure GoodsAtEndOfEditingOnServer()
	
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
EndProcedure

&AtServer
Procedure GoodsAfterDeleteRowServer()
	
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	If UseTransferAgainstSeveralOrders Then
		UpdateOrderInformation();
	EndIf;
	
EndProcedure

#EndRegion

#Region SelectionAndProcessingOfQuantityVerification

&AtServer
Procedure ProcessingProductSelectionFromOrder(AddressInStorage)

	StructureOfData = GetFromTempStorage(AddressInStorage);
	SalesServerLocalization.TransferBarcodesOfPackages(ThisObject, StructureOfData.PackageBarcodes);
	FillInProductsSelectedFromOrder(StructureOfData.Goods);

EndProcedure

// Parameters:
//  Table - ValueTable - Table
&AtServer
Function SenderSeriesAndReceiverSeriesTables(Table)
	
	Table.Columns.Add("IndexOf", New TypeDescription("Number"));
	For IndexOf = 0 To Table.Count() - 1 Do
		Table[IndexOf].IndexOf = IndexOf;
	EndDo;
	
	Result = New Structure("SenderSeriesTable, RecipientSeriesTable",
		Table.CopyColumns(), Table.CopyColumns());
	
	Query = New Query();
	Query.SetParameter("Table", Table);
	Query.SetParameter("SourceWarehouse", Object.SourceWarehouse);
	
	Query.Text =
		"SELECT
		|	Table.IndexOf       AS IndexOf,
		|	Table.Products AS Products
		|INTO TTProducts_1
		|FROM
		|	&Table AS Table
		|;
		|
		|/////////////////////////////////////////////////////////
		|SELECT
		|	Table.IndexOf AS IndexOf,
		|	CASE WHEN BatchAccountingPolicies.Ref IS NULL THEN
		|				FALSE
		|			ELSE
		|				TRUE
		|		END AS SpecifySenderSeries
		|FROM
		|	TTProducts_1 AS Table
		|		
		|		LEFT JOIN Catalog.Products AS CatProducts
		|		ON Table.Products = CatProducts.Ref
		|		
		|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
		|		ON BatchAccountingPolicies.Ref = CatProducts.ProductKind.Ref
		|		 AND BatchAccountingPolicies.Warehouse = &SourceWarehouse
		|		 AND (BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment
		|			OR BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches)";
	
	Indexes = Query.Execute().Unload();
	For Each IndexRow In Indexes Do
		
		If IndexRow.SpecifySenderSeries Then
			FillPropertyValues(Result.SenderSeriesTable.Add(), Table[IndexRow.IndexOf]);
		Else
			FillPropertyValues(Result.RecipientSeriesTable.Add(), Table[IndexRow.IndexOf]);
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

&AtServer
Procedure FillInProductsSelectedFromOrder(Table)
	
	TableStructure = SenderSeriesAndReceiverSeriesTables(Table);
	FillInProductsSelectedFromOrderTakingIntoAccountSeries(TableStructure.SenderSeriesTable, True);
	FillInProductsSelectedFromOrderTakingIntoAccountSeries(TableStructure.RecipientSeriesTable,  False);
	
EndProcedure

// Parameters:
//  Table - TabularSection -
//  ConsiderSeries_ - Boolean -
&AtServer
Procedure FillInProductsSelectedFromOrderTakingIntoAccountSeries(Table, ConsiderSeries_)
	
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
	
	OrderRelationshipFields = New Structure("RowCode, TransferOrder", 0, Documents.TransferOrder.EmptyRef());
	AddedRows = InvoicesServer.FillInProductsSelectedFromOrder(StringTree, FieldsNames, Object.Goods, OrderRelationshipFields,
		?(ConsiderSeries_, "", "Series"));
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	StructureOfActions.Insert("FillInSenderSControlledLotReference", CacheQualityControl);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Products", StructureOfActions);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
	For Each LineProducts_ In AddedRows Do
		
		If ValueIsFilled(LineProducts_.TransferOrder) Then
			Object.TransferAgainstOrders = True;
			If Not UseTransferAgainstSeveralOrders Then
				Object.TransferOrder = LineProducts_.TransferOrder;
			EndIf;
		EndIf;
		LineProducts_.SetIndex = ?(ValueIsFilled(LineProducts_.ProductsInSet), 1, 0);
	EndDo;
	
	UpdateSenderAssignmentInProductsTable();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	UpdateOrderInformation();
	FillInServiceDetailsForProductRange();
	
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
EndProcedure

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected)

	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInSenderSControlledLotReference", CacheQualityControl);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
			ThisObject, "Products", StructureOfActions);
	
	RowsToProcess = New Array;
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct, "ProductsInSet, ItemVariantOfSet, Products,
		|Characteristic, ItemVariantsAreUsed, Package, NumberOfPackages, Series");
		CurrentRow.SetIndex = ?(ValueIsFilled(CurrentRow.ProductsInSet), 1, 0);
		UpdateOrderDeviationsInLine(CurrentRow, Object.TransferAgainstOrders);
		CurrentRow.TransferOrder = OrderInOverOrderLine(Object.TransferAgainstOrders, Object.TransferOrder);
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods);
		
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
EndProcedure

&AtClient
Procedure OpenProductSelectionByOrdersOrders()
	
	HeaderAttributes = New Structure("Organization, CompanyRecipient, SourceWarehouse, DestinationWarehouse, Department, BusinessOperation, Ref");
	FillPropertyValues(HeaderAttributes, Object);
	AdditionalFields = New Structure("DateOfShipment, SalesOpportunity");
	
	FormParameters = New Structure();
	FormParameters.Insert("HeaderAttributes",                           HeaderAttributes);
	FormParameters.Insert("OrderDocument",                                    Object.TransferOrder);
	FormParameters.Insert("AdvancedWarehousingOnShipment",                 AdvancedWarehousingOnShipment);
	FormParameters.Insert("InvoiceForOrders",                       Object.TransferAgainstOrders
																		And ValueIsFilled(Object.TransferOrder));
	FormParameters.Insert("AddressGoods",                              AddressInvoiceGoods());
	FormParameters.Insert("Invoice",                                Object.Ref);
	FormParameters.Insert("UseInvoicesForSeveralOrders", UseTransferAgainstSeveralOrders);
	FormParameters.Insert("OrdersAreUsed",                       UseTransferOrders);
	FormParameters.Insert("AdditionalFields",                       AdditionalFields);
	
	OpenForm("CommonForm.AddItemsFromSalesOrderGoodsIssue",
		FormParameters, ThisForm, UUID,,,,FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure OpensGoodsSelection()

	ControlledLotReference = Object.ControlledLotOfTheSender;
	If Object.LockedGoodsTransfer And Not ValueIsFilled(ControlledLotReference) Then
		ControlledLotReference = ControlledLotReferenceLinkNew; // so that Balances without Lot references are not displayed.
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Warehouse",                                     Object.SourceWarehouse);
	FormParameters.Insert("SelectionModeWithoutAmountParameters",         True);
	FormParameters.Insert("HideTheViewPriceColumn",                    True);
	FormParameters.Insert("HideTheItemPricesCommand",           True);
	FormParameters.Insert("FilterByProductType",                   New FixedArray(ProductsClientServer.SelectionByProductMultiTurnContainer()));
	FormParameters.Insert("Title",                                 NStr("vi = 'Chọn hàng hóa';
																		|ru = 'Подбор товаров';
																		|en = 'Pick goods'; fa = 'انتخاب کالاها';
																		|it = 'Selezione delle merci';
																		|pl = 'Wybór towarów';
																		|tr = 'Ürünlerin seçimi'"));
	FormParameters.Insert("Date",                                      Object.Date);
	FormParameters.Insert("Document",                                  Object.Ref);
	FormParameters.Insert("SeriesSpecificationParameters",                    SeriesSpecificationParameters);
	FormParameters.Insert("ControlledLotReference",                      ControlledLotReference);
	
	OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form", FormParameters, ThisForm, UUID);

EndProcedure

&AtServer
Function AddressInvoiceGoods()
	
	Table = Object.Goods.Unload();
	Table.Columns.TransferOrder.Name = "MovingOrder";
	
	Table.Columns.Add("TransferOrder", New TypeDescription("DocumentRef.TransferOrder, DocumentRef.InventoryTransfer"));
	Table.Columns.Add("DateOfShipment",       New TypeDescription("Date"));
	
	For Each String In Table Do
		String.TransferOrder = ?(ValueIsFilled(String.MovingOrder), String.MovingOrder, Object.Ref);
		If String.BatchesIndicationStatusSender <> 10 And String.BatchesIndicationStatusSender <> 14 Then
			String.Series = Catalogs.ItemsBatches.EmptyRef();
		EndIf;
	EndDo;
	
	Table.FillValues(CurrentSessionDate(), "DateOfShipment");
	
	Return PutToTempStorage(Table);
	
EndFunction

&AtServer
Function PutTablePartOfGoodsInTemporaryStorageToCheckQuantity()
	
	TabularPartProducts = Object.Goods.Unload(,"ProductsInSet, ItemVariantOfSet,Products, Characteristic, ItemVariantsAreUsed, Package, NumberOfPackages, Series, BatchesIndicationStatus, ItemsType");
	TabularPartProducts.GroupBy("ProductsInSet, ItemVariantOfSet,Products, Characteristic, ItemVariantsAreUsed, Package, Series, BatchesIndicationStatus, ItemsType", "NumberOfPackages");
	AddressInTempStorage = PutToTempStorage(TabularPartProducts, UUID);
	Return AddressInTempStorage;
	
EndFunction

&AtServer
Procedure ChangeTablePartBasedOnResultsOfCheck(ReturnParameters, CachedValues)
	
	GoodsTable = GetFromTempStorage(ReturnParameters.Goods);
	AddedAndChangedLines = New Array();
	AddedRows = New Array();
	LinesToDelete = New Array;
	For Each SourceRow In GoodsTable Do
		
		Filter = New Structure("ProductsInSet, ItemVariantOfSet, Products, Characteristic, Series, BatchesIndicationStatus, Package");
		FillPropertyValues(Filter, SourceRow);
		FoundRows = Object.Goods.FindRows(Filter);
		For Each TSRow In FoundRows Do
			
			If SourceRow.NumberOfPackages = 0 Then
				Break;
			EndIf;
			
			If SourceRow.NumberOfPackages >= 0 Then
				
				TSRow.NumberOfPackages = TSRow.NumberOfPackages + SourceRow.NumberOfPackages;
				SourceRow.NumberOfPackages = 0;
				AddedAndChangedLines.Add(TSRow);
				
			Else
				
				QuantityToWriteOff = -SourceRow.NumberOfPackages;
				QuantityPerLine   = TSRow.NumberOfPackages;
				
				If QuantityToWriteOff >= QuantityPerLine Then
					SourceRow.NumberOfPackages = QuantityPerLine - QuantityToWriteOff;
					TSRow.NumberOfPackages       = 0;
				Else
					SourceRow.NumberOfPackages = 0;
					TSRow.NumberOfPackages       = QuantityPerLine - QuantityToWriteOff;
					AddedAndChangedLines.Add(TSRow);
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
			AddedAndChangedLines.Add(TSRow);
			AddedRows.Add(TSRow);
			
			
		EndIf;
		
	EndDo;
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
			ThisObject, "Products", StructureOfActions);
			
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		AddedAndChangedLines,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInSenderSControlledLotReference", CacheQualityControl);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		AddedRows,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	For Each TSRow In LinesToDelete Do
		Object.Goods.Delete(TSRow);
	EndDo;
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
EndProcedure

&AtClient
Procedure CheckQuantityInTheDocument(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.InventoryTransfer.DocumentForm.Command.CheckQuantityInTheDocument");
	
	ParametersForSpecifyingTimeSeries = New Structure(SeriesSpecificationParameters);
	ParametersForSpecifyingTimeSeries.WarehouseFieldName = "Warehouse";
	ParametersForSpecifyingTimeSeries.NameOfSenderWarehouseField = Undefined;
	ParametersForSpecifyingTimeSeries.NameOfRecipientWarehouseField = Undefined;
	
	ParametersForSpecifyingSeriesCheckingQuantity = New FixedStructure(ParametersForSpecifyingTimeSeries);

	If Object.Status = PredefinedValue("Enum.GoodsTransferStatuses.Accepted") Then
		Warehouse = Object.DestinationWarehouse;
	Else	
		Warehouse = Object.SourceWarehouse;
	EndIf;
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("AddressInTempStorage",            PutTablePartOfGoodsInTemporaryStorageToCheckQuantity());
	OpeningParameters.Insert("TabularSectionName",                    "Goods");
	OpeningParameters.Insert("Ref",                               Object.Ref);
	OpeningParameters.Insert("GoodsQuantityExcessIsAllowed", Not Object.TransferAgainstOrders);
	OpeningParameters.Insert("SeriesSpecificationParameters",               ParametersForSpecifyingSeriesCheckingQuantity);
	OpeningParameters.Insert("Warehouse",                                Warehouse);
	OpeningParameters.Insert("TransferAgainstOrders",                 Object.TransferAgainstOrders);
	OpeningParameters.Insert("Status",                               Object.Status);
	OpeningParameters.Insert("CalculateSets",                   True);
	
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

&AtServer
Procedure OrderSelectionProcessingOnServer(TransferOrder)
	
	CurrentData = Object.Goods.FindByID(Items.Goods.CurrentRow);
	
	CurrentData.TransferOrder = TransferOrder;
	CurrentData.SalesOpportunity = Common.ObjectAttributeValue(TransferOrder, "SalesOpportunity");
	
	StructureOfActions = New Structure();
	SeriesVerificationParameters = New Structure("Warehouse, SeriesSpecificationParameters");
	SeriesVerificationParameters.Warehouse = New Structure("Sender, Recipient", Object.SourceWarehouse, Object.DestinationWarehouse);
	SeriesVerificationParameters.SeriesSpecificationParameters = SeriesSpecificationParameters;
	StructureOfActions.Insert("CheckSeriesCalculateStatus", SeriesVerificationParameters);
	StructureOfActions.Insert("FillInSenderSControlledLotReference", CacheQualityControl);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentData, StructureOfActions, Undefined);
	
	UpdateOrderInformation();
	
EndProcedure

#EndRegion

#Region BarcodesAndTradeEquipment

&AtClient
Procedure ProcessBarcodes(BarcodeData_5)
	
	ClearMessages();
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
		Return;
	EndIf;
	
	StructureOfActionsWithAddedStrings = New Structure;
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsWithAddedStrings.Insert("FillInSenderSControlledLotReference", CacheQualityControl);
	StructureOfActionsWithAddedStrings.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActionsWithAddedStrings.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithAddedStrings);
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Products", StructureOfActionsWithAddedStrings);
	
	StructureOfActionsWithModifiedStrings = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithModifiedStrings);
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	StructureOfActions.SeriesSpecificationParameters                 = SeriesSpecificationParameters;
	StructureOfActions.CalculateSets                     = True;
	StructureOfActions.AddOnlyProductsOverAndAboveOrder        = True;
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

&AtServer
Procedure ProcessBarcodesServer(StructureOfActionParameters, CachedValues)
	
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject, Object, StructureOfActionParameters, CachedValues);
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
EndProcedure

#EndRegion

#Region SetOfSeries

&AtServer
Function ParametersOfSeriesIndicationForm(CurDataId)
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(Object, SeriesSpecificationParameters, CurDataId, ThisForm);
	
EndFunction

&AtServer
Procedure SetVisibilityOfSeriesElements()
	Items.GoodsBatchesIndicationStatus.Visible  = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsSpecifySeries.Visible         = SeriesSpecificationParameters.UseItemsBatch;
	
	Items.GoodsFillInSeriesByFEFO.Visible = 
		GetFunctionalOption("UseItemsBatchWarehouse", New Structure("Warehouse", Object.SourceWarehouse))
		And Not AdvancedWarehousingOnShipment;
	
	SetPrivilegedMode(True);
	OrderSchemeOnReceipt = WarehousesServer.UseWarehouseManagemantSystemForGoodsReceipt(Object.DestinationWarehouse,
		                                                                                           Object.Date);
	
	YouCanPopulateSeriesByShipment = AdvancedWarehousingOnShipment
		And GetFunctionalOption("UseItemsBatchWarehouse",New Structure("Warehouse", Object.SourceWarehouse))
		And Not OrderSchemeOnReceipt
		And GetFunctionalOption("UseItemsBatchWarehouse",New Structure("Warehouse", Object.DestinationWarehouse));
	SetPrivilegedMode(False);
		
	Items.GoodsSeries.Visible = SeriesSpecificationParameters.UseItemsBatch;
EndProcedure

&AtServer
Procedure ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm)
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInSenderSControlledLotReference", CacheQualityControl);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	ProductsServer.ProcessSeriesIndication_(Object,SeriesSpecificationParameters,ParametersOfSeriesIndicationForm, StructureOfActions);

EndProcedure

&AtServer
Procedure FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues)
	
	ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Object, 
				SeriesSpecificationParameters, IDCurrentRow, CachedValues);
	
EndProcedure

&AtServer
Function FillInSeriesByFEFOServer()
	If ProductsServer.ThereAreLinesWithFEFOFilledSeries_(Object.Goods) Then
		ProductsServer.FillInSeriesByFEFO(Object,SeriesSpecificationParameters);	
		FormEvents.WhenChangingElement(ThisObject, "Goods");
		Return True;
	Else
		Return False;
	EndIf;
EndFunction

&AtServer
Function ThereAreFilledSeriesByFEFO()

	Return ProductsServer.ThereAreLinesWithFEFOFilledSeries(Object.Goods);

EndFunction

&AtClient
Procedure OpenSelectionOfSeries(Text = "", CurrentData = Undefined)
	If ProductsClient.YouNeedServerCallToSpecifySeries(ThisForm, SeriesSpecificationParameters, Text, CurrentData)Then
		
		If CurrentData = Undefined Then
			CurDataId = Items.Goods.CurrentData.GetID();
		Else
			CurDataId = CurrentData.GetID();
		EndIf;

		ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm(CurDataId);
		
		ReturnValue_1 = Undefined;
		
		OpenForm(ParametersOfSeriesIndicationForm.FormName,ParametersOfSeriesIndicationForm,ThisForm,,,, New CallbackDescription("OpenSelectionOfSeriesCompletion", ThisObject, New Structure("ParametersOfSeriesIndicationForm", ParametersOfSeriesIndicationForm)), FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
EndProcedure

&AtClient
Procedure OpenSelectionOfSeriesCompletion(Result, AdditionalParameters) Export
    
    ParametersOfSeriesIndicationForm = AdditionalParameters.ParametersOfSeriesIndicationForm;
    
    ReturnValue_1 = Result;
    
    If ReturnValue_1 <> Undefined Then
        ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm);
    EndIf;

EndProcedure

&AtClient
Procedure OpenSeriesSelectionWhenScanningProductBarCode()
	
	If CurDataId = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.Goods.FindByID(CurDataId);
	OpenSelectionOfSeries(,CurrentData);
	
EndProcedure

&AtServer
Function DisplayMessageOnUsingStatuses()
	DisplayMessageOnUsingStatuses = False;
	
	If SeriesSpecificationParameters.UseItemsBatch 
		And Not GetFunctionalOption("UseGoodsTransferStatuses") Then
		
		SetPrivilegedMode(True);
		
		SerialAccountingPoliciesWarehouseSender = WarehousesServer.UseOfSeriesInStockAccordingToAccountingPolicies(Object.SourceWarehouse);
		SeriesAccountingPoliciesWarehouseRecipient  = WarehousesServer.UseOfSeriesInStockAccordingToAccountingPolicies(Object.DestinationWarehouse);
		UseRecipientOrderScheme  = WarehousesServer.UseWarehouseManagemantSystemForGoodsReceipt(Object.DestinationWarehouse, Object.Date, False);
		UseSenderOrderScheme = WarehousesServer.UseWarehouseManagemantSystemForGoodsIssue(Object.SourceWarehouse, Object.Date);
		SerialSenderParameters = WarehousesServer.UseOfSeriesInStock(Object.SourceWarehouse, False);
		RecipientWarehouseSeriesParameters  = WarehousesServer.UseOfSeriesInStock(Object.DestinationWarehouse, False);
		
		SetPrivilegedMode(False);
		
		If UseSenderOrderScheme Then
			
			If UseRecipientOrderScheme Then
				
				If Not SerialAccountingPoliciesWarehouseSender.SpecifyWhenPlanningShipment 
					And SeriesAccountingPoliciesWarehouseRecipient.UseCostAccountingByBatches Then
					
					DisplayMessageOnUsingStatuses = True;
					
				EndIf;
				
				If Not SerialSenderParameters.UseItemsBatch
					And SeriesAccountingPoliciesWarehouseRecipient.UseCostAccountingByBatches Then
					
					DisplayMessageOnUsingStatuses = True;
					
				EndIf;
				
			Else
				
				If Not SerialAccountingPoliciesWarehouseSender.SpecifyWhenPlanningShipment 
					And SeriesAccountingPoliciesWarehouseRecipient.UseCostAccountingByBatches Then
					
					DisplayMessageOnUsingStatuses = True;
					
				EndIf;
				
				If Not SerialAccountingPoliciesWarehouseSender.SpecifyWhenPlanningShipment 
					And RecipientWarehouseSeriesParameters.UseItemsBatch Then
					
					DisplayMessageOnUsingStatuses = True;
					
				EndIf;
				
				If Not SerialSenderParameters.UseItemsBatch
					And SeriesAccountingPoliciesWarehouseRecipient.UseCostAccountingByBatches Then
					
					DisplayMessageOnUsingStatuses = True;
					
				EndIf;
				
				If Not SerialSenderParameters.UseItemsBatch
					And RecipientWarehouseSeriesParameters.UseItemsBatch Then
					
					DisplayMessageOnUsingStatuses = True;
					
				EndIf;
				
			EndIf;
			
		Else
			
			If UseRecipientOrderScheme Then
				
				If Not SerialSenderParameters.UseItemsBatch
					And SeriesAccountingPoliciesWarehouseRecipient.UseCostAccountingByBatches Then
					
					DisplayMessageOnUsingStatuses = True;
					
				EndIf;
				
			Else
				
				If Not SerialSenderParameters.UseItemsBatch
					And SeriesAccountingPoliciesWarehouseRecipient.UseCostAccountingByBatches Then
					
					DisplayMessageOnUsingStatuses = True;
					
				EndIf;
				
				If Not SerialSenderParameters.UseItemsBatch
					And RecipientWarehouseSeriesParameters.UseItemsBatch Then
					
					DisplayMessageOnUsingStatuses = True;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return DisplayMessageOnUsingStatuses;
	
EndFunction

#EndRegion

#Region FormItemsManagement

&AtServer
Procedure FormItemsManagement()
	
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	
	Documents.InventoryTransfer.FillInNamesOfBusinessTransactionDetails(
		Object.BusinessOperation,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	CashServer.SetVisibilityOfElementsByArray(
		Items,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	ThisIsTransferOfGoodsBetweenSeparateUnits = (Object.BusinessOperation = Enums.BusinessTransactions.TransferOfGoodsBetweenBranchOffices);
	
	Items.Organization.Title =
		?(ThisIsTransferOfGoodsBetweenSeparateUnits, NStr("vi = 'Doanh nghiệp-người gửi';
															|ru = 'Организация-отправитель';
															|en = 'Shipping company'; fa = 'شرکت ارسال‌کننده';
															|it = 'Azienda-mittente';
															|pl = 'Shipping company';
															|tr = 'Gönderen iş yeri'"),
		                                                       NStr("vi = 'Doanh nghiệp';
																	|ru = 'Организация';
																	|en = 'Company'; fa = 'Company';
																	|it = 'Azienda';
																	|pl = 'Company';
																	|tr = 'İş yeri'"));

EndProcedure

&AtServer
Procedure LockedGoodsTransferOnChangeServer()
	
	EstablishVisibilityOfQualityControlGroup();
	If Not Object.LockedGoodsTransfer Then
		
		Object.ControlledLotOfTheSender = Catalogs.ControlledLots.EmptyRef();
		
	EndIf;
	
	If QualityControl.UpdateActionParameters(
			Documents.InventoryTransfer,
			Object,
			CacheQualityControl) Then
		
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInSenderSControlledLotReference", CacheQualityControl);
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		For Each TableRow In Object.SetOfSeries Do
			TableRow.ControlledLotOfTheSender = Object.ControlledLotOfTheSender;
		EndDo;
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ControlledLotOfTheSenderOnChangeServer()
	
	If QualityControl.UpdateActionParameters(
			Documents.InventoryTransfer,
			Object,
			CacheQualityControl) Then
		
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInSenderSControlledLotReference", CacheQualityControl);
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		For Each TableRow In Object.SetOfSeries Do
			TableRow.ControlledLotOfTheSender = Object.ControlledLotOfTheSender;
		EndDo;
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FillingByOrderByOrder

&AtClient
Procedure MoveByOrderSetOrderSelected(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Object.TransferAgainstOrders = False;
	Else
		
		If Object.Goods.Count() = 0 Then
			QueryText = StrReplace(NStr("vi = 'Danh sách Hàng hóa sẽ được điền số dư của hàng hóa chưa được lập theo chứng từ %TransferOrder%. Tiếp tục?';
										|ru = 'Список Товары будет заполнен остатками неоформленных товаров по документу %TransferOrder%. Продолжить?';
										|en = 'The Item list will be populated with remaining unregistered goods under the %TransferOrder% document. Continue?'; fa = 'The Item list will be populated with remaining unregistered goods under the %TransferOrder% document. Continue?';
										|it = 'L''elenco Merci sarà ricompilato con rimanenze delle merci non formalizzate per il documento %TransferOrder%. Continuare?';
										|pl = 'Lista Produktów będzie wypełniona resztkami niesporządzonych towarów wg dokumentu %TransferOrder%. Kontynuować?';
										|tr = 'Ürünler listesi, belgeye göre düzenlenmeyen ürün bakiyeleri ile doldurulacaktır %TransferOrder%. Devam edilsin mi?'"), "%TransferOrder%", Result);
		Else
			QueryText = StrReplace(NStr("vi = 'Dòng trong danh sách Hàng hóa sẽ được gắn với các dòng của chứng từ %TransferOrder%. Các dòng không thể gắn với dòng của đơn hàng sẽ bị xóa bỏ. Tiếp tục?';
										|ru = 'Строки в списке Товары будут привязаны к строкам документа %TransferOrder%. Строки, которые невозможно привязать к строкам заказа, будут удалены.  Продолжить?';
										|en = 'Lines in the Item list will be linked to lines of the %TransferOrder% document. Lines which cannot be linked to order lines will be deleted. Continue?'; fa = 'Lines in the Item list will be linked to lines of the %TransferOrder% document. Lines which cannot be linked to order lines will be deleted. Continue?';
										|it = 'Le righe nell''elenco Merci verranno associate alle righe del documento %TransferOrder%. Le righe che non possono essere associate alle righe dell''ordine verranno eliminate. Continuare?';
										|pl = 'Wiersze w liście Wiersze pozycji będą przywiązane do wierszy dokumentu %TransferOrder%. Wiersze, których nie można powiązać z wierszami zamówienia, zostaną usunięte. Kontynuować?';
										|tr = 'Ürünler listesindeki satırlar, belge satırlarına bağlanacaktır %TransferOrder%. Sipariş satırlarına bağlanamayan satırlar silinecektir. Devam edilsin mi?'"), "%TransferOrder%", Result);
		EndIf;
		
		ShowQueryBox(New CallbackDescription("MoveByOrderSetOrderSelectedCompletion", ThisObject, New Structure("TransferOrder", Result)), QueryText, QuestionDialogMode.YesNo);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotifyAboutDisconnectingLinesFromOrders()
	
	If UseTransferAgainstSeveralOrders Then
		NotificationText1 = NStr("vi = 'Các dòng trong danh sách ""Hàng hóa"" được bỏ liên kết từ các dòng đặt hàng.';
								|ru = 'Строки в списке ""Товары"" отвязаны от строк заказов.';
								|en = 'Lines in Item list are unlinked from lines in the orders.'; fa = 'Lines in Item list are unlinked from lines in the orders.';
								|it = 'Le righe dell''elenco ""Merci"" sono scollegate dalle righe degli ordini.';
								|pl = 'Wiersze na liście ""Towary"" są odwiązane od wierszy zamówień.';
								|tr = '""Ürünler"" listesindeki satırlar, sipariş satırlarından ayrılmıştır.'");
	Else
		NotificationText1 = NStr("vi = 'Các dòng trong danh sách ""Hàng hóa"" được bỏ liên kết từ các dòng đặt hàng.';
								|ru = 'Строки в списке ""Товары"" отвязаны от строк заказа.';
								|en = 'Lines in Item list are unlinked from order lines.'; fa = 'Lines in Item list are unlinked from order lines.';
								|it = 'Le righe dell''elenco ""Merci"" sono scollegate dalle righe dell''ordine.';
								|pl = 'Wiersze na liście ""Wiersze pozycji"" są odwiązane od wierszy zamówienia.';
								|tr = '""Ürünler"" listesindeki satırlar, sipariş satırından ayrılmıştır.'");
	EndIf;
	
	ShowUserNotification(NStr("vi = 'Xử lý danh sách ""Hàng hóa""';
								|ru = 'Обработка списка ""Товары""';
								|en = 'The Item list processing'; fa = 'The Item list processing';
								|it = 'Elaborazione dell''elenco ""Merci""';
								|pl = 'Przetwarzanie listy ""Wiersze pozycji""';
								|tr = '""Ürünler"" listesinin işlenmesi'"),, NotificationText1);
	
EndProcedure

&AtClient
Procedure NotifyAboutLinkingRowsToOrders(OrderRef = Undefined)
	
	If OrderRef <> Undefined Then
		
		TextTemplate1 = NStr("vi = 'Các dòng trong danh sách ""Hàng hóa"" được liên kết với các dòng của chứng từ %OrderDocument%.
			|Các dòng không thể liên kết với các dòng của đơn hàng sẽ bị xóa.';
			|ru = 'Строки в списке ""Товары"" привязаны к строкам документа %OrderDocument%.
			|Строки, которые неудалось привязать к строкам заказа - удалены.';
			|en = 'Lines in Item list are linked to lines of document %OrderDocument%.
			|Lines which cannot be linked to order lines are deleted.'; fa = 'Lines in Item list are linked to lines of document %OrderDocument%.
			|Lines which cannot be linked to order lines are deleted.';
			|it = 'Le righe nell''elenco ""Merci"" sono associate alle righe del documento %OrderDocument%.
			|Le righe che non è stato possibile associare alle righe dell''ordine sono cancellate.';
			|pl = 'Wiersze na liście ""Wiersze pozycji"" są powiązane z wierszami dokumentu %OrderDocument%.
			| Wiersze, które nie mogą być powiązane z wierszami zamówienia, są usunięte.';
			|tr = '""Ürünler"" listesindeki satırlar, belgedeki satırlara bağlanır %OrderDocument%.
			|Sipariş satırlarına bağlanamayan satırlar - silinmiştir.'");
		NotificationText1 = StrReplace(TextTemplate1, "%OrderDocument%", OrderRef);
		
	Else
		
		NotificationText1 = NStr("vi = 'Các dòng trong danh sách ""Hàng hóa"" được liên kết với các dòng của đơn hàng chưa lập.
			|Các dòng không thể liên kết với các dòng của đơn hàng sẽ bị xóa.';
			|ru = 'Строки в списке ""Товары"" привязаны к строкам неоформленных заказов.
			|Строки, которые неудалось привязать к строкам заказов - удалены.';
			|en = 'Lines in Item list are linked to ungenerated order lines.
			|Lines which cannot be linked to order lines are deleted.'; fa = 'Lines in Item list are linked to ungenerated order lines.
			|Lines which cannot be linked to order lines are deleted.';
			|it = 'Le righe nell''elenco ""Merci"" sono associate alle righe degli ordini non formalizzati.
			|Le righe che non è stato possibile associare alle righe degli ordini sono cancellate.';
			|pl = 'Linie na liście ""Wiersze pozycji"" są powiązane z wierszami nieuformowanych zamówień.
			| Wiersze, które nie mogą być powiązane z wierszami zleceń, są usunięte.';
			|tr = '""Ürünler"" listesindeki satırlar düzenlenmeyen sipariş satırlarına bağlanmıştır.
			|Sipariş satırlarına bağlanamayan satırlar - silinmiştir.'");
		
	EndIf;
	
	ShowUserNotification(NStr("vi = 'Xử lý danh sách ""Hàng hóa""';
								|ru = 'Обработка списка ""Товары""';
								|en = 'The Item list processing'; fa = 'The Item list processing';
								|it = 'Elaborazione dell''elenco ""Merci""';
								|pl = 'Przetwarzanie listy ""Wiersze pozycji""';
								|tr = '""Ürünler"" listesinin işlenmesi'"),, NotificationText1);
	
EndProcedure

&AtClient
Procedure NotifyAboutFillingInOrderBalances(OrderRef = Undefined)
	
	If Object.Goods.Count() > 0 Then
	
		If OrderRef <> Undefined Then
		
			TextTemplate1 = NStr("vi = 'Danh sách ""Hàng hóa"" điền số dư chưa lập theo chứng từ %OrderDocument%.';
								|ru = 'Список ""Товары"" заполнен остатками неоформленных товаров по документу %OrderDocument%.';
								|en = 'The Item list is filled in with remaining unregistered goods under the %OrderDocument% document.'; fa = 'The Item list is filled in with remaining unregistered goods under the %OrderDocument% document.';
								|it = 'L''elenco ""Merci"" è compilato con le rimanenze delle merci non formalizzate per il documento %OrderDocument%.';
								|pl = 'Lista ""Towarów"" jest wypełniona resztkami nieusuniętych towarów na dokumencie %OrderDocument%.';
								|tr = '""Ürünler"" listesi, belgeye göre düzenlenmeyen ürün bakiyeleri ile doldurulur %OrderDocument%.'");
			NotificationText1 = StrReplace(TextTemplate1, "%OrderDocument%", OrderRef);
			
		Else
			
			NotificationText1 = NStr("vi = 'Danh sách ""Hàng hóa"" điền số dư chưa lập theo đơn hàng.';
									|ru = 'Список ""Товары"" заполнен остатками неоформленных товаров по заказам.';
									|en = 'The Item list is filled in with remaining unregistered goods against orders.'; fa = 'The Item list is filled in with remaining unregistered goods against orders.';
									|it = 'L''elenco ""Merci"" è compilato con le rimanenze delle merci non formalizzate per gli ordini.';
									|pl = 'Lista ""Towarów"" jest wypełniona pozostałościami nieformalnych towarów wg zamówień.';
									|tr = '""Ürünler"" listesi, siparişlerdeki düzenlenmeyen ürün bakiyeleri ile doldurulur.'");
			
		EndIf;
		ShowUserNotification(NStr("vi = 'Xử lý danh sách ""Hàng hóa""';
									|ru = 'Обработка списка ""Товары""';
									|en = 'The Item list processing'; fa = 'The Item list processing';
									|it = 'Elaborazione dell''elenco ""Merci""';
									|pl = 'Przetwarzanie listy ""Wiersze pozycji""';
									|tr = '""Ürünler"" listesinin işlenmesi'"),, NotificationText1);
		
	Else
		
		If OrderRef <> Undefined Then
		
			TextTemplate1 = NStr("vi = 'Không có hàng hóa chưa được định dạng theo chứng từ %OrderDocument%.';
								|ru = 'Нет неоформленных товаров по документу %OrderDocument%.';
								|en = 'No unregistered goods for document %OrderDocument%.'; fa = 'No unregistered goods for document %OrderDocument%.';
								|it = 'Nono ci sono merci non registrate per il documento %OrderDocument%.';
								|pl = 'Brak niezarejestrowanych towarów w dokumencie %OrderDocument%.';
								|tr = 'Belgeye göre düzenlenmeyen ürünler bulunmamaktadır %OrderDocument%.'");
			NotificationText1 = StrReplace(TextTemplate1, "%OrderDocument%", OrderRef);
			
		Else
			
			If Not ValueIsFilled(Object.SourceWarehouse) Then
				NotificationText1 = NStr("vi = 'Kho người gửi không đầy đủ.';
										|ru = 'Не заполнен склад-отправитель.';
										|en = 'Origin warehouse is required.'; fa = 'Origin warehouse is required.';
										|it = 'Magazzino-mittente non è compilato.';
										|pl = 'Magazyn wysyłki nie jest wypełniony.';
										|tr = 'Çıkış ambarı doldurulmadı.'");
			ElsIf Not ValueIsFilled(Object.DestinationWarehouse) Then
				NotificationText1 = NStr("vi = 'Kho nhận hàng không đầy đủ.';
										|ru = 'Не заполнен склад-получатель.';
										|en = 'Destination warehouse is required.'; fa = 'Destination warehouse is required.';
										|it = 'Magazzino-destinatario non è compilato.';
										|pl = 'Magazyn odbiorca nie jest wypełniony.';
										|tr = 'Hedef ambar doldurulmadı.'");
			ElsIf Not ValueIsFilled(Object.Organization) Then
				NotificationText1 = NStr("vi = 'Chưa điền doanh nghiệp.';
										|ru = 'Не заполнена организация.';
										|en = 'Company is required.'; fa = 'Company is required.';
										|it = 'Società non è compilata.';
										|pl = 'Firma nie jest wypełniona.';
										|tr = 'İş yeri doldurulmadı.'");
			ElsIf UseMultipleCompanies And UseBusinessUnits Then
				If ValueIsFilled(Object.Department) Then
					TextTemplate1 = NStr("vi = 'Không có hàng hóa chưa lập theo đơn hàng điều chuyển
					                        |từ kho ""%1"" đến kho ""%2"" trong bộ phận ""%3"" của doanh nghiệp ""%4""';
					                        |ru = 'Нет неоформленных товаров по заказам на перемещение
					                        |со склада ""%1"" на склад ""%2"" в подразделении ""%3"" в организации ""%4""';
					                        |en = 'No unregistered goods against orders of transfer
					                        | from warehouse ""%1"" to warehouse ""%2"" in business unit ""%3"" of company ""%4""'; fa = 'No unregistered goods against orders of transfer
					                        | from warehouse ""%1"" to warehouse ""%2"" in business unit ""%3"" of company ""%4""';
					                        |it = 'Non ci sono merci non registrate per gli ordini di trasferimento
					                        |dal magazzino ""%1"" al magazzino ""%2"" del reparto ""%3"" della società ""%4""';
					                        |pl = 'Brak nieujętych towarów na zlecenie przeniesienia 
					                        | z magazynu ""%1"" do magazynu ""%2"" w dziale ""%3"" w firmie ""%4""';
					                        |tr = '%4"""" iş yerinde ""%3"" departmanda""%1"" ambarından ""%2"" ambarına
					                        |transfer siparişlerinde düzenlenmemiş ürün mevcut değil'");
				Else
					TextTemplate1 = NStr("vi = 'Không có hàng hóa chưa lập theo đơn hàng điều chuyển
					                        |từ kho ""%1"" đến kho ""%2"" mà chưa chỉ ra bộ phận trong doanh nghiệp ""%4""';
					                        |ru = 'Нет неоформленных товаров по заказам на перемещение
					                        |со склада ""%1"" на склад ""%2"" без указания подразделения в организации ""%4""';
					                        |en = 'No unregistered goods against orders of goods transfer
					                        | from warehouse ""%1"" to warehouse ""%2"" without specifying a business unit in company ""%4""'; fa = 'No unregistered goods against orders of goods transfer
					                        | from warehouse ""%1"" to warehouse ""%2"" without specifying a business unit in company ""%4""';
					                        |it = 'Non ci sono merci non registrate per gli ordini di trasferimento
					                        |dal magazzino ""%1"" al magazzino ""%2"" senza indicazione di reparto della società ""%4""';
					                        |pl = 'Brak nieujętych towarów na zlecenie przeniesienia 
					                        | z magazynu ""%1"" do magazynu ""%2"" bez podania działu w firmie ""%4""';
					                        |tr = '
					                        |Ambardan ""%1"" ambara ""%2"" transfer emirlerinde, ""%4"" iş yerinde bir departman belirtilmeden düzenlenmemiş ürün mevcut değil'");
				EndIf;
				NotificationText1 = StringFunctionsClientServer.SubstituteParametersToString(TextTemplate1,
					Object.SourceWarehouse, Object.DestinationWarehouse, Object.Department, Object.Organization);
			ElsIf UseMultipleCompanies Then
				TextTemplate1 = NStr("vi = 'Không có hàng hóa chưa lập theo đơn hàng điều chuyển
				                        |từ kho ""%1"" đến kho ""%2"" trong doanh nghiệp ""%3""';
				                        |ru = 'Нет неоформленных товаров по заказам на перемещение
				                        |со склада ""%1"" на склад ""%2"" в организации ""%3""';
				                        |en = 'No unregistered goods against orders of goods transfer
				                        | from warehouse ""%1"" to warehouse ""%2"" in company ""%3""'; fa = 'No unregistered goods against orders of goods transfer
				                        | from warehouse ""%1"" to warehouse ""%2"" in company ""%3""';
				                        |it = 'Non ci sono merci non registrate per gli ordini di trasferimento
				                        |dal magazzino ""%1"" al magazzino ""%2"" della società ""%3""';
				                        |pl = 'Brak nieujętych towarów na zlecenie przeniesienia 
				                        | z magazynu ""%1"" do magazynu ""%2"" w firmie ""%3""';
				                        |tr = '""%3"" iş yerinde ""%1"" ambardan ""%2"" ambara transfer
				                        |siparişlerinde düzenlenmemiş ürün mevcut değil'");
				NotificationText1 = StringFunctionsClientServer.SubstituteParametersToString(TextTemplate1,
					Object.SourceWarehouse, Object.DestinationWarehouse, Object.Organization);
			ElsIf UseBusinessUnits Then
				If ValueIsFilled(Object.Department) Then
					TextTemplate1 = NStr("vi = 'Không có hàng hóa chưa lập theo đơn hàng điều chuyển
					                        |từ kho ""%1"" đến kho ""%2"" trong bộ phận ""%3""';
					                        |ru = 'Нет неоформленных товаров по заказам на перемещение
					                        |со склада ""%1"" на склад ""%2"" в подразделении ""%3""';
					                        |en = 'No unregistered goods against orders of goods transfer
					                        | from warehouse ""%1"" to warehouse ""%2"" in business unit ""%3""'; fa = 'No unregistered goods against orders of goods transfer
					                        | from warehouse ""%1"" to warehouse ""%2"" in business unit ""%3""';
					                        |it = 'Non ci sono merci non registrate per gli ordini di trasferimento
					                        |dal magazzino ""%1"" al magazzino ""%2"" del reparto ""%3""';
					                        |pl = 'Brak nieujętych towarów na zlecenie przeniesienia 
					                        | z magazynu ""%1"" do magazynu ""%2"" w dziale ""%3""';
					                        |tr = '""%1"" ambarından ""%3"" departmanındaki""%2"" ambara
					                        |transfer siparişlerinde düzenlenmemiş ürün mevcut değil'");
				Else
					TextTemplate1 = NStr("vi = 'Không có hàng hóa chưa lập theo đơn hàng điều chuyển
					                        |từ kho ""%1"" đến kho ""%2"" mà chưa chỉ ra bộ phận';
					                        |ru = 'Нет неоформленных товаров по заказам на перемещение
					                        |со склада ""%1"" на склад ""%2"" без указания подразделения';
					                        |en = 'No unregistered goods against orders of transfer
					                        | from warehouse ""%1"" to warehouse ""%2"" without specifying a business unit'; fa = 'No unregistered goods against orders of transfer
					                        | from warehouse ""%1"" to warehouse ""%2"" without specifying a business unit';
					                        |it = 'Non ci sono merci non registrate per gli ordini di trasferimento
					                        |dal magazzino ""%1"" al magazzino ""%2"" senza indicazione di reparto';
					                        |pl = 'Brak nieujętych towarów na zlecenie przeniesienia 
					                        | z magazynu ""%1"" do magazynu ""%2"" bez podania działu';
					                        |tr = 'Departman belirtilmeden ambardan ""%1"" ambara ""%2""
					                        |transfer siparişlerinde düzenlenmemiş ürün mevcut değil'");
				EndIf;
				NotificationText1 = StringFunctionsClientServer.SubstituteParametersToString(TextTemplate1,
					Object.SourceWarehouse, Object.DestinationWarehouse, Object.Department);
			Else
				TextTemplate1 = NStr("vi = 'Không có hàng hóa chưa lập theo đơn hàng điều chuyển
				                        |từ kho ""%1"" đến kho ""%2""';
				                        |ru = 'Нет неоформленных товаров по заказам на перемещение
				                        |со склада ""%1"" на склад ""%2""';
				                        |en = 'No unregistered goods against orders of goods transfer
				                        | from warehouse ""%1"" to warehouse ""%2""'; fa = 'No unregistered goods against orders of goods transfer
				                        | from warehouse ""%1"" to warehouse ""%2""';
				                        |it = 'Non ci sono merci non registrate per gli ordini di trasferimento
				                        |dal magazzino ""%1"" al magazzino ""%2""';
				                        |pl = 'Brak nieujętych towarów na zlecenie przeniesienia 
				                        | z magazynu ""%1"" do magazynu ""%2""';
				                        |tr = '""%1"" ambarından ""%2"" ambara
				                        |transfer siparişlerinde düzenlenmemiş ürün mevcut değil'");
				NotificationText1 = StringFunctionsClientServer.SubstituteParametersToString(TextTemplate1,
					Object.SourceWarehouse, Object.DestinationWarehouse);
			EndIf;
			
		EndIf;
		ShowMessageBox(, NotificationText1);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenYouChangeMovementForMultipleOrders(CachedValues)
	
	If Object.TransferAgainstOrders Then
		
		If Object.Goods.Count() = 0 Then
			FillInFromOrderServer();
		Else
			LinkRowsToMovingOrders(Not UseTransferAgainstSeveralOrders);
		EndIf;
		
		If UseTransferAgainstSeveralOrders Then
			Object.SalesOpportunity = Catalogs.SalesOpportunitiesToCustomer.EmptyRef();
		EndIf;
		Object.LockedGoodsTransfer = False;
		Object.ControlledLotOfTheSender = Catalogs.ControlledLots.EmptyRef();
		
		FillInServiceDetailsForProductRange();
		
	Else
		
		Object.TransferOrder = Documents.TransferOrder.EmptyRef();
		UnlinkFromOrderServer(CachedValues, True);
		OrderList.Clear();
		ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
		
	EndIf;
	
	// Recalculating the Quantity of Packages field
	Documents.InventoryTransfer.UpdateDependentDetailsOfTablePart(Object.Goods, Undefined);
	
	QualityControl.UpdateActionParameters(Documents.InventoryTransfer, Object, CacheQualityControl);
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInSenderSControlledLotReference", CacheQualityControl);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	UpdateOrderInformation();
	UpdateOrderDeviations();
	UpdateDependentDetailsOfServerByOrderForm();
	
	Items.SalesOpportunity.Visible = Not (UseTransferAgainstSeveralOrders And Object.TransferAgainstOrders);
	Items.GoodsSalesOpportunity.Visible = UseTransferAgainstSeveralOrders And Object.TransferAgainstOrders;
	ConfigurePickUpByOrdersOrdersCommand(False);
	TMCommonUseClientServer.SetFormItemProperty(Items, "SalesOpportunity", "Visible", Not (UseTransferAgainstSeveralOrders And Object.TransferAgainstOrders));
	
	SetVisibilityOfItemsOverOrder(Items, Object.TransferAgainstOrders);
	
	GoodsDelivery.WhenChangingFlagForOrders(Items, Object, Object.TransferAgainstOrders);
	SetVisibilityOfCommandsByOrder();
	EstablishVisibilityOfQualityControlGroup();
	
EndProcedure

&AtServer
Function LinkRowsToMovingOrders(SelectByOrder_ = False)
	
	If Not UseTransferOrders
		Or Not UseTransferAgainstSeveralOrders And Not ValueIsFilled(Object.TransferOrder) Then
		
		Return False;
		
	EndIf;
	
	Query = New Query(
	"SELECT
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|WHERE
	|	Goods.RowCode = 0
	|	AND Goods.TransferOrder = VALUE(Document.TransferOrder.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	OrdersTable.TransferOrder.SalesOpportunity AS SalesOpportunity,
	|	OrdersTable.TransferOrder        AS TransferOrder,
	|	OrdersTable.Products              AS Products,
	|	OrdersTable.Characteristic            AS Characteristic,
	|	OrdersTable.RowCode                 AS RowCode,
	|	SUM(OrdersTable.ToRegister)        AS ToRegisterBalance
	|INTO MovingOrdersWithoutAssignments
	|FROM
	|	(SELECT
	|		Orders.TransferOrder AS TransferOrder,
	|		Orders.Products AS Products,
	|		Orders.Characteristic AS Characteristic,
	|		Orders.RowCode AS RowCode,
	|		Orders.ToRegisterBalance AS ToRegister
	|	FROM
	|		AccumulationRegister.TransferOrders.Balance(,
	|			CASE
	|				WHEN &SelectByOrder_
	|					THEN TransferOrder = &OrderDocument
	|				ELSE
	|					TransferOrder.Organization = &Organization
	|					AND TransferOrder.SourceWarehouse = &SourceWarehouse
	|					AND TransferOrder.DestinationWarehouse = &DestinationWarehouse
	|					AND TransferOrder.GoodsReceiptOption = &GoodsReceiptOption
	|				END
	|				AND (Products, Characteristic) IN
	|					(SELECT
	|						Goods.Products AS Products,
	|						Goods.Characteristic AS Characteristic
	|					FROM
	|					Goods AS Goods)) AS Orders
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Orders.TransferOrder,
	|		Orders.Products,
	|		Orders.Characteristic,
	|		Orders.RowCode,
	|		CASE
	|			WHEN Orders.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -Orders.ToRegister
	|			ELSE Orders.ToRegister
	|		END
	|	FROM
	|		AccumulationRegister.TransferOrders AS Orders
	|	WHERE
	|		Orders.Recorder = &Recorder
	|		AND CASE
	|			WHEN &SelectByOrder_
	|				THEN TransferOrder = &OrderDocument
	|			ELSE
	|				TransferOrder.Organization = &Organization
	|				AND TransferOrder.SourceWarehouse = &SourceWarehouse
	|				AND TransferOrder.DestinationWarehouse = &DestinationWarehouse
	|				AND TransferOrder.GoodsReceiptOption = &GoodsReceiptOption
	|		END
	|		AND Orders.Active
	|		AND (Products, Characteristic) IN
	|			(SELECT
	|				Goods.Products AS Products,
	|				Goods.Characteristic AS Characteristic
	|			FROM
	|				Goods AS Goods)
	|		) AS OrdersTable
	|
	|GROUP BY
	|	OrdersTable.Products,
	|	OrdersTable.Characteristic,
	|	OrdersTable.RowCode,
	|	OrdersTable.TransferOrder
	|
	|HAVING
	|	SUM(OrdersTable.ToRegister) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OrdersTable.TransferOrder.SalesOpportunity AS SalesOpportunity,
	|	OrdersTable.TransferOrder        AS TransferOrder,
	|	OrdersTable.Products              AS Products,
	|	OrdersTable.Characteristic            AS Characteristic,
	|	OrdersTable.RowCode                 AS RowCode,
	|	GoodsTable.ShipmentStart            AS ShipmentStart,
	|	GoodsTable.LineNumber               AS LineNumber,
	|	OrdersTable.ToRegisterBalance        AS ToRegisterBalance,
	|	CASE WHEN GoodsTable.WithAssignment THEN
	|				
	|				CASE WHEN GoodsTable.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|					OR (GoodsTable.Ref.AssignByOrderAssignment
	|						AND GoodsTable.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.Own)) THEN
	|						GoodsTable.Ref.Purpose
	|					ELSE
	|						GoodsTable.Purpose
	|				END
	|			ELSE
	|				VALUE(Catalog.Assignments.EmptyRef)
	|		END AS AssignmentSender,
	|	GoodsTable.Purpose AS Purpose
	|INTO TransferOrders
	|FROM
	|	MovingOrdersWithoutAssignments AS OrdersTable
	|		LEFT JOIN Document.TransferOrder.Goods AS GoodsTable
	|		ON GoodsTable.Ref = OrdersTable.TransferOrder
	|		 AND GoodsTable.RowCode = OrdersTable.RowCode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	COUNT(*) AS DuplicateCount,
	|	TransferOrders.Products AS Products,
	|	TransferOrders.Characteristic AS Characteristic,
	|	TransferOrders.AssignmentSender AS AssignmentSender,
	|	TransferOrders.Purpose AS Purpose
	|INTO DuplicatesOfProducts
	|FROM
	|	TransferOrders AS TransferOrders
	|
	|GROUP BY
	|	TransferOrders.Products,
	|	TransferOrders.Characteristic,
	|	TransferOrders.AssignmentSender,
	|	TransferOrders.Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Orders.SalesOpportunity AS SalesOpportunity,
	|	Orders.TransferOrder AS TransferOrder,
	|	Orders.Products AS Products,
	|	Orders.Characteristic AS Characteristic,
	|	Orders.RowCode AS RowCode,
	|	Orders.AssignmentSender AS AssignmentSender,
	|	Orders.Purpose AS Purpose,
	|	Orders.ToRegisterBalance AS ToRegisterBalance,
	|	0 AS Allocated,
	|	DuplicatesOfProducts.DuplicateCount AS DuplicateCount
	|FROM
	|	TransferOrders AS Orders
	|		LEFT JOIN DuplicatesOfProducts AS DuplicatesOfProducts
	|		ON Orders.Products = DuplicatesOfProducts.Products
	|			AND Orders.Characteristic = DuplicatesOfProducts.Characteristic
	|			AND Orders.AssignmentSender = DuplicatesOfProducts.AssignmentSender
	|			AND Orders.Purpose = DuplicatesOfProducts.Purpose
	|
	|ORDER BY
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	AssignmentSender,
	|	ShipmentStart,
	|	TransferOrder,
	|	LineNumber");
	
	Query.SetParameter("OrderDocument",            Object.TransferOrder);
	Query.SetParameter("Organization",      Object.Organization);
	Query.SetParameter("SourceWarehouse", Object.SourceWarehouse);
	Query.SetParameter("DestinationWarehouse",  Object.DestinationWarehouse);
	Query.SetParameter("Recorder",      Object.Ref);
	Query.SetParameter("SelectByOrder_", SelectByOrder_);
	Query.SetParameter("GoodsReceiptOption", Object.GoodsReceiptOption);
	
	Query.SetParameter("Goods", Object.Goods.Unload(,"RowCode,Products,Characteristic,TransferOrder"));
	QueryResult = Query.ExecuteBatch();
	If QueryResult[1].IsEmpty() Then
		Return False;
	EndIf;
	
	Selection = QueryResult[4].Select();
	
	TableOfUnallocatedGoods = New ValueTable();
	TableOfUnallocatedGoods.Columns.Add("Products");
	TableOfUnallocatedGoods.Columns.Add("Characteristic");
	TableOfUnallocatedGoods.Columns.Add("TransferOrder");
	TableOfUnallocatedGoods.Columns.Add("Purpose");
	TableOfUnallocatedGoods.Columns.Add("AssignmentSender");
	TableOfUnallocatedGoods.Columns.Add("RowCode");
	TableOfUnallocatedGoods.Columns.Add("Count");
	TableOfUnallocatedGoods.Columns.Add("SalesOpportunity");
	
	While Selection.Next() Do
		
		TheStructureOfTheSearch = New Structure();
		TheStructureOfTheSearch.Insert("Products",          Selection.Products);
		TheStructureOfTheSearch.Insert("Characteristic",        Selection.Characteristic);
		TheStructureOfTheSearch.Insert("AssignmentSender", Selection.AssignmentSender);
		TheStructureOfTheSearch.Insert("Purpose",            Selection.Purpose);
		TheStructureOfTheSearch.Insert("RowCode",      0);
		
		FoundRows = Object.Goods.FindRows(TheStructureOfTheSearch);
		RetainedQuantity = Selection.ToRegisterBalance;
		
		// If there are no duplicates, we distribute the order line to the invoice lines
		If Selection.DuplicateCount < 2 Then
		
			For Each CurRow In FoundRows Do
				
				If CurRow.Count > RetainedQuantity Then
					
					NewRow = Object.Goods.Add();
					FillPropertyValues(NewRow, CurRow);
					NewRow.Count = CurRow.Count - RetainedQuantity;
					CurRow.Count = RetainedQuantity;
					
				EndIf;
				
				FillPropertyValues(CurRow, Selection, "RowCode,TransferOrder,Purpose,AssignmentSender,SalesOpportunity");
				RetainedQuantity = RetainedQuantity - CurRow.Count;
				
				If RetainedQuantity <= 0 Then
					Break;
				EndIf;
			
			EndDo;
			
		// If there are duplicates, we distribute the order lines according to the invoice lines, taking into account the quantity.
		Else
			
			// On the first pass, we will fill in only if the quantity in the order line and the invoice match.
			
			MatchingStringFound = False;
			
			For Each CurRow In FoundRows Do
				
				If CurRow.Count = Selection.ToRegisterBalance Then
					
					MatchingStringFound = True;
					FillPropertyValues(CurRow, Selection, "RowCode,TransferOrder,Purpose,AssignmentSender,SalesOpportunity");
					
					Break;
					
				EndIf;
				
			EndDo;
			
			If Not MatchingStringFound Then
				
				NewRow = TableOfUnallocatedGoods.Add();
				FillPropertyValues(NewRow, Selection);
				NewRow.Count = RetainedQuantity;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	// We will distribute duplicates of goods that were not distributed on the first pass
	If TableOfUnallocatedGoods.Count() > 0 Then
	
		TheStructureOfTheSearch = New Structure();
		TheStructureOfTheSearch.Insert("RowCode", 0);
		TheStructureOfTheSearch.Insert("TransferOrder", Documents.TransferOrder.EmptyRef());
		
		ProductLines_3 = Object.Goods.FindRows(TheStructureOfTheSearch);
		TotalRowsToProcess = ProductLines_3.Count();
		
		IndexOf = 0;
		While IndexOf < TotalRowsToProcess Do
			
			LineProducts_ = ProductLines_3[IndexOf];
			
			// We will find the necessary rows in the table of unallocated goods
			TheStructureOfTheSearch = New Structure();
			TheStructureOfTheSearch.Insert("Products",          LineProducts_.Products);
			TheStructureOfTheSearch.Insert("Characteristic",        LineProducts_.Characteristic);
			TheStructureOfTheSearch.Insert("AssignmentSender", LineProducts_.AssignmentSender);
			TheStructureOfTheSearch.Insert("Purpose",            LineProducts_.Purpose);
			
			FoundRows = TableOfUnallocatedGoods.FindRows(TheStructureOfTheSearch);
			
			For Each CurRow In FoundRows Do
				If CurRow.Products = LineProducts_.Products
					And CurRow.Characteristic = LineProducts_.Characteristic
					And CurRow.Count > 0 Then
					
					NumberOfEmployees = Min(CurRow.Count, LineProducts_.Count);
					If NumberOfEmployees < LineProducts_.Count Then
						
						NewRow = Object.Goods.Add();
						FillPropertyValues(NewRow, LineProducts_);
						NewRow.Count = LineProducts_.Count - NumberOfEmployees;
						ProductLines_3.Add(NewRow);
						TotalRowsToProcess = TotalRowsToProcess + 1;
						
					EndIf;
					LineProducts_.Count = NumberOfEmployees;
					
					FillPropertyValues(LineProducts_, CurRow, "RowCode,TransferOrder,Purpose,AssignmentSender,SalesOpportunity");
					
					// Reduce the unallocated quantity in the table
					CurRow.Count = CurRow.Count - LineProducts_.Count;
					
					Break;
					
				EndIf;
				
			EndDo;
			
			IndexOf = IndexOf + 1;
			
		EndDo;
		
	EndIf;
	
	For Each CurRow In Object.Goods Do
		If Not ValueIsFilled(CurRow.RowCode) Or Not ValueIsFilled(CurRow.TransferOrder) Then
			CurRow.RowCode = 0;
			CurRow.TransferOrder = Object.TransferOrder;
		EndIf;
	EndDo;
	
	TableOfGoods = Object.Goods.Unload();
	TableOfGoods.GroupBy("ProductsInSet,ItemVariantOfSet,Products,Characteristic,Package,RowCode,BatchesIndicationStatus,
		|TransferOrder,SalesOpportunity,Purpose,AssignmentSender,Series,RowID",
		"Count");
	Object.Goods.Load(TableOfGoods);
	Return True;
	
EndFunction

&AtServer
Procedure RefillByNotes(AnArrayOfOrders)
	
	AnArrayOfOrders.Add(Object.Ref);
	
	FillParameters = Documents.InventoryTransfer.DocumentFillingParameters();
	FillParameters.FormIsOpen          = True;
	FillParameters.FillByWarehouseDocument     = True;
	
	HeaderAttributes = New Structure("Organization, SourceWarehouse, DestinationWarehouse, Department,
		|BusinessOperation, GoodsReceiptOption, Ref");
	FillPropertyValues(HeaderAttributes, Object);
	Documents.InventoryTransfer.InitializeFillingParameters(FillParameters, HeaderAttributes, AnArrayOfOrders);
	
	InvoiceTable = Documents.InventoryTransfer.TableDataAndDocument(Object.Ref);
	
	Documents.InventoryTransfer.FillInByOrdersOrders(InvoiceTable, Object.Ref, FillParameters, Object.PackageBarcodes);
	
	NumberOfIndexes = InvoiceTable.Count() - 1;
	For IndexOf = 0 To NumberOfIndexes Do
		
		String = InvoiceTable[NumberOfIndexes - IndexOf];
		
		If AnArrayOfOrders.Find(String.TransferOrder) = Undefined Then
			Continue;
		EndIf;
		
		If String.NoteQuantity = 0 Then
			InvoiceTable.Delete(String);
		Else
			String.Count = String.NoteQuantity;
		EndIf;
		
	EndDo;
	
	Object.Goods.Load(InvoiceTable);
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInSenderSControlledLotReference", CacheQualityControl);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
	
	// Recalculating the Quantity of Packages field
	Documents.InventoryTransfer.UpdateDependentDetailsOfTablePart(Object.Goods, FillParameters);
	
	// Post-processing is individual for the document
	UpdateSenderAssignmentInProductsTable();
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	FillInServiceDetailsForProductRange();
	
	UpdateOrderInformation();
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
EndProcedure

&AtClient
Procedure ReportResults()
	
	If FillingResults <> Undefined Then
		
		If FillingResults.ThereAreUnassembled Then
			
			ShowUserNotification(
				NStr("vi = 'Số lượng điền lại';
					|ru = 'Количество перезаполнено';
					|en = 'Refilled quantity'; fa = 'Refilled quantity';
					|it = 'La quantità è ricompilata';
					|pl = 'Ponowne wypełnienie ilości.';
					|tr = 'Miktar yeniden dolduruldu'"),,
				NStr("vi = 'Số lượng dòng trong các dòng được bổ sung, có tính đến hàng hóa thu thập trong kho.';
					|ru = 'В строках перезаполнено количество с учетом собирающихся на складе товаров.';
					|en = 'Quantity considering goods that are assembled in the warehouse is refilled in lines.'; fa = 'Quantity considering goods that are assembled in the warehouse is refilled in lines.';
					|it = 'La quantità nelle righe è ricompilata tenuto conto delle merci raccolte in magazzino.';
					|pl = 'W wierszach zapełniono ponownie ilość z uwzględnieniem gromadzących się w magazynie towarów.';
					|tr = 'Satırlarda, ambarda toplanan ürünler dikkate alınarak miktar yeniden dolduruldu.'"),
				PictureLib.Information32);
			
		Else
			
			ShowUserNotification(
				NStr("vi = 'Số lượng điền lại';
					|ru = 'Количество перезаполнено';
					|en = 'Refilled quantity'; fa = 'Refilled quantity';
					|it = 'La quantità è ricompilata';
					|pl = 'Ponowne wypełnienie ilości.';
					|tr = 'Miktar yeniden dolduruldu'"),,
				NStr("vi = 'Trong các dòng điền lại số lượng.';
					|ru = 'В строках перезаполнено количество.';
					|en = 'Quantity is refilled in lines.'; fa = 'Quantity is refilled in lines.';
					|it = 'La quantità nelle righe è stata ricompilata.';
					|pl = 'W wierszach jest ponownie wypełnona ilość.';
					|tr = 'Satırlarda miktar yeniden dolduruldu.'"),
			PictureLib.Information32);
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure


&AtServer
Procedure FillInServiceDetailsForProductRange()
	
	For Each RowGoods In Object.Goods Do
		UpdateOrderDeviationsInLine(RowGoods, Object.TransferAgainstOrders);
	EndDo;
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute",
											New Structure("Products", "ItemVariantsAreUsed"));
	ParametersForFillingInBankingDetails.Insert("FillInArticleAttribute",
											New Structure("Products", "SKU"));
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_",
											New Structure("Products", "ItemsType"));
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Products", ParametersForFillingInBankingDetails);
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods,ParametersForFillingInBankingDetails);
	
	SetsServer.FillInServiceDetails(ThisForm);
	
EndProcedure

&AtServer
Function PutGoodsAndStockTypesInStorage()
	
	OptionsForEditingInventoryTypes       = InventoriesServer.OptionsForEditingInventoryTypes();
	OptionsForEditingInventoryTypes.Warehouse = Object.SourceWarehouse;
	
	If GetFunctionalOption("UseExcisableGoods") Then
		OptionsForEditingInventoryTypes.UseExcisableGoods = True;
	EndIf;
	
	Return InventoriesServer.PutGoodsAndStockTypesInStorage(ThisObject, OptionsForEditingInventoryTypes);
	
EndFunction

&AtServer
Procedure GetStockTypesFromStorage(ValueSelected)
	
	InventoriesServer.ProcessInputOfInventoryTypesManually(ValueSelected, ThisForm);
	
EndProcedure

&AtServer
Procedure ConfigurePickUpByOrdersOrdersCommand(SetAvailability_ = True)
	
	ParametersStructure = New Structure("AdvancedWarehousingOnShipment, OrdersUse, UseInvoicesForSeveralOrders",
		AdvancedWarehousingOnShipment, UseTransferOrders, UseTransferAgainstSeveralOrders);
	
	InvoicesServer.ConfigurePickUpByOrdersOrdersCommand(
		Items.GoodsSelectGoodsByOrdersNotes, ParametersStructure, SetAvailability_);
		
	If Object.Patch Then
		Items.GoodsSelectGoodsByOrdersNotes.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateOrderInformation()
	
	UpdateDependentDetailsOfOrderForm_(
		Object.Goods,
		DiscrepancyOrderText,
		Items);
	
	ParametersOfUpdate = OrdersServer.ParametersForUpdatingOrderInformationInForm();
	
	ParametersOfUpdate.PropsNameOrderList         = "OrderList";
	ParametersOfUpdate.OrderPathInHeader                  = "Object.TransferOrder";
	ParametersOfUpdate.TitleLabelName               = "HeaderOrdersText";
	ParametersOfUpdate.NameOfColumnGroupInTableSection   = "ProductsGroupTransferOrder";
	ParametersOfUpdate.OrderNameInTablePart          = "TransferOrder";
	ParametersOfUpdate.UseOrdersInTabularSection = UseTransferAgainstSeveralOrders;

	OrdersServer.UpdateOrderInformationInForm(ThisForm, Object.Goods, ParametersOfUpdate);
	
EndProcedure

&AtServer
Procedure DeleteLinesOverOrder(Table)
	
	CurrentRowNumber = Table.Count() - 1;
	While CurrentRowNumber >= 0 Do
		If ValueIsFilled(Table[CurrentRowNumber].TransferOrder) 
			And Not ValueIsFilled(Table[CurrentRowNumber].RowCode) Then
			Table.Delete(CurrentRowNumber);
		EndIf;
		CurrentRowNumber = CurrentRowNumber - 1;
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions)
	StructureOfActions.Insert("RecalculateNumberOfUnits");
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
	Notify("Write_InventoryTransfer", NotificationProcessingParameter, Object.Ref);

EndProcedure

&AtServer
Procedure ClearProductsTabularPartWhenWarehouseChanges(UntieAllLinesFromOrder, ClearLines_, CachedValues)
	
	If Object.TransferAgainstOrders And Object.Goods.Count() > 0 And ClearLines_ Then
		Object.Goods.Clear();
	EndIf;
	
	If UntieAllLinesFromOrder Then
		UnlinkFromOrderServer(CachedValues);
	EndIf;
	
	If UseTransferAgainstSeveralOrders Then
		UpdateOrderInformation();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillOperationSelectionList()
	
	If Not GetFormFunctionalOption("UseBranchOfficesWithSeparateBalanceSheets") Then
		
		ListItem = Items.BusinessOperation.ChoiceList.FindByValue(Enums.BusinessTransactions.TransferOfGoodsBetweenBranchOffices);
		If ListItem <> Undefined Then
			Items.BusinessOperation.ChoiceList.Delete(ListItem);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillMultiTurnContainersFromStorageServer(AddressOfContainerInStorage)
	
	ActionStructureModifiedStrings = New Structure;
	ActionStructureModifiedStrings.Insert("RecalculateNumberOfPackages");
	
	StructureOfActionsAddedLines = New Structure;
	StructureOfActionsAddedLines.Insert("RecalculateNumberOfPackages");
	StructureOfActionsAddedLines.Insert("FillInSenderSControlledLotReference", CacheQualityControl);
	StructureOfActionsAddedLines.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActionsAddedLines.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	
	ReusablePackageServer.FillMultiTurnContainersFromStorage(
		Object,
		AddressOfContainerInStorage,
		"Goods",
		"Products,Characteristic",
		ActionStructureModifiedStrings,
		ActionStructureModifiedStrings);
	
	FillInServiceDetailsForProductRange();
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
EndProcedure

&AtServer
Procedure UpdateSenderAssignmentInProductsTable()

	For Each LineProducts_ In Object.Goods Do
		If Not Object.TransferAgainstOrders Or LineProducts_.RowCode = 0 Then
			LineProducts_.AssignmentSender = LineProducts_.Purpose;
		EndIf;
	EndDo;

EndProcedure

&AtClient
Procedure UpdateSenderDestination()

	LineProducts_ = Items.Goods.CurrentData;
	If Not Object.TransferAgainstOrders Or LineProducts_.RowCode = 0 Then
		LineProducts_.AssignmentSender = LineProducts_.Purpose;
	EndIf;

EndProcedure

#EndRegion

#Region Delivery

&AtServer
Procedure MethodPlaceOfDeliveryCarrierIfChangedServer(ItemName)
	
	UpdateTextDocumentsBasedOn();
	GoodsDelivery.FillInDeliveryDetails(Items, ItemName, Object);

EndProcedure

&AtClient
Procedure ProcessAddressChange(Item, NameOfAddressDetails)
	
	AttributesNames = GoodsDeliveryClientServer.NamesOfDetailsOfDeliveryAddresses(NameOfAddressDetails);
	
	If IsBlankString(Object[AttributesNames.NameOfDetailsOfDeliveryAddress]) Then
		
		GoodsDeliveryClient.ClearAddressPresentation(
			Object[AttributesNames.NameOfDetailsOfDeliveryAddress],
			Object[AttributesNames.AttributeNameOfDeliveryAddressFieldValues],
			Object[AttributesNames.NameOfAttributeOfDeliveryAddressValue]);
		
	Else
		
		GoodsDeliveryClient.WhenChangingAddressPresentation(
			Item,
			Object[AttributesNames.NameOfDetailsOfDeliveryAddress],
			Object[AttributesNames.NameOfAttributeOfDeliveryAddressValue]);
		
		DeliveryAddressOnChangeATServer(
			Object[AttributesNames.NameOfDetailsOfDeliveryAddress],
			Object[AttributesNames.NameOfAttributeOfDeliveryAddressValue],
			Object[AttributesNames.AttributeNameOfDeliveryAddressFieldValues]);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure DeliveryAddressOnChangeATServer(Address, AddressValue, FieldValueAddress)
	
	CustomFormatAddress = ContactsManager.AddressEnteredInFreeFormat(AddressValue);
	If Not CustomFormatAddress Then
		
		CountryData1 = ContactsManager.ContactInformationAddressCountry(AddressValue);
		
		NewAddressStructure = ContactsManager.InfoAboutAddress();
		NewAddressStructure.Presentation = Address;
		NewAddressStructure.Country = CountryData1.Description;
		NewAddressStructure.CountryCode = CountryData1.Code;
		
		AddressValue = ContactsManager.ContactInformationInJSON(
			NewAddressStructure,
			Enums.ContactInformationTypes.Address);
		
		SetAddressTypeInFreeForm(AddressValue);
		
	EndIf;
	
	FieldValueAddress = ContactsManager.ContactInformationToXML(
		AddressValue,
		Address,
		Enums.ContactInformationTypes.Address);
	
EndProcedure

&AtServerNoContext
Procedure SetAddressTypeInFreeForm(DeliveryAddressValue)
	
	StringTypeToReplace = """addressType"": ""Administrative-territorial""";
	StringIsFreeType = """addressType"": ""FreeForm""";
	DeliveryAddressValue = StrReplace(DeliveryAddressValue, StringTypeToReplace, StringIsFreeType);
	
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
	
	Columns = "Products,Characteristic,Package,NumberOfPackages,ProductsInSet,ItemVariantOfSet,Purpose";
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInSenderSControlledLotReference", CacheQualityControl);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array();
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);

		UpdateOrderDeviationsInLine(CurrentRow, Object.TransferAgainstOrders);
		CurrentRow.TransferOrder = OrderInOverOrderLine(Object.TransferAgainstOrders, Object.TransferOrder);
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
			
	UpdateSenderAssignmentInProductsTable();
	FillInServiceDetailsForProductRange();
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
	UpdateDependentDetailsOfOrderForm_(
		Object.Goods,
		DiscrepancyOrderText,
		Items);
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfClipboardCommands()
	
	ItemArray = New Array();
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled",
		ProcessingOfTabularForms.ThereAreLinesInClipboard());
	
EndProcedure

&AtClient
Procedure SetAvailabilityOfClipboardCommandsOnClient()
	
	ItemArray = New Array();
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", True);
	
EndProcedure

&AtServer
Procedure FillSetVisibilityAndReFillAvailabilityByShipment()
	
	ConfigurePickUpByOrdersOrdersCommand();
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.InventoryTransfer));
	Items.GroupInformationRequiredStatuses.Visible = DisplayMessageOnUsingStatuses();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	SetVisibilityOfSeriesElements();
	
EndProcedure

&AtServerNoContext
Function ThisIsAReferenceInvoice(Ref, AdvancedWarehousingOnShipment)
	
	Return AdvancedWarehousingOnShipment And InvoicesServer.ThereIsSpendingOrderForShippingOrders(Ref);
	
EndFunction

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
Procedure SpecialTransportationConditionsOnChange(Item)
	
	SpecialTransportationConditionsOnChangeServer();
	
EndProcedure

&AtClient
Procedure SupplementDeliveryInformationWithContacts(Command)
	
	SupplementDeliveryInformationWithContactsServer();
	
EndProcedure

&AtServer
Procedure SpecialTransportationConditionsOnChangeServer()
	
	GoodsDelivery.SpecialTransportationConditionsOnChange(Items, Object);
	
EndProcedure

&AtServer
Procedure SupplementDeliveryInformationWithContactsServer()
	
	GoodsDelivery.SupplementDeliveryInformationWithContacts(Object);
	
EndProcedure

&AtClient
Procedure MovingAnOrderWhenItChangesCompletion(QuestionResult, AdditionalParameters) Export
	
	UserAnswer = QuestionResult;
	If UserAnswer = DialogReturnCode.No Then
		Object.TransferAgainstOrders = Not Object.TransferAgainstOrders;
		Return;
	EndIf;
	
	WhenYouChangeMovementForMultipleOrders(CachedValues);
	
	If Not Object.TransferAgainstOrders
		And Object.Goods.Count() > 0 Then
		NotifyAboutDisconnectingLinesFromOrders();
	EndIf;
	
EndProcedure

// Parameters:
//  Result - Boolean - result of closing the dialog form. 
//  AdditionalParameters - Structure - Additional parameters for performing the action.
&AtClient
Procedure GoodsNomenclatureWhenChangingQuestionToUserCompletion(Result, AdditionalParameters) Export
	
	If Not Result Then
		Return;
	EndIf;
	
	CurrentRow = AdditionalParameters.CurrentRow;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner"      , CurrentRow.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	
	SeriesVerificationParameters = New Structure("Warehouse, SeriesSpecificationParameters");
	SeriesVerificationParameters.Warehouse = New Structure("Sender, Recipient", Object.SourceWarehouse, Object.DestinationWarehouse);
	SeriesVerificationParameters.SeriesSpecificationParameters = SeriesSpecificationParameters;
	StructureOfActions.Insert("CheckSeriesCalculateStatus", SeriesVerificationParameters);
	StructureOfActions.Insert("CheckFillAssignment");
	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Products", StructureOfActions);
	
	StructureOfActions.Insert("FillInSenderSControlledLotReference", CacheQualityControl);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

// Parameters:
//  Result - Boolean - result of closing the dialog form. 
//  AdditionalParameters - Structure - Additional parameters for performing the action.
&AtClient
Procedure GoodsCharacteristicWhenChangingQuestionToUserCompletion(Result, AdditionalParameters) Export
	
	If Not Result Then
		Return;
	EndIf;
	
	CurrentRow = AdditionalParameters.CurrentRow;
	
		StructureOfActions = New Structure;
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

// Parameters:
//  QuestionResult - DialogReturnCode - The result of closing the form with a question to the user. 
//  AdditionalParameters - Structure - Additional parameters for performing the action.
&AtClient
Procedure MoveByOrderSetOrderSelectedCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.No Then
		Object.TransferAgainstOrders = Not Object.TransferAgainstOrders;
		Return;
	EndIf;
	
	TransferOrder = AdditionalParameters.TransferOrder;
	
	Object.TransferOrder = TransferOrder;
	
	ThereAreLinesBeforeFilling = Object.Goods.Count() > 0;
	
	WhenYouChangeMovementForMultipleOrders(CachedValues);
	
	If ThereAreLinesBeforeFilling Then
		NotifyAboutLinkingRowsToOrders(TransferOrder);
	Else
		NotifyAboutFillingInOrderBalances(TransferOrder);
		Object.TransferAgainstOrders = Object.Goods.Count() > 0;
	EndIf;
	
	SetVisibilityOfItemsOverOrder(Items, Object.TransferAgainstOrders);
	
EndProcedure

&AtServer
Procedure UnlinkFromOrderServer(CachedValues, AllRows = True)
	
	If AllRows Then
		RowsCollection = Object.Goods;
	Else
		RowsCollection = Items.Goods.SelectedRows;
	EndIf;
	
	For Each RowID In RowsCollection Do
		
		If AllRows Then
			TableRow = RowID;
			RowID = TableRow.GetID();
		Else
			TableRow = Object.Goods.FindByID(RowID);
		EndIf;
		
		ProductsClientServer.UpdateCachedValuesToAccountForSeries(TableRow, CachedValues, SeriesSpecificationParameters);
		
		TableRow.RowCode = 0;
		TableRow.OrderDiscrepancy_3 = 1;
		TableRow.SalesOpportunity = Catalogs.SalesOpportunitiesToCustomer.EmptyRef();
		TableRow.AssignmentSender = TableRow.Purpose;
		TableRow.TransferOrder = OrderInOverOrderLine(Object.TransferAgainstOrders, Object.TransferOrder);
		
		// Reassign the series lines
		ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Object,SeriesSpecificationParameters,RowID, CachedValues);
		
	EndDo;
	
	UpdateDependentDetailsOfServerByOrderForm();
	
EndProcedure

&AtClientAtServerNoContext
Function OrderInOverOrderLine(TransferAgainstOrders, TransferOrder)
	
	Return ?(TransferAgainstOrders And ValueIsFilled(TransferOrder), TransferOrder, Undefined);
	
EndFunction

&AtServer
Procedure UpdateDependentDetailsOfServerByOrderForm()
	
	If Object.Goods.Count() = 0 
		Or Not Object.TransferAgainstOrders
		Or Not UseTransferOrders Then
		
		Items.PictureDiscrepancyOrder.Picture = New Picture();
		Items.PictureDiscrepancyOrders.Picture = New Picture();
		DiscrepancyOrderText = "";
		
		If Object.Goods.Count() > 0 Then
			For Each LineProducts_ In Object.Goods Do
				LineProducts_.OrderDiscrepancy_3 = 0;
			EndDo;
		EndIf;
		
		NumberOfDiscrepancies = 0;
		
		Return;
	EndIf;
	
	UpdateDependentDetailsOfOrderForm_(
		Object.Goods,
		DiscrepancyOrderText,
		Items);
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateDependentDetailsOfOrderForm_(Goods, DiscrepancyOrderText, FormItems)
	NumberOfDiscrepancies = Goods.Total("OrderDiscrepancy_3");
	
	If NumberOfDiscrepancies > 0 Then
		FormItems.PictureDiscrepancyOrder.Picture = PictureLib.ExceededOrder;
		FormItems.PictureDiscrepancyOrders.Picture = PictureLib.ExceededOrder;
		DiscrepancyOrderText = StrReplace(NStr("vi = 'Dòng khác với đơn hàng';
												|ru = 'Строк сверх заказа';
												|en = 'Lines exceeding the order'; fa = 'Lines exceeding the order';
												|it = 'Righe oltre ordine';
												|pl = 'Wierzy przewyższających zamówienie';
												|tr = 'Sipariş fazlası satırı'") + NStr("vi = ': %NumberOfDiscrepancies%';
																							|ru = ': %NumberOfDiscrepancies%';
																							|en = ': %NumberOfDiscrepancies%'; fa = ': %NumberOfDiscrepancies%';
																							|it = ': %NumberOfDiscrepancies%';
																							|pl = ': %NumberOfDiscrepancies%';
																							|tr = ': %NumberOfDiscrepancies%'"), "%NumberOfDiscrepancies%", NumberOfDiscrepancies);
	Else
		FormItems.PictureDiscrepancyOrder.Picture = New Picture();
		FormItems.PictureDiscrepancyOrders.Picture = New Picture();
		DiscrepancyOrderText = "";
		NumberOfDiscrepancies = 0;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetVisibilityOfItemsOverOrder(Items, TransferAgainstOrders)
	
	ItemArray = New Array;
	ItemArray.Add("GoodsUnlinkFromOrder");
	ItemArray.Add("GoodsContextMenuUnlinkFromOrder");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible", TransferAgainstOrders);

EndProcedure

&AtClient
Procedure NotifyAboutEndOfUnbindingLines(NumberOfLinesWorked, LinesWereUnlinked = True)

	If LinesWereUnlinked Then
		NotificationText1 = NStr("vi = 'Trong chứng từ đã bỏ các dòng (%%Count%%) khỏi đơn hàng.';
								|ru = 'В документе от заказов отвязано строк (%%Count%%).';
								|en = 'In the document, the lines (%%Count%%) are detached from the orders.'; fa = 'In the document, the lines (%%Count%%) are detached from the orders.';
								|it = 'Righe dissociate (%%Count%%) dagli ordini nel documento.';
								|pl = 'W dokumencie odłączyć od zamówienia (%%Count%%) wierszy.';
								|tr = 'Belgede siparişlerden ayrılmış satırlar (%Count%) vardır.'");
		NotificationText1 = StrReplace(NotificationText1, "%%Count%%", NumberOfLinesWorked);
		ShowUserNotification(
			NStr("vi = 'Các dòng liên quan';
				|ru = 'Строки отвязаны';
				|en = 'Lines were unlinked'; fa = 'Lines were unlinked';
				|it = 'Righe dissociate';
				|pl = 'Wierze odłączone';
				|tr = 'Ayrılmış satırlar'"),
			,
			NotificationText1,
			PictureLib.Information32);
	Else
		ShowUserNotification(
			NStr("vi = 'Dòng có liên quan';
				|ru = 'Строки не отвязаны';
				|en = 'Lines were not unlinked'; fa = 'Lines were not unlinked';
				|it = 'Righe non dissociate';
				|pl = 'Wierze nie odłączone';
				|tr = 'Satırlar ayrılmadı'"),
			,
			NStr("vi = 'Không có dòng nào liên quan.';
				|ru = 'Ни одна строка не была отвязана.';
				|en = 'No line was unlinked.'; fa = 'No line was unlinked.';
				|it = 'Nessuna riga è stata dissociata.';
				|pl = 'Nie odłączono ani jednego wiersza.';
				|tr = 'Hiçbir satır ayrılmamış.'"),
			PictureLib.Information32);
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateOrderDeviations()
	
	For Each CurRow In Object.Goods Do
		UpdateOrderDeviationsInLine(CurRow, Object.TransferAgainstOrders);
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateOrderDeviationsInLine(CurrentRow, TransferAgainstOrders)
	
	If TransferAgainstOrders Then
		If CurrentRow.RowCode = 0 Then
			CurrentRow.OrderDiscrepancy_3 = 1;
		Else
			CurrentRow.OrderDiscrepancy_3 = 0;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure QuestionUserWhenChangingRowDetails(CallbackDescription, CurrentRow)
	
	// If the current line is not related to the order
	If CurrentRow.RowCode = 0 Then
		RunCallback(CallbackDescription, True);
		Return;
	EndIf;
	
	// If none of the key details have changed
	If CurrentRow.Products = PreviousRowDetails.Products
		And CurrentRow.Characteristic = PreviousRowDetails.Characteristic Then
		RunCallback(CallbackDescription, True);
		Return;
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("CurrentRow", CurrentRow);
	AdditionalParameters.Insert("CallbackDescription", CallbackDescription);
	QueryText = NStr("vi = 'Dòng được soạn sẽ không liên quan đến dòng của đơn hàng. Tiếp tục?';
					|ru = 'Редактируемая строка перестанет быть связанной со строкой заказа. Продолжить?';
					|en = 'The edited line will be unlinked from the order line. Continue?'; fa = 'The edited line will be unlinked from the order line. Continue?';
					|it = 'La riga da modificare non sarà più associata alla riga dell''ordine. Continuare?';
					|pl = 'Edytowany wiersz nie będzie powiązany z wierszem zamówienia. Kontynuować?';
					|tr = 'Düzenlenecek satır artık sipariş satırına bağlı olmayacaktır. Devam edilsin mi?'");
	ShowQueryBox(
		New CallbackDescription("QuestionToUserWhenChangingDetailsOfLineQuestionCompletion", ThisObject, AdditionalParameters),
		QueryText,
		QuestionDialogMode.YesNo);
	
EndProcedure

// Parameters:
//  Response - DialogReturnCode - The result of closing the form with a question to the user. 
//  AdditionalParameters - Structure - Additional parameters for performing the action.
&AtClient
Procedure QuestionToUserWhenChangingDetailsOfLineQuestionCompletion(Response, AdditionalParameters) Export
	
	// If the user has confirmed the change in the value of the key details
	If Response = DialogReturnCode.Yes Then
		
		AdditionalParameters.CurrentRow.RowCode = 0;
		UpdateOrderDeviationsInLine(AdditionalParameters.CurrentRow, Object.TransferAgainstOrders);
		RunCallback(AdditionalParameters.CallbackDescription, True);
		
	Else
		
		// If the user refused to change the linked string, we will return the old values
		FillPropertyValues(AdditionalParameters.CurrentRow, PreviousRowDetails);
		RunCallback(AdditionalParameters.CallbackDescription, False);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInFromOrderServer()
	
	Object.Goods.Clear();
	
	AnArrayOfOrders = New Array();
	If Not UseTransferAgainstSeveralOrders Then
		AnArrayOfOrders.Add(Object.TransferOrder);
	EndIf;
	
	HeaderAttributes = New Structure("Organization, Department, SourceWarehouse, DestinationWarehouse, Ref");
	FillPropertyValues(HeaderAttributes, Object);
	
	SelectionData_ = New Structure("AnArrayOfOrders, HeaderAttributes", AnArrayOfOrders, HeaderAttributes);
	
	RegistrationProcedure    = Constants.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.Get();
	OrderFirst = RegistrationProcedure = Enums.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.OrdersFirst;
	SelectionData_.Insert("FillByWarehouseDocument", AdvancedWarehousingOnShipment And OrderFirst);
	QueryResult = Documents.InventoryTransfer.RequestResultForOrderBalances(SelectionData_, "FillingInOrders");
	
	If SelectionData_.FillByWarehouseDocument Then
		
		KeyFields = "TransferOrder, Products, Characteristic, ProductsInSet, ItemVariantOfSet, AssignmentSender, Series";
		InvoicesServer.FillInQuantityIndicatorForOrders(QueryResult.TableOfContents_, QueryResult.TableShipped, KeyFields);
		DeleteLinesOverOrder(QueryResult.TableOfContents_);
		InvoicesServer.FillInOption(Object.Goods, QueryResult.TableOfContents_, "FillByWarehouseDocument");
		
	Else
		
		InvoicesServer.FillInOption(Object.Goods, QueryResult.TableOfContents_, "FillByOrderDocument");
		
	EndIf;
	
	UpdateSenderAssignmentInProductsTable();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	FillInServiceDetailsForProductRange();

EndProcedure

&AtServer
Procedure SetVisibilityOfCommandsByOrder()
	
	Items.CloseOrder.Visible = Object.TransferAgainstOrders;
	Items.CloseOrders_2.Visible = Object.TransferAgainstOrders;
	
EndProcedure

#EndRegion

#Region Sets

&AtClientAtServerNoContext
Function DialColumns(Form)
	
	Columns = New Array;
	Columns.Add("Products");
	Columns.Add("Characteristic");
	
	Columns.Add("Package");
	Columns.Add("Count");
	Columns.Add("NumberOfPackages");
	
	Return Columns;
	
EndFunction

&AtClient
// Called via the description of the message from the general module setclient 
Procedure WhenRemovingComponents(Action, AdditionalParameter) Export
	
	If SetsClient.EditSetAction(Action) Then
		SetsClient.WhenRemovingComponents(ThisForm, "Goods", AdditionalParameter);
	ElsIf SetsClient.DeleteEntireSetAction(Action) Then
		WhenRemovingComponentsOnServer("Goods", AdditionalParameter);
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenRemovingComponentsOnServer(TSName, AdditionalParameter)
	SetsServer.WhenRemovingComponents(ThisForm, TSName, AdditionalParameter);
EndProcedure

&AtServer
Function SetAddressInTemporaryStorage(Var_Parameters)
	
	Return SetsServer.SetAddressInTemporaryStorage(ThisForm, Var_Parameters, "Goods");
	
EndFunction

&AtServer
Procedure AtEndOfEditingSet(AddressInTempStorage)
	
	StructureOfActionsWithAddedStrings = New Structure;
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsWithAddedStrings.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsWithAddedStrings.Insert("FillInSenderSControlledLotReference", CacheQualityControl);
	StructureOfActionsWithAddedStrings.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActionsWithAddedStrings.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Products", StructureOfActionsWithAddedStrings);
	
	DataParameters = New Structure;
	DataParameters.Insert("Data", GetFromTempStorage(AddressInTempStorage));
	DataParameters.Insert("StructureOfActionsWithModifiedStrings", New Structure);
	DataParameters.Insert("StructureOfActionsWithAddedStrings", StructureOfActionsWithAddedStrings);
	DataParameters.Insert("DialColumns", DialColumns(ThisForm));
	DataParameters.Insert("ExceedingOrder", True);
	
	SetsServer.AtEndOfEditingSet(ThisForm, "Goods", DataParameters);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	UpdateOrderDeviations();
	
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
EndProcedure

#EndRegion

&AtServer
Procedure UpdateTextDocumentsBasedOn()
	
	TextsFieldsDocumentsBasedOn.Clear();
	UpdateTextDocumentsBasedOnLocalization();
	TMCommonUseClientServer.UpdateTextDocumentsBasedOn(ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
EndProcedure

#Region ImportDataFromFile

&AtClient
Procedure ShowUploadFormFromFile()
	
	ImportParameters = ImportDataFromFileClient.DataImportParameters();
	ImportParameters.FullTabularSectionName = "InventoryTransfer.Goods";
	ImportParameters.Title               = NStr("vi = 'Kết nhập bảng ''''Hàng hóa'''' từ tệp';
												|ru = 'Загрузка таблицы ""Товары"" из файла';
												|en = 'Import the Goods table from the file'; fa = 'Import the Goods table from the file';
												|it = 'Download della tabella ""Merci"" dal file';
												|pl = 'Wczytywanie tabeli ""Towary"" z pliku';
												|tr = 'Dosyadan ""Ürünler"" tablosunun indirilmesi'");
	
	ImportParameters.TemplateColumns = DescriptionOfTemplateColumnsForUploadingProducts();
	
	Notification = New CallbackDescription("ShowUploadFormFromFileCompletion", ThisObject);
	ImportDataFromFileClient.ShowImportForm(ImportParameters, Notification);
	
EndProcedure

&AtClient
Procedure ShowUploadFormFromFileCompletion(ImportedDataAddress, AdditionalParameters) Export
	
	If ImportedDataAddress = Undefined Then
		Return;
	EndIf;
	
	UploadFromFileOnServer(ImportedDataAddress, AdditionalParameters);
	
EndProcedure

&AtClient
Function DescriptionOfTemplateColumnsForUploadingProducts();
	
	 TemplateColumns = New Array;
	
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("SKU", New TypeDescription("String",, New StringQualifiers(50)), NStr("vi = 'Mã hiệu';
																																		|ru = 'Артикул';
																																		|en = 'Item ID'; fa = 'شناسه قلم';
																																		|it = 'Артикул';
																																		|pl = 'Artykuł';
																																		|tr = 'Ürün kodu'"), 10);
	Column.Parent = "Products";
	TemplateColumns.Add(Column);
	
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("ProductsAndServicesCode", New TypeDescription("String",, New StringQualifiers(11)), NStr("vi = 'Mã hàng';
																																							|ru = 'Код номенклатуры';
																																							|en = 'Items code'; fa = 'کد اقلام';
																																							|it = 'Codice dell''elenco articoli';
																																							|pl = 'Kod towaru';
																																							|tr = 'Öğe kodu'"), 15);
	Column.Parent = "Products";
	TemplateColumns.Add(Column);
	
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("Products", New TypeDescription("String",, New StringQualifiers(150)), NStr("vi = 'Mặt hàng';
																																				|ru = 'Номенклатура';
																																				|en = 'Items'; fa = 'اقلام';
																																				|it = 'Номенклатура';
																																				|pl = 'Pozycja';
																																				|tr = 'Öğe'"), 15);
	TemplateColumns.Add(Column);
	
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("Characteristic", New TypeDescription("String",, New StringQualifiers(150)), NStr("vi = 'Đặc tính';
																																					|ru = 'Характеристика';
																																					|en = 'Variant'; fa = 'گونه';
																																					|it = 'Характеристика';
																																					|pl = 'Charakterystyka';
																																					|tr = 'Varyant'"), 15);
	TemplateColumns.Add(Column);
	
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("Purpose", New TypeDescription("String",, New StringQualifiers(150)), NStr("vi = 'Ấn định';
																																			|ru = 'Назначение';
																																			|en = 'Assignment'; fa = 'تخصیص';
																																			|it = 'Назначение';
																																			|pl = 'Przeznaczenie';
																																			|tr = 'Atama'"), 15);
	TemplateColumns.Add(Column);
	
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("Series", New TypeDescription("String",, New StringQualifiers(150)), NStr("vi = 'Sê-ri';
																																			|ru = 'Серия';
																																			|en = 'Batch'; fa = 'بچ';
																																			|it = 'Серия';
																																			|pl = 'Batch';
																																			|tr = 'Parti'"), 15);
	TemplateColumns.Add(Column);
	
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("PackageCode", New TypeDescription("String",, New StringQualifiers(4)), NStr("vi = 'Mã đóng gói';
																																				|ru = 'Код упаковки';
																																				|en = 'Packaging unit code'; fa = 'کد واحد بسته‌بندی';
																																				|it = 'Codice di imballaggio';
																																				|pl = 'Kod opakowania';
																																				|tr = 'Paketleme ünitesi kodu'"), 12);
	Column.Parent = "Package";
	TemplateColumns.Add(Column);
	
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("Package", New TypeDescription("String",, New StringQualifiers(50)), NStr("vi = 'Bộ đóng gói';
																																			|ru = 'Упаковка';
																																			|en = 'Packaging unit'; fa = 'واحد بسته‌بندی';
																																			|it = 'Упаковка';
																																			|pl = 'Opakowanie';
																																			|tr = 'Paketleme ünitesi'"), 10);
	TemplateColumns.Add(Column);
	
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("NumberOfPackages", New TypeDescription("Number",, New NumberQualifiers(15, 3)), NStr("vi = 'Số lượng';
																																						|ru = 'Количество';
																																						|en = 'Quantity'; fa = 'مقدار';
																																						|it = 'Количество';
																																						|pl = 'Ilość';
																																						|tr = 'Miktar'"), 10);
	TemplateColumns.Add(Column);
	
	For Position = 1 To TemplateColumns.Count() Do
		TemplateColumns[Position-1].Position = Position;
	EndDo;

	Return TemplateColumns;
	
EndFunction

&AtServer
Procedure UploadFromFileOnServer(ImportedDataAddress, AdditionalParameters)
	
	ImportedData = GetFromTempStorage(ImportedDataAddress);
	
	Object.Goods.Load(ImportedData);
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
	For Each LineProducts_ In Object.Goods Do
		
		If ValueIsFilled(LineProducts_.TransferOrder) Then
			Object.TransferAgainstOrders = True;
			If Not UseTransferAgainstSeveralOrders Then
				Object.TransferOrder = LineProducts_.TransferOrder;
			EndIf;
		EndIf;
		LineProducts_.SetIndex = ?(ValueIsFilled(LineProducts_.ProductsInSet), 1, 0);
	EndDo;
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInSenderSControlledLotReference", CacheQualityControl);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
	
	UpdateSenderAssignmentInProductsTable();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	UpdateOrderInformation();
	FillInServiceDetailsForProductRange();
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
EndProcedure

#EndRegion

#EndRegion

#Region Localization

&AtClient
Procedure NotificationProcessingLocalization(EventName, Parameter, Source)
	
	
	Return;
	
EndProcedure


&AtServer
Procedure UpdateTextDocumentsBasedOnLocalization()
	
	
	Return;
	
EndProcedure

&AtClient
Procedure TextDocumentsBasedOnURLProcessingLocalization(FormattedStringURL, StandardProcessing)
	

	Return;
	
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
