#Region Internal

Procedure PrepareStatementLines(DocumentsToImport, BankAccount, AccountAttributes, ImportSettings) Export
	
	DocumentsToImport.Columns.Add("OnlyOtherRelationships", New TypeDescription("Boolean"));
	DocumentsToImport.Columns.Add("LoanAndDepositAmountType", New TypeDescription("EnumRef.LoanAndDepositScheduleAmountTypes"));
	DocumentsToImport.Columns.Add("ARAPCurrency", New TypeDescription("CatalogRef.Currencies"));
	DocumentsToImport.Columns.Add("ThisIsBankSFee", New TypeDescription("Boolean"));
	DocumentsToImport.Columns.Add("FPSTransactionID", New TypeDescription("String", New StringQualifiers(32)));
	
	TypesOfPaymentDocumentsReceipts = New Map;
	TypesOfPaymentDocumentsReceipts.Insert("PAYMENTORDER", Enums.TypesOfPaymentDocuments.PaymentOrder);
	TypesOfPaymentDocumentsReceipts.Insert("PAYMENTDEMAND", Enums.TypesOfPaymentDocuments.PaymentDemand);
	TypesOfPaymentDocumentsReceipts.Insert("PAYMENTWARRANT", Enums.TypesOfPaymentDocuments.PaymentWarrant);
	TypesOfPaymentDocumentsReceipts.Insert("BANKPAYMENTORDER", Enums.TypesOfPaymentDocuments.PaymentWarrant);
	TypesOfPaymentDocumentsReceipts.Insert("MEMORIALRECORDER", Enums.TypesOfPaymentDocuments.PaymentWarrant);
	TypesOfPaymentDocumentsReceipts.Insert("COLLECTIONORDER_2", Enums.TypesOfPaymentDocuments.CollectionOrder_2);
	
	TypesOfDebitedPaymentDocuments = New Map;
	TypesOfDebitedPaymentDocuments.Insert("PAYMENTORDER", Enums.TypesOfPaymentDocuments.PaymentOrder);
	TypesOfDebitedPaymentDocuments.Insert("PAYMENTDEMAND", Enums.TypesOfPaymentDocuments.PaymentDemand);
	TypesOfDebitedPaymentDocuments.Insert("PAYMENTWARRANT", Enums.TypesOfPaymentDocuments.PaymentWarrant);
	TypesOfDebitedPaymentDocuments.Insert("BANKPAYMENTORDER", Enums.TypesOfPaymentDocuments.BankPaymentOrder);
	TypesOfDebitedPaymentDocuments.Insert("MEMORIALRECORDER", Enums.TypesOfPaymentDocuments.BankPaymentOrder);
	TypesOfDebitedPaymentDocuments.Insert("COLLECTIONORDER_2", Enums.TypesOfPaymentDocuments.CollectionOrder_2);
	
	OwnAccounts = OwnAccounts(BankAccount);
	
	AccountNumber = AccountAttributes.AccountNumber;
	
	For Each DocumentLine In DocumentsToImport Do
		
		If Not DocumentLine.ToImport 
			Or (Not DocumentLine.PayerAccount = AccountNumber
			And Not DocumentLine.BeneficiaryAccount = AccountNumber) Then
			DocumentLine.ToImport = False;
			Continue;
		EndIf;
		
	EndDo;
	
	Filter = New Structure;
	Filter.Insert("ToImport", True);
	LinesToLoad = DocumentsToImport.FindRows(Filter);
	EDIWithBanksLocalization.MarkPaymentsThatAreNotUploaded(LinesToLoad, AccountAttributes);
	
	// Preparation of statement lines to search for documents and counterparties, filling in general details. Primary recognition.
	Filter = New Structure;
	Filter.Insert("ToImport", True);
	PaymentsToUpload = DocumentsToImport.FindRows(Filter);
	
	For Each DocumentLine In PaymentsToUpload Do
		
		// Incoming or outgoing payment
		If DocumentLine.PayerAccount = AccountNumber And DocumentLine.BeneficiaryAccount = AccountNumber Then // if the bank's BIC has changed, but the account number remains the same
			Outgoing = ValueIsFilled(DocumentLine.DepartureDate);
		Else
			Outgoing = (DocumentLine.PayerAccount = AccountNumber);
		EndIf;
		DocumentLine.Outgoing = Outgoing;
		
		// Document date
		If Not ValueIsFilled(DocumentLine.DocDate) Then
			DocumentLine.DocDate = CashClientServer.GetDateFromString(DocumentLine.Date);
			If Not ValueIsFilled(DocumentLine.DocDate) Then
				DocumentLine.DocDate = CashClientServer.GetDateFromString(
					?(Outgoing, DocumentLine.DepartureDate, DocumentLine.ArrivalDate_));
			EndIf;
		EndIf;
		
		// The type of payment document
		TypeAsString = StrReplace(Upper(StrReplace(TrimAll(DocumentLine.Operation), " ", "")), "E__", "E");
		If Outgoing Then
			PaymentDocumentType = TypesOfDebitedPaymentDocuments.Get(TypeAsString);
		Else
			PaymentDocumentType = TypesOfPaymentDocumentsReceipts.Get(TypeAsString);
		EndIf;
		If PaymentDocumentType = Undefined Then
			PaymentDocumentType = Enums.TypesOfPaymentDocuments.PaymentOrder;
		EndIf;

		DocumentLine.PaymentDocumentType = PaymentDocumentType;
		
		// Household. operation by type of payment
		If DocumentLine.PaymentKind_ = "03" Then
			DocumentLine.OperationKind = Enums.BusinessTransactions.WithdrawalFromBankAccount;
			
		ElsIf DocumentLine.PaymentKind_ = "04" Then
			DocumentLine.OperationKind = Enums.BusinessTransactions.CashReceiptFromCashRegisterToBankAccount;
			
		ElsIf DocumentLine.PaymentKind_ = "13" Then
			If Outgoing Then
				DocumentLine.OperationKind = Enums.BusinessTransactions.RefundAcquiringPayment;
			Else
				DocumentLine.OperationKind = Enums.BusinessTransactions.CashRecieptByAcquiringTransactionsPayment;
			EndIf;
		EndIf;
		
		// Transfers
		If DocumentLine.Outgoing Then
			
			If ValueIsFilled(DocumentLine.BeneficiaryBIC) Then
				TheStructureOfTheSearch = New Structure("AccountNumber, BIC", DocumentLine.BeneficiaryAccount, DocumentLine.BeneficiaryBIC);
			ElsIf ValueIsFilled(DocumentLine.BeneficiarySWIFT) Then
				TheStructureOfTheSearch = New Structure("AccountNumber, SWIFT", DocumentLine.BeneficiaryAccount, DocumentLine.BeneficiarySWIFT);
			Else
				TheStructureOfTheSearch = New Structure("AccountNumber", DocumentLine.BeneficiaryAccount);
			EndIf;
			
			OwnAccountsRecipients = OwnAccounts.FindRows(TheStructureOfTheSearch);
			If OwnAccountsRecipients.Count() > 0 Then
				DetailsOfRecipient = OwnAccountsRecipients[0];
				If DetailsOfRecipient.Currency = AccountAttributes.Currency Then
					DocumentLine.OperationKind = Enums.BusinessTransactions.TransferCashToAnotherAccount;
				Else
					DocumentLine.OperationKind = Enums.BusinessTransactions.CurrencyConversion;
					DocumentLine.CurrencyOfConversion = DetailsOfRecipient.Currency;
				EndIf;
				DocumentLine.AccountOfCounterparty = DetailsOfRecipient["Ref"];
				If Not ValueIsFilled(DocumentLine.DepartureDate) Then
					DocumentLine.ToImport = False;
					Continue;
				EndIf;
			EndIf;
		Else
			
			If ValueIsFilled(DocumentLine.PayerBIC) Then
				TheStructureOfTheSearch = New Structure("AccountNumber, BIC", DocumentLine.PayerAccount, DocumentLine.PayerBIC);
			ElsIf ValueIsFilled(DocumentLine.PayerSWIFT) Then
				TheStructureOfTheSearch = New Structure("AccountNumber, SWIFT", DocumentLine.PayerAccount, DocumentLine.PayerSWIFT);
			Else
				TheStructureOfTheSearch = New Structure("AccountNumber", DocumentLine.PayerAccount);
			EndIf;
			
			OwnAccountsSenders = OwnAccounts.FindRows(TheStructureOfTheSearch);
			If OwnAccountsSenders.Count() > 0 Then
				SenderAttributes = OwnAccountsSenders[0];
				If SenderAttributes.Currency = AccountAttributes.Currency Then
					DocumentLine.OperationKind = Enums.BusinessTransactions.CashReceiptFromAnotherAccount;
				Else
					DocumentLine.OperationKind = Enums.BusinessTransactions.CurrencyConversion;
					DocumentLine.CurrencyOfConversion = SenderAttributes.Currency;
				EndIf;
				DocumentLine.AccountOfCounterparty = SenderAttributes["Ref"];
				If Not ValueIsFilled(DocumentLine.ArrivalDate_) Then
					DocumentLine.ToImport = False;
					Continue;
				EndIf;
			EndIf;
		EndIf;
		
		// Collection_
		If Not ValueIsFilled(DocumentLine.OperationKind) Then
			
			BalanceAccount = Left(DocumentLine.PayerAccount, 5);
			If BalanceAccount    = "20202" // receipt/withdrawal of cash from the cash register
				Or BalanceAccount = "20208" // receipt/withdrawal of cash from an ATM, Cash-in device
			Then
				If DocumentLine.Outgoing Then
					DocumentLine.OperationKind = Enums.BusinessTransactions.WithdrawalFromBankAccount;
				Else
					DocumentLine.OperationKind = Enums.BusinessTransactions.CashReceiptFromCashRegisterToBankAccount;
				EndIf;
			EndIf;
		EndIf;
		
		// Counterparty
		If Outgoing Then
			If DocumentLine.Recipient1 <> "" Then
				DocumentLine.NameOfCounterparty = DocumentLine.Recipient1;
			Else
				DocumentLine.NameOfCounterparty = DocumentLine.Recipient;
			EndIf;
		Else
			If DocumentLine.Payer1 <> "" Then
				DocumentLine.NameOfCounterparty = DocumentLine.Payer1;
			Else
				DocumentLine.NameOfCounterparty = DocumentLine.Payer;
			EndIf;
		EndIf;
		
		EDIWithBanksLocalization.FillInDetailsOfPaymentCounterparty(Outgoing, DocumentLine, DocumentLine.NameOfCounterparty);
		
		NameStructure_1 = CashServerLocalization.CompanyName(DocumentLine.NameOfCounterparty);
		DocumentLine.AbbreviatedCounterpartyName = NameStructure_1.NameAbbreviated;
		
		If StringFunctionsClientServer.OnlyNumbersInString(Left(DocumentLine.NameOfCounterparty, 10)) Then
			If StringFunctionsClientServer.OnlyNumbersInString(Left(DocumentLine.NameOfCounterparty, 12)) Then
				DocumentLine.NameOfCounterparty = TrimAll(Mid(DocumentLine.NameOfCounterparty, 13));
			Else
				DocumentLine.NameOfCounterparty = TrimAll(Mid(DocumentLine.NameOfCounterparty, 11));
			EndIf;
		EndIf;
		
		SearchInn = ?(Outgoing, DocumentLine.BeneficiaryTIN, DocumentLine.PayerTIN);
		DocumentLine.CheckTIN = ValueIsFilled(SearchInn)
										And SearchInn <> "000000000000"
										And SearchInn <> "0000000000"
										And SearchInn <> "0";
	
		SearchCheckpoint = ?(Outgoing, DocumentLine.BeneficiaryCRTR, DocumentLine.KPPPayer);
		DocumentLine.CheckCRTR = (ValueIsFilled(SearchCheckpoint) And SearchCheckpoint <> "0");
		
		// UIP
		If ValueIsFilled(DocumentLine.Code)
			And DocumentLine.Code <> "0" Then
			DocumentLine.UIPIsFilledIn = True;
		EndIf;
		
		// Purpose of payment
		If IsBlankString(DocumentLine.PaymentPurposes) Then
			DocumentLine.PaymentPurposes = DocumentLine.PaymentPurposes1;
			For Indus = 2 To 6 Do
				If Not ValueIsFilled(DocumentLine["PaymentPurposes" + Indus]) Then
					Break;
				EndIf;
				DocumentLine.PaymentPurposes =
					DocumentLine.PaymentPurposes + Chars.LF + DocumentLine["PaymentPurposes" + Indus];
			EndDo;
		EndIf;
		
		DocumentLine.FormattedPurposeOfPayment =
			CashServer.FormatPaymentPurpose(DocumentLine.PaymentPurposes);
		
		// Sum
		ListOfAmounts = StrSplit(DocumentLine.Sum, "+");
		
		For Each CurrentAmount In ListOfAmounts Do
			
			Sum = StringFunctionsClientServer.StringToNumber(CurrentAmount);
			If Sum <> Undefined Then
				If Sum < 0 Then
					Sum = - Sum;
				EndIf;
				DocumentLine.DocumentAmount = DocumentLine.DocumentAmount + Sum;
				If Outgoing Then
					DocumentLine.AmountCredited   = DocumentLine.AmountCredited + Sum;
				Else
					DocumentLine.ReceivedAmount = DocumentLine.ReceivedAmount + Sum;
				EndIf;
			Else
				AddRemark(DocumentLine.ImportErrors,
					StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Số lượng chứng từ không hợp lệ (%1)!';
							|ru = 'Неверная сумма документа (%1)!';
							|en = 'Incorrect document amount (%1).'; fa = 'Incorrect document amount (%1).';
							|it = 'Неверная сумма документа (%1)!';
							|pl = 'Nieprawidłowa wartość dokumentu (%1)!';
							|tr = 'Belgenin yanlış değeri (%1)!'"), DocumentLine.Sum));
			EndIf;
		
		EndDo;
		
		// Date of the event by the Bank
		If Outgoing Then
			If Not ValueIsFilled(DocumentLine.WrittenOff) Then
				
				If ValueIsFilled(DocumentLine.DepartureDate) Then
					DocumentLine.WrittenOff = CashClientServer.GetDateFromString(
						DocumentLine.DepartureDate);
				Else
					DocumentLine.WrittenOff = CashClientServer.GetDateFromString(
						DocumentLine.Date);
				EndIf;
				
				If ValueIsFilled(DocumentLine.WrittenOff) Then
					DocumentLine.ProcessingDate = DocumentLine.WrittenOff;
				EndIf;
			EndIf;
		Else
			If Not ValueIsFilled(DocumentLine.Received) Then
				
				If ValueIsFilled(DocumentLine.ArrivalDate_) Then
					DocumentLine.Received = CashClientServer.GetDateFromString(
						DocumentLine.ArrivalDate_);
				Else
					DocumentLine.Received = CashClientServer.GetDateFromString(
						DocumentLine.Date);
				EndIf;
				
				If ValueIsFilled(DocumentLine.Received) Then
					DocumentLine.ProcessingDate = DocumentLine.Received;
				EndIf;
			EndIf;
		EndIf;
		
	EndDo;
	
	EDIWithBanksLocalization.PrepareStatementLines(DocumentsToImport, BankAccount, AccountAttributes, ImportSettings);
	
	// Previously uploaded/manually entered documents
	Filter = New Structure;
	Filter.Insert("ToImport", True);
	LinesToLoad = DocumentsToImport.FindRows(Filter);
	DocumentsTable = DocumentsToImport.Copy(
		LinesToLoad,
		"LineNumber, DocDate, Received, WrittenOff, Number, ShortNumber, Outgoing, BeneficiaryAccount, PayerAccount, PaymentDocumentType,
		|BeneficiaryTIN, PayerTIN, BeneficiaryCRTR, KPPPayer, CheckTIN, CheckCRTR, StatementData, Code, Operation,
		|ThisIsBankFeedsImport, FPSTransactionID, DocumentAmount");
	FillInLinksToDocuments(DocumentsToImport, DocumentsTable, BankAccount);
	
	// The basis of the payment under the UIP
	Filter = New Structure;
	Filter.Insert("ToImport", True);
	Filter.Insert("UIPIsFilledIn", True);
	LinesToLoad = DocumentsToImport.FindRows(Filter);
	If LinesToLoad.Count() Then
		DocumentsTable = DocumentsToImport.Copy(LinesToLoad, "LineNumber, Code, Outgoing");
		FillInBasisOfPaymentsForUIP(DocumentsToImport, DocumentsTable, BankAccount);
	EndIf;
	
	// Counterparties, counterparty accounts
	Filter = New Structure;
	Filter.Insert("ToImport", True);
	LinesToLoad = DocumentsToImport.FindRows(Filter);
	DocumentsTable = DocumentsToImport.Copy(
		LinesToLoad,
		"LineNumber, Outgoing, NameOfCounterparty, AbbreviatedCounterpartyName, Counterparty, BeneficiaryAccount, BeneficiaryBIC, PayerAccount, PayerBIC,
		|BeneficiaryTIN, PayerTIN, BeneficiaryCRTR, KPPPayer, CheckTIN, CheckCRTR, OperationKind");
	ListOfCounterparties(DocumentsToImport, DocumentsTable);
	
	// Partners
	Filter = New Structure;
	Filter.Insert("ToImport", True);
	Filter.Insert("CounterpartyIsFound", True);
	LinesToLoad = DocumentsToImport.FindRows(Filter);
	DocumentsTable = DocumentsToImport.Copy(
		LinesToLoad,
		"LineNumber, Counterparty, Partner");
	FillOutPartners(DocumentsToImport, DocumentsTable, BankAccount);
	
	// Filling in the bank fee of operation
	Filter = New Structure;
	Filter.Insert("ThisIsBankSFee", True);
	Filter.Insert("CounterpartyIsFound", True);
	Filter.Insert("PaymentBasisIsFound", False);
	LinesToLoad = DocumentsToImport.FindRows(Filter);
	EDIWithBanksLocalization.FillInBankSFeeTransaction(AccountAttributes.Organization, BankAccount, LinesToLoad);
	
	// Sample documents to fill out
	Filter = New Structure;
	Filter.Insert("ToImport", True);
	Filter.Insert("PaymentBasisIsFound", False);
	Filter.Insert("CounterpartyAccountIsFound", True);
	LinesToLoad = DocumentsToImport.FindRows(Filter);
	FillInSamples(LinesToLoad, BankAccount);
	
	// Filling in by indirect data
	Filter = New Structure;
	Filter.Insert("ToImport", True);
	Filter.Insert("PaymentBasisIsFound", False);
	Filter.Insert("CounterpartyIsFound", True);
	LinesToLoad = DocumentsToImport.FindRows(Filter);
	FillInIndirectData(LinesToLoad, BankAccount);
	
	// Filling of operation "Other receipt" or "Other expense"
	Filter = New Structure;
	Filter.Insert("ToImport", True);
	Filter.Insert("CounterpartyIsFound", True);
	Filter.Insert("OnlyOtherRelationships", True);
	Filter.Insert("OperationKind", Enums.BusinessTransactions.EmptyRef());
	LinesToLoad = DocumentsToImport.FindRows(Filter);
	FillInOtherReceiptExpense(LinesToLoad);
	
	// Search for PKO during collection
	Filter = New Structure;
	Filter.Insert("ToImport", True);
	Filter.Insert("DocumentIsFoundInBase", False);
	Filter.Insert("PaymentBasisIsFound", False);
	Filter.Insert("FoundSample", False);
	Filter.Insert("OperationKind", Enums.BusinessTransactions.WithdrawalFromBankAccount);
	LinesToLoad = DocumentsToImport.FindRows(Filter);
	DocumentsTable = DocumentsToImport.Copy(
		LinesToLoad,
		"LineNumber, DocumentAmount, ProcessingDate");
	FillInCashDocument(DocumentsToImport, DocumentsTable, BankAccount, True);
	
	// Search for RKO during collection
	Filter = New Structure;
	Filter.Insert("ToImport", True);
	Filter.Insert("DocumentIsFoundInBase", False);
	Filter.Insert("PaymentBasisIsFound", False);
	Filter.Insert("FoundSample", False);
	Filter.Insert("OperationKind", Enums.BusinessTransactions.CashReceiptFromCashRegisterToBankAccount);
	LinesToLoad = DocumentsToImport.FindRows(Filter);
	DocumentsTable = DocumentsToImport.Copy(
		LinesToLoad,
		"LineNumber, DocumentAmount, ProcessingDate");
	FillInCashDocument(DocumentsToImport, DocumentsTable, BankAccount, False);
	
	// Filling in the business of operation by default
	Filter = New Structure;
	Filter.Insert("ToImport", True);
	Filter.Insert("OperationKind", Enums.BusinessTransactions.EmptyRef());
	LinesToLoad = DocumentsToImport.FindRows(Filter);
	FillInDefaultOfOperationView(LinesToLoad);
	
	// Filling in the default Cash RegisterRecorded Item
	Filter = New Structure;
	Filter.Insert("ToImport", True);
	LinesToLoad = DocumentsToImport.FindRows(Filter);
	AddCashFlowArticlesToUploadSettings(LinesToLoad, ImportSettings);
	FillInCashFlowItems(LinesToLoad, ImportSettings.ArticlesOfCashFlowOfOperations);
	
EndProcedure

Procedure UpdateDocuments(DocumentsToImport, BankAccount, ImportSettings) Export
	
	Var DetailsAll, DetailsOfBusinessTransaction;
	
	Filter = New Structure("BankAccount, ToImport, DocumentIsFoundInBase",
		BankAccount, True, True);
	LinesToLoad = DocumentsToImport.FindRows(Filter);
	
	If LinesToLoad.Count() = 0 Then
		Return;
	EndIf;
	
	CreateCounterparties = ImportSettings.CreateCounterparties;
	PostDocuments = ImportSettings.PostDocuments;
	
	ClearTableOfCashFlowArticles = False;
	
	If ImportSettings.ArticlesOfCashFlowOfOperations = Undefined Then
		
		AddCashFlowArticlesToUploadSettings(LinesToLoad, ImportSettings);
		ClearTableOfCashFlowArticles = True;
		
	EndIf;
	
	For Each DocumentLine In LinesToLoad Do
		
		DocumentObject = DocumentLine.Document.GetObject();
		
		MakeUnverified = False;
		
		CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(DocumentObject.Organization);
		
		Filter = New Structure("BusinessOperation", DocumentObject.BusinessOperation);
		AvailableCashFlowArticles = ImportSettings.ArticlesOfCashFlowOfOperations.Copy(Filter).UnloadColumn("CashFlowItem");
		
		SetProperty(DocumentObject, "ProcessedByBank", True);
		SetProperty(DocumentObject, "BankPostingDate", DocumentLine.ProcessingDate);
		
		ReplaceOldValue = Not EDIWithBanksLocalization.ThisIsPaymentOperationThroughOnlineService(DocumentLine.Operation);
		
		SetProperty(DocumentObject, "IncomingDocumentNumber", DocumentLine.Number, ReplaceOldValue);
		
		If TypeOf(DocumentObject) = Type("DocumentObject.BankAccountReceiptNote") Then
			Documents.BankAccountReceiptNote.FillInNamesOfBusinessTransactionDetails(
				DocumentObject, DetailsAll, DetailsOfBusinessTransaction);
				
		ElsIf TypeOf(DocumentObject) = Type("DocumentObject.BankAccountIssue") Then
			Documents.BankAccountIssue.FillInNamesOfBusinessTransactionDetails(
				DocumentObject, DetailsAll, DetailsOfBusinessTransaction);
		EndIf;
		
		// Counterparty
		If DetailsOfBusinessTransaction.Find("Counterparty") <> Undefined And Not ValueIsFilled(DocumentObject.Counterparty) Then
			If ValueIsFilled(DocumentLine.Counterparty) Then
				SetProperty(DocumentObject, "Counterparty", DocumentLine.Counterparty);
			ElsIf CreateCounterparties And DocumentLine.CreateCounterparty Then
				SetProperty(DocumentObject, "Counterparty", CreateCounterparty(DocumentsToImport, DocumentLine));
			Else
				SetProperty(DocumentObject, "NameOfCounterparty", DocumentLine.NameOfCounterparty);
			EndIf;
		EndIf;
		
		// The account of the counterparty
		If DetailsOfBusinessTransaction.Find("CounterpartyBankAccount") <> Undefined And Not ValueIsFilled(DocumentObject.CounterpartyBankAccount) Then
			If ValueIsFilled(DocumentLine.AccountOfCounterparty) Then
				SetProperty(DocumentObject, "CounterpartyBankAccount", DocumentLine.AccountOfCounterparty);
			ElsIf ValueIsFilled(DocumentObject.Counterparty) Then
				SetProperty(DocumentObject, "CounterpartyBankAccount",
				CreateCounterpartySBankAccount(DocumentsToImport, DocumentLine, DocumentObject.Counterparty));
			EndIf;
		EndIf;
		
		AmountsVary = (DocumentLine.DocumentAmount <> DocumentObject.DocumentAmount);
		
		If TypeOf(DocumentObject) = Type("DocumentObject.BankAccountIssue")
			And DocumentObject.PaymentWithConversion Then
			SetProperty(DocumentObject, "AmountInPayerSCurrency", DocumentLine.DocumentAmount, True);
		Else
			SetProperty(DocumentObject, "DocumentAmount", DocumentLine.DocumentAmount, True);
		EndIf;
		
		If AmountsVary
			And DocumentObject.ARAPDetails.Count() <> 1 Then
			
			DocumentObject.ARAPDetails.Clear();
			
			If DocumentLine.Outgoing Then
				FillInDecryptionOfWriteOff(DocumentLine, DocumentObject, DetailsOfBusinessTransaction, ImportSettings, AvailableCashFlowArticles);
			Else
				FillInReceiptTranscript(DocumentLine, DocumentObject, DetailsOfBusinessTransaction, ImportSettings, AvailableCashFlowArticles);
			EndIf;
			
		Else
			
			CashFlowItem = OnlyCashFlowItemFromList(AvailableCashFlowArticles);
			
			For Each DecryptionString In DocumentObject.ARAPDetails Do
				
				// Partner
				If Not ValueIsFilled(DecryptionString.Partner)
					And DetailsOfBusinessTransaction.Find("ARAPDetails.Partner") <> Undefined Then
					DecryptionString.Partner = DocumentLine.Partner;
				EndIf;
				
				If DecryptionString.ExchangeRateNumeratorOfMutualSettlements = 0
					Or DecryptionString.TheExchangeRateIsTheDenominatorOfMutualSettlements = 0 Then
					ProcessingOfExchangeRatesTM.FillInDefaultDocumentCourse(DecryptionString.ExchangeRateNumeratorOfMutualSettlements,
																			DecryptionString.TheExchangeRateIsTheDenominatorOfMutualSettlements,
																			DocumentObject.Currency,
																			DecryptionString.ARAPCurrency,
																			DocumentObject.Organization,
																			?(ValueIsFilled(DocumentLine.ProcessingDate), DocumentLine.ProcessingDate, DocumentObject.Date),,
																			DecryptionString.ARAPObject);
				EndIf;
				
				// DDS article
				If DetailsOfBusinessTransaction.Find("ARAPDetails.CashFlowItem") <> Undefined
					And Not ValueIsFilled(DecryptionString.CashFlowItem) Then
					
					If ValueIsFilled(DecryptionString.ARAPObject) Then
						
						APARObjectDetails = Common.ObjectAttributesValues(
										DecryptionString.ARAPObject,
										"Contract.CashFlowItem, Terms.CashFlowItem");
						
						ArticleOfCashFlowOfSettlementObject = 
							?(ValueIsFilled(APARObjectDetails.CashFlowContract),
							APARObjectDetails.CashFlowContract,
							APARObjectDetails.CashFlowAgreement);
						
						If ValueIsFilled(ArticleOfCashFlowOfSettlementObject) Then
							DecryptionString.CashFlowItem =
								?(ValueIsFilled(APARObjectDetails.CashFlowContract),
								APARObjectDetails.CashFlowContract,
								APARObjectDetails.CashFlowAgreement);
						EndIf;
						
					EndIf;
					
					If Not ValueIsFilled(DecryptionString.CashFlowItem)
						And ValueIsFilled(CashFlowItem) Then
						DecryptionString.CashFlowItem = CashFlowItem;
					EndIf;
					
				EndIf;
				
			EndDo;
			
			If AmountsVary
				And DocumentObject.ARAPDetails.Count() = 1 Then
				
				DecryptionString = DocumentObject.ARAPDetails[0];
				DecryptionString.Sum = DocumentObject.DocumentAmount;
				
				CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
					DecryptionString, DocumentObject.Currency, CurrencyOfComplianceAccounting);
					
				StructureOfRecalculationOfAmount = New Structure;
				StructureOfRecalculationOfAmount.Insert("PriceIncludesVAT", True);
				StructureOfActions = New Structure;
				StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
				BatchProcessingOfTablePartServer.ProcessTSString(DecryptionString, StructureOfActions, Undefined);
				
			EndIf;
			
		EndIf;
		
		SetProperty(DocumentObject, "PaymentPurposes", DocumentLine.PaymentPurposes, True);
		SetProperty(DocumentObject, "FormattedPurposeOfPayment", DocumentLine.FormattedPurposeOfPayment, True);
		SetProperty(DocumentObject, "StatementData", DocumentLine.StatementData, True);
		
		SetProperty(DocumentObject, "Comment", DocumentLine.Comment);
		
		If DocumentObject.Modified() Then
			SetProperty(DocumentObject, "ImportDate", CurrentSessionDate(), True);
		EndIf;
		
		DocumentObject.AdditionalProperties.Insert("EDIWithBanks", True);
		DocumentObject.RegisterRecords.BankAccountCash.AdditionalProperties.Insert("EDIWithBanks", True);
		DocumentObject.CheckFilling();
		
		If DocumentObject.AdditionalProperties.Property("FillingErrors") Then
			SetProperty(DocumentObject, "ImportErrors", DocumentObject.AdditionalProperties.FillingErrors, True);
		EndIf;
		
		If PostDocuments
			And TrimAll(DocumentObject.ImportErrors) = "" Then
			WriteMode = DocumentWriteMode.Posting;
		Else
			
			WriteMode = DocumentWriteMode.Write;
			
			If TrimAll(DocumentObject.ImportErrors) <> "" Then
				MakeUnverified = DocumentObject.Posted;
			EndIf;
			
		EndIf;
		
		If AmountsVary Then
			AddRemark(DocumentLine.ImportErrors, NStr("vi = 'Đã thay đổi số tiền chứng từ';
														|ru = 'Изменилась сумма документа';
														|en = 'The document amount has changed'; fa = 'The document amount has changed';
														|it = 'Изменилась сумма документа';
														|pl = 'The document amount has changed';
														|tr = 'Belge tutarı değiştirildi'"));
		EndIf;
		
		WriteObject(DocumentObject, ?(MakeUnverified, DocumentWriteMode.UndoPosting, WriteMode), DocumentLine);
	EndDo;
	
	If ClearTableOfCashFlowArticles Then
		ImportSettings.ArticlesOfCashFlowOfOperations = Undefined;
	EndIf;
	
EndProcedure

Procedure CreateDocuments(DocumentsToImport, BankAccount, ImportSettings) Export
	
	AccountAttributes = Catalogs.CompaniesBankAccounts.GetCompanySBankAccountDetails(BankAccount);
	EnableCreatingCashIssueWithoutPaymentRequest = AccountAttributes.EnableCreatingCashIssueWithoutPaymentRequest;
	
	Organization          = AccountAttributes.Organization;
	Prefix              = Common.ObjectAttributeValue(Organization, "Prefix");
	Currency               = AccountAttributes.Currency;
	CurrentUser  = Users.CurrentUser();
	
	Filter = New Structure("BankAccount, ToImport, DocumentIsFoundInBase",
		BankAccount, True, False);
	LinesToLoad = DocumentsToImport.FindRows(Filter);
	
	If LinesToLoad.Count() = 0 Then
		Return;
	EndIf;
	
	PostDocuments = ImportSettings.PostDocuments;
	BalancesOfApplications = Undefined;
	
	If GetFunctionalOption("UsePaymentRequests")
		And Not EnableCreatingCashIssueWithoutPaymentRequest Then
		BalancesOfApplications = BalancesOfPaymentRequestsOnInvoice(BankAccount, AccountAttributes);
	EndIf;
	
	If ImportSettings.ArticlesOfCashFlowOfOperations = Undefined Then
		AddCashFlowArticlesToUploadSettings(LinesToLoad, ImportSettings);
	EndIf;
	
	For Each DocumentLine In LinesToLoad Do
		
		If DocumentLine.Outgoing Then
			DocumentObject = Documents.BankAccountIssue.CreateDocument();
		Else
			DocumentObject = Documents.BankAccountReceiptNote.CreateDocument();
		EndIf;
		
		// General banking details
		DateOfDocumentEntry = CashClientServer.GetDateFromString(DocumentLine.Date);
		If ValueIsFilled(DateOfDocumentEntry) Then
			SetProperty(DocumentObject, "IncomingDocumentDate", DateOfDocumentEntry);
		Else
			SetProperty(DocumentObject, "IncomingDocumentDate", DocumentLine.DocDate);
		EndIf;
		SetProperty(DocumentObject, "IncomingDocumentNumber", DocumentLine.Number);
		
		SetProperty(DocumentObject, "Organization", Organization);
		SetProperty(DocumentObject, "BankAccount", BankAccount);
		SetProperty(DocumentObject, "Currency", Currency);
		
		SetProperty(DocumentObject, "BusinessOperation", DocumentLine.OperationKind);
		SetProperty(DocumentObject, "PaymentDocumentType", DocumentLine.PaymentDocumentType);
		SetProperty(DocumentObject, "DocumentAmount", DocumentLine.DocumentAmount);
		
		SetProperty(DocumentObject, "PaymentPurposes", DocumentLine.PaymentPurposes);
		SetProperty(DocumentObject, "FormattedPurposeOfPayment", DocumentLine.FormattedPurposeOfPayment);
		SetProperty(DocumentObject, "StatementData", DocumentLine.StatementData);
		SetProperty(DocumentObject, "PaymentID", DocumentLine.Code);
		
		SetProperty(DocumentObject, "Comment", DocumentLine.Comment);
		SetProperty(DocumentObject, "ImportDate", CurrentSessionDate());
		
		SetProperty(DocumentObject, "TaxType", DocumentLine.TaxType);
		SetProperty(DocumentObject, "GLAccountSettings", DocumentLine.GLAccountSettings);
		
		SetProperty(DocumentObject, "ImportErrors", DocumentLine.ImportErrors);
		
		SetProperty(DocumentObject, "EmployeeResponsible", CurrentUser);
		
		SetProperty(DocumentObject, "Date", DocumentObject.IncomingDocumentDate);
		
		If BegOfDay(DocumentObject.Date) = BegOfDay(CurrentSessionDate()) Then
			DocumentObject.Date = CurrentSessionDate();
		Else
			DocumentObject.Date = EndOfDay(DocumentObject.Date);
		EndIf;
		
		SetProperty(DocumentObject, "CurrencyOfConversion", DocumentLine.CurrencyOfConversion);
		CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(DocumentObject.Organization);
		
		If ValueIsFilled(DocumentObject.CurrencyOfConversion) Then
			CashServer.RecalculateConversionParameters(DocumentObject, CurrencyOfComplianceAccounting, "CurrencyOfConversion");
		EndIf;
		
		// Taxation of operation by default
		CashServer.FillInTaxationOfVATOnSalesPurchases(DocumentObject, DocumentObject.VATTaxation);
		
		// Individual filling
		If DocumentLine.Outgoing Then
			FillInDebitDetails(DocumentsToImport, DocumentLine, DocumentObject, ImportSettings, Prefix);
			PickUpPaymentRequests(BalancesOfApplications, DocumentLine, DocumentObject);
		Else
			FillInReceiptDetails(DocumentsToImport, DocumentLine, DocumentObject, ImportSettings);
		EndIf;
		
		If Not EDIWithBanksLocalization.ThisIsPaymentOperationThroughOnlineService(DocumentLine.Operation) Then
			SetProperty(DocumentObject, "ProcessedByBank", True);
		EndIf;
		
		If ValueIsFilled(DocumentLine.ProcessingDate) Then
			SetProperty(DocumentObject, "BankPostingDate", DocumentLine.ProcessingDate);
		Else
			SetProperty(DocumentObject, "BankPostingDate", DocumentObject.Date);
		EndIf;
		
		If Not ValueIsFilled(DocumentObject.IncomingDocumentDate) Then
			DocumentObject.IncomingDocumentDate = DocumentObject.Date;
		EndIf;
		If Not ValueIsFilled(DocumentObject.IncomingDocumentNumber) Then
			DocumentObject.IncomingDocumentNumber = ObjectsPrefixesClientServer.NumberForPrinting(DocumentObject.Number);
		EndIf;
		
		DocumentObject.AdditionalProperties.Insert("EDIWithBanks", True);
		DocumentObject.RegisterRecords.BankAccountCash.AdditionalProperties.Insert("EDIWithBanks", True);
		DocumentObject.CheckFilling();
		
		If DocumentObject.AdditionalProperties.Property("FillingErrors") Then
			DocumentObject.ImportErrors = TrimAll(DocumentObject.ImportErrors + "
			|" + DocumentObject.AdditionalProperties.FillingErrors);
		EndIf;
		
		If PostDocuments
			And TrimAll(DocumentObject.ImportErrors) = "" Then
			WriteMode = DocumentWriteMode.Posting;
		Else
			WriteMode = DocumentWriteMode.Write;
		EndIf;
		
		If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany 
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany Then
			If DocumentLine.Outgoing Then
				InvertedPaymentReference = Documents.BankAccountIssue.FindMirrorPayment(DocumentObject);
				If ValueIsFilled(InvertedPaymentReference) And InvertedPaymentReference.DocumentAmount = DocumentObject.DocumentAmount Then
					Documents.BankAccountReceiptNote.AlignMirrorPayment(InvertedPaymentReference, DocumentObject);
				EndIf;
			Else
				InvertedPaymentReference = Documents.BankAccountReceiptNote.FindMirrorPayment(DocumentObject);
				If ValueIsFilled(InvertedPaymentReference) And InvertedPaymentReference.DocumentAmount = DocumentObject.DocumentAmount Then
					Documents.BankAccountIssue.AlignMirrorPayment(InvertedPaymentReference, DocumentObject);
				EndIf;
			EndIf;
		EndIf;
		
		WriteObject(DocumentObject, WriteMode, DocumentLine);
		
		DocumentLine.Document = DocumentObject.Ref;
	EndDo;
	
EndProcedure

// Creates an element of the "Contractors" reference list"
//
// Parameters:
//    DocumentsToImport - ValueTable - Statement document table
//    DocumentLine - ValueTableRow - Contains a description of the counterparty and related data.
//
// Returns:
//    CatalogRef.Counterparties - A link to a new directory item.
//
Function CreateCounterparty(DocumentsToImport, DocumentLine) Export
	
	SetPrivilegedMode(True);
	
	If DocumentLine.Outgoing Then
		
		ColumnNameColumnName = "RecipientInternationalName";
		TinColumnName    = "BENEFICIARYTIN";
		NameOfCheckpointColumn    = "BENEFICIARYCRTR";
		ColumnNameCountry = "RecipientCountry";
		
	Else
		
		ColumnNameColumnName = "PayerInternationalName";
		TinColumnName = "PAYERTIN";
		NameOfCheckpointColumn = "KPPPAYER";
		ColumnNameCountry = "PayerCountry";	
		
	EndIf;
	
	NameStructure_1 = CashServerLocalization.CompanyName(DocumentLine.NameOfCounterparty);
	
	CounterpartyData = AttributesOfCounterparty();
	PartnerData = PartnerSAttributesForFillingInForm();
	
	CounterpartyData.Insert("Description", NameStructure_1.NameAbbreviated);
	CounterpartyData.Insert("DescriptionFull", DocumentLine.NameOfCounterparty);
	CounterpartyData.Insert("DescriptionInternational", DocumentLine[ColumnNameColumnName]);
	CounterpartyData.Insert("TIN", ?(DocumentLine[TinColumnName] = "000000000000" Or DocumentLine[TinColumnName] = "0000000000",
										"",
										DocumentLine[TinColumnName]));
	CounterpartyData.Insert("CRTR", ?(DocumentLine[NameOfCheckpointColumn] = "0", "", DocumentLine[NameOfCheckpointColumn]));
	CounterpartyData.Insert("RegistrationCountry", Catalogs.WorldCountries.FindByAttribute("CodeAlpha2", DocumentLine[ColumnNameCountry]));
	
	MainCountry = Constants.MainCountry.Get();
	If Not ValueIsFilled(CounterpartyData.RegistrationCountry) Then
		CounterpartyData.Insert("RegistrationCountry", MainCountry);
	EndIf;
	
	If StrLen(CounterpartyData.TIN) = 10
			Or DocumentLine.ThisIsBankFeedsImport Then
		CounterpartyData.Insert("LegalEntityIndividual", Enums.LegalEntityIndividual.Entity);
	ElsIf ValueIsFilled(CounterpartyData.RegistrationCountry)
		And CounterpartyData.RegistrationCountry <> MainCountry Then
		CounterpartyData.Insert("LegalEntityIndividual", Enums.LegalEntityIndividual.LegalEntityNonResident);
	Else
		
		If DocumentLine.ItSPhysical Then
			CounterpartyData.Insert("LegalEntityIndividual", Enums.LegalEntityIndividual.Person);
			PartnerData.Insert("LegalEntityIndividual", Enums.IndividualCompany.Person_);
		Else
			CounterpartyData.Insert("LegalEntityIndividual", Enums.LegalEntityIndividual.IndividualEntrepreneur);
		EndIf;
		
	EndIf;
	
	FillPropertyValues(PartnerData, CounterpartyData, , "LegalEntityIndividual");
	
	If ValueIsFilled(DocumentLine.Counterparty) Then
		Return DocumentLine.Counterparty;
	EndIf;
	
	CounterpartyDetails_ = FindCreateCounterparty(DocumentLine, CounterpartyData, PartnerData);
	
	DocumentLine.Counterparty = CounterpartyDetails_.Counterparty;
	DocumentLine.Partner = CounterpartyDetails_.Partner;
	
	// You need to substitute a new counterparty and partner in other lines of the statement
	If Not IsBlankString(CounterpartyData.TIN) Then
		
		FilterFields = "BankAccount, BENEFICIARYTIN, Outgoing";
		TheStructureOfTheSearch = New Structure(
			FilterFields, DocumentLine.BankAccount, CounterpartyData.TIN, True);
		FillInCounterpartyInUploadDocuments(
			CounterpartyDetails_.Counterparty, CounterpartyDetails_.Partner, DocumentsToImport, TheStructureOfTheSearch);
		
		FilterFields = "BankAccount, PAYERTIN, Outgoing";
		TheStructureOfTheSearch = New Structure(
			FilterFields, DocumentLine.BankAccount, CounterpartyData.TIN, False);
		FillInCounterpartyInUploadDocuments(
			CounterpartyDetails_.Counterparty, CounterpartyDetails_.Partner, DocumentsToImport, TheStructureOfTheSearch);
		
	Else
		
		FilterFields = "BankAccount, NameOfCounterparty";
		TheStructureOfTheSearch = New Structure(
			FilterFields, DocumentLine.BankAccount, DocumentLine.NameOfCounterparty);
		FillInCounterpartyInUploadDocuments(
			CounterpartyDetails_.Counterparty, CounterpartyDetails_.Partner, DocumentsToImport, TheStructureOfTheSearch);
		
	EndIf;
	
	Return CounterpartyDetails_.Counterparty;
	
EndFunction

// Creates an element of the reference list " bankaccounts of Counterparties"
//
// Parameters:
//    DocumentsToImport - ValueTable - Statement document table
//    DocumentLine - ValueTableRow - Contains a description of the invoice and related data
//    AccountHolder - CatalogRef.Counterparties - Counterparty - the account owner.
//
// Returns:
//    CatalogRef.CounterpartyBankAccounts - A link to a new directory item.
//
Function CreateCounterpartySBankAccount(DocumentsToImport, DocumentLine, AccountHolder) Export
	
	If DocumentLine.Outgoing Then
		
		NameOfAccountColumn              = "BENEFICIARYACCOUNT";
		ColumnNameDirectCalculations     = "Recipient2";
		ColumnNameBankNameNotDirectSettlement     = "Recipient3";
		ColumnNameBankCityNotDirectCalculations     = "Recipient4";
		NameOfBICColumn               = "BENEFICIARYBIC";
		ColumnNameCorAccount           = "BENEFICIARYCORACCOUNT";
		NameOfCalculationColumn          = "RECIPIENTBANKACCOUNT";
		ColumnNameBankCountryCode    = "RecipientBank_5";
		ColumnNameSWIFT             = "BENEFICIARYSWIFT";
		ColumnNameBankName = "RecipientBank_1";
		NameAndCityOfBank        = "RecipientBank_2";
		
	Else
		
		NameOfAccountColumn              = "PAYERACCOUNT";
		ColumnNameDirectCalculations     = "Payer2";
		ColumnNameBankNameNotDirectSettlement     = "Payer3";
		ColumnNameBankCityNotDirectCalculations     = "Payer4";
		NameOfBICColumn               = "PAYERBIC";
		ColumnNameCorAccount           = "PAYERCORACCOUNT";
		NameOfCalculationColumn          = "PAYERBANKACCOUNT";
		ColumnNameBankCountryCode    = "PayerBank_5";
		ColumnNameSWIFT             = "PAYERSWIFT";
		ColumnNameBankName = "PayerBank_1";
		NameAndCityOfBank        = "PayerBank_2";
		
	EndIf;
	
	AccountNumber = DocumentLine[NameOfAccountColumn];
	If Not ValueIsFilled(AccountNumber) Then
		Return Undefined;
	EndIf;
	
	SetPrivilegedMode(True);
	
	InvoiceData = BankAccountDetails();
	
	InvoiceData.Insert("Owner",              AccountHolder);
	InvoiceData.Insert("CashCurrency", DocumentLine.Currency);
	InvoiceData.Insert("AccountNumber",            AccountNumber);
	
	If DocumentLine.ThisIsBankFeedsImport 
		And CashClientServer.CorrectIBANLength(AccountNumber) Then
		
		InvoiceData.Insert("ThisIsAnIBAN",   True);
		
	EndIf;
	
	DirectCalculations = IsBlankString(DocumentLine[ColumnNameDirectCalculations]);
	MainCountry = Constants.MainCountry.Get();
	If DirectCalculations Then
		
		// Counterparty's bank
		BankBIC       = DocumentLine[NameOfBICColumn];
		BankCorrAccount  = DocumentLine[ColumnNameCorAccount];
		
		Bank = Undefined;
		If Not IsBlankString(BankBIC) Then
			Bank = Catalogs.BankClassifier.FindByCode(BankBIC);
		EndIf;
		If Not ValueIsFilled(Bank) And Not IsBlankString(BankCorrAccount) Then
			Bank = Catalogs.BankClassifier.FindByAttribute("CorrAccount", BankCorrAccount);
		EndIf;
		
		BankCountryCode = DocumentLine[ColumnNameBankCountryCode];
		If ValueIsFilled(BankCountryCode) Then
			CountryOfBank = Catalogs.WorldCountries.FindByAttribute("CodeAlpha2", BankCountryCode);
			If ValueIsFilled(CountryOfBank)
				Then
				InvoiceData.Insert("ForeignBank", True);
			EndIf;
			InvoiceData.Insert("CountryOfBank", CountryOfBank);
		EndIf;
		
		If ValueIsFilled(Bank) Then
			
			CountryOfBank = CashServer.BankCountryByBank(Bank);
			
			If CountryOfBank = MainCountry Then
				InvoiceData.Insert("Bank", Bank);
			EndIf;
			
		EndIf;
		
		If Not ValueIsFilled(InvoiceData.Bank) Then
			InvoiceData.Insert("ManualBankDetailsChange", True);
			InvoiceData.Insert("BankBIC",          DocumentLine[NameOfBICColumn]);
			InvoiceData.Insert("BankSWIFTCode",        DocumentLine[ColumnNameSWIFT]);
			InvoiceData.Insert("BankDescription", DocumentLine[ColumnNameBankName]);
			InvoiceData.Insert("BankCity",        DocumentLine[NameAndCityOfBank]);
			InvoiceData.Insert("BankCorrAccount",     DocumentLine[ColumnNameCorAccount]);
		EndIf;
		
	Else
		
		// Counterparty's bank
		BankNaim      = DocumentLine[ColumnNameBankNameNotDirectSettlement];
		BankCorrAccount  = DocumentLine[NameOfCalculationColumn];
		
		Bank = Undefined;
		If Not IsBlankString(BankNaim) And Not IsBlankString(BankCorrAccount) Then
			Bank = Catalogs.BankClassifier.FindByAttribute("CorrAccount", BankCorrAccount);
		EndIf;
		
		If ValueIsFilled(Bank) Then
			
			CountryOfBank = CashServer.BankCountryByBank(Bank);
			
			If CountryOfBank = MainCountry Then
				InvoiceData.Insert("Bank", Bank);
			EndIf;
			
		EndIf;
		
		If Not ValueIsFilled(InvoiceData.Bank) Then
			InvoiceData.Insert("ManualBankDetailsChange", True);
			InvoiceData.Insert("BankDescription", BankNaim);
			InvoiceData.Insert("BankCity",        DocumentLine[ColumnNameBankCityNotDirectCalculations]);
			InvoiceData.Insert("BankCorrAccount",     BankCorrAccount);
		EndIf;
		
		// RC of the counterparty's bank
		RCBank_         = DocumentLine[ColumnNameBankName];
		BICRCBank      = DocumentLine[NameOfBICColumn];
		CorrespondentAccountOfRCBank = DocumentLine[ColumnNameCorAccount];
		
		RCBank = Undefined;
		If Not IsBlankString(RCBank_) And Not IsBlankString(BICRCBank) Then
			RCBank = Catalogs.BankClassifier.FindByCode(BICRCBank);
			If Not ValueIsFilled(RCBank) Then
				RCBank = Catalogs.BankClassifier.FindByAttribute("CorrAccount", CorrespondentAccountOfRCBank);
			EndIf;
		EndIf;
		
		If ValueIsFilled(RCBank) Then
			
			CountryOfBank = CashServer.BankCountryByBank(RCBank);
			
			If CountryOfBank = MainCountry Then
				InvoiceData.Insert("TransferBank", RCBank);
			EndIf;
			
		EndIf;
		
		If Not ValueIsFilled(InvoiceData.TransferBank) Then
			InvoiceData.Insert("TransferBankDetailsManualEdit", True);
			InvoiceData.Insert("TransferBankDescription", RCBank_);
			InvoiceData.Insert("TransferBankCity",        DocumentLine[NameAndCityOfBank]);
			InvoiceData.Insert("TransferBankBIC",          BICRCBank);
			InvoiceData.Insert("TransferBankCorrAccount",     CorrespondentAccountOfRCBank);
		EndIf;
	EndIf;
	
	If InvoiceData.ManualBankDetailsChange Then
		NameString_ = Right(TrimAll(InvoiceData.AccountNumber), 4)
			+ ?(ValueIsFilled(InvoiceData.BankDescription), " In " + String(InvoiceData.BankDescription), "")
			+ " (" + String(InvoiceData.CashCurrency) + ")";
	Else
		NameString_ = Right(TrimAll(InvoiceData.AccountNumber), 4) 
			+ ?(ValueIsFilled(InvoiceData.Bank), " In " + String(InvoiceData.Bank), "")
			+ " (" + String(InvoiceData.CashCurrency) + ")";
	EndIf;
	
	InvoiceData.Insert("Description", Left(NameString_, 150));
	
	If ValueIsFilled(DocumentLine.AccountOfCounterparty) Then
		Return DocumentLine.AccountOfCounterparty;
	EndIf;
	
	Account = FindCreateCounterpartyBankAccount(InvoiceData);
	
	// You need to insert a new account in other lines of the statement
	TheStructureOfTheSearch = New Structure("BENEFICIARYACCOUNT, Counterparty, BankAccount",
		InvoiceData.AccountNumber, AccountHolder, DocumentLine.BankAccount);
	
	CounterpartyRecords = DocumentsToImport.FindRows(TheStructureOfTheSearch);
	
	For Each CounterpartyRecord In CounterpartyRecords Do
		CounterpartyRecord.AccountOfCounterparty = Account;
	EndDo;
	
	TheStructureOfTheSearch = New Structure("PAYERACCOUNT, Counterparty, BankAccount",
		InvoiceData.AccountNumber, AccountHolder, DocumentLine.BankAccount);
	
	CounterpartyRecords = DocumentsToImport.FindRows(TheStructureOfTheSearch);
	
	For Each CounterpartyRecord In CounterpartyRecords Do
		CounterpartyRecord.AccountOfCounterparty = Account;
	EndDo;
	
	Return Account;
	
EndFunction

Procedure ListOfCounterparties(DocumentsToImport, DocumentsTable) Export
	
	Query = New Query;
	TempTablesManager = New TempTablesManager;
	Query.TempTablesManager = TempTablesManager;
	
	Query.Text = "
	|SELECT
	|	DocumentsTable.LineNumber,
	|	DocumentsTable.NameOfCounterparty AS Description,
	|	DocumentsTable.AbbreviatedCounterpartyName AS NameAbbreviated,
	|	DocumentsTable.Counterparty AS Counterparty,
	|	CASE
	|		WHEN DocumentsTable.Outgoing THEN
	|			DocumentsTable.BeneficiaryTIN
	|		ELSE
	|			DocumentsTable.PayerTIN
	|	END AS TIN,
	|	CASE
	|		WHEN DocumentsTable.Outgoing THEN
	|		DocumentsTable.BeneficiaryCRTR
	|	ELSE
	|		DocumentsTable.KPPPayer
	|	END AS CRTR,
	|	DocumentsTable.CheckTIN,
	|	DocumentsTable.CheckCRTR,
	|	CASE
	|		WHEN DocumentsTable.Outgoing THEN
	|			DocumentsTable.BeneficiaryAccount
	|		ELSE
	|			DocumentsTable.PayerAccount
	|	END AS AccountNumber,
	|	CAST(CASE
	|		WHEN DocumentsTable.Outgoing THEN
	|			DocumentsTable.BeneficiaryBIC
	|		ELSE
	|			DocumentsTable.PayerBIC
	|	END AS STRING(9)) AS BankBIC,
	|	DocumentsTable.OperationKind
	|
	|INTO DocumentsTable
	|
	|FROM
	|	&DocumentsTable AS DocumentsTable
	|";
	
	Query.SetParameter("DocumentsTable", DocumentsTable);
	Query.Execute();
	
	Query.Text = "
	|SELECT
	|	DocumentsTable.LineNumber AS LineNumber,
	|	CatalogData.Owner AS Counterparty,
	|	CatalogData.Ref AS AccountOfCounterparty,
	|	0 AS Priority
	|
	|FROM
	|	DocumentsTable
	|	
	|	INNER JOIN
	|		Catalog.CompaniesBankAccounts AS CatalogData
	|	ON
	|		CatalogData.AccountNumber = DocumentsTable.AccountNumber
	|		AND (CatalogData.Bank.Code = DocumentsTable.BankBIC OR CatalogData.BankBIC = DocumentsTable.BankBIC)
	|		AND CatalogData.Owner.TIN = DocumentsTable.TIN
	|		AND DocumentsTable.CheckTIN
	|		AND NOT CatalogData.Closed,
	|	Constant.UseCustomerInvoiceIntercompany AS UseCustomerInvoiceIntercompany
	|WHERE
	|	CASE
	|		WHEN DocumentsTable.OperationKind = VALUE(Enum.BusinessTransactions.EmptyRef)
	|				OR DocumentsTable.OperationKind = VALUE(Enum.BusinessTransactions.CashReceiptFromOtherCompany)
	|				OR DocumentsTable.OperationKind = VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany)
	|			THEN UseCustomerInvoiceIntercompany.Value
	|			ELSE TRUE
	|		END
	|	
	|UNION ALL
	|
	|SELECT // The counterparty has already been found, we are looking for an account
	|	DocumentsTable.LineNumber AS LineNumber,
	|	Counterparties.Ref AS Counterparty,
	|	CatalogData.Ref AS AccountOfCounterparty,
	|	5 AS Priority
	|
	|FROM
	|	DocumentsTable
	|	
	|	INNER JOIN
	|		Catalog.Counterparties AS Counterparties
	|	ON
	|		Counterparties.Ref = DocumentsTable.Counterparty
	|	
	|	LEFT JOIN
	|		Catalog.CounterpartyBankAccounts AS CatalogData
	|	ON
	|		CatalogData.AccountNumber = DocumentsTable.AccountNumber
	|		AND CatalogData.Owner = Counterparties.Ref
	|		AND NOT CatalogData.Closed
	|	
	|UNION ALL
	|
	|SELECT
	|	DocumentsTable.LineNumber AS LineNumber,
	|	CatalogData.Owner AS Counterparty,
	|	CatalogData.Ref AS AccountOfCounterparty,
	|	10 AS Priority
	|
	|FROM
	|	DocumentsTable
	|	
	|	INNER JOIN
	|		Catalog.CounterpartyBankAccounts AS CatalogData
	|	ON
	|		CatalogData.AccountNumber = DocumentsTable.AccountNumber
	|		AND CatalogData.Owner.TIN = DocumentsTable.TIN
	|		AND CatalogData.Owner.CRTR = DocumentsTable.CRTR
	|		AND DocumentsTable.CheckCRTR
	|		AND NOT CatalogData.Closed
	|	
	|UNION ALL
	|
	|SELECT
	|	DocumentsTable.LineNumber AS LineNumber,
	|	CatalogData.Owner AS Counterparty,
	|	CatalogData.Ref AS AccountOfCounterparty,
	|	20 AS Priority
	|
	|FROM
	|	DocumentsTable
	|	
	|	INNER JOIN
	|		Catalog.CounterpartyBankAccounts AS CatalogData
	|	ON
	|		CatalogData.AccountNumber = DocumentsTable.AccountNumber
	|		AND CatalogData.Owner.TIN = DocumentsTable.TIN
	|		AND DocumentsTable.CheckTIN
	|		AND NOT CatalogData.Closed
	|	
	|UNION ALL
	|
	|SELECT
	|	DocumentsTable.LineNumber AS LineNumber,
	|	CatalogData.Owner AS Counterparty,
	|	CatalogData.Ref AS AccountOfCounterparty,
	|	30 AS Priority
	|
	|FROM
	|	DocumentsTable
	|	
	|	INNER JOIN
	|		Catalog.CounterpartyBankAccounts AS CatalogData
	|	ON
	|		CatalogData.AccountNumber = DocumentsTable.AccountNumber
	|		AND (CatalogData.Owner.DescriptionFull = DocumentsTable.Description
	|			OR CatalogData.Owner.DescriptionFull = DocumentsTable.NameAbbreviated)
	|		AND NOT CatalogData.Closed
	|	
	|UNION ALL
	|
	|SELECT
	|	DocumentsTable.LineNumber AS LineNumber,
	|	CatalogData.Ref AS Counterparty,
	|	UNDEFINED AS AccountOfCounterparty,
	|	40 AS Priority
	|
	|FROM
	|	DocumentsTable
	|	
	|	INNER JOIN
	|		Catalog.Counterparties AS CatalogData
	|	ON
	|		CatalogData.TIN = DocumentsTable.TIN
	|		AND CatalogData.CRTR = DocumentsTable.CRTR
	|		AND DocumentsTable.CheckCRTR
	|	
	|UNION ALL
	|
	|SELECT
	|	DocumentsTable.LineNumber AS LineNumber,
	|	CatalogData.Ref AS Counterparty,
	|	UNDEFINED AS AccountOfCounterparty,
	|	50 AS Priority
	|
	|FROM
	|	DocumentsTable
	|	
	|	INNER JOIN
	|		Catalog.Counterparties AS CatalogData
	|	ON
	|		CatalogData.TIN = DocumentsTable.TIN
	|		AND DocumentsTable.CheckTIN
	|	
	|UNION ALL
	|
	|SELECT
	|	DocumentsTable.LineNumber AS LineNumber,
	|	CatalogData.Ref AS Counterparty,
	|	UNDEFINED AS AccountOfCounterparty,
	|	60 AS Priority
	|
	|FROM
	|	DocumentsTable
	|	
	|	INNER JOIN
	|		Catalog.Counterparties AS CatalogData
	|	ON
	|		CatalogData.DescriptionFull = DocumentsTable.Description
	|		AND (CatalogData.TIN = """"
	|			OR NOT DocumentsTable.CheckTIN)
	|		AND (CatalogData.CRTR = """"
	|			OR NOT DocumentsTable.CheckCRTR)
	|	
	|UNION ALL
	|
	|SELECT
	|	DocumentsTable.LineNumber AS LineNumber,
	|	CatalogData.Ref AS Counterparty,
	|	UNDEFINED AS AccountOfCounterparty,
	|	70 AS Priority
	|
	|FROM
	|	DocumentsTable
	|	
	|	INNER JOIN
	|		Catalog.Persons AS CatalogData
	|	ON
	|		CatalogData.Description = DocumentsTable.Description
	|		AND (CatalogData.TIN = DocumentsTable.TIN
	|			OR CatalogData.TIN = """"
	|			OR NOT DocumentsTable.CheckTIN)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentsTable.LineNumber,
	|	CatalogData.Owner,
	|	CatalogData.Ref,
	|	80
	|
	|FROM
	|	DocumentsTable
	|		INNER JOIN
	|		Catalog.CounterpartyBankAccounts AS CatalogData
	|		ON CatalogData.AccountNumber = DocumentsTable.AccountNumber
	|			AND NOT CatalogData.Closed
	|			AND (CatalogData.Owner.TIN = """"
	|				OR NOT DocumentsTable.CheckTIN)
	|
	|ORDER BY
	|	LineNumber,
	|	Priority
	|";
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	While Selection.NextByFieldValue("LineNumber") Do
		
		DocumentLine = DocumentsToImport.Find(Selection.LineNumber, "LineNumber");
		If DocumentLine <> Undefined Then
			
			CounterpartiesFound = 0;
			CurPriority = 99;
			
			While Selection.Next() Do
				If CurPriority < Selection.Priority Then
					Break;
				EndIf;
				
				If DocumentLine.ThisIsFPS
					And Not ValueIsFilled(DocumentLine.Counterparty)
					And Selection.Counterparty = Catalogs.Counterparties.RetailCustomer Then
					Continue;
				EndIf;
				
				CurPriority = Selection.Priority;
				CounterpartiesFound = CounterpartiesFound + 1;
				
				If CounterpartiesFound = 1 Then
					
					DocumentLine.Counterparty = Selection.Counterparty;
					DocumentLine.CounterpartyIsFound = True;
					
					If ValueIsFilled(Selection.AccountOfCounterparty) Then
						DocumentLine.AccountOfCounterparty = Selection.AccountOfCounterparty;
						DocumentLine.CounterpartyAccountIsFound = True;
					EndIf;
				EndIf;
			EndDo;
			
			// If two identical counterparties with the same account number are found, then we do not fill in the counterparty 
			// , we will be prompted to select the counterparty, the account will be determined by the selected counterparty.
			// If two identical counterparties are found without the found account, then we do not fill in the counterparty 
			// , we will be prompted to select a counterparty and an account will be created for it.
			// If one counterparty has 2 or more identical accounts, then we do not fill in the counterparty.
			// In other cases, if duplicates with the same priority are found, the counterparty will remain empty and a new one will not be created.
			If CounterpartiesFound > 1 Then
				
				DocumentLine.Counterparty = Undefined;
				DocumentLine.AccountOfCounterparty = Undefined;
				DocumentLine.CreateCounterparty = False;
				DocumentLine.CounterpartyIsFound = False;
				DocumentLine.CounterpartyAccountIsFound = False;
			
				AddRemark(DocumentLine.ImportErrors,
					StrTemplate(NStr("vi = 'Đã tìm thấy nhiều hơn một đối tác hoặc tài khoản ngân hàng của đối tác (%1)!';
									|ru = 'Найдено более одного контрагента или банковского счета контрагента (%1)!';
									|en = 'More than one counterparty or counterparty bank account is found (%1).'; fa = 'More than one counterparty or counterparty bank account is found (%1).';
									|it = 'Найдено более одного контрагента или банковского счета контрагента (%1)!';
									|pl = 'Znaleziono więcej niż jednego kontrahenta lub więcej niż jedno konto bankowe kontrahenta (%1)!';
									|tr = 'Birden fazla cari hesap veya banka hesabı bulundu (%1)!'"), DocumentLine.NameOfCounterparty));
				
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

// Returns an empty invoice table to check that data editing is prohibited during the loading period.
// 
// Returns:
//  ValueTable - An Empty Invoice Table To Check If Editing Is Prohibited:
// * Object - CatalogRef.CompaniesBankAccounts - bank account.
// * Date - Date - the date to check.
Function EmptyInvoiceTableToCheckIfEditingIsProhibited() Export

	Table = New ValueTable;
	
	Table.Columns.Add("Object", New TypeDescription("CatalogRef.CompaniesBankAccounts"));
	Table.Columns.Add("Date", New TypeDescription("Date"));
	
	Return Table;

EndFunction

// Returns a list of invoices that cannot be changed during the loading period.
// 
// Parameters:
//  AuditedAccounts - See EmptyInvoiceTableToCheckIfEditingIsProhibited.
// 
// Returns:
//  Array of CatalogRef.CompaniesBankAccounts - list of accounts.
//
Function FillInListOfInvoicesWithBanOnChangesInUploadedPeriod(AuditedAccounts) Export

	AccountList = New Array;
	
	If AuditedAccounts.Count() = 0 Then
		Return AccountList;
	EndIf;
	
	DataToCheck = PeriodClosingDates.DataToCheckTemplate();
	
	For Each Account In AuditedAccounts Do
		
		NewRow = DataToCheck.Add();
		NewRow.Date = Account.Date;
		NewRow.Section = "Bank";
		NewRow.Object = Account.Object;
		
	EndDo;
	
	MessageParameters = PeriodClosingDates.PeriodEndMessageParameters();
	ErrorDescription = New Structure;
	
	ChangesAreDisabled = PeriodClosingDates.PeriodEndClosingFound(DataToCheck, MessageParameters, ErrorDescription);
	
	If Not ChangesAreDisabled Then
		Return AccountList;
	EndIf;
	
	For Each Error In ErrorDescription.PeriodEnds Do
		AccountList.Add(Error.Object);
	EndDo;
	
	Return AccountList;

EndFunction

// Updates the value of the property/Attribute of the object (document) with a new value.
// Filling is performed if the new value is filled in and different from the Cur current one, while the property/Attribute may 
// not be filled in or filled in with the condition that the Cur value is updated.
// 
// Parameters:
//  Object - DocumentObject.BankAccountReceiptNote, DocumentObject.BankAccountIssue - Object for updating Attributes.
//  PropertyName - String - name of the property/Attribute.
//  PropertyValue - Arbitrary - new property/Attribute value.
//  MandatoryReplacementOfOldValue - Boolean - indicates whether the Cur value of the object's property/Attribute has been replaced if the new 
//  and Cur values differ.
//
Procedure SetProperty(Object, PropertyName, PropertyValue, MandatoryReplacementOfOldValue = False) Export
	
	If PropertyValue <> Undefined And Object[PropertyName] <> PropertyValue Then
		If (Not ValueIsFilled(Object[PropertyName]) Or MandatoryReplacementOfOldValue)
			Or TypeOf(Object[PropertyName]) = Type("Boolean")
			Or TypeOf(Object[PropertyName]) = Type("Date") Then
			
			Object[PropertyName] = PropertyValue;
		EndIf;
	EndIf;
	
EndProcedure

// Fills in the line in the tabular part "Decryption of payment" for the settlement object.
// 
// Parameters:
//  DecryptionString - LineOfATabularSection - the payment decryption string.
//  DataOfPayment - ValueTableRow - data of the recognized payment.
//  DocumentObject - DocumentObject.BankAccountIssue, DocumentObject.BankAccountReceiptNote - Filling document.
//  DataOfCalculationObject - ValueTableRow - data of the calculation object according to the Balance table.
//  FillParameters - Structure - Parameters for filling in the table part.
//
Procedure FillInLineOfPaymentDecryptionForSettlementObject(
		DecryptionString, DataOfPayment, DocumentObject, DataOfCalculationObject, FillParameters) Export

	If DecryptionString = Undefined Then
		DecryptionString = DocumentObject.ARAPDetails.Add();
	EndIf;
	
	LineAmount = Min(FillParameters.AmountToDistribute, DataOfCalculationObject.Sum);
	FillParameters.AmountToDistribute = FillParameters.AmountToDistribute - DataOfCalculationObject.Sum;
	
	FillPropertyValues(DecryptionString, DataOfCalculationObject, , "Sum, CashFlowItem");
	
	// In case of return, the Cash flow item of the settlement object is not suitable for such a business of operation
	If FillParameters.AvailableCashFlowArticles.Find(DataOfCalculationObject.CashFlowItem) <> Undefined Then
		DecryptionString.CashFlowItem = DataOfCalculationObject.CashFlowItem;
		
	// If the Cash Flow item of the settlement object does not correspond to the business transaction of operation selected in the document, then
	// the Cash Flow item is filled in according to the found sample, if there was no sample, then according to the business of operation
	Else
		DecryptionString.CashFlowItem = DataOfPayment.CashFlowItem;
	EndIf;
	
	DecryptionString.Sum = LineAmount;
	
	ProcessingOfExchangeRatesTM.FillInDefaultDocumentCourse(
		DecryptionString.ExchangeRateNumeratorOfMutualSettlements,
		DecryptionString.TheExchangeRateIsTheDenominatorOfMutualSettlements,
		DocumentObject.Currency,
		DecryptionString.ARAPCurrency,
		DocumentObject.Organization,
		?(ValueIsFilled(DataOfPayment.ProcessingDate), DataOfPayment.ProcessingDate, DocumentObject.Date),,
		DecryptionString.ARAPObject);
	
EndProcedure

// Fills in the line in the tabular part "Payment decryption" based on the data of the recognized payment from the statement.
// 
// Parameters:
//  DecryptionString - LineOfATabularSection - the payment decryption string.
//  DataOfPayment - ValueTableRow - data of the recognized payment.
//  DocumentObject - DocumentObject.BankAccountIssue, DocumentObject.BankAccountReceiptNote - Filling document.
//  FillParameters - Structure - Parameters for filling in the table part.
//
Procedure FillInLineOfDecryptionOfPaymentForPayment(
		DecryptionString, DataOfPayment, DocumentObject, FillParameters) Export

	If DecryptionString = Undefined Then
		DecryptionString = DocumentObject.ARAPDetails.Add();
	EndIf;
	
	FillPropertyValues(DecryptionString, DataOfPayment, FillParameters.DetailsToFillIn);
	FillInTranscriptOfPaymentForSettlementObject(DecryptionString);
	
	FillInVATRateUnderContract(DocumentObject, DecryptionString);
	
	DecryptionString.Sum = FillParameters.AmountToDistribute;
	ProcessingOfExchangeRatesTM.FillInDefaultDocumentCourse(
		DecryptionString.ExchangeRateNumeratorOfMutualSettlements,
		DecryptionString.TheExchangeRateIsTheDenominatorOfMutualSettlements,
		DocumentObject.Currency,
		DecryptionString.ARAPCurrency,
		DocumentObject.Organization,
		?(ValueIsFilled(DataOfPayment.ProcessingDate), DataOfPayment.ProcessingDate, DocumentObject.Date),,
		DecryptionString.ARAPObject);
	
EndProcedure

// Generates the name of the payee bank, taking into account the RCC.
//
// Parameters:
//   Bank - String - Bank description
//   CSCBank - String - Name of the Bank's RCC
//
// Returns:
//   String - Name of the payee bank
//
Function NameOfPayeeSBank(Bank, CSCBank) Export

	If ValueIsFilled(CSCBank) Then
		
		PartsOfName = New Array;
		PartsOfName.Add(CSCBank);
		PartsOfName.Add(Bank);
		Result = StrConcat(PartsOfName, "//");
		
	Else
		Result = Bank;
	EndIf;
	
	Return Result;

EndFunction

#EndRegion

#Region Private

Procedure FillInTranscriptOfPaymentForSettlementObject(DetailsData)

	If Not ValueIsFilled(DetailsData.ARAPObject) Then
		Return;
	EndIf;
	
	APARObjectDetails = "ARAPCurrency, LineOfBusiness, Organization, Department";
	FillPropertyValues(DetailsData, DetailsData.ARAPObject, APARObjectDetails);

EndProcedure

Procedure FillInDebitDetails(DocumentsToImport, DocumentLine, DocumentObject, ImportSettings, Prefix)
	
	Var DetailsAll, DetailsOfBusinessTransaction;
	
	CreateCounterparties = ImportSettings.CreateCounterparties;
	
	Filter = New Structure("BusinessOperation", DocumentObject.BusinessOperation);
	AvailableCashFlowArticles = ImportSettings.ArticlesOfCashFlowOfOperations.Copy(Filter).UnloadColumn("CashFlowItem");
	
	// Application control
	If Not (DocumentObject.PaymentDocumentType = Enums.TypesOfPaymentDocuments.CollectionOrder_2
		Or DocumentObject.PaymentDocumentType = Enums.TypesOfPaymentDocuments.PaymentWarrant
		Or DocumentObject.PaymentDocumentType = Enums.TypesOfPaymentDocuments.BankPaymentOrder) Then
		DocumentObject.PaymentByRequests = Not CashServer.EnabledCreatingCashIssueWithoutPaymentRequest(DocumentObject);
	Else
		EDIWithBanksLocalization.AllowPaymentWithoutRequest(DocumentObject);
	EndIf;
	
	EDIWithBanksLocalization.FillInPayerSAttributes(DocumentObject, DocumentLine);
	
	Documents.BankAccountIssue.FillInNamesOfBusinessTransactionDetails(
		DocumentObject, DetailsAll, DetailsOfBusinessTransaction);
	
	// Counterparty
	If DetailsOfBusinessTransaction.Find("Counterparty") <> Undefined Then
		If ValueIsFilled(DocumentLine.Counterparty) Then
			SetProperty(DocumentObject, "Counterparty", DocumentLine.Counterparty);
		ElsIf CreateCounterparties And DocumentLine.CreateCounterparty Then
			SetProperty(DocumentObject, "Counterparty", CreateCounterparty(DocumentsToImport, DocumentLine));
		Else
			SetProperty(DocumentObject, "NameOfCounterparty", DocumentLine.NameOfCounterparty);
		EndIf;
	EndIf;
	
	// The account of the counterparty
	If DetailsOfBusinessTransaction.Find("CounterpartyBankAccount") <> Undefined Then
		If ValueIsFilled(DocumentLine.AccountOfCounterparty) Then
			SetProperty(DocumentObject, "CounterpartyBankAccount", DocumentLine.AccountOfCounterparty);
		ElsIf ValueIsFilled(DocumentObject.Counterparty) Then
			SetProperty(DocumentObject, "CounterpartyBankAccount",
				CreateCounterpartySBankAccount(DocumentsToImport, DocumentLine, DocumentObject.Counterparty));
		EndIf;
	EndIf;
	
	// Accountable person
	If DetailsOfBusinessTransaction.Find("AdvanceHolder") <> Undefined Then
		If DocumentLine.CounterpartyIsFound Then
			SetProperty(DocumentObject, "AdvanceHolder", DocumentLine.Counterparty);
		Else
			SetProperty(DocumentObject, "AdvanceHolder", DocumentLine.AdvanceHolder);
		EndIf;
	EndIf;
	
	If DetailsOfBusinessTransaction.Find("ExpenseReportDate") <> Undefined Then
		SetProperty(DocumentObject, "ExpenseReportDate",
			?(ValueIsFilled(DocumentObject.Date), DocumentObject.Date, CurrentSessionDate()) + 7 * 24 * 3600);
	EndIf;
	
	// Bank account the recipient
	If DetailsOfBusinessTransaction.Find("BankAccountBeneficiary") <> Undefined Then
		SetProperty(DocumentObject, "BankAccountBeneficiary", DocumentLine.AccountOfCounterparty);
	EndIf;
	
	// Other banking details
	FillPropertyValues(DocumentObject, DocumentLine,
		"CashFlowItem, Department, CashAccountRecipient");
	
	EDIWithBanksLocalization.FillInDebitDetails(DocumentLine, DocumentObject, AvailableCashFlowArticles);
	
	// Breakdown of payment
	FillInDecryptionOfWriteOff(DocumentLine, DocumentObject, DetailsOfBusinessTransaction, ImportSettings, AvailableCashFlowArticles);
	
EndProcedure

Procedure FillInReceiptDetails(DocumentsToImport, DocumentLine, DocumentObject, ImportSettings)
	
	Var DetailsAll, DetailsOfBusinessTransaction;
	
	CreateCounterparties = ImportSettings.CreateCounterparties;
	
	Filter = New Structure("BusinessOperation", DocumentObject.BusinessOperation);
	AvailableCashFlowArticles = ImportSettings.ArticlesOfCashFlowOfOperations.Copy(Filter).UnloadColumn("CashFlowItem");
	
	Documents.BankAccountReceiptNote.FillInNamesOfBusinessTransactionDetails(
		DocumentObject, DetailsAll, DetailsOfBusinessTransaction);
	
	CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(DocumentObject.Organization);
	
	// Counterparty
	If DetailsOfBusinessTransaction.Find("Counterparty") <> Undefined Then
		If ValueIsFilled(DocumentLine.Counterparty) Then
			SetProperty(DocumentObject, "Counterparty", DocumentLine.Counterparty);
		ElsIf CreateCounterparties And DocumentLine.CreateCounterparty Then
			SetProperty(DocumentObject, "Counterparty", CreateCounterparty(DocumentsToImport, DocumentLine));
		Else
			SetProperty(DocumentObject, "NameOfCounterparty", DocumentLine.NameOfCounterparty);
		EndIf;
	EndIf;
	
	// The account of the counterparty
	If DetailsOfBusinessTransaction.Find("CounterpartyBankAccount") <> Undefined Then
		If ValueIsFilled(DocumentLine.AccountOfCounterparty) Then
			SetProperty(DocumentObject, "CounterpartyBankAccount", DocumentLine.AccountOfCounterparty);
		ElsIf ValueIsFilled(DocumentObject.Counterparty) Then
			SetProperty(DocumentObject, "CounterpartyBankAccount",
				CreateCounterpartySBankAccount(DocumentsToImport, DocumentLine, DocumentObject.Counterparty));
		EndIf;
	EndIf;
	
	// Accountable person
	If DetailsOfBusinessTransaction.Find("AdvanceHolder") <> Undefined Then
		If DocumentLine.CounterpartyIsFound Then
			SetProperty(DocumentObject, "AdvanceHolder", DocumentLine.Counterparty);
		Else
			SetProperty(DocumentObject, "AdvanceHolder", DocumentLine.AdvanceHolder);
		EndIf;
	EndIf;
	
	// Bank account the sender
	If DetailsOfBusinessTransaction.Find("SenderBankAccount") <> Undefined Then
		SetProperty(DocumentObject, "SenderBankAccount", DocumentLine.AccountOfCounterparty);
	EndIf;
	
	// Other banking details
	FillPropertyValues(DocumentObject, DocumentLine,
		"CashFlowItem, Department, CashAccountIssuer");
	
	// Acquiring payment receipt
	If DetailsOfBusinessTransaction.Find("AcquiringContract") <> Undefined Then
		
		If Not ValueIsFilled(DocumentLine.AcquiringContract) Then
			
			MakingPaymentMethod = Undefined;
			
			If DocumentLine.ThisIsFPS Then
				MakingPaymentMethod = Enums.MakingPaymentMethods.InstantPayments;
			EndIf;
			
			FilterParameters = Catalogs.AcquiringContracts.ParametersOfAcquisitionContractSelection();
		
			FilterParameters.Organization = DocumentObject.Organization;
			FilterParameters.Acquirer = DocumentObject.Counterparty;
			FilterParameters.BankAccount = DocumentObject.BankAccount;
			FilterParameters.MakingPaymentMethod = MakingPaymentMethod;
			
			DocumentLine.AcquiringContract = Catalogs.AcquiringContracts.ContractOfAcquiringByDefault(FilterParameters);
			
		EndIf;
		
		FillInAccordingToActivationContract(DocumentLine, DocumentObject, AvailableCashFlowArticles);
		
	EndIf;
	
	EDIWithBanksLocalization.FillInReceiptDetails(DocumentLine, DocumentObject);
	
	// Breakdown of payment
	FillInReceiptTranscript(DocumentLine, DocumentObject, DetailsOfBusinessTransaction, ImportSettings, AvailableCashFlowArticles);
	
	If DocumentLine.ConversionAmount <> 0 Then
		
		SetProperty(DocumentObject, "ConversionAmount", DocumentLine.ConversionAmount, True);
		CashServer.RecalculateConversionParameters(DocumentObject, CurrencyOfComplianceAccounting, "ConversionAmount");
		
	EndIf;
	
	EDIWithBanksLocalization.FillInCurrencyOfOperationCode(DocumentObject);
	
EndProcedure

Procedure FillInDecryptionOfWriteOff(DocumentLine, DocumentObject, DetailsOfBusinessTransaction, ImportSettings, AvailableCashFlowArticles)

	PostDocuments = ImportSettings.PostDocuments;
	
	If DetailsOfBusinessTransaction.Find("ARAPDetails") <> Undefined Then
		
		If DocumentLine.PaymentBasisIsFound
			And DetailsOfBusinessTransaction.Find("ARAPDetails.ARAPObject") <> Undefined Then // UIP
			
			DecryptionString = DocumentObject.ARAPDetails.Add();
			
			DetailsToFillIn = "Counterparty, Partner, ARAPObject, CashFlowItem";
			FillPropertyValues(DecryptionString, DocumentLine, DetailsToFillIn);
			
			FillInTranscriptOfPaymentForSettlementObject(DecryptionString);
			EDIWithBanksLocalization.FillInArticleOfTargetFundsOfDecryptionOfPayment(DocumentLine, DecryptionString);
			
			DecryptionString.Sum = DocumentObject.DocumentAmount;
			
			ProcessingOfExchangeRatesTM.FillInDefaultDocumentCourse(
				DecryptionString.ExchangeRateNumeratorOfMutualSettlements,
				DecryptionString.TheExchangeRateIsTheDenominatorOfMutualSettlements,
				DocumentObject.Currency,
				DecryptionString.ARAPCurrency,
				DocumentObject.Organization,
				?(ValueIsFilled(DocumentLine.ProcessingDate), DocumentLine.ProcessingDate, DocumentObject.Date),,
				DecryptionString.ARAPObject);
			
			CashServer.FillInNDSInDecryption(
				DocumentObject.ARAPDetails,
				CashServer.TranscriptOfVATPayment(DocumentObject.Organization,
					DocumentObject.Date, DocumentObject.Currency, DocumentObject.ARAPDetails.UnloadColumn("ARAPObject"), True));
			
			
		ElsIf DetailsOfBusinessTransaction.Find("ARAPDetails.LoanDepositContract") <> Undefined Then
			
			DecryptionString = DocumentObject.ARAPDetails.Add();
			
			// Credit or loan received: payment of the main debt, interest or commission
			Query = New Query;
			Query.Text = "
			|SELECT
			|	RegisterData.PaymentObject AS LoanDepositContract,
			|	CAST(RegisterData.PaymentObject AS Catalog.LoanAndDepositContracts).Partner AS Partner,
			|	CAST(RegisterData.PaymentObject AS Catalog.LoanAndDepositContracts).InterestBankAccount AS InterestBankAccount,
			|	CAST(RegisterData.PaymentObject AS Catalog.LoanAndDepositContracts).BankAccountOfFee AS BankAccountOfFee,
			|	CAST(RegisterData.PaymentObject AS Catalog.LoanAndDepositContracts).ARAPCurrency AS ARAPCurrency,
			|	CAST(RegisterData.PaymentObject AS Catalog.LoanAndDepositContracts).CashFlowItemOfPrincipalDebt AS CashFlowItemOfPrincipalDebt,
			|	CAST(RegisterData.PaymentObject AS Catalog.LoanAndDepositContracts).CashFlowItemOfInterestPayment AS CashFlowItemOfInterestPayment,
			|	CAST(RegisterData.PaymentObject AS Catalog.LoanAndDepositContracts).CashFlowItemOfFeePayment AS CashFlowItemOfFeePayment
			|FROM
			|	InformationRegister.ScheduleOfPayments AS RegisterData
			|WHERE
			|	RegisterData.BankAccountCashAccount = &BankAccount
			|	AND RegisterData.PayerBeneficiary = &Counterparty
			|	AND RegisterData.ReceiptIssue = VALUE(Enum.CashFlowTypes.WriteOff)
			|	AND RegisterData.BusinessOperation = VALUE(Enum.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived)
			|GROUP BY
			|	RegisterData.PaymentObject
			|HAVING
			|	COUNT(DISTINCT RegisterData.PaymentObject) = 1
			|";
			
			Query.SetParameter("BankAccount", DocumentObject.BankAccount);
			Query.SetParameter("Counterparty", DocumentObject.Counterparty);
			
			Selection = Query.Execute().Select();
			
			If Selection.Next() Then
				
				FillPropertyValues(DecryptionString, Selection);
				
				If DocumentObject.CounterpartyBankAccount = Selection.InterestBankAccount Then
					DecryptionString.LoanAndDepositAmountType = Enums.LoanAndDepositScheduleAmountTypes.Interests;
					DecryptionString.CashFlowItem = Selection.CashFlowItemOfInterestPayment;
				ElsIf DocumentObject.CounterpartyBankAccount = Selection.BankAccountOfFee Then
					DecryptionString.LoanAndDepositAmountType = Enums.LoanAndDepositScheduleAmountTypes.Fee;
					DecryptionString.CashFlowItem = Selection.CashFlowItemOfFeePayment;
				Else
					DecryptionString.LoanAndDepositAmountType = Enums.LoanAndDepositScheduleAmountTypes.PrincipalDebt;
					DecryptionString.CashFlowItem = Selection.CashFlowItemOfPrincipalDebt;
				EndIf;
				
			Else
				
				If Not ValueIsFilled(DocumentLine.LoanDepositContract) Then
					
					LinesToLoad = New Array;
					LinesToLoad.Add(DocumentLine);
					FillInIndirectData(LinesToLoad, DocumentObject.BankAccount);
					
				EndIf;

				FillPropertyValues(DecryptionString, DocumentLine,
					"Partner, CashFlowItem, LoanDepositContract, LoanAndDepositAmountType, ARAPCurrency");
				
			EndIf;
			
			DecryptionString.Sum = DocumentLine.DocumentAmount;
			
			ProcessingOfExchangeRatesTM.FillInDefaultDocumentCourse(
				DecryptionString.ExchangeRateNumeratorOfMutualSettlements,
				DecryptionString.TheExchangeRateIsTheDenominatorOfMutualSettlements,
				DocumentObject.Currency,
				DecryptionString.ARAPCurrency,
				DocumentObject.Organization,
				?(ValueIsFilled(DocumentLine.ProcessingDate), DocumentLine.ProcessingDate, DocumentObject.Date));
			CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(DocumentObject.Organization);
			CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
				DecryptionString, DocumentObject.Currency, CurrencyOfComplianceAccounting);
		
		ElsIf DetailsOfBusinessTransaction.Find("ARAPDetails.ARAPObject") = Undefined Then
			
			DecryptionString = DocumentObject.ARAPDetails.Add();
			FillPropertyValues(DecryptionString, DocumentLine,
				"Partner, CashFlowItem, ExpenseItem, DimensionOfExpenses, AssetsLiabilitiesDimension, Department");
			EDIWithBanksLocalization.FillInArticleOfTargetFundsOfDecryptionOfPayment(DocumentLine, DecryptionString);
			DecryptionString.Sum = DocumentLine.DocumentAmount;
			ProcessingOfExchangeRatesTM.FillInDefaultDocumentCourse(
				DecryptionString.ExchangeRateNumeratorOfMutualSettlements,
				DecryptionString.TheExchangeRateIsTheDenominatorOfMutualSettlements,
				DocumentObject.Currency,
				DecryptionString.ARAPCurrency,
				DocumentObject.Organization,
				?(ValueIsFilled(DocumentLine.ProcessingDate), DocumentLine.ProcessingDate, DocumentObject.Date));
		
		Else
			
			Attributes = New Structure;
			Attributes.Insert("Date", DocumentObject.Date);
			Attributes.Insert("Organization", DocumentObject.Organization);
			Attributes.Insert("DocumentAmount", 0);
			Attributes.Insert("Currency", DocumentObject.Currency);
			
			If ValueIsFilled(DocumentObject.Counterparty) Then
				Attributes.Insert("Counterparty", DocumentObject.Counterparty);
			Else
				Attributes.Insert("Counterparty", DocumentObject.NameOfCounterparty);
			EndIf;
			
			If TypeOf(DocumentLine.Counterparty) = Type("CatalogRef.Companies") Then
				Attributes.Insert("Partner", Catalogs.Partners.OurEnterprise);
			Else
				Attributes.Insert("Partner", Undefined);
			EndIf;
			
			Attributes.Insert("BusinessOperation", DocumentObject.BusinessOperation);
			
			If DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToCustomer
				Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany Then
				Attributes.Insert("PaymentType_", Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting);
			Else
				Attributes.Insert("PaymentType_", Enums.PartnersARAPAccountingTypes.VendorARAPAccounting);
			EndIf;
			
			Attributes.Insert("PartnerOtherRelations", False);
			Attributes.Insert("SelectAccountsReceivable", False);
			Attributes.Insert("SelectOnlyUnconditionalDebt", False);
			Attributes.Insert("SelectionOfPaymentByRequest", False);
			Attributes.Insert("ByPaymentDates", True);
			Attributes.Insert("AsOfDateOfOccurrence", DocumentObject.Date);
			
			
			AddressOfPaymentsInTheStorage = "";
			PaymentBalanceTable = Undefined;
			
			ARAPAccountingServer.FillInTableOfSettlementBalances(Attributes, AddressOfPaymentsInTheStorage, PaymentBalanceTable);
			ColumnsOfTableOfBalancesOfMutualSettlements = PaymentBalanceTable.Columns; // ValueTableColumnCollection 
			ColumnsOfTableOfBalancesOfMutualSettlements.Add("Processed", New TypeDescription("Boolean"));
			
			AmountToDistribute = DocumentObject.DocumentAmount;
			
			ParametersForAddingLine = New Structure;
			ParametersForAddingLine.Insert("AmountToDistribute", AmountToDistribute);
			ParametersForAddingLine.Insert("AvailableCashFlowArticles", AvailableCashFlowArticles);
			
			NumbersOfObjectsByDestination = EDIWithBanksLocalization.PaymentDestinationSettlementObjects(DocumentLine.PaymentPurposes);
			EDIWithBanksLocalization.AddParametersForFillingInDecryption(ImportSettings, ParametersForAddingLine);
			
			For Each TableRow In PaymentBalanceTable Do
				
				If TypeOf(TableRow.ARAPObject) = Type("CatalogRef.ARAPObjects") Then
					
					PaymentDocumentNumber_ = ObjectsPrefixesClientServer.NumberForPrinting(TableRow.Number, True, True);
					
					If EDIWithBanksLocalization.ThereIsCalculationObjectInAssignment(DocumentLine.PaymentPurposes, NumbersOfObjectsByDestination, PaymentDocumentNumber_) Then
						
						EDIWithBanksLocalization.AddLineToDecryptPaymentForSettlementObject(
							DocumentLine, DocumentObject, TableRow, ParametersForAddingLine);
						TableRow.Processed = True;
						
						If ParametersForAddingLine.AmountToDistribute <= 0 Then
							Break;
						EndIf;
						
					EndIf;
				EndIf;
			EndDo;
			
			If PostDocuments And ParametersForAddingLine.AmountToDistribute > 0 Then // Selection of payment objects
				
				For Each TableRow In PaymentBalanceTable Do
					
					If ValueIsFilled(TableRow.ARAPObject) Then
						
						If TableRow.Processed Then
							Continue;
						EndIf;
						
						EDIWithBanksLocalization.AddLineToDecryptPaymentForSettlementObject(
							DocumentLine, DocumentObject, TableRow, ParametersForAddingLine);
						TableRow.Processed = True;
						
						If ParametersForAddingLine.AmountToDistribute <= 0 Then
							Break;
						EndIf;
						
					EndIf;
				EndDo;
			EndIf;
			
			If ParametersForAddingLine.AmountToDistribute > 0 Or Not DocumentObject.ARAPDetails.Count() Then
				
				DetailsToFillIn = "Counterparty, Partner, ARAPObject, CashFlowItem";
				ParametersForAddingLine.Insert("DetailsToFillIn", DetailsToFillIn);
				EDIWithBanksLocalization.AddLineToDecryptPaymentByPayment(
					DocumentLine, DocumentObject, ParametersForAddingLine);
				
			EndIf;
			
			DocumentObject.ARAPDetails.GroupBy(
				"Counterparty, Partner, CashFlowItem, ARAPCurrency, Department, Organization,
				|ARAPObject, ExchangeRateNumeratorOfMutualSettlements, TheExchangeRateIsTheDenominatorOfMutualSettlements, TargetFundItem, MaturityDate,
				|LineOfBusiness, VATRate, GLAccountSettings",
				"Sum, AmountARAP, VATAmount");
			
			
			CashServer.FillInNDSInDecryption(
				DocumentObject.ARAPDetails,
				CashServer.TranscriptOfVATPayment(DocumentObject.Organization,
					DocumentObject.Date, DocumentObject.Currency, DocumentObject.ARAPDetails.UnloadColumn("ARAPObject"), False));
		EndIf;
	EndIf;

EndProcedure

Procedure FillInReceiptTranscript(DocumentLine, DocumentObject, DetailsOfBusinessTransaction, ImportSettings, AvailableCashFlowArticles)

	PostDocuments = ImportSettings.PostDocuments;
	
	If DetailsOfBusinessTransaction.Find("ARAPDetails") <> Undefined Then
		
		CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(DocumentObject.Organization);
		
		If DocumentLine.PaymentBasisIsFound Then // UIP
			
			DecryptionString = DocumentObject.ARAPDetails.Add();
			FillPropertyValues(DecryptionString, DocumentLine,
				"Partner, PaymentPurpose, ARAPObject, CashFlowItem");
			FillInTranscriptOfPaymentForSettlementObject(DecryptionString);
			EDIWithBanksLocalization.FillInArticleOfTargetFundsOfDecryptionOfPayment(DocumentLine, DecryptionString);
			DecryptionString.Sum = DocumentObject.DocumentAmount;
			
			ProcessingOfExchangeRatesTM.FillInDefaultDocumentCourse(
				DecryptionString.ExchangeRateNumeratorOfMutualSettlements,
				DecryptionString.TheExchangeRateIsTheDenominatorOfMutualSettlements,
				DocumentObject.Currency,
				DecryptionString.ARAPCurrency,
				DocumentObject.Organization,
				?(ValueIsFilled(DocumentLine.ProcessingDate), DocumentLine.ProcessingDate, DocumentObject.Date),,
				DecryptionString.ARAPObject);
			
			CashServer.FillInNDSInDecryption(
				DocumentObject.ARAPDetails,
				CashServer.TranscriptOfVATPayment(DocumentObject.Organization,
					DocumentObject.Date, DocumentObject.Currency, DocumentObject.ARAPDetails.UnloadColumn("ARAPObject"), True));
					
		ElsIf DetailsOfBusinessTransaction.Find("ARAPDetails.LoanDepositContract") <> Undefined Then
			
			DecryptionString = DocumentObject.ARAPDetails.Add();
			
			// Credit or loan received: receipt of credit
			Query = New Query;
			Query.Text = "
			|SELECT
			|	RegisterData.PaymentObject AS LoanDepositContract,
			|	CAST(RegisterData.PaymentObject AS Catalog.LoanAndDepositContracts).Partner AS Partner,
			|	CAST(RegisterData.PaymentObject AS Catalog.LoanAndDepositContracts).CashFlowItemOfReceiptIssuie AS CashFlowItem,
			|	CAST(RegisterData.PaymentObject AS Catalog.LoanAndDepositContracts).ARAPCurrency AS ARAPCurrency
			|FROM
			|	InformationRegister.ScheduleOfPayments AS RegisterData
			|WHERE
			|	RegisterData.BankAccountCashAccount = &BankAccount
			|	AND RegisterData.PayerBeneficiary = &Counterparty
			|	AND RegisterData.ReceiptIssue = VALUE(Enum.CashFlowTypes.Inpayment)
			|	AND RegisterData.BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromLoansRepayment)
			|GROUP BY
			|	RegisterData.PaymentObject
			|HAVING
			|	COUNT(DISTINCT RegisterData.PaymentObject) = 1
			|";
			
			Query.SetParameter("BankAccount", DocumentObject.BankAccount);
			Query.SetParameter("Counterparty", DocumentObject.Counterparty);
			
			Selection = Query.Execute().Select();
			
			If Selection.Next() Then
				FillPropertyValues(DecryptionString, Selection);
			Else
				
				If Not ValueIsFilled(DocumentLine.LoanDepositContract) Then
					
					LinesToLoad = New Array;
					LinesToLoad.Add(DocumentLine);
					FillInIndirectData(LinesToLoad, DocumentObject.BankAccount);
					
				EndIf;
				
				FillPropertyValues(DecryptionString, DocumentLine,
					"Partner, CashFlowItem, LoanDepositContract, LoanAndDepositAmountType, ARAPCurrency");
				
			EndIf;
			
			DecryptionString.Sum = DocumentLine.DocumentAmount;
			
			ProcessingOfExchangeRatesTM.FillInDefaultDocumentCourse(
				DecryptionString.ExchangeRateNumeratorOfMutualSettlements,
				DecryptionString.TheExchangeRateIsTheDenominatorOfMutualSettlements,
				DocumentObject.Currency,
				DecryptionString.ARAPCurrency,
				DocumentObject.Organization,
				?(ValueIsFilled(DocumentLine.ProcessingDate), DocumentLine.ProcessingDate, DocumentObject.Date));
			CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
				DecryptionString, DocumentObject.Currency, CurrencyOfComplianceAccounting);
			
		ElsIf DetailsOfBusinessTransaction.Find("ARAPDetails.ARAPObject") = Undefined Then // Other payments
			
			DecryptionString = DocumentObject.ARAPDetails.Add();
			FillPropertyValues(DecryptionString, DocumentLine,
				"Partner, CashFlowItem, IncomeItem, DimensionOfRevenue, AssetsLiabilitiesDimension, Department");
			EDIWithBanksLocalization.FillInArticleOfTargetFundsOfDecryptionOfPayment(DocumentLine, DecryptionString);
			DecryptionString.Sum = DocumentLine.DocumentAmount;
			ProcessingOfExchangeRatesTM.FillInDefaultDocumentCourse(
				DecryptionString.ExchangeRateNumeratorOfMutualSettlements,
				DecryptionString.TheExchangeRateIsTheDenominatorOfMutualSettlements,
				DocumentObject.Currency,
				DecryptionString.ARAPCurrency,
				DocumentObject.Organization,
				?(ValueIsFilled(DocumentLine.ProcessingDate), DocumentLine.ProcessingDate, DocumentObject.Date));
		
		Else
			
			Attributes = New Structure;
			Attributes.Insert("Date", DocumentObject.Date);
			Attributes.Insert("Organization", DocumentObject.Organization);
			Attributes.Insert("DocumentAmount", 0);
			Attributes.Insert("Currency", DocumentObject.Currency);
			
			If ValueIsFilled(DocumentObject.Counterparty) Then
				Attributes.Insert("Counterparty", DocumentObject.Counterparty);
			Else
				Attributes.Insert("Counterparty", DocumentObject.NameOfCounterparty);
			EndIf;
			
			If TypeOf(DocumentLine.Counterparty) = Type("CatalogRef.Companies") Then
				Attributes.Insert("Partner", Catalogs.Partners.OurEnterprise);
			Else
				Attributes.Insert("Partner", Undefined);
			EndIf;
			
			Attributes.Insert("BusinessOperation", DocumentObject.BusinessOperation);
			
			If DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromVendor
				Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromAnotherCompany Then
				Attributes.Insert("PaymentType_", Enums.PartnersARAPAccountingTypes.VendorARAPAccounting);
			Else
				Attributes.Insert("PaymentType_", Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting);
			EndIf;
			
			Attributes.Insert("PartnerOtherRelations", False);
			Attributes.Insert("SelectAccountsReceivable", True);
			Attributes.Insert("SelectOnlyUnconditionalDebt", False);
			Attributes.Insert("SelectionOfPaymentByRequest", False);
			Attributes.Insert("ByPaymentDates", True);
			Attributes.Insert("AsOfDateOfOccurrence", DocumentObject.Date);
			
			
			AddressOfPaymentsInTheStorage = "";
			PaymentBalanceTable = Undefined;
			
			ARAPAccountingServer.FillInTableOfSettlementBalances(Attributes, AddressOfPaymentsInTheStorage, PaymentBalanceTable);
			ColumnsOfTableOfBalancesOfMutualSettlements = PaymentBalanceTable.Columns; // ValueTableColumnCollection
			ColumnsOfTableOfBalancesOfMutualSettlements.Add("Processed", New TypeDescription("Boolean"));
			ColumnsOfTableOfBalancesOfMutualSettlements.Object.Name = "PaymentPurpose";
			
			AmountToDistribute = DocumentObject.DocumentAmount;
			
			ParametersForAddingLine = New Structure;
			ParametersForAddingLine.Insert("AmountToDistribute", AmountToDistribute);
			ParametersForAddingLine.Insert("AvailableCashFlowArticles", AvailableCashFlowArticles);
			
			NumbersOfObjectsByDestination = EDIWithBanksLocalization.PaymentDestinationSettlementObjects(DocumentLine.PaymentPurposes);
			
			For Each TableRow In PaymentBalanceTable Do
				
				If TypeOf(TableRow.ARAPObject) = Type("CatalogRef.ARAPObjects") Then
					
					PaymentDocumentNumber_ = ObjectsPrefixesClientServer.NumberForPrinting(TableRow.Number, True, True);
					
					If EDIWithBanksLocalization.ThereIsCalculationObjectInAssignment(DocumentLine.PaymentPurposes, NumbersOfObjectsByDestination, PaymentDocumentNumber_) Then
						
						DecryptionString = DocumentObject.ARAPDetails.Add();
						FillInLineOfPaymentDecryptionForSettlementObject(
							DecryptionString, DocumentLine, DocumentObject, TableRow, ParametersForAddingLine);
						EDIWithBanksLocalization.FillInArticleOfTargetFundsOfDecryptionOfPayment(DocumentLine, DecryptionString);
						
						TableRow.Processed = True;
						
						If ParametersForAddingLine.AmountToDistribute <= 0 Then
							Break;
						EndIf;
						
					EndIf;
					
				EndIf;
				
			EndDo;
			
			If PostDocuments And ParametersForAddingLine.AmountToDistribute > 0 Then // Selection of payment objects
				
				For Each TableRow In PaymentBalanceTable Do
					
					If ValueIsFilled(TableRow.ARAPObject) Then
						
						If TableRow.Processed Then
							Continue;
						EndIf;
						
						DecryptionString = DocumentObject.ARAPDetails.Add();
						FillInLineOfPaymentDecryptionForSettlementObject(
							DecryptionString, DocumentLine, DocumentObject, TableRow, ParametersForAddingLine);
						EDIWithBanksLocalization.FillInArticleOfTargetFundsOfDecryptionOfPayment(DocumentLine, DecryptionString);
						
						TableRow.Processed = True;
						
						If ParametersForAddingLine.AmountToDistribute <= 0 Then
							Break;
						EndIf;
						
					EndIf;
				EndDo;
			EndIf;
			
			If ParametersForAddingLine.AmountToDistribute > 0 Or Not DocumentObject.ARAPDetails.Count() Then
				
				DetailsToFillIn = "Partner, PaymentPurpose, ARAPObject, CashFlowItem";
				ParametersForAddingLine.Insert("DetailsToFillIn", DetailsToFillIn);
				EDIWithBanksLocalization.AddLineToDecryptPaymentByPayment(
					DocumentLine, DocumentObject, ParametersForAddingLine);
				
			EndIf;
			
			DocumentObject.ARAPDetails.GroupBy(
				"PaymentPurpose, Partner, CashFlowItem, ARAPCurrency, Department, Organization,
				|ARAPObject, ExchangeRateNumeratorOfMutualSettlements, TheExchangeRateIsTheDenominatorOfMutualSettlements, TargetFundItem, MaturityDate,
				|LineOfBusiness, VATRate, GLAccountSettings",
				"Sum, AmountARAP, VATAmount");
			
			CashServer.FillInNDSInDecryption(
				DocumentObject.ARAPDetails,
				CashServer.TranscriptOfVATPayment(DocumentObject.Organization,
					DocumentObject.Date, DocumentObject.Currency, DocumentObject.ARAPDetails.UnloadColumn("ARAPObject"), True));
		EndIf;
	EndIf;

EndProcedure

Function AttributesOfCounterparty()

	CounterpartyDetails_ = New Structure;
	CounterpartyDetails_.Insert("Description", "");
	CounterpartyDetails_.Insert("DescriptionFull", "");
	CounterpartyDetails_.Insert("DescriptionInternational", "");
	CounterpartyDetails_.Insert("TIN", "");
	CounterpartyDetails_.Insert("CRTR", "");
	CounterpartyDetails_.Insert("RegistrationCountry", Undefined);
	CounterpartyDetails_.Insert("LegalEntityIndividual", Undefined);
	
	Return CounterpartyDetails_;

EndFunction

Function PartnerSAttributesForFillingInForm()

	PartnerDetails_ = New Structure;
	PartnerDetails_.Insert("Description", "");
	PartnerDetails_.Insert("DescriptionFull", "");
	PartnerDetails_.Insert("Client", True);
	PartnerDetails_.Insert("Vendor", True);
	PartnerDetails_.Insert("OtherRelations", True);
	PartnerDetails_.Insert("LegalEntityIndividual", Enums.IndividualCompany.Company);
	
	Return PartnerDetails_;

EndFunction

Function CreatePartner(Filter)

	NewPartner = Catalogs.Partners.CreateItem();
	FillPropertyValues(NewPartner, Filter);
	NewPartner.RegistrationDate = CurrentSessionDate();
	NewPartner.Comment = NStr("vi = '#Đã tạo tự động khi kết nhập chứng từ ngân hàng';
								|ru = '#Создан автоматически при импорте банковских документов';
								|en = '#Created automatically while importing bank documents'; fa = '#Created automatically while importing bank documents';
								|it = '#Создан автоматически при импорте банковских документов';
								|pl = '#Tworzony automatycznie podczas importowania dokumentów bankowych';
								|tr = '#Banka belgelerini içe aktarırken otomatik olarak oluşturuldu'");
	NewPartner.Write();
	
	Result = NewPartner.Ref;
	
	Return Result;

EndFunction

Function FindCreateCounterparty(RawData, Filter, PartnerData)

	Result = New Structure("Counterparty, Partner");
	
	// search for an existing counterparty
	Result.Counterparty = LinkFromSelectionTable("Catalog.Counterparties", Filter);
	
	If ValueIsFilled(Result.Counterparty) Then
		
		Result.Partner = Common.ObjectAttributeValue(Result.Counterparty, "Partner");
		Return Result;
		
	EndIf;
	
	// creating a new counterparty if an existing one is not found
	NewCounterparty = Catalogs.Counterparties.CreateItem();
	FillPropertyValues(NewCounterparty, Filter);
	
	BeginTransaction();
	
	Try
	
		NewCounterparty.Partner = CreatePartner(PartnerData);
		NewCounterparty.Write();
		
		// checking the presence of a counterparty, excluding a newly created one
		Exceptions = New Structure("Ref", NewCounterparty.Ref);
		Result.Counterparty = LinkFromSelectionTable("Catalog.Counterparties", Filter, Exceptions);
		
		If ValueIsFilled(Result.Counterparty) Then
			Raise "Counterparty exists";
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		If Not ValueIsFilled(Result.Counterparty) Then
			
			// error recording a partner or counterparty
			Event = StrTemplate("%1 %2", NStr("ru = 'Загрузка платежей из банка.';
												|vi = 'Import payments from the bank.';
												|en = 'Import payments from the bank.'; fa = 'Import payments from the bank.';
												|it = 'Import payments from the bank.';
												|pl = 'Import payments from the bank.';
												|tr = 'Bankadan ödemelerin yüklenmesi.'", Common.DefaultLanguageCode()),
							NStr("ru = 'Создание контрагента';
								|vi = 'Create counterparty';
								|en = 'Create counterparty'; fa = 'ایجاد طرف حساب';
								|it = 'Create counterparty';
								|pl = 'Create counterparty';
								|tr = 'Cari hesap oluşturma'", Common.DefaultLanguageCode()));
			ErrorText = StrTemplate(NStr("ru = 'Ошибка записи контрагента %1 по причине: 
								|%2';
								|vi = 'An error occurred when saving the %1 counterparty. Reason:
								|%2';
								|en = 'An error occurred when saving the %1 counterparty. Reason:
								|%2'; fa = 'An error occurred when saving the %1 counterparty. Reason:
								|%2';
								|it = 'An error occurred when saving the %1 counterparty. Reason:
								|%2';
								|pl = 'An error occurred when saving the %1 counterparty. Reason:
								|%2';
								|tr = '%1 cari hesabının kaydedilmesinde hata, sebep: 
								| %2'"), Filter.DescriptionFull, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			WriteLogEvent(Event, EventLogLevel.Error, , , ErrorText);
			
		EndIf;
		
	EndTry;
	
	If Not NewCounterparty.IsNew() Then
		
		// processing a new counterparty
		Result.Partner = NewCounterparty.Partner;
		Result.Counterparty = NewCounterparty.Ref;
		
		ValidityDate = ?(ValueIsFilled(RawData.ProcessingDate), RawData.ProcessingDate, RawData.Date);
		FillInCounterpartySAddress(ValidityDate, Result.Counterparty, Filter.LegalEntityIndividual, RawData.CounterpartyAddress);
		
		EDIWithBanksLocalization.StartFillingInCounterpartyData(Result.Counterparty, Filter, ValidityDate);
		
	Else
		// partner of an existing counterparty 
		Result.Partner = Common.ObjectAttributeValue(Result.Counterparty, "Partner");
	EndIf;
	
	Return Result;

EndFunction

Procedure FillInCounterpartyInUploadDocuments(Counterparty, Partner, DocumentsToImport, Filter)

	CounterpartyRecords = DocumentsToImport.FindRows(Filter);
	
	For Each CounterpartyRecord In CounterpartyRecords Do
		CounterpartyRecord.Counterparty = Counterparty;
		CounterpartyRecord.Partner = Partner;
	EndDo;

EndProcedure

Function BankAccountDetails()

	AccountAttributes = New Structure;
	AccountAttributes.Insert("Owner", Undefined);
	AccountAttributes.Insert("CashCurrency", Undefined);
	AccountAttributes.Insert("AccountNumber", "");
	AccountAttributes.Insert("ForeignBank", False);
	AccountAttributes.Insert("CountryOfBank", Catalogs.WorldCountries.EmptyRef());
	AccountAttributes.Insert("Bank", Undefined);
	AccountAttributes.Insert("ManualBankDetailsChange", False);
	AccountAttributes.Insert("BankBIC", "");
	AccountAttributes.Insert("BankSWIFTCode", "");
	AccountAttributes.Insert("BankDescription", "");
	AccountAttributes.Insert("BankCity", "");
	AccountAttributes.Insert("BankCorrAccount", "");
	AccountAttributes.Insert("TransferBank", "");
	AccountAttributes.Insert("TransferBankDetailsManualEdit", False);
	AccountAttributes.Insert("TransferBankDescription", "");
	AccountAttributes.Insert("TransferBankCity", "");
	AccountAttributes.Insert("TransferBankBIC", "");
	AccountAttributes.Insert("TransferBankCorrAccount", "");
	AccountAttributes.Insert("Description", "");
	
	Return AccountAttributes;

EndFunction

Function LinkFromSelectionTable(TableName, QueryOptions, ExceptionParameters = Undefined)

	Query = New Query;
	Query.Text = 
		"SELECT TOP 1
		|	Table.Ref AS Ref
		|FROM
		|	&TableName AS Table
		|WHERE
		|	NOT Table.DeletionMark
		|	AND &Conditions";
	
	ListOfConditions = New Array;
	
	For Each CurrentParameter In QueryOptions Do
		
		If ValueIsFilled(CurrentParameter.Value) Then
			
			ListOfConditions.Add(StrTemplate("Table.%1 = &%1", CurrentParameter.Key));
			Query.SetParameter(CurrentParameter.Key, CurrentParameter.Value);
			
		EndIf;
		
	EndDo;
	
	If ExceptionParameters <> Undefined Then
		
		For Each CurrentExceptionParameter In ExceptionParameters Do
			
			ListOfConditions.Add(StrTemplate("Table.%1 <> &%1", CurrentExceptionParameter.Key));
			Query.SetParameter(CurrentExceptionParameter.Key, CurrentExceptionParameter.Value);
			
		EndDo;
		
	EndIf;
	
	Query.Text = StrReplace(Query.Text, "&TableName", TableName);
	Query.Text = StrReplace(Query.Text, "&Conditions", StrConcat(ListOfConditions, " And ")); //@Query-part
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		Return Selection.Ref;
	Else
		Return Undefined;
	EndIf;

EndFunction

Function FindCreateCounterpartyBankAccount(Filter)

	Result = LinkFromSelectionTable("Catalog.CounterpartyBankAccounts", Filter);
	
	If Not ValueIsFilled(Result) Then
	
		NewAccount_ = Catalogs.CounterpartyBankAccounts.CreateItem();
		FillPropertyValues(NewAccount_, Filter);
		
		NewAccount_.Write();
		Result = NewAccount_.Ref;
		
	EndIf;
	
	Return Result;

EndFunction

Function TextOfDocumentEntryError()

	Return NStr("vi = 'Đã xảy ra lỗi trong khi ghi lại chứng từ!';
				|ru = 'Произошли ошибки при записи документа!';
				|en = 'Errors occurred when saving the document.'; fa = 'Errors occurred when saving the document.';
				|it = 'Произошли ошибки при записи документа!';
				|pl = 'Podczas pisania dokumentu wystąpiły błędy!';
				|tr = 'Belge kaydedilirken hatalar oluştu!'");

EndFunction

Procedure WriteDocumentModificationErrorToLog(Object, DocumentRef, Comment)

	Event = NStr("vi = 'Dữ liệu';
				|ru = 'Данные';
				|en = 'Data'; fa = 'داده';
				|it = 'Данные';
				|pl = 'Data';
				|tr = 'Veriler'", Common.DefaultLanguageCode())
		+ "." + NStr("vi = 'Thay đổi';
					|ru = 'Изменение';
					|en = 'Change'; fa = 'تغییر';
					|it = 'Изменение';
					|pl = 'Change';
					|tr = 'Değişiklik'", Common.DefaultLanguageCode());
	WriteLogEvent(
		Event,
		EventLogLevel.Error,
		Object.Metadata(),
		DocumentRef,
		Comment);

EndProcedure

Procedure OutputRecordingError(Object, ErrorDescription, ImportErrors)

	NameOfObject = String(Object);
	ThisIsNewDocument = Object.IsNew();
	
	MessageText  = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = '%1%2. %3';
			|ru = '%1%2. %3';
			|en = '%1%2. %3'; fa = '%1%2. %3';
			|it = '%1%2. %3';
			|pl = '%1%2. %3';
			|tr = '%1%2. %3'"),
		Upper(Left(NameOfObject, 1)) + Mid(NameOfObject, 2),
		?(ThisIsNewDocument, " " + NStr("vi = 'không được tạo';
										|ru = 'не создан';
										|en = 'not created'; fa = 'not created';
										|it = 'не создан';
										|pl = 'nie utworzony';
										|tr = 'oluşturulmadı'"), " " + NStr("vi = 'chưa ghi lại';
																			|ru = 'не записан';
																			|en = 'not saved'; fa = 'not saved';
																			|it = 'не записан';
																			|pl = 'nie zapisane';
																			|tr = 'kaydedilmedi'")),
		TextOfDocumentEntryError());
	
	DocumentRef = ?(ThisIsNewDocument, "", Object.Ref);
	
	DetailedErrorDetails = GenerateDescriptionOfDocumentRecordingError(ErrorDescription);
	
	ErrorText = NStr("vi = '%1
						|%2';
						|ru = '%1
						|%2';
						|en = '%1
						|%2'; fa = '%1
						|%2';
						|it = '%1
						|%2';
						|pl = '%1
						|%2';
						|tr = '%1
						|%2'");
	
	Comment = StringFunctionsClientServer.SubstituteParametersToString(
		ErrorText,
		DetailedErrorDetails,
		?(ThisIsNewDocument, MessageText, TextOfDocumentEntryError()));
	
	WriteDocumentModificationErrorToLog(Object, DocumentRef, Comment);
	
	If DetailedErrorDetails <> "" Then
		AddRemark(ImportErrors, DetailedErrorDetails);
	EndIf;

EndProcedure

Procedure WriteObject(ObjectToWrite1, WriteMode, DocumentLine)
	
	ObjectIsModified = ObjectToWrite1.Modified();
	ObjectCompleted      = ObjectToWrite1.Posted;
	Post = (WriteMode = DocumentWriteMode.Posting Or ObjectCompleted And WriteMode = DocumentWriteMode.Write);
	
	If ObjectIsModified
		And Not Post Then
		Try
			ObjectToWrite1.Write(WriteMode);
		Except
			
			ErrorDescription = ErrorInfo();
			OutputRecordingError(ObjectToWrite1, ErrorDescription, DocumentLine.ImportErrors);
			Return;
			
		EndTry;
	EndIf;
	
	If Post And (ObjectIsModified Or Not ObjectCompleted) Then
		
		// Saving the decryption of the payment before the transaction
		CopyOfPaymentTranscript = Undefined;
		
		If ObjectToWrite1.ARAPDetails.Count() > 0 Then
			CopyOfPaymentTranscript = ObjectToWrite1.ARAPDetails.Unload();
		EndIf;
		
		Try
			ObjectToWrite1.Write(DocumentWriteMode.Posting);
		Except
			
			ErrorDescription = ErrorInfo();
			ErrorText = NStr("vi = '%1
				|Đã xảy ra lỗi khi kết chuyển!';
				|ru = '%1
				|Произошли ошибки при проведении!';
				|en = '%1 
				|Errors occurred when posting.'; fa = '%1 
				|Errors occurred when posting.';
				|it = '%1
				|Произошли ошибки при проведении!';
				|pl = '%1
				|Wystąpiły błędy podczas księgowania!';
				|tr = '%1
				|Kaydedilirken hatalar oluştu!'");
			
			DetailedErrorDetails = GenerateDescriptionOfDocumentRecordingError(ErrorDescription);
			Comment = StringFunctionsClientServer.SubstituteParametersToString(
				ErrorText,
				DetailedErrorDetails);
			WriteDocumentModificationErrorToLog(ObjectToWrite1, ObjectToWrite1.Ref, Comment);
			
			If ErrorDescription.Cause <> Undefined Then
				AddRemark(DocumentLine.ImportErrors, DetailedErrorDetails);
			EndIf;
			
		EndTry;
		
		If Not ObjectToWrite1.Posted Then
			
			// Restoring the decryption of the payment before the execution in case of an error in the execution,
			// because during the recording of the object, a settlement object is created and filled into the tabular part,
			// and after the transaction is rolled back, a link remains, a non-existing settlement object ("broken link").
			If CopyOfPaymentTranscript <> Undefined Then
				ObjectToWrite1.ARAPDetails.Load(CopyOfPaymentTranscript);
			EndIf;
			
			Try
				ObjectToWrite1.Write(DocumentWriteMode.Write);
			Except
				ErrorDescription = ErrorInfo();
				OutputRecordingError(ObjectToWrite1, ErrorDescription, DocumentLine.ImportErrors);
			EndTry;
		
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure FillInLinksToDocuments(DocumentsToImport, DocumentsTable, BankAccount)
	
	Query = New Query;
	TempTablesManager = New TempTablesManager;
	Query.TempTablesManager = TempTablesManager;
	
	Query.Text = "
	|SELECT
	|	DocumentsTable.LineNumber,
	|	DocumentsTable.DocDate,
	|	DocumentsTable.Received,
	|	DocumentsTable.WrittenOff,
	|	DocumentsTable.Number,
	|	DocumentsTable.ShortNumber,
	|	DocumentsTable.Outgoing,
	|	DocumentsTable.PaymentDocumentType,
	|	DocumentsTable.BeneficiaryAccount,
	|	DocumentsTable.PayerAccount,
	|	DocumentsTable.BeneficiaryTIN,
	|	DocumentsTable.PayerTIN,
	|	DocumentsTable.BeneficiaryCRTR,
	|	DocumentsTable.KPPPayer,
	|	DocumentsTable.CheckTIN,
	|	DocumentsTable.CheckCRTR,
	|	CAST(DocumentsTable.Code AS STRING(25)) AS Code,
	|	CAST(DocumentsTable.StatementData AS STRING(1024)) AS StatementData,
	|	CAST(DocumentsTable.Operation AS STRING(128)) AS Operation,
	|	DocumentsTable.ThisIsBankFeedsImport, 
	|	DocumentsTable.FPSTransactionID, 
	|	DocumentsTable.DocumentAmount 
	|
	|INTO DocumentsTable
	|
	|FROM
	|	&DocumentsTable AS DocumentsTable
	|";
	
	Query.SetParameter("DocumentsTable", DocumentsTable);
	Query.Execute();
	
	Query.Text = "
	|SELECT
	|	DocumentsTable.LineNumber AS LineNumber,
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.BusinessOperation AS BusinessOperation
	|
	|FROM
	|	DocumentsTable
	|	
	|	LEFT JOIN
	|		Document.BankAccountIssue AS DocumentData
	|	ON
	|		DocumentData.BankAccount = &BankAccount
	|		
	|		AND (BEGINOFPERIOD(DocumentData.IncomingDocumentDate, DAY) = DocumentsTable.DocDate
	|			AND NOT DocumentData.ProcessedByBank
	|			OR BEGINOFPERIOD(DocumentData.IncomingDocumentDate, DAY) = DocumentsTable.DocDate
	|				AND DocumentData.BankPostingDate = DocumentsTable.WrittenOff
	|				AND DocumentData.ProcessedByBank)
	|		
	|		AND (DocumentData.IncomingDocumentNumber = DocumentsTable.Number
	|			OR DocumentData.IncomingDocumentNumber = DocumentsTable.ShortNumber)
	|		AND DocumentData.PaymentDocumentType = DocumentsTable.PaymentDocumentType
	|	
	|		AND (DocumentData.BankAccountBeneficiary.AccountNumber = DocumentsTable.BeneficiaryAccount
	|			OR DocumentData.CounterpartyBankAccount.AccountNumber = DocumentsTable.BeneficiaryAccount
	|			OR (ISNULL(DocumentData.BankAccountBeneficiary.AccountNumber, """") = """"
	|				AND ISNULL(DocumentData.CounterpartyBankAccount.AccountNumber, """") = """")
	|			OR DocumentsTable.BeneficiaryAccount = """"
	|			)
	|		
	|WHERE
	|	DocumentsTable.Outgoing
	|	AND NOT DocumentData.Ref IS NULL
	|	AND NOT DocumentData.DeletionMark
	|	
	|UNION ALL
	|	
	|SELECT
	|	DocumentsTable.LineNumber AS LineNumber,
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.BusinessOperation AS BusinessOperation
	|
	|FROM
	|	DocumentsTable
	|	
	|	LEFT JOIN
	|		Document.BankAccountReceiptNote AS DocumentData
	|	ON
	|		DocumentData.BankAccount = &BankAccount
	|		
	|		AND (BEGINOFPERIOD(DocumentData.IncomingDocumentDate, DAY) = DocumentsTable.DocDate
	|			AND NOT DocumentData.ProcessedByBank
	|			OR BEGINOFPERIOD(DocumentData.IncomingDocumentDate, DAY) = DocumentsTable.DocDate
	|				AND DocumentData.BankPostingDate = DocumentsTable.Received
	|				AND DocumentData.ProcessedByBank)
	|		
	|		AND (DocumentData.IncomingDocumentNumber = DocumentsTable.Number
	|			OR DocumentData.IncomingDocumentNumber = DocumentsTable.ShortNumber
	|			OR DocumentData.IncomingDocumentNumber = """"
	|				AND NOT DocumentData.ProcessedByBank
	|				AND DocumentData.FPSTransactionID <> """"
	|				AND DocumentsTable.FPSTransactionID <> """"
	|				AND DocumentData.FPSTransactionID = DocumentsTable.FPSTransactionID
	|			OR DocumentData.IncomingDocumentNumber = """"
	|				AND NOT DocumentData.ProcessedByBank
	|				AND DocumentData.FPSTransactionID <> """"
	|				AND DocumentsTable.FPSTransactionID = """"
	|				AND DocumentData.DocumentAmount = DocumentsTable.DocumentAmount)
	|		AND DocumentData.PaymentDocumentType = DocumentsTable.PaymentDocumentType
	|		
	|		AND (DocumentData.SenderBankAccount.AccountNumber = DocumentsTable.PayerAccount
	|			OR DocumentData.CounterpartyBankAccount.AccountNumber = DocumentsTable.PayerAccount
	|			OR (ISNULL(DocumentData.SenderBankAccount.AccountNumber, """") = """"
	|				AND ISNULL(DocumentData.CounterpartyBankAccount.AccountNumber, """") = """")
	|			OR DocumentsTable.PayerAccount = """"
	|			)
	|		AND (
	|			(CAST(DocumentData.StatementData AS STRING(1024)) = DocumentsTable.StatementData
	|				AND CAST(DocumentData.StatementData AS STRING(1024)) <> """")
	|			OR DocumentsTable.ThisIsBankFeedsImport)
	|		
	|WHERE
	|	NOT DocumentsTable.Outgoing
	|	AND NOT DocumentData.Ref IS NULL
	|	AND NOT DocumentData.DeletionMark
	|	
	|
	|ORDER BY
	|	Posted DESC";
	
	Query.SetParameter("BankAccount", BankAccount);
	
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		DocumentLine = DocumentsToImport.Find(Selection.LineNumber, "LineNumber");
		If DocumentLine <> Undefined Then
			
			// If the document is found, we will not create a new one. If several documents are found,
			// then we skip duplicates of the document, update only the first document found.
			If ValueIsFilled(DocumentLine.Document) Then
				Continue;
			EndIf;
			DocumentLine.Document = Selection.Ref;
			DocumentLine.DocumentIsFoundInBase = True;
			DocumentLine.OperationKind = Selection.BusinessOperation;
			
		EndIf;
	EndDo;
	
EndProcedure

Function SplitListOfUIPS(DocumentsTable)
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	UIPTable.Code AS Code,
		|	UIPTable.LineNumber AS LineNumber,
		|	UIPTable.Outgoing AS Outgoing
		|INTO ListOfUIPS
		|FROM
		|	&UIPTable AS UIPTable
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ListOfUIPS.LineNumber AS LineNumber,
		|	ListOfUIPS.Code AS Code,
		|	ListOfUIPS.Outgoing AS Outgoing
		|INTO ListOfCurrencyConversionUIPS
		|FROM
		|	ListOfUIPS AS ListOfUIPS
		|WHERE
		|	ListOfUIPS.Code LIKE &ConversionPrefix
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ListOfUIPS.Code AS Code,
		|	ListOfUIPS.LineNumber AS LineNumber,
		|	ListOfUIPS.Outgoing AS Outgoing
		|INTO ListOfUIPSettlementsWithCounterparties
		|FROM
		|	ListOfUIPS AS ListOfUIPS
		|WHERE
		|	NOT ListOfUIPS.LineNumber IN
		|				(SELECT
		|					ListOfCurrencyConversionUIPS.LineNumber AS LineNumber
		|				FROM
		|					ListOfCurrencyConversionUIPS AS ListOfCurrencyConversionUIPS)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ListOfUIPSettlementsWithCounterparties.Code AS Code,
		|	ListOfUIPSettlementsWithCounterparties.LineNumber AS LineNumber
		|FROM
		|	ListOfUIPSettlementsWithCounterparties AS ListOfUIPSettlementsWithCounterparties
		|WHERE
		|	ListOfUIPSettlementsWithCounterparties.Outgoing
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ListOfUIPSettlementsWithCounterparties.Code AS Code,
		|	ListOfUIPSettlementsWithCounterparties.LineNumber AS LineNumber
		|FROM
		|	ListOfUIPSettlementsWithCounterparties AS ListOfUIPSettlementsWithCounterparties
		|WHERE
		|	NOT ListOfUIPSettlementsWithCounterparties.Outgoing
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ListOfCurrencyConversionUIPS.LineNumber AS LineNumber,
		|	ListOfCurrencyConversionUIPS.Code AS Code
		|FROM
		|	ListOfCurrencyConversionUIPS AS ListOfCurrencyConversionUIPS
		|WHERE
		|	NOT ListOfCurrencyConversionUIPS.Outgoing";
	
	Query.SetParameter("UIPTable", DocumentsTable);
	Query.SetParameter("ConversionPrefix", NStr("vi = 'TT%';
												|ru = 'ПП%';
												|en = '#%'; fa = '#%';
												|it = 'ПП%';
												|pl = '#%';
												|tr = 'PP%'", Common.DefaultLanguageCode()));
	
	QueriesArray = Query.ExecuteBatch();
	UIPSettlementsWithSuppliers = QueriesArray[QueriesArray.UBound() - 2].Unload();
	VIPSettlementsWithClients = QueriesArray[QueriesArray.UBound() - 1].Unload();
	UIPConversion = QueriesArray[QueriesArray.UBound()].Unload();
	
	UIPLists = New Structure;
	UIPLists.Insert("UIPSettlementsWithSuppliers", UIPSettlementsWithSuppliers);
	UIPLists.Insert("VIPSettlementsWithClients", VIPSettlementsWithClients);
	UIPLists.Insert("UIPConversion", UIPConversion);
	
	Return UIPLists;
	
EndFunction

Procedure FillInBasisOfPaymentsForUIP(DocumentsToImport, DocumentsTable, BankAccount)
	
	UIPLists = SplitListOfUIPS(DocumentsTable);
	
	If UIPLists.VIPSettlementsWithClients.Count() <> 0 Then
		FillInPaymentsToBeUploadedUsingUIP(False, BankAccount, DocumentsToImport, UIPLists.VIPSettlementsWithClients);
	EndIf;
	
	If UIPLists.UIPSettlementsWithSuppliers.Count() <> 0 Then
		
		FillInPaymentsToBeUploadedUsingUIP(True, BankAccount, DocumentsToImport, UIPLists.UIPSettlementsWithSuppliers);
		EDIWithBanksLocalization.SetCalculationAttributeWithSelfEmployedByCalculationObject(DocumentsToImport);
		
	EndIf;
	
	If UIPLists.UIPConversion.Count() <> 0 Then
	
		DocumentsData = CashServer.GroundsOfOperationOfConversionByUIP(
			UIPLists.UIPConversion.UnloadColumn("Code"), CurrentSessionDate());
	
		For Each CurrentData In DocumentsData Do
			
			IdFilter = New Structure;
			IdFilter.Insert("Code", CurrentData.PaymentID);
			DocumentStrings = DocumentsToImport.FindRows(IdFilter);
			
			For Each DocumentLine In DocumentStrings Do
				
				DocumentLine.PaymentBasisIsFound = True;
				DocumentLine.CounterpartyIsFound = True;
				DocumentLine.CreateCounterparty = False;
			
				FillPropertyValues(
					DocumentLine,
					CurrentData, 
					"Counterparty, Partner, PaymentPurpose, Department, CashFlowItem, CurrencyOfConversion, ConversionAmount");
				DocumentLine.OperationKind = Enums.BusinessTransactions.CurrencyConversion;
			
			EndDo;
			
		EndDo;
		
	EndIf;
	
EndProcedure

Function DetailsOfBusinessTransactionsReceipts()
	
	DetailsOfBusinessTransactions = New Map;
	
	DetailsOfBusinessTransactions.Insert(Enums.BusinessTransactions.CashReceiptFromCustomer,
		New Structure("ARAPDetailsCashFlowItem"));
	DetailsOfBusinessTransactions.Insert(Enums.BusinessTransactions.CashRecieptByAcquiringTransactionsPayment,
		New Structure("AcquiringContract, Department, ExpenseItem, DimensionOfExpenses, CashFlowItem"));
	DetailsOfBusinessTransactions.Insert(Enums.BusinessTransactions.CashReceiptFromOtherCompany,
		New Structure("ARAPDetailsCashFlowItem"));
	DetailsOfBusinessTransactions.Insert(Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices,
		New Structure("CashFlowItem"));
	DetailsOfBusinessTransactions.Insert(Enums.BusinessTransactions.CashReceiptFromAnotherAccount,
		New Structure(""));
	DetailsOfBusinessTransactions.Insert(Enums.BusinessTransactions.CashCollectionToBank,
		New Structure("CashAccount"));
	DetailsOfBusinessTransactions.Insert(Enums.BusinessTransactions.CashReceiptFromLoansRepayment,
		New Structure("ARAPDetailsCashFlowItem"));
	DetailsOfBusinessTransactions.Insert(Enums.BusinessTransactions.CashReceiptUnderDeposits,
		New Structure("ARAPDetailsCashFlowItem"));
	DetailsOfBusinessTransactions.Insert(Enums.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty,
		New Structure("ARAPDetailsCashFlowItem"));
	DetailsOfBusinessTransactions.Insert(Enums.BusinessTransactions.CurrencyConversion,
		New Structure("CashFlowItem"));
	DetailsOfBusinessTransactions.Insert(Enums.BusinessTransactions.OtherCashReceipt,
		New Structure("ARAPDetailsCashFlowItem, ARAPDetailsIncomeItem, ARAPDetailsDimensionOfRevenue, ARAPDetailsAssetsLiabilitiesDimension, ARAPDetailsDepartment"));
	DetailsOfBusinessTransactions.Insert(Enums.BusinessTransactions.RefundFromVendor,
		New Structure("ARAPDetailsCashFlowItem"));
	DetailsOfBusinessTransactions.Insert(Enums.BusinessTransactions.CashReturnByAdvanceHolder,
		New Structure("CashFlowItem"));
	DetailsOfBusinessTransactions.Insert(Enums.BusinessTransactions.RefundFromAnotherCompany,
		New Structure("ARAPDetailsCashFlowItem"));
	DetailsOfBusinessTransactions.Insert(Enums.BusinessTransactions.UnremittedSalaryReturnToPersonalAccounts,
		New Structure(""));
	DetailsOfBusinessTransactions.Insert(Enums.BusinessTransactions.TaxRefund,
		New Structure("TaxType, GLAccountSettings, ARAPDetailsCashFlowItem"));
	
	Return DetailsOfBusinessTransactions;
	
EndFunction

Function DetailsOfBusinessTransactionsWriteOff()
	
	DetailsOfBusinessTransactions = New Map;
	
	DetailsOfBusinessTransactions.Insert(Enums.BusinessTransactions.PaymentToVendor,
		New Structure("ARAPDetailsCashFlowItem"));
	DetailsOfBusinessTransactions.Insert(Enums.BusinessTransactions.IssueCashToAdvanceHolder,
		New Structure("AdvanceHolder, Department, ARAPDetailsCashFlowItem"));
	DetailsOfBusinessTransactions.Insert(Enums.BusinessTransactions.TransferOfTaxesAndContributions,
		New Structure("TaxType, GLAccountSettings, ARAPDetailsCashFlowItem"));
	DetailsOfBusinessTransactions.Insert(Enums.BusinessTransactions.CustomsPayment,
		New Structure("ARAPDetailsCashFlowItem"));
	DetailsOfBusinessTransactions.Insert(Enums.BusinessTransactions.CashPaymentToAnotherCompany,
		New Structure("ARAPDetailsCashFlowItem"));
	DetailsOfBusinessTransactions.Insert(Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices,
		New Structure("CashFlowItem"));
	DetailsOfBusinessTransactions.Insert(Enums.BusinessTransactions.SalaryPaymentToBankAccounts,
		New Structure("CashFlowItem, Department"));
	DetailsOfBusinessTransactions.Insert(Enums.BusinessTransactions.SalaryPaymentByPayrollCardProgram,
		New Structure("CashFlowItem, Department"));
	DetailsOfBusinessTransactions.Insert(Enums.BusinessTransactions.TransferCashToAnotherAccount,
		New Structure(""));
	DetailsOfBusinessTransactions.Insert(Enums.BusinessTransactions.CashCollectionFromBank,
		New Structure("CashAccountRecipient"));
	DetailsOfBusinessTransactions.Insert(Enums.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived,
		New Structure("ARAPDetailsCashFlowItem"));
	DetailsOfBusinessTransactions.Insert(Enums.BusinessTransactions.TransferToDeposits,
		New Structure("ARAPDetailsCashFlowItem"));
	DetailsOfBusinessTransactions.Insert(Enums.BusinessTransactions.CashIssueAsLoanToCounterparty,
		New Structure("ARAPDetailsCashFlowItem"));
	DetailsOfBusinessTransactions.Insert(Enums.BusinessTransactions.CurrencyConversion,
		New Structure("CashFlowItem"));
	DetailsOfBusinessTransactions.Insert(Enums.BusinessTransactions.OtherCashIssue,
		New Structure("ARAPDetailsCashFlowItem, ARAPDetailsExpenseItem, ARAPDetailsDimensionOfExpenses, ARAPDetailsAssetsLiabilitiesDimension, ARAPDetailsDepartment"));
	DetailsOfBusinessTransactions.Insert(Enums.BusinessTransactions.RefundToCustomer,
		New Structure("ARAPDetailsCashFlowItem"));
	DetailsOfBusinessTransactions.Insert(Enums.BusinessTransactions.RefundToAnotherCompany,
		New Structure("ARAPDetailsCashFlowItem"));
	DetailsOfBusinessTransactions.Insert(Enums.BusinessTransactions.RefundAcquiringPayment,
		New Structure("AcquiringContract, Department, ExpenseItem, DimensionOfExpenses, CashFlowItem"));
	
	Return DetailsOfBusinessTransactions;
	
EndFunction

Function SearchIsCorrect(DocumentLine, Selection, AttributesSet, ConditionText)
	
	Query = New Query;
	
	If DocumentLine.Outgoing Then
		
		Query.Text = "
		|SELECT TOP 1
		|	1
		|FROM
		|	Document.BankAccountIssue AS DocumentData
		|	
		|	LEFT JOIN
		|		Document.BankAccountIssue.ARAPDetails AS TabPart
		|	ON
		|		TabPart.Ref = DocumentData.Ref
		|WHERE
		|	&Condition
		|	
		|";
		
	Else
		
		Query.Text = "
		|SELECT TOP 1
		|	1
		|FROM
		|	Document.BankAccountReceiptNote AS DocumentData
		|	
		|	LEFT JOIN
		|		Document.BankAccountReceiptNote.ARAPDetails AS TabPart
		|	ON
		|		TabPart.Ref = DocumentData.Ref
		|WHERE
		|	&Condition
		|	
		|";
	EndIf;
	
	Query.Text = StrReplace(Query.Text, "&Condition", ConditionText);
	
	Query.SetParameter("BankAccount", DocumentLine.BankAccount);
	Query.SetParameter("AccountOfCounterparty", DocumentLine.AccountOfCounterparty);
	
	If Query.FindParameters().Find("Counterparty") <> Undefined Then
		Query.SetParameter("Counterparty", DocumentLine.Counterparty);
	EndIf;
	If Query.FindParameters().Find("FormattedPurposeOfPayment") <> Undefined Then
		Query.SetParameter("FormattedPurposeOfPayment", DocumentLine.FormattedPurposeOfPayment);
	EndIf;
	
	Query.Text = Query.Text + "
	|	AND DocumentData.Posted
	|	AND DocumentData.Date > &VerificationPeriod";
	Query.SetParameter("VerificationPeriod", CurrentSessionDate() - 60 * 60 * 24 * 15); // Documents are checked for the last 15 days
	
	If ValueIsFilled(DocumentLine.OperationKind) Then
		Query.Text = Query.Text + " AND DocumentData.BusinessOperation = &BusinessOperation AND (TRUE";
		Query.SetParameter("BusinessOperation", DocumentLine.OperationKind);
	Else
		Query.Text = Query.Text + " AND (DocumentData.BusinessOperation <> &BusinessOperation";
		Query.SetParameter("BusinessOperation", Selection.BusinessOperation);
	EndIf;
	
	ConditionString = "";
	If AttributesSet <> Undefined Then
		For Each Attribute In AttributesSet Do
			
			If Not ValueIsFilled(Attribute.Value) Then
				Continue;
			EndIf;
			
			If StrFind(Attribute.Key, "ARAPDetails") Then
				AttributeName = Mid(Attribute.Key, StrLen("ARAPDetails") + 1);
				ConditionString = " OR TabPart.AttributeName <> &AttributeName";
			Else
				AttributeName = Attribute.Key;
				ConditionString = " OR DocumentData.AttributeName <> &AttributeName";
			EndIf;
			
			ConditionString = StrReplace(ConditionString, "AttributeName", AttributeName);
			Query.Text = Query.Text + ConditionString;
			Query.SetParameter(AttributeName, Attribute.Value);
		EndDo;
	EndIf;
	
	Query.Text = Query.Text + ")";
	
	Result = Query.Execute();
	
	Return Result.IsEmpty();
	
EndFunction

Procedure FillInSamples(LinesToLoad, BankAccount)
	
	DetailsOfBusinessTransactionsReceipts = DetailsOfBusinessTransactionsReceipts();
	DetailsOfBusinessTransactionsWriteOff = DetailsOfBusinessTransactionsWriteOff();
	
	Query = New Query;
	
	QueryTextIncomingMessages = "
	|SELECT TOP 1
	|	DocumentData.Ref                          AS Ref,
	|	DocumentData.BusinessOperation           AS BusinessOperation,
	|	TabPart.CashFlowItem          AS ARAPDetailsCashFlowItem,
	|	DocumentData.CashFlowItem   AS CashFlowItem,
	|	DocumentData.AdvanceHolder                 AS AdvanceHolder,
	|	DocumentData.CashAccountIssuer                AS CashAccountIssuer,
	|	TabPart.Department                          AS ARAPDetailsDepartment,
	|	DocumentData.Department                   AS Department,
	|	TabPart.IncomeItem                          AS ARAPDetailsIncomeItem,
	|	TabPart.DimensionOfRevenue                       AS ARAPDetailsDimensionOfRevenue,
	|	TabPart.AssetsLiabilitiesDimension               AS ARAPDetailsAssetsLiabilitiesDimension,
	|	DocumentData.AcquiringContract               AS AcquiringContract,
	|	DocumentData.ExpenseItem                  AS ExpenseItem,
	|	DocumentData.DimensionOfExpenses               AS DimensionOfExpenses,
	|	DocumentData.TaxType                       AS TaxType,
	|	DocumentData.GLAccountSettings            AS GLAccountSettings,
	|	DocumentData.PaymentID            AS PaymentID
	|	
	|FROM
	|	Document.BankAccountReceiptNote AS DocumentData
	|	
	|	LEFT JOIN
	|		Document.BankAccountReceiptNote.ARAPDetails AS TabPart
	|	ON
	|		TabPart.Ref = DocumentData.Ref
	|	
	|WHERE
	|	&Condition
	|	
	|ORDER BY
	|	DocumentData.Date DESC
	|";
	
	QueryTextOutbox = "
	|SELECT TOP 1
	|	DocumentData.Ref                          AS Ref,
	|	DocumentData.BusinessOperation           AS BusinessOperation,
	|	TabPart.CashFlowItem          AS ARAPDetailsCashFlowItem,
	|	DocumentData.CashFlowItem   AS CashFlowItem,
	|	DocumentData.AdvanceHolder                 AS AdvanceHolder,
	|	DocumentData.CashAccountRecipient                 AS CashAccountRecipient,
	|	TabPart.Department                          AS ARAPDetailsDepartment,
	|	DocumentData.Department                   AS Department,
	|	TabPart.ExpenseItem                         AS ARAPDetailsExpenseItem,
	|	TabPart.DimensionOfExpenses                      AS ARAPDetailsDimensionOfExpenses,
	|	TabPart.AssetsLiabilitiesDimension               AS ARAPDetailsAssetsLiabilitiesDimension,
	|	DocumentData.AcquiringContract               AS AcquiringContract,
	|	DocumentData.ExpenseItem                  AS ExpenseItem,
	|	DocumentData.DimensionOfExpenses               AS DimensionOfExpenses,
	|	DocumentData.TaxType                       AS TaxType,
	|	DocumentData.GLAccountSettings            AS GLAccountSettings,
	|	DocumentData.PaymentID            AS PaymentID
	|	
	|FROM
	|	Document.BankAccountIssue AS DocumentData
	|	
	|	LEFT JOIN
	|		Document.BankAccountIssue.ARAPDetails AS TabPart
	|	ON
	|		TabPart.Ref = DocumentData.Ref
	|	
	|WHERE
	|	&Condition
	|	
	|ORDER BY
	|	DocumentData.Date DESC
	|";
	
	Query.SetParameter("BankAccount", BankAccount);
	
	// Step 1. Search by sender's account, recipient, payment purpose
	OutgoingConditions = "
	|	DocumentData.BankAccount = &BankAccount
	|	AND (DocumentData.CounterpartyBankAccount = &AccountOfCounterparty
	|		OR DocumentData.BankAccountBeneficiary = &AccountOfCounterparty)
	|	AND DocumentData.FormattedPurposeOfPayment = &FormattedPurposeOfPayment
	|	AND DocumentData.Posted
	|";

	ConditionIncoming = "
	|	DocumentData.BankAccount = &BankAccount
	|	AND (DocumentData.CounterpartyBankAccount = &AccountOfCounterparty
	|		OR DocumentData.SenderBankAccount = &AccountOfCounterparty
	|		OR (DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CashRecieptByAcquiringTransactionsPayment)
	|			AND DocumentData.Counterparty = &Counterparty))
	|	AND DocumentData.FormattedPurposeOfPayment = &FormattedPurposeOfPayment
	|	AND DocumentData.Posted
	|";
	
	SearchStringsStep2 = New Array;
	For Each DocumentLine In LinesToLoad Do
		
		If DocumentLine.Outgoing Then
			Query.Text = QueryTextOutbox;
			ConditionText = OutgoingConditions;
			Attributes = DetailsOfBusinessTransactionsWriteOff;
		Else
			Query.Text = QueryTextIncomingMessages;
			ConditionText = ConditionIncoming;
			Attributes = DetailsOfBusinessTransactionsReceipts;
		EndIf;
		
		If ValueIsFilled(DocumentLine.OperationKind) Then
			ConditionText = ConditionText + "
			|	AND DocumentData.BusinessOperation = &BusinessOperation";
			Query.SetParameter("BusinessOperation", DocumentLine.OperationKind);
		EndIf;
		
		Query.Text = StrReplace(Query.Text, "&Condition", ConditionText);
		
		If Query.FindParameters().Find("Counterparty") <> Undefined Then
			Query.SetParameter("Counterparty", DocumentLine.Counterparty);
		EndIf;
		
		Query.SetParameter("AccountOfCounterparty", DocumentLine.AccountOfCounterparty);
		Query.SetParameter("FormattedPurposeOfPayment", DocumentLine.FormattedPurposeOfPayment);
		
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			
			AttributesSet = Attributes.Get(Selection.BusinessOperation);
			If AttributesSet <> Undefined Then
				
				FillPropertyValues(AttributesSet, Selection);
				
				If SearchIsCorrect(DocumentLine, Selection, AttributesSet, ConditionText) Then
					
					DocumentLine.FoundSample = True;
					DocumentLine.Pattern = Selection.Ref;
					DocumentLine.OperationKind = Selection.BusinessOperation;
					
					For Each Attribute In AttributesSet Do
						If Not ValueIsFilled(Attribute.Value) Then
							Continue;
						EndIf;
						If StrFind(Attribute.Key, "ARAPDetails") Then
							AttributeName = Mid(Attribute.Key, StrLen("ARAPDetails") + 1);
						Else
							AttributeName = Attribute.Key;
						EndIf;
						DocumentLine[AttributeName] = Attribute.Value;
					EndDo;
				EndIf;
			EndIf;
		Else
			SearchStringsStep2.Add(DocumentLine);
		EndIf;
	EndDo;
	
	If Not SearchStringsStep2.Count() Then
		Return;
	EndIf;
	
	// Step 2. Search by the account of the sender, recipient, without taking into account the purpose of the payment
	OutgoingConditions = "
	|	DocumentData.BankAccount = &BankAccount
	|	AND (DocumentData.CounterpartyBankAccount = &AccountOfCounterparty
	|		OR DocumentData.BankAccountBeneficiary = &AccountOfCounterparty)
	|	AND DocumentData.Posted
	|";

	ConditionIncoming = "
	|	DocumentData.BankAccount = &BankAccount
	|	AND (DocumentData.CounterpartyBankAccount = &AccountOfCounterparty
	|		OR DocumentData.SenderBankAccount = &AccountOfCounterparty
	|		OR (DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CashRecieptByAcquiringTransactionsPayment)
	|			AND DocumentData.Counterparty = &Counterparty))
	|	AND DocumentData.Posted
	|";
	
	SearchStringsStep3 = New Array;
	For Each DocumentLine In SearchStringsStep2 Do
		
		If DocumentLine.Outgoing Then
			Query.Text = QueryTextOutbox;
			ConditionText = OutgoingConditions;
			Attributes = DetailsOfBusinessTransactionsWriteOff;
		Else
			Query.Text = QueryTextIncomingMessages;
			ConditionText = ConditionIncoming;
			Attributes = DetailsOfBusinessTransactionsReceipts;
		EndIf;
		
		If ValueIsFilled(DocumentLine.OperationKind) Then
			ConditionText = ConditionText + "
			|	AND DocumentData.BusinessOperation = &BusinessOperation";
			Query.SetParameter("BusinessOperation", DocumentLine.OperationKind);
		EndIf;
		
		Query.Text = StrReplace(Query.Text, "&Condition", ConditionText);
		
		Query.SetParameter("AccountOfCounterparty", DocumentLine.AccountOfCounterparty);
		If Query.FindParameters().Find("Counterparty") <> Undefined Then
			Query.SetParameter("Counterparty", DocumentLine.Counterparty);
		EndIf;
	
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			
			AttributesSet = Attributes.Get(Selection.BusinessOperation);
			If AttributesSet <> Undefined Then
				
				FillPropertyValues(AttributesSet, Selection);
				
				If SearchIsCorrect(DocumentLine, Selection, AttributesSet, ConditionText) Then
					
					DocumentLine.FoundSample = True;
					DocumentLine.Pattern = Selection.Ref;
					DocumentLine.OperationKind = Selection.BusinessOperation;
					
					For Each Attribute In AttributesSet Do
						If Not ValueIsFilled(Attribute.Value) Then
							Continue;
						EndIf;
						If StrFind(Attribute.Key, "ARAPDetails") Then
							AttributeName = Mid(Attribute.Key, StrLen("ARAPDetails") + 1);
						Else
							AttributeName = Attribute.Key;
						EndIf;
						DocumentLine[AttributeName] = Attribute.Value;
					EndDo;
				EndIf;
			EndIf;
		Else
			SearchStringsStep3.Add(DocumentLine);
		EndIf;
	EndDo;
	
	If Not SearchStringsStep3.Count() Then
		Return;
	EndIf;
	
	// Step 3. Mirror Payment
	OutgoingConditions = "
	|	DocumentData.BankAccount = &AccountOfCounterparty
	|	AND (DocumentData.CounterpartyBankAccount = &BankAccount
	|		OR DocumentData.BankAccountBeneficiary = &BankAccount)
	|	AND DocumentData.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.PaymentToVendor),
	|		VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder),
	|		VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany)
	|	)
	|	AND DocumentData.Posted
	|";
	
	ConditionIncoming = "
	|	DocumentData.BankAccount = &AccountOfCounterparty
	|	AND (DocumentData.CounterpartyBankAccount = &BankAccount
	|		OR DocumentData.SenderBankAccount = &BankAccount)
	|	AND DocumentData.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer),
	|		VALUE(Enum.BusinessTransactions.CashReceiptFromOtherCompany)
	|	)
	|	AND DocumentData.Posted
	|";
	
	SearchStringsStep4 = New Array;
	
	For Each DocumentLine In SearchStringsStep3 Do
		
		If DocumentLine.Outgoing Then
			Query.Text = QueryTextIncomingMessages;
			ConditionText = ConditionIncoming;
			Attributes = DetailsOfBusinessTransactionsReceipts;
		Else
			Query.Text = QueryTextOutbox;
			ConditionText = OutgoingConditions;
			Attributes = DetailsOfBusinessTransactionsWriteOff;
		EndIf;
		
		Query.Text = StrReplace(Query.Text, "&Condition", ConditionText);
		Query.SetParameter("AccountOfCounterparty", DocumentLine.AccountOfCounterparty);
		
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			
			AttributesSet = Attributes.Get(Selection.BusinessOperation);
			If AttributesSet <> Undefined Then
				
				FillPropertyValues(AttributesSet, Selection);
				
				DocumentLine.FoundSample = True;
				DocumentLine.Pattern = Selection.Ref;
				
				If Selection.BusinessOperation = Enums.BusinessTransactions.PaymentToVendor Then
					DocumentLine.OperationKind = Enums.BusinessTransactions.RefundFromVendor;
				ElsIf Selection.BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany Then
					DocumentLine.OperationKind = Enums.BusinessTransactions.CashReceiptFromOtherCompany;
				ElsIf Selection.BusinessOperation = Enums.BusinessTransactions.CashEquivalentsIssueToAdvanceHolder Then
					DocumentLine.OperationKind = Enums.BusinessTransactions.CashReturnByAdvanceHolder;
				EndIf;
				
				If Selection.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer Then
					DocumentLine.OperationKind = Enums.BusinessTransactions.RefundToCustomer;
				ElsIf Selection.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany Then
					DocumentLine.OperationKind = Enums.BusinessTransactions.CashPaymentToAnotherCompany;
				EndIf;
				
				For Each Attribute In AttributesSet Do
					If Not ValueIsFilled(Attribute.Value) Then
						Continue;
					EndIf;
					If StrFind(Attribute.Key, "ARAPDetails") Then
						AttributeName = Mid(Attribute.Key, StrLen("ARAPDetails") + 1);
					Else
						AttributeName = Attribute.Key;
					EndIf;
					DocumentLine[AttributeName] = Attribute.Value;
				EndDo;
			EndIf;
		Else
			SearchStringsStep4.Add(DocumentLine);
		EndIf;
	EndDo;
	
	If Not SearchStringsStep4.Count() Then
		Return;
	EndIf;
	
	// Step 4. Mirror payment: receipt of the converted currency
	
	OutgoingConditions = "
	|	DocumentData.BankAccount = &AccountOfCounterparty
	|	AND (DocumentData.CounterpartyBankAccount = &BankAccount
	|		OR DocumentData.BankAccountBeneficiary = &BankAccount)
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CurrencyConversion)
	|	AND DocumentData.PaymentID <> """"
	|	AND DocumentData.Posted
	|";
	
	For Each DocumentLine In SearchStringsStep4 Do
		
		If DocumentLine.Outgoing Then
			Continue;
		Else
			Query.Text = QueryTextOutbox;
			ConditionText = OutgoingConditions;
		EndIf;
		
		Query.Text = StrReplace(Query.Text, "&Condition", ConditionText);
		Query.SetParameter("AccountOfCounterparty", DocumentLine.AccountOfCounterparty);
		
		ConversionDocuments = Query.Execute().Unload();
		
		If ConversionDocuments.Count() = 0 Then
			Continue;
		EndIf;
		
		ListOfUIPS = ConversionDocuments.UnloadColumn("PaymentID");
		DocumentsData = CashServer.GroundsOfOperationOfConversionByUIP(ListOfUIPS, CurrentSessionDate());
		
		For Each DocumentData In DocumentsData Do
			
			If DocumentData.ConversionAmount > 0 Then
				
				DocumentLine.PaymentBasisIsFound = True;
				DocumentLine.CounterpartyIsFound = True;
				DocumentLine.CreateCounterparty = False;
				DocumentLine.OperationKind = Enums.BusinessTransactions.CurrencyConversion;
				DocumentLine.FoundSample = True;
				DocumentLine.Pattern = DocumentData.PaymentPurpose;
				
				FillPropertyValues(
					DocumentLine,
					DocumentData, 
					"PaymentID, Counterparty, Partner, PaymentPurpose, Department, CashFlowItem, CurrencyOfConversion, ConversionAmount");
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

Procedure FillOutPartners(DocumentsToImport, DocumentsTable, BankAccount)
	
	Organization = Catalogs.CompaniesBankAccounts.GetCompanySBankAccountDetails(BankAccount).Organization;
	
	Query = New Query;
	TempTablesManager = New TempTablesManager;
	Query.TempTablesManager = TempTablesManager;
	
	Query.Text = "
	|SELECT
	|	DocumentsTable.LineNumber,
	|	DocumentsTable.Counterparty AS Counterparty
	|
	|INTO DocumentsTable
	|
	|FROM
	|	&DocumentsTable AS DocumentsTable
	|WHERE
	|	DocumentsTable.Partner = VALUE(Catalog.Partners.EmptyRef)
	|";
	
	Query.SetParameter("DocumentsTable", DocumentsTable);
	Query.Execute();
	
	Query.Text = "
	|SELECT
	|	DocumentsTable.LineNumber,
	|	CASE WHEN CatalogData.Partner <> VALUE(Catalog.Partners.EmptyRef) THEN
	|		CatalogData.Partner
	|	WHEN NOT AccountingDimensionByPartners.Partner IS NULL THEN
	|		AccountingDimensionByPartners.Partner
	|	ELSE
	|		VALUE(Catalog.Partners.UnknownPartner)
	|	END AS Partner
	|
	|INTO FoundPartners
	|FROM
	|	DocumentsTable
	|	
	|	INNER JOIN
	|		Catalog.Counterparties AS CatalogData
	|	ON
	|		CatalogData.Ref = DocumentsTable.Counterparty
	|		
	|		LEFT JOIN
	|			InformationRegister.AccountingDimensionByPartners AS AccountingDimensionByPartners
	|		ON
	|			AccountingDimensionByPartners.Counterparty = CatalogData.Ref
	|			AND AccountingDimensionByPartners.Organization = &Organization
	|			AND AccountingDimensionByPartners.Partner <> VALUE(Catalog.Partners.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FoundPartners.LineNumber AS LineNumber,
	|	FoundPartners.Partner AS Partner,
	|	CASE
	|		WHEN ISNULL(Partners.OtherRelations, FALSE) = TRUE
	|				AND ISNULL(Partners.Client, FALSE) = FALSE
	|				AND ISNULL(Partners.Vendor, FALSE) = FALSE
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS OtherRelations
	|FROM
	|	FoundPartners AS FoundPartners
	|		LEFT JOIN Catalog.Partners AS Partners
	|		ON FoundPartners.Partner = Partners.Ref";
	
	Query.SetParameter("Organization", Organization);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		DocumentLine = DocumentsToImport.Find(Selection.LineNumber, "LineNumber");
		
		If DocumentLine <> Undefined Then
			DocumentLine.Partner = Selection.Partner;
			DocumentLine.OnlyOtherRelationships = Selection.OtherRelations;
		EndIf;
		
	EndDo;
	
EndProcedure

// Returns a table with AR/AP objects for counterparty Contracts.
// 
// Parameters:
//  BankAccount - CatalogRef.CompaniesBankAccounts -  The company's bank account.
//  Organization - CatalogRef.Companies -  Organization.
//  SourceTable - ValueTable - a table containing a list of counterparties and their accounts:
//   *Counterparty - CatalogRef.Companies, CatalogRef.Counterparties, String, CatalogRef.Persons - 
//                the counterparty for which the search for counterparty Contracts is performed.
//   *AccountOfCounterparty - CatalogRef.CounterpartyBankAccounts, CatalogRef.CompaniesBankAccounts, String - 
//                     The bank account of the counterparty that is used to search for counterparty Contracts.
// 
// Returns:
//  ValueTable -  List of AR/AP objects for the found Contracts of counterparties:
//   *Counterparty - CatalogRef.Companies, CatalogRef.Counterparties, String, CatalogRef.Persons - 
//                the counterparty for which the search for counterparty Contracts was performed.
//   *AccountOfCounterparty - CatalogRef.CounterpartyBankAccounts, CatalogRef.CompaniesBankAccounts, String - 
//                     The bank account of the counterparty that was used to search for counterparty Contracts.
//   *Contract - CatalogRef.CounterpartyContracts - the Contract of the counterparty found.
//   *CashFlowItem - CatalogRef.CashFlowReportItems - article of the DDS under the Contract.
//   *ARAPObject - CatalogRef.ARAPObjects - AR/AP object under the Contract.
//
Function ListOfSettlementObjectsUnderContracts(BankAccount, Organization, SourceTable)

	SourceTable.Indexes.Add("Counterparty, AccountOfCounterparty");
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	Table.Counterparty AS Counterparty,
		|	Table.AccountOfCounterparty AS AccountOfCounterparty
		|INTO CounterpartiesAndAccounts
		|FROM
		|	&Table AS Table
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CounterpartiesAndAccounts.Counterparty AS Counterparty,
		|	CounterpartiesAndAccounts.AccountOfCounterparty AS AccountOfCounterparty,
		|	CounterpartyContracts.Ref AS Contract,
		|	CounterpartyContracts.CounterpartyBankAccount AS CounterpartyBankAccount,
		|	CounterpartyContracts.BankAccount AS BankAccount,
		|	CounterpartyContracts.CashFlowItem AS CashFlowItem,
		|	CounterpartyContracts.ContractWithSelfEmployedPerson AS ContractWithSelfEmployedPerson,
		|	CounterpartyContracts.Status AS Status,
		|	UNDEFINED AS ARAPObject,
		|	CASE
		|		WHEN CounterpartyContracts.ContractType IN (
		|			VALUE(Enum.ContractTypes.WithCustomer),
		|			VALUE(Enum.ContractTypes.ReceiptForTolling2_5),
		|			VALUE(Enum.ContractTypes.WithConsignee),
		|			VALUE(Enum.ContractTypes.TransferToCustody),
		|			VALUE(Enum.ContractTypes.TransferToRental),
		|			VALUE(Enum.ContractTypes.Sublease),
		|			VALUE(Enum.ContractTypes.CustomerInvoiceOutsourcedSale),
		|			VALUE(Enum.ContractTypes.SalesViaCommissionAgent))
		|		THEN VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
		|		ELSE VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
		|	END AS PaymentType_
		|INTO Contracts_WithCounterparties
		|FROM
		|	Catalog.CounterpartyContracts AS CounterpartyContracts
		|		INNER JOIN CounterpartiesAndAccounts AS CounterpartiesAndAccounts
		|		ON CounterpartyContracts.Counterparty = CounterpartiesAndAccounts.Counterparty
		|			AND CounterpartyContracts.Organization = &Organization
		|			AND (CounterpartyContracts.Status = VALUE(Enum.CounterpartyContractStatuses.Valid)
		|				OR CounterpartyContracts.Status = VALUE(Enum.CounterpartyContractStatuses.NotApproved))
		|
		|INDEX BY
		|	CounterpartyBankAccount,
		|	BankAccount,
		|	Status
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CounterpartyContracts.Counterparty AS Counterparty,
		|	CounterpartyContracts.AccountOfCounterparty AS AccountOfCounterparty,
		|	CounterpartyContracts.Contract AS Contract,
		|	CounterpartyContracts.CashFlowItem AS CashFlowItem,
		|	CounterpartyContracts.ContractWithSelfEmployedPerson AS ContractWithSelfEmployedPerson,
		|	CounterpartyContracts.ARAPObject AS ARAPObject,
		|	CounterpartyContracts.PaymentType_ AS PaymentType_,
		|	CASE
		|		WHEN CounterpartyContracts.Status = VALUE(Enum.CounterpartyContractStatuses.Valid)
		|			THEN 1
		|		ELSE 2
		|	END AS Priority
		|FROM
		|	Contracts_WithCounterparties AS CounterpartyContracts
		|WHERE
		|	(CounterpartyContracts.CounterpartyBankAccount = CounterpartyContracts.AccountOfCounterparty
		|		OR CounterpartyContracts.CounterpartyBankAccount = VALUE(Catalog.CounterpartyBankAccounts.EmptyRef))
		|	AND (CounterpartyContracts.BankAccount = &BankAccount
		|		OR CounterpartyContracts.BankAccount = VALUE(Catalog.CompaniesBankAccounts.EmptyRef))
		|
		|UNION ALL
		|
		|SELECT
		|	CounterpartyContracts.Counterparty,
		|	CounterpartyContracts.AccountOfCounterparty,
		|	CounterpartyContracts.Contract,
		|	CounterpartyContracts.CashFlowItem,
		|	CounterpartyContracts.ContractWithSelfEmployedPerson,
		|	CounterpartyContracts.ARAPObject,
		|	CounterpartyContracts.PaymentType_,
		|	CASE
		|		WHEN CounterpartyContracts.Status = VALUE(Enum.CounterpartyContractStatuses.Valid)
		|			THEN 3
		|		ELSE 4
		|	END
		|FROM
		|	Contracts_WithCounterparties AS CounterpartyContracts
		|WHERE
		|	CounterpartyContracts.CounterpartyBankAccount <> CounterpartyContracts.AccountOfCounterparty
		|	AND CounterpartyContracts.CounterpartyBankAccount <> VALUE(Catalog.CounterpartyBankAccounts.EmptyRef)
		|	AND (CounterpartyContracts.BankAccount = &BankAccount
		|		OR CounterpartyContracts.BankAccount = VALUE(Catalog.CompaniesBankAccounts.EmptyRef))
		|
		|UNION ALL
		|
		|SELECT
		|	CounterpartyContracts.Counterparty,
		|	CounterpartyContracts.AccountOfCounterparty,
		|	CounterpartyContracts.Contract,
		|	CounterpartyContracts.CashFlowItem,
		|	CounterpartyContracts.ContractWithSelfEmployedPerson,
		|	CounterpartyContracts.ARAPObject,
		|	CounterpartyContracts.PaymentType_,
		|	CASE
		|		WHEN CounterpartyContracts.Status = VALUE(Enum.CounterpartyContractStatuses.Valid)
		|			THEN 3
		|		ELSE 4
		|	END
		|FROM
		|	Contracts_WithCounterparties AS CounterpartyContracts
		|WHERE
		|	(CounterpartyContracts.CounterpartyBankAccount = CounterpartyContracts.AccountOfCounterparty
		|		OR CounterpartyContracts.CounterpartyBankAccount = VALUE(Catalog.CounterpartyBankAccounts.EmptyRef))
		|	AND CounterpartyContracts.BankAccount <> &BankAccount
		|	AND CounterpartyContracts.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
		|
		|UNION ALL
		|
		|SELECT
		|	CounterpartyContracts.Counterparty,
		|	CounterpartyContracts.AccountOfCounterparty,
		|	CounterpartyContracts.Contract,
		|	CounterpartyContracts.CashFlowItem,
		|	CounterpartyContracts.ContractWithSelfEmployedPerson,
		|	CounterpartyContracts.ARAPObject,
		|	CounterpartyContracts.PaymentType_,
		|	CASE
		|		WHEN CounterpartyContracts.Status = VALUE(Enum.CounterpartyContractStatuses.Valid)
		|			THEN 3
		|		ELSE 4
		|	END
		|FROM
		|	Contracts_WithCounterparties AS CounterpartyContracts
		|WHERE
		|	CounterpartyContracts.CounterpartyBankAccount <> CounterpartyContracts.AccountOfCounterparty
		|	AND CounterpartyContracts.CounterpartyBankAccount <> VALUE(Catalog.CounterpartyBankAccounts.EmptyRef)
		|	AND CounterpartyContracts.BankAccount <> &BankAccount
		|	AND CounterpartyContracts.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
		|";
	
	Query.SetParameter("Table", SourceTable);
	Query.SetParameter("BankAccount", BankAccount);
	Query.SetParameter("Organization", Organization);
	
	Result = Query.Execute().Unload();
	
	If Result.Count() <> 0 Then
		
		Filter = ARAPObjectsServer.AdditionalSearchCriteria_1();
		Filter.Insert("ReturnFirstOne", True);
		
		ContractsAndSettlementObjects = ARAPObjectsServer.GetCalculationObjectsFromLinks(
			Result.UnloadColumn("Contract"),
			Organization, ,
			Filter);
		
		For Each ContractLine In Result Do
			ContractLine.ARAPObject = ContractsAndSettlementObjects[ContractLine.Contract];
		EndDo;
		
	EndIf;
	
	Return Result;

EndFunction

// Returns a table with Contracts for loans and deposits.
// 
// Parameters:
//  BankAccount - CatalogRef.CompaniesBankAccounts -  The company's bank account.
//  Company - Directory link.Companies - An Company.
//  SourceTable - ValueTable - a table containing a list of counterparties and their accounts:
//   *Counterparty - CatalogRef.Companies, CatalogRef.Counterparties, String, CatalogRef.Persons - 
//                the counterparty for which the Contract search is performed.
//   *AccountOfCounterparty - CatalogRef.CounterpartyBankAccounts, CatalogRef.CompaniesBankAccounts, String - 
//                     The bank account of the counterparty that is used to search for Contracts.
// 
// Returns:
//  ValueTable -  List of AR/AP objects for the Contracts found:
//   *Counterparty - CatalogRef.Companies, CatalogRef.Counterparties, String, CatalogRef.Persons - 
//                the counterparty for which the Contract search was performed.
//   *AccountOfCounterparty - CatalogRef.CounterpartyBankAccounts, CatalogRef.CompaniesBankAccounts, String - 
//                     The bank account of the counterparty that was used to search for Contracts.
//   *Ref - CatalogRef.LoanAndDepositContracts - found loan and deposit Contract.
//   *ContractKind - EnumRef.ContractKindsOfFinancialInstruments - nature of the agreement.
//   *CashFlowItemOfReceiptIssuie - CatalogRef.CashFlowReportItems - cash flow item 
//                                 of receipt (issuance) under the Contract.
//   *CashFlowItemOfPrincipalDebt - CatalogRef.ARAPObjects - Cash flow item of the principal debt under 
//                              the Contract.
//
Function ListOfContractsLoansDeposits(BankAccount, SourceTable)

	SourceTable.Indexes.Add("Counterparty, AccountOfCounterparty");
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	Table.Counterparty AS Counterparty,
		|	Table.AccountOfCounterparty AS AccountOfCounterparty
		|INTO CounterpartiesAndAccounts
		|FROM
		|	&Table AS Table
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CounterpartiesAndAccounts.Counterparty AS Counterparty,
		|	CounterpartiesAndAccounts.AccountOfCounterparty AS AccountOfCounterparty,
		|	LoanAndDepositContracts.Ref AS Ref,
		|	LoanAndDepositContracts.ContractKind AS ContractKind,
		|	LoanAndDepositContracts.CashFlowItemOfReceiptIssuie AS CashFlowItemOfReceiptIssuie,
		|	LoanAndDepositContracts.CashFlowItemOfPrincipalDebt AS CFItem,
		|	VALUE(Enum.LoanAndDepositScheduleAmountTypes.PrincipalDebt) AS LoanAndDepositAmountType,
		|	LoanAndDepositContracts.ARAPCurrency AS ARAPCurrency
		|FROM
		|	Catalog.LoanAndDepositContracts AS LoanAndDepositContracts
		|		INNER JOIN CounterpartiesAndAccounts AS CounterpartiesAndAccounts
		|		ON LoanAndDepositContracts.Counterparty = CounterpartiesAndAccounts.Counterparty
		|			AND LoanAndDepositContracts.CounterpartyBankAccount = CounterpartiesAndAccounts.AccountOfCounterparty
		|			AND (LoanAndDepositContracts.BankAccount = &BankAccount)
		|			AND (LoanAndDepositContracts.Status = VALUE(Enum.CounterpartyContractStatuses.Valid))
		|
		|UNION ALL
		|
		|SELECT
		|	CounterpartiesAndAccounts.Counterparty,
		|	CounterpartiesAndAccounts.AccountOfCounterparty,
		|	LoanAndDepositContracts.Ref,
		|	LoanAndDepositContracts.ContractKind,
		|	UNDEFINED,
		|	LoanAndDepositContracts.CashFlowItemOfInterestPayment,
		|	VALUE(Enum.LoanAndDepositScheduleAmountTypes.Interests),
		|	LoanAndDepositContracts.ARAPCurrency
		|FROM
		|	Catalog.LoanAndDepositContracts AS LoanAndDepositContracts
		|		INNER JOIN CounterpartiesAndAccounts AS CounterpartiesAndAccounts
		|		ON LoanAndDepositContracts.Counterparty = CounterpartiesAndAccounts.Counterparty
		|			AND LoanAndDepositContracts.InterestBankAccount = CounterpartiesAndAccounts.AccountOfCounterparty
		|			AND (LoanAndDepositContracts.BankAccount = &BankAccount)
		|			AND (LoanAndDepositContracts.Status = VALUE(Enum.CounterpartyContractStatuses.Valid))
		|
		|UNION ALL
		|
		|SELECT
		|	CounterpartiesAndAccounts.Counterparty,
		|	CounterpartiesAndAccounts.AccountOfCounterparty,
		|	LoanAndDepositContracts.Ref,
		|	LoanAndDepositContracts.ContractKind,
		|	UNDEFINED,
		|	LoanAndDepositContracts.CashFlowItemOfFeePayment,
		|	VALUE(Enum.LoanAndDepositScheduleAmountTypes.Fee),
		|	LoanAndDepositContracts.ARAPCurrency
		|FROM
		|	Catalog.LoanAndDepositContracts AS LoanAndDepositContracts
		|		INNER JOIN CounterpartiesAndAccounts AS CounterpartiesAndAccounts
		|		ON LoanAndDepositContracts.Counterparty = CounterpartiesAndAccounts.Counterparty
		|			AND LoanAndDepositContracts.BankAccountOfFee = CounterpartiesAndAccounts.AccountOfCounterparty
		|			AND (LoanAndDepositContracts.BankAccount = &BankAccount)
		|			AND (LoanAndDepositContracts.Status = VALUE(Enum.CounterpartyContractStatuses.Valid))";
	
	Query.SetParameter("Table", SourceTable);
	Query.SetParameter("BankAccount", BankAccount);
	
	Return Query.Execute().Unload();

EndFunction

Procedure FillInIndirectData(LinesToLoad, BankAccount)
	
	If LinesToLoad.Count() = 0 Then
		Return;
	EndIf;
	
	Organization = Common.ObjectAttributeValue(BankAccount, "Owner");
	ArrayOfInterconnectedOrganizations = Catalogs.Companies.ArrayOfInterconnectedOrganizations(Organization);
	
	TableRow = LinesToLoad.Get(0);
	TableIsReadyToLoad = TableRow.Owner();
	CounterpartiesAndAccounts = TableIsReadyToLoad.Copy(LinesToLoad, "Counterparty, AccountOfCounterparty");
	CounterpartiesAndAccounts.GroupBy("Counterparty, AccountOfCounterparty");
	
	ObjectsOfSettlementsUnderContracts = ListOfSettlementObjectsUnderContracts(BankAccount, Organization, CounterpartiesAndAccounts);
	ObjectsOfSettlementsUnderContracts.Indexes.Add("Counterparty, AccountOfCounterparty");
	
	LoanDepositAgreements_ = ListOfContractsLoansDeposits(BankAccount, CounterpartiesAndAccounts);
	LoanDepositAgreements_.Indexes.Add("Counterparty, AccountOfCounterparty");
	
	Payment_Parameters = SelectionOfAttributesForBusinessOfOperation();
	
	For Each DocumentLine In LinesToLoad Do
		
		If Not ValueIsFilled(DocumentLine.OperationKind) And TypeOf(DocumentLine.Counterparty) = Type("CatalogRef.Companies") Then // Own organization
			
			If ArrayOfInterconnectedOrganizations.Find(DocumentLine.Counterparty) <> Undefined Then
				DocumentLine.OperationKind = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices;
			Else
				
				If DocumentLine.Outgoing Then
					DocumentLine.OperationKind = Enums.BusinessTransactions.CashPaymentToAnotherCompany;
				Else
					DocumentLine.OperationKind = Enums.BusinessTransactions.CashReceiptFromOtherCompany;
				EndIf;
				
			EndIf;
			
			Continue;
		EndIf;
		
		ArrayOfAllProps = New Array;
		ArrayOfOperationDetails = New Array;
		
		If ValueIsFilled(DocumentLine.OperationKind) Then
			
			Payment_Parameters.BusinessOperation = DocumentLine.OperationKind;
			Payment_Parameters.Counterparty = DocumentLine.Counterparty;
			
			If DocumentLine.Outgoing Then
				Documents.BankAccountIssue.FillInNamesOfBusinessTransactionDetails(
					Payment_Parameters, ArrayOfAllProps, ArrayOfOperationDetails);
			Else
				Documents.BankAccountReceiptNote.FillInNamesOfBusinessTransactionDetails(
					Payment_Parameters, ArrayOfAllProps, ArrayOfOperationDetails);
			EndIf;
			
		EndIf;
		
		SelectContractOfOperation = (ArrayOfOperationDetails.Count() > 0 
			And ArrayOfOperationDetails.Find("ARAPDetails.LoanDepositContract") <> Undefined)
			Or ArrayOfOperationDetails.Count() = 0;
		
		FilterParameters = New Structure ("Counterparty, AccountOfCounterparty");
		FillPropertyValues(FilterParameters, DocumentLine);
		
		// Loan/Deposit Agreement
		ContractsOfLoansAndDepositsFound = LoanDepositAgreements_.FindRows(FilterParameters);
		
		If ContractsOfLoansAndDepositsFound.Count() = 1
			And SelectContractOfOperation Then
			
			Selection = ContractsOfLoansAndDepositsFound.Get(0);
			DocumentLine.LoanDepositContract = Selection.Ref;
			DocumentLine.OperationKind = Catalogs.LoanAndDepositContracts.OperationByNatureOfContract(
				Selection.ContractKind,
				Not DocumentLine.Outgoing);
			DocumentLine.ARAPCurrency = Selection.ARAPCurrency;
			If Selection.ContractKind = Enums.ContractKindsOfFinancialInstruments.LoanOrBorrowing Then
				
				If DocumentLine.Outgoing Then
					DocumentLine.CashFlowItem = Selection.CFItem;
					DocumentLine.LoanAndDepositAmountType = Selection.LoanAndDepositAmountType;
				Else
					DocumentLine.CashFlowItem = Selection.CashFlowItemOfReceiptIssuie;
				EndIf;
				
			Else
				
				If DocumentLine.Outgoing Then
					DocumentLine.CashFlowItem = Selection.CashFlowItemOfReceiptIssuie;
				Else
					DocumentLine.CashFlowItem = Selection.CFItem;
					DocumentLine.LoanAndDepositAmountType = Selection.LoanAndDepositAmountType;
				EndIf;
				
			EndIf;
			
			Continue;
			
		EndIf;
		
		// Contract with the counterparty
		SelectContractOfOperation = (ArrayOfOperationDetails.Count() > 0 
			And ArrayOfOperationDetails.Find("Contract") <> Undefined)
			Or ArrayOfOperationDetails.Count() = 0;
			
		If Not ValueIsFilled(DocumentLine.ARAPObject)
			And ObjectsOfSettlementsUnderContracts.Count() > 0
			And SelectContractOfOperation Then
			
			AddContractSelectionParameters(FilterParameters);
			
			If DocumentLine.Outgoing Then
				FilterParameters.PaymentType_ = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
			EndIf;
				
			FillInARAPObjectOfPaymentUnderContract(DocumentLine, ObjectsOfSettlementsUnderContracts, FilterParameters);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure FillInCashDocument(DocumentsToImport, DocumentsTable, BankAccount, Outbox)
	
	If Not DocumentsTable.Count() Then
		Return;
	EndIf;
	
	Query = New Query;
	TempTablesManager = New TempTablesManager;
	Query.TempTablesManager = TempTablesManager;
	
	Query.Text = "
	|SELECT
	|	DocumentsTable.LineNumber,
	|	DocumentsTable.ProcessingDate,
	|	DocumentsTable.DocumentAmount
	|
	|INTO DocumentsTable
	|
	|FROM
	|	&DocumentsTable AS DocumentsTable
	|";
	
	Query.SetParameter("DocumentsTable", DocumentsTable);
	Query.Execute();
	
	If Outbox Then
	
		QueryText = "
		|SELECT
		|	DocumentsTable.LineNumber AS LineNumber,
		|	DocumentData.Ref AS Ref
		|FROM
		|	DocumentsTable
		|	
		|	LEFT JOIN
		|		Document.CashAccountReceiptNote AS DocumentData
		|	ON
		|		DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromBank)
		|		AND DocumentData.BankAccount = &BankAccount
		|		AND BEGINOFPERIOD(DocumentData.Date, DAY) = DocumentsTable.ProcessingDate
		|		AND DocumentData.DocumentAmount = DocumentsTable.DocumentAmount
		|		AND DocumentData.Posted
		|WHERE
		|	NOT DocumentData.Ref IS NULL
		|";
		
	Else
		
		QueryText = "
		|SELECT
		|	DocumentsTable.LineNumber AS LineNumber,
		|	DocumentData.Ref AS Ref
		|FROM
		|	DocumentsTable
		|	
		|	LEFT JOIN
		|		Document.CashVoucher AS DocumentData
		|	ON
		|		DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CashDepositToBankAccount)
		|		AND DocumentData.BankAccount = &BankAccount
		|		AND BEGINOFPERIOD(DocumentData.Date, DAY) = DocumentsTable.ProcessingDate
		|		AND DocumentData.DocumentAmount = DocumentsTable.DocumentAmount
		|		AND DocumentData.Posted
		|WHERE
		|	NOT DocumentData.Ref IS NULL
		|";
		
	EndIf;
	
	Query.Text = QueryText;
	
	Query.SetParameter("BankAccount", BankAccount);
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		DocumentLine = DocumentsToImport.Find(Selection.LineNumber, "LineNumber");
		If DocumentLine <> Undefined Then
			DocumentLine.CashAccountDocument = Selection.Ref;
			DocumentLine.ToImport = False;
		EndIf;
	EndDo;
	
EndProcedure

Function OwnAccounts(BankAccount)
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	BankAccounts.Ref AS Ref,
	|	BankAccounts.AccountNumber AS AccountNumber,
	|	BankAccounts.CashCurrency AS Currency,
	|	CASE
	|		WHEN BankAccounts.ManualBankDetailsChange THEN
	|			BankAccounts.BankBIC
	|		ELSE
	|			BankAccounts.Bank.Code
	|	END AS BIC,
	|	CASE
	|		WHEN BankAccounts.ManualBankDetailsChange THEN
	|			BankAccounts.BankSWIFTCode
	|		ELSE
	|			BankAccounts.Bank.SWIFTBIC
	|	END AS SWIFT
	|FROM
	|	Catalog.CompaniesBankAccounts AS BankAccounts
	|	
	|	INNER JOIN
	|		Catalog.CompaniesBankAccounts AS CompaniesBankAccounts
	|	ON
	|		CompaniesBankAccounts.Owner = BankAccounts.Owner
	|		AND CompaniesBankAccounts.Ref = &BankAccount
	|	
	|WHERE
	|	BankAccounts.Ref <> &BankAccount
	|	AND NOT BankAccounts.DeletionMark
	|";
	
	Query.SetParameter("BankAccount", BankAccount);
	
	Return Query.Execute().Unload();
	
EndFunction

Procedure AddRemark(Buffer, NewRow, Separator = "")
	
	If IsBlankString(Buffer) Then
		Buffer = NewRow;
	Else
		Template = NStr("vi = '%1%2%3';
						|ru = '%1%2%3';
						|en = '%1%2%3'; fa = '%1%2%3';
						|it = '%1%2%3';
						|pl = '%1%2%3';
						|tr = '%1%2%3'");
		Buffer = StringFunctionsClientServer.SubstituteParametersToString(
			Template,
			Buffer,
			?(IsBlankString(Separator), Chars.LF, Separator),
			NewRow);
	EndIf;
	
EndProcedure

Procedure FillInCounterpartySAddress(Date, Counterparty, CounterpartyKind, Address)

	If IsBlankString(Address) Then
		Return;
	EndIf;
	
	If CounterpartyKind = Enums.LegalEntityIndividual.Entity
		Or CounterpartyKind = Enums.LegalEntityIndividual.LegalEntityNonResident Then
		ContactsManager.AddContactInformation(
			Counterparty,
			Address,
			Catalogs.ContactInformationKinds.LegalAddressOfCounterparty,
			Date,
			False);
	Else
		ContactsManager.AddContactInformation(
			Counterparty,
			Address,
			Catalogs.ContactInformationKinds.ActualDataCounterpartyAddress,
			Date,
			False);
	EndIf;

EndProcedure

Function GenerateDescriptionOfDocumentRecordingError(ErrorDescription)

	Cause = ?(
		ErrorDescription.Cause <> Undefined, GenerateDescriptionOfDocumentRecordingError(ErrorDescription.Cause), "");
	
	If ErrorDescription.ModuleName <> "" Then
		LongDesc = StrTemplate(NStr("vi = '%1
						|{%2(%3)}:%4';
						|ru = '%1
						|{%2(%3)}:%4';
						|en = '%1
						|{%2(%3)}:%4'; fa = '%1
						|{%2(%3)}:%4';
						|it = '%1
						|{%2(%3)}:%4';
						|pl = '%1
						|{%2(%3)}:%4';
						|tr = '%1
						|{%2(%3)}:%4'"),
				ErrorDescription.Description,
				ErrorDescription.ModuleName,
				ErrorDescription.LineNumber,
				ErrorDescription.SourceLine);
	Else
		LongDesc = StrTemplate("%1", ErrorDescription.Description);
	EndIf;
	
	Return ?(Cause <> "", Cause + Chars.LF, Cause) + LongDesc;

EndFunction

Procedure FillInVATRateUnderContract(Object, DecryptionString)

	If Not ValueIsFilled(DecryptionString.ARAPObject) Then
		
		If ValueIsFilled(Object.Contract)
			And Not ValueIsFilled(Object.VATTaxation) Then
				
			TaxationUnderContract = Common.ObjectAttributeValue(Object.Contract, "VATTaxation");
			SetProperty(Object, "VATTaxation", TaxationUnderContract);
			
		EndIf;
		
		VATAccountingERP.FillInVATRateForPayments_(
			DecryptionString.VATRate,
			Object.VATTaxation,
			Object.Organization,
			Object.Date);
		
	EndIf;

EndProcedure

Procedure AddContractSelectionParameters(FilterParameters)

	FilterParameters.Insert("Priority", 1);
	FilterParameters.Insert("PaymentType_", Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting);

EndProcedure

Procedure FillInARAPObjectOfPaymentUnderContract(PaymentLine_1, ObjectsOfSettlementsUnderContracts, Filter)

	If Filter.Priority > 4 Then
		Return;
	EndIf;
	
	APARObjectList = ObjectsOfSettlementsUnderContracts.FindRows(Filter);
	
	If APARObjectList.Count() = 1 Then
		
		PaymentLine_1.ARAPObject = APARObjectList[0].ARAPObject;
		PaymentLine_1.ContractWithSelfEmployedPerson = APARObjectList[0].ContractWithSelfEmployedPerson;
		PaymentLine_1.Contract = APARObjectList[0].Contract;

		If ValueIsFilled(APARObjectList[0].CashFlowItem) Then
			PaymentLine_1.CashFlowItem = APARObjectList[0].CashFlowItem;
		EndIf;
		
	ElsIf APARObjectList.Count() = 0 Then
		
		Filter.Insert("Priority", Filter.Priority + 1);
		FillInARAPObjectOfPaymentUnderContract(PaymentLine_1, ObjectsOfSettlementsUnderContracts, Filter);
		
	EndIf;

EndProcedure

Procedure FillInOtherReceiptExpense(LinesToLoad)

	For Each PaymentLine_1 In LinesToLoad Do
		PaymentLine_1.OperationKind = ?(PaymentLine_1.Outgoing,
						Enums.BusinessTransactions.OtherCashIssue,
						Enums.BusinessTransactions.OtherCashReceipt);
	EndDo;

EndProcedure

Procedure FillInPaymentsToBeUploadedUsingUIP(Outgoing, BankAccount, DocumentsToImport, ListOfUIPS)

	ThisIsAccountOfGOZ = EDIWithBanksLocalization.ThisIsAccountOfGOZ(BankAccount);
	
	If ThisIsAccountOfGOZ Then
		
		EDIWithBanksLocalization.FillInPaymentsForUploadingStateBudgetForUIP(Outgoing, BankAccount, DocumentsToImport, ListOfUIPS);
		Return;
		
	EndIf;
	
	ChoiceData = New ValueList;
	
	FilterStructure1 = ARAPAccountingClientServer.SelectionDataSelectionStructure();
	FilterStructure1.Organization = Common.ObjectAttributeValue(BankAccount, "Owner");
	FilterStructure1.Text       = ListOfUIPS.UnloadColumn("Code");
	FilterStructure1.PaymentType_ = 
		?(Outgoing, Enums.PartnersARAPAccountingTypes.VendorARAPAccounting, Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting);
	FilterStructure1.RecordBranches = True;
	
	ARAPAccountingServer.FillInUIPSelectionData(
		ChoiceData,
		FilterStructure1,
		False);
	
	For Each DataElement In ChoiceData Do
		
		Selection = DataElement.Value.Value;
		
		Filter = New Structure("Code", Selection.PaymentID);
		TableRows = ListOfUIPS.FindRows(Filter);
		
		For Each TableRow In TableRows Do
			
			DocumentLine = DocumentsToImport.Find(TableRow["LineNumber"], "LineNumber");
			
			If DocumentLine <> Undefined Then
				
				DocumentLine.PaymentBasisIsFound = True;
				DocumentLine.CounterpartyIsFound = True;
				DocumentLine.CreateCounterparty = False;
				
				FillPropertyValues(DocumentLine, Selection, "Counterparty, Partner, PaymentPurpose");
				
				If ValueIsFilled(Selection.PaymentPurpose) And Not ValueIsFilled(Selection.ARAPObject) Then
					DocumentLine.ARAPObject = ARAPObjectsServer.ARAPObjectOnBasisOfPayment(
						Selection.PaymentPurpose)
				Else
					DocumentLine.ARAPObject = Selection.ARAPObject;
				EndIf;
				
				If Not ValueIsFilled(DocumentLine.OperationKind) Then
					
					If TypeOf(DocumentLine.Counterparty) = Type("CatalogRef.Counterparties")
						And Not Outgoing Then
						DocumentLine.OperationKind = Enums.BusinessTransactions.CashReceiptFromCustomer;
					ElsIf TypeOf(DocumentLine.Counterparty) = Type("CatalogRef.Companies")
						And Not Outgoing Then
						DocumentLine.OperationKind = Enums.BusinessTransactions.CashReceiptFromOtherCompany;
					ElsIf TypeOf(DocumentLine.Counterparty) = Type("CatalogRef.Counterparties")
						And Outgoing Then
						DocumentLine.OperationKind = Enums.BusinessTransactions.PaymentToVendor;
					ElsIf TypeOf(DocumentLine.Counterparty) = Type("CatalogRef.Companies")
						And Outgoing Then
						DocumentLine.OperationKind = Enums.BusinessTransactions.CashPaymentToAnotherCompany;
					EndIf;
					
				EndIf;
				
				If ValueIsFilled(DocumentLine.ARAPObject) Then
					DocumentLine.CashFlowItem =
						CashServer.ArticleOfCashFlowOfSettlementObject(DocumentLine.ARAPObject, DocumentLine.OperationKind);
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndDo;

EndProcedure

Procedure FillInDefaultOfOperationView(LinesToLoad)

	If LinesToLoad.Count() = 0 Then
		Return;
	EndIf;
	
	For Each TableRow In LinesToLoad Do
		
		If TableRow.Outgoing Then
			TableRow.OperationKind = Enums.BusinessTransactions.PaymentToVendor;
		Else
			TableRow.OperationKind = Enums.BusinessTransactions.CashReceiptFromCustomer;
		EndIf;
		
	EndDo;

EndProcedure

Procedure AddCashFlowArticlesToUploadSettings(LinesToLoad, ImportSettings)

	If LinesToLoad.Count() = 0 Then
		Return;
	EndIf;
	
	OperationKinds = New Array;
	
	For Each TableRow In LinesToLoad Do
		
		If OperationKinds.Find(TableRow.OperationKind) = Undefined Then
			OperationKinds.Add(TableRow.OperationKind);
		EndIf;
		
	EndDo;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	ARTICLES__.Ref AS CashFlowItem,
		|	OFOperationsOfArticles.BusinessOperation AS BusinessOperation
		|FROM
		|	Catalog.CashFlowReportItems AS ARTICLES__
		|		INNER JOIN Catalog.CashFlowReportItems.BusinessTransactions AS OFOperationsOfArticles
		|		ON ARTICLES__.Ref = OFOperationsOfArticles.Ref
		|			AND (NOT ARTICLES__.DeletionMark)
		|			AND OFOperationsOfArticles.BusinessOperation IN (&OperationKinds)";
	
	Query.SetParameter("OperationKinds", OperationKinds);
	Result = Query.Execute().Unload();
	ImportSettings.Insert("ArticlesOfCashFlowOfOperations", Result);

EndProcedure

Procedure FillInCashFlowItems(LinesToLoad, ArticlesOfCashFlowOfOperations)

	If LinesToLoad.Count() = 0 Then
		Return;
	EndIf;
	
	For Each TableRow In LinesToLoad Do
		
		FilterParameters = New Structure;
		FilterParameters.Insert("BusinessOperation", TableRow.OperationKind);
		
		If ValueIsFilled(TableRow.CashFlowItem) Then
			FilterParameters.Insert("CashFlowItem", TableRow.CashFlowItem);
		EndIf;
		
		CashFlowItem = ArticleOfBusinessTransaction(ArticlesOfCashFlowOfOperations, FilterParameters);
		
		// If the Cash Flow item selected earlier does not correspond to the business transaction of operation, then we are trying to fill
		// it in with the only article linked to the business of operation (if there is one).
		If ValueIsFilled(TableRow.CashFlowItem)
			And Not ValueIsFilled(CashFlowItem) Then
			
			FilterParameters.Delete("CashFlowItem");
			CashFlowItem = ArticleOfBusinessTransaction(ArticlesOfCashFlowOfOperations, FilterParameters);
			
		EndIf;
		
		TableRow.CashFlowItem = CashFlowItem;
		
	EndDo;
	
EndProcedure

Function BalancesOfPaymentRequestsOnInvoice(BankAccount, AccountAttributes)

	Query = New Query;
	Query.Text = 
		"SELECT DISTINCT
		|	Requests.Ref AS Ref,
		|	ISNULL(AccountDistributions.BankAccountCashAccount, UNDEFINED) AS BankAccount,
		|	Requests.OperationWithSelfEmployedPerson AS OperationWithSelfEmployedPerson,
		|	Requests.BusinessOperation AS BusinessOperation,
		|	Requests.PayrollTransaction AS PayrollTransaction,
		|	Requests.Counterparty AS Counterparty,
		|	Requests.AdvanceHolder AS AdvanceHolder,
		|	Requests.CompanyRecipient AS CompanyRecipient,
		|	Requests.PersonsList AS PersonsList,
		|	Requests.ListOfCounterparties_ AS ListOfCounterparties_,
		|	Requests.DocumentAmount AS DocumentAmount,
		|	Requests.FPSTransactionID AS FPSTransactionID,
		|	Requests.Date AS Date
		|INTO PaymentRequests
		|FROM
		|	Document.PaymentRequest AS Requests
		|		LEFT JOIN Document.PaymentRequest.AllocationByAccounts AS AccountDistributions
		|		ON Requests.Ref = AccountDistributions.Ref
		|WHERE
		|	Requests.Status = VALUE(Enum.StatusesOfPaymentRequests.AmountDue)
		|	AND Requests.PaymentMethodOfPaymentRequest IN (VALUE(Enum.PaymentForms.EmptyRef),
		|		VALUE(Enum.PaymentForms.BankAccountPayment),
		|		VALUE(Enum.PaymentForms.InstantPayments))
		|	AND (Requests.Currency = &Currency
		|			OR Requests.AmountPlanning = VALUE(Enum.MethodsOfPlanningRequestPayment.InARAPCurrency))
		|	AND Requests.Organization = &Organization
		|	AND (AccountDistributions.BankAccountCashAccount = &BankAccount
		|			OR AccountDistributions.BankAccountCashAccount IS NULL)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CashToBePaidBalance.PaymentRequest AS PaymentRequest,
		|	CashToBePaidBalance.BankAccountCashAccount AS BankAccountCashAccount,
		|	CashToBePaidBalance.SumBalance AS SumBalance
		|INTO BalancesOfApplications
		|FROM
		|	AccumulationRegister.CashToBePaid.Balance(
		|			,
		|			(PaymentRequest, BankAccountCashAccount) IN
		|				(SELECT
		|					PaymentRequests.Ref,
		|					PaymentRequests.BankAccount
		|				FROM
		|					PaymentRequests)) AS CashToBePaidBalance
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	PaymentRequests.Ref AS Ref,
		|	PaymentRequests.OperationWithSelfEmployedPerson AS OperationWithSelfEmployedPerson,
		|	PaymentRequests.BusinessOperation AS BusinessOperation,
		|	PaymentRequests.PayrollTransaction AS PayrollTransaction,
		|	PaymentRequests.Counterparty AS Counterparty,
		|	PaymentRequests.AdvanceHolder AS AdvanceHolder,
		|	PaymentRequests.CompanyRecipient AS CompanyRecipient,
		|	PaymentRequests.PersonsList AS PersonsList,
		|	PaymentRequests.ListOfCounterparties_ AS ListOfCounterparties_,
		|	PaymentRequests.DocumentAmount AS DocumentAmount,
		|	SUM(BalancesOfApplications.SumBalance) AS SumBalance,
		|	PaymentRequests.FPSTransactionID AS FPSTransactionID,
		|	PaymentRequests.Date AS Date
		|INTO RequestsForPayment
		|FROM
		|	PaymentRequests AS PaymentRequests
		|		INNER JOIN BalancesOfApplications AS BalancesOfApplications
		|		ON PaymentRequests.Ref = BalancesOfApplications.PaymentRequest
		|			AND PaymentRequests.BankAccount = BalancesOfApplications.BankAccountCashAccount
		|
		|GROUP BY
		|	PaymentRequests.Ref,
		|	PaymentRequests.OperationWithSelfEmployedPerson,
		|	PaymentRequests.BusinessOperation,
		|	PaymentRequests.PayrollTransaction,
		|	PaymentRequests.Counterparty,
		|	PaymentRequests.AdvanceHolder,
		|	PaymentRequests.CompanyRecipient,
		|	PaymentRequests.PersonsList,
		|	PaymentRequests.ListOfCounterparties_,
		|	PaymentRequests.DocumentAmount,
		|	PaymentRequests.FPSTransactionID,
		|	PaymentRequests.Date
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	PaymentDecryptionTables.PaymentRequest AS PaymentRequest,
		|	PaymentDecryptionTables.Counterparty AS Recipient,
		|	SUM(PaymentDecryptionTables.Sum) AS Sum
		|INTO WrittenOffByRequests
		|FROM
		|	Document.BankAccountIssue.ARAPDetails AS PaymentDecryptionTables
		|		INNER JOIN Document.BankAccountIssue AS WriteOffDocuments
		|		ON PaymentDecryptionTables.Ref = WriteOffDocuments.Ref
		|			AND (WriteOffDocuments.ListOfCounterparties_)
		|			AND (WriteOffDocuments.Posted)
		|		INNER JOIN RequestsForPayment AS RequestsForPayment
		|		ON PaymentDecryptionTables.PaymentRequest = RequestsForPayment.Ref
		|			AND (RequestsForPayment.ListOfCounterparties_)
		|
		|GROUP BY
		|	PaymentDecryptionTables.PaymentRequest,
		|	PaymentDecryptionTables.Counterparty
		|
		|UNION ALL
		|
		|SELECT
		|	PaymentDecryptionTables.PaymentRequest,
		|	WriteOffDocuments.Counterparty,
		|	SUM(PaymentDecryptionTables.Sum)
		|FROM
		|	Document.BankAccountIssue.ARAPDetails AS PaymentDecryptionTables
		|		INNER JOIN Document.BankAccountIssue AS WriteOffDocuments
		|		ON PaymentDecryptionTables.Ref = WriteOffDocuments.Ref
		|			AND (NOT WriteOffDocuments.ListOfCounterparties_)
		|			AND (WriteOffDocuments.Posted)
		|		INNER JOIN RequestsForPayment AS RequestsForPayment
		|		ON PaymentDecryptionTables.PaymentRequest = RequestsForPayment.Ref
		|			AND (RequestsForPayment.ListOfCounterparties_)
		|
		|GROUP BY
		|	PaymentDecryptionTables.PaymentRequest,
		|	WriteOffDocuments.Counterparty
		|
		|UNION ALL
		|
		|SELECT
		|	PaymentDecryptionTables.PaymentRequest,
		|	TablesPersonalAccountsOfEmployees.Individual,
		|	SUM(TablesPersonalAccountsOfEmployees.Sum)
		|FROM
		|	Document.BankAccountIssue.ARAPDetails AS PaymentDecryptionTables
		|		INNER JOIN Document.BankAccountIssue AS WriteOffDocuments
		|			INNER JOIN Document.BankAccountIssue.PersonalAccountsOfStaff AS TablesPersonalAccountsOfEmployees
		|			ON (TablesPersonalAccountsOfEmployees.Ref = WriteOffDocuments.Ref)
		|				AND (WriteOffDocuments.Posted)
		|		ON PaymentDecryptionTables.Ref = WriteOffDocuments.Ref
		|			AND (WriteOffDocuments.PersonsList)
		|		INNER JOIN RequestsForPayment AS RequestsForPayment
		|		ON PaymentDecryptionTables.PaymentRequest = RequestsForPayment.Ref
		|			AND (RequestsForPayment.PersonsList)
		|
		|GROUP BY
		|	PaymentDecryptionTables.PaymentRequest,
		|	TablesPersonalAccountsOfEmployees.Individual
		|
		|UNION ALL
		|
		|SELECT
		|	PaymentDecryptionTables.PaymentRequest,
		|	WriteOffDocuments.AdvanceHolder,
		|	SUM(PaymentDecryptionTables.Sum)
		|FROM
		|	Document.BankAccountIssue.ARAPDetails AS PaymentDecryptionTables
		|		INNER JOIN Document.BankAccountIssue AS WriteOffDocuments
		|		ON PaymentDecryptionTables.Ref = WriteOffDocuments.Ref
		|			AND (NOT WriteOffDocuments.PersonsList)
		|			AND (WriteOffDocuments.Posted)
		|		INNER JOIN RequestsForPayment AS RequestsForPayment
		|		ON PaymentDecryptionTables.PaymentRequest = RequestsForPayment.Ref
		|			AND (RequestsForPayment.PersonsList)
		|
		|GROUP BY
		|	PaymentDecryptionTables.PaymentRequest,
		|	WriteOffDocuments.AdvanceHolder
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	RequestsForPayment.Ref AS Ref,
		|	RequestsForPayment.OperationWithSelfEmployedPerson AS OperationWithSelfEmployedPerson,
		|	RequestsForPayment.BusinessOperation AS BusinessOperation,
		|	RequestsForPayment.PayrollTransaction AS PayrollTransaction,
		|	RequestsForPayment.Counterparty AS Recipient,
		|	RequestsForPayment.SumBalance AS SumBalance,
		|	RequestsForPayment.DocumentAmount AS AmountOnRequest,
		|	RequestsForPayment.PersonsList AS PersonsList,
		|	RequestsForPayment.ListOfCounterparties_ AS ListOfCounterparties_,
		|	RequestsForPayment.FPSTransactionID AS FPSTransactionID,
		|	RequestsForPayment.Date AS Date
		|INTO DetailsByRecipients
		|FROM
		|	RequestsForPayment AS RequestsForPayment
		|WHERE
		|	NOT RequestsForPayment.ListOfCounterparties_
		|	AND NOT RequestsForPayment.PersonsList
		|	AND NOT RequestsForPayment.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder),
		|		VALUE(Enum.BusinessTransactions.CashIssueAsLoanToEmployee),
		|		VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany),
		|		VALUE(Enum.BusinessTransactions.RefundToAnotherCompany),
		|		VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices))
		|
		|UNION ALL
		|
		|SELECT
		|	RequestsForPayment.Ref,
		|	RequestsForPayment.OperationWithSelfEmployedPerson,
		|	RequestsForPayment.BusinessOperation,
		|	RequestsForPayment.PayrollTransaction,
		|	ARAPDetails.Counterparty,
		|	RequestsForPayment.SumBalance,
		|	ARAPDetails.Sum,
		|	RequestsForPayment.PersonsList,
		|	RequestsForPayment.ListOfCounterparties_,
		|	RequestsForPayment.FPSTransactionID,
		|	RequestsForPayment.Date
		|FROM
		|	RequestsForPayment AS RequestsForPayment
		|		INNER JOIN Document.PaymentRequest.ARAPDetails AS ARAPDetails
		|		ON RequestsForPayment.Ref = ARAPDetails.Ref
		|			AND (RequestsForPayment.ListOfCounterparties_)
		|			AND (NOT RequestsForPayment.PersonsList)
		|			AND (NOT RequestsForPayment.BusinessOperation IN (
		|				VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder),
		|				VALUE(Enum.BusinessTransactions.CashIssueAsLoanToEmployee),
		|				VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany),
		|				VALUE(Enum.BusinessTransactions.RefundToAnotherCompany),
		|				VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices)))
		|
		|UNION ALL
		|
		|SELECT
		|	RequestsForPayment.Ref,
		|	RequestsForPayment.OperationWithSelfEmployedPerson,
		|	RequestsForPayment.BusinessOperation,
		|	RequestsForPayment.PayrollTransaction,
		|	RequestsForPayment.AdvanceHolder,
		|	RequestsForPayment.SumBalance,
		|	RequestsForPayment.DocumentAmount,
		|	RequestsForPayment.PersonsList,
		|	RequestsForPayment.ListOfCounterparties_,
		|	RequestsForPayment.FPSTransactionID,
		|	RequestsForPayment.Date
		|FROM
		|	RequestsForPayment AS RequestsForPayment
		|WHERE
		|	NOT RequestsForPayment.PersonsList
		|	AND RequestsForPayment.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder),
		|		VALUE(Enum.BusinessTransactions.CashIssueAsLoanToEmployee))
		|
		|UNION ALL
		|
		|SELECT
		|	RequestsForPayment.Ref,
		|	RequestsForPayment.OperationWithSelfEmployedPerson,
		|	RequestsForPayment.BusinessOperation,
		|	RequestsForPayment.PayrollTransaction,
		|	PersonalAccountsOfStaff.Individual,
		|	RequestsForPayment.SumBalance,
		|	PersonalAccountsOfStaff.Sum,
		|	RequestsForPayment.PersonsList,
		|	RequestsForPayment.ListOfCounterparties_,
		|	RequestsForPayment.FPSTransactionID,
		|	RequestsForPayment.Date
		|FROM
		|	RequestsForPayment AS RequestsForPayment
		|		INNER JOIN Document.PaymentRequest.PersonalAccountsOfStaff AS PersonalAccountsOfStaff
		|		ON RequestsForPayment.Ref = PersonalAccountsOfStaff.Ref
		|			AND (RequestsForPayment.PersonsList)
		|WHERE
		|	NOT RequestsForPayment.PersonsList
		|	AND RequestsForPayment.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder),
		|		VALUE(Enum.BusinessTransactions.CashIssueAsLoanToEmployee))
		|
		|UNION ALL
		|
		|SELECT
		|	RequestsForPayment.Ref,
		|	RequestsForPayment.OperationWithSelfEmployedPerson,
		|	RequestsForPayment.BusinessOperation,
		|	RequestsForPayment.PayrollTransaction,
		|	RequestsForPayment.CompanyRecipient,
		|	RequestsForPayment.SumBalance,
		|	RequestsForPayment.DocumentAmount,
		|	RequestsForPayment.PersonsList,
		|	RequestsForPayment.ListOfCounterparties_,
		|	RequestsForPayment.FPSTransactionID,
		|	RequestsForPayment.Date
		|FROM
		|	RequestsForPayment AS RequestsForPayment
		|WHERE
		|	RequestsForPayment.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany),
		|		VALUE(Enum.BusinessTransactions.RefundToAnotherCompany),
		|		VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices))
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DetailsByRecipients.Ref AS Ref,
		|	DetailsByRecipients.OperationWithSelfEmployedPerson AS OperationWithSelfEmployedPerson,
		|	DetailsByRecipients.BusinessOperation AS BusinessOperation,
		|	DetailsByRecipients.PayrollTransaction AS PayrollTransaction,
		|	DetailsByRecipients.Recipient AS Recipient,
		|	DetailsByRecipients.AmountOnRequest AS AmountOnRequest,
		|	WrittenOffByRequests.Sum AS AmountCredited,
		|	CASE
		|		WHEN DetailsByRecipients.PersonsList
		|			THEN DetailsByRecipients.AmountOnRequest - ISNULL(WrittenOffByRequests.Sum, 0)
		|		WHEN DetailsByRecipients.ListOfCounterparties_
		|			THEN DetailsByRecipients.AmountOnRequest - ISNULL(WrittenOffByRequests.Sum, 0)
		|		ELSE DetailsByRecipients.SumBalance
		|	END AS Balance,
		|	DetailsByRecipients.FPSTransactionID AS FPSTransactionID,
		|	DetailsByRecipients.Date AS Date
		|FROM
		|	DetailsByRecipients AS DetailsByRecipients
		|		LEFT JOIN WrittenOffByRequests AS WrittenOffByRequests
		|		ON DetailsByRecipients.Ref = WrittenOffByRequests.PaymentRequest
		|			AND DetailsByRecipients.Recipient = WrittenOffByRequests.Recipient
		|WHERE
		|	CASE
		|			WHEN DetailsByRecipients.PersonsList
		|				THEN DetailsByRecipients.AmountOnRequest - ISNULL(WrittenOffByRequests.Sum, 0)
		|			WHEN DetailsByRecipients.ListOfCounterparties_
		|				THEN DetailsByRecipients.AmountOnRequest - ISNULL(WrittenOffByRequests.Sum, 0)
		|			ELSE DetailsByRecipients.SumBalance
		|		END > 0
		|
		|ORDER BY
		|	Date
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP PaymentRequests
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP BalancesOfApplications
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP RequestsForPayment
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP WrittenOffByRequests
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP DetailsByRecipients";
	
	Query.SetParameter("BankAccount", BankAccount);
	Query.SetParameter("Currency", AccountAttributes.Currency);
	Query.SetParameter("Organization", AccountAttributes.Organization);
	
	Return Query.Execute().Unload();

EndFunction

Procedure PickUpPaymentRequests(BalancesOfApplications, Payment_, DocumentObject)

	If BalancesOfApplications = Undefined Then
		Return;
	EndIf;
	
	If Not Payment_.CounterpartyIsFound Then
		Return;
	EndIf;
	
	FilterParameters = New Structure;
	FilterParameters.Insert("OperationWithSelfEmployedPerson", DocumentObject.OperationWithSelfEmployedPerson);
	
	If ValueIsFilled(DocumentObject.Counterparty) Then
		FilterParameters.Insert("Recipient", DocumentObject.Counterparty);
	ElsIf ValueIsFilled(DocumentObject.AdvanceHolder) Then
		FilterParameters.Insert("Recipient", DocumentObject.AdvanceHolder);
	Else
		
		CompanyRecipient = Common.ObjectAttributeValue(DocumentObject.BankAccountBeneficiary, "Owner");
		FilterParameters.Insert("Recipient", CompanyRecipient);
		
	EndIf;
	
	FilterParameters.Insert("FPSTransactionID", Payment_.FPSTransactionID);
	
	Selected_1Balance = BalancesOfApplications.FindRows(FilterParameters);
	
	If Selected_1Balance.Count() = 0
		And Not IsBlankString(Payment_.FPSTransactionID) Then
		
		FilterParameters.Insert("FPSTransactionID", "");
		Selected_1Balance = BalancesOfApplications.FindRows(FilterParameters);
		
		If Selected_1Balance.Count() = 0 Then
			Return;
		EndIf;
		
	ElsIf Selected_1Balance.Count() = 0 Then
		Return;
	EndIf;
	
	NewTable = DocumentObject.ARAPDetails.UnloadColumns();
	
	For Each LineOfATabularSection In DocumentObject.ARAPDetails Do
		
		DistributionAmount_ = LineOfATabularSection.Sum;
		
		For Each Current_Balance In Selected_1Balance Do
			
			OperationMatches = 
				(Current_Balance.BusinessOperation = DocumentObject.BusinessOperation
					And Current_Balance.PayrollTransaction <> DocumentObject.BusinessOperation)
				Or (Current_Balance.BusinessOperation <> DocumentObject.BusinessOperation
					And Current_Balance.PayrollTransaction = DocumentObject.BusinessOperation);
			
			If OperationMatches
				And Current_Balance.Date <= DocumentObject.Date Then
				
				NewRow = NewTable.Add();
				FillPropertyValues(NewRow, LineOfATabularSection);
				NewRow.Sum = Min(Current_Balance.Balance, DistributionAmount_);
				DistributionAmount_ = DistributionAmount_ - NewRow.Sum;
				Current_Balance.Balance = Current_Balance.Balance - NewRow.Sum;
				NewRow.PaymentRequest = Current_Balance.Ref;
				
				If DistributionAmount_ <= 0 Then
					Break;
				EndIf;
				
			EndIf;
			
		EndDo;
		
		If DistributionAmount_ > 0 Then
			NewRow = NewTable.Add();
			FillPropertyValues(NewRow, LineOfATabularSection);
			NewRow.Sum = DistributionAmount_;
		EndIf;
		
	EndDo;
	
	DocumentObject.ARAPDetails.Load(NewTable);

EndProcedure

Procedure FillInAccordingToActivationContract(PaymentLine_1, DocumentObject, AvailableCashFlowArticles)

	If Not ValueIsFilled(PaymentLine_1.AcquiringContract) Then
		Return;
	EndIf;
	
	SetProperty(DocumentObject, "AcquiringContract", PaymentLine_1.AcquiringContract);
	ContractDetails_ = Catalogs.AcquiringContracts.ContractDetails_(DocumentObject.AcquiringContract);
	
	RecordCommission = ContractDetails_.CommissionPostingMethod = Enums.MethodsOfAcquiringCommissionRecording.OnCashReceiving;
	SetProperty(DocumentObject, "RecordCommission", RecordCommission);
	
	If AvailableCashFlowArticles.Find(ContractDetails_.CashFlowItemCashReceipt) <> Undefined Then
		SetProperty(DocumentObject, "CashFlowItem", ContractDetails_.CashFlowItemCashReceipt);
	Else
		SetProperty(DocumentObject, "CashFlowItem", PaymentLine_1.CashFlowItem);
	EndIf;
	
	If DocumentObject.RecordCommission Then
		
		SetProperty(DocumentObject, "KeepRecordsOfCommissionInARAPAccounting", ContractDetails_.KeepRecordsOfCommissionInARAPAccounting);
	
		If ContractDetails_.KeepRecordsOfCommissionInARAPAccounting Then
			SetProperty(DocumentObject, "CommissionARAPObject", ContractDetails_.CommissionARAPObject);
		Else
			SetProperty(DocumentObject, "Department", ContractDetails_.ExpensesBusinessUnit);
			SetProperty(DocumentObject, "ExpenseItem", ContractDetails_.ExpenseItem);
			SetProperty(DocumentObject, "DimensionOfExpenses", ContractDetails_.DimensionOfExpenses);
		EndIf;
		
		EDIWithBanksLocalization.FillInCommissionAmount(PaymentLine_1, DocumentObject, ContractDetails_);
		
	EndIf;

EndProcedure

Function ArticleOfBusinessTransaction(ArticlesOfCashFlowOfOperations, FilterParameters)

	FoundRows = ArticlesOfCashFlowOfOperations.FindRows(FilterParameters);
	
	Return OnlyCashFlowItemFromList(FoundRows);

EndFunction

Function OnlyCashFlowItemFromList(ListOfArticles)

	If ListOfArticles.Count() = 1 Then
		
		If TypeOf(ListOfArticles[0]) = Type("ValueTableRow") Then
			CashFlowItem = ListOfArticles[0].CashFlowItem
		Else
			CashFlowItem = ListOfArticles[0];
		EndIf;
		
	Else
		CashFlowItem = Catalogs.CashFlowReportItems.EmptyRef();
	EndIf;
	
	Return CashFlowItem;

EndFunction

Function SelectionOfAttributesForBusinessOfOperation()

	Filter = New Structure;
	Filter.Insert("BusinessOperation", Enums.BusinessTransactions.EmptyRef());
	Filter.Insert("Counterparty", Undefined);
	Filter.Insert("PersonsList", False);
	
	Return Filter;

EndFunction

#EndRegion
