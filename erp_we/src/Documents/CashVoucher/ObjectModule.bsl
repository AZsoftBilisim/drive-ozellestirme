#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	InitialFillingData = FillingData;
	
	If TypeOf(FillingData) = Type("DocumentRef.ExpenseReport") Then
		
		FillInAdvanceReport(
			FillingData,
			FillingData);
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef." + Metadata().Name) Then
		
		DocumentCorrection.FillInCorrection(ThisObject, FillingData);
			
	ElsIf TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("MultipleSpendingRequests") Then
		
		If Not FillingData.MultipleSpendingRequests
			And TypeOf(FillingData.DocumentBasis[0]) = Type("DocumentRef.CashTransferReferenceOrder") Then
			
			CashServer.FillInDocumentOnOrderForTransferOfFunds(
				FillingData.DocumentBasis[0],
				ThisObject,
				FillingData,
				ARAPDetails);
				
			If Not IsNew() Then
				FillPropertyValues(ThisObject, FillingData);
			EndIf;
			
		Else
			CashServer.FillOutDocumentOnApplicationsForSpendingMoney(
				FillingData,
				ARAPDetails,
				Enums.PaymentForms.CashAccountPayment_);
		EndIf;
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.PaymentRequest") Then
		
		CashServer.FillOutDocumentOnApplicationsForSpendingMoney(
			FillingData,
			ARAPDetails,
			Enums.PaymentForms.CashAccountPayment_,
			Ref);
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.PurchaseOrder") Then
		
		FillInByOrderToSupplier(
			FillingData,
			0, // AmountToPay
			FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.SubcontractOrder2_5") Then
		
		FillInByOrderToProcessor2_5(
			FillingData,
			0, // AmountToPay
			FillingData);
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.SubcontractorReport2_5") Then
		
		FillInReportOfProcessor2_5(
			FillingData,
			0, // AmountToPay
			FillingData);
		
	ElsIf TypeOf(FillingData) = Type("CatalogRef.LeaseContract") Then
		FillInLeaseAgreement(FillingData, FillingData);
		
	ElsIf TypeOf(FillingData) = Type("Structure")
	 	And FillingData.Property("Contract")
	 	And TypeOf(FillingData.Contract) = Type("CatalogRef.LeaseContract") Then	
		FillInLeaseAgreement(FillingData.Contract, FillingData);
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.ReceivingLeaseServices") Then
		FillInOnReceiptOfRentalServices(
			FillingData,
			0, // AmountToPay
			FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.VendorInvoice") Then
		
		InformationOnReceiptOfGoods(
			FillingData,
			0,
			FillingData);
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.VendorInvoiceServicesAndAssets") Then
		
		IncomeFromServicesAndNonCurrentAssets(
			FillingData,
			0,
			FillingData);
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.ConsignmentReportToVendor") Then
		
		FillInSalesReportToCommittee(
			FillingData,
			0, //AmountToPay
			FillingData);
	
	ElsIf TypeOf(FillingData) = Type("DocumentRef.ConsignmentReportFromCustomer") Then
		
		FillInReportOfCommissionAgentOnSales(
			FillingData,
			0, //AmountToPay
			FillingData);
	
	ElsIf TypeOf(FillingData) = Type("CatalogRef.CounterpartyContracts") Then
		
		FillInUnderCounterpartySAgreement(
			FillingData,
			0,
			FillingData);
			
	ElsIf TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("PurchaseOrder") Then
		
		If TypeOf(FillingData.PurchaseOrder) = Type("DocumentRef.PurchaseOrder") Then
		
			FillInByOrderToSupplier(
				FillingData.PurchaseOrder,
				FillingData.AmountToPay,
				FillingData);
			
		ElsIf TypeOf(FillingData.PurchaseOrder) = Type("DocumentRef.SubcontractOrder2_5") Then
			
			FillInByOrderToProcessor2_5(
				FillingData.PurchaseOrder,
				FillingData.AmountToPay,
				FillingData);
		ElsIf TypeOf(FillingData.PurchaseOrder) = Type("DocumentRef.VendorInvoice") Then
			
			InformationOnReceiptOfGoods(
				FillingData.PurchaseOrder,
				FillingData.AmountToPay,
				FillingData);
			
		ElsIf TypeOf(FillingData.PurchaseOrder) = Type("DocumentRef.VendorInvoiceServicesAndAssets") Then
			
			IncomeFromServicesAndNonCurrentAssets(
				FillingData.PurchaseOrder,
				FillingData.AmountToPay,
				FillingData);
			
		ElsIf TypeOf(FillingData.PurchaseOrder) = Type("DocumentRef.ConsignmentReportToVendor") Then
			
			FillInSalesReportToCommittee(
				FillingData.PurchaseOrder,
				FillingData.AmountToPay,
				FillingData);
			
		ElsIf TypeOf(FillingData.PurchaseOrder) = Type("DocumentRef.PurchaseInvoiceConsignmentStockLost") Then
			
			FillInReportToCommitteeAboutWriteOff(
				FillingData.PurchaseOrder,
				FillingData.AmountToPay,
				FillingData);
			
		ElsIf TypeOf(FillingData.PurchaseOrder) = Type("DocumentRef.ConsignmentReportFromCustomer") Then
			
			FillInReportOfCommissionAgentOnSales(
				FillingData.PurchaseOrder,
				FillingData.AmountToPay,
				FillingData);
			
		ElsIf TypeOf(FillingData.PurchaseOrder) = Type("DocumentRef.CustomerInvoiceIntercompany") Then
			
			InstructionsForTransferOfGoods(
				FillingData.PurchaseOrder,
				FillingData.AmountToPay,
				FillingData);
		ElsIf TypeOf(FillingData.PurchaseOrder) = Type("DocumentRef.ConsumptionReportSubcontractingServicesDeliveredIntercompany") Then
			
			FillInGiverReportBetweenCompanies(
				FillingData.PurchaseOrder,
				FillingData.AmountToPay,
				FillingData);
		ElsIf TypeOf(FillingData.PurchaseOrder) = Type("CatalogRef.CounterpartyContracts") Then
			
			FillInUnderCounterpartySAgreement(
				FillingData.PurchaseOrder,
				FillingData.AmountToPay,
				FillingData);
			
		ElsIf TypeOf(FillingData.PurchaseOrder) = Type("DocumentRef.CommissionReportIntercompany") Then
			
			FillInCommissionReport(
				FillingData.PurchaseOrder,
				FillingData.Organization,
				FillingData.AmountToPay,
				FillingData);
				
		ElsIf TypeOf(InitialFillingData.PurchaseOrder) = Type("DocumentRef.CCDImport") Then
			
			FillInCustomsDeclaration(
				InitialFillingData.PurchaseOrder,
				InitialFillingData.AmountToPay,
				FillingData);
			
		EndIf;
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.CashTransferReferenceOrder") Then
		
		CashServer.FillInDocumentOnOrderForTransferOfFunds(
			FillingData,
			ThisObject,
			FillingData,
			ARAPDetails);
		
		// If the document was recorded, it is necessary to fill in the filled fields.
		If Not IsNew() Then
			FillPropertyValues(ThisObject, FillingData);
		EndIf;
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.ReturnOfGoodsFromCustomer") Then
		
		InstructionsForReturningGoodsFromClient(
			FillingData,
			FillingData);
		
	ElsIf TypeOf(FillingData) = Type("CatalogRef.LoanAndDepositContracts") Then
		
		CashServer.FillInUnderLoanDepositAgreement(FillingData, FillingData, ARAPDetails, False);
		
	ElsIf TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("BusinessOperation")
		And FillingData.BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder
		And FillingData.Property("AdvanceHolder") Then
		
		If Not FillingData.Property("Department") Then
			FillingData.Insert("Department", PersonsTM.DivisionOfIndividual(FillingData.AdvanceHolder));
		EndIf;
		
		NewRow = ARAPDetails.Add();
		FillPropertyValues(NewRow, FillingData);
		If FillingData.Property("Sum") Then
			NewRow.AmountARAP = FillingData.Sum;
		EndIf;
		If FillingData.Property("Currency") Then
			NewRow.ARAPCurrency = FillingData.Currency;
		EndIf;
		
	ElsIf TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("Basis")
		And TypeOf(FillingData.Basis) = Type("Array") Then
		
		FillByArrayOfBases(FillingData, FillingData.Basis);
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.RedemptionOfGoodsFromStorage") Then
		
		FillingDataDetails = Common.ObjectAttributesValues(FillingData, "BusinessOperation, Counterparty");
		If FillingDataDetails.BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal Then
			BusinessOperation = Enums.BusinessTransactions.RefundToCustomer;
			Counterparty = FillingDataDetails.Counterparty;
		EndIf;
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.SalesOrder") Then
		FillInOnTheCustomerSOrder(FillingData, FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.CashAccountReceiptNote") Then
		FillInReceiptCashOrder(FillingData, FillingData);
		
	ElsIf TypeOf(FillingData) = Type("CatalogRef.GiftCertificates")
		Or TypeOf(FillingData) = Type("Structure") 
			And FillingData.Property("GiftCertificate")
			And FillingData.Property("Counterparty") Then
		
		FillInGiftCertificate(FillingData, FillingData);
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.RedemptionOfGoodsFromStorage") Then
		
		InstructionsForRedemptionOfGoodsAcceptedForStorage(
			FillingData,
			0,
			FillingData);

	//++ WE
	ElsIf TypeOf(FillingData) = Type("DocumentRef.PayrollStatementHR") Then
		FillInHRFormOnSheet(FillingData);
	//-- WE
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.ApplicationForCollateral") Then
		
		FillInAccordingToSupplyRequest(FillingData, FillingData);
		
	EndIf;
	
	If TypeOf(FillingData) = Type("Structure") Then
		
		If CommonClientServer.HasAttributeOrObjectProperty(FillingData, "ThisIsSalaryPayment")
			And CommonClientServer.HasAttributeOrObjectProperty(FillingData, "PaymentRequest")
			And Not FillingData.ThisIsSalaryPayment
			And ValueIsFilled(FillingData.PaymentRequest) Then
			
			If ARAPDetails.Count() = 0 Then
				
				NewRow = ARAPDetails.Add();
				FillPropertyValues(NewRow, FillingData);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	//++ WE
	If GetFunctionalOption("PayrollAndHumanResourcesWE") Then
		If TypeOf(InitialFillingData) = Type("Structure") And FillingData.Property("Statement") Then
			FillInHRFormOnSheet(FillingData.Statement);
		EndIf;
	Else
	//-- WE
		CashVoucherLocalization.Filling(ThisObject, InitialFillingData, FillingData, StandardProcessing);
	//++ WE
	EndIf;
	//-- WE
	
	Author = Users.CurrentUser();
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	If Not TypeOf(FillingData) = Type("DocumentRef." + Metadata().Name) Then
		InitializeDocument(FillingData);
	EndIf;
	
	If ValueIsFilled(CashAccount) Then
		
		OrganizationSCashAccountData =
			CashCached.GetCheckoutDetails(CashAccount);
		PaymentByRequests = PaymentByRequests
							Or ?(OrganizationSCashAccountData.EnableCreatingCashIssueWithoutPaymentRequest, False, True);
		
	EndIf;
	
	CashServer.FillInCashFlowItem(
		ThisObject,
		FillingData,
		?(ValueIsFilled(BusinessOperation), BusinessOperation, Enums.BusinessTransactions.PaymentToVendor));
		
	If FillingData = Undefined
		Or TypeOf(FillingData) <> Type("Structure")
		Or Not FillingData.Property("BusinessOperation")
		Or FillingData.BusinessOperation <> Enums.BusinessTransactions.CashDepositToBankAccount Then
	
		AdditionalProperties.Insert("NeedToFillOutAccountWhenFOUseMultipleAccountsIsFalse", False);
	EndIf;
	
	If TypeOf(FillingData) = Type("Structure") And FillingData.Property("BusinessOperation") Then
		ItemsAndDimensionsSelectionParameters = Documents.CashVoucher.ItemsAndDimensionsSelectionParameters(FillingData.BusinessOperation);
	Else
		ItemsAndDimensionsSelectionParameters = Documents.CashVoucher.ItemsAndDimensionsSelectionParameters(BusinessOperation);
	EndIf;
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	If TypeOf(FillingData) = Type("Structure") And FillingData.Property("BusinessOperation") Then
		CurBusinessTransaction = BusinessOperation;
		BusinessOperation = FillingData.BusinessOperation;
		ARAPAccountingServer.Filling(ThisObject, FillingData);
		BusinessOperation = CurBusinessTransaction;
	Else
		ARAPAccountingServer.Filling(ThisObject, FillingData);
	EndIf;
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	
	DocumentBasis = Undefined;
	Author = Users.CurrentUser();
	
	EnabledCreatingCashIssueWithoutPaymentRequest = CashServer.EnabledCreatingCashIssueWithoutPaymentRequest(ThisObject);
	PaymentByRequests = (Not EnabledCreatingCashIssueWithoutPaymentRequest And ValueIsFilled(CashAccount))
		Or (EnabledCreatingCashIssueWithoutPaymentRequest And PaymentByRequests);
	
	ARAPAccountingServer.OnCopy(ThisObject);
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "ARAPDetails");
	
	CashVoucherLocalization.OnCopy(ThisObject, CopiedObject);
	
	ExpenseReportDate = Date(1,1,1);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	ArrayOfAllProps = New Array;
	ArrayOfOperationDetails = New Array;
	NotCheckedAttributeArray = New Array;
	
	ExplanationWithoutSplit = False;
	If AdditionalProperties.Property("ExplanationWithoutSplit")
		And AdditionalProperties.ExplanationWithoutSplit Then
		ExplanationWithoutSplit = True;
	EndIf;
	
	Documents.CashVoucher.FillInNamesOfBusinessTransactionDetails(
		ThisObject, ArrayOfAllProps, ArrayOfOperationDetails);
	
	If ExplanationWithoutSplit Then
		NotCheckedAttributeArray.Add("ARAPDetails.Sum");
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.OtherCashIssue Then
		NotCheckedAttributeArray.Add("Counterparty");
	EndIf;
	
	DoNotCheckApplicationForm = CashServer.EnabledCreatingCashIssueWithoutPaymentRequest(ThisObject)
		And Not PaymentByRequests;
	
	If DoNotCheckApplicationForm Then
		NotCheckedAttributeArray.Add("ARAPDetails.PaymentRequest");
	EndIf;
	
	If Not (BusinessOperation = Enums.BusinessTransactions.SalaryPaymentToEmployee
		Or BusinessOperation = Enums.BusinessTransactions.SalaryPaymentByDistributor
		Or BusinessOperation = Enums.BusinessTransactions.SalaryPaymentViaCashAccount)
		Or DoNotCheckApplicationForm Then
		NotCheckedAttributeArray.Add("PaymentRequest");
	EndIf;
	
	If Documents.CashVoucher.ArrayOfOperationsWithoutPaymentDecryption().Find(BusinessOperation) <> Undefined
		And DoNotCheckApplicationForm Then
		NotCheckedAttributeArray.Add("ARAPDetails");
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder Then
		NotCheckedAttributeArray.Add("Department");
		
		NotCheckedAttributeArray.Add("ExpenseReportDate");
		
		If Not ValueIsFilled(ExpenseReportDate) Then
			ErrorText = NStr("vi = 'Trường ""Thanh toán"" chưa điền';
							|ru = 'Поле ""Отчитаться"" не заполнено';
							|en = '""Report"" is required'; fa = '""Report"" is required';
							|it = 'Il campo ""Presentare il rendiconto"" non è compilato';
							|pl = 'Pole ""Złożyć sprawozdanie"" nie jest wypełnione';
							|tr = '""Rapor"" alanı doldurulmamış'");
			CommonClientServer.MessageToUser(
				ErrorText,,
				"ExpenseReportPeriod",,
				Cancel);
		EndIf;
	EndIf;
	
	If Not GetFunctionalOption("UseDataSynchronization") Then
		NotCheckedAttributeArray.Add("PaysheetNumber");
		NotCheckedAttributeArray.Add("PaysheetDate");
	EndIf;
	
	NotCheckedAttributeArray.Add("AdvanceHolder");
	UsePayroll = Constants.UsePayroll.Get();
	
	If BusinessOperation = Enums.BusinessTransactions.SalaryPaymentByDistributor Then
		
		If Not ValueIsFilled(AdvanceHolder) Then
			ErrorText = NStr("vi = 'Chưa điền trường ""Nhà phân phối""';
							|ru = 'Поле ""Раздатчик"" не заполнено';
							|en = '""Distributor"" is required'; fa = '""Distributor"" is required';
							|it = 'Il campo ""Distributore"" non è compilato';
							|pl = 'Pole ""Osoba wydającą"" nie jest wypełnione';
							|tr = '""Dağıtımcı"" alanı doldurulmamış'");
			CommonClientServer.MessageToUser(
				ErrorText,
				ThisObject,
				"AdvanceHolder",,
				Cancel);
		EndIf;
	
	ElsIf BusinessOperation = Enums.BusinessTransactions.SalaryPaymentToEmployee Then
		
		If Not ValueIsFilled(AdvanceHolder) Then
			ErrorText = NStr("vi = 'Chưa điền trường ""Nhân viên""';
							|ru = 'Поле ""Сотрудник"" не заполнено';
							|en = '""Employee"" is required'; fa = '""Employee"" is required';
							|it = 'Il campo ""Dipendente"" non è compilato';
							|pl = 'Pole ""Pracownik"" nie jest wypełnione.';
							|tr = '""Çalışan"" alanı doldurulmamış'");
			CommonClientServer.MessageToUser(
				ErrorText,
				ThisObject,
				"AdvanceHolder",,
				Cancel);
		EndIf;
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder
		And Not ValueIsFilled(AdvanceHolder) Then
		ErrorText = NStr("vi = 'Chưa điền trường ""Cá nhân tạm ứng""';
						|ru = 'Поле ""Подотчетное лицо"" не заполнено';
						|en = '""Advance holder"" is required'; fa = '""Advance holder"" is required';
						|it = 'Il campo ""Persona responsabile"" non è compilato';
						|pl = 'Pole ""Osoba rozliczająca się za wydatki"" nie jest wypełnione';
						|tr = '""Sorumlu kişi"" alanı doldurulmamış'");
		CommonClientServer.MessageToUser(
			ErrorText,
			ThisObject,
			"AdvanceHolder",,
			Cancel);
	EndIf;
	
	If (BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SalaryPaymentViaCashAccount")
		Or BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SalaryPaymentByDistributor"))
		And DocumentAmount <> PayrollPayment.Total("Sum") And (UsePayroll Or EntriesByEmployees) Then
		Text = NStr("vi = 'Tổng số tiền theo người lao động không bằng số tiền trên chứng từ. Không thể kết chuyển chứng từ.';
					|ru = 'Итоговая сумма по сотрудникам не равна сумме документа. Документ не может быть проведен.';
					|en = 'Total amount by employees is not equal to the document amount. The document cannot be posted.'; fa = 'Total amount by employees is not equal to the document amount. The document cannot be posted.';
					|it = 'L''importo finale per dipendenti non è equivalente all''importo del documento. il documento non può essere registrato in contabilità.';
					|pl = 'Suma brutto wg pracowników nie jest równa kwocie dokumentu. Dokument nie może zostać zaksięgowany.';
					|tr = 'Çalışanlara ilişkin toplam tutar, belgenin tutarına eşit değildir. Belge kaydedilemedi.'");
			CommonClientServer.MessageToUser(
			Text,
			ThisObject,
			"DocumentAmount",,
			Cancel);
	EndIf;
	
	TMCommonUseClientServer.FillInArrayOfUnverifiableBankingDetails(
		ArrayOfAllProps, ArrayOfOperationDetails, NotCheckedAttributeArray);
	
	ItemsAndDimensionsSelectionParameters = Documents.CashVoucher.ItemsAndDimensionsSelectionParameters(BusinessOperation);
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	CashServer.CheckPartnerContent(
		ThisObject, BusinessOperation, NotCheckedAttributeArray, ExplanationWithoutSplit, Cancel);
	
	CashServer.AddUnverifiableDetailsForPaymentOfWages(ThisObject, NotCheckedAttributeArray);
	
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	Common.DeleteNotCheckedAttributesFromArray(
		CheckedAttributes, NotCheckedAttributeArray);
	
	CashServer.CheckRequestForSpendingMoney(
		ThisObject, Cancel);
	CashServer.CheckOrderForTransferOfFunds(
		ThisObject, Cancel);
		
	CashServer.CheckCompletionOfPaymentDecryption(
		ThisObject, DocumentAmount, BusinessOperation, Cancel);
		
	CashServer.CheckCashRegister(
		ThisObject, Cancel);
	
	CheckBankAccount(Cancel);
	CashServer.CheckRecipientSCashRegister(ThisObject, Cancel);
	CashServer.CheckConversionCurrency(ThisObject, Cancel);
	
	If ExplanationWithoutSplit Then
		CashServer.CheckCompletionOfDecryptionWithoutSplitting(
			ThisObject, CheckedAttributes, "ARAPDetails", "ExplanationWithoutSplit", Cancel);
	EndIf;
	
	If Patch Then
		AmountOfCorrectedDocument = Common.ObjectAttributeValue(CorrectedDocument, "DocumentAmount");
		If DocumentAmount <> AmountOfCorrectedDocument Then
			Text = NStr("vi = 'Khi chỉnh sửa, không thể thay đổi số tiền trong chứng từ.';
						|ru = 'При исправлении сумма документа не может быть изменена.';
						|en = 'When corrected, document amount cannot be changed.'; fa = 'When corrected, document amount cannot be changed.';
						|it = 'Una volta corretto, l''importo del documento non può essere modificato.';
						|pl = 'Przy korekcie wartość dokumentu nie może być zmieniona.';
						|tr = 'Düzeltildiğinde, belge miktarı değiştirilemez.'");
			CommonClientServer.MessageToUser(
				Text,
				ThisObject,
				"DocumentAmount",,
				Cancel);
		EndIf;
	EndIf;
	
	CashVoucherLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	CheckRepaymentDates(Cancel);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	// Clear the table part if it should not be filled in
	ArrayOfOperationDetails = New Array;
	Documents.CashVoucher.FillInNamesOfBusinessTransactionDetails(
		ThisObject, Undefined, ArrayOfOperationDetails);
	
	If ARAPDetails.Count() > 0
		And (ArrayOfOperationDetails.Find("ARAPDetails") = Undefined
			Or Documents.CashVoucher.ArrayOfOperationsWithoutPaymentDecryption().Find(BusinessOperation) <> Undefined
				And Not PaymentByRequests) Then
		ARAPDetails.Clear();
	EndIf;
	
	ArrayOfAllProps = New Array;
	ArrayOfOperationDetails = New Array;
	
	Documents.CashVoucher.FillInNamesOfBusinessTransactionDetails(
		ThisObject, ArrayOfAllProps, ArrayOfOperationDetails);
	CashServer.ClearUnusedProps(
		ThisObject, ArrayOfAllProps, ArrayOfOperationDetails);
	
	If IsNew() And Not ValueIsFilled(Number) Then
		SetNewNumber();
	EndIf;
	
	CashServer.BeforeWrite(ThisObject, Cancel);
	ARAPAccountingServer.BeforeWrite(ThisObject, Cancel, WriteMode);
	
	If WriteMode = DocumentWriteMode.Posting Then
		
		If ArrayOfOperationDetails.Find("ARAPDetails.AmountARAP") <> Undefined Then
			ARAPAccountingServer.FillInAmountOfSettlementsInTablePart(Currency, Date, ARAPDetails, Organization);
		EndIf;
		
		CashServer.FillInOrganizationInTableSection(ARAPDetails, Organization, BusinessOperation);
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "ARAPDetails");

	//Setting up accounting accounts
	GLAccountSettingsServer.BeforeWrite(ThisObject,
		Documents.CashVoucher.AccountingAccountSettings_(BusinessOperation));
	ItemsAndDimensionsSelectionParameters = Documents.CashVoucher.ItemsAndDimensionsSelectionParameters(BusinessOperation);
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	CashVoucherLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	If Not ValueIsFilled(Author) And IsNew() Then
		Author = Users.CurrentUser();
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	CashVoucherLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	CashVoucherLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	CashVoucherLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnSetNewNumber(StandardProcessing, Prefix)
	
	CashVoucherLocalization.OnSetNewNumber(ThisObject, StandardProcessing, Prefix);
	DocumentCorrection.OnSetNewNumber(ThisObject, StandardProcessing, Prefix);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillInAdvanceReport(Val DocumentBasis, FillingData)
	
	SetPrivilegedMode(True);
	
	// Fill in the data of the document header.
	Query = New Query("
	|SELECT
	|	VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder) AS BusinessOperation,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	UNDEFINED AS CashAccount,
	|	ISNULL(Cash.Currency,VALUE(Catalog.Currencies.EmptyRef)) AS Currency,
	|	ISNULL(Cash.Currency,VALUE(Catalog.Currencies.EmptyRef)) AS ARAPCurrency,
	|	DocumentData.AdvanceHolder AS AdvanceHolder,
	|	DocumentData.AdvanceHolder.Description AS Issue,
	|	&Ref AS DocumentBasis,
	|	PRESENTATION(DocumentData.Ref) AS Basis,
	|	Cash.IssuancePurpose AS CashFlowItem,
	|	ISNULL(-Cash.SumBalance,0) AS Sum,
	|	ISNULL(-Cash.SumBalance,0) AS AmountARAP,
	|	ISNULL(-Cash.SumBalance,0) AS DocumentAmount
	|FROM
	|	Document.ExpenseReport AS DocumentData
	|
	|	LEFT JOIN
	|		AccumulationRegister.AdvanceHolderCash.Balance AS Cash
	|	ON
	|		Cash.Organization = DocumentData.Organization
	|		AND Cash.AdvanceHolder = DocumentData.AdvanceHolder
	|		AND Cash.SumBalance < 0
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
	DocumentCurrency = Undefined;
	While Selection.Next() Do
		If DocumentCurrency = Undefined Then
			DocumentCurrency = Selection.Currency;
		EndIf;
		
		If DocumentCurrency = Selection.Currency Then
			FillPropertyValues(FillingData, Selection);
			CashServer.FillInDetailsOfDocumentOnFormOfPayment(
				Enums.PaymentForms.CashAccountPayment_,
				FillingData);
			
			DocumentOfTheIndividual = PersonsTM.GetIndividualSDefaultDocument(Selection.AdvanceHolder).Presentation;
			FillingData.Insert("ByDocument", DocumentOfTheIndividual);
		
			NewRow = ARAPDetails.Add();
			FillPropertyValues(NewRow, Selection);
		EndIf;
	EndDo;
	
EndProcedure

Procedure FillInDetailsBasedOnRequestResult(DocumentBasis, QueryResult, AmountToPay, FillingData) Export
	
	If QueryResult.IsEmpty() Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhập phiếu chi trên cơ sở chứng từ %1';
				|ru = 'Не требуется вводить расходный кассовый ордер на основании документа %1';
				|en = 'You do not have to enter ""Outgoing payment — Cash account"" based on document %1'; fa = 'You do not have to enter ""Outgoing payment — Cash account"" based on document %1';
				|it = 'Non è necessario inserire il mandato di pagamento in contanti in base al documento %1';
				|pl = 'Nie trzeba wprowadzać asygnaty kasowej rozchodowej na podstawie dokumentu %1';
				|tr = '%1 belgesine göre giden ödeme - kasa hesabı girmek gerekli değildir'"),
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
		
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(Enums.PaymentForms.CashAccountPayment_, FillingData);
		
		OrdersToSupplier = DocumentBasis;
		
		QueryText = "";
		If TypeOf(DocumentBasis) = Type("DocumentRef.VendorInvoice") Then
			
			QueryText = 
			"SELECT DISTINCT
			|	GoodsTable.PurchaseOrder AS PurchaseOrder
			|FROM
			|	Document.VendorInvoice.Goods AS GoodsTable
			|WHERE
			|	GoodsTable.Ref = &Ref
			|	AND GoodsTable.Ref.ReceiptUnderOrders
			|	AND GoodsTable.Ref.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
			|	AND GoodsTable.Ref.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
			|";
			
		ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.SubcontractorReport2_5") Then
			
			QueryText = "
			|SELECT DISTINCT
			|	GoodsTable.SubcontractOrder AS PurchaseOrder
			|FROM
			|	Document.SubcontractorReport2_5.ManufacturedProducts AS GoodsTable
			|WHERE
			|	GoodsTable.Ref = &Ref
			|	AND GoodsTable.Ref.ByOrders
			|	AND GoodsTable.Ref.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
			|	AND GoodsTable.Ref.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
			|";
			
		ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.ReceivingLeaseServices") Then
			Return;
		EndIf; 
		
		If QueryText <> "" Then
			Query = New Query(QueryText);
			Query.SetParameter("Ref", DocumentBasis);
			
			RequestResultForOrders = Query.Execute();
			If Not RequestResultForOrders.IsEmpty() Then
				OrdersToSupplier = RequestResultForOrders.Unload().UnloadColumn("PurchaseOrder");
				OrdersToSupplier.Add(DocumentBasis);
			EndIf;
		EndIf;
		
		If ValueIsFilled(Selection.Contract) And TypeOf(OrdersToSupplier) <> Type("CatalogRef.CounterpartyContracts") Then
			ContractSchedule = Common.ObjectAttributeValue(Selection.Contract, "ContractSchedule");
			If ValueIsFilled(ContractSchedule) Then
				OrdersToSupplier = CommonClientServer.ValueInArray(Selection.Contract);
				OrdersToSupplier.Add(DocumentBasis);
			EndIf;
		EndIf;
		
		ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfOrderPaymentToSupplier(
			OrdersToSupplier,
			Selection.Contract,
			FillingData.Currency,
			AmountToPay,
			ARAPDetails);
		
		If Not IsBlankString(Selection.CounterpartyFullName) Then
			FillingData.Insert("Issue", Selection.CounterpartyFullName);
		Else
			FillingData.Insert("Issue", Selection.CounterpartyName_);
		EndIf;
		
	EndIf;
	
	// Filling in the amount of the document header
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure

Procedure FillInByOrderToSupplier(Val DocumentBasis, Val AmountToPay, FillingData)
	
	// Fill in the data of the document header.
	Query = New Query("
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
	|	DocumentData.Counterparty.Description AS CounterpartyName_,
	|	DocumentData.Counterparty.DescriptionFull AS CounterpartyFullName,
	|	VALUE(Enum.BusinessTransactions.PaymentToVendor) AS BusinessOperation,
	|	DocumentData.CashAccount AS CashAccount,
	|	DocumentData.Currency AS Currency,
	|	&Ref AS DocumentBasis
	|FROM
	|	Document.PurchaseOrder AS DocumentData
	|		
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
	|	AND DocumentData.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)
	|");
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhập phiếu chi trên cơ sở chứng từ %1';
				|ru = 'Не требуется вводить расходный кассовый ордер на основании документа %1';
				|en = 'You do not have to enter ""Outgoing payment — Cash account"" based on document %1'; fa = 'You do not have to enter ""Outgoing payment — Cash account"" based on document %1';
				|it = 'Non è necessario inserire il mandato di pagamento in contanti in base al documento %1';
				|pl = 'Nie trzeba wprowadzać asygnaty kasowej rozchodowej na podstawie dokumentu %1';
				|tr = '%1 belgesine göre giden ödeme - kasa hesabı girmek gerekli değildir'"),
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
		
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(Enums.PaymentForms.CashAccountPayment_, FillingData);
		
		ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfOrderPaymentToSupplier(
			DocumentBasis,
			Selection.Contract,
			FillingData.Currency,
			AmountToPay,
			ARAPDetails);
		
		If Not IsBlankString(Selection.CounterpartyFullName) Then
			FillingData.Insert("Issue", Selection.CounterpartyFullName);
		Else
			FillingData.Insert("Issue", Selection.CounterpartyName_);
		EndIf;
		
	EndIf;
	
	// Filling in the amount of the document header
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure

Procedure InformationOnReceiptOfGoods(Val DocumentBasis, Val AmountToPay, FillingData)
	
	// Fill in the data of the document header.
	Query = New Query("
	|SELECT
	|	CASE WHEN DocumentData.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.CompanyBankAccount.Owner
	|	ELSE
	|		DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Counterparty.Description AS CounterpartyName_,
	|	DocumentData.Counterparty.DescriptionFull AS CounterpartyFullName,
	|	VALUE(Enum.BusinessTransactions.PaymentToVendor) AS BusinessOperation,
	|	UNDEFINED AS CashAccount,
	|	DocumentData.Currency AS Currency,
	|	&Ref AS DocumentBasis
	|FROM
	|	Document.VendorInvoice AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND (DocumentData.BusinessOperation IN (&BusinessTransactionsPurchasingFromSupplier)
	|			OR DocumentData.BusinessOperation IN (&BusinessTransactionsImportPurchase)
	|			OR DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromVendorLocal))");
	
	Query.SetParameter("Ref", DocumentBasis);
	Query.SetParameter("BusinessTransactionsPurchasingFromSupplier",
		PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.PurchaseFromSupplier));
	Query.SetParameter("BusinessTransactionsImportPurchase",
		PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.PurchaseByImport));
	
	QueryResult = Query.Execute();
	FillInDetailsBasedOnRequestResult(
		DocumentBasis,
		QueryResult,
		AmountToPay,
		FillingData);
		
EndProcedure

Procedure IncomeFromServicesAndNonCurrentAssets(Val DocumentBasis, Val AmountToPay, FillingData)
	
	// Fill in the data of the document header.
	Query = New Query("
	|SELECT
	|	CASE WHEN DocumentData.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.CompanyBankAccount.Owner
	|	ELSE
	|		DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Counterparty.Description AS CounterpartyName_,
	|	DocumentData.Counterparty.DescriptionFull AS CounterpartyFullName,
	|	VALUE(Enum.BusinessTransactions.PaymentToVendor) AS BusinessOperation,
	|	UNDEFINED AS CashAccount,
	|	DocumentData.Currency AS Currency,
	|	&Ref AS DocumentBasis
	|FROM
	|	Document.VendorInvoiceServicesAndAssets AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|");
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	FillInDetailsBasedOnRequestResult(
		DocumentBasis,
		QueryResult,
		AmountToPay,
		FillingData);
		
EndProcedure

Procedure FillInReportToCommitteeAboutWriteOff(Val DocumentBasis, Val AmountToPay, FillingData)
	
	// Fill in the data of the document header.
	Query = New Query("
	|SELECT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Counterparty.Description AS CounterpartyName_,
	|	DocumentData.Counterparty.DescriptionFull AS CounterpartyFullName,
	|	VALUE(Enum.BusinessTransactions.PaymentToVendor) AS BusinessOperation,
	|	UNDEFINED AS CashAccount,
	|	DocumentData.Currency AS Currency,
	|	&Ref AS DocumentBasis
	|FROM
	|	Document.PurchaseInvoiceConsignmentStockLost AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|");
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	FillInDetailsBasedOnRequestResult(
		DocumentBasis,
		QueryResult,
		AmountToPay,
		FillingData);
	
EndProcedure

Procedure InstructionsForTransferOfGoods(Val DocumentBasis, Val AmountToPay, FillingData)
	
	Query = New Query("
	|SELECT
	|	DocumentData.CompanyRecipient AS Organization,
	|	DocumentData.Organization AS CompanyRecipient,
	|	DocumentData.Organization.Description AS CounterpartyName_,
	|	DocumentData.Organization.AbbreviatedDescription AS CounterpartyFullName,
	|	UNDEFINED AS Counterparty,
	|	UNDEFINED AS Contract,
	
	|	VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany) AS BusinessOperation,
	
	|	UNDEFINED AS CashAccount,
	|	UNDEFINED AS CashAccountRecipient,
	|	DocumentData.Currency AS Currency,
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
	|	DocumentData.Organization AS CompanyRecipient,
	|	DocumentData.Organization.Description AS CounterpartyName_,
	|	DocumentData.Organization.AbbreviatedDescription AS CounterpartyFullName,
	|	DocumentData.Counterparty AS Counterparty,
	|	UNDEFINED AS Contract,
	
	|	VALUE(Enum.BusinessTransactions.PaymentToVendor) AS BusinessOperation,
	
	|	UNDEFINED AS CashAccount,
	|	UNDEFINED AS CashAccountRecipient,
	|	DocumentData.Currency AS Currency,
	|	&Ref AS DocumentBasis
	|FROM
	|	Document.CustomerInvoiceIntercompany AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany)
	|	AND DocumentData.ARAPAccountingViaSeparateCounterparty
	|");
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	FillInDetailsBasedOnRequestResult(
		DocumentBasis,
		QueryResult,
		AmountToPay,
		FillingData);
	
	If Not QueryResult.IsEmpty() Then
		FillingData.CashAccountRecipient = Catalogs.CashAccounts.GetCheckoutByDefault(
			FillingData.CompanyRecipient,
			FillingData.Currency);
	EndIf;
		
EndProcedure

Procedure FillInGiverReportBetweenCompanies(Val DocumentBasis, Val AmountToPay, FillingData)
	
	Query = New Query("
	|SELECT
	|	DocumentData.MaterialProvider AS Organization,
	|	DocumentData.Organization AS CompanyRecipient,
	|	DocumentData.Organization.Description AS CounterpartyName_,
	|	DocumentData.Organization.AbbreviatedDescription AS CounterpartyFullName,
	|	UNDEFINED AS Counterparty,
	|	UNDEFINED AS Contract,
	
	|	VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany) AS BusinessOperation,
	
	|	UNDEFINED AS CashAccount,
	|	UNDEFINED AS CashAccountRecipient,
	|	DocumentData.Currency AS Currency,
	|	&Ref AS DocumentBasis
	|FROM
	|	Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredIntercompany)
	|");
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	FillInDetailsBasedOnRequestResult(
		DocumentBasis,
		QueryResult,
		AmountToPay,
		FillingData);
	
	If Not QueryResult.IsEmpty() Then
		FillingData.CashAccountRecipient = Catalogs.CashAccounts.GetCheckoutByDefault(
			FillingData.CompanyRecipient,
			FillingData.Currency);
	EndIf;
		
EndProcedure
Procedure FillInCommissionReport(Val DocumentBasis, Val DocumentOrganization, Val AmountToPay, FillingData)
	
	Query = New Query("
	|SELECT
	|	DocumentData.Consignee AS Organization,
	|	DocumentData.Organization AS CompanyRecipient,
	|	DocumentData.Organization.Description AS CounterpartyName_,
	|	DocumentData.Organization.AbbreviatedDescription AS CounterpartyFullName,
	|	UNDEFINED AS Counterparty,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS CashAccount,
	|	UNDEFINED AS CashAccountRecipient,
	|	DocumentData.Currency AS Currency,
	|	&Ref AS DocumentBasis,
	|	VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany) AS BusinessOperation
	|FROM
	|	Document.CommissionReportIntercompany AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND NOT DocumentData.ARAPAccountingViaSeparateCounterparty
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Consignee AS Organization,
	|	DocumentData.Organization AS CompanyRecipient,
	|	DocumentData.Counterparty.Description AS CounterpartyName_,
	|	DocumentData.Counterparty.Description AS CounterpartyFullName,
	|	DocumentData.Counterparty AS Counterparty,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS CashAccount,
	|	UNDEFINED AS CashAccountRecipient,
	|	DocumentData.Currency AS Currency,
	|	&Ref AS DocumentBasis,
	|	VALUE(Enum.BusinessTransactions.PaymentToVendor) AS BusinessOperation
	|FROM
	|	Document.CommissionReportIntercompany AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.ARAPAccountingViaSeparateCounterparty
	|");
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	FillInDetailsBasedOnRequestResult(
		DocumentBasis,
		QueryResult,
		AmountToPay,
		FillingData);
	
	If Not QueryResult.IsEmpty() Then
		FillingData.CashAccountRecipient = Catalogs.CashAccounts.GetCheckoutByDefault(
			FillingData.CompanyRecipient,
			FillingData.Currency);
	EndIf;
		
EndProcedure

Procedure InstructionsForReturningGoodsFromClient(Val DocumentBasis, FillingData)
	
	// Fill in the data of the document header.
	Query = New Query("
	|SELECT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Counterparty.Description AS CounterpartyName_,
	|	DocumentData.Counterparty.DescriptionFull AS CounterpartyFullName,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.DocumentAmount AS Sum,
	|	DocumentData.RequestForReturnOfGoodsFromCustomer AS RequestForReturnOfGoodsFromCustomer,
	|	&Ref AS DocumentBasis,
	|
	|	UNDEFINED AS CashAccount,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.CompensationMethod AS CompensationMethod,
	|	VALUE(Enum.BusinessTransactions.RefundToCustomer) AS BusinessOperation,
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
			NStr("vi = 'Không cần nhập phiếu chi trên cơ sở chứng từ %1';
				|ru = 'Не требуется вводить расходный кассовый ордер на основании документа %1';
				|en = 'You do not have to enter ""Outgoing payment — Cash account"" based on document %1'; fa = 'You do not have to enter ""Outgoing payment — Cash account"" based on document %1';
				|it = 'Non è necessario inserire il mandato di pagamento in contanti in base al documento %1';
				|pl = 'Nie trzeba wprowadzać asygnaty kasowej rozchodowej na podstawie dokumentu %1';
				|tr = '%1 belgesine göre giden ödeme - kasa hesabı girmek gerekli değildir'"),
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
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(Enums.PaymentForms.CashAccountPayment_, FillingData);
		
		If Not IsBlankString(Selection.CounterpartyFullName) Then
			FillingData.Insert("Issue", Selection.CounterpartyFullName);
		Else
			FillingData.Insert("Issue", Selection.CounterpartyName_);
		EndIf;
		
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
	
	// Filling in the amount of the document header
	DocumentAmount = ARAPDetails.Total("Sum");
		
EndProcedure

Procedure FillInSalesReportToCommittee(Val DocumentBasis, Val AmountToPay, FillingData)
	
	// Fill in the data of the document header.
	Query = New Query("
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
	|	DocumentData.Counterparty.Description AS CounterpartyName_,
	|	DocumentData.Counterparty.DescriptionFull AS CounterpartyFullName,
	|	VALUE(Enum.BusinessTransactions.PaymentToVendor) AS BusinessOperation,
	|	DocumentData.CashAccount AS CashAccount,
	|	DocumentData.Currency AS Currency,
	|	&Ref AS DocumentBasis
	|FROM
	|	Document.ConsignmentReportToVendor AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|");
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	FillInDetailsBasedOnRequestResult(
		DocumentBasis,
		QueryResult,
		AmountToPay,
		FillingData);
	
EndProcedure

Procedure FillInReportOfCommissionAgentOnSales(Val DocumentBasis, Val AmountToPay, FillingData)
	
	// Fill in the data of the document header.
	Query = New Query("
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
	|	DocumentData.DocumentAmount AS Sum,
	|	DocumentData.Counterparty.Description AS CounterpartyName_,
	|	DocumentData.Counterparty.DescriptionFull AS CounterpartyFullName,
	|	DocumentData.CashAccount AS CashAccount,
	|	DocumentData.Currency AS Currency,
	|	&Ref AS DocumentBasis,
	|
	|	CASE WHEN DocumentData.DocumentAmount >= 0 THEN
	|		VALUE(Enum.BusinessTransactions.PaymentToVendor)
	|	ELSE
	|		VALUE(Enum.BusinessTransactions.RefundToCustomer)
	|	END AS BusinessOperation,
	|
	|	DocumentData.KeepCommissionFee AS KeepCommissionFee
	|FROM
	|	Document.ConsignmentReportFromCustomer AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|");
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhập phiếu chi trên cơ sở chứng từ %1';
				|ru = 'Не требуется вводить расходный кассовый ордер на основании документа %1';
				|en = 'You do not have to enter ""Outgoing payment — Cash account"" based on document %1'; fa = 'You do not have to enter ""Outgoing payment — Cash account"" based on document %1';
				|it = 'Non è necessario inserire il mandato di pagamento in contanti in base al documento %1';
				|pl = 'Nie trzeba wprowadzać asygnaty kasowej rozchodowej na podstawie dokumentu %1';
				|tr = '%1 belgesine göre giden ödeme - kasa hesabı girmek gerekli değildir'"),
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
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(Enums.PaymentForms.CashAccountPayment_, FillingData);
		
		If Not IsBlankString(Selection.CounterpartyFullName) Then
			FillingData.Insert("Issue", Selection.CounterpartyFullName);
		Else
			FillingData.Insert("Issue", Selection.CounterpartyName_);
		EndIf;
		
		If FillingData.BusinessOperation = Enums.BusinessTransactions.PaymentToVendor Then
			
			If FillingData.KeepCommissionFee Then
				Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không cần nhập phiếu chi trên cơ sở chứng từ %1, vì trong đó đã giữ lại khoản hoa hồng';
					|ru = 'Не требуется вводить расходный кассовый ордер на основании документа %1, поскольку в нем удержано вознаграждение';
					|en = 'You do not have to enter ""Outgoing payment — Cash account"" based on document %1 as remuneration is deducted in it'; fa = 'You do not have to enter ""Outgoing payment — Cash account"" based on document %1 as remuneration is deducted in it';
					|it = 'Non è necessario inserire il mandato di pagamento in contanti in base al documento %1 perché vi è stato trattenuto il premio';
					|pl = 'Nie trzeba wprowadzać asygnaty kasowej rozchodowej na podstawie dokumentu %1, ponieważ w nim jest potrącono wynagrodzenie';
					|tr = '%1 belgesine dayalı olarak giden ödeme - kasa hesabı girmenize gerek yoktur, çünkü ikramiye bu belgeden düşülür.'"),
					DocumentBasis);
				Raise Text;
			Else
				
				ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfOrderPaymentToSupplier(
					DocumentBasis,
					Selection.Contract,
					FillingData.Currency,
					AmountToPay,
					ARAPDetails);
				
			EndIf;
			
		Else
			
			ARAPObjects = CommonClientServer.ValueInArray(DocumentBasis);
			ARAPObjects.Add(Selection.Contract);
			
			ARAPAccountingARAPDetailsFillingIn.FillInDecryptionOfPaymentForReturnOfGoodsFromClient(
				ARAPObjects,
				FillingData.Organization,
				FillingData.Currency,
				-FillingData.Sum,
				FillingData.Partner,
				ARAPDetails);
			
		EndIf;
		
	EndIf;
	
	// Filling in the amount of the document header
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure

Procedure FillInUnderCounterpartySAgreement(Val DocumentBasis, Val AmountToPay, FillingData)
	
	// Fill in the data of the document header.
	Query = New Query("
	|SELECT
	|	CASE WHEN DocumentData.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.BankAccount.Owner
	|	ELSE
	|		DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Counterparty.Description AS CounterpartyName_,
	|	DocumentData.Counterparty.DescriptionFull AS CounterpartyFullName,
	|	CASE 
	|		WHEN DocumentData.ContractType IN (&TypesOfCustomerContracts) THEN
	|		VALUE(Enum.BusinessTransactions.RefundToCustomer)
	|	ELSE
	|		VALUE(Enum.BusinessTransactions.PaymentToVendor)
	|	END AS BusinessOperation,
	|	DocumentData.ARAPCurrency AS Currency,
	|	DocumentData.ContractType AS ContractType,
	|	VendorsARAPAccounting.BeingPaidBalance -VendorsARAPAccounting.AmountDueBalance AS AmountARAP,
	|	VendorsARAPAccounting.BeingPaidBalance -VendorsARAPAccounting.AmountDueBalance AS Sum,
	|	VendorsARAPAccounting.BeingPaidBalance -VendorsARAPAccounting.AmountDueBalance AS DocumentAmount,
	|	UNDEFINED AS CashAccount,
	|	VendorsARAPAccounting.ARAPObject AS ARAPObject,
	|	DocumentData.Ref AS Contract,
	|	DocumentData.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	DocumentData.CashFlowItem AS CashFlowItem,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.Department AS Department,
	|	&Ref AS DocumentBasis,
	|	DocumentData.ARAPObjectSettings AS ARAPObjectSettings
	|FROM
	|	Catalog.CounterpartyContracts AS DocumentData
	|	
	|	LEFT JOIN
	|		AccumulationRegister.VendorsARAPAccounting.Balance(, ARAPObject.Object = &Ref) AS VendorsARAPAccounting
	|	ON
	|		TRUE
	|	
	|WHERE
	|	DocumentData.Ref = &Ref
	|");
	Query.SetParameter("Ref", DocumentBasis);
	Query.SetParameter("TypesOfCustomerContracts", CashServer.TypesOfRefundContracts());
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhập phiếu chi trên cơ sở hợp đồng %1';
				|ru = 'Не требуется вводить расходный кассовый ордер на основании договора %1';
				|en = 'You do not have to enter ""Outgoing payment — Cash account"" based on contract %1'; fa = 'You do not have to enter ""Outgoing payment — Cash account"" based on contract %1';
				|it = 'Non è necessario inserire il mandato di pagamento in contanti in base al contratto %1';
				|pl = 'Nie trzeba wprowadzać asygnaty kasowej rozchodowej na podstawie dokumentu %1';
				|tr = '%1sözleşmesine belgesine göre giden ödeme - kasa hesabı girmek gerekli değildir'"),
			DocumentBasis);
		Raise Text;
	Else
		FillingData = New Structure;
		For Each Column In QueryResult.Columns Do
			FillingData.Insert(Column.Name);
		EndDo;
		
		Selection = QueryResult.Select();
		Selection.Next();
		
		If CashServer.TypesOfContractsForPaymentToSupplier().Find(Selection.ContractType) = Undefined
			And CashServer.TypesOfRefundContracts().Find(Selection.ContractType) = Undefined Then
			Raise CashServer.TextAboutExclusionOfPaymentUnderContract(
				Metadata().Synonym,
				Selection.ContractType);
		EndIf;
		
		FillPropertyValues(FillingData, Selection);
		
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(Enums.PaymentForms.CashAccountPayment_, FillingData);
		If Selection.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts 
			Or Selection.ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice Then
			ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentUnderContractWithSupplier(
				DocumentBasis,
				FillingData.Currency,
				ARAPDetails,
				Selection.Organization);
		Else
			DecryptionString = ARAPDetails.Add();
			FillPropertyValues(DecryptionString,Selection);
		EndIf;
		
		If Not IsBlankString(Selection.CounterpartyFullName) Then
			FillingData.Insert("Issue", Selection.CounterpartyFullName);
		Else
			FillingData.Insert("Issue", Selection.CounterpartyName_);
		EndIf;
		
	EndIf;
	
	// Filling in the amount of the document header
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure

Procedure FillInCustomsDeclaration(Val DocumentBasis, Val AmountToPay, FillingData)
	
	// Fill in the data of the document header.
	Query = New Query("
	|SELECT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Counterparty.Description AS CounterpartyName_,
	|	DocumentData.Counterparty.DescriptionFull AS CounterpartyFullName,
	|	VALUE(Enum.BusinessTransactions.PaymentToVendor) AS BusinessOperation,
	|	UNDEFINED AS CashAccount,
	|	DocumentData.Currency AS Currency,
	|	&Ref AS DocumentBasis
	|FROM
	|	Document.CCDImport AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|");
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	FillInDetailsBasedOnRequestResult(
		DocumentBasis,
		QueryResult,
		AmountToPay,
		FillingData);
		
EndProcedure

Procedure InstructionsForRedemptionOfGoodsAcceptedForStorage(Val DocumentBasis, Val AmountToPay, FillingData)
	
	Query = New Query("
	|SELECT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Counterparty.Description AS CounterpartyName_,
	|	DocumentData.Counterparty.DescriptionFull AS CounterpartyFullName,
	|	VALUE(Enum.BusinessTransactions.PaymentToVendor) AS BusinessOperation,
	|	UNDEFINED AS CashAccount,
	|	DocumentData.Currency AS Currency,
	|	&Ref AS DocumentBasis
	|FROM
	|	Document.RedemptionOfGoodsFromStorage AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref");
	
	Query.SetParameter("Ref", DocumentBasis);
	QueryResult = Query.Execute();
	
	FillInDetailsBasedOnRequestResult(DocumentBasis, QueryResult, AmountToPay, FillingData);
	
EndProcedure


Procedure FillInByOrderToProcessor2_5(Val DocumentBasis, Val AmountToPay, FillingData)
	
	// Fill in the data of the document header.
	Query = New Query("
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
	|	DocumentData.Counterparty.Description AS CounterpartyName_,
	|	DocumentData.Counterparty.DescriptionFull AS CounterpartyFullName,
	|	VALUE(Enum.BusinessTransactions.PaymentToVendor) AS BusinessOperation,
	|	DocumentData.CashAccount AS CashAccount,
	|	DocumentData.Currency AS Currency,
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
	If QueryResult.IsEmpty() Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhập phiếu chi trên cơ sở chứng từ %1';
				|ru = 'Не требуется вводить расходный кассовый ордер на основании документа %1';
				|en = 'You do not have to enter ""Outgoing payment — Cash account"" based on document %1'; fa = 'You do not have to enter ""Outgoing payment — Cash account"" based on document %1';
				|it = 'Non è necessario inserire il mandato di pagamento in contanti in base al documento %1';
				|pl = 'Nie trzeba wprowadzać asygnaty kasowej rozchodowej na podstawie dokumentu %1';
				|tr = '%1 belgesine göre giden ödeme - kasa hesabı girmek gerekli değildir'"),
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
		
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(Enums.PaymentForms.CashAccountPayment_, FillingData);
		
		ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfOrderPaymentToSupplier(
			DocumentBasis,
			Selection.Contract,
			FillingData.Currency,
			AmountToPay,
			ARAPDetails);
		
		If Not IsBlankString(Selection.CounterpartyFullName) Then
			FillingData.Insert("Issue", Selection.CounterpartyFullName);
		Else
			FillingData.Insert("Issue", Selection.CounterpartyName_);
		EndIf;
		
	EndIf;
	
	// Filling in the amount of the document header
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure


Procedure FillInReportOfProcessor2_5(Val DocumentBasis, Val AmountToPay, FillingData)
	
	// Fill in the data of the document header.
	Query = New Query("
	|SELECT
	|	CASE WHEN DocumentData.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.CompanyBankAccount.Owner
	|	ELSE
	|		DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Counterparty.Description AS CounterpartyName_,
	|	DocumentData.Counterparty.DescriptionFull AS CounterpartyFullName,
	|	VALUE(Enum.BusinessTransactions.PaymentToVendor) AS BusinessOperation,
	|	UNDEFINED AS CashAccount,
	|	DocumentData.Currency AS Currency,
	|	&Ref AS DocumentBasis
	|FROM
	|	Document.SubcontractorReport2_5 AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|");
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	FillInDetailsBasedOnRequestResult(
		DocumentBasis,
		QueryResult,
		AmountToPay,
		FillingData);
		
EndProcedure

Procedure FillInOnReceiptOfRentalServices(Val DocumentBasis, Val AmountToPay, FillingData)
	
	QueryText = Documents.ReceivingLeaseServices.GetTextToFillInBasedOn();
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	FillInDetailsBasedOnRequestResult(DocumentBasis, QueryResult, AmountToPay, FillingData);
	Documents.ReceivingLeaseServices.FillInTranscriptOfReceiptOfRentalServices(ThisObject, QueryResult, FillingData);
	
EndProcedure

Procedure FillByArrayOfBases(FillingData, ArrayOfBases)
	
	CashServer.FillInDetailsOfDocumentOnFormOfPayment(Enums.PaymentForms.CashAccountPayment_, FillingData);
	
	If ArrayOfBases.Count() Then
		
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
			For Each BaseString In ArrayOfBases Do
				NewRow = ARAPDetails.Add();
				FillPropertyValues(NewRow, BaseString);
			EndDo;
		EndIf;
		
		DocumentAmount = ARAPDetails.Total("Sum");
		
		PaymentBaseObjects = New Array;
		For Each ElementBase In ArrayOfBases Do
			PaymentBaseObjects.Add(ElementBase.PaymentPurpose);
		EndDo;
		PaymentBaseObjects = TMCommonUse.DeleteDuplicateElementsFromArray(PaymentBaseObjects);
		
		If PaymentBaseObjects.Count() = 1 Then
			FillingData.Insert("DocumentBasis", PaymentBaseObjects[0]);
			AttributesValues = Common.ObjectAttributesValues(FillingData.DocumentBasis, "Number, Date");
			FillingData.Insert("Basis",
				TMCommonUse.GetDocumentPresentation(FillingData.DocumentBasis,
					ObjectsPrefixesClientServer.NumberForPrinting(AttributesValues.Number),
						AttributesValues.Date));
		Else
			FillingData.Delete("Basis");
		EndIf;
	EndIf;
	
	If FillingData.Property("Counterparty")
		And TypeOf(FillingData.Counterparty) = Type("CatalogRef.Counterparties") Then
		
		CounterpartyDetails_ = Common.ObjectAttributesValues(FillingData.Counterparty, "Description, DescriptionFull");
		
		If Not IsBlankString(CounterpartyDetails_.DescriptionFull) Then
			FillingData.Insert("Issue", CounterpartyDetails_.DescriptionFull);
		Else
			FillingData.Insert("Issue", CounterpartyDetails_.Description);
		EndIf;
	EndIf;
	
EndProcedure

Procedure InitializeDocument(FillingData)
	
	If TypeOf(FillingData) <> Type("Structure")
		Or Not FillingData.Property("CashAccount")
		Or Not ValueIsFilled(FillingData.CashAccount) Then
		
		CashAccount = Common.CommonSettingsStorageLoad("CurrentCashAccount", "", CashAccount);
		
		If Not ValueIsFilled(CashAccount) Then
			
			If TypeOf(FillingData) = Type("Structure")
				And FillingData.Property("Organization")
				And FillingData.Property("Currency") Then
				
				CashAccount = Catalogs.CashAccounts.GetCheckoutByDefault(
					?(ValueIsFilled(FillingData.Organization), FillingData.Organization, Undefined),
					?(ValueIsFilled(FillingData.Currency), FillingData.Currency, Undefined));
			EndIf;
		EndIf;
		
		If ValueIsFilled(CashAccount) Then
			AttributesStructure1 = CashCached.GetCheckoutDetails(CashAccount);
			If TypeOf(FillingData) = Type("Structure")
				And FillingData.Property("Organization")
				And ValueIsFilled(FillingData.Organization)
				And FillingData.Organization <> AttributesStructure1.Organization Then
				CashAccount = Undefined;
			Else
				Organization = AttributesStructure1.Organization;
				Currency = AttributesStructure1.Currency;
			EndIf;
		EndIf;
	EndIf;
	
	If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("Organization") Then
		If TypeOf(FillingData) = Type("Structure") And FillingData.Property("CashAccount") Then
			Organization = Common.ObjectAttributeValue(FillingData.CashAccount, "Owner");
		Else
			Organization = SettingsValueCached.GetDefaultOrganization(Organization);
		EndIf;
	EndIf;
	
	If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("Currency") Then
		If Not ValueIsFilled(Currency) Then
			If ValueIsFilled(CashAccount) Then
				AttributesStructure1 = CashCached.GetCheckoutDetails(CashAccount);
				Currency = AttributesStructure1.Currency;
			Else
				Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
			EndIf;
		EndIf;
	EndIf;
	
	If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("BankAccount") Then
		ParametersStructure = CashServer.ParametersForFillingOutOrganizationSBankAccount();
		ParametersStructure.Organization = Organization;
		ParametersStructure.Currency      = Currency;
		BankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersStructure);
	EndIf;
	
	If FillingData <> Undefined
		And CommonClientServer.HasAttributeOrObjectProperty(FillingData, "CashAccountRecipient")
		And ValueIsFilled(FillingData.CashAccountRecipient) Then
		
		AttributesStructure1 = CashCached.GetCheckoutDetails(FillingData.CashAccountRecipient);
		
		If ValueIsFilled(AttributesStructure1.Organization) Then
			CompanyRecipient = AttributesStructure1.Organization;
			Issue = Common.ObjectAttributeValue(CompanyRecipient, "DescriptionFull");
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
	
	Author = Users.CurrentUser();
	
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	If Not ValueIsFilled(Currency) Then
		Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	EndIf;
	
	ParametersStructure = CashServer.DefaultParametersForFillingInCheckout();
	ParametersStructure.Organization = Organization;
	ParametersStructure.PaymentMethod = Enums.PaymentForms.CashAccountPayment_;
	ParametersStructure.CashAccount       = CashAccount;
	ParametersStructure.Currency      = Currency;
	
	CashAccount = SettingsValueCached.GetOrganizationSDefaultSalesRegister(ParametersStructure);
	
	If ValueIsFilled(CashAccount) Then
		If Not ValueIsFilled(Organization) Then
			Organization = Catalogs.CashAccounts.GetCheckoutDetails(CashAccount).Organization;
		EndIf;
		If Not ValueIsFilled(Currency) Then
			Currency = Catalogs.CashAccounts.GetCheckoutDetails(CashAccount).Currency;
		EndIf;
	EndIf;
	
EndProcedure

Procedure FillInLeaseAgreement(Val LeaseContracts, FillingData)

	Query = New Query("
	|SELECT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Ref AS Contract,
	|
	|	CASE WHEN DocumentData.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.BankAccount.CashCurrency
	|	ELSE
	|		DocumentData.ARAPCurrency
	|	END AS Currency,
	|	DocumentData.VATTaxation AS VATTaxation,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|
	|	UNDEFINED AS CashAccount,
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
	
	Query.SetParameter("Ref", LeaseContracts);
	
	QueryResult = Query.Execute();
	
	FillingData = New Structure;
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult.Select();
	Selection.Next();
	FillPropertyValues(FillingData, Selection);
	
	CashServer.FillInDetailsOfDocumentOnFormOfPayment(Enums.PaymentForms.CashAccountPayment_, FillingData);
	
	FillPropertyValues(ARAPDetails.Add(), Selection);
	
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure
Procedure FillInOnTheCustomerSOrder(Val DocumentBasis, FillingData)
	
	FillingData = CashServer.GenerateFillInDataForReturningPaymentFromCustomerSOrder(DocumentBasis, ThisObject, Enums.PaymentForms.CashAccountPayment_);
	
	If ValueIsFilled(FillingData.Counterparty) Then
		
		CounterpartyFullName = Common.ObjectAttributeValue(FillingData.Counterparty, "DescriptionFull");
		
		If Not IsBlankString(CounterpartyFullName) Then
			FillingData.Insert("Issue", CounterpartyFullName);
		Else
			FillingData.Insert("Issue", Common.ObjectAttributeValue(FillingData.Counterparty, "Description"));
		EndIf;
		
	EndIf;
	
	CashServer.FillInTranscriptOfPaymentOnClientSOrder(FillingData, ARAPDetails);
	
	DocumentAmount = ARAPDetails.Total("Sum");	
	
EndProcedure

Procedure FillInReceiptCashOrder(Val DocumentBasis, FillingData)
	
	FillingData = CashServer.GenerateFillInDataForReturningPaymentFromIncomingCashOrder(DocumentBasis);
	
	If ValueIsFilled(FillingData.CashAccountRecipient) Then
		FillingData.Insert("CompanyRecipient", Common.ObjectAttributeValue(FillingData.CashAccountRecipient, "Owner"));
	EndIf;
	
	If ValueIsFilled(FillingData.Counterparty) Then
		
		CounterpartyFullName = Common.ObjectAttributeValue(FillingData.Counterparty, "DescriptionFull");
		
		If Not IsBlankString(CounterpartyFullName) Then
			FillingData.Insert("Issue", CounterpartyFullName);
		Else
			FillingData.Insert("Issue", Common.ObjectAttributeValue(FillingData.Counterparty, "Description"));
		EndIf;
	
	ElsIf ValueIsFilled(FillingData.CompanyRecipient) Then
		FillingData.Insert("Issue", Common.ObjectAttributeValue(FillingData.CompanyRecipient, "DescriptionFull"));
	EndIf;
	
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
					|it = 'Questa operazione viene supportata solo per i tipi di buoni regalo che utilizzano la contabilità dei buoni regali 2.5.';
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
					|en = 'This transaction is supported only for gift cards with a non-zero amount.'; fa = 'This transaction is supported only for gift cards with a non-zero amount.';
					|it = 'Questa operazione viene supportata solo per i buoni regalo con denominazione diversa da zero.';
					|pl = 'Ta operacja jest obsługiwana tylko dla certyfikatów podarunkowych z niezerową wartością nominalną.';
					|tr = 'Bu işlem yalnızca sıfır olmayan bir değere sahip hediye kuponları için desteklenir.'");
		Raise Text;
	EndIf;
	
	BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RefundToCustomer");
	
	Organization = GiftCertificateDetails.Organization;
	DocumentAmount = GiftCertificateDetails.Nominal;
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
	NewRow.ARAPObject = GiftCertificateDetails.ARAPObject;
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
		CurrencyOfComplianceAccounting, Date, GiftCertificateDetails.ARAPObject);
	NewRow.ExchangeRateNumeratorOfMutualSettlements = CourseAndMultiplicity.CourseNumerator;
	NewRow.TheExchangeRateIsTheDenominatorOfMutualSettlements = CourseAndMultiplicity.CourseDenominator;

	CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
				NewRow, Currency, CurrencyOfComplianceAccounting);
				
EndProcedure

//++ WE
Procedure FillInHRFormOnSheet(FillingData)
	If TypeOf(FillingData) = Type("DocumentRef.PayrollStatementHR") Then

		DataOfStatement = IntegrationPayrollAndHumanResourcesServer.DataOfStatement(FillingData);

		HeaderAttributes = DataOfStatement.HeaderAttributes;
		FillPropertyValues(ThisObject, HeaderAttributes);

		If ValueIsFilled(HeaderAttributes.DateOfPayment) Then
			RegistrationPeriod = HeaderAttributes.DateOfPayment;
		Else
			RegistrationPeriod = BegOfDay(CurrentSessionDate());
		EndIf;

		If Not ValueIsFilled(Currency) Then
			Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(HeaderAttributes.Organization);
		EndIf;

		CashAccount = Catalogs.CashAccounts.GetCheckoutByDefault(HeaderAttributes.Organization, Currency);
		BusinessOperation = Enums.BusinessTransactions.SalaryPaymentViaCashAccount;

		Basis = HeaderAttributes.Presentation;
		CashFlowItem = Catalogs.CashFlowReportItems.CashFlowItemForBusinessTransaction(
		BusinessOperation);

		Author = Users.AuthorizedUser();
		Statement = FillingData;

		TableData = DataOfStatement.Table;
		For Each StatementLine In DataOfStatement.Table Do
			NewLinePayout  = PayrollPayment.Add();
			FillPropertyValues(NewLinePayout, StatementLine);
		EndDo;
		DocumentAmount = PayrollPayment.Total("Sum");

		FillingData = New Structure("Statement", Statement);
		FillingData.Insert("Organization", Organization);
		FillingData.Insert("CashAccount", CashAccount);
		FillingData.Insert("BusinessOperation", BusinessOperation);
		FillPropertyValues(FillingData, ThisObject);

	EndIf;
	Return;

EndProcedure
//-- WE

Procedure FillInAccordingToSupplyRequest(Val DocumentBasis, FillingData)
	
	ApplicationRequestData = Documents.ApplicationForCollateral.DataForPayment(DocumentBasis);
	Selection = ApplicationRequestData.HeaderRequestResult.Select();
	Selection.Next();
	
	FillingData = New Structure;
	For Each Column In Selection.Owner().Columns Do
		FillingData.Insert(Column.Name, Selection[Column.Name]);
	EndDo;
	
	Documents.ApplicationForCollateral.FillInPaymentTranscript(ThisObject, ApplicationRequestData);
	
EndProcedure

#EndRegion

#Region Other

Procedure CheckBankAccount(Cancel)
	
	If BusinessOperation = Enums.BusinessTransactions.CashDepositToBankAccount
		And ValueIsFilled(CashAccount)
		And ValueIsFilled(BankAccount) Then
		
		AccountAttributes = Catalogs.CompaniesBankAccounts.GetCompanySBankAccountDetails(BankAccount);
		If Organization <> AccountAttributes.Organization Then
			Text = NStr("vi = 'Doanh nghiệp theo tài khoản người nhận không tương ứng với doanh nghiệp trên chứng từ';
						|ru = 'Организация счета получателя не соответствует организации документа';
						|en = 'The company mentioned in the beneficiary account does not match the company mentioned in the document'; fa = 'The company mentioned in the beneficiary account does not match the company mentioned in the document';
						|it = 'L''azienda del conto del destinatario non coincide con l''azienda del documento';
						|pl = 'Firma w rachunku odbiorcy nie odpowiada firmie w dokumencie';
						|tr = 'Alıcı hesabı iş yeri, belge iş yeri ile eşleşmiyor'");
			CommonClientServer.MessageToUser(
				Text,
				ThisObject,
				"BankAccount",,
				Cancel);
		EndIf;
		If Currency <> AccountAttributes.Currency Then
			Text = NStr("vi = 'Tiền tệ trong tài khoản của người nhận không tương ứng với tiền tệ trong chứng từ';
						|ru = 'Валюта счета получателя не соответствует валюте документа';
						|en = 'Beneficiary account currency does not match the document currency'; fa = 'Beneficiary account currency does not match the document currency';
						|it = 'La valuta del conto del destinatario non coincide con la valuta del documento';
						|pl = 'Waluta rachunku odbiorcy nie odpowiada walucie w dokumencie';
						|tr = 'Alıcının hesabının para birimi, belgenin para birimiyle eşleşmiyor'");
			CommonClientServer.MessageToUser(
				Text,
				ThisObject,
				"BankAccount",,
				Cancel);
		EndIf;
	EndIf;
	
EndProcedure

Procedure CheckRepaymentDates(Cancel, FlagEDIWithBanks = False, FillingErrors = "") Export
	
	For Each DecryptionString In ARAPDetails Do
		If ValueIsFilled(DecryptionString.MaturityDate)
			And DecryptionString.MaturityDate < BegOfDay(Date) Then
			
			ErrorText = NStr("vi = 'Ngày giảm nợ không thể trước ngày thanh toán.';
							|ru = 'Дата погашения не может быть раньше даты платежа.';
							|en = 'The repayment date cannot be earlier than the payment date.'; fa = 'The repayment date cannot be earlier than the payment date.';
							|it = 'Дата погашения не может быть раньше даты платежа.';
							|pl = 'The repayment date cannot be earlier than the payment date.';
							|tr = 'Vade tarihi ödeme tarihinden önce olamaz.'");
			If FlagEDIWithBanks Then
				CashServer.AddFillInError(FillingErrors, ErrorText);
			Else
				If AdditionalProperties.Property("ExplanationWithoutSplit")
					And AdditionalProperties.ExplanationWithoutSplit Then
					ErrorDataPath = "MaturityDateWithoutSplitting";
				Else
					ErrorDataPath = "Object.ARAPDetails" + "[" + (DecryptionString.LineNumber - 1) + "].MaturityDate";
				EndIf;
				Common.MessageToUser(ErrorText, , ErrorDataPath, , Cancel);
			EndIf;
			
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
