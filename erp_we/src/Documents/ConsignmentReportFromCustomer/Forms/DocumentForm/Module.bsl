#Region Variables

&AtClient
Var CounterpartyVerificationWaitHandlerParameters Export;

&AtClient
Var TimeConsumingOperationForm Export;

&AtClient
Var CachedValues; // used by the mechanism for processing changes in PM details

&AtClient
Var ParametersForRecording Export;

&AtClient
Var CurDataId; // used to pass the current line to the wait handler

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25();

	DocumentCorrection.OnCreateAtServer(ThisForm, Items.LineCorrection);
	
	DefaultBusinessTransaction = PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent");
	ConsignmentSales25 = ?(Object.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgent, True, False);
	
	If ConsignmentSales25 Then
		
		Items.GoodsFillThePricesByTermsOfSales.Visible = False;
		Items.GoodsFillInPricesUnderAgreement.Visible = True;
		Items.GoodsFillInCommitteePrices.Visible = True;
		Items.GoodsFillInCustomerPrices.Visible = True;
		Items.GoodsSellingPriceType.Visible = True;
		
	Else
		
		Items.GoodsFillThePricesByTermsOfSales.Visible = True;
		Items.GoodsFillInPricesUnderAgreement.Visible = False;
		Items.GoodsFillInCommitteePrices.Visible = False;
		Items.GoodsFillInCustomerPrices.Visible = False;
		Items.GoodsSellingPriceType.Visible = False;
		
	EndIf;
	
	ManagingRelationshipsOfFormDetailsSelectionParameters();
	HowToSetSeriesVisibility();
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	// Handler of the subsystem "Versioning of objects"
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
		CalculateRemuneration = True;
	EndIf;
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.GroupInTotal.BackColor = New Color();
	EndIf;
	
	SalesServer.SetBlankContractMark(Items, "Contract");
	
	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisForm);

	Items.GoodsPriceKind.QuickChoice = Not GetFunctionalOption("UseSeveralPriceTypes");
	
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	CommissionFeeCalculationMethod = Object.CommissionFeeCalculationMethod;
	RemunerationPercentage = Object.RemunerationPercentage;
	CommissionAmount = Object.CommissionAmount;

	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	AccountingForTraceableGoodsLocalization.SetTitleNumberOfCCD(Items, "GoodsCCDNumber");

	VATAccountingERP.SetVisibilityOfCommandAndFillInVATRate(ThisObject);
	
	AddSBPPaymentStatusUpdateCommand();

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
	// The end of the standard subsystem.Pluggable commands
	// Standard subsystems.Worksfiles
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	ForceCloseTheForm = True;
	
EndProcedure

&AtClient
Procedure OnClose()
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)

	If ChoiceSource.FormName = "CommonForm.SelectByGoodsTransferredToCommissionAgent" Then
		
		GetProductsFromStorage(ValueSelected);
		
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectGoodsTransferredToCustody.Form.Form" Then
		
		PricesCalculated = True;
		SelectionProcessingSelectionOfTransferredGoods(ValueSelected, PricesCalculated);
		
	ElsIf VATAccountingERPClient.FinishedEditingInvoicesToCommissionAgent(ValueSelected, ChoiceSource) Then
		
		UpdateTextOfInvoiceToCommissionAgent();
		
	ElsIf VATAccountingERPClient.FinishedEditingInvoiceReceived(ValueSelected, ChoiceSource) Then
		
		UpdateTextOfInvoiceReceived();
		
	ElsIf ChoiceSource.FormName = "Catalog.InventoryKinds.Form.InventoryOwnerAttributesForm" Then
		
		GetStockTypesFromStorage(ValueSelected);
		
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);
		
	ElsIf PurchasesClient.ThisIsSelectionOfCCDNumber(ChoiceSource) Then
		
		ProcessSelectionOfCCDNumber(ValueSelected);
		
	EndIf;
	
	If Window <> Undefined Then
		Window.Activate();
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
	
	
	
	DocumentCorrectionClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	If EventName = "UpdateInformationSecurityDocumentAfterFillingItOut"  And Parameter.Find(Object.Ref) <> Undefined Then
		Read();
	ElsIf EventName = "UpdateIBDocumentAfterFillingItOutFromFile"  And Parameter.Find(Object.Ref) <> Undefined Then
		OnReadCreateAtServer();
	ElsIf EventName = "Entry_InvoiceOfCommissionAgent" Then
		UpdateTextOfInvoiceToCommissionAgent();
	ElsIf EventName = "Write_InvoiceIssued"
		And (Parameter.Property("OwnerForm") And Parameter.OwnerForm = UUID
			Or Parameter.Property("ListOfGrounds") And Parameter.ListOfGrounds.FindByValue(Object.Ref) <> Undefined) Then
		UpdateTextOfInvoiceToCommissionAgent();
	ElsIf EventName = "Write_VendorInvoiceReceived" Then
		UpdateTextOfInvoiceReceived();
	EndIf;

	If ARAPAccountingClient.NeedAlertProcessingCall(ThisObject, EventName, Parameter) Then
		ChangedPaymentServer(EventName, Parameter, Source);
	EndIf;
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
	If EventName = "WhenChangingAgreement"
		And Source = ThisObject Then
		ContractOnChange(Items[Parameter]);
	EndIf;
	
	If EventName = "SBPStatusHasBeenChanged" Then
		AddSBPPaymentStatusUpdateCommand();
		CashClientLocalization.CheckSBPPayment(ThisObject, Object.Ref, Object.Counterparty);
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	DocumentCorrection.OnReadAtServer(ThisForm, Items.LineCorrection);
	
	OnReadCreateAtServer();
	
	ARAPAccountingFormWork.FormWhenReadingOnServer(ThisForm);
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
	If NotExecuteCheck1BeforeWrite Then
		NotExecuteCheck1BeforeWrite = False;
		Return;
	EndIf;
	
	// If the document is carried out, the correctness of the payment schedule for the order
	If WriteParameters.WriteMode = DocumentWriteMode.Posting Then
		If CalculateRemuneration Then
		
			Cancel = True;
			AdditionalParameters = New Structure;
			AdditionalParameters.Insert("WriteParameters", WriteParameters);
			ConsignmentSalesClient.YouNeedToCalculateReward(
				New CallbackDescription("BeforeRecordingYouNeedToCalculateReward", ThisObject, AdditionalParameters),
				ThisForm);
			
		EndIf;
		
	EndIf;
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters, Cancel);
	
EndProcedure

&AtClient
Procedure BeforeRecordingYouNeedToCalculateReward(YouNeedToCalculateReward, AdditionalParameters) Export
	
	YouNeedToCalculateReward = YouNeedToCalculateReward = True;
	
	BeforeWriteAtClientServer(YouNeedToCalculateReward);
	
	If YouNeedToCalculateReward Then
		ConsignmentSalesClient.NotifyAboutEndOfCalculationOfRemuneration(Object.CommissionFeeCalculationMethod);
	EndIf;
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, AdditionalParameters.WriteParameters,,True);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtClientServer(YouNeedToCalculateReward)
	
	If YouNeedToCalculateReward Then
		CalculateServerCommission();
	EndIf;
	
	ARAPAccountingServerCall.FormBeforeRecordingOnClientServer(ThisForm);
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Handler of the "Properties" mechanism
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
		
	
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
	
	StructureCharacteristicsOfProducts = New Structure;
	StructureCharacteristicsOfProducts.Insert("FillInFeatureAttribute",	New Structure("Products", "ItemVariantsAreUsed"));
	StructureCharacteristicsOfProducts.Insert("FillInArticleAttribute",	New Structure("Products", "SKU"));
	StructureCharacteristicsOfProducts.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureCharacteristicsOfProducts.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
		StructureCharacteristicsOfProducts);
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureCharacteristicsOfProducts);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
	UpdateTextOfInvoiceReceived();
	
	UpdateTextOfInvoiceToCommissionAgent();
	
	ARAPAccountingFormWork.FormAfterRecordingOnServer(ThisForm, CurrentObject.AdditionalProperties);
	

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	
	UnlockFormDataForEdit();
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
	Notify("Write_ConsignmentReportFromCustomer", WriteParameters, Object.Ref);
	ARAPAccountingClient.FormAfterRecording(ThisForm);
		
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisForm, Object, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If CurrentPage.Name = "AdditionalPage"
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	If CurrentPage.Name = "MainGroup3" Then
		ARAPAccountingClient.UpdateHyperlinkTextPaymentSteps(ThisForm);
	EndIf;
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	RecalculatePrices_2 = False;
	
	If (ToUseTermsOfSales
		And ValueIsFilled(Object.Terms)
		And ValueIsFilled(Object.Currency)
		And Not ConsignmentSales25)
		Or (ValueIsFilled(Object.Contract)
		And ConsignmentSales25)
		And Object.Goods.Count() <> 0 Then
		
		ArrayOfBusinessOperations25 = New Array;
		ArrayOfBusinessOperations25.Add(PredefinedValue("Enum.BusinessTransactions.SalesViaCommissionAgent"));
		ArrayOfBusinessOperations25.Add(PredefinedValue("Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit"));
		
		If ArrayOfBusinessOperations25.Find(Object.BusinessOperation) <> Undefined Then
			
			If ValueIsFilled(Object.Contract) Then
				
				HandlerNotifications = New CallbackDescription("ContractOnChangeCompletion", ThisObject);
				EnterprisePricesFillingClient.AskQuestionAboutRecalculatingPriceWhenChangingAgreement(Object, HandlerNotifications);
				Return;
				
			EndIf;
			
		Else
			
			NotificationParameters = New Structure("RecalculatePrices_2", RecalculatePrices_2);
			HandlerNotifications = New CallbackDescription("DateOnChangeCompletion", ThisObject, NotificationParameters);
			EnterprisePricesFillingClient.AskQuestionAboutRecalculatingPriceWhenDateChanges(Object, HandlerNotifications);
			Return;
			
		EndIf;
		
	EndIf;
	
	DateWhenFragmentWasChanged(RecalculatePrices_2);
	
	
EndProcedure

&AtClient
Procedure DateOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	RecalculatePrices_2 = AdditionalParameters.RecalculatePrices_2;
	
	If QuestionResult = True Then
		RecalculatePrices_2 = True;
	EndIf;
	
	DateWhenFragmentWasChanged(RecalculatePrices_2);
	
EndProcedure

&AtClient
Procedure DateWhenFragmentWasChanged(Val RecalculatePrices_2)
	
	PricesCalculated = DateOnChangeServer(RecalculatePrices_2);
	
	If RecalculatePrices_2 Then
		SalesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated);
	EndIf;
	
EndProcedure

&AtClient
Procedure OrganizationOnChange()
	
	OrganizationOnChangeServer();
	
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	
	If ValueIsFilled(Object.Currency) Then
		
		ConsignmentSalesClient.CheckWhetherCurrencyConversionIsNecessaryCommissionReports(
			New CallbackDescription("CurrencyWhenQuestionChangesRecalculateCurrency", ThisObject),
			Object,
			DocumentCurrency);
		
	Else
		DocumentCurrency = Object.Currency;
	EndIf;
	
EndProcedure

&AtClient
Procedure CurrencyWhenQuestionChangesRecalculateCurrency(RecalculateCurrency, AdditionalParameters) Export
	
	CurrencyOnChangeServer(
		Object.Currency,
		RecalculateCurrency);
		
	PriceManagementSystemClient.NotifyAboutEndOfConversionOfAmountsIntoCurrency(DocumentCurrency, Object.Currency);
	
	DocumentCurrency = Object.Currency;
	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	If ValueIsFilled(Object.Partner) Then
		PartnerOnChangeServer();
		If ToUseTermsOfSales And ValueIsFilled(Object.Terms) Then
			SalesClient.NotifyEndOfFillingInDefaultSalesConditions();
		EndIf;
	EndIf;
	
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyOnChangeServer();
	
	
EndProcedure

&AtClient
Procedure VATTaxationOnChange(Item)
	
	ClearMessages();
	
	VATTaxationOnChangeServer();
	CalculateRemuneration = True;
	
EndProcedure

&AtClient
Procedure PriceIncludesVATOnChange(Item)
	
	PriceIncludesVATOnChangeServer(CachedValues);
	
EndProcedure

&AtServerNoContext
Function ParametersForRegisteringInvoicesReceivedServer(Val Object)
	
	Return Documents.ConsignmentReportFromCustomer.ParametersForRegisteringInvoicesReceived(Object);
	
EndFunction	

&AtClient
Procedure InvoiceTextReceivedURLProcessing(Item, Var_URL, StandardProcessing)
	
	RegistrationParameters = ParametersForRegisteringInvoicesReceivedServer(Object);
	
	VATAccountingERPClient.ProcessingNavigationLinkInvoicesReceived(
		ThisForm,
		Var_URL,
		StandardProcessing,
		RegistrationParameters);
		
EndProcedure

&AtServerNoContext
Function ParametersForRegisteringInvoicesToCommissionAgentServer(Val Object)
	
	Return Documents.ConsignmentReportFromCustomer.ParametersForRegisteringInvoicesToCommissionAgent(Object);
	
EndFunction

&AtClient
Procedure TextOfInvoiceToConsigneeURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	ClearMessages();
	RegistrationParameters = ParametersForRegisteringInvoicesToCommissionAgentServer(Object);
	
	VATAccountingERPClient.ProcessingOfInvoiceNavigationLinkToCommissionAgent(
		ThisForm,
		FormattedStringURL,
		StandardProcessing,
		RegistrationParameters);
			
		
	UpdateTextOfInvoiceToCommissionAgent();
	
EndProcedure

&AtClient
Procedure TermsOnChange(Item)
	
	If Not ValueIsFilled(Object.Terms) Then
		TheCommissionAgentDoesNotKeepRecordsOnTheRNPT = False;
		Return;
	EndIf;
	
	TermsOnChangeServer();
	SalesClient.NotifyEndOfFillingInTermsOfSale();
	
EndProcedure

&AtClient
Procedure ContractCreating(Item, StandardProcessing)
	
	SalesClient.OpenContractCreationForm(ThisObject, Item, "Object.Contract", Object.Partner, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ContractOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = True Then
		PricesCalculated = ContractOnChangeCompletionServer();
		SalesClient.NotifyAboutEndOfFillingInPricesUnderContract(PricesCalculated);
	Else
		VATTaxationOnChangeServer();
		CalculateRemuneration = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	MessageText = "";
	ContractOnChangeServer(MessageText);
	
	If ValueIsFilled(MessageText) Then
		ShowUserNotification(
			NStr("vi = 'Không thể điền đơn giá';
				|ru = 'Цены не могут быть заполнены';
				|en = 'Prices cannot be filled'; fa = 'Prices cannot be filled';
				|it = 'Цены не могут быть заполнены';
				|pl = 'Prices cannot be filled';
				|tr = 'Fiyatlar doldurulamıyor'"),
			,
			MessageText,
			PictureLib.Information32);
	EndIf;
	
EndProcedure

&AtClient
Procedure ContractStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("Organization", Object.Organization);
	FilterStructure1.Insert("DeletionMark", False);
	FilterStructure1.Insert("ARAPCurrency", Object.Currency);
	FilterStructure1.Insert("Counterparty", Object.Counterparty);
	FilterStructure1.Insert("Status", PredefinedValue("Enum.CounterpartyContractStatuses.Valid"));
	FilterStructure1.Insert("BusinessOperation", PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent"));
	FilterStructure1.Insert("ConductARAPAccountingThroughEndCustomers", False);
	FilterStructure1.Insert("ConsignmentSales25", ConsignmentSales25);
	FilterStructure1.Insert("DeletionMark", False);
	
	StructureOfSelectionParameters = New Structure;
	
	StructureOfSelectionParameters.Insert("Partner", Object.Partner);
	StructureOfSelectionParameters.Insert("Terms", Object.Terms);
	StructureOfSelectionParameters.Insert("Filter",FilterStructure1);
	StructureOfSelectionParameters.Insert("ChoiceMode", True);
	
	ListOfOrders_ = New ValueList;
	ListOfOrders_.Add(PredefinedValue("Enum.ARAPObjectSettings.ByOrders"));
	ListOfOrders_.Add(PredefinedValue("Enum.ARAPObjectSettings.ByCounterpartyContracts"));
	
	StructureOfSelectionParameters.Insert("AvailablePaymentTerms", ListOfOrders_);
	
	StructureOfSelectionParameters.Insert("Filter",FilterStructure1);
		OpenForm("Catalog.CounterpartyContracts.Form.ChoiceForm",
		StructureOfSelectionParameters,
		Item,
		Item,)
	
EndProcedure

&AtClient
Procedure TermsStartChoice(Item, ChoiceData, StandardProcessing)

	AgreementSelectionParameters = SalesClient.ParametersForStartingSelectionOfAgreementWithClient();
	
	AgreementSelectionParameters.Item                     = Item;
	AgreementSelectionParameters.Partner                     = Object.Partner;
	AgreementSelectionParameters.Document                    = Object.Terms;
	AgreementSelectionParameters.DocumentDate               = Object.Date;
	AgreementSelectionParameters.BusinessOperation       = DefaultBusinessTransaction;
	AgreementSelectionParameters.ConsignmentSales25       = ConsignmentSales25;
	AgreementSelectionParameters.FormDataStructure        = Object;
	
	SalesClient.StartSelectingAgreementWithClient(AgreementSelectionParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure ByPhysicalCountResultsOnChange(Item)
	
	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure CommissionFeeCalculationMethodOnChange(Item)
	
	If Not Object.CommissionFeeCalculationMethod = CommissionFeeCalculationMethod Then
		AdditionalParameters = New Structure("RestoreAttributes", False);
		Notification = New CallbackDescription(
			"MethodOfCalculatingRemunerationWhenChangingItIsNecessaryToCalculateRemunerationCompletion", ThisObject, AdditionalParameters);
		ConsignmentSalesClient.YouNeedToCalculateReward(Notification, ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure MethodOfCalculatingRemunerationWhenChangingItIsNecessaryToCalculateRemunerationCompletion(YouNeedToCalculateReward, AdditionalParameters) Export
	
	If YouNeedToCalculateReward = True Then
		CommissionFeeCalculationMethod = Object.CommissionFeeCalculationMethod;
		CalculateServerCommission();
		ConsignmentSalesClient.NotifyAboutEndOfCalculationOfRemuneration(Object.CommissionFeeCalculationMethod);
	ElsIf AdditionalParameters.RestoreAttributes Then
		Object.CommissionFeeCalculationMethod = CommissionFeeCalculationMethod;
	EndIf;
	
	CommissionFeeCalculationMethodOnChangeServer();
	
	If Object.CommissionFeeCalculationMethod = PredefinedValue("Enum.CommissionFeeCalculationMethods.NotCalculating") Then
		Object.RemunerationPercentage = 0;
		Object.CommissionAmount = 0;
		RemunerationPercentage = 0;
		CommissionAmount = 0;
		Object.OperationService = PredefinedValue("Catalog.Products.EmptyRef");
		Object.VATRateOfRemuneration = PredefinedValue("Catalog.VATRates.EmptyRef");
		Object.PaymentDate = Date(1, 1, 1, 0, 0, 0);
		Object.KeepCommissionFee = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure CommissionFeeCalculationMethodStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommissionFeeCalculationMethod = Object.CommissionFeeCalculationMethod;
	
EndProcedure

&AtClient
Procedure RemunerationPercentageOnChange(Item)
	
	If Not Object.RemunerationPercentage = RemunerationPercentage Then
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("RestoreAttributes", False);
		AdditionalParameters.Insert("ClearCommission", False);
		CallbackDescription = New CallbackDescription(
			"PercentageAmountOfRemunerationWhenChangingItIsNecessaryToCalculateEndRemuneration", ThisObject, AdditionalParameters);
		ConsignmentSalesClient.YouNeedToCalculateReward(CallbackDescription, ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure CommissionAmountOnChange(Item)

	If Not Object.CommissionAmount = CommissionAmount Then
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("RestoreAttributes", False);
		AdditionalParameters.Insert("ClearCommission", False);
		CallbackDescription = New CallbackDescription(
			"PercentageAmountOfRemunerationWhenChangingItIsNecessaryToCalculateEndRemuneration", ThisObject, AdditionalParameters);
		ConsignmentSalesClient.YouNeedToCalculateReward(CallbackDescription, ThisObject);
	EndIf;

EndProcedure

&AtClient
Procedure PercentageAmountOfRemunerationWhenChangingItIsNecessaryToCalculateEndRemuneration(YouNeedToCalculateReward, AdditionalParameters) Export
	
	If YouNeedToCalculateReward = True Then
		
		CalculateServerCommission();

		CalculationMethodForNotification = ?(
			AdditionalParameters.ClearCommission,
			PredefinedValue("Enum.CommissionFeeCalculationMethods.NotCalculating"),
			Object.CommissionFeeCalculationMethod);
		ConsignmentSalesClient.NotifyAboutEndOfCalculationOfRemuneration(CalculationMethodForNotification);

		RemunerationPercentage = Object.RemunerationPercentage;
		CommissionAmount = Object.CommissionAmount;

	ElsIf AdditionalParameters.RestoreAttributes Then

		Object.RemunerationPercentage = RemunerationPercentage;
		Object.CommissionAmount = CommissionAmount;

	EndIf;
	
EndProcedure

&AtClient
Procedure OperationServiceOnChange(Item)
	
	OperationServiceOnChangeServer();
	
EndProcedure

&AtClient
Procedure VATRateOfRemunerationOnChange(Item)
	
	ConsignmentSalesClient.VATRateOfRemunerationOnChange(Object, VATPercentage);
	
EndProcedure

&AtClient
Procedure KeepCommissionFeeOnChange(Item)
	
	CalculateFinalIndicatorsOfCommissionAgentSReport(ThisForm);
	KeepCommissionFeeOnChangeServer();
	
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
Procedure Decorationedonage(Item, StandardProcessing)
	
	
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(
		ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.GoodsPrice Then
		
		CurrentData = Items.Goods.CurrentData;
		If ValueIsFilled(CurrentData.PriceKind) Then
			ClearMessages();
			CommonClientServer.MessageToUser(
				NStr("vi = 'Để soạn đơn giá, hãy xóa dạng giá';
					|ru = 'Для редактирования цены очистите вид цены';
					|en = 'To edit the price, clear the price type'; fa = 'To edit the price, clear the price type';
					|it = 'Для редактирования цены очистите вид цены';
					|pl = 'To edit the price, clear the price type';
					|tr = 'Fiyatı düzenlemek için fiyat türünü temizleyin'"),
				Object.Ref,
				CommonClientServer.PathToTabularSection("Object.Goods", CurrentData.LineNumber, "PriceKind"),);
		EndIf;
		
	ElsIf ConsignmentSales25
		And Field = Items.GoodsSellingPrice Then
		
		CurrentData = Items.Goods.CurrentData;
		If ValueIsFilled(CurrentData.SellingPriceType) Then
			ClearMessages();
			CommonClientServer.MessageToUser(
				NStr("vi = 'Để soạn đơn giá, hãy xóa dạng giá';
					|ru = 'Для редактирования цены очистите вид цены';
					|en = 'To edit the price, clear the price type'; fa = 'To edit the price, clear the price type';
					|it = 'Для редактирования цены очистите вид цены';
					|pl = 'To edit the price, clear the price type';
					|tr = 'Fiyatı düzenlemek için fiyat türünü temizleyin'"),
				Object.Ref,
				CommonClientServer.PathToTabularSection("Object.Goods", CurrentData.LineNumber, "SellingPriceType"),);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsOnActivateCell(Item)
	
	If Item.CurrentItem = Items.GoodsCCDNumber Then
		
		PurchasesClient.FillInListOfCCDNumberSelection(
			Items.Goods.CurrentData, Items.GoodsCCDNumber.ChoiceList);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	CurrentRow = Items.Goods.CurrentData;
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
	
	SalesClient.ProductItemLineAtBeginningOfEditing(ThisForm, "Goods", CurrentRow, NewRow, Copy);
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters,
		Copy);

EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CheckSeriesCalculateStatus = New Structure;
	CheckSeriesCalculateStatus.Insert("Warehouse",                  PredefinedValue("Catalog.Warehouses.EmptyRef"));
	CheckSeriesCalculateStatus.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters);
	FillInProductTypeAttribute_ = New Structure("Products", "ItemsType");

	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner"      , CurrentRow.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	If (ToUseTermsOfSales And ValueIsFilled(Object.Terms)) 
		Or (Not ToUseTermsOfSales And UsePriceManagementSystem25) Then
		StructureOfActions.Insert("FillIn_TermsOfSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
	Else
		StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	EndIf;
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));
	StructureOfActions.Insert("ClearRewardAmount");
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("CheckSeriesCalculateStatus",        CheckSeriesCalculateStatus);
	StructureOfActions.Insert("FillInProductTypeAttribute_",       FillInProductTypeAttribute_);
	StructureOfActions.Insert("FillInHSCode", Object.VATTaxation);
	StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActions.Insert("FillInCountryOfOriginOfProduct",
								BatchProcessingOfTablePartClientServer.CountryOfOriginFillingParameters());
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
		StructureOfActions);
	
	AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(ThisForm, StructureOfActions);
	
	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If Not CurrentRow.AccountingForTheRNPTIsMaintained Then
		CurrentRow.CCDNumber = Undefined;
		CurrentRow.CCDNumberType = Undefined;
		CurrentRow.OriginCountry = Undefined;
	EndIf;
	
	CalculateFinalIndicatorsOfCommissionAgentSReport(ThisForm);
	
	CalculateRemuneration = True;
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	If (ToUseTermsOfSales And ValueIsFilled(Object.Terms)) 
		Or (Not ToUseTermsOfSales And UsePriceManagementSystem25) Then
		StructureOfActions.Insert("FillIn_TermsOfSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
	Else
		StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	EndIf;
	
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	StructureOfActions.Insert("RecalculateVATAmount",  BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));

	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	CalculateFinalIndicatorsOfCommissionAgentSReport(ThisForm);
	
	CurrentRow.CommissionAmount = 0;
	CalculateRemuneration = True;

EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)
	
	ClearMessages();

	CurrentRow = Items.Goods.CurrentData;
	
	If CurrentRow.Count = 0 Then
		RecalculateBalancesBasedOnAccountingDataServer(CurrentRow.LineNumber);
		CurrentRow.NumberOfPackagesReal = CurrentRow.NumberOfPackagesAccounting;
	Else

		QuantityBeforeRecalculation = CurrentRow.Count;
		
		ConsignmentSalesClient.CommissionAgentSReportGoodsPackagingWhenChanged(Object, CurrentRow,
			ToUseTermsOfSales, CachedValues);
		
		If CurrentRow.Count <> QuantityBeforeRecalculation And CurrentRow.Count <> 0 Then
			CurrentRow.NumberOfPackagesAccounting = Round(CurrentRow.NumberOfPackagesAccounting * QuantityBeforeRecalculation / CurrentRow.Count, 2, 1);
			CurrentRow.NumberOfPackagesReal = CurrentRow.NumberOfPackagesAccounting - CurrentRow.NumberOfPackages;
		EndIf;
		
	EndIf;
	
	CalculateFinalIndicatorsOfCommissionAgentSReport(ThisForm);

	CalculateRemuneration = True;

EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	ConsignmentSalesClient.CommissionAgentSReportGoodsNumberOfPackagesWhenChanged(Object, CurrentRow, CachedValues);;
	
	CalculateRemuneration = True;
	CalculateFinalIndicatorsOfCommissionAgentSReport(ThisForm);

EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesRealOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackagesAfterFact");
	SelfServiceClientServer.AddCommissionAgentSReportToActionStructureWhenChangingNumberOfPackages(StructureOfActions, Object);
	
	AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(ThisForm, StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateRemuneration = True;
	CalculateFinalIndicatorsOfCommissionAgentSReport(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsPriceKindOnChange(Item)
	
	ClearMessages();

	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	StructureOfActions.Insert("RecalculateVATAmount",  BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));
	StructureOfActions.Insert("ClearRewardAmount");

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

	CalculateRemuneration = True;
	CalculateFinalIndicatorsOfCommissionAgentSReport(ThisForm);

EndProcedure

&AtClient
Procedure GoodsSellingPriceTypeOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	ParametersForFillingInSalePrice = BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object);
	ParametersForFillingInSalePrice.Insert("NameOfPriceField", "SellingPrice");
	ParametersForFillingInSalePrice.Insert("ColumnNamePriceType", "SellingPriceType");
	
	StructureOfActions.Insert("FillInSalePrice", ParametersForFillingInSalePrice);
	StructureOfActions.Insert("ClearRewardAmount");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	ConsignmentSalesClient.CommissionAgentSReportProductsSalePriceWhenChanged(CurrentRow, CachedValues);
	
	CalculateRemuneration = True;
	CalculateFinalIndicatorsOfCommissionAgentSReport(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsPriceOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount",  BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));
	StructureOfActions.Insert("ClearRewardAmount");

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateRemuneration = True;
	CalculateFinalIndicatorsOfCommissionAgentSReport(ThisForm);

EndProcedure

&AtClient
Procedure GoodsSumOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePriceDiscountByAmountInSales");
	StructureOfActions.Insert("RecalculateVATAmount",  BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));
	StructureOfActions.Insert("ClearRewardAmount");

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateRemuneration = True;
	CalculateFinalIndicatorsOfCommissionAgentSReport(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsVATAmountOnChange(Item)
	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));
	StructureOfActions.Insert("ClearRewardAmount");

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateRemuneration = True;
	CalculateFinalIndicatorsOfCommissionAgentSReport(ThisForm);
EndProcedure

&AtClient
Procedure GoodsVATRateOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));
	StructureOfActions.Insert("RecalculateVATSalesAmount");
	StructureOfActions.Insert("ClearRewardAmount");

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

	CalculateRemuneration = True;
	CalculateFinalIndicatorsOfCommissionAgentSReport(ThisForm);

EndProcedure

&AtClient
Procedure GoodsSellingPriceOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	ConsignmentSalesClient.CommissionAgentSReportProductsSalePriceWhenChanged(CurrentRow, CachedValues);

	CalculateRemuneration = True;
	CalculateFinalIndicatorsOfCommissionAgentSReport(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsSalesAmountOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateSalePriceBySaleAmount");
	StructureOfActions.Insert("RecalculateVATSalesAmount");
	StructureOfActions.Insert("ClearRewardAmount");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateRemuneration = True;
	CalculateFinalIndicatorsOfCommissionAgentSReport(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsAmountSalesVATOnChange(Item)
	
	CalculateRemuneration = True;
	CalculateFinalIndicatorsOfCommissionAgentSReport(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsCommissionAmountOnChange(Item)
	
	Object.CommissionAmount = Object.Goods.Total("CommissionAmount");
	TotalSalesAmount = Object.Goods.Total("SalesAmount");
	Object.RemunerationPercentage = ?(TotalSalesAmount <> 0, Object.CommissionAmount / TotalSalesAmount * 100, 0);
	ConsignmentSalesClient.CalculateCommissionFeeVAT(Object, VATPercentage);
	CalculateFinalIndicatorsOfCommissionAgentSReport(ThisForm);
	
	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure GoodsCustomerOnChange(Item)
	

EndProcedure

&AtClient
Procedure GoodsDateOfTaxInvoiceIssuedByCommissionAgentOnChange(Item)
	

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
	FillPropertyValues(AdditionalParameters, ThisObject);
	
	AdditionalParameters.BasisOfCostOfAdmission = False;
	
	CreationParameters = PurchasesClient.ParametersForCreatingCCDNumber(CurrentData,
																Item.EditText,
																AdditionalParameters);
	
	PurchasesClient.OpenFormForCreatingGTDNumber(ThisObject, CreationParameters);
	
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
Procedure SetDateInterval(Command)
	
	TMCommonUseClient.EditPeriod(Object, 
		New Structure("StartDate, EndDate", "BeginOfPeriod", "EndOfPeriod"));

EndProcedure

&AtClient
Procedure SelectionByStock(Command)
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.CheckedAttributes.Insert("Organization", NStr("vi = 'Doanh nghiệp';
																	|ru = 'Организация';
																	|en = 'Company'; fa = 'Company';
																	|it = 'Azienda';
																	|pl = 'Firma';
																	|tr = 'İş yeri'"));
	CheckParameters.CheckedAttributes.Insert("Partner",     NStr("vi = 'Người nhận bán ký gửi';
																|ru = 'Комиссионер';
																|en = 'Consignee'; fa = 'امانت‌دار';
																|it = 'Commissionario';
																|pl = 'Komisant';
																|tr = 'Konsinye'"));
	If ConsignmentSales25 Then
		CheckParameters.CheckedAttributes.Insert("Contract", NStr("vi = 'Hợp đồng';
																	|ru = 'Договор';
																	|en = 'Contract'; fa = 'قرارداد';
																	|it = 'Contratto';
																	|pl = 'Umowa';
																	|tr = 'Sözleşme'"));
		CheckParameters.Insert("CheckForPromiscuity", False);
	EndIf;
	Notification = New CallbackDescription("SelectionByStockCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure RecalculateBalancesBasedOnAccountingData(Command)
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.CheckedAttributes.Insert("Organization", NStr("vi = 'Doanh nghiệp';
																	|ru = 'Организация';
																	|en = 'Company'; fa = 'Company';
																	|it = 'Azienda';
																	|pl = 'Firma';
																	|tr = 'İş yeri'"));
	CheckParameters.CheckedAttributes.Insert("Partner",     NStr("vi = 'Người nhận bán ký gửi';
																|ru = 'Комиссионер';
																|en = 'Consignee'; fa = 'امانت‌دار';
																|it = 'Commissionario';
																|pl = 'Komisant';
																|tr = 'Konsinye'"));
	Notification = New CallbackDescription("RecalculateBalancesBasedOnAccountingDataCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure OpenInventoryKinds(Command)
	
	OptionsForEditingInventoryTypes = PutGoodsAndStockTypesInStorage();
	
	FinancesClient.OpenInventoryKinds(ThisObject, OptionsForEditingInventoryTypes);
	
EndProcedure

&AtClient
Procedure SearchByBarcode(Command)
	
	ClearMessages();
	Notification = New CallbackDescription("SearchByBarcodeCompletion", ThisObject);
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);
	
EndProcedure

&AtClient
Procedure ImportDataFromPDT(Command)
	
	ClearMessages();
	
	EquipmentManagerClient.StartDownloadingDataFromTSD(
		New CallbackDescription("DownloadFromTSDCompletion", ThisObject),
		UUID);
	
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
Procedure SplitRow(Command)
	
	FormTable  = Items.Goods;
	TableData = Object.Goods;
	
	StringSplittingParameters = ProcessingOfTabularFormsClient.StringSplittingParameters();
	If Object.ByPhysicalCountResults Then
		StringSplittingParameters.Title = NStr("vi = 'Hãy nhập số dư theo thực tế trong dòng mới.';
												|ru = 'Введите остаток по факту в новой строке.';
												|en = 'Enter actual balance in a new line.'; fa = 'Enter actual balance in a new line.';
												|it = 'Inserire il saldo effettivo nella nuova riga.';
												|pl = 'Wprowadź saldo rzeczywiste w nowym wierszu.';
												|tr = 'Fiili bakiyeyi yeni satıra girin.'");
		StringSplittingParameters.FieldNameQuantity = "NumberOfPackagesReal";
	Else
		StringSplittingParameters.AllowZeroCount = False;
	EndIf;
	
	AdditionalParameters = AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfParametersForSplittingRowInTablePart(FormTable.CurrentData);
	
	Notification = New CallbackDescription("SplitRowCompletion", ThisObject, AdditionalParameters);
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, Notification, StringSplittingParameters);
	
EndProcedure

&AtClient
Procedure CalculateCommissionFee(Command)
	
	ConsignmentSalesClient.YouNeedToCalculateReward(
		New CallbackDescription("CalculateRewardItIsNecessaryToCalculateRewardCompletion", ThisObject),
		ThisForm);
	
EndProcedure

&AtClient
Procedure CalculateRewardItIsNecessaryToCalculateRewardCompletion(YouNeedToCalculateReward, AdditionalParameters) Export
	
	If YouNeedToCalculateReward = True Then
		CalculateServerCommission();
		ConsignmentSalesClient.NotifyAboutEndOfCalculationOfRemuneration(Object.CommissionFeeCalculationMethod);
		FormItemsManagement();
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm, True);
	
EndProcedure

&AtClient
Procedure FillThePricesByTermsOfSales(Command)
	
	ClearMessages();

	If EnterprisePricesFillingClient.ItIsNecessaryToFillInPricesByAgreement(Object, "Goods", NStr("vi = 'Hàng hóa';
																									|ru = 'Товары';
																									|en = 'Goods'; fa = 'کالاها';
																									|it = 'Merci';
																									|pl = 'Towary';
																									|tr = 'Ürünler'")) Then
		
		ErrorText = "";
		PricesCalculated = FillThePricesByTermsOfSalesServer(ErrorText);
		SalesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated, ErrorText);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInPricesUnderAgreement(Command)
	
	CommissionAgentSPriceType = GetContractPriceType("PriceTypeAccountingPriceType");
	SellingPriceType = GetContractPriceType("SalesPriceType");
	
	If EnterprisePricesFillingClient.YouNeedToFillInPricesByType(Object, CommissionAgentSPriceType)
		And EnterprisePricesFillingClient.YouNeedToFillInPricesByType(Object, SellingPriceType) Then
		
		PricesCalculated = FillInPricesByPriceKind("PriceTypeAccountingPriceType");
		PricesCalculated = FillInPricesByPriceKind("SalesPriceType") Or PricesCalculated;
		SalesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInCommitteePrices(Command)
	
	TypeOfContractPrice = GetContractPriceType("PriceTypeAccountingPriceType");
	
	If EnterprisePricesFillingClient.YouNeedToFillInPricesByType(Object, TypeOfContractPrice) Then
		
		PricesCalculated = FillInPricesByPriceKind("PriceTypeAccountingPriceType");
		SalesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInCustomerPrices(Command)
	
	TypeOfContractPrice = GetContractPriceType("SalesPriceType");
	
	If EnterprisePricesFillingClient.YouNeedToFillInPricesByType(Object, TypeOfContractPrice) Then
		
		PricesCalculated = FillInPricesByPriceKind("SalesPriceType");
		SalesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ImportFromExternalFile(Command)
	
	ImportParameters = ProcessingOfTabularFormsClient.ProductLoadingParameters();
	ImportParameters.Organization = Object.Organization;
	ImportParameters.ImportPrices = True;
	ImportParameters.PriceIncludesVAT    = Object.PriceIncludesVAT;
	ImportParameters.VATTaxation = Object.VATTaxation;
	ImportParameters.FillingDate     = Object.Date;
	ImportParameters.FilterParameters.Insert("ItemsType",
		ProductsClientServer.SelectionByProductReusablePackagingServiceWork(False));
	
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
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm, True);
	
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
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
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


&AtClient
Procedure PaymentSettlement(Command)
	
	PlacePaymentDecryptionInTemporaryStorage();
	ARAPAccountingClient.PaymentSettlement(ThisForm, Items.CreditPaymentForm);
	
EndProcedure

&AtClient
Procedure OffsetOfPaymentRemuneration(Command)
	
	PlacePaymentDecryptionInTemporaryStorage();
	ARAPAccountingClient.PaymentSettlement(ThisForm, Items.PaymentOffsetByRemuneration);
	
EndProcedure

&AtClient
Procedure FillInVATRate(Command)

	If Object.Goods.Count() = 0 Then
		WarningText = NStr("vi = 'Trong danh sách ""Hàng hóa"" chưa điền dòng nào.';
							|ru = 'В список ""Товары"" не введено ни одной строки.';
							|en = 'No lines entered in the Item list.'; fa = 'No lines entered in the Item list.';
							|it = 'В список ""Товары"" не введено ни одной строки.';
							|pl = 'Do listy ""Wiersze pozycji"" nie wprowadzono żadnego wiersza.';
							|tr = '""Ürünler"" listesine hiçbir satır girilmemiştir'");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;

	ClosingNotification1 = New CallbackDescription("FillInVATRateCompletion", ThisObject);
	FormParameters = New Structure();
	FormParameters.Insert("VATTaxationType", Object.VATTaxation);
	OpenForm("Catalog.VATRates.ChoiceForm", FormParameters,,,,, ClosingNotification1);

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
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm);
	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisForm, False);
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisForm,
		"SeriesWhenPlanningShipmentWHGoodsAreIndicated");
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsVATRate.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsVATAmount.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSum.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAmountSalesVAT.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.VATTaxation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT;

	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPrice.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PriceKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCommissionAgentSTaxInvoiceNumber.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDateOfTaxInvoiceIssuedByCommissionAgent.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCustomer.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.NumberOfPackages");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Không bắt buộc>';
													|ru = '<не требуется>';
													|en = '<not required>'; fa = '<الزامی نیست>';
													|it = '<non richiesto>';
													|pl = '<nie jest wymagane>';
													|tr = '<gerekli değil>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm);

	//

	EnterprisePricesFillingServer.EstablishConditionalAppearanceOfPriceTypes(ThisForm);

	//
	
	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisForm);
	
	//
	
	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForSalesTaxation(ThisForm);
	
	//
	
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfQuantityAccordingToRNPT(ThisObject);
	AccountingForTraceableGoodsLocalization.EstablishConditionalAppearanceOfAccountingOnGTDVDocumentsOfCommissionAgent(ThisObject);
	//
	
	EnterprisePricesFillingServer.EstablishConditionalAppearanceOfPriceTypes(ThisForm, "GoodsSellingPriceType", "Object.Goods.SellingPriceType");
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSellingPrice.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.SellingPriceType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

&AtClient
Procedure Attachable_CloseForm()
	
	If IsOpen() Then
		Close();
	EndIf;
	
EndProcedure

#Region OnChangeAttributes

&AtServer
Procedure OrganizationOnChangeServer()
	
	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible, Object.Contract);
	
	CashServer.CheckOrganizationSSalesRegisterByOwner(Object.Organization, Object.CashAccount, Object.PaymentMethod);
	
	If ValueIsFilled(Object.Organization) Then
		FillInDefaultContract();
		
		If UseLinesOfBusiness Then
			LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
		EndIf;
		
		UpdateTextOfInvoiceToCommissionAgent();
		
		UpdateTextOfInvoiceReceived();
		
		FillInSalesVATTaxation();
		VATTaxationOnChangeServer();
		
		RecalculateNumberOfRNPT();
	EndIf;
	
	CashServer.CheckFillInOrganizationSBankAccountByOwner(Object.Organization,
		Object.BankAccount, Object.PaymentMethod, , Object.ForeignCurrencyTransaction);
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Organization");
	FillInSubordinatePropertiesForStatistics("Organization");
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	FillInShipperSelectionList();
	
EndProcedure

&AtServer
Procedure CurrencyOnChangeServer(NewCurrency, RecalculateAmounts)
	
	FillInDefaultContract();
	Object.BankAccount = GetOrganizationSDefaultBankAccountServer();
	
	If RecalculateAmounts Then
		SalesServer.ConvertDocumentAmountToCurrency(
			Object,
			DocumentCurrency,
			Object.Currency,
			True, // ThereIsSaleAmount
			True); // ThereIsVATSaleAmount
		CalculateRemuneration = True;
		CalculateFinalIndicatorsOfCommissionAgentSReport(ThisForm);
	EndIf;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Currency");
	
	FillInSubordinatePropertiesForStatistics("Currency");
	
EndProcedure

&AtServer
Procedure PartnerOnChangeServer()
	
	ArrayOfChangedProps = New Array;
	ArrayOfChangedProps.Add("Partner");
	
	If ToUseTermsOfSales Then
		FillIn_TermsOfSales();
		ArrayOfChangedProps.Add("Currency");
		ArrayOfChangedProps.Add("LineOfBusiness");
		ArrayOfChangedProps.Add("Organization");
		ArrayOfChangedProps.Add("Counterparty");
		ArrayOfChangedProps.Add("Contract");
	EndIf;
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Partner, Object.Counterparty);
	PartnersAndCounterparties.FillInDefaultPartnerContactPerson(Object.Partner, Object.ContactPerson);
	
	DocumentCurrency = Object.Currency;
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, ArrayOfChangedProps);
	
	CalculateFinalIndicatorsOfCommissionAgentSReport(ThisForm);

	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	
	UpdateTextOfInvoiceToCommissionAgent();
	
	UpdateTextOfInvoiceReceived();	
	
	FormItemsManagement();
	
	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible, Object.Contract);
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	ResponsiblePersonsServer.FillInManager_(Object);
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	
	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible, Object.Contract);
	
	If ValueIsFilled(Object.Counterparty) Then
		FillInDefaultContract();
	EndIf;

	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	
	FillInShipperSelectionList();
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Counterparty");
	PurchasesServer.FillInSelectionListNameOfIncomingDocument(ThisObject, Object.Counterparty);
EndProcedure

&AtServer
Procedure ContractOnChangeServer(MessageText = "")
	
	ForeignCurrencyTransaction = Object.ForeignCurrencyTransaction;
	
	If ValueIsFilled(Object.Contract) Then
		
		CommissionAgentSPriceType = GetContractPriceType("PriceTypeAccountingPriceType");
		SellingPriceType = GetContractPriceType("SalesPriceType");
		
		If (Not CommissionAgentSPriceType.PriceIncludesVAT = Undefined 
				And Not Object.PriceIncludesVAT = CommissionAgentSPriceType.PriceIncludesVAT) 
			Or (Not SellingPriceType.PriceIncludesVAT = Undefined 
				And Not Object.PriceIncludesVAT = SellingPriceType.PriceIncludesVAT) Then
			
			MessageText = NStr("vi = 'Dấu hiệu ""Đơn giá gồm thuế GTGT"" khác nhau trong dạng giá hợp đồng và chứng từ';
								|ru = 'Признак ""Цена включает НДС"" различается в виде цен договора и документа';
								|en = 'The ""Price includes VAT"" checkbox has different statuses in the price type in the contract and in the document'; fa = 'The ""Price includes VAT"" checkbox has different statuses in the price type in the contract and in the document';
								|it = 'Признак ""Цена включает НДС"" различается в виде цен договора и документа';
								|pl = 'The ""Price includes VAT"" checkbox has different statuses in the price type in the contract and in the document';
								|tr = '""Fiyata KDV dahildir"" özelliği sözleşme ve belge fiyatlarını birbirinden ayırır'");
		
		EndIf;
		
	EndIf;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Contract");
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	
	If Object.ForeignCurrencyTransaction <> ForeignCurrencyTransaction Then
		Object.BankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
	EndIf;
	
	SalesServer.FillInBankAccountsUnderAgreement(Object.Contract, Object.BankAccount);
	Object.BankAccount = GetOrganizationSDefaultBankAccountServer();
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();
	ResponsiblePersonsServer.FillInManager_(Object);
	FillInSubordinatePropertiesForStatistics("Contract");
	
EndProcedure

&AtServer
Procedure VATTaxationOnChangeServer()
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("AdjustVATRate",  BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object));
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));
	StructureOfActions.Insert("RecalculateVATSalesAmount");
	StructureOfActions.Insert("ClearRewardAmount");
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValues.ProcessedRows,
		StructureOfActions,
		Object.Goods,
		Undefined);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInHSCode", Object.VATTaxation);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	CalculateFinalIndicatorsOfCommissionAgentSReport(ThisForm);
	
	CalculateRemuneration = True;

	VATAccountingERP.SetVisibilityOfCommandAndFillInVATRate(ThisObject);
	UpdateVATRateOfRemuneration();
	
EndProcedure

&AtServer
Procedure UpdateVATRateOfRemuneration() 
	
	StructureOfFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	
	CurrentRow = New Structure("VATRate", Catalogs.VATRates.EmptyRef());
	StructureOfActions = New Structure;
	StructureOfActions.Insert("AdjustVATRate", StructureOfFillingInVATRate);
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentRow, StructureOfActions, Undefined);
	Object.VATRateOfRemuneration = CurrentRow.VATRate;
	
	Object.AmountVATRemuneration = VATAccountingERPClientServer.CalculateVATAmount(Object.CommissionAmount,
		VATAccountingERPClientServer.ValueOfVATRate(Object.VATRateOfRemuneration));
	
EndProcedure

&AtServer
Procedure PriceIncludesVATOnChangeServer(CachedValues)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object));
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	CalculateFinalIndicatorsOfCommissionAgentSReport(ThisForm);
	
	Items.GoodsSum.Visible = Not Object.PriceIncludesVAT;
	
EndProcedure

&AtServer
Procedure TermsOnChangeServer()
	
	DocumentObject = FormAttributeToValue("Object");
	DocumentObject.FillInTermsOfSalesUnderAgreement();
	ResponsiblePersonsServer.FillInManager_(DocumentObject);
	ValueToFormAttribute(DocumentObject, "Object");
	
	FillInCommissionAgentDoesNotKeepRecordsOfRPTOnServer();
	
	ConsignmentSalesServer.CalculateRewardAmount(Object,, True);
	CalculateRemuneration = False;
	
	StructureCharacteristicsOfProducts = New Structure;
	StructureCharacteristicsOfProducts.Insert("FillInFeatureAttribute",	New Structure("Products", "ItemVariantsAreUsed"));
	StructureCharacteristicsOfProducts.Insert("FillInArticleAttribute",	New Structure("Products", "SKU"));
	StructureCharacteristicsOfProducts.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureCharacteristicsOfProducts.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
		StructureCharacteristicsOfProducts);
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureCharacteristicsOfProducts);
	
	DocumentCurrency = Object.Currency;
	
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	FillInCommissionAgentDoesNotKeepRecordsOfRPTOnServer();
	
	ArrayOfChangedProps = New Array;
	
	ArrayOfChangedProps.Add("Partner");
	ArrayOfChangedProps.Add("Currency");
	ArrayOfChangedProps.Add("LineOfBusiness");
	ArrayOfChangedProps.Add("Organization");
	ArrayOfChangedProps.Add("Counterparty");
	ArrayOfChangedProps.Add("Contract");
	ArrayOfChangedProps.Add("CommissionFeeCalculationMethod");
	ArrayOfChangedProps.Add("KeepCommissionFee");
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, ArrayOfChangedProps);
	
	FormItemsManagement();
	
	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible, Object.Contract);
	
	UpdateTextOfInvoiceToCommissionAgent();
	
	UpdateTextOfInvoiceReceived();

	CalculateFinalIndicatorsOfCommissionAgentSReport(ThisForm);
	
	FillInSubordinatePropertiesForStatistics("Contract");

	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
EndProcedure

&AtServer
Function ContractOnChangeCompletionServer()
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions = New Structure;
	StructureOfActions.Insert("AdjustVATRate",  BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);

	PricesCalculated = FillInPricesByPriceKind("PriceTypeAccountingPriceType");
	PricesCalculated = FillInPricesByPriceKind("SalesPriceType") Or PricesCalculated;
		
	UpdateVATRateOfRemuneration();
	
	Return PricesCalculated;
	
EndFunction


&AtServer
Procedure OperationServiceOnChangeServer()
	
	ConsignmentSalesServer.FillInLBRateOfJointCommissionRemuneration(Object, VATPercentage);
	
EndProcedure

&AtServer
Procedure CommissionFeeCalculationMethodOnChangeServer()
	
	FormItemsManagement();
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "CommissionFeeCalculationMethod");
	UpdateTextOfInvoiceReceived();
	
EndProcedure

&AtServer
Procedure FillInCommissionAgentDoesNotKeepRecordsOfRPTOnServer()
	
	TheCommissionAgentDoesNotKeepRecordsOnTheRNPT =
		Not Catalogs.TermsOfSale.CommissionAgentUsesInventoryAccountingByProductBatchID(Object.Terms);
	
EndProcedure

&AtServer
Function DateOnChangeServer(RecalculatePrices_2)
	
	UseTraceableImportedGoodsAccounting =
		AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(Object.Date);
	
	AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(ThisForm, Object.Date);
	
	If Not Items.ProductsGroupQuantityByRNPT.Visible Then
		RecalculateNumberOfRNPT();
	EndIf;
	
	If RecalculatePrices_2 Then
		PricesCalculated = FillThePricesByTermsOfSalesServer();
	Else
		PricesCalculated = False;
	EndIf;
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	Return PricesCalculated;
	
EndFunction

&AtClientAtServerNoContext
Procedure AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(Form, StructureOfActions)
	
	If Form.TheCommissionAgentDoesNotKeepRecordsOnTheRNPT Then
		Return;
	EndIf;
	
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Form.Object,
		StructureOfActions,
		"Partner");
	
EndProcedure

&AtClient
Procedure GoodsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	OpenSelectionOfSeries(Item.EditText);
	
EndProcedure

&AtClient
Procedure GoodsSeriesOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	ValueSelected                            = ProductsClientServer.SelectedSeries();
	ValueSelected.Value                   = CurrentRow.Series;
	ValueSelected.CurrentRowID = CurrentRow.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);
	
EndProcedure

#EndRegion

#Region SelectionAndProcessingOfQuantityVerification

// This procedure is used in the AutoTest of the sales process.
//
&AtServer
Function PutProductsInStorage(Val Goods, Var_UUID)

	AddressOfPaymentsInTheStorage = PutToTempStorage(
		Goods.Unload(,"Products, Characteristic, CCDNumber, Count, QuantityByGBRN"),
		Var_UUID);
		
	Return AddressOfPaymentsInTheStorage;
	
EndFunction

&AtServer
Function PutGoodsInVaultWithSeries(Val Goods, Var_UUID)

	AddressOfPaymentsInTheStorage = PutToTempStorage(
		Goods.Unload(,"LineNumber, Products, Characteristic, CCDNumber, Series, Count"),
		Var_UUID);
		
	Return AddressOfPaymentsInTheStorage;
	
EndFunction

&AtServer
Function PutGoodsAndStockTypesInStorage()
	
	Return InventoriesServer.PutGoodsAndStockTypesInStorage(ThisObject);
		
EndFunction

&AtServer
Procedure GetStockTypesFromStorage(ValueSelected)
	
	InventoriesServer.ProcessInputOfInventoryTypesManually(ValueSelected, ThisForm);
	
EndProcedure

&AtServer
Procedure GetProductsFromStorage(AddressOfPaymentsInTheStorage)
	
	Var CachedValues;
	
	Object.Goods.Load(GetFromTempStorage(AddressOfPaymentsInTheStorage));
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	FillParameters = New Structure;
	FillParameters.Insert("Date", ?(ValueIsFilled(Object.EndOfPeriod), Object.EndOfPeriod, Object.Date));
	FillParameters.Insert("Currency", Object.Currency);
	FillParameters.Insert("Organization", Object.Organization);
	FillParameters.Insert("Terms", Object.Terms);
	FillParameters.Insert("VATTaxation", Object.VATTaxation);
	FillParameters.Insert("PopulationFields", "Price, VATRate, PriceKind");
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	
	EnterprisePricesFillingServer.FillInPrices(
		Object.Goods, // Table part
		, // Array of rows or selection structure
		FillParameters,
		StructureOfActions);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	StructureOfActions.Insert("RecalculateSaleAmountByAmountWithVAT");
	StructureOfActions.Insert("RecalculateSalePriceBySaleAmount");
	StructureOfActions.Insert("RecalculateVATSalesAmount");
	StructureOfActions.Insert("ClearRewardAmount");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActions.Insert("FillInHSCode", Object.VATTaxation);
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
		StructureOfActions);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	
	CalculateRemuneration = True;
	
	StructureCharacteristicsOfProducts = New Structure;
	StructureCharacteristicsOfProducts.Insert("FillInFeatureAttribute",	New Structure("Products", "ItemVariantsAreUsed"));
	StructureCharacteristicsOfProducts.Insert("FillInArticleAttribute",	New Structure("Products", "SKU"));
	StructureCharacteristicsOfProducts.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureCharacteristicsOfProducts);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
	RecalculateNumberOfRNPT();
	
EndProcedure

&AtServer
Procedure SelectionProcessingSelectionOfTransferredGoods(ValueSelected, PricesCalculated)
	
	ArrayOfRowsForRecalculatingPrices = New Array();
	RowsToProcess = New Array();
	
	TableOfGoods       = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	CollapseGTDNumbers = Not UseTraceableImportedGoodsAccounting Or TheCommissionAgentDoesNotKeepRecordsOnTheRNPT;
	
	CheckSeriesCalculateStatus = New Structure;
	CheckSeriesCalculateStatus.Insert("Warehouse",                  PredefinedValue("Catalog.Warehouses.EmptyRef"));
	CheckSeriesCalculateStatus.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters);
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	StructureOfActions.Insert("CheckSeriesCalculateStatus",        CheckSeriesCalculateStatus);
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInVATRate",  BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInHSCode", Object.VATTaxation);
	StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActions.Insert("CheckCharacteristicsByOwner");
	StructureOfActions.Insert("CheckFillPackageByOwner");
	
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActions,
		"Partner");
	
	For Each RowOfProduct In TableOfGoods Do
		
		ProductsSearch = New Structure();
		ProductsSearch.Insert("Products", RowOfProduct.Products);
		ProductsSearch.Insert("Characteristic", RowOfProduct.Characteristic);
		ProductsSearch.Insert("Series", RowOfProduct.Series);
		If Not CollapseGTDNumbers Then
			ProductsSearch.Insert("CCDNumber", RowOfProduct.CCDNumber);
		EndIf;
		ProductLines_2 = Object.Goods.FindRows(ProductsSearch);
		
		If ProductLines_2.Count() = 0 Then
			
			If Object.ByPhysicalCountResults And RowOfProduct.QuantityIsSelected = 0 Then
				Continue;
			EndIf;
			CurrentRow = Object.Goods.Add();
			
		ElsIf ProductLines_2.Count() = 1 Then
			
			CurrentRow = ProductLines_2[0];
			If Object.ByPhysicalCountResults And RowOfProduct.QuantityIsSelected = 0 Then
				Object.Goods.Delete(CurrentRow);
				Continue;
			EndIf;
			
		ElsIf ProductLines_2.Count() > 1 Then
			For Each RowToDelete In ProductLines_2 Do
				Object.Goods.Delete(RowToDelete);
			EndDo;
			If Object.ByPhysicalCountResults And RowOfProduct.QuantityIsSelected = 0 Then
				Continue;
			EndIf;
			CurrentRow = Object.Goods.Add();
		EndIf;
		
		FillPropertyValues(CurrentRow, RowOfProduct);
		
		If CurrentRow.Count <> RowOfProduct.QuantityIsSelected Then
			ArrayOfRowsForRecalculatingPrices.Add(CurrentRow);
		EndIf;
		
		CurrentRow.Count = RowOfProduct.QuantityIsSelected;
		CurrentRow.NumberOfPackagesAccounting = RowOfProduct.CountBalance;
		CurrentRow.NumberOfPackagesReal = RowOfProduct.LeftToSelect;
		
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	FillInPricesByPriceKind("PriceTypeAccountingPriceType", ArrayOfRowsForRecalculatingPrices);
	FillInPricesByPriceKind("SalesPriceType", ArrayOfRowsForRecalculatingPrices);
	
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
	If (ToUseTermsOfSales And ValueIsFilled(Object.Terms)) 
		Or (Not ToUseTermsOfSales And UsePriceManagementSystem25) Then
		StructureOfActionsWithAddedStrings.Insert("FillIn_TermsOfSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
	Else
		StructureOfActionsWithAddedStrings.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	EndIf;
	StructureOfActionsWithAddedStrings.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	StructureOfActionsWithAddedStrings.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsWithAddedStrings.Insert("FillInHSCode", Object.VATTaxation);
	SelfServiceClientServer.AddCommissionAgentSReportToActionStructureWhenChangingNumberOfPackages(StructureOfActionsWithAddedStrings, Object);
	StructureOfActionsWithAddedStrings.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
		StructureOfActionsWithAddedStrings);
	
	AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(ThisObject, StructureOfActionsWithAddedStrings);
	
	StructureOfActionsWithModifiedStrings = New Structure;
	SelfServiceClientServer.AddCommissionAgentSReportToActionStructureWhenChangingNumberOfPackages(StructureOfActionsWithModifiedStrings, Object);
	AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(ThisObject, StructureOfActionsWithModifiedStrings);
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	StructureOfActions.SeriesSpecificationParameters                 = ?(ConsignmentSales25, SeriesSpecificationParameters, Undefined);
	
	ProcessBarcodesServer(StructureOfActions, CachedValues);
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(StructureOfActions, CachedValues, ThisObject);
	
	If BarcodingOfItemsClient.YouNeedToOpenFormForSpecifyingSeriesAfterProcessingBarcodes(StructureOfActions) Then
		CurDataId = StructureOfActions.ArrayOfRowsWithSeries_[0];
		
		AttachIdleHandler("OpenSeriesSelectionWhenScanningProductBarCode", 0.1, True);
	EndIf;
	
	CalculateRemuneration = True;
	
	If StructureOfActions.CurrentRow <> Undefined Then
		Items.Goods.CurrentRow = StructureOfActions.CurrentRow;
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessBarcodesServer(StructureOfActionParameters, CachedValues)
	
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject, Object, StructureOfActionParameters, CachedValues);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
EndProcedure

#EndRegion

#Region FormItemsManagement

&AtServer
Procedure FormItemsManagement()
	
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	
	Documents.ConsignmentReportFromCustomer.FillInNamesOfBusinessTransactionDetails(
		Object.CommissionFeeCalculationMethod,
		ArrayOfAllProps, 
		ArrayOfOperationDetails);
	CashServer.SetAvailabilityOfElementsByArray(
		Items,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	Items.GoodsSum.Visible = Not Object.PriceIncludesVAT;
	Items.GoodsNumberOfPackagesAccounting.Visible = Object.ByPhysicalCountResults;
	Items.GoodsNumberOfPackagesReal.Visible = Object.ByPhysicalCountResults;
	Items.GoodsRecalculateBalancesBasedOnAccountingData.Visible = Object.ByPhysicalCountResults;
	
	Items.GoodsSplitRow.Visible = Not Object.ByPhysicalCountResults;
	Items.GoodsContextMenuSplitRow.Visible = Not Object.ByPhysicalCountResults;
	
	CalculationMethodNotCalculated = (Object.CommissionFeeCalculationMethod = Enums.CommissionFeeCalculationMethods.NotCalculating);
	Items.PaymentOffsetByRemuneration.Enabled = Not Object.KeepCommissionFee And Not CalculationMethodNotCalculated
													And Object.CommissionAmount > 0;

	Items.PaymentDate.Enabled = Not Object.KeepCommissionFee And Not CalculationMethodNotCalculated;	

	CalculationMethodIsArbitraryAmount = (Object.CommissionFeeCalculationMethod = Enums.CommissionFeeCalculationMethods.ArbitraryAmount);
	CommonClientServer.SetFormItemProperty(Items, "RemunerationPercentage", "Visible", Not CalculationMethodIsArbitraryAmount);
	CommonClientServer.SetFormItemProperty(Items, "CommissionAmount", "ReadOnly", Not CalculationMethodIsArbitraryAmount);
	
	AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(ThisForm, Object.Date);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure OnReadCreateAtServer()
	
	ToUseTermsOfSales               = GetFunctionalOption("ToUseTermsOfSales");
	UsePaymentSchedules                      = GetFunctionalOption("UsePaymentSchedules");
	UseSimplifiedPaymentScheme              = GetFunctionalOption("UseSimplifiedPaymentSchemeInSales");
	UseLinesOfBusiness            = GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness");
	UsePartnersAsCounterparties           = GetFunctionalOption("UsePartnersAsCounterparties");
	UseTraceableImportedGoodsAccounting =
		AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(Object.Date);
	SeriesSpecificationParameters         = SeriesSpecificationParameters();
	ConsignmentSales25 = ?(Object.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgent,
		True, False);
	
	Items.CounterpartyGroup.Visible = Not UsePartnersAsCounterparties;
	
	If Not ToUseTermsOfSales Then
		PriceTypeSelectionParameters = SettingsValueCached.ParametersForSelectingDefaultPriceType();
	
		PriceTypeSelectionParameters.PriceIncludesVAT        = Object.PriceIncludesVAT;
		PriceTypeSelectionParameters.UseWhileSellingToCustomers = True;
		PriceTypeSelectionParameters.Status                 = Enums.StatusesOfPriceTypeValidity.Valid;
		
		DefaultPriceType = SettingsValueCached.DefaultPriceType(PriceTypeSelectionParameters);
	EndIf;
	
	DocumentCurrency = Object.Currency;
	
	FormItemsManagement();
	VATPercentage = PriceManagementSystemClientServer.GetVATRateAsNumber(Object.VATRateOfRemuneration);
	
	CalculateFinalIndicatorsOfCommissionAgentSReport(ThisForm);
	
	StructureCharacteristicsOfProducts = New Structure;
	StructureCharacteristicsOfProducts.Insert("FillInFeatureAttribute",	New Structure("Products", "ItemVariantsAreUsed"));
	StructureCharacteristicsOfProducts.Insert("FillInArticleAttribute",	New Structure("Products", "SKU"));
	StructureCharacteristicsOfProducts.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureCharacteristicsOfProducts.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
		StructureCharacteristicsOfProducts);
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureCharacteristicsOfProducts);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible);
	
	UpdateTextOfInvoiceToCommissionAgent();
	
	UpdateTextOfInvoiceReceived();
	
	FillInShipperSelectionList();
	
	SetVisibilityOfSeriesElements();
	ProcessingOfTabularForms.InitializeRowCache(Items.Goods);
	
	FillParameters = Documents.ConsignmentReportFromCustomer.ParametersForFillingInSalesVATTaxation(Object);
	VATAccountingERP.FillInSalesVATTaxSelectionList(Items.VATTaxation, Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues);
	PurchasesServer.FillInSelectionListNameOfIncomingDocument(ThisObject, Object.Counterparty);
	
	FillInCommissionAgentDoesNotKeepRecordsOfRPTOnServer();
	
	SetPropertiesOfOutdatedCommissionUsageComment();
	
EndProcedure

&AtServer
Procedure FillInDefaultContract()
	
	If Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts 
		And UseLinesOfBusiness Then
		Contract = SalesServer.GetDefaultContract(
			Object,
			Enums.BusinessTransactions.TransferToCommissionAgent,
			Object.Currency,
			Object.LineOfBusiness);
	Else
		Contract = SalesServer.GetDefaultContract(
			Object,
			Enums.BusinessTransactions.TransferToCommissionAgent,
			Object.Currency);
	EndIf;
		
	If Contract <> Object.Contract Then
		Object.Contract = Contract;
		ForeignCurrencyTransaction = Object.ForeignCurrencyTransaction;
		ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Contract");
		If ForeignCurrencyTransaction <> Object.ForeignCurrencyTransaction Then
			Object.BankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
		EndIf;
		SalesServer.FillInBankAccountsUnderAgreement(Object.Contract, Object.BankAccount);
	EndIf;
	
EndProcedure

&AtServer
Procedure CalculateServerCommission()
	
	ConsignmentSalesServer.CalculateRewardAmount(Object,, True);
	CalculateRemuneration = False;
	
	FormItemsManagement();
	
EndProcedure

&AtServer
Function FillThePricesByTermsOfSalesServer(ErrorText = "")
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	FillParameters = New Structure;
	FillParameters.Insert("Date", ?(ValueIsFilled(Object.EndOfPeriod), Object.EndOfPeriod, Object.Date));
	FillParameters.Insert("Currency", Object.Currency);
	FillParameters.Insert("Organization", Object.Organization);
	FillParameters.Insert("Partner", Object.Partner);
	FillParameters.Insert("Terms", Object.Terms);
	FillParameters.Insert("VATTaxation", Object.VATTaxation);
	FillParameters.Insert("PopulationFields", "Price, VATRate, PriceKind");
	If ConsignmentSales25 Then
		FillParameters.Insert("PriceKind", Common.ObjectAttributeValue(Object.Contract, "SalesPriceType"));
	Else
		If Common.ObjectAttributeValue(Object.Terms, "PriceIncludesVAT") <> Object.PriceIncludesVAT Then
			ErrorText = 
			NStr("vi = 'Các giá trị đã đặt cho trường ""Đơn giá gồm thuế GTGT"" trong chứng từ và thỏa thuận là khác nhau.';
				|ru = 'Установленные значения полей ""Цена включает НДС"" в документе и соглашении разные.';
				|en = 'Set values of the ""Price includes VAT"" fields in the document and agreement are different.'; fa = 'Set values of the ""Price includes VAT"" fields in the document and agreement are different.';
				|it = 'I valori impostati dei campi ""Prezzo IVA inclusa"" nel documento e nell''accordo differiscono.';
				|pl = 'Ustawione wartości pól ""Cena brutto"" w dokumencie i umową są różne.';
				|tr = 'Belgedeki ve sözleşmedeki ""KDV dahildir"" alanlarının hesaplanan değerleri farklıdır.'");
			Return False;
		EndIf;
	EndIf;
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("FillInVATRate", 
		BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	
	PricesCalculated = EnterprisePricesFillingServer.FillInPrices(
		Object.Goods, // Table part
		, // Array of rows or selection structure
		FillParameters,
		StructureOfActions);
			
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateSaleAmountByAmountWithVAT");
	StructureOfActions.Insert("RecalculateSalePriceBySaleAmount");
	StructureOfActions.Insert("RecalculateVATSalesAmount");
	StructureOfActions.Insert("ClearRewardAmount");
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
	CalculateRemuneration = True;
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Function FillInPricesByPriceKind(AgreementPriceTypeField, RowsForRecalculate = Undefined)
	
	PricesCalculated = False;
	
	PriceKind = Common.ObjectAttributeValue(Object.Contract, AgreementPriceTypeField);
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	PriceField = ?(AgreementPriceTypeField = "SalesPriceType", "SellingPrice", "Price");
	PriceTypeField = ?(AgreementPriceTypeField = "SalesPriceType", "SellingPriceType", "PriceKind");
	
	PopulationFields = "%1, %2";
	PopulationFields = StringFunctionsClientServer.SubstituteParametersToString(PopulationFields, PriceField, PriceTypeField);
	
	FillParameters = New Structure;
	FillParameters.Insert("Date", ?(ValueIsFilled(Object.EndOfPeriod), Object.EndOfPeriod, Object.Date));
	FillParameters.Insert("Currency", Object.Currency);
	FillParameters.Insert("Organization", Object.Organization);
	FillParameters.Insert("Partner", Object.Partner);
	FillParameters.Insert("Terms", Object.Terms);
	FillParameters.Insert("VATTaxation", Object.VATTaxation);
	FillParameters.Insert("PopulationFields", PopulationFields);
	FillParameters.Insert("PriceKind",PriceKind);
	FillParameters.Insert("PriceField", PriceField);
	FillParameters.Insert("PriceTypeField", PriceTypeField);
	
	StructureOfActions = New Structure;
	
	If AgreementPriceTypeField = "SalesPriceType" Then
		
		StructureOfActions.Insert("RecalculateSaleAmount");
		StructureOfActions.Insert("RecalculateVATSalesAmount", StructureOfRecalculationOfAmount);
		
	Else
		
		StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
		
	EndIf;
	StructureOfActions.Insert("ClearRewardAmount");
	
	If ValueIsFilled(PriceKind) Then
		
		PricesCalculated = EnterprisePricesFillingServer.FillInPrices(
			Object.Goods,
			RowsForRecalculate,
			FillParameters,
			StructureOfActions);
		
	ElsIf RowsForRecalculate <> Undefined Then
		
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			RowsForRecalculate,
			StructureOfActions,
			Object.Goods,
			CachedValues);
		
	Else
		
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
		
	EndIf;
	
	CalculateRemuneration = True;
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Procedure RecalculateBalancesBasedOnAccountingDataServer(LineNumber = Undefined)
	
	ConsignmentSalesServer.RecalculateBalancesBasedOnAccountingData(
		Object,
		Object.EndOfPeriod,
		True, // ThereIsSaleAmount
		CalculateRemuneration,
		LineNumber);
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateFinalIndicatorsOfCommissionAgentSReport(Form)
	
	DisplayTotalAmountOfVAT = VATAccountingERPClientServer.DisplayNDSInResultsOfSalesDocument(Form.Object.VATTaxation);
	
	If DisplayTotalAmountOfVAT Then
		Form.Items.VATPageGroup.CurrentPage   = Form.Items.PageVAT;
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.TotalSNDSPage;
	Else
		Form.Items.VATPageGroup.CurrentPage   = Form.Items.PageExcludingVAT;
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.PageTotalWithoutVAT;
	EndIf;
	
	If Form.Object.CommissionFeeCalculationMethod = PredefinedValue("Enum.CommissionFeeCalculationMethods.NotCalculating") Then
		Form.Items.TotalRemunerationAmount.Visible      = False;
	Else
		Form.Items.TotalRemunerationAmount.Visible      = True;
	EndIf;
	
	TotalPaymentPercentage = 0;
	PreviousDateValue = Date(1, 1, 1);
	Form.LineNumberOfFullPayment = 0;
	For Each CurRow In Form.Object.PaymentScheduleSteps Do
		TotalPaymentPercentage = TotalPaymentPercentage + CurRow.PaymentPercentage;
		CurRow.PercentageIsFilledInIncorrectly = (TotalPaymentPercentage > 100);
		CurRow.DateIsFilledInIncorrectly = (PreviousDateValue > CurRow.PaymentDate);
		PreviousDateValue = CurRow.PaymentDate;
		If TotalPaymentPercentage = 100 Then
			Form.LineNumberOfFullPayment = CurRow.LineNumber;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure UpdateTextOfInvoiceToCommissionAgent()

	RegistrationParameters = ParametersForRegisteringInvoicesToCommissionAgentServer(Object);
	InvoicesToCommissionAgent = VATAccountingERP.InvoicesToCommissionAgentOnBasisOf(RegistrationParameters);
	ThisForm.TextOfInvoiceToConsignee = InvoicesToCommissionAgent.Presentation;

EndProcedure

&AtServer
Procedure UpdateTextOfInvoiceReceived()
	
	RegistrationParameters = Documents.ConsignmentReportFromCustomer.ParametersForRegisteringInvoicesReceived(Object);
	InvoicesReceivedOnBasisOf = VATAccountingERP.InvoicesReceivedOnBasisOf(RegistrationParameters);
	
	InvoiceTextReceived = InvoicesReceivedOnBasisOf.Presentation;
	
EndProcedure

&AtClient
Procedure LabelPaymentStagesClick(Item, StandardProcessing)
	
	Notification = New CallbackDescription("LabelPaymentStagesClickCompletion", ThisObject);
	PlacePaymentStepsInTemporaryStorage(Item.Name);
	ARAPAccountingClient.LabelPaymentStagesClick(ThisForm, Item, StandardProcessing, Notification );
	
EndProcedure

&AtServer
Procedure PlacePaymentStepsInTemporaryStorage(TagName)
	PaymentStepsServer.PlacePaymentStepsInTemporaryStorage(ThisForm, TagName);
EndProcedure

&AtClient
Procedure LabelPaymentStagesClickCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		ChangedBankingDetails = Result.OldValuesOfChangedProps;
		ReflectChangesToPaymentRules(ChangedBankingDetails);
	EndIf;
	
	CalculateFinalIndicatorsOfCommissionAgentSReport(ThisForm);
	
EndProcedure

&AtServer
Procedure FillIn_TermsOfSales()
	
	DocumentObject = FormAttributeToValue("Object");
	DocumentObject.FillInDefaultSalesConditions();
	ValueToFormAttribute(DocumentObject, "Object");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
		StructureOfActions);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
	FillInCommissionAgentDoesNotKeepRecordsOfRPTOnServer();
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
EndProcedure

&AtServer
Procedure GetUploadedProductsFromStorage(GoodsAddressInStorage)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateSaleAmountByAmountWithVAT");
	StructureOfActions.Insert("RecalculateSalePriceBySaleAmount");
	SelfServiceClientServer.AddCommissionAgentSReportToActionStructureWhenChangingNumberOfPackages(StructureOfActions, Object);
	StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
		StructureOfActions);
	AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(ThisForm, StructureOfActions);
	
	ItemsFromStorage = GetFromTempStorage(GoodsAddressInStorage);
	
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
	
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	CalculateFinalIndicatorsOfCommissionAgentSReport(ThisForm);
	
EndProcedure

&AtServer
Procedure FillInSalesVATTaxation()
	
	FillParameters = Documents.ConsignmentReportFromCustomer.ParametersForFillingInSalesVATTaxation(Object);
	VATAccountingERP.FillInSalesVATTaxation(Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues);
	VATAccountingERP.FillInSalesVATTaxSelectionList(Items.VATTaxation, Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues); 
	
EndProcedure

&AtServer
Function GetContractPriceType(FieldPriceType)
	
	ParametersStructure = EnterprisePricesFillingServer.NewParametersForCheckingTypeOfContractPrices();
	ParametersStructure.FieldPriceType = FieldPriceType;
	
	If ValueIsFilled(Object.Contract) Then
		PriceKind = Common.ObjectAttributeValue(Object.Contract, FieldPriceType);
		If ValueIsFilled(PriceKind) Then
			ParametersStructure.PriceKind = PriceKind;
			ParametersStructure.PriceIncludesVAT = Common.ObjectAttributeValue(PriceKind, "PriceIncludesVAT");
		EndIf;
	EndIf;
	
	Return ParametersStructure;
	
EndFunction

&AtServer
Procedure AddSBPPaymentStatusUpdateCommand()

	CommandParameters = CashServerLocalization.NewParametersOfSBPPaymentStatusUpdateCommand();
	CommandParameters.Parent = Items.PaymentGroup_2;
	CommandParameters.Location = Items.CreditPaymentForm;
	CashServerLocalization.AddSBPPaymentStatusUpdateCommand(ThisObject, CommandParameters);

EndProcedure

&AtClient
Procedure Attachable_SBPPaymentVerification()

	CashClientLocalization.CheckSBPPayment(ThisObject, Object.Ref, Object.Counterparty);

EndProcedure

&AtServer
Function GetOrganizationSDefaultBankAccountServer()
	
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Object.Organization);
	ParametersOfAccount.LineOfBusiness = Object.LineOfBusiness;
	ParametersOfAccount.ExcludeCurrencyAccounts = Object.ForeignCurrencyTransaction;
	ParametersOfAccount.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	Return CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount,
		Object.BankAccount, Object.PaymentMethod);
	
EndFunction

#EndRegion

#Region WorkingWithCounterparties
&AtClient
Procedure CheckCounterparties(Command)
	
	
EndProcedure

#EndRegion

&AtServer
Procedure FillInSubordinatePropertiesForStatistics(ParentPropsName)
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, ParentPropsName);
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	// Subsystem "Properties"
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

&AtClient
Procedure SelectionByStockCompletion(Result, AdditionalParameters) Export
	
	If ConsignmentSales25 Then
		
		PerformanceMonitorClient.TimeMeasurement(True,
			"Document.ConsignmentReportFromCustomer.DocumentForm.Command.SelectTransferredGoods");
		
		AddressOfPaymentsInTheStorage = PutGoodsInVaultWithSeries(
			Object.Goods,
			UUID);
			
		PickingParameters = New Structure;
		PickingParameters.Insert("Ref",      Object.Ref);
		PickingParameters.Insert("Owner",    Object.Partner);
		PickingParameters.Insert("Organization", Object.Organization);
		PickingParameters.Insert("Contract",     Object.Contract);
		PickingParameters.Insert("BusinessOperation", Object.BusinessOperation);
		
		PickingParameters.Insert("ByPhysicalCountResults", Object.ByPhysicalCountResults);
		PickingParameters.Insert("AddressOfGoodsInvoiceInVault", AddressOfPaymentsInTheStorage);
		PickingParameters.Insert("ObjectManager", "Document.ConsignmentReportFromCustomer");
		PickingParameters.Insert("CollapseGTDNumbers", Not UseTraceableImportedGoodsAccounting
			Or TheCommissionAgentDoesNotKeepRecordsOnTheRNPT);
		PickingParameters.Insert("UseTraceableImportedGoodsAccounting", UseTraceableImportedGoodsAccounting);
		PickingParameters.Insert("TheCommissionAgentDoesNotKeepRecordsOnTheRNPT", TheCommissionAgentDoesNotKeepRecordsOnTheRNPT);
		
		OpenForm("DataProcessor.SelectGoodsTransferredToCustody.Form.Form",
			PickingParameters,
			ThisObject,
			UUID);
			
	Else
			
		AddressOfPaymentsInTheStorage = PutProductsInStorage(
			Object.Goods,
			UUID);
		
		PickingParameters = New Structure;
		PickingParameters.Insert("AddressOfPaymentsInTheStorage", AddressOfPaymentsInTheStorage);
		PickingParameters.Insert("Organization", Object.Organization);
		PickingParameters.Insert("Partner", Object.Partner);
		PickingParameters.Insert("Terms", Object.Terms);
		PickingParameters.Insert("Date", ?(ValueIsFilled(Object.EndOfPeriod), Object.EndOfPeriod, Object.Date));
		PickingParameters.Insert("ByPhysicalCountResults", Object.ByPhysicalCountResults);
		PickingParameters.Insert("UseTraceableImportedGoodsAccounting", UseTraceableImportedGoodsAccounting);
	
		OpenForm(
			"CommonForm.SelectByGoodsTransferredToCommissionAgent",
			PickingParameters, 
			ThisForm);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure RecalculateBalancesBasedOnAccountingDataCompletion(Result, AdditionalParameters) Export
	
	RecalculateBalancesBasedOnAccountingDataServer();
	
	ShowUserNotification(
		NStr("vi = 'Hàng tồn kho (kế toán) đã điền';
			|ru = 'Остаток (учет) заполнен.';
			|en = 'Book quantity entered.'; fa = 'Book quantity entered.';
			|it = 'Saldo (contabilità) è compilato.';
			|pl = 'Saldo (ewidencja) jest wypełnione.';
			|tr = 'Bakiye (muhasebe) tamamlanmıştır.'"),
		,
		NStr("vi = 'Hàng tồn kho theo dữ liệu kế toán trong chứng từ đã điền';
			|ru = 'Остаток по данным учета в документе заполнен.';
			|en = 'Balance by accounting data is filled in the document.'; fa = 'Balance by accounting data is filled in the document.';
			|it = 'Il saldo secondo i dati contabili è compilato.';
			|pl = 'Saldo danych ewidencji w dokumencie jest wypełnione.';
			|tr = 'Belgedeki muhasebe verilerine göre bakiye doldurulur.'"),
		PictureLib.Information32);
	
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
		
		If Object.ByPhysicalCountResults Then
			StructureOfActions.Insert("RecalculateNumberOfPackagesAfterFact");
		EndIf;
		
		SelfServiceClientServer.AddCommissionAgentSReportToActionStructureWhenChangingNumberOfPackages(StructureOfActions, Object);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
		CalculateFinalIndicatorsOfCommissionAgentSReport(ThisForm);
		CalculateRemuneration = True;
		
	EndIf;
	
	AccountingForTraceableGoodsClientServerLocalization.SplitRowCompletion(NewRow, AdditionalParameters);
	
EndProcedure

&AtServer
Procedure LineOfBusinessOnChangeServer()
	
	FillInDefaultContract();
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "LineOfBusiness");
	
EndProcedure

&AtServer
Procedure FillInShipperSelectionList()
	
	Items.Shipper.ChoiceList.Clear();
	ShipperOrganization = NStr("vi = 'Doanh nghiệp: %1';
								|ru = 'Организация: %1';
								|en = 'Company: %1'; fa = 'Company: %1';
								|it = 'Società: %1';
								|pl = 'Firma: %1';
								|tr = 'İş yeri: %1'");
	ShipperOrganization = StringFunctionsClientServer.SubstituteParametersToString(ShipperOrganization, Object.Organization);
	
	If ValueIsFilled(Object.Organization) Then
		Items.Shipper.ChoiceList.Add(,ShipperOrganization);
	EndIf;
	If ValueIsFilled(Object.Counterparty) Then
		Items.Shipper.ChoiceList.Add(Object.Counterparty,Object.Counterparty);
	EndIf;
	Items.Shipper.InputHint = ShipperOrganization;
EndProcedure

&AtServer
Procedure ManagingRelationshipsOfFormDetailsSelectionParameters()
	
	//Agreement, we add a link with the details of the business operation form to silence
	FormItem = Items.Terms;
	NewSelectionParameterRelationships = New Array;
	For Each RelationshipOfSelectionParameters In FormItem.ChoiceParameterLinks Do
		If Not RelationshipOfSelectionParameters.Name = "Filter.BusinessOperation" Then
			NewSelectionParameterRelationships.Add(RelationshipOfSelectionParameters);
		EndIf;
	EndDo;
	ChoiceParameter = New ChoiceParameterLink("Filter.BusinessOperation", "DefaultBusinessTransaction", LinkedValueChangeMode.DontChange);
	NewSelectionParameterRelationships.Add(ChoiceParameter);
	FormItem.ChoiceParameterLinks = New FixedArray(NewSelectionParameterRelationships);
	
EndProcedure	

&AtServer
Procedure KeepCommissionFeeOnChangeServer()
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "KeepCommissionFee");
	FormItemsManagement();
EndProcedure

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
EndProcedure

&AtServer
Procedure ReflectChangesToPaymentRules(ChangedBankingDetails)
	
	PaymentStepsServer.LoadPaymentStagesFromTemporaryStorage(ThisForm);
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, ChangedBankingDetails, True);
	
EndProcedure

&AtServer
Procedure ChangedPaymentServer(EventName, Parameter, Source)
	
	ARAPAccountingFormWork.NotificationProcessing(ThisForm, EventName, Parameter);
	
EndProcedure

&AtServer
Procedure PlacePaymentDecryptionInTemporaryStorage()
	ARAPAccountingFormWork.PlacePaymentDecryptionInTemporaryStorage(ThisForm);
EndProcedure

&AtServer
Procedure RecalculateNumberOfRNPT()
	
	If Not TheCommissionAgentDoesNotKeepRecordsOnTheRNPT
		And ValueIsFilled(Object.Organization) Then
		
		ParametersForObtainingRnptCoefficient = AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(
												Object,
												"Partner");
		AccountingForTraceableGoodsLocalization.FillInQuantityByRNPTVOfTablePart(ParametersForObtainingRnptCoefficient,
																						Object.Goods);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
		
	CurrentData        = Items.Goods.CurrentData;
	UpdateSeriesStatuses = ProductsClient.SeriesStatusesNeedToBeUpdated(Item,
																			CachedValues,
																			SeriesSpecificationParameters);
	
	If UpdateSeriesStatuses Then
		
		IDCurrentRow = CurrentData.GetID();
		
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues);
		
		ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters);
		
	EndIf;
	

EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	
	UpdateSeriesStatuses = ProductsClient.SeriesStatusesNeedToBeUpdated(Item,
																			CachedValues,
																			SeriesSpecificationParameters,
																			True);
	
	If UpdateSeriesStatuses Then
		ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters);
	EndIf;
	
	CalculateRemuneration = True;
	
EndProcedure

&AtClient
Procedure FillInVATRateCompletion(VATRate, AdditionalParameters) Export

	If VATRate = Undefined Then
		Return;
	EndIf;

	FillInVATRateOnServer(VATRate, CachedValues);

EndProcedure

&AtServer
Procedure FillInVATRateOnServer(VATRate, CachedValues)

	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));
	StructureOfActions.Insert("RecalculateVATSalesAmount");
	StructureOfActions.Insert("ClearRewardAmount");

	SelectedRows = ProcessingOfTabularFormsClientServer.CollectionItems(
		Object.Goods, Items.Goods.SelectedRows);
	
	For Each LineOfATabularSection In SelectedRows Do
		LineOfATabularSection.VATRate = VATRate;
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		SelectedRows,
		StructureOfActions,
		Object.Goods,
		CachedValues);

	CalculateRemuneration = True;
	CalculateFinalIndicatorsOfCommissionAgentSReport(ThisObject);

EndProcedure

&AtServer
Procedure SetPropertiesOfOutdatedCommissionUsageComment()
	
	Items.CommentUsingOutdatedCommission.Title = ConsignmentSalesServer.CommentUsingOutdatedCommission();
	Items.GroupCommentUsingOutdatedCommission.Visible = Not ConsignmentSales25;
	
EndProcedure

#Region SetOfSeries

&AtServer
Function SeriesSpecificationParameters()
	
	ObjectManager = Documents.ConsignmentReportFromCustomer;
	
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
	
	NeedServerCall = ProductsClient.YouNeedServerCallToSpecifySeries(ThisForm,
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
		
		OpenForm(ParametersOfSeriesIndicationForm.FormName, ParametersOfSeriesIndicationForm, ThisForm, , , , CallbackDescription,
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
															ThisForm);
	
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
		
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

&AtClient
Procedure SpecifySeries(Command)
	
	OpenSelectionOfSeries();
	
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
	
	If Object.ByPhysicalCountResults Then
		ProcessingActions.Insert("RecalculateNumberOfPackagesAfterFact");
	EndIf;
	
	AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(ThisObject, ProcessingActions);
	
	If SelectionData_1.ResidualNumberOfCCD <> Undefined Then
		SelfServiceClientServer.AddCommissionAgentSReportToActionStructureWhenChangingNumberOfPackages(
			ProcessingActions,
			Object);
	EndIf;
	
	PurchasesServer.ProcessIndicationOfCCDNumber(ThisObject,
												RowID,
												SelectionData_1,
												CCDNumbersFilledIn,
												Undefined,
												ProcessingActions);
	
	CalculateFinalIndicatorsOfCommissionAgentSReport(ThisObject);
	
	CalculateRemuneration = True;
	
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
