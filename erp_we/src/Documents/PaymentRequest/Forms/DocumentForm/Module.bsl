#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

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
	
	ItemsAndDimensionsSelectionParameters =
		Documents.PaymentRequest.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		
		If Parameters.Property("Basis") Then
			Basis = Parameters.Basis;
		EndIf;
		
		If ValueIsFilled(Parameters.CopyingValue) Then
			Object.Closed_ = False;
		EndIf;
		
		CashServer.CheckFillOutContract(Object);
	EndIf;
	
	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisForm);
	
	Items.DecryptionWithoutSplittingRepaymentDate.ReadOnly = Not AccessRight(
		"Edit",
		Metadata.Documents.PaymentRequest.TabularSections.ARAPDetails.Attributes.MaturityDate);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	SetupParameters = Documents.PaymentRequest.AccountingAccountSettings_(
		Object.BusinessOperation, Object.TaxType);
	GLAccountSettingsServer.OnCreateAtServer(ThisObject, SetupParameters);
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	If Not ValueIsFilled(Object.Ref) Then
		
		FinancesClient.CheckDocumentCompletionBasedOn(Object, Basis);
		
		CurrentDate = Object.Date;
		
		If ExpenseReportPeriod = NStr("vi = 'Qua tuần';
										|ru = 'Через неделю';
										|en = 'In a week'; fa = 'In a week';
										|it = 'Tra una settimana';
										|pl = 'Za tydzień';
										|tr = 'Bir hafta sonra'") Then
			Object.ExpenseReportDate = ?(ValueIsFilled(Object.PaymentDate), Object.PaymentDate, CurrentDate()) + 7 * 24 * 3600;
		EndIf;
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// The end of the standard subsystem.Pluggable commands
	// Standard subsystems.Worksfiles
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	ItemsAndDimensionsSelectionParameters =
		Documents.PaymentRequest.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation);
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	OnReadCreateAtServer();
	
	ARAPAccountingFormWork.FormWhenReadingOnServer(ThisForm);
	
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	//Setting up accounting accounts
	SetupParameters = Documents.PaymentRequest.AccountingAccountSettings_(
		Object.BusinessOperation, Object.TaxType);
	GLAccountSettingsServer.OnReadAtServer(ThisObject, SetupParameters);
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectionResult, ChoiceSource)
	
	If Window <> Undefined Then
		Window.Activate();
	EndIf;
	
	//++ WE
	If ChoiceSource.FormName = "Document.PayrollStatementHR.Form.ChoiceForm" Then
		
		Modified = True;
		
		CurrentData = Items.ARAPDetails.CurrentData;
		CurrentSourceData = ChoiceSource.CurrentItem.CurrentData;
		CurrentData.Sum = CurrentSourceData.SumByDocument;
		If ValueIsFilled(CurrentSourceData.Department) Then
			Object.Department = CurrentSourceData.Department;
		EndIf;
		CurrentData.Statement = SelectionResult;
		CurrentData.ARAPCurrency = Object.Currency;
		CurrentData.ExchangeRateNumeratorOfMutualSettlements = 1;
		CurrentData.TheExchangeRateIsTheDenominatorOfMutualSettlements = 1;
		
		Items.ARAPDetails.EndEditRow(False);
		Object.DocumentAmount = Object.ARAPDetails.Total("Sum");
	EndIf;
	//-- WE
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Subsystem "Properties"
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	If EventName = "Write_BankAccountIssue"
		Or EventName = "Write_CashVoucher"
		Or EventName = "Write_PaymentCardTransaction" Then
		FillInPaymentDetailsForApplication();
	EndIf;

	If EventName = "GiftCertificateIsRead"
		And Parameter.OwnerForm = UUID Then
		
		ProcessGiftCertificate(Parameter.GiftCertificate);
	EndIf;
		
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
	If Not DecryptionSwitch Then
		
		DocumentObject = FormAttributeToValue("Object");
		DocumentObject.AdditionalProperties.Insert("ExplanationWithoutSplit", True);
		
		If Not DocumentObject.CheckFilling() Then
			Cancel = True;
		EndIf;
		
		CheckedAttributes.Clear();
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SalaryPayment")
		And Not UsePayrollTM
		And Object.PayrollTransaction = PredefinedValue("Enum.BusinessTransactions.SalaryPaymentToBankAccounts")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.IssueCashToAdvanceHolder")
			And Object.PersonsList Then
		TabularSection = "PersonalAccountsOfStaff";
	Else
		TabularSection = "ARAPDetails";
	EndIf;
	
	If NotExecuteCheck1BeforeWrite Then
		NotExecuteCheck1BeforeWrite = False;
		Return;
	EndIf;
		
	If WriteParameters.WriteMode = DocumentWriteMode.Posting Then
		
		Cancel = True;
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("WriteParameters", WriteParameters);
		
		FinancesClient.RecalculateAmountOfDocumentBasedOnPaymentDecryption(
			ThisForm,
			New CallbackDescription("BeforeRecordingOfferToRecalculateAmountOfDocument", ThisObject, AdditionalParameters),
			TabularSection);
		Return;
	EndIf;
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters, Cancel);
	
EndProcedure

&AtClient
Procedure BeforeRecordingOfferToRecalculateAmountOfDocument(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult Then
		TMCommonUseClient.RecordObjectIfNecessary(ThisObject, AdditionalParameters.WriteParameters,,True);
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Handler of the "Properties" subsystem
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	
	ARAPAccountingServer.BeforeWriteAtServer(ThisForm, CurrentObject);
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	GLAccountSettingsServer.BeforeWriteAtServer(ThisObject, CurrentObject);
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	GLAccountSettingsServer.AfterWriteAtServer(ThisObject);
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	ARAPAccountingFormWork.FormAfterRecordingOnServer(ThisForm, CurrentObject.AdditionalProperties);
	
	CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object, , True);
	FillInParametersOfCalculationObjectInDecryption();
	FillInCurrencyOfMutualSettlementsOfDocument();
	FillMultiplicityCourseWithText();
	
	FillInPaymentDetailsForApplication();
	CompleteVATTaxation(False);
	
	SetRestrictionOnTypeOfPaymentDecryptionContract();
	
	ConfigureDependentFormElementsOnServer();
	
	UnlockFormDataForEdit();
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	ConfigureDependentFormElements("Modified");
	
	// Used for automatic updating of the payment calendar form
	Notify("Write_PaymentRequest", WriteParameters, Object.Ref);
	
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
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	ForceCloseTheForm = True;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	ProcessingIsRequired = DateOnChangeClient();
	
	If ProcessingIsRequired Then
		DateOfChangeOnServer();
	EndIf;
	
	CurrentDate = Object.Date;
	
EndProcedure

&AtServer
Procedure DateOfChangeOnServer()
	
	FillInSettlementRate();
	CalculateAmountOfSettlements_();
	FillMultiplicityCourseWithText();
	FillInCurrencyOfMutualSettlementsOfDocument();
	
	CompleteVATTaxation();
	
	If Not ConnectedHandlersLocalization Then
		ConfigureDependentFormElementsOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure RequiredPaymentDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	Object.ExpenseReportDate =
		CashClient.RecalculateAdvanceReportDate(ExpenseReportPeriod, Object.RequiredPaymentDate);
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	NeedToSwitchToServer = BusinessOperationOnChangeClient();
	If NeedToSwitchToServer Then
		BusinessOperationOnChangeServer();
	EndIf;
	
	UpdatePresentationOfMaturityDate();
	CurrentCompany = Object.Organization;
	
EndProcedure

&AtClient
Function BusinessOperationOnChangeClient()
	
	If SavedBusinessTransaction = Object.BusinessOperation Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

&AtServer
Procedure BusinessOperationOnChangeServer()
	
	InitializePaymentDecryption();
	
	For Each DecryptionString In Object.ARAPDetails Do
		IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, DecryptionString, "Object.ARAPDetails");
	EndDo;
	
	SavedBusinessTransaction = Object.BusinessOperation;
	
	ManagerOfDocument = Common.ObjectManagerByFullName("Document.PaymentRequest");
	CashServer.FillInFormDataAccordingToListOfAttributesOfBusinessTransaction(Object, ManagerOfDocument);
	CounterpartyLegEntInd = Common.ObjectAttributeValue(Object.Counterparty, "LegalEntityIndividual");
	
	CashServer.CheckFillOutContract(Object);
	
	CurrentCounterparty = Object.Counterparty;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.SalaryPayment Then
		Object.PayrollTransaction = Enums.BusinessTransactions.SalaryPaymentToBankAccounts;
	Else
		Object.PayrollTransaction = Undefined;
	EndIf;
	SavedBusinessOperationForSalary = Object.PayrollTransaction;
	
	If ValueIsFilled(Object.DocumentBasis)
		And AvailableBaseOfOperations.FindByValue(Object.BusinessOperation) = Undefined Then
		
		Object.DocumentBasis = Undefined;
		AvailableBaseOfOperations.Clear();
		
	EndIf;
	
	EstablishFormsOfPaymentForBusinessTransaction();
	PaymentMethodIsLimited = PaymentMethodIsLimited();
	SetPaymentForm();
	
	CheckAndClearOrganizationAndBankAccount();
	CheckAndClearRecipientOrganizationAndRecipientBankAccount();
	
	If Not AccountCorrespondsToOwner() Then
		Object.CounterpartyBankAccount = Undefined;
	EndIf;
	
	Object.CashFlowItem = 
		Catalogs.CashFlowReportItems.CashFlowItemForBusinessTransaction(
			?(Object.BusinessOperation = Enums.BusinessTransactions.SalaryPayment,
				Object.PayrollTransaction, Object.BusinessOperation));
	
	If Not ValueIsFilled(Partner) Then
		Partner = CashServer.GetCounterpartyPartner(Object.Counterparty, Object.BusinessOperation);
	EndIf;
	
	For Each DecryptionString In Object.ARAPDetails Do
	
		DecryptionString.CashFlowItem = 
			CashServer.ArticleOfCashFlowOfSettlementObject(
			DecryptionString.ARAPObject, Object.BusinessOperation);
	
		If Not ValueIsFilled(DecryptionString.Partner) Then
			DecryptionString.Partner = Partner;
		EndIf;
	
	EndDo;
	
	Object.PersonsList = False;
	PersonsList = 0;
	Object.TransferToEmployeeViaABank = False;
	TransferToEmployeeViaABank = 0;
	
	If Not Object.TransferOfTaxesAndContributions Then
		Object.PaymentID = "";
	EndIf;
	
	CashServer.DetermineCurrencyPayment(ThisObject);
	
	If Object.PaymentWithConversion
		And ValueIsFilled(Object.BankAccount) Then
		
		Object.Currency = Common.ObjectAttributeValue(
			Object.BankAccount, "CashCurrency");
		CurrencyOfPayersAccount = Object.Currency;
		
		If Not ConnectedHandlersLocalization Then
			UpdateCurrencyData();
		EndIf;
		
	EndIf;
	SetupParameters = Documents.PaymentRequest.AccountingAccountSettings_(
		Object.BusinessOperation, Object.TaxType);
	GLAccountSettingsServer.WhenChangingSettings(ThisObject, SetupParameters);
	GetDefaultContractServer(Object.Counterparty, Object.CounterpartyBankAccount);
	Object.LineOfBusiness = CashServer.LineOfBusiness(
		Object.BusinessOperation,
		Object.LineOfBusiness);
	CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object, , True);
	ProcessIPChange();
	
	If Not ConnectedHandlersLocalization Then
		FormItemsManagement();
	EndIf;
	
	PartnersAndCounterparties.TitleOfPartnerElementDependingOnBusinessOperation(
		ThisObject, "ARAPDetailsPartner", Object.BusinessOperation);
	PartnersAndCounterparties.TitleOfPartnerElementDependingOnBusinessOperation(
		ThisObject, "DecryptionWithoutPartitioningPartner", Object.BusinessOperation);
		
	ItemsAndDimensionsSelectionParameters =
		Documents.PaymentRequest.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisObject);
	
EndProcedure

&AtClient
Procedure DocumentAmountOnChange(Item)
	
	NeedToSwitchToServer = DocumentAmountOnChangeClient();
	If NeedToSwitchToServer Then
		DocumentAmountOnChangeServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	
	NeedToSwitchToServer = CurrencyOnChangeClient();
	If NeedToSwitchToServer Then
		CurrencyOnChangeServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	CurrentCompany = Object.Organization;
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Organization");
	
	SetParametersForSelectingRecipientOrganization();
	SetParametersForSelectingLoanDepositAgreements(Object.Counterparty);
	SetParametersForSelectingLeaseAgreement_(Object.Counterparty);
	CheckAndClearRecipientOrganizationAndRecipientBankAccount();
	
	If Object.BusinessOperation <> Enums.BusinessTransactions.CurrencyConversion
		And Not Object.TransferOfTaxesAndContributions Then
		Object.PaymentID = "";
	EndIf;
	
	CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	If Not ValueIsFilled(Object.Currency) Then
		Object.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	EndIf;
	
	If ValueIsFilled(Object.Organization) And ValueIsFilled(Object.PaymentMethodOfPaymentRequest) Then
		
		ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Object.Organization);
		If Object.AmountPlanning = Enums.MethodsOfPlanningRequestPayment.InPaymentCurrency Then
			ParametersOfAccount.Currency = Object.Currency;
		EndIf;
		Object.BankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount,
			Object.BankAccount, Object.PaymentMethodOfPaymentRequest);
		
		ParametersStructure = CashServer.DefaultParametersForFillingInCheckout();
		ParametersStructure.Organization = Object.Organization;
		ParametersStructure.PaymentMethod = Object.PaymentMethodOfPaymentRequest;
		ParametersStructure.CashAccount       = Object.CashAccount;
		If Object.AmountPlanning = Enums.MethodsOfPlanningRequestPayment.InPaymentCurrency Then
			ParametersStructure.Currency = Object.Currency;
		EndIf;
		Object.CashAccount = SettingsValueCached.GetOrganizationSDefaultSalesRegister(ParametersStructure);
		
	EndIf;
	
	FillInSubordinatePropertiesForStatistics("Organization");
	
	If ValueIsFilled(Object.Organization) Then
		LegalEntityIndividual = Common.ObjectAttributeValue(Object.Organization, "LegalEntityIndividual");
		BranchesOfOrganization.LoadValues(Catalogs.Companies.BranchesWithPaymentsThroughParentOrganization(Object.Organization));
	Else
		BranchesOfOrganization.Clear();
	EndIf;
	
	If Not ConnectedHandlersLocalization Then
		
		If CurrentBankAccount <> Object.BankAccount Then
			BankAccountOnChangeServer();
		EndIf;
		
		If CurrentCurrency <> Object.Currency Then
			UpdateCurrencyData();
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(Object.Counterparty) Then
		
		GetDefaultContractServer(Object.Counterparty, Object.CounterpartyBankAccount);
		
		If ValueIsFilled(CounterpartyContract) Then
			ARAPObjectContract = ARAPObjectsServer.GetCalculationObjectFromLink(CounterpartyContract);
		EndIf;
		
		For Each TSRow In Object.ARAPDetails Do
			FillInPaymentTranscript(TSRow, ARAPObjectContract);
		EndDo;
		
		StructureOfActions = New Structure("RecalculateVATAmount", New Structure("PriceIncludesVAT", True));
		BatchProcessingOfTablePartServer.TreatTS(Object.ARAPDetails, StructureOfActions, Undefined);
	EndIf;
	
	CashServer.SetContractSelectionParameters(ThisObject, Items.Contract);
	If Object.BusinessOperation = Enums.BusinessTransactions.PaymentToLessor Then
		
		For Each TSRow In Object.ARAPDetails Do
			
			TSRow.LeaseContracts = Catalogs.LeaseContract.DefaultContract(
				Object.Organization, TSRow.Partner, Object.Counterparty, TSRow.LeaseContracts);
			ARAPDetailsLeaseContractsOnChangeServer(TSRow.GetID());
			
		EndDo;
		
	EndIf;
	If Not ValueIsFilled(CounterpartyContract) Then
		
		CompleteVATTaxation();
		CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object, , True);
		SetRestrictionOnTypeOfPaymentDecryptionContract();
		ProcessIPChange();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PayrollTransactionOnChange(Item)
	
	NeedToSwitchToServer = PayrollTransactionOnChangeClient();
	If NeedToSwitchToServer Then
		PayrollTransactionOnChangeServer();
	EndIf;
	
EndProcedure

&AtClient
Function PayrollTransactionOnChangeClient()
	
	If SavedBusinessOperationForSalary = Object.PayrollTransaction Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

&AtServer
Procedure PayrollTransactionOnChangeServer()
	
	If SavedBusinessOperationForSalary <> Object.PayrollTransaction Then
		Object.CashFlowItem =
			Catalogs.CashFlowReportItems.CashFlowItemForBusinessTransaction(Object.PayrollTransaction);
	EndIf;
	
	SavedBusinessOperationForSalary = Object.PayrollTransaction;
	
	EstablishFormsOfPaymentForBusinessTransaction();
	PaymentMethodIsLimited = PaymentMethodIsLimited();
	
	If Object.PayrollTransaction = Enums.BusinessTransactions.SalaryPaymentViaCashAccount
		And Not ValueIsFilled(Object.CashAccount) And ValueIsFilled(Object.Organization) Then
		Object.CashAccount = Catalogs.CashAccounts.GetCheckoutByDefault(Object.Organization, Object.Currency);
	EndIf;

	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure PaymentMethodOnChange(Item)
	
	TypesOfDistribution = New Array;
	For Each DistributionString In Object.AllocationByAccounts Do
		TypesOfDistribution.Add(TypeOf(DistributionString.BankAccountCashAccount));
	EndDo;
	
	MismatchOfDistributionTypes = False;
	If PaymentMethod = "CashAccountPayment_" Then
		MismatchOfDistributionTypes =
			(TypesOfDistribution.Find(Type("CatalogRef.CompaniesBankAccounts")) <> Undefined);
		Object.BankAccount = Undefined;
		CurrencyOfPayersAccount = Undefined;
	ElsIf PaymentMethod = "BankAccountPayment"
		Or PaymentMethod = "SBP" Then
		MismatchOfDistributionTypes =
			(TypesOfDistribution.Find(Type("CatalogRef.CashAccounts")) <> Undefined);
		Object.CashAccount = Undefined;
	EndIf;
	
	If MismatchOfDistributionTypes Then
		QueryText = NStr("vi = 'biểu mẫu thanh toán được chọn khác với biểu mẫu được chỉ định trong phân bổ tài khoản. Xóa đường phân bổ không hợp lệ?';
						|ru = 'Выбранная форма оплаты отличается от указанной в распределении по счетам. Удалить некорректные строки распределения?';
						|en = 'The selected payment method differs from the one specified in allocation to accounts. Remove the incorrect allocation lines?'; fa = 'The selected payment method differs from the one specified in allocation to accounts. Remove the incorrect allocation lines?';
						|it = 'La modalità di pagamento selezionata differisce da quella specificata nella ripartizione sui conti. Eliminare le righe di ripartizione errate?';
						|pl = 'Wybrana forma płatności różni się od podanej w przydziele według rachunków. Usunąć nieprawidłowe wiersze podziału?';
						|tr = 'Seçilen ödeme şekli fatura tahsisinde gösterilenden farklı. Hatalı tahsisat satırları silinsin mi?'");
		Notification = New CallbackDescription("PaymentMethodOnChangeCompletion", ThisForm, Undefined);
		ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo);
	Else
		PaymentFormWhenChangingFragment();
	EndIf;
	
EndProcedure

&AtClient
Procedure PaymentMethodOnChangeCompletion(Result, Var_Parameters) Export
	
	If Result = DialogReturnCode.Yes Then
		ClearDistributionOfAccountsByPaymentForm();
	Else
		SetPaymentForm();
	EndIf;
	
EndProcedure

&AtClient
Procedure PaymentFormWhenChangingFragment()
	
	If PaymentMethod = "CashAccountPayment_" Then
		Object.PaymentMethodCash = True;
		Object.PaymentMethodBankAccount = False;
		Object.MethodOfPaymentPaymentCard = False;
		Object.PaymentMethodOfPaymentRequest = PredefinedValue("Enum.PaymentForms.CashAccountPayment_");
		
	ElsIf PaymentMethod = "BankAccountPayment" Then
		Object.PaymentMethodCash = False;
		Object.PaymentMethodBankAccount = True;
		Object.MethodOfPaymentPaymentCard = False;
		Object.PaymentMethodOfPaymentRequest = PredefinedValue("Enum.PaymentForms.BankAccountPayment");
		
	ElsIf PaymentMethod = "Any_" Then
		Object.PaymentMethodCash = True;
		Object.PaymentMethodBankAccount = True;
		Object.MethodOfPaymentPaymentCard = False;
		Object.PaymentMethodOfPaymentRequest = Undefined;
		
	ElsIf PaymentMethod = "PaymentCard" Then
		Object.PaymentMethodCash = False;
		Object.PaymentMethodBankAccount = False;
		Object.MethodOfPaymentPaymentCard = True;
		Object.PaymentMethodOfPaymentRequest = PredefinedValue("Enum.PaymentForms.PaymentCard");
		
	ElsIf PaymentMethod = "SBP" Then
		Object.PaymentMethodCash = False;
		Object.PaymentMethodBankAccount = True;
		Object.MethodOfPaymentPaymentCard = False;
		Object.PaymentMethodOfPaymentRequest = PredefinedValue("Enum.PaymentForms.InstantPayments");
		
	Else
		Object.PaymentMethodCash = False;
		Object.PaymentMethodBankAccount = False;
		Object.MethodOfPaymentPaymentCard = False;
		
	EndIf;
	
	FormOfPaymentForApplicationWhenServerChanges();
	
EndProcedure

&AtServer
Procedure FormOfPaymentForApplicationWhenServerChanges()
	
	If Object.PaymentMethodOfPaymentRequest <> Enums.PaymentForms.BankAccountPayment Then
		Object.TransferToEmployeeViaABank = False;
		TransferToEmployeeViaABank = 0;
		TransferToEmployeeViaBankWhenChangesAreMadeOnServer();

	EndIf;
	
	FillInDetailsOfDocumentOnFormOfPayment();
	SetPaymentWithConversionAttribute();
	
	
	SetParametersForSelectingBankAccountOfCashier();
	SetParametersForSelectingCounterpartySBankAccount(Object, Items.CounterpartyBankAccount);
	CashServer.SetParametersForSelectingRecipientSBankAccount(Object, Items.BankAccountBeneficiary, False);
	CashServer.SetParametersForSelectingRecipientSBankAccount(Object, Items.CashAccountRecipient);
	SetParametersForSelectingLoanDepositAgreements(Object.Counterparty);
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtClient
Procedure BankAccountOnChange(Item)
	
	BankAccountOnChangeServer();
	
EndProcedure

&AtServer
Procedure BankAccountOnChangeServer()
	
	CurrencyOfPayersAccount = Common.ObjectAttributeValue(Object.BankAccount, "CashCurrency");
	
	If ValueIsFilled(CurrencyOfPayersAccount)
		And Object.AmountPlanning <> Enums.MethodsOfPlanningRequestPayment.InARAPCurrency Then
		Object.Currency = CurrencyOfPayersAccount;
	EndIf;
	
	UpdateCurrencyData();
	CurrentBankAccount = Object.BankAccount;
	
	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyOnChangeServer();
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	
	If CurrentCounterparty <> Object.Counterparty Then
		
		If Object.BusinessOperation <> Enums.BusinessTransactions.CurrencyConversion Then
			Object.PaymentID = "";
		EndIf;
		
		ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Counterparty");
		
		If ValueIsFilled(Object.Counterparty) Then
			FillInSubordinatePropertiesForStatistics("Counterparty");
		EndIf;
		
		WhenChangingCounterparty(Object.Counterparty, Object.CounterpartyBankAccount, Object.ListOfCounterparties_ = False);
		
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
		
		CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object, , True);
		ProcessIPChange();
		
		If ValueIsFilled(Object.Counterparty) Then
		
			If ValueIsFilled(Object.CounterpartyBankAccount)
				And Common.ObjectAttributeValue(Object.CounterpartyBankAccount, "Closed") Then
				Object.CounterpartyBankAccount = Undefined;
			EndIf;
			
			RecipientSCurrency = Common.ObjectAttributeValue(Object.CounterpartyBankAccount, "CashCurrency");
			
			If (Object.Currency <> RecipientSCurrency
				And Object.PaymentWithConversion)
				Or Object.PaymentMethodOfPaymentRequest = Enums.PaymentForms.CashAccountPayment_ Then
				Object.CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.EmptyRef();
			EndIf;
			
			If Not ValueIsFilled(Object.CounterpartyBankAccount) Then
				Object.CounterpartyBankAccount =
					Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(Object.Counterparty, Object.Currency);
			EndIf;
			
			FillInPurposeOfPaymentOnRecipientSAccount();
			
		EndIf;
		
		CounterpartyLegEntInd = Common.ObjectAttributeValue(Object.Counterparty, "LegalEntityIndividual");
		CurrentCounterparty = Object.Counterparty;
		
	EndIf;
	If Object.BusinessOperation = Enums.BusinessTransactions.PaymentToLessor Then
		
		For Each TSRow In Object.ARAPDetails Do
			
			TSRow.LeaseContracts = Catalogs.LeaseContract.DefaultContract(
				Object.Organization, TSRow.Partner, Object.Counterparty, TSRow.LeaseContracts);
			ARAPDetailsLeaseContractsOnChangeServer(TSRow.GetID());
			
		EndDo;
		
	EndIf;
	FormItemsManagement();
	
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
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.PaymentRequest.ItemsAndDimensionsSelectionParameters(
		Object.BusinessOperation, Object.RecordCommission);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure CounterpartyBankAccountOnChange(Item)
	
	CounterpartySBankAccountWhenChangedOnServer();
	
EndProcedure

&AtServer
Procedure CounterpartySBankAccountWhenChangedOnServer()
	
	FillInCurrencyOnRecipientSAccount(Object.CounterpartyBankAccount);
	
	If Not ValueIsFilled(Object.PaymentPurposes) Then
		FillInPurposeOfPaymentOnRecipientSAccount();
	EndIf;
	
	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure AmountPlanningOnChange(Item)
	
	AmountPlanningOnChangeServer();
	
EndProcedure

&AtServer
Procedure AmountPlanningOnChangeServer()
	
	If Object.AmountPlanning = Enums.MethodsOfPlanningRequestPayment.InPaymentCurrency Then
		
		If Object.PaymentMethodOfPaymentRequest = Enums.PaymentForms.CashAccountPayment_ Then
			If ValueIsFilled(Object.CashAccount) Then
				Object.Currency = Common.ObjectAttributeValue(Object.CashAccount, "CashCurrency");
			EndIf;
		ElsIf Object.PaymentMethodOfPaymentRequest = Enums.PaymentForms.EmptyRef()
			Or Object.PaymentMethodOfPaymentRequest = Enums.PaymentForms.PaymentCard Then
			Object.Currency = CurrencyOfComplianceAccounting;
		Else
			
			If ValueIsFilled(Object.BankAccount) Then
				Object.Currency = Common.ObjectAttributeValue(Object.BankAccount, "CashCurrency");
			Else
				Object.Currency = CurrencyOfComplianceAccounting;
			EndIf;
			
		EndIf;
		
	Else
		
		ArrayOfCurrencies = New Array;
		For Each TableRow In Object.ARAPDetails Do
			If ValueIsFilled(TableRow.ARAPCurrency)
				And ArrayOfCurrencies.Find(TableRow.ARAPCurrency) = Undefined Then
				ArrayOfCurrencies.Add(TableRow.ARAPCurrency);
			EndIf;
		EndDo;
		
		If ArrayOfCurrencies.Count() = 1 Then
			Object.Currency = ArrayOfCurrencies[0];
		Else
			Object.Currency = Undefined;
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(Object.Currency) Then
		
		FillInSubordinatePropertiesForStatistics("Currency");
	
		ClearPaymentFormData();
		
		SetPaymentWithConversionAttribute(Object.PaymentWithConversion);
		
		If Object.AmountPlanning = Enums.MethodsOfPlanningRequestPayment.InARAPCurrency Then
			
			For Each TableRow In Object.ARAPDetails Do
				TableRow.Sum = TableRow.AmountARAP;
				TableRow.ExchangeRateNumeratorOfMutualSettlements = 1;
				TableRow.TheExchangeRateIsTheDenominatorOfMutualSettlements = 1;
			EndDo;
			Object.DocumentAmount = Object.ARAPDetails.Total("Sum");
		Else
			
			CashServer.ConversionOfDocumentAmountsIntoCurrency(Object, CurrentCurrency, Object.Currency);
			FillInSettlementRate();
			
		EndIf;
		
		CashServer.SetPaymentAmountHeader(Object.Currency, Items);
		InformationForRegulatoryBodiesIsRequired = (Common.ObjectAttributeValue(Object.Currency, "Code") = "980");
		
		CheckCurrencyCompliance();
		FillInDetailsOfDocumentOnFormOfPayment();
		
		FillMultiplicityCourseWithText();
		FillInCurrencyOfMutualSettlementsOfDocument();
		
		CurrentCurrency = Object.Currency;
	
	Else
		AfterChangingCurrency();
	EndIf;
	
	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure AdvanceHolderOnChange(Item)
	
	AdvanceHolderOnChangeServer();
	
EndProcedure

&AtServer
Procedure AdvanceHolderOnChangeServer()
	
	If (Not ValueIsFilled(Object.CounterpartyBankAccount)
		Or Not AccountCorrespondsToOwner())
		And Not Object.TransferToEmployeeViaABank Then
		Object.CounterpartyBankAccount =
			Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(Object.AdvanceHolder, Object.Currency);
	EndIf;

	FormItemsManagement();
	ConfigureDependentFormElementsOnServer("AdvanceHolder");
		
EndProcedure

&AtClient
Procedure CompanyRecipientOnChange(Item)

	CompanyRecipientOnChangeServer();
	
EndProcedure

&AtServer
Procedure CompanyRecipientOnChangeServer()
	
	If ValueIsFilled(Object.CompanyRecipient) Then
		ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(
			Object.CompanyRecipient);
		ParametersOfAccount.Currency = Object.Currency;
		Object.BankAccountBeneficiary = Catalogs.CompaniesBankAccounts.GetDefaultBankAccount(
			ParametersOfAccount);
		FillInSubordinatePropertiesForStatistics("CompanyRecipient");
		FormItemsManagement();
	EndIf;
	
EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	
	If CurrentStatus <> Object.Status Then
		StatusOnChangeServer();
		CurrentStatus = Object.Status;
	EndIf;
	
	Object.ExpenseReportDate =
		CashClient.RecalculateAdvanceReportDate(ExpenseReportPeriod, Object.RequiredPaymentDate);
	
EndProcedure

&AtServer
Procedure StatusOnChangeServer()
	
	If (Object.Status = Enums.StatusesOfPaymentRequests.AgreedUpon
		Or Object.Status = Enums.StatusesOfPaymentRequests.AmountDue)
		And Not ValueIsFilled(Object.PaymentDate)
		And ValueIsFilled(Object.RequiredPaymentDate) Then
		
		Object.PaymentDate = Max(Object.Date, Object.RequiredPaymentDate);
	EndIf;
	
	If Object.Status = Enums.StatusesOfPaymentRequests.AgreedUpon
		Or CurrentStatus <> Enums.StatusesOfPaymentRequests.AgreedUpon
			And Object.Status = Enums.StatusesOfPaymentRequests.AmountDue Then
		Object.WhoDecided = Users.CurrentUser();
	EndIf;
	
	SetListOfStatuses();
	ConfigureDependentFormElementsOnServer("Status");
	
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
Procedure OverLimitsOnChange(Item)
	
	ConfigureDependentFormElements(Item.Name);
	
EndProcedure

&AtClient
Procedure ConversionAmountOnChange(Item)
	
	RecalculateConversionParameters("ConversionAmount");
	
	If Object.ARAPDetails.Count() = 1 Then
		Object.ARAPDetails[0].Sum = Object.DocumentAmount;
	EndIf;
	
EndProcedure

&AtClient
Procedure TheLabelPaymentClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	FormParameters.Insert("VariantKey", "FulfillmentOfPaymentRequests");
	FormParameters.Insert("PurposeUseKey", "FulfillmentOfPaymentRequests");
	FormParameters.Insert("GenerateOnOpen", True);
	FormParameters.Insert("ReportOptionsCommandsVisibility", False);
	
	Filter = New Structure;
	Filter.Insert("PaymentRequest", Object.Ref);
	FormParameters.Insert("Filter", Filter);
	
	OpenForm("Report.FulfillmentOfPaymentRequests.Form", FormParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	If CurrentPage = Items.TheDecryptionPage And Not DecryptionSwitch And Not ReadOnly Then
		ARAPDetailsOnStartEdit(Item, False, False);
	EndIf;
	
EndProcedure

&AtClient
Procedure BankAccountBeneficiaryOnChange(Item)
	
	RecipientSBankAccountWhenModifiedOnServer();
	
EndProcedure

&AtServer
Procedure RecipientSBankAccountWhenModifiedOnServer()
	
	FillInCurrencyOnRecipientSAccount(Object.BankAccountBeneficiary);
	
	FormItemsManagement();
	
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
	InstructionSelectionOptions.Insert("ReadOnly", Item.ReadOnly);
	
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
Procedure PersonsListOnChange(Item)
	
	Object.PersonsList = Boolean(PersonsList);
	
	If Object.PersonsList Then
		ListOfPersonsChangedOnServer();
	EndIf;
	
	ConfigureDependentFormElements("PersonsList");
	
EndProcedure

&AtClient
Procedure ExpenseReportPeriodOnChange(Item)
	
	Object.ExpenseReportDate =
		CashClient.RecalculateAdvanceReportDate(ExpenseReportPeriod, Object.PaymentDate);
	
	ConfigureDependentFormElements("ExpenseReportPeriodDate");
	
EndProcedure

&AtClient
Procedure ExpenseReportPeriodChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	Notification = New CallbackDescription("ExecuteAfterSelectingDate", ThisObject);
	
	CashClient.ExpenseReportPeriodChoiceProcessing(
		Item, ValueSelected, StandardProcessing, ThisForm, Object.RequiredPaymentDate, Notification);
	
	ExpenseReportPeriodDate = (TypeOf(ValueSelected) = Type("Date") Or ValueSelected = "TillDate");
	
EndProcedure

&AtClient
Procedure ExecuteAfterSelectingDate(SelectedDate, Var_Parameters) Export
	
	ExpenseReportPeriodDate = (TypeOf(ExpenseReportPeriod) = Type("Date"));
	ConfigureDependentFormElements();
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	AgreementWhenModifiedOnServer();
	
EndProcedure

&AtServer
Procedure AgreementWhenModifiedOnServer()
	
	CurrentRow = Object.ARAPDetails.FindByID(Items.ARAPDetails.CurrentRow);
	
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
	
	CompleteVATTaxation(False);
	SetRestrictionOnTypeOfPaymentDecryptionContract();
	GenerateHyperlinkCaptionPaymentObjectDetails();
	
	StructureOfActions = New Structure("RecalculateVATAmount", New Structure("PriceIncludesVAT", True));
	BatchProcessingOfTablePartServer.TreatTS(Object.ARAPDetails, StructureOfActions, Undefined);
	
EndProcedure

&AtClient
Procedure ReturnAgreementCreating(Item, StandardProcessing)

	StandardProcessing = False;
	
	CashClient.OpenCreationOfRefundContract(ThisObject, Item);

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
	
	VATConversionParameters = New Structure("PriceIncludesVAT", True);
	StructureOfActions = New Structure("RecalculateVATAmount", VATConversionParameters);
	BatchProcessingOfTablePartServer.TreatTS(Object.ARAPDetails, StructureOfActions, Undefined);
	
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	
	CompleteVATTaxation();
	
EndProcedure

&AtClient
Procedure TransferToEmployeeViaABankOnChange(Item)

	TransferToEmployeeViaBankONChangeOnClient(Item);
	TransferToEmployeeViaBankWhenChangesAreMadeOnServer();

EndProcedure

&AtServer
Procedure TransferToEmployeeViaBankWhenChangesAreMadeOnServer()

	Object.TransferToEmployeeViaABank = Boolean(TransferToEmployeeViaABank);
	
	If Not Object.TransferToEmployeeViaABank Then
		
		If Object.BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder
			Or Object.BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToEmployee
			Or (Object.BusinessOperation = Enums.BusinessTransactions.SalaryPayment
			And Object.PayrollTransaction = Enums.BusinessTransactions.SalaryPaymentToBankAccounts) Then
			Object.Counterparty = Catalogs.Counterparties.EmptyRef();
		EndIf;
		
		Object.CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(Object.AdvanceHolder, Object.Currency);
		
	Else
		
		If Object.PersonsList Then
			
			Object.Currency = Common.ObjectAttributeValue(Object.BankAccount, "CashCurrency");
			UpdateCurrencyData();
			
		EndIf;
		
		Object.CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(Object.Counterparty, Object.Currency);
		
	EndIf;
	
	ConfigureDependentFormElementsOnServer("TransferToEmployeeViaABank");
	
	FormItemsManagement();

EndProcedure

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	ClearMessages();
	
	Return;
	
EndProcedure

&AtClient
Procedure DecorationSparkriskieIndexesURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure LabelPayerAttributesClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	
EndProcedure

&AtClient
Procedure PaymentIDOnChange(Item)
	
	PaymentIdOnChangeAtServer();
	
EndProcedure

&AtClient
Procedure PaymentsAsPer275FZOnChange(Item)
	
	Return;
	
EndProcedure

&AtClient
Procedure PaymentType275FZOnChange(Item)
	
	
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
Procedure ListOfCounterparties_OnChange(Item)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure ConversionRateMultiplierOnChange(Item)
	
	MultiplicityOfConversionRateWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure Closed_OnChange(Item)

	ConfigureDependentFormElements("Closed_");
	
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
			CommonClientServer.MessageToUser(MessageText);
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
Procedure ARAPDetailsOnActivateCell(Item)
	
	TableColumn2 = Items.ARAPDetails.CurrentItem;
	
	If TableColumn2 = Undefined Then
		Return;
	EndIf;
	
	If TableColumn2.Name = "ARAPDetailsPartner" Then
		SetVisibilityAvailabilityOfPaymentDecryptionElementPartner();
	EndIf;
	
	If TableColumn2.Name = "ARAPDetailsAmountARAP" Then
		CashClient.SetAvailabilityOfPaymentDecryptionItemAmountOfSettlements(ThisObject, Object.Currency);
	EndIf;
	
	CashClient.SetAvailabilityOfPaymentDecryptionContractElement(ThisObject);
	
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
		Object, Partner, CounterpartyContract, TableRow, NewRow, Copy);
		
	If NewRow Then
		If Not Object.ListOfCounterparties_ Then
			TableRow.Counterparty = Object.Counterparty;
		EndIf;
		LineID = TableRow.GetID();
		If Not Copy Then
			TableRow.ARAPCurrency = Object.Currency;
			TableRow.ExchangeRateNumeratorOfMutualSettlements = 1;
			TableRow.TheExchangeRateIsTheDenominatorOfMutualSettlements = 1;
			IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, TableRow, "Object.ARAPDetails");

			If Not ValueIsFilled(TableRow.VATRate) Then
				FillInLBBidByDefault(LineID);
			EndIf;
		EndIf;
		CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
			TableRow, Object.Currency, CurrencyOfComplianceAccounting);
		RecalculateVATAmount(LineID);
	EndIf;
	
	DecryptionOfPaymentAmountWhenChangedOnServer();
	
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
Procedure DecryptionWithoutSplittingTheCalculationObjectOnChange(Item)
	
	DecryptionWithoutSplittingTheCalculationObjectOnChangeServer();
	
	TableRow = Items.ARAPDetails.CurrentData;
	If Not ValueIsFilled(TableRow.ARAPObject) Then
		TableRow.MaturityDate = Date(1, 1, 1);
	EndIf;
	UpdatePresentationOfMaturityDate();
	
EndProcedure

&AtServer
Procedure DecryptionWithoutSplittingTheCalculationObjectOnChangeServer()
	
	CashServer.CheckFillOutContract(Object, Items.ARAPDetails.CurrentRow);
	CashServer.UpdateSettlementCurrencyOfPaymentDecryption(
		"Document.PaymentRequest", Object, CurrencyOfComplianceAccounting);
	FillMultiplicityCourseWithText();
	FillInCurrencyOfMutualSettlementsOfDocument();
	
	CompleteVATTaxation();
	SetRestrictionOnTypeOfPaymentDecryptionContract();
	
	CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object, , True);
	FillInUIP(Items.ARAPDetails.CurrentRow);
	ProcessIPChange();
	ARAPAccountingFormWork.BlockSettlementObjects(ThisObject);
	CalculateControlPaymentFlagForSettlementObjects();
	
EndProcedure

&AtClient
Procedure DecodingWithoutSplittingRepresentationOfReflectionInReglAccountingClick(Item, StandardProcessing)
	CallbackOnCompletion = New CallbackDescription("ReflectionsInLocalAccountingWhenChangesOccur", ThisObject);
	GLAccountSettingsClient.OnClick(ThisObject, Item, StandardProcessing, CallbackOnCompletion);
	Return;
	
EndProcedure

&AtClient
Procedure ARAPDetailsARAPObjectStartChoice(Item, ChoiceData, StandardProcessing)
	
	ARAPObject = PredefinedValue("Catalog.ARAPObjects.EmptyRef");
	CurrentData = Items.ARAPDetails.CurrentData;
	If CurrentData <> Undefined Then
		ARAPObject = CurrentData.ARAPObject;
	EndIf;
	
	AdditionalSelection = Undefined;
	
	
	ARAPAccountingClient.ARAPObjectStartChoice(
		ThisObject, Item, StandardProcessing,, ARAPObject, AdditionalSelection);
	
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
	
	FillPropertyValues(TableRow, ValueSelected);
	Modified = True;
	ARAPAccountingFormWork.BlockSettlementObjects(ThisForm);
	
	
	FillInCourseAndMultiplicityInDecryptionLine(TableRow);
	CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
		TableRow, Object.Currency, CurrencyOfComplianceAccounting);
	CashServer.FormCourseDenominatorByText(TableRow, Object.Currency, CurrencyOfComplianceAccounting);
	FillInCurrencyOfMutualSettlementsOfDocument();
	FillInUIP(RowID);
	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	
	DecryptionOfTheCalculationObjectWhenChangingServer(RowID);


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
		CurrencyExchangeRate = ProcessingOfExchangeRatesTM.GetCurrencyRate(ValueSelected.ARAPCurrency, Undefined, CurrencyOfComplianceAccounting);
		ValueSelected.Insert("ExchangeRateNumeratorOfMutualSettlements", CurrencyExchangeRate.CourseNumerator);
		ValueSelected.Insert("TheExchangeRateIsTheDenominatorOfMutualSettlements", CurrencyExchangeRate.CourseDenominator);
	EndIf;
	
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
Procedure ARAPDetailsPartnerCreating(Item, StandardProcessing)
	
	TableRow = Items.ARAPDetails.CurrentData;
	RowData = New Structure("ARAPObject, LeaseContracts, LoanDepositContract");
	FillPropertyValues(RowData, TableRow);
	RowData.Insert("Ref", Object.Ref);
	
	If YouCanTEditPartnerElement(RowData) Then
		
		StandardProcessing = False;
		OutputRow = StrTemplate(NStr("vi = 'Không thể chỉnh sửa trường ""%1""';
									|ru = 'Поле ""%1"" не доступно для редактирования';
									|en = 'The ""%1"" field editing is unavailable'; fa = 'The ""%1"" field editing is unavailable';
									|it = 'Il campo ""%1"" non è disponibile per la modifica';
									|pl = 'Pole ""%1"" nie jest dostępne do edycji';
									|tr = '""%1"" alanı düzenlenebilir değil'"), Item.Title);
		CommonClient.MessageToUser(OutputRow, , Item);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ARAPDetailsSumOnChange(Item)
	
	TableRow = Items.ARAPDetails.CurrentData;
	
	CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
		TableRow, Object.Currency, CurrencyOfComplianceAccounting);
	
	StructureOfRecalculationOfAmount = New Structure;
	StructureOfRecalculationOfAmount.Insert("PriceIncludesVAT", True);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartClient.ProcessTSString(TableRow, StructureOfActions, CachedValues);
	
	DecryptionOfPaymentAmountWhenChangedOnServer();
	
EndProcedure

&AtServer
Procedure DecryptionOfPaymentAmountWhenChangedOnServer()
	
	CurrencyDecorationAndPaymentRate = CashServer.CurrencyLabelAndPaymentRate(ThisObject);
	SetRestrictionOnTypeOfPaymentDecryptionContract();
	GenerateHyperlinkCaptionPaymentObjectDetails();
	
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
	Documents.PaymentRequest.FillInNamesOfBusinessTransactionDetails(
		Object, Undefined, ArrayOfOperationDetails);
	
	If CurrentRow.ARAPCurrency <> ARAPCurrency
		And ArrayOfOperationDetails.Find("Contract") <> Undefined Then
		Object.Contract = Undefined;
		CashServer.SetContractSelectionParameters(ThisObject, Items.Contract);
	EndIf;
	
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
	
	CashServer.FillInCourseOfMutualSettlementsOfDecryptionLine(Object, CurrencyOfComplianceAccounting, Object.Date, TSRow);
	
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
Procedure ARAPDetailsExpenseItemOnChangeServer(TagName)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items[TagName]);
	
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
Procedure ARAPDetailsDimensionOfExpensesChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	TableRow = Items.ARAPDetails.CurrentData;
	If TypeOf(ValueSelected) = Type("Structure") Then
		FillPropertyValues(TableRow, ValueSelected);
		StandardProcessing = False;
		Modified = True;
	EndIf;
	
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
Procedure ARAPDetailsExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
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
		FormParameters.Insert("Counterparty",            Object.CompanyRecipient);
	Else
		FormParameters.Insert("Counterparty",            Object.Counterparty);
	EndIf;
	
	FormParameters.Insert("FinancialAccountingGroup",    Object.FinancialAccountingGroup);
	FormParameters.Insert("LineOfBusiness",   Object.LineOfBusiness);
	FormParameters.Insert("Contract",                   Object.Contract);
	FormParameters.Insert("Organization",               Object.Organization);
	FormParameters.Insert("Department",             Object.Department);
	FormParameters.Insert("VATTaxation",        Object.VATTaxation);
	FormParameters.Insert("ListOfVATTaxes",  Items.DecodingWithoutSplittingVATTaxation.ChoiceList);
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
	
	If Not Object.Status = PredefinedValue("Enum.StatusesOfPaymentRequests.AmountDue") Then
		
		Object.FinancialAccountingGroup  = Result.FinancialAccountingGroup;
		Object.LineOfBusiness = Result.LineOfBusiness;
		Object.Contract                 = Result.Contract;
		Object.Department           = Result.Department;
		ThereIsChangeInVATTaxation = ?(Object.VATTaxation = Result.VATTaxation, False, True);
		HyperlinkDetailsOfSettlementObjectClickEndOnServer();
		If ThereIsChangeInVATTaxation Then
			Object.VATTaxation = Result.VATTaxation;
			CompleteVATTaxation();
		EndIf;
		
		Modified = True;
	
	EndIf;
	
EndProcedure

&AtServer
Procedure HyperlinkDetailsOfSettlementObjectClickEndOnServer()
	
	ModifiedRows = CashServer.CheckFillInARAPObject(Object);
	
	For Each IndexOf In ModifiedRows Do
		DecryptionString = Object.ARAPDetails[IndexOf]; 
		ARAPDetailsARAPObjectOnChangeServer(DecryptionString.GetID());
		FillInCourseAndMultiplicityInDecryptionLine(DecryptionString);
		CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
			DecryptionString, Object.Currency, CurrencyOfComplianceAccounting);
		CashServer.FormCourseDenominatorByText(DecryptionString, Object.Currency, CurrencyOfComplianceAccounting);
		YouAreAllowedToWorkWithAffiliatedPartners(DecryptionString);
		FillInUIP(DecryptionString.GetID());
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
		FilterStructure1.Organization = Object.CompanyRecipient;
		FilterStructure1.Insert("CompanyRecipient", Object.Organization);
		StructureOfSelectionParameters.Insert("Filter",FilterStructure1);
		OpenForm("Catalog.IntercompanyContracts.Form.ChoiceForm",
			StructureOfSelectionParameters,
			Item,
			Item,)
	Else
		
		If FinancesClient.TheseAreSettlementsWithCustomers(Object.BusinessOperation) Then
			StructureOfSelectionParameters.Insert("ContractTypes", ARAPAccountingClientServer.TypesOfContractsWithClient());
		Else
			StructureOfSelectionParameters.Insert("ContractTypes", ARAPAccountingClientServer.TypesOfContractsWithSupplier());
		EndIf;
		
		If Object.ListOfCounterparties_ Then
			FilterStructure1.Insert("Counterparty", Items.ARAPDetails.CurrentData.Counterparty);
		Else
			FilterStructure1.Insert("Counterparty", Object.Counterparty);
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
	ARAPAccountingFormWork.BlockSettlementObjects(ThisForm);
	DefineUIPIsDifferent();
	
EndProcedure

&AtClient
Procedure ARAPDetailsARAPObjectOnChange(Item)
	
	TableRow = Items.ARAPDetails.CurrentData;
	ARAPDetailsARAPObjectOnChangeServer(TableRow.GetID());
	If Not ValueIsFilled(TableRow.ARAPObject) Then
		TableRow.MaturityDate = Date(1, 1, 1);
	EndIf;
	
EndProcedure

&AtServer
Procedure ARAPDetailsARAPObjectOnChangeServer(LineID)
	
	TableRow = Object.ARAPDetails.FindByID(LineID);
	CashServer.UpdateSettlementCurrencyOfPaymentDecryption(
		"Document.PaymentRequest", Object, CurrencyOfComplianceAccounting);
	CashServer.FormCourseDenominatorByText(TableRow, Object.Currency, CurrencyOfComplianceAccounting);
	FillInCurrencyOfMutualSettlementsOfDocument();
	FillInUIP(LineID);
	
	DecryptionOfTheCalculationObjectWhenChangingServer(LineID)
	
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

&AtClient
Procedure TranscriptOfThePaymentTaxationOfPersonalIncomeTaxChanges(Item)
	
	CompleteVATTaxation();

EndProcedure

&AtClient
Procedure ARAPDetailsLeaseContractsOnChange(Item)
	ARAPDetailsLeaseContractsOnChangeServer();
	
	TableRow = Items.ARAPDetails.CurrentData;
	
	StructureOfRecalculationOfAmount = New Structure;
	StructureOfRecalculationOfAmount.Insert("PriceIncludesVAT", True);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartClient.ProcessTSString(TableRow, StructureOfActions, CachedValues);
	Return;
	
EndProcedure

&AtServer
Procedure ARAPDetailsLeaseContractsOnChangeServer(RowID = Undefined)
	
	If RowID = Undefined Then
		RowID = Items.ARAPDetails.CurrentRow;
	EndIf;
	
	CurrentRow = Object.ARAPDetails.FindByID(RowID);
	
	QueryText = 
	"SELECT
	|	LeaseContract.CashFlowItem AS CashFlowItem,
	|	LeaseContract.ARAPCurrency AS ARAPCurrency,
	|	TermsOfLeaseContracts.VATRate AS VATRate
	|FROM
	|	Catalog.LeaseContract AS LeaseContract
	|		LEFT JOIN InformationRegister.TermsOfLeaseContracts.SliceLast(, Contract = &LeaseContracts) AS TermsOfLeaseContracts
	|		ON TermsOfLeaseContracts.Contract = &LeaseContracts
	|WHERE
	|	LeaseContract.Ref = &LeaseContracts";
	
	Query = New Query(QueryText);
	Query.SetParameter("LeaseContracts", CurrentRow.LeaseContracts);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	If Selection.Next() Then
		FillPropertyValues(CurrentRow, Selection);
	EndIf;
	
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
	
	//++ WE
	If PayrollAndHumanResourcesWE Then	
		ParametersStructure = New Structure;
		ParametersStructure.Insert("ChoiceMode", True);
		ParametersStructure.Insert("MultipleChoice", False);
		ParametersStructure.Insert("CloseOnChoice", True);
		FilterStructure1 = New Structure;
		FilterStructure1.Insert("Posted", True);
		FilterStructure1.Insert("Organization", Object.Organization);
		If ValueIsFilled(Object.Department) Then
			FilterStructure1.Insert("Department", Object.Department);
		EndIf;
		If PaymentMethod = "BankAccountPayment" Then
			FilterStructure1.Insert("PaymentMethodHR", PredefinedValue(
			"Enum.PaymentMethodsHR.EmployeeSBankAccount"));
		Else
			FilterStructure1.Insert("PaymentMethodHR", PredefinedValue(
			"Enum.PaymentMethodsHR.CashAccount"));
		EndIf;
		ParametersStructure.Insert("Filter", FilterStructure1);
		OpenForm("Document.PayrollStatementHR.ChoiceForm", ParametersStructure, ThisObject);
		Return;
	EndIf;
	//-- WE
	

EndProcedure

&AtClient
Procedure ReferenceDocumentsFileStartChoice(Item, ChoiceData, StandardProcessing)
	
	
	Return;
	
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

#Region FormTableItemsEventHandlersPaysheets

&AtClient
Procedure PersonalAccountsOfStaffIndividualOnChange(Item)
	
	CurLineTSPersonalAccounts = Items.PersonalAccountsOfStaff.CurrentData;
	
	If Not ValueIsFilled(CurLineTSPersonalAccounts.PersonalAccount) Then
		CurLineTSPersonalAccounts.PersonalAccount =
			GetPersonalFLAccount(CurLineTSPersonalAccounts.Individual, Object.Currency);
	EndIf;

EndProcedure

&AtServerNoContext
Function GetPersonalFLAccount(Person, Currency)
	
	Return Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(Person, Currency);
	
EndFunction

#EndRegion

#Region FormTableItemsEventHandlersAllocationByAccounts

&AtClient
Procedure AllocationByAccountsAfterDeleteRow(Item)

	SetPaymentWithConversionAttribute();

EndProcedure

&AtClient
Procedure AllocationByAccountsOnStartEdit(Item, NewRow, Copy)
	
	If NewRow And Object.AllocationByAccounts.Count() = 1 Then
		CurrentData = Item.CurrentData;
		CurrentData.Sum = Object.DocumentAmount;
		CurrentData.PaymentDate = Object.PaymentDate;
	EndIf;
	
EndProcedure

&AtClient
Procedure DistributionToAccountsBankAccountStartChoice(Item, ChoiceData, StandardProcessing)
	
	TypesArray = New Array;
	
	If Object.PaymentMethodBankAccount Then
		TypesArray.Add(Type("CatalogRef.CompaniesBankAccounts"));
	EndIf;
	If Object.PaymentMethodCash Then
		TypesArray.Add(Type("CatalogRef.CashAccounts"));
	EndIf;
	
	Items.DistributionToAccountsBankAccount.TypeRestriction = New TypeDescription(TypesArray);
	
EndProcedure

&AtClient
Procedure DistributionToAccountsBankAccountOnChange(Item)
	
	SetPaymentWithConversionAttribute();
	
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
Procedure SelectionByResiduesProcessing(CompletionProcedure)
	
	IntercompanyPayment =
		Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.CashPaymentToAnotherCompany")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RefundToAnotherCompany");
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.CheckedAttributes.Insert("Organization", NStr("vi = 'Doanh nghiệp';
																	|ru = 'Организация';
																	|en = 'Company'; fa = 'Company';
																	|it = 'Azienda';
																	|pl = 'Firma';
																	|tr = 'İş yeri'"));
	CheckParameters.CheckedAttributes.Insert("Currency",      NStr("vi = 'Tiền tệ';
																	|ru = 'Валюта';
																	|en = 'Currency'; fa = 'ارز';
																	|it = 'Valuta';
																	|pl = 'Waluta';
																	|tr = 'Para birimi'"));
	If IntercompanyPayment Then
		If Object.PaymentMethodOfPaymentRequest = PredefinedValue("Enum.PaymentForms.CashAccountPayment_") Then
			CheckParameters.CheckedAttributes.Insert("CashAccountRecipient",          NStr("vi = 'Quỹ tiền mặt của người nhận';
																							|ru = 'Касса получателя';
																							|en = 'Receiving cash account'; fa = 'صندوق دریافت‌کننده';
																							|it = 'Cassa del destinatario';
																							|pl = 'Kasa odbiorcy';
																							|tr = 'Alıcı Kasası'"));
		ElsIf Object.PaymentMethodOfPaymentRequest = PredefinedValue("Enum.PaymentForms.BankAccountPayment")
			Or Object.PaymentMethodOfPaymentRequest = PredefinedValue("Enum.PaymentForms.InstantPayments") Then
			CheckParameters.CheckedAttributes.Insert("BankAccountBeneficiary", NStr("vi = 'Tài khoản người nhận';
																					|ru = 'Счет получателя';
																					|en = 'Payee account'; fa = 'حساب ذی‌نفع';
																					|it = 'Conto del destinatario';
																					|pl = 'Rachunek odbiorcy';
																					|tr = 'Alıcı hesabı'"));
		EndIf;
	Else
		If Not Object.ListOfCounterparties_ Then
			CheckParameters.CheckedAttributes.Insert("Counterparty", NStr("vi = 'Đối tác';
																			|ru = 'Контрагент';
																			|en = 'Counterparty'; fa = 'طرف حساب';
																			|it = 'Controparte';
																			|pl = 'Counterparty';
																			|tr = 'Cari hesap'"));
		EndIf;
	EndIf;
	Notification = New CallbackDescription("SelectionBasedOnBalancesAfterVerification", ThisObject,
		New Structure("IntercompanyPayment, CompletionProcedure", IntercompanyPayment, CompletionProcedure));
		
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure SelectionBasedOnBalancesAfterVerification(Result, AdditionalParameters) Export
	
	Notification = New CallbackDescription(AdditionalParameters.CompletionProcedure, ThisObject);
	PlacePaymentDecryptionInTemporaryStorage();
	
	AdditionalSelection = Undefined;
	ARAPAccountingClient.AddToPaymentDecryption(
		ThisObject, Items.ARAPDetailsSelectionByStock.Name, Notification, AdditionalSelection);
	
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
	DefaultCFItem =
		Catalogs.CashFlowReportItems.CashFlowItemForBusinessTransaction(Object.BusinessOperation);
	ArticlesOfBusinessOfOperation =
		Catalogs.CashFlowReportItems.ArticlesOfBusinessOfOperation(Object.BusinessOperation);
	
	TableOfCalculationObjects = Object.ARAPDetails.Unload(, "ARAPObject");
	TableOfCalculationObjects.GroupBy("ARAPObject");
	TaxationOfSettlementObjects =
		Common.ObjectsAttributeValue(TableOfCalculationObjects.UnloadColumn("ARAPObject"), "VATTaxation");
	
	For Each TableRow In Object.ARAPDetails Do
		
		If ValueIsFilled(TableRow.ARAPObject) Then
			TableRow.VATTaxation = TaxationOfSettlementObjects[TableRow.ARAPObject];
		EndIf;
		
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
	
	FillInParametersOfCalculationObjectInDecryption(True);
	
	ConfigureDependentFormElementsOnServer();
	
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
Procedure ExportFileForBankExchange(Command)
	
	Return;
	
EndProcedure

&AtClient
Procedure FillInThePaysheetsByBalance(Command)
	
	Return;
	
EndProcedure

&AtClient
Procedure FillInTheRemainingOutstandingAmountsToTheEmployee(Command)
	
	Return;
	
EndProcedure

&AtClient
Procedure FillOutJustificationDocuments(Command)
	
	Return;
	
EndProcedure

&AtClient
Procedure FillInWithThePreviousPayment(Command)
	
	Return;
	
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
Procedure SelectTaxInvoices(Command)
	
	Return;
	
EndProcedure

&AtClient
Procedure ViewJustificationDocument(Command)
	
	Return;
	
EndProcedure

&AtClient
Procedure CloseRequest(Command)
	
	Object.Closed_ = True;
	
	WriteParameters = New Structure;
	WriteParameters.Insert("WriteMode", DocumentWriteMode.Posting);
	
	Write(WriteParameters);
	
EndProcedure

&AtClient
Procedure FillInCashFlowItem(Command)

	CashClient.FillInCashFlowItem(
		ThisObject, Items.PersonalAccountsOfStaff, "PersonalAccountsOfStaff");

EndProcedure

#EndRegion

#Region Private

#Region ElementEventHandlers

&AtClient
Function DateOnChangeClient()

	If CurrentDate = Object.Date Then
		Return False;
	EndIf;
	
	If Object.PaymentDate < Object.Date Then
		Object.PaymentDate = Object.Date;
	EndIf;
	
	Return True;

EndFunction

&AtClient
Procedure ReflectionsInLocalAccountingWhenChangesOccur(Result, AdditionalParameters) Export
	ReflectionsInLocalAccountingWhenChangesAreMadeOnServer();
EndProcedure

&AtServer
Procedure ReflectionsInLocalAccountingWhenChangesAreMadeOnServer()
	
	MechanismData = TMCommonUseClientServer.GetEngineDataFromFormCache(ThisObject, "GLAccountSettings");
	If Not ValueIsFilled(MechanismData) Then
		Return;
	EndIf;
	
	GLAccountSettings = MechanismData.AccountingAccountSettings[Object.GLAccountSettings];
	If Not ValueIsFilled(GLAccountSettings) Then
		Return;
	EndIf;
	
	
	
EndProcedure

&AtServer
Procedure ListOfPersonsChangedOnServer()

	ListOfIndividualsEnabledWhenChangedOnServer();
	
	UpdateCurrencyData();

EndProcedure

&AtServer
Procedure ListOfIndividualsEnabledWhenChangedOnServer()

	If Object.TransferToEmployeeViaABank Then
		Object.Currency = Common.ObjectAttributeValue(Object.BankAccount, "CashCurrency");
	EndIf;

	Object.ARAPDetails.Clear();
	InitializePaymentDecryption();
	SetRestrictionOnTypeOfPaymentDecryptionContract();
	FillInCurrencyOfMutualSettlementsOfDocument();

EndProcedure

&AtClient
Function DocumentAmountOnChangeClient()
	
	FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, Object.DocumentAmount, False);
	
	Return True;
	
EndFunction

&AtServer
Procedure DocumentAmountOnChangeServer()
	
	If Object.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion Then
		RecalculateConversionParameters("ConversionRate");
	EndIf;
	
	VATConversionParameters = New Structure("PriceIncludesVAT", True);
	StructureOfActions = New Structure("RecalculateVATAmount", VATConversionParameters);
	BatchProcessingOfTablePartServer.TreatTS(Object.ARAPDetails, StructureOfActions);
	
	SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning();
	SetRestrictionOnTypeOfPaymentDecryptionContract();
	GenerateHyperlinkCaptionPaymentObjectDetails();
	
	If Object.RecordCommission Then
		Object.FeeAmount = CashClientServer.CalculateCommissionAmount(Object.DocumentAmount, CommissionRate, "Return");
		Items.GroupCommission.Title = TitleOfAcquiringCommission(Object.FeeAmount, Object.Currency, CommissionRate);
	EndIf;
	
	FillInSettlementRate();
	CalculateAmountOfSettlements_();
	FillInCurrencyOfMutualSettlementsOfDocument();
	
EndProcedure

&AtClient
Function CurrencyOnChangeClient()
	
	If CurrentCurrency = Object.Currency Then
		Return False;
	EndIf;
	
	Object.CashAccount = Undefined;
	
	Return True;
	
EndFunction

&AtServer
Procedure CurrencyOnChangeServer(ReFillInAttributes = True)
	
	AfterChangingCurrency();
	
	FormItemsManagement();
	
EndProcedure

&AtServer
Procedure CurrencyOfConversionOnChangeServer()
	
	RecalculateConversionParameters("CurrencyOfConversion");
	SetConversionAmountHeader();
	
EndProcedure

&AtServer
Procedure MultiplicityOfConversionRateWhenChangingOnServer()

	RecalculateConversionParameters("ConversionRateMultiplier");

EndProcedure

#EndRegion

#Region OnChangeAttributes

&AtServer
Procedure AfterChangingCurrency()

	FillInSubordinatePropertiesForStatistics("Currency");
	
	ClearPaymentFormData();
	
	SetPaymentWithConversionAttribute(Object.PaymentWithConversion);
	
	If Object.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion Then
		CurrencyOfConversionOnChangeServer();
	EndIf;
	
	CashServer.ConversionOfDocumentAmountsIntoCurrency(Object, CurrentCurrency, Object.Currency);
	CashServer.SetPaymentAmountHeader(Object.Currency, Items);
	InformationForRegulatoryBodiesIsRequired = (Common.ObjectAttributeValue(Object.Currency, "Code") = "980");
	
	CheckCurrencyCompliance();
	FillInDetailsOfDocumentOnFormOfPayment();
	
	CashServer.UpdateSettlementCurrencyOfPaymentDecryption(
		"Document.PaymentRequest", Object, CurrencyOfComplianceAccounting);
	
	FillMultiplicityCourseWithText();
	FillInCurrencyOfMutualSettlementsOfDocument();
	
	UpdateAmountUnallocated();
	GenerateHyperlinkCaptionPaymentObjectDetails();
	
	CurrentCurrency = Object.Currency;

EndProcedure

&AtServer
Procedure UpdateCurrencyData()

	If CurrentCurrency <> Object.Currency Then
		AfterChangingCurrency();
	EndIf;

EndProcedure

&AtServer
Procedure ClearPaymentFormData()

	If Object.PaymentMethodCash 
		And Object.PaymentMethodBankAccount Then
		
		Object.BankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
		Object.CashAccount = Catalogs.CashAccounts.EmptyRef();
		Object.BankAccountBeneficiary = Catalogs.CompaniesBankAccounts.EmptyRef();
		Object.CashAccountRecipient = Catalogs.CashAccounts.EmptyRef();
		CurrencyOfPayersAccount = Undefined;
		CurrentBankAccount = Object.BankAccount;
		
	EndIf;

EndProcedure

&AtServer
Procedure DecryptionOfTheCalculationObjectWhenChangingServer(LineID)
	
	TableRow = Object.ARAPDetails.FindByID(LineID);
	CashServer.CheckFillOutContract(Object, LineID);
	SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning();
	
	If Not ValueIsFilled(TableRow.VATRate) Then
		FillInLBBidByDefault(LineID);
	EndIf;
	RecalculateVATAmount(LineID);
	ARAPAccountingFormWork.BlockSettlementObjects(ThisObject);
	
	YouAreAllowedToWorkWithAffiliatedPartners(TableRow);
	
	CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object, LineID, True);
	
	SetRestrictionOnTypeOfPaymentDecryptionContract();
	GenerateHyperlinkCaptionPaymentObjectDetails();
	CalculateControlPaymentFlagForSettlementObjects();
	ProcessIPChange(TableRow);
	
EndProcedure

&AtServer
Procedure PaymentIdOnChangeAtServer()
	
	ProcessIPChange();
	
EndProcedure

&AtClient
Procedure TransferToEmployeeViaBankONChangeOnClient(Item)

	If TransferToEmployeeViaABank = 1 Then
		PaymentMethod = "BankAccountPayment";
	Else
		PaymentMethod = "Any_";
	EndIf;
	
	PaymentMethodOnChange(Item);

EndProcedure

#EndRegion

#Region Properties

// StandardSubsystems.Properties
&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.TabularSection            = Object.ReferenceDocuments;
	CheckParameters.CheckForPromiscuity = False;
	CheckParameters.CheckedAttributes.Insert("PaymentType275FZ", NStr("vi = 'Kiểu thanh toán 275-FZ';
																		|ru = 'Тип платежа 275-ФЗ';
																		|en = 'Payment type 275-FZ'; fa = 'نوع پرداخت 275-FZ';
																		|it = 'Tipo di pagamento 275-Legge Federale';
																		|pl = 'Rodzaj płatności 275-OF';
																		|tr = 'Ödeme türü 275-F3'"));
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

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

#EndRegion

#Region FormItemsManagement

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	// In the statuses "Not approved", "Rejected", filling in the fields "Asset-passive articles" and "Expense articles" is optional.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ARAPDetailsExpenseItem.Name);
	ItemField.Field = New DataCompositionField(Items.DecodingWithoutSplittingTheCostItem.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.StatusesOfPaymentRequests.NotAgreedUpon);
	ValueList.Add(Enums.StatusesOfPaymentRequests.IsRejected);
	ItemFilter.RightValue = ValueList;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CounterpartyBankAccount.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.CounterpartyBankAccount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.BankAccountBeneficiary.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BankAccountBeneficiary");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CounterpartyBankAccount.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.BankAccountBeneficiary.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PaymentMethodBankAccount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PaymentMethodOfPaymentRequest");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.PaymentForms.BankAccountPayment;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CounterpartyBankAccount.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.CounterpartyBankAccount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.CounterpartyBankAccount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.StatusesOfPaymentRequests.AgreedUpon);
	ValueList.Add(Enums.StatusesOfPaymentRequests.AmountDue);
	ItemFilter.RightValue = ValueList;
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PaymentMethodBankAccount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PaymentMethodOfPaymentRequest");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.PaymentForms.BankAccountPayment;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PaymentMethodOfPaymentRequest");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.BankAccountBeneficiary.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BankAccountBeneficiary");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PaymentMethodBankAccount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PaymentMethodOfPaymentRequest");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.PaymentForms.BankAccountPayment;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PaymentMethodOfPaymentRequest");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.BankAccountBeneficiary.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CashAccountRecipient.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.CurrencyConversion;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
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
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Tự động>';
													|ru = '<автоматически>';
													|en = '<automatically>'; fa = '<automatically>';
													|it = '<автоматически>';
													|pl = '<automatically>';
													|tr = '<otomatik olarak>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	// ARAPCurrency
	CashServer.SetConditionalAppearanceOfSettlementCurrency(ThisObject);
	
	// Partner
	CashServer.SetPartnerConditionalAppearance(ThisObject);
	
	// VATAmount
	CashServer.SetConditionalAppearanceOfVATAmountOfPaymentDecryption(ThisObject);
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	CashServer.ManagingFormElementsWhenReadingCreatingOnServer(ThisObject);
	
	UsePayrollTM       = Constants.UsePayroll.Get();
	//++ WE
	PayrollAndHumanResourcesWE           = GetFunctionalOption("PayrollAndHumanResourcesWE");
	//-- WE
	UseMultipleCurrencies             = GetFunctionalOption("UseMultipleCurrencies");
	UseCurrencyPayments            = GetFunctionalOption("UseCurrencyPayments");
	UseIntercompanyContracts = GetFunctionalOption("UseIntercompanyContracts");
	UseCustomerContracts         = GetFunctionalOption("UseCustomerContracts");
	UseContractsWithVendors      = GetFunctionalOption("UseContractsWithVendors");
	UseAccountingOfOtherAssetsAndLiabilities  = GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities");
	UseDataSynchronization        = GetFunctionalOption("UseDataSynchronization");
	UseVATAccounting                    = GetFunctionalOption("UseVATAccounting");
	UsingPartnersAsCounterparties  = GetFunctionalOption("UsePartnersAsCounterparties");
	
	CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	ApprovalRight = UserRightsCached.PaymentRequestsApproval();
	ConfirmationRight  = UserRightsCached.ApprovalOfPaymentRequestsForPayment();

	If ValueIsFilled(Object.Organization) Then
		LegalEntityIndividual = Common.ObjectAttributeValue(Object.Organization, "LegalEntityIndividual");
		BranchesOfOrganization.LoadValues(Catalogs.Companies.BranchesWithPaymentsThroughParentOrganization(Object.Organization));
	EndIf;
	
	CounterpartyLegEntInd = Common.ObjectAttributeValue(Object.Counterparty, "LegalEntityIndividual");
	
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
	
	CurrentCurrency = Object.Currency;
	CurrentStatus = Object.Status;
	CurrentCounterparty = Object.Counterparty;
	CurrentBankAccount = Object.BankAccount;
	CurrentCompany = Object.Organization;
	
	PaymentMethodBankAccount = Enums.PaymentForms.BankAccountPayment;
	
	GetDefaultServerPartner(Object.Counterparty, Partner, Object.BusinessOperation);
	GetDefaultContractServer(Object.Counterparty, Object.CounterpartyBankAccount, False);
	
	InitializePaymentDecryption();
	
	FillInPaymentDetailsForApplication();
	CashServer.FillInListOfAdvanceReportPeriodSelections(ThisObject, Object.PaymentDate);
	ExpenseReportPeriodDate = (TypeOf(ExpenseReportPeriod) = Type("Date"));
	
	PersonsList = Number(Object.PersonsList);
	TransferToEmployeeViaABank = Number(Object.TransferToEmployeeViaABank);
	
	FillInListOfBusinessOperations();
	SpecifyListOfBusinessOperations();
	FillInListOfBusinessOperationsOnSalary();
	SetHeadingIncomeExpenseItem();
	SetConversionAmountHeader();
	CashServer.DetermineCurrencyPayment(ThisObject);
	
	FillInCurrencyOfMutualSettlementsOfDocument();
	FillMultiplicityCourseWithText();
	
	InformationForRegulatoryBodiesIsRequired = (Common.ObjectAttributeValue(Object.Currency, "Code") = "980");
	CodesOfInstructionsForBank = LabelInstructionCodes(Object);
	
	PaymentMethodIsLimited = PaymentMethodIsLimited();
	FormItemsManagement();
	CashServer.GetAvailableBusinessOfOperationsBasedOn(
		Object.DocumentBasis, Object.PaymentMethodOfPaymentRequest, AvailableBaseOfOperations);
	SetListOfStatuses();
	
	SavedBusinessTransaction = Object.BusinessOperation;
	SavedBusinessOperationForSalary = Object.PayrollTransaction;
	
	PartnersAndCounterparties.TitleOfPartnerElementDependingOnBusinessOperation(
		ThisObject, "ARAPDetailsPartner", Object.BusinessOperation);
	PartnersAndCounterparties.TitleOfPartnerElementDependingOnBusinessOperation(
		ThisObject, "DecryptionWithoutPartitioningPartner", Object.BusinessOperation);
	If LimitsByBudgetingDataServer.RegisterOfBudgetingLimitsIsUsed() Then
		Items.OverLimits.Title = NStr("vi = 'Không có kiểm soát hạn mức';
										|ru = 'Без контроля лимита';
										|en = 'Without limit control'; fa = 'Without limit control';
										|it = 'Без контроля лимита';
										|pl = 'Without limit control';
										|tr = 'Limit kontrolü olmadan'");
	EndIf;
EndProcedure

&AtClient
Procedure ConfigureDependentFormElements(ChangedProps = "")
	
	CashClientServer.CustomizeFormElements(ThisObject, ChangedProps, FormAttributes(ThisObject));
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(ChangedProps = "") Export
	
	CashClientServer.CustomizeFormElements(ThisObject, ChangedProps, FormAttributes(ThisObject));
	
EndProcedure

&AtClientAtServerNoContext
Function FormAttributes(Form)
	
	FormAttributes = New Structure;
	FormAttributes.Insert("UseLocal");
	FormAttributes.Insert("PaymentMethodIsLimited");
	FormAttributes.Insert("PaymentMethod");
	FormAttributes.Insert("UseMultipleCurrencies");
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
	FormAttributes.Insert("ApprovalRight");
	FormAttributes.Insert("ConfirmationRight");
	FormAttributes.Insert("TextNotPaid");
	FormAttributes.Insert("PaymentOfVATToBudgetByCertainTransactions");
	FormAttributes.Insert("UseDataSynchronization");
	FormAttributes.Insert("Modified");
	FormAttributes.Insert("AmountUnallocated");
	FormAttributes.Insert("UseIntercompanyContracts");
	FormAttributes.Insert("UseCustomerContracts");
	FormAttributes.Insert("UseContractsWithVendors");
	FormAttributes.Insert("TheIndication20195286YIsValid");
	FormAttributes.Insert("ARAPCurrency");
	FormAttributes.Insert("CurrencyOfComplianceAccounting");
	FormAttributes.Insert("BalanceOfPayment");
	FormAttributes.Insert("ContractRateOption");
	FormAttributes.Insert("ARAPObjectType");
	FormAttributes.Insert("ExchangeRateNumeratorOfMutualSettlements");
	FormAttributes.Insert("UsePaymentsToSelfEmployedPersons");
	
	FormAttributes.Insert("CounterpartyLegEntInd");
	FormAttributes.Insert("MultipleARAPCurrency");
	FormAttributes.Insert("SBPHyperlinkIsAvailable");
	
	FormAttributes.Insert("UIPIsDifferent");
	
	FillPropertyValues(FormAttributes, Form);
	
	Return FormAttributes;
	
EndFunction

&AtServer
Procedure InitializePaymentDecryption()
	
	ArrayOfOperationDetails = New Array;
	Documents.PaymentRequest.FillInNamesOfBusinessTransactionDetails(
		Object, Undefined, ArrayOfOperationDetails);
	
	If ArrayOfOperationDetails.Find("ARAPDetails") = Undefined Then
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
			CompleteVATTaxation(False);
			Items.ARAPDetails.CurrentRow = Object.ARAPDetails[0].GetID();
			DecryptionSwitch = 0;
		Else
			CompleteVATTaxation(False);
			DecryptionSwitch = 1;
		EndIf;
		FillInCurrencyOfMutualSettlementsOfDocument();
		CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object, , True);
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
	Documents.PaymentRequest.FillInNamesOfBusinessTransactionDetails(
		Object, Undefined, ArrayOfOperationDetails);
	
	SetPaymentForm();
	ConfigureAvailablePaymentMethods();
	
	CashServer.SetCounterpartySelectionParameters(Object, Items.Counterparty);
	CashServer.SetPartnerSelectionParameters(Object, Items.ARAPDetailsPartner);
	CashServer.SetPartnerSelectionParameters(Object, Items.DecryptionWithoutPartitioningPartner);
	SetParametersForSelectingBankAccountOfCashier();
	SetParametersForSelectingCounterpartySBankAccount(Object, Items.CounterpartyBankAccount);
	CashServer.SetParametersForSelectingRecipientSBankAccount(Object, Items.BankAccountBeneficiary, False);
	CashServer.SetParametersForSelectingRecipientSBankAccount(Object, Items.CashAccountRecipient);
	
	SetOrganizationSelectionParameters();
	SetParametersForSelectingRecipientOrganization();
	SetParametersForSelectingLoanDepositAgreements(Object.Counterparty);
	SetParametersForSelectingLeaseAgreement_(Object.Counterparty);
	If ArrayOfOperationDetails.Find("Contract") <> Undefined Then
		CashServer.SetContractSelectionParameters(ThisObject, Items.Contract);
	EndIf;
	
	CashServer.SetParametersForSelectingCashFlowItems(Object, Items.CashFlowItem);
	CashServer.SetParametersForSelectingCashFlowItems(Object, Items.DecodingWithoutSplittingTheCashFlowItem);
	CashServer.SetParametersForSelectingCashFlowItems(Object, Items.ARAPDetailsCashFlowItem);
	CashServer.CompleteVATTaxation(Object, Object.VATTaxation, Items.DecodingWithoutSplittingVATTaxation,, False);
	CashServer.EstablishLinksBetweenVATRateSelectionParameters(Object, Items.DecodingWithoutSplittingTheVATRate);
	CashServer.EstablishLinksBetweenVATRateSelectionParameters(Object, Items.ARAPDetailsVATRate);
	CashServer.SetParametersForSelectingDirectionOfActivity(Object, Items.LineOfBusiness);
	CashServer.SetParametersForSelectingDirectionOfActivity(Object, Items.DirectionOfReturnActivity);
	CashServer.SetParametersForSelectingDirectionOfActivity(Object, Items.DecodingWithoutSplittingTheDirectionOfActivity);
	
	ElementsToChange = New Array;
	ElementsToChange.Add("AllocationByAccountsSum");
	ElementsToChange.Add("PersonalAccountsOfStaffSum");
	ElementsToChange.Add("BankAccountsOfCounterpartyListSum");
	CashServer.SetPaymentAmountHeader(Object.Currency, Items, ElementsToChange);
	Items.LabelCurrencyCommission.Title = String(Object.Currency);
	
	Items.GroupCommission.Title = TitleOfAcquiringCommission(Object.FeeAmount, Object.Currency, CommissionRate);
	
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
			MaturityDateWithoutSplitting = NStr("vi = '<Tự động>';
												|ru = '<автоматически>';
												|en = '<automatically>'; fa = '<automatically>';
												|it = '<автоматически>';
												|pl = '<automatically>';
												|tr = '<otomatik olarak>'");
		EndIf;
	EndIf;

	SetRestrictionOnTypeOfPaymentDecryptionContract();
	GenerateHyperlinkCaptionPaymentObjectDetails();
	
	SetVisibilityOfGiftCertificateSelectionButton();
	
	SetDecryptionSwitchToBeAvailable();
	UpdateAmountUnallocated();
	
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
	AvailableTransactions.Add(Operations.SalaryPayment);
	AvailableTransactions.Add(Operations.PaymentToLessor);
	AvailableTransactions.Add(Operations.PaymentOnLoansAndBorrowingsReceived);
	AvailableTransactions.Add(Operations.TransferToDeposits);
	AvailableTransactions.Add(Operations.CashIssueAsLoanToCounterparty, NStr("vi = 'Chi cho đối tác vay';
																			|ru = 'Выдача займа контрагенту';
																			|en = 'Loan to counterparty'; fa = 'وام به طرف حساب';
																			|it = 'Emissione del prestito al contraente';
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
Procedure FillInListOfBusinessOperationsOnSalary()
	
	Operations = Enums.BusinessTransactions;
	AvailableTransactions = Items.PayrollTransaction.ChoiceList;
	AvailableTransactions.Clear();
	
	AvailableTransactions.Add(Operations.SalaryPaymentToBankAccounts, NStr("vi = 'Để tài khoản cá nhân';
																			|ru = 'На лицевые счета';
																			|en = 'To personal accounts'; fa = 'به حساب‌های شخصی';
																			|it = 'Sui conti correnti';
																			|pl = 'Na konta osobiste';
																			|tr = 'Kişisel hesaplara'"));
	AvailableTransactions.Add(Operations.SalaryPaymentViaCashAccount, NStr("vi = 'Qua quỹ';
																			|ru = 'Через кассу';
																			|en = 'Via cash account'; fa = 'از طریق صندوق';
																			|it = 'Tramite la cassa';
																			|pl = 'Przez kasę';
																			|tr = 'Kasa aracılığıyla'"));
	
EndProcedure

&AtServer
Procedure SpecifyListOfBusinessOperations()
	
	ItemBusinessOperation = Items.BusinessOperation;
	
	CashServer.EstablishVisibilityOfTransferOperationsBetweenOrganizations(ItemBusinessOperation);
	CashServer.EstablishVisibilityOfInternalTransferOperations(ItemBusinessOperation);
	CashServer.EstablishVisibilityOfOperationOtherCashDisbursement(ItemBusinessOperation);
	CashServer.EstablishVisibilityOfTransactionsUnderLoanAndDepositAgreements(ItemBusinessOperation);
	CashServer.EstablishVisibilityOfPaymentToLandlordOperation(ItemBusinessOperation);
	CashServer.EstablishVisibilityOfOperationsToLoansToEmployees(ItemBusinessOperation);
	CashServer.EstablishVisibilityOfAcquiringOperations(ItemBusinessOperation);
	
EndProcedure

&AtServer
Procedure SetListOfStatuses()
	
	ChoiceList = Items.Status.ChoiceList;
	
	ChoiceList.Clear();
	
	If Not Object.Status = Enums.StatusesOfPaymentRequests.AmountDue
		And Not Object.Status = Enums.StatusesOfPaymentRequests.AgreedUpon Then
		ChoiceList.Add(Enums.StatusesOfPaymentRequests.NotAgreedUpon);
	EndIf;
	
	If (ApprovalRight And Object.Status = Enums.StatusesOfPaymentRequests.NotAgreedUpon)
		Or Object.Status = Enums.StatusesOfPaymentRequests.AgreedUpon Then
		ChoiceList.Add(Enums.StatusesOfPaymentRequests.AgreedUpon);
	EndIf;
	
	If (ConfirmationRight 
		And (Object.Status = Enums.StatusesOfPaymentRequests.AgreedUpon
		Or Object.Status = Enums.StatusesOfPaymentRequests.NotAgreedUpon))
		Or Object.Status = Enums.StatusesOfPaymentRequests.AmountDue Then
		ChoiceList.Add(Enums.StatusesOfPaymentRequests.AmountDue);
	EndIf;
	
	If Object.Status = Enums.StatusesOfPaymentRequests.NotAgreedUpon
		Or Object.Status = Enums.StatusesOfPaymentRequests.AgreedUpon
		Or (ConfirmationRight And Object.Status = Enums.StatusesOfPaymentRequests.AmountDue)
		Or Object.Status = Enums.StatusesOfPaymentRequests.IsRejected Then
		ChoiceList.Add(Enums.StatusesOfPaymentRequests.IsRejected);
	EndIf;
	
EndProcedure

&AtServer
Procedure ConfigureAvailablePaymentMethods()
	
	ChoiceList = Items.PaymentMethod.ChoiceList;
	ChoiceList.Clear();
	CashPayment = ChoiceList.Add("CashAccountPayment_", NStr("vi = 'Bằng tiền mặt';
															|ru = 'Наличными';
															|en = 'Cash'; fa = 'صندوق';
															|it = 'In contanti';
															|pl = 'Gotówką';
															|tr = 'Nakit'"));
	NonCashPayment = ChoiceList.Add("BankAccountPayment", NStr("vi = 'Chuyển khoản';
																|ru = 'Безналичными';
																|en = 'Bank account'; fa = 'حساب بانکی';
																|it = 'Cashless';
																|pl = 'Bezgotówkowymi';
																|tr = 'Elektronik'"));
	AnyPayment_ = ChoiceList.Add("Any_", NStr("vi = 'Trong mọi biểu mẫu';
												|ru = 'В любой форме';
												|en = 'Any'; fa = 'هر';
												|it = 'In qualsiasi modo';
												|pl = 'W dowolnej formie';
												|tr = 'Herhangi bir formda'"));
	CardPayment = ChoiceList.Add("PaymentCard", NStr("vi = 'Thẻ thanh toán';
													|ru = 'Платежной картой';
													|en = 'With payment card'; fa = 'با کارت پرداخت';
													|it = 'Con la carta di pagamento';
													|pl = 'Kartą płatniczą';
													|tr = 'Banka kartı ile'"));
	
	If (Object.BusinessOperation <> Enums.BusinessTransactions.RefundToCustomer)
		Or Not GetFormFunctionalOption("UsePaymentByCards") Then
		Items.PaymentMethod.ChoiceList.Delete(CardPayment);
	EndIf;
	
	PaymentRequestLocalization.SupplementAvailableFormsOfPayment(ThisObject);
	
EndProcedure

&AtServer
Procedure FillInPaymentDetailsForApplication()
	
	BalanceOfPayment = BalanceOfPaymentForApplication(Object.Ref);
	
	If Not Object.Posted Or Object.DocumentAmount = BalanceOfPayment Then
		LabelActualPayment = StringFunctions.FormattedString(
			NStr("vi = '<span style=""color: %1"">Chưa thanh toán</span>';
				|ru = '<span style=""color: %1"">Не оплачена</span>';
				|en = '<span style=""color: %1"">Not paid</span>'; fa = '<span style=""color: %1"">Not paid</span>';
				|it = '<span style=""color: %1"">Не оплачена</span>';
				|pl = '<span style=""color: %1"">Not paid</span>';
				|tr = '<span style=""color: %1"">Ödeme yapılmadı</span>'"), "TextColorWarning");
	ElsIf BalanceOfPayment = 0 Then
		If Object.Closed_ Then
			AmountClosed = AmountClosed(Object.Ref);
			LabelActualPayment = StringFunctions.FormattedString(
				NStr("vi = 'Đã thanh toán một phần, <span style=""color: %1"">đã đóng: %2</span>';
					|ru = 'Оплачена частично, <span style=""color: %1"">закрыто: %2</span>';
					|en = 'Paid partially, <span style=""color: %1"">closed: %2</span>'; fa = 'Paid partially, <span style=""color: %1"">closed: %2</span>';
					|it = 'Оплачена частично, <span style=""color: %1"">закрыто: %2</span>';
					|pl = 'Paid partially, <span style=""color: %1"">closed: %2</span>';
					|tr = 'Kısmen ödenmiş, <span style=""color: %1"">kapalı: %2</span>'"),
				"TextColorWarning", PrintFormGeneration.SumFormat(AmountClosed, Object.Currency));
		Else
			LabelActualPayment = StringFunctions.FormattedString(NStr("vi = 'Đã thanh toán toàn bộ';
																		|ru = 'Оплачена полностью';
																		|en = 'Fully paid'; fa = 'Fully paid';
																		|it = 'Pagata interamente';
																		|pl = 'Opłacono w całości';
																		|tr = 'Tamamen ödenmiş'"));
		EndIf;
	Else
		LabelActualPayment = StringFunctions.FormattedString(
			NStr("vi = 'Đã thanh toán một phần, <span style=""color: %1"">chưa thanh toán: %2</span>';
				|ru = 'Оплачена частично, <span style=""color: %1"">не оплачено: %2</span>';
				|en = 'Paid partially, <span style=""color: %1"">not paid: %2</span>'; fa = 'Paid partially, <span style=""color: %1"">not paid: %2</span>';
				|it = 'Оплачена частично, <span style=""color: %1"">не оплачено: %2</span>';
				|pl = 'Paid partially, <span style=""color: %1"">not paid: %2</span>';
				|tr = 'Kısmen ödenmiş, <span style=""color: %1"">ödeme yapılmadı: %2</span>'"),
			"TextColorWarning", PrintFormGeneration.SumFormat(BalanceOfPayment, Object.Currency));
	EndIf;
	
	ConfigureDependentFormElementsOnServer("BalanceOfPayment");
	
EndProcedure

&AtServerNoContext
Function BalanceOfPaymentForApplication(Ref)
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	ISNULL(Cash.SumBalance, 0) AS NotPaid
	|FROM
	|	AccumulationRegister.CashToBePaid.Balance(,
	|		PaymentRequest = &Ref
	|	) AS Cash
	|";
	
	Query.SetParameter("Ref", Ref);
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	
	Selection = QueryResult.Select();
	
	Return ?(Selection.Next(), Selection.NotPaid, 0);
	
EndFunction

&AtServerNoContext
Function AmountClosed(Ref)
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	-SUM(Cash.Sum) AS Closed
	|FROM
	|	AccumulationRegister.CashToBePaid AS Cash
	|WHERE
	|	Cash.PaymentRequest = &Ref
	|	AND Cash.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND Cash.Sum < 0
	|";
	
	Query.SetParameter("Ref", Ref);
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	
	Return QueryResult.Unload()[0].Closed;
	
EndFunction

&AtServer
Procedure FillInDetailsOfDocumentOnFormOfPayment()
	
	If Not ValueIsFilled(Object.CounterpartyBankAccount) Then
		If Object.BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder Then
			Recipient = Object.AdvanceHolder;
		Else
			Recipient = Object.Counterparty;
		EndIf;
		Object.CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(
			Recipient,
			Object.Currency);
	EndIf;
	If Not ValueIsFilled(Object.BankAccount) Then
		ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Object.Organization);
		ParametersOfAccount.Currency = Object.Currency;
		Object.BankAccount = Catalogs.CompaniesBankAccounts.GetDefaultBankAccount(ParametersOfAccount);
		CurrentBankAccount = Object.BankAccount;
		CurrencyOfPayersAccount = Common.ObjectAttributeValue(Object.BankAccount, "CashCurrency");
	EndIf;
	If Not ValueIsFilled(Object.CashAccount) Then
		Object.CashAccount = Catalogs.CashAccounts.GetCheckoutByDefault(
			Object.Organization,
			Object.Currency);
	EndIf;
	If Not ValueIsFilled(Object.BankAccountBeneficiary) Then
		ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(
			Object.CompanyRecipient);
		ParametersOfAccount.Currency = Object.Currency;
		Object.BankAccountBeneficiary = Catalogs.CompaniesBankAccounts.GetDefaultBankAccount(
			ParametersOfAccount);
	EndIf;
	If Not ValueIsFilled(Object.CashAccountRecipient) Then
		Object.CashAccountRecipient = Catalogs.CashAccounts.GetCheckoutByDefault(
			Object.CompanyRecipient,
			Object.Currency);
	EndIf;
	
EndProcedure

&AtServer
Procedure GetDefaultContractServer(Counterparty, CounterpartyBankAccount, FillInInvoiceUnderAgreement = True)
	
	ArrayOfAllProps = New Array;
	ArrayOfOperationDetails = New Array;
	Documents.PaymentRequest.FillInNamesOfBusinessTransactionDetails(
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
			
		EndIf;
		
		CounterpartyContract = CashServer.DefaultContract(
			CounterpartyContract, Partner, Counterparty, Object.Organization, ContractBusinessTransaction, Filter);
		
		If FillInInvoiceUnderAgreement Then
			PurchasesServerCall.FillInBankAccountsUnderAgreement(CounterpartyContract,, CounterpartyBankAccount);
			If (Object.Currency <> Common.ObjectAttributeValue(CounterpartyBankAccount, "CashCurrency")
				And Object.PaymentWithConversion)
				Or Object.PaymentMethodOfPaymentRequest = Enums.PaymentForms.CashAccountPayment_ Then
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
	
	Attributes =
		Catalogs.CounterpartyBankAccounts.GetBankAccountDetails(Object.CounterpartyBankAccount);
	PurposeOfPaymentText = Attributes.PurposeText;
	
	If ValueIsFilled(Object.PaymentPurposes) Then
		Object.PaymentPurposes = Object.PaymentPurposes + "
			|" + PurposeOfPaymentText;
	Else
		Object.PaymentPurposes = PurposeOfPaymentText;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetOrganizationSelectionParameters()
	
	ParametersArray = New Array;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices Then
		ParametersArray.Add(New ChoiceParameter("ModeForSelectingRelatedOrganizations", "OnlyInterconnected"));
	EndIf;
	
	Items.Organization.ChoiceParameters = New FixedArray(ParametersArray);
	
EndProcedure

&AtServer
Procedure SetParametersForSelectingRecipientOrganization()
	
	ParametersArray = New Array;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices Then
		
		ParametersArray.Add(New ChoiceParameter("ModeForSelectingRelatedOrganizations", "OnlyInterconnected"));
		ParametersArray.Add(New ChoiceParameter("Organization", Object.Organization));
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany
		Or Object.BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany Then
		
		ParametersArray.Add(New ChoiceParameter("ModeForSelectingRelatedOrganizations", "JustNotInterconnected"));
		ParametersArray.Add(New ChoiceParameter("Organization", Object.Organization));
		
	EndIf;
	
	Items.CompanyRecipient.ChoiceParameters = New FixedArray(ParametersArray);
	
EndProcedure

&AtServer
Procedure CheckAndClearOrganizationAndBankAccount()
	
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices
		And Not Catalogs.Companies.OrganizationIsInterconnectedWithOtherOrganizations(Object.Organization) Then
		Object.Organization = Undefined;
		Object.BankAccount = Undefined;
	EndIf;
	
EndProcedure

&AtServer
Procedure CheckAndClearRecipientOrganizationAndRecipientBankAccount()
	
	If ValueIsFilled(Object.Organization)
		And Object.BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices
		And Not Catalogs.Companies.OrganizationsAreInterconnectedByOrganizationalStructure(
			Object.Organization, Object.CompanyRecipient) Then
		Object.CompanyRecipient = Undefined;
		Object.BankAccountBeneficiary = Undefined;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetParametersForSelectingBankAccountOfCashier()
	
	ParametersArray = New Array;
	ParameterRelationships = New ChoiceParameterLink("Filter.Owner", "Object.Organization", LinkedValueChangeMode.Clear);
	ParametersArray.Add(ParameterRelationships);
	
	Items.BankAccount.ChoiceParameterLinks = New FixedArray(ParametersArray);
	Items.DistributionToAccountsBankAccount.ChoiceParameterLinks = New FixedArray(ParametersArray);
	
	If Object.AmountPlanning = Enums.MethodsOfPlanningRequestPayment.InPaymentCurrency Then
		ParameterRelationships = New ChoiceParameterLink("Filter.CashCurrency", "Object.Currency");
		ParametersArray.Add(ParameterRelationships);
	EndIf;
	
	Items.CashAccount.ChoiceParameterLinks = New FixedArray(ParametersArray);
	
EndProcedure

&AtServer
Procedure SetParametersForSelectingCounterpartySBankAccount(Object, CounterpartySBankAccountElement)
	
	ParametersArray = New Array;
	
	If (Object.BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder
		Or Object.BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToEmployee)
		And Not Object.TransferToEmployeeViaABank Then
		ParameterRelationships = New ChoiceParameterLink("Filter.Owner", "Object.AdvanceHolder", LinkedValueChangeMode.Clear);
		ParametersArray.Add(ParameterRelationships);
	Else
		ParameterRelationships = New ChoiceParameterLink("Filter.Owner", "Object.Counterparty", LinkedValueChangeMode.Clear);
		ParametersArray.Add(ParameterRelationships);
	EndIf;
	
	ChoiceParametersArray = New Array;
	ChoiceParameter = New ChoiceParameter("Filter.Closed", False);
	ChoiceParametersArray.Add(ChoiceParameter);
	
	CounterpartySBankAccountElement.ChoiceParameterLinks = New FixedArray(ParametersArray);
	CounterpartySBankAccountElement.ChoiceParameters = New FixedArray(ChoiceParametersArray)
	
EndProcedure

&AtServer
Procedure SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning()
	
	CashServer.SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning(ThisObject);
	
EndProcedure

&AtServer
Procedure SetParametersForSelectingLoanDepositAgreements(Counterparty)

	ParametersArray = New Array;
	
	If Not Object.Organization.IsEmpty() Then
		ParametersArray.Add(New ChoiceParameter("Filter.Organization", Object.Organization));
	EndIf;
	
	If ValueIsFilled(Object.PaymentMethodOfPaymentRequest)
		And (Object.PaymentMethodOfPaymentRequest = Enums.PaymentForms.BankAccountPayment
		Or Object.PaymentMethodOfPaymentRequest = Enums.PaymentForms.CashAccountPayment_) Then
		ParametersArray.Add(New ChoiceParameter("Filter.PaymentMethod", Object.PaymentMethodOfPaymentRequest));
	EndIf;
	
	ParametersArray.Add(New ChoiceParameter("Filter.Status", Enums.CounterpartyContractStatuses.Valid));
	ParametersArray.Add(New ChoiceParameter("Filter.ContractKind",
		Catalogs.LoanAndDepositContracts.NatureOfTransactionAgreement(Object.BusinessOperation)));
		
	ParametersArray.Add(New ChoiceParameter("Filter.DeletionMark",False));
	
	If Not Counterparty.IsEmpty() Then
		ParametersArray.Add(New ChoiceParameter("Filter.Counterparty", Counterparty));
	EndIf;
	
	NewSelectionOptions = New FixedArray(ParametersArray);
	
	Items.DecryptionWithoutSplittingTheLoanDepositAgreement.ChoiceParameters = NewSelectionOptions;
	Items.ARAPDetailsLoanDepositContract.ChoiceParameters = NewSelectionOptions;
	
EndProcedure

&AtServer
Procedure EstablishFormsOfPaymentForBusinessTransaction()
	
	FillingDataStructure = New Structure;
	FillingDataStructure.Insert("BusinessOperation", Object.BusinessOperation);
	FillingDataStructure.Insert("PayrollTransaction", Object.PayrollTransaction);
	
	Documents.PaymentRequest.FillInPaymentFormForBusinessTransaction(FillingDataStructure);
	
	If FillingDataStructure.Property("PaymentMethodCash")
		And FillingDataStructure.Property("PaymentMethodBankAccount")
		And FillingDataStructure.Property("MethodOfPaymentPaymentCard")
		And FillingDataStructure.Property("PaymentMethodOfPaymentRequest") Then
		
		FillPropertyValues(Object, FillingDataStructure,
			"PaymentMethodCash, PaymentMethodBankAccount, MethodOfPaymentPaymentCard, PaymentMethodOfPaymentRequest");
	EndIf;
	
EndProcedure

&AtServer
Procedure SetParametersForSelectingLeaseAgreement_(Counterparty)

	ParametersArray = New Array;
	If Not Object.Organization.IsEmpty() Then
		ParametersArray.Add(New ChoiceParameter("Filter.Organization", Object.Organization));
	EndIf;
	ParametersArray.Add(New ChoiceParameter("Filter.Status", Enums.CounterpartyContractStatuses.Valid));
	ParametersArray.Add(New ChoiceParameter("Filter.DeletionMark",False));
	If Not Counterparty.IsEmpty() Then
		ParametersArray.Add(New ChoiceParameter("Filter.Counterparty", Counterparty));
	EndIf;
	
	Items.ARAPDetailsLeaseContracts.ChoiceParameters = New FixedArray(ParametersArray);
	Items.DecryptionWithoutSplittingTheLeaseAgreement.ChoiceParameters = New FixedArray(ParametersArray);
	
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

// Fill in "StavkaNDS" in the "Decryption of payment" line if it was not filled out earlier from the "Accounts Object".
// 
// Parameters:
//  TableRowID_ - Number - ID for the "Decryption Payment" collection item.
//
&AtServer
Procedure FillInLBBidByDefault(TableRowID_)
	
	TableRow = Object.ARAPDetails.FindByID(TableRowID_);
	
	If TableRow <> Undefined Then
		VATAccountingERP.FillInVATRateForPayments_(TableRow.VATRate, TableRow.VATTaxation,
			Object.Organization, Object.Date);
	EndIf;
	
EndProcedure

&AtServer
Procedure RecalculateVATAmount(LineID)
	
	CashServer.RecalculateVATAmount(Object, LineID);
	
EndProcedure

&AtClient
Procedure SetVisibilityAvailabilityOfPaymentDecryptionElementPartner()

	CurTableColumn = Items.ARAPDetails.CurrentItem;
	
	TableRow = Items.ARAPDetails.CurrentData;
	
	If TableRow = Undefined Then
		Return;
	EndIf;
	
	RowData = New Structure("ARAPObject, LeaseContracts, LoanDepositContract");
	FillPropertyValues(RowData, TableRow);
	RowData.Insert("Ref", Object.Ref);
	
	CellViewOnly = YouCanTEditPartnerElement(RowData);
	
	CurTableColumn.TextEdit = Not CellViewOnly;
	CurTableColumn.DropListButton = Not CellViewOnly;
	CurTableColumn.ChoiceButton = Not CellViewOnly;
	CurTableColumn.ChoiceHistoryOnInput = ?(CellViewOnly, ChoiceHistoryOnInput.DontUse, ChoiceHistoryOnInput.Auto);
	
EndProcedure

&AtClient
Procedure UpdatePresentationOfMaturityDate()
	If Object.ARAPDetails.Count() = 0 
		Or Not ValueIsFilled(Object.ARAPDetails[0].MaturityDate) Then
		MaturityDateWithoutSplitting = NStr("vi = '<Tự động>';
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

&AtClient
Procedure ClearDistributionOfAccountsByPaymentForm()

	Indus = Object.AllocationByAccounts.Count() - 1;
	While Indus >= 0 Do
		If PaymentMethod = "CashAccountPayment_"
			And TypeOf(Object.AllocationByAccounts[Indus].BankAccountCashAccount) <> Type("CatalogRef.CashAccounts") Then
			Object.AllocationByAccounts.Delete(Indus);
		ElsIf (PaymentMethod = "BankAccountPayment"
			Or PaymentMethod = "SBP")
			And TypeOf(Object.AllocationByAccounts[Indus].BankAccountCashAccount) <> Type("CatalogRef.CompaniesBankAccounts") Then
			Object.AllocationByAccounts.Delete(Indus);
		EndIf;
		Indus = Indus - 1;
	EndDo;
	
	PaymentFormWhenChangingFragment();

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

&AtServer
Function PaymentMethodIsLimited() // One value
	
	If Object.BusinessOperation = Enums.BusinessTransactions.SalaryPayment Then
		AcceptableFormOfPayment = Documents.PaymentRequest.LimitingFormOfPayment(Object.PayrollTransaction);
	Else
		AcceptableFormOfPayment = Documents.PaymentRequest.LimitingFormOfPayment(Object.BusinessOperation);
	EndIf;
	
	Return (AcceptableFormOfPayment <> Undefined);
	
EndFunction

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
Procedure CheckCurrencyCompliance()
	
	If Object.PaymentMethodOfPaymentRequest = Enums.PaymentForms.CashAccountPayment_
		And Object.AmountPlanning = Enums.MethodsOfPlanningRequestPayment.InPaymentCurrency Then
		
		CashAccountCurrency = Common.ObjectAttributeValue(Object.CashAccount, "CashCurrency");
		ComparisonCurrency = Object.Currency;
		
		If CashAccountCurrency <> ComparisonCurrency Then
			Object.CashAccount = Undefined;
		EndIf;
		
	ElsIf Object.PaymentMethodOfPaymentRequest = Enums.PaymentForms.BankAccountPayment
		Or Object.PaymentMethodOfPaymentRequest = Enums.PaymentForms.InstantPayments Then
		
		AccountCurrency = Common.ObjectAttributeValue(Object.BankAccount, "CashCurrency");
		CounterpartyAccountCurrency = Common.ObjectAttributeValue(Object.CounterpartyBankAccount, "CashCurrency");
		
		ArrayOfAccounts_ = New Array;
		For Each InvoiceLine_ In Object.AllocationByAccounts Do
			If ValueIsFilled(InvoiceLine_.BankAccountCashAccount)
				And TypeOf(InvoiceLine_.BankAccountCashAccount) = Type("CatalogRef.CompaniesBankAccounts") Then
				ArrayOfAccounts_.Add(InvoiceLine_.BankAccountCashAccount);
			EndIf;
		EndDo;
		AccountCurrencies = Common.ObjectsAttributesValues(ArrayOfAccounts_, "CashCurrency");
		
		ComparisonCurrency = CashPlanningCurrency(AccountCurrency);
		
		If CounterpartyAccountCurrency <> ComparisonCurrency
			And Object.PaymentWithConversion Then
			Object.CounterpartyBankAccount = Undefined;
		EndIf;
		
		ForDeletion = New Array;
		For Each InvoiceLine_ In Object.AllocationByAccounts Do
			If ValueIsFilled(InvoiceLine_.BankAccountCashAccount)
				And TypeOf(InvoiceLine_.BankAccountCashAccount) = Type("CatalogRef.CompaniesBankAccounts") Then
				If AccountCurrencies[InvoiceLine_.BankAccountCashAccount].CashCurrency <> ComparisonCurrency
					And Not Object.PaymentWithConversion Then 
					ForDeletion.Add(InvoiceLine_);
				EndIf;
			EndIf;
		EndDo;
		
		For Each InvoiceLine_ In ForDeletion Do
			Object.AllocationByAccounts.Delete(InvoiceLine_);
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServer
Function CashPlanningCurrency(BankAccountCurrency)
	
	If Object.PaymentMethodOfPaymentRequest <> Enums.PaymentForms.BankAccountPayment Then
		Return Undefined;
	EndIf;
	
	If Object.AmountPlanning = Enums.MethodsOfPlanningRequestPayment.InARAPCurrency Then
		Return BankAccountCurrency;
	Else
		Return Object.Currency;
	EndIf;
	
EndFunction

&AtServer
Procedure SetPaymentForm()
	
	If Object.PaymentMethodCash And Object.PaymentMethodBankAccount Then
		PaymentMethod = "Any_";
	
	ElsIf Object.PaymentMethodCash Then
		PaymentMethod = "CashAccountPayment_";
		
	ElsIf Object.PaymentMethodBankAccount
		And Object.PaymentMethodOfPaymentRequest = Enums.PaymentForms.InstantPayments Then
		PaymentMethod = "SBP";
		
	ElsIf Object.PaymentMethodBankAccount Then
		PaymentMethod = "BankAccountPayment";
		
	ElsIf Object.MethodOfPaymentPaymentCard Then
		PaymentMethod = "PaymentCard";
		
	Else
		PaymentMethod = "";
		
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
	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	
EndProcedure

&AtServer
Procedure FillMultiplicityCourseWithText()
	
	For Each TSRow In Object.ARAPDetails Do
		CashServer.FormCourseDenominatorByText(TSRow, Object.Currency, CurrencyOfComplianceAccounting);
	EndDo;
	
EndProcedure

&AtServer
Procedure CalculateAmountOfSettlements_()
	
	For Each TSRow In Object.ARAPDetails Do
		CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
			TSRow, Object.Currency, CurrencyOfComplianceAccounting);
	EndDo;
	
EndProcedure

&AtServerNoContext
Function YouCanTEditPartnerElement(Data)
	
	Return (ValueIsFilled(Data.ARAPObject)
			And Common.ObjectAttributeValue(Data.ARAPObject,"Object") <> Data.Ref)
			Or ValueIsFilled(Data.LeaseContracts)
			Or ValueIsFilled(Data.LoanDepositContract);
	
EndFunction

&AtServer
Procedure SetVisibilityOfGiftCertificateSelectionButton()
	
	SaleOfGiftCertificateIsAllowed =
		RetailSalesLocalization.ItIsAllowedToSellGiftCertificateInDocument(Object.BusinessOperation);
	Items.ARAPDetailsPickUpGiftCertificate.Visible = SaleOfGiftCertificateIsAllowed;
	
EndProcedure

&AtServer
Procedure SetDecryptionSwitchToBeAvailable()
	
	If ValueIsFilled(Object.DocumentBasis)
		And TypeOf(Object.DocumentBasis) = Type("DocumentRef.PaymentCardTransaction") Then
		Items.DecryptionSwitch.Enabled = False;
	Else
		Items.DecryptionSwitch.Enabled = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessGiftCertificate(GiftCertificate)
	
	FoundRow = GiftCertificatesServer.AddGiftCertificateToTablePartOfPaymentDecryption(GiftCertificate, ThisObject);
	If FoundRow <> Undefined Then
		
		Modified = True;
		
		ARAPDetailsARAPObjectOnChangeServer(FoundRow.GetID());
		
		FillInCourseAndMultiplicityInDecryptionLine(FoundRow);
		CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
			FoundRow, Object.Currency, CurrencyOfComplianceAccounting);
		CashServer.FormCourseDenominatorByText(FoundRow, Object.Currency, CurrencyOfComplianceAccounting);
		CashServer.SetDesignAccuracyOfCourse(ThisObject);
		
		ConfigureDependentFormElementsOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenChangingCounterparty(
	Counterparty,
	CounterpartyBankAccount,
	FillInTranscriptForCounterparty = True,
	CurPartner = Undefined,
	CurrentDecryptionLine = Undefined)

	If FillInTranscriptForCounterparty Then
	
		If CurPartner = Undefined Then
			Partner = CashServer.GetCounterpartyPartner(Counterparty, Object.BusinessOperation);
		Else
			Partner = CurPartner;
		EndIf;
		
		GetDefaultContractServer(Counterparty, CounterpartyBankAccount);
		
		If ValueIsFilled(CounterpartyContract) Then
			ARAPObjectContract = ARAPObjectsServer.GetCalculationObjectFromLink(CounterpartyContract);
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
		
		SetParametersForSelectingLoanDepositAgreements(Counterparty);
		SetParametersForSelectingLeaseAgreement_(Counterparty);
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
	
	FillInCourseAndMultiplicityInDecryptionLine(CurrentTableRow);
	FillInCurrencyOfMutualSettlementsOfDocument();
	CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
		CurrentTableRow, Object.Currency, CurrencyOfComplianceAccounting);
	CashServer.FormCourseDenominatorByText(CurrentTableRow, Object.Currency, CurrencyOfComplianceAccounting);
	CashServer.SetDesignAccuracyOfCourse(ThisObject);

EndProcedure

&AtServer
Procedure YouAreAllowedToWorkWithAffiliatedPartners(TableRow)
	
	ReferencesArrray = CommonClientServer.ValueInArray(TableRow.ARAPObject);
	ComplianceOfContractCurrencyExchangeRate = ARAPAccountingServer.ComplianceOfARAPObjectsAndParametersOfContract(ReferencesArrray);
	TableRow.ItIsAllowedToWorkWithSubsidiaryPartners = ComplianceOfContractCurrencyExchangeRate[TableRow.ARAPObject].ItIsAllowedToWorkWithSubsidiaryPartners;
	TableRow.TheCalculationObjectMatchesTheDocument = ComplianceOfContractCurrencyExchangeRate[TableRow.ARAPObject].Object = Object.Ref;
	
EndProcedure

&AtServer
Procedure SetPaymentWithConversionAttribute(DefaultValue = False)

	Object.PaymentWithConversion = DefaultValue;
	
	If Object.AmountPlanning <> Enums.MethodsOfPlanningRequestPayment.InARAPCurrency Then
		CashServer.SetPaymentWithConversionAttribute(
			Object,
			"Document.PaymentRequest");
	Else
		
		Object.PaymentWithConversion = False;
		Return;
		
	EndIf;
	
	If Object.PaymentWithConversion Then
		
		Accounts = New Array;
		Accounts.Add(Object.CounterpartyBankAccount);
		Accounts.Add(Object.BankAccountBeneficiary);
		AccountCurrencies = Common.ObjectsAttributeValue(Accounts, "CashCurrency");
		
		If Object.Currency <> AccountCurrencies.Get(Object.CounterpartyBankAccount) Then
			Object.CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.EmptyRef();
		EndIf;
		
		If Object.Currency <> AccountCurrencies.Get(Object.BankAccountBeneficiary) Then
			Object.BankAccountBeneficiary = Catalogs.CompaniesBankAccounts.EmptyRef();
		EndIf;
		
		If Object.PaymentMethodOfPaymentRequest = Enums.PaymentForms.InstantPayments Then
			Object.PaymentMethodOfPaymentRequest = Enums.PaymentForms.BankAccountPayment;
		EndIf;
		
	Else
		
		If ValueIsFilled(CurrencyOfPayersAccount)
			And Object.Currency <> CurrencyOfPayersAccount
			And Object.AmountPlanning <> Enums.MethodsOfPlanningRequestPayment.InARAPCurrency Then
			
			Object.BankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
			Object.CashAccount = Catalogs.CashAccounts.EmptyRef();
			CurrencyOfPayersAccount = Undefined;
			CurrentBankAccount = Object.BankAccount;
			
		EndIf;
		
	EndIf;

EndProcedure

&AtServer
Procedure FillInCurrencyOnRecipientSAccount(Account)

	RecipientSCurrency = Common.ObjectAttributeValue(Account, "CashCurrency");
	
	If Object.Currency <> RecipientSCurrency
		And Object.PaymentWithConversion
		And ValueIsFilled(RecipientSCurrency) Then
		Object.Currency = RecipientSCurrency;
	EndIf;
	
	UpdateCurrencyData();

EndProcedure

&AtServer
Procedure CalculateControlPaymentFlagForSettlementObjects()

	ArrayOfCalculationObjects_ = Common.UnloadColumn(Object.ARAPDetails, "ARAPObject");
	Object.ControlPaymentByARAPObjects = Documents.PaymentRequest.ControlPaymentByARAPObjects(
																Object.BusinessOperation, ArrayOfCalculationObjects_);

EndProcedure

&AtServer
Procedure FillInPaymentDecryptionLineUnderContract(DecryptionString, ContractDetails_)

	FillPropertyValues(DecryptionString, ContractDetails_);
	DecryptionString.Contract = Object.Contract;
	
	FillInCourseAndMultiplicityInDecryptionLine(DecryptionString);
	CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
		DecryptionString, Object.Currency, CurrencyOfComplianceAccounting);
	CashServer.FormCourseDenominatorByText(DecryptionString, Object.Currency, CurrencyOfComplianceAccounting);
	CashServer.SetDesignAccuracyOfCourse(ThisObject);

EndProcedure

&AtServer
Procedure FillInUIP(IdOfDecryptionString)
	
	If ValueIsFilled(Object.PaymentID) And DecryptionSwitch = 1 Then
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
	
	UIPIsDifferent = Object.ARAPDetails.Total("UIPIndexIsDifferent") <> 0;
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
	ElsIf Item.Name = "sh_ShamsiInput_RequiredPaymentDate" Then
		RequiredPaymentDateOnChange(Items.RequiredPaymentDate);
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
