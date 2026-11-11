
#Region Variables

&AtClient
Var CachedValues; // used by the mechanism for processing changes in PM details

&AtClient
Var PreviousRowDetails; // used to unlink the receipt line from the order line

&AtClient
Var CurDataId; // used to pass the current line to the wait handler


&AtClient
Var ParametersForRecording Export;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Refund upon receipt of the form for analysis.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.GroupInTotal.BackColor = New Color();
	EndIf;
	
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object",                   Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization",  True);
	
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisObject);
	
	TMCommonUse.CustomizePeripherals(ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		AutoTitle = False;
		OnReadCreateAtServer();
		If Items.BusinessOperation.ChoiceList.Count() = 0 Then
			Cancel = True;
		EndIf;
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	ElsIf Parameters.FillingValues.Property("FillByWarehouseDocument") Then
		Modified = True;
		
		RefillByNotes(Parameters.FillingValues.AnArrayOfOrders);
	EndIf;
	SetConditionalAppearance();
	
	SalesServer.SetModeForSelectingGroupsOfWarehouseItems(Items.Warehouse);
	SalesServer.SetBlankContractMark(Items, "Contract", True);
	
	ReadPriceTypeRight   = AccessRight("View",
											Metadata.Documents.TransferOfGoodsToBailee.TabularSections.Goods.Attributes.PriceKind);
	
	Items.GoodsPriceKind.QuickChoice = Not GetFunctionalOption("UseSeveralPriceTypes");

	ElementsToFillIn = New Array;
	ElementsToFillIn.Add(Items.DeliveryTimeFrom);
	ElementsToFillIn.Add(Items.DeliveryTimeTo);
	ElementsToFillIn.Add(Items.DeliveryTimeFrom1);
	ElementsToFillIn.Add(Items.DeliveryTimeTo1);
	GoodsDeliveryClientServer.FillTimeFieldSelectionList(ElementsToFillIn);
	
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	If Object.Patch Then
		Items.GoodsSelectGoodsByOrdersNotes.Visible = False;
	EndIf;
		
	DocumentCorrection.OnCreateAtServer(ThisObject, Items.LineCorrection);

	// Standard subsystems.Accounting of the originals of the first documents
	SourceDocumentsOriginalsRecording.OnCreateAtServerDocumentForm(ThisObject);
	// The end of the standard subsystem.Accounting of the originals of the first documents 
	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	Items.EPDStateGroup.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");

	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	PreviousRowDetails = New Structure(
		"SKU,
		|Products,
		|ItemsType,
		|Characteristic,
		|ItemVariantsAreUsed,
		|Package,
		|Count,
		|NumberOfPackages,
		|Warehouse,
		|RowCode,
		|SalesOrder");
	
	If Object.TransferByOrders
		And Not TransferInExcessOfOrder
		And Not ValueIsFilled(Object.Ref)
		And Not ValueIsFilled(Object.Warehouse) Then
		
		If UseTransferForSeveralOrders Then
			MessageText = NStr("vi = 'Chỉ định kho chuyển nhượng và điền vào hàng hóa bằng lệnh ""Điền vào đơn hàng""';
								|ru = 'Уточните склад передачи и заполните товары с помощью команды ""Заполнить по заказам""';
								|en = 'Specify a transfer warehouse and fill in goods using the ""Fill in from orders"" command'; fa = 'Specify a transfer warehouse and fill in goods using the ""Fill in from orders"" command';
								|it = 'Specificare il magazzino di trasferimento e compilare le merci con l''aiuto del comando ""Compilare in base agli ordini""';
								|pl = 'Określ magazyn transferu i wypełnij wiersze pozycji poleceniem „Wypełnij wg zamówienia”';
								|tr = 'Transfer deposunu belirleyin ve ""Siparişe ilişkin doldur"" komutunu kullanarak ürünleri tamamlayın'");
		Else
			MessageText = NStr("vi = 'Chỉ định kho chuyển và điền vào hàng hóa bằng lệnh ""Điền vào đơn hàng""';
								|ru = 'Уточните склад передачи и заполните товары с помощью команды ""Заполнить по заказу""';
								|en = 'Specify a transfer warehouse and fill in goods using the ""Fill in from order"" command'; fa = 'Specify a transfer warehouse and fill in goods using the ""Fill in from order"" command';
								|it = 'Specificare il magazzino di trasferimento e compilare le merci con l''aiuto del comando ""Compilare in base all''ordine""';
								|pl = 'Określ magazyn transferu i wypełnij wiersze pozycji za pomocą polecenia „Wypełnij wg zamówienia”';
								|tr = 'Transfer deposunu belirleyin ve ""Siparişe göre doldur"" komutunu kullanarak ürünleri tamamlayın'");
		EndIf;
		
		CommonClient.MessageToUser(MessageText, Object.Ref, "Object.Warehouse");
		
	EndIf;
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisObject, "BarcodeScanner");
	
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
	EnableWaitingHandlerReceivingCarriers();
	
EndProcedure

&AtClient
Procedure OnClose()
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisObject);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "DataProcessor.SelectGoodsToSalesDocument.Form.Form" Then
		
		ProcessingSelectionOfSelectionOnServer(ValueSelected);
		
	ElsIf ChoiceSource.FormName = "Document.TransferOfGoodsToBailee.Form.SelectionOfGoodsFromOrderForm" Then
		
		ProcessingProductSelectionFromOrder(ValueSelected.GoodsAddressInStorage);
		
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectReusablePackage.Form.Form" Then
		
		FillMultiTurnContainersFromStorageServer(ValueSelected.AddressOfReusableContainerInStorage);
		ReusablePackageClient.NotifyUserAboutFillingMultiTurnContainers();
		
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected);
		
	ElsIf ChoiceSource.FormName = "Catalog.InventoryKinds.Form.InventoryOwnerAttributesForm" Then
		
		GetStockTypesFromStorage(ValueSelected);
		
	ElsIf ChoiceSource.FormName = "CommonForm.PrintingDetailsOfSales" Then
		
		If ValueSelected <> Undefined Then
			Modified = True;
			
			FillInAndSetDeliveryAttributes = Object.GoodsRecipient <> ValueSelected.GoodsRecipient;
			
			FillPropertyValues(Object, ValueSelected);
			
			If FillInAndSetDeliveryAttributes Then
				FillInAndSetDeliveryAttributesServer("GoodsRecipient");
			EndIf;
			
		EndIf;
		
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
	
	If EventName = "AddingPartnerToSegment"
		Or EventName = "RemovingPartnerFromSegment" Then
		
		SetVisibilityOfShipmentBanToPartner();
		
	EndIf;
	
	If EventName = "Write_GoodsIssueNote" Then
		ThereIsSpendingOrderForShippingOrders(Object.Ref, ShipmentStarted);
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
		If Parameter.Property("SalesOrder") Then
			SetParameters.Insert("SalesOrder", Parameter.SalesOrder);
		EndIf;
		SetParameters.Insert("ExceedingOrder",          True);
		SetParameters.Insert("DialColumns",        DialColumns(ThisObject));
		
		SetAddressInTemporaryStorage = SetAddressInTemporaryStorage(SetParameters);
		
		OpeningParameters = New Structure;
		OpeningParameters.Insert("AddressInTempStorage", SetAddressInTemporaryStorage);
		OpeningParameters.Insert("Ref",                    Object.Ref);
		OpeningParameters.Insert("Date",                      Object.Date);
		OpeningParameters.Insert("Partner",                   Object.Partner);
		OpeningParameters.Insert("Terms",                Object.Terms);
		OpeningParameters.Insert("Warehouse",                     Object.Warehouse);
		OpeningParameters.Insert("Currency",                    Object.Currency);
		OpeningParameters.Insert("ProductsInSet",        Parameter.ProductsInSet);
		OpeningParameters.Insert("ItemVariantOfSet",      Parameter.ItemVariantOfSet);
		OpeningParameters.Insert("HideCommandRemainingQuantityInWarehouses", False);
		
		OpenForm("DataProcessor.EditSet.Form.Form", OpeningParameters, ThisObject, UUID);
		
	EndIf;
	
	
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
	NotificationProcessingLocalization(EventName, Parameter, Source);
	
	
	DocumentCorrectionClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording	
	SourceDocumentsOriginalsRecordingClient.NotificationHandlerDocumentForm(EventName,ThisObject);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
	If EventName = "WhenChangingAgreement"
		And Source = ThisObject Then
		Modified = True;
		ContractOnChange(Items[Parameter]);
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
	
	If Not Object.TransferByOrders
		And WriteParameters.WriteMode = DocumentWriteMode.Posting
		And Object.Goods.Count() > 0
		And (Object.ReusablePackageFillingStatus = PredefinedValue("Enum.ReusablePackageFillingStates.OfferToFillIn")
			Or Not ValueIsFilled(Object.ReusablePackageFillingStatus)) Then
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("ThisObject", ThisObject);
		AdditionalParameters.Insert("WriteParameters", WriteParameters);
		
		TableName = "Goods";
		ColumnsNames = "Products,Characteristic,Count,Warehouse";
		
		AskAQuestion = ReusablePackageServerCall.AskQuestionAboutFillingMultiTurnContainers(
			Object,
			TableName,
			ColumnsNames);
		
		If AskAQuestion Then
			
			Cancel = True;
			CallbackDescription = New CallbackDescription(
				"BeforeRecordingOfferToPickUpMultiTurnContainer",
				ThisObject,
				AdditionalParameters);
			
			ReusablePackageClient.OfferToPickUpMultiTurnContainer(
				ThisObject,
				TableName,
				ColumnsNames,
				CallbackDescription,
				AskAQuestion);
			
		EndIf;
		
	EndIf;
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters, Cancel);
	
EndProcedure

&AtClient
Procedure BeforeRecordingOfferToPickUpMultiTurnContainer(Result, AdditionalParameters) Export
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject,
															AdditionalParameters.WriteParameters,
															False,
															True);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Handler of the "Properties" mechanism
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
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
	
	Handler = Documents.TransferOfGoodsToBailee.ActionHandler(Object.BusinessOperation);
	Handler.CustomizeForm(ThisObject, Object.Number, Object.Date);
	Handler.FillInShopPantryAttributeInTable(Object);
	UpdateOrderDeviations();
	FillInServiceDetailsForProductRange();
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, Object.ToReturnReusablePackage);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	SetElementProperties();
	CalculateTotals_(ThisObject);
	
	
	LinesOfBusinessServer.AfterWriteAtServer(ThisObject);
	
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	

	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)

	FormEventsClient.URLProcessing(ThisObject, FormattedStringURL, StandardProcessing);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Title = "";
	AutoTitle = True;
	
	WriteParameters.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
	Notify("Write_TransferOfGoodsToBailee", WriteParameters, Object.Ref);
	
	
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
Procedure BusinessOperationOnChange(Item)
	
	If BusinessTransactionBeforeTheChange = Object.BusinessOperation Then
		Return;
	EndIf;
	
	Object.Partner    = PredefinedValue("Catalog.Partners.EmptyRef");
	Object.Counterparty = PredefinedValue("Catalog.Counterparties.EmptyRef");
	Object.Terms = PredefinedValue("Catalog.TermsOfSale.EmptyRef");
	Object.Contract    = PredefinedValue("Catalog.CounterpartyContracts.EmptyRef");
	Object.Basis  = "";
	PartnerOnChange(Items.Partner);
	CounterpartyOnChange(Items.Counterparty);
	
	BusinessOperationOnChangeServer();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure TransferByOrdersOnChange(Item)
	
	SalesOrder = Undefined;
	
	SetAvailabilityOfClipboardCommandsOnClient();
	
	If ShipmentStarted
		And Object.TransferByOrders Then
		
		Object.TransferByOrders = False;
		
		WarningText = NStr("vi = 'Chứng từ này đã bắt đầu giao hàng. Thay đổi dấu hiệu ""Chuyển theo lệnh"" sau khi bắt đầu giao hàng không được phép.';
							|ru = 'По данному документу уже начата отгрузка. Менять признак ""Передача по заказу"" после начала отгрузки не допускается.';
							|en = 'Shipment has already started by this document. Cannot change the ""Transfer by order"" check box after shipment start.'; fa = 'Shipment has already started by this document. Cannot change the ""Transfer by order"" check box after shipment start.';
							|it = 'La spedizione in base al documento è già iniziata. La modifica del criterio ""Consegna per ordine"" dopo l''inizio della spedizione non è consentita.';
							|pl = 'Wysyłka w ramach dokumentu już się rozpoczęła. Zmiana oznaki „Transfer wg zamówienia” po rozpoczęciu wysyłki nie jest dozwolona.';
							|tr = 'Bu belge üzerinde sevkiyat zaten başlamıştır. Sevkiyat başladıktan sonra ""Siparişe ilişkin transfer"" işaretinin değiştirilmesine izin verilmez.'");
		
		ShowMessageBox(Undefined, WarningText);
		
		Return;
		
	EndIf;
	
	If Object.TransferByOrders Then
		
		If UseTransferForSeveralOrders Then
			
			If Object.Goods.Count() = 0 Then
				QueryText = NStr("vi = 'Danh sách Hàng hóa sẽ được điền lại bằng số dư hàng hóa chưa lập theo đơn hàng. Tiếp tục?';
								|ru = 'Список Товары будет перезаполнен остатками неоформленных товаров по заказам. Продолжить?';
								|en = 'The Item list will be refilled by remaining unregistered goods against orders. Continue?'; fa = 'The Item list will be refilled by remaining unregistered goods against orders. Continue?';
								|it = 'L''elenco Merci sarà ricompilato con giacenze delle merci non formalizzate per ordini. Continuare?';
								|pl = 'Lista Wiersze pozycji zostanie ponownie wypełniona przez resztki nieodebranych towarów z zamówień. Kontynuować?';
								|tr = 'Ürünler listesi siparişe ilişkin işlenmemiş ürünlerin bakiyeleri ile yeniden doldurulacaktır. Devam edilsin mi?'");
			Else
				QueryText = NStr("vi = 'Dòng trong danh sách Hàng hóa sẽ được gắn với dòng của đơn hàng. Tiếp tục?';
								|ru = 'Строки в списке Товары будут привязаны к строкам заказов. Продолжить?';
								|en = 'The Item list lines will be linked with the order lines. Continue?'; fa = 'The Item list lines will be linked with the order lines. Continue?';
								|it = 'Le righe nell''elenco ""Merci"" saranno associate alle righe degli ordini. Continuare?';
								|pl = 'Wiersze na liście Wiersze pozycji będą powiązane z wierszami zamówień. Kontynuować?';
								|tr = 'Ürünler listesindeki satırlar sipariş satırlarına bağlanacaktır. Devam edilsin mi?'");
			EndIf;
			
		Else
			
			FilterParameters = New Structure(
				"Partner,
				|Counterparty,
				|Terms,
				|Organization,
				|Contract,
				|Currency,
				|SalesOpportunity,
				|LineOfBusiness,
				|ToReturnReusablePackage");
			FillPropertyValues(FilterParameters, Object);
			
			OpeningParameters  = New Structure;
			OpeningParameters.Insert("Filter",                 FilterParameters);
			OpeningParameters.Insert("Warehouse",                 Object.Warehouse);
			OpeningParameters.Insert("Recorder",           Object.Ref);
			OpeningParameters.Insert("BusinessOperation", Object.BusinessOperation);
			CallbackDescription = New CallbackDescription("TransferByOrdersWhenChangedAfterSelection", ThisObject);
			
			OpenForm("Document.TransferOfGoodsToBailee.Form.ReferenceChoiceForm", OpeningParameters, ThisObject, , , ,
				CallbackDescription, FormWindowOpeningMode.LockOwnerWindow);
			
			Return;
			
		EndIf;
		
	Else
		
		If Object.Goods.Count() > 0 Then
			
			If UseTransferForSeveralOrders Then
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
			
			TransferByOrdersOnChangeServer();
			
			Return;
			
		EndIf;
		
	EndIf;
	
	TransferByOrdersWhenFragmentChanges(SalesOrder, QueryText);
	
EndProcedure

&AtClient
Procedure TransferByOrdersOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	SalesOrder = AdditionalParameters.SalesOrder;
	
	If QuestionResult = DialogReturnCode.No Then
		Object.TransferByOrders = Not Object.TransferByOrders;
		
		Return;
	EndIf;
	
	If ValueIsFilled(SalesOrder) Then
		Object.SalesOrder = SalesOrder;
	EndIf;
	
	TransferByOrdersOnChangeServer();
	
EndProcedure

&AtClient
Procedure LabelHeaderSalesOrdersClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	TitleText    = NStr("vi = 'Đơn hàng của khách (%DocumentsCount%)';
						|ru = 'Заказы клиентов (%DocumentsCount%)';
						|en = 'Sales orders (%DocumentsCount%)'; fa = 'Sales orders (%DocumentsCount%)';
						|it = 'Ordini dei clienti (%DocumentsCount%)';
						|pl = 'Zamówienia klientów (%DocumentsCount%)';
						|tr = 'Satış siparişleri (%DocumentsCount%)'");
	OpeningParameters = New Structure("DocumentsList, Title", OrderList, TitleText);
	
	OpenForm("CommonForm.ViewingListOfDocuments", OpeningParameters, ThisObject, , , , Undefined,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	NumberOfDiscrepancies = Object.Goods.Total("OrderDiscrepancy_3");
	
	If Not Object.TransferByOrders
		Or (TransferInExcessOfOrder
			And NumberOfDiscrepancies > 0) Then
		
		Notification = New CallbackDescription("DateOnChangeCompletion", ThisObject);
		EnterprisePricesFillingClient.AskQuestionAboutRecalculatingPriceWhenDateChanges(Object, Notification);
		
		Return;
		
	EndIf;
	
	DateWhenFragmentWasChanged(False);
	
EndProcedure

&AtClient
Procedure DateOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	If Not QuestionResult = DialogReturnCode.Cancel Then
		DateWhenFragmentWasChanged(QuestionResult);
	EndIf;
	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	PartnerOnChangeServer();
	
	If ToUseTermsOfSales
		And ValueIsFilled(Object.Terms) Then
		
		SalesClient.NotifyEndOfFillingInDefaultSalesConditions();
		
	EndIf;
	
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyOnChangeServer();
	
	
	WhenChangingKeyDetailsStatusOfEDO();
	
EndProcedure

&AtClient
Procedure TermsOnChange(Item)
	
	If Not ValueIsFilled(Object.Terms) Then
		Return;
	EndIf;
	
	ContractBeforeModifications = Object.Contract;
	
	WhenChangingAgreementAtServer();
	
	If Not ContractBeforeModifications = Object.Contract And ValueIsFilled(Object.Contract) And ConsignmentSales25
			And ValueIsFilled(PriceTypeAccountingPriceType) Then
		Notification = New CallbackDescription("ContractOnChangeCompletion", ThisObject);
		EnterprisePricesFillingClient.AskQuestionAboutRecalculatingPriceWhenChangingAgreement(Object, Notification);
	EndIf;
	
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
	AgreementSelectionParameters.BusinessOperation = Object.BusinessOperation;
	AgreementSelectionParameters.Organization           = Object.Organization;
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent") Then
		AgreementSelectionParameters.ConsignmentSales25 = True;
	EndIf;
	
	SalesClient.StartSelectingAgreementWithClient(AgreementSelectionParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	ContractBeforeModifications = Object.Contract;
	OrganizationOnChangeServer();
	
	If Not ContractBeforeModifications  = Object.Contract
		And ValueIsFilled(Object.Contract) And NewCommissionAgreement
		And ValueIsFilled(PriceTypeAccountingPriceType) Then
		Notification = New CallbackDescription("ContractOnChangeCompletion", ThisObject);
		EnterprisePricesFillingClient.AskQuestionAboutRecalculatingPriceWhenChangingAgreement(Object, Notification);
	EndIf;
	
	WhenChangingKeyDetailsStatusOfEDO();
	
EndProcedure

&AtClient
Procedure TextShippingToAPartnerIsProhibitedClick(Item)
	
	OpeningParameters = New Structure("Partner", Object.Partner);
	
	OpenForm("Catalog.Partners.Form.FormOfSegmentsOfShipmentProhibition", OpeningParameters);
	
EndProcedure

&AtClient
Procedure ContractCreating(Item, StandardProcessing)
	
	SalesClient.OpenContractCreationForm(ThisObject, Item, "Object.Contract", Object.Partner, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	ContractOnChangeServer();
	
	If ValueIsFilled(Object.Contract)
		And NewCommissionAgreement
		And ValueIsFilled(PriceTypeAccountingPriceType) Then
		Notification = New CallbackDescription("ContractOnChangeCompletion", ThisObject, True);
		EnterprisePricesFillingClient.AskQuestionAboutRecalculatingPriceWhenChangingAgreement(Object, Notification);
	EndIf;
	
	WhenChangingKeyDetailsStatusOfEDO();
	
EndProcedure

&AtClient
Procedure ContractOnChangeCompletion(QuestionResult, AdditionalParameters) Export 
	
	If Not QuestionResult = DialogReturnCode.Cancel And QuestionResult Then
		
		FillParameters = New Structure();
		FillParameters.Insert("PriceKind", PriceTypeAccountingPriceType);
		FillParameters.Insert("FieldPriceType", "PriceTypeAccountingPriceType");
		FillParameters.Insert("PriceIncludesVAT", Undefined);
		FillParameters.Insert("TabularSectionName", "Goods");
		FillParameters.Insert("TabularSectionPresentation", "Goods");
		
		If EnterprisePricesFillingClient.YouNeedToFillInPricesByType(Object, FillParameters) Then
			
			PricesCalculated = FillThePricesByTermsOfSalesServer(True, False, ValueIsFilled(AdditionalParameters));
			SalesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	If Warehouse <> Object.Warehouse Then
		
		If Object.TransferByOrders
			And Object.Goods.Count() > 0 Then
			
			If Not ItIsGroupOfWarehousesAndWarehousesUsedByWHForSale(Object.BusinessOperation, Object.Warehouse) Then
				
				ButtonsList = New ValueList;
				
				If TransferInExcessOfOrder Then
					ButtonsList.Add("Continue", NStr("vi = 'Xóa hàng hóa';
													|ru = 'Очистить товары';
													|en = 'Clear goods'; fa = 'Clear goods';
													|it = 'Cancellare le merci';
													|pl = 'Oczyść wiersze pozycji';
													|tr = 'Ürünleri temizle'"));
					ButtonsList.Add("Unlink",   NStr("vi = 'Bỏ khỏi đơn hàng';
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
									|tr = 'Stok değiştiğinde, ""Ürünler"" listesinin temizlenmesi veya satırların siparişten ayrılması gerekir. Devam edilsin mi?'")
				Else
					ButtonsList.Add("Continue", NStr("vi = 'Tiếp tục';
													|ru = 'Продолжить';
													|en = 'Continue'; fa = 'ادامه';
													|it = 'Continuare';
													|pl = 'Continue';
													|tr = 'Devam'"));
					
					QueryText = NStr("vi = 'Danh sách ""Hàng hóa"" sẽ bị xóa. Tiếp tục?';
									|ru = 'Список ""Товары"" будет очищен. Продолжить?';
									|en = 'The Item list will be cleared. Continue?'; fa = 'The Item list will be cleared. Continue?';
									|it = 'L''elenco ""Merci"" verrà cancellato. Continuare?';
									|pl = 'Lista ""Towaty"" zostanie wyczyszczona. Kontynuować?';
									|tr = '""Ürünler"" listesi temizlenecek. Devam edilsin mi?'")
				EndIf;
				
				ButtonsList.Add("Cancel", NStr("vi = 'Hủy bỏ';
												|ru = 'Отмена';
												|en = 'Cancel'; fa = 'انصراف';
												|it = 'Annulla';
												|pl = 'Cancel';
												|tr = 'İptal'"));
				
				AdditionalParameters = New Structure("UntieAllLinesFromOrder", False);
				CallbackDescription      = New CallbackDescription("WarehouseOnChangeCompletion",
																	ThisObject,
																	AdditionalParameters);
				
				ShowQueryBox(CallbackDescription, QueryText, ButtonsList);
				
				Return;
				
			EndIf;
			
		EndIf;
		
		WarehouseWhenFragmentChanges(False, False);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WarehouseOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	UntieAllLinesFromOrder = AdditionalParameters.UntieAllLinesFromOrder;
	
	If QuestionResult = "Cancel" Then
		
		Object.Warehouse = Warehouse;
		
		Return;
		
	ElsIf QuestionResult = "Unlink" Then
		ClearLines_             = False;
		UntieAllLinesFromOrder = True;
	Else
		ClearLines_ = True;
	EndIf;
	
	WarehouseWhenFragmentChanges(UntieAllLinesFromOrder, ClearLines_);
	
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	
	If Not ValueIsFilled(Object.Currency) Then
		Object.Currency = DocumentCurrency;
		
		Return;
	EndIf;
	
	RecalculateAmounts = PriceManagementSystemClient.CurrencyConversionRequired(Object, DocumentCurrency);
	
	WhenChangingCurrencyServer(Object.Currency, RecalculateAmounts);
	
	PriceManagementSystemClient.NotifyAboutEndOfConversionOfAmountsIntoCurrency(DocumentCurrency, Object.Currency);
	
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

#Region EventHandlersDelivery

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
Procedure SpecialTransportationConditionsOnChange(Item)
	
	SpecialTransportationConditionsOnChangeServer();
	
EndProcedure

#EndRegion

&AtClient
Procedure ManagerOnChange(Item)
	
	FillInSubordinatePropertiesForStatistics("Manager");
	
EndProcedure

&AtClient
Procedure ContactPersonOnChange(Item)
	
	If Object.ContactPerson.IsEmpty() Then
		Return;
	ElsIf Not Object.Partner.IsEmpty() Then
		Return;
	EndIf;
	
	PartnerChanged_ = False;
	
	ContactPersonOnChangeServer(PartnerChanged_);
	
	If Not PartnerChanged_ Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Object.Partner) Then
		GoodsDeliveryClientServer.ClearDeliveryDetails(Items,Object);
	Else
		
		If ToUseTermsOfSales
			And ValueIsFilled(Object.Terms) Then
			
			SalesClient.NotifyEndOfFillingInDefaultSalesConditions();
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure LineOfBusinessOnChange(Item)
	
	LineOfBusinessOnChangeServer();
	
EndProcedure


&AtClient
Procedure ToReturnReusablePackageOnChange(Item)
	
	ToReturnReusablePackageOnChangeServer();
	
EndProcedure

&AtClient
Procedure PrintDetails(Item)
	
	OpenTransferPrintDetails();
	
EndProcedure

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
	
EndProcedure
// End StandardSubsystems.Properties

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

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData; 
	
	If CurrentRow <> Undefined Then
		UpdateOrderDeviationsInLine(CurrentRow, Object.TransferByOrders);
		UpdateDependentDetailsOfOrderForm_(Items, Object.Goods, DiscrepancyOrderText);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.GoodsSalesOrder Then
		
		CurrentData = Items.Goods.CurrentData;
		
		If ValueIsFilled(CurrentData.SalesOrder) Then
			ShowValue(Undefined, CurrentData.SalesOrder);
		ElsIf ValueIsFilled(Object.SalesOrder) Then
			ShowValue(Undefined, Object.SalesOrder);
		EndIf;
		
	ElsIf Field = Items.GoodsPrice Then
		
		If ReadPriceTypeRight Then
			
			CurrentData = Items.Goods.CurrentData;
			
			If ValueIsFilled(CurrentData.PriceKind) Then
				
				ClearMessages();
				
				MessageText = NStr("vi = 'Để soạn đơn giá, hãy xóa dạng giá';
									|ru = 'Для редактирования цены очистите вид цены';
									|en = 'To edit the price, clear the price type'; fa = 'To edit the price, clear the price type';
									|it = 'Для редактирования цены очистите вид цены';
									|pl = 'To edit the price, clear the price type';
									|tr = 'Fiyatı düzenlemek için fiyat türünü temizleyin'");
				ItemField   = CommonClientServer.PathToTabularSection("Object.Goods",
																					CurrentData.LineNumber,
																					"PriceKind");
				
				CommonClient.MessageToUser(MessageText, Object.Ref, ItemField);
				
			EndIf;
			
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
Procedure GoodsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	If Object.TransferByOrders
		And Not TransferInExcessOfOrder Then
		
		Cancel = True;
		AddItemsFromSalesOrderGoodsIssue();
		
	EndIf;
	
	If Copy Then
		SetsClient.BeforeDeletingRowOfTablePart(ThisObject, "Goods", Cancel, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsBeforeRowChange(Item, Cancel)
	
	FillPropertyValues(PreviousRowDetails, Items.Goods.CurrentData);
	
EndProcedure

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters);
	
	SetsClient.BeforeDeletingRowOfTablePart(ThisObject, "Goods", Cancel);
	
EndProcedure

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	CurrentRow = Items.Goods.CurrentData;
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
	
	If Copy
		And Object.TransferByOrders Then
		
		CurrentRow.SalesOrder = Undefined;
		CurrentRow.RowCode = 0;
		
		CurrentRow.Purpose            = Undefined;
		CurrentRow.AssignmentSender = Undefined;
		
		UpdateOrderDeviationsInLine(CurrentRow, Object.TransferByOrders);
		UpdateDependentDetailsOfOrderForm_(Items, Object.Goods, DiscrepancyOrderText);
		
	EndIf;
	
	If CurrentRow <> Undefined And NewRow And NewCommissionAgreement
		And ValueIsFilled(PriceTypeAccountingPriceType) Then
		CurrentRow.PriceKind = PriceTypeAccountingPriceType;
	EndIf;
	
	SalesClient.ProductItemLineAtBeginningOfEditing(ThisObject, "Goods", CurrentRow, NewRow, Copy);
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters,
		Copy);
	
EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	CurrentData        = Items.Goods.CurrentData;
	UpdateSeriesStatuses = ProductsClient.SeriesStatusesNeedToBeUpdated(Item,
																			CachedValues,
																			SeriesSpecificationParameters);
	
	AdditionalParameters = New Structure;
	FormEventsClient.WhenChangingElement(ThisObject, Items.Goods, AdditionalParameters);
	
	If AdditionalParameters.Property("ServerCallRequired__") Or UpdateSeriesStatuses Then
		GoodsAtEndOfEditingOnServer(
			AdditionalParameters.Property("ServerCallRequired__"),
			?(UpdateSeriesStatuses, CurrentData.GetID(), Undefined),
			CachedValues);
	EndIf;
	
	If UpdateSeriesStatuses Then
		ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters);
	EndIf;
	
	UpdateDependentDetailsOfOrderForm_(Items, Object.Goods, DiscrepancyOrderText);
	ReusablePackageClient.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
	CalculateTotals_(ThisObject);
	
	If Not CancelEdit Then
		
		LineCache = ?(NewRow, Undefined, ProcessingOfTabularFormsClientServer.LineCache(Items.Goods, ThisObject));
		WarehousesClient.UpdateWarehouseTable(WarehouseTable, CurrentData, LineCache, WarehouseGroup_, False);
		
		TotalWarehouses_ = WarehouseTable.Count();
		
		WarehousesClientServer.UpdateWarehouseGroupImage(SeveralWarehousesText, Items.PictureMultipleWarehouses,
			TotalWarehouses_);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	
	UpdateSeriesStatuses = ProductsClient.SeriesStatusesNeedToBeUpdated(Item,
																			CachedValues,
																			SeriesSpecificationParameters,
																			True);
	
	GoodsAfterDeleteRowServer(UpdateSeriesStatuses, CachedValues);
	
	If UpdateSeriesStatuses Then
		ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters);
	EndIf;
	
	ReusablePackageClient.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	AdditionalParameters = AdditionalCompletionProcessingParameters();
	AdditionalParameters.CurrentRow = CurrentRow;
	CallbackDescription      = New CallbackDescription("GoodsNomenclatureWhenChangingQuestionToUserCompletion",
														ThisObject,
														AdditionalParameters);
	
	QuestionUserWhenChangingRowDetails(CallbackDescription, CurrentRow);
	
EndProcedure

// Goods nomenclature when changing the question to the user completion.
// 
// Parameters:
//	Result - Boolean
//	AdditionalParameters - Structure - 
&AtClient
Procedure GoodsNomenclatureWhenChangingQuestionToUserCompletion(Result, AdditionalParameters) Export
	
	If Not Result
		And TransferInExcessOfOrder Then
		
		Return;
		
	EndIf;
	
	CurrentRow = AdditionalParameters.CurrentRow;
	
	FillInArticleAttribute         = New Structure("Products", "SKU");
	FillInProductTypeAttribute_ = New Structure("Products", "ItemsType");
	
	CheckSeriesCalculateStatus = New Structure;
	CheckSeriesCalculateStatus.Insert("Warehouse",                  Object.Warehouse);
	CheckSeriesCalculateStatus.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters);
	
	CheckFillWarehouse = BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object,
																											WarehouseGroup_);
	
	ProductsOnChangeOverridable = New Structure;
	ProductsOnChangeOverridable.Insert("FormName",          FormName);
	ProductsOnChangeOverridable.Insert("TabularSectionName", "Goods");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInArticleAttribute",               FillInArticleAttribute);
	StructureOfActions.Insert("FillInProductTypeAttribute_",       FillInProductTypeAttribute_);
	StructureOfActions.Insert("CheckCharacteristicsByOwner",    CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("CheckSeriesCalculateStatus",        CheckSeriesCalculateStatus);
	StructureOfActions.Insert("CheckFillWarehouse",               CheckFillWarehouse);
	
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	
	StructureOfActions.Insert("ProductsOnChangeOverridable", ProductsOnChangeOverridable);
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	AddPriceFillingActionsToStructure(StructureOfActions, Object, ToUseTermsOfSales, UsePriceManagementSystem25, NewCommissionAgreement);
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Products", StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	FillInSenderSAssignment(Object.TransferByOrders, Object.BusinessOperation, CurrentRow);
	
	FillPropertyValues(PreviousRowDetails, CurrentRow);
	
	CalculateTotals_(ThisObject);
	
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

// Goods characteristic when changing the question to the user completion.
// 
// Parameters:
//	Result - Boolean
//	AdditionalParameters - Structure -
//
&AtClient
Procedure GoodsCharacteristicWhenChangingQuestionToUserCompletion(Result, AdditionalParameters) Export
	
	If Not Result
		And TransferInExcessOfOrder Then
		
		Return;
		
	EndIf;
	
	CurrentRow = AdditionalParameters.CurrentRow;
	
	CharacteristicOnChangeOverridable = New Structure;
	CharacteristicOnChangeOverridable.Insert("FormName",          FormName);
	CharacteristicOnChangeOverridable.Insert("TabularSectionName", "Goods");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", CharacteristicOnChangeOverridable);
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object, False);
	AddPriceFillingActionsToStructure(StructureOfActions, Object, ToUseTermsOfSales, UsePriceManagementSystem25, NewCommissionAgreement);
	
	If AdditionalParameters.LineDetachedFromOrder	Then
		LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	FillInSenderSAssignment(Object.TransferByOrders, Object.BusinessOperation, CurrentRow);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsPurposeOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	FillInSenderSAssignment(Object.TransferByOrders, Object.BusinessOperation, CurrentData);
	
EndProcedure

&AtClient
Procedure GoodsWithAssignmentOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	LinesOfBusinessClient.GoodsWithAssignmentOnChange(ThisObject, CurrentData);
	FillInSenderSAssignment(Object.TransferByOrders, Object.BusinessOperation, CurrentData);
	
EndProcedure

&AtClient
Procedure GoodsSeriesOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	ValueSelected.Value                   = CurrentRow.Series;
	ValueSelected.CurrentRowID = CurrentRow.GetID();
	
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
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	
	If CurrentRow.Count > 0 Then
		StructureOfActions.Insert("RecalculatePricePerPackage", CurrentRow.Count);
	Else
		AddPriceFillingActionsToStructure(StructureOfActions, Object, ToUseTermsOfSales, UsePriceManagementSystem25, NewCommissionAgreement);
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsPriceKindOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	FillInSalePrice = BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInSalePrice", FillInSalePrice);
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object, False);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsPriceOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object, False);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsSumOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePriceByAmount");
	
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

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

&AtClient
Procedure GoodsWarehouseOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	AdditionalParameters = AdditionalCompletionProcessingParameters();
	AdditionalParameters.CurrentRow = CurrentRow;
	CallbackDescription      = New CallbackDescription("GoodsWarehouseWhenChangingQuestionToUserCompletion",
														ThisObject,
														AdditionalParameters);
	
	QuestionUserWhenChangingRowDetails(CallbackDescription, CurrentRow);
	
EndProcedure

// Parameters:
// 	Result - Boolean - 
// 	AdditionalParameters - See AdditionalCompletionProcessingParameters
&AtClient
Procedure GoodsWarehouseWhenChangingQuestionToUserCompletion(Result, AdditionalParameters) Export
	
	If Not Result
		And TransferInExcessOfOrder Then
		
		WhenChangingWarehouseInTablePartServer();
		Return;
		
	EndIf;
	
	CurrentRow = AdditionalParameters.CurrentRow;
	
	CheckSeriesCalculateStatus = New Structure;
	CheckSeriesCalculateStatus.Insert("Warehouse",                  Object.Warehouse);
	CheckSeriesCalculateStatus.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckSeriesCalculateStatus", CheckSeriesCalculateStatus);
	AddFillInActionForShopPantryAttribute(Object.BusinessOperation, StructureOfActions, True);
	If AdditionalParameters.LineDetachedFromOrder Then
		LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	FillInSenderSAssignment(Object.TransferByOrders, Object.BusinessOperation, CurrentRow);
	
	UpdateDependentDetailsOfOrderForm_(Items, Object.Goods, DiscrepancyOrderText);
	
EndProcedure

&AtClient
Procedure GoodsSalesOrderStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData <> Undefined Then
		
		FilterParameters = New Structure();
		FilterParameters.Insert("Partner",                   Object.Partner);
		FilterParameters.Insert("Counterparty",                Object.Counterparty);
		FilterParameters.Insert("Terms",                Object.Terms);
		FilterParameters.Insert("Organization",               Object.Organization);
		FilterParameters.Insert("Contract",                   Object.Contract);
		FilterParameters.Insert("Currency",                    Object.Currency);
		FilterParameters.Insert("SalesOpportunity",                    Object.SalesOpportunity);
		FilterParameters.Insert("LineOfBusiness",   Object.LineOfBusiness);
		FilterParameters.Insert("ToReturnReusablePackage", Object.ToReturnReusablePackage);
		
		OpeningParameters  = New Structure;
		OpeningParameters.Insert("Filter",                 FilterParameters);
		OpeningParameters.Insert("Warehouse",                 Object.Warehouse);
		OpeningParameters.Insert("Recorder",           Object.Ref);
		OpeningParameters.Insert("BusinessOperation", Object.BusinessOperation);
		CallbackDescription = New CallbackDescription("GoodsSalesOrderStartChoiceCompletion", ThisObject);
		
		OpenForm("Document.TransferOfGoodsToBailee.Form.ReferenceChoiceForm", OpeningParameters, ThisObject , , , ,
			CallbackDescription, FormWindowOpeningMode.LockOwnerWindow);
		
		Return;
		
	EndIf;
	
	UpdateOrderInformation();
	
EndProcedure

&AtClient
Procedure GoodsSalesOrderStartChoiceCompletion(Result, AdditionalParameters) Export
	
	Items.Goods.CurrentData.SalesOrder = Result;
	
	UpdateOrderInformation();
	
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
	
	TMCommonUseClient.Write(ThisObject, True);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject, True);
	
EndProcedure

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
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure CheckCounterparties(Command)
	
	
EndProcedure

&AtClient
Procedure OpenInventoryKinds(Command)
	
	OptionsForEditingInventoryTypes = PutGoodsAndStockTypesInStorage();
	
	FinancesClient.OpenInventoryKinds(ThisObject, OptionsForEditingInventoryTypes);
	
EndProcedure

&AtClient
Procedure CloseOrder(Command)
	
	If Modified
		Or Not Object.Posted Then
		
		CallbackDescription = New CallbackDescription("CloseOrderCompletion", ThisObject);
		QueryText       = NStr("vi = 'Cần kết chuyển chứng thừ để thực hiện giao dịch. Kết chuyển chứng từ?';
								|ru = 'Необходимо провести документ для выполнения операции. Провести документ?';
								|en = 'To proceed, you need to post the document. Do you want to post the document?'; fa = 'To proceed, you need to post the document. Do you want to post the document?';
								|it = 'È necessario pubblicare il documento per eseguire operazione. pubblicare documento?';
								|pl = 'Należy zaksięgować dokument aby wykonać operację. Zaksięgować dokument?';
								|tr = 'Bir işlemin gerçekleştirilmesi için belgenin düzenlenmesi gerekir. Belge düzenlensin mi?'");
		
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		
		Return;
		
	EndIf;
	
	CloseOrderFragment();
	
EndProcedure

&AtClient
Procedure CloseOrderCompletion(QuestionResult, AdditionalParameters) Export
	
	WriteParameters = New Structure("WriteMode", DocumentWriteMode.Posting);
	
	If QuestionResult = DialogReturnCode.No Then
		Return;
	ElsIf Not Write(WriteParameters) Then
		Return;
	EndIf;
	
	CloseOrderFragment();
	
EndProcedure

#Region FormTableCommandHandlersGoods

&AtClient
Procedure CopyRows(Command)
	
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items.Goods) Then
		CopyLinesOnServer();
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(Items.Goods.SelectedRows.Count());
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
	TableData = Object.Goods;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.StructureOfRecalculationOfAmount(
		"Count, Sum", "NumberOfPackages");
	
	If FormTable.CurrentData <> Undefined Then
		BatchProcessingOfTablePartClientServer.FillInStructureForRecalculatingAmount(StructureOfRecalculationOfAmount, FormTable.CurrentData);
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("StructureOfRecalculationOfAmount", StructureOfRecalculationOfAmount);
	
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable,
		New CallbackDescription("SplitRowCompletion", ThisObject, AdditionalParameters));
	
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
		AddActionRecalculateNumberOfUnits(Object.BusinessOperation, StructureOfActions, True);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
		WhenChangingWarehouseInTablePartServer();
		CalculateTotals_(ThisObject);
		
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
	KitParameters.Insert("SalesOrder", CurrentRow.SalesOrder);
	KitParameters.Insert("ExceedingOrder",          True);
	KitParameters.Insert("DialColumns",        DialColumns(ThisObject));
	
	SetAddressInTemporaryStorage = SetAddressInTemporaryStorage(KitParameters);
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("Ref",     Object.Ref);
	OpeningParameters.Insert("Date",       Object.Date);
	OpeningParameters.Insert("Partner",    Object.Partner);
	OpeningParameters.Insert("Terms", Object.Terms);
	OpeningParameters.Insert("Warehouse",      Object.Warehouse);
	OpeningParameters.Insert("Currency",     Object.Currency);
	
	OpeningParameters.Insert("ProductsInSet",   CurrentRow.ProductsInSet);
	OpeningParameters.Insert("ItemVariantOfSet", CurrentRow.ItemVariantOfSet);
	OpeningParameters.Insert("SalesOrder", CurrentRow.SalesOrder);
	
	OpeningParameters.Insert("HideCommandRemainingQuantityInWarehouses", False);
	OpeningParameters.Insert("AddressInTempStorage",       SetAddressInTemporaryStorage);
	
	OpenForm("DataProcessor.EditSet.Form.Form", OpeningParameters, ThisObject, UUID);
	
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
	
	Notification = New CallbackDescription("DownloadFromTSDCompletion", ThisObject);
	
	EquipmentManagerClient.StartDownloadingDataFromTSD(Notification, UUID);
	
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
Procedure GetWeight(Command)
	
	CurrentRow = EquipmentManagerTMClient.CurrentRow(ThisObject);
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	Notification = New CallbackDescription("GetWeightCompletion", ThisObject, CurrentRow);
	
	EquipmentManagerClient.StartGettingWeightWithElectronicScales(Notification, UUID);
	
EndProcedure

&AtClient
Procedure GetWeightCompletion(ExecutionResult, CurrentRow) Export
	
	If ExecutionResult.Result Then
		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
		
		CurrentRow.NumberOfPackages = ExecutionResult.Weight;
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		
		CalculateTotals_(ThisObject);
	Else
		EquipmentManagerTMClient.ReportError(ExecutionResult);
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckQuantityInTheDocument(Command)
	
	AddressOfTheGoodsInTheTemporaryStorage     = PutTablePartOfGoodsInTemporaryStorageToCheckQuantity();
	GoodsQuantityExcessIsAllowed = Not Object.TransferByOrders
											Or TransferInExcessOfOrder;
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("Ref",            Object.Ref);
	OpeningParameters.Insert("TabularSectionName", "Goods");
	
	OpeningParameters.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters);
	OpeningParameters.Insert("CalculateSets",     True);
	
	OpeningParameters.Insert("AddressInTempStorage", AddressOfTheGoodsInTheTemporaryStorage);
	OpeningParameters.Insert("GoodsQuantityExcessIsAllowed", GoodsQuantityExcessIsAllowed);
	
	CallbackDescription = New CallbackDescription("CheckQuantityInTheDocumentCompletion", ThisObject);
	
	OpenForm("CommonForm.CheckDocumentPopulation", OpeningParameters, ThisObject, , , , CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure CheckQuantityInTheDocumentCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		Modified   = True;
		CachedValues = ?(CachedValues = Undefined,
								BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues(),
								CachedValues);
		
		ChangeTablePartBasedOnResultsOfCheck(Result, CachedValues);
		BaseText = NStr("vi = 'đã nhập trên cơ sở lệnh hoặc không sử dụng được vai trò ""Bán hàng vượt quá đơn hàng"".';
						|ru = 'введенного на основании распоряжения или недоступна роль ""Реализация сверх заказа"".';
						|en = 'entered based on the reference, or the ""Sales in excess of order"" role is unavailable.'; fa = 'entered based on the reference, or the ""Sales in excess of order"" role is unavailable.';
						|it = 'введенного на основании распоряжения или недоступна роль ""Реализация сверх заказа"".';
						|pl = 'entered based on the reference, or the ""Sales in excess of order"" role is unavailable.';
						|tr = 'введенного на основании распоряжения или недоступна роль ""Реализация сверх заказа"".'");
		TMCommonUseClient.DisplayMessageExceedingNumber(Result, BaseText);
		
		CalculateTotals_(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure UnlinkFromOrder(Command)
	
	SelectedRows = Items.Goods.SelectedRows;
	
	If SelectedRows.Count() > 0 Then
		UnlinkFromOrderServer(False);
		NotifyAboutEndOfUnbindingLines(SelectedRows.Count());
	Else
		WarningText = NStr("vi = 'Hãy chọn dòng cần hủy liên kết với đơn hàng.';
							|ru = 'Выберите строки, которые необходимо отвязать от заказа.';
							|en = 'Select lines to remove from the order.'; fa = 'Select lines to remove from the order.';
							|it = 'Selezionare le righe da dissociare dall''ordine.';
							|pl = 'Wybierz wierze, które należy odłączyć od zamówienia.';
							|tr = 'Siparişten çıkarılacak satırları seçin.'");
		ShowMessageBox(Undefined, WarningText);
	EndIf;
	
EndProcedure

&AtClient
Procedure NotifyAboutEndOfUnbindingLines(NumberOfLinesWorked, LinesWereUnlinked = True)

	If LinesWereUnlinked Then
		MessageText = NStr("vi = 'Các dòng liên quan';
							|ru = 'Строки отвязаны';
							|en = 'Lines were unlinked'; fa = 'Lines were unlinked';
							|it = 'Righe dissociate';
							|pl = 'Wierze odłączone';
							|tr = 'Ayrılmış satırlar'");
		ExplanationText = NStr("vi = 'Trong chứng từ, các dòng được bỏ liên kết từ các lệnh (%Count%).';
								|ru = 'В документе от заказов отвязано строк (%Count%).';
								|en = 'In the document, (%Count%) lines are detached from the orders.'; fa = 'In the document, (%Count%) lines are detached from the orders.';
								|it = 'Righe dissociate (%Count%) dagli ordini nel documento.';
								|pl = 'W dokumencie od zamówień odwiązano wierszy (%Count%).';
								|tr = 'Belgede siparişlerden ayrılmış satırlar (%Count%) vardır.'");
		ExplanationText = StrReplace(ExplanationText, "%Count%", NumberOfLinesWorked);
	Else
		MessageText = NStr("vi = 'Dòng có liên quan';
							|ru = 'Строки не отвязаны';
							|en = 'Lines were not unlinked'; fa = 'Lines were not unlinked';
							|it = 'Righe non dissociate';
							|pl = 'Wierze nie odłączone';
							|tr = 'Birleşik satırlar'");
		ExplanationText = NStr("vi = 'Không có dòng nào liên quan.';
								|ru = 'Ни одна строка не была отвязана.';
								|en = 'No line was unlinked.'; fa = 'No line was unlinked.';
								|it = 'Nessuna riga è stata dissociata.';
								|pl = 'Nie odłączono ani jednego wiersza.';
								|tr = 'Hiçbir satır ayrılmamış'");
	EndIf;
	
	ShowUserNotification(MessageText, , ExplanationText, PictureLib.Information32);
	
EndProcedure

&AtClient
Procedure SpecifySeries(Command)
	
	OpenSelectionOfSeries();
	
EndProcedure

&AtClient
Procedure OpenSelection(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.TransferOfGoodsToBailee.DocumentForm.Command.OpenSelection");
	
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
		HeaderParameter_ = StrReplace(HeaderParameter_, "%Document%", NStr("vi = 'chuyển hàng cho người trông coi';
																			|ru = 'передачу товаров хранителю';
																			|en = 'vmi fill-up'; fa = 'vmi fill-up';
																			|it = 'consegna delle merci al depositario';
																			|pl = 'transfer towarów do depozytariusza';
																			|tr = 'malların emanetçiye transferi'"));
	EndIf;

	FilterByProductType = New FixedArray(ProductsClientServer.SelectionByProductMultiTurnContainer());
	
	FormParameters = New Structure;
	FormParameters.Insert("Document",    Object.Ref);
	FormParameters.Insert("Title",   HeaderParameter_);
	FormParameters.Insert("Date",        Object.Date);
	FormParameters.Insert("Terms",  Object.Terms);
	FormParameters.Insert("Partner",     Object.Partner);
	FormParameters.Insert("Organization", Object.Organization);
	FormParameters.Insert("Warehouse",       Object.Warehouse);
	FormParameters.Insert("Currency",      Object.Currency);
	
	FormParameters.Insert("FilterByProductType", FilterByProductType);
	FormParameters.Insert("SeriesSpecificationParameters",  SeriesSpecificationParameters);
	
	FormParameters.Insert("SelectionModeUseWarehousesInTabularSection", True);
	FormParameters.Insert("SelectionModeExcludeGroupsAvailableInOrders",  True);
	
	FormParameters.Insert("HideManualDiscounts", True);
	
	FormParameters.Insert("LineOfBusiness",      Object.LineOfBusiness);
	FormParameters.Insert("ReturnReusablePackage", Object.ToReturnReusablePackage);
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferToToller2_5") Then
		FormParameters.Insert("UseAdvancedFeaturesOfSalesOrder", True);
	EndIf;
	OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form", FormParameters, ThisObject, UUID);
	
EndProcedure

&AtClient
Procedure SelectGoodsByOrdersNotes(Command)
	
	AddItemsFromSalesOrderGoodsIssue();
	
EndProcedure

&AtClient
Procedure AddReusablePackage(Command)
		
	ReusablePackageClient.SelectReusablePackage(ThisObject, "Goods",
		"Products,Characteristic,Count,Warehouse");
	
EndProcedure

&AtClient
Procedure FillInSeriesByFEFO(Command)
	
	If ThereAreFilledSeriesByFEFO() Then
		
		Notification = New CallbackDescription("CompleteSeriesOnFEFOCompletion", ThisObject);
		
		ProductsClient.AskQuestionAboutReFillingSeriesByFEFO(Notification);
		
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
Procedure ImportFromExternalFile(Command)
	
	ImportParameters = ProcessingOfTabularFormsClient.ProductLoadingParameters();
	ImportParameters.ImportPrices = True;
	ImportParameters.ThisIsReusablePackage = Object.ToReturnReusablePackage;
	ImportParameters.ComponentsPriceParameters.Date       = Object.Date;
	ImportParameters.ComponentsPriceParameters.Currency     = Object.Currency;
	ImportParameters.ComponentsPriceParameters.Terms = Object.Terms;
	ImportParameters.FilterParameters.Insert("ItemsType",
		ProductsClientServer.SelectionByProductMultiTurnContainer());
	
	Notification = New CallbackDescription("ImportFromExternalFileCompletion", ThisObject);
	ProcessingOfTabularFormsClient.ShowProductUploadForm(ImportParameters, Notification);

EndProcedure

&AtClient
Procedure AutoTestFillInPricesByAgreement(Command) Export
	
	FillThePricesByTermsOfSales(Command);
	
EndProcedure

&AtClient
Procedure FillThePricesByTermsOfSales(Command)
	
	If EnterprisePricesFillingClient.ItIsNecessaryToFillInPricesByAgreement(Object, "Goods", NStr("vi = 'Hàng hóa';
																									|ru = 'Товары';
																									|en = 'Goods'; fa = 'کالاها';
																									|it = 'Merci';
																									|pl = 'Wiersze pozycji';
																									|tr = 'Ürünler'")) Then
		
		If TransferInExcessOfOrder
			And Not VarianceFromTransferConditions Then
			
			If Object.TransferByOrders
				And Object.Goods.Total("OrderDiscrepancy_3") = 0 Then
				
				WarningText = NStr("vi = 'Giá không thể gán cho các dòng theo đơn hàng.';
									|ru = 'Цена не может быть назначена в строках по заказу.';
									|en = 'Price cannot be assigned in the order lines.'; fa = 'Price cannot be assigned in the order lines.';
									|it = 'Il prezzo non può essere impostato nelle righe per ordine.';
									|pl = 'Cena nie może być wyznaczona w wierszach wg zamówienia.';
									|tr = 'Fiyat, sipariş satırlarına girilemiyor.'");
				
				ShowMessageBox(Undefined, WarningText);
				
				Return;
				
			EndIf;
			
		EndIf;
		
		PricesCalculated = FillThePricesByTermsOfSalesServer();
		
		SalesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInPricesUnderAgreement(Command)
	
	FillInContractPricesInLine();
	
EndProcedure

&AtClient
Procedure FillInPricesOfSelectedRowsByPriceType(Command)
	
	If EnterprisePricesFillingClient.ItIsNecessaryToFillInPricesByTypeOfPrices(Object, "Goods", NStr("vi = 'Hàng hóa';
																									|ru = 'Товары';
																									|en = 'Goods'; fa = 'کالاها';
																									|it = 'Merci';
																									|pl = 'Wiersze pozycji';
																									|tr = 'Ürünler'")) Then
		PriceSelectionOptions = EnterprisePricesFillingClient.NewFillOptionsSelectPriceType();
		PriceSelectionOptions.CallbackDescription = 
			New CallbackDescription("FillInPricesOfSelectedRowsByPriceTypeCompletion", ThisObject);
		PriceSelectionOptions.UseWhileSellingToCustomers = True;
		PriceSelectionOptions.OwnerOfAnIndividualPriceType = ?(ToUseTermsOfSales,Object.Terms,Object.Partner);
		
		EnterprisePricesFillingClient.ChooseTypeOfPrices(PriceSelectionOptions);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInPricesOfSelectedRowsByPriceTypeCompletion(PricesKind, AdditionalParameters) Export
	
	If ValueIsFilled(PricesKind) Then
		
		RowsArray = New Array;
		
		For Each CurRow In Items.Goods.SelectedRows Do
			
			FoundRow = Object.Goods.FindByID(CurRow);
			
			If VarianceFromTransferConditions
				Or (TransferInExcessOfOrder
					And FoundRow.RowCode = 0) Then
				
				RowsArray.Add(FoundRow);
				
			EndIf;
			
		EndDo;
		
		If RowsArray.Count() = 0
			And TransferInExcessOfOrder
			And Object.TransferByOrders
			And Not VarianceFromTransferConditions Then
			
			WarningText = NStr("vi = 'Giá không thể gán cho các dòng theo đơn hàng.';
								|ru = 'Цена не может быть назначена в строках по заказу.';
								|en = 'Price cannot be assigned in the order lines.'; fa = 'Price cannot be assigned in the order lines.';
								|it = 'Il prezzo non può essere impostato nelle righe per ordine.';
								|pl = 'Cena nie może być wyznaczona w wierszach wg zamówienia.';
								|tr = 'Fiyat, sipariş satırlarına girilemiyor.'");
			
			ShowMessageBox(Undefined, WarningText);
			
			Return;
			
		EndIf;
		
		PricesCalculated = FillInPricesOfSelectedRowsByPriceTypeServer(PricesKind);
		SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, PricesKind);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInTheWarehouseInSelectedLines(Command)
	
	PresentationOfTS  = NStr("vi = 'Hàng hóa';
							|ru = 'Товары';
							|en = 'Goods'; fa = 'کالاها';
							|it = 'Merci';
							|pl = 'Wiersze pozycji';
							|tr = 'Ürünler'");
	SelectedRows = Items.Goods.SelectedRows;
	
	FillWarehouses_1 = WarehousesClient.CheckPossibilityOfFillingWarehousesInTablePart(Object,
																						Object.Goods,
																						PresentationOfTS,
																						SelectedRows);
	
	If FillWarehouses_1 Then
		FilterStructure1 = New Structure;
		FilterStructure1.Insert("IsFolder", False);
		FilterStructure1.Insert("SelectGroup",
								PredefinedValue("Enum.SelectWarehouseGroup.AllowInOrdersAndInvoices"));
		
		ParametersStructure = New Structure("Filter, GroupOfWarehouses", FilterStructure1, Object.Warehouse);
		
		AdditionalParameters = New Structure("SelectedRows", SelectedRows);
		CallbackDescription      = New CallbackDescription("FillInTheWarehouseInSelectedLinesCompletion",
															ThisObject,
															AdditionalParameters);
		
		OpenForm("Catalog.Warehouses.ChoiceForm", ParametersStructure, ThisObject, , , , CallbackDescription,
			FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInTheWarehouseInSelectedLinesCompletion(Result, AdditionalParameters) Export
	
	SelectedWarehouse   = Result;
	SelectedRows = AdditionalParameters.SelectedRows;
	
	If ValueIsFilled(SelectedWarehouse) Then
		FilledWithRows = FillWarehouseInSelectedLinesOnServer(SelectedRows, SelectedWarehouse);
		RowsSelectedCount  = SelectedRows.Count();
		
		WarehousesClient.ShowNotificationAboutFillingOfWarehouseInTablePart(SelectedWarehouse, FilledWithRows, RowsSelectedCount);
	EndIf;
	
EndProcedure

&AtClient
Procedure ImportFromExternalFileCompletion(ImportedDataAddress, AdditionalParameters) Export
	
	If ValueIsFilled(ImportedDataAddress) Then
		GetUploadedProductsFromStorage(ImportedDataAddress);
	EndIf;
	
EndProcedure

#EndRegion

&AtClient
Procedure SupplementDeliveryInformationWithContacts(Command)
	
	SupplementDeliveryInformationWithContactsServer();
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure


&AtClient
Procedure SetTheMarkApart(Command)
	
	SetUncheckSeparately(True);
	
EndProcedure

&AtClient
Procedure UncheckTheSeparateBox(Command)
	
	SetUncheckSeparately(False);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure UpdateTextDocumentsBasedOn()
	
	TextsFieldsDocumentsBasedOn.Clear();
	UpdateTextDocumentsBasedOnLocalization();
	TMCommonUseClientServer.UpdateTextDocumentsBasedOn(ThisObject);
	
EndProcedure

#Region OnChangeAttributes

&AtServer
Procedure BusinessOperationOnChangeServer()
	
	ConsignmentSales25 = ?(Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent,
		True, False);
	
	If Object.ToReturnReusablePackage Then
		Object.ToReturnReusablePackage = False;
	EndIf;
	
	Items.TareGroup.Visible = Object.ToReturnReusablePackage;
	
	UseTransferForMultipleOrdersBeforeChange = UseTransferForSeveralOrders;
	
	Handler = Documents.TransferOfGoodsToBailee.ActionHandler(Object.BusinessOperation);
	
	ToUseTermsOfSales        = Handler.CustomerAgreementsAreApplicable()
											  And Handler.ToUseTermsOfSales();
	UseSalesOrders              = Handler.UseSalesOrders();
	UseTransferForSeveralOrders = Handler.UseSaleByMultipleOrders();
	
	If Object.TransferByOrders
		Or UseTransferForMultipleOrdersBeforeChange <> UseTransferForSeveralOrders Then
		Object.TransferByOrders = False;
		TransferByOrdersOnChangeServer();
	EndIf;
	
	Handler.RecalculateNumberOfUnits(Object);
	
	ContractOnChangeServer();
	
	SetDefaultPriceView();
	
	Handler.AdjustItemSelectionSettings(ThisObject, Object);
	Handler.CustomizeForm(ThisObject, Object.Number, Object.Date);
	
	SeriesSpecificationParameters = SeriesSpecificationParameters();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	BusinessTransactionBeforeTheChange = Object.BusinessOperation;
	
	SetVisibilityOfGoodsDestinationFormElement();
	
	
EndProcedure

&AtServer
Procedure MethodPlaceOfDeliveryCarrierIfChangedServer(ItemName)
	
	GoodsDelivery.FillInDeliveryDetails(Items, ItemName, Object);
	UpdateTextDocumentsBasedOn();

EndProcedure

&AtServer
Procedure TransferByOrdersOnChangeServer()
	
	If Object.TransferByOrders Then
		
		If Object.Goods.Count() = 0 Then
			FillInFromOrderServer();
		Else
			LinkTransferLinesToOrders(Not UseTransferForSeveralOrders);
		EndIf;
		
	Else
		
		OrderList.Clear();
		UnlinkFromOrderServer(True, False);
		
		Object.SalesOrder = Undefined;
		
		ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
		
	EndIf;
	
	UpdateOrderInformation();
	UpdateOrderDeviations();
	UpdateDependentDetailsOfServerByOrderForm();
	SetElementProperties();
	CalculateTotals_(ThisObject);
	
	GoodsDelivery.WhenChangingFlagForOrders(Items, Object, Object.TransferByOrders);
	LinesOfBusinessServer.SetVisibilityOfElementsSeparately(ThisObject);
	SetLBEditingOption();
	
EndProcedure

&AtServer
Procedure DateOnChangeServer(RecalculatePrices_, PricesCalculated)
	
	If RecalculatePrices_ Then
		PricesCalculated = FillThePricesByTermsOfSalesServer(True);
	Else
		PricesCalculated = False;
	EndIf;
	
	TableWarehouses            = Object.Goods.Unload(,"Warehouse").UnloadColumn("Warehouse");
	AdvancedWarehousingOnShipment = WarehousesServer.ThereIsOrderWarehouseForShipment(TableWarehouses, Object.Date, Object.Warehouse);
	
	DocumentDate = ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate());
	
	Object.LocalConversionRatio = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(Object.Currency,
																										LocalAccountingCurrency,
																										DocumentDate);
	
	HowToSetSeriesVisibility();
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
EndProcedure

&AtServer
Procedure PartnerOnChangeServer()
	
	If Not ValueIsFilled(Object.Partner) Then
		SetVisibilityOfShipmentBanToPartner();
		GoodsDeliveryClientServer.ClearDeliveryDetails(Items, Object);
		Object.Terms = Catalogs.TermsOfSale.EmptyRef();
		Handler = Documents.TransferOfGoodsToBailee.ActionHandler(Object.BusinessOperation);
		Handler.SetContractAvailability(ThisObject, Object, Object.Contract);
		
		Return;
	EndIf;
	
	DirectionsOfActivity = Object.LineOfBusiness;
	
	DocumentSales = FormAttributeToValue("Object");
	DocumentSales.FillInDefaultSalesConditions();
	ResponsiblePersonsServer.FillInManager_(DocumentSales);
	ValueToFormAttribute(DocumentSales, "Object");
	
	If ValueIsFilled(Object.Terms) Then
		DocumentCurrency = Object.Currency;
	EndIf;
	
	SetVisibilityOfShipmentBanToPartner();
	
	FillInDefaultContract();
	
	WarehouseOnChangeServer();
	
	FillInServiceDetailsForProductRange();
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, Object.ToReturnReusablePackage);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateTotals_(ThisObject);
	
	SalesServer.PartnerOnChange(Object);
	
	FillInSubordinatePropertiesForStatistics("Counterparty");
	
	GoodsDelivery.FillInDeliveryDetails(Items, "Partner", Object);
	
	If DirectionsOfActivity <> Object.LineOfBusiness Then
		LineOfBusinessOnChangeServer();
	EndIf;
	
	UpdateAvailabilityOfReturnContainerItems(ThisObject);
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	
	DirectionsOfActivity = Object.LineOfBusiness;
	
	GoodsDelivery.FillInDeliveryDetails(Items, "Partner", Object);
	
	Handler = Documents.TransferOfGoodsToBailee.ActionHandler(Object.BusinessOperation);
	Handler.SetContractAvailability(ThisObject, Object, Object.Contract);
	
	If ValueIsFilled(Object.Counterparty) Then
		FillInDefaultContract();
		
		SalesServer.PartnerOnChange(Object);
	EndIf;
	
	FillInSubordinatePropertiesForStatistics("Counterparty");
	
	If DirectionsOfActivity <> Object.LineOfBusiness Then
		LineOfBusinessOnChangeServer();
	EndIf;
	
	UpdateTextDocumentsBasedOn();
	
EndProcedure

&AtServer
Procedure WhenChangingAgreementAtServer()
	
	DirectionsOfActivity = Object.LineOfBusiness;
	
	DocumentSales = FormAttributeToValue("Object");
	DocumentSales.FillInTermsOfSalesUnderAgreement();
	ResponsiblePersonsServer.FillInManager_(DocumentSales);
	ValueToFormAttribute(DocumentSales, "Object");
	
	DocumentCurrency = Object.Currency;
	
	If Contract <> Object.Contract Then
		Contract = Object.Contract;
		ContractOnChangeServer();
		FillBaseForPrinting();
	EndIf;
	
	Handler = Documents.TransferOfGoodsToBailee.ActionHandler(Object.BusinessOperation);
	Handler.SetContractAvailability(ThisObject, Object, Object.Contract);
	
	WarehouseOnChangeServer();
	
	FillInServiceDetailsForProductRange();
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, Object.ToReturnReusablePackage);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateTotals_(ThisObject);
	
	If DirectionsOfActivity <> Object.LineOfBusiness Then
		LineOfBusinessOnChangeServer();
	EndIf;
	
	UpdateAvailabilityOfReturnContainerItems(ThisObject);
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	DirectionsOfActivity = Object.LineOfBusiness;
	
	If ValueIsFilled(Object.Organization) Then
		FillInDefaultContract();
	EndIf;
	
	If ValueIsFilled(Object.Terms)
		And Common.ObjectAttributeValue(Object.Terms, "Organization") <> Object.Organization Then
		Object.Terms = Catalogs.TermsOfSale.EmptyRef();
	EndIf;
	
	Handler = Documents.TransferOfGoodsToBailee.ActionHandler(Object.BusinessOperation);
	Handler.SetContractAvailability(ThisObject, Object, Object.Contract);
	
	CashServer.CheckFillInOrganizationSBankAccountByOwner(Object.Organization,
		Object.CompanyBankAccount, Undefined, Object.LineOfBusiness);
	
	FillInSubordinatePropertiesForStatistics("Organization");
	
	If DirectionsOfActivity <> Object.LineOfBusiness Then
		LineOfBusinessOnChangeServer();
	EndIf;
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	UpdateTextDocumentsBasedOn();
EndProcedure

&AtServer
Procedure ContractOnChangeServer()
	
	DirectionsOfActivity = Object.LineOfBusiness;
	
	BasisChanged = BasisChanged
						And ValueIsFilled(Object.Basis);
	
	Contract = Object.Contract;
	
	ContractDetails_ = New Structure("Currency, Department", "ARAPCurrency");
	Catalogs.CounterpartyContracts.FillInDocumentDetails(Object, Object.Contract, ContractDetails_);
	
	SalesServer.FillInBankAccountsUnderAgreement(Object.Contract,
		Object.CompanyBankAccount, Object.CounterpartyBankAccount);
	ResponsiblePersonsServer.FillInManager_(Object);
	FillInSubordinatePropertiesForStatistics("Contract");
	
	If UseLinesOfBusiness
		And Not Object.TransferByOrders Then
		
		LinesOfBusinessServer.FillInDefaultDirection(
				Object.LineOfBusiness,
				Object.Terms,
				Object.Contract);
		
		If DirectionsOfActivity <> Object.LineOfBusiness Then
			LineOfBusinessOnChangeServer();
		EndIf;
	
	EndIf;
	
	If DocumentCurrency <> Object.Currency Then
		WhenChangingCurrencyServer(Object.Currency, True);
	EndIf;
	
	FillBaseForPrinting();
	
	NewCommissionAgreement = ThisIsContractForNewCommission();
	If NewCommissionAgreement Then
		PriceTypeAccountingPriceType = ConsignmentSalesServer.TypeOfContractPrice(Object.Contract, True);
	Else
		PriceTypeAccountingPriceType = Catalogs.TypesOfPrices.EmptyRef();
	EndIf;
	
	SetLBEditingOption();
	
EndProcedure

&AtServer
Procedure WarehouseOnChangeServer(ClearLines_ = True, UntieAllLinesFromOrder = False)
	
	Warehouse       = Object.Warehouse;
	WarehouseGroup_ = ItIsGroupOfWarehousesAndWarehousesUsedByWHForSale(Object.BusinessOperation, Object.Warehouse);
	
	SetParametersForSelectingProductsWarehouse();
	
	If ClearLines_
		And Not WarehouseGroup_
		And Object.TransferByOrders
		And Object.Goods.Count() > 0 Then
		
		Object.Goods.Clear();
		
	EndIf;

	If UntieAllLinesFromOrder Then
		UnlinkFromOrderServer();
	EndIf;
	
	Items.GoodsFillInTheWarehouseInSelectedLines.Enabled = WarehouseGroup_;
	WarehousesServer.FillInWarehousesInTablePart(Object.Warehouse, WarehouseGroup_, Object.Goods, True);
	Handler = Documents.TransferOfGoodsToBailee.ActionHandler(Object.BusinessOperation);
	Handler.FillInShopPantryAttributeInTable(Object);
	UpdateOrderInformation();
	SetTitleFillInByOrdersOrders();
	WhenChangingWarehouseInTablePartServer();
	HowToSetSeriesVisibility();
	CalculateTotals_(ThisObject);
	
	StructureOfResponsible = SalesServer.GetWarehouseManager(Object.Warehouse);
	
	If StructureOfResponsible <> Undefined Then
		Object.IssuiedBy          = StructureOfResponsible.EmployeeResponsible;
		Object.IssuiedByJobTitle = StructureOfResponsible.ResponsiblePosition;
	EndIf;
	
	Items.GroupLabelAndPictureSeveralWarehouses.Visible = WarehouseGroup_;
	
EndProcedure

&AtServer
Procedure WhenChangingCurrencyServer(NewCurrency, RecalculateAmounts)
	
	If RecalculateAmounts Then
		ExecuteRecalculateDocumentAmountsServer(DocumentCurrency, NewCurrency);
	EndIf;
	
	DocumentCurrency = Object.Currency;
	
	DocumentDate = ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate());
	
	Object.LocalConversionRatio = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(Object.Currency,
																								LocalAccountingCurrency,
																								DocumentDate);
	
	FillInSubordinatePropertiesForStatistics("Currency");
	
EndProcedure

&AtServer
Procedure ContactPersonOnChangeServer(PartnerChanged_)
	
	OwnerOfContactPerson = Common.ObjectAttributeValue(Object.ContactPerson, "Owner");
	
	If OwnerOfContactPerson <> Object.Partner Then
		PartnerChanged_ = True;
		Object.Partner  = OwnerOfContactPerson;
		
		PartnerOnChangeServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure LineOfBusinessOnChangeServer()
	
	Changes = LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	
	For Each CurrentData In Changes Do
		FillInSenderSAssignment(Object.TransferByOrders, Object.BusinessOperation, CurrentData);
	EndDo;
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
EndProcedure

&AtServer
Procedure ToReturnReusablePackageOnChangeServer()
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	UpdateAvailabilityOfReturnContainerItems(ThisObject);
	
	FillInServiceDetailsForProductRange();
	CalculateTotals_(ThisObject);
	
EndProcedure

#EndRegion


#Region WorkingWithClipboard

&AtClient
Procedure SetAvailabilityOfClipboardCommandsOnClient()
	
	ItemArray = New Array();
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsContextMenuInsertRows");

	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled",
		Not Object.TransferByOrders Or TransferInExcessOfOrder);
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfClipboardCommands()
	
	ItemArray = New Array();
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsContextMenuInsertRows");

	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled",
		ProcessingOfTabularForms.ThereAreLinesInClipboard() And (Not Object.TransferByOrders Or TransferInExcessOfOrder));
	
EndProcedure

&AtServer
Procedure CopyLinesOnServer()
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object.Goods, Items.Goods.SelectedRows);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboard()
	
	FilterParameters = New Map;
	FilterParameters.Insert("Products.ItemsType", ProductsClientServer.SelectionByProductMultiTurnContainer());
	
	Columns =
		"Products,Characteristic,Package,NumberOfPackages,
		|PriceKind,Price,Warehouse,ProductsInSet,ItemVariantOfSet";
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("CheckFillWarehouse",
								BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object,
																												WarehouseGroup_));
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	
	ParametersForFillingInPriceType = BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceTypeInTSLine("PriceKind");
	ParametersForFillingInPriceType.FilterParameters.PriceIncludesVAT = False;
	ParametersForFillingInPriceType.FilterParameters.UseWhileSellingToCustomers = True;
	StructureOfActions.Insert("CheckFillInPriceView", ParametersForFillingInPriceType);
	
	StructureOfActions.Insert("FillInSalePrice",
		BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	
	RowsToProcess = New Array;
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		
		FillPropertyValues(CurrentRow, RowOfProduct);
		FillInSenderSAssignment(Object.TransferByOrders, Object.BusinessOperation, CurrentRow);
		UpdateOrderDeviationsInLine(CurrentRow, Object.TransferByOrders);
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods);
		
	For Each CurrentRow In RowsToProcess Do
		FillInSenderSAssignment(Object.TransferByOrders, Object.BusinessOperation, CurrentRow);
	EndDo;
	
	FillInServiceDetailsForProductRange();
	WhenChangingWarehouseInTablePartServer();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

#EndRegion

#Region BarcodesAndTradeEquipment

&AtClient
Procedure ProcessBarcodes(BarcodeData_5)
	
	ClearMessages();
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
		Return;
	EndIf;
	
	FillInArticleAttribute         = New Structure("Products", "SKU");
	FillInProductTypeAttribute_ = New Structure("Products", "ItemsType");
	
	CheckFillWarehouse = BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object,
								WarehouseGroup_);
	
	StructureOfActionsWithAddedStrings = New Structure;
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute",         FillInArticleAttribute);
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", FillInProductTypeAttribute_);
	
	StructureOfActionsWithAddedStrings.Insert("FillInNoReturnContainerAttribute",
													Object.ToReturnReusablePackage);
	
	StructureOfActionsWithAddedStrings.Insert("CheckFillWarehouse", CheckFillWarehouse);
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithAddedStrings, Object);
	AddPriceFillingActionsToStructure(StructureOfActionsWithAddedStrings, Object,
		ToUseTermsOfSales, UsePriceManagementSystem25, NewCommissionAgreement);
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject,
		StructureOfActionsWithAddedStrings);
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Products", StructureOfActionsWithAddedStrings);
	
	StructureOfActionsWithModifiedStrings = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithModifiedStrings, Object);
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	StructureOfActions.SeriesSpecificationParameters                 = SeriesSpecificationParameters;
	StructureOfActions.GoodsOnly                           = True;
	StructureOfActions.CalculateSets                     = True;
	StructureOfActions.AddOnlyProductsOverAndAboveOrder        = True;
	
	ProcessBarcodesServer(StructureOfActions, CachedValues);
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(StructureOfActions, CachedValues, ThisObject);
	
	OpenSeriesIndicationForm = BarcodingOfItemsClient.YouNeedToOpenFormForSpecifyingSeriesAfterProcessingBarcodes(
								StructureOfActions);
	
	If OpenSeriesIndicationForm Then
		CurDataId = StructureOfActions.ArrayOfRowsWithSeries_[0];
		
		AttachIdleHandler("OpenSeriesSelectionWhenScanningProductBarCode", 0.1, True);
	EndIf;
	
	CalculateTotals_(ThisObject);
	
	If StructureOfActions.CurrentRow <> Undefined Then
		Items.Goods.CurrentRow = StructureOfActions.CurrentRow;
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessBarcodesServer(StructureOfActionParameters, CachedValues)
	
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject, Object, StructureOfActionParameters, CachedValues);
	UpdateOrderDeviations();
	UpdateDependentDetailsOfServerByOrderForm();
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
EndProcedure

#EndRegion

#Region Sets

&AtServer
Procedure AtEndOfEditingSet(AddressInTempStorage)
	
	Data = GetFromTempStorage(AddressInTempStorage);
	
	StructureOfActionsWithModifiedStrings = New Structure;
	StructureOfActionsWithModifiedStrings.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	FillInArticleAttribute                    = New Structure("Products", "SKU");
	FillInProductTypeAttribute_            = New Structure("Products", "ItemsType");
	FillInFeatureAttribute = New Structure("Products", "ItemVariantsAreUsed");
	
	CheckFillWarehouse = BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object,
								WarehouseGroup_);
	
	StructureOfActionsWithAddedStrings = Common.CopyRecursive(
		StructureOfActionsWithModifiedStrings);
	
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute",         FillInArticleAttribute);
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", FillInProductTypeAttribute_);
	StructureOfActionsWithAddedStrings.Insert("FillInFeatureAttribute",
													FillInFeatureAttribute);
	
	StructureOfActionsWithAddedStrings.Insert("CheckFillWarehouse", CheckFillWarehouse);
	StructureOfActionsWithAddedStrings.Insert("FillInNoReturnContainerAttribute",
													Object.ToReturnReusablePackage);
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Products", StructureOfActionsWithAddedStrings);
	
	DataParameters = New Structure;
	DataParameters.Insert("Data",                                 Data);
	DataParameters.Insert("StructureOfActionsWithModifiedStrings",  StructureOfActionsWithModifiedStrings);
	DataParameters.Insert("StructureOfActionsWithAddedStrings", StructureOfActionsWithAddedStrings);
	DataParameters.Insert("ExceedingOrder",                            True);
	DataParameters.Insert("DialColumns",                          DialColumns(ThisObject));
	
	SetsServer.AtEndOfEditingSet(ThisObject, "Goods", DataParameters);
	
	UpdateOrderDeviations();
	CalculateTotals_(ThisObject);
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
EndProcedure

&AtClientAtServerNoContext
Function DialColumns(Form)
	
	Columns = New Array;
	Columns.Add("Products");
	Columns.Add("Characteristic");
	Columns.Add("Package");
	Columns.Add("Count");
	Columns.Add("NumberOfPackages");
	Columns.Add("PriceKind");
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
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtServer
Procedure WhenRemovingComponentsOnServer(TSName, AdditionalParameter)
	
	SetsServer.WhenRemovingComponents(ThisObject, TSName, AdditionalParameter);
	
EndProcedure

#EndRegion

#Region SelectionAndProcessingOfQuantityVerification

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected)
	
	TableOfGoods       = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array();
	
	ListOfProperties = "ProductsInSet, Products, Characteristic, ItemVariantOfSet, Package, Series, 
					|NumberOfPackages, PriceKind, Price, DeliveryPeriodDays, WithAssignment";
	
	If ValueIsFilled(Object.Warehouse) Then
		ListOfProperties = ListOfProperties + ", Warehouse";
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct, ListOfProperties);
		LinesOfBusinessClientServer.FillAssignmentByFlagSeparately(ThisObject, CurrentRow);
		FillInSenderSAssignment(Object.TransferByOrders, Object.BusinessOperation, CurrentRow);
		
		UpdateOrderDeviationsInLine(CurrentRow, Object.TransferByOrders);
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
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	CalculateTotals_(ThisObject);
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
EndProcedure

&AtServer
Procedure ProcessingProductSelectionFromOrder(GoodsAddressInStorage)
	
	SearchStructureForOrderItems    = New Structure("SalesOrder, RowCode");
	StructureOfSearchForGoodsWaybill = New Structure("LineNumber");
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActions = New Structure;
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Products", StructureOfActions);
	AddFillInActionForShopPantryAttribute(Object.BusinessOperation, StructureOfActions, True);
	Result = GetFromTempStorage(GoodsAddressInStorage); // DocumentTabularSection.TransferOfGoodsToBailee.Goods
	
	RowsToProcess = New Array();
	SelectedGoods = Result.Goods;
	
	For Each RowOfGoods In SelectedGoods Do
		
		// PM goods processing.
		If RowOfGoods.RowCode <> 0
			And ValueIsFilled(RowOfGoods.SalesOrder) Then
			
			SearchStructureForOrderItems.RowCode    = RowOfGoods.RowCode;
			SearchStructureForOrderItems.SalesOrder = RowOfGoods.SalesOrder;
			
			ArrayOfTSRows = Object.Goods.FindRows(SearchStructureForOrderItems);
			
		Else
			StructureOfSearchForGoodsWaybill.LineNumber = RowOfGoods.LineNumber;
			
			ArrayOfTSRows = Object.Goods.FindRows(StructureOfSearchForGoodsWaybill);
		EndIf;
		
		If ArrayOfTSRows.Count() = 0 Then
			StringTSGoods = Object.Goods.Add();
		ElsIf ArrayOfTSRows.Count() = 1 Then
			StringTSGoods = ArrayOfTSRows[0];
		ElsIf ArrayOfTSRows.Count() > 1 Then
			
			For Each RowToDelete In ArrayOfTSRows Do
				Object.Goods.Delete(RowToDelete);
			EndDo;
			
			StringTSGoods = Object.Goods.Add();
			
		EndIf;
		
		FillPropertyValues(StringTSGoods, RowOfGoods);
		FillInSenderSAssignment(Object.TransferByOrders, Object.BusinessOperation, StringTSGoods);
		
		If Not UseTransferForSeveralOrders
			And ValueIsFilled(StringTSGoods.SalesOrder)
			And Object.SalesOrder <> StringTSGoods.SalesOrder Then
			
			Object.SalesOrder = StringTSGoods.SalesOrder;
			
		EndIf;
		
		StringTSGoods.SetIndex = ?(ValueIsFilled(StringTSGoods.ProductsInSet), 1, 0);
		RowsToProcess.Add(StringTSGoods);
		
	EndDo;
	
	If StructureOfActions.Count() Then
		
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			RowsToProcess,
			StructureOfActions,
			Object.Goods,
			CachedValues);
		
	EndIf;
	
	UpdateOrderInformation();
	
	Object.TransferByOrders =
		ValueIsFilled(Object.SalesOrder)
		Or OrderList.Count() > 0;
	
	UpdateOrderDeviations();
	FillInServiceDetailsForProductRange();
	WhenChangingWarehouseInTablePartServer();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, Object.ToReturnReusablePackage);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	SetElementProperties();
	CalculateTotals_(ThisObject);

	If Object.TransferByOrders Then
		For Each String In Object.Goods Do
			If String.RowCode = 0 Then
				String.Purpose            = Catalogs.Assignments.EmptyRef();
				String.AssignmentSender = Catalogs.Assignments.EmptyRef();
			EndIf;
		EndDo;
	EndIf;
	GoodsDelivery.WhenChangingFlagForOrders(Items, Object, Object.TransferByOrders);
	LinesOfBusinessServer.SetVisibilityOfElementsSeparately(ThisObject);
	LinesOfBusinessServer.ReFillInServiceDetailsOfTablePart(ThisObject);
	
	SalesServerLocalization.TransferBarcodesOfPackages(ThisObject, Result.PackageBarcodes);
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
EndProcedure

&AtClient
Procedure AddItemsFromSalesOrderGoodsIssue()
	
	Try
		Modified = True;
		
		LockFormDataForEdit();
	Except
		ShowMessageBox(, ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		
		Return;
	EndTry;
	
	AddressOfGoods     = "";
	FormCaption   = "";
	ArrayOfStringCodes = New Array;
	
	BeforeSelectingProductsFromOrder(ArrayOfStringCodes, AddressOfGoods, FormCaption);
	
	PickingParameters = New Structure(
		"SalesOrder,
		|Date,
		|Partner,
		|Counterparty,
		|Terms,
		|BusinessOperation,
		|Organization,
		|Contract,
		|Warehouse,
		|SalesOpportunity,
		|LineOfBusiness,
		|ToReturnReusablePackage");
	FillPropertyValues(PickingParameters, Object);
	
	PickingParameters.Insert("Document",                 Object.Ref);
	PickingParameters.Insert("BusinessOperation",    Object.BusinessOperation);
	PickingParameters.Insert("TransferByOrders",        Object.TransferByOrders);
	PickingParameters.Insert("DocumentCurrency",          Object.Currency);
	PickingParameters.Insert("ArrayOfStringCodes",         ArrayOfStringCodes);
	PickingParameters.Insert("AdvancedWarehousingOnShipment", AdvancedWarehousingOnShipment);
	PickingParameters.Insert("AddressOfGoodsToTransferInTemporaryStorage", AddressOfGoods);
	PickingParameters.Insert("Title",                FormCaption);
	
	OpenForm("Document.TransferOfGoodsToBailee.Form.SelectionOfGoodsFromOrderForm", PickingParameters, ThisObject, , , ,
		Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtServer
Function PutTablePartOfGoodsInTemporaryStorageToCheckQuantity()
	
	GroupColumns =
		"SalesOrder,
		|RowCode,
		|ProductsInSet,
		|ItemVariantOfSet,
		|Products,
		|ItemsType,
		|Characteristic,
		|ItemVariantsAreUsed,
		|Package,
		|Series,
		|BatchesIndicationStatus,
		|Warehouse";
	
	UnloadedColumns = GroupColumns + ", NumberOfPackages";
	
	TabularPartProducts = Object.Goods.Unload(, UnloadedColumns);
	TabularPartProducts.GroupBy(GroupColumns, "NumberOfPackages");
	
	AddressInTempStorage = PutToTempStorage(TabularPartProducts, UUID);
	
	Return AddressInTempStorage;
	
EndFunction

&AtServer
Procedure ChangeTablePartBasedOnResultsOfCheck(ReturnParameters, CachedValues)
	
	GoodsTable   = GetFromTempStorage(ReturnParameters.Goods);
	RowsToProcess = New Array;
	ProcessedLinesAreNew = New Array;
	LinesToDelete = New Array;
	
	SelectionColumns =
		"SalesOrder,
		|RowCode,
		|ProductsInSet,
		|ItemVariantOfSet,
		|Products,
		|Characteristic,
		|ItemVariantsAreUsed,
		|Package,
		|Series";
	
	For Each SourceRow In GoodsTable Do
		
		Filter = New Structure(SelectionColumns);
		FillPropertyValues(Filter, SourceRow);
		
		FoundRows = Object.Goods.FindRows(Filter);
		
		For Each TSRow In FoundRows Do
			
			If SourceRow.NumberOfPackages = 0 Then
				Break;
			EndIf;
			
			If SourceRow.NumberOfPackages >= 0 Then
				
				TSRow.NumberOfPackages       = TSRow.NumberOfPackages + SourceRow.NumberOfPackages;
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
				
				RowsToProcess.Add(TSRow);
				
			EndIf;
			
		EndDo;
		
		If FoundRows.Count() = 0 Then
			
			TSRow = Object.Goods.Add();
			FillPropertyValues(TSRow, SourceRow);
			FillInSenderSAssignment(Object.TransferByOrders, Object.BusinessOperation, TSRow);
			
			UpdateOrderDeviationsInLine(TSRow, Object.TransferByOrders);
			
			ProcessedLinesAreNew.Add(TSRow);
			
		EndIf;
		
	EndDo;

	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);

	FillIn_TermsOfSales  = BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object);
	CheckFillWarehouse = BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object,
		WarehouseGroup_);

	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillIn_TermsOfSales",  FillIn_TermsOfSales);
	StructureOfActions.Insert("CheckFillWarehouse", CheckFillWarehouse);

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ProcessedLinesAreNew,
		StructureOfActions,
		Object.Goods,
		CachedValues);

	For Each TSRow In LinesToDelete Do
		Object.Goods.Delete(TSRow);
	EndDo;
	
	FillInServiceDetailsForProductRange();
	WhenChangingWarehouseInTablePartServer();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
EndProcedure

#EndRegion

#Region PriceManagementSystem

&AtServer
Function FillThePricesByTermsOfSalesServer(OnAllLines = False, ConsiderLinesOverAndAboveOrder = True, UpdateDataOnContract = False)
	
	If OnAllLines Then
		If TransferInExcessOfOrder And ConsiderLinesOverAndAboveOrder Then
			FilterParameters = New Structure("RowCode", 0);
			RowsArray     = Object.Goods.FindRows(FilterParameters);
		Else
			RowsArray = Undefined;
		EndIf;
	Else
		
		RowsArray = New Array;
		
		For Each String In Items.Goods.SelectedRows Do
			
			FoundRow = Object.Goods.FindByID(String);
			
			If (TransferInExcessOfOrder
					And FoundRow.RowCode = 0)
				Or VarianceFromTransferConditions Then
				
				RowsArray.Add(FoundRow);
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	SetsServerCall.AddToFullSet(Object.Goods, RowsArray, True);
	
	FillParameters = New Structure();
	FillParameters.Insert("Date",                      Object.Date);
	FillParameters.Insert("Partner",                   Object.Partner);
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
		And UpdateDataOnContract Then
		FillParameters.Insert("PriceKind", Common.ObjectAttributeValue(Object.Contract,"PriceTypeAccountingPriceType"));
	Else
		FillParameters.Insert("Terms", Object.Terms);
	EndIf;
	FillParameters.Insert("Organization",               Object.Organization);
	FillParameters.Insert("Currency",                    Object.Currency);
	FillParameters.Insert("ToReturnReusablePackage", Object.ToReturnReusablePackage);
	FillParameters.Insert("CalculateSets",        True);
	FillParameters.Insert("PopulationFields",            "PriceKind, Price, DeliveryPeriodDays");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	
	PricesCalculated = EnterprisePricesFillingServer.FillInPrices(Object.Goods, RowsArray, FillParameters, StructureOfActions);
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	
	CalculateTotals_(ThisObject);
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Function FillInPricesOfSelectedRowsByPriceTypeServer(PricesKind)
	
	RowsArray = New Array;
	
	For Each CurRow In Items.Goods.SelectedRows Do
		
		FoundRow = Object.Goods.FindByID(CurRow);
		
		If VarianceFromTransferConditions
			Or (TransferInExcessOfOrder
				And FoundRow.RowCode = 0) Then
			
			RowsArray.Add(FoundRow);
			
		EndIf;
		
	EndDo;
	
	SetsServerCall.AddToFullSet(Object.Goods, RowsArray, True);
	
	FillParameters = New Structure();
	FillParameters.Insert("Date",    Object.Date);
	FillParameters.Insert("Organization", Object.Organization);
	FillParameters.Insert("Currency",  Object.Currency);
	FillParameters.Insert("PriceKind", PricesKind);
	
	FillParameters.Insert("CalculateSets", True);
	
	FillParameters.Insert("PopulationFields", "Price, PriceKind");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	
	PricesCalculated = EnterprisePricesFillingServer.FillInPrices(Object.Goods, RowsArray, FillParameters, StructureOfActions);
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	
	CalculateTotals_(ThisObject);
	
	Return PricesCalculated;
	
EndFunction

#EndRegion

#Region SetOfSeries

&AtServer
Function SeriesSpecificationParameters()
	
	ObjectManager = Documents.TransferOfGoodsToBailee;
	
	Return New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, ObjectManager));
	
EndFunction

&AtServer
Procedure SetVisibilityOfSeriesElements()
	
	Items.GoodsSeries.Visible                = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsSpecifySeries.Visible         = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsBatchesIndicationStatus.Visible  = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsFillInSeriesByFEFO.Visible = SeriesSpecificationParameters.UseItemsBatch;
	
EndProcedure

&AtServer
Procedure HowToSetSeriesVisibility()
	
	SeriesSpecificationParameters = SeriesSpecificationParameters();
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	SetVisibilityOfSeriesElements();
	
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
	
	NeedServerCall = ProductsClient.YouNeedServerCallToSpecifySeries(ThisObject,
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
		AdditionalParameters     = New Structure("ParametersOfSeriesIndicationForm", ParametersOfSeriesIndicationForm);
		CallbackDescription          = New CallbackDescription("OpenSelectionOfSeriesCompletion",
																ThisObject,
																AdditionalParameters);
		
		OpenForm(ParametersOfSeriesIndicationForm.FormName, ParametersOfSeriesIndicationForm, ThisObject, , , , CallbackDescription,
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
	
	ProductsServer.ProcessSeriesIndication_(Object, SeriesSpecificationParameters, ParametersOfSeriesIndicationForm);
	
EndProcedure

&AtServer
Procedure FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow,
																			CachedValues)
	
	ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Object, SeriesSpecificationParameters,
		IDCurrentRow, CachedValues);
	
EndProcedure

&AtServer
Function ThereAreFilledSeriesByFEFO()
	
	Return ProductsServer.ThereAreLinesWithFEFOFilledSeries(Object.Goods);
	
EndFunction

&AtServer
Function FillInSeriesByFEFOServer()
	
	If ProductsServer.ThereAreLinesWithFEFOFilledSeries_(Object.Goods) Then
		ProductsServer.FillInSeriesByFEFO(Object, SeriesSpecificationParameters);
		FormEvents.WhenChangingElement(ThisObject, "Goods");
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

#EndRegion

#Region Supply

&AtClientAtServerNoContext
Procedure FillInSenderSAssignment(TransferByOrders, BusinessOperation, CurrentData)
	
	If BusinessOperation =
				PredefinedValue("Enum.BusinessTransactions.TransferToStorageWithRightOfSale")
		Or Not ValueIsFilled(CurrentData.SalesOrder)
		Or CurrentData.RowCode = 0 Then
		CurrentData.AssignmentSender = CurrentData.Purpose;
	EndIf;
	
EndProcedure

#EndRegion

#Region Delivery

&AtServer
Procedure SpecialTransportationConditionsOnChangeServer()
	
	GoodsDelivery.SpecialTransportationConditionsOnChange(Items, Object);
	
EndProcedure

&AtServer
Procedure SupplementDeliveryInformationWithContactsServer()
	
	GoodsDelivery.SupplementDeliveryInformationWithContacts(Object);
	
EndProcedure

&AtServer
Procedure FillInAndSetDeliveryAttributesServer(FormItemName);
	
	GoodsDelivery.FillInDeliveryDetails(Items, FormItemName, Object);
	
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

#Region Goods

&AtServer
Procedure GoodsAtEndOfEditingOnServer(UpdateGoods, IDCurrentRow, CachedValues)
	
	If UpdateGoods Then
		FormEvents.WhenChangingElement(ThisObject, "Goods");
	EndIf;
	
	If IDCurrentRow <> Undefined Then
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues);
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure SetUncheckSeparately(Set)
	LinesOfBusinessServer.SetUncheckSeparately(ThisObject, Set);
EndProcedure

&AtClient
Procedure EnableWaitingHandlerReceivingCarriers()
		
	If BackgroundTaskData.Property("JobID") Then
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = False;
		CallbackOnCompletion = New CallbackDescription("UpdateListOfCarriersNotification", ThisObject);
		
		TimeConsumingOperationsClient.WaitCompletion(
			BackgroundTaskData, CallbackOnCompletion, IdleParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateListOfCarriersNotification(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		GoodsDeliveryClient.UpdateListOfCarriers(Items.CarrierPartner.ChoiceList, Result);
		RefreshDataRepresentation(Items.CarrierPartner);
		BackgroundTaskData = New Structure;
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_CloseForm()
	
	If IsOpen() Then
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
EndProcedure


&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Setting the conditional design for the 'Warehouse' element
	WarehousesServer.SetConditionalAppearanceOfWarehouseInHeader(ThisObject);
	
	// Setting the conditional design for the items of the nomenclature of the tabular part 'Goods'
	SetsServer.SetConditionalAppearance(ThisObject, "Goods");
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject);
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisObject,
		"SeriesWhenPlanningShipmentWHGoodsAreIndicated");
	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisObject, False);
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject);
	
	// Setting the conditional design for the 'Packaging' and 'View Price' elements of the 'Products' tabular part
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPackage.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPriceKind.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TransferInExcessOfOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("VarianceFromTransferConditions");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	FilterGroup3 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup3.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TransferInExcessOfOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("VarianceFromTransferConditions");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//

	LinesOfBusinessServer.SetConditionalAppearanceOfFlagSeparately(ThisObject);

	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPackage.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPriceKind.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter =FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TransferInExcessOfOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("VarianceFromTransferConditions");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("ReadOnly", False);
	
	// Setting the conditional design for the 'Price' element of the 'Products' tabular part
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPrice.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("VarianceFromTransferConditions");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PriceKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// Setting the conditional design for the 'Amount' element of the 'Products' tabular part
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSum.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("VarianceFromTransferConditions");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SalesOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TransferInExcessOfOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PriceKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	FilterGroup3 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup3.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("VarianceFromTransferConditions");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SalesOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TransferInExcessOfOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// Setting the conditional design for the VAT accounting elements of the "Goods" tabular part
	EnterprisePricesFillingServer.EstablishConditionalAppearanceOfPriceTypes(ThisObject);
	
	// Setting the conditional design for the 'Warehouse' element of the 'Goods' tabular part
	WarehousesServer.SetConditionalAppearanceOfVTCHWarehouse(ThisObject);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsWarehouse.Name);
	
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	ValueList.Add(Enums.ItemsTypes.ReusablePackage);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = ValueList;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Warehouse");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	
	ConditionalDesignParameters = WarehousesServer.ParametersOfConditionalAppearanceOfVHFWarehouseByItemType();
	ConditionalDesignParameters.Form = ThisObject;
	WarehousesServer.SetConditionalAppearanceOfVHFWarehouseByTypeOfItem(ConditionalDesignParameters);
	
	// Setting the conditional design for the 'Code Line' element of the 'Products' tabular part
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsRowCode.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SalesOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// Setting the conditional design for the "Customer's Order" element of the "Products" tabular part
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSalesOrder.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseTransferForSeveralOrders");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSalesOrder.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SalesOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.TransferByOrders");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSalesOrder.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.SalesOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSalesOrder.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.SalesOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSalesOrder.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.SalesOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SalesOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ErrorNoteText);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Vượt quá trên đơn hàng, chưa chọn đơn hàng';
													|ru = 'Сверх заказа, заказ не выбран';
													|en = 'In excess of the order, the order is not selected'; fa = 'In excess of the order, the order is not selected';
													|it = 'Oltre all''ordine, l''ordine non è selezionato';
													|pl = 'Przewyższa zamówienie, zamówienie nie wybrane';
													|tr = 'Sipariş fazlası, sipariş seçilmedi'"));
	
	// Setting the conditional design for the elements of the rows of the multi-turn packaging of the tabular part 'Goods'
	InstallationParameters = ReusablePackageServer.ParametersForSettingConditionalAppearanceForLinesWithMultiTurnContainers();
	InstallationParameters.Form          = ThisObject;
	InstallationParameters.ThisIsAdmission = False;
	InstallationParameters.ThisIsTransfer = True;
	InstallationParameters.NameOfVATRateField = "";
	
	ReusablePackageServer.SetConditionalAppearanceForLinesWithMultiTurnContainers(InstallationParameters);
	
	// Setting the conditional design for the 'Division' element
	InventoriesServer.EstablishConditionalAppearanceOfDivisionForTypesOfStocks(ThisObject);
	
	// Setting the conditional design for the 'Activity Direction' element
	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisObject);
	
	// Setting Destination Availability
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPurpose.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.SalesOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	Documents.TransferOfGoodsToBailee.ConfigureBusinessTransactionDetails(ThisObject, Object);
	
	Handler = Documents.TransferOfGoodsToBailee.ActionHandler(Object.BusinessOperation);
	
	UseSalesOrders              = Handler.UseSalesOrders();
	UseTransferForSeveralOrders = Handler.UseSaleByMultipleOrders();
	
	TransferInExcessOfOrder         = Handler.SalesInExcessOfOrder();
	VarianceFromTransferConditions = Handler.VarianceFromSalesTermsAndConditions();
	
	UsePartnersAsCounterparties = GetFunctionalOption("UsePartnersAsCounterparties");
	ToUseTermsOfSales     = Handler.CustomerAgreementsAreApplicable()
										   And Handler.ToUseTermsOfSales();
	
	UsePriceManagementSystem25        = PriceManagementSystemServerCall.UsePriceManagementSystem25();
	UseLinesOfBusiness  = GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness");
	
	Contract                        = Object.Contract;
	Warehouse                          = Object.Warehouse;
	WarehouseGroup_                    = ItIsGroupOfWarehousesAndWarehousesUsedByWHForSale(Object.BusinessOperation, Object.Warehouse);
	DocumentCurrency                = Object.Currency;
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	BasisChanged              = False;
	SeriesSpecificationParameters         = SeriesSpecificationParameters();
	BusinessTransactionBeforeTheChange = Object.BusinessOperation;
	ConsignmentSales25          = ?(Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent,
		True, False);
	
	LinesOfBusinessServer.OnReadCreateAtServer(ThisObject);
	SetLBEditingOption();
	
	Handler.AdjustItemSelectionSettings(ThisObject, Object);	
	Handler.CustomizeForm(ThisObject, Object.Number, Object.Date);
	
	UpdateOrderInformation();
	SetDefaultPriceView();
	ThereIsSpendingOrderForShippingOrders(Object.Ref, ShipmentStarted);
	
	If Not UseSalesOrders Then
		Items.GroupDiscrepancyOnOrder.Visible = False;
		Items.GroupDiscrepancyOnOrders.Visible = False;
	EndIf;
	
	SetVisibilityOfShipmentBanToPartner();
	
	Handler.SetContractAvailability(ThisObject, Object);
	
	Items.GoodsFillInTheWarehouseInSelectedLines.Enabled = WarehouseGroup_;
	Items.GroupLabelAndPictureSeveralWarehouses.Visible   = WarehouseGroup_;
	
	SetVisibilityOfSeriesElements();
	SetParametersForSelectingProductsWarehouse();
	SetTitleFillInByOrdersOrders();
	Handler.FillInShopPantryAttributeInTable(Object);
	UpdateOrderDeviations();
	FillInServiceDetailsForProductRange();
	WhenChangingWarehouseInTablePartServer();
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, Object.ToReturnReusablePackage);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateTotals_(ThisObject);
	FillOperationSelectionList();
	
	BackgroundTaskData = GoodsDelivery.WhenReadingCreatingOrdersOnServer(Items, Object, Object.TransferByOrders,,, True);
	
	CurrentDeliveryMethod = Object.DeliveryMethod;
	
	If AccessRight("Update", Metadata.Documents.TransferOfGoodsToBailee) Then
		
		PrintBasisTable.Load(Handler.PrintBasisTable(Object));
		
		If ValueIsFilled(Object.Basis) Then
			
			BaseStructure = Handler.StructureOfBaseForPrinting(Object);
			BasisChanged  = (TrimAll(Object.Basis) <> BaseStructure.Basis)
									Or (TrimAll(Object.BaseDocumentNumber) <> BaseStructure.BaseDocumentNumber)
									Or (Object.ReferenceDocumentDateForPrintForms <> BaseStructure.ReferenceDocumentDateForPrintForms);
			
		EndIf;
		
	EndIf;
	
	SetElementProperties();
	UpdateAvailabilityOfReturnContainerItems(ThisObject);
	
	ProcessingOfTabularForms.InitializeRowCache(Items.Goods);
	
	UpdateTextDocumentsBasedOn();
	
	NewCommissionAgreement = ThisIsContractForNewCommission();
	If NewCommissionAgreement Then
		PriceTypeAccountingPriceType = ConsignmentSalesServer.TypeOfContractPrice(Object.Contract, True);
	Else
		PriceTypeAccountingPriceType = Catalogs.TypesOfPrices.EmptyRef();
	EndIf;
	
	Items.TareGroup.Visible = Object.ToReturnReusablePackage;
	
	SetVisibilityOfGoodsDestinationFormElement();
	
EndProcedure

&AtServerNoContext
Function ItIsGroupOfWarehousesAndWarehousesUsedByWHForSale(BusinessOperation, Warehouse)
	
	Handler = Documents.TransferOfGoodsToBailee.ActionHandler(BusinessOperation);
	
	Return Handler.ItIsGroupOfWarehousesAndWarehousesUsedByWHForSale(Warehouse);
	
EndFunction

&AtServer
Procedure UpdateOrderInformation()
	
	ParametersOfUpdate = OrdersServer.ParametersForUpdatingOrderInformationInForm();
	ParametersOfUpdate.PropsNameOrderList         = "OrderList";
	ParametersOfUpdate.OrderPathInHeader                  = "Object.SalesOrder";
	ParametersOfUpdate.TitleLabelName               = "HeaderOrdersText";
	ParametersOfUpdate.NameOfColumnGroupInTableSection   = "GoodsGroupSalesOrder";
	ParametersOfUpdate.OrderNameInTablePart          = "SalesOrder";
	ParametersOfUpdate.UseOrdersInTabularSection = True;
	ParametersOfUpdate.OrdersUse                = UseSalesOrders;
	
	OrdersServer.UpdateOrderInformationInForm(ThisObject, Object.Goods, ParametersOfUpdate);
	
	UseAdvancedFeaturesOfSalesOrder = UseAdvancedFeaturesOfSalesOrder();

EndProcedure

&AtServer
Procedure SetDefaultPriceView()
	
	If Not ToUseTermsOfSales Then
		PriceTypeSelectionParameters = SettingsValueCached.ParametersForSelectingDefaultPriceType();
		PriceTypeSelectionParameters.UseWhileSellingToCustomers = True;
		PriceTypeSelectionParameters.Status                 = Enums.StatusesOfPriceTypeValidity.Valid;
		
		DefaultPriceType = SettingsValueCached.DefaultPriceType(PriceTypeSelectionParameters);
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure ThereIsSpendingOrderForShippingOrders(Ref, ShipmentStarted)
	
	ShipmentStarted = InvoicesServer.ThereIsSpendingOrderForShippingOrders(Ref);
	
EndProcedure

&AtServer
Procedure SetVisibilityOfShipmentBanToPartner()
	
	SegmentsServer.SetVisibilityOfShipmentBanToPartner(Object.Partner, Items);
	
EndProcedure

&AtServer
Procedure SetVisibilityOfGoodsDestinationFormElement()
	
	DisplayElement = Object.BusinessOperation <> Enums.BusinessTransactions.TransferToCommissionAgent
		And Object.BusinessOperation <> Enums.BusinessTransactions.TransferToStorageWithRightOfSale;
	
	Items.GoodsPurpose.Visible = DisplayElement;
	
EndProcedure

&AtServer
Procedure SetParametersForSelectingProductsWarehouse()
	
	GoodsWarehouse                 = Items.GoodsWarehouse;
	ParameterValue           = WarehouseSelectionData(Object.Warehouse);
	GoodsWarehouse.ChoiceParameters = New FixedArray(New Array);
	
	TMCommonUseClientServer.AddSelectionParameter(GoodsWarehouse, "Ref", ParameterValue);
	
EndProcedure

&AtServer
Procedure SetTitleFillInByOrdersOrders()
	
	WarehouseArray            = Object.Goods.Unload(, "Warehouse").UnloadColumn("Warehouse");
	AdvancedWarehousingOnShipment = WarehousesServer.ThereIsOrderWarehouseForShipment(WarehouseArray, Object.Date, Object.Warehouse);
	
	If Not AdvancedWarehousingOnShipment
		And UseSalesOrders
		And Not UseTransferForSeveralOrders Then
		
		TitleFillIn = NStr("vi = 'Chọn hàng hóa từ đơn hàng';
							|ru = 'Подобрать товары из заказа';
							|en = 'Pick goods from order'; fa = 'انتخاب کالاها از سفارش';
							|it = 'Selezionare le merci dall''ordine';
							|pl = 'Dobierz wiersze pozycji i zamówienia';
							|tr = 'Siparişten mal seçme'");
		
	ElsIf Not AdvancedWarehousingOnShipment
		And UseSalesOrders
		And UseTransferForSeveralOrders Then
		
		TitleFillIn = NStr("vi = 'Chọn hàng hóa từ đơn hàng';
							|ru = 'Подобрать товары из заказов';
							|en = 'Pick goods from orders'; fa = 'Pick goods from orders';
							|it = 'Selezionare le merci dagli ordini';
							|pl = 'Dobierz wiersze pozycji z zamówienia';
							|tr = 'Siparişlerden mal seçme'");
		
	ElsIf AdvancedWarehousingOnShipment
		And Not UseSalesOrders Then
		
		TitleFillIn = NStr("vi = 'Chọn hàng hóa theo lệnh';
							|ru = 'Подобрать товары по ордерам';
							|en = 'Pick goods by notes'; fa = 'انتخاب کالا بر اساس حواله‌ها';
							|it = 'Selezionare le merci in base ai mandati';
							|pl = 'Wybierz wiersze pozycji wg zleceń';
							|tr = 'Emirlere göre mal seçme'");
		
	Else
		TitleFillIn = NStr("vi = 'Chọn hàng hóa theo đơn hàng/phiếu kho';
							|ru = 'Подобрать товары по заказам/ордерам';
							|en = 'Pick by Order/Goods issue'; fa = 'انتخاب بر اساس سفارش/صدور کالا';
							|it = 'Seleziona le merci in base agli ordini/mandati';
							|pl = 'Wybierz wiersze pozycji wg zamówień/zleceń';
							|tr = 'Siparişe/emre ilişkin mal seçme'");
	EndIf;
	
	Items.GoodsSelectGoodsByOrdersNotes.Title = TitleFillIn;
	
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

&AtServer
Procedure UpdateOrderDeviations()
	
	For Each CurRow In Object.Goods Do
		UpdateOrderDeviationsInLine(CurRow, Object.TransferByOrders);
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateOrderDeviationsInLine(CurrentRow, TransferByOrders)
	
	If TransferByOrders Then
		If CurrentRow.RowCode = 0 Then
			CurrentRow.OrderDiscrepancy_3 = 1;
		Else
			CurrentRow.OrderDiscrepancy_3 = 0;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsForProductRange()
	
	FillInArticleAttribute                    = New Structure("Products", "SKU");
	FillInProductTypeAttribute_            = New Structure("Products", "ItemsType");
	FillInFeatureAttribute = New Structure("Products", "ItemVariantsAreUsed");
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInArticleAttribute",         FillInArticleAttribute);
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_", FillInProductTypeAttribute_);
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute",
											FillInFeatureAttribute);
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Products", ParametersForFillingInBankingDetails);
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, ParametersForFillingInBankingDetails);
	
	SetsServer.FillInServiceDetails(ThisObject);
	
EndProcedure

&AtServer
Procedure WhenChangingWarehouseInTablePartServer()
	
	WarehousesServer.WhenChangingWarehouseInTablePart(Object.Goods, WarehouseTable, WarehouseGroup_, False);
	
	TotalWarehouses_             = WarehouseTable.Count();
	TableWarehouses            = Object.Goods.Unload(, "Warehouse").UnloadColumn("Warehouse");
	AdvancedWarehousingOnShipment = WarehousesServer.ThereIsOrderWarehouseForShipment(TableWarehouses, Object.Date, Object.Warehouse);
	
	UpdateDependentDetailsOfServerByOrderForm();
	WarehousesClientServer.UpdateWarehouseGroupImage(SeveralWarehousesText, Items.PictureMultipleWarehouses,
		TotalWarehouses_);
	
EndProcedure

&AtServer
Procedure UpdateDependentDetailsOfServerByOrderForm()
	
	If Object.Goods.Count() = 0
		Or Not Object.TransferByOrders
		Or Not UseSalesOrders Then
		
		DiscrepancyOrderText = "";
		
		Items.GroupDiscrepancyOnOrder.Visible  = False;
		Items.GroupDiscrepancyOnOrders.Visible = False;
		
		If Object.Goods.Count() > 0 Then
			For Each LineProducts_ In Object.Goods Do
				LineProducts_.OrderDiscrepancy_3 = 0;
			EndDo;
		EndIf;
		
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
		DiscrepancyOrderText = NStr("vi = 'Dòng khác với đơn hàng: %NumberOfDiscrepancies%';
									|ru = 'Строк сверх заказа: %NumberOfDiscrepancies%';
									|en = 'Lines in excess of order: %NumberOfDiscrepancies%'; fa = 'Lines in excess of order: %NumberOfDiscrepancies%';
									|it = 'Righe oltre all''ordine: %NumberOfDiscrepancies%';
									|pl = 'Wierszy ponad zamówienia: %NumberOfDiscrepancies%';
									|tr = 'Sipariş fazlası satırı: %NumberOfDiscrepancies%'");
		DiscrepancyOrderText = StrReplace(DiscrepancyOrderText, "%NumberOfDiscrepancies%", NumberOfDiscrepancies);
	Else
		DiscrepancyOrderText = "";
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function DependentDetails()
	
	Return New Structure("WithoutReusablePackages", "Sum");
	
EndFunction

&AtClientAtServerNoContext
Procedure CalculateTotals_(Form)
	
	Form.AmountTotal = Form.Object.Goods.Total("SumWithoutReusablePackages");
	
EndProcedure

&AtServerNoContext
Procedure UpdateAvailabilityOfReturnContainerItems(Form)
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Form.Items,
		"ToReturnReusablePackage, ReusablePackagesReturnDate", "Enabled", Form.Object.ToReturnReusablePackage);
	
	If Not Form.Object.ToReturnReusablePackage Then
		Form.Object.ReusablePackagesReturnDate = Date(1,1,1);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetElementProperties()
	
	SetVisibilityOfCommandsByOrder();
	SetAvailabilityOfClipboardCommands();
	
	ItemArray = New Array;
	ItemArray.Add("GoodsUnlinkFromOrder");
	ItemArray.Add("GoodsContextMenuUnlinkFromOrder");
	
	PropertyValue = Object.TransferByOrders
						And TransferInExcessOfOrder;
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible",
		PropertyValue);
	
	ItemArray = New Array;
	ItemArray.Add("GoodsOpenSelection");
	ItemArray.Add("GoodsImportFromExternalFile");
	
	PropertyValue = Not Object.TransferByOrders
						Or (Object.TransferByOrders
							And TransferInExcessOfOrder);
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled",
		PropertyValue);
	
	TagName      = "GoodsAddReusablePackage";
	PropertyValue = Not Object.TransferByOrders;
	
	TMCommonUseClientServer.SetFormItemProperty(Items, TagName, "Enabled",
		PropertyValue);
	
	TagName = "GoodsFillInTheWarehouseInSelectedLines";
	
	If Not Object.TransferByOrders Then
		TMCommonUseClientServer.SetFormItemProperty(Items, TagName, "Enabled", WarehouseGroup_);
	Else
		TMCommonUseClientServer.SetFormItemProperty(Items, TagName, "Visible", False);
	EndIf;
	
	If Object.TransferByOrders Then
		ItemArray = New Array;
		ItemArray.Add("GoodsImportDataFromPDT");
		
		If Not TransferInExcessOfOrder Then
			ItemArray.Add("GoodsSplitRow");
			ItemArray.Add("GoodsContextMenuSplitRow");
			ItemArray.Add("GoodsSearchByBarcode");
		EndIf;
		
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", False);
	EndIf;
	
	If Object.TransferByOrders
		And Not VarianceFromTransferConditions Then
		
		ItemArray = New Array;
		ItemArray.Add("TransferByOrder");
		ItemArray.Add("TransferByOrders");
		ItemArray.Add("Partner");
		ItemArray.Add("Counterparty");
		ItemArray.Add("Terms");
		ItemArray.Add("Organization");
		ItemArray.Add("Contract");
		ItemArray.Add("Warehouse");
		ItemArray.Add("ToReturnReusablePackage");
		ItemArray.Add("ReusablePackagesReturnDate");
		
		If Not TransferInExcessOfOrder Then
			ItemArray.Add("GoodsRowCode");
			ItemArray.Add("GoodsProducts");
			ItemArray.Add("GoodsCharacteristic");
			ItemArray.Add("GoodsPackage");
			ItemArray.Add("GoodsPriceKind");
		EndIf;
		
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "ReadOnly", True);
		
		ItemArray = New Array;
		ItemArray.Add("GoodsFillThePricesByTermsOfSales");
		ItemArray.Add("GoodsFillInPricesOfSelectedRowsByPriceType");
		
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled",
			TransferInExcessOfOrder);
		
	EndIf;
	
	TagName      = "GoodsGroupSalesOrder";
	PropertyValue = Object.TransferByOrders;
	
	TMCommonUseClientServer.SetFormItemProperty(Items, TagName, "Visible", PropertyValue);
	
	If Items.BusinessOperation.ChoiceList.FindByValue(Object.BusinessOperation) = Undefined Then
		ReadOnly = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfCommandsByOrder()
	
	Items.CloseOrder.Visible  = Object.TransferByOrders And UseAdvancedFeaturesOfSalesOrder;
	Items.CloseOrders_2.Visible = Object.TransferByOrders And UseAdvancedFeaturesOfSalesOrder;
	
EndProcedure

&AtServer
Procedure RefillByNotes(AnArrayOfOrders)
	
	FillingStructure = SalesServerCall.ReFillInvoiceForOrders(Object);
	
	If FillingStructure.HasChanges Then
		Modified = True;
		Handler = Documents.TransferOfGoodsToBailee.ActionHandler(Object.BusinessOperation);
		Handler.FillInShopPantryAttributeInTable(Object);
		CalculateTotals_(ThisObject);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions,
																	Object,
																	RecalculateQuantity = True)
	
	If RecalculateQuantity Then
		AddActionRecalculateNumberOfUnits(Object.BusinessOperation, StructureOfActions);
	EndIf;
	
	StructureOfActions.Insert("RecalculateAmount");
	
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
EndProcedure

&AtServerNoContext
Procedure AddActionRecalculateNumberOfUnits(
			BusinessOperation, StructureOfActions, CheckIfYouNeedToRecalculateNumberOfUnits = False)
	
	Handler = Documents.TransferOfGoodsToBailee.ActionHandler(BusinessOperation);
	Handler.AddFillInActionForShopPantryAttribute(StructureOfActions);
	If Not CheckIfYouNeedToRecalculateNumberOfUnits Then
		Handler.AddActionRecalculateNumberOfUnits(StructureOfActions);
	EndIf;
	
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
EndProcedure

&AtServerNoContext
Procedure AddFillInActionForShopPantryAttribute(
			BusinessOperation, StructureOfActions, CheckIfYouNeedToRecalculateNumberOfUnits = False)
	
	Handler = Documents.TransferOfGoodsToBailee.ActionHandler(BusinessOperation);
	Handler.AddFillInActionForShopPantryAttribute(StructureOfActions);
	
EndProcedure

&AtServer
Procedure FillMultiTurnContainersFromStorageServer(AddressOfContainerInStorage)
	
	FillInProductTypeAttribute_ = New Structure("Products", "ItemsType");
	CheckFillWarehouse         = BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object,
																													WarehouseGroup_);
	
	ActionStructureModifiedStrings = New Structure;
	ActionStructureModifiedStrings.Insert("RecalculateNumberOfPackages");
	ActionStructureModifiedStrings.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	
	AddActionsToStructureWhenChangingPackagesNumber(ActionStructureModifiedStrings, Object, False);
	
	StructureOfActionsAddedLines = Common.CopyRecursive(
											ActionStructureModifiedStrings);
	StructureOfActionsAddedLines.Insert("CheckFillWarehouse",         CheckFillWarehouse);
	StructureOfActionsAddedLines.Insert("FillInProductTypeAttribute_", FillInProductTypeAttribute_);
	
	AddPriceFillingActionsToStructure(StructureOfActionsAddedLines, Object, ToUseTermsOfSales, UsePriceManagementSystem25, NewCommissionAgreement);
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject,
		StructureOfActionsAddedLines);
	
	ReusablePackageServer.FillMultiTurnContainersFromStorage(Object, AddressOfContainerInStorage, "Goods",
		"Products,Characteristic,Warehouse", ActionStructureModifiedStrings, StructureOfActionsAddedLines);
	Handler = Documents.TransferOfGoodsToBailee.ActionHandler(Object.BusinessOperation);
	Handler.FillInShopPantryAttributeInTable(Object);
	FillInServiceDetailsForProductRange();
	WhenChangingWarehouseInTablePartServer();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddPriceFillingActionsToStructure(StructureOfActions, Object, UseAgreements, UsePriceManagementSystem25, NewCommissionAgreement)
	
	If Not NewCommissionAgreement And ((UseAgreements And ValueIsFilled(Object.Terms)) 
		Or (Not UseAgreements And UsePriceManagementSystem25)) Then
		
		FillIn_TermsOfSales = BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object);
		StructureOfActions.Insert("FillIn_TermsOfSales", FillIn_TermsOfSales);
		
	Else
		
		FillInSalePrice = BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object);
		StructureOfActions.Insert("FillInSalePrice", FillInSalePrice);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure GetUploadedProductsFromStorage(GoodsAddressInStorage)
	
	ItemsFromStorage    = GetFromTempStorage(GoodsAddressInStorage);
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array();
	
	CheckFillWarehouse = BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object,
		WarehouseGroup_);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckFillWarehouse",           CheckFillWarehouse);
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	
	For Each RowOfGoods In ItemsFromStorage Do
		
		StringTSGoods = Object.Goods.Add();
		FillPropertyValues(StringTSGoods, RowOfGoods, , "RowCode");
		FillInSenderSAssignment(Object.TransferByOrders, Object.BusinessOperation, StringTSGoods);
		
		UpdateOrderDeviationsInLine(StringTSGoods, Object.TransferByOrders);
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
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtServer
Procedure GetStockTypesFromStorage(ValueSelected)
	
	InventoriesServer.ProcessInputOfInventoryTypesManually(ValueSelected, ThisObject);
	
EndProcedure

&AtClient
Procedure TransferByOrdersWhenChangedAfterSelection(Result, AdditionalParameters) Export
	
	SalesOrder = Result;
	
	If SalesOrder = Undefined Then
		Object.TransferByOrders = False;
		Return;
	EndIf;
	
	If Object.Goods.Count() = 0 Then
		QueryText = NStr("vi = 'Danh sách Hàng hóa sẽ được điền bằng số dư hàng hóa chưa lập theo chứng từ %SalesOrder%. Tiếp tục?';
						|ru = 'Список Товары будет заполнен остатками неоформленных товаров по документу %SalesOrder%. Продолжить?';
						|en = 'The Item list will be filled in with non-generated goods under the %SalesOrder% document. Continue?'; fa = 'The Item list will be filled in with non-generated goods under the %SalesOrder% document. Continue?';
						|it = 'Elenco Merci sarà compilato con le giacenze delle merci non formalizzate nel documento %SalesOrder%. Continuare?';
						|pl = 'Lista Wiersze pozycji zostanie wypełniona przez resztki niesporządzonych towarów według dokumentu %SalesOrder%. Kontynuować?';
						|tr = 'Ürünler listesi %SalesOrder%belgesinden kalan ürünlerle doldurulacaktır. Devam edilsin mi?'");
		QueryText = StrReplace(QueryText, "%SalesOrder%", SalesOrder);
	Else
		QueryText = NStr("vi = 'Các dòng trong danh sách hàng hóa sẽ được liên kết với các dòng của chứng từ %SalesOrder%. Các dòng không thể được liên kết với các dòng thứ tự sẽ bị xóa. Tiếp tục?';
						|ru = 'Строки в списке Товары будут привязаны к строкам документа %SalesOrder%. Строки, которые невозможно привязать к строкам заказа, будут удалены. Продолжить?';
						|en = 'Lines in the Item list will be linked to lines of the %SalesOrder% document. Lines that cannot be linked to the order lines will be deleted. Continue?'; fa = 'Lines in the Item list will be linked to lines of the %SalesOrder% document. Lines that cannot be linked to the order lines will be deleted. Continue?';
						|it = 'Le righe nell''elenco Merci saranno associate alle righe del documento %SalesOrder%. Le righe che non potranno essere associate alle righe dell''ordine saranno eliminate. Continuare?';
						|pl = 'Linie na liście Wiersze pozycji zostaną połączone z wierszami dokumentu %SalesOrder%. Wiersze, których nie można połączyć z wierszami zamówień, zostaną usunięte. Kontynuować?';
						|tr = 'Ürünler listesindeki satırlar %SalesOrder% belgesinin satırlarına bağlanacaktır. Sipariş satırlarına bağlanamayan satırlar silinecektir. Devam edilsin mi?'");
		QueryText = StrReplace(QueryText, "%SalesOrder%", SalesOrder);
	EndIf;
	
	TransferByOrdersWhenFragmentChanges(SalesOrder, QueryText);
	
EndProcedure

&AtClient
Procedure TransferByOrdersWhenFragmentChanges(Val SalesOrder, Val QueryText)
	
	AdditionalParameters = New Structure("SalesOrder", SalesOrder);
	CallbackDescription      = New CallbackDescription("TransferByOrdersOnChangeCompletion", ThisObject,
									AdditionalParameters);
	
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtServer
Procedure FillInFromOrderServer()
	
	Object.Goods.Clear();
	
	If UseTransferForSeveralOrders Then
		AnArrayOfOrders = Undefined;
	Else
		AnArrayOfOrders = New Array();
		AnArrayOfOrders.Add(Object.SalesOrder);
	EndIf;

	FillParameters = New Structure("DisplayMessage_1", False);

	Documents.TransferOfGoodsToBailee.FillByOrderBalances(
		Object, Object.Goods, Warehouse, AnArrayOfOrders, FillParameters, Object.PackageBarcodes);
	
	FillInServiceDetailsForProductRange();
	Handler = Documents.TransferOfGoodsToBailee.ActionHandler(Object.BusinessOperation);
	Handler.FillInShopPantryAttributeInTable(Object);
	WhenChangingWarehouseInTablePartServer();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, Object.ToReturnReusablePackage);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	
	FillBaseForPrinting();
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
EndProcedure

&AtServer
Procedure LinkTransferLinesToOrders(SelectByOrder_)
	
	Documents.TransferOfGoodsToBailee.LinkTransferLinesToOrders(ThisObject, Object, SeriesSpecificationParameters, SelectByOrder_);
	Handler = Documents.TransferOfGoodsToBailee.ActionHandler(Object.BusinessOperation);
	Handler.FillInShopPantryAttributeInTable(Object);
	For Each CurRow In Object.Goods Do
		If Not ValueIsFilled(CurRow.RowCode) Then
			CurRow.Purpose            = Catalogs.Assignments.EmptyRef();
			CurRow.AssignmentSender = Catalogs.Assignments.EmptyRef();
		EndIf;
		If Not ValueIsFilled(CurRow.SalesOrder) And SelectByOrder_ Then
			CurRow.SalesOrder = Object.SalesOrder;
		EndIf;
	EndDo;
	
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
		
		ProductsClientServer.UpdateCachedValuesToAccountForSeries(TableRow, CachedValues,
			SeriesSpecificationParameters);
		
		TableRow.RowCode             = 0;
		TableRow.Purpose            = Undefined;
		TableRow.AssignmentSender = Undefined;
		TableRow.WithAssignment           = False;
		
		If UntieOnlyStrings Then
			TableRow.OrderDiscrepancy_3 = 1;
		Else
			TableRow.SalesOrder = Undefined;
		EndIf;
		
		// Reassign the series lines
		ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Object, SeriesSpecificationParameters,
			CurRow, CachedValues);
		
	EndDo;
	
	UpdateDependentDetailsOfServerByOrderForm();
	
EndProcedure

&AtClient
Procedure DateWhenFragmentWasChanged(RecalculatePrices_)
	
	Var PricesCalculated;
	
	DateOnChangeServer(RecalculatePrices_, PricesCalculated);
	
	If RecalculatePrices_ Then
		SalesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated);
	EndIf;
	
	
EndProcedure

&AtServer
Procedure FillBaseForPrinting()

	Handler = Documents.TransferOfGoodsToBailee.ActionHandler(Object.BusinessOperation);
	
	If Not BasisChanged Then
		FillPropertyValues(Object, Handler.StructureOfBaseForPrinting(Object));
	EndIf;
	
	PrintBasisTable.Load(Handler.PrintBasisTable(Object));
	
EndProcedure

&AtServer
Procedure FillInSubordinatePropertiesForStatistics(ParentPropsName)
	
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, ParentPropsName);
	
EndProcedure

&AtServer
Procedure FillInDefaultContract()
	
	Handler = Documents.TransferOfGoodsToBailee.ActionHandler(Object.BusinessOperation);
	Contract = Handler.GetDefaultContract(Object);
	
	If Contract <> Object.Contract Then
		Object.Contract = Contract;
	EndIf;
	
	If ValueIsFilled(Object.Contract) Then
		
		SalesServer.FillInBankAccountsUnderAgreement(Object.Contract,
			Object.CompanyBankAccount, Object.CounterpartyBankAccount);
		
		FillBaseForPrinting();
		NewCommissionAgreement = ThisIsContractForNewCommission();
		If NewCommissionAgreement Then
			PriceTypeAccountingPriceType = ConsignmentSalesServer.TypeOfContractPrice(Object.Contract, True);
		Else
			PriceTypeAccountingPriceType = Catalogs.TypesOfPrices.EmptyRef();
		EndIf;
		
	Else
		NewCommissionAgreement = False;
		PriceTypeAccountingPriceType = Catalogs.TypesOfPrices.EmptyRef();
	EndIf;
	
	Handler.SetContractAvailability(ThisObject, Object, Object.Contract);
	
EndProcedure

&AtClient
Procedure WarehouseWhenFragmentChanges(Val UntieAllLinesFromOrder, Val ClearLines_)
	
	WarehouseOnChangeServer(ClearLines_, UntieAllLinesFromOrder);
	
EndProcedure

&AtServer
Procedure ExecuteRecalculateDocumentAmountsServer(OldCurrency, NewCurrency)
	
	If OldCurrency <> NewCurrency Then
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateAmount");
		
		DocumentDate               = ?(ValueIsFilled(Object.Date), Object.Date,CurrentSessionDate());
		StructureOfOldCurrencyRates = ProcessingOfExchangeRatesTM.GetCurrencyRate(OldCurrency, DocumentDate, LocalAccountingCurrency);
		StructureOfNewCurrencyRates  = ProcessingOfExchangeRatesTM.GetCurrencyRate(NewCurrency,  DocumentDate, LocalAccountingCurrency);
		
		CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
		RowsToProcess = New Array();
		
		For Each CurRow In Object.Goods Do
			
			CurRow.Price = ProcessingOfExchangeRatesTM.ConvertAtRate(
				CurRow.Price,
				StructureOfOldCurrencyRates,
				StructureOfNewCurrencyRates);
			RowsToProcess.Add(CurRow);
			
		EndDo;
		
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			RowsToProcess,
			StructureOfActions,
			Object.Goods,
			CachedValues);
		
		TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
		
		CalculateTotals_(ThisObject);
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeSelectingProductsFromOrder(ArrayOfStringCodes, AddressOfGoods, FormCaption)
	
	For Each TSRow In Object.Goods Do
		
		If TSRow.RowCode <> 0
			And ValueIsFilled(TSRow.SalesOrder) Then
			
			FilterParameters = New Structure("SalesOrder, RowCode", TSRow.SalesOrder, TSRow.RowCode);
			
			ArrayOfStringCodes.Add(FilterParameters);
			
		EndIf;
		
	EndDo;
	
	AddressOfGoods = PutToTempStorage(Object.Goods.Unload());
	
	Handler = Documents.TransferOfGoodsToBailee.ActionHandler(Object.BusinessOperation);
	
	FormCaption = Handler.DocumentFormHeader(Not ValueIsFilled(Object.Ref), Object.Number, Object.Date);
	
EndProcedure

&AtServer
Procedure GoodsAfterDeleteRowServer(SeriesStatusesNeedToBeUpdated, CachedValues)
	
	If SeriesStatusesNeedToBeUpdated Then
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Undefined, CachedValues);
	EndIf;
	
	UpdateOrderInformation();
	WhenChangingWarehouseInTablePartServer();
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
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
	
	IssueNotification = New CallbackDescription("QuestionToUserWhenChangingDetailsOfLineQuestionCompletion",
												ThisObject,
												AdditionalParameters);
	
	QueryText = NStr("vi = 'Dòng được soạn sẽ sẽ không liên quan đến dòng của đơn hàng. Tiếp tục?';
					|ru = 'Редактируемая строка перестанет быть связанной со строкой заказа. Продолжить?';
					|en = 'The edited line will be unlinked from the order line. Continue?'; fa = 'The edited line will be unlinked from the order line. Continue?';
					|it = 'La riga da modificare non sarà più associata alla riga dell''ordine. Continuare?';
					|pl = 'Edytowany wiersz nie będzie powiązany z wierszem zamówienia. Kontynuować?';
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
		UpdateOrderDeviationsInLine(CurrentRow, Object.TransferByOrders);
		RunCallback(CallbackDescription, True);
	Else
		// If the user refused to change the linked string, we return the old values.
		FillPropertyValues(CurrentRow, PreviousRowDetails);
		RunCallback(CallbackDescription, False);
	EndIf;
	
EndProcedure

&AtServer
Function PutGoodsAndStockTypesInStorage()
	
	Return InventoriesServer.PutGoodsAndStockTypesInStorage(ThisObject);
	
EndFunction

&AtClient
Procedure CloseOrderFragment()
	
	ListOfOrdersToClose = New ValueList;
	
	If ValueIsFilled(Object.SalesOrder) Then
		ListOfOrdersToClose.Add(Object.SalesOrder)
	Else
		ListOfOrdersToClose.LoadValues(OrderList.UnloadValues());
	EndIf;
	
	ClosureStructure = New Structure;
	ClosureStructure.Insert("Orders",                       ListOfOrdersToClose);
	ClosureStructure.Insert("DocumentInitiator",            Object.Ref);
	ClosureStructure.Insert("CancelUnprocessedLines", True);
	ClosureStructure.Insert("CloseOrders",              True);
	
	OpenForm("DataProcessor.OrderClosureWizard.Form.ClosureForm", ClosureStructure, ThisObject, , , , Undefined,
		FormWindowOpeningMode.LockOwnerWindow);
	
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
		CommonClient.MessageToUser(MessageText, Object.Ref, "Object.Terms", ,Cancel);
		
	EndIf;
	
	If Not ValueIsFilled(Object.Currency) Then
		MessageText = NStr("vi = 'Chưa điền trường ""Tiền tệ""';
							|ru = 'Поле ""Валюта"" не заполнено';
							|en = '""Currency"" is required'; fa = '""Currency"" is required';
							|it = 'Il campo ""Valuta"" non è compilato';
							|pl = 'Pole ""Waluta"" nie jest wypełnione';
							|tr = '""Para Birimi"" alanı doldurulmadı'");
		CommonClient.MessageToUser(MessageText, Object.Ref, "Object.Currency", ,Cancel);
	EndIf;
	
EndProcedure

&AtServer
Function FillWarehouseInSelectedLinesOnServer(Val ArrayOfSelectedRows, Warehouse)
	
	FilledWithRows = WarehousesServer.FillInWarehousesInSelectedLines(Object.Goods, ArrayOfSelectedRows, Warehouse);
	Rows = New Array;
	For Each RowID In ArrayOfSelectedRows Do
		Rows.Add(Object.Goods.FindByID(RowID));
	EndDo;
	
	Handler = Documents.TransferOfGoodsToBailee.ActionHandler(Object.BusinessOperation);
	Handler.FillInShopPantryAttributeInTable(Object, Rows);
	If FilledWithRows > 0 Then
		ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
		WhenChangingWarehouseInTablePartServer();
	EndIf;
	
	Return FilledWithRows;
	
EndFunction

&AtClient
Procedure OpenTransferPrintDetails()
	
	Try
		LockFormDataForEdit();
	Except
		ShowMessageBox(Undefined, BriefErrorDescription(ErrorInfo()));
		Return;
	EndTry;
	
	DeliveryOrderData = GoodsDeliveryClientServer.OrderParameters();
	FillPropertyValues(DeliveryOrderData, Object);
	
	ParametersStructure = New Structure();
	ParametersStructure.Insert("Ref",                         Object.Ref);
	ParametersStructure.Insert("ObjectType",                     "TransferOfGoodsToBailee");
	ParametersStructure.Insert("OrderSales",            Object.TransferByOrders);
	ParametersStructure.Insert("Date",                           Object.Date);
	ParametersStructure.Insert("Partner",                        Object.Partner);
	ParametersStructure.Insert("Counterparty",                     Object.Counterparty);
	ParametersStructure.Insert("CounterpartyBankAccount",      Object.CounterpartyBankAccount);
	ParametersStructure.Insert("BusinessOperation",          Object.BusinessOperation);
	ParametersStructure.Insert("Organization",                    Object.Organization);
	ParametersStructure.Insert("CompanyBankAccount",      Object.CompanyBankAccount);
	ParametersStructure.Insert("Contract",                        Object.Contract);
	
	ParametersStructure.Insert("DeliveryAddress",                  Object.DeliveryAddress);
	ParametersStructure.Insert("DeliveryAddressValue",          Object.DeliveryAddressValue);
	ParametersStructure.Insert("DeliveryAddressFieldValues",     Object.DeliveryAddressFieldValues);
	ParametersStructure.Insert("DeliveryZone",                   Object.DeliveryZone);
	ParametersStructure.Insert("DeliveryTimeFrom",                 Object.DeliveryTimeFrom);
	ParametersStructure.Insert("DeliveryTimeTo",                Object.DeliveryTimeTo);
	ParametersStructure.Insert("AdditionalDeliveryInformation", Object.AdditionalDeliveryInformation);
	ParametersStructure.Insert("DeliveryOrderData",   DeliveryOrderData);
	
	ParametersStructure.Insert("Shipper",               Object.Shipper);
	ParametersStructure.Insert("ShipperBankAccount", Object.ShipperBankAccount);
	ParametersStructure.Insert("GoodsRecipient",                Object.GoodsRecipient);
	ParametersStructure.Insert("GoodsRecipientBankAccount",  Object.GoodsRecipientBankAccount);
	ParametersStructure.Insert("Director",                   Object.Director);
	ParametersStructure.Insert("ChiefAccountant",               Object.ChiefAccountant);
	ParametersStructure.Insert("IssuiedBy",                       Object.IssuiedBy);
	ParametersStructure.Insert("IssuiedByJobTitle",              Object.IssuiedByJobTitle);
	ParametersStructure.Insert("Basis",                      Object.Basis);
	ParametersStructure.Insert("ReferenceDocumentDateForPrintForms",                  Object.ReferenceDocumentDateForPrintForms);
	ParametersStructure.Insert("BaseDocumentNumber",                 Object.BaseDocumentNumber);
	ParametersStructure.Insert("ReadOnly",                 ReadOnly);
	ParametersStructure.Insert("PrintBasisTable",      PrintBasisTable);
	ParametersStructure.Insert("LetterOfAuthorityIssuedBy",             Object.LetterOfAuthorityIssuedBy);
	ParametersStructure.Insert("PowerOfAttorneyDate",               Object.PowerOfAttorneyDate);
	ParametersStructure.Insert("PowerOfAttorneyPerson",               Object.PowerOfAttorneyPerson);
	ParametersStructure.Insert("PowerOfAttorneyNumber",              Object.PowerOfAttorneyNumber);
	
	OpenForm("CommonForm.PrintingDetailsOfSales", ParametersStructure, ThisObject, , , , Undefined,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtServer
Procedure FillOperationSelectionList()
	
	If Items.Find("BusinessOperation") <> Undefined  Then
	
		If Not GetFormFunctionalOption("UseSalesCommission") Then
			
			ListItem = Items.BusinessOperation.ChoiceList.FindByValue(Enums.BusinessTransactions.TransferToCommissionAgent);
			
			If ListItem <> Undefined Then
				Items.BusinessOperation.ChoiceList.Delete(ListItem);
			EndIf;
			
		EndIf;
		
		If Not GetFormFunctionalOption("UseTransferToCustodyWithRightOfSale") Then
			
			ListItem = Items.BusinessOperation.ChoiceList.FindByValue(Enums.BusinessTransactions.TransferToStorageWithRightOfSale);
			
			If ListItem <> Undefined Then
				Items.BusinessOperation.ChoiceList.Delete(ListItem);
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

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

&AtServer
Function ThisIsContractForNewCommission()

	Result = Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
		And ValueIsFilled(Object.Contract)
		And Common.ObjectAttributeValue(Object.Contract, "ConsignmentSales25");
		
	Return Result;
	
EndFunction

&AtClient
Procedure FillInContractPricesInLine(OnAllLines = False)
	
	FillParameters = New Structure();
	FillParameters.Insert("PriceKind", PriceTypeAccountingPriceType);
	FillParameters.Insert("FieldPriceType", "PriceTypeAccountingPriceType");
	FillParameters.Insert("PriceIncludesVAT", Undefined);
	FillParameters.Insert("TabularSectionName", "Goods");
	FillParameters.Insert("TabularSectionPresentation", "Goods");
	
	If EnterprisePricesFillingClient.YouNeedToFillInPricesByType(Object, FillParameters) Then
		
		If TransferInExcessOfOrder
			And Not VarianceFromTransferConditions Then
			
			If Object.TransferByOrders
				And Object.Goods.Total("OrderDiscrepancy_3") = 0 Then
				
				WarningText = NStr("vi = 'Không thể ấn định đơn giá vào các dòng theo đơn hàng.';
									|ru = 'Цена не может быть назначена в строках по заказу.';
									|en = 'Price cannot be assigned in the order lines.'; fa = 'Price cannot be assigned in the order lines.';
									|it = 'Il prezzo non può essere impostato nelle righe per ordine.';
									|pl = 'Cena nie może być wyznaczona w wierszach wg zamówienia.';
									|tr = 'Fiyat, sipariş satırlarına girilemiyor.'");
				
				ShowMessageBox(Undefined, WarningText);
				
				Return;
				
			EndIf;
			
		EndIf;
		
		PricesCalculated = FillThePricesByTermsOfSalesServer(OnAllLines,, True);
		SalesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
EndProcedure

&AtServer
Procedure WhenChangingKeyDetailsStatusOfEDO()
	
	
EndProcedure

&AtServer
Procedure SetLBEditingOption()
	
	LBAvailabilityParameters = LinesOfBusinessServer.ParametersLBEditingCapability();
	
	LBAvailabilityParameters.OrderInvoice_3 = Object.TransferByOrders;
	LBAvailabilityParameters.Contract           = Object.Contract;
	LBAvailabilityParameters.ARAPObjectSettings   = Common.ObjectAttributeValue(Object.Contract, "ARAPObjectSettings");
	
	LinesOfBusinessServer.SetLBEditingOption(ThisObject, LBAvailabilityParameters);
	
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

&AtServer
Function UseAdvancedFeaturesOfSalesOrder()
	
	Handler = Documents.TransferOfGoodsToBailee.ActionHandler(Object.BusinessOperation);
	
	If OrderList.Count() = 0
		Or Not Handler.OrderType_5() = Type("DocumentRef.SalesOrder") Then
		Return Handler.UseAdvancedFeaturesOfSalesOrder();
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	T.ThisIsOrderAsInvoice AS ThisIsOrderAsInvoice
	|FROM
	|	(SELECT
	|		Document.ThisIsOrderAsInvoice AS ThisIsOrderAsInvoice
	|	FROM
	|		Document.SalesOrder AS Document
	|	WHERE
	|		Document.Ref IN(&Ref)
	|	) AS T
	|
	|GROUP BY
	|	T.ThisIsOrderAsInvoice";
	
	Query.SetParameter("Ref", OrderList);
	
	SetPrivilegedMode(True);
	Upload0 = Query.Execute().Unload();
	If Upload0.Count() = 1 Then
		Return Not Upload0[0].ThisIsOrderAsInvoice;
	Else
		Handler = Documents.TransferOfGoodsToBailee.ActionHandler(Object.BusinessOperation);
		Return Handler.UseAdvancedFeaturesOfSalesOrder();
	EndIf;
	
EndFunction


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
