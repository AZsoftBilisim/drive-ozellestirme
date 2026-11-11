#Region Variables

//used by the mechanism for processing changes in PM details
&AtClient
Var CachedValues;

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
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	ItemsAndDimensionsSelectionParameters = Documents.BankAccountIssue.ItemsAndDimensionsSelectionParameters(
		Object.BusinessOperation, Object.RecordCommission And Not Object.KeepRecordsOfCommissionInARAPAccounting);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	SetupParameters = Documents.BankAccountIssue.AccountingAccountSettings_(
		Object.BusinessOperation, Object.TaxType);
	GLAccountSettingsServer.OnCreateAtServer(ThisObject, SetupParameters);
	If Parameters.Property("BankAccount") Then
		Object.BankAccount = Parameters.BankAccount;
	EndIf;
	
	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisForm);
	
	GeneratingFiscalChecksServer.FormWhenCreatedOnServer(ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
		CashServer.CheckFillOutContract(Object);
	EndIf;
	
	Items.DecryptionWithoutSplittingRepaymentDate.ReadOnly = Not AccessRight(
		"Edit",
		Metadata.Documents.BankAccountIssue.TabularSections.ARAPDetails.Attributes.MaturityDate);
	
	Items.TransferToEmployeeViaABank.Enabled = Not ReadOnly;
	Items.ListOfIndividualsDisabled.ReadOnly = ReadOnly;
	Items.ListOfIndividualsIncluded.ReadOnly = ReadOnly;
	Items.ExpenseReportPeriod.ReadOnly = ReadOnly;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	// Handler of the "Properties" mechanism
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	DocumentCorrection.OnCreateAtServer(ThisForm, Items.LineCorrection);
	
	
	//++ WE
	ExchangeWithBankFeedsServer.WhenCreatingPaymentDocument(ThisObject);
	//-- WE
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	If Not ValueIsFilled(Object.Ref) Then
		
		FinancesClient.CheckDocumentCompletionBasedOn(Object, Object.DocumentBasis);
		
		CurrentDate = Object.Date;
		
		If ExpenseReportPeriod = NStr("vi = 'Qua tuần';
										|ru = 'Через неделю';
										|en = 'In a week'; fa = 'In a week';
										|it = 'Tra una settimana';
										|pl = 'Za tydzień';
										|tr = 'Bir hafta sonra'") Then
			Object.ExpenseReportDate = ?(ValueIsFilled(Object.Date), Object.Date, CurrentDate()) + 7 * 24 * 3600;
		EndIf;
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// The end of the standard subsystem.Pluggable commands
	// Standard subsystems.Worksfiles
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectionResult, ChoiceSource)
	
	If ChoiceSource.FormName = "Document.PaymentRequest.Form.PaymentRequestSelectionInCashIssueNote" Then
		
		ProcessingSelectionFromApplications(SelectionResult.AddressOfRequestsInRepository);
	EndIf;
	
	//++ WE
	If ChoiceSource.FormName = "Document.PayrollStatementHR.Form.ChoiceForm" Then
		ProcessingListSelection(SelectionResult);
	EndIf;
	//-- WE
	
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
	If Not CurrentObject.ProcessedByBank Then
		CurrentObject.AdditionalProperties.Insert("CheckingDateWhenChangesWereBanned", False);
	EndIf;
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	ItemsAndDimensionsSelectionParameters = Documents.BankAccountIssue.ItemsAndDimensionsSelectionParameters(
		Object.BusinessOperation, Object.RecordCommission And Not Object.KeepRecordsOfCommissionInARAPAccounting);
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	SetupParameters = Documents.BankAccountIssue.AccountingAccountSettings_(
		Object.BusinessOperation, Object.TaxType);
	GLAccountSettingsServer.OnReadAtServer(ThisObject, SetupParameters);
	ARAPAccountingFormWork.FormWhenReadingOnServer(ThisForm);
	
	GeneratingFiscalChecksServer.FormWhenReadingOnServer(ThisObject);
	
	OnReadCreateAtServer();
	
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	DocumentCorrection.OnReadAtServer(ThisForm, Items.LineCorrection);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	BusinessTransactionsExceptionOperations = New Array;
	BusinessTransactionsExceptionOperations.Add(PredefinedValue("Enum.BusinessTransactions.SalaryPaymentToBankAccounts"));
	
	BeforeRecordingProcessing(Cancel, WriteParameters, BusinessTransactionsExceptionOperations);
	
EndProcedure

&AtClient
Procedure BeforeRecordingProcessing(Cancel, WriteParameters, BusinessTransactionsExceptionOperations)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
	If NotExecuteCheck1BeforeWrite Then
		NotExecuteCheck1BeforeWrite = False;
		Return;
	EndIf;
	
	If WriteParameters.WriteMode = DocumentWriteMode.Posting
		And BusinessTransactionsExceptionOperations.Find(Object.BusinessOperation) = Undefined Then
		
		Cancel = True;
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("WriteParameters", WriteParameters);
		CallbackDescription = New CallbackDescription(
			"BeforeRecordingOfferToRecalculateAmountOfDocument", ThisObject, AdditionalParameters);
		
		TabularSection = ?(Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.IssueCashToAdvanceHolder")
							And PersonsList = 1,
							"PersonalAccountsOfStaff", "ARAPDetails");
		FinancesClient.RecalculateAmountOfDocumentBasedOnPaymentDecryption(ThisObject, CallbackDescription, TabularSection);
		Return;
	EndIf;
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters, Cancel);
	
EndProcedure

&AtClient
Procedure BeforeRecordingOfferToRecalculateAmountOfDocument(QuestionResult, AdditionalParameters) Export
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.IssueCashToAdvanceHolder")
		And PersonsList = 1
		And Object.ARAPDetails.Count() > 0 Then
		
		If Object.ARAPDetails.Total("Sum") <> Object.DocumentAmount Then
			
			MessageText = NStr("vi = 'Số tiền theo yêu cầu thanh toán không bằng số tiền chứng từ.';
								|ru = 'Сумма по заявкам на оплату не равна сумме документа.';
								|en = 'The amount of the payment requests is not equal to the document amount.'; fa = 'The amount of the payment requests is not equal to the document amount.';
								|it = 'The amount of the payment requests is not equal to the document amount.';
								|pl = 'The amount of the payment requests is not equal to the document amount.';
								|tr = 'Ödeme taleplerindeki tutar, belge tutarıyla eşit değil.'");
			CommonClient.MessageToUser(MessageText, , Items.ARAPDetails.Name, "Object", True);
			QuestionResult = False;
			
		EndIf;
		
	EndIf;
	
	If QuestionResult Then
		TMCommonUseClient.RecordObjectIfNecessary(ThisObject, AdditionalParameters.WriteParameters,,True);
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Handler of the "Properties" mechanism
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	
	ARAPAccountingServer.BeforeWriteAtServer(ThisForm, CurrentObject);
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	GLAccountSettingsServer.BeforeWriteAtServer(ThisObject, CurrentObject);
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_BankAccountIssue", WriteParameters, Object.Ref);
	ARAPAccountingClient.FormAfterRecording(ThisForm);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisForm, Object, WriteParameters);
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.CashPaymentToAnotherCompany")
		And ValueIsFilled(InvertedPaymentReference)
		And Not CorrespondsToInvertedPayment Then
			ShowQueryBox(New CallbackDescription("AlignMirrorPaymentCompletion", ThisObject, False),
				StrTemplate(NStr("vi = 'Kết chuyển khớp %1?';
								|ru = 'Привести в соответствие %1?';
								|en = 'Adjust to %1?'; fa = 'Adjust to %1?';
								|it = 'Rendere conforme %1?';
								|pl = 'Uzgodnić %1?';
								|tr = '%1 ile uygun hale getirsin mi?'"), InvertedPaymentReference), QuestionDialogMode.YesNo);
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	DocumentCorrectionClient.AfterWrite(Object);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	GLAccountSettingsServer.AfterWriteAtServer(ThisObject);
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	ARAPAccountingFormWork.FormAfterRecordingOnServer(ThisForm, CurrentObject.AdditionalProperties);
	CompleteVATTaxation(False);
	
	SetRestrictionOnTypeOfPaymentDecryptionContract();
	CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object, , True);
	
	FillInParametersOfCalculationObjectInDecryption();
	FillInCurrencyOfMutualSettlementsOfDocument();
	FillMultiplicityCourseWithText();
	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	SavedBusinessTransaction = Object.BusinessOperation;
	
	If ValueIsFilled(InvertedPaymentReference)
		And Object.BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany Then
		
		CorrespondsToInvertedPayment = Documents.BankAccountIssue.CorrespondsToInvertedPayment(
			Object.Ref, InvertedPaymentReference);
		
		If Not CorrespondsToInvertedPayment Then
			UpdateMirrorPaymentLabel();
		EndIf;
	EndIf;
	
	GeneratingFiscalChecksServer.FormWhenChangingBankingDetails(ThisObject);
	
	SetInscriptionOfDSEnrollment();
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	//++ WE
	ExchangeWithBankFeedsServer.AfterRecordingPaymentDocument(Object);
	//-- WE
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Handler of the "Properties" mechanism
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	If EventName = "GiftCertificateIsRead"
		And Parameter.OwnerForm = UUID Then
		
		ProcessGiftCertificate(Parameter.GiftCertificate);
	EndIf;
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
	DocumentCorrectionClient.NotificationProcessing(ThisForm, EventName, Parameter, Source);

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
	PerformVerificationOfFillingOutContractOfCommission = (Object.RecordCommission And Object.FeeAmount <> 0
		And Object.KeepRecordsOfCommissionInARAPAccounting);
	
	ExcludeVerificationOfFillingInARAPObjectOfFee = False;
	If Not PerformVerificationOfFillingOutContractOfCommission Then
		NotCheckedAttributeArray.Add("CommissionAgreement");
		ExcludeVerificationOfFillingInARAPObjectOfFee = True;
	EndIf;
	
	If Not ValueIsFilled(CommissionAgreement) Then
		ExcludeVerificationOfFillingInARAPObjectOfFee = True; 
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	If Not DecryptionSwitch Then
		
		DocumentObject = FormAttributeToValue("Object");
		DocumentObject.AdditionalProperties.Insert("ExplanationWithoutSplit", True);
		
		If ExcludeVerificationOfFillingInARAPObjectOfFee Then
			DocumentObject.AdditionalProperties.Insert("ExcludeVerificationOfFillingInARAPObjectOfFee", True);
		EndIf;
		
		If Not DocumentObject.CheckFilling() Then
			Cancel = True;
		EndIf;
		
		ObjectAttributesToBeChecked = CheckedAttributes.Find("Object");
		If ObjectAttributesToBeChecked <> Undefined Then
			CheckedAttributes.Delete(ObjectAttributesToBeChecked);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	ForceCloseTheForm = True;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure StateOfBankFeedsClick(Item, StandardProcessing)
	
	//++ WE
	ExchangeWithBankFeedsServiceClient.ProcessClickingOnStateOfDocument(Object.Ref, ThisObject, StandardProcessing);
	//-- WE
	
	Return;
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	NeedProcessing = DateOnChangeClient();
	If NeedProcessing Then
		CurrentDate = Object.Date;
		DateOnChangeServer();
	EndIf;
	
EndProcedure

&AtClient
Function DateOnChangeClient()
	
	If CurrentDate = Object.Date Then
		Return False;
	EndIf;
	
	Object.ExpenseReportDate =
		CashClient.RecalculateAdvanceReportDate(ExpenseReportPeriod, Object.Date);
	
	If Object.ProcessedByBank Then
		Object.BankPostingDate = Object.Date;
	EndIf;
	
	Return True;
	
EndFunction

&AtClient
Procedure ProcessedByBankOnChange(Item)
	
	If Not Object.ProcessedByBank Then
		Object.BankPostingDate = Undefined;
	Else
		If Not ValueIsFilled(Object.BankPostingDate) Then
			Object.BankPostingDate = Object.Date;
		EndIf;
	EndIf;
	
	ProcessedByBankOnChangeServer();
	
EndProcedure

&AtServer
Procedure ProcessedByBankOnChangeServer()
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisForm);
	
	FillInSettlementRate();
	CalculateAmountOfSettlements_();
	FillMultiplicityCourseWithText();
	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	
	ConfigureDependentFormElementsOnServer();
	
	GeneratingFiscalChecksServer.FormWhenChangingBankingDetails(ThisObject);
	
EndProcedure

&AtClient
Procedure BankPostingDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateWhenChangeWasMadeByBankOnServer();
	
EndProcedure

&AtServer
Procedure DateWhenChangeWasMadeByBankOnServer()
	
	FillInSettlementRate();
	CalculateAmountOfSettlements_();
	FillMultiplicityCourseWithText();
	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	NeedToSwitchToServer = BusinessOperationOnChangeClient();
	If NeedToSwitchToServer Then
		BusinessOperationOnChangeServer();
	EndIf;
	
	UpdatePresentationOfMaturityDate();
	
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	
EndProcedure

&AtClient
Function BusinessOperationOnChangeClient()
	
	If SavedBusinessTransaction = Object.BusinessOperation Then
		Return False;
	EndIf;
	
	SetPaymentByRequestAttribute();
	
	Return True;
	
EndFunction

&AtServer
Procedure BusinessOperationOnChangeServer()
	
	CashServer.ClearApplicationForSpendingMoney(Object);
	
	RequestList.Clear();
	
	If Not Object.TransferOfTaxesAndContributions Then
		Object.PaymentID = "";
	EndIf;
	
	If ValueIsFilled(Object.DocumentBasis)
		And AvailableBaseOfOperations.FindByValue(Object.BusinessOperation) = Undefined Then
		
		Object.DocumentBasis = Undefined;
		AvailableBaseOfOperations.Clear();
		
	EndIf;
	
	InitializePaymentDecryption();
	
	For Each DecryptionString In Object.ARAPDetails Do
		IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, DecryptionString, "Object.ARAPDetails");
	EndDo;
	
	CashServer.DetermineCurrencyPayment(ThisObject);
	
	SetPossibleRecipientAccountValues();
	
	If Not AccountCorrespondsToOwner() Then
		Object.CounterpartyBankAccount = Undefined;
	EndIf;
	
	CurrentPaymentWithConversion = Object.PaymentWithConversion;
	SetPaymentWithConversionAttribute();
	
	If CurrentPaymentWithConversion
		And Not Object.PaymentWithConversion Then
	
		If ValueIsFilled(Object.BankAccount) Then
			Object.Currency = Common.ObjectAttributeValue(Object.BankAccount, "CashCurrency");
			UpdateCurrencyData();
		EndIf;
		
	EndIf;
	
	CFItemByBT = Catalogs.CashFlowReportItems.CashFlowItemForBusinessTransaction(
		Object.BusinessOperation);
	Object.CashFlowItem = CFItemByBT;
	
	If Not ValueIsFilled(Partner) Then
		Partner = CashServer.GetCounterpartyPartner(Object.Counterparty, Object.BusinessOperation);
	EndIf;
	
	For Each PaymentDecryptionString In Object.ARAPDetails Do
		
		PaymentDecryptionString.CashFlowItem = CFItemByBT;
		
		If Not ValueIsFilled(PaymentDecryptionString.Partner) Then
			PaymentDecryptionString.Partner = Partner;
		EndIf;
		
	EndDo;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices
		And Not Catalogs.Companies.OrganizationIsInterconnectedWithOtherOrganizations(Object.Organization) Then
		
		Object.BankAccountBeneficiary = Undefined;
		If CurrentBankAccount <> Object.BankAccount Then
			
			AttributesStructure1 = Catalogs.CompaniesBankAccounts.GetCompanySBankAccountDetails(Object.BankAccount);
			OnChangingBankAccount(AttributesStructure1);
			
		EndIf;
	EndIf;
	
	ManagerOfDocument = Common.ObjectManagerByFullName("Document.BankAccountIssue");
	CashServer.FillInFormDataAccordingToListOfAttributesOfBusinessTransaction(Object, ManagerOfDocument);
	
	CurrentCounterparty = Object.Counterparty;
	
	If Not ValueIsFilled(Object.Counterparty) Then
		Partner = Catalogs.Partners.EmptyRef();
		CounterpartyLegEntInd = Enums.LegalEntityIndividual.EmptyRef();
	EndIf;
	SetupParameters = Documents.BankAccountIssue.AccountingAccountSettings_(
		Object.BusinessOperation, Object.TaxType);
	GLAccountSettingsServer.WhenChangingSettings(ThisObject, SetupParameters);
	
	If Object.BusinessOperation = Enums.BusinessTransactions.PaymentToLessor Then
		
		For Each TSRow In Object.ARAPDetails Do
			TSRow.LeaseContracts = Catalogs.LeaseContract.DefaultContract(
				Object.Organization, TSRow.Partner, Object.Counterparty, TSRow.LeaseContracts);
		EndDo;
		
		FillInAttributesOfPaymentUnderLeaseContracts();
		
	EndIf;
	ItemsAndDimensionsSelectionParameters = Documents.BankAccountIssue.ItemsAndDimensionsSelectionParameters(
		Object.BusinessOperation, Object.RecordCommission And Not Object.KeepRecordsOfCommissionInARAPAccounting);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisObject);
	
	GeneratingFiscalChecksServer.FormWhenChangingBankingDetails(ThisObject);
	
	If Not Object.BusinessOperation = Enums.BusinessTransactions.PaymentToLessor Then
		
		CounterpartyContract = Undefined;
		GetDefaultContractServer(Object.Counterparty, Object.CounterpartyBankAccount);
		
		If ValueIsFilled(CounterpartyContract) Then
			ARAPObjectContract = ARAPObjectsServer.GetCalculationObjectFromLink(CounterpartyContract);
		EndIf;
	
		For Each TSRow In Object.ARAPDetails Do
			FillInPaymentTranscript(TSRow, ARAPObjectContract);
		EndDo;
		
	EndIf;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.WithdrawalFromBankAccount
		 And Not ValueIsFilled(Object.CashAccountRecipient) Then
		Object.CashAccountRecipient = Catalogs.CashAccounts.GetCheckoutByDefault(Object.Organization, Object.Currency);
	EndIf;
	
	CashServer.CalculateAmountsInSenderSCurrencyInDecryption(Object, BankAccountCurrency);
	FillInCurrencyOfMutualSettlementsOfDocument();
	Object.LineOfBusiness = CashServer.LineOfBusiness(
		Object.BusinessOperation,
		Object.LineOfBusiness);
	CashServer.CompleteVATTaxation(
		Object,
		Object.VATTaxation,
		Items.DecodingWithoutSplittingVATTaxation,
		Items.DecryptionWithoutDivisionTaxationVATRefund,
		True);
	UpdateMirrorPaymentLabel();
	UpdateInformationOnApplications();
	
	DisplayingTitleOfAccountablePersonField();
	
	Object.PersonsList = False;
	PersonsList = 0;
	
	FormItemsManagement();
	
	SavedBusinessTransaction = Object.BusinessOperation;
	
EndProcedure

&AtClient
Procedure BankAccountOnChange(Item)
	
	ReturnStructure = BankAccountOnChangeClient("CurrencyConversionAllowed");
	If ReturnStructure.NeedToSwitchToServer Then
		BankAccountOnChangeServer(ReturnStructure.BankAccountDetails, ReturnStructure.AmountsRecalculate);
	EndIf;
	
EndProcedure

&AtClient
Function BankAccountOnChangeClient(HandlerName)
	
	ReturnStructure = New Structure("NeedToSwitchToServer, BankAccountDetails, AmountsRecalculate");
	
	BankAccountDetails = GetBankAccountDetails(Object.BankAccount);
	
	AllowPaymentsWithoutApplicationSpecificationBankAccount = BankAccountDetails.EnableCreatingCashIssueWithoutPaymentRequest;
	EnabledCreatingCashIssueWithoutPaymentRequest =
		(AllowPaymentsWithoutApplicationSpecificationBankAccount And UsePaymentRequests)
		Or Object.DoNotControlRequestFilling
		Or Not UsePaymentRequests;
		
	SetPaymentByRequestAttribute();
	
	If Not FinancesClient.CurrencyConversionRequired(Object, Object.Currency, BankAccountDetails.Currency) Then
		
		ReturnStructure.Insert("NeedToSwitchToServer", True);
		ReturnStructure.Insert("BankAccountDetails", BankAccountDetails);
		ReturnStructure.Insert("AmountsRecalculate", False);
	Else
		
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Tính lại số tiền trong chứng từ theo tiền tệ %1?';
				|ru = 'Пересчитать суммы в документе в валюту %1?';
				|en = 'Convert amounts in the document in %1?'; fa = 'Convert amounts in the document in %1?';
				|it = 'Ricalcolare gli importi del documento in valuta %1?';
				|pl = 'Przeliczyć kwoty w dokumencie na walutę %1?';
				|tr = 'Belgedeki tutarlar %1 para birimine göre yeniden hesaplansın mı?'"),
			BankAccountDetails.Currency);
		
		QuestionDialogButtons = New ValueList;
		QuestionDialogButtons.Add(DialogReturnCode.Yes, NStr("vi = 'Tính lại';
															|ru = 'Пересчитать';
															|en = 'Recalculate'; fa = 'محاسبه مجدد';
															|it = 'Ricalcolare';
															|pl = 'Recalculate';
															|tr = 'Yeniden hesapla'"));
		QuestionDialogButtons.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
																|ru = 'Отменить';
																|en = 'Cancel'; fa = 'انصراف';
																|it = 'Annullare';
																|pl = 'Cancel';
																|tr = 'İptal et'"));
		
		CallbackDescription = New CallbackDescription(
			HandlerName, ThisObject, New Structure("AttributesStructure1", BankAccountDetails));
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogButtons);
		
		ReturnStructure.Insert("NeedToSwitchToServer", False);
	EndIf;
	
	Return ReturnStructure;
	
EndFunction

&AtClient
Procedure CurrencyConversionAllowed(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		
		CurrentCurrency = Object.Currency;
		BankAccountOnChangeServer(AdditionalParameters.AttributesStructure1, True);
		PriceManagementSystemClient.NotifyAboutEndOfConversionOfAmountsIntoCurrency(CurrentCurrency, Object.Currency);
	Else
		
		Object.BankAccount = CurrentBankAccount;
	EndIf;
	
EndProcedure

&AtServer
Procedure BankAccountOnChangeServer(AttributesStructure1, AmountsRecalculate)
	
	OrganizationChanged_ = (Object.Organization <> AttributesStructure1.Organization);
	CurrencyChanged_1 = (Object.Currency <> AttributesStructure1.Currency);
	
	AttributesArray = New Array;
	If OrganizationChanged_ Then
		AttributesArray.Add("Organization");
	EndIf;
	If CurrencyChanged_1 Then
		AttributesArray.Add("Currency");
	EndIf;
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, AttributesArray);
	
	If OrganizationChanged_ Then
		
		CashServer.ClearApplicationForSpendingMoney(Object);
		
		If Object.BusinessOperation <> Enums.BusinessTransactions.CurrencyConversion
			And Not Object.TransferOfTaxesAndContributions Then
			Object.PaymentID = "";
		EndIf;
	
	EndIf;
	
	OnChangingBankAccount(AttributesStructure1);
	SetPaymentWithConversionAttribute();
	
	If ValueIsFilled(Object.BankAccount) Then

		FillInInvoiceUnderAgreement = OrganizationChanged_ Or Not ValueIsFilled(Object.CounterpartyBankAccount);
		GetDefaultContractServer(Object.Counterparty, Object.CounterpartyBankAccount, FillInInvoiceUnderAgreement);
		
		If OrganizationChanged_ Then
			
			If ValueIsFilled(CounterpartyContract) Then
				PaymentType_ = ?(Object.BusinessOperation = Enums.BusinessTransactions.PaymentToVendor
					Or Object.BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany
					Or Object.BusinessOperation = Enums.BusinessTransactions.CustomsPayment,
					Enums.PartnersARAPAccountingTypes.VendorARAPAccounting,
					Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting);
					
				ARAPObjectContract = ARAPObjectsServer.GetCalculationObjectFromLink(CounterpartyContract,,PaymentType_);
			EndIf;
			
			For Each TSRow In Object.ARAPDetails Do
				FillInPaymentTranscript(TSRow, ARAPObjectContract);
			EndDo;
			
		EndIf;
	Else
		CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object, , True);
		ProcessIPChange();
	EndIf;
	
	If CurrentCurrency <> Object.Currency
		Or AmountsRecalculate Then
		WhenChangingCurrency();
	EndIf;
	FillInContractFeeSVObjectOfSettlementARAPObject();
	
	SetPossibleRecipientAccountValues();
	If Object.BusinessOperation = Enums.BusinessTransactions.PaymentToLessor Then
		
		For Each TSRow In Object.ARAPDetails Do
			TSRow.LeaseContracts = Catalogs.LeaseContract.DefaultContract(
				Object.Organization, TSRow.Partner, Object.Counterparty, TSRow.LeaseContracts);
		EndDo;
		
		FillInAttributesOfPaymentUnderLeaseContracts();
		
	EndIf;
	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure CounterpartyBankAccountOnChange(Item)
	
	CounterpartyBankAccountOnChangeServer();
	
EndProcedure

&AtServer
Procedure CounterpartyBankAccountOnChangeServer()
	
	FillInCurrencyOnRecipientSAccount(Object.CounterpartyBankAccount);
	
	If Not ValueIsFilled(Object.PaymentPurposes) Then
		FillInPurposeOfPaymentOnRecipientSAccount();
	EndIf;
	
	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure DocumentAmountOnChange(Item)
	
	DocumentAmountOnChangeClient();
	DocumentAmountOnChangeServer();
	
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)

	NeedToSwitchToServer = CurrencyOnChangeClient();
	
	If NeedToSwitchToServer Then
		CurrencyWhenChangedOnServer();
	EndIf;

EndProcedure

&AtClient
Procedure FeeAmountOnChange(Item)
	
	If Object.DocumentAmount <> 0 Then
		CommissionRate = CashClientServer.CalculateCommissionRate(Object.DocumentAmount, Object.FeeAmount, "Return");
	Else
		CommissionRate = 0;
	EndIf;
	Items.GroupCommission.Title = TitleOfAcquiringCommission(Object.FeeAmount, Object.Currency, CommissionRate);
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyOnChangeServer();
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	
	CounterpartySCurrentBankAccount = Object.CounterpartyBankAccount;
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Counterparty");
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, "Counterparty");
	
	If CurrentCounterparty <> Object.Counterparty Then
		
		CashServer.ClearApplicationForSpendingMoney(Object);
		
		If Object.BusinessOperation <> Enums.BusinessTransactions.CurrencyConversion Then
			Object.PaymentID = "";
		EndIf;
	
	EndIf;
	
	WhenChangingCounterparty(Object.Counterparty, Object.CounterpartyBankAccount, Object.ListOfCounterparties_ = False);
	
	If ValueIsFilled(Object.Counterparty) Then
		
		If ValueIsFilled(Object.CounterpartyBankAccount)
			And Common.ObjectAttributeValue(Object.CounterpartyBankAccount, "Closed") Then
			Object.CounterpartyBankAccount = Undefined;
		EndIf;
		
		If Not ValueIsFilled(Object.CounterpartyBankAccount) Then
			Object.CounterpartyBankAccount =
				Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(Object.Counterparty, Object.Currency);
		Else
			
			If Object.Counterparty <> Common.ObjectAttributeValue(Object.CounterpartyBankAccount, "Owner") Then
				Object.CounterpartyBankAccount =
					Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(Object.Counterparty, Object.Currency);
			EndIf;
			
		EndIf;
		
		If CounterpartySCurrentBankAccount <> Object.CounterpartyBankAccount
			And ValueIsFilled(Object.CounterpartyBankAccount) Then
			CounterpartyBankAccountOnChangeServer();
		EndIf;
		
		FillInPurposeOfPaymentOnRecipientSAccount();
		
		If Object.BusinessOperation = Enums.BusinessTransactions.RefundAcquiringPayment Then
			
			FilterParameters = Catalogs.AcquiringContracts.ParametersOfAcquisitionContractSelection();
			
			FilterParameters.Organization = Object.Organization;
			FilterParameters.Acquirer = Object.Counterparty;
			FilterParameters.BankAccount = Object.BankAccount;
			Object.AcquiringContract = Catalogs.AcquiringContracts.ContractOfAcquiringByDefault(FilterParameters);
			If ValueIsFilled(Object.AcquiringContract) Then
				AcquiringAgreementInCaseOfChangesOnServer();
			EndIf;
		EndIf;
	
	EndIf;
	FillInContractFeeSVObjectOfSettlementARAPObject();
	If Object.BusinessOperation = Enums.BusinessTransactions.PaymentToLessor Then
		
		For Each TSRow In Object.ARAPDetails Do
			TSRow.LeaseContracts = Catalogs.LeaseContract.DefaultContract(
				Object.Organization, TSRow.Partner, Object.Counterparty, TSRow.LeaseContracts);
		EndDo;
		
		FillInAttributesOfPaymentUnderLeaseContracts();
		
	EndIf;
	SetVisibilityOfGiftCertificateSelectionButton();
	
	If Not DecryptionSwitch Then
		SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning();
	EndIf;
	
	SetRestrictionOnTypeOfPaymentDecryptionContract();
	
	GeneratingFiscalChecksServer.FormWhenChangingBankingDetails(ThisObject);
	
	CurrentCounterparty = Object.Counterparty;
	ConfigureDependentFormElementsOnServer("Counterparty");
	
EndProcedure

&AtClient
Procedure AcquiringContractOnChange(Item)
	
	AcquiringAgreementInCaseOfChangesOnServer();
	
EndProcedure

&AtServer
Procedure AcquiringAgreementInCaseOfChangesOnServer()
	
	AttributesValues = Catalogs.AcquiringContracts.ContractDetails_(Object.AcquiringContract);
	
	Object.CashFlowItem = AttributesValues.CashFlowItemReturn;
	
	Object.RecordCommission = (AttributesValues.CommissionPostingMethod = Enums.MethodsOfAcquiringCommissionRecording.OnCashReceiving
		And AttributesValues.FeeIsChargedOnRefund);
	
	If Object.RecordCommission Then
		
		If AttributesValues.FixedFeeRate Then
			CommissionRate = AttributesValues.CommissionRate;
			Object.FeeAmount = CashClientServer.CalculateCommissionAmount(Object.DocumentAmount, CommissionRate, "Return");
		Else
			CommissionRate = 0;
		EndIf;
		
		Object.ExpenseItem          = AttributesValues.ExpenseItem;
		Object.DimensionOfExpenses       = AttributesValues.DimensionOfExpenses;
		Object.Department           = AttributesValues.ExpensesBusinessUnit;
		Object.LineOfBusiness = AttributesValues.LineOfBusiness;
		Object.KeepRecordsOfCommissionInARAPAccounting = AttributesValues.KeepRecordsOfCommissionInARAPAccounting;
		Object.CommissionARAPObject = AttributesValues.CommissionARAPObject;
		CommissionAgreement = ContractARAPObjectOfFee(Object.CommissionARAPObject);
	Else
		Object.FeeAmount = 0;
		Object.KeepRecordsOfCommissionInARAPAccounting = False;
		Object.CommissionARAPObject = Catalogs.ARAPObjects.EmptyRef();
		CommissionAgreement = Catalogs.CounterpartyContracts.EmptyRef();
	EndIf;
	KeepRecordsOfCommissionInMutualSettlementsSwitch = Object.KeepRecordsOfCommissionInARAPAccounting;
	
	ItemsAndDimensionsSelectionParameters = Documents.PaymentRequest.ItemsAndDimensionsSelectionParameters(
		Object.BusinessOperation, Object.RecordCommission And Not Object.KeepRecordsOfCommissionInARAPAccounting);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure AdvanceHolderOnChange(Item)
	
	AdvanceHolderOnChangeServer();
	
EndProcedure

&AtServer
Procedure AdvanceHolderOnChangeServer()
	
	If ValueIsFilled(Object.AdvanceHolder) Then
		If (Not ValueIsFilled(Object.CounterpartyBankAccount)
			Or Not AccountCorrespondsToOwner())
			And Not Object.TransferToEmployeeViaABank Then
			Object.CounterpartyBankAccount =
				Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(Object.AdvanceHolder, Object.Currency);
		EndIf;
	EndIf;
	
	If Object.PaymentByRequests Then
		CashServer.SetApplicationSelectionParameters(
			Object, Items.ARAPDetailsPaymentRequest);
		CashServer.SetApplicationSelectionParameters(
			Object, Items.DecryptionWithoutSplittingTheApplicationForSpendingMoney);
	EndIf;
	
	ConfigureDependentFormElementsOnServer("AdvanceHolder");
	
EndProcedure

&AtClient
Procedure PaymentRequestOnChange(Item)
	
	If ValueIsFilled(Object.PaymentRequest) Then
		PaymentRequestOnChangeServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure PaymentRequestOnChangeServer()
	
	HeldByBankSavedValue = Object.ProcessedByBank;
	
	DocumentObject = FormAttributeToValue("Object");
	DocumentObject.Fill(Object.PaymentRequest);
	ValueToFormAttribute(DocumentObject, "Object");
	
	If (Object.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentByPayrollCardProgram
			Or Object.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentToBankAccounts)
		And Not Object.ProcessedByBank Then
		Object.ProcessedByBank = HeldByBankSavedValue;
	EndIf;
	
	SetPossibleRecipientAccountValues();
	
EndProcedure

&AtClient
Procedure CashTransferReferenceOrderOnChange(Item)
	
	If ValueIsFilled(Object.CashTransferReferenceOrder) Then
		CashTransferReferenceOrderOnChangeServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure CashTransferReferenceOrderOnChangeServer()
	
	DocumentObject = FormAttributeToValue("Object");
	DocumentObject.Fill(Object.CashTransferReferenceOrder);
	ValueToFormAttribute(DocumentObject, "Object");
	
EndProcedure

&AtClient
Procedure BankAccountBeneficiaryOnChange(Item)
	
	BankAccountBeneficiaryOnChangeServer();
	
EndProcedure

&AtServer
Procedure BankAccountBeneficiaryOnChangeServer()
	
	SourceCompanyRecipient = CompanyRecipient;
	
	OnChangingRecipientSBankAccount();
	
	SetPossibleRecipientAccountValues(False);
	
	If ValueIsFilled(Object.BankAccountBeneficiary) Then
		
		If ValueIsFilled(SourceCompanyRecipient)
			And SourceCompanyRecipient <> CompanyRecipient Then
			CashServer.ClearApplicationForSpendingMoney(Object);
		EndIf;
		
	EndIf;
	
	FillInCurrencyOnRecipientSAccount(Object.BankAccountBeneficiary);
	
	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure CurrencyOfConversionOnChange(Item)
	
	CurrencyOfConversionOnChangeServer();
	
EndProcedure

&AtClient
Procedure ConversionRateOnChange(Item)
	
	RecalculateConversionParameters("ConversionRate");
	
EndProcedure

&AtClient
Procedure ConversionAmountOnChange(Item)
	
	RecalculateConversionParameters("ConversionAmount");
	
	If Object.ARAPDetails.Count() = 1 Then
		Object.ARAPDetails[0].Sum = Object.DocumentAmount;
	EndIf;
	
EndProcedure

&AtClient
Procedure TextApplicationHeaderClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If RequestList.Count() = 1 Then
		ShowValue(, RequestList[0].Value);
	Else
		OpenForm(
			"CommonForm.ViewingListOfDocuments",
			New Structure("DocumentsList, Title",
				RequestList,
				NStr("vi = 'Giấy đề nghị thanh toán (%DocumentsCount%)';
					|ru = 'Заявки на оплату (%DocumentsCount%)';
					|en = 'Payment requests (%DocumentsCount%)'; fa = 'Payment requests (%DocumentsCount%)';
					|it = 'Payment requests (%DocumentsCount%)';
					|pl = 'Payment requests (%DocumentsCount%)';
					|tr = 'Ödeme talepleri (%DocumentsCount%)'")
			),
			ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtClient
Procedure PaymentByRequestsOnChange(Item)
	
	WhenChangingPaymentForMultipleRequests();
	
EndProcedure

&AtServer
Procedure WhenChangingPaymentForMultipleRequests()
	
	If Not Object.PaymentByRequests Then
		
		If PersonsList Then
			PersonalAccountsOfEmployeesWhenChangedOnServer();
		Else
			
			For Each String In Object.ARAPDetails Do
				String.PaymentRequest = Undefined;
			EndDo;
			
		EndIf;
		
		Object.PaymentRequest = Undefined;
		RequestList.Clear();
	EndIf;
	
	InitializePaymentDecryption();
	CashServer.CheckFillOutContract(Object);
	UpdateInformationOnApplications();
	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	If CurrentPage = Items.TheDecryptionPage And Not DecryptionSwitch And Not ReadOnly Then
		ARAPDetailsOnStartEdit(Item, False, False);
	EndIf;
	
EndProcedure

&AtClient
Procedure MirrorPaymentClick(Item, StandardProcessing)
	
	If ValueIsFilled(InvertedPaymentReference) Then
		StandardProcessing = False;
		ShowValue(,InvertedPaymentReference);
	EndIf;
	
EndProcedure

&AtClient
Procedure CodesOfInstructionsForBankClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	InstructionList = New Array;
	For Each InstructionLine In Object.InstructionsForBank Do
		InstructionList.Add(InstructionLine.Instruction);
	EndDo;
	
	InstructionSelectionOptions = New Structure;
	InstructionSelectionOptions.Insert("InstructionList", InstructionList);
	
	OpenForm("Catalog.InstructionsForBank.ChoiceForm",
		InstructionSelectionOptions,
		ThisForm,,,,
		New CallbackDescription("AfterSelectingInstructionsToBank", ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AfterSelectingInstructionsToBank(Result, AdditionalParameters) Export
	
	If TypeOf(Result) = Type("Array") Then
		Modified = True;
		Object.InstructionsForBank.Clear();
		For Each NewInstructions In Result Do
			Object.InstructionsForBank.Add().Instruction = NewInstructions;
		EndDo;
		CodesOfInstructionsForBank = LabelInstructionCodes(Object);
	EndIf;
	
EndProcedure

&AtClient
Procedure InformationForRegulatoryBodiesClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	ShowInputString(New CallbackDescription("AfterEnteringLineInformationForRegulatoryAuthorities", ThisObject),
		Object.InformationForRegulatoryBodies, NStr("vi = 'Thông tin cho bộ điều khiển (77B):';
													|ru = 'Информация для регулятора (77B):';
													|en = 'Information for controller (77V):'; fa = 'Information for controller (77V):';
													|it = 'Informazioni per il regolatore (77B):';
													|pl = 'Informacje dla regulatora (77B):';
													|tr = 'Düzenleyici için bilgi (77B):'"),, True);
	
EndProcedure

&AtClient
Procedure AfterEnteringLineInformationForRegulatoryAuthorities(Result, AdditionalParameters) Export
	
	If Result <> Undefined And Object.InformationForRegulatoryBodies <> Result Then
		Modified = True;
		Object.InformationForRegulatoryBodies = Result;
		InformationForRegulatoryBodies = LabelInformationForRegulatoryAuthorities(Object);
	EndIf;
	
EndProcedure

&AtClient
Procedure ExpenseReportPeriodOnChange(Item)
	
	Object.ExpenseReportDate =
		CashClient.RecalculateAdvanceReportDate(ExpenseReportPeriod, Object.Date);
	
	ConfigureDependentFormElements("ExpenseReportPeriodDate");
	
EndProcedure

&AtClient
Procedure ExpenseReportPeriodChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	Notification = New CallbackDescription("ExecuteAfterSelectingDate", ThisObject);
	
	CashClient.ExpenseReportPeriodChoiceProcessing(
		Item, ValueSelected, StandardProcessing, ThisForm, Object.Date, Notification);
	
	ExpenseReportPeriodDate = (TypeOf(ValueSelected) = Type("Date") Or ValueSelected = "TillDate");
	
EndProcedure

&AtClient
Procedure ExecuteAfterSelectingDate(SelectedDate, Var_Parameters) Export
	
	ExpenseReportPeriodDate = (TypeOf(ExpenseReportPeriod) = Type("Date"));
	ConfigureDependentFormElements();
	
EndProcedure

&AtClient
Procedure FiscalOperationStatusURLProcessing(Item, Var_URL, StandardProcessing)
	
	GeneratingFiscalChecksClient.FiscalOperationNavigationLinkProcessing(
		ThisObject, Var_URL, StandardProcessing);
	
EndProcedure

&AtClient
Procedure FiscalTransactionCompletion(Result, AdditionalParameters) Export
	
	FiscalOperationCompletionOnServer();
	
EndProcedure

&AtServer
Procedure FiscalOperationCompletionOnServer()
	
	GeneratingFiscalChecksServer.UpdateFiscalCheckBreakdownHyperlink(Object.Ref, ThisObject, FiscalOperationStatus);
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	AgreementWhenModifiedOnServer();
	
EndProcedure

&AtServer
Procedure AgreementWhenModifiedOnServer()
	
	CurrentRow = Object.ARAPDetails.FindByID(Items.ARAPDetails.CurrentRow);
	ClearCalculationObject(CurrentRow);
	
	If ValueIsFilled(Object.Contract) Then
		
		ContractDetails_ = Undefined;
		CashServer.FillInDataOfDocumentFormByContract(ThisObject, ContractDetails_);
		
		If CommonClientServer.HasAttributeOrObjectProperty(ContractDetails_, "FinancialAccountingGroup") Then
			Object.FinancialAccountingGroup = ContractDetails_.FinancialAccountingGroup;
		EndIf;

		If CommonClientServer.HasAttributeOrObjectProperty(ContractDetails_, "LineOfBusiness") Then
			Object.LineOfBusiness = CashServer.LineOfBusiness(
				Object.BusinessOperation, 
				ContractDetails_.LineOfBusiness);
		EndIf;

		FillInPaymentDecryptionLineUnderContract(CurrentRow, ContractDetails_);
		FillInCurrencyOfMutualSettlementsOfDocument();
		
	EndIf;
	
	CurrentARAPObject = CurrentRow.ARAPObject;
	CashServer.CheckFillInARAPObject(Object, Items.ARAPDetails.CurrentRow);
	CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object, , True);
	If CurrentARAPObject <> CurrentRow.ARAPObject Then
		FillInUIP(Items.ARAPDetails.CurrentRow);
	EndIf;
	ProcessIPChange();
	
	CompleteVATTaxation();
	
	SetRestrictionOnTypeOfPaymentDecryptionContract();
	GenerateHyperlinkCaptionPaymentObjectDetails();
	
	StructureOfActions = New Structure("RecalculateVATAmount", New Structure("PriceIncludesVAT", True));
	BatchProcessingOfTablePartServer.TreatTS(Object.ARAPDetails, StructureOfActions, Undefined);
	
	CashServer.CalculateAmountsInSenderSCurrencyInDecryption(Object, BankAccountCurrency);
	
EndProcedure

&AtClient
Procedure ReturnAgreementCreating(Item, StandardProcessing)

	StandardProcessing = False;
	
	CashClient.OpenCreationOfRefundContract(ThisObject, Item);

EndProcedure

&AtClient
Procedure ExpenseItemOnChange(Item)
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
EndProcedure

&AtClient
Procedure ExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure ExpenseItemStartListChoice(Item, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure DimensionOfExpensesOnChange(Item)
	IncomeAndExpensesClientServer.DimensionOfExpensesOnChange(ThisObject, Item);
EndProcedure

&AtClient
Procedure DimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure DimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure DimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(ThisObject, FormattedStringURL, StandardProcessing);			
EndProcedure

&AtClient
Procedure CurrencyDecorationAndPaymentRateClick(Item, StandardProcessing)
	
	Notification = New CallbackDescription("CurrencyDecorationAndPaymentRateClickCompletion", ThisObject);
	ARAPAccountingClient.CurrencyAndExchangeRateOfDocument(ThisForm, Item, StandardProcessing, Notification);
	
EndProcedure

&AtClient
Procedure CurrencyDecorationAndPaymentRateClickCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	CurrencyDecorationAndPaymentRateClickFinishOnServer();
	
EndProcedure

&AtServer
Procedure CurrencyDecorationAndPaymentRateClickFinishOnServer()
	
	FillMultiplicityCourseWithText();
	FillInCurrencyOfMutualSettlementsOfDocument();
	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	
	VATConversionParameters = New Structure("PriceIncludesVAT", True);
	StructureOfActions = New Structure("RecalculateVATAmount", VATConversionParameters);
	BatchProcessingOfTablePartServer.TreatTS(Object.ARAPDetails, StructureOfActions, Undefined);
	
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	
	CompleteVATTaxation();
	
EndProcedure

&AtClient
Procedure DecorationSparkriskieIndexesURLProcessing(Item, FormattedStringURL, StandardProcessing)

	
	Return;

EndProcedure

&AtClient
Procedure LabelFilesForTransferToTheBankClick(Item)
	
	Return;
	
EndProcedure

&AtClient
Procedure LabelPayerAttributesClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure PaymentDocumentTypeOnChange(Item)
	
	If Object.PaymentDocumentType = PredefinedValue("Enum.TypesOfPaymentDocuments.CollectionOrder_2")
		Or Object.PaymentDocumentType = PredefinedValue("Enum.TypesOfPaymentDocuments.PaymentWarrant")
		Or Object.PaymentDocumentType = PredefinedValue("Enum.TypesOfPaymentDocuments.BankPaymentOrder") Then
		
		Object.DoNotControlRequestFilling = True;
		EnabledCreatingCashIssueWithoutPaymentRequest = True;
		
		Object.ProcessedByBank = True;
		Object.BankPostingDate = Object.Date;
		
	Else
		
		Object.DoNotControlRequestFilling = False;
		EnabledCreatingCashIssueWithoutPaymentRequest = 
			(AllowPaymentsWithoutApplicationSpecificationBankAccount And UsePaymentRequests)
			Or Not UsePaymentRequests;
		SetPaymentByRequestAttribute();
		
	EndIf;
	
	ConfigureDependentFormElements("PaymentDocumentType, EnabledCreatingCashIssueWithoutPaymentRequest");
	
EndProcedure

&AtClient
Procedure PaymentIDOnChange(Item)
	
	PaymentIdOnChangeAtServer();
	
EndProcedure

&AtClient
Procedure PaymentKindStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure PaymentsAsPer275FZOnChange(Item)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure PaysheetPersonalIncomeTaxOnChange(Item)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure TaxTypeOnChange(Item)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure TextDetailsOfPaymentToBudgetClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure TransferOfTaxesAndContributionsOnChange(Item)
	
	Return;
	
EndProcedure

&AtClient
Procedure KeyOfTransactionWithForeignCurrencyOnChange(Item)
	
	Return;
	
EndProcedure

&AtClient
Procedure TransferToEmployeeViaABankOnChange(Item)
	
	TransferToEmployeeViaABankOnChange_Server();
	
EndProcedure

&AtClient
Procedure PersonsListOnChange(Item)
	
	Object.PersonsList = (PersonsList = 1);
	
	If Object.PersonsList Then
		ListOfPersonsChangedOnServer();
	Else
		Object.PersonalAccountsOfStaff.Clear();
	EndIf;
	
	ConfigureDependentFormElements("PersonsList");

EndProcedure

&AtClient
Procedure DetailsOfContractWithBankWhenChanging(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	Return;
	
EndProcedure

&AtClient
Procedure ListOfCounterparties_OnChange(Item)

	Return;

EndProcedure

&AtClient
Procedure ConversionRateMultiplierOnChange(Item)

	MultiplicityOfConversionRateWhenChangingOnServer();

EndProcedure

&AtClient
Procedure LineOfBusinessOnChange(Item)

	DirectionOfActivityWhenChangingOnServer();

EndProcedure

&AtClient
Procedure FinancialAccountingGroupOnChange(Item)

	FinancialAccountingGroupOnChangeAtServer();

EndProcedure

&AtClient
Procedure DecryptionWithoutPartitioningPartnerOnChange(Item)

	ARAPDetailsPartnerOnChangeAtServer();

EndProcedure

&AtClient
Procedure KeepRecordsOfCommissionInMutualSettlementsSwitchOnChange(Item)
	
	KeepRecordsOfCommissionInMutualSettlementsSwitchOnChangesAtServer();
	
EndProcedure

&AtClient
Procedure CommissionAgreementStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("DeletionMark", False);
	FilterStructure1.Insert("Organization", Object.Organization);
	FilterStructure1.Insert("Counterparty", Object.Counterparty);
	FilterStructure1.Insert("ARAPCurrency", Object.Currency);
	FilterStructure1.Insert("ARAPObjectSettings", PredefinedValue("Enum.ARAPObjectSettings.ByCounterpartyContracts"));
	
	StructureOfSelectionParameters = New Structure;
	StructureOfSelectionParameters.Insert("ChoiceMode", True);
	StructureOfSelectionParameters.Insert("ContractTypes", ARAPAccountingClientServer.TypesOfContractsWithSupplier());
	StructureOfSelectionParameters.Insert("Filter",FilterStructure1);
	
	OpenForm("Catalog.CounterpartyContracts.Form.ChoiceForm", StructureOfSelectionParameters, Item, Item);
	
EndProcedure

&AtClient
Procedure CommissionAgreementOnChange(Item)
	
	ContractFeesOnChangesATServer();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersARAPDetails

&AtClient
Procedure DecryptionSwitchOnChange(Item)
	
	If Not DecryptionSwitch Then
		If Object.ARAPDetails.Count() = 0 Then
			NewRow = Object.ARAPDetails.Add();
			Items.ARAPDetails.CurrentRow = NewRow.GetID();
			ARAPDetailsOnStartEdit(Items.ARAPDetails, True, False);
		ElsIf Object.ARAPDetails.Count() = 1 Then
			If Items.ARAPDetails.CurrentRow = Undefined Then
				Items.ARAPDetails.CurrentRow = Object.ARAPDetails[0].GetID();
			EndIf;
		ElsIf Object.ARAPDetails.Count() > 1 Then
			ClearMessages();
			MessageText = NStr("vi = 'Chuyển sang chế độ không phân chia là không thể nếu có nhiều hơn một dòng được nhập vào giải mã thanh toán!';
								|ru = 'Переключение в режим без разбиения невозможно, если в расшифровке платежа введено более одной строки!';
								|en = 'Cannot switch to no-split mode if multiple lines are entered into the payment details.'; fa = 'Cannot switch to no-split mode if multiple lines are entered into the payment details.';
								|it = 'Passare alla modalità senza la partizione è impossibile se nella decifrazione del pagamento viene inserita più di una riga!';
								|pl = 'Przełączenie do trybu bez podziału jest niemożliwe, jeśli w szczegółach płatności wprowadzono więcej niż jeden wiersz!';
								|tr = 'Ödeme detayında birden fazla satır girilmişse ayrıştırılmış moda geçmek mümkün değildir!'");
			CommonClient.MessageToUser(MessageText);
			DecryptionSwitch = 1;
		EndIf;
	EndIf;
	
	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure ARAPDetailsSelection(Item, RowSelected, Field, StandardProcessing)
	If Field.Name = "ARAPDetailsPresentationOfRecordingInComplAccounting" Then
		GLAccountSettingsClient.OnClick(ThisObject, Field, StandardProcessing);
	EndIf;
	Return;
	
EndProcedure

&AtClient
Procedure DecodingWithoutSplittingRepresentationOfReflectionInReglAccountingClick(Item, StandardProcessing)
	CallbackOnCompletion = New CallbackDescription("ReflectionsInLocalAccountingWhenChangesOccur", ThisObject);
	GLAccountSettingsClient.OnClick(ThisObject, Item, StandardProcessing, CallbackOnCompletion);
	Return;
	
EndProcedure

&AtClient
Procedure ARAPDetailsOnStartEdit(Item, NewRow, Copy)
	
	TableRow = Items.ARAPDetails.CurrentData;
	
	If Object.ListOfCounterparties_ Then
		Partner = TableRow.Partner;
	EndIf;
	
	If Not ValueIsFilled(Partner)
		And Not Object.ListOfCounterparties_ Then
		GetDefaultServerPartner(Object.Counterparty, Partner, Object.BusinessOperation);
	EndIf;
	
	FinancesClient.ARAPDetailsOnStartEdit(
		Object, Partner, CounterpartyContract, TableRow, NewRow, Copy, CashFlowItem);
		
	If NewRow Then
		If Not Copy Then
			
			TableRow.ARAPCurrency = Object.Currency;
			TableRow.ExchangeRateNumeratorOfMutualSettlements = 1;
			TableRow.TheExchangeRateIsTheDenominatorOfMutualSettlements = 1;
			
			If Not Object.ListOfCounterparties_ Then
				TableRow.Counterparty = Object.Counterparty;
			EndIf;
			If Not ValueIsFilled(TableRow.CashFlowItem) Then
				TableRow.CashFlowItem = Object.CashFlowItem;
			EndIf;
			
			IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, TableRow, "Object.ARAPDetails");
		EndIf;
		CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
			TableRow, Object.Currency, CurrencyOfComplianceAccounting);
		UpdateTaxRateRecalculateVATAmount(TableRow.GetID());
	EndIf;
	
	OnChangePaymentDecryptionAmount();
	
	//Setting up accounting accounts 
	If NewRow And Copy Then
		GLAccountSettingsClient.WhenCopyingString(ThisObject, Item);
	EndIf;
EndProcedure

&AtClient
Procedure ARAPDetailsOnEditEnd(Item, NewRow, CancelEdit)
	
	DecryptionOfPaymentAtEndOfEditingOnServer();
	
EndProcedure

&AtServer
Procedure DecryptionOfPaymentAtEndOfEditingOnServer()
	
	CashServer.FillInCurrencyOfMutualSettlementsOfDocument(ThisObject);
	CurrencyDecorationAndPaymentRate = CashServer.CurrencyLabelAndPaymentRate(ThisObject);
	
EndProcedure

&AtClient
Procedure ARAPDetailsPaymentRequestOnChange(Item)
	
	DecryptionOfPaymentRequestForChangeServer(Items.ARAPDetails.CurrentData.PaymentRequest);
	
EndProcedure

&AtServer
Procedure DecryptionOfPaymentRequestForChangeServer(ApplicationLink)
	
	If TypeOf(ApplicationLink) = Type("DocumentRef.PaymentRequest") Then
		
		AttributesOfApplication = Common.ObjectAttributesValues(ApplicationLink, "Counterparty, PaymentID");
		BidCounterparty = AttributesOfApplication.Counterparty;
	
		If Not ValueIsFilled(Object.Counterparty) Then
			Object.Counterparty = BidCounterparty;
		ElsIf ValueIsFilled(BidCounterparty) And Object.Counterparty <> BidCounterparty Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Người nhận tiền ""%1"" trong chứng từ thanh toán không trùng với người nhận ""%2"" trong giấy đề nghị!';
					|ru = 'Получатель платежа ""%1"" в документе оплаты не соответствует получателю ""%2"" в заявке!';
					|en = 'Payee ""%1"" in the AR/AP transaction does not match the payee ""%2"" in the request!'; fa = 'Payee ""%1"" in the AR/AP transaction does not match the payee ""%2"" in the request!';
					|it = 'Il destinatario del pagamento ""%1"" nel documento di pagamento non corrisponde al destinatario ""%2"" nella richiesta!';
					|pl = 'Odbiorca płatności ""%1"" w dokumencie płatności nie odpowiada odbiorcy ""%2"" we wniosku!';
					|tr = 'Ödeme belgesindeki ""%1"" alacaklı, başvurudaki ""%2"" alacaklıyla eşleşmiyor!'"),
				Object.Counterparty,
				BidCounterparty);
			CommonClientServer.MessageToUser(ErrorText);
		EndIf;
		
		If IsBlankString(Object.PaymentID) Then
			Object.PaymentID = AttributesOfApplication.PaymentID;
		EndIf;
		
	EndIf;
	
	DecryptionString = Object.ARAPDetails.FindByID(Items.ARAPDetails.CurrentRow);
	
	If DecryptionString <> Undefined
		And Object.PersonsList Then
		DecryptionString.Sum = AmountOfBalanceOfApplication(ApplicationLink);
	EndIf;
	
	UpdateInformationOnApplications();
	
EndProcedure

&AtClient
Procedure DecryptionWithoutSplittingTheCalculationObjectOnChange(Item)
	
	TableRow = Items.ARAPDetails.CurrentData;
	DecryptionWithoutSplittingTheCalculationObjectOnChangeServer(TableRow.GetID());
	If Not ValueIsFilled(TableRow.ARAPObject) Then
		TableRow.MaturityDate = Date(1, 1, 1);
	EndIf;
	UpdatePresentationOfMaturityDate();
	
EndProcedure

&AtServer
Procedure DecryptionWithoutSplittingTheCalculationObjectOnChangeServer(LineID)
	
	CashServer.CheckFillOutContract(Object, LineID);
	CashServer.UpdateSettlementCurrencyOfPaymentDecryption(
		"Document.BankAccountIssue", Object, CurrencyOfComplianceAccounting);
	FillInCurrencyOfMutualSettlementsOfDocument();
	FillMultiplicityCourseWithText();
	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	
	CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(
		Object, Items.ARAPDetails.CurrentRow, True);
	FillInUIP(Items.ARAPDetails.CurrentRow);
	ProcessIPChange();
	UpdateTaxRateRecalculateVATAmount(LineID);
	SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning();
	SetRestrictionOnTypeOfPaymentDecryptionContract();
	ARAPAccountingFormWork.BlockSettlementObjects(ThisObject);
	
EndProcedure

&AtClient
Procedure ARAPDetailsARAPObjectStartChoice(Item, ChoiceData, StandardProcessing)
	
	ARAPObject = Undefined;
	CurrentData = Items.ARAPDetails.CurrentData;
	If CurrentData <> Undefined Then
		ARAPObject = CurrentData.ARAPObject;
	EndIf;
	
	AdditionalSelection = Undefined;
	
	
	ARAPAccountingClient.ARAPObjectStartChoice(
		ThisObject, Item, StandardProcessing,, ARAPObject, AdditionalSelection);
	
EndProcedure

&AtClient
Procedure DecryptionWithoutSplittingTheCalculationObjectAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	ARAPAccountingClient.ObjectOfCalculationsBasisOfPaymentAutoSelection(ThisForm, Items.ARAPDetails, Text, ChoiceData, StandardProcessing, False, True);
	
EndProcedure

&AtClient
Procedure ARAPDetailsARAPObjectAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	ARAPAccountingClient.ObjectOfCalculationsBasisOfPaymentAutoSelection(ThisForm, Items.ARAPDetails, Text, ChoiceData, StandardProcessing, False, True);
	
EndProcedure

&AtClient
Procedure DecryptionWithoutSplittingTheCalculationObjectTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	ARAPAccountingClient.ObjectOfCalculationsBasisOfPaymentAutoSelection(ThisForm, Items.ARAPDetails, Text, ChoiceData, StandardProcessing, False, True);
	
EndProcedure

&AtClient
Procedure ARAPDetailsARAPObjectTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	ARAPAccountingClient.ObjectOfCalculationsBasisOfPaymentAutoSelection(ThisForm, Items.ARAPDetails, Text, ChoiceData, StandardProcessing, False, True);
	
EndProcedure

&AtClient
Procedure ARAPDetailsARAPObjectChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	If TypeOf(ValueSelected) = Type("Structure") Then
		PaymentDecryptionSettlementObjectSelectionProcessingOnServer(ValueSelected);
	EndIf;
	
	UpdatePresentationOfMaturityDate();
	
EndProcedure

&AtServer
Procedure PaymentDecryptionSettlementObjectSelectionProcessingOnServer(ValueSelected)
	
	RowID = Items.ARAPDetails.CurrentRow;
	TableRow = Object.ARAPDetails.FindByID(RowID);
	
	AddSelectedValue(ValueSelected);
	
	PropertiesToExclude = "";
	If ValueSelected.Property("CashFlowItem")
		And Not ValueIsFilled(ValueSelected.CashFlowItem) Then
		PropertiesToExclude = "CashFlowItem";
	EndIf;
	FillPropertyValues(TableRow, ValueSelected,, PropertiesToExclude);
	
	Modified = True;
	ARAPAccountingFormWork.BlockSettlementObjects(ThisForm);
	
	FillInUIP(RowID);
	DecryptionOfTheCalculationObjectWhenChangingServer(TableRow.GetID());
	
	UpdateAmountUnallocated();
	GenerateHyperlinkCaptionPaymentObjectDetails();
	SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning();
	
	FillInCourseAndMultiplicityInDecryptionLine(TableRow);
	CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
		TableRow, Object.Currency, CurrencyOfComplianceAccounting);
	CashServer.FormCourseDenominatorByText(TableRow, Object.Currency, CurrencyOfComplianceAccounting);
	FillInCurrencyOfMutualSettlementsOfDocument();
	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	
	CashServer.CalculateAmountsInSenderSCurrencyInDecryption(Object, BankAccountCurrency);
	

	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtServer
Procedure AddSelectedValue(ValueSelected)
	
	ValueSelected.Insert("CashFlowItem",
		CashServer.ArticleOfCashFlowOfSettlementObject(ValueSelected.ARAPObject, Object.BusinessOperation));
	
	
	ARAPObjects = New Array;
	ARAPObjects.Add(ValueSelected.ARAPObject);
	
	VATTable = CashServer.TranscriptOfVATPayment(Object.Organization, Undefined, Undefined, ARAPObjects, ValueSelected.TheseAreSettlementsWithCustomers);
	If VATTable.Count() = 1 Then
		ValueSelected.Insert("VATRate", VATTable[0].VATRate);
		If ValueSelected.PaymentAmount = ValueSelected.OrderAmount Then
			ValueSelected.Insert("VATAmount", VATTable[0].VATAmount);
		EndIf;
	EndIf;
	
	If ValueIsFilled(ValueSelected.ARAPCurrency) Then
		CurrencyExchangeRate = ProcessingOfExchangeRatesTM.GetCurrencyRate(ValueSelected.ARAPCurrency, Undefined,
						SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization));
		ValueSelected.Insert("ExchangeRateNumeratorOfMutualSettlements", CurrencyExchangeRate.CourseNumerator);
		ValueSelected.Insert("TheExchangeRateIsTheDenominatorOfMutualSettlements", CurrencyExchangeRate.CourseDenominator);
	EndIf;
	
EndProcedure

&AtClient
Procedure ARAPDetailsSumOnChange(Item)
	
	TableRow = Items.ARAPDetails.CurrentData;
	
	CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
		TableRow, Object.Currency, CurrencyOfComplianceAccounting);
	
	DecryptionOfPaymentAmountWhenChangedOnServer();
	
EndProcedure

&AtServer
Procedure DecryptionOfPaymentAmountWhenChangedOnServer()
	
	TableRow = Object.ARAPDetails.FindByID(Items.ARAPDetails.CurrentRow);
	
	StructureOfRecalculationOfAmount = New Structure;
	StructureOfRecalculationOfAmount.Insert("PriceIncludesVAT", True);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartServer.ProcessTSString(TableRow, StructureOfActions, Undefined);
	
	CashServer.CalculateAmountsInSenderSCurrencyInDecryption(Object, BankAccountCurrency);
	
	OnChangePaymentDecryptionAmount();
	
EndProcedure

&AtClient
Procedure ARAPDetailsAmountARAPOnChange(Item)
	
	TableRow = Items.ARAPDetails.CurrentData;
	If ValueIsFilled(TableRow.AmountARAP)
		And TableRow.ARAPCurrency = Object.Currency
		And TableRow.AmountARAP <> TableRow.Sum Then
		TableRow.AmountARAP = TableRow.Sum;
	Else
		DecryptionOfPaymentAmountOfSettlementsWhenChangingOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure DecryptionOfPaymentAmountOfSettlementsWhenChangingOnServer()
	
	CurrentRow = Object.ARAPDetails.FindByID(Items.ARAPDetails.CurrentRow);
	
	If CurrentRow.Sum = 0 Then
		CashClientServer.CalculateAmountInDecryptionLine(CurrentRow, Object.Currency, CurrencyOfComplianceAccounting);
	Else
		CashServer.CalculateExchangeRateNumeratorOfMutualSettlementsInDecryptionLine(
			CurrentRow, Object.Currency, CurrencyOfComplianceAccounting);
		CashServer.FormCourseDenominatorByText(CurrentRow, Object.Currency, CurrencyOfComplianceAccounting);
	EndIf;
	
	CashServer.CalculateAmountsInSenderSCurrencyInDecryption(Object, BankAccountCurrency);
	
	FillInCurrencyOfMutualSettlementsOfDocument();
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtClient
Procedure ARAPDetailsARAPCurrencyOnChange(Item)
	
	DecryptionOfPaymentCurrencyOfSettlementsWhenChangedOnServer();
	
EndProcedure

&AtServer
Procedure DecryptionOfPaymentCurrencyOfSettlementsWhenChangedOnServer()
	
	CurrentRow = Object.ARAPDetails.FindByID(Items.ARAPDetails.CurrentRow);
	
	ArrayOfOperationDetails = New Array;
	Documents.BankAccountIssue.FillInNamesOfBusinessTransactionDetails(
		Object, Undefined, ArrayOfOperationDetails);
	
	If CurrentRow.ARAPCurrency <> ARAPCurrency
		And ArrayOfOperationDetails.Find("Contract") <> Undefined Then
		Object.Contract = Undefined;
		CashServer.SetContractSelectionParameters(ThisObject, Items.Contract);
	EndIf;
	
	ClearCalculationObject(CurrentRow);
	FillInCourseAndMultiplicityInDecryptionLine(CurrentRow);
	CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
		CurrentRow, Object.Currency, CurrencyOfComplianceAccounting);
	CashServer.FormCourseDenominatorByText(CurrentRow, Object.Currency, CurrencyOfComplianceAccounting);
	FillInCurrencyOfMutualSettlementsOfDocument();
	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtClient
Procedure ARAPDetailsExchangeRateNumeratorOfMutualSettlementsOnChange(Item)
	
	DecryptionOfPaymentExchangeRateNumeratorOfSettlementsWhenChangedOnServer();
	
EndProcedure

&AtServer
Procedure DecryptionOfPaymentExchangeRateNumeratorOfSettlementsWhenChangedOnServer()
	
	CurrentRow = Object.ARAPDetails.FindByID(Items.ARAPDetails.CurrentRow);
	
	CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
		CurrentRow, Object.Currency, CurrencyOfComplianceAccounting);
	CashServer.FormCourseDenominatorByText(CurrentRow, Object.Currency, CurrencyOfComplianceAccounting);
	FillInCurrencyOfMutualSettlementsOfDocument();
	
EndProcedure

&AtServer
Procedure FillInCourseAndMultiplicityInDecryptionLine(TSRow)
	
	DateOfCourse = ?(ValueIsFilled(Object.BankPostingDate), Object.BankPostingDate, Object.Date);
	CashServer.FillInCourseOfMutualSettlementsOfDecryptionLine(Object, CurrencyOfComplianceAccounting, DateOfCourse, TSRow);
	
EndProcedure

&AtClient
Procedure ARAPDetailsLoanDepositContractOnChange(Item)
	
	ARAPDetailsLoanDepositContractOnChangeServer();
	
EndProcedure

&AtServer
Procedure ARAPDetailsLoanDepositContractOnChangeServer()
	
	CurrentRow = Object.ARAPDetails.FindByID(Items.ARAPDetails.CurrentRow);
	
	ContractDetails_ = Common.ObjectAttributesValues(CurrentRow.LoanDepositContract,
		"ARAPCurrency, ContractKind, CashFlowItemOfPrincipalDebt, CashFlowItemOfReceiptIssuie");
	
	CurrentRow.ARAPCurrency = ContractDetails_.ARAPCurrency;
	If ContractDetails_.ContractKind = Enums.ContractKindsOfFinancialInstruments.LoanOrBorrowing Then
		
		If ValueIsFilled(CurrentRow.LoanAndDepositAmountType) Then
			CurrentRow.CashFlowItem =
				CashServer.ArticleOfDepositLoanContractByTypeOfDepositLoanAmount(
					CurrentRow.LoanDepositContract,
					CurrentRow.LoanAndDepositAmountType,
					Object.CashFlowItem);
		Else
			CurrentRow.CashFlowItem = ContractDetails_.CashFlowItemOfPrincipalDebt;
		EndIf;
		
	Else
		CurrentRow.CashFlowItem = ContractDetails_.CashFlowItemOfReceiptIssuie;
	EndIf;
	
	FillInCourseAndMultiplicityInDecryptionLine(CurrentRow);
	CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
		CurrentRow, Object.Currency, CurrencyOfComplianceAccounting);
	CashServer.FormCourseDenominatorByText(CurrentRow, Object.Currency, CurrencyOfComplianceAccounting);
	FillInCurrencyOfMutualSettlementsOfDocument();
	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	
	ConfigureDependentFormElementsOnServer();
	
	SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning();
	SetRestrictionOnTypeOfPaymentDecryptionContract();
	
EndProcedure

&AtClient
Procedure ARAPDetailsLoanAndDepositAmountTypeOnChange(Item)
	
	TypeOfDepositCreditAmountWhenServerChanges();
	
EndProcedure

&AtServer
Procedure TypeOfDepositCreditAmountWhenServerChanges()
	
	CurrentRow = Object.ARAPDetails.FindByID(Items.ARAPDetails.CurrentRow);
	
	CurrentRow.CashFlowItem =
		CashServer.ArticleOfDepositLoanContractByTypeOfDepositLoanAmount(
			CurrentRow.LoanDepositContract,
			CurrentRow.LoanAndDepositAmountType,
			Object.CashFlowItem);
	
EndProcedure

&AtClient
Procedure ARAPDetailsExpenseItemOnChange(Item)
	
	ARAPDetailsExpenseItemOnChangeServer(Item.Name);
	
EndProcedure

&AtServer
Procedure ARAPDetailsExpenseItemOnChangeServer(TagName);
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items[TagName]);
	
EndProcedure

&AtClient
Procedure ARAPDetailsExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ARAPDetailsDimensionOfExpensesOnChange(Item)
	
	IncomeAndExpensesClientServer.DimensionOfExpensesOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure ARAPDetailsDimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ARAPDetailsDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ARAPDetailsDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ARAPDetailsAssetsLiabilitiesDimensionOnChange(Item)
	IncomeAndExpensesClientServer.AssetsLiabilitiesDimensionOnChange(ThisObject, Item);
EndProcedure

&AtClient
Procedure HyperlinkPaymentObjectDetailsClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	BlockData_();
	
	CallbackDescription = New CallbackDescription("HyperlinkPaymentObjectDetailsClickCompletion", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("BusinessOperation", Object.BusinessOperation);
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.CashPaymentToAnotherCompany")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RefundToAnotherCompany") Then
		FormParameters.Insert("Counterparty",            CompanyRecipient);
	Else
		FormParameters.Insert("Counterparty",            Object.Counterparty);
	EndIf;
	
	FormParameters.Insert("FinancialAccountingGroup",    Object.FinancialAccountingGroup);
	FormParameters.Insert("LineOfBusiness",   Object.LineOfBusiness);
	FormParameters.Insert("Contract",                   Object.Contract);
	FormParameters.Insert("Organization",               Object.Organization);
	FormParameters.Insert("Department",             Object.Department);
	FormParameters.Insert("VATTaxation",      Object.VATTaxation);
	FormParameters.Insert("ListOfVATTaxes",Items.DecodingWithoutSplittingVATTaxation.ChoiceList);
	FormParameters.Insert("DocumentRef",            Object.Ref);
	FormParameters.Insert("AddressInTempStorage", PlaceDecryptionInTemporaryStorage());
	
	OpenForm("CommonForm.FormForSelectionOfPaymentARAPObjectDetails",
		FormParameters,
		ThisForm,,,,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure HyperlinkPaymentObjectDetailsClickCompletion(Result, AdditionalParameters) Export
	
	UnlockData();
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Modified = Modified Or Result.Modified;
	
	Object.FinancialAccountingGroup  = Result.FinancialAccountingGroup;
	Object.LineOfBusiness = Result.LineOfBusiness;
	Object.Contract                 = Result.Contract;
	Object.Department           = Result.Department;
	HyperlinkDetailsOfSettlementObjectClickEndOnServer();
		
	ThereIsChangeInVATTaxation = ?(Object.VATTaxation = Result.VATTaxation, False, True);
	
	If ThereIsChangeInVATTaxation Then
		Object.VATTaxation = Result.VATTaxation;
		CompleteVATTaxation();
	EndIf;
	
EndProcedure

&AtServer
Procedure HyperlinkDetailsOfSettlementObjectClickEndOnServer()

	ModifiedRows = CashServer.CheckFillInARAPObject(Object);
	
	For Each IndexOf In ModifiedRows Do
		DecryptionString = Object.ARAPDetails[IndexOf]; 
		FillInUIP(DecryptionString.GetID());
		ARAPDetailsARAPObjectOnChangeServer(DecryptionString.GetID());
		FillInCourseAndMultiplicityInDecryptionLine(DecryptionString);
		CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
			DecryptionString, Object.Currency, CurrencyOfComplianceAccounting);
		CashServer.FormCourseDenominatorByText(DecryptionString, Object.Currency, CurrencyOfComplianceAccounting);
		YouAreAllowedToWorkWithAffiliatedPartners(DecryptionString);
	EndDo;
	
	If ValueIsFilled(Object.Contract) Then
		
		ContractDetails_ = Undefined;
		CashServer.FillInDataOfDocumentFormByContract(ThisObject, ContractDetails_);
		
		For Each DecryptionString In Object.ARAPDetails Do
			
			If (Not ValueIsFilled(DecryptionString.ARAPObject)
				Or DecryptionString.CalculationObject = Object.Ref) Then
				FillInPaymentDecryptionLineUnderContract(DecryptionString, ContractDetails_);
			EndIf;
			
		EndDo;
		
		FillInCurrencyOfMutualSettlementsOfDocument();
		
		StructureOfActions = New Structure("RecalculateVATAmount", New Structure("PriceIncludesVAT", True));
		BatchProcessingOfTablePartServer.TreatTS(Object.ARAPDetails, StructureOfActions, Undefined);
		
	Else
		CashServer.ClearPaymentDecryptionContract(Object);
	EndIf;
	
	UpdateAmountUnallocated();
	GenerateHyperlinkCaptionPaymentObjectDetails();

EndProcedure

&AtClient
Procedure SettlementObjectContractStartOfSelection(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("Organization", Object.Organization);
	FilterStructure1.Insert("DeletionMark", False);
	
	If ValueIsFilled(Items.ARAPDetails.CurrentData.ARAPCurrency) Then
		FilterStructure1.Insert("ARAPCurrency", Items.ARAPDetails.CurrentData.ARAPCurrency);
	EndIf;
	
	StructureOfSelectionParameters = New Structure;
	StructureOfSelectionParameters.Insert("ChoiceMode", True);
	StructureOfSelectionParameters.Insert("AllowSelectionOfBranchContracts", True);
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.CashPaymentToAnotherCompany") 
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RefundToAnotherCompany") Then
		
		If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.CashPaymentToAnotherCompany") Then
			FilterStructure1.Organization = CompanyRecipient;
			FilterStructure1.Insert("CompanyRecipient", Object.Organization);
		Else
			FilterStructure1.Insert("CompanyRecipient", CompanyRecipient);
		EndIf;
		
		StructureOfSelectionParameters.Insert("Filter",FilterStructure1);
		OpenForm("Catalog.IntercompanyContracts.Form.ChoiceForm",
			StructureOfSelectionParameters,
			Item,
			Item,)
	Else
		
		If Object.ListOfCounterparties_ Then
			FilterStructure1.Insert("Counterparty", Items.ARAPDetails.CurrentData.Counterparty);
		Else
			FilterStructure1.Insert("Counterparty", Object.Counterparty);
		EndIf;
		
		If FinancesClient.TheseAreSettlementsWithCustomers(Object.BusinessOperation) Then
			StructureOfSelectionParameters.Insert("ContractTypes", ARAPAccountingClientServer.TypesOfContractsWithClient());
		Else
			StructureOfSelectionParameters.Insert("ContractTypes", ARAPAccountingClientServer.TypesOfContractsWithSupplier());
		EndIf;
		
		
		StructureOfSelectionParameters.Insert("Filter",FilterStructure1);
			OpenForm("Catalog.CounterpartyContracts.Form.ChoiceForm",
			StructureOfSelectionParameters,
			Item,
			Item,)
	EndIf;
	
EndProcedure

&AtClient
Procedure ARAPDetailsAfterDeleteRow(Item)
	
	ARAPDetailsAfterDeleteRowServer();
	
EndProcedure

&AtServer
Procedure ARAPDetailsAfterDeleteRowServer()
	
	UpdateAmountUnallocated();
	GenerateHyperlinkCaptionPaymentObjectDetails();
	UpdateInformationOnApplications();
	FillInCurrencyOfMutualSettlementsOfDocument();
	DefineUIPIsDifferent();
	ARAPAccountingFormWork.BlockSettlementObjects(ThisForm);
	
EndProcedure

&AtClient
Procedure ARAPDetailsARAPObjectOnChange(Item)
	
	TableRow = Items.ARAPDetails.CurrentData;
	ARAPDetailsARAPObjectOnChangeServer(TableRow.GetID());
	
EndProcedure

&AtServer
Procedure ARAPDetailsARAPObjectOnChangeServer(LineID)
	
	TableRow = Object.ARAPDetails.FindByID(LineID);
	CashServer.UpdateSettlementCurrencyOfPaymentDecryption(
		"Document.BankAccountIssue", Object, CurrencyOfComplianceAccounting);
	CashServer.FormCourseDenominatorByText(TableRow, Object.Currency, CurrencyOfComplianceAccounting);
	FillInCurrencyOfMutualSettlementsOfDocument();	
	FillInUIP(LineID);
	DecryptionOfTheCalculationObjectWhenChangingServer(LineID);
	
EndProcedure

&AtClient
Procedure ARAPDetailsVATRateOnChange(Item)
	
	CurrentRow = Items.ARAPDetails.CurrentData;
	
	StructureOfRecalculationOfAmount = New Structure;
	StructureOfRecalculationOfAmount.Insert("PriceIncludesVAT", True);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	Items.DecryptionWithoutSplittingTheVATAmount.ReadOnly =
		CashClientServer.ThisIsZeroVATRATE(CurrentRow.VATRate);
	
EndProcedure

&AtServer
Procedure DecryptionOfTheCalculationObjectWhenChangingServer(LineID)
	
	UpdateTaxRateRecalculateVATAmount(LineID);
	SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning();
	ARAPAccountingFormWork.BlockSettlementObjects(ThisForm);
		
	TableRow = Object.ARAPDetails.FindByID(LineID);
	YouAreAllowedToWorkWithAffiliatedPartners(TableRow);
	
	CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object, LineID, True);
	
	CashServer.CheckFillOutContract(Object, LineID);
	
	SetRestrictionOnTypeOfPaymentDecryptionContract();
	GenerateHyperlinkCaptionPaymentObjectDetails();
	ProcessIPChange(TableRow);
	
EndProcedure

&AtClient
Procedure TranscriptOfThePaymentTaxationOfPersonalIncomeTaxChanges(Item)
	
	CompleteVATTaxation();
	
EndProcedure

&AtClient
Procedure ARAPDetailsLeaseContractsOnChange(Item)
	RowID = Items.ARAPDetails.CurrentRow;
	
	FillInAttributesOfPaymentUnderLeaseContract(RowID);
	
	StructureOfRecalculationOfAmount = New Structure;
	StructureOfRecalculationOfAmount.Insert("PriceIncludesVAT", True);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	TableRow = Object.ARAPDetails.FindByID(RowID);
	BatchProcessingOfTablePartClient.ProcessTSString(TableRow, StructureOfActions, CachedValues);
	Return;
	
EndProcedure

&AtServer
Procedure ARAPDetailsLeaseContractsOnChangeServer(RowID = Undefined)
	
	If RowID = Undefined Then
		RowID = Items.ARAPDetails.CurrentRow;
	EndIf;
	
	CurrentRow = Object.ARAPDetails.FindByID(RowID);
	
	CurrentRow.TypeOfLeasePayment = Enums.TypesOfLeasePayments.RentalService;
	
	Items.DecryptionWithoutSplittingTheTypeOfRentPayment.ChoiceParameters = New FixedArray(New Array);
	TMCommonUseClientServer.AddSelectionParameter(
		Items.DecryptionWithoutSplittingTheTypeOfRentPayment, "Contract", CurrentRow.LeaseContracts);
	TMCommonUseClientServer.AddSelectionParameter(Items.DecryptionWithoutSplittingTheTypeOfRentPayment, "Payment_", True);
	
	Items.ARAPDetailsTypeOfLeasePayment.ChoiceParameters = New FixedArray(New Array);
	TMCommonUseClientServer.AddSelectionParameter(
		Items.DecryptionWithoutSplittingTheTypeOfRentPayment, "Contract", CurrentRow.LeaseContracts);
	TMCommonUseClientServer.AddSelectionParameter(Items.ARAPDetailsTypeOfLeasePayment, "Payment_", True);
	
	FillInCourseAndMultiplicityInDecryptionLine(CurrentRow);
	CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
		CurrentRow, Object.Currency, CurrencyOfComplianceAccounting);
	CashServer.FormCourseDenominatorByText(CurrentRow, Object.Currency, CurrencyOfComplianceAccounting);
	FillInCurrencyOfMutualSettlementsOfDocument();
	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	
	ConfigureDependentFormElementsOnServer();
	
	SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning();
	SetRestrictionOnTypeOfPaymentDecryptionContract();
	
EndProcedure
&AtClient
Procedure TranscriptTypeOfRentalPaymentStartOfSelection(Item, ChoiceData, StandardProcessing)
	CurrentData = Items.ARAPDetails.CurrentData;
	
	PaymentTypeSelectionParameters = New Array;
	PaymentTypeSelectionParameters.Add(New ChoiceParameter("Filter.Contract", CurrentData.LeaseContracts));
	PaymentTypeSelectionParameters.Add(New ChoiceParameter("Filter.Payment_", True));
	Items.ARAPDetailsTypeOfLeasePayment.ChoiceParameters = New FixedArray(PaymentTypeSelectionParameters);
	Items.DecryptionWithoutSplittingTheTypeOfRentPayment.ChoiceParameters = New FixedArray(PaymentTypeSelectionParameters);
	Return;
	
EndProcedure

&AtClient
Procedure ARAPDetailsStatementStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not PayrollAndHumanResourcesWE Then
	Else
		//++ WE
		If ValueIsFilled(Object.AdvanceHolder) And ValueIsFilled(Object.BankAccount) Then
			ParametersStructure = New Structure;
			ParametersStructure.Insert("ChoiceMode", True);
			ParametersStructure.Insert("MultipleChoice", False);
			ParametersStructure.Insert("CloseOnChoice", True);
			FilterStructure1 = New Structure;
			FilterStructure1.Insert("Organization", Object.Organization);
			If ValueIsFilled(Object.Department) Then
				FilterStructure1.Insert("Department", Object.Department);
			EndIf;
			FilterStructure1.Insert("PaymentMethodHR", PredefinedValue(
			"Enum.PaymentMethodsHR.EmployeeSBankAccount"));
			ParametersStructure.Insert("Filter", FilterStructure1);
			OpenForm("Document.PayrollStatementHR.ChoiceForm", ParametersStructure, ThisObject);
		Else
			ErrorText = NStr("vi = 'Trong phần đầu, hãy chọn nhân viên và tài khoản ngân hàng.';
							|ru = 'В начале выберите сотрудника и банковский счет.';
							|en = 'First, select an employee and a bank account.'; fa = 'First, select an employee and a bank account.';
							|it = 'First, select an employee and a bank account.';
							|pl = 'First, select an employee and a bank account.';
							|tr = 'Öncelikle çalışanı ve banka hesabını seçin.'");
			CommonClient.MessageToUser(ErrorText, Object.Ref, "Object.AdvanceHolder");
			Return;
		EndIf;
		//-- WE
	EndIf;
	
EndProcedure

&AtClient
Procedure ARAPDetailsOnActivateCell(Item)
	
	CashClient.SetAvailabilityOfPaymentDecryptionItemAmountOfSettlements(ThisObject, Object.Currency);
	CashClient.SetAvailabilityOfPaymentDecryptionContractElement(ThisObject);
	
EndProcedure

&AtClient
Procedure DecodingWithoutSplittingIsVariantOfContractCourseClick(Item, StandardProcessing)
	ARAPAccountingClient.TranscriptOfPaymentCourseOptionOfContractClick(Items.ARAPDetails.CurrentData, StandardProcessing);
EndProcedure

&AtClient
Procedure DecryptionWithoutSplittingRepaymentDateOnChange(Item)
	
	Object.ARAPDetails[0].MaturityDate = MaturityDateWithoutSplitting;
	UpdatePresentationOfMaturityDate();
	
EndProcedure

&AtClient
Procedure DecryptionWithoutSplittingRepaymentDateStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	OpeningParameters = New Structure("InitialValue", Object.ARAPDetails[0].MaturityDate);
	CallbackDescription = New CallbackDescription("DecryptionWithoutSplittingRepaymentDateEndOfSelection", ThisObject);
	OpenForm("CommonForm.SelectDate", OpeningParameters, ThisObject,,,, CallbackDescription, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure DecryptionWithoutSplittingRepaymentDateClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	Object.ARAPDetails[0].MaturityDate = Date(1, 1, 1);
	UpdatePresentationOfMaturityDate();
	
EndProcedure

&AtClient
Procedure DecryptionWithoutSplittingRepaymentDateTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If TypeOf(MaturityDateWithoutSplitting) = Type("Date") Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	DateInNumbers = StrConcat(StrSplit(Text, StrConcat(StrSplit(Text, "0123456789"))));
	If Not IsBlankString(DateInNumbers) Then
		SelectedDay  = Left(DateInNumbers, 2);
		If StrLen(DateInNumbers) > 2 Then
			SelectedMonth = Mid(DateInNumbers, 3, 2);
		Else
			SelectedMonth = Format(CommonClient.SessionDate(), "DF=MM")
		EndIf;
		If StrLen(DateInNumbers) > 4 Then
			SelectedYear = Mid(DateInNumbers, 5, 4);
		Else
			SelectedYear   = Format(CommonClient.SessionDate(), "DF=yyyy")
		EndIf;
		SelectedDateAsString = StrTemplate("%1.%2.%3", SelectedDay, SelectedMonth, SelectedYear);
		SelectedDate = StringFunctionsClientServer.StringToDate(SelectedDateAsString);
		Object.ARAPDetails[0].MaturityDate = SelectedDate;
		UpdatePresentationOfMaturityDate();
		ChoiceData = New ValueList();
		ChoiceData.Add(SelectedDate);
	EndIf;
	
EndProcedure

&AtClient
Procedure TranscriptOfPaymentContractOnChange(Item)
	
	LineOfATabularSection = Items.ARAPDetails.CurrentData;
	
	If LineOfATabularSection = Undefined Then
		Return;
	EndIf;
	
	Object.Contract = LineOfATabularSection.Contract;
	
	AgreementWhenModifiedOnServer();
	
EndProcedure

&AtClient
Procedure TranscriptOfPaymentContractStartChoice(Item, ChoiceData, StandardProcessing)
	
	SettlementObjectContractStartOfSelection(Item, ChoiceData, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPersonalAccountsOfStaff

&AtClient
Procedure PersonalAccountsOfStaffOnChange(Item)

	If Not Object.PaymentByRequests Then
		PersonalAccountsOfEmployeesWhenChangedOnServer();
	EndIf;

EndProcedure

&AtClient
Procedure ARAPDetailsPartnerOnChange(Item)

	ARAPDetailsPartnerOnChangeAtServer();

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

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
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm, True);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm, True);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm, True);
	
EndProcedure

&AtClient
Procedure SelectionByStock(Command)
	
	SelectionByResiduesProcessing("SelectionByStockCompletion");
	
EndProcedure

&AtClient
Procedure PickUpGiftCertificate(Command)
	
	If GiftCertificatesClient.CheckPossibilityOfAddingGiftCertificate(ThisObject, False) Then
		DescriptionOfAssuranceNotification = New CallbackDescription("PickUpGiftCertificateCompletion", ThisObject);
		If Object.Posted Then
			RetailSalesClient.DisplayQuestionAboutNeedForUnverifiedDocument(ThisObject, DescriptionOfAssuranceNotification);
		Else
			RunCallback(DescriptionOfAssuranceNotification, True);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure PickUpGiftCertificateCompletion(Result, AdditionalParameters) Export
	
	If Result = True Then
		StatusesForSelection = New Array;
		StatusesForSelection.Add(PredefinedValue("Enum.GiftCertificateStatuses.Activated"));
		StatusesForSelection.Add(PredefinedValue("Enum.GiftCertificateStatuses.PartiallyRepaid"));
		
		FilterParameters = New Structure;
		FilterParameters.Insert("Organization", Object.Organization);
		FilterParameters.Insert("Currency", CurrencyOfComplianceAccounting);
		FilterParameters.Insert("Status", StatusesForSelection);
		FilterParameters.Insert("GiftCardAccounting25", True);
		FilterParameters.Insert("OperationType", GiftCertificatesClientServer.TypeOfOperationForGiftCertificates(Object));
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("Organization", Object.Organization);
		AdditionalParameters.Insert("DoNotUseManualInput", False);
		AdditionalParameters.Insert("Filter", FilterParameters);
		AdditionalParameters.Insert("RegisterNewOnes", False);
		
		OpenForm(
			"Catalog.GiftCertificates.Form.ReadGiftCard",
			AdditionalParameters,
			ThisObject,
			UUID);
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectionBasedOnBalancesAfterVerification(Result, AdditionalParameters) Export 
	
	Notification = New CallbackDescription(AdditionalParameters.CompletionProcedure, ThisObject);
	PlacePaymentDecryptionInTemporaryStorage();
	
	AdditionalFilters = New Map();
	If Object.PaymentsAsPer275FZ Then
		AdditionalFilters.Insert("Contract.PaymentsAsPer275FZ", True);
	EndIf;
	ARAPAccountingClient.AddToPaymentDecryption(ThisForm, Items.ARAPDetailsSelectionByStock.Name, Notification, AdditionalFilters);
	
EndProcedure

&AtServer
Procedure PlacePaymentDecryptionInTemporaryStorage()
	ARAPAccountingFormWork.PlacePaymentDecryptionInTemporaryStorage(ThisForm, "ARAPDetailsSelectionByStock");
EndProcedure

&AtClient
Procedure SelectionByStockCompletion(Result, AdditionalParameters) Export
	If Result <> Undefined Then
		SelectionByStockCompletionServer();
	EndIf;
EndProcedure

&AtServer
Procedure SelectionByStockCompletionServer()
	
	ARAPAccountingFormWork.DownloadPaymentTranscriptFromTemporaryStorage(ThisObject);
	CompleteVATTaxation();
	DefaultCFItem =
		Catalogs.CashFlowReportItems.CashFlowItemForBusinessTransaction(Object.BusinessOperation);
	ArticlesOfBusinessOfOperation =
		Catalogs.CashFlowReportItems.ArticlesOfBusinessOfOperation(Object.BusinessOperation);
	
	For Each TableRow In Object.ARAPDetails Do
		If ArticlesOfBusinessOfOperation.Find(TableRow.CashFlowItem) = Undefined Then
			TableRow.CashFlowItem = DefaultCFItem;
		EndIf;
		FillInCourseAndMultiplicityInDecryptionLine(TableRow);
		CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
			TableRow, Object.Currency, CurrencyOfComplianceAccounting);
		CashServer.FormCourseDenominatorByText(TableRow, Object.Currency, CurrencyOfComplianceAccounting);
	EndDo;
	
	CashServer.CheckFillOutContract(Object);
	
	SetRestrictionOnTypeOfPaymentDecryptionContract();
	GenerateHyperlinkCaptionPaymentObjectDetails();
	FillInCurrencyOfMutualSettlementsOfDocument();
	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	
	CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object, , True);
	
	// If the selection is not for the entire amount of the document, then you need to fill in the VAT rate on the line without the calculation object
	For Each DecryptionString In Object.ARAPDetails Do
		If Not ValueIsFilled(DecryptionString.ARAPObject)
			Or DecryptionString.CalculationObject = Object.Ref Then
			If ValueIsFilled(DecryptionString.Contract) Then
				DecryptionString.VATRate = Common.ObjectAttributeValue(DecryptionString.Contract, "VATRate");
			EndIf;
			If ValueIsFilled(DecryptionString.VATRate) Then
				StructureOfActions = New Structure("RecalculateVATAmount", New Structure("PriceIncludesVAT", True));
				BatchProcessingOfTablePartServer.TreatTS(Object.ARAPDetails, StructureOfActions, Undefined);
			Else
				UpdateTaxRateRecalculateVATAmount(DecryptionString.GetID());
			EndIf;
		EndIf;
	EndDo;
	
	FillInParametersOfCalculationObjectInDecryption(Not Object.PaymentByRequests);
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtClient
Procedure SelectFromRequests(Command)
	
	Notification = New CallbackDescription("SelectFromRequestsCompletion", ThisObject);
	CheckPossibilityOfFillingOutApplication(Notification);
	
EndProcedure

&AtClient
Procedure SelectFromRequestsCompletion(Result, AdditionalParameters) Export 
	
	AddressOfPaymentsInTheStorage = PlacePaymentDecryptionInVault();
	
	PickingParameters = New Structure(
		"Counterparty,
		|BankAccountBeneficiary,
		|AdvanceHolder,
		|Organization,
		|BusinessOperation,
		|PayrollTransaction,
		|Currency,
		|DocumentAmount,
		|Date,
		|ListOfCounterparties_,
		|OperationWithSelfEmployedPerson");
	
	FillPropertyValues(PickingParameters, Object);
	
	PickingParameters.Insert("Ref",                              Object.Ref);
	
	PaymentForms = FormsOfPaymentForApplicationsForNonCashPayment();
	
	PickingParameters.Insert("PaymentMethod",                         PaymentForms);
	PickingParameters.Insert("BankAccountCashAccount",                 Object.BankAccount);
	PickingParameters.Insert("AddressOfPaymentsInTheStorage",             AddressOfPaymentsInTheStorage);
	PickingParameters.Insert("ListOfCounterparties_",                  Object.ListOfCounterparties_);
	PickingParameters.Insert("OperationWithSelfEmployedPerson",                Object.OperationWithSelfEmployedPerson);
	
	CompleteSelectionAccordingToListOfIndividuals(PickingParameters);
	
	OpenForm("Document.PaymentRequest.Form.PaymentRequestSelectionInCashIssueNote",
		PickingParameters,
		ThisObject,,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure FillInTheRemainingAmountsOfNonIssuedAmountsToTheCounterparty(Command)
	
	FillInBalanceOfOutstandingAmountsToCounterpartyOnServer();
	
EndProcedure

&AtServer
Procedure FillInBalanceOfOutstandingAmountsToCounterpartyOnServer()
	
	Object.ARAPDetails.Clear();
	
	CurrentAgreements = Catalogs.LoanAndDepositContracts.CurrentContractsForCounterparty(
		Object.Organization, Object.Counterparty, Enums.ContractKindsOfFinancialInstruments.IssuedBorrowing);
	
	For Each Contract In CurrentAgreements Do
		
		DetailsData = Catalogs.LoanAndDepositContracts.PaymentDecryptionDataOfDDSDocument(
			Contract, False, Object.Ref);
		
		For Each String In DetailsData Do
			NewRow = Object.ARAPDetails.Add();
			FillPropertyValues(NewRow, String);
			IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, NewRow, "Object.ARAPDetails");
		EndDo;
	EndDo;
	
	Object.DocumentAmount = Object.ARAPDetails.Total("Sum");
	
EndProcedure

&AtClient
Procedure PopulatePurposeOfPayment(Command)
	
	PopulatePurposeOfPaymentServer();
	
EndProcedure

&AtServer
Procedure PopulatePurposeOfPaymentServer()
	
	CashServer.FillInPaymentDestinationText(Object);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)

	ClearMessages();
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
Procedure InsertIntoAssignment(Command)
	
	Return;
	
EndProcedure

&AtClient
Procedure ExportFileForBankExchange(Command)
	
	Return;
	
EndProcedure

&AtClient
Procedure FillInTheRemainingOutstandingAmountsToTheEmployee(Command)
	
	Return;
	
EndProcedure

&AtClient
Procedure FillInWithThePreviousPayment(Command)
	
	Return;
	
EndProcedure

&AtClient
Procedure SelectTaxInvoices(Command)
	
	Return;
	
EndProcedure

&AtClient
Procedure CheckCounterparties(Command)
	
	Return;
	
EndProcedure

&AtClient
Procedure SetDeletionMarkForADocument(Command)
	TMCommonUseClient.SetDeletionMarkForADocument(ThisForm);
EndProcedure

&AtClient
Procedure FillInCashFlowItem(Command)

	ClearMessages();
	CashClient.FillInCashFlowItem(
		ThisObject, Items.PersonalAccountsOfStaff, "PersonalAccountsOfStaff");

EndProcedure

#EndRegion

#Region Private

#Region ElementEventHandlers

&AtServer
Procedure DateOnChangeServer()

	CompleteVATTaxation();
	CashServer.CalculateAmountsInSenderSCurrencyInDecryption(Object, BankAccountCurrency);

EndProcedure

&AtServer
Procedure OnChangingBankAccount(AttributesStructure1)

	OrganizationChanged_ = (Object.Organization <> AttributesStructure1.Organization);
	
	Object.Currency           = AttributesStructure1.Currency;
	Object.Organization      = AttributesStructure1.Organization;
	CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	BankAccountCurrency = AttributesStructure1.Currency;
	
	If ValueIsFilled(Object.BankAccount) Then

		If OrganizationChanged_ Then
			
			BranchesOfOrganization.LoadValues(Catalogs.Companies.BranchesWithPaymentsThroughParentOrganization(Object.Organization));
			ThereAreBranches = (BranchesOfOrganization.Count() > 0);

		EndIf;
		
	Else
		BranchesOfOrganization.Clear();
	EndIf;
	
	CurrentBankAccount = Object.BankAccount;

EndProcedure

&AtServer
Procedure DocumentAmountOnChangeServer()
	
	If Object.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion Then
		RecalculateConversionParameters("ConversionRate");
	EndIf;
	
	VATConversionParameters = New Structure("PriceIncludesVAT", True);
	StructureOfActions = New Structure("RecalculateVATAmount", VATConversionParameters);
	BatchProcessingOfTablePartServer.TreatTS(Object.ARAPDetails, StructureOfActions, Undefined);
	
	CashServer.CalculateAmountsInSenderSCurrencyInDecryption(Object, BankAccountCurrency);
	
	SetRestrictionOnTypeOfPaymentDecryptionContract();
	GenerateHyperlinkCaptionPaymentObjectDetails();
	SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning();
	
	If Object.RecordCommission Then 
		Object.FeeAmount = CashClientServer.CalculateCommissionAmount(Object.DocumentAmount, CommissionRate, "Return");
		Items.GroupCommission.Title = TitleOfAcquiringCommission(Object.FeeAmount, Object.Currency, CommissionRate);
	EndIf;
	
EndProcedure

&AtClient
Function CurrencyOnChangeClient()
	
	If CurrentCurrency = Object.Currency Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

&AtServer
Procedure CurrencyWhenChangedOnServer()

	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Currency");
	
	CashServer.ClearApplicationForSpendingMoney(Object);
	
	SetPaymentWithConversionAttribute();
	
	WhenChangingCurrency();
	
	SetPossibleRecipientAccountValues();
	FormItemsManagement();

EndProcedure

&AtServer
Procedure UpdateCurrencyData()

	If CurrentCurrency <> Object.Currency Then
		WhenChangingCurrency();
	EndIf;

EndProcedure

&AtServer
Procedure WhenChangingCurrency()

	Object.CashAccountRecipient = Catalogs.CashAccounts.EmptyRef();
	
	If Object.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion Then
		RecalculateConversionParameters("CurrencyOfConversion");
		SetConversionAmountHeader();
	EndIf;
	
	CashServer.ConversionOfDocumentAmountsIntoCurrency(Object, CurrentCurrency, Object.Currency);
	
	CashServer.UpdateSettlementCurrencyOfPaymentDecryption(
		"Document.BankAccountIssue", Object, CurrencyOfComplianceAccounting, True);
	
	VATConversionParameters = New Structure("PriceIncludesVAT", True);
	StructureOfActions = New Structure("RecalculateVATAmount", VATConversionParameters);
	BatchProcessingOfTablePartServer.TreatTS(Object.ARAPDetails, StructureOfActions, Undefined);
	
	CashServer.CalculateAmountsInSenderSCurrencyInDecryption(Object, BankAccountCurrency);
	
	FillMultiplicityCourseWithText();
	FillInCurrencyOfMutualSettlementsOfDocument();
	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	
	InformationForRegulatoryBodiesIsRequired = (Common.ObjectAttributeValue(Object.Currency, "Code") = "980");
	
	UpdateAmountUnallocated();
	GenerateHyperlinkCaptionPaymentObjectDetails();
	
	CurrentCurrency = Object.Currency;

EndProcedure

&AtServer
Procedure ListOfPersonsChangedOnServer()

	ListOfIndividualsEnabledWhenChangedOnServer();
	
	UpdateCurrencyData();

EndProcedure

&AtServer
Procedure CurrencyOfConversionOnChangeServer()
	
	SetPossibleRecipientAccountValues();
	
	RecalculateConversionParameters("CurrencyOfConversion");
	SetConversionAmountHeader();
	
EndProcedure

&AtServer
Procedure MultiplicityOfConversionRateWhenChangingOnServer()

	RecalculateConversionParameters("ConversionRateMultiplier");

EndProcedure

&AtServer
Procedure OnChangingRecipientSBankAccount()

	AttributesStructure1 = Catalogs.CompaniesBankAccounts.GetCompanySBankAccountDetails(
		Object.BankAccountBeneficiary);
	FillInRecipientSOrganization(AttributesStructure1);
	
	If Object.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion Then
		
		If ValueIsFilled(AttributesStructure1.Currency) Then
			Object.CurrencyOfConversion = AttributesStructure1.Currency;
			RecalculateConversionParameters("CurrencyOfConversion");
			SetConversionAmountHeader();
		EndIf;
		
	EndIf;

EndProcedure

&AtServer
Procedure OnChangePaymentDecryptionAmount()

	CurrencyDecorationAndPaymentRate = CashServer.CurrencyLabelAndPaymentRate(ThisObject);
	SetRestrictionOnTypeOfPaymentDecryptionContract();
	GenerateHyperlinkCaptionPaymentObjectDetails();

EndProcedure

&AtServer
Procedure PaymentIdOnChangeAtServer()
	
	ProcessIPChange();
	
EndProcedure

&AtServer
Procedure ContractFeesOnChangesATServer()
	
	Object.CommissionARAPObject = ?(ValueIsFilled(CommissionAgreement),
		ARAPObjectsServer.GetCalculationObjectFromLink(CommissionAgreement), Catalogs.ARAPObjects.EmptyRef());
	
EndProcedure

&AtServer
Procedure KeepRecordsOfCommissionInMutualSettlementsSwitchOnChangesAtServer()
	
	Object.KeepRecordsOfCommissionInARAPAccounting = KeepRecordsOfCommissionInMutualSettlementsSwitch;
	
	If Not Object.KeepRecordsOfCommissionInARAPAccounting Then
		CommissionAgreement = PredefinedValue("Catalog.CounterpartyContracts.EmptyRef");
		Object.CommissionARAPObject = PredefinedValue("Catalog.ARAPObjects.EmptyRef");
	EndIf;
	ItemsAndDimensionsSelectionParameters = Documents.BankAccountIssue.ItemsAndDimensionsSelectionParameters(
		Object.BusinessOperation, Object.RecordCommission And Not Object.KeepRecordsOfCommissionInARAPAccounting);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);
	ConfigureDependentFormElementsOnServer("KeepRecordsOfCommissionInARAPAccounting");
	
EndProcedure

#EndRegion

#Region Properties

// StandardSubsystems.Properties
&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure
// End StandardSubsystems.Properties


&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

&AtServer
Procedure PersonalAccountsOfEmployeesWhenChangedOnServer()

	Object.ARAPDetails.Clear();
	NewRow = Object.ARAPDetails.Add();
	NewRow.ARAPCurrency = Object.Currency;
	NewRow.ExchangeRateNumeratorOfMutualSettlements = 1;
	NewRow.TheExchangeRateIsTheDenominatorOfMutualSettlements = 1;
	NewRow.Sum = Object.PersonalAccountsOfStaff.Total("Sum");
	
	CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
		NewRow, Object.Currency, CurrencyOfComplianceAccounting);
	
EndProcedure

#EndRegion

#Region FormItemsManagement

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	//ARAPCurrency
	CashServer.SetConditionalAppearanceOfSettlementCurrency(ThisObject);
	
	//Partner
	CashServer.SetPartnerConditionalAppearance(ThisObject);
	
	//
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Department.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.IssueCashToAdvanceHolder;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ARAPDetailsPaymentRequest.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PaymentByRequests");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ARAPDetailsDepartment.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.TransferOfTaxesAndContributions;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ARAPDetailsARAPObject.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ARAPDetails.ARAPObject");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ARAPDetails.TheCalculationObjectMatchesTheDocument");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.DarkGray);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Chứng từ này>';
													|ru = '<этот документ>';
													|en = '<this document>'; fa = '<this document>';
													|it = '<questo documento>';
													|pl = '<ten dokument>';
													|tr = '<bu belge>'"));
	
	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisForm);
	
	// The course of settlements
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ARAPDetailsExchangeRateNumeratorOfMutualSettlements.Name);
	
	Item.Appearance.SetParameterValue("Text", "");
	
	// Maturity Date
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ARAPDetailsMaturityDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.ARAPDetails.MaturityDate");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<tự động>';
													|ru = '<автоматически>';
													|en = '<automatically>'; fa = '<automatically>';
													|it = '<автоматически>';
													|pl = '<automatically>';
													|tr = '<otomatik olarak>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	// VATAmount
	CashServer.SetConditionalAppearanceOfVATAmountOfPaymentDecryption(ThisObject);
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	CashServer.ManagingFormElementsWhenReadingCreatingOnServer(ThisObject);
	
	UsePayroll                    = Constants.UsePayroll.Get();
	//++ WE
	PayrollAndHumanResourcesWE                      = GetFunctionalOption("PayrollAndHumanResourcesWE");
	//-- WE
	UsePaymentRequests   = GetFunctionalOption("UsePaymentRequests");
	UseApplicationsForBusinessTrip                  = GetFunctionalOption("UseApplicationsForBusinessTrip");
	UseMultipleCurrencies                        = GetFunctionalOption("UseMultipleCurrencies");
	UseDataSynchronization                   = GetFunctionalOption("UseDataSynchronization");
	UseAccountingOfOtherAssetsAndLiabilities             = GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities");
	UseIntercompanyContracts            = GetFunctionalOption("UseIntercompanyContracts");
	UseCustomerContracts                    = GetFunctionalOption("UseCustomerContracts");
	UseContractsWithVendors                 = GetFunctionalOption("UseContractsWithVendors");
	UseCurrencyPayments                       = GetFunctionalOption("UseCurrencyPayments");
	UseCashDepositToListEmployees =
		GetFunctionalOption("UseCashDepositToListEmployees");
	UsingPartnersAsCounterparties             = GetFunctionalOption("UsePartnersAsCounterparties");
	
	CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	CurrentBankAccount = Object.BankAccount;
	SavedBusinessTransaction = Object.BusinessOperation;
	CurrentCurrency = Object.Currency;
	TypesOfTaxesWithAccountSettings.LoadValues(LocalAccntingServer.TypesOfTaxesWithAccountSettings());
	
	If ValueIsFilled(Object.Organization) Then
		BranchesOfOrganization.LoadValues(Catalogs.Companies.BranchesWithPaymentsThroughParentOrganization(Object.Organization));
		ThereAreBranches = BranchesOfOrganization.Count() > 0;
		LegalEntityIndividual = Common.ObjectAttributeValue(Object.Organization, "LegalEntityIndividual", True);
	EndIf;
	
	If ValueIsFilled(Object.AcquiringContract) Then
		If Object.RecordCommission Then
			If Object.DocumentAmount <> 0 Then
				CommissionRate = CashClientServer.CalculateCommissionRate(Object.DocumentAmount, Object.FeeAmount, "Return");
			Else
				CommissionRate = 0;
			EndIf;
			Items.GroupCommission.Title = TitleOfAcquiringCommission(Object.FeeAmount, Object.Currency, CommissionRate);
		EndIf;
	EndIf;
	
	InformationForRegulatoryBodiesIsRequired = (Common.ObjectAttributeValue(Object.Currency, "Code") = "980");
	
	BankAccountDetails = Catalogs.CompaniesBankAccounts.GetCompanySBankAccountDetails(CurrentBankAccount);
	
	AllowPaymentsWithoutApplicationSpecificationBankAccount = BankAccountDetails.EnableCreatingCashIssueWithoutPaymentRequest;
	EnabledCreatingCashIssueWithoutPaymentRequest =
		(AllowPaymentsWithoutApplicationSpecificationBankAccount And UsePaymentRequests)
		Or Object.DoNotControlRequestFilling
		Or Not UsePaymentRequests;
	BankAccountCurrency = BankAccountDetails.Currency;
	
	GetDefaultServerPartner(Object.Counterparty, Partner, Object.BusinessOperation);
	GetDefaultContractServer(Object.Counterparty, Object.CounterpartyBankAccount, False);
	
	InitializePaymentDecryption();
	
	CashServer.FillInListOfAdvanceReportPeriodSelections(ThisObject, Object.Date);
	ExpenseReportPeriodDate = (TypeOf(ExpenseReportPeriod) = Type("Date"));
	
	TransferToEmployeeViaABank = Number(Object.TransferToEmployeeViaABank);
	
	PersonsList = Number(Object.PersonsList);
	
	BusinessTransactionCurrencyConverter = Enums.BusinessTransactions.CurrencyConversion;
	ParameterLinks = New Array;
	ParameterLinks.Add(New ChoiceParameterLink("Filter.BusinessOperation", "BusinessTransactionCurrencyConverter"));
	Items.CashFlowItemConversion.ChoiceParameterLinks = New FixedArray(ParameterLinks);
	
	If ValueIsFilled(Object.CommissionARAPObject) Then
		CommissionAgreement = ContractARAPObjectOfFee(Object.CommissionARAPObject);
	EndIf;
	KeepRecordsOfCommissionInMutualSettlementsSwitch = Object.KeepRecordsOfCommissionInARAPAccounting;
	
	DisplayingTitleOfAccountablePersonField();
	FillInRecipientSOrganization();
	FillInListOfBusinessOperations();
	SpecifyListOfBusinessOperations();
	CashServer.GetAvailableBusinessOfOperationsBasedOn(
		Object.DocumentBasis, Enums.PaymentForms.BankAccountPayment, AvailableBaseOfOperations);

	SetHeadingIncomeExpenseItem();
	SetConversionAmountHeader();
	UpdateInformationOnApplications();
	UpdateMirrorPaymentLabel();
	
	FillInCurrencyOfMutualSettlementsOfDocument();
	FillMultiplicityCourseWithText();
	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	
	CashServer.DetermineCurrencyPayment(ThisObject);
	CodesOfInstructionsForBank = LabelInstructionCodes(Object);
	InformationForRegulatoryBodies = LabelInformationForRegulatoryAuthorities(Object);
	
	SetInscriptionOfDSEnrollment();
	
	SetPossibleRecipientAccountValues(False);
	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure ConfigureDependentFormElements(ChangedProps = "")
	
	CashClientServer.CustomizeFormElements(ThisObject, ChangedProps, FormAttributes(ThisForm));
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(ChangedProps = "") Export
	
	CashClientServer.CustomizeFormElements(ThisObject, ChangedProps, FormAttributes(ThisForm));
	
EndProcedure

&AtClientAtServerNoContext
Function FormAttributes(Form)
	
	FormAttributes = New Structure;
	FormAttributes.Insert("UsePaymentRequests");
	FormAttributes.Insert("UseApplicationsForBusinessTrip");
	FormAttributes.Insert("EnabledCreatingCashIssueWithoutPaymentRequest");
	FormAttributes.Insert("ThereAreBranches");
	FormAttributes.Insert("UseLocal");
	FormAttributes.Insert("ChartOfAccountsAccessRight");
	FormAttributes.Insert("UseMultipleCurrencies");
	FormAttributes.Insert("UsePayroll");
	FormAttributes.Insert("UsePayrollTM");
	//++ WE
	FormAttributes.Insert("PayrollAndHumanResourcesWE");
	//-- WE
	FormAttributes.Insert("ExpenseReportPeriodDate");
	FormAttributes.Insert("InformationForRegulatoryBodiesIsRequired");
	FormAttributes.Insert("UseCurrencyPayments");
	FormAttributes.Insert("CurrencyPayment");
	FormAttributes.Insert("ForeignExchangeControl");
	FormAttributes.Insert("VOCodeFilledIn");
	FormAttributes.Insert("ThisIsATransitAccount");
	FormAttributes.Insert("PaymentOfVATToBudgetByCertainTransactions");
	FormAttributes.Insert("AmountUnallocated");
	FormAttributes.Insert("UseIntercompanyContracts");
	FormAttributes.Insert("UseCustomerContracts");
	FormAttributes.Insert("UseContractsWithVendors");
	FormAttributes.Insert("TheUseOfSparkrazIsAllowed");
	FormAttributes.Insert("TheIndication20195286YIsValid");
	FormAttributes.Insert("CounterpartyLegEntInd");
	FormAttributes.Insert("ARAPCurrency");
	FormAttributes.Insert("CurrencyOfComplianceAccounting");
	FormAttributes.Insert("AvailabilityOfCashTransferDocument");
	FormAttributes.Insert("UseCashDepositToListEmployees");
	FormAttributes.Insert("ContractRateOption");
	FormAttributes.Insert("ARAPObjectType");
	FormAttributes.Insert("ExchangeRateNumeratorOfMutualSettlements");
	FormAttributes.Insert("UsePaymentsToSelfEmployedPersons");
	FormAttributes.Insert("MultipleARAPCurrency");
	FormAttributes.Insert("UIPIsDifferent");
	
	FillPropertyValues(FormAttributes, Form);
	
	Return FormAttributes;
	
EndFunction

&AtServer
Procedure InitializePaymentDecryption()
	
	ArrayOfOperationDetails = New Array;
	Documents.BankAccountIssue.FillInNamesOfBusinessTransactionDetails(
		Object, Undefined, ArrayOfOperationDetails);
	
	If ArrayOfOperationDetails.Find("ARAPDetails") = Undefined
		Or Documents.BankAccountIssue.ArrayOfOperationsWithoutPaymentDecryption().Find(Object.BusinessOperation) <> Undefined
			And Not Object.PaymentByRequests Then
		Object.ARAPDetails.Clear();
		DecryptionSwitch = 0;
	Else
		If ArrayOfOperationDetails.Find("ARAPDetails.MaturityDate") = Undefined Then
			For Each DecryptionString In Object.ARAPDetails Do
				DecryptionString.MaturityDate = Date(1 , 1 ,1);
			EndDo;
		EndIf;
		If Object.ARAPDetails.Count() = 0 Then
			NewRow = Object.ARAPDetails.Add();
			Items.ARAPDetails.CurrentRow = NewRow.GetID();
			DecryptionSwitch = 0;
			NewRow.CashFlowItem = Object.CashFlowItem;
			NewRow.Sum = Object.DocumentAmount;
			NewRow.ARAPCurrency = Object.Currency;
			NewRow.ExchangeRateNumeratorOfMutualSettlements = 1;
			NewRow.TheExchangeRateIsTheDenominatorOfMutualSettlements = 1;
			IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, NewRow, "Object.ARAPDetails");
			CompleteVATTaxation();
		ElsIf Object.ARAPDetails.Count() = 1 Then
			Items.ARAPDetails.CurrentRow = Object.ARAPDetails[0].GetID();
			DecryptionSwitch = 0 Or ThisIsSelectionOfApplications;
			CompleteVATTaxation(False);
		Else
			DecryptionSwitch = 1;
			CompleteVATTaxation(False);
		EndIf;
		CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object, , True);
		SetRestrictionOnTypeOfPaymentDecryptionContract();
		FillInParametersOfCalculationObjectInDecryption();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInParametersOfCalculationObjectInDecryption(FillInUIP = False)
	ComplianceOfContractCurrencyExchangeRate = ARAPAccountingServer.ComplianceOfARAPObjectsAndParametersOfContract(
		Object.ARAPDetails.Unload(,"ARAPObject").UnloadColumn("ARAPObject"));
	For Each TSRow In Object.ARAPDetails Do
		TSRow.ContractRateOption = ComplianceOfContractCurrencyExchangeRate[TSRow.ARAPObject].ContractRateOption;
		TSRow.ItIsAllowedToWorkWithSubsidiaryPartners = ComplianceOfContractCurrencyExchangeRate[TSRow.ARAPObject].ItIsAllowedToWorkWithSubsidiaryPartners;
		TSRow.TheCalculationObjectMatchesTheDocument = ComplianceOfContractCurrencyExchangeRate[TSRow.ARAPObject].Object = Object.Ref;
		If ValueIsFilled(TSRow.ARAPObject) Then
			TSRow.ARAPObjectType = ComplianceOfContractCurrencyExchangeRate[TSRow.ARAPObject].ARAPObjectType;
			If FillInUIP And IsBlankString(Object.PaymentID) And ValueIsFilled(TSRow.PaymentID) Then
				Object.PaymentID = TSRow.PaymentID;
			EndIf;
		EndIf;
		FillInUIPIndexIsDifferent(TSRow);
	EndDo;
	DefineUIPIsDifferent();
EndProcedure

&AtServer
Procedure FormItemsManagement()
	
	ArrayOfOperationDetails = New Array;
	Documents.BankAccountIssue.FillInNamesOfBusinessTransactionDetails(
		Object, Undefined, ArrayOfOperationDetails);
	CashServer.SetBankAccountSelectionParameters_(Object, Items.BankAccount);
	CashServer.SetParametersForSelectingCounterpartySBankAccount(Object, Items.CounterpartyBankAccount);
	CashServer.SetApplicationSelectionParameters(Object, Items.PaymentRequest);
	CashServer.SetApplicationSelectionParameters(Object, Items.ARAPDetailsPaymentRequest);
	CashServer.SetApplicationSelectionParameters(Object, Items.DecryptionWithoutSplittingTheApplicationForSpendingMoney);
	CashServer.SetCounterpartySelectionParameters(Object, Items.Counterparty);
	CashServer.SetPartnerSelectionParameters(Object, Items.ARAPDetailsPartner);
	CashServer.SetPartnerSelectionParameters(Object, Items.DecryptionWithoutPartitioningPartner);
	CashServer.SetParametersForSelectingLoanDepositAgreement(Object, Items.ARAPDetailsLoanDepositContract);
	CashServer.SetParametersForSelectingLoanDepositAgreement(Object, Items.DecryptionWithoutSplittingTheLoanDepositAgreement, True);
	CashServer.SetParametersForSelectingLeaseAgreement(Object, Items.ARAPDetailsLeaseContracts);
	CashServer.SetParametersForSelectingLeaseAgreement(Object, Items.DecryptionWithoutSplittingTheLeaseAgreement);
	If ArrayOfOperationDetails.Find("Contract") <> Undefined Then
		CashServer.SetContractSelectionParameters(ThisObject, Items.Contract);
	EndIf;
	
	CashServer.SetParametersForSelectingCashFlowItems(Object, Items.CashFlowItem);
	CashServer.SetParametersForSelectingDirectionOfActivity(Object, Items.LineOfBusiness);
	CashServer.SetParametersForSelectingDirectionOfActivity(Object, Items.DirectionOfReturnActivity);
	CashServer.SetParametersForSelectingDirectionOfActivity(Object, Items.DecodingWithoutSplittingTheDirectionOfActivity);
	
	SetVisibilityOfGiftCertificateSelectionButton();
	
	CashServer.FillInListOfTypesOfAmountsOfLoansDeposits(
		Items.ARAPDetailsLoanAndDepositAmountType.ChoiceList, Object.BusinessOperation);
	CashServer.FillInListOfTypesOfAmountsOfLoansDeposits(
		Items.DecryptionWithoutSplittingTheTypeOfLoanAmountDeposit.ChoiceList, Object.BusinessOperation);
	
	ElementsToChange = New Array;
	ElementsToChange.Add("PersonalAccountsOfStaffSum");
	ElementsToChange.Add("BankAccountsOfCounterpartyListSum");
	CashServer.SetPaymentAmountHeader(Object.Currency, Items, ElementsToChange);
	Items.LabelCurrency.Title = String(Object.Currency);
	Items.LabelCurrencyCommission.Title = Items.LabelCurrency.Title;
	
	Items.GroupCommission.Title = TitleOfAcquiringCommission(Object.FeeAmount, Object.Currency, CommissionRate);
	
	PartnersAndCounterparties.TitleOfPartnerElementDependingOnBusinessOperation(
		ThisObject, "ARAPDetailsPartner", Object.BusinessOperation);
	PartnersAndCounterparties.TitleOfPartnerElementDependingOnBusinessOperation(
		ThisObject, "DecryptionWithoutPartitioningPartner", Object.BusinessOperation);
	
	If DecryptionSwitch Then
		Items.ExplanationPages.CurrentPage = Items.ExplanationAsAList;
	Else
		Items.ExplanationPages.CurrentPage = Items.ExplanationWithoutSplit;
	EndIf;
	
	If Not DecryptionSwitch Then
		SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning();
		If Object.ARAPDetails.Count() > 0
			And ValueIsFilled(Object.ARAPDetails[0].MaturityDate) Then
			MaturityDateWithoutSplitting = Object.ARAPDetails[0].MaturityDate;
		Else
			MaturityDateWithoutSplitting = NStr("vi = '<tự động>';
												|ru = '<автоматически>';
												|en = '<automatically>'; fa = '<automatically>';
												|it = '<автоматически>';
												|pl = '<automatically>';
												|tr = '<otomatik olarak>'");
		EndIf;
	EndIf;
	
	SetRestrictionOnTypeOfPaymentDecryptionContract();
	GenerateHyperlinkCaptionPaymentObjectDetails();
	
	SystemSettingsLocalization.SetVisibilityOfLocalizationElements(ThisObject);
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtServer
Procedure FillInListOfBusinessOperations()
	
	Operations = Enums.BusinessTransactions;
	AvailableTransactions = Items.BusinessOperation.ChoiceList;
	AvailableTransactions.Clear();
	
	AvailableTransactions.Add(Operations.PaymentToVendor);
	AvailableTransactions.Add(Operations.IssueCashToAdvanceHolder, NStr("vi = 'Chi tạm ứng';
																		|ru = 'Выдача подотчетнику';
																		|en = 'Payment to advance holder'; fa = 'پرداخت به تنخواه‌گردان';
																		|it = 'Rilasciare alla persona responsabile';
																		|pl = 'Wydanie osobie rozliczającej';
																		|tr = 'Avans sahibine transfer'"));
	AvailableTransactions.Add(Operations.TransferOfTaxesAndContributions);
	AvailableTransactions.Add(Operations.CashPaymentToAnotherCompany, NStr("vi = 'Thanh toán cho doanh nghiệp khác';
																			|ru = 'Оплата другой организации';
																			|en = 'Intercompany payment'; fa = 'پرداخت درون‌گروهی';
																			|it = 'Pagamento ad un''altra azienda';
																			|pl = 'Płatność innej firmy';
																			|tr = 'Başka iş yeri ödemesi'"));
	AvailableTransactions.Add(Operations.TransferCashBetweenCompanyAndItsBranchOffices, NStr("vi = 'Chuyển giữa doanh nghiệp và chi nhánh';
																							|ru = 'Передача между организацией и филиалом';
																							|en = 'Transfer between the company and its branch office'; fa = 'انتقال بین شرکت و شعبه آن';
																							|it = 'Trasferimento tra organizzazione e filiale';
																							|pl = 'Transfer między organizacją i filią';
																							|tr = 'İş yerleri ve şubeler arasında transfer'"));
	AvailableTransactions.Add(Operations.SalaryPaymentToBankAccounts);
	AvailableTransactions.Add(Operations.PaymentToLessor);
	
	AvailableTransactions.Add(Operations.TransferCashToAnotherAccount, NStr("vi = 'Chuyển sang tài khoản khác';
																			|ru = 'Перечисление на другой счет';
																			|en = 'Cash transfer to other account'; fa = 'انتقال وجه به حساب دیگر';
																			|it = 'Trasferimento su un altro conto';
																			|pl = 'Przelej na inny rachunek';
																			|tr = 'Başka bir hesaba aktarma'"));
	AvailableTransactions.Add(Operations.WithdrawalFromBankAccount, NStr("vi = 'Chuyển tiền từ ngân hàng';
																		|ru = 'Инкассация из банка';
																		|en = 'Cash withdrawal from bank'; fa = 'برداشت وجه نقد از بانک';
																		|it = 'Incasso dalla banca';
																		|pl = 'Inkasacja z banku';
																		|tr = 'Bankadan nakit çekimi'"));
	
	AvailableTransactions.Add(Operations.PaymentOnLoansAndBorrowingsReceived);
	AvailableTransactions.Add(Operations.TransferToDeposits);
	AvailableTransactions.Add(Operations.CashIssueAsLoanToCounterparty, NStr("vi = 'Chi cho đối tác vay';
																			|ru = 'Выдача займа контрагенту';
																			|en = 'Loan to counterparty'; fa = 'وام به طرف حساب';
																			|it = 'Emissione del prestito alla controparte';
																			|pl = 'Wydanie pożyczki kontrahentowi';
																			|tr = 'Cari hesaba kredi'"));
	AvailableTransactions.Add(Operations.CashIssueAsLoanToEmployee, NStr("vi = 'Chi cho nhân viên vay';
																		|ru = 'Выдача займа сотруднику';
																		|en = 'Loan to employee'; fa = 'وام به کارمند';
																		|it = 'Emissione del prestito al dipendente';
																		|pl = 'Wydanie pożyczki pracownikowi';
																		|tr = 'Çalışana kredi'"));
	
	AvailableTransactions.Add(Operations.CurrencyConversion);
	AvailableTransactions.Add(Operations.OtherCashIssue, NStr("vi = 'Chi khác';
																|ru = 'Прочий расход';
																|en = 'Other expenses'; fa = 'سایر هزینه‌ها';
																|it = 'Altre spese';
																|pl = 'Inny wydatek';
																|tr = 'Diğer giderler'"));
	
	AvailableTransactions.Add(Operations.RefundToCustomer);
	AvailableTransactions.Add(Operations.RefundToAnotherCompany, NStr("vi = 'Hoàn lại cho doanh nghiệp khác';
																		|ru = 'Возврат другой организации';
																		|en = 'Refund to another company'; fa = 'بازپرداخت به شرکت دیگر';
																		|it = 'La restituzione ad un''altra organizzazione';
																		|pl = 'Zwrot innej firmy';
																		|tr = 'Başka bir iş yeri iadesi'"));
	AvailableTransactions.Add(Operations.RefundAcquiringPayment);
	
EndProcedure

&AtServer
Procedure SpecifyListOfBusinessOperations()
	
	ItemBusinessOperation = Items.BusinessOperation;
	
	CashServer.EstablishVisibilityOfTransferOperationsBetweenOrganizations(ItemBusinessOperation);
	CashServer.EstablishVisibilityOfInternalTransferOperations(ItemBusinessOperation);
	CashServer.EstablishVisibilityOfOperationOtherCashDisbursement(ItemBusinessOperation);
	CashServer.EstablishVisibilityOfTransactionsUnderLoanAndDepositAgreements(ItemBusinessOperation);
	CashServer.SetVisibilityOfCurrencyConversionNonCashOperation(ItemBusinessOperation);
	CashServer.SetVisibilityOfTransferOperationsToAnotherAccount(ItemBusinessOperation);
	CashServer.EstablishVisibilityOfPaymentToLandlordOperation(ItemBusinessOperation);
	CashServer.EstablishVisibilityOfOperationsToLoansToEmployees(ItemBusinessOperation);
	CashServer.EstablishVisibilityOfAcquiringOperations(ItemBusinessOperation);
	
EndProcedure

&AtServer
Procedure UpdateInformationOnApplications()
	
	ManagerOfDocument = Common.ObjectManagerByFullName("Document.BankAccountIssue");
	CashServer.DisplayInformationOnApplications(ThisObject, ManagerOfDocument);
	
EndProcedure

&AtServer
Procedure SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning()
	
	CashServer.SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning(ThisObject);
	
EndProcedure

&AtServer
Procedure FillInRecipientSOrganization(AttributesStructure1 = Undefined)
	
	If Object.BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany
		Or Object.BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany
		Or Object.BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices Then
		
		If AttributesStructure1 = Undefined Then
			AttributesStructure1 = Catalogs.CompaniesBankAccounts.GetCompanySBankAccountDetails(
				Object.BankAccountBeneficiary);
		EndIf;
		
		If ValueIsFilled(AttributesStructure1.Organization) Then
			If ValueIsFilled(CompanyRecipient) 
				And CompanyRecipient <> AttributesStructure1.Organization Then
				ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "BankAccountBeneficiary.Owner");
			EndIf;
			CompanyRecipient = AttributesStructure1.Organization;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Function PlacePaymentDecryptionInVault()
	GLAccountSettingsServer.RecordFormSInvoiceSettings(ThisObject);
	AddressOfPaymentsInTheStorage = CashServer.PlacePaymentDecryptionInVault(
		Object.ARAPDetails,
		UUID);
	Return AddressOfPaymentsInTheStorage;
	
EndFunction

&AtServer
Procedure GetDefaultContractServer(Counterparty, CounterpartyBankAccount, FillInInvoiceUnderAgreement = True)
	
	ArrayOfAllProps = New Array;
	ArrayOfOperationDetails = New Array;
	Documents.BankAccountIssue.FillInNamesOfBusinessTransactionDetails(
		Object, ArrayOfAllProps, ArrayOfOperationDetails);
		
	If ArrayOfOperationDetails.Find("ARAPDetails.ARAPObject") = Undefined Then
		Return;
	EndIf;
	
	If AccessRight("Read", Metadata.Catalogs.CounterpartyContracts) Then
		
		Filter = Undefined;
		ContractBusinessTransaction = New Array;
		If Object.BusinessOperation = Enums.BusinessTransactions.PaymentToVendor
			And Not Object.OperationWithSelfEmployedPerson Then
			
			ContractBusinessTransaction.Add(Enums.BusinessTransactions.PurchaseFromSupplier);
			ContractBusinessTransaction.Add(Enums.BusinessTransactions.PurchaseByImport);
			ContractBusinessTransaction.Add(Enums.BusinessTransactions.ConsignmentProcurement);
			
			Filter = New Structure;
			Filter.Insert("ContractWithSelfEmployedPerson", False);
			
		ElsIf Object.BusinessOperation = Enums.BusinessTransactions.RefundToCustomer Then
			ContractBusinessTransaction.Add(Enums.BusinessTransactions.SaleToCustomer);
			ContractBusinessTransaction.Add(Enums.BusinessTransactions.TransferToCommissionAgent);
		ElsIf Object.BusinessOperation = Enums.BusinessTransactions.PaymentToVendor
			And Object.OperationWithSelfEmployedPerson Then
			
			ContractBusinessTransaction.Add(Enums.BusinessTransactions.PurchaseFromSupplier);
			
			Filter = New Structure;
			Filter.Insert("ContractWithSelfEmployedPerson", True);
			
		Else
			Return;
		EndIf;
		
		CounterpartyContract = CashServer.DefaultContract(
			CounterpartyContract, Partner, Counterparty, Object.Organization, ContractBusinessTransaction, Filter);
			
		If FillInInvoiceUnderAgreement Then
			PurchasesServerCall.FillInBankAccountsUnderAgreement(CounterpartyContract,, CounterpartyBankAccount);
			If Object.Currency <> Common.ObjectAttributeValue(CounterpartyBankAccount, "CashCurrency")
				And Object.PaymentWithConversion Then
				CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.EmptyRef();
			EndIf;
		EndIf;
	
		If ValueIsFilled(CounterpartyContract) Then
			AccountingInformationUnderAgreement = Catalogs.CounterpartyContracts.AccountingInformationUnderAgreement(CounterpartyContract);
			If ValueIsFilled(AccountingInformationUnderAgreement) Then
				If Not ValueIsFilled(Object.CashFlowItem) Then
					AccountingInformationUnderAgreement.Property("CashFlowItem", Object.CashFlowItem);
				EndIf;
				AccountingInformationUnderAgreement.Property("VATRate", VATRate);
				AccountingInformationUnderAgreement.Property("ARAPCurrency", ARAPCurrency);
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure GetDefaultServerPartner(Counterparty, Partner, BusinessOperation)
	
	Partner = CashServer.GetCounterpartyPartner(Counterparty, BusinessOperation);
	
EndProcedure

&AtServer
Procedure FillInPurposeOfPaymentOnRecipientSAccount()
	
	Attributes = Catalogs.CounterpartyBankAccounts.GetBankAccountDetails(
		Object.CounterpartyBankAccount);
	PurposeOfPaymentText = Attributes.PurposeText;
	
	If ValueIsFilled(Object.PaymentPurposes) Then
		Object.PaymentPurposes = Object.PaymentPurposes + "
			|" + PurposeOfPaymentText;
	Else
		Object.PaymentPurposes = PurposeOfPaymentText;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetConversionAmountHeader()
	
	ConversionParameters_SSLy = CashServer.InitializeConversionParameters();
	FillPropertyValues(ConversionParameters_SSLy, Object);
	ConversionParameters_SSLy.CurrencyOfComplianceAccounting = CurrencyOfComplianceAccounting;
	
	CashServer.CurrencyHeadingExchangeRateAndConversionMultiplicity(ThisObject, ConversionParameters_SSLy);
	
EndProcedure

&AtServer
Procedure CompleteVATTaxation(UpdateVATRateAndAmount = True)
	
	CashServer.CompleteVATTaxation(Object, Object.VATTaxation, Items.DecodingWithoutSplittingVATTaxation, Items.DecryptionWithoutDivisionTaxationVATRefund, UpdateVATRateAndAmount);
	SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning();
	
EndProcedure

&AtServer
Procedure UpdateTaxRateRecalculateVATAmount(LineID = Undefined)
	
	CashServer.UpdateTaxRateRecalculateVATAmount(Object, LineID);
	
EndProcedure

&AtServer
Procedure DisplayingTitleOfAccountablePersonField()
	
	If Object.BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder
		And Object.TransferToEmployeeViaABank
		And GetFunctionalOption("UseCashDepositToListEmployees") Then
		Items.AdvanceHolder.TitleLocation = FormItemTitleLocation.None;
	Else
		Items.AdvanceHolder.TitleLocation = FormItemTitleLocation.Auto;
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdatePresentationOfMaturityDate()
	If Object.ARAPDetails.Count() = 0 
		Or Not ValueIsFilled(Object.ARAPDetails[0].MaturityDate) Then
		MaturityDateWithoutSplitting = NStr("vi = '<tự động>';
											|ru = '<автоматически>';
											|en = '<automatically>'; fa = '<automatically>';
											|it = '<автоматически>';
											|pl = '<automatically>';
											|tr = '<otomatik olarak>'");
	Else
		MaturityDateWithoutSplitting = Object.ARAPDetails[0].MaturityDate;
	EndIf;
EndProcedure

&AtClient
Procedure DecryptionWithoutSplittingRepaymentDateEndOfSelection(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		Object.ARAPDetails[0].MaturityDate = Result;
		Modified = True;
	EndIf;
	UpdatePresentationOfMaturityDate();
	
EndProcedure

&AtServer
Procedure SetRestrictionOnTypeOfPaymentDecryptionContract()

	CashServer.SetRestrictionOnTypeOfPaymentDecryptionContract(ThisObject);
	ConfigureDependentFormElementsOnServer("AmountUnallocated");

EndProcedure

&AtServer
Procedure DirectionOfActivityWhenChangingOnServer()

	CurrentRow = Object.ARAPDetails.FindByID(Items.ARAPDetails.CurrentRow);
	ClearCalculationObject(CurrentRow);

EndProcedure

&AtServer
Procedure FinancialAccountingGroupOnChangeAtServer()

	CurrentRow = Object.ARAPDetails.FindByID(Items.ARAPDetails.CurrentRow);
	ClearCalculationObject(CurrentRow);

EndProcedure

&AtServer
Procedure ARAPDetailsPartnerOnChangeAtServer()

	CurrentRow = Object.ARAPDetails.FindByID(Items.ARAPDetails.CurrentRow);
	ClearCalculationObject(CurrentRow);

EndProcedure

&AtServer
Procedure UpdateAmountUnallocated()

	AmountUnallocated = CashServer.UnallocatedPaymentBalance(Object);
	ConfigureDependentFormElementsOnServer("AmountUnallocated");

EndProcedure

#EndRegion

#Region Other

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
EndProcedure

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtServerNoContext
Function GetBankAccountDetails(BankAccount)
	
	Return Catalogs.CompaniesBankAccounts.GetCompanySBankAccountDetails(BankAccount);
	
EndFunction

&AtServer
Procedure UpdateMirrorPaymentLabel()
	
	If Object.BusinessOperation <> Enums.BusinessTransactions.CashPaymentToAnotherCompany Then
		Return;
	EndIf;
	
	InvertedPaymentReference = Documents.BankAccountIssue.FindMirrorPayment(Object.Ref);
	
	If ValueIsFilled(InvertedPaymentReference) Then
		Items.LabelInvertedPayment.Hyperlink = True;
		CorrespondsToInvertedPayment = Documents.BankAccountIssue.CorrespondsToInvertedPayment(
			Object.Ref,InvertedPaymentReference);
		If CorrespondsToInvertedPayment Then
			Items.LabelInvertedPayment.TextColor = StyleColors.HyperlinkColor;
			LabelInvertedPayment = InvertedPaymentReference;
		Else
			Items.LabelInvertedPayment.TextColor = StyleColors.TextColorWarning;
			LabelInvertedPayment = StrTemplate(NStr("vi = '%1 (có sự khác biệt)';
													|ru = '%1 (есть различия)';
													|en = '%1 (there are differences)'; fa = '%1 (there are differences)';
													|it = '%1 (ci sono differenze)';
													|pl = '%1 (są różnice)';
													|tr = '%1 (farklılıklar bulunuyor)'"),InvertedPaymentReference);
		EndIf;
	Else
		Items.LabelInvertedPayment.TextColor = StyleColors.TextColorWarning; 
		Items.LabelInvertedPayment.Hyperlink = False;
		LabelInvertedPayment = NStr("vi = '<Không tìm thấy dòng tiền.>';
									|ru = '<Поступление безналичных денежных средств не найдено.>';
									|en = '<""Incoming payment — Bank account"" is not found.>'; fa = '<""Incoming payment — Bank account"" is not found.>';
									|it = '<L''entrata dei mezzi monetari cashless non è stata trovata.>';
									|pl = '<Nie znaleziono wpływu bezgotówkowych środków pieniężnych.>';
									|tr = '<Gelen ödeme - banka hesabı bulunamadı.>'");
	EndIf;
	
EndProcedure

&AtClient
Procedure AlignMirrorPaymentCompletion(QuestionResult, InvertedPaymentOffsetBetweenCompanies) Export
	
	ResponseCode = QuestionResult;
	If ResponseCode = DialogReturnCode.Yes Then
		AlignMirrorPaymentOnServer();
	Else
		UpdateMirrorPaymentLabel();
	EndIf;
	
EndProcedure

&AtServer
Procedure AlignMirrorPaymentOnServer()
	
	MirrorPaymentObject = InvertedPaymentReference.GetObject();
	Success = Documents.BankAccountIssue.AlignMirrorPayment(Object.Ref, MirrorPaymentObject);
	
	If Success Then
		Try
			MirrorPaymentObject.Write(?(MirrorPaymentObject.Posted, DocumentWriteMode.Posting, DocumentWriteMode.Write));
			UpdateMirrorPaymentLabel();
		Except
			WriteLogEvent(
				NStr("vi = 'Chi tiền từ tài khoản ngân hàng, thay đổi phản chiếu chứng từ liên quan.';
					|ru = 'Списание безналичных денежных средств, зеркальное изменение связанного документа.';
					|en = '""Outgoing payment — Bank account"", inverted change of related document.'; fa = '""Outgoing payment — Bank account"", inverted change of related document.';
					|it = 'Storno dei mezzi monetari cashless, cambiamento speculare del documento associato.';
					|pl = 'Wpływ bezgotówkowych środków pieniężnych, zmiana lustrzana powiązanego dokumentu.';
					|tr = 'Giden ödeme - banka hesabı, ilgili belgenin yansıtma değişimi'",
					CommonClientServer.DefaultLanguageCode()),
				EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
			Raise;
		EndTry;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetPossibleRecipientAccountValues(ChangeRecipientAccount = True)
	
	Query = New Query("
	|SELECT ALLOWED
	|	BankAccounts.Ref AS Ref
	|FROM
	|	Catalog.CompaniesBankAccounts AS BankAccounts
	|
	|WHERE
	|	(BankAccounts.CashCurrency = &Currency OR NOT &SelectByCurrency)
	|	AND (BankAccounts.CashCurrency <> &Currency OR NOT &SelectByConversionCurrency)
	|	AND (BankAccounts.Owner IN (&Owner) OR NOT &SelectByOwner)
	|	AND BankAccounts.Owner NOT IN (&OwnerFilter_)
	|	AND BankAccounts.Ref <> &SenderBankAccount
	|	AND (NOT BankAccounts.Closed
	|		OR (BankAccounts.Ref = &RecipientSCurrentBankAccount AND &DocumentWritten))
	|");
	
	Query.SetParameter("SenderBankAccount", Object.BankAccount);
	Query.SetParameter("SelectByConversionCurrency", False);
	Query.SetParameter("RecipientSCurrentBankAccount", Object.BankAccountBeneficiary);
	Query.SetParameter("DocumentWritten", ValueIsFilled(Object.Ref));
	
	If Object.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion Then
		
		If ValueIsFilled(Object.CurrencyOfConversion) Then
			Query.SetParameter("Currency", Object.CurrencyOfConversion);
			Query.SetParameter("SelectByCurrency", True);
		Else
			Query.SetParameter("Currency", Object.Currency);
			Query.SetParameter("SelectByCurrency", False);
			Query.SetParameter("SelectByConversionCurrency", True);
		EndIf;
	Else
		Query.SetParameter("Currency", Undefined);
		Query.SetParameter("SelectByCurrency", False);
	EndIf;
	
	If (Object.BusinessOperation = Enums.BusinessTransactions.TransferCashToAnotherAccount
		Or Object.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion)
		And ValueIsFilled(Object.BankAccount)
		And ValueIsFilled(Object.Organization) Then
		
		Query.SetParameter("Owner", Object.Organization);
		Query.SetParameter("SelectByOwner", True);
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices Then
		
		ArrayOfInterconnectedOrganizations = Catalogs.Companies.ArrayOfInterconnectedOrganizations(Object.Organization);
		Query.SetParameter("Owner", ArrayOfInterconnectedOrganizations);
		Query.SetParameter("SelectByOwner", True);
	Else
		
		Query.SetParameter("Owner", Undefined);
		Query.SetParameter("SelectByOwner", False);
	EndIf;
	
	Query.SetParameter("OwnerFilter_", Undefined);
	
	If (Object.BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany
		Or Object.BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany) Then
		
		If ValueIsFilled(Object.BankAccount)
			And ValueIsFilled(Object.Organization) Then
		
			ArrayOfInterconnectedOrganizations = Catalogs.Companies.ArrayOfInterconnectedOrganizations(Object.Organization);
			ArrayOfInterconnectedOrganizations.Add(Object.Organization);
			Query.SetParameter("OwnerFilter_", ArrayOfInterconnectedOrganizations);
		EndIf;
	EndIf;
	
	ArrayOfRecipientAccounts = Query.Execute().Unload().UnloadColumn("Ref");
	Items.BankAccountBeneficiary.ChoiceList.LoadValues(ArrayOfRecipientAccounts);
	
	If ChangeRecipientAccount Then
		If ArrayOfRecipientAccounts.Count() = 1 Then
			
			Object.BankAccountBeneficiary = ArrayOfRecipientAccounts[0];
			OnChangingRecipientSBankAccount();
			
		ElsIf ValueIsFilled(Object.BankAccountBeneficiary)
			And ArrayOfRecipientAccounts.Find(Object.BankAccountBeneficiary) = Undefined Then
			
			Object.BankAccountBeneficiary = Catalogs.CompaniesBankAccounts.EmptyRef();
			OnChangingRecipientSBankAccount();
			
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessingSelectionFromApplications(AddressOfRequestsInRepository)
	
	Object.PaymentByRequests = True;
	
	PaymentTable_3 = GetFromTempStorage(AddressOfRequestsInRepository);
	
	TheStructureOfTheSearch = New Structure;
	
	ArrayOfAllProps = New Array; ArrayOfOperationDetails = New Array;
	Documents.BankAccountIssue.FillInNamesOfBusinessTransactionDetails(
		Object, ArrayOfAllProps, ArrayOfOperationDetails);
	
	For Each OperationAttribute In ArrayOfOperationDetails Do
		Pos = StrFind(OperationAttribute, "ARAPDetails.");
		CharsCount = StrLen("ARAPDetails");
		If Pos Then
			TheStructureOfTheSearch.Insert(Mid(OperationAttribute, Pos + CharsCount + 1));
		EndIf;
	EndDo;
	
	CalculationObjectsAreUsed = Items.ARAPDetailsSelectionByStock.Visible;
	If CalculationObjectsAreUsed Then
		TheStructureOfTheSearch.Insert("ARAPObject");
	EndIf;
	
	
	For Each PaymentLine_1 In PaymentTable_3 Do
		
		FillPropertyValues(TheStructureOfTheSearch, PaymentLine_1);
		
		If CommonClientServer.HasAttributeOrObjectProperty(TheStructureOfTheSearch, "Organization")
			And Not ValueIsFilled(TheStructureOfTheSearch.Organization) Then
			TheStructureOfTheSearch.Organization = Catalogs.Companies.EmptyRef();
		EndIf;
		
		If Object.ListOfCounterparties_ Then
			
			If Not ValueIsFilled(TheStructureOfTheSearch.Counterparty) Then
				FillPropertyValues(TheStructureOfTheSearch, TheStructureOfTheSearch.ARAPObject, "Counterparty");
			EndIf;
			
		EndIf;
		
		Rows = Object.ARAPDetails.FindRows(TheStructureOfTheSearch);
		
		If Rows.Count() = 0 Then
			AddLineOfDecryptionOnRequest(PaymentLine_1, TheStructureOfTheSearch);
			
			
		EndIf;
	EndDo;
	
	CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object, , True);
	ProcessIPChange();
	GLAccountSettingsServer.UpdateSettingsPresentation(ThisObject, "Object.ARAPDetails");
	Object.DocumentAmount = Object.ARAPDetails.Total("Sum");
	
	UpdateInformationOnApplications();
	
	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	ConfigureDependentFormElementsOnServer("PaymentByRequests");
	
EndProcedure

//++ WE
&AtServer
Procedure ProcessingListSelection(SelectionResult)
	
	FilterParameters = New Structure();
	FilterParameters.Insert("Individual", Object.AdvanceHolder);
	FilterParameters.Insert("BankAccount", Object.CounterpartyBankAccount);
	
	DataOfStatement = IntegrationPayrollAndHumanResourcesServer.DataOfStatement(SelectionResult, FilterParameters);
	DataOfStatement.Table.GroupBy("Individual", "Sum");
	If DataOfStatement.Table.Count() = 0 Then
		ErrorText = StrTemplate(NStr("vi = 'Trong bảng thanh toán đã chọn không có dữ liệu theo nhân viên ""%1"" với tài khoản ngân hàng đã chọn';
									|ru = 'В выбранной ведомости нет данных по сотруднику ""%1"" с выбранным банковским счетом';
									|en = 'There is no data on employee ""%1"" with the selected bank account in the selected paysheet'; fa = 'There is no data on employee ""%1"" with the selected bank account in the selected paysheet';
									|it = 'There is no data on employee ""%1"" with the selected bank account in the selected paysheet';
									|pl = 'There is no data on employee ""%1"" with the selected bank account in the selected paysheet';
									|tr = 'Seçilen bordroda ""%1"" adlı çalışana ve seçilen banka hesabına ait veri bulunmuyor.'"),
		Object.AdvanceHolder);
		CommonClientServer.MessageToUser(ErrorText, ,"AdvanceHolder", "Object");
		Return;
	EndIf;

	DocObject = FormAttributeToValue("Object");
	
	HeaderAttributes = DataOfStatement.HeaderAttributes;
	If ValueIsFilled(HeaderAttributes.Department) Then
		DocObject.Department = HeaderAttributes.Department;
	EndIf;
	If ValueIsFilled(HeaderAttributes.DateOfPayment) Then
		DocObject.BankPostingDate = HeaderAttributes.DateOfPayment;
	EndIf;

	DocObject.ARAPDetails.Clear();
	NewDecryptionLine  = DocObject.ARAPDetails.Add();
	FillPropertyValues(NewDecryptionLine, DataOfStatement.Table[0]);
	NewDecryptionLine.Statement = HeaderAttributes.Statement;
	NewDecryptionLine.CashFlowItem = Catalogs.CashFlowReportItems.CashFlowItemForBusinessTransaction(
	DocObject.BusinessOperation);

	DocObject.DocumentAmount = DocObject.ARAPDetails.Total("Sum");
	
	ValueToFormAttribute(DocObject, "Object");

EndProcedure
//-- WE

&AtServer
Procedure SetHeadingIncomeExpenseItem()
	
	If Not GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities") Then
		Items.DecodingWithoutSplittingTheCostItem.Title = NStr("vi = 'Dạng chi phí';
																|ru = 'Статья расходов';
																|en = 'Expense item'; fa = 'قلم هزینه';
																|it = 'Voce di spese';
																|pl = 'Rodzaj kosztu';
																|tr = 'Gider kalemi'");
		Items.ARAPDetailsExpenseItem.Title      = NStr("vi = 'Dạng chi phí';
														|ru = 'Статья расходов';
														|en = 'Expense item'; fa = 'قلم هزینه';
														|it = 'Voce di spese';
														|pl = 'Rodzaj kosztu';
														|tr = 'Gider kalemi'");
	EndIf;
	
EndProcedure

&AtServer
Procedure GenerateHyperlinkCaptionPaymentObjectDetails()
	CashServer.GenerateHyperlinkCaptionPaymentObjectDetails(ThisForm, Object);
EndProcedure

&AtServer
Function PlaceDecryptionInTemporaryStorage()
	Return PutToTempStorage(Object.ARAPDetails.Unload());
EndFunction

&AtClientAtServerNoContext
Function LabelInstructionCodes(Object)
	
	CodesOfInstructionsForBank = "";
	
	If Object.InstructionsForBank.Count() Then
		CodesOfInstructionsForBank = NStr("vi = 'Hướng dẫn gửi ngân hàng:';
											|ru = 'Инструкции банку:';
											|en = 'Instructions for bank:'; fa = 'Instructions for bank:';
											|it = 'Istruzioni alla banca:';
											|pl = 'Instrukcje dla banku:';
											|tr = 'Bankaya talimatlar:'") + " ";
		For Each InstructionLine In Object.InstructionsForBank Do
			CodesOfInstructionsForBank = CodesOfInstructionsForBank + String(InstructionLine.Instruction) + ", ";
		EndDo;
		CodesOfInstructionsForBank = Left(CodesOfInstructionsForBank, StrLen(CodesOfInstructionsForBank) - 2);
	Else
		CodesOfInstructionsForBank = NStr("vi = '<Chỉ dẫn cho ngân hàng>';
											|ru = '<Указать инструкции банку>';
											|en = '<Specify instructions for bank>'; fa = '<Specify instructions for bank>';
											|it = '<Specificare istruzioni alla banca>';
											|pl = '<Przekaż instrukcje do banku>';
											|tr = '<Bankaya talimatları belirtin>'");
	EndIf;
	
	Return CodesOfInstructionsForBank;
	
EndFunction

&AtClientAtServerNoContext
Function LabelInformationForRegulatoryAuthorities(Object)
	
	InformationForRegulatoryBodies = NStr("vi = 'Đối với bộ điều chỉnh (77B):';
											|ru = 'Для регулятора (77B):';
											|en = 'For controller (77V):'; fa = 'For controller (77V):';
											|it = 'Per il regolatore (77B):';
											|pl = 'Dla regulatora (77B):';
											|tr = 'Regülatör (77B) için:'");
	
	If ValueIsFilled(Object.InformationForRegulatoryBodies) Then
		InformationForRegulatoryBodies = InformationForRegulatoryBodies + " " + Object.InformationForRegulatoryBodies;
	Else
		InformationForRegulatoryBodies = InformationForRegulatoryBodies + " " + NStr("vi = '<Chỉ định>';
																					|ru = '<Указать>';
																					|en = '<Specify>'; fa = '<Specify>';
																					|it = '<indicare>';
																					|pl = '<podaj>';
																					|tr = '<Belirt>'");
	EndIf;
	
	Return InformationForRegulatoryBodies;
	
EndFunction

&AtServer
Procedure RecalculateConversionParameters(Var_AttributeName)
	
	ConversionParameters_SSLy = CashServer.InitializeConversionParameters();
	FillPropertyValues(ConversionParameters_SSLy, Object);
	ConversionParameters_SSLy.CurrencyOfComplianceAccounting = CurrencyOfComplianceAccounting;
	
	CashServer.CalculateConversionParameters(ConversionParameters_SSLy, Var_AttributeName);
	FillPropertyValues(Object, ConversionParameters_SSLy);
	
EndProcedure

&AtServer
Function AccountCorrespondsToOwner()
	
	Result = False;
	
	If (Object.BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder
		Or Object.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentToBankAccounts
		Or Object.BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToEmployee)
		And Not Object.TransferToEmployeeViaABank Then
		Result = Catalogs.CounterpartyBankAccounts.VerifyBankAccountHolder(
			Object.CounterpartyBankAccount, Object.AdvanceHolder);
	Else
		Result = Catalogs.CounterpartyBankAccounts.VerifyBankAccountHolder(
			Object.CounterpartyBankAccount, Object.Counterparty);
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Procedure BlockData_()
	LockDataForEdit(Object.Ref,,ThisForm.UUID);
EndProcedure

&AtServer
Procedure UnlockData()
	UnlockDataForEdit(,ThisForm.UUID);
EndProcedure

&AtClientAtServerNoContext
Function TitleOfAcquiringCommission(Sum, Currency, Rate1)
	
	Return NStr("vi = 'Phí ngân hàng';
				|ru = 'Комиссия';
				|en = 'Fee'; fa = 'کارمزد';
				|it = 'Commissione';
				|pl = 'Fee';
				|tr = 'Komisyon'") + " " + String(Sum) + " " + String(Currency) + " " + String(Rate1) + "%";
	
EndFunction

&AtServer
Procedure FillInCurrencyOfMutualSettlementsOfDocument()
	
	CashServer.FillInCurrencyOfMutualSettlementsOfDocument(ThisForm);
	CurrencyDecorationAndPaymentRate = CashServer.CurrencyLabelAndPaymentRate(ThisObject);
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtServer
Procedure FillInSettlementRate()
	
	For Each TSRow In Object.ARAPDetails Do
		FillInCourseAndMultiplicityInDecryptionLine(TSRow);
	EndDo;
	
	FillInCurrencyOfMutualSettlementsOfDocument();
	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	
EndProcedure

&AtServer
Procedure FillMultiplicityCourseWithText()
	
	For Each TSRow In Object.ARAPDetails Do
		CashServer.FormCourseDenominatorByText(TSRow, Object.Currency, CurrencyOfComplianceAccounting);
	EndDo;
	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	
EndProcedure

&AtServer
Procedure CalculateAmountOfSettlements_()
	
	For Each TSRow In Object.ARAPDetails Do
		CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
			TSRow, Object.Currency, CurrencyOfComplianceAccounting);
	EndDo;
	
	CashServer.CalculateAmountsInSenderSCurrencyInDecryption(Object, BankAccountCurrency);
	
EndProcedure

&AtServer
Procedure SetVisibilityOfGiftCertificateSelectionButton()
	
	SaleOfGiftCertificateIsAllowed =
		RetailSalesLocalization.ItIsAllowedToSellGiftCertificateInDocument(Object.BusinessOperation);
	Items.ARAPDetailsPickUpGiftCertificate.Visible = SaleOfGiftCertificateIsAllowed;
	
EndProcedure

&AtServer
Procedure ProcessGiftCertificate(GiftCertificate)
	
	FoundRow = GiftCertificatesServer.AddGiftCertificateToTablePartOfPaymentDecryption(GiftCertificate, ThisObject);
	If FoundRow <> Undefined Then
		
		Modified = True;
		
		UpdateTaxRateRecalculateVATAmount(FoundRow.GetID());
		
		DecryptionOfTheCalculationObjectWhenChangingServer(FoundRow.GetID());
		
		SetRestrictionOnTypeOfPaymentDecryptionContract();
		GenerateHyperlinkCaptionPaymentObjectDetails();
		SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning();
		
		FillInCourseAndMultiplicityInDecryptionLine(FoundRow);
		CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
			FoundRow, Object.Currency, CurrencyOfComplianceAccounting);
		CashServer.FormCourseDenominatorByText(FoundRow, Object.Currency, CurrencyOfComplianceAccounting);
		FillInCurrencyOfMutualSettlementsOfDocument();
		CashServer.SetDesignAccuracyOfCourse(ThisObject);
		
		CashServer.CalculateAmountsInSenderSCurrencyInDecryption(Object, BankAccountCurrency);
		
		ConfigureDependentFormElementsOnServer();
	EndIf;

EndProcedure

&AtServer
Procedure TransferToEmployeeViaABankOnChange_Server()

	TransferToEmployeeViaABankOnChangeServer();
	DisplayingTitleOfAccountablePersonField();
	CashServer.SetParametersForSelectingCounterpartySBankAccount(Object, Items.CounterpartyBankAccount);
	ConfigureDependentFormElementsOnServer("TransferToEmployeeViaABank");

EndProcedure

// Sets the inscription on the availability of the document "Crediting DS to personal accounts"
//
&AtServer
Procedure SetInscriptionOfDSEnrollment()

	AvailabilityOfCashTransferDocument = CashServer.ThereAreDepositsOfDSToPersonalAccounts(Object.Ref);
	Items.DecorationAbsenceOfCashCreditingToAccounts.Title = ?(AvailabilityOfCashTransferDocument, "",
						NStr("vi = 'Cần kết nhập dữ liệu ghi có tiền vào tài khoản cá nhân';
							|ru = 'Требуется загрузить данные о зачислении денежных средств на лицевые счета';
							|en = 'Import data of bank receipt to personal accounts'; fa = 'Import data of bank receipt to personal accounts';
							|it = 'È richiesto il download dei dati di accedito dei fondi su conti personali';
							|pl = 'Należy przesłać dane o zaliczeniu środków pieniężnych na rachunki osobiste';
							|tr = 'Kredilendirme fonlarına ilişkin verilerin kişisel hesaplara yüklenmesi gerekir'"));

EndProcedure

&AtServer
Function StringOfExcludedPropertiesByContract(PaymentDecryptionString, PropertiesByContract)
	
	ExcludedProperties = "";
	
	For Each CurrentProperty In PropertiesByContract Do
		
		If Not PaymentDecryptionString.Property(CurrentProperty.Key) Then
			Continue;
		EndIf;
		
		If Not ValueIsFilled(CurrentProperty.Value)
			And ValueIsFilled(PaymentDecryptionString[CurrentProperty.Key]) Then
			ExcludedProperties = ?(ExcludedProperties <> "", ExcludedProperties + ",", "") + CurrentProperty.Key;
		EndIf;
		
	EndDo;
	
	Return ExcludedProperties;
	
EndFunction

&AtClient
Procedure ReflectionsInLocalAccountingWhenChangesOccur(Result, AdditionalParameters) Export
	ReflectionsInLocalAccountingWhenChangesAreMadeOnServer();
EndProcedure

&AtServer
Procedure ReflectionsInLocalAccountingWhenChangesAreMadeOnServer()
	
	Return;
	
EndProcedure

&AtServer
Procedure FillInAttributesOfPaymentUnderLeaseContract(RowID)

	CurrentRow = Object.ARAPDetails.FindByID(RowID);
	
	ListOfAgreements = CommonClientServer.ValueInArray(CurrentRow.LeaseContracts);
	DataTable = DataOnLeaseContracts(ListOfAgreements);
	FoundRow = DataTable.Find(CurrentRow.LeaseContracts, "LeaseContracts");
	
	If FoundRow <> Undefined Then
		FillPropertyValues(CurrentRow, FoundRow, , "LeaseContracts");
	EndIf;
	
	ARAPDetailsLeaseContractsOnChangeServer();

EndProcedure

&AtServer
Procedure FillInAttributesOfPaymentUnderLeaseContracts()

	DecryptionTable = Object.ARAPDetails.Unload(, "LeaseContracts");
	ListOfAgreements = DecryptionTable.UnloadColumn("LeaseContracts");
	DataTable = DataOnLeaseContracts(ListOfAgreements);
	
	For Each DecryptionString In Object.ARAPDetails Do
		
		FoundRow = DataTable.Find(DecryptionString.LeaseContracts, "LeaseContracts");
		
		If ValueIsFilled(FoundRow) Then
			
			FillPropertyValues(DecryptionString, FoundRow);
			ARAPDetailsLeaseContractsOnChangeServer(DecryptionString.GetID());
			
		EndIf;
		
	EndDo;

EndProcedure

&AtServer
Function DataOnLeaseContracts(ListOfAgreements)

	Query = New Query;
	Query.Text = 
		"SELECT
		|	TermsOfLeaseContractsSliceLast.Contract AS Contract,
		|	TermsOfLeaseContractsSliceLast.VATRate AS VATRate
		|INTO DataOfContractsByConditionOfConclusion
		|FROM
		|	InformationRegister.TermsOfLeaseContracts.SliceLast(, Contract IN (&Contracts)) AS TermsOfLeaseContractsSliceLast
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	LeaseContract.Ref AS LeaseContracts,
		|	LeaseContract.CashFlowItem AS CashFlowItem,
		|	LeaseContract.ARAPCurrency AS ARAPCurrency,
		|	DataOfContractsByConditionOfConclusion.VATRate AS VATRate
		|FROM
		|	Catalog.LeaseContract AS LeaseContract
		|		LEFT JOIN DataOfContractsByConditionOfConclusion AS DataOfContractsByConditionOfConclusion
		|		ON LeaseContract.Ref = DataOfContractsByConditionOfConclusion.Contract
		|WHERE
		|	LeaseContract.Ref IN(&Contracts)";
	
	Query.SetParameter("Contracts", ListOfAgreements);
	
	Return Query.Execute().Unload();

EndFunction

&AtClient
Procedure DocumentAmountOnChangeClient()
	
	FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, Object.DocumentAmount, False);
	
EndProcedure

&AtClient
Procedure SelectionByResiduesProcessing(CompletionProcedure)
	
	IntercompanyPayment =
		(Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.CashPaymentToAnotherCompany")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RefundToAnotherCompany"));
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.CheckedAttributes.Insert("BankAccount",  NStr("vi = 'Tài khoản';
																	|ru = 'Счет';
																	|en = 'Account'; fa = 'حساب';
																	|it = 'Счет';
																	|pl = 'Account';
																	|tr = 'Hesap'"));
	
	If IntercompanyPayment Then
		CheckParameters.CheckedAttributes.Insert("BankAccountBeneficiary", NStr("vi = 'Người nhận';
																				|ru = 'Получатель';
																				|en = 'Payee'; fa = 'ذی‌نفع';
																				|it = 'Получатель';
																				|pl = 'Payee';
																				|tr = 'Alıcı'"));
	Else
		If Not Object.ListOfCounterparties_ Then
			CheckParameters.CheckedAttributes.Insert("Counterparty", NStr("vi = 'Đối tác';
																			|ru = 'Контрагент';
																			|en = 'Counterparty'; fa = 'طرف حساب';
																			|it = 'Контрагент';
																			|pl = 'Counterparty';
																			|tr = 'Cari hesap'"));
		EndIf;
	EndIf;
	
	Notification = New CallbackDescription("SelectionBasedOnBalancesAfterVerification", ThisObject,
		New Structure("IntercompanyPayment, CompletionProcedure", IntercompanyPayment, CompletionProcedure));
		
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisObject, Notification, CheckParameters);
	
EndProcedure

&AtServer
Procedure WhenChangingCounterparty(
	Counterparty,
	CounterpartyBankAccount,
	FillInTranscriptForCounterparty = True,
	CurPartner = Undefined,
	CurrentDecryptionLine = Undefined) Export

	If FillInTranscriptForCounterparty Then
	
		If CurPartner = Undefined Then
			Partner = CashServer.GetCounterpartyPartner(Counterparty, Object.BusinessOperation);
		Else
			Partner = CurPartner;
		EndIf;
		
		GetDefaultContractServer(Counterparty, CounterpartyBankAccount);
		
		If ValueIsFilled(CounterpartyContract) Then
			ARAPObjectContract = ARAPObjectsServer.GetCalculationObjectFromLink(CounterpartyContract)
		EndIf;
		
		StructureOfActions = New Structure("RecalculateVATAmount", New Structure("PriceIncludesVAT", True));
		
		If CurrentDecryptionLine = Undefined Then
		
			For Each TSRow In Object.ARAPDetails Do
				FillInPaymentTranscript(TSRow, ARAPObjectContract);
			EndDo;
			
			BatchProcessingOfTablePartServer.TreatTS(Object.ARAPDetails, StructureOfActions, Undefined);
		
		Else
		
			FillInPaymentTranscript(CurrentDecryptionLine, ARAPObjectContract);
			BatchProcessingOfTablePartServer.ProcessTSString(CurrentDecryptionLine, StructureOfActions, Undefined);
		
		EndIf;
		
		FillInCurrencyOfMutualSettlementsOfDocument();
		
		If Not ValueIsFilled(CounterpartyContract) Then
			CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object, , True);
			ProcessIPChange();
		EndIf;
		
		CashServer.SetParametersForSelectingLoanDepositAgreement(
			Object, Items.ARAPDetailsLoanDepositContract);
		CashServer.SetParametersForSelectingLoanDepositAgreement(
			Object, Items.DecryptionWithoutSplittingTheLoanDepositAgreement);
		CashServer.SetParametersForSelectingLeaseAgreement(
			Object, Items.ARAPDetailsLeaseContracts);
		CashServer.SetParametersForSelectingLeaseAgreement(
			Object, Items.DecryptionWithoutSplittingTheLeaseAgreement);
	EndIf;

EndProcedure

&AtServer
Procedure FillInPaymentTranscript(CurrentTableRow, ARAPObjectContract)

	If Not Object.ListOfCounterparties_ Then
		CurrentTableRow.Counterparty = Object.Counterparty;
	EndIf;
	
	CurrentTableRow.Partner = Partner;
	CurrentTableRow.ARAPCurrency = ARAPCurrency;
	
	If ValueIsFilled(CounterpartyContract) Then
		
		CurrentTableRow.ARAPObject = ARAPObjectContract;
		CurrentTableRow.CashFlowItem = Object.CashFlowItem;
		CurrentTableRow.VATRate = VATRate;
		DecryptionOfTheCalculationObjectWhenChangingServer(CurrentTableRow.GetID());
		FillInUIP(CurrentTableRow.GetID());
		
	EndIf;
	
	CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
		CurrentTableRow, Object.Currency, CurrencyOfComplianceAccounting);
	FillInCourseAndMultiplicityInDecryptionLine(CurrentTableRow);
	CashServer.FormCourseDenominatorByText(CurrentTableRow, Object.Currency, CurrencyOfComplianceAccounting);
	CashServer.SetDesignAccuracyOfCourse(ThisObject);

EndProcedure

&AtServer
Procedure TransferToEmployeeViaABankOnChangeServer()
	
	Object.TransferToEmployeeViaABank = Boolean(TransferToEmployeeViaABank);
	
	If PaymentToOneIndividual() Then
		
		Object.Counterparty = Catalogs.Counterparties.EmptyRef();
		Object.CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(Object.AdvanceHolder, Object.Currency);
		
	Else
		
		If Object.PersonsList Then
			
			CurrentCurrency = Object.Currency;
			Object.Currency = Common.ObjectAttributeValue(Object.BankAccount, "CashCurrency");
			
		EndIf;
		
		Object.CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(Object.Counterparty, Object.Currency);
		
	EndIf;

EndProcedure

&AtServer
Procedure YouAreAllowedToWorkWithAffiliatedPartners(TableRow)
	
	ReferencesArrray = CommonClientServer.ValueInArray(TableRow.ARAPObject);
	ComplianceOfContractCurrencyExchangeRate = ARAPAccountingServer.ComplianceOfARAPObjectsAndParametersOfContract(ReferencesArrray);
	TableRow.ItIsAllowedToWorkWithSubsidiaryPartners = ComplianceOfContractCurrencyExchangeRate[TableRow.ARAPObject].ItIsAllowedToWorkWithSubsidiaryPartners;
	TableRow.TheCalculationObjectMatchesTheDocument = ComplianceOfContractCurrencyExchangeRate[TableRow.ARAPObject].Object = Object.Ref;
	
EndProcedure

&AtClient
Procedure CheckPossibilityOfFillingOutApplication(EventAfterVerification)

	ThisIsIssueToAnotherOrganization = (Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.CashPaymentToAnotherCompany"))
		Or (Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RefundToAnotherCompany"));
	ThisIsIssueToDebtor = (Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.IssueCashToAdvanceHolder"));
	ThisIsInternalTransfer = (Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices"));
	ThisIsLoanToEmployee = (Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.CashIssueAsLoanToEmployee"));
	ThisIsSalaryPayment = (Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SalaryPaymentToBankAccounts")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SalaryPaymentByPayrollCardProgram"));
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.CheckedAttributes.Insert("BankAccount", NStr("vi = 'Tài khoản ngân hàng';
																|ru = 'Банковский счет';
																|en = 'Bank account'; fa = 'حساب بانکی';
																|it = 'Conto corrente bancario';
																|pl = 'Rachunek bankowy';
																|tr = 'Banka hesabı'"));
	If ThisIsIssueToAnotherOrganization Then
		CheckParameters.CheckedAttributes.Insert("BankAccountBeneficiary", NStr("vi = 'Tài khoản ngân hàng người nhận';
																				|ru = 'Банковский счет получатель';
																				|en = 'Bank account payee'; fa = 'Bank account payee';
																				|it = 'Conto corente destinatario';
																				|pl = 'Konto bankowe odbiorca';
																				|tr = 'Banka hesabı alıcı'"));
	ElsIf (ThisIsIssueToDebtor Or ThisIsLoanToEmployee) Then
		
		If Not Object.PersonsList Then
			CheckParameters.CheckedAttributes.Insert("AdvanceHolder", NStr("vi = 'Người nhận tạm ứng';
																			|ru = 'Подотчетное лицо';
																			|en = 'Advance holder'; fa = 'تنخواه‌دار';
																			|it = 'Titolare di anticipo';
																			|pl = 'Osoba rozliczająca się za wydatki';
																			|tr = 'Sorumlu kişi'"));
		Else
			If Object.PersonalAccountsOfStaff.Count() = 0 Then
				ErrorText = StrTemplate(NStr("vi = 'Chưa điền bảng ""%1""';
											|ru = 'Таблица ""%1"" не заполнена';
											|en = 'The ""%1"" table is not filled'; fa = 'The ""%1"" table is not filled';
											|it = 'Таблица ""%1"" не заполнена';
											|pl = 'The ""%1"" table is not filled';
											|tr = 'Tablo ""%1"" doldurulmamış'"), Items.PersonalAccountsOfStaff.Name);
				CommonClient.MessageToUser(ErrorText, , "PersonalAccountsOfStaff", "Object");
				Return;
			EndIf;
		EndIf;
		
	ElsIf Not ThisIsInternalTransfer And Not ThisIsSalaryPayment And Not ThisIsIssueToDebtor And Not ThisIsLoanToEmployee Then
		CheckParameters.CheckedAttributes.Insert("Counterparty", NStr("vi = 'Đối tác';
																		|ru = 'Контрагент';
																		|en = 'Counterparty'; fa = 'طرف حساب';
																		|it = 'Контрагент';
																		|pl = 'Counterparty';
																		|tr = 'Cari hesap'"));
	EndIf;
	
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisObject, EventAfterVerification, CheckParameters);

EndProcedure

&AtClient
Procedure CompleteSelectionAccordingToListOfIndividuals(Filter)

	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.IssueCashToAdvanceHolder")
		And Object.PersonsList Then
		
		ListOfAccountablePersons = New Array;
		
		For Each TableRow In Object.PersonalAccountsOfStaff Do
			ListOfAccountablePersons.Add(TableRow.Individual);
		EndDo;
		
		Filter.Insert("AdvanceHolder", ListOfAccountablePersons);
		
	EndIf;

EndProcedure

&AtServer
Procedure ListOfIndividualsEnabledWhenChangedOnServer()

	PayerSCurrency = Common.ObjectAttributeValue(Object.BankAccount, "CashCurrency");
	
	If CurrentCurrency <> PayerSCurrency Then
		Object.Currency = PayerSCurrency;
	EndIf;
	
	RecipientSCurrency = Common.ObjectAttributeValue(Object.CounterpartyBankAccount, "CashCurrency");
	
	If Object.Currency <> RecipientSCurrency Then
		Object.CounterpartyBankAccount =
			Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(Object.Counterparty, Object.Currency);
	EndIf;
	
	If ValueIsFilled(Object.AdvanceHolder) Then
		
		NewRow = Object.PersonalAccountsOfStaff.Add();
		NewRow.Individual = Object.AdvanceHolder;
		NewRow.PersonalAccount = Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(Object.AdvanceHolder, Object.Currency);
		NewRow.Sum = Object.DocumentAmount;
		NewRow.CashFlowItem = Object.CashFlowItem;
		
	EndIf;
	
	If Not Object.PaymentByRequests Then
		PersonalAccountsOfEmployeesWhenChangedOnServer();
	EndIf;
	
	If Object.DepositKind = "" Then
		Object.DepositKind = "07";
	EndIf;

EndProcedure

&AtServer
Procedure FillInCurrencyOnRecipientSAccount(Account)

	RecipientSCurrency = Common.ObjectAttributeValue(Account, "CashCurrency");
	
	If Object.Currency <> RecipientSCurrency
		And (Object.PaymentWithConversion
		Or Not ValueIsFilled(Object.Currency))
		And ValueIsFilled(RecipientSCurrency) Then
		Object.Currency = RecipientSCurrency;
		SetPaymentWithConversionAttribute();
	EndIf;
	
	UpdateCurrencyData();

EndProcedure

&AtServer
Procedure ClearCalculationObject(DecryptionString)

	CashServer.ClearCalculationObject(Object, DecryptionString);

EndProcedure

&AtServer
Procedure AddLineOfDecryptionOnRequest(PaymentLine_1, AdditionalParameters)

	NewRow = Object.ARAPDetails.Add();
	FillPropertyValues(NewRow, PaymentLine_1);
	
	If Object.ListOfCounterparties_ Then
		FillPropertyValues(NewRow, AdditionalParameters, "Counterparty");
	EndIf;
	
	If Not ValueIsFilled(NewRow.Partner) Then
		If Not ValueIsFilled(Partner) Then
			GetDefaultServerPartner(Object.Counterparty, Partner, Object.BusinessOperation);
		EndIf;
		NewRow.Partner = Partner;
	EndIf;
	IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, NewRow, "Object.ARAPDetails");
	
	If IsBlankString(Object.PaymentID) And ValueIsFilled(PaymentLine_1.PaymentID) Then
		Object.PaymentID = PaymentLine_1.PaymentID;
	EndIf;
	
	ARAPDetailsARAPObjectOnChangeServer(NewRow.GetID());
	FillInCourseAndMultiplicityInDecryptionLine(NewRow);
	CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
		NewRow, Object.Currency, CurrencyOfComplianceAccounting);
	CashServer.FormCourseDenominatorByText(NewRow, Object.Currency, CurrencyOfComplianceAccounting);
	YouAreAllowedToWorkWithAffiliatedPartners(NewRow);
	
EndProcedure

&AtServer
Procedure SetPaymentWithConversionAttribute()

	CashServer.SetPaymentWithConversionAttribute(
		Object,
		"Document.BankAccountIssue");
	
	If Object.PaymentWithConversion Then
		
		Accounts = New Array;
		Accounts.Add(Object.CounterpartyBankAccount);
		Accounts.Add(Object.BankAccountBeneficiary);
		AccountCurrencies = Common.ObjectsAttributeValue(Accounts, "CashCurrency");
		
		If Object.Currency <> AccountCurrencies.Get(Object.CounterpartyBankAccount) Then
			
			If PaymentToOneIndividual() Then
				Object.CounterpartyBankAccount = 
					Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(Object.AdvanceHolder, Object.Currency);
			Else
				Object.CounterpartyBankAccount =
					Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(Object.Counterparty, Object.Currency);
			EndIf;
			
		EndIf;
		
		If Object.Currency <> AccountCurrencies.Get(Object.BankAccountBeneficiary) Then
			ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount();
			ParametersOfAccount.Currency = Object.Currency;
			Object.BankAccountBeneficiary = Catalogs.CompaniesBankAccounts.GetDefaultBankAccount(
				ParametersOfAccount);
		EndIf;
		
	EndIf;

	ConfigureDependentFormElementsOnServer("PaymentWithConversion");

EndProcedure

&AtServer
Function PaymentToOneIndividual()

	Return Not Object.TransferToEmployeeViaABank
		And (Object.BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder
		Or Object.BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToEmployee
		Or Object.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentToBankAccounts);

EndFunction

&AtClient
Procedure SetPaymentByRequestAttribute()

	If Not EnabledCreatingCashIssueWithoutPaymentRequest
		And ValueIsFilled(Object.BankAccount) Then
		Object.PaymentByRequests = True;
	ElsIf Not ValueIsFilled(Object.BankAccount) Then
		
		Object.PaymentByRequests = False;
		Object.PaymentRequest = Undefined;
		
		For Each String In Object.ARAPDetails Do
			String.PaymentRequest = Undefined;
		EndDo;
		
		UpdateInformationOnApplications();
		
	EndIf;

EndProcedure

&AtServer
Procedure FillInPaymentDecryptionLineUnderContract(DecryptionString, ContractDetails_)

	If TypeOf(Object.Contract) = Type("CatalogRef.IntercompanyContracts") Then
		FillPropertyValues(DecryptionString, ContractDetails_);
	Else
		ExcludeProperties = StringOfExcludedPropertiesByContract(DecryptionString, ContractDetails_);
		FillPropertyValues(DecryptionString, ContractDetails_, , ExcludeProperties);
	EndIf;
	
	DecryptionString.Contract = Object.Contract;
	
	FillInCourseAndMultiplicityInDecryptionLine(DecryptionString);
	CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
		DecryptionString, Object.Currency, CurrencyOfComplianceAccounting);
	CashServer.FormCourseDenominatorByText(DecryptionString, Object.Currency, CurrencyOfComplianceAccounting);
	CashServer.SetDesignAccuracyOfCourse(ThisObject);

EndProcedure

&AtServer
Function AmountOfBalanceOfApplication(RequestForPayment)

	Query = New Query;
	Query.Text = 
		"SELECT
		|	BalancesPayable.SumBalance AS SumBalance
		|FROM
		|	AccumulationRegister.CashToBePaid.Balance(, PaymentRequest = &Request) AS BalancesPayable";
	
	Query.SetParameter("Request", RequestForPayment);
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	
	If QueryResult.IsEmpty() Then
		Return 0;
	Else
		
		Selection = QueryResult.Select();
		Selection.Next();
		
		Return Selection.SumBalance;
		
	EndIf;

EndFunction

&AtServer
Procedure FillInUIP(IdOfDecryptionString)
	
	If Object.PaymentByRequests Or ValueIsFilled(Object.PaymentID) And DecryptionSwitch = 1 Then
		Return;
	EndIf;
	
	DecryptionString = Object.ARAPDetails.FindByID(IdOfDecryptionString);
	If ValueIsFilled(DecryptionString.PaymentID) Then
		Object.PaymentID = DecryptionString.PaymentID;
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessIPChange(DecryptionString = Undefined)
	
	If DecryptionString <> Undefined Then
		FillInUIPIndexIsDifferent(DecryptionString);
	Else
		For Each TSRow In Object.ARAPDetails Do
			FillInUIPIndexIsDifferent(TSRow);
		EndDo;
	EndIf;
	
	DefineUIPIsDifferent();
	
EndProcedure

&AtServer
Procedure DefineUIPIsDifferent()
	
	UIPIsDifferent = Not Object.PaymentByRequests And Object.ARAPDetails.Total("UIPIndexIsDifferent") <> 0;
	ConfigureDependentFormElementsOnServer("UIPIsDifferent");
	
EndProcedure

&AtServer
Procedure FillInUIPIndexIsDifferent(DecryptionString)
	
	If ValueIsFilled(Object.PaymentID)
		And ValueIsFilled(DecryptionString.PaymentID)
		And DecryptionString.PaymentID <> Object.PaymentID Then
		DecryptionString.UIPIndexIsDifferent = 1;
	Else
		DecryptionString.UIPIndexIsDifferent = 0;
	EndIf;
	
EndProcedure

// The Contract of the fee settlement object.
// 
// Parameters:
//  ARAPObject - CatalogRef.ARAPObjects
// 
// Returns:
//  CatalogRef.CounterpartyContracts
//
&AtServerNoContext
Function ContractARAPObjectOfFee(Val ARAPObject)

	Return Common.ObjectAttributeValue(ARAPObject, "Contract");
	
EndFunction

&AtServer
Procedure FillInContractFeeSVObjectOfSettlementARAPObject()
	
	If Not ValueIsFilled(Object.Organization)
		Or Not ValueIsFilled(Object.Counterparty)
		Or Not ValueIsFilled(Object.Currency) Then
		CommissionAgreement = Catalogs.CounterpartyContracts.EmptyRef();
	EndIf;

	If ValueIsFilled(CommissionAgreement) Then
		
		ContractDetails_ = Common.ObjectAttributesValues(CommissionAgreement,
			"Organization, Counterparty, ARAPCurrency");
		
		Clear_Contract = (Object.Organization <> ContractDetails_.Organization
			Or Object.Counterparty <> ContractDetails_.Counterparty
			Or Object.Currency <> ContractDetails_.ARAPCurrency);
		
		If Clear_Contract Then
			CommissionAgreement = Catalogs.CounterpartyContracts.EmptyRef();
		EndIf;
	EndIf;

	Object.CommissionARAPObject = ?(ValueIsFilled(CommissionAgreement),
		ARAPObjectsServer.GetCalculationObjectFromLink(CommissionAgreement), Catalogs.ARAPObjects.EmptyRef());

EndProcedure

&AtClient
Function FormsOfPaymentForApplicationsForNonCashPayment()

	If ConnectedHandlersLocalization Then
		Return CashClientServerLocalization.FormsOfPaymentForApplicationsForNonCashPayment();
	EndIf;
	
	PaymentForms = New Array;
	
	PaymentForms.Add(PredefinedValue("Enum.PaymentForms.BankAccountPayment"));
	PaymentForms.Add(PredefinedValue("Enum.PaymentForms.EmptyRef"));
	
	Return PaymentForms;

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
	ElsIf Item.Name = "sh_ShamsiInput_BankPostingDate" Then
		BankPostingDateOnChange(Items.BankPostingDate);
	ElsIf Item.Name = "sh_ShamsiInput_BankContractDate" Then
		DetailsOfContractWithBankWhenChanging(Items.BankContractDate);
	ElsIf Item.Name = "sh_ShamsiInput_PaysheetDate" Then
		DateOnChange(Items.PaysheetDate);
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
