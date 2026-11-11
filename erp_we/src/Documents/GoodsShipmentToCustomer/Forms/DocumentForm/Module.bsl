
#Region Variables

&AtClient
Var CachedValues; // used by the mechanism for processing changes in PM details

&AtClient
Var PreviousRowDetails; // Used to separate the receipt line from the order line

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
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization",  True);
	
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	TMCommonUse.CustomizePeripherals(ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		AutoTitle = False;
		OnReadCreateAtServer();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	ElsIf Parameters.FillingValues.Property("FillByWarehouseDocument") Then
		Modified = True;
		
		RefillByNotes(Parameters.FillingValues.AnArrayOfOrders);
	EndIf;
	SetConditionalAppearance();
	
	SalesServer.SetModeForSelectingGroupsOfWarehouseItems(Items.Warehouse);
	SalesServer.SetBlankContractMark(Items, "Contract", True);
	
	ReadPriceTypeRight   = AccessRight("View",
		Metadata.Documents.GoodsShipmentToCustomer.TabularSections.Goods.Attributes.PriceKind);
	
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

	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecording.OnCreateAtServerDocumentForm(ThisObject);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording 
	
	Items.EPDStateGroup.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	
	
	VATAccountingERP.EstablishVisibilityOfCountryOfImplementation(ThisObject);
	
	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisObject);
	
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
	PreviousRowDetails.Insert("SalesOrder");
	
	If Object.ShipmentByOrders
		And Not ShipmentInExcessOfOrder
		And Not ValueIsFilled(Object.Ref)
		And Not ValueIsFilled(Object.Warehouse) Then
		
		If UseShipmentForMultipleOrders Then
			MessageText = NStr("vi = 'Hãy làm rõ kho giao hàng và điền hàng hóa bằng lệnh ""Điền theo lệnh""';
								|ru = 'Уточните склад отгрузки и заполните товары с помощью команды ""Заполнить по распоряжениям""';
								|en = 'Specify an origin warehouse and fill in goods using the ""Fill in by references"" command'; fa = 'Specify an origin warehouse and fill in goods using the ""Fill in by references"" command';
								|it = 'Specify an origin warehouse and fill in goods using the ""Fill in by references"" command';
								|pl = 'Specify an origin warehouse and fill in goods using the ""Fill in by references"" command';
								|tr = 'Ürünler listesindeki satırlar, ""Siparişlere göre doldur"" komutu ile belge satırlarına bağlanacaktır.'");
		Else
			MessageText = NStr("vi = 'Hãy chỉ định kho giao hàng và điền hàng hóa bằng lệnh ""Điền theo lệnh""';
								|ru = 'Уточните склад отгрузки и заполните товары с помощью команды ""Заполнить по распоряжению""';
								|en = 'Specify an origin warehouse  and fill in goods using the ""Fill in by reference"" command'; fa = 'Specify an origin warehouse  and fill in goods using the ""Fill in by reference"" command';
								|it = 'Specify an origin warehouse  and fill in goods using the ""Fill in by reference"" command';
								|pl = 'Specify an origin warehouse  and fill in goods using the ""Fill in by reference"" command';
								|tr = 'Ürünler listesindeki satırlar, ""Siparişe göre doldur"" komutu ile belge satırlarına bağlanacaktır.'");
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
	
	Attachable_CheckCompletionOfTaskForReceivingCarriers();
	
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
		
	ElsIf ChoiceSource.FormName = "Catalog.InventoryKinds.Form.InventoryOwnerAttributesForm" Then
		
		GetStockTypesFromStorage(ValueSelected);
		
	ElsIf VATAccountingERPClient.FinishedEditingInvoiceIssued(ValueSelected, ChoiceSource) Then
		
		UpdateTextDocumentsBasedOn();
		
	ElsIf ChoiceSource.FormName = "CommonForm.PrintingDetailsOfSales" Then
		
		If ValueSelected <> Undefined Then
			Modified = True;
			
			If GoodsDeliveryClientServer.UsedDelivery25()
				And CommonClientServer.HasAttributeOrObjectProperty(ValueSelected, "DeliveryZone") Then
				
				FillPropertyValues(Object, ValueSelected,, "DeliveryZone");
				
			Else
				
				FillPropertyValues(Object, ValueSelected);
				
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
	
	If EventName = "Write_InvoiceIssued"
		And (Parameter.Property("OwnerForm") And Parameter.OwnerForm = UUID
			Or Parameter.Property("ListOfGrounds") And Parameter.ListOfGrounds.FindByValue(Object.Ref) <> Undefined) Then
		UpdateTextDocumentsBasedOn();
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
		SetParameters.Insert("DialColumns",        DialColumns(ThisObject));
		
		SetAddressInTemporaryStorage = SetAddressInTemporaryStorage(SetParameters);
		
		OpeningParameters = New Structure;
		OpeningParameters.Insert("AddressInTempStorage", SetAddressInTemporaryStorage);
		OpeningParameters.Insert("Ref",                    Object.Ref);
		OpeningParameters.Insert("Date",                      Object.Date);
		OpeningParameters.Insert("Partner",                   Object.Partner);
		OpeningParameters.Insert("Terms",                Object.Terms);
		OpeningParameters.Insert("PriceIncludesVAT",           True);
		OpeningParameters.Insert("Warehouse",                     Object.Warehouse);
		OpeningParameters.Insert("Currency",                    Object.Currency);
		OpeningParameters.Insert("ProductsInSet",        Parameter.ProductsInSet);
		OpeningParameters.Insert("ItemVariantOfSet",      Parameter.ItemVariantOfSet);
		OpeningParameters.Insert("HideCommandRemainingQuantityInWarehouses", False);
		
		OpenForm("DataProcessor.EditSet.Form.Form",
						OpeningParameters,
						ThisObject,
						UUID);
		
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
		ContractOnChange(Items[Parameter]);
	EndIf;
	
EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)
	
	FormEventsClient.URLProcessing(ThisObject,
															FormattedStringURL,
															StandardProcessing);
	
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
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters, Cancel);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Handler of the "Properties" mechanism
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject,
																			Cancel,
																			CurrentObject,
																			WriteParameters);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject,
																							CurrentObject,
																							WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	ARAPAccountingServer.BeforeWriteAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	Documents.GoodsShipmentToCustomer.CustomizeForm(ThisObject, Object.Number, Object.Date);
	
	UpdateOrderDeviations();
	FillInServiceDetailsForProductRange();
	SetElementProperties();
	UpdateTextDocumentsBasedOn();
	
	
	
	LinesOfBusinessServer.AfterWriteAtServer(ThisObject);
	
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject,
																			CurrentObject,
																			WriteParameters);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	ARAPAccountingFormWork.FormAfterRecordingOnServer(ThisObject, CurrentObject.AdditionalProperties);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Title = "";
	AutoTitle = True;
	
	Notify("Write_GoodsShipmentToCustomer", WriteParameters, Object.Ref);
	
	
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
Procedure ShipmentByOrdersOnChange(Item)
	
	SalesOrder = Undefined;
	
	SetAvailabilityOfClipboardCommandsOnClient();
	
	If ShipmentStarted
		And Object.ShipmentByOrders Then
		
		Object.ShipmentByOrders = False;
		
		WarningText = NStr("vi = 'Đã bắt đầu giao hàng theo chứng từ này. Không thể thay đổi dấu hiệu ""Giao hàng theo lệnh"" sau khi bắt đầu giao hàng.';
							|ru = 'По данному документу уже начата отгрузка. Менять признак ""Отгрузка по распоряжению"" после начала отгрузки не допускается.';
							|en = 'Shipment has already started for this document. Cannot change the ""Shipment by reference"" checkbox after shipment start.'; fa = 'Shipment has already started for this document. Cannot change the ""Shipment by reference"" checkbox after shipment start.';
							|it = 'Shipment has already started for this document. Cannot change the ""Shipment by reference"" checkbox after shipment start.';
							|pl = 'Shipment has already started for this document. Cannot change the ""Shipment by reference"" checkbox after shipment start.';
							|tr = 'Bu belgeye göre sevkiyat hali hazırda başlamıştır. Sevkiyat başladıktan sonra ""Siparişe göre sevkiyat"" işaretinin değiştirilmesine izin verilmez.'");
		
		ShowMessageBox(Undefined, WarningText);
		
		Return;
		
	EndIf;
	
	If Object.ShipmentByOrders Then
		
		If UseShipmentForMultipleOrders Then
			
			If Object.Goods.Count() = 0 Then
				QueryText = NStr("vi = 'Sẽ điền lại danh sách ""Hàng hóa"" bởi số dư hàng hóa chưa lập chứng từ theo lệnh. Tiếp tục?';
								|ru = 'Список ""Товары"" будет перезаполнен остатками неоформленных товаров по распоряжениям. Продолжить?';
								|en = 'The ""Goods"" list will be refilled with remaining unregistered reference goods. Continue?'; fa = 'The ""Goods"" list will be refilled with remaining unregistered reference goods. Continue?';
								|it = 'The ""Goods"" list will be refilled with remaining unregistered reference goods. Continue?';
								|pl = 'The ""Goods"" list will be refilled with remaining unregistered reference goods. Continue?';
								|tr = '""Ürünler"" listesi siparişe ilişkin işlenmemiş ürünlerin bakiyeleri ile yeniden doldurulacaktır. Devam edilsin mi?'");
			Else
				QueryText = NStr("vi = 'Các dòng trong danh sách ""Hàng hóa"" sẽ được gắn với các dòng trong lệnh. Tiếp tục?';
								|ru = 'Строки в списке ""Товары"" будут привязаны к строкам распоряжений. Продолжить?';
								|en = 'The ""Goods"" list lines will be linked to the reference lines. Continue?'; fa = 'The ""Goods"" list lines will be linked to the reference lines. Continue?';
								|it = 'The ""Goods"" list lines will be linked to the reference lines. Continue?';
								|pl = 'The ""Goods"" list lines will be linked to the reference lines. Continue?';
								|tr = '""Ürünler"" listesindeki satırlar sipariş satırlarına bağlanacaktır. Devam edilsin mi?'");
			EndIf;
			
		Else

			CallbackDescription = New CallbackDescription("ShippingOnOrdersWhenChangingAfterSelection", ThisObject);
			OpenOrderSelection(CallbackDescription);
			Return;
			
		EndIf;
		
	Else
		
		If Object.Goods.Count() > 0 Then
			
			If UseShipmentForMultipleOrders Then
				QueryText = NStr("vi = 'Các dòng trong danh sách ""Hàng hóa"" sẽ không còn liên kết với các dòng trong lệnh. Tiếp tục?';
								|ru = 'Строки в списке ""Товары"" перестанут быть связанными со строками распоряжения. Продолжить?';
								|en = 'The ""Goods"" list lines will be unlinked from the reference lines. Continue?'; fa = 'The ""Goods"" list lines will be unlinked from the reference lines. Continue?';
								|it = 'The ""Goods"" list lines will be unlinked from the reference lines. Continue?';
								|pl = 'The ""Goods"" list lines will be unlinked from the reference lines. Continue?';
								|tr = '""Ürünler"" listesindeki satırlar artık sipariş satırlarına ilişkilendirilmeyecektir. Devam edilsin mi?'");
			Else
				QueryText = NStr("vi = 'Các dòng trong danh sách ""Hàng hóa"" sẽ không còn liên kết với các dòng trong lệnh. Tiếp tục?';
								|ru = 'Строки в списке ""Товары"" перестанут быть связанными со строками распоряжения. Продолжить?';
								|en = 'The ""Goods"" list lines will be unlinked from the reference lines. Continue?'; fa = 'The ""Goods"" list lines will be unlinked from the reference lines. Continue?';
								|it = 'The ""Goods"" list lines will be unlinked from the reference lines. Continue?';
								|pl = 'The ""Goods"" list lines will be unlinked from the reference lines. Continue?';
								|tr = '""Ürünler"" listesindeki satırlar artık sipariş satırlarına ilişkilendirilmeyecektir. Devam edilsin mi?'");
			EndIf;
			
		Else
			
			ShipmentForOrdersOnChangeATServer();
			
			Return;
			
		EndIf;
		
	EndIf;
	
	ShipmentOnOrdersONChangeFragment(SalesOrder, QueryText);
	
EndProcedure

&AtClient
Procedure LabelHeaderSalesOrdersClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	TitleText    = NStr("vi = 'Lệnh (%DocumentsCount%)';
						|ru = 'Распоряжения (%DocumentsCount%)';
						|en = 'References (%DocumentsCount%)'; fa = 'References (%DocumentsCount%)';
						|it = 'Disposizioni (%DocumentsCount%)';
						|pl = 'Zamówienia (%DocumentsCount%)';
						|tr = 'Talimatlar (%DocumentsCount%)'");
	OpeningParameters = New Structure("DocumentsList, Title", OrderList, TitleText);
	
	OpenForm("CommonForm.ViewingListOfDocuments",
					OpeningParameters,
					ThisObject,
					,
					,
					,
					Undefined,
					FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	NumberOfDiscrepancies = Object.Goods.Total("OrderDiscrepancy_3");
	
	If Not Object.ShipmentByOrders
		Or (ShipmentInExcessOfOrder
			And NumberOfDiscrepancies > 0) Then
		
		Notification = New CallbackDescription("DateOnChangeCompletion", ThisObject);
		EnterprisePricesFillingClient.AskQuestionAboutRecalculatingPriceWhenDateChanges(Object, Notification);
		
		Return;
		
	EndIf;
	
	DateWhenFragmentWasChanged(False);
	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	If Not ValueIsFilled(Object.Partner) Then
		SetVisibilityOfShipmentBanToPartner();
		GoodsDeliveryClientServer.ClearDeliveryDetails(Items,Object);
		
		UpdateDeliveryPlanningView(ThisObject);
		
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
	
	
	WhenChangingKeyDetailsStatusOfEDO();
	
EndProcedure

&AtClient
Procedure TermsOnChange(Item)
	
	If Not ValueIsFilled(Object.Terms) Then
		
		UpdateDeliveryPlanningView(ThisObject);
		
		Return;
	EndIf;
	
	WhenChangingAgreementAtServer();
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
	AgreementSelectionParameters.Organization           = Object.Organization;
	AgreementSelectionParameters.ConsignmentSales25 = False;
	AgreementSelectionParameters.BusinessOperation =
		PredefinedValue("Enum.BusinessTransactions.SaleToCustomer");
	
	SalesClient.StartSelectingAgreementWithClient(AgreementSelectionParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	WhenChangingKeyDetailsStatusOfEDO();
	
EndProcedure

&AtClient
Procedure TextShippingToAPartnerIsProhibitedClick(Item)
	
	OpeningParameters = New Structure("Partner", Object.Partner);
	
	OpenForm("Catalog.Partners.Form.FormOfSegmentsOfShipmentProhibition", OpeningParameters);
	
EndProcedure

&AtClient
Procedure ContractCreating(Item, StandardProcessing)
	
	SalesClient.OpenContractCreationForm(ThisObject,
		Item,
		"Object.Contract",
		Object.Partner,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	If Object.ShipmentByOrders And Contract <> Object.Contract Then
				
		UnlinkFromOrder = False;
		AnswersOptions = New ValueList;
		
		AnswersOptions.Add("UnlinkFromOrder", NStr("ru = 'Отвязать от заказа';
													|vi = 'Unlink from order';
													|en = 'Unlink from order'; fa = 'جدا کردن از سفارش';
													|it = 'Scollegare dall''ordine';
													|pl = 'Odłącz od zamówienia';
													|tr = 'Siparişten ayır'"));
		AnswersOptions.Add("Cancel", NStr("ru = 'Отмена';
											|vi = 'Cancel';
											|en = 'Cancel'; fa = 'انصراف';
											|it = 'Cancel';
											|pl = 'Cancel';
											|tr = 'İptal'"));
		QueryText = NStr("ru = 'При изменении договора документ будет отвязан от заказа. Продолжить?';
						|vi = 'If you change the contract, the document will be unlinked from the order. Continue?';
						|en = 'If you change the contract, the document will be unlinked from the order. Continue?'; fa = 'If you change the contract, the document will be unlinked from the order. Continue?';
						|it = 'If you change the contract, the document will be unlinked from the order. Continue?';
						|pl = 'If you change the contract, the document will be unlinked from the order. Continue?';
						|tr = 'Sözleşme değiştirildiğinde belge siparişten ayrılacaktır. Devam edilsin mi?'");
			
		ShowQueryBox(
			New CallbackDescription("ContractOnChangeCompletion",
				ThisObject,
				New Structure("UnlinkFromOrder", UnlinkFromOrder)),
			QueryText,
			AnswersOptions);
			
	Else
		
		ContractOnChangeServer();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ContractOnChangeCompletion(QuestionResult, AdditionalParameters) Export 
	
	ClearMessages();
	
	If QuestionResult = "Cancel" Then
		
		Object.Contract = Contract;
		
	ElsIf QuestionResult = "UnlinkFromOrder" Then
		
		Object.ShipmentByOrders = False;
		ShipmentForOrdersOnChangeATServer();
		
	EndIf;

	ContractOnChangeServer();

EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	If Warehouse <> Object.Warehouse Then
		
		If Object.ShipmentByOrders
			And Object.Goods.Count() > 0
			And Not OrdersAreUsedAsInvoices() Then
			
			If Not ItIsGroupOfWarehousesAndWarehousesUsedByWHForSale(Object.Warehouse) Then
				
				ButtonsList = New ValueList;
				
				If ShipmentInExcessOfOrder Then
					ButtonsList.Add("Continue", NStr("vi = 'Xóa hàng hóa';
													|ru = 'Очистить товары';
													|en = 'Clear goods'; fa = 'Clear goods';
													|it = 'Cancellare le merci';
													|pl = 'Oczyść wiersze pozycji';
													|tr = 'Ürünleri temizle'"));
					ButtonsList.Add("Unlink",   NStr("vi = 'Hủy liên kết với lệnh';
													|ru = 'Отвязать от распоряжения';
													|en = 'Unlink from reference'; fa = 'جدا کردن از مرجع';
													|it = 'Scollegare dalla disposizione';
													|pl = 'Odwiąż od dyspozycji';
													|tr = 'Emirden ayır'"));
					
					QueryText = NStr("vi = 'Khi thay đổi kho bãi, cần xóa hết danh sách ""Hàng hóa"", hoặc bỏ liên kết dòng khỏi lệnh. Tiếp tục?';
									|ru = 'При изменении склада список ""Товары"" необходимо очистить, либо отвязать строки от распоряжения. Продолжить?';
									|en = 'It is required to clear the ""Goods"" list or unlink lines from the reference while changing the warehouse. Continue?'; fa = 'It is required to clear the ""Goods"" list or unlink lines from the reference while changing the warehouse. Continue?';
									|it = 'It is required to clear the ""Goods"" list or unlink lines from the reference while changing the warehouse. Continue?';
									|pl = 'It is required to clear the ""Goods"" list or unlink lines from the reference while changing the warehouse. Continue?';
									|tr = 'Ambar değiştiğinde, ""Ürünler"" listesinin temizlenmesi veya satırların siparişten ayrılması gerekir. Devam edilsin mi?'")
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
				CallbackDescription = New CallbackDescription("WarehouseOnChangeCompletion",
					ThisObject, AdditionalParameters);
				
				ShowQueryBox(CallbackDescription, QueryText, ButtonsList);
				
				Return;
				
			EndIf;
			
		EndIf;
		
		WarehouseWhenFragmentChanges(False, False);
		
	EndIf;
	
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
	
	RegistrationParameters = ParametersForRegisteringInvoicesIssuedServer(Object);
	VATAccountingERPClient.ProcessingNavigationLinkInvoicesIssued(
		ThisObject,
		FormattedStringURL,
		StandardProcessing,
		RegistrationParameters);
	
	TextDocumentsBasedOnURLProcessingLocalization(
		Item, FormattedStringURL, StandardProcessing);
	
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(
		ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

#Region Delivery

&AtClient
Procedure DeliveryIsRequiredOnChange(Item)
	
	If Object.DeliveryIsRequired Then
		
		DeliverySettings = GoodsDeliveryClientServer.DefaultDeliverySettings();
		Object.DeliveryMethod25 = DeliverySettings.DeliveryMethod;
		UpdateDeliveryPlanningView(ThisObject, True);
		
	Else
		
		Object.DeliveryToCarrier = False;
		
	EndIf;
	
	SetAvailabilityVisibilityOfDeliveryItems(ThisObject);
	
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	
EndProcedure

#EndRegion

#Region Delivery20

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
	
	NamesOfDetailsOfDeliveryAddresses =
		GoodsDeliveryClientServer.NamesOfDetailsOfDeliveryAddresses("DeliveryAddress");
	
	GoodsDeliveryClient.ClearAddressPresentation(
		Object[NamesOfDetailsOfDeliveryAddresses.NameOfDetailsOfDeliveryAddress],
		Object[NamesOfDetailsOfDeliveryAddresses.AttributeNameOfDeliveryAddressFieldValues],
		Object[NamesOfDetailsOfDeliveryAddresses.NameOfAttributeOfDeliveryAddressValue]);
	
EndProcedure

&AtClient
Procedure DeliveryAddressStartChoice(Item, ChoiceData, StandardProcessing)
	
	NamesOfDetailsOfDeliveryAddresses =
		GoodsDeliveryClientServer.NamesOfDetailsOfDeliveryAddresses("DeliveryAddress");
	
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
	
	NamesOfDetailsOfDeliveryAddresses =
		GoodsDeliveryClientServer.NamesOfDetailsOfDeliveryAddresses("DeliveryAddressOfCarrier");
	
	GoodsDeliveryClient.ClearAddressPresentation(
		Object[NamesOfDetailsOfDeliveryAddresses.NameOfDetailsOfDeliveryAddress],
		Object[NamesOfDetailsOfDeliveryAddresses.AttributeNameOfDeliveryAddressFieldValues],
		Object[NamesOfDetailsOfDeliveryAddresses.NameOfAttributeOfDeliveryAddressValue]);
	
EndProcedure

&AtClient
Procedure DeliveryAddressOfCarrierStartChoice(Item, ChoiceData, StandardProcessing)
	
	NamesOfDetailsOfDeliveryAddresses =
		GoodsDeliveryClientServer.NamesOfDetailsOfDeliveryAddresses("DeliveryAddressOfCarrier");
	
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

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
	
EndProcedure
// End StandardSubsystems.Properties

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
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
Procedure VATTaxationOnChange(Item)
	VATTaxationOnChangeServer();
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();
	
EndProcedure

&AtClient
Procedure TextAllowedCreditBalanceClick(Item, StandardProcessing)
	
	ARAPAccountingClient.DebtLimitsClick(ThisObject, Item, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData; 
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;;
	OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, Object.ShipmentByOrders);
	BatchProcessingOfTablePartClient.ProcessTSString(
		CurrentRow,
		StructureOfActions,
		Undefined);
	
	UpdateDependentDetailsOfOrderForm_(ThisObject, DiscrepancyOrderText);
	
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
		
		If ValueIsFilled(CurrentRow.ProductsInSet)
			And (Not Object.ShipmentByOrders
				Or CurrentRow.RowCode = 0) Then
			
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
	
	If Object.ShipmentByOrders
		And Not ShipmentInExcessOfOrder Then
		
		Cancel = True;
		OpenSelectionByOrdersAndOrders();
		
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
	
	If NewRow And Not UseShipmentForMultipleOrders Then
		CurrentRow.SalesOrder = Object.SalesOrder;
	ElsIf NewRow Then
		CurrentRow.SalesOrder = Undefined;
	EndIf;
	
	If Copy Then
		
		CurrentRow.SalesOrder = Undefined;
		CurrentRow.RowCode = 0;
		CurrentRow.DeliveryLineCode = 0;
		CurrentRow.Purpose = Undefined;
		
		StructureOfActions = New Structure;
		OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, Object.ShipmentByOrders);
		BatchProcessingOfTablePartClient.ProcessTSString(
			CurrentRow,
			StructureOfActions,
			Undefined);
		
		UpdateDependentDetailsOfOrderForm_(ThisObject, DiscrepancyOrderText);
		
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
	
	ServerHandlers = New Structure;
	ServerHandlers.Insert("ServerCallRequired__", False);
	FormEventsClient.WhenChangingElement(ThisObject, Items.Goods, ServerHandlers);
	ServerHandlers.Insert("UpdateSeriesStatuses", UpdateSeriesStatuses);
	
	If UpdateSeriesStatuses Or ServerHandlers.ServerCallRequired__ Then
		
		IDCurrentRow = CurrentData.GetID();
		GoodsAtEndOfEditingOnServer(IDCurrentRow, ServerHandlers, CachedValues);
		
		ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters);
		
	EndIf;
	
	UpdateDependentDetailsOfOrderForm_(ThisObject, DiscrepancyOrderText);
	
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
Procedure GoodsWithAssignmentOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	LinesOfBusinessClient.GoodsWithAssignmentOnChange(ThisObject, CurrentData);
	
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
	
EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	
	If CurrentRow.Count > 0 Then
		StructureOfActions.Insert("RecalculatePricePerPackage", CurrentRow.Count);
	Else
		
		AddPriceFillingActionsToStructure(
			StructureOfActions,
			Object,
			ToUseTermsOfSales,
			UsePriceManagementSystem25);
		
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsPriceKindOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	FillInSalePrice = BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInSalePrice", FillInSalePrice);
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object, False);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsPriceOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object, False);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsSumOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePriceByAmount");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsWarehouseOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	AdditionalParameters = AdditionalCompletionProcessingParameters();
	AdditionalParameters.CurrentRow = CurrentRow;
	CallbackDescription = New CallbackDescription("GoodsWarehouseWhenChangingQuestionToUserCompletion",
														ThisObject,
														AdditionalParameters);
	
	QuestionUserWhenChangingRowDetails(CallbackDescription, CurrentRow);
	
EndProcedure

&AtClient
Procedure GoodsSalesOrderStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData <> Undefined Then
		
		CallbackDescription = New CallbackDescription("GoodsSalesOrderStartChoiceCompletion", ThisObject);
		OpenOrderSelection(CallbackDescription);
		Return;
		
	EndIf;
	
	UpdateOrderInformation();
	
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
	
	TMCommonUseClient.Write(ThisObject, True);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject, True);
	
EndProcedure

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
								|tr = 'İşlemin gerçekleştirilmesi için belgenin kaydedilmesi gerekmektedir. Belge kaydedilsin mi?'");
		
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		
		Return;
		
	EndIf;
	
	CloseOrderFragment();
	
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

&AtClient
Procedure PrintDetails(Item)
	
	OpenShipmentPrintingAttributes();
	
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
	TableData = Object.Goods;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.StructureOfRecalculationOfAmount(
		"Count, Sum", "NumberOfPackages");
	
	If FormTable.CurrentData <> Undefined Then
		
		BatchProcessingOfTablePartClientServer.FillInStructureForRecalculatingAmount(
			StructureOfRecalculationOfAmount,
			FormTable.CurrentData);
		
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("StructureOfRecalculationOfAmount", StructureOfRecalculationOfAmount);
	
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable,
		New CallbackDescription("SplitRowCompletion", ThisObject, AdditionalParameters));
	
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
	KitParameters.Insert("DialColumns",        DialColumns(ThisObject));
	
	SetAddressInTemporaryStorage = SetAddressInTemporaryStorage(KitParameters);
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("Ref",          Object.Ref);
	OpeningParameters.Insert("Date",            Object.Date);
	OpeningParameters.Insert("Partner",         Object.Partner);
	OpeningParameters.Insert("Terms",      Object.Terms);
	OpeningParameters.Insert("Warehouse",           Object.Warehouse);
	OpeningParameters.Insert("Currency",          Object.Currency);
	OpeningParameters.Insert("PriceIncludesVAT", True);
	
	OpeningParameters.Insert("ProductsInSet",   CurrentRow.ProductsInSet);
	OpeningParameters.Insert("ItemVariantOfSet", CurrentRow.ItemVariantOfSet);
	OpeningParameters.Insert("SalesOrder", CurrentRow.SalesOrder);
	
	OpeningParameters.Insert("HideCommandRemainingQuantityInWarehouses", False);
	OpeningParameters.Insert("AddressInTempStorage",       SetAddressInTemporaryStorage);
	
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
Procedure ImportDataFromPDT(Command)
	
	Notification = New CallbackDescription("DownloadFromTSDCompletion", ThisObject);
	
	EquipmentManagerClient.StartDownloadingDataFromTSD(Notification, UUID);
	
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
Procedure CheckQuantityInTheDocument(Command)
	
	AddressOfTheGoodsInTheTemporaryStorage = PutTablePartOfGoodsInTemporaryStorageToCheckQuantity();
	GoodsQuantityExcessIsAllowed = Not Object.ShipmentByOrders Or ShipmentInExcessOfOrder;
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("Ref",            Object.Ref);
	OpeningParameters.Insert("TabularSectionName", "Goods");
	
	OpeningParameters.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters);
	OpeningParameters.Insert("CalculateSets",     True);
	
	OpeningParameters.Insert("AddressInTempStorage", AddressOfTheGoodsInTheTemporaryStorage);
	OpeningParameters.Insert("GoodsQuantityExcessIsAllowed",
								GoodsQuantityExcessIsAllowed);
	
	CallbackDescription = New CallbackDescription("CheckQuantityInTheDocumentCompletion", ThisObject);
	
	OpenForm("CommonForm.CheckDocumentPopulation",
					OpeningParameters,
					ThisObject,
					,
					,
					,
					CallbackDescription,
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

&AtClient
Procedure SpecifySeries(Command)
	
	OpenSelectionOfSeries();
	
EndProcedure

&AtClient
Procedure OpenSelection(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.GoodsShipmentToCustomer.DocumentForm.Command.OpenSelection");
	
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
	
	HeaderParameter_ = NStr("vi = 'Lựa chọn hàng hóa vào %Document%';
							|ru = 'Подбор товаров в %Document%';
							|en = 'Pick goods in %Document%'; fa = 'Pick goods in %Document%';
							|it = 'Selezione merci in %Document%';
							|pl = 'Wybór towarów w %Document%';
							|tr = '%Document% içindeki ürünlerin seçimi'");
	
	If ValueIsFilled(Object.Ref) Then
		HeaderParameter_ = StrReplace(HeaderParameter_, "%Document%", Object.Ref);
	Else
		HeaderParameter_ = StrReplace(HeaderParameter_, "%Document%", NStr("vi = 'giao hàng cho khách';
																			|ru = 'отгрузку товаров клиенту';
																			|en = 'goods shipment to customer'; fa = 'goods shipment to customer';
																			|it = 'goods shipment to customer';
																			|pl = 'goods shipment to customer';
																			|tr = 'müşteri ürünlerinin sevkiyatı'"));
	EndIf;
	
	FilterByProductType = New Array;
	FilterByProductType.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
	FilterByProductType.Add(PredefinedValue("Enum.ItemsTypes.Set"));
	
	FormParameters = New Structure;
	FormParameters.Insert("Document",           Object.Ref);
	FormParameters.Insert("Title",          HeaderParameter_);
	FormParameters.Insert("Date",               Object.Date);
	FormParameters.Insert("Terms",         Object.Terms);
	FormParameters.Insert("Partner",            Object.Partner);
	FormParameters.Insert("Organization",        Object.Organization);
	FormParameters.Insert("Warehouse",              Object.Warehouse);
	FormParameters.Insert("Currency",             Object.Currency);
	FormParameters.Insert("PriceIncludesVAT",    True);
	FormParameters.Insert("VATTaxation", Object.VATTaxation);
	
	FormParameters.Insert("FilterByProductType", New FixedArray(FilterByProductType));
	FormParameters.Insert("SeriesSpecificationParameters",  SeriesSpecificationParameters);
	
	FormParameters.Insert("SelectionModeUseWarehousesInTabularSection", True);
	FormParameters.Insert("SelectionModeExcludeGroupsAvailableInOrders",  True);
	
	FormParameters.Insert("HideManualDiscounts", True);
	
	FormParameters.Insert("LineOfBusiness", Object.LineOfBusiness);
	
	OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form",
					FormParameters,
					ThisObject,
					UUID);
	
EndProcedure

&AtClient
Procedure SelectGoodsByOrdersNotes(Command)
	
	OpenSelectionByOrdersAndOrders();
	
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
Procedure ImportFromExternalFile(Command)
	
	ArrayOfProductTypes = New Array;
	ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
	ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.Set"));
	
	ImportParameters = ProcessingOfTabularFormsClient.ProductLoadingParameters();
	ImportParameters.ImportPrices                        = True;
	ImportParameters.Organization                          = Object.Organization;
	ImportParameters.PriceIncludesVAT                      = True;
	ImportParameters.VATTaxation                   = Object.VATTaxation;
	ImportParameters.ComponentsPriceParameters.Date       = Object.Date;
	ImportParameters.ComponentsPriceParameters.Currency     = Object.Currency;
	ImportParameters.ComponentsPriceParameters.Terms = Object.Terms;
	ImportParameters.FilterParameters.Insert("ItemsType", ArrayOfProductTypes);
	
	Notification = New CallbackDescription("ImportFromExternalFileCompletion", ThisObject);
	ProcessingOfTabularFormsClient.ShowProductUploadForm(ImportParameters, Notification);

EndProcedure

&AtClient
Procedure FillThePricesByTermsOfSales(Command)
	
	If EnterprisePricesFillingClient.ItIsNecessaryToFillInPricesByAgreement(Object, "Goods", NStr("vi = 'Hàng hóa';
																									|ru = 'Товары';
																									|en = 'Items'; fa = 'اقلام';
																									|it = 'Merci';
																									|pl = 'Towary';
																									|tr = 'Ürünler'")) Then
		
		If ShipmentInExcessOfOrder
			And Not DeviationFromShipmentConditions Then
			
			If Object.ShipmentByOrders
				And Object.Goods.Total("OrderDiscrepancy_3") = 0 Then
				
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
		
		PriceSelectionOptions.OwnerOfAnIndividualPriceType =
			?(ToUseTermsOfSales,Object.Terms,Object.Partner);
		
		EnterprisePricesFillingClient.ChooseTypeOfPrices(PriceSelectionOptions);
		
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
	EndIf;
	
EndProcedure

#EndRegion

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
		Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#Region Delivery

&AtClient
Procedure EditDeliveryParameters(Command)
	
	If Object.Partner.IsEmpty() Then
		
		ErrorText = CommonClientServer.FillingErrorText(
			"Field",
			"FillType",
			"Partner");
		
		CommonClient.MessageToUser(
			ErrorText,
			,
			"Object.Partner");
		
		Return;
		
	EndIf;
	
	OpenDeliverySettings();
	
EndProcedure

#EndRegion

#Region Delivery20

&AtClient
Procedure SupplementDeliveryInformationWithContacts(Command)
	
	SupplementDeliveryInformationWithContactsServer();
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

&AtServer
Procedure UpdateTextDocumentsBasedOn()
	
	TextsFieldsDocumentsBasedOn.Clear();
	UpdateTextOfInvoiceIssued();
	UpdateTextDocumentsBasedOnLocalization();
	TMCommonUseClientServer.UpdateTextDocumentsBasedOn(ThisObject);
	
EndProcedure

#Region OnChangeAttributes

&AtServer
Procedure MethodPlaceOfDeliveryCarrierIfChangedServer(ItemName)
	
	GoodsDelivery.FillInDeliveryDetails(Items, ItemName, Object);
	UpdateTextDocumentsBasedOn();

EndProcedure

&AtServer
Procedure ShipmentForOrdersOnChangeATServer()
	
	If Object.ShipmentByOrders Then
		
		If Object.Goods.Count() = 0 Then
			FillInFromOrderServer();
		Else
			UnlinkFromOrderServer(True, False); // it is necessary to reset the line code to zero
			LinkShipmentLinesToOrders(Not UseShipmentForMultipleOrders);
		EndIf;
		
	Else
		
		OrderList.Clear();
		UnlinkFromOrderServer(True, False);
		
		Object.SalesOrder = Undefined;
		
	EndIf;
	
	UpdateDeliveryPlanningView(ThisObject);
	UpdateOrderInformation();
	UpdateOrderDeviations();
	UpdateDependentDetailsOfServerByOrderForm();
	SetElementProperties();
	
	GoodsDelivery.WhenChangingFlagForOrders(Items, Object, Object.ShipmentByOrders);
	SetAvailabilityVisibilityOfDeliveryItems(ThisObject);
	LinesOfBusinessServer.SetVisibilityOfElementsSeparately(ThisObject);
	
	AttributesArray = New Array;
	AttributesArray.Add("ShipmentByOrders");
	AttributesArray.Add("ARAPObjectSettings");
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, AttributesArray);
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisObject);
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	
EndProcedure

&AtServer
Procedure DateOnChangeServer(RecalculatePrices_, PricesCalculated)
	
	If RecalculatePrices_ Then
		PricesCalculated = FillThePricesByTermsOfSalesServer(True);
	Else
		PricesCalculated = False;
	EndIf;
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();
	
	AdvancedWarehousingOnShipment = AdvancedWarehousingOnShipment();
	
	DocumentDate = ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate());
	
	Object.LocalConversionRatio = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
		Object.Currency, LocalAccountingCurrency, DocumentDate);
	
	HowToSetSeriesVisibility();
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	SetElementProperties();
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Date");
	
EndProcedure

&AtServer
Procedure PartnerOnChangeServer()
	
	DirectionsOfActivity = Object.LineOfBusiness;
	
	DocumentSales = FormAttributeToValue("Object");
	DocumentSales.FillInDefaultSalesConditions();
	ResponsiblePersonsServer.FillInManager_(DocumentSales);
	ValueToFormAttribute(DocumentSales, "Object");
	
	If ValueIsFilled(Object.Terms) Then
		DocumentCurrency = Object.Currency;
	EndIf;
	
	FillInSubordinatePropertiesForStatistics("Counterparty");
	SetVisibilityOfShipmentBanToPartner();
	
	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible,
		Object.Contract);
	
	FillInDefaultContract();
	WarehouseOnChangeServer();
	
	FillInServiceDetailsForProductRange();
	
	GoodsDelivery.FillInDeliveryDetails(Items, "Partner", Object);
	
	SalesServer.PartnerOnChange(Object);
	
	FillBaseForPrinting();
	
	If UseLinesOfBusiness Then
		
		LinesOfBusinessServer.FillInDefaultDirection(
				Object.LineOfBusiness,
				Object.Terms,
				Object.Contract);
		
		If DirectionsOfActivity <> Object.LineOfBusiness Then
			LineOfBusinessOnChangeServer();
		EndIf;
	
	EndIf;
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	SetElementProperties();
	
	UpdateDeliveryPlanningView(ThisObject);
	GoodsShipmentToCustomerLocalization.PartnerOnChange(ThisObject);
	AttributesArray = New Array;
	AttributesArray.Add("Currency");
	AttributesArray.Add("Partner");
	AttributesArray.Add("Contract");
	AttributesArray.Add("LineOfBusiness");
	AttributesArray.Add("Counterparty");
	AttributesArray.Add("Organization");
	AttributesArray.Add("Terms");
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, AttributesArray);
	
	SalesServer.SetContractAvailability(Object,
		Items.Contract.Enabled,
		Items.Contract.Visible,
		Object.Contract);
	
	Items.GroupLabelContract.Visible = Items.Contract.Visible
		And Not Object.ShipmentByOrders;
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	
	DirectionsOfActivity = Object.LineOfBusiness;
	
	If ValueIsFilled(Object.Counterparty) Then
		FillInDefaultContract();
		
		SalesServer.PartnerOnChange(Object);
	EndIf;
	
	FillInSubordinatePropertiesForStatistics("Counterparty");
	
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
	
	UpdateTextDocumentsBasedOn();
	SetElementProperties();
	GoodsShipmentToCustomerLocalization.CounterpartyOnChange(ThisObject);
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Counterparty");
	
	SalesServer.SetContractAvailability(Object,
		Items.Contract.Enabled,
		Items.Contract.Visible,
		Object.Contract);
	
	Items.GroupLabelContract.Visible = Items.Contract.Visible
		And Not Object.ShipmentByOrders;
	
EndProcedure

&AtServer
Procedure WhenChangingAgreementAtServer()
	
	DirectionsOfActivity = Object.LineOfBusiness;
	
	DocumentSales = FormAttributeToValue("Object");
	DocumentSales.FillInTermsOfSalesUnderAgreement();
	ResponsiblePersonsServer.FillInManager_(DocumentSales);
	ValueToFormAttribute(DocumentSales, "Object");
	
	If Object.Organization = Catalogs.Companies.ManagementCompany Then
		
		Object.DeliveryIsRequired = False;
		SetAvailabilityVisibilityOfDeliveryItems(ThisObject);
		
	EndIf;
	
	DocumentCurrency = Object.Currency;
	
	If Contract <> Object.Contract Then
		Contract = Object.Contract;
		ContractOnChangeServer();
		FillBaseForPrinting();
	EndIf;
	
	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible,
		Object.Contract);
	
	WarehouseOnChangeServer();
	
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
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	SetElementProperties();
	
	UpdateDeliveryPlanningView(ThisObject);
	
	SalesServer.SetContractAvailability(Object,
		Items.Contract.Enabled,
		Items.Contract.Visible,
		Object.Contract);
	
	Items.GroupLabelContract.Visible = Items.Contract.Visible
		And Not Object.ShipmentByOrders;
	
	AttributesArray = New Array;
	AttributesArray.Add("Currency");
	AttributesArray.Add("Partner");
	AttributesArray.Add("Contract");
	AttributesArray.Add("LineOfBusiness");
	AttributesArray.Add("Counterparty");
	AttributesArray.Add("Organization");
	AttributesArray.Add("Terms");
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, AttributesArray);
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	DirectionsOfActivity = Object.LineOfBusiness;
	
	LocalAccountingCurrency =
		SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	If ValueIsFilled(Object.Organization) Then
		
		FillInDefaultContract();
		
		FillInSalesVATTaxation();
		VATTaxationOnChangeServer();
		
	EndIf;
	
	If ValueIsFilled(Object.Terms)
		And Common.ObjectAttributeValue(Object.Terms, "Organization") <> Object.Organization Then
		Object.Terms = Catalogs.TermsOfSale.EmptyRef();
	EndIf;
	
	CashServer.CheckFillInOrganizationSBankAccountByOwner(Object.Organization,
		Object.CompanyBankAccount, Undefined, Object.LineOfBusiness);
	
	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible,
		Object.Contract);
	
	FillInSubordinatePropertiesForStatistics("Organization");
	
	If UseLinesOfBusiness Then
		
		LinesOfBusinessServer.FillInDefaultDirection(
				Object.LineOfBusiness,
				Object.Terms,
				Object.Contract);
		
		If DirectionsOfActivity <> Object.LineOfBusiness Then
			LineOfBusinessOnChangeServer();
		EndIf;
	
	EndIf;
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	UpdateTextDocumentsBasedOn();
	SetElementProperties();
	
	SalesServer.SetContractAvailability(Object,
		Items.Contract.Enabled,
		Items.Contract.Visible,
		Object.Contract);
	
	Items.GroupLabelContract.Visible = Items.Contract.Visible
		And Not Object.ShipmentByOrders;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Organization");
	
	If Object.Organization = Catalogs.Companies.ManagementCompany Then
		Object.DeliveryIsRequired = False;
	EndIf;
	SetAvailabilityVisibilityOfDeliveryItems(ThisObject);
	
EndProcedure

&AtServer
Procedure ContractOnChangeServer()
	
	DirectionsOfActivity = Object.LineOfBusiness;
	
	BasisChanged = BasisChanged And ValueIsFilled(Object.Basis);
	
	Contract = Object.Contract;
	
	ContractDetails_ = New Structure("Currency, LineOfBusiness, Department", "ARAPCurrency");
	Catalogs.CounterpartyContracts.FillInDocumentDetails(Object, Object.Contract, ContractDetails_);
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();
	
	SalesServer.FillInBankAccountsUnderAgreement(Object.Contract,
		Object.CompanyBankAccount, Object.CounterpartyBankAccount);
		
	ResponsiblePersonsServer.FillInManager_(Object);
	FillInSubordinatePropertiesForStatistics("Contract");
	
	If UseLinesOfBusiness Then
		
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
	SetElementProperties();
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Contract");
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisObject);
	
	WhenChangingKeyDetailsStatusOfEDO();
	
EndProcedure

&AtServer
Procedure WarehouseOnChangeServer(ClearLines_ = True, UntieAllLinesFromOrder = False)
	
	Warehouse       = Object.Warehouse;
	WarehouseGroup_ = ItIsGroupOfWarehousesAndWarehousesUsedByWHForSale(Object.Warehouse);
	
	SetParametersForSelectingProductsWarehouse();
	
	If ClearLines_
		And Not WarehouseGroup_
		And Object.ShipmentByOrders
		And Object.Goods.Count() > 0 Then
		
		Object.Goods.Clear();
		
	EndIf;
	
	If UntieAllLinesFromOrder Then
		UnlinkFromOrderServer();
	EndIf;
	
	Items.GoodsFillInTheWarehouseInSelectedLines.Enabled = WarehouseGroup_;
	WarehousesServer.FillInWarehousesInTablePart(Object.Warehouse, WarehouseGroup_, Object.Goods, True);
	
	UpdateOrderInformation();
	SetTitleFillInByOrdersOrders();
	WhenChangingWarehouseInTablePartServer();
	HowToSetSeriesVisibility();

	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();
	
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
		LocalAccountingCurrency, DocumentDate);
	
EndProcedure

&AtServer
Procedure ContactPersonOnChangeServer(PartnerChanged_)
	
	OwnerOfContactPerson = Common.ObjectAttributeValue(Object.ContactPerson,
																					"Owner");
	
	If OwnerOfContactPerson <> Object.Partner Then
		PartnerChanged_ = True;
		Object.Partner  = OwnerOfContactPerson;
		
		PartnerOnChangeServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure VATTaxationOnChangeServer()
	
	If Object.Patch Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInHSCode", Object.VATTaxation);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
	VATAccountingERP.EstablishVisibilityOfCountryOfImplementation(ThisObject);
	
EndProcedure

&AtServer
Procedure LineOfBusinessOnChangeServer()
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();

	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "LineOfBusiness");
	
EndProcedure

&AtServer
Procedure WhenChangingKeyDetailsStatusOfEDO()
	
	
EndProcedure

#EndRegion

#Region ProceduresForNotificationDescriptions

&AtClient
Procedure ShipmentByOrdersOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	SalesOrder = AdditionalParameters.SalesOrder;
	
	If QuestionResult = DialogReturnCode.No Then
		Object.ShipmentByOrders = Not Object.ShipmentByOrders;
		
		Return;
	EndIf;
	
	If ValueIsFilled(SalesOrder) Then
		Object.SalesOrder = SalesOrder;
	EndIf;
	
	ShipmentForOrdersOnChangeATServer();
	
EndProcedure

&AtClient
Procedure DateOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	If Not QuestionResult = DialogReturnCode.Cancel Then
		DateWhenFragmentWasChanged(QuestionResult);
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

// Goods nomenclature when changing the question to the user completion.
// 
// Parameters:
//	Result - Boolean
//	AdditionalParameters - Structure - 
&AtClient
Procedure GoodsNomenclatureWhenChangingQuestionToUserCompletion(Result,
	                                                                 AdditionalParameters) Export
	
	If Not Result
		And ShipmentInExcessOfOrder Then
		
		Return;
		
	EndIf;
	
	CurrentRow = AdditionalParameters.CurrentRow;
	
	FillInArticleAttribute         = New Structure("Products", "SKU");
	FillInProductTypeAttribute_ = New Structure("Products", "ItemsType");
	
	CheckSeriesCalculateStatus = New Structure;
	CheckSeriesCalculateStatus.Insert("Warehouse",                  Object.Warehouse);
	CheckSeriesCalculateStatus.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters);
	
	CheckFillWarehouse = BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(
		Object, WarehouseGroup_);
	
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
	StructureOfActions.Insert("FillInHSCode",                     Object.VATTaxation);
	
	StructureOfActions.Insert("ProductsOnChangeOverridable",
		ProductsOnChangeOverridable);
	
	AddActionsToStructureWhenChangingPackagesNumber(
		StructureOfActions,
		Object);
	
	AddPriceFillingActionsToStructure(
		StructureOfActions,
		Object,
		ToUseTermsOfSales,
		UsePriceManagementSystem25);
	
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(
		ThisObject,
		StructureOfActions);
	
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Products", StructureOfActions);
	
	OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, Object.ShipmentByOrders);
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	BatchProcessingOfTablePartClient.ProcessTSString(
		CurrentRow,
		StructureOfActions,
		CachedValues);
	
	FillPropertyValues(PreviousRowDetails, CurrentRow);
	
EndProcedure

// Goods characteristic when changing the question to the user completion.
// 
// Parameters:
//	Result - Boolean
//	AdditionalParameters - Structure -
//
&AtClient
Procedure GoodsCharacteristicWhenChangingQuestionToUserCompletion(Result,
																				AdditionalParameters) Export
	
	If Not Result
		And ShipmentInExcessOfOrder Then
		
		Return;
		
	EndIf;
	
	CurrentRow = AdditionalParameters.CurrentRow;
	
	CharacteristicOnChangeOverridable = New Structure;
	CharacteristicOnChangeOverridable.Insert("FormName",          FormName);
	CharacteristicOnChangeOverridable.Insert("TabularSectionName", "Goods");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CharacteristicOnChangeOverridable",
		CharacteristicOnChangeOverridable);
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object, False);
	AddPriceFillingActionsToStructure(StructureOfActions,
													Object,
													ToUseTermsOfSales,
													UsePriceManagementSystem25);
	
	If AdditionalParameters.LineDetachedFromOrder Then
		LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject,
			StructureOfActions);
	EndIf;
	
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Characteristic", StructureOfActions);
	
	OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, Object.ShipmentByOrders);
	
	BatchProcessingOfTablePartClient.ProcessTSString(
		CurrentRow,
		StructureOfActions,
		CachedValues);
	
EndProcedure

// Parameters:
// 	Result - Boolean - 
// 	AdditionalParameters - See AdditionalCompletionProcessingParameters
&AtClient
Procedure GoodsWarehouseWhenChangingQuestionToUserCompletion(Result,
																		AdditionalParameters) Export
	
	If Not Result
		And ShipmentInExcessOfOrder Then
		
		WhenChangingWarehouseInTablePartServer();
		Return;
		
	EndIf;
	
	CurrentRow = AdditionalParameters.CurrentRow;
	
	CheckSeriesCalculateStatus = New Structure;
	CheckSeriesCalculateStatus.Insert("Warehouse",                  Object.Warehouse);
	CheckSeriesCalculateStatus.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckSeriesCalculateStatus", CheckSeriesCalculateStatus);
	
	If AdditionalParameters.LineDetachedFromOrder Then
		LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject,
			StructureOfActions);
	EndIf;
	
	OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, Object.ShipmentByOrders);
	
	BatchProcessingOfTablePartClient.ProcessTSString(
		CurrentRow,
		StructureOfActions,
		CachedValues);
	
	UpdateDependentDetailsOfOrderForm_(ThisObject, DiscrepancyOrderText);
	
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
Procedure GoodsSalesOrderStartChoiceCompletion(Result, AdditionalParameters) Export
	
	Items.Goods.CurrentData.SalesOrder = Result;
	
	UpdateOrderInformation();
	
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

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export 
	
	CurrentRow = Items.Goods.CurrentData;
	
	If NewRow <> Undefined Then
		
		If Not Object.ShipmentByOrders Then
			NewRow.RowCode = 0;
		EndIf;
		
		NewRow.DeliveryLineCode = 0;
		
		StructureOfRecalculationOfAmount = AdditionalParameters.StructureOfRecalculationOfAmount;
		
		BatchProcessingOfTablePartClientServer.AddLineToRecalculateAmount(
			StructureOfRecalculationOfAmount,
			CurrentRow);
		
		BatchProcessingOfTablePartClientServer.AddLineToRecalculateAmount(
			StructureOfRecalculationOfAmount,
			NewRow);
		
		BatchProcessingOfTablePartClientServer.RecalculateAmounts(StructureOfRecalculationOfAmount);
		
		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
		
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
Procedure CompleteSeriesOnFEFOCompletion(Result, AdditionalParameters) Export 
	
	If Not Result Then
		Return;
	EndIf;
	
	If Not FillInSeriesByFEFOServer() Then
		ProductsClient.WarnAboutAbsenceOfLinesFilledByFEFO();
	EndIf;

EndProcedure

&AtClient
Procedure FillInPricesOfSelectedRowsByPriceTypeCompletion(PricesKind, AdditionalParameters) Export
	
	If ValueIsFilled(PricesKind) Then
		
		RowsArray = New Array;
		
		For Each CurRow In Items.Goods.SelectedRows Do
			
			FoundRow = Object.Goods.FindByID(CurRow);
			
			If DeviationFromShipmentConditions
				Or (ShipmentInExcessOfOrder
					And FoundRow.RowCode = 0) Then
				
				RowsArray.Add(FoundRow);
				
			EndIf;
			
		EndDo;
		
		If RowsArray.Count() = 0
			And ShipmentInExcessOfOrder
			And Object.ShipmentByOrders
			And Not DeviationFromShipmentConditions Then
			
			WarningText = NStr("vi = 'Không thể gán đơn giá vào các dòng theo lệnh.';
								|ru = 'Цена не может быть назначена в строках по распоряжению.';
								|en = 'Price cannot be assigned in the reference lines.'; fa = 'Price cannot be assigned in the reference lines.';
								|it = 'Price cannot be assigned in the reference lines.';
								|pl = 'Price cannot be assigned in the reference lines.';
								|tr = 'Fiyat, sipariş satırlarına atanamıyor.'");
			
			ShowMessageBox(Undefined, WarningText);
			
			Return;
			
		EndIf;
		
		PricesCalculated = FillInPricesOfSelectedRowsByPriceTypeServer(PricesKind);
		SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, PricesKind);
		
	EndIf;
	
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

&AtClient
Procedure ImportFromExternalFileCompletion(ImportedDataAddress, AdditionalParameters) Export
	
	If ValueIsFilled(ImportedDataAddress) Then
		GetUploadedProductsFromStorage(ImportedDataAddress);
	EndIf;
	
EndProcedure

#EndRegion


#Region WorkingWithClipboard

&AtClient
Procedure SetAvailabilityOfClipboardCommandsOnClient()
	
	ItemArray = New Array();
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsContextMenuInsertRows");

	TMCommonUseClientServer.SetPropertyOfFormElements(Items,
																				ItemArray,
																				"Enabled",
																				Not Object.ShipmentByOrders
																					Or ShipmentInExcessOfOrder);
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfClipboardCommands()
	
	ItemArray = New Array();
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsContextMenuInsertRows");

	TMCommonUseClientServer.SetPropertyOfFormElements(Items,
		ItemArray,
		"Enabled",
		ProcessingOfTabularForms.ThereAreLinesInClipboard()
			And (Not Object.ShipmentByOrders
				Or ShipmentInExcessOfOrder));
	
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
	ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.Set"));
	
	FilterParameters = New Map;
	FilterParameters.Insert("Products.ItemsType", ArrayOfProductTypes);
	
	Columns =
		"Products,Characteristic,Package,NumberOfPackages,
		|Sum,AmountIncludingVAT,Warehouse,ProductsInSet,ItemVariantOfSet";
	
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
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_",
		New Structure("Products", "ItemsType"));
	
	StructureOfActions.Insert("CheckFillWarehouse",
		BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(
			Object,
			WarehouseGroup_));
	
	AddActionRecalculateNumberOfUnits(StructureOfActions);
	StructureOfActions.Insert("RecalculatePriceByAmount");
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject,
																								StructureOfActions);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, Object.ShipmentByOrders);
	
	RowsToProcess = New Array();
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);
		
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
	
	CheckFillWarehouse = BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(
		Object,
		WarehouseGroup_);
	
	StructureOfActionsWithAddedStrings = New Structure;
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", FillInArticleAttribute);
	StructureOfActionsWithAddedStrings.Insert("CheckFillWarehouse", CheckFillWarehouse);
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_",
		FillInProductTypeAttribute_);
	
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Products", StructureOfActionsWithAddedStrings);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithAddedStrings,
		Object);
	
	AddPriceFillingActionsToStructure(StructureOfActionsWithAddedStrings,
											Object,
											ToUseTermsOfSales,
											UsePriceManagementSystem25);
	
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject,
		StructureOfActionsWithAddedStrings);
	
	StructureOfActionsWithModifiedStrings = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithModifiedStrings,
		Object);
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	StructureOfActions.SeriesSpecificationParameters                 = SeriesSpecificationParameters;
	StructureOfActions.GoodsOnly                           = True;
	StructureOfActions.CalculateSets                     = True;
	StructureOfActions.AddContainers                         = False;
	StructureOfActions.UseContainersAsGoods        = False;
	StructureOfActions.AddOnlyProductsOverAndAboveOrder        = True;
	
	ProcessBarcodesServer(StructureOfActions, CachedValues);
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(StructureOfActions, CachedValues, ThisObject);
	
	OpenSeriesIndicationForm =
		BarcodingOfItemsClient.YouNeedToOpenFormForSpecifyingSeriesAfterProcessingBarcodes(
		StructureOfActions);
	
	If OpenSeriesIndicationForm Then
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
	UpdateOrderDeviations();
	UpdateDependentDetailsOfServerByOrderForm();
	
EndProcedure

#EndRegion

#Region Sets

&AtServer
Procedure AtEndOfEditingSet(AddressInTempStorage)
	
	Data = GetFromTempStorage(AddressInTempStorage);
	
	StructureOfActionsWithModifiedStrings = New Structure;
	
	FillInArticleAttribute                    = New Structure("Products", "SKU");
	FillInProductTypeAttribute_            = New Structure("Products", "ItemsType");
	FillInFeatureAttribute = New Structure("Products",
																			"ItemVariantsAreUsed");
	
	CheckFillWarehouse = BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(
		Object,
		WarehouseGroup_);
	
	StructureOfActionsWithAddedStrings = Common.CopyRecursive(
		StructureOfActionsWithModifiedStrings);
	
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", FillInArticleAttribute);
	
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_",
															FillInProductTypeAttribute_);
	
	StructureOfActionsWithAddedStrings.Insert("FillInFeatureAttribute",
															FillInFeatureAttribute);
	
	StructureOfActionsWithAddedStrings.Insert("CheckFillWarehouse", CheckFillWarehouse);
	
	DataParameters = New Structure;
	DataParameters.Insert("Data",                                 Data);
	DataParameters.Insert("ExceedingOrder",                            True);
	DataParameters.Insert("DialColumns",                          DialColumns(ThisObject));

	DataParameters.Insert("StructureOfActionsWithModifiedStrings",
									StructureOfActionsWithModifiedStrings);

	DataParameters.Insert("StructureOfActionsWithAddedStrings",
									StructureOfActionsWithAddedStrings);
	
	SetsServer.AtEndOfEditingSet(ThisObject, "Goods", DataParameters);
	
	UpdateOrderDeviations();
	
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
	
	UpdateDependentDetailsOfOrderForm_(ThisObject, DiscrepancyOrderText);
	
EndProcedure

&AtServer
Procedure WhenRemovingComponentsOnServer(TSName, AdditionalParameter)
	
	SetsServer.WhenRemovingComponents(ThisObject, TSName, AdditionalParameter);
	
	UpdateOrderInformation();
	
	StructureOfActions = New Structure;
	OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, Object.ShipmentByOrders);
	BatchProcessingOfTablePartServer.TreatTS(
		Object[TSName],
		StructureOfActions);
	
EndProcedure

#EndRegion

#Region SelectionAndProcessingOfQuantityVerification

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected)
	
	TableOfGoods       = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	ListOfProperties = "ProductsInSet, Products, Characteristic, ItemVariantOfSet, Package,
					|Series, NumberOfPackages, PriceKind, Price, DeliveryPeriodDays, WithAssignment";
	
	If ValueIsFilled(Object.Warehouse) Then
		ListOfProperties = ListOfProperties + ", Warehouse";
	EndIf;
	
	StructureOfActions = New Structure;
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, Object.ShipmentByOrders);
	
	RowsToProcess = New Array();
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct, ListOfProperties);
		
		LinesOfBusinessClientServer.FillAssignmentByFlagSeparately(
			ThisObject,
			CurrentRow);
		
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
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
EndProcedure

&AtServer
Procedure ProcessingProductSelectionFromOrder(AddressInStorage)
	
	FieldsNames = "RowCode, SalesOrder";
	
	TableStructure = GetFromTempStorage(AddressInStorage);
	GoodsTable = TableStructure.Goods;  // ValueTable -
	TableOfBarcodesOfPackages = TableStructure.PackageBarcodes;
	
	GoodsTable.Sort(FieldsNames + " Desc");
	
	ActionsToRecalculateNumber = New Structure;
	AddActionRecalculateNumberOfUnits(ActionsToRecalculateNumber);
	BatchProcessingOfTablePartServer.TreatTS(GoodsTable, ActionsToRecalculateNumber);
	
	RowsRecalculateAmount = New Array;
	
	// Grouping a table by row keys.
	StringTree = New Array;
		
	For Each TableRow In GoodsTable Do
		
		If TableRow.SalesOrder  = Object.Ref Then
			TableRow.SalesOrder = Undefined;
		EndIf;
		
		If TableRow.QuantityInOrder <> TableRow.Count Then
			RowsRecalculateAmount.Add(TableRow);
		EndIf;
		
		If TableRow.RowCode <> 0 Then
			RowsArray = New Array;
			StringTree.Add(RowsArray);
		EndIf;
		
		TableRow.SetIndex = ?(ValueIsFilled(TableRow.ProductsInSet), 1, 0);
		
		RowsArray.Add(TableRow);
		
	EndDo;
	
	ActionsToRecalculateAmount = New Structure("RecalculateAmount");
	BatchProcessingOfTablePartServer.ProcessTSStrings(RowsRecalculateAmount, ActionsToRecalculateAmount, GoodsTable);
	
	InvoicesServer.FillInProductsSelectedFromOrder(StringTree, FieldsNames, Object.Goods, New Structure);
	
	StructureOfActions = New Structure;
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Products", StructureOfActions);
	BatchProcessingOfTablePartServer.TreatTS(
		Object.Goods,
		StructureOfActions,
		Undefined);
	
	UpdateOrderInformation();
	
	Object.ShipmentByOrders =
		ValueIsFilled(Object.SalesOrder)
		Or OrderList.Count() > 0;
	UpdateDeliveryPlanningView(ThisObject);
	
	UpdateOrderDeviations();
	FillInServiceDetailsForProductRange();
	WhenChangingWarehouseInTablePartServer();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	SetElementProperties();

	If Object.ShipmentByOrders Then
		For Each String In Object.Goods Do
			If String.RowCode = 0 Then
				String.Purpose = Catalogs.Assignments.EmptyRef();
			EndIf;
		EndDo;
	EndIf;
	
	LinesOfBusinessServer.SetVisibilityOfElementsSeparately(ThisObject);
	LinesOfBusinessServer.ReFillInServiceDetailsOfTablePart(ThisObject);
	SalesServerLocalization.TransferBarcodesOfPackages(ThisObject, TableOfBarcodesOfPackages);
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "OrderSales");
	
EndProcedure

&AtClient
Procedure OpenSelectionByOrdersAndOrders()
	
	AttributesNames =
		"Currency,
		|Contract,
		|Counterparty,
		|VATTaxation,
		|LineOfBusiness,
		|Organization,
		|ShipmentByOrders,
		|Partner,
		|Department,
		|SalesOpportunity,
		|Warehouse,
		|Terms,
		|Ref,
		|BusinessOperation,
		|PriceIncludesVAT,
		|UseAdvancedFeaturesOfSalesOrder
		|";
	
	HeaderAttributes = New Structure(AttributesNames);
	FillPropertyValues(HeaderAttributes, Object);
	HeaderAttributes.PriceIncludesVAT = PriceIncludesVATOrders;
	HeaderAttributes.UseAdvancedFeaturesOfSalesOrder = UseAdvancedFeaturesOfSalesOrder;
	
	FillInResources = CommonClientServer.ValueInArray("SelectionByOrdersOrders");
	
	FormParameters = New Structure();
	FormParameters.Insert("HeaderAttributes",                           HeaderAttributes);
	FormParameters.Insert("OrderDocument",                                    Object.SalesOrder); 
	FormParameters.Insert("AdvancedWarehousingOnShipment",                 AdvancedWarehousingOnShipment);
	FormParameters.Insert("AdvancedWarehousingOnGoodsReceipt",              False);
	FormParameters.Insert("InvoiceForOrders",                       Object.ShipmentByOrders);
	FormParameters.Insert("AddressGoods",                              AddressInvoiceGoods());
	FormParameters.Insert("AddressBarcodesOfPackages",                   AddressBarcodesOfPackages());
	FormParameters.Insert("Invoice",                                Object.Ref);
	FormParameters.Insert("UseInvoicesForSeveralOrders", UseShipmentForMultipleOrders);
	FormParameters.Insert("OrdersAreUsed",                       True);
	FormParameters.Insert("FillInStampData",                  False);
	FormParameters.Insert("AdditionalFields",                       Undefined);
	FormParameters.Insert("FillInResources",                        FillInResources);
	
	OpenForm("CommonForm.AddItemsFromSalesOrderGoodsIssue",
		FormParameters,
		ThisObject,
		UUID,
		,
		,
		,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtServer
Function AddressInvoiceGoods()
	
	Table = Object.Goods.Unload(); // ValueTable

	Table.Columns.Add("DateOfShipment",    New TypeDescription("Date"));
	Table.Columns.Add("DateOfReceipt", New TypeDescription("Date"));

	Table.FillValues(CurrentSessionDate(), "DateOfShipment");
	Table.FillValues(CurrentSessionDate(), "DateOfReceipt");
	
	Table.Columns.SalesOrder.Name = "CustomerSOriginalOrder";
	Table.Columns.Add(
		"SalesOrder",
		New TypeDescription(
			"DocumentRef.SalesOrder,
			|DocumentRef.RequestForReturnOfGoodsFromCustomer"));
	
	For Each String In Table Do
		
		If ValueIsFilled(String.CustomerSOriginalOrder) Then
			String.SalesOrder = String.CustomerSOriginalOrder;
		Else
			String.SalesOrder = Object.Ref;
		EndIf;
		
	EndDo;
		
	AddressInTempStorage = PutToTempStorage(Table, UUID);
	
	Return AddressInTempStorage;
	
EndFunction

&AtServer
Function AddressBarcodesOfPackages()
	
	Table = Object.PackageBarcodes.Unload(); // ValueTable
	
	AddressInTempStorage = PutToTempStorage(Table, UUID);
	
	Return AddressInTempStorage;
	
EndFunction

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
				
				ProcessedRowsFoundRows.Add(TSRow);
				
			EndIf;
			
		EndDo;
		
		If FoundRows.Count() = 0 Then
			
			TSRow = Object.Goods.Add();
			FillPropertyValues(TSRow, SourceRow);
			
			ProcessedRowsAddedRows.Add(TSRow);
			
		EndIf;
		
	EndDo;
	
	StructureOfActionsFoundLines = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsFoundLines, Object);
	
	FillIn_TermsOfSales = BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(
		Object);
	
	CheckFillWarehouse = BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(
		Object,
		WarehouseGroup_);
	
	StructureOfActionsAddedLines = New Structure;
	StructureOfActionsAddedLines.Insert("FillIn_TermsOfSales", FillIn_TermsOfSales);
	StructureOfActionsAddedLines.Insert("CheckFillWarehouse", CheckFillWarehouse);
	
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Products", StructureOfActionsAddedLines);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsAddedLines, Object);
	OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActionsAddedLines, Object.ShipmentByOrders);
	
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
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
EndProcedure

#EndRegion

#Region PriceManagementSystem

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
	FillParameters.Insert("PopulationFields",     "PriceKind, Price, DeliveryPeriodDays");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	
	PricesCalculated = EnterprisePricesFillingServer.FillInPrices(
		Object.Goods,
		RowsArray,
		FillParameters,
		StructureOfActions);
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Function FillInPricesOfSelectedRowsByPriceTypeServer(PricesKind)
	
	RowsArray = New Array;
	
	For Each CurRow In Items.Goods.SelectedRows Do
		
		FoundRow = Object.Goods.FindByID(CurRow);
		
		If DeviationFromShipmentConditions
			Or (ShipmentInExcessOfOrder
				And FoundRow.RowCode = 0) Then
			
			RowsArray.Add(FoundRow);
			
		EndIf;
		
	EndDo;
	
	SetsServerCall.AddToFullSet(Object.Goods, RowsArray, True);
	
	FillParameters = New Structure();
	FillParameters.Insert("Date", Object.Date);
	FillParameters.Insert("Organization", Object.Organization);
	FillParameters.Insert("Currency", Object.Currency);
	FillParameters.Insert("PriceKind", PricesKind);
	FillParameters.Insert("CalculateSets", True);
	FillParameters.Insert("PopulationFields", "Price, PriceKind");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	
	PricesCalculated = EnterprisePricesFillingServer.FillInPrices(Object.Goods,
		RowsArray, FillParameters, StructureOfActions);
	
	Return PricesCalculated;
	
EndFunction

#EndRegion

#Region SetOfSeries

&AtServer
Function SeriesSpecificationParameters()
	
	ObjectManager = Documents.GoodsShipmentToCustomer;
	
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

#Region Delivery

&AtClient
Procedure OpenDeliverySettings()
	
	LockFormDataForEdit();
	
	DeliverySettings = GenerateDeliveryParameterSettings();
	
	FormParameters = New Structure;
	FormParameters.Insert("DeliverySettings", DeliverySettings);
	FormParameters.Insert("ReadOnly", ReadOnly);
	
	CompletionDetails = New CallbackDescription("ProcessDeliveryParameterSettings", ThisObject);
	GoodsDeliveryClient.OpenDeliverySettingsForm(FormParameters, CompletionDetails);
	
EndProcedure

&AtServer
Function GenerateDeliveryParameterSettings()
	
	ShippingMethodsUsed = New Array; // Array of EnumRef.TransportMethods25
	ShippingMethodsUsed.Add(Enums.TransportMethods25.SelfPickup);
	ShippingMethodsUsed.Add(Enums.TransportMethods25.OwnDelivery); 
	ShippingMethodsUsed.Add(Enums.TransportMethods25.ByCarrier);
	ShippingMethodsUsed.Add(Enums.TransportMethods25.DefinedByDeliveryService);
	
	DeliverySettings = GoodsDeliveryClientServer.NewDeliverySettings();
	DeliverySettings.DeliverySpecificationMethod = Enums.DeliverySpecificationMethods.ForWholeDocument;
	DeliverySettings.AllowChangingDeliveryIndicationMethod = False;
	DeliverySettings.DeliveryPlanning = Object.DeliveryPlanning;
	DeliverySettings.AllowChangingTypeOfDeliveryPlanning = Not Object.ShipmentByOrders;
	DeliverySettings.DeliveryMethod = Object.DeliveryMethod25;
	DeliverySettings.ShippingMethodsUsed = ShippingMethodsUsed;
	
	DeliverySettings.Partner = Object.Partner;
	DeliverySettings.DeliveryPoint = Object.DeliveryPoint;
	DeliverySettings.DeliveryZone = Object.DeliveryZone;
	
	DeliverySettings.DeliveryToCarrier = Object.DeliveryToCarrier;
	DeliverySettings.Carrier = Object.CarrierPartner;
	DeliverySettings.CarrierDeliveryPoint = Object.CarrierDeliveryPoint;
	DeliverySettings.CarrierSDeliveryArea = Object.CarrierSDeliveryArea;
	
	DeliverySettings.DeliveryTimeFrom = Object.DeliveryTimeFrom;
	DeliverySettings.DeliveryTimeTo = Object.DeliveryTimeTo;
	
	DeliverySettings.AdditionalDeliveryInformation = Object.AdditionalDeliveryInformation;
	DeliverySettings.SpecialTransportationConditions = Object.SpecialTransportationConditions;
	DeliverySettings.SpecialTransportationConditionsDescription = Object.SpecialTransportationConditionsDescription;
	
	GoodsFieldNames = "Warehouse";
	SearchParameters = New Structure;
	SearchParameters.Insert("ItemsType", Enums.ItemsTypes.OwnGoods);
	GoodsReadyForUnloading = Object.Goods.FindRows(SearchParameters);
	TableOfGoods = Object.Goods.Unload(GoodsReadyForUnloading, GoodsFieldNames);
	WarehouseInformationTable = Object.WarehousesDeliveryInformation.Unload();
	
	Query = New Query;
	QueryText =
	"SELECT
	|	TableOfGoods.Warehouse AS Warehouse
	|INTO TTTableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	WarehouseInformationTable.Warehouse AS Warehouse,
	|	WarehouseInformationTable.WarehousePoint AS WarehousePoint,
	|	WarehouseInformationTable.AreaOfWarehouse AS AreaOfWarehouse
	|INTO TTWarehouseInformationTable
	|FROM
	|	&WarehouseInformationTable AS WarehouseInformationTable
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.Warehouse AS Warehouse,
	|	CASE
	|		WHEN TableWarehousesDeliveryDetails.WarehousePoint IS NULL
	|			THEN ISNULL(DeliveryPoints.Ref, VALUE(Catalog.DeliveryPoints.EmptyRef))
	|		ELSE TableWarehousesDeliveryDetails.WarehousePoint
	|	END AS WarehousePoint,
	|	CASE
	|		WHEN TableWarehousesDeliveryDetails.AreaOfWarehouse IS NULL
	|			THEN ISNULL(DeliveryPoints.DeliveryZone, VALUE(Catalog.DeliveryZones.EmptyRef))
	|		ELSE TableWarehousesDeliveryDetails.AreaOfWarehouse
	|	END AS AreaOfWarehouse
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|		LEFT JOIN Catalog.DeliveryPoints AS DeliveryPoints
	|		ON TableOfGoods.Warehouse = DeliveryPoints.Owner
	|		AND DeliveryPoints.MainPoint
	|		LEFT JOIN TTWarehouseInformationTable AS TableWarehousesDeliveryDetails
	|		ON TableOfGoods.Warehouse = TableWarehousesDeliveryDetails.Warehouse";
	
	Query.Text = QueryText;
	Query.SetParameter("TableOfGoods", TableOfGoods);
	Query.SetParameter("WarehouseInformationTable", WarehouseInformationTable);
	
	CacheOfWarehouses = New Map();
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		If ValueIsFilled(Selection.Warehouse)
			And CacheOfWarehouses[Selection.Warehouse] = Undefined Then
			
			CacheOfWarehouses[Selection.Warehouse] = True; // We remember that the line was added earlier
			
			WarehouseLine_ = GoodsDeliveryClientServer.NewDeliveryWarehouseRowData();
			WarehouseLine_.Warehouse = Selection.Warehouse;
			WarehouseLine_.WarehousePoint = Selection.WarehousePoint;
			WarehouseLine_.AreaOfWarehouse = Selection.AreaOfWarehouse;
			DeliverySettings.Warehouses.Add(WarehouseLine_);
			
		EndIf;
		
	EndDo;
	
	If Not Object.Warehouse.IsEmpty()
		And CacheOfWarehouses[Object.Warehouse] = Undefined Then
		
		IsFolder = Common.ObjectAttributeValue(Object.Warehouse, "IsFolder");
		If Not IsFolder Then
			
			PointData_ = Catalogs.DeliveryPoints.DeliveryPointInformationMain(Object.Warehouse);
			WarehouseLine_ = GoodsDeliveryClientServer.NewDeliveryWarehouseRowData();
			WarehouseLine_.Warehouse = Object.Warehouse;
			WarehouseLine_.WarehousePoint = PointData_.DeliveryPoint;
			WarehouseLine_.AreaOfWarehouse = PointData_.DeliveryZone;
			DeliverySettings.Warehouses.Add(WarehouseLine_);
			
			CacheOfWarehouses[Object.Warehouse] = True;
			
		EndIf;
		
	EndIf;
	
	Return DeliverySettings;
	
EndFunction

// Parameters:
//  Settings - Undefined -
//            - See GoodsDeliveryClientServer.DefaultDeliverySettings
//  AdditionalParameters - Structure
//
&AtClient
Procedure ProcessDeliveryParameterSettings(Settings, AdditionalParameters) Export
	
	If Settings = Undefined Then
		Return;
	EndIf;
	
	ProcessDeliveryParameterSettingsServer(Settings);
	
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	Modified = True;
	
EndProcedure

&AtServer
Procedure ProcessDeliveryParameterSettingsServer(Val Settings)
	
	Object.DeliveryPlanning = Settings.DeliveryPlanning;
	Object.DeliveryMethod25 = Settings.DeliveryMethod;
	
	Object.DeliveryPoint = Settings.DeliveryPoint;
	Object.DeliveryZone = Settings.DeliveryZone;
	
	Object.DeliveryToCarrier = Settings.DeliveryToCarrier;
	Object.CarrierPartner = Settings.Carrier;
	Object.CarrierDeliveryPoint = Settings.CarrierDeliveryPoint;
	Object.CarrierSDeliveryArea = Settings.CarrierSDeliveryArea;
	
	Object.DeliveryTimeFrom = Settings.DeliveryTimeFrom;
	Object.DeliveryTimeTo = Settings.DeliveryTimeTo;
	
	Object.AdditionalDeliveryInformation = Settings.AdditionalDeliveryInformation;
	Object.SpecialTransportationConditions = Settings.SpecialTransportationConditions;
	Object.SpecialTransportationConditionsDescription = Settings.SpecialTransportationConditionsDescription;
	
	Object.WarehousesDeliveryInformation.Clear();
	For Each WarehouseLine_ In Settings.Warehouses Do
	
		NewRow = Object.WarehousesDeliveryInformation.Add();
		FillPropertyValues(NewRow, WarehouseLine_);
		
	EndDo;
	Object.WarehousesDeliveryInformation.Sort("Warehouse");
	
	FieldNamesOfDeliveryPointAddresses = "Address, AddressValue, FieldValueAddress";
	DeliveryPointAddressFields = Common.ObjectAttributesValues(Object.DeliveryPoint, FieldNamesOfDeliveryPointAddresses);
	
	Object.DeliveryAddress = DeliveryPointAddressFields.Address;
	Object.DeliveryAddressFieldValues = DeliveryPointAddressFields.AddressValue;
	Object.DeliveryAddressValue = DeliveryPointAddressFields.FieldValueAddress;
	
EndProcedure

// Parameters:
//  Form - See Document.GoodsShipmentToCustomer.Form.DocumentForm
//
&AtClientAtServerNoContext
Procedure SetAvailabilityVisibilityOfDeliveryItems(Form)
	
	Object = Form.Object;
	Items = Form.Items;
	UseAdvancedFeaturesOfSalesOrder = Form.UseAdvancedFeaturesOfSalesOrder;
	
	ItemsNames = New Array; // Array of String
	ItemsNames.Add("DeliveryIsRequired");
	ItemsNames.Add("EditDeliveryParametersHeader");
	
	If Not GoodsDeliveryClientServer.UsedDelivery25()
		Or Object.Organization = PredefinedValue("Catalog.Companies.ManagementCompany") Then
		
		ItemsNames.Add("DecorationDeliveryAction");
		
		TMCommonUseClientServer.SetPropertyOfFormElements(
			Items,
			ItemsNames,
			"Visible",
			False);
		
	Else
		
		NumberOfDiscrepancies = 0;
		
		If Object.ShipmentByOrders Then
			
			NumberOfDiscrepancies = Object.Goods.Total("OrderDiscrepancy_3");
			
		EndIf;
		
		If Object.ShipmentByOrders Then
			
			If Not UseAdvancedFeaturesOfSalesOrder Then
				
				Items.DecorationDeliveryAction.Visible = False;
				Items.DecorationDeliveryAction.Title = "";
				
				TMCommonUseClientServer.SetPropertyOfFormElements(
					Items,
					ItemsNames,
					"Visible",
					True);
				
			ElsIf UseAdvancedFeaturesOfSalesOrder
				And NumberOfDiscrepancies > 0 Then
				
				Items.DecorationDeliveryAction.Visible = Object.DeliveryIsRequired;
				Items.DecorationDeliveryAction.Title = NStr("ru = '(действуют только на строки сверх распоряжений)';
															|vi = '(valid only for lines in excess of references)';
															|en = '(valid only for lines in excess of references)'; fa = '(valid only for lines in excess of references)';
															|it = '(valid only for lines in excess of references)';
															|pl = '(valid only for lines in excess of references)';
															|tr = '(sadece talimat fazlası satırlar için geçerlidir)'");
				
				TMCommonUseClientServer.SetPropertyOfFormElements(
					Items,
					ItemsNames,
					"Visible",
					True);
				
			Else
				
				ItemsNames.Add("DecorationDeliveryAction");
				Items.DecorationDeliveryAction.Title = "";
				
				TMCommonUseClientServer.SetPropertyOfFormElements(
					Items,
					ItemsNames,
					"Visible",
					False);
				
			EndIf; 
			
		Else
			
			Items.DecorationDeliveryAction.Visible = False;
			
			TMCommonUseClientServer.SetPropertyOfFormElements(
				Items,
				ItemsNames,
				"Visible",
				True);
			
		EndIf;
		
		CommonClientServer.SetFormItemProperty(
			Items,
			"EditDeliveryParametersHeader",
			"Enabled",
			Object.DeliveryIsRequired);
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateDeliveryPlanningView(Form, DeliveryFlagHasBeenChanged = False)
	
	Object = Form.Object;
	
	If Object.DeliveryIsRequired Then
		
		If Object.ShipmentByOrders Then
			
			Object.DeliveryPlanning = PredefinedValue("Enum.DeliveryPlanningKinds.ByCurrentDocument");
		
		Else
			
			TypeOfPlanning = TypeOfDeliveryPlanningByPartnerAgreement(
				Object.Partner,
				Object.Terms,
				Object.ShipmentByOrders,
				DeliveryFlagHasBeenChanged);
			
			If TypeOfPlanning <> Undefined Then
				
				Object.DeliveryPlanning = TypeOfPlanning;
				
			EndIf;
		
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function TypeOfDeliveryPlanningByPartnerAgreement(Partner, Terms, ShipmentByOrders, DeliveryFlagHasBeenChanged)
	
	AdvancedOrderOptions = GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder");
	DeliveryPlanning = Undefined;
	
	If Not AdvancedOrderOptions
	 Or Not ShipmentByOrders Then
		
		DeliveryPlanning = GoodsDelivery.TypeOfDeliveryPlanningByPartnerAgreement(Partner, Terms);
		
	ElsIf DeliveryFlagHasBeenChanged Then
		
		DeliveryPlanning = Enums.DeliveryPlanningKinds.ByCurrentDocument;
		
	EndIf;
	
	Return DeliveryPlanning;
	
EndFunction

#EndRegion

#Region Delivery20

&AtServer
Procedure SpecialTransportationConditionsOnChangeServer()
	
	GoodsDelivery.SpecialTransportationConditionsOnChange(Items, Object);
	
EndProcedure

&AtServer
Procedure SupplementDeliveryInformationWithContactsServer()
	
	GoodsDelivery.SupplementDeliveryInformationWithContacts(Object);
	
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
Procedure TextDocumentsBasedOnURLProcessingLocalization(Item, FormattedStringURL, StandardProcessing)
	

	Return;
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure SetUncheckSeparately(Set)
	LinesOfBusinessServer.SetUncheckSeparately(ThisObject, Set);
EndProcedure

&AtClient
Procedure Attachable_CheckCompletionOfTaskForReceivingCarriers()
	
	If ValueIsFilled(BackgroundTaskData) Then
		
		If BackgroundTaskData.Status = "Completed2"
			Or (ValueIsFilled(BackgroundTaskData.JobID)
				And JobCompleted(BackgroundTaskData.JobID)) Then
			
			GoodsDeliveryClient.UpdateListOfCarriers(Items.CarrierPartner.ChoiceList,
				BackgroundTaskData);
			
		Else
			
			AttachIdleHandler("Attachable_CheckCompletionOfTaskForReceivingCarriers", 1, True);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function JobCompleted(JobID)
	
	Return TimeConsumingOperations.JobCompleted(JobID);
	
EndFunction

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
	
	// Setting the conditional design for the items of the nomenclature of the tabular part 'Goods'
	SetsServer.SetConditionalAppearance(ThisObject, "Goods");
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject);
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisObject,
		"SeriesWhenPlanningShipmentWHGoodsAreIndicated");
	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisObject, False);
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject);
	
	// Setting the conditional design for the 'Price view' element of the 'Goods' tabular part
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPriceKind.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ShipmentByOrders");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// Setting a conditional layout for the 'Packaging' element of the 'Goods' tabular part
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPackage.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ShipmentInExcessOfOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ShipmentByOrders");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DeviationFromShipmentConditions");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	FilterGroup3 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup3.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ShipmentInExcessOfOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DeviationFromShipmentConditions");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//

	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPackage.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter =FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ShipmentInExcessOfOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ShipmentByOrders");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DeviationFromShipmentConditions");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("ReadOnly", False);

	//

	LinesOfBusinessServer.SetConditionalAppearanceOfFlagSeparately(ThisObject);

	// Setting the conditional design for the 'Price' element of the 'Products' tabular part
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPrice.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ShipmentByOrders");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DeviationFromShipmentConditions");
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
	ItemFilter.LeftValue = New DataCompositionField("DeviationFromShipmentConditions");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SalesOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ShipmentInExcessOfOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PriceKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	FilterGroup3 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup3.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DeviationFromShipmentConditions");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SalesOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ShipmentInExcessOfOrder");
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
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = ValueList;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Warehouse");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsWarehouse.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = ValueList;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// Setting the conditional design for the "Customer's Order" element of the "Products" tabular part

	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSalesOrder.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SalesOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ShipmentByOrders");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseShipmentForMultipleOrders");
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
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Vượt quá lệnh, chưa chọn lệnh';
													|ru = 'Сверх распоряжения, распоряжение не выбрано';
													|en = 'In excess of reference. Reference is not selected'; fa = 'In excess of reference. Reference is not selected';
													|it = 'In excess of reference. Reference is not selected';
													|pl = 'In excess of reference. Reference is not selected';
													|tr = 'Sipariş iptal edildi, hiçbir sipariş seçilmedi'"));
	
	// Setting the conditional design for the 'Division' element
	InventoriesServer.EstablishConditionalAppearanceOfDivisionForTypesOfStocks(ThisObject);
	
	// Setting the conditional design for the 'Activity Direction' element
	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisObject);
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	UseSalesOrders = GetFunctionalOption("UseSalesOrders")
		Or GetFunctionalOption("UseRequestsForReturnOfGoodsFromCustomers");
		
	UseShipmentForMultipleOrders =
		GetFunctionalOption("UseSaleByMultipleOrders");
	
	ShipmentInExcessOfOrder         = UserRightsCached.SalesInExcessOfOrder();
	DeviationFromShipmentConditions = UserRightsCached.VarianceFromSalesTermsAndConditions();
	
	UsePartnersAsCounterparties =
		GetFunctionalOption("UsePartnersAsCounterparties");
	
	ToUseTermsOfSales = GetFunctionalOption("ToUseTermsOfSales");
	
	UsePriceManagementSystem25       = PriceManagementSystemServerCall.UsePriceManagementSystem25();
	UseLinesOfBusiness =
		GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness");
	
	Contract                          = Object.Contract;
	Warehouse                            = Object.Warehouse;
	WarehouseGroup_                      = ItIsGroupOfWarehousesAndWarehousesUsedByWHForSale(Object.Warehouse);
	DocumentCurrency                  = Object.Currency;
	LocalAccountingCurrency   = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	BasisChanged                = False;
	SeriesSpecificationParameters           = SeriesSpecificationParameters();
	BusinessTransactionBeforeTheChange = Object.BusinessOperation;
	
	If Object.ShipmentByOrders
		And ValueIsFilled(Object.SalesOrder) Then
		
		PriceIncludesVATOrders =
			Common.ObjectAttributeValue(Object.SalesOrder, "PriceIncludesVAT");
			
	ElsIf Object.ShipmentByOrders
		And Object.Goods.Count() > 0 Then
		
		PriceIncludesVATOrders = True;
		
		For Each TSRow In Object.Goods Do
			
			If ValueIsFilled(TSRow.SalesOrder) Then
				PriceIncludesVATOrders =
					Common.ObjectAttributeValue(TSRow.SalesOrder, "PriceIncludesVAT");
				Break;
			EndIf;
			
		EndDo;
		
	Else
		PriceIncludesVATOrders = True;
	EndIf;
	
	LinesOfBusinessServer.OnReadCreateAtServer(ThisObject);
	
	Documents.GoodsShipmentToCustomer.AdjustItemSelectionSettings(ThisObject, Object);
	Documents.GoodsShipmentToCustomer.CustomizeForm(ThisObject, Object.Number, Object.Date);
	
	UpdateOrderInformation();
	SetDefaultPriceView();
	ThereIsSpendingOrderForShippingOrders(Object.Ref, ShipmentStarted);
	
	If Not UseSalesOrders Then
		Items.GroupDiscrepancyOnOrder.Visible = False;
		Items.GroupDiscrepancyOnOrders.Visible = False;
	EndIf;
	
	SetVisibilityOfShipmentBanToPartner();
	
	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible,
		Object.Contract);
	
	Items.GoodsFillInTheWarehouseInSelectedLines.Enabled = WarehouseGroup_;
	Items.GroupLabelAndPictureSeveralWarehouses.Visible   = WarehouseGroup_;
	
	SetVisibilityOfSeriesElements();
	SetParametersForSelectingProductsWarehouse();
	SetTitleFillInByOrdersOrders();

	UpdateOrderDeviations();
	FillInServiceDetailsForProductRange();
	WhenChangingWarehouseInTablePartServer();
	
	BackgroundTaskData = GoodsDelivery.WhenReadingCreatingOrdersOnServer(Items, Object, Object.ShipmentByOrders,,, True);
	
	CurrentDeliveryMethod = Object.DeliveryMethod;
	
	If AccessRight("Update", Metadata.Documents.GoodsShipmentToCustomer) Then
		
		PrintBasisTable.Load(Documents.GoodsShipmentToCustomer.PrintBasisTable(Object));
		
		If ValueIsFilled(Object.Basis) Then
			
			BaseStructure = Documents.GoodsShipmentToCustomer.StructureOfBaseForPrinting(Object);
			BasisChanged  = (TrimAll(Object.Basis) <> BaseStructure.Basis)
									Or (TrimAll(Object.BaseDocumentNumber) <> BaseStructure.BaseDocumentNumber)
									Or (Object.ReferenceDocumentDateForPrintForms <> BaseStructure.ReferenceDocumentDateForPrintForms);
			
		EndIf;
		
	EndIf;
	
	SetElementProperties();
	
	ProcessingOfTabularForms.InitializeRowCache(Items.Goods);
	
	UpdateTextDocumentsBasedOn();
	
	FillParameters = Documents.GoodsShipmentToCustomer.ParametersForFillingInSalesVATTaxation(Object);
	VATAccountingERP.FillInSalesVATTaxSelectionList(
		Items.VATTaxation,
		Object.VATTaxation,
		FillParameters,
		VATAccountingCachedParameterValues);
	
	ARAPAccountingFormWork.FormWhenReadingOnServer(ThisObject);
	
	SalesServer.SetContractAvailability(Object,
		Items.Contract.Enabled,
		Items.Contract.Visible,
		Object.Contract);
	
	Items.GroupLabelContract.Visible = Items.Contract.Visible
		And Not Object.ShipmentByOrders;
	
EndProcedure

&AtServerNoContext
Function ItIsGroupOfWarehousesAndWarehousesUsedByWHForSale(Warehouse)
	Return Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWHForSales(Warehouse);
EndFunction

&AtServer
Procedure UpdateOrderInformation()
	
	ParametersOfUpdate = OrdersServer.ParametersForUpdatingOrderInformationInForm();
	ParametersOfUpdate.PropsNameOrderList         = "OrderList";
	ParametersOfUpdate.OrderPathInHeader                  = "Object.SalesOrder";
	ParametersOfUpdate.TitleLabelName               = "HeaderOrdersText";
	ParametersOfUpdate.NameOfColumnGroupInTableSection   = "GoodsGroupSalesOrder";
	ParametersOfUpdate.OrderNameInTablePart          = "SalesOrder";
	ParametersOfUpdate.UseOrdersInTabularSection = UseShipmentForMultipleOrders;
	ParametersOfUpdate.OrdersUse                = UseSalesOrders;
	
	OrdersServer.UpdateOrderInformationInForm(ThisObject, Object.Goods, ParametersOfUpdate);
	
	UseAdvancedFeaturesOfSalesOrder =
		Documents.GoodsShipmentToCustomer.UseAdvancedFeaturesOfSalesOrder(OrderList.UnloadValues());
	SetVisibilityOfCommandsByOrder();
	
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
Procedure SetParametersForSelectingProductsWarehouse()
	
	GoodsWarehouse                 = Items.GoodsWarehouse;
	ParameterValue           = WarehouseSelectionData(Object.Warehouse);
	GoodsWarehouse.ChoiceParameters = New FixedArray(New Array);
	
	TMCommonUseClientServer.AddSelectionParameter(GoodsWarehouse, "Ref", ParameterValue);
	
EndProcedure

&AtServer
Procedure SetTitleFillInByOrdersOrders()
	
	AdvancedWarehousingOnShipment = AdvancedWarehousingOnShipment();
	
	If Not AdvancedWarehousingOnShipment
		And UseSalesOrders
		And Not UseShipmentForMultipleOrders Then
		
		TitleFillIn = NStr("vi = 'Chọn hàng hóa từ lệnh';
							|ru = 'Подобрать товары из распоряжения';
							|en = 'Pick goods from reference'; fa = 'Pick goods from reference';
							|it = 'Pick goods from reference';
							|pl = 'Pick goods from reference';
							|tr = 'Siparişten ürünler seç'");
		
	ElsIf Not AdvancedWarehousingOnShipment
		And UseSalesOrders
		And UseShipmentForMultipleOrders Then
		
		TitleFillIn = NStr("vi = 'Chọn hàng hóa từ lệnh';
							|ru = 'Подобрать товары из распоряжений';
							|en = 'Pick goods from references'; fa = 'Pick goods from references';
							|it = 'Pick goods from references';
							|pl = 'Pick goods from references';
							|tr = 'Siparişlerden ürünler seç'");
		
	ElsIf AdvancedWarehousingOnShipment
		And Not UseSalesOrders Then
		
		TitleFillIn = NStr("vi = 'Chọn hàng hóa theo lệnh';
							|ru = 'Подобрать товары по ордерам';
							|en = 'Pick goods by notes'; fa = 'انتخاب کالا بر اساس حواله‌ها';
							|it = 'Selezionare le merci in base ai mandati';
							|pl = 'Wybierz wiersze pozycji wg zleceń';
							|tr = 'Emirlere göre malları seç'");
		
	Else
		TitleFillIn = NStr("vi = 'Nhận hàng theo lệnh / đơn hàng';
							|ru = 'Подобрать товары по распоряжениям/ордерам';
							|en = 'Pick goods by references/notes'; fa = 'انتخاب کالا بر اساس مراجع/حواله‌ها';
							|it = 'Selezionare le merci secondo le disposizioni/mandati';
							|pl = 'Wybierz wiersze pozycji wg zamówień/zleceń';
							|tr = 'Talimatlara/emirlere göre ürünleri seç'");
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
	
	StructureOfActions = New Structure;
	OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, Object.ShipmentByOrders);
	
	BatchProcessingOfTablePartServer.TreatTS(
		Object.Goods,
		StructureOfActions,
		Undefined);
	
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
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(ParametersForFillingInBankingDetails);
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, ParametersForFillingInBankingDetails);
	
	SetsServer.FillInServiceDetails(ThisObject);
	
EndProcedure

&AtServer
Procedure WhenChangingWarehouseInTablePartServer()
	
	WarehousesServer.WhenChangingWarehouseInTablePart(Object.Goods, WarehouseTable, WarehouseGroup_, False);
	
	TotalWarehouses_             = WarehouseTable.Count();
	AdvancedWarehousingOnShipment = AdvancedWarehousingOnShipment();
	UpdateDependentDetailsOfServerByOrderForm();
	WarehousesClientServer.UpdateWarehouseGroupImage(SeveralWarehousesText, Items.PictureMultipleWarehouses,
		TotalWarehouses_);
	
EndProcedure

&AtServer
Procedure UpdateDependentDetailsOfServerByOrderForm()
	
	If Object.Goods.Count() = 0
		Or Not Object.ShipmentByOrders
		Or Not UseSalesOrders Then
		
		DiscrepancyOrderText = "";
		
		Items.GroupDiscrepancyOnOrder.Visible = False;
		Items.GroupDiscrepancyOnOrders.Visible = False;
		
		If Object.Goods.Count() > 0 Then
			For Each LineProducts_ In Object.Goods Do
				LineProducts_.OrderDiscrepancy_3 = 0;
			EndDo;
		EndIf;
		
		SetAvailabilityVisibilityOfDeliveryItems(ThisObject);
		
		Return;
		
	EndIf;
	
	UpdateDependentDetailsOfOrderForm_(ThisObject, DiscrepancyOrderText);
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateDependentDetailsOfOrderForm_(Form, DiscrepancyOrderText)
	
	Object = Form.Object;
	Goods = Object.Goods;
	FormItems = Form.Items;
	
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
	
	SetAvailabilityVisibilityOfDeliveryItems(Form);
	
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
		|VATTaxation,
		|Currency,
		|PriceIncludesVAT,
		|UseAdvancedFeaturesOfSalesOrder
		|";
		
	FormParameters = New Structure(NamesOfDocumentDetails);
	FillPropertyValues(FormParameters, Object);
	FormParameters.PriceIncludesVAT = PriceIncludesVATOrders;
	FormParameters.UseAdvancedFeaturesOfSalesOrder = UseAdvancedFeaturesOfSalesOrder;
	
	OpenForm("Document.GoodsShipmentToCustomer.Form.ReferenceChoiceForm", 
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
	
	SetAvailabilityOfClipboardCommands();
	
	ItemArray = New Array;
	ItemArray.Add("GoodsUnlinkFromOrder");
	ItemArray.Add("GoodsContextMenuUnlinkFromOrder");
	
	PropertyValue = Object.ShipmentByOrders
						And ShipmentInExcessOfOrder;
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible",
		PropertyValue);
	
	ItemArray = New Array;
	ItemArray.Add("GoodsOpenSelection");
	ItemArray.Add("GoodsImportFromExternalFile");
	
	PropertyValue = Not Object.ShipmentByOrders
						Or (Object.ShipmentByOrders
							And ShipmentInExcessOfOrder);
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled",
		PropertyValue);
	
	TagName = "GoodsFillInTheWarehouseInSelectedLines";
	
	If Not Object.ShipmentByOrders Then
		TMCommonUseClientServer.SetFormItemProperty(Items, TagName, "Visible", True);
		TMCommonUseClientServer.SetFormItemProperty(Items, TagName, "Enabled", WarehouseGroup_);
	Else
		TMCommonUseClientServer.SetFormItemProperty(Items, TagName, "Visible", False);
	EndIf;
	
	SetLBEditingOption();
	
	If Object.ShipmentByOrders Then
		ItemArray = New Array;
		ItemArray.Add("GoodsImportDataFromPDT");
		
		If Not ShipmentInExcessOfOrder Then
			ItemArray.Add("GoodsSplitRow");
			ItemArray.Add("GoodsContextMenuSplitRow");
			ItemArray.Add("GoodsSearchByBarcode");
		EndIf;
		
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", False);
	EndIf;
	
	If Object.ShipmentByOrders
		And Not DeviationFromShipmentConditions Then
		
		ItemArray = New Array;
		ItemArray.Add("ShipmentByOrder");
		ItemArray.Add("ShipmentByOrders");
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
		
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "ReadOnly", True);
		
	EndIf;
	
	AvailabilityOfEditingCostIndicators = True;
	
	If Object.ShipmentByOrders
		And ValueIsFilled(Object.CorrectedDocument) Then
		
		CurrentSettings_ = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate(
			"TaxationSystemSettings",
			Object.Organization,
			Object.Date);
		
		If CurrentSettings_.TaxationSystem = Enums.TaxationSystems.Shared3 Then
			AvailabilityOfEditingCostIndicators = False;
		EndIf;
		
	EndIf;
	
	ItemArray = New Array;
	ItemArray.Add("GoodsPriceKind");
	ItemArray.Add("GoodsPrice");
	ItemArray.Add("GoodsSum");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items,
		ItemArray,
		"Enabled",
		AvailabilityOfEditingCostIndicators);
	
	ItemArray = New Array;
	ItemArray.Add("GoodsFillThePricesByTermsOfSales");
	ItemArray.Add("GoodsFillInPricesOfSelectedRowsByPriceType");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled",
		Not Object.ShipmentByOrders);
	
	ItemArray = New Array;
	ItemArray.Add("Currency");
	ItemArray.Add("VATTaxation");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items,
		ItemArray,
		"ReadOnly",
		Object.ShipmentByOrders);
	
	TagName      = "VATTaxation";
	PropertyValue = Object.Patch;

	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		TagName,
		"ReadOnly",
		PropertyValue);
	
	TagName      = "GoodsGroupSalesOrder";
	PropertyValue = Object.ShipmentByOrders;
	
	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		TagName,
		"Visible",
		PropertyValue);
	
EndProcedure

&AtServer
Procedure SetLBEditingOption()
	
	If Not UseLinesOfBusiness Then
		Return;
	EndIf;
	
	LBAvailabilityParameters = LinesOfBusinessServer.ParametersLBEditingCapability();
	
	LBAvailabilityParameters.Contract           = Object.Contract;
	LBAvailabilityParameters.ARAPObjectSettings   = Common.ObjectAttributeValue(Object.Contract, "ARAPObjectSettings");
	LBAvailabilityParameters.OrderInvoice_3 = Object.ShipmentByOrders;
	
	LinesOfBusinessServer.SetLBEditingOption(ThisObject, LBAvailabilityParameters);
	
EndProcedure

&AtServer
Procedure RefillByNotes(AnArrayOfOrders)
	
	FillingStructure = SalesServerCall.ReFillInvoiceForOrders(Object);
	
	If FillingStructure.HasChanges Then
		Modified = True;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions,
	Object,
	RecalculateQuantity = True)
	
	If RecalculateQuantity Then
		AddActionRecalculateNumberOfUnits(StructureOfActions);
	EndIf;
	
	StructureOfActions.Insert("RecalculateAmount");
	
EndProcedure

&AtServerNoContext
Procedure AddActionRecalculateNumberOfUnits(StructureOfActions,
	CheckIfYouNeedToRecalculateNumberOfUnits = False)
	
	If Not CheckIfYouNeedToRecalculateNumberOfUnits Then
		StructureOfActions.Insert("RecalculateNumberOfUnits", Undefined);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddPriceFillingActionsToStructure(StructureOfActions, Object, UseAgreements, UsePriceManagementSystem25)
	
	If ((UseAgreements And ValueIsFilled(Object.Terms)) 
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
	
	CheckFillWarehouse = BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(
		Object,
		WarehouseGroup_);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckFillWarehouse", CheckFillWarehouse);
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, Object.ShipmentByOrders);
	
	RowsToProcess = New Array();
	
	For Each RowOfGoods In ItemsFromStorage Do
		
		StringTSGoods = Object.Goods.Add();
		FillPropertyValues(StringTSGoods, RowOfGoods,, "RowCode");
		
		RowsToProcess.Add(StringTSGoods)
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	FillInServiceDetailsForProductRange();
	WhenChangingWarehouseInTablePartServer();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
EndProcedure

&AtServer
Procedure GetStockTypesFromStorage(ValueSelected)
	
	InventoriesServer.ProcessInputOfInventoryTypesManually(ValueSelected, ThisObject);
	
EndProcedure

&AtClient
Procedure ShippingOnOrdersWhenChangingAfterSelection(Result, AdditionalParameters) Export
	
	SalesOrder = Result;
	
	If SalesOrder = Undefined Then
		Object.ShipmentByOrders = False;
		Return;
	EndIf;
	
	If Object.Goods.Count() = 0 Then
		QueryText = NStr("vi = 'Danh sách ""Hàng hóa"" sẽ được điền bằng số dư hàng hóa chưa lập theo chứng từ %SalesOrder%. Tiếp tục?';
						|ru = 'Список ""Товары"" будет заполнен остатками неоформленных товаров по документу %SalesOrder%. Продолжить?';
						|en = 'The ""Goods"" list will be populated with remaining unregistered goods under the ""%SalesOrder%"" document. Continue?'; fa = 'The ""Goods"" list will be populated with remaining unregistered goods under the ""%SalesOrder%"" document. Continue?';
						|it = 'The ""Goods"" list will be populated with remaining unregistered goods under the ""%SalesOrder%"" document. Continue?';
						|pl = 'The ""Goods"" list will be populated with remaining unregistered goods under the ""%SalesOrder%"" document. Continue?';
						|tr = '""Ürünler"" listesi %SalesOrder% belgesinden kalan ürünlerle doldurulacaktır. Devam edilsin mi?'");
		QueryText = StrReplace(QueryText, "%SalesOrder%", SalesOrder);
	Else
		QueryText = NStr("vi = 'Các dòng trong danh sách ""Hàng hóa"" sẽ được liên kết với các dòng của chứng từ %SalesOrder%. Các dòng mà không thể được liên kết với các dòng trong lệnh sẽ bị xóa. Tiếp tục?';
						|ru = 'Строки в списке ""Товары"" будут привязаны к строкам документа %SalesOrder%. Строки, которые невозможно привязать к строкам распоряжения, будут удалены. Продолжить?';
						|en = 'Lines in the ""Goods"" list will be linked to lines of the ""%SalesOrder%"" document. Lines that cannot be linked will be deleted. Continue?'; fa = 'Lines in the ""Goods"" list will be linked to lines of the ""%SalesOrder%"" document. Lines that cannot be linked will be deleted. Continue?';
						|it = 'Lines in the ""Goods"" list will be linked to lines of the ""%SalesOrder%"" document. Lines that cannot be linked will be deleted. Continue?';
						|pl = 'Lines in the ""Goods"" list will be linked to lines of the ""%SalesOrder%"" document. Lines that cannot be linked will be deleted. Continue?';
						|tr = 'Ürünler listesindeki satırlar, %SalesOrder% belge satırlarına bağlanacaktır. Sipariş satırlarına bağlanamayan satırlar silinecektir. Devam edilsin mi?'");
		QueryText = StrReplace(QueryText, "%SalesOrder%", SalesOrder);
	EndIf;
	
	ShipmentOnOrdersONChangeFragment(SalesOrder, QueryText);
	
EndProcedure

&AtClient
Procedure ShipmentOnOrdersONChangeFragment(Val SalesOrder, Val QueryText)
	
	AdditionalParameters = New Structure("SalesOrder", SalesOrder);
	CallbackDescription      = New CallbackDescription("ShipmentByOrdersOnChangeCompletion", ThisObject,
		AdditionalParameters);
	
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtServer
Procedure FillInFromOrderServer()
	
	InvoiceManager = Documents.GoodsShipmentToCustomer;
	
	HeaderAttributes = InvoiceManager.HeaderAttributes();
	FillPropertyValues(HeaderAttributes, Object);
	HeaderAttributes.PriceIncludesVAT = PriceIncludesVATOrders;
	HeaderAttributes.UseAdvancedFeaturesOfSalesOrder = UseAdvancedFeaturesOfSalesOrder;
	
	References = InvoiceManager.WaybillOrders(Undefined, HeaderAttributes);
	
	FillParameters = InvoiceManager.DocumentFillingParameters();
	InvoiceManager.InitializeFillingParameters(
		FillParameters,
		HeaderAttributes,
		References);
	
	GoodsTable = Object.Goods.Unload();
	InvoiceManager.FillInByOrdersOrders(
		GoodsTable,
		Object.Ref,
		FillParameters);
	
	Object.Goods.Load(GoodsTable);
	
	InvoicesServer.DeleteEmptyLines(Object.Goods, "Count");
	
	FillInServiceDetailsForProductRange();
	
	WhenChangingWarehouseInTablePartServer();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
	FillBaseForPrinting();
	
EndProcedure

&AtServer
Procedure LinkShipmentLinesToOrders(SelectByOrder_)
	
	Documents.GoodsShipmentToCustomer.LinkRowsToOrders(
		ThisObject,
		Object,
		SeriesSpecificationParameters,
		SelectByOrder_,
		PriceIncludesVATOrders);
	
	For Each CurRow In Object.Goods Do
		If Not ValueIsFilled(CurRow.RowCode) Then
			CurRow.Purpose = Catalogs.Assignments.EmptyRef();
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
		
		TableRow.RowCode   = 0;
		TableRow.Purpose  = Undefined;
		TableRow.WithAssignment = False;
		
		If UntieOnlyStrings Then
			TableRow.OrderDiscrepancy_3 = 1;
		Else
			TableRow.SalesOrder = Undefined;
		EndIf;
		
		// Reassign the series lines
		ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Object,
			SeriesSpecificationParameters, CurRow, CachedValues);
		
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

	If Not BasisChanged Then
		FillPropertyValues(Object, Documents.GoodsShipmentToCustomer.StructureOfBaseForPrinting(Object));
	EndIf;
	
	PrintBasisTable.Load(Documents.GoodsShipmentToCustomer.PrintBasisTable(Object));
	
EndProcedure

&AtServer
Procedure FillInSubordinatePropertiesForStatistics(ParentPropsName)
	
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, ParentPropsName);
	
EndProcedure

&AtServer
Procedure FillInDefaultContract()
	
	Contract = Documents.GoodsShipmentToCustomer.GetDefaultContract(Object);
	
	If Contract <> Object.Contract Then
		
		Object.Contract = Contract;
		
	EndIf;
	
	If ValueIsFilled(Object.Contract) Then
		
		SalesServer.FillInBankAccountsUnderAgreement(Object.Contract,
			Object.CompanyBankAccount, Object.CounterpartyBankAccount);
		
		FillBaseForPrinting();
		ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Contract");

	EndIf;
	
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
		
		DocumentDate = ?(ValueIsFilled(Object.Date), Object.Date,CurrentSessionDate());
		StructureOfOldCurrencyRates = ProcessingOfExchangeRatesTM.GetCurrencyRate(OldCurrency, DocumentDate, LocalAccountingCurrency);
		StructureOfNewCurrencyRates  = ProcessingOfExchangeRatesTM.GetCurrencyRate(NewCurrency,  DocumentDate, LocalAccountingCurrency);
		
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
Procedure GoodsAfterDeleteRowServer(SeriesStatusesNeedToBeUpdated, CachedValues)
	
	If SeriesStatusesNeedToBeUpdated Then
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Undefined, CachedValues);
	EndIf;
	
	UpdateOrderInformation();
	WhenChangingWarehouseInTablePartServer();
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisObject);
	
EndProcedure

&AtServer
Procedure GoodsAtEndOfEditingOnServer(IDCurrentRow, ServerHandlers, CachedValues)
	
	If ServerHandlers.UpdateSeriesStatuses Then
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues);
	EndIf;
	If ServerHandlers.ServerCallRequired__ Then
		FormEvents.WhenChangingElement(ThisObject, Items.Goods, ServerHandlers);
	EndIf;
	
EndProcedure

&AtClient
Procedure QuestionUserWhenChangingRowDetails(CallbackDescription, CurrentRow)
	
	// If the current line is not associated with the order.
	If CurrentRow.RowCode = 0
		Or Not Object.ShipmentByOrders Then

		RunCallback(CallbackDescription, True);
		
		Return;
	EndIf;
	
	// If none of the key details have changed.
	If CurrentRow.Products = PreviousRowDetails.Products
		And CurrentRow.Characteristic = PreviousRowDetails.Characteristic
		And (CurrentRow.Warehouse = PreviousRowDetails.Warehouse
			Or Not ValueIsFilled(PreviousRowDetails.Warehouse)
				And OrdersAreUsedAsInvoices()) Then
		
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
Function PutGoodsAndStockTypesInStorage()
	
	Return InventoriesServer.PutGoodsAndStockTypesInStorage(ThisObject);
	
EndFunction

&AtClient
Procedure CloseOrderFragment()
	
	ListOfOrdersToClose = New ValueList;
	
	For Each ReferenceOrder In OrderList Do
		
		If TypeOf(ReferenceOrder.Value) = Type("DocumentRef.SalesOrder")
			Or TypeOf(ReferenceOrder.Value) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
			ListOfOrdersToClose.Add(ReferenceOrder.Value);
		EndIf;
		
	EndDo;
	
	ClosureStructure = New Structure;
	ClosureStructure.Insert("Orders",                       ListOfOrdersToClose);
	ClosureStructure.Insert("DocumentInitiator",            Object.Ref);
	ClosureStructure.Insert("CancelUnprocessedLines", True);
	ClosureStructure.Insert("CloseOrders",              True);
	
	OpenForm("DataProcessor.OrderClosureWizard.Form.ClosureForm",
		ClosureStructure,
		ThisObject,,,,,
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
	
	FilledWithRows = WarehousesServer.FillInWarehousesInSelectedLines(Object.Goods,
																				ArrayOfSelectedRows,
																				Warehouse);
	
	If FilledWithRows > 0 Then
		ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
		WhenChangingWarehouseInTablePartServer();
	EndIf;
	
	Return FilledWithRows;
	
EndFunction

&AtClient
Procedure OpenShipmentPrintingAttributes()
	
	Try
		LockFormDataForEdit();
	Except
		ShowMessageBox(Undefined, ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		Return;
	EndTry;
	
	DeliveryOrderData = GoodsDeliveryClientServer.OrderParameters();
	FillPropertyValues(DeliveryOrderData, Object);
	
	ParametersStructure = New Structure();
	ParametersStructure.Insert("ObjectType",                     "GoodsShipmentToCustomer");
	ParametersStructure.Insert("OrderSales",            Object.ShipmentByOrders);
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
	ParametersStructure.Insert("DeliveryOrderData",   DeliveryOrderData);
	ParametersStructure.Insert("Ref",                         Object.Ref);
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
	ParametersStructure.Insert("InformationOnTransportationAndCargo", Object.InformationOnTransportationAndCargo);
	ParametersStructure.Insert("SupportingDocuments",      Object.SupportingDocuments);
	ParametersStructure.Insert("DeliveryIsRequired", Object.DeliveryIsRequired);
	ParametersStructure.Insert("DeliverySpecificationMethod", PredefinedValue("Enum.DeliverySpecificationMethods.ForWholeDocument"));
	
	
	OpenForm("CommonForm.PrintingDetailsOfSales",
					ParametersStructure,
					ThisObject,
					,
					,
					,
					Undefined,
					FormWindowOpeningMode.LockOwnerWindow);
	
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

&AtServer
Procedure UpdateTextOfInvoiceIssued()
	
	RegistrationParameters = Documents.GoodsShipmentToCustomer.ParametersForRegisteringInvoicesIssued(Object);
	InvoicesIssuedOnBasisOf = VATAccountingERP.InvoicesIssuedOnBasisOf(RegistrationParameters);
		
	TextOfTheInvoiceIssued =
		SalesServer.CreatePresentationOfInvoiceGenerationCommandsBasedOn(
			Object.Ref, InvoicesIssuedOnBasisOf);
	
	TextsFieldsDocumentsBasedOn.Add(TextOfTheInvoiceIssued);
	
EndProcedure

&AtServer
Procedure FillInSalesVATTaxation()
	
	If Object.Patch Then
		Return;
	EndIf;
	
	FillParameters = Documents.GoodsShipmentToCustomer.ParametersForFillingInSalesVATTaxation(Object);
	
	VATAccountingERP.FillInSalesVATTaxation(Object.VATTaxation,
		FillParameters, VATAccountingCachedParameterValues);
	
	VATAccountingERP.FillInSalesVATTaxSelectionList(Items.VATTaxation,
		Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues); 
	
EndProcedure

&AtServer
Procedure SetVisibilityOfCommandsByOrder()
	
	BasisDocuments = OrderList.UnloadValues();
	
	DocumentsByType = SalesServer.DocumentsBasedOnAvailabilityOfSettlementObjects(BasisDocuments);
	ThereAreDocumentsWithCalculationObjects = DocumentsByType.DocumentsWithCalculationObjects.Count() > 0;
	
	VisibilityOfOrderClosingCommands = UseAdvancedFeaturesOfSalesOrder
		And Object.ShipmentByOrders
		And ThereAreDocumentsWithCalculationObjects;
	
	Items.CloseOrder.Visible = VisibilityOfOrderClosingCommands;
	Items.CloseOrders_2.Visible = VisibilityOfOrderClosingCommands;
	
EndProcedure

&AtServerNoContext
Function ParametersForRegisteringInvoicesIssuedServer(Val Object)
	
	Return Documents.GoodsShipmentToCustomer.ParametersForRegisteringInvoicesIssued(Object);
	
EndFunction

&AtServer
Function AdvancedWarehousingOnShipment()
	
	// The situation when warehouses are not filled in TS has been handled. This may happen if the order is an order, like an invoice - 
	// in such orders, filling out the warehouse is optional.
	TableWarehouses = New Array;
	
	For Each TSRow In Object.Goods Do
		
		If ValueIsFilled(TSRow.Warehouse) Then
			TableWarehouses.Add(TSRow.Warehouse);
		EndIf;
		
	EndDo;
	
	If TableWarehouses.Count() = 0 Then
		Return False;
	EndIf;
	
	Return WarehousesServer.ThereIsOrderWarehouseForShipment(TableWarehouses, Object.Date, Object.Warehouse);
	
EndFunction

&AtServer
Function OrdersAreUsedAsInvoices()
	
	AnArrayOfOrders = Object.Goods.Unload(, "SalesOrder").UnloadColumn("SalesOrder");
	AnArrayOfOrders.Add(Object.SalesOrder);
	
	Query = New Query;
	Query.SetParameter("AnArrayOfOrders", AnArrayOfOrders);
	Query.Text =
	"SELECT
	|	DocumentsTable.ThisIsOrderAsInvoice AS ThisIsOrderAsInvoice
	|INTO TableOfOrderDetails
	|FROM
	|	Document.SalesOrder AS DocumentsTable
	|WHERE
	|	DocumentsTable.Ref IN (&AnArrayOfOrders)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentsTable.ThisIsOrderAsInvoice
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer AS DocumentsTable
	|WHERE
	|	DocumentsTable.Ref IN (&AnArrayOfOrders)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	TRUE AS ThereAreRecords
	|FROM
	|	TableOfOrderDetails AS TableOfOrderDetails
	|HAVING
	|	COUNT(TableOfOrderDetails.ThisIsOrderAsInvoice) > 0
	|	AND MIN(TableOfOrderDetails.ThisIsOrderAsInvoice) = TRUE";
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

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
