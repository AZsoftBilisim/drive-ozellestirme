#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	Author = Users.CurrentUser();
	
	If TypeOf(FillingData) = Type("DocumentRef.SalesOrder") Then
		
		FillInOnTheCustomerSOrder(FillingData, FillingData);
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.CustomerCommercialInvoice") Then
		
		FillInInvoiceForPaymentToClient(FillingData, FillingData);
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.CustomerInvoice") Then
		
		ServicesForSaleOfGoods(FillingData, FillingData);
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.CustomerInvoiceServicesAndAssets") Then
		
		ActivitiesForSaleOfServicesOfOtherAssets(FillingData, FillingData);
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.CustomerInvoiceServices") Then
		
		FillInActOfWorkPerformed(FillingData, FillingData);
			
	ElsIf TypeOf(FillingData) = Type("DocumentRef.ReturnOfGoodsFromCustomer") Then
		
		DocumentBasis = FillingData;
		InstructionsForReturningGoodsFromClient(FillingData, FillingData);
			
	ElsIf TypeOf(FillingData) = Type("DocumentRef.PaymentRequest") Then
		
		FillingData = New Structure("DocumentBasis, BankAccountCashAccount, Sum", FillingData);
		
		DocumentBasis = FillingData.DocumentBasis;
		CashServer.FillOutDocumentOnApplicationsForSpendingMoney(
			FillingData, ARAPDetails, Enums.PaymentForms.PaymentCard, Ref);
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.RedemptionOfGoodsByCustodian") Then
		
		InstructionsForRedemptionOfGoodsByCustodian(FillingData, FillingData);
		
	ElsIf TypeOf(FillingData) = Type("CatalogRef.GiftCertificates")
		Or TypeOf(FillingData) = Type("Structure") 
			And FillingData.Property("GiftCertificate")
			And FillingData.Property("Counterparty") Then
		
		FillInGiftCertificate(FillingData, FillingData);
			
	ElsIf TypeOf(FillingData) = Type("DocumentRef.ReportToMaterialProvider2_5") Then
		
		FillInReportToGiver2_5(FillingData, FillingData);
	ElsIf TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("Basis")
		And TypeOf(FillingData.Basis) = Type("Array") Then
		
		FillByArrayOfBases(FillingData, FillingData.Basis);
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef." + Metadata().Name) Then
		
		DocumentCorrection.FillInCorrection(ThisObject, FillingData);
		
	ElsIf TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("Basis") Then
		
		If TypeOf(FillingData.Basis) = Type("DocumentRef.SalesOrder") Then
			FillInByCustomerSOrder_Refund(FillingData);
		ElsIf TypeOf(FillingData.Basis) = Type("DocumentRef.PaymentCardTransaction") Then
			InformationOnAcquiringOperation(FillingData);
		EndIf;
		
	Else
		If TypeOf(FillingData) = Type("Structure") And FillingData.Property("AcquiringContract") Then
			AcquiringContract = FillingData.AcquiringContract;
		Else
			AcquiringContract = Common.CommonSettingsStorageLoad("CurrentAcquiringAgreement", "");
		EndIf;
		
		If TypeOf(FillingData) = Type("Structure") And FillingData.Property("POSTerminal") Then
			POSTerminal = FillingData.POSTerminal;
		Else
			POSTerminal = Common.CommonSettingsStorageLoad("CurrentPOSTerminal", "");
		EndIf;
		
		If Not ValueIsFilled(AcquiringContract) Then
			
			FilterParameters = Catalogs.AcquiringContracts.ParametersOfAcquisitionContractSelection();
			AcquiringContract = Catalogs.AcquiringContracts.ContractOfAcquiringByDefault(FilterParameters);
			
		EndIf;
		
		If ValueIsFilled(AcquiringContract) Then
			AttributesValues = Catalogs.AcquiringContracts.ContractDetails_(AcquiringContract);
			FillPropertyValues(ThisObject, AttributesValues, "Organization, Currency");
			
			If BusinessOperation = Enums.BusinessTransactions.RefundToCustomer Then
				RecordCommission = (AttributesValues.CommissionPostingMethod = Enums.MethodsOfAcquiringCommissionRecording.DuringTransaction)
					And AttributesValues.FeeIsChargedOnRefund;
			Else
				RecordCommission = (AttributesValues.CommissionPostingMethod = Enums.MethodsOfAcquiringCommissionRecording.DuringTransaction);
			EndIf;
			
			If RecordCommission Then
				KeepRecordsOfCommissionInARAPAccounting = AttributesValues.KeepRecordsOfCommissionInARAPAccounting;
				CommissionARAPObject = AttributesValues.CommissionARAPObject;
			EndIf;
		EndIf;
	EndIf;
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	InitializeDocument(FillingData);
	
	ARAPAccountingServer.Filling(ThisObject, FillingData);
	
	ItemsAndDimensionsSelectionParameters = Documents.PaymentCardTransaction.ItemsAndDimensionsSelectionParameters(
		RecordCommission And Not KeepRecordsOfCommissionInARAPAccounting);
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	PaymentCardTransactionLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
	If Not ValueIsFilled(EmployeeResponsible) Then
		EmployeeResponsible = Users.CurrentUser();
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	
	ExplanationWithoutSplit = False;
	If AdditionalProperties.Property("ExplanationWithoutSplit")
		And AdditionalProperties.ExplanationWithoutSplit Then
		ExplanationWithoutSplit = True;
	EndIf;
	
	Documents.PaymentCardTransaction.FillInNamesOfBusinessTransactionDetails(
		BusinessOperation, ArrayOfAllProps, ArrayOfOperationDetails);
	
	NotCheckedAttributeArray = New Array;
	
	TMCommonUseClientServer.FillInArrayOfUnverifiableBankingDetails(
		ArrayOfAllProps, ArrayOfOperationDetails, NotCheckedAttributeArray);
		
	If CashServer.EnabledCreatingCashIssueWithoutPaymentRequest(ThisObject) Then
		NotCheckedAttributeArray.Add("PaymentRequest");
	EndIf;
	
	If Not ValueIsFilled(AcquiringContract)
		Or Not Common.ObjectAttributeValue(AcquiringContract, "POSTerminalsAreUsed") Then
		NotCheckedAttributeArray.Add("POSTerminal");
	EndIf;
	
	If ExplanationWithoutSplit Then
		NotCheckedAttributeArray.Add("ARAPDetails.Sum");
	EndIf;
	
	CashServer.CheckRequestForSpendingMoney(ThisObject, Cancel);
	CashServer.CheckCompletionOfPaymentDecryption(ThisObject, DocumentAmount, BusinessOperation, Cancel);
	
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	If ExplanationWithoutSplit Then
		CashServer.CheckCompletionOfDecryptionWithoutSplitting(
			ThisObject, CheckedAttributes, "ARAPDetails", "ExplanationWithoutSplit", Cancel);
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
	
	ItemsAndDimensionsSelectionParameters = Documents.PaymentCardTransaction.ItemsAndDimensionsSelectionParameters(
		CheckCompletionOfCommissionArticle);
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	PaymentCardTransactionLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	CheckRepaymentDates(Cancel);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If Not ValueIsFilled(Number) Then
		SetNewNumber();
	EndIf;
	
	If Not ValueIsFilled(PaymentCardNumber) Then
		PaymentCardNumber = "0";
	EndIf;
	
	CashServer.BeforeWrite(ThisObject, Cancel);
	ARAPAccountingServer.BeforeWrite(ThisObject, Cancel, WriteMode);
	
	ItemsAndDimensionsSelectionParameters = Documents.PaymentCardTransaction.ItemsAndDimensionsSelectionParameters(
		RecordCommission And Not KeepRecordsOfCommissionInARAPAccounting);
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "ARAPDetails");
	
	// We will clear the details of the document that are not used for the business operation.
	ArrayOfAllProps = New Array;
	ArrayOfOperationDetails = New Array;
	Documents.PaymentCardTransaction.FillInNamesOfBusinessTransactionDetails(
		BusinessOperation, ArrayOfAllProps, ArrayOfOperationDetails);
	CashServer.ClearUnusedProps(
		ThisObject, ArrayOfAllProps, ArrayOfOperationDetails);
	
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
	
	// Check if there is an "Application for the return of goods from the customer" as the object of calculations, then write it down in the details of the "Basis of payment"
	// tabular part of the "Decryption of payment"
	If BusinessOperation = Enums.BusinessTransactions.RefundToCustomer Then
		For Each PaymentDecryptionString In ARAPDetails Do
			DocumentObject = Common.ObjectAttributeValue(PaymentDecryptionString.ARAPObject, "Object");
			If TypeOf(DocumentObject) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer")
				And Not ValueIsFilled(PaymentDecryptionString.PaymentPurpose) Then
				
				PaymentDecryptionString.PaymentPurpose = DocumentObject;
			EndIf;
		EndDo;
	EndIf;
	
	If Not KeepRecordsOfCommissionInARAPAccounting Then
		CommissionARAPObject = Catalogs.ARAPObjects.EmptyRef();
	EndIf;
	
	PaymentCardTransactionLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	If Not ValueIsFilled(Author) And IsNew() Then
		Author = Users.CurrentUser();
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	PaymentCardTransactionLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	PaymentCardTransactionLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	PaymentCardTransactionLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	
	PaymentCompleted = False;
	
	ARAPAccountingServer.OnCopy(ThisObject);
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "ARAPDetails");
	
	PaymentCardTransactionLocalization.OnCopy(ThisObject, CopiedObject);
	Author = Users.CurrentUser();
	EmployeeResponsible = Users.CurrentUser();

EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillInOnTheCustomerSOrder(
	Val DocumentBasis,
	FillingData)
	
	// Fill in the data of the document header.
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
	|	
	|	CASE WHEN DocumentData.Contract.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts) THEN
	|		DocumentData.Contract.CashFlowItem
	|	ELSE
	|		CASE WHEN ISNULL(DocumentData.Contract.CashFlowItem, VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef) THEN
	|			CAST(DocumentData.Terms AS Catalog.TermsOfSale).CashFlowItem
	|		ELSE
	|			DocumentData.Contract.CashFlowItem
	|		END
	|	END AS CashFlowItem,
	|	
	|	DocumentData.Currency  AS Currency,
	|	DocumentData.BankAccount AS BankAccount,
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer) AS BusinessOperation
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
			NStr("vi = 'Không cần nhập giao dịch thẻ thanh toán trên cơ sở chứng từ %1';
				|ru = 'Не требуется вводить эквайринговую операцию на основании документа %1';
				|en = 'Generating an acquiring transaction from base document %1 is not required'; fa = 'Generating an acquiring transaction from base document %1 is not required';
				|it = 'Non è necessario immettere l''operazione di acquiring in base al documento %1';
				|pl = 'Nie jest wymagane wprowadzenie operacji przez centrum autoryzacyjny na podstawie dokumentu %1';
				|tr = '%1 belgesine dayalı PoS işlemini girmek gerekli değildir.'"),
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
			Enums.PaymentForms.PaymentCard,
			FillingData);
		
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

Procedure FillInInvoiceForPaymentToClient(
	Val DocumentBasis,
	FillingData)
	
	// Fill in the data of the document header.
	QueryText = "
	|SELECT
	|	CASE WHEN DocumentData.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.BankAccount.Owner
	|	WHEN DocumentData.CashAccount <> VALUE(Catalog.CashAccounts.EmptyRef) THEN
	|		DocumentData.CashAccount.Owner
	|	ELSE
	|		DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.DocumentBasis.Counterparty AS Counterparty,
	|	DocumentData.DocumentBasis AS SalesOrder,
	|	DocumentData.Contract AS Contract,
	|	
	|	CASE WHEN DocumentData.Contract.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts) THEN
	|		DocumentData.Contract.CashFlowItem
	|	ELSE
	|		CASE WHEN ISNULL(DocumentData.Contract.CashFlowItem, VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef) THEN
	|			CAST(DocumentData.DocumentBasis.Terms AS Catalog.TermsOfSale).CashFlowItem
	|		ELSE
	|			DocumentData.Contract.CashFlowItem
	|		END
	|	END AS CashFlowItem,
	|	
	|	DocumentData.Currency  AS Currency,
	|	DocumentData.BankAccount AS BankAccount,
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
		
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(
			Enums.PaymentForms.PaymentCard,
			FillingData);
		ARAPAccountingServer.FillInTranscriptOfPaymentOnInvoice(
			DocumentBasis,
			Selection.Organization,
			Selection.SalesOrder,
			FillingData.Currency,
			ARAPDetails);
	EndIf;
	
	// Filling in the amount of the document header
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure

Procedure ServicesForSaleOfGoods(
	Val DocumentBasis,
	FillingData)
	
	// Fill in the data of the document header.
	QueryText = "
	|SELECT
	|	CASE WHEN DocumentData.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.CompanyBankAccount.Owner
	|	WHEN DocumentData.CashAccount <> VALUE(Catalog.CashAccounts.EmptyRef) THEN
	|		DocumentData.CashAccount.Owner
	|	ELSE
	|		DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	ISNULL(DocumentData.Contract.ContractType, VALUE(Enum.ContractTypes.EmptyRef)) AS ContractTypeOfContract,
	|	ISNULL(DocumentData.Contract.ConsignmentSales25, FALSE) AS ContractCommissionSales25,
	|	ISNULL(DocumentData.Contract.ConductARAPAccountingThroughEndCustomers, FALSE) AS ContractToConductSettlementsThroughEndCustomers,
	|	DocumentData.Ref AS DocumentBasis,
	|	DocumentData.ARAPObjectSettings AS ARAPObjectSettings,
	|	DocumentData.OrderSales AS OrderSales,
	|	
	|	CASE WHEN DocumentData.Contract.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts) THEN
	|		DocumentData.Contract.CashFlowItem
	|	ELSE
	|		CASE WHEN ISNULL(DocumentData.Contract.CashFlowItem, VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef) THEN
	|			CAST(DocumentData.Terms AS Catalog.TermsOfSale).CashFlowItem
	|		ELSE
	|			DocumentData.Contract.CashFlowItem
	|		END
	|	END AS CashFlowItem,
	|	
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.AmountARAP AS AmountARAP,
	|	DocumentData.AmountARAP AS Sum,
	|	
	|	DocumentData.Currency AS Currency,
	|	DocumentData.CompanyBankAccount AS BankAccount,
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer) AS BusinessOperation
	|FROM
	|	Document.CustomerInvoice AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
	|";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhập giao dịch thẻ thanh toán trên cơ sở chứng từ %1';
				|ru = 'Не требуется вводить эквайринговую операцию на основании документа %1';
				|en = 'Generating an acquiring transaction from base document %1 is not required'; fa = 'Generating an acquiring transaction from base document %1 is not required';
				|it = 'Non è necessario immettere l''operazione di acquiring in base al documento %1';
				|pl = 'Nie jest wymagane wprowadzenie operacji przez centrum autoryzacyjny na podstawie dokumentu %1';
				|tr = '%1 belgesine dayalı PoS işlemini girmek gerekli değildir.'"),
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
			Enums.PaymentForms.PaymentCard, FillingData);
			
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
			
			Result = CashServer.PayChartLines(GraphLines, "PaymentCardTransaction");
			
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
			
			AmountToPay = Selection.Sum;
			
			ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(
				ParametersForFillingInDecryption, ARAPDetails, AmountToPay);
		
		EndIf;
		
	EndIf;
	
	// Filling in the amount of the document header
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure

Procedure ActivitiesForSaleOfServicesOfOtherAssets(
	Val DocumentBasis,
	FillingData)
	
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
	|	UNDEFINED AS CashAccount,
	|	DocumentData.CompanyBankAccount AS BankAccount
	|FROM
	|	Document.CustomerInvoiceServicesAndAssets AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
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
		
		ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
		ParametersForFillingInDecryption.SalesOrder     = DocumentBasis;
		ParametersForFillingInDecryption.Contract          = Selection.Contract;
		ParametersForFillingInDecryption.DocumentCurrency  = FillingData.Currency;
		ParametersForFillingInDecryption.Partner          = Selection.Partner;
		ParametersForFillingInDecryption.PaymentPurpose = DocumentBasis;
		ParametersForFillingInDecryption.CashFlowItem = Selection.CashFlowItem;

		AmountToPay = Selection.Sum;

		ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(
			ParametersForFillingInDecryption,
			ARAPDetails,
			AmountToPay);
		
	EndIf;
	
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure

Procedure FillInActOfWorkPerformed(
	Val DocumentBasis,
	FillingData)
	
	// Fill in the data of the document header.
	QueryText = "
	|SELECT
	|	CASE WHEN DocumentData.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|		DocumentData.CompanyBankAccount.Owner
	|	WHEN DocumentData.CashAccount <> VALUE(Catalog.CashAccounts.EmptyRef) THEN
	|		DocumentData.CashAccount.Owner
	|	ELSE
	|		DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Ref AS DocumentBasis,
	|	DocumentData.ARAPObjectSettings AS ARAPObjectSettings,
	|	
	|	CASE WHEN DocumentData.Contract.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts) THEN
	|		DocumentData.Contract.CashFlowItem
	|	ELSE
	|		CASE WHEN ISNULL(DocumentData.Contract.CashFlowItem, VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef) THEN
	|			CAST(DocumentData.Terms AS Catalog.TermsOfSale).CashFlowItem
	|		ELSE
	|			DocumentData.Contract.CashFlowItem
	|		END
	|	END AS CashFlowItem,
	|	
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.AmountARAP AS AmountARAP,
	|	DocumentData.AmountARAP AS Sum,
	|	
	|	DocumentData.Currency AS Currency,
	|	DocumentData.CompanyBankAccount AS BankAccount,
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer) AS BusinessOperation
	|FROM
	|	Document.CustomerInvoiceServices AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhập giao dịch thẻ thanh toán trên cơ sở chứng từ %1';
				|ru = 'Не требуется вводить эквайринговую операцию на основании документа %1';
				|en = 'Generating an acquiring transaction from base document %1 is not required'; fa = 'Generating an acquiring transaction from base document %1 is not required';
				|it = 'Non è necessario immettere l''operazione di acquiring in base al documento %1';
				|pl = 'Nie jest wymagane wprowadzenie operacji przez centrum autoryzacyjny na podstawie dokumentu %1';
				|tr = '%1 belgesine dayalı PoS işlemini girmek gerekli değildir.'"),
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
			Enums.PaymentForms.PaymentCard, FillingData);
		
		GraphLines = New Array;
		
		If (Selection.ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments
			Or Selection.ARAPObjectSettings = Enums.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice) Then
			GraphLines = CashServer.ScheduleLinesForPayment(Selection.DocumentBasis);
		EndIf;
		
		If GraphLines.Count() Then
			
			Result = CashServer.PayChartLines(GraphLines, "PaymentCardTransaction");
			
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
			
			AmountToPay = Selection.Sum;
			
			ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(
				ParametersForFillingInDecryption, ARAPDetails, AmountToPay);
			
		EndIf;
		
	EndIf;
	
	// Filling in the amount of the document header
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure

Procedure InstructionsForReturningGoodsFromClient(
	Val DocumentBasis, FillingData)
	
	// Fill in the data of the document header.
	Query = New Query("
	|SELECT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.DocumentAmount AS Sum,
	|	DocumentData.RequestForReturnOfGoodsFromCustomer AS RequestForReturnOfGoodsFromCustomer,
	|	&Ref AS DocumentBasis,
	|
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
			NStr("vi = 'Không cần nhập giao dịch thẻ thanh toán trên cơ sở chứng từ %1';
				|ru = 'Не требуется вводить эквайринговую операцию на основании документа %1';
				|en = 'Generating an acquiring transaction from base document %1 is not required'; fa = 'Generating an acquiring transaction from base document %1 is not required';
				|it = 'Non è necessario immettere l''operazione di acquiring in base al documento %1';
				|pl = 'Nie jest wymagane wprowadzenie operacji przez centrum autoryzacyjny na podstawie dokumentu %1';
				|tr = '%1 belgesine dayalı PoS işlemini girmek gerekli değildir.'"),
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
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(Enums.PaymentForms.PaymentCard, FillingData);
		
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

Procedure InstructionsForRedemptionOfGoodsByCustodian(Val DocumentBasis, FillingData)
	
	// Fill in the data of the document header.
	Query = New Query;
	Query.Text =
	"SELECT
	|	DocumentData.Partner              AS Partner,
	|	DocumentData.Counterparty           AS Counterparty,
	|	CASE
	|		WHEN ISNULL(BankAccounts.Ref, VALUE(Catalog.CompaniesBankAccounts.EmptyRef)) <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
	|			THEN BankAccounts.Owner
	|		WHEN ISNULL(CashAccounts.Ref, VALUE(Catalog.CashAccounts.EmptyRef)) <> VALUE(Catalog.CashAccounts.EmptyRef)
	|			THEN CashAccounts.Owner
	|		ELSE DocumentData.Organization
	|	END                                AS Organization,
	|	DocumentData.Contract              AS Contract,
	|	CASE
	|		WHEN ISNULL(CounterpartyContracts.ARAPObjectSettings, VALUE(Enum.ARAPObjectSettings.EmptyRef)) = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
	|			THEN CounterpartyContracts.CashFlowItem
	|		ELSE
	|			CASE
	|				WHEN ISNULL(CounterpartyContracts.CashFlowItem, VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef)
	|					THEN ISNULL(TermsOfSale.CashFlowItem, VALUE(Catalog.CashFlowReportItems.EmptyRef))
	|				ELSE CounterpartyContracts.CashFlowItem
	|			END
	|	END                                AS CashFlowItem,
	|	DocumentData.Currency               AS Currency,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.AmountARAP  AS Sum,
	|	DocumentData.AmountARAP  AS AmountARAP,
	|	DocumentData.CompanyBankAccount AS BankAccount,
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer) AS BusinessOperation
	|FROM
	|	Document.RedemptionOfGoodsByCustodian AS DocumentData
	|		LEFT JOIN Catalog.CompaniesBankAccounts AS BankAccounts
	|		ON DocumentData.CompanyBankAccount = BankAccounts.Ref
	|		
	|		LEFT JOIN Catalog.CashAccounts AS CashAccounts
	|		ON DocumentData.CashAccount = CashAccounts.Ref
	|	
	|		LEFT JOIN Catalog.CounterpartyContracts AS CounterpartyContracts
	|		ON DocumentData.Contract = CounterpartyContracts.Ref
	|	
	|		LEFT JOIN Catalog.TermsOfSale AS TermsOfSale
	|		ON DocumentData.Terms = TermsOfSale.Ref
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		
		MessageText = NStr("vi = 'Không cần nhập giao dịch thẻ thanh toán trên cơ sở chứng từ %1';
							|ru = 'Не требуется вводить эквайринговую операцию на основании документа %1';
							|en = 'Generating an acquiring transaction from base document %1 is not required'; fa = 'Generating an acquiring transaction from base document %1 is not required';
							|it = 'Non è necessario immettere l''operazione di acquiring in base al documento %1';
							|pl = 'Nie jest wymagane wprowadzenie operacji przez centrum autoryzacyjny na podstawie dokumentu %1';
							|tr = '%1 belgesine dayalı PoS işlemini girmek gerekli değildir.'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, DocumentBasis);
		
		Raise MessageText;
		
	Else
		
		FillingData = New Structure;
		
		For Each Column In QueryResult.Columns Do
			FillingData.Insert(Column.Name);
		EndDo;
	
		Selection = QueryResult.Select();
		
		Selection.Next();
		FillPropertyValues(FillingData, Selection);
		
		CashServer.FillInDetailsOfDocumentOnFormOfPayment(Enums.PaymentForms.PaymentCard,
			FillingData);
		
		ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
		ParametersForFillingInDecryption.SalesOrder     = DocumentBasis;
		ParametersForFillingInDecryption.Contract          = Selection.Contract;
		ParametersForFillingInDecryption.DocumentCurrency  = FillingData.Currency;
		ParametersForFillingInDecryption.Partner          = Selection.Partner;
		ParametersForFillingInDecryption.PaymentPurpose = DocumentBasis;
		ParametersForFillingInDecryption.CashFlowItem = Selection.CashFlowItem;
		
		ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(ParametersForFillingInDecryption, ARAPDetails);
		
	EndIf;
	
	// Filling in the amount of the document header
	DocumentAmount = ARAPDetails.Total("Sum");
	
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
	AllowedStatuses.Add(Enums.GiftCertificateStatuses.NotActivated);
	AllowedStatuses.Add(Enums.GiftCertificateStatuses.Activated);
	AllowedStatuses.Add(Enums.GiftCertificateStatuses.PartiallyRepaid);
	
	If AllowedStatuses.Find(GiftCertificateStatus) = Undefined Then
		Text = NStr("vi = 'Giao dịch này được hỗ trợ đối với phiếu quà tặng có trạng thái: ""Không kích hoạt"", ""Đã kích hoạt"", ""Đã thanh toán một phần"".';
					|ru = 'Данная операция поддерживается для подарочных сетификатов в статусе: ""Не активирован"", ""Активирован"", ""Частично погашен"".';
					|en = 'This transaction is supported for gift cards with the following status: Not activated, Activated, or Used partially.'; fa = 'This transaction is supported for gift cards with the following status: Not activated, Activated, or Used partially.';
					|it = 'Questa operazione viene supportata per i buoni regalo con stato: ""Non attivato"", ""Attivato"", ""Parzialmente rimborsato"".';
					|pl = 'Ta operacja jest obsługiwana dla certyfikatów podarunkowych ze statusem: ""Nie aktywowany"", ""Aktywowany"", ""Częściowo spłacony"".';
					|tr = 'Bu işlem şu durumdaki hediye sertifikaları için desteklenir: ""Etkinleştirilmedi"", ""Etkinleştirildi"", ""Kısmen geri ödendi"".'");
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
	
	If GiftCertificateDetails.ActivationStatus = False Then
		BusinessOperation = PredefinedValue("Enum.BusinessTransactions.CashReceiptFromCustomer");
	Else
		BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RefundToCustomer");
	EndIf;
	
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
	
	If BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer Then
		NewRow.CashFlowItem = GiftCertificateDetails.CashFlowItemSale;
	Else
		NewRow.CashFlowItem = GiftCertificateDetails.CashFlowItemReturn;
	EndIf;
	
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


Procedure FillInReportToGiver2_5(Val DocumentBasis, FillingData)
	
	// Fill in the data of the document header.
	QueryText = "SELECT
	|	CASE
	|		WHEN DocumentData.CompanyBankAccount <>
	|									VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
	|			THEN DocumentData.CompanyBankAccount.Owner
	|		WHEN DocumentData.CashAccount <> VALUE(Catalog.CashAccounts.EmptyRef)
	|			THEN DocumentData.CashAccount.Owner
	|		ELSE DocumentData.Organization
	|	END                                                                   AS Organization,
	|	DocumentData.Partner                                                 AS Partner,
	|	DocumentData.Counterparty                                              AS Counterparty,
	|	DocumentData.Contract                                                 AS Contract,
	|	DocumentData.Contract.CashFlowItem                   AS CashFlowItem,
	|	DocumentData.ARAPCurrency                                    AS ARAPCurrency,
	|	DocumentData.AmountARAP                                     AS AmountARAP,
	|	DocumentData.AmountARAP                                     AS Sum,
	|	DocumentData.Currency                                                  AS Currency,
	|	DocumentData.CompanyBankAccount                               AS BankAccount,
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer) AS BusinessOperation
	|FROM
	|	Document.ReportToMaterialProvider2_5 AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhập giao dịch thẻ thanh toán trên cơ sở chứng từ %1';
				|ru = 'Не требуется вводить эквайринговую операцию на основании документа %1';
				|en = 'Generating an acquiring transaction from base document %1 is not required'; fa = 'Generating an acquiring transaction from base document %1 is not required';
				|it = 'Non è necessario immettere l''operazione di acquiring in base al documento %1';
				|pl = 'Nie jest wymagane wprowadzenie operacji przez centrum autoryzacyjny na podstawie dokumentu %1';
				|tr = '%1 belgesine dayalı PoS işlemini girmek gerekli değildir.'"),
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
			Enums.PaymentForms.PaymentCard, FillingData);
		
		Query = New Query;
		Query.Text =
		"SELECT DISTINCT
		|	ProductTable.MaterialProviderOrder AS SalesOrder
		|FROM
		|	Document.ReportToMaterialProvider2_5.ManufacturedProduct AS ProductTable
		|WHERE
		|	ProductTable.Ref = &Ref";
		
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
		
		ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(
			ParametersForFillingInDecryption, ARAPDetails);
		
	EndIf;
	
	// Filling in the amount of the document header
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure
Procedure FillByArrayOfBases(FillingData, ArrayOfBases)
	
	CashServer.FillInDetailsOfDocumentOnFormOfPayment(Enums.PaymentForms.PaymentCard, FillingData);
	
	For Each BaseString In ArrayOfBases Do
		
		If TypeOf(BaseString.PaymentObject) = Type("CatalogRef.LoanAndDepositContracts") Then
			Continue;
		EndIf;
		
		ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
		FillPropertyValues(ParametersForFillingInDecryption, BaseString);
		ParametersForFillingInDecryption.DocumentCurrency = FillingData.Currency;
		
		ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(
			ParametersForFillingInDecryption,
			ARAPDetails,
			BaseString.AmountToPay);
	EndDo;
	
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure

Procedure InitializeDocument(FillingData = Undefined)
	
	If ValueIsFilled(AcquiringContract) Then
		
		AttributesValues = Catalogs.AcquiringContracts.ContractDetails_(AcquiringContract);
		Organization = AttributesValues.Organization;
		Currency = AttributesValues.Currency;
		ReflectCommissionUnderAcquiringContract(AttributesValues);
		
	ElsIf ValueIsFilled(POSTerminal) Then
		
		AttributesValues = Catalogs.POSTerminals.GetDetailsOfAcquiringTerminal(POSTerminal);
		Organization = AttributesValues.Organization;
		Currency = AttributesValues.Currency;
		
	ElsIf TypeOf(FillingData) = Type("Structure") And FillingData.Property("Organization") Then
		
		FilterParameters = Catalogs.AcquiringContracts.ParametersOfAcquisitionContractSelection();
		
		FilterParameters.Organization = FillingData.Organization;
		AcquiringContract = Catalogs.AcquiringContracts.ContractOfAcquiringByDefault(FilterParameters);
		POSTerminal = Catalogs.POSTerminals.DefaultPOSTerminal(
			FillingData.Organization, AcquiringContract);
		
		AcquiringContractDetails = Catalogs.AcquiringContracts.ContractDetails_(AcquiringContract);
		ReflectCommissionUnderAcquiringContract(AcquiringContractDetails);
		
	EndIf;
	
	If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("Organization") Then
		Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	EndIf;
	
	If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("Currency") Then
		If Not ValueIsFilled(Currency) Then
			Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
		EndIf;
	EndIf;
	
	If TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("DocumentBasisOfApplication")
		And ValueIsFilled(FillingData.DocumentBasisOfApplication) Then
		DocumentBasis = FillingData.DocumentBasisOfApplication;
	EndIf;
	
	If TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("FPSPaymentID") Then
		FPSPaymentID = FillingData.FPSPaymentID;
	EndIf;
	
	If TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("BusinessOperation") Then
		CashServer.FillInCashFlowItem(
			ThisObject, FillingData, FillingData.BusinessOperation);
	Else
		CashServer.FillInCashFlowItem(
			ThisObject, FillingData, Enums.BusinessTransactions.CashReceiptFromCustomer);
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

Procedure FillInByCustomerSOrder_Refund(FillingData)
	
	FillingData = CashServer.GenerateFillInDataForReturningPaymentFromCustomerSOrder(FillingData.Basis, 
							Metadata.Documents.PaymentCardTransaction.Presentation(),
							Enums.PaymentForms.PaymentCard);
							
	CashServer.FillInTranscriptOfPaymentOnClientSOrder(FillingData, ARAPDetails);
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure

Procedure InformationOnAcquiringOperation(FillingData)
	
	DocumentBasis = FillingData.Basis;
	
	FillingData = CashServer.FillingDataForRefundOfAcquiringTransactionPayment(DocumentBasis);
	If ValueIsFilled(DocumentBasis) Then
		AcquiringContract = FillingData.AcquiringContract;
	EndIf;
	
	CashServer.FillInPaymentTranscriptForPaymentDocument(DocumentBasis, FillingData.BusinessOperation, ARAPDetails);
	
	DocumentAmount = ARAPDetails.Total("Sum");
	
EndProcedure

Procedure ReflectCommissionUnderAcquiringContract(AttributesOfAcquiringContract)
	
	If BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer Then
		RecordCommission = (AttributesOfAcquiringContract.CommissionPostingMethod = Enums.MethodsOfAcquiringCommissionRecording.DuringTransaction);
	ElsIf BusinessOperation = Enums.BusinessTransactions.RefundToCustomer Then
		RecordCommission = (AttributesOfAcquiringContract.CommissionPostingMethod = Enums.MethodsOfAcquiringCommissionRecording.DuringTransaction)
			And AttributesOfAcquiringContract.FeeIsChargedOnRefund;
	EndIf;
	
	If ValueIsFilled(AttributesOfAcquiringContract.ExpensesBusinessUnit) Then
		Department = AttributesOfAcquiringContract.ExpensesBusinessUnit;
	EndIf;
	
	If RecordCommission Then
	
		If AttributesOfAcquiringContract.FixedFeeRate Then
			CommissionRate = AttributesOfAcquiringContract.CommissionRate;
			FeeAmount = CashClientServer.CalculateCommissionAmount(DocumentAmount, CommissionRate);
		Else
			CommissionRate = 0;
		EndIf;
		FillPropertyValues(ThisObject, AttributesOfAcquiringContract, "ExpenseItem, DimensionOfExpenses,
			|KeepRecordsOfCommissionInARAPAccounting, CommissionARAPObject");
	EndIf;
	
EndProcedure

#EndRegion

Procedure CheckRepaymentDates(Cancel) Export
	
	For Each DecryptionString In ARAPDetails Do
		If ValueIsFilled(DecryptionString.MaturityDate)
			And DecryptionString.MaturityDate < BegOfDay(Date) Then
			
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
				ErrorDataPath = "Object.ARAPDetails" + "[" + (DecryptionString.LineNumber - 1) + "].MaturityDate";
			EndIf;
			Common.MessageToUser(ErrorText, , ErrorDataPath, , Cancel);
			
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#EndIf
