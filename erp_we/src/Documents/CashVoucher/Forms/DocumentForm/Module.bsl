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
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	ItemsAndDimensionsSelectionParameters = Documents.CashVoucher.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	//Setting up accounting accounts
	SetupParameters = Documents.CashVoucher.AccountingAccountSettings_(Object.BusinessOperation);
	GLAccountSettingsServer.OnCreateAtServer(ThisObject, SetupParameters);
	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisForm);
	
	GeneratingFiscalChecksServer.FormWhenCreatedOnServer(ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		
		If Parameters.Property("Basis") Then
			If ValueIsFilled(Parameters.Basis) And TypeOf(Parameters.Basis) <> Type("Structure") Then
				If TypeOf(Parameters.Basis) = Type("CatalogRef.GiftCertificates") Then
					Object.Basis = Parameters.Basis;
				Else
					Object.Basis = TMCommonUse.GetDocumentPresentation(Parameters.Basis,
						ObjectsPrefixesClientServer.NumberForPrinting(Parameters.Basis.Number),
						Parameters.Basis.Date);
				EndIf;
			EndIf;
			Basis = Parameters.Basis;
		EndIf;
		
		If ValueIsFilled(Object.CashRegister) Then
			CashRegisterParameters = New FixedStructure(Catalogs.CashRegisters.CashRegisterParameters(Object.CashRegister));
			AccessRights = SalesSettingsForUsersServer.CWPAccessRights(Users.CurrentUser());
		EndIf;
		CashServer.CheckFillOutContract(Object);
	EndIf;
	
	Items.DecryptionWithoutSplittingRepaymentDate.ReadOnly = Not AccessRight(
		"Edit",
		Metadata.Documents.CashVoucher.TabularSections.ARAPDetails.Attributes.MaturityDate);
	
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
	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	DocumentCorrection.OnCreateAtServer(ThisForm, Items.LineCorrection);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	If Not ValueIsFilled(Object.Ref) Then
		FinancesClient.CheckDocumentCompletionBasedOn(Object, Basis);
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
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectionResult, ChoiceSource)
	
	If ChoiceSource.FormName = "Document.PaymentRequest.Form.PaymentRequestSelectionInCashIssueNote" Then
		
		ProcessingSelectionFromApplications(SelectionResult.AddressOfRequestsInRepository);
		
	EndIf;
	If ChoiceSource.FormName = "Document.CashVoucher.Form.FormSalaryPayment" Then
		
		GetSalaryPaymentFromVault(SelectionResult);
		
	ElsIf ChoiceSource.FormName = "CommonForm.Paysheets" Then
		
		Modified = True;
		
		Object.Statement = SelectionResult.Statement;
		Object.RegistrationPeriod = SelectionResult.RegistrationPeriod;
		If Not ValueIsFilled(Object.AdvanceHolder) Then
			Object.AdvanceHolder = SelectionResult.Recipient;
		EndIf;
		StatementOnChangesAtServer();
		//++ WE
	ElsIf ChoiceSource.FormName = "Document.PayrollStatementHR.Form.ChoiceForm" Then
		
		Modified = True;
		
		Object.Statement = SelectionResult;
		StatementOnChangesAtServer();
		//-- WE
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
	
	ItemsAndDimensionsSelectionParameters = Documents.CashVoucher.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation);
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);

	//Setting up accounting accounts
	SetupParameters = Documents.CashVoucher.AccountingAccountSettings_(Object.BusinessOperation);
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
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
	If NotExecuteCheck1BeforeWrite Then
		NotExecuteCheck1BeforeWrite = False;
		Return;
	EndIf;
	
	BusinessTransactionsExceptionOperations = New Array;
	BusinessTransactionsExceptionOperations.Add(PredefinedValue("Enum.BusinessTransactions.SalaryPaymentViaCashAccount"));
	BusinessTransactionsExceptionOperations.Add(PredefinedValue("Enum.BusinessTransactions.SalaryPaymentByDistributor"));
	BusinessTransactionsExceptionOperations.Add(PredefinedValue("Enum.BusinessTransactions.SalaryPaymentToEmployee"));
	
	If BusinessTransactionsExceptionOperations.Find(Object.BusinessOperation) = Undefined
		And WriteParameters.WriteMode = DocumentWriteMode.Posting Then
		
		Cancel = True;
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("WriteParameters", WriteParameters);
		CallbackDescription = New CallbackDescription(
			"BeforeRecordingOfferToRecalculateAmountOfDocument", ThisObject, AdditionalParameters);
		
		FinancesClient.RecalculateAmountOfDocumentBasedOnPaymentDecryption(ThisForm, CallbackDescription);
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

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
	Notify("Write_CashVoucher", WriteParameters, Object.Ref);
	ARAPAccountingClient.FormAfterRecording(ThisForm);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisForm, Object, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	DocumentCorrectionClient.AfterWrite(Object);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Handler of the "Properties" mechanism
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	
	ARAPAccountingServer.BeforeWriteAtServer(ThisForm, CurrentObject);
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
	//Setting up accounting accounts
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
	
	//Setting up accounting accounts
	GLAccountSettingsServer.AfterWriteAtServer(ThisObject);
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	ARAPAccountingFormWork.FormAfterRecordingOnServer(ThisForm, CurrentObject.AdditionalProperties);
	
	FillInParametersOfCalculationObjectInDecryption();
	FillInCurrencyOfMutualSettlementsOfDocument();
	FillMultiplicityCourseWithText();
	CompleteVATTaxation(False);
	SetRestrictionOnTypeOfPaymentDecryptionContract();
	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	
	CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	SavedBusinessTransaction = Object.BusinessOperation;
	
	GeneratingFiscalChecksServer.FormWhenChangingBankingDetails(ThisObject);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
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
	
	DocumentCorrectionClient.NotificationProcessing(ThisForm, EventName, Parameter, Source);
	
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
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	ForceCloseTheForm = True;
	
EndProcedure

&AtServer
Procedure StatementOnChangesAtServer()
	
	//++ WE
	If PayrollAndHumanResourcesWE Then
		
		Object.PayrollPayment.Clear();
		
		DataOfStatement = IntegrationPayrollAndHumanResourcesServer.DataOfStatement(Object.Statement);
		HeaderAttributes = DataOfStatement.HeaderAttributes;
		
		If DataOfStatement.Table.Count()= 0 Then
			ErrorText = NStr("vi = 'Trong bảng thanh toán đã chọn không có dữ liệu';
							|ru = 'В выбранной ведомости нет данных';
							|en = 'There is no data in the selected paysheet'; fa = 'There is no data in the selected paysheet';
							|it = 'There is no data in the selected paysheet';
							|pl = 'There is no data in the selected paysheet';
							|tr = 'Seçilen bordroda veri yok.'");
			Common.MessageToUser(ErrorText, ,"Statement", "Object");
		EndIf;
		
		FillPropertyValues(Object, HeaderAttributes,,"BusinessOperation");
		If ValueIsFilled(HeaderAttributes.DateOfPayment) Then
			Object.RegistrationPeriod = HeaderAttributes.DateOfPayment;
		EndIf;
		
		TableData = DataOfStatement.Table;
		For Each StatementLine In TableData Do
			NewLinePayout  = Object.PayrollPayment.Add();
			FillPropertyValues(NewLinePayout, StatementLine);
		EndDo;
		Object.DocumentAmount = Object.PayrollPayment.Total("Sum");
		UpdateDisplayRowPersons();
		
	Else
	//-- WE
		Object.PayrollPayment.Clear();
		
		If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SalaryPaymentViaCashAccount") Then
			Object.AdvanceHolder = Catalogs.Persons.EmptyRef();
		EndIf;
		
		FillInAmountOfUnpaidPayrollATServer();
		
		UpdateDisplayRowPersons();
	//++ WE
	EndIf;
	//-- WE
	
	Return; // in ut empty
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	NeedProcessing = DateOnChangeClient();
	If NeedProcessing Then
		DateOnChangeServer();
	EndIf;
	
EndProcedure

&AtClient
Function DateOnChangeClient()
	
	Object.ExpenseReportDate =
		CashClient.RecalculateAdvanceReportDate(ExpenseReportPeriod, Object.Date);
	
	Return True;
	
EndFunction

&AtServer
Procedure DateOnChangeServer()
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	CompleteVATTaxation();
	FillInCourseCourseDenominatorOfSettlements();
	CalculateAmountOfSettlements_();
	FillMultiplicityCourseWithText();
	FillInCurrencyOfMutualSettlementsOfDocument();
	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	
	SetRestrictionOnTypeOfPaymentDecryptionContract();
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	Notification = New CallbackDescription("BusinessOperationWhenChangingFragment", ThisObject);;
	BusinessOperationOnChangeClient(Notification);
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChangeClient(Notification)
	
	If SavedBusinessTransaction = Object.BusinessOperation Then
		Return;
	EndIf;
	
	SetPaymentByRequestAttribute();
	
	Object.CashAccountRecipient = Undefined;
	Object.CompanyRecipient = Undefined;
	
	If Object.PayrollPayment.Count() > 0 Then
		QueryText = NStr("vi = 'Danh sách người lao động sẽ bị xóa. Tiếp tục?';
						|ru = 'Список работников будет очищен. Продолжить?';
						|en = 'Employee list will be cleared. Continue?'; fa = 'Employee list will be cleared. Continue?';
						|it = 'I dati nell''elenco dei dipendenti verranno eliminati. Continuare?';
						|pl = 'Lista pracowników zostanie wyczyszczona. Kontynuować?';
						|tr = 'Çalışan listesi silinecektir. Devam edilsin mi?'");
		ResponseCode = Undefined;
		AdditionalParameters = New Structure("Notification", Notification);
		NotificationCompletion = 
			New CallbackDescription("BusinessOperationOnChangeCompletion", ThisObject, AdditionalParameters);
		ShowQueryBox(NotificationCompletion, QueryText, QuestionDialogMode.YesNo);
		Return;
	EndIf;
	
	RunCallback(Notification);
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	ResponseCode = QuestionResult;
	
	If ResponseCode = DialogReturnCode.No Then
		Object.BusinessOperation = SavedBusinessTransaction;
		Return;
	EndIf;
	
	Object.PayrollPayment.Clear();
	
	RunCallback(AdditionalParameters.Notification);
	
EndProcedure

&AtClient
Procedure BusinessOperationWhenChangingFragment(Result, AdditionalParameters) Export
	
	BusinessOperationOnChangeServer();
	
	UpdatePresentationOfMaturityDate();
	
EndProcedure

&AtServer
Procedure BusinessOperationOnChangeServer()
	
	InitializePaymentDecryption();
	
	If ValueIsFilled(Object.DocumentBasis)
		And AvailableBaseOfOperations.FindByValue(Object.BusinessOperation) = Undefined Then
		
		Object.DocumentBasis = Undefined;
		AvailableBaseOfOperations.Clear();
		
	EndIf;
	
	CashServer.CheckFillOutContract(Object);
		
	For Each DecryptionString In Object.ARAPDetails Do
		IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, DecryptionString, "Object.ARAPDetails");
	EndDo;
	
	SetPossibleValuesOfRecipientSCashRegister();
	
	CFItemByBT = Catalogs.CashFlowReportItems.CashFlowItemForBusinessTransaction(
		Object.BusinessOperation);
	Object.CashFlowItem = CFItemByBT;
	For Each PaymentDecryptionString In Object.ARAPDetails Do
		PaymentDecryptionString.CashFlowItem = CFItemByBT;
	EndDo;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices
		And Not Catalogs.Companies.OrganizationIsInterconnectedWithOtherOrganizations(Object.Organization) Then
		
		Object.CashAccount = Undefined;
		Object.Organization = Undefined;
		CurrencyOfComplianceAccounting = Undefined;
		CurrentCashAccount = Object.CashAccount;
	EndIf;
	
	ArrayOfAllProps = New Array; ArrayOfOperationDetails = New Array;
	Documents.CashVoucher.FillInNamesOfBusinessTransactionDetails(
		Object, ArrayOfAllProps, ArrayOfOperationDetails);
	If ArrayOfOperationDetails.Find("Counterparty") = Undefined Then
		Object.Counterparty = Undefined;
		Object.Contract = Undefined;
		For Each CurDecryptionString In Object.ARAPDetails Do
			CurDecryptionString.ARAPObject = Catalogs.ARAPObjects.EmptyRef();
		EndDo;
	EndIf;
	
	If Not ValueIsFilled(Object.Counterparty) Then
		ClearAdditionalExpenseInformation();
	EndIf;
	AccountingAccountSettings_ = Documents.CashVoucher.AccountingAccountSettings_(Object.BusinessOperation);
	GLAccountSettingsServer.WhenChangingSettings(ThisObject, AccountingAccountSettings_);
	ItemsAndDimensionsSelectionParameters = Documents.CashVoucher.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisObject);
	
	GeneratingFiscalChecksServer.FormWhenChangingBankingDetails(ThisObject);
	
	If (Object.BusinessOperation = Enums.BusinessTransactions.CashDepositToBankAccount
		Or Object.BusinessOperation = Enums.BusinessTransactions.CashCollectionToBank)
		And Not ValueIsFilled(Object.BankAccount) Then
		
		GetDefaultBankAccount();
		If Not ValueIsFilled(Object.BankAccount) And Not GetFunctionalOption("UseMultipleBankAccounts") Then
			Raise NStr("vi = 'Không thể điền trường ""Tài khoản ngân hàng"". Có thể là trong cơ sở thông tin chưa nhập tài khoản ngân hàng nào của doanh nghiệp!';
						|ru = 'Не удалось заполнить поле ""Банковский счет"". Возможно, в информационной базе не введено ни одного банковского счета организации!';
						|en = 'Cannot fill in field ""Bank account"". Possibly no bank accounts of the company are entered into the infobase.'; fa = 'Cannot fill in field ""Bank account"". Possibly no bank accounts of the company are entered into the infobase.';
						|it = 'Non è stato possibile compilare il campo ""Conto bancario"". Probabilmente nel database informatico non è stato immesso nessun conto bancario della società!';
						|pl = 'Nie udało się wypełnić pola ""Банковский счет"". Możliwe, że do bazy informacyjnej nie wprowadzono ani jednego rachunku bankowego firmy!';
						|tr = '""Banka hesabı"" alanı doldurulamadı. Infobase''e iş yerine ait bir banka hesabı girilmemiş olabilir!'");
		EndIf;
	EndIf;
	
	GetDefaultContractServer();
	Object.LineOfBusiness = CashServer.LineOfBusiness(
		Object.BusinessOperation,
		Object.LineOfBusiness);
	CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object);
	CompleteVATTaxation();
	FormItemsManagement();
	
	SavedBusinessTransaction = Object.BusinessOperation;
	
	Object.AdvanceHolder = Catalogs.Persons.EmptyRef();
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SalaryPaymentToEmployee") Then
		FillInAmountOfUnpaidPayrollATServer();
	EndIf;
	UpdateDisplayRowPersons();
	
EndProcedure

&AtClient
Procedure CashAccountOnChange(Item)
	
	PropsStructures = GetCheckoutDetails(Object.CashAccount);
	
	EnabledCreatingCashIssueWithoutPaymentRequest =
		(PropsStructures.EnableCreatingCashIssueWithoutPaymentRequest And UsePaymentRequests)
		Or Not UsePaymentRequests;
		
	SetPaymentByRequestAttribute();
	
	If Not ValueIsFilled(Object.Currency) Then
		Object.Currency = PropsStructures.Currency;
	EndIf;
		
	If Not FinancesClient.CurrencyConversionRequired(Object, Object.Currency, PropsStructures.Currency) Then
		
		If Object.Currency <> PropsStructures.Currency Then
			FinancesClient.ClearAmountAndCurrencyOfSettlementsPaymentDecryption(Object);
		EndIf;
		CashAccountOnChangeServer(PropsStructures, False);
		
	Else
		
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Tính lại số tiền trong chứng từ theo tiền tệ %1?';
				|ru = 'Пересчитать суммы в документе в валюту %1?';
				|en = 'Convert amounts in the document in %1?'; fa = 'Convert amounts in the document in %1?';
				|it = 'Ricalcolare gli importi del documento in valuta %1?';
				|pl = 'Przeliczyć kwoty w dokumencie na walutę %1?';
				|tr = 'Belgedeki tutarlar %1 para birimine göre yeniden hesaplansın mı?'"),
			PropsStructures.Currency);
		
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
			"CurrencyConversionAllowed", ThisObject, New Structure("PropsStructures", PropsStructures));
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogButtons);
	EndIf;
	
EndProcedure

&AtClient
Procedure CurrencyConversionAllowed(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		CurrentCurrency = Object.Currency;
		CashAccountOnChangeServer(AdditionalParameters.PropsStructures, True);
		PriceManagementSystemClient.NotifyAboutEndOfConversionOfAmountsIntoCurrency(CurrentCurrency, Object.Currency);
	Else
		Object.CashAccount = CurrentCashAccount;
	EndIf;
	
EndProcedure

&AtServer
Procedure CashAccountOnChangeServer(AttributesStructure1, AmountsRecalculate)
	
	OrganizationChanged_ = (Object.Organization <> AttributesStructure1.Organization);
	CurrencyChanged_1 = (Object.Currency <> AttributesStructure1.Currency);
	
	CurrentCashAccount         = Object.CashAccount;
	CurrentCurrency        = Object.Currency;
	Object.Currency        = AttributesStructure1.Currency;
	Object.Organization   = AttributesStructure1.Organization;
	CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	AttributesArray = New Array;
	If OrganizationChanged_ Then
		AttributesArray.Add("Organization");
	EndIf;
	If CurrencyChanged_1 Then
		AttributesArray.Add("Currency");
	EndIf;
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, AttributesArray);
	
	If ValueIsFilled(CurrentCashAccount) Then
		
		If ValueIsFilled(CurrentCurrency) And CurrencyChanged_1 Then
			
			Object.CashAccountRecipient                     = Catalogs.CashAccounts.EmptyRef();
			Object.BankAccount                      = Catalogs.CompaniesBankAccounts.EmptyRef();
			Object.CashRegister                            = Catalogs.CashRegisters.EmptyRef();
			
			If Object.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion Then
				CurrencyOfConversionOnChangeServer();
			EndIf;
		EndIf;
		
		GetDefaultContractServer();
		
		If OrganizationChanged_ Then
			
			Object.PaymentRequest = Undefined;
			For Each DecryptionString In Object.ARAPDetails Do
				DecryptionString.PaymentRequest = Undefined;
			EndDo;
			
			Object.CashRegister = Catalogs.CashRegisters.EmptyRef();
			BranchesOfOrganization.LoadValues(Catalogs.Companies.BranchesWithPaymentsThroughParentOrganization(Object.Organization));
			ThereAreBranches = BranchesOfOrganization.Count() > 0;
			
			If ValueIsFilled(CounterpartyContract) Then
				PaymentType_ = ?(Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PaymentToVendor")
						Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.CashPaymentToAnotherCompany"),
				PredefinedValue("Enum.PartnersARAPAccountingTypes.VendorARAPAccounting"),
				PredefinedValue("Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting"));
				ARAPObjectContract = ARAPObjectsServer.GetCalculationObjectFromLink(CounterpartyContract,,PaymentType_);
			EndIf;
			
			For Each TSRow In Object.ARAPDetails Do
				TSRow.Partner = Partner;
				If ValueIsFilled(CounterpartyContract) Then
					TSRow.ARAPObject = ARAPObjectContract;
					TSRow.CashFlowItem = Object.CashFlowItem;
					TSRow.VATRate = VATRate;
				EndIf;
			EndDo;
			
			CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object);
			
			CompleteVATTaxation();
			
			StructureOfActions = New Structure("RecalculateVATAmount", New Structure("PriceIncludesVAT", True));
			BatchProcessingOfTablePartServer.TreatTS(Object.ARAPDetails, StructureOfActions, Undefined);
			
			CashServer.FillInResponsiblePersonsOfCompany(Object);
			
		EndIf;
	Else
		BranchesOfOrganization.Clear();
	EndIf;
	
	If AmountsRecalculate Then
		CashServer.ConversionOfDocumentAmountsIntoCurrency(Object, CurrentCurrency, Object.Currency);
		
		VATConversionParameters = New Structure("PriceIncludesVAT", True);
		StructureOfActions = New Structure("RecalculateVATAmount", VATConversionParameters);
		BatchProcessingOfTablePartServer.TreatTS(Object.ARAPDetails, StructureOfActions, Undefined);
	EndIf;
	
	For Each TSRow In Object.ARAPDetails Do
		If CurrencyChanged_1 Then
			If Not ValueIsFilled(TSRow.ARAPObject)
				And Not ValueIsFilled(Object.Contract) Then
				TSRow.AmountARAP = TSRow.Sum;
				TSRow.ARAPCurrency = Object.Currency;
				TSRow.ExchangeRateNumeratorOfMutualSettlements = 1;
				TSRow.TheExchangeRateIsTheDenominatorOfMutualSettlements = 1;
			EndIf;
			CashServer.CalculateExchangeRateNumeratorOfMutualSettlementsInDecryptionLine(TSRow, Object.Currency, CurrencyOfComplianceAccounting);
			CalculateAmountOfSettlements_();
		EndIf;
	EndDo;
	
	FillInCurrencyOfMutualSettlementsOfDocument();
	FillMultiplicityCourseWithText();
	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	
	If CurrencyChanged_1 Then
		CashServer.SetPaymentAmountHeader(Object.Currency, Items);
		Items.LabelCurrency.Title = String(Object.Currency);
		UpdateAmountUnallocated();
		GenerateHyperlinkCaptionPaymentObjectDetails();
	EndIf;
	
	SetPossibleValuesOfRecipientSCashRegister();
	
	If (Object.BusinessOperation = Enums.BusinessTransactions.CashDepositToBankAccount
		Or Object.BusinessOperation = Enums.BusinessTransactions.CashCollectionToBank)
		And Not ValueIsFilled(Object.BankAccount) Then
		
		GetDefaultBankAccount();
	EndIf;
	
	FillInCashier();
	
	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure DocumentAmountOnChange(Item)
	
	FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, Object.DocumentAmount, False);
	DocumentAmountOnChangeServer();
	
EndProcedure

&AtClient
Procedure CashRegisterOnChange(Item)
	
	CashRegisterOnChangeServer();
	
EndProcedure

&AtServer
Procedure CashRegisterOnChangeServer()
	
	CashRegisterParameters = New FixedStructure(Catalogs.CashRegisters.CashRegisterParameters(Object.CashRegister));
	AccessRights = SalesSettingsForUsersServer.CWPAccessRights(Users.CurrentUser());
	
	GeneratingFiscalChecksServer.FormWhenChangingBankingDetails(ThisObject);
	
	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyOnChangeServer();
	CurrentCounterparty = Object.Counterparty;
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Counterparty");
	
	If CurrentCounterparty <> Object.Counterparty Then
		CashServer.ClearApplicationForSpendingMoney(Object);
	EndIf;
	
	If ValueIsFilled(Object.Counterparty) Then
		
		If CurrentCounterparty <> Object.Counterparty Then
			ClearAdditionalExpenseInformation();
		EndIf;
		
		If Not ValueIsFilled(Object.Issue) Then
			
			CounterpartyData = New Structure();
			PrintFormGeneration.FillInInformationAboutLegalEntity(CounterpartyData, Object.Counterparty, Object.Date);
			Object.Issue = CounterpartyData.Presentation;
			
		EndIf;
		
		Partner = CashServer.GetCounterpartyPartner(Object.Counterparty, Object.BusinessOperation);
		GetDefaultContractServer();
		
		If ValueIsFilled(CounterpartyContract) Then
			ARAPObjectContract = ARAPObjectsServer.GetCalculationObjectFromLink(CounterpartyContract)
		EndIf;
		
		For Each TSRow In Object.ARAPDetails Do
			TSRow.Partner = Partner;
			If ValueIsFilled(CounterpartyContract) Then
				TSRow.ARAPObject = ARAPObjectContract;
				TSRow.CashFlowItem = Object.CashFlowItem;
				TSRow.VATRate = VATRate;
				TSRow.ARAPCurrency = ARAPCurrency;
				FillInCourseAndMultiplicityInDecryptionLine(TSRow);
				CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
					TSRow, Object.Currency, CurrencyOfComplianceAccounting);
				CashServer.FormCourseDenominatorByText(TSRow, Object.Currency, CurrencyOfComplianceAccounting);
				FillInCurrencyOfMutualSettlementsOfDocument();
				DecryptionOfTheCalculationObjectWhenChangingServer(TSRow.GetID());
			EndIf;
		EndDo;
		
		If Not ValueIsFilled(CounterpartyContract) Then
			CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object);
		EndIf;
		CashServer.SetDesignAccuracyOfCourse(ThisObject);
		
		StructureOfActions = New Structure("RecalculateVATAmount", New Structure("PriceIncludesVAT", True));
		BatchProcessingOfTablePartServer.TreatTS(Object.ARAPDetails, StructureOfActions, Undefined);
		
		CashServer.SetParametersForSelectingLoanDepositAgreement(Object, Items.ARAPDetailsLoanDepositContract);
		CashServer.SetParametersForSelectingLoanDepositAgreement(Object, Items.DecryptionWithoutSplittingTheLoanDepositAgreement);
		CashServer.SetParametersForSelectingLeaseAgreement(Object, Items.ARAPDetailsLeaseContracts);
		CashServer.SetParametersForSelectingLeaseAgreement(Object, Items.DecryptionWithoutSplittingTheLeaseAgreement);
	Else
		ClearAdditionalExpenseInformation();
	EndIf;
	
	SetVisibilityOfGiftCertificateSelectionButton();
	
	If Not DecryptionSwitch Then
		SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning();
	EndIf;
	
	SetRestrictionOnTypeOfPaymentDecryptionContract();
	
	GeneratingFiscalChecksServer.FormWhenChangingBankingDetails(ThisObject);
	
	If Object.PaymentByRequests Then
		CashServer.SetApplicationSelectionParameters(
			Object, Items.ARAPDetailsPaymentRequest);
		CashServer.SetApplicationSelectionParameters(
			Object, Items.DecryptionWithoutSplittingTheApplicationForSpendingMoney);
	EndIf;
	
EndProcedure

&AtClient
Procedure AdvanceHolderOnChange(Item)
	
	AdvanceHolderOnChangeServer();
	
EndProcedure

&AtServer
Procedure AdvanceHolderOnChangeServer()
	
	If ValueIsFilled(Object.AdvanceHolder) Then
		
		Object.Issue = Common.ObjectAttributeValue(Object.AdvanceHolder, "Description");
		DocumentOfTheIndividual = PersonsTM.GetIndividualSDefaultDocument(Object.AdvanceHolder).Presentation;
		Object.ByDocument = DocumentOfTheIndividual;
		Object.Department = PersonsTM.DivisionOfIndividual(Object.AdvanceHolder);
	Else
		ClearAdditionalExpenseInformation();
	EndIf;
	
	If Object.PaymentByRequests Then
		CashServer.SetApplicationSelectionParameters(
			Object, Items.ARAPDetailsPaymentRequest);
		CashServer.SetApplicationSelectionParameters(
			Object, Items.DecryptionWithoutSplittingTheApplicationForSpendingMoney);
	EndIf;
	
EndProcedure

&AtClient
Procedure CashAccountRecipientOnChange(Item)
	
	CashAccountRecipientOnChangeServer();
	
EndProcedure

&AtServer
Procedure CashAccountRecipientOnChangeServer()
	
	SourceCompanyRecipient = Object.CompanyRecipient;
	
	FillInRecipientSOrganization();
	
	If Object.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion Then
		
		AttributesStructure1 = Catalogs.CashAccounts.GetCheckoutDetails(Object.CashAccountRecipient);
		If ValueIsFilled(AttributesStructure1.Currency) Then
			Object.CurrencyOfConversion = AttributesStructure1.Currency;
			SetPossibleValuesOfRecipientSCashRegister(False);
			RecalculateConversionParameters("CurrencyOfConversion");
			SetConversionAmountHeader();
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(Object.CashAccountRecipient)
		And SourceCompanyRecipient <> Object.CompanyRecipient Then
		ClearAdditionalExpenseInformation();
	EndIf;
	
	CashServer.SetContractSelectionParameters(ThisObject, Items.Contract);
	
EndProcedure

&AtClient
Procedure PaymentRequestOnChange(Item)
	
	If ValueIsFilled(Object.PaymentRequest) Then
		PaymentRequestOnChangeServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure PaymentRequestOnChangeServer()
	
	DocumentObject = FormAttributeToValue("Object");
	DocumentObject.Fill(Object.PaymentRequest);
	ValueToFormAttribute(DocumentObject, "Object");
	
	SetPossibleValuesOfRecipientSCashRegister();
	
	UpdateDisplayRowPersons();
	
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
		For Each String In Object.ARAPDetails Do
			String.PaymentRequest = Undefined;
		EndDo;
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
	
	ResultOfFiscalOperation = Undefined;
	If Result = False 
		And TypeOf(AdditionalParameters) = Type("Structure") 
		And AdditionalParameters.Property("ResultOfFiscalOperation", ResultOfFiscalOperation) 
		And TypeOf(ResultOfFiscalOperation) = Type("Structure")
		And ResultOfFiscalOperation.Property("Result")
		And Not ResultOfFiscalOperation.Result Then
		
		DocumentReference = Undefined;
		AdditionalParameters.Property("DocumentReference", DocumentReference);
		
	EndIf;
	
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
	
	CashServer.CheckFillInARAPObject(Object, Items.ARAPDetails.CurrentRow);
	CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object);
	
	CompleteVATTaxation();
	
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
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
		
		DocumentCorrectionClient.StringFixHandlingNavigationLinks(
			ThisObject, FormattedStringURL, StandardProcessing);
			
EndProcedure

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	ClearMessages();
	
	
	Return;
	
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
Procedure StatementOnChange(Item)
	
	StatementOnChangesAtServer();
	
	Return;
	
EndProcedure

&AtClient
Procedure StatementStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("Source", Object.Ref);
	ParametersStructure.Insert("ExcludePaid", True);
	
	If ValueIsFilled(Object.PaymentRequest) Then
		ParametersStructure.Insert("RequestForPayment", Object.PaymentRequest);
	EndIf;
	
	SelectionOfStatements = New Structure;
	SelectionOfStatements.Insert("Organization", Object.Organization);
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SalaryPaymentToEmployee") Then
		OperationArray = New Array;
		OperationArray.Add(PredefinedValue("Enum.BusinessTransactions.SalaryPaymentByDistributor"));
		OperationArray.Add(PredefinedValue("Enum.BusinessTransactions.SalaryPaymentViaCashAccount"));
		SelectionOfStatements.Insert("OperationArray", OperationArray);
		SelectionOfStatements.Insert("Employee_", Object.AdvanceHolder);
	Else
		SelectionOfStatements.Insert("BusinessOperation", Object.BusinessOperation);
	EndIf;
	
	ParametersStructure.Insert("SelectionOfStatements", SelectionOfStatements);
	
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
			FilterStructure1.Insert("PaymentMethodHR", PredefinedValue(
			"Enum.PaymentMethodsHR.CashAccount"));
			ParametersStructure.Insert("Filter", FilterStructure1);
			OpenForm("Document.PayrollStatementHR.ChoiceForm", ParametersStructure, ThisObject);
	Else
	//-- WE


	//++ WE
	EndIf;
	//-- WE

EndProcedure

&AtClient
Procedure RowIndividualsClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	ClearMessages();
	Cancel = False;
	
	If Not ValueIsFilled(Object.Statement) 
		And (UsePayroll 
		//++ WE
		Or PayrollAndHumanResourcesWE
		//-- WE
		Or False) Then
		CommonClientServer.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Bảng thanh toán""';
				|ru = 'Поле ""Ведомость"" не заполнено';
				|en = 'The ""Paysheet"" field is not filled in'; fa = 'The ""Paysheet"" field is not filled in';
				|it = 'The ""Paysheet"" field is not filled in';
				|pl = 'The ""Paysheet"" field is not filled in';
				|tr = '""Bordro"" alanı doldurulmadı.'"),,
			"Statement",
			"Object",
			Cancel);
	EndIf;
	
	If Not Cancel Then
		
		Modified = True;
		
		FormParameters = New Structure;
		FormParameters.Insert("Statement", Object.Statement);
		FormParameters.Insert("AddressPayrollInVault", PlacePayrollPaymentInVault());
		FormParameters.Insert("DocumentPayments", Object.Ref);
		FormParameters.Insert("Organization", Object.Organization);
		
		OpenForm("Document.CashVoucher.Form.FormSalaryPayment",
			FormParameters,
			ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
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
Procedure DecodingWithoutSplittingRepresentationOfReflectionInReglAccountingClick(Item, StandardProcessing)
	GLAccountSettingsClient.OnClick(ThisObject, Item, StandardProcessing);
	Return;
	
EndProcedure

&AtClient
Procedure ARAPDetailsOnStartEdit(Item, NewRow, Copy)
	
	TableRow = Items.ARAPDetails.CurrentData;
	
	If Not ValueIsFilled(Partner) Then
		GetDefaultServerPartner(Object.Counterparty, Partner, Object.BusinessOperation);
	EndIf;
	
	FinancesClient.ARAPDetailsOnStartEdit(
		Object, Partner, CounterpartyContract, TableRow, NewRow, Copy, CashFlowItem);
		
	If NewRow Then
		If Not Copy Then
			If Not ValueIsFilled(TableRow.CashFlowItem) Then
				TableRow.CashFlowItem = Object.CashFlowItem;
			EndIf;
			IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, TableRow, "Object.ARAPDetails");
		EndIf;
		CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
			TableRow, Object.Currency, CurrencyOfComplianceAccounting);
		UpdateTaxRateRecalculateVATAmount(TableRow.GetID());
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
	Documents.CashVoucher.FillInNamesOfBusinessTransactionDetails(
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
	
	CourseAndMultiplicity = CashServer.CourseNumeratorAndCourseDenominatorOfMutualSettlements(
		Object.Currency, TSRow.ARAPCurrency, CurrencyOfComplianceAccounting, Object.Date, TSRow.ARAPObject, Object.Contract);
	TSRow.ExchangeRateNumeratorOfMutualSettlements = CourseAndMultiplicity.CourseNumerator;
	TSRow.TheExchangeRateIsTheDenominatorOfMutualSettlements = CourseAndMultiplicity.CourseDenominator;
	TSRow.ContractRateOption = CourseAndMultiplicity.ContractRateOption;
	TSRow.ARAPObjectType = CourseAndMultiplicity.ARAPObjectType;
	
EndProcedure

&AtClient
Procedure DecryptionWithoutSplittingTheCalculationObjectOnChange(Item)
	
	TableRow = Items.ARAPDetails.CurrentData;
	If Not ValueIsFilled(TableRow.ARAPObject) Then
		TableRow.MaturityDate = Date(1, 1, 1);
	EndIf;
	UpdatePresentationOfMaturityDate();
	
	DecryptionWithoutSplittingTheCalculationObjectOnChangeServer();
	
EndProcedure

&AtServer
Procedure DecryptionWithoutSplittingTheCalculationObjectOnChangeServer()
	
	RowID = Items.ARAPDetails.CurrentRow;
	SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning();
	ARAPAccountingFormWork.BlockSettlementObjects(ThisForm);
	UpdateTaxRateRecalculateVATAmount(RowID);
	CashServer.CheckFillOutContract(Object, RowID);
	CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object, RowID);
	SetRestrictionOnTypeOfPaymentDecryptionContract();
	
EndProcedure

&AtClient
Procedure ARAPDetailsARAPObjectStartChoice(Item, ChoiceData, StandardProcessing)
	
	ARAPObject = Undefined;
	CurrentData = Items.ARAPDetails.CurrentData;
	If CurrentData <> Undefined Then
		ARAPObject = CurrentData.ARAPObject;
	EndIf;
	
	ARAPAccountingClient.ARAPObjectStartChoice(ThisForm, Item, StandardProcessing,, ARAPObject);
	
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
	
	DecryptionOfTheCalculationObjectWhenChangingServer(TableRow.GetID());
	
	SetRestrictionOnTypeOfPaymentDecryptionContract();
	GenerateHyperlinkCaptionPaymentObjectDetails();
	SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning();
	
	FillInCourseAndMultiplicityInDecryptionLine(TableRow);
	CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
		TableRow, Object.Currency, CurrencyOfComplianceAccounting);
	CashServer.FormCourseDenominatorByText(TableRow, Object.Currency, CurrencyOfComplianceAccounting);
	FillInCurrencyOfMutualSettlementsOfDocument();
	YouAreAllowedToWorkWithAffiliatedPartners(TableRow);
	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	
	ConfigureDependentFormElementsOnServer();
	
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
Procedure ARAPDetailsExpenseItemOnChange(Item)
	
	ARAPDetailsExpenseItemOnChangeServer(CachedValues, Item.Name);
	
EndProcedure

&AtServer
Procedure ARAPDetailsExpenseItemOnChangeServer(CachedValues, TagName)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items[TagName]);
	
EndProcedure

&AtClient
Procedure ARAPDetailsExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
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
	
	CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
		CurrentRow, Object.Currency, CurrencyOfComplianceAccounting);
	CashServer.FormCourseDenominatorByText(CurrentRow, Object.Currency, CurrencyOfComplianceAccounting);
	FillInCurrencyOfMutualSettlementsOfDocument();
	
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
Procedure ARAPDetailsPaymentRequestOnChange(Item)
	
	DecryptionOfPaymentRequestForChangeServer(Items.ARAPDetails.CurrentData.PaymentRequest);
	
EndProcedure

&AtServer
Procedure DecryptionOfPaymentRequestForChangeServer(ApplicationLink)
	
	If TypeOf(ApplicationLink) = Type("DocumentRef.PaymentRequest") Then
		
		BidCounterparty = Common.ObjectAttributeValue(ApplicationLink, "Counterparty");
		
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
	EndIf;
	
	UpdateInformationOnApplications();
	
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
	ARAPAccountingFormWork.BlockSettlementObjects(ThisForm);
	
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
Procedure ARAPDetailsARAPObjectOnChange(Item)
	
	TableRow = Items.ARAPDetails.CurrentData;
	ARAPDetailsARAPObjectOnChangeServer(TableRow.GetID());
	
EndProcedure

&AtServer
Procedure ARAPDetailsARAPObjectOnChangeServer(LineID)
	
	DecryptionOfTheCalculationObjectWhenChangingServer(LineID);
	
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
	
	FormParameters.Insert("FinancialAccountingGroup",  Object.FinancialAccountingGroup);
	FormParameters.Insert("LineOfBusiness", Object.LineOfBusiness);
	FormParameters.Insert("Contract",                 Object.Contract);
	FormParameters.Insert("Organization",             Object.Organization);
	FormParameters.Insert("VATTaxation",      Object.VATTaxation);
	FormParameters.Insert("ListOfVATTaxes",Items.DecodingWithoutSplittingVATTaxation.ChoiceList);
	FormParameters.Insert("DocumentRef",          Object.Ref);
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
	
	Object.FinancialAccountingGroup  = Result.FinancialAccountingGroup;
	Object.LineOfBusiness = Result.LineOfBusiness;
	Object.Contract                 = Result.Contract;
	ThereIsChangeInVATTaxation = ?(Object.VATTaxation = Result.VATTaxation, False, True);
	HyperlinkDetailsOfSettlementObjectClickEndOnServer();
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
			FilterStructure1.Organization = Object.CompanyRecipient;
			FilterStructure1.Insert("CompanyRecipient", Object.Organization);
		Else
			FilterStructure1.Insert("CompanyRecipient", Object.CompanyRecipient);
		EndIf;
		
		StructureOfSelectionParameters.Insert("Filter",FilterStructure1);
		OpenForm("Catalog.IntercompanyContracts.Form.ChoiceForm",
			StructureOfSelectionParameters,
			Item,
			Item,)
	Else
		FilterStructure1.Insert("Counterparty", Object.Counterparty);
		
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
Procedure TranscriptOfThePaymentTaxationOfPersonalIncomeTaxChanges(Item)
	
	CompleteVATTaxation();
	
EndProcedure

&AtServer
Procedure DecryptionOfTheCalculationObjectWhenChangingServer(LineID)
	
	UpdateTaxRateRecalculateVATAmount(LineID);
	SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning();
	CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object, LineID);
	CashServer.CheckFillOutContract(Object, LineID);
	SetRestrictionOnTypeOfPaymentDecryptionContract();
	GenerateHyperlinkCaptionPaymentObjectDetails();
	ARAPAccountingFormWork.BlockSettlementObjects(ThisForm);	
	TableRow = Object.ARAPDetails.FindByID(LineID);
	YouAreAllowedToWorkWithAffiliatedPartners(TableRow);
	
EndProcedure

&AtClient
Procedure ARAPDetailsLeaseContractsOnChange(Item)
	DecryptionOfPaymentLeaseAgreementWhenChangedOnServer();
	
	TableRow = Items.ARAPDetails.CurrentData;
	
	StructureOfRecalculationOfAmount = New Structure;
	StructureOfRecalculationOfAmount.Insert("PriceIncludesVAT", True);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartClient.ProcessTSString(TableRow, StructureOfActions, CachedValues);
	Return;

EndProcedure

&AtServer
Procedure DecryptionOfPaymentLeaseAgreementWhenChangedOnServer()
	
	CurrentRow = Object.ARAPDetails.FindByID(Items.ARAPDetails.CurrentRow);
	
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
	
	CurrentRow.AmountARAP = 0;
	CurrentRow.TypeOfLeasePayment = Catalogs.LeaseContract.TypesOfPaymentsUnderAgreement(CurrentRow.LeaseContracts)[0];
	
	Items.DecryptionWithoutSplittingTheTypeOfRentPayment.ChoiceParameters = New FixedArray(New Array);
	TMCommonUseClientServer.AddSelectionParameter(
		Items.DecryptionWithoutSplittingTheTypeOfRentPayment, "Contract", CurrentRow.LeaseContracts);
	TMCommonUseClientServer.AddSelectionParameter(Items.DecryptionWithoutSplittingTheTypeOfRentPayment, "Payment_", True);
	
	Items.ARAPDetailsTypeOfLeasePayment.ChoiceParameters = New FixedArray(New Array);
	TMCommonUseClientServer.AddSelectionParameter(
		Items.DecryptionWithoutSplittingTheTypeOfRentPayment, "Contract", CurrentRow.LeaseContracts);
	TMCommonUseClientServer.AddSelectionParameter(Items.ARAPDetailsTypeOfLeasePayment, "Payment_", True);
	
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


&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm, True);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm, True);
	
EndProcedure

&AtClient
Procedure SelectionByStock(Command)
	
	ThisIsIssueToAnotherOrganization =
		(Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.CashPaymentToAnotherCompany"))
		Or (Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RefundToAnotherCompany"));
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.CheckedAttributes.Insert("CashAccount", NStr("vi = 'Quỹ tiền mặt';
																|ru = 'Касса';
																|en = 'Cash account'; fa = 'صندوق';
																|it = 'Cassa';
																|pl = 'Kasa';
																|tr = 'Kasa hesabı'"));
	If ThisIsIssueToAnotherOrganization Then
		CheckParameters.CheckedAttributes.Insert("CashAccountRecipient", NStr("vi = 'Người nhận';
																				|ru = 'Получатель';
																				|en = 'Recipient'; fa = 'گیرنده';
																				|it = 'Destinatario';
																				|pl = 'Odbiorca';
																				|tr = 'Alıcı'"));
	Else
		CheckParameters.CheckedAttributes.Insert("Counterparty", NStr("vi = 'Người nhận';
																		|ru = 'Получатель';
																		|en = 'Recipient'; fa = 'گیرنده';
																		|it = 'Destinatario';
																		|pl = 'Odbiorca';
																		|tr = 'Alıcı'"));
	EndIf;
	Notification = New CallbackDescription("SelectionBasedOnBalancesAfterVerification", ThisObject,
		New Structure("ThisIsIssueToAnotherOrganization", ThisIsIssueToAnotherOrganization));
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
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
	
	Notification = New CallbackDescription("SelectionByStockCompletion", ThisObject);
	PlacePaymentDecryptionInTemporaryStorage();
	ARAPAccountingClient.AddToPaymentDecryption(ThisForm, Items.ARAPDetailsSelectionByStock.Name, Notification);
	
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
	
	CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object);
	
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
	
	FillInParametersOfCalculationObjectInDecryption();
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtClient
Procedure SelectFromRequests(Command)
	
	ThisIsIssueToAnotherOrganization = (Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.CashPaymentToAnotherCompany"))
		Or (Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RefundToAnotherCompany"));
	ThisIsIssueToDebtor = (Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.IssueCashToAdvanceHolder"));
	ThisIsInternalTransfer = (Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices"));
	ThisIsLoanToEmployee = (Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.CashIssueAsLoanToEmployee"));
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.CheckedAttributes.Insert("CashAccount", NStr("vi = 'Quỹ tiền mặt';
																|ru = 'Касса';
																|en = 'Cash account'; fa = 'صندوق';
																|it = 'Cassa';
																|pl = 'Kasa';
																|tr = 'Kasa hesabı'"));
	If ThisIsIssueToAnotherOrganization Then
		CheckParameters.CheckedAttributes.Insert("CashAccountRecipient", NStr("vi = 'Người nhận';
																				|ru = 'Получатель';
																				|en = 'Recipient'; fa = 'گیرنده';
																				|it = 'Destinatario';
																				|pl = 'Odbiorca';
																				|tr = 'Alıcı'"));
	ElsIf ThisIsIssueToDebtor Or ThisIsLoanToEmployee Then
		CheckParameters.CheckedAttributes.Insert("AdvanceHolder", NStr("vi = 'Người nhận tạm ứng';
																		|ru = 'Подотчетное лицо';
																		|en = 'Advance holder'; fa = 'تنخواه‌دار';
																		|it = 'Titolare di anticipo';
																		|pl = 'Osoba rozliczająca się za wydatki';
																		|tr = 'Sorumlu kişi'"));
	ElsIf Not ThisIsInternalTransfer Then
		CheckParameters.CheckedAttributes.Insert("Counterparty", NStr("vi = 'Người nhận';
																		|ru = 'Получатель';
																		|en = 'Recipient'; fa = 'گیرنده';
																		|it = 'Destinatario';
																		|pl = 'Odbiorca';
																		|tr = 'Alıcı'"));
	EndIf;
	Notification = New CallbackDescription("SelectFromRequestsCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure SelectFromRequestsCompletion(Result, AdditionalParameters) Export 
	
	AddressOfPaymentsInTheStorage = PlacePaymentDecryptionInVault();
	
	PickingParameters = New Structure(
		"Counterparty,
		|CashAccountRecipient,
		|AdvanceHolder,
		|Organization,
		|BusinessOperation,
		|PayrollTransaction,
		|Currency,
		|DocumentAmount,
		|Date");
	
	FillPropertyValues(PickingParameters, Object);
	
	PaymentForms = New Array;
	
	PaymentForms.Add(PredefinedValue("Enum.PaymentForms.CashAccountPayment_"));
	PaymentForms.Add(PredefinedValue("Enum.PaymentForms.EmptyRef"));
	
	PickingParameters.Insert("Ref",                              Object.Ref);
	PickingParameters.Insert("PaymentMethod",                         PaymentForms);
	PickingParameters.Insert("BankAccountCashAccount",                 Object.CashAccount);
	PickingParameters.Insert("AddressOfPaymentsInTheStorage",             AddressOfPaymentsInTheStorage);
	PickingParameters.Insert("ListOfCounterparties_",                  False);
	
	OpenForm("Document.PaymentRequest.Form.PaymentRequestSelectionInCashIssueNote",
		PickingParameters,
		ThisObject,,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm, True);
	
EndProcedure

&AtClient
Procedure FillInThePaymentExplanationOnLoansForCounterparty(Command)
	
	FillInThePaymentExplanationOnLoansForCounterpartyServer();
	
EndProcedure

&AtServer
Procedure FillInThePaymentExplanationOnLoansForCounterpartyServer()
	
	Object.ARAPDetails.Clear();
	
	CurrentAgreements = Catalogs.LoanAndDepositContracts.CurrentContractsForCounterparty(
		Object.Organization, Object.Counterparty, Enums.ContractKindsOfFinancialInstruments.IssuedBorrowing);
	
	For Each Contract In CurrentAgreements Do
		
		DetailsData = Catalogs.LoanAndDepositContracts.PaymentDecryptionDataOfDDSDocument(Contract, False, Object.Ref);
		
		For Each String In DetailsData Do
			NewRow = Object.ARAPDetails.Add();
			FillPropertyValues(NewRow, String);
			IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, NewRow, "Object.ARAPDetails");
		EndDo;
	EndDo;
	
	Object.DocumentAmount = Object.ARAPDetails.Total("Sum");
	
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
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
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

&AtClient
Procedure SetDeletionMarkForADocument(Command)
	TMCommonUseClient.SetDeletionMarkForADocument(ThisForm);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure FillInThePaymentExplanationOnLoansForEmployee(Command)
	
	Return;
	
EndProcedure

&AtClient
Procedure CheckCounterparties(Command)
	
	Return;
	
EndProcedure

#EndRegion

#Region Private

#Region ElementEventHandlers

&AtServer
Procedure DocumentAmountOnChangeServer()
	
	If Object.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion Then
		RecalculateConversionParameters("ConversionRate");
	EndIf;
	
	VATConversionParameters = New Structure("PriceIncludesVAT", True);
	StructureOfActions = New Structure("RecalculateVATAmount", VATConversionParameters);
	BatchProcessingOfTablePartServer.TreatTS(Object.ARAPDetails, StructureOfActions, Undefined);
	
	SetRestrictionOnTypeOfPaymentDecryptionContract();
	GenerateHyperlinkCaptionPaymentObjectDetails();
	SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning();
	
	CalculateAmountOfSettlements_();
	FillInCurrencyOfMutualSettlementsOfDocument();
	
EndProcedure

&AtServer
Procedure CurrencyOfConversionOnChangeServer()
	
	SetPossibleValuesOfRecipientSCashRegister();
	
	RecalculateConversionParameters("CurrencyOfConversion");
	SetConversionAmountHeader();
	
EndProcedure

&AtServer
Procedure MultiplicityOfConversionRateWhenChangingOnServer()

	RecalculateConversionParameters("ConversionRateMultiplier");

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
	ItemField.Field = New DataCompositionField(Items.Counterparty.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.BusinessTransactions.OtherCashIssue);
	ItemFilter.RightValue = ValueList;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Counterparty.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ValueList = New ValueList;
	ValueList.Add(Enums.BusinessTransactions.OtherCashIssue);
	ItemFilter.RightValue = ValueList;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Counterparty");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ARAPDetailsPartner.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ARAPDetails.ARAPObject");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ARAPDetails.Partner");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

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
Procedure FormItemsManagement()
	
	SetPossibleValuesOfRecipientSCashRegister(False);
	
	Items.BusinessOperation.Enabled = Not Object.Patch;
	Items.DocumentAmount.Enabled = Not Object.Patch;
	Items.CashAccount.Enabled = Not Object.Patch;
	Items.CashAccountRecipient.Enabled = Not Object.Patch;
	Items.Counterparty.Enabled = Not Object.Patch;
	Items.CashAccountRecipient.Enabled = Not Object.Patch;
	Items.BankAccount.Enabled = Not Object.Patch;
	Items.CashRegister.Enabled = Not Object.Patch;
	
	ArrayOfOperationDetails = New Array;
	Documents.CashVoucher.FillInNamesOfBusinessTransactionDetails(
		Object, Undefined, ArrayOfOperationDetails);
	
	CashServer.SetParametersForSelectingCashRegister(Object, Items.CashAccount);
	CashServer.SetApplicationSelectionParameters(Object, Items.PaymentRequest);
	CashServer.SetApplicationSelectionParameters(Object, Items.ARAPDetailsPaymentRequest);
	CashServer.SetApplicationSelectionParameters(Object, Items.DecryptionWithoutSplittingTheApplicationForSpendingMoney);
	CashServer.SetCounterpartySelectionParameters(Object, Items.Counterparty);
	CashServer.SetPartnerSelectionParameters(Object, Items.ARAPDetailsPartner);
	CashServer.SetPartnerSelectionParameters(Object, Items.DecryptionWithoutPartitioningPartner);
	CashServer.SetParametersForSelectingLoanDepositAgreement(Object, Items.ARAPDetailsLoanDepositContract);
	CashServer.SetParametersForSelectingLoanDepositAgreement(Object, Items.DecryptionWithoutSplittingTheLoanDepositAgreement);
	CashServer.SetParametersForSelectingLeaseAgreement(Object, Items.ARAPDetailsLeaseContracts);
	CashServer.SetParametersForSelectingLeaseAgreement(Object, Items.DecryptionWithoutSplittingTheLeaseAgreement);
	If ArrayOfOperationDetails.Find("Contract") <> Undefined Then
		CashServer.SetContractSelectionParameters(ThisObject, Items.Contract);
	EndIf;
	
	CashServer.SetParametersForSelectingCashFlowItems(Object, Items.CashFlowItem);
	CashServer.EstablishLinksBetweenVATRateSelectionParameters(Object, Items.DecodingWithoutSplittingTheVATRate);
	CashServer.EstablishLinksBetweenVATRateSelectionParameters(Object, Items.ARAPDetailsVATRate);
	CashServer.SetParametersForSelectingDirectionOfActivity(Object, Items.LineOfBusiness);
	CashServer.SetParametersForSelectingDirectionOfActivity(Object, Items.DirectionOfReturnActivity);
	
	SetVisibilityOfGiftCertificateSelectionButton();
	
	CashServer.FillInListOfTypesOfAmountsOfLoansDeposits(
		Items.ARAPDetailsLoanAndDepositAmountType.ChoiceList, Object.BusinessOperation);
	CashServer.FillInListOfTypesOfAmountsOfLoansDeposits(
		Items.DecryptionWithoutSplittingTheTypeOfLoanAmountDeposit.ChoiceList, Object.BusinessOperation);
	
	CashServer.SetPaymentAmountHeader(Object.Currency, Items);
	Items.LabelCurrency.Title = String(Object.Currency);
	
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
	
	UpdateDisplayRowPersons();
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtClient
Procedure ConfigureDependentFormElements(ChangedProps = "")
	
	CashClientServer.CustomizeFormElements(ThisForm, ChangedProps, FormAttributes(ThisForm));
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(ChangedProps = "")
	
	CashClientServer.CustomizeFormElements(ThisForm, ChangedProps, FormAttributes(ThisForm));
	
EndProcedure

&AtClientAtServerNoContext
Function FormAttributes(Form)
	
	FormAttributes = New Structure;
	FormAttributes.Insert("UsePaymentRequests");
	FormAttributes.Insert("UseApplicationsForBusinessTrip");
	FormAttributes.Insert("UseMultipleCurrencies");
	FormAttributes.Insert("EnabledCreatingCashIssueWithoutPaymentRequest");
	FormAttributes.Insert("UsePayrollTM");
	//++ WE
	FormAttributes.Insert("PayrollAndHumanResourcesWE");
	//-- WE
	FormAttributes.Insert("ExpenseReportPeriodDate");
	FormAttributes.Insert("ThereAreBranches");
	FormAttributes.Insert("AmountUnallocated");
	FormAttributes.Insert("UseIntercompanyContracts");
	FormAttributes.Insert("UseCustomerContracts");
	FormAttributes.Insert("UseContractsWithVendors");
	FormAttributes.Insert("ARAPCurrency");
	FormAttributes.Insert("CurrencyOfComplianceAccounting");
	FormAttributes.Insert("ContractRateOption");
	FormAttributes.Insert("ARAPObjectType");
	FormAttributes.Insert("ExchangeRateNumeratorOfMutualSettlements");
	FormAttributes.Insert("MultipleARAPCurrency");
	
	FillPropertyValues(FormAttributes, Form);
	
	Return FormAttributes;
	
EndFunction

&AtServer
Procedure SpecifyListOfBusinessOperations()
	
	ItemBusinessOperation = Items.BusinessOperation;
	
	CashServer.EstablishVisibilityOfTransferOperationsBetweenOrganizations(ItemBusinessOperation);
	CashServer.EstablishVisibilityOfInternalTransferOperations(ItemBusinessOperation);
	CashServer.EstablishVisibilityOfTransactionsUnderLoanAndDepositAgreements(ItemBusinessOperation);
	CashServer.EstablishVisibilityOfOperationOtherCashDisbursement(ItemBusinessOperation);
	CashServer.SetVisibilityOfCurrencyConversionCashOperation(ItemBusinessOperation);
	CashServer.SetVisibilityOfTransferOperationsBetweenCashRegisters(ItemBusinessOperation);
	CashServer.SetVisibilityOfOperationsWithCashRegisterCashRegisters(ItemBusinessOperation);
	CashServer.EstablishVisibilityOfPaymentToLandlordOperation(ItemBusinessOperation);
	CashServer.EstablishVisibilityOfOperationsToLoansToEmployees(ItemBusinessOperation);
	//++ WE
	IntegrationPayrollAndHumanResourcesServer.EstablishVisibilityOfOperationsOfPayrollIssuanceToEmployees(ItemBusinessOperation);
	//-- WE
	
EndProcedure

&AtServer
Procedure UpdateInformationOnApplications()
	
	ManagerOfDocument = Common.ObjectManagerByFullName("Document.CashVoucher");
	CashServer.DisplayInformationOnApplications(ThisObject, ManagerOfDocument);
	
EndProcedure

&AtServer
Procedure SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning()
	
	CashServer.SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning(ThisObject);
	
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

&AtServer
Procedure OnReadCreateAtServer()
	
	CashServer.ManagingFormElementsWhenReadingCreatingOnServer(ThisObject);
	
	UsePaymentRequests = GetFunctionalOption("UsePaymentRequests");
	UseApplicationsForBusinessTrip                = GetFunctionalOption("UseApplicationsForBusinessTrip");
	UseMultipleCurrencies                      = GetFunctionalOption("UseMultipleCurrencies");
	UsePayroll                  = GetFunctionalOption("UsePayroll");
	UsePayrollTM                = GetFunctionalOption("UsePayrollTM");
	//++ WE
	PayrollAndHumanResourcesWE                    = GetFunctionalOption("PayrollAndHumanResourcesWE");
	//-- WE
	UseDataSynchronization                 = GetFunctionalOption("UseDataSynchronization");
	UseIntercompanyContracts          = GetFunctionalOption("UseIntercompanyContracts");
	UseCustomerContracts                  = GetFunctionalOption("UseCustomerContracts");
	UseContractsWithVendors               = GetFunctionalOption("UseContractsWithVendors");
	
	CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	If ValueIsFilled(Object.CashRegister) Then
		CashRegisterParameters = New FixedStructure(Catalogs.CashRegisters.CashRegisterParameters(Object.CashRegister));
		AccessRights = SalesSettingsForUsersServer.CWPAccessRights(Users.CurrentUser());
	EndIf;
	
	CurrentCashAccount = Object.CashAccount;
	SavedBusinessTransaction = Object.BusinessOperation;
	
	CurrentCounterparty = Object.Counterparty;
	CurrentRecipientOrganization = Object.CompanyRecipient;
	
	If ValueIsFilled(Object.Organization) Then
		BranchesOfOrganization.LoadValues(Catalogs.Companies.BranchesWithPaymentsThroughParentOrganization(Object.Organization));
		ThereAreBranches = BranchesOfOrganization.Count() > 0;
	EndIf;
	
	EnabledCreatingCashIssueWithoutPaymentRequest =
		(Catalogs.CashAccounts.GetCheckoutDetails(CurrentCashAccount).EnableCreatingCashIssueWithoutPaymentRequest And UsePaymentRequests)
		Or Not UsePaymentRequests;
		
	GetDefaultServerPartner(Object.Counterparty, Partner, Object.BusinessOperation);
	GetDefaultContractServer();
	
	InitializePaymentDecryption();
	
	CashServer.FillInListOfAdvanceReportPeriodSelections(ThisForm, Object.Date);
	ExpenseReportPeriodDate = (TypeOf(ExpenseReportPeriod) = Type("Date"));
	
	SpecifyListOfBusinessOperations();
	CashServer.GetAvailableBusinessOfOperationsBasedOn(
		Object.DocumentBasis, Enums.PaymentForms.CashAccountPayment_, AvailableBaseOfOperations);
	
	SetHeadingIncomeExpenseItem();
	SetConversionAmountHeader();
	UpdateInformationOnApplications();
	
	FillInCurrencyOfMutualSettlementsOfDocument();
	FillMultiplicityCourseWithText();
	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	
	FormItemsManagement();
	
EndProcedure

&AtServer
Procedure InitializePaymentDecryption()
	
	ArrayOfAllProps = New Array; ArrayOfOperationDetails = New Array;
	Documents.CashVoucher.FillInNamesOfBusinessTransactionDetails(
		Object, ArrayOfAllProps, ArrayOfOperationDetails);
	
	If ArrayOfOperationDetails.Find("ARAPDetails") = Undefined
		Or Documents.CashVoucher.ArrayOfOperationsWithoutPaymentDecryption().Find(Object.BusinessOperation) <> Undefined
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
			DecryptionSwitch = 0;
			CompleteVATTaxation(False);
		Else
			DecryptionSwitch = 1;
			CompleteVATTaxation(False);
		EndIf;
		CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object);
		FillInParametersOfCalculationObjectInDecryption();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInParametersOfCalculationObjectInDecryption()
	ComplianceOfContractCurrencyExchangeRate = ARAPAccountingServer.ComplianceOfARAPObjectsAndParametersOfContract(
		Object.ARAPDetails.Unload(,"ARAPObject").UnloadColumn("ARAPObject"));
	For Each TSRow In Object.ARAPDetails Do
		TSRow.ContractRateOption = ComplianceOfContractCurrencyExchangeRate[TSRow.ARAPObject].ContractRateOption;
		TSRow.ItIsAllowedToWorkWithSubsidiaryPartners = ComplianceOfContractCurrencyExchangeRate[TSRow.ARAPObject].ItIsAllowedToWorkWithSubsidiaryPartners;
		TSRow.TheCalculationObjectMatchesTheDocument = ComplianceOfContractCurrencyExchangeRate[TSRow.ARAPObject].Object = Object.Ref;
		If ValueIsFilled(TSRow.ARAPObject) Then
			TSRow.ARAPObjectType = ComplianceOfContractCurrencyExchangeRate[TSRow.ARAPObject].ARAPObjectType;
		EndIf;
	EndDo;
EndProcedure

&AtServer
Procedure FillInRecipientSOrganization()
	
	If Object.BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany
		Or Object.BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany
		Or Object.BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices Then
		
		AttributesStructure1 = Catalogs.CashAccounts.GetCheckoutDetails(Object.CashAccountRecipient);
		If ValueIsFilled(AttributesStructure1.Organization) Then
			If ValueIsFilled(CurrentRecipientOrganization) 
				And CurrentRecipientOrganization <> AttributesStructure1.Organization Then
				ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "CashAccountRecipient.Owner");
			EndIf;
			Object.CompanyRecipient = AttributesStructure1.Organization;
			CurIssue = Common.ObjectAttributeValue(CurrentRecipientOrganization, "DescriptionFull");
			If Not ValueIsFilled(Object.Issue) Or Object.Issue = CurIssue Then
				Object.Issue = Common.ObjectAttributeValue(Object.CompanyRecipient, "DescriptionFull");
			EndIf;
			CurrentRecipientOrganization = Object.CompanyRecipient;
		EndIf;
	Else
		Object.CompanyRecipient = Undefined;
		Object.Issue = "";
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
Procedure GetDefaultContractServer()
	
	ArrayOfAllProps = New Array;
	ArrayOfOperationDetails = New Array;
	Documents.CashVoucher.FillInNamesOfBusinessTransactionDetails(
		Object, ArrayOfAllProps, ArrayOfOperationDetails);
		
	If ArrayOfOperationDetails.Find("ARAPDetails.ARAPObject") = Undefined Then
		Return;
	EndIf;
	
	If AccessRight("Read", Metadata.Catalogs.CounterpartyContracts) Then
		
		ContractBusinessTransaction = New Array;
		If Object.BusinessOperation = Enums.BusinessTransactions.PaymentToVendor Then
			ContractBusinessTransaction.Add(Enums.BusinessTransactions.PurchaseFromSupplier);
			ContractBusinessTransaction.Add(Enums.BusinessTransactions.PurchaseByImport);
			ContractBusinessTransaction.Add(Enums.BusinessTransactions.ConsignmentProcurement);
		ElsIf Object.BusinessOperation = Enums.BusinessTransactions.RefundToCustomer Then
			ContractBusinessTransaction.Add(Enums.BusinessTransactions.SaleToCustomer);
			ContractBusinessTransaction.Add(Enums.BusinessTransactions.TransferToCommissionAgent);
		EndIf;
		
		CounterpartyContract = CashServer.DefaultContract(
			CounterpartyContract, Partner, Object.Counterparty, Object.Organization, ContractBusinessTransaction);
			
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

&AtServer
Procedure GetDefaultBankAccount()
	
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Object.Organization);
	ParametersOfAccount.Currency = Object.Currency;
	Object.BankAccount = Catalogs.CompaniesBankAccounts.GetDefaultBankAccount(ParametersOfAccount);
	
EndProcedure

&AtServerNoContext
Procedure GetDefaultServerPartner(Counterparty, Partner, BusinessOperation)
	
	Partner = CashServer.GetCounterpartyPartner(Counterparty, BusinessOperation);
	
EndProcedure

&AtServerNoContext
Function GetCheckoutDetails(CashAccount)
	
	Return Catalogs.CashAccounts.GetCheckoutDetails(CashAccount);
	
EndFunction

&AtServer
Procedure SetPossibleValuesOfRecipientSCashRegister(ChangeRecipientSCashier = True)
	
	If Object.BusinessOperation = Enums.BusinessTransactions.CashIssueToAnotherCashAccount
		And ValueIsFilled(Object.CashAccount) Then
		
		Query = New Query("
		|SELECT ALLOWED TOP 1
		|	Recipients.Ref AS Ref
		|
		|FROM
		|	Catalog.CashAccounts.RecipientOfCashTransfer AS Recipients
		|
		|WHERE
		|	Recipients.Ref = &CashAccountIssuer
		|");
		Query.SetParameter("CashAccountIssuer", Object.CashAccount);
		CheckoutRecipients = Not Query.Execute().IsEmpty();
		
	Else
		
		CheckoutRecipients = False;
		
	EndIf;
	
	Query = New Query("
	|SELECT ALLOWED
	|	CashAccounts.Ref AS Ref
	|
	|FROM
	|	Catalog.CashAccounts AS CashAccounts
	|
	|	LEFT JOIN
	|		Catalog.CashAccounts.RecipientOfCashTransfer AS RecipientsOfSenderCheckout
	|	ON
	|		RecipientsOfSenderCheckout.PaymentBeneficiary = CashAccounts.Ref
	|		AND RecipientsOfSenderCheckout.Ref = &CashAccountIssuer
	|		AND &SelectRecipientsByCheckout
	|
	|WHERE
	|	(CashAccounts.CashCurrency = &Currency OR NOT &SelectByCurrency)
	|	AND (CashAccounts.CashCurrency <> &Currency OR NOT &SelectByConversionCurrency)
	|	AND (CashAccounts.Owner IN (&Owner) OR NOT &SelectByOwner)
	|	AND CashAccounts.Owner NOT IN (&OwnerFilter_)
	|	AND (RecipientsOfSenderCheckout.Ref IS NOT NULL OR NOT &SelectRecipientsByCheckout)
	|	AND CashAccounts.Ref <> &CashAccountIssuer
	|	
	|UNION ALL
	|	
	|SELECT
	|	CashAccounts.Ref AS Ref
	|
	|FROM
	|	Catalog.CashRegisters AS CashAccounts
	|
	|WHERE
	|	(CashAccounts.CashCurrency = &Currency OR NOT &SelectByCurrency)
	|	AND (CashAccounts.Owner IN (&Owner) OR NOT &SelectByOwner)
	|	AND CashAccounts.Owner NOT IN (&OwnerFilter_)
	|	AND CashAccounts.CashRegisterType NOT IN (VALUE(Enum.CashRegisterTypes.MobileCashRegister), VALUE(Enum.CashRegisterTypes.CashRegisterOffline))
	|");
	
	Query.SetParameter("CashAccountIssuer", Object.CashAccount);
	Query.SetParameter("SelectRecipientsByCheckout", CheckoutRecipients);
	Query.SetParameter("SelectByConversionCurrency", False);
	
	If Object.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion Then
		
		If ValueIsFilled(Object.CurrencyOfConversion) Then
			Query.SetParameter("Currency", Object.CurrencyOfConversion);
			Query.SetParameter("SelectByCurrency", True);
		Else
			Query.SetParameter("Currency", Object.Currency);
			Query.SetParameter("SelectByCurrency", False);
			Query.SetParameter("SelectByConversionCurrency", True);
		EndIf;
		
	ElsIf ValueIsFilled(Object.Currency) Then
		
		Query.SetParameter("Currency", Object.Currency);
		Query.SetParameter("SelectByCurrency", True);
	Else
		
		Query.SetParameter("Currency", Undefined);
		Query.SetParameter("SelectByCurrency", False);
	EndIf;
	
	Query.SetParameter("Owner", Undefined);
	If (Object.BusinessOperation = Enums.BusinessTransactions.CashIssueToAnotherCashAccount
		Or Object.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion)
		And ValueIsFilled(Object.CashAccount)
		And ValueIsFilled(Object.Organization) Then
		
		Query.SetParameter("Owner", Object.Organization);
		Query.SetParameter("SelectByOwner", True);
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices Then
		
		ArrayOfInterconnectedOrganizations = Catalogs.Companies.ArrayOfInterconnectedOrganizations(Object.Organization);
		Query.SetParameter("Owner", ArrayOfInterconnectedOrganizations);
		Query.SetParameter("SelectByOwner", True);
	Else
		
		Query.SetParameter("SelectByOwner", False);
	EndIf;
	
	Query.SetParameter("OwnerFilter_", Undefined);
	
	If (Object.BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany
		Or Object.BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany) Then
		
		If ValueIsFilled(Object.CashAccount)
			And ValueIsFilled(Object.Organization) Then
		
			ArrayOfInterconnectedOrganizations = Catalogs.Companies.ArrayOfInterconnectedOrganizations(Object.Organization);
			ArrayOfInterconnectedOrganizations.Add(Object.Organization);
			Query.SetParameter("OwnerFilter_", ArrayOfInterconnectedOrganizations);
		EndIf;
		
		If ValueIsFilled(Object.CompanyRecipient) Then
			ArrayOfInterconnectedOrganizations = Catalogs.Companies.ArrayOfInterconnectedOrganizations(Object.CompanyRecipient);
			ArrayOfInterconnectedOrganizations.Add(Object.CompanyRecipient);
			Query.SetParameter("Owner", ArrayOfInterconnectedOrganizations);
			Query.SetParameter("SelectByOwner", True);
		EndIf;
	EndIf;
	
	ArrayOfCheckoutRecipients = Query.Execute().Unload().UnloadColumn("Ref");
	Items.CashAccountRecipient.ChoiceList.LoadValues(ArrayOfCheckoutRecipients);
	
	If ChangeRecipientSCashier Then
		If ArrayOfCheckoutRecipients.Count() = 1 Then
			
			Object.CashAccountRecipient = ArrayOfCheckoutRecipients[0];
			CashAccountRecipientOnChangeServer();
			
		ElsIf ValueIsFilled(Object.CashAccountRecipient)
			And ArrayOfCheckoutRecipients.Find(Object.CashAccountRecipient) = Undefined Then
			
			Object.CashAccountRecipient = Catalogs.CashAccounts.EmptyRef();
			CashAccountRecipientOnChangeServer();
			
		EndIf;
	EndIf;
	
EndProcedure

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

&AtServer
Procedure RecalculateConversionParameters(Var_AttributeName)
	
	ConversionParameters_SSLy = CashServer.InitializeConversionParameters();
	FillPropertyValues(ConversionParameters_SSLy, Object);
	ConversionParameters_SSLy.CurrencyOfComplianceAccounting = CurrencyOfComplianceAccounting;
	
	CashServer.CalculateConversionParameters(ConversionParameters_SSLy, Var_AttributeName);
	FillPropertyValues(Object, ConversionParameters_SSLy);
	
EndProcedure

&AtServer
Procedure ProcessingSelectionFromApplications(AddressOfRequestsInRepository)
	
	Object.PaymentByRequests = True;
	
	PaymentTable_3 = GetFromTempStorage(AddressOfRequestsInRepository);
	
	TheStructureOfTheSearch = New Structure;
	
	ArrayOfAllProps = New Array; ArrayOfOperationDetails = New Array;
	Documents.CashVoucher.FillInNamesOfBusinessTransactionDetails(
		Object, ArrayOfAllProps, ArrayOfOperationDetails);
	
	For Each OperationAttribute In ArrayOfOperationDetails Do
		Pos = StrFind(OperationAttribute, "ARAPDetails.");
		CharsCount = StrLen("ARAPDetails");
		If Pos Then
			TheStructureOfTheSearch.Insert(Mid(OperationAttribute, Pos + CharsCount + 1));
		EndIf;
	EndDo;
	
	
	For Each PaymentLine_1 In PaymentTable_3 Do
		
		FillPropertyValues(TheStructureOfTheSearch, PaymentLine_1);
		
		If CommonClientServer.HasAttributeOrObjectProperty(TheStructureOfTheSearch, "Organization")
			And Not ValueIsFilled(TheStructureOfTheSearch.Organization) Then
			TheStructureOfTheSearch.Organization = Catalogs.Companies.EmptyRef();
		EndIf;
		
		Rows = Object.ARAPDetails.FindRows(TheStructureOfTheSearch);
		
		If Rows.Count() = 0 Then
			AddLineOfDecryptionOnRequest(PaymentLine_1, TheStructureOfTheSearch);
			
		
		EndIf;
	EndDo;
	GLAccountSettingsServer.UpdateSettingsPresentation(ThisObject, "Object.ARAPDetails");
	Object.DocumentAmount = Object.ARAPDetails.Total("Sum");
	
	UpdateInformationOnApplications();

	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	ConfigureDependentFormElementsOnServer("PaymentByRequests");
	
EndProcedure

&AtClient
Procedure RecalculateAmountOfDocumentBasedOnPaymentDecryptionCompletion(QuestionResult, AdditionalParameters) Export
	
	If AdditionalParameters.Property("TabularSectionName") Then
		TabularSection = Object[AdditionalParameters.TabularSectionName];
	Else
		TabularSection = Object.ARAPDetails;
	EndIf;
	
	ResponseCode = QuestionResult;
	If ResponseCode = DialogReturnCode.Yes Then
		Object.DocumentAmount = TabularSection.Total("Sum");
		TMCommonUseClient.RecordObjectIfNecessary(ThisObject, AdditionalParameters.WriteParameters,,True);
	EndIf;
	
EndProcedure

&AtServer
Procedure BlockData_()
	LockDataForEdit(Object.Ref,,ThisForm.UUID);
EndProcedure

&AtServer
Procedure UnlockData()
	UnlockDataForEdit(,ThisForm.UUID);
EndProcedure

&AtServer
Procedure FillInCurrencyOfMutualSettlementsOfDocument()
	
	CashServer.FillInCurrencyOfMutualSettlementsOfDocument(ThisForm);
	CurrencyDecorationAndPaymentRate = CashServer.CurrencyLabelAndPaymentRate(ThisObject);
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtServer
Procedure FillInCourseCourseDenominatorOfSettlements()
	
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
		
		ConfigureDependentFormElementsOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure YouAreAllowedToWorkWithAffiliatedPartners(TableRow)
	
	ReferencesArrray = CommonClientServer.ValueInArray(TableRow.ARAPObject);
	ComplianceOfContractCurrencyExchangeRate = ARAPAccountingServer.ComplianceOfARAPObjectsAndParametersOfContract(ReferencesArrray);
	TableRow.ItIsAllowedToWorkWithSubsidiaryPartners = ComplianceOfContractCurrencyExchangeRate[TableRow.ARAPObject].ItIsAllowedToWorkWithSubsidiaryPartners;
	TableRow.TheCalculationObjectMatchesTheDocument = ComplianceOfContractCurrencyExchangeRate[TableRow.ARAPObject].Object = Object.Ref;
	
EndProcedure

&AtServer
Procedure FillInCashier()
	
	CashierCashAccounts = Common.ObjectAttributeValue(Object.CashAccount, "Cashier");
	If ValueIsFilled(CashierCashAccounts) Then
		Object.Cashier = CashierCashAccounts;
	Else
		Object.Cashier = CashServer.CashierOfLastACWOrICO(Object.Date, Object.Organization, Object.CashAccount);
	EndIf;
	
EndProcedure

&AtServer
Procedure ClearAdditionalExpenseInformation()

	Object.Issue = "";
	Object.ByDocument = "";
	Object.Basis = "";
	Object.Application = "";

EndProcedure

&AtServer
Procedure ClearCalculationObject(DecryptionString)

	CashServer.ClearCalculationObject(Object, DecryptionString);

EndProcedure

&AtServer
Procedure AddLineOfDecryptionOnRequest(PaymentLine_1, AdditionalParameters)

	NewRow = Object.ARAPDetails.Add();
	FillPropertyValues(NewRow, PaymentLine_1);
	
	If Not ValueIsFilled(NewRow.Partner) Then
		If Not ValueIsFilled(Partner) Then
			GetDefaultServerPartner(Object.Counterparty, Partner, Object.BusinessOperation);
		EndIf;
		NewRow.Partner = Partner;
	EndIf;
	IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, NewRow, "Object.ARAPDetails");
	
	ARAPDetailsARAPObjectOnChangeServer(NewRow.GetID());
	FillInCourseAndMultiplicityInDecryptionLine(NewRow);
	CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
		NewRow, Object.Currency, CurrencyOfComplianceAccounting);
	CashServer.FormCourseDenominatorByText(NewRow, Object.Currency, CurrencyOfComplianceAccounting);
	YouAreAllowedToWorkWithAffiliatedPartners(NewRow);

EndProcedure

&AtClient
Procedure SetPaymentByRequestAttribute()

	If Not EnabledCreatingCashIssueWithoutPaymentRequest
		And ValueIsFilled(Object.CashAccount) Then
		Object.PaymentByRequests = True;
	ElsIf Not ValueIsFilled(Object.CashAccount) Then
		
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

	FillPropertyValues(DecryptionString, ContractDetails_);
	DecryptionString.Contract = Object.Contract;
	
	FillInCourseAndMultiplicityInDecryptionLine(DecryptionString);
	CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
		DecryptionString, Object.Currency, CurrencyOfComplianceAccounting);
	CashServer.FormCourseDenominatorByText(DecryptionString, Object.Currency, CurrencyOfComplianceAccounting);
	CashServer.SetDesignAccuracyOfCourse(ThisObject);

EndProcedure

&AtServer
Procedure UpdateDisplayRowPersons()
	
	RowIndividuals = NStr("vi = 'Danh sách nhân viên';
							|ru = 'Список работников';
							|en = 'Employee list'; fa = 'فهرست کارکنان';
							|it = 'Employee list';
							|pl = 'Employee list';
							|tr = 'Çalışan listesi'") + " (" + Object.PayrollPayment.Count() + ")";
	Items.RowIndividuals.TextColor =
		?(Object.PayrollPayment.Count() = 0, StyleColors.SpecialTextColor, StyleColors.HyperlinkColor);
	
EndProcedure

&AtServer
Function GetSalaryPaymentFromVault(AddressPayrollInVault)
	
	Object.PayrollPayment.Load(GetFromTempStorage(AddressPayrollInVault));
	Object.DocumentAmount = Object.PayrollPayment.Total("Sum");
	UpdateDisplayRowPersons();
	
EndFunction

&AtServer
Function PlacePayrollPaymentInVault()
	
	Return PutToTempStorage(Object.PayrollPayment.Unload());
	
EndFunction

&AtServer
Procedure FillInAmountOfUnpaidPayrollATServer()
	
	
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
