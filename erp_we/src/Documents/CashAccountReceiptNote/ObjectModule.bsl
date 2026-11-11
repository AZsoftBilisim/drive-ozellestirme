#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	Author = Users.CurrentUser();
	
	DocBasis = Undefined;
	AmountToPay = 0;
	
	If Documents.AllRefsType().ContainsType(TypeOf(FillingData))
		Or Catalogs.AllRefsType().ContainsType(TypeOf(FillingData)) Then
		
		DocBasis = FillingData;
		FillingData = New Structure;
	EndIf;
	
	If TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("DocumentBasis") Then
			
		If TypeOf(FillingData.DocumentBasis) = Type("Array")
			And FillingData.DocumentBasis.Count() > 0
			And TypeOf(FillingData.DocumentBasis[0]) = Type("DocumentRef.CashTransferReferenceOrder") Then
			
			DocBasis = FillingData.DocumentBasis[0];
			
		ElsIf Documents.AllRefsType().ContainsType(TypeOf(FillingData.DocumentBasis))
			Or Catalogs.AllRefsType().ContainsType(TypeOf(FillingData.DocumentBasis)) Then
				
			DocBasis = FillingData.DocumentBasis;
			
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(DocBasis) Then
		
		BasisType = TypeOf(DocBasis);
		
		If BasisType = Type("DocumentRef.CashVoucher") Then
			FillInUsingExpenseCashOrder(DocBasis, FillingData);
			
		ElsIf BasisType = Type("DocumentRef.SalesOrder") Then
			FillInOnTheCustomerSOrder(DocBasis, FillingData, AmountToPay);
			
		ElsIf BasisType = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
			FillInRequestForReturnOfGoods(DocBasis, FillingData, AmountToPay);
			
		ElsIf BasisType = Type("DocumentRef.CustomerCommercialInvoice") Then
			FillInInvoiceForPaymentToClient(DocBasis, FillingData);
			
		ElsIf BasisType = Type("DocumentRef.ExpenseReport") Then
			FillInAdvanceReport(DocBasis, FillingData);
			
		ElsIf BasisType = Type("DocumentRef.CustomerInvoice") Then
			ServicesForSaleOfGoods(DocBasis, FillingData, AmountToPay);
			
		ElsIf BasisType = Type("DocumentRef.ReturnablePackagingRedemptionByCustomer") Then
			InstructionsForRedemptionOfReturnableContainersByClient(DocBasis, FillingData, AmountToPay);
			
		ElsIf BasisType = Type("DocumentRef.RedemptionOfGoodsByCustodian") Then
			InstructionsForRedemptionOfGoodsByCustodian(DocBasis, FillingData, AmountToPay);
			
		ElsIf BasisType = Type("DocumentRef.CustomerInvoiceServices") Then
			FillInActOfWorkPerformed(DocBasis, FillingData, AmountToPay);
			
		ElsIf BasisType = Type("DocumentRef.PlannedCashReceipt") Then
			FillInPlannedReceiptOfFunds(DocBasis, FillingData);
			
		ElsIf BasisType = Type("DocumentRef.CustomerInvoiceServicesAndAssets") Then
			ActivitiesForSaleOfServicesOfOtherAssets(DocBasis, FillingData, AmountToPay);
			
		ElsIf BasisType = Type("DocumentRef.ReturnOfGoodsToVendor") Then
			InstructionsForReturningGoodsToSupplier(DocBasis, FillingData);
			
		ElsIf BasisType = Type("CatalogRef.CounterpartyContracts") Then
			FillInUnderCounterpartySAgreement(DocBasis, FillingData, AmountToPay);
			
		ElsIf BasisType = Type("DocumentRef.ConsignmentReportFromCustomer") Then
			FillInReportOfCommissionAgent(DocBasis, FillingData, AmountToPay);
			
		ElsIf BasisType = Type("DocumentRef.ConsignmentReportToVendor") Then
			FillInReportToCommittee(DocBasis, FillingData, AmountToPay);
			
		ElsIf BasisType = Type("DocumentRef.BankAccountIssue") Then
			InstructionsForDebitingNonCashCashTransactions(DocBasis, FillingData);
			
		ElsIf BasisType = Type("DocumentRef.CustomerInvoiceIntercompany") Then
			InstructionsForTransferOfGoods(DocBasis, FillingData, AmountToPay);
			
		ElsIf BasisType = Type("DocumentRef.CommissionReportIntercompany") Then
			FillInCommissionReport(DocBasis, FillingData, AmountToPay);
			
		ElsIf BasisType = Type("DocumentRef.CashTransferReferenceOrder") Then
			CashServer.FillInDocumentOnOrderForTransferOfFunds(DocBasis, ThisObject, FillingData);
			
		ElsIf BasisType = Type("CatalogRef.LoanAndDepositContracts") Then
			CashServer.FillInUnderLoanDepositAgreement(DocBasis, FillingData, ARAPDetails, True);
			
		ElsIf BasisType = Type("DocumentRef.ReportToMaterialProvider2_5") Then
			FillInReportToGiver(DocBasis, FillingData, AmountToPay);
		ElsIf BasisType = Type("DocumentRef.MaterialProviderOrder2_5") Then
			FillInByOrderOfGiver(DocBasis, FillingData, AmountToPay);
		ElsIf BasisType = Type("DocumentRef.ConsumptionReportSubcontractingServicesDeliveredIntercompany") Then
			FillInGiverReportBetweenCompanies(DocBasis, FillingData, AmountToPay);
		ElsIf BasisType = Type("DocumentRef.PurchasingReportToConsignorPrincipal") Then
			FillInReportToPurchasingCommittee(DocBasis, FillingData, AmountToPay);
			
		ElsIf BasisType = Type("CatalogRef.GiftCertificates") Then
			FillInGiftCertificate(DocBasis, FillingData, AmountToPay);
			
		ElsIf TypeOf(DocBasis) = Type("DocumentRef." + Metadata().Name) Then
		
			DocumentCorrection.FillInCorrection(ThisObject, DocBasis);
			
		EndIf;
	
	ElsIf TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("BusinessOperation")
		And FillingData.BusinessOperation = Enums.BusinessTransactions.CashReturnByAdvanceHolder
		And FillingData.Property("AdvanceHolder") Then
		
		If Not FillingData.Property("Department") Then
			FillingData.Insert("Department", PersonsTM.DivisionOfIndividual(FillingData.AdvanceHolder));
		EndIf;
		
		NewRow = ARAPDetails.Add();
		FillPropertyValues(NewRow, FillingData);
		
	ElsIf TypeOf(FillingData) = Type("Structure") 
		And FillingData.Property("GiftCertificate")
		And FillingData.Property("Counterparty") Then
		
		FillInGiftCertificate(FillingData, FillingData, AmountToPay);
		
	ElsIf TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("Basis")
		And TypeOf(FillingData.Basis) = Type("Array") Then
		
		FillByArrayOfBases(FillingData, FillingData.Basis);
	EndIf;
	
	CashAccountReceiptNoteLocalization.Filling(ThisObject, DocBasis, FillingData, StandardProcessing);
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	If Not TypeOf(DocBasis) = Type("DocumentRef." + Metadata().Name) Then
		InitializeDocument(FillingData);
	EndIf;
	
	If FillingData = Undefined
		Or TypeOf(FillingData) <> Type("Structure")
		Or Not FillingData.Property("BusinessOperation")
		Or FillingData.BusinessOperation <> Enums.BusinessTransactions.CashReceiptFromBank Then
		
		AdditionalProperties.Insert("NeedToFillOutAccountWhenFOUseMultipleAccountsIsFalse", False);
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.CashAccountReceiptNote.ItemsAndDimensionsSelectionParameters(BusinessOperation);
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	ARAPAccountingServer.Filling(ThisObject, FillingData);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	
	DocumentBasis = Undefined;
	Author = Users.CurrentUser();
	
	ARAPAccountingServer.OnCopy(ThisObject);
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "ARAPDetails");
	
	CashAccountReceiptNoteLocalization.OnCopy(ThisObject, CopiedObject);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	
	ExplanationWithoutSplit = False;
	If AdditionalProperties.Property("ExplanationWithoutSplit")
		And AdditionalProperties.ExplanationWithoutSplit Then
		ExplanationWithoutSplit = True;
	EndIf;
	
	Documents.CashAccountReceiptNote.FillInNamesOfBusinessTransactionDetails(
		BusinessOperation, 
		ArrayOfAllProps, 
		ArrayOfOperationDetails);
	
	NotCheckedAttributeArray = New Array;
	
	TMCommonUseClientServer.FillInArrayOfUnverifiableBankingDetails(
		ArrayOfAllProps,
		ArrayOfOperationDetails,
		NotCheckedAttributeArray);
	CashServer.CheckOrderForTransferOfFunds(
		ThisObject,
		Cancel);
	CashServer.CheckCompletionOfPaymentDecryption(
		ThisObject,
		DocumentAmount,
		BusinessOperation,
		Cancel);
	CashServer.CheckCashRegister(
		ThisObject, 
		Cancel);
	CheckBankAccount(Cancel);
	CashServer.CheckConversionCurrency(ThisObject, Cancel);
	
	If ExplanationWithoutSplit Then
		NotCheckedAttributeArray.Add("ARAPDetails.Sum");
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.OtherCashReceipt Then
		NotCheckedAttributeArray.Add("Counterparty");
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.CashReturnByAdvanceHolder
		And TypeOf(DocumentBasis) = Type("DocumentRef.BankAccountIssue") Then
		NotCheckedAttributeArray.Add("CashVoucher");
	EndIf;
	If BusinessOperation = Enums.BusinessTransactions.LoanRepaymentByEmployee Then
		If Not ValueIsFilled(AdvanceHolder) Then
			CommonClientServer.MessageToUser(
				NStr("vi = 'Chưa điền trường ""Nhân viên""';
					|ru = 'Поле ""Сотрудник"" не заполнено.';
					|en = '""Employee"" is required.'; fa = '""Employee"" is required.';
					|it = 'Il campo ""Dipendente"" non è compilato.';
					|pl = 'Pole ""Pracownik"" nie jest wypełnione.';
					|tr = '""Çalışan"" alanı doldurulmamış.'"), , "AdvanceHolder", "Object", Cancel);
			NotCheckedAttributeArray.Add("AdvanceHolder");
		EndIf;
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.RefundFromLessor Then
		NotCheckedAttributeArray.Add("ARAPDetails.ARAPDocumentForLease");
		For Each DecryptionString In ARAPDetails Do
			If (DecryptionString.TypeOfLeasePayment = Enums.TypesOfLeasePayments.DepositPayment
				Or DecryptionString.TypeOfLeasePayment = Enums.TypesOfLeasePayments.BuyoutValuePrepayment)
				And Not ValueIsFilled(DecryptionString.ARAPDocumentForLease) Then
				
				ErrorText = NStr("vi = 'Chưa điền trường ""Chứng từ thanh toán"".';
								|ru = 'Поле ""Расчетный документ"" не заполнено.';
								|en = 'The ""AR/AP document"" field is not filled in.'; fa = 'The ""AR/AP document"" field is not filled in.';
								|it = 'Campo ""documento di calcolo"" non compilato.';
								|pl = 'Pole ""Dokument rozliczeniowy"" nie jest wypełnione.';
								|tr = '""Alacak/Borç belgesi"" alanı doldurulmamış.'");
				
				If ExplanationWithoutSplit Then
					FieldName = "Items.ARAPDetails.CurrentData.ARAPDocumentForLease";
					DataKey = Undefined;
				Else
					FieldName = CommonClientServer.PathToTabularSection(
						"ARAPDetails", DecryptionString.LineNumber, "ARAPDocumentForLease");
					DataKey = ThisObject;
				EndIf;
				
				Common.MessageToUser(ErrorText, DataKey, FieldName,, Cancel);
			EndIf;
		EndDo;
	EndIf;
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	Common.DeleteNotCheckedAttributesFromArray(
		CheckedAttributes, NotCheckedAttributeArray);
	
	ItemsAndDimensionsSelectionParameters = Documents.CashAccountReceiptNote.ItemsAndDimensionsSelectionParameters(BusinessOperation);
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	CashServer.CheckPartnerContent(
		ThisObject, BusinessOperation, NotCheckedAttributeArray, ExplanationWithoutSplit, Cancel);
	
	CashServer.CheckSenderSCashier(ThisObject, Cancel);
	
	If ExplanationWithoutSplit Then
		CashServer.CheckCompletionOfDecryptionWithoutSplitting(ThisObject, CheckedAttributes, "ARAPDetails", "ExplanationWithoutSplit", Cancel);
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
	
	CashAccountReceiptNoteLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	CheckRepaymentDates(Cancel);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	// Clear the table part if it should not be filled in.
	If ARAPDetails.Count() > 0
		And (BusinessOperation = Enums.BusinessTransactions.CashReceiptFromAnotherCashAccount
			Or BusinessOperation = Enums.BusinessTransactions.CashReceiptFromBank
			Or BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCashRegister)
	Then
		ARAPDetails.Clear();
	EndIf;
	
	If Not ValueIsFilled(Number) Then
		SetNewNumber();
	EndIf;
	
	//Setting up accounting accounts
	GLAccountSettingsServer.BeforeWrite(ThisObject,
		Documents.CashAccountReceiptNote.AccountingAccountSettings_(BusinessOperation));
	CashServer.BeforeWrite(ThisObject, Cancel);
	ARAPAccountingServer.BeforeWrite(ThisObject, Cancel, WriteMode);
	
	If WriteMode = DocumentWriteMode.Posting Then
		
		If BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer
			Or BusinessOperation = Enums.BusinessTransactions.RefundFromVendor
			Or BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany
			Or BusinessOperation = Enums.BusinessTransactions.RefundFromAnotherCompany
			Or BusinessOperation = Enums.BusinessTransactions.CashReceiptFromLoansRepayment
			Or BusinessOperation = Enums.BusinessTransactions.CashReceiptUnderDeposits
			Or BusinessOperation = Enums.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty
			Or BusinessOperation = Enums.BusinessTransactions.LoanRepaymentByEmployee
			Or BusinessOperation = Enums.BusinessTransactions.RefundFromLessor
			Then
			
			ARAPAccountingServer.FillInAmountOfSettlementsInTablePart(
				Currency, Date, ARAPDetails, Organization);
		EndIf;
		
		If IsBlankString(IncludingVAT) Then
			IncludingVAT = CashServer.TextAmountOfVATPayment(Organization, Currency, ARAPDetails, False);
		EndIf;
		
		CashServer.FillInOrganizationInTableSection(ARAPDetails, Organization, BusinessOperation);
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "ARAPDetails");
	
	// We will clear the details of the document that are not used for the business operation
	ArrayOfAllProps = New Array;
	ArrayOfOperationDetails = New Array;
	Documents.CashAccountReceiptNote.FillInNamesOfBusinessTransactionDetails(
		BusinessOperation,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	CashServer.ClearUnusedProps(
		ThisObject,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	If BusinessOperation = Enums.BusinessTransactions.LoanRepaymentByEmployee Then
		For Each String In ARAPDetails Do
			String.IncomeItem = ChartsOfCharacteristicTypes.AssetLiabilityItems.IssuedBorrowings;
			String.AssetsLiabilitiesDimension = Undefined;
		EndDo;
	EndIf;
	
	CheckChangesInBusinessOperations();
	
	AttributesStructure1 = New Structure();
	AttributesStructure1.Insert("FinancialAccountingGroup",  FinancialAccountingGroup);
	AttributesStructure1.Insert("LineOfBusiness", LineOfBusiness);
	AttributesStructure1.Insert("Contract",                 Contract);
	AttributesStructure1.Insert("Department",           Department);
	AttributesStructure1.Insert("DocumentRef",          Ref);
	
	UnallocatedPaymentDetails = CashServer.UnallocatedPaymentDetails(ARAPDetails, AttributesStructure1);
	If UnallocatedPaymentDetails.Count() > 0 Then
		For Each Column In UnallocatedPaymentDetails.Columns Do
			If Not ValueIsFilled(ThisObject[Column.Name]) Then
				ValueTable = UnallocatedPaymentDetails.Copy(,Column.Name);
				ValueTable.GroupBy(Column.Name);
				ArrayOfValues = ValueTable.UnloadColumn(Column.Name);
				If ArrayOfValues.Count() = 1 Then
					ThisObject[Column.Name] = ArrayOfValues[0];
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.CashAccountReceiptNote.ItemsAndDimensionsSelectionParameters(BusinessOperation);
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	CashAccountReceiptNoteLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	If Not ValueIsFilled(Author) And IsNew() Then
		Author = Users.CurrentUser();
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	CashAccountReceiptNoteLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	CashAccountReceiptNoteLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	CashAccountReceiptNoteLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnSetNewNumber(StandardProcessing, Prefix)
	
	Prefix = "0";
	If BusinessOperation = Enums.BusinessTransactions.CashReceiptFromAnotherCashAccount Then
		If TypeOf(CashAccountIssuer) = Type("CatalogRef.CashAccounts") Then
			If Common.ObjectAttributeValue(CashAccountIssuer, "CashBook")
				= Common.ObjectAttributeValue(CashAccount, "CashBook") Then
				Prefix = "In";
			EndIf;
		EndIf;
	EndIf;
	
	DocumentCorrection.OnSetNewNumber(ThisObject, StandardProcessing, Prefix);
	
EndProcedure

#EndRegion

#Region Private

#Region FillingByReason

Procedure FillInAdvanceReport(Val DocumentBasis, FillingData)
	
	// Fill in the data of the document header.
	Query = New Query("
	|SELECT
	|	VALUE(Enum.BusinessTransactions.CashReturnByAdvanceHolder) AS BusinessOperation,
	|	Document.Organization AS Organization,
	|	UNDEFINED AS CashAccount,
	|	Document.Currency AS Currency,
	|	Document.AdvanceHolder AS AdvanceHolder,
	|	Document.AdvanceHolder.Description AS ReceivedFrom,
	|	PRESENTATION(Document.Ref) AS Basis,
	|	Document.Ref AS ExpenseReport,
	|	Document.Ref AS DocumentBasis,
	|	Document.Balance AS DocumentAmount
	|FROM
	|	Document.ExpenseReport AS Document
	|WHERE
	|	Document.Ref = &Ref
	|");
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult.Select();
	If Selection.Next() Then
		FillPropertyValues(FillingData, Selection);
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(
			Enums.PaymentForms.CashAccountPayment_,
			FillingData);
	EndIf;
	
EndProcedure

Procedure FillInOnTheCustomerSOrder(Val DocumentBasis, FillingData, AmountToPay = 0)
	
	// Fill in the data of the document header.
	Query = New Query("
	|SELECT
	|	CASE WHEN DocumentData.CashAccount <> VALUE(Catalog.CashAccounts.EmptyRef) THEN
	|		DocumentData.CashAccount.Owner
	|	WHEN DocumentData.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.BankAccount.Owner
	|	ELSE
	|		DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Counterparty.Description AS CounterpartyName_,
	|	DocumentData.Counterparty.DescriptionFull AS CounterpartyFullName,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Ref AS DocumentBasis,
	|
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer) AS BusinessOperation,
	|	DocumentData.CashAccount AS CashAccount,
	|	DocumentData.Currency AS Currency
	|FROM
	|	Document.SalesOrder AS DocumentData
	|	
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
	|	AND DocumentData.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)
	|");
	
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhập phiếu thu trên cơ sở chứng từ %1';
				|ru = 'Не требуется вводить приходный кассовый ордер на основании документа %1';
				|en = 'It is not required to enter an ""Incoming payment — Cash account"" based on document %1'; fa = 'It is not required to enter an ""Incoming payment — Cash account"" based on document %1';
				|it = 'Non è necessario inserire la ricevuta di cassa in base al documento %1';
				|pl = 'Nie trzeba prowadzać asygnaty kasowej przychodowej na podstawie dokumentu %1';
				|tr = '%1 belgesine göre gelen ödeme - kasa hesabı girmek gerekli değildir'"),
			DocumentBasis);
		Raise Text;
	Else
		
		For Each Column In QueryResult.Columns Do
			FillingData.Insert(Column.Name);
		EndDo;
		
		Selection = QueryResult.Select();
		Selection.Next();
		FillPropertyValues(FillingData, Selection);
		
		If Not IsBlankString(Selection.CounterpartyFullName) Then
			FillingData.Insert("ReceivedFrom", Selection.CounterpartyFullName);
		Else
			FillingData.Insert("ReceivedFrom", Selection.CounterpartyName_);
		EndIf;
		
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(
			Enums.PaymentForms.CashAccountPayment_,
			FillingData);
		
		ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
		ParametersForFillingInDecryption.SalesOrder     = DocumentBasis;
		ParametersForFillingInDecryption.Contract          = Selection.Contract;
		ParametersForFillingInDecryption.DocumentCurrency  = FillingData.Currency;
		ParametersForFillingInDecryption.Partner          = Selection.Partner;
		ParametersForFillingInDecryption.PaymentPurpose = DocumentBasis;
		
		ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(
			ParametersForFillingInDecryption,
			ARAPDetails,
			AmountToPay);
	EndIf;
	
	// Filling in the amount of the document header
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure

Procedure FillInInvoiceForPaymentToClient(Val ProformaInvoice, FillingData)
	
	// Fill in the data of the document header.
	Query = New Query("
	|SELECT
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer) AS BusinessOperation,
	|	CASE WHEN DocumentData.CashAccount <> VALUE(Catalog.CashAccounts.EmptyRef) THEN
	|		DocumentData.CashAccount.Owner
	|	WHEN DocumentData.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.BankAccount.Owner
	|	ELSE
	|		DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.DocumentBasis.Counterparty AS Counterparty,
	|	DocumentData.DocumentBasis.Counterparty.Description AS CounterpartyName_,
	|	DocumentData.DocumentBasis.Counterparty.DescriptionFull AS CounterpartyFullName,
	|	DocumentData.DocumentBasis AS SalesOrder,
	|	DocumentData.Ref AS DocumentBasis,
	|	DocumentData.Contract AS Contract,
	|
	|	DocumentData.CashAccount AS CashAccount,
	|	CASE WHEN DocumentData.CashAccount <> VALUE(Catalog.CashAccounts.EmptyRef) THEN
	|		DocumentData.CashAccount.CashCurrency
	|	ELSE
	|		DocumentData.Currency
	|	END AS Currency
	|FROM
	|	Document.CustomerCommercialInvoice AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|");
	Query.SetParameter("Ref", ProformaInvoice);
	
	QueryResult = Query.Execute();
	
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult.Select();
	If Selection.Next() Then
		FillPropertyValues(FillingData, Selection);
		
		If Not IsBlankString(Selection.CounterpartyFullName) Then
			FillingData.Insert("ReceivedFrom", Selection.CounterpartyFullName);
		Else
			FillingData.Insert("ReceivedFrom", Selection.CounterpartyName_);
		EndIf;
		
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(
			Enums.PaymentForms.CashAccountPayment_,
			FillingData);
			
		ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnInvoice(
			ProformaInvoice,
			Selection.Organization,
			Selection.SalesOrder,
			FillingData.Currency,
			ARAPDetails);
	EndIf;
	
	// Filling in the amount of the document header
	DocumentAmount = ARAPDetails.Total("Sum");
	
	DocumentBasis = ProformaInvoice;
	
EndProcedure

Procedure ServicesForSaleOfGoods(Val GoodsSales, FillingData, AmountToPay = 0)
	
	// Fill in the data of the document header.
	Query = New Query("
	|SELECT
	|	CASE WHEN DocumentData.CashAccount <> VALUE(Catalog.CashAccounts.EmptyRef) THEN
	|		DocumentData.CashAccount.Owner
	|	WHEN DocumentData.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.CompanyBankAccount.Owner
	|	ELSE
	|		DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Counterparty.Description AS CounterpartyName_,
	|	DocumentData.Counterparty.DescriptionFull AS CounterpartyFullName,
	|	DocumentData.Contract AS Contract,
	|	ISNULL(DocumentData.Contract.ContractType, VALUE(Enum.ContractTypes.EmptyRef)) AS ContractTypeOfContract,
	|	ISNULL(DocumentData.Contract.ConsignmentSales25, FALSE) AS ContractCommissionSales25,
	|	ISNULL(DocumentData.Contract.ConductARAPAccountingThroughEndCustomers, FALSE) AS ContractToConductSettlementsThroughEndCustomers,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.AmountARAP AS AmountARAP,
	|	DocumentData.AmountARAP AS Sum,
	|	DocumentData.Ref AS DocumentBasis,
	|	&ARAPObject AS ARAPObject,
	|	DocumentData.ARAPObjectSettings AS ARAPObjectSettings,
	|	DocumentData.OrderSales AS OrderSales,
	|	
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer) AS BusinessOperation,
	|	DocumentData.CashAccount AS CashAccount,
	|	DocumentData.Currency AS Currency
	|FROM
	|	Document.CustomerInvoice AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|");
	
	Query.SetParameter("Ref", GoodsSales);
	Query.SetParameter("ARAPObject", ARAPObjectsServer.GetCalculationObjectFromLink(GoodsSales));
	
	QueryResult = Query.Execute();
	
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult.Select();
	If Selection.Next() Then
		
		FillPropertyValues(FillingData, Selection);
		
		If Not IsBlankString(Selection.CounterpartyFullName) Then
			FillingData.Insert("ReceivedFrom", Selection.CounterpartyFullName);
		Else
			FillingData.Insert("ReceivedFrom", Selection.CounterpartyName_);
		EndIf;
		
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(
			Enums.PaymentForms.CashAccountPayment_, FillingData);
			
		ContractForCommissionSettlementsThroughEndCustomers = Selection.ContractTypeOfContract = Enums.ContractTypes.WithConsignee
				And Selection.ContractCommissionSales25
				And Selection.ContractToConductSettlementsThroughEndCustomers;
		
		If ((Selection.ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments
			Or Selection.ARAPObjectSettings = Enums.ARAPObjectSettings.ByOrders)
			And Not Selection.OrderSales) 
			Or Selection.ARAPObjectSettings = Enums.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice
			Or Selection.ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice 
				And Not ContractForCommissionSettlementsThroughEndCustomers Then
			
			GraphLines = CashServer.ScheduleLinesForPayment(Selection.DocumentBasis);
			If GraphLines.Count() Then
				
				Result = CashServer.PayChartLines(GraphLines, "CashAccountReceiptNote");
				
				If Result.Property("DocumentToCreate") And ValueIsFilled(Result.DocumentToCreate) Then
					FillByArrayOfBases(FillingData, Result.DocumentToCreate.FillingData.Basis);
				EndIf;
			EndIf;
		Else
			
			Query = New Query;
			Query.SetParameter("Ref", GoodsSales);
			Query.Text =
			"SELECT DISTINCT
			|	GoodsTable.SalesOrder AS SalesOrder
			|FROM
			|	Document.CustomerInvoice.Goods AS GoodsTable
			|		INNER JOIN Document.CustomerInvoice AS DocumentTable
			|		ON GoodsTable.Ref = DocumentTable.Ref
			|WHERE
			|	GoodsTable.Ref = &Ref
			|	AND DocumentTable.OrderSales
			|	AND NOT (VALUETYPE(GoodsTable.SalesOrder) = TYPE(Document.GoodsShipmentToCustomer)
			|		OR VALUETYPE(GoodsTable.SalesOrder) = TYPE(Document.SourceDocument)
			|			AND CAST(GoodsTable.SalesOrder AS
			|			Document.SourceDocument).SourceDocumentType =
			|				VALUE(Enum.SourceDocumentTypes.GoodsShipmentToCustomer))";
			
			RequestResultForOrders = Query.Execute();
			If Not RequestResultForOrders.IsEmpty() Then
				CustomerOrders = RequestResultForOrders.Unload().UnloadColumn("SalesOrder");
				CustomerOrders.Add(GoodsSales);
			Else
				CustomerOrders = GoodsSales;
			EndIf;
			
			ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
			If Selection.ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice 
				And ContractForCommissionSettlementsThroughEndCustomers Then
				ParametersForFillingInDecryption.SalesOrder = Selection.Contract;
				ParametersForFillingInDecryption.PaymentPurpose = Selection.Contract;
			Else
				ParametersForFillingInDecryption.SalesOrder = CustomerOrders;
				ParametersForFillingInDecryption.PaymentPurpose = GoodsSales;
			EndIf;
			ParametersForFillingInDecryption.Contract          = Selection.Contract;
			ParametersForFillingInDecryption.DocumentCurrency  = FillingData.Currency;
			ParametersForFillingInDecryption.Partner          = Selection.Partner;
			
			If AmountToPay = 0 Then
				AmountToPay = Selection.Sum;
			EndIf;
			
			ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(
				ParametersForFillingInDecryption,
				ARAPDetails,
				AmountToPay);
		EndIf;
	EndIf;
	
	// Filling in the amount of the document header
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure

Procedure FillInActOfWorkPerformed(Val CustomerInvoiceServices, FillingData, AmountToPay = 0)
	
	// Fill in the data of the document header.
	Query = New Query("
	|SELECT
	|	CASE WHEN DocumentData.CashAccount <> VALUE(Catalog.CashAccounts.EmptyRef) THEN
	|		DocumentData.CashAccount.Owner
	|	WHEN DocumentData.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.CompanyBankAccount.Owner
	|	ELSE
	|		DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Counterparty.Description AS CounterpartyName_,
	|	DocumentData.Counterparty.DescriptionFull AS CounterpartyFullName,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.AmountARAP AS AmountARAP,
	|	DocumentData.AmountARAP AS Sum,
	|	DocumentData.Ref AS DocumentBasis,
	|	DocumentData.ARAPObjectSettings AS ARAPObjectSettings,
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer) AS BusinessOperation,
	|	DocumentData.CashAccount AS CashAccount,
	|	DocumentData.Currency AS Currency
	|FROM
	|	Document.CustomerInvoiceServices AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|");
	
	Query.SetParameter("Ref", CustomerInvoiceServices);
	Query.SetParameter("ARAPObject", ARAPObjectsServer.GetCalculationObjectFromLink(CustomerInvoiceServices));
	
	QueryResult = Query.Execute();
	
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult.Select();
	If Selection.Next() Then
		
		FillPropertyValues(FillingData, Selection);
		
		If Not IsBlankString(Selection.CounterpartyFullName) Then
			FillingData.Insert("ReceivedFrom", Selection.CounterpartyFullName);
		Else
			FillingData.Insert("ReceivedFrom", Selection.CounterpartyName_);
		EndIf;
		
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(
			Enums.PaymentForms.CashAccountPayment_, FillingData);
		
		If Selection.ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments
			Or Selection.ARAPObjectSettings = Enums.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice
			Or Selection.ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice Then
			
			GraphLines = CashServer.ScheduleLinesForPayment(Selection.DocumentBasis);
			If GraphLines.Count() Then
				
				Result = CashServer.PayChartLines(GraphLines, "CashAccountReceiptNote");
				
				If Result.Property("DocumentToCreate") And ValueIsFilled(Result.DocumentToCreate) Then
					FillByArrayOfBases(FillingData, Result.DocumentToCreate.FillingData.Basis);
				EndIf;
			EndIf;
		Else
		
			Query = New Query("
			|SELECT DISTINCT
			|	TableServices.SalesOrder AS SalesOrder
			|FROM
			|	Document.CustomerInvoiceServices.Services AS TableServices
			|WHERE
			|	TableServices.Ref = &Ref
			|	AND TableServices.Ref.InvoiceByOrders
			|");
			Query.SetParameter("Ref", CustomerInvoiceServices);
			
			RequestResultForOrders = Query.Execute();
			If Not RequestResultForOrders.IsEmpty() Then
				CustomerOrders = RequestResultForOrders.Unload().UnloadColumn("SalesOrder");
				CustomerOrders.Add(CustomerInvoiceServices);
			Else
				CustomerOrders = CustomerInvoiceServices;
			EndIf;
			
			ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
			ParametersForFillingInDecryption.SalesOrder     = CustomerOrders;
			ParametersForFillingInDecryption.Contract          = Selection.Contract;
			ParametersForFillingInDecryption.DocumentCurrency  = FillingData.Currency;
			ParametersForFillingInDecryption.Partner          = Selection.Partner;
			ParametersForFillingInDecryption.PaymentPurpose = CustomerInvoiceServices;
			
			If AmountToPay = 0 Then
				AmountToPay = Selection.Sum;
			EndIf;
			
			ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(
				ParametersForFillingInDecryption,
				ARAPDetails,
				AmountToPay);
		EndIf;
	EndIf;
	
	// Filling in the amount of the document header
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure

Procedure FillInPlannedReceiptOfFunds(Val DocumentBasis, FillingData)
	
	// Fill in the data of the document header.
	Query = New Query("
	|SELECT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.CashAccount AS CashAccount,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.CashFlowItem AS CashFlowItem,
	|	DocumentData.PaymentPurposes AS PaymentPurposes,
	|	DocumentData.Ref AS DocumentBasis,
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|	DocumentData.DocumentAmount AS Sum,
	|	CASE WHEN COUNT(DISTINCT BusinessTransactions.BusinessOperation) = 1 THEN
	|		MAX(BusinessTransactions.BusinessOperation)
	|	END AS BusinessOperation
	|FROM
	|	Document.PlannedCashReceipt AS DocumentData
	|	
	|	LEFT JOIN
	|		Catalog.CashFlowReportItems.BusinessTransactions AS BusinessTransactions
	|	ON
	|		BusinessTransactions.Ref = DocumentData.CashFlowItem
	|	
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|GROUP BY
	|	DocumentData.Organization,
	|	DocumentData.CashAccount,
	|	DocumentData.Currency,
	|	DocumentData.CashFlowItem,
	|	DocumentData.PaymentPurposes,
	|	DocumentData.Ref,
	|	DocumentData.DocumentAmount
	|");
	
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhập phiếu thu trên cơ sở chứng từ %1';
				|ru = 'Не требуется вводить приходный кассовый ордер на основании документа %1';
				|en = 'It is not required to enter an ""Incoming payment — Cash account"" based on document %1'; fa = 'It is not required to enter an ""Incoming payment — Cash account"" based on document %1';
				|it = 'Non è necessario inserire la ricevuta di cassa in base al documento %1';
				|pl = 'Nie trzeba prowadzać asygnaty kasowej przychodowej na podstawie dokumentu %1';
				|tr = '%1 belgesine göre gelen ödeme - kasa hesabı girmek gerekli değildir'"),
			DocumentBasis);
		Raise Text;
	Else
		For Each Column In QueryResult.Columns Do
			FillingData.Insert(Column.Name);
		EndDo;
		
		Selection = QueryResult.Select();
		Selection.Next();
		
		FillPropertyValues(FillingData, Selection);
		
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(
			Enums.PaymentForms.CashAccountPayment_,
			FillingData);
		
		NewRow = ARAPDetails.Add();
		FillPropertyValues(NewRow, Selection);
	EndIf;
	
EndProcedure

Procedure FillInUsingExpenseCashOrder(Val DocumentBasis, FillingData)
	
	// Fill in the data of the document header.
	Query = New Query("
	|SELECT
	|	CASE WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CashIssueToAnotherCashAccount) THEN
	|		VALUE(Enum.BusinessTransactions.CashReceiptFromAnotherCashAccount)
	|
	|	WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany)
	|	THEN
	|		VALUE(Enum.BusinessTransactions.CashReceiptFromOtherCompany)
	|
	|	WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundToAnotherCompany)
	|	THEN
	|		VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany)
	|
	|	WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder) THEN
	|		VALUE(Enum.BusinessTransactions.CashReturnByAdvanceHolder)
	|
	|	ELSE
	|		DocumentData.BusinessOperation
	|	END AS BusinessOperation,
	|
	|	CASE WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CashIssueToAnotherCashAccount)
	|		OR DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany)
	|		OR DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundToAnotherCompany)
	|		OR DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices)
	|		OR DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CurrencyConversion)
	|	THEN
	|		DocumentData.CashAccountRecipient
	|	WHEN
	|		&CashAccount <> VALUE(Catalog.CashAccounts.EmptyRef)
	|	THEN
	|		&CashAccount
	|	ELSE
	|		DocumentData.CashAccount
	|	END AS CashAccount,
	|
	|	DocumentData.CashAccount AS CashAccountIssuer,
	|	
	|	CASE WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany)
	|		OR DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundToAnotherCompany)
	|		OR DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices)
	|	THEN
	|		DocumentData.CashAccountRecipient.Owner
	|	ELSE
	|		DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.Department AS Department,
	|
	|	CASE WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany)
	|		OR DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundToAnotherCompany)
	|		OR DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
	|	THEN
	|		VALUE(Catalog.CashFlowReportItems.EmptyRef)
	|	ELSE
	|		DocumentData.CashFlowItem
	|	END AS CashFlowItem,
	|
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.AdvanceHolder AS AdvanceHolder,
	|	DocumentData.AdvanceHolder.Description AS ReportingEntityName,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.Currency AS CurrencyOfConversion,
	
	|	CASE WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CurrencyConversion) THEN
	|		CASE WHEN DocumentData.Currency = DocumentData.Organization.LocalAccountingCurrency
	|			OR DocumentData.CurrencyOfConversion = DocumentData.Organization.LocalAccountingCurrency
	|			OR DocumentData.CashAccountRecipient.CashCurrency = DocumentData.Organization.LocalAccountingCurrency THEN
	|			DocumentData.ConversionRate
	|		ELSE
	|			1 / DocumentData.ConversionRate
	|		END
	|	ELSE 0
	|	END AS ConversionRate,
	
	|	CASE WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CurrencyConversion) THEN
	|		CASE WHEN DocumentData.Currency = DocumentData.Organization.LocalAccountingCurrency
	|			OR DocumentData.CurrencyOfConversion = DocumentData.Organization.LocalAccountingCurrency
	|			OR DocumentData.CashAccountRecipient.CashCurrency = DocumentData.Organization.LocalAccountingCurrency THEN
	|			DocumentData.ConversionRateMultiplier
	|		ELSE
	|			1
	|		END
	|	ELSE 0
	|	END AS ConversionRateMultiplier,
	
	|	DocumentData.Ref AS CashVoucher,
	|	DocumentData.Ref AS DocumentBasis,
	|
	|	CASE WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder) THEN
	|		ISNULL(AdvanceHolderCash.SumBalance, 0)
	|	WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CurrencyConversion) THEN
	|		DocumentData.ConversionAmount
	|	ELSE
	|		DocumentData.DocumentAmount
	|
	|	END AS DocumentAmount,
	|	DocumentData.DocumentAmount AS ConversionAmount,
	|
	|	CASE WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany)
	|		OR DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundToAnotherCompany)
	|	THEN
	|		DocumentData.Organization.DescriptionFull
	|	ELSE
	|		""""
	|	END AS ReceivedFrom
	|
	|FROM
	|	Document.CashVoucher AS DocumentData
	|
	|	LEFT JOIN
	|		AccumulationRegister.AdvanceHolderCash.Balance(, ) AS AdvanceHolderCash
	|	ON
	|		AdvanceHolderCash.Organization = DocumentData.Organization
	|		AND AdvanceHolderCash.AdvanceHolder = DocumentData.AdvanceHolder
	|		AND AdvanceHolderCash.Currency = DocumentData.Currency
	|	
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.CashIssueToAnotherCashAccount),
	|		VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany),
	|		VALUE(Enum.BusinessTransactions.RefundToAnotherCompany),
	|		VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices),
	|		VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder),
	|		VALUE(Enum.BusinessTransactions.CurrencyConversion)
	|	)
	|");
	Query.SetParameter("Ref", DocumentBasis);
	Query.SetParameter("CashAccount", CashAccount);
	
	QueryResult = Query.Execute();
	
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	If QueryResult.IsEmpty() Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhập phiếu thu trên cơ sở chứng từ %1
			|với giao dịch kinh tế %2';
			|ru = 'Не требуется вводить приходный кассовый ордер на основании документа %1
			|с хозяйственной операцией %2';
			|en = 'You do not have to enter ""Incoming payment — Cash account"" based on document %1 
			| business transaction %2'; fa = 'You do not have to enter ""Incoming payment — Cash account"" based on document %1 
			| business transaction %2';
			|it = 'Non è necessario inserire la ricevuta di cassa in base al documento %1
			|con la transazione commerciale %2';
			|pl = 'Nie trzeba prowadzać asygnaty kasowej przychodowej na podstawie dokumentu %1
			|z operacją gospodarczą %2';
			|tr = '%1 belgesine göre gelen ödeme - kasa hesabı girmek gerekli değildir 
			|ticari işleme sahip%2'"),
			DocumentBasis,
			Common.ObjectAttributeValue(DocumentBasis, "BusinessOperation"));
		Raise Text;
	Else
		
		Selection = QueryResult.Select();
		Selection.Next();
		
		FillPropertyValues(FillingData, Selection,, "CashFlowItem");
		
		If FillingData.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany
			Or FillingData.BusinessOperation = Enums.BusinessTransactions.RefundFromAnotherCompany Then
			
			Query = New Query("
			|SELECT
			|	CASE 
			|		WHEN ARAPDetails.ARAPObject.Object REFS Document.CashVoucher
			|			THEN UNDEFINED
			|		ELSE ISNULL(ARAPObjects.Ref, VALUE(Catalog.ARAPObjects.EmptyRef))
			|	END AS ARAPObject,
			|	ARAPDetails.Sum AS Sum,
			|	ARAPDetails.AmountARAP AS AmountARAP,
			|	ARAPDetails.ARAPCurrency AS ARAPCurrency
			|FROM
			|	Document.CashVoucher.ARAPDetails AS ARAPDetails
			|		INNER JOIN Catalog.ARAPObjects AS ObjectsOfDecryptionCalculations
			|			ON ObjectsOfDecryptionCalculations.Ref = ARAPDetails.ARAPObject
			|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
			|			ON ARAPObjects.Object = ObjectsOfDecryptionCalculations.Object
			|			AND ARAPObjects.PaymentType_ <> ObjectsOfDecryptionCalculations.PaymentType_
			|			AND ARAPObjects.Organization = ObjectsOfDecryptionCalculations.Counterparty
			|			AND NOT ARAPObjects.DeletionMark
			|WHERE
			|	ARAPDetails.Ref = &Ref
			|");
			
			Query.SetParameter("Ref", DocumentBasis);
			ARAPDetails.Load(Query.Execute().Unload());
		EndIf;
		
		If FillingData.BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices Then
			FillingData.CashFlowItem = Selection.CashFlowItem;
		EndIf;
		
		If FillingData.BusinessOperation = Enums.BusinessTransactions.CashReturnByAdvanceHolder Then
			
			DecryptionString = ARAPDetails.Add();
			DecryptionString.Sum = Selection.DocumentAmount;
			
			Query = New Query("
			|SELECT DISTINCT
			|	ARAPDetails.CashFlowItem AS CashFlowItem
			|FROM
			|	Document.CashVoucher.ARAPDetails AS ARAPDetails
			|WHERE
			|	ARAPDetails.Ref = &Ref
			|");
			
			Query.SetParameter("Ref", DocumentBasis);
			SelectionOfCFItems = Query.Execute().Select();
			If SelectionOfCFItems.Next() Then
				DecryptionString.CashFlowItem = SelectionOfCFItems.CashFlowItem;
			EndIf;
			
			ReceivedFrom = FillingData.ReportingEntityName;
		EndIf;
		
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(
			Enums.PaymentForms.CashAccountPayment_, FillingData);
		
		If FillingData.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion Then
			
			ConversionParameters_SSLy = CashServer.InitializeConversionParameters();
			FillPropertyValues(ConversionParameters_SSLy, FillingData);
			ConversionParameters_SSLy.DocumentAmount = 0;
			ConversionParameters_SSLy.CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(FillingData.Organization);
			
			CashServer.CalculateConversionParameters(ConversionParameters_SSLy, "ConversionAmount");
			FillPropertyValues(FillingData, ConversionParameters_SSLy);
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure FillInRequestForReturnOfGoods(Val DocumentBasis, FillingData, AmountToPay = 0)
	
	// Fill in the data of the document header.
	Query = New Query("
	|SELECT
	|	CASE WHEN DocumentData.CashAccount <> VALUE(Catalog.CashAccounts.EmptyRef) THEN
	|		DocumentData.CashAccount.Owner
	|	WHEN DocumentData.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.BankAccount.Owner
	|	ELSE
	|		DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Counterparty.Description AS CounterpartyName_,
	|	DocumentData.Counterparty.DescriptionFull AS CounterpartyFullName,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Ref AS DocumentBasis,
	|
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer) AS BusinessOperation,
	|	DocumentData.CashAccount AS CashAccount,
	|	DocumentData.Currency AS Currency
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer AS DocumentData
	|	
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
	|	AND DocumentData.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)
	|");
	
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhập phiếu thu trên cơ sở chứng từ %1';
				|ru = 'Не требуется вводить приходный кассовый ордер на основании документа %1';
				|en = 'It is not required to enter an ""Incoming payment — Cash account"" based on document %1'; fa = 'It is not required to enter an ""Incoming payment — Cash account"" based on document %1';
				|it = 'Non è necessario inserire la ricevuta di cassa in base al documento %1';
				|pl = 'Nie trzeba prowadzać asygnaty kasowej przychodowej na podstawie dokumentu %1';
				|tr = '%1 belgesine göre gelen ödeme - kasa hesabı girmek gerekli değildir'"),
			DocumentBasis);
		Raise Text;
	Else
		For Each Column In QueryResult.Columns Do
			FillingData.Insert(Column.Name);
		EndDo;
		
		Selection = QueryResult.Select();
		Selection.Next();
		FillPropertyValues(FillingData, Selection);
		
		If Not IsBlankString(Selection.CounterpartyFullName) Then
			FillingData.Insert("ReceivedFrom", Selection.CounterpartyFullName);
		Else
			FillingData.Insert("ReceivedFrom", Selection.CounterpartyName_);
		EndIf;
		
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(
			Enums.PaymentForms.CashAccountPayment_,
			FillingData);
		
		ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
		ParametersForFillingInDecryption.SalesOrder     = DocumentBasis;
		ParametersForFillingInDecryption.Contract          = Selection.Contract;
		ParametersForFillingInDecryption.DocumentCurrency  = FillingData.Currency;
		ParametersForFillingInDecryption.Partner          = Selection.Partner;
		ParametersForFillingInDecryption.PaymentPurpose = DocumentBasis;
		
		ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(
			ParametersForFillingInDecryption,
			ARAPDetails,
			AmountToPay);
	EndIf;
	
	// Filling in the amount of the document header
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure

Procedure ActivitiesForSaleOfServicesOfOtherAssets(Val SaleOfGoodsAndServices, FillingData, AmountToPay = 0)
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	CASE WHEN DocumentData.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.CompanyBankAccount.Owner
	|	ELSE
	|		DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Counterparty.Description AS CounterpartyName_,
	|	DocumentData.Counterparty.DescriptionFull AS ReceivedFrom,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.AmountARAP AS AmountARAP,
	|	DocumentData.AmountARAP AS Sum,
	|	DocumentData.Ref AS DocumentBasis,
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer) AS BusinessOperation,
	|	DocumentData.Currency AS Currency,
	|	UNDEFINED AS CashAccount
	|FROM
	|	Document.CustomerInvoiceServicesAndAssets AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	Query.SetParameter("Ref", SaleOfGoodsAndServices);
	QueryResult = Query.Execute();
	
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult.Select();
	If Selection.Next() Then
		FillPropertyValues(FillingData, Selection);
		If IsBlankString(FillingData.ReceivedFrom) Then
			FillingData.ReceivedFrom = Selection.CounterpartyName_;
		EndIf;
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(Enums.PaymentForms.CashAccountPayment_, FillingData);
		
		ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
		ParametersForFillingInDecryption.SalesOrder     = SaleOfGoodsAndServices;
		ParametersForFillingInDecryption.Contract          = Selection.Contract;
		ParametersForFillingInDecryption.DocumentCurrency  = FillingData.Currency;
		ParametersForFillingInDecryption.Partner          = Selection.Partner;
		ParametersForFillingInDecryption.PaymentPurpose = SaleOfGoodsAndServices;
		
		ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(
			ParametersForFillingInDecryption,
			ARAPDetails,
			AmountToPay);
	EndIf;
	
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure

Procedure FillInByOrderOfGiver(Val MaterialProviderOrder, FillingData, AmountToPay = 0)
	
	// Fill in the data of the document header.
	Query = New Query("
	|SELECT
	|	CASE
	|		WHEN DocumentData.CashAccount <> VALUE(Catalog.CashAccounts.EmptyRef)
	|			THEN DocumentData.CashAccount.Owner
	|		WHEN DocumentData.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
	|			THEN DocumentData.BankAccount.Owner
	|		ELSE DocumentData.Organization
	|	END                                                                   AS Organization,
	|	DocumentData.Partner                                                 AS Partner,
	|	DocumentData.Counterparty                                              AS Counterparty,
	|	DocumentData.Counterparty.Description                                 AS CounterpartyName_,
	|	DocumentData.Counterparty.DescriptionFull                           AS CounterpartyFullName,
	|	DocumentData.Contract                                                 AS Contract,
	|	DocumentData.Ref                                                  AS DocumentBasis,
	|
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer) AS BusinessOperation,
	|	DocumentData.CashAccount                                                   AS CashAccount,
	|	DocumentData.Currency                                                  AS Currency
	|FROM
	|	Document.MaterialProviderOrder2_5 AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|");
	
	Query.SetParameter("Ref", MaterialProviderOrder);
	
	QueryResult = Query.Execute();
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult.Select();
	If Selection.Next() Then
		
		FillPropertyValues(FillingData, Selection);
		
		If Not IsBlankString(Selection.CounterpartyFullName) Then
			FillingData.Insert("ReceivedFrom", Selection.CounterpartyFullName);
		Else
			FillingData.Insert("ReceivedFrom", Selection.CounterpartyName_);
		EndIf;
		
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(
			Enums.PaymentForms.CashAccountPayment_,
			FillingData);
		
		ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
		ParametersForFillingInDecryption.SalesOrder     = MaterialProviderOrder;
		ParametersForFillingInDecryption.Contract          = Selection.Contract;
		ParametersForFillingInDecryption.DocumentCurrency  = FillingData.Currency;
		ParametersForFillingInDecryption.Partner          = Selection.Partner;
		ParametersForFillingInDecryption.PaymentPurpose = MaterialProviderOrder;
		
		ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(
			ParametersForFillingInDecryption,
			ARAPDetails,
			AmountToPay);
	EndIf;
	
	// Filling in the amount of the document header
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure

Procedure FillInReportToGiver(Val ReportToMaterialProvider, FillingData, AmountToPay = 0)
	
	// Fill in the data of the document header.
	Query = New Query("
	|SELECT
	|	CASE
	|		WHEN DocumentData.CashAccount <> VALUE(Catalog.CashAccounts.EmptyRef)
	|			THEN DocumentData.CashAccount.Owner
	|		WHEN DocumentData.CompanyBankAccount <>
	|									VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
	|			THEN DocumentData.CompanyBankAccount.Owner
	|		ELSE DocumentData.Organization
	|	END                                                                   AS Organization,
	|	DocumentData.Partner                                                 AS Partner,
	|	DocumentData.Counterparty                                              AS Counterparty,
	|	DocumentData.Counterparty.Description                                 AS CounterpartyName_,
	|	DocumentData.Counterparty.DescriptionFull                           AS CounterpartyFullName,
	|	DocumentData.Contract                                                 AS Contract,
	|	DocumentData.ARAPCurrency                                    AS ARAPCurrency,
	|	DocumentData.AmountARAP                                     AS AmountARAP,
	|	DocumentData.AmountARAP                                     AS Sum,
	|	DocumentData.Ref                                                  AS DocumentBasis,
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer) AS BusinessOperation,
	|	DocumentData.CashAccount                                                   AS CashAccount,
	|	DocumentData.Currency                                                  AS Currency
	|FROM
	|	Document.ReportToMaterialProvider2_5 AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|");
	Query.SetParameter("Ref", ReportToMaterialProvider);
	
	QueryResult = Query.Execute();
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult.Select();
	If Selection.Next() Then
		
		FillPropertyValues(FillingData, Selection);
		
		If Not IsBlankString(Selection.CounterpartyFullName) Then
			FillingData.Insert("ReceivedFrom", Selection.CounterpartyFullName);
		Else
			FillingData.Insert("ReceivedFrom", Selection.CounterpartyName_);
		EndIf;
		
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(
			Enums.PaymentForms.CashAccountPayment_,
			FillingData);
		
		Query = New Query("
		|SELECT DISTINCT
		|	ProductTable.MaterialProviderOrder AS SalesOrder
		|FROM
		|	Document.ReportToMaterialProvider2_5.ManufacturedProduct AS ProductTable
		|WHERE
		|	ProductTable.Ref = &Ref
		|");
		Query.SetParameter("Ref", ReportToMaterialProvider);
		
		RequestResultForOrders = Query.Execute();
		If Not RequestResultForOrders.IsEmpty() Then
			CustomerOrders = RequestResultForOrders.Unload().UnloadColumn("SalesOrder");
			CustomerOrders.Add(ReportToMaterialProvider);
		Else
			CustomerOrders = ReportToMaterialProvider;
		EndIf;
		
		ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
		ParametersForFillingInDecryption.SalesOrder     = CustomerOrders;
		ParametersForFillingInDecryption.Contract          = Selection.Contract;
		ParametersForFillingInDecryption.DocumentCurrency  = FillingData.Currency;
		ParametersForFillingInDecryption.Partner          = Selection.Partner;
		ParametersForFillingInDecryption.PaymentPurpose = ReportToMaterialProvider;
		
		ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(
			ParametersForFillingInDecryption,
			ARAPDetails,
			AmountToPay);
	EndIf;
	
	// Filling in the amount of the document header
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure

Procedure FillInGiverReportBetweenCompanies(Val DocumentBasis, FillingData, AmountToPay = 0)
	
	Query = New Query("
	|SELECT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.MaterialProvider AS Partner,
	|	DocumentData.MaterialProvider AS Counterparty,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS CashAccount,
	|	UNDEFINED AS CashAccountIssuer,
	|
	|	DocumentData.Currency AS Currency,
	|	&Ref AS DocumentBasis,
	|	
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromOtherCompany) AS BusinessOperation
	|FROM
	|	Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredIntercompany)
	|");
	
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult.Select();
	If Selection.Next() Then
		FillPropertyValues(FillingData, Selection);
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(Enums.PaymentForms.CashAccountPayment_, FillingData);
		
		ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
		ParametersForFillingInDecryption.SalesOrder     = DocumentBasis;
		ParametersForFillingInDecryption.Contract          = Selection.Contract;
		ParametersForFillingInDecryption.DocumentCurrency  = FillingData.Currency;
		ParametersForFillingInDecryption.Partner          = Selection.Partner;
		ParametersForFillingInDecryption.PaymentPurpose = DocumentBasis;
		
		ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(
			ParametersForFillingInDecryption,
			ARAPDetails,
			AmountToPay);
	EndIf;
	
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure
Procedure InstructionsForRedemptionOfReturnableContainersByClient(Val ReturnablePackagingRedemptionByCustomer, FillingData, AmountToPay = 0)
	
	// Fill in the data of the document header.
	Query = New Query("
	|SELECT
	|	CASE WHEN DocumentData.CashAccount <> VALUE(Catalog.CashAccounts.EmptyRef) THEN
	|		DocumentData.CashAccount.Owner
	|	WHEN DocumentData.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.CompanyBankAccount.Owner
	|	ELSE
	|		DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Counterparty.Description AS CounterpartyName_,
	|	DocumentData.Counterparty.DescriptionFull AS CounterpartyFullName,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.AmountARAP AS AmountARAP,
	|	DocumentData.AmountARAP AS Sum,
	|	DocumentData.Ref AS DocumentBasis,
	|	VALUE(Catalog.ARAPObjects.EmptyRef) AS ARAPObject,
	|
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer) AS BusinessOperation,
	|	DocumentData.CashAccount AS CashAccount,
	|	DocumentData.Currency AS Currency
	|FROM
	|	Document.ReturnablePackagingRedemptionByCustomer AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|");
	Query.SetParameter("Ref", ReturnablePackagingRedemptionByCustomer);
	
	QueryResult = Query.Execute();
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult.Select();
	If Selection.Next() Then
		
		FillPropertyValues(FillingData, Selection);
		
		If Not IsBlankString(Selection.CounterpartyFullName) Then
			FillingData.Insert("ReceivedFrom", Selection.CounterpartyFullName);
		Else
			FillingData.Insert("ReceivedFrom", Selection.CounterpartyName_);
		EndIf;
		
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(
			Enums.PaymentForms.CashAccountPayment_,
			FillingData);
		
		ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
		ParametersForFillingInDecryption.SalesOrder     = ReturnablePackagingRedemptionByCustomer;
		ParametersForFillingInDecryption.Contract          = Selection.Contract;
		ParametersForFillingInDecryption.DocumentCurrency  = FillingData.Currency;
		ParametersForFillingInDecryption.Partner          = Selection.Partner;
		ParametersForFillingInDecryption.PaymentPurpose = ReturnablePackagingRedemptionByCustomer;
		
		ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(
			ParametersForFillingInDecryption,
			ARAPDetails,
			AmountToPay);
	EndIf;
	
	// Filling in the amount of the document header
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure

Procedure InstructionsForReturningGoodsToSupplier(Val DocumentBasis, FillingData)
	
	Query = New Query(
	"SELECT
	|	
	|	CASE WHEN DocumentData.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.CompanyBankAccount.Owner
	|	ELSE
	|		DocumentData.Organization
	|	END AS Organization,
	|	
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Counterparty.Description AS CounterpartyName_,
	|	DocumentData.Counterparty.DescriptionFull AS ReceivedFrom,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.DocumentAmount AS Sum,
	|	DocumentData.Ref AS DocumentBasis,
	|	VALUE(Enum.BusinessTransactions.RefundFromVendor) AS BusinessOperation,
	|	DocumentData.Currency AS Currency,
	|	UNDEFINED AS CashAccount,
	|	DocumentData.CompensationMethod AS CompensationMethod
	|FROM
	|	Document.ReturnOfGoodsToVendor AS DocumentData
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
	If Selection.Next() Then
		FillPropertyValues(FillingData, Selection);
		If IsBlankString(FillingData.ReceivedFrom) Then
			FillingData.ReceivedFrom = Selection.CounterpartyName_;
		EndIf;
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(Enums.PaymentForms.CashAccountPayment_, FillingData);
		
		ARAPObjects = New Array;
		If Selection.CompensationMethod = Enums.CompensationMethodsForReturnsOfGoods.ReturnCash Then
			ARAPObjects.Add(DocumentBasis);
		Else
			ARAPObjects.Add(Undefined);
		EndIf;
		ARAPObjects.Add(Selection.Contract);
		
		Query = New Query("
		|SELECT 
		|	ARAPObjects.Ref AS ARAPObject
		|INTO TTCalculationObjects_
		|FROM Catalog.ARAPObjects AS ARAPObjects
		|WHERE ARAPObjects.Object IN (&Objects)
		|;
		|SELECT
		|	VendorsARAPAccounting.ARAPObject AS ARAPObject,
		|	VendorsARAPAccounting.Currency AS ARAPCurrency,
		|	VendorsARAPAccounting.SumBalance AS AmountARAP
		|FROM
		|	AccumulationRegister.VendorsARAPAccounting.Balance(,
		|		ARAPObject IN (SELECT ARAPObject FROM TTCalculationObjects_)
		|	) AS VendorsARAPAccounting
		|WHERE
		|	VendorsARAPAccounting.SumBalance > 0
		|");
		
		Query.SetParameter("Objects", ARAPObjects);
		
		SampleByCalculation = Query.Execute().Select();
		If SampleByCalculation.Next() Then
			NewRow = ARAPDetails.Add();
			FillPropertyValues(NewRow, SampleByCalculation);
			NewRow.Partner = FillingData.Partner;
			NewRow.PaymentPurpose = FillingData.DocumentBasis;
			
			Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
								FillingData.Currency,
								SampleByCalculation.ARAPCurrency,
								CurrentSessionDate(),
								FillingData.Organization);
			
			LineAmount_ = ?(Coefficients.ConversionRateToSettlementCurrency <> 0, NewRow.AmountARAP / Coefficients.ConversionRateToSettlementCurrency, 0);
			If LineAmount_ <= FillingData.Sum Then
				NewRow.Sum = LineAmount_;
			Else
				NewRow.Sum = FillingData.Sum;
				NewRow.AmountARAP = 0;
			EndIf;
		Else
			NewRow = ARAPDetails.Add();
			NewRow.PaymentPurpose = FillingData.DocumentBasis;
			NewRow.ARAPObject = ARAPObjectsServer.GetCalculationObjectFromLink(FillingData.DocumentBasis);
			NewRow.Partner = FillingData.Partner;
			NewRow.Sum = FillingData.Sum;
			
			NewRow.CashFlowItem =
				Catalogs.CashFlowReportItems.CashFlowItemForBusinessTransaction(Selection.BusinessOperation);
		EndIf;
		
		CashServer.FillInNDSInDecryption(ARAPDetails,
			CashServer.TranscriptOfVATPayment(Selection.Organization, CurrentSessionDate(), Selection.Currency, ARAPDetails.UnloadColumn("ARAPObject"), False));
	EndIf;
	
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure

Procedure FillInUnderCounterpartySAgreement(Val Contract, FillingData, AmountToPay = 0)
	
	Query = New Query("
	|SELECT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Counterparty.Description AS CounterpartyName_,
	|	DocumentData.Counterparty.DescriptionFull AS ReceivedFrom,
	|	DocumentData.Ref AS PaymentPurpose,
	|	DocumentData.Ref AS Contract,
	|	DocumentData.Ref AS SalesOrder,
	|	&ARAPObject AS ARAPObject,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.ContractType AS ContractType,
	|	DocumentData.Ref AS DocumentBasis,
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer) AS BusinessOperation,
	|	DocumentData.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	DocumentData.CashFlowItem AS CashFlowItem,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.Department AS Department,
	|	DocumentData.ARAPCurrency AS Currency,
	|	DocumentData.ARAPCurrency AS DocumentCurrency
	|
	|FROM
	|	Catalog.CounterpartyContracts AS DocumentData
	|	
	|WHERE
	|	DocumentData.Ref = &Ref
	|");
	
	Query.SetParameter("Ref", Contract);
	Query.SetParameter("ARAPObject", ARAPObjectsServer.GetCalculationObjectFromLink(Contract));
	
	QueryResult = Query.Execute();
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult.Select();
	If Selection.Next() Then
		
		If Not (Selection.ContractType = Enums.ContractTypes.WithCustomer
			Or Selection.ContractType = Enums.ContractTypes.WithConsignee
			Or Selection.ContractType = Enums.ContractTypes.TransferToRental
			Or Selection.ContractType = Enums.ContractTypes.Sublease
			Or Selection.ContractType = Enums.ContractTypes.CustomerInvoiceOutsourcedSale) Then
			Raise CashServer.TextAboutExclusionOfPaymentUnderContract(
				Metadata().Synonym,
				Selection.ContractType);
		EndIf;
		
		FillPropertyValues(FillingData, Selection);
		If IsBlankString(FillingData.ReceivedFrom) Then
			FillingData.ReceivedFrom = Selection.CounterpartyName_;
		EndIf;
		
		If Not FillingData.Property("CashAccount") Then
			FillingData.Insert("CashAccount");
		EndIf;
		
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(Enums.PaymentForms.CashAccountPayment_, FillingData);
		
		If ValueIsFilled(Selection.ARAPObject) Then
			ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
			ParametersForFillingInDecryption.SalesOrder     = FillingData.SalesOrder;
			ParametersForFillingInDecryption.Contract          = FillingData.Contract;
			ParametersForFillingInDecryption.DocumentCurrency  = FillingData.Currency;
			ParametersForFillingInDecryption.Partner          = FillingData.Partner;
			ParametersForFillingInDecryption.PaymentPurpose = FillingData.PaymentPurpose;
		
			ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(
				ParametersForFillingInDecryption,
				ARAPDetails,
				AmountToPay);
		Else
			DecryptionString = ARAPDetails.Add();
			FillPropertyValues(DecryptionString,Selection);
		EndIf;
	EndIf;
	
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure

Procedure FillInReportOfCommissionAgent(Val DocumentBasis, FillingData, AmountToPay = 0)
	
	Query = New Query(
	"SELECT
	|	
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Counterparty.Description AS CounterpartyName_,
	|	DocumentData.Counterparty.DescriptionFull AS CounterpartyFullName,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.DocumentAmount AS Sum,
	|	DocumentData.CommissionAmount AS CommissionAmount,
	|	DocumentData.Ref AS DocumentBasis,
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer) AS BusinessOperation,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.CashAccount AS CashAccount
	|FROM
	|	Document.ConsignmentReportFromCustomer AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|");
	
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult.Select();
	If Selection.Next() Then
		FillPropertyValues(FillingData, Selection);
		
		If Not IsBlankString(Selection.CounterpartyFullName) Then
			FillingData.Insert("ReceivedFrom", Selection.CounterpartyFullName);
		Else
			FillingData.Insert("ReceivedFrom", Selection.CounterpartyName_);
		EndIf;
		
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(
			Enums.PaymentForms.CashAccountPayment_,
			FillingData);
		
		ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
		ParametersForFillingInDecryption.SalesOrder     = DocumentBasis;
		ParametersForFillingInDecryption.Contract          = Selection.Contract;
		ParametersForFillingInDecryption.DocumentCurrency  = FillingData.Currency;
		ParametersForFillingInDecryption.Partner          = Selection.Partner;
		ParametersForFillingInDecryption.PaymentPurpose = DocumentBasis;
		
		If Selection.CommissionAmount >= 0 Then
			ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(
				ParametersForFillingInDecryption, ARAPDetails, AmountToPay);
		Else
			ARAPObjects = New Array;
			ARAPObjects.Add(DocumentBasis);
			ARAPObjects.Add(Selection.Contract);
			
			ARAPAccountingARAPDetailsFillingIn.FillInDecryptionOfRefundPaymentToSupplier(
				ARAPObjects, Selection.Organization, Selection.Currency, -Selection.CommissionAmount, Selection.Partner, ARAPDetails);
		EndIf;
	EndIf;
	
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure

Procedure FillInReportToCommittee(Val ConsignmentReportToVendor, FillingData, AmountToPay = 0)
	
	Query = New Query(
	"SELECT
	|	CASE WHEN DocumentData.CashAccount <> VALUE(Catalog.CashAccounts.EmptyRef) THEN
	|		DocumentData.CashAccount.Owner
	|	ELSE
	|		DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Counterparty.Description AS CounterpartyName_,
	|	DocumentData.Counterparty.DescriptionFull AS CounterpartyFullName,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.CommissionAmount AS Sum,
	|	DocumentData.Ref AS DocumentBasis,
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer) AS BusinessOperation,
	|	DocumentData.CashAccount AS CashAccount,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.KeepCommissionFee AS KeepCommissionFee
	|FROM
	|	Document.ConsignmentReportToVendor AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|");
	
	Query.SetParameter("Ref", ConsignmentReportToVendor);
	
	QueryResult = Query.Execute();
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult.Select();
	If Selection.Next() Then
		
		If Selection.KeepCommissionFee Then
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không cần nhập phiếu thu trên cơ sở chứng từ %1, vì trong đó đã giữ lại hoa hồng';
					|ru = 'Не требуется вводить приходный кассовый ордер на основании документа %1, поскольку в нем удержано вознаграждение';
					|en = 'You do not have to enter ""Incoming payment — Cash account"" based on document %1 as remuneration is deducted in it'; fa = 'You do not have to enter ""Incoming payment — Cash account"" based on document %1 as remuneration is deducted in it';
					|it = 'Non è necessario inserire la ricevuta di cassa in base al documento %1, perché nel documento è trattenuto il compenso';
					|pl = 'Nie trzeba prowadzać asygnaty kasowej przychodowej na podstawie dokumentu %1, ponieważ w nim jest potrącono wynagrodzenie';
					|tr = '%1 belgesine dayalı olarak gelen ödeme - banka hesabı girmenize gerek yoktur, çünkü ikramiye bu belgeden düşülür.'"),
				ConsignmentReportToVendor);
			Raise Text;
		EndIf;
		
		FillPropertyValues(FillingData, Selection);
		
		If Not IsBlankString(Selection.CounterpartyFullName) Then
			FillingData.Insert("ReceivedFrom", Selection.CounterpartyFullName);
		Else
			FillingData.Insert("ReceivedFrom", Selection.CounterpartyName_);
		EndIf;
		
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(
			Enums.PaymentForms.CashAccountPayment_,
			FillingData);
		
		ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
		ParametersForFillingInDecryption.SalesOrder     = ConsignmentReportToVendor;
		ParametersForFillingInDecryption.Contract          = Selection.Contract;
		ParametersForFillingInDecryption.DocumentCurrency  = FillingData.Currency;
		ParametersForFillingInDecryption.Partner          = Selection.Partner;
		ParametersForFillingInDecryption.PaymentPurpose = ConsignmentReportToVendor;
		
		ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(
			ParametersForFillingInDecryption,
			ARAPDetails,
			AmountToPay);
	EndIf;
	
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure

Procedure InstructionsForDebitingNonCashCashTransactions(Val DocumentBasis, FillingData)
	
	Query = New Query("
	|SELECT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.CashAccountRecipient AS CashAccount,
	|	DocumentData.Currency AS Currency,
	|	UNDEFINED AS AdvanceHolder,

	|	DocumentData.CashFlowItem AS CashFlowItem,
	|	DocumentData.DocumentAmount AS Sum,
	|	DocumentData.Ref AS DocumentBasis,
	|	DocumentData.BankAccount AS BankAccount,
	|	VALUE(Enum.BusinessTransactions.CashCollectionFromBank) AS BusinessOperation
	|FROM
	|	Document.BankAccountIssue AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.WithdrawalFromBankAccount)
	|	
	|UNION ALL
	|	
	|SELECT
	|	
	|	DocumentData.Organization AS Organization,
	|	UNDEFINED AS CashAccount,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.AdvanceHolder AS AdvanceHolder,
	|	UNDEFINED AS CashFlowItem,
	|	ISNULL(AdvanceHolderCash.SumBalance, 0) AS Sum,
	|	DocumentData.Ref AS DocumentBasis,
	|	UNDEFINED AS BankAccount,
	|	VALUE(Enum.BusinessTransactions.CashReturnByAdvanceHolder) AS BusinessOperation
	|FROM
	|	Document.BankAccountIssue AS DocumentData
	|
	|	LEFT JOIN
	|		AccumulationRegister.AdvanceHolderCash.Balance(,
	|		) AS AdvanceHolderCash
	|	ON
	|		AdvanceHolderCash.Organization = DocumentData.Organization
	|		AND AdvanceHolderCash.AdvanceHolder = DocumentData.AdvanceHolder
	|		AND AdvanceHolderCash.Currency = DocumentData.Currency
	|	
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
	|	
	|");
	
	Query.SetParameter("Ref", DocumentBasis);
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhập phiếu thu trên cơ sở chứng từ %1
				|với giao dịch kinh tế %2';
				|ru = 'Не требуется вводить приходный кассовый ордер на основании документа %1
				|с хозяйственной операцией %2';
				|en = 'You do not have to enter ""Incoming payment — Cash account"" based on document %1 
				| business transaction %2'; fa = 'You do not have to enter ""Incoming payment — Cash account"" based on document %1 
				| business transaction %2';
				|it = 'Non è necessario inserire la ricevuta di cassa in base al documento %1
				|con la transazione commerciale %2';
				|pl = 'Nie trzeba prowadzać asygnaty kasowej przychodowej na podstawie dokumentu %1
				|z operacją gospodarczą %2';
				|tr = '%1 belgesine göre gelen ödeme - kasa hesabı girmek gerekli değildir 
				|ticari işleme sahip%2'"),
			DocumentBasis,
			Common.ObjectAttributeValue(DocumentBasis, "BusinessOperation"));
		Raise Text;
	Else
		
		FillingData = New Structure;
		For Each Column In QueryResult.Columns Do
			FillingData.Insert(Column.Name);
		EndDo;
		
		Selection = QueryResult.Select();
		If Selection.Next() Then
			
			ExcludedFields = "";
			If Selection.BusinessOperation = Enums.BusinessTransactions.CashReturnByAdvanceHolder Then
				ExcludedFields = "CashAccount";
			EndIf;
			
			FillPropertyValues(FillingData, Selection, , ExcludedFields);
			
			CashServer.FillInDetailsOfDocumentOnFormOfPayment(Enums.PaymentForms.CashAccountPayment_, FillingData);
		EndIf;
		
		DocumentAmount = FillingData.Sum;
	EndIf;
	
EndProcedure

Procedure InstructionsForTransferOfGoods(Val DocumentBasis, FillingData, AmountToPay = 0)
	
	Query = New Query("
	|SELECT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.CompanyRecipient AS Partner,
	|	DocumentData.CompanyRecipient AS Counterparty,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS CashAccount,
	|	UNDEFINED AS CashAccountIssuer,
	|
	|	DocumentData.Currency AS Currency,
	|	&Ref AS DocumentBasis,
	|	
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromOtherCompany) AS BusinessOperation
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
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS CashAccount,
	|	UNDEFINED AS CashAccountIssuer,
	|
	|	DocumentData.Currency AS Currency,
	|	&Ref AS DocumentBasis,
	|	
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer) AS BusinessOperation
	|FROM
	|	Document.CustomerInvoiceIntercompany AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany)
	|	AND DocumentData.ARAPAccountingViaSeparateCounterparty
	|");
	
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult.Select();
	If Selection.Next() Then
		FillPropertyValues(FillingData, Selection);
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(Enums.PaymentForms.CashAccountPayment_, FillingData);
		
		ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
		ParametersForFillingInDecryption.SalesOrder     = DocumentBasis;
		ParametersForFillingInDecryption.Contract          = Selection.Contract;
		ParametersForFillingInDecryption.DocumentCurrency  = FillingData.Currency;
		ParametersForFillingInDecryption.Partner          = Selection.Partner;
		ParametersForFillingInDecryption.PaymentPurpose = DocumentBasis;
		
		ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(
			ParametersForFillingInDecryption,
			ARAPDetails,
			AmountToPay);
	EndIf;
	
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure

Procedure FillInCommissionReport(Val DocumentBasis, FillingData, AmountToPay = 0)
	
	Query = New Query("
	|SELECT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Consignee AS Partner,
	|	UNDEFINED AS Counterparty,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS CashAccount,
	|	UNDEFINED AS CashAccountIssuer,
	|	DocumentData.Currency AS Currency,
	|	&Ref AS DocumentBasis,
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromOtherCompany) AS BusinessOperation
	|FROM
	|	Document.CommissionReportIntercompany AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND NOT DocumentData.ARAPAccountingViaSeparateCounterparty
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS CashAccount,
	|	UNDEFINED AS CashAccountIssuer,
	|	DocumentData.Currency AS Currency,
	|	&Ref AS DocumentBasis,
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer) AS BusinessOperation
	|FROM
	|	Document.CommissionReportIntercompany AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.ARAPAccountingViaSeparateCounterparty
	|");
	
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult.Select();
	If Selection.Next() Then
		FillPropertyValues(FillingData, Selection);
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(Enums.PaymentForms.CashAccountPayment_, FillingData);
		
		ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
		ParametersForFillingInDecryption.SalesOrder     = DocumentBasis;
		ParametersForFillingInDecryption.Contract          = Selection.Contract;
		ParametersForFillingInDecryption.DocumentCurrency  = FillingData.Currency;
		ParametersForFillingInDecryption.Partner          = Selection.Partner;
		ParametersForFillingInDecryption.PaymentPurpose = DocumentBasis;
		
		ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(
			ParametersForFillingInDecryption,
			ARAPDetails,
			AmountToPay);
	EndIf;
	
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure

Procedure FillByArrayOfBases(FillingData, ArrayOfBases)
	
	CashServer.FillInDetailsOfDocumentOnFormOfPayment(Enums.PaymentForms.CashAccountPayment_, FillingData);
	
	If ArrayOfBases.Count() Then
		
		If Metadata.DefinedTypes.ARAPObjectWithVendor.Type.ContainsType(TypeOf(ArrayOfBases[0].PaymentObject))
			Or Metadata.DefinedTypes.ARAPObjectWithCustomer.Type.ContainsType(TypeOf(ArrayOfBases[0].PaymentObject)) Then
			
			For Each BaseString In ArrayOfBases Do
				
				ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
				FillPropertyValues(ParametersForFillingInDecryption, BaseString);
				ParametersForFillingInDecryption.DocumentCurrency = FillingData.Currency;
				
				If TypeOf(ParametersForFillingInDecryption.PaymentPurpose) <> Type("DocumentRef.ReturnOfGoodsToVendor") Then
					ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(
						ParametersForFillingInDecryption,
						ARAPDetails,
						BaseString.AmountToPay);
				Else
					InstructionsForReturningGoodsToSupplier(ParametersForFillingInDecryption.PaymentPurpose, FillingData);
				EndIf;
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
			FillingData.Insert("Application",
				TMCommonUse.GetDocumentPresentation(FillingData.DocumentBasis,
					ObjectsPrefixesClientServer.NumberForPrinting(AttributesValues.Number),
						AttributesValues.Date));
		EndIf;
		
		FillingData.Delete("Basis");
		
	EndIf;
	
	If FillingData.Property("Counterparty")
		And TypeOf(FillingData.Counterparty) = Type("CatalogRef.Counterparties") Then
		
		CounterpartyDetails_ = Common.ObjectAttributesValues(FillingData.Counterparty, "Description, DescriptionFull");
		
		If Not IsBlankString(CounterpartyDetails_.DescriptionFull) Then
			FillingData.Insert("ReceivedFrom", CounterpartyDetails_.DescriptionFull);
		Else
			FillingData.Insert("ReceivedFrom", CounterpartyDetails_.Description);
		EndIf;
	EndIf;
	
EndProcedure

Procedure InstructionsForRedemptionOfGoodsByCustodian(Val DocumentBasis, FillingData, AmountToPay = 0)
	
	Query = New Query;
	Query.SetParameter("Ref", DocumentBasis);
	Query.Text =
	"SELECT
	|	CASE
	|		WHEN DocumentData.CashAccount <> VALUE(Catalog.CashAccounts.EmptyRef)
	|			THEN DocumentData.CashAccount.Owner
	|		WHEN DocumentData.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
	|			THEN DocumentData.CompanyBankAccount.Owner
	|		ELSE DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Counterparty.Description AS CounterpartyName_,
	|	DocumentData.Counterparty.DescriptionFull AS CounterpartyFullName,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.AmountARAP AS AmountARAP,
	|	DocumentData.AmountARAP AS Sum,
	|	DocumentData.Ref AS DocumentBasis,
	|	VALUE(Catalog.ARAPObjects.EmptyRef) AS OrderDocument,
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer) AS BusinessOperation,
	|	DocumentData.CashAccount AS CashAccount,
	|	DocumentData.Currency AS Currency
	|FROM
	|	Document.RedemptionOfGoodsByCustodian AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	QueryResult = Query.Execute();
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult.Select();
	If Selection.Next() Then
		
		FillPropertyValues(FillingData, Selection);
		
		If Not IsBlankString(Selection.CounterpartyFullName) Then
			FillingData.Insert("ReceivedFrom", Selection.CounterpartyFullName);
		Else
			FillingData.Insert("ReceivedFrom", Selection.CounterpartyName_);
		EndIf;
		
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(
			Enums.PaymentForms.CashAccountPayment_,
			FillingData);
		
		ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
		ParametersForFillingInDecryption.SalesOrder = DocumentBasis;
		ParametersForFillingInDecryption.Contract = Selection.Contract;
		ParametersForFillingInDecryption.DocumentCurrency = FillingData.Currency;
		ParametersForFillingInDecryption.Partner = Selection.Partner;
		ParametersForFillingInDecryption.PaymentPurpose = DocumentBasis;
		
		ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(
			ParametersForFillingInDecryption,
			ARAPDetails,
			AmountToPay);
		
	EndIf;
	
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure

Procedure FillInReportToPurchasingCommittee(Val PurchasingReportToConsignorPrincipal, FillingData, AmountToPay = 0)
	
	Query = New Query(
	"SELECT
	|	CASE WHEN DocumentData.CashAccount <> VALUE(Catalog.CashAccounts.EmptyRef) THEN
	|		DocumentData.CashAccount.Owner
	|	ELSE
	|		DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Counterparty.Description AS CounterpartyName_,
	|	DocumentData.Counterparty.DescriptionFull AS CounterpartyFullName,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.CommissionAmount AS Sum,
	|	DocumentData.Ref AS DocumentBasis,
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer) AS BusinessOperation,
	|	DocumentData.CashAccount AS CashAccount,
	|	DocumentData.Currency AS Currency,
	|	CASE WHEN DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts) THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS SettlementUnderContracts
	|FROM
	|	Document.PurchasingReportToConsignorPrincipal AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|");
	
	Query.SetParameter("Ref", PurchasingReportToConsignorPrincipal);
	
	QueryResult = Query.Execute();
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult.Select();
	If Selection.Next() Then
				
		FillPropertyValues(FillingData, Selection);
		
		If Not IsBlankString(Selection.CounterpartyFullName) Then
			FillingData.Insert("ReceivedFrom", Selection.CounterpartyFullName);
		Else
			FillingData.Insert("ReceivedFrom", Selection.CounterpartyName_);
		EndIf;
		
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(
			Enums.PaymentForms.CashAccountPayment_,
			FillingData);
		
		If Selection.SettlementUnderContracts Then
			
			CustomerOrders = Selection.Contract;
		Else
			Query = New Query("
			|SELECT DISTINCT
			|	GoodsTable.SalesOrder AS SalesOrder
			|FROM
			|	Document.PurchasingReportToConsignorPrincipal.Goods AS GoodsTable
			|WHERE
			|	GoodsTable.Ref = &Ref
			|	AND NOT GoodsTable.SalesOrder = VALUE(Document.SalesOrder.EmptyRef)
			|");
			Query.SetParameter("Ref", PurchasingReportToConsignorPrincipal);
			
			RequestResultForOrders = Query.Execute();
			If Not RequestResultForOrders.IsEmpty() Then
				CustomerOrders = RequestResultForOrders.Unload().UnloadColumn("SalesOrder");
				CustomerOrders.Add(PurchasingReportToConsignorPrincipal);
			Else
				CustomerOrders = PurchasingReportToConsignorPrincipal;
			EndIf;
		EndIf;
		
		ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
		ParametersForFillingInDecryption.SalesOrder     = CustomerOrders;
		ParametersForFillingInDecryption.Contract          = Selection.Contract;
		ParametersForFillingInDecryption.DocumentCurrency  = FillingData.Currency;
		ParametersForFillingInDecryption.Partner          = Selection.Partner;
		ParametersForFillingInDecryption.PaymentPurpose = PurchasingReportToConsignorPrincipal;

		If AmountToPay = 0 Then
			AmountToPay = Selection.Sum;
		EndIf;
		
		ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(
			ParametersForFillingInDecryption,
			ARAPDetails,
			AmountToPay);
	EndIf;
	
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure

Procedure FillInGiftCertificate(Val DocumentBasis, FillingData, AmountToPay = 0)

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
	If GiftCertificateDetails.ActivationStatus Then
		Text = NStr("vi = 'Chỉ hỗ trợ giao dịch này đối với phiếu quà tặng chưa kích hoạt.';
					|ru = 'Данная операция поддерживается только для не активированных подарочных сертификатов.';
					|en = 'This transaction is supported only for unactivated gift cards.'; fa = 'This transaction is supported only for unactivated gift cards.';
					|it = 'Questa operazione viene supportata solo per i buoni regalo non attivati.';
					|pl = 'Ta operacja jest obsługiwana tylko dla nie aktywowanych certyfikatów podarunkowych.';
					|tr = 'Bu işlem sadece etkinleştirilmemiş hediye kartları için desteklenir.'");
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
	
	BusinessOperation = PredefinedValue("Enum.BusinessTransactions.CashReceiptFromCustomer");
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
	NewRow.Organization = Organization;
	NewRow.Partner = Partner;
	NewRow.ARAPObject = GiftCertificateDetails.ARAPObject;
	NewRow.Sum = DocumentAmount; 
	NewRow.CashFlowItem = GiftCertificateDetails.CashFlowItemSale;
	
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

#EndRegion

#Region Initialize

Procedure InitializeDocument(FillingData = Undefined)
	
	If TypeOf(FillingData) <> Type("Structure")
		Or Not FillingData.Property("CashAccount")
		Or Not ValueIsFilled(FillingData.CashAccount) Then
		
		CashAccount = Common.CommonSettingsStorageLoad("CurrentCashAccount", "");
		If Not ValueIsFilled(CashAccount) Then
			CashAccount = Catalogs.CashAccounts.GetCheckoutByDefault(
				?(ValueIsFilled(Organization), Organization, Undefined),
				?(ValueIsFilled(Currency), Currency, Undefined));
		EndIf;
		If ValueIsFilled(CashAccount) Then
			AttributesStructure1 = Catalogs.CashAccounts.GetCheckoutDetails(CashAccount);
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
	
	If TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("DocumentAmount") Then
		DocumentAmount = FillingData.DocumentAmount;
	EndIf;
	
	If DocumentAmount <> 0 Then
		If TypeOf(FillingData) = Type("Structure")
			And FillingData.Property("Currency") Then
			Currency = FillingData.Currency;
		EndIf;
		
		IncludingVAT = CashServer.TextAmountOfVATPayment(Organization, Currency, ARAPDetails, False);
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
				AttributesStructure1 = Catalogs.CashAccounts.GetCheckoutDetails(CashAccount);
				Currency = AttributesStructure1.Currency;
			Else
				Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
			EndIf;
		EndIf;
	EndIf;
	
	If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("BankAccount") Then
		ParametersStructure = CashServer.ParametersForFillingOutOrganizationSBankAccount();
		ParametersStructure.Organization = Organization;
		ParametersStructure.Currency		= Currency;
		BankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersStructure);
	EndIf;
	
	CashServer.FillInCashFlowItem(
		ThisObject,
		FillingData,
		Enums.BusinessTransactions.CashReceiptFromCustomer);
		
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
	ParametersStructure.PaymentMethod	= Enums.PaymentForms.CashAccountPayment_;
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
#EndRegion

#Region Other

Procedure CheckBankAccount(Cancel)
	
	If BusinessOperation = Enums.BusinessTransactions.CashReceiptFromBank
		And ValueIsFilled(CashAccount)
		And ValueIsFilled(BankAccount) Then
		
		AccountAttributes = Catalogs.CompaniesBankAccounts.GetCompanySBankAccountDetails(BankAccount);
		If Organization <> AccountAttributes.Organization Then
			Text = NStr("vi = 'Doanh nghiệp theo tài khoản không tương ứng với doanh nghiệp trên chứng từ';
						|ru = 'Организация счета не соответствует организации документа';
						|en = 'The company mentioned in the account does not match the company mentioned in the document'; fa = 'The company mentioned in the account does not match the company mentioned in the document';
						|it = 'L''azienda del conto non corrisponde all''azienda del documento';
						|pl = 'Firma w rachunku nie odpowiada firmie w dokumencie';
						|tr = 'Hesabın iş yeri, belgenin iş yeri ile eşleşmiyor'");
			CommonClientServer.MessageToUser(
				Text,
				ThisObject,
				"BankAccount",
				,
				Cancel);
		EndIf;
		If Currency <> AccountAttributes.Currency Then
			Text = NStr("vi = 'Tiền tệ trong tài khoản không tương ứng với tiền tệ trong chứng từ';
						|ru = 'Валюта счета не соответствует валюте документа';
						|en = 'Account currency does not correspond to the document currency'; fa = 'Account currency does not correspond to the document currency';
						|it = 'Valuta del conto non corrisponde al valuta del documento';
						|pl = 'Waluta rachunku nie odpowiada walucie w dokumencie';
						|tr = 'Hesabın para birimi, belgenin para birimiyle eşleşmiyor'");
			CommonClientServer.MessageToUser(
				Text,
				ThisObject,
				"BankAccount",
				,
				Cancel);
		EndIf;
	EndIf;
	
EndProcedure

Procedure CheckChangesInBusinessOperations()
	
	If Not IsNew() Then
		
		Query = New Query("
		|SELECT
		|	CASE WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromAnotherCashAccount)
		|		AND DocumentData.CashAccountIssuer.CashBook = DocumentData.CashAccount.CashBook
		|	THEN
		|		TRUE
		|	ELSE
		|		FALSE
		|	END AS InternalMovement
		|FROM
		|	Document.CashAccountReceiptNote AS DocumentData
		|WHERE
		|	DocumentData.Ref = &Ref
		|");
		Query.SetParameter("Ref", Ref);
	
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			
			SenderSCashBook = Undefined;
			If TypeOf(CashAccountIssuer) = Type("CatalogRef.CashAccounts") Then
				SenderSCashBook = Common.ObjectAttributeValue(CashAccountIssuer, "CashBook");
			EndIf;
			
			InternalMovement =
				(BusinessOperation = Enums.BusinessTransactions.CashReceiptFromAnotherCashAccount)
				And SenderSCashBook = Common.ObjectAttributeValue(CashAccount, "CashBook");
			
			If Selection.InternalMovement <> InternalMovement Then
				Number = "";
			EndIf;
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
