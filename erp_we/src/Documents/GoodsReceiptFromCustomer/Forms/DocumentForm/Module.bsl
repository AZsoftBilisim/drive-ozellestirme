#Region Variables

&AtClient
Var CachedValues; // used by the mechanism for processing changes in PM details

&AtClient
Var PreviousRowDetails; // used to unlink the receipt line from the order line

&AtClient
Var CurDataId; // used to pass the current line to the wait handler

&AtClient
Var CounterpartyVerificationWaitHandlerParameters Export;

&AtClient
Var TimeConsumingOperationForm Export;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	// Refund upon receipt of the form for analysis.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If ClientApplication.CurrentInterfaceVariant() =
		ClientApplicationInterfaceVariant.Version8_2 Then
		
		Items.GroupInTotal.BackColor = New Color();
	EndIf;
	
	SetAvailabilityOfClipboardCommands();
	
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object",                   Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization",  True);
	
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	TMCommonUse.CustomizePeripherals(ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
		
	EndIf;
	
	SalesServer.SetModeForSelectingGroupsOfWarehouseItems(Items.Warehouse);
	
	AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(ThisObject, Object.Date);
	
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	
	Items.InscriptionStateOfEDO.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	DocumentCorrection.OnCreateAtServer(ThisObject, Items.LineCorrection);
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecording.OnCreateAtServerDocumentForm(ThisObject);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	AccountingForTraceableGoodsLocalization.SetTitleNumberOfCCD(Items, "GoodsCCDNumber");
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	PreviousRowDetails = New Structure;
	PreviousRowDetails.Insert("SKU");
	PreviousRowDetails.Insert("Products");
	PreviousRowDetails.Insert("ItemsType");
	PreviousRowDetails.Insert("Characteristic");
	PreviousRowDetails.Insert("ItemVariantsAreUsed");
	PreviousRowDetails.Insert("Package");
	PreviousRowDetails.Insert("Count");
	PreviousRowDetails.Insert("NumberOfPackages");
	PreviousRowDetails.Insert("Warehouse");
	PreviousRowDetails.Insert("RowCode");
	PreviousRowDetails.Insert("ReferenceOrder");
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined,
																						ThisObject,
																						"BarcodeScanner");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	ForceCloseTheForm = True;
	
EndProcedure

&AtClient
Procedure OnClose()
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisObject);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "DataProcessor.SelectGoodsToSalesDocument.Form.Form" Then
		
		ProcessingSelectionOfSelectionOnServer(ValueSelected);
		
	ElsIf ChoiceSource.FormName = "CommonForm.AddItemsFromSalesOrderGoodsIssue" Then
		
		ProcessingProductSelectionFromOrder(ValueSelected.AddressInStorage);
		
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected);
		
	ElsIf PurchasesClient.ThisIsSelectionOfCCDNumber(ChoiceSource) Then
		
		ProcessSelectionOfCCDNumber(ValueSelected);
		
	ElsIf ChoiceSource.FormName = "Catalog.InventoryKinds.Form.InventoryOwnerAttributesForm" Then
		
		GetStockTypesFromStorage(ValueSelected);
		
	EndIf;
	
	If Window <> Undefined Then
		Window.Activate();
	EndIf;
	
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
	
	If EventName = "Closing_EditingSet"
		And Parameter.OwnerForm = UUID Then
		
		AtEndOfEditingSet(Parameter.AddressInTempStorage);
		
	EndIf;
	
	If EventName = "CopyingLinesToClipboard" Then
		SetAvailabilityOfClipboardCommandsOnClient();
	EndIf;
	
	If EventName = "EditSet"
		And Parameter.OwnerForm = UUID Then
		
		SetParameters = New Structure;
		SetParameters.Insert("ProductsInSet",   Parameter.ProductsInSet);
		SetParameters.Insert("ItemVariantOfSet", Parameter.ItemVariantOfSet);
		SetParameters.Insert("DialColumns",        DialColumns(ThisObject));
		
		SetAddressInTemporaryStorage = SetAddressInTemporaryStorage(SetParameters);
		
		OpeningParameters = New Structure;
		OpeningParameters.Insert("AddressInTempStorage", SetAddressInTemporaryStorage);
		OpeningParameters.Insert("Ref",                    Object.Ref);
		OpeningParameters.Insert("Date",                      Object.Date);
		OpeningParameters.Insert("Terms",                Object.Terms);
		OpeningParameters.Insert("Warehouse",                     Object.Warehouse);
		OpeningParameters.Insert("Currency",                    Object.Currency);
		OpeningParameters.Insert("ProductsInSet",        Parameter.ProductsInSet);
		OpeningParameters.Insert("ItemVariantOfSet",      Parameter.ItemVariantOfSet);
		OpeningParameters.Insert("HideCommandRemainingQuantityInWarehouses", False);
		OpeningParameters.Insert("Organization", Object.Organization);
		
		OpenForm("DataProcessor.EditSet.Form.Form", OpeningParameters, ThisObject,
			UUID);
		
	EndIf;
	
	DocumentCorrectionClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording	
	SourceDocumentsOriginalsRecordingClient.NotificationHandlerDocumentForm(EventName, ThisObject);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	If EventName = "WhenChangingAgreement"
		And Source = ThisObject Then
		ContractOnChange(Items[Parameter]);
	EndIf;
	
EndProcedure

&AtClient
Procedure NewWriteProcessing(NewObject, Source, StandardProcessing)
	
	If PurchasesClient.ThisIsIndicationOfCCDNumber(Source) Then
		Actions = New Structure;
		
		AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
			Object,
			Actions,
			"Contract");
		
		PurchasesClient.ProcessIndicationOfCCDNumber(ThisObject, NewObject, , , Actions);
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	// Handler of the "Properties" subsystem
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	
	OnReadCreateAtServer();
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	
	DocumentCorrection.OnReadAtServer(ThisObject, Items.LineCorrection);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
	If NotExecuteCheck1BeforeWrite Then
		NotExecuteCheck1BeforeWrite = False;
		Return;
	EndIf;

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If ValueIsFilled(Object.ReferenceOrder) Then
		For Each CurRow In Object.Goods Do
			If Not ValueIsFilled(CurRow.ReferenceOrder) Then
				CurRow.ReferenceOrder = Object.ReferenceOrder;
			EndIf;
		EndDo;
	EndIf;
	
	// Handler of the "Properties" mechanism
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject,
		WriteParameters);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject,
		WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	Documents.GoodsReceiptFromCustomer.CustomizeForm(ThisObject, Object.Number, Object.Date);
	
	UpdateOrderDeviations();
	FillInServiceDetailsForProductRange();
	SetElementProperties();
	
	
	
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Title = "";
	AutoTitle = True;
	
	Notify("Write_GoodsReceiptFromCustomer", WriteParameters, Object.Ref);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisObject, Object, WriteParameters);
	
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	DocumentCorrectionClient.AfterWrite(Object);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)
	
	FormEventsClient.URLProcessing(ThisObject, FormattedStringURL,
		StandardProcessing);
	
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
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	NumberOfDiscrepancies = Object.Goods.Total("OrderDiscrepancy_3");
	
	If ShipmentInExcessOfOrder And NumberOfDiscrepancies > 0 Then
		
		Notification = New CallbackDescription("DateOnChangeCompletion", ThisObject);
		EnterprisePricesFillingClient.AskQuestionAboutRecalculatingPriceWhenDateChanges(Object, Notification);
		
		Return;
		
	EndIf;
	
	DateWhenFragmentWasChanged(False);
	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	If Not ValueIsFilled(Object.Partner) Then
		Return;
	EndIf;
	
	PartnerOnChangeServer();
	
	If ToUseTermsOfSales
		And ValueIsFilled(Object.Terms) Then
		
		SalesClient.NotifyEndOfFillingInDefaultSalesConditions();
		
	EndIf;
	
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyOnChangeServer();
	
	
EndProcedure

&AtClient
Procedure TermsOnChange(Item)

	If Not ValueIsFilled(Object.Terms) Then
		Return;
	EndIf;
	
	If Terms = Object.Terms Then
		Return;
	EndIf;
	
	Contract = Object.Contract;
	Terms = Object.Terms;
	TermsOnChangeServer();
	SalesClient.NotifyEndOfFillingInTermsOfSale();
	
EndProcedure

&AtClient
Procedure TermsStartChoice(Item, ChoiceData, StandardProcessing)
	
	AgreementSelectionParameters = SalesClient.ParametersForStartingSelectionOfAgreementWithClient();
	AgreementSelectionParameters.Item               = Item;
	AgreementSelectionParameters.Partner               = Object.Partner;
	AgreementSelectionParameters.Document              = Object.Terms;
	AgreementSelectionParameters.DocumentDate         = Object.Date;
	AgreementSelectionParameters.FormDataStructure  = Object;
	AgreementSelectionParameters.BusinessOperation = 
		PredefinedValue("Enum.BusinessTransactions.SaleToCustomer");
	
	SalesClient.StartSelectingAgreementWithClient(AgreementSelectionParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	
EndProcedure

&AtClient
Procedure ContractCreating(Item, StandardProcessing)
	
	PurchasesClient.OpenContractCreationForm(ThisObject, Item, "Object.Contract", Object.Partner,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	If Contract = Object.Contract Then
		Return;
	EndIf;
	
	If Object.Goods.Count() > 0 Then
	
		ButtonsList = New ValueList;
		ButtonsList.Add("Continue", NStr("vi = 'Xóa hàng hóa';
										|ru = 'Очистить товары';
										|en = 'Clear goods'; fa = 'Clear goods';
										|it = 'Cancellare le merci';
										|pl = 'Oczyść wiersze pozycji';
										|tr = 'Ürünleri temizle'"));
		ButtonsList.Add("Unlink", NStr("vi = 'Hủy liên kết với lệnh';
										|ru = 'Отвязать от распоряжения';
										|en = 'Unlink from reference'; fa = 'جدا کردن از مرجع';
										|it = 'Scollegare dalla disposizione';
										|pl = 'Odwiąż od dyspozycji';
										|tr = 'Emirden ayır'"));
		
		QueryText = NStr("vi = 'Khi thay đổi hợp đồng, cần xóa hết danh sách ""Hàng hóa"" hoặc bỏ liên kết dòng khỏi lệnh. Tiếp tục?';
						|ru = 'При изменении договора список ""Товары"" необходимо очистить, либо отвязать строки от распоряжения. Продолжить?';
						|en = 'It is required to clear the ""Goods"" list or unlink lines from the reference while changing the contract. Continue?'; fa = 'It is required to clear the ""Goods"" list or unlink lines from the reference while changing the contract. Continue?';
						|it = 'It is required to clear the ""Goods"" list or unlink lines from the reference while changing the contract. Continue?';
						|pl = 'It is required to clear the ""Goods"" list or unlink lines from the reference while changing the contract. Continue?';
						|tr = 'Ambar değiştiğinde, ""Ürünler"" listesinin temizlenmesi veya satırların siparişlerden ayrılması gerekir. Devam edilsin mi?'");
		
		Notification = New CallbackDescription("ContractOnChangeCompletion", ThisObject);
		
		ShowQueryBox(Notification, QueryText, ButtonsList);
	
	Else
		
		ContractOnChangeServer(False, False, True);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	If Warehouse <> Object.Warehouse Then
		
		ReceiptOfCorrection = True;
		For Each TSRow In Object.Goods Do
			
			If ValueIsFilled(TSRow.ReferenceOrder)
				And TypeOf(TSRow.ReferenceOrder) <> Type("DocumentRef.SaleAdjustment") Then
				ReceiptOfCorrection = False;
				Break;
			EndIf;
			
		EndDo;
		
		If Object.Goods.Count() > 0
			And Not ItIsGroupOfWarehousesAndWarehousesUsedByWHForSale(Object.Warehouse)
			And Not ReceiptOfCorrection
			And ValueIsFilled(Warehouse) Then
			
			QueryText = NStr("vi = 'Khi thay đổi kho bãi, các dòng trong danh sách ""Hàng hóa"" sẽ bị bỏ liên kết khỏi lệnh. Tiếp tục?';
							|ru = 'При изменении склада строки списка ""Товары"" будут отвязаны от распоряжений. Продолжить?';
							|en = 'If you change the warehouse, the ""Goods"" list lines will be unlinked from references. Continue?'; fa = 'If you change the warehouse, the ""Goods"" list lines will be unlinked from references. Continue?';
							|it = 'If you change the warehouse, the ""Goods"" list lines will be unlinked from references. Continue?';
							|pl = 'If you change the warehouse, the ""Goods"" list lines will be unlinked from references. Continue?';
							|tr = 'Ambar değiştirildiğinde ürün listesi satırları siparişlerden ayrıştırılacaktır. Devam edilsin mi?'");
			Notification = New CallbackDescription("WarehouseOnChangeCompletion", ThisObject);
			ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo);
			
			Return;
			
		EndIf;
		
		WarehouseOnChangeServer(False, False, True);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	
	If Not ValueIsFilled(Object.Currency) Then
		Object.Currency = DocumentCurrency;
		Return;
	EndIf;
	
	RecalculateAmounts =
		PriceManagementSystemClient.CurrencyConversionRequired(Object, DocumentCurrency);
	
	WhenChangingCurrencyServer(Object.Currency, RecalculateAmounts);
	
	If RecalculateAmounts Then
		PriceManagementSystemClient.NotifyAboutEndOfConversionOfAmountsIntoCurrency(DocumentCurrency, Object.Currency);
	EndIf;

EndProcedure

&AtClient
Procedure ManagerOnChange(Item)
	
	FillInSubordinatePropertiesForStatistics("Manager");
	
EndProcedure

&AtClient
Procedure LineOfBusinessOnChange(Item)
	
	LineOfBusinessOnChangeServer();
	
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item,
																FormattedStringURL,
																StandardProcessing)

	DocumentCorrectionClient.StringFixHandlingNavigationLinks(
		ThisObject, FormattedStringURL, StandardProcessing);
		
EndProcedure

&AtClient
Procedure InscriptionIsTitleOfOrdersClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	FormOpenParameters = New Structure("DocumentsList, Title",
		ListOfOrders_,
		NStr("vi = 'Lệnh (%DocumentsCount%)';
			|ru = 'Распоряжения (%DocumentsCount%)';
			|en = 'References (%DocumentsCount%)'; fa = 'References (%DocumentsCount%)';
			|it = 'Disposizioni (%DocumentsCount%)';
			|pl = 'Zamówienia (%DocumentsCount%)';
			|tr = 'Talimatlar (%DocumentsCount%)'"));
	
	OpenForm(
		"CommonForm.ViewingListOfDocuments",
		FormOpenParameters,
		ThisObject,,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure InscriptionStateOfEDOClick(Item, StandardProcessing)
	
	
EndProcedure

&AtClient
Procedure ReferenceOrderPresentationURLProcessing(Item,
	FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "Open_Order" Then
		ShowValue(, Object.ReferenceOrder)
	Else
		
		// &PerformanceMeasurement
		PerformanceMonitorClient.TimeMeasurement(
			"Document.GoodsReceiptFromCustomer.Form.ReferenceChoiceForm");

		CallbackDescription = New CallbackDescription("CustomerSChoice", ThisObject);
		OpenOrderSelection(CallbackDescription);

	EndIf;
	
EndProcedure

&AtClient
Procedure ReduceShipmentByReferenceOnChange(Item)
	
	ReduceShipmentByReferenceOnChangeServer();
	
EndProcedure

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
	
EndProcedure
// End StandardSubsystems.Properties

&AtClient
Procedure DateOfReceiptOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOfReceiptOnChangeServer();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsOnChange(Item)

	CurrentRow = Items.Goods.CurrentData; 
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, True);
	BatchProcessingOfTablePartClient.ProcessTSString(
		CurrentRow,
		StructureOfActions,
		Undefined);
	
	UpdateDependentDetailsOfOrderForm_(Items, Object.Goods, DiscrepancyOrderText);
	
EndProcedure

&AtClient
Procedure GoodsBeforeRowChange(Item, Cancel)
	FillPropertyValues(PreviousRowDetails, Items.Goods.CurrentData);
EndProcedure

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.GoodsReferenceOrder Then
		
		CurrentData = Items.Goods.CurrentData;
		
		If ValueIsFilled(CurrentData.ReferenceOrder) Then
			ShowValue(Undefined, CurrentData.ReferenceOrder);
		ElsIf ValueIsFilled(Object.ReferenceOrder) Then
			ShowValue(Undefined, Object.ReferenceOrder);
		EndIf;
		
	ElsIf SetsClient.ItemToLock(Field) Then
		
		CurrentRow = Object.Goods.FindByID(RowSelected);
		
		If ValueIsFilled(CurrentRow.ProductsInSet) Then
			
			NotificationParameter1 = New Structure;
			NotificationParameter1.Insert("ProductsInSet",   CurrentRow.ProductsInSet);
			NotificationParameter1.Insert("ItemVariantOfSet", CurrentRow.ItemVariantOfSet);
			NotificationParameter1.Insert("OwnerForm",        UUID);
			
			Notify("EditSet", NotificationParameter1, ThisObject);
			
		EndIf;
		
	ElsIf Field = Items.GoodsProductsInSet Then
		
		CurrentData = Items.Goods.CurrentData;
		
		ShowValue(Undefined, CurrentData.ProductsInSet);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)

	If Not ShipmentInExcessOfOrder Then
		
		Cancel = True;
		OpenSelectionByOrdersOrders();
		
	EndIf;

	If Copy Then
		SetsClient.BeforeDeletingRowOfTablePart(ThisObject, "Goods", Cancel, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters);
	
	SetsClient.BeforeDeletingRowOfTablePart(ThisObject, "Goods", Cancel);
	
EndProcedure

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.Goods.CurrentData;
	
	If NewRow And Not UseReceiptForMultipleOrders Then
		CurrentData.ReferenceOrder = Object.ReferenceOrder;
	ElsIf NewRow Then
		CurrentData.ReferenceOrder = Undefined;
	EndIf;
	
	If Copy Then
		
		CurrentData.ReferenceOrder = Undefined;
		CurrentData.RowCode = 0;
		CurrentData.Purpose = Undefined;
		
		StructureOfActions = New Structure;
		OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, True);
		BatchProcessingOfTablePartClient.ProcessTSString(
			CurrentData,
			StructureOfActions,
			CachedValues);
		
		UpdateDependentDetailsOfOrderForm_(Items, Object.Goods, DiscrepancyOrderText);
		
	EndIf;
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(
		Item,
		CachedValues,
		SeriesSpecificationParameters,
		Copy);

EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	LineCache = ProcessingOfTabularFormsClientServer.LineCache(Items.Goods, ThisObject);
	
	If Not CancelEdit
		And Not CurrentData.RowCode = 0
		And (Not CurrentData.Products = LineCache.Products
			Or Not CurrentData.Characteristic = LineCache.Characteristic) Then
		CurrentData.RowCode = 0;
	EndIf;
	
	If Not CancelEdit Then
		
		LineCache =
			?(NewRow,
			Undefined,
			ProcessingOfTabularFormsClientServer.LineCache(Items.Goods, ThisObject));
		
		WarehousesClient.UpdateWarehouseTable(WarehouseTable, CurrentData, LineCache, WarehouseGroup_, False);
		
		TotalWarehouses_ = WarehouseTable.Count();
		
		WarehousesClientServer.UpdateWarehouseGroupImage(SeveralWarehousesText, Items.PictureMultipleWarehouses,
			TotalWarehouses_);
		
	EndIf;
	
	UpdateSeriesStatuses =
		ProductsClient.SeriesStatusesNeedToBeUpdated(
			Item,
			CachedValues,
			SeriesSpecificationParameters);
	
	IDCurrentRow        = CurrentData.GetID();
	
	GoodsOnEditEndServer(UpdateSeriesStatuses, CachedValues, IDCurrentRow);
	
	If UpdateSeriesStatuses Then
		ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters);
	EndIf;
	
	UpdateDependentDetailsOfOrderForm_(Items, Object.Goods, DiscrepancyOrderText);
	
EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	
	UpdateSeriesStatuses = ProductsClient.SeriesStatusesNeedToBeUpdated(Item,
																			CachedValues,
																			SeriesSpecificationParameters,
																			True);
	
	GoodsAfterDeleteRowServer(UpdateSeriesStatuses, CachedValues);
	
	If UpdateSeriesStatuses Then
		ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues,
			SeriesSpecificationParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	AdditionalParameters = AdditionalCompletionProcessingParameters();
	AdditionalParameters.CurrentRow = CurrentRow;
	CallbackDescription = New CallbackDescription("GoodsNomenclatureWhenChangingQuestionToUserCompletion",
	                                              ThisObject,
	                                              AdditionalParameters);
	
	QuestionUserWhenChangingRowDetails(CallbackDescription, CurrentRow);
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	AdditionalParameters = AdditionalCompletionProcessingParameters();
	AdditionalParameters.CurrentRow = CurrentRow;
	CallbackDescription      = New CallbackDescription("GoodsCharacteristicWhenChangingQuestionToUserCompletion",
														ThisObject,
														AdditionalParameters);
	
	QuestionUserWhenChangingRowDetails(CallbackDescription, CurrentRow);
	
EndProcedure

&AtClient
Procedure GoodsSeriesOnChange(Item)
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	ValueSelected.Value                   = Items.Goods.CurrentData.Series;
	ValueSelected.CurrentRowID = Items.Goods.CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected);
	
EndProcedure

&AtClient
Procedure GoodsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	OpenSelectionOfSeries(Item.EditText);
	
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	
	BatchProcessingOfTablePartClient.ProcessTSString(
		CurrentRow,
		StructureOfActions,
		CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	
	If CurrentRow.Count > 0 Then
		StructureOfActions.Insert("RecalculatePricePerPackage", CurrentRow.Count);
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(
		CurrentRow,
		StructureOfActions,
		CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsPriceOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object, False);
	
	BatchProcessingOfTablePartClient.ProcessTSString(
		CurrentRow,
		StructureOfActions,
		CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsSumOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePriceByAmount");
	
	BatchProcessingOfTablePartClient.ProcessTSString(
		CurrentRow,
		StructureOfActions,
		CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsOnActivateCell(Item)
	
	If Item.CurrentItem = Undefined Then
		
		Return;
		
	ElsIf Item.CurrentItem.Name = "GoodsCCDNumber" Then
		
		PurchasesClient.FillInListOfCCDNumberSelection(Items.Goods.CurrentData,
			Items.GoodsCCDNumber.ChoiceList);
			
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsCCDNumberOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	FillParameters = New Structure("CCDNumber", CurrentData.CCDNumber);
	
	Actions = New Structure;
	Actions.Insert("FillInCCDNumberType", FillParameters);
	Actions.Insert("FillInCountryOfOriginForCCDNumber", FillParameters);
	
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		Actions,
		"Contract");
	
	BatchProcessingOfTablePartClient.ProcessTSString(
		CurrentData,
		Actions,
		Undefined);
	
EndProcedure

&AtClient
Procedure GoodsCCDNumberCreating(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.Goods.CurrentData;
	
	AdditionalParameters = PurchasesClient.AdditionalParametersForCreatingCCDNumber();
	FillPropertyValues(AdditionalParameters, Object);
	FillPropertyValues(AdditionalParameters, ThisObject);
	
	CreationParameters = PurchasesClient.ParametersForCreatingCCDNumber(CurrentData,
																Item.EditText,
																AdditionalParameters);
	
	PurchasesClient.OpenFormForCreatingGTDNumber(ThisObject, CreationParameters);
	
EndProcedure

&AtClient
Procedure GoodsReferenceOrderOnChange(Item)
	UpdateInformationOnOrders();
EndProcedure

&AtClient
Procedure GoodsProductsRecordingAsReceivedOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	CurrentRow = New Structure;
	CurrentRow.Insert("Products", CurrentData.ProductsRecordingAsReceived);
	CurrentRow.Insert("ItemVariantsAreUsed",
		CurrentData.ItemVariantsAreUsedRecordingAsReceived);
	CurrentRow.Insert("Characteristic", CurrentData.CharacteristicRecordingAsReceived);
	CurrentRow.Insert("SKU", CurrentData.SKURegistration);
	CurrentRow.Insert("Series", CurrentData.Series);
	CurrentRow.Insert("BatchesIndicationStatus", CurrentData.BatchesIndicationStatus);
	
	CheckFillWarehouse = BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(
		Object,
		WarehouseGroup_);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentData.CharacteristicRecordingAsReceived);
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("CheckFillWarehouse", CheckFillWarehouse);
	
	BatchProcessingOfTablePartClient.ProcessTSString(
		CurrentRow,
		StructureOfActions,
		Undefined);
	
	CurrentData.CharacteristicRecordingAsReceived             = CurrentRow.Characteristic;
	CurrentData.ItemVariantsAreUsedRecordingAsReceived = CurrentRow.ItemVariantsAreUsed;
	CurrentData.Series                                   = CurrentRow.Series;
	CurrentData.BatchesIndicationStatus                     = CurrentRow.BatchesIndicationStatus;
	CurrentData.SKURegistration                    = CurrentRow.SKU;
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, Undefined);
	
EndProcedure

&AtClient
Procedure GoodsProductsRecordingAsReceivedStartChoice(Item,
																ChoiceData,
																ChoiceByAdding,
																StandardProcessing)

	StandardProcessing = False;
	CurrentData = Items.Goods.CurrentData;
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentData.Characteristic);
	If ValueIsFilled(CurrentData.Characteristic) Then
		StructureOfActions.Insert("FillInDescriptionOfPoorQualityProduct");
	EndIf;
	
	FillInArticleAttribute = New Structure;
	FillInArticleAttribute.Insert("Products", "SKU");
	FillInArticleAttribute.Insert("ProductsOfOriginalQuality", "SKURegistration");
	StructureOfActions.Insert("FillInArticleAttribute", FillInArticleAttribute);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	WarehousesClient.ChangeQuality(CurrentData, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure GoodsDamageOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;
	
	If Not CurrentRow.Damage Then
		
		CurrentRow.ProductsRecordingAsReceived =
			PredefinedValue("Catalog.Products.EmptyRef");
		
		CurrentRow.CharacteristicRecordingAsReceived =
			PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef");
		
		CurrentRow.ItemVariantsAreUsedRecordingAsReceived = False;
		
	EndIf;
	
	CheckFillWarehouse = BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(
		Object,
		WarehouseGroup_);
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("CheckFillWarehouse", CheckFillWarehouse);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsReferenceOrderStartChoice(Item,
													ChoiceData,
													ChoiceByAdding,
													StandardProcessing)
	
	StandardProcessing = False;

	If Items.Goods.CurrentData <> Undefined Then
		
		CallbackDescription = New CallbackDescription("SelectReferenceCompletion", ThisObject);
		OpenOrderSelection(CallbackDescription);
		Return;
		
	EndIf;
	
	UpdateInformationOnOrders();

EndProcedure

&AtClient
Procedure GoodsWarehouseOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	AdditionalParameters = AdditionalCompletionProcessingParameters();
	AdditionalParameters.CurrentRow = CurrentRow;
	CallbackDescription = New CallbackDescription("GoodsWarehouseWhenChangingQuestionToUserCompletion",
														ThisObject,
														AdditionalParameters);
	
	If TypeOf(CurrentRow.ReferenceOrder) = Type("DocumentRef.SaleAdjustment") Then
		RunCallback(CallbackDescription, True);
	Else
		QuestionUserWhenChangingRowDetails(CallbackDescription, CurrentRow);
	EndIf;
	
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
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject, True);
	
EndProcedure

&AtClient
Procedure SetDeletionMarkForADocument(Command)
	
	TMCommonUseClient.SetDeletionMarkForADocument(ThisObject);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject);
	
EndProcedure

&AtClient
Procedure CheckCounterparties(Command)
	
	
EndProcedure

&AtClient
Procedure OpenInventoryKinds(Command)
	
	OptionsForEditingInventoryTypes = PutGoodsAndStockTypesInStorage();
	
	FinancesClient.OpenInventoryKinds(ThisObject, OptionsForEditingInventoryTypes);
	
EndProcedure

#Region FormTableCommandHandlersGoods

&AtClient
Procedure CopyRows(Command)
	
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items.Goods) Then
		CopyLinesOnServer();
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(
			Items.Goods.SelectedRows.Count());
	EndIf;
	
EndProcedure

&AtClient
Procedure InsertRows(Command)
	
	NumberOfProductsBeforeInsertion = Object.Goods.Count();
	
	GetLinesFromClipboard();
	
	NumberOfInserted = Object.Goods.Count() - NumberOfProductsBeforeInsertion;
	
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
	
EndProcedure

&AtClient
Procedure SplitRow(Command)
	
	FormTable  = Items.Goods;
	CurrentData = FormTable.CurrentData;
	
	TableData = Object.Goods;
	
	AttributesNames   = "Count, Sum";
	FieldNameQuantity = "NumberOfPackages";
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.StructureOfRecalculationOfAmount(
		AttributesNames,
		FieldNameQuantity);
	
	AdditionalParameters = New Structure;
	
	If CurrentData <> Undefined Then
		
		BatchProcessingOfTablePartClientServer.FillInStructureForRecalculatingAmount(
			StructureOfRecalculationOfAmount,
			CurrentData);
		
		AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfParametersForSplittingRowInTablePart(
			CurrentData,
			AdditionalParameters);
		
	EndIf;
	
	AdditionalParameters.Insert("StructureOfRecalculationOfAmount", StructureOfRecalculationOfAmount);
	CallbackDescription = New CallbackDescription("SplitRowCompletion",
																ThisObject,
																AdditionalParameters);
	
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, CallbackDescription);
	
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
	KitParameters.Insert("DialColumns",        DialColumns(ThisObject));
	
	SetAddressInTemporaryStorage = SetAddressInTemporaryStorage(KitParameters);
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("Ref",     Object.Ref);
	OpeningParameters.Insert("Date",       Object.Date);
	OpeningParameters.Insert("Terms", Object.Terms);
	OpeningParameters.Insert("Warehouse",      Object.Warehouse);
	OpeningParameters.Insert("Currency",     Object.Currency);
	
	OpeningParameters.Insert("ProductsInSet",   CurrentRow.ProductsInSet);
	OpeningParameters.Insert("ItemVariantOfSet", CurrentRow.ItemVariantOfSet);
	
	OpeningParameters.Insert("HideCommandRemainingQuantityInWarehouses", False);
	OpeningParameters.Insert("AddressInTempStorage",       SetAddressInTemporaryStorage);
	OpeningParameters.Insert("Organization",                     Object.Organization);
	
	OpenForm("DataProcessor.EditSet.Form.Form",
					OpeningParameters,
					ThisObject,
					UUID);
	
EndProcedure

&AtClient
Procedure SearchByBarcodeExecute(Command)
	
	ClearMessages();
	
	Notification = New CallbackDescription("SearchByBarcodeCompletion", ThisObject);
	
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);
	
EndProcedure

&AtClient
Procedure SelectGoodsByOrdersNotes(Command)
	
	OpenSelectionByOrdersOrders();
	
EndProcedure

&AtClient
Procedure GetWeight(Command)
	
	CurrentRow = EquipmentManagerTMClient.CurrentRow(ThisObject);
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	Notification = New CallbackDescription("GetWeightCompletion", ThisObject, CurrentRow);
	
	EquipmentManagerClient.StartGettingWeightWithElectronicScales(Notification, UUID);
	
EndProcedure

&AtClient
Procedure OpenSelectionByOrdersOrders()
	
	AttributesNames =
		"Currency,
		|GoodsReceiptOption,
		|Contract,
		|Counterparty,
		|LineOfBusiness,
		|Organization,
		|ShipmentByOrders,
		|Partner,
		|Department,
		|SalesOpportunity,
		|Warehouse,
		|Terms,
		|Ref,
		|BusinessOperation
		|";
	
	HeaderAttributes = New Structure(AttributesNames);
	FillPropertyValues(HeaderAttributes, Object);
	
	FormParameters = New Structure();
	FormParameters.Insert("HeaderAttributes",                           HeaderAttributes);
	FormParameters.Insert("OrderDocument",                                    Object.ReferenceOrder); 
	// We do not give you the opportunity to select orders, because the order of receipt of goods from the client
	// and the order of the order of receipt of goods from the client do not match by type.
	// For Receipt, the order may be: customer order, return request, shipment of goods to the customer and
	// adjustment of sales. For the order - only the receipt of goods from the client
	FormParameters.Insert("AdvancedWarehousingOnShipment",                 False);
	FormParameters.Insert("AdvancedWarehousingOnGoodsReceipt",              False);
	FormParameters.Insert("InvoiceForOrders",                       True);
	FormParameters.Insert("AddressGoods",                              AddressInvoiceGoods());
	FormParameters.Insert("Invoice",                                Object.Ref);
	FormParameters.Insert("UseInvoicesForSeveralOrders", UseReceiptForMultipleOrders);
	FormParameters.Insert("OrdersAreUsed",                       True);
	FormParameters.Insert("FillInStampData",                  False);
	
	OpenForm("CommonForm.AddItemsFromSalesOrderGoodsIssue",
		FormParameters,
		ThisObject,
		UUID,
		,
		,
		,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure CheckQuantityInTheDocument(Command)
	
	CheckQuantityInTheDocumentClient();
	
EndProcedure

&AtClient
Procedure SpecifySeries(Command)
	
	OpenSelectionOfSeries();
	
EndProcedure

&AtClient
Procedure OpenSelection(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.GoodsReceiptFromCustomer.DocumentForm.Command.OpenSelection");
	
	Cancel = False;
	
	If (ToUseTermsOfSales
			And Not ValueIsFilled(Object.Terms))
		Or Not ValueIsFilled(Object.Currency) Then
		
		ClearMessages();
		ReportErrorsWhenOpeningSelection(Cancel);
		
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	HeaderParameter_ = NStr("vi = 'Chọn hàng hóa vào %Document%';
							|ru = 'Подбор товаров в %Document%';
							|en = 'Pick goods in %Document%'; fa = 'Pick goods in %Document%';
							|it = 'Selezione merci in %Document%';
							|pl = 'Wybór towarów w %Document%';
							|tr = '%Document% içindeki ürünlerin seçimi'");
	
	If ValueIsFilled(Object.Ref) Then
		HeaderParameter_ = StrReplace(HeaderParameter_, "%Document%", Object.Ref);
	Else
		HeaderParameter_ = StrReplace(HeaderParameter_, "%Document%",
			NStr("vi = 'tiếp nhận hàng hóa từ khách';
				|ru = 'поступление товаров от клиента';
				|en = 'goods receipt from customer'; fa = 'goods receipt from customer';
				|it = 'goods receipt from customer';
				|pl = 'goods receipt from customer';
				|tr = 'müşteriden ürün alımı'"));
	EndIf;
	
	FilterByProductType = New Array;
	FilterByProductType.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
	FilterByProductType.Add(PredefinedValue("Enum.ItemsTypes.Set"));
	
	FormParameters = New Structure;
	FormParameters.Insert("Document",    Object.Ref);
	FormParameters.Insert("Title",   HeaderParameter_);
	FormParameters.Insert("Date",        Object.Date);
	FormParameters.Insert("Terms",  Object.Terms);
	FormParameters.Insert("Organization", Object.Organization);
	FormParameters.Insert("Warehouse",       Object.Warehouse);
	FormParameters.Insert("Currency",      Object.Currency);
	
	FormParameters.Insert("FilterByProductType", New FixedArray(FilterByProductType));
	FormParameters.Insert("SeriesSpecificationParameters",  SeriesSpecificationParameters);
	
	FormParameters.Insert("HideManualDiscounts", True);
	
	FormParameters.Insert("LineOfBusiness", Object.LineOfBusiness);
	
	OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form",
					FormParameters,
					ThisObject,
					UUID);
	
EndProcedure

&AtClient
Procedure ImportFromExternalFile(Command)

	ArrayOfProductTypes = New Array;
	ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
	ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.Set"));
	
	ImportParameters = ProcessingOfTabularFormsClient.ProductLoadingParameters();
	ImportParameters.Organization = Object.Organization;
	ImportParameters.ImportPrices = True;

	ImportParameters.ImportCCD  = True;
	ImportParameters.ComponentsPriceParameters.Date       = Object.Date;
	ImportParameters.ComponentsPriceParameters.Currency     = Object.Currency;
	ImportParameters.ComponentsPriceParameters.Terms = Object.Terms;
	ImportParameters.FilterParameters.Insert("ItemsType", ArrayOfProductTypes);

	Notification = New CallbackDescription("ImportFromExternalFileCompletion", ThisObject);
	ProcessingOfTabularFormsClient.ShowProductUploadForm(ImportParameters, Notification);

EndProcedure

&AtClient
Procedure FillThePricesByTermsOfSales(Command)
	
	If EnterprisePricesFillingClient.ItIsNecessaryToFillInPricesByAgreement(Object,
		"Goods",
		NStr("vi = 'Hàng hóa';
			|ru = 'Товары';
			|en = 'Items'; fa = 'اقلام';
			|it = 'Merci';
			|pl = 'Towary';
			|tr = 'Ürünler'")) Then
		
		If ShipmentInExcessOfOrder
			And Not DeviationFromShipmentConditions Then
			
			If Object.Goods.Total("OrderDiscrepancy_3") = 0 Then
				
				WarningText = NStr("vi = 'Không thể gán đơn giá vào các dòng theo lệnh.';
									|ru = 'Цена не может быть назначена в строках по распоряжению.';
									|en = 'Price cannot be assigned in the reference lines.'; fa = 'Price cannot be assigned in the reference lines.';
									|it = 'Price cannot be assigned in the reference lines.';
									|pl = 'Price cannot be assigned in the reference lines.';
									|tr = 'Fiyat, sipariş satırlarına atanamıyor.'");
				
				ShowMessageBox(Undefined, WarningText);
				
				Return;
				
			EndIf;
			
		EndIf;
		
		PricesCalculated = FillThePricesByTermsOfSalesServer();
		
		SalesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ReturnOfSpoiledGoods(Command)

	If Object.ReturnOfSpoiledGoods Then 
		
		ThereAreLinesWithCorruption = CheckDisableConfigureFormForCorruption();
		
		If ThereAreLinesWithCorruption Then
			
			QueryText = NStr("vi = 'Trong quá trình vận hành, thông tin về chất lượng của hàng trả lại sẽ bị xóa. Tiếp tục?';
							|ru = 'При выполнении операции будет очищена информация о качестве возвращаемых товаров. Продолжить?';
							|en = 'Item quality will be cleared. Do you want to continue?'; fa = 'Item quality will be cleared. Do you want to continue?';
							|it = 'Quando si esegue l''operazione, le informazioni sulla qualità delle merci in reso verranno cancellate. Continuare?';
							|pl = 'Podczas wykonania operacji będzie oczyszczona informacja o jakości zwracanych towarów. Kontynuować?';
							|tr = 'İşlem, iade edilen malların kalitesi hakkındaki bilgileri temizleyecektir. Devam edilsin mi?'");
			
			ShowQueryBox(New CallbackDescription("ReturnOfSpoiledGoodsCompletion", ThisObject), QueryText,
				QuestionDialogMode.YesNo,, DialogReturnCode.Yes);
			
		EndIf;
		
	Else
		Object.ReturnOfSpoiledGoods = True;
		ConfigureFormForCorruption();
	EndIf;

EndProcedure

&AtClient
Procedure FillInTheWarehouseInSelectedLines(Command)

	PresentationOfTS  = NStr("vi = 'Hàng hóa';
							|ru = 'Товары';
							|en = 'Items'; fa = 'اقلام';
							|it = 'Items';
							|pl = 'Items';
							|tr = 'Ürünler'");
	SelectedRows = Items.Goods.SelectedRows;
	
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	FillWarehouses_1 = WarehousesClient.CheckPossibilityOfFillingWarehousesInTablePart(Object,
																						Object.Goods,
																						PresentationOfTS,
																						SelectedRows);
	
	If FillWarehouses_1 Then
		
		ReceiptOfCorrection = True;
		ThereIsFullVTCHWarehouse = False;
		For Each SelectedRow In SelectedRows Do
			
			TSRow = Object.Goods.FindByID(SelectedRow);
			
			If ValueIsFilled(TSRow.Warehouse) And TSRow.RowCode <> 0 Then
				ThereIsFullVTCHWarehouse = True;
			EndIf;
			
			If ValueIsFilled(TSRow.ReferenceOrder)
				And TypeOf(TSRow.ReferenceOrder) <> Type("DocumentRef.SaleAdjustment") Then
				ReceiptOfCorrection = False;
			EndIf;
			
			If ThereIsFullVTCHWarehouse And Not ReceiptOfCorrection Then
				Break;
			EndIf;
			
		EndDo;
		
		If ThereIsFullVTCHWarehouse And Not ReceiptOfCorrection Then
			
			QueryText = NStr("vi = 'Khi điền kho bãi vào danh sách ""Hàng hóa"", các dòng theo lệnh đã được điền kho bãi, sẽ bị bỏ liên kết với lệnh. Tiếp tục?';
							|ru = 'При заполнении склада в списке ""Товары"" строки по распоряжению, для которых склад уже заполнен, будут отвязаны от распоряжения. Продолжить?';
							|en = 'If you fill the warehouse, the ""Goods"" list lines with the already filled warehouse will be unlinked from the reference. Continue?'; fa = 'If you fill the warehouse, the ""Goods"" list lines with the already filled warehouse will be unlinked from the reference. Continue?';
							|it = 'If you fill the warehouse, the ""Goods"" list lines with the already filled warehouse will be unlinked from the reference. Continue?';
							|pl = 'If you fill the warehouse, the ""Goods"" list lines with the already filled warehouse will be unlinked from the reference. Continue?';
							|tr = '""Ürünler"" listesinde ambar doldurulurken, ambarın hali hazırda dolu olduğu sipariş satırlarının sipariş ile olan bağlantısı kaldırılacaktır. Devam edilsin mi?'");
			
			Notification = New CallbackDescription("GoodsWarehouseOnChangeCompletion", ThisObject, SelectedRows);
			
			ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo);
			Return;
			
		EndIf;
		
		ShowChoiceOfWarehouseToFillInVHFItems(SelectedRows);
		
	EndIf;

EndProcedure

#EndRegion

&AtClient
Procedure FillInTheGTDNumbersForSalesDocuments(Command)
	
	ThereAreFilledInCCDNumbers = False;
	
	For Each RowOfGoods In Object.Goods Do
		If ValueIsFilled(RowOfGoods.CCDNumber) Then
			ThereAreFilledInCCDNumbers = True;
			
			Break;
		EndIf;
	EndDo;
	
	If ThereAreFilledInCCDNumbers Then

		CallbackDescription = New CallbackDescription("FillInCCDNumbersCompletion", ThisObject);
		QueryText = NStr("vi = 'Số TKHQ sẽ được xóa và điền lại. Tiếp tục?';
						|ru = 'Будут очищены и перезаполнены номера ГТД. Продолжить?';
						|en = 'CCD numbers will be cleared and refilled. Continue?'; fa = 'CCD numbers will be cleared and refilled. Continue?';
						|it = 'I numeri delle polizze doganali di carico verranno eliminati e reinseriti. Continuare?';
						|pl = 'Numery LP zostaną wyczyszczone i uzupełnione. Kontynuować?';
						|tr = 'GKB numarası silinecek ve yeniden doldurulacaktır. Devam edilsin mi?'");
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		
	Else
		FillInCCDNumbersServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	 FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
EndProcedure

&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldDrag(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure

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
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand,
												Var_URL = Undefined,
												StandardProcessing = Undefined)
	
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

// StandardSubsystems.SourceDocumentsOriginalsRecording

&AtClient
Procedure Attachable_OriginalStateDecorationClick()
	SourceDocumentsOriginalsRecordingClient.OpenStateSelectionMenu(ThisObject, Items.OriginalStateDecoration);
EndProcedure

//End StandardSubsystems.SourceDocumentsOriginalsRecording

#EndRegion

#Region Private

#Region OnChangeAttributes

&AtServer
Procedure WhenChangingKeyDetailsStatusOfEDO()
	
	
EndProcedure

&AtServer
Procedure UnlinkFromOrderServer(AllRows = True, UntieOnlyStrings = True)
	
	Var CachedValues;
	
	If AllRows Then
		RowsCollection = Object.Goods;
	Else
		RowsCollection = Items.Goods.SelectedRows;
	EndIf;
	
	For Each CurRow In RowsCollection Do
		
		If AllRows Then
			TableRow = CurRow;
			CurRow = TableRow.GetID();
		Else
			TableRow = Object.Goods.FindByID(CurRow);
		EndIf;
		
		ProductsClientServer.UpdateCachedValuesToAccountForSeries(
			TableRow,
			CachedValues,
			SeriesSpecificationParameters);
		
		TableRow.RowCode = 0;
		TableRow.Purpose = Undefined;
		
		If UntieOnlyStrings Then
			TableRow.OrderDiscrepancy_3 = 1;
		Else
			TableRow.ReferenceOrder = Undefined;
		EndIf;
		
		// Reassign the series lines
		ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(
			Object,
			SeriesSpecificationParameters,
			CurRow,
			CachedValues);
		
	EndDo;
	
	UpdateDependentDetailsOfServerByOrderForm();
	
EndProcedure

&AtClient
Procedure DateOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	If Not QuestionResult = DialogReturnCode.Cancel Then
		DateWhenFragmentWasChanged(QuestionResult);
	EndIf;
	
EndProcedure

&AtServer
Procedure DateOnChangeServer(RecalculatePrices_, PricesCalculated)
	
	If RecalculatePrices_ Then
		PricesCalculated = FillThePricesByTermsOfSalesServer(True);
	Else
		PricesCalculated = False;
	EndIf;
	
	HowToSetSeriesVisibility();
	
	UseTraceableImportedGoodsAccounting = 
		AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(Object.Date);
	
	AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(ThisObject, Object.Date);
	
	If Not Items.ProductsGroupQuantityByRNPT.Visible Then
		RecalculateNumberOfRNPT();
	EndIf;
	
	If QualityControl.UpdateActionParameters(
			Documents.GoodsReceiptFromCustomer,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
EndProcedure

&AtServer
Procedure DateOfReceiptOnChangeServer()
	
	If QualityControl.UpdateActionParameters(
			Documents.GoodsReceiptFromCustomer,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	DirectionsOfActivity = Object.LineOfBusiness;
	
	If ValueIsFilled(Object.Organization) Then
		FillInDefaultContract();
	EndIf;
	
	FillInSubordinatePropertiesForStatistics("Organization");
	
	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible,
		Object.Contract);
	
	If UseLinesOfBusiness Then
		
		LinesOfBusinessServer.FillInDefaultDirection(
				Object.LineOfBusiness,
				Object.Terms,
				Object.Contract);
		
		If DirectionsOfActivity <> Object.LineOfBusiness Then
			LineOfBusinessOnChangeServer();
		EndIf;
		
	EndIf;
	
	If QualityControl.UpdateActionParameters(
			Documents.GoodsReceiptFromCustomer,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	RecalculateNumberOfRNPT();
	WhenChangingKeyDetailsStatusOfEDO();
	SetElementProperties();
	
EndProcedure

&AtServer
Procedure PartnerOnChangeServer()
	
	DirectionsOfActivity = Object.LineOfBusiness;
	
	DocumentSales = FormAttributeToValue("Object");
	DocumentSales.FillInDefaultSalesConditions();
	ResponsiblePersonsServer.FillInManager_(DocumentSales);
	ValueToFormAttribute(DocumentSales, "Object");
	
	DocumentCurrency = Object.Currency;
	
	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible,
		Object.Contract);
	
	If Contract <> Object.Contract Then
		Contract = Object.Contract;
	EndIf;

	If Terms <> Object.Terms Then
		Terms = Object.Terms;
	EndIf;
	
	WarehouseOnChangeServer(False, True);
	FillInServiceDetailsForProductRange();
	
	If UseLinesOfBusiness Then
		
		LinesOfBusinessServer.FillInDefaultDirection(
				Object.LineOfBusiness,
				Object.Terms,
				Object.Contract);
		
		If DirectionsOfActivity <> Object.LineOfBusiness Then
			LineOfBusinessOnChangeServer();
		EndIf;
		
	EndIf;
	
	If QualityControl.UpdateActionParameters(
			Documents.GoodsReceiptFromCustomer,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	SetElementProperties();
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	
	DirectionsOfActivity = Object.LineOfBusiness;
	
	If ValueIsFilled(Object.Counterparty) Then
		FillInDefaultContract();
	EndIf;
	
	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible,
		Object.Contract);
	
	If UseLinesOfBusiness Then
		
		LinesOfBusinessServer.FillInDefaultDirection(
				Object.LineOfBusiness,
				Object.Terms,
				Object.Contract);
		
		If DirectionsOfActivity <> Object.LineOfBusiness Then
			LineOfBusinessOnChangeServer();
		EndIf;
		
	EndIf;
	
	If QualityControl.UpdateActionParameters(
			Documents.GoodsReceiptFromCustomer,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
	PurchasesServer.FillInSelectionListNameOfIncomingDocument(ThisObject, Object.Counterparty);
	WhenChangingKeyDetailsStatusOfEDO();
	SetElementProperties();
	
EndProcedure

&AtServer
Procedure TermsOnChangeServer()
	
	DirectionsOfActivity = Object.LineOfBusiness;
	
	DocumentSales = FormAttributeToValue("Object");
	DocumentSales.FillInTermsOfSalesUnderAgreement();
	ResponsiblePersonsServer.FillInManager_(DocumentSales);
	ValueToFormAttribute(DocumentSales, "Object");
	
	DocumentCurrency = Object.Currency;
	
	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible,
		Object.Contract);
	
	WarehouseOnChangeServer(False, True);
	FillInServiceDetailsForProductRange();
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	If UseLinesOfBusiness Then
		
		LinesOfBusinessServer.FillInDefaultDirection(
				Object.LineOfBusiness,
				Object.Terms,
				Object.Contract);
		
		If DirectionsOfActivity <> Object.LineOfBusiness Then
			LineOfBusinessOnChangeServer();
		EndIf;
		
	EndIf;
	
	If QualityControl.UpdateActionParameters(
			Documents.GoodsReceiptFromCustomer,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
	SetElementProperties();
	
EndProcedure

&AtClient
Procedure ContractOnChangeCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Object.Contract = Contract;
		Return;
	EndIf;
	
	ClearLines =
		Result = "Continue";
	
	UnbindLines =
		Result = "Unlink";
		
	ContractOnChangeServer(ClearLines, UnbindLines, True);
	
EndProcedure

&AtServer
Procedure ContractOnChangeServer(ClearLines, UnbindLines, DirectModificationOfContractField = False)
	
	DirectionsOfActivity = Object.LineOfBusiness;
	
	If ClearLines Then
		
		Object.ReferenceOrder = Undefined;
		Object.Goods.Clear();
		
	ElsIf UnbindLines Then
		
		UnlinkFromOrderServer(True, False);
		
	EndIf;
	
	UpdateInformationOnOrders();
	UpdateDependentDetailsOfServerByOrderForm();
	
	ContractDetails_ = New Structure("Currency, LineOfBusiness, Department", "ARAPCurrency");
	Catalogs.CounterpartyContracts.FillInDocumentDetails(Object, Object.Contract, ContractDetails_);
	
	If UseLinesOfBusiness Then
		
		LinesOfBusinessServer.FillInDefaultDirection(
				Object.LineOfBusiness,
				Object.Terms,
				Object.Contract);
		
		If DirectionsOfActivity <> Object.LineOfBusiness Then
			LineOfBusinessOnChangeServer();
		EndIf;
		
	EndIf;
	
	Contract = Object.Contract;
	ResponsiblePersonsServer.FillInManager_(Object);
	
	If ValueIsFilled(Contract) Then
		DocumentCurrency = Object.Currency;
	EndIf;
	
	RecalculateNumberOfRNPT();
	
	If QualityControl.UpdateActionParameters(
			Documents.GoodsReceiptFromCustomer,
			Object,
			CacheQualityControl,
			DirectModificationOfContractField) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
	WhenChangingKeyDetailsStatusOfEDO();
	SetElementProperties();
	
EndProcedure

&AtServer
Procedure WarehouseOnChangeServer(ClearLines_ = True, UntieAllLinesFromOrder = False, DirectModificationOfWarehouseField = False)
	
	Warehouse       = Object.Warehouse;
	WarehouseGroup_ = ItIsGroupOfWarehousesAndWarehousesUsedByWHForSale(Object.Warehouse);
	
	SetParametersForSelectingProductsWarehouse();
	
	If ClearLines_
		And Not WarehouseGroup_
		And Object.Goods.Count() > 0 Then
		
		Object.Goods.Clear();
		
	EndIf;
	
	WarehousesServer.FillInWarehousesInTablePart(Object.Warehouse, WarehouseGroup_, Object.Goods, True);
	
	If UntieAllLinesFromOrder Then
		UnlinkFromOrderServer();
	EndIf;
	
	If QualityControl.UpdateActionParameters(
			Documents.GoodsReceiptFromCustomer,
			Object,
			CacheQualityControl,
			DirectModificationOfWarehouseField) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
	UpdateInformationOnOrders();
	WhenChangingWarehouseInTablePartServer();
	HowToSetSeriesVisibility();
	
EndProcedure

&AtServer
Procedure WhenChangingCurrencyServer(NewCurrency, RecalculateAmounts)
	
	If RecalculateAmounts Then
		ExecuteRecalculateDocumentAmountsServer(DocumentCurrency, NewCurrency);
	EndIf;
	
	DocumentCurrency = Object.Currency;
	
EndProcedure

&AtServer
Procedure LineOfBusinessOnChangeServer()
	
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
EndProcedure

&AtServer
Procedure ReduceShipmentByReferenceOnChangeServer()
	
	SetElementProperties();
	HowToSetSeriesVisibility();
	
EndProcedure

&AtServer
Procedure WhenChangingWarehouseInTablePartServer()
	
	WarehousesServer.WhenChangingWarehouseInTablePart(Object.Goods, WarehouseTable, WarehouseGroup_, False);
	
	TotalWarehouses_ = WarehouseTable.Count();
	
	WarehousesClientServer.UpdateWarehouseGroupImage(SeveralWarehousesText, Items.PictureMultipleWarehouses,
		TotalWarehouses_);
	
EndProcedure

&AtServer
Procedure UpdateOrderDeviations()
	
	StructureOfActions = New Structure;
	OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, True);
	
	BatchProcessingOfTablePartServer.TreatTS(
		Object.Goods,
		StructureOfActions,
		Undefined);
	
EndProcedure

&AtServer
Procedure UpdateDependentDetailsOfServerByOrderForm()
	
	If Object.Goods.Count() = 0 Then
		
		DiscrepancyOrderText = "";
		
		Items.GroupDiscrepancyOnOrder.Visible = False;
		Items.GroupDiscrepancyOnOrders.Visible = False;
		
		Return;
		
	EndIf;
	
	UpdateDependentDetailsOfOrderForm_(Items, Object.Goods, DiscrepancyOrderText);
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateDependentDetailsOfOrderForm_(FormItems, Goods, DiscrepancyOrderText)
	
	NumberOfDiscrepancies = Goods.Total("OrderDiscrepancy_3");
	
	FormItems.GroupDiscrepancyOnOrder.Visible = NumberOfDiscrepancies > 0;
	FormItems.GroupDiscrepancyOnOrders.Visible = NumberOfDiscrepancies > 0;
	
	If NumberOfDiscrepancies > 0 Then
		DiscrepancyOrderText = NStr("vi = 'Dòng trên lệnh: %NumberOfDiscrepancies%';
									|ru = 'Строк сверх распоряжения: %NumberOfDiscrepancies%';
									|en = 'Lines beyond reference: %NumberOfDiscrepancies%'; fa = 'Lines beyond reference: %NumberOfDiscrepancies%';
									|it = 'Righe oltre la disposizione: %NumberOfDiscrepancies%';
									|pl = 'Wierszy ponad zamówienia: %NumberOfDiscrepancies%';
									|tr = 'Talimatların üzerindeki satırlar: %NumberOfDiscrepancies%'");
		DiscrepancyOrderText = StrReplace(DiscrepancyOrderText, "%NumberOfDiscrepancies%", NumberOfDiscrepancies);
	Else
		DiscrepancyOrderText = "";
	EndIf;
	
EndProcedure

// Goods nomenclature when changing the question to the user completion.
// 
// Parameters:
//	Result - Boolean
//	AdditionalParameters - Structure - 
&AtClient
Procedure GoodsNomenclatureWhenChangingQuestionToUserCompletion(Result, AdditionalParameters) Export
	
	If Not Result
		And ShipmentInExcessOfOrder Then
		
		Return;
		
	EndIf;
	
	CurrentRow = AdditionalParameters.CurrentRow;
	
	If CurrentRow.Damage
		And ValueIsFilled(CurrentRow.ProductsRecordingAsReceived) Then
		
		ThereIsGradation = CheckForGradationServer(CurrentRow.Products,
			CurrentRow.ProductsRecordingAsReceived);
		
		If Not ThereIsGradation Then
			
			CurrentRow.ProductsRecordingAsReceived =
				PredefinedValue("Catalog.Products.EmptyRef");
			
			CurrentRow.CharacteristicRecordingAsReceived =
				PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef");
			
			CurrentRow.ItemVariantsAreUsedRecordingAsReceived = False;
		EndIf;
		
	EndIf;
	
	FillInArticleAttribute          = New Structure("Products", "SKU");
	FillInProductTypeAttribute_  = New Structure("Products", "ItemsType");
	FillInCCDTrackingAttribute = New Structure("Products", "TheRecordsAreKeptByCCD");
	
	CheckSeriesCalculateStatus = New Structure;
	CheckSeriesCalculateStatus.Insert("Warehouse",                  Object.Warehouse);
	CheckSeriesCalculateStatus.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters);
	
	CheckFillWarehouse = BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(
		Object,
		WarehouseGroup_);
	
	CountryOfOriginFillingParameters =
		BatchProcessingOfTablePartClientServer.CountryOfOriginFillingParameters();
	
	ProductsOnChangeOverridable = New Structure;
	ProductsOnChangeOverridable.Insert("FormName",          FormName);
	ProductsOnChangeOverridable.Insert("TabularSectionName", "Goods");
	
	FillInSalePrice = BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInArticleAttribute",               FillInArticleAttribute);
	StructureOfActions.Insert("FillInProductTypeAttribute_",       FillInProductTypeAttribute_);
	StructureOfActions.Insert("CheckCharacteristicsByOwner",    CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("CheckSeriesCalculateStatus",        CheckSeriesCalculateStatus);
	StructureOfActions.Insert("FillInCCDTrackingAttribute",      FillInCCDTrackingAttribute);
	StructureOfActions.Insert("FillInSalePrice",                  FillInSalePrice);
	StructureOfActions.Insert("FillInCountryOfOriginOfProduct",
		CountryOfOriginFillingParameters);
	StructureOfActions.Insert("CheckFillWarehouse",               CheckFillWarehouse);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	StructureOfActions.Insert("ProductsOnChangeOverridable",
		ProductsOnChangeOverridable);
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, True);
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(
		CurrentRow,
		StructureOfActions,
		CachedValues);
	
	FillPropertyValues(PreviousRowDetails, CurrentRow);
	
	If Not CurrentRow.TheRecordsAreKeptByCCD Then
		CurrentRow.CCDNumber = Undefined;
		CurrentRow.OriginCountry = Undefined;
	EndIf;
	
EndProcedure

// Goods characteristic when changing the question to the user completion.
// 
// Parameters:
//	Result - Boolean
//	AdditionalParameters - Structure -
//
&AtClient
Procedure GoodsCharacteristicWhenChangingQuestionToUserCompletion(Result, AdditionalParameters) Export
	
	If Not Result
		And ShipmentInExcessOfOrder Then
		
		Return;
		
	EndIf;
	
	CurrentRow = AdditionalParameters.CurrentRow;
	
	CharacteristicOnChangeOverridable = New Structure;
	CharacteristicOnChangeOverridable.Insert("FormName",          FormName);
	CharacteristicOnChangeOverridable.Insert("TabularSectionName", "Goods");
	
	FillInSalePrice = BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CharacteristicOnChangeOverridable",
		CharacteristicOnChangeOverridable);
	StructureOfActions.Insert("FillInSalePrice", FillInSalePrice);
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object, False);
	OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, True);
	
	If AdditionalParameters.LineDetachedFromOrder Then
		LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject,
			StructureOfActions);
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(
		CurrentRow,
		StructureOfActions,
		CachedValues);
	
EndProcedure

#EndRegion

#Region WorkingWithCounterparties


#EndRegion

#Region Filling_By_Order

&AtClient
Procedure CustomerSChoice(ValueSelected, Var_Parameters) Export
	
	If ValueSelected <> Undefined Then
		Modified  = True;
		
		If Object.Goods.Count() > 0 Then
			NotificationParameters = New Structure("ValueSelected", ValueSelected);
			CallbackDescription  = New CallbackDescription("CustomerSChoiceCompletion",
															ThisObject,
															NotificationParameters);
			
			QueryText = NStr("vi = 'Các dòng trong danh sách Hàng hóa sẽ được điền lại theo lệnh đã chọn. Tiếp tục?';
							|ru = 'Строки в списке Товары будут перезаполнены по выбранному распоряжению. Продолжить?';
							|en = 'This will re-populate rows in the Item list based on the selected references. Continue?'; fa = 'This will re-populate rows in the Item list based on the selected references. Continue?';
							|it = 'Le righe nell''elenco Merci verranno ricompilate in base alla disposizione selezionata. Continuare?';
							|pl = 'Wiersze na liście Wiersze pozycji zostaną wypełnione ponownie zgodnie z wybranym zaówieniem. Kontynuować?';
							|tr = 'Ürünler listesindeki satırlar seçilen sipariş tarafından yeniden doldurulacaktır. Devam edilsin mi?'");
			
			ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		Else
			FillInByOrderServer(ValueSelected);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure CustomerSChoiceCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.No Then
		Return;
	EndIf;
	
	Object.Goods.Clear();
	FillInByOrderServer(AdditionalParameters.ValueSelected);
	
EndProcedure

&AtServer
Procedure PresentationOfOrderServer()
	
	If ValueIsFilled(Object.ReferenceOrder) Then
		ReferenceOrderPresentation = StringFunctions.FormattedString(
										"<a href='Open_Order'>%1</a> <a href='SelectReference'>%2</a>",
										String(Object.ReferenceOrder),
										NStr("vi = 'Thay đổi';
											|ru = 'Изменить';
											|en = 'Edit'; fa = 'ویرایش';
											|it = 'Изменить';
											|pl = 'Edit';
											|tr = 'Değiştir'"));
	Else
		ReferenceOrderPresentation = StringFunctions.FormattedString(
										"‹%1› <a href='SelectReference'>%2</a>",
										NStr("vi = 'chưa chọn';
											|ru = 'не выбрано';
											|en = 'not selected'; fa = 'not selected';
											|it = 'не выбрано';
											|pl = 'not selected';
											|tr = 'seçilmedi'"),
										NStr("vi = 'Chọn';
											|ru = 'Выбрать';
											|en = 'Select'; fa = 'انتخاب';
											|it = 'Выбрать';
											|pl = 'Select';
											|tr = 'Seç'")); 
	EndIf;

EndProcedure

&AtServer
Procedure FillInByOrderServer(ReferenceOrder)
	
	If Not ValueIsFilled(ReferenceOrder) Then
		Return;
	EndIf;
	
	Object.ReferenceOrder = ReferenceOrder;
	
	InvoiceManager = Documents.GoodsReceiptFromCustomer;
	
	HeaderAttributes = InvoiceManager.HeaderAttributes();
	FillPropertyValues(HeaderAttributes, Object);
	
	GoodsTable = Object.Goods.Unload();
	
	AnArrayOfOrders = CommonClientServer.ValueInArray(ReferenceOrder);
	
	FillParameters = InvoiceManager.DocumentFillingParameters();
	InvoiceManager.InitializeFillingParameters(FillParameters, HeaderAttributes, AnArrayOfOrders);
	
	InvoiceManager.FillInByOrdersOrders(GoodsTable, Object.Ref, FillParameters);
	
	TableColumn2 = GoodsTable.Columns.Count; // ValueTableColumn
	TableColumn2.Name = "QuantityBeforeChange_";
	
	TableColumn2 = GoodsTable.Columns.QuantityInOrder; // ValueTableColumn
	TableColumn2.Name = "Count";
	
	Object.Goods.Load(GoodsTable);
	
	InvoiceManager.UpdateDependentDetailsOfTablePart(Object.Goods, Undefined);
	
	If Object.Goods.Count() > 0 Then
		If TypeOf(Object.ReferenceOrder) = Type("DocumentRef.SourceDocument") Then
			
			WarehouseTS = Undefined;
			For Each TSRow In Object.Goods Do
				
				If ValueIsFilled(TSRow.Warehouse) Then
					WarehouseTS = TSRow.Warehouse;
					Break;
				EndIf;
				
			EndDo;
			
			If ValueIsFilled(WarehouseTS) Then
				Object.Warehouse = WarehouseTS;
			EndIf;
			
		Else
			Object.Warehouse = Common.ObjectAttributeValue(Object.ReferenceOrder, "Warehouse");
		EndIf;
	EndIf;
	
	WarehouseOnChangeServer(False, False);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActions,
		"Contract");
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	
	BatchProcessingOfTablePartServer.TreatTS(
		Object.Goods,
		StructureOfActions);
	
	FillInServiceDetailsForProductRange();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	UpdateOrderDeviations();
	UpdateDependentDetailsOfServerByOrderForm();
	
EndProcedure

#EndRegion

#Region WorkingWithClipboard

&AtClient
Procedure SetAvailabilityOfClipboardCommandsOnClient()
	
	ItemArray = New Array();
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", True);
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfClipboardCommands()
	
	ItemArray = New Array();
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items,
		ItemArray,
		"Enabled",
		ProcessingOfTabularForms.ThereAreLinesInClipboard());
	
EndProcedure

&AtServer
Procedure CopyLinesOnServer()
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object.Goods,
		Items.Goods.SelectedRows);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboard()
	
	ArrayOfProductTypes = New Array;
	ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
	
	FilterParameters = New Map;
	FilterParameters.Insert("Products.ItemsType", ArrayOfProductTypes);
	
	Columns = "Products,Characteristic,Package,NumberOfPackages,Sum,AmountIncludingVAT,Warehouse,CCDNumber,
		|Damage,ProductsRecordingAsReceived,CharacteristicRecordingAsReceived,ReferenceOrder,
		|ProductsInSet,ItemVariantOfSet";
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	If TableOfGoods.Columns.Find("AmountIncludingVAT") <> Undefined Then
		
		If TableOfGoods.Columns.Find("Sum") <> Undefined Then
			TableOfGoods.Columns.Delete("Sum");
		EndIf;
		
		TableColumn2 = TableOfGoods.Columns.AmountIncludingVAT; // ValueTableColumn
		TableColumn2.Name = "Sum";
		
	EndIf;
	
	FillInProductTypeAttribute_ = New Structure("Products", "ItemsType");
	CheckFillWarehouse = BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(
		Object,
		WarehouseGroup_);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
		StructureOfActions);
	
	StructureOfActions.Insert("RecalculatePriceByAmount");
	
	AddActionRecalculateNumberOfUnits(Object.BusinessOperation, StructureOfActions, Object.Warehouse);
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActions,
		"Contract");
	
	OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, True);
	
	StructureOfActions.Insert("FillInProductTypeAttribute_", FillInProductTypeAttribute_);
	StructureOfActions.Insert("CheckFillWarehouse", CheckFillWarehouse);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	RowsToProcess = New Array();
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);
		
		If Not Object.ReturnOfSpoiledGoods
			And CurrentRow.Damage Then
			
			CurrentRow.Damage = False;
			CurrentRow.ProductsRecordingAsReceived = Catalogs.Products.EmptyRef();
			CurrentRow.CharacteristicRecordingAsReceived = Catalogs.ItemsCharacteristics.EmptyRef();
			
		EndIf;
		
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	UpdateInformationOnOrders();
	
	FillInServiceDetailsForProductRange();
	WhenChangingWarehouseInTablePartServer();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	UpdateDependentDetailsOfOrderForm_(Items, Object.Goods, DiscrepancyOrderText);
	
EndProcedure

#EndRegion

#Region Damage

&AtServer
Function CheckDisableConfigureFormForCorruption()
	
	ThereAreLinesWithCorruption = Object.Goods.FindRows(New Structure("Damage", True)).Count() > 0;
	If Not ThereAreLinesWithCorruption Then
		
		Object.ReturnOfSpoiledGoods = False;
		ConfigureFormForCorruption();
		
	EndIf;
	
	Return ThereAreLinesWithCorruption;
	
EndFunction

&AtServer
Procedure ConfigureFormForCorruption()
	
	Items.ReturnOfSpoiledGoods.Check                               = Object.ReturnOfSpoiledGoods;
	Items.GoodsGroupProductsShippedEarlier.ShowInHeader = Object.ReturnOfSpoiledGoods;
	Items.GoodsGroupReturnedGoods.Visible            = Object.ReturnOfSpoiledGoods;
	
EndProcedure

&AtClient
Procedure ReturnOfSpoiledGoodsCompletion(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	If Response <> DialogReturnCode.Yes Then
		Return;
	Else
		ClearDisableConfigureFormForCorruption();
	EndIf;
	
EndProcedure

&AtServer
Procedure ClearDisableConfigureFormForCorruption()
	
	Object.ReturnOfSpoiledGoods = False;
	ConfigureFormForCorruption();
	
	RowsToProcess = New Array();
	For Each RowOfTables In Object.Goods Do
		If RowOfTables.Damage Then
			RowsToProcess.Add(RowOfTables);
		EndIf;
		RowOfTables.Damage                       = False;
		RowOfTables.ProductsRecordingAsReceived   = Catalogs.Products.EmptyRef();
		RowOfTables.CharacteristicRecordingAsReceived = Catalogs.ItemsCharacteristics.EmptyRef();
	EndDo;
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.ProcessTSStrings(RowsToProcess, StructureOfActions, Object.Goods);
	
	If SeriesSpecificationParameters.UseItemsBatch Then
		For Each RowOfTables In Object.SetOfSeries Do
			RowOfTables.ProductsRecordingAsReceived   = Catalogs.Products.EmptyRef();
			RowOfTables.CharacteristicRecordingAsReceived = Catalogs.ItemsCharacteristics.EmptyRef();
		EndDo;
	EndIf;

EndProcedure

&AtServer
Function CheckForGradationServer(ProductOfOriginalQuality, NonconformingProducts)
	
	Return InformationRegisters.AnotherQualityGoods.CheckForGradation(ProductOfOriginalQuality,
		NonconformingProducts);
	
EndFunction

#EndRegion

#Region Sets

&AtServer
Procedure AtEndOfEditingSet(AddressInTempStorage)
	
	Data = GetFromTempStorage(AddressInTempStorage);
	
	FillInArticleAttribute                    = New Structure("Products", "SKU");
	FillInProductTypeAttribute_            = New Structure("Products", "ItemsType");
	FillInFeatureAttribute = New Structure("Products",
		"ItemVariantsAreUsed");
	CheckFillWarehouse                    = BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(
		Object, WarehouseGroup_);
	
	StructureOfActionsWithAddedStrings = New Structure;
	
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", FillInArticleAttribute);
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_",
		FillInProductTypeAttribute_);
	StructureOfActionsWithAddedStrings.Insert("FillInFeatureAttribute",
		FillInFeatureAttribute);
	StructureOfActionsWithAddedStrings.Insert("FillInCheckQualityDateOfQualityConfirmation",
		CacheQualityControl);
	StructureOfActionsWithAddedStrings.Insert("CheckFillWarehouse", CheckFillWarehouse);
	
	DataParameters = New Structure;
	DataParameters.Insert("Data", Data);
	
	DataParameters.Insert("StructureOfActionsWithAddedStrings",
		StructureOfActionsWithAddedStrings);
	
	DataParameters.Insert("StructureOfActionsWithModifiedStrings",
		New Structure);
	
	DataParameters.Insert("DialColumns", DialColumns(ThisObject));
	
	SetsServer.AtEndOfEditingSet(ThisObject, "Goods", DataParameters);
	
EndProcedure

&AtClientAtServerNoContext
Function DialColumns(Form)
	
	Columns = New Array;
	Columns.Add("Products");
	Columns.Add("Characteristic");
	Columns.Add("Package");
	Columns.Add("Count");
	Columns.Add("NumberOfPackages");
	Columns.Add("Price");
	Columns.Add("Sum");
	
	Return Columns;
	
EndFunction

&AtServer
Function SetAddressInTemporaryStorage(Var_Parameters)
	
	Return SetsServer.SetAddressInTemporaryStorage(ThisObject, Var_Parameters, "Goods");
	
EndFunction

&AtClient
Procedure WhenRemovingComponents(Action, AdditionalParameter) Export
	
	If SetsClient.EditSetAction(Action) Then
		SetsClient.WhenRemovingComponents(ThisObject, "Goods", AdditionalParameter);
	ElsIf SetsClient.DeleteEntireSetAction(Action) Then
		WhenRemovingComponentsOnServer("Goods", AdditionalParameter);
	EndIf;
	
	UpdateDependentDetailsOfOrderForm_(
		Items,
		Object.Goods,
		DiscrepancyOrderText);
	
EndProcedure

&AtServer
Procedure WhenRemovingComponentsOnServer(TSName, AdditionalParameter)
	
	SetsServer.WhenRemovingComponents(ThisObject, TSName, AdditionalParameter);
	
	UpdateInformationOnOrders();
	
	StructureOfActions = New Structure;
	OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, True);
	BatchProcessingOfTablePartServer.TreatTS(
		Object[TSName],
		StructureOfActions);
	
EndProcedure

#EndRegion

#Region BarcodesAndTradeEquipment

&AtClient
Procedure ProcessBarcodes(BarcodeData_5)
	
	ClearMessages();
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
		Return;
	EndIf;
	
	FillInArticleAttribute          = New Structure("Products", "SKU");
	FillInProductTypeAttribute_  = New Structure("Products", "ItemsType");
	FillInCCDTrackingAttribute = New Structure("Products", "TheRecordsAreKeptByCCD");
	CheckFillWarehouse          = BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(
										Object,
										WarehouseGroup_);
	
	StructureOfActionsWithAddedStrings = New Structure;
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", FillInArticleAttribute);
	StructureOfActionsWithAddedStrings.Insert("CheckFillWarehouse", CheckFillWarehouse);
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_",
		FillInProductTypeAttribute_);
	StructureOfActionsWithAddedStrings.Insert("FillInCCDTrackingAttribute",
		FillInCCDTrackingAttribute);
	StructureOfActionsWithAddedStrings.Insert("FillInCheckQualityDateOfQualityConfirmation",
		CacheQualityControl);
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActionsWithAddedStrings);
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithAddedStrings, Object);
	OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActionsWithAddedStrings, True);
	
	StructureOfActionsWithModifiedStrings = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithModifiedStrings, Object);
	OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActionsWithModifiedStrings, True);
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	StructureOfActions.SeriesSpecificationParameters                 = SeriesSpecificationParameters;
	StructureOfActions.AddOnlyProductsOverAndAboveOrder        = True;
	StructureOfActions.GoodsOnly                           = True;
	StructureOfActions.AddContainers                         = False;
	StructureOfActions.UseContainersAsGoods        = False;
	StructureOfActions.CalculateSets                     = True;
	
	ProcessBarcodesServer(StructureOfActions, CachedValues);
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(StructureOfActions, CachedValues, ThisObject);
	
	OpenSeriesIndicationForm = BarcodingOfItemsClient.YouNeedToOpenFormForSpecifyingSeriesAfterProcessingBarcodes(
		StructureOfActions);
	
	If OpenSeriesIndicationForm Then
		CurDataId = StructureOfActions.ArrayOfRowsWithSeries_[0];
		
		AttachIdleHandler("OpenSeriesSelectionWhenScanningProductBarCode", 0.1, True);
	EndIf;
	
	If StructureOfActions.CurrentRow <> Undefined Then
		Items.Goods.CurrentRow = StructureOfActions.CurrentRow;
	EndIf;
	
	UpdateDependentDetailsOfOrderForm_(Items, Object.Goods, DiscrepancyOrderText);
	
EndProcedure

&AtServer
Procedure ProcessBarcodesServer(StructureOfActionParameters, CachedValues)
	
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject, Object, StructureOfActionParameters, CachedValues);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	UpdateOrderDeviations();
	
EndProcedure

#EndRegion

#Region SelectionAndProcessingOfQuantityVerification

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected)
	
	TableOfGoods       = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	ListOfProperties = 
	    "ProductsInSet,
	    |Products,
	    |Characteristic,
	    |ItemVariantOfSet,
	    |Package,
	    |Series,
	    |NumberOfPackages,
	    |Price";
	
	CheckFillWarehouse = BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(
		Object,
		WarehouseGroup_);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("FillInProductTypeAttribute_",
		New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInCCDTrackingAttribute",
		New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActions.Insert("CheckFillWarehouse", CheckFillWarehouse);
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, True);
	
	RowsToProcess = New Array();
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct, ListOfProperties);
		
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	FillInServiceDetailsForProductRange();
	WhenChangingWarehouseInTablePartServer();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	UpdateDependentDetailsOfOrderForm_(Items, Object.Goods, DiscrepancyOrderText);
	
EndProcedure

&AtClient
Procedure CheckQuantityInTheDocumentClient()
	
	OnlyNonLabeledProductsHaveBeenUnloaded = True;
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("AddressInTempStorage",
		AddressInvoiceGoods(OnlyNonLabeledProductsHaveBeenUnloaded));
	OpeningParameters.Insert("TabularSectionName", "Goods");
	OpeningParameters.Insert("Ref", Object.Ref);
	OpeningParameters.Insert("GoodsQuantityExcessIsAllowed", ShipmentInExcessOfOrder);
	OpeningParameters.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters);
	OpeningParameters.Insert("Warehouse", Object.Warehouse);
	OpeningParameters.Insert("OnlyNonLabeledProductsHaveBeenUnloaded", OnlyNonLabeledProductsHaveBeenUnloaded);

	OpenForm("CommonForm.CheckDocumentPopulation",
		OpeningParameters,
		,
		,
		,
		,
		New CallbackDescription("CheckQuantityInTheDocumentCompletion", ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure UnlinkFromOrder(Command)
	
	SelectedRows = Items.Goods.SelectedRows;
	
	If SelectedRows.Count() > 0 Then
		UnlinkFromOrderServer(False);
		NotifyAboutEndOfUnbindingLines(SelectedRows.Count());
	Else
		WarningText = NStr("vi = 'Hãy chọn dòng cần bỏ liên kết với lệnh.';
							|ru = 'Выберите строки, которые необходимо отвязать от распоряжения.';
							|en = 'Select lines which should be unlinked from the reference.'; fa = 'Select lines which should be unlinked from the reference.';
							|it = 'Select lines which should be unlinked from the reference.';
							|pl = 'Select lines which should be unlinked from the reference.';
							|tr = 'Siparişlerden çıkarılması gereken satırları seçin.'");
		ShowMessageBox(Undefined, WarningText);
	EndIf;
	
EndProcedure

&AtServer
Function AddressInvoiceGoods(OnlyNonLabeledProductsHaveBeenUnloaded = False)
	
	Table = Object.Goods.Unload(); // ValueTable

	If OnlyNonLabeledProductsHaveBeenUnloaded And Table.Columns.Find("MarkedProducts") <> Undefined Then
		OnlyNonLabeledProductsHaveBeenUnloaded = False;
		CurrentRowNumber = Table.Count()-1;
		While CurrentRowNumber >= 0 Do
			If Table[CurrentRowNumber].MarkedProducts Then
				Table.Delete(CurrentRowNumber);
				OnlyNonLabeledProductsHaveBeenUnloaded = True;
			EndIf;
			CurrentRowNumber = CurrentRowNumber - 1;
		EndDo;
	EndIf;
	
	For Each Page1 In Table Do 
		
		If TypeOf(Page1.ReferenceOrder) = Type("DocumentRef.SaleAdjustment")
			And ValueIsFilled(Page1.BatchesIndicationStatusInWarehouses)
			And Not ValueIsFilled(Page1.BatchesIndicationStatusOfGoodsTransferred) Then
			
			Page1.Series = Catalogs.ItemsBatches.EmptyRef();
			
		EndIf;
		
	EndDo;
	
	Table.Columns.Add("DateOfShipment",    New TypeDescription("Date"));
	Table.Columns.Add("DateOfReceipt", New TypeDescription("Date"));

	Table.FillValues(CurrentSessionDate(), "DateOfShipment");
	Table.FillValues(CurrentSessionDate(), "DateOfReceipt");

	AddressInTempStorage = PutToTempStorage(Table, UUID);
	
	Return AddressInTempStorage;
	
EndFunction

&AtServer
Procedure ChangeTablePartBasedOnResultsOfCheck(ReturnParameters, CachedValues)
	
	GoodsTable   = GetFromTempStorage(ReturnParameters.Goods);
	LinesToDelete = New Array;
	
	SelectionColumns =
		"ProductsInSet,
		|ItemVariantOfSet,
		|Products,
		|Characteristic,
		|ItemVariantsAreUsed,
		|Package,
		|Series,
		|RowID";
	
	ProcessedRowsFoundRows = New Array();
	ProcessedRowsAddedRows = New Array();
	
	For Each SourceRow In GoodsTable Do
		
		Filter = New Structure(SelectionColumns);
		FillPropertyValues(Filter, SourceRow);
		
		FoundRows = Object.Goods.FindRows(Filter);
		
		For Each TSRow In FoundRows Do
			
			If SourceRow.NumberOfPackages = 0 Then
				Break;
			EndIf;
			
			If SourceRow.NumberOfPackages >= 0 Then
				
				TSRow.NumberOfPackages = TSRow.NumberOfPackages
					+ SourceRow.NumberOfPackages;
				SourceRow.NumberOfPackages = 0;
				
			Else
				
				QuantityToWriteOff = -SourceRow.NumberOfPackages;
				QuantityPerLine   = TSRow.NumberOfPackages;
				
				If QuantityToWriteOff > QuantityPerLine Then
					SourceRow.NumberOfPackages = QuantityPerLine - QuantityToWriteOff;
					TSRow.NumberOfPackages       = 0;
				Else
					SourceRow.NumberOfPackages = 0;
					TSRow.NumberOfPackages       = QuantityPerLine - QuantityToWriteOff;
				EndIf;
				
			EndIf;
			
			If TSRow.NumberOfPackages = 0 Then
				LinesToDelete.Add(TSRow);
			Else
				
				ProcessedRowsFoundRows.Add(TSRow);
				
			EndIf;
			
		EndDo;
		
		If FoundRows.Count() = 0 Then
			
			TSRow = Object.Goods.Add();
			FillPropertyValues(TSRow, SourceRow);
			
			ProcessedRowsAddedRows.Add(TSRow);
			
		EndIf;
		
	EndDo;
	
	CheckFillWarehouse = BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(
		Object,
		WarehouseGroup_);
	
	StructureOfActionsFoundLines = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsFoundLines, Object);
	
	StructureOfActionsAddedLines = New Structure;
	StructureOfActionsAddedLines.Insert("FillInProductTypeAttribute_",
		New Structure("Products", "ItemsType"));
	
	StructureOfActionsAddedLines.Insert("FillInArticleAttribute",
		New Structure("Products", "SKU"));
	
	StructureOfActionsAddedLines.Insert("FillInCCDTrackingAttribute",
		New Structure("Products", "TheRecordsAreKeptByCCD"));
	
	StructureOfActionsAddedLines.Insert("FillInCheckQualityDateOfQualityConfirmation",
		CacheQualityControl);
	
	StructureOfActionsAddedLines.Insert("CheckFillWarehouse", CheckFillWarehouse);
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsAddedLines, Object);
	OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActionsAddedLines, True);
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
		StructureOfActionsAddedLines);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ProcessedRowsFoundRows,
		StructureOfActionsFoundLines,
		Object.Goods,
		CachedValues);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ProcessedRowsAddedRows,
		StructureOfActionsAddedLines,
		Object.Goods,
		CachedValues);
	
	For Each TSRow In LinesToDelete Do
		Object.Goods.Delete(TSRow);
	EndDo;
	
	FillInServiceDetailsForProductRange();
	WhenChangingWarehouseInTablePartServer();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	UpdateDependentDetailsOfOrderForm_(Items, Object.Goods, DiscrepancyOrderText);
	
EndProcedure

#EndRegion

#Region SetOfSeries

&AtServer
Function SeriesSpecificationParameters()
	
	ObjectManager = Documents.GoodsReceiptFromCustomer;
	
	Return New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object,
		ObjectManager));
	
EndFunction

&AtServer
Procedure SetVisibilityOfSeriesElements()
	
	Items.GoodsSeries.Visible                = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsSpecifySeries.Visible         = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsBatchesIndicationStatus.Visible  = SeriesSpecificationParameters.UseItemsBatch;
	
EndProcedure

&AtClient
Procedure OpenSeriesSelectionWhenScanningProductBarCode()
	
	If CurDataId = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.Goods.FindByID(CurDataId);
	
	OpenSelectionOfSeries(,CurrentData);
	
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
			CurDataId = Items.Goods.CurrentData.GetID();
		Else
			CurDataId = CurrentData.GetID();
		EndIf;
		
		ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm(CurDataId);
		AdditionalParameters = New Structure("ParametersOfSeriesIndicationForm",
			ParametersOfSeriesIndicationForm);
		
		CallbackDescription = New CallbackDescription("OpenSelectionOfSeriesCompletion",
																ThisObject,
																AdditionalParameters);
		
		OpenForm(ParametersOfSeriesIndicationForm.FormName,
						ParametersOfSeriesIndicationForm,
						ThisObject,
						,
						,
						,
						CallbackDescription,
						FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenSelectionOfSeriesCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		ProcessSeriesIndication_Server(AdditionalParameters.ParametersOfSeriesIndicationForm);
	EndIf;
	
EndProcedure

&AtServer
Function ParametersOfSeriesIndicationForm(CurDataId)
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(Object,
															SeriesSpecificationParameters,
															CurDataId,
															ThisObject);
	
EndFunction

&AtServer
Procedure ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm)
	
	StructureOfActions = New Structure("UpdateNumberOfProductsWhenRegistering", True);
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	ProductsServer.ProcessSeriesIndication_(Object,SeriesSpecificationParameters,ParametersOfSeriesIndicationForm,
		StructureOfActions);
	
EndProcedure

&AtServer
Procedure FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow,
																			CachedValues)
	
	ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Object,
		SeriesSpecificationParameters,
		IDCurrentRow,
		CachedValues);
	
EndProcedure

&AtServer
Procedure HowToSetSeriesVisibility()
	
	SeriesSpecificationParameters = SeriesSpecificationParameters();
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	SetVisibilityOfSeriesElements();
	
EndProcedure

#EndRegion

#Region CCDNumbers

&AtClient
Procedure ProcessSelectionOfCCDNumber(CalculationResult1)
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	RowID = CurrentData.GetID();
	
	If RowID = Undefined Then
		Return;
	EndIf;
	
	CCDNumbersFilledIn = False;
	CCDNumber = Undefined;
	
	ProcessIndicationOfCCDNumberServer(RowID, CalculationResult1, CCDNumbersFilledIn, CCDNumber);
	
	PurchasesClient.NotifyAboutFillingInGTNumbersInTabularPart(CCDNumbersFilledIn, CCDNumber);
	
EndProcedure

&AtServer
Procedure ProcessIndicationOfCCDNumberServer(RowID,
											CalculationResult1,
											CCDNumbersFilledIn,
											CCDNumber)
	
	SelectionData_1	= GetFromTempStorage(CalculationResult1.AddressInTempStorage);
	CCDNumber		= ?(SelectionData_1.ResidualNumberOfCCD <> Undefined,
						CCDNumber,
						SelectionData_1.MainNumberOfCCD);
	
	ProcessingActions = New Structure;
	
	If SelectionData_1.ResidualNumberOfCCD <> Undefined Then
		AddActionsToStructureWhenChangingPackagesNumber(ProcessingActions, Object);
	Else
		AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
			Object,
			ProcessingActions,
			"Contract");
	EndIf;
	
	PurchasesServer.ProcessIndicationOfCCDNumber(ThisObject,
		RowID,
		SelectionData_1,
		CCDNumbersFilledIn,
		Undefined,
		ProcessingActions);
	
EndProcedure

&AtClient
Procedure FillInCCDNumbersCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		FillInCCDNumbersServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInCCDNumbersServer()
	
	FillParameters = PurchasesServer.ParametersForFillingInCCDNumbersBasedOnCredentials();
	
	QueryOptions = FillParameters.QueryOptions;
	QueryOptions.Ref = Object.Ref;
	
	FillParameters.NameOfOrderField = "ReferenceOrder";

	ActionsWithString = New Structure;
	ActionsWithString.Insert("RecalculateAmount");
	
	AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(ThisObject, ActionsWithString);
	
	FillParameters.ActionsWithString = ActionsWithString;
	
	PurchasesServer.FillInCCDNumbersAccordingToCredentials(Object.Goods, "ByReferences", FillParameters);

EndProcedure

#EndRegion

#Region Properties

// StandardSubsystems.Properties
&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
	
EndProcedure

&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	
	PropertyManager.FillAdditionalAttributesInForm(ThisObject);
	
EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
	
EndProcedure

// End StandardSubsystems.Properties

#EndRegion

#Region Other

&AtClient
Procedure Attachable_CloseForm()
	
	If IsOpen() Then
		Close();
	EndIf;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Setting the conditional design for the 'Warehouse' element
	WarehousesServer.SetConditionalAppearanceOfWarehouseInHeader(ThisObject);
	
	// Setting the conditional design for the items of the nomenclature of the tabular part 'Goods'
	SetsServer.SetConditionalAppearance(ThisObject, "Goods");
	
	// Setting the Conditional appearance of the returned item of a different quality.
	ConditionalDesignParameters = ProductsServer.ParametersOfConditionalAppearanceOfDifferentQualityItem();
	ConditionalDesignParameters.StockQualityChangeAttributeIsUsed = True;
	ConditionalDesignParameters.PathToStockQualityChangeField = "Object.Goods.Damage";
	
	ProductsServer.SetConditionalAppearanceOfDifferentQualityItem(ThisObject, ConditionalDesignParameters);
	
	// Setting the conditional design for the items of the nomenclature of the tabular part 'Goods'
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject);
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisObject,
																	"SeriesWhenPlanningShipmentWHGoodsAreIndicated");
	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisObject, False);
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject);
	
	// Setting the conditional design of the order submission element
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReferenceOrderPresentation.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReferenceOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ResultIssueColor);
	
	// Setting a conditional layout for the 'Packaging' element of the 'Goods' tabular part
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPackage.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DeviationFromShipmentConditions");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// Setting a conditional layout for the 'Price' and 'Amount' elements of the 'Goods' tabular part
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPrice.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSum.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ReferenceOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DeviationFromShipmentConditions");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PriceKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//

	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsWarehouse.Name);
	
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = ValueList;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Warehouse");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	// Setting the conditional design for the 'Order' element of the 'Goods' tabular part
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsReferenceOrder.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReferenceOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseReceiptForMultipleOrders");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsReferenceOrder.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ReferenceOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsReferenceOrder.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ReferenceOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsReferenceOrder.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ReferenceOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReferenceOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ErrorNoteText);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Vượt quá lệnh. chưa chọn lệnh';
													|ru = 'Сверх распоряжения, распоряжение не выбрано';
													|en = 'In excess of reference. Reference is not selected'; fa = 'In excess of reference. Reference is not selected';
													|it = 'In excess of reference. Reference is not selected';
													|pl = 'In excess of reference. Reference is not selected';
													|tr = 'Sipariş iptal edildi, hiçbir sipariş seçilmedi'"));
	
	// Setting the conditional design for the 'Warehouse' element of the 'Goods' tabular part
	WarehousesServer.SetConditionalAppearanceOfVTCHWarehouse(ThisObject);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsWarehouse.Name);
	
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = ValueList;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfQuantityAccordingToRNPT(ThisObject);
	
	// 
	
	#Region ItemsItemRegistrationCharacteristicsRegistration
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCharacteristicRecordingAsReceived.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemVariantsAreUsedRecordingAsReceived");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Damage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng đặc tính>';
													|ru = '<характеристики не используются>';
													|en = '<variants are not used>'; fa = '<گونه‌ها استفاده نمی‌شوند>';
													|it = '<le caratteristiche non vengono usate>';
													|pl = '<charakterystyki nie dotyczą>';
													|tr = '<varyantlar kullanılmamaktadır>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsProductsRecordingAsReceived.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCharacteristicRecordingAsReceived.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Damage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	#EndRegion
	
	#Region GoodsCCDNumberOriginCountry
	
	ParametersForSettingConditionalAppearanceOfCCDNumber =
		ProductsServer.ParametersForSettingConditionalAppearanceOfCCDNumber();
	ParametersForSettingConditionalAppearanceOfCCDNumber.NameOfFieldForEnteringCCDNumber = "GoodsOriginCountry";
	
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject);
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject,
		ParametersForSettingConditionalAppearanceOfCCDNumber);
	
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfCCDNumber(ThisObject);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCCDNumber.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsOriginCountry.Name);
	
	TypesOfGoods = New ValueList;
	TypesOfGoods.Add(Enums.ItemsTypes.OwnGoods);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = TypesOfGoods;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<cho hàng hóa>';
													|ru = '<для товаров>';
													|en = '<for goods>'; fa = '<for goods>';
													|it = '<per le merci>';
													|pl = '<dla towarów>';
													|tr = '<ürünler için>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	#EndRegion
	
	// Setting the conditional design for the 'Activity Direction' element
	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisObject);
	
	// Conditional appearance of quality control Attributes.
	Fields = QualityControl.Fields(
		Items.GoodsToControlQuality,
		Items.GoodsQualityConfirmationDate);
	QualityControl.SetupAppearance(ConditionalAppearance, Fields);
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	ToUseTermsOfSales =
		GetFunctionalOption("ToUseTermsOfSales");
	RestrictGoodsReceiptWithoutCCDNumbers =
		GetFunctionalOption("RestrictGoodsReceiptWithoutCCDNumbers");
	UseLinesOfBusiness =
		GetFunctionalOption("UseCostAccountingByLinesOfBusiness");
	UseTraceableImportedGoodsAccounting =
		AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(Object.Date);
	UseReceiptForMultipleOrders =
		GetFunctionalOption("UseSaleByMultipleOrders");
	
	ShipmentInExcessOfOrder         = UserRightsCached.SalesInExcessOfOrder();
	DeviationFromShipmentConditions = UserRightsCached.VarianceFromSalesTermsAndConditions();
	
	UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25();
	
	Warehouse                  = Object.Warehouse;
	Contract                = Object.Contract;
	Terms             = Object.Terms;
	DocumentCurrency        = Object.Currency;
	WarehouseGroup_            = ItIsGroupOfWarehousesAndWarehousesUsedByWHForSale(Object.Warehouse);
	SeriesSpecificationParameters = SeriesSpecificationParameters();
	
	ConfigureFormForCorruption();
	SetTitleAvailabilityPickUpProductsByOrdersOrders();
	
	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible,
		Object.Contract);
	
	Documents.GoodsReceiptFromCustomer.AdjustItemSelectionSettings(ThisObject, Object);
	
	ProcessingOfTabularForms.InitializeRowCache(Items.Goods);
	
	SetVisibilityOfSeriesElements();
	SetParametersForSelectingProductsWarehouse();
	
	UpdateDependentDetailsOfServerByOrderForm();
	UpdateInformationOnOrders();
	UpdateOrderDeviations();
	FillInServiceDetailsForProductRange();
	SetElementProperties();
	
	Documents.GoodsReceiptFromCustomer.CustomizeForm(ThisObject, Object.Number, Object.Date);
	
	WhenChangingWarehouseInTablePartServer();
	LinesOfBusinessServer.OnReadCreateAtServer(ThisObject);
	PurchasesServer.FillInSelectionListNameOfIncomingDocument(ThisObject, Object.Counterparty);
	CacheQualityControl = QualityControl.DataCacheOfMechanism(Object);
	
EndProcedure

&AtClient
Procedure OpenOrderSelection(CallbackDescription)
	
	NamesOfDocumentDetails =
		"Ref,
		|Partner,
		|Counterparty,
		|Terms,
		|Organization,
		|Warehouse,
		|Contract,
		|SalesOpportunity,
		|Department,
		|LineOfBusiness,
		|Currency
		|";
		
	FormParameters = New Structure(NamesOfDocumentDetails);
	FillPropertyValues(FormParameters, Object);

	OpenForm("Document.GoodsReceiptFromCustomer.Form.ReferenceChoiceForm", 
		FormParameters,
		ThisObject,
		,
		,
		,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtServer
Procedure SetElementProperties()
	
	ReceiptOfCorrection = False;
	For Each ReferenceOrder In ListOfOrders_ Do
		If TypeOf(ReferenceOrder.Value) = Type("DocumentRef.SaleAdjustment") Then
			ReceiptOfCorrection = True;
			
			Break;
		EndIf;
	EndDo;
	
	SetAvailabilityOfClipboardCommands();
	
	ItemArray = New Array;
	ItemArray.Add("GoodsUnlinkFromOrder");
	ItemArray.Add("GoodsContextMenuUnlinkFromOrder");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible",
		ShipmentInExcessOfOrder);
	
	ItemArray = New Array;
	ItemArray.Add("GoodsOpenSelection");
	ItemArray.Add("GoodsImportFromExternalFile");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled",
		ShipmentInExcessOfOrder);
	
	TagName = "GoodsFillInTheWarehouseInSelectedLines";
	
	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		TagName,
		"Enabled",
		WarehouseGroup_);
	
	TagName = "GoodsFillInTheWarehouseInSelectedLines";
	
	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		TagName,
		"Visible",
		ReceiptOfCorrection);
	
	TagName = "GroupLabelAndPictureSeveralWarehouses";
	
	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		TagName,
		"Visible",
		WarehouseGroup_);
	
	If Not DeviationFromShipmentConditions Then
		
		ItemArray = New Array;
		ItemArray.Add("Partner");
		ItemArray.Add("Counterparty");
		ItemArray.Add("Terms");
		ItemArray.Add("Organization");
		ItemArray.Add("Contract");
		ItemArray.Add("Warehouse");
		
		If Not ShipmentInExcessOfOrder Then
			ItemArray.Add("GoodsRowCode");
			ItemArray.Add("GoodsProducts");
			ItemArray.Add("GoodsCharacteristic");
			ItemArray.Add("GoodsPackage");
		EndIf;
		
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "ReadOnly",
			True);
		
		ItemArray = New Array;
		ItemArray.Add("GoodsFillThePricesByTermsOfSales");
		
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled",
			ShipmentInExcessOfOrder);
		
	EndIf;
	
	SetLBEditingOption();
	
EndProcedure

&AtServer
Procedure SetLBEditingOption()
	
	If Not UseLinesOfBusiness Then
		Return;
	EndIf;
	
	LBAvailabilityParameters = LinesOfBusinessServer.ParametersLBEditingCapability();
	
	LBAvailabilityParameters.Contract           = Object.Contract;
	LBAvailabilityParameters.ARAPObjectSettings   = Common.ObjectAttributeValue(Object.Contract, "ARAPObjectSettings");
	
	LinesOfBusinessServer.SetLBEditingOption(ThisObject, LBAvailabilityParameters);
	
EndProcedure

&AtServer
Procedure UpdateInformationOnOrders()
	
	ListOfOrders_.Clear();
	InAllRowsThereIsOrder = True;
	For Each CurRow In Object.Goods Do
		If ValueIsFilled(CurRow.ReferenceOrder) Then
			If ListOfOrders_.FindByValue(CurRow.ReferenceOrder) = Undefined Then
				ListOfOrders_.Add(CurRow.ReferenceOrder);
			EndIf;
		Else
			InAllRowsThereIsOrder = False;
		EndIf;
	EndDo;
	
	If ListOfOrders_.Count() = 1 And InAllRowsThereIsOrder Then
		Object.ReferenceOrder = ListOfOrders_[0].Value;
	ElsIf ListOfOrders_.Count() > 1
		Or Not InAllRowsThereIsOrder Then
		Object.ReferenceOrder = Undefined;
	EndIf;
	
	If ListOfOrders_.Count() > 1 Then
		LabelTotalOrders = NStr("vi = 'Tổng số chứng từ';
								|ru = 'Всего документов';
								|en = 'Total documents'; fa = 'Total documents';
								|it = 'Total documents';
								|pl = 'Total documents';
								|tr = 'Belgelerin tümü'");
		InscriptionIsTitleOfOrders = LabelTotalOrders + ": " + ListOfOrders_.Count();
	EndIf;
	
	If ListOfOrders_.Count() <= 1 Then
		Items.Pages_Order.CurrentPage = Items.Page_Order;
		PresentationOfOrderServer();
	Else
		Items.Pages_Order.CurrentPage = Items.PageOfOrder;
		Items.PageOfOrder.Enabled = True;
	EndIf;
	
	If ValueIsFilled(Object.ReferenceOrder) Or Not UseReceiptForMultipleOrders Then
		Items.GoodsGroupReference.Group = ColumnsGroup.Vertical;
	Else
		Items.GoodsGroupReference.Group = ColumnsGroup.InCell;
	EndIf;
	
	SetPropertiesToReduceShipmentByOrder();
	
	SetElementProperties();
	
EndProcedure

&AtServer
Procedure SetPropertiesToReduceShipmentByOrder()
	
	ReceiptAgainstOrder = False;
	
	For Each ReferenceOrder In ListOfOrders_ Do
		If TypeOf(ReferenceOrder.Value) <> Type("DocumentRef.SaleAdjustment") 
			And TypeOf(ReferenceOrder.Value) <> Type("DocumentRef.SourceDocument")
			And TypeOf(ReferenceOrder.Value) <> Type("DocumentRef.GoodsShipmentToCustomer") Then
			ReceiptAgainstOrder = True;
			
			Break;
		EndIf;
	EndDo;
	
	If Not ReceiptAgainstOrder And Object.ReduceShipmentByReference Then 
		Object.ReduceShipmentByReference = False;
	EndIf;
	
	Items.ReduceShipmentByReference.Enabled = ReceiptAgainstOrder;
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsForProductRange()
	
	FillInArticleAttribute = New Structure;
	FillInArticleAttribute.Insert("Products",              "SKU");
	FillInArticleAttribute.Insert("ProductsRecordingAsReceived", "SKURegistration");
	
	FillInProductTypeAttribute_ = New Structure;
	FillInProductTypeAttribute_.Insert("Products", "ItemsType");
	
	FillInCCDTrackingAttribute = New Structure;
	FillInCCDTrackingAttribute.Insert("Products", "TheRecordsAreKeptByCCD");
	
	FillInFeatureAttribute = New Structure;
	FillInFeatureAttribute.Insert("Products", "ItemVariantsAreUsed");
	FillInFeatureAttribute.Insert(
		"ProductsRecordingAsReceived",
		"ItemVariantsAreUsedRecordingAsReceived");
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInArticleAttribute",         FillInArticleAttribute);
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_", FillInProductTypeAttribute_);
	ParametersForFillingInBankingDetails.Insert(
		"FillInFeatureAttribute",
		FillInFeatureAttribute);
	
	ParametersForFillingInBankingDetails.Insert("FillInCCDTrackingAttribute",
		FillInCCDTrackingAttribute);
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(ParametersForFillingInBankingDetails);
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods,
		ParametersForFillingInBankingDetails);
	
	SetsServer.FillInServiceDetails(ThisObject);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions,
																	Object,
																	RecalculateQuantity = True)
	
	If RecalculateQuantity Then
		AddActionRecalculateNumberOfUnits(Object.BusinessOperation, StructureOfActions, Object.Warehouse);
	EndIf;
	
	StructureOfActions.Insert("RecalculateAmount");
	
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActions,
		"Contract");
	
EndProcedure

&AtServerNoContext
Procedure AddActionRecalculateNumberOfUnits(BusinessOperation, StructureOfActions, Warehouse = Undefined)

	Documents.GoodsReceiptFromCustomer.AddActionRecalculateNumberOfUnits(StructureOfActions);

EndProcedure

&AtServer
Procedure GetUploadedProductsFromStorage(GoodsAddressInStorage)
	
	ItemsFromStorage    = GetFromTempStorage(GoodsAddressInStorage);
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	CheckFillWarehouse = BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(
		Object,
		WarehouseGroup_);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("CheckFillWarehouse", CheckFillWarehouse);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
		StructureOfActions);
	
	OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, True);
	
	RowsToProcess = New Array();
	
	For Each RowOfGoods In ItemsFromStorage Do
		
		StringTSGoods = Object.Goods.Add();
		FillPropertyValues(StringTSGoods, RowOfGoods,, "RowCode");
		
		RowsToProcess.Add(StringTSGoods);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	FillInServiceDetailsForProductRange();
	WhenChangingWarehouseInTablePartServer();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	UpdateDependentDetailsOfOrderForm_(Items, Object.Goods, DiscrepancyOrderText);
	
EndProcedure

&AtServer
Procedure GetStockTypesFromStorage(ValueSelected)
	
	InventoriesServer.ProcessInputOfInventoryTypesManually(ValueSelected, ThisObject);
	
EndProcedure

&AtServer
Procedure FillInSubordinatePropertiesForStatistics(ParentPropsName)
	
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, ParentPropsName);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(Form, StructureOfActions)
	
	Object = Form.Object;
	
	WarehouseFieldName = "Warehouse";
	
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActions,
		WarehouseFieldName);
	
EndProcedure

&AtServer
Procedure FillInDefaultContract()
	
	Contract = Documents.GoodsReceiptFromCustomer.GetDefaultContract(Object);
	
	If Contract <> Object.Contract Then
		Object.Contract = Contract;
		ContractOnChangeServer(False, True);
	EndIf;
	
EndProcedure

&AtServer
Procedure ExecuteRecalculateDocumentAmountsServer(OldCurrency, NewCurrency)
	
	If OldCurrency <> NewCurrency Then
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateAmount");
		
		DocumentDate = ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate());
		LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
		
		StructureOfOldCurrencyRates = ProcessingOfExchangeRatesTM.GetCurrencyRate(
			OldCurrency,
			DocumentDate,
			LocalAccountingCurrency);
		
		StructureOfNewCurrencyRates = ProcessingOfExchangeRatesTM.GetCurrencyRate(
			NewCurrency,
			DocumentDate,
			LocalAccountingCurrency);
		
		For Each CurRow In Object.Goods Do
			
			CurRow.Price = ProcessingOfExchangeRatesTM.ConvertAtRate(
				CurRow.Price,
				StructureOfOldCurrencyRates,
				StructureOfNewCurrencyRates);
			
		EndDo;
		
		BatchProcessingOfTablePartServer.TreatTS(
			Object.Goods,
			StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Function PutGoodsAndStockTypesInStorage()
	
	Return InventoriesServer.PutGoodsAndStockTypesInStorage(ThisObject);
	
EndFunction

&AtServer
Procedure GoodsAfterDeleteRowServer(SeriesStatusesNeedToBeUpdated, CachedValues)
	
	If SeriesStatusesNeedToBeUpdated Then
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Undefined,
			CachedValues);
	EndIf;
	
	UpdateDependentDetailsOfServerByOrderForm();
	UpdateInformationOnOrders();
	WhenChangingWarehouseInTablePartServer();
	
EndProcedure

&AtServer
Procedure GoodsOnEditEndServer(UpdateSeriesStatuses,
															CachedValues,
															IDCurrentRow)
	
	If UpdateSeriesStatuses Then
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow,
			CachedValues);
	EndIf;
	
EndProcedure

&AtClient
Procedure WarehouseOnChangeCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Or Result = DialogReturnCode.No Then
		Object.Warehouse = Warehouse;
		Return;
	EndIf;
	
	WarehouseOnChangeServer(False, True, True);
	
EndProcedure

&AtClient
Procedure GoodsWarehouseOnChangeCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Or Result = DialogReturnCode.No Then
		Return;
	EndIf;
	
	ShowChoiceOfWarehouseToFillInVHFItems(AdditionalParameters);
	
EndProcedure

&AtClient
Procedure ShowChoiceOfWarehouseToFillInVHFItems(SelectedRows)

	FilterStructure1 = New Structure;
	FilterStructure1.Insert("IsFolder", False);
	FilterStructure1.Insert("SelectGroup",
		PredefinedValue("Enum.SelectWarehouseGroup.AllowInOrdersAndInvoices"));
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("Filter", FilterStructure1);
	ParametersStructure.Insert("GroupOfWarehouses", Object.Warehouse);
	ParametersStructure.Insert("TableRepresentation", TableRepresentation.List);
	
	AdditionalParameters = New Structure("SelectedRows", SelectedRows);
	CallbackDescription      = New CallbackDescription("FillInTheWarehouseInSelectedLinesCompletion",
														ThisObject,
														AdditionalParameters);
	
	OpenForm("Catalog.Warehouses.ChoiceForm",
					ParametersStructure,
					ThisObject,
					,
					,
					,
					CallbackDescription,
					FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure SelectReferenceCompletion(ValueSelected, AdditionalParameters) Export
	
	Modified = True;
	Items.Goods.CurrentData.ReferenceOrder = ValueSelected;
	UpdateInformationOnOrders();
	
EndProcedure

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export 
	
	CurrentRow = Items.Goods.CurrentData;
	
	If NewRow <> Undefined Then
		
		StructureOfRecalculationOfAmount = AdditionalParameters.StructureOfRecalculationOfAmount;
		
		BatchProcessingOfTablePartClientServer.AddLineToRecalculateAmount(StructureOfRecalculationOfAmount, CurrentRow);
		BatchProcessingOfTablePartClientServer.AddLineToRecalculateAmount(StructureOfRecalculationOfAmount, NewRow);
		BatchProcessingOfTablePartClientServer.RecalculateAmounts(StructureOfRecalculationOfAmount);
		
		StructureOfActions = New Structure;
		AddActionRecalculateNumberOfUnits(Object.BusinessOperation, StructureOfActions, Object.Warehouse);
		
		BatchProcessingOfTablePartClient.ProcessTSString(
			CurrentRow,
			StructureOfActions,
			CachedValues);
		
		BatchProcessingOfTablePartClient.ProcessTSString(
			NewRow,
			StructureOfActions,
			CachedValues);
		
		WhenChangingWarehouseInTablePartServer();
		
	EndIf;
	
	AccountingForTraceableGoodsClientServerLocalization.SplitRowCompletion(NewRow, AdditionalParameters);
	
EndProcedure

&AtClient
Procedure SearchByBarcodeCompletion(BarcodeData_2, AdditionalParameters) Export
	
	ProcessBarcodes(BarcodeData_2);
	
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
Procedure GetWeightCompletion(ExecutionResult, CurrentRow) Export
	
	If ExecutionResult.Result Then
		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
		
		CurrentRow.NumberOfPackages = ExecutionResult.Weight;
		
		BatchProcessingOfTablePartClient.ProcessTSString(
			CurrentRow,
			StructureOfActions,
			CachedValues);
		
	Else
		EquipmentManagerTMClient.ReportError(ExecutionResult);
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckQuantityInTheDocumentCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		
		Modified = True;
		CachedValues = ?(CachedValues = Undefined,
			BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues(),
			CachedValues);
		
		ChangeTablePartBasedOnResultsOfCheck(Result, CachedValues);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ImportFromExternalFileCompletion(ImportedDataAddress, AdditionalParameters) Export
	
	If ValueIsFilled(ImportedDataAddress) Then
		GetUploadedProductsFromStorage(ImportedDataAddress);
	EndIf;
	
EndProcedure

&AtClient
Procedure ReportErrorsWhenOpeningSelection(Cancel)
	
	If ToUseTermsOfSales
		And Not ValueIsFilled(Object.Terms) Then
		
		MessageText = NStr("vi = 'Chưa điền trường ""Thỏa thuận""';
							|ru = 'Поле ""Соглашение"" не заполнено';
							|en = '""Terms of sales"" are not filled'; fa = '""Terms of sales"" are not filled';
							|it = 'Il campo ""Accordo"" non è compilato';
							|pl = 'Pole ""Porozumienie"" nie jest wypełnione';
							|tr = '""Anlaşma"" alanı doldurulmamış'");
		CommonClient.MessageToUser(MessageText,
															Object.Ref,
															"Object.Terms",
															,
															Cancel);
		
	EndIf;
	
	If Not ValueIsFilled(Object.Currency) Then
		MessageText = NStr("vi = 'Chưa điền trường ""Tiền tệ""';
							|ru = 'Поле ""Валюта"" не заполнено';
							|en = '""Currency"" is required'; fa = '""Currency"" is required';
							|it = 'Il campo ""Valuta"" non è compilato';
							|pl = 'Pole ""Waluta"" nie jest wypełnione';
							|tr = '""Para Birimi"" alanı doldurulmadı'");
		CommonClient.MessageToUser(MessageText,
															Object.Ref,
															"Object.Currency",
															,
															Cancel);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetTitleAvailabilityPickUpProductsByOrdersOrders()
	
	If UseReceiptForMultipleOrders Then
		ButtonTitle = NStr("vi = 'Chọn theo đơn đặt hàng';
							|ru = 'Подобрать по распоряжениям';
							|en = 'Pick by references'; fa = 'انتخاب بر اساس مراجع';
							|it = 'Selezionare in base alle disposizioni';
							|pl = 'Wybierz wg zamówień';
							|tr = 'Talimatlara göre seçim'");
	Else
		ButtonTitle = NStr("vi = 'Chọn theo lệnh';
							|ru = 'Подобрать по распоряжению';
							|en = 'Pick by reference'; fa = 'Pick by reference';
							|it = 'Pick by reference';
							|pl = 'Pick by reference';
							|tr = 'Siparişlere göre seç'");
	EndIf;
	
	Items.GoodsSelectGoodsByOrdersNotes.Title = ButtonTitle;
	
EndProcedure

&AtServer
Procedure RecalculateNumberOfRNPT()
	
	If ValueIsFilled(Object.Warehouse)
		And ValueIsFilled(Object.Organization) Then
		
		ParametersForObtainingRnptCoefficient =
			AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(Object,
				"Contract");
		
		AccountingForTraceableGoodsLocalization.FillInQuantityByRNPTVOfTablePart(
			ParametersForObtainingRnptCoefficient, Object.Goods);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessingProductSelectionFromOrder(AddressInStorage)
	
	FieldsNames = "RowCode, CCDNumber, "
		+ Documents.GoodsReceiptFromCustomer.KeyFieldsOfGoodsTable();
	
	GoodsTable = GetFromTempStorage(AddressInStorage).Goods; // ValueTable
	GoodsTable.Sort(FieldsNames + " Desc");
	
	ActionsToRecalculateNumber = New Structure;
	AddActionRecalculateNumberOfUnits(Object.BusinessOperation, ActionsToRecalculateNumber, Object.Warehouse);
	BatchProcessingOfTablePartServer.TreatTS(GoodsTable, ActionsToRecalculateNumber);
	
	RowsRecalculateAmount = New Array;
	
	// Grouping a table by row keys.
	StringTree = New Array;
		
	For Each TableRow In GoodsTable Do
		
		If TableRow.QuantityInOrder <> TableRow.Count Then
			RowsRecalculateAmount.Add(TableRow);
		EndIf;
		
		RowsArray = New Array;
		RowsArray.Add(TableRow);
		
		StringTree.Add(RowsArray);
		
		TableRow.SetIndex = ?(ValueIsFilled(TableRow.ProductsInSet), 1, 0);
		
	EndDo;
	
	ActionsToRecalculateAmount = New Structure("RecalculateAmount");
	BatchProcessingOfTablePartServer.ProcessTSStrings(RowsRecalculateAmount, ActionsToRecalculateAmount, GoodsTable);
	
	AddedRows = InvoicesServer.FillInProductsSelectedFromOrder(
		StringTree, FieldsNames, Object.Goods, New Structure);

	StructureOfActions = New Structure;
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	
	BatchProcessingOfTablePartServer.TreatTS(
		Object.Goods,
		StructureOfActions);
	
	StructureOfActionsAddedLines = New Structure();
	StructureOfActionsAddedLines.Insert("FillInCheckQualityDateOfQualityConfirmation",
		CacheQualityControl);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		AddedRows,
		StructureOfActionsAddedLines,
		Object.Goods);
	
	UpdateInformationOnOrders();
	
	FillInServiceDetailsForProductRange();
	SetElementProperties();
	UpdateOrderDeviations();
	WhenChangingWarehouseInTablePartServer();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	UpdateDependentDetailsOfOrderForm_(Items, Object.Goods, DiscrepancyOrderText);
	
	LinesOfBusinessServer.SetVisibilityOfElementsSeparately(ThisObject);
	LinesOfBusinessServer.ReFillInServiceDetailsOfTablePart(ThisObject);
	
EndProcedure

&AtServerNoContext
Function ItIsGroupOfWarehousesAndWarehousesUsedByWHForSale(Warehouse)
	Return Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWHForSales(Warehouse);
EndFunction

&AtServer
Procedure SetParametersForSelectingProductsWarehouse()
	
	GoodsWarehouse                 = Items.GoodsWarehouse;
	ParameterValue           = WarehouseSelectionData(Object.Warehouse);
	GoodsWarehouse.ChoiceParameters = New FixedArray(New Array);
	
	TMCommonUseClientServer.AddSelectionParameter(GoodsWarehouse, "Ref", ParameterValue);
	
EndProcedure

&AtServerNoContext
Function WarehouseSelectionData(Warehouse)
	
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED
	|	Warehouses.Ref AS Ref
	|FROM
	|	Catalog.Warehouses AS Warehouses
	|WHERE
	|	Warehouses.Ref IN HIERARCHY(&GroupOfWarehouses)
	|	AND Warehouses.IsFolder = FALSE
	|	AND Warehouses.SelectGroup = VALUE(Enum.SelectWarehouseGroup.AllowInOrdersAndInvoices)";
	
	Query.SetParameter("GroupOfWarehouses", Warehouse);
	
	WarehouseTable = Query.Execute().Unload();
	WarehouseArray  = WarehouseTable.UnloadColumn("Ref");
	
	Return WarehouseArray;
	
EndFunction

// The constructor function of additional parameters processing is complete
// Returns:
// 	Structure - advanced setting:
// * CurrentRow - FormDataCollectionItem, FormDataStructure, FormDataTreeItem - 
// * CallbackDescription - CallbackDescription - 
// * LineDetachedFromOrder - Boolean - 
&AtClient
Function AdditionalCompletionProcessingParameters() 
	
	Result = New Structure;
	Result.Insert("CurrentRow", Undefined);
	Result.Insert("CallbackDescription", Undefined);
	Result.Insert("LineDetachedFromOrder", False);
	Return Result;
	
EndFunction

// Parameters:
// 	Result - Boolean - 
// 	AdditionalParameters - See AdditionalCompletionProcessingParameters
&AtClient
Procedure GoodsWarehouseWhenChangingQuestionToUserCompletion(Result,
																		AdditionalParameters) Export
	
	If Not Result Then
		
		WhenChangingWarehouseInTablePartServer();
		Return;
		
	EndIf;
	
	CurrentRow = AdditionalParameters.CurrentRow;
	
	CheckSeriesCalculateStatus = New Structure;
	CheckSeriesCalculateStatus.Insert("Warehouse",                  Object.Warehouse);
	CheckSeriesCalculateStatus.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckSeriesCalculateStatus", CheckSeriesCalculateStatus);
	OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, True);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	If AdditionalParameters.LineDetachedFromOrder Then
		LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject,
			StructureOfActions);
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(
		CurrentRow,
		StructureOfActions,
		CachedValues);
	
	UpdateDependentDetailsOfOrderForm_(Items, Object.Goods, DiscrepancyOrderText);
	
EndProcedure

&AtClient
Procedure QuestionUserWhenChangingRowDetails(CallbackDescription, CurrentRow)
	
	// If the current line is not related to the order.
	If CurrentRow.RowCode = 0 Then
		RunCallback(CallbackDescription, True);
		
		Return;
	EndIf;
	
	// If none of the key details have changed.
	If CurrentRow.Products = PreviousRowDetails.Products
		And CurrentRow.Characteristic = PreviousRowDetails.Characteristic
		And CurrentRow.Warehouse = PreviousRowDetails.Warehouse Then
		
		RunCallback(CallbackDescription, True);
		
		Return;
		
	EndIf;
	
	AdditionalParameters = AdditionalCompletionProcessingParameters();
	AdditionalParameters.CurrentRow = CurrentRow;
	AdditionalParameters.CallbackDescription = CallbackDescription;
	
	IssueNotification = New CallbackDescription(
		"QuestionToUserWhenChangingDetailsOfLineQuestionCompletion", ThisObject, AdditionalParameters);
	
	QueryText = NStr("vi = 'Dòng đang chỉnh sửa sẽ không còn liên kết với dòng trong lệnh. Tiếp tục?';
					|ru = 'Редактируемая строка перестанет быть связанной со строкой распоряжения. Продолжить?';
					|en = 'The edited line will be unlinked from the reference line. Continue?'; fa = 'The edited line will be unlinked from the reference line. Continue?';
					|it = 'The edited line will be unlinked from the reference line. Continue?';
					|pl = 'The edited line will be unlinked from the reference line. Continue?';
					|tr = 'Düzenlenecek satır artık sipariş satırına bağlı olmayacaktır. Devam edilsin mi?'");
	
	ShowQueryBox(IssueNotification, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

// Question to the user when changing the details of the line question completion.
// 
// Parameters:
//	Response - DialogReturnCode
//	AdditionalParameters - Structure - 
&AtClient
Procedure QuestionToUserWhenChangingDetailsOfLineQuestionCompletion(Response, AdditionalParameters) Export
	
	CurrentRow      = AdditionalParameters.CurrentRow;
	CallbackDescription = AdditionalParameters.CallbackDescription;
	
	// If the user has confirmed the change in the value of the key details.
	If Response = DialogReturnCode.Yes Then
		CurrentRow.RowCode = 0;
		AdditionalParameters.LineDetachedFromOrder = True;
		RunCallback(CallbackDescription, True);
	Else
		// If the user refused to change the linked string, we return the old values.
		FillPropertyValues(CurrentRow, PreviousRowDetails);
		RunCallback(CallbackDescription, False);
	EndIf;
	
EndProcedure

&AtServer
Function FillThePricesByTermsOfSalesServer(OnAllLines = False, ConsiderLinesOverAndAboveOrder = True)
	
	If OnAllLines Then

		If ShipmentInExcessOfOrder And ConsiderLinesOverAndAboveOrder Then
			FilterParameters = New Structure("RowCode", 0);
			RowsArray     = Object.Goods.FindRows(FilterParameters);
		Else
			RowsArray = Undefined;
		EndIf;

	Else
		
		RowsArray = New Array;
		
		For Each String In Items.Goods.SelectedRows Do
			
			FoundRow = Object.Goods.FindByID(String);
			
			If (ShipmentInExcessOfOrder
					And FoundRow.RowCode = 0)
				Or DeviationFromShipmentConditions Then
				
				RowsArray.Add(FoundRow);
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	SetsServerCall.AddToFullSet(Object.Goods, RowsArray, True);
	
	FillParameters = New Structure();
	FillParameters.Insert("Date",               Object.Date);
	FillParameters.Insert("Partner",            Object.Partner);
	FillParameters.Insert("Terms",         Object.Terms);
	FillParameters.Insert("Organization",        Object.Organization);
	FillParameters.Insert("Currency",             Object.Currency);
	FillParameters.Insert("CalculateSets", True);
	FillParameters.Insert("PopulationFields",     "Price");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	
	PricesCalculated = EnterprisePricesFillingServer.FillInPrices(
		Object.Goods,
		RowsArray,
		FillParameters,
		StructureOfActions);

	Return PricesCalculated;
	
EndFunction

&AtClient
Procedure NotifyAboutEndOfUnbindingLines(NumberOfLinesWorked, LinesWereUnlinked = True)

	If LinesWereUnlinked Then
		MessageText = NStr("vi = 'Các dòng liên quan';
							|ru = 'Строки отвязаны';
							|en = 'Lines were unlinked'; fa = 'Lines were unlinked';
							|it = 'Righe dissociate';
							|pl = 'Wierze odłączone';
							|tr = 'Satırlar çıkarıldı'");
		ExplanationText = NStr("vi = 'Trong chứng từ, có dòng (%Count%) bị bỏ liên kết với lệnh.';
								|ru = 'В документе от распоряжений отвязано строк (%Count%).';
								|en = 'In the document, the lines (%Count%) are unlinked from the references.'; fa = 'In the document, the lines (%Count%) are unlinked from the references.';
								|it = 'In the document, the lines (%Count%) are unlinked from the references.';
								|pl = 'In the document, the lines (%Count%) are unlinked from the references.';
								|tr = 'Belgede, siparişlerden ayrılmış bir satır mevcuttur (%Count%).'");
		ExplanationText = StrReplace(ExplanationText, "%Count%", NumberOfLinesWorked);
	Else
		MessageText = NStr("vi = 'Các dòng không liên quan';
							|ru = 'Строки не отвязаны';
							|en = 'Lines were not unlinked'; fa = 'Lines were not unlinked';
							|it = 'Righe non dissociate';
							|pl = 'Wierze nie odłączone';
							|tr = 'Satırlar çıkarılmadı'");
		ExplanationText = NStr("vi = 'Không có dòng nào liên quan.';
								|ru = 'Ни одна строка не была отвязана.';
								|en = 'No line was unlinked.'; fa = 'No line was unlinked.';
								|it = 'Nessuna riga è stata dissociata.';
								|pl = 'Nie odłączono ani jednego wiersza.';
								|tr = 'Herhangi bir satır çıkarılmadı.'");
	EndIf;
	
	ShowUserNotification(MessageText, , ExplanationText, PictureLib.Information32);
	
EndProcedure

&AtClient
Procedure FillInTheWarehouseInSelectedLinesCompletion(Result, AdditionalParameters) Export
	
	SelectedWarehouse   = Result;
	SelectedRows = AdditionalParameters.SelectedRows;
	
	If ValueIsFilled(SelectedWarehouse) Then
		FilledWithRows = FillWarehouseInSelectedLinesOnServer(SelectedRows, SelectedWarehouse);
		RowsSelectedCount  = SelectedRows.Count();
		
		WarehousesClient.ShowNotificationAboutFillingOfWarehouseInTablePart(SelectedWarehouse,
																					FilledWithRows,
																					RowsSelectedCount);
	EndIf;
	
EndProcedure

&AtServer
Function FillWarehouseInSelectedLinesOnServer(Val ArrayOfSelectedRows, Warehouse)
	
	FilledWithRows = WarehousesServer.FillInWarehousesInSelectedLines(Object.Goods,
																				ArrayOfSelectedRows,
																				Warehouse);
	
	If FilledWithRows > 0 Then
		RowsToProcess = New Array();
		For Each Id In ArrayOfSelectedRows Do
			RowsToProcess.Add(Object.Goods.FindByID(Id));
		EndDo;
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.ProcessTSStrings(RowsToProcess, StructureOfActions, Object.Goods);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
		WhenChangingWarehouseInTablePartServer();
	EndIf;
	
	Return FilledWithRows;
	
EndFunction

&AtClient
Procedure DateWhenFragmentWasChanged(RecalculatePrices_)
	
	Var PricesCalculated;
	
	DateOnChangeServer(RecalculatePrices_, PricesCalculated);
	
	If RecalculatePrices_ Then
		SalesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated);
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
