#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	Documents.PaymentRequest.FillInPaymentFormForBusinessTransaction(FillingData);
	
	BasisType = TypeOf(FillingData);
	
	If BasisType = Type("DocumentRef.PurchaseOrder") Then
		FillInByOrderToSupplier(FillingData, FillingData);
		
	ElsIf BasisType = Type("DocumentRef.ExpenseReport") Then
		FillInAdvanceReport(FillingData, FillingData);
		
	ElsIf BasisType = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
		FillInRequestForReturnOfGoodsFromClient(FillingData, FillingData);
		
	ElsIf BasisType = Type("DocumentRef.ReturnOfGoodsFromCustomer") Then
		InstructionsForReturningGoodsFromClient(FillingData, FillingData);
		
	ElsIf BasisType = Type("DocumentRef.VendorInvoice") Then
		InformationOnReceiptOfGoodsServices(FillingData, FillingData);
	
	ElsIf BasisType = Type("DocumentRef.VendorInvoiceServicesAndAssets") Then
		IncomeFromServicesAndNonCurrentAssets(FillingData, FillingData);
		
	ElsIf BasisType = Type("DocumentRef.ConsignmentReportToVendor") Then
		FillInReportToCommittee(FillingData, FillingData);
		
	ElsIf BasisType = Type("DocumentRef.PurchaseInvoiceConsignmentStockLost") Then
		FillInReportToCommitteeAboutWriteOff(FillingData, FillingData);
		
	ElsIf BasisType = Type("DocumentRef.ConsignmentReportFromCustomer") Then
		FillInReportOfCommissionAgent(FillingData, FillingData);
		
	ElsIf BasisType = Type("DocumentRef.CustomerInvoiceIntercompany") Then
		InstructionsForTransferOfGoods(FillingData, FillingData);
	ElsIf BasisType = Type("DocumentRef.ConsumptionReportSubcontractingServicesDeliveredIntercompany") Then
		FillInGiverReportBetweenCompanies(FillingData, FillingData);
	ElsIf BasisType = Type("DocumentRef.CommissionReportIntercompany") Then
		FillInCommissionReport(FillingData, FillingData);
		
	ElsIf BasisType = Type("DocumentRef.CCDImport") Then
		FillInImportCustomsDeclaration(FillingData, FillingData);
		
	ElsIf BasisType = Type("CatalogRef.CounterpartyContracts") Then
		FillInTheContract(FillingData, FillingData);
		
	ElsIf BasisType = Type("CatalogRef.LoanAndDepositContracts") Then
		FillInUnderLoanDepositAgreement(FillingData, FillingData);
		
	ElsIf BasisType = Type("DocumentRef.IntercompanyGoodsReturn") Then
		RefundAgreementsBetweenOrganizations(FillingData, FillingData);
		
	ElsIf TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("BusinessOperation")
		And FillingData.BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder
		And FillingData.Property("AdvanceHolder") Then
		
		If Not FillingData.Property("Department") Then
			FillingData.Insert("Department", PersonsTM.DivisionOfIndividual(FillingData.AdvanceHolder));
		EndIf;
		
		NewRow = ARAPDetails.Add();
		FillPropertyValues(NewRow, FillingData);
	ElsIf BasisType = Type("CatalogRef.LeaseContract") Then
		FillInLeaseAgreement(FillingData, FillingData);
	ElsIf BasisType = Type("DocumentRef.RedemptionOfGoodsFromStorage") Then
		InstructionsForRedemptionOfGoodsAcceptedForStorage(FillingData, FillingData);
		
	ElsIf BasisType = Type("DocumentRef.ReportOnVMIAdjustment") Then
		InstructionsForDebitingGoodsAcceptedForStorage(FillingData, FillingData);

	ElsIf BasisType = Type("CatalogRef.GiftCertificates") 
		Or BasisType = Type("Structure") 
			And FillingData.Property("GiftCertificate")
			And FillingData.Property("Counterparty") Then
		
		FillInGiftCertificate(FillingData, FillingData);
		
	ElsIf BasisType = Type("DocumentRef.SubcontractOrder2_5") Then
		FillInByOrderToProcessor2_5(FillingData, FillingData);
		
	ElsIf BasisType = Type("DocumentRef.SubcontractorReport2_5") Then
		FillInReportOfProcessor2_5(FillingData, FillingData);
		
	ElsIf TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("CommissionReportIntercompany") 
			And TypeOf(FillingData.CommissionReportIntercompany) = Type("DocumentRef.CommissionReportIntercompany") Then
			
		ReportOnCommission = FillingData.CommissionReportIntercompany;
		If ReportOnCommission.KeepCommissionFee Then
			Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không bắt buộc phải nhập giấy đề nghị chi tiêu tiền: Tiền công trên cơ sở chứng từ %1, vì tiền công được giữ lại trong đó';
				|ru = 'Не требуется вводить Заявку на расходование ДС: Вознаграждение на основании документа %1, поскольку в нем удержано вознаграждение';
				|en = 'It is not required to enter Payment request: Remuneration is based on the %1 document because remuneration is deducted in it'; fa = 'It is not required to enter Payment request: Remuneration is based on the %1 document because remuneration is deducted in it';
				|it = 'Non è richiesto l''inserimento della Domanda di spesa dei fondi monetari: il Compenso in base al documento %1, poiché in esso il compenso è trattenuto';
				|pl = 'Nie trzeba wprowadzać Wniosek o wydatkowanie środków pieniężnych: Wynagrodzenie na podstawie dokumentu %1, ponieważ w nim jest potrącono wynagrodzenie';
				|tr = 'Bir Harcama Beyanı girilmesine gerek yoktur: Ücretlendirme %1 belgesine dayanmaktadır, zira bu belge ücretleri saklı tutmaktadır'"),
			ReportOnCommission);
			Raise Text;
		EndIf;
		
		FillInCommissionReport(ReportOnCommission, FillingData, ReportOnCommission.Organization);
		
	ElsIf BasisType = Type("DocumentRef.ReceivingLeaseServices") Then
		FillInOnReceiptOfRentalServices(FillingData, FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.SalesOrder") Then
		FillInOnTheCustomerSOrder(FillingData, FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.CashAccountReceiptNote") Then
		FillInReceiptCashOrder(FillingData, FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.BankAccountReceiptNote") Then
		InstructionsForReceiptOfNonCashFunds(FillingData, FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.PaymentCardTransaction") Then
		FillInByPaymentCardTransaction(FillingData, FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.CommissionWriteOffReportIntercompany") Then
		FillInCommissionReport(FillingData, FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.CustomerBonusCertificate") Then
		FillInCertificateOfAwardToClient(FillingData, FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.ApplicationForCollateral") Then
		FillInAccordingToSupplyRequest(FillingData, FillingData);
	ElsIf TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("Basis")
		And TypeOf(FillingData.Basis) = Type("Array") Then
		
		FillByArrayOfBases(FillingData, FillingData.Basis);
	EndIf;
	
	AdditionalProperties.Insert("NeedToFillInCashRegisterWhenUsingMultipleCashRegistersIsFalse", False);
	AdditionalProperties.Insert("NeedToFillOutAccountWhenFOUseMultipleAccountsIsFalse", False);
	
	//++ WE
	If GetFunctionalOption("PayrollAndHumanResourcesWE") Then
		If BasisType = Type("Structure") And FillingData.Property("ArrayOfStatements") Then
			FillInHRFormOnSheet(FillingData, StandardProcessing);
		EndIf;
	Else
	//-- WE
		PaymentRequestLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	//++ WE
	EndIf;
	//-- WE
	
	FillOutBankAccounts(FillingData);
	
	Author = Users.CurrentUser();
	WhoStated = Users.CurrentUser();
		
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	If BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices
		And Not Catalogs.Companies.OrganizationIsInterconnectedWithOtherOrganizations(Organization) Then
		Organization = Undefined;
		BankAccount = Undefined;
	EndIf;
	
	InitializeDocument(FillingData);
	
	If TypeOf(FillingData) = Type("Structure") And FillingData.Property("BusinessOperation") Then
		ItemsAndDimensionsSelectionParameters = Documents.PaymentRequest.ItemsAndDimensionsSelectionParameters(
			FillingData.BusinessOperation);
	Else
		ItemsAndDimensionsSelectionParameters = Documents.PaymentRequest.ItemsAndDimensionsSelectionParameters(
			BusinessOperation);
	EndIf;
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	ControlPaymentByARAPObjects = Documents.PaymentRequest.ControlPaymentByARAPObjects(
														BusinessOperation, 
														ARAPDetails.UnloadColumn("ARAPObject"));
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	WhoStated = Users.CurrentUser();
	WhoDecided = Catalogs.Users.EmptyRef();
	Status = Enums.StatusesOfPaymentRequests.NotAgreedUpon;
	
	AllocationByAccounts.Clear();
	
	PaymentDate = Date(1, 1, 1);
	RequiredPaymentDate = Date(1, 1, 1);
	DocumentBasis = Undefined;
	
	ARAPAccountingServer.OnCopy(ThisObject);
	
	PaymentRequestLocalization.OnCopy(ThisObject, CopiedObject);
	
	Author = Users.CurrentUser();
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	AllAttributes = New Array;
	TransactionDetails = New Array;
	AttributesNotToCheck = New Array;
	
	ExplanationWithoutSplit = False;
	If AdditionalProperties.Property("ExplanationWithoutSplit") And AdditionalProperties.ExplanationWithoutSplit Then
		ExplanationWithoutSplit = True;
	EndIf;
	
	If ValueIsFilled(Organization)
		And ValueIsFilled(CompanyRecipient)
		And Organization = CompanyRecipient Then
		
		Text = NStr("vi = 'Một doanh nghiệp không thể đồng thời là nơi gửi và nơi nhận';
					|ru = 'Одна и та же организация не может являться отправителем и получателем одновременно';
					|en = 'Same company cannot be both a sender and a recipient'; fa = 'Same company cannot be both a sender and a recipient';
					|it = 'La stessa società non può essere mittente e destinatario contemporaneamente';
					|pl = 'Jedna i ta sama firma nie może jednocześnie być nadawcą i odbiorcą';
					|tr = 'Bir iş yeri aynı anda hem gönderici hem de alıcı olamaz'");
		CommonClientServer.MessageToUser(Text, ThisObject, "Organization",, Cancel);
	EndIf;
	
	// A payment card can only be used to pay for a refund to the customer.
	If BusinessOperation <> Enums.BusinessTransactions.RefundToCustomer
		And (MethodOfPaymentPaymentCard Or PaymentMethodOfPaymentRequest = Enums.PaymentForms.PaymentCard) Then
		
		ErrorText = NStr("vi = 'Có thể chỉ chọn thanh toán bằng thẻ thanh toán đối với hoàn lại tiền cho người mua';
						|ru = 'Оплату платежной картой можно выбирать только для возврата оплаты клиенту';
						|en = 'Payment by payment card can be selected only for refund to a customer'; fa = 'Payment by payment card can be selected only for refund to a customer';
						|it = 'Il pagamento con la carta può essere selezionato solo per il rimborso al cliente';
						|pl = 'Płatność kartą płatniczą można wybierać tylko dla zwrotu płatności klientowi';
						|tr = 'Kartla ödeme sadece müşteriye yapılacak iadeler için seçilebilir'");
		CommonClientServer.MessageToUser(ErrorText, ThisObject, "BusinessOperation",, Cancel);
	EndIf;
	
	// The receiving organization must be interconnected with the sending organization by organizational structure.
	If BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices
		And ValueIsFilled(Organization)
		And ValueIsFilled(CompanyRecipient)
		And Not Catalogs.Companies.OrganizationsAreInterconnectedByOrganizationalStructure(
			Organization, CompanyRecipient) Then
		
		ErrorText = NStr("vi = 'Doanh nghiệ-người nhận phải có quan hệ với doanh nghiệp-người gửi theo cơ cấu tổ chức.';
						|ru = 'Организация-получатель должна быть взаимосвязана с организацией-отправителем по организационной структуре.';
						|en = 'Receiving company should be connected with a shipping company by the organizational structure.'; fa = 'Receiving company should be connected with a shipping company by the organizational structure.';
						|it = 'La società-destinatario deve essere interconnessa con la società-mittente per la struttura organizzativa.';
						|pl = 'Firma odbiorca powinna być wzajemnie powiązana z firmą nadawcą według struktury organizacyjnej.';
						|tr = 'Alıcı iş yeri, organizasyon yapısı bakımından gönderici iş yeri ile bağlantılı olmalıdır.'");
		CommonClientServer.MessageToUser(ErrorText, ThisObject, "CompanyRecipient",, Cancel);
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder Then
		AttributesNotToCheck.Add("ExpenseReportDate");
		If Not ValueIsFilled(ExpenseReportDate) Then
			ErrorText = NStr("vi = 'Trường ""Thanh toán"" chưa điền';
							|ru = 'Поле ""Отчитаться"" не заполнено';
							|en = '""Report"" is required'; fa = '""Report"" is required';
							|it = 'Il campo ""Presentare il rendiconto"" non è compilato';
							|pl = 'Pole ""Złożyć sprawozdanie"" nie jest wypełnione';
							|tr = '""Rapor"" alanı doldurulmamış'");
			CommonClientServer.MessageToUser(ErrorText,, "ExpenseReportPeriod",, Cancel);
		EndIf;
	EndIf;
	
	If AllocationByAccounts.Total("Sum") > DocumentAmount Then
		ErrorText = NStr("vi = 'Việc phân bổ tài khoản không thể vượt quá số lượng chứng từ';
						|ru = 'Сумма распределения по счетам не может превышать сумму документа';
						|en = 'The amount of allocation by accounts cannot exceed the document amount'; fa = 'The amount of allocation by accounts cannot exceed the document amount';
						|it = 'L''importo della distribuzione sui conti non può superare l''importo del documento';
						|pl = 'Wartość dystrybucji kont nie może przekroczyć kwoty dokumentu';
						|tr = 'Hesaplara tahsis edilen tutar, belge tutarını aşamaz'");
		CommonClientServer.MessageToUser(ErrorText, ThisObject, "AllocationByAccounts",, Cancel);
	EndIf;
	
	If RequiredPaymentDate < BegOfDay(Date) Then
		Text = NStr("vi = 'Ngày thanh toán mong muốn không thể nhỏ hơn ngày lập chứng từ';
					|ru = 'Желательная дата платежа не может быть меньше даты документа';
					|en = 'Required payment date cannot be earlier than the document date'; fa = 'Required payment date cannot be earlier than the document date';
					|it = 'La data auspicabile di pagamento non può essere inferiore alla data del documento';
					|pl = 'Planowana data płatności nie może być mniejsza niż data dokumentu';
					|tr = 'İstenen ödeme tarihi belgenin tarihinden daha önce olamaz'");
		CommonClientServer.MessageToUser(Text, ThisObject, "RequiredPaymentDate",, Cancel);
	EndIf;
	
	For Each DistributionString In AllocationByAccounts Do
		If DistributionString.PaymentDate < BegOfDay(Date) Then
			Text = NStr("vi = 'Ngày thanh toán không thể nhỏ hơn ngày chứng từ';
						|ru = 'Дата платежа не может быть меньше даты документа';
						|en = 'Payment date cannot be earlier than the document date'; fa = 'Payment date cannot be earlier than the document date';
						|it = 'La data del pagamento non può essere antecedente alla data del documento';
						|pl = 'Data płatności nie może być mniejsza niż data dokumentu';
						|tr = 'Ödeme tarihi belgenin tarihinden daha önce olamaz'");
			CommonClientServer.MessageToUser(
				Text,
				ThisObject,
				"AllocationByAccounts[" + AllocationByAccounts.IndexOf(DistributionString) + "].PaymentDate",,
				Cancel);
		EndIf;
	EndDo;
	
	If Status = Enums.StatusesOfPaymentRequests.AgreedUpon
		And Not UserRightsCached.PaymentRequestsApproval() Then
		
		ErrorText = NStr("vi = 'Bạn không có quyền thống nhất đề nghị chi tiền';
						|ru = 'У вас нет права согласования заявок на расходование денежных средств';
						|en = 'You are not authorized to approve payment requests'; fa = 'You are not authorized to approve payment requests';
						|it = 'Non vi sono diritti di concordare le richieste di spesa di fondi monetari';
						|pl = 'Nie masz uprawnień uzgodnienia wniosków o wydatkowanie środków pieniężnych';
						|tr = 'Ödeme taleplerini onaylama hakkına sahip değilsiniz'");
		CommonClientServer.MessageToUser(ErrorText, ThisObject,,, Cancel);
		
	ElsIf Status = Enums.StatusesOfPaymentRequests.AmountDue
		And Not UserRightsCached.ApprovalOfPaymentRequestsForPayment() Then
		
		ErrorText = NStr("vi = 'Bạn không có quyền phê duyệt thanh toán giấy đề nghị chi tiền';
						|ru = 'У вас нет права утверждения к оплате заявок на расходование денежных средств';
						|en = 'You are not authorized to confirm payment requests'; fa = 'You are not authorized to confirm payment requests';
						|it = 'Non vi sono diritti di approvare al pagamento le richieste di spesa di fondi monetari';
						|pl = 'Nie masz uprawnień zatwierdzenia do płatności zleceń na wydatkowanie środków pieniężnych';
						|tr = 'Ödeme taleplerini ödeme hakkına sahip değilsiniz'");
		CommonClientServer.MessageToUser(ErrorText, ThisObject,,, Cancel);
	EndIf;
	
	If Not (BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder And PersonsList) Then
		CashServer.CheckCompletionOfPaymentDecryption(ThisObject, DocumentAmount, BusinessOperation, Cancel);
	ElsIf TransferToEmployeeViaABank Then
		CashServer.CheckPersonalAccountsOfBankEmployees(ThisObject, Cancel);
	EndIf;
	
	// We check the correspondence of the application currency, the settlement currency and the payment currency
	If AmountPlanning = Enums.MethodsOfPlanningRequestPayment.InARAPCurrency
		And BusinessOperation <> Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices
		And BusinessOperation <> Enums.BusinessTransactions.CurrencyConversion
		And BusinessOperation <> Enums.BusinessTransactions.SalaryPayment Then
		
		ARAPAccountingServer.FillInAmountOfSettlementsInTablePart(Currency, Date, ARAPDetails, Organization);
		CheckIfSettlementCurrencyMatches(Cancel);
	EndIf;
	
	Documents.PaymentRequest.FillInNamesOfBusinessTransactionDetails(
		ThisObject, AllAttributes, TransactionDetails);
		
	TMCommonUseClientServer.FillInArrayOfUnverifiableBankingDetails(
		AllAttributes, TransactionDetails, AttributesNotToCheck);
		
	If PaymentMethodOfPaymentRequest <> Enums.PaymentForms.BankAccountPayment
		And PaymentMethodOfPaymentRequest <> Enums.PaymentForms.InstantPayments Then
		AttributesNotToCheck.Add("CounterpartyBankAccount");
	EndIf;
	
	If ExplanationWithoutSplit Then
		AttributesNotToCheck.Add("ARAPDetails.Sum");
	EndIf;
	
	If Status = Enums.StatusesOfPaymentRequests.NotAgreedUpon
		Or Status = Enums.StatusesOfPaymentRequests.IsRejected Then
		
		AttributesNotToCheck.Add("CashFlowItem");
		AttributesNotToCheck.Add("ARAPDetails.CashFlowItem");
		AttributesNotToCheck.Add("Counterparty");
		AttributesNotToCheck.Add("CounterpartyBankAccount");
		AttributesNotToCheck.Add("ARAPDetails.Partner");
		AttributesNotToCheck.Add("AssetAndLiabilityItem");
		AttributesNotToCheck.Add("ARAPDetails.ExpenseItem");
		AttributesNotToCheck.Add("PersonalAccountsOfStaff.PersonalAccount");
		AttributesNotToCheck.Add("PersonalAccountsOfStaff.CashFlowItem");
		AttributesNotToCheck.Add("ARAPDetails.Counterparty");
		
	ElsIf Status = Enums.StatusesOfPaymentRequests.AgreedUpon Then
		AttributesNotToCheck.Add("CounterpartyBankAccount");
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany
		Or BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany
		Or BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices Then
		
		If PaymentMethodOfPaymentRequest = Enums.PaymentForms.CashAccountPayment_ Then
			AttributesNotToCheck.Add("BankAccountBeneficiary");
			
		ElsIf PaymentMethodOfPaymentRequest = Enums.PaymentForms.BankAccountPayment Then
			AttributesNotToCheck.Add("CashAccountRecipient");
			
		Else
			AttributesNotToCheck.Add("BankAccountBeneficiary");
			AttributesNotToCheck.Add("CashAccountRecipient");
		EndIf;
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.CurrencyConversion Then
		AttributesNotToCheck.Add("BankAccountBeneficiary");
		AttributesNotToCheck.Add("CashAccountRecipient");
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder Then
		If PersonsList Then
			AttributesNotToCheck.Add("AdvanceHolder");
			AttributesNotToCheck.Add("ARAPDetails");
			AttributesNotToCheck.Add("ARAPDetails.CashFlowItem");
			AttributesNotToCheck.Add("ARAPDetails.Sum");
			If Not TransferToEmployeeViaABank Then
				AttributesNotToCheck.Add("CounterpartyBankAccount");
			EndIf;
		Else
			AttributesNotToCheck.Add("PersonalAccountsOfStaff");
			AttributesNotToCheck.Add("PersonalAccountsOfStaff.Individual");
			AttributesNotToCheck.Add("PersonalAccountsOfStaff.PersonalAccount");
			AttributesNotToCheck.Add("PersonalAccountsOfStaff.Sum");
			AttributesNotToCheck.Add("PersonalAccountsOfStaff.CashFlowItem");
		EndIf;
		If PaymentMethodOfPaymentRequest = Enums.PaymentForms.CashAccountPayment_ Then
			AttributesNotToCheck.Add("PersonalAccountsOfStaff.PersonalAccount");
			AttributesNotToCheck.Add("Counterparty");
		EndIf;
	EndIf;
	
	CashServer.AddUnverifiableDetailsForPaymentOfWages(
		ThisObject, AttributesNotToCheck, PayrollTransaction);
	
	If TransferToEmployeeViaABank Then
		
		If PaymentMethodOfPaymentRequest <> Enums.PaymentForms.CashAccountPayment_ Then
			TransactionDetails.Add("Counterparty");
			TransactionDetails.Add("CounterpartyBankAccount");
		EndIf;
		
	Else
		
		If (BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder
			Or BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToEmployee)
			And AttributesNotToCheck.Find("Counterparty") = Undefined Then
			AttributesNotToCheck.Add("Counterparty");
		EndIf;
		
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.TransferOfTaxesAndContributions
		And Not GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities") Then
		AttributesNotToCheck.Add("ARAPDetails.ExpenseItem");
	EndIf;
	
	CashServer.CheckPartnerContent(
		ThisObject, BusinessOperation, AttributesNotToCheck, ExplanationWithoutSplit, Cancel);
	
	AttributesNotToCheck.Add("ExpenseItem");
	If RecordCommission And FeeAmount<>0 And Not ValueIsFilled(ExpenseItem) Then
		Text = NStr("vi = 'Chưa điền trường ""Dạng chi phí"" theo phí thanh toán thẻ';
					|ru = 'Поле ""Статья расходов"" по эквайринговой комиссии не заполнено';
					|en = 'The ""Expense item"" field for the acquiring commission is required'; fa = 'The ""Expense item"" field for the acquiring commission is required';
					|it = 'Il campo ""Voci di spesa"" per la commissione di acquisizione non è compilato';
					|pl = 'Nie wypełniono pola ""Pozycja rozchodów"" z tytułu prowizji agenta rozliczeniowego';
					|tr = 'POS komisyonu için ""Gider kalemi"" alanı doldurulmamış'");
		Common.MessageToUser(Text, ThisObject, "ExpenseItem",, Cancel);
	EndIf;
	
	If Not ListOfCounterparties_ Then
		AttributesNotToCheck.Add("ARAPDetails.Counterparty");
	Else
		
		If PaymentMethodOfPaymentRequest = Enums.PaymentForms.CashAccountPayment_ Then
			AttributesNotToCheck.Add("Counterparty");
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(BankAccount) Then
		CashServer.CheckAvailabilityOfBankAccount(ThisObject, BankAccount, "BankAccount");
	EndIf;
	
	If AllocationByAccounts.Count() <> 0
		And PaymentMethodOfPaymentRequest <> Enums.PaymentForms.CashAccountPayment_ Then
		CashServer.CheckAvailabilityOfTabularPartOfBankAccount(
			ThisObject, "AllocationByAccounts", "BankAccountCashAccount");
	EndIf;
	
	If ValueIsFilled(CounterpartyBankAccount)
		And TransactionDetails.Find("CounterpartyBankAccount") <> Undefined Then
		CashServer.CheckAvailabilityOfBankAccount(
			ThisObject, CounterpartyBankAccount, "CounterpartyBankAccount");
	EndIf;
	
	If ValueIsFilled(BankAccountBeneficiary)
		And TransactionDetails.Find("BankAccountBeneficiary") <> Undefined Then
		CashServer.CheckAvailabilityOfBankAccount(
			ThisObject, BankAccountBeneficiary, "BankAccountBeneficiary");
	EndIf;
	
	If ValueIsFilled(BankAccountForFeeWriteOff)
		And TransactionDetails.Find("BankAccountForFeeWriteOff") <> Undefined Then
		CashServer.CheckAvailabilityOfBankAccount(
			ThisObject, BankAccountForFeeWriteOff, "BankAccountForFeeWriteOff");
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.PaymentRequest.ItemsAndDimensionsSelectionParameters(BusinessOperation);
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);
	
	CashServer.CheckRecipientSBankAccount(ThisObject, Cancel);
	CashServer.CheckConversionCurrency(ThisObject, Cancel);
	
	CheckWhetherApplicationHasBeenPaid(Cancel);
	CheckRepaymentDates(Cancel);
	
	PaymentRequestLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	If ExplanationWithoutSplit Then
		CashServer.CheckCompletionOfDecryptionWithoutSplitting(
			ThisObject, CheckedAttributes, "ARAPDetails", "ExplanationWithoutSplit", Cancel);
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	CashServer.BeforeWrite(ThisObject, Cancel);
	ARAPAccountingServer.BeforeWrite(ThisObject, Cancel, WriteMode);
	
	UnusedAttributes = New Array;
	ArrayOfAllProps = New Array;
	ArrayOfOperationDetails = New Array;
	
	Documents.PaymentRequest.FillInNamesOfBusinessTransactionDetails(
		ThisObject, ArrayOfAllProps, ArrayOfOperationDetails);
		
	If WriteMode = DocumentWriteMode.Posting Then
		
		If ArrayOfOperationDetails.Find("ARAPDetails.AmountARAP") <> Undefined Then
			ARAPAccountingServer.FillInAmountOfSettlementsInTablePart(Currency, Date, ARAPDetails, Organization);
		EndIf;
		
		CashServer.FillInOrganizationInTableSection(ARAPDetails, Organization, BusinessOperation);
	EndIf;
	
	If PayrollTransaction = Enums.BusinessTransactions.SalaryPaymentViaCashAccount Then
		
		UnusedAttributes.Add("Counterparty");
		If PersonalAccountsOfStaff.Count() <> 1 Then
			UnusedAttributes.Add("CounterpartyBankAccount");
		EndIf;
		
	ElsIf PayrollTransaction = Enums.BusinessTransactions.SalaryPaymentToBankAccounts Then

		If Not TransferToEmployeeViaABank Then
			
			UnusedAttributes.Add("Counterparty");
			
			If PersonalAccountsOfStaff.Count() <> 1 Then
				UnusedAttributes.Add("CounterpartyBankAccount");
			EndIf;
			
		EndIf;
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToEmployee
		And Not GetFunctionalOption("UsePayrollTM") Then
		
		ARAPDetails.Clear();
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder Then
		If PersonsList Then
			UnusedAttributes.Add("AdvanceHolder");
			
			If Not ValueIsFilled(Counterparty) Then
				UnusedAttributes.Add("CounterpartyBankAccount");
			EndIf;
			
			ARAPDetails.Clear();
		Else
			PersonalAccountsOfStaff.Clear();
		EndIf;
		
		If PaymentMethodOfPaymentRequest = Enums.PaymentForms.CashAccountPayment_ Then
			
			UnusedAttributes.Add("Counterparty");
			UnusedAttributes.Add("CounterpartyBankAccount");
			
		EndIf;
		
	Else
		UnusedAttributes.Add("PersonsList");
	EndIf;
	
	If PaymentMethodOfPaymentRequest = Enums.PaymentForms.CashAccountPayment_ Then
		UnusedAttributes.Add("CounterpartyBankAccount");
	EndIf;
	
	If TransferToEmployeeViaABank Then
		
		If PaymentMethodOfPaymentRequest <> Enums.PaymentForms.CashAccountPayment_ Then
			ArrayOfOperationDetails.Add("Counterparty");
			ArrayOfOperationDetails.Add("CounterpartyBankAccount");
		EndIf;
		
	Else
		
		If (BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder
			Or BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToEmployee)
			And UnusedAttributes.Find("Counterparty") = Undefined Then
			UnusedAttributes.Add("Counterparty");
		EndIf;
		
	EndIf;
	
	If ArrayOfOperationDetails.Find("ARAPDetails.Counterparty") <> Undefined Then
		CashServer.FillInCounterpartyOfPaymentDecryptionWithoutListOfCounterparties(ThisObject, ARAPDetails);
	EndIf;
	
	If ArrayOfOperationDetails.Find("ARAPDetails.Partner") <> Undefined Then
		CashServer.FillInPaymentTranscriptForm(ThisObject, ARAPDetails);
	EndIf;
	
	If ListOfCounterparties_
		And ValueIsFilled(Contract) Then
		UnusedAttributes.Add("Contract");
	EndIf;
	
	For Each UnusedProps In UnusedAttributes Do
		AttributeToDelete = ArrayOfOperationDetails.Find(UnusedProps);
		If AttributeToDelete <> Undefined Then
			ArrayOfOperationDetails.Delete(AttributeToDelete);
		EndIf;
	EndDo;
	
	CashServer.ClearUnusedProps(ThisObject, ArrayOfAllProps, ArrayOfOperationDetails);
	CashServer.ClearUnusedPaymentFormDetails(ThisObject, PaymentMethodOfPaymentRequest, True);
	
	If AmountPlanning <> Enums.MethodsOfPlanningRequestPayment.InARAPCurrency Then
		PaymentWithConversion = CashServer.DefinePaymentWithConversion(ThisObject);
	Else
		PaymentWithConversion = False;
	EndIf;
	
	If WriteMode = DocumentWriteMode.Posting
		And BusinessOperation = Enums.BusinessTransactions.SalaryPayment
		And AssetAndLiabilityItem <> ChartsOfCharacteristicTypes.AssetLiabilityItems.Payroll Then
		
		AssetAndLiabilityItem = ChartsOfCharacteristicTypes.AssetLiabilityItems.EmptyRef();
		AssetsLiabilitiesDimension = Undefined;
	EndIf;

	If PersonalAccountsOfStaff.Count() = 1
		And (BusinessOperation = Enums.BusinessTransactions.SalaryPayment
			And PayrollTransaction = Enums.BusinessTransactions.SalaryPaymentToBankAccounts
			Or BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder
			And PersonsList)
		And Not ValueIsFilled(Counterparty) Then
		CounterpartyBankAccount = PersonalAccountsOfStaff[0].PersonalAccount;
	EndIf;
	
	If AllocationByAccounts.Count() Then
		
		If IsNew() Then
			StatusSetNotAgreed = (Status = Enums.StatusesOfPaymentRequests.NotAgreedUpon);
		Else
			StatusSetNotAgreed = (Common.ObjectAttributeValue(Ref, "Status") <> Status
				And Status = Enums.StatusesOfPaymentRequests.NotAgreedUpon);
		EndIf;
		
		If StatusSetNotAgreed Then
			AllocationByAccounts.Clear();
		Else
			PaymentDates_ = AllocationByAccounts.Unload(,"PaymentDate");
			PaymentDates_.Sort("PaymentDate");
			PaymentDate = PaymentDates_[0].PaymentDate;
		EndIf;
	Else
		PaymentDate = RequiredPaymentDate;
		
		If IsNew() Then
			AmountDueStatusHasBeenSet = (Status = Enums.StatusesOfPaymentRequests.AmountDue);
		Else
			AmountDueStatusHasBeenSet = (Common.ObjectAttributeValue(Ref, "Status") <> Status
				And Status = Enums.StatusesOfPaymentRequests.AmountDue);
		EndIf;
		
		If AmountDueStatusHasBeenSet
			And ValueIsFilled(PaymentDate)
			And ValueIsFilled(DocumentAmount) Then
		
			BankAccountCashAccount = Undefined;
			
			If ValueIsFilled(BankAccount) Then
				BankAccountCashAccount = BankAccount;
			ElsIf ValueIsFilled(CashAccount) Then
				BankAccountCashAccount = CashAccount;
			EndIf;
			
			If ValueIsFilled(BankAccountCashAccount) Then
				NewRow = AllocationByAccounts.Add();
				NewRow.BankAccountCashAccount = BankAccountCashAccount;
				NewRow.Sum = DocumentAmount;
				NewRow.PaymentDate = PaymentDate;
			EndIf;
		EndIf;
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder
		And PersonsList Then
		ArrayOfCFItems = TMCommonUse.DeleteDuplicateElementsFromArray(
			PersonalAccountsOfStaff.UnloadColumn("CashFlowItem"));
	Else
		ArrayOfCFItems = TMCommonUse.DeleteDuplicateElementsFromArray(
			ARAPDetails.UnloadColumn("CashFlowItem"));
	EndIf;
	
	If ArrayOfCFItems.Count() = 1 Then
		CashFlowItem = ArrayOfCFItems[0];
	ElsIf ArrayOfCFItems.Count() > 1 Then
		CashFlowItem = Undefined;
	EndIf;
	
	DistributionTable_1 = AllocationByAccounts.Unload();
	DistributionTable_1.GroupBy("BankAccountCashAccount, PaymentDate", "Sum");
	AllocationByAccounts.Load(DistributionTable_1);
	AllocationByAccounts.Sort("PaymentDate");
	
	ControlPaymentByARAPObjects = Documents.PaymentRequest.ControlPaymentByARAPObjects(
														BusinessOperation, 
														ARAPDetails.UnloadColumn("ARAPObject"));
	
	//Setting up accounting accounts
	GLAccountSettingsServer.BeforeWrite(ThisObject,
		Documents.PaymentRequest.AccountingAccountSettings_(BusinessOperation, TaxType));
	ItemsAndDimensionsSelectionParameters = Documents.PaymentRequest.ItemsAndDimensionsSelectionParameters(BusinessOperation);
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	PaymentRequestLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	If Not ValueIsFilled(Author) And IsNew() Then
		Author = Users.CurrentUser();
	EndIf;
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	PaymentRequestLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	PaymentRequestLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	PaymentRequestLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillInDetailsBasedOnRequestResult(DocumentBasis, QueryResult, FillingData, FillingInContract = False, AmountToPay = Undefined) Export
	
	If QueryResult.IsEmpty() Then
		If FillingInContract Then
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không cần nhập Giấy đề nghị thanh toán trên cơ sở hợp đồng %1';
					|ru = 'Не требуется вводить Заявку на расходование ДС на основании договора %1';
					|en = 'Entering payment request on basis of contract %1 is not required'; fa = 'Entering payment request on basis of contract %1 is not required';
					|it = 'Non è necessario immettere la Richiesta di spesa di fondi monetari in base all''accordo %1';
					|pl = 'Nie jest wymagane wprowadzanie Wniosku o wydatkowanie środków pieniężnych na podstawie kontraktu %1';
					|tr = '%1sözleşmesine dayalı bir ödeme talebi girmeye gerek yok '"),
				DocumentBasis);
		Else
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không cần nhập Giấy đề nghị thanh toán trên cơ sở chứng từ %1';
					|ru = 'Не требуется вводить Заявку на расходование ДС на основании документа %1';
					|en = 'Entering payment request on basis of document %1 is not required'; fa = 'Entering payment request on basis of document %1 is not required';
					|it = 'Non è necessario immettere la Richiesta di spesa di fondi monetari in base al documento %1';
					|pl = 'Nie jest wymagane wprowadzanie Wniosku o wydatkowanie środków pieniężnych na podstawie dokumentu %1';
					|tr = '%1belgesine dayalı bir ödeme talebi girmeye gerek yok '"),
				DocumentBasis);
		EndIf;
		Raise Text;
	Else
		FillingData = New Structure;
		For Each Column In QueryResult.Columns Do
			FillingData.Insert(Column.Name);
		EndDo;
		
		FillingData.Insert("RequiredPaymentDate");
		FillingData.Insert("PaymentID");
		
		Selection = QueryResult.Select();
		Selection.Next();
		
		If CommonClientServer.HasAttributeOrObjectProperty(Selection, "ContractType")
			And CashServer.TypesOfContractsForPaymentToSupplier().Find(Selection.ContractType) = Undefined
			And CashServer.TypesOfRefundContracts().Find(Selection.ContractType) = Undefined Then
			Raise CashServer.TextAboutExclusionOfPaymentUnderContract(
				Metadata().Synonym,
				Selection.ContractType);
		EndIf;
		
		FillPropertyValues(FillingData, Selection);
		
		If Not ValueIsFilled(FillingData.PaymentMethodOfPaymentRequest) Then
			FillingData.PaymentMethodCash = True;
			FillingData.PaymentMethodBankAccount = True;
		EndIf;
		
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(FillingData.PaymentMethodOfPaymentRequest, FillingData);
		
		OrdersToSupplier = DocumentBasis;
		
		If TypeOf(DocumentBasis) = Type("DocumentRef.VendorInvoice") Then
			
			Query = New Query("
			|SELECT DISTINCT
			|	GoodsTable.PurchaseOrder AS PurchaseOrder
			|FROM
			|	Document.VendorInvoice.Goods AS GoodsTable
			|WHERE
			|	GoodsTable.Ref = &Ref
			|	AND GoodsTable.Ref.ReceiptUnderOrders
			|	AND GoodsTable.Ref.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
			|	AND GoodsTable.Ref.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
			|");
			Query.SetParameter("Ref", DocumentBasis);
			
			RequestResultForOrders = Query.Execute();
			If Not RequestResultForOrders.IsEmpty() Then
				OrdersToSupplier = RequestResultForOrders.Unload().UnloadColumn("PurchaseOrder");
				OrdersToSupplier.Add(DocumentBasis);
			EndIf;
			
		ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.SubcontractorReport2_5") Then
			
			Query = New Query("
			|SELECT DISTINCT
			|	GoodsTable.SubcontractOrder AS SubcontractOrder
			|FROM
			|	Document.SubcontractorReport2_5.ManufacturedProducts AS GoodsTable
			|WHERE
			|	GoodsTable.Ref = &Ref
			|	AND GoodsTable.Ref.ByOrders
			|	AND GoodsTable.Ref.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
			|	AND GoodsTable.Ref.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
			|");
			Query.SetParameter("Ref", DocumentBasis);
			
			RequestResultForOrders = Query.Execute();
			If Not RequestResultForOrders.IsEmpty() Then
				OrdersToSupplier = RequestResultForOrders.Unload().UnloadColumn("SubcontractOrder");
				OrdersToSupplier.Add(DocumentBasis);
			EndIf;
			
		ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.ReceivingLeaseServices") Then
			Return;
		
		ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.CustomerBonusCertificate") Then
			Return;
		ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.ApplicationForCollateral") Then
			Return;
		EndIf;
		
		If ValueIsFilled(Selection.Contract) Then
			
			ContractDetails_ = Common.ObjectAttributesValues(
				Selection.Contract, "ContractSchedule, PaymentID");
			
			If ValueIsFilled(ContractDetails_.ContractSchedule) Then
				OrdersToSupplier = CommonClientServer.ValueInArray(Selection.Contract);
				OrdersToSupplier.Add(DocumentBasis);
			EndIf;
			
			If Not ValueIsFilled(FillingData.PaymentID) Then
				FillingData.PaymentID = ContractDetails_.PaymentID;
			EndIf;
			
		Else
			ContractSchedule = Undefined;
		EndIf;

		PaymentRequestLocalization.FillInPaymentLinkBasedOn(FillingData, OrdersToSupplier, AmountToPay);
		
		If FillingInContract And Not ValueIsFilled(ContractSchedule) Then
			If Selection.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts 
				Or Selection.ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice Then
				ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentUnderContractWithSupplier(
					DocumentBasis, FillingData.Currency, ARAPDetails, Selection.Organization);
			Else
				DecryptionString = ARAPDetails.Add();
				FillPropertyValues(DecryptionString, Selection);
			EndIf;
		
		Else
			ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfOrderPaymentToSupplier(
				OrdersToSupplier,
				Selection.Contract,
				FillingData.Currency,
				?(AmountToPay = Undefined, ?(FillingData.Property("Sum"), FillingData.Sum, 0), AmountToPay),
				ARAPDetails,
				?(ValueIsFilled(FillingData.RequiredPaymentDate), Undefined, FillingData.RequiredPaymentDate));
		EndIf;

	EndIf;
	
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure

Procedure FillInByOrderToSupplier(Val DocumentBasis, FillingData)
	
	Query = New Query("
	|SELECT
	|	CASE WHEN DocumentData.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.BankAccount.Owner
	|	WHEN DocumentData.CashAccount <> VALUE(Catalog.CashAccounts.EmptyRef) THEN
	|		DocumentData.CashAccount.Owner
	|	ELSE
	|		DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.Department AS Department,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	ISNULL(DocumentData.Contract.PaymentsAsPer275FZ, FALSE) AS PaymentsAsPer275FZ,
	|	ISNULL(DocumentData.Contract.ContractWithSDOParticipant, FALSE) AS ContractWithSDOParticipant,
	|	ISNULL(DocumentData.Contract.PaymentOfExpensesAccordingToTariffsThatAreASubjectToStateRegulation, FALSE) AS PaymentOfExpensesAccordingToTariffsThatAreASubjectToStateRegulation,
	|	DocumentData.Priority AS Priority,
	|	DocumentData.Currency AS ARAPCurrency,
	|
	|	CASE WHEN DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.CashAccountPayment_) THEN
	| 		TRUE
	|	ELSE
	|		FALSE
	|	END AS PaymentMethodCash,
	|
	|	CASE WHEN DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.BankAccountPayment)
	|			OR DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.InstantPayments) THEN
	| 		TRUE
	|	ELSE
	|		FALSE
	|	END AS PaymentMethodBankAccount,
	|	DocumentData.PaymentMethod AS PaymentMethodOfPaymentRequest,
	|
	|	CASE WHEN DocumentData.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.BankAccount
	|	ELSE
	|		DocumentData.Contract.BankAccount
	|	END AS BankAccount,
	|
	|	DocumentData.CashAccount AS CashAccount,
	|	DocumentData.Contract.CounterpartyBankAccount AS CounterpartyBankAccount,
	|	DocumentData.PaymentID AS PaymentID,
	|
	|	CASE WHEN DocumentData.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.BankAccount.CashCurrency
	|	WHEN DocumentData.CashAccount <> VALUE(Catalog.CashAccounts.EmptyRef) THEN
	|		DocumentData.CashAccount.CashCurrency
	|	ELSE
	|		ISNULL(DocumentData.Contract.BankAccount.CashCurrency, DocumentData.Currency)
	|	END AS Currency,
	|
	|	VALUE(Enum.BusinessTransactions.PaymentToVendor) AS BusinessOperation,
	|	DocumentData.OperationWithSelfEmployedPerson AS OperationWithSelfEmployedPerson,
	|	&Ref AS DocumentBasis
	|FROM
	|	Document.PurchaseOrder AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND NOT DocumentData.BusinessOperation IN(
	|		VALUE(Enum.BusinessTransactions.ConsignmentProcurement),
	|		VALUE(Enum.BusinessTransactions.ReceivingForStorageWithRightOfSale))
	|	AND DocumentData.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)
	|");
	
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	FillInDetailsBasedOnRequestResult(DocumentBasis, QueryResult, FillingData);
	
EndProcedure

Procedure FillInAdvanceReport(Val DocumentBasis, FillingData)
	
	QueryText = "
	|SELECT
	|	VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder) AS BusinessOperation,
	|	DocumentData.Organization AS Organization,
	|	ISNULL(Cash.Currency,VALUE(Catalog.Currencies.EmptyRef)) AS Currency,
	|	ISNULL(Cash.Currency,VALUE(Catalog.Currencies.EmptyRef)) AS ARAPCurrency,
	|	DocumentData.Department AS Department,
	|	DocumentData.AdvanceHolder AS AdvanceHolder,
	|	DocumentData.AdvanceHolder.Description AS Issue,
	|	DocumentData.Ref AS ExpenseReport,
	|	PRESENTATION(DocumentData.Ref) AS Basis,
	|	Cash.IssuancePurpose AS CashFlowItem,
	|	ISNULL(-Cash.SumBalance,0) AS Sum,
	|	ISNULL(-Cash.SumBalance,0) AS AmountARAP,
	|	ISNULL(-Cash.SumBalance,0) AS DocumentAmount,
	|	&Ref AS DocumentBasis
	|FROM
	|	Document.ExpenseReport AS DocumentData
	|
	|	LEFT JOIN
	|		AccumulationRegister.AdvanceHolderCash.Balance(, ) AS Cash
	|	ON
	|		Cash.Organization = DocumentData.Organization
	|		AND Cash.AdvanceHolder = DocumentData.AdvanceHolder
	|		AND Cash.SumBalance < 0
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Ref", DocumentBasis); 
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	
	FillingData = New Structure;
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult.Select();
	DocumentCurrency = Undefined;
	While Selection.Next() Do
		If DocumentCurrency = Undefined Then
			DocumentCurrency = Selection.Currency;
		EndIf;
		
		If DocumentCurrency = Selection.Currency Then
			FillPropertyValues(FillingData, Selection);
			
			CurrencyOfRecipient = New Array;
			CurrencyOfRecipient.Add(Undefined);
			CurrencyOfRecipient.Add(Selection.Currency);
			
			If CurrencyOfRecipient.Find(FillingData.Currency) = Undefined Then
				CurrencyOfRecipient.Add(FillingData.Currency);
			EndIf;
			
			CashServer.DefaultCounterpartyBankAccount(
				CounterpartyBankAccount, FillingData.AdvanceHolder, CurrencyOfRecipient);
			NewRow = ARAPDetails.Add();
			FillPropertyValues(NewRow, Selection);
		EndIf;
	EndDo;
	
EndProcedure

Procedure InstructionsForReturningGoodsFromClient(Val DocumentBasis, FillingData)
	
	Query = New Query("
	|SELECT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.RequestForReturnOfGoodsFromCustomer AS RequestForReturnOfGoodsFromCustomer,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.DocumentAmount AS Sum,
	|
	|	CASE WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromRetailCustomer) THEN
	|		FALSE
	|	ELSE
	|		TRUE
	|	END AS PaymentMethodBankAccount,
	|
	|	CASE WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromRetailCustomer) THEN
	|		VALUE(Enum.PaymentForms.CashAccountPayment_)
	|	ELSE
	|		VALUE(Enum.PaymentForms.EmptyRef)
	|	END AS PaymentMethodOfPaymentRequest,
	|
	|	VALUE(Enum.BusinessTransactions.RefundToCustomer) AS BusinessOperation,
	|	DocumentData.CompensationMethod AS CompensationMethod,
	|	DocumentData.PaymentID AS PaymentID,
	|	&Ref AS DocumentBasis,
	|	DocumentData.CustomerContract AS CustomerContract,
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsViaCommissionAgent)
	|			AND DocumentData.Contract.ConductARAPAccountingThroughEndCustomers
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS UseContractWithClient
	|FROM
	|	Document.ReturnOfGoodsFromCustomer AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
	|");
	
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhập giấy đề nghị trên cơ sở chứng từ %1';
				|ru = 'Не требуется вводить заявку на основании документа %1';
				|en = 'Generation of request from base document %1 is not required'; fa = 'Generation of request from base document %1 is not required';
				|it = 'Non è necessario immettere la richiesta in base al documento %1';
				|pl = 'Nie jest wymagane wprowadzanie wniosku na podstawie dokumentu %1';
				|tr = '%1belgesine dayalı bir talep girmeye gerek yok'"),
			DocumentBasis);
		Raise Text;
	Else
		
		FillingData = New Structure;
		For Each Column In QueryResult.Columns Do
			FillingData.Insert(Column.Name);
		EndDo;
		
		Selection = QueryResult.Select();
		Selection.Next();
		
		FillPropertyValues(FillingData, Selection);
		
		ARAPObjects = New Array;
		If Selection.CompensationMethod = Enums.CompensationMethodsForReturnsOfGoods.ReturnCash Then
			ARAPObjects.Add(DocumentBasis);
		Else
			ARAPObjects.Add(Undefined);
		EndIf;
		If ValueIsFilled(Selection.RequestForReturnOfGoodsFromCustomer) Then
			ARAPObjects.Add(Selection.RequestForReturnOfGoodsFromCustomer);
		EndIf;
		If Selection.UseContractWithClient Then
			ARAPObjects.Add(Selection.CustomerContract);
		Else
			ARAPObjects.Add(Selection.Contract);
		EndIf;
		
		ARAPAccountingARAPDetailsFillingIn.FillInDecryptionOfPaymentForReturnOfGoodsFromClient(
			ARAPObjects,
			FillingData.Organization,
			FillingData.Currency,
			FillingData.Sum,
			FillingData.Partner,
			ARAPDetails);
	EndIf;
	
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure

Procedure FillInRequestForReturnOfGoodsFromClient(Val DocumentBasis, FillingData)
	
	QueryText = "
	|SELECT
	|	CASE WHEN DocumentData.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.BankAccount.Owner
	|	WHEN DocumentData.CashAccount <> VALUE(Catalog.CashAccounts.EmptyRef) THEN
	|		DocumentData.CashAccount.Owner
	|	ELSE
	|		DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.Partner         AS Partner,
	|	DocumentData.Priority       AS Priority,
	|	DocumentData.Counterparty      AS Counterparty,
	|	&ARAPObject                 AS ARAPObject,
	|	DocumentData.Currency          AS Currency,
	|	DocumentData.Currency          AS ARAPCurrency,
	|	DocumentData.ARAPObjectSettings AS ARAPObjectSettings,
	|	DocumentData.DocumentAmount - DocumentData.ReplacementAmount AS Sum,
	|	DocumentData.DocumentAmount - DocumentData.ReplacementAmount AS AmountARAP,
	|	NOT DocumentData.Posted     AS ThereAreErrorsPosted,
	|	DocumentData.Status          AS DocumentStatus,
	|
	|	VALUE(Enum.BusinessTransactions.RefundToCustomer) AS BusinessOperation,
	|	&Ref AS DocumentBasis,
	|
	|	CASE WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromRetailCustomer) THEN
	|		FALSE
	|	ELSE
	|		TRUE
	|	END AS PaymentMethodBankAccount,
	|
	|	CASE WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromRetailCustomer) THEN
	|		VALUE(Enum.PaymentForms.CashAccountPayment_)
	|	ELSE
	|		UNDEFINED
	|	END AS PaymentMethodOfPaymentRequest,
	|	UNDEFINED AS CashAccount,
	|	DocumentData.BankAccount AS BankAccount
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Ref", DocumentBasis);
	
	If DocumentBasis.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts Then
		FoundationAgreement = Common.ObjectAttributeValue(DocumentBasis, "Contract");
		BasisOfCalculations = ARAPObjectsServer.GetCalculationObjectFromLink(FoundationAgreement);
	Else
		BasisOfCalculations = ARAPObjectsServer.GetCalculationObjectFromLink(DocumentBasis);
	EndIf;
	
	Query.SetParameter("ARAPObject", BasisOfCalculations);
	
	QueryResult = Query.Execute();
	
	FillingData = New Structure;
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult.Select();
	If Selection.Next() Then
		
		Documents.RequestForReturnOfGoodsFromCustomer.CheckPossibilityOfEnteringBasedOn(
			Selection.DocumentBasis,
			Selection.DocumentStatus,
			Selection.ThereAreErrorsPosted,
			True);
		
		FillPropertyValues(FillingData, Selection);
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(FillingData.PaymentMethodOfPaymentRequest, FillingData);
		
		If Selection.ARAPObjectSettings = Enums.ARAPObjectSettings.ByOrders Then
			
			ARAPObjects = New Array;
			ARAPObjects.Add(DocumentBasis);
			
			ARAPAccountingARAPDetailsFillingIn.FillInDecryptionOfPaymentForReturnOfGoodsFromClient(
				ARAPObjects,
				FillingData.Organization,
				FillingData.Currency,
				FillingData.Sum,
				FillingData.Partner,
				ARAPDetails);
		Else
			NewRow = ARAPDetails.Add();
			FillPropertyValues(NewRow, Selection);
		EndIf;
		
		DocumentAmount = ARAPDetails.Total("Sum");
	EndIf;
	
EndProcedure

Procedure InformationOnReceiptOfGoodsServices(Val DocumentBasis, FillingData)
	
	Query = New Query("
	|SELECT
	|	CASE WHEN DocumentData.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.CompanyBankAccount.Owner
	|	ELSE
	|		DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.Department AS Department,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	ISNULL(DocumentData.Contract.PaymentsAsPer275FZ, FALSE) AS PaymentsAsPer275FZ,
	|	ISNULL(DocumentData.Contract.ContractWithSDOParticipant, FALSE) AS ContractWithSDOParticipant,
	|	ISNULL(DocumentData.Contract.PaymentOfExpensesAccordingToTariffsThatAreASubjectToStateRegulation, FALSE) AS PaymentOfExpensesAccordingToTariffsThatAreASubjectToStateRegulation,
	|	DocumentData.CompanyBankAccount AS BankAccount,
	|	DocumentData.CounterpartyBankAccount AS CounterpartyBankAccount,
	|	UNDEFINED AS CashAccount,
	|
	|	ISNULL(ARAPObjects.Ref, VALUE(Catalog.ARAPObjects.EmptyRef)) AS ARAPObject,
	|
	|	CASE WHEN DocumentData.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.CompanyBankAccount.CashCurrency
	|	ELSE
	|		DocumentData.Currency
	|	END AS Currency,
	|
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.AmountARAP AS AmountARAP,
	|	DocumentData.DocumentAmount AS Sum,
	|	DocumentData.PaymentMethod AS PaymentMethodOfPaymentRequest,
	|
	|	CASE WHEN DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.CashAccountPayment_) THEN
	| 		TRUE
	|	ELSE
	|		FALSE
	|	END AS PaymentMethodCash,
	|
	|	CASE WHEN DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.BankAccountPayment)
	|			OR DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.InstantPayments)THEN
	| 		TRUE
	|	ELSE
	|		FALSE
	|	END AS PaymentMethodBankAccount,
	|
	|	VALUE(Enum.BusinessTransactions.PaymentToVendor) AS BusinessOperation,
	|	DocumentData.OperationWithSelfEmployedPerson AS OperationWithSelfEmployedPerson,
	|	DocumentData.PaymentID AS PaymentID,
	|	&Ref AS DocumentBasis
	|FROM
	|	Document.VendorInvoice AS DocumentData
	|		LEFT JOIN Document.VendorInvoice.PaymentScheduleSteps AS PaymentSteps
	|			ON DocumentData.Ref = PaymentSteps.Ref
	|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
	|			ON CASE WHEN DocumentData.PurchaseOrder = VALUE(Document.PurchaseOrder.EmptyRef)
	|					THEN &Ref
	|					ELSE DocumentData.PurchaseOrder
	|				END = ARAPObjects.Object
	|				AND NOT ARAPObjects.DeletionMark
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND (DocumentData.BusinessOperation IN (&BusinessTransactionsPurchasingFromSupplier)
	|			OR DocumentData.BusinessOperation IN (&BusinessTransactionsImportPurchase)
	|			OR DocumentData.BusinessOperation IN (&BusinessTransactionsProcurementInEAEUCountries)
	|			OR DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromVendorLocal))
	|GROUP BY
	|	DocumentData.Ref,
	|	ARAPObjects.Ref
	|");
	
	Query.SetParameter("Ref", DocumentBasis);	
	Query.SetParameter("BusinessTransactionsPurchasingFromSupplier",
		PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.PurchaseFromSupplier));
	Query.SetParameter("BusinessTransactionsImportPurchase",
		PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.PurchaseByImport));
	Query.SetParameter("BusinessTransactionsProcurementInEAEUCountries",
		PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.ImportFromEAEU));
	
	QueryResult = Query.Execute();
	FillInDetailsBasedOnRequestResult(DocumentBasis, QueryResult, FillingData,, 0);
	
EndProcedure
Procedure FillInOnReceiptOfRentalServices(Val DocumentBasis, FillingData)
	
	QueryText = Documents.ReceivingLeaseServices.GetTextToFillInBasedOn();
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	FillInDetailsBasedOnRequestResult(DocumentBasis, QueryResult, FillingData,, 0);
	Documents.ReceivingLeaseServices.FillInTranscriptOfReceiptOfRentalServices(ThisObject, QueryResult, FillingData);

EndProcedure
Procedure IncomeFromServicesAndNonCurrentAssets(Val DocumentBasis, FillingData)
	
	Query = New Query("
	|SELECT
	|	CASE WHEN DocumentData.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.CompanyBankAccount.Owner
	|	ELSE
	|		DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.Department AS Department,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	ISNULL(ARAPObjects.Ref, VALUE(Catalog.ARAPObjects.EmptyRef)) AS ARAPObject,
	|	DocumentData.CompanyBankAccount AS BankAccount,
	|	DocumentData.CounterpartyBankAccount AS CounterpartyBankAccount,
	|	UNDEFINED AS CashAccount,
	|
	|	CASE WHEN DocumentData.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.CompanyBankAccount.CashCurrency
	|	ELSE
	|		DocumentData.Currency
	|	END AS Currency,
	|
	|	DocumentData.PaymentDate AS RequiredPaymentDate,
	|	DocumentData.PaymentMethod AS PaymentMethodOfPaymentRequest,
	|
	|	CASE WHEN DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.CashAccountPayment_) THEN
	| 		TRUE
	|	ELSE
	|		FALSE
	|	END AS PaymentMethodCash,
	|
	|	CASE WHEN DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.BankAccountPayment)
	|			OR DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.InstantPayments) THEN
	| 		TRUE
	|	ELSE
	|		FALSE
	|	END AS PaymentMethodBankAccount,
	|
	|	VALUE(Enum.BusinessTransactions.PaymentToVendor) AS BusinessOperation,
	|	DocumentData.OperationWithSelfEmployedPerson AS OperationWithSelfEmployedPerson,
	|	DocumentData.PaymentID AS PaymentID,
	|	&Ref AS DocumentBasis
	|FROM
	|	Document.VendorInvoiceServicesAndAssets AS DocumentData
	|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
	|			ON &Ref = ARAPObjects.Object
	|			AND NOT ARAPObjects.DeletionMark
	|WHERE
	|	DocumentData.Ref = &Ref
	|");
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	FillInDetailsBasedOnRequestResult(DocumentBasis, QueryResult, FillingData);
	
EndProcedure

Procedure FillInReportToCommittee(Val DocumentBasis, FillingData)
	
	Query = New Query("
	|SELECT
	|	CASE WHEN DocumentData.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.BankAccount.Owner
	|	WHEN DocumentData.CashAccount <> VALUE(Catalog.CashAccounts.EmptyRef) THEN
	|		DocumentData.CashAccount.Owner
	|	ELSE
	|		DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.Currency AS ARAPCurrency,
	|	DocumentData.Department AS Department,
	|
	|	CASE WHEN DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.CashAccountPayment_) THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS PaymentMethodCash,
	|
	|	CASE WHEN DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.BankAccountPayment)
	|			OR DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.InstantPayments) THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS PaymentMethodBankAccount,
	|	DocumentData.PaymentMethod AS PaymentMethodOfPaymentRequest,
	|	DocumentData.BankAccount AS BankAccount,
	|	DocumentData.CashAccount AS CashAccount,
	|	DocumentData.Contract.CounterpartyBankAccount AS CounterpartyBankAccount,
	|	DocumentData.PaymentID AS PaymentID,
	|
	|	VALUE(Enum.BusinessTransactions.PaymentToVendor)  AS BusinessOperation,
	|	&Ref AS DocumentBasis
	|FROM
	|	Document.ConsignmentReportToVendor AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|");
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	FillInDetailsBasedOnRequestResult(DocumentBasis, QueryResult, FillingData);
	
EndProcedure

Procedure FillInReportToCommitteeAboutWriteOff(Val DocumentBasis, FillingData)
	
	Query = New Query("
	|SELECT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.Currency AS ARAPCurrency,
	|	DocumentData.Department AS Department,
	|
	|	CASE WHEN DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.CashAccountPayment_) THEN
	| 		TRUE
	|	ELSE
	|		FALSE
	|	END AS PaymentMethodCash,
	|
	|	CASE WHEN DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.BankAccountPayment)
	|			OR DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.InstantPayments) THEN
	| 		TRUE
	|	ELSE
	|		FALSE
	|	END AS PaymentMethodBankAccount,
	|	DocumentData.PaymentMethod AS PaymentMethodOfPaymentRequest,
	|	UNDEFINED AS BankAccount,
	|	UNDEFINED AS CashAccount,
	|	DocumentData.Contract.CounterpartyBankAccount AS CounterpartyBankAccount,
	|	DocumentData.PaymentID AS PaymentID,
	|
	|	VALUE(Enum.BusinessTransactions.PaymentToVendor) AS BusinessOperation,
	|	&Ref AS DocumentBasis
	|FROM
	|	Document.PurchaseInvoiceConsignmentStockLost AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|");
	
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	FillInDetailsBasedOnRequestResult(DocumentBasis, QueryResult,FillingData);
	
EndProcedure

Procedure FillInReportOfCommissionAgent(Val DocumentBasis, FillingData)
	
	QueryText = "
	|SELECT
	|	CASE WHEN DocumentData.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.BankAccount.Owner
	|	WHEN DocumentData.CashAccount <> VALUE(Catalog.CashAccounts.EmptyRef) THEN
	|		DocumentData.CashAccount.Owner
	|	ELSE
	|		DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.Currency AS ARAPCurrency,
	|	DocumentData.Department AS Department,
	|	DocumentData.PaymentDate AS RequiredPaymentDate,
	|	DocumentData.PaymentMethod AS PaymentMethodOfPaymentRequest,
	|
	|	CASE WHEN DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.CashAccountPayment_) THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS PaymentMethodCash,
	|
	|	CASE WHEN DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.BankAccountPayment)
	|			OR DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.InstantPayments) THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS PaymentMethodBankAccount,
	|
	|	DocumentData.BankAccount AS BankAccount,
	|	DocumentData.CashAccount AS CashAccount,
	|
	|	VALUE(Enum.BusinessTransactions.PaymentToVendor) AS BusinessOperation,
	|	DocumentData.CommissionAmount AS Sum,
	|	&Ref AS DocumentBasis
	|FROM
	|	Document.ConsignmentReportFromCustomer AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.CommissionAmount > 0
	|	AND NOT DocumentData.KeepCommissionFee
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.Currency AS ARAPCurrency,
	|	DocumentData.Department AS Department,
	|	DocumentData.PaymentDate AS RequiredPaymentDate,
	|	DocumentData.PaymentMethod AS PaymentMethodOfPaymentRequest,
	|
	|	CASE WHEN DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.CashAccountPayment_) THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS PaymentMethodCash,
	|
	|	CASE WHEN DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.BankAccountPayment)
	|			OR DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.InstantPayments) THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS PaymentMethodBankAccount,
	|
	|	UNDEFINED AS BankAccount,
	|	UNDEFINED AS CashAccount,
	|
	|	VALUE(Enum.BusinessTransactions.RefundToCustomer) AS BusinessOperation,
	|	-DocumentData.DocumentAmount AS Sum,
	|	&Ref AS DocumentBasis
	|FROM
	|	Document.ConsignmentReportFromCustomer AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.DocumentAmount < 0
	|";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhập giấy đề nghị trên cơ sở chứng từ %1';
				|ru = 'Не требуется вводить заявку на основании документа %1';
				|en = 'Generation of request from base document %1 is not required'; fa = 'Generation of request from base document %1 is not required';
				|it = 'Non è necessario immettere la richiesta in base al documento %1';
				|pl = 'Nie jest wymagane wprowadzanie wniosku na podstawie dokumentu %1';
				|tr = '%1belgesine dayalı bir talep girmeye gerek yok'"),
			DocumentBasis);
		Raise Text;
	Else
	
		FillingData = New Structure;
		For Each Column In QueryResult.Columns Do
			FillingData.Insert(Column.Name);
		EndDo;
	
		Selection = QueryResult.Select();
		Selection.Next();
		
		FillPropertyValues(FillingData, Selection);
		
		If Not ValueIsFilled(FillingData.PaymentMethodOfPaymentRequest) Then
			FillingData.PaymentMethodCash = True;
			FillingData.PaymentMethodBankAccount = True;
		EndIf;
		
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(FillingData.PaymentMethodOfPaymentRequest, FillingData);
		
		If Selection.BusinessOperation = Enums.BusinessTransactions.RefundToCustomer Then
			ARAPObjects = New Array;
			ARAPObjects.Add(DocumentBasis);
			ARAPObjects.Add(Selection.Contract);
			ARAPAccountingARAPDetailsFillingIn.FillInDecryptionOfPaymentForReturnOfGoodsFromClient(
				ARAPObjects,
				FillingData.Organization,
				FillingData.Currency,
				Selection.Sum,
				FillingData.Partner,
				ARAPDetails);
		Else
			ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfOrderPaymentToSupplier(
				DocumentBasis,
				Selection.Contract,
				FillingData.Currency,
				0, // AmountToPay
				ARAPDetails,
				RequiredPaymentDate);
		EndIf;
		DocumentAmount = ARAPDetails.Total("Sum");
	EndIf;
	
EndProcedure

Procedure InstructionsForTransferOfGoods(Val DocumentBasis, FillingData)
	
	QueryText = "
	|SELECT
	|	DocumentData.CompanyRecipient AS Organization,
	|	DocumentData.Organization AS CompanyRecipient,
	|	UNDEFINED AS Counterparty,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.Department AS Department,
	|	DocumentData.PaymentDate AS RequiredPaymentDate,
	|	DocumentData.PaymentMethod AS PaymentMethodOfPaymentRequest,
	|
	|	CASE WHEN DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.CashAccountPayment_) THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS PaymentMethodCash,
	|
	|	CASE WHEN DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.BankAccountPayment)
	|			OR DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.InstantPayments) THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS PaymentMethodBankAccount,
	|
	|	DocumentData.RecipientCompanyBankAccount AS BankAccount,
	|	DocumentData.CompanyBankAccount AS BankAccountBeneficiary,
	|	UNDEFINED AS CounterpartyBankAccount,
	|	UNDEFINED AS CashAccount,
	|	UNDEFINED AS CashAccountRecipient,
	|	DocumentData.PaymentID AS PaymentID,
	|
	|	VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany) AS BusinessOperation,
	|
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|	&Ref AS DocumentBasis
	|FROM
	|	Document.CustomerInvoiceIntercompany AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany)
	|	AND NOT DocumentData.ARAPAccountingViaSeparateCounterparty
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.CompanyRecipient AS Organization,
	|	UNDEFINED AS CompanyRecipient,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.Department AS Department,
	|	DocumentData.PaymentDate AS RequiredPaymentDate,
	|	DocumentData.PaymentMethod AS PaymentMethodOfPaymentRequest,
	|
	|	CASE WHEN DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.CashAccountPayment_) THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS PaymentMethodCash,
	|
	|	CASE WHEN DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.BankAccountPayment)
	|			OR DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.InstantPayments) THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS PaymentMethodBankAccount,
	|
	|	DocumentData.RecipientCompanyBankAccount AS BankAccount,
	|	UNDEFINED AS BankAccountBeneficiary,
	|	DocumentData.CounterpartyBankAccount AS CounterpartyBankAccount,
	|	UNDEFINED AS CashAccount,
	|	UNDEFINED AS CashAccountRecipient,
	|	DocumentData.PaymentID AS PaymentID,
	|
	|	VALUE(Enum.BusinessTransactions.PaymentToVendor) AS BusinessOperation,
	|
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|	&Ref AS DocumentBasis
	|FROM
	|	Document.CustomerInvoiceIntercompany AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany)
	|	AND DocumentData.ARAPAccountingViaSeparateCounterparty
	|";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Không cần nhập giấy đề nghị thanh toán trên cơ sở chứng từ %1';
			|ru = 'Не требуется вводить заявку на расходование денежных средств на основании документа %1';
			|en = 'Entering payment request on basis of document %1 is not required'; fa = 'Entering payment request on basis of document %1 is not required';
			|it = 'Non è necessario immettere la richiesta di spesa di fondi monetari in base al documento %1';
			|pl = 'Nie jest wymagane wprowadzanie wniosku o wydatkowanie środków pieniężnych na podstawie dokumentu %1';
			|tr = '%1belgesine dayalı bir ödeme talebi girmeye gerek yok '"),
		DocumentBasis);
		Raise Text;
	Else
		FillingData = New Structure;
		For Each Column In QueryResult.Columns Do
			FillingData.Insert(Column.Name);
		EndDo;
		
		Selection = QueryResult.Select();
		If Selection.Next() Then
			FillPropertyValues(FillingData, Selection);
			
			If Not ValueIsFilled(FillingData.PaymentMethodOfPaymentRequest) Then
				FillingData.PaymentMethodCash = True;
				FillingData.PaymentMethodBankAccount = True;
			EndIf;
			
			CashServer.FillInDetailsOfDocumentOnFormOfPayment(
				FillingData.PaymentMethodOfPaymentRequest,
				FillingData);
			
			ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfOrderPaymentToSupplier(
				DocumentBasis,
				Undefined, // Contract
				FillingData.Currency,
				0, // AmountToPay
				ARAPDetails,
				RequiredPaymentDate);
			
			DocumentAmount = ARAPDetails.Total("Sum");
		EndIf;
	EndIf;
	
EndProcedure

Procedure FillInGiverReportBetweenCompanies(Val DocumentBasis, FillingData)
	
	QueryText = "
	|SELECT
	|	DocumentData.MaterialProvider AS Organization,
	|	DocumentData.Organization AS CompanyRecipient,
	|	UNDEFINED AS Counterparty,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.Department AS Department,
	|	DocumentData.PaymentDate AS RequiredPaymentDate,
	|	DocumentData.PaymentMethod AS PaymentMethodOfPaymentRequest,
	|
	|	CASE
	|		WHEN DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.CashAccountPayment_)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS PaymentMethodCash,
	|
	|	CASE
	|		WHEN DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.BankAccountPayment)
	|			OR DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.InstantPayments)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS PaymentMethodBankAccount,
	|
	|	DocumentData.MaterialProviderAccount AS BankAccount,
	|	DocumentData.SubcontractorAccount AS BankAccountBeneficiary,
	|	UNDEFINED AS CounterpartyBankAccount,
	|	UNDEFINED AS CashAccount,
	|	UNDEFINED AS CashAccountRecipient,
	|
	|	VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany) AS BusinessOperation,
	|
	|	DocumentData.DocumentAmount      AS DocumentAmount,
	|	ReverseAttributes.Ref IS NOT NULL AS IntroducedByReverse,
	|	&Ref AS DocumentBasis
	|FROM
	|	Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany AS DocumentData
	|	
	|	LEFT JOIN Document.ReversingEntry AS ReverseAttributes
	|	ON ReverseAttributes.ReversedDocument = DocumentData.Ref
	|	AND ReverseAttributes.Posted
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredIntercompany)
	|";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Text =
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không cần nhập giấy đề nghị thanh toán trên cơ sở chứng từ %1';
					|ru = 'Не требуется вводить заявку на расходование денежных средств на основании документа %1';
					|en = 'Entering payment request on basis of document %1 is not required'; fa = 'Entering payment request on basis of document %1 is not required';
					|it = 'Non è necessario immettere la richiesta di spesa di fondi monetari in base al documento %1';
					|pl = 'Nie jest wymagane wprowadzanie wniosku o wydatkowanie środków pieniężnych na podstawie dokumentu %1';
					|tr = '%1belgesine dayalı bir ödeme talebi girmeye gerek yok '"),
				DocumentBasis);
		Raise Text;
	Else
		
		Selection = QueryResult.Select();
		If Selection.Next() Then
			
			If Selection.IntroducedByReverse Then
				Text =
					StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Theo chứng từ đã tạo đảo ngược. Không thể nhập giấy đề nghị chi tiền.';
							|ru = 'По документу оформлено сторно. Ввод заявки на расходования денежных средств невозможен.';
							|en = 'Storno is registered for the document. Cannot generate a payment request.'; fa = 'Storno is registered for the document. Cannot generate a payment request.';
							|it = 'По документу оформлено сторно. Ввод заявки на расходования денежных средств невозможен.';
							|pl = 'Storno is registered for the document. Cannot generate a payment request.';
							|tr = 'Belgeye göre iptal düzenlendi. Ödeme talebi girişi mümkün değildir.'"),
						DocumentBasis);
				Raise Text;
			EndIf;
			
			FillingData = New Structure;
			For Each Column In QueryResult.Columns Do
				FillingData.Insert(Column.Name);
			EndDo;
			
			FillPropertyValues(FillingData, Selection);
			
			If Not ValueIsFilled(FillingData.PaymentMethodOfPaymentRequest) Then
				FillingData.PaymentMethodCash = True;
				FillingData.PaymentMethodBankAccount = True;
			EndIf;
			
			CashServer.FillInDetailsOfDocumentOnFormOfPayment(
				FillingData.PaymentMethodOfPaymentRequest,
				FillingData);
			
			ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount();
			ParametersOfAccount.Organization = FillingData.CompanyRecipient;
			ParametersOfAccount.Currency = FillingData.Currency;
			BankAccountBeneficiary =
				Catalogs.CompaniesBankAccounts.GetDefaultBankAccount(ParametersOfAccount);
			ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfOrderPaymentToSupplier(
				DocumentBasis,
				Undefined, // Contract
				FillingData.Currency,
				0, // AmountToPay
				ARAPDetails,
				RequiredPaymentDate);
			
			DocumentAmount = ARAPDetails.Total("Sum");
			
		EndIf;
		
	EndIf;
	
EndProcedure
Procedure FillInCommissionReport(Val DocumentBasis, FillingData, AmountDue = 0, Remuneration = False)
	
	QueryText = "
	|SELECT
	|	DocumentData.Organization AS CompanyRecipient,
	|	DocumentData.Consignee AS Organization,
	|	UNDEFINED AS Counterparty,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.Currency AS ARAPCurrency,
	|	DocumentData.Department AS Department,
	|	DocumentData.PaymentDate AS RequiredPaymentDate,
	|	DocumentData.PaymentMethod AS PaymentMethodOfPaymentRequest,
	|
	|	DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.CashAccountPayment_) AS PaymentMethodCash,
	|	DocumentData.PaymentMethod IN (VALUE(Enum.PaymentForms.BankAccountPayment), VALUE(Enum.PaymentForms.InstantPayments)) AS PaymentMethodBankAccount,
	|
	|	DocumentData.Contract.BankAccountOfBeneficiary AS BankAccount,
	|	DocumentData.Contract.BankAccount AS BankAccountBeneficiary,
	|	UNDEFINED AS CashAccount,
	|
	|	VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany) AS BusinessOperation,
	|
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|	&Ref AS DocumentBasis
	|FROM
	|	DocumentName AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND NOT DocumentData.ARAPAccountingViaSeparateCounterparty
	|	AND DocumentData.DocumentAmount > 0
	|	AND NOT &Remuneration
	|
	|UNION ALL
	|
	|SELECT
	|	UNDEFINED AS CompanyRecipient,
	|	DocumentData.Consignee AS Organization,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.Currency AS ARAPCurrency,
	|	DocumentData.Department AS Department,
	|	DocumentData.PaymentDate AS RequiredPaymentDate,
	|	DocumentData.PaymentMethod AS PaymentMethodOfPaymentRequest,
	|
	|	DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.CashAccountPayment_) AS PaymentMethodCash,
	|	DocumentData.PaymentMethod IN (VALUE(Enum.PaymentForms.BankAccountPayment), VALUE(Enum.PaymentForms.InstantPayments)) AS PaymentMethodBankAccount,
	|
	|	UNDEFINED AS BankAccount,
	|	UNDEFINED AS BankAccountBeneficiary,
	|	UNDEFINED AS CashAccount,
	|
	|	VALUE(Enum.BusinessTransactions.PaymentToVendor) AS BusinessOperation,
	|
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|	&Ref AS DocumentBasis
	|FROM
	|	DocumentName AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.ARAPAccountingViaSeparateCounterparty
	|	AND DocumentData.DocumentAmount > 0
	|	AND NOT &Remuneration
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Consignee AS CompanyRecipient,
	|	DocumentData.Organization AS Organization,
	|	UNDEFINED AS Counterparty,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.Currency AS ARAPCurrency,
	|	DocumentData.Department AS Department,
	|	DocumentData.PaymentDate AS RequiredPaymentDate,
	|	DocumentData.PaymentMethod AS PaymentMethodOfPaymentRequest,
	|
	|	DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.CashAccountPayment_) AS PaymentMethodCash,
	|	DocumentData.PaymentMethod IN (VALUE(Enum.PaymentForms.BankAccountPayment), VALUE(Enum.PaymentForms.InstantPayments)) AS PaymentMethodBankAccount,
	|
	|	DocumentData.Contract.BankAccount AS BankAccount,
	|	DocumentData.Contract.BankAccountOfBeneficiary AS BankAccountBeneficiary,
	|	UNDEFINED AS CashAccount,
	|
	|	VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany) AS BusinessOperation,
	|
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|	&Ref AS DocumentBasis
	|FROM
	|	DocumentName AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND NOT DocumentData.ARAPAccountingViaSeparateCounterparty
	|	AND DocumentData.DocumentAmount > 0
	|	AND &Remuneration
	|
	|UNION ALL
	|
	|SELECT
	|	UNDEFINED AS CompanyRecipient,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.Currency AS ARAPCurrency,
	|	DocumentData.Department AS Department,
	|	DocumentData.PaymentDate AS RequiredPaymentDate,
	|	DocumentData.PaymentMethod AS PaymentMethodOfPaymentRequest,
	|
	|	DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.CashAccountPayment_) AS PaymentMethodCash,
	|	DocumentData.PaymentMethod IN (VALUE(Enum.PaymentForms.BankAccountPayment), VALUE(Enum.PaymentForms.InstantPayments)) AS PaymentMethodBankAccount,
	|
	|	UNDEFINED AS BankAccount,
	|	UNDEFINED AS BankAccountBeneficiary,
	|	UNDEFINED AS CashAccount,
	|
	|	VALUE(Enum.BusinessTransactions.PaymentToVendor) AS BusinessOperation,
	|
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|	&Ref AS DocumentBasis
	|FROM
	|	DocumentName AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.ARAPAccountingViaSeparateCounterparty
	|	AND DocumentData.DocumentAmount > 0
	|	AND &Remuneration
	|";
	
	NameOfFoundationDocument = DocumentBasis.Metadata().FullName();
	QueryText = StrReplace(QueryText, "DocumentName", NameOfFoundationDocument);
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Ref", DocumentBasis);
	Query.SetParameter("Remuneration", Remuneration);
	
	QueryResult = Query.Execute();
	
	FillingData = New Structure;
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult.Select();
	If Selection.Next() Then
		FillPropertyValues(FillingData, Selection);
		
		If Not ValueIsFilled(FillingData.PaymentMethodOfPaymentRequest) Then
			FillingData.PaymentMethodCash = True;
			FillingData.PaymentMethodBankAccount = True;
		EndIf;
		
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(FillingData.PaymentMethodOfPaymentRequest, FillingData);
		
		ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfOrderPaymentToSupplier(
			DocumentBasis,
			Undefined, // Contract
			FillingData.Currency,
			0, // AmountToPay
			ARAPDetails,
			RequiredPaymentDate,
			FillingData.Organization);
			
		FillingData.Insert("CashFlowItem", 
			Catalogs.CashFlowReportItems.CashFlowItemForBusinessTransaction(FillingData.BusinessOperation));
		
		If ValueIsFilled(FillingData.CashFlowItem) Then
			For Each Page1 In ARAPDetails Do
				Page1.CashFlowItem = FillingData.CashFlowItem;
			EndDo;
		EndIf;
		
		FillingData.DocumentAmount = ARAPDetails.Total("Sum");
	Else
		Raise
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Giấy đề nghị thanh toán không cần thiết đối với chứng từ %1';
					|ru = 'Заявка на расходование ДС не требуется для документа %1';
					|en = 'Payment request is not required for document %1'; fa = 'Payment request is not required for document %1';
					|it = 'La Richiesta di spesa di mezzi per il documento %1 non è necessaria';
					|pl = 'Wniosek o wydatkowanie środków pieniężnych nie jest wymagane dla dokumentu %1';
					|tr = '%1belgesi için ödeme talebi gerekli değildir'"), DocumentBasis);
	EndIf;
	
EndProcedure

Procedure FillInImportCustomsDeclaration(Val DocumentBasis, FillingData)
	// Fill in the data of the document header.
	Query = New Query("
	|SELECT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.CompanyBankAccount AS BankAccount,
	|	DocumentData.CounterpartyBankAccount AS CounterpartyBankAccount,
	|	UNDEFINED AS CashAccount,
	|
	|	CASE WHEN DocumentData.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
	|		THEN DocumentData.CompanyBankAccount.CashCurrency ELSE DocumentData.Currency END AS Currency,
	|
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.AmountARAP AS AmountARAP,
	|	DocumentData.DocumentAmount AS Sum,
	|	DocumentData.PaymentDate AS RequiredPaymentDate,
	|	DocumentData.PaymentID AS PaymentID,
	|	DocumentData.PaymentMethod AS PaymentMethodOfPaymentRequest,
	|	CASE WHEN DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.CashAccountPayment_)
	|		THEN TRUE ELSE FALSE END AS PaymentMethodCash,
	|	CASE WHEN DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.BankAccountPayment)
	|				OR DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.InstantPayments)
	|		THEN TRUE ELSE FALSE END AS PaymentMethodBankAccount,
	|
	|	CASE WHEN DocumentData.RegistrationOption = VALUE(Enum.BusinessTransactions.RegisterCCDUnassisted)
	|		THEN VALUE(Enum.BusinessTransactions.CustomsPayment)
	|		ELSE VALUE(Enum.BusinessTransactions.PaymentToVendor) END AS BusinessOperation,
	|	&Ref AS DocumentBasis
	|FROM
	|	Document.CCDImport AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|");
	Query.SetParameter("Ref", DocumentBasis);
	QueryResult = Query.Execute();
	FillInDetailsBasedOnRequestResult(DocumentBasis, QueryResult, FillingData);
EndProcedure

Procedure RefundAgreementsBetweenOrganizations(Val DocumentBasis, FillingData)
	
	QueryText = "
		|SELECT
		|	DocumentData.CompanyRecipient AS Organization,
		|	(CASE WHEN DocumentData.ARAPAccountingViaSeparateCounterparty
		|		THEN UNDEFINED
		|		ELSE DocumentData.Organization END) AS CompanyRecipient,
		|	(CASE WHEN DocumentData.ARAPAccountingViaSeparateCounterparty
		|		THEN DocumentData.Counterparty
		|		ELSE UNDEFINED END) AS Counterparty,
		|	(CASE WHEN DocumentData.ARAPAccountingViaSeparateCounterparty
		|		THEN DocumentData.Partner
		|		ELSE UNDEFINED END) AS Partner,
		|	ISNULL(ARAPObjects.Ref, VALUE(Catalog.ARAPObjects.EmptyRef)) AS ARAPObject,
		|	DocumentData.ARAPDetails.(ARAPObject) AS ObjectOfDecryptionCalculations,
		|	DATEADD(DocumentData.Date,DAY,
		|			DATEDIFF(DocumentData.DocumentTransfers_.Date,DocumentData.DocumentTransfers_.PaymentDate,DAY)
		|		) AS RequiredPaymentDate,
		|	DocumentData.Currency AS Currency,
		|	DocumentData.Department AS Department,
		|
		|	UNDEFINED AS PaymentMethodOfPaymentRequest,
		|	TRUE AS PaymentMethodCash,
		|	TRUE AS PaymentMethodBankAccount,
		|
		|	DocumentData.RecipientCompanyBankAccount AS BankAccount,
		|	(CASE WHEN DocumentData.ARAPAccountingViaSeparateCounterparty
		|		THEN UNDEFINED ELSE DocumentData.CompanyBankAccount END) AS BankAccountBeneficiary,
		|	(CASE WHEN DocumentData.ARAPAccountingViaSeparateCounterparty
		|		THEN DocumentData.CounterpartyBankAccount ELSE UNDEFINED END) AS CounterpartyBankAccount,
		|	UNDEFINED AS CashAccount,
		|	UNDEFINED AS CashAccountRecipient,
		|	DocumentData.PaymentID AS PaymentID,
		|
		|	(CASE WHEN DocumentData.ARAPAccountingViaSeparateCounterparty
		|		THEN VALUE(Enum.BusinessTransactions.RefundToCustomer)
		|		ELSE VALUE(Enum.BusinessTransactions.RefundToAnotherCompany) END) AS BusinessOperation,
		|
		|	DocumentData.DocumentAmount AS Sum,
		|	&Ref AS DocumentBasis
		|FROM
		|	Document.IntercompanyGoodsReturn AS DocumentData
		|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
		|			ON DocumentData.DocumentTransfers_ = ARAPObjects.Object
		|				AND NOT ARAPObjects.DeletionMark
		|WHERE
		|	DocumentData.Ref = &Ref
		|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.IntercompanyGoodsReturn)
		|";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhập giấy đề nghị thanh toán trên cơ sở chứng từ %1';
				|ru = 'Не требуется вводить заявку на расходование денежных средств на основании документа %1';
				|en = 'Entering payment request on basis of document %1 is not required'; fa = 'Entering payment request on basis of document %1 is not required';
				|it = 'Non è necessario immettere la richiesta di spesa di fondi monetari in base al documento %1';
				|pl = 'Nie jest wymagane wprowadzanie wniosku o wydatkowanie środków pieniężnych na podstawie dokumentu %1';
				|tr = '%1belgesine dayalı bir ödeme talebi girmeye gerek yok '"),
			DocumentBasis);
		Raise Text;
	Else
		FillingData = New Structure;
		For Each Column In QueryResult.Columns Do
			FillingData.Insert(Column.Name);
		EndDo;
		
		Selection = QueryResult.Select();
		If Selection.Next() Then
			FillPropertyValues(FillingData, Selection);
			
			ARAPObjects = Selection.ObjectOfDecryptionCalculations.Unload().UnloadColumn("ARAPObject"); // Array of references to calculation objects
			ARAPObjects.Add(FillingData.ARAPObject);
			
			CashServer.FillInDetailsOfDocumentOnFormOfPayment(
				FillingData.PaymentMethodOfPaymentRequest,
				FillingData);
			
			ARAPAccountingARAPDetailsFillingIn.FillInDecryptionOfPaymentForReturnOfGoodsFromClient(
				ARAPObjects,
				FillingData.Organization,
				FillingData.Currency,
				Selection.Sum,
				FillingData.Partner, // Partner
				ARAPDetails);
			
			DocumentAmount = ARAPDetails.Total("Sum");
		EndIf;
	EndIf;
	
EndProcedure

Procedure FillInTheContract(Val DocumentBasis, FillingData)
	
	Query = New Query("
	|SELECT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Ref AS Contract,
	|
	|	FALSE AS PaymentMethodCash,
	|	CASE
	|		WHEN DocumentData.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
	|			AND DocumentData.CounterpartyBankAccount <> VALUE(Catalog.CounterpartyBankAccounts.EmptyRef) THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS PaymentMethodBankAccount,
	|	CASE
	|		WHEN DocumentData.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
	|			AND DocumentData.CounterpartyBankAccount <> VALUE(Catalog.CounterpartyBankAccounts.EmptyRef) THEN
	|		VALUE(Enum.PaymentForms.BankAccountPayment)
	|	ELSE
	|		UNDEFINED
	|	END AS PaymentMethodOfPaymentRequest,
	|
	|	DocumentData.BankAccount AS BankAccount,
	|	DocumentData.CounterpartyBankAccount AS CounterpartyBankAccount,
	|
	|	CASE WHEN DocumentData.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.BankAccount.CashCurrency
	|	ELSE
	|		DocumentData.ARAPCurrency
	|	END AS Currency,
	|
	|	CASE 
	|		WHEN DocumentData.ContractType IN (&TypesOfCustomerContracts) THEN
	|		VALUE(Enum.BusinessTransactions.RefundToCustomer)
	|	ELSE
	|		VALUE(Enum.BusinessTransactions.PaymentToVendor)
	|	END AS BusinessOperation,
	|
	|	ISNULL(ARAPObjects.Ref, VALUE(Catalog.ARAPObjects.EmptyRef)) AS ARAPObject,
	|	&Ref AS DocumentBasis,
	|	
	|	DocumentData.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	DocumentData.CashFlowItem AS CashFlowItem,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.Department AS Department,
	|	
	|	DocumentData.PaymentsAsPer275FZ AS PaymentsAsPer275FZ,
	|	DocumentData.ContractWithSDOParticipant AS ContractWithSDOParticipant,
	|	DocumentData.PaymentOfExpensesAccordingToTariffsThatAreASubjectToStateRegulation AS PaymentOfExpensesAccordingToTariffsThatAreASubjectToStateRegulation,
	|	DocumentData.ARAPObjectSettings AS ARAPObjectSettings,
	|	DocumentData.ContractType AS ContractType,
	|	DocumentData.PaymentID AS PaymentID
	|	
	|FROM
	|	Catalog.CounterpartyContracts AS DocumentData
	|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
	|			ON DocumentData.Ref = ARAPObjects.Object
	|			AND NOT ARAPObjects.DeletionMark
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.SaleToCustomer)
	|");
	
	Query.SetParameter("Ref", DocumentBasis);
	Query.SetParameter("TypesOfCustomerContracts", CashServer.TypesOfRefundContracts());
	
	QueryResult = Query.Execute();
	FillInDetailsBasedOnRequestResult(DocumentBasis, QueryResult, FillingData, True);
	
EndProcedure

Procedure FillInUnderLoanDepositAgreement(Val DocumentBasis, FillingData)
	
	CashServer.FillInUnderLoanDepositAgreement(DocumentBasis, FillingData, ARAPDetails, False);
	
	FillingData.Insert("RequiredPaymentDate", CurrentSessionDate());
	FillingData.Insert("PaymentMethodOfPaymentRequest", Enums.PaymentForms.BankAccountPayment);
	FillingData.Insert("Status", Enums.StatusesOfPaymentRequests.NotAgreedUpon);
	
EndProcedure

Procedure FillByArrayOfBases(FillingData, ArrayOfBases)
	
	If ArrayOfBases.Count() Then
		
		FillingData.Insert("RequiredPaymentDate", Max(ArrayOfBases[0].PaymentDate, CurrentSessionDate()));
		FillingData.Insert("CounterpartyBankAccount", ArrayOfBases[0].CounterpartyBankAccount);
		
		FillingData.Insert("PaymentMethodOfPaymentRequest", ArrayOfBases[0].PaymentMethod);
		If FillingData.PaymentMethodOfPaymentRequest = Enums.PaymentForms.BankAccountPayment
			Or FillingData.PaymentMethodOfPaymentRequest = Enums.PaymentForms.InstantPayments Then
			FillingData.Insert("PaymentMethodBankAccount", True);
			FillingData.Insert("PaymentMethodCash", False);
		ElsIf FillingData.PaymentMethodOfPaymentRequest = Enums.PaymentForms.CashAccountPayment_ Then
			FillingData.Insert("PaymentMethodCash", True);
			FillingData.Insert("PaymentMethodBankAccount", False);
		EndIf;
		
		If Metadata.DefinedTypes.ARAPObjectWithVendor.Type.ContainsType(TypeOf(ArrayOfBases[0].PaymentObject))
			Or Metadata.DefinedTypes.ARAPObjectWithCustomer.Type.ContainsType(TypeOf(ArrayOfBases[0].PaymentObject)) Then
			
			For Each BaseString In ArrayOfBases Do
				ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfOrderPaymentToSupplier(
					BaseString.PaymentObject,
					Undefined,
					BaseString.DocumentCurrency,
					BaseString.AmountToPay,
					ARAPDetails,,
					BaseString.Organization);
			EndDo;
		Else
			For Each Basis In ArrayOfBases Do
				NewRow = ARAPDetails.Add();
				FillPropertyValues(NewRow, Basis);
			EndDo;
		EndIf;
		
		DocumentAmount = ARAPDetails.Total("Sum");
	EndIf;
	
EndProcedure

Procedure InitializeDocument(FillingData = Undefined)
	
	If TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("Date")
		And ValueIsFilled(FillingData.Date) Then
		
		Date = FillingData.Date;
	EndIf;
	
	If TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("PaymentMethodOfPaymentRequest")
		And ValueIsFilled(FillingData.PaymentMethodOfPaymentRequest) Then
		
		PaymentMethodCash = (FillingData.PaymentMethodOfPaymentRequest = Enums.PaymentForms.CashAccountPayment_);
		PaymentMethodBankAccount = (FillingData.PaymentMethodOfPaymentRequest = Enums.PaymentForms.BankAccountPayment
			Or FillingData.PaymentMethodOfPaymentRequest = Enums.PaymentForms.InstantPayments);
		MethodOfPaymentPaymentCard = (FillingData.PaymentMethodOfPaymentRequest = Enums.PaymentForms.PaymentCard);
		
	ElsIf ValueIsFilled(PaymentMethodOfPaymentRequest) Then
		
		PaymentMethodCash = (PaymentMethodOfPaymentRequest = Enums.PaymentForms.CashAccountPayment_);
		PaymentMethodBankAccount = (PaymentMethodOfPaymentRequest = Enums.PaymentForms.BankAccountPayment
			Or PaymentMethodOfPaymentRequest = Enums.PaymentForms.InstantPayments);
		MethodOfPaymentPaymentCard = (PaymentMethodOfPaymentRequest = Enums.PaymentForms.PaymentCard);
	EndIf;
	
	If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("Organization") Then
		Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	EndIf;
	
	If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("Currency") Then
		If Not ValueIsFilled(Currency) Then
			Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
		EndIf;
	EndIf;
	
	PaymentPriority = Catalogs.PaymentPriorities.GetDefaultPriority(PaymentPriority);
	
	CashServer.FillInCashFlowItem(
		ThisObject, FillingData, Enums.BusinessTransactions.PaymentToVendor);

	If TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("RequiredPaymentDate")
		And ValueIsFilled(FillingData.RequiredPaymentDate) Then
		
		If FillingData.RequiredPaymentDate < CurrentSessionDate() Then
			FillingData.RequiredPaymentDate = CurrentSessionDate();
		EndIf;
		
	ElsIf ValueIsFilled(RequiredPaymentDate) Then
		
		If RequiredPaymentDate < CurrentSessionDate() Then
			RequiredPaymentDate = CurrentSessionDate();
		EndIf;
	EndIf;
	
	If TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("Currency")
		And ValueIsFilled(FillingData.Currency) Then
		
		CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
		For Each TSRow In ARAPDetails Do
			CourseAndMultiplicity = CashServer.CourseNumeratorAndCourseDenominatorOfMutualSettlements(
				FillingData.Currency, TSRow.ARAPCurrency, CurrencyOfComplianceAccounting, Date, TSRow.ARAPObject, Contract);
			TSRow.ExchangeRateNumeratorOfMutualSettlements = CourseAndMultiplicity.CourseNumerator;
			TSRow.TheExchangeRateIsTheDenominatorOfMutualSettlements = CourseAndMultiplicity.CourseDenominator;
		EndDo;
	Else
		For Each TSRow In ARAPDetails Do
			TSRow.ExchangeRateNumeratorOfMutualSettlements = 1;
			TSRow.TheExchangeRateIsTheDenominatorOfMutualSettlements = 1;
		EndDo;
	EndIf;
	
EndProcedure

Procedure FillDetailsWithDefaultValues() Export
	
	WhoStated = Users.CurrentUser();
	
	PaymentPriority = Catalogs.PaymentPriorities.GetDefaultPriority(Undefined);
	
	If Not ValueIsFilled(PaymentMethodOfPaymentRequest) Then
		PaymentMethodCash = True;
		PaymentMethodBankAccount = True;
	Else
		PaymentMethodCash = (PaymentMethodOfPaymentRequest = Enums.PaymentForms.CashAccountPayment_);
		PaymentMethodBankAccount = (PaymentMethodOfPaymentRequest = Enums.PaymentForms.BankAccountPayment
									Or PaymentMethodOfPaymentRequest = Enums.PaymentForms.InstantPayments);
		MethodOfPaymentPaymentCard = (PaymentMethodOfPaymentRequest = Enums.PaymentForms.PaymentCard);
	EndIf;
	
	ParametersStructure = CashServer.ParametersForFillingOutOrganizationSBankAccount();
	ParametersStructure.Organization = Organization;
	ParametersStructure.Currency      = Currency;
	BankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersStructure, ,
		PaymentMethodOfPaymentRequest);
	
	ParametersStructure = CashServer.DefaultParametersForFillingInCheckout();
	ParametersStructure.Organization = Organization;
	ParametersStructure.PaymentMethod = PaymentMethodOfPaymentRequest;
	ParametersStructure.Currency      = Currency;
	
	CashAccount = SettingsValueCached.GetOrganizationSDefaultSalesRegister(ParametersStructure);
	
	CounterpartyBankAccount =
		Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(Counterparty, Currency);
	PaymentPurposes =
		Catalogs.CounterpartyBankAccounts.GetBankAccountDetails(CounterpartyBankAccount).PurposeText;
	
EndProcedure

Procedure FillInLeaseAgreement(Val DocumentBasis, FillingData)

	Query = New Query("
	|SELECT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Ref AS Contract,
	|
	|	FALSE AS PaymentMethodCash,
	|	CASE
	|		WHEN DocumentData.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
	|			AND DocumentData.CounterpartyBankAccount <> VALUE(Catalog.CounterpartyBankAccounts.EmptyRef) THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS PaymentMethodBankAccount,
	|	CASE
	|		WHEN DocumentData.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
	|			AND DocumentData.CounterpartyBankAccount <> VALUE(Catalog.CounterpartyBankAccounts.EmptyRef) THEN
	|		VALUE(Enum.PaymentForms.BankAccountPayment)
	|	ELSE
	|		UNDEFINED
	|	END AS PaymentMethodOfPaymentRequest,
	|
	|	DocumentData.BankAccount AS BankAccount,
	|	DocumentData.CounterpartyBankAccount AS CounterpartyBankAccount,
	|
	|	CASE WHEN DocumentData.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.BankAccount.CashCurrency
	|	ELSE
	|		DocumentData.ARAPCurrency
	|	END AS Currency,
	|	DocumentData.VATTaxation AS VATTaxation,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|
	|	VALUE(Enum.BusinessTransactions.PaymentToLessor) AS BusinessOperation,
	|	&Ref AS DocumentBasis,
	|	&Ref AS LeaseContracts,
	|	DocumentData.CashFlowItem AS CashFlowItem,
	|	TermsOfLeaseContracts.VATRate AS VATRate
	|	
	|FROM
	|	Catalog.LeaseContract AS DocumentData
	|		LEFT JOIN InformationRegister.TermsOfLeaseContracts.SliceLast(, Contract = &Ref) AS TermsOfLeaseContracts
	|		ON TermsOfLeaseContracts.Contract = &Ref
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|");
	
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	
	FillingData = New Structure;
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult.Select();
	Selection.Next();
	FillPropertyValues(FillingData, Selection);
	
	FillingData.Insert("RequiredPaymentDate");
	
	If Not ValueIsFilled(FillingData.PaymentMethodOfPaymentRequest) Then
		FillingData.PaymentMethodCash = True;
		FillingData.PaymentMethodBankAccount = True;
	EndIf;
	
	CashServer.FillInDetailsOfDocumentOnFormOfPayment(FillingData.PaymentMethodOfPaymentRequest, FillingData);
	
	FillPropertyValues(ARAPDetails.Add(), Selection);
	
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure


Procedure FillInByOrderToProcessor2_5(Val DocumentBasis, FillingData)
	
	Query = New Query("
	|SELECT
	|	CASE WHEN DocumentData.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.BankAccount.Owner
	|	WHEN DocumentData.CashAccount <> VALUE(Catalog.CashAccounts.EmptyRef) THEN
	|		DocumentData.CashAccount.Owner
	|	ELSE
	|		DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.Department AS Department,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Priority AS Priority,
	|	DocumentData.Currency AS ARAPCurrency,
	|
	|	CASE WHEN DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.CashAccountPayment_) THEN
	| 		TRUE
	|	ELSE
	|		FALSE
	|	END AS PaymentMethodCash,
	|
	|	CASE WHEN DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.BankAccountPayment)
	|				OR DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.InstantPayments) THEN
	| 		TRUE
	|	ELSE
	|		FALSE
	|	END AS PaymentMethodBankAccount,
	|	DocumentData.PaymentMethod AS PaymentMethodOfPaymentRequest,
	|
	|	CASE WHEN DocumentData.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.BankAccount
	|	ELSE
	|		DocumentData.Contract.BankAccount
	|	END AS BankAccount,
	|
	|	DocumentData.CashAccount AS CashAccount,
	|	DocumentData.Contract.CounterpartyBankAccount AS CounterpartyBankAccount,
	|	DocumentData.PaymentID AS PaymentID,
	|
	|	CASE WHEN DocumentData.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.BankAccount.CashCurrency
	|	WHEN DocumentData.CashAccount <> VALUE(Catalog.CashAccounts.EmptyRef) THEN
	|		DocumentData.CashAccount.CashCurrency
	|	ELSE
	|		ISNULL(DocumentData.Contract.BankAccount.CashCurrency, DocumentData.Currency)
	|	END AS Currency,
	|
	|	VALUE(Enum.BusinessTransactions.PaymentToVendor) AS BusinessOperation,
	|	&Ref AS DocumentBasis
	|FROM
	|	Document.SubcontractOrder2_5 AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)
	|");
	
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	FillInDetailsBasedOnRequestResult(DocumentBasis, QueryResult, FillingData);
	
EndProcedure


Procedure FillInReportOfProcessor2_5(Val DocumentBasis, FillingData)
	
	Query = New Query("
	|SELECT
	|	CASE WHEN DocumentData.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.CompanyBankAccount.Owner
	|	ELSE
	|		DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.Department AS Department,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Currency AS ARAPCurrency,
	|
	|	CASE WHEN DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.CashAccountPayment_) THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS PaymentMethodCash,
	|
	|	CASE WHEN DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.BankAccountPayment)
	|				OR DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.InstantPayments) THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS PaymentMethodBankAccount,
	|	DocumentData.PaymentMethod AS PaymentMethodOfPaymentRequest,
	|
	|	CASE WHEN DocumentData.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.CompanyBankAccount
	|	ELSE
	|		DocumentData.Contract.BankAccount
	|	END AS BankAccount,
	|
	|	UNDEFINED AS CashAccount,
	|	DocumentData.CounterpartyBankAccount AS CounterpartyBankAccount,
	|	DocumentData.PaymentID AS PaymentID,
	|
	|	CASE WHEN DocumentData.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.CompanyBankAccount.CashCurrency
	|	ELSE
	|		ISNULL(DocumentData.Contract.BankAccount.CashCurrency, DocumentData.Currency)
	|	END AS Currency,
	|
	|	VALUE(Enum.BusinessTransactions.PaymentToVendor) AS BusinessOperation,
	|	&Ref AS DocumentBasis
	|FROM
	|	Document.SubcontractorReport2_5 AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|");
	
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	FillInDetailsBasedOnRequestResult(DocumentBasis, QueryResult, FillingData);
	
EndProcedure
Procedure InstructionsForRedemptionOfGoodsAcceptedForStorage(Val DocumentBasis, FillingData)
	
	Query = New Query("
	|SELECT
	|	CASE WHEN DocumentData.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.CompanyBankAccount.Owner
	|	ELSE
	|		DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.Department AS Department,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.CompanyBankAccount AS BankAccount,
	|	DocumentData.CounterpartyBankAccount AS CounterpartyBankAccount,
	|	UNDEFINED AS CashAccount,
	|
	|	UNDEFINED AS OrderDocument,
	|
	|	CASE WHEN DocumentData.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.CompanyBankAccount.CashCurrency
	|	ELSE
	|		DocumentData.Currency
	|	END AS Currency,
	|
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.AmountARAP AS AmountARAP,
	|	DocumentData.DocumentAmount AS Sum,
	|	DocumentData.PaymentDate AS RequiredPaymentDate,
	|	DocumentData.PaymentID AS PaymentID,
	|	DocumentData.PaymentMethod AS PaymentMethodOfPaymentRequest,
	|
	|	CASE WHEN DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.CashAccountPayment_) THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS PaymentMethodCash,
	|
	|	CASE WHEN DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.BankAccountPayment)
	|				OR DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.InstantPayments) THEN
	| 		TRUE
	|	ELSE
	|		FALSE
	|	END AS PaymentMethodBankAccount,
	|
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.DeliveryForPrincipal)
	|			THEN VALUE(Enum.BusinessTransactions.RefundToCustomer)
	|			ELSE VALUE(Enum.BusinessTransactions.PaymentToVendor)
	|	END AS BusinessOperation,
	|	&Ref AS DocumentBasis
	|FROM
	|	Document.RedemptionOfGoodsFromStorage AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref");
	
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	FillInDetailsBasedOnRequestResult(DocumentBasis, QueryResult, FillingData);
	
EndProcedure

Procedure InstructionsForDebitingGoodsAcceptedForStorage(Val DocumentBasis, FillingData)
	
	Query = New Query("
	|SELECT
	|	CASE WHEN DocumentData.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.CompanyBankAccount.Owner
	|	ELSE
	|		DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.Department AS Department,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.CompanyBankAccount AS BankAccount,
	|	UNDEFINED AS CashAccount,
	|	DocumentData.Contract.CounterpartyBankAccount AS CounterpartyBankAccount,
	|
	|	UNDEFINED AS OrderDocument,
	|
	|	CASE WHEN DocumentData.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.CompanyBankAccount.CashCurrency
	|	ELSE
	|		DocumentData.Currency
	|	END AS Currency,
	|
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.AmountARAP AS AmountARAP,
	|	DocumentData.DocumentAmount AS Sum,
	|	DocumentData.PaymentDate AS RequiredPaymentDate,
	|	DocumentData.PaymentID AS PaymentID,
	|	DocumentData.PaymentMethod AS PaymentMethodOfPaymentRequest,
	|
	|	CASE WHEN DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.CashAccountPayment_) THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS PaymentMethodCash,
	|
	|	CASE WHEN DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.BankAccountPayment)
	|				OR DocumentData.PaymentMethod = VALUE(Enum.PaymentForms.InstantPayments) THEN
	| 		TRUE
	|	ELSE
	|		FALSE
	|	END AS PaymentMethodBankAccount,
	|
	|	CASE
	|		WHEN DocumentData.BusinessOperation IN(
	|				VALUE(Enum.BusinessTransactions.ProviderGoodsWriteOffAsExpenses),
	|				VALUE(Enum.BusinessTransactions.ConsumptionOfGoodsReceivedAsExpenses))
	|			THEN VALUE(Enum.BusinessTransactions.PaymentToVendor)
	|		ELSE VALUE(Enum.BusinessTransactions.RefundToCustomer)
	|	END
	|	AS BusinessOperation,
	|	&Ref AS DocumentBasis
	|FROM
	|	Document.ReportOnVMIAdjustment AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.BusinessOperation IN(
	|		VALUE(Enum.BusinessTransactions.ProviderGoodsWriteOffAsExpenses),
	|		VALUE(Enum.BusinessTransactions.ConsumptionOfGoodsReceivedAsExpenses))
	|");
	
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	FillInDetailsBasedOnRequestResult(DocumentBasis, QueryResult, FillingData);
	
EndProcedure

Procedure FillInOnTheCustomerSOrder(Val DocumentBasis, FillingData)
	
	FillingData = CashServer.GenerateFillInDataForReturningPaymentFromCustomerSOrder(DocumentBasis, ThisObject);
	
	CashServer.FillInTranscriptOfPaymentOnClientSOrder(FillingData, ARAPDetails);
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure

Procedure FillInReceiptCashOrder(Val DocumentBasis, FillingData)
	
	FillingData = CashServer.GenerateFillInDataForReturningPaymentFromIncomingCashOrder(DocumentBasis);
	CashServer.FillInPaymentTranscriptForPaymentDocument(DocumentBasis, FillingData.BusinessOperation, ARAPDetails); 
	
EndProcedure

Procedure InstructionsForReceiptOfNonCashFunds(Val DocumentBasis, FillingData)
	
	FillingData = CashServer.GenerateFillInDataForRefundOfPaymentFromReceiptOfNonCashFunds(DocumentBasis);		
	CashServer.FillInPaymentTranscriptForPaymentDocument(DocumentBasis, FillingData.BusinessOperation, ARAPDetails);
	
EndProcedure

Procedure FillInGiftCertificate(Val DocumentBasis, FillingData)

	GiftCertificate = DocumentBasis;
	If TypeOf(DocumentBasis) = Type("Structure") Then
		If TypeOf(FillingData.GiftCertificate) = Type("Array") Then
			GiftCertificate = FillingData.GiftCertificate[0];
		Else
			GiftCertificate = FillingData.GiftCertificate;
		EndIf;
	EndIf;

	GiftCertificateDetails = GiftCertificatesServerCall.GetGiftCertificateDetails(GiftCertificate);	
	If Not GiftCertificateDetails.GiftCardAccounting25 Then
		Text = NStr("vi = 'Chỉ hỗ trợ giao dịch này đối với các dạng phiếu quà tặng sử dụng để ghi nhận phiếu quà tặng 2.5.';
					|ru = 'Данная операция поддерживается только для видов подарочных сертификатов, использующих учет подарочных сертификатов 2.5.';
					|en = 'This transaction is supported only for gift card kinds that use gift card accounting 2.5.'; fa = 'This transaction is supported only for gift card kinds that use gift card accounting 2.5.';
					|it = 'Questa operazione viene supportata solo per i tipi di buoni regalo che utilizzano la contabilità dei buoni regali 2.5';
					|pl = 'Ta operacja jest obsługiwana tylko dla rodzajów certyfikatów podarunkowych, używających ewidencję certyfikatów podarunkowych 2.5.';
					|tr = 'Bu işlem yalnızca hediye kuponu muhasebesi 2.5 kullanan hediye kuponu türleri için desteklenir.'");
		Raise Text;
	EndIf;
	
	GiftCertificateStatus = GiftCertificatesClientServer.CalculateStatusOfGiftCertificate2_5(GiftCertificateDetails);
	
	AllowedStatuses = New Array;
	AllowedStatuses.Add(Enums.GiftCertificateStatuses.Activated);
	AllowedStatuses.Add(Enums.GiftCertificateStatuses.PartiallyRepaid);
	If AllowedStatuses.Find(GiftCertificateStatus) = Undefined Then
		Text = NStr("vi = 'Chỉ hỗ trợ giao dịch này đối với phiếu quà tặng có trạng thái ""Đã kích hoạt"" hoặc ""Thanh lý một phần"".';
					|ru = 'Данная операция поддерживается только для подарочных сертификатов в статусе ""Активирован"" или ""Частично погашен"".';
					|en = 'This transaction is supported only for gift cards with the Activated or Used partially status.'; fa = 'This transaction is supported only for gift cards with the Activated or Used partially status.';
					|it = 'Questa operazione viene supportata solo per buoni regalo con stato ""Attivato"" o ""Parzialmente rimborsato"".';
					|pl = 'Ta operacja jest obsługiwana tylko dla certyfikatów podarunkowych ze statusem ""Aktywowany"" lub ""Częściowo spłacony"".';
					|tr = 'Bu işlem yalnızca ""Etkinleştirildi"" veya ""Kısmen kullanıldı"" durumundaki hediye çekleri için desteklenir.'");
		Raise Text;
	EndIf;
	If GiftCertificateDetails.Nominal <= 0 Then
		Text = NStr("vi = 'Chỉ hỗ trợ giao dịch này đối với phiếu quà tặng có mệnh giá bằng 0.';
					|ru = 'Данная операция поддерживается только для подарочных сертификатов с ненулевым номиналом.';
					|en = 'This transaction is supported only for gift cards with a non-zero nominal value.'; fa = 'This transaction is supported only for gift cards with a non-zero nominal value.';
					|it = 'Questa operazione viene supportata solo per i buoni regalo con denominazione diversa da zero.';
					|pl = 'Ta operacja jest obsługiwana tylko dla certyfikatów podarunkowych z niezerową wartością nominalną.';
					|tr = 'Bu işlem yalnızca sıfır olmayan bir değere sahip hediye kuponları için desteklenir.'");
		Raise Text;
	EndIf;
	
	BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RefundToCustomer");
	
	Organization = GiftCertificateDetails.Organization;
	DocumentAmount = GiftCertificateDetails.Nominal;
	ARAPObject = GiftCertificateDetails.ARAPObject;
	Counterparty = Catalogs.Counterparties.RetailCustomer;
	Partner = Catalogs.Partners.RetailCustomer;
	If TypeOf(DocumentBasis) = Type("Structure") And FillingData.Property("Counterparty") Then
		Counterparty = FillingData.Counterparty;
		Partner = CashServer.GetCounterpartyPartner(Counterparty, BusinessOperation);
	EndIf;
	
	VATTaxation = Common.ObjectAttributeValue(GiftCertificateDetails.ARAPObject, "VATTaxation");
	CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	Currency = GiftCertificateDetails.Currency;
	
	NewRow = ARAPDetails.Add();
	NewRow.Partner = Partner;
	NewRow.ARAPObject = ARAPObject;
	NewRow.Sum = DocumentAmount;
	
	NewRow.CashFlowItem = GiftCertificateDetails.CashFlowItemReturn;
	
	NewRow.ExchangeRateNumeratorOfMutualSettlements = 1;
	NewRow.TheExchangeRateIsTheDenominatorOfMutualSettlements = 1;

	NewRow.ARAPCurrency = Currency;
	VATAccountingERP.FillInVATRateForPayments_(NewRow.VATRate, VATTaxation, Organization, Date);
	
	StructureOfRecalculationOfAmount = New Structure;
	StructureOfRecalculationOfAmount.Insert("PriceIncludesVAT", True);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartServer.ProcessTSString(NewRow, StructureOfActions, Undefined);
		
	CourseAndMultiplicity = CashServer.CourseNumeratorAndCourseDenominatorOfMutualSettlements(Currency, NewRow.ARAPCurrency,
		CurrencyOfComplianceAccounting, Date, ARAPObject);
	NewRow.ExchangeRateNumeratorOfMutualSettlements = CourseAndMultiplicity.CourseNumerator;
	NewRow.TheExchangeRateIsTheDenominatorOfMutualSettlements = CourseAndMultiplicity.CourseDenominator;

	CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
				NewRow, Currency, CurrencyOfComplianceAccounting);
				
EndProcedure

Procedure FillInByPaymentCardTransaction(Val DocumentBasis, FillingData)

	FillingData = CashServer.FillingDataForRefundOfAcquiringTransactionPayment(DocumentBasis);
	
	If ValueIsFilled(DocumentBasis) Then
		AcquiringContract = FillingData.AcquiringContract;
	EndIf;
	
	CashServer.FillInPaymentTranscriptForPaymentDocument(DocumentBasis, FillingData.BusinessOperation, ARAPDetails);

EndProcedure

Procedure FillInCertificateOfAwardToClient(Val DocumentBasis, FillingData)
	
	MessageTemplate = NStr("vi = 'Chứng từ %1 có trạng thái ""%2"". Nhập trên cơ sở chỉ cho phép với trạng thái ""Đã nhận"".';
							|ru = 'Документ %1 находится в статусе ""%2"". Ввод на основании разрешен только в статусе ""Получен"".';
							|en = 'The %1 document is in the ""%2"" status. Generation is only allowed in the ""Received"" status.'; fa = 'The %1 document is in the ""%2"" status. Generation is only allowed in the ""Received"" status.';
							|it = 'Документ %1 находится в статусе ""%2"". Ввод на основании разрешен только в статусе ""Получен"".';
							|pl = 'The %1 document is in the ""%2"" status. Generation is only allowed in the ""Received"" status.';
							|tr = '%1 belgesi,  ""%2"" durumundadır. Temellendirmedeki girdiye sadece ""Alındı"" durumunda izin verilir.'");
	
	QueryText = Documents.CustomerBonusCertificate.QueryTextToBeFilledInBasedOnCashExpenseRequest();
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", DocumentBasis);
	Query.SetParameter("CurrentDate", CurrentSessionDate());
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	Selection.Next();
	
	If Selection.ItIsForbiddenToEnterByStatus Then
		
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			MessageTemplate,
			Selection.PresentationOfDocument,
			Selection.StatusPresentation);
		Raise Text;
		
	EndIf;
	
	FillInDetailsBasedOnRequestResult(DocumentBasis, QueryResult, FillingData,, 0);
	Documents.CustomerBonusCertificate.FillInTranscriptOfPaymentWhenEnteringBasedOn(ThisObject, Selection);

EndProcedure

//++ WE
Procedure FillInHRFormOnSheet(FillingData, StandardProcessing)
	If TypeOf(FillingData) = Type("Structure") Then

		DataOfStatement = IntegrationPayrollAndHumanResourcesServer.DataOfStatement(FillingData.ArrayOfStatements[0]);

		HeaderAttributes = DataOfStatement.HeaderAttributes;

		If Not HeaderAttributes.Posted Then
			Text = NStr("vi = 'Không thể tạo chứng từ mới dựa trên chứng từ chưa kết chuyển.';
						|ru = 'Нельзя создавать новый документ на основании непроведенного.';
						|en = 'Cannot create a new document based on an unposted one.'; fa = 'Cannot create a new document based on an unposted one.';
						|it = 'Cannot create a new document based on an unposted one.';
						|pl = 'Cannot create a new document based on an unposted one.';
						|tr = 'Kaydedilmemiş belge üzerinden yeni belge oluşturulamaz.'");
			Raise Text;
		EndIf;

		If Not ValueIsFilled(HeaderAttributes.Department) Then
			AdditionalProperties.Insert("DisableObjectFillingBasedOnStatistics", True);
		EndIf;

		FillPropertyValues(ThisObject, HeaderAttributes);

		If Not ValueIsFilled(Currency) Then
			Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(HeaderAttributes.Organization);
		EndIf;

		Status = Enums.StatusesOfPaymentRequests.NotAgreedUpon;

		PaymentMethodOfPaymentRequest = ?(HeaderAttributes.PaymentMethodHR = Enums.PaymentMethodsHR.CashAccount,
			Enums.PaymentForms.CashAccountPayment_, Enums.PaymentForms.BankAccountPayment);
		PaymentMethodCash = PaymentMethodOfPaymentRequest = Enums.PaymentForms.CashAccountPayment_;
		PaymentMethodBankAccount = PaymentMethodOfPaymentRequest = Enums.PaymentForms.BankAccountPayment;

		FillingData.PaymentMethodOfPaymentRequest = PaymentMethodOfPaymentRequest;
		FillingData.PaymentMethodCash = PaymentMethodCash;
		FillingData.PaymentMethodBankAccount = PaymentMethodBankAccount;

		BusinessOperation = Enums.BusinessTransactions.SalaryPayment;
		PayrollTransaction = ?(PaymentMethodBankAccount,
			Enums.BusinessTransactions.SalaryPaymentToBankAccounts,
			Enums.BusinessTransactions.SalaryPaymentViaCashAccount);

		RequiredPaymentDate = HeaderAttributes.DateOfPayment;
		PaymentDate = HeaderAttributes.DateOfPayment;
		FillingData.Insert("RequiredPaymentDate", HeaderAttributes.DateOfPayment);

		CashFlowItem = Catalogs.CashFlowReportItems.CashFlowItemForBusinessTransaction(
		BusinessOperation);

		If PaymentMethodBankAccount Then
			ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Organization);
			ParametersOfAccount.Currency = Currency;
			BankAccount = Catalogs.CompaniesBankAccounts.GetDefaultBankAccount(ParametersOfAccount);
		ElsIf FillingData.PaymentMethodCash Then
			CashAccount = Catalogs.CashAccounts.GetCheckoutByDefault(
			Organization, Currency);
		EndIf;

		TableData = DataOfStatement.Table;
		TableData.GroupBy("Statement", "Sum");
		For Each StatementLine In DataOfStatement.Table Do
			NewRow  = ARAPDetails.Add();
			FillPropertyValues(NewRow, StatementLine);
			NewRow.CashFlowItem = CashFlowItem;
		EndDo;
		DocumentAmount = ARAPDetails.Total("Sum");

	EndIf;
	Return;

EndProcedure
//-- WE

Procedure FillInAccordingToSupplyRequest(Val DocumentBasis, FillingData)
	
	ApplicationRequestData = Documents.ApplicationForCollateral.DataForPayment(DocumentBasis);
	FillInDetailsBasedOnRequestResult(DocumentBasis, ApplicationRequestData.HeaderRequestResult, FillingData);
	Documents.ApplicationForCollateral.FillInPaymentTranscript(ThisObject, ApplicationRequestData);
	
EndProcedure

Procedure FillOutBankAccounts(FillingData)
	
	If TypeOf(FillingData) = Type("Structure") Then
		
		HeaderAttributes = New Structure;
		HeaderAttributes.Insert("Organization");
		HeaderAttributes.Insert("BankAccount");
		HeaderAttributes.Insert("Counterparty");
		HeaderAttributes.Insert("CounterpartyBankAccount");
		HeaderAttributes.Insert("CompanyRecipient");
		HeaderAttributes.Insert("BankAccountBeneficiary");
		HeaderAttributes.Insert("Contract");
		HeaderAttributes.Insert("Currency");
		
		FillPropertyValues(HeaderAttributes, FillingData);
		
		For Each KeyAndValue In HeaderAttributes Do
			If ValueIsFilled(KeyAndValue.Value) And Not ValueIsFilled(ThisObject[KeyAndValue.Key]) Then
				ThisObject[KeyAndValue.Key] = KeyAndValue.Value;
			EndIf;
		EndDo;
		
	EndIf;
	
	If ValueIsFilled(Contract) Then
		
		If TypeOf(Contract) = Type("CatalogRef.CounterpartyContracts")
			And (Not ValueIsFilled(BankAccount) Or Not ValueIsFilled(CounterpartyBankAccount)) Then
			
			Catalogs.CounterpartyContracts.FillInBankAccountsUnderAgreement(Contract,
				?(ValueIsFilled(BankAccount), Undefined, BankAccount),
				?(ValueIsFilled(CounterpartyBankAccount), Undefined, CounterpartyBankAccount));
		EndIf;
		
		If TypeOf(Contract) = Type("CatalogRef.IntercompanyContracts")
			And (Not ValueIsFilled(BankAccount) Or Not ValueIsFilled(BankAccountBeneficiary)) Then
			
			Catalogs.IntercompanyContracts.FillInBankAccountsUnderAgreement(Contract,
				?(ValueIsFilled(BankAccount), Undefined, BankAccount),
				?(ValueIsFilled(BankAccountBeneficiary), Undefined, BankAccountBeneficiary));
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(Organization) And Not ValueIsFilled(BankAccount) Then
		ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Organization);
		ParametersOfAccount.LineOfBusiness = LineOfBusiness;
		ParametersOfAccount.Currency = Currency;
		BankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount);
	EndIf;
	
	If ValueIsFilled(CompanyRecipient) And Not ValueIsFilled(BankAccountBeneficiary) Then
		ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(CompanyRecipient);
		ParametersOfAccount.Currency = Currency;
		ParametersOfAccount.LineOfBusiness = LineOfBusiness;
		BankAccountBeneficiary = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount);
	EndIf;
	
	If ValueIsFilled(Counterparty) And Not ValueIsFilled(CounterpartyBankAccount) Then
		ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
		ParametersOfAccount.Currency = Currency;
		CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount);
	EndIf;
	
	If ValueIsFilled(CounterpartyBankAccount) Then
		AccountAttributes = Catalogs.CounterpartyBankAccounts.GetBankAccountDetails(
			CounterpartyBankAccount);
		PaymentPurposes = AccountAttributes.PurposeText;
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

Function SetStatus(NewStatus, AdditionalParameters) Export
	
	MeaningOfNewStatus = Enums.StatusesOfPaymentRequests[NewStatus];
	
	If MeaningOfNewStatus = Enums.StatusesOfPaymentRequests.AgreedUpon
		Or Status <> Enums.StatusesOfPaymentRequests.AgreedUpon
			And MeaningOfNewStatus = Enums.StatusesOfPaymentRequests.AmountDue Then
		WhoDecided = Users.CurrentUser();
	EndIf;
	
	Status = MeaningOfNewStatus;
	
	Return CheckFilling();
	
EndFunction

Procedure CheckWhetherApplicationHasBeenPaid(Cancel)
	
	If Not IsNew() And Status <> Enums.StatusesOfPaymentRequests.AmountDue Then
		
		SetPrivilegedMode(True);
		
		Query = New Query("
		|SELECT
		|	Cash.SumExpense AS Paid
		|FROM
		|	AccumulationRegister.CashToBePaid.Turnovers(,,Period,
		|		PaymentRequest = &Request
		|	) AS Cash
		|WHERE
		|	Cash.SumExpense > 0
		|");
		Query.SetParameter("Request", Ref);
		
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			Text = NStr("vi = 'Giấy đề nghị đã được thanh toán. Không thể thay đổi trạng thái giấy đề nghị là ""Cần thanh toán""';
						|ru = 'Заявка оплачена. Нельзя изменять статус заявки ""К оплате""';
						|en = 'Request is paid up. Cannot change request status ""For payment""'; fa = 'Request is paid up. Cannot change request status ""For payment""';
						|it = 'La richiesta è stata pagata. Non è possibile modificare lo stato della richiesta ""Da pagare""';
						|pl = 'Wniosek jest opłacony. Nie można zmienić status wniosku ""К оплате""';
						|tr = 'Talep ödendi. Talebin durumu ""Ödenecek"" olarak değiştirilmemeli'");
			CommonClientServer.MessageToUser(Text, ThisObject, "Status",, Cancel);
		EndIf;
	EndIf;
	
EndProcedure

Procedure CheckIfSettlementCurrencyMatches(Cancel)
	
	Query = New Query("SELECT
	|	*
	|INTO DocumentTable
	|FROM
	|	&DocumentTable AS DocumentTable
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|	
	|SELECT
	|	DocumentTable.LineNumber AS LineNumber
	|
	|FROM
	|	DocumentTable AS DocumentTable
	|
	|WHERE
	|	DocumentTable.ARAPCurrency <> &RequestCurrency
	|
	|ORDER BY
	|	DocumentTable.LineNumber
	|;
	|");
	
	DocumentTable = ARAPDetails.Unload();
	Query.SetParameter("DocumentTable", DocumentTable);
	Query.SetParameter("RequestCurrency",Currency);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
	
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Tiền tệ hạch toán tại dòng %1 trong danh sách ""Diễn giải thanh toán"" không tương ứng với tiền tệ trong chứng từ %2';
				|ru = 'Валюта взаиморасчетов в строке %1 списка ""Расшифровка платежа"" не соответствует валюте документа %2';
				|en = 'Currency of mutual settlements in line %1 of ""Payment details"" list does not match the currency of document %2'; fa = 'Currency of mutual settlements in line %1 of ""Payment details"" list does not match the currency of document %2';
				|it = 'La valuta di pagamento nella riga %1 ""Deciframento del pagamento"" non corrisponde alla valuta del documento %2';
				|pl = 'Waluta rozliczeń wzajemnych w wierszu %1 listy ""Szczegóły płatności"" nie odpowiada walucie dokumentu%2';
				|tr = '""Ödeme bilgileri"" listesinin %1 satırındaki karşılıklı mutabakat para birimi, %2belgesinin para birimine karşılık gelmiyor '"),
			Selection.LineNumber,
			Currency);
		CommonClientServer.MessageToUser(
			Text,
			ThisObject,
			"ARAPDetails[" + (Selection.LineNumber - 1) + "].ARAPCurrency",,
			Cancel);
	EndDo;
	
EndProcedure

Procedure CheckRepaymentDates(Cancel)
	
	For Each DecryptionString In ARAPDetails Do
		If ValueIsFilled(DecryptionString.MaturityDate)
			And DecryptionString.MaturityDate < RequiredPaymentDate Then
			
			ErrorText = NStr("vi = 'Ngày giảm nợ không thể trước ngày thanh toán.';
							|ru = 'Дата погашения не может быть раньше даты платежа.';
							|en = 'The repayment date cannot be earlier than the payment date.'; fa = 'The repayment date cannot be earlier than the payment date.';
							|it = 'Дата погашения не может быть раньше даты платежа.';
							|pl = 'The repayment date cannot be earlier than the payment date.';
							|tr = 'Vade tarihi ödeme tarihinden önce olamaz.'");
			If AdditionalProperties.Property("ExplanationWithoutSplit")
				And AdditionalProperties.ExplanationWithoutSplit Then
				ErrorDataPath = "MaturityDateWithoutSplitting";
			Else
				ErrorDataPath = "Object.ARAPDetails[" + (DecryptionString.LineNumber - 1) + "].MaturityDate";
			EndIf;
			Common.MessageToUser(ErrorText, , ErrorDataPath, , Cancel);
			
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
