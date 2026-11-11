#Region Variables

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
	Items.ReflectionInAccounting_.TitleTextColor = Metadata.StyleItems.HyperlinkColor.Value;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25();

	DocumentCorrection.OnCreateAtServer(ThisForm, Items.LineCorrection);
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisForm);

	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	FillOperationSelectionList();
	
	ManagingRelationshipsOfFormDetailsSelectionParameters();
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	ElsIf Parameters.FillingValues.Property("FillByWarehouseDocument") Then
		RefillByNotes(Parameters.FillingValues.AnArrayOfOrders);
		CalculateReturnTotals(ThisForm);
		Modified = True;
	EndIf;
	
	SalesServer.SetModeForSelectingGroupsOfWarehouseItems(Items.Warehouse);
	
	SalesServer.SetBlankContractMark(Items, "Contract");
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.GroupInTotal.BackColor = New Color();
	EndIf;
	
	UpdateRegisteredProducts();
	
	SetAvailabilityOfClipboardCommands();
	
	AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(ThisForm, Object.Date);
	
	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisForm);
	
	GeneratingFiscalChecksServer.FormWhenCreatedOnServer(ThisObject);
	
	CalculateCompensationAmount(ThisForm);
	
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	
	ProcessingOfTabularForms.InitializeRowCache(Items.Goods);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	// Standard subsystems.Accounting of the originals of the first documents
	SourceDocumentsOriginalsRecording.OnCreateAtServerDocumentForm(ThisObject);
	// The end of the standard subsystem.Accounting of the originals of the first documents 
	
	AccountingForTraceableGoodsLocalization.SetTitleNumberOfCCD(Items, "GoodsCCDNumber");

	VATAccountingERP.SetVisibilityOfCommandAndFillInVATRate(ThisObject);

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	ReturnOfGoodsFromCustomerLocalization.FillCheckProcessingAtServer(ThisObject, Cancel, CheckedAttributes);
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// StandardSubsystems.Properties
		PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties	
	
	ARAPAccountingFormWork.FormWhenReadingOnServer(ThisForm);
	
	GeneratingFiscalChecksServer.FormWhenReadingOnServer(ThisObject);
	
	DocumentCorrection.OnReadAtServer(ThisForm, Items.LineCorrection);
	
	OnReadCreateAtServer();
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);

	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	Var CurrentOperation1;
	
	If TypeOf(ValueSelected) = Type("Structure") And ValueSelected.Property("CurrentOperation1", CurrentOperation1) Then
		
		If Upper(CurrentOperation1) = Upper("AddItemsFromSalesOrderGoodsIssue") Then
			ProcessingProductSelectionFromOrder(ValueSelected.AddressInStorage);
			FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, AmountTotal);
			CalculateCompensationAmount(ThisForm);
		EndIf;
		
	ElsIf ChoiceSource.FormName = "Catalog.InventoryKinds.Form.InventoryOwnerAttributesForm" Then
		
		GetStockTypesFromStorage(ValueSelected);
		
	ElsIf ChoiceSource.FormName = "CommonForm.SelectGoodsBySalesAndTransfers" Then
		
		ProcessingSelectionSelectionByImplementationServer(ValueSelected);
		FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, AmountTotal);
		CalculateCompensationAmount(ThisForm);
		
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectGoodsToSalesDocument.Form.Form" Then
		
		ProcessingSelectionOfSelectionOnServer(ValueSelected);
		FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, AmountTotal);
		CalculateCompensationAmount(ThisForm);
		
	ElsIf ChoiceSource.FormName = "DataProcessor.PrintApplicationForReturnOfGoodsFromCustomer.Form.AttributesForReturnApplicationPrinting" Then
		
		If ValueSelected <> Undefined Then
			Modified = True;
			FillPropertyValues(Object, ValueSelected);
		EndIf;
		
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectReusablePackage.Form.Form" Then
		
		FillMultiTurnContainersFromStorageServer(ValueSelected.AddressOfReusableContainerInStorage);
		ReusablePackageClient.NotifyUserAboutFillingMultiTurnContainers();
		FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, AmountTotal);
		CalculateCompensationAmount(ThisForm);
		
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);
		
		ProductsSeriesRecalculatePrices();
		
	ElsIf PurchasesClient.ThisIsSelectionOfCCDNumber(ChoiceSource) Then
		
		ProcessSelectionOfCCDNumber(ValueSelected);
		
	ElsIf VATAccountingERPClient.FinishedEditingInvoiceReceived(ValueSelected, ChoiceSource) Then
		
		UpdateTextOfInvoiceReceived();
		
	ElsIf VATAccountingERPClient.FinishedEditingInvoiceIssued(ValueSelected, ChoiceSource) Then
		
		UpdateTextOfInvoiceReceived();
		
	EndIf;
	
	If Window <> Undefined Then
		Window.Activate();
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	
	ARAPAccountingServer.BeforeWriteAtServer(ThisForm, CurrentObject);
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	FillInServiceDetailsOfTablePart();
	
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, Object.ReusablePackageReturn);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	
	UpdateTextOfInvoiceReceived();

	EstablishCostPresentation();
	

	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
	ARAPAccountingFormWork.FormAfterRecordingOnServer(ThisForm, CurrentObject.AdditionalProperties);
	
	GeneratingFiscalChecksServer.FormWhenChangingBankingDetails(ThisObject);
	
	CalculateCompensationAmount(ThisForm);
	
	UnlockFormDataForEdit();
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	ExcisableGoodsAccounting.UpdateElementsOfAccountingForExcisableItems(ThisObject, False);
	
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	If ValueIsFilled(Object.RequestForReturnOfGoodsFromCustomer) Then
		WriteParameters.Insert("SalesOpportunity", Object.SalesOpportunity);
	EndIf;
	ARAPAccountingClient.FormAfterRecording(ThisForm);
	
	WriteParameters.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
		
	Notify("Write_ReturnOfGoodsFromCustomer", WriteParameters, Object.Ref);
	
	FormEventsClient.AfterWrite(ThisObject, WriteParameters);
	
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisForm, Object, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(
		Undefined,
		ThisObject,
		"BarcodeScanner,FiscalCashRegisters");
	
	// StandardSubsystems.Properties
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	
	
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
	
	If Exit Then
		Return;
	EndIf;
	
	CloseKmVerificationSessionOnCCT(Cancel);
	
EndProcedure

&AtClient
Procedure OnClose()
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties

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
		
		KitParameters = New Structure;
		KitParameters.Insert("ProductsInSet", Parameter.ProductsInSet);
		KitParameters.Insert("ItemVariantOfSet", Parameter.ItemVariantOfSet);
		KitParameters.Insert("DocumentSalesOfGoodsAndServices", Parameter.DocumentSalesOfGoodsAndServices);
		KitParameters.Insert("DialColumns", DialColumns());
		
		SetAddressInTemporaryStorage = SetAddressInTemporaryStorage(KitParameters);
		
		OpeningParameters = New Structure;
		OpeningParameters.Insert("AddressInTempStorage", SetAddressInTemporaryStorage);
		OpeningParameters.Insert("ProductsInSet",   Parameter.ProductsInSet);
		OpeningParameters.Insert("ItemVariantOfSet", Parameter.ItemVariantOfSet);
		OpeningParameters.Insert("DocumentSalesOfGoodsAndServices", Parameter.DocumentSalesOfGoodsAndServices);
		OpeningParameters.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
		OpeningParameters.Insert("VATTaxation", Object.VATTaxation);
		OpeningParameters.Insert("Currency", Object.Currency);
		OpeningParameters.Insert("Terms", Object.Terms);
		OpeningParameters.Insert("Date", Object.Date);
		OpeningParameters.Insert("Ref", Object.Ref);
		OpeningParameters.Insert("Warehouse", Object.Warehouse);
		OpeningParameters.Insert("HideCommandRemainingQuantityInWarehouses", False);
		If ValueIsFilled(Object.CashRegisterReceipt) Then
			OpeningParameters.Insert("PriceKind", CashReceiptPriceType);
			OpeningParameters.Insert("ProhibitPriceEditing", True);
		EndIf;	
		OpeningParameters.Insert("Organization", Object.Organization);
		
		OpenForm("DataProcessor.EditSet.Form.Form", OpeningParameters, ThisObject, UUID);
		
	EndIf;
	

	
	DocumentCorrectionClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);

	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

	// StandardSubsystems.SourceDocumentsOriginalsRecording	
	SourceDocumentsOriginalsRecordingClient.NotificationHandlerDocumentForm(EventName, ThisObject);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
	
	If EventName = "WhenChangingAgreement"
		And Source = ThisObject Then
		Modified = True;
		ContractOnChange(Items[Parameter]);
	EndIf;
	
	If EventName = "WhenChangingClientSContract"
		And Source = ThisObject Then
		Modified = True;
		CustomerContractOnChange(Items[Parameter]);
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

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)

	FormEventsClient.URLProcessing(ThisObject, FormattedStringURL, StandardProcessing);

EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
	If NotExecuteCheck1BeforeWrite Then
		NotExecuteCheck1BeforeWrite = False;
		Return;
	EndIf;
	
	If WriteParameters.WriteMode = DocumentWriteMode.Posting 
		And Not ValueIsFilled(Object.RequestForReturnOfGoodsFromCustomer)
		And Object.Goods.Count() > 0
		And (Object.ReusablePackageFillingStatus = PredefinedValue("Enum.ReusablePackageFillingStates.OfferToFillIn")
			Or Not ValueIsFilled(Object.ReusablePackageFillingStatus)) Then
		
		AdditionalParameters = New Structure;
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
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters, Cancel, WriteParameters.Property("AttachableCommandExecutionParameters"));
	
EndProcedure

&AtClient
Procedure BeforeRecordingOfferToPickUpMultiTurnContainer(Result, AdditionalParameters) Export
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, AdditionalParameters.WriteParameters,,True);
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	
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
	If CurrentPage.Name = "AdvancedGroup" And ItIsRequiredToUpdateTitleIsSubjectToExciseDuty Then
		CalculateNumberOfExcisableItemsDeferred();
		ExcisableGoodsAccountingClient.AfterCalculatingNumberOfExcisableItems(ThisObject);
	EndIf;
EndProcedure

&AtClient
Procedure TermsStartChoice(Item, ChoiceData, StandardProcessing)
	
	AgreementSelectionParameters = SalesClient.ParametersForStartingSelectionOfAgreementWithClient();
	
	AgreementSelectionParameters.Item                     = Item;
	AgreementSelectionParameters.Partner                     = Object.Partner;
	AgreementSelectionParameters.Document                    = Object.Terms;
	AgreementSelectionParameters.DocumentDate               = Object.Date;
	AgreementSelectionParameters.FormDataStructure        = Object;
	AgreementSelectionParameters.BusinessOperation       = BusinessTransactionFromAgreement;
	
	SalesClient.StartSelectingAgreementWithClient(AgreementSelectionParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	If Not ValueIsFilled (Object.Partner) Then
		PartnerClearingServer();
		Return;
	EndIf;
	
	PartnerOnChangeServer();
	FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, AmountTotal);
	CalculateCompensationAmount(ThisForm);
	
	If ToUseTermsOfSales And ValueIsFilled(Object.Terms) Then
		SalesClient.NotifyEndOfFillingInDefaultSalesConditions();
	EndIf;
	
	
EndProcedure

&AtClient
Procedure TermsOnChange(Item)

	If Not ValueIsFilled (Object.Terms) Then
		TermsClearingServer();
		TheCommissionAgentDoesNotKeepRecordsOnTheRNPT = False;
		Return;
	EndIf;
	
	TermsOnChangeServer();
	FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, AmountTotal);
	CalculateCompensationAmount(ThisObject);
	
	SalesClient.NotifyEndOfFillingInTermsOfSale();
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	WarehouseOnChangeServer(True);
	
EndProcedure

&AtClient
Procedure VATTaxationOnChange(Item)
	
	VATTaxationOnChangeServer();
	FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, AmountTotal);
	CalculateCompensationAmount(ThisForm);
	
EndProcedure

&AtClient
Procedure PriceIncludesVATOnChange(Item)
	
	PriceIncludesVATOnChangeServer(CachedValues);
	FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, AmountTotal);
	CalculateCompensationAmount(ThisForm);
	
EndProcedure

&AtServer
Procedure WhenChangingReceiptOfKKMServer(ReFillProducts)

	DocumentSalesOfGoodsAndServices = GetReportOnRetailSalesByCashRegisterReceipt(Object.CashRegisterReceipt);
	Object.DocumentSalesOfGoodsAndServices = DocumentSalesOfGoodsAndServices;
	
	For Each LineProducts_ In Object.Goods Do
		LineProducts_.DocumentSalesOfGoodsAndServices = DocumentSalesOfGoodsAndServices;
		LineProducts_.CostDefiningMethod = PredefinedValue("Enum.WaysToCalculateReturnCost.FromSalesDocument");
	EndDo;
	
	Object.Partner = Common.ObjectAttributeValue(Object.CashRegisterReceipt, "Partner");
	Object.Counterparty = Catalogs.Counterparties.RetailCustomer;

	If ToUseTermsOfSales Then
		FillIn_TermsOfSales();
	EndIf;

	TMCommonUseClientServer.SetFormItemProperty(Items, "Partner", "ReadOnly", ValueIsFilled(Object.CashRegisterReceipt));
	
	UpdateTextOfInvoiceReceived();

	If ReFillProducts Then
		FillInReturnedItemsByReceipt();
	EndIf;

	FillInFormDetailsFromCashRegisterReceipt(Object.CashRegisterReceipt, New Structure("CashReceiptPriceType", "PriceKind"));
	FillInServiceDetailsOfTablePart();
	CalculateReturnTotals(ThisForm);
	CalculateCompensationAmount(ThisForm);
	If QualityControl.UpdateActionParameters(
			Documents.ReturnOfGoodsFromCustomer,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
	SetVisibilityOfElementsAccordingToImplementationDocuments();
	OrderOfReflection = OrderOfReflection(Object.RecordInProfitLossOfPreviousYears);
	Items.ReflectionInAccounting_.Title = TitleOfReflectionInAccounting(Object.RecordInProfitLossOfPreviousYears);
	
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	
	If ValueIsFilled(Object.Currency) Then
		
		CurrencyOnChangeServer(Object.Currency, PriceManagementSystemClient.CurrencyConversionRequired(Object,DocumentCurrency));
		PriceManagementSystemClient.NotifyAboutEndOfConversionOfAmountsIntoCurrency(DocumentCurrency, Object.Currency);
		
	EndIf;
	
	DocumentCurrency = Object.Currency;
	
EndProcedure

&AtClient
Procedure FeaturesOfReflectionONChange(Item)
	
	UpdateAttributesOfAccountingDocument();
	Items.ReflectionInAccounting_.Title = TitleOfReflectionInAccounting(Object.RecordInProfitLossOfPreviousYears);
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyOnChangeServer();
	
	
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
	
	If ValueIsFilled (Object.Partner) Then
		
		If ToUseTermsOfSales And ValueIsFilled(Object.Terms) Then
			SalesClient.NotifyEndOfFillingInDefaultSalesConditions();
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	WhenBusinessOperationIsChangedInteractivelyServer();
	
	ClearImplementationDocuments();
	
EndProcedure

&AtClient
Procedure CustomerVATExemptOnChange(Item)
	
	UpdateTextOfInvoiceReceived();
	
EndProcedure

&AtClient
Procedure CashIssuedOnChange(Item)
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "CashAccountIssueNoteDate", "Enabled", Object.CashIssued);
	TMCommonUseClientServer.SetFormItemProperty(Items, "CashAccountIssueNoteNumber", "Enabled", Object.CashIssued);
	
EndProcedure

&AtClient
Procedure CashRegisterReceiptOnChange(Item)
	
	If ValueIsFilled(Object.CashRegisterReceipt) Then
		If CashRegisterReceiptChangeOpen(Object.CashRegisterReceipt) Then
			Object.CashRegisterReceipt = Undefined;
			Raise NStr("vi = 'Phiên thu ngân đã mở! Cấm nhập chứng từ ""Nhận hàng bán bị trả lại"" trên cơ sở phiếu khi phiên thu ngân đang mở';
						|ru = 'Кассовая смена открыта! Ввод на основании чека документа ""Возврат товаров от клиента"" при открытой кассовой смене запрещен.';
						|en = 'POS shift is opened. Input on the basis of receipt of document ""Sales return"" is prohibited when the POS shift is opened.'; fa = 'POS shift is opened. Input on the basis of receipt of document ""Sales return"" is prohibited when the POS shift is opened.';
						|it = 'Il turno di cassa è aperto! È vietata l''immissione in base allo scontrino del documento ""Reso delle merci dal cliente"" con un turno di cassa aperto.';
						|pl = 'Kasowa zmiana jest otwarta! Wprowadzenie na podstawie paragonu dokumentu ""Возврат товаров от клиента"" podczas otwartej zmiany kasowej jest zabronione.';
						|tr = 'Kasa vardiyası açık! ""Müşteriden Mal İadesi"" belgesi, bir kasiyerin vardiyası açıkken makbuz bazında girilmemelidir.'");
		EndIf;
		
		AnswersOptions = New ValueList;
		AnswersOptions.Add(DialogReturnCode.Yes, NStr("vi = 'Điền lại';
														|ru = 'Перезаполнить';
														|en = 'Refill'; fa = 'پرکردن مجدد';
														|it = 'Ricompilare';
														|pl = 'Refill';
														|tr = 'Yeniden doldur'"));
		AnswersOptions.Add(DialogReturnCode.No, NStr("vi = 'Không điền lại';
													|ru = 'Не перезаполнять';
													|en = 'Do not refill'; fa = 'Do not refill';
													|it = 'Non ricompilare';
													|pl = 'Nie wypełniaj ponownie';
													|tr = 'Yeniden doldurma'"));
		
		ShowQueryBox(
			New CallbackDescription("CashRegisterReceiptOnChangeCompletion", ThisObject),
			NStr("vi = 'Điền lại hàng hóa ';
				|ru = 'Перезаполнить возвращаемые товары по выбранному чеку ККМ?';
				|en = 'Refill goods pending return by the selected receipt?'; fa = 'Refill goods pending return by the selected receipt?';
				|it = 'Ricompilare i prodotti in reso per scontrino selezionato KKM (Macchinari di Registrazione e Controllo)?';
				|pl = 'Ponownie wypełnić zwracane wiersze pozycji według wybranego paragonu kasy?';
				|tr = 'İade edilen ürünler seçilen kasa fişine yeniden doldurulsun mu?'"),
			AnswersOptions);
		Return;

	Else
		TMCommonUseClientServer.SetFormItemProperty(Items, "Partner", "ReadOnly", False);
	EndIf;

EndProcedure

&AtServer
Function CashRegisterReceiptChangeOpen(CashRegisterReceipt)
	
	CashRegisterReceiptAttributes = Common.ObjectAttributesValues(CashRegisterReceipt, "Date, CashRegisterShift");
	
	Return RetailSales.ShiftIsOpened(CashRegisterReceiptAttributes.CashRegisterShift, CurrentSessionDate())
	
EndFunction

&AtClient
Procedure CashRegisterReceiptOnChangeCompletion(QuestionResult, AdditionalParameters) Export

	UserAnswer = QuestionResult;

	ReFillProducts = (UserAnswer = DialogReturnCode.Yes);
	
	CashRegisterReceiptWhenChangingFragment();
	WhenChangingReceiptOfKKMServer(ReFillProducts);

EndProcedure

&AtClient
Procedure CashRegisterReceiptWhenChangingFragment()
	
	CalculateReturnTotals(ThisForm);
	FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, AmountTotal);
	
	If ToUseTermsOfSales And ValueIsFilled(Object.Terms) Then
		SalesClient.NotifyEndOfFillingInDefaultSalesConditions();
	EndIf;
	
	UpdateInformationOnImplementations();

EndProcedure

&AtClient
Procedure DocumentSalesOfGoodsAndServicesOnChange(Item)
	
	DocumentSalesOfGoodsAndServicesOnChangeServer();
	
EndProcedure

&AtServerNoContext
Function ParametersForRegisteringInvoicesReceivedServer(Val Object)
	
	Return Documents.ReturnOfGoodsFromCustomer.ParametersForRegisteringInvoicesReceived(Object);
	
EndFunction	

&AtServerNoContext
Function ParametersForRegisteringInvoicesIssuedServer(Val Object)
	
	Return Documents.ReturnOfGoodsFromCustomer.ParametersForRegisteringInvoicesIssued(Object);
	
EndFunction

&AtClient
Procedure TextDocumentsBasedOnFooterURLProcessing(Item, Var_URL, StandardProcessing)
	
	RegistrationParameters = ParametersForRegisteringInvoicesReceivedServer(Object);
	
	VATAccountingERPClient.ProcessingNavigationLinkInvoicesReceived(
		ThisForm,
		Var_URL,
		StandardProcessing,
		RegistrationParameters);
		
	RegistrationParameters = ParametersForRegisteringInvoicesIssuedServer(Object);
	
	VATAccountingERPClient.ProcessingNavigationLinkInvoicesIssued(
		ThisForm,
		Var_URL,
		StandardProcessing,
		RegistrationParameters);
	
	FiscalOperationNavigationLinkProcessing(Item, Var_URL, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOnChangeServer();
	
	
EndProcedure

&AtClient
Procedure TheInscriptionTheTitleOfTheImplementationClick(Item, StandardProcessing)
	StandardProcessing = False;
	
	OpenForm(
		"CommonForm.ViewingListOfDocuments",
		New Structure("DocumentsList, Title",
			SalesList,
			NStr("vi = 'Giao hàng cho khách (%DocumentsCount%)';
				|ru = 'Реализации клиентам (%DocumentsCount%)';
				|en = 'Sales to the customers (%DocumentsCount%)'; fa = 'Sales to the customers (%DocumentsCount%)';
				|it = 'Realizzi ai clienti (%DocumentsCount%)';
				|pl = 'Sprzedaż klientom (%DocumentsCount%)';
				|tr = 'Müşterilere satışlar (%DocumentsCount%)'")
		),
		ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure ReusablePackageReturnOnChange(Item)
	
	ReusablePackageReturnOnChangeServer();
	FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, AmountTotal);
	CalculateCompensationAmount(ThisForm);
	
EndProcedure

&AtClient
Procedure ReducedDebtByLineClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.CheckForPromiscuity = False;
	CheckParameters.CheckedAttributes.Insert("Organization", NStr("vi = 'Doanh nghiệp';
																	|ru = 'Организация';
																	|en = 'Company'; fa = 'Company';
																	|it = 'Azienda';
																	|pl = 'Firma';
																	|tr = 'İş yeri'"));
	CheckParameters.CheckedAttributes.Insert("Partner",     NStr("vi = 'Khách hàng';
																|ru = 'Клиент';
																|en = 'Customer'; fa = 'مشتری';
																|it = 'Cliente';
																|pl = 'Klient';
																|tr = 'Müşteri'"));
	CheckParameters.CheckedAttributes.Insert("Currency",      NStr("vi = 'Tiền tệ';
																	|ru = 'Валюта';
																	|en = 'Currency'; fa = 'ارز';
																	|it = 'Valuta';
																	|pl = 'Currency';
																	|tr = 'Para birimi'"));
	If Not UsePartnersAsCounterparties Then
		CheckParameters.CheckedAttributes.Insert("Counterparty", NStr("vi = 'Đối tác';
																		|ru = 'Контрагент';
																		|en = 'Counterparty'; fa = 'طرف حساب';
																		|it = 'Controparte';
																		|pl = 'Kontrahent';
																		|tr = 'Cari hesap'"));
	EndIf;
	CheckParameters.CheckedAttributes.Insert("BusinessOperation", NStr("vi = 'Giao dịch';
																		|ru = 'Операция';
																		|en = 'Transaction'; fa = 'تراکنش';
																		|it = 'Operazione';
																		|pl = 'Transaction';
																		|tr = 'İşlem'"));
	Notification = New CallbackDescription("ReducedDebtByClickingAfterVerification", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure ReducedDebtByLineClickCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		Modified = True;
		GetPaymentDecryptionFromVault(Result);
		CalculateReturnTotals(ThisForm);
		CalculateCompensationAmount(ThisForm);
	EndIf;
	
EndProcedure

&AtClient
Procedure DepositForPackageIsRequiredOnChange(Item)
	
	CalculateReturnTotals(ThisForm);
	FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, AmountTotal);
	CalculateCompensationAmount(ThisForm);
	
EndProcedure

&AtClient
Procedure ContractCreating(Item, StandardProcessing)
	
	SalesClient.OpenContractCreationForm(ThisObject, Item, "Object.Contract", Object.Partner, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	If ValueIsFilled(Object.RequestForReturnOfGoodsFromCustomer) 
		And Contract <> Object.Contract And UseAdvancedFeaturesOfSalesOrder() Then
				
		UntieFromApplication = False;
		AnswersOptions = New ValueList;
		
		AnswersOptions.Add("UntieFromApplication", NStr("ru = 'Отвязать от заявки';
														|vi = 'Unlink from request';
														|en = 'Unlink from request'; fa = 'Unlink from request';
														|it = 'Unlink from request';
														|pl = 'Unlink from request';
														|tr = 'Talepten ayır'"));
		AnswersOptions.Add("Cancel", NStr("ru = 'Отмена';
											|vi = 'Cancel';
											|en = 'Cancel'; fa = 'انصراف';
											|it = 'Cancel';
											|pl = 'Cancel';
											|tr = 'İptal'"));
		QueryText = NStr("ru = 'При изменении договора документ будет отвязан от заявки. Продолжить?';
						|vi = 'If you change the contract, the document will be unlinked from the request. Continue?';
						|en = 'If you change the contract, the document will be unlinked from the request. Continue?'; fa = 'If you change the contract, the document will be unlinked from the request. Continue?';
						|it = 'If you change the contract, the document will be unlinked from the request. Continue?';
						|pl = 'If you change the contract, the document will be unlinked from the request. Continue?';
						|tr = 'Sözleşme değiştirildiğinde belge talepten ayrılacaktır. Devam edilsin mi?'");
			
		ShowQueryBox(
			New CallbackDescription("ContractOnChangeCompletion",
				ThisObject,
				New Structure("UntieFromApplication", UntieFromApplication)),
			QueryText,
			AnswersOptions);
			
	Else
		
		ContractOnChangeServer(True);
		
	EndIf;
		
	
EndProcedure

&AtClient
Procedure ContractOnChangeCompletion(QuestionResult, AdditionalParameters) Export 
	
	ClearMessages();
	
	If QuestionResult = "Cancel" Then
		
		Object.Contract = Contract;
		Return;
		
	ElsIf QuestionResult = "UntieFromApplication" Then
		
		Object.RequestForReturnOfGoodsFromCustomer = PredefinedValue("Document.RequestForReturnOfGoodsFromCustomer.EmptyRef");
		SetVisibilityOfElementsOfReturnOfGoodsRequest();
		
	EndIf;

	ContractOnChangeServer(True);

EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	
	FillInSalesVATTaxation();
	
EndProcedure

&AtClient
Procedure DateOfReceiptOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOfReceiptOnChangeServer();
	
EndProcedure

&AtClient
Procedure GoodsOnActivateCell(Item)
	
	If Not Item.CurrentItem = Items.GoodsBarcode
		And Not Item.CurrentItem = Items.GoodsCCDNumber Then
		Return;
	EndIf;

	CurrentData = Items.Goods.CurrentData;
	If CurrentData = Undefined Then
		Items.GoodsBarcode.ChoiceList.Clear();
		Return;
	EndIf;
	
	If Item.CurrentItem = Items.GoodsBarcode Then
		
		ProductData_8 = New Structure;
		ProductData_8.Insert("Products",   CurrentData.Products);
		ProductData_8.Insert("Characteristic", CurrentData.Characteristic);
		ProductData_8.Insert("Package",       CurrentData.Package);
		ProductData_8.Insert("Series",          CurrentData.Series);
		
		Items.GoodsBarcode.ChoiceList.LoadValues(
			RetailSalesServerCall.GetProductBarcodes(ProductData_8));
		
	ElsIf Item.CurrentItem = Items.GoodsCCDNumber Then
		
		PurchasesClient.FillInListOfCCDNumberSelection(
			Items.Goods.CurrentData, Items.GoodsCCDNumber.ChoiceList);
		
	EndIf;

EndProcedure

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
	ProductsClient.UpdateCachedValuesToAccountForSeries(Item,CachedValues,SeriesSpecificationParameters);
	
	SetsClient.BeforeDeletingRowOfTablePart(ThisForm, "Goods", Cancel);
	
EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	
	SeriesStatusesNeedToBeUpdated = ProductsClient.SeriesStatusesNeedToBeUpdated(
		Item, CachedValues, SeriesSpecificationParameters, True);
	
	ProductsAfterDeletionOnServer(SeriesStatusesNeedToBeUpdated, CachedValues);
	
	If SeriesStatusesNeedToBeUpdated Then
		ProductsClient.UpdateCachedValuesToAccountForSeries(
					Item,CachedValues,SeriesSpecificationParameters);
	EndIf;
	
	ReusablePackageClient.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);

	WhenChangingWarehouseInTablePartServer(); 
	
EndProcedure

&AtClient
Procedure GoodsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	If ValueIsFilled(Object.RequestForReturnOfGoodsFromCustomer) Then
		Cancel = True;
		OpenSelectionByOrdersOrders();
	EndIf;
	
	If Copy Then
		SetsClient.BeforeDeletingRowOfTablePart(ThisForm, "Goods", Cancel, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
	ProductsClient.UpdateCachedValuesToAccountForSeries(
				Item,CachedValues,SeriesSpecificationParameters, Copy);
	
	CurrentRow = Items.Goods.CurrentData;
	If Copy Then
		CurrentRow.RowID = "";
	EndIf;
	
	If NewRow Then
		CurrentRow.CostDefiningMethod = PredefinedValue("Enum.WaysToCalculateReturnCost.FromCurrentDocument");
		SetCostPresentationInLine(CurrentRow);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	CalculateReturnTotals(ThisForm);
	FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, AmountTotal);
	CalculateCompensationAmount(ThisForm);
	
	CurrentData = Items.Goods.CurrentData;
	
	If ProductsClient.SeriesStatusesNeedToBeUpdated(
		Item,CachedValues,SeriesSpecificationParameters) Then
		
		IDCurrentRow = CurrentData.GetID();
		
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues);	
		ProductsClient.UpdateCachedValuesToAccountForSeries(Item,CachedValues,SeriesSpecificationParameters);
		
	EndIf;
	
	If ValueIsFilled(Object.CashRegisterReceipt) Then
		If Not ValueIsFilled(CurrentData.DocumentSalesOfGoodsAndServices) Then
			CurrentData.DocumentSalesOfGoodsAndServices = GetReportOnRetailSalesByCashRegisterReceipt(Object.CashRegisterReceipt);
			CurrentData.CostDefiningMethod = PredefinedValue("Enum.WaysToCalculateReturnCost.FromSalesDocument");
		EndIf;
	EndIf;
	
	If Not CancelEdit Then
		LineCache = ?(NewRow, Undefined, ProcessingOfTabularFormsClientServer.LineCache(Items.Goods, ThisObject));
		WarehousesClient.UpdateWarehouseTable(WarehouseTable, CurrentData, LineCache, WarehouseGroup_, False);
		TotalWarehouses_ = WarehouseTable.Count();
		WarehousesClientServer.UpdateWarehouseGroupImage(SeveralWarehousesText, Items.PictureMultipleWarehouses, TotalWarehouses_);
	EndIf;
	
	SetCostPresentationInLine(CurrentData);
	
	ReusablePackageClient.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
	SetVisibilityOfElementsAccordingToImplementationDocuments();
	OrderOfReflection = OrderOfReflection(Object.RecordInProfitLossOfPreviousYears);
	Items.ReflectionInAccounting_.Title = TitleOfReflectionInAccounting(Object.RecordInProfitLossOfPreviousYears);
	
	AdditionalParameters = New Structure;
	FormEventsClient.WhenChangingElement(ThisObject, Items.Goods, AdditionalParameters);
	If AdditionalParameters.Property("ServerCallRequired__") Then
		AttachIdleHandler("GoodsAtEndOfEditingForServerCall", 0.5, True);
	EndIf;

EndProcedure

&AtServer
Procedure GoodsAtEndOfEditingOnServer()

	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
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
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products, ProductsOfOriginalQuality", "SKU", "SKURegistration"));
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	WarehousesClient.ChangeQuality(CurrentData, StructureOfActions, CachedValues);
	
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
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, Undefined);
	
EndProcedure

&AtClient
Procedure GoodsProductsRecordingAsReceivedOnChange(Item)

	CurrentData = Items.Goods.CurrentData;
	
	CurrentRow = New Structure;
	CurrentRow.Insert("Products", CurrentData.ProductsRecordingAsReceived);
	CurrentRow.Insert("ItemVariantsAreUsed", CurrentData.ItemVariantsAreUsedRecordingAsReceived);
	CurrentRow.Insert("Characteristic", CurrentData.CharacteristicRecordingAsReceived);
	CurrentRow.Insert("SKU", CurrentData.SKURegistration);
	CurrentRow.Insert("Series", CurrentData.Series);
	CurrentRow.Insert("BatchesIndicationStatus", CurrentData.BatchesIndicationStatus);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentData.CharacteristicRecordingAsReceived);
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, Undefined);
	
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
Procedure GoodsPackageOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	If ToUseTermsOfSales And ValueIsFilled(Object.Terms) Then
		StructureOfActions.Insert("FillIn_TermsOfSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
	EndIf;	
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(ThisForm, StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateReturnTotals(ThisForm);
	FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, AmountTotal);
	CalculateCompensationAmount(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CurrentRowID = Items.Goods.CurrentData.GetID();
	GoodsProductsOnChangeServer(CurrentRowID);
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)

	CurrentRowID = Items.Goods.CurrentData.GetID();
	
	GoodsCharacteristicOnChangeServer(CurrentRowID);
	
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisForm);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateReturnTotals(ThisForm);
	FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, AmountTotal);
	CalculateCompensationAmount(ThisForm);
	
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
	
	CalculateReturnTotals(ThisForm);
	FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, AmountTotal);
	CalculateCompensationAmount(ThisForm);
	
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
	
	CalculateReturnTotals(ThisForm);
	FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, AmountTotal);
	CalculateCompensationAmount(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsSumOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("RecalculatePriceDiscountByAmountInSales");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateReturnTotals(ThisForm);
	FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, AmountTotal);
	CalculateCompensationAmount(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsVATAmountOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateReturnTotals(ThisForm);
	FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, AmountTotal);
	CalculateCompensationAmount(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	OpenSelectionOfSeries(Item.EditText);
EndProcedure

&AtClient
Procedure GoodsSeriesOnChange(Item)
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	CurrentRow = Items.Goods.CurrentData;
	
	ValueSelected.Value            		 = CurrentRow.Series;
	ValueSelected.CurrentRowID = CurrentRow.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);

	ProductsSeriesRecalculatePrices(CurrentRow);
EndProcedure

&AtClient
Procedure ProductsSeriesRecalculatePrices(CurrentRow = Undefined)
	
	If CurrentRow = Undefined Then
		CurrentRow = Items.Goods.CurrentData;
	EndIf;
	
	If PriceManagementSystemClient.ItIsNecessaryToRecalculatePriceWhenChanging(CurrentRow.Products, "Series", Object.Date) Then
		CurrentRowID = CurrentRow.GetID();
		ProductsSeriesRecalculatePricesServer(CurrentRowID);
	EndIf;
	
EndProcedure

&AtServer
Procedure ProductsSeriesRecalculatePricesServer(CurrentRowID)
	
	CurrentRow = Object.Goods.FindByID(CurrentRowID);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	
	If (ToUseTermsOfSales And ValueIsFilled(Object.Terms)) 
		Or (Not ToUseTermsOfSales And UsePriceManagementSystem25) Then
		StructureOfActions.Insert("FillIn_TermsOfSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
	EndIf;

	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);

	BatchProcessingOfTablePartServer.ProcessTSString(CurrentRow, StructureOfActions, Undefined);

	CalculateReturnTotals(ThisForm);
	FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, AmountTotal);
	CalculateCompensationAmount(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If SetsClient.ItemToLock(Field) Then
		
		CurrentRow = Object.Goods.FindByID(RowSelected);
		If ValueIsFilled(CurrentRow.ProductsInSet) Then
			
			NotificationParameter1 = New Structure;
			NotificationParameter1.Insert("ProductsInSet",   CurrentRow.ProductsInSet);
			NotificationParameter1.Insert("ItemVariantOfSet", CurrentRow.ItemVariantOfSet);
			NotificationParameter1.Insert("DocumentSalesOfGoodsAndServices", CurrentRow.DocumentSalesOfGoodsAndServices);
			NotificationParameter1.Insert("OwnerForm", UUID);
			
			Notify("EditSet", NotificationParameter1, ThisForm);
			
		EndIf;
		
	ElsIf Field = Items.GoodsProductsInSet Then
		ShowValue(Undefined, Items.Goods.CurrentData.ProductsInSet);
		
	ElsIf Field = Items.GoodsMethodForDeterminingTheCostOfALine Then
		
		FillInCostInTable();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure LineOfBusinessOnChange(Item)
	
	LineOfBusinessOnChangeServer();

EndProcedure

&AtClient
Procedure GoodsMethodForDeterminingTheCostOfALineOnChange(Item)
	
	UpdateInformationOnImplementations();
	
EndProcedure

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
EndProcedure

&AtClient
Procedure GoodsDocumentSalesOfGoodsAndServicesOnChange(Item)
	
	CurrentRowID = Items.Goods.CurrentData.GetID();
	GoodsDocumentSalesOfGoodsAndServicesOnChangeServer(CurrentRowID);
	
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
Procedure CompensationMethodOnChange(Item)
	CompensationMethodOnChangeServer();
EndProcedure

&AtClient
Procedure Attachable_OriginalStateDecorationClick()

	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecordingClient.OpenStateSelectionMenu(ThisObject,Items.OriginalStateDecoration);
	//End StandardSubsystems.SourceDocumentsOriginalsRecording

EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(
		ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

&AtClient
Procedure CustomerPartnerOnChange(Item)
	
	PartnerClientWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure CustomerCounterpartyOnChange(Item)
	
	ClientCounterpartyWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure CustomerContractCreating(Item, StandardProcessing)
	
	SalesClient.OpenContractCreationForm(ThisObject, Item, "Object.Contract", Object.Partner,
		StandardProcessing, "WhenChangingClientSContract");
	
EndProcedure

&AtClient
Procedure CustomerContractOnChange(Item)
	
	ClientAgreesOnChangeOnServer();
	
EndProcedure

&AtClient
Procedure SubjectToExciseOnChange(Item)
	ExcisableGoodsAccountingClientServer.ConfigureProductionDivisionField(ThisObject);
	Return; // Not used in TM
EndProcedure
	
&AtClient
Procedure GoodsWarehouseOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", CurrentRow.Warehouse, SeriesSpecificationParameters));
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
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
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	If Not Object.Ref.IsEmpty() Then
		OpenForm("Document.ReturnOfGoodsFromCustomer.Form.AttributeUnlocking",,,,,, 
			New CallbackDescription("Attachable_AllowObjectAttributeEditCompletion", ThisObject), 
			FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEditCompletion(Result, AdditionalParameters) Export
    
    If TypeOf(Result) = Type("Array") And Result.Count() > 0 Then
		ObjectAttributesLockClient.SetFormItemEnabled(ThisForm, Result);
		SetAvailabilityOfFormCommands(True);
    EndIf;

EndProcedure

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure
// End StandardSubsystems.Properties


&AtClient
Procedure OpenInventoryKinds(Command)
	
	OptionsForEditingInventoryTypes = PutGoodsAndStockTypesInStorage();
		
	FinancesClient.OpenInventoryKinds(ThisObject, OptionsForEditingInventoryTypes);
	
EndProcedure

&AtClient
Procedure SearchByBarcodeExecute(Command)
	
	ClearMessages();
	Notification = New CallbackDescription("SearchByBarcodeCompletion", ThisObject);
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);
	
EndProcedure

&AtClient
Procedure ToPickUpTheGoodsInImplementations(Command)
	
	SelectionOfGoodsBySales();
	UpdateInformationOnImplementations();
	
EndProcedure

&AtClient
Procedure SelectionOfGoodsBySales()
	
	Cancel = False;
	ClearMessages();
	
	ReturnFromRetailCustomer = False;
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromRetailCustomer") Then
		ReturnFromRetailCustomer = True;
	EndIf;
	
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
	
	If Not ValueIsFilled(Object.VATTaxation)
		And Not Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromCommissionAgent") Then
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
	
	If Not UsePartnersAsCounterparties Then
		If Not ValueIsFilled(Object.Counterparty) Then
			CommonClientServer.MessageToUser(
			NStr("vi = 'Trường ""Đối tác"" chưa điền';
				|ru = 'Поле ""Контрагент"" не заполнено';
				|en = '""Counterparty"" is not filled in'; fa = '""Counterparty"" is not filled in';
				|it = 'Il campo ""Contraente"" non è compilato';
				|pl = 'Pole ""Kontrahent"" nie jest wypełnione';
				|tr = '""Cari hesap"" alanı doldurulmadı'"),
			Object.Ref, "Object.Counterparty",
			,
			Cancel);
		EndIf;
	EndIf;
	
	If ReturnOfGoodsViaCommissionAgent
		And Not ValueIsFilled(Object.CustomerPartner) Then
		CommonClientServer.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Khách hàng cuối""';
				|ru = 'Поле ""Конечный клиент"" не заполнено';
				|en = 'The ""End customer"" field is not filled in'; fa = 'The ""End customer"" field is not filled in';
				|it = 'Campo ""Cliente finale"" non compilato';
				|pl = 'Pole ""Nabywca końcowy"" nie jest wypełnione';
				|tr = '""Son müşteri"" alanı doldurulmamış'"),
			Object.Ref, "Object.CustomerPartner",
			,
			Cancel);
		EndIf;
		
	If Not UsePartnersAsCounterparties 
		And ReturnOfGoodsViaCommissionAgent Then
		If Not ValueIsFilled(Object.CustomerCounterparty) Then
			CommonClientServer.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Đối tác của khách hàng cuối""';
				|ru = 'Поле ""Контрагент конечного клиента"" не заполнено';
				|en = '""End customer counterparty"" is not filled in'; fa = '""End customer counterparty"" is not filled in';
				|it = 'Campo ""Controparte cliente finale"" non compilato';
				|pl = 'Pole ""Kontrahent nabywcy końcowego"" nie jest wypełnione';
				|tr = 'Lütfen, ""Son müşteri cari hesabı"" belirtin'"),
			Object.Ref, "Object.CustomerCounterparty",
			,
			Cancel);
		EndIf;
	EndIf;

	If Not Cancel Then
		
		PickingParameters = New Structure;
		PickingParameters.Insert("DocumentReturnPolicy", Object.Ref);
		PickingParameters.Insert("Currency", Object.Currency);
		PickingParameters.Insert("Date", ?(ValueIsFilled(Object.Date), Object.Date, CommonClient.SessionDate()));
		PickingParameters.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
		PickingParameters.Insert("Warehouse", Object.Warehouse);
		PickingParameters.Insert("FilterByWarehouse", True);
		PickingParameters.Insert("NotShowWarehouse", ReturnOfGoodsViaCommissionAgent);
		PickingParameters.Insert("VATTaxation", Object.VATTaxation);
		PickingParameters.Insert("Partner", Object.Partner);
		PickingParameters.Insert("Counterparty", Object.Counterparty);
		PickingParameters.Insert("Terms", Object.Terms);
		PickingParameters.Insert("Contract", Object.Contract);
		PickingParameters.Insert("Organization", Object.Organization);
		PickingParameters.Insert("ReturnFromRetailCustomer", ReturnFromRetailCustomer);
		PickingParameters.Insert("CashRegisterReceipt", Object.CashRegisterReceipt);
		PickingParameters.Insert("ShowProducts_", True);
		PickingParameters.Insert("ShowContainers", Not ReturnFromRetailCustomer And Object.ReusablePackageReturn);
		PickingParameters.Insert("LineOfBusiness", Object.LineOfBusiness);
		PickingParameters.Insert("DepositForPackageIsRequired", Object.DepositForPackageIsRequired);
		PickingParameters.Insert("CustomerPartner", Object.CustomerPartner);
		PickingParameters.Insert("CustomerCounterparty", Object.CustomerCounterparty);
		PickingParameters.Insert("CustomerContract", Object.CustomerContract);
		
		OpenForm(
			"CommonForm.SelectGoodsBySalesAndTransfers",
			PickingParameters,
			ThisForm);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenSelection(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.ReturnOfGoodsFromCustomer.DocumentForm.Command.OpenSelection");
	
	Cancel = False;
	If (ToUseTermsOfSales And Not ValueIsFilled(Object.Terms))
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
		HeaderParameter_ = StrReplace(HeaderParameter_, "%Document%", NStr("vi = 'nhận hàng bán bị trả lại';
																			|ru = 'возврат товаров от клиента';
																			|en = 'sales return'; fa = 'sales return';
																			|it = 'resi delle merci dal cliente';
																			|pl = 'zwrot towarów od klienta';
																			|tr = 'müşteriden mal iadesi'"));
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Terms",           Object.Terms);
	FormParameters.Insert("Organization",          Object.Organization);
	FormParameters.Insert("PriceIncludesVAT",      Object.PriceIncludesVAT);
	FormParameters.Insert("VATTaxation",   Object.VATTaxation);
	FormParameters.Insert("ReturnReusablePackage", Object.ReusablePackageReturn);
	FormParameters.Insert("Warehouse",                Object.Warehouse);
	FormParameters.Insert("Currency",               Object.Currency);
	FormParameters.Insert("Title",            HeaderParameter_);
	FormParameters.Insert("Date",                 Object.Date);
	FormParameters.Insert("SelectionModeUseWarehousesInTabularSection", True);
	FormParameters.Insert("Document",             Object.Ref);
	FormParameters.Insert("HideManualDiscounts", True);
	FormParameters.Insert("FilterByProductType", New FixedArray(ProductsClientServer.SelectionByProductMultiTurnContainer(True)));
	FormParameters.Insert("SeriesSpecificationParameters",SeriesSpecificationParameters);
	
	OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form", FormParameters, ThisForm, UUID);
	
EndProcedure

&AtClient
Procedure SelectGoodsByOrdersNotes(Command)
	
	OpenSelectionByOrdersOrders();
	
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
		
		CalculateReturnTotals(ThisForm);
		FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, AmountTotal);
		CalculateCompensationAmount(ThisForm);
	Else
		EquipmentManagerTMClient.ReportError(ExecutionResult);
	EndIf;
	
EndProcedure

&AtClient
Procedure ReturnOfSpoiledGoods(Command)
	
	If Object.ReturnOfSpoiledGoods Then 
		
		ThereAreLinesWithCorruption = CheckDisableConfigureFormForCorruption();
		
		If ThereAreLinesWithCorruption Then

			ShowQueryBox(New CallbackDescription("ReturnOfSpoiledGoodsCompletion", ThisObject), NStr("vi = 'Trong quá trình vận hành, thông tin về chất lượng của hàng trả lại sẽ bị xóa. Tiếp tục?';
																									|ru = 'При выполнении операции будет очищена информация о качестве возвращаемых товаров. Продолжить?';
																									|en = 'Item quality will be cleared. Do you want to continue?'; fa = 'Item quality will be cleared. Do you want to continue?';
																									|it = 'Quando si esegue l''operazione, le informazioni sulla qualità delle merci in reso verranno cancellate. Continuare?';
																									|pl = 'Podczas wykonania operacji będzie oczyszczona informacja o jakości zwracanych towarów. Kontynuować?';
																									|tr = 'İşlem, iade edilen malların kalitesi hakkındaki bilgileri temizleyecektir. Devam edilsin mi?'"),QuestionDialogMode.YesNo,,DialogReturnCode.Yes);
			
		EndIf;
		
	Else
		Object.ReturnOfSpoiledGoods = True;
		ConfigureFormForCorruption();
	EndIf;
		
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
		ProcessBarcodes(Result.TableOfGoods, True);
	Else
		EquipmentManagerTMClient.ReportError(Result);
	EndIf;
	
EndProcedure

&AtClient
Procedure SplitRow(Command)
	
	FormTable  = Items.Goods;
	TableData = Object.Goods;
	
	AdditionalParameters = AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfParametersForSplittingRowInTablePart(FormTable.CurrentData);
	
	Notification = New CallbackDescription("SplitRowCompletion", ThisObject, AdditionalParameters);
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, Notification);
	
EndProcedure

&AtClient
Procedure SpecifySeries(Command)
	
	OpenSelectionOfSeries();
	
EndProcedure

&AtClient
Procedure AttributesForReturnApplicationPrinting(Command)
	
	Try
		LockFormDataForEdit();
	Except
		ShowMessageBox(Undefined, BriefErrorDescription(ErrorInfo()));
		Return;
	EndTry;
	
	ParametersStructure = New Structure();
	ParametersStructure.Insert("ReadOnly",                      ReadOnly);
	ParametersStructure.Insert("Counterparty",                          Object.Counterparty);
	ParametersStructure.Insert("Customer",                          Object.Customer);
	ParametersStructure.Insert("CustomerSDateOfBirth",              Object.CustomerSDateOfBirth);
	ParametersStructure.Insert("ReasonForReturn",                     Object.ReasonForReturn);
	ParametersStructure.Insert("CustomerDocumentKind",              Object.CustomerDocumentKind);
	ParametersStructure.Insert("CustomerDocumentSeries",            Object.CustomerDocumentSeries);
	ParametersStructure.Insert("CustomerDocumentNumber",            Object.CustomerDocumentNumber);
	ParametersStructure.Insert("DateOfCustomerDocumentIssue",       Object.DateOfCustomerDocumentIssue);
	ParametersStructure.Insert("CustomerDocumentValidityPeriod",     Object.CustomerDocumentValidityPeriod);
	ParametersStructure.Insert("IssuingAuthorityOfCustomerDocument",          Object.IssuingAuthorityOfCustomerDocument);
	ParametersStructure.Insert("CustomerDocumentBusinessUnitCode", Object.CustomerDocumentBusinessUnitCode);
	ParametersStructure.Insert("DocumentDate",                       Object.Date);
	ParametersStructure.Insert("Organization",                         Object.Organization);
	
	OpenForm("DataProcessor.PrintApplicationForReturnOfGoodsFromCustomer.Form.AttributesForReturnApplicationPrinting", ParametersStructure, ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
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
Procedure FillInSalesAndPrices(Command)
	
	If Object["Goods"].Count() = 0 Then
		
		WarningText = NStr("vi = 'Chứng từ không hoàn thành danh sách hàng hóa. chứng từ bán hàng và giá cả không thể được điền vào.';
							|ru = 'В документе не заполнен список Товары. Документы продажи и цены не могут быть заполнены.';
							|en = 'The ""Goods"" list in the document is not filled in. Cannot fill in sales documents and prices.'; fa = 'The ""Goods"" list in the document is not filled in. Cannot fill in sales documents and prices.';
							|it = 'Nel documento non è compilato l''elenco Merci. I documenti di vendita e i prezzi non possono essere compilati.';
							|pl = 'W dokumencie nie wypełniono listy Wiersze pozycji. Dokumenty sprzedaży i ceny nie mogą być wypełnione.';
							|tr = 'Belgedeki Mal listesi eksiktir. Satış belgeleri ve fiyatlar doldurulamaz.'");
		ShowMessageBox(, WarningText);
		Return;
		
	EndIf;
	
	FillInSalesAndPricesServer();
	
EndProcedure

&AtClient
Procedure InsertRows(Command)
	
	NumberOfProductsBeforeInsertion = Object.Goods.Count();
	
	GetLinesFromClipboard();
	
	NumberOfInserted = Object.Goods.Count()-NumberOfProductsBeforeInsertion;
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
	
	FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, AmountTotal);
	CalculateCompensationAmount(ThisForm);
	
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
	ImportParameters.ImportPrices = True;
	ImportParameters.ImportCCD  = True;
	ImportParameters.PriceIncludesVAT    = Object.PriceIncludesVAT;
	ImportParameters.VATTaxation = Object.VATTaxation;
	ImportParameters.FillingDate     = Object.Date;
	ImportParameters.ThisIsReusablePackage  = Object.ReusablePackageReturn;
	ImportParameters.ComponentsPriceParameters.Date       = Object.Date;
	ImportParameters.ComponentsPriceParameters.Currency     = Object.Currency;
	ImportParameters.ComponentsPriceParameters.Terms = Object.Terms;
	ImportParameters.FilterParameters.Insert("ItemsType",
		ProductsClientServer.SelectionByProductMultiTurnContainer());

	Notification = New CallbackDescription("ImportFromExternalFileCompletion", ThisObject);
	ProcessingOfTabularFormsClient.ShowProductUploadForm(ImportParameters, Notification);
	
EndProcedure

&AtClient
Procedure ImportFromExternalFileCompletion(ImportedDataAddress, AdditionalParameters) Export

	If ValueIsFilled(ImportedDataAddress) Then
		GetUploadedProductsFromStorage(ImportedDataAddress);
		FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, AmountTotal);
		CalculateCompensationAmount(ThisForm);
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
	KitParameters.Insert("ProductsInSet", CurrentRow.ProductsInSet);
	KitParameters.Insert("ItemVariantOfSet", CurrentRow.ItemVariantOfSet);
	KitParameters.Insert("DocumentSalesOfGoodsAndServices", CurrentRow.DocumentSalesOfGoodsAndServices);
	KitParameters.Insert("DialColumns", DialColumns());
	
	SetAddressInTemporaryStorage = SetAddressInTemporaryStorage(KitParameters);
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("AddressInTempStorage", SetAddressInTemporaryStorage);
	OpeningParameters.Insert("ProductsInSet", CurrentRow.ProductsInSet);
	OpeningParameters.Insert("ItemVariantOfSet", CurrentRow.ItemVariantOfSet);
	OpeningParameters.Insert("DocumentSalesOfGoodsAndServices", CurrentRow.DocumentSalesOfGoodsAndServices);
	OpeningParameters.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
	OpeningParameters.Insert("VATTaxation", Object.VATTaxation);
	OpeningParameters.Insert("Currency", Object.Currency);
	OpeningParameters.Insert("Terms", Object.Terms);
	OpeningParameters.Insert("Date", Object.Date);
	OpeningParameters.Insert("Ref", Object.Ref);
	OpeningParameters.Insert("FilterByProductType", ProductsClientServer.SelectionByProductMultiTurnContainer());
	OpeningParameters.Insert("Warehouse", Object.Warehouse);
	OpeningParameters.Insert("HideCommandRemainingQuantityInWarehouses", False);
	If ValueIsFilled(Object.CashRegisterReceipt) Then
		OpeningParameters.Insert("PriceKind", ThisForm.CashReceiptPriceType);
		OpeningParameters.Insert("ProhibitPriceEditing", True);
	EndIf;
	OpeningParameters.Insert("Organization", Object.Organization);
	
	OpenForm("DataProcessor.EditSet.Form.Form", OpeningParameters, ThisForm, UUID);
	
EndProcedure

&AtClient
Procedure FillInTheCostPrice(Command)
	
	If Not ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items.Goods) Then
		Return;
	EndIf;
	
	FillInCostInTable();
	
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
Procedure CloseRequest(Command)
	
	If Modified Or Not Object.Posted Then
		Response = Undefined;
		ShowQueryBox(New CallbackDescription("CloseRequestCompletion", ThisObject),
		               NStr("vi = 'Bạn phải kết chuyển chứng từ để hoàn thành giao dịch. Kết chuyển chứng từ?';
							|ru = 'Необходимо провести документ для выполнения операции. Провести документ?';
							|en = 'To proceed, you need to post the document. Do you want to post the document?'; fa = 'To proceed, you need to post the document. Do you want to post the document?';
							|it = 'È necessario pubblicare il documento per eseguire operazione. pubblicare documento?';
							|pl = 'Należy zaksięgować dokument aby wykonać operację. Zaksięgować dokument?';
							|tr = 'Bir işlemin gerçekleştirilmesi için belgenin düzenlenmesi gerekir. Belge düzenlensin mi?'"),
		               QuestionDialogMode.YesNo);
		Return;
	EndIf;
	
	CloseRequestFragment();
	
EndProcedure

&AtClient
Procedure CloseRequestCompletion(QuestionResult, AdditionalParameters) Export
	
	ClearMessages();
	Response = QuestionResult;
	If Response = DialogReturnCode.No Then
		Return;
	ElsIf Not Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
		Return;
	EndIf;
	
	CloseRequestFragment();
	
EndProcedure

&AtClient
Procedure CloseRequestFragment()
	
	ListOfOrdersToClose = New ValueList;
	ListOfOrdersToClose.Add(Object.RequestForReturnOfGoodsFromCustomer);
	
	ClosureStructure = New Structure;
	ClosureStructure.Insert("Orders",                       ListOfOrdersToClose);
	ClosureStructure.Insert("DocumentInitiator",            Object.Ref);
	ClosureStructure.Insert("CancelUnprocessedLines", True);
	ClosureStructure.Insert("CloseOrders",              True);
	
	OpenForm("DataProcessor.OrderClosureWizard.Form.ClosureForm", 
	             ClosureStructure,,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure FillInTheGTDNumbersForSalesDocuments(Command)
	
	FillInCCDNumbers("ByReferences", "DocumentSalesOfGoodsAndServices");
	
EndProcedure

&AtClient
Procedure ToFillTheRoomGtdoTransferredToTheProductsTeam(Command)
	
	FillInCCDNumbers("ForBalancesTransferredToCommission");
	
EndProcedure

&AtClient
Procedure FillInVATRate(Command)

	If Object.Goods.Count() = 0 Then
		WarningText = NStr("vi = 'Trong danh sách ""Hàng hóa"" chưa điền dòng nào.';
							|ru = 'В список ""Товары"" не введено ни одной строки.';
							|en = 'No lines entered in the Item list.'; fa = 'No lines entered in the Item list.';
							|it = 'Nell''elenco ""Merci"" non è stata immessa alcuna riga.';
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

#EndRegion

#Region Private

&AtServer
Procedure SetVisibilityOfItemsAcrossMultipleWarehouses()

	Items.GroupLabelAndPictureSeveralWarehouses.Visible = WarehouseGroup_;

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

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Terms.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.BusinessTransactions.ReturnFromCommissionAgent;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Terms");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Terms.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.ReturnFromCommissionAgent;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Terms");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//
	
	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForSalesTaxation(ThisObject);

	//

	EnterprisePricesFillingServer.SetConditionalAppearancePriceIncludesVAT(ThisObject);
	
	// Setting the Conditional appearance of a different quality item.
	ConditionalDesignParameters = ProductsServer.ParametersOfConditionalAppearanceOfDifferentQualityItem();
	ConditionalDesignParameters.StockQualityChangeAttributeIsUsed = True;
	ConditionalDesignParameters.PathToStockQualityChangeField = "Object.Goods.Damage";
	
	ProductsServer.SetConditionalAppearanceOfDifferentQualityItem(ThisObject, ConditionalDesignParameters);
	
	//

	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject);

	//

	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisObject);

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
	ConditionalDesignParameters = ProductsServer.ParametersForSettingConditionalAppearanceOfCCDNumber();
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber = "GoodsCCDNumberOriginCountry";
	
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject);
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfCCDNumber(ThisObject);
	AccountingForTraceableGoodsLocalization.EstablishConditionalAppearanceOfAccountingOnGTDVDocumentsOfCommissionAgent(ThisObject, False);
	
	//
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfQuantityAccordingToRNPT(ThisObject);
	
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
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPrice.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSum.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAmountIncludingVAT.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsVATAmount.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsVATRate.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsProducts.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCharacteristic.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsProductsRecordingAsReceived.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCharacteristicRecordingAsReceived.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.RequestForReturnOfGoodsFromCustomer");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsMethodForDeterminingTheCostOfALine.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.ReturnFromCommissionAgent;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsMethodForDeterminingTheCostOfALine.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.CostDefiningMethod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.WaysToCalculateReturnCost.FromSalesDocument;
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDocumentSalesOfGoodsAndServices.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.DocumentSalesOfGoodsAndServices");
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
	ItemFilter.LeftValue = New DataCompositionField("Object.ReusablePackageReturn");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsProductsRecordingAsReceived.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsProductsRecordingAsReceivedItemsType.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsProductsRecordingAsReceivedCode.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductsNomenclatureRegistrationArticle.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCharacteristicRecordingAsReceived.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDamage.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.RequestForReturnOfGoodsFromCustomer");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReturnOfSpoiledGoods");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("ReadOnly", True);

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
	ItemFilter.RightValue = Enums.BusinessTransactions.ReturnFromCommissionAgent;

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
	ItemFilter.LeftValue = New DataCompositionField("Object.ReusablePackageReturn");
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
	ItemFilter.RightValue = Enums.BusinessTransactions.ReturnFromCommissionAgent;

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
	ItemFilter.LeftValue = New DataCompositionField("Object.ReusablePackageReturn");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DepositForPackageIsRequired");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisObject, False);

	//

	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisObject, False);

	//
	
	SetsServer.SetConditionalAppearance(ThisObject, "Goods");
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDocumentSalesOfGoodsAndServices.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsMethodForDeterminingTheCostOfALine.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.CashRegisterReceipt");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDocumentSalesOfGoodsAndServices.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.ReturnFromCommissionAgent;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ItemsTypes.ReusablePackage;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReusablePackageReturn");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//

	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDocumentSalesOfGoodsAndServices.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.CostDefiningMethod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.WaysToCalculateReturnCost.FromSalesDocument;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.BusinessTransactions.ReturnFromCommissionAgent;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không cần điền>';
													|ru = '<заполнение не требуется>';
													|en = '<filling is not required>'; fa = '<filling is not required>';
													|it = '<non da compilare>';
													|pl = '<wypełnienie nie jest wymagane>';
													|tr = '<doldurma gerekli değil>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisObject);

	//WarehouseGroup_ 
	
	WarehousesServer.SetConditionalAppearanceOfVTCHWarehouse(ThisForm);
	
	//TovarySklad - mark of an empty

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
	
	// Conditional appearance of quality control Attributes.
	Fields = QualityControl.Fields(
		Items.GoodsToControlQuality,
		Items.GoodsQualityConfirmationDate);
	QualityControl.SetupAppearance(ConditionalAppearance, Fields);
	
EndProcedure

#Region OnChangeAttributes

&AtServer
Procedure PartnerOnChangeServer()
	
	AttributesArray = New Array;
	
	If ToUseTermsOfSales Then
		FillIn_TermsOfSales();
		AttributesArray.Add("Currency");	
		AttributesArray.Add("Contract");
		AttributesArray.Add("LineOfBusiness");
		AttributesArray.Add("Counterparty");
		AttributesArray.Add("Organization");
		AttributesArray.Add("Terms");
	Else
		PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Partner, Object.Counterparty);
	EndIf;
	
	FillInServiceDetailsOfTablePart();
	
	SetContractVisibility();
	UseCustomerContracts = GetFunctionalOption("UseCustomerContracts");
	If UseCustomerContracts Then
		FillInDefaultContract();
	EndIf;
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "Partner", "ReadOnly", ValueIsFilled(Object.CashRegisterReceipt));
	
	UpdateTextOfInvoiceReceived();
	
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, Object.ReusablePackageReturn);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateReturnTotals(ThisForm);
	UpdateInformationOnImplementations();
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	
	AttributesArray.Add("Partner");
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, AttributesArray);
	
	GeneratingFiscalChecksServer.FormWhenChangingBankingDetails(ThisObject);
	
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	DocumentBasis = SalesServer.DocumentBasis(Object,
		"RequestForReturnOfGoodsFromCustomer, DocumentSalesOfGoodsAndServices, Goods.DocumentSalesOfGoodsAndServices");
	ResponsiblePersonsServer.InstallManager(Object, DocumentBasis);
	
	If QualityControl.UpdateActionParameters(
			Documents.ReturnOfGoodsFromCustomer,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure PartnerClearingServer()
	
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	DocumentBasis = SalesServer.DocumentBasis(Object,
		"RequestForReturnOfGoodsFromCustomer, DocumentSalesOfGoodsAndServices, Goods.DocumentSalesOfGoodsAndServices");
	ResponsiblePersonsServer.InstallManager(Object, DocumentBasis);
	
EndProcedure

&AtServer
Procedure TermsOnChangeServer()
	
	OldCurrency = DocumentCurrency;
	DocumentSales = FormAttributeToValue("Object");
	DocumentSales.FillInTermsOfSalesUnderAgreement();
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, DocumentSales);
	DocumentBasis = SalesServer.DocumentBasis(DocumentSales,
		"RequestForReturnOfGoodsFromCustomer, DocumentSalesOfGoodsAndServices, Goods.DocumentSalesOfGoodsAndServices");
	ResponsiblePersonsServer.InstallManager(DocumentSales, DocumentBasis);
	ValueToFormAttribute(DocumentSales, "Object");
	
	DocumentCurrency = Object.Currency;
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	
	SaleDate = ?(ValueIsFilled(Object.DocumentSalesOfGoodsAndServices), Common.ObjectAttributeValue(Object.DocumentSalesOfGoodsAndServices, "Date"), Object.Date);
	
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersFillInVATRate.Date = SaleDate;
	
	WarehouseGroup_ = ItIsGroupOfWarehousesAndWarehousesUsedByWHForSale(Object.Warehouse);
	WarehouseOnChangeServer();
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ReusablePackageReturn);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	StructureOfActions.Insert("FillInCostDeterminationMethodWithLine", CostDeterminationParameters(ThisObject));
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
	ExecuteRecalculateDocumentAmountsServer(OldCurrency, DocumentCurrency);
	BusinessOperationOnChangeServer();
	
	FillInServiceDetailsOfTablePart();
	
	FillSetVisibilityAndAvailabilityOfOverfillingOnAcceptance();
	
	SetContractVisibility();
	
	UpdateTextOfInvoiceReceived();

	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, Object.ReusablePackageReturn);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		"DepositForPackageIsRequired",
		"Enabled",
		Object.ReusablePackageReturn);
	
	CalculateReturnTotals(ThisObject);
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	If QualityControl.UpdateActionParameters(
			Documents.ReturnOfGoodsFromCustomer,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;

EndProcedure

&AtServer
Procedure TermsClearingServer()
	
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	DocumentBasis = SalesServer.DocumentBasis(Object,
		"RequestForReturnOfGoodsFromCustomer, DocumentSalesOfGoodsAndServices, Goods.DocumentSalesOfGoodsAndServices");
	ResponsiblePersonsServer.InstallManager(Object, DocumentBasis);
	
EndProcedure

&AtServer
Procedure BusinessOperationOnChangeServer()
	
	ReturnOfGoodsViaCommissionAgent = ConsignmentSalesServer.ReturnOfGoodsViaCommissionAgent(Object.BusinessOperation);
	UseLinesOfBusiness = UseLinesOfBusiness And Not ReturnOfGoodsViaCommissionAgent;
	
	FillInCommissionAgentDoesNotKeepRecordsOfRPTOnServer();
	EstablishRelationshipsBetweenContractSelectionParameters();
	
	ContractBusinessTransaction = GetBusinessTransaction(Object.BusinessOperation);
	NewEconomicOperationOfAgreement = SelfServiceClientServer.BusinessTransactionFromAgreement(Object.BusinessOperation);
	
	If ToUseTermsOfSales
		And NewEconomicOperationOfAgreement <> BusinessTransactionFromAgreement Then
		
		BusinessTransactionFromAgreement = NewEconomicOperationOfAgreement;
		Object.Terms = Undefined;
		
	EndIf;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent Then
		
		Object.ARAPDetails.Clear();
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromRetailCustomer Then
		
		Object.SalesOpportunity = Catalogs.SalesOpportunitiesToCustomer.EmptyRef();
		Object.ReusablePackageReturn = False;
		Object.DepositForPackageIsRequired = False;
		ReusablePackageReturnOnChangeServer();
		Object.CompensationMethod = Enums.CompensationMethodsForReturnsOfGoods.ReturnCash;
		
	EndIf;
		
	If Object.BusinessOperation <> Enums.BusinessTransactions.ReturnFromRetailCustomer Then
		Object.CashIssued = False;
		Object.CashAccountIssueNoteDate = Undefined;
		Object.CashAccountIssueNoteNumber = "";
	EndIf;
	
	UpdateTextOfInvoiceReceived();
	
	SetConditionalAppearance();
	SetVisibilityOfElementsByOperationServer();
	SetAvailabilityOfDetailsOfSpendingCashOrderServer();
	SetAvailabilityOfCompensationMethod(ThisObject);
	CalculateReturnTotals(ThisObject);
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisObject);
	
EndProcedure

&AtServer
Procedure WhenBusinessOperationIsChangedInteractivelyServer()
	
	Object.CashRegisterReceipt = Undefined;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromRetailCustomer Then
	
		PartnerChanged = False;
		
		Object.ReusablePackageReturn = False;
		Object.DepositForPackageIsRequired = False;
		ReusablePackageReturnOnChangeServer();
		
		If Object.Partner <> Catalogs.Partners.RetailCustomer Then
			Object.Partner = Catalogs.Partners.RetailCustomer;
			PartnerChanged = True;
		EndIf;
				
		If PartnerChanged Then
			
			If ValueIsFilled(Object.Counterparty) Then
				Object.Counterparty = Catalogs.Counterparties.EmptyRef();
			EndIf;
			
			PartnerOnChangeServer();
			SetVisibilityOfElementsByOperationServer();
			FillInDefaultContract();
			UpdateInformationOnImplementations();
			Return;
			
		EndIf;
		
	EndIf;
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "Partner", "ReadOnly", ValueIsFilled(Object.CashRegisterReceipt));
	
	BusinessOperationOnChangeServer();
	FillInDefaultContract();
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();
	
	UpdateInformationOnImplementations();
	
EndProcedure

&AtServer
Procedure CurrencyOnChangeServer(NewCurrency, RecalculatePrices_ = True)
	
	FillInDefaultContract();
	
	OldCurrency = DocumentCurrency;
	ExecuteRecalculateDocumentAmountsServer(OldCurrency, NewCurrency);
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, Object.ReusablePackageReturn);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateReturnTotals(ThisForm);
	FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, AmountTotal);
	CalculateCompensationAmount(ThisForm);
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Currency");
	If QualityControl.UpdateActionParameters(
			Documents.ReturnOfGoodsFromCustomer,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	SetContractVisibility();
	
	If ValueIsFilled(Object.Organization) Then
		
		FillInDefaultContract();
		
		UpdateTextOfInvoiceReceived();
		
		FillInSalesVATTaxation();
		VATTaxationOnChangeServer();
		
	EndIf;
	
	For Each LineProducts_ In Object.Goods Do
		LineProducts_.CostDefiningMethod = Enums.WaysToCalculateReturnCost.FromCurrentDocument;
	EndDo;
	EstablishCostPresentation();
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Organization");
	
	DocumentBasis = SalesServer.DocumentBasis(Object,
		"RequestForReturnOfGoodsFromCustomer, DocumentSalesOfGoodsAndServices, Goods.DocumentSalesOfGoodsAndServices");
	ResponsiblePersonsServer.InstallManager(Object, DocumentBasis);
	
	RecalculateNumberOfRNPT();
	ExcisableGoodsAccounting.UpdateElementsOfAccountingForExcisableItems(ThisObject);
	If QualityControl.UpdateActionParameters(
			Documents.ReturnOfGoodsFromCustomer,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure WarehouseOnChangeServer(DirectModificationOfWarehouseField = False)
	
	WarehouseGroup_ = ItIsGroupOfWarehousesAndWarehousesUsedByWHForSale(Object.Warehouse);
	
	SetParametersForSelectingProductsWarehouse();
	
	WarehousesServer.FillInWarehousesInTablePart(Object.Warehouse, WarehouseGroup_, Object.Goods, True);
	
	DeterminePresenceOfOrderScheme();
	SetTitleAvailabilityPickUpProductsByOrdersOrders();   

	SetVisibilityOfItemsAcrossMultipleWarehouses();
	
	WhenChangingWarehouseInTablePartServer();
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();
	
	FillSetVisibilityAndAvailabilityOfOverfillingOnAcceptance();
	
	RecalculateNumberOfRNPT();
	If QualityControl.UpdateActionParameters(
			Documents.ReturnOfGoodsFromCustomer,
			Object,
			CacheQualityControl,
			DirectModificationOfWarehouseField) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	
	SetContractVisibility();
	
	If ValueIsFilled(Object.Counterparty) Then
		FillInDefaultContract();
	EndIf;
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Counterparty");
	
	GeneratingFiscalChecksServer.FormWhenChangingBankingDetails(ThisObject);
	PurchasesServer.FillInSelectionListNameOfIncomingDocument(ThisObject, Object.Counterparty);
	If QualityControl.UpdateActionParameters(
			Documents.ReturnOfGoodsFromCustomer,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure PriceIncludesVATOnChangeServer(CachedValues)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods,StructureOfActions, CachedValues);
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateReturnTotals(ThisForm);
	
EndProcedure

&AtServer
Procedure VATTaxationOnChangeServer()
	
	CachedValuesInternal = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActions = New Structure;
	ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object, False, Object.ReusablePackageReturn);
	If ValueIsFilled(Object.DocumentSalesOfGoodsAndServices) Then
		ParametersForFillingInVATRate.Date = Common.ObjectAttributeValue(Object.DocumentSalesOfGoodsAndServices, "Date");
	EndIf;
	StructureOfActions.Insert("AdjustVATRate", ParametersForFillingInVATRate);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValuesInternal);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValuesInternal.ProcessedRows,
		StructureOfActions,
		Object.Goods,
		Undefined);
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateReturnTotals(ThisForm);

	VATAccountingERP.SetVisibilityOfCommandAndFillInVATRate(ThisObject);

EndProcedure

&AtServer
Procedure DateOnChangeServer()
	
	UseTraceableImportedGoodsAccounting =
		AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(Object.Date);
	
	AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(ThisForm, Object.Date);
	
	If Not Items.ProductsGroupQuantityByRNPT.Visible Then
		RecalculateNumberOfRNPT();
	EndIf;
	
	DeterminePresenceOfOrderScheme();
	SetTitleAvailabilityPickUpProductsByOrdersOrders();
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();
	
	UpdateTextOfInvoiceReceived();
	
	FillSetVisibilityAndAvailabilityOfOverfillingOnAcceptance();
	ExcisableGoodsAccounting.UpdateElementsOfAccountingForExcisableItems(ThisObject);
	If QualityControl.UpdateActionParameters(
			Documents.ReturnOfGoodsFromCustomer,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure DateOfReceiptOnChangeServer()
	
	If QualityControl.UpdateActionParameters(
			Documents.ReturnOfGoodsFromCustomer,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ContractOnChangeServer(DirectModificationOfContractField = False)
	
	Contract = Object.Contract;
	
	If ValueIsFilled(Object.Contract) Then
		Object.ForeignCurrencyTransaction = Common.ObjectAttributeValue(Object.Contract, "ForeignCurrencyTransaction");
	EndIf;
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	
	FillInDefaultEndClientContract();
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Contract");
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisObject);
	
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	DocumentBasis = SalesServer.DocumentBasis(Object,
		"RequestForReturnOfGoodsFromCustomer, DocumentSalesOfGoodsAndServices, Goods.DocumentSalesOfGoodsAndServices");
	ResponsiblePersonsServer.InstallManager(Object, DocumentBasis);
	If QualityControl.UpdateActionParameters(
			Documents.ReturnOfGoodsFromCustomer,
			Object,
			CacheQualityControl,
			DirectModificationOfContractField) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure LineOfBusinessOnChangeServer()
	
	If Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts Then
		FillInDefaultContract();
	EndIf;
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();
	
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "LineOfBusiness");
	If QualityControl.UpdateActionParameters(
			Documents.ReturnOfGoodsFromCustomer,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure PartnerClientWhenChangingOnServer()
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.CustomerPartner, Object.CustomerCounterparty);
	ClientCounterpartyWhenChangingOnServer();
	If QualityControl.UpdateActionParameters(
			Documents.ReturnOfGoodsFromCustomer,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;

EndProcedure

&AtServer
Procedure ClientCounterpartyWhenChangingOnServer()
	
	FillInDefaultEndClientContract();
	ClientAgreesOnChangeOnServer();

EndProcedure

&AtServer
Procedure ClientAgreesOnChangeOnServer()
	
	UpdateInformationOnImplementations();
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Contract");
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisObject);
	
EndProcedure

// Parameters:
// 	SelectionResult - Structure - goods row data:
// 		* RowsOfProductsTable - Array of See TMCommonUseClient.NewElementArrayProducts
// 	AdditionalParameters - Undefined - not analyzed
&AtClient
Procedure ChoosingMethodForDeterminingCostOfProduction(SelectionResult, AdditionalParameters) Export
	
	If TypeOf(SelectionResult) = Type("Structure") Then
		Rows = SelectionResult.RowsOfProductsTable;
		For Each String In Rows Do
			TableRow = Object.Goods.FindByID(String.Id);
			If TableRow <> Undefined Then
				FillPropertyValues(TableRow, String);
			EndIf;
		EndDo;
		UpdateInformationOnImplementations();
		Modified = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region SelectionAndProcessingOfQuantityVerification

&AtClient
Procedure OpenSelectionByOrdersOrders()
	
	HeaderAttributes = New Structure("Organization, Warehouse, Organization, Department, BusinessOperation, GoodsReceiptOption, Ref");
	FillPropertyValues(HeaderAttributes, Object);
	
	AdditionalFields = New Structure;
	AdditionalFields.Insert("DateOfReceipt");
	
	FormParameters = New Structure();
	FormParameters.Insert("HeaderAttributes",				HeaderAttributes);
	FormParameters.Insert("OrderDocument",						Object.RequestForReturnOfGoodsFromCustomer);
	FormParameters.Insert("AdvancedWarehousingOnShipment",		False);
	FormParameters.Insert("AdvancedWarehousingOnGoodsReceipt",	AdvancedWarehousing);
	FormParameters.Insert("InvoiceForOrders",			ValueIsFilled(Object.RequestForReturnOfGoodsFromCustomer));
	FormParameters.Insert("AddressGoods",					AddressInvoiceGoods());
	FormParameters.Insert("AddressBarcodesOfPackages",		AddressBarcodesOfPackages());
	FormParameters.Insert("Invoice",					Object.Ref);
	FormParameters.Insert("UseInvoicesForSeveralOrders", False);
	FormParameters.Insert("OrdersAreUsed",			True);
	FormParameters.Insert("AdditionalFields",			AdditionalFields);
	
	OpenForm("CommonForm.AddItemsFromSalesOrderGoodsIssue",
		FormParameters, ThisForm, UUID,,,,FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure CheckQuantityInTheDocument(Command)
	
	CheckQuantityInTheDocumentClient();
	
EndProcedure

&AtClient
Procedure CheckQuantityInTheDocumentClient()
	
	OnlyNonLabeledProductsHaveBeenUnloaded = True;
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("AddressInTempStorage",             AddressInvoiceGoods(OnlyNonLabeledProductsHaveBeenUnloaded));
	OpeningParameters.Insert("TabularSectionName",                     "Goods");
	OpeningParameters.Insert("Ref",                                Object.Ref);
	OpeningParameters.Insert("GoodsQuantityExcessIsAllowed",  Not ValueIsFilled(Object.RequestForReturnOfGoodsFromCustomer));
	OpeningParameters.Insert("SeriesSpecificationParameters",                SeriesSpecificationParameters);
	OpeningParameters.Insert("Warehouse",                                 Object.Warehouse);
	OpeningParameters.Insert("CalculateSets",                    True);
	OpeningParameters.Insert("OnlyNonLabeledProductsHaveBeenUnloaded", OnlyNonLabeledProductsHaveBeenUnloaded);

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
		
		CalculateReturnTotals(ThisForm);
		FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, AmountTotal);
		CalculateCompensationAmount(ThisForm);
		
	EndIf;

EndProcedure

&AtClient
Procedure ReportErrorsWhenOpeningSelection(Cancel)
	
	If ToUseTermsOfSales And Not ValueIsFilled(Object.Terms) Then
		CommonClientServer.MessageToUser(NStr("vi = 'Chưa điền trường ""Thỏa thuận""';
												|ru = 'Поле ""Соглашение"" не заполнено';
												|en = '""Terms of sales"" are not filled'; fa = '""Terms of sales"" are not filled';
												|it = 'Il campo ""Accordo"" non è compilato';
												|pl = 'Pole ""Porozumienie"" nie jest wypełnione';
												|tr = '""Anlaşma"" alanı doldurulmamış'"), Object.Ref, "Object.Terms",,Cancel);
	EndIf;
	
	If Not ValueIsFilled(Object.Currency) Then
		CommonClientServer.MessageToUser(NStr("vi = 'Chưa điền trường ""Tiền tệ""';
												|ru = 'Поле ""Валюта"" не заполнено';
												|en = '""Currency"" is required'; fa = '""Currency"" is required';
												|it = 'Il campo ""Valuta"" non è compilato';
												|pl = 'Pole ""Waluta"" nie jest wypełnione';
												|tr = '""Para Birimi"" alanı doldurulmadı'"), Object.Ref, "Object.Currency",,Cancel);
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessingSelectionSelectionByImplementationServer(ValueSelected)
	
	ReturnValueStructure = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	TableOfGoods = ReturnValueStructure.Goods;
	HeaderStructure_ = ReturnValueStructure.HeaderStructure_;
	
	ReturnFromRetailCustomer = (Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromRetailCustomer);
	QuantityOfGoodsInitially = Object.Goods.Count();
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		CurrentRow.DocumentSalesOfGoodsAndServices = RowOfProduct.SaleTransferDocument;
		FillPropertyValues(CurrentRow, RowOfProduct);
		CurrentRow.Price = CurrentRow.Sum / CurrentRow.NumberOfPackages;
		If ReturnFromRetailCustomer Then
			CurrentRow.DocumentSalesOfGoodsAndServices = GetReportOnRetailSalesByCashRegisterReceipt(RowOfProduct.SaleTransferDocument);
			CurrentRow.CostDefiningMethod = Enums.WaysToCalculateReturnCost.FromSalesDocument;
		ElsIf ValueIsFilled(CurrentRow.DocumentSalesOfGoodsAndServices) Then
			CurrentRow.CostDefiningMethod = Enums.WaysToCalculateReturnCost.FromSalesDocument;
		Else
			CurrentRow.CostDefiningMethod = Enums.WaysToCalculateReturnCost.FromCurrentDocument;
		EndIf;
		
		If ValueIsFilled(Object.Warehouse)
			And Not (ValueIsFilled(RowOfProduct.Warehouse) And WarehouseGroup_) Then
			CurrentRow.Warehouse = Object.Warehouse;
		EndIf;
		
	EndDo;
	
	Object.Partner = HeaderStructure_.Partner;
	If ValueIsFilled(HeaderStructure_.CashRegisterReceipt) Then
		If Not ValueIsFilled(Object.CashRegisterReceipt) And QuantityOfGoodsInitially=0 Then
			Object.CashRegisterReceipt = HeaderStructure_.CashRegisterReceipt;
			Object.Partner = Common.ObjectAttributeValue(Object.CashRegisterReceipt, "Partner");
			PartnerOnChangeServer();
		EndIf;
	EndIf;
	
	FillInServiceDetailsOfTablePart();
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInCostDeterminationMethodWithLine", CostDeterminationParameters(ThisForm));
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(ThisForm, StructureOfActions);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);

	UpdateInformationOnImplementations();
	
	WhenChangingWarehouseInTablePartServer();
	
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, Object.ReusablePackageReturn);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateReturnTotals(ThisForm);
	
	SetVisibilityOfElementsAccordingToImplementationDocuments();
	OrderOfReflection = OrderOfReflection(Object.RecordInProfitLossOfPreviousYears);
	Items.ReflectionInAccounting_.Title = TitleOfReflectionInAccounting(Object.RecordInProfitLossOfPreviousYears);
	
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	ItIsRequiredToUpdateTitleIsSubjectToExciseDuty = UseExcisableGoods;
EndProcedure

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected)
	
	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	If ValueIsFilled(Object.DocumentSalesOfGoodsAndServices) Then
		ParametersFillInVATRate.Date = Common.ObjectAttributeValue(Object.DocumentSalesOfGoodsAndServices, "Date");
	EndIf;
	ListOfProperties = "ProductsInSet, ItemVariantOfSet, Products, Characteristic, 
				|ItemVariantsAreUsed, Package, Price, NumberOfPackages, Series";
	If ValueIsFilled(Object.Warehouse) Then
		ListOfProperties = ListOfProperties + ", Warehouse";
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ReusablePackageReturn);
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ReusablePackageReturn);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject);
	StructureOfActions.Insert("FillInMethodForDeterminingCost",Enums.WaysToCalculateReturnCost.FromCurrentDocument);
	StructureOfActions.Insert("FillInCostDeterminationMethodWithLine", CostDeterminationParameters(ThisObject));
	RowsToProcess = New Array();
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct,ListOfProperties);
		CurrentRow.SetIndex = ?(ValueIsFilled(CurrentRow.ProductsInSet), 1, 0);
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	FillInServiceDetailsOfTablePart();
	WhenChangingWarehouseInTablePartServer();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);  
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateReturnTotals(ThisForm);
	
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	ItIsRequiredToUpdateTitleIsSubjectToExciseDuty = UseExcisableGoods;
EndProcedure

#EndRegion

#Region BarcodesAndTradeEquipment

&AtClient
Procedure ProcessBarcodes(BarcodeData_5, LoadingFromPDT = False)
	
	ClearMessages();
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
		Return;
	EndIf;
	
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	If ValueIsFilled(Object.DocumentSalesOfGoodsAndServices) Then
		ParametersFillInVATRate.ByCorrectionDate = True;
		ParametersFillInVATRate.CorrectedDocument = Object.DocumentSalesOfGoodsAndServices;
	EndIf;
	StructureOfActionsWithAddedStrings = New Structure;
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsWithAddedStrings.Insert("CheckFillWarehouse",
		BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	
	StructureOfActionsWithAddedStrings.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActionsWithAddedStrings.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActionsWithAddedStrings.Insert("FillInVATRateForReturnableContainers", Object.ReusablePackageReturn);
	StructureOfActionsWithAddedStrings.Insert("FillInNoReturnContainerAttribute", Object.ReusablePackageReturn);
	StructureOfActionsWithAddedStrings.Insert("FillInMethodForDeterminingCost", 
		PredefinedValue("Enum.WaysToCalculateReturnCost.FromCurrentDocument"));
	StructureOfActionsWithAddedStrings.Insert("FillInCostDeterminationMethodWithLine", CostDeterminationParameters(ThisObject));
	StructureOfActionsWithAddedStrings.Insert("FillInCheckQualityDateOfQualityConfirmation",
		CacheQualityControl);
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActionsWithAddedStrings);
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithAddedStrings, ThisObject);
	If (ToUseTermsOfSales And ValueIsFilled(Object.Terms)) 
		Or (Not ToUseTermsOfSales And UsePriceManagementSystem25) Then
		StructureOfActionsWithAddedStrings.Insert("FillIn_TermsOfSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
	EndIf;
	
	StructureOfActionsWithModifiedStrings = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithModifiedStrings, ThisObject);
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	StructureOfActions.SeriesSpecificationParameters                 = SeriesSpecificationParameters;
	StructureOfActions.ChangeQuantity                     = Not ValueIsFilled(Object.RequestForReturnOfGoodsFromCustomer);
	StructureOfActions.GoodsOnly                           = True;
	StructureOfActions.CalculateSets                     = True;
	StructureOfActions.WHBarcodes                           = True;
	StructureOfActions.LoadingFromPDT                          = LoadingFromPDT;
	
	ProcessBarcodesServer(StructureOfActions, CachedValues);
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(StructureOfActions, CachedValues, ThisObject);
	
	If BarcodingOfItemsClient.YouNeedToOpenFormForSpecifyingSeriesAfterProcessingBarcodes(StructureOfActions) Then
		CurDataId = StructureOfActions.ArrayOfRowsWithSeries_[0];
		
		AttachIdleHandler("OpenSeriesSelectionWhenScanningProductBarCode", 0.1, True);
	EndIf;
	
	CalculateReturnTotals(ThisObject);
	FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, AmountTotal);
	CalculateCompensationAmount(ThisObject);
	
	If StructureOfActions.CurrentRow <> Undefined Then
		Items.Goods.CurrentRow = StructureOfActions.CurrentRow;
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessBarcodesServer(StructureOfActionParameters, CachedValues)
	
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject, Object, StructureOfActionParameters, CachedValues);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	CalculateReturnTotals(ThisObject);
	ItIsRequiredToUpdateTitleIsSubjectToExciseDuty = UseExcisableGoods;
EndProcedure

#EndRegion

#Region SetOfSeries

&AtServer
Procedure SetVisibilityOfSeriesElements()
	
	Items.GoodsBatchesIndicationStatus.Visible = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsSpecifySeries.Visible        = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsSeries.Visible               = SeriesSpecificationParameters.UseItemsBatch;
	
EndProcedure

&AtServer
Procedure ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("UpdateNumberOfProductsWhenRegistering", True);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisForm);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	ProductsServer.ProcessSeriesIndication_(Object,SeriesSpecificationParameters,ParametersOfSeriesIndicationForm,StructureOfActions);
	CalculateReturnTotals(ThisForm);
	FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, AmountTotal);

EndProcedure

&AtServer
Procedure FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues)
	
	ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Object, 
				SeriesSpecificationParameters, IDCurrentRow, CachedValues);
	
EndProcedure

&AtServer
Function ParametersOfSeriesIndicationForm(CurDataId)
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(Object, SeriesSpecificationParameters, CurDataId, ThisForm);
	
EndFunction

&AtClient
Procedure OpenSelectionOfSeries(Text = "", CurrentData = Undefined, NotificationOnCompletion = Undefined)
	
	If ProductsClient.YouNeedServerCallToSpecifySeries(ThisObject,SeriesSpecificationParameters,Text, CurrentData)Then
		
		If CurrentData = Undefined Then
			CurDataId = Items.Goods.CurrentData.GetID();
		Else
			CurDataId = CurrentData.GetID();
		EndIf;

		ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm(CurDataId);
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("ParametersOfSeriesIndicationForm", ParametersOfSeriesIndicationForm);
		AdditionalParameters.Insert("NotificationOnCompletion", NotificationOnCompletion);
		
		OpenForm(
			ParametersOfSeriesIndicationForm.FormName,
			ParametersOfSeriesIndicationForm,
			ThisObject,,,,
			New CallbackDescription("OpenSelectionOfSeriesCompletion", ThisObject, AdditionalParameters),
			FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenSelectionOfSeriesCompletion(Result, AdditionalParameters) Export
	
	ParametersOfSeriesIndicationForm = AdditionalParameters.ParametersOfSeriesIndicationForm;
	
	If Result <> Undefined Then
		ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm);
	EndIf;
	
	If AdditionalParameters.Property("NotificationOnCompletion") Then
		RunCallback(AdditionalParameters.NotificationOnCompletion);
	EndIf;

	ProductsSeriesRecalculatePrices();
	
EndProcedure

&AtClient
Procedure OpenSeriesSelectionWhenScanningProductBarCode()
	
	If CurDataId = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.Goods.FindByID(CurDataId);
	OpenSelectionOfSeries(,CurrentData);
	
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
		AddActionsToStructureWhenChangingPackagesNumber(ProcessingActions, ThisObject);
	Else
		AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(ProcessingActions, ThisObject);
	EndIf;
	
	PurchasesServer.ProcessIndicationOfCCDNumber(ThisObject,
												RowID,
												SelectionData_1,
												CCDNumbersFilledIn,
												Undefined,
												ProcessingActions);
	
	CalculateReturnTotals(ThisObject);
	FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, AmountTotal);
	CalculateCompensationAmount(ThisObject);
	
EndProcedure

&AtClient
Procedure FillInCCDNumbers(DataAcquisitionOption, NameOfOrderField = "")
	
	ThereAreFilledInCCDNumbers = False;
	
	For Each RowOfGoods In Object.Goods Do
		If ValueIsFilled(RowOfGoods.CCDNumber) Then
			ThereAreFilledInCCDNumbers = True;
			
			Break;
		EndIf;
	EndDo;
	
	If ThereAreFilledInCCDNumbers Then
		NotificationParameters	= New Structure("DataAcquisitionOption, NameOfOrderField",
												DataAcquisitionOption, NameOfOrderField);
		CallbackDescription	= New CallbackDescription("FillInCCDNumbersCompletion", ThisObject, NotificationParameters);
		
		QueryText = NStr("vi = 'Số TKHQ sẽ được xóa và điền lại. Tiếp tục?';
						|ru = 'Будут очищены и перезаполнены номера ГТД. Продолжить?';
						|en = 'CCD numbers will be cleared and refilled. Continue?'; fa = 'CCD numbers will be cleared and refilled. Continue?';
						|it = 'I numeri delle polizze doganali di carico verranno eliminati e reinseriti. Continuare?';
						|pl = 'Numery LP zostaną wyczyszczone i uzupełnione. Kontynuować?';
						|tr = 'GKB numaraları silinecek ve yeniden doldurulacaktır. Devam edilsin mi?'");
		
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	Else
		FillInCCDNumbersServer(DataAcquisitionOption, NameOfOrderField);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInCCDNumbersCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		DataAcquisitionOption	= AdditionalParameters.DataAcquisitionOption;
		NameOfOrderField		= AdditionalParameters.NameOfOrderField;
		
		FillInCCDNumbersServer(DataAcquisitionOption, NameOfOrderField);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInCCDNumbersServer(DataAcquisitionOption, NameOfOrderField)
	
	FillParameters = PurchasesServer.ParametersForFillingInCCDNumbersBasedOnCredentials();
	
	QueryOptions = FillParameters.QueryOptions;
	QueryOptions.Ref = Object.Ref;
	
	If DataAcquisitionOption = "ByReferences" Then
		FillParameters.NameOfOrderField = NameOfOrderField;
	Else
		
		PeriodDate_	= EndOfDay(CurrentSessionDate());
		Period		= New Boundary(PeriodDate_, BoundaryType.Including);
		
		QueryOptions.Period		= Period;
		QueryOptions.Partner	= Object.Partner;
		
		If DataAcquisitionOption = "ForBalancesTransferredToCommission" Then
			QueryOptions.Organization = Object.Organization;
		EndIf;
		
	EndIf;
	
	ParametersForRecalculatingAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	ActionsWithString = New Structure;
	ActionsWithString.Insert("RecalculateAmount");
	ActionsWithString.Insert("RecalculateVATAmount",	ParametersForRecalculatingAmount);
	ActionsWithString.Insert("RecalculateAmountWithVAT",	ParametersForRecalculatingAmount);
	ActionsWithString.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(ThisObject, ActionsWithString);
	
	FillParameters.ActionsWithString = ActionsWithString;
	
	PurchasesServer.FillInCCDNumbersAccordingToCredentials(Object.Goods, DataAcquisitionOption, FillParameters);
	
	CalculateReturnTotals(ThisObject);
	FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, AmountTotal);
	CalculateCompensationAmount(ThisObject);
	
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
	
	Return InformationRegisters.AnotherQualityGoods.CheckForGradation(ProductOfOriginalQuality, NonconformingProducts);
	
EndFunction

#EndRegion

#Region Sets

&AtClientAtServerNoContext
Function DialColumns()
	
	Columns = New Array;
	Columns.Add("Products");
	Columns.Add("Characteristic");
	
	Columns.Add("Price");
	Columns.Add("Package");
	Columns.Add("Count");
	Columns.Add("NumberOfPackages");
	
	Columns.Add("VATRate");
	Columns.Add("VATAmount");
	Columns.Add("AmountIncludingVAT");
	Columns.Add("Sum");

	Columns.Add("DocumentSalesOfGoodsAndServices");

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
	
	SetVisibilityOfElementsAccordingToImplementationDocuments();
	OrderOfReflection = OrderOfReflection(Object.RecordInProfitLossOfPreviousYears);
	Items.ReflectionInAccounting_.Title = TitleOfReflectionInAccounting(Object.RecordInProfitLossOfPreviousYears);
	
	CalculateReturnTotals(ThisForm);
	FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, AmountTotal);
	CalculateCompensationAmount(ThisForm);
	
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
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsWithAddedStrings.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActionsWithAddedStrings.Insert("FillInNoReturnContainerAttribute", Object.ReusablePackageReturn);
	StructureOfActionsWithAddedStrings.Insert("FillInDuplicateDependentDetails", DependentDetails());
	StructureOfActionsWithAddedStrings.Insert("CheckFillWarehouse",
		BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	StructureOfActionsWithAddedStrings.Insert("FillInCheckQualityDateOfQualityConfirmation",
		CacheQualityControl);
	
	If (ToUseTermsOfSales And ValueIsFilled(Object.Terms)) 
		Or (Not ToUseTermsOfSales And UsePriceManagementSystem25) Then
		StructureOfActionsWithAddedStrings.Insert("FillIn_TermsOfSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
	EndIf;
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActionsWithAddedStrings);

	StructureOfActionsWithModifiedStrings = New Structure;
	StructureOfActionsWithModifiedStrings.Insert("FillInDuplicateDependentDetails", DependentDetails());

	DataParameters = New Structure;
	DataParameters.Insert("Data", GetFromTempStorage(AddressInTempStorage));
	DataParameters.Insert("StructureOfActionsWithModifiedStrings", StructureOfActionsWithModifiedStrings);
	DataParameters.Insert("StructureOfActionsWithAddedStrings", StructureOfActionsWithAddedStrings);
	DataParameters.Insert("DialColumns", DialColumns());
	
	SetsServer.AtEndOfEditingSet(ThisForm, "Goods", DataParameters);
	
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
	CalculateReturnTotals(ThisForm);
	FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, AmountTotal);
	CalculateCompensationAmount(ThisForm);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	ItIsRequiredToUpdateTitleIsSubjectToExciseDuty = UseExcisableGoods;
EndProcedure

#EndRegion

#Region Other

&AtServerNoContext
Function ItIsGroupOfWarehousesAndWarehousesUsedByWHForSale(Warehouse)
	
	Return Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWHForSales(Warehouse);
	
EndFunction 

&AtServer
Procedure ProductsAfterDeletionOnServer(SeriesStatusesNeedToBeUpdated, CachedValues)
	
	If SeriesStatusesNeedToBeUpdated Then
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Undefined, CachedValues);
	EndIf;
	
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
	UpdateInformationOnImplementations();
	CalculateReturnTotals(ThisForm);
	FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, AmountTotal);
	CalculateCompensationAmount(ThisForm);
	ItIsRequiredToUpdateTitleIsSubjectToExciseDuty = UseExcisableGoods;
EndProcedure

&AtClient
Procedure Attachable_CloseForm()
	
	If IsOpen() Then
		Close();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	UseReturnRequests			= GetFunctionalOption("UseRequestsForReturnOfGoodsFromCustomers");
	ToUseTermsOfSales	= GetFunctionalOption("ToUseTermsOfSales");
	UseLinesOfBusiness	= GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness");
	ReturnOfGoodsViaCommissionAgent		= ConsignmentSalesServer.ReturnOfGoodsViaCommissionAgent(Object.BusinessOperation);
	UseLinesOfBusiness = UseLinesOfBusiness And Not ReturnOfGoodsViaCommissionAgent;
	
	UseTraceableImportedGoodsAccounting =
		AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(Object.Date);
	
	ManagementAccountingCurrency = Constants.ManagementAccountingCurrency.Get();
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	UseLocal = GetFunctionalOption("UseLocal");
	
	DocumentCurrency = Object.Currency;
	
	WarehouseGroup_ = ItIsGroupOfWarehousesAndWarehousesUsedByWHForSale(Object.Warehouse);
	
	SetParametersForSelectingProductsWarehouse();
	
	Contract = Object.Contract;
	
	DeterminePresenceOfOrderScheme();
	FillInCommissionAgentDoesNotKeepRecordsOfRPTOnServer();
	SetVisibilityOfElementsByOperationServer();
	SetVisibilityOfItemsAcrossMultipleWarehouses();
	SetAvailabilityOfDetailsOfSpendingCashOrderServer();
	FillSetVisibilityAndAvailabilityOfOverfillingOnAcceptance();
	UsePartnersAsCounterparties = GetFunctionalOption("UsePartnersAsCounterparties");
	RestrictGoodsReceiptWithoutCCDNumbers = GetFunctionalOption("RestrictGoodsReceiptWithoutCCDNumbers");
	
	SetTitleAvailabilityPickUpProductsByOrdersOrders();
	
	FillInFormDetailsFromCashRegisterReceipt(Object.CashRegisterReceipt, New Structure("CashReceiptPriceType", "PriceKind"));
	FillInServiceDetailsOfTablePart();
	EstablishCostPresentation();
	
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, Object.ReusablePackageReturn);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateReturnTotals(ThisObject);
	CalculateCompensationAmount(ThisObject);
	
	SetVisibilityOfElementsOfReturnOfGoodsRequest();
	
	SetVisibilityOfElementsAccordingToImplementationDocuments();
	OrderOfReflection = OrderOfReflection(Object.RecordInProfitLossOfPreviousYears);
	Items.ReflectionInAccounting_.Title = TitleOfReflectionInAccounting(Object.RecordInProfitLossOfPreviousYears);
	
	ContractBusinessTransaction = GetBusinessTransaction(Object.BusinessOperation);
	BusinessTransactionFromAgreement = SelfServiceClientServer.BusinessTransactionFromAgreement(Object.BusinessOperation);
	
	SetContractVisibility();
	EstablishRelationshipsBetweenContractSelectionParameters();
	
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	
	ConfigureFormForCorruption();
	TMCommonUseClientServer.SetFormItemProperty(Items, "Partner", "ReadOnly", ValueIsFilled(Object.CashRegisterReceipt));
	
	UpdateTextOfInvoiceReceived();
	
	ToUpdateData = Not ValueIsFilled(Object.Ref);
	UpdateInformationOnImplementations(ToUpdateData);
	
	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		"DepositForPackageIsRequired",
		"Enabled",
		Object.ReusablePackageReturn);
	
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
	LinesOfBusinessServer.OnReadCreateAtServer(ThisObject);
	
	WhenChangingWarehouseInTablePartServer();
	
	FillParameters = Documents.ReturnOfGoodsFromCustomer.ParametersForFillingInSalesVATTaxation(Object);
	VATAccountingERP.FillInSalesVATTaxSelectionList(Items.VATTaxation, Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues);
	PurchasesServer.FillInSelectionListNameOfIncomingDocument(ThisObject, Object.Counterparty);
	CacheQualityControl = QualityControl.DataCacheOfMechanism(Object);
	
EndProcedure

&AtClientAtServerNoContext
Function GetBusinessTransaction(BusinessOperation)
	
	If BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromCommissionAgent") Then
		Return PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent");
	ElsIf BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnOfGoodsFromCustomer") Then
		Return PredefinedValue("Enum.BusinessTransactions.SaleToCustomer");
	ElsIf BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnOfGoodsViaCommissionAgent") Then
		Return PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent");
	Else
		Return PredefinedValue("Enum.BusinessTransactions.EmptyRef");
	EndIf;
	
EndFunction

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Form)
	
	Object = Form.Object;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateVATAmount",StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT",StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(Form, StructureOfActions);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(Form, StructureOfActions)
	
	Object = Form.Object;
	
	ThisIsRefundFromCommissionAgent = Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromCommissionAgent");
	
	If ThisIsRefundFromCommissionAgent
		And Form.TheCommissionAgentDoesNotKeepRecordsOnTheRNPT Then
		
		Return;
		
	EndIf;
	
	WarehouseFieldName = ?(ThisIsRefundFromCommissionAgent, "Partner", "Warehouse");
	
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActions,
		WarehouseFieldName);
	
EndProcedure

&AtServer
Procedure FillInDefaultContract()
	
	If Not AccessRight("Read", Metadata.Catalogs.CounterpartyContracts) Then
		Return;
	EndIf;
	
	If Object.BusinessOperation <> Enums.BusinessTransactions.ReturnFromRetailCustomer Then
		
		SettlementCurrencyForContract = ?(ReturnOfGoodsViaCommissionAgent, Undefined, Object.Currency);
		
		If Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts 
			And UseLinesOfBusiness Then
	
			Object.Contract = SalesServer.GetDefaultContract(Object, 
															ContractBusinessTransaction, 
															SettlementCurrencyForContract, 
															Object.LineOfBusiness,
															ReturnOfGoodsViaCommissionAgent);
		Else
															
			Object.Contract = SalesServer.GetDefaultContract(Object, 
															ContractBusinessTransaction, 
															SettlementCurrencyForContract,
															,
															ReturnOfGoodsViaCommissionAgent);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInDefaultEndClientContract()
	
	If ReturnOfGoodsViaCommissionAgent Then
		Object.CustomerContract = ConsignmentSalesServer.GetDefaultContract(Object, 
															Enums.BusinessTransactions.SalesViaCommissionAgent);
	EndIf;
	
EndProcedure

&AtServer
Procedure GetPaymentDecryptionFromVault(AddressOfPaymentsInTheStorage)
	
	Object.ARAPDetails.Load(GetFromTempStorage(AddressOfPaymentsInTheStorage));
	ARAPAccountingFormWork.UpdateDistributedDecryptionAmount(ThisForm);
	
EndProcedure

&AtServer
Function PutGoodsAndStockTypesInStorage()
	
	OptionsForEditingInventoryTypes = InventoriesServer.OptionsForEditingInventoryTypes();
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromCommissionAgent") Then  
		OptionsForEditingInventoryTypes.DisplaySalesDocuments = False;
	Else
		OptionsForEditingInventoryTypes.DisplaySalesDocuments = True;
	EndIf;
	If UseExcisableGoods Then
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
Procedure ExecuteRecalculateDocumentAmountsServer(OldCurrency, NewCurrency)
	
	If OldCurrency <> NewCurrency Then
		
		DocumentDate               = ?(ValueIsFilled(Object.Date), Object.Date,CurrentSessionDate());
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
		
	EndIf;
	
	GoodsAmount = ?(Object.DepositForPackageIsRequired Or Not Object.ReusablePackageReturn,
		Object.Goods.Total("AmountIncludingVAT"),
		Object.Goods.Total("AmountIncludingVATWithoutReusablePackages"));
	ARAPAccountingARAPDetailsFillingIn.ConvertAmountsToCurrencyPaymentDecryption(Object, GoodsAmount);
	
EndProcedure

&AtServer
Procedure ManagingRelationshipsOfFormDetailsSelectionParameters()
	
	If ValueIsFilled(Object.CashRegisterReceipt) Then
		NewArrayOfLinks = New Array();
		For Each ParameterRelationships In Items.GoodsDocumentSalesOfGoodsAndServices.ChoiceParameterLinks Do
			ParameterRelationshipValueChange = ParameterRelationships.ValueChange;
			ParameterRelationshipName = ParameterRelationships.Name;
			ParameterRelationshipDataPath = ParameterRelationships.DataPath;
			
			AddParameterRelationship = True;
			If (ParameterRelationshipName = "Filter.Contract") Or (ParameterRelationshipName = "Filter.Counterparty") Then
				ParameterRelationshipValueChange = LinkedValueChangeMode.DontChange;				
			EndIf;
			
			If AddParameterRelationship Then
				NewArrayOfLinks.Add(New ChoiceParameterLink(ParameterRelationshipName, ParameterRelationshipDataPath, ParameterRelationshipValueChange));
			EndIf;
		EndDo;	
		Items.GoodsDocumentSalesOfGoodsAndServices.ChoiceParameterLinks = New FixedArray(NewArrayOfLinks);
	EndIf;	
	
EndProcedure	

&AtServer
Procedure FillOperationSelectionList()
	
	RefundFromCommissionAgentElement = 
		Items.BusinessOperation.ChoiceList.FindByValue(Enums.BusinessTransactions.ReturnFromCommissionAgent);
	ItemReturnOfGoodsViaCommissionAgent = 
		Items.BusinessOperation.ChoiceList.FindByValue(Enums.BusinessTransactions.ReturnOfGoodsViaCommissionAgent);
	
	If GetFormFunctionalOption("UseSalesCommission") Then
		
		Template = NStr("vi = '%1 (%2)';
						|ru = '%1 (%2)';
						|en = '%1 (%2)'; fa = '%1 (%2)';
						|it = '%1 (%2)';
						|pl = '%1 (%2)';
						|tr = '%1 (%2)'");
		
		If GetFormFunctionalOption("OnlyConsignmentSales25") Then
			If RefundFromCommissionAgentElement <> Undefined Then
				Items.BusinessOperation.ChoiceList.Delete(RefundFromCommissionAgentElement);
				RefundFromCommissionAgentElement = Undefined;
			EndIf;
		Else
			If RefundFromCommissionAgentElement <> Undefined Then
				RefundFromCommissionAgentElement.Presentation = StrTemplate(Template, 
					Enums.BusinessTransactions.ReturnFromCommissionAgent, ConsignmentSalesServer.PostfixCommissionSchemes());
			EndIf;
			If ItemReturnOfGoodsViaCommissionAgent <> Undefined Then
				ItemReturnOfGoodsViaCommissionAgent.Presentation = StrTemplate(Template,
					Enums.BusinessTransactions.ReturnOfGoodsViaCommissionAgent, 
					ConsignmentSalesServer.PostfixCommissionSchemes25());
			EndIf;
		EndIf;
		
	Else
		
		If RefundFromCommissionAgentElement <> Undefined Then
			Items.BusinessOperation.ChoiceList.Delete(RefundFromCommissionAgentElement);
			RefundFromCommissionAgentElement = Undefined;
		EndIf;
		
		If ItemReturnOfGoodsViaCommissionAgent <> Undefined Then
			Items.BusinessOperation.ChoiceList.Delete(ItemReturnOfGoodsViaCommissionAgent);
		EndIf;
		
	EndIf;
	
	If Not GetFunctionalOption("SelectConsignmentSalesVersion") 
		And Object.BusinessOperation <> Enums.BusinessTransactions.ReturnFromCommissionAgent Then
		If RefundFromCommissionAgentElement <> Undefined Then
			Items.BusinessOperation.ChoiceList.Delete(RefundFromCommissionAgentElement);
		EndIf;
	EndIf;
	
	If Not GetFormFunctionalOption("UseRetailSales") Then
		
		ListItem = Items.BusinessOperation.ChoiceList.FindByValue(Enums.BusinessTransactions.ReturnFromRetailCustomer);
		If ListItem <> Undefined Then
			Items.BusinessOperation.ChoiceList.Delete(ListItem);
		EndIf;
		
	EndIf;
	
	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		"BusinessOperation",
		"ReadOnly",
		Items.BusinessOperation.ChoiceList.Count() = 1 And ValueIsFilled(Object.BusinessOperation));
	
EndProcedure

&AtServer
Procedure SetVisibilityOfElementsByOperationServer()
	
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	
	Documents.ReturnOfGoodsFromCustomer.FillInNamesOfBusinessTransactionDetails(
		Object.BusinessOperation,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	CashServer.SetVisibilityOfElementsByArray(
		Items,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	SetContractVisibility();
	
	ThisIsRefundFromCommissionAgent = (Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent);
	ThisIsReturnFromRetailBuyer = (Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromRetailCustomer);
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "SalesOpportunity", "Visible", Not ThisIsReturnFromRetailBuyer);
	TMCommonUseClientServer.SetFormItemProperty(Items, "CashRegisterReceipt", "Visible", ThisIsReturnFromRetailBuyer);
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "ReducedDebtByLine", "Visible", Not ThisIsRefundFromCommissionAgent);
	TMCommonUseClientServer.SetFormItemProperty(Items, "GroupCashVoucher", "Visible", ThisIsReturnFromRetailBuyer);
	Items.GoodsFillInTheCostPrice.Visible = Not ThisIsReturnFromRetailBuyer And Not ThisIsRefundFromCommissionAgent;
	
	Items.DecorationIndentThereIsADepositForTheContainer.Visible = Not ThisIsReturnFromRetailBuyer And Not ThisIsRefundFromCommissionAgent;
	Items.GoodsMethodForDeterminingTheCostOfALine.Visible = Not ThisIsRefundFromCommissionAgent; 
		
	If ThisIsReturnFromRetailBuyer Then
		LinkTypeRetailSalesReport = New TypeDescription("DocumentRef.RetailSalesReport");
		Items.GoodsDocumentSalesOfGoodsAndServices.TypeRestriction  = LinkTypeRetailSalesReport;
	Else 
		TypeLinkSaleOfGoodsServices = New TypeDescription("DocumentRef.CustomerInvoice");
		Items.GoodsDocumentSalesOfGoodsAndServices.TypeRestriction  = TypeLinkSaleOfGoodsServices;
	EndIf;
	
	Items.GoodsFillInTheGTDNumbersForSalesDocuments_3.Visible = Not ThisIsRefundFromCommissionAgent;
	Items.GoodsFillInTheGTDPoNumbersForTheTransferredGoods.Visible = ThisIsRefundFromCommissionAgent
																		And Not TheCommissionAgentDoesNotKeepRecordsOnTheRNPT;
	
	Items.GroupClientData.Visible = ReturnOfGoodsViaCommissionAgent;
	
	Items.Partner.Title = 		?(ReturnOfGoodsViaCommissionAgent, NStr("vi = 'Người nhận ký gửi';
																			|ru = 'Комиссионер';
																			|en = 'Consignee'; fa = 'امانت‌دار';
																			|it = 'Commissionario';
																			|pl = 'Consignee';
																			|tr = 'Konsinye'"), "");
	Items.Counterparty.Title = 	?(ReturnOfGoodsViaCommissionAgent, NStr("vi = 'Đối tác của người nhận ký gửi';
																			|ru = 'Контрагент комиссионера';
																			|en = 'Consignee''s counterparty'; fa = 'طرف حساب امانت‌دار';
																			|it = 'Controparte commissionario';
																			|pl = 'Kontrahent komisanta';
																			|tr = 'Konsinye cari hesap'"), "");
	
	Items.GoodsSelectGoodsByOrdersNotes.Visible = Not ReturnOfGoodsViaCommissionAgent;
	Items.ReturnOfSpoiledGoods.Visible = Not ReturnOfGoodsViaCommissionAgent;
	
	Items.DateOfReceipt.Visible = Not ReturnOfGoodsViaCommissionAgent;
	
	SetPropertiesOfOutdatedCommissionUsageComment();
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfDetailsOfSpendingCashOrderServer()
	
	If Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromRetailCustomer Then
		TMCommonUseClientServer.SetFormItemProperty(Items, "CashAccountIssueNoteDate", "Enabled", Object.CashIssued);
		TMCommonUseClientServer.SetFormItemProperty(Items, "CashAccountIssueNoteNumber", "Enabled", Object.CashIssued);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetAvailabilityOfCompensationMethod(Form)
	
	TMCommonUseClientServer.SetFormItemProperty(
		Form.Items,
		"CompensationMethod",
		"Enabled",
		Form.CompensationAmount <> 0
		And Form.Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnOfGoodsFromCustomer"));
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateReturnTotals(Form)
	
	Form.AmountTotal = ?(Form.Object.DepositForPackageIsRequired,
		Form.Object.Goods.Total("AmountIncludingVAT"),
		Form.Object.Goods.Total("AmountIncludingVATWithoutReusablePackages"));
	Form.VATAmount = ?(Form.Object.DepositForPackageIsRequired,
		Form.Object.Goods.Total("VATAmount"),
		Form.Object.Goods.Total("VATAmountWithoutReusablePackages"));
	
	Form.PackageDepositValue = Form.Object.Goods.Total("AmountIncludingVAT") - Form.Object.Goods.Total("AmountIncludingVATWithoutReusablePackages");

	DisplayTotalAmountOfVAT = VATAccountingERPClientServer.DisplayNDSInResultsOfSalesDocument(Form.Object.VATTaxation);
	
	
	If DisplayTotalAmountOfVAT Then
		Form.Items.VATPageGroup.CurrentPage   = Form.Items.PageVAT;
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.TotalSNDSPage;
	Else
		Form.Items.VATPageGroup.CurrentPage   = Form.Items.PageExcludingVAT;
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.PageTotalWithoutVAT;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateCompensationAmount(Form)
	
	Form.CompensationAmount = Form.AmountTotal - Form.AllocatedAmountOfPrintName;
	
	Form.ReducedDebtByLine = NStr("vi = 'Giảm nợ khách hàng:';
									|ru = 'Уменьшен долг клиента:';
									|en = 'Customer receivable is reduced:'; fa = 'Customer receivable is reduced:';
									|it = 'Il debito del cliente è ridotto:';
									|pl = 'Zmniejszono dług klienta:';
									|tr = 'Müşterinin borcu azaltıldı:'") + " " + Format(Form.AllocatedAmountOfPrintName, "NFD=2; NZ=0,00")
		+ " " + Form.Object.Currency;
	
	SetAvailabilityOfCompensationMethod(Form);
	
EndProcedure

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
	TMCommonUseClientServer.AddSelectionParameter(Items.GoodsWarehouse, "Ref", WarehouseSelectionData(Object.Warehouse));

EndProcedure

#Region FillType

&AtServer
Procedure RefillByNotes(AnArrayOfOrders)
	
	FillParameters = Documents.ReturnOfGoodsFromCustomer.DocumentFillingParameters();
	FillParameters.FormIsOpen          = True;
	FillParameters.FillByWarehouseDocument     = True;
	
	InvoiceTable = Documents.ReturnOfGoodsFromCustomer.TableDataAndDocument(Object.Ref);
	
	HeaderAttributes = New Structure("Organization, Department, Warehouse, SalesOpportunity,
		|BusinessOperation, Ref, LineOfBusiness, PriceIncludesVAT");
	FillPropertyValues(HeaderAttributes, Object);
	Documents.ReturnOfGoodsFromCustomer.InitializeFillingParameters(FillParameters,
		HeaderAttributes, AnArrayOfOrders);
	
	TableOfBarcodesOfPackages = ReturnOfGoodsFromCustomerLocalization.ToFormStructureOfBarcodesOfPackages();
	
	Documents.ReturnOfGoodsFromCustomer.FillInByOrdersOrders(
		InvoiceTable, Object.Ref, FillParameters, TableOfBarcodesOfPackages);
	
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

	If FillParameters.FillByWarehouseDocument And TableOfBarcodesOfPackages.Count() > 0 Then
		Object.PackageBarcodes.Load(TableOfBarcodesOfPackages);
	EndIf; 
	
	// Recalculating the Quantity of Packages field
	Documents.ReturnOfGoodsFromCustomer.UpdateDependentDetailsOfTablePart(Object.Goods, FillParameters);
	
	// Post-processing is individual for the document
	FillInServiceDetailsOfTablePart();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
	
	For Each LineProducts_ In Object.Goods Do
		LineProducts_.CostDefiningMethod = Enums.WaysToCalculateReturnCost.FromCurrentDocument;
	EndDo;
	EstablishCostPresentation();
	
	UpdateInformationOnImplementations();
	
EndProcedure

#EndRegion

&AtServer
Procedure FillSetVisibilityAndAvailabilityOfOverfillingOnAcceptance()
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.ReturnOfGoodsFromCustomer));
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	SetVisibilityOfSeriesElements();
	
EndProcedure

&AtServer
Procedure FillInFormDetailsFromCashRegisterReceipt(CashRegisterReceipt, Attributes)
	If ValueIsFilled(CashRegisterReceipt) Then
		SetPrivilegedMode(True);
		CashRegisterReceiptDetailsValues = Common.ObjectAttributesValues(CashRegisterReceipt, Attributes);
		SetPrivilegedMode(False);
		For Each AttributeValue In CashRegisterReceiptDetailsValues Do
			ThisForm[AttributeValue.Key] = AttributeValue.Value;
		EndDo;
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
	
	Table.Columns.Add("DateOfShipment",    New TypeDescription("Date"));
	Table.Columns.Add("DateOfReceipt", New TypeDescription("Date"));
	Table.Columns.Add("ReferenceOrder",    New TypeDescription("DocumentRef.RequestForReturnOfGoodsFromCustomer, 
		|DocumentRef.ReturnOfGoodsFromCustomer"));
	For Each String In Table Do
		String.ReferenceOrder = ?(ValueIsFilled(Object.RequestForReturnOfGoodsFromCustomer), Object.RequestForReturnOfGoodsFromCustomer, Object.Ref);
	EndDo;
	
	Table.FillValues(CurrentSessionDate(), "DateOfShipment");
	Table.FillValues(CurrentSessionDate(), "DateOfReceipt");
	
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
Procedure ChangeTablePartBasedOnResultsOfCheck(ReturnParameters, CachedValues)
	
	GoodsTable = GetFromTempStorage(ReturnParameters.Goods);
	LinesToDelete = New Array;
	RowsToProcess = New Array();
	NewLines = New Array();
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject);
	
	StructureOfActionsForNewLines = New Structure;
	StructureOfActionsForNewLines.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsForNewLines.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsForNewLines.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object); 
	If ValueIsFilled(Object.DocumentSalesOfGoodsAndServices) Then
		ParametersFillInVATRate.Date = Common.ObjectAttributeValue(Object.DocumentSalesOfGoodsAndServices, "Date");
	EndIf;
	StructureOfActionsForNewLines.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActionsForNewLines.Insert("FillInVATRateForReturnableContainers", Object.ReusablePackageReturn);
	StructureOfActionsForNewLines.Insert("FillInNoReturnContainerAttribute", Object.ReusablePackageReturn);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsForNewLines, ThisObject);
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActionsForNewLines);
	StructureOfActionsForNewLines.Insert("FillInCheckQualityDateOfQualityConfirmation",
		CacheQualityControl);
	
	If (ToUseTermsOfSales And ValueIsFilled(Object.Terms))
		Or (Not ToUseTermsOfSales And UsePriceManagementSystem25) Then
		StructureOfActionsForNewLines.Insert(
			"FillIn_TermsOfSales",
			BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
	EndIf;
	
	For Each SourceRow In GoodsTable Do
		
		Filter = New Structure("RowID, ProductsInSet, ItemVariantOfSet, Products, Characteristic, Series, Package");
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
			
			NewLines.Add(TSRow);
			
		EndIf;
		
	EndDo;
	
	For Each TSRow In LinesToDelete Do
		Object.Goods.Delete(TSRow);
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		NewLines,
		StructureOfActionsForNewLines,
		Object.Goods,
		CachedValues);
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateReturnTotals(ThisForm);
	ItIsRequiredToUpdateTitleIsSubjectToExciseDuty = UseExcisableGoods;
	WhenChangingWarehouseInTablePartServer();
	
EndProcedure

&AtServer
Procedure FillInSalesAndPricesOnServer()
	
	SalesServer.FillInSalesAndPrices(Object, "Goods");
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateReturnTotals(ThisForm);
	
EndProcedure

&AtServer
Procedure UpdateInformationOnImplementations(ToUpdateData = True)
	
	If Not ValueIsFilled(Object.CashRegisterReceipt) Then
		SalesServer.UpdateInformationOnImplementationsInForm(
			SalesList,
			Object.DocumentSalesOfGoodsAndServices,
			TheInscriptionTheTitleOfTheImplementation,
			Items,
			Items.GoodsDocumentSalesOfGoodsAndServices,
			Object.Goods,
			"DocumentSalesOfGoodsAndServices");
	Else
		Object.DocumentSalesOfGoodsAndServices = GetReportOnRetailSalesByCashRegisterReceipt(Object.CashRegisterReceipt);
		For Each RowOfTables In Object.Goods Do
			RowOfTables.CostDefiningMethod = Enums.WaysToCalculateReturnCost.FromSalesDocument;
			RowOfTables.DocumentSalesOfGoodsAndServices = Object.DocumentSalesOfGoodsAndServices;
		EndDo;
		Items.SalePages.CurrentPage = Items.PageSales;
	EndIf;
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	EstablishCostPresentation();
	UseExcisableGoods = Documents.ReturnOfGoodsFromCustomer.ExcisableGoodsAreUsed(Object);
	ExcisableGoodsAccounting.UpdateElementsOfAccountingForExcisableItems(ThisObject, ToUpdateData);
	
	SetVisibilityOfElementsAccordingToImplementationDocuments();
	OrderOfReflection = OrderOfReflection(Object.RecordInProfitLossOfPreviousYears);
	Items.ReflectionInAccounting_.Title = TitleOfReflectionInAccounting(Object.RecordInProfitLossOfPreviousYears);
	
EndProcedure

&AtServer
Procedure UpdateTextOfInvoiceReceived()
	
	ParametersForRegisteringIssuedSF = ParametersForRegisteringInvoicesIssuedServer(Object);
	ParametersForRegisteringReceivedSF = ParametersForRegisteringInvoicesReceivedServer(Object);
	InvoiceBasedOn = VATAccountingERP.InvoicesGeneralOnBasisOf(ParametersForRegisteringIssuedSF, ParametersForRegisteringReceivedSF);
	
	TextDocumentsBasedOnFooter = SalesServer.CreatePresentationOfInvoiceGenerationCommandsBasedOn(Object.Ref, InvoiceBasedOn);
	
	GeneratingFiscalChecksServer.UpdateFiscalCheckBreakdownHyperlink(Object.Ref, ThisObject, TextDocumentsBasedOnFooter);
	
	Items.CustomerVATExempt.Visible = InvoiceBasedOn.Invoices_.Count() = 0;
	
EndProcedure

&AtServer
Procedure ClearImplementationDocuments()
	
	Object.DocumentSalesOfGoodsAndServices = Undefined;
	
	For Each LineProducts_ In Object.Goods Do
		LineProducts_.DocumentSalesOfGoodsAndServices = Undefined;
	EndDo;
	
	TheInscriptionTheTitleOfTheImplementation = Undefined;
	
	SetVisibilityOfElementsAccordingToImplementationDocuments();
	OrderOfReflection = OrderOfReflection(Object.RecordInProfitLossOfPreviousYears);
	Items.ReflectionInAccounting_.Title = TitleOfReflectionInAccounting(Object.RecordInProfitLossOfPreviousYears);
	
EndProcedure

&AtServer
Procedure FillInReturnedItemsByReceipt()
	
	Object.Goods.Clear();
	SalesServer.FillInReturnedItemsByReceipt(Object, "Goods");
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, Object.ReusablePackageReturn);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	UpdateInformationOnImplementations();
	
EndProcedure

&AtServer
Procedure FillIn_TermsOfSales()
	
	OldCurrency = DocumentCurrency;
	
	DocumentSales = FormAttributeToValue("Object");
	DocumentSales.FillInDefaultSalesConditions();
	ValueToFormAttribute(DocumentSales, "Object");
	
	DocumentCurrency = Object.Currency;
	
	FillInCommissionAgentDoesNotKeepRecordsOfRPTOnServer();
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	If ValueIsFilled(Object.DocumentSalesOfGoodsAndServices) Then
		ParametersFillInVATRate.Date = Common.ObjectAttributeValue(Object.DocumentSalesOfGoodsAndServices, "Date");
	EndIf;
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ReusablePackageReturn);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ReusablePackageReturn);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
	ExecuteRecalculateDocumentAmountsServer(OldCurrency, DocumentCurrency);
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Partner, Object.Counterparty);
	BusinessOperationOnChangeServer();
	CalculateReturnTotals(ThisObject);
	FillSetVisibilityAndAvailabilityOfOverfillingOnAcceptance();
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
	SetContractVisibility();
	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		"DepositForPackageIsRequired",
		"Enabled",
		Object.ReusablePackageReturn);
	ItIsRequiredToUpdateTitleIsSubjectToExciseDuty = UseExcisableGoods;
EndProcedure

&AtServerNoContext
Function GetReportOnRetailSalesByCashRegisterReceipt(CashRegisterReceipt)
	
	Return RetailSales.GetReportOnRetailSalesByCashRegisterReceipt(CashRegisterReceipt);
	
EndFunction

&AtServer
Procedure FillMultiTurnContainersFromStorageServer(AddressOfContainerInStorage)
	
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	If ValueIsFilled(Object.DocumentSalesOfGoodsAndServices) Then
		ParametersFillInVATRate.Date = Common.ObjectAttributeValue(Object.DocumentSalesOfGoodsAndServices, "Date");
	EndIf;
	ActionStructureModifiedStrings = New Structure;
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	ActionStructureModifiedStrings.Insert("RecalculateNumberOfPackages");
	ActionStructureModifiedStrings.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	ActionStructureModifiedStrings.Insert("RecalculateAmount");
	ActionStructureModifiedStrings.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	ActionStructureModifiedStrings.Insert("FillInDuplicateDependentDetails", DependentDetails());
	AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(ThisObject, ActionStructureModifiedStrings);
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(ActionStructureModifiedStrings);
	
	StructureOfActionsAddedLines =  CommonClientServer.CopyStructure(ActionStructureModifiedStrings);
	StructureOfActionsAddedLines.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsAddedLines.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsAddedLines.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActionsAddedLines.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActionsAddedLines.Insert("FillInVATRateForReturnableContainers", Object.ReusablePackageReturn);
	StructureOfActionsAddedLines.Insert("FillInNoReturnContainerAttribute", Object.ReusablePackageReturn);
	StructureOfActionsAddedLines.Insert("FillInDuplicateDependentDetails", DependentDetails());
	StructureOfActionsAddedLines.Insert("FillInMethodForDeterminingCost", Enums.WaysToCalculateReturnCost.FromCurrentDocument);
	StructureOfActionsAddedLines.Insert("FillInCostDeterminationMethodWithLine", CostDeterminationParameters(ThisForm));
	StructureOfActionsAddedLines.Insert("CheckFillWarehouse",
		BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	StructureOfActionsAddedLines.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	If (ToUseTermsOfSales And ValueIsFilled(Object.Terms)) 
		Or (Not ToUseTermsOfSales And UsePriceManagementSystem25) Then
		StructureOfActionsAddedLines.Insert("FillIn_TermsOfSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
	EndIf;
	
	ReusablePackageServer.FillMultiTurnContainersFromStorage(
		Object,
		AddressOfContainerInStorage,
		"Goods",
		"Products,Characteristic",
		ActionStructureModifiedStrings,
		StructureOfActionsAddedLines);
		
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", 
			New Structure("Products,ProductsRecordingAsReceived", "ItemVariantsAreUsed", "ItemVariantsAreUsedRecordingAsReceived"));
		
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureOfActions);
	
	SetsServer.FillInServiceDetails(ThisForm);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
	UpdateInformationOnImplementations();
	CalculateReturnTotals(ThisForm);
	ItIsRequiredToUpdateTitleIsSubjectToExciseDuty = UseExcisableGoods;
	WhenChangingWarehouseInTablePartServer();
	
EndProcedure

&AtServer
Procedure ReusablePackageReturnOnChangeServer()
	
	If Not Object.ReusablePackageReturn Then
		Object.DepositForPackageIsRequired = False;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ReusablePackageReturn);
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ReusablePackageReturn);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	CalculateReturnTotals(ThisForm);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		"DepositForPackageIsRequired",
		"Enabled",
		Object.ReusablePackageReturn);
	ItIsRequiredToUpdateTitleIsSubjectToExciseDuty = UseExcisableGoods;
EndProcedure

&AtClientAtServerNoContext
Function DependentDetails()
	
	Return New Structure(
		"WithoutReusablePackages",
		"Sum,VATAmount,AmountIncludingVAT");
	
EndFunction

&AtServer
Procedure SetContractVisibility()
	
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	
	Documents.ReturnOfGoodsFromCustomer.FillInNamesOfBusinessTransactionDetails(
		Object.BusinessOperation, 
		ArrayOfAllProps, 
		ArrayOfOperationDetails);
	
	VisibilityOfTransactionAgreement = ArrayOfOperationDetails.Find("Contract") <> Undefined;
	
	ContractVisibility = False;
	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, ContractVisibility, Object.Contract);
	Items.Contract.Visible = ContractVisibility And VisibilityOfTransactionAgreement;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfElementsAccordingToImplementationDocuments()
	
	CompletedImplementationDocument = False;
	
	For Each TSRow In Object.Goods Do
		
		If ValueIsFilled(TSRow.DocumentSalesOfGoodsAndServices)
			And TSRow.CostDefiningMethod =
				Enums.WaysToCalculateReturnCost.FromSalesDocument Then
			CompletedImplementationDocument = True;
			Break;
		EndIf;
		
	EndDo;
	
	Items.ReflectionInAccounting_.Visible = Not CompletedImplementationDocument;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfElementsOfReturnOfGoodsRequest()
	
	ItemArray = New Array;
	
	If ValueIsFilled(Object.RequestForReturnOfGoodsFromCustomer) Then
		ItemArray.Add("GoodsCopy");
		ItemArray.Add("ProductItemsContextMenuCopy");
		ItemArray.Add("GoodsOpenSelection");
		ItemArray.Add("GoodsAddReusablePackage");
		ItemArray.Add("GoodsToPickUpTheGoodsInImplementations");
		ItemArray.Add("GoodsFillInSalesAndPrices");
		ItemArray.Add("GoodsSearchByBarcode");
		ItemArray.Add("GoodsSplitRow");
		ItemArray.Add("GoodsContextMenuSplitRow");
		ItemArray.Add("ReturnOfSpoiledGoods");
		ItemArray.Add("GoodsImportFromExternalFile");
		ItemArray.Add("GoodsFillInVATRate");
		
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", False);
	Else
		ItemArray.Add("GroupRequest");
		
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible", False);
	EndIf;
	
	UseAdvancedFeaturesOfSalesOrder = UseAdvancedFeaturesOfSalesOrder();
	
	Items.GroupRequest.Visible = ValueIsFilled(Object.RequestForReturnOfGoodsFromCustomer) And UseAdvancedFeaturesOfSalesOrder;
	Items.CloseRequest.Enabled = AccessRight("Update",Metadata.Documents.RequestForReturnOfGoodsFromCustomer);
	
EndProcedure

&AtServer
Procedure GetUploadedProductsFromStorage(GoodsAddressInStorage)
	
	ItemsFromStorage = GetFromTempStorage(GoodsAddressInStorage);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ReusablePackageReturn);
	StructureOfActions.Insert("CheckFillWarehouse", 
		BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
		
	StructureOfActions.Insert("FillInCCDTrackingAttribute",  New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActions.Insert("FillInMethodForDeterminingCost", Enums.WaysToCalculateReturnCost.FromCurrentDocument);
	StructureOfActions.Insert("FillInCostDeterminationMethodWithLine", CostDeterminationParameters(ThisForm));
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisForm);
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
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
	
	WhenChangingWarehouseInTablePartServer();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateReturnTotals(ThisForm);
	
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	ItIsRequiredToUpdateTitleIsSubjectToExciseDuty = UseExcisableGoods;
EndProcedure

&AtServer
Procedure UpdateRegisteredProducts()
	If ContractBusinessTransaction = Enums.BusinessTransactions.ReturnFromCommissionAgent Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ReturnOfGoodsFromCustomerGoods.ProductsRecordingAsReceived
	|INTO Goods
	|FROM
	|	&Goods AS ReturnOfGoodsFromCustomerGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.ProductsRecordingAsReceived.SKU AS SKURegistration,
	|	CASE
	|		WHEN Goods.ProductsRecordingAsReceived.UseVariants IS NULL
	|			OR Goods.ProductsRecordingAsReceived.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.EmptyRef)
	|			OR Goods.ProductsRecordingAsReceived.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.DontUse)
	|
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ItemVariantsAreUsedRecordingAsReceived  
	|FROM
	|	Goods AS Goods";
	Query.SetParameter("Goods",Object.Goods.Unload());
	SelectionProductsRegistration =  Query.Execute().Select();
	For Each LineProducts_ In Object.Goods Do
		SelectionProductsRegistration.Next();
		LineProducts_.ItemVariantsAreUsedRecordingAsReceived = SelectionProductsRegistration.ItemVariantsAreUsedRecordingAsReceived;
		LineProducts_.SKURegistration 					 = SelectionProductsRegistration.SKURegistration;
	EndDo;
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfFormCommands(InstallableAvailability)
	
	ItemArray = New Array;
	ItemArray.Add("ReturnOfSpoiledGoods");
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsAddReusablePackage");
	ItemArray.Add("GoodsImportDataFromPDT");
	ItemArray.Add("GoodsImportFromExternalFile");
	ItemArray.Add("GoodsFillInSalesAndPrices");
	ItemArray.Add("FormOpenInventoryKinds");
	ItemArray.Add("GoodsOpenSelection");
	ItemArray.Add("ProductsSelectProductsFromApplication");
	ItemArray.Add("GoodsToPickUpTheGoodsInImplementations");
	ItemArray.Add("GoodsSearchByBarcode");
	ItemArray.Add("GoodsGetWeight");
	ItemArray.Add("GoodsCheckQuantityInTheDocument");
	ItemArray.Add("GoodsSplitRow");
	ItemArray.Add("GoodsContextMenuSplitRow");
	ItemArray.Add("AttributesForReturnApplicationPrinting");
	ItemArray.Add("GoodsCopyRows");
	ItemArray.Add("GoodsSetComposition");
	ItemArray.Add("GoodsSpecifySeries");
	ItemArray.Add("GoodsFillInVATRate");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", InstallableAvailability);
EndProcedure

&AtServer
Procedure EstablishCostPresentation()
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInCostDeterminationMethodWithLine", CostDeterminationParameters(ThisForm));
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
EndProcedure

&AtClient
Procedure SetCostPresentationInLine(CurrentRow)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInCostDeterminationMethodWithLine", CostDeterminationParameters(ThisForm));
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtServer
Procedure FillInSalesVATTaxation()
	
	FillParameters = Documents.ReturnOfGoodsFromCustomer.ParametersForFillingInSalesVATTaxation(Object);
	VATAccountingERP.FillInSalesVATTaxation(Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues);
	VATAccountingERP.FillInSalesVATTaxSelectionList(Items.VATTaxation, Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues); 
	
EndProcedure

&AtClient
Procedure FillInCostInTable()
	
	FormParameters = New Structure;
	FormParameters.Insert("Organization", Object.Organization);
	FormParameters.Insert("Date", Object.Date);
	FormParameters.Insert("Partner", Object.Partner);
	FormParameters.Insert("Counterparty", Object.Counterparty);
	FormParameters.Insert("Contract", Object.Contract);
	FormParameters.Insert("Terms", Object.Terms);
	FormParameters.Insert("DocumentCurrency", Object.Currency);
	FormParameters.Insert("TaxationType", Object.VATTaxation);
	FormParameters.Insert("ShowSales", 
		Object.BusinessOperation <> PredefinedValue("Enum.BusinessTransactions.ReturnFromRetailCustomer"));
		
	SelectedRows = Items.Goods.SelectedRows;
	RowsOfProductsTable = New Array();
	
	For Each CurRowId_ In SelectedRows Do
		
		TableRow = Object.Goods.FindByID(CurRowId_);
		RowParameters = New Structure();
		
		RowParameters.Insert("Id", CurRowId_);
		RowParameters.Insert("CostDefiningMethod", TableRow.CostDefiningMethod);
		RowParameters.Insert("PriceKind", TableRow.CostPriceKind);
		RowParameters.Insert("DateOfCostFillingByPriceType", TableRow.DateOfCostFillingByPriceType);
		RowParameters.Insert("NumberOfPackages", TableRow.Count);
		RowParameters.Insert("Package", TableRow.Package);
		RowParameters.Insert("DocumentSales", TableRow.DocumentSalesOfGoodsAndServices);
		RowParameters.Insert("Products", TableRow.Products);
		RowParameters.Insert("Characteristic", TableRow.Characteristic);
		RowParameters.Insert("VATRate", TableRow.VATRate);
		RowParameters.Insert("AmountIncludingVAT", TableRow.Cost_);
		RowParameters.Insert("AmountExcludingVAT", TableRow.CostExcludingVAT_);
		RowParameters.Insert("SumCompl", TableRow.CostLocal);
		RowParameters.Insert("AmountPermanentDifferences", TableRow.CDCost);
		RowParameters.Insert("AmountTemporaryDifferences", TableRow.TDCost);
		RowsOfProductsTable.Add(RowParameters);
		
	EndDo;
	
	FormParameters.Insert("RowsOfProductsTable", RowsOfProductsTable);
	
	OpenForm("Document.ReturnOfGoodsFromCustomer.Form.SelectionFormOfCostDefiningMethod",
		FormParameters,
		ThisForm,,,,
		New CallbackDescription("ChoosingMethodForDeterminingCostOfProduction",
				ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtServer
Procedure EstablishRelationshipsBetweenContractSelectionParameters()
	
	RelationshipsOfContractParameters = New Array;
	
	RelationshipsOfContractParameters.Add(New ChoiceParameterLink("Filter.Counterparty",				"Object.Counterparty"));
	RelationshipsOfContractParameters.Add(New ChoiceParameterLink("Filter.Organization",			"Object.Organization"));
	RelationshipsOfContractParameters.Add(New ChoiceParameterLink("Filter.ConsignmentSales25",	"ReturnOfGoodsViaCommissionAgent"));
	RelationshipsOfContractParameters.Add(New ChoiceParameterLink("Filter.BusinessOperation",	"ContractBusinessTransaction"));
	RelationshipsOfContractParameters.Add(New ChoiceParameterLink("Partner",						"Object.Partner"));
	RelationshipsOfContractParameters.Add(New ChoiceParameterLink("Terms",					"Object.Terms",
			LinkedValueChangeMode.DontChange));
	
	If Not ReturnOfGoodsViaCommissionAgent Then
		RelationshipsOfContractParameters.Add(New ChoiceParameterLink("Filter.ARAPCurrency", "Object.Currency"));
	EndIf;
	
	Items.Contract.ChoiceParameterLinks = New FixedArray(RelationshipsOfContractParameters);
	
EndProcedure
&AtServer
Procedure CalculateNumberOfExcisableItemsDeferred()
	
	CalculationParameters = ExcisableGoodsAccounting.ParametersForCalculatingNumberOfExcisableItems();
	CalculationParameters.FilterParameters = New Structure("DocumentSalesOfGoodsAndServices", Undefined);
	DataForCalculatingNumberOfExcisableGoods =
		ExcisableGoodsAccounting.StartCalculatingNumberOfExcisableItems(Object, CalculationParameters);
	
EndProcedure

&AtClient
Procedure Attachable_UpdateFieldHeaderIsSubjectToExciseDuty()
	
	ExcisableGoodsAccountingClient.AfterCalculatingNumberOfExcisableItems(ThisObject);
	
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
	FilterParameters.Insert("Products.ItemsType", ProductsClientServer.SelectionByProductMultiTurnContainer());
	
	Columns = "Products,Characteristic,Package,NumberOfPackages,Price,CCDNumber,CostDefiningMethod,
		|Damage,ProductsRecordingAsReceived,CharacteristicRecordingAsReceived,DocumentSalesOfGoodsAndServices,
		|ProductsInSet,ItemVariantOfSet,Warehouse";
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	SetsServer.DeleteRowsOfSetsAccordingToSelection(TableOfGoods, FilterParameters["Products.ItemsType"]);
	
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	If ValueIsFilled(Object.DocumentSalesOfGoodsAndServices) Then
		ParametersFillInVATRate.Date = Common.ObjectAttributeValue(Object.DocumentSalesOfGoodsAndServices, "Date");
	EndIf;
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("CheckFillWarehouse",
		BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ReusablePackageReturn);
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ReusablePackageReturn);
	StructureOfActions.Insert("FillInCostDeterminationMethodWithLine", CostDeterminationParameters(ThisForm));
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisForm);
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
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
		Object.Goods);
	
	FillInServiceDetailsOfTablePart();
	WhenChangingWarehouseInTablePartServer();
	
	StructureCharacteristicsOfProducts = New Structure;
	StructureCharacteristicsOfProducts.Insert("FillInFeatureAttribute",
			New Structure("Products,ProductsRecordingAsReceived", "ItemVariantsAreUsed", "ItemVariantsAreUsedRecordingAsReceived"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureCharacteristicsOfProducts);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	
	SetVisibilityOfElementsAccordingToImplementationDocuments();
	OrderOfReflection = OrderOfReflection(Object.RecordInProfitLossOfPreviousYears);
	Items.ReflectionInAccounting_.Title = TitleOfReflectionInAccounting(Object.RecordInProfitLossOfPreviousYears);
	
	CalculateReturnTotals(ThisForm);
	ItIsRequiredToUpdateTitleIsSubjectToExciseDuty = UseExcisableGoods;
EndProcedure

&AtServer
Procedure SetAvailabilityOfClipboardCommands()
	
	ItemArray = New Array();
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled",
		ProcessingOfTabularForms.ThereAreLinesInClipboard() And Not ValueIsFilled(Object.RequestForReturnOfGoodsFromCustomer));
	
EndProcedure

&AtClient
Procedure SetAvailabilityOfClipboardCommandsOnClient()
	
	ItemArray = New Array();
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled",
		Not ValueIsFilled(Object.RequestForReturnOfGoodsFromCustomer));
	
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

#EndRegion

#Region WorkingWithCounterparties
&AtClient
Procedure CheckCounterparties(Command)
	
	
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
Procedure SearchByBarcodeCompletion(BarcodeData_2, AdditionalParameters) Export
	
	ProcessBarcodes(BarcodeData_2);
	
EndProcedure

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export 
	
	CurrentRow = Items.Goods.CurrentData;
	
	If NewRow <> Undefined Then
		
		NewRow.RowCode = 0;
		
		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisForm);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
		CalculateReturnTotals(ThisForm);
		FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, AmountTotal);
		CalculateCompensationAmount(ThisForm);
		
	EndIf;
	
	WhenChangingWarehouseInTablePartServer();
	AccountingForTraceableGoodsClientServerLocalization.SplitRowCompletion(NewRow, AdditionalParameters);
	
EndProcedure

&AtServer
Procedure FillInSalesAndPricesServer()
	
	FillInSalesAndPricesOnServer();
	FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, AmountTotal);
	CalculateCompensationAmount(ThisForm);
	UpdateInformationOnImplementations();
	
EndProcedure

&AtServer
Procedure DeterminePresenceOfOrderScheme()
	
	AdvancedWarehousing = WarehousesServer.UseWarehouseManagemantSystemForGoodsReceipt(Object.Warehouse, Object.Date);
	
EndProcedure

&AtServer
Procedure ProcessingProductSelectionFromOrder(AddressInStorage)
	
	Table = GetFromTempStorage(AddressInStorage).Goods;//ValueTable
	TableOfBarcodesOfPackages = GetFromTempStorage(AddressInStorage).PackageBarcodes;
	
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
	AddedRows = InvoicesServer.FillInProductsSelectedFromOrder(
		StringTree, FieldsNames, Object.Goods, OrderRelationshipFields);
	
	For Each CurrentRow In Object.Goods Do
		If ValueIsFilled(CurrentRow.DocumentSalesOfGoodsAndServices) Then
			CurrentRow.CostDefiningMethod = Enums.WaysToCalculateReturnCost.FromSalesDocument;
		ElsIf Not ValueIsFilled(CurrentRow.CostDefiningMethod) Then
			CurrentRow.CostDefiningMethod = Enums.WaysToCalculateReturnCost.FromCurrentDocument;
		EndIf;
	EndDo;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(ThisObject, StructureOfActions);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
	StructureOfActionsAddedLines = New Structure();
	StructureOfActionsAddedLines.Insert("FillInCheckQualityDateOfQualityConfirmation",
		CacheQualityControl);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		AddedRows,
		StructureOfActionsAddedLines,
		Object.Goods);
	
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, Object.ReusablePackageReturn);
	
	FillInCCDNumbersServer("ByReferences", "DocumentSalesOfGoodsAndServices");
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
	UpdateInformationOnImplementations();
	CalculateReturnTotals(ThisObject);
	WhenChangingWarehouseInTablePartServer();
	
	FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, AmountTotal);
	CalculateCompensationAmount(ThisObject);
	
	SetVisibilityOfElementsAccordingToImplementationDocuments();
	OrderOfReflection = OrderOfReflection(Object.RecordInProfitLossOfPreviousYears);
	Items.ReflectionInAccounting_.Title = TitleOfReflectionInAccounting(Object.RecordInProfitLossOfPreviousYears);
	
	SalesServerLocalization.TransferBarcodesOfPackages(ThisObject, TableOfBarcodesOfPackages);
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	ItIsRequiredToUpdateTitleIsSubjectToExciseDuty = UseExcisableGoods;
EndProcedure

&AtServer
Procedure GoodsProductsOnChangeServer(CurrentRowID)
	
	CurrentRow = Object.Goods.FindByID(CurrentRowID);
	
	If CurrentRow.Damage
		And ValueIsFilled(CurrentRow.ProductsRecordingAsReceived) Then
		ThereIsGradation = CheckForGradationServer(CurrentRow.Products, CurrentRow.ProductsRecordingAsReceived);
		If Not ThereIsGradation Then
			CurrentRow.ProductsRecordingAsReceived = PredefinedValue("Catalog.Products.EmptyRef");
			CurrentRow.CharacteristicRecordingAsReceived = PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef");
			CurrentRow.ItemVariantsAreUsedRecordingAsReceived = False;
		EndIf;
	EndIf;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	
	If ValueIsFilled(Object.DocumentSalesOfGoodsAndServices) Then
		ParametersFillInVATRate.Date = Common.ObjectAttributeValue(Object.DocumentSalesOfGoodsAndServices, "Date");
	EndIf;
	
	StructureOfActions = New Structure;
	
	If (ToUseTermsOfSales And ValueIsFilled(Object.Terms)) 
		Or (Not ToUseTermsOfSales And UsePriceManagementSystem25) Then
		StructureOfActions.Insert("FillIn_TermsOfSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
	EndIf;

	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits"); 
	StructureOfActions.Insert("CheckFillWarehouse",
		BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ReusablePackageReturn);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ReusablePackageReturn);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	StructureOfActions.Insert("CheckSeriesCalculateStatus",
		New Structure("Warehouse, SeriesSpecificationParameters", CurrentRow.Warehouse, SeriesSpecificationParameters));
	StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActions.Insert("FillInCountryOfOriginOfProduct",
								BatchProcessingOfTablePartClientServer.CountryOfOriginFillingParameters());

	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(ThisForm, StructureOfActions);

	BatchProcessingOfTablePartServer.ProcessTSString(CurrentRow, StructureOfActions, Undefined);
	
	If Not CurrentRow.TheRecordsAreKeptByCCD Then
		CurrentRow.CCDNumber = Undefined;
		CurrentRow.CCDNumberType = Undefined;
		CurrentRow.OriginCountry = Undefined;
	EndIf;
	
	CalculateReturnTotals(ThisForm);
	FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, AmountTotal);
	CalculateCompensationAmount(ThisForm);
	ItIsRequiredToUpdateTitleIsSubjectToExciseDuty = UseExcisableGoods;
EndProcedure

&AtServer
Procedure GoodsCharacteristicOnChangeServer(CurrentRowID)
	CurrentRow = Object.Goods.FindByID(CurrentRowID);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	If (ToUseTermsOfSales And ValueIsFilled(Object.Terms)) 
		Or (Not ToUseTermsOfSales And UsePriceManagementSystem25) Then
		StructureOfActions.Insert("FillIn_TermsOfSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
	EndIf;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));

	BatchProcessingOfTablePartServer.ProcessTSString(CurrentRow, StructureOfActions, Undefined);
	
	CalculateReturnTotals(ThisForm);
	FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, AmountTotal);
	CalculateCompensationAmount(ThisForm);
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsOfTablePart()
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute",
			New Structure("Products,ProductsRecordingAsReceived", "ItemVariantsAreUsed", "ItemVariantsAreUsedRecordingAsReceived"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute",New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureOfActions);
	
	SetsServer.FillInServiceDetails(ThisForm);
	
EndProcedure

&AtServer
Procedure SetTitleAvailabilityPickUpProductsByOrdersOrders()
	
	RefundOnRequest = UseReturnRequests
						And ValueIsFilled(Object.RequestForReturnOfGoodsFromCustomer);
	ButtonTitle = NStr("vi = 'Chọn theo đơn đặt hàng / bảo hành';
						|ru = 'Подобрать по распоряжениям/ордерам';
						|en = 'Pick by references/notes'; fa = 'انتخاب بر اساس مراجع/حواله‌ها';
						|it = 'Seleziona in base alle disposizioni/mandati';
						|pl = 'Wybierz wg zamówień/zleceń';
						|tr = 'Talimatlara/emirlere göre seçin'");
	
	If Not AdvancedWarehousing
		And RefundOnRequest Then
		
		ButtonTitle = NStr("vi = 'Chọn theo đơn đặt hàng';
							|ru = 'Подобрать по распоряжениям';
							|en = 'Pick by references'; fa = 'انتخاب بر اساس مراجع';
							|it = 'Selezionare in base alle disposizioni';
							|pl = 'Wybierz wg zamówień';
							|tr = 'Talimatlara göre seçim'");
		
	ElsIf Not RefundOnRequest Then
		ButtonTitle = NStr("vi = 'Nhận theo đơn đặt hàng';
							|ru = 'Подобрать по ордерам';
							|en = 'Pick by notes'; fa = 'Pick by notes';
							|it = 'Selezionare in base ai mandati';
							|pl = 'Wybierz wg zleceń';
							|tr = 'Emirlere göre seçim'");
	EndIf;
	
	Items.GoodsSelectGoodsByOrdersNotes.Title	= ButtonTitle;
	Items.GoodsSelectGoodsByOrdersNotes.Enabled	= AdvancedWarehousing
																	Or RefundOnRequest;
	
EndProcedure

&AtServer
Procedure CompensationMethodOnChangeServer()
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisForm);
EndProcedure

&AtServer
Procedure RecalculateNumberOfRNPT()
	
	ThisIsRefundFromCommissionAgent = Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent;
	
	If (Not ThisIsRefundFromCommissionAgent
			And ValueIsFilled(Object.Warehouse))
		Or (ThisIsRefundFromCommissionAgent
			And Not TheCommissionAgentDoesNotKeepRecordsOnTheRNPT
			And ValueIsFilled(Object.Partner))
		And ValueIsFilled(Object.Organization) Then
		
		WarehouseFieldName = ?(ThisIsRefundFromCommissionAgent, "Partner", "Warehouse");
		
		ParametersForObtainingRnptCoefficient = AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(
												Object,
												WarehouseFieldName);
		AccountingForTraceableGoodsLocalization.FillInQuantityByRNPTVOfTablePart(ParametersForObtainingRnptCoefficient,
																						Object.Goods);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsAtEndOfEditingForServerCall()

	GoodsAtEndOfEditingOnServer();

EndProcedure

&AtServer
Procedure FillInCommissionAgentDoesNotKeepRecordsOfRPTOnServer()
	
	TheCommissionAgentDoesNotKeepRecordsOnTheRNPT = Not Catalogs.TermsOfSale.CommissionAgentUsesInventoryAccountingByProductBatchID(Object.Terms)
									Or Not Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent;
	
EndProcedure

&AtClient
Procedure FillInVATRateCompletion(VATRate, AdditionalParameters) Export

	If VATRate = Undefined Then
		Return;
	EndIf;

	FillInVATRateOnServer(VATRate, CachedValues);

	CalculateReturnTotals(ThisObject);
	FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, AmountTotal);
	CalculateCompensationAmount(ThisObject);

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
		If Object.ReusablePackageReturn
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

&AtServer
Procedure DocumentSalesOfGoodsAndServicesOnChangeServer()
	
	ThisIsReturnFromRetailBuyer = (Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromRetailCustomer);
	If ThisIsReturnFromRetailBuyer Then
		
		If ValueIsFilled(Object.CashRegisterReceipt) Then
			
			If GetReportOnRetailSalesByCashRegisterReceipt(Object.CashRegisterReceipt) <> Object.DocumentSalesOfGoodsAndServices Then
				Object.CashRegisterReceipt = Undefined;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	SetVisibilityOfElementsAccordingToImplementationDocuments();
	OrderOfReflection = OrderOfReflection(Object.RecordInProfitLossOfPreviousYears);
	Items.ReflectionInAccounting_.Title = TitleOfReflectionInAccounting(Object.RecordInProfitLossOfPreviousYears);
	
EndProcedure

&AtServer
Procedure GoodsDocumentSalesOfGoodsAndServicesOnChangeServer(CurrentRowID)
	
	CurrentRow = Object.Goods.FindByID(CurrentRowID);
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	UpdateInformationOnImplementations();
	
	If CurrentRow.DocumentSalesOfGoodsAndServices <> Undefined And Not ValueIsFilled(CurrentRow.DocumentSalesOfGoodsAndServices)
		And Not ValueIsFilled(Object.CashRegisterReceipt)
		And Object.BusinessOperation <> PredefinedValue("Enum.BusinessTransactions.ReturnFromCommissionAgent") Then
		
		CurrentRow.CostDefiningMethod = PredefinedValue("Enum.WaysToCalculateReturnCost.FromCurrentDocument");
		
	ElsIf CurrentRow.DocumentSalesOfGoodsAndServices <> Undefined And ValueIsFilled(CurrentRow.DocumentSalesOfGoodsAndServices)
		And Not ValueIsFilled(Object.CashRegisterReceipt)
		And (Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromRetailCustomer")
			Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromCommissionAgent")) Then
		
		CurrentRow.CostDefiningMethod = PredefinedValue("Enum.WaysToCalculateReturnCost.FromSalesDocument");
		
	EndIf;
	
	SetVisibilityOfElementsAccordingToImplementationDocuments();
	OrderOfReflection = OrderOfReflection(Object.RecordInProfitLossOfPreviousYears);
	Items.ReflectionInAccounting_.Title = TitleOfReflectionInAccounting(Object.RecordInProfitLossOfPreviousYears);
	
EndProcedure

#EndRegion

#Region Other

#Region FiscalTransaction

&AtClient
Procedure FiscalOperationNavigationLinkProcessing(Item, Var_URL, StandardProcessing)
	
	If "IssueCashReceipt" = Var_URL Then
		
		StandardProcessing = False;

		GeneratingFiscalChecksClient.DisplayReceipt(
			ThisObject,
			New CallbackDescription("FiscalTransactionCompletion", ThisObject));
		
	ElsIf "OpenRecordOfFiscalTransaction" = Var_URL Then
		
		StandardProcessing = False;
		
		TMPeripheralsClient.OpenRecordOfFiscalTransaction(ThisObject, Object.Ref);
		
	ElsIf "ConfigureHardware_" = Var_URL Then
		
		StandardProcessing = False;
		
		OpenForm("DataProcessor.PreviewReceipt.Form.ErrorOfCREConnection");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FiscalTransactionCompletion(Result, AdditionalParameters) Export
	
	UpdateTextOfInvoiceReceived();
	
EndProcedure

#Region Properties

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

#EndRegion

#EndRegion

&AtClientAtServerNoContext
Function CostDeterminationParameters(Form)
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("VATTaxation", Form.Object.VATTaxation);
	ParametersStructure.Insert("ManagementAccountingCurrency", Form.ManagementAccountingCurrency);
	ParametersStructure.Insert("LocalAccountingCurrency", Form.LocalAccountingCurrency);
	ParametersStructure.Insert("UseLocal",  Form.UseLocal);
	
	Return ParametersStructure;
	
EndFunction

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);

EndProcedure

&AtClient
Procedure UpdateAttributesOfAccountingDocument()
	
	If OrderOfReflection = "Revenue" And Object.RecordInProfitLossOfPreviousYears Then
		Object.RecordInProfitLossOfPreviousYears = False;
	ElsIf OrderOfReflection = "OtherIncome" And Not Object.RecordInProfitLossOfPreviousYears Then
		Object.RecordInProfitLossOfPreviousYears = True;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function OrderOfReflection(RecordInProfitLossOfPreviousYears)
	
	If RecordInProfitLossOfPreviousYears Then
		Return "OtherIncome";
	EndIf;
	
	Return "Revenue";
	
EndFunction

&AtClientAtServerNoContext
Function TitleOfReflectionInAccounting(RecordInProfitLossOfPreviousYears)
	
	TitleReflectionInAccounting = NStr("ru = 'Отражение в учете: %1';
										|vi = 'Accounting attributes: %1';
										|en = 'Accounting attributes: %1'; fa = 'Accounting attributes: %1';
										|it = 'Accounting attributes: %1';
										|pl = 'Accounting attributes: %1';
										|tr = 'Muhasebeye yansıtma: %1'");
	
	If RecordInProfitLossOfPreviousYears Then
		ReflectionOfAC = NStr("ru = 'прочие доходы/расходы';
								|vi = 'other income/expenses';
								|en = 'other income/expenses'; fa = 'other income/expenses';
								|it = 'other income/expenses';
								|pl = 'other income/expenses';
								|tr = 'diğer gelirler/giderler'");
	Else
		ReflectionOfAC = NStr("ru = 'уменьшение выручки и себестоимости продаж';
								|vi = 'decrease in revenue and cost of goods sold';
								|en = 'decrease in revenue and cost of goods sold'; fa = 'decrease in revenue and cost of goods sold';
								|it = 'decrease in revenue and cost of goods sold';
								|pl = 'decrease in revenue and cost of goods sold';
								|tr = 'satış geliri ve satış maliyetinin azaltılması'");
	EndIf;
	
	Return StringFunctionsClientServer.SubstituteParametersToString(TitleReflectionInAccounting, ReflectionOfAC);
	
EndFunction

&AtServer
Procedure SetPropertiesOfOutdatedCommissionUsageComment()
	
	Items.CommentUsingOutdatedCommission.Title = ConsignmentSalesServer.CommentUsingOutdatedCommission();
	Items.GroupCommentUsingOutdatedCommission.Visible = Not ReturnOfGoodsViaCommissionAgent
		And Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromCommissionAgent");
	
EndProcedure

#EndRegion

#Region Localization

&AtClient
Procedure CloseKmVerificationSessionOnCCT(Val Cancel)
	
	
	Return;

EndProcedure


&AtServer
Function UseAdvancedFeaturesOfSalesOrder()
	
	If ValueIsFilled(Object.RequestForReturnOfGoodsFromCustomer) Then
		Return Not Common.ObjectAttributeValue(Object.RequestForReturnOfGoodsFromCustomer, "ThisIsOrderAsInvoice");
	Else
		Return GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder");
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
