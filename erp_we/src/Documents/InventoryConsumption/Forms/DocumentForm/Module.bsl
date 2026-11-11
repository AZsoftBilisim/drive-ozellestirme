#Region Variables

&AtClient
Var CachedValues;

&AtClient
Var CurDataId;

&AtClient
Var PreviousRowDetails; //used to unlink the transfer line from the order line

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
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	If GetFunctionalOption("UseProduction") 
		And Object.BusinessOperation = Enums.BusinessTransactions.TransferToProduction Then
		Items.BusinessOperation.ChoiceList.Add(Enums.BusinessTransactions.TransferToProduction);
	EndIf;
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferToProduction Then
		// Such documents are no longer used and are only opened for viewing
		ReadOnly = True;
	EndIf;
	If Not Object.Patch Then
		Items.BusinessOperation.ChoiceList.Add(Enums.BusinessTransactions.TransferToOperation);
	EndIf; 
	
	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		"BaseGroup_",
		"Visible",
		ValueIsFilled(Object.DocumentBasis));
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
		Items.PictureDiscrepancyOrder.Picture = New Picture();
		Items.PictureDiscrepancyOrders.Picture = New Picture();
		
	ElsIf Parameters.FillingValues.Property("FillByWarehouseDocument") Then
		
		RefillByNotes(Parameters.FillingValues.AnArrayOfOrders);
		Modified = True;
		
	EndIf;
	
	SetConditionalAppearance();
	
	If Items.BusinessOperation.ChoiceList.Count() = 1 Then
		Items.BusinessOperation.Visible = False;
	EndIf;
	
	Items.CloseOrder.Enabled = AccessRight("Update",Metadata.Documents.InventoryConsumptionOrder);
	
	SetAvailabilityOfClipboardCommands();
	SetSelectionParameters();
		
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	// Setting up accounting accounts.
	SetupParameters = Documents.InventoryConsumption.AccountingAccountSettings_(Object.BusinessOperation);
	GLAccountSettingsServer.OnCreateAtServer(ThisObject, SetupParameters);
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.InventoryConsumption.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	DocumentCorrection.OnCreateAtServer(ThisForm, Items.LineCorrection);

	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	
	InventoryConsumptionLocalization.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations

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

	// Setting up accounting accounts.
	SetupParameters = Documents.InventoryConsumption.AccountingAccountSettings_(Object.BusinessOperation);
	GLAccountSettingsServer.OnReadAtServer(ThisObject, SetupParameters);
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.InventoryConsumption.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation);
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	DocumentCorrection.OnReadAtServer(ThisForm, Items.LineCorrection);
	
	// StandardSubsystems.Properties	
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties

	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands

	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	FillInServiceDetailsOfTablePart();
	
	ChangeHeadersForBusinessTransactions();
	GLAccountSettingsServer.AfterWriteAtServer(ThisObject);
	Catalogs.OperationCategories.FillInCategoryAttributes(Object.Goods);
	// Selection of articles and analytics.
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	LinesOfBusinessServer.AfterWriteAtServer(ThisObject);
	
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	Var CurrentOperation1;
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.InventoryConsumption.DocumentForm.Event.ChoiceProcessing");
	
	If TypeOf(ValueSelected) = Type("Structure") And ValueSelected.Property("CurrentOperation1", CurrentOperation1) Then
		
		If Upper(CurrentOperation1) = Upper("AddItemsFromSalesOrderGoodsIssue") Then
			ProcessingProductSelectionFromOrder(ValueSelected.AddressInStorage);
		EndIf;
		
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectGoodsToSalesDocument.Form.Form" Then
		
		ProcessingSelectionOfSelectionOnServer(ValueSelected);
		
	ElsIf ChoiceSource.FormName = "Catalog.InventoryKinds.Form.InventoryOwnerAttributesForm" Then
		
		GetStockTypesFromStorage(ValueSelected);
		
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectReusablePackage.Form.Form" Then
		
		FillMultiTurnContainersFromStorageServer(ValueSelected.AddressOfReusableContainerInStorage);
		ReusablePackageClient.NotifyUserAboutFillingMultiTurnContainers();
		
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);
		
	EndIf;
	
	SetFlagForFillingWarehouseOnClient();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	ReportResults();
	
	PreviousRowDetails = New Structure(
		"Products,
		|Characteristic,
		|Package,
		|Count,
		|NumberOfPackages,
		|ItemsType,
		|ItemVariantsAreUsed,
		|SKU,
		|InventoryConsumptionOrder,
		|RowCode");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// The end of the standard subsystem.Pluggable commands
	// Standard subsystems.Worksfiles
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	ForceCloseTheForm = True;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	
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
	
	If EventName = "Write_GoodsIssueNote" Then
		ThisIsAReferenceInvoice = ThisIsAReferenceInvoice(Object.Ref, AdvancedWarehousingOnShipment);
	EndIf;
	
	// StandardSubsystems.Properties
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	DocumentCorrectionClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	

	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)
	
	FormEventsClient.URLProcessing(ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	NotifyAboutDocument(WriteParameters);
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	NonCurrentAssetsClient.NotifyAboutDocumentEntryInFALog();
	NonCurrentAssetsClient.NotifyAboutEntryOfDocumentInJournalOfIA();
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferToOperation") Then
		NotifyChanged(Type("CatalogRef.Assets"));
		NotifyChanged(Type("CatalogRef.LotsOfInventoryInOperation"));
	EndIf;
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

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
	If NotExecuteCheck1BeforeWrite Then
		NotExecuteCheck1BeforeWrite = False;
		Return;
	EndIf;
	
	If WriteParameters.WriteMode = DocumentWriteMode.Posting And Not Object.ConsumptionByOrders Then
		
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
	
	If Result <> DialogReturnCode.No Then
		
		TMCommonUseClient.RecordObjectIfNecessary(ThisObject, AdditionalParameters.WriteParameters,,True);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// Setting up accounting accounts.
	GLAccountSettingsServer.BeforeWriteAtServer(ThisObject, CurrentObject);
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
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
Procedure WarehouseOnChange(Item)
	
	If Warehouse <> Object.Warehouse Then
		
		If Object.ConsumptionByOrders And Object.Goods.Count() > 0 Then
			ShowQueryBox(New CallbackDescription("WarehouseOnChangeCompletion", ThisObject), NStr("vi = 'Danh sách ""Hàng hóa"" sẽ bị xóa. Tiếp tục?';
																									|ru = 'Список ""Товары"" будет очищен. Продолжить?';
																									|en = 'The Item list will be cleared. Continue?'; fa = 'The Item list will be cleared. Continue?';
																									|it = 'L''elenco ""Merci"" verrà cancellato. Continuare?';
																									|pl = 'Lista ""Towaty"" zostanie wyczyszczona. Kontynuować?';
																									|tr = '""Ürünler"" listesi temizlenecek. Devam edilsin mi?'"), QuestionDialogMode.YesNo);
			Return;
		EndIf;
		
		WarehouseOnChangeServer();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WarehouseOnChangeCompletion(QuestionResult, AdditionalParameters) Export
    
    Response = QuestionResult;
    If Response = DialogReturnCode.No Then
        Object.Warehouse = Warehouse;
        Return;
    EndIf;
    
    WarehouseOnChangeServer();

EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOnChangeServer();
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	InventoryConsumptionClientLocalization.BusinessOperationOnChange(ThisForm);
	
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	
EndProcedure

&AtClient
Procedure CaptionTitleDomesticConsumptionOrdersClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	OpenForm(
		"CommonForm.ViewingListOfDocuments",
		New Structure("DocumentsList, Title",
			OrderList,
			NStr("vi = 'Đơn hàng tiêu dùng nội bộ (ghi giảm) (%DocumentsCount%)';
				|ru = 'Заказы на внутреннее потребление (списание) (%DocumentsCount%)';
				|en = 'Inventory consumption orders (write-off) (%DocumentsCount%)'; fa = 'Inventory consumption orders (write-off) (%DocumentsCount%)';
				|it = 'Ordini per consumo interno (storno) (%DocumentsCount%)';
				|pl = 'Zamówienia na rozchód wewnętrzny (spisanie) (%DocumentsCount%)';
				|tr = 'Stok tüketim emirleri (iptal) (%DocumentsCount%)'")), ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ConsumptionToOrderWhenYouChange(Item)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.InventoryConsumption.DocumentForm.Item.OrderInvoice_3.OnChange");
	
	If Object.ConsumptionByOrders And ThisIsAReferenceInvoice Then
		
		WarningText = NStr("vi = 'Đã bắt đầu tiêu dùng từ kho. Không thể đặt dấu hiệu này.';
							|ru = 'Потребление со склада уже начато. Установка признака невозможна.';
							|en = 'Consumption from the warehouse already started. Cannot set the flag.'; fa = 'Consumption from the warehouse already started. Cannot set the flag.';
							|it = 'Il consumo dal magazzino è già iniziato. Impossibile impostare un criterio.';
							|pl = 'Już zaczęto konsumpcję z magazynu. Ustawianie właściwości jest niemożliwe.';
							|tr = 'Depodan yapılan sarfiyat çoktan başladı. İşaret ayarlanamaz.'");
		ShowMessageBox(, WarningText);
		Object.ConsumptionByOrders = False;
		Return;
		
	EndIf;
	
	If Object.ConsumptionByOrders Then
		
		If UseInventoryConsumptionForMultipleOrders Then
			
			ThereAreLinesBeforeFilling = Object.Goods.Count() > 0;
			WhenChangingConsumptionForMultipleOrders();
			If ThereAreLinesBeforeFilling Then
				NotifyAboutLinkingRowsToOrders();
			Else
				NotifyAboutFillingInOrderBalances();
				Object.ConsumptionByOrders = Object.Goods.Count() > 0;
			EndIf;
			UpdateDependentDetailsOfServerByOrderForm();
			SetVisibilityOfCommandsByOrder();
			
		Else
			
			FormParameters = New Structure();
			FormParameters.Insert("Organization",             Object.Organization);
			FormParameters.Insert("Department",           Object.Department);
			FormParameters.Insert("Warehouse",                   Object.Warehouse);
			FormParameters.Insert("BusinessOperation",   Object.BusinessOperation);
			FormParameters.Insert("SalesOpportunity",                  Object.SalesOpportunity);
			FormParameters.Insert("LineOfBusiness", Object.LineOfBusiness);
			FormParameters.Insert("Recorder",             Object.Ref);
			
			CallbackDescription = New CallbackDescription("ConsumptionByOrderSetOrderSelected", ThisObject); //fills in the "Products" list
			OpenForm("Document.InventoryConsumption.Form.ReferenceChoiceForm",
				FormParameters, ThisForm, UUID,,, CallbackDescription);
			
		EndIf;
		
	Else
		
		WhenChangingConsumptionForMultipleOrders();
		If Object.Goods.Count() > 0 Then
			If UseInventoryConsumptionForMultipleOrders Then
				NotificationText1 = NStr("vi = 'Các dòng trong danh sách ""Hàng hóa"" đã bỏ liên kết khỏi các dòng đơn hàng.';
										|ru = 'Строки в списке ""Товары"" отвязаны от строк заказов.';
										|en = 'Lines in Item list are unlinked from lines in the orders.'; fa = 'Lines in Item list are unlinked from lines in the orders.';
										|it = 'Le righe dell''elenco ""Merci"" sono scollegate dalle righe degli ordini.';
										|pl = 'Wiersze na liście ""Towary"" są odwiązane od wierszy zamówień.';
										|tr = '""Ürünler"" listesindeki satırlar, sipariş satırlarından ayrılmıştır.'");
			Else
				NotificationText1 = NStr("vi = 'Các dòng trong danh sách ""Hàng hóa"" đã bỏ liên kết khỏi các dòng đơn hàng.';
										|ru = 'Строки в списке ""Товары"" отвязаны от строк заказа.';
										|en = 'Lines in Item list are unlinked from order lines.'; fa = 'Lines in Item list are unlinked from order lines.';
										|it = 'Le righe dell''elenco ""Merci"" sono scollegate dalle righe dell''ordine.';
										|pl = 'Wiersze na liście ""Wiersze pozycji"" są odwiązane od wierszy zamówienia.';
										|tr = '""Ürünler"" listesindeki satırlar, sipariş satırından ayrılmıştır.'");
			EndIf;
			ShowUserNotification(NStr("vi = 'Bộ xử lý danh sách ""Hàng hóa""';
										|ru = 'Обработка списка ""Товары""';
										|en = 'The Item list processing'; fa = 'The Item list processing';
										|it = 'Elaborazione dell''elenco ""Merci""';
										|pl = 'Przetwarzanie listy ""Wiersze pozycji""';
										|tr = '""Ürünler"" listesinin işlenmesi'"),, NotificationText1);
		EndIf;
		UpdateDependentDetailsOfServerByOrderForm();
		SetVisibilityOfCommandsByOrder();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure LineOfBusinessOnChange(Item)
	
	LineOfBusinessOnChangeServer();
	
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
Procedure ConsumptionForActivityClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(
		ThisObject, FormattedStringURL, StandardProcessing);
EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	
	If SeriesSpecificationParameters.UseItemsBatch Then
		
		FillInShippingInstructions = False;
		
		If YouCanPopulateSeriesByShipment
			And Object.Status = PredefinedValue("Enum.InternalConsumptionStatuses.Accepted") Then
			
			QueryText = NStr("vi = 'Điền sê-ri theo dữ liệu phiếu xuất kho?';
							|ru = 'Заполнить серии по данным расходных ордеров?';
							|en = 'Fill in batch according to goods issue note data?'; fa = 'Fill in batch according to goods issue note data?';
							|it = 'Compilare le serie in base ai dati dei mandati di pagamento?';
							|pl = 'Uzupełnij serię zgodnie z danymi zestawień wydatków?';
							|tr = 'Ambar çıkış fişi verilerine göre partiler doldurulsun mu?'");
			
			CallbackDescription = New CallbackDescription("StatusOnChangeCompletion", ThisObject);
			ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo,, DialogReturnCode.Yes);
			
			Return;
			
		EndIf;
		
		StatusOnChangeServer(FillInShippingInstructions);
	
	EndIf;
	
EndProcedure

&AtClient
Procedure ExpenseLineOfBusinessIsSpecifiedInListOnChange(Item)

	Object.ExpenseLineOfBusinessIsSpecifiedInList = (ExpenseLineOfBusinessIsSpecifiedInList = 1);
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item.Name);
		
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.GoodsInventoryConsumptionOrder Then
		If ValueIsFilled(Items.Goods.CurrentData.InventoryConsumptionOrder) Then
			ShowValue(Undefined, Items.Goods.CurrentData.InventoryConsumptionOrder);
		EndIf;
	EndIf;
	
	// Setting up accounting accounts.
	GLAccountSettingsClient.OnClick(ThisObject, Field, StandardProcessing);
EndProcedure

&AtClient
Procedure GoodsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	If Object.ConsumptionByOrders Then 
		If CurrentRow <> Undefined Then
			If CurrentRow.RowCode = 0 Then
				CurrentRow.OrderDiscrepancy_3 = 1;
			Else
				CurrentRow.OrderDiscrepancy_3 = 0;
			EndIf;
		EndIf;
		UpdateDependentDetailsOfOrderForm_(
			Object.Goods,
			DiscrepancyOrderText, 
			Items.PictureDiscrepancyOrder,
			Items.PictureDiscrepancyOrders);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
	CurrentData = Items.Goods.CurrentData;
	
	WarehousesClient.UpdateCachedValues(Item, CachedValues, SeriesSpecificationParameters, Copy);
	
	If Not NewRow Then
		
	ElsIf Copy Then
		
		// Setting up accounting accounts.
		GLAccountSettingsClient.WhenCopyingString(ThisObject, Item);
	Else
		
		StructureOfActions = New Structure();
		
		// Selection of articles and analytics.
		IncomeAndExpensesClientServer.InsertActionFillInItemCostAnalysisOfProducts(
			StructureOfActions,
			ThisObject,
			Object.BusinessOperation,
			Object.Organization,
			Object.Department);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
		WhenAddingLineOfProductsOnClient(CurrentData);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	CurrentData = Items.Goods.CurrentData;
	
	If ProductsClient.SeriesStatusesNeedToBeUpdated(Item, CachedValues, SeriesSpecificationParameters) Then
		
		IDCurrentRow = CurrentData.GetID();
		
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues);	
		ProductsClient.UpdateCachedValuesToAccountForSeries(Item,CachedValues,SeriesSpecificationParameters);
		
	EndIf;
	
	ReusablePackageClient.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
	UpdateDependentDetailsOfOrderForm_(
		Object.Goods,
		DiscrepancyOrderText, 
		Items.PictureDiscrepancyOrder,
		Items.PictureDiscrepancyOrders);
	
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
	
EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	
	SeriesStatusesNeedToBeUpdated = ProductsClient.SeriesStatusesNeedToBeUpdated(Item, CachedValues, SeriesSpecificationParameters, True);
	If SeriesStatusesNeedToBeUpdated Then
		ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters);
	EndIf;
	
	ReusablePackageClient.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
	GoodsAfterDeleteRowServer(SeriesStatusesNeedToBeUpdated, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsOperationCategoryOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	WhenChangingCategoryOfOperation(CurrentRow);
	InventoryInOperationClient.ProcessLineWhenChangingCategoryOfOperation(CurrentRow, Object.Goods);
		
EndProcedure

&AtClient
Procedure PackageOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	If Object.ConsumptionByOrders And Not InventoryConsumptionInExcessOfOrder Then
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsBeforeRowChange(Item, Cancel)
	FillPropertyValues(PreviousRowDetails, Items.Goods.CurrentData);
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	AdditionalParameters = AdditionalCompletionProcessingParameters();
	AdditionalParameters.CurrentRow = CurrentRow;
	CallbackDescription = New CallbackDescription(
		"GoodsNomenclatureWhenChangingQuestionToUserCompletion", ThisObject, AdditionalParameters);
	QuestionUserWhenChangingRowDetails(CallbackDescription, CurrentRow);
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	AdditionalParameters = AdditionalCompletionProcessingParameters();
	AdditionalParameters.CurrentRow = CurrentRow;
	CallbackDescription = New CallbackDescription(
		"GoodsCharacteristicOnChangeCompletion", ThisObject, AdditionalParameters);
	QuestionUserWhenChangingRowDetails(CallbackDescription, CurrentRow);

EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChangeCompletion(Result, AdditionalParameters) Export
	
	If Not Result Then
		Return;
	EndIf;
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	If AdditionalParameters.LineDetachedFromOrder	Then
		LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	EndIf;
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsWithAssignmentOnChange(Item)
	
	LinesOfBusinessClient.GoodsWithAssignmentOnChange(ThisObject, Items.Goods.CurrentData);	
	
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
Procedure NumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
		
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsExpenseItemOnChange(Item)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure GoodsDimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure GoodsDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, Var_Parameters, Waiting, StandardProcessing)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(
		ThisObject,
		Item,
		Text,
		ChoiceData,
		Var_Parameters,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure GoodsDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(
		ThisObject,
		Item,
		Text,
		ChoiceData,
		Var_Parameters,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure GoodsInventoryConsumptionOrderStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	CurrentData = Items.Goods.CurrentData;
	If ValueIsFilled(CurrentData.InventoryConsumptionOrder) Then
		Return;
	EndIf;
	
	If CurrentData <> Undefined Then
	
		FormParameters = New Structure();
		FormParameters.Insert("Organization",             Object.Organization);
		FormParameters.Insert("Department",           Object.Department);
		FormParameters.Insert("Warehouse",                   Object.Warehouse);
		FormParameters.Insert("BusinessOperation",   Object.BusinessOperation);
		FormParameters.Insert("SalesOpportunity",                  Object.SalesOpportunity);
		FormParameters.Insert("LineOfBusiness", Object.LineOfBusiness);
		FormParameters.Insert("Recorder",             Object.Ref);
		
		OpenForm("Document.InventoryConsumption.Form.ReferenceChoiceForm", 
			FormParameters,,,,, 
			New CallbackDescription("GoodsReferenceOrderStartChoiceCompletion", ThisObject), 
			FormWindowOpeningMode.LockOwnerWindow);
			
        Return;
		
	EndIf;
	
	GoodsOrderStartOfSelectionFragment();
	
EndProcedure

&AtClient
Procedure GoodsExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
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

&AtClient
Procedure OpenInventoryKinds(Command)

	OptionsForEditingInventoryTypes = PutGoodsAndStockTypesInStorage();
	
	FinancesClient.OpenInventoryKinds(ThisObject, OptionsForEditingInventoryTypes);

EndProcedure

&AtClient
Procedure SelectGoods(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.InventoryConsumption.DocumentForm.Command.SelectGoods");
	
	FormParameters = New Structure;
	FormParameters.Insert("Warehouse",                                     Object.Warehouse);
	FormParameters.Insert("SelectionModeWithoutAmountParameters",         True);
	FormParameters.Insert("HideTheViewPriceColumn",                    True);
	FormParameters.Insert("HideTheItemPricesCommand",           True);
	FormParameters.Insert("Title",                                 NStr("vi = 'Chọn hàng hóa';
																		|ru = 'Подбор товаров';
																		|en = 'Pick goods'; fa = 'انتخاب کالاها';
																		|it = 'Selezione delle merci';
																		|pl = 'Wybór towarów';
																		|tr = 'Ürünlerin seçimi'"));
	FormParameters.Insert("Date",                                      Object.Date);
	FormParameters.Insert("Document",                                  Object.Ref);
	FormParameters.Insert("LineOfBusiness",                   Object.LineOfBusiness);
	FormParameters.Insert("SeriesSpecificationParameters",                    SeriesSpecificationParameters);
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.GoodsConsumptionOnDemand") Then
		FormParameters.Insert("FilterByProductType", New FixedArray(ProductsClientServer.SelectionByProductReusablePackagingWork(False)));
	Else
		FormParameters.Insert("FilterByProductType", New FixedArray(ProductsClientServer.SelectionByProductMultiTurnContainer(False)));
	EndIf;
	
	OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form", FormParameters, ThisForm, UUID);
	
EndProcedure

&AtClient
Procedure SelectGoodsByOrdersNotes(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.InventoryConsumption.DocumentForm.Command.SelectGoodsByOrdersNotes");
	
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
		
		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		
	Else
		EquipmentManagerTMClient.ReportError(ExecutionResult);
	EndIf;
	
EndProcedure

&AtClient
Procedure ImportDataFromPDT(Command)
	
	ClearMessages();
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.InventoryConsumption.DocumentForm.Command.ImportDataFromPDT");
	
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
Procedure FillInExpenseItem(Command)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.FillInArticleAndAnalyticsInSelectedLines(
		ThisObject,
		Items.GoodsExpenseItem,
		Items.Goods.SelectedRows);
	
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
Procedure SetTheMarkApart(Command)
	
	SetUncheckSeparately(True);
	
EndProcedure

&AtClient
Procedure UncheckTheSeparateBox(Command)
	
	SetUncheckSeparately(False);
	
EndProcedure

&AtClient
Procedure CreateGroupFA(Command)
	If Object.BusinessOperation <> PredefinedValue("Enum.BusinessTransactions.TransferToOperation") Then
		Return;
	EndIf;

	StringsList = New Array;
	For Each RowID In Items.Goods.SelectedRows Do
		RowData = Object.Goods.FindByID(RowID);
		If RowData.AccountAsGroupFA Then
			StringsList.Add(RowID);
		EndIf;
	EndDo;
	
	If StringsList.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Cần chọn các dòng có ghi nhận dạng TSCĐ theo nhóm';
								|ru = 'Необходимо выбрать строки с учетом в виде группового ОС';
								|en = 'Select lines with accounting as group fixed assets'; fa = 'Select lines with accounting as group fixed assets';
								|it = 'È necessario selezionare le righe con contabilità del tipo immobilizzazioni di gruppo';
								|pl = 'Należy wybrać wiersze z ewidencją w postaci grupowego środka trwałego';
								|tr = 'Grup işletim sistemi görünümünde hesaba katılan satırları seçmeniz gerekir'"));
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Tạo TSCĐ theo nhóm và điền đối tượng phân tích trong các dòng đã chọn?';
					|ru = 'Создать групповое ОС и заполнить аналитику в выбранных строках?';
					|en = 'Create group fixed assets and fill the analytics in the selected lines?'; fa = 'Create group fixed assets and fill the analytics in the selected lines?';
					|it = 'Creare immobilizzazione di gruppo e compilare l''analitica nelle righe selezionate?';
					|pl = 'Utworzyć grupowy środek trwały i wypełnić analitykę w wybranych wierszach?';
					|tr = 'Sabit kıymet grubu oluşturulsun ve seçilen satırlardaki boyut doldurulsun mu?'");
	CallbackDescription = New CallbackDescription("CreateGroupFACompletion", ThisObject);
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	Return // the UT has an empty handler
	
EndProcedure

&AtClient
Procedure FillInCategoryOfOperation(Command)
	
	AdditionalParameters = New Structure();
	AdditionalParameters.Insert("SelectedRows", Items.Goods.SelectedRows);
	CallbackDescription = New CallbackDescription("FillInCategoryOfOperationCompletion", ThisObject, AdditionalParameters);

	InventoryInOperationClient.FillInCategoryOfOperation(
		Object.Goods,
		Items.Goods.SelectedRows,
		Undefined,
		CallbackDescription);
	
EndProcedure

&AtClient
Procedure FillInIndividual(Command)
	InventoryInOperationClient.FillInIndividual(Object.Goods, Items.Goods.SelectedRows);
	Return // the UT has an empty handler
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm, True);
	
EndProcedure

&AtClient
Procedure UnlinkFromOrder(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.InventoryConsumption.DocumentForm.Command.UnlinkFromOrder");
	
	SelectedRows = Items.Goods.SelectedRows;
	If SelectedRows.Count()>0 Then
		UnbindLinesFromOrderOnServer(CachedValues);
		NotifyAboutEndOfUnbindingLines(SelectedRows.Count());
	Else
		WarningText = NStr("vi = 'Hãy chọn dòng cần bỏ liên kết với đơn hàng.';
							|ru = 'Выберите строки, которые необходимо отвязать от заказа.';
							|en = 'Select lines to remove from the order.'; fa = 'Select lines to remove from the order.';
							|it = 'Selezionare le righe da dissociare dall''ordine.';
							|pl = 'Wybierz wierze, które należy odłączyć od zamówienia.';
							|tr = 'Siparişten çıkarılacak satırları seçin.'");
		ShowMessageBox(,WarningText);
	EndIf; 
	
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
Procedure SetDeletionMarkForADocument(Command)
	
	TMCommonUseClient.SetDeletionMarkForADocument(ThisForm);
	
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

&AtClient
Procedure CloseOrder(Command)
	
	If Modified Or Not Object.Posted Then
		ShowQueryBox(New CallbackDescription("CloseOrderCompletion", ThisObject),
			NStr("vi = 'Cần kết chuyển chứng từ để thực hiện giao dịch. Kết chuyển chứng từ?';
				|ru = 'Необходимо провести документ для выполнения операции. Провести документ?';
				|en = 'To proceed, you need to post the document. Do you want to post the document?'; fa = 'To proceed, you need to post the document. Do you want to post the document?';
				|it = 'È necessario registrare il documento per eseguire operazione. Registrare documento?';
				|pl = 'Należy zaksięgować dokument aby wykonać operację. Zaksięgować dokument?';
				|tr = 'Bir işlemin gerçekleştirilmesi için belgenin düzenlenmesi gerekir. Belge düzenlensin mi?'"), QuestionDialogMode.YesNo);
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
	If ValueIsFilled(Object.InventoryConsumptionOrder) Then
		ListOfOrdersToClose.Add(Object.InventoryConsumptionOrder)
	Else
		ListOfOrdersToClose.LoadValues(OrderList.UnloadValues())
	EndIf;
	
	ClosureStructure = New Structure;
	ClosureStructure.Insert("Orders",                       ListOfOrdersToClose);
	ClosureStructure.Insert("DocumentInitiator",            Object.Ref);
	ClosureStructure.Insert("CancelUnprocessedLines", True);
	ClosureStructure.Insert("CloseOrders",              True);
	
	OpenForm("DataProcessor.OrderClosureWizard.Form.ClosureForm", 
	              ClosureStructure,,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure FillInInventoryNumber(Command)
	
	If Object.BusinessOperation <> PredefinedValue("Enum.BusinessTransactions.TransferToOperation") Then
		Return;
	EndIf;
	
	StringsList = New Array;
	For Each RowID In Items.Goods.SelectedRows Do
		RowData = Object.Goods.FindByID(RowID);
		If RowData.StocktakingRecord Then
			StringsList.Add(RowID);
		EndIf;
	EndDo;
	
	If StringsList.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Cần chọn các dòng có kế toán vật tư';
								|ru = 'Необходимо выбрать строки с инвентарным учетом';
								|en = 'Select lines with stocktaking record'; fa = 'Select lines with stocktaking record';
								|it = 'È necessario selezionare le righe con contabilità di inventario';
								|pl = 'Należy wybrać wiersze z ewidencją inwentarzową';
								|tr = 'Envanter satırlarını seçmeniz gerekir'"));
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Điền số kiểm kê trong các dòng đã chọn?';
					|ru = 'Заполнить инвентарный номер в выбранных строках?';
					|en = 'Do you want to fill the inventory number in the selected lines?'; fa = 'Do you want to fill the inventory number in the selected lines?';
					|it = 'Compilare il numero di inventario nelle righe selezionate?';
					|pl = 'Wypełnić numer inwentarzowy w wybranych wierszach?';
					|tr = 'Seçilen satırlardaki stok numarasını mı dolduruyorsunuz?'");
	CallbackDescription = New CallbackDescription("FillInInventoryNumberCompletion", ThisObject);
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
	Return; // the UT has an empty handler
	
EndProcedure

&AtClient
Procedure FillInDirectionOfActivity(Command)
	
	StringsList = New Array;
	For Each RowID In Items.Goods.SelectedRows Do
		StringsList.Add(RowID);
	EndDo;
	
	If StringsList.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Cần chọn các dòng cần điền lĩnh vực hoạt động';
								|ru = 'Необходимо выбрать строки, в которых требуется заполнить направление деятельности';
								|en = 'Select lines in which line of business must be filled in'; fa = 'Select lines in which line of business must be filled in';
								|it = 'Select lines in which line of business must be filled in';
								|pl = 'Select lines in which line of business must be filled in';
								|tr = 'İş kolunun doldurulması gereken satırların seçilmesi gerekir'"));
		Return;
	EndIf;
	
	ChoiceFormParameters = TMCommonUseClientServer.ChoiceParameters(Items.GoodsLineOfBusiness, ThisObject);

	CallbackDescription = New CallbackDescription("FillInDirectionOfActivityCompletion", ThisObject, StringsList);
	
	OpenForm("Catalog.LinesOfBusiness.ChoiceForm", 
					ChoiceFormParameters,,,,,
					CallbackDescription, 
					FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region Private

// StandardSubsystems.Properties

&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	PropertyManager.FillAdditionalAttributesInForm(ThisObject);
EndProcedure

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

#Region OnChangeAttributes

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
Procedure AtEndOfChangingLocalizationDetails(TagName, NotificationParameters) Export
	
	If NotificationParameters.ServerCallRequired_ Then
		WhenYouChangeDetailsOfCompletionOnServer(TagName, NotificationParameters.ProcessingParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenYouChangeDetailsOfCompletionOnServer(Val TagName, Val AdditionalParameters)
	
	If TagName = "BusinessOperation" Then
		BusinessOperationOnChangeServer(AdditionalParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(Val ChangedBankingDetails = "")

	OnChangeAttributes(ChangedBankingDetails);
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	If StructureOfChangedProps.Property("BusinessOperation")
		Or UpdateAll Then
		
		ChangeHeadersForBusinessTransactions();

		AllAttributes = New Array;
		TransactionDetails = New Array;
		
		Documents.InventoryConsumption.FillInNamesOfBusinessTransactionDetails(
			Object.BusinessOperation,
			AllAttributes,
			TransactionDetails);
		
		CashServer.SetVisibilityOfElementsByArray(
			Items,
			AllAttributes,
			TransactionDetails);
			
		Items.Status.Visible =
			Object.BusinessOperation = Enums.BusinessTransactions.TransferToOperation
			And UseStatuses;
		
		ParametersArray = New Array;
		
		ArrayOfProductTypes = New Array();
		ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
		ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
		If Object.BusinessOperation = Enums.BusinessTransactions.GoodsConsumptionOnDemand Then
			ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
		EndIf;
		
		FixedArrayOfProductTypes = New FixedArray(ArrayOfProductTypes);
		ParametersArray.Add(New ChoiceParameter("Filter.ItemsType", FixedArrayOfProductTypes));
		
		Items.GoodsProducts.ChoiceParameters = New FixedArray(ParametersArray);
		
	EndIf; 
	
	If StructureOfChangedProps.Property("BusinessOperation")
		Or StructureOfChangedProps.Property("Warehouse")
		Or UpdateAll Then
			
		Items.GroupInformationRequiredStatuses.Visible = DisplayMessageOnUsingStatuses();
	EndIf; 
	
	If StructureOfChangedProps.Property("BusinessOperation")
		Or StructureOfChangedProps.Property("Goods")
		Or UpdateAll Then
			
		Catalogs.OperationCategories.FillInCategoryAttributes(Object.Goods);
		
	EndIf;
	
	If StructureOfChangedProps.Property("BusinessOperation")
		Or UpdateAll Then
			
		PropertyValue = (Object.BusinessOperation = Enums.BusinessTransactions.TransferToOperation);
		Items.GoodsFillInInventoryNumber.Visible = PropertyValue;
		Items.GoodsContextMenuFillInInventoryNumber.Visible = PropertyValue;
		Items.GoodsFillInIndividual.Visible = PropertyValue;
		Items.GoodsCreateGroupFA.Visible = PropertyValue;
		Items.GoodsFillInCategoryOfOperation.Visible = PropertyValue;

	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElementsOnClientOnServer(Form, ChangedBankingDetails = "")
	
	Object = Form.Object;
	Items = Form.Items;
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	If StructureOfChangedProps.Property("ExpenseLineOfBusinessIsSpecifiedInList")
		Or UpdateAll Then
		
		Items.GoodsLineOfBusiness.Visible = Object.ExpenseLineOfBusinessIsSpecifiedInList;
		Items.GoodsFillInDirectionOfActivity.Visible = Object.ExpenseLineOfBusinessIsSpecifiedInList;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnChangeAttributes(ChangedBankingDetails)
	
	If Not ValueIsFilled(ChangedBankingDetails) Then
		Return; 
	EndIf; 
	
	AttributesList = StrSplit(ChangedBankingDetails, ",");

	If AttributesList.Find("InventoryConsumptionOrder") <> Undefined Then
		
		SetAvailabilityOfFormElementsByOrder();
		
		If UseInventoryConsumptionForMultipleOrders Then
			UpdateOrderInformation();
		EndIf;
		
	EndIf; 
	
	If AttributesList.Find("BusinessOperation") <> Undefined Then
		
		FillInStatusesForSpecifyingSeriesServer(True);
		FillInServiceDetailsWhenChangingBusinessOperation();
		UpdateConsumptionForActivities_();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure BusinessOperationOnChangeServer(AdditionalParameters)
	
	ChangedBankingDetails = "BusinessOperation";
	
	If Object.BusinessOperation <> Enums.BusinessTransactions.TransferToOperation
		And Object.Status <> Enums.InternalConsumptionStatuses.Accepted Then
		Object.Status = Enums.InternalConsumptionStatuses.Accepted;
	EndIf;
	
	FillInStatusesForSpecifyingSeriesServer(True);
	
	If AdditionalParameters.ClearGoods Then
		Object.Goods.Clear();
		Object.InventoryConsumptionOrder = Undefined;
		ChangedBankingDetails = ChangedBankingDetails + ",Goods,InventoryConsumptionOrder";
		SetWhetherWarehouseIsFullOnServer();
	EndIf;
	
	// Setting up accounting accounts.
	SetupParameters = Documents.InventoryConsumption.AccountingAccountSettings_(Object.BusinessOperation);
	GLAccountSettingsServer.WhenChangingSettings(ThisObject, SetupParameters);
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.InventoryConsumption.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	ConfigureDependentFormElementsOnServer(ChangedBankingDetails);
	
	ConfigureNavigationBar();
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsWhenChangingBusinessOperation()
	
	DepartmentMandatory = GetFunctionalOption("UseProduction")
		Or GetFunctionalOption("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers")
		Or Object.BusinessOperation = Enums.BusinessTransactions.TransferToOperation;
	
EndProcedure

&AtServer
Procedure WhenChangingConsumptionForMultipleOrders(OrderRef = Undefined)

	Object.InventoryConsumptionOrder = OrderRef;
	
	If Object.ConsumptionByOrders Then
		
		If Object.Goods.Count() = 0 Then
			FillInFromOrderServer();
		Else
			BindRowsToDomesticConsumptionOrders(Not UseInventoryConsumptionForMultipleOrders);
		EndIf;
		
	Else
		
		UntieRowsFromOrders();
		Object.InventoryConsumptionOrder = Undefined;
		OrderList.Clear();
		ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
		
	EndIf;
	
	// Recalculating the Quantity of Packages field
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
	
	UpdateOrderInformation();
	SetAvailabilityOfFormElementsByOrder();
	SetAvailabilityOfClipboardCommands();
	ConfigurePickUpByOrdersOrdersCommand(False);
	LinesOfBusinessServer.SetVisibilityOfElementsSeparately(ThisObject);
	
	For Each String In Object.Goods Do
		WhenAddingLineOfProductsOnServer(String);
	EndDo;
	
EndProcedure

&AtServer
Procedure OrganizationWhenChangedOnServer()
	
	UpdateConsumptionForActivities_();
	
EndProcedure

&AtServer
Procedure WarehouseOnChangeServer()
	
	Object.PriceKind = Catalogs.Warehouses.AccountingPriceType(Object.Warehouse);
	AdvancedWarehousingOnShipment = WarehousesServer.UseWarehouseManagemantSystemForGoodsIssue(Object.Warehouse, Object.Date);
	
	ClearProductsTabularPartWhenWarehouseChanges();
	FillInStatusesForSpecifyingSeriesServer(True);
	
	SetVisibilityOfSeriesElements();
	Warehouse = Object.Warehouse;
	
	UpdateConsumptionForActivities_();
	
	ConfigurePickUpByOrdersOrdersCommand();

	ConfigureDependentFormElementsOnServer("Warehouse");
	
EndProcedure

&AtServer
Procedure ClearProductsTabularPartWhenWarehouseChanges()
	
	If Object.ConsumptionByOrders And Object.Goods.Count() > 0 Then
		
		Object.Goods.Clear();
		If UseInventoryConsumptionForMultipleOrders Then
			UpdateOrderInformation();
		EndIf;
		SetWhetherWarehouseIsFullOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure DateOnChangeServer()
	
	AdvancedWarehousingOnShipment = WarehousesServer.UseWarehouseManagemantSystemForGoodsIssue(Warehouse, Object.Date);
	ConfigurePickUpByOrdersOrdersCommand();
	
	FillInStatusesForSpecifyingSeriesServer(True);
	SetVisibilityOfSeriesElements();
	
	UpdateConsumptionForActivities_();
	
EndProcedure

&AtServer
Procedure LineOfBusinessOnChangeServer()
	
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	UpdateConsumptionForActivities_();
	
EndProcedure

&AtServer
Procedure UpdateConsumptionForActivities_(Validate = True)
	
	FillParameters = Documents.InventoryConsumption.ParametersForFillingInVATActivityType(Object);
	
	If Validate Then
		
		VATAccountingERP.FillInTypeOfActivityVAT(
			Object.ConsumptionForActivity,
			FillParameters,
			VATAccountingCachedParameterValues);
		
	EndIf;
	
	VATAccountingERP.FillInActivitySelectionList(
		Items.ConsumptionForActivity,
		Object.ConsumptionForActivity,
		FillParameters,
		VATAccountingCachedParameterValues);
	
EndProcedure

&AtClient
Procedure WhenAddingLineOfProductsOnClient(String)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, String, "Object.Goods");
	
EndProcedure

&AtServer
Procedure WhenAddingLineOfProductsOnServer(String)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, String, "Object.Goods");
	
EndProcedure

&AtClient
Procedure SetFlagForFillingWarehouseOnClient()
	
	WarehouseIsRequired = ?(Object.Goods.Total("WarehouseIsRequired") = 0, 0, 1);
	
EndProcedure

&AtServer
Procedure SetWhetherWarehouseIsFullOnServer()
	
	WarehouseIsRequired = ?(Object.Goods.Total("WarehouseIsRequired") = 0, 0, 1);
	
EndProcedure

&AtServer
Procedure UpdateVHFWarehouseObligation()
	
	FillParameters = New Structure("ThereAreWorks, IsCanceled", True, False);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("WhenChangingProductType", FillParameters);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
	WarehouseIsRequired = ?(Object.Goods.Total("WarehouseIsRequired") = 0, 0, 1);
	
EndProcedure

#EndRegion

#Region SelectionAndProcessingOfQuantityVerification

&AtClient
Procedure OpenProductSelectionByOrdersOrders()
	
	HeaderAttributes = New Structure("Organization, Department, Warehouse, SalesOpportunity, BusinessOperation, Ref, LineOfBusiness");
	FillPropertyValues(HeaderAttributes, Object);
	AdditionalFields = New Structure("DateOfShipment");
	
	FormParameters = New Structure();
	FormParameters.Insert("HeaderAttributes",                           HeaderAttributes);
	FormParameters.Insert("OrderDocument",                                    Object.InventoryConsumptionOrder);
	FormParameters.Insert("Invoice",                                Object.Ref);
	FormParameters.Insert("AdvancedWarehousingOnShipment",                 AdvancedWarehousingOnShipment);
	FormParameters.Insert("AddressGoods",                              AddressInvoiceGoods());
	FormParameters.Insert("InvoiceForOrders",                       Object.ConsumptionByOrders);
	FormParameters.Insert("UseInvoicesForSeveralOrders", UseInventoryConsumptionForMultipleOrders);
	FormParameters.Insert("OrdersAreUsed",                       OrdersAreUsed);
	FormParameters.Insert("AdditionalFields",                       AdditionalFields);
	
	OpenForm("CommonForm.AddItemsFromSalesOrderGoodsIssue",
		FormParameters, ThisForm, UUID,,,,FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtServer
Function AddressInvoiceGoods()
	
	Table = Object.Goods.Unload();
	Table.Columns.InventoryConsumptionOrder.Name = "DomesticConsumptionOrder";
	
	Table.Columns.Add("InventoryConsumptionOrder", New TypeDescription("DocumentRef.InventoryConsumptionOrder,
		|DocumentRef.RMOrder,
		|DocumentRef.InventoryConsumption"));
	Table.Columns.Add("SalesOpportunity",       New TypeDescription("CatalogRef.SalesOpportunitiesToCustomer"));
	Table.Columns.Add("DateOfShipment", New TypeDescription("Date"));
	
	For Each String In Table Do
		String.InventoryConsumptionOrder = ?(ValueIsFilled(String.DomesticConsumptionOrder),
			String.DomesticConsumptionOrder, Object.Ref);
	EndDo;
	
	Table.FillValues(Object.SalesOpportunity,       "SalesOpportunity");
	Table.FillValues(CurrentSessionDate(), "DateOfShipment");
	
	Return PutToTempStorage(Table);
	
EndFunction

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected)

	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	
	// Selection of articles and analytics.
	IncomeAndExpensesClientServer.InsertActionFillInItemCostAnalysisOfProducts(
		StructureOfActions,
		ThisObject,
		Object.BusinessOperation,
		Object.Organization,
		Object.Department);
	
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("WhenChangingProductType", New Structure("ThereAreWorks, IsCanceled", True, False));
	
	RowsToProcess = New Array();
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct, "Products, Characteristic,
			| ItemVariantsAreUsed, Package, NumberOfPackages, Series, WithAssignment");
		
		LinesOfBusinessClientServer.FillAssignmentByFlagSeparately(ThisObject, CurrentRow);
		If Object.ConsumptionByOrders Then
			CurrentRow.OrderDiscrepancy_3 = 1;
		EndIf;
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods);
			
	For Each CurrentRow In RowsToProcess Do
		WhenAddingLineOfProductsOnServer(CurrentRow);
	EndDo;

	FillInStatusesForSpecifyingSeriesServer();
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
	UpdateDependentDetailsOfServerByOrderForm();
	SetWhetherWarehouseIsFullOnServer();
	
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
EndProcedure

&AtServer
Function PutTablePartOfGoodsInTemporaryStorageToCheckQuantity(OnlyNonLabeledProductsHaveBeenUnloaded = False)
	
	TabularPartProducts = Object.Goods.Unload();
	If TabularPartProducts.Columns.Find("MarkedProducts") <> Undefined Then
		CurrentRowNumber = TabularPartProducts.Count()-1;
		While CurrentRowNumber >= 0 Do
			If TabularPartProducts[CurrentRowNumber].MarkedProducts Then
				TabularPartProducts.Delete(CurrentRowNumber);
				OnlyNonLabeledProductsHaveBeenUnloaded = True;
			EndIf;
			CurrentRowNumber = CurrentRowNumber - 1;
		EndDo;
	EndIf;
	TabularPartProducts.GroupBy("Products, Characteristic, Series, BatchesIndicationStatus, ItemsType, ItemVariantsAreUsed, Package", "NumberOfPackages");
	
	AddressInTempStorage = PutToTempStorage(TabularPartProducts, UUID);
	
	Return AddressInTempStorage;
	
EndFunction

&AtServer
Procedure ChangeTablePartBasedOnResultsOfCheck(ReturnParameters, CachedValues)
	
	GoodsTable = GetFromTempStorage(ReturnParameters.Goods);
	
	StructureOfActionsFoundLines = New Structure;
	
	// Selection of articles and analytics.
	IncomeAndExpensesClientServer.InsertActionFillInItemCostAnalysisOfProducts(
		StructureOfActionsFoundLines,
		ThisObject,
		Object.BusinessOperation,
		Object.Organization,
		Object.Department);
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsFoundLines);
	StructureOfActionsFoundLines.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsFoundLines.Insert("WhenChangingProductType", New Structure("ThereAreWorks, IsCanceled", True, False));

	StructureOfActionsNewLines = New Structure;
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsNewLines);
	StructureOfActionsNewLines.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsNewLines.Insert("WhenChangingProductType", New Structure("ThereAreWorks, IsCanceled", True, False));
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Products", StructureOfActionsNewLines);
		
	ProcessedNewLines = New Array;
	ProcessedFoundRows = New Array;
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
				ProcessedFoundRows.Add(TSRow);
			EndIf;
			
		EndDo;
		
		If FoundRows.Count() = 0 Then
			
			TSRow = Object.Goods.Add();
			FillPropertyValues(TSRow, SourceRow);
			ProcessedNewLines.Add(TSRow);
			
		EndIf;
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ProcessedNewLines,
		StructureOfActionsNewLines,
		Object.Goods,
		CachedValues);
		
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ProcessedFoundRows,
		StructureOfActionsFoundLines,
		Object.Goods,
		CachedValues);

	For Each TSRow In ProcessedNewLines Do
		WhenAddingLineOfProductsOnServer(TSRow);
	EndDo;
	
	For Each TSRow In ProcessedFoundRows Do
		WhenAddingLineOfProductsOnServer(TSRow);
	EndDo;

	For Each TSRow In LinesToDelete Do
		Object.Goods.Delete(TSRow);
	EndDo;
	
	FillInStatusesForSpecifyingSeriesServer();
	
	SetWhetherWarehouseIsFullOnServer();
	
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
EndProcedure

&AtClient
Procedure CheckQuantityInTheDocument(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.InventoryConsumption.DocumentForm.Command.CheckQuantityInTheDocument");
	
	OnlyNonLabeledProductsHaveBeenUnloaded = False;
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("AddressInTempStorage",             PutTablePartOfGoodsInTemporaryStorageToCheckQuantity(OnlyNonLabeledProductsHaveBeenUnloaded));
	OpeningParameters.Insert("TabularSectionName",                    "Goods");
	OpeningParameters.Insert("Ref",                               Object.Ref);
	OpeningParameters.Insert("GoodsQuantityExcessIsAllowed", Not Object.ConsumptionByOrders Or InventoryConsumptionInExcessOfOrder);
	OpeningParameters.Insert("SeriesSpecificationParameters",               SeriesSpecificationParameters);
	OpeningParameters.Insert("Warehouse",                                Object.Warehouse);
	OpeningParameters.Insert("OnlyNonLabeledProductsHaveBeenUnloaded", OnlyNonLabeledProductsHaveBeenUnloaded);
	
	OpenForm("CommonForm.CheckDocumentPopulation", OpeningParameters,,,,, New CallbackDescription("CheckQuantityInTheDocumentCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure CheckQuantityInTheDocumentCompletion(Result, AdditionalParameters) Export
    
    ReturnParameters = Result;
    
    If ReturnParameters <> Undefined Then
        ChangeTablePartBasedOnResultsOfCheck(ReturnParameters, 
        ?(CachedValues = Undefined, BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues(), CachedValues));
        Modified = True;
        
        BaseText = NStr("vi = 'đã nhập trên cơ sở lệnh hoặc không sử dụng được vai trò ""Tiêu thụ nội bộ vượt quá đơn hàng"".';
						|ru = 'введенного на основании распоряжения или недоступна роль ""Внутреннее потребление сверх заказа"".';
						|en = 'entered based on the reference, or the ""Inventory consumption in excess of order"" role is unavailable.'; fa = 'entered based on the reference, or the ""Inventory consumption in excess of order"" role is unavailable.';
						|it = 'введенного на основании распоряжения или недоступна роль ""Внутреннее потребление сверх заказа"".';
						|pl = 'entered based on the reference, or the ""Inventory consumption in excess of order"" role is unavailable.';
						|tr = 'sipariş baz alınarak girilir veya ""Siparişi aşan stok tüketimi"" rolü kullanılamaz.'");
        TMCommonUseClient.DisplayMessageExceedingNumber(ReturnParameters, BaseText);
    EndIf;

EndProcedure

&AtClient
Procedure SpecifySeries(Command)
	
	OpenSelectionOfSeries();
	
EndProcedure

&AtClient
Procedure SplitRow(Command)
	
	If Not YouCanSplitString() Then
		Return;
	EndIf; 
	
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
		GLAccountSettingsClient.WhenCopyingString(ThisObject, Items.Goods, NewRow);
	EndIf;
	
	UpdateDependentDetailsOfOrderForm_(
		Object.Goods,
		DiscrepancyOrderText, 
		Items.PictureDiscrepancyOrder,
		Items.PictureDiscrepancyOrders);
	
EndProcedure

&AtServer
Procedure ProcessingProductSelectionFromOrder(AddressInStorage)
	
	CalculationResult1 = GetFromTempStorage(AddressInStorage);
	Object.PackageBarcodes.Load(CalculationResult1.PackageBarcodes);
	Table = CalculationResult1.Goods; // TabularSection
	
	FieldsNames = "LineNumber";
	TheStructureOfTheSearch = New Structure(FieldsNames);
	Table.Sort(FieldsNames + " Desc");
	
	AnArrayOfOrders = Table.UnloadColumn("InventoryConsumptionOrder");
	LineOfBusinessOfExpensesIsIndicatedInListForOrders = Documents.InventoryConsumption.ToIncicializeAreasOfActivityOfExpenses(AnArrayOfOrders);
	
	If Object.Goods.Count() = 0 Then
		Object.ExpenseLineOfBusinessIsSpecifiedInList = LineOfBusinessOfExpensesIsIndicatedInListForOrders
	Else
		Object.ExpenseLineOfBusinessIsSpecifiedInList = LineOfBusinessOfExpensesIsIndicatedInListForOrders Or ExpenseLineOfBusinessIsSpecifiedInList = 1
	EndIf;		
	ExpenseLineOfBusinessIsSpecifiedInList = ?(Object.ExpenseLineOfBusinessIsSpecifiedInList, 1, 0);
	
	// Grouping a table by row keys.
	StringTree = New Array();
	For Each TableRow In Table Do
		
		If TheStructureOfTheSearch.LineNumber <> TableRow.LineNumber Then
			
			RowsArray = New Array();
			StringTree.Add(RowsArray);
			
			FillPropertyValues(TheStructureOfTheSearch, TableRow);
			
		EndIf;
		
		If ExpenseLineOfBusinessIsSpecifiedInList = 1 And Not LineOfBusinessOfExpensesIsIndicatedInListForOrders Then
			TableRow.LineOfBusiness = Common.ObjectAttributeValue(TableRow.InventoryConsumptionOrder, "LineOfBusiness");
		EndIf;
			
		RowsArray.Add(TableRow);
		
	EndDo;
	
	OrderRelationshipFields = New Structure("RowCode, InventoryConsumptionOrder", 0, Undefined);
	AddedRows = InvoicesServer.FillInProductsSelectedFromOrder(StringTree, FieldsNames, Object.Goods, OrderRelationshipFields);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("WhenChangingProductType", New Structure("ThereAreWorks, IsCanceled", True, False));
	// Selection of articles and analytics.
	IncomeAndExpensesClientServer.InsertActionFillInItemCostAnalysisOfProducts(
		StructureOfActions,
		ThisObject,
		Object.BusinessOperation,
		Object.Organization,
		Object.Department);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		AddedRows,
		StructureOfActions,
		Object.Goods,
		CachedValues);
			
	For Each LineProducts_ In AddedRows Do
		
		If ValueIsFilled(LineProducts_.InventoryConsumptionOrder) Then
			Object.ConsumptionByOrders = True;
			If Not UseInventoryConsumptionForMultipleOrders Then
				Object.InventoryConsumptionOrder = LineProducts_.InventoryConsumptionOrder;
			EndIf;
		EndIf;
		WhenAddingLineOfProductsOnServer(LineProducts_);
	EndDo;
	
	Documents.InventoryConsumption.ProcessDocumentAfterAddingLines(Object);
	
	FillInServiceDetailsOfTablePart();
	FillInStatusesForSpecifyingSeriesServer();
	
	UpdateOrderInformation();
	SetAvailabilityOfFormElementsByOrder();
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	ConfigureDependentFormElementsOnServer("BusinessOperation,Goods,ExpenseLineOfBusinessIsSpecifiedInList");
	
	If Object.ConsumptionByOrders Then
		For Each String In Object.Goods Do
			If String.RowCode = 0 Then
				String.Purpose = Catalogs.Assignments.EmptyRef();
			EndIf;
		EndDo;
	EndIf;
	LinesOfBusinessServer.SetVisibilityOfElementsSeparately(ThisObject);
	LinesOfBusinessServer.ReFillInServiceDetailsOfTablePart(ThisObject);
	
	SetWhetherWarehouseIsFullOnServer();
	
	SalesServerLocalization.TransferBarcodesOfPackages(ThisObject, CalculationResult1.PackageBarcodes);
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
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
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithAddedStrings);
	
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	
	// Selection of articles and analytics.
	IncomeAndExpensesClientServer.InsertActionFillInItemCostAnalysisOfProducts(
		StructureOfActionsWithAddedStrings,
		ThisObject,
		Object.BusinessOperation,
		Object.Organization,
		Object.Department);
	
	SeriesVerificationParameters = New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters);
	StructureOfActionsWithAddedStrings.Insert("CheckSeriesCalculateStatus", SeriesVerificationParameters);
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Products", StructureOfActionsWithAddedStrings);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithAddedStrings);
	
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActionsWithAddedStrings);
	
	StructureOfActionsWithModifiedStrings = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithModifiedStrings);
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActionsWithModifiedStrings);
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	StructureOfActions.SeriesSpecificationParameters                 = SeriesSpecificationParameters;
	StructureOfActions.AddOnlyProductsOverAndAboveOrder        = True;

	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.GoodsConsumptionOnDemand") Then
		StructureOfActions.OnlyGoodsAndWork = True;
	Else
		StructureOfActions.GoodsOnly = True;
	EndIf;
	
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
	
	For Each String In Object.Goods Do
		WhenAddingLineOfProductsOnServer(String);
		UpdateOrderDeviationsInLine(String, Object.ConsumptionByOrders);
	EndDo;
	
	UpdateDependentDetailsOfOrderForm_(
		Object.Goods,
		DiscrepancyOrderText,
		Items.PictureDiscrepancyOrder, 
		Items.PictureDiscrepancyOrders);
	
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
EndProcedure

#EndRegion

#Region SetOfSeries

&AtServer
Function ThereAreFilledSeriesByFEFO()

	Return ProductsServer.ThereAreLinesWithFEFOFilledSeries(Object.Goods);

EndFunction

&AtClient
Procedure FillInSeriesByFEFO(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.InventoryConsumption.DocumentForm.Command.FillInSeriesByFEFO");
	
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

&AtClient
Procedure OpenSeriesSelectionWhenScanningProductBarCode()

	If CurDataId = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.Goods.FindByID(CurDataId);
	OpenSelectionOfSeries(,CurrentData);

EndProcedure

&AtServer
Procedure SetVisibilityOfSeriesElements()
	
	Items.GoodsBatchesIndicationStatus.Visible  = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsSpecifySeries.Visible         = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsFillInSeriesByFEFO.Visible = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsSeries.Visible                = SeriesSpecificationParameters.UseItemsBatch;
	
	YouCanPopulateSeriesByShipment = 
		AdvancedWarehousingOnShipment
		And GetFunctionalOption("UseItemsBatchWarehouse",New Structure("Warehouse", Object.Warehouse))
		And GetFunctionalOption("UseItemsBatchWarehouse", New Structure());
	
EndProcedure

&AtServer
Procedure ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm)
	
	ProductsServer.ProcessSeriesIndication_(Object,SeriesSpecificationParameters,ParametersOfSeriesIndicationForm);
	
EndProcedure

&AtServer
Procedure FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues)
	
	ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Object, 
		SeriesSpecificationParameters, IDCurrentRow, CachedValues);
	
EndProcedure

&AtServer
Procedure FillInStatusesForSpecifyingSeriesServer(UpdateParametersForSpecifyingSeries = False)
	
	If UpdateParametersForSpecifyingSeries Then
		SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.InventoryConsumption));
	EndIf; 
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	
EndProcedure

#EndRegion

#Region FillingByOrderByOrder

&AtClient
Procedure ConsumptionByOrderSetOrderSelected(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Object.ConsumptionByOrders = False;
	Else
		ThereAreLinesBeforeFilling = Object.Goods.Count() > 0;
		WhenChangingConsumptionForMultipleOrders(Result);
		If ThereAreLinesBeforeFilling Then
			NotifyAboutLinkingRowsToOrders(Result);
		Else
			NotifyAboutFillingInOrderBalances(Result);
			Object.ConsumptionByOrders = Object.Goods.Count() > 0;
		EndIf;
		UpdateDependentDetailsOfServerByOrderForm();
		SetVisibilityOfCommandsByOrder();
	EndIf;
	
EndProcedure

&AtClient
Procedure NotifyAboutLinkingRowsToOrders(OrderRef = Undefined)
	
	If OrderRef <> Undefined Then
		
		TextTemplate1 = NStr("vi = 'Các dòng trong danh sách ""Hàng hóa"" được gắn với các dòng của chứng từ %OrderDocument%.';
							|ru = 'Строки в списке ""Товары"" привязаны к строкам документа %OrderDocument%.';
							|en = 'Lines in Item list are linked to lines of document %OrderDocument%.'; fa = 'Lines in Item list are linked to lines of document %OrderDocument%.';
							|it = 'Le righe nell''elenco ""Merci"" sono collegate alle righe del documento %OrderDocument%.';
							|pl = 'Wiersze w liście ""Товары"" są przywiązane do wierszy dokumentu %OrderDocument%.';
							|tr = '""Ürünler"" listesindeki satırlar %OrderDocument%belgesinin satırlarına bağlanır.'");
		NotificationText1 = StrReplace(TextTemplate1, "%OrderDocument%", OrderRef);
		
	Else
		
		NotificationText1 = NStr("vi = 'Các dòng trong danh sách ""Hàng hóa"" được gắn với các dòng đơn hàng chưa lập.';
								|ru = 'Строки в списке ""Товары"" привязаны к строкам неоформленных заказов.';
								|en = 'Lines in Item list are linked to ungenerated order lines.'; fa = 'Lines in Item list are linked to ungenerated order lines.';
								|it = 'Le righe nell''elenco ""Merci"" sono collegate alle righe degli ordini non formalizzati.';
								|pl = 'Wiersze w liście ""Товары"" są przywiązane do wierszy niesporządzonych zamówień.';
								|tr = 'Ürünler listesindeki satırlar, verilmemiş siparişlerin satırlarına bağlanır.'");
		
	EndIf;
	
	ShowUserNotification(NStr("vi = 'Bộ xử lý danh sách ""Hàng hóa""';
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
		
			TextTemplate1 = NStr("vi = 'Danh sách ""Hàng hóa"" đã điền số dư hàng hóa chưa lập theo chứng từ %OrderDocument%.';
								|ru = 'Список ""Товары"" заполнен остатками неоформленных товаров по документу %OrderDocument%.';
								|en = 'The Item list is filled in with remaining unregistered goods under the %OrderDocument% document.'; fa = 'The Item list is filled in with remaining unregistered goods under the %OrderDocument% document.';
								|it = 'L''elenco ""Merci"" è compilato con le rimanenze delle merci non formalizzate per il documento %OrderDocument%.';
								|pl = 'Lista ""Towarów"" jest wypełniona resztkami nieusuniętych towarów na dokumencie %OrderDocument%.';
								|tr = '""Ürünler"" listesi, belgeye göre düzenlenmeyen stok bakiyesi ile doldurulur %OrderDocument%.'");
			NotificationText1 = StrReplace(TextTemplate1, "%OrderDocument%", OrderRef);
			
		Else
			
			NotificationText1 = NStr("vi = 'Danh sách ""Hàng hóa"" đã điền số dư hàng hóa chưa lập theo đơn hàng.';
									|ru = 'Список ""Товары"" заполнен остатками неоформленных товаров по заказам.';
									|en = 'The Item list is filled in with remaining unregistered goods against orders.'; fa = 'The Item list is filled in with remaining unregistered goods against orders.';
									|it = 'L''elenco ""Merci"" è compilato con le rimanenze delle merci non formalizzate per gli ordini.';
									|pl = 'Lista ""Towarów"" jest wypełniona pozostałościami nieformalnych towarów wg zamówień.';
									|tr = '""Ürünler"" listesi, siparişlerdeki düzenlenmeyen stok bakiyesi ile doldurulur.'");
			
		EndIf;
		ShowUserNotification(NStr("vi = 'Bộ xử lý danh sách ""Hàng hóa""';
									|ru = 'Обработка списка ""Товары""';
									|en = 'The Item list processing'; fa = 'The Item list processing';
									|it = 'Elaborazione dell''elenco ""Merci""';
									|pl = 'Przetwarzanie listy ""Wiersze pozycji""';
									|tr = '""Ürünler"" listesinin işlenmesi'"),, NotificationText1);
		
	Else
		
		If OrderRef <> Undefined Then
		
			TextTemplate1 = NStr("vi = 'Không có hàng hóa chưa lập theo chứng từ %OrderDocument%.';
								|ru = 'Нет неоформленных товаров по документу %OrderDocument%.';
								|en = 'No unregistered goods for document %OrderDocument%.'; fa = 'No unregistered goods for document %OrderDocument%.';
								|it = 'Nono ci sono merci non registrate per il documento %OrderDocument%.';
								|pl = 'Brak niezarejestrowanych towarów w dokumencie %OrderDocument%.';
								|tr = 'Belgeye göre düzenlenmeyen ürünler bulunmamaktadır %OrderDocument%.'");
			NotificationText1 = StrReplace(TextTemplate1, "%OrderDocument%", OrderRef);
			
		Else
			
			If Not ValueIsFilled(Object.Warehouse) Then
				NotificationText1 = NStr("vi = 'Chưa điền kho bãi.';
										|ru = 'Не заполнен склад.';
										|en = 'Warehouse is required.'; fa = 'Warehouse is required.';
										|it = 'Magazzino non è compilato.';
										|pl = 'Nie wypełniono magazynu.';
										|tr = 'Depo dolu değil.'");
			ElsIf Not ValueIsFilled(Object.Organization) Then
				NotificationText1 = NStr("vi = 'Chưa điền doanh nghiệp.';
										|ru = 'Не заполнена организация.';
										|en = 'Company is required.'; fa = 'Company is required.';
										|it = 'Società non è compilata.';
										|pl = 'Firma nie jest wypełniona.';
										|tr = 'İş yeri doldurulmadı.'");
			ElsIf UseMultipleCompanies And UseBusinessUnits And ValueIsFilled(Object.Department) Then
				TextTemplate1 = NStr("vi = 'Không có hàng hóa chưa lập chứng từ theo đơn hàng tiêu dùng nội bộ 
				                        |từ kho ""%1"" trong bộ phận ""%2"" trong doanh nghiệp ""%3""';
				                        |ru = 'Нет неоформленных товаров по заказам на внутреннее потребление
				                        |со склада ""%1"" в подразделении ""%2"" в организации ""%3""';
				                        |en = 'No unregistered goods of inventory consumption orders
				                        |from warehouse ""%1"" in business unit ""%2"" in company ""%3""'; fa = 'No unregistered goods of inventory consumption orders
				                        |from warehouse ""%1"" in business unit ""%2"" in company ""%3""';
				                        |it = 'Non ci sono merci non registrate per gli ordini per il consumo interno
				                        |dal magazzino ""%1"" del reparto ""%2"" della società ""%3""';
				                        |pl = 'Brak niezarejestrowanych towarów według zamówień na konsumpcję wewnętrzną 
				                        |z magazynu ""%1"" w dziale ""%2"" w firmie ""%3""';
				                        |tr = '""%3"" iş yerinin ""%2"" departmanındaki ""%1"" deposundan stok tüketimi emirlerinde
				                        |kaydedilmemiş ürün yok'");
				NotificationText1 = StringFunctionsClientServer.SubstituteParametersToString(TextTemplate1,
					Object.Warehouse, Object.Department, Object.Organization);
			ElsIf UseMultipleCompanies Then
				TextTemplate1 = NStr("vi = 'Không có hàng hóa chưa lập chứng từ theo đơn hàng tiêu dùng nội bộ 
				                        |từ kho ""%1"" trong doanh nghiệp ""%2""';
				                        |ru = 'Нет неоформленных товаров по заказам на внутреннее потребление
				                        |со склада ""%1"" в организации ""%2""';
				                        |en = 'No unregistered goods of inventory consumption orders
				                        |from warehouse ""%1"" in company ""%2""'; fa = 'No unregistered goods of inventory consumption orders
				                        |from warehouse ""%1"" in company ""%2""';
				                        |it = 'Non ci sono merci non registrate per gli ordini per il consumo interno
				                        |dal magazzino ""%1"" della società ""%2""';
				                        |pl = 'Brak niezarejestrowanych towarów według zamówień na konsumpcję wewnętrzną 
				                        |z magazynu ""%1"" w firmie ""%2""';
				                        |tr = '""%2"" iş yerindeki ""%1"" deposundan stok tüketimi emirlerinde
				                        |kaydedilmemiş ürün yok'");
				NotificationText1 = StringFunctionsClientServer.SubstituteParametersToString(TextTemplate1,
					Object.Warehouse, Object.Organization);
			ElsIf UseBusinessUnits And ValueIsFilled(Object.Department) Then
				TextTemplate1 = NStr("vi = 'Không có hàng hóa chưa lập chứng từ theo đơn hàng tiêu dùng nội bộ
				                        |từ kho ""%1"" trong bộ phận ""%2""';
				                        |ru = 'Нет неоформленных товаров по заказам на внутреннее потребление
				                        |со склада ""%1"" в подразделении ""%2""';
				                        |en = 'No unregistered goods of inventory consumption orders
				                        |from warehouse ""%1"" in business unit ""%2""'; fa = 'No unregistered goods of inventory consumption orders
				                        |from warehouse ""%1"" in business unit ""%2""';
				                        |it = 'Non ci sono merci non registrate per gli ordini per consumo interno
				                        |dal magazzino ""%1"" del reparto ""%2""';
				                        |pl = 'Brak niezarejestrowanych towarów według zamówień na konsumpcję wewnętrzną 
				                        |z magazynu ""%1"" w dziale ""%2""';
				                        |tr = '""%2"" departmanındaki ""%1"" deposundan stok tüketimi emirlerinde
				                        |kaydedilmemiş ürün yok'");
				NotificationText1 = StringFunctionsClientServer.SubstituteParametersToString(TextTemplate1,
					Object.Warehouse, Object.Department);
			Else
				TextTemplate1 = NStr("vi = 'Không có hàng hóa chưa lập chứng từ theo đơn hàng tiêu dùng nội bộ 
				                        |từ kho ""%1""';
				                        |ru = 'Нет неоформленных товаров по заказам на внутреннее потребление
				                        |со склада ""%1""';
				                        |en = 'No unregistered goods of inventory consumption orders
				                        |from warehouse ""%1""'; fa = 'No unregistered goods of inventory consumption orders
				                        |from warehouse ""%1""';
				                        |it = 'Non ci sono merci non registrate per gli ordini per consumo interno
				                        |dal magazzino ""%1""';
				                        |pl = 'Brak niezarejestrowanych towarów według zamówień na konsumpcję wewnętrzną 
				                        |z magazynu ""%1""';
				                        |tr = '""%1"" deposundan 
				                        | stok tüketimi  emirlerinde kaydedilmemiş ürün yok'");
				NotificationText1 = StringFunctionsClientServer.SubstituteParametersToString(TextTemplate1,
					Object.Warehouse);
			EndIf;
			
		EndIf;
		ShowMessageBox(, NotificationText1);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UntieRowsFromOrders()
	
	StructureOfActions = New Structure();
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	
	For Each CurRow In Object.Goods Do
		CurRow.RowCode = 0;
		CurRow.InventoryConsumptionOrder = Undefined;
	EndDo;

	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
	
EndProcedure

&AtServer
Function BindRowsToDomesticConsumptionOrders(SelectByOrder_ = False)
	
	QueryTexts = New Array();
	Text =
		"SELECT
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic
		|INTO Goods
		|FROM
		|	&Goods AS Goods
		|WHERE
		|	Goods.RowCode = 0
		|	AND Goods.InventoryConsumptionOrder IN(&EmptyOrderValues)";
	QueryTexts.Add(Text);
	
	Texts = New Array();
	If AccessRight("Read", Metadata.Documents.InventoryConsumptionOrder) Then
		
		Text =
			"SELECT
			|	Table.Ref AS OrderDocument
			|FROM
			|	Document.InventoryConsumptionOrder AS Table
			|WHERE
			|	CASE WHEN &SelectByOrder_ THEN
			|				Table.Ref = &OrderDocument
			|			ELSE Table.Department = &Department
			|				AND Table.Organization = &Organization
			|				AND Table.Warehouse = &Warehouse
			|				AND Table.SalesOpportunity = &SalesOpportunity
			|				AND Table.BusinessOperation = &BusinessOperation
			|		END
			|	AND Table.Posted";
		Texts.Add(Text);
		
	EndIf;
	If AccessRight("Read", Metadata.Documents.RMOrder) Then
		
		Text =
			"SELECT
			|	Table.Ref AS OrderDocument
			|FROM
			|	Document.RMOrder AS Table
			|WHERE
			|	CASE WHEN &SelectByOrder_ THEN
			|				Table.Ref = &OrderDocument
			|			ELSE Table.Department = &Department
			|				AND Table.Organization = &Organization
			|				AND &BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
			|		END
			|	AND Table.Posted";
		Texts.Add(Text);
		
	EndIf;
	Text =
		"SELECT ALLOWED
		|	Table.OrderDocument AS OrderDocument
		|INTO TTOrdersSelection
		|FROM
		|	&MergeText AS Table";
	MergeText = StrConcat(Texts, TMCommonUse.QuerySeparatorInJoin());
	Text = StrReplace(Text, "&MergeText", StrTemplate("(%1)", MergeText));
	QueryTexts.Add(Text);
	
	Text =
		"SELECT ALLOWED
		|	OrdersTable.InventoryConsumptionOrder AS InventoryConsumptionOrder,
		|	OrdersTable.Products AS Products,
		|	OrdersTable.Characteristic AS Characteristic,
		|	OrdersTable.RowCode AS RowCode,
		|	SUM(OrdersTable.ToRegister) AS ToRegisterBalance
		|INTO DomesticConsumptionOrdersWithoutAnalytics
		|FROM
		|	(
		|	// ORDER FOR DOMESTIC CONSUMPTION
		|	SELECT
		|		Orders.InventoryConsumptionOrder AS InventoryConsumptionOrder,
		|		Orders.Products AS Products,
		|		Orders.Characteristic AS Characteristic,
		|		Orders.RowCode AS RowCode,
		|		Orders.ToRegisterBalance AS ToRegister
		|	FROM
		|		AccumulationRegister.InventoryConsumptionOrders.Balance(
		|				,
		|					InventoryConsumptionOrder IN(
		|						SELECT
		|							Table.OrderDocument AS OrderDocument
		|						FROM
		|							TTOrdersSelection AS Table)
		|					AND (Products, Characteristic) IN
		|						(SELECT
		|							Goods.Products AS Products,
		|							Goods.Characteristic AS Characteristic
		|						FROM
		|							Goods AS Goods)
		|					AND (Warehouse = &Warehouse OR Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5))) AS Orders
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		TrafficOrders.InventoryConsumptionOrder,
		|		TrafficOrders.Products,
		|		TrafficOrders.Characteristic,
		|		TrafficOrders.RowCode,
		|		CASE
		|			WHEN TrafficOrders.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -TrafficOrders.ToRegister
		|			ELSE TrafficOrders.ToRegister
		|		END
		|	FROM
		|		AccumulationRegister.InventoryConsumptionOrders AS TrafficOrders
		|	WHERE
		|		TrafficOrders.Recorder = &Recorder
		|		AND TrafficOrders.Active
		|		AND TrafficOrders.InventoryConsumptionOrder IN(
		|						SELECT
		|							Table.OrderDocument AS OrderDocument
		|						FROM
		|							TTOrdersSelection AS Table)
		|		AND (TrafficOrders.Warehouse = &Warehouse OR TrafficOrders.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5))
		|		AND (TrafficOrders.Products, TrafficOrders.Characteristic) IN
		|				(SELECT
		|					Goods.Products AS Products,
		|					Goods.Characteristic AS Characteristic
		|				FROM
		|					Goods AS Goods)) AS OrdersTable
		|
		|GROUP BY
		|	OrdersTable.Products,
		|	OrdersTable.Characteristic,
		|	OrdersTable.RowCode,
		|	OrdersTable.InventoryConsumptionOrder
		|
		|HAVING
		|	SUM(OrdersTable.ToRegister) > 0";
	QueryTexts.Add(Text);
	
	Texts = New Array();
	
	If AccessRight("Read", Metadata.Documents.InventoryConsumptionOrder) Then
		
		Text =
			"SELECT
			|	OrdersTable.InventoryConsumptionOrder AS InventoryConsumptionOrder,
			|	OrdersTable.Products AS Products,
			|	OrdersTable.Characteristic AS Characteristic,
			|	OrdersTable.RowCode AS RowCode,
			|	OrderingProducts.Ref.SalesOpportunity AS SalesOpportunity,
			|	OrdersTable.ToRegisterBalance AS ToRegisterBalance,
			|	OrderingProducts.ExpenseItem AS ExpenseItem,
			|	OrderingProducts.DimensionOfExpenses AS DimensionOfExpenses,
			|	OrderingProducts.ProductsGroup AS ProductsGroup,
			|	OrderingProducts.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
			|	CASE
			|		WHEN OrderingProducts.WithAssignment
			|			THEN OrdersTable.InventoryConsumptionOrder.Purpose
			|		ELSE VALUE(Catalog.Assignments.EmptyRef)
			|	END AS Purpose,
			|	OrderingProducts.Individual AS Individual,
			|	OrderingProducts.OperationCategory AS OperationCategory,
			|	CASE 
			|		WHEN OrderingProducts.Ref.ExpenseLineOfBusinessIsSpecifiedInList THEN
			|			OrderingProducts.LineOfBusiness
			|		ELSE
			|			OrderingProducts.Ref.LineOfBusiness
			|	END AS LineOfBusiness
			|FROM
			|	DomesticConsumptionOrdersWithoutAnalytics AS OrdersTable
			|		
			|		INNER JOIN Document.InventoryConsumptionOrder.Goods AS OrderingProducts
			|		ON OrderingProducts.Ref = OrdersTable.InventoryConsumptionOrder
			|			AND OrderingProducts.RowCode = OrdersTable.RowCode";
		Texts.Add(Text);
		
	EndIf;
	If AccessRight("Read", Metadata.Documents.RMOrder) Then
		
		Text =
			"SELECT
			|	OrdersTable.InventoryConsumptionOrder AS InventoryConsumptionOrder,
			|	OrdersTable.Products AS Products,
			|	OrdersTable.Characteristic AS Characteristic,
			|	OrdersTable.RowCode AS RowCode,
			|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
			|	OrdersTable.ToRegisterBalance AS ToRegisterBalance,
			|	RM.ExpenseItem AS ExpenseItem,
			|	CASE 
			|		WHEN RM.ExpenseItem.ExpensesOnAssets
			|			THEN MaterialsAndWorks.Ref.Asset
			|		WHEN RM.ExpenseItem.RMOrderExpenses
			|			THEN MaterialsAndWorks.Ref
			|		ELSE UNDEFINED
			|	END AS DimensionOfExpenses,
			|	VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef) AS ProductsGroup,
			|	UNDEFINED AS AssetsLiabilitiesDimension,
			|	
			|	CASE WHEN MaterialsAndWorks.WithAssignment THEN
			|				
			|				OrdersTable.InventoryConsumptionOrder.Purpose
			|				
			|			ELSE
			|				
			|				VALUE(Catalog.Assignments.EmptyRef)
			|				
			|		END AS Purpose,
			|
			|	VALUE(Catalog.Persons.EmptyRef) AS Individual,
			|	VALUE(Catalog.OperationCategories.EmptyRef) AS OperationCategory,
			|	MaterialsAndWorks.Ref.LineOfBusiness AS LineOfBusiness
			|
			|FROM
			|	DomesticConsumptionOrdersWithoutAnalytics AS OrdersTable
			|		
			|		INNER JOIN Document.RMOrder.MaterialsAndWorks AS MaterialsAndWorks
			|		ON MaterialsAndWorks.Ref = OrdersTable.InventoryConsumptionOrder
			|			AND MaterialsAndWorks.RowCode = OrdersTable.RowCode
			|		
			|		INNER JOIN Document.RMOrder.RM AS RM
			|		ON RM.Ref = MaterialsAndWorks.Ref
			|			AND RM.RMCode = MaterialsAndWorks.RMCode";
		Texts.Add(Text);
		
	EndIf;
	MergeText = StrConcat(Texts, TMCommonUse.QuerySeparatorInJoin());
	
	Text =
		"SELECT ALLOWED
		|	OrdersTable.InventoryConsumptionOrder AS InventoryConsumptionOrder,
		|	OrdersTable.Products AS Products,
		|	OrdersTable.Characteristic AS Characteristic,
		|	OrdersTable.RowCode AS RowCode,
		|	OrdersTable.SalesOpportunity AS SalesOpportunity,
		|	OrdersTable.ToRegisterBalance AS ToRegisterBalance,
		|	OrdersTable.ExpenseItem AS ExpenseItem,
		|	OrdersTable.DimensionOfExpenses AS DimensionOfExpenses,
		|	OrdersTable.ProductsGroup AS ProductsGroup,
		|	OrdersTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
		|	OrdersTable.Purpose AS Purpose,
		|	OrdersTable.Individual AS Individual,
		|	OrdersTable.OperationCategory AS OperationCategory,
		|	OrdersTable.LineOfBusiness AS LineOfBusiness
		|INTO InventoryConsumptionOrders
		|FROM
		|	&MergeText AS OrdersTable";
	
	Text = StrReplace(Text, "&MergeText", StrTemplate("(%1)", MergeText));
	QueryTexts.Add(Text);
	
	Text =
		"SELECT
		|	COUNT(*) AS DuplicateCount,
		|	InventoryConsumptionOrders.Products AS Products,
		|	InventoryConsumptionOrders.Characteristic AS Characteristic,
		|	InventoryConsumptionOrders.ExpenseItem AS ExpenseItem,
		|	InventoryConsumptionOrders.DimensionOfExpenses AS DimensionOfExpenses,
		|	InventoryConsumptionOrders.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
		|	InventoryConsumptionOrders.ProductsGroup AS ProductsGroup,
		|	InventoryConsumptionOrders.Individual AS Individual,
		|	InventoryConsumptionOrders.OperationCategory AS OperationCategory,
		|	InventoryConsumptionOrders.LineOfBusiness AS LineOfBusiness
		|INTO DuplicatesOfProducts
		|FROM
		|	InventoryConsumptionOrders AS InventoryConsumptionOrders
		|
		|GROUP BY
		|	InventoryConsumptionOrders.Products,
		|	InventoryConsumptionOrders.Characteristic,
		|	InventoryConsumptionOrders.ExpenseItem,
		|	InventoryConsumptionOrders.DimensionOfExpenses,
		|	InventoryConsumptionOrders.ProductsGroup,
		|	InventoryConsumptionOrders.AssetsLiabilitiesDimension,
		|	InventoryConsumptionOrders.Individual,
		|	InventoryConsumptionOrders.OperationCategory,
		|	InventoryConsumptionOrders.LineOfBusiness
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Orders.InventoryConsumptionOrder AS InventoryConsumptionOrder,
		|	Orders.Products AS Products,
		|	Orders.Characteristic AS Characteristic,
		|	Orders.ExpenseItem AS ExpenseItem,
		|	Orders.DimensionOfExpenses AS DimensionOfExpenses,
		|	Orders.ProductsGroup AS ProductsGroup,
		|	Orders.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
		|	Orders.Purpose AS Purpose,
		|	Orders.RowCode AS RowCode,
		|	Orders.ToRegisterBalance AS ToRegisterBalance,
		|	0 AS Allocated,
		|	DuplicatesOfProducts.DuplicateCount AS DuplicateCount,
		|	Orders.Individual AS Individual,
		|	Orders.OperationCategory AS OperationCategory,
		|	Orders.LineOfBusiness AS LineOfBusiness
		|FROM
		|	InventoryConsumptionOrders AS Orders
		|
		|		LEFT JOIN DuplicatesOfProducts AS DuplicatesOfProducts
		|		ON Orders.Individual = DuplicatesOfProducts.Individual
		|			AND Orders.OperationCategory = DuplicatesOfProducts.OperationCategory
		|			AND Orders.Products = DuplicatesOfProducts.Products
		|			AND Orders.ExpenseItem = DuplicatesOfProducts.ExpenseItem
		|			AND Orders.DimensionOfExpenses = DuplicatesOfProducts.DimensionOfExpenses
		|			AND Orders.ProductsGroup = DuplicatesOfProducts.ProductsGroup
		|			AND Orders.AssetsLiabilitiesDimension = DuplicatesOfProducts.AssetsLiabilitiesDimension
		|			AND Orders.LineOfBusiness = DuplicatesOfProducts.LineOfBusiness
		|
		|ORDER BY
		|	Products,
		|	Characteristic,
		|	InventoryConsumptionOrder";
	QueryTexts.Add(Text);
	
	QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
		
	Query = New Query(QueryText);
	
	Query.SetParameter("OrderDocument",                 Object.InventoryConsumptionOrder);
	Query.SetParameter("Organization",           Object.Organization);
	Query.SetParameter("Warehouse",                 Object.Warehouse);
	Query.SetParameter("Department",         Object.Department);
	Query.SetParameter("SalesOpportunity",                Object.SalesOpportunity);
	Query.SetParameter("BusinessOperation", Object.BusinessOperation);
	Query.SetParameter("Recorder",           Object.Ref);
	Query.SetParameter("SelectByOrder_",      SelectByOrder_);
	
	EmptyOrderValues = New Array();
	EmptyOrderValues.Add(Undefined);
	SetPrivilegedMode(True);
	EmptyOrderValues.Add(Documents.InventoryConsumptionOrder.EmptyRef());
	EmptyOrderValues.Add(Documents.RMOrder.EmptyRef());
	SetPrivilegedMode(False);
	
	Query.SetParameter("EmptyOrderValues", EmptyOrderValues);
	
	Query.SetParameter("Goods",  Object.Goods.Unload(,"RowCode,Products,Characteristic,InventoryConsumptionOrder"));
	Query.TempTablesManager = New TempTablesManager;
	QueryResult = Query.ExecuteBatch();
	If QueryResult[2].IsEmpty() Then
		Return False;
	EndIf;
	Selection = QueryResult[5].Select();
	
	TableOfUnallocatedGoods = New ValueTable();
	TableOfUnallocatedGoods.Columns.Add("Products");
	TableOfUnallocatedGoods.Columns.Add("Characteristic");
	TableOfUnallocatedGoods.Columns.Add("InventoryConsumptionOrder");
	TableOfUnallocatedGoods.Columns.Add("RowCode");
	TableOfUnallocatedGoods.Columns.Add("Count");
	TableOfUnallocatedGoods.Columns.Add("Purpose");
	TableOfUnallocatedGoods.Columns.Add("ExpenseItem");
	TableOfUnallocatedGoods.Columns.Add("DimensionOfExpenses");
	TableOfUnallocatedGoods.Columns.Add("ProductsGroup");
	TableOfUnallocatedGoods.Columns.Add("AssetsLiabilitiesDimension");
	TableOfUnallocatedGoods.Columns.Add("Individual");
	TableOfUnallocatedGoods.Columns.Add("OperationCategory");
	TableOfUnallocatedGoods.Columns.Add("LineOfBusiness");
	
	TableOfGoods = Object.Goods.Unload();
	If Not Object.ExpenseLineOfBusinessIsSpecifiedInList Then
		TableOfGoods.Columns.Add("LineOfBusinessOfOrder");
		TableOfGoods.FillValues(Object.LineOfBusiness, "LineOfBusinessOfOrder");
	EndIf;
	
	While Selection.Next() Do
		
		TheStructureOfTheSearch = New Structure();
		TheStructureOfTheSearch.Insert("Products",             Selection.Products);
		TheStructureOfTheSearch.Insert("Characteristic",           Selection.Characteristic);
		TheStructureOfTheSearch.Insert("RowCode",                0);
		TheStructureOfTheSearch.Insert("ExpenseItem",           Selection.ExpenseItem);
		TheStructureOfTheSearch.Insert("DimensionOfExpenses",        Selection.DimensionOfExpenses);
		TheStructureOfTheSearch.Insert("ProductsGroup",          Selection.ProductsGroup);
		TheStructureOfTheSearch.Insert("AssetsLiabilitiesDimension", Selection.AssetsLiabilitiesDimension);
		TheStructureOfTheSearch.Insert("Individual",           Selection.Individual);
		TheStructureOfTheSearch.Insert("OperationCategory",    Selection.OperationCategory);
		If Object.ExpenseLineOfBusinessIsSpecifiedInList Then
			TheStructureOfTheSearch.Insert("LineOfBusiness", Selection.LineOfBusiness);
		Else
			TheStructureOfTheSearch.Insert("LineOfBusinessOfOrder", Selection.LineOfBusiness);
		EndIf;
		
		FoundRows = TableOfGoods.FindRows(TheStructureOfTheSearch);
		RetainedQuantity = Selection.ToRegisterBalance;
		
		// If there are no duplicates, we distribute the order line to the invoice lines
		If Selection.DuplicateCount < 2 Then
		
			For Each CurRow In FoundRows Do
				
				If CurRow.Count > RetainedQuantity Then
					
					NewRow = TableOfGoods.Add();
					FillPropertyValues(NewRow, CurRow);
					NewRow.Count = CurRow.Count - RetainedQuantity;
					CurRow.Count = RetainedQuantity;
					
				EndIf;
				
				FillPropertyValues(CurRow, Selection, "RowCode,InventoryConsumptionOrder,Purpose");
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
					FillPropertyValues(CurRow, Selection, "RowCode,InventoryConsumptionOrder,Purpose");
					
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
		
		ProductLines_3 = New Array();
		For Each LineProducts_ In TableOfGoods Do
			
			If LineProducts_.RowCode = 0 And Not ValueIsFilled(LineProducts_.InventoryConsumptionOrder) Then
				ProductLines_3.Add(LineProducts_);
			EndIf;
			
		EndDo;
		
		ProductLines_3 = TableOfGoods.FindRows(TheStructureOfTheSearch);
		TotalRowsToProcess = ProductLines_3.Count();
		
		IndexOf = 0;
		While IndexOf < TotalRowsToProcess Do
			
			LineProducts_ = ProductLines_3[IndexOf];
			
			// We will find the necessary rows in the table of unallocated goods
			TheStructureOfTheSearch = New Structure();
			TheStructureOfTheSearch.Insert("Products",             LineProducts_.Products);
			TheStructureOfTheSearch.Insert("Characteristic",           LineProducts_.Characteristic);
			TheStructureOfTheSearch.Insert("ExpenseItem",           LineProducts_.ExpenseItem);
			TheStructureOfTheSearch.Insert("DimensionOfExpenses",        LineProducts_.DimensionOfExpenses);
			TheStructureOfTheSearch.Insert("ProductsGroup",          LineProducts_.ProductsGroup);
			TheStructureOfTheSearch.Insert("AssetsLiabilitiesDimension", LineProducts_.AssetsLiabilitiesDimension);
			TheStructureOfTheSearch.Insert("Individual",           LineProducts_.Individual);
			TheStructureOfTheSearch.Insert("OperationCategory",    LineProducts_.OperationCategory);
			If Object.ExpenseLineOfBusinessIsSpecifiedInList Then
				TheStructureOfTheSearch.Insert("LineOfBusiness", LineProducts_.LineOfBusiness);
			Else
				TheStructureOfTheSearch.Insert("LineOfBusinessOfOrder", LineProducts_.LineOfBusinessOfOrder);
			EndIf;
			
			FoundRows = TableOfUnallocatedGoods.FindRows(TheStructureOfTheSearch);
			
			For Each CurRow In FoundRows Do
				If CurRow.Products = LineProducts_.Products
					And CurRow.Characteristic = LineProducts_.Characteristic
					And CurRow.Count > 0 Then
					
					NumberOfEmployees = Min(CurRow.Count, LineProducts_.Count);
					If NumberOfEmployees < LineProducts_.Count Then
						
						NewRow = TableOfGoods.Add();
						FillPropertyValues(NewRow, LineProducts_);
						NewRow.Count = LineProducts_.Count - NumberOfEmployees;
						ProductLines_3.Add(NewRow);
						TotalRowsToProcess = TotalRowsToProcess + 1;
						
					EndIf;
					LineProducts_.Count = NumberOfEmployees;
					
					FillPropertyValues(LineProducts_, CurRow, "RowCode,InventoryConsumptionOrder,Purpose");
					
					// Reduce the unallocated quantity in the table
					CurRow.Count = CurRow.Count - LineProducts_.Count;
					
					Break;
					
				EndIf;
			EndDo;
			
			IndexOf = IndexOf + 1;
			
		EndDo;
		
	EndIf;
	
	For Each CurRow In TableOfGoods Do
		If Not ValueIsFilled(CurRow.RowCode) Or Not ValueIsFilled(CurRow.InventoryConsumptionOrder) Then
			CurRow.RowCode = 0;
			CurRow.InventoryConsumptionOrder = Object.InventoryConsumptionOrder;
			CurRow.Purpose = Catalogs.Assignments.EmptyRef();
		EndIf;
	EndDo;
	
	// We delete the service column added for searching in the case when the direction of the expenditure 
	// activity coincides with the direction of the inventory activity
	If TableOfGoods.Columns.Find("LineOfBusinessOfOrder") <> Undefined Then
		TableOfGoods.Columns.Delete("LineOfBusinessOfOrder");
	EndIf;
	
	CollapseFields = New Array();
	For Each Column In TableOfGoods.Columns Do
		
		If Column.Name = "ItemsLocationAttributes"
				Or Column.Name = "Count"
				Or Column.Name = "NumberOfPackages" Then
				Continue;
		EndIf;
		CollapseFields.Add(Column.Name);
		
	EndDo;
	
	TableOfGoods.GroupBy(StrConcat(CollapseFields, ","), "Count");
	Object.Goods.Load(TableOfGoods);
	
	For Each RowGoods In Object.Goods Do
		UpdateOrderDeviationsInLine(RowGoods, Object.ConsumptionByOrders);
	EndDo;
	
	FillInStatusesForSpecifyingSeriesServer();
	
	Return True;
	
EndFunction

&AtServer
Procedure RefillByNotes(AnArrayOfOrders)
	
	FillParameters = Documents.InventoryConsumption.DocumentFillingParameters();
	FillParameters.FormIsOpen          = True;
	FillParameters.ObjectForm          = ThisObject;
	FillParameters.FillByWarehouseDocument     = True;
	
	InvoiceTable = Documents.InventoryConsumption.TableDataAndDocument(Object.Ref);
	
	HeaderAttributes = New Structure("Organization, Department, Warehouse, SalesOpportunity,
		|BusinessOperation, Ref, LineOfBusiness");
	FillPropertyValues(HeaderAttributes, Object);
	Documents.InventoryConsumption.InitializeFillingParameters(FillParameters,
		HeaderAttributes, AnArrayOfOrders);
	
	Documents.InventoryConsumption.FillInByOrdersOrders(InvoiceTable, Object.Ref, FillParameters, Object.PackageBarcodes);
	
	NumberOfIndexes = InvoiceTable.Count() - 1;
	For IndexOf = 0 To NumberOfIndexes Do
		
		String = InvoiceTable[NumberOfIndexes - IndexOf];
		
		If AnArrayOfOrders.Find(String.InventoryConsumptionOrder) = Undefined Then
			Continue;
		EndIf;
		
		If String.NoteQuantity = 0 Then
			InvoiceTable.Delete(String);
		Else
			String.Count = String.NoteQuantity;
		EndIf;
		
	EndDo;
	
	Object.Goods.Load(InvoiceTable);
	
	// Recalculating the Quantity of Packages field
	Documents.InventoryConsumption.UpdateDependentDetailsOfTablePart(Object.Goods, FillParameters);
	
	Documents.InventoryConsumption.ProcessDocumentAfterAddingLines(Object);
	
	FillInServiceDetailsOfTablePart();
	
	For Each String In Object.Goods Do
		WhenAddingLineOfProductsOnServer(String);
	EndDo;
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	UpdateOrderInformation();
	
	ConfigureDependentFormElementsOnServer("BusinessOperation,Goods");
	
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
EndProcedure

&AtClient
Procedure ReportResults()
	
	If FillingResults <> Undefined Then
		
		If FillingResults.ThereAreUnassembled Then
			
			ShowUserNotification(
				NStr("vi = 'Số lượng đã điền lại';
					|ru = 'Количество перезаполнено';
					|en = 'Refilled quantity'; fa = 'Refilled quantity';
					|it = 'La quantità è ricompilata';
					|pl = 'Ponowne wypełnienie ilości.';
					|tr = 'Miktar yeniden dolduruldu'"),,
				NStr("vi = 'Trong các dòng đã điền lại số lượng có tính đến hàng hóa đang tập hợp trong kho.';
					|ru = 'В строках перезаполнено количество с учетом собирающихся на складе товаров.';
					|en = 'Quantity considering goods that are assembled in the warehouse is refilled in lines.'; fa = 'Quantity considering goods that are assembled in the warehouse is refilled in lines.';
					|it = 'La quantità nelle righe è ricompilata tenuto conto delle merci raccolte in magazzino.';
					|pl = 'W wierszach zapełniono ponownie ilość z uwzględnieniem gromadzących się w magazynie towarów.';
					|tr = 'Satırlarda, ambarda toplanan ürünler dikkate alınarak miktar yeniden dolduruldu.'"),
				PictureLib.Information32);
			
		Else
			
			ShowUserNotification(
				NStr("vi = 'Số lượng đã điền lại';
					|ru = 'Количество перезаполнено';
					|en = 'Refilled quantity'; fa = 'Refilled quantity';
					|it = 'La quantità è ricompilata';
					|pl = 'Ponowne wypełnienie ilości.';
					|tr = 'Miktar yeniden dolduruldu'"),,
				NStr("vi = 'Trong các dòng đã điền lại số lượng.';
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
Procedure GoodsAfterDeleteRowServer(SeriesStatusesNeedToBeUpdated, CachedValues)

	If SeriesStatusesNeedToBeUpdated Then
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Undefined, CachedValues);
	EndIf;
	
	If UseInventoryConsumptionForMultipleOrders Then
		UpdateOrderInformation();
	EndIf;
	
	UpdateDependentDetailsOfServerByOrderForm();
	
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
EndProcedure

&AtClient
Procedure GoodsReferenceOrderStartChoiceCompletion(Result, AdditionalParameters) Export
	
	Items.Goods.CurrentData.InventoryConsumptionOrder = Result;
	
	GoodsOrderStartOfSelectionFragment();
	
EndProcedure

&AtClient
Procedure GoodsOrderStartOfSelectionFragment()
	
	UpdateOrderInformation();
	
EndProcedure

&AtClient
Procedure GoodsNomenclatureWhenChangingQuestionToUserCompletion(Result, AdditionalParameters) Export
	
	If Not Result Then
		Return;
	EndIf;
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("WhenChangingProductType", New Structure("ThereAreWorks, IsCanceled", True, False));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisForm, StructureOfActions);
	
	SeriesVerificationParameters = New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters);
	StructureOfActions.Insert("CheckSeriesCalculateStatus", SeriesVerificationParameters);

	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Products", StructureOfActions);
	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));
	
	// Selection of articles and analytics.
	IncomeAndExpensesClientServer.InsertActionFillInItemCostAnalysisOfProducts(
		StructureOfActions,
		ThisObject,
		Object.BusinessOperation,
		Object.Organization,
		Object.Department);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	SetFlagForFillingWarehouseOnClient();
	
EndProcedure

&AtClient
Procedure FillInDirectionOfActivityCompletion(Result, StringsList) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	For Each RowID In StringsList Do
		RowData = Object.Goods.FindByID(RowID);
		RowData.LineOfBusiness = Result;
	EndDo;
	
EndProcedure

#EndRegion

#Region Other

&AtClientAtServerNoContext
Function OrderInOverOrderLine(ConsumptionByOrders, InventoryConsumptionOrder)
	
	Return ?(ConsumptionByOrders And ValueIsFilled(InventoryConsumptionOrder), InventoryConsumptionOrder, Undefined);
	
EndFunction

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtServer
Procedure SetUncheckSeparately(Set)
	LinesOfBusinessServer.SetUncheckSeparately(ThisObject, Set);
EndProcedure

&AtServer
Function PutGoodsAndStockTypesInStorage()
	
	OptionsForEditingInventoryTypes = InventoriesServer.OptionsForEditingInventoryTypes();
	If GetFunctionalOption("UseExcisableGoods") Then
		OptionsForEditingInventoryTypes.DisplayExciseTaxAmount = True;
		OptionsForEditingInventoryTypes.UseExcisableGoods = True;
	EndIf;
	Return InventoriesServer.PutGoodsAndStockTypesInStorage(ThisObject, OptionsForEditingInventoryTypes);
	
EndFunction

&AtServer
Procedure GetStockTypesFromStorage(ValueSelected)
	
	InventoriesServer.ProcessInputOfInventoryTypesManually(ValueSelected, ThisForm);
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	OrdersAreUsed = GetFunctionalOption("UseInventoryConsumptionOrders");
	OrdersAreUsed = OrdersAreUsed Or GetFunctionalOption("UseRMManagement");
	UseStatuses = GetFunctionalOption("UseInventoryConsumptionStatuses");
	
	ExpenseLineOfBusinessIsSpecifiedInList = ?(Object.ExpenseLineOfBusinessIsSpecifiedInList, 1, 0);
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.InventoryConsumption));
	AdvancedWarehousingOnShipment = WarehousesServer.UseWarehouseManagemantSystemForGoodsIssue(Object.Warehouse, Object.Date);
	ThisIsAReferenceInvoice = ThisIsAReferenceInvoice(Object.Ref, AdvancedWarehousingOnShipment);
	If Parameters.Property("CheckResults") And Parameters.CheckResults.ThereAreWarnings Then
		CommonClientServer.MessageToUser(Parameters.CheckResults.WarningText);
	EndIf;
	
	SetVisibilityOfSeriesElements();
	FillInServiceDetailsOfTablePart();
	UseInventoryConsumptionForMultipleOrders = GetFunctionalOption("UseInventoryConsumptionForMultipleOrders");
	UseMultipleCompanies = GetFunctionalOption("UseMultipleCompanies");
	UseBusinessUnits = GetFunctionalOption("UseBusinessUnits");
	
	LinesOfBusinessServer.OnReadCreateAtServer(ThisObject);
	
	ConfigurePickUpByOrdersOrdersCommand();
	UpdateOrderInformation();
	
	If Not OrdersAreUsed Then
		Items.PictureDiscrepancyOrder.Visible = False;
		Items.PictureDiscrepancyOrders.Visible = False;
	EndIf;
	
	InventoryConsumptionInExcessOfOrder = UserRightsCached.InventoryConsumptionInExcessOfOrder();
	
	SetAvailabilityOfFormElementsByOrder();
	UpdateDependentDetailsOfServerByOrderForm(True);
	
	UpdateConsumptionForActivities_(False);
	
	UpdateDependentDetailsOfOrderForm_(
		Object.Goods,
		DiscrepancyOrderText, 
		Items.PictureDiscrepancyOrder,
		Items.PictureDiscrepancyOrders);
	
	FillInServiceDetailsWhenChangingBusinessOperation();
	SetVisibilityOfCommandsByOrder();
	
	ConfigureDependentFormElementsOnServer();
	
	ConfigureNavigationBar();
	
	UpdateVHFWarehouseObligation();
	
	ProcessingOfTabularForms.InitializeRowCache(Items.Goods);
	
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
	
	Notify("Write_InventoryConsumption", NotificationProcessingParameter, Object.Ref);
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfFormElementsByOrder()
	
	ItemArray = New Array;
	ItemArray.Add("GoodsUnlinkFromOrder");
	ItemArray.Add("GoodsContextMenuUnlinkFromOrder");
	ItemArray.Add("ProductsGroupOrderForDomesticConsumption");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible",
		Object.ConsumptionByOrders And InventoryConsumptionInExcessOfOrder);
	
	ItemArray = New Array;
	ItemArray.Add("GoodsAdd");
	ItemArray.Add("ProductsContextMenuAdd");
	ItemArray.Add("GoodsCopy");
	ItemArray.Add("ProductItemsContextMenuCopy");
	ItemArray.Add("GoodsSearchByBarcode");
	ItemArray.Add("GoodsOpenSelection");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled",
		Not Object.ConsumptionByOrders Or (Object.ConsumptionByOrders And InventoryConsumptionInExcessOfOrder));
	
EndProcedure

&AtServer
Procedure ConfigurePickUpByOrdersOrdersCommand(SetAvailability_ = True)
	
	ParametersStructure = New Structure("AdvancedWarehousingOnShipment, OrdersUse, UseInvoicesForSeveralOrders",
		AdvancedWarehousingOnShipment, OrdersAreUsed, UseInventoryConsumptionForMultipleOrders);
	
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
		Items.PictureDiscrepancyOrder, 
		Items.PictureDiscrepancyOrders);
		
	ParametersOfUpdate = OrdersServer.ParametersForUpdatingOrderInformationInForm();
	
	ParametersOfUpdate.PropsNameOrderList         = "OrderList";
	ParametersOfUpdate.OrderPathInHeader                  = "Object.InventoryConsumptionOrder";
	ParametersOfUpdate.TitleLabelName               = "HeaderOrdersText";
	ParametersOfUpdate.NameOfColumnGroupInTableSection   = "ProductsGroupOrderForDomesticConsumption";
	ParametersOfUpdate.OrderNameInTablePart          = "InventoryConsumptionOrder";
	ParametersOfUpdate.UseOrdersInTabularSection = UseInventoryConsumptionForMultipleOrders;
	
	OrdersServer.UpdateOrderInformationInForm(ThisForm,Object.Goods, ParametersOfUpdate);
	
EndProcedure

&AtServer
Procedure FillInFromOrderServer()
	
	Object.Goods.Clear();
	
	AnArrayOfOrders = New Array();
	If Not UseInventoryConsumptionForMultipleOrders Then
		AnArrayOfOrders.Add(Object.InventoryConsumptionOrder);
	EndIf;
	
	HeaderAttributes = New Structure("Organization, LineOfBusiness, Department, Warehouse, SalesOpportunity, BusinessOperation, Ref");
	FillPropertyValues(HeaderAttributes, Object);
	
	SelectionData_ = New Structure("AnArrayOfOrders, HeaderAttributes", AnArrayOfOrders, HeaderAttributes);
	
	RegistrationProcedure    = Constants.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.Get();
	OrderFirst = RegistrationProcedure = Enums.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.OrdersFirst;
	SelectionData_.Insert("FillByWarehouseDocument", AdvancedWarehousingOnShipment And OrderFirst);
	SelectionData_.Insert("ExpenseLineOfBusinessIsSpecifiedInList", ?(ExpenseLineOfBusinessIsSpecifiedInList = 1, True, False));
	QueryResult = Documents.InventoryConsumption.RequestResultForOrderBalances(SelectionData_, "FillingInOrders");
	
	If SelectionData_.FillByWarehouseDocument Then
		
		KeyFields = "InventoryConsumptionOrder, Products, Characteristic, Purpose, Series";
		InvoicesServer.FillInQuantityIndicatorForOrders(QueryResult.TableOfContents_, QueryResult.TableShipped, KeyFields);
		InvoicesServer.FillInOption(Object.Goods, QueryResult.TableOfContents_, "FillByWarehouseDocument");
		
	Else
		
		InvoicesServer.FillInOption(Object.Goods, QueryResult.TableOfContents_, "FillByOrderDocument");
		
	EndIf;
	
	Documents.InventoryConsumption.ProcessDocumentAfterAddingLines(Object);
	
	FillInLineOfBusinessOfExpensesIndicatedInList(QueryResult.TableOfContents_);
	FillInServiceDetailsOfTablePart();
	FillInStatusesForSpecifyingSeriesServer();
	
	ConfigureDependentFormElementsOnServer("Goods, ExpenseLineOfBusinessIsSpecifiedInList");
	
	SetWhetherWarehouseIsFullOnServer();
	
EndProcedure 

&AtServer
Procedure FillInLineOfBusinessOfExpensesIndicatedInList(TableOfGoods) Export
	
	If TableOfGoods.Count() = 0 Then
		Return;
	EndIf; 
	
	ExpenseLineOfBusinessIsSpecifiedInList = ?(TableOfGoods[0].ExpenseLineOfBusinessIsSpecifiedInList, 1, 0);
	Object.ExpenseLineOfBusinessIsSpecifiedInList = TableOfGoods[0].ExpenseLineOfBusinessIsSpecifiedInList;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions)

	StructureOfActions.Insert("RecalculateNumberOfUnits");

EndProcedure

&AtServer
Procedure FillMultiTurnContainersFromStorageServer(AddressOfContainerInStorage)
	
	ActionStructureModifiedStrings = New Structure;
	ActionStructureModifiedStrings.Insert("RecalculateNumberOfPackages");
	
	StructureOfActionsAddedLines = New Structure;
	StructureOfActionsAddedLines.Insert("RecalculateNumberOfPackages");
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisForm, StructureOfActionsAddedLines);
	
	// Selection of articles and analytics.
	IncomeAndExpensesClientServer.InsertActionFillInItemCostAnalysisOfProducts(
		StructureOfActionsAddedLines,
		ThisObject,
		Object.BusinessOperation,
		Object.Organization,
		Object.Department);
	
	ReusablePackageServer.FillMultiTurnContainersFromStorage(
		Object,
		AddressOfContainerInStorage,
		"Goods",
		"Products,Characteristic",
		ActionStructureModifiedStrings,
		StructureOfActionsAddedLines);
	
	FillInServiceDetailsOfTablePart();
	FillInStatusesForSpecifyingSeriesServer();
	
	ConfigureDependentFormElementsOnServer("Goods");
	
EndProcedure

&AtServer
Procedure ChangeHeadersForBusinessTransactions()
	
	AutoTitle = True;
	Title = "";
	Items.OrderInvoice_3.Title = NStr("vi = 'Nhu cầu theo đơn hàng';
										|ru = 'Потребление по заказу';
										|en = 'Consumption by order'; fa = 'مصرف بر اساس سفارش';
										|it = 'Fabbisogno per l''ordine';
										|pl = 'Zużycie według zamówienia';
										|tr = 'Siparişe göre tüketim'");
	Items.InvoiceForOrders.Title = NStr("vi = 'Nhu cầu theo đơn hàng';
										|ru = 'Потребление по заказам';
										|en = 'Consumption by orders'; fa = 'مصرف بر اساس سفارش‌ها';
										|it = 'Fabbisogno per gli ordini';
										|pl = 'Zużycie według zamówień';
										|tr = 'Siparişlere göre tüketim'");
	
	If GetFunctionalOption("BaseVersion") Then
		
		AutoTitle = False;
		If ValueIsFilled(Object.Ref) Then
			Title = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Ghi giảm hàng hóa vào nhu cầu kinh doanh %1 ngày %2';
					|ru = 'Списание товаров на хознужды %1 от %2';
					|en = 'Goods write-off to business needs %1 from %2'; fa = 'Goods write-off to business needs %1 from %2';
					|it = 'Storno merci per fabbisogni economici %1 dal %2';
					|pl = 'Rozchód towarów na potrzeby gospodarcze %1 z dn. %2';
					|tr = '%2''nin %1''inin ticari ihtiyaçları için malların gider yazılması'"),
				Object.Number,
				Object.Date);
		Else
			Title = NStr("vi = 'Ghi giảm hàng hóa vào nhu cầu kinh doanh (tạo mới)';
						|ru = 'Списание товаров на хознужды (создание)';
						|en = 'Goods write-off to business needs (generation)'; fa = 'Goods write-off to business needs (generation)';
						|it = 'Storno delle merci per i fabbisogni economici (creazione)';
						|pl = 'Rozchód towarów na potrzeby gospodarcze (utworzenie)';
						|tr = 'Ev ihtiyaçları için malların gider yazılması (yaratılış)'");
		EndIf;
		
	ElsIf ValueIsFilled(Object.BusinessOperation) Then
		
		If Object.BusinessOperation = Enums.BusinessTransactions.TransferToOperation Then
			Items.OrderInvoice_3.Title = NStr("vi = 'Chuyển giao theo đơn hàng';
												|ru = 'Передача по заказу';
												|en = 'Transfer by order'; fa = 'انتقال بر اساس سفارش';
												|it = 'Trasferimento per ordine';
												|pl = 'Przekazanie według zamówienia';
												|tr = 'Siparişe göre transfer'");
			Items.InvoiceForOrders.Title = NStr("vi = 'Chuyển giao theo đơn hàng';
												|ru = 'Передача по заказам';
												|en = 'Transfer by orders'; fa = 'انتقال بر اساس سفارش‌ها';
												|it = 'Trasferimento per ordini';
												|pl = 'Przekazywanie zleceń';
												|tr = 'Siparişe göre transfer'");
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm);
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm);
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisForm, "SeriesWhenPlanningShipmentWHGoodsAreIndicated");
	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisForm, False);
	InventoriesServer.EstablishConditionalAppearanceOfDivisionForTypesOfStocks(ThisForm);
	LinesOfBusinessServer.SetConditionalAppearanceOfFlagSeparately(ThisObject);
	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisForm);
	
	InventoryInOperationServer.SetConditionalRegistrationOfInventoryNumber(
		ThisObject,,, Undefined);
		
	InventoryInOperationServer.EstablishConditionalRegistrationOfIndividual(
		ThisObject,,, Undefined);
		
	TMCommonUse.SetUncheckBlank(
		ConditionalAppearance, "Warehouse", "Object.Warehouse", "WarehouseIsRequired");
	
	// Removing the checkmark property from the Division field"
	#Region DivisionMarkNotFilledIn
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Department.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.GoodsConsumptionOnDemand;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	#EndRegion
	
	// Hide the String Code field
	#Region ProductsLineCodeVisibility
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsRowCode.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ConsumptionByOrders");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Visible", False);
	#EndRegion

	// The color of the text in the Order field
	#Region ProductsAndTextColor
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsInventoryConsumptionOrder.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.InventoryConsumptionOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	#EndRegion
	
	// Only inspection of the Order field
	#Region ProductsOrderViewOnly
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsInventoryConsumptionOrder.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.InventoryConsumptionOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	#EndRegion
	
	// The text "Over the order, the order is not selected" in the Order field
	#Region ProductsAndText
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsInventoryConsumptionOrder.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.InventoryConsumptionOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.InventoryConsumptionOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ErrorNoteText);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Vượt mức đơn hàng, chưa chọn đơn hàng';
													|ru = 'Сверх заказа, заказ не выбран';
													|en = 'In excess of the order, the order is not selected'; fa = 'In excess of the order, the order is not selected';
													|it = 'Oltre all''ordine, l''ordine non è selezionato';
													|pl = 'Przewyższa zamówienie, zamówienie nie wybrane';
													|tr = 'Sipariş fazlası, sipariş seçilmedi'"));
	#EndRegion
	
	// Hide the Order field
	#Region ProductsAndVisibility
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsInventoryConsumptionOrder.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.InventoryConsumptionOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ConsumptionByOrders");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Visible", False);
	#EndRegion
	
	// Other
	#Region Other
	
	TMCommonUse.SetUncheckBlank(
		ConditionalAppearance, "Department", "Object.Department", "DepartmentMandatory");
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsProducts.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCharacteristic.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ConsumptionByOrders");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InventoryConsumptionInExcessOfOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	#EndRegion
	
	#Region GoodsFixedAsset_Visibility
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsFixedAsset.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.AccountAsGroupFA");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ConditionalAppearanceItem.Appearance.SetParameterValue("Visible", False);
	
	#EndRegion

	#Region ProductsCostAnalytics_Visibility
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDimensionOfExpenses.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.AccountAsGroupFA");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ConditionalAppearanceItem.Appearance.SetParameterValue("Visible", False);
	
	#EndRegion

	#Region ProductsMainMeans_Text
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsFixedAsset.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.AccountAsGroupFA");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.FixedAsset");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<tự động tạo, nếu chưa điền>';
																		|ru = '<создается автоматически, если не заполнено>';
																		|en = '<created automatically if not filled>'; fa = '<created automatically if not filled>';
																		|it = '<viene creato automaticamente se non compilato>';
																		|pl = '<jest tworzone automatycznie, jeśli nie jest wypełnione>';
																		|tr = '<doldurulmadığı takdirde otomatik olarak oluşturulur>'"));
	
	#EndRegion

EndProcedure

&AtServer
Procedure UnbindLinesFromOrderOnServer(CachedValues)
	
	If Not Object.ConsumptionByOrders Then
		Return;
	EndIf;

	SelectedRows = Items.Goods.SelectedRows;
	For Each RowID In SelectedRows Do
		UntieLineFromOrder(RowID, CachedValues);
	EndDo;
	UpdateDependentDetailsOfServerByOrderForm();

EndProcedure

&AtServer
Procedure UntieLineFromOrder(RowID, CachedValues)

	If Not Object.ConsumptionByOrders Then
		Return;
	EndIf;
	
	TableRow = Object.Goods.FindByID(RowID);
	
	ProductsClientServer.UpdateCachedValuesToAccountForSeries(TableRow,CachedValues,SeriesSpecificationParameters);
	
	TableRow.RowCode = 0;
	TableRow.Purpose = Undefined;
	TableRow.WithAssignment = False;
	TableRow.OrderDiscrepancy_3 = 1;
	
	TableRow.InventoryConsumptionOrder = OrderInOverOrderLine(Object.ConsumptionByOrders, Object.InventoryConsumptionOrder);

	// Reassign the series lines
	ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Object,SeriesSpecificationParameters,RowID,CachedValues);
	
EndProcedure

&AtServerNoContext
Function ThisIsAReferenceInvoice(Ref, AdvancedWarehousingOnShipment)
	
	Return AdvancedWarehousingOnShipment And InvoicesServer.ThereIsSpendingOrderForShippingOrders(Ref);
	
EndFunction

&AtServer
Procedure SetVisibilityOfCommandsByOrder()
	
	Items.CloseOrder.Visible = Object.ConsumptionByOrders;
	Items.CloseOrders_2.Visible = Object.ConsumptionByOrders;
	
EndProcedure

&AtServer
Procedure SetSelectionParameters()
	
	#Region GoodsExpenseItem
	NewSelectionParameterRelationships = New Array;

	NewLink = New ChoiceParameterLink("AccountAsGroupFA", "Items.Goods.CurrentData.AccountAsGroupFA", LinkedValueChangeMode.DontChange);
	NewSelectionParameterRelationships.Add(NewLink);

	Items.GoodsExpenseItem.ChoiceParameterLinks = New FixedArray(NewSelectionParameterRelationships);
	#EndRegion
	
	#Region GoodsDimensionOfExpenses
	NewSelectionParameterRelationships = New Array;

	NewLink = New ChoiceParameterLink("Filter.Owner", "Items.Goods.CurrentData.ExpenseItem", LinkedValueChangeMode.Clear);
	NewSelectionParameterRelationships.Add(NewLink);

	NewLink = New ChoiceParameterLink("AccountAsGroupFA", "Items.Goods.CurrentData.AccountAsGroupFA", LinkedValueChangeMode.DontChange);
	NewSelectionParameterRelationships.Add(NewLink);

	Items.GoodsDimensionOfExpenses.ChoiceParameterLinks = New FixedArray(NewSelectionParameterRelationships);
	#EndRegion
	
EndProcedure

&AtClient
Procedure StatusOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	FillInShippingInstructions = False;
    
    Response = QuestionResult;
    
    If Response = DialogReturnCode.Yes Then
        FillInShippingInstructions = True;
    EndIf;
    
    StatusOnChangeServer(FillInShippingInstructions);

EndProcedure

&AtServer
Procedure StatusOnChangeServer(FillInShippingInstructions)

	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.InventoryConsumption));

	If FillInShippingInstructions Then
		Documents.InventoryConsumption.FillInShippingInstructions(Object);
		FormEvents.WhenChangingElement(ThisObject, "Goods");
	EndIf;

	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	ConfigureDependentFormElementsOnServer("Status");
	
EndProcedure

&AtServer
Function DisplayMessageOnUsingStatuses()
	
	DisplayMessageOnUsingStatuses = False;
	
	If SeriesSpecificationParameters.UseItemsBatch
		And Object.BusinessOperation = Enums.BusinessTransactions.TransferToOperation 
		And Not GetFunctionalOption("UseInventoryConsumptionStatuses") Then
		
		SetPrivilegedMode(True);
		
		ItIsPossibleToTakeIntoAccountSeriesInOperation = InventoryInOperationCached.ItIsPossibleToTakeIntoAccountSeriesInOperation();
		
		SerialAccountingPoliciesWarehouseSender = WarehousesServer.UseOfSeriesInStockAccordingToAccountingPolicies(Object.Warehouse);
		UseSenderOrderScheme = WarehousesServer.UseWarehouseManagemantSystemForGoodsIssue(Object.Warehouse, Object.Date);
		SerialSenderParameters = WarehousesServer.UseOfSeriesInStock(Object.Warehouse, False);
		
		SetPrivilegedMode(False);
		
		If UseSenderOrderScheme Then
			
			If Not SerialAccountingPoliciesWarehouseSender.SpecifyWhenPlanningShipment 
				And ItIsPossibleToTakeIntoAccountSeriesInOperation Then
				
				DisplayMessageOnUsingStatuses = True;
				
			EndIf;
			
			If Not SerialSenderParameters.UseItemsBatch
				And ItIsPossibleToTakeIntoAccountSeriesInOperation Then
				
				DisplayMessageOnUsingStatuses = True;
				
			EndIf;
			
		Else
			
			If Not SerialSenderParameters.UseItemsBatch
				And ItIsPossibleToTakeIntoAccountSeriesInOperation Then
				
				DisplayMessageOnUsingStatuses = True;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return DisplayMessageOnUsingStatuses;
	
EndFunction

&AtClient
Function YouCanSplitString()

	CurrentRow = Items.Goods.CurrentData;
	
	If CurrentRow <> Undefined And CurrentRow.StocktakingRecord Then
		MessageText = NStr("vi = 'Không thể tách dòng có kế toán vật tư.';
							|ru = 'Невозможно разбить строку с инвентарным учетом.';
							|en = 'Cannot split the line with stocktaking record.'; fa = 'Cannot split the line with stocktaking record.';
							|it = 'Impossibile dividere la riga con la contabilità di inventario.';
							|pl = 'Nie można podzielić wiersza z ewidencją inwentarzową.';
							|tr = 'Bir envanter satırını bölemezsiniz.'");
		ShowMessageBox(,MessageText);
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

#EndRegion

#Region WorkingWithClipboard

&AtServer
Procedure CopyLinesOnServer()
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object.Goods, Items.Goods.SelectedRows);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboard()
	
	FilterParameters = New Map;
	If Object.BusinessOperation = Enums.BusinessTransactions.GoodsConsumptionOnDemand Then
		FilterParameters.Insert("Products.ItemsType", ProductsClientServer.SelectionByProductReusablePackagingWork(False));
	Else
		FilterParameters.Insert("Products.ItemsType", ProductsClientServer.SelectionByProductMultiTurnContainer(False));
	EndIf;
	
	Columns = "Products,Characteristic,Package,NumberOfPackages,OperationCategory,Individual,AssetID,
		|ExpenseItem,DimensionOfExpenses,AssetsLiabilitiesDimension,FixedAsset";
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	
	// Selection of articles and analytics.
	IncomeAndExpensesClientServer.InsertActionFillInItemCostAnalysisOfProducts(
		StructureOfActions,
		ThisObject,
		Object.BusinessOperation,
		Object.Organization,
		Object.Department);
	
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisForm, StructureOfActions);
	
	RowsToProcess = New Array();
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);
		UpdateOrderDeviationsInLine(CurrentRow, Object.ConsumptionByOrders);
		CurrentRow.InventoryConsumptionOrder = OrderInOverOrderLine(
			Object.ConsumptionByOrders, Object.InventoryConsumptionOrder);
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods);
		
	For Each CurrentRow In RowsToProcess Do
		
		WhenAddingLineOfProductsOnServer(CurrentRow);
		
	EndDo;
	
	FillInServiceDetailsOfTablePart();
	FillInStatusesForSpecifyingSeriesServer();
	SetWhetherWarehouseIsFullOnServer();
	
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
	UpdateDependentDetailsOfOrderForm_(
		Object.Goods,
		DiscrepancyOrderText,
		Items.PictureDiscrepancyOrder, 
		Items.PictureDiscrepancyOrders);
		
	ConfigureDependentFormElementsOnServer("Goods");
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfClipboardCommands()
	
	ItemArray = New Array();
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled",
		ProcessingOfTabularForms.ThereAreLinesInClipboard() And (Not Object.ConsumptionByOrders Or InventoryConsumptionInExcessOfOrder));
	
EndProcedure

&AtClient
Procedure SetAvailabilityOfClipboardCommandsOnClient()
	
	ItemArray = New Array();
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", 
		(Not Object.ConsumptionByOrders Or InventoryConsumptionInExcessOfOrder));
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsOfTablePart()
	
	For Each RowGoods In Object.Goods Do
		UpdateOrderDeviationsInLine(RowGoods, Object.ConsumptionByOrders);
	EndDo;
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	ParametersForFillingInBankingDetails.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Products", ParametersForFillingInBankingDetails);
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods,ParametersForFillingInBankingDetails);
	Catalogs.OperationCategories.FillInCategoryAttributes(Object.Goods);
EndProcedure

&AtClient
Procedure OpenSelectionOfSeries(Text = "", CurrentData = Undefined)
	
	If ProductsClient.YouNeedServerCallToSpecifySeries(ThisForm,SeriesSpecificationParameters,Text, CurrentData)Then
		
		If CurrentData = Undefined Then
			CurDataId = Items.Goods.CurrentData.GetID();
		Else
			CurDataId = CurrentData.GetID();
		EndIf;

		ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm(CurDataId);
		AdditionalParameters = New Structure("ParametersOfSeriesIndicationForm", ParametersOfSeriesIndicationForm);		
		CallbackDescription = New CallbackDescription("OpenSelectionOfSeriesCompletion", ThisObject, AdditionalParameters);
		OpenForm(ParametersOfSeriesIndicationForm.FormName,
						ParametersOfSeriesIndicationForm,
						ThisForm,,,, 
						CallbackDescription,
						FormWindowOpeningMode.LockOwnerWindow);
		
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

&AtServer
Function ParametersOfSeriesIndicationForm(CurDataId)
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(Object, SeriesSpecificationParameters, CurDataId, ThisForm);
	
EndFunction

#EndRegion

#Region DiscrepanciesInShippingDocuments

&AtServer
Procedure UpdateDependentDetailsOfServerByOrderForm(ThisIsReadingObject = False)
	
	If Object.Goods.Count() = 0 
		Or Not Object.ConsumptionByOrders 
		Or Not OrdersAreUsed Then
		
		Items.PictureDiscrepancyOrder.Picture = New Picture();
		Items.PictureDiscrepancyOrders.Picture = New Picture();
		DiscrepancyOrderText = "";
		
		If Object.Goods.Count() > 0 And Not ThisIsReadingObject Then
			For Each LineProducts_ In Object.Goods Do
				LineProducts_.OrderDiscrepancy_3 = 0;
			EndDo;
		EndIf;
		
		Return;
	EndIf;
	
	UpdateDependentDetailsOfOrderForm_(
		Object.Goods,
		DiscrepancyOrderText,
		Items.PictureDiscrepancyOrder, 
		Items.PictureDiscrepancyOrders);
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateDependentDetailsOfOrderForm_(Goods, DiscrepancyOrderText, PictureDiscrepancyOrder, PictureDiscrepancyOrders)
	
	NumberOfDiscrepancies = Goods.Total("OrderDiscrepancy_3");
	
	If NumberOfDiscrepancies > 0 Then
		PictureDiscrepancyOrder.Picture = PictureLib.ExceededOrder;
		PictureDiscrepancyOrders.Picture = PictureLib.ExceededOrder;
		DiscrepancyOrderText = StrReplace(NStr("vi = 'Dòng vượt quá đơn hàng: %NumberOfDiscrepancies%';
												|ru = 'Строк сверх заказа: %NumberOfDiscrepancies%';
												|en = 'Lines in excess of order: %NumberOfDiscrepancies%'; fa = 'Lines in excess of order: %NumberOfDiscrepancies%';
												|it = 'Righe oltre all''ordine: %NumberOfDiscrepancies%';
												|pl = 'Wierszy ponad zamówienia: %NumberOfDiscrepancies%';
												|tr = 'Sipariş fazlası satırı: %NumberOfDiscrepancies%'"), "%NumberOfDiscrepancies%", NumberOfDiscrepancies);
	Else
		PictureDiscrepancyOrder.Picture = New Picture();
		PictureDiscrepancyOrders.Picture = New Picture();
		DiscrepancyOrderText = "";
		NumberOfDiscrepancies = 0;
	EndIf;
	
EndProcedure

&AtClient
Procedure NotifyAboutEndOfUnbindingLines(NumberOfLinesWorked, LinesWereUnlinked = True)

	If LinesWereUnlinked Then
		NotificationText1 = NStr("vi = 'Trong chứng từ đã bỏ (%%Count%%) dòng khỏi đơn hàng.';
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
			NStr("vi = 'Các dòng không liên quan';
				|ru = 'Строки не отвязаны';
				|en = 'Lines were not unlinked'; fa = 'Lines were not unlinked';
				|it = 'Righe non dissociate';
				|pl = 'Wierze nie odłączone';
				|tr = 'Birleşik satırlar'"),
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

&AtClientAtServerNoContext
Procedure UpdateOrderDeviationsInLine(CurrentRow, ConsumptionByOrders)
	
	If ConsumptionByOrders Then
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
	
	AdditionalParameters = AdditionalCompletionProcessingParameters();
	AdditionalParameters.CurrentRow = CurrentRow;
	AdditionalParameters.CallbackDescription = CallbackDescription;

	QueryText = NStr("vi = 'Dòng đang soạn sẽ không liên kết với dòng đơn hàng nữa. Tiếp tục?';
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
//  Response - DialogReturnCode - the user's response in the question window.
//  AdditionalParameters - Structure - Additional parameters passed to the notification handler.
&AtClient
Procedure QuestionToUserWhenChangingDetailsOfLineQuestionCompletion(Response, AdditionalParameters) Export
	
	// If the user has confirmed the change in the value of the key details
	If Response = DialogReturnCode.Yes Then
		
		AdditionalParameters.CurrentRow.RowCode = 0;
		AdditionalParameters.LineDetachedFromOrder = True;
		UpdateOrderDeviationsInLine(AdditionalParameters.CurrentRow, Object.ConsumptionByOrders);
		RunCallback(AdditionalParameters.CallbackDescription, True);
		
	Else
		
		// If the user refused to change the linked string, we will return the old values
		FillPropertyValues(AdditionalParameters.CurrentRow, PreviousRowDetails);
		RunCallback(AdditionalParameters.CallbackDescription, False);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region InventoryInOperation

&AtServer
Procedure ConfigureNavigationBar()
	
	SettingsStructure = New Structure;
	SettingsStructure.Insert("UseMaterialsInOperation",
		Object.BusinessOperation = Enums.BusinessTransactions.TransferToOperation
		Or Object.BusinessOperation = Enums.BusinessTransactions.PutOutOfOperation);
	
	TMCommonUse.ConfigureFormByParameters(ThisObject, SettingsStructure);
	
EndProcedure

&AtClient
Procedure WhenChangingCategoryOfOperation(CurrentRow)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInCategoryAttributes");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.GoodsExpenseItem);
	
	If Not CurrentRow.AccountingForIndividuals Then
		CurrentRow.Individual = PredefinedValue("Catalog.Persons.EmptyRef");
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInCategoryOfOperationCompletion(Result, AdditionalParameters) Export
	
	SelectedRows = AdditionalParameters.SelectedRows;
	
	For Each RowID In SelectedRows Do
		
		CurrentRow = Object.Goods.FindByID(RowID);
		WhenChangingCategoryOfOperation(CurrentRow);
		
	EndDo;
	
	InventoryInOperationClient.ProcessLineWhenChangingCategoryOfOperation(SelectedRows, Object.Goods);
	
EndProcedure

&AtClient
Procedure FillInInventoryNumberCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		FillInInventoryNumberOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInInventoryNumberOnServer()
	
	TakeIntoAccountInventoryNumbers = New Array;
	For Each RowData In Object.Goods Do
		If RowData.StocktakingRecord
			And ValueIsFilled(RowData.AssetID)
			And Items.Goods.SelectedRows.Find(RowData.GetID()) = Undefined Then
			TakeIntoAccountInventoryNumbers.Add(RowData.AssetID);
		EndIf;
	EndDo;
	
	StringsList = New Array;
	For Each RowID In Items.Goods.SelectedRows Do
		RowData = Object.Goods.FindByID(RowID);
		If RowData.StocktakingRecord Then
			StringsList.Add(RowID);
		EndIf;
	EndDo;

	NewInventoryNumbers = InventoryInOperationServer.NewInventoryNumbers(
		StringsList.Count(),
		TakeIntoAccountInventoryNumbers, 
		Object.Ref);
	
	For IndexOf = 0 To StringsList.UBound() Do
		RowData = Object.Goods.FindByID(StringsList[IndexOf]);
		RowData.AssetID = NewInventoryNumbers[IndexOf];
	EndDo;
	
EndProcedure

&AtClient
Procedure CreateGroupFACompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		CreateGroupOSOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure CreateGroupOSOnServer()
	
	StringsList = New Array;
	For Each RowID In Items.Goods.SelectedRows Do
		RowData = Object.Goods.FindByID(RowID);
		If RowData.AccountAsGroupFA Then
			StringsList.Add(RowData);
		EndIf;
	EndDo;

	If StringsList.Count() = 0 Then
		Return;
	EndIf;

	TabularSection = Object.Goods; // FormDataCollection
	ListOfCategories = TabularSection.Unload(StringsList, "OperationCategory").UnloadColumn("OperationCategory");
	
	QueryText = 
	"SELECT
	|	OperationCategories.Ref AS Ref,
	|	OperationCategories.OSGroup AS OSGroup,
	|	&StartDateOfOperation AS StartDateOfOperation,
	|	CASE
	|		WHEN ISNULL(OperationCategories.ServiceLife, 0) <> 0
	|			THEN BEGINOFPERIOD(ENDOFPERIOD(DATEADD(&StartDateOfOperation, MONTH, OperationCategories.ServiceLife), MONTH), DAY)
	|		ELSE DATETIME(1,1,1)
	|	END AS CompletionDate_,
	|	OperationCategories.ServiceLife AS ServiceLife
	|FROM
	|	Catalog.OperationCategories AS OperationCategories
	|WHERE
	|	OperationCategories.Ref IN (&ListOfCategories)
	|	AND OperationCategories.AccountAsGroupFA";
	
	Query = New Query(QueryText);
	Query.SetParameter("ListOfCategories", ListOfCategories);
	Query.SetParameter("StartDateOfOperation", BegOfMonth(Object.Date));
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	CreatedOS = New Map();
	NamingParameters = New Structure("StartDateOfOperation,CompletionDate_,ServiceLife,OperationCategory");

	While Selection.Next() Do
		
		FillPropertyValues(NamingParameters, Selection);
		NamingParameters.OperationCategory = Selection.Ref;
		
		FixedAsset = Catalogs.Assets.CreateItem();
		FixedAsset.OSType = Enums.FATypes.GroupFA;
		FixedAsset.Description = Catalogs.LotsOfInventoryInOperation.FormNameOfGroupOS(NamingParameters);
		FixedAsset.OSGroup = Selection.OSGroup;
		FixedAsset.Write();
	
		CreatedOS.Insert(Selection.Ref, FixedAsset.Ref);
		
	EndDo;

	For Each RowData In StringsList Do
		FixedAsset = CreatedOS.Get(RowData.OperationCategory);
		If FixedAsset <> Undefined Then
			RowData.FixedAsset = FixedAsset;
		EndIf;
	EndDo;
	
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
