#Region Variables

&AtClient
Var CachedValues; // used by the mechanism for processing changes in PM details

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
		
		OnReadCreateAtServer();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
		
	EndIf;
	
	If Parameters.FillingValues.Property("FillByWarehouseDocument") Then
		
		Modified = True;
		
		RefillByReceivingServer();
		
	EndIf;
	
	SetElementProperties();
	
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
	
	Var CurrentOperation1;
	
	If ChoiceSource.FormName = "DataProcessor.SelectGoodsToSalesDocument.Form.Form" Then
		
		ProcessingSelectionOfSelectionOnServer(ValueSelected);
		
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectGoodsTransferredToCustody.Form.Form" Then
		
		PricesCalculated = False;
		
		SelectionProcessingSelectionOfTransferredGoods(ValueSelected, PricesCalculated);
		SalesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated);
		
	ElsIf TypeOf(ValueSelected) = Type("Structure")
		And ValueSelected.Property("CurrentOperation1", CurrentOperation1) Then
		
		If Upper(CurrentOperation1) = Upper("AddItemsFromSalesOrderGoodsIssue") Then
			ProcessingProductSelectionFromOrder(ValueSelected.AddressInStorage);
		EndIf;
		
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectReusablePackage.Form.Form" Then
		
		FillMultiTurnContainersFromStorageServer(ValueSelected.AddressOfReusableContainerInStorage);
		ReusablePackageClient.NotifyUserAboutFillingMultiTurnContainers();
		
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
	
	If EventName = "CopyingLinesToClipboard" Then
		SetAvailabilityOfClipboardCommandsOnClient();
	EndIf;
	
	If EventName = "Closing_EditingSet"
		And Parameter.OwnerForm = UUID Then
		
		AtEndOfEditingSet(Parameter.AddressInTempStorage);
		
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
		
		OpenForm("DataProcessor.EditSet.Form.Form", OpeningParameters, ThisObject, UUID);
		
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
		Modified = True;
		ContractOnChange(Items[Parameter]);
	EndIf;
	
EndProcedure

&AtClient
Procedure NewWriteProcessing(NewObject, Source, StandardProcessing)
	
	If PurchasesClient.ThisIsIndicationOfCCDNumber(Source) Then
		Actions = New Structure;
		
		AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(ThisObject, Actions);
		
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
	
	If Not Object.ByReferences
		And WriteParameters.WriteMode = DocumentWriteMode.Posting
		And Object.Goods.Count() > 0
		And (Object.ReusablePackageFillingStatus = PredefinedValue("Enum.ReusablePackageFillingStates.OfferToFillIn")
			Or Not ValueIsFilled(Object.ReusablePackageFillingStatus)) Then
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("ThisObject", ThisObject);
		AdditionalParameters.Insert("WriteParameters", WriteParameters);
		
		TableName = "Goods";
		ColumnsNames = "Products,Characteristic,Count";
		
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
	
EndProcedure

&AtClient
Procedure BeforeRecordingOfferToPickUpMultiTurnContainer(Result, AdditionalParameters) Export
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, AdditionalParameters.WriteParameters);
	
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
	
	Handler = Documents.ReceiptOfGoodsFromCustodian.ActionHandler(Object.BusinessOperation);
	Handler.CustomizeForm(ThisObject, Object.Number, Object.Date);
	Handler.FillInShopPantryAttributeInTable(Object);
	FillInDiscrepancyAttributeOrder(Object.Goods, Object.ByReferences, UseLineCode);
	
	FillInServiceDetailsForProductRange();
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, Object.ReusablePackageReturn);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	SetElementProperties();
	CalculateTotals_(ThisObject);
	
	
	
	UnlockFormDataForEdit();
	
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Title = "";
	AutoTitle = True;
	
	WriteParameters.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
	Notify("Write_ReceiptOfGoodsFromCustodian", WriteParameters, Object.Ref);
	
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
Procedure URLProcessing(FormattedStringURL, StandardProcessing) Export
	
	FormEventsClient.URLProcessing(ThisObject, FormattedStringURL, StandardProcessing);
	
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
Procedure ByReferenceOnChange(Item)
	OnOrdersWhenChangingOnClient();
EndProcedure

&AtClient
Procedure ByReferencesOnChange(Item)
	OnOrdersWhenChangingOnClient();
EndProcedure

&AtClient
Procedure HeaderOrdersTextClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	TitleText    = NStr("vi = 'Đơn hàng của khách (%DocumentsCount%)';
						|ru = 'Заказы клиентов (%DocumentsCount%)';
						|en = 'Sales orders (%DocumentsCount%)'; fa = 'Sales orders (%DocumentsCount%)';
						|it = 'Ordini dei clienti (%DocumentsCount%)';
						|pl = 'Zamówienia klientów (%DocumentsCount%)';
						|tr = 'Satış siparişleri (%DocumentsCount%)'");
	If Object.BusinessOperation =
			PredefinedValue("Enum.BusinessTransactions.ReceiptFromToller2_5") Then
		TitleText    = NStr("vi = 'Đơn đặt hàng gia công (%DocumentsCount%)';
							|ru = 'Заказы переработчикам (%DocumentsCount%)';
							|en = 'Subcontracting purchase orders (%DocumentsCount%)'; fa = 'Subcontracting purchase orders (%DocumentsCount%)';
							|it = 'Ordini ai trasformatori (%DocumentsCount%)';
							|pl = 'Zamówienia dla przetwórców (%DocumentsCount%)';
							|tr = 'Fason satın alma siparişleri (%DocumentsCount%)'");
	EndIf;
	OpeningParameters = New Structure("DocumentsList, Title", OrderList, TitleText);
	
	OpenForm("CommonForm.ViewingListOfDocuments", OpeningParameters, ThisObject, , , , Undefined,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure InscriptionStateOfEDOClick(Item, StandardProcessing)
	
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)

	If BusinessTransactionBeforeTheChange = Object.BusinessOperation Then
		Return;
	EndIf;
	If (BusinessTransactionBeforeTheChange = PredefinedValue("Enum.BusinessTransactions.ReceiptFromToller2_5")
				Or BusinessTransactionBeforeTheChange = PredefinedValue("Enum.BusinessTransactions.ReturnFromProcessingCompany2_5"))
			And Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromCustodian")
		Or BusinessTransactionBeforeTheChange = PredefinedValue("Enum.BusinessTransactions.ReturnFromCustodian")
			And (Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReceiptFromToller2_5")
				Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromProcessingCompany2_5")) Then
		
		Object.Partner         = PredefinedValue("Catalog.Partners.EmptyRef");
		Object.Counterparty      = PredefinedValue("Catalog.Counterparties.EmptyRef");
		
	EndIf;
	Object.Terms      = PredefinedValue("Catalog.TermsOfSale.EmptyRef");
	Object.ByReferences = False;
	Object.ReferenceOrder    = Undefined;
	PartnerOnChange(Items.Partner);
	CounterpartyOnChange(Items.Counterparty);
	BusinessOperationOnChangeServer();
	FillInPriceTypes();
	ConfigureFormForCorruption();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands

EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReceiptFromToller2_5") Then
		DateOnChangeCompletion(False, Undefined);
	Else
		Notification = New CallbackDescription("DateOnChangeCompletion", ThisObject);
		EnterprisePricesFillingClient.AskQuestionAboutRecalculatingPriceWhenDateChanges(Object, Notification);
	EndIf;
EndProcedure

&AtClient
Procedure DateOnChangeCompletion(RecalculatePrices_, AdditionalParameters) Export
	
	Var PricesCalculated;
	
	DateOnChangeServer(RecalculatePrices_, PricesCalculated);
	
	If RecalculatePrices_ Then
		SalesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated);
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
	
	
EndProcedure

&AtClient
Procedure TermsOnChange(Item)
	
	If Not ValueIsFilled(Object.Terms) Then
		TheCommissionAgentDoesNotKeepRecordsOnTheRNPT = False;
		Return;
	Else
		If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromCustodian") Then
			EnterprisePricesFillingClient.AskQuestionAboutRecalculatingPriceWhenDateChanges(Object,
				New CallbackDescription("AgreementWhenChangingQuestionCompletion", ThisObject));
		Else
			WhenChangingAgreementAtServer(False);
			
			SalesClient.NotifyEndOfFillingInTermsOfSale();
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure AgreementWhenChangingQuestionCompletion(UserAnswer, AdditionalParameters) Export
	
	WhenChangingAgreementAtServer(
		ValueIsFilled(Object.Terms)
		And Object.Goods.Count() > 0
		And Not UserAnswer = DialogReturnCode.Cancel
		And UserAnswer);
	
	If ValueIsFilled(Object.Terms) Then
		SalesClient.NotifyEndOfFillingInTermsOfSale();
	EndIf;
	
EndProcedure

&AtClient
Procedure TermsStartChoice(Item, ChoiceData, StandardProcessing)
	
	ThisIsRefundFromCommissionAgent = ?(Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromCommissionAgent"), True, False);
	
	AgreementSelectionParameters = SalesClient.ParametersForStartingSelectionOfAgreementWithClient();
	AgreementSelectionParameters.Item               = Item;
	AgreementSelectionParameters.Partner               = Object.Partner;
	AgreementSelectionParameters.Document              = Object.Terms;
	AgreementSelectionParameters.DocumentDate         = Object.Date;
	AgreementSelectionParameters.FormDataStructure  = Object;
	AgreementSelectionParameters.BusinessOperation = ?(ThisIsRefundFromCommissionAgent,
		PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent"),
		PredefinedValue("Enum.BusinessTransactions.TransferToStorageWithRightOfSale"));
	AgreementSelectionParameters.ConsignmentSales25 = ThisIsRefundFromCommissionAgent;
	
	SalesClient.StartSelectingAgreementWithClient(AgreementSelectionParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	
EndProcedure

&AtClient
Procedure ContractCreating(Item, StandardProcessing)
	
	PurchasesClient.OpenContractCreationForm(ThisObject, Item, "Object.Contract", Object.Partner, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	If Contract = Object.Contract Then
		Return;
	EndIf;
	
	OriginalPriceView = Object.PriceKind;
	
	If Object.ByReferences Then
		
		ButtonsList = New ValueList;
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
						|tr = 'Ambar değiştiğinde, ""Ürünler"" listesinin temizlenmesi veya satırların siparişten ayrılması gerekir. Devam et?'");
		
		Notification = New CallbackDescription("ContractOnChangeCompletion", ThisObject);
		
		ShowQueryBox(Notification, QueryText, ButtonsList);
		
	Else
		ContractOnChangeServer(False, False, True);
		
		ThisIsRefundFromCommissionAgent = ?(Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromCommissionAgent"), True, False);
		
		If ThisIsRefundFromCommissionAgent
			And ValueIsFilled(NewKindOfPrice)
			And Not OriginalPriceView = NewKindOfPrice Then
			
			If Object.Goods.Count() > 0 Then
				AskQuestionWhenChangingPriceType(NewKindOfPrice);
			Else
				Object.PriceKind = NewKindOfPrice;
			EndIf;
			
		EndIf;
		
	EndIf;
	
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
	
	ThisIsRefundFromCommissionAgent = ?(Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromCommissionAgent"), True, False);
	
	If ThisIsRefundFromCommissionAgent
		And ValueIsFilled(NewKindOfPrice)
		And Not OriginalPriceView = NewKindOfPrice Then
		
		If Object.Goods.Count() > 0 Then
			AskQuestionWhenChangingPriceType(NewKindOfPrice);
		Else
			Object.PriceKind = NewKindOfPrice;
		EndIf;
		
	EndIf;

EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	If Warehouse = Object.Warehouse Then
		Return;
	EndIf;
	
	ApplicationsAreUsedAsInvoices = ApplicationsAreUsedAsInvoices();
	
	If ApplicationsAreUsedAsInvoices Then
		WarehouseOnChangeServer(False, False, True);
	ElsIf Object.ByReferences Then
		
		ButtonsList = New ValueList;
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
						|tr = 'Stok değiştiğinde, ""Ürünler"" listesinin temizlenmesi veya satırların siparişten ayrılması gerekir. Devam edilsin mi?'");
		
		Notification = New CallbackDescription("WarehouseOnChangeCompletion", ThisObject);
		
		ShowQueryBox(Notification, QueryText, ButtonsList);
		
	Else
		WarehouseOnChangeServer(False, False, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure WarehouseOnChangeCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Object.Warehouse = Warehouse;
		Return;
	EndIf;
	
	ClearLines =
		Result = "Continue";
	
	UnbindLines =
		Result = "Unlink";
		
	WarehouseOnChangeServer(ClearLines, UnbindLines, True);
	
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	
	If Not ValueIsFilled(Object.Currency) Then
		Object.Currency = DocumentCurrency;
		Return;
	EndIf;
	
	RecalculateAmounts =
		PriceManagementSystemClient.CurrencyConversionRequired(Object, DocumentCurrency)
		And Not Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReceiptFromToller2_5")
		And True;
	
	WhenChangingCurrencyServer(Object.Currency, RecalculateAmounts);
	
	If RecalculateAmounts Then
		PriceManagementSystemClient.NotifyAboutEndOfConversionOfAmountsIntoCurrency(DocumentCurrency, Object.Currency);
	EndIf;
	
	FillInPriceTypes();
	
EndProcedure

&AtClient
Procedure PriceKindOnChange(Item)
	
	If Not ValueIsFilled(Object.PriceKind) Then
		Return;
	EndIf;
	
	AskQuestionWhenChangingPriceType(Object.PriceKind);
	
EndProcedure

&AtClient
Procedure AskQuestionWhenChangingPriceType(NewKindOfPrice)
	
	If ValueIsFilled(NewKindOfPrice) And Not OriginalPriceView = NewKindOfPrice Then
		
		If Object.Goods.Count() > 0 Then
		
			QueryText = NStr("vi = 'Điền đơn giá theo dạng giá ""%PriceKind%""?';
							|ru = 'Заполнить цены по виду цен ""%PriceKind%""?';
							|en = 'Fill in prices by price type ""%PriceKind%""?'; fa = 'Fill in prices by price type ""%PriceKind%""?';
							|it = 'Compilare i prezzi per il tipo di prezzi ""%PriceKind%""?';
							|pl = 'Podaj ceny według rodzaju ceny ""%PriceKind%""?';
							|tr = 'Fiyatlar, ""%PriceKind%"" fiyat türüne göre doldurulsun mu?'");
			QueryText = StrReplace(QueryText,"%PriceKind%", NewKindOfPrice);
			ShowQueryBox(New CallbackDescription("PriceViewWhenChangingQuestionEnding", ThisObject, NewKindOfPrice), QueryText,QuestionDialogMode.YesNo,,DialogReturnCode.Yes);
		Else
			Object.PriceKind = NewKindOfPrice;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PriceViewWhenChangingQuestionEnding(UserAnswer, AdditionalParameters) Export
	
	If UserAnswer <> Undefined
		And UserAnswer = DialogReturnCode.Yes Then
		
		Object.PriceKind = AdditionalParameters;
		FillInPricesByPriceType_();
		
	ElsIf Not Object.PriceKind = OriginalPriceView Then
		Object.PriceKind = OriginalPriceView;
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
Procedure ReusablePackageReturnOnChange(Item)
	
	ReusablePackageReturnOnChangeServer();
	
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(
		ThisObject, FormattedStringURL, StandardProcessing);
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
	
	If NewRow
		And Object.ByReferences
		And Not UseReceiptForMultipleOrders Then
		CurrentData.ReferenceOrder = Object.ReferenceOrder;
	ElsIf NewRow
		And Object.ByReferences Then
		CurrentData.ReferenceOrder = Undefined;
	EndIf;
	
	If Copy
		And Object.ByReferences Then
		CurrentData.RowCode = 0;
	EndIf;
	
	If UseLineCode Then
		StructureOfActions = New Structure;
		OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, Object.ByReferences);
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	Else
		CurrentData.OrderDiscrepancy_3 = 0;
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
		
		StructureOfActions = New Structure;
		
		If UseLineCode Then
			OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(
				StructureOfActions, Object.ByReferences);
		Else
			CurrentData.OrderDiscrepancy_3 = 0;
		EndIf;
		
		If ValueIsFilled(StructureOfActions) Then
			BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, Undefined);
		EndIf;
		
		UpdateDependentDetailsOfOrderForm(Items, Object.Goods, DiscrepancyOrderText);
		
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
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	If CurrentRow.Damage
		And ValueIsFilled(CurrentRow.ProductsRecordingAsReceived) Then
		
		ThereIsGradation = CheckForGradationServer(CurrentRow.Products, CurrentRow.ProductsRecordingAsReceived);
		If Not ThereIsGradation Then
			
			CurrentRow.ProductsRecordingAsReceived = PredefinedValue("Catalog.Products.EmptyRef");
			CurrentRow.CharacteristicRecordingAsReceived = PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef");
			CurrentRow.ItemVariantsAreUsedRecordingAsReceived = False;
			
		EndIf;
		
	EndIf;
	
	FillInArticleAttribute = New Structure("Products, ProductsRecordingAsReceived",
		"SKU",
		"SKURegistration");
	
	FillInProductTypeAttribute_  = New Structure("Products", "ItemsType");
	FillInCCDTrackingAttribute = New Structure("Products", "TheRecordsAreKeptByCCD");
	
	CheckSeriesCalculateStatus = New Structure;
	CheckSeriesCalculateStatus.Insert("Warehouse", Object.Warehouse);
	CheckSeriesCalculateStatus.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters);
	
	CountryOfOriginFillingParameters = BatchProcessingOfTablePartClientServer.CountryOfOriginFillingParameters();
	
	ProductsOnChangeOverridable = New Structure;
	ProductsOnChangeOverridable.Insert("FormName", FormName);
	ProductsOnChangeOverridable.Insert("TabularSectionName", "Goods");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInArticleAttribute",               FillInArticleAttribute);
	StructureOfActions.Insert("FillInProductTypeAttribute_",       FillInProductTypeAttribute_);
	StructureOfActions.Insert("CheckCharacteristicsByOwner",    CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("CheckSeriesCalculateStatus",        CheckSeriesCalculateStatus);
	StructureOfActions.Insert("FillInNoReturnContainerAttribute",     Object.ReusablePackageReturn);
	StructureOfActions.Insert("FillInCCDTrackingAttribute",      FillInCCDTrackingAttribute);
	StructureOfActions.Insert("FillInCountryOfOriginOfProduct", CountryOfOriginFillingParameters);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("ProductsOnChangeOverridable", ProductsOnChangeOverridable);
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object, TheCommissionAgentDoesNotKeepRecordsOnTheRNPT);
	AddPriceFillingActionsToStructure(StructureOfActions, Object, ToUseTermsOfSales);
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisObject);
	
	If Not CurrentRow.TheRecordsAreKeptByCCD Then
		
		CurrentRow.CCDNumber = Undefined;
		CurrentRow.OriginCountry = Undefined;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	CharacteristicOnChangeOverridable = New Structure;
	CharacteristicOnChangeOverridable.Insert("FormName",          FormName);
	CharacteristicOnChangeOverridable.Insert("TabularSectionName", "Goods");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", CharacteristicOnChangeOverridable);
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object, TheCommissionAgentDoesNotKeepRecordsOnTheRNPT, False);
	AddPriceFillingActionsToStructure(StructureOfActions, Object, ToUseTermsOfSales);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisObject);
	
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
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object, TheCommissionAgentDoesNotKeepRecordsOnTheRNPT);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object, TheCommissionAgentDoesNotKeepRecordsOnTheRNPT);
	
	If True
		And Not Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReceiptFromToller2_5")
		And CurrentRow.Count > 0 Then
		StructureOfActions.Insert("RecalculatePricePerPackage", CurrentRow.Count);
	Else
		AddPriceFillingActionsToStructure(StructureOfActions, Object, ToUseTermsOfSales);
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsPriceOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object, TheCommissionAgentDoesNotKeepRecordsOnTheRNPT, False);
	
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

&AtClient
Procedure GoodsOnActivateCell(Item)
	
	If Item.CurrentItem = Undefined Then
		Return;
	ElsIf Item.CurrentItem.Name = "GoodsCCDNumber" Then
		PurchasesClient.FillInListOfCCDNumberSelection(Items.Goods.CurrentData, Items.GoodsCCDNumber.ChoiceList);
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
	
	AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(ThisObject, Actions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, Actions, Undefined);
	
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
Procedure GoodsDamageOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	If Not CurrentRow.Damage Then
		
		CurrentRow.ProductsRecordingAsReceived = PredefinedValue("Catalog.Products.EmptyRef");
		CurrentRow.CharacteristicRecordingAsReceived = PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef");
		CurrentRow.ItemVariantsAreUsedRecordingAsReceived = False;
		
	EndIf;
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsProductsRecordingAsReceivedOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	CurrentRow = New Structure;
	CurrentRow.Insert("Products", CurrentData.ProductsRecordingAsReceived);
	CurrentRow.Insert("ItemVariantsAreUsed", CurrentData.ItemVariantsAreUsedRecordingAsReceived);
	CurrentRow.Insert("Characteristic", CurrentData.Characteristic);
	CurrentRow.Insert("SKU", CurrentData.SKU);
	CurrentRow.Insert("Series", CurrentData.Series);
	CurrentRow.Insert("BatchesIndicationStatus", CurrentData.BatchesIndicationStatus);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentData.Characteristic);
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	
	BatchProcessingOfTablePartClient.ProcessTSString(
		CurrentRow,
		StructureOfActions,
		Undefined);
	
	CurrentData.CharacteristicRecordingAsReceived = CurrentRow.Characteristic;
	CurrentData.ItemVariantsAreUsedRecordingAsReceived = CurrentRow.ItemVariantsAreUsed;
	CurrentData.Series = CurrentRow.Series;
	CurrentData.BatchesIndicationStatus = CurrentRow.BatchesIndicationStatus;
	CurrentData.SKURegistration = CurrentRow.SKU;
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, Undefined);
	
EndProcedure

&AtClient
Procedure GoodsProductsRecordingAsReceivedStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentData.Characteristic);
	
	If ValueIsFilled(CurrentData.Characteristic) Then
		StructureOfActions.Insert("FillInDescriptionOfPoorQualityProduct");
	EndIf;
	
	ArticleFillingParameters = New Structure;
	ArticleFillingParameters.Insert("Products", "SKU");
	ArticleFillingParameters.Insert("ProductsOfOriginalQuality", "SKURegistration");
	StructureOfActions.Insert("FillInArticleAttribute", ArticleFillingParameters);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	WarehousesClient.ChangeQuality(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsReferenceOrderStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData <> Undefined Then
		
		CallbackDescription = New CallbackDescription("GoodsSalesOrderStartChoiceCompletion", ThisObject);
		OpenOrderSelection(CallbackDescription);
		Return;
		
	EndIf;
	
	UpdateOrderInformation();
	
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
	
	TMCommonUseClient.Write(ThisObject);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject);
	
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
Procedure CloseRequest(Command)
	
	If Modified
		Or Not Object.Posted Then
		
		CallbackDescription = New CallbackDescription("CloseRequestCompletion", ThisObject);
		QueryText       = NStr("vi = 'Cần kết chuyển chứng thừ để thực hiện giao dịch. Kết chuyển chứng từ?';
								|ru = 'Необходимо провести документ для выполнения операции. Провести документ?';
								|en = 'To proceed, you need to post the document. Do you want to post the document?'; fa = 'To proceed, you need to post the document. Do you want to post the document?';
								|it = 'È necessario pubblicare il documento per eseguire operazione. pubblicare documento?';
								|pl = 'Należy zaksięgować dokument aby wykonać operację. Zaksięgować dokument?';
								|tr = 'Bir işlemin gerçekleştirilmesi için belgenin düzenlenmesi gerekir. Belge düzenlensin mi?'");
		
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		
		Return;
		
	EndIf;
	
	CloseRequestFragment();
	
EndProcedure

&AtClient
Procedure CloseRequestCompletion(QuestionResult, AdditionalParameters) Export
	
	WriteParameters = New Structure("WriteMode", DocumentWriteMode.Posting);
	
	If QuestionResult = DialogReturnCode.No Then
		Return;
	ElsIf Not Write(WriteParameters) Then
		Return;
	EndIf;
	
	CloseRequestFragment();
	
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
	CurrentData = FormTable.CurrentData;
	
	TableData = Object.Goods;
	
	AttributesNames   = "Count, Sum";
	FieldNameQuantity = "NumberOfPackages";
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.StructureOfRecalculationOfAmount(
		AttributesNames, FieldNameQuantity);
	
	AdditionalParameters = New Structure;
	
	If CurrentData <> Undefined Then
		
		BatchProcessingOfTablePartClientServer.FillInStructureForRecalculatingAmount(StructureOfRecalculationOfAmount, CurrentData);
		
		AdditionalParameters = AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfParametersForSplittingRowInTablePart(CurrentData, AdditionalParameters);
		
	EndIf;
	
	AdditionalParameters.Insert("StructureOfRecalculationOfAmount", StructureOfRecalculationOfAmount);
	CallbackDescription = New CallbackDescription("SplitRowCompletion", ThisObject, AdditionalParameters);
	
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, CallbackDescription);
	
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
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
		CalculateTotals_(ThisObject);
		
	EndIf;
	
	AccountingForTraceableGoodsClientServerLocalization.SplitRowCompletion(NewRow, AdditionalParameters);
	
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
	OpeningParameters.Insert("Organization", Object.Organization);
	
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
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object, TheCommissionAgentDoesNotKeepRecordsOnTheRNPT);
		
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
	GoodsQuantityExcessIsAllowed = Not Object.ByReferences;
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("Ref",            Object.Ref);
	OpeningParameters.Insert("Warehouse",             Object.Warehouse);
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
Procedure UnlinkFromOrder(Command)
	
	SelectedRows = Items.Goods.SelectedRows;
	
	If SelectedRows.Count() > 0 Then
		
		For Each CurRow In SelectedRows Do
			TableRow = Object.Goods.FindByID(CurRow);
			TableRow.RowCode = 0;
			TableRow.OrderDiscrepancy_3 = 1;
		EndDo;
		
		UpdateDependentDetailsOfOrderForm(Items, Object.Goods, DiscrepancyOrderText);
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
Procedure CheckQuantityInTheDocumentCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		Modified   = True;
		CachedValues = ?(CachedValues = Undefined,
								BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues(),
								CachedValues);
		
		ChangeTablePartBasedOnResultsOfCheck(Result, CachedValues);
		
		TMCommonUseClient.DisplayMessageExceedingNumber(Result, NStr("vi = 'được nhập trên cơ sở lệnh.';
																	|ru = 'введенного на основании распоряжения.';
																	|en = 'entered based on the reference.'; fa = 'entered based on the reference.';
																	|it = 'введенного на основании распоряжения.';
																	|pl = 'entered based on the reference.';
																	|tr = 'sipariş temelinde yansıtılır.'"));
		CalculateTotals_(ThisObject);
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
		"Document.ReceiptOfGoodsFromCustodian.DocumentForm.Command.OpenSelection");
	
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
		HeaderParameter_ = StrReplace(HeaderParameter_, "%Document%", NStr("vi = 'tiếp nhận hàng hóa từ bên bảo quản';
																			|ru = 'поступление товаров от хранителя';
																			|en = 'VMI return'; fa = 'برگشت VMI';
																			|it = 'arrivo di merci dal consegnatario';
																			|pl = 'wpływ towarów od magazyniera';
																			|tr = 'Malların VMI''dan teslim alınması'"));
	EndIf;
	
	FilterByProductType = New FixedArray(SelectionByProductMultiTurnContainer(Object.BusinessOperation));
	
	FormParameters = New Structure;
	FormParameters.Insert("Document",    Object.Ref);
	FormParameters.Insert("Title",   HeaderParameter_);
	FormParameters.Insert("Date",        Object.Date);
	FormParameters.Insert("Terms",  Object.Terms);
	FormParameters.Insert("Organization", Object.Organization);
	FormParameters.Insert("Warehouse",       Object.Warehouse);
	FormParameters.Insert("Currency",      Object.Currency);
	
	FormParameters.Insert("FilterByProductType", FilterByProductType);
	FormParameters.Insert("SeriesSpecificationParameters",  SeriesSpecificationParameters);
	
	FormParameters.Insert("HideManualDiscounts", True);
	
	FormParameters.Insert("BusinessOperation",        Object.BusinessOperation);
	FormParameters.Insert("LineOfBusiness",      Object.LineOfBusiness);
	FormParameters.Insert("ReturnReusablePackage", Object.ReusablePackageReturn);
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReceiptFromToller2_5")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromProcessingCompany2_5") Then
		FormParameters.Insert("UseAdvancedFeaturesOfSalesOrder", True);
	EndIf;
	OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form", FormParameters, ThisObject, UUID);
	
EndProcedure

&AtClient
Procedure SelectTransferredGoods(Command)
	
	Cancel = False;
	
	ClearMessages();
	
	If Not ValueIsFilled(Object.Partner) Then
		ErrorText = StrTemplate(NStr("vi = 'Chưa điền trường ""%1""';
									|ru = 'Поле ""%1"" не заполнено';
									|en = 'Field %1 is required'; fa = 'Field %1 is required';
									|it = 'Il campo ""%1"" non è compilato';
									|pl = 'Pole ""%1"" nie jest wypełnione';
									|tr = '""%1"" alanı doldurulmamış'"), Items.Partner.Title);
		
		CommonClientServer.MessageToUser(ErrorText, Object.Ref, "Object.Partner", "", Cancel);
	EndIf;
	
	If Not ValueIsFilled(Object.Organization) Then
		ErrorText = NStr("vi = 'Chưa điền trường ""Doanh nghiệp""';
						|ru = 'Поле ""Организация"" не заполнено';
						|en = '""Company"" is required'; fa = '""Company"" is required';
						|it = 'Il campo ""Società"" non è compilato';
						|pl = 'Nie wypełniono pola ""Firma""';
						|tr = '""İş yeri"" alanı doldurulmadı'");
		
		CommonClientServer.MessageToUser(ErrorText, Object.Ref, "Object.Organization", "", Cancel);
	EndIf;
	
	If Not ValueIsFilled(Object.Contract) Then
		ErrorText = NStr("vi = 'Trường ""Hợp đồng"" chưa điền';
						|ru = 'Поле ""Договор"" не заполнено';
						|en = '""Contract"" is not filled in.'; fa = '""Contract"" is not filled in.';
						|it = 'Il campo ""Accordo"" non è compilato';
						|pl = 'Pole ""Umowa"" nie jest wypełnione';
						|tr = '""Sözleşme"" alanı doldurulmamış'");
		
		CommonClientServer.MessageToUser(ErrorText, Object.Ref, "Object.Contract", "", Cancel);
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	PerformanceMonitorClient.TimeMeasurement(True,
		"Document.ReceiptOfGoodsFromCustodian.DocumentForm.Command.SelectTransferredGoods");
	
	AddressOfGoods = PlaceGoodsInStorageForSelectionOfTransferredGoods();
	
	FormParameters = New Structure;
	FormParameters.Insert("Ref",                Object.Ref);
	FormParameters.Insert("Owner",              Object.Partner);
	FormParameters.Insert("Organization",           Object.Organization);
	FormParameters.Insert("Contract",               Object.Contract);
	FormParameters.Insert("BusinessOperation", Object.BusinessOperation);
	FormParameters.Insert("ObjectManager",       "Document.ReceiptOfGoodsFromCustodian");
	FormParameters.Insert("Title",             HeaderOfSubmittedProductSelectionForm);
	FormParameters.Insert("AddressOfGoodsInvoiceInVault", AddressOfGoods);
	FormParameters.Insert(
		"CollapseGTDNumbers",
		Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReceiptFromToller2_5")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromProcessingCompany2_5"));
	OpenForm("DataProcessor.SelectGoodsTransferredToCustody.Form.Form", FormParameters, ThisObject,
		UUID);
	
EndProcedure

&AtClient
Procedure SelectGoodsByOrdersNotes(Command)
	
	OpenSelectionByOrdersOrders();
	
EndProcedure

&AtClient
Procedure RefillByReceiving(Command)
	
	ClearMessages();
	
	If Not ValueIsFilled(Object.Ref) Then
		CallbackDescription = New CallbackDescription("ResubmitUserSResponseUponReceipt", ThisObject);
		QueryText       = NStr("vi = 'Để điền vào sự chấp nhận, trước tiên bạn phải ghi lại chứng từ. Ghi lại một chứng từ và tiếp tục?';
								|ru = 'Для заполнения по приемке необходимо предварительно записать документ. Выполнить запись документа и продолжить?';
								|en = 'To fill in by receipt, you should save the document first. Save the document and continue?'; fa = 'To fill in by receipt, you should save the document first. Save the document and continue?';
								|it = 'Prima di compilare per accettazione è necessario registrare il documento. Effettuare la registrazione del documento e continuare?';
								|pl = 'W celu wypełnienia według przyjęcia należy wstępnie zapisać dokument. Wykonać zapisywanie dokumentu i kontynuować?';
								|tr = 'Belgenin teslim alındığında tamamlanabilmesi için önceden kaydedilmiş olması gerekir. Belge kaydı gerçekleştirilsin mi?'");
		
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	Else
		RefillByReceivingServer();
		
		MessageText = NStr("vi = 'Số lượng điền lại';
							|ru = 'Количество перезаполнено';
							|en = 'Refilled quantity'; fa = 'Refilled quantity';
							|it = 'La quantità è ricompilata';
							|pl = 'Ponowne wypełnienie ilości.';
							|tr = 'Miktar yeniden dolduruldu'");
		ExplanationText = NStr("vi = 'Trong các dòng điền lại số lượng.';
								|ru = 'В строках перезаполнено количество.';
								|en = 'Quantity is refilled in lines.'; fa = 'Quantity is refilled in lines.';
								|it = 'La quantità nelle righe è stata ricompilata.';
								|pl = 'W wierszach jest ponownie wypełnona ilość.';
								|tr = 'Satırlarda miktar yeniden dolduruldu.'");
		
		ShowUserNotification(MessageText, , ExplanationText, PictureLib.Information32);
	EndIf;
	
EndProcedure

&AtClient
Procedure ResubmitUserSResponseUponReceipt(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.No Then
		Return;
	Else
		WriteParameters = New Structure("WriteMode", DocumentWriteMode.Write);
		
		Write(WriteParameters);
	EndIf;
	
	If Object.Posted Then
		RefillByReceivingServer();
		
		MessageText = NStr("vi = 'Số lượng điền lại';
							|ru = 'Количество перезаполнено';
							|en = 'Refilled quantity'; fa = 'Refilled quantity';
							|it = 'La quantità è ricompilata';
							|pl = 'Ponowne wypełnienie ilości.';
							|tr = 'Miktar yeniden dolduruldu'");
		ExplanationText = NStr("vi = 'Trong các dòng điền lại số lượng.';
								|ru = 'В строках перезаполнено количество.';
								|en = 'Quantity is refilled in lines.'; fa = 'Quantity is refilled in lines.';
								|it = 'La quantità nelle righe è stata ricompilata.';
								|pl = 'W wierszach jest ponownie wypełnona ilość.';
								|tr = 'Satırlarda miktar yeniden dolduruldu.'");
		
		ShowUserNotification(MessageText, , ExplanationText, PictureLib.Information32);
	EndIf;
	
EndProcedure

&AtClient
Procedure AddReusablePackage(Command)
	
	ReusablePackageClient.SelectReusablePackage(ThisObject, "Goods", "Products,Characteristic,Count");
	
EndProcedure

&AtClient
Procedure FillInPricesByPriceKind(Command)
	
	ClearMessages();
	FillInPricesByPriceType_(Items.Goods.SelectedRows);
	
EndProcedure

&AtClient
Procedure ImportFromExternalFile(Command)
	
	ImportParameters = ProcessingOfTabularFormsClient.ProductLoadingParameters();
	ImportParameters.Organization = Object.Organization;
	ImportParameters.ImportPrices = True;
	ImportParameters.ImportPrices =
		Not Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReceiptFromToller2_5");
	ImportParameters.ImportCCD  = True;
	ImportParameters.ThisIsReusablePackage = Object.ReusablePackageReturn;
	ImportParameters.ComponentsPriceParameters.Date       = Object.Date;
	ImportParameters.ComponentsPriceParameters.Currency     = Object.Currency;
	ImportParameters.ComponentsPriceParameters.Terms = Object.Terms;
	ImportParameters.FilterParameters.Insert("ItemsType",
		SelectionByProductMultiTurnContainer(Object.BusinessOperation));
	
	Notification = New CallbackDescription("ImportFromExternalFileCompletion", ThisObject);
	ProcessingOfTabularFormsClient.ShowProductUploadForm(ImportParameters, Notification);
	
EndProcedure

&AtClient
Procedure ImportFromExternalFileCompletion(ImportedDataAddress, AdditionalParameters) Export
	
	If ValueIsFilled(ImportedDataAddress) Then
		GetUploadedProductsFromStorage(ImportedDataAddress);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInTheGTDPoNumbersForTheTransferredGoods(Command)
	
	ThereAreFilledInCCDNumbers = False;
	For Each Page1 In Object.Goods Do
		If ValueIsFilled(Page1.CCDNumber) Then
			ThereAreFilledInCCDNumbers = True;
			Break;
		EndIf;
	EndDo;
	
	If ThereAreFilledInCCDNumbers Then
		CallbackDescription = New CallbackDescription("ProcessAnswerToQuestionAboutFillingInCCDNumbers", ThisObject);
		QueryText = NStr("vi = 'Số TKHQ sẽ được xóa và điền lại. Tiếp tục?';
						|ru = 'Будут очищены и перезаполнены номера ГТД. Продолжить?';
						|en = 'CCD numbers will be cleared and refilled. Continue?'; fa = 'CCD numbers will be cleared and refilled. Continue?';
						|it = 'I numeri delle polizze doganali di carico verranno eliminati e reinseriti. Continuare?';
						|pl = 'Numery LP zostaną wyczyszczone i uzupełnione. Kontynuować?';
						|tr = 'GKB numaraları silinecek ve yeniden doldurulacaktır. Devam edilsin mi?'");
		
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	Else
		FillInCCDNumbersForTransferredGoodsOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessAnswerToQuestionAboutFillingInCCDNumbers(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		FillInCCDNumbersForTransferredGoodsOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInPricesUnderAgreement(Command)
	
	TypeOfContractPrice = AccountingTypeOfContractPrice();
	
	If EnterprisePricesFillingClient.YouNeedToFillInPricesByType(Object, TypeOfContractPrice) Then
		
		ErrorText = "";
		PricesCalculated = FillThePricesByTermsOfSalesServer(ErrorText);
		SalesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated, ErrorText);
		
	EndIf;
	
EndProcedure

#EndRegion

&AtClient
Procedure ReturnOfSpoiledGoods(Command)
	
	If Object.ReturnOfSpoiledGoods Then 
		
		ThereAreLinesWithCorruption = CheckDisableConfigureFormForCorruption();
		If ThereAreLinesWithCorruption Then
			
			If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReceiptFromToller2_5") Then
				
				QueryText =
					NStr("vi = 'Khi thực hiện giao dịch, sẽ xóa thông tin về chất lượng của hàng hóa tiếp nhận. Tiếp tục?';
						|ru = 'При выполнении операции будет очищена информация о качестве поступающих товаров. Продолжить?';
						|en = 'Item quality will be cleared. Continue?'; fa = 'Item quality will be cleared. Continue?';
						|it = 'Item quality will be cleared. Continue?';
						|pl = 'Item quality will be cleared. Continue?';
						|tr = 'İşlem, gelen ürünlerin kalitesine dair bilgileri temizleyecektir. Devam edilsin mi?'");
				
			Else
				
				QueryText =
					NStr("vi = 'Trong quá trình vận hành, thông tin về chất lượng của hàng trả lại sẽ bị xóa. Tiếp tục?';
						|ru = 'При выполнении операции будет очищена информация о качестве возвращаемых товаров. Продолжить?';
						|en = 'Item quality will be cleared. Do you want to continue?'; fa = 'Item quality will be cleared. Do you want to continue?';
						|it = 'Quando si esegue l''operazione, le informazioni sulla qualità delle merci in reso verranno cancellate. Continuare?';
						|pl = 'Podczas wykonania operacji będzie oczyszczona informacja o jakości zwracanych towarów. Kontynuować?';
						|tr = 'İşlem, iade edilen malların kalitesi hakkındaki bilgileri temizleyecektir. Devam edilsin mi?'");
				
			EndIf;
			
			ShowQueryBox(New CallbackDescription("ReturnOfSpoiledGoodsCompletion", ThisObject),
				QueryText,
				QuestionDialogMode.YesNo,,
				DialogReturnCode.Yes);
			
		EndIf;
		
	Else
		
		Object.ReturnOfSpoiledGoods = True;
		ConfigureFormForCorruption();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

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

&AtClient
Procedure OnOrdersWhenChangingOnClient()
	
	If Object.ByReferences Then
		
		If Not UseReceiptForMultipleOrders Then
			CallbackDescription = New CallbackDescription("ForOrdersWhenChangingOpenSelectionOfOrder", ThisObject);
			OpenOrderSelection(CallbackDescription);
			Return;
		Else
			If Object.Goods.Count() = 0 Then
				QueryText = NStr("vi = 'Danh sách ""Hàng hóa"" sẽ được điền lại bằng số dư hàng hóa chưa lập chứng từ theo đơn hàng. Tiếp tục?';
								|ru = 'Список ""Товары"" будет перезаполнен остатками неоформленных товаров по заказам. Продолжить?';
								|en = 'The ""Goods"" list will be refilled with remaining unregistered order goods. Continue?'; fa = 'The ""Goods"" list will be refilled with remaining unregistered order goods. Continue?';
								|it = 'L''elenco ""Articoli"" sarà ricompilato con i saldi degli articoli non formalizzati per ordini. Continuare?';
								|pl = 'Lista ""Towary"" zostanie wypełniona ponownie resztami niezarejestrowanych towarów według zamówień. Kontynuować?';
								|tr = '""Ürünler"" listesi siparişe ilişkin işlenmemiş ürünlerin bakiyeleri ile yeniden doldurulacaktır. Devam edilsin mi?'");
			Else
				QueryText = NStr("vi = 'Dòng trong danh sách ""Hàng hóa"" sẽ được gắn với dòng của đơn hàng. Tiếp tục?';
								|ru = 'Строки в списке ""Товары"" будут привязаны к строкам заказов. Продолжить?';
								|en = 'The ""Goods"" list lines will be linked to the order lines. Continue?'; fa = 'The ""Goods"" list lines will be linked to the order lines. Continue?';
								|it = 'Le righe nell''elenco ""Articoli"" saranno associate alle righe degli ordini. Continuare?';
								|pl = 'Wiersze na liście ""Towary"" będą powiązane z wierszami zamówień. Kontynuować?';
								|tr = '""Ürünler"" listesindeki satırlar sipariş satırlarına bağlanacaktır. Devam edilsin mi?'");
			EndIf;
		EndIf;
		
	Else
		If Not Object.Goods.Count() = 0 Then
			If UseReceiptForMultipleOrders Then
				QueryText =
					NStr("vi = 'Dòng trong danh sách ""Hàng hóa"" không còn liên kết với dòng trong đơn hàng. Tiếp tục?';
						|ru = 'Строки в списке ""Товары"" перестанут быть связанными со строками заказов. Продолжить?';
						|en = 'The ""Goods"" list lines will be unlinked from the order lines. Continue?'; fa = 'The ""Goods"" list lines will be unlinked from the order lines. Continue?';
						|it = 'Le righe nell''elenco ""Articoli"" non saranno più associate alle righe degli ordini. Continuare?';
						|pl = 'Wiersze na liście ""Towary"" nie będą więcej powiązane z wierszami zamówień. Kontynuować?';
						|tr = '""Ürünler"" listesindeki satırlar artık sipariş satırlarına ilişkilendirilmeyecektir. Devam edilsin mi?'");
			Else
				QueryText =
					NStr("vi = 'Dòng trong danh sách ""Hàng hóa"" không còn liên kết với dòng trong đơn hàng. Tiếp tục?';
						|ru = 'Строки в списке ""Товары"" перестанут быть связанными со строками заказов. Продолжить?';
						|en = 'The ""Goods"" list lines will be unlinked from the order lines. Continue?'; fa = 'The ""Goods"" list lines will be unlinked from the order lines. Continue?';
						|it = 'Le righe nell''elenco ""Articoli"" non saranno più associate alle righe degli ordini. Continuare?';
						|pl = 'Wiersze na liście ""Towary"" nie będą więcej powiązane z wierszami zamówień. Kontynuować?';
						|tr = '""Ürünler"" listesindeki satırlar artık sipariş satırlarına ilişkilendirilmeyecektir. Devam edilsin mi?'");
			EndIf;
		Else
			OnOrdersWhenChangingOnServer();
			Return;
		EndIf;
	EndIf;
	
	AskQuestionOnChangeOrders(QueryText);
	
EndProcedure

&AtClient
Procedure AskQuestionOnChangeOrders(QueryText)
	
	CallbackDescription = New CallbackDescription("AskQuestionOnChangeOrdersCompletion", ThisObject);
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure AskQuestionOnChangeOrdersCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		OnOrdersWhenChangingOnServer();
	Else
		Object.ByReferences = Not Object.ByReferences;
	EndIf;
	
EndProcedure

&AtClient
Procedure ForOrdersWhenChangingOpenSelectionOfOrder(Result, AdditionalParameters) Export
	
	Object.ReferenceOrder = Result;
	If Not ValueIsFilled(Object.ReferenceOrder) Then
		Object.ByReferences = False;
		Return;
	EndIf;
	
	OnOrdersWhenChangingOnServer();
	
EndProcedure

&AtServer
Procedure OnOrdersWhenChangingOnServer()
	
	If Object.ByReferences Then
		
		If Object.Goods.Count() = 0
			Or Not UseLineCode Then
			FillInByOrderOnServer();
		Else
			LinkRowsToOrders(Not UseReceiptForMultipleOrders);
		EndIf;
		
		FillInDiscrepancyAttributeOrder(Object.Goods, Object.ByReferences, UseLineCode);
		
		If TypeOf(Object.ReferenceOrder) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
			
			ThisIsReturnOfSpoilage = Common.ObjectAttributeValue(Object.ReferenceOrder, "ReturnOfSpoiledGoods");
			If ThisIsReturnOfSpoilage = True Then
				
				Object.ReturnOfSpoiledGoods = True;
				ConfigureFormForCorruption();
				
			Else
				ClearDisableConfigureFormForCorruption();
			EndIf;
			
		Else
			
			ClearDisableConfigureFormForCorruption();
			
		EndIf;
		
	Else
		
		OrderList.Clear();
		UnlinkFromOrderServer(True, False);
		
		Object.ReferenceOrder = Undefined;
		
		ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
		
		ConfigureFormForCorruption();
		
	EndIf;
	
	UpdateOrderInformation();
	UpdateDependentDetailsOfOrderForm(Items, Object.Goods, DiscrepancyOrderText);
	SetElementProperties();
	SetLBEditingOption();
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtServer
Procedure BusinessOperationOnChangeServer()
	
	Handler = Documents.ReceiptOfGoodsFromCustodian.ActionHandler(Object.BusinessOperation);
	
	UseOrders                   = Handler.UseOrders();
	UseLineCode                      = Handler.UseLineCode();
	UseReceiptForMultipleOrders = Handler.UseReceiptForMultipleOrders();
	ContractBusinessTransaction              = Handler.ContractBusinessTransaction();
	
	ToUseTermsOfSales =
		Handler.CustomerAgreementsAreApplicable()
		And Handler.ToUseTermsOfSales();
	
	FillInCommissionAgentDoesNotKeepRecordsOfRPTOnServer();
	OnOrdersWhenChangingOnServer();
	
	Handler.RecalculateNumberOfUnits(Object);
	
	ContractOnChangeServer(False, False);
	
	SetDefaultPriceView();
	
	Handler.AdjustItemSelectionSettings(ThisObject, Object);
	Handler.CustomizeForm(ThisObject, Object.Number, Object.Date);
	
	SeriesSpecificationParameters = SeriesSpecificationParameters();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	BusinessTransactionBeforeTheChange = Object.BusinessOperation;
	
	If QualityControl.UpdateActionParameters(
			Documents.ReceiptOfGoodsFromCustodian,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure DateOnChangeServer(RecalculatePrices_, PricesCalculated)
	
	If RecalculatePrices_ Then
		PricesCalculated = FillThePricesByTermsOfSalesServer();
	Else
		PricesCalculated = False;
	EndIf;
	
	UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
														Object.Date);
	
	DeterminePresenceOfOrderScheme();
	HowToSetSeriesVisibility();
	SetAvailabilityOfRefillsUponAcceptance();
	
	AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(ThisObject, Object.Date);
	
	If Not Items.ProductsGroupQuantityByRNPT.Visible Then
		RecalculateNumberOfRNPT();
	EndIf;
	
	If QualityControl.UpdateActionParameters(
			Documents.ReceiptOfGoodsFromCustodian,
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
			Documents.ReceiptOfGoodsFromCustodian,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure PartnerOnChangeServer()
	
	DirectionsOfActivity = Object.LineOfBusiness;
	
	DocumentSales = FormAttributeToValue("Object");
	DocumentSales.FillInDefaultSalesConditions();
	ResponsiblePersonsServer.FillInManager_(DocumentSales);
	ValueToFormAttribute(DocumentSales, "Object");
	
	DocumentCurrency = Object.Currency;
	
	If Contract <> Object.Contract Then
		Contract = Object.Contract;
	EndIf;
	
	FillInCommissionAgentDoesNotKeepRecordsOfRPTOnServer();
	Handler = Documents.ReceiptOfGoodsFromCustodian.ActionHandler(Object.BusinessOperation);
	Handler.SetContractAvailability(ThisObject, Object, Object.Contract);
	Handler.CustomizeForm(ThisObject, Object.Number, Object.Date);
	
	WarehouseOnChangeServer(False, Object.ByReferences);
	FillInPriceTypes();
	FillInServiceDetailsForProductRange();
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, Object.ReusablePackageReturn);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateTotals_(ThisObject);
	
	If DirectionsOfActivity <> Object.LineOfBusiness Then
		LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	If QualityControl.UpdateActionParameters(
			Documents.ReceiptOfGoodsFromCustodian,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	
	DirectionsOfActivity = Object.LineOfBusiness;
	
	Handler = Documents.ReceiptOfGoodsFromCustodian.ActionHandler(Object.BusinessOperation);
	Handler.SetContractAvailability(ThisObject, Object, Object.Contract);
	
	If ValueIsFilled(Object.Counterparty) Then
		FillInDefaultContract();
	EndIf;
	
	If DirectionsOfActivity <> Object.LineOfBusiness Then
		LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	FillInPriceTypes();
	PurchasesServer.FillInSelectionListNameOfIncomingDocument(ThisObject, Object.Counterparty);
	
	WhenChangingKeyDetailsStatusOfEDO();
	If QualityControl.UpdateActionParameters(
			Documents.ReceiptOfGoodsFromCustodian,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenChangingAgreementAtServer(RecalculatePrices_ = True)
	
	DirectionsOfActivity = Object.LineOfBusiness;
	
	DocumentSales = FormAttributeToValue("Object");
	DocumentSales.FillInTermsOfSalesUnderAgreement(RecalculatePrices_);
	ResponsiblePersonsServer.FillInManager_(DocumentSales);
	ValueToFormAttribute(DocumentSales, "Object");
	
	DocumentCurrency = Object.Currency;
	FillInPriceTypes();
	FillInCommissionAgentDoesNotKeepRecordsOfRPTOnServer();
	
	If Contract <> Object.Contract Then
		Contract = Object.Contract;
	EndIf;
	
	Handler = Documents.ReceiptOfGoodsFromCustodian.ActionHandler(Object.BusinessOperation);
	Handler.SetContractAvailability(ThisObject, Object, Object.Contract);
	Handler.CustomizeForm(ThisObject, Object.Number, Object.Date);
	
	WarehouseOnChangeServer(False, Object.ByReferences);
	
	FillInServiceDetailsForProductRange();
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, Object.ReusablePackageReturn);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateTotals_(ThisObject);
	
	If DirectionsOfActivity <> Object.LineOfBusiness Then
		LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	If QualityControl.UpdateActionParameters(
			Documents.ReceiptOfGoodsFromCustodian,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	DirectionsOfActivity = Object.LineOfBusiness;
	
	If ValueIsFilled(Object.Organization) Then
		FillInDefaultContract();
	EndIf;
	
	Handler = Documents.ReceiptOfGoodsFromCustodian.ActionHandler(Object.BusinessOperation);
	Handler.SetContractAvailability(ThisObject, Object, Object.Contract);
	
	FillInSubordinatePropertiesForStatistics("Organization");
	
	If DirectionsOfActivity <> Object.LineOfBusiness Then
		LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	FillInPriceTypes();
	WhenChangingKeyDetailsStatusOfEDO();
	RecalculateNumberOfRNPT();
	If QualityControl.UpdateActionParameters(
			Documents.ReceiptOfGoodsFromCustodian,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ContractOnChangeServer(ClearLines, UnbindLines, DirectModificationOfContractField = False)
	
	If ClearLines
		Or (UnbindLines
			And Not UseLineCode) Then
		
		Object.ByReferences = False;
		Object.ReferenceOrder    = Undefined;
		
		If ClearLines Then
			Object.Goods.Clear();
		EndIf;
		
		OnOrdersWhenChangingOnServer();
		
		SetElementProperties();
		
	ElsIf UnbindLines Then
		
		UnlinkFromOrderServer(True, False);
		
		UpdateOrderInformation();
		UpdateDependentDetailsOfOrderForm(Items, Object.Goods, DiscrepancyOrderText);
		
	EndIf;
	
	ContractDetails_ = New Structure("Currency, Department", "ARAPCurrency");
	Catalogs.CounterpartyContracts.FillInDocumentDetails(Object, Object.Contract, ContractDetails_);
	
	If UseLinesOfBusiness
		And Not Object.ByReferences Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms,
			Object.Contract);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	Contract = Object.Contract;
	
	WhenChangingKeyDetailsStatusOfEDO();
	
	ResponsiblePersonsServer.FillInManager_(Object);
	
	If ValueIsFilled(Contract) Then
		
		If Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent Then
			CurrencyOfContractSettlements = Common.ObjectAttributeValue(Contract, "ARAPCurrency");
			If Object.Currency <> CurrencyOfContractSettlements Then
				OriginalPriceView = Catalogs.TypesOfPrices.EmptyRef();
				Object.Currency = CurrencyOfContractSettlements;
				
			EndIf;
		EndIf;
		
		DocumentCurrency = Object.Currency;
		NewKindOfPrice = Common.ObjectAttributeValue(Object.Contract,"PriceTypeAccountingPriceType");
		
	EndIf;
	
	FillInPriceTypes();
	RecalculateNumberOfRNPT();
	If QualityControl.UpdateActionParameters(
			Documents.ReceiptOfGoodsFromCustodian,
			Object,
			CacheQualityControl,
			DirectModificationOfContractField) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
	SetLBEditingOption();
	
EndProcedure

&AtServer
Procedure WarehouseOnChangeServer(ClearLines, UnbindLines, DirectModificationOfWarehouseField = False)
	
	If ClearLines
		Or (UnbindLines
			And Not UseLineCode) Then
		
		Object.ByReferences = False;
		Object.ReferenceOrder    = Undefined;
		
		If ClearLines Then
			Object.Goods.Clear();
		EndIf;
		
		OnOrdersWhenChangingOnServer();
		
		SetElementProperties();
		
	ElsIf UnbindLines Then
		
		UnlinkFromOrderServer(True, False);
		
		UpdateOrderInformation();
		UpdateDependentDetailsOfOrderForm(Items, Object.Goods, DiscrepancyOrderText);
		
	EndIf;
	Handler = Documents.ReceiptOfGoodsFromCustodian.ActionHandler(Object.BusinessOperation);
	Handler.FillInShopPantryAttributeInTable(Object);
	DeterminePresenceOfOrderScheme();
	HowToSetSeriesVisibility();
	SetAvailabilityOfRefillsUponAcceptance();
	
	Warehouse = Object.Warehouse;
	If QualityControl.UpdateActionParameters(
			Documents.ReceiptOfGoodsFromCustodian,
			Object,
			CacheQualityControl,
			DirectModificationOfWarehouseField) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
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
Procedure ReusablePackageReturnOnChangeServer()
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ReusablePackageReturn);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
	FillInServiceDetailsForProductRange();
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsSalesOrderStartChoiceCompletion(Result, AdditionalParameters) Export
	
	Items.Goods.CurrentData.ReferenceOrder = Result;
	
	UpdateOrderInformation();
	
EndProcedure

#EndRegion

#Region WorkingWithCounterparties
#EndRegion

#Region WorkingWithClipboard

&AtClient
Procedure SetAvailabilityOfClipboardCommandsOnClient()
	
	ItemArray = New Array();
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items,
		ItemArray,
		"Enabled",
		True);
	
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
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object.Goods, Items.Goods.SelectedRows);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboard()
	
	FilterParameters = New Map;
	FilterParameters.Insert("Products.ItemsType", SelectionByProductMultiTurnContainer(Object.BusinessOperation));
	
	Columns = "Products,Characteristic,Package,NumberOfPackages,Price,CCDNumber,
		|ProductsInSet,ItemVariantOfSet,Damage,ProductsRecordingAsReceived,CharacteristicRecordingAsReceived";
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReceiptFromToller2_5") Then
		Columns =
			"Products,Characteristic,Package,NumberOfPackages,CCDNumber,
			|ProductsInSet,ItemVariantOfSet,Damage,ProductsRecordingAsReceived,CharacteristicRecordingAsReceived";
	EndIf;
	If UseLineCode Then
		Columns = "ReferenceOrder," + Columns;
	EndIf;
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ReusablePackageReturn);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
		StructureOfActions);
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object, TheCommissionAgentDoesNotKeepRecordsOnTheRNPT);
	
	If UseLineCode Then
		OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, Object.ByReferences);
	EndIf;
	
	RowsToProcess = New Array;
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);
		
		If Not Object.ReturnOfSpoiledGoods
			And CurrentRow.Damage Then
			
			CurrentRow.Damage = False;
			CurrentRow.ProductsRecordingAsReceived = Catalogs.Products.EmptyRef();
			CurrentRow.CharacteristicRecordingAsReceived = Catalogs.ItemsCharacteristics.EmptyRef();
			
		EndIf;
		
		If Not UseLineCode Then
			CurrentRow.OrderDiscrepancy_3 = 0;
		EndIf;
		
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods);
	
	UpdateOrderInformation();
	UpdateDependentDetailsOfOrderForm(Items, Object.Goods, DiscrepancyOrderText);
	
	FillInServiceDetailsForProductRange();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	CalculateTotals_(ThisObject);
	
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
	
	StructureOfActionsWithAddedStrings = Common.CopyRecursive(
		StructureOfActionsWithModifiedStrings);
	
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute",         FillInArticleAttribute);
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", FillInProductTypeAttribute_);
	StructureOfActionsWithAddedStrings.Insert("FillInFeatureAttribute",
													FillInFeatureAttribute);
	StructureOfActionsWithAddedStrings.Insert("FillInNoReturnContainerAttribute",
													Object.ReusablePackageReturn);
	StructureOfActionsWithAddedStrings.Insert("FillInCheckQualityDateOfQualityConfirmation",
		CacheQualityControl);
	
	DataParameters = New Structure;
	DataParameters.Insert("Data",                                 Data);
	DataParameters.Insert("StructureOfActionsWithModifiedStrings",  StructureOfActionsWithModifiedStrings);
	DataParameters.Insert("StructureOfActionsWithAddedStrings", StructureOfActionsWithAddedStrings);
	DataParameters.Insert("DialColumns",                          DialColumns(ThisObject));
	
	SetsServer.AtEndOfEditingSet(ThisObject, "Goods", DataParameters);
	
	CalculateTotals_(ThisObject);
	
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
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtServer
Procedure WhenRemovingComponentsOnServer(TSName, AdditionalParameter)
	
	SetsServer.WhenRemovingComponents(ThisObject, TSName, AdditionalParameter);
	
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
	
	StructureOfActionsWithAddedStrings = New Structure;
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute",          FillInArticleAttribute);
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_",  FillInProductTypeAttribute_);
	StructureOfActionsWithAddedStrings.Insert("FillInCCDTrackingAttribute", FillInCCDTrackingAttribute);
	StructureOfActionsWithAddedStrings.Insert("FillInCheckQualityDateOfQualityConfirmation",
		CacheQualityControl);
	
	StructureOfActionsWithAddedStrings.Insert("FillInNoReturnContainerAttribute",
													Object.ReusablePackageReturn);
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActionsWithAddedStrings);
	
	AddActionsToStructureWhenChangingPackagesNumber(
		StructureOfActionsWithAddedStrings, Object, TheCommissionAgentDoesNotKeepRecordsOnTheRNPT);
	AddPriceFillingActionsToStructure(StructureOfActionsWithAddedStrings, Object,
		ToUseTermsOfSales);
	
	If UseLineCode Then
		OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActionsWithAddedStrings, Object.ByReferences);
	EndIf;
	
	StructureOfActionsWithModifiedStrings = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(
		StructureOfActionsWithModifiedStrings, Object, TheCommissionAgentDoesNotKeepRecordsOnTheRNPT);
	
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
	
	OpenSeriesIndicationForm = BarcodingOfItemsClient.YouNeedToOpenFormForSpecifyingSeriesAfterProcessingBarcodes(
								StructureOfActions);
	
	If OpenSeriesIndicationForm Then
		CurDataId = StructureOfActions.ArrayOfRowsWithSeries_[0];
		
		AttachIdleHandler("OpenSeriesSelectionWhenScanningProductBarCode", 0.1, True);
	EndIf;
	
	If StructureOfActions.CurrentRow <> Undefined Then
		Items.Goods.CurrentRow = StructureOfActions.CurrentRow;
	EndIf;
	
	UpdateOrderInformation();
	UpdateDependentDetailsOfOrderForm(Items, Object.Goods, DiscrepancyOrderText);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtServer
Procedure ProcessBarcodesServer(StructureOfActionParameters, CachedValues)
	
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject, Object, StructureOfActionParameters, CachedValues);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
EndProcedure

#EndRegion

#Region SelectionAndProcessingOfQuantityVerification

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected)
	
	TableOfGoods       = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	
	ListOfProperties =
		"ProductsInSet, Products, Characteristic, ItemVariantOfSet, Package, Series, NumberOfPackages, Price";
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReceiptFromToller2_5") Then
		ListOfProperties =
			"ProductsInSet, Products, Characteristic, ItemVariantOfSet, Package, Series, NumberOfPackages";
	EndIf;
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ReusablePackageReturn);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object, TheCommissionAgentDoesNotKeepRecordsOnTheRNPT);
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	
	If UseLineCode Then
		OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(
			StructureOfActions, Object.ByReferences);
	EndIf;
	
	RowsToProcess = New Array;
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct, ListOfProperties);
		
		If Not UseLineCode Then
			CurrentRow.OrderDiscrepancy_3 = 0;
		EndIf;
		
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods);
	
	UpdateDependentDetailsOfOrderForm(Items, Object.Goods, DiscrepancyOrderText);
	
	FillInServiceDetailsForProductRange();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtServer
Procedure SelectionProcessingSelectionOfTransferredGoods(ValueSelected, PricesCalculated)
	
	RowsArray = New Array;
	
	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	If Not Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReceiptFromToller2_5") Then
		PriceFillingParameters = New Structure();
		PriceFillingParameters.Insert("PopulationFields", "Price");
		PriceFillingParameters.Insert("Date",           Object.Date);
		PriceFillingParameters.Insert("Organization",    Object.Organization);
		PriceFillingParameters.Insert("Currency",         Object.Currency);
		PriceFillingParameters.Insert("PriceKind",        Object.PriceKind);
	EndIf;
	CollapseGTDNumbers = False;
	CollapseGTDNumbers =
		Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReceiptFromToller2_5")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromProcessingCompany2_5");
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	If UseLineCode Then
		OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(
			StructureOfActions, Object.ByReferences);
	EndIf;
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(ThisObject, StructureOfActions);
	
	For Each RowOfProduct In TableOfGoods Do
		
		ProductsSearch = New Structure();
		ProductsSearch.Insert("Products", RowOfProduct.Products);
		ProductsSearch.Insert("Characteristic", RowOfProduct.Characteristic);
		ProductsSearch.Insert("Purpose", RowOfProduct.Purpose);
		If Not CollapseGTDNumbers Then
			ProductsSearch.Insert("CCDNumber", RowOfProduct.CCDNumber);
		EndIf;
		If Not RowOfProduct.DifferentSeriesAccounting Then
			ProductsSearch.Insert("Series", RowOfProduct.Series);
		EndIf;
		ProductLines_2 = Object.Goods.FindRows(ProductsSearch);
		
		If ProductLines_2.Count() = 0 Then
			CurrentRow = Object.Goods.Add();
			FillPropertyValues(CurrentRow, RowOfProduct);
		ElsIf ProductLines_2.Count() = 1 Then
			CurrentRow = ProductLines_2[0];
		ElsIf ProductLines_2.Count() > 1 Then
			For Each RowToDelete In ProductLines_2 Do
				Object.Goods.Delete(RowToDelete);
			EndDo;
			CurrentRow = Object.Goods.Add();
			FillPropertyValues(CurrentRow, RowOfProduct);
		EndIf;
		
		CurrentRow.Count = RowOfProduct.QuantityIsSelected;
		RowsArray.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsArray,
		StructureOfActions,
		Object.Goods);
	
	UpdateDependentDetailsOfOrderForm(Items, Object.Goods, DiscrepancyOrderText);
	
	FillInServiceDetailsForProductRange();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	Handler = Documents.ReceiptOfGoodsFromCustodian.ActionHandler(Object.BusinessOperation);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActions = New Structure; 
	Handler.AddFillInActionForShopPantryAttribute(StructureOfActions, Object.Warehouse);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsArray,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	If Not Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReceiptFromToller2_5") Then
		StructureOfPriceCalculationActions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(
			StructureOfPriceCalculationActions, Object, TheCommissionAgentDoesNotKeepRecordsOnTheRNPT, False);
		StructureOfPriceCalculationActions.Insert("FillInNoReturnContainerAttribute", Object.ReusablePackageReturn);
		
		PricesCalculated =
			EnterprisePricesFillingServer.FillInPrices(
				Object.Goods,
				RowsArray,
				PriceFillingParameters,
				StructureOfPriceCalculationActions);
	EndIf;
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtServer
Procedure ProcessingProductSelectionFromOrder(AddressInStorage)
	
	Table = GetFromTempStorage(AddressInStorage).Goods;//ValueTable
	
	FieldsNames = "LineNumber";
	Table.Sort(FieldsNames + " Desc");
	
	// Grouping a table by row keys.
	StringTree     = New Array;
	TheStructureOfTheSearch = New Structure(FieldsNames);
	
	For Each TableRow In Table Do
		If TheStructureOfTheSearch.LineNumber <> TableRow.LineNumber Then
			RowsArray = New Array;
			StringTree.Add(RowsArray);
			
			FillPropertyValues(TheStructureOfTheSearch, TableRow);
		EndIf;
		
		RowsArray.Add(TableRow);
	EndDo;
	
	OrderRelationshipFields = New Structure("RowCode", 0);
	AddedRows = InvoicesServer.FillInProductsSelectedFromOrder(
		StringTree,
		FieldsNames,
		Object.Goods,
		OrderRelationshipFields);
	
	If ValueIsFilled(Object.PriceKind) Then
		FillInPricesByPriceType_Server();
	EndIf;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object, TheCommissionAgentDoesNotKeepRecordsOnTheRNPT);
	
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.ProcessTSStrings(AddedRows, StructureOfActions, Object.Goods);
	
	FillInDiscrepancyAttributeOrder(Object.Goods, Object.ByReferences, UseLineCode);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
	UpdateOrderInformation();
	UpdateDependentDetailsOfOrderForm(Items, Object.Goods, DiscrepancyOrderText);
	
	FillInServiceDetailsForProductRange();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtServer
Function PutTablePartOfGoodsInTemporaryStorageToCheckQuantity()
	
	GroupColumns =
		"ProductsInSet,
		|ItemVariantOfSet,
		|Products,
		|ItemsType,
		|Characteristic,
		|ItemVariantsAreUsed,
		|Package,
		|Series,
		|BatchesIndicationStatus,
		|RowID";
	
	UnloadedColumns = GroupColumns + ", NumberOfPackages";
	
	TabularPartProducts = Object.Goods.Unload(, UnloadedColumns);
	TabularPartProducts.GroupBy(GroupColumns, "NumberOfPackages");
	
	AddressInTempStorage = PutToTempStorage(TabularPartProducts, UUID);
	
	Return AddressInTempStorage;
	
EndFunction

&AtServer
Function PlaceGoodsInStorageForSelectionOfTransferredGoods()
	
	Columns =
		"LineNumber,
		|Products,
		|Characteristic,
		|Purpose,
		|CCDNumber,
		|Series,
		|BatchesIndicationStatus,
		|Count";
	
	Address = PutToTempStorage(Object.Goods.Unload(, Columns), UUID);
	
	Return Address;
	
EndFunction

&AtServer
Procedure ChangeTablePartBasedOnResultsOfCheck(ReturnParameters, CachedValues)
	
	GoodsTable   = GetFromTempStorage(ReturnParameters.Goods);
	RowsToProcess = New Array;
	ProcessedLinesAreNew = New Array;
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
			
			ProcessedLinesAreNew.Add(TSRow);
			
		EndIf;
		
	EndDo;

	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object, TheCommissionAgentDoesNotKeepRecordsOnTheRNPT);

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);

	FillInSalePrice = BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object, True);
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ReusablePackageReturn);
	StructureOfActions.Insert("FillInSalePrice", FillInSalePrice);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ProcessedLinesAreNew,
		StructureOfActions,
		Object.Goods,
		CachedValues);

	For Each TSRow In LinesToDelete Do
		Object.Goods.Delete(TSRow);
	EndDo;
	
	FillInServiceDetailsForProductRange();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	
EndProcedure

#EndRegion

#Region PriceManagementSystem

&AtServer
Function FillThePricesByTermsOfSalesServer(ErrorText = "")
	
	FillParameters = New Structure();
	FillParameters.Insert("Date",                      Object.Date);
	FillParameters.Insert("Terms",                Object.Terms);
	If Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent Then
		FillParameters.Insert("PriceKind", Common.ObjectAttributeValue(Object.Contract,"PriceTypeAccountingPriceType"));
	EndIf;
	FillParameters.Insert("Organization",               Object.Organization);
	FillParameters.Insert("Currency",                    Object.Currency);
	FillParameters.Insert("ToReturnReusablePackage", Object.ReusablePackageReturn);
	FillParameters.Insert("CalculateSets",        True);
	FillParameters.Insert("PopulationFields",            "Price");
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(
		StructureOfActions, Object, TheCommissionAgentDoesNotKeepRecordsOnTheRNPT, False);
	
	PricesCalculated = EnterprisePricesFillingServer.FillInPrices(Object.Goods, Undefined, FillParameters, StructureOfActions);
	
	CalculateTotals_(ThisObject);
	
	Return PricesCalculated;
	
EndFunction

&AtClient
Procedure FillInPricesByPriceType_(SelectedRows = Undefined)
	
	TabularSectionName           = "Goods";
	TabularSectionPresentation = NStr("vi = 'Hàng hóa';
										|ru = 'Товары';
										|en = 'Goods'; fa = 'کالاها';
										|it = 'Merci';
										|pl = 'Wiersze pozycji';
										|tr = 'Ürünler'");
	
	FillInPrices = EnterprisePricesFillingClient.ItIsNecessaryToFillInPricesByTypeOfPrices(Object, TabularSectionName, TabularSectionPresentation);
	
	If FillInPrices Then
		
		If Not ValueIsFilled(Object.PriceKind) Then
			WarningText = NStr("vi = 'Chứng từ không chỉ ra loại giá. Giá không thể được điền';
								|ru = 'В документе не указан вид цены. Цены не могут быть заполнены';
								|en = 'The price type is not specified in the document. Prices cannot be filled in'; fa = 'The price type is not specified in the document. Prices cannot be filled in';
								|it = 'Nel documento non è indicato il tipo di prezzo. I prezzi non possono essere inseriti';
								|pl = 'Dokument nie określa rodzaju ceny. Ceny nie mogą być wypełnione';
								|tr = 'Belgede fiyat türü belirtilmemiştir. Fiyatlar doldurulamaz'");
			ShowMessageBox(, WarningText);
		Else
			PricesCalculated = FillInPricesByPriceType_Server(SelectedRows);
			SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, Object.PriceKind);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Function FillInPricesByPriceType_Server(Val SelectedRows = Undefined)
	
	FillParameters = New Structure;
	FillParameters.Insert("PopulationFields",     "Price");
	FillParameters.Insert("Date",               Object.Date);
	FillParameters.Insert("Organization",        Object.Organization);
	FillParameters.Insert("Currency",             Object.Currency);
	FillParameters.Insert("PriceKind",            Object.PriceKind);
	FillParameters.Insert("CalculateSets", True);
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(
		StructureOfActions, Object, TheCommissionAgentDoesNotKeepRecordsOnTheRNPT, False);
	
	LinesToFillIn_ = Undefined;
	If Not SelectedRows = Undefined Then
		
		LinesToFillIn_ = New Array;
		For Each CurID_ In SelectedRows Do
			LinesToFillIn_.Add(Object.Goods.FindByID(CurID_));
		EndDo;
		
	EndIf;
	
	PricesCalculated = EnterprisePricesFillingServer.FillInPrices(Object.Goods, LinesToFillIn_, FillParameters, StructureOfActions);
	
	CalculateTotals_(ThisObject);
	
	Return PricesCalculated;
	
EndFunction

#EndRegion

#Region SetOfSeries

&AtServer
Function SeriesSpecificationParameters()
	
	ObjectManager = Documents.ReceiptOfGoodsFromCustodian;
	
	Return New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, ObjectManager));
	
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
	
	StructureOfActions = New Structure("UpdateNumberOfProductsWhenRegistering", True);
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object, TheCommissionAgentDoesNotKeepRecordsOnTheRNPT);
	
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	ProductsServer.ProcessSeriesIndication_(Object,SeriesSpecificationParameters,ParametersOfSeriesIndicationForm,StructureOfActions);
	
EndProcedure

&AtServer
Procedure FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow,
																			CachedValues)
	
	ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Object, SeriesSpecificationParameters,
		IDCurrentRow, CachedValues);
	
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
		AddActionsToStructureWhenChangingPackagesNumber(ProcessingActions, Object, TheCommissionAgentDoesNotKeepRecordsOnTheRNPT);
	Else
		AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(ThisObject, ProcessingActions);
	EndIf;
	
	PurchasesServer.ProcessIndicationOfCCDNumber(ThisObject,
												RowID,
												SelectionData_1,
												CCDNumbersFilledIn,
												Undefined,
												ProcessingActions);
	
EndProcedure

&AtServer
Procedure FillInCCDNumbersForTransferredGoodsOnServer()
	
	FillParameters	= PurchasesServer.ParametersForFillingInCCDNumbersBasedOnCredentials();
	QueryOptions	= FillParameters.QueryOptions;
	
	PeriodDate_	= EndOfDay(CurrentSessionDate());
	Period		= New Boundary(PeriodDate_, BoundaryType.Including);
	
	RequestParametersToFillIn = "Organization, Contract";
	FillPropertyValues(QueryOptions, Object, RequestParametersToFillIn);
	
	QueryOptions.Period = Period;
	
	ActionsWithString = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(
		ActionsWithString, Object, TheCommissionAgentDoesNotKeepRecordsOnTheRNPT, False);
	
	FillParameters.ActionsWithString = ActionsWithString;
	
	PurchasesServer.FillInCCDNumbersAccordingToCredentials(Object.Goods, "KeeperSLeftovers", FillParameters);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

#EndRegion

#Region Damage

&AtClient
Procedure ReturnOfSpoiledGoodsCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		ClearDisableConfigureFormForCorruption();
	EndIf;
	
EndProcedure

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
	
	DisplaySpoilageElements = Object.ReturnOfSpoiledGoods;
	
	CommandReturnsDamageHeader = NStr("vi = 'Nhận lại hàng hóa có chất lượng khác';
										|ru = 'Возврат товаров другого качества';
										|en = 'Return nonconforming products'; fa = 'برگشت محصولات نامنطبق';
										|it = 'Reso dei prodotti di qualità diversa';
										|pl = 'Zwrot towarów innej jakości';
										|tr = 'Uygun olmayan ürünlerin iadesi'");
	ShippedItemTitle = NStr("vi = 'Hàng hóa đã giao từ trước.';
							|ru = 'Ранее был отгружен товар';
							|en = 'Goods were unloaded earlier'; fa = 'کالا قبلاً تخلیه شده است';
							|it = 'La merce è stata spedita precedentemente';
							|pl = 'Wcześniej został wysłany towar';
							|tr = 'Ürün daha önce sevk edildi'");
	ReturnItemTitle = NStr("vi = 'Hàng hóa bị trả lại có chất lượng khác';
							|ru = 'Возвращается товар другого качества';
							|en = 'Goods of other quality are returned'; fa = 'کالا با کیفیت دیگر برگشت داده می‌شود';
							|it = 'Viene restituita la merce di qualità diversa';
							|pl = 'Zwracany jest towar innej jakości';
							|tr = 'Uygun olmayan ürünler iade ediliyor'");
	If Object.BusinessOperation =
		Enums.BusinessTransactions.ReceiptFromToller2_5 Then
		
		CommandReturnsDamageHeader = NStr("vi = 'Tiếp nhận hàng hóa có chất lượng khác';
											|ru = 'Поступление товаров другого качества';
											|en = 'Nonconforming product receipt'; fa = 'Nonconforming product receipt';
											|it = 'Nonconforming product receipt';
											|pl = 'Nonconforming product receipt';
											|tr = 'Uygun kalitede olmayan ürünlerin kabulü'");
		ShippedItemTitle = NStr("vi = 'Hàng hóa dự tính';
								|ru = 'Ожидаемый товар';
								|en = 'Expected item'; fa = 'Expected item';
								|it = 'Expected item';
								|pl = 'Expected item';
								|tr = 'Beklenen ürünler'");
		ReturnItemTitle = NStr("vi = 'Tiếp nhận hàng hóa có chất lượng khác';
								|ru = 'Поступает товар другого качества';
								|en = 'Nonconforming product is received'; fa = 'Nonconforming product is received';
								|it = 'Nonconforming product is received';
								|pl = 'Nonconforming product is received';
								|tr = 'Uygun kalitede olmayan ürünler teslim alınır'");
		
	EndIf;
	AvailabilityOfSpoilageElements = Not Object.ByReferences
		And Not ValueIsFilled(Object.ReferenceOrder)
		And Not ValueIsFilled(Object.DocumentTransfers_);
	
	Items.ReturnOfSpoiledGoods.Enabled = AvailabilityOfSpoilageElements;
	
	Items.ReturnOfSpoiledGoods.Title = CommandReturnsDamageHeader;
	Items.GoodsGroupProductsShippedEarlier.Title = ShippedItemTitle;
	Items.GoodsGroupReturnedGoods.Title = ReturnItemTitle;
	
	Items.ReturnOfSpoiledGoods.Check = DisplaySpoilageElements;
	Items.GoodsGroupProductsShippedEarlier.ShowInHeader = DisplaySpoilageElements;
	Items.GoodsGroupReturnedGoods.Visible = DisplaySpoilageElements;
	
EndProcedure

&AtServer
Procedure ClearDisableConfigureFormForCorruption()
	
	Object.ReturnOfSpoiledGoods = False;
	
	ConfigureFormForCorruption();
	
	RowsToProcess = New Array();
	For Each LineProducts_ In Object.Goods Do
		
		If LineProducts_.Damage Then
			RowsToProcess.Add(LineProducts_);
		EndIf;
		LineProducts_.Damage = False;
		LineProducts_.ProductsRecordingAsReceived = Catalogs.Products.EmptyRef();
		LineProducts_.CharacteristicRecordingAsReceived = Catalogs.ItemsCharacteristics.EmptyRef();
		
	EndDo;
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.ProcessTSStrings(RowsToProcess, StructureOfActions, Object.Goods);
	
	If SeriesSpecificationParameters.UseItemsBatch Then
		
		For Each RowSeries In Object.SetOfSeries Do
			
			RowSeries.ProductsRecordingAsReceived = Catalogs.Products.EmptyRef();
			RowSeries.CharacteristicRecordingAsReceived = Catalogs.ItemsCharacteristics.EmptyRef();
			
		EndDo;
		
	EndIf;

EndProcedure

&AtServer
Function CheckForGradationServer(ProductOfOriginalQuality, NonconformingProducts)
	
	Return InformationRegisters.AnotherQualityGoods.CheckForGradation(ProductOfOriginalQuality, NonconformingProducts);
	
EndFunction

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
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisObject);
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisObject, False);
	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisObject, False);
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject);
	
	// Setting the conditional design for the 'Purpose' element of the 'Products' tabular part
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPurpose.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfQuantityAccordingToRNPT(ThisObject);
	
	#Region GoodsCCDNumberOriginCountry
	
	ConditionalDesignParameters = ProductsServer.ParametersForSettingConditionalAppearanceOfCCDNumber();
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber = "GoodsCCDNumberOriginCountry";
	
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject);
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfCCDNumber(ThisObject);
	AccountingForTraceableGoodsLocalization.EstablishConditionalAppearanceOfAccountingOnGTDVDocumentsOfCommissionAgent(ThisObject, False);
	
	#Region ConditionalAppearance_StockQualityChange
	
	// Design characterization Arrival
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
	
	// Properties Nomenclature Arrival, characterization Arrival
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
	
	#EndRegion
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCCDNumber.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCCDNumberOriginCountry.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsQuantityByGBRN.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsProductsFEACNUnitOfMeasure.Name);
	
	ProcessorOperations = New ValueList;
	ProcessorOperations.Add(Enums.BusinessTransactions.ReceiptFromToller2_5);
	ProcessorOperations.Add(Enums.BusinessTransactions.ReturnFromProcessingCompany2_5);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = ProcessorOperations;
	
	Item.Appearance.SetParameterValue("Visible", False);
	#EndRegion
	
	#Region GoodsOrderLineCode
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsReferenceOrder.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsRowCode.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ByReferences");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	#EndRegion
	
	#Region GoodsReferenceOrder
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsReferenceOrder.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OrderList.RowsCount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = 2;
	
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
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Vượt quá đơn hàng, chưa chọn đơn hàng';
													|ru = 'Сверх заказа, заказ не выбран';
													|en = 'In excess of the order, the order is not selected'; fa = 'In excess of the order, the order is not selected';
													|it = 'Oltre all''ordine, l''ordine non è selezionato';
													|pl = 'Przewyższa zamówienie, zamówienie nie wybrane';
													|tr = 'Sipariş fazlası, sipariş seçilmedi'"));
	
	#EndRegion
	
	#Region GoodsRowCode
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsRowCode.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseLineCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsRowCode.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ReferenceOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	#EndRegion
	
	// Blocking the 'price' column if the price type is specified
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPrice.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSum.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PriceKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// Setting the conditional design for the 'Activity Direction' element
	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisObject);
	
	// Setting the conditional design for the type of prices
	EnterprisePricesFillingServer.EstablishConditionalAppearanceOfPriceTypes(ThisObject, "PriceKind", "Object.PriceKind");
	
	// Conditional appearance of quality control Attributes.
	Fields = QualityControl.Fields(
		Items.GoodsToControlQuality,
		Items.GoodsQualityConfirmationDate);
	QualityControl.SetupAppearance(ConditionalAppearance, Fields);
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	Documents.ReceiptOfGoodsFromCustodian.ConfigureBusinessTransactionDetails(ThisObject, Object);
	
	Handler = Documents.ReceiptOfGoodsFromCustodian.ActionHandler(Object.BusinessOperation);
	
	UseOrders                   = Handler.UseOrders();
	UseLineCode                      = Handler.UseLineCode();
	UseReceiptForMultipleOrders = Handler.UseReceiptForMultipleOrders();
	RestrictGoodsReceiptWithoutCCDNumbers   = GetFunctionalOption("RestrictGoodsReceiptWithoutCCDNumbers");
	UseLinesOfBusiness        = GetFunctionalOption("UseCostAccountingByLinesOfBusiness");
	UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
														Object.Date);
	
	ToUseTermsOfSales =
		Handler.CustomerAgreementsAreApplicable()
		And Handler.ToUseTermsOfSales();
	
	Warehouse                  = Object.Warehouse;
	Contract                = Object.Contract;
	DocumentCurrency        = Object.Currency;
	SeriesSpecificationParameters = SeriesSpecificationParameters();
	ContractBusinessTransaction    = Handler.ContractBusinessTransaction();
	BusinessTransactionBeforeTheChange = Object.BusinessOperation;
	
	FillInCommissionAgentDoesNotKeepRecordsOfRPTOnServer();
	DeterminePresenceOfOrderScheme();
	SetDefaultPriceView();
	
	Handler.SetContractAvailability(ThisObject, Object);	
	Handler.AdjustItemSelectionSettings(ThisObject, Object);
	Handler.FillInShopPantryAttributeInTable(Object);
	ProcessingOfTabularForms.InitializeRowCache(Items.Goods);
	
	SetVisibilityOfSeriesElements();
	SetAvailabilityOfRefillsUponAcceptance();
	SetLBEditingOption();
	
	FillInDiscrepancyAttributeOrder(Object.Goods, Object.ByReferences, UseLineCode);
	
	UpdateOrderInformation();
	UpdateDependentDetailsOfOrderForm(Items, Object.Goods, DiscrepancyOrderText);
	FillInPriceTypes();
	FillInServiceDetailsForProductRange();
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, Object.ReusablePackageReturn);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateTotals_(ThisObject);
	ConfigureFormForCorruption();
	
	Handler.CustomizeForm(ThisObject, Object.Number, Object.Date);

	LinesOfBusinessServer.OnReadCreateAtServer(ThisObject);
	PurchasesServer.FillInSelectionListNameOfIncomingDocument(ThisObject, Object.Counterparty);
	CacheQualityControl = QualityControl.DataCacheOfMechanism(Object);
	
EndProcedure

&AtServer
Procedure UpdateOrderInformation()
	
	ParametersOfUpdate = OrdersServer.ParametersForUpdatingOrderInformationInForm();
	ParametersOfUpdate.PropsNameOrderList         = "OrderList";
	ParametersOfUpdate.OrderPathInHeader                  = "Object.ReferenceOrder";
	ParametersOfUpdate.TitleLabelName               = "HeaderOrdersText";
	ParametersOfUpdate.NameOfColumnGroupInTableSection   = "GoodsGroupReference";
	ParametersOfUpdate.OrderNameInTablePart          = "ReferenceOrder";
	ParametersOfUpdate.UseOrdersInTabularSection = UseReceiptForMultipleOrders;
	ParametersOfUpdate.OrdersUse                = UseOrders;
	
	OrdersServer.UpdateOrderInformationInForm(ThisObject, Object.Goods, ParametersOfUpdate);
	
	If Not UseReceiptForMultipleOrders
		And Object.ByReferences
		And ValueIsFilled(Object.ReferenceOrder) Then
		OrderList.Add(Object.ReferenceOrder);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetDefaultPriceView()
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReceiptFromToller2_5") Then
		Return;
	EndIf;
	If Not ToUseTermsOfSales Then
		PriceTypeSelectionParameters = SettingsValueCached.ParametersForSelectingDefaultPriceType();
		PriceTypeSelectionParameters.UseWhileSellingToCustomers = True;
		PriceTypeSelectionParameters.Status                 = Enums.StatusesOfPriceTypeValidity.Valid;
		
		DefaultPriceType = SettingsValueCached.DefaultPriceType(PriceTypeSelectionParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfRefillsUponAcceptance()
	
	Items.GoodsRefillByReceiving.Enabled = WarehousesServer.UseWarehouseManagemantSystemForGoodsReceipt(Object.Warehouse,
																											Object.Date);
	
EndProcedure

&AtServer
Procedure SetLBEditingOption()
	
	LBAvailabilityParameters = LinesOfBusinessServer.ParametersLBEditingCapability();
	
	LBAvailabilityParameters.OrderInvoice_3 = Object.ByReferences;
	LBAvailabilityParameters.Contract           = Object.Contract;
	LBAvailabilityParameters.ARAPObjectSettings   = Common.ObjectAttributeValue(Object.Contract, "ARAPObjectSettings");
	
	LinesOfBusinessServer.SetLBEditingOption(ThisObject, LBAvailabilityParameters);
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsForProductRange()
	
	FillInArticleAttribute = New Structure("Products, ProductsRecordingAsReceived",
		"SKU",
		"SKURegistration");
	
	FillInFeatureAttribute = New Structure("Products, ProductsRecordingAsReceived",
		"ItemVariantsAreUsed",
		"ItemVariantsAreUsedRecordingAsReceived");
	
	FillInProductTypeAttribute_ = New Structure("Products", "ItemsType");
	FillInCCDTrackingAttribute = New Structure("Products", "TheRecordsAreKeptByCCD");
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInArticleAttribute", FillInArticleAttribute);
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_", FillInProductTypeAttribute_);
	ParametersForFillingInBankingDetails.Insert("FillInCCDTrackingAttribute", FillInCCDTrackingAttribute);
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute",
		FillInFeatureAttribute);
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
		ParametersForFillingInBankingDetails);
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, ParametersForFillingInBankingDetails);
	
	SetsServer.FillInServiceDetails(ThisObject);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
EndProcedure

&AtClientAtServerNoContext
Function DependentDetails()
	
	Return New Structure("WithoutReusablePackages", "Sum");
	
EndFunction

&AtClientAtServerNoContext
Procedure CalculateTotals_(Form)
	If Form.Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReceiptFromToller2_5")Then
		Return;
	EndIf;
	Form.AmountTotal = Form.Object.Goods.Total("SumWithoutReusablePackages");
	
EndProcedure

&AtServer
Procedure RefillByReceivingServer()
	
	AnArrayOfOrders = OrderList.UnloadValues();
	AnArrayOfOrders.Add(Object.Ref);
	
	FillParameters = Documents.ReceiptOfGoodsFromCustodian.DocumentFillingParameters();
	FillParameters.FormIsOpen      = True;
	FillParameters.FillByWarehouseDocument = True;
	
	InvoiceTable = Documents.ReceiptOfGoodsFromCustodian.TableDataAndDocument(Object.Ref);
	
	HeaderAttributes = New Structure("Ref, Organization, BusinessOperation, Warehouse, SalesOpportunity, Department, 
									|LineOfBusiness");
	
	FillPropertyValues(HeaderAttributes, Object);
	
	Documents.ReceiptOfGoodsFromCustodian.InitializeFillingParameters(FillParameters,
																				HeaderAttributes,
																				AnArrayOfOrders);
	
	Documents.ReceiptOfGoodsFromCustodian.FillInByOrdersOrders(InvoiceTable, Object.Ref, FillParameters);
	
	NumberOfIndexes = InvoiceTable.Count() - 1;
	
	For IndexOf = 0 To NumberOfIndexes Do
		String = InvoiceTable[NumberOfIndexes - IndexOf];
		
		If String.NoteQuantity = 0 Then
			InvoiceTable.Delete(String);
		Else
			String.Count = String.NoteQuantity;
		EndIf;
	EndDo;
	
	Object.Goods.Load(InvoiceTable);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	AddActionsToStructureWhenChangingPackagesNumber(
		StructureOfActions, Object, TheCommissionAgentDoesNotKeepRecordsOnTheRNPT, False);
	
	If UseLineCode Then
		OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(
			StructureOfActions, Object.ByReferences);
	EndIf;
	
	For Each String In Object.Goods Do
		
		If Not UseLineCode Then
			String.OrderDiscrepancy_3 = 0;
		EndIf;
		
	EndDo;

	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
	Handler = Documents.ReceiptOfGoodsFromCustodian.ActionHandler(Object.BusinessOperation);
	Handler.FillInShopPantryAttributeInTable(Object);
	UpdateDependentDetailsOfOrderForm(Items, Object.Goods, DiscrepancyOrderText);
	
	FillInServiceDetailsForProductRange();
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, Object.ReusablePackageReturn);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	CalculateTotals_(ThisObject);
	
	Modified = True;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions,
																	Object,
																	TheCommissionAgentDoesNotKeepRecordsOnTheRNPT,
																	RecalculateQuantity = True)
	
	If RecalculateQuantity Then
		AddActionRecalculateNumberOfUnits(Object.BusinessOperation, StructureOfActions, Object.Warehouse);
	EndIf;
	
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ReusablePackageReturn);
	If Not Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReceiptFromToller2_5") Then
		StructureOfActions.Insert("RecalculateAmount");
		StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	EndIf;
	ThisIsRefundFromCommissionAgent = Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromCommissionAgent");
	
	If Not ThisIsRefundFromCommissionAgent
		Or Not TheCommissionAgentDoesNotKeepRecordsOnTheRNPT Then
		
		AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
			Object,
			StructureOfActions,
			"Contract");
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure AddActionRecalculateNumberOfUnits(BusinessOperation, StructureOfActions, Warehouse = Undefined)
	
	Handler = Documents.ReceiptOfGoodsFromCustodian.ActionHandler(BusinessOperation);
	Handler.AddActionRecalculateNumberOfUnits(StructureOfActions);
	Handler.AddFillInActionForShopPantryAttribute(StructureOfActions, Warehouse);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(Form, StructureOfActions)
	
	Object = Form.Object;
	
	ThisIsRefundFromCommissionAgent = Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromCommissionAgent");
	
	If ThisIsRefundFromCommissionAgent
		And Form.TheCommissionAgentDoesNotKeepRecordsOnTheRNPT Then
		
		Return;
		
	EndIf;
	
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActions,
		"Contract");
	
EndProcedure

&AtServer
Procedure DeterminePresenceOfOrderScheme()
	
	AdvancedWarehousing = WarehousesServer.UseWarehouseManagemantSystemForGoodsReceipt(Object.Warehouse, Object.Date);
	
EndProcedure

&AtServer
Procedure SetElementProperties()
	
	SetAvailabilityOfClipboardCommands();
	
	ItemArray = New Array;
	ItemArray.Add("CloseRequest");
	ItemArray.Add("CloseApplications");
	ItemArray.Add("GoodsSelectGoodsByOrdersNotes");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible", Object.ByReferences);
	
	If Object.ByReferences Then
		
		ItemArray = New Array;
		ItemArray.Add("CloseRequest");
		ItemArray.Add("CloseApplications");
		
		If ValueIsFilled(Object.ReferenceOrder) Then
			YouCanEditOrder = AccessManagement.EditionAllowed(Object.ReferenceOrder);
		Else
			YouCanEditOrder = True;
			For Each RowOfGoods In Object.Goods Do
				YouCanEditOrder = YouCanEditOrder And AccessManagement.EditionAllowed(RowOfGoods.ReferenceOrder);
				If Not YouCanEditOrder Then
					Break;
				EndIf;
			EndDo;
		EndIf;
		
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "ReadOnly", Not YouCanEditOrder);
		
	EndIf;
	
	Items.GoodsUnlinkFromOrder.Visible =
		Object.ByReferences
		And UseLineCode;
	If Not Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReceiptFromToller2_5")
		And Not Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromProcessingCompany2_5") Then
		Items.GoodsUnlinkFromOrder.Visible = UseOrders And Items.GoodsUnlinkFromOrder.Visible;
	EndIf;
EndProcedure

&AtServer
Procedure FillMultiTurnContainersFromStorageServer(AddressOfContainerInStorage)
	
	ActionStructureModifiedStrings = New Structure;
	ActionStructureModifiedStrings.Insert("RecalculateNumberOfPackages");
	ActionStructureModifiedStrings.Insert("FillInNoReturnContainerAttribute",
												Object.ReusablePackageReturn);
	
	AddActionsToStructureWhenChangingPackagesNumber(ActionStructureModifiedStrings, Object, TheCommissionAgentDoesNotKeepRecordsOnTheRNPT, False);
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(ActionStructureModifiedStrings);
	
	StructureOfActionsAddedLines = Common.CopyRecursive(
											ActionStructureModifiedStrings);
	
	StructureOfActionsAddedLines.Insert("FillInCheckQualityDateOfQualityConfirmation",
		CacheQualityControl);
	AddPriceFillingActionsToStructure(StructureOfActionsAddedLines, Object, ToUseTermsOfSales);
	
	ReusablePackageServer.FillMultiTurnContainersFromStorage(Object, AddressOfContainerInStorage, "Goods",
		"Products,Characteristic,", ActionStructureModifiedStrings, StructureOfActionsAddedLines);
	Handler = Documents.ReceiptOfGoodsFromCustodian.ActionHandler(Object.BusinessOperation);
	Handler.FillInShopPantryAttributeInTable(Object);
	FillInServiceDetailsForProductRange();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtServer
Procedure GetUploadedProductsFromStorage(GoodsAddressInStorage)
	
	ItemsFromStorage    = GetFromTempStorage(GoodsAddressInStorage);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ReusablePackageReturn);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object, TheCommissionAgentDoesNotKeepRecordsOnTheRNPT);
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
		StructureOfActions);
	
	RowsToProcess = New Array;
	
	For Each RowOfGoods In ItemsFromStorage Do
		StringTSGoods = Object.Goods.Add();
		FillPropertyValues(StringTSGoods, RowOfGoods,, "RowCode");
		RowsToProcess.Add(StringTSGoods);		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods);
	
	FillInServiceDetailsForProductRange();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
	FillInDiscrepancyAttributeOrder(Object.Goods, Object.ByReferences, UseLineCode);
	UpdateDependentDetailsOfOrderForm(Items, Object.Goods, DiscrepancyOrderText);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtServer
Procedure GetStockTypesFromStorage(ValueSelected)
	
	InventoriesServer.ProcessInputOfInventoryTypesManually(ValueSelected, ThisObject);
	
EndProcedure

&AtServer
Procedure FillInSubordinatePropertiesForStatistics(ParentPropsName)
	
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, ParentPropsName);
	
EndProcedure

&AtServer
Procedure FillInDefaultContract()
	
	Handler = Documents.ReceiptOfGoodsFromCustodian.ActionHandler(Object.BusinessOperation);
	Contract = Handler.GetDefaultContract(Object);
	
	If Contract <> Object.Contract Then
		Object.Contract = Contract;
		ContractOnChangeServer(False, Object.ByReferences);
	EndIf;
	
EndProcedure

&AtServer
Procedure ExecuteRecalculateDocumentAmountsServer(OldCurrency, NewCurrency)
	
	If OldCurrency <> NewCurrency Then
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateAmount");
		
		DocumentDate               = ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate());
		LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
		StructureOfOldCurrencyRates = ProcessingOfExchangeRatesTM.GetCurrencyRate(OldCurrency, DocumentDate, LocalAccountingCurrency);
		StructureOfNewCurrencyRates  = ProcessingOfExchangeRatesTM.GetCurrencyRate(NewCurrency,  DocumentDate, LocalAccountingCurrency);
		
		For Each CurRow In Object.Goods Do
			
			CurRow.Price = ProcessingOfExchangeRatesTM.ConvertAtRate(
				CurRow.Price,
				StructureOfOldCurrencyRates,
				StructureOfNewCurrencyRates);
			
		EndDo;
		
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
		TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
		
		CalculateTotals_(ThisObject);
	EndIf;
	
EndProcedure

&AtServer
Function PutGoodsAndStockTypesInStorage()
	
	Return InventoriesServer.PutGoodsAndStockTypesInStorage(ThisObject);
	
EndFunction

&AtClient
Procedure CloseRequestFragment()
	
	ClosureStructure = New Structure;
	ClosureStructure.Insert("Orders",                       OrderList);
	ClosureStructure.Insert("DocumentInitiator",            Object.Ref);
	ClosureStructure.Insert("CancelUnprocessedLines", True);
	ClosureStructure.Insert("CloseOrders",              True);
	
	OpenForm("DataProcessor.OrderClosureWizard.Form.ClosureForm", ClosureStructure, , , , , ,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure OpenSelectionByOrdersOrders()
	
	HeaderAttributes = HeaderAttributes(Object);
	
	AdditionalFields = New Structure;
	AdditionalFields.Insert("DateOfReceipt");
	
	FormParameters = New Structure;
	FormParameters.Insert("HeaderAttributes",				HeaderAttributes);
	FormParameters.Insert("Invoice",					Object.Ref);
	FormParameters.Insert("OrdersAreUsed",			UseOrders);
	FormParameters.Insert("InvoiceForOrders",			Object.ByReferences);
	FormParameters.Insert("OrderDocument",						Object.ReferenceOrder);
	FormParameters.Insert("AdvancedWarehousingOnShipment",		False);
	FormParameters.Insert("AdvancedWarehousingOnGoodsReceipt",	AdvancedWarehousing);
	FormParameters.Insert("AddressGoods",					AddressInvoiceGoods());
	FormParameters.Insert("AdditionalFields",			AdditionalFields);
	
	FormParameters.Insert("UseInvoicesForSeveralOrders", UseReceiptForMultipleOrders);
	
	OpenForm("CommonForm.AddItemsFromSalesOrderGoodsIssue", FormParameters, ThisObject, UUID, , , ,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure OpenOrderSelection(CallbackDescription)
	
	FilterParameters = New Structure();
	FilterParameters.Insert("Partner",                   Object.Partner);
	FilterParameters.Insert("Counterparty",                Object.Counterparty);
	FilterParameters.Insert("Terms",                Object.Terms);
	FilterParameters.Insert("Organization",               Object.Organization);
	FilterParameters.Insert("Contract",                   Object.Contract);
	FilterParameters.Insert("Currency",                    Object.Currency);
	FilterParameters.Insert("SalesOpportunity",                    Object.SalesOpportunity);
	FilterParameters.Insert("LineOfBusiness",   Object.LineOfBusiness);
	FilterParameters.Insert("ToReturnReusablePackage", Object.ReusablePackageReturn);
	
	OpeningParameters  = New Structure;
	OpeningParameters.Insert("Filter",                 FilterParameters);
	OpeningParameters.Insert("Warehouse",                 Object.Warehouse);
	OpeningParameters.Insert("Recorder",           Object.Ref);
	OpeningParameters.Insert("BusinessOperation", Object.BusinessOperation);
	
	OpenForm(
		"Document.ReceiptOfGoodsFromCustodian.Form.ReferenceChoiceForm",
		OpeningParameters,
		ThisObject,,,,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddPriceFillingActionsToStructure(StructureOfActions, Object, UseAgreements)
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReceiptFromToller2_5") Then
		Return;
	EndIf;
	FillInSalePrice = BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object, True);
	StructureOfActions.Insert("FillInSalePrice", FillInSalePrice);
	
EndProcedure

&AtServer
Procedure GoodsAfterDeleteRowServer(SeriesStatusesNeedToBeUpdated, CachedValues)
	
	If SeriesStatusesNeedToBeUpdated Then
		If Object.Goods.Count() > 1 Then
			ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
		Else
			FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Undefined, CachedValues);
		EndIf;
	EndIf;
	
	UpdateDependentDetailsOfOrderForm(Items, Object.Goods, DiscrepancyOrderText);
	
EndProcedure

&AtServer
Procedure GoodsOnEditEndServer(UpdateSeriesStatuses, CachedValues, IDCurrentRow)
	
	If UpdateSeriesStatuses Then
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues);
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
		CommonClientServer.MessageToUser(MessageText, Object.Ref, "Object.Terms", ,Cancel);
		
	EndIf;
	
	If Not ValueIsFilled(Object.Currency) Then
		MessageText = NStr("vi = 'Chưa điền trường ""Tiền tệ""';
							|ru = 'Поле ""Валюта"" не заполнено';
							|en = '""Currency"" is required'; fa = '""Currency"" is required';
							|it = 'Il campo ""Valuta"" non è compilato';
							|pl = 'Pole ""Waluta"" nie jest wypełnione';
							|tr = '""Para Birimi"" alanı doldurulmadı'");
		CommonClientServer.MessageToUser(MessageText, Object.Ref, "Object.Currency", ,Cancel);
	EndIf;
	
EndProcedure

&AtServer
Function AddressInvoiceGoods()
	
	Table = Object.Goods.Unload();
	Table.Columns.Add("DateOfShipment",    New TypeDescription("Date"));
	Table.Columns.Add("DateOfReceipt", New TypeDescription("Date"));
	
	Table.FillValues(CurrentSessionDate(), "DateOfShipment");
	Table.FillValues(CurrentSessionDate(), "DateOfReceipt");
	
	If Not UseLineCode Then
		Table.FillValues(1, "RowCode");
	EndIf;
	
	AddressInTempStorage = PutToTempStorage(Table, UUID);
	
	Return AddressInTempStorage;
	
EndFunction

&AtServer
Procedure RecalculateNumberOfRNPT()
	
	ThisIsRefundFromCommissionAgent = Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent;
	
	If ValueIsFilled(Object.Contract)
		And ValueIsFilled(Object.Organization)
		And (Not ThisIsRefundFromCommissionAgent
			Or (ThisIsRefundFromCommissionAgent
				And Not TheCommissionAgentDoesNotKeepRecordsOnTheRNPT)) Then
		
		ParametersForObtainingRnptCoefficient = AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(
												Object,
												"Contract");
		AccountingForTraceableGoodsLocalization.FillInQuantityByRNPTVOfTablePart(ParametersForObtainingRnptCoefficient,
																						Object.Goods);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInCommissionAgentDoesNotKeepRecordsOfRPTOnServer()
	
	TheCommissionAgentDoesNotKeepRecordsOnTheRNPT = Not Catalogs.TermsOfSale.CommissionAgentUsesInventoryAccountingByProductBatchID(Object.Terms)
									Or Not Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent;
	
EndProcedure

&AtServer
Function AccountingTypeOfContractPrice()
	
	ParametersStructure = EnterprisePricesFillingServer.NewParametersForCheckingTypeOfContractPrices();
	ParametersStructure.FieldPriceType = "PriceTypeAccountingPriceType";
	
	If ValueIsFilled(Object.Contract) Then
		PriceKind = Common.ObjectAttributeValue(Object.Contract, ParametersStructure.FieldPriceType);
		If ValueIsFilled(PriceKind) Then
			ParametersStructure.PriceKind = PriceKind;
		EndIf;
	EndIf;
	
	Return ParametersStructure;
	
EndFunction

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

&AtClientAtServerNoContext
Procedure UpdateDependentDetailsOfOrderForm(FormItems, Goods, DiscrepancyOrderText)
	
	NumberOfDiscrepancies = Goods.Total("OrderDiscrepancy_3");
	
	FormItems.GroupDiscrepancyOnOrder.Visible = NumberOfDiscrepancies > 0;
	FormItems.GroupDiscrepancyOnOrders.Visible = NumberOfDiscrepancies > 0;
	
	If NumberOfDiscrepancies > 0 Then
		DiscrepancyOrderText = StrTemplate(NStr("vi = 'Các dòng phía trên đơn hàng: %1';
												|ru = 'Строк сверх заказа: %1';
												|en = 'Lines exceeding the order: %1'; fa = 'Lines exceeding the order: %1';
												|it = 'Righe in eccesso rispetto all''ordine: %1';
												|pl = 'Wierzy przewyższających zamówienie: %1';
												|tr = 'Sipariş fazlası satırı: %1'"), NumberOfDiscrepancies);
	Else
		DiscrepancyOrderText = "";
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInByOrderOnServer()
	
	Object.Goods.Clear();
	
	HeaderAttributes = HeaderAttributes(Object);
	
	If UseReceiptForMultipleOrders Then
		AnArrayOfOrders =
			Documents.ReceiptOfGoodsFromCustodian.WaybillOrders(Object.Ref, HeaderAttributes);
	Else
		AnArrayOfOrders = New Array();
		AnArrayOfOrders.Add(Object.ReferenceOrder);
	EndIf;
	
	FillParameters = Documents.ReceiptOfGoodsFromCustodian.DocumentFillingParameters();
	FillParameters.AddSeriesOnRequest = True;
	
	Documents.ReceiptOfGoodsFromCustodian.InitializeFillingParameters(
		FillParameters,
		HeaderAttributes,
		AnArrayOfOrders);
	
	InvoiceTable = Object.Goods.Unload();
	
	Documents.ReceiptOfGoodsFromCustodian.FillInByOrdersOrders(
		InvoiceTable, Object.Ref, FillParameters);
	
	TableOverheadColumnQuantity     = InvoiceTable.Columns.Count; // ValueTableColumn
	TableOverheadColumnQuantity.Name = "QuantityBeforeChange_";
	
	InvoiceTableColumnsQuantityInOrder     = InvoiceTable.Columns.QuantityInOrder; // ValueTableColumn
	InvoiceTableColumnsQuantityInOrder.Name = "Count";
	
	InvoicesServer.DeleteEmptyLines(InvoiceTable, "Count");
	
	Object.Goods.Load(InvoiceTable);
	
	Documents.ReceiptOfGoodsFromCustodian.UpdateDependentDetailsOfTablePart(Object, FillParameters);
	
	Handler = Documents.ReceiptOfGoodsFromCustodian.ActionHandler(Object.BusinessOperation);
	Handler.FillInShopPantryAttributeInTable(Object);
	FillInDiscrepancyAttributeOrder(Object.Goods, Object.ByReferences, UseLineCode);
	
	FillInServiceDetailsForProductRange();
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, Object.ReusablePackageReturn);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	CalculationParameters =
		AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(Object, "Contract");
	AccountingForTraceableGoodsLocalization.FillInQuantityByRNPTVOfTablePart(CalculationParameters, Object.Goods);
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
	
EndProcedure

&AtServer
Procedure LinkRowsToOrders(SelectByOrder_)
	
	Documents.ReceiptOfGoodsFromCustodian.LinkRowsToOrders(ThisObject, Object, SeriesSpecificationParameters, SelectByOrder_);
	OrdersServer.FillInOrderInOrderHeaderInTableSection(Object.ReferenceOrder, Object.Goods, "ReferenceOrder");
	
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
		
		If UntieOnlyStrings Then
			TableRow.OrderDiscrepancy_3 = 1;
		Else
			TableRow.ReferenceOrder = Undefined;
			TableRow.OrderDiscrepancy_3 = 0;
		EndIf;
		
		// Reassign the series lines
		ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(
			Object,
			SeriesSpecificationParameters,
			CurRow,
			CachedValues);
		
	EndDo;
	
EndProcedure

&AtServerNoContext
Procedure FillInDiscrepancyAttributeOrder(Goods, ByReferences, UseLineCode)
	
	If UseLineCode Then
		StructureOfActions = New Structure;
		OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, ByReferences);
		BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions, Undefined);
	Else
		For Each CurrentData In Goods Do
			CurrentData.OrderDiscrepancy_3 = 0;
		EndDo;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function HeaderAttributes(Object)
	
	HeaderAttributes =
		New Structure(
				"Ref, BusinessOperation, Organization, Warehouse, Partner, Counterparty, Contract, Terms,
				|SalesOpportunity, Currency, LineOfBusiness, ToReturnReusablePackage");
	
	FillPropertyValues(HeaderAttributes, Object);
	HeaderAttributes.ToReturnReusablePackage = Object.ReusablePackageReturn;
	
	Return HeaderAttributes;
	
EndFunction

&AtServer
Procedure FillInPriceTypes()
	
	SelectionParametersPriceType = New Array;
	SelectionParametersPriceType.Add(New ChoiceParameter("OutputAnArbitraryTypeOfPrices", True));
	SelectionParametersPriceType.Add(New ChoiceParameter("Filter.Status",               Enums.StatusesOfPriceTypeValidity.Valid));
	SelectionParametersPriceType.Add(New ChoiceParameter("Filter.IsFolder",            False));
	SelectionParametersPriceType.Add(New ChoiceParameter("Filter.DeletionMark",      False));
	SelectionParametersPriceType.Add(New ChoiceParameter("Filter.PriceCurrency",           Object.Currency));
	If Object.BusinessOperation = Enums.BusinessTransactions.ReceiptFromToller2_5
			Or Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromProcessingCompany2_5 Then
		SelectionParametersPriceType.Add(New ChoiceParameter("UseForIssuingProductsWorksAndServicesAtFixedCost", True));
		If Not ReadOnly
				And ValueIsFilled(Object.PriceKind)
				And Not Common.ObjectAttributeValue(Object.PriceKind, "UseForIssuingProductsWorksAndServicesAtFixedCost") Then
			Object.PriceKind = Catalogs.TypesOfPrices.EmptyRef();
		EndIf;
	Else
		SelectionParametersPriceType.Add(New ChoiceParameter("UseWhileSellingToCustomers", True));
		If Not ReadOnly
				And ValueIsFilled(Object.PriceKind)
				And Not Common.ObjectAttributeValue(Object.PriceKind, "UseWhileSellingToCustomers") Then
			Object.PriceKind = Catalogs.TypesOfPrices.EmptyRef();
		EndIf;
	EndIf;
	Items.PriceKind.ChoiceParameters = New FixedArray(SelectionParametersPriceType);
	
	If Not ReadOnly
			And ValueIsFilled(Object.PriceKind)
			And Common.ObjectAttributeValue(Object.PriceKind, "PriceCurrency") <> Object.Currency Then
		Object.PriceKind = Catalogs.TypesOfPrices.EmptyRef();
	EndIf;
	
EndProcedure

&AtClient
Procedure NotifyAboutEndOfUnbindingLines(NumberOfLinesWorked)

	NotificationText1 = NStr("vi = 'Trong chứng từ đã bỏ liên kết các dòng (%%Count%%) khỏi đơn hàng.';
							|ru = 'В документе от заказов отвязано строк (%%Count%%).';
							|en = 'In the document, the lines (%%Count%%) are detached from the orders.'; fa = 'In the document, the lines (%%Count%%) are detached from the orders.';
							|it = 'Righe dissociate (%%Count%%) dagli ordini nel documento.';
							|pl = 'W dokumencie odłączyć od zamówienia (%%Count%%) wierszy.';
							|tr = 'Belgede siparişlerden ayrılmış satırlar (%Count%) vardır.'");
	NotificationText1 = StrReplace(NotificationText1, "%%Count%%", NumberOfLinesWorked);
	ShowUserNotification(
		NStr("vi = 'Các dòng đã bỏ liên kết';
			|ru = 'Строки отвязаны';
			|en = 'Lines were unlinked'; fa = 'Lines were unlinked';
			|it = 'Righe dissociate';
			|pl = 'Wierze odłączone';
			|tr = 'Ayrılmış satırlar'"),,
		NotificationText1,
		PictureLib.Information32);
	
EndProcedure

&AtClientAtServerNoContext
Function SelectionByProductMultiTurnContainer(BusinessOperation)
	
	IncludeSets = True;
	If BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReceiptFromToller2_5") Then
		IncludeSets = False;
	EndIf;
	Return ProductsClientServer.SelectionByProductMultiTurnContainer(IncludeSets);
	
EndFunction

&AtServer
Function ApplicationsAreUsedAsInvoices()
	
	FoundationOrders = Object.Goods.Unload(, "ReferenceOrder").UnloadColumn("ReferenceOrder");
	FoundationOrders.Add(Object.ReferenceOrder);
	
	Query = New Query;
	Query.SetParameter("FoundationOrders", FoundationOrders);
	Query.Text =
	"SELECT DISTINCT
	|	DocumentsTable.ThisIsOrderAsInvoice AS ThisIsOrderAsInvoice
	|INTO TableOfOrderDetails
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer AS DocumentsTable
	|WHERE
	|	DocumentsTable.Ref IN (&FoundationOrders)
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
