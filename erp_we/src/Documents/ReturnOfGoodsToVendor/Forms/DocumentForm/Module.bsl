#Region Variables

//used to unlink the receipt line from the order line
&AtClient
Var PreviousRowDetails; 

//used by the mechanism for processing changes in PM details
&AtClient
Var CachedValues;

//used to pass the current line to the wait handler
&AtClient
Var CurDataId; 

&AtClient
Var CounterpartyVerificationWaitHandlerParameters Export;

&AtClient
Var TimeConsumingOperationForm Export;

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
	
	DocumentCorrection.OnCreateAtServer(ThisForm, Items.LineCorrection);

	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
		
	EndIf;
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.GroupInTotal.BackColor = New Color();
	EndIf;
	
	SetAvailabilityOfClipboardCommands();
	
	UpdateAvailabilityOfReturnContainerItems();
	
	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisForm);
	
	PurchasesServer.SetModeForSelectingGroupsOfWarehouseItems(Items.Warehouse);
	
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	Items.EPDStateGroup.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisForm);
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations

	// Standard subsystems.Accounting of the originals of the first documents
	SourceDocumentsOriginalsRecording.OnCreateAtServerDocumentForm(ThisObject);
	// The end of the standard subsystem.Accounting of the originals of the first documents 
	
	

	VATAccountingERP.SetVisibilityOfCommandAndFillInVATRate(ThisObject);

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)

	If ChoiceSource.FormName = "DataProcessor.SelectGoodsToPurchaseDocument.Form.Form" Then
		
		ProcessingSelectionOfSelectionOnServer(ValueSelected);
		RecalculateAmountsInPaymentDecryptionLine();
		CalculateReturnTotals(ThisForm);
		
	ElsIf ChoiceSource.FormName = "CommonForm.SelectGoodsByReceipts" Then
		
		ProcessingSelectionSelectionOnReceiptServer(ValueSelected);
		RecalculateAmountsInPaymentDecryptionLine();
		CalculateReturnTotals(ThisForm);
		UpdateInformationOnReceipts();
		
	ElsIf VATAccountingERPClient.FinishedEditingInvoiceIssued(ValueSelected, ChoiceSource) Then
		
		UpdateTextDocumentsBasedOn();
		
	ElsIf VATAccountingERPClient.FinishedEditingInvoiceReceived(ValueSelected, ChoiceSource) Then
		
		UpdateTextDocumentsBasedOn();
		
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectReusablePackage.Form.Form" Then
		
		FillMultiTurnContainersFromStorageServer(ValueSelected.AddressOfReusableContainerInStorage);
		RecalculateAmountsInPaymentDecryptionLine();
		CalculateReturnTotals(ThisForm);
		ReusablePackageClient.NotifyUserAboutFillingMultiTurnContainers();
		
	ElsIf ChoiceSource.FormName = "Catalog.InventoryKinds.Form.InventoryOwnerAttributesForm" Then	
		
		GetStockTypesFromStorage(ValueSelected);
		
	ElsIf ChoiceSource.FormName = "CommonForm.PrintingDetailsOfSales" Then
		
		If ValueSelected <> Undefined Then
			Modified = True;
			FillPropertyValues(Object, ValueSelected);
			UpdateTextDocumentsBasedOn();
		EndIf;
		
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);
				
	EndIf;
	
	If Window <> Undefined Then
		Window.Activate();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	ARAPAccountingFormWork.FormWhenReadingOnServer(ThisForm);
	
	DocumentCorrection.OnReadAtServer(ThisForm, Items.LineCorrection);
	
	OnReadCreateAtServer();
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	FillInServiceDetailsForProductRange();
		
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, Object.ReturnOfReceivedReusablePackages);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateReturnTotals(ThisForm);
	
	ARAPAccountingFormWork.FormAfterRecordingOnServer(ThisForm, CurrentObject.AdditionalProperties);
	CalculateReturnTotals(ThisForm);
	

	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
	If NotExecuteCheck1BeforeWrite Then
		NotExecuteCheck1BeforeWrite = False;
		Return;
	EndIf;
	
	If WriteParameters.WriteMode = DocumentWriteMode.Posting
		And Object.Goods.Count() > 0
		And (Object.ReusablePackageFillingStatus = PredefinedValue("Enum.ReusablePackageFillingStates.OfferToFillIn")
			Or Not ValueIsFilled(Object.ReusablePackageFillingStatus)) Then
		
		AdditionalParameters = New Structure;
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
			
		Else
			
			FillInDocumentsOfAdmissionOfVHF();
			
		EndIf;
		
	EndIf;
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters, Cancel);
	
EndProcedure

&AtClient
Procedure BeforeRecordingOfferToPickUpMultiTurnContainer(Result, AdditionalParameters) Export
	
	FillInDocumentsOfAdmissionOfVHF();
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, AdditionalParameters.WriteParameters,,True);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	PreviousRowDetails = New Structure("Products");
	
	
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// The end of the standard subsystem.Pluggable commands
	// Standard subsystems.Worksfiles
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
	EnableWaitingHandlerReceivingCarriers();
	
EndProcedure

&AtClient
Procedure OnClose()
	
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
	
	If EventName = "Write_TermsOfPurchaseFromVendors" Then
		
		SetAvailabilityAgreements();
		
	EndIf;
	
	If EventName = "Write_InvoiceIssued"
		And ((Parameter.Property("OwnerForm") And Parameter.OwnerForm = UUID)
			Or Parameter.Property("ListOfGrounds") And Parameter.ListOfGrounds.FindByValue(Object.Ref) <> Undefined) Then
		UpdateTextDocumentsBasedOn();
	EndIf;
	
	If EventName = "CopyingLinesToClipboard" Then
		
		SetAvailabilityOfClipboardCommandsOnClient();
		
	EndIf;
	
	
	
	DocumentCorrectionClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);

	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
	NotificationProcessingLocalization(EventName, Parameter, Source);
	
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

	FormEventsClient.URLProcessing(ThisObject, FormattedStringURL, StandardProcessing);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
		
	Notify("Write_ReturnOfGoodsToVendor", WriteParameters, Object.Ref);
	ARAPAccountingClient.FormAfterRecording(ThisForm);

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisForm, Object, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	FormEventsClient.AfterWrite(ThisObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	
EndProcedure

&AtClient
Procedure TermsStartChoice(Item, ChoiceData, StandardProcessing)
	
	PurchasesClient.StartSelectingSupplierAgreement(
		Item,
		StandardProcessing,
		Object.Partner,
		Object.Terms,
		Object.Date);

EndProcedure

&AtClient
Procedure ContractCreating(Item, StandardProcessing)
	
	PurchasesClient.OpenContractCreationForm(ThisObject, Item, "Object.Contract", Object.Partner, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	BasisChanged = BasisChanged And ValueIsFilled(Object.Basis);
	ContractOnChangeServer();
	
EndProcedure

&AtServer
Procedure BusinessOperationOnChangeServer()
	
	ContractBusinessTransaction = GetBusinessTransaction(Object.BusinessOperation);
	
	FillInDefaultContract();
	
	FillInVATTaxationPurchases();
	VATTaxationOnChangeServer();
	
	UpdateTextDocumentsBasedOn();
	
	If Object.BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsToConsignor Then
		Object.DepositForPackageIsRequired = False;
		ReturnOfReceivedReusablePackagesOnChangeServer();
	EndIf;
	UpdateAvailabilityOfReturnContainerItems();
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisForm);
	
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	BusinessOperationOnChangeServer();
	RecalculateAmountsInPaymentDecryptionLine();
	CalculateReturnTotals(ThisForm);
	
	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	If Not ValueIsFilled (Object.Partner) Then
		PartnerClearingServer();
		GoodsDeliveryClientServer.ClearDeliveryDetails(Items,Object);
		Return;
	EndIf;
	
	PartnerOnChangeServer();
	RecalculateAmountsInPaymentDecryptionLine();
	CalculateReturnTotals(ThisForm);
	
	If ValueIsFilled(Object.Terms) Then
		PurchasesClient.NotifyEndOfFillingInDefaultPurchaseConditions();
	EndIf;
	
	
EndProcedure

&AtClient
Procedure TermsOnChange(Item)
	
	Terms = Object.Terms;
	
	TermsOnChangeServer();
	
	If Not ValueIsFilled(Object.Terms) Then
		Return;
	EndIf;
	
	RecalculateAmountsInPaymentDecryptionLine();
	CalculateReturnTotals(ThisForm);
	PurchasesClient.NotifyEndOfFillingInTermsOfPurchase();

EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyOnChangeServer();
	
	
EndProcedure

&AtClient
Procedure VATTaxationOnChange(Item)
	
	VATTaxationOnChangeServer();
	RecalculateAmountsInPaymentDecryptionLine();
	CalculateReturnTotals(ThisForm);
	
EndProcedure

&AtClient
Procedure PriceIncludesVATOnChange(Item)
	
	PriceIncludesVATOnChangeServer(CachedValues);
	RecalculateAmountsInPaymentDecryptionLine();
	CalculateReturnTotals(ThisForm);
	
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	
	If ValueIsFilled(Object.Currency) Then
		
		CurrencyOnChangeServer(
			Object.Currency,
			PriceManagementSystemClient.CurrencyConversionRequired(Object, DocumentCurrency));
		PriceManagementSystemClient.NotifyAboutEndOfConversionOfAmountsIntoCurrency(DocumentCurrency, Object.Currency);
		
	EndIf;
	
	DocumentCurrency = Object.Currency;
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	WarehouseOnChangeServer();
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOnChangeServer();
	

EndProcedure

&AtClient
Procedure CaptionRevenueHeaderClick(Item, StandardProcessing)
	StandardProcessing = False;
	
	OpenForm(
		"CommonForm.ViewingListOfDocuments",
		New Structure("DocumentsList, Title",
			ReceiptsList,
			NStr("vi = 'Mua từ đối tác (%DocumentsCount%)';
				|ru = 'Приобретения от партнеров (%DocumentsCount%)';
				|en = 'Purchases from partners (%DocumentsCount%)'; fa = 'Purchases from partners (%DocumentsCount%)';
				|it = 'Acquisti dai partner (%DocumentsCount%)';
				|pl = 'Nabycia od partnerów (%DocumentsCount%)';
				|tr = 'İş ortağından satın alım (%DocumentsCount%)'")
		),
		ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure ReturnOfReceivedReusablePackagesOnChange(Item)
	
	ReturnOfReceivedReusablePackagesOnChangeServer();
	RecalculateAmountsInPaymentDecryptionLine();
	CalculateReturnTotals(ThisForm);
	
EndProcedure

&AtClient
Procedure ReducedDebtByLineClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.CheckForPromiscuity = False;
	CheckParameters.CheckedAttributes.Insert("Organization",           NStr("vi = 'Doanh nghiệp';
																			|ru = 'Организация';
																			|en = 'Company'; fa = 'Company';
																			|it = 'Azienda';
																			|pl = 'Firma';
																			|tr = 'İş yeri'"));
	CheckParameters.CheckedAttributes.Insert("Partner",               NStr("vi = 'Nhà cung cấp';
																			|ru = 'Поставщик';
																			|en = 'Vendor'; fa = 'تأمین‌کننده';
																			|it = 'Fornitore';
																			|pl = 'Dostawca';
																			|tr = 'Tedarikçi'"));
	CheckParameters.CheckedAttributes.Insert("Counterparty",            NStr("vi = 'Đối tác';
																			|ru = 'Контрагент';
																			|en = 'Counterparty'; fa = 'طرف حساب';
																			|it = 'Controparte';
																			|pl = 'Kontrahent';
																			|tr = 'Cari hesap'"));
	CheckParameters.CheckedAttributes.Insert("Currency",                NStr("vi = 'Tiền tệ';
																			|ru = 'Валюта';
																			|en = 'Currency'; fa = 'ارز';
																			|it = 'Valuta';
																			|pl = 'Waluta';
																			|tr = 'Para birimi'"));
	CheckParameters.CheckedAttributes.Insert("BusinessOperation", NStr("vi = 'Giao dịch';
																		|ru = 'Операция';
																		|en = 'Transaction'; fa = 'تراکنش';
																		|it = 'Operazione';
																		|pl = 'Operacja';
																		|tr = 'İşlem'"));
	Notification = New CallbackDescription("ReducedDebtByClickingAfterVerification", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);

EndProcedure

&AtClient
Procedure ReducedDebtByLineClickCompletion(AddressOfPaymentsInTheStorage, AdditionalParameters) Export
	
	If AddressOfPaymentsInTheStorage <> Undefined Then
		Modified = True;
		GetPaymentDecryptionFromVault(AddressOfPaymentsInTheStorage);
		CalculateReturnTotals(ThisForm);
	EndIf;
	
EndProcedure

&AtClient
Procedure DepositForPackageIsRequiredOnChange(Item)
	
	RecalculateAmountsInPaymentDecryptionLine();
	CalculateReturnTotals(ThisForm);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	
	ARAPAccountingServer.BeforeWriteAtServer(ThisForm, CurrentObject);
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure LineOfBusinessOnChange(Item)
	
	DirectionOfActivityWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure DeliveryAddressOnChange(Item)
	
	ProcessAddressChange(Item, "DeliveryAddress");
	
EndProcedure

&AtClient
Procedure DeliveryAddressOfCarrierOnChange(Item)
	
	ProcessAddressChange(Item, "DeliveryAddressOfCarrier");
	
EndProcedure

&AtClient
Procedure DeliveryAddressClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	NamesOfDetailsOfDeliveryAddresses = GoodsDeliveryClientServer.NamesOfDetailsOfDeliveryAddresses("DeliveryAddress");
	
	GoodsDeliveryClient.ClearAddressPresentation(
		Object[NamesOfDetailsOfDeliveryAddresses.NameOfDetailsOfDeliveryAddress],
		Object[NamesOfDetailsOfDeliveryAddresses.AttributeNameOfDeliveryAddressFieldValues]);
	
EndProcedure

&AtClient
Procedure DeliveryAddressOfCarrierClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	NamesOfDetailsOfDeliveryAddresses = GoodsDeliveryClientServer.NamesOfDetailsOfDeliveryAddresses("DeliveryAddressOfCarrier");
	
	GoodsDeliveryClient.ClearAddressPresentation(
		Object[NamesOfDetailsOfDeliveryAddresses.NameOfDetailsOfDeliveryAddress],
		Object[NamesOfDetailsOfDeliveryAddresses.AttributeNameOfDeliveryAddressFieldValues]);
	
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
Procedure DeliveryAddressOfCarrierStartChoice(Item, ChoiceData, StandardProcessing)
	
	NamesOfDetailsOfDeliveryAddresses = GoodsDeliveryClientServer.NamesOfDetailsOfDeliveryAddresses("DeliveryAddressOfCarrier");
	
	GoodsDeliveryClient.OpenAddressSelectionFormAndProcessResult(
		Item,
		Object, 
		NamesOfDetailsOfDeliveryAddresses,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure DeliveryAddressChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	NamesOfDetailsOfDeliveryAddresses = GoodsDeliveryClientServer.NamesOfDetailsOfDeliveryAddresses("DeliveryAddress");

	GoodsDeliveryClient.WhenChangingAddressPresentation(
		Item,
		Object[NamesOfDetailsOfDeliveryAddresses.NameOfDetailsOfDeliveryAddress],
		Object[NamesOfDetailsOfDeliveryAddresses.NameOfAttributeOfDeliveryAddressValue]);
	
	GoodsDeliveryClient.DeliveryAddressChoiceProcessing(Items, Object, Item.Name, ValueSelected);
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure DeliveryAddressOfCarrierChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	NamesOfDetailsOfDeliveryAddresses = GoodsDeliveryClientServer.NamesOfDetailsOfDeliveryAddresses("DeliveryAddressOfCarrier");

	GoodsDeliveryClient.WhenChangingAddressPresentation(
		Item,
		Object[NamesOfDetailsOfDeliveryAddresses.NameOfDetailsOfDeliveryAddress],
		Object[NamesOfDetailsOfDeliveryAddresses.NameOfAttributeOfDeliveryAddressValue]);
	
	GoodsDeliveryClient.DeliveryAddressChoiceProcessing(Items, Object, Item.Name, ValueSelected);
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
EndProcedure

&AtClient
Procedure TextDocumentsBasedOnURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	ClearMessages();
	
	RegistrationParameters = InvoiceRegistrationParameters();                                                            
	VATAccountingERPClient.ProcessingNavigationLinkInvoicesIssued(ThisForm, FormattedStringURL,  StandardProcessing, RegistrationParameters.Issued);
	VATAccountingERPClient.ProcessingNavigationLinkInvoicesReceived(ThisForm, FormattedStringURL,  StandardProcessing, RegistrationParameters.Received);
	
	TextDocumentsBasedOnURLProcessingLocalization(FormattedStringURL, StandardProcessing);
	
EndProcedure
// The end of Integrationegais

&AtClient
Procedure CompensationMethodOnChange(Item)
	CompensationMethodOnChangeServer();
EndProcedure

&AtClient
Procedure Attachable_OriginalStateDecorationClick()

	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecordingClient.OpenStateSelectionMenu(ThisForm,Items.OriginalStateDecoration);
	//End StandardSubsystems.SourceDocumentsOriginalsRecording

EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(
		ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DecorationOfEPDClick(Item)
	
	
EndProcedure

&AtClient
Procedure DecorationToIssueEPDClick(Item, StandardProcessing)
	
	
EndProcedure

&AtClient
Procedure ForeignCurrencyTransactionOnChange(Item)
	PaymentInCurrencyOnChangeAtServer();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(
				Item,CachedValues,SeriesSpecificationParameters);
	
EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	
	RecalculateAmountsInPaymentDecryptionLine();
	CalculateReturnTotals(ThisForm);
	
	If ProductsClient.SeriesStatusesNeedToBeUpdated(
		Item,CachedValues,SeriesSpecificationParameters,True) Then
		
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Undefined, CachedValues);
		ProductsClient.UpdateCachedValuesToAccountForSeries(
					Item,CachedValues,SeriesSpecificationParameters);
		
	EndIf;
	
	ReusablePackageClient.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
	GoodsAfterDeleteRowServer();
	
EndProcedure

&AtClient
Procedure GoodsBeforeRowChange(Item, Cancel)
	
	FillPropertyValues(PreviousRowDetails, Items.Goods.CurrentData);
	
EndProcedure

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
	ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters, Copy);
	
EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	RecalculateAmountsInPaymentDecryptionLine();
	CalculateReturnTotals(ThisForm);
	
	CurrentData = Items.Goods.CurrentData;
	
	If ProductsClient.SeriesStatusesNeedToBeUpdated(
		Item,CachedValues,SeriesSpecificationParameters) Then
		
		IDCurrentRow = CurrentData.GetID();
		
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues);	
		ProductsClient.UpdateCachedValuesToAccountForSeries(Item,CachedValues,SeriesSpecificationParameters);
		
	EndIf;
	
	If Not CancelEdit Then
		LineCache = ?(NewRow, Undefined, ProcessingOfTabularFormsClientServer.LineCache(Items.Goods, ThisObject));
		WarehousesClient.UpdateWarehouseTable(WarehouseTable, CurrentData, LineCache, WarehouseGroup_, False);
		TotalWarehouses_ = WarehouseTable.Count();
		WarehousesClientServer.UpdateWarehouseGroupImage(SeveralWarehousesText, Items.PictureMultipleWarehouses, TotalWarehouses_);
	EndIf;
	
	ReusablePackageClient.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
	AdditionalParameters = New Structure;
	FormEventsClient.WhenChangingElement(ThisObject, Items.Goods, AdditionalParameters);
	If AdditionalParameters.Property("ServerCallRequired__") Then
		AttachIdleHandler("GoodsAtEndOfEditingForServerCall", 0.5, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	PartnersProductsClient.WhenSelectingPartnerProducts(Object, Field, "GoodsPartnerProducts", NStr("vi = 'Nhà cung cấp';
																									|ru = 'Поставщик';
																									|en = 'Vendor'; fa = 'تأمین‌کننده';
																									|it = 'Fornitore';
																									|pl = 'Vendor';
																									|tr = 'Tedarikçi'"));
	
EndProcedure

&AtClient
Procedure GoodsPartnerProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	PartnersProductsClient.SetPackageSelectionParameters(Item.ChoiceParameters, CurrentRow);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersFillInVATRate.ByDateOfReceipt = True;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInTheItemByThePartnerSItem");
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillWarehouse", 
					BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ReturnOfReceivedReusablePackages);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ReturnOfReceivedReusablePackages);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Products", StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If PreviousRowDetails.Products <> CurrentRow.Products Then
		StructureOfActions = New Structure;
		LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisForm, StructureOfActions);
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	EndIf;
	
	FillPropertyValues(PreviousRowDetails, CurrentRow);
	
EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculatePricePerPackage", CurrentRow.Count);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	RecalculateAmountsInPaymentDecryptionLine();
	
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersFillInVATRate.ByDateOfReceipt = True;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ReturnOfReceivedReusablePackages);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", CurrentRow.Warehouse, SeriesSpecificationParameters));
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ReturnOfReceivedReusablePackages);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	StructureOfActions.Insert("CheckFillWarehouse", 
					BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisForm, StructureOfActions);
	
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Products", StructureOfActions);
	
	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	FillPropertyValues(PreviousRowDetails, CurrentRow);
	RecalculateAmountsInPaymentDecryptionLine();
	
EndProcedure

&AtClient
Procedure GoodsWarehouseOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	CheckSeriesCalculateStatus = New Structure("Warehouse, SeriesSpecificationParameters",
													CurrentRow.Warehouse, SeriesSpecificationParameters);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckSeriesCalculateStatus", CheckSeriesCalculateStatus);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);

	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisForm, StructureOfActions);
	
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	RecalculateAmountsInPaymentDecryptionLine();
	
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisForm);	
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	RecalculateAmountsInPaymentDecryptionLine();
	
EndProcedure

&AtClient
Procedure GoodsPriceOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	RecalculateAmountsInPaymentDecryptionLine();
	
EndProcedure

&AtClient
Procedure GoodsVATRateOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	RecalculateAmountsInPaymentDecryptionLine();
	
EndProcedure

&AtClient
Procedure GoodsSumOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePriceDiscountForAmountInPurchases");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	RecalculateAmountsInPaymentDecryptionLine();
	
EndProcedure

&AtClient
Procedure GoodsDocumentInflowOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;	                   
	IDCurrentRow = ?(CurrentRow <> Undefined, CurrentRow.GetID(), Undefined);
	
	GoodsDocumentInflowOnChangeServer(IDCurrentRow, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsOnActivateCell(Item)
	If Item.CurrentItem = Undefined Then
		Return
	ElsIf Item.CurrentItem.Name = "GoodsPartnerProducts" Then
		
		CurrentData = Items.Goods.CurrentData;
		
		PartnersProductsClient.FillInPartnerProductSelectionList(
			Object.Partner, CurrentData, Items.GoodsPartnerProducts.ChoiceList);
			
		PartnersProductsClient.SetPackageSelectionParameters(
			Items.GoodsPartnerProducts.ChoiceParameters, CurrentData);
		
	EndIf;
EndProcedure

&AtClient
Procedure GoodsPartnerProductsStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentRow = Items.Goods.CurrentData;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("FormItem" , Item);
	AdditionalParameters.Insert("CurrentRow", CurrentRow);
	
	ClosingNotification = New CallbackDescription("ProcessResultOfSelectingPartnerProductName", ThisObject, AdditionalParameters);

	PartnersProductsClient.OpenPartnerProductSelectionForm(ThisObject, Object.Partner, CurrentRow, Item.Title, ClosingNotification);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands


// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
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
Procedure SpecifySeries(Command)
	
	OpenSelectionOfSeries();
	
EndProcedure

&AtServer
Function ParametersOfSeriesIndicationForm(CurDataId)
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(Object, SeriesSpecificationParameters, CurDataId, ThisForm);
	
EndFunction

&AtClient
Procedure OpenInventoryKinds(Command)
	
	OptionsForEditingInventoryTypes = PutGoodsAndStockTypesInStorage();
	
	FinancesClient.OpenInventoryKinds(ThisObject, OptionsForEditingInventoryTypes);
	
EndProcedure

&AtClient
Procedure SelectGoods(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.ReturnOfGoodsToVendor.DocumentForm.Command.SelectGoods");
	
	FormParameters = New Structure;
	FormParameters.Insert("Document",                Object.Ref);
	FormParameters.Insert("Partner",                 Object.Partner);
	FormParameters.Insert("Warehouse",                   Object.Warehouse);
	FormParameters.Insert("Terms",              Object.Terms);
	FormParameters.Insert("PriceIncludesVAT",         Object.PriceIncludesVAT);
	FormParameters.Insert("Currency",                  Object.Currency);
	FormParameters.Insert("Date",                    Object.Date);
	FormParameters.Insert("SelectionModeUseWarehousesInTabularSection", True);
	FormParameters.Insert("FilterByProductType", New FixedArray(ProductsClientServer.SelectionByProductMultiTurnContainer(False)));
	FormParameters.Insert("HideManualDiscounts",    True);
	
	OpenForm("DataProcessor.SelectGoodsToPurchaseDocument.Form", FormParameters, ThisForm, UUID);
	
EndProcedure

&AtClient
Procedure SelectProductsBasedOnReceipts(Command)
	
	SelectGoodsByReceipts();
	
EndProcedure

&AtClient
Procedure SelectGoodsByReceipts()
	
	Cancel = False;
	ClearMessages();
	
	If Not ValueIsFilled(Object.Currency) Then
		CommonClientServer.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Tiền tệ""';
				|ru = 'Поле ""Валюта"" не заполнено';
				|en = '""Currency"" is required'; fa = '""Currency"" is required';
				|it = 'Il campo ""Valuta"" non è compilato';
				|pl = 'Pole ""Waluta"" nie jest wypełnione';
				|tr = '""Para Birimi"" alanı doldurulmadı'"),
			Object.Ref, "Object.Currency",
			,
			Cancel);
	EndIf;
	
	If Not ValueIsFilled(Object.VATTaxation) Then
		CommonClientServer.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Tính thuế GTGT""';
				|ru = 'Поле ""Налогообложение НДС"" не заполнено';
				|en = '""VAT taxation"" is not filled in'; fa = '""VAT taxation"" is not filled in';
				|it = 'Il campo ""Tassazione IVA"" non è compilato';
				|pl = 'Pole ""Opodatkowanie VAT"" nie jest wypełnione';
				|tr = '""KDV vergilendirmesi"" alanı doldurulmamış'"),
			Object.Ref, "Object.VATTaxation",
			,
			Cancel);
	EndIf;
	
	If Not ValueIsFilled(Object.Organization) Then
		CommonClientServer.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Doanh nghiệp""';
				|ru = 'Поле ""Организация"" не заполнено';
				|en = '""Company"" is required'; fa = '""Company"" is required';
				|it = 'Il campo ""Società"" non è compilato';
				|pl = 'Nie wypełniono pola ""Firma""';
				|tr = '""İş yeri"" alanı doldurulmadı'"),
			Object.Ref, "Object.Organization",
			,
			Cancel);
	EndIf;
	
	If Not ValueIsFilled(Object.Partner) Then
		CommonClientServer.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Khách hàng""';
				|ru = 'Поле ""Клиент"" не заполнено';
				|en = '""Customer"" is required'; fa = '""Customer"" is required';
				|it = 'Il campo ""Cliente"" non è compilato';
				|pl = 'Nie wypełniono pole ""Клиент""';
				|tr = '""Müşteri"" alanı doldurulmadı'"),
			Object.Ref, "Object.Partner",
			,
			Cancel);
	EndIf;
	
	If Not ValueIsFilled(Object.Counterparty) And Not UsePartnersAsCounterparties Then
		CommonClientServer.MessageToUser(
			NStr("vi = 'Trường ""Đối tác"" chưa điền';
				|ru = 'Поле ""Контрагент"" не заполнено';
				|en = '""Counterparty"" is not filled in'; fa = '""Counterparty"" is not filled in';
				|it = 'Il campo ""Contraente"" non è compilato';
				|pl = 'Pole ""Kontrahent"" nie jest wypełnione';
				|tr = '""Cari hesap"" alanı doldurulmadı '"),
			Object.Ref, "Object.Counterparty",
			,
			Cancel);
	EndIf;
	
	If Not Cancel Then
		
		PickingParameters = New Structure;
		PickingParameters.Insert("DocumentReturnPolicy", Object.Ref);
		PickingParameters.Insert("Currency", Object.Currency);
		PickingParameters.Insert("Date", ?(ValueIsFilled(Object.Date), Object.Date, CommonClient.SessionDate()));
		PickingParameters.Insert("VATTaxation", Object.VATTaxation);
		PickingParameters.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
		PickingParameters.Insert("Partner", Object.Partner);
		PickingParameters.Insert("Terms", Object.Terms);
		PickingParameters.Insert("Organization", Object.Organization);
		PickingParameters.Insert("Counterparty", Object.Counterparty);
		PickingParameters.Insert("ShowProducts_", True);
		PickingParameters.Insert("ShowContainers", Object.ReturnOfReceivedReusablePackages);
		PickingParameters.Insert("LineOfBusiness", Object.LineOfBusiness);
		
		OpenForm(
			"CommonForm.SelectGoodsByReceipts",
			PickingParameters,
			ThisForm);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowSupplierProducts(Command)
	
	PartnersProductsClient.ShowThePartnerSNomenclature(Object.Partner, Object.Ref, Items.Goods.CurrentData, NStr("vi = 'Nhà cung cấp';
																												|ru = 'Поставщик';
																												|en = 'Vendor'; fa = 'تأمین‌کننده';
																												|it = 'Fornitore';
																												|pl = 'Vendor';
																												|tr = 'Tedarikçi'"));
	
EndProcedure

&AtClient
Procedure RefillByShipment(Command)
	
	If SalesClient.ItIsNecessaryToFillInGoodsOnShipment(Object.Posted) Then
		
		ShipmentStatus = SalesServerCall.GetStateOfActualShipment(Object.Ref);
		
		If ShipmentStatus.ThereAreUnassembledGoods Then
			
			AdditionalParameters = New Structure;
			AdditionalParameters.Insert("ShipmentStatus", ShipmentStatus);
			SalesClient.QuestionAboutReFillingWithShippedGoods(
				New CallbackDescription("QuestionAboutReFillingWithShippedGoodsCompletion", ThisObject, AdditionalParameters),ShipmentStatus.ThereAreShippedGoods);
			
		Else
			
			RefillByShipmentCompletion(ShipmentStatus);
			
		EndIf;
		
	EndIf;
	
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
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisForm);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		
		RecalculateAmountsInPaymentDecryptionLine();
		CalculateReturnTotals(ThisForm);
	Else
		EquipmentManagerTMClient.ReportError(ExecutionResult);
	EndIf;
	
EndProcedure

&AtClient
Procedure SearchByBarcodeExecute(Command)
	
	ClearMessages();
	Notification = New CallbackDescription("SearchByBarcodeCompletion", ThisObject);
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);
	
EndProcedure

&AtClient
Procedure ImportDataFromPDT(Command)

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
Procedure FillInTheItemByThePartnerSItem(Command)
	
	If Not TMCommonUseClient.CheckForRowsInList(Object.Goods, "Goods") Then
		Return;
	EndIf;
	
	FilterItemsType = New Array;
	FilterItemsType.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
	FilterItemsType.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
	
	PurchasesClient.OpenSupplierProductListForm(
		New CallbackDescription("FillInTheItemByThePartnerSItemCompletion", ThisObject),
		PlaceGoodsInTemporaryStorageServer(),
		ThisForm,
		FilterItemsType);
	
EndProcedure

&AtClient
Procedure FillInTheItemByThePartnerSItemCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		
		FillInItemsFromTemporaryStorageServer(Result);
		RecalculateAmountsInPaymentDecryptionLine();
		CalculateReturnTotals(ThisForm);
		
	EndIf;
	
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
Procedure CompleteSeriesOnFEFOCompletion(Result, AdditionalParameters) Export 
	
	If Not Result Then
		Return;
	EndIf;
	
	If Not FillInSeriesByFEFOServer() Then
		ProductsClient.WarnAboutAbsenceOfLinesFilledByFEFO();
	EndIf;

EndProcedure

&AtClient
Procedure FillInTheReceiptsAndPrices(Command)
	FillInReceiptsAndPricesOnServer();
	RecalculateAmountsInPaymentDecryptionLine();
	CalculateReturnTotals(ThisForm);
	UpdateInformationOnReceipts();
EndProcedure

&AtClient
Procedure FillInVATRate(Command)

	If Object.Goods.Count() = 0 Then
		WarningText = NStr("vi = 'Trong danh sách ""Hàng hóa"" chưa điền dòng nào.';
							|ru = 'В список ""Товары"" не введено ни одной строки.';
							|en = 'No lines entered in the Item list.'; fa = 'No lines entered in the Item list.';
							|it = 'В список ""Товары"" не введено ни одной строки.';
							|pl = 'Do listy ""Wiersze pozycji"" nie wprowadzono żadnego wiersza.';
							|tr = '""Ürünler"" listesine hiçbir satır girilmemiştir.'");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;

	ClosingNotification1 = New CallbackDescription("FillInVATRateCompletion", ThisObject);
	FormParameters = New Structure();
	FormParameters.Insert("VATTaxationType", Object.VATTaxation);
	OpenForm("Catalog.VATRates.ChoiceForm", FormParameters,,,,, ClosingNotification1);

EndProcedure

&AtClient
Procedure InsertRows(Command)
	
	NumberOfProductsBeforeInsertion = Object.Goods.Count();
	
	GetLinesFromClipboard();
	
	RecalculateAmountsInPaymentDecryptionLine();
	CalculateReturnTotals(ThisForm);
	
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
		"Products,Characteristic,Count,Warehouse");
	
EndProcedure

&AtClient
Procedure ImportFromExternalFile(Command)
	
	ImportParameters = ProcessingOfTabularFormsClient.ProductLoadingParameters();
	ImportParameters.Organization = Object.Organization;
	ImportParameters.FillInThePartnerSNomenclature = Object.Partner;
	ImportParameters.ImportPrices = True;
	ImportParameters.PriceIncludesVAT    = Object.PriceIncludesVAT;
	ImportParameters.VATTaxation = Object.VATTaxation;
	ImportParameters.FillingDate     = Object.Date;
	ImportParameters.ThisIsReusablePackage  = Object.ReturnOfReceivedReusablePackages;
	ImportParameters.FilterParameters.Insert("ItemsType",
		ProductsClientServer.SelectionByProductMultiTurnContainer(False));
	
	Notification = New CallbackDescription("ImportFromExternalFileCompletion", ThisObject);
	ProcessingOfTabularFormsClient.ShowProductUploadForm(ImportParameters, Notification);
	
EndProcedure

&AtClient
Procedure PrintDetails(Item)
	
	OpenPrintDetails();
	
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



&AtClient
Procedure ImportFromExternalFileCompletion(ImportedDataAddress, AdditionalParameters) Export
	
	If ValueIsFilled(ImportedDataAddress) Then
		GetUploadedProductsFromStorage(ImportedDataAddress);
		RecalculateAmountsInPaymentDecryptionLine();
		CalculateReturnTotals(ThisForm);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Function WarehouseSelectionData(Warehouse)

	Query = New Query(
	"SELECT ALLOWED
	|	Warehouses.Ref AS Ref
	|FROM
	|	Catalog.Warehouses AS Warehouses
	|WHERE
	|	Warehouses.Ref IN HIERARCHY(&GroupOfWarehouses)
	|	AND Warehouses.IsFolder = FALSE
	|	AND Warehouses.SelectGroup <> VALUE(Enum.SelectWarehouseGroup.Disable)");

	Query.SetParameter("GroupOfWarehouses", Warehouse);
	WarehouseArray = Query.Execute().Unload().UnloadColumn("Ref");
	Return WarehouseArray;

EndFunction

&AtServer
Procedure SetParametersForSelectingProductsWarehouse()
	
	Items.GoodsWarehouse.ChoiceParameters = New FixedArray(New Array);
	
	WarehouseSelectionData = WarehouseSelectionData(Object.Warehouse);
	
	TMCommonUseClientServer.AddSelectionParameter(Items.GoodsWarehouse, "Ref", WarehouseSelectionData);

EndProcedure

&AtServer
Procedure WhenChangingWarehouseInTablePartServer()
	
	WarehousesServer.WhenChangingWarehouseInTablePart(Object.Goods, WarehouseTable, WarehouseGroup_, False);
	TotalWarehouses_ = WarehouseTable.Count();
	WarehousesClientServer.UpdateWarehouseGroupImage(SeveralWarehousesText, Items.PictureMultipleWarehouses, TotalWarehouses_);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//
	
	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForSalesTaxation(ThisForm);
	
	//

	EnterprisePricesFillingServer.SetConditionalAppearancePriceIncludesVAT(ThisForm);

	//

	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPartnerProducts.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Partner");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<hãy chọn nhà cung cấp>';
													|ru = '<выберите поставщика>';
													|en = '<select vendor>'; fa = '<select vendor>';
													|it = '<selezionare il fornitore>';
													|pl = '<wybierz dostawcę>';
													|tr = '<tedarikçi seçin>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsVATAmount.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAmountIncludingVAT.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.ReturnOfGoodsToConsignor;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPrice.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Price");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.BusinessTransactions.ReturnOfGoodsToConsignor;
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ItemsTypes.ReusablePackage;

	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.ReusablePackage;

	FilterGroup3 = FilterGroup2.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup3.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReturnOfReceivedReusablePackages");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DepositForPackageIsRequired");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSum.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Sum");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.BusinessTransactions.ReturnOfGoodsToConsignor;

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ItemsTypes.ReusablePackage;

	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.ReusablePackage;

	FilterGroup3 = FilterGroup2.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup3.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReturnOfReceivedReusablePackages");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DepositForPackageIsRequired");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	////////////////////////////////////////////////////////////////////
	
	
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Contract.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Terms");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Contract");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Contract.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Terms");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Contract");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsVATRate.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.ReusablePackage;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReturnOfReceivedReusablePackages");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisForm, "SeriesWhenPlanningShipmentWHGoodsAreIndicated");

	//

	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisForm, False);

	//
	
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisForm);
	
	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisForm);
	
	//WarehouseGroup_

	WarehousesServer.SetConditionalAppearanceOfVTCHWarehouse(ThisForm);
	
	//Products.Warehouse - mark empty

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsWarehouse.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	ValueList.Add(Enums.ItemsTypes.ReusablePackage);
	ItemFilter.RightValue = ValueList;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Warehouse");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
		
EndProcedure

#Region OnChangeAttributes

&AtClient
Procedure GoodsAtEndOfEditingForServerCall()

	GoodsAtEndOfEditingOnServer();

EndProcedure

&AtServer
Procedure GoodsAtEndOfEditingOnServer()

	FormEvents.WhenChangingElement(ThisObject, "Goods");

EndProcedure

&AtServer
Procedure GoodsDocumentInflowOnChangeServer(IDCurrentRow, CachedValues)
	
	If IDCurrentRow <> Undefined Then
		
		CurrentRow = Object.Goods.FindByID(IDCurrentRow);
		
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
		ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
		ParametersFillInVATRate.ByDateOfReceipt = True;
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
		StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ReturnOfReceivedReusablePackages);
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmount");
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		BatchProcessingOfTablePartServer.ProcessTSString(CurrentRow, StructureOfActions, Undefined);
		
	EndIf;
	
	UpdateInformationOnReceipts();
	
EndProcedure

&AtServer
Procedure PartnerOnChangeServer()
	
	OldCurrency = DocumentCurrency;
	
	DocumentPurchases = FormAttributeToValue("Object");
	DocumentPurchases.FillInDefaultPurchaseConditions();
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, DocumentPurchases);
	ResponsiblePersonsServer.InstallManager(
		DocumentPurchases, SalesServer.DocumentBasis(DocumentPurchases, "DocumentInflow, Goods.DocumentInflow"));
	ValueToFormAttribute(DocumentPurchases, "Object");
	
	SetAvailabilityAgreements();
	Terms = Object.Terms;	
	
	WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWTCProcurementDocuments(Object.Warehouse);
	WarehouseOnChangeServer();
	
	If ValueIsFilled(Object.Terms) Then
			
		If Object.BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsToConsignor Then
			Object.ReturnOfReceivedReusablePackages = False;
			Object.DepositForPackageIsRequired = False;
		EndIf;
		UpdateAvailabilityOfReturnContainerItems();
		
		DocumentCurrency = Object.Currency;
		
		ContractBusinessTransaction = GetBusinessTransaction(Object.BusinessOperation);
		
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
		ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
		ParametersFillInVATRate.ByDateOfReceipt = True;
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
		StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
		StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
		StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ReturnOfReceivedReusablePackages);
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ReturnOfReceivedReusablePackages);
		StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
		
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
		
		ExecuteRecalculateDocumentAmountsServer(OldCurrency, DocumentCurrency);
		SetCurPageOfBasementSums();
		
	EndIf;
	
	PartnersProductsServer.FillInPartnerProductListByProductNameWhenPartnerChanges(Object.Goods, Object.Partner);
	FillInServiceDetailsForProductRange();

	WarehouseOnChangeServer();
	
	UpdateTextDocumentsBasedOn();
	
	FillBaseForPrinting();
	PurchasesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible, Object.Contract);
	
	MethodPlaceOfDeliveryCarrierIfChangedServer("Partner");
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	UpdateInformationOnReceipts();
	SalesServer.PartnerOnChange(Object);
	
	FillInSubordinatePropertiesForStatistics("Counterparty");
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	
	AttributesArray = New Array;
	AttributesArray.Add("Currency");
	AttributesArray.Add("Partner");
	AttributesArray.Add("Contract");
	AttributesArray.Add("LineOfBusiness");
	AttributesArray.Add("Counterparty");
	AttributesArray.Add("Organization");
	AttributesArray.Add("Terms");
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, AttributesArray);
	
EndProcedure

&AtServer
Procedure PartnerClearingServer()
	
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	ResponsiblePersonsServer.InstallManager(
		Object, PurchasesServer.DocumentBasis(Object, "DocumentInflow, Goods.DocumentInflow"));
	
EndProcedure


&AtServer
Procedure TermsOnChangeServer()
	
	PurchasesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible, Object.Contract);
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	
	If Not ValueIsFilled(Object.Terms) Then
		ResponsiblePersonsServer.InstallManager(
			Object, PurchasesServer.DocumentBasis(Object, "DocumentInflow, Goods.DocumentInflow"));
		Return;
	EndIf;
	
	OldCurrency = DocumentCurrency;
	DocumentPurchases = FormAttributeToValue("Object");
	DocumentPurchases.FillInTermsOfPurchaseUnderAgreement();
	ResponsiblePersonsServer.InstallManager(
		DocumentPurchases, PurchasesServer.DocumentBasis(DocumentPurchases, "DocumentInflow, Goods.DocumentInflow"));
	ValueToFormAttribute(DocumentPurchases, "Object");
	
	FillInSubordinatePropertiesForStatistics("Contract");
	
	If Object.BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsToConsignor Then
		Object.ReturnOfReceivedReusablePackages = False;
		Object.DepositForPackageIsRequired = False;
	EndIf;
	UpdateAvailabilityOfReturnContainerItems();
	
	DocumentCurrency = Object.Currency;
	
	ContractBusinessTransaction = GetBusinessTransaction(Object.BusinessOperation);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersFillInVATRate.ByDateOfReceipt = True;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ReturnOfReceivedReusablePackages);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ReturnOfReceivedReusablePackages);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
	ExecuteRecalculateDocumentAmountsServer(OldCurrency, DocumentCurrency);
	SetCurPageOfBasementSums();
	FillInServiceDetailsForProductRange();

	WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWTCProcurementDocuments(Object.Warehouse);
	WarehouseOnChangeServer();
	
	UpdateTextDocumentsBasedOn();
	
	FillBaseForPrinting();
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, Object.ReturnOfReceivedReusablePackages);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateReturnTotals(ThisForm);
	
	FillOperationSelectionList();
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	
	AttributesArray = New Array;
	AttributesArray.Add("Currency");
	AttributesArray.Add("Partner");
	AttributesArray.Add("LineOfBusiness");
	AttributesArray.Add("Organization");
	AttributesArray.Add("Terms");
	AttributesArray.Add("BusinessOperation");
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, AttributesArray);
	
EndProcedure

&AtServer
Procedure CurrencyOnChangeServer(NewCurrency, RecalculateAmounts)
	
	FillInDefaultContract();
	If RecalculateAmounts Then
		OldCurrency = DocumentCurrency;
		ExecuteRecalculateDocumentAmountsServer(OldCurrency, NewCurrency);
	EndIf;
	
	FillInSubordinatePropertiesForStatistics("Currency");
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Currency");
	
	ForeignCurrencyTransaction = ARAPAccountingServer.GetPaidInDefaultCurrency();
	If ForeignCurrencyTransaction <> Object.ForeignCurrencyTransaction Then
		Object.ForeignCurrencyTransaction = ForeignCurrencyTransaction;
		Object.CompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
	EndIf;
	
	If Not ValueIsFilled(Object.CompanyBankAccount) Then
		Object.CompanyBankAccount = GetOrganizationSDefaultBankAccountServer();
	EndIf;

EndProcedure

&AtServer
Procedure PriceIncludesVATOnChangeServer(CachedValues)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	
EndProcedure

&AtServer
Procedure WarehouseOnChangeServer()
	
	Warehouse = Object.Warehouse;  
	WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWTCProcurementDocuments(Object.Warehouse);
	
	SetParametersForSelectingProductsWarehouse();
	
	WarehousesServer.FillInWarehousesInTablePart(Object.Warehouse, WarehouseGroup_, Object.Goods, True);
	
	AdvancedWarehousingOnShipment = WarehousesServer.UseWarehouseManagemantSystemForGoodsIssue(Warehouse, Object.Date);
	FillSetVisibilityAndReFillAvailabilityByShipment();

	Items.GroupPictureAndLabelMultipleWarehouses.Visible = WarehouseGroup_;
	
	WhenChangingWarehouseInTablePartServer();
	
EndProcedure

&AtServer
Procedure VATTaxationOnChangeServer()
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActions = New Structure;
	ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object, False, Object.ReturnOfReceivedReusablePackages);
	If ValueIsFilled(Object.DocumentInflow) Then
		ParametersForFillingInVATRate.Date = Common.ObjectAttributeValue(Object.DocumentInflow, "Date");
	EndIf;
	
	StructureOfActions.Insert("AdjustVATRate", ParametersForFillingInVATRate);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValues.ProcessedRows,
		StructureOfActions,
		Object.Goods,
		Undefined);
	
	SetCurPageOfBasementSums();

	VATAccountingERP.SetVisibilityOfCommandAndFillInVATRate(ThisObject);

EndProcedure

&AtServer
Procedure DateOnChangeServer()
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	AdvancedWarehousingOnShipment = WarehousesServer.UseWarehouseManagemantSystemForGoodsIssue(Warehouse, Object.Date);
	
	FillInVATTaxationPurchases();
	VATTaxationOnChangeServer();
	
	FillSetVisibilityAndReFillAvailabilityByShipment();
	UpdateTextDocumentsBasedOn();
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	PurchasesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible, Object.Contract);
	
	If ValueIsFilled(Object.Organization) Then
		
		FillInVATTaxationPurchases();
		VATTaxationOnChangeServer();
		
		FillInDefaultContract();
		
		If UseLinesOfBusiness Then
			LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
		EndIf;
		
		CashServer.CheckFillInOrganizationSBankAccountByOwner(Object.Organization,
			Object.CompanyBankAccount, , Object.LineOfBusiness, Object.ForeignCurrencyTransaction);
		FillInSubordinatePropertiesForStatistics("Organization");
		
		UpdateTextDocumentsBasedOn();
		
	EndIf;
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	ResponsiblePersonsServer.InstallManager(
		Object, PurchasesServer.DocumentBasis(Object, "DocumentInflow, Goods.DocumentInflow"));
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Organization");
	
EndProcedure

&AtServer
Procedure ContractOnChangeServer()
	
	ForeignCurrencyTransaction = Object.ForeignCurrencyTransaction;
	FillBaseForPrinting();
	
	If ValueIsFilled(Object.Contract) Then
		Object.ForeignCurrencyTransaction = Common.ObjectAttributeValue(Object.Contract,"ForeignCurrencyTransaction");
	EndIf;
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	
	If ForeignCurrencyTransaction <> Object.ForeignCurrencyTransaction Then
		Object.CompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
	EndIf;
	
	PurchasesServerCall.FillInBankAccountsUnderAgreement(Object.Contract, Object.CompanyBankAccount,
		Object.CounterpartyBankAccount);
	
	If Not ValueIsFilled(Object.CompanyBankAccount) Then
		Object.CompanyBankAccount = GetOrganizationSDefaultBankAccountServer();
	EndIf;
	
	FillInSubordinatePropertiesForStatistics("Contract");
	
	FillInVATTaxationPurchases();
	VATTaxationOnChangeServer();
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Contract");
	
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	ResponsiblePersonsServer.InstallManager(
		Object, PurchasesServer.DocumentBasis(Object, "DocumentInflow, Goods.DocumentInflow"));
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	
	PurchasesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible, Object.Contract);
	
	If ValueIsFilled(Object.Counterparty) Then
		
		FillInDefaultContract();
		
	EndIf;
	SalesServer.PartnerOnChange(Object);
	FillInSubordinatePropertiesForStatistics("Counterparty");
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	
	FillInVATTaxationPurchases();
	VATTaxationOnChangeServer();
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Counterparty");
	
EndProcedure

&AtServer
Procedure DirectionOfActivityWhenChangingOnServer()
	
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "LineOfBusiness");
	
EndProcedure

#EndRegion

#Region SelectionAndProcessingOfQuantityVerification

&AtClient
Procedure CheckQuantityInTheDocumentClient()
	
	OnlyNonLabeledProductsHaveBeenUnloaded = False;
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("AddressInTempStorage",             PutTablePartOfGoodsInTemporaryStorageToCheckQuantity(OnlyNonLabeledProductsHaveBeenUnloaded));
	OpeningParameters.Insert("TabularSectionName",                     "Goods");
	OpeningParameters.Insert("Ref",                                Object.Ref);
	OpeningParameters.Insert("GoodsQuantityExcessIsAllowed",  True);
	OpeningParameters.Insert("SeriesSpecificationParameters",                SeriesSpecificationParameters);
	OpeningParameters.Insert("Warehouse",                                 Object.Warehouse);
	OpeningParameters.Insert("OnlyNonLabeledProductsHaveBeenUnloaded", OnlyNonLabeledProductsHaveBeenUnloaded);
	
	OpenForm("CommonForm.CheckDocumentPopulation", OpeningParameters,,,,, New CallbackDescription("CheckQuantityInTheDocumentCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	
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
	TabularPartProducts.GroupBy("Products, Characteristic, ItemVariantsAreUsed, Warehouse, Package, Series, BatchesIndicationStatus, ItemsType", "NumberOfPackages");
	AddressInTempStorage = PutToTempStorage(TabularPartProducts, UUID);
	Return AddressInTempStorage;
	
EndFunction

&AtServer
Procedure ChangeTablePartBasedOnResultsOfCheck(ReturnParameters, CachedValues)
	
	GoodsTable = GetFromTempStorage(ReturnParameters.Goods);
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersFillInVATRate.ByDateOfReceipt = True;
	
	RowsToProcess = New Array;
	ProcessedLinesAreNew = New Array;
	LinesToDelete = New Array;
	For Each SourceRow In GoodsTable Do
		
		Filter = New Structure("Products, Characteristic, Series, ItemVariantsAreUsed, Warehouse, Package");
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
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ReturnOfReceivedReusablePackages);
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ReturnOfReceivedReusablePackages);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject);
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Products", StructureOfActions);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ProcessedLinesAreNew,
		StructureOfActions,
		Object.Goods,
		CachedValues);

	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);

	For Each TSRow In LinesToDelete Do
		Object.Goods.Delete(TSRow);
	EndDo;
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	
EndProcedure

&AtClient
Procedure CheckQuantityInTheDocument(Command)

	CheckQuantityInTheDocumentClient();
	
EndProcedure

&AtClient
Procedure CheckQuantityInTheDocumentCompletion(Result, AdditionalParameters) Export
    
    ReturnParameters = Result;
    If ReturnParameters <> Undefined Then
        ChangeTablePartBasedOnResultsOfCheck(ReturnParameters, ?(CachedValues = Undefined, BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues(), CachedValues));
        Modified = True;
        
        RecalculateAmountsInPaymentDecryptionLine();
        CalculateReturnTotals(ThisForm);
        
    EndIf;

EndProcedure

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected)
	
	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersFillInVATRate.ByDateOfReceipt = True;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ReturnOfReceivedReusablePackages);
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ReturnOfReceivedReusablePackages);
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject);
	
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Products", StructureOfActions);
	RowsToProcess = New Array();
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct, 
			"PartnerProducts,
			|Products,
			|Characteristic,
			|ItemVariantsAreUsed,
			|Package,
			|Warehouse,
			|Price,
			|NumberOfPackages");
			
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	FillInServiceDetailsForProductRange();
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
	WhenChangingWarehouseInTablePartServer();
	
EndProcedure

&AtServer
Procedure ProcessingSelectionSelectionOnReceiptServer(ValueSelected)
	
	ReturnValueStructure = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	TableOfGoods = ReturnValueStructure.Goods;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ReturnOfReceivedReusablePackages);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Products", StructureOfActions);

	RowsToProcess = New Array;
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);
		RowsToProcess.Add(CurrentRow);
		
		If ValueIsFilled(Object.Warehouse) Then
			
			If Not WarehouseGroup_ Then  
				CurrentRow.Warehouse = Object.Warehouse;
			ElsIf Not CurrentRow.Warehouse.BelongsToItem(Object.Warehouse) Then
				CurrentRow.Warehouse = Catalogs.Warehouses.EmptyRef();
			EndIf;
		Else
			
			CurrentRow.Warehouse = Catalogs.Warehouses.EmptyRef();
			
		EndIf;	
		
	EndDo;
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods);
	
	FillInServiceDetailsForProductRange();
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
	WhenChangingWarehouseInTablePartServer();
	
EndProcedure

#EndRegion

#Region BarcodesAndTradeEquipment

&AtClient
Procedure ProcessBarcodes(BarcodeData_5)
	
	ClearMessages();
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
		Return;
	EndIf;
	
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersFillInVATRate.ByDateOfReceipt = True;
	
	StructureOfActionsWithAddedStrings = New Structure;
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsWithAddedStrings.Insert("FillInProductNameOfProductPartner", Object.Partner);
	StructureOfActionsWithAddedStrings.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActionsWithAddedStrings.Insert("FillInVATRateForReturnableContainers", Object.ReturnOfReceivedReusablePackages);
	StructureOfActionsWithAddedStrings.Insert("FillInNoReturnContainerAttribute", Object.ReturnOfReceivedReusablePackages);
	StructureOfActionsWithAddedStrings.Insert("CheckFillWarehouse", 
								BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActionsWithAddedStrings);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithAddedStrings, ThisObject);
	
	StructureOfActionsWithModifiedStrings = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithModifiedStrings, ThisObject);
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	StructureOfActions.SeriesSpecificationParameters                 = SeriesSpecificationParameters;
	StructureOfActions.GoodsOnly                           = True;
	
	ProcessBarcodesServer(StructureOfActions, CachedValues);
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(StructureOfActions, CachedValues, ThisObject);
	
	If BarcodingOfItemsClient.YouNeedToOpenFormForSpecifyingSeriesAfterProcessingBarcodes(StructureOfActions) Then
		CurDataId = StructureOfActions.ArrayOfRowsWithSeries_[0];
		
		AttachIdleHandler("OpenSeriesSelectionWhenScanningProductBarCode", 0.1, True);
	EndIf;
	
	RecalculateAmountsInPaymentDecryptionLine();
	CalculateReturnTotals(ThisObject);
	
	If StructureOfActions.CurrentRow <> Undefined Then
		Items.Goods.CurrentRow = StructureOfActions.CurrentRow;	
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessBarcodesServer(StructureOfActionParameters, CachedValues)
	
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject, Object, StructureOfActionParameters, CachedValues);
	
EndProcedure

#EndRegion

#Region SetOfSeries

&AtServer
Procedure SetVisibilityOfSeriesElements ()
	
	Items.GoodsBatchesIndicationStatus.Visible  = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsSpecifySeries.Visible         = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsFillInSeriesByFEFO.Visible = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsSeries.Visible                = SeriesSpecificationParameters.UseItemsBatch;
	
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
Function FillInSeriesByFEFOServer()
	
	If ProductsServer.ThereAreLinesWithFEFOFilledSeries_(Object.Goods) Then
		ProductsServer.FillInSeriesByFEFO(Object,SeriesSpecificationParameters);	
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
Procedure OpenSeriesSelectionWhenScanningProductBarCode()

	If CurDataId = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.Goods.FindByID(CurDataId);
	OpenSelectionOfSeries(,CurrentData);

EndProcedure

&AtClientAtServerNoContext
Function GetBusinessTransaction(BusinessOperation)
	
	If BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnOfGoodsToVendor") Then
		Return PredefinedValue("Enum.BusinessTransactions.PurchaseFromSupplier");
	ElsIf BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnOfGoodsToConsignor") Then
		Return PredefinedValue("Enum.BusinessTransactions.ConsignmentProcurement");
	Else
		Return PredefinedValue("Enum.BusinessTransactions.EmptyRef");
	EndIf;
	
EndFunction

&AtServer
Procedure FillInDefaultContract()
	
	BusinessOperationsOfTheContract = New Array;
	If Object.BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsToVendor Then
		BusinessOperationsOfTheContract.Add(Enums.BusinessTransactions.PurchaseFromSupplier);
		BusinessOperationsOfTheContract.Add(Enums.BusinessTransactions.PurchaseByImport);
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsToConsignor Then
		BusinessOperationsOfTheContract.Add(Enums.BusinessTransactions.ConsignmentProcurement);
	EndIf;
	
	If UseLinesOfBusiness Then
		
		AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
		AddlParameters.ARAPCurrency = Object.Currency;
		AddlParameters.LineOfBusiness = Object.LineOfBusiness;
		Contract = PurchasesServer.GetDefaultContract(Object, BusinessOperationsOfTheContract, AddlParameters);
		
	Else
		
		AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
		AddlParameters.ARAPCurrency = Object.Currency;
		Contract = PurchasesServer.GetDefaultContract(Object, BusinessOperationsOfTheContract, AddlParameters);
		
	EndIf;
														
	If Contract <> Object.Contract Then
		Object.Contract = Contract;
		ForeignCurrencyTransaction = Object.ForeignCurrencyTransaction;
		ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Contract");
		If ForeignCurrencyTransaction <> Object.ForeignCurrencyTransaction Then
			Object.CompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
		EndIf;
		PurchasesServerCall.FillInBankAccountsUnderAgreement(Object.Contract, Object.CompanyBankAccount, Object.CounterpartyBankAccount);
	EndIf;
	
	FillBaseForPrinting();
	
EndProcedure

&AtServer
Procedure GetPaymentDecryptionFromVault(AddressOfPaymentsInTheStorage)

	Object.ARAPDetails.Load(GetFromTempStorage(AddressOfPaymentsInTheStorage));
	ARAPAccountingFormWork.UpdateDistributedDecryptionAmount(ThisForm);
	
EndProcedure

&AtServer
Function PutGoodsAndStockTypesInStorage()
	
	Return InventoriesServer.PutGoodsAndStockTypesInStorage(ThisObject);
	
EndFunction

&AtServer
Procedure GetStockTypesFromStorage(ValueSelected)
	
	InventoriesServer.ProcessInputOfInventoryTypesManually(ValueSelected, ThisForm);
	
EndProcedure

&AtServer
Procedure ExecuteRecalculateDocumentAmountsServer(OldCurrency, NewCurrency)
	
	If OldCurrency <> NewCurrency Then
		
		DocumentDate               = ?(ValueIsFilled(Object.Date), Object.Date,CurrentSessionDate());
		LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
		CourseStructures = ARAPAccountingServer.ExchangeRatesForTranslation(ThisForm, OldCurrency, NewCurrency, LocalAccountingCurrency, DocumentDate);
		StructureOfOldCurrencyRates = CourseStructures.StructureOfOldCurrencyRates;
		StructureOfNewCurrencyRates  = CourseStructures.StructureOfNewCurrencyRates;
		
		PriceManagementSystem.ConvertTabularAmountsToCurrency(
			Object.Goods,
			Object.PriceIncludesVAT,
			OldCurrency,
			NewCurrency,
			StructureOfOldCurrencyRates,
			StructureOfNewCurrencyRates);
		
		TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
		
	EndIf;
	
	GoodsAmount = ?(Object.DepositForPackageIsRequired Or Not Object.ReturnOfReceivedReusablePackages,
		Object.Goods.Total("AmountIncludingVAT"),
		Object.Goods.Total("AmountIncludingVATWithoutReusablePackages"));
	ARAPAccountingARAPDetailsFillingIn.ConvertAmountsToCurrencyPaymentDecryption(Object, GoodsAmount);
	CalculateReturnTotals(ThisForm);
	
EndProcedure

&AtServer
Procedure FormItemsManagement()
	
	ThereAreMutualSettlements = (Object.BusinessOperation <> Enums.BusinessTransactions.ReturnOfGoodsToConsignor);
	
	ItemArray = New Array();
	ItemArray.Add("ReducedDebtByLine");
	ItemArray.Add("CompensationAmount");
	ItemArray.Add("CurrencyOfCompensation");
	ItemArray.Add("CompensationMethod");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items,
		ItemArray,
		"Visible",
		ThereAreMutualSettlements);
	
EndProcedure

&AtServer
Procedure SetCurPageOfBasementSums()
	
	DisplayTotalAmountOfVAT = VATAccountingERPClientServer.DisplayNDSInResultsOfSalesDocument(Object.VATTaxation);
	
	If DisplayTotalAmountOfVAT Then
		Items.VATPageGroup.CurrentPage   = Items.PageVAT;
		Items.PagesTotalGroup.CurrentPage = Items.TotalSNDSPage;
	Else
		Items.VATPageGroup.CurrentPage   = Items.PageExcludingVAT;
		Items.PagesTotalGroup.CurrentPage = Items.PageTotalWithoutVAT;
	EndIf;
	
EndProcedure

&AtServer
Function FillInShippingServer(ShipmentStatus, FillWithUnassembledGoods=False)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersFillInVATRate.ByDateOfReceipt = True;
	
	StructureOfActionsWithModifiedStrings = New Structure;
	StructureOfActionsWithModifiedStrings.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActionsWithModifiedStrings.Insert("RecalculateAmount");
	StructureOfActionsWithModifiedStrings.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActionsWithModifiedStrings.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	StructureOfActionsWithAddedStrings = New Structure;
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsWithAddedStrings.Insert("FillInProductNameOfProductPartner", Object.Partner);
	StructureOfActionsWithAddedStrings.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActionsWithAddedStrings.Insert("FillInVATRateForReturnableContainers", Object.ReturnOfReceivedReusablePackages);
	StructureOfActionsWithAddedStrings.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActionsWithAddedStrings.Insert("RecalculateAmount");
	StructureOfActionsWithAddedStrings.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActionsWithAddedStrings.Insert("FillInNoReturnContainerAttribute", Object.ReturnOfReceivedReusablePackages);
	StructureOfActionsWithAddedStrings.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	ParametersStructure = SalesServer.StructureOfDocumentToFillInForActualShipment();
	FillPropertyValues(ParametersStructure, Object);
	FillPropertyValues(ParametersStructure, ShipmentStatus);
	ParametersStructure.StructureOfActionsWithModifiedStrings = StructureOfActionsWithModifiedStrings;
	ParametersStructure.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	ParametersStructure.FillWithUnassembledGoods = FillWithUnassembledGoods;
	ParametersStructure.PaddingLines = True;
	ParametersStructure.SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(Object, Documents.ReturnOfGoodsToVendor);
	
	HasChanges = SalesServer.FillInByActualShipment(Object, ParametersStructure);
	
	If HasChanges Then
		ReturnOfGoodsToVendorLocalization.FillInCacheOfBarcodesOfPackages(ThisObject);
	EndIf;
	
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
	Return HasChanges;
	
EndFunction

&AtServer
Function PlaceGoodsInTemporaryStorageServer()
	
	Return PurchasesServer.PlaceGoodsInTemporaryStorage(Object.Goods);
	
EndFunction

&AtServer
Procedure FillInItemsFromTemporaryStorageServer(AddressInTempStorage)
	
	TableOfGoods = GetFromTempStorage(AddressInTempStorage); // DocumentTabularSection.ReturnOfGoodsToVendor.Goods
	
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersFillInVATRate.ByDateOfReceipt = True;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActions = New Structure;
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ReturnOfReceivedReusablePackages);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ReturnOfReceivedReusablePackages);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	RowsToProcess = New Array();
	
	For Each CurRow In TableOfGoods Do
		
		ArrayOfCollectionRows = Object.Goods.FindRows(New Structure("LineNumber", CurRow.LineNumber));
		If ArrayOfCollectionRows.Count() <> 1 Then
			Continue;
		Else
			CollectionRow = ArrayOfCollectionRows[0];
		EndIf;
		
		FillPropertyValues(CollectionRow, CurRow, "Products, Characteristic, Package");
		
		RowsToProcess.Add(CollectionRow);
		StructureOfActions.Insert("CheckFillWarehouse", 
							BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	FillInServiceDetailsForProductRange();
	WhenChangingWarehouseInTablePartServer();
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	UsePartnersAsCounterparties = GetFunctionalOption("UsePartnersAsCounterparties");
	UseLinesOfBusiness = GetFunctionalOption("UseCostAccountingByLinesOfBusiness");
	UseTransportationJobsForDeliveryAccountingByCarriers = GetFunctionalOption("UseTransportationJobsForDeliveryAccountingByCarriers");
		
	SetAvailabilityAgreements();
	
	ManagingRelationshipsOfFormDetailsSelectionParameters();
	
	FillOperationSelectionList(False);
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	
	ContractBusinessTransaction = GetBusinessTransaction(Object.BusinessOperation); 

	WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWTCProcurementDocuments(Object.Warehouse);
	Warehouse = Object.Warehouse;
	
	SetParametersForSelectingProductsWarehouse();
	
	Terms = Object.Terms;
	
	DocumentCurrency = Object.Currency;
	FormItemsManagement();
	SetCurPageOfBasementSums();
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.ReturnOfGoodsToVendor));
	SetVisibilityOfSeriesElements();

	FillInServiceDetailsForProductRange();
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, Object.ReturnOfReceivedReusablePackages);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());

	WarehouseOnChangeServer();
		PurchasesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible);
		
	Items.GroupPictureAndLabelMultipleWarehouses.Visible = WarehouseGroup_;
		
	UpdateTextDocumentsBasedOn();
	
	PrintBasisTable.Load(Documents.ReturnOfGoodsToVendor.PrintBasisTable(Object));
	If AccessRight("Update", Metadata.Documents.ReturnOfGoodsToVendor) And ValueIsFilled(Object.Basis) Then
		If ValueIsFilled(Object.Basis) Then
			BaseStructure = Documents.ReturnOfGoodsToVendor.StructureOfBaseForPrinting(Object);
			BasisChanged = (TrimAll(Object.Basis) <> BaseStructure.Basis) 
				Or (TrimAll(Object.BaseDocumentNumber) <> BaseStructure.BaseDocumentNumber)
				Or (Object.ReferenceDocumentDateForPrintForms <> BaseStructure.ReferenceDocumentDateForPrintForms);
		EndIf;
	Else
		BasisChanged = False;
	EndIf;
	UpdateInformationOnReceipts();
	
	CalculateReturnTotals(ThisForm);
	
	BackgroundTaskData = GoodsDelivery.WhenReadingCreatingOrdersOnServer(Items, Object,,,,True);
	CurrentDeliveryMethod = Object.DeliveryMethod;
		
	UpdateAvailabilityOfReturnContainerItems();
	
	LinesOfBusinessServer.OnReadCreateAtServer(ThisObject);
	
	ProcessingOfTabularForms.InitializeRowCache(Items.Goods);
	
	FillParameters = Documents.ReturnOfGoodsToVendor.ParametersForFillingInVATTaxationPurchases(Object);
	VATAccountingERP.FillInListOfVATTaxChoices(Items.VATTaxation, Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues);
	
	WhenChangingWarehouseInTablePartServer();
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Form)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Form.Object);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
EndProcedure

&AtServer
Procedure UpdateInformationOnReceipts()
	
	PurchasesServer.UpdateInformationOnReceiptsInForm(
		ReceiptsList,
		Object.DocumentInflow,
		ReceiptHeaderText,
		Items,
		Items.GoodsDocumentInflow,
		Object.Goods,
		"DocumentInflow");
	
EndProcedure

&AtServer
Procedure FillInReceiptsAndPricesOnServer()
	
	PurchasesServer.FillInTheReceiptsAndPrices(Object, "Goods");
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	
EndProcedure

&AtServer
Procedure SetAvailabilityAgreements()
	If ValueIsFilled(Object.Partner) Then
		NumberOfAgreementsWithPostavshik  = PurchasesServerCall.GetNumberOfAgreementsWithSupplier(Object.Partner);
		TMCommonUseClientServer.SetFormItemProperty(Items, "Terms", "Visible", NumberOfAgreementsWithPostavshik > 0);
	EndIf; 
EndProcedure

&AtServer
Procedure ManagingRelationshipsOfFormDetailsSelectionParameters()
	
	If ValueIsFilled(Object.DocumentInflow) Then
		
		ReceiptDetails = Common.ObjectAttributesValues(
			Object.DocumentInflow, "BusinessOperation, Partner");
		
		If ReceiptDetails.BusinessOperation = Enums.BusinessTransactions.PurchaseViaAdvanceHolder Then
			
			NewLinks = New Array;
			
			If ValueIsFilled(ReceiptDetails.Partner) Then
				Mode = LinkedValueChangeMode.Clear;
			Else
				Mode = LinkedValueChangeMode.DontChange;
			EndIf;
			
			NewLinks.Add(New ChoiceParameterLink("Filter.Contract", "Object.Contract", Mode));
			NewLinks.Add(New ChoiceParameterLink("Filter.Partner", "Object.Partner", Mode));
			NewLinks.Add(New ChoiceParameterLink("Filter.Counterparty", "Object.Counterparty", Mode));
			NewLinks.Add(New ChoiceParameterLink("Filter.Terms", "Object.Terms", Mode));
			NewLinks.Add(New ChoiceParameterLink("Filter.Organization", "Object.Organization", LinkedValueChangeMode.Clear));
			
			Items.GoodsDocumentInflow.ChoiceParameterLinks = New FixedArray(NewLinks);
		EndIf;
	EndIf;
	
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
	
	If Not ValueIsFilled (Object.Partner) Then
		GoodsDeliveryClientServer.ClearDeliveryDetails(Items,Object);
	EndIf;
	
	RecalculateAmountsInPaymentDecryptionLine();
	CalculateReturnTotals(ThisForm);
	
	If ValueIsFilled(Object.Terms) Then
		PurchasesClient.NotifyEndOfFillingInDefaultPurchaseConditions();
	EndIf;
	
EndProcedure

&AtServer
Procedure ContactPersonOnChangeServer(PartnerChanged_)
	
	OwnerOfContactPerson = Common.ObjectAttributeValue(Object.ContactPerson, "Owner");
	If OwnerOfContactPerson <> Object.Partner Then
		Object.Partner = OwnerOfContactPerson;
		PartnerOnChangeServer();
		PartnerChanged_ = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillMultiTurnContainersFromStorageServer(AddressOfContainerInStorage)
	
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersFillInVATRate.ByDateOfReceipt = True;
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	ActionStructureModifiedStrings = New Structure;
	ActionStructureModifiedStrings.Insert("RecalculateNumberOfPackages");
	ActionStructureModifiedStrings.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	ActionStructureModifiedStrings.Insert("RecalculateAmount");
	ActionStructureModifiedStrings.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	ActionStructureModifiedStrings.Insert("FillInNoReturnContainerAttribute", Object.ReturnOfReceivedReusablePackages);
	ActionStructureModifiedStrings.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	StructureOfActionsAddedLines =  CommonClientServer.CopyStructure(ActionStructureModifiedStrings);
	StructureOfActionsAddedLines.Insert("CheckFillWarehouse", 
						BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	StructureOfActionsAddedLines.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsAddedLines.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsAddedLines.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActionsAddedLines.Insert("FillInVATRateForReturnableContainers", Object.ReturnOfReceivedReusablePackages);
	StructureOfActionsAddedLines.Insert("FillInNoReturnContainerAttribute", Object.ReturnOfReceivedReusablePackages);
	StructureOfActionsAddedLines.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	ReusablePackageServer.FillMultiTurnContainersFromStorage(
		Object,
		AddressOfContainerInStorage,
		"Goods",
		"Products,Characteristic",
		ActionStructureModifiedStrings,
		StructureOfActionsAddedLines);
	
	FillInServiceDetailsForProductRange();
	
	UpdateInformationOnReceipts();
	
EndProcedure

&AtServer
Procedure ReturnOfReceivedReusablePackagesOnChangeServer()
	
	If Not Object.ReturnOfReceivedReusablePackages Then
		Object.DepositForPackageIsRequired = False;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ReturnOfReceivedReusablePackages);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ReturnOfReceivedReusablePackages);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
	UpdateAvailabilityOfReturnContainerItems();
	
EndProcedure

&AtServer
Procedure UpdateAvailabilityOfReturnContainerItems()
	
	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		"DepositForPackageIsRequired",
		"Visible",
		Object.ReturnOfReceivedReusablePackages
		And Object.BusinessOperation <> Enums.BusinessTransactions.ReturnOfGoodsToConsignor);
	
EndProcedure

&AtServer
Procedure GetUploadedProductsFromStorage(GoodsAddressInStorage)
	
	ItemsFromStorage = GetFromTempStorage(GoodsAddressInStorage);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckFillWarehouse", 
					BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ReturnOfReceivedReusablePackages);
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ReturnOfReceivedReusablePackages);
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisForm, StructureOfActions);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisForm);
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Products", StructureOfActions);
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array();
	
	For Each RowOfGoods In ItemsFromStorage Do
		StringTSGoods = Object.Goods.Add();
		FillPropertyValues(StringTSGoods, RowOfGoods);
		RowsToProcess.Add(StringTSGoods);
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
EndProcedure

&AtServer
Procedure FillSetVisibilityAndReFillAvailabilityByShipment()
	
	Items.GoodsRefillByShipment.Enabled = AdvancedWarehousingOnShipment;
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.ReturnOfGoodsToVendor));
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	SetVisibilityOfSeriesElements();
	
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
Procedure OpenSelectionOfSeries(Text = "", CurrentData = Undefined)
	
	If ProductsClient.YouNeedServerCallToSpecifySeries(ThisForm,SeriesSpecificationParameters,Text, CurrentData)Then
		
		If Not Items.GoodsSpecifySeries.Enabled Then
			Return;
		EndIf;
		
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
	
	Columns = "Products,Characteristic,Package,NumberOfPackages,Price,DocumentInflow,Warehouse";
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);

	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersFillInVATRate.ByDateOfReceipt = True;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ReturnOfReceivedReusablePackages);
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ReturnOfReceivedReusablePackages);
	StructureOfActions.Insert("CheckFillWarehouse", 
				BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisForm);
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisForm, StructureOfActions);

	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array();

	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Products", StructureOfActions);
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
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
	WhenChangingWarehouseInTablePartServer();
	
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

#Region WorkingWithCounterparties
&AtClient
Procedure CheckCounterparties(Command)
	
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure GoodsAfterDeleteRowServer()

	UpdateInformationOnReceipts();
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
	WhenChangingWarehouseInTablePartServer();
	
EndProcedure

&AtClient
Procedure Attachable_CloseForm()
	
	If IsOpen() Then
		Close();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsForProductRange()
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute",
		New Structure("Products", "ItemVariantsAreUsed"));
	
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_",
		New Structure("Products", "ItemsType"));
	
	ParametersForFillingInBankingDetails.Insert("FillInArticleAttribute",
		New Structure("Products", "SKU"));

	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods,ParametersForFillingInBankingDetails);
	
EndProcedure

&AtClient
Procedure RecalculateAmountsInPaymentDecryptionLine()
	
	GoodsAmount = ?(Object.DepositForPackageIsRequired Or Not Object.ReturnOfReceivedReusablePackages,
		Object.Goods.Total("AmountIncludingVAT"),
		Object.Goods.Total("AmountIncludingVATWithoutReusablePackages"));
	
	FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, GoodsAmount);
	
EndProcedure

&AtClientAtServerNoContext
Function DependentDetails()
	
	Return New Structure("WithoutReusablePackages", "AmountIncludingVAT");
	
EndFunction

&AtClientAtServerNoContext
Procedure CalculateReturnTotals(Form)
	
	Form.AmountTotal = ?(Form.Object.DepositForPackageIsRequired Or Not Form.Object.ReturnOfReceivedReusablePackages,
		Form.Object.Goods.Total("AmountIncludingVAT"),
		Form.Object.Goods.Total("AmountIncludingVATWithoutReusablePackages"));
	
	Form.PackageDepositValue = Form.Object.Goods.Total("AmountIncludingVAT") - Form.Object.Goods.Total("AmountIncludingVATWithoutReusablePackages");
	
	Form.CompensationAmount = Form.AmountTotal - Form.AllocatedAmountOfPrintName;
	
	TMCommonUseClientServer.SetFormItemProperty(
		Form.Items,
		"CompensationMethod",
		"Enabled",
		Form.CompensationAmount <> 0);
	
	Form.ReducedDebtByLine = NStr("vi = 'Giảm nợ nhà cung cấp:';
									|ru = 'Уменьшен долг перед поставщиком:';
									|en = 'Debt owed to vendor is reduced:'; fa = 'Debt owed to vendor is reduced:';
									|it = 'Debito ridotto verso il fornitore:';
									|pl = 'Zmniejszono zobowiązanie przed dostawcą:';
									|tr = 'Tedarikçiye olan borç azaltıldı:'") + " " + Format(Form.AllocatedAmountOfPrintName, "NFD=2; NZ=0,00")
		+ " " + Form.Object.Currency;
	
EndProcedure

&AtClient
Procedure OpenPrintDetails()

	Try
		LockFormDataForEdit();
	Except
		ShowMessageBox(Undefined, BriefErrorDescription(ErrorInfo()));
		Return;
	EndTry;
	
	ParametersStructure = New Structure();
	ParametersStructure.Insert("DeliveryAddress",                   Object.DeliveryAddress);
	ParametersStructure.Insert("DeliveryAddressValue",           Object.DeliveryAddressValue);
	ParametersStructure.Insert("DeliveryAddressFieldValues",      Object.DeliveryAddressFieldValues);
	ParametersStructure.Insert("ShipperBankAccount",  Object.ShipperBankAccount);
	ParametersStructure.Insert("GoodsRecipientBankAccount",   Object.GoodsRecipientBankAccount);
	ParametersStructure.Insert("CounterpartyBankAccount",       Object.CounterpartyBankAccount);
	ParametersStructure.Insert("Shipper",                Object.Shipper);
	ParametersStructure.Insert("GoodsRecipient",                 Object.GoodsRecipient);
	ParametersStructure.Insert("LetterOfAuthorityIssuedBy",              Object.LetterOfAuthorityIssuedBy);
	ParametersStructure.Insert("PowerOfAttorneyDate",                Object.PowerOfAttorneyDate);
	ParametersStructure.Insert("PowerOfAttorneyPerson",                Object.PowerOfAttorneyPerson);
	ParametersStructure.Insert("PowerOfAttorneyNumber",               Object.PowerOfAttorneyNumber);
	ParametersStructure.Insert("Contract",                         Object.Contract);
	ParametersStructure.Insert("Basis",                       Object.Basis);
	ParametersStructure.Insert("ReferenceDocumentDateForPrintForms",                   Object.ReferenceDocumentDateForPrintForms);
	ParametersStructure.Insert("BaseDocumentNumber",                  Object.BaseDocumentNumber);
	ParametersStructure.Insert("IssuiedBy",                        Object.IssuiedBy);
	ParametersStructure.Insert("IssuiedByJobTitle",               Object.IssuiedByJobTitle);
	ParametersStructure.Insert("Partner",                         Object.Partner);
	ParametersStructure.Insert("BusinessOperation",           Object.BusinessOperation);
	ParametersStructure.Insert("Counterparty",                      Object.Counterparty);
	ParametersStructure.Insert("ReadOnly",                  ReadOnly);
	ParametersStructure.Insert("ObjectType",                     "ReturnOfGoodsToVendor");
	ParametersStructure.Insert("CompanyBankAccount",       Object.CompanyBankAccount);
	ParametersStructure.Insert("Organization",                     Object.Organization);
	ParametersStructure.Insert("Date",                            Object.Date);
	ParametersStructure.Insert("Director",                    Object.Director);
	ParametersStructure.Insert("ChiefAccountant",                Object.ChiefAccountant);
	ParametersStructure.Insert("PrintBasisTable",       PrintBasisTable);

	OpenForm("CommonForm.PrintingDetailsOfSales", ParametersStructure, ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtServer
Procedure FillBaseForPrinting()
	
	If Not BasisChanged Then
		BaseStructure = Documents.ReturnOfGoodsToVendor.StructureOfBaseForPrinting(Object);
		FillPropertyValues(Object, BaseStructure);
	EndIf;
	PrintBasisTable.Load(Documents.ReturnOfGoodsToVendor.PrintBasisTable(Object));
	
EndProcedure

&AtServer
Procedure FillInVATTaxationPurchases()
	
	FillParameters = Documents.ReturnOfGoodsToVendor.ParametersForFillingInVATTaxationPurchases(Object);
	VATAccountingERP.FillInVATTaxationPurchases(Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues);
	VATAccountingERP.FillInListOfVATTaxChoices(Items.VATTaxation, Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues); 
	
EndProcedure

&AtServer
Procedure FillOperationSelectionList(SetOperation = True)
	
	If Not GetFormFunctionalOption("UsePurchaseCommission") Then
		
		ListItem = Items.BusinessOperation.ChoiceList.FindByValue(Enums.BusinessTransactions.ReturnOfGoodsToConsignor);
		If ListItem <> Undefined Then
			Items.BusinessOperation.ChoiceList.Delete(ListItem);
		EndIf;
		
	EndIf;
	
	OnlyOperation = Items.BusinessOperation.ChoiceList.Count() = 1;
	If SetOperation And OnlyOperation And Not ValueIsFilled(Object.BusinessOperation) Then
		Object.BusinessOperation = Items.BusinessOperation.ChoiceList[0].Value;
		BusinessOperationOnChangeServer();
	EndIf;
	
	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		"BusinessOperation",
		"ReadOnly",
		OnlyOperation And ValueIsFilled(Object.BusinessOperation));
	
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

&AtServer
Function InvoiceRegistrationParameters()
	
	Result = New Structure;
	Result.Insert("Issued", Documents.ReturnOfGoodsToVendor.ParametersForRegisteringInvoicesIssued(Object)); 
	Result.Insert("Received", Documents.ReturnOfGoodsToVendor.ParametersForRegisteringInvoicesReceived(Object)); 
	
	Return Result; 
	
EndFunction

&AtServer
Procedure UpdateTextDocumentsBasedOn()
	
	TextsFieldsDocumentsBasedOn.Clear();
	
	UpdateTextOfInvoiceIssued();
	UpdateTextDocumentsBasedOnLocalization();
	
	ParametersForRegisteringImportNotifications = ReturnOfGoodsToVendorLocalization.ParametersForRegisteringImportNotificationsOfTraceableGoods(Object);
	NotificationOfImportationOnBasisOf = AccountingForTraceableGoodsLocalization.NotificationsOfImportOfTraceableGoodsOnDocumentOfReceipt(ParametersForRegisteringImportNotifications);
	TextsFieldsDocumentsBasedOn.Add(NotificationOfImportationOnBasisOf.PresentationOfOrderForRegistration);
	TextsFieldsDocumentsBasedOn.Add(NotificationOfImportationOnBasisOf.PresentationOfImportNotification);
	
	TMCommonUseClientServer.UpdateTextDocumentsBasedOn(ThisObject);
	
EndProcedure

// Parameters:
// ValueSelected - CatalogRef.ProductCrossReferences
// AdditionalParameters - Structure
// 
&AtClient
Procedure ProcessResultOfSelectingPartnerProductName(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	
	AdditionalParameters.CurrentRow.PartnerProducts = ValueSelected;
	
	GoodsPartnerProductsOnChange(AdditionalParameters.FormItem);
	
EndProcedure

#EndRegion

&AtClient
Procedure ReducedDebtByClickingAfterVerification(Result, AdditionalParameters) Export
	
	Notification = New CallbackDescription("ReducedDebtByLineClickCompletion", ThisObject);
	PlacePaymentDecryptionInTemporaryStorage();
	ARAPAccountingClient.ARAPAccountingOnReturnOfGoods(ThisForm, Items.ReducedDebtByLine, Notification);
	
EndProcedure

&AtServer
Procedure PlacePaymentDecryptionInTemporaryStorage()
	ARAPAccountingFormWork.PlacePaymentDecryptionInTemporaryStorage(ThisForm, "ReducedDebtByLine");
EndProcedure

&AtClient
Procedure QuestionAboutReFillingWithShippedGoodsCompletion(Result, AdditionalParameters) Export
	
	If Not Result.Refill Then
		Return;
	EndIf;
	
	RefillByShipmentCompletion(AdditionalParameters.ShipmentStatus, Result.FillWithUnassembledGoods);
	
EndProcedure

&AtClient
Procedure RefillByShipmentCompletion(ShipmentStatus, FillWithUnassembledGoods = False)
	
	HasChanges = FillInShippingServer(ShipmentStatus, FillWithUnassembledGoods);
	
	RecalculateAmountsInPaymentDecryptionLine();
	CalculateReturnTotals(ThisForm);
	
	SalesClient.NotifyEndOfReplenishmentOfGoodsForShipment(HasChanges, 
		ShipmentStatus.ThereAreShippedGoods Or ShipmentStatus.ThereAreUnassembledGoods);
	
EndProcedure

&AtClient
Procedure SearchByBarcodeCompletion(BarcodeData_2, AdditionalParameters) Export
	
	ProcessBarcodes(BarcodeData_2);
	
EndProcedure

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export 
	
	CurrentRow = Items.Goods.CurrentData;
	
	If NewRow <> Undefined Then
		
		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisForm);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
		WhenChangingWarehouseInTablePartServer();
		
		RecalculateAmountsInPaymentDecryptionLine();
		CalculateReturnTotals(ThisForm);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInVATRateCompletion(VATRate, AdditionalParameters) Export

	If VATRate = Undefined Then
		Return;
	EndIf;

	FillInVATRateOnServer(VATRate, CachedValues);
	RecalculateAmountsInPaymentDecryptionLine();
	CalculateReturnTotals(ThisObject);

EndProcedure

&AtServer
Procedure FillInVATRateOnServer(VATRate, CachedValues)

	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());

	SelectedRows = ProcessingOfTabularFormsClientServer.CollectionItems(
		Object.Goods, Items.Goods.SelectedRows);
	RowsToDelete = New Array;
	For Each LineOfATabularSection In SelectedRows Do
		If Object.ReturnOfReceivedReusablePackages
			And LineOfATabularSection.ItemsType = Enums.ItemsTypes.ReusablePackage Then
			RowsToDelete.Add(LineOfATabularSection);
			Continue;
		EndIf;
		LineOfATabularSection.VATRate = VATRate;
	EndDo;
	For Each LineToDelete In RowsToDelete Do
		SelectedRows.Delete(SelectedRows.Find(LineToDelete));
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		SelectedRows,
		StructureOfActions,
		Object.Goods,
		CachedValues);

EndProcedure

#Region EventHandlersDelivery

&AtClient
Procedure DecorationDeliveryServiceCreateClick(Item)
	
	
EndProcedure

&AtClient
Procedure DecorationDeliveryServiceOrderListClick(Item)
	
	
EndProcedure

&AtClient
Procedure DecorationDeliveryServiceAddToDeliveryOrderClick(Item)
	
	
EndProcedure


&AtClient
Procedure MethodPlaceOfDeliveryCarrierIfChanged(Item)
	
	MethodPlaceOfDeliveryCarrierIfChangedServer(Item.Name);
	
EndProcedure

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

&AtServer
Procedure MethodPlaceOfDeliveryCarrierIfChangedServer(ItemName)
	
	UpdateTextDocumentsBasedOn();
	GoodsDelivery.FillInDeliveryDetails(Items, ItemName, Object);

EndProcedure

#EndRegion

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
EndProcedure

&AtServer
Procedure UpdateTextOfInvoiceIssued()
	
	ParametersForRegisteringIssuedSF = Documents.ReturnOfGoodsToVendor.ParametersForRegisteringInvoicesIssued(Object);
	ParametersForRegisteringReceivedSF = Documents.ReturnOfGoodsToVendor.ParametersForRegisteringInvoicesReceived(Object);
	InvoiceBasedOn = VATAccountingERP.InvoicesGeneralOnBasisOf(ParametersForRegisteringIssuedSF, ParametersForRegisteringReceivedSF);
	
	TextOfTheInvoiceIssued = SalesServer.CreatePresentationOfInvoiceGenerationCommandsBasedOn(Object.Ref, InvoiceBasedOn);
	
	TextsFieldsDocumentsBasedOn.Add(TextOfTheInvoiceIssued);
	
EndProcedure

&AtServer
Procedure CompensationMethodOnChangeServer()
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisForm);
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

&AtClient
Procedure FillInDocumentsOfAdmissionOfVHF()
	
	If ValueIsFilled(Object.DocumentInflow) Then
		For Each RowOfProduct In Object.Goods Do
			If Not ValueIsFilled(RowOfProduct.DocumentInflow) Then
				RowOfProduct.DocumentInflow = Object.DocumentInflow;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInSubordinatePropertiesForStatistics(ParentPropsName)
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, ParentPropsName);
EndProcedure

&AtServer
Procedure PaymentInCurrencyOnChangeAtServer()
	
	Object.CompanyBankAccount = GetOrganizationSDefaultBankAccountServer();
	
EndProcedure

&AtServer
Function GetOrganizationSDefaultBankAccountServer()
	
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Object.Organization);
	ParametersOfAccount.LineOfBusiness = Object.LineOfBusiness;
	ParametersOfAccount.ExcludeCurrencyAccounts = Object.ForeignCurrencyTransaction;
	ParametersOfAccount.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	Return CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount);
	
EndFunction

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
