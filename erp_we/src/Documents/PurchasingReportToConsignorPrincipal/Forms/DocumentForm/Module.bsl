#Region Variables

&AtClient
Var CachedValues; // used by the mechanism for processing changes in PM details


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

	UsePartnersAsCounterparties      = GetFunctionalOption("UsePartnersAsCounterparties");
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisForm);
	
	// Handler of the subsystem "Versioning of objects"
	ObjectsVersioning.OnCreateAtServer(ThisForm);

	AttributeSelectionParameters = PaymentStepsServer.ParametersForSelectingPaymentDetails(Metadata.Documents.PurchasingReportToConsignorPrincipal);
	
	DocumentCorrection.OnCreateAtServer(ThisForm, Items.LineCorrection);
	
	ContractIsOld = Object.Contract;
	
	If Not ValueIsFilled(Object.Ref) Then
		
		CalculateRemuneration = True;
		FillInvoicesReceivedByServer();
		
		OnReadCreateAtServer();
		
		If Parameters.Property("Basis")
		 And TypeOf(Parameters.Basis) = Type("Structure")
		 And Parameters.Basis.Property("FillInByTheGoodsForRegistration") Then
			FillInByTheGoodsForRegistration = Parameters.Basis.FillInByTheGoodsForRegistration;
		EndIf;
		
	EndIf;
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.GroupInTotal.BackColor = New Color();
	EndIf;
	
	AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(ThisForm,
		Object.Date, "ProductsGroupQuantityByRNPT");
	
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

	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisForm);

	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	SetPresentationOfFoundationDocument();
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
	
	If Not ValueIsFilled(Object.Ref)
	 And FillInByTheGoodsForRegistration Then
		ConsignmentSalesClient.CheckDocumentCompletionByBalances(Object);	
	EndIf;
	
	
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
	CashClientLocalization.AttachablePaymentVerificationViaServices(ThisObject, Object.Ref, Object.Counterparty);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)

	If ChoiceSource.FormName = "CommonForm.SelectGoodsAndWorksForRegistrationOfPurchasingReportForConsignor" Then
		
		GetProductsFromStorage(ValueSelected);
		
	ElsIf VATAccountingERPClient.FinishedEditingInvoiceIssued(ValueSelected, ChoiceSource) Then
	
		UpdateTextOfInvoiceIssued();
		
	ElsIf VATAccountingERPClient.CompletedProcessingOfInvoicesIssued(ValueSelected, ChoiceSource) Then
		
		FillInByPurchaseResultServer();
		
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
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	If EventName = "Write_TermsOfPurchaseFromVendors" Then
		
		SetAvailabilityAgreements();
		
	EndIf;
	
	If EventName = "Write_InvoiceIssued"
		And ((Parameter.Property("OwnerForm") And Parameter.OwnerForm = UUID)
			Or Parameter.Property("ListOfGrounds") And Parameter.ListOfGrounds.FindByValue(Object.Ref) <> Undefined) Then
		HandlersParameters = New Structure;
		HandlersParameters.Insert("UpdateTextOfInvoiceIssued");
		HandlersParameters.Insert("FillInInvoicesSubmittedByServer");
		HandlersParameters.Insert("UpdateTextOfInvoiceReissued");
		CallServerHandlers(HandlersParameters);
	EndIf;
	
	If EventName = "SupplierInvoiceReissued"
		And (Parameter.Property("OwnerForm") And Parameter.OwnerForm = UUID) Then
		HandlersParameters = New Structure;
		HandlersParameters.Insert("FillInInvoicesSubmittedByServer");
		HandlersParameters.Insert("UpdateTextOfInvoiceReissued");
		CallServerHandlers(HandlersParameters);
	EndIf;
	
	If ARAPAccountingClient.NeedAlertProcessingCall(ThisForm, EventName, Parameter) Then
			
		StructurePaymentCreditedServer = NewStructureCreditedToServer();
		StructurePaymentCreditedServer.EventName = EventName;
		StructurePaymentCreditedServer.Parameter 	= Parameter;
		StructurePaymentCreditedServer.Source 	= Source;
		
		HandlersParameters = New Structure;
		HandlersParameters.Insert("PaymentCreditedServer", StructurePaymentCreditedServer);
		CallServerHandlers(HandlersParameters);
		If Not Object.ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ByCounterpartyContracts") Then
			Read();
		EndIf;
	EndIf;
	
	If EventName = "SelectionOfAcquisitionDocumentsToReportToCommittee" And Source.FormOwner = ThisObject Then
		
		If Object.DocumentAcquisitions <> Parameter Then
			
			If Object.Goods.Count() > 0 Then
				
				CallbackDescription = New CallbackDescription("WhenSelectingPurchaseDocumentEnd", ThisObject, Parameter);
				
				ShowQueryBox(
						CallbackDescription,
						NStr("vi = 'Điền lại bảng hàng hóa theo chứng từ mua sắm?';
							|ru = 'Перезаполнить таблицу товаров по документу приобретения?';
							|en = 'Do you want to refill the goods table by the purchase document?'; fa = 'Do you want to refill the goods table by the purchase document?';
							|it = 'Ricompilare la tabella articoli per documento di acquisizione?';
							|pl = 'Ponownie wypełnić tabelę towarów według dokumentu zakupu?';
							|tr = 'Mallar tablosu bir satın alma belgesiyle yeniden doldurulsun mu?'"),
						QuestionDialogMode.YesNo);
						
			Else
				Object.DocumentAcquisitions = Parameter;
				SetPresentationOfFoundationDocument();
				CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
				CheckParameters.TabularSection = Object.Goods;
				CheckParameters.CheckedAttributes.Insert("Organization", NStr("vi = 'Doanh nghiệp';
																				|ru = 'Организация';
																				|en = 'Company'; fa = 'Company';
																				|it = 'Azienda';
																				|pl = 'Firma';
																				|tr = 'İş yeri'"));
				CheckParameters.CheckedAttributes.Insert("Partner",     NStr("vi = 'Người đặt ký gửi';
																			|ru = 'Комитент';
																			|en = 'Consignor'; fa = 'امانت‌گذار';
																			|it = 'Committente';
																			|pl = 'Komitent';
																			|tr = 'Gönderici'"));
				CheckParameters.CheckedAttributes.Insert("Currency",      NStr("vi = 'Tiền tệ';
																				|ru = 'Валюта';
																				|en = 'Currency'; fa = 'ارز';
																				|it = 'Valuta';
																				|pl = 'Waluta';
																				|tr = 'Para birimi'"));
				Notification = New CallbackDescription("FillInByPurchaseResultCompletion", ThisObject);
				ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
			EndIf;
				
		EndIf;
			
	EndIf;
	
	
	DocumentCorrectionClient.NotificationProcessing(ThisForm, EventName, Parameter, Source);
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
	If EventName = "WhenChangingAgreement"
		And Source = ThisObject Then
		Modified = True;
		ContractOnChange(Items[Parameter]);
	EndIf;
	
	If EventName = "SBPStatusHasBeenChanged" Then
		AddSBPPaymentStatusUpdateCommand();
		CashClientLocalization.CheckSBPPayment(ThisObject, Object.Ref, Object.Counterparty);
	EndIf;
	
EndProcedure

&AtClient
Procedure NewWriteProcessing(NewObject, Source, StandardProcessing)
	
	If PurchasesClient.ThisIsIndicationOfCCDNumber(Source) Then
		Actions = New Structure;
		
		AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
			Object,
			Actions,
			"DocumentAcquisitions",
			True);
		
		PurchasesClient.ProcessIndicationOfCCDNumber(ThisObject, NewObject, , , Actions);
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
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	
	ARAPAccountingFormWork.FormWhenReadingOnServer(ThisForm);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	
	If PurchaseReport
		And Not ValueIsFilled(Object.DocumentAcquisitions) Then
		
		MessageText = NStr("vi = 'Chưa chỉ ra chứng từ mua sắm. Cần chỉ ra chứng từ hoặc chọn không chia tách.';
							|ru = 'Не указан документ приобретения. Необходимо указать документ или отказаться от разбиения.';
							|en = 'Purchase document is not specified. Specify the document or do not split.'; fa = 'Purchase document is not specified. Specify the document or do not split.';
							|it = 'Non è indicato il documento di acquisizione. Bisogna indicare il documento o rinunciare alla ripartizione.';
							|pl = 'Nie określono dokumentu zakupu. Należy podać dokument lub zrezygnować od podziału.';
							|tr = 'Satın alma belgesi belirtilmemiştir. Belge belirtilmeli veya bölümden ayrılmalıdır.'");
		
		Common.MessageToUser(MessageText,
		Object.Ref,
		"DocumentAcquisitions",
		"Object",
		Cancel);
		
	EndIf;
	
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
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("WriteParameters", WriteParameters);
	
	If CalculateRemuneration Then
		Cancel = True;
		ConsignmentSalesClient.YouNeedToCalculateReward(
			New CallbackDescription("BeforeRecordingContinuationYouNeedToCalculateReward", ThisObject, AdditionalParameters),
			ThisForm);
	Else
		BeforeWriteAtClientServer(False);	
	EndIf;

	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters, Cancel);

EndProcedure

&AtClient
Procedure BeforeWriteContinued(Result, AdditionalParameters) Export
	
	If Not Result Then
		Return;
	EndIf;
	
	If CalculateRemuneration Then
		ConsignmentSalesClient.YouNeedToCalculateReward(
			New CallbackDescription("BeforeRecordingContinuationYouNeedToCalculateReward", ThisObject, AdditionalParameters),
			ThisForm);
	Else
		BeforeRecordingContinuationYouNeedToCalculateReward(False, AdditionalParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeRecordingContinuationYouNeedToCalculateReward(YouNeedToCalculateReward, AdditionalParameters) Export
	
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
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement

	FillInDataOnPurchaseDocument();
	
	FillInInvoicesSubmittedByServer();
	
	UpdateTextOfInvoiceIssued();
	UpdateTextOfInvoiceReissued();
	UpdateOrderInformation();
	CalculateFinalIndicatorsOfReportToPurchasingCommittee(ThisForm);
	
	StructureCharacteristicsOfProducts = New Structure;
	StructureCharacteristicsOfProducts.Insert("FillInFeatureAttribute",	New Structure("Products", "ItemVariantsAreUsed"));
	StructureCharacteristicsOfProducts.Insert("FillInArticleAttribute",	New Structure("Products", "SKU"));
	
	StructureCharacteristicsOfProducts.Insert("FillInProductTypeAttribute_",	New Structure("Products", "ItemsType"));
	StructureCharacteristicsOfProducts.Insert("FillInCCDTrackingAttribute",	New Structure("Products", "TheRecordsAreKeptByCCD"));
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureCharacteristicsOfProducts);
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureCharacteristicsOfProducts);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
	
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	ARAPAccountingFormWork.FormAfterRecordingOnServer(ThisForm, CurrentObject.AdditionalProperties);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_PurchasingReportToConsignorPrincipal", WriteParameters, Object.Ref);
	ARAPAccountingClient.FormAfterRecording(ThisForm);
	
	If WriteParameters.WriteMode <> DocumentWriteMode.Write Then
		WriteParameters.Insert("OwnerForm", UUID);
		Notify("SupplierInvoiceReissued", WriteParameters, Object.Ref);
	EndIf;
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisForm, Object, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	
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
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	

EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	ForceCloseTheForm = True;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)

	CashClientLocalization.DisablePaymentVerificationViaServices(ThisObject);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If CurrentPage.Name = "AdditionalPage"
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	If CurrentPage.Name = "PageGeneral" Then
		ARAPAccountingClient.UpdateHyperlinkTextPaymentSteps(ThisForm);
		UpdateOrderInformation();
	EndIf;
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	Notification = New CallbackDescription("DateOnChangeCompletion", ThisObject);
	EnterprisePricesFillingClient.AskQuestionAboutRecalculatingPriceWhenDateChanges(Object, Notification);
	
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	
	If ValueIsFilled(Object.Currency) Then
		
		ConsignmentSalesClient.CheckWhetherCurrencyConversionIsNecessaryCommissionReports(
			New CallbackDescription("CurrencyWhenQuestionChangesRecalculateCurrency", ThisObject),
			Object,
			DocumentCurrency,
			"AmountIncludingVAT");

	Else
		
		DocumentCurrency = Object.Currency;
		
		FillInSubordinatePropertiesForStatistics("Currency");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CurrencyWhenQuestionChangesRecalculateCurrency(RecalculateCurrency, AdditionalParameters) Export
	
	CurrencyOnChangeServer(
		Object.Currency,
		RecalculateCurrency);
		
	PriceManagementSystemClient.NotifyAboutEndOfConversionOfAmountsIntoCurrency(DocumentCurrency, Object.Currency);
	
	DocumentCurrency = Object.Currency;
	
	FillInSubordinatePropertiesForStatistics("Currency");
	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	If ValueIsFilled(Object.Partner) Then
		PartnerOnChangeServer();
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
	
	If ValueIsFilled(Object.Terms) Then
		
		QuestionUserBeforeFillingInPricesByAgreement(
			New CallbackDescription("ContactPersonWhenChangingWhenChangingQuestionFillInPrice", ThisObject));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ContactPersonWhenChangingWhenChangingQuestionFillInPrice(FillInPrices, AdditionalParameters) Export
	
	If Object.Goods.Total("Price") <> 0 And FillInPrices Then
		FillThePricesByTermsOfSalesServer();
	EndIf;
	
	PurchasesClient.NotifyEndOfFillingInDefaultPurchaseConditions();
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyOnChangeServer();
	
	
EndProcedure

&AtServerNoContext
Function ParametersForRegisteringInvoicesIssuedServer(Val Object)
	
	Return Documents.PurchasingReportToConsignorPrincipal.ParametersForRegisteringInvoicesIssued(Object);
	
EndFunction	

&AtClient
Procedure VATTaxationOnChange(Item)
	
	VATTaxationOnChangeServer();
	CalculateRemuneration = True;
	
EndProcedure

&AtClient
Procedure PriceIncludesVATOnChange(Item)
	
	PriceIncludesVATOnChangeServer(CachedValues);
	
EndProcedure

&AtClient
Procedure TermsOnChange(Item)

	If Not ValueIsFilled (Object.Terms) Then
		Return;
	EndIf;
	
	
	TermsOnChangeServer();
	SalesClient.NotifyEndOfFillingInTermsOfSale();
	
EndProcedure

&AtServer
Procedure TermsOnChangeServer()

	DocumentSales = FormAttributeToValue("Object");
	DocumentSales.FillInTermsOfSalesUnderAgreement();
	ResponsiblePersonsServer.FillInManager_(DocumentSales);
	ValueToFormAttribute(DocumentSales, "Object");
	
	DocumentCurrency = Object.Currency;
	
	CashServer.CheckFillInOrganizationSBankAccountByOwner(Object.Organization,
		Object.BankAccount, Object.PaymentMethod, Object.LineOfBusiness, Object.ForeignCurrencyTransaction);
	CashServer.CheckOrganizationSSalesRegisterByOwner(Object.Organization, Object.CashAccount, Object.PaymentMethod, Object.LineOfBusiness);
	
	AttributesArray = New Array;
	AttributesArray.Add("Contract");
	AttributesArray.Add("Terms");
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, AttributesArray);
	
	FillInSubordinatePropertiesForStatistics("Contract");
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
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
	AgreementSelectionParameters.BusinessOperation       = PredefinedValue("Enum.BusinessTransactions.DeliveryForPrincipal");
	
	SalesClient.StartSelectingAgreementWithClient(AgreementSelectionParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ContractCreating(Item, StandardProcessing)
	
	PurchasesClient.OpenContractCreationForm(ThisObject, Item, "Object.Contract", Object.Partner, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	ContractOnChangeServer();
	
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
	EndIf;
	
EndProcedure

&AtClient
Procedure CommissionFeeCalculationMethodStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommissionFeeCalculationMethod = Object.CommissionFeeCalculationMethod;
	
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
Procedure VATRateOfRemunerationStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	RemunerationRate = Object.VATRateOfRemuneration;
	
EndProcedure

&AtClient
Procedure VATRateOfRemunerationOnChange(Item)
	
	If Not Object.VATRateOfRemuneration = RemunerationRate Then
		AdditionalParameters = New Structure("RestoreAttributes", False);
		Notification = New CallbackDescription(
			"RateOfCalculationOfRemunerationInCaseOfChangeItIsNecessaryToCalculateRemuneration", ThisObject, AdditionalParameters);
		ConsignmentSalesClient.YouNeedToCalculateReward(Notification, ThisObject);
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
Procedure LabelHeaderSalesOrdersClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	OpenForm(
		"CommonForm.ViewingListOfDocuments",
		New Structure("DocumentsList, Title",
			OrderList,
			NStr("vi = 'Đơn hàng của khách (%DocumentsCount%)';
				|ru = 'Заказы клиентов (%DocumentsCount%)';
				|en = 'Sales orders (%DocumentsCount%)'; fa = 'Sales orders (%DocumentsCount%)';
				|it = 'Ordini dei clienti (%DocumentsCount%)';
				|pl = 'Zamówienia klientów (%DocumentsCount%)';
				|tr = 'Satış siparişleri (%DocumentsCount%)'")
		),
		ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
		
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(
		ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ReportOnOrderOnChange(Item)
	
	QuestionAboutRemovalOfGoods();
	
EndProcedure

&AtClient
Procedure ReportOnOrdersOnChange(Item)
	
	QuestionAboutRemovalOfGoods();
	
EndProcedure

&AtClient
Procedure PurchaseReportOnChange(Item)
	
	If Not PurchaseReport Then
		Object.DocumentAcquisitions = Undefined;
	EndIf;
	
	SetPresentationOfFoundationDocument();
	
EndProcedure

&AtClient
Procedure AcquisitionSubmissionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "OpenDocument" Then
		
		ShowValue(Undefined, Object.DocumentAcquisitions);
		
	ElsIf FormattedStringURL = "SelectDocument" Then
		ChoiceFormName = "Document.PurchasingReportToConsignorPrincipal.Form.PurchaseDocumentChoiceForm";
		FilterParameters = New Structure();
		FilterParameters.Insert("Contract", Object.Contract);
		FilterParameters.Insert("Terms", Object.Terms);
		FilterParameters.Insert("Partner", Object.Partner);
		If ReportOnOrder Then
			FilterParameters.Insert("Orders", OrderList);
		EndIf;
		OpenForm(ChoiceFormName, FilterParameters, ThisObject);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WhenSelectingPurchaseDocumentEnd(Response, SelectedPurchaseDocument) Export
	
	If Response = DialogReturnCode.Yes Then
		Object.DocumentAcquisitions = SelectedPurchaseDocument;
		SetPresentationOfFoundationDocument();
		Object.Goods.Clear();
		CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
		CheckParameters.TabularSection = Object.Goods;
		CheckParameters.CheckedAttributes.Insert("Organization", NStr("vi = 'Doanh nghiệp';
																		|ru = 'Организация';
																		|en = 'Company'; fa = 'Company';
																		|it = 'Azienda';
																		|pl = 'Firma';
																		|tr = 'İş yeri'"));
		CheckParameters.CheckedAttributes.Insert("Partner",     NStr("vi = 'Người đặt ký gửi';
																	|ru = 'Комитент';
																	|en = 'Consignor'; fa = 'امانت‌گذار';
																	|it = 'Committente';
																	|pl = 'Komitent';
																	|tr = 'Gönderici'"));
		CheckParameters.CheckedAttributes.Insert("Currency",      NStr("vi = 'Tiền tệ';
																		|ru = 'Валюта';
																		|en = 'Currency'; fa = 'ارز';
																		|it = 'Valuta';
																		|pl = 'Waluta';
																		|tr = 'Para birimi'"));
		Notification = New CallbackDescription("FillInByPurchaseResultCompletion", ThisObject);
		ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
EndProcedure

&AtClient
Procedure PresentationOfCodeOfSpecialCircumstancesStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	Return;
	
EndProcedure

&AtClient
Procedure PresentationOfCodeOfSpecialCircumstancesClearing(Item, StandardProcessing)
	
	Return;
	
EndProcedure

&AtClient
Procedure PresentationOfCodeOfSpecialCircumstancesOpening(Item, StandardProcessing)
	
	Return;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	Value = Undefined;
	
	If Field = Items.GoodsVendor Then
		Value = Item.CurrentData.Vendor;
	ElsIf Field = Items.GoodsInvoiceIssuedToTheCommitee Then
		Value = Item.CurrentData.InvoiceIssuedToTheCommitee;
	EndIf; 
	
	If Value <> Undefined Then
		StandardProcessing = False;
		ShowValue(, Value);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	StructureOfActions.Insert("RecalculateVATAmount",  BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));
	StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActions.Insert("FillInCountryOfOriginOfProduct",
								BatchProcessingOfTablePartClientServer.CountryOfOriginFillingParameters());
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActions,
		"DocumentAcquisitions",
		True);
	
	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		FormName, "Goods"));
	
	AddPriceConversionAction(StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If Not CurrentRow.AccountingForTheRNPTIsMaintained Then
		CurrentRow.CCDNumber = Undefined;
		CurrentRow.CCDNumberType = Undefined;
		CurrentRow.OriginCountry = Undefined;
	EndIf;
	
	CurrentRow.CommissionAmount = 0;
	CalculateRemuneration = True;
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);

	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		FormName, "Goods"));
	
	AddPriceConversionAction(StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CurrentRow.CommissionAmount = 0;
	CalculateRemuneration = True;
	
EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	NumberOfUnitsBeforeRecalculation = CurrentRow.Count;
	If CurrentRow.Count > 0 Then
		StructureOfActions.Insert("RecalculatePricePerPackage", CurrentRow.Count);
	Else
		AddPriceConversionAction(StructureOfActions);
	EndIf;
	StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CurrentRow.CommissionAmount = 0;
	CalculateRemuneration = True;
	
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActions,
		"DocumentAcquisitions",
		True);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CurrentRow.CommissionAmount = 0;
	CalculateRemuneration = True;
	
EndProcedure

&AtClient
Procedure GoodsPriceOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CurrentRow.CommissionAmount = 0;
	CurrentRow.AmountARAP = CurrentRow.AmountIncludingVAT;
	CalculateRemuneration = True;
	
EndProcedure

&AtClient
Procedure GoodsVATRateOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CurrentRow.CommissionAmount = 0;
	CalculateRemuneration = True;
	
EndProcedure

&AtClient
Procedure GoodsSumOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("RecalculatePriceDiscountByAmountInSales");
	StructureOfActions.Insert("RecalculateVATAmount",  BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CurrentRow.CommissionAmount = 0;
	CalculateRemuneration = True;
	
EndProcedure

&AtClient
Procedure GoodsVATAmountOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CurrentRow.CommissionAmount = 0;
	CalculateRemuneration = True;
	
EndProcedure
&AtClient

Procedure GoodsCommissionAmountOnChange(Item)
	
	Object.CommissionAmount = Object.Goods.Total("CommissionAmount");
	TotalAmountWithVAT = Object.Goods.Total("AmountIncludingVAT");
	Object.RemunerationPercentage = ?(TotalAmountWithVAT <> 0, Object.CommissionAmount / TotalAmountWithVAT * 100, 0);
	ConsignmentSalesClient.CalculateCommissionFeeVAT(Items.Goods.CurrentData, VATPercentage);
	Object.AmountVATRemuneration = Object.Goods.Total("AmountVATRemuneration");
	CalculateFinalIndicatorsOfReportToPurchasingCommittee(ThisForm);
	CalculateRemuneration = True;
	
EndProcedure

&AtClient
Procedure GoodsAmountVATRemunerationOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	CurrentRow.CommissionAmount = CurrentRow.AmountVATRemuneration / VATPercentage * (100 + VATPercentage);
	Object.AmountVATRemuneration = Object.Goods.Total("AmountVATRemuneration");
	Object.CommissionAmount = Object.Goods.Total("CommissionAmount");
	TotalAmountWithVAT = Object.Goods.Total("AmountIncludingVAT");
	Object.RemunerationPercentage = ?(TotalAmountWithVAT <> 0, Object.CommissionAmount / TotalAmountWithVAT * 100, 0);
	CalculateFinalIndicatorsOfReportToPurchasingCommittee(ThisForm);
	CalculateRemuneration = True;
	
EndProcedure

&AtClient
Procedure GoodsPurposeOnChange(Item)
	TheCurrentDataRow = Items.Goods.CurrentData;
	If Not TheCurrentDataRow = Undefined Then
		TheCurrentDataRow.SalesOrder = GetOrderByDestination(TheCurrentDataRow.Purpose);
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
		"DocumentAcquisitions",
		True);
	
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

&AtClient
Procedure GoodsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData; 
	
	If CurrentRow <> Undefined Then
		CurrentRow.AmountARAP = CurrentRow.AmountIncludingVAT + CurrentRow.CommissionAmount; 
		If ValueIsFilled(Object.DocumentAcquisitions) Then
			CurrentRow.DocumentAcquisitions = Object.DocumentAcquisitions;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	
	CalculateRemuneration = True;
	If Object.Goods.Count() = 0 Then
		Object.SalesOrder = Undefined;
		UpdateOrderInformation();
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsDocumentAcquisitionsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	If CurrentRow <> Undefined Then
		
		StructureOfRecalculationOfAmount = New Structure("PriceIncludesVAT", Object.PriceIncludesVAT);
		StructureOfActions = New Structure;
		
		VATRate = Undefined;
		If ValueIsFilled(CurrentRow.DocumentAcquisitions) Then
			
			DataBiItem = New Structure();
			DataBiItem.Insert("Products");
			DataBiItem.Insert("Characteristic");
			DataBiItem.Insert("DocumentAcquisitions");
			DataBiItem.Insert("Purpose");
			DataBiItem.Insert("CCDNumber");
			
			FillPropertyValues(DataBiItem, CurrentRow);
			
			VATRate = GetRateOnPurchase(DataBiItem);
		EndIf;
		
		If VATRate <> Undefined And CurrentRow.VATRate <> VATRate Then
			CurrentRow.VATRate = VATRate;
			StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
			StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		EndIf;
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, Undefined);
		
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
Procedure SplitRow(Command)
	
	FormTable  = Items.Goods;
	TableData = Object.Goods;
	
	Notification = New CallbackDescription("SplitRowCompletion", ThisObject);
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, Notification);
	
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
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm, True);
	
EndProcedure

&AtClient
Procedure FillInByPurchaseResult(Command)
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.TabularSection = Object.Goods;
	CheckParameters.CheckedAttributes.Insert("Organization",          NStr("vi = 'Doanh nghiệp';
																			|ru = 'Организация';
																			|en = 'Company'; fa = 'Company';
																			|it = 'Azienda';
																			|pl = 'Firma';
																			|tr = 'İş yeri'"));
	CheckParameters.CheckedAttributes.Insert("Currency",               NStr("vi = 'Tiền tệ';
																			|ru = 'Валюта';
																			|en = 'Currency'; fa = 'ارز';
																			|it = 'Valuta';
																			|pl = 'Waluta';
																			|tr = 'Para birimi'"));
	CheckParameters.CheckedAttributes.Insert("Contract",              NStr("vi = 'Hợp đồng';
																			|ru = 'Договор';
																			|en = 'Contract'; fa = 'قرارداد';
																			|it = 'Contratto';
																			|pl = 'Umowa';
																			|tr = 'Sözleşme'"));
	If PurchaseReport Then
		CheckParameters.CheckedAttributes.Insert("DocumentAcquisitions", NStr("vi = 'Chứng từ mua sắm';
																				|ru = 'Документ приобретения';
																				|en = 'Purchase document'; fa = 'سند خرید';
																				|it = 'Documento di acquisto';
																				|pl = 'Dokument nabycia';
																				|tr = 'Alım belgesi'"));
	EndIf;
	
	Notification = New CallbackDescription("FillInByPurchaseResultCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure ShowSupplierProducts(Command)
	
	PartnersProductsClient.ShowThePartnerSNomenclature(Object.Partner, Object.Ref, Items.Goods.CurrentData, NStr("vi = 'Người đặt ký gửi';
																												|ru = 'Комитент';
																												|en = 'Consignor'; fa = 'امانت‌گذار';
																												|it = 'Committente';
																												|pl = 'Komitent';
																												|tr = 'Gönderici'"));
	
EndProcedure

&AtClient
Procedure SelectByPurchaseResult(Command)

	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.CheckedAttributes.Insert("Organization", NStr("vi = 'Doanh nghiệp';
																	|ru = 'Организация';
																	|en = 'Company'; fa = 'Company';
																	|it = 'Azienda';
																	|pl = 'Firma';
																	|tr = 'İş yeri'"));
	CheckParameters.CheckedAttributes.Insert("Partner",     NStr("vi = 'Người đặt ký gửi';
																|ru = 'Комитент';
																|en = 'Consignor'; fa = 'امانت‌گذار';
																|it = 'Committente';
																|pl = 'Komitent';
																|tr = 'Gönderici'"));
	CheckParameters.CheckedAttributes.Insert("Currency",      NStr("vi = 'Tiền tệ';
																	|ru = 'Валюта';
																	|en = 'Currency'; fa = 'ارز';
																	|it = 'Valuta';
																	|pl = 'Waluta';
																	|tr = 'Para birimi'"));
	CheckParameters.CheckedAttributes.Insert("Contract",      NStr("vi = 'Hợp đồng';
																	|ru = 'Договор';
																	|en = 'Contract'; fa = 'قرارداد';
																	|it = 'Contratto';
																	|pl = 'Umowa';
																	|tr = 'Sözleşme'"));
	If PurchaseReport Then
		CheckParameters.CheckedAttributes.Insert("DocumentAcquisitions", NStr("vi = 'Chứng từ mua';
																				|ru = 'Документ приобретения';
																				|en = 'Purchase document'; fa = 'سند خرید';
																				|it = 'Documento di acquisto';
																				|pl = 'Dokument nabycia';
																				|tr = 'Alım belgesi'"));
	EndIf;
	
	Notification = New CallbackDescription("SelectByPurchaseResultCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
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


&AtClient
Procedure PaymentSettlement(Command)
	
	PlacePaymentDecryptionInTemporaryStorage();
	ARAPAccountingClient.PaymentSettlement(ThisForm, Items.PaymentSettlement);

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
	
	// only view totals if Betcands = BezNDS or NDS0%
	
	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForTaxationOfPurchases(ThisForm);
	
	//
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsNumberOfPackages.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;


	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PurchaseDocumentType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = New TypeDescription("DocumentRef.PurchaseAdjustment");
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.NumberOfPackages");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	
	ConditionalDesignParameters = ProductsServer.ParametersForSettingConditionalAppearanceOfCCDNumber();
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber = "GoodsCCDNumberOriginCountry";
	
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject);
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);

	//

	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfQuantityAccordingToRNPT(ThisObject);
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
	ItemField.Field = New DataCompositionField(Items.GoodsVendorInvoiceReceived.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.VATAmount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 0;
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.VendorInvoiceReceived");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisForm);

EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

&AtClient
Procedure FillThePricesByTermsOfSales(Command)

	If PartnerPricesFillingClient.ItIsNecessaryToFillInPricesByAgreement(Object, "Goods", NStr("vi = 'Hàng hóa';
																								|ru = 'Товары';
																								|en = 'Goods'; fa = 'کالاها';
																								|it = 'Merci';
																								|pl = 'Goods';
																								|tr = 'Ürünler'")) Then
		
		ErrorText = "";
		PricesCalculated = FillThePricesByTermsOfSalesServer(ErrorText);
		PurchasesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated, ErrorText);
		
	EndIf;

EndProcedure

#Region OnChangeAttributes

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));
	StructureOfActions.Insert("ClearRewardAmount");
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	PurchasesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible, Object.Contract);
	
	If ValueIsFilled(Object.Organization) Then
		
		FillInDefaultContract();
		
		If UseLinesOfBusiness Then
			LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
		EndIf;
		
		FillInSalesVATTaxation();
		VATTaxationOnChangeServer();
		
		ConsignmentSalesServer.FillInLBRateOfJointCommissionRemuneration(Object, VATPercentage);
		
		UpdateTextOfInvoiceIssued();
		
	EndIf;
	
	CashServer.CheckFillInOrganizationSBankAccountByOwner(Object.Organization,
		Object.BankAccount, Object.PaymentMethod, Object.LineOfBusiness, Object.ForeignCurrencyTransaction);
	CashServer.CheckOrganizationSSalesRegisterByOwner(Object.Organization, Object.CashAccount, Object.PaymentMethod, Object.LineOfBusiness);
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Organization");
	
	FillInSubordinatePropertiesForStatistics("Organization");
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
EndProcedure

&AtServer
Procedure CurrencyOnChangeServer(NewCurrency, RecalculateAmounts)
	
	FillInDefaultContract();
	Object.BankAccount = GetOrganizationSDefaultBankAccountServer();
	
	If RecalculateAmounts Then
		SalesServer.ConvertDocumentAmountToCurrency(Object, DocumentCurrency, Object.Currency, False);
		CalculateRemuneration = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure PartnerOnChangeServer()
	
	ArrayOfChangedProps = New Array;
	ArrayOfChangedProps.Add("Partner");
	
	StructureOfAdditionalSelection = New Structure("SelectedAgreement", Object.Terms);
	
	OperationArray = New Array();
	OperationArray.Add(PredefinedValue("Enum.BusinessTransactions.DeliveryForPrincipal"));
	StructureOfAdditionalSelection.Insert("BusinessTransactions", OperationArray);
	
	SalesTermsAndConditions = SalesServer.GetDefaultSalesTerms(
		Object.Partner,
		StructureOfAdditionalSelection);
		
	If SalesTermsAndConditions <> Undefined Then
		
		If Object.Terms <> SalesTermsAndConditions.Terms
			And ValueIsFilled(SalesTermsAndConditions.Terms) Then
		
			Object.Terms = SalesTermsAndConditions.Terms;
			TermsOnChangeServer();
			
		Else
			Object.Terms = SalesTermsAndConditions.Terms;
			ArrayOfChangedProps.Add("Currency");
			ArrayOfChangedProps.Add("LineOfBusiness");
			ArrayOfChangedProps.Add("Organization");
			ArrayOfChangedProps.Add("Counterparty");
			ArrayOfChangedProps.Add("Contract");
		EndIf;
			
	Else
		Object.Terms = Undefined;
	EndIf;
	
	If Not ValueIsFilled(Object.Counterparty) Then
		Object.Counterparty = PartnersAndCounterparties.GetPartnerSDefaultCounterparty(Object.Partner);
	EndIf;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, ArrayOfChangedProps);
	
	SetAvailabilityAgreements();
	
	UpdateTextOfInvoiceIssued();
	
	PartnersAndCounterparties.FillInDefaultPartnerContactPerson(Object.Partner, Object.ContactPerson);
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;	
	
	ResponsiblePersonsServer.FillInManager_(Object);
	
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
Procedure CounterpartyOnChangeServer()
	
	PurchasesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible);
	
	If ValueIsFilled(Object.Counterparty) Then
		FillInDefaultContract();
	EndIf;
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Counterparty");
	
EndProcedure

&AtServer
Procedure ContractOnChangeServer()
	
	ForeignCurrencyTransaction = Object.ForeignCurrencyTransaction;
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Contract");
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	
	If Object.ForeignCurrencyTransaction <> ForeignCurrencyTransaction Then
		Object.BankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
	EndIf;
	
	PurchasesServerCall.FillInBankAccountsUnderAgreement(Object.Contract, Object.BankAccount);
	Object.BankAccount = GetOrganizationSDefaultBankAccountServer();
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();
	ResponsiblePersonsServer.FillInManager_(Object);
	FillInSubordinatePropertiesForStatistics("Contract");
	SetPresentationOfFoundationDocument();
	
EndProcedure

&AtServer
Procedure VATTaxationOnChangeServer()
	
	CachedValuesInternal = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	If Object.CommissionFeeCalculationMethod <> Enums.CommissionFeeCalculationMethods.NotCalculating Then	
	
		CurrentRow = New Structure("VATRate", Object.VATRateOfRemuneration);
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
		BatchProcessingOfTablePartServer.ProcessTSString(CurrentRow, StructureOfActions, Undefined);
		Object.VATRateOfRemuneration = CurrentRow.VATRate;
	
		StructureOfActions = New Structure;
		StructureOfActions.Insert("ClearRewardAmount");
		
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			CachedValuesInternal.ProcessedRows,
			StructureOfActions,
			Object.Goods,
			Undefined);
	
	EndIf;
	
	If Object.VATTaxation = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT Then
		StructureOfActions = New Structure;
		StructureOfRecalculationOfAmount = New Structure("PriceIncludesVAT", Object.PriceIncludesVAT);
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("AdjustVATRate",  BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
		
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValuesInternal);
	EndIf;
	
	CalculateFinalIndicatorsOfReportToPurchasingCommittee(ThisObject);
	CalculateRemuneration = True;
	
	VATAccountingERP.SetVisibilityOfCommandAndFillInVATRate(ThisObject);
	
EndProcedure

&AtServer
Procedure PriceIncludesVATOnChangeServer(CachedValues)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object));
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));
	StructureOfActions.Insert("ClearRewardAmount");
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	
	For Each RowOfProduct In Object.Goods Do
		RowOfProduct.AmountVATRemuneration = 0;
	EndDo;
	
	Object.CommissionAmount = 0;
	Object.AmountVATRemuneration = 0;
	
	CalculateRemuneration = True;
	Items.GoodsSum.Visible = Not Object.PriceIncludesVAT
	Or Object.VATTaxation = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT;
	
EndProcedure

&AtServer
Procedure CommissionFeeCalculationMethodOnChangeServer()
	
	FormItemsManagement();
	CalculateFinalIndicatorsOfReportToPurchasingCommittee(ThisForm);
	
	UpdateTextOfInvoiceIssued();
	
EndProcedure

&AtServer
Function DateOnChangeServer(RecalculatePrices_2)
	
	If RecalculatePrices_2 Then
		PricesCalculated = FillThePricesByTermsOfSalesServer();
	Else
		PricesCalculated = False;
	EndIf;
	
	UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
														Object.Date);
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();
	
	ConsignmentSalesServer.FillInLBRateOfJointCommissionRemuneration(Object, VATPercentage);
	
	AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(ThisForm,
		Object.Date, "ProductsGroupQuantityByRNPT");
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Date");
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Procedure OperationServiceOnChangeServer()
	
	ConsignmentSalesServer.FillInLBRateOfJointCommissionRemuneration(Object, VATPercentage, True);
	
EndProcedure

&AtServer
Procedure LineOfBusinessOnChangeServer()
	
	If Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts Then
		
		FillInDefaultContract();
		
	EndIf;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "LineOfBusiness");
	
EndProcedure

&AtServer
Procedure SetPresentationOfFoundationDocument()
	
	PurchaseDocumentIsSpecified = False;
	SplitReportByDocuments = Common.ObjectAttributeValue(Object.Contract, "SplitReportByDocuments");
	
	If ValueIsFilled(Object.Contract)
		And (Not ContractIsOld = Object.Contract
		Or Not SplitReportByDocuments) Then
		
		Object.DocumentAcquisitions = Undefined;
		ContractIsOld = Object.Contract;
		
	EndIf;
	
	Items.PurchaseReport.Visible = ValueIsFilled(Object.Contract)
		And SplitReportByDocuments;
		
	If ValueIsFilled(Object.DocumentAcquisitions) Then
		
		StatusOfEDIOfPurchaseDocument = NStr("vi = '(Quản lý chứng từ điện tử: Chưa bắt đầu)';
											|ru = '(ЭДО: Не начат)';
											|en = '(EDI: Not started)'; fa = '(EDI: Not started)';
											|it = '(SDE: Non avviato)';
											|pl = '(EOD: Nie rozpoczęty)';
											|tr = '(EVD: Başlatılmadı)'");
		DescriptionPurchaseDocument = New FormattedString(String(Object.DocumentAcquisitions),,StyleColors.HyperlinkColor,,"OpenDocument");
		AcquisitionSubmission = New FormattedString(DescriptionPurchaseDocument, "  ", StatusOfEDIOfPurchaseDocument);
		PurchaseReport = True;
		PurchaseDocumentIsSpecified = True;
		
	ElsIf ValueIsFilled(Object.Contract)
		And SplitReportByDocuments
		And PurchaseReport Then
		AcquisitionSubmission = New FormattedString(NStr("vi = '<chưa chọn>';
														|ru = '<не выбран>';
														|en = '<Not selected>'; fa = '<Not selected>';
														|it = '<non è selezionato>';
														|pl = '<nie wybrany>';
														|tr = '<seçilmedi>'"),,StyleColors.SpecialTextColor,,"SelectDocument");
		PurchaseDocumentIsSpecified = True;
	Else
		Object.DocumentAcquisitions = Undefined;
	EndIf;
	
	If PurchaseReport Then
		Items.GoodsDocumentAcquisitions.Visible = False;
		Items.GoodsVendor.Visible = False;
		Items.GoodsVendorInvoiceReceived.Visible = False;
		Items.GoodsInvoiceIssuedToTheCommitee.Visible = False;
	Else
		Items.GoodsDocumentAcquisitions.Visible = True;
		Items.GoodsVendor.Visible = True;
		Items.GoodsVendorInvoiceReceived.Visible = True;
		Items.GoodsInvoiceIssuedToTheCommitee.Visible = True;
	EndIf;
	
	Items.GroupDataOnPurchaseDocument.Visible = PurchaseDocumentIsSpecified;
	
EndProcedure

&AtClient
Procedure RateOfCalculationOfRemunerationInCaseOfChangeItIsNecessaryToCalculateRemuneration(YouNeedToCalculateReward, AdditionalParameters) Export
	
	If YouNeedToCalculateReward = True Then
		RemunerationRate = Object.VATRateOfRemuneration;
		CalculateServerCommission();
		ConsignmentSalesClient.NotifyAboutEndOfCalculationOfRemuneration(Object.CommissionFeeCalculationMethod);
	ElsIf AdditionalParameters.RestoreAttributes Then
		Object.VATRateOfRemuneration = RemunerationRate;
	EndIf;
		
EndProcedure


#EndRegion

#Region SelectionAndProcessingOfQuantityVerification

&AtServer
Function PutProductsInStorage(Val Goods, Var_UUID)

	AddressOfPaymentsInTheStorage = PutToTempStorage(
		Goods.Unload(,"Products, Characteristic, Purpose, ItemsLocationAttributes, DocumentAcquisitions, Vendor, CCDNumber, NumberOfPackages"),
		Var_UUID);
		
	Return AddressOfPaymentsInTheStorage;
	
EndFunction

&AtServer
Procedure GetStockTypesFromStorage(ValueSelected)
	
	InventoriesServer.ProcessInputOfInventoryTypesManually(ValueSelected, ThisForm);
	
EndProcedure

&AtServer
Procedure GetProductsFromStorage(AddressOfPaymentsInTheStorage)
	
	CachedValues = Undefined;
	
	Object.Goods.Load(GetFromTempStorage(AddressOfPaymentsInTheStorage));
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePriceByAmount", "NumberOfPackages");
	StructureOfActions.Insert("FillInDataOnPurchaseDocumentInReportToPurchasingCommittee");
	StructureOfActions.Insert("FillInCCDTrackingAttribute",	New Structure("Products", "TheRecordsAreKeptByCCD"));
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActions,
		"DocumentAcquisitions",
		True);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	
	CalculateRemuneration = True;
	CalculateServerCommission();
	CalculateFinalIndicatorsOfReportToPurchasingCommittee(ThisForm);
	
	StructureCharacteristicsOfProducts = New Structure;
	StructureCharacteristicsOfProducts.Insert("FillInFeatureAttribute",	New Structure("Products", "ItemVariantsAreUsed"));
	StructureCharacteristicsOfProducts.Insert("FillInArticleAttribute",	New Structure("Products", "SKU"));
	
	StructureCharacteristicsOfProducts.Insert("FillInProductTypeAttribute_",	New Structure("Products", "ItemsType"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureCharacteristicsOfProducts);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	Documents.PurchasingReportToConsignorPrincipal.CheckForAcquisitionsAndCorrectiveAdjustmentsInSameReport(Object);
	
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
	EndIf;
	
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		ProcessingActions,
		"DocumentAcquisitions",
		True);
	
	PurchasesServer.ProcessIndicationOfCCDNumber(ThisObject,
												RowID,
												SelectionData_1,
												CCDNumbersFilledIn,
												Undefined,
												ProcessingActions);
	
	CalculateFinalIndicatorsOfReportToPurchasingCommittee(ThisObject);
	
	CalculateRemuneration = True;
	
EndProcedure

#EndRegion

#Region FormItemsManagement

&AtServer
Procedure FormItemsManagement()
	
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	
	Documents.PurchasingReportToConsignorPrincipal.FillInNamesOfDetailsAccordingToMethodOfCalculatingRemuneration(
		Object.CommissionFeeCalculationMethod,
		ArrayOfAllProps, 
		ArrayOfOperationDetails);
		
	CashServer.SetAvailabilityOfElementsByArray(
		Items,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	Items.GoodsSum.Visible = Not Object.PriceIncludesVAT
		Or Object.VATTaxation = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT;;
	
	CalculationMethodNotCalculated = (Object.CommissionFeeCalculationMethod = Enums.CommissionFeeCalculationMethods.NotCalculating);
	CommonClientServer.SetFormItemProperty(Items, "PaymentOffsetByRemuneration", "Enabled",Not CalculationMethodNotCalculated);
	CalculationMethodIsArbitraryAmount = (Object.CommissionFeeCalculationMethod = Enums.CommissionFeeCalculationMethods.ArbitraryAmount);
	CommonClientServer.SetFormItemProperty(Items, "RemunerationPercentage", "Visible", Not CalculationMethodIsArbitraryAmount);
	CommonClientServer.SetFormItemProperty(Items, "CommissionAmount", "ReadOnly", Not CalculationMethodIsArbitraryAmount);
	
EndProcedure

&AtClient
Procedure QuestionAboutRemovalOfGoods()
	
	If Not ReportOnOrder Then
		If Object.Goods.Count() > 0 Then
			QueryText = NStr("vi = 'Danh sách hàng hóa sẽ bị xóa. Tiếp tục?';
							|ru = 'Список товаров будет очищен. Продолжить?';
							|en = 'The item list will be cleared. Continue?'; fa = 'The item list will be cleared. Continue?';
							|it = 'L''elenco degli articoli sarà cancellato. Continuare?';
							|pl = 'Lista towarów zostanie wyczyszczona. Kontynuować?';
							|tr = 'Mallar listesi temizlenecek. Devam edilsin mi?'");
			ShowQueryBox(New CallbackDescription("ReportOnOrdersOnChangeCompletion",
				ThisObject, ), QueryText, QuestionDialogMode.YesNo);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ReportOnOrdersOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		Object.SalesOrder = Undefined;
		Object.Goods.Clear();
		UpdateOrderInformation();
	Else
		ReportOnOrder = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateOrderInformation()
	
	ParametersOfUpdate = OrdersServer.ParametersForUpdatingOrderInformationInForm();
	
	ParametersOfUpdate.PropsNameOrderList         = "OrderList";
	ParametersOfUpdate.OrderPathInHeader                  = "Object.SalesOrder";
	ParametersOfUpdate.TitleLabelName               = "HeaderOrdersText";
	ParametersOfUpdate.OrderNameInTablePart          = "SalesOrder";
	ParametersOfUpdate.UseOrdersInTabularSection = True;
	
	OrdersServer.UpdateOrderInformationInForm(ThisObject, Object.Goods, ParametersOfUpdate);

	ReportOnOrder = ValueIsFilled(Object.SalesOrder) Or OrderList.Count() > 0;
	Items.SalesByOrderGroup.Visible = ReportOnOrder; 
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure OnReadCreateAtServer()
	
	UseSimplifiedPaymentScheme = GetFunctionalOption("UseSimplifiedPaymentSchemeInPurchasing");
	UseLinesOfBusiness = GetFunctionalOption("UseCostAccountingByLinesOfBusiness");
	ToUseTermsOfSales = GetFunctionalOption("ToUseTermsOfSales");
	UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25();
	UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
														Object.Date);
	
	SetAvailabilityAgreements();
	
	DocumentCurrency = Object.Currency;
	FormItemsManagement();
	VATPercentage = PriceManagementSystemClientServer.GetVATRateAsNumber(Object.VATRateOfRemuneration);
	
	FillInDataOnPurchaseDocument();
	
	FillInInvoicesSubmittedByServer();
	
	UpdateTextOfInvoiceIssued();
	UpdateTextOfInvoiceReissued();
	UpdateOrderInformation();
	CalculateFinalIndicatorsOfReportToPurchasingCommittee(ThisForm);
	
	StructureCharacteristicsOfProducts = New Structure;
	StructureCharacteristicsOfProducts.Insert("FillInFeatureAttribute",	New Structure("Products", "ItemVariantsAreUsed"));
	StructureCharacteristicsOfProducts.Insert("FillInArticleAttribute",	New Structure("Products", "SKU"));
	
	StructureCharacteristicsOfProducts.Insert("FillInProductTypeAttribute_",	New Structure("Products", "ItemsType"));
	StructureCharacteristicsOfProducts.Insert("FillInCCDTrackingAttribute",	New Structure("Products", "TheRecordsAreKeptByCCD"));
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureCharacteristicsOfProducts);
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureCharacteristicsOfProducts);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
	FormMetadata = Common.ObjectManagerByRef(Object.Ref).MetadataOfDocument();
	
	
EndProcedure

&AtServer
Procedure FillInDefaultContract()
	
	If Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts 
			And UseLinesOfBusiness Then
			
		AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
		AddlParameters.ARAPCurrency = Object.Currency;
		AddlParameters.LineOfBusiness = Object.LineOfBusiness;
		Contract = PurchasesServer.GetDefaultContract(Object, 
															Enums.BusinessTransactions.DeliveryForPrincipal, 
															AddlParameters);
	Else
		
		AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
		AddlParameters.ARAPCurrency = Object.Currency;
		Contract = PurchasesServer.GetDefaultContract(Object, 
															Enums.BusinessTransactions.DeliveryForPrincipal, 
															AddlParameters);
	EndIf;	
		
	If Contract <> Object.Contract Then
		Object.Contract = Contract;
		ForeignCurrencyTransaction = Object.ForeignCurrencyTransaction;
		ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Contract");
		If ForeignCurrencyTransaction <> Object.ForeignCurrencyTransaction Then
			Object.BankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
		EndIf;
		PurchasesServerCall.FillInBankAccountsUnderAgreement(Object.Contract, Object.BankAccount);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInvoicesReceivedByServer()
EndProcedure

&AtServer
Procedure FillInInvoicesSubmittedByServer()
EndProcedure	

&AtServer
Procedure FillInDataOnPurchaseDocument()
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
	"Document.PurchasingReportToConsignorPrincipal.Form.DocumentForm.FillInDataOnPurchaseDocument");
	
	For Each RowProducts_ In Object.Goods Do
		TypesArray = New Array;
		TypesArray.Add(TypeOf(RowProducts_.DocumentAcquisitions));
		RowProducts_.PurchaseDocumentType = New TypeDescription(TypesArray);
	EndDo;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, Object.Goods.Count());
	
EndProcedure	

&AtServer
Function FillThePricesByTermsOfSalesServer(ErrorText = "")
	
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

	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	FillParameters = EnterprisePricesFillingServer.NewFillOptionsFillPrices();
	FillParameters.Insert("PopulationFields", "Price");
	FillParameters.Insert("Date", Object.Date);
	FillParameters.Insert("Organization", Object.Organization);
	FillParameters.Insert("Currency", Object.Currency);
	FillParameters.Insert("Terms", Object.Terms);
	FillParameters.Insert("VATTaxation", Object.VATTaxation);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	
	PricesCalculated = EnterprisePricesFillingServer.FillInPrices(
		Object.Goods,
		Undefined, // Array of strings
		FillParameters,
		StructureOfActions);
	
	ConsignmentSalesServer.FillInAmountWithVAT(
		Object.Goods,
		Object.PriceIncludesVAT);
	Return PricesCalculated;
	
EndFunction

&AtClient
Procedure QuestionUserBeforeFillingInPricesByAgreement(CallbackDescription)
	
	AnswersOptions = New ValueList;
	AnswersOptions.Add(True, NStr("vi = 'Điền lại';
									|ru = 'Перезаполнить';
									|en = 'Refill'; fa = 'پرکردن مجدد';
									|it = 'Ricompilare';
									|pl = 'Refill';
									|tr = 'Yeniden doldur'"));
	AnswersOptions.Add(False, NStr("vi = 'Không điền lại';
									|ru = 'Не перезаполнять';
									|en = 'Do not refill'; fa = 'Do not refill';
									|it = 'Non ricompilare';
									|pl = 'Nie wypełniaj ponownie';
									|tr = 'Yeniden doldurma'"));
	
	ShowQueryBox(
		CallbackDescription,
		NStr("vi = 'Điền lại giá theo thỏa thuận?';
			|ru = 'Перезаполнить цены по соглашению?';
			|en = 'Refill prices by terms of sales?'; fa = 'Refill prices by terms of sales?';
			|it = 'Ricompilare i prezzi in base all''accordo?';
			|pl = 'Wypełnić ceny ponownie wg porozumienia?';
			|tr = 'Fiyatlar anlaşmaya göre yeniden doldurulsun mu?'"),
		AnswersOptions);
	
EndProcedure

&AtServer
Procedure FillInByPurchaseResultServer()
	
	AssignmentsArray = New Array;
	ArrayOfAcquisitionDocuments = New Array;
	If ValueIsFilled(Object.DocumentAcquisitions) Then
		ArrayOfAcquisitionDocuments.Add(Object.DocumentAcquisitions);
	EndIf;
	Documents.PurchasingReportToConsignorPrincipal.RequirementsForGoodsAndServicesForMakingReportsToPurchasingCommittee(
		Object, 
		AssignmentsArray, ArrayOfAcquisitionDocuments);
		
	FillInDataOnPurchaseDocument();
	FillInvoicesReceivedByServer();
	FillInInvoicesSubmittedByServer();
	
	StructureCharacteristicsOfProducts = New Structure;
	StructureCharacteristicsOfProducts.Insert("FillInFeatureAttribute",	New Structure("Products", "ItemVariantsAreUsed"));
	StructureCharacteristicsOfProducts.Insert("FillInArticleAttribute",	New Structure("Products", "SKU"));
	
	StructureCharacteristicsOfProducts.Insert("FillInProductTypeAttribute_",	New Structure("Products", "ItemsType"));
	StructureCharacteristicsOfProducts.Insert("FillInCCDTrackingAttribute",	New Structure("Products", "TheRecordsAreKeptByCCD"));
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureCharacteristicsOfProducts);
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureCharacteristicsOfProducts);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
	CalculateServerCommission();
	CalculateFinalIndicatorsOfReportToPurchasingCommittee(ThisObject);
	UpdateOrderInformation();
	
EndProcedure

// This procedure is used in the AutoTest of the sales process.
//
&AtServer
Procedure CalculateServerCommission()
	
	ConsignmentSalesServer.CalculateRewardAmount(Object, "AmountIncludingVAT", True);
	CalculateRemuneration = False;
	For Each RowOfProduct In Object.Goods Do
		RowOfProduct.AmountARAP = RowOfProduct.AmountIncludingVAT + RowOfProduct.CommissionAmount;
	EndDo;
	
	FormItemsManagement();
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateFinalIndicatorsOfReportToPurchasingCommittee(Form)
	
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
	
	Form.LineNumberOfFullPayment = 0;
	
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
		
EndProcedure

&AtServer
Procedure SetAvailabilityAgreements()
	TMCommonUseClientServer.SetFormItemProperty(Items, "Terms", "Visible", ToUseTermsOfSales);
EndProcedure

&AtServer
Procedure UpdateTextOfInvoiceIssued()
	
	If Object.CommissionFeeCalculationMethod = PredefinedValue("Enum.CommissionFeeCalculationMethods.NotCalculating") Then
		TextInvoice = NStr("vi = 'Không cần lập hóa đơn GTGT (Hoa hồng ký gửi)';
							|ru = 'Оформление счета-фактуры не требуется (Комиссионное вознаграждение)';
							|en = 'Tax invoice registration is not required (Commission)'; fa = 'Tax invoice registration is not required (Commission)';
							|it = 'Formalizzazione fattura non richiesta (Provvigione)';
							|pl = 'Utworzenie faktury nie jest wymagane (Wynagrodzenie prowizyjne)';
							|tr = 'Fatura düzenlemesi gerekmez (Komisyon ücreti)'");
		TextOfTheInvoiceIssued = New FormattedString(TextInvoice);
	Else
		RegistrationParameters = ParametersForRegisteringInvoicesIssuedServer(Object);
		RegistrationParameters.Insert("DocumentPresentationPostfix", NStr("vi = '(Hoa hồng ký gửi)';
																			|ru = '(Комиссионное вознаграждение)';
																			|en = '(Commission)'; fa = '(Commission)';
																			|it = '(Provvigione)';
																			|pl = '(Wynagrodzenie prowizyjne)';
																			|tr = '(Komisyon ücreti)'"));
		InvoicesIssuedOnBasisOf = VATAccountingERP.InvoicesIssuedOnBasisOf(RegistrationParameters);
		TextOfTheInvoiceIssued =  InvoicesIssuedOnBasisOf.Presentation;
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateTextOfInvoiceReissued()
	
	ArrayOfHyperlinks = New Array;
	
	TaxInvoiceTextReissued = New FormattedString(ArrayOfHyperlinks);
	
EndProcedure

&AtClient
Procedure TextOfTheInvoiceIssuedURLProcessing(Item, Var_URL, StandardProcessing)
	
	RegistrationParameters = ParametersForRegisteringInvoicesIssuedServer(Object);
	VATAccountingERPClient.ProcessingNavigationLinkInvoicesIssued(ThisForm, Var_URL,  StandardProcessing, RegistrationParameters);
	
EndProcedure

&AtClient
Procedure TaxInvoiceTextReissuedURLProcessing(Item, Var_URL, StandardProcessing)
	
	
EndProcedure


&AtClient
Procedure CalculationsClick(Item, StandardProcessing)
	
	ARAPAccountingClient.CalculationsClick(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtServer
Procedure PlacePaymentDecryptionInTemporaryStorage()
	ARAPAccountingFormWork.PlacePaymentDecryptionInTemporaryStorage(ThisForm, "PaymentSettlement");
EndProcedure

&AtServer
Function GetRateOnPurchase(DataBiItem)
	Return Documents.PurchasingReportToConsignorPrincipal.GetVATRateOnPurchase(DataBiItem, Object.Organization);
EndFunction

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

&AtClient
Procedure Attachable_CloseForm()
	
	If IsOpen() Then
		Close();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInSubordinatePropertiesForStatistics(ParentPropsName)
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, ParentPropsName);
EndProcedure

#Region WorkingWithCounterparties
&AtClient
Procedure CheckCounterparties(Command)
	
	
EndProcedure

#EndRegion

&AtClient
Procedure DateOnChangeCompletion(QuestionResult, AdditionalParameters) Export 
	
	If Not QuestionResult = DialogReturnCode.Cancel Then
		PricesCalculated = DateOnChangeServer(QuestionResult);
	EndIf;
	
	If QuestionResult = True Then
		SalesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated);
	EndIf;
	
EndProcedure

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export 
	
	CurrentRow = Items.Goods.CurrentData;
	
	If NewRow <> Undefined Then
		
		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
		AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
			Object,
			StructureOfActions,
			"DocumentAcquisitions",
			True);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
		CalculateFinalIndicatorsOfReportToPurchasingCommittee(ThisForm);
		CalculateRemuneration = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInByPurchaseResultCompletion(Result, AdditionalParameters) Export 
	
	PerformanceMonitorClient.TimeMeasurement(
		"Document.PurchasingReportToConsignorPrincipal.Form.DocumentForm.FillInByPurchaseResultCompletion");

	FillInByPurchaseResultServer();
	
EndProcedure

&AtClient
Procedure SelectByPurchaseResultCompletion(Result, AdditionalParameters) Export
	
	PerformanceMonitorClient.TimeMeasurement(
		"Document.PurchasingReportToConsignorPrincipal.Form.DocumentForm.SelectByPurchaseResultCompletion");
	
	AddressGoodsInStorage = PutProductsInStorage(
		Object.Goods,
		UUID);
		
	PickingParameters = New Structure;
	PickingParameters.Insert("AddressGoodsInStorage", AddressGoodsInStorage);
	PickingParameters.Insert("Organization", Object.Organization);
	PickingParameters.Insert("Counterparty", Object.Counterparty);
	PickingParameters.Insert("Contract", Object.Contract);
	PickingParameters.Insert("Currency", Object.Currency);
	PickingParameters.Insert("Date", Object.Date);
	PickingParameters.Insert("DocumentAcquisitions", Object.DocumentAcquisitions);
	
	OpenForm(
		"CommonForm.SelectGoodsAndWorksForRegistrationOfPurchasingReportForConsignor",
		PickingParameters, 
		ThisForm);
	
EndProcedure

&AtServer
Procedure FillInSalesVATTaxation()
	
	FillParameters = Documents.PurchasingReportToConsignorPrincipal.ParametersForFillingInSalesVATTaxation(Object);
	VATAccountingERP.FillInSalesVATTaxation(Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues);
	VATAccountingERP.FillInSalesVATTaxSelectionList(Items.VATTaxation, Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues); 
	
EndProcedure

&AtClient
Procedure FillInVATRateCompletion(VATRate, AdditionalParameters) Export

	If VATRate = Undefined Then
		Return;
	EndIf;

	FillInVATRateOnServer(VATRate, CachedValues);
	CalculateRemuneration = True;

EndProcedure

&AtServer
Procedure FillInVATRateOnServer(VATRate, CachedValues)

	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));
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

	CalculateFinalIndicatorsOfReportToPurchasingCommittee(ThisObject);

EndProcedure

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
EndProcedure

&AtClient
Procedure GoodsVendorInvoiceReceivedOnChange(Item)
EndProcedure

// Parameters:
// 	HandlersParameters - Structure:
// * UpdateTextOfInvoiceReissued - Undefined
// * FillInInvoicesSubmittedByServer - Undefined
// * UpdateTextOfInvoiceIssued - Undefined
// * PaymentCreditedServer - See NewStructureCreditedToServer
//
&AtServer
Procedure CallServerHandlers(HandlersParameters)
	
	If HandlersParameters.Property("UpdateTextOfInvoiceIssued") Then
		UpdateTextOfInvoiceIssued();
	EndIf;
	
	If HandlersParameters.Property("FillInInvoicesSubmittedByServer") Then
		FillInInvoicesSubmittedByServer();
	EndIf;
	
	If HandlersParameters.Property("UpdateTextOfInvoiceReissued") Then
		UpdateTextOfInvoiceReissued();
	EndIf;
	
	PaymentCreditedServerParameters = Undefined; // See NewStructureCreditedToServer
	If HandlersParameters.Property("PaymentCreditedServer", PaymentCreditedServerParameters) And Not PaymentCreditedServerParameters = Undefined Then
		PaymentCreditedServer(PaymentCreditedServerParameters.EventName, PaymentCreditedServerParameters.Parameter, PaymentCreditedServerParameters.Source);
	EndIf;
	
EndProcedure	

// Returns:
// 	Structure:
// 		* EventName - String 
// 		* Parameter - Arbitrary
// 		* Source - Arbitrary
&AtClient
Function NewStructureCreditedToServer()
	
	Result = New Structure();
	Result.Insert("EventName");
	Result.Insert("Parameter");
	Result.Insert("Source");
	 
	Return Result;
	
EndFunction

&AtServer
Procedure ReflectChangesToPaymentRules(ChangedBankingDetails)
	
	PaymentStepsServer.LoadPaymentStagesFromTemporaryStorage(ThisForm);
	
	For Each PaymentStage In Object.PaymentScheduleSteps Do
		If Not ValueIsFilled(PaymentStage.PaymentOption) Then
			PaymentStage.PaymentOption = Enums.CustomerPaymentControlOptions.CreditAfterShipment;
		EndIf;
	EndDo;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, ChangedBankingDetails, True);
	AddSBPPaymentStatusUpdateCommand();
	
EndProcedure

&AtServerNoContext
Function GetOrderByDestination(CurrentData)
	SalesOrder = Undefined;
	If ValueIsFilled(CurrentData) Then
		SalesOrder = Common.ObjectAttributeValue(CurrentData, "OrderDocument");
	EndIf;
	Return SalesOrder;
EndFunction

&AtServer
Procedure PaymentCreditedServer(EventName, Parameter, Source)
	
	ARAPAccountingFormWork.NotificationProcessing(ThisForm, EventName, Parameter);
	
EndProcedure

&AtClient
Procedure AddPriceConversionAction(StructureOfActions)
	
	If (ToUseTermsOfSales And ValueIsFilled(Object.Terms)) 
		Or (Not ToUseTermsOfSales And UsePriceManagementSystem25) Then
		StructureOfActions.Insert("FillIn_TermsOfSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
	EndIf;
	
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
