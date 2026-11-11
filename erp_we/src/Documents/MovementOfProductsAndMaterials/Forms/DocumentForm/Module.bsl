#Region Variables

&AtClient
Var CachedValues;

&AtClient
Var CurDataId;

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
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
		
	ElsIf Parameters.FillingValues.Property("FillByWarehouseDocument") Then
		
		SetShopPantryAttribute("Sender");
		SetShopPantryAttribute("Recipient");
		
		RefillByNotes(Parameters.FillingValues);
		Modified = True;
		
	EndIf;
	
	If TypeOf(Object.ReferenceOrder) = Type("DocumentRef.OrderOfMaterialsForProduction") Then
		AvailableUpdate = AccessRight("Update", Metadata.Documents.OrderOfMaterialsForProduction);
	Else
		AvailableUpdate = AccessRight("Update", Metadata.Documents.ProductionStage2_2);
	EndIf;
	
	Items.CloseOrder.Enabled  = AvailableUpdate;
	Items.CloseOrders_2.Enabled = AvailableUpdate;
	
	FillInListOfOperations();
	If Items.BusinessOperation.ChoiceList.Count() = 1 Then
		Items.BusinessOperation.Visible = False;
	EndIf;
	
	SetAvailabilityOfClipboardCommands();
	
	#Region UniversalMechanisms
	
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	#EndRegion
	
	DocumentCorrection.OnCreateAtServer(ThisForm, Items.LineCorrection);
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisForm);
	
	SetVisibilityOfInputCommandsBasedOn_();
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	DocumentCorrection.OnReadAtServer(ThisForm, Items.LineCorrection);
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	OnReadCreateAtServer();

	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If UpdateOnOpening Then
		OnReadCreateAtServer();
	EndIf;
	
	ReportResults();
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	
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
Procedure OnClose()
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	RefreshFormTitle();
	
	FillInServiceDetailsOfTablePart();
	
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	Var CurrentOperation1;
	
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
		
	ElsIf ChoiceSource.FormName = "Document.OrderOfMaterialsForProduction.Form.ChoiceForm" Then
		
		CurrentData = Items.Goods.CurrentData;
		
		If Not CurrentData.ReferenceOrder = ValueSelected Then
			CurrentData.ReferenceOrder = ValueSelected;
			Modified = True;
			UpdateOrderInformation();
		EndIf;
		
	Else
		
		ProcessingSelectionOfProductsOnServer(ValueSelected);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "CopyingLinesToClipboard" Then
		SetAvailabilityOfClipboardCommandsOnClient();
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
	
	// Handler of the "Properties" mechanism
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	
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
	
	NotificationProcessingParameter = CommonClient.CopyRecursive(WriteParameters);
	If TypeOf(FormOwner) = Type("ClientApplicationForm") Then
		IdOfOwnerSForm = FormOwner.UUID;
	Else
		IdOfOwnerSForm = Undefined;
	EndIf;
	NotificationProcessingParameter.Insert("IdOfOwnerSForm", IdOfOwnerSForm);
	NotificationProcessingParameter.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
	Notify("Write_MovementOfProductsAndMaterials", NotificationProcessingParameter, Object.Ref);
	
	
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
	
	If WriteParameters.WriteMode = DocumentWriteMode.Posting
		And (Not Object.ByReferences
			Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferOfMaterialsToStoreroom")) Then
			
		Cancel = True;
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("WriteParameters", WriteParameters);
		
		ReusablePackageClient.OfferToPickUpMultiTurnContainer(
			ThisForm,
			"Goods",
			"Products,Characteristic,Count",
			New CallbackDescription("BeforeRecordingOfferToPickUpMultiTurnContainer", ThisObject, AdditionalParameters));
		
	EndIf;
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters, Cancel);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties

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
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOnChangeServer();
	
EndProcedure

&AtClient
Procedure DateOfReceiptOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOfReceiptOnChangeATServer();
	
EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	
	If SeriesSpecificationParameters.UseItemsBatch Then
		
		If YouCanPopulateSeriesByShipment
			And Object.Status = PredefinedValue("Enum.StatusesOfProductsAndMaterialMovement.Accepted") Then
			
			QueryText = NStr("vi = 'Điền sê-ri theo dữ liệu phiếu xuất kho?';
							|ru = 'Заполнить серии по данным расходных ордеров?';
							|en = 'Fill in batch according to goods issue note data?'; fa = 'Fill in batch according to goods issue note data?';
							|it = 'Compilare le serie in base ai dati dei mandati di pagamento?';
							|pl = 'Uzupełnij serię zgodnie z danymi zestawień wydatków?';
							|tr = 'Ambar çıkış fişlerine göre partiler doldurulsun mu?'");
			ShowQueryBox(New CallbackDescription("StatusOnChangeCompletion", ThisObject), QueryText,QuestionDialogMode.YesNo,,DialogReturnCode.Yes);
			Return;
			
		EndIf;
		
		StatusOnChangeServer(False);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure StatusOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	FillInShippingInstructions = False;
	
	If QuestionResult = DialogReturnCode.Yes Then
		FillInShippingInstructions = True;
	EndIf;
	
	StatusOnChangeServer(FillInShippingInstructions);
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	If BusinessTransactionBeforeChange = Object.BusinessOperation Then
		Return;
	EndIf;
	
	ByOrdersBeforeChange = Object.ByReferences;
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferOfProductsFromProduction")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnOfMaterialsFromProduction")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.MaterialTransferToProduction") Then
		Object.ByReferences = True;
	ElsIf Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferOfProductsFromStoreroom")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnOfMaterialsFromStoreroom")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferOfSemiFinishedProducts")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices") Then
		Object.ByReferences = False;
	EndIf;
	
	If Object.ByReferences And ShipmentStarted Then
		
		WarningText = NStr("vi = 'Theo chứng từ này đã bắt đầu giao hàng.
										|Không thể thay đổi giao dịch kinh tế.';
										|ru = 'По данному документу уже начата отгрузка.
										|Изменять хоз.операцию не допускается.';
										|en = 'Shipment has already started under this document.
										|Cannot change the business transaction.'; fa = 'Shipment has already started under this document.
										|Cannot change the business transaction.';
										|it = 'La spedizione per questo documento è già iniziata.
										|Non è consentito modificare l''operazione commerciale.';
										|pl = 'Według tego dokumentu już jest zaczęta wysyłka. 
										|Zmiana operacji gospodarczej nie jest dopuszczalna.';
										|tr = 'Mevcut belgeye göre sevkiyat başlatılmıştır.
										|Ticari işlemin değiştirilmesine izin verilmemektedir.'");
		ShowMessageBox(, WarningText);
		Object.ByReferences = ByOrdersBeforeChange;
		Object.BusinessOperation = BusinessTransactionBeforeChange;
		Return;
		
	ElsIf ByOrdersBeforeChange Then
		
		UntieDocumentFromOrders = Not Object.ByReferences
			Or BusinessTransactionBeforeChange = PredefinedValue("Enum.BusinessTransactions.TransferOfMaterialsToStoreroom")
			Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferOfMaterialsToStoreroom");
		
		If UntieDocumentFromOrders
			And ThereAreLinesTiedToOrder() Then
			
			If ValueIsFilled(Object.ReferenceOrder) Then
				QueryText = NStr("vi = 'Các dòng Chứng từ sẽ không còn được liên kết với các dòng thứ tự. Tiếp tục?';
								|ru = 'Строки документа перестанут быть связанными со строками распоряжения. Продолжить?';
								|en = 'Document lines will not be linked to the reference lines anymore. Continue?'; fa = 'Document lines will not be linked to the reference lines anymore. Continue?';
								|it = 'Le righe del documento non saranno più associate alle righe della disposizione. Continuare?';
								|pl = 'Wiersze dokumentu przestaną być powiązanymi z wierszami zamówienia. Kontynuować?';
								|tr = 'Belge satırları, talimat satırlarıyla ilişkilendirilmeyecektir. Devam edilsin mi?'");
			Else
				QueryText = NStr("vi = 'Các dòng Chứng từ sẽ không còn được liên kết với các dòng thứ tự. Tiếp tục?';
								|ru = 'Строки документа перестанут быть связанными со строками распоряжений. Продолжить?';
								|en = 'Document lines will not be linked with the reference lines anymore. Continue?'; fa = 'Document lines will not be linked with the reference lines anymore. Continue?';
								|it = 'Le righe del documento non saranno più associate alle righe delle disposizioni. Continuare?';
								|pl = 'Wiersze dokumentu przestaną być powiązanymi z wierszami zamówień. Kontynuować?';
								|tr = 'Belge satırları, talimat satırlarıyla ilişkilendirilmeyecektir. Devam edilsin mi?'");
			EndIf;
			
			CallbackDescription = New CallbackDescription("BusinessTransactionOnChangeEnd", ThisObject, ByOrdersBeforeChange);
			ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
			Return;
			
		EndIf;
		
	EndIf;
	
	BusinessOperationWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure ByReferencesOnChange(Item)
	
	If Object.ByReferences And ShipmentStarted Then
		
		WarningText = NStr("vi = 'Chứng từ này đã bắt đầu giao hàng. Đặt cờ là không thể.';
							|ru = 'По данному документу уже начата отгрузка. Установка признака невозможна.';
							|en = 'Shipment has already started by this document. Cannot select the flag.'; fa = 'Shipment has already started by this document. Cannot select the flag.';
							|it = 'La spedizione per questo documento è già iniziata. Impossibile impostare un criterio.';
							|pl = 'Według tego dokumentu już jest rozpoczęta wysyłka. Ustawienie znaku jest niemożliwe.';
							|tr = 'Mevcut belgeye göre sevkiyat başlatılmıştır. İşaretin yapılandırılması mümkün değildir.'");
		ShowMessageBox(, WarningText);
		Object.ByReferences = False;
		Return;
		
	EndIf;
	
	If Object.ByReferences Then
		
		If Object.Goods.Count() = 0 Then
			QueryText = NStr("vi = 'Danh sách các Sản phẩm và Nguyên vật liệu sẽ được bổ sung với phần còn lại của hàng hóa chưa được định dạng theo đơn đặt hàng. Tiếp tục?';
							|ru = 'Список Продукция и материалы будет перезаполнен остатками неоформленных товаров по распоряжениям. Продолжить?';
							|en = 'The Products and materials list will be overwritten with remaining unregistered goods by references. Continue?'; fa = 'The Products and materials list will be overwritten with remaining unregistered goods by references. Continue?';
							|it = 'L''elenco Prodotti e materiali sarà ricompilato con rimanenze delle merci non formalizzate per disposizioni. Continuare?';
							|pl = 'Lista Wiersze pozycji i materiały będzie wypełniona ponownie ostatkami niesporządzonych wierszy pozycji według zamówień. Kontynuować?';
							|tr = 'İmal Edilen Ürünler ve Malzemeler listesi, düzenlenmemiş ürün bakiyeleri ile talimatlara göre yeniden doldurulacaktır. Devam edilsin mi?'");
		Else
			QueryText = NStr("vi = 'Các dòng trong danh sách Hàng hóa và nguyên vật liệu sẽ được gắn với các dòng đặt hàng. Tiếp tục?';
							|ru = 'Строки в списке Продукция и материалы будут привязаны к строкам распоряжений. Продолжить?';
							|en = 'Lines in the Products and materials list will be linked to reference lines. Continue?'; fa = 'Lines in the Products and materials list will be linked to reference lines. Continue?';
							|it = 'Le righe dell''elenco Prodotti e i materiali saranno collegate alle righe delle disposizioni. Continuare?';
							|pl = 'Wiersze na liście Wiersze pozycji i materiały będą przywiązane do wierszy zamówień. Kontynuować?';
							|tr = 'İmal Edilen Ürünler ve Malzemeler listesindeki satırlar, talimat satırlarına bağlanacaktır. Devam edilsin mi?'");
		EndIf;
		
	Else
		
		If ThereAreLinesTiedToOrder() Then
			
			QueryText = NStr("vi = 'Các dòng trong danh sách Hàng hóa và nguyên vật liệu sẽ không còn được liên kết với các dòng đơn hàng. Tiếp tục?';
							|ru = 'Строки в списке Продукция и материалы перестанут быть связанными со строками распоряжений. Продолжить?';
							|en = 'Lines in the Products and materials list will not be linked with reference lines. Continue?'; fa = 'Lines in the Products and materials list will not be linked with reference lines. Continue?';
							|it = 'Le righe dell''elenco Prodotti e i materiali non saranno più collegate alle righe delle disposizioni. Continuare?';
							|pl = 'Wiersze na liście Wiersze pozycji i maeriały przestaną być powiązanymi z wierszami zamówień. Kontynuować?';
							|tr = 'İmal Edilen Ürünler ve Malzemeler listesindeki satırlar, talimat satırlarıyla ilişkilendirilmeyecektir. Devam edilsin mi?'");
			
		Else
			
			OnOrdersWhenChangingOnServer();
			Return;
			
		EndIf;
		
	EndIf;
	
	ShowQueryBox(New CallbackDescription("ByReferencesOnChangeCompletion", ThisObject), QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	If Not CompanyBeforeChange = Object.Organization Then
		OrganizationWhenChangedOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure CompanyRecipientOnChange(Item)
	
	RecipientOrganizationWhenModifiedOnServer();
	
EndProcedure

&AtClient
Procedure SenderOnChange(Item)
	
	If Object.Sender <> SenderBeforeChange 
		And (Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.MaterialTransferToProduction")
			Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferOfMaterialsToStoreroom"))
		And Object.ByReferences And Object.Goods.Count() > 0 Then
		
		QueryText = NStr("vi = 'Danh sách ""Nguyên vật liệu"" sẽ bị xóa. Tiếp tục?';
						|ru = 'Список ""Материалы"" будет очищен. Продолжить?';
						|en = 'The ""Materials"" list will be cleared. Continue?'; fa = 'The ""Materials"" list will be cleared. Continue?';
						|it = 'L''elenco ""Materiali"" verrà cancellato. Continuare?';
						|pl = 'Lista ""Materiałów"" zostanie wyczyszczona. Kontynuować?';
						|tr = '""Malzemeler"" listesi temizlenecektir. Devam edilsin mi?'");
		CallbackDescription = New CallbackDescription("SenderOnChangeCompletion", ThisObject);
		ButtonsList = New ValueList;
		ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Xóa và tiếp tục';
													|ru = 'Очистить и продолжить';
													|en = 'Clear and continue'; fa = 'Clear and continue';
													|it = 'Cancellare e continuare';
													|pl = 'Oczyść i kontynuuj';
													|tr = 'Temizle ve devam et'"));
		ButtonsList.Add(DialogReturnCode.Cancel);
		ShowQueryBox(CallbackDescription, QueryText, ButtonsList);
		Return;
		
	EndIf;
	
	SenderOnChangeServer();
	
EndProcedure

&AtClient
Procedure RecipientOnChange(Item)
	
	RecipientOnChangeServer(True);
	
EndProcedure

&AtClient
Procedure LabelReferencesClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	FormParameters = New Structure;
	FormParameters.Insert("DocumentsList", ListOfOrders_);
	FormParameters.Insert("Title", NStr("vi = 'Lệnh (%DocumentsCount%)';
										|ru = 'Распоряжения (%DocumentsCount%)';
										|en = 'References (%DocumentsCount%)'; fa = 'References (%DocumentsCount%)';
										|it = 'Disposizioni (%DocumentsCount%)';
										|pl = 'Zamówienia (%DocumentsCount%)';
										|tr = 'Talimatlar (%DocumentsCount%)'"));
	OpenForm("CommonForm.ViewingListOfDocuments", FormParameters, ThisForm,,,,, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

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
Procedure LineOfBusinessOnChange(Item)
	
	If Object.BusinessOperation <> PredefinedValue("Enum.BusinessTransactions.TransferOfMaterialsToStoreroom") Then
		
		LineOfBusinessOnChangeServer();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PriceKindOnChange(Item)
	
	If UseTargetCost Then
		ThereAreLinesToChange = Object.Goods.Count() > 0;
	Else
		FIlter_By_Type = New Structure("SideProduct",
			False);
		RowsArray = Object.Goods.FindRows(FIlter_By_Type);
		ThereAreLinesToChange = RowsArray.Count() > 0;
	EndIf;
	
	If ValueIsFilled(Object.PriceKind) And ThereAreLinesToChange Then
		
		CallbackDescription = New CallbackDescription("PriceKindOnChangeCompletion", ThisForm);
		QueryText = NStr("vi = 'Điền lại giá hàng hóa?';
						|ru = 'Перезаполнить цены товаров?';
						|en = 'Refill goods prices?'; fa = 'Refill goods prices?';
						|it = 'Ricompilare i prezzi delle merci?';
						|pl = 'Wypełnić ponownie ceny towarów?';
						|tr = 'Ürün fiyatları yeniden doldurulsun mu?'");
		
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PriceKindOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		
		PricesCalculated = FillInPricesByPriceKindServer(Object.PriceKind);
		SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, Object.PriceKind);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	
	If PriceManagementSystemClient.CurrencyConversionRequired(Object, DocumentCurrency) Then
		CurrencyOnChangeServer();
		PriceManagementSystemClient.NotifyAboutEndOfConversionOfAmountsIntoCurrency(DocumentCurrency, Object.Currency);
	EndIf;
	
	DocumentCurrency = Object.Currency;
	
EndProcedure

&AtClient
Procedure InternalSubcontractingOnChange(Item)
	If Not Object.InternalSubcontracting Then
		Object.MaterialProviderCompany = Undefined;
		CompanyGiverBeforeChange = Object.MaterialProviderCompany;
	EndIf;
	
	ConfigureDependentElementsOfInternalProcessing(ThisObject, "InternalSubcontracting");
	Return;
	
EndProcedure

&AtClient
Procedure MaterialProviderCompanyOnChange(Item)
	If ValueIsFilled(Object.MaterialProviderCompany)
		And Object.MaterialProviderCompany = Object.Organization Then
		
		MessageText = NStr("vi = 'Doanh nghiệp-người đặt gia công không thể trùng với doanh nghiệp-người nhận gia công.';
							|ru = 'Организация-давалец не может совпадать с организацией-переработчиком.';
							|en = 'Material provider company and the subcontractor company cannot be the same.'; fa = 'Material provider company and the subcontractor company cannot be the same.';
							|it = 'Организация-давалец не может совпадать с организацией-переработчиком.';
							|pl = 'Material provider company and the subcontractor company cannot be the same.';
							|tr = 'Tedarikçi iş yeri ile fason üretici iş yeri aynı olamaz.'");
		CommonClient.MessageToUser(MessageText,, "MaterialProviderCompany", "Object");
		
		Object.MaterialProviderCompany = CompanyGiverBeforeChange;
		
		Return;
		
	EndIf;
	
	If Not CompanyGiverBeforeChange = Object.MaterialProviderCompany Then
		CompanyGivesGiverWhenChangeIsMadeOnServer();
	EndIf;
	Return;
	
EndProcedure

&AtClient
Procedure CloseStage(Command)
	
	If Modified Or Not Object.Posted Then
		ShowQueryBox(New CallbackDescription("CloseStageCompletion", ThisObject),
						NStr("vi = 'Cần kết chuyển chứng từ để hoàn thành giao dịch. Kết chuyển chứng từ?';
							|ru = 'Необходимо провести документ для выполнения операции. Провести документ?';
							|en = 'To proceed, you need to post the document. Do you want to post the document?'; fa = 'To proceed, you need to post the document. Do you want to post the document?';
							|it = 'È necessario registrare il documento per eseguire operazione. Registrare documento?';
							|pl = 'Należy zaksięgować dokument aby wykonać operację. Zaksięgować dokument?';
							|tr = 'İşlemin gerçekleştirilmesi için belgenin kaydedilmesi gerekmektedir. Belge kaydedilsin mi?'"),QuestionDialogMode.YesNo);
		Return;
	EndIf;
	
	CloseStageFragment();
	
EndProcedure

&AtClient
Procedure CloseStageCompletion(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	If Response = DialogReturnCode.No Then
		Return;
	ElsIf Not Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
		Return;
	EndIf;
	
	CloseStageFragment();
	
EndProcedure

&AtClient
Procedure CloseStageFragment()
	
	PerformanceMonitorClient.TimeMeasurement(
		"Document.MovementOfProductsAndMaterials.DocumentForm.Command.CloseStageFragment");
	
	ListOfOrdersToClose = New ValueList;
	If ValueIsFilled(Object.ReferenceOrder) Then
		ListOfOrdersToClose.Add(Object.ReferenceOrder)
	Else
		ListOfOrdersToClose.LoadValues(ListOfOrders_.UnloadValues())
	EndIf;
	
	ClosureStructure = New Structure;
	ClosureStructure.Insert("Orders",                       ListOfOrdersToClose);
	ClosureStructure.Insert("DocumentInitiator",            Object.Ref);
	ClosureStructure.Insert("CancelUnprocessedLines", True);
	ClosureStructure.Insert("CloseOrders",              True);
	
	OpenForm("DataProcessor.OrderClosureWizard.Form.ClosureForm", ClosureStructure,
					ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure VATTaxationClearing(Item, StandardProcessing)
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

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData; 
	
	If CurrentRow <> Undefined Then
		UpdateDeviationsFromOrderInLine(CurrentRow, Object.ByReferences, Object.BusinessOperation);
		
		UpdateInformationOnDeviationFromOrders(
			Object.Goods,
			LabelDiscrepancy, 
			Items.PictureDiscrepancy1,
			Items.PictureDiscrepancy2);
			
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.GoodsReferenceOrder Then
		If ValueIsFilled(Items.Goods.CurrentData.ReferenceOrder) Then
			ShowValue(Undefined, Items.Goods.CurrentData.ReferenceOrder);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	If ByStep
		And Copy Then
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
	WarehousesClient.UpdateCachedValues(Item, CachedValues, SeriesSpecificationParameters, Copy);
	
EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	CurrentData = Items.Goods.CurrentData;
	
	UpdateSeriesStatuses = ProductsClient.SeriesStatusesNeedToBeUpdated(
		Item, CachedValues, SeriesSpecificationParameters);
	
	AdditionalParameters = New Structure;
	FormEventsClient.WhenChangingElement(ThisObject, Items.Goods, AdditionalParameters);
	
	If AdditionalParameters.Property("ServerCallRequired__") Or UpdateSeriesStatuses Then
		GoodsAtEndOfEditingOnServer(
			AdditionalParameters.Property("ServerCallRequired__"),
			?(UpdateSeriesStatuses, CurrentData.GetID(), Undefined),
			CachedValues);
	EndIf;
	
	If UpdateSeriesStatuses Then
		ProductsClient.UpdateCachedValuesToAccountForSeries(Item,CachedValues,SeriesSpecificationParameters);
	EndIf;
	
	ReusablePackageClient.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
	UpdateInformationOnDeviationFromOrders(
		Object.Goods,
		LabelDiscrepancy, 
		Items.PictureDiscrepancy1,
		Items.PictureDiscrepancy2);
	
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
	GoodsAfterDeleteRowServer(SeriesStatusesNeedToBeUpdated, CachedValues);
	If SeriesStatusesNeedToBeUpdated Then
		ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters);
	EndIf;
	
	ReusablePackageClient.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
		
	StructureOfActions = New Structure;
	AddActionRecalculateNumberOfUnits(ThisObject, StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingProducts(ThisObject, CurrentRow, StructureOfActions);
	AddQualityControlActionsToStructure(StructureOfActions, CacheQualityControl);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	
	SupplyClientServer.StructureOfInsertActionsWhenChangingAssignment(StructureOfActions);
	
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
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
Procedure GoodsNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(ThisObject, StructureOfActions);

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsPriceOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	
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
Procedure GoodsPurposeOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	CurrentData.AssignmentSender = CurrentData.Purpose;
	
EndProcedure

&AtClient
Procedure GoodsReferenceOrderStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	CurrentData = Items.Goods.CurrentData;
	If ValueIsFilled(CurrentData.ReferenceOrder) Then
		Return;
	EndIf;
	
	If CurrentData <> Undefined Then
		
		FilterParameters = New Structure();
		FilterParameters.Insert("Posted",              True);
		FilterParameters.Insert("Organization",           Object.Organization);
		FilterParameters.Insert("Warehouse",                 Object.Sender);
		FilterParameters.Insert("ShopFloorStockroom",       Object.Recipient);
		FilterParameters.Insert("BusinessOperation", Object.BusinessOperation);
		
		OpenForm("Document.OrderOfMaterialsForProduction.Form.ChoiceForm",
			New Structure("Filter", FilterParameters), ThisForm);
		
		Return;
		
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
Procedure SelectGoods(Command)
	
	If Not ValueIsFilled(Object.Sender) Then
		ClearMessages();
		CommonClientServer.MessageToUser(NStr("vi = 'Chưa điền trường ""Kho bãi""';
												|ru = 'Поле ""Склад"" не заполнено';
												|en = 'Warehouse is required'; fa = 'انبار الزامی است';
												|it = 'Il campo ""Magazzino"" non è compilato';
												|pl = 'Nie wypełniono pola ""Magazyn""';
												|tr = '""Ambar"" alanı doldurulmadı'"), Object.Ref, "Object.Sender");
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Warehouse",                                     Object.Sender);
	FormParameters.Insert("SelectionModeWithoutAmountParameters",         True);
	FormParameters.Insert("HideTheViewPriceColumn",                    True);
	FormParameters.Insert("HideTheItemPricesCommand",           True);
	FormParameters.Insert("FilterByProductType",                   New FixedArray(ProductsClientServer.SelectionByProductMultiTurnContainer(False)));
	FormParameters.Insert("Title",                                 NStr("vi = 'Chọn hàng hóa';
																		|ru = 'Подбор товаров';
																		|en = 'Pick goods'; fa = 'انتخاب کالاها';
																		|it = 'Selezione delle merci';
																		|pl = 'Wybór towarów';
																		|tr = 'Ürünlerin seçimi'"));
	FormParameters.Insert("Date",                                      Object.Date);
	FormParameters.Insert("Document",                                  Object.Ref);
	FormParameters.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters);
	
	OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form", FormParameters, ThisForm, UUID);
	
EndProcedure

&AtClient
Procedure SelectGoodsByOrdersNotes(Command)
	
	OpenSelectionByOrdersOrders();
	
EndProcedure

&AtClient
Procedure SearchByBarcodeExecute(Command)
	
	ClearMessages();
	Notification = New CallbackDescription("SearchByBarcodeCompletion", ThisObject);
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);
	
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
		AddActionsToStructureWhenChangingPackagesNumber(ThisObject, StructureOfActions);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	Else
		EquipmentManagerTMClient.ReportError(ExecutionResult);
	EndIf;
	
EndProcedure

&AtClient
Procedure ImportDataFromPDT(Command)
	
	ClearMessages();
	
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
Procedure UnlinkFromOrder(Command)
	
	SelectedRows = Items.Goods.SelectedRows;
	If SelectedRows.Count()>0 Then
		
		UntieSelectedLinesFromOrder();
		
		NotifyAboutEndOfUnbindingLines(SelectedRows.Count());
		
	Else
		
		WarningText = NStr("vi = 'Hãy chọn dòng cần hủy liên kết với các lệnh.';
							|ru = 'Выберите строки, которые необходимо отвязать от распоряжений.';
							|en = 'Select lines which should be unlinked from references.'; fa = 'Select lines which should be unlinked from references.';
							|it = 'Selezionare le righe da scollegare dalle disposizioni.';
							|pl = 'Wybierz wierze, które należy odłączyć od zamówień.';
							|tr = 'Talimatlardan çıkarılması gereken satırları seçin.'");
		ShowMessageBox(Undefined, WarningText);
		
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
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm, True);
	
EndProcedure

&AtClient
Procedure SetDeletionMarkForADocument(Command)
	
	TMCommonUseClient.SetDeletionMarkForADocument(ThisForm);
	
EndProcedure

&AtClient
Procedure FillInSeriesByFEFO(Command)
	
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
Procedure OpenInventoryKinds(Command)

	OptionsForEditingInventoryTypes = PutGoodsAndStockTypesInStorage();
	FinancesClient.OpenInventoryKinds(ThisObject, OptionsForEditingInventoryTypes);

EndProcedure

&AtClient
Procedure ChangeTheQualityOfTheItem(Command)
	
	CurrentRow = Items.Goods.CurrentData;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("ChangeQuality");
	
	If ValueIsFilled(CurrentRow.Characteristic) Then
		StructureOfActions.Insert("FillInDescriptionOfPoorQualityProduct", CurrentRow.Characteristic);
	EndIf;
	If ValueIsFilled(CurrentRow.Package) Then
		StructureOfActions.Insert("FillInPackagingOfLowQualityGoods", CurrentRow.Package);
	EndIf;
	AddActionsToStructureWhenChangingProducts(ThisForm, CurrentRow, StructureOfActions);
	AddQualityControlActionsToStructure(StructureOfActions, CacheQualityControl);
	
	WarehousesClient.ChangeQuality(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure RoundToTheWholePackage(Command)
	
	If Items.Goods.SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	TotalRows = 0;
	For Each RowID In Items.Goods.SelectedRows Do
		RowData = Object.Goods.FindByID(RowID);
		If Int(RowData.NumberOfPackages) = RowData.NumberOfPackages Then
			Continue;
		EndIf;
		TotalRows = TotalRows + 1;
	EndDo;
	
	If TotalRows = 0 Then
		ShowUserNotification(
			NStr("vi = 'Không cần làm tròn';
				|ru = 'Округление не требуется';
				|en = 'Rounding is not required'; fa = 'Rounding is not required';
				|it = 'L''arrotondamento non è richiesto';
				|pl = 'Zaokrąglenie nie jest potrzebne';
				|tr = 'Yuvarlama gerekmemektedir'"),, 
			NStr("vi = 'Các hàng được chọn đã có số nguyên đơn vị.';
				|ru = 'В выбранных строках уже целое количество единиц.';
				|en = 'There is already a whole number of units in the selected lines.'; fa = 'There is already a whole number of units in the selected lines.';
				|it = 'Nelle righe selezionate è già presente un numero intero di unità.';
				|pl = 'W wybranych wierszach już jest liczba całkowita jednostek.';
				|tr = 'Seçili satırlarda zaten tam sayı birimi mevcut.'"),
			PictureLib.Information32);
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Trong các dòng đã chọn, số lượng sẽ được làm tròn đến hàng đơn vị. 
							|Tiếp tục?';
							|ru = 'В выбранных строках количество будет округлено до целых единиц. 
							|Продолжить?';
							|en = 'The selected lines will be rounded up to integral units.
							|Continue?'; fa = 'The selected lines will be rounded up to integral units.
							|Continue?';
							|it = 'Nelle righe selezionate, la quantità verrà arrotondata a unità intere. 
							|Continuare?';
							|pl = 'W wybranych wierszach ilość zostanie zaokrągloną do liczb całkowitych. 
							|Kontynuować?';
							|tr = 'Seçili satırlardaki miktar, tam sayı birimlerine yuvarlanacaktır. 
							|Devam edilsin mi?'");
	CallbackDescription = New CallbackDescription("RoundToTheWholePackageCompletion", ThisObject);
	ButtonsList = New ValueList;
	ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Tiếp tục';
												|ru = 'Продолжить';
												|en = 'Continue'; fa = 'ادامه';
												|it = 'Continuare';
												|pl = 'Continue';
												|tr = 'Devam et'"));
	ButtonsList.Add(DialogReturnCode.Cancel);
	ShowQueryBox(CallbackDescription, QueryText, ButtonsList); 
	
EndProcedure

&AtClient
Procedure GoodsFillInPricesByPriceKind(Command)
	
	PricesCalculated = GoodsFillInPricesByPriceKindServer();
	
	If PricesCalculated Then
		SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, Object.PriceKind);
	EndIf;

EndProcedure

&AtClient
Procedure ProductsFillInThePricesAccordingToTheCalculation(Command)
	CurrentData = Items.Goods.CurrentData;
	If CurrentData = Undefined Then
		Return
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("RowsIDs", 
		TMCommonUseClientServer.Array(CurrentData.GetID(),
			False));

	FormParameters = New Structure;
	FormParameters.Insert("Organization", Object.Organization);
	FormParameters.Insert("Products", CurrentData.Products);
	If ValueIsFilled(CurrentData.Characteristic) Then
		FormParameters.Insert("Characteristic", CurrentData.Characteristic);
	EndIf;
	FormParameters.Insert("Purpose", CurrentData.Purpose);
	FormParameters.Insert("State", 
		PredefinedValue("Enum.StatesOfStandardCostEstimateCalculation.Calculated"));
	
	OpenForm("Document.StandardCosting2_2.Form.ChoiceForm", FormParameters,,,,, 
		New CallbackDescription("CompletionOfPlanningCalculationSelection", ThisObject, AdditionalParameters),
		FormWindowOpeningMode.LockOwnerWindow);
	Return; // in UT and KA the handler is empty
	
EndProcedure

&AtClient
Procedure CompletionOfPlanningCalculationSelection(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	FillInPlanningCalculationsAndPricesOnServer(AdditionalParameters.RowsIDs, 
		Result);
		
EndProcedure
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
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

#EndRegion

#Region Private

#Region OnChangeAttributes

&AtServer
Procedure OrganizationWhenChangedOnServer()
	If Object.InternalSubcontracting
		And ValueIsFilled(Object.Organization) Then
		
		If Object.MaterialProviderCompany = Object.Organization Then
			
			MessageText = NStr("vi = 'Doanh nghiệp-người nhận gia công không thể trùng với doanh nghiệp-người đặt gia công.';
								|ru = 'Организация-переработчик не может совпадать с организацией-давальцем.';
								|en = 'Subcontractor company and the material provider company cannot be the same.'; fa = 'Subcontractor company and the material provider company cannot be the same.';
								|it = 'Организация-переработчик не может совпадать с организацией-давальцем.';
								|pl = 'Subcontractor company and the material provider company cannot be the same.';
								|tr = 'Fason üretici iş yeri ile tedarikçi iş yeri aynı olamaz.'");
			Common.MessageToUser(MessageText,, "Organization", "Object");
			
			Object.Organization = CompanyBeforeChange;
			
			Return;
			
		EndIf;
		
		If Not Object.MaterialProviderCompany = Object.Organization
			And Catalogs.Companies.OrganizationsAreInterconnectedByOrganizationalStructure(Object.Organization, Object.MaterialProviderCompany) Then
			
			MessageText = NStr("vi = 'Doanh nghiệp nhận gia công không được phép có quan hệ với doanh nghiệp đặt gia công về mặt cơ cấu tổ chức.';
								|ru = 'Организация-переработчик не должна быть взаимосвязана с организацией-давальцем по организационной структуре.';
								|en = 'Subcontractor company must not be interrelated to the material provider company by the organizational structure.'; fa = 'Subcontractor company must not be interrelated to the material provider company by the organizational structure.';
								|it = 'Организация-переработчик не должна быть взаимосвязана с организацией-давальцем по организационной структуре.';
								|pl = 'Subcontractor company must not be interrelated to the material provider company by the organizational structure.';
								|tr = 'Fason üretici iş yeri, iş yeri yapısı bakımından tedarikçi iş yeri ile bağlantılı olmamalıdır.'");
			Common.MessageToUser(MessageText,, "Organization", "Object");
			
			Object.Organization = CompanyBeforeChange;
			
			Return;
			
		EndIf;
		
	EndIf;
	UpdateVATTaxation_();
	EstablishUseOfPlannedValue();
	
	CompanyBeforeChange = Object.Organization;
	
EndProcedure

&AtServer
Procedure RecipientOrganizationWhenModifiedOnServer()
	
	UpdateVATTaxation_();
	
EndProcedure

&AtServer
Procedure DateOnChangeServer()
	
	DeterminePresenceOfOrderScheme();
	ConfigurePickUpByOrdersOrdersCommand();
	UpdateVATTaxation_();
	
	If QualityControl.UpdateActionParameters(Documents.MovementOfProductsAndMaterials, Object, CacheQualityControl) Then
		StructureOfActions = New Structure;
		AddQualityControlActionsToStructure(StructureOfActions, CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
	EndIf;
	
	FillInStatusesForSpecifyingSeriesServer(True);
	
EndProcedure

&AtServer
Procedure DateOfReceiptOnChangeATServer()
	
	If QualityControl.UpdateActionParameters(Documents.MovementOfProductsAndMaterials, Object, CacheQualityControl) Then
		StructureOfActions = New Structure;
		AddQualityControlActionsToStructure(StructureOfActions, CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
	EndIf;
	
EndProcedure

&AtServer
Procedure BusinessOperationWhenChangingOnServer()
	
	If Not ValueIsFilled(Object.BusinessOperation) Then
		Object.BusinessOperation = Items.BusinessOperation.ChoiceList[0].Value;
	EndIf;
	ListOfChangedBankingDetails = "BusinessOperation";
	
	If Not AvailableSelectionByOrder(Object) Then
		Documents.MovementOfProductsAndMaterials.UntieFromOrders(Object);
		ListOfChangedBankingDetails = ListOfChangedBankingDetails + ",ByReferences";
	EndIf;
	
	SwapSenderAndRecipientWhenChangingOperation(ListOfChangedBankingDetails);
	
	UpdateVATTaxation_();
	ConfigureDependentFormElementsOnServer(ListOfChangedBankingDetails);
	
	LimitValueType("Sender");
	LimitValueType("Recipient");
	
	If Not UseSeveralWarehouses Then
		If TypeOf(Object.Recipient) = Type("CatalogRef.Warehouses") Then
			Object.Recipient = SettingsValueCached.GetDefaultWarehouse(Object.Recipient);
		ElsIf TypeOf(Object.Sender) = Type("CatalogRef.Warehouses") Then
			Object.Sender = SettingsValueCached.GetDefaultWarehouse(Object.Sender);
		EndIf;
	EndIf;
	
	StructureOfActions = New Structure;
	SetShopPantryAttribute("Sender", StructureOfActions);
	SetShopPantryAttribute("Recipient", StructureOfActions);
	
	If QualityControl.UpdateActionParameters(Documents.MovementOfProductsAndMaterials, Object, CacheQualityControl) Then
		AddQualityControlActionsToStructure(StructureOfActions, CacheQualityControl);
	EndIf;
	
	If ValueIsFilled(StructureOfActions) Then
		CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
		BatchProcessingOfTablePartServer.TreatTS(Object["Goods"], StructureOfActions, CachedValues);
	EndIf;	 
	
	FillInStatusesForSpecifyingSeriesServer(True);
	
	ConfigurePickUpByOrdersOrdersCommand();
	UpdateOrderInformation();
	UpdateInformationOnDeviationFromOrdersServer();
	
	AfterChangingStringsProgrammaticallyOnServer(False);
	
	BusinessTransactionBeforeChange = Object.BusinessOperation;
	
EndProcedure

&AtServer
Procedure SwapSenderAndRecipientWhenChangingOperation(ListOfChangedBankingDetails)

	OldSender = Object.Sender;
	OldRecipient  = Object.Recipient;
	
	If (Object.BusinessOperation = Enums.BusinessTransactions.TransferOfSemiFinishedProducts
				Or Object.BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction
				Or Object.BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromStoreroom)
			And (BusinessTransactionBeforeChange = Enums.BusinessTransactions.MaterialTransferToProduction
				Or BusinessTransactionBeforeChange = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom)
			
		// First we returned it to the warehouse now we are transferring it back
		Or (Object.BusinessOperation = Enums.BusinessTransactions.MaterialTransferToProduction
				Or Object.BusinessOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom)
			And (BusinessTransactionBeforeChange = Enums.BusinessTransactions.ReturnOfMaterialsFromProduction
				Or BusinessTransactionBeforeChange = Enums.BusinessTransactions.ReturnOfMaterialsFromStoreroom)
			
		// First we transferred it now we return it
		Or (Object.BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromProduction
				Or Object.BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromStoreroom)
			And (BusinessTransactionBeforeChange = Enums.BusinessTransactions.MaterialTransferToProduction
				Or BusinessTransactionBeforeChange = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom)
		Then
		
		Object.Sender = OldRecipient;
		ListOfChangedBankingDetails = ListOfChangedBankingDetails + ",Sender";
	EndIf;
	
	If (Object.BusinessOperation = Enums.BusinessTransactions.MaterialTransferToProduction
			Or Object.BusinessOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom)
			And (BusinessTransactionBeforeChange = Object.BusinessOperation = Enums.BusinessTransactions.TransferOfSemiFinishedProducts
				Or BusinessTransactionBeforeChange = Enums.BusinessTransactions.TransferOfProductsFromProduction
				Or BusinessTransactionBeforeChange = Enums.BusinessTransactions.TransferOfProductsFromStoreroom)
				
		// First we returned it to the warehouse now we are transferring it back
		Or (Object.BusinessOperation = Enums.BusinessTransactions.MaterialTransferToProduction
				Or Object.BusinessOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom)
			And (BusinessTransactionBeforeChange = Enums.BusinessTransactions.ReturnOfMaterialsFromProduction
				Or BusinessTransactionBeforeChange = Enums.BusinessTransactions.ReturnOfMaterialsFromStoreroom)
			
		// First we transferred it now we return it
		Or (Object.BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromProduction
				Or Object.BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromStoreroom)
			And (BusinessTransactionBeforeChange = Enums.BusinessTransactions.MaterialTransferToProduction
				Or BusinessTransactionBeforeChange = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom)
		Then
		
		Object.Recipient = OldSender;
		ListOfChangedBankingDetails = ListOfChangedBankingDetails + ",Recipient";
	EndIf; 

EndProcedure

&AtServer
Procedure SenderOnChangeServer()
	
	If Object.BusinessOperation = Enums.BusinessTransactions.MaterialTransferToProduction
		Or Object.BusinessOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom Then
		
		FillInWarehousePriceView();
		DeterminePresenceOfOrderScheme();
		ConfigurePickUpByOrdersOrdersCommand();
		
		If Object.ByReferences And Object.Goods.Count() > 0  Then
			Object.Goods.Clear();
			UpdateOrderInformation();
		EndIf;
		
	EndIf;
	
	StructureOfActions = New Structure;
	SetShopPantryAttribute("Sender", StructureOfActions);
	
	If ValueIsFilled(StructureOfActions) Then
		CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
		BatchProcessingOfTablePartServer.TreatTS(Object["Goods"], StructureOfActions, CachedValues);
	EndIf;	 
	 
	FillInStatusesForSpecifyingSeriesServer(True);
	
	ConfigureDependentFormElementsOnServer("Sender");
	
	SenderBeforeChange = Object.Sender;
	
EndProcedure

&AtServer
Procedure FillInWarehousePriceView()
	
	Query = New Query;
	Query.SetParameter("Ref", Object.Sender);
	Query.Text =
	"SELECT
	|	Warehouses.AccountingPriceType AS AccountingPriceType
	|FROM
	|	Catalog.Warehouses AS Warehouses
	|WHERE
	|	Warehouses.Ref = &Ref";
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() And ValueIsFilled(Selection.AccountingPriceType) Then
		Object.PriceKind = Selection.AccountingPriceType;
	EndIf;
	
EndProcedure

&AtServer
Procedure RecipientOnChangeServer(DirectModificationOfWarehouseField = False)
	
	DeterminePresenceOfOrderScheme();
	ConfigurePickUpByOrdersOrdersCommand();
	
	UpdateVATTaxation_();
	
	StructureOfActions = New Structure;
	SetShopPantryAttribute("Recipient", StructureOfActions);
	
	If QualityControl.UpdateActionParameters(
			Documents.MovementOfProductsAndMaterials,
			Object,
			CacheQualityControl,
			DirectModificationOfWarehouseField) Then
		AddQualityControlActionsToStructure(StructureOfActions, CacheQualityControl);
	EndIf;
	
	If ValueIsFilled(StructureOfActions) Then
		CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
		BatchProcessingOfTablePartServer.TreatTS(Object["Goods"], StructureOfActions, CachedValues);
	EndIf;	 
	
	FillInStatusesForSpecifyingSeriesServer(True);

	ConfigureDependentFormElementsOnServer("Recipient");

EndProcedure

&AtServer
Procedure LineOfBusinessOnChangeServer()
	
	UpdateVATTaxation_();
	
EndProcedure

&AtServer
Procedure GoodsAfterDeleteRowServer(SeriesStatusesNeedToBeUpdated, CachedValues)
	
	If SeriesStatusesNeedToBeUpdated Then
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Undefined, CachedValues);
	EndIf;
	
	UpdateOrderInformation();
	
	UpdateInformationOnDeviationFromOrdersServer();
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
EndProcedure

&AtServer
Procedure GoodsAtEndOfEditingOnServer(UpdateGoods, IDCurrentRow, CachedValues)
	
	If UpdateGoods Then
		FormEvents.WhenChangingElement(ThisObject, "Goods");
	EndIf;
	
	If IDCurrentRow <> Undefined Then
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues);
	EndIf;
	
EndProcedure

&AtClient
Procedure SenderOnChangeCompletion(QuestionResult, AdditionalParameters) Export
    
    If QuestionResult <> DialogReturnCode.Yes Then
        Object.Sender = SenderBeforeChange;
        Return;
    EndIf;
    
    SenderOnChangeServer();

EndProcedure

&AtServer
Procedure CurrencyOnChangeServer()
	
	OldCurrency                = DocumentCurrency;
	NewCurrency                 = Object.Currency;
	DocumentDate               = ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate());
	StructureOfOldCurrencyRates = ProcessingOfExchangeRatesTM.GetCurrencyRate(OldCurrency, DocumentDate);
	StructureOfNewCurrencyRates  = ProcessingOfExchangeRatesTM.GetCurrencyRate(NewCurrency,  DocumentDate);
	
	// Recalculate the price
	PriceManagementSystem.ConvertAmountsToCurrencyProducts(
		Object,
		OldCurrency,
		NewCurrency,
		StructureOfOldCurrencyRates,
		StructureOfNewCurrencyRates,
		False);
	
	// Recalculate the amount
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	
EndProcedure

&AtServer
Procedure CompanyGivesGiverWhenChangeIsMadeOnServer()
	
	If ValueIsFilled(Object.MaterialProviderCompany)
		And Not Object.MaterialProviderCompany = Object.Organization
		And Catalogs.Companies.OrganizationsAreInterconnectedByOrganizationalStructure(Object.Organization, Object.MaterialProviderCompany) Then
		
		MessageText = NStr("vi = 'Doanh nghiệp nhận gia công không được phép có quan hệ với doanh nghiệp đặt gia công về mặt cơ cấu tổ chức.';
							|ru = 'Организация-давалец не должна быть взаимосвязана с организацией-переработчиком по организационной структуре.';
							|en = 'Material provider company must not be interrelated to the subcontractor company by the organizational structure.'; fa = 'Material provider company must not be interrelated to the subcontractor company by the organizational structure.';
							|it = 'Организация-давалец не должна быть взаимосвязана с организацией-переработчиком по организационной структуре.';
							|pl = 'Material provider company must not be interrelated to the subcontractor company by the organizational structure.';
							|tr = 'Tedarikçi iş yeri, iş yeri yapısı bakımından fason üretici iş yeri ile bağlantılı olmamalıdır.'");
		Common.MessageToUser(MessageText,, "MaterialProviderCompany", "Object");
		
		Object.MaterialProviderCompany = CompanyGiverBeforeChange;
		
		Return;
		
	EndIf;
	
	ConfigureDependentElementsOfInternalProcessing(ThisObject, "MaterialProviderCompany");
	
	CompanyGiverBeforeChange = Object.MaterialProviderCompany;
	
EndProcedure
#EndRegion

#Region SelectionAndProcessingOfQuantityVerification

&AtClient
Procedure OpenSelectionByOrdersOrders()
	
	HeaderAttributes = New Structure("Organization, Recipient, Sender, BusinessOperation, GoodsReceiptOption, Ref");
	HeaderAttributes = New Structure("Organization, Recipient, Sender, BusinessOperation, GoodsReceiptOption, InternalSubcontracting, MaterialProviderCompany, Ref");
	FillPropertyValues(HeaderAttributes, Object);
	AdditionalFields = New Structure;
	
	FormParameters = New Structure();
	FormParameters.Insert("HeaderAttributes",                           HeaderAttributes);
	FormParameters.Insert("OrderDocument",                                    Object.ReferenceOrder);
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.MaterialTransferToProduction")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferOfMaterialsToStoreroom") Then
		FormParameters.Insert("AdvancedWarehousingOnShipment",             AdvancedWarehousing);
		FormParameters.Insert("AdvancedWarehousingOnGoodsReceipt",          False);
		AdditionalFields.Insert("DateOfShipment");
	Else
		FormParameters.Insert("AdvancedWarehousingOnShipment",             False);
		FormParameters.Insert("AdvancedWarehousingOnGoodsReceipt",          AdvancedWarehousing);
		AdditionalFields.Insert("DateOfReceipt");
	EndIf;
	FormParameters.Insert("InvoiceForOrders",                       Object.ByReferences);
	FormParameters.Insert("AddressGoods",                              AddressInvoiceGoods());
	FormParameters.Insert("Invoice",                                Object.Ref);
	FormParameters.Insert("UseInvoicesForSeveralOrders", True);
	FormParameters.Insert("OrdersAreUsed",                       AvailableSelectionByOrder(Object));
	FormParameters.Insert("AdditionalFields",                       AdditionalFields);
	
	OpenForm("CommonForm.AddItemsFromSalesOrderGoodsIssue",
		FormParameters, ThisForm, UUID,,,,FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtServer
Function AddressInvoiceGoods()
	
	Table = Object.Goods.Unload();
	Table.Columns.ReferenceOrder.Name = "Source_Order";
	
	Table.Columns.Add("ReferenceOrder", New TypeDescription("DocumentRef.OrderOfMaterialsForProduction, 
		|DocumentRef.ProductionStage2_2,
		|DocumentRef.MovementOfProductsAndMaterials"));
	Table.Columns.Add("DateOfShipment",    New TypeDescription("Date"));
	Table.Columns.Add("DateOfReceipt", New TypeDescription("Date"));
	
	For Each String In Table Do
		String.ReferenceOrder = ?(ValueIsFilled(String.Source_Order), String.Source_Order, Object.Ref);
	EndDo;
	
	Table.FillValues(CurrentSessionDate(), "DateOfShipment");
	Table.FillValues(CurrentSessionDate(), "DateOfReceipt");
	
	Return PutToTempStorage(Table);
	
EndFunction

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected)

	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct, "Products, Characteristic, ItemVariantsAreUsed, Package, NumberOfPackages, Series");
		
		ProcessLineAddedProgrammatically(CurrentRow, CachedValues);
		
	EndDo;

	AfterChangingStringsProgrammaticallyOnServer();
	
EndProcedure

&AtServer
Procedure ProcessingSelectionOfProductsOnServer(ValueSelected)

	If TypeOf(ValueSelected) = Type("Array") Then
		GoodsList = ValueSelected;
	Else
		GoodsList = New Array;
		GoodsList.Add(ValueSelected);
	EndIf;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	For Each RowOfProduct In GoodsList Do
		
		CurrentRow = Object.Goods.Add();
		CurrentRow.Products = RowOfProduct;
		
		ProcessLineAddedProgrammatically(CurrentRow, CachedValues);
		
	EndDo;

	AfterChangingStringsProgrammaticallyOnServer();
	
EndProcedure

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export 
	
	CurrentRow = Items.Goods.CurrentData;
	
	If NewRow <> Undefined Then
		
		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(ThisObject, StructureOfActions);
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
	EndIf;
	
	UpdateInformationOnDeviationFromOrders(
		Object.Goods,
		LabelDiscrepancy, 
		Items.PictureDiscrepancy1,
		Items.PictureDiscrepancy2);
	
EndProcedure

&AtServer
Procedure ProcessingProductSelectionFromOrder(AddressInStorage)
	
	CalculationResult1 = GetFromTempStorage(AddressInStorage);
	Table = CalculationResult1.Goods; // TabularSection
	
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
	
	OrderRelationshipFields = New Structure("RowCode, ReferenceOrder", 0, Undefined);
	InvoicesServer.FillInProductsSelectedFromOrder(StringTree, FieldsNames, Object.Goods, OrderRelationshipFields);
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(ThisObject, StructureOfActions);
	AddQualityControlActionsToStructure(StructureOfActions, CacheQualityControl);
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Products", StructureOfActions);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
	FillInSeriesStatuses = True;
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction Then
		Documents.MovementOfProductsAndMaterials.FillSeriesByProductionStages(Object);
		FillInSeriesStatuses = False;
	EndIf;
	
	UpdateAvailabilityOfInternalProcessing();
	ConfigureDependentFormElementsOnServer("ByReferences");
	SalesServerLocalization.TransferBarcodesOfPackages(ThisObject, CalculationResult1.PackageBarcodes);
	AfterChangingStringsProgrammaticallyOnServer(True, FillInSeriesStatuses);
	
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
	
	Columns = "Products,Characteristic,Package,NumberOfPackages,ProductsGroup";
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);
		
		ProcessLineAddedProgrammatically(CurrentRow, CachedValues);
		
	EndDo;
	
	AfterChangingStringsProgrammaticallyOnServer();
	
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

#EndRegion

#Region BarcodesAndTradeEquipment

&AtClient
Procedure SearchByBarcodeCompletion(BarcodeData_2, AdditionalParameters) Export
	
	ProcessBarcodes(BarcodeData_2);
	
EndProcedure

&AtClient
Procedure ProcessBarcodes(BarcodeData_5)
	
	ClearMessages();
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
		Return;
	EndIf;
	
	StructureOfActionsWithAddedStrings = New Structure;
	AddActionsToStructureWhenChangingProducts(ThisObject, Undefined, StructureOfActionsWithAddedStrings);
	AddActionsToStructureWhenChangingPackagesNumber(ThisObject, StructureOfActionsWithAddedStrings);
	AddQualityControlActionsToStructure(StructureOfActionsWithAddedStrings, CacheQualityControl);
	
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	
	StructureOfActionsWithModifiedStrings = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(ThisObject, StructureOfActionsWithModifiedStrings);
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	StructureOfActions.SeriesSpecificationParameters                 = SeriesSpecificationParameters;
	StructureOfActions.ChangeQuantity                     = Not Object.ByReferences;
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
	
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject, Object,StructureOfActionParameters,CachedValues);
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
EndProcedure

#EndRegion

#Region SetOfSeries

&AtServer
Function ThereAreFilledSeriesByFEFO()

	Return ProductsServer.ThereAreLinesWithFEFOFilledSeries(Object.Goods);

EndFunction

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
	
EndProcedure

&AtServer
Procedure ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm)
	
	StructureOfActions = New Structure();
	AddQualityControlActionsToStructure(StructureOfActions, CacheQualityControl);
	ProductsServer.ProcessSeriesIndication_(Object,SeriesSpecificationParameters,ParametersOfSeriesIndicationForm, StructureOfActions);
	
EndProcedure

&AtServer
Procedure FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues)
	
	ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Object, 
		SeriesSpecificationParameters, IDCurrentRow, CachedValues);
	
EndProcedure

&AtServer
Procedure FillInStatusesForSpecifyingSeriesServer(UpdateParametersForSpecifyingSeries = False)
	
	If UpdateParametersForSpecifyingSeries Then
		
		SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.MovementOfProductsAndMaterials));
		SetVisibilityOfSeriesElements();
		
	EndIf; 
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	
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
		CallbackDescription = New CallbackDescription("OpenSelectionOfSeriesCompletion", 
														ThisObject, 
														New Structure("ParametersOfSeriesIndicationForm", ParametersOfSeriesIndicationForm));
		
		OpenForm(ParametersOfSeriesIndicationForm.FormName,
						ParametersOfSeriesIndicationForm,ThisForm,,,, 
						CallbackDescription,
						FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtServer
Function ParametersOfSeriesIndicationForm(CurDataId)
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(Object, SeriesSpecificationParameters, CurDataId, ThisForm);
	
EndFunction

&AtClient
Procedure OpenSelectionOfSeriesCompletion(Result, AdditionalParameters) Export
    
    If Result <> Undefined Then
        ProcessSeriesIndication_Server(AdditionalParameters.ParametersOfSeriesIndicationForm);
    EndIf;

EndProcedure

&AtClient
Procedure ByReferencesOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.No Then
		Object.ByReferences = Not Object.ByReferences;
		Return;
	EndIf;
	
	OnOrdersWhenChangingOnServer();
	
	If Not Object.ByReferences
		And Object.Goods.Count() > 0 Then
		NotifyAboutDisconnectingLinesFromOrders();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnOrdersWhenChangingOnServer()

	ChangedBankingDetails = "ByReferences";
	
	If Object.ByReferences Then
		
		If Object.Goods.Count() > 0 Then
			BindRowsToOrders();
			AfterChangingStringsProgrammaticallyOnServer(True);
		EndIf;
		
	Else
		
		UntieDocumentFromOrders();
		
	EndIf;

	StructureOfActions = New Structure;
	SetShopPantryAttribute("Sender", StructureOfActions);
	SetShopPantryAttribute("Recipient", StructureOfActions);
	AddQualityControlActionsToStructure(StructureOfActions, CacheQualityControl);
	
	If ValueIsFilled(StructureOfActions) Then
		CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
		BatchProcessingOfTablePartServer.TreatTS(Object["Goods"], StructureOfActions, CachedValues);
	EndIf;
	
	ConfigureDependentFormElementsOnServer(ChangedBankingDetails);
	
	LimitValueType("Sender");
	LimitValueType("Recipient");
	
EndProcedure

#EndRegion

#Region References

&AtServer
Procedure UntieSelectedLinesFromOrder()
	
	Var CachedValues;
	
	RowsCollection = Items.Goods.SelectedRows;
	
	For Each CurRow In RowsCollection Do
		
		TableRow = Object.Goods.FindByID(CurRow);
		ProductsClientServer.UpdateCachedValuesToAccountForSeries(TableRow,CachedValues,SeriesSpecificationParameters);
		
		TableRow.RowCode = 0;
		TableRow.Purpose = Catalogs.Assignments.EmptyRef();
		TableRow.AssignmentSender = Catalogs.Assignments.EmptyRef();
		
		If Object.BusinessOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom Then
			TableRow.OrderDiscrepancy_3 = 1;
		EndIf;
		
		// Reassign the series lines
		ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Object,SeriesSpecificationParameters,CurRow,CachedValues);
		
	EndDo;
	
	UpdateInformationOnDeviationFromOrdersServer();
	
EndProcedure

&AtServer
Procedure UntieDocumentFromOrders()
	
	ListOfOrders_.Clear();
	Documents.MovementOfProductsAndMaterials.UntieFromOrders(Object);
	AfterChangingStringsProgrammaticallyOnServer();
	
EndProcedure

&AtServer
Procedure BindRowsToOrders()
	
	If Object.BusinessOperation = Enums.BusinessTransactions.MaterialTransferToProduction
		Or Object.BusinessOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom Then
		
		QueryText =
		"SELECT
		|	Goods.Products    AS Products,
		|	Goods.Characteristic  AS Characteristic
		|INTO Goods
		|FROM
		|	&Goods AS Goods
		|WHERE
		|	Goods.ReferenceOrder IN(&EmptyOrderValues)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	OrdersTable.ReferenceOrder          AS ReferenceOrder,
		|	OrdersTable.Products          AS Products,
		|	OrdersTable.Characteristic        AS Characteristic,
		|	OrdersTable.Purpose            AS Purpose,
		|	OrdersTable.AssignmentSender AS AssignmentSender,
		|	OrdersTable.RowCode             AS RowCode,
		|	SUM(OrdersTable.ToRegister)    AS ToRegisterBalance
		|FROM
		|	(SELECT
		|		Orders.ReferenceOrder          AS ReferenceOrder,
		|		Orders.Products          AS Products,
		|		Orders.Characteristic        AS Characteristic,
		|		Orders.Purpose            AS Purpose,
		|		Orders.AssignmentSender AS AssignmentSender,
		|		Orders.RowCode             AS RowCode,
		|		Orders.ToRegisterBalance    AS ToRegister
		|	FROM
		|		AccumulationRegister.OrdersOfMaterialsForProduction.Balance(
		|				,
		|					Warehouse = &Sender
		|					AND (Products, Characteristic) IN
		|						(SELECT
		|							Goods.Products AS Products,
		|							Goods.Characteristic AS Characteristic
		|						FROM
		|							Goods AS Goods)
		|					AND (Department = &Recipient
		|						OR Recipient = &Recipient)) AS Orders
		|		LEFT JOIN Document.OrderOfMaterialsForProduction AS OrderOfMaterialsForProduction
		|		ON Orders.ReferenceOrder = OrderOfMaterialsForProduction.Ref
		|	WHERE
		|		Orders.ReferenceOrder.Organization = &Organization
		|		AND ISNULL(OrderOfMaterialsForProduction.ProductionManagement2_2, TRUE)
		|		AND &AdditionalConditionsRequestBalances
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		TrafficOrders.ReferenceOrder,
		|		TrafficOrders.Products,
		|		TrafficOrders.Characteristic,
		|		TrafficOrders.Purpose,
		|		TrafficOrders.AssignmentSender,
		|		TrafficOrders.RowCode,
		|		CASE
		|			WHEN TrafficOrders.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -TrafficOrders.ToRegister
		|			ELSE TrafficOrders.ToRegister
		|		END
		|	FROM
		|		AccumulationRegister.OrdersOfMaterialsForProduction AS TrafficOrders
		|	WHERE
		|		TrafficOrders.Recorder = &Recorder
		|		AND TrafficOrders.ReferenceOrder.Organization = &Organization
		|		AND TrafficOrders.Warehouse = &Sender
		|		AND TrafficOrders.Active
		|		AND (TrafficOrders.Products, TrafficOrders.Characteristic) IN
		|				(SELECT
		|					Goods.Products AS Products,
		|					Goods.Characteristic AS Characteristic
		|				FROM
		|					Goods AS Goods)
		|		AND (TrafficOrders.Department = &Recipient
		|			OR TrafficOrders.Recipient = &Recipient)
		|		AND &AdditionalTrafficConditions
		|	) AS OrdersTable
		|
		|GROUP BY
		|	OrdersTable.Products,
		|	OrdersTable.Characteristic,
		|	OrdersTable.Purpose,
		|	OrdersTable.AssignmentSender,
		|	OrdersTable.RowCode,
		|	OrdersTable.ReferenceOrder
		|
		|HAVING
		|	SUM(OrdersTable.ToRegister) > 0
		|";
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction
		Or Object.BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromProduction Then
		
		QueryText =
		"SELECT
		|	Goods.Products    AS Products,
		|	Goods.Characteristic  AS Characteristic
		|INTO Goods
		|FROM
		|	&Goods AS Goods
		|WHERE
		|	Goods.ReferenceOrder IN(&EmptyOrderValues)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	OrdersTable.ReferenceOrder          AS ReferenceOrder,
		|	OrdersTable.Products          AS Products,
		|	OrdersTable.Characteristic        AS Characteristic,
		|	OrdersTable.Purpose            AS Purpose,
		|	OrdersTable.AssignmentSender AS AssignmentSender,
		|	OrdersTable.RowCode             AS RowCode,
		|	SUM(OrdersTable.ToRegister)    AS ToRegisterBalance
		|FROM
		|	(SELECT
		|		Orders.ReferenceOrder          AS ReferenceOrder,
		|		Orders.Products          AS Products,
		|		Orders.Characteristic        AS Characteristic,
		|		Orders.Purpose            AS Purpose,
		|		Orders.AssignmentSender AS AssignmentSender,
		|		Orders.RowCode             AS RowCode,
		|		Orders.CountBalance     AS ToRegister
		|	FROM
		|		AccumulationRegister.ReferencesToTransferFromProduction.Balance(
		|				,
		|				Organization = &Organization
		|				AND Sender = &Sender
		|					AND Recipient = &Recipient
		|					AND (Products, Characteristic) IN
		|						(SELECT
		|							Goods.Products AS Products,
		|							Goods.Characteristic AS Characteristic
		|						FROM
		|							Goods AS Goods)) AS Orders
		|	WHERE
		|		&AdditionalConditionsRequestBalances
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		TrafficOrders.ReferenceOrder,
		|		TrafficOrders.Products,
		|		TrafficOrders.Characteristic,
		|		TrafficOrders.Purpose,
		|		TrafficOrders.AssignmentSender,
		|		TrafficOrders.RowCode,
		|		CASE
		|			WHEN TrafficOrders.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -TrafficOrders.Count
		|			ELSE TrafficOrders.Count
		|		END
		|	FROM
		|		AccumulationRegister.ReferencesToTransferFromProduction AS TrafficOrders
		|	WHERE
		|		TrafficOrders.Recorder = &Recorder
		|		AND TrafficOrders.Recipient = &Recipient
		|		AND TrafficOrders.Sender = &Sender
		|		AND TrafficOrders.Organization = &Organization
		|		AND TrafficOrders.Active
		|		AND (TrafficOrders.Products, TrafficOrders.Characteristic) IN
		|				(SELECT
		|					Goods.Products AS Products,
		|					Goods.Characteristic AS Characteristic
		|				FROM
		|					Goods AS Goods)
		|		AND &AdditionalTrafficConditions
		|		) AS OrdersTable
		|
		|GROUP BY
		|	OrdersTable.Products,
		|	OrdersTable.Characteristic,
		|	OrdersTable.Purpose,
		|	OrdersTable.AssignmentSender,
		|	OrdersTable.RowCode,
		|	OrdersTable.ReferenceOrder
		|
		|HAVING
		|	SUM(OrdersTable.ToRegister) > 0
		|";
	Else
		Return;
	EndIf;
	
	AdditionalConditionsRequestBalances = "TRUE";
	AdditionalTrafficConditions = "TRUE";
	
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom Then
		AdditionalConditionsRequestBalances = "VALUETYPE(Orders.ReferenceOrder) = TYPE(Document.OrderOfMaterialsForProduction)";
		AdditionalTrafficConditions = "VALUETYPE(TrafficOrders.ReferenceOrder) = TYPE(Document.OrderOfMaterialsForProduction)";
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.MaterialTransferToProduction Then
		AdditionalConditionsRequestBalances = "VALUETYPE(Orders.ReferenceOrder) = TYPE(Document.ProductionStage2_2)
									|	AND CAST(Orders.ReferenceOrder AS Document.ProductionStage2_2).InternalSubcontracting = &InternalSubcontracting
									|	AND CAST(Orders.ReferenceOrder AS Document.ProductionStage2_2).MaterialProviderCompany = &MaterialProviderCompany";
		AdditionalTrafficConditions = "VALUETYPE(TrafficOrders.ReferenceOrder) = TYPE(Document.ProductionStage2_2)
									|	AND CAST(TrafficOrders.ReferenceOrder AS Document.ProductionStage2_2).InternalSubcontracting = &InternalSubcontracting
									|	AND CAST(TrafficOrders.ReferenceOrder AS Document.ProductionStage2_2).MaterialProviderCompany = &MaterialProviderCompany";
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction Then
		AdditionalConditionsRequestBalances = "Orders.Operation = VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction)
									|	AND Orders.ReferenceOrder.InternalSubcontracting = &InternalSubcontracting
									|	AND Orders.ReferenceOrder.MaterialProviderCompany = &MaterialProviderCompany";
		AdditionalTrafficConditions = "TrafficOrders.Operation = VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction)
									|	AND TrafficOrders.ReferenceOrder.InternalSubcontracting = &InternalSubcontracting
									|	AND TrafficOrders.ReferenceOrder.MaterialProviderCompany = &MaterialProviderCompany";
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromProduction Then
		AdditionalConditionsRequestBalances = "Orders.Operation = VALUE(Enum.BusinessTransactions.ReturnOfMaterialsFromProduction)
									|	AND Orders.ReferenceOrder.InternalSubcontracting = &InternalSubcontracting
									|	AND Orders.ReferenceOrder.MaterialProviderCompany = &MaterialProviderCompany";
		AdditionalTrafficConditions = "TrafficOrders.Operation = VALUE(Enum.BusinessTransactions.ReturnOfMaterialsFromProduction)
									|	AND TrafficOrders.ReferenceOrder.InternalSubcontracting = &InternalSubcontracting
									|	AND TrafficOrders.ReferenceOrder.MaterialProviderCompany = &MaterialProviderCompany";
	EndIf;
	
	QueryText = StrReplace(QueryText, "&AdditionalConditionsRequestBalances", AdditionalConditionsRequestBalances);
	QueryText = StrReplace(QueryText, "&AdditionalTrafficConditions", AdditionalTrafficConditions);
	
	Query = New Query(QueryText);
	
	Query.SetParameter("OrderDocument",                 Object.ReferenceOrder);
	Query.SetParameter("Organization",           Object.Organization);
	Query.SetParameter("InternalSubcontracting", Object.InternalSubcontracting);
	Query.SetParameter("MaterialProviderCompany",    Object.MaterialProviderCompany);
	Query.SetParameter("Sender",           Object.Sender);
	Query.SetParameter("Recipient",            Object.Recipient);
	Query.SetParameter("Recorder",           Object.Ref);
	Query.SetParameter("EmptyOrderValues", Documents.MovementOfProductsAndMaterials.EmptyOrderValues());
	
	Query.SetParameter("Goods",  Object.Goods.Unload(,"Products,Characteristic,ReferenceOrder"));
	QueryResult = Query.ExecuteBatch();
	If QueryResult[1].IsEmpty() Then
		Return;
	EndIf;
	
	RemnantsOfOrders = QueryResult[1].Unload();
	RemnantsOfOrders.Indexes.Add("Products, Characteristic");
	
	GoodsTable = Object.Goods.Unload(New Array);
	For Each CurRow In Object.Goods Do
		
		If CurRow.ReferenceOrder = Undefined Then
			
			GoodsQuantity = CurRow.Count;
			
			TheStructureOfTheSearch = New Structure();
			TheStructureOfTheSearch.Insert("Products",   CurRow.Products);
			TheStructureOfTheSearch.Insert("Characteristic", CurRow.Characteristic);
			
			FoundRows = RemnantsOfOrders.FindRows(TheStructureOfTheSearch);
			For Each TechBalance In FoundRows Do
				
				If TechBalance.ToRegisterBalance = 0 Then
					Continue;
				EndIf;
				
				ToRegister = Min(GoodsQuantity, TechBalance.ToRegisterBalance);
				
				NewRow = GoodsTable.Add();
				FillPropertyValues(NewRow, CurRow);
				FillPropertyValues(NewRow, TechBalance, "RowCode,ReferenceOrder,Purpose,AssignmentSender");
				NewRow.Count = ToRegister;
				
				GoodsQuantity = GoodsQuantity - ToRegister;
				TechBalance.ToRegisterBalance = TechBalance.ToRegisterBalance - ToRegister;
				
				If GoodsQuantity = 0 Then
					Break;
				EndIf;
				
			EndDo;
			
			If Not GoodsQuantity = 0 Then
				
				NewRow = GoodsTable.Add();
				FillPropertyValues(NewRow, CurRow);
				NewRow.Count = GoodsQuantity;
				
			EndIf;
			
		Else
			FillPropertyValues(GoodsTable.Add(), CurRow);
		EndIf;
		
	EndDo;
	
	RecalculationParameters = New Structure;
	RecalculationParameters.Insert("Products");
	RecalculationParameters.Insert("Package");
	RecalculationParameters.Insert("Count", "NumberOfPackages");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages", RecalculationParameters);
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Products", StructureOfActions);
	
	BatchProcessingOfTablePartServer.TreatTS(
		GoodsTable,
		StructureOfActions,
		Undefined);
	
	Object.Goods.Load(GoodsTable);
	
EndProcedure

&AtServer
Procedure UpdateOrderInformation()
	
	If Not AvailableSelectionByOrder(Object) Then
		Return;
	EndIf;
	
	ParametersOfUpdate = OrdersServer.ParametersForUpdatingOrderInformationInForm();
	
	ParametersOfUpdate.PropsNameOrderList         = "ListOfOrders_";
	ParametersOfUpdate.OrderPathInHeader                  = "Object.ReferenceOrder";
	ParametersOfUpdate.TitleLabelName               = "LabelReferences";
	ParametersOfUpdate.NameOfColumnGroupInTableSection   = "GoodsGroupReference";
	ParametersOfUpdate.OrderNameInTablePart          = "ReferenceOrder";
	ParametersOfUpdate.UseOrdersInTabularSection = True;
	ParametersOfUpdate.LabelTotalOrders               = NStr("vi = 'Tổng số lệnh';
															|ru = 'Всего распоряжений';
															|en = 'Total references'; fa = 'Total references';
															|it = 'Totale disposizioni';
															|pl = 'Łącznie zamówień';
															|tr = 'Toplam talimatlar'");
	
	OrdersServer.UpdateOrderInformationInForm(ThisForm, Object.Goods, ParametersOfUpdate);
	
	If Not Object.ByReferences
		And Not ListOfOrders_.Count() = 0 Then
		Object.ByReferences = True;
	EndIf;
	
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
					|tr = 'Satırlardaki miktar yeniden dolduruldu.'"),
			PictureLib.Information32);
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region DeviationsFromOrders

&AtServer
Procedure UpdateInformationOnDeviationFromOrdersServer()
	
	If Not AvailableSelectionByOrder(Object) Then
		Return;
	EndIf;
	
	If Object.Goods.Count() = 0 
		Or Not Object.ByReferences Then
		
		Items.PictureDiscrepancy1.Picture = New Picture();
		Items.PictureDiscrepancy2.Picture = New Picture();
		LabelDiscrepancy = "";
		
	Else
	
		UpdateInformationOnDeviationFromOrders(
			Object.Goods,
			LabelDiscrepancy,
			Items.PictureDiscrepancy1, 
			Items.PictureDiscrepancy2);
	
	EndIf;
		
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateInformationOnDeviationFromOrders(Goods, LabelDiscrepancy, PictureDiscrepancyOrder, PictureDiscrepancyOrders)
	
	NumberOfDiscrepancies = Goods.Total("OrderDiscrepancy_3");
	
	If NumberOfDiscrepancies > 0 Then
		PictureDiscrepancyOrder.Picture = PictureLib.ExceededOrder;
		PictureDiscrepancyOrders.Picture = PictureLib.ExceededOrder;
		LabelDiscrepancy = StrReplace(NStr("vi = 'Dòng trên lệnh: %NumberOfDiscrepancies%';
											|ru = 'Строк сверх распоряжения: %NumberOfDiscrepancies%';
											|en = 'Lines beyond reference: %NumberOfDiscrepancies%'; fa = 'Lines beyond reference: %NumberOfDiscrepancies%';
											|it = 'Righe oltre la disposizione: %NumberOfDiscrepancies%';
											|pl = 'Wierszy ponad zamówienia: %NumberOfDiscrepancies%';
											|tr = 'Talimatların üzerindeki satırlar: %NumberOfDiscrepancies%'"), "%NumberOfDiscrepancies%", NumberOfDiscrepancies);
	Else
		PictureDiscrepancyOrder.Picture = New Picture();
		PictureDiscrepancyOrders.Picture = New Picture();
		LabelDiscrepancy = "";
		NumberOfDiscrepancies = 0;
	EndIf;
	
EndProcedure

&AtClient
Procedure NotifyAboutDisconnectingLinesFromOrders()
	
	NotificationText1 = NStr("vi = 'Các dòng trong danh sách ""Hàng hóa và nguyên vật liệu"" được bỏ liên kết từ các dòng lệnh.';
							|ru = 'Строки в списке ""Продукция и материалы"" отвязаны от строк распоряжений.';
							|en = 'Lines in the Products and materials list are unlinked from the reference lines.'; fa = 'Lines in the Products and materials list are unlinked from the reference lines.';
							|it = 'Le righe nell''elenco ""Prodotti e materiali"" sono scollegate dalle righe delle disposizioni.';
							|pl = 'Wiersze na liście liście ""Wiersze pozycji i materiały"" są odwiązane od wierszy zamówień.';
							|tr = '""İmal Edilen Ürünler ve Malzemeler"" listesindeki satırlar, talimat satırlarından çıkarıldı.'");
	ShowUserNotification(NStr("vi = 'Xử lý danh sách ""Hàng hóa và nguyên vật liệu""';
								|ru = 'Обработка списка ""Продукция и материалы""';
								|en = 'Processing the ""Products and materials"" list'; fa = 'Processing the ""Products and materials"" list';
								|it = 'Elaborazione dell''elenco ""Prodotti e materiali""';
								|pl = 'Przetwarzanie listy ""Wiersze pozycji i materiały""';
								|tr = '""İmal Edilen Ürünler ve Malzemeler"" listesinin işlenmesi'"),, NotificationText1);
	
EndProcedure

&AtClient
Procedure NotifyAboutEndOfUnbindingLines(NumberOfLinesWorked, LinesWereUnlinked = True)

	If LinesWereUnlinked Then
		
		NotificationText1 = NStr("vi = 'Trong chứng từ, các dòng được bỏ liên kết từ các lệnh (%%Count%%).';
								|ru = 'В документе от распоряжений отвязано строк (%%Count%%).';
								|en = 'In the document, the lines (%%Count%%) are detached from the references.'; fa = 'In the document, the lines (%%Count%%) are detached from the references.';
								|it = 'Righe non associate (%%Count%%) alle disposizioni del documento.';
								|pl = 'W dokumencie od zamówień odwiązano wierszy (%%Count%%).';
								|tr = 'Belgedeki talimatlardan satırlar çıkarıldı (%%Count%%).'");
		NotificationText1 = StrReplace(NotificationText1, "%%Count%%", NumberOfLinesWorked);
		ShowUserNotification(
			NStr("vi = 'Các dòng liên quan';
				|ru = 'Строки отвязаны';
				|en = 'Lines were unlinked'; fa = 'Lines were unlinked';
				|it = 'Righe dissociate';
				|pl = 'Wierze odłączone';
				|tr = 'Satırlar çıkarıldı'"),
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
				|tr = 'Satırlar çıkarılmadı'"),
			,
			NStr("vi = 'Không có dòng nào liên quan.';
				|ru = 'Ни одна строка не была отвязана.';
				|en = 'No line was unlinked.'; fa = 'No line was unlinked.';
				|it = 'Nessuna riga è stata dissociata.';
				|pl = 'Nie odłączono ani jednego wiersza.';
				|tr = 'Herhangi bir satır çıkarılmadı.'"),
			PictureLib.Information32);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateDeviationsFromOrder()
	
	For Each CurrentRow In Object.Goods Do
		UpdateDeviationsFromOrderInLine(CurrentRow, Object.ByReferences, Object.BusinessOperation);
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateDeviationsFromOrderInLine(CurrentRow, ByReferences, BusinessTransaction)
	
	If BusinessTransaction = PredefinedValue("Enum.BusinessTransactions.TransferOfMaterialsToStoreroom")
		And ByReferences
		And CurrentRow.RowCode = 0 Then
		CurrentRow.OrderDiscrepancy_3 = 1;
	Else
		CurrentRow.OrderDiscrepancy_3 = 0;
	EndIf;
	
EndProcedure

&AtServer
Procedure DetermineShipmentStarted()
	
	If Object.BusinessOperation = Enums.BusinessTransactions.MaterialTransferToProduction
		Or Object.BusinessOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom Then
		ShipmentStarted = InvoicesServer.ThereIsSpendingOrderForShippingOrders(Object.Ref);
	Else
		ShipmentStarted = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region InventoryKinds

&AtServer
Function PutGoodsAndStockTypesInStorage()
	
	OptionsForEditingInventoryTypes       = InventoriesServer.OptionsForEditingInventoryTypes();
	OptionsForEditingInventoryTypes.Warehouse = Object.Sender;
	If Documents.MovementOfProductsAndMaterials.ExcisableGoodsAreUsed(Object) Then
		OptionsForEditingInventoryTypes.UseExcisableGoods = True;
	EndIf;
	Return InventoriesServer.PutGoodsAndStockTypesInStorage(ThisObject, OptionsForEditingInventoryTypes);
	
EndFunction

&AtServer
Procedure GetStockTypesFromStorage(ValueSelected)
	
	InventoriesServer.ProcessInputOfInventoryTypesManually(ValueSelected, ThisForm);
	
EndProcedure

#EndRegion

#Region Tara

&AtClient
Procedure BeforeRecordingOfferToPickUpMultiTurnContainer(Result, AdditionalParameters) Export
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, AdditionalParameters.WriteParameters,,True);
	
EndProcedure

&AtServer
Procedure FillMultiTurnContainersFromStorageServer(AddressOfContainerInStorage)
	
	StructureOfActionsAddedLines = New Structure;
	StructureOfActionsAddedLines.Insert("RecalculateNumberOfPackages");
	AddQualityControlActionsToStructure(StructureOfActionsAddedLines, CacheQualityControl);
	
	ActionStructureModifiedStrings = New Structure;
	ActionStructureModifiedStrings.Insert("RecalculateNumberOfPackages");
	
	ReusablePackageServer.FillMultiTurnContainersFromStorage(
		Object,
		AddressOfContainerInStorage,
		"Goods",
		"Products,Characteristic",
		ActionStructureModifiedStrings,
		StructureOfActionsAddedLines);
		
	AfterChangingStringsProgrammaticallyOnServer(True, True);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Function ThereAreLinesTiedToOrder()
	
	For Each String In Object.Goods Do
		If String.RowCode <> 0 Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

&AtServer
Procedure OnReadCreateAtServer()
	
	UseSeveralWarehouses = GetFunctionalOption("UseSeveralWarehouses");
	
	BusinessTransactionBeforeChange			= Object.BusinessOperation;
	SenderBeforeChange			= Object.Sender;
	DocumentCurrency					= Object.Currency;
	CompanyBeforeChange			= Object.Organization;
	CompanyGiverBeforeChange	= Object.MaterialProviderCompany;
	
	UpdateAvailabilityOfInternalProcessing();
	DeterminePresenceOfOrderScheme();
	
	EstablishUseOfPlannedValue();
	
	CacheQualityControl = QualityControl.DataCacheOfMechanism(Object);
	
	FillInServiceDetailsOfTablePart();
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.MovementOfProductsAndMaterials));
	SetVisibilityOfSeriesElements();
	
	DetermineShipmentStarted();
	
	ConfigurePickUpByOrdersOrdersCommand();
	UpdateOrderInformation();
	
	UpdateVATTaxation_(False);
	
	SetShopPantryAttribute("Sender");
	SetShopPantryAttribute("Recipient");
	
	ConfigureDependentFormElementsOnServer();
	LimitValueType("Sender");
	LimitValueType("Recipient");
	
	UpdateInformationOnDeviationFromOrders(
		Object.Goods,
		LabelDiscrepancy, 
		Items.PictureDiscrepancy1,
		Items.PictureDiscrepancy2);
	ProcessingOfTabularForms.InitializeRowCache(Items.Goods);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Standard design
	#Region StandardAppearance
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm);
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm);
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisForm);	
	
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction
		Or Object.BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromProduction Then
		ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisForm, False);
	Else
		ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisForm, "SeriesWhenPlanningShipmentWHGoodsAreIndicated");
	EndIf;
	
	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisForm, False);
	#EndRegion
	
	// The color of the text in the Order field
	#Region ProductsAndTextColor
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsReferenceOrder.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ReferenceOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	#EndRegion
	
	// Only inspection of the Order field
	#Region ProductsOrderViewOnly
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsReferenceOrder.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ReferenceOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	#EndRegion
	
	// The text "Over the order, the order is not selected" in the Order field when transferring materials to the storeroom.
	#Region GoodsOrderTextOverOrder
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsReferenceOrder.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom;
	
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
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Vượt quá trên đơn hàng, chưa chọn đơn hàng';
													|ru = 'Сверх заказа, заказ не выбран';
													|en = 'In excess of the order, the order is not selected'; fa = 'In excess of the order, the order is not selected';
													|it = 'Oltre all''ordine, l''ordine non è selezionato';
													|pl = 'Przewyższa zamówienie, zamówienie nie wybrane';
													|tr = 'Sipariş fazlası, sipariş seçilmedi'"));
	#EndRegion
	
	// The text "The order is not filled in" in the Order field when transferring materials to the storeroom.
	#Region ProductsOrderTextNotFilledIn
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsReferenceOrder.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ReferenceOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ErrorNoteText);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Lệnh chưa được điền';
													|ru = 'Распоряжение не заполнено';
													|en = 'Reference is not filled in'; fa = 'Reference is not filled in';
													|it = 'La disposizione non è compilata';
													|pl = 'Nie wypełniono zamówienia';
													|tr = 'Talimat doldurulmadı'"));
	#EndRegion
	
	// Hide the Order field
	#Region ProductsAndVisibility
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsReferenceOrder.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReferenceOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ByReferences");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	#EndRegion
	
	// Text "<without assignment>"
	#Region ProductsPurposeViewOnly
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPurpose.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.OrderDiscrepancy_3");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ByReferences");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Purpose");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không mục đích>';
													|ru = '<без назначения>';
													|en = '<without assignment>'; fa = '<بدون تخصیص>';
													|it = '<senza assegnazione>';
													|pl = '<bez przeznaczenia>';
													|tr = '<atamasız>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	#EndRegion
	
	// Forbidding the editing of the assignment
	#Region ProductsPurposeViewOnly
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPurpose.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 0;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ByReferences");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	#EndRegion
	
	#Region TargetCost
	// Visibility of planned cost fields.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPrice.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSum.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseTargetCost");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);

	// Availability of planned cost fields.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPrice.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSum.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.SideProduct");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Không bắt buộc>';
													|ru = '<Не требуется>';
													|en = '<Not needed>'; fa = '<Not needed>';
													|it = '<non richiesto>';
													|pl = '<Nie jest wymagane>';
													|tr = '<Gerekli değil>'"));
	
	// Mark blank.
	// Price.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPrice.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.SideProduct");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Price");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	// The amount.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSum.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.SideProduct");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Sum");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	#EndRegion
	
	Fields = QualityControl.Fields(
		Items.GoodsToControlQuality,
		Items.GoodsQualityConfirmationDate);
	FlagDisabled = New Array();
	QualityControl.AddFilter(FlagDisabled, "Object.BusinessOperation",
		Enums.BusinessTransactions.TransferOfProductsFromProduction);
	QualityControl.AddFilter(FlagDisabled, "Object.BusinessOperation",
		Enums.BusinessTransactions.MaterialTransferToProduction);
	QualityControl.AddFilter(FlagDisabled, "Object.BusinessOperation",
		Enums.BusinessTransactions.ReturnOfMaterialsFromProduction);
	QualityControl.SetupAppearance(ConditionalAppearance, Fields, FlagDisabled);
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(AttributesList = "")
	
	StructureOfChangedProps = New Structure(AttributesList);
	
	FieldsPresentation = New FixedStructure(Documents.MovementOfProductsAndMaterials.FieldsPresentation(Object));
	
	SetVisibilityWhenChangingBankingDetails(StructureOfChangedProps);
	SetHeadersWhenChangingBankingDetails(StructureOfChangedProps);
	ConfigureDependentElementsOfInternalProcessing(ThisObject, StructureOfChangedProps);
	SetOtherPropertiesWhenChangingBankingDetails(StructureOfChangedProps);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentElementsOfInternalProcessing(Form, AttributesList = "")
	
	Object = Form.Object;
	Items = Form.Items;
	
	If TypeOf(AttributesList) = Type("String") Then
		AttributesStructure1 = New Structure(AttributesList);
	Else
		AttributesStructure1 = AttributesList;
	EndIf;
	
	Initialize =
		AttributesStructure1.Count() = 0;
	
	If Initialize
		Or AttributesStructure1.Property("ByReferences")
		Or AttributesStructure1.Property("BusinessOperation")
		Or AttributesStructure1.Property("InternalSubcontracting") Then
		Items.MaterialProviderCompany.ReadOnly = Not Object.InternalSubcontracting;
	EndIf;
	
	If Initialize
		Or AttributesStructure1.Property("InternalSubcontracting")
		Or AttributesStructure1.Property("BusinessOperation")
		Or AttributesStructure1.Property("MaterialProviderCompany") Then
		Items.MaterialProviderCompany.MarkIncomplete =
			Object.InternalSubcontracting
			And Not ValueIsFilled(Object.MaterialProviderCompany);
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateAvailabilityOfInternalProcessing()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	MIN(StageDetails_.ProductionLot.InternalSubcontracting) AS InternalSubcontracting
	|FROM
	|	Document.ProductionStage2_2 AS StageDetails_
	|WHERE
	|	StageDetails_.Ref IN(&References)
	|";
	Query.SetParameter("References", Object.Goods.Unload(, "ReferenceOrder").UnloadColumn("ReferenceOrder"));
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	If Selection.Next() Then
		InternalRecyclingIsAvailable = Selection.InternalSubcontracting;
	EndIf;
	
EndProcedure
&AtServer
Procedure SetVisibilityWhenChangingBankingDetails(StructureOfChangedProps)

	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	
	AllAttributes = (StructureOfChangedProps.Count() = 0); 
	
	If StructureOfChangedProps.Property("ByReferences") 
		Or StructureOfChangedProps.Property("BusinessOperation")
		Or AllAttributes Then
		LinesExceedingTheOrderAreAvailable = (Object.BusinessOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom);
		// COMMANDS OF THE TABLE PART
		// You need to hide all commands that can add lines that are not tied to the stage
		Items.GoodsUnlinkFromOrder.Visible              = Object.ByReferences And LinesExceedingTheOrderAreAvailable;
		Items.GoodsInsertRows.Visible                = Not Object.ByReferences Or LinesExceedingTheOrderAreAvailable;
		Items.GoodsContextMenuInsertRows.Visible = Not Object.ByReferences Or LinesExceedingTheOrderAreAvailable;
		Items.GoodsSearchByBarcode.Visible              = Not Object.ByReferences Or LinesExceedingTheOrderAreAvailable;
		Items.GoodsSelectGoods.Visible               = Not Object.ByReferences Or LinesExceedingTheOrderAreAvailable;
		Items.GoodsAddReusablePackage.Visible  = Not Object.ByReferences Or LinesExceedingTheOrderAreAvailable;
		Items.GoodsFillInSeriesByFEFO.Visible          = Not Object.ByReferences Or LinesExceedingTheOrderAreAvailable;
		Items.GoodsChangeQuality.Visible =
			Not Object.ByReferences
			And (Object.BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromStoreroom);
		
		// The commands of the connected equipment may not be available according to the settings
		TMCommonUse.CustomizePeripherals(ThisObject);
		Items.GoodsImportDataFromPDT.Visible          = Items.GoodsImportDataFromPDT.Visible
																And (Not Object.ByReferences
																	Or LinesExceedingTheOrderAreAvailable);
		
		// ELEMENTS OF THE TABULAR PART
		Items.GoodsPurpose.Visible = FieldsPresentation.TypeRecipient <> "Department";
		
		// Internal Processing
		Items.InternalSubcontracting.Visible = InternalRecyclingIsAvailable;
		Items.MaterialProviderCompany.Visible = InternalRecyclingIsAvailable;
	EndIf;
	
	If StructureOfChangedProps.Property("ByReferences") Or AllAttributes Then
		// ELEMENTS OF THE TABULAR PART
		Items.GoodsRowCode.Visible = Object.ByReferences;
	EndIf;
	
	If StructureOfChangedProps.Property("BusinessOperation")
		Or StructureOfChangedProps.Property("UseTargetCost")
		Or AllAttributes Then
		
		Items.PriceKind.Visible = 
			UseTargetCost
				And Object.BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction;
		
		Items.FillInPricesGroup.Visible =
			UseTargetCost
				And Object.BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction;
		
	EndIf;
	
	If StructureOfChangedProps.Property("BusinessOperation") Or AllAttributes Then
		
		If Not UseSeveralWarehouses Then
			Items.Sender.Visible = (FieldsPresentation.SenderType = "Department");
			Items.Recipient.Visible = (FieldsPresentation.TypeRecipient = "Department");
		EndIf;
		
		Documents.MovementOfProductsAndMaterials.FillInNamesOfBusinessTransactionDetails(
			Object.BusinessOperation, 
			ArrayOfAllProps, 
			ArrayOfOperationDetails);
			
		CashServer.SetVisibilityOfElementsByArray(
			Items,
			ArrayOfAllProps,
			ArrayOfOperationDetails);
		
		// INPUT COMMANDS BASED ON
		If Not AllAttributes Then
			SetVisibilityOfInputCommandsBasedOn_();
		EndIf;
		
		// COMMANDS OF THE TABLE PART
		
		ByStep = Object.BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction
			Or Object.BusinessOperation = Enums.BusinessTransactions.MaterialTransferToProduction
			Or Object.BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromProduction;
		
		Items.RoundToTheWholePackage.Visible =
			(Object.BusinessOperation = Enums.BusinessTransactions.MaterialTransferToProduction
			Or Object.BusinessOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom);
		
		Items.GoodsFillOutOrders.Visible = ByStep
			Or Object.BusinessOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom;
		
		ItemArray = New Array;
		ItemArray.Add("GoodsAdd");
		ItemArray.Add("GoodsCopy");
		ItemArray.Add("ProductsContextMenuAdd");
		ItemArray.Add("ProductItemsContextMenuCopy");
		
		TMCommonUseClientServer.SetPropertyOfFormElements(Items,
			ItemArray, "Enabled", Not ByStep);
		
	EndIf;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom Then
		Items.ByReference.Visible  = True;
		Items.ByReferences.Visible = True;
		
		Items.ReferenceOrder.TitleLocation        = FormItemTitleLocation.None;
		Items.LabelReferences.TitleLocation = FormItemTitleLocation.None;
	Else
		Items.ByReference.Visible  = False;
		Items.ByReferences.Visible = False;
		
		Items.ReferenceOrder.TitleLocation        = FormItemTitleLocation.Auto;
		Items.LabelReferences.TitleLocation = FormItemTitleLocation.Auto;
	EndIf;
	
	If Not ValueIsFilled(Object.ReferenceOrder) And ListOfOrders_.Count() = 0 Then
		Items.CloseOrder.Visible = False;
		Items.CloseOrders_2.Visible = False;
	Else
		Items.CloseOrder.Visible = True;
		Items.CloseOrders_2.Visible = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetHeadersWhenChangingBankingDetails(StructureOfChangedProps)

	AllAttributes = (StructureOfChangedProps.Count() = 0); 
	
	If StructureOfChangedProps.Property("BusinessOperation") 
		Or StructureOfChangedProps.Property("ByReferences") 
		Or AllAttributes  Then
		
		Items.Sender.Title = FieldsPresentation.Sender;
		Items.Recipient.Title = FieldsPresentation.Recipient;
		Items.Sender.ToolTip = FieldsPresentation.SenderHint;
		Items.Recipient.ToolTip = FieldsPresentation.RecipientHint;
		
	EndIf;
	
	If StructureOfChangedProps.Property("BusinessOperation") Or AllAttributes Then
		
		//
		If Object.BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction
			Or Object.BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromStoreroom Then
			VATTaxation_ = NStr("vi = 'Xuất xưởng theo hoạt động';
								|ru = 'Выпуск под деятельность';
								|en = 'Release for activity'; fa = 'تولید برای فعالیت';
								|it = 'Produzione per attività';
								|pl = 'Wypuszczenie na działalność';
								|tr = 'Faaliyet altında ürün çıkışı'");
		ElsIf Object.BusinessOperation = Enums.BusinessTransactions.MaterialTransferToProduction
			Or Object.BusinessOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom Then
			VATTaxation_ = NStr("vi = 'Nhu cầu cho hoạt động';
								|ru = 'Потребление для деятельности';
								|en = 'Consumption for activity'; fa = 'مصرف برای فعالیت';
								|it = 'Consumo per attività';
								|pl = 'Zużycie do działalności';
								|tr = 'Faaliyet tüketimi'");
		ElsIf Object.BusinessOperation = Enums.BusinessTransactions.TransferOfSemiFinishedProducts
			Or Object.BusinessOperation = Enums.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices Then
			VATTaxation_ = NStr("vi = 'Điều chuyển theo hoạt động';
								|ru = 'Перемещение под деятельность';
								|en = 'Transfer for activity'; fa = 'انتقال برای فعالیت';
								|it = 'Trasferimento per attività';
								|pl = 'Transfer w ramach działalności';
								|tr = 'Faaliyet altında transfer'");
		Else
			VATTaxation_ = Items.VATTaxation.Title;
		EndIf;
		Items.VATTaxation.Title = VATTaxation_;
		
		//
		If Object.BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction
			Or Object.BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromStoreroom Then
			Items.GoodsSelectGoods.Title = NStr("vi = 'Chọn hàng hóa';
												|ru = 'Подобрать продукцию';
												|en = 'Pick products'; fa = 'انتخاب محصولات';
												|it = 'Selezionare i prodotti';
												|pl = 'Wybierz produkcję';
												|tr = 'İmal edilen ürünü seç'");
		ElsIf Object.BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromProduction
			Or Object.BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromStoreroom Then
			Items.GoodsSelectGoods.Title = NStr("vi = 'Chọn nguyên vật liệu';
												|ru = 'Подобрать материалы';
												|en = 'Pick materials'; fa = 'انتخاب مواد';
												|it = 'Selezionare materiali';
												|pl = 'Wybierz materiały';
												|tr = 'Malzemeleri seç'");
		ElsIf Object.BusinessOperation = Enums.BusinessTransactions.MaterialTransferToProduction
			Or Object.BusinessOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom Then
			Items.GoodsSelectGoods.Title = NStr("vi = 'Chọn nguyên vật liệu';
												|ru = 'Подобрать материалы';
												|en = 'Pick materials'; fa = 'انتخاب مواد';
												|it = 'Selezionare materiali';
												|pl = 'Wybierz materiały';
												|tr = 'Malzemeleri seç'");
		ElsIf Object.BusinessOperation = Enums.BusinessTransactions.TransferOfSemiFinishedProducts
			Or Object.BusinessOperation = Enums.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices Then
			Items.GoodsSelectGoods.Title = NStr("vi = 'Chọn nguyên vật liệu';
												|ru = 'Подобрать материалы';
												|en = 'Pick materials'; fa = 'انتخاب مواد';
												|it = 'Selezionare materiali';
												|pl = 'Wybierz materiały';
												|tr = 'Malzemeleri seç'");
		EndIf;

		//
		Items.GroupGoods.Title = FieldsPresentation.Goods;
		
		//
		If FieldsPresentation.Property("Organization") Then
			Items.Organization.Title = FieldsPresentation.Organization;
		EndIf;
		
		RefreshFormTitle();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetOtherPropertiesWhenChangingBankingDetails(StructureOfChangedProps)

	AllAttributes = (StructureOfChangedProps.Count() = 0); 
	
	If StructureOfChangedProps.Property("BusinessOperation") 
		Or StructureOfChangedProps.Property("ByReferences")
		Or AllAttributes Then
		
		If FieldsPresentation.SenderType = "Warehouse" Or FieldsPresentation.SenderType = "Storeroom" Then
			Items.Sender.TypeRestriction = New TypeDescription("CatalogRef.Warehouses");
		Else
			Items.Sender.TypeRestriction = New TypeDescription("CatalogRef.BusinessStructure");
		EndIf; 
		If FieldsPresentation.TypeRecipient = "Warehouse" Or FieldsPresentation.TypeRecipient = "Storeroom" Then
			Items.Recipient.TypeRestriction = New TypeDescription("CatalogRef.Warehouses");
		Else
			Items.Recipient.TypeRestriction = New TypeDescription("CatalogRef.BusinessStructure");
		EndIf;
		
		// Selection Parameters - Sender
		ChoiceParametersArray = New Array;
		If FieldsPresentation.SenderType = "Warehouse" Then
			TypesArray = New Array;
			TypesArray.Add(Enums.TypesOfWarehouses.WholesaleWarehouse);
			TypesArray.Add(Enums.TypesOfWarehouses.RetailStore);
			ChoiceParametersArray.Add(New ChoiceParameter("Filter.WarehouseStore", New FixedArray(TypesArray)));
		ElsIf FieldsPresentation.SenderType = "Storeroom" Then
			ChoiceParametersArray.Add(New ChoiceParameter("Filter.ShopFloorStockroom", True));
		ElsIf FieldsPresentation.SenderType = "Department" Then
			ChoiceParametersArray.Add(New ChoiceParameter("Filter.ProductionBusinessUnit", True));
		EndIf; 
		Items.Sender.ChoiceParameters = New FixedArray(ChoiceParametersArray);
		
		// Selection Parameters - Recipient
		ChoiceParametersArray = New Array;
		If FieldsPresentation.TypeRecipient = "Warehouse" Then
			TypesArray = New Array;
			TypesArray.Add(Enums.TypesOfWarehouses.WholesaleWarehouse);
			TypesArray.Add(Enums.TypesOfWarehouses.RetailStore);
			ChoiceParametersArray.Add(New ChoiceParameter("Filter.WarehouseStore", New FixedArray(TypesArray)));
		ElsIf FieldsPresentation.TypeRecipient = "Storeroom" Then
			ChoiceParametersArray.Add(New ChoiceParameter("Filter.ShopFloorStockroom", True));
		ElsIf FieldsPresentation.TypeRecipient = "Department" Then
			ChoiceParametersArray.Add(New ChoiceParameter("Filter.ProductionBusinessUnit", True));
		EndIf; 
		Items.Recipient.ChoiceParameters = New FixedArray(ChoiceParametersArray);
		
		//
		AvailableSelectionByOrder = AvailableSelectionByOrder(Object);
		If AvailableSelectionByOrder And ListOfOrders_.Count() > 1 Then
			Items.PagesOrder.CurrentPage = Items.OrdersPage;
		ElsIf AvailableSelectionByOrder Then
			Items.PagesOrder.CurrentPage = Items.PageOrder;
		Else
			Items.PagesOrder.CurrentPage = Items.PageWithoutReferences;
		EndIf;
		
	EndIf;

EndProcedure

&AtServer
Procedure UpdateVATTaxation_(Fill = True)
	
	FillParameters = Documents.MovementOfProductsAndMaterials.ParametersForFillingInVATActivityType(Object);
	If Fill Then
		VATAccountingERP.FillInTypeOfActivityVAT(
			Object.VATTaxation,
			FillParameters,
			VATAccountingCachedParameterValues);
	EndIf;
	
	VATAccountingERP.FillInActivitySelectionList(
		Items.VATTaxation,
		Object.VATTaxation,
		FillParameters,
		VATAccountingCachedParameterValues);
	
EndProcedure

&AtServer
Procedure LimitValueType(FieldName)
	
	CastedValue = Items[FieldName].TypeRestriction.AdjustValue(Object[FieldName]);
	
	If Not Object[FieldName] = CastedValue Then
		Object[FieldName] = CastedValue;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfInputCommandsBasedOn_()
	AttachableCommandsClientServer.UpdateCommands(ThisForm, Object);
EndProcedure

&AtServer
Procedure RefreshFormTitle()
	
	If ValueIsFilled(Object.Ref) Then
		Template = NStr("vi = '%1 %2 ngày %3';
						|ru = '%1 %2 от %3';
						|en = '%1 %2 dated %3'; fa = '%1 %2 dated %3';
						|it = '%1 %2 del %3';
						|pl = '%1 %2 z dnia %3';
						|tr = '%3 tarihli %1 %2'");
	Else
		Template = NStr("vi = '%1 (tạo mới)';
						|ru = '%1 (создание)';
						|en = '%1 (Create)'; fa = '%1 (Create)';
						|it = '%1 (creazione)';
						|pl = '%1 (utworzenie)';
						|tr = '%1 (oluşturma)'");
	EndIf;
	PresentationOperation = Documents.MovementOfProductsAndMaterials.TransactionList().FindByValue(Object.BusinessOperation);
	If PresentationOperation <> Undefined Then
		PresentationOperation = PresentationOperation.Presentation;
	Else
		PresentationOperation = Object.BusinessOperation;
	EndIf;
	
	Title = StringFunctionsClientServer.SubstituteParametersToString(
					Template, PresentationOperation, Object.Number, Object.Date);

EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(Form, StructureOfActions)
	
	AddActionRecalculateNumberOfUnits(Form, StructureOfActions);
	StructureOfActions.Insert("RecalculateAmount");
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingProducts(Form, CurrentRow, StructureOfActions)

	If CurrentRow <> Undefined Then
		StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
		StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	Else
		StructureOfActions.Insert("CheckFillPackageByOwner");
	EndIf;
	
	AddActionRecalculateNumberOfUnits(Form, StructureOfActions);
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	
	SeriesVerificationParameters = New Structure("Warehouse, SeriesSpecificationParameters");
	SeriesVerificationParameters.Warehouse = New Structure("Sender, Recipient", Form.Object.Sender, Form.Object.Recipient);
	SeriesVerificationParameters.SeriesSpecificationParameters = Form.SeriesSpecificationParameters;
	StructureOfActions.Insert("CheckSeriesCalculateStatus", SeriesVerificationParameters);

	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		Form, "Products", StructureOfActions);
	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		Form.FormName, "Goods"));
	
	SupplyClientServer.StructureOfInsertActionsWhenChangingAssignment(StructureOfActions);

EndProcedure

&AtClientAtServerNoContext
Procedure AddQualityControlActionsToStructure(StructureOfActions, CacheQualityControl)
	
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsOfTablePart()
	
	UpdateDeviationsFromOrder();
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	ParametersForFillingInBankingDetails.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Products", ParametersForFillingInBankingDetails);
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods,ParametersForFillingInBankingDetails);
		
EndProcedure

&AtServer
Procedure FillInListOfOperations()
	
	OperationsInOrderOfAddition = New Array();
	OperationsInOrderOfAddition.Add(Enums.BusinessTransactions.TransferOfProductsFromProduction);
	OperationsInOrderOfAddition.Add(Enums.BusinessTransactions.TransferOfProductsFromStoreroom);
	OperationsInOrderOfAddition.Add(Enums.BusinessTransactions.MaterialTransferToProduction);
	OperationsInOrderOfAddition.Add(Enums.BusinessTransactions.TransferOfMaterialsToStoreroom);
	OperationsInOrderOfAddition.Add(Enums.BusinessTransactions.ReturnOfMaterialsFromProduction);
	OperationsInOrderOfAddition.Add(Enums.BusinessTransactions.ReturnOfMaterialsFromStoreroom);
	OperationsInOrderOfAddition.Add(Enums.BusinessTransactions.TransferOfSemiFinishedProducts);
	OperationsInOrderOfAddition.Add(Enums.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices);
	
	AvailableTransactions = Documents.MovementOfProductsAndMaterials.TransactionList();
	
	Items.BusinessOperation.ChoiceList.Clear();
	For Each CollectionItem In OperationsInOrderOfAddition Do
		
		AvailableOperation = AvailableTransactions.FindByValue(CollectionItem);
		If AvailableOperation <> Undefined Then
			Items.BusinessOperation.ChoiceList.Add(AvailableOperation.Value, AvailableOperation.Presentation);
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

// This procedure should be used if the rows were added programmatically (not interactively), for example, when pasting from
// a buffer, or when selecting from orders. The procedure performs actions that depend on the data in the rows.
//
&AtServer
Procedure AfterChangingStringsProgrammaticallyOnServer(FillInServiceDetails = False, FillInStatusesForSpecifyingSeries = True)

	If FillInStatusesForSpecifyingSeries Then
		FillInStatusesForSpecifyingSeriesServer();
	EndIf;
	
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
	UpdateOrderInformation();
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom
		And Object.ByReferences <> (ValueIsFilled(Object.ReferenceOrder) Or ListOfOrders_.Count() > 0) Then
		ConfigureDependentFormElementsOnServer("ByReferences");
	EndIf;
	
	UpdateDeviationsFromOrder();
	UpdateInformationOnDeviationFromOrdersServer();
	
	If FillInServiceDetails Then
		FillInServiceDetailsOfTablePart();
	EndIf;
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
EndProcedure

&AtServer
Procedure ProcessLineAddedProgrammatically(CurrentRow, CachedValues)
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingProducts(ThisForm, CurrentRow, StructureOfActions);
	AddQualityControlActionsToStructure(StructureOfActions, CacheQualityControl);
	
	StructureOfActions.Delete("CheckSeriesCalculateStatus"); // this action can only be performed during interactive editing
	
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom
		And Object.ByReferences
		And CurrentRow.RowCode = 0 Then
		CurrentRow.OrderDiscrepancy_3 = 1;
	EndIf;

EndProcedure

&AtClientAtServerNoContext
Function AvailableSelectionByOrder(Object)

	Return Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferOfMaterialsToStoreroom")
			Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.MaterialTransferToProduction")
			Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferOfProductsFromProduction")
			Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnOfMaterialsFromProduction")
			;

EndFunction

&AtServer
Procedure StatusOnChangeServer(FillInShippingInstructions)
	
	If FillInShippingInstructions Then
		Documents.MovementOfProductsAndMaterials.FillInShippingInstructions(Object);
	EndIf;
	
	FillInStatusesForSpecifyingSeriesServer(True);
	
EndProcedure

&AtServer
Procedure DeterminePresenceOfOrderScheme()

	AdvancedWarehousing = False;
	YouCanPopulateSeriesByShipment = False;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.MaterialTransferToProduction
		Or Object.BusinessOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom Then
		AdvancedWarehousing = WarehousesServer.UseWarehouseManagemantSystemForGoodsIssue(Object.Sender, Object.Date);
		YouCanPopulateSeriesByShipment = AdvancedWarehousing;
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction
		Or Object.BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromStoreroom
		Or Object.BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromProduction
		Or Object.BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromStoreroom Then
		AdvancedWarehousing = WarehousesServer.UseWarehouseManagemantSystemForGoodsReceipt(Object.Recipient, Object.Date);
	EndIf;

EndProcedure

&AtServer
Procedure ConfigurePickUpByOrdersOrdersCommand()
	
	UseOrders = Object.BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction
		Or Object.BusinessOperation = Enums.BusinessTransactions.MaterialTransferToProduction
		Or Object.BusinessOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom
		Or Object.BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromProduction;
	
	Items.GoodsSelectGoodsByOrdersNotes.Visible = AdvancedWarehousing Or UseOrders;
	
	If UseOrders Then
		
		If AdvancedWarehousing Then
			
			Items.GoodsSelectGoodsByOrdersNotes.Title = NStr("vi = 'Nhận hàng theo lệnh / đơn hàng';
															|ru = 'Подобрать товары по распоряжениям/ордерам';
															|en = 'Pick goods by references/notes'; fa = 'انتخاب کالا بر اساس مراجع/حواله‌ها';
															|it = 'Selezionare le merci secondo le disposizioni/mandati';
															|pl = 'Wybierz wiersze pozycji wg zamówień/zleceń';
															|tr = 'Talimatlara/emirlere göre ürünleri seç'");
			
		Else
			
			Items.GoodsSelectGoodsByOrdersNotes.Title = NStr("vi = 'Nhận hàng theo lệnh';
															|ru = 'Подобрать товары по распоряжениям';
															|en = 'Pick goods by references'; fa = 'Pick goods by references';
															|it = 'Selezionare le merci in base alle disposizioni';
															|pl = 'Wybierz wiersze pozycji wg zamówień';
															|tr = 'Talimatlara göre ürünleri seç'");
			
		EndIf;
		
	Else
		
		Items.GoodsSelectGoodsByOrdersNotes.Title = NStr("vi = 'Chọn hàng hóa theo lệnh';
														|ru = 'Подобрать товары по ордерам';
														|en = 'Pick goods by notes'; fa = 'انتخاب کالا بر اساس حواله‌ها';
														|it = 'Selezionare le merci in base ai mandati';
														|pl = 'Wybierz wiersze pozycji wg zleceń';
														|tr = 'Emirlere göre ürün seç'");
		
	EndIf;
	
	If Object.Patch Then
		Items.GoodsSelectGoodsByOrdersNotes.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure RoundToTheWholePackageCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	RoundUpToWholePackageOnServer(CachedValues);
	NotificationText1 = NStr("vi = 'Các hàng được chọn được làm tròn cho toàn bộ đơn vị.';
							|ru = 'В выбранных строках выполнено округление до целых единиц.';
							|en = 'The selected lines are rounded up to integral units.'; fa = 'The selected lines are rounded up to integral units.';
							|it = 'Nelle righe selezionate è eseguito arrotondamento a intere unità.';
							|pl = 'W wybranych wierszach wykonano zaokrąglenie do liczb całkowitych.';
							|tr = 'Seçilen satırlarda tam sayı birimlerine yuvarlama gerçekleşti.'");
	ShowUserNotification(NStr("vi = 'Hoàn thành làm tròn';
								|ru = 'Выполнено округление';
								|en = 'Rounded'; fa = 'گردشده';
								|it = 'Eseguito arrotondamento';
								|pl = 'Wykonano zaokrąglenie';
								|tr = 'Yuvarlama gerçekleşti'"),, NotificationText1, PictureLib.Success32);
	
EndProcedure

&AtServer
Procedure RoundUpToWholePackageOnServer(CachedValues)

	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(ThisObject, StructureOfActions);
	
	SelectedRows = Items.Goods.SelectedRows;
	RowsToProcess = New Array();
	CachedValuesTSProcessing = Common.CopyRecursive(CachedValues);
	
	For Each RowID In SelectedRows Do
		RowData = Object.Goods.FindByID(RowID);
		If Int(RowData.NumberOfPackages) = RowData.NumberOfPackages Then
			Continue;
		EndIf;
		RowData.NumberOfPackages = Int(RowData.NumberOfPackages) + 1;
		RowsToProcess.Add(RowData);
	EndDo;

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValuesTSProcessing);
			
	FillInStatusesForSpecifyingSeriesServer();
	
EndProcedure

&AtServer
Procedure EstablishUseOfPlannedValue()
	
	AccountingPolicyParameters = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate(
		"FinancialAccountingPolicy",
		Object.Organization,
		Object.Date);
	
	
	If Not AccountingPolicyParameters = Undefined Then
		
		UseTargetCost = AccountingPolicyParameters.ProductCostingByPlannedCost;
		ConfigureDependentFormElementsOnServer("UseTargetCost");
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetShopPantryAttribute(WarehouseFieldName, StructureOfActions = Undefined)
	
	If WarehouseFieldName = "Sender" Then
		FieldNameShopPantry = "SenderWorkshopStoreroom";
	ElsIf WarehouseFieldName = "Recipient" Then
		FieldNameShopPantry = "RecipientWorkshopStoreroom";
	EndIf;
	
	WarehouseValue = Object[WarehouseFieldName];
	MeaningShopPantryBeforeChange = ThisObject[FieldNameShopPantry];
	
	SetPrivilegedMode(True);
	MeaningShopPantry = 
		?(TypeOf(WarehouseValue) <> Type("CatalogRef.Warehouses") Or Not ValueIsFilled(WarehouseValue),
			False, Common.ObjectAttributeValue(WarehouseValue, "ShopFloorStockroom"));
	SetPrivilegedMode(False);
	
	ThisObject[FieldNameShopPantry] = MeaningShopPantry;
	
	If StructureOfActions <> Undefined And MeaningShopPantryBeforeChange <> MeaningShopPantry Then
		AddActionRecalculateNumberOfUnits(ThisObject, StructureOfActions);	
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionRecalculateNumberOfUnits(Form, StructureOfActions)
	
	StructureOfActions.Insert("RecalculateNumberOfUnits", 
		New Structure("MustBeRoundOff", Not Form.SenderWorkshopStoreroom And Not Form.RecipientWorkshopStoreroom));
	
EndProcedure	

#EndRegion

#Region StandardSubsystems

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

&AtClient
Procedure BusinessTransactionOnChangeEnd(QuestionResult, ByOrdersBeforeChange) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		BusinessOperationWhenChangingOnServer();
		UntieDocumentFromOrders();
	Else
		Object.BusinessOperation = BusinessTransactionBeforeChange;
		Object.ByReferences = ByOrdersBeforeChange;
	EndIf;
	
EndProcedure

&AtClient
Procedure LinkToReferences(Command)
	
	BindStringsToOrdersOnServer();
	
EndProcedure

&AtServer
Procedure BindStringsToOrdersOnServer()
	
	BindRowsToOrders();
	AfterChangingStringsProgrammaticallyOnServer(True);
	
EndProcedure

#EndRegion

#Region Orders_3

// Procedure-re-Fill on orders orders
//
// Parameters:
//	FillingData - Structure - order data
//
&AtServer
Procedure RefillByNotes(FillingData)

	AnArrayOfOrders = FillingData.AnArrayOfOrders;
	
	FillParameters = Documents.MovementOfProductsAndMaterials.DocumentFillingParameters();
	FillParameters.Insert("FormIsOpen", True);
	FillParameters.Insert("FillByWarehouseDocument", True);
	
	InvoiceTable = Documents.MovementOfProductsAndMaterials.TableDataAndDocument(Object.Ref);
	
	HeaderAttributes = New Structure("Organization, Recipient, Sender, BusinessOperation, Ref, GoodsReceiptOption");
	FillPropertyValues(HeaderAttributes, Object);
	
	SelectionByGoodsIsEstablished = False;
	If FillingData.Property("FilterByGoods") Then
		
		HeaderAttributes.Insert("FilterByGoods", FillingData.FilterByGoods);
		
		FiltersSettings         = Documents.MovementOfProductsAndMaterials.GetSelectionSettings_(HeaderAttributes);
		SelectionByGoodsIsEstablished = FiltersSettings <> Undefined;
		
		If SelectionByGoodsIsEstablished Then
			
			FilterFields = "Ref, Products, Characteristic";
			
			TableFilters  = FiltersSettings.TableFilters;
			TableFilters.Indexes.Add(FilterFields);
			
			FilterStructure1 = New Structure(FilterFields);
			
		EndIf;
		
	EndIf;	
	
	Documents.MovementOfProductsAndMaterials.InitializeFillingParameters(FillParameters, HeaderAttributes, AnArrayOfOrders);
	
	Documents.MovementOfProductsAndMaterials.FillInByOrdersOrders(InvoiceTable, Object.Ref, FillParameters);
	
	FillingInAcceptanceForm = Object.BusinessOperation <> Enums.BusinessTransactions.MaterialTransferToProduction
		And Object.BusinessOperation <> Enums.BusinessTransactions.TransferOfMaterialsToStoreroom;
	InvoiceIsOrder = PurchasesServer.OrderForAcceptanceOfGoodsConsignmentNote(Object.GoodsReceiptOption);
	NumberOfIndexes = InvoiceTable.Count() - 1;
	For IndexOf = 0 To NumberOfIndexes Do
		
		String = InvoiceTable[NumberOfIndexes - IndexOf];
		
		OrderInOrders = AnArrayOfOrders.Find(String.ReferenceOrder) <> Undefined;
		
		If Not (FillingInAcceptanceForm And InvoiceIsOrder) And Not OrderInOrders Then
			Continue;
		EndIf;	
		
		If SelectionByGoodsIsEstablished Then
			
			FillPropertyValues(FilterStructure1, String);
			FilterStructure1.Ref = ?(OrderInOrders, String.ReferenceOrder, Object.Ref);
			
			FoundRows = TableFilters.FindRows(FilterStructure1);
			If FoundRows.Count() > 0 Then
				If String.NoteQuantity > 0 Then
					String.Count = String.NoteQuantity;
				Else
					InvoiceTable.Delete(String);
				EndIf;
			EndIf;
			
		Else
			If String.NoteQuantity > 0 Then
				String.Count = String.NoteQuantity;
			Else
				InvoiceTable.Delete(String);
			EndIf;
		EndIf;	
		
	EndDo;
	
	Object.Goods.Load(InvoiceTable);
	
	StructureOfActions = New Structure;
	AddQualityControlActionsToStructure(StructureOfActions, CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
	
	// Recalculating the Quantity of Packages field
	Documents.MovementOfProductsAndMaterials.UpdateDependentDetailsOfTablePart(Object.Goods, FillParameters);
	
	// Post-processing is individual for the document
	If Object.BusinessOperation = Enums.BusinessTransactions.MaterialTransferToProduction
		Or Object.BusinessOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom Then
		Documents.MovementOfProductsAndMaterials.FillInShippingInstructions(
			Object, ?(SelectionByGoodsIsEstablished, TableFilters, Undefined));
	EndIf;
	
	FillInServiceDetailsOfTablePart();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	UpdateOrderInformation();
	
	UpdateInformationOnDeviationFromOrders(
		Object.Goods,
		LabelDiscrepancy,
		Items.PictureDiscrepancy1,
		Items.PictureDiscrepancy2);
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
EndProcedure

// End StandardSubsystems.Properties

#EndRegion

#Region TargetCost

&AtServer
Function GoodsFillInPricesByPriceKindServer()
	
	Cancel = False;
	
	SelectedRows = Items.Goods.SelectedRows;
	
	If SelectedRows.Count() = 0 Then
		
		MessageText = NStr("vi = 'Trong bảng ""Hàng hóa và công trình"" không chọn một hàng nào. Giá không thể được điền.';
							|ru = 'В таблице ""Товары и работы"" не выбрано ни одной строки. Цены не могут быть заполнены.';
							|en = 'No row is selected in the ""Goods and labor"" table. Prices cannot be filled in.'; fa = 'No row is selected in the ""Goods and labor"" table. Prices cannot be filled in.';
							|it = 'Nella tabella ""Merci e lavori"" non è stata selezionata alcuna riga. I prezzi non possono essere compilati.';
							|pl = 'W tabeli ""Товары и работы"" nie wybrano ani jednego wierszu. Ceny nie mogą być wypełnione.';
							|tr = '""Ürünler ve İşler"" tablosunda herhangi bir satır seçilmedi. Fiyatlar doldurulamaz.'");
		CommonClientServer.MessageToUser(MessageText,, "Goods", "Object", Cancel);
		
	Else
		
		RowsArray = New Array;
		
		For Each Id In SelectedRows Do
			
			String = Object.Goods.FindByID(Id);
			If String.SideProduct Then
				Continue
			EndIf;
			
			RowsArray.Add(String);
			
		EndDo;
		
		If RowsArray.Count() = 0 Then
			MessageText = NStr("vi = 'Trong các dòng được tô sáng, không có vị trí có sẵn để điền theo loại giá.';
								|ru = 'В выделенных строках отсутствуют позиции, доступные для заполнения по виду цен.';
								|en = 'There are no items available for filling by a price type in the selected lines.'; fa = 'There are no items available for filling by a price type in the selected lines.';
								|it = 'Nelle righe selezionate non ci sono voci disponibili per la compilazione per tipo di prezzi.';
								|pl = 'W wybranych wierszach brak pozycji, dostępnych do wypełnienia według cen.';
								|tr = 'Seçilen satırlarda, fiyat türüne göre doldurulabilecek pozisyon bulunmamaktadır.'");
			CommonClientServer.MessageToUser(MessageText,, "Goods", "Object", Cancel);
		EndIf;
		
	EndIf;
	
	If Not ValueIsFilled(Object.PriceKind) Then
		
		MessageText = NStr("vi = 'Trường ""Dạng giá"" không được điền.';
							|ru = 'Не заполнено поле ""Вид цены"".';
							|en = '""Price type"" is required.'; fa = '""Price type"" is required.';
							|it = 'Il campo ""Tipo di prezzo"" non è compilato.';
							|pl = 'Nie wypełniono pole ""Rodzaj ceny""';
							|tr = '""Fiyat Türü"" alanı doldurulmadı.'");
		CommonClientServer.MessageToUser(MessageText,, "PriceKind", "Object", Cancel);
		
	EndIf;
	
	If Cancel Then
		Return False;
	EndIf;
	
	Return FillInPricesByPriceKindServer(Object.PriceKind, RowsArray);
	
EndFunction

&AtServer
Function FillInPricesByPriceKindServer(PricesKind, RowsArray = Undefined)
	
	If RowsArray = Undefined Then
		RowFilter = New Structure("SideProduct", False);
	Else
		RowFilter = RowsArray;
	EndIf;

	PricesCalculated = EnterprisePricesFillingServer.FillInPrices(
		Object.Goods, // Table part
		RowFilter, // Array of rows or selection structure
		New Structure( // The fill parameters
			"Date, Currency, PriceKind, Organization",
			Object.Date,
			Object.Currency,
			Object.PriceKind,
			Object.Organization),
		New Structure( // The structure of the action with the changed strings
			"RecalculateAmount",
			"NumberOfPackages"));
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Procedure FillInPlanningCalculationsAndPricesOnServer(RowsIDs = Undefined, StandardCostEstimate = Undefined)
	
	If RowsIDs <> Undefined Then
		
		RowsArray = New Array;
		For Each Id In RowsIDs Do
			
			RowOfProduct = Object.Goods.FindByID(Id);
			If RowOfProduct.SideProduct Then
				Continue
			EndIf;
			
			RowsArray.Add(RowOfProduct);
			
		EndDo;
		
	EndIf;
	
	FillParameters = Documents.StandardCosting2_2.DescriptionOfPriceFillingParameterInCollection();
	FillParameters.DocumentDate = Object.Date;
	FillParameters.DocumentCurrency = DocumentCurrency;
	FillParameters.StandardCostEstimate = StandardCostEstimate;
	
	Documents.StandardCosting2_2.FillInPricesByCalculationInCollection(
		Object.Goods,
		RowsArray,
		FillParameters);
	
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
