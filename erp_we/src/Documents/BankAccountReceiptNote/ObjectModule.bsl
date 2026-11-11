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
	
	Author = Users.CurrentUser();
	
	DocBasis = Undefined;
	AmountToPay = 0;
	
	If Documents.AllRefsType().ContainsType(TypeOf(FillingData))
		Or Catalogs.AllRefsType().ContainsType(TypeOf(FillingData)) Then
		
		DocBasis = FillingData;
		FillingData = New Structure;
	EndIf;
	
	If ValueIsFilled(DocBasis) Then
		
		BasisType = TypeOf(DocBasis);
		
		If BasisType = Type("DocumentRef.SalesOrder") Then
			FillInOnTheCustomerSOrder(DocBasis, FillingData, AmountToPay);
			
		ElsIf BasisType = Type("DocumentRef.CustomerCommercialInvoice") Then
			FillInInvoiceForPaymentToClient(DocBasis, FillingData);
			
		ElsIf BasisType = Type("DocumentRef.BankAccountIssue") Then
			InstructionsForDebitingNonCashFunds(DocBasis, FillingData);
			
		ElsIf BasisType = Type("DocumentRef.CashVoucher") Then
			FillInUsingExpenseCashOrder(DocBasis, FillingData);
			
		ElsIf BasisType = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
			FillInRequestForReturnOfGoods(DocBasis, FillingData, AmountToPay);
			
		ElsIf BasisType = Type("DocumentRef.CustomerInvoice") Then
			ServicesForSaleOfGoodsServices(DocBasis, FillingData, AmountToPay);
			
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
			
		ElsIf BasisType = Type("DocumentRef.CustomerInvoiceIntercompany") Then
			InstructionsForTransferOfGoods(DocBasis, FillingData, AmountToPay);
		ElsIf BasisType = Type("DocumentRef.CommissionReportIntercompany") Then
			FillInCommissionReport(DocBasis, FillingData, AmountToPay);
			
		ElsIf BasisType = Type("CatalogRef.LoanAndDepositContracts") Then
			CashServer.FillInUnderLoanDepositAgreement(DocBasis, FillingData, ARAPDetails, True);
		
		ElsIf BasisType = Type("DocumentRef.ReportToMaterialProvider2_5") Then
			FillInReportToGiver(DocBasis, FillingData, AmountToPay);
		ElsIf BasisType = Type("DocumentRef.ConsumptionReportSubcontractingServicesDeliveredIntercompany") Then
			FillInGiverReportBetweenCompanies(DocBasis, FillingData, AmountToPay);
		ElsIf BasisType = Type("DocumentRef.MaterialProviderOrder2_5") Then
			FillInByOrderOfGiver(DocBasis, FillingData, AmountToPay);
		ElsIf BasisType = Type("DocumentRef.PurchasingReportToConsignorPrincipal") Then
			FillInReportToPurchasingCommittee(DocBasis, FillingData, AmountToPay);
			
		ElsIf BasisType = Type("CatalogRef.GiftCertificates") Then
			FillInGiftCertificate(DocBasis, FillingData, AmountToPay);

		ElsIf BasisType = Type("DocumentRef." + Metadata().Name) Then
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
		And FillingData.Property("CommissionReportIntercompany") 
		And TypeOf(FillingData.CommissionReportIntercompany) = Type("DocumentRef.CommissionReportIntercompany") Then
		
		FillInCommissionReport(FillingData.CommissionReportIntercompany, FillingData,, True);

	ElsIf TypeOf(FillingData) = Type("Structure") 
		And FillingData.Property("GiftCertificate")
		And FillingData.Property("Counterparty") Then
		FillInGiftCertificate(FillingData, FillingData, AmountToPay);
		
	ElsIf TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("Basis")
		And TypeOf(FillingData.Basis) = Type("Array") Then
		
		FillByArrayOfBases(FillingData, FillingData.Basis);
	EndIf;
	
	BankAccountReceiptNoteLocalization.Filling(ThisObject, DocBasis, FillingData, StandardProcessing);
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	If Not BasisType = Type("DocumentRef." + Metadata().Name) Then
		InitializeDocument(FillingData);
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.BankAccountReceiptNote.ItemsAndDimensionsSelectionParameters(BusinessOperation);
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	ARAPAccountingServer.Filling(ThisObject, FillingData);
	
	If Not ValueIsFilled(EmployeeResponsible) Then
		EmployeeResponsible = Users.CurrentUser();
	EndIf;
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	
	IncomingDocumentDate = "";
	IncomingDocumentNumber = "";
	BankPostingDate = "";
	ExportDate = "";
	ImportDate = "";
	ImportErrors = "";
	FormattedPurposeOfPayment = "";
	StatementData = "";
	NameOfCounterparty = "";
	ProcessedByBank = False;
	
	If PaymentDocumentType = Enums.TypesOfPaymentDocuments.CollectionOrder_2
		Or PaymentDocumentType = Enums.TypesOfPaymentDocuments.PaymentWarrant Then
		ProcessedByBank = True;
		BankPostingDate = CurrentSessionDate();
	EndIf;
	
	ARAPAccountingServer.OnCopy(ThisObject);
	
	EmployeeResponsible = Users.CurrentUser();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "ARAPDetails");
	
	BankAccountReceiptNoteLocalization.OnCopy(ThisObject, CopiedObject);
	
	Author = Users.CurrentUser();
	
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
	
	Documents.BankAccountReceiptNote.FillInNamesOfBusinessTransactionDetails(
		ThisObject, ArrayOfAllProps, ArrayOfOperationDetails);
		
	TMCommonUseClientServer.FillInArrayOfUnverifiableBankingDetails(
		ArrayOfAllProps, ArrayOfOperationDetails, NotCheckedAttributeArray);
	
	If PaymentDocumentType = Enums.TypesOfPaymentDocuments.PaymentDemand Then
		NotCheckedAttributeArray.Add("IncomingDocumentDate");
		NotCheckedAttributeArray.Add("IncomingDocumentNumber");
	EndIf;
	
	If Not ProcessedByBank Then
		NotCheckedAttributeArray.Add("BankPostingDate");
	EndIf;
	
	If FlagEDIWithBanks Then
		VerificationDetails_1 = New Structure("ARAPDetails", "IncomeItem, DimensionOfRevenue");
		AdditionalParameters = New Structure("SoftwareVerification", True);
		ChartsOfCharacteristicTypes.IncomeItems.CheckAnalystCompletion(
			ThisObject, VerificationDetails_1, NotCheckedAttributeArray, Cancel, AdditionalParameters);
		
		For Each Error In AdditionalParameters.Errors.ErrorList Do
			CashServer.AddFillInError(
				FillingErrors, Error.SeveralErrorsText);
		EndDo;
	EndIf;
	
	If ExplanationWithoutSplit Then
		NotCheckedAttributeArray.Add("ARAPDetails.Sum");
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.CashRecieptByAcquiringTransactionsPayment Then
		
		NotCheckedAttributeArray.Add("Counterparty");
		
		If Not ValueIsFilled(Counterparty) Then
			ErrorText = NStr("vi = 'Chưa điền trường ""Ngân hàng thanh toán"".';
							|ru = 'Поле ""Эквайер"" не заполнено.';
							|en = '""Acquirer"" is required.'; fa = '""Acquirer"" is required.';
							|it = 'Campo ""Aquirer"" non compilato.';
							|pl = 'Pole ""Centrum autoryzacyjne"" nie zostało wypełnione.';
							|tr = '""Alıcı banka"" alanı doldurulmadı.'");
			If FlagEDIWithBanks Then
				CashServer.AddFillInError(FillingErrors, ErrorText);
			Else
				Common.MessageToUser(ErrorText,, "Counterparty", "Object", Cancel);
			EndIf;
		EndIf;
	EndIf;
	If BusinessOperation = Enums.BusinessTransactions.LoanRepaymentByEmployee Then
		NotCheckedAttributeArray.Add("AdvanceHolder");
		
		If Not ValueIsFilled(AdvanceHolder) Then
			ErrorText = NStr("vi = 'Chưa điền trường ""Nhân viên"".';
							|ru = 'Поле ""Сотрудник"" не заполнено.';
							|en = '""Employee"" is required.'; fa = '""Employee"" is required.';
							|it = 'Il campo ""Dipendente"" non è compilato.';
							|pl = 'Pole ""Pracownik"" nie jest wypełnione.';
							|tr = '""Çalışan"" alanı doldurulmamış.'");
			If FlagEDIWithBanks Then
				CashServer.AddFillInError(FillingErrors, ErrorText);
			Else
				Common.MessageToUser(ErrorText,, "AdvanceHolder", "Object", Cancel);
			EndIf;
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
				
				If Not FlagEDIWithBanks Then
					
					If ExplanationWithoutSplit Then
						FieldName = "Items.ARAPDetails.CurrentData.ARAPDocumentForLease";
						DataKey = Undefined;
					Else
						FieldName = CommonClientServer.PathToTabularSection(
							"ARAPDetails", DecryptionString.LineNumber, "ARAPDocumentForLease");
						DataKey = ThisObject;
					EndIf;
					
					Common.MessageToUser(ErrorText, DataKey, FieldName,, Cancel);
				Else
					CashServer.AddFillInError(FillingErrors, ErrorText);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	If Not FlagEDIWithBanks Then
		CashServer.CheckPartnerContent(
			ThisObject, BusinessOperation, NotCheckedAttributeArray, ExplanationWithoutSplit, Cancel);
		CashServer.CheckCompletionOfAmountNotCredited(ThisObject, Cancel);
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
	
	If ValueIsFilled(SenderBankAccount)
		And ArrayOfOperationDetails.Find("SenderBankAccount") <> Undefined Then
		CashServer.CheckAvailabilityOfBankAccount(
			ThisObject, SenderBankAccount, "SenderBankAccount", FlagEDIWithBanks, FillingErrors);
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.BankAccountReceiptNote.ItemsAndDimensionsSelectionParameters(
		BusinessOperation, CheckCompletionOfCommissionArticle);
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
		
	CashServer.CheckCompletionOfPaymentDecryption(
		ThisObject, DocumentAmount, BusinessOperation, Cancel, FlagEDIWithBanks, FillingErrors);
	
	CashServer.CheckConversionCurrency(ThisObject, Cancel, FlagEDIWithBanks, FillingErrors);
	
	BankAccountReceiptNoteLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
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
	// Clear the table part if it should not be filled in.
	ArrayOfOperationDetails = New Array;
	Documents.BankAccountReceiptNote.FillInNamesOfBusinessTransactionDetails(
		ThisObject, Undefined, ArrayOfOperationDetails);
	
	If ARAPDetails.Count() > 0
		And (ArrayOfOperationDetails.Find("ARAPDetails") = Undefined
			Or Documents.BankAccountReceiptNote.ArrayOfOperationsWithoutPaymentDecryption().Find(BusinessOperation) <> Undefined
			) Then
		ARAPDetails.Clear();
	EndIf;
		
	If Not ValueIsFilled(Number) Then
		SetNewNumber();
	EndIf;
	
	CashServer.BeforeWrite(ThisObject, Cancel);
	ARAPAccountingServer.BeforeWrite(ThisObject, Cancel, WriteMode);
	
	If WriteMode = DocumentWriteMode.Posting Then
		If (BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer
			Or BusinessOperation = Enums.BusinessTransactions.RefundFromVendor
			Or BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany
			Or BusinessOperation = Enums.BusinessTransactions.RefundFromAnotherCompany
			Or BusinessOperation = Enums.BusinessTransactions.CashReceiptFromLoansRepayment
			Or BusinessOperation = Enums.BusinessTransactions.CashReceiptUnderDeposits
			Or BusinessOperation = Enums.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty
			Or BusinessOperation = Enums.BusinessTransactions.RefundFromLessor
			) Then
			ARAPAccountingServer.FillInAmountOfSettlementsInTablePart(
				Currency, ?(ProcessedByBank, BankPostingDate, Date), ARAPDetails, Organization);
		EndIf;
		
		CashServer.FillInOrganizationInTableSection(ARAPDetails, Organization, BusinessOperation);
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "ARAPDetails");
	
	// We will clear the details of the document that are not used for the business operation
	ArrayOfAllProps = New Array;
	ArrayOfOperationDetails = New Array;
	UnusedAttributes = New Array;
	Documents.BankAccountReceiptNote.FillInNamesOfBusinessTransactionDetails(
		ThisObject, ArrayOfAllProps, ArrayOfOperationDetails);
	
	If Not KeepRecordsOfCommissionInARAPAccounting Then
		UnusedAttributes.Add("CommissionARAPObject");
	EndIf;
		
	For Each UnusedProps In UnusedAttributes Do
		AttributeToDelete = ArrayOfOperationDetails.Find(UnusedProps);
		If AttributeToDelete <> Undefined Then
			ArrayOfOperationDetails.Delete(AttributeToDelete);
		EndIf;
	EndDo;
		
	CashServer.ClearUnusedProps(ThisObject, ArrayOfAllProps, ArrayOfOperationDetails);
	
	If Not GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities") And Not ValueIsFilled(AssetAndLiabilityItem) Then
		AssetAndLiabilityItem = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceOtherLiabilities;
	EndIf;
	
	FormattedPurposeOfPayment = CashServer.FormatPaymentPurpose(PaymentPurposes);
	
	If WriteMode = DocumentWriteMode.Posting Then
		ImportErrors = "";
	EndIf;
	
	//Setting up accounting accounts
	GLAccountSettingsServer.BeforeWrite(ThisObject,
		Documents.BankAccountReceiptNote.AccountingAccountSettings_(BusinessOperation, TaxType));
	ItemsAndDimensionsSelectionParameters = Documents.BankAccountReceiptNote.ItemsAndDimensionsSelectionParameters(
		BusinessOperation, RecordCommission And Not KeepRecordsOfCommissionInARAPAccounting);
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	If Not ValueIsFilled(Author) And IsNew() Then
		Author = Users.CurrentUser();
	EndIf;
	
	BankAccountReceiptNoteLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	If PaymentDocumentType = Enums.TypesOfPaymentDocuments.PaymentDemand
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
	
	BankAccountReceiptNoteLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	BankAccountReceiptNoteLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	BankAccountReceiptNoteLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region FillType

Procedure FillInOnTheCustomerSOrder(Val DocumentBasis, FillingData, AmountToPay = 0)
	
	// Fill in the data of the document header.
	QueryText = "
	|SELECT
	|	CASE WHEN DocumentData.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.BankAccount.Owner
	|	ELSE
	|		DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	CASE WHEN DocumentData.Contract.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts) THEN
	|		DocumentData.Contract.CashFlowItem
	|	ELSE
	|		CASE WHEN ISNULL(DocumentData.Contract.CashFlowItem, VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef) THEN
	|			DocumentData.Terms.CashFlowItem
	|		ELSE
	|			DocumentData.Contract.CashFlowItem
	|		END
	|	END AS CashFlowItem,
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer) AS BusinessOperation,
	|	DocumentData.BankAccount AS BankAccount,
	|
	|	CASE WHEN DocumentData.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.BankAccount.CashCurrency
	|	ELSE
	|		DocumentData.Currency
	|	END AS Currency
	|FROM
	|	Document.SalesOrder AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
	|	AND DocumentData.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)
	|";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhập thu tiền vào tài khoản ngân hàng trên cơ sở chứng từ %1';
				|ru = 'Не требуется вводить поступление безналичных денежных средств на основании документа %1';
				|en = 'It is not required to enter ""Incoming payment — Bank account"" based on document %1'; fa = 'It is not required to enter ""Incoming payment — Bank account"" based on document %1';
				|it = 'Non è necessario immettere l''entrata dei mezzi monetari cashless in base al documento %1';
				|pl = 'Nie trzeba wprowadzać dopływ bezgotówkowych środków pieniężnych na podstawie dokumentu %1';
				|tr = '%1 belgeye dayalı olarak gelen ödeme - banka hesabı girilmesi gerekli değildir.'"),
			DocumentBasis);
		Raise Text;
	Else
		For Each Column In QueryResult.Columns Do
			FillingData.Insert(Column.Name);
		EndDo;
		
		Selection = QueryResult.Select();
		Selection.Next();
		FillPropertyValues(FillingData, Selection);
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(Enums.PaymentForms.BankAccountPayment, FillingData);
		CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(
			FillingData.Counterparty,
			FillingData.Currency,
			FillingData.BankAccount);
		
		ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
		ParametersForFillingInDecryption.SalesOrder     = DocumentBasis;
		ParametersForFillingInDecryption.Contract          = Selection.Contract;
		ParametersForFillingInDecryption.DocumentCurrency  = FillingData.Currency;
		ParametersForFillingInDecryption.Partner          = Selection.Partner;
		ParametersForFillingInDecryption.PaymentPurpose = DocumentBasis;
		ParametersForFillingInDecryption.CashFlowItem = Selection.CashFlowItem;
		
		ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(
			ParametersForFillingInDecryption,
			ARAPDetails,
			AmountToPay);
		
	EndIf;
	
	// Filling in the amount of the document header
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure

Procedure FillInByOrderOfGiver(Val DocumentBasis, FillingData, AmountToPay = 0)
	
	// Fill in the data of the document header.
	QueryText = "
	|SELECT
	|	CASE
	|		WHEN DocumentData.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
	|			THEN DocumentData.BankAccount.Owner
	|		ELSE DocumentData.Organization
	|	END																	AS Organization,
	|	DocumentData.Partner													AS Partner,
	|	DocumentData.Counterparty												AS Counterparty,
	|	DocumentData.Contract													AS Contract,
	|	DocumentData.Contract.CashFlowItem					AS CashFlowItem,
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer)	AS BusinessOperation,
	|	DocumentData.BankAccount											AS BankAccount,
	|	CASE
	|		WHEN DocumentData.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
	|			THEN DocumentData.BankAccount.CashCurrency
	|		ELSE DocumentData.Currency
	|	END																	AS Currency
	|
	|FROM
	|	Document.MaterialProviderOrder2_5 AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)
	|";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhập thu tiền vào tài khoản ngân hàng trên cơ sở chứng từ %1';
				|ru = 'Не требуется вводить поступление безналичных денежных средств на основании документа %1';
				|en = 'It is not required to enter ""Incoming payment — Bank account"" based on document %1'; fa = 'It is not required to enter ""Incoming payment — Bank account"" based on document %1';
				|it = 'Non è necessario immettere l''entrata dei mezzi monetari cashless in base al documento %1';
				|pl = 'Nie trzeba wprowadzać dopływ bezgotówkowych środków pieniężnych na podstawie dokumentu %1';
				|tr = '%1 belgeye dayalı olarak gelen ödeme - banka hesabı girilmesi gerekli değildir.'"),
			DocumentBasis);
		Raise Text;
		
	Else
		
		For Each Column In QueryResult.Columns Do
			FillingData.Insert(Column.Name);
		EndDo;
		
		Selection = QueryResult.Select();
		Selection.Next();
		FillPropertyValues(FillingData, Selection);
		
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(Enums.PaymentForms.BankAccountPayment, FillingData);
		
		CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(
			FillingData.Counterparty,
			FillingData.Currency);
		
		ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
		ParametersForFillingInDecryption.SalesOrder     = DocumentBasis;
		ParametersForFillingInDecryption.Contract          = Selection.Contract;
		ParametersForFillingInDecryption.DocumentCurrency  = FillingData.Currency;
		ParametersForFillingInDecryption.Partner          = Selection.Partner;
		ParametersForFillingInDecryption.PaymentPurpose = DocumentBasis;
		ParametersForFillingInDecryption.CashFlowItem = Selection.CashFlowItem;
		
		ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(
			ParametersForFillingInDecryption,
			ARAPDetails,
			AmountToPay);
		
	EndIf;
	
	// Filling in the amount of the document header
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure

Procedure FillInReportToGiver(Val DocumentBasis, FillingData, AmountToPay = 0)
	
	// Fill in the data of the document header.
	Query = New Query(
	"SELECT
	|	CASE
	|		WHEN DocumentData.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
	|			THEN DocumentData.CompanyBankAccount.Owner
	|		ELSE DocumentData.Organization
	|	END                                     AS Organization,
	|	
	|	DocumentData.Partner                   AS Partner,
	|	DocumentData.Counterparty                AS Counterparty,
	|	DocumentData.Contract                   AS Contract,
	|	DocumentData.Contract.CashFlowItem AS CashFlowItem,
	|	DocumentData.ARAPObjectSettings           AS ARAPObjectSettings,
	|	DocumentData.ReportOnOrders            AS ReportOnOrders,
	|	DocumentData.DocumentAmount            AS Sum,
	|	DocumentData.Ref                    AS DocumentBasis,
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer) AS BusinessOperation,
	|	DocumentData.Currency                    AS Currency,
	|	DocumentData.CompanyBankAccount AS BankAccount
	|FROM
	|	Document.ReportToMaterialProvider2_5 AS DocumentData
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
		
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(Enums.PaymentForms.BankAccountPayment, FillingData);
		
		CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(
			FillingData.Counterparty, FillingData.Currency);
		
		GraphLines = New Array;
		
		If ((Selection.ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments
				Or Selection.ARAPObjectSettings = Enums.ARAPObjectSettings.ByOrders)
				And Not Selection.ReportOnOrders)
			Or Selection.ARAPObjectSettings = Enums.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice
			Or Selection.ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice Then
			GraphLines = CashServer.ScheduleLinesForPayment(Selection.DocumentBasis);
		EndIf;
		
		If GraphLines.Count() Then
			
			Result = CashServer.PayChartLines(GraphLines, "BankAccountReceiptNote");
			
			If Result.Property("DocumentToCreate") And ValueIsFilled(Result.DocumentToCreate) Then
				FillByArrayOfBases(FillingData, Result.DocumentToCreate.FillingData.Basis);
			EndIf;
			
		Else
			
			Query = New Query(
			"SELECT DISTINCT
			|	ProductTable.MaterialProviderOrder AS SalesOrder
			|FROM
			|	Document.ReportToMaterialProvider2_5.ManufacturedProduct AS ProductTable
			|WHERE
			|	ProductTable.Ref = &Ref
			|	AND ProductTable.Ref.ReportOnOrders
			|");
			Query.SetParameter("Ref", DocumentBasis);
			
			RequestResultForOrders = Query.Execute();
			If Not RequestResultForOrders.IsEmpty() Then
				CustomerOrders = RequestResultForOrders.Unload().UnloadColumn("SalesOrder");
				CustomerOrders.Add(DocumentBasis);
			Else
				CustomerOrders = DocumentBasis;
			EndIf;
			
			ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
			ParametersForFillingInDecryption.SalesOrder     = CustomerOrders;
			ParametersForFillingInDecryption.Contract          = Selection.Contract;
			ParametersForFillingInDecryption.DocumentCurrency  = FillingData.Currency;
			ParametersForFillingInDecryption.Partner          = Selection.Partner;
			ParametersForFillingInDecryption.PaymentPurpose = DocumentBasis;
			ParametersForFillingInDecryption.CashFlowItem = Selection.CashFlowItem;
			
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

Procedure FillInGiverReportBetweenCompanies(Val DocumentBasis, FillingData, AmountToPay = 0)
	
	Query = New Query("
	|SELECT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.MaterialProvider AS Partner,
	|	DocumentData.MaterialProvider AS Counterparty,
	|	UNDEFINED AS Contract,
	|	DocumentData.MaterialProviderAccount AS BankAccountBeneficiary,
	|	DocumentData.SubcontractorAccount AS BankAccount,
	|	CASE
	|		WHEN DocumentData.SubcontractorAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
	|			THEN DocumentData.SubcontractorAccount.CashCurrency
	|		ELSE DocumentData.Currency
	|	END AS Currency,
	|	&Ref AS DocumentBasis,
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromOtherCompany) AS BusinessOperation
	|FROM
	|	Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredIntercompany)
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
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(Enums.PaymentForms.BankAccountPayment, FillingData);
		
		ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
		ParametersForFillingInDecryption.SalesOrder     = DocumentBasis;
		ParametersForFillingInDecryption.Contract          = Selection.Contract;
		ParametersForFillingInDecryption.DocumentCurrency  = FillingData.Currency;
		ParametersForFillingInDecryption.Partner          = Selection.Partner;
		ParametersForFillingInDecryption.PaymentPurpose = DocumentBasis;
		
		ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(ParametersForFillingInDecryption, ARAPDetails);
		
	EndIf;
	
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure
Procedure FillInInvoiceForPaymentToClient(Val DocumentBasis, FillingData)
	
	// Fill in the data of the document header.
	QueryText = "
	|SELECT
	|	CASE WHEN DocumentData.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.BankAccount.Owner
	|	ELSE
	|		DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.DocumentBasis.Counterparty AS Counterparty,
	|	DocumentData.DocumentBasis AS SalesOrder,
	|	DocumentData.BankAccount AS BankAccount,
	|	DocumentData.Contract AS Contract,
	|
	|	CASE WHEN DocumentData.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.BankAccount.CashCurrency
	|	ELSE
	|		DocumentData.Currency
	|	END AS Currency,
	|
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer) AS BusinessOperation
	|FROM
	|	Document.CustomerCommercialInvoice AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	
	FillingData = New Structure;
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult.Select();
	If Selection.Next() Then
		
		FillPropertyValues(FillingData, Selection);
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(Enums.PaymentForms.BankAccountPayment, FillingData);
		CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(
			FillingData.Counterparty,
			FillingData.Currency);
		
		ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnInvoice(
			DocumentBasis,
			Selection.Organization,
			Selection.SalesOrder,
			FillingData.Currency,
			ARAPDetails);
	EndIf;
	
	// Filling in the amount of the document header
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure

Procedure FillInPlannedReceiptOfFunds(Val DocumentBasis, FillingData)
	
	// Fill in the data of the document header.
	Query = New Query("
	|SELECT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.BankAccount AS BankAccount,
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
	|	DocumentData.BankAccount,
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
			NStr("vi = 'Không cần nhập thu tiền vào tài khoản ngân hàng trên cơ sở chứng từ %1';
				|ru = 'Не требуется вводить поступление безналичных денежных средств на основании документа %1';
				|en = 'It is not required to enter ""Incoming payment — Bank account"" based on document %1'; fa = 'It is not required to enter ""Incoming payment — Bank account"" based on document %1';
				|it = 'Non è necessario immettere l''entrata dei mezzi monetari cashless in base al documento %1';
				|pl = 'Nie trzeba wprowadzać dopływ bezgotówkowych środków pieniężnych na podstawie dokumentu %1';
				|tr = '%1 belgeye dayalı olarak gelen ödeme - banka hesabı girilmesi gerekli değildir.'"),
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
		
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(
			Enums.PaymentForms.BankAccountPayment,
			FillingData);
		
		NewRow = ARAPDetails.Add();
		FillPropertyValues(NewRow, Selection);
		
	EndIf;
	
EndProcedure

Procedure InstructionsForDebitingNonCashFunds(Val DocumentBasis, FillingData)
	
	// Fill in the data of the document header.
	Query = New Query(
	"SELECT
	|	DocumentData.Ref AS Document,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.AdvanceHolder AS AdvanceHolder,
	|	DocumentData.BankAccount AS BankAccount,
	|	DocumentData.BankAccountBeneficiary AS BankAccountBeneficiary,
	|	DocumentData.CounterpartyBankAccount AS CounterpartyBankAccount,
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|	DocumentData.ConversionAmount AS ConversionAmount,
	|	DocumentData.AmountInPayerSCurrency AS AmountInPayerSCurrency,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.CurrencyOfConversion AS CurrencyOfConversion,
	|	DocumentData.ConversionRate AS ConversionRate,
	|	DocumentData.ConversionRateMultiplier AS ConversionRateMultiplier,
	|	DocumentData.CashFlowItem AS CashFlowItem,
	|	DocumentData.PersonsList AS PersonsList,
	|	DocumentData.PaymentWithConversion AS PaymentWithConversion,
	|	DocumentData.PaymentPurposes AS PaymentPurposes,
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CurrencyConversion)
	|			THEN DocumentData.PaymentID
	|		ELSE """"
	|	END AS PaymentID
	|INTO DocumentData
	|FROM
	|	Document.BankAccountIssue AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.CurrencyConversion),
	|		VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder),
	|		VALUE(Enum.BusinessTransactions.SalaryPaymentToBankAccounts),
	|		VALUE(Enum.BusinessTransactions.SalaryPaymentByPayrollCardProgram),
	|		VALUE(Enum.BusinessTransactions.TransferCashToAnotherAccount),
	|		VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany),
	|		VALUE(Enum.BusinessTransactions.RefundToAnotherCompany),
	|		VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices),
	|		VALUE(Enum.BusinessTransactions.PaymentToVendor))
	|
	|INDEX BY
	|	AdvanceHolder,
	|	Organization,
	|	Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AdvanceHolderCashBalance.AdvanceHolder AS AdvanceHolder,
	|	AdvanceHolderCashBalance.Organization AS Organization,
	|	AdvanceHolderCashBalance.Currency AS Currency,
	|	AdvanceHolderCashBalance.SumBalance AS SumBalance
	|INTO BalancesOfCashHeldByAccountablePersons
	|FROM
	|	AccumulationRegister.AdvanceHolderCash.Balance(
	|			,
	|			(AdvanceHolder, Organization, Currency) IN
	|				(SELECT
	|					DocumentData.AdvanceHolder,
	|					DocumentData.Organization,
	|					DocumentData.Currency
	|				FROM
	|					DocumentData
	|				WHERE
	|					DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder))) AS AdvanceHolderCashBalance
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.Counterparty AS Counterparty,
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
	|				AND NOT DocumentData.PersonsList
	|			THEN VALUE(Enum.BusinessTransactions.CashReturnByAdvanceHolder)
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.SalaryPaymentToBankAccounts)
	|			THEN VALUE(Enum.BusinessTransactions.UnremittedSalaryReturnToPersonalAccounts)
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.SalaryPaymentByPayrollCardProgram)
	|				OR DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
	|					AND DocumentData.PersonsList
	|			THEN VALUE(Enum.BusinessTransactions.ReturnOfPayrollPaymentByPayrollCardProgram)
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferCashToAnotherAccount)
	|			THEN VALUE(Enum.BusinessTransactions.CashReceiptFromAnotherAccount)
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany)
	|			THEN VALUE(Enum.BusinessTransactions.CashReceiptFromOtherCompany)
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundToAnotherCompany)
	|			THEN VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany)
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices)
	|			THEN VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices)
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CurrencyConversion)
	|			THEN VALUE(Enum.BusinessTransactions.CurrencyConversion)
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PaymentToVendor)
	|			THEN VALUE(Enum.BusinessTransactions.RefundFromVendor)
	|	END AS BusinessOperation,
	|	CASE
	|		WHEN DocumentData.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder),
	|				VALUE(Enum.BusinessTransactions.SalaryPaymentToBankAccounts),
	|				VALUE(Enum.BusinessTransactions.SalaryPaymentByPayrollCardProgram),
	|				VALUE(Enum.BusinessTransactions.PaymentToVendor))
	|			THEN DocumentData.BankAccount
	|		ELSE DocumentData.BankAccountBeneficiary
	|	END AS BankAccount,
	|	CASE
	|		WHEN DocumentData.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany),
	|				VALUE(Enum.BusinessTransactions.RefundToAnotherCompany),
	|				VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices),
	|				VALUE(Enum.BusinessTransactions.TransferCashToAnotherAccount))
	|			THEN DocumentData.BankAccount
	|		ELSE UNDEFINED
	|	END AS SenderBankAccount,
	|	CASE
	|		WHEN DocumentData.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany),
	|				VALUE(Enum.BusinessTransactions.RefundToAnotherCompany),
	|				VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices))
	|			THEN DocumentData.BankAccountBeneficiary.Owner
	|		ELSE DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.Department AS Department,
	|	CASE
	|		WHEN DocumentData.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder),
	|				VALUE(Enum.BusinessTransactions.PaymentToVendor),
	|				VALUE(Enum.BusinessTransactions.SalaryPaymentToBankAccounts),
	|				VALUE(Enum.BusinessTransactions.SalaryPaymentByPayrollCardProgram))
	|			THEN DocumentData.BankAccount.CashCurrency
	|		ELSE DocumentData.BankAccountBeneficiary.CashCurrency
	|	END AS Currency,
	|	DocumentData.CashFlowItem AS CashFlowItem,
	|	DocumentData.PaymentPurposes AS PaymentPurposes,
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PaymentToVendor)
	|			THEN UNDEFINED
	|		ELSE DocumentData.Document
	|	END AS WithdrawalDocument,
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
	|				AND NOT DocumentData.PersonsList
	|			THEN ISNULL(BalancesOfCashHeldByAccountablePersons.SumBalance, 0)
	|		WHEN DocumentData.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.SalaryPaymentToBankAccounts),
	|				VALUE(Enum.BusinessTransactions.SalaryPaymentByPayrollCardProgram),
	|				VALUE(Enum.BusinessTransactions.TransferCashToAnotherAccount),
	|				VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany),
	|				VALUE(Enum.BusinessTransactions.RefundToAnotherCompany),
	|				VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices))
	|			THEN DocumentData.DocumentAmount
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
	|				AND DocumentData.PersonsList
	|			THEN DocumentData.DocumentAmount
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PaymentToVendor)
	|				AND NOT DocumentData.PaymentWithConversion
	|			THEN DocumentData.DocumentAmount
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PaymentToVendor)
	|				AND DocumentData.PaymentWithConversion
	|			THEN DocumentData.AmountInPayerSCurrency
	|		ELSE DocumentData.ConversionAmount
	|	END AS DocumentAmount,
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CurrencyConversion)
	|			THEN DocumentData.DocumentAmount
	|		ELSE 0
	|	END AS ConversionAmount,
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CurrencyConversion)
	|			THEN DocumentData.Currency
	|		ELSE VALUE(Catalog.Currencies.EmptyRef)
	|	END AS CurrencyOfConversion,
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CurrencyConversion)
	|			THEN CASE
	|					WHEN DocumentData.Currency = DocumentData.Organization.LocalAccountingCurrency
	|							OR DocumentData.CurrencyOfConversion = DocumentData.Organization.LocalAccountingCurrency
	|							OR DocumentData.BankAccountBeneficiary.CashCurrency = DocumentData.Organization.LocalAccountingCurrency
	|						THEN DocumentData.ConversionRate
	|					ELSE 1 / DocumentData.ConversionRate
	|				END
	|		ELSE 0
	|	END AS ConversionRate,
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CurrencyConversion)
	|			THEN CASE
	|					WHEN DocumentData.Currency = DocumentData.Organization.LocalAccountingCurrency
	|							OR DocumentData.CurrencyOfConversion = DocumentData.Organization.LocalAccountingCurrency
	|							OR DocumentData.BankAccountBeneficiary.CashCurrency = DocumentData.Organization.LocalAccountingCurrency
	|						THEN DocumentData.ConversionRateMultiplier
	|					ELSE 1
	|				END
	|		ELSE 0
	|	END AS ConversionRateMultiplier,
	|	DocumentData.AdvanceHolder AS AdvanceHolder,
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CurrencyConversion)
	|			THEN UNDEFINED
	|		ELSE DocumentData.CounterpartyBankAccount
	|	END AS CounterpartyBankAccount,
	|	DocumentData.Document AS DocumentBasis,
	|	DocumentData.PaymentWithConversion AS PaymentWithConversion,
	|	DocumentData.PaymentID AS PaymentID
	|FROM
	|	DocumentData AS DocumentData
	|		LEFT JOIN BalancesOfCashHeldByAccountablePersons AS BalancesOfCashHeldByAccountablePersons
	|		ON DocumentData.AdvanceHolder = BalancesOfCashHeldByAccountablePersons.AdvanceHolder
	|			AND DocumentData.Organization = BalancesOfCashHeldByAccountablePersons.Organization
	|			AND DocumentData.Currency = BalancesOfCashHeldByAccountablePersons.Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP DocumentData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP BalancesOfCashHeldByAccountablePersons");
	
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể nhập chứng từ thu tiền vào tài khoản ngân hàng trên cơ sở chứng từ %1
				|với giao dịch kinh tế %2';
				|ru = 'Не требуется вводить поступление безналичных денежных средств на основании документа %1
				|с хозяйственной операцией %2';
				|en = 'It is not required to enter ""Incoming payment — Bank account"" based on document %1 
				|with business transaction %2'; fa = 'It is not required to enter ""Incoming payment — Bank account"" based on document %1 
				|with business transaction %2';
				|it = 'Non è necessario immettere l''entrata dei mezzi monetari cashless in base al documento %1
				|con la transazione commerciale %2';
				|pl = 'Nie trzeba wprowadzać dopływ bezgotówkowych środków pieniężnych na podstawie dokumentu %1 
				|z gospodarczą operacją %2';
				|tr = '%1 belgeye dayalı olarak gelen ödeme - banka hesabı girilmesi gerekli değildir 
				|ticari işlem ile%2'"),
			DocumentBasis,
			Common.ObjectAttributeValue(DocumentBasis, "BusinessOperation"));
		Raise Text;
	Else
		FillingData = New Structure;
		For Each Column In QueryResult.Columns Do
			FillingData.Insert(Column.Name);
		EndDo;
		
		Selection = QueryResult.Select();
		Selection.Next();
		
		FillPropertyValues(FillingData, Selection);
		
		If FillingData.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany
			Or FillingData.BusinessOperation = Enums.BusinessTransactions.RefundFromAnotherCompany Then
			
			Query = New Query("
			|SELECT
			|	CASE 
			|		WHEN ObjectsOfDecryptionCalculations.Object REFS Document.BankAccountIssue
			|			THEN UNDEFINED
			|		ELSE ISNULL(ARAPObjects.Ref, VALUE(Catalog.ARAPObjects.EmptyRef))
			|	END AS ARAPObject,
			|	ARAPDetails.Sum AS Sum,
			|	ARAPDetails.AmountARAP AS AmountARAP,
			|	CASE WHEN VALUETYPE(ObjectsOfDecryptionCalculations.Object) = TYPE(Catalog.IntercompanyContracts)
			|		THEN ObjectsOfDecryptionCalculations.Object.CashFlowItem
			|		ELSE ARAPDetails.CashFlowItem
			|	END AS CashFlowItem,
			|	ARAPDetails.ARAPCurrency AS ARAPCurrency,
			|	ARAPDetails.VATRate AS VATRate,
			|	ARAPDetails.VATAmount AS VATAmount
			|FROM
			|	Document.BankAccountIssue.ARAPDetails AS ARAPDetails
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
		
		If FillingData.BusinessOperation = Enums.BusinessTransactions.RefundFromVendor Then
			
			CashServer.FillInPaymentTranscriptForPaymentDocument(
				DocumentBasis, FillingData.BusinessOperation, ARAPDetails);
			
			LocalAccountingCurrency =
				SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(FillingData.Organization);
			
			ObjectsByCalculationObjects = Common.ObjectsAttributeValue(
				ARAPDetails.UnloadColumn("ARAPObject"),
				"Object");
			
			For Each DecryptionString In ARAPDetails Do
			
				If ValueIsFilled(DecryptionString.ARAPObject) Then
					DecryptionString.PaymentPurpose =
						ObjectsByCalculationObjects[DecryptionString.ARAPObject];
				EndIf;
				
				CourseAndMultiplicity = CashServer.CourseNumeratorAndCourseDenominatorOfMutualSettlements(
					FillingData.Currency,
					DecryptionString.ARAPCurrency,
					LocalAccountingCurrency,
					CurrentSessionDate(),
					DecryptionString.ARAPObject);
				
				DecryptionString.ExchangeRateNumeratorOfMutualSettlements = CourseAndMultiplicity.CourseNumerator;
				DecryptionString.TheExchangeRateIsTheDenominatorOfMutualSettlements = CourseAndMultiplicity.CourseDenominator;
				
				CashClientServer.CalculateAmountInDecryptionLine(
					DecryptionString, FillingData.Currency, LocalAccountingCurrency);
			
			EndDo;
			
			FillingData.DocumentAmount = ARAPDetails.Total("Sum");
				
		EndIf;
		
		If FillingData.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion Then
			
			ConversionParameters_SSLy = CashServer.InitializeConversionParameters();
			FillPropertyValues(ConversionParameters_SSLy, FillingData);
			ConversionParameters_SSLy.DocumentAmount = 0;
			ConversionParameters_SSLy.CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(FillingData.Organization);
			
			CashServer.CalculateConversionParameters(ConversionParameters_SSLy, "ConversionAmount");
			FillPropertyValues(FillingData, ConversionParameters_SSLy);
			
		EndIf;
		
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(
			Enums.PaymentForms.BankAccountPayment,
			FillingData);
		
		If Not ValueIsFilled(CounterpartyBankAccount)
			And Not FillingData.Property("CounterpartyBankAccount")
			And Not ValueIsFilled(FillingData.CounterpartyBankAccount) Then
		
			CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(
				FillingData.Counterparty,
				FillingData.Currency);
		
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure FillInUsingExpenseCashOrder(Val DocumentBasis, FillingData)
	
	// Fill in the data of the document header.
	Query = New Query(
	"SELECT
	|	DocumentData.Organization AS Organization,
	|	VALUE(Enum.TypesOfPaymentDocuments.PaymentWarrant) AS PaymentDocumentType,
	|	TRUE AS ProcessedByBank,
	|	&BankPostingDate AS BankPostingDate,
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromCashRegisterToBankAccount) AS BusinessOperation,
	|	DocumentData.BankAccount AS BankAccount,
	|	DocumentData.CashAccount AS CashAccountIssuer,
	|	UNDEFINED AS AdvanceHolder,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.CashFlowItem AS CashFlowItem,
	|	DocumentData.Ref AS DocumentBasis,
	|
	|	DocumentData.DocumentAmount AS DocumentAmount
	|	
	|FROM
	|	Document.CashVoucher AS DocumentData
	|	
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CashCollectionToBank)
	|	
	|UNION ALL
	|	
	|SELECT
	|	
	|	DocumentData.Organization AS Organization,
	|	VALUE(Enum.TypesOfPaymentDocuments.PaymentOrder) AS PaymentDocumentType,
	|	FALSE AS ProcessedByBank,
	|	UNDEFINED AS BankPostingDate,
	|	VALUE(Enum.BusinessTransactions.CashReturnByAdvanceHolder) AS BusinessOperation,
	|	UNDEFINED AS BankAccount,
	|	UNDEFINED AS CashAccountIssuer,
	|	DocumentData.AdvanceHolder AS AdvanceHolder,
	|	DocumentData.Currency AS Currency,
	|	UNDEFINED AS CashFlowItem,
	|	DocumentData.Ref AS DocumentBasis,
	|
	|	ISNULL(AdvanceHolderCash.SumBalance, 0) AS DocumentAmount
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
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
	|	
	|");
	
	Query.SetParameter("Ref", DocumentBasis);
	Query.SetParameter("BankPostingDate", CurrentSessionDate());
	
	QueryResult = Query.Execute();
 	If QueryResult.IsEmpty() Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể nhập chứng từ thu tiền vào tài khoản ngân hàng trên cơ sở chứng từ %1
				|với giao dịch kinh tế %2';
				|ru = 'Не требуется вводить поступление безналичных денежных средств на основании документа %1
				|с хозяйственной операцией %2';
				|en = 'It is not required to enter ""Incoming payment — Bank account"" based on document %1 
				|with business transaction %2'; fa = 'It is not required to enter ""Incoming payment — Bank account"" based on document %1 
				|with business transaction %2';
				|it = 'Non è necessario immettere l''entrata dei mezzi monetari cashless in base al documento %1
				|con la transazione commerciale %2';
				|pl = 'Nie trzeba wprowadzać dopływ bezgotówkowych środków pieniężnych na podstawie dokumentu %1 
				|z gospodarczą operacją %2';
				|tr = '%1 belgeye dayalı olarak gelen ödeme - banka hesabı girilmesi gerekli değildir 
				|ticari işlem ile%2'"),
			DocumentBasis,
			Common.ObjectAttributeValue(DocumentBasis, "BusinessOperation"));
		Raise Text;
	Else
		FillingData = New Structure;
		For Each Column In QueryResult.Columns Do
			FillingData.Insert(Column.Name);
		EndDo;
		
		Selection = QueryResult.Select();
		Selection.Next();
		
		FillPropertyValues(FillingData, Selection);
		
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
		EndIf;
		
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(
			Enums.PaymentForms.BankAccountPayment, FillingData);
	EndIf;
	
EndProcedure

Procedure InstructionsForRedemptionOfReturnableContainersByClient(Val DocumentBasis, FillingData, AmountToPay = 0)
	
	// Fill in the data of the document header.
	Query = New Query("
	|SELECT
	|
	|	CASE WHEN DocumentData.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.CompanyBankAccount.Owner
	|	ELSE
	|		DocumentData.Organization
	|	END AS Organization,
	|
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	CASE WHEN DocumentData.Contract.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts) THEN
	|		DocumentData.Contract.CashFlowItem
	|	ELSE
	|		CASE WHEN ISNULL(DocumentData.Contract.CashFlowItem, VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef) THEN
	|			DocumentData.Terms.CashFlowItem
	|		ELSE
	|			DocumentData.Contract.CashFlowItem
	|		END
	|	END AS CashFlowItem,
	|	DocumentData.DocumentAmount AS Sum,
	|	DocumentData.Ref AS DocumentBasis,
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer) AS BusinessOperation,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.CompanyBankAccount AS BankAccount
	|FROM
	|	Document.ReturnablePackagingRedemptionByCustomer AS DocumentData
	|
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
		
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(
			Enums.PaymentForms.BankAccountPayment,
			FillingData);
			
		CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(
			FillingData.Counterparty,
			FillingData.Currency);
		
		ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
		ParametersForFillingInDecryption.SalesOrder     = DocumentBasis;
		ParametersForFillingInDecryption.Contract          = Selection.Contract;
		ParametersForFillingInDecryption.DocumentCurrency  = FillingData.Currency;
		ParametersForFillingInDecryption.Partner          = Selection.Partner;
		ParametersForFillingInDecryption.PaymentPurpose = DocumentBasis;
		ParametersForFillingInDecryption.CashFlowItem = Selection.CashFlowItem;
		
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
	|	DocumentData.Contract AS Contract,
	|	DocumentData.DocumentAmount AS Sum,
	|	DocumentData.Ref AS DocumentBasis,
	|	DocumentData.DocumentInflow AS DocumentInflow,
	|	VALUE(Enum.BusinessTransactions.RefundFromVendor) AS BusinessOperation,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.CompanyBankAccount AS BankAccount,
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
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(Enums.PaymentForms.BankAccountPayment, FillingData);
		CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(
			FillingData.Counterparty,
			FillingData.Currency);
		
		DocumentsArray = New Array;
		If Selection.CompensationMethod = Enums.CompensationMethodsForReturnsOfGoods.LeaveAsPrepayment Then
			DocumentsArray.Add(DocumentBasis);
		EndIf;
		DocumentsArray.Add(Selection.Contract);
		
		Query = New Query("
		|SELECT
		|	ARAPObjects.Ref AS ARAPObject
		|INTO TTCalculationObjects_
		|FROM Catalog.ARAPObjects AS ARAPObjects
		|WHERE ARAPObjects.Object IN (&DocumentsArray)
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
		
		Query.SetParameter("DocumentsArray", DocumentsArray);
		
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
			NewRow.PaymentPurpose = FillingData.DocumentInflow;
			NewRow.ARAPObject = ARAPObjectsServer.GetCalculationObjectFromLink(FillingData.DocumentInflow);
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

Procedure ServicesForSaleOfGoodsServices(Val DocumentBasis, FillingData, AmountToPay = 0)
	
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
	|	DocumentData.Contract AS Contract,
	
	|	ISNULL(DocumentData.Contract.ContractType, VALUE(Enum.ContractTypes.EmptyRef)) AS ContractTypeOfContract,
	|	ISNULL(DocumentData.Contract.ConsignmentSales25, FALSE) AS ContractCommissionSales25,
	|	ISNULL(DocumentData.Contract.ConductARAPAccountingThroughEndCustomers, FALSE) AS ContractToConductSettlementsThroughEndCustomers,
	
	|	CASE WHEN DocumentData.Contract.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts) THEN
	|		DocumentData.Contract.CashFlowItem
	|	ELSE
	|		CASE WHEN ISNULL(DocumentData.Contract.CashFlowItem, VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef) THEN
	|			DocumentData.Terms.CashFlowItem
	|		ELSE
	|			DocumentData.Contract.CashFlowItem
	|		END
	|	END AS CashFlowItem,
	
	|	DocumentData.ARAPObjectSettings AS ARAPObjectSettings,
	|	DocumentData.OrderSales AS OrderSales,
	
	|	DocumentData.DocumentAmount AS Sum,
	|	DocumentData.Ref AS DocumentBasis,
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer) AS BusinessOperation,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.CompanyBankAccount AS BankAccount
	|FROM
	|	Document.CustomerInvoice AS DocumentData
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
		
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(Enums.PaymentForms.BankAccountPayment, FillingData);
		
		CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(
			FillingData.Counterparty, FillingData.Currency, FillingData.BankAccount);
			
		ContractForCommissionSettlementsThroughEndCustomers = Selection.ContractTypeOfContract = Enums.ContractTypes.WithConsignee
				And Selection.ContractCommissionSales25
				And Selection.ContractToConductSettlementsThroughEndCustomers;
		
		GraphLines = New Array;
		
		If ((Selection.ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments
			Or Selection.ARAPObjectSettings = Enums.ARAPObjectSettings.ByOrders)
			And Not Selection.OrderSales) 
			Or Selection.ARAPObjectSettings = Enums.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice
			Or Selection.ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice 
				And Not ContractForCommissionSettlementsThroughEndCustomers Then
			GraphLines = CashServer.ScheduleLinesForPayment(Selection.DocumentBasis);
		EndIf;
		
		If GraphLines.Count() Then
			
			Result = CashServer.PayChartLines(GraphLines, "BankAccountReceiptNote");
			
			If Result.Property("DocumentToCreate") And ValueIsFilled(Result.DocumentToCreate) Then
				FillByArrayOfBases(FillingData, Result.DocumentToCreate.FillingData.Basis);
			EndIf;
			
		Else
			
			Query = New Query;
			Query.SetParameter("Ref", DocumentBasis);
			Query.Text =
			"SELECT DISTINCT
			|	GoodsTable.SalesOrder AS SalesOrder
			|FROM
			|	Document.CustomerInvoice.Goods AS GoodsTable
			|WHERE
			|	GoodsTable.Ref = &Ref
			|	AND GoodsTable.Ref.OrderSales
			|	AND NOT (VALUETYPE(GoodsTable.SalesOrder) = TYPE(Document.GoodsShipmentToCustomer)
			|		OR VALUETYPE(GoodsTable.SalesOrder) = TYPE(Document.SourceDocument)
			|			AND CAST(GoodsTable.SalesOrder AS
			|			Document.SourceDocument).SourceDocumentType =
			|				VALUE(Enum.SourceDocumentTypes.GoodsShipmentToCustomer))";
			
			RequestResultForOrders = Query.Execute();
			If Not RequestResultForOrders.IsEmpty() Then
				CustomerOrders = RequestResultForOrders.Unload().UnloadColumn("SalesOrder");
				CustomerOrders.Add(DocumentBasis);
			Else
				CustomerOrders = DocumentBasis;
			EndIf;
			
			ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
			If Selection.ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice 
				And ContractForCommissionSettlementsThroughEndCustomers Then
				ParametersForFillingInDecryption.SalesOrder = Selection.Contract;
				ParametersForFillingInDecryption.PaymentPurpose = Selection.Contract;
			Else
				ParametersForFillingInDecryption.SalesOrder = CustomerOrders;
				ParametersForFillingInDecryption.PaymentPurpose = DocumentBasis;
			EndIf;
			ParametersForFillingInDecryption.Contract          = Selection.Contract;
			ParametersForFillingInDecryption.DocumentCurrency  = FillingData.Currency;
			ParametersForFillingInDecryption.Partner          = Selection.Partner;
			ParametersForFillingInDecryption.CashFlowItem = Selection.CashFlowItem;
			
			If AmountToPay = 0 Then
				AmountToPay = Selection.Sum;
			EndIf;
			
			ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(
				ParametersForFillingInDecryption,
				ARAPDetails,
				AmountToPay);
			
		EndIf;
		
	EndIf;
	
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure

Procedure FillInActOfWorkPerformed(Val DocumentBasis, FillingData, AmountToPay = 0)
	
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
	|	DocumentData.Contract AS Contract,
	|	CASE WHEN DocumentData.Contract.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts) THEN
	|		DocumentData.Contract.CashFlowItem
	|	ELSE
	|		CASE WHEN ISNULL(DocumentData.Contract.CashFlowItem, VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef) THEN
	|			DocumentData.Terms.CashFlowItem
	|		ELSE
	|			DocumentData.Contract.CashFlowItem
	|		END
	|	END AS CashFlowItem,
	|	DocumentData.DocumentAmount AS Sum,
	|	DocumentData.Ref AS DocumentBasis,
	|	DocumentData.ARAPObjectSettings AS ARAPObjectSettings,
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer) AS BusinessOperation,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.CompanyBankAccount AS BankAccount
	|FROM
	|	Document.CustomerInvoiceServices AS DocumentData
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
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(Enums.PaymentForms.BankAccountPayment, FillingData);
		CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(
			FillingData.Counterparty, FillingData.Currency);
			
		GraphLines = New Array;
		
		If Selection.ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments
			Or Selection.ARAPObjectSettings = Enums.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice
			Or Selection.ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice Then
			GraphLines = CashServer.ScheduleLinesForPayment(Selection.DocumentBasis);
		EndIf;
		
		If GraphLines.Count() Then
			
			Result = CashServer.PayChartLines(GraphLines, "BankAccountReceiptNote");
			
			If Result.Property("DocumentToCreate") And ValueIsFilled(Result.DocumentToCreate) Then
				FillByArrayOfBases(FillingData, Result.DocumentToCreate.FillingData.Basis);
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
			Query.SetParameter("Ref", DocumentBasis);
			
			RequestResultForOrders = Query.Execute();
			If Not RequestResultForOrders.IsEmpty() Then
				CustomerOrders = RequestResultForOrders.Unload().UnloadColumn("SalesOrder");
				CustomerOrders.Add(DocumentBasis);
			Else
				CustomerOrders = DocumentBasis;
			EndIf;
			
			ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
			ParametersForFillingInDecryption.SalesOrder     = CustomerOrders;
			ParametersForFillingInDecryption.Contract          = Selection.Contract;
			ParametersForFillingInDecryption.DocumentCurrency  = FillingData.Currency;
			ParametersForFillingInDecryption.Partner          = Selection.Partner;
			ParametersForFillingInDecryption.PaymentPurpose = DocumentBasis;
			ParametersForFillingInDecryption.CashFlowItem = Selection.CashFlowItem;
			
			If AmountToPay = 0 Then
				AmountToPay = Selection.Sum;
			EndIf;
			
			ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(
				ParametersForFillingInDecryption,
				ARAPDetails,
				AmountToPay);
			
		EndIf;
		
	EndIf;
	
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure

Procedure FillInUnderCounterpartySAgreement(Val Contract, FillingData, AmountToPay = 0)
	
	FillingData.Property("BankAccount", BankAccount);
	
	Query = New Query("
	|SELECT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Counterparty.Description AS CounterpartyName_,
	|	DocumentData.Counterparty.DescriptionFull AS ReceivedFrom,
	|	DocumentData.Ref AS PaymentPurpose,
	|	DocumentData.Ref AS Contract,
	|	&ARAPObject AS ARAPObject,
	|	DocumentData.Ref AS SalesOrder,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.ContractType AS ContractType,
	|	DocumentData.Ref AS DocumentBasis,
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer) AS BusinessOperation,
	|	DocumentData.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	DocumentData.CashFlowItem AS CashFlowItem,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.Department AS Department,
	|	DocumentData.BankAccount AS BankAccount,
	|	DocumentData.CounterpartyBankAccount AS CounterpartyBankAccount,
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
		
		If ValueIsFilled(BankAccount) Then
			FillingData.Insert("BankAccount", BankAccount);
		EndIf;
		
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(Enums.PaymentForms.BankAccountPayment, FillingData);
		If ValueIsFilled(Selection.ARAPObject) Then
			ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
			ParametersForFillingInDecryption.SalesOrder     = FillingData.SalesOrder;
			ParametersForFillingInDecryption.Contract          = FillingData.Contract;
			ParametersForFillingInDecryption.DocumentCurrency  = FillingData.Currency;
			ParametersForFillingInDecryption.Partner          = FillingData.Partner;
			ParametersForFillingInDecryption.PaymentPurpose = FillingData.PaymentPurpose;
			ParametersForFillingInDecryption.CashFlowItem = Selection.CashFlowItem;
			
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
	|	DocumentData.Contract AS Contract,
	|	DocumentData.DocumentAmount AS Sum,
	|	DocumentData.CommissionAmount AS CommissionAmount,
	|	DocumentData.Ref AS DocumentBasis,
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer) AS BusinessOperation,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.BankAccount AS BankAccount
	|FROM
	|	Document.ConsignmentReportFromCustomer AS DocumentData
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
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(Enums.PaymentForms.BankAccountPayment, FillingData);
		CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(
			FillingData.Counterparty,
			FillingData.Currency);
		
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
	|	CASE WHEN DocumentData.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.BankAccount.Owner
	|	ELSE
	|		DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	CASE WHEN DocumentData.Contract.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts) THEN
	|		DocumentData.Contract.CashFlowItem
	|	ELSE
	|		CASE WHEN ISNULL(DocumentData.Contract.CashFlowItem, VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef) THEN
	|			DocumentData.Terms.CashFlowItem
	|		ELSE
	|			DocumentData.Contract.CashFlowItem
	|		END
	|	END AS CashFlowItem,
	|	DocumentData.CommissionAmount AS Sum,
	|	DocumentData.Ref AS DocumentBasis,
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer) AS BusinessOperation,
	|	DocumentData.BankAccount AS BankAccount,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.KeepCommissionFee AS KeepCommissionFee
	|FROM
	|	Document.ConsignmentReportToVendor AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|");
	
	Query.SetParameter("Ref", ConsignmentReportToVendor);
	QueryResult = Query.Execute();
	
	FillingData = New Structure;
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult.Select();
	If Selection.Next() Then
		
		If Selection.KeepCommissionFee Then
				
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không cần nhập chứng từ thu tiền vào tài khoản ngân hàng trên cơ sở chứng từ %1, vì trong đó đã giữ lại khoản hoa hồng';
					|ru = 'Не требуется вводить поступление безналичных денежных средств на основании документа %1, поскольку в нем удержано вознаграждение';
					|en = 'It is not required to enter ""Incoming payment — Bank account"" based on document %1 as remuneration is deducted in it'; fa = 'It is not required to enter ""Incoming payment — Bank account"" based on document %1 as remuneration is deducted in it';
					|it = 'Non è necessario immettere l''entrata dei mezzi monetari cashless in base al documento %1, perché nel documento è trattenuto il compenso';
					|pl = 'Nie trzeba wprowadzać wpływu bezgotówkowych środków pieniężnych na podstawie dokumentu %1, ponieważ w nim potrącono wynagrodzenie';
					|tr = '%1 belgesine dayalı olarak gelen ödeme - banka hesabı girmek gerekli değildir, çünkü ikramiye bu belgeden düşülür.'"),
				ConsignmentReportToVendor);
			
			Raise Text;
			
		EndIf;
		
		FillPropertyValues(FillingData, Selection);
		
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(
			Enums.PaymentForms.BankAccountPayment,
			FillingData);
			
		CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(
			FillingData.Counterparty,
			FillingData.Currency);
		
		ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
		ParametersForFillingInDecryption.SalesOrder     = ConsignmentReportToVendor;
		ParametersForFillingInDecryption.Contract          = Selection.Contract;
		ParametersForFillingInDecryption.DocumentCurrency  = FillingData.Currency;
		ParametersForFillingInDecryption.Partner          = Selection.Partner;
		ParametersForFillingInDecryption.PaymentPurpose = ConsignmentReportToVendor;
		ParametersForFillingInDecryption.CashFlowItem = Selection.CashFlowItem;
		
		ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(
			ParametersForFillingInDecryption,
			ARAPDetails);
		
	EndIf;
	
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure

Procedure FillInReportToPurchasingCommittee(Val DocumentBasis, FillingData, AmountToPay = 0)
	
	Query = New Query(
	"SELECT
	|	
	|	CASE WHEN DocumentData.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.BankAccount.Owner
	|	ELSE
	|		DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	CASE WHEN DocumentData.Contract.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts) THEN
	|		DocumentData.Contract.CashFlowItem
	|	ELSE
	|		CASE WHEN ISNULL(DocumentData.Contract.CashFlowItem, VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef) THEN
	|			DocumentData.Terms.CashFlowItem
	|		ELSE
	|			DocumentData.Contract.CashFlowItem
	|		END
	|	END AS CashFlowItem,
	|	DocumentData.ARAPObjectSettings AS ARAPObjectSettings,
	|	DocumentData.DocumentAmount AS Sum,
	|	DocumentData.Ref AS DocumentBasis,
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer) AS BusinessOperation,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.BankAccount AS BankAccount
	|FROM
	|	Document.PurchasingReportToConsignorPrincipal AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|");
	
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	OrderSales = Constants.OptionOfGoodsAssignmentInSales.Get() = Enums.OptionsOfGoodsAssignmentInSales.SalesOrder;
	
	Selection = QueryResult.Select();
	If Selection.Next() Then
		
		FillPropertyValues(FillingData, Selection);
		
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(Enums.PaymentForms.BankAccountPayment, FillingData);
		
		CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(
			FillingData.Counterparty, FillingData.Currency);
			
		GraphLines = New Array;
		
		If (Selection.ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments
			Or Selection.ARAPObjectSettings = Enums.ARAPObjectSettings.ByOrders)
			And Not OrderSales Then
			GraphLines = CashServer.ScheduleLinesForPayment(Selection.DocumentBasis);
		EndIf;
		
		If GraphLines.Count() Then
			
			Result = CashServer.PayChartLines(GraphLines, "BankAccountReceiptNote");
			
			If Result.Property("DocumentToCreate") And ValueIsFilled(Result.DocumentToCreate) Then
				FillByArrayOfBases(FillingData, Result.DocumentToCreate.FillingData.Basis);
			EndIf;
			
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
			Query.SetParameter("Ref", DocumentBasis);
			
			RequestResultForOrders = Query.Execute();
			If Not RequestResultForOrders.IsEmpty() Then
				CustomerOrders = RequestResultForOrders.Unload().UnloadColumn("SalesOrder");
				CustomerOrders.Add(DocumentBasis);
			Else
				CustomerOrders = DocumentBasis;
			EndIf;
			
			ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
			ParametersForFillingInDecryption.SalesOrder     = CustomerOrders;
			ParametersForFillingInDecryption.Contract          = Selection.Contract;
			ParametersForFillingInDecryption.DocumentCurrency  = FillingData.Currency;
			ParametersForFillingInDecryption.Partner          = Selection.Partner;
			ParametersForFillingInDecryption.PaymentPurpose = DocumentBasis;
			ParametersForFillingInDecryption.CashFlowItem = Selection.CashFlowItem;
			
			If AmountToPay = 0 Then
				AmountToPay = Selection.Sum;
			EndIf;
			
			ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(
				ParametersForFillingInDecryption,
				ARAPDetails,
				AmountToPay);
			
		EndIf;
		
	EndIf;
	
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure

Procedure FillInRequestForReturnOfGoods(Val DocumentBasis, FillingData, AmountToPay = 0)
	
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
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Ref AS DocumentBasis,
	|	CASE WHEN DocumentData.Contract.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts) THEN
	|		DocumentData.Contract.CashFlowItem
	|	ELSE
	|		CASE WHEN ISNULL(DocumentData.Contract.CashFlowItem, VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef) THEN
	|			DocumentData.Terms.CashFlowItem
	|		ELSE
	|			DocumentData.Contract.CashFlowItem
	|		END
	|	END AS CashFlowItem,
	|
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer) AS BusinessOperation,
	|	DocumentData.BankAccount AS BankAccount,
	|	DocumentData.CounterpartyBankAccount AS CounterpartyBankAccount,
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
			NStr("vi = 'Không cần nhập thu tiền vào tài khoản ngân hàng trên cơ sở chứng từ %1';
				|ru = 'Не требуется вводить поступление безналичных денежных средств на основании документа %1';
				|en = 'It is not required to enter ""Incoming payment — Bank account"" based on document %1'; fa = 'It is not required to enter ""Incoming payment — Bank account"" based on document %1';
				|it = 'Non è necessario immettere l''entrata dei mezzi monetari cashless in base al documento %1';
				|pl = 'Nie trzeba wprowadzać dopływ bezgotówkowych środków pieniężnych na podstawie dokumentu %1';
				|tr = '%1 belgeye dayalı olarak gelen ödeme - banka hesabı girilmesi gerekli değildir.'"),
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
		CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(
			FillingData.Counterparty,
			FillingData.Currency);
		
		ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
		ParametersForFillingInDecryption.SalesOrder     = DocumentBasis;
		ParametersForFillingInDecryption.Contract          = Selection.Contract;
		ParametersForFillingInDecryption.DocumentCurrency  = FillingData.Currency;
		ParametersForFillingInDecryption.Partner          = Selection.Partner;
		ParametersForFillingInDecryption.PaymentPurpose = DocumentBasis;
		ParametersForFillingInDecryption.CashFlowItem = Selection.CashFlowItem;
		
		ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(
			ParametersForFillingInDecryption,
			ARAPDetails);
		
	EndIf;
	
	// Filling in the amount of the document header
	DocumentAmount = ARAPDetails.Total("Sum");
		
EndProcedure

Procedure ActivitiesForSaleOfServicesOfOtherAssets(Val SaleOfGoodsAndServices, FillingData, AmountToPay = 0)
	
	Query = New Query("
		|SELECT
		|	CASE WHEN DocumentData.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
		|		DocumentData.CompanyBankAccount.Owner
		|	ELSE
		|		DocumentData.Organization
		|	END AS Organization,
		|	DocumentData.Partner AS Partner,
		|	DocumentData.Counterparty AS Counterparty,
		|	DocumentData.Counterparty.Description AS CounterpartyName_,
		|	DocumentData.Contract AS Contract,
		|	CASE WHEN DocumentData.Contract.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts) THEN
		|		DocumentData.Contract.CashFlowItem
		|	ELSE
		|		CASE WHEN ISNULL(DocumentData.Contract.CashFlowItem, VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef) THEN
		|			DocumentData.Terms.CashFlowItem
		|		ELSE
		|			DocumentData.Contract.CashFlowItem
		|		END
		|	END AS CashFlowItem,
		|	DocumentData.ARAPCurrency AS ARAPCurrency,
		|	DocumentData.AmountARAP AS AmountARAP,
		|	DocumentData.AmountARAP AS Sum,
		|	DocumentData.Ref AS DocumentBasis,
		|	VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer) AS BusinessOperation,
		|	DocumentData.Currency AS Currency,
		|	DocumentData.CompanyBankAccount AS BankAccount
		|FROM
		|	Document.CustomerInvoiceServicesAndAssets AS DocumentData
		|WHERE
		|	DocumentData.Ref = &Ref
		|");
	Query.SetParameter("Ref", SaleOfGoodsAndServices);
	QueryResult = Query.Execute();
	
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult.Select();
	If Selection.Next() Then
		
		FillPropertyValues(FillingData, Selection);
		
		If Not FillingData.Property("BankAccount") Then
			FillingData.Insert("BankAccount");
		EndIf;
		
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(Enums.PaymentForms.BankAccountPayment, FillingData);
		
		ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
		ParametersForFillingInDecryption.SalesOrder     = SaleOfGoodsAndServices;
		ParametersForFillingInDecryption.Contract          = Selection.Contract;
		ParametersForFillingInDecryption.DocumentCurrency  = FillingData.Currency;
		ParametersForFillingInDecryption.Partner          = Selection.Partner;
		ParametersForFillingInDecryption.PaymentPurpose = SaleOfGoodsAndServices;
		ParametersForFillingInDecryption.CashFlowItem = Selection.CashFlowItem;
		
		ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(ParametersForFillingInDecryption, ARAPDetails);
		
	EndIf;
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure

Procedure InstructionsForTransferOfGoods(Val DocumentBasis, FillingData, AmountToPay = 0)
	
	Query = New Query("
	|SELECT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.CompanyRecipient AS Partner,
	|	DocumentData.CompanyRecipient AS Counterparty,
	|	UNDEFINED AS Contract,
	|	DocumentData.RecipientCompanyBankAccount AS BankAccountBeneficiary,
	|	DocumentData.CompanyBankAccount AS BankAccount,
	|
	|	CASE WHEN DocumentData.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.CompanyBankAccount.CashCurrency
	|	ELSE
	|		DocumentData.Currency
	|	END AS Currency,
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
	|	DocumentData.RecipientCompanyBankAccount AS BankAccountBeneficiary,
	|	DocumentData.CompanyBankAccount AS BankAccount,
	|
	|	CASE WHEN DocumentData.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.CompanyBankAccount.CashCurrency
	|	ELSE
	|		DocumentData.Currency
	|	END AS Currency,
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
	
	FillingData = New Structure;
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult.Select();
	If Selection.Next() Then
		FillPropertyValues(FillingData, Selection);
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(Enums.PaymentForms.BankAccountPayment, FillingData);
		
		ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
		ParametersForFillingInDecryption.SalesOrder     = DocumentBasis;
		ParametersForFillingInDecryption.Contract          = Selection.Contract;
		ParametersForFillingInDecryption.DocumentCurrency  = FillingData.Currency;
		ParametersForFillingInDecryption.Partner          = Selection.Partner;
		ParametersForFillingInDecryption.PaymentPurpose = DocumentBasis;
		
		ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(ParametersForFillingInDecryption, ARAPDetails);
	EndIf;
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure

Procedure FillInCommissionReport(Val DocumentBasis, FillingData, AmountDue = 0, Remuneration = False)
	
	Query = New Query("
	|SELECT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Consignee AS SenderOrganization,
	|	DocumentData.Consignee AS Partner,
	|	UNDEFINED AS Counterparty,
	|	UNDEFINED AS Contract,
	|	DocumentData.Contract.BankAccount AS BankAccount,
	|	DocumentData.Contract.BankAccountOfBeneficiary AS SenderBankAccount,
	|	DocumentData.Currency AS Currency,
	|	&Ref AS DocumentBasis,
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromOtherCompany) AS BusinessOperation
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
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Consignee AS SenderOrganization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS BankAccount,
	|	UNDEFINED AS SenderBankAccount,
	|	DocumentData.Currency AS Currency,
	|	&Ref AS DocumentBasis,
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer) AS BusinessOperation
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
	|	DocumentData.Consignee AS Organization,
	|	DocumentData.Organization AS SenderOrganization,
	|	DocumentData.Organization AS Partner,
	|	UNDEFINED AS Counterparty,
	|	UNDEFINED AS Contract,
	|	DocumentData.Contract.BankAccountOfBeneficiary AS SenderBankAccount,
	|	DocumentData.Contract.BankAccount AS BankAccount,
	|	DocumentData.Currency AS Currency,
	|	&Ref AS DocumentBasis,
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromOtherCompany) AS BusinessOperation
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
	|	DocumentData.Consignee AS Organization,
	|	DocumentData.Organization AS SenderOrganization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS BankAccount,
	|	UNDEFINED AS SenderBankAccount,
	|	DocumentData.Currency AS Currency,
	|	&Ref AS DocumentBasis,
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer) AS BusinessOperation
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
	
	Selection = QueryResult.Select();
	If Selection.Next() Then
		FillPropertyValues(FillingData, Selection);
		
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(Enums.PaymentForms.BankAccountPayment, FillingData);
		
		ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
		ParametersForFillingInDecryption.SalesOrder     = DocumentBasis;
		ParametersForFillingInDecryption.Contract          = Selection.Contract;
		ParametersForFillingInDecryption.DocumentCurrency  = FillingData.Currency;
		ParametersForFillingInDecryption.Partner          = Selection.Partner;
		ParametersForFillingInDecryption.PaymentPurpose = DocumentBasis;
		
		ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(
			ParametersForFillingInDecryption, ARAPDetails, AmountDue, FillingData.Organization);
		
		If Not ValueIsFilled(FillingData.BankAccount) Then
			ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount();
			ParametersOfAccount.Organization = FillingData.Organization;
			ParametersOfAccount.Currency = FillingData.Currency;
			FillingData.BankAccount = Catalogs.CompaniesBankAccounts.GetDefaultBankAccount(
				ParametersOfAccount);
		EndIf;
		
		If Not ValueIsFilled(FillingData.SenderBankAccount) Then
			ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount();
			ParametersOfAccount.Organization = FillingData.SenderOrganization;
			ParametersOfAccount.Currency = FillingData.Currency;
			ParametersOfAccount.OffsettingAccount = FillingData.BankAccount;
			FillingData.SenderBankAccount =
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
	
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure

Procedure FillByArrayOfBases(FillingData, ArrayOfBases)
	
	CashServer.FillInDetailsOfDocumentOnFormOfPayment(Enums.PaymentForms.BankAccountPayment, FillingData);
	
	If FillingData.Property("BusinessOperation")
		And FillingData.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany Then
		ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount();
		ParametersOfAccount.Organization = FillingData.Counterparty;
		ParametersOfAccount.Currency = FillingData.Currency;
		ParametersOfAccount.OffsettingAccount = FillingData.BankAccount;
		SenderBankAccount = Catalogs.CompaniesBankAccounts.GetDefaultBankAccount(
			ParametersOfAccount);
	Else
		CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(
			FillingData.Counterparty, FillingData.Currency, FillingData.BankAccount);
	EndIf;
		
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
			For Each Basis In ArrayOfBases Do
				NewRow = ARAPDetails.Add();
				FillPropertyValues(NewRow, Basis);
			EndDo;
		EndIf;
		
		DocumentAmount = ARAPDetails.Total("Sum");
	EndIf;
	
EndProcedure

Procedure InstructionsForRedemptionOfGoodsByCustodian(Val DocumentBasis, FillingData, AmountToPay = 0)
	
	Query = New Query;
	Query.SetParameter("Ref", DocumentBasis);
	Query.Text =
	"SELECT
	|	CASE
	|		WHEN DocumentData.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
	|			THEN DocumentData.CompanyBankAccount.Owner
	|		ELSE DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	CASE
	|		WHEN ISNULL(DocumentData.Contract.ARAPObjectSettings, VALUE(Enum.ARAPObjectSettings.EmptyRef)) = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
	|			THEN DocumentData.Contract.CashFlowItem
	|		ELSE
	|			CASE
	|				WHEN ISNULL(DocumentData.Contract.CashFlowItem, VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef)
	|					THEN ISNULL(DocumentData.Terms.CashFlowItem, VALUE(Catalog.CashFlowReportItems.EmptyRef))
	|				ELSE DocumentData.Contract.CashFlowItem
	|			END
	|	END AS CashFlowItem,
	|	DocumentData.DocumentAmount AS Sum,
	|	DocumentData.Ref AS DocumentBasis,
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer) AS BusinessOperation,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.CompanyBankAccount AS BankAccount
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
		
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(
			Enums.PaymentForms.BankAccountPayment,
			FillingData);
			
		CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(
			FillingData.Counterparty,
			FillingData.Currency);
		
		ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
		ParametersForFillingInDecryption.SalesOrder = DocumentBasis;
		ParametersForFillingInDecryption.Contract = Selection.Contract;
		ParametersForFillingInDecryption.DocumentCurrency = FillingData.Currency;
		ParametersForFillingInDecryption.Partner = Selection.Partner;
		ParametersForFillingInDecryption.PaymentPurpose = DocumentBasis;
		ParametersForFillingInDecryption.CashFlowItem = Selection.CashFlowItem;
		
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
		CurrencyOfComplianceAccounting, ?(ValueIsFilled(BankPostingDate), BankPostingDate, Date), GiftCertificateDetails.ARAPObject);
	NewRow.ExchangeRateNumeratorOfMutualSettlements = CourseAndMultiplicity.CourseNumerator;
	NewRow.TheExchangeRateIsTheDenominatorOfMutualSettlements = CourseAndMultiplicity.CourseDenominator;

	CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
				NewRow, Currency, CurrencyOfComplianceAccounting);
				
EndProcedure


#EndRegion

#Region Initialize

Procedure InitializeDocument(FillingData = Undefined)
	
	If TypeOf(FillingData) <> Type("Structure")
		Or Not FillingData.Property("BankAccount")
		Or Not ValueIsFilled(FillingData.BankAccount) Then
		
		BankAccount = CashServer.OrganizationSCurrentBankAccount();
		
		If Not ValueIsFilled(BankAccount) Then
			ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount();
			ParametersOfAccount.Organization = ?(ValueIsFilled(Organization), Organization, Undefined);
			ParametersOfAccount.Currency = ?(ValueIsFilled(Currency), Currency, Undefined);
			BankAccount = Catalogs.CompaniesBankAccounts.GetDefaultBankAccount(ParametersOfAccount);
		EndIf;
		If ValueIsFilled(BankAccount) Then
			AttributesStructure1 = Catalogs.CompaniesBankAccounts.GetCompanySBankAccountDetails(BankAccount);
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
	
	If TypeOf(FillingData) <> Type("Structure")
		Or Not FillingData.Property("CashAccountIssuer")
		Or Not ValueIsFilled(FillingData.CashAccountIssuer) Then
		
		If Not ValueIsFilled(CashAccountIssuer) Then
			CashAccountIssuer = Catalogs.CashAccounts.GetCheckoutByDefault(
				?(ValueIsFilled(Organization), Organization, Undefined),
				?(ValueIsFilled(Currency), Currency, Undefined));
		EndIf;
	EndIf;
	
	If TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("DocumentAmount") Then
		DocumentAmount = FillingData.DocumentAmount;
	EndIf;
	
	If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("Organization") Then
		Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	EndIf;
	
	If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("Currency") Then
		If Not ValueIsFilled(Currency) Then
			Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
		EndIf;
	EndIf;
	
	If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("ProcessedByBank") Then
		ProcessedByBank = ValueIsFilled(PaymentDocumentType) And
			Not (PaymentDocumentType = Enums.TypesOfPaymentDocuments.PaymentDemand
			Or PaymentDocumentType = Enums.TypesOfPaymentDocuments.PaymentOrder);
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
		?(ValueIsFilled(BusinessOperation), BusinessOperation, Enums.BusinessTransactions.CashReceiptFromCustomer));
	
	ThereAreCurrencyData = TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("Currency")
		And ValueIsFilled(FillingData.Currency);
	
	ThereIsPartnerData = TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("Partner")
		And ValueIsFilled(FillingData.Partner);
	
	CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	
	For Each TSRow In ARAPDetails Do
		
		If Not ValueIsFilled(TSRow.Partner)
			And ThereIsPartnerData Then
			TSRow.Partner = FillingData.Partner;
		EndIf;
		
		If ThereAreCurrencyData Then
			
			CourseAndMultiplicity = CashServer.CourseNumeratorAndCourseDenominatorOfMutualSettlements(
				FillingData.Currency, TSRow.ARAPCurrency, CurrencyOfComplianceAccounting, Date, TSRow.ARAPObject, Contract);
			TSRow.ExchangeRateNumeratorOfMutualSettlements = CourseAndMultiplicity.CourseNumerator;
			TSRow.TheExchangeRateIsTheDenominatorOfMutualSettlements = CourseAndMultiplicity.CourseDenominator;
			
		Else
			TSRow.ExchangeRateNumeratorOfMutualSettlements = 1;
			TSRow.TheExchangeRateIsTheDenominatorOfMutualSettlements = 1;
		EndIf;
		
	EndDo;
	
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

#EndRegion

#EndIf
