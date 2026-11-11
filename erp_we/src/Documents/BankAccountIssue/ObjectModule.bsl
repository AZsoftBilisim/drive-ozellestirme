#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Sets the status of the Bank's transaction to the document
//
// Parameters:
//    NewStatus - String - not used
//    AdditionalParameters - Structure - Structure of additional parameters for setting the status.
//
// Returns:
//    Boolean - True, in case of successful installation of the new status.
//
Function SetStatus(NewStatus, AdditionalParameters) Export
	
	If AdditionalParameters <> Undefined Then
		If AdditionalParameters.Property("BankPostingDate", BankPostingDate) Then
			ProcessedByBank = True;
		EndIf;
	EndIf;
	
	Return CheckFilling();
	
EndFunction

#EndRegion

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	BasisType = TypeOf(FillingData);
	
	If BasisType = Type("Structure")
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
			
			DocumentAmount = ARAPDetails.Total("Sum");
			
		Else
			Basis = FillingData.DocumentBasis;
			
			CashServer.FillOutDocumentOnApplicationsForSpendingMoney(
				FillingData,
				ARAPDetails,
				Enums.PaymentForms.BankAccountPayment);
				
			If TypeOf(Basis) = Type("Array") And Basis.Count() > 1 Then
				CashServer.FillInPaymentDestinationText(ThisObject);
				If FillingData.Property("PaymentPurposes") Then
					FillingData.Delete("PaymentPurposes");
				EndIf;
			EndIf;
			
			If TypeOf(Basis) = Type("Array") And Basis.Count() = 1 Then
				FillingData.Insert("DocumentBasis", Basis[0]);
			ElsIf TypeOf(Basis) = Type("DocumentRef.PaymentRequest") Then
				FillingData.Insert("DocumentBasis", Basis);
			EndIf;
		EndIf;
		
	ElsIf BasisType = Type("DocumentRef.PaymentRequest") Then
		
		Basis = FillingData;
		CashServer.FillOutDocumentOnApplicationsForSpendingMoney(
			FillingData,
			ARAPDetails,
			Enums.PaymentForms.BankAccountPayment,
			Ref);
		FillingData.Insert("DocumentBasis", Basis);
		
	ElsIf BasisType = Type("DocumentRef.PurchaseOrder") Then
		
		FillInByOrderToSupplier(
			FillingData,
			0, // AmountToPay
			FillingData);
			
	ElsIf BasisType = Type("DocumentRef.SubcontractOrder2_5") Then
		
		FillInByOrderToProcessor2_5(
			FillingData,
			0, // AmountToPay
			FillingData);
		
	ElsIf BasisType = Type("DocumentRef.SubcontractorReport2_5") Then
		
		FillInReportOfProcessor2_5(
			FillingData,
			0, // AmountToPay
			FillingData);
			
	ElsIf BasisType = Type("DocumentRef.ReceivingLeaseServices") Then
		
		FillInOnReceiptOfRentalServices(
			FillingData,
			0, // AmountToPay
			FillingData);
	
	ElsIf BasisType = Type("DocumentRef.RedemptionOfGoodsFromStorage") Then
		
		InstructionsForRedemptionOfGoodsAcceptedForStorage(
			FillingData,
			0,
			FillingData);
	ElsIf BasisType = Type("DocumentRef.ReportOnVMIAdjustment") Then
		
		InstructionsForDebitingGoodsAcceptedForStorage(
			FillingData,
			0,
			FillingData);
	ElsIf BasisType = Type("CatalogRef.LeaseContract") Then
		FillInLeaseAgreement(FillingData, FillingData);
	ElsIf BasisType = Type("Structure")
	 	And FillingData.Property("Contract")
	 	And TypeOf(FillingData.Contract) = Type("CatalogRef.LeaseContract") Then	
		FillInLeaseAgreement(FillingData.Contract, FillingData);
	ElsIf BasisType = Type("DocumentRef.VendorInvoice") Then
		
		InformationOnReceiptOfGoods(
			FillingData,
			0,
			FillingData);
			
	ElsIf BasisType = Type("DocumentRef.VendorInvoiceServicesAndAssets") Then
		
		IncomeFromServicesAndNonCurrentAssets(
			FillingData,
			0,
			FillingData);
			
	ElsIf BasisType = Type("DocumentRef.ConsignmentReportToVendor") Then
		
		FillInSalesReportToCommittee(
			FillingData,
			0, //AmountToPay
			FillingData);
	
	ElsIf BasisType = Type("DocumentRef.ConsignmentReportFromCustomer") Then
		
		FillInReportOfCommissionAgentOnSales(
			FillingData,
			0, //AmountToPay
			FillingData);
	
	ElsIf BasisType = Type("CatalogRef.CounterpartyContracts") Then
		
		FillInUnderCounterpartySAgreement(
			FillingData,
			0,
			FillingData);
			
	ElsIf BasisType = Type("DocumentRef.CommissionReportIntercompany") Then
		
		AmountToPay = 0;
		FillInCommissionReport(FillingData, FillingData);
	
	ElsIf BasisType = Type("DocumentRef.CustomerBonusCertificate") Then
		
		FillInCertificateOfAwardToClient(FillingData, FillingData);	
		
	ElsIf BasisType = Type("DocumentRef." + Metadata().Name) Then
		
		DocumentCorrection.FillInCorrection(ThisObject, FillingData);
		
	ElsIf BasisType = Type("Structure") And FillingData.Property("PurchaseOrder") Then
		
		DocBasis = FillingData.PurchaseOrder;
		AmountDue = FillingData.AmountToPay;
		
		If TypeOf(FillingData.PurchaseOrder) = Type("DocumentRef.PurchaseOrder") Then
			FillInByOrderToSupplier(DocBasis, AmountDue, FillingData);
			
		ElsIf TypeOf(FillingData.PurchaseOrder) = Type("DocumentRef.VendorInvoice") Then
			InformationOnReceiptOfGoods(DocBasis, AmountDue, FillingData);
			
		ElsIf TypeOf(FillingData.PurchaseOrder) = Type("DocumentRef.VendorInvoiceServicesAndAssets") Then
			IncomeFromServicesAndNonCurrentAssets(DocBasis, AmountDue, FillingData);
				
		ElsIf TypeOf(FillingData.PurchaseOrder) = Type("DocumentRef.ConsignmentReportToVendor") Then
			FillInSalesReportToCommittee(DocBasis, AmountDue, FillingData);
			
		ElsIf TypeOf(FillingData.PurchaseOrder) = Type("DocumentRef.PurchaseInvoiceConsignmentStockLost") Then
			FillInReportToCommitteeAboutWriteOff(DocBasis, AmountDue, FillingData);
			
		ElsIf TypeOf(FillingData.PurchaseOrder) = Type("DocumentRef.ConsignmentReportFromCustomer") Then
			FillInReportOfCommissionAgentOnSales(DocBasis, AmountDue, FillingData);
			
		ElsIf TypeOf(FillingData.PurchaseOrder) = Type("DocumentRef.CustomerInvoiceIntercompany") Then
			InstructionsForTransferOfGoods(DocBasis, AmountDue, FillingData);
		ElsIf TypeOf(FillingData.PurchaseOrder) = Type("DocumentRef.ConsumptionReportSubcontractingServicesDeliveredIntercompany") Then
			FillInGiverReportBetweenCompanies(DocBasis, FillingData, AmountToPay);
		ElsIf TypeOf(FillingData.PurchaseOrder) = Type("DocumentRef.CCDImport") Then
			FillInCustomsDeclaration(DocBasis, AmountDue, FillingData);
			
		ElsIf TypeOf(FillingData.PurchaseOrder) = Type("DocumentRef.CommissionReportIntercompany") Then
			
		ElsIf TypeOf(FillingData.PurchaseOrder) = Type("DocumentRef.ReturnOfGoodsFromCustomer") Then
			InstructionsForReturningGoodsFromClient(DocBasis, FillingData);
			
		ElsIf TypeOf(FillingData.PurchaseOrder) = Type("CatalogRef.CounterpartyContracts") Then
			FillInTheContract(DocBasis, AmountDue, FillingData);
			
		ElsIf TypeOf(FillingData.PurchaseOrder) = Type("DocumentRef.SubcontractOrder2_5") Then
			FillInByOrderToProcessor2_5(DocBasis, AmountDue, FillingData);
		EndIf;
		
	ElsIf BasisType = Type("Structure")
		And FillingData.Property("DocumentBasis")
		And TypeOf(DocumentBasis) = Type("Array") Then
		
		For Each ArrayRow In FillingData.DocumentBasis Do
			
			If TypeOf(ArrayRow)= Type("DocumentRef.PurchaseOrder") Then
				FillInByOrderToSupplier(ArrayRow, 0, FillingData);
				
			ElsIf TypeOf(ArrayRow)= Type("DocumentRef.VendorInvoice") Then	 
				InformationOnReceiptOfGoods(ArrayRow, 0, FillingData);
				
			ElsIf TypeOf(ArrayRow)= Type("DocumentRef.VendorInvoiceServicesAndAssets") Then	 
				IncomeFromServicesAndNonCurrentAssets(ArrayRow, 0, FillingData);
				
			ElsIf TypeOf(ArrayRow)= Type("DocumentRef.ConsignmentReportToVendor") Then	 
				FillInSalesReportToCommittee(ArrayRow, 0, FillingData);
				
			ElsIf TypeOf(ArrayRow)= Type("DocumentRef.PurchaseInvoiceConsignmentStockLost") Then	 
				FillInReportToCommitteeAboutWriteOff(ArrayRow, 0, FillingData);
				
			ElsIf TypeOf(ArrayRow)= Type("DocumentRef.ConsignmentReportFromCustomer") Then	 
				FillInReportOfCommissionAgentOnSales(ArrayRow, 0, FillingData);
				
			ElsIf TypeOf(ArrayRow)= Type("DocumentRef.CustomerInvoiceIntercompany") Then	 
				InstructionsForTransferOfGoods(ArrayRow, 0, FillingData);
			ElsIf TypeOf(ArrayRow)= Type("DocumentRef.ConsumptionReportSubcontractingServicesDeliveredIntercompany") Then	 
				FillInGiverReportBetweenCompanies(ArrayRow, 0, FillingData);
			ElsIf TypeOf(ArrayRow)= Type("DocumentRef.CCDImport") Then	 
				FillInCustomsDeclaration(ArrayRow, 0, FillingData);
				
			ElsIf TypeOf(ArrayRow) = Type("DocumentRef.SubcontractOrder2_5") Then
				FillInByOrderToProcessor2_5(ArrayRow, 0, FillingData);
			ElsIf TypeOf(ArrayRow)= Type("DocumentRef.RedemptionOfGoodsFromStorage") Then
				InstructionsForRedemptionOfGoodsAcceptedForStorage(ArrayRow, 0, FillingData);
			ElsIf TypeOf(ArrayRow)= Type("DocumentRef.ReportOnVMIAdjustment") Then
				InstructionsForDebitingGoodsAcceptedForStorage(ArrayRow, 0, FillingData);
				
			EndIf;
			
		EndDo; 
		
	ElsIf BasisType = Type("DocumentRef.ExpenseReport") Then
		
		FillInAdvanceReport(
			FillingData,
			FillingData);
		
	ElsIf BasisType = Type("DocumentRef.CashTransferReferenceOrder") Then
		
		CashServer.FillInDocumentOnOrderForTransferOfFunds(
			FillingData,
			ThisObject,
			FillingData,
			ARAPDetails);
		
		// If the document was recorded, it is necessary to fill in the filled fields.
		If Not IsNew() Then
			FillPropertyValues(ThisObject, FillingData);
		EndIf;
		
		DocumentAmount = ARAPDetails.Total("Sum");
		
	ElsIf BasisType = Type("DocumentRef.ReturnOfGoodsFromCustomer") Then
		
		InstructionsForReturningGoodsFromClient(
			FillingData,
			FillingData);
		
	ElsIf BasisType = Type("CatalogRef.LoanAndDepositContracts") Then
		
		CashServer.FillInUnderLoanDepositAgreement(FillingData, FillingData, ARAPDetails, False);
		
	ElsIf BasisType = Type("CatalogRef.GiftCertificates")
		Or BasisType = Type("Structure") 
			And FillingData.Property("GiftCertificate")
			And FillingData.Property("Counterparty") Then
		
		FillInGiftCertificate(FillingData, FillingData);
		
	ElsIf BasisType = Type("Structure")
		And FillingData.Property("BusinessOperation")
		And FillingData.BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder
		And FillingData.Property("AdvanceHolder") Then
		
		If Not FillingData.Property("Department") Then
			FillingData.Insert("Department", PersonsTM.DivisionOfIndividual(FillingData.AdvanceHolder));
		EndIf;
		If Not FillingData.Property("CounterpartyBankAccount") Then
			FillingData.Insert("CounterpartyBankAccount",
				Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(FillingData.AdvanceHolder));
		EndIf;
		
		NewRow = ARAPDetails.Add();
		FillPropertyValues(NewRow, FillingData);
		If FillingData.Property("Sum") Then
			NewRow.AmountARAP = FillingData.Sum;
		EndIf;
		If FillingData.Property("Currency") Then
			NewRow.ARAPCurrency = FillingData.Currency;
		EndIf;
		
	ElsIf BasisType = Type("Structure")
		And FillingData.Property("BusinessOperation")
		And FillingData.Property("PaymentRequest")
		And FillingData.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentToBankAccounts Then
		
		NewRow = ARAPDetails.Add();
		FillPropertyValues(NewRow, FillingData);
		
	ElsIf BasisType = Type("Structure")
		And FillingData.Property("CommissionReportIntercompany") 
		And TypeOf(FillingData.CommissionReportIntercompany) = Type("DocumentRef.CommissionReportIntercompany") Then
		
		FillInCommissionReport(FillingData.CommissionReportIntercompany, FillingData,, True);
		
	ElsIf TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("Basis")
		And TypeOf(FillingData.Basis) = Type("Array") Then
		
		FillByArrayOfBases(FillingData, FillingData.Basis);
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.SalesOrder") Then
		FillInOnTheCustomerSOrder(FillingData, FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.BankAccountReceiptNote") Then
		InstructionsForReceiptOfNonCashFunds(FillingData, FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.ApplicationForCollateral") Then
		FillInAccordingToSupplyRequest(FillingData, FillingData);
	EndIf;
		
	If TypeOf(FillingData) = Type("Structure") Then
		
		If FillingData.Property("BankAccount")
			And Not ValueIsFilled(FillingData.BankAccount) Then
			FillingData.BankAccount = CashServer.OrganizationSCurrentBankAccount();
		EndIf;
		
		If FillingData.Property("InstructionsForBank")
			And ValueIsFilled(FillingData.InstructionsForBank) Then
			InstructionsForBank.Load(FillingData.InstructionsForBank.Unload());
		EndIf;
		
		If FillingData.Property("TransferToEmployeeViaABank") Then
			TransferToEmployeeViaABank = FillingData.TransferToEmployeeViaABank;
		EndIf;
		
		If GetFunctionalOption("UseCashDepositToListEmployees") Then
			
			If FillingData.Property("PersonsList") Then
				
				PersonsList = FillingData.PersonsList;
				
				If ARAPDetails.Count() = 0 Then
					
					NewRow = ARAPDetails.Add();
					FillPropertyValues(NewRow, FillingData);
					
				EndIf;
				
			EndIf;
			
			If FillingData.Property("PersonalAccountsOfStaff") Then
				
				For Each TableRow In FillingData.PersonalAccountsOfStaff Do
					
					NewRow = PersonalAccountsOfStaff.Add();
					FillPropertyValues(NewRow, TableRow);
					
				EndDo;
				
				If PersonalAccountsOfStaff.Count() <> 0 Then
					TransferToEmployeeViaABank = True;
				EndIf;
				
			EndIf;
		
		EndIf;
		
	EndIf;
	
	//++ WE
	If Not GetFunctionalOption("PayrollAndHumanResourcesWE") Then
	//-- WE
		BankAccountIssueLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	//++ WE
	EndIf;
	//-- WE

	Author = Users.CurrentUser();
	EmployeeResponsible = Users.CurrentUser();
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	If ValueIsFilled(AcquiringContract) Then
		AttributesOfAcquiringContract = Catalogs.AcquiringContracts.ContractDetails_(AcquiringContract);
		CashFlowItem = AttributesOfAcquiringContract.CashFlowItemReturn;
		ValueAtTimeOfCrediting = Enums.MethodsOfAcquiringCommissionRecording.OnCashReceiving;
		RecordCommission = (AttributesOfAcquiringContract.CommissionPostingMethod = ValueAtTimeOfCrediting
			And AttributesOfAcquiringContract.FeeIsChargedOnRefund);
		
		If RecordCommission Then
			If AttributesOfAcquiringContract.FixedFeeRate Then
				CommissionRate = AttributesOfAcquiringContract.CommissionRate;
				FeeAmount = CashClientServer.CalculateCommissionAmount(DocumentAmount, CommissionRate);
			EndIf;
			FillPropertyValues(ThisObject, AttributesOfAcquiringContract,
				"ExpenseItem, DimensionOfExpenses, LineOfBusiness, KeepRecordsOfCommissionInARAPAccounting, CommissionARAPObject");
			Department = AttributesOfAcquiringContract.ExpensesBusinessUnit;
		EndIf;
	EndIf;
	
	If Not BasisType = Type("DocumentRef." + Metadata().Name) Then
		InitializeDocument(FillingData);
	EndIf;
	
	If ValueIsFilled(BankAccount) Then
		SetPaymentByRequestFlag(BankAccount);
	ElsIf TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("BankAccount")
		And ValueIsFilled(FillingData.BankAccount) Then
		SetPaymentByRequestFlag(FillingData.BankAccount);
	EndIf;
	
	If DocumentAmount <> 0 Then
		If BasisType = Type("Structure") And FillingData.Property("CounterpartyBankAccount") Then
			CounterpartyBankAccount = FillingData.CounterpartyBankAccount;
			If Not ValueIsFilled(PaymentPurposes)
				And (BasisType <> Type("Structure")
					Or Not FillingData.Property("PaymentPurposes")
					Or Not ValueIsFilled(FillingData.PaymentPurposes)) Then
				PaymentPurposes = Catalogs.CounterpartyBankAccounts.GetBankAccountDetails(CounterpartyBankAccount).PurposeText;
			EndIf;
		EndIf;
	EndIf;
	
	If TypeOf(FillingData) = Type("Structure") And FillingData.Property("BusinessOperation") Then
		ItemsAndDimensionsSelectionParameters = Documents.BankAccountIssue.ItemsAndDimensionsSelectionParameters(FillingData.BusinessOperation);
	Else
		ItemsAndDimensionsSelectionParameters = Documents.BankAccountIssue.ItemsAndDimensionsSelectionParameters(BusinessOperation);
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
	
	If Not ValueIsFilled(EmployeeResponsible) Then
		EmployeeResponsible = Users.CurrentUser();
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	
	FlagEDIWithBanks = False;
	FillingErrors = "";
	ExplanationWithoutSplit = False;
	
	If AdditionalProperties.Property("EDIWithBanks")
		And AdditionalProperties.EDIWithBanks Then
		FlagEDIWithBanks = True;
	EndIf;
	
	If AdditionalProperties.Property("ExplanationWithoutSplit")
		And AdditionalProperties.ExplanationWithoutSplit Then
		ExplanationWithoutSplit = True;
	EndIf;
	
	NotCheckedAttributeArray = New Array;
	Documents.BankAccountIssue.FillInNamesOfBusinessTransactionDetails(
		ThisObject, ArrayOfAllProps, ArrayOfOperationDetails);
	TMCommonUseClientServer.FillInArrayOfUnverifiableBankingDetails(
		ArrayOfAllProps, ArrayOfOperationDetails, NotCheckedAttributeArray);
		
	NotCheckedAttributeArray.Add("PaymentRequest");
	
	OptionalSpecificationOfApplication = (CashServer.EnabledCreatingCashIssueWithoutPaymentRequest(ThisObject)
		Or DoNotControlRequestFilling) And Not PaymentByRequests;
	
	If OptionalSpecificationOfApplication Then
		NotCheckedAttributeArray.Add("ARAPDetails.PaymentRequest");
	EndIf;
	
	If Documents.BankAccountIssue.ArrayOfOperationsWithoutPaymentDecryption().Find(BusinessOperation) <> Undefined
		And OptionalSpecificationOfApplication Then
		NotCheckedAttributeArray.Add("ARAPDetails");
	EndIf;
	
	If PaymentDocumentType = Enums.TypesOfPaymentDocuments.PaymentOrder Then
		
		NotCheckedAttributeArray.Add("IncomingDocumentDate");
		NotCheckedAttributeArray.Add("IncomingDocumentNumber");
		
		ErrorText = "";
		
		If Not ValueIsFilled(IncomingDocumentDate)
			And ValueIsFilled(IncomingDocumentNumber) Then
			ErrorText = NStr("vi = 'Chưa điền trường ""Ngày chứng từ đầu vào""';
							|ru = 'Поле ""Дата входящего документа"" не заполнено';
							|en = 'The ""Incoming document date"" field is not filled'; fa = 'The ""Incoming document date"" field is not filled';
							|it = 'Поле ""Дата входящего документа"" не заполнено';
							|pl = 'The ""Incoming document date"" field is not filled';
							|tr = '""Gelen belgenin tarihi"" alanı doldurulmamış'");
			Field = "IncomingDocumentDate";
		ElsIf Not ValueIsFilled(IncomingDocumentNumber)
			And ValueIsFilled(IncomingDocumentDate) Then
			ErrorText = NStr("vi = 'Chưa điền trường ""Số theo ngân hàng""';
							|ru = 'Поле ""Номер по банку"" не заполнено';
							|en = 'The ""Bank number"" field is not filled'; fa = 'The ""Bank number"" field is not filled';
							|it = 'Поле ""Номер по банку"" не заполнено';
							|pl = 'The ""Bank number"" field is not filled';
							|tr = '""Bankaya göre numara"" alanı doldurulmamış'");
			Field = "IncomingDocumentNumber";
		EndIf;
		
		If ErrorText <> "" Then
			
			If FlagEDIWithBanks Then
				CashServer.AddFillInError(FillingErrors, ErrorText);
			Else
				Common.MessageToUser(ErrorText, ThisObject, Field, , Cancel);
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If Not ProcessedByBank Then
		NotCheckedAttributeArray.Add("BankPostingDate");
		NotCheckedAttributeArray.Add("AmountInPayerSCurrency");
	EndIf;
	
	If Not ValueIsFilled(BankAccount) Then
		NotCheckedAttributeArray.Add("Organization");
		NotCheckedAttributeArray.Add("Currency");
		NotCheckedAttributeArray.Add("ARAPDetails.PaymentRequest");
	EndIf;
	
	If ExplanationWithoutSplit Then
		NotCheckedAttributeArray.Add("ARAPDetails.Sum");
	EndIf;
	
	If PersonsList Then
		
		NotCheckedAttributeArray.Add("AdvanceHolder");
		NotCheckedAttributeArray.Add("ARAPDetails.CashFlowItem");
		
	Else
		
		NotCheckedAttributeArray.Add("PersonalAccountsOfStaff");
		NotCheckedAttributeArray.Add("PersonalAccountsOfStaff.Individual");
		NotCheckedAttributeArray.Add("PersonalAccountsOfStaff.PersonalAccount");
		NotCheckedAttributeArray.Add("PersonalAccountsOfStaff.Sum");
		NotCheckedAttributeArray.Add("PersonalAccountsOfStaff.CashFlowItem");
		
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
			If FlagEDIWithBanks Then
				CashServer.AddFillInError(FillingErrors, ErrorText);
			Else
				Common.MessageToUser(ErrorText,, "ExpenseReportPeriod",, Cancel);
			EndIf;
		EndIf;
		
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.TransferOfTaxesAndContributions Then
		NotCheckedAttributeArray.Add("ARAPDetails.Department");
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.CurrencyConversion Then
		NotCheckedAttributeArray.Add("CounterpartyBankAccount");
	EndIf;
	
	CashServer.AddUnverifiableDetailsForPaymentOfWages(ThisObject, NotCheckedAttributeArray);
	
	If TransferToEmployeeViaABank Then
		
		ControlArray = New Array;
		ControlArray.Add("Counterparty");
		ControlArray.Add("CounterpartyBankAccount");
		
		For Each ArrayRow In ControlArray Do
			
			DesiredElement = NotCheckedAttributeArray.Find(ArrayRow);
			
			If DesiredElement <> Undefined Then
				NotCheckedAttributeArray.Delete(DesiredElement);
			EndIf;
			
		EndDo;
		
	Else
		
		If (BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder
			Or BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToEmployee)
			And NotCheckedAttributeArray.Find("Counterparty") = Undefined Then
			NotCheckedAttributeArray.Add("Counterparty");
		EndIf;
		
	EndIf;
	
	If Not PaymentWithConversion Then
		NotCheckedAttributeArray.Add("AmountInPayerSCurrency");
		NotCheckedAttributeArray.Add("CashFlowItemConversion");
	EndIf;
	
	If FlagEDIWithBanks Then
		AdditionalParameters = New Structure("SoftwareVerification", True);
		ChartsOfCharacteristicTypes.ExpenseItems.CheckAnalystCompletion(
			ThisObject, New Structure("ARAPDetails"), NotCheckedAttributeArray, Cancel, AdditionalParameters);
			
		For Each Error In AdditionalParameters.Errors.ErrorList Do
			CashServer.AddFillInError(
				FillingErrors, Error.SeveralErrorsText);
		EndDo;
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.TransferOfTaxesAndContributions
		And Not GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities") Then
		NotCheckedAttributeArray.Add("ARAPDetails.ExpenseItem");
		NotCheckedAttributeArray.Add("ARAPDetails.DimensionOfExpenses");
		NotCheckedAttributeArray.Add("ARAPDetails.AssetsLiabilitiesDimension");
	EndIf;
	
	If Not ListOfCounterparties_ Then
		NotCheckedAttributeArray.Add("ARAPDetails.Counterparty");
	EndIf;
	
	If Not FlagEDIWithBanks Then
		CashServer.CheckPartnerContent(
			ThisObject, BusinessOperation, NotCheckedAttributeArray, ExplanationWithoutSplit, Cancel);
	EndIf;
	
	CheckCompletionOfCommissionArticle = (RecordCommission And FeeAmount <> 0
		And Not KeepRecordsOfCommissionInARAPAccounting);
	
	PerformVerificationOfFillingOutContractOfCommission = (RecordCommission And FeeAmount <> 0
		And KeepRecordsOfCommissionInARAPAccounting);
	
	If Not PerformVerificationOfFillingOutContractOfCommission Then
		NotCheckedAttributeArray.Add("CommissionARAPObject");
	EndIf;
	
	If AdditionalProperties.Property("ExcludeVerificationOfFillingInARAPObjectOfFee")
		And AdditionalProperties.ExcludeVerificationOfFillingInARAPObjectOfFee Then
		NotCheckedAttributeArray.Add("CommissionARAPObject");
	EndIf;
	
	If ValueIsFilled(BankAccount) Then
		CashServer.CheckAvailabilityOfBankAccount(
			ThisObject, BankAccount, "BankAccount", FlagEDIWithBanks, FillingErrors);
	EndIf;
	
	If ValueIsFilled(CounterpartyBankAccount)
		And ArrayOfOperationDetails.Find("CounterpartyBankAccount") <> Undefined Then
		CashServer.CheckAvailabilityOfBankAccount(
			ThisObject, CounterpartyBankAccount, "CounterpartyBankAccount", FlagEDIWithBanks, FillingErrors);
	EndIf;
	
	If ValueIsFilled(BankAccountBeneficiary)
		And ArrayOfOperationDetails.Find("BankAccountBeneficiary") <> Undefined Then
		CashServer.CheckAvailabilityOfBankAccount(
			ThisObject, BankAccountBeneficiary, "BankAccountBeneficiary", FlagEDIWithBanks, FillingErrors);
	EndIf;
	
	If ValueIsFilled(BankAccountForFeeWriteOff)
		And ArrayOfOperationDetails.Find("BankAccountForFeeWriteOff") <> Undefined Then
		CashServer.CheckAvailabilityOfBankAccount(
			ThisObject, BankAccountForFeeWriteOff, "BankAccountForFeeWriteOff", FlagEDIWithBanks, FillingErrors);
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	ItemsAndDimensionsSelectionParameters = Documents.BankAccountIssue.ItemsAndDimensionsSelectionParameters(
		BusinessOperation, CheckCompletionOfCommissionArticle);
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	If Not (BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder
		And PersonsList) Then
		CashServer.CheckCompletionOfPaymentDecryption(
			ThisObject, DocumentAmount, BusinessOperation, Cancel, FlagEDIWithBanks, FillingErrors);
	EndIf;
		
	If Not FlagEDIWithBanks Then
		CashServer.CheckRequestForSpendingMoney(ThisObject, Cancel);
		CashServer.CheckOrderForTransferOfFunds(ThisObject, Cancel);
	EndIf;
	
	CashServer.CheckRecipientSBankAccount(ThisObject, Cancel, FlagEDIWithBanks, FillingErrors);
	CashServer.CheckConversionCurrency(ThisObject, Cancel, FlagEDIWithBanks, FillingErrors);
	
	CashServer.CheckPersonalAccountsOfBankEmployees(ThisObject, Cancel, FlagEDIWithBanks, FillingErrors);
	
	If PaymentByRequests
		And BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder
		And PersonsList Then
		
		Requests = ARAPDetails.UnloadColumn("PaymentRequest");
		
		If Requests.Count() <> 0 Then
			CashServer.CheckFillingOfPersonalAccountsBySources(
				ThisObject, "PersonalAccountsOfStaff", Requests, Cancel, FlagEDIWithBanks, FillingErrors);
		EndIf;
		
	EndIf;
	
	BankAccountIssueLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	CheckRepaymentDates(Cancel, FlagEDIWithBanks, FillingErrors);
	
	If ExplanationWithoutSplit And Not FlagEDIWithBanks Then
		CashServer.CheckCompletionOfDecryptionWithoutSplitting(
			ThisObject, CheckedAttributes, "ARAPDetails", "ExplanationWithoutSplit", Cancel);
	EndIf;
	
	If FlagEDIWithBanks Then
		CashServer.CheckRequiredBankingDetails(ThisObject, CheckedAttributes, FillingErrors);
		AdditionalProperties.Insert("FillingErrors", TrimAll(FillingErrors));
		CheckedAttributes.Clear();
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);

	ArrayOfAllProps = New Array;
	ArrayOfOperationDetails = New Array;
	UnusedAttributes = New Array;
	Documents.BankAccountIssue.FillInNamesOfBusinessTransactionDetails(
		ThisObject, ArrayOfAllProps, ArrayOfOperationDetails);
		
	If PersonsList Then
		
		ArrayOfOperationDetails.Delete(ArrayOfOperationDetails.Find("AdvanceHolder"));
		UnusedAttributes.Add("ARAPDetails.CashFlowItem");
		
	Else
		
		UnusedAttributes.Add("PersonalAccountsOfStaff");
		UnusedAttributes.Add("PersonalAccountsOfStaff.Individual");
		UnusedAttributes.Add("PersonalAccountsOfStaff.PersonalAccount");
		UnusedAttributes.Add("PersonalAccountsOfStaff.Sum");
		UnusedAttributes.Add("PersonalAccountsOfStaff.CashFlowItem");
		
		PersonalAccountsOfStaff.Clear();
		
	EndIf;
	
	If (BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder
		Or BusinessOperation = Enums.BusinessTransactions.SalaryPaymentToBankAccounts
		Or BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToEmployee) 
		And Not TransferToEmployeeViaABank Then
		UnusedAttributes.Add("Counterparty");
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
	
	If Not KeepRecordsOfCommissionInARAPAccounting Then
		UnusedAttributes.Add("CommissionARAPObject");
	EndIf;
	
	For Each UnusedProps In UnusedAttributes Do
		AttributeToDelete = ArrayOfOperationDetails.Find(UnusedProps);
		If AttributeToDelete <> Undefined Then
			ArrayOfOperationDetails.Delete(AttributeToDelete);
		EndIf;
	EndDo;
	
	If ARAPDetails.Count() > 0
		And (ArrayOfOperationDetails.Find("ARAPDetails") = Undefined
			Or Documents.BankAccountIssue.ArrayOfOperationsWithoutPaymentDecryption().Find(BusinessOperation) <> Undefined
				And Not PaymentByRequests) Then
		ARAPDetails.Clear();
	EndIf;
	
	If Not ValueIsFilled(Number) Then
		SetNewNumber();
	EndIf;
	
	If ValueIsFilled(DocumentBasis)
		And TypeOf(DocumentBasis) = Type("DocumentRef.PaymentRequest") Then
		
		If ARAPDetails.Count() <> 0
			And ARAPDetails.Find(DocumentBasis, "PaymentRequest") = Undefined Then
			DocumentBasis = Undefined;
		EndIf;
		
	EndIf;
	
	CashServer.BeforeWrite(ThisObject, Cancel);
	ARAPAccountingServer.BeforeWrite(ThisObject, Cancel, WriteMode);
	
	If Not PaymentWithConversion Then
		
		AmountInPayerSCurrency = 0;
		CashServer.CalculateAmountsInSenderSCurrencyInDecryption(ThisObject);
		
	Else
		
		PayerSCurrency = Common.ObjectAttributeValue(BankAccount, "CashCurrency");
		ConversionFactor_ = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
			Currency,
			PayerSCurrency,
			?(ProcessedByBank, BankPostingDate, Date));
			
		RecalculatedAmount = Round(ConversionFactor_ * ARAPDetails.Total("Sum"), 2);
		VATAmountRecalculated = Round(ConversionFactor_ * ARAPDetails.Total("VATAmount"), 2);
		
		If RecalculatedAmount <> ARAPDetails.Total("AmountInPayerSCurrency")
			Or VATAmountRecalculated <> ARAPDetails.Total("VATAmountInPayerSCurrency") Then
			CashServer.CalculateAmountsInSenderSCurrencyInDecryption(
				ThisObject, PayerSCurrency, ConversionFactor_);
		EndIf;
		
	EndIf;
	
	If WriteMode = DocumentWriteMode.Posting Then
		
		If ArrayOfOperationDetails.Find("ARAPDetails.AmountARAP") <> Undefined Then
			ARAPAccountingServer.FillInAmountOfSettlementsInTablePart(
				Currency, ?(ProcessedByBank, BankPostingDate, Date), ARAPDetails, Organization);
		EndIf;
		
		CashServer.FillInOrganizationInTableSection(ARAPDetails, Organization, BusinessOperation);
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "ARAPDetails");
	TMCommonUse.FillInDocumentIDs(ThisObject, "PersonalAccountsOfStaff");
	
	CashServer.ClearUnusedProps(ThisObject, ArrayOfAllProps, ArrayOfOperationDetails);
	
	FormattedPurposeOfPayment = CashServer.FormatPaymentPurpose(PaymentPurposes);
	
	If WriteMode = DocumentWriteMode.Posting Then
		ImportErrors = "";
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.BankAccountIssue.ItemsAndDimensionsSelectionParameters(
		BusinessOperation, RecordCommission And Not KeepRecordsOfCommissionInARAPAccounting);
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	AccountingAccountSettings_ = Documents.BankAccountIssue.AccountingAccountSettings_(BusinessOperation, TaxType);
	GLAccountSettingsServer.BeforeWrite(ThisObject, AccountingAccountSettings_);
	If Not ValueIsFilled(Author) And IsNew() Then
		Author = Users.CurrentUser();
	EndIf;
	
	//++ WE
	If Not GetFunctionalOption("PayrollAndHumanResourcesWE") Then
	//-- WE
		BankAccountIssueLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	//++ WE
	EndIf;
	//-- WE
	
	
	
	If PaymentDocumentType = Enums.TypesOfPaymentDocuments.PaymentOrder
		And Not (ValueIsFilled(IncomingDocumentNumber) Or ValueIsFilled(IncomingDocumentDate)) Then
		IncomingDocumentNumber = TrimAll(ObjectsPrefixesClientServer.NumberForPrinting(Number, True, True));
		IncomingDocumentDate = Date;
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	BankAccountIssueLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	BankAccountIssueLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	BankAccountIssueLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnSetNewNumber(StandardProcessing, Prefix)
	
	BankAccountIssueLocalization.OnSetNewNumber(ThisObject, StandardProcessing, Prefix);
	
EndProcedure

Procedure OnCopy(CopiedObject)

	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	
	IncomingDocumentDate = "";
	IncomingDocumentNumber = "";
	ExportDate = "";
	ImportDate = "";
	ImportErrors = "";
	FormattedPurposeOfPayment = "";
	StatementData = "";
	NameOfCounterparty = "";
	TypeIndicator = "";
	
	If PaymentDocumentType = Enums.TypesOfPaymentDocuments.CollectionOrder_2
		Or PaymentDocumentType = Enums.TypesOfPaymentDocuments.PaymentWarrant
		Or PaymentDocumentType = Enums.TypesOfPaymentDocuments.BankPaymentOrder Then
		
		EnabledCreatingCashIssueWithoutPaymentRequest = True;
		
		ProcessedByBank = True;
		BankPostingDate = CurrentSessionDate();
		
	Else
		
		EnabledCreatingCashIssueWithoutPaymentRequest = CashServer.EnabledCreatingCashIssueWithoutPaymentRequest(ThisObject);
		
		ProcessedByBank = False;
		BankPostingDate = "";
		
	EndIf;
	
	PaymentByRequests = (Not EnabledCreatingCashIssueWithoutPaymentRequest And ValueIsFilled(BankAccount))
		Or (EnabledCreatingCashIssueWithoutPaymentRequest And PaymentByRequests);
	
	EmployeeResponsible = Users.CurrentUser();
	
	ARAPAccountingServer.OnCopy(ThisObject);
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "ARAPDetails,PersonalAccountsOfStaff");
	
	BankAccountIssueLocalization.OnCopy(ThisObject, CopiedObject);
	
	Author = Users.CurrentUser();
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillInAdvanceReport(Val DocumentBasis, FillingData)
	
	SetPrivilegedMode(True);
	
	Query = New Query("
	|SELECT
	|	VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder) AS BusinessOperation,
	|	DocumentData.Organization,
	|	DocumentData.Department AS Department,
	|	UNDEFINED AS BankAccount,
	|	ISNULL(Cash.Currency,VALUE(Catalog.Currencies.EmptyRef)) AS Currency,
	|	ISNULL(Cash.Currency,VALUE(Catalog.Currencies.EmptyRef)) AS ARAPCurrency,
	|	DocumentData.AdvanceHolder,
	|	DocumentData.AdvanceHolder.Description AS Issue,
	|	DocumentData.Ref AS ExpenseReport,
	|	PRESENTATION(DocumentData.Ref) AS Basis,
	|	Cash.IssuancePurpose AS CashFlowItem,
	|	(-Cash.SumBalance) AS Sum,
	|	(-Cash.SumBalance) AS DocumentAmount,
	|	(-Cash.SumBalance) AS AmountARAP
	|FROM
	|	Document.ExpenseReport AS DocumentData
	|
	|	LEFT JOIN
	|		AccumulationRegister.AdvanceHolderCash.Balance AS Cash
	|	ON
	|		Cash.Organization = DocumentData.Organization
	|		AND Cash.AdvanceHolder = DocumentData.AdvanceHolder
	|		AND  Cash.SumBalance < 0
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
			CashServer.FillInDetailsOfDocumentOnFormOfPayment(Enums.PaymentForms.BankAccountPayment, FillingData);
			
			CurrencyOfRecipient = New Array;
			CurrencyOfRecipient.Add(Undefined);
			CurrencyOfRecipient.Add(Selection.Currency);
			
			If CurrencyOfRecipient.Find(FillingData.Currency) = Undefined Then
				CurrencyOfRecipient.Add(FillingData.Currency);
			EndIf;
			
			CashServer.DefaultCounterpartyBankAccount(
				CounterpartyBankAccount, FillingData.AdvanceHolder, CurrencyOfRecipient);
			PaymentPurposes =
				Catalogs.CounterpartyBankAccounts.GetBankAccountDetails(CounterpartyBankAccount).PurposeText;
			
			NewRow = ARAPDetails.Add();
			FillPropertyValues(NewRow, Selection);
			
			NewRow.Sum = ProcessingOfExchangeRatesTM.ConvertToCurrency(
									NewRow.AmountARAP,
									SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization),
									NewRow.ARAPCurrency,
									FillingData.Currency,
									CurrentSessionDate());
		EndIf;
	EndDo;
	
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure

Procedure FillInByOrderToSupplier(Val DocumentBasis, Val AmountToPay, FillingData)
	
	Query = New Query("
	|SELECT
	|	CASE WHEN DocumentData.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.BankAccount.Owner
	|	WHEN DocumentData.CashAccount <> VALUE(Catalog.CashAccounts.EmptyRef) THEN
	|		DocumentData.CashAccount.Owner
	|	ELSE
	|		DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.Counterparty,
	|	DocumentData.Contract,
	|
	|	CASE WHEN DocumentData.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.BankAccount
	|	ELSE
	|		DocumentData.Contract.BankAccount
	|	END AS BankAccount,
	|	DocumentData.Contract.CounterpartyBankAccount AS CounterpartyBankAccount,
	|	DocumentData.PaymentID AS PaymentID,
	|
	|	CASE WHEN DocumentData.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.BankAccount.CashCurrency
	|	ELSE
	|		ISNULL(DocumentData.Contract.BankAccount.CashCurrency, DocumentData.Currency)
	|	END AS Currency,
	|	&Ref AS DocumentBasis,
	|	DocumentData.OperationWithSelfEmployedPerson AS OperationWithSelfEmployedPerson,
	|	VALUE(Enum.BusinessTransactions.PaymentToVendor) AS BusinessOperation
	|FROM
	|	Document.PurchaseOrder AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
	|	AND DocumentData.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)
	|");
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	FillInDetailsBasedOnRequestResult(DocumentBasis, QueryResult, AmountToPay, FillingData);
	
EndProcedure

Procedure InformationOnReceiptOfGoods(Val DocumentBasis, Val AmountToPay, FillingData)
	
	Query = New Query("
	|SELECT
	|	CASE WHEN DocumentData.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.CompanyBankAccount.Owner
	|	ELSE
	|		DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.CompanyBankAccount AS BankAccount,
	|	DocumentData.CounterpartyBankAccount AS CounterpartyBankAccount,
	|	DocumentData.PaymentID AS PaymentID,
	|
	|	CASE WHEN DocumentData.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.CompanyBankAccount.CashCurrency
	|	ELSE
	|		DocumentData.Currency
	|	END AS Currency,
	|	&Ref AS DocumentBasis,
	|	DocumentData.OperationWithSelfEmployedPerson AS OperationWithSelfEmployedPerson,
	|	VALUE(Enum.BusinessTransactions.PaymentToVendor) AS BusinessOperation
	|FROM
	|	Document.VendorInvoice AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND (DocumentData.BusinessOperation IN (&BusinessTransactionsPurchasingFromSupplier)
	|			OR DocumentData.BusinessOperation IN (&BusinessTransactionsImportPurchase)
	|			OR DocumentData.BusinessOperation IN (&BusinessTransactionsProcurementInEAEUCountries)
	|			OR DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromVendorLocal))");
	
	Query.SetParameter("Ref", DocumentBasis);
	Query.SetParameter("BusinessTransactionsPurchasingFromSupplier",
		PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.PurchaseFromSupplier));
	Query.SetParameter("BusinessTransactionsImportPurchase",
		PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.PurchaseByImport));
	Query.SetParameter("BusinessTransactionsProcurementInEAEUCountries",
		PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.ImportFromEAEU));
	
	QueryResult = Query.Execute();
	FillInDetailsBasedOnRequestResult(DocumentBasis, QueryResult, AmountToPay, FillingData);
	
EndProcedure

Procedure IncomeFromServicesAndNonCurrentAssets(Val DocumentBasis, Val AmountToPay, FillingData)
	
	Query = New Query("
	|SELECT
	|	CASE WHEN DocumentData.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.CompanyBankAccount.Owner
	|	ELSE
	|		DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.CompanyBankAccount AS BankAccount,
	|	DocumentData.CounterpartyBankAccount AS CounterpartyBankAccount,
	|	DocumentData.PaymentID AS PaymentID,
	|
	|	CASE WHEN DocumentData.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.CompanyBankAccount.CashCurrency
	|	ELSE
	|		DocumentData.Currency
	|	END AS Currency,
	|	DocumentData.OperationWithSelfEmployedPerson AS OperationWithSelfEmployedPerson,
	|	&Ref AS DocumentBasis,
	|
	|	VALUE(Enum.BusinessTransactions.PaymentToVendor) AS BusinessOperation
	|FROM
	|	Document.VendorInvoiceServicesAndAssets AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|");
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	FillInDetailsBasedOnRequestResult(DocumentBasis, QueryResult, AmountToPay, FillingData);
	
EndProcedure

Procedure FillInSalesReportToCommittee(Val DocumentBasis, Val AmountToPay, FillingData)
	
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
	|	DocumentData.BankAccount AS BankAccount,
	|	DocumentData.Contract.CounterpartyBankAccount AS CounterpartyBankAccount,
	|	DocumentData.PaymentID AS PaymentID,
	|
	|	CASE WHEN DocumentData.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.BankAccount.CashCurrency
	|	ELSE
	|		DocumentData.Currency
	|	END AS Currency,
	|	&Ref AS DocumentBasis,
	|
	|	VALUE(Enum.BusinessTransactions.PaymentToVendor) AS BusinessOperation
	|FROM
	|	Document.ConsignmentReportToVendor AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|");
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	FillInDetailsBasedOnRequestResult(DocumentBasis, QueryResult, AmountToPay, FillingData);
	
EndProcedure

Procedure FillInReportToCommitteeAboutWriteOff(Val DocumentBasis, Val AmountToPay, FillingData)
	
	Query = New Query("
	|SELECT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	UNDEFINED AS BankAccount,
	|	DocumentData.Contract.CounterpartyBankAccount AS CounterpartyBankAccount,
	|	DocumentData.PaymentID AS PaymentID,
	|	DocumentData.Currency AS Currency,
	|	&Ref AS DocumentBasis,
	|	VALUE(Enum.BusinessTransactions.PaymentToVendor) AS BusinessOperation
	|FROM
	|	Document.PurchaseInvoiceConsignmentStockLost AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|");
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	FillInDetailsBasedOnRequestResult(DocumentBasis, QueryResult, AmountToPay, FillingData);
	
EndProcedure

Procedure FillInReportOfCommissionAgentOnSales(Val DocumentBasis, Val AmountToPay, FillingData)
	
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
	|	DocumentData.BankAccount AS BankAccount,
	|	&Ref AS DocumentBasis,
	|
	|	CASE WHEN DocumentData.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.BankAccount.CashCurrency
	|	ELSE
	|		DocumentData.Currency
	|	END AS Currency,
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
			NStr("vi = 'Không cần nhập Chi tiền từ tài khoản ngân hàng trên cơ sở chứng từ %1';
				|ru = 'Не требуется вводить Списание безналичных ДС на основании документа %1';
				|en = 'It is not required to enter ""Outgoing payment — Bank account"" based on document %1'; fa = 'It is not required to enter ""Outgoing payment — Bank account"" based on document %1';
				|it = 'Non è necessario inserire Lo storno dei mezzi monetari cashless in base al documento %1';
				|pl = 'Nie trzeba wprowadzać Wyksięgowanie bezgotówkowych środków pieniężnych na podstawie dokumentu %1';
				|tr = '%1 belgesine dayalı giden ödeme - banka hesabı girişi gerekmiyor'"),
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
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(Enums.PaymentForms.BankAccountPayment, FillingData);
		
		If ValueIsFilled(FillingData.BankAccount) Then
			CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(
				FillingData.Counterparty, FillingData.Currency);
		Else
			CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(
				FillingData.Counterparty);
		EndIf;
		
		If FillingData.BusinessOperation = Enums.BusinessTransactions.PaymentToVendor Then
			
			If FillingData.KeepCommissionFee Then
				Text = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không cần nhập chứng từ chi tiền từ tài khoản ngân hàng trên cơ sở chứng từ %1, vì trong đó đã giữ lại khoản hoa hồng';
						|ru = 'Не требуется вводить списание безналичных денежных средств на основании документа %1, поскольку в нем удержано вознаграждение';
						|en = 'It is not required to enter ""Outgoing payment — Bank account"" based on document %1 because remuneration is deducted in it'; fa = 'It is not required to enter ""Outgoing payment — Bank account"" based on document %1 because remuneration is deducted in it';
						|it = 'Non è necessario immettere lo storno dei mezzi monetari cashless in base al documento %1, perché nel documento è trattenuto il compenso';
						|pl = 'Nie trzeba wprowadzać wyksięgowanie bezgotówkowych środków pieniężnych na podstawie dokumentu %1, ponieważ w nim jest potrącono wynagrodzenie';
						|tr = '%1 belgesine dayalı olarak giden ödeme - banka hesabı girmek gerekli değildir, çünkü ikramiye bu belgeden düşülür.'"),
					DocumentBasis);
				Raise Text;
			Else
				ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfOrderPaymentToSupplier(
					DocumentBasis, Selection.Contract, FillingData.Currency, AmountToPay, ARAPDetails);
			EndIf;
		Else
			
			ARAPObjects = CommonClientServer.ValueInArray(DocumentBasis);
			ARAPObjects.Add(Selection.Contract);
			
			ARAPAccountingARAPDetailsFillingIn.FillInDecryptionOfPaymentForReturnOfGoodsFromClient(
				ARAPObjects, FillingData.Organization, FillingData.Currency, -FillingData.Sum, FillingData.Partner, ARAPDetails);
		EndIf;
	EndIf;
	
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure

Procedure InstructionsForTransferOfGoods(Val DocumentBasis, Val AmountToPay, FillingData)
	
	Query = New Query("
	|SELECT
	|	DocumentData.CompanyRecipient AS Organization,
	|	DocumentData.Organization AS CompanyRecipient,
	|	UNDEFINED AS Counterparty,
	|	UNDEFINED AS Contract,
	|	DocumentData.RecipientCompanyBankAccount AS BankAccount,
	|	DocumentData.CompanyBankAccount AS BankAccountBeneficiary,
	|	UNDEFINED AS CounterpartyBankAccount,
	|
	|	CASE WHEN DocumentData.RecipientCompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.RecipientCompanyBankAccount.CashCurrency
	|	ELSE
	|		DocumentData.Currency
	|	END AS Currency,
	|	&Ref AS DocumentBasis,
	|	DocumentData.PaymentID AS PaymentID,
	|	VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany) AS BusinessOperation
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
	|	DocumentData.Counterparty AS Counterparty,
	|	UNDEFINED AS Contract,
	|	DocumentData.RecipientCompanyBankAccount AS BankAccount,
	|	DocumentData.CompanyBankAccount AS BankAccountBeneficiary,
	|	UNDEFINED AS CounterpartyBankAccount,
	|
	|	CASE WHEN DocumentData.RecipientCompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.RecipientCompanyBankAccount.CashCurrency
	|	ELSE
	|		DocumentData.Currency
	|	END AS Currency,
	|	&Ref AS DocumentBasis,
	|	DocumentData.PaymentID AS PaymentID,
	|	VALUE(Enum.BusinessTransactions.PaymentToVendor) AS BusinessOperation
	|FROM
	|	Document.CustomerInvoiceIntercompany AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany)
	|	AND DocumentData.ARAPAccountingViaSeparateCounterparty
	|");
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	FillInDetailsBasedOnRequestResult(DocumentBasis, QueryResult, AmountToPay, FillingData);
	
EndProcedure

Procedure FillInGiverReportBetweenCompanies(Val DocumentBasis, Val AmountToPay, FillingData)
	
	Query = New Query("
	|SELECT
	|	DocumentData.MaterialProvider AS Organization,
	|	DocumentData.Organization AS CompanyRecipient,
	|	UNDEFINED AS Counterparty,
	|	UNDEFINED AS Contract,
	|	DocumentData.MaterialProviderAccount AS BankAccount,
	|	DocumentData.SubcontractorAccount AS BankAccountBeneficiary,
	|	CASE
	|		WHEN DocumentData.MaterialProviderAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
	|			THEN DocumentData.MaterialProviderAccount.CashCurrency
	|		ELSE DocumentData.Currency
	|	END AS Currency,
	|	&Ref AS DocumentBasis,
	
	|	VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany) AS BusinessOperation
	|FROM
	|	Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredIntercompany)
	|");
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	FillInDetailsBasedOnRequestResult(DocumentBasis, QueryResult, AmountToPay, FillingData);
	
EndProcedure
Procedure FillInCommissionReport(Val DocumentBasis, FillingData, AmountDue = 0, Remuneration = False)
	
	Query = New Query("
	|SELECT
	|	DocumentData.Consignee AS Organization,
	|	DocumentData.Organization AS CompanyRecipient,
	|	UNDEFINED AS Counterparty,
	|	UNDEFINED AS Contract,
	|	DocumentData.Contract.BankAccountOfBeneficiary AS BankAccount,
	|	DocumentData.Contract.BankAccount AS BankAccountBeneficiary,
	|	UNDEFINED AS CounterpartyBankAccount,
	|	DocumentData.Currency AS Currency,
	|	&Ref AS DocumentBasis,
	|	VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany) AS BusinessOperation
	|FROM
	|	Document.CommissionReportIntercompany AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND NOT DocumentData.ARAPAccountingViaSeparateCounterparty
	|	AND NOT &Remuneration
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Consignee AS Organization,
	|	DocumentData.Organization AS CompanyRecipient,
	|	DocumentData.Counterparty AS Counterparty,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS BankAccount,
	|	UNDEFINED AS BankAccountBeneficiary,
	|	DocumentData.PurchasingContract.CounterpartyBankAccount AS CounterpartyBankAccount,
	|	DocumentData.Currency AS Currency,
	|	&Ref AS DocumentBasis,
	|	VALUE(Enum.BusinessTransactions.PaymentToVendor) AS BusinessOperation
	|FROM
	|	Document.CommissionReportIntercompany AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.ARAPAccountingViaSeparateCounterparty
	|	AND NOT &Remuneration
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Consignee AS CompanyRecipient,
	|	UNDEFINED AS Counterparty,
	|	UNDEFINED AS Contract,
	|	DocumentData.Contract.BankAccount AS BankAccount,
	|	DocumentData.Contract.BankAccountOfBeneficiary AS BankAccountBeneficiary,
	|	UNDEFINED AS CounterpartyBankAccount,
	|	DocumentData.Currency AS Currency,
	|	&Ref AS DocumentBasis,
	|	VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany) AS BusinessOperation
	|FROM
	|	Document.CommissionReportIntercompany AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND NOT DocumentData.ARAPAccountingViaSeparateCounterparty
	|	AND &Remuneration
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Consignee AS CompanyRecipient,
	|	DocumentData.Counterparty AS Counterparty,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS BankAccount,
	|	UNDEFINED AS BankAccountBeneficiary,
	|	DocumentData.SalesContract.CounterpartyBankAccount AS CounterpartyBankAccount,
	|	DocumentData.Currency AS Currency,
	|	&Ref AS DocumentBasis,
	|	VALUE(Enum.BusinessTransactions.PaymentToVendor) AS BusinessOperation
	|FROM
	|	Document.CommissionReportIntercompany AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.ARAPAccountingViaSeparateCounterparty
	|	AND &Remuneration
	|");
	
	Query.SetParameter("Ref", DocumentBasis);
	Query.SetParameter("Remuneration", Remuneration);
	
	QueryResult = Query.Execute();
	
	FillingData = New Structure;
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	FillInDetailsBasedOnRequestResult(DocumentBasis, QueryResult, AmountDue, FillingData, FillingData.Organization);
	
	If Not QueryResult.IsEmpty() Then
		
		If Not ValueIsFilled(FillingData.BankAccount) Then
			ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount();
			ParametersOfAccount.Organization = FillingData.Organization;
			ParametersOfAccount.Currency = FillingData.Currency;
			FillingData.BankAccount =
				Catalogs.CompaniesBankAccounts.GetDefaultBankAccount(ParametersOfAccount);
		EndIf;
		
		If Not ValueIsFilled(FillingData.BankAccountBeneficiary) Then
			ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount();
			ParametersOfAccount.Organization = FillingData.CompanyRecipient;
			ParametersOfAccount.Currency = FillingData.Currency;
			ParametersOfAccount.OffsettingAccount = FillingData.BankAccount;
			FillingData.BankAccountBeneficiary =
				Catalogs.CompaniesBankAccounts.GetDefaultBankAccount(ParametersOfAccount);
		EndIf;
		
		FillingData.Insert("CashFlowItem",
			Catalogs.CashFlowReportItems.CashFlowItemForBusinessTransaction(FillingData.BusinessOperation));
		
		If ValueIsFilled(FillingData.CashFlowItem) Then
			For Each Page1 In ARAPDetails Do
				Page1.CashFlowItem = FillingData.CashFlowItem;
			EndDo;
		EndIf;
	EndIf;
	
EndProcedure

Procedure InstructionsForReturningGoodsFromClient(Val DocumentBasis, FillingData)
	
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
	|	DocumentData.PaymentID AS PaymentID,
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
			NStr("vi = 'Không cần nhập chứng từ chi tiền từ tài khoản ngân hàng trên cơ sở chứng từ %1';
				|ru = 'Не требуется вводить списание безналичных денежных средств на основании документа %1';
				|en = 'It is not required to enter ""Outgoing payment — Bank account"" based on document %1'; fa = 'It is not required to enter ""Outgoing payment — Bank account"" based on document %1';
				|it = 'Non è necessario immettere lo storno dei mezzi monetari cashless in base al documento %1';
				|pl = 'Nie trzeba wprowadzać wyksięgowanie bezgotówkowych środków pieniężnych na podstawie dokumentu %1';
				|tr = '%1 belgeye dayalı olarak giden ödeme - banka hesabı girilmesi gerekli değildir.'"),
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
			ARAPObjects, FillingData.Organization , FillingData.Currency, FillingData.Sum, FillingData.Partner, ARAPDetails);
	EndIf;
	
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure

Procedure FillInCustomsDeclaration(Val DocumentBasis, Val AmountToPay, FillingData)
	
	// Fill in the data of the document header.
	Query = New Query("
	|SELECT
	|	CASE WHEN DocumentData.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.CompanyBankAccount.Owner
	|	ELSE
	|		DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.CompanyBankAccount AS BankAccount,
	|	DocumentData.CounterpartyBankAccount AS CounterpartyBankAccount,
	|	DocumentData.PaymentID AS PaymentID,
	|
	|	CASE WHEN DocumentData.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.CompanyBankAccount.CashCurrency
	|	ELSE
	|		DocumentData.Currency
	|	END AS Currency,
	|	&Ref AS DocumentBasis,
	|
	|	CASE WHEN DocumentData.RegistrationOption = VALUE(Enum.BusinessTransactions.RegisterCCDUnassisted)
	|		THEN VALUE(Enum.BusinessTransactions.CustomsPayment)
	|		ELSE VALUE(Enum.BusinessTransactions.PaymentToVendor) END AS BusinessOperation
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

Procedure FillInTheContract(Val DocumentBasis, Val AmountToPay, FillingData)
	
	Query = New Query("
	|SELECT
	|	CASE WHEN DocumentData.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.BankAccount.Owner
	|	ELSE
	|		DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.Counterparty,
	|	DocumentData.Ref AS Contract,
	|	DocumentData.BankAccount AS BankAccount,
	|	DocumentData.CounterpartyBankAccount AS CounterpartyBankAccount,
	|
	|	CASE WHEN DocumentData.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.BankAccount.CashCurrency
	|	ELSE
	|		DocumentData.ARAPCurrency
	|	END AS Currency,
	|
	|	VALUE(Enum.BusinessTransactions.PaymentToVendor) AS BusinessOperation
	|FROM
	|	Catalog.CounterpartyContracts AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|");
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	FillInDetailsBasedOnRequestResult(DocumentBasis, QueryResult, AmountToPay, FillingData);
	
EndProcedure

Procedure FillInUnderCounterpartySAgreement(Val DocumentBasis, Val AmountToPay, FillingData)
	
	Query = New Query("
	|SELECT
	|	CASE WHEN DocumentData.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.BankAccount.Owner
	|	ELSE
	|		DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.BankAccount AS BankAccount,
	|	DocumentData.CounterpartyBankAccount AS CounterpartyBankAccount,
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
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.ContractType AS ContractType,
	|	VendorsARAPAccounting.BeingPaidBalance - VendorsARAPAccounting.AmountDueBalance AS AmountARAP,
	|	VendorsARAPAccounting.BeingPaidBalance - VendorsARAPAccounting.AmountDueBalance AS Sum,
	|	VendorsARAPAccounting.BeingPaidBalance - VendorsARAPAccounting.AmountDueBalance AS DocumentAmount,
	|	UNDEFINED AS CashAccount,
	|	&Ref AS DocumentBasis,
	|	VendorsARAPAccounting.ARAPObject AS ARAPObject,
	|	DocumentData.Ref AS Contract,
	|	DocumentData.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	DocumentData.CashFlowItem AS CashFlowItem,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.Department AS Department,
	|	
	|	DocumentData.PaymentsAsPer275FZ AS PaymentsAsPer275FZ,
	|	DocumentData.ContractWithSDOParticipant AS ContractWithSDOParticipant,
	|	DocumentData.PaymentType275FZ AS PaymentType275FZ,
	|	DocumentData.ARAPObjectSettings AS ARAPObjectSettings,
	|	DocumentData.PaymentID AS PaymentID
	|	
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
			NStr("vi = 'Không cần nhập chứng từ chi tiền từ tài khoản ngân hàng trên cơ sở hợp đồng %1';
				|ru = 'Не требуется вводить списание безналичных денежных средств на основании договора %1';
				|en = 'It is not required to enter ""Outgoing payment — Bank account"" based on contract %1'; fa = 'It is not required to enter ""Outgoing payment — Bank account"" based on contract %1';
				|it = 'Non è necessario immettere lo storno dei mezzi monetari cashless in base al contratto %1';
				|pl = 'Nie trzeba wprowadzać wyksięgowanie bezgotówkowych środków pieniężnych na podstawie umowy %1';
				|tr = '%1 sözleşmeye dayalı olarak giden ödeme - banka hesabı girilmesi gerekli değildir.'"),
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
		
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(Enums.PaymentForms.BankAccountPayment, FillingData);
		If Selection.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts 
			Or Selection.ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice Then
			ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentUnderContractWithSupplier(
				DocumentBasis, FillingData.Currency, ARAPDetails, Selection.Organization);
		Else
			DecryptionString = ARAPDetails.Add();
			FillPropertyValues(DecryptionString,Selection);
		EndIf;
	EndIf;
	
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure


Procedure FillInByOrderToProcessor2_5(Val DocumentBasis, Val AmountToPay, FillingData)
	
	Query = New Query("
	|SELECT
	|	CASE
	|		WHEN DocumentData.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
	|			THEN DocumentData.BankAccount.Owner
	|		WHEN DocumentData.CashAccount <> VALUE(Catalog.CashAccounts.EmptyRef)
	|			THEN DocumentData.CashAccount.Owner
	|		ELSE DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.Counterparty,
	|	DocumentData.Contract,
	|
	|	CASE
	|		WHEN DocumentData.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
	|			THEN DocumentData.BankAccount
	|		ELSE DocumentData.Contract.BankAccount
	|	END AS BankAccount,
	|	DocumentData.Contract.CounterpartyBankAccount AS CounterpartyBankAccount,
	|	DocumentData.PaymentID AS PaymentID,
	|
	|	CASE
	|		WHEN DocumentData.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
	|			THEN DocumentData.BankAccount.CashCurrency
	|		ELSE ISNULL(DocumentData.Contract.BankAccount.CashCurrency, DocumentData.Currency)
	|	END AS Currency,
	|	&Ref AS DocumentBasis,
	|	VALUE(Enum.BusinessTransactions.PaymentToVendor) AS BusinessOperation,
	|	DocumentData.ARAPObjectSettings AS ARAPObjectSettings
	|FROM
	|	Document.SubcontractOrder2_5 AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|");
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	If Selection.Next()
		And Selection.ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments Then
		
		Text =
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không cần nhập Chi tiền từ tài khoản ngân hàng dựa trên chứng từ %1, bởi vì việc hạch toán được thực hiện ""%2"".';
					|ru = 'Не требуется вводить Списание безналичных ДС на основании документа %1, так как расчеты ведутся ""%2"".';
					|en = 'It is not required to enter ""Outgoing payment — Bank account"" based on the %1 document, as the AR/AP accounting option is ""%2"".'; fa = 'It is not required to enter ""Outgoing payment — Bank account"" based on the %1 document, as the AR/AP accounting option is ""%2"".';
					|it = 'Не требуется вводить Списание безналичных ДС на основании документа %1, так как расчеты ведутся ""%2"".';
					|pl = 'It is not required to enter ""Outgoing payment — Bank account"" based on the %1 document, as the AR/AP accounting option is ""%2"".';
					|tr = '%1 belgesine dayalı ""%2"" giden ödeme - banka hesabı girişi gerekmiyor.'"),
				DocumentBasis,
				Selection.ARAPObjectSettings);
		
		Raise Text;
		
	EndIf;
	
	FillInDetailsBasedOnRequestResult(DocumentBasis, QueryResult, AmountToPay, FillingData);
	
EndProcedure


Procedure FillInReportOfProcessor2_5(Val DocumentBasis, Val AmountToPay, FillingData)
	
	Query = New Query("
	|SELECT
	|	CASE WHEN DocumentData.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.CompanyBankAccount.Owner
	|	ELSE
	|		DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.CompanyBankAccount AS BankAccount,
	|	DocumentData.CounterpartyBankAccount AS CounterpartyBankAccount,
	|	DocumentData.PaymentID AS PaymentID,
	|
	|	CASE WHEN DocumentData.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.CompanyBankAccount.CashCurrency
	|	ELSE
	|		DocumentData.Currency
	|	END AS Currency,
	|	&Ref AS DocumentBasis,
	|	VALUE(Enum.BusinessTransactions.PaymentToVendor) AS BusinessOperation
	|FROM
	|	Document.SubcontractorReport2_5 AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|");
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	FillInDetailsBasedOnRequestResult(DocumentBasis, QueryResult, AmountToPay, FillingData);
	
EndProcedure

Procedure FillInOnReceiptOfRentalServices(Val DocumentBasis, Val AmountToPay, FillingData)
	
	QueryText = Documents.ReceivingLeaseServices.GetTextToFillInBasedOn();
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	FillInDetailsBasedOnRequestResult(DocumentBasis, QueryResult, AmountToPay, FillingData);
	Documents.ReceivingLeaseServices.FillInTranscriptOfReceiptOfRentalServices(ThisObject, QueryResult, FillingData);
	
EndProcedure

Procedure InstructionsForRedemptionOfGoodsAcceptedForStorage(Val DocumentBasis, Val AmountToPay, FillingData)
	
	Query = New Query("
	|SELECT
	|	CASE WHEN DocumentData.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.CompanyBankAccount.Owner
	|	ELSE
	|		DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.CompanyBankAccount AS BankAccount,
	|	DocumentData.CounterpartyBankAccount AS CounterpartyBankAccount,
	|	DocumentData.PaymentID AS PaymentID,
	|
	|	CASE WHEN DocumentData.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.CompanyBankAccount.CashCurrency
	|	ELSE
	|		DocumentData.Currency
	|	END AS Currency,
	|	&Ref AS DocumentBasis,
	|	VALUE(Enum.BusinessTransactions.PaymentToVendor) AS BusinessOperation
	|FROM
	|	Document.RedemptionOfGoodsFromStorage AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref");
	
	Query.SetParameter("Ref", DocumentBasis);
	QueryResult = Query.Execute();
	
	FillInDetailsBasedOnRequestResult(DocumentBasis, QueryResult, AmountToPay, FillingData);
	
EndProcedure

Procedure InstructionsForDebitingGoodsAcceptedForStorage(Val DocumentBasis, Val AmountToPay, FillingData)
	
	Query = New Query("
	|SELECT
	|	CASE WHEN DocumentData.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.CompanyBankAccount.Owner
	|	ELSE
	|		DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.CompanyBankAccount AS BankAccount,
	|	DocumentData.CounterpartyBankAccount AS CounterpartyBankAccount,
	|	DocumentData.PaymentID AS PaymentID,
	|
	|	CASE WHEN DocumentData.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.CompanyBankAccount.CashCurrency
	|	ELSE
	|		DocumentData.Currency
	|	END AS Currency,
	|	&Ref AS DocumentBasis,
	|	VALUE(Enum.BusinessTransactions.PaymentToVendor) AS BusinessOperation
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
	
	FillInDetailsBasedOnRequestResult(DocumentBasis, QueryResult, AmountToPay, FillingData);
	
EndProcedure

Procedure FillByArrayOfBases(FillingData, ArrayOfBases)
	
	CashServer.FillInDetailsOfDocumentOnFormOfPayment(Enums.PaymentForms.BankAccountPayment, FillingData);
	If ValueIsFilled(FillingData.BankAccount) Then
		CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(
			FillingData.Counterparty, FillingData.Currency);
	Else
		CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(
			FillingData.Counterparty);
	EndIf;
	PaymentPurposes =
		Catalogs.CounterpartyBankAccounts.GetBankAccountDetails(CounterpartyBankAccount).PurposeText;
	
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
		And FillingData.Property("Currency")
		And Not ValueIsFilled(FillingData.Currency)
		And Not ValueIsFilled(Currency) Then
		FillingData.Insert("Currency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization));
	EndIf;
	
	If TypeOf(FillingData) <> Type("Structure")
		Or Not FillingData.Property("BankAccount")
		Or Not ValueIsFilled(FillingData.BankAccount) Then
		
		If Not ValueIsFilled(BankAccount) Then
			BankAccount = CashServer.OrganizationSCurrentBankAccount();
		EndIf;
		
		If Not ValueIsFilled(BankAccount) Then
			
			If TypeOf(FillingData) = Type("Structure")
				And FillingData.Property("Organization")
				And FillingData.Property("Currency") Then
			
				ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount();
				ParametersOfAccount.Organization =
					?(ValueIsFilled(FillingData.Organization), FillingData.Organization, Undefined);
				ParametersOfAccount.Currency =
					?(ValueIsFilled(FillingData.Currency), FillingData.Currency, Undefined);
				BankAccount =
					Catalogs.CompaniesBankAccounts.GetDefaultBankAccount(ParametersOfAccount);
			EndIf;
		EndIf;
		
		If ValueIsFilled(BankAccount) Then
			AttributesStructure1 = CashCached.GetCompanySBankAccountDetails(BankAccount);
			If TypeOf(FillingData) = Type("Structure")
				And FillingData.Property("Organization")
				And ValueIsFilled(FillingData.Organization)
				And FillingData.Organization <> AttributesStructure1.Organization Then
				
				BankAccount = Undefined;
			Else
				Organization = AttributesStructure1.Organization;
				Currency = AttributesStructure1.Currency;
			EndIf;
		EndIf;
	EndIf;
	
	If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("Organization") Then
		Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	EndIf;
	
	BankAccountIssueLocalization.ProcessFillingInPayerSAttributes(ThisObject, FillingData);
	
	If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("Currency") Then
		If Not ValueIsFilled(Currency) Then
			Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
		EndIf;
	EndIf;
	
	If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("ProcessedByBank") Then
		ProcessedByBank = ValueIsFilled(PaymentDocumentType) And
			Not (PaymentDocumentType = Enums.TypesOfPaymentDocuments.PaymentOrder
				Or PaymentDocumentType = Enums.TypesOfPaymentDocuments.PaymentDemand);
	Else
		ProcessedByBank = FillingData.ProcessedByBank;
	EndIf;
	
	If TypeOf(FillingData) <> Type("Structure") Then
		If ProcessedByBank Then
			BankPostingDate = CurrentSessionDate();
		EndIf;
	ElsIf Not FillingData.Property("BankPostingDate")
		And FillingData.Property("ProcessedByBank") And FillingData.ProcessedByBank Then
		BankPostingDate = CurrentSessionDate();
	EndIf;
	
	CashServer.FillInCashFlowItem(
		ThisObject,
		FillingData,
		?(ValueIsFilled(BusinessOperation), BusinessOperation, Enums.BusinessTransactions.PaymentToVendor));
	
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

Procedure FillInDetailsBasedOnRequestResult(DocumentBasis, QueryResult, AmountToPay, FillingData, OrganizationOfFilling = Undefined) Export
	
	If QueryResult.IsEmpty() Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhập Chi tiền từ tài khoản ngân hàng trên cơ sở chứng từ %1';
				|ru = 'Не требуется вводить Списание безналичных ДС на основании документа %1';
				|en = 'It is not required to enter ""Outgoing payment — Bank account"" based on document %1'; fa = 'It is not required to enter ""Outgoing payment — Bank account"" based on document %1';
				|it = 'Non è necessario inserire Lo storno dei mezzi monetari cashless in base al documento %1';
				|pl = 'Nie trzeba wprowadzać Wyksięgowanie bezgotówkowych środków pieniężnych na podstawie dokumentu %1';
				|tr = '%1 belgesine dayalı giden ödeme - banka hesabı girişi gerekmiyor'"),
			DocumentBasis);
		Raise Text;
	Else
		FillingData = New Structure;
		For Each Column In QueryResult.Columns Do
			FillingData.Insert(Column.Name);
		EndDo;
		
		FillingData.Insert("PaymentByRequests", False);
		FillingData.Insert("PaymentID");
		
		Selection = QueryResult.Select();
		Selection.Next();
		FillPropertyValues(FillingData, Selection);
		
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(Enums.PaymentForms.BankAccountPayment, FillingData);
		
		If Not ValueIsFilled(FillingData.CounterpartyBankAccount) Then
			
			If ValueIsFilled(FillingData.BankAccount) Then
				CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(
					FillingData.Counterparty, FillingData.Currency, FillingData.BankAccount);
			Else
				CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(
					FillingData.Counterparty);
			EndIf;
			
		EndIf;
		
		PaymentPurposes =
			Catalogs.CounterpartyBankAccounts.GetBankAccountDetails(CounterpartyBankAccount).PurposeText;
		
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
			|	AND NOT GoodsTable.Ref.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
			|	AND NOT GoodsTable.Ref.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)";
			
		ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.SubcontractorReport2_5") Then
			QueryText = 
			"SELECT
			|	Table.SubcontractOrder AS PurchaseOrder
			|FROM
			|	Document.SubcontractorReport2_5 AS Table
			|WHERE
			|	Table.Ref = &Ref
			|	AND Table.ByOrders
			|	AND NOT Table.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
			|	AND NOT Table.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)";
		
		ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.ReceivingLeaseServices") Then
			Return;
		
		ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.CustomerBonusCertificate") Then
			
			PaymentRequest = Documents.PaymentRequest.EmptyRef();
			
			Return;
		
		ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.ApplicationForCollateral") Then
			
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
			ContractDetails_ = Common.ObjectAttributesValues(
				Selection.Contract, "ContractSchedule, PaymentID");
			
			If ValueIsFilled(ContractDetails_.ContractSchedule) Then
				OrdersToSupplier = CommonClientServer.ValueInArray(Selection.Contract);
				OrdersToSupplier.Add(DocumentBasis);
			EndIf;
			
			If Not FillingData.PaymentByRequests
				And Not ValueIsFilled(FillingData.PaymentID) Then
				FillingData.PaymentID = ContractDetails_.PaymentID;
			EndIf;
		EndIf;
		
		ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfOrderPaymentToSupplier(
			OrdersToSupplier,
			Selection.Contract,
			FillingData.Currency,
			AmountToPay,
			ARAPDetails,,
			OrganizationOfFilling);
	EndIf;
	
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure

Procedure FillInLeaseAgreement(Val LeaseContracts, FillingData)

	Query = New Query("
	|SELECT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Ref AS Contract,
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
	
	Query.SetParameter("Ref", LeaseContracts);
	
	QueryResult = Query.Execute();
	
	FillingData = New Structure;
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult.Select();
	Selection.Next();
	FillPropertyValues(FillingData, Selection);
	
	CashServer.FillInDetailsOfDocumentOnFormOfPayment(Enums.PaymentForms.BankAccountPayment, FillingData);
	
	If ValueIsFilled(FillingData.Currency) Then
		CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(
			FillingData.Counterparty, FillingData.Currency);
	Else
		CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(
			FillingData.Counterparty);
	EndIf;
	
	VATTaxation = FillingData.VATTaxation;
	
	AccountAttributes = Catalogs.CounterpartyBankAccounts.GetBankAccountDetails(CounterpartyBankAccount);
	PaymentPurposes = AccountAttributes.PurposeText;
	
	FillPropertyValues(ARAPDetails.Add(), Selection);
	
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure
Procedure FillInOnTheCustomerSOrder(Val DocumentBasis, FillingData)
	
	FillingData = CashServer.GenerateFillInDataForReturningPaymentFromCustomerSOrder(DocumentBasis, ThisObject, Enums.PaymentForms.BankAccountPayment);
	
	CashServer.FillInTranscriptOfPaymentOnClientSOrder(FillingData, ARAPDetails);
	
	PaymentsAsPer275FZ = FillingData.PaymentsAsPer275FZ;	
	DocumentAmount = ARAPDetails.Total("Sum");
	
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
		CurrencyOfComplianceAccounting, ?(ValueIsFilled(BankPostingDate), BankPostingDate, Date), GiftCertificateDetails.ARAPObject);
	NewRow.ExchangeRateNumeratorOfMutualSettlements = CourseAndMultiplicity.CourseNumerator;
	NewRow.TheExchangeRateIsTheDenominatorOfMutualSettlements = CourseAndMultiplicity.CourseDenominator;

	CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
				NewRow, Currency, CurrencyOfComplianceAccounting);
				
EndProcedure

Procedure FillInCertificateOfAwardToClient(Val DocumentBasis, FillingData)
	
	MessageTemplate = NStr("vi = 'Chứng từ %1 có trạng thái ""%2"". Nhập trên cơ sở chỉ cho phép với trạng thái ""Đã nhận"".';
							|ru = 'Документ %1 находится в статусе ""%2"". Ввод на основании разрешен только в статусе ""Получен"".';
							|en = 'The %1 document is in the ""%2"" status. Generation is only allowed from base documents in the ""Received"" status.'; fa = 'The %1 document is in the ""%2"" status. Generation is only allowed from base documents in the ""Received"" status.';
							|it = 'Документ %1 находится в статусе ""%2"". Ввод на основании разрешен только в статусе ""Получен"".';
							|pl = 'The %1 document is in the ""%2"" status. Generation is only allowed from base documents in the ""Received"" status.';
							|tr = '%1 belgesi,  ""%2"" durumundadır. Temellendirmedeki girdiye sadece ""Alındı"" durumunda izin verilir.'");
	
	QueryText = Documents.CustomerBonusCertificate.QueryTextToFillInBasedOnDebitOfNonCashCash();
	
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
	
	FillInDetailsBasedOnRequestResult(DocumentBasis, QueryResult, 0, FillingData);
	Documents.CustomerBonusCertificate.FillInTranscriptOfPaymentWhenEnteringBasedOn(ThisObject, Selection);

EndProcedure

Procedure FillInAccordingToSupplyRequest(Val DocumentBasis, FillingData)

	ApplicationRequestData = Documents.ApplicationForCollateral.DataForPayment(DocumentBasis);
	AmountToPay = 0; // Not used, because the transcript is filled in separately
	FillInDetailsBasedOnRequestResult(DocumentBasis, ApplicationRequestData.HeaderRequestResult, AmountToPay, FillingData);
	Documents.ApplicationForCollateral.FillInPaymentTranscript(ThisObject, ApplicationRequestData);

EndProcedure

#EndRegion

Procedure CheckRepaymentDates(Cancel, FlagEDIWithBanks = False, FillingErrors = "") Export
	
	For Each DecryptionString In ARAPDetails Do
		If ValueIsFilled(DecryptionString.MaturityDate)
			And (Not ProcessedByBank And DecryptionString.MaturityDate < BegOfDay(Date)
				Or ProcessedByBank And DecryptionString.MaturityDate < BegOfDay(BankPostingDate)) Then
			
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

Procedure SetPaymentByRequestFlag(Account)

	OrganizationAccountData =
		CashCached.GetCompanySBankAccountDetails(Account);
	PaymentByRequests = (PaymentByRequests
						Or ?(OrganizationAccountData.EnableCreatingCashIssueWithoutPaymentRequest, False, True))
						And GetFunctionalOption("UsePaymentRequests");

EndProcedure

#EndRegion

#EndIf
