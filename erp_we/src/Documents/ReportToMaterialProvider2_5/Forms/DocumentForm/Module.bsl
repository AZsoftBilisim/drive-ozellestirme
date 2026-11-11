#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

&AtClient
Var PreviousRowDetails; //used to separate the report line from the order line

&AtClient
Var CurDataId; //used to pass the current line to the wait handler

&AtClient
Var CounterpartyVerificationWaitHandlerParameters Export;

&AtClient
Var TimeConsumingOperationForm Export;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	SetConditionalAppearance();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object",                   Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization",  True);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisObject);
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	// ItemsAndDimensionsSelectionParameters
	ItemsAndDimensionsSelectionParameters = Documents.ReportToMaterialProvider2_5.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	// End ItemsAndDimensionsSelectionParameters
	
	// GLAccountSettings
	SetupParameters = Documents.ReportToMaterialProvider2_5.AccountingAccountSettings_();
	GLAccountSettingsServer.OnCreateAtServer(ThisObject, SetupParameters);
	// End GLAccountSettings
	
	SalesServer.SetModeForSelectingGroupsOfWarehouseItems(Items.Warehouse);
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.GroupInTotal.BackColor = New Color();
	EndIf;
	
	SetVisibilityOfElementsByTaxationServer();
	
	SetAvailabilityOfClipboardCommands();

	Items.ManufacturedProductPriceKind.QuickChoice = Not GetFunctionalOption("UseSeveralPriceTypes");
	
	// ARAPAccounting
	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisObject);
	// End ARAPAccounting
	
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	DocumentCorrection.OnCreateAtServer(ThisObject, Items.LineCorrection);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecording.OnCreateAtServerDocumentForm(ThisObject);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
	AddSBPPaymentStatusUpdateCommand();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	PreviousRowDetails = New Structure;
	PreviousRowDetails.Insert("Products");
	PreviousRowDetails.Insert("Characteristic");
	PreviousRowDetails.Insert("Package");
	PreviousRowDetails.Insert("Count");
	PreviousRowDetails.Insert("NumberOfPackages");
	PreviousRowDetails.Insert("Warehouse");
	PreviousRowDetails.Insert("Series");
	PreviousRowDetails.Insert("ItemsType");
	PreviousRowDetails.Insert("ItemVariantsAreUsed");
	PreviousRowDetails.Insert("SKU");
	PreviousRowDetails.Insert("MaterialProviderOrder");
	PreviousRowDetails.Insert("RowCode");
	
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
	CashClientLocalization.AttachablePaymentVerificationViaServices(ThisObject, Object.Ref, Object.Counterparty);

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	DocumentCorrection.OnReadAtServer(ThisObject, Items.LineCorrection);
	
	OnReadCreateAtServer();
	
	// ARAPAccounting
	ARAPAccountingFormWork.FormWhenReadingOnServer(ThisObject);
	// End ARAPAccounting
	
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	// ItemsAndDimensionsSelectionParameters
	ItemsAndDimensionsSelectionParameters = Documents.ReportToMaterialProvider2_5.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	// End ItemsAndDimensionsSelectionParameters
	
	// GLAccountSettings
	SetupParameters = Documents.ReportToMaterialProvider2_5.AccountingAccountSettings_();
	GLAccountSettingsServer.OnReadAtServer(ThisObject, SetupParameters);
	// End GLAccountSettings
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	WhenChangingWarehouseInTablePartServer();
	
	// Filling in service details (not visible to the user)
	FillInDependentServiceAttributes();
	FillInServiceDetailsOfTableParts();
	
	ConfigureDependentFormElements(ThisObject);
	
	SetAvailabilityOfItemsByStatusServer();
	
	UpdateOrderInformation();
	UpdateOrderDeviations();
	
	CalculateTotals_(ThisObject);
	
	UpdateInvoiceText();
	
	// ItemsAndDimensionsSelectionParameters
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	// End ItemsAndDimensionsSelectionParameters
	
	// GLAccountSettings
	GLAccountSettingsServer.AfterWriteAtServer(ThisObject);
	// End GLAccountSettings
	
	// ARAPAccounting
	ARAPAccountingFormWork.FormAfterRecordingOnServer(ThisObject);
	// End ARAPAccounting
	

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
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
	
	If EventName = "PaymentCredited" And Parameter = Object.Ref
	 Or SalesClient.ChangedPaymentDocumentsForCustomers(EventName) Then
		ChangedPaymentServer(EventName, Parameter);
	EndIf;
	If EventName = "Write_ApplicationForImportOfGoodsReceived"
		And TypeOf(Parameter) = Type("Structure")
		And Parameter.Basis1.Find(Object.Ref) <> Undefined Then
		UpdateInvoiceText();
	EndIf;
	If EventName = "ChangedStatusDependentBankingDetails"
	   And Parameter.UUID = UUID Then
		
		If Object.Approved Then
			Object.Approved = False;
		EndIf;
		
		AttachIdleHandler("Attachable_WhenChangingDetailsDependingOnStatus", 0.1, True);
		
	EndIf;
	
	If EventName = "CopyingLinesToClipboard" Then
		
		SetAvailabilityOfClipboardCommandsOnClient(True);
		
	EndIf;
	
	If EventName = "SBPStatusHasBeenChanged" Then
		AddSBPPaymentStatusUpdateCommand();
		CashClientLocalization.CheckSBPPayment(ThisObject, Object.Ref, Object.Counterparty);
	EndIf;
	
	
	DocumentCorrectionClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording	
	SourceDocumentsOriginalsRecordingClient.NotificationHandlerDocumentForm(EventName, ThisObject);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "DataProcessor.SelectGoodsToSalesDocument.Form.Form" Then
		
		ChoiceProcessingProductSelection(ValueSelected);
		
	ElsIf ChoiceSource.FormName = "Document.ReportToMaterialProvider2_5.Form.FormPickReleasedGoods" Then
		
		GetManufacturedProductsFromStorage(ValueSelected);
		
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectGoodsReceivedForCustody.Form.Form" Then
		
		SelectionProcessingSelectionOfManufacturedProducts(ValueSelected);
		
	ElsIf ChoiceSource.FormName = "CommonForm.PrintingDetailsOfSales" Then
		
		If ValueSelected <> Undefined Then
			Modified = True;
			FillPropertyValues(Object, ValueSelected);
		EndIf;
		
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected);
		
	ElsIf VATAccountingERPClient.FinishedEditingInvoiceIssued(ValueSelected, ChoiceSource) Then
		
		UpdateInvoiceText();
		
	EndIf;
	
	If Window <> Undefined Then
		Window.Activate();
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
	Notify("Write_ReportToMaterialProvider2_5", WriteParameters, Object.Ref);

	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);

	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// GLAccountSettings
	GLAccountSettingsServer.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End GLAccountSettings
	
	// Handler of the "Properties" mechanism
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	
	
	ARAPAccountingServer.BeforeWriteAtServer(ThisForm, CurrentObject);
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	BeforeWriteAtClientServer();
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtClientServer()
	ARAPAccountingServerCall.FormBeforeRecordingOnClientServer(ThisObject);
EndProcedure

&AtClient
Procedure OnClose(Exit)

	CashClientLocalization.DisablePaymentVerificationViaServices(ThisObject);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(
		ThisObject, FormattedStringURL, StandardProcessing);

EndProcedure

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If CurrentPage.Name = "AdditionalPage"
	   And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure ReportOnOrdersOnChange(Item)
	
	ClearMessages();
	If Object.ReportOnOrders Then
		
		If UseReportToMaterialProviderBySeveralOrders2_5 Then
		
			If Object.ManufacturedProduct.Count() = 0 Then
				
				QueryText = NStr("vi = 'Sẽ điền lại danh sách ""Thành phẩm"" Hàng hóa bằng số dư của thành phẩm chưa được tạo theo đơn hàng.
										|Tiếp tục?';
										|ru = 'Список ""Выпущенная продукция"" будет перезаполнен остатками неоформленных товаров по заказам.
										|Продолжить?';
										|en = 'The ""Released products"" list will be refilled with the remaining unregistered goods by orders.
										|Continue?'; fa = 'The ""Released products"" list will be refilled with the remaining unregistered goods by orders.
										|Continue?';
										|it = 'L''elenco ""Prodotti emessi"" sarà ricompilato con i saldi delle merci non formalizzate in base agli ordini.
										|Continuare?';
										|pl = 'Lista ""Wyprodukowana produkcja"" zostanie ponownie wypełniona niezarejestrowanymi zapasami według zamówień.
										|Kontynuować?';
										|tr = '""Piyasaya sürülen ürünler"" listesi siparişlere ilişkin işlenmemiş malların bakiyeleri ile yeniden doldurulacaktır.
										| Devam edilsin mi?'");
				
			Else
				
				QueryText = NStr("vi = 'Dòng trong danh sách ""Thành phẩm"" sẽ được gán vào dòng đơn hàng.
										|Tiếp tục?';
										|ru = 'Строки в списке ""Выпущенная продукция"" будут привязаны к строкам заказов.
										|Продолжить?';
										|en = 'The ""Released products"" list lines will be linked to the order lines.
										|Continue?'; fa = 'The ""Released products"" list lines will be linked to the order lines.
										|Continue?';
										|it = 'Le stringhe nell''elenco ""Prodotti emessi"" saranno associati alle righe degli ordini.
										|Continuare?';
										|pl = 'Wiersze na liście ""Wyprodukowana produkcja"" zostaną powiązane z wierszami zamówień.
										|Kontynuować?';
										|tr = '""Piyasaya sürülen imal edilen ürünler"" listesindeki satırlar sipariş satırlarına bağlanacaktır.
										| Devam edilsin mi?'");
				
			EndIf;
		
		Else
			
			FilterParameters = New Structure;
			FilterParameters.Insert("Recorder",                         Object.Ref);
			If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReportToMaterialProvider2_5") Then
				FilterParameters.Insert("BusinessOperation",           PredefinedValue("Enum.BusinessTransactions.TollManufacturing2_5"));
			Else
				FilterParameters.Insert("BusinessOperation",           Object.BusinessOperation);
			EndIf;
			FilterParameters.Insert("Organization",                         Object.Organization);
			FilterParameters.Insert("Partner",                             Object.Partner);
			FilterParameters.Insert("Counterparty",                          Object.Counterparty);
			FilterParameters.Insert("Contract",                             Object.Contract);
			FilterParameters.Insert("Warehouse",                               Object.Warehouse);
			FilterParameters.Insert("Currency",                              Object.ARAPCurrency);
			FilterParameters.Insert("SalesOpportunity",                              Object.SalesOpportunity);
			FilterParameters.Insert("VATTaxation",                  Object.VATTaxation);
			FilterParameters.Insert("LineOfBusiness",             Object.LineOfBusiness);
			FilterParameters.Insert("UseLinesOfBusiness", UseLinesOfBusiness);
			
			FormParameters = New Structure;
			FormParameters.Insert("Filter", FilterParameters);
		
			OpenForm(
				"Document.ReportToMaterialProvider2_5.Form.ReferenceChoiceForm",
				FormParameters,,,,,
				New CallbackDescription("ReportOnOrdersChangedAfterSelection", ThisObject),
				FormWindowOpeningMode.LockOwnerWindow);
				
			Return;
			
		EndIf;
		
	Else
		
		If Object.ManufacturedProduct.Count() > 0 Then
			
			If UseReportToMaterialProviderBySeveralOrders2_5 Then
				
				QueryText = NStr("vi = 'Dòng trong danh sách ""Thành phẩm"" không còn liên kết với dòng trong đơn hàng.
										|Tiếp tục?';
										|ru = 'Строки в списке ""Выпущенная продукция"" перестанут быть связанными со строками заказов.
										|Продолжить?';
										|en = 'The ""Released products"" list lines will be unlinked from the lines in the orders.
										|Continue?'; fa = 'The ""Released products"" list lines will be unlinked from the lines in the orders.
										|Continue?';
										|it = 'Le stringhe nell''elenco ""Prodotti emessi"" non saranno più associate con le stringhe degli ordini.
										|Continuare?';
										|pl = 'Wiersze na liście ""Wyprodukowana produkcja"" nie będą więcej powiązane z wierszami zamówień.
										|Kontynuować?';
										|tr = '""Piyasaya sürülen imal edilen ürünler"" listesindeki satırlar artık sipariş satırlarına bağlanmayacaktır.
										| Devam edilsin mi?'");
				
			Else
				
				QueryText = NStr("vi = 'Dòng trong danh sách ""Thành phẩm"" sẽ không còn liên kết với dòng của đơn hàng.
										|Tiếp tục?';
										|ru = 'Строки в списке ""Выпущенная продукция"" перестанут быть связанными со строками заказа.
										|Продолжить?';
										|en = 'The ""Released products"" list lines will be unlinked from the order lines.
										|Continue?'; fa = 'The ""Released products"" list lines will be unlinked from the order lines.
										|Continue?';
										|it = 'Le stringhe nell''elenco ""Prodotti emessi"" smetteranno di essere associate con le stringhe dell''ordine.
										|Continuare?';
										|pl = 'Wiersze na liście ""Wyprodukowana produkcja"" nie będą więcej powiązane z wierszami zamówienia.
										|Kontynuować?';
										|tr = '""Piyasaya sürülen imal edilen ürünler"" listesindeki satırlar artık sipariş satırlarına bağlanmayacaktır.
										| Devam edilsin mi?'");
				
			EndIf;
			
		Else
			
			WhenChangingReportForMultipleOrders();
			Return;
			
		EndIf;
		
	EndIf;
	
	ReportOnOrdersWhenFragmentChanges(Undefined, QueryText);
	
EndProcedure

&AtClient
Procedure ReportOnOrdersChangedAfterSelection(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Object.ReportOnOrders = False;
		Return;
	EndIf;
	
	If Object.ManufacturedProduct.Count() = 0 Then
		
		QueryText = NStr("vi = 'Sẽ điền danh sách ""Thành phẩm"" bằng số dư của hàng hóa chưa tạo theo chứng từ %1.
								|Tiếp tục?';
								|ru = 'Список ""Выпущенная продукция"" будет заполнен остатками неоформленных товаров по документу %1.
								|Продолжить?';
								|en = 'The ""Released products"" list will be filled with the remaining unregistered goods by the %1 document.
								|Continue?'; fa = 'The ""Released products"" list will be filled with the remaining unregistered goods by the %1 document.
								|Continue?';
								|it = 'L''elenco ""Prodotti emessi"" sarà compilato con i saldi non formalizzati delle merci in base al documento %1.
								|Continuare?';
								|pl = 'Lista ""Wyprodukowana produkcja"" zostanie wypełniona niezarejestrowanymi zapasami według dokumentu %1.
								|Kontynuować?';
								|tr = '""Piyasaya sürülen imal edilen ürünler"" listesi, %1 belgesine göre işlenmemiş ürünlerin bakiyeleri ile doldurulacaktır.
								| Devam edilsin mi?'");
		
	Else
		
		QueryText = NStr("vi = 'Dòng trong danh sách ""Thành phẩm"" sẽ được gán vào dòng chứng từ %1.
								|Tiếp tục?';
								|ru = 'Строки в списке ""Выпущенная продукция"" будут привязаны к строкам документа %1.
								|Продолжить?';
								|en = 'The ""Released products"" list lines will be linked to the %1 document lines.
								|Continue?'; fa = 'The ""Released products"" list lines will be linked to the %1 document lines.
								|Continue?';
								|it = 'Le stringhe nell''elenco ""Prodotti emessi"" saranno associati alle stringhe del documento %1.
								|Continuare?';
								|pl = 'Wiersze na liście ""Wyprodukowana produkcja"" zostaną powiązane z wierszami dokumentu %1.
								|Kontynuować?';
								|tr = '""Piyasaya sürülen imal edilen ürünler"" listesindeki satırlar %1 belgesinin satırlarına bağlanacaktır.
								| Devam edilsin mi?'");
		
	EndIf;
	
	ReportOnOrdersWhenFragmentChanges(Result, StrTemplate(QueryText, Result.MaterialProviderOrder));
	
EndProcedure

&AtClient
Procedure ReportOnOrdersWhenFragmentChanges(Result, QueryText)
	
	AdditionalParameters = New Structure("Result", Result);
	
	ShowQueryBox(
		New CallbackDescription("ReportOnOrdersOnChangeCompletion", ThisObject, AdditionalParameters),
		QueryText,
		QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure ReportOnOrdersOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.No Then
		Object.ReportOnOrders = Not Object.ReportOnOrders;
		Return;
	EndIf;
	
	If ValueIsFilled(AdditionalParameters.Result) Then
		Object.MaterialProviderOrder = AdditionalParameters.Result.MaterialProviderOrder;
		Object.ARAPObjectSettings = AdditionalParameters.Result.ARAPObjectSettings;
	EndIf;
	
	WhenChangingReportForMultipleOrders();
	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	If Not ValueIsFilled (Object.Partner) Then
		Return;
	EndIf;
	
	WhenChangingPartnerServer();
	
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	If AttributesValuesBeforeChange.Warehouse <> Object.Warehouse Then
		
		If Object.ReportOnOrders
		   And Object.ManufacturedProduct.Count() > 0 Then
			
			If Not ItIsGroupOfWarehousesAndWarehousesUsedByWHForSale(Object.Warehouse) Then
				
				ButtonsList = New ValueList;
				
				If Object.ManufacturedProduct.FindRows(New Structure("RowCode", 0)).Count() > 0 Then
					
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
					
					QueryText = NStr("vi = 'Khi thay đổi kho bãi, cần xóa danh sách ""Thành phẩm"" hoặc bỏ liên kết dòng với đơn hàng.
											|Tiếp tục?';
											|ru = 'При изменении склада список ""Выпущенная продукция"" необходимо очистить, либо отвязать строки от заказа.
											|Продолжить?';
											|en = 'When changing the warehouse, clear the ""Released products"" list or unlink the lines from the order.
											|Continue?'; fa = 'When changing the warehouse, clear the ""Released products"" list or unlink the lines from the order.
											|Continue?';
											|it = 'Alla modifica del magazzino, l''elenco ""Prodotti emessi"" deve essere cancellato, oppure le stringhe devono essere scollegate dall''ordine.
											|Continuare?';
											|pl = 'Po zmianie magazynu lista ""Wyprodukowana produkcja"" musi zostać wyczyszczona lub należy odłączyć wiersze od zamówienia.
											|Kontynuować?';
											|tr = 'Stoku değiştirdiğinizde, ""Piyasaya sürülen imal edilen ürünler"" listesinin temizlenmesi veya satırların siparişten ayrılması gerekir.
											| Devam edilsin mi?'")
					
				Else
					
					ButtonsList.Add("Continue", NStr("vi = 'Tiếp tục';
													|ru = 'Продолжить';
													|en = 'Continue'; fa = 'ادامه';
													|it = 'Continuare';
													|pl = 'Continue';
													|tr = 'Devam'"));
					
					QueryText = NStr("vi = 'Danh sách ""Thành phẩm"" sẽ bị xóa. Tiếp tục?';
									|ru = 'Список ""Выпущенная продукция"" будет очищен. Продолжить?';
									|en = 'List ""Released products"" will be cleared. Continue?'; fa = 'List ""Released products"" will be cleared. Continue?';
									|it = 'L''elenco ""Prodotti emessi"" verrà cancellato. Continuare?';
									|pl = 'Lista ""Wypuszczone wiersze pozycji"" zostanie wyczyszczona. Kontynuować?';
									|tr = '""Piyasaya sürülen imal edilen ürünler"" listesi temizlenecek. Devam edilsin mi?'")
					
				EndIf;
				
				ButtonsList.Add("Cancel", NStr("vi = 'Hủy bỏ';
												|ru = 'Отмена';
												|en = 'Cancel'; fa = 'انصراف';
												|it = 'Annulla';
												|pl = 'Cancel';
												|tr = 'İptal'"));
				
				ShowQueryBox(
					New CallbackDescription("WarehouseOnChangeCompletion", ThisObject), QueryText, ButtonsList);
				
				Return;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	WarehouseWhenFragmentChanges(False, False);
	
EndProcedure

&AtClient
Procedure WarehouseOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = "Cancel" Then
		Object.Warehouse = AttributesValuesBeforeChange.Warehouse;
		Return;
	EndIf;
	
	UntieAllLinesFromOrder = QuestionResult = "Unlink";
	ClearLines_             = QuestionResult <> "Unlink";
	
	WarehouseWhenFragmentChanges(ClearLines_, UntieAllLinesFromOrder);
	
EndProcedure

&AtClient
Procedure WarehouseWhenFragmentChanges(ClearLines_, UntieAllLinesFromOrder)
	
	WhenChangingWarehouseServer(ClearLines_, UntieAllLinesFromOrder);
	
EndProcedure

&AtClient
Procedure ContactPersonOnChange(Item)
	
	If Not ValueIsFilled(Object.ContactPerson)
	 Or ValueIsFilled(Object.Partner) Then
		Return;
	EndIf;
	
	WhenChangingContactPersonServer();
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	If Object.Contract = AttributesValuesBeforeChange.Contract Then
		Return;
	EndIf;
	
	BasisChanged = BasisChanged And ValueIsFilled(Object.Basis);
	
	If Object.ManufacturedProduct.Count() > 0 Then
		
		ShowQueryBox(
			New CallbackDescription("ContractOnChangeCompletion", ThisObject),
			NStr("vi = 'Sẽ xóa bảng ""Thành phẩm"". Tiếp tục?';
				|ru = 'Будет очищена таблица ""Выпущенная продукция"". Продолжить?';
				|en = 'The Released products tab will be cleared. Do you want to continue?'; fa = 'The Released products tab will be cleared. Do you want to continue?';
				|it = 'La tabella ""Prodotti emessi"" verrà cancellata. Continuare?';
				|pl = 'Będzie wyczyszczona tabela ""Wypuszczone wiersze pozycji"", Kontynuować?';
				|tr = '""Piyasaya sürülen imal edilen ürünler"" tablosu temizlenecek. Devam edilsin mi?'"),
			QuestionDialogMode.YesNo);
		
	Else
		
		WhenChangingAgreementServer();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure VATTaxationOnChange(Item)
	
	WhenChangingVATTaxationServer(CachedValues);
	
EndProcedure

&AtClient
Procedure PriceIncludesVATOnChange(Item)
	
	OnChangePriceIncludesVATServer(CachedValues);
	
EndProcedure

&AtClient
Procedure TextOfTheInvoiceIssuedURLProcessing(Item, Var_URL, StandardProcessing)
	
	RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesIssued();
	RegistrationParameters.Ref				  = Object.Ref;
	RegistrationParameters.Date				  = Object.Date;
	RegistrationParameters.Organization		  = Object.Organization;
	RegistrationParameters.Counterparty			  = Object.Counterparty;
	RegistrationParameters.VATTaxation	  = Object.VATTaxation;
	RegistrationParameters.ImplementationOfWorksServices = True;
	
	VATAccountingERPClient.ProcessingNavigationLinkInvoicesIssued(
		ThisObject, Var_URL, StandardProcessing, RegistrationParameters);
	
	TextURLProcessing(Item, Var_URL, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	
	Var PricesCalculated;
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If Not Object.ReportOnOrders Then
		
		EnterprisePricesFillingClient.AskQuestionAboutRecalculatingPriceWhenDateChanges(
			Object,
			New CallbackDescription("DateOnChangeCompletion", ThisObject),
			"ManufacturedProduct",
			False,
			NStr("vi = 'Điền lại đơn giá?';
				|ru = 'Перезаполнить цены?';
				|en = 'Refill prices?'; fa = 'Refill prices?';
				|it = 'Ricompilare i prezzi?';
				|pl = 'Ponownie wypełnić ceny?';
				|tr = 'Fiyatlar yeniden doldurulsun mu?'"));
		
		Return;
		
	EndIf; 
	
	RecalculatePrices_ = False;
	
	WhenChangingDateServer(RecalculatePrices_, PricesCalculated);

	
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	If Not Object.BusinessOperation = AttributesValuesBeforeChange.BusinessOperation Then
		
		If Not Object.ManufacturedProduct.Count() = 0 Then
			
			ShowQueryBox(
				New CallbackDescription("BusinessOperationOnChangeCompletion", ThisObject),
				NStr("vi = 'Khi thay đổi sẽ thực hiện xác minh sự tương ứng giữa mặt hàng được chỉ định trong chứng từ, giao dịch đã chọn và xóa dòng không tương ứng. Tiếp tục?';
					|ru = 'При изменении будет выполнена проверка соответствия указанной в документе номенклатуры, выбранной операции и удаление несоответствующих строк. Продолжить?';
					|en = 'Upon the change, the compliance of the item specified in the document, the selected operation, and the deletion of nonconforming lines will be checked. Continue?'; fa = 'Upon the change, the compliance of the item specified in the document, the selected operation, and the deletion of nonconforming lines will be checked. Continue?';
					|it = 'Upon the change, the compliance of the item specified in the document, the selected operation, and the deletion of nonconforming lines will be checked. Continue?';
					|pl = 'Upon the change, the compliance of the item specified in the document, the selected operation, and the deletion of nonconforming lines will be checked. Continue?';
					|tr = 'Değişiklik yapıldığında, belgede belirtilen öğenin seçili işlemle eşleştiğinden emin olmak için kontrol yapılacak ve tutarsız satırlar silinecektir. devam edilsin mi?'"),
				QuestionDialogMode.YesNo);
				
		Else
			BusinessOperationOnChangeCompletion(DialogReturnCode.Yes, Undefined)
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	WhenOrganizationChangesServer();
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	WhenChangingCounterpartyServer();
	
	
EndProcedure

&AtClient
Procedure TextAllowedCreditBalanceClick(Item, StandardProcessing)
	
	ARAPAccountingClient.DebtLimitsClick(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure LabelPaymentStagesClick(Item, StandardProcessing)
	
	PlacePaymentStepsInTemporaryStorage(Item.Name);
	
	Notification = New CallbackDescription("LabelPaymentStagesClickCompletion", ThisObject);
	ARAPAccountingClient.LabelPaymentStagesClick(ThisObject, Item, StandardProcessing, Notification);
	
EndProcedure

&AtClient
Procedure LabelPaymentStagesClickCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		ChangedBankingDetails = Result.OldValuesOfChangedProps;
		ReflectChangesToPaymentRules(ChangedBankingDetails);
	EndIf
	
EndProcedure

&AtClient
Procedure ManagerOnChange(Item)
	
	FillInSubordinatePropertiesForStatistics("Manager");
	
EndProcedure

&AtClient
Procedure LineOfBusinessOnChange(Item)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.ReportToMaterialProvider2_5.Form.DocumentForm.Item.LineOfBusiness.OnChange");
	
	LineOfBusinessOnChangeServer();
	
EndProcedure

&AtClient
Procedure LabelCurrenciesClick(Item, StandardProcessing)
	
	Notification = New CallbackDescription("LabelCurrenciesClickCompletion", ThisObject);
	ARAPAccountingClient.CurrencyAndExchangeRateOfDocument(ThisObject, Item, StandardProcessing, Notification);
	
EndProcedure

&AtClient
Procedure OrdersLabelClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	FormParameters.Insert("DocumentsList", OrderList);
	FormParameters.Insert("Title",        NStr("vi = 'Đơn hàng của bên đặt gia công (%DocumentsCount%)';
												|ru = 'Заказы давальцев (%DocumentsCount%)';
												|en = 'Subcontracting sales orders (%DocumentsCount%)'; fa = 'Subcontracting sales orders (%DocumentsCount%)';
												|it = 'Ordini dei prestatori (%DocumentsCount%)';
												|pl = 'Zamówienia właścicieli surowca (%DocumentsCount%)';
												|tr = 'Sağlayıcı siparişleri (%DocumentsCount%)'"));
	
	OpenForm(
		"CommonForm.ViewingListOfDocuments",
		FormParameters,
		ThisObject,,,,
		Undefined,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure Attachable_OriginalStateDecorationClick()

	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecordingClient.OpenStateSelectionMenu(ThisObject, Items.OriginalStateDecoration);
	//End StandardSubsystems.SourceDocumentsOriginalsRecording

EndProcedure

&AtClient
Procedure VATRateOnChange(Item)
	
	If Object.VATRate = AttributesValuesBeforeChange.VATRate Then
		Return;
	EndIf;
	
	WhenChangingVATRateServer();
	
EndProcedure

&AtClient
Procedure ContentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText,
		ThisObject,
		"Object.ProcessingService",
		NStr("vi = 'Nội dung dịch vụ gia công';
			|ru = 'Содержание услуги по переработке';
			|en = 'Subcontracting service content'; fa = 'Subcontracting service content';
			|it = 'Il contenuto del servizio di trasformazione';
			|pl = 'Opis usług przetwarzania';
			|tr = 'İşleme hizmetlerinin içeriği'"));
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersManufacturedProduct

&AtClient
Procedure ManufacturedProductOnStartEdit(Item, NewRow, Copy)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.ManufacturedProduct, ThisObject);
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(
		Item, CachedValues, SeriesSpecificationParameters, Copy);
		
	CurrentData = Items.ManufacturedProduct.CurrentData;
	
	If Copy Then
		
		If CurrentData.RowCode <> 0 Then
			CurrentData.RowCode = 0;
		EndIf;
		
	EndIf;
	
	If NewRow Then
		
		If Copy Then
			
			GLAccountSettingsClient.WhenCopyingString(ThisObject, Item);
			
		Else
			
			StructureOfActions = New Structure;
			
			If Not VATRateIsIndicatedInTablePart(Object.BusinessOperation) Then
				CurrentData.VATRate = Object.VATRate;
			Else
				AddActionToStructureFillInVATRate(Object, StructureOfActions);
			EndIf;
			
			IncomeAndExpensesClientServer.InsertActionInitializeArticleAndAnalyticsAfterAddingLine(
				StructureOfActions, ThisObject, "Object.ManufacturedProduct");
			
			ParametersForFillingInPriceType = BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceTypeInTSLine("PriceKind");
			ParametersForFillingInPriceType.DefaultPriceType = DefaultPriceType;
			ParametersForFillingInPriceType.FilterParameters.PriceIncludesVAT = Object.PriceIncludesVAT;
			ParametersForFillingInPriceType.FilterParameters.UseWhileTransferringProductsToMaterialProvider = True;
			StructureOfActions.Insert("CheckFillInPriceView", ParametersForFillingInPriceType);
			
			BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
			
		EndIf;
		
	EndIf;
	
	UpdateOrderDeviationsInLine(CurrentData, Object.ReportOnOrders);
	
EndProcedure

&AtClient
Procedure ManufacturedProductBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	
	If CancelEdit Then
		Return;
	EndIf;
	
	CurrentData = Items.ManufacturedProduct.CurrentData;
	
	If ProductsClient.SeriesStatusesNeedToBeUpdated(Item, CachedValues, SeriesSpecificationParameters) Then
		
		RowID = CurrentData.GetID();
		
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(RowID, CachedValues);
		
		ProductsClient.UpdateCachedValuesToAccountForSeries(
			Item, CachedValues, SeriesSpecificationParameters);
		
	EndIf;
	
	If Not ValueIsFilled(CurrentData.MaterialProviderOrder) Then
		
		If ValueIsFilled(Object.MaterialProviderOrder) Then
			
			CurrentData.MaterialProviderOrder = Object.MaterialProviderOrder;
			If Not CurrentData.RowCode = 0
				Or Not ValueIsFilled(CurrentData.Purpose) Then
				CurrentData.Purpose =
					GeneralPurposeTMServerCall.ObjectAttributeValue(CurrentData.MaterialProviderOrder, "Purpose");
			EndIf;
			
		ElsIf Not ValueIsFilled(CurrentData.Purpose) Then
			
			CurrentData.Purpose    = PurposeOfContract;
			
		EndIf;
		
	EndIf;
	
	LineCache =
		?(NewRow, Undefined, ProcessingOfTabularFormsClientServer.LineCache(Items.ManufacturedProduct, ThisObject));
	
	WarehousesClient.UpdateWarehouseTable(WarehouseTable, CurrentData, LineCache, WarehouseGroup_, False);
	TotalWarehouses_ = WarehouseTable.Count();
	WarehousesClientServer.UpdateWarehouseGroupImage(
		SeveralWarehousesText, Items.PictureMultipleWarehouses, TotalWarehouses_);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure ManufacturedProductBeforeDeleteRow(Item, Cancel)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.ManufacturedProduct, ThisObject);
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters);
	
EndProcedure

&AtClient
Procedure ManufacturedProductAfterDeleteRow(Item)
	
	CalculateTotals_(ThisObject);
	
	SeriesStatusesNeedToBeUpdated = ProductsClient.SeriesStatusesNeedToBeUpdated(
										Item, CachedValues, SeriesSpecificationParameters, True);

	ManufacturedProductAfterDeleteRowServer(SeriesStatusesNeedToBeUpdated, CachedValues);
	
	If SeriesStatusesNeedToBeUpdated Then
		
		ProductsClient.UpdateCachedValuesToAccountForSeries(
			Item, CachedValues, SeriesSpecificationParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ManufacturedProductBeforeRowChange(Item, Cancel)
	
	FillPropertyValues(PreviousRowDetails, Items.ManufacturedProduct.CurrentData);
	
EndProcedure

&AtClient
Procedure ManufacturedProductSelection(Item, RowSelected, Field, StandardProcessing)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.ReportToMaterialProvider2_5.Form.DocumentForm.Item.ManufacturedProduct.Selection");
	
	CurrentData = Items.ManufacturedProduct.CurrentData;
	
	If Field = Items.ManufacturedProductPrice Then
		
		If Not IsFullUser
		   And Not VarianceFromSalesTermsAndConditions
		   And ValueIsFilled(CurrentData.RowCode) Then
			StandardProcessing = False;
			Return;
		EndIf;
		
		If ReadPriceTypeRight Then
			
			If ValueIsFilled(CurrentData.PriceKind) And Not Object.Approved Then
				
				ClearMessages();
				
				CommonClient.MessageToUser(
					NStr("vi = 'Để soạn đơn giá, hãy xóa dạng giá';
						|ru = 'Для редактирования цены очистите вид цены';
						|en = 'To edit the price, clear the price type'; fa = 'To edit the price, clear the price type';
						|it = 'Для редактирования цены очистите вид цены';
						|pl = 'To edit the price, clear the price type';
						|tr = 'Fiyatı düzenlemek için fiyat türünü temizleyin'"),
					Object.Ref,
					CommonClientServer.PathToTabularSection(
						"Object.ManufacturedProduct", CurrentData.LineNumber, "PriceKind"),);
				
			EndIf;
			
		EndIf;
		
	ElsIf Field = Items.ManufacturedProductPriceKind Then
		
		If Not IsFullUser
		   And Not VarianceFromSalesTermsAndConditions
		   And ValueIsFilled(CurrentData.RowCode) Then
			StandardProcessing = False;
		EndIf;
		
	ElsIf Field = Items.ManufacturedProductMaterialProviderOrder Then
		
		If ValueIsFilled(CurrentData.MaterialProviderOrder) Then
			
			ShowValue(Undefined, CurrentData.MaterialProviderOrder);
			
		ElsIf ValueIsFilled(Object.MaterialProviderOrder) Then
			
			ShowValue(Undefined, Object.MaterialProviderOrder);
			
		EndIf;
		
	ElsIf Field = Items.ManufacturedProductTransactionRecordingPresentation
			And ValueIsFilled(CurrentData.ExpenseItem) Then
		
		GLAccountSettingsClient.OnClick(ThisObject, Field, StandardProcessing);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ManufacturedProductProductsOnChange(Item)
	
	CurrentRow = Items.ManufacturedProduct.CurrentData;
	
	AdditionalParameters = AdditionalCompletionProcessingParameters();
	AdditionalParameters.CurrentRow = CurrentRow;
	
	CallbackDescription = New CallbackDescription("ProductsProductListWhenChangingQuestionToUserEnd",
												  ThisObject,
												  AdditionalParameters);
	
	QuestionUserWhenChangingRowDetails(CallbackDescription, CurrentRow);
	
EndProcedure

&AtClient
Procedure ProductsProductListWhenChangingQuestionToUserEnd(Result, AdditionalParameters) Export
	
	If Not Result Then
		Return;
	EndIf;
	
	CurrentRow = Items.ManufacturedProduct.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert(
		"FillInSalePrice",
		BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	StructureOfActions.Insert("CheckCharacteristicsByOwner",    CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("FillInArticleAttribute",               New Structure("Products", "SKU"));
	StructureOfActions.Insert(
		"FillInProductTypeAttribute_",
		New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	StructureOfActions.Insert(
		"CheckFillWarehouse",
		BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	
	StructureOfActions.Insert(
		"CheckSeriesCalculateStatus",
		New Structure("Warehouse, SeriesSpecificationParameters", CurrentRow.Warehouse, SeriesSpecificationParameters));
	
	StructureOfActions.Insert(
		"ProductsOnChangeOverridable",
		New Structure("FormName, TabularSectionName", FormName, "ManufacturedProduct"));
		
	StructureOfActions.Insert(
		"RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	
	AddActionsClearFillArticleAnalytics(StructureOfActions, ThisObject);
	
	If VATRateIsIndicatedInTablePart(Object.BusinessOperation) Then
		AddActionToStructureFillInVATRate(Object, StructureOfActions);
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure ManufacturedProductCharacteristicOnChange(Item)
	
	CurrentRow = Items.ManufacturedProduct.CurrentData;
	
	AdditionalParameters = AdditionalCompletionProcessingParameters();
	AdditionalParameters.CurrentRow = CurrentRow;
	
	CallbackDescription = New CallbackDescription("ProductsCharacteristicWhenChangingQuestionToUserEnd",
												  ThisObject,
												  AdditionalParameters);
	
	QuestionUserWhenChangingRowDetails(CallbackDescription, CurrentRow);
	
EndProcedure

&AtClient
Procedure ProductsCharacteristicWhenChangingQuestionToUserEnd(Result, AdditionalParameters) Export
	
	If Not Result Then
		Return;
	EndIf;
	
	CurrentRow = Items.ManufacturedProduct.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert(
		"FillInSalePrice",
		BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	StructureOfActions.Insert("FillInArticleAttribute",         New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert(
		"CharacteristicOnChangeOverridable",
		New Structure("FormName, TabularSectionName", FormName, "ManufacturedProduct"));
		
	AddActionsClearFillArticleAnalytics(StructureOfActions, ThisObject);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure ManufacturedProductPackageOnChange(Item)
	
	CurrentRow = Items.ManufacturedProduct.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert(
		"RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	
	If CurrentRow.Count > 0 Then
		
		StructureOfActions.Insert("RecalculatePricePerPackage", CurrentRow.Count);
		
	ElsIf ValueIsFilled(CurrentRow.PriceKind) Then
		
		StructureOfActions.Insert(
			"FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
		
	EndIf;
	
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure ManufacturedProductPriceKindOnChange(Item)
	
	CurrentRow = Items.ManufacturedProduct.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert(
		"FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure ManufacturedProductPriceOnChange(Item)
	
	CurrentRow = Items.ManufacturedProduct.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure ManufacturedProductSumOnChange(Item)
	
	CurrentRow = Items.ManufacturedProduct.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePriceByAmount", "NumberOfPackages");
	StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure ManufacturedProductVATRateStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	DateSelectionParameter = New ChoiceParameter("Date", Object.Date);
	VATRateSelectionParameters = New Array;
	VATRateSelectionParameters.Add(DateSelectionParameter);
	Item.ChoiceParameters = New FixedArray(VATRateSelectionParameters);
	
EndProcedure

&AtClient
Procedure ManufacturedProductVATRateOnChange(Item)
	
	CurrentRow = Items.ManufacturedProduct.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure ManufacturedProductVATAmountOnChange(Item)
	
	CurrentRow = Items.ManufacturedProduct.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure ManufacturedProductNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.ManufacturedProduct.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions,Object);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GiverSOrderOfManufacturedProductsStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.ManufacturedProduct.CurrentData;
	
	If CurrentData <> Undefined Then
	
		FilterParameters = New Structure;
		FilterParameters.Insert("Recorder",                         Object.Ref);
		FilterParameters.Insert("BusinessOperation",               Object.BusinessOperation);
		FilterParameters.Insert("Organization",                         Object.Organization);
		FilterParameters.Insert("Partner",                             Object.Partner);
		FilterParameters.Insert("Counterparty",                          Object.Counterparty);
		FilterParameters.Insert("Contract",                             Object.Contract);
		FilterParameters.Insert("Warehouse",                               Object.Warehouse);
		FilterParameters.Insert("Currency",                              Object.ARAPCurrency);
		FilterParameters.Insert("SalesOpportunity",                              Object.SalesOpportunity);
		FilterParameters.Insert("VATRate",                           Object.VATRate);
		FilterParameters.Insert("VATTaxation",                  Object.VATTaxation);
		FilterParameters.Insert("LineOfBusiness",             Object.LineOfBusiness);
		FilterParameters.Insert("UseLinesOfBusiness", UseLinesOfBusiness);
		
		FormParameters = New Structure;
		FormParameters.Insert("Filter", FilterParameters);
		
		OpenForm(
			"Document.ReportToMaterialProvider2_5.Form.ReferenceChoiceForm",
			FormParameters,,,,,
			New CallbackDescription("GiverSOrderOfManufacturedProductsStartChoiceCompletion", ThisObject),
			FormWindowOpeningMode.LockOwnerWindow);
		
		Return;
		
	EndIf;
		
	UpdateOrderInformation();
		
EndProcedure

&AtClient
Procedure GiverSOrderOfManufacturedProductsStartChoiceCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.ARAPObjectSettings <> Object.ARAPObjectSettings Then
		ThereAreSpecifiedOrders = False;
		For Each RowOfProduct In Object.Goods Do 
			If ValueIsFilled(RowOfProduct.MaterialProviderOrder)
				And RowOfProduct.GetID() <> Items.Goods.CurrentData.GetID() Then
				ThereAreSpecifiedOrders = True;
			EndIf;
		EndDo;
		If ThereAreSpecifiedOrders Then
			MessageText = NStr("vi = 'Trong chứng từ đã chọn, trình tự hạch toán %1 khác với trình tự hạch toán của chứng từ %2.';
								|ru = 'У выбранного заказа порядок расчетов %1 отличается от порядка расчетов документа %2.';
								|en = 'The %1 payment terms of the selected order differ from the %2 payment terms of the document.'; fa = 'The %1 payment terms of the selected order differ from the %2 payment terms of the document.';
								|it = 'У выбранного заказа порядок расчетов %1 отличается от порядка расчетов документа %2.';
								|pl = 'The %1 payment terms of the selected order differ from the %2 payment terms of the document.';
								|tr = 'Seçilen emir için %1 alacak/borç muhasebesi prosedürü %2 belgesinin alacak/borç muhasebesi prosedüründen farklıdır.'");
			MessageText = StrTemplate(MessageText, Result.ARAPObjectSettings, Object.ARAPObjectSettings);
			RowIndex = Object.Goods.FindByID(Items.Goods.CurrentData.GetID()).LineNumber - 1;
			CommonClient.MessageToUser(MessageText,,"Object.ManufacturedProduct[" + RowIndex + "].MaterialProviderOrder");
			Return;
		Else
			Object.ARAPObjectSettings = Result.ARAPObjectSettings;
		EndIf;
	EndIf;
	
	CurrentData = Items.ManufacturedProduct.CurrentData;
	CurrentData.MaterialProviderOrder = Result.MaterialProviderOrder;
	CurrentData.Purpose    = Result.Purpose;
	
	UpdateDependentDetailsOfOrderForm_(Object.ManufacturedProduct, DiscrepancyOrderText, Items);
	
	UpdateOrderInformation();
	
EndProcedure

&AtClient
Procedure ManufacturedProductSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenSelectionOfSeries(Item.EditText, Items.ManufacturedProduct.CurrentData);
	
EndProcedure

&AtClient
Procedure ManufacturedProductSeriesOnChange(Item)

	CurrentRow = Items.ManufacturedProduct.CurrentData;
	
	AdditionalParameters = AdditionalCompletionProcessingParameters();
	AdditionalParameters.CurrentRow = CurrentRow;
	
	CallbackDescription = New CallbackDescription("ProductsSeriesWhenChangingQuestionToUserEnd",
												  ThisObject,
												  AdditionalParameters);
	
	QuestionUserWhenChangingRowDetails(CallbackDescription, CurrentRow);
	
EndProcedure

&AtClient
Procedure ProductsSeriesWhenChangingQuestionToUserEnd(Result, AdditionalParameters) Export
	
	If Not Result Then
		Return;
	EndIf;
	
	CurrentData = Items.ManufacturedProduct.CurrentData;
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	ValueSelected.Value                   = CurrentData.Series;
	ValueSelected.CurrentRowID = CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected);

EndProcedure

&AtClient
Procedure ManufacturedProductWarehouseOnChange(Item)
	
	CurrentRow = Items.ManufacturedProduct.CurrentData;
	
	AdditionalParameters = AdditionalCompletionProcessingParameters();
	AdditionalParameters.CurrentRow = CurrentRow;
	
	CallbackDescription = New CallbackDescription("ProductsWarehouseWhenChangingQuestionToUserEnd",
												  ThisObject,
												  AdditionalParameters);
	
	QuestionUserWhenChangingRowDetails(CallbackDescription, CurrentRow);
	
EndProcedure

&AtClient
Procedure ProductsWarehouseWhenChangingQuestionToUserEnd(Result, AdditionalParameters) Export
	
	If Not Result Then
		Return;
	EndIf;
	
	CurrentRow = Items.ManufacturedProduct.CurrentData;
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert(
		"CheckSeriesCalculateStatus",
		New Structure("Warehouse, SeriesSpecificationParameters", CurrentRow.Warehouse, SeriesSpecificationParameters));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure ManufacturedProductToExpenseAsOnChange(Item)
	
	CurrentData = Items.ManufacturedProduct.CurrentData;
	
	IncomeAndExpensesClientServer.WhenChangingArticleAvailabilityDetailsInLine(
		ThisObject, CurrentData, "Object.ManufacturedProduct");
	
	GLAccountSettingsClientServer.WhenChangingAccountAvailabilityDetailsInLine(
		ThisObject, CurrentData, "Object.ManufacturedProduct");
	
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
Procedure ManufacturedProductDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(
		ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ManufacturedProductDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(
		ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ManufacturedProductDimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
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
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

&AtClient
Procedure SelectGoods(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.ReportToMaterialProvider2_5.DocumentForm.Command.SelectGoods");
	
	FormCaption = StrTemplate(
						NStr("vi = 'Chọn hàng hóa vào %1';
							|ru = 'Подбор товаров в %1';
							|en = 'Pick goods in %1'; fa = 'Pick goods in %1';
							|it = 'Selezione merci in %1';
							|pl = 'Wybór towarów w %1';
							|tr = '%1 içindeki ürünlerin seçimi'"),
						?(ValueIsFilled(Object.Ref), Object.Ref, NStr("vi = 'Báo cáo dành cho người đặt gia công';
																		|ru = 'отчет давальцу';
																		|en = 'consumption report — subcontracting services delivered'; fa = 'consumption report — subcontracting services delivered';
																		|it = 'report al fornitore';
																		|pl = 'raport dla właściciela surowców';
																		|tr = 'Tüketim raporu-Verilen fason hizmetleri'")));
	
	FormParameters = New Structure;
	FormParameters.Insert("Document",                Object.Ref);
	FormParameters.Insert("Date",                    Object.Date);
	FormParameters.Insert("Currency",                  Object.Currency);
	FormParameters.Insert("Organization",             Object.Organization);
	FormParameters.Insert("PriceIncludesVAT",         Object.PriceIncludesVAT);
	FormParameters.Insert("VATTaxation",      Object.VATTaxation);
	FormParameters.Insert("LineOfBusiness", Object.LineOfBusiness);
	FormParameters.Insert("SeriesSpecificationParameters",  SeriesSpecificationParameters);
	FormParameters.Insert("Title",               FormCaption);
	FormParameters.Insert("SelectionModeUseWarehousesInTabularSection", WarehouseGroup_);
	FormParameters.Insert("SelectionModeExcludeGroupsAvailableInOrders",  True);
	FormParameters.Insert("UseAdvancedFeaturesOfSalesOrder", True);
	
	If ManufacturedProductsProduced
		And WorksAreBeingCarriedOut Then
		
		FormParameters.Insert("SelectionModeUseWarehousesInTabularSection", True);
		
		If Not WarehouseGroup_ Then
			FormParameters.Insert("Warehouse", Object.Warehouse);
		EndIf;
		
		FormParameters.Insert("FilterByProductType", ProductsClientServer.SelectionByProductReusablePackagingWork(False));
		
	ElsIf ManufacturedProductsProduced
		And Not WorksAreBeingCarriedOut Then
		
		FormParameters.Insert("SelectionModeUseWarehousesInTabularSection", True);
		
		If Not WarehouseGroup_ Then
			FormParameters.Insert("Warehouse", Object.Warehouse);
		EndIf;
		
		FormParameters.Insert("FilterByProductType", ProductsClientServer.SelectionByProductMultiTurnContainer(False));
		
	Else
		FormParameters.Insert("FilterByProductType", ProductsClientServer.JobSelection(False));
	EndIf;
	
	SelectionParametersPriceType = New Array;
	SelectionParametersPriceType.Add(New ChoiceParameter("Filter.UseWhileTransferringProductsToMaterialProvider", True));
	FormParameters.Insert("SelectionParametersPriceType", SelectionParametersPriceType);

	OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form", FormParameters, ThisObject, UUID);
	
EndProcedure

&AtClient
Procedure PickUpFromOrder(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.ReportToMaterialProvider2_5.DocumentForm.Command.PickUpFromOrder");
	
	ArrayOfStringCodes = New Array;
	For Each TSRow In Object.ManufacturedProduct Do
		
		If TSRow.RowCode <> 0 And ValueIsFilled(TSRow.MaterialProviderOrder) Then
			ArrayOfStringCodes.Add(
				New Structure("RowCode, MaterialProviderOrder", TSRow.RowCode, TSRow.MaterialProviderOrder));
		EndIf;
		
	EndDo;
	
	AnArrayOfOrders = Undefined;
	If Not UseReportToMaterialProviderBySeveralOrders2_5 Then
		AnArrayOfOrders = New Array;
		AnArrayOfOrders.Add(Object.MaterialProviderOrder);
	EndIf;
	
	PickingParameters = New Structure;
	PickingParameters.Insert("AnArrayOfOrders",           AnArrayOfOrders);
	PickingParameters.Insert("ArrayOfStringCodes",        ArrayOfStringCodes);
	PickingParameters.Insert("Ref",                  Object.Ref);
	PickingParameters.Insert("BusinessOperation",   Object.BusinessOperation);
	PickingParameters.Insert("Organization",             Object.Organization);
	PickingParameters.Insert("Partner",                 Object.Partner);
	PickingParameters.Insert("Counterparty",              Object.Counterparty);
	PickingParameters.Insert("Contract",                 Object.Contract);
	PickingParameters.Insert("Warehouse",                   Object.Warehouse);
	PickingParameters.Insert("Currency",                  Object.Currency);
	PickingParameters.Insert("ARAPCurrency",    Object.ARAPCurrency);
	PickingParameters.Insert("SalesOpportunity",                  Object.SalesOpportunity);
	PickingParameters.Insert("VATRate",               Object.VATRate);
	PickingParameters.Insert("VATTaxation",      Object.VATTaxation);
	PickingParameters.Insert("ARAPObjectSettings",         Object.ARAPObjectSettings);
	PickingParameters.Insert("LineOfBusiness", Object.LineOfBusiness);
	PickingParameters.Insert("PriceIncludesVAT",         Object.PriceIncludesVAT);
	
	OpenForm(
		"Document.ReportToMaterialProvider2_5.Form.FormPickReleasedGoods",
		PickingParameters,
		ThisObject,,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure PickUpReleasedProducts(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.ReportToMaterialProvider2_5.DocumentForm.Command.PickUpReleasedProducts");
	
	Cancel = False;
	
	ClearMessages();
	
	If Not ValueIsFilled(Object.Partner) Then
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Nhà cung cấp""';
				|ru = 'Поле ""Поставщик"" не заполнено';
				|en = '""Vendor"" is required'; fa = '""Vendor"" is required';
				|it = 'Il campo ""Fornitore"" non è compilato';
				|pl = 'Nie wypełniono pola ""Dostawca""';
				|tr = '""Tedarikçi"" alanı doldurulmadı'"), Object.Ref, "Object.Partner", "", Cancel);
	EndIf;
	
	If Not ValueIsFilled(Object.Organization) Then
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Doanh nghiệp""';
				|ru = 'Поле ""Организация"" не заполнено';
				|en = 'The ""Company"" field is required'; fa = 'The ""Company"" field is required';
				|it = 'Il campo ""Società"" non è compilato';
				|pl = 'Nie wypełniono pola ""Firma""';
				|tr = '""İş yeri"" alanı doldurulmadı'"), Object.Ref, "Object.Organization", "", Cancel);
	EndIf;
	
	If Not ValueIsFilled(Object.Warehouse) Then
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Kho bãi""';
				|ru = 'Поле ""Склад"" не заполнено';
				|en = '""Warehouse"" is required'; fa = '""Warehouse"" is required';
				|it = 'Il campo ""Magazzino"" non è compilato';
				|pl = 'Nie wypełniono pola ""Magazyn""';
				|tr = '""Ambar"" alanı doldurulmamış'"), Object.Ref, "Object.Warehouse", "", Cancel);
	EndIf;
	
	If Not ValueIsFilled(Object.Contract) Then
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Hợp đồng""';
				|ru = 'Поле ""Договор"" не заполнено';
				|en = '""Contract"" is not filled in.'; fa = '""Contract"" is not filled in.';
				|it = 'Il campo ""Accordo"" non è compilato';
				|pl = 'Pole ""Umowa"" nie jest wypełnione';
				|tr = '""Sözleşme"" alanı doldurulmamış'"), Object.Ref, "Object.Contract", "", Cancel);
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	AddressOfGoods = PlaceGoodsInStorageForSelectionOfAcceptedGoods();
	
	CurStockType    = PredefinedValue("Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider");
	CurOrderOfGiver =
		?(Object.ReportOnOrders And ValueIsFilled(Object.MaterialProviderOrder), Object.MaterialProviderOrder, Undefined);
	
	FormParameters = New Structure;
	FormParameters.Insert("Ref",                Object.Ref);
	FormParameters.Insert("Organization",           Object.Organization);
	FormParameters.Insert("Owner",              Object.Partner);
	FormParameters.Insert("Contract",               Object.Contract);
	FormParameters.Insert("Warehouse",                 Object.Warehouse);
	FormParameters.Insert("BusinessOperation", Object.BusinessOperation);
	FormParameters.Insert("InventoryType",            CurStockType);
	FormParameters.Insert("OrderDocument",                 CurOrderOfGiver);
	FormParameters.Insert("Title",             NStr("vi = 'Chọn thành phẩm';
													|ru = 'Подбор выпущенной продукции';
													|en = 'Pick released goods'; fa = 'انتخاب کالای تولیدشده';
													|it = 'Selezione di prodotti rilasciati';
													|pl = 'Wybór wypuszczonej produkcji';
													|tr = 'Piyasaya sürülen ürünlerin seçimi'"));
	FormParameters.Insert("AddressOfGoodsInvoiceInVault", AddressOfGoods);
	
	OpenForm(
		"DataProcessor.SelectGoodsReceivedForCustody.Form.Form",
		FormParameters,
		ThisObject,
		UUID);
	
EndProcedure

&AtClient
Procedure SearchByBarcode(Command)
	
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
	
	EquipmentManagerClient.StartDownloadingDataFromTSD(
		New CallbackDescription("ProductsDownloadFromTSDCompletion", ThisObject),
		UUID);
	
EndProcedure

&AtClient
Procedure ProductsDownloadFromTSDCompletion(Result, Var_Parameters) Export
	
	If Result.Result Then
		ProcessBarcodes(Result.TableOfGoods);
	Else
		EquipmentManagerTMClient.ReportError(Result);
	EndIf;
	
EndProcedure

&AtClient
Procedure SplitRow(Command)
	
	FormTable  = Items.ManufacturedProduct;
	TableData = Object.ManufacturedProduct;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.StructureOfRecalculationOfAmount(
									"Count, Sum, VATAmount, AmountIncludingVAT",
									"NumberOfPackages");
		
	If FormTable.CurrentData <> Undefined Then
		
		BatchProcessingOfTablePartClientServer.FillInStructureForRecalculatingAmount(
			StructureOfRecalculationOfAmount,
			FormTable.CurrentData);
			
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("StructureOfRecalculationOfAmount", StructureOfRecalculationOfAmount);
	
	ProcessingOfTabularFormsClient.SplitRow(
		TableData, FormTable,
		New CallbackDescription("SplitRowCompletion", ThisObject, AdditionalParameters));
	
EndProcedure

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export 
	
	If NewRow = Undefined Then
		Return;
	EndIf;
	
	CurrentRow = Items.ManufacturedProduct.CurrentData;
	
	BatchProcessingOfTablePartClientServer.AddLineToRecalculateAmount(AdditionalParameters.StructureOfRecalculationOfAmount, CurrentRow);
	BatchProcessingOfTablePartClientServer.AddLineToRecalculateAmount(AdditionalParameters.StructureOfRecalculationOfAmount, NewRow);
	BatchProcessingOfTablePartClientServer.RecalculateAmounts(AdditionalParameters.StructureOfRecalculationOfAmount);
		
	StructureOfActions = New Structure;
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
	CalculateTotals_(ThisObject);
	
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
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject);
	
EndProcedure

&AtClient
Procedure CopyRows(Command)
	
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items.ManufacturedProduct) Then
		
		CopyLinesOnServer();
		
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(
			Items.ManufacturedProduct.SelectedRows.Count());
		
	EndIf;
	
EndProcedure

&AtClient
Procedure InsertRows(Command)
	
	NumberOfProductsBeforeInsertion = Object.ManufacturedProduct.Count();
	
	GetLinesFromClipboard();
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
	NumberOfInserted = Object.ManufacturedProduct.Count() - NumberOfProductsBeforeInsertion;
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
	
EndProcedure

&AtClient
Procedure UnlinkFromOrder(Command)
	
	SelectedRows = Items.ManufacturedProduct.SelectedRows;
	
	If SelectedRows.Count() > 0 Then
		
		UnlinkFromOrderServer(False);
		NotifyAboutEndOfUnbindingLines(SelectedRows.Count());
		
	Else
		
		ShowMessageBox(Undefined, NStr("vi = 'Hãy chọn dòng mà cần hủy liên kết với đơn hàng.';
										|ru = 'Выберите строки, которые необходимо отвязать от заказа.';
										|en = 'Select lines to remove from the order.'; fa = 'Select lines to remove from the order.';
										|it = 'Selezionare le righe da dissociare dall''ordine.';
										|pl = 'Wybierz wierze, które należy odłączyć od zamówienia.';
										|tr = 'Siparişten çıkarılacak satırları seçin.'"));
		
	EndIf; 
	
EndProcedure

&AtClient
Procedure PaymentSettlement(Command)
	
	PlacePaymentDecryptionInTemporaryStorage();
	ARAPAccountingClient.PaymentSettlement(ThisObject, Items.PaymentSettlement);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

&AtClient
Procedure CalculationsClick(Item, StandardProcessing)
	
	ARAPAccountingClient.CalculationsClick(ThisForm, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure FillInPricesByPriceKind(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.ReportToMaterialProvider2_5.DocumentForm.Command.FillInPricesByPriceKind");
	
	If Not EnterprisePricesFillingClient.ItIsNecessaryToFillInPricesByTypeOfPrices(Object, "ManufacturedProduct", NStr("vi = 'Sản phẩm xuất xưởng';
																														|ru = 'Выпущенная продукция';
																														|en = 'Issued products'; fa = 'محصولات صادرشده';
																														|it = 'Prodotti emessi';
																														|pl = 'Wypuszczone wiersze pozycji';
																														|tr = 'Piyasaya sürülen imal edilen ürünler'")) Then
		Return;
	EndIf;
	
	SelectedRows = Items.ManufacturedProduct.SelectedRows;
	
	If SelectedRows.Count() = 0 Then
		
		ClearMessages();
		
		CommonClient.MessageToUser(
			NStr("vi = 'Không có dòng được chọn trong bảng. Chọn dòng để điền giá.';
				|ru = 'В таблице отсутствуют выделенные строки. Выделите строки для заполнения цен.';
				|en = 'There are no selected rows in the table. Select rows to fill the prices.'; fa = 'There are no selected rows in the table. Select rows to fill the prices.';
				|it = 'Nella tabella mancano le stringhe selezionate. Selezionare le stringhe per la compilazione dei prezzi.';
				|pl = 'Brak wydzielonych wierszy w tabeli. Zaznacz wiersze do wypełnienia cen.';
				|tr = 'Tabloda seçili satırlar mevcut değil. Fiyatları doldurmak için satırları seçin.'"),
			Object.Ref,
			"Object.ManufacturedProduct");
		Return;
		
	EndIf;
	
	RowsIDs = New Array;
	
	For Each RowID In SelectedRows Do
		
		CurrentRow = Object.ManufacturedProduct.FindByID(RowID);
		If Object.ReportOnOrders And CurrentRow.RowCode > 0 And Not VarianceFromSalesTermsAndConditions Then
			Continue;
		EndIf;
		
		RowsIDs.Add(RowID);
		
	EndDo;
	
	If RowsIDs.Count() = 0 Then
		
		ClearMessages();
		
		CommonClient.MessageToUser(
			NStr("vi = 'Giá không thể gán cho các dòng theo đơn hàng.';
				|ru = 'Цена не может быть назначена в строках по заказу.';
				|en = 'Price cannot be assigned in the order lines.'; fa = 'Price cannot be assigned in the order lines.';
				|it = 'Il prezzo non può essere impostato nelle righe per ordine.';
				|pl = 'Cena nie może być wyznaczona w wierszach wg zamówienia.';
				|tr = 'Fiyat, sipariş satırlarına girilemiyor.'"),
			Object.Ref,
			"Object.ManufacturedProduct");
		Return;
		
	EndIf;
		
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("RowsIDs", RowsIDs);
		
	PriceSelectionOptions = EnterprisePricesFillingClient.NewFillOptionsSelectPriceType();
	PriceSelectionOptions.PriceIncludesVAT                          = Object.PriceIncludesVAT;
	PriceSelectionOptions.UseWhileTransferringProductsToMaterialProvider = True;
	PriceSelectionOptions.CallbackDescription =
		New CallbackDescription("ManufacturedProductFillInPricesByPriceKindCompletion", ThisObject, AdditionalParameters);
	
	EnterprisePricesFillingClient.ChooseTypeOfPrices(PriceSelectionOptions);
	
EndProcedure

&AtClient
Procedure ManufacturedProductFillInPricesByPriceKindCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	PricesCalculated = ManufacturedProductFillInPricesByPriceKindServer(Result, AdditionalParameters.RowsIDs);
	SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, Result);
	
EndProcedure

&AtServer
Function ManufacturedProductFillInPricesByPriceKindServer(PriceKind, RowsIDs)
	
	CollectionOfSelectedRows = New Array;
	For Each RowID In RowsIDs Do
		CollectionOfSelectedRows.Add(Object.ManufacturedProduct.FindByID(RowID));
	EndDo;
	
	FillParameters = EnterprisePricesFillingServer.NewFillOptionsFillPrices();
	FillParameters.Date           = Object.Date;
	FillParameters.Currency         = Object.Currency;
	FillParameters.PriceKind        = PriceKind;
	FillParameters.Organization    = Object.Organization;
	FillParameters.PopulationFields = "Price, PriceKind";
	
	PricesCalculated = EnterprisePricesFillingServer.FillInPrices(
						Object.ManufacturedProduct,
						CollectionOfSelectedRows,
						FillParameters);
	
	If PricesCalculated Then
		
		ParametersForRecalculatingAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateAmount");
		StructureOfActions.Insert("RecalculateVATAmount",  ParametersForRecalculatingAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT", ParametersForRecalculatingAmount);
		StructureOfActions.Insert("ClearAmountOfSettlements");
		
		CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
		
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			CollectionOfSelectedRows,
			StructureOfActions,
			Object.ManufacturedProduct,
			CachedValues);
		
		CalculateTotals_(ThisObject);
		
	EndIf;
	
	Return PricesCalculated;
	
EndFunction

&AtClient
Procedure FillInTheWarehouse(Command)
	
	SelectedRows = Items.ManufacturedProduct.SelectedRows;
	
	RequiredFilling_ = WarehousesClient.CheckPossibilityOfFillingWarehousesInTablePart(
							Object, Object.ManufacturedProduct, NStr("vi = 'Sản phẩm';
																	|ru = 'Продукция';
																	|en = 'Manufactured products'; fa = 'محصولات تولیدی';
																	|it = 'Prodotti';
																	|pl = 'Produkcja';
																	|tr = 'İmal edilen ürünler'"), SelectedRows);
	
	If RequiredFilling_ Then
		
		FilterArray = New Array;
		FilterArray.Add(PredefinedValue("Enum.SelectWarehouseGroup.AllowInOrders"));
		FilterArray.Add(PredefinedValue("Enum.SelectWarehouseGroup.AllowInOrdersAndInvoices"));
		
		FilterStructure1 = New Structure;
		FilterStructure1.Insert("SelectGroup", FilterArray);
		FilterStructure1.Insert("IsFolder",   False);
		
		ParametersStructure = New Structure;
		ParametersStructure.Insert("Filter",         FilterStructure1);
		ParametersStructure.Insert("GroupOfWarehouses", Object.Warehouse);
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("SelectedRows", SelectedRows);
		
		CallbackDescription =
			New CallbackDescription("FillInTheWarehouseCompletion", ThisObject, AdditionalParameters);
		
		OpenForm(
			"Catalog.Warehouses.ChoiceForm",
			ParametersStructure,
			ThisObject,,,,
			CallbackDescription,
			FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInTheWarehouseCompletion(Result, AdditionalParameters) Export
	
	If Not ValueIsFilled(Result) Then
		Return;
	EndIf;
	
	SelectedRows = AdditionalParameters.SelectedRows;
	
	FilledWithRows = FillWarehouseOnServer(SelectedRows, Result);
	
	WarehousesClient.ShowNotificationAboutFillingOfWarehouseInTablePart(
		Result, FilledWithRows, SelectedRows.Count());
	
EndProcedure

&AtServer
Function FillWarehouseOnServer(SelectedRows, Warehouse)
	
	FilledWithRows = WarehousesServer.FillInWarehousesInSelectedLines(Object.ManufacturedProduct, SelectedRows, Warehouse);
	
	If FilledWithRows > 0 Then
		
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
		
		WhenChangingWarehouseInTablePartServer();
		
	EndIf;
	
	Return FilledWithRows;
	
EndFunction

&AtClient
Procedure FillInSenderDivision(Command)
	
	WarehousesClient.FillInDivisionInTablePart(
		Object,
		ThisObject,
		Object.ManufacturedProduct,
		"ManufacturedProduct",
		Items.ManufacturedProduct.SelectedRows,
		New CallbackDescription("FillInSenderDivisionCompletion", ThisObject));
	
EndProcedure

&AtClient
Procedure FillInSenderDivisionCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	SalesClient.ProcessingUnitSelection(Object.ManufacturedProduct, Items.ManufacturedProduct.SelectedRows, Result);
	
EndProcedure

&AtClient
Procedure FillInRecipient(Command)
	
	SelectedRows = Items.ManufacturedProduct.SelectedRows;
	
	If SelectedRows.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Trong danh sách ""Thành phẩm"" chưa nhập bất kỳ dòng nào.';
								|ru = 'В список ""Выпущенная продукция"" не введено ни одной строки.';
								|en = 'No lines are entered in the ""Released products"" list.'; fa = 'No lines are entered in the ""Released products"" list.';
								|it = 'Nell''elenco ""Prodotti emessi"" non è inserita alcuna stringa.';
								|pl = 'Do listy ""Wyprodukowana produkcja"" nie wprowadzono ani jednego wiersza.';
								|tr = '""Piyasaya sürülen imal edilen ürünler"" listesine hiçbir satır girilmemiştir.'"), 45);
		Return;
	EndIf;
	
	TSStrings = New Array;
	For Each RowID In SelectedRows Do
		
		CurrentRow = Object.ManufacturedProduct.FindByID(RowID);
		If Not CurrentRow.ToExpenseAs Then
			Continue;
		EndIf;
		
		TSStrings.Add(CurrentRow);
		
	EndDo;
	
	If TSStrings.Count() = 0 Then
		ShowMessageBox(
			,
			NStr("vi = 'Tại các dòng đã chọn trong danh sách ""Sản phẩm xuất xưởng"" không cần điền bộ phận-nơi nhận.';
				|ru = 'В выделенных строках списка ""Выпущенная продукция"" заполнение получателя не требуется.';
				|en = 'You do not need to fill the recipient in the selected lines of the ""Released products"" list.'; fa = 'You do not need to fill the recipient in the selected lines of the ""Released products"" list.';
				|it = 'Nelle stringhe selezionate dell''elenco ""Prodotti emessi"" non è richiesta la compilazione del destinatario.';
				|pl = 'W zaznaczonych wierszach listy ""Wyprodukowana produkcja"" wypełnienie działów-odbiorców nie jest wymagane.';
				|tr = '""Piyasaya sürülen imal edilen ürünler"" listesinin seçili satırlarında alıcı birimin doldurulmasına gerek yoktur.'"),
			45);
		Return;
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("TSStrings", TSStrings);
	
	OpenForm(
		"Catalog.BusinessStructure.ChoiceForm",,
		ThisObject,,,,
		New CallbackDescription("FillInRecipientCompletion", ThisObject, AdditionalParameters),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure FillInRecipientCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	TSStrings = AdditionalParameters.TSStrings;
	For Each TableRow In TSStrings Do
		TableRow.Recipient = Result;
	EndDo;
	
	ShowUserNotification(
		NStr("vi = 'Đã điền người nhận';
			|ru = 'Получатель заполнен';
			|en = 'Recipient is filled in'; fa = 'Recipient is filled in';
			|it = 'Il destinatario è compilato';
			|pl = 'Odbiorca wypełniony';
			|tr = 'Alıcı girildi'"),,
		NStr("vi = 'Đối với các dòng được chọn đã điền người nhận';
			|ru = 'Для выделенных строк выполнено заполнение получателя';
			|en = 'Recipients are filled in for the selected lines'; fa = 'Recipients are filled in for the selected lines';
			|it = 'Per le righe selezionata è stata eseguita la compilazione del destinatario';
			|pl = 'Dla wybranych wierszy wykonano wypełnienie odbiorcy';
			|tr = 'Seçili satırlar için alıcı dolduruldu'"),
		PictureLib.Information32);
	
EndProcedure

&AtClient
Procedure PrintDetails(Command)
	
	Try
		LockFormDataForEdit();
	Except
		ShowMessageBox(Undefined, BriefErrorDescription(ErrorInfo()));
		Return;
	EndTry;
	
	ParametersStructure = New Structure();
	ParametersStructure.Insert("Date",                      Object.Date);
	ParametersStructure.Insert("BusinessOperation",     Object.BusinessOperation);
	ParametersStructure.Insert("Organization",               Object.Organization);
	ParametersStructure.Insert("Partner",                   Object.Partner);
	ParametersStructure.Insert("Counterparty",                Object.Counterparty);
	ParametersStructure.Insert("Contract",                   Object.Contract);
	ParametersStructure.Insert("CounterpartyBankAccount", Object.CounterpartyBankAccount);
	ParametersStructure.Insert("CompanyBankAccount", Object.CompanyBankAccount);
	ParametersStructure.Insert("Basis",                 Object.Basis);
	ParametersStructure.Insert("ReferenceDocumentDateForPrintForms",             Object.ReferenceDocumentDateForPrintForms);
	ParametersStructure.Insert("BaseDocumentNumber",            Object.BaseDocumentNumber);
	ParametersStructure.Insert("OrderSales",       Object.ReportOnOrders);
	ParametersStructure.Insert("Director",              Object.Director);
	ParametersStructure.Insert("ChiefAccountant",          Object.ChiefAccountant);
	ParametersStructure.Insert("ReadOnly",            ReadOnly);
	ParametersStructure.Insert("ObjectType",                "ReportToMaterialProvider2_5");
	ParametersStructure.Insert("PrintBasisTable", PrintBasisTable);
	
	DoNotShowBankDetails = New Array;
	DoNotShowBankDetails.Add("DeliveryAddress");
	DoNotShowBankDetails.Add("ShipperBankAccount");
	DoNotShowBankDetails.Add("GoodsRecipientBankAccount");
	DoNotShowBankDetails.Add("Shipper");
	DoNotShowBankDetails.Add("GoodsRecipient");
	DoNotShowBankDetails.Add("LetterOfAuthorityIssuedBy");
	DoNotShowBankDetails.Add("PowerOfAttorneyDate");
	DoNotShowBankDetails.Add("PowerOfAttorneyPerson");
	DoNotShowBankDetails.Add("PowerOfAttorneyNumber");
	DoNotShowBankDetails.Add("IssuiedBy");
	DoNotShowBankDetails.Add("IssuiedByJobTitle");
	
	ParametersStructure.Insert("DoNotShowBankDetails", DoNotShowBankDetails);
	
	OpenForm("CommonForm.PrintingDetailsOfSales", ParametersStructure, ThisObject,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure Attachable_UpdateSBPPaymentStatus(Command)

	ClearMessages();
	CashClientLocalization.UpdateStatusOfSBPPaymentByDocument(ThisObject, Object.Ref);

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

// End StandardSubsystems.Properties

&AtServer
Procedure FillInSubordinatePropertiesForStatistics(ParentPropsName)
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, ParentPropsName);
EndProcedure

#Region FormSettingsItem

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	EnterprisePricesFillingServer.EstablishConditionalAppearanceOfPriceTypes(
		ThisObject, "ManufacturedProductPriceKind", "Object.ManufacturedProduct.PriceKind");
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductPriceKind.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductPackage.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("IsFullUser");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("VarianceFromSalesTermsAndConditions");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ManufacturedProduct.RowCode");
	ItemFilter.ComparisonType  = DataCompositionComparisonType.Filled;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductAmountARAP.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Currency");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("Object.ARAPCurrency");
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	// VAT rate
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductVATRate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("ManufacturedProductsProduced");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForSalesTaxation(
		ThisObject, "ManufacturedProductVATRate", "ManufacturedProductVATAmount", "ManufacturedProductAmountIncludingVAT");
	
	//
	
	EnterprisePricesFillingServer.SetConditionalAppearancePriceIncludesVAT(ThisObject, "ManufacturedProductAmountIncludingVAT");
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductPrice.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialProviderOrder");
	ItemFilter.ComparisonType  = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("VarianceFromSalesTermsAndConditions");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ManufacturedProduct.PriceKind");
	ItemFilter.ComparisonType  = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductSum.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("VarianceFromSalesTermsAndConditions");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialProviderOrder");
	ItemFilter.ComparisonType  = DataCompositionComparisonType.Filled;
	
	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ManufacturedProduct.PriceKind");
	ItemFilter.ComparisonType  = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(
		ThisObject, "ManufacturedProductCharacteristic", "Object.ManufacturedProduct.ItemVariantsAreUsed");
	
	//
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "ManufacturedProductProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.ManufacturedProduct.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);
	
	//
	
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(
		ThisObject,
		"SeriesIsAlwaysWHProducts",
		"ManufacturedProductSeries",
		"Object.ManufacturedProduct.BatchesIndicationStatus",
		"Object.ManufacturedProduct.ItemsType");
	
	//
	
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisObject, "ManufacturedProductPurpose", "Object.ManufacturedProduct.ItemsType", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductPurpose.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ManufacturedProduct.RowCode");
	ItemFilter.ComparisonType  = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductRowCode.Name);
	
	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialProviderOrder");
	ItemFilter.ComparisonType  = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ManufacturedProduct.RowCode");
	ItemFilter.ComparisonType  = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductMaterialProviderOrder.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductRowCode.Name);
	
	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.ReportOnOrders");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialProviderOrder");
	ItemFilter.ComparisonType  = DataCompositionComparisonType.Filled;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("UseReportToMaterialProviderBySeveralOrders2_5");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductMaterialProviderOrder.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ManufacturedProduct.MaterialProviderOrder");
	ItemFilter.ComparisonType  = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductMaterialProviderOrder.Name);
	
	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ManufacturedProduct.RowCode");
	ItemFilter.ComparisonType  = DataCompositionComparisonType.Filled;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Approved");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialProviderOrder");
	ItemFilter.ComparisonType  = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductMaterialProviderOrder.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialProviderOrder");
	ItemFilter.ComparisonType  = DataCompositionComparisonType.Filled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ManufacturedProduct.RowCode");
	ItemFilter.ComparisonType  = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	Item.Appearance.SetParameterValue("Text",      New DataCompositionField("Object.MaterialProviderOrder"));
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductMaterialProviderOrder.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.ReportOnOrders");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialProviderOrder");
	ItemFilter.ComparisonType  = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ManufacturedProduct.MaterialProviderOrder");
	ItemFilter.ComparisonType  = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ErrorNoteText);
	Item.Appearance.SetParameterValue("Text",      NStr("vi = 'Vượt quá trên đơn hàng, chưa chọn đơn hàng';
														|ru = 'Сверх заказа, заказ не выбран';
														|en = 'In excess of the order, the order is not selected'; fa = 'In excess of the order, the order is not selected';
														|it = 'Oltre all''ordine, l''ordine non è selezionato';
														|pl = 'Przewyższa zamówienie, zamówienie nie wybrane';
														|tr = 'Sipariş fazlası, sipariş seçilmedi'"));
	
	//
	
	WarehousesServer.SetConditionalAppearanceOfVTCHWarehouse(ThisObject, "ManufacturedProductWarehouse");
	
	//
	
	WarehousesServer.EstablishConditionalAppearanceOfVTCHDivision(ThisObject, "ManufacturedProduct");
	
	//
	
	ConditionalDesignParameters = WarehousesServer.ParametersOfConditionalAppearanceOfVHFWarehouseByItemType();
	ConditionalDesignParameters.Form = ThisObject;
	ConditionalDesignParameters.NameOfWarehouseInputField = Items.ManufacturedProductWarehouse.Name;
	ConditionalDesignParameters.NameOfItemTypeField = "Object.ManufacturedProduct.ItemsType";
	
	WarehousesServer.SetConditionalAppearanceOfVHFWarehouseByTypeOfItem(ConditionalDesignParameters);
	
	//
	
	ListOfProductTypes = New ValueList;
	ListOfProductTypes.LoadValues(ProductsClientServer.SelectionByProductMultiTurnContainer(False));
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductWarehouse.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.ManufacturedProduct.ItemsType");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = ListOfProductTypes;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ManufacturedProduct.Warehouse");
	ItemFilter.ComparisonType  = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductRecipient.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.ManufacturedProduct.ToExpenseAs");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ManufacturedProduct.Recipient");
	ItemFilter.ComparisonType  = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductRecipient.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.ManufacturedProduct.ToExpenseAs");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Text",          NStr("vi = '<khi ghi giảm vào chi phí>';
															|ru = '<при списании на расходы>';
															|en = '<when writing off as expenses>'; fa = '<when writing off as expenses>';
															|it = '<durante lo storno sulle spese>';
															|pl = '<przy wyksięgowaniu na rozchody>';
															|tr = '<gider yazılması>'"));
	Item.Appearance.SetParameterValue("TextColor",     StyleColors.InaccessibleCellTextColor);
	
	//
	
	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisObject);
	
EndProcedure

&AtServer
Procedure CustomizeFormElements()
	
	#Region BusinessOperation
	
	BusinessOperationSelectionList = Items.BusinessOperation.ChoiceList;
	BusinessOperationSelectionList.Clear();
	
	If Object.BusinessOperation = Enums.BusinessTransactions.ReportToMaterialProvider2_5 Then
		BusinessOperationSelectionList.Add(Enums.BusinessTransactions.ReportToMaterialProvider2_5, NStr("vi = 'Gia công (chung)';
																										|ru = 'Переработка (общее)';
																										|en = 'Subcontracting (general)'; fa = 'Subcontracting (general)';
																										|it = 'Subcontracting (general)';
																										|pl = 'Subcontracting (general)';
																										|tr = 'Geri dönüşüm (genel)'"));
	Else
		
		BusinessOperationSelectionList.Add(Enums.BusinessTransactions.Subcontracting2_5, NStr("vi = 'Gia công thành phẩm';
																								|ru = 'Переработка продукции';
																								|en = 'Product subcontracting'; fa = 'Product subcontracting';
																								|it = 'Product subcontracting';
																								|pl = 'Product subcontracting';
																								|tr = 'Ürün geri dönüşüm'"));
		BusinessOperationSelectionList.Add(Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5, NStr("vi = 'Thực hiện công việc';
																													|ru = 'Выполнение работ';
																													|en = 'Work performance'; fa = 'Work performance';
																													|it = 'Work performance';
																													|pl = 'Work performance';
																													|tr = 'İş tamamlama'"));
		
		SubsystemSettingsProduction = ProductionServerCached.SubsystemSettingsProduction();
		
		If SubsystemSettingsProduction.DynamicStructureOfProductionOrders Then
			BusinessOperationSelectionList.Add(Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5, NStr("vi = 'Sửa chữa';
																													|ru = 'Ремонт';
																													|en = 'R&M'; fa = 'تعمیر و نگهداری';
																													|it = 'R&M';
																													|pl = 'R&M';
																													|tr = 'Bakım-onarım'"));
		EndIf;
		
		If Not SubsystemSettingsProduction.DynamicStructureOfProductionOrders
			Or Object.BusinessOperation = Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5 Then
			BusinessOperationSelectionList.Add(Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5, NStr("vi = 'Sửa chữa thành phẩm';
																														|ru = 'Ремонт продукции';
																														|en = 'Product R&M'; fa = 'تعمیر و نگهداری محصول';
																														|it = 'Product R&M';
																														|pl = 'Product R&M';
																														|tr = 'Ürün bakım-onarım'"));
		EndIf;
		
	EndIf;
	
	Items.BusinessOperation.Visible = Not BusinessOperationSelectionList.Count() = 1;
	
	#EndRegion
	
	#Region OrderDocument
	
	Items.PagesOrder.Visible             = UseMaterialProviderOrder2_5;
	Items.PictureDiscrepancyOrder.Visible  = UseMaterialProviderOrder2_5;
	Items.PictureDiscrepancyOrders.Visible = UseMaterialProviderOrder2_5;
	
	Items.PictureDiscrepancyOrder.Picture   = PictureLib.AnEmptyPicture;
	Items.PictureDiscrepancyOrders.Picture  = PictureLib.AnEmptyPicture;
	
	#EndRegion
	
	#Region Department
	
	Items.ManufacturedProductDepartment.Visible = GetFunctionalOption("UseBusinessUnits");
	
	#EndRegion
	
EndProcedure

// Parameters:
// 	Form - ClientApplicationForm
// 	AttributesList - String
&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Items = Form.Items;
	Object   = Form.Object;
	
	AttributesList = New Structure(AttributesList);
	Initialize = Not ValueIsFilled(AttributesList);
	
	If Initialize
		Or AttributesList.Property("BusinessOperation") Then
		
		// Hint "Business of operation"
		Items.BusinessOperation.ToolTip    = Object.BusinessOperation;
		
		// Production of manufactured products
		Items.Content.Visible               = Form.ManufacturedProductsProduced;
		Items.VATRate.Visible                = Form.ManufacturedProductsProduced;
		
		Items.Warehouse.Visible                    = Form.ManufacturedProductsProduced And Form.UseSeveralWarehouses;
		Items.PictureMultipleWarehouses.Visible = Form.ManufacturedProductsProduced And Form.UseSeveralWarehouses;
		Items.SeveralWarehousesText.Visible  = Form.ManufacturedProductsProduced And Form.UseSeveralWarehouses;
		
		Items.ManufacturedProductPickUpReleasedProducts.Visible      = Form.ManufacturedProductsProduced;
		Items.ManufacturedProductFillInTheWarehouse.Visible                    = Form.ManufacturedProductsProduced And Form.UseSeveralWarehouses;
		Items.ManufacturedProductFillInSenderDivision.Visible = Form.WorksAreBeingCarriedOut;
		
		// Headings of the "Manufactured Products" page
		TitleManufacturingProducts = NStr("vi = 'Thành phẩm xuất xưởng';
											|ru = 'Выпускаемая продукция';
											|en = 'Released products'; fa = 'محصولات تولیدشده';
											|it = 'Prodotti in fabbricazione';
											|pl = 'Wypuszczana produkcja';
											|tr = 'İmal edilen ürünler'");
		HintManufacturedProducts = NStr("vi = 'Thành phẩm do bên nhận gia công chịu trách nhiệm sản xuất';
										|ru = 'Продукция, обязательства по выпуску которой берет на себя переработчик';
										|en = 'Products which will be released by the subcontractor'; fa = 'محصولاتی که توسط پیمانکار فرعی تولید خواهند شد';
										|it = 'Prodotti per la fabbricazione dei quali si impegna l''addetto alla lavorazione';
										|pl = 'Wiersze pozycji, zobowiązania w ramach wypuszczenia których bierze na siebie przetwórca';
										|tr = 'Fason üreticinin üretmekle yükümlü olduğu imal edilen ürünler'");
		
		If Not Form.ManufacturedProductsProduced
			And Form.WorksAreBeingCarriedOut Then
			TitleManufacturingProducts = NStr("vi = 'Công việc được thực hiện';
												|ru = 'Выполняемые работы';
												|en = 'Works to perform'; fa = 'کارهای قابل انجام';
												|it = 'Works to perform';
												|pl = 'Works to perform';
												|tr = 'Yapılan işler'");
			HintManufacturedProducts = NStr("vi = 'Thực hiện công việc có sử dụng nguyên liệu gia công';
											|ru = 'Работы, выполняемые с использованием давальческого сырья';
											|en = 'Works performed using provided materials'; fa = 'Works performed using provided materials';
											|it = 'Works performed using provided materials';
											|pl = 'Works performed using provided materials';
											|tr = 'Sağlayıcı hammaddeleri kullanarak yapılan çalışmalar'");
		EndIf;
		
		Items.ProductsPage.Title = TitleManufacturingProducts;
		Items.ProductsPage.ToolTip = HintManufacturedProducts;
		
		// Title "Pick up products"
		TitlePickUpGoods = NStr("vi = 'Chọn mặt hàng';
								|ru = 'Подобрать товары';
								|en = 'Pick goods'; fa = 'انتخاب کالاها';
								|it = 'Selezionare la merce';
								|pl = 'Dobierz wiersze pozycji';
								|tr = 'Ürünleri seç'");
		If Not Form.ManufacturedProductsProduced
			And Form.WorksAreBeingCarriedOut Then
			TitlePickUpGoods = NStr("vi = 'Chọn công việc';
									|ru = 'Подобрать работы';
									|en = 'Pick works'; fa = 'Pick works';
									|it = 'Pick works';
									|pl = 'Pick works';
									|tr = 'İşleri seç'");
		EndIf;
		Items.ManufacturedProductSelectGoods.Title = TitlePickUpGoods;
		
		// Item of Manufactured products
		ParametersForSelectingManufacturedProducts = New Array;
		
		ItemsTypes = New Array;
		If Form.ManufacturedProductsProduced Then
			ItemsTypes.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
			ItemsTypes.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
		EndIf;
		If Form.WorksAreBeingCarriedOut Then
			ItemsTypes.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
		EndIf;
		
		NewChoiceParameter = New ChoiceParameter("Filter.ItemsType", New FixedArray(ItemsTypes));
		
		ParametersForSelectingManufacturedProducts.Add(NewChoiceParameter);
		
		Items.ManufacturedProductProducts.ChoiceParameters = New FixedArray(ParametersForSelectingManufacturedProducts);
		
	EndIf;
	
	If Initialize
		Or AttributesList.Property("Warehouse") Then
		
		Items.ManufacturedProductFillInTheWarehouse.Enabled = Form.WarehouseGroup_;
		
		If Not Form.WarehouseGroup_ Then
			Items.ProductsSenderGroup.Title = NStr("vi = 'Bộ phận gửi';
													|ru = 'Подразделение-отправитель';
													|en = 'Shipping business unit'; fa = 'واحد تجاری ارسال‌کننده';
													|it = 'Reparto-mittente';
													|pl = 'Shipping business unit';
													|tr = 'Gönderen departman'");
		Else
			Items.ProductsSenderGroup.Title = NStr("vi = 'Người gửi';
													|ru = 'Отправитель';
													|en = 'Sender'; fa = 'فرستنده';
													|it = 'Mittente';
													|pl = 'Sender';
													|tr = 'Gönderen'");
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region OnChangeAttributes

&AtServer
Procedure WhenChangingReportForMultipleOrders()
	
	If Object.ReportOnOrders Then
		
		If Object.ManufacturedProduct.Count() = 0 Then
			FillInFromOrderServer();
		Else
			LinkRowsToOrders(Not UseReportToMaterialProviderBySeveralOrders2_5);
		EndIf;
		
	Else
		
		UnlinkFromOrderServer(True, False);
		Object.MaterialProviderOrder = Undefined;
		OrderList.Clear();
		
	EndIf;
	
	SetAvailabilityOfItemsByStatusServer();
	UpdateOrderInformation();
	
	CalculateTotals_(ThisObject);
	UpdateOrderDeviations();
	UpdateDependentDetailsOfServerByOrderForm();
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisObject);
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "ReportOnOrders");
	
EndProcedure

&AtServer
Procedure WhenChangingVATRateServer()
	
	For Each CurrentData In Object.ManufacturedProduct Do
		CurrentData.VATRate = Object.VATRate;
	EndDo;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartServer.TreatTS(Object.ManufacturedProduct, StructureOfActions, CachedValues);
	
	SaveDetailsValuesBeforeChanging(ThisObject);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtServer
Procedure WhenChangingDateServer(RecalculatePrices_, PricesCalculated)
	
	UpdateVATTaxation_();
	FillInVATRateOnServer();
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Date");
	
EndProcedure

&AtServer
Procedure WhenChangingWarehouseServer(ClearLines_ = True, UntieAllLinesFromOrder = False)
	
	FillInDependentServiceAttributes("Warehouse");
	
	ConfigureDependentFormElements(ThisObject, "Warehouse");
	
	SetParametersForSelectingManufacturedProductsWarehouse();
	
	If Object.ReportOnOrders Then
		If Not WarehouseGroup_ And Object.ManufacturedProduct.Count() > 0 And ClearLines_ Then
			Object.ManufacturedProduct.Clear();
		EndIf;
	Else
		WarehousesServer.FillInWarehousesInTablePart(Object.Warehouse, WarehouseGroup_, Object.ManufacturedProduct, True);
	EndIf;
	
	If UntieAllLinesFromOrder Then
		UnlinkFromOrderServer();
		WarehousesServer.FillInWarehousesInTablePart(Object.Warehouse, WarehouseGroup_, Object.ManufacturedProduct, True);
	EndIf;
	
	WhenChangingWarehouseInTablePartServer();
	
	UpdateOrderInformation();
	CalculateTotals_(ThisObject);
	
	ARAPAccountingClientServer.UpdateHyperlinkText(ThisObject);
	
	SeriesSpecificationParameters =
		New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.ReportToMaterialProvider2_5));
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	Items.ManufacturedProductSeries.Visible = SeriesSpecificationParameters.UseItemsBatch;
	
	UpdateVATTaxation_();
	
EndProcedure

&AtServer
Procedure WhenChangingPartnerServer()
	
	Counterparty = Object.Counterparty;
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Partner, Object.Counterparty);
	
	If Counterparty <> Object.Counterparty Then
		Object.CounterpartyBankAccount = GetDefaultCounterpartyBankAccountServer(Object.Counterparty);
	EndIf;
	
	FillInDefaultContract();
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Partner");
	
	SetAvailabilityOfItemsByStatusServer();
	
	FillBaseForPrinting();
	
	FillInServiceDetailsOfTableParts();
	
	SetVisibilityOfElementsByTaxationServer();
	
	ResponsiblePersonsServer.FillInManager_(Object);
	
	FillInSubordinatePropertiesForStatistics("Counterparty");
	
	UpdateInvoiceText();
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness,, Object.Contract);
	EndIf;
	
	PurposeOfContract = GetContractAssignment(Object);
	
EndProcedure

&AtServer
Procedure WhenChangingContactPersonServer()
	
	OwnerOfContactPerson = Common.ObjectAttributeValue(Object.ContactPerson, "Owner");
	If OwnerOfContactPerson <> Object.Partner Then
		Object.Partner = OwnerOfContactPerson;
		WhenChangingPartnerServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure DocumentAmountOnChangeServer(DocumentAmount)
	
	RecalculationParameters = PriceManagementSystem.ParametersForRecalculationOfTableAmountsONChangeOfExchangeRate(Object.PriceIncludesVAT, DocumentAmount);
	
	PriceManagementSystem.RecalculateTableAmountsONChangeOfExchangeRate(Object.ManufacturedProduct, RecalculationParameters);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtServer
Procedure WhenChangingCounterpartyServer()
	
	FillInDefaultContract();
	
	If ValueIsFilled(Object.Counterparty)
	   And Not ValueIsFilled(Object.CounterpartyBankAccount) Then
		Object.CounterpartyBankAccount = GetDefaultCounterpartyBankAccountServer(Object.Counterparty);
	EndIf;
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness,, Object.Contract);
	EndIf;
	
	PurposeOfContract = GetContractAssignment(Object);
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Counterparty");
	
	UpdateVATTaxation_();
	UpdateInvoiceText();
	
	FillInSubordinatePropertiesForStatistics("Counterparty");
	
EndProcedure

&AtServer
Procedure WhenChangingAgreementServer()
	
	ForeignCurrencyTransaction = Object.ForeignCurrencyTransaction;
	
	CancelCompletedProductSelection();
	
	Object.Department = Common.ObjectAttributeValue(Object.Contract, "Department");
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Contract");
	
	UpdateVATTaxation_();
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness,, Object.Contract);
	EndIf;
	
	If ForeignCurrencyTransaction <> Object.ForeignCurrencyTransaction Then
		Object.CompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
	EndIf;
	
	SalesServer.FillInBankAccountsUnderAgreement(
		Object.Contract, Object.CompanyBankAccount, Object.CounterpartyBankAccount);
	
	If Not ValueIsFilled(Object.CompanyBankAccount) Then
		ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Object.Organization);
		ParametersOfAccount.LineOfBusiness = Object.LineOfBusiness;
		ParametersOfAccount.ExcludeCurrencyAccounts = Object.ForeignCurrencyTransaction;
		ParametersOfAccount.Currency = LocalAccountingCurrency;
		Object.CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(
			ParametersOfAccount);
	EndIf;
	
	ResponsiblePersonsServer.FillInManager_(Object);
	
	PurposeOfContract = GetContractAssignment(Object);
	
	FillInSubordinatePropertiesForStatistics("Contract");
	
	FillBaseForPrinting();
	
	SaveDetailsValuesBeforeChanging(ThisObject);
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	If Not QuestionResult = DialogReturnCode.Yes Then
		Object.BusinessOperation = AttributesValuesBeforeChange.BusinessOperation;
		Return;
	EndIf;
	
	BusinessOperationWhenChangingOnServer();
	
EndProcedure

&AtServer
Procedure BusinessOperationWhenChangingOnServer()
	
	// Clearing fields that are insignificant of operation
	Object.ProcessingService = Undefined;
	Object.VATRate           = Undefined;
	
	FillInDependentServiceAttributes("BusinessOperation");
	
	// We will delete the lines of manufactured products that do not match the type of item.
	If ManufacturedProductsProduced
			And Not WorksAreBeingCarriedOut
		Or Not ManufacturedProductsProduced
			And WorksAreBeingCarriedOut Then
		
		If Not Object.ManufacturedProduct.Count() = 0 Then
			
			ItemsTypes =
				Common.ObjectsAttributeValue(
					Object.ManufacturedProduct.Unload(, "Products").UnloadColumn("Products"),
					"ItemsType");
			
			LinesToDelete = New Array;
			For Each CurrentData In Object.ManufacturedProduct Do
				If ManufacturedProductsProduced
						And ItemsTypes[CurrentData.Products] = Enums.ItemsTypes.Work_5
					Or WorksAreBeingCarriedOut
						And Not ItemsTypes[CurrentData.Products] = Enums.ItemsTypes.Work_5 Then
					LinesToDelete.Add(CurrentData);
				EndIf;
			EndDo;
			
			For Each CurrentData In LinesToDelete Do
				Object.ManufacturedProduct.Delete(CurrentData);
			EndDo;
			
		EndIf;
		
		Object.Warehouse = Undefined;
		WhenChangingWarehouseServer("ManufacturedProduct");
		
	EndIf;
	
	FillInVATRateOnServer();
	
	// Let's process the dependencies.
	ConfigureDependentFormElements(ThisObject, "BusinessOperation");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure WhenOrganizationChangesServer()
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	If ValueIsFilled(Object.Organization) Then
		
		FillInDefaultContract();
		
		If UseLinesOfBusiness Then
			
			LinesOfBusinessServer.FillInDefaultDirection(
				Object.LineOfBusiness,, Object.Contract);
			
		EndIf;
		
		PurposeOfContract = GetContractAssignment(Object);
		
	EndIf;
	
	CashServer.CheckFillInOrganizationSBankAccountByOwner(
		Object.Organization, Object.CompanyBankAccount,, Object.LineOfBusiness, Object.ForeignCurrencyTransaction);
	
	CashServer.CheckOrganizationSSalesRegisterByOwner(
		Object.Organization, Object.CashAccount, Object.PaymentMethod, Object.LineOfBusiness);
	
	FillInSubordinatePropertiesForStatistics("Organization");
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Organization");
	
	UpdateVATTaxation_();
	WhenChangingVATTaxationServer(Undefined);
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
EndProcedure

&AtServer
Procedure WhenChangingVATTaxationServer(CachedValues)
	
	FillInVATRateOnServer();
	
	SetVisibilityOfElementsByTaxationServer();
	UpdateInvoiceText();
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtServer
Procedure OnChangePriceIncludesVATServer(CachedValues)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartServer.TreatTS(Object.ManufacturedProduct, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisObject);
	
	PriceTypeSelectionParameters = SettingsValueCached.ParametersForSelectingDefaultPriceType();
	PriceTypeSelectionParameters.PriceIncludesVAT                          = Object.PriceIncludesVAT;
	PriceTypeSelectionParameters.UseWhileTransferringProductsToMaterialProvider = True;
	PriceTypeSelectionParameters.Status                                   = Enums.StatusesOfPriceTypeValidity.Valid;
	
	DefaultPriceType = SettingsValueCached.DefaultPriceType(PriceTypeSelectionParameters);
	
EndProcedure

&AtServer
Procedure LineOfBusinessOnChangeServer()
	
	PurposeOfContract = GetContractAssignment(Object);
	
	UpdateVATTaxation_();
	
EndProcedure

&AtClient
Procedure ContractOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.No Then
		FillPropertyValues(Object, AttributesValuesBeforeChange, "Contract");
		Return;
	EndIf;
	
	WhenChangingAgreementServer();
	
EndProcedure

&AtServer
Procedure ManufacturedProductAfterDeleteRowServer(SeriesStatusesNeedToBeUpdated, CachedValues)

	If SeriesStatusesNeedToBeUpdated Then
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Undefined, CachedValues);
	EndIf;

	FormEvents.WhenChangingElement(ThisObject, "ManufacturedProduct");
	
	UpdateOrderInformation();
	
	WhenChangingWarehouseInTablePartServer();

EndProcedure

&AtServer
Procedure WhenChangingWarehouseInTablePartServer()
	
	WarehousesServer.WhenChangingWarehouseInTablePart(Object.ManufacturedProduct, WarehouseTable, WarehouseGroup_, False);
	
	TotalWarehouses_ = WarehouseTable.Count();
	WarehousesClientServer.UpdateWarehouseGroupImage(
		SeveralWarehousesText, Items.PictureMultipleWarehouses, TotalWarehouses_);
	
	UpdateDependentDetailsOfServerByOrderForm();
	
EndProcedure

&AtClientAtServerNoContext
Procedure SaveDetailsValuesBeforeChanging(Form)
	
	AttributesToSave = "Contract, VATRate, Warehouse, BusinessOperation";
	AttributesValuesBeforeChange = New Structure(AttributesToSave);
	FillPropertyValues(AttributesValuesBeforeChange, Form.Object);
	
	Form.AttributesValuesBeforeChange = AttributesValuesBeforeChange;
	
EndProcedure	

#EndRegion

#Region SelectionAndProcessingOfQuantityVerification

&AtServer
Procedure ChoiceProcessingProductSelection(ValueSelected)
	
	ProductTable = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	If ProductTable.Count() = 0 Then
		Return;
	EndIf;
	
	CurOrderOfGiver =
		?(Object.ReportOnOrders And ValueIsFilled(Object.MaterialProviderOrder), Object.MaterialProviderOrder, Undefined);
	
	If ValueIsFilled(CurOrderOfGiver) Then
		CurAssignment = GeneralPurposeTMServerCall.ObjectAttributeValue(CurOrderOfGiver, "Purpose");
	Else
		CurAssignment = PurposeOfContract;
	EndIf;
	
	VATRateIsIndicatedInTablePart = VATRateIsIndicatedInTablePart(Object.BusinessOperation);
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	AddActionsClearFillArticleAnalytics(StructureOfActions, ThisObject);
	If VATRateIsIndicatedInTablePart Then
		AddActionToStructureFillInVATRate(Object, StructureOfActions);
	EndIf;
	
	ParametersForFillingInPriceType = BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceTypeInTSLine("PriceKind");
	ParametersForFillingInPriceType.DefaultPriceType = DefaultPriceType;
	ParametersForFillingInPriceType.FilterParameters.PriceIncludesVAT = Object.PriceIncludesVAT;
	ParametersForFillingInPriceType.FilterParameters.UseWhileTransferringProductsToMaterialProvider = True;
	StructureOfActions.Insert("CheckFillInPriceView", ParametersForFillingInPriceType);
	
	GLAccountSettingsClientServer.InsertActionFillPresentationAccountSettingsAccounting(
		StructureOfActions, ThisObject, "Object.ManufacturedProduct");
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array();
	
	For Each TableRow In ProductTable Do
		
		LineTSProducts = Object.ManufacturedProduct.Add();
		
		FillPropertyValues(LineTSProducts, TableRow);
		LineTSProducts.MaterialProviderOrder = CurOrderOfGiver;
		LineTSProducts.Purpose    = CurAssignment;
		If Not VATRateIsIndicatedInTablePart Then
			LineTSProducts.VATRate = Object.VATRate;
		EndIf;
		
		RowsToProcess.Add(LineTSProducts);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.ManufacturedProduct,
		CachedValues);

	FillInServiceDetailsOfTableParts();
	
	WhenChangingWarehouseInTablePartServer();
	
	SetAvailabilityOfItemsByStatusServer();
	UpdateOrderInformation();
	
	CalculateTotals_(ThisObject);
	UpdateOrderDeviations();
	UpdateDependentDetailsOfServerByOrderForm();
	
	SeriesSpecificationParameters = 
		New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.ReportToMaterialProvider2_5));
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisObject);
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "ReportOnOrders");
	
EndProcedure

&AtServer
Procedure GetManufacturedProductsFromStorage(ValueSelected)
	
	ProductTable = GetFromTempStorage(ValueSelected.AddressInStorage);
	If ProductTable.Count() = 0 Then
		Return;
	EndIf;
	
	If Not Object.ReportOnOrders Then
		Object.ReportOnOrders = True;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("ClearAmountOfSettlements");
	GLAccountSettingsClientServer.InsertActionFillPresentationAccountSettingsAccounting(StructureOfActions, ThisObject, "Object.ManufacturedProduct");
	
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("MaterialProviderOrder");
	TheStructureOfTheSearch.Insert("Products");
	TheStructureOfTheSearch.Insert("Characteristic");
	TheStructureOfTheSearch.Insert("Series");
	TheStructureOfTheSearch.Insert("BatchesIndicationStatus");
	TheStructureOfTheSearch.Insert("Warehouse");
	TheStructureOfTheSearch.Insert("Department");
	TheStructureOfTheSearch.Insert("ToExpenseAs");
	TheStructureOfTheSearch.Insert("ExpenseItem");
	TheStructureOfTheSearch.Insert("DimensionOfExpenses");
	TheStructureOfTheSearch.Insert("AssetsLiabilitiesDimension");
	TheStructureOfTheSearch.Insert("Recipient");
	
	RowsToProcess = New Array;
	
	For Each TableRow In ProductTable Do
		
		FillPropertyValues(TheStructureOfTheSearch, TableRow);
		
		RowsArray     = Object.ManufacturedProduct.FindRows(TheStructureOfTheSearch);
		RowsCount = RowsArray.Count();
		
		If RowsCount = 0 Then
			
			LineTSProducts = Object.ManufacturedProduct.Add();
			
		ElsIf RowsCount = 1 Then
			
			LineTSProducts = RowsArray[0];
			
		ElsIf RowsCount > 1 Then
			
			For Each RowToDelete In RowsArray Do
				Object.ManufacturedProduct.Delete(RowToDelete);
			EndDo;
			
			LineTSProducts = Object.ManufacturedProduct.Add();
			
		EndIf;
		
		FillPropertyValues(LineTSProducts, TableRow);
		
		RowsToProcess.Add(LineTSProducts);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.ManufacturedProduct);
	
	FillInServiceDetailsOfTableParts();
	
	WhenChangingWarehouseInTablePartServer();
	
	SetAvailabilityOfItemsByStatusServer();
	UpdateOrderInformation();
	
	CalculateTotals_(ThisObject);
	UpdateOrderDeviations();
	UpdateDependentDetailsOfServerByOrderForm();
	
	SeriesSpecificationParameters = 
		New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.ReportToMaterialProvider2_5));
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisObject);
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "ReportOnOrders");
	
EndProcedure

&AtServer
Procedure SelectionProcessingSelectionOfManufacturedProducts(ValueSelected)
	
	ProductTable = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	If ProductTable.Count() = 0 Then
		Return;
	EndIf;
	
	Object.Approved = False;
	
	CurOrderOfGiver =
		?(Object.ReportOnOrders And ValueIsFilled(Object.MaterialProviderOrder), Object.MaterialProviderOrder, Undefined);
	
	VATRateIsIndicatedInTablePart = VATRateIsIndicatedInTablePart(Object.BusinessOperation);
	
	RowsToProcess = New Array;
	ProcessedNewLines = New Array;
	
	For Each RowOfProduct In ProductTable Do
		
		ProductsSearch = New Structure();
		ProductsSearch.Insert("Products", RowOfProduct.Products);
		ProductsSearch.Insert("Characteristic", RowOfProduct.Characteristic);
		ProductsSearch.Insert("Purpose", RowOfProduct.Purpose);
		If Not RowOfProduct.DifferentSeriesAccounting Then
			ProductsSearch.Insert("Series", RowOfProduct.Series);
		EndIf;
		ProductsSearch.Insert("Warehouse", RowOfProduct.StorageLocation);
		ProductLines_2 = Object.ManufacturedProduct.FindRows(ProductsSearch);
		
		If ProductLines_2.Count() = 0 Then
			
			CurrentRow = Object.ManufacturedProduct.Add();
			FillPropertyValues(CurrentRow, RowOfProduct);
			CurrentRow.Count = RowOfProduct.QuantityIsSelected;
			CurrentRow.MaterialProviderOrder = CurOrderOfGiver;
			CurrentRow.Warehouse = RowOfProduct.StorageLocation;
			ProcessedNewLines.Add(CurrentRow);
			
		ElsIf ProductLines_2.Count() = 1 Then
			
			CurrentRow = ProductLines_2[0];
			RowsToProcess.Add(CurrentRow);
			
		ElsIf ProductLines_2.Count() > 1 Then
			
			For Each RowToDelete In ProductLines_2 Do
				Object.ManufacturedProduct.Delete(RowToDelete);
			EndDo;
			
			CurrentRow = Object.ManufacturedProduct.Add();
			FillPropertyValues(CurrentRow, RowOfProduct);
			CurrentRow.Count = RowOfProduct.QuantityIsSelected;
			CurrentRow.MaterialProviderOrder = CurOrderOfGiver;
			CurrentRow.Warehouse = RowOfProduct.StorageLocation;
			ProcessedNewLines.Add(CurrentRow);
			
		EndIf;
		
		CurrentRow.Count = RowOfProduct.QuantityIsSelected;
		
		If Not VATRateIsIndicatedInTablePart Then
			CurrentRow.VATRate = Object.VATRate;
		EndIf;
		
	EndDo;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	PriceFillingStructure = BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	
	ParametersForFillingInPriceType = BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceTypeInTSLine("PriceKind");
	ParametersForFillingInPriceType.DefaultPriceType = DefaultPriceType;
	ParametersForFillingInPriceType.FilterParameters.PriceIncludesVAT = Object.PriceIncludesVAT;
	ParametersForFillingInPriceType.FilterParameters.UseWhileTransferringProductsToMaterialProvider = True;
	StructureOfActions.Insert("CheckFillInPriceView", ParametersForFillingInPriceType);
	
	StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	AddActionsClearFillArticleAnalytics(StructureOfActions, ThisObject);
	
	If VATRateIsIndicatedInTablePart Then
		AddActionToStructureFillInVATRate(Object, StructureOfActions);
	EndIf;
	
	GLAccountSettingsClientServer.InsertActionFillPresentationAccountSettingsAccounting(
		StructureOfActions, ThisObject, "Object.ManufacturedProduct");
	
	StructureOfActionsForNewLines = New Structure(New FixedStructure(StructureOfActions));
	StructureOfActionsForNewLines.Insert("FillInPriceView", New Structure("PriceKind", DefaultPriceType));
	StructureOfActionsForNewLines.Insert("FillInSalePrice", PriceFillingStructure);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.ManufacturedProduct,
		CachedValues);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ProcessedNewLines,
		StructureOfActionsForNewLines,
		Object.ManufacturedProduct,
		CachedValues);
	
	FillInServiceDetailsOfTableParts();
	
	WhenChangingWarehouseInTablePartServer();
	
	SetAvailabilityOfItemsByStatusServer();
	UpdateOrderInformation();
	
	CalculateTotals_(ThisObject);
	UpdateOrderDeviations();
	UpdateDependentDetailsOfServerByOrderForm();
	
	SeriesSpecificationParameters = 
		New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.ReportToMaterialProvider2_5));
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisObject);
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "ReportOnOrders");
	
EndProcedure

&AtServer
Function PlaceGoodsInStorageForSelectionOfAcceptedGoods()
	
	Columns = "LineNumber, Products, Characteristic, Purpose, Series, BatchesIndicationStatus, Warehouse, Count";
	
	Result = Object.ManufacturedProduct.Unload(, Columns);
	
	Result.Columns.Warehouse.Name = "StorageLocation";
	
	Address = PutToTempStorage(Result, UUID);
	
	Return Address;
	
EndFunction

&AtServer
Procedure CancelCompletedProductSelection()
	
	If Object.ManufacturedProduct.Count() > 0 Then
		Object.ManufacturedProduct.Clear();
	EndIf;
	
	If ValueIsFilled(Object.MaterialProviderOrder) Then
		Object.MaterialProviderOrder = Undefined;
	EndIf;
	
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
	AddToStructureActionsToUpdateVspAttributesOfLine(StructureOfActionsWithAddedStrings);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithAddedStrings, Object);
	AddActionsClearFillArticleAnalytics(StructureOfActionsWithAddedStrings, ThisObject);
	
	StructureOfActionsWithAddedStrings.Insert(
		"CheckFillWarehouse",
		BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	StructureOfActionsWithAddedStrings.Insert(
		"CheckSeriesCalculateStatus",
		New Structure("Warehouse, SeriesSpecificationParameters", Undefined, SeriesSpecificationParameters));
	
	StructureOfActionsWithAddedStrings.Insert("CheckFillAssignment", PurposeOfContract);
	
	ParametersForFillingInPriceType = BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceTypeInTSLine("PriceKind");
	ParametersForFillingInPriceType.DefaultPriceType = DefaultPriceType;
	ParametersForFillingInPriceType.FilterParameters.PriceIncludesVAT = Object.PriceIncludesVAT;
	ParametersForFillingInPriceType.FilterParameters.UseWhileTransferringProductsToMaterialProvider = True;
	StructureOfActionsWithAddedStrings.Insert("CheckFillInPriceView", ParametersForFillingInPriceType);
	
	StructureOfActionsWithAddedStrings.Insert(
		"FillInSalePrice",
		BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	
	If VATRateIsIndicatedInTablePart(Object.BusinessOperation) Then
		AddActionToStructureFillInVATRate(Object, StructureOfActionsWithAddedStrings);
	EndIf;
	
	StructureOfActionsWithModifiedStrings  = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithModifiedStrings, Object);
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.Barcodes								 = BarcodeData_5;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings	 = StructureOfActionsWithModifiedStrings;
	StructureOfActions.SeriesSpecificationParameters				 = SeriesSpecificationParameters;
	StructureOfActions.TSName									 = "ManufacturedProduct";
	StructureOfActions.GoodsOnly							 = ManufacturedProductsProduced And Not WorksAreBeingCarriedOut;
	StructureOfActions.OnlyWorks							 = Not ManufacturedProductsProduced And WorksAreBeingCarriedOut;
	StructureOfActions.OnlyGoodsAndWork					 = ManufacturedProductsProduced And WorksAreBeingCarriedOut;
	
	ProcessBarcodesServer(StructureOfActions, CachedValues);
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(StructureOfActions, CachedValues, ThisObject);
	
	If BarcodingOfItemsClient.YouNeedToOpenFormForSpecifyingSeriesAfterProcessingBarcodes(StructureOfActions) Then
		CurDataId = StructureOfActions.ArrayOfRowsWithSeries_[0];
		
		AttachIdleHandler("OpenSeriesSelectionWhenScanningProductBarCode", 0.1, True);
	EndIf;
	
	CalculateTotals_(ThisObject);
	
	If StructureOfActions.CurrentRow <> Undefined Then
		Items.ManufacturedProduct.CurrentRow = StructureOfActions.CurrentRow;
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessBarcodesServer(StructureOfActionParameters, CachedValues)
	
	BarcodingOfItemsServer.ProcessBarcodes(
		ThisObject,
		Object,
		StructureOfActionParameters,
		CachedValues);
		
	UpdateOrderDeviations();
	
	WhenChangingWarehouseInTablePartServer();
	
EndProcedure

#EndRegion

#Region SetOfSeries

&AtClient
Procedure OpenSelectionOfSeries(Text = "", CurrentData = Undefined)
	
	NeedServerCall = ProductsClient.YouNeedServerCallToSpecifySeries(
							ThisObject, SeriesSpecificationParameters, Text, CurrentData);
	
	If NeedServerCall Then
		
		If CurrentData = Undefined Then
			RowID = Items.ManufacturedProduct.CurrentData.GetID();
		Else
			RowID = CurrentData.GetID();
		EndIf;
		
		ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm(RowID);
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("ParametersOfSeriesIndicationForm", ParametersOfSeriesIndicationForm);
		
		CallbackDescription =
			New CallbackDescription("OpenSelectionOfSeriesCompletion", ThisObject, AdditionalParameters);
		
		OpenForm(
			ParametersOfSeriesIndicationForm.FormName, ParametersOfSeriesIndicationForm, ThisObject,,,, CallbackDescription);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenSeriesSelectionWhenScanningProductBarCode()

	If CurDataId = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.ManufacturedProduct.FindByID(CurDataId);
	OpenSelectionOfSeries(, CurrentData);

EndProcedure

&AtServer
Function ParametersOfSeriesIndicationForm(RowID)
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(
				Object, SeriesSpecificationParameters, RowID, ThisObject);
	
EndFunction

&AtClient
Procedure OpenSelectionOfSeriesCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	ProcessIndicationOfSeriesOnServer(AdditionalParameters.ParametersOfSeriesIndicationForm);
	
EndProcedure

&AtServer
Procedure ProcessIndicationOfSeriesOnServer(ParametersOfSeriesIndicationForm)
	
	ProductsServer.ProcessSeriesIndication_(
		Object, SeriesSpecificationParameters, ParametersOfSeriesIndicationForm, New Structure);
	
EndProcedure

&AtServer
Procedure FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(RowID, CachedValues)
	
	ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(
		Object, SeriesSpecificationParameters, RowID, CachedValues);
	
EndProcedure

#EndRegion

#Region Assignments

&AtServerNoContext
Function GetContractAssignment(Object)
	
	If ValueIsFilled(Object.Contract) Then
		
		DestinationPattern   = Documents.ReportToMaterialProvider2_5.DestinationPattern(Object);
		PurposeOfContract = Catalogs.Assignments.FindByTemplate(DestinationPattern);
		
	Else
		
		PurposeOfContract = Catalogs.Assignments.EmptyRef();
		
	EndIf;
	
	Return PurposeOfContract;
	
EndFunction

#EndRegion

#Region EAEUExports

&AtClient
Procedure TextURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	Return;
	
EndProcedure

&AtServer
Procedure UpdateTextsDocumentsBasedOn(TextsDocumentsBasedOn, InvoicesIssuedOnBasisOf)
	
	Return;
	
EndProcedure

#EndRegion

#Region Other

&AtClientAtServerNoContext
Procedure AddToStructureActionsToUpdateVspAttributesOfLine(StructureOfActions)
	
	StructureCharacteristics  = New Structure("Products", "ItemVariantsAreUsed");
	StructureTypeOfProduct = New Structure("Products", "ItemsType");
	StructureArticle         = New Structure("Products", "SKU");
	
	StructureOfActions.Insert("FillInFeatureAttribute", StructureCharacteristics);
	StructureOfActions.Insert("FillInProductTypeAttribute_",            StructureTypeOfProduct);
	StructureOfActions.Insert("FillInArticleAttribute",                    StructureArticle);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionToStructureFillInVATRate(Object, StructureOfActions)
	
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object, True));
	
EndProcedure

&AtClientAtServerNoContext
Function VATRateIsIndicatedInTablePart(BusinessOperation)
	
	Return
		BusinessOperation =
				PredefinedValue("Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5")
		Or BusinessOperation =
				PredefinedValue("Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5");
	
EndFunction

&AtServer
Procedure FillInVATRateOnServer()
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActions = New Structure;
	AddActionToStructureFillInVATRate(Object, StructureOfActions);
	
	If Not VATRateIsIndicatedInTablePart(Object.BusinessOperation) Then
		
		BatchProcessingOfTablePartServer.ProcessTSString(Object, StructureOfActions, CachedValues);
		StructureOfActions.Clear();
		
		For Each CurrentData In Object.ManufacturedProduct Do
			CurrentData.VATRate = Object.VATRate;
		EndDo;
		
	EndIf;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartServer.TreatTS(Object.ManufacturedProduct, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtServer
Procedure FillInServiceDetails()
	
	UsePartnersAsCounterparties            = GetFunctionalOption("UsePartnersAsCounterparties");
	UseSimplifiedPaymentSchemeInSales      = GetFunctionalOption("UseSimplifiedPaymentSchemeInSales");
	UseSeveralWarehouses                    = GetFunctionalOption("UseSeveralWarehouses");
	UseMaterialProviderOrder2_5                  = GetFunctionalOption("UseMaterialProviderOrder2_5");
	UseReportToMaterialProviderBySeveralOrders2_5 = GetFunctionalOption("UseReportToMaterialProviderBySeveralOrders2_5");
	UseLinesOfBusiness             = GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness");
	
	VarianceFromSalesTermsAndConditions   = UserRightsCached.VarianceFromSalesTermsAndConditions();
	IsFullUser = Users.IsFullUser(,, False);
	
	ReadPriceTypeRight       = AccessRight("View", Metadata.Documents.MaterialProviderOrder2_5.TabularSections.ManufacturedProduct.Attributes.PriceKind);
	
	DocumentCurrency                = Object.Currency;
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
EndProcedure

&AtServer
Procedure FillInDependentServiceAttributes(AttributesList = "")
	
	AttributesList = New Structure(AttributesList);
	Initialize = Not ValueIsFilled(AttributesList);
	
	If Initialize
		Or AttributesList.Property("BusinessOperation")
		Or AttributesList.Property("Warehouse")
		Or AttributesList.Property("Contract")
		Or AttributesList.Property("VATRate") Then
		SaveDetailsValuesBeforeChanging(ThisObject);
	EndIf;
	
	// Production of manufactured products
	If Initialize
		Or AttributesList.Property("BusinessOperation") Then
		
		ManufacturedProductsProduced =
			Object.BusinessOperation = Enums.BusinessTransactions.ReportToMaterialProvider2_5
			Or Object.BusinessOperation = Enums.BusinessTransactions.Subcontracting2_5
			Or Object.BusinessOperation = Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5;
		
		WorksAreBeingCarriedOut =
			Object.BusinessOperation = Enums.BusinessTransactions.ReportToMaterialProvider2_5
			Or Object.BusinessOperation = Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5
			Or Object.BusinessOperation = Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5;
		
	EndIf;
	
	If Initialize
		Or AttributesList.Property("Warehouse") Then
		WarehouseGroup_ = ItIsGroupOfWarehousesAndWarehousesUsedByWHForSale(Object.Warehouse);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsOfTableParts()
	
	StructureOfActions = New Structure;
	AddToStructureActionsToUpdateVspAttributesOfLine(StructureOfActions);
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.ManufacturedProduct, StructureOfActions);
	
EndProcedure

&AtServer
Procedure SetVisibilityOfElementsByTaxationServer()
	
	SaleIsSubjectToVAT = Object.VATTaxation = Enums.VATTaxationTypes.SaleIsSubjectToVAT;
	Items.PriceIncludesVAT.Visible = SaleIsSubjectToVAT;
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	FillInServiceDetails();
	FillInDependentServiceAttributes();
	FillInServiceDetailsOfTableParts();
	
	CustomizeFormElements();
	ConfigureDependentFormElements(ThisObject);
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.ReportToMaterialProvider2_5));
	Items.ManufacturedProductSeries.Visible = SeriesSpecificationParameters.UseItemsBatch;
	
	PurposeOfContract = GetContractAssignment(Object);
	
	PriceTypeSelectionParameters = SettingsValueCached.ParametersForSelectingDefaultPriceType();
	PriceTypeSelectionParameters.PriceIncludesVAT                          = Object.PriceIncludesVAT;
	PriceTypeSelectionParameters.UseWhileTransferringProductsToMaterialProvider = True;
	PriceTypeSelectionParameters.Status                                   = Enums.StatusesOfPriceTypeValidity.Valid;
	
	DefaultPriceType = SettingsValueCached.DefaultPriceType(PriceTypeSelectionParameters);
	
	SetParametersForSelectingManufacturedProductsWarehouse();
	
	WhenChangingWarehouseInTablePartServer();
	
	UpdateVATTaxation_(False);
	
	AssignmentsServer.OnReadCreateAtServer(ThisObject);
	
	UpdateOrderInformation();
	UpdateOrderDeviations();
	
	ProcessingOfTabularForms.InitializeRowCache(Items.ManufacturedProduct);
	
	SetAvailabilityOfItemsByStatusServer();
	
	CalculateTotals_(ThisObject);
	
	BasisChanged = False;
	If AccessRight("Update", Metadata.Documents.ReportToMaterialProvider2_5) Then
		PrintBasisTable.Load(Documents.ReportToMaterialProvider2_5.PrintBasisTable(Object));
		If ValueIsFilled(Object.Basis) Then
			BaseStructure = Documents.ReportToMaterialProvider2_5.StructureOfBaseForPrinting(Object);
			BasisChanged =
				TrimAll(Object.Basis) <> BaseStructure.Basis
				Or TrimAll(Object.BaseDocumentNumber) <> BaseStructure.BaseDocumentNumber
				Or Object.ReferenceDocumentDateForPrintForms <> BaseStructure.ReferenceDocumentDateForPrintForms;
		EndIf;
	EndIf;
	
	UpdateInvoiceText();
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateTotals_(Form)
	
	Object   = Form.Object;
	Items = Form.Items;
	
	Form.AmountTotal = Object.ManufacturedProduct.Total("AmountIncludingVAT");
	
	If VATAccountingERPClientServer.DisplayNDSInResultsOfSalesDocument(Object.VATTaxation) Then
		
		Items.VATPageGroup.CurrentPage   = Items.PageVAT;
		Items.PagesTotalGroup.CurrentPage = Items.TotalSNDSPage;
		
	Else
		
		Items.VATPageGroup.CurrentPage   = Items.PageExcludingVAT;
		Items.PagesTotalGroup.CurrentPage = Items.PageTotalWithoutVAT;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions.Insert(
		"RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
EndProcedure

&AtServer
Procedure FillInDefaultContract()
			
	If Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts 
	   And UseLinesOfBusiness Then
		
		Contract = SalesServer.GetDefaultContract(
										Object,
										TollingSchemeClientServer.ContractBusinessTransaction(),
										Object.ARAPCurrency,
										Object.LineOfBusiness);
		
	Else
		
		Contract = SalesServer.GetDefaultContract(
										Object,
										TollingSchemeClientServer.ContractBusinessTransaction(),
										Object.ARAPCurrency);
		
	EndIf;
	
	If Contract <> Object.Contract Then
		Object.Contract = Contract;
		WhenChangingAgreementServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInFromOrderServer()
	
	Object.ManufacturedProduct.Clear();
	
	If UseReportToMaterialProviderBySeveralOrders2_5 Then
		AnArrayOfOrders = Undefined;
	Else
		AnArrayOfOrders = New Array;
		AnArrayOfOrders.Add(Object.MaterialProviderOrder);
	EndIf;
	
	FillParameters = New Structure;
	Documents.ReportToMaterialProvider2_5.FillByOrderBalances(Object, Object.ManufacturedProduct, AnArrayOfOrders, FillParameters);
	
	UpdateOrderInformation();
	
	FillInServiceDetailsOfTableParts();
	WhenChangingWarehouseInTablePartServer();
	
	FillBaseForPrinting();
	
	CalculateTotals_(ThisObject);
	
	SeriesSpecificationParameters = 
		New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.ReportToMaterialProvider2_5));
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfItemsByStatusServer()
	
	ItemArray = New Array;
	
	If Not Object.ReportOnOrders Then
		ItemArray.Add("Date");
	EndIf;
	
	// Header Controls
	ItemArray.Add("Partner");
	ItemArray.Add("Contract");
	
	ItemArray.Add("PriceIncludesVAT");
	ItemArray.Add("Organization");
	ItemArray.Add("Counterparty");
	ItemArray.Add("VATTaxation");
	
	ItemArray.Add("ManufacturedProduct;BeforeAddRow,BeforeDeleteRow,BeforeRowChange");
	
	ItemArray.Add("ProductsAdd");
	ItemArray.Add("ManufacturedProductInsertRows");
	ItemArray.Add("ManufacturedProductContextMenuAdd");
	ItemArray.Add("ManufacturedProductContextMenuInsertRows");
	
	ItemArray.Add("ManufacturedProductProducts");
	ItemArray.Add("ManufacturedProductRowCode");
	ItemArray.Add("ManufacturedProductCharacteristic");
	ItemArray.Add("ManufacturedProductPriceKind");
	
	TMCommonUse.SetSubscriptionForFormElementChangeEvents(ThisObject, ItemArray);
	
	If Not Object.ReportOnOrders Then
		
		TMCommonUseClientServer.SetFormItemProperty(
			Items, "ManufacturedProductUnlinkFromOrder", "Visible", False);
		
		TMCommonUseClientServer.SetFormItemProperty(
			Items, "ProductsContextMenuUnlinkFromOrder", "Visible", False);
			
		TMCommonUseClientServer.SetFormItemProperty(
			Items, "ProductsGroupGiverSOrder", "Visible", False);
		
		TMCommonUseClientServer.SetFormItemProperty(
			Items, "ManufacturedProductFillInTheWarehouse", "Enabled", WarehouseGroup_);
		
		TMCommonUseClientServer.SetFormItemProperty(
			Items,
			"ProductsToPickUpFromOrderByBalance",
			"Enabled",
			UseReportToMaterialProviderBySeveralOrders2_5);
		
	Else
		
		TMCommonUseClientServer.SetFormItemProperty(
			Items, "ManufacturedProductUnlinkFromOrder", "Visible", True);
		
		TMCommonUseClientServer.SetFormItemProperty(
			Items, "ProductsContextMenuUnlinkFromOrder", "Visible", True);
			
		TMCommonUseClientServer.SetFormItemProperty(
			Items, "ProductsGroupGiverSOrder", "Visible", True);
		
		TMCommonUseClientServer.SetFormItemProperty(
			Items,"ManufacturedProductFillInTheWarehouse", "Visible", False);
		
		TMCommonUseClientServer.SetFormItemProperty(
			Items,
			"ProductsToPickUpFromOrderByBalance",
			"Enabled",
			True);
		
	EndIf;
	
	ItemArray = New Array;
	ItemArray.Add("BusinessOperation");
	ItemArray.Add("Partner");
	ItemArray.Add("Contract");
	ItemArray.Add("Currency");
	ItemArray.Add("PriceIncludesVAT");
	ItemArray.Add("Organization");
	ItemArray.Add("Counterparty");
	ItemArray.Add("Warehouse");
	ItemArray.Add("SalesOpportunity");
	ItemArray.Add("Department");
	ItemArray.Add("LineOfBusiness");
	ItemArray.Add("VATTaxation");
	ItemArray.Add("ARAPCurrency");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items,
		ItemArray,
		"ReadOnly",
		Object.ReportOnOrders And (ValueIsFilled(Object.MaterialProviderOrder) Or OrderList.Count() > 0));
	
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
	
EndProcedure

&AtServerNoContext
Function GetDefaultCounterpartyBankAccountServer(Counterparty)
	
	ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
	
	Return CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount);
	
EndFunction

&AtServer
Procedure ChangedPaymentServer(EventName, Parameter)
	
	// ARAPAccounting
	ARAPAccountingFormWork.NotificationProcessing(ThisObject, EventName, Parameter);
	// End ARAPAccounting
	
EndProcedure

&AtServer
Procedure UpdateInvoiceText()
	
	RegistrationParameters            = Documents.ReportToMaterialProvider2_5.ParametersForRegisteringInvoicesIssued(Object);
	InvoicesIssuedOnBasisOf = VATAccountingERP.InvoicesIssuedOnBasisOf(RegistrationParameters);
	
	TextsDocumentsBasedOn = New Array;
	TextsDocumentsBasedOn.Add(InvoicesIssuedOnBasisOf.Presentation);
	
	UpdateTextsDocumentsBasedOn(TextsDocumentsBasedOn, InvoicesIssuedOnBasisOf);
	
	TextOfTheInvoiceIssued = New FormattedString(TextsDocumentsBasedOn);
	
EndProcedure

&AtServer
Procedure UpdateVATTaxation_(Fill = True, CachedValues = Undefined)
	
	FillParameters = Documents.ReportToMaterialProvider2_5.ParametersForFillingInVATTaxation_(Object);
	
	If Fill Then
		
		VATAccountingERP.FillInSalesVATTaxation(
			Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues);
		
	EndIf;
	
	VATAccountingERP.FillInSalesVATTaxSelectionList(
		Items.VATTaxation,
		Object.VATTaxation,
		FillParameters,
		VATAccountingCachedParameterValues);
	
EndProcedure

&AtServer
Procedure UpdateOrderInformation()
	
	ParametersOfUpdate = OrdersServer.ParametersForUpdatingOrderInformationInForm();
	
	ParametersOfUpdate.PropsNameOrderList         = "OrderList";
	ParametersOfUpdate.OrderPathInHeader                  = "Object.MaterialProviderOrder";
	ParametersOfUpdate.TitleLabelName               = "HeaderOrdersText";
	ParametersOfUpdate.NameOfColumnGroupInTableSection   = "ProductsGroupGiverSOrder";
	ParametersOfUpdate.OrderNameInTablePart          = "MaterialProviderOrder";
	ParametersOfUpdate.UseOrdersInTabularSection = UseReportToMaterialProviderBySeveralOrders2_5;
	
	OrdersServer.UpdateOrderInformationInForm(ThisObject, Object.ManufacturedProduct, ParametersOfUpdate);
	
EndProcedure
	
&AtServer
Procedure UpdateDependentDetailsOfServerByOrderForm()
	
	If Object.ManufacturedProduct.Count() = 0
	 Or Not Object.ReportOnOrders
	 Or Not UseMaterialProviderOrder2_5 Then
	
		Items.PictureDiscrepancyOrder.Picture  = PictureLib.AnEmptyPicture;
		Items.PictureDiscrepancyOrders.Picture = PictureLib.AnEmptyPicture;
		
		DiscrepancyOrderText = "";
		
		If Object.ManufacturedProduct.Count() > 0 Then
			
			For Each LineProducts In Object.ManufacturedProduct Do
				LineProducts.OrderDiscrepancy_3 = 0;
			EndDo;
			
		EndIf;
		
		Return;
		
	EndIf;
	
	UpdateDependentDetailsOfOrderForm_(Object.ManufacturedProduct, DiscrepancyOrderText, Items);
	
EndProcedure
	
&AtClientAtServerNoContext
Procedure UpdateDependentDetailsOfOrderForm_(ManufacturedProduct, DiscrepancyOrderText, FormItems)
	
	NumberOfDiscrepancies = ManufacturedProduct.Total("OrderDiscrepancy_3");
	
	If NumberOfDiscrepancies > 0 Then
		
		FormItems.PictureDiscrepancyOrder.Picture  = PictureLib.ExceededOrder;
		FormItems.PictureDiscrepancyOrders.Picture = PictureLib.ExceededOrder;
		
		DiscrepancyOrderText = StrTemplate(NStr("vi = 'Các dòng phía trên đơn hàng: %1';
												|ru = 'Строк сверх заказа: %1';
												|en = 'Lines exceeding the order: %1'; fa = 'Lines exceeding the order: %1';
												|it = 'Righe in eccesso rispetto all''ordine: %1';
												|pl = 'Wierzy przewyższających zamówienie: %1';
												|tr = 'Sipariş fazlası satırı: %1'"), NumberOfDiscrepancies);
		
	Else
		
		FormItems.PictureDiscrepancyOrder.Picture  = PictureLib.AnEmptyPicture;
		FormItems.PictureDiscrepancyOrders.Picture = PictureLib.AnEmptyPicture;
		
		DiscrepancyOrderText = "";
		
	EndIf;
	
EndProcedure

&AtServer
Function LinkRowsToOrders(SelectByOrder_)
	
	If Not UseMaterialProviderOrder2_5
	 Or Not UseReportToMaterialProviderBySeveralOrders2_5 And Not ValueIsFilled(Object.MaterialProviderOrder) Then
		Return False;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Goods.Products   AS Products,
	|	Goods.Characteristic AS Characteristic
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|
	|INDEX BY
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	MaterialProviderOrder2_5.Ref AS Ref
	|INTO TheOrdersTable
	|FROM
	|	Document.MaterialProviderOrder2_5 AS MaterialProviderOrder2_5
	|WHERE
	|	CASE
	|		WHEN &FilterByOrders
	|			THEN MaterialProviderOrder2_5.Ref IN (&AnArrayOfOrders)
	|		ELSE MaterialProviderOrder2_5.Organization        = &Organization
	|			AND MaterialProviderOrder2_5.Currency             = &Currency
	|			AND MaterialProviderOrder2_5.Counterparty         = &Counterparty
	|			AND MaterialProviderOrder2_5.Contract            = &Contract
	|			AND MaterialProviderOrder2_5.Partner            = &Partner
	|			AND MaterialProviderOrder2_5.SalesOpportunity             = &SalesOpportunity
	|			AND MaterialProviderOrder2_5.BusinessOperation = &BusinessOperation
	|			AND MaterialProviderOrder2_5.VATTaxation = &VATTaxation
	|			AND (NOT &UseLinesOfBusiness
	|				OR MaterialProviderOrder2_5.LineOfBusiness = &LineOfBusiness)
	|			AND (MaterialProviderOrder2_5.Warehouse = &Warehouse
	|				OR MaterialProviderOrder2_5.Warehouse IN HIERARCHY (&Warehouse)
	|				OR MaterialProviderOrder2_5.Warehouse = VALUE(Catalog.Warehouses.EmptyRef))
	|			AND MaterialProviderOrder2_5.Posted
	|	END
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TurnoversByOrders.ReferenceOrder                                      AS SalesOrder,
	|	TurnoversByOrders.Products                                      AS Products,
	|	TurnoversByOrders.Characteristic                                    AS Characteristic,
	|	TurnoversByOrders.RowCode                                         AS RowCode,
	|	TurnoversByOrders.Warehouse                                             AS Warehouse,
	|	TurnoversByOrders.Series                                             AS Series,
	|	SUM(TurnoversByOrders.QuantityToBeShippedTurnover) AS ToTransferReceipt,
	|	SUM(TurnoversByOrders.IssuedQuantityTurnover) AS ToRegisterExpense
	|INTO OrdersTurnoverInExcessOfOrder
	|FROM
	|	#ShipmentOrdersTurnoverExpanded1 AS TurnoversByOrders
	|GROUP BY
	|	TurnoversByOrders.ReferenceOrder,
	|	TurnoversByOrders.Products,
	|	TurnoversByOrders.Characteristic,
	|	TurnoversByOrders.RowCode,
	|	TurnoversByOrders.Warehouse,
	|	TurnoversByOrders.Series
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfOrdersToBeProcessed.SalesOrder       AS MaterialProviderOrder,
	|	TableOfOrdersToBeProcessed.Products       AS Products,
	|	TableOfOrdersToBeProcessed.Characteristic     AS Characteristic,
	|	TableOfOrdersToBeProcessed.RowCode          AS RowCode,
	|	TableOfOrdersToBeProcessed.Warehouse              AS Warehouse,
	|	TableOfOrdersToBeProcessed.Series              AS Series,
	|	SUM(TableOfOrdersToBeProcessed.ToRegister) AS Count
	|INTO BalanceTable
	|FROM
	|	(SELECT
	|		TurnoversByOrders.ReferenceOrder       AS SalesOrder,
	|		TurnoversByOrders.Products       AS Products,
	|		TurnoversByOrders.Characteristic     AS Characteristic,
	|		TurnoversByOrders.RowCode          AS RowCode,
	|		TurnoversByOrders.Warehouse              AS Warehouse,
	|		TurnoversByOrders.Series              AS Series,
	|		(TurnoversByOrders.ForRegistrationQuantityTurnover
	|			- TurnoversByOrders.IssuedQuantityTurnover) AS ToRegister
	|	FROM
	|		#ShipmentOrdersTurnoverExpanded2 AS TurnoversByOrders
	|	WHERE
	|		(TurnoversByOrders.ForRegistrationQuantityTurnover
	|			- TurnoversByOrders.IssuedQuantityTurnover) <> 0
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ShipmentReferences.ReferenceOrder   AS SalesOrder,
	|		ShipmentReferences.Products   AS Products,
	|		ShipmentReferences.Characteristic AS Characteristic,
	|		ShipmentReferences.RowCode      AS RowCode,
	|		ShipmentReferences.Warehouse          AS Warehouse,
	|		ShipmentReferences.Series          AS Series,
	|		ShipmentReferences.Count     ToRegister
	|	FROM
	|		AccumulationRegister.ShipmentAndReturnReferences AS ShipmentReferences
	|	WHERE
	|		ShipmentReferences.Active
	|		AND ShipmentReferences.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Issued_1)
	|		AND ShipmentReferences.Recorder = &Recorder
	|		AND ShipmentReferences.ReferenceOrder IN
	|			(SELECT
	|				TheOrdersTable.Ref AS Ref
	|			FROM
	|				TheOrdersTable AS TheOrdersTable)
	|		AND (ShipmentReferences.Products, ShipmentReferences.Characteristic) IN
	|			(SELECT
	|				Goods.Products   AS Products,
	|				Goods.Characteristic AS Characteristic
	|			FROM
	|				Goods AS Goods)
	|		AND ShipmentReferences.RowCode <> 0) AS TableOfOrdersToBeProcessed
	|
	|	GROUP BY
	|		TableOfOrdersToBeProcessed.SalesOrder,
	|		TableOfOrdersToBeProcessed.Products,
	|		TableOfOrdersToBeProcessed.Characteristic,
	|		TableOfOrdersToBeProcessed.RowCode,
	|		TableOfOrdersToBeProcessed.Warehouse,
	|		TableOfOrdersToBeProcessed.Series
	|
	|	HAVING
	|		SUM(TableOfOrdersToBeProcessed.ToRegister) > 0
	|
	|UNION ALL
	|
	|	SELECT
	|		TableOfOrdersOverAndAboveOrder.SalesOrder       AS SalesOrder,
	|		TableOfOrdersOverAndAboveOrder.Products       AS Products,
	|		TableOfOrdersOverAndAboveOrder.Characteristic     AS Characteristic,
	|		TableOfOrdersOverAndAboveOrder.RowCode          AS RowCode,
	|		TableOfOrdersOverAndAboveOrder.Warehouse              AS Warehouse,
	|		TableOfOrdersOverAndAboveOrder.Series              AS Series,
	|		SUM(TableOfOrdersOverAndAboveOrder.ToRegister) AS Count
	|	FROM
	|		(SELECT
	|			OrdersTurnovers.SalesOrder                                      AS SalesOrder,
	|			OrdersTurnovers.Products                                      AS Products,
	|			OrdersTurnovers.Characteristic                                    AS Characteristic,
	|			OrdersTurnovers.RowCode                                         AS RowCode,
	|			OrdersTurnovers.Warehouse                                             AS Warehouse,
	|			OrdersTurnovers.Series                                             AS Series,
	|			OrdersTurnovers.ToTransferReceipt - OrdersTurnovers.ToRegisterExpense AS ToRegister
	|		FROM
	|			OrdersTurnoverInExcessOfOrder AS OrdersTurnovers
	|
	|		UNION ALL
	|
	|		SELECT
	|			ShipmentReferences.ReferenceOrder   AS SalesOrder,
	|			ShipmentReferences.Products   AS Products,
	|			ShipmentReferences.Characteristic AS Characteristic,
	|			ShipmentReferences.RowCode      AS RowCode,
	|			ShipmentReferences.Warehouse          AS Warehouse,
	|			ShipmentReferences.Series          AS Series,
	|			ShipmentReferences.Count     AS ToRegister
	|		FROM
	|			AccumulationRegister.ShipmentAndReturnReferences AS ShipmentReferences
	|		WHERE
	|			ShipmentReferences.Active
	|			AND ShipmentReferences.Recorder = &Recorder
	|			AND ShipmentReferences.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Issued_1)
	|			AND ShipmentReferences.ReferenceOrder IN
	|				(SELECT
	|					TheOrdersTable.Ref AS Ref
	|				FROM
	|					TheOrdersTable AS TheOrdersTable)
	|			AND (ShipmentReferences.Products, ShipmentReferences.Characteristic) IN
	|				(SELECT
	|					Goods.Products   AS Products,
	|					Goods.Characteristic AS Characteristic
	|				FROM
	|					Goods AS Goods)
	|			AND ShipmentReferences.RowCode = 0) AS TableOfOrdersOverAndAboveOrder
	|	
	|	GROUP BY
	|		TableOfOrdersOverAndAboveOrder.SalesOrder,
	|		TableOfOrdersOverAndAboveOrder.Products,
	|		TableOfOrdersOverAndAboveOrder.Characteristic,
	|		TableOfOrdersOverAndAboveOrder.RowCode,
	|		TableOfOrdersOverAndAboveOrder.Warehouse,
	|		TableOfOrdersOverAndAboveOrder.Series
	|	
	|	HAVING
	|		SUM(TableOfOrdersOverAndAboveOrder.ToRegister) > 0
	|
	|INDEX BY
	|	MaterialProviderOrder,
	|	RowCode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BalanceTable.MaterialProviderOrder            AS MaterialProviderOrder,
	|	BalanceTable.MaterialProviderOrder.ARAPObjectSettings AS ARAPObjectSettings,
	|	BalanceTable.MaterialProviderOrder.Purpose AS Purpose,
	|	BalanceTable.RowCode                AS RowCode,
	|	BalanceTable.Products             AS Products,
	|	BalanceTable.Characteristic           AS Characteristic,
	|	BalanceTable.Warehouse                    AS Warehouse,
	|	BalanceTable.Series                    AS Series,
	|	ProductTable.PriceKind                 AS PriceKind,
	|	ProductTable.Price                    AS Price,
	|	BalanceTable.Count               AS ToRegisterBalance
	|FROM
	|	BalanceTable AS BalanceTable
	|		LEFT JOIN Document.MaterialProviderOrder2_5.ManufacturedProduct AS ProductTable
	|		ON BalanceTable.MaterialProviderOrder = ProductTable.Ref
	|		 AND BalanceTable.RowCode     = ProductTable.RowCode
	|
	|ORDER BY
	|	ProductTable.Ref,
	|	ProductTable.Products,
	|	ProductTable.Characteristic,
	|	ProductTable.Warehouse,
	|	ProductTable.Series,
	|	ProductTable.DateOfShipment,
	|	ProductTable.LineNumber,
	|	BalanceTable.RowCode DESC
	|";
	
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"ReferenceOrder IN
		|		(SELECT
		|				TheOrdersTable.Ref AS Ref
		|			FROM
		|				TheOrdersTable AS TheOrdersTable)
		|		AND RowCode = 0
		|		AND (Products, Characteristic) IN
		|			(SELECT
		|				Goods.Products AS Products,
		|				Goods.Characteristic AS Characteristic
		|			FROM
		|				Goods AS Goods)";
	TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, RowCode, Warehouse, Series";
	TableFormationParameters.Indicators = "ToShip, Issued_1";
	TableFormationParameters.Resources = "Count";
	
	ShipmentOrdersTurnoverExpanded1 =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query.Text = StrReplace(Query.Text,
		"#ShipmentOrdersTurnoverExpanded1",
		ShipmentOrdersTurnoverExpanded1);
	
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"ReferenceOrder IN
		|		(SELECT
		|				TheOrdersTable.Ref AS Ref
		|			FROM
		|				TheOrdersTable AS TheOrdersTable)
		|		AND (Products, Characteristic) IN
		|			(SELECT
		|					Goods.Products   AS Products,
		|					Goods.Characteristic AS Characteristic
		|				FROM
		|					Goods AS Goods)
		|		AND RowCode <> 0";
	TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, RowCode, Warehouse, Series";
	TableFormationParameters.Indicators = "ToRegister, Issued_1";
	TableFormationParameters.Resources = "Count";
	
	ShipmentOrdersTurnoverExpanded2 =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query.Text = StrReplace(Query.Text,
		"#ShipmentOrdersTurnoverExpanded2",
		ShipmentOrdersTurnoverExpanded2);
	
	AnArrayOfOrders = New Array;
	AnArrayOfOrders.Add(Object.MaterialProviderOrder);
	
	Query.SetParameter("FilterByOrders",                      SelectByOrder_);
	Query.SetParameter("AnArrayOfOrders",                       AnArrayOfOrders);
	Query.SetParameter("Recorder",                         Object.Ref);
	Query.SetParameter("Organization",                         Object.Organization);
	Query.SetParameter("Currency",                              Object.ARAPCurrency);
	Query.SetParameter("Counterparty",                          Object.Counterparty);
	Query.SetParameter("Contract",                             Object.Contract);
	Query.SetParameter("Partner",                             Object.Partner);
	Query.SetParameter("SalesOpportunity",                              Object.SalesOpportunity);
	Query.SetParameter(
		"BusinessOperation",
		?(Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReportToMaterialProvider2_5"),
			PredefinedValue("Enum.BusinessTransactions.TollManufacturing2_5"),
			Object.BusinessOperation));
	Query.SetParameter("VATTaxation",                  Object.VATTaxation);
	Query.SetParameter("Warehouse",                               Object.Warehouse);
	Query.SetParameter("LineOfBusiness",             Object.LineOfBusiness);
	Query.SetParameter("UseLinesOfBusiness", UseLinesOfBusiness);
	
	Query.SetParameter("Goods", Object.ManufacturedProduct.Unload(, "Products, Characteristic"));
	
	SetPrivilegedMode(True);
	
	QueryResult = Query.ExecuteBatch();
	If QueryResult[3].IsEmpty() Then
		Return False;
	EndIf;
	
	Selection = QueryResult[4].Select();
	ArrayOfARAPObjectsSettings = New Array();
	While Selection.Next() Do
		If ValueIsFilled(Selection.ARAPObjectSettings)
			And ArrayOfARAPObjectsSettings.Find(Selection.ARAPObjectSettings) = Undefined Then
			ArrayOfARAPObjectsSettings.Add(Selection.ARAPObjectSettings);
		EndIf;
	EndDo;
	
	If ArrayOfARAPObjectsSettings.Count() > 1 Then
		Common.MessageToUser(NStr("vi = 'Trong các đơn hàng đã tìm thấy, khác trường ""Trình tự hạch toán""';
									|ru = 'У найденных заказов отличается поле ""Порядок расчетов""';
									|en = 'The ""Payment terms"" field data is different for the found orders'; fa = 'The ""Payment terms"" field data is different for the found orders';
									|it = 'У найденных заказов отличается поле ""Порядок расчетов""';
									|pl = 'The ""Payment terms"" field data is different for the found orders';
									|tr = 'Bulunan siparişlerin farklı bir ""Alacak/Borç muhasebesi prosedürü"" alanı mevcut'"));
		Return False;
	EndIf;
	
	Selection.Reset();
	
	While Selection.Next() Do
		
		QuantityToRegister = Selection.ToRegisterBalance;
		
		TheStructureOfTheSearch = New Structure;
		TheStructureOfTheSearch.Insert("MaterialProviderOrder",  Documents.MaterialProviderOrder2_5.EmptyRef());
		TheStructureOfTheSearch.Insert("RowCode",      0);
		TheStructureOfTheSearch.Insert("Products",   Selection.Products);
		TheStructureOfTheSearch.Insert("Characteristic", Selection.Characteristic);
		TheStructureOfTheSearch.Insert("Warehouse",          Selection.Warehouse);
		TheStructureOfTheSearch.Insert("Series",          Selection.Series);
		TheStructureOfTheSearch.Insert("PriceKind",        Selection.PriceKind);
		TheStructureOfTheSearch.Insert("Price",           Selection.Price);
		DistributeQuantityForRegistration(Selection, QuantityToRegister, TheStructureOfTheSearch);
		
		TheStructureOfTheSearch.Delete("PriceKind");
		TheStructureOfTheSearch.Delete("Price");
		DistributeQuantityForRegistration(Selection, QuantityToRegister, TheStructureOfTheSearch);
		
	EndDo;
	
	RowsArray =
		Object.ManufacturedProduct.FindRows(New Structure("MaterialProviderOrder", Documents.MaterialProviderOrder2_5.EmptyRef()));
		
	NumberOfRowsFound = RowsArray.Count();
	If NumberOfRowsFound > 0 Then
		
		CurrentOrder     = Undefined;
		OrderAssignment = Undefined;
		
		If ValueIsFilled(Object.MaterialProviderOrder) Then
			
			CurrentOrder     = Object.MaterialProviderOrder;
			OrderAssignment = Common.ObjectAttributeValue(Object.MaterialProviderOrder, "Purpose");
			
		ElsIf Object.ManufacturedProduct.Count() > NumberOfRowsFound Then
			
			TheOrdersTable = Object.ManufacturedProduct.Unload(, "MaterialProviderOrder, Purpose");
			TheOrdersTable.GroupBy("MaterialProviderOrder, Purpose");
			
			CurrentOrder = TheOrdersTable[0].MaterialProviderOrder;
			If ValueIsFilled(CurrentOrder) Then
				OrderAssignment = TheOrdersTable[0].Purpose;
			Else
				CurrentOrder     = TheOrdersTable[1].MaterialProviderOrder;
				OrderAssignment = TheOrdersTable[1].Purpose;
			EndIf;
				
		EndIf;
		
		If ValueIsFilled(CurrentOrder) Then
			
			For Each TableRow In RowsArray Do
				TableRow.MaterialProviderOrder = CurrentOrder;
				TableRow.Purpose    = OrderAssignment;
			EndDo;
			
		EndIf;
		
	EndIf;
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	Return True;
	
EndFunction

&AtServer
Procedure DistributeQuantityForRegistration(OrderData, QuantityToRegister, TheStructureOfTheSearch)
	
	If QuantityToRegister = 0 Then
		Return;
	EndIf;
	
	RowsToProcess = New Array;
	RowsArray = Object.ManufacturedProduct.FindRows(TheStructureOfTheSearch);
	For Each LineTSProducts In RowsArray Do
		
		If LineTSProducts.Count <= QuantityToRegister Then
			
			FillPropertyValues(LineTSProducts, OrderData, "RowCode, MaterialProviderOrder, Purpose");
			
			QuantityToRegister = QuantityToRegister - LineTSProducts.Count;
			
		Else
			
			NewRow = Object.ManufacturedProduct.Insert(Object.ManufacturedProduct.IndexOf(LineTSProducts) + 1);
			
			FillPropertyValues(NewRow, LineTSProducts,, "Count");
			NewRow.Count = LineTSProducts.Count - QuantityToRegister;
			
			FillPropertyValues(LineTSProducts, OrderData, "RowCode, MaterialProviderOrder, Purpose");
			LineTSProducts.Count = QuantityToRegister;
			RowsToProcess.Add(LineTSProducts);
			RowsToProcess.Add(NewRow);

			QuantityToRegister = 0;
			
		EndIf;
		
		If QuantityToRegister = 0 Then
			Break;
		EndIf;
		
	EndDo;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	ValuesInCache = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.ManufacturedProduct,
		ValuesInCache);

EndProcedure

&AtServer
Procedure UnlinkFromOrderServer(AllRows = True, UntieOnlyStrings = True)
	
	Var CachedValues;
	
	If AllRows Then
		RowsCollection = Object.ManufacturedProduct;
	Else
		RowsCollection = Items.ManufacturedProduct.SelectedRows;
	EndIf;
	
	For Each CurRow In RowsCollection Do
		
		If AllRows Then
			TableRow = CurRow;
			CurRow = TableRow.GetID();
		Else
			TableRow = Object.ManufacturedProduct.FindByID(CurRow);
		EndIf;
		
		ProductsClientServer.UpdateCachedValuesToAccountForSeries(
			TableRow, CachedValues, SeriesSpecificationParameters);
		
		TableRow.RowCode = 0;
		
		If UntieOnlyStrings Then
			TableRow.OrderDiscrepancy_3 = 1;
		Else
			TableRow.MaterialProviderOrder = Undefined;
			TableRow.Purpose    = PurposeOfContract;
		EndIf;
		
		// Reassign the series lines
		ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(
			Object, SeriesSpecificationParameters, CurRow, CachedValues);
		
	EndDo;
	
	UpdateDependentDetailsOfServerByOrderForm();
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateOrderDeviationsInLine(CurrentRow, ReportOnOrders)
	
	If ReportOnOrders Then
		CurrentRow.OrderDiscrepancy_3 = ?(CurrentRow.RowCode = 0, 1, 0);
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateOrderDeviations()
	
	For Each TableRow In Object.ManufacturedProduct Do
		UpdateOrderDeviationsInLine(TableRow, Object.ReportOnOrders);
	EndDo;
	
EndProcedure
	
&AtClient
Procedure NotifyAboutEndOfUnbindingLines(NumberOfLinesWorked, LinesWereUnlinked = True)

	If LinesWereUnlinked Then
		
		NotificationText1 = NStr("vi = 'Các dòng đã bỏ liên kết';
								|ru = 'Строки отвязаны';
								|en = 'Lines were unlinked'; fa = 'Lines were unlinked';
								|it = 'Righe dissociate';
								|pl = 'Wierze odłączone';
								|tr = 'Ayrılmış satırlar'");
		TextExplanation  =
			StrTemplate(NStr("vi = 'Trong chứng từ, bỏ liên kết các dòng với đơn hàng (%1).';
							|ru = 'В документе от заказов отвязано строк (%1).';
							|en = 'In the document, the lines (%1) are detached from the orders.'; fa = 'In the document, the lines (%1) are detached from the orders.';
							|it = 'Nel documento saranno scollegate le stringhe (%1).';
							|pl = 'W dokumencie odwiązano od zamówień (%1) wierszy.';
							|tr = 'Belgede siparişlerden ayrılmış satırlar (%1) vardır.'"), NumberOfLinesWorked);
		
	Else
		
		NotificationText1 = NStr("vi = 'Các dòng chưa bỏ liên kết';
								|ru = 'Строки не отвязаны';
								|en = 'Lines were not unlinked'; fa = 'Lines were not unlinked';
								|it = 'Righe non dissociate';
								|pl = 'Wierze nie odłączone';
								|tr = 'Birleşik satırlar'");
		TextExplanation  = NStr("vi = 'Không có dòng nào liên quan.';
								|ru = 'Ни одна строка не была отвязана.';
								|en = 'No line was unlinked.'; fa = 'No line was unlinked.';
								|it = 'Nessuna riga è stata dissociata.';
								|pl = 'Nie odłączono ani jednego wiersza.';
								|tr = 'Hiçbir satır ayrılmamış'");
		
	EndIf;
	
	ShowUserNotification(NotificationText1,, TextExplanation, PictureLib.Information32);
	
EndProcedure
	
// The constructor function of additional parameters processing is complete
// 
// Returns:
//  Structure - advanced setting:
//   * CurrentRow - FormDataCollectionItem, FormDataStructure, FormDataTreeItem - 
//   * CallbackDescription - CallbackDescription - 
//
&AtClient
Function AdditionalCompletionProcessingParameters() 
	
	Result = New Structure;
	Result.Insert("CurrentRow");
	Result.Insert("CallbackDescription");
	
	Return Result;
	
EndFunction
	
&AtClient
Procedure QuestionUserWhenChangingRowDetails(CallbackDescription, CurrentRow)
	
	// If the current line is not related to the order
	If CurrentRow.RowCode = 0 Then
		RunCallback(CallbackDescription, True);
		Return;
	EndIf;
	
	// If none of the key details have changed
	If CurrentRow.Products = PreviousRowDetails.Products
	   And CurrentRow.Characteristic = PreviousRowDetails.Characteristic
	   And CurrentRow.Warehouse = PreviousRowDetails.Warehouse
	   And CurrentRow.Series = PreviousRowDetails.Series Then
		RunCallback(CallbackDescription, True);
		Return;
	EndIf;
	
	AdditionalParameters = AdditionalCompletionProcessingParameters();
	AdditionalParameters.CurrentRow      = CurrentRow;
	AdditionalParameters.CallbackDescription = CallbackDescription;
	
	QueryText = NStr("vi = 'Dòng đang chỉnh sửa sẽ không còn liên kết với dòng đơn hàng. Tiếp tục?';
					|ru = 'Редактируемая строка перестанет быть связанной со строкой заказа. Продолжить?';
					|en = 'The edited line will be unlinked from the order line. Continue?'; fa = 'The edited line will be unlinked from the order line. Continue?';
					|it = 'La riga da modificare non sarà più associata alla riga dell''ordine. Continuare?';
					|pl = 'Edytowany wiersz nie będzie powiązany z wierszem zamówienia. Kontynuować?';
					|tr = 'Düzenlenecek satır artık sipariş satırına bağlı olmayacaktır. Devam edilsin mi?'");
	
	NotifyDescriptionQuestion = New CallbackDescription("QuestionToUserWhenChangingDetailsOfLineQuestionCompletion",
														ThisObject,
														AdditionalParameters);
	
	ShowQueryBox(NotifyDescriptionQuestion, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

// Parameters:
// 	QuestionResult - DialogReturnCode - 
// 	AdditionalParameters - See AdditionalCompletionProcessingParameters
&AtClient
Procedure QuestionToUserWhenChangingDetailsOfLineQuestionCompletion(QuestionResult, AdditionalParameters) Export
	
	// If the user has confirmed the change of the key Attribute value
	If QuestionResult = DialogReturnCode.Yes Then
		
		AdditionalParameters.CurrentRow.RowCode = 0;
		UpdateOrderDeviationsInLine(AdditionalParameters.CurrentRow, Object.ReportOnOrders);
		RunCallback(AdditionalParameters.CallbackDescription, True);
		
	Else
		
		// If the user refused to change the linked string, we return the old values
		FillPropertyValues(AdditionalParameters.CurrentRow, PreviousRowDetails);
		RunCallback(AdditionalParameters.CallbackDescription, False);
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function ItIsGroupOfWarehousesAndWarehousesUsedByWHForSale(Warehouse)
	
	Return Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWHForSales(Warehouse);
	
EndFunction 

&AtServerNoContext
Function WarehouseSelectionData(Warehouse)

	Query = New Query;
	Query.Text =
	"SELECT ALLOWED
	|	Warehouses.Ref AS Ref
	|FROM
	|	Catalog.Warehouses AS Warehouses
	|WHERE
	|	Warehouses.Ref IN HIERARCHY (&Warehouse)
	|	AND NOT Warehouses.IsFolder
	|	AND NOT Warehouses.SelectGroup = VALUE(Enum.SelectWarehouseGroup.Disable)";

	Query.SetParameter("Warehouse", Warehouse);
	
	Result = Query.Execute();
	
	Return Result.Unload().UnloadColumn("Ref");

EndFunction

&AtServer
Procedure SetParametersForSelectingManufacturedProductsWarehouse()
	
	Items.ManufacturedProductWarehouse.ChoiceParameters = New FixedArray(New Array);
	
	TMCommonUseClientServer.AddSelectionParameter(
		Items.ManufacturedProductWarehouse, "Ref", WarehouseSelectionData(Object.Warehouse));

EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsClearFillArticleAnalytics(StructureOfActions, Form)
	
	IncomeAndExpensesClientServer.InsertActionClearItemAndExpenseAnalytics(
		StructureOfActions, Form, "Object.ManufacturedProduct");
	
	IncomeAndExpensesClientServer.InsertActionFillInItemCostAnalysisOfProducts(
		StructureOfActions,
		Form,
		PredefinedValue("Enum.BusinessTransactions.GoodsConsumptionOnDemand"),
		Form.Object.Organization,
		Form.Object.Department,
		"Object.ManufacturedProduct");
	
EndProcedure

&AtServer
Procedure AddSBPPaymentStatusUpdateCommand()

	CommandParameters = CashServerLocalization.NewParametersOfSBPPaymentStatusUpdateCommand();
	CommandParameters.Parent = Items.PaymentGroup_2;
	CashServerLocalization.AddSBPPaymentStatusUpdateCommand(ThisObject, CommandParameters);

EndProcedure

&AtClient
Procedure Attachable_SBPPaymentVerification()

	CashClientLocalization.CheckSBPPayment(ThisObject, Object.Ref, Object.Counterparty);

EndProcedure

#Region ARAPAccounting

&AtClient
Procedure LabelCurrenciesClickCompletion(ClosingResult, AdditionalParameters) Export
	
	If ClosingResult = Undefined Then 
		Return;
	EndIf;
	
	If TypeOf(ClosingResult) = Type("Structure") Then
		
		LabelCurrenciesClickCompletionServer(ClosingResult);
		If ClosingResult.RecalculateDocumentAmounts Then
			PriceManagementSystemClient.NotifyAboutEndOfConversionOfAmountsIntoCurrency(DocumentCurrency, Object.Currency);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure LabelCurrenciesClickCompletionServer(ClosingResult)
	
	ChangedBankingDetails = ClosingResult.OldValuesOfChangedProps;
	
	If ClosingResult.RecalculateDocumentAmounts Then
		DocumentAmountOnChangeServer(ClosingResult.DocumentAmount);
	EndIf;
	
	If ChangedBankingDetails.Property("Currency") Then
		
		DocumentCurrency = Object.Currency;
		
		FillInSubordinatePropertiesForStatistics("Currency");
		
	EndIf;
	
	If ChangedBankingDetails.Property("ARAPCurrency") Then
		
		FillInDefaultContract();
		
		If UseLinesOfBusiness Then
			
			LinesOfBusinessServer.FillInDefaultDirection(
				Object.LineOfBusiness,, Object.Contract);
			
		EndIf;
		
		PurposeOfContract = GetContractAssignment(Object);
		
	EndIf;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, ChangedBankingDetails, True);
	
EndProcedure

&AtServer
Procedure ReflectChangesToPaymentRules(ChangedBankingDetails)
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, ChangedBankingDetails, True);
	PaymentStepsServer.LoadPaymentStagesFromTemporaryStorage(ThisObject);
	AddSBPPaymentStatusUpdateCommand();
	
EndProcedure

&AtServer
Procedure PlacePaymentStepsInTemporaryStorage(TagName)
	
	PaymentStepsServer.PlacePaymentStepsInTemporaryStorage(ThisObject, TagName);
	
EndProcedure

#EndRegion

#EndRegion

#Region ControlOfInconsistentChanges

&AtClient
Procedure ControlOfNonConsistentChangesHandleEventOnChange(Item)
	
	If Item.Name = "Date" Then
		DateOnChange(Item);
	ElsIf Item.Name = "Partner" Then
		PartnerOnChange(Item);
	ElsIf Item.Name = "Contract" Then
		ContractOnChange(Item);
	ElsIf Item.Name = "PriceIncludesVAT" Then
		PriceIncludesVATOnChange(Item);
	ElsIf Item.Name = "Organization" Then
		OrganizationOnChange(Item);
	ElsIf Item.Name = "Counterparty" Then
		CounterpartyOnChange(Item);
	ElsIf Item.Name = "VATTaxation" Then
		VATTaxationOnChange(Item);
	ElsIf Item.Name = "ManufacturedProductProducts" Then
		ManufacturedProductProductsOnChange(Item);
	ElsIf Item.Name = "ManufacturedProductCharacteristic" Then
		ManufacturedProductCharacteristicOnChange(Item);
	ElsIf Item.Name = "ManufacturedProductSeries" Then
		ManufacturedProductSeriesOnChange(Item);
	ElsIf Item.Name = "ManufacturedProductWarehouse" Then
		ManufacturedProductWarehouseOnChange(Item);
	ElsIf Item.Name = "ManufacturedProductNumberOfPackages" Then
		ManufacturedProductNumberOfPackagesOnChange(Item);
	ElsIf Item.Name = "ManufacturedProductPackage" Then
		ManufacturedProductPackageOnChange(Item);
	ElsIf Item.Name = "ManufacturedProductPriceKind" Then
		ManufacturedProductPriceKindOnChange(Item);
	ElsIf Item.Name = "ManufacturedProductPrice" Then
		ManufacturedProductPriceOnChange(Item);
	ElsIf Item.Name = "ManufacturedProductSum" Then
		ManufacturedProductSumOnChange(Item);
	ElsIf Item.Name = "ManufacturedProductVATRate" Then
		ManufacturedProductVATRateOnChange(Item);
	ElsIf Item.Name = "ManufacturedProductVATAmount" Then
		ManufacturedProductVATAmountOnChange(Item);
	ElsIf Item.Name = "ManufacturedProductToExpenseAs" Then
		ManufacturedProductToExpenseAsOnChange(Item);
	ElsIf Item.Name = "ManufacturedProductExpenseItem" Then
		ManufacturedProductExpenseItemOnChange(Item)
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
	EndIf;
	
EndProcedure

&AtClient
Procedure ControlOfNonConsistentChangesHandleCommandEvent(Command)
	
	If Command.Name = "InsertRows" Then
		InsertRows(Command);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Command);
	EndIf;
	
EndProcedure

&AtClient
Procedure ControlOfNonConsistentChangesHandlePushEvent(Item)
	
	TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeStartingChange(Item, Cancel)
	
	If Item.Name = "ManufacturedProduct" Then
		FillPropertyValues(PreviousRowDetails, Items.ManufacturedProduct.CurrentData);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
	EndIf;
	
EndProcedure

&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeDeletion(Item, Cancel)
	
	If Item.Name = "ManufacturedProduct" Then
		Return;
	EndIf;
	
	TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeStartingAdding(Item, Cancel, Copy, Parent, Var_Group)
	
	If Item.Name = "ManufacturedProduct" Then
		Return;
	EndIf;
	
	TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
	
EndProcedure

// Parameters:
// 	Item - FormField - Item
&AtClient
Procedure Attachable_WhenChanging_SetAvailabilityOfItemsByStatusServer(Item)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisObject) Then
		Return;
	EndIf;
	
	If StructureOfActionsControlOfNonAgreedChanges.OnChange.Property(Item.Name) Then
		ControlOfNonConsistentChangesHandleEventOnChange(Item);
	EndIf;
	
EndProcedure

// Parameters:
// 	Item - FormField - Item
&AtClient
Procedure Attachable_Clicking_SetAvailabilityOfItemsByStatusServer(Item)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisObject) Then
		Return;
	EndIf;
	
	If StructureOfActionsControlOfNonAgreedChanges.Click.Property(Item.Name) Then
		ControlOfNonConsistentChangesHandlePushEvent(Item);
	EndIf;

EndProcedure

// Parameters:
// 	Command - FormCommand - Command
&AtClient
Procedure Attachable_Command_SetAvailabilityOfItemsByStatusServer(Command)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisObject) Then
		Return;
	EndIf;
	
	If StructureOfActionsControlOfNonAgreedChanges.Commands.Property(Command.Name) Then
		ControlOfNonConsistentChangesHandleCommandEvent(Command);
	EndIf;
	
EndProcedure

// Parameters:
// 	Item - FormTable - form table
// 	Cancel - Boolean
&AtClient
Procedure Attachable_BeforeStartingChange_SetAvailabilityOfItemsByStatusServer(Item, Cancel)
	
	If StructureOfActionsControlOfNonAgreedChanges = Undefined Then
		Return;
	EndIf;
	
	FillPropertyValues(StructureOfActionsControlOfNonAgreedChanges.AttributesValues[Item.Name], Item.CurrentData);
	
	If StructureOfActionsControlOfNonAgreedChanges.BeforeRowChange.Property(Item.Name) Then
		ControlOfNonConsistentChangesHandleEventBeforeStartingChange(Item, Cancel);
	EndIf;

EndProcedure

// Parameters:
// 	Item - FormTable - form table
// 	Cancel - Boolean
&AtClient
Procedure Attachable_BeforeDeleting_SetAvailabilityOfItemsByStatusServer(Item, Cancel)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisObject) Then
		Return;
	EndIf;
	
	Name = Item.Name;
	If StructureOfActionsControlOfNonAgreedChanges.BeforeDeleteRow.Property(Name) Then
		ControlOfNonConsistentChangesHandleEventBeforeDeletion(Item, Cancel);
	EndIf;

EndProcedure

// Parameters:
// 	Item - FormTable - form table
// 	Cancel - Boolean
// 	Copy - Boolean
// 	Parent - FormGroup
// 	Var_Group - Boolean
&AtClient
Procedure Attachable_BeforeYouStartAdding_SetAvailabilityOfItemsByStatusServer(
			Item, Cancel, Copy, Parent, Var_Group)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisObject) Then
		Return;
	EndIf;
	
	Name = Item.Name;
	If StructureOfActionsControlOfNonAgreedChanges.BeforeAddRow.Property(Name) Then
		ControlOfNonConsistentChangesHandleEventBeforeStartingAdding(
			Item, Cancel, Copy, Parent, Var_Group);
	EndIf;

EndProcedure

&AtClient
Procedure Attachable_WhenChangingDetailsDependingOnStatus()
	
	SetAvailabilityOfItemsByStatusServer();
	TMCommonUseClient.AfterChangingPropsDependentOnStatus(ThisObject);
	
EndProcedure

#EndRegion

#Region WorkingWithClipboard

&AtServer
Procedure CopyLinesOnServer()
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object.ManufacturedProduct, Items.ManufacturedProduct.SelectedRows);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboard()
	
	If ManufacturedProductsProduced
		And Not WorksAreBeingCarriedOut Then
		ItemsTypes = ProductsClientServer.SelectionByProductMultiTurnContainer(False);
	ElsIf Not ManufacturedProductsProduced
		And WorksAreBeingCarriedOut Then
		ItemsTypes = ProductsClientServer.JobSelection(False);
	Else
		ItemsTypes = ProductsClientServer.SelectionByProductReusablePackagingWork(False);
	EndIf;
	
	FilterParameters = New Map;
	FilterParameters.Insert("Products.ItemsType", ItemsTypes);
	
	Columns = "Products,
			  |Characteristic,
			  |Package,
			  |NumberOfPackages,
			  |Count,
			  |PriceKind,
			  |Price,
			  |Warehouse,
			  |Department";

	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);

	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	VATRateIsIndicatedInTablePart = VATRateIsIndicatedInTablePart(Object.BusinessOperation);
	
	RowsToProcess = New Array;
	ProcessedRowsWithPrice = New Array;
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.ManufacturedProduct.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);
		
		If Not VATRateIsIndicatedInTablePart Then
			CurrentRow.VATRate = Object.VATRate;
		EndIf;
		
		UpdateOrderDeviationsInLine(CurrentRow, Object.ReportOnOrders);
		
		If ValueIsFilled(CurrentRow.Price) And Not ValueIsFilled(CurrentRow.PriceKind) Then
			ProcessedRowsWithPrice.Add(CurrentRow);
		Else
			CurrentRow.Price = 0;
			RowsToProcess.Add(CurrentRow);
		EndIf;
		
	EndDo;
	
	StructureOfActions = New Structure;
	AddToStructureActionsToUpdateVspAttributesOfLine(StructureOfActions);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	AddActionsClearFillArticleAnalytics(StructureOfActions, ThisObject);
	
	If VATRateIsIndicatedInTablePart Then
		AddActionToStructureFillInVATRate(Object, StructureOfActions);
	EndIf;
	
	StructureOfActions.Insert(
		"CheckFillWarehouse",
		BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	
	StructureOfActions.Insert("CheckFillAssignment", PurposeOfContract);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ProcessedRowsWithPrice,
		StructureOfActions,
		Object.ManufacturedProduct);
	
	ParametersForFillingInPriceType = BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceTypeInTSLine("PriceKind");
	ParametersForFillingInPriceType.DefaultPriceType = DefaultPriceType;
	ParametersForFillingInPriceType.FilterParameters.PriceIncludesVAT = Object.PriceIncludesVAT;
	ParametersForFillingInPriceType.FilterParameters.UseWhileTransferringProductsToMaterialProvider = True;
	StructureOfActions.Insert("CheckFillInPriceView", ParametersForFillingInPriceType);
	
	StructureOfActions.Insert(
		"FillInSalePrice",
		BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.ManufacturedProduct);
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	WhenChangingWarehouseInTablePartServer();
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfClipboardCommands()
	
	ItemArray = New Array();
	ItemArray.Add("ManufacturedProductInsertRows");
	ItemArray.Add("ManufacturedProductContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items,
		ItemArray,
		"Enabled",
		ProcessingOfTabularForms.ThereAreLinesInClipboard());
	
EndProcedure

&AtClient
Procedure SetAvailabilityOfClipboardCommandsOnClient(Var_Enabled)
	
	ItemArray = New Array();
	ItemArray.Add("ManufacturedProductInsertRows");
	ItemArray.Add("ManufacturedProductContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items,
		ItemArray,
		"Enabled",
		Var_Enabled);
	
EndProcedure

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

#EndRegion

#Region WorkingWithCounterparties





&AtClient
Procedure CheckCounterparties(Command)
	
	Return;
	
EndProcedure

#EndRegion

&AtClient
Procedure DateOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	Var PricesCalculated;
	
	If Not QuestionResult = DialogReturnCode.Cancel Then
		WhenChangingDateServer(QuestionResult, PricesCalculated);
	EndIf;
	
EndProcedure

&AtServer
Procedure PlacePaymentDecryptionInTemporaryStorage()
	ARAPAccountingFormWork.PlacePaymentDecryptionInTemporaryStorage(ThisObject);
EndProcedure

&AtServer
Procedure FillBaseForPrinting()
	
	If Not BasisChanged Then
		BaseStructure = Documents.ReportToMaterialProvider2_5.StructureOfBaseForPrinting(Object);
		FillPropertyValues(Object, BaseStructure);
	EndIf;
	
	PrintBasisTable.Load(Documents.ReportToMaterialProvider2_5.PrintBasisTable(Object));
	
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
