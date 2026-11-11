#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Posting

// Generates parameters for conducting a document on the registers of the accounting mechanism through the General mechanism of conducting.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  Properties - See DocumentsPosting.DocumentProperties
//
// Returns:
//  Structure - See DocumentsPosting.ParametersOfAccountingMechanism
//
Function ParametersForHoldingDocument(Document, Properties) Export
	
	Parameters = DocumentsPosting.ParametersOfAccountingMechanism();
	
	If Properties.WriteMode = DocumentWriteMode.Posting
		Or Properties.WriteMode = DocumentWriteMode.UndoPosting Then
		
		Parameters.IndependentRegisters.Add(Metadata.InformationRegisters.ScheduleOfPayments);
	EndIf;
	
	Return Parameters;
	
EndFunction

// Complements the request text of the mechanism for checking the ban date by the table of changes.
// 
// Parameters:
// 	Query - Query - used for setting request parameters.
// 
// Returns:
//	Map - matching the names of the register change tables and query texts.
//	
Function QueryTextsMonitoringBanDateBasedOnChangesTable(Query) Export

	MatchingQueryTexts = New Map();
	Return MatchingQueryTexts;
	
EndFunction

#EndRegion

// To record a graph, it imposes a lock on the table that the graph depends on
// 
// Parameters:
//    TableOfPaymentObjects - ValueTable - table with columns:
//        * PaymentObject - DefinedType.PaymentObject - paid object
//        * ARAPObject - DefinedType.ARAPObject - the object in the context of which calculations are performed
//    TableName - String - blocked table
//    FieldName - String - field of the blocked table
//    ColumnName - String - field in the payment object table used for blocking
//
Procedure SetDataLocksForGraphCalculation(TableOfPaymentObjects, TableName, FieldName, ColumnName = "PaymentObject") Export
	
	Block = New DataLock;
	LockItem = Block.Add(TableName);
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.DataSource = TableOfPaymentObjects;
	LockItem.UseFromDataSource(FieldName, ColumnName);
	Block.Lock();
	
EndProcedure

// Calculates and records the schedule for settlements with clients
//
// Parameters:
//    TableOfPaymentObjects - ValueTable - table with columns:
//        * PaymentObject - DefinedType.PaymentObject - paid object
//        * ARAPObject - DefinedType.ARAPObject - the object in the context of which calculations are performed
//    Queue - Number - queue number when updating data
//
Procedure CalculatePaymentScheduleForSettlementsWithCustomers(TableOfPaymentObjects, Queue = Undefined) Export
	
	NewOnlineARAPAccounting = GetFunctionalOption("NewOnlineARAPAccounting");
	
	NotProcessed = UnprocessedDocuments_();
	LinesToDelete = New Array;
	For Each TableRow In TableOfPaymentObjects Do
		If NotProcessed.Find(TypeOf(TableRow.PaymentObject)) <> Undefined Then
			LinesToDelete.Add(TableRow);
		EndIf;
	EndDo;
	For Each TableRow In LinesToDelete Do
		TableOfPaymentObjects.Delete(TableRow);
	EndDo;
	
	PaymentLines = New Array;
	ReturnLines = New Array;
	
	For Each TableRow In TableOfPaymentObjects Do
		If TypeOf(TableRow.PaymentObject) = Type("DocumentRef.ReturnOfGoodsFromCustomer")
			Or TypeOf(TableRow.PaymentObject) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
			ReturnLines.Add(TableRow);
		Else
			PaymentLines.Add(TableRow);
		EndIf;
	EndDo;
	
	If PaymentLines.Count() Then
		
		If NewOnlineARAPAccounting Then
			QueryText = RequestTextPaymentScheduleForSettlementsWithCustomersNewArchitecture();
		Else
			QueryText = RequestTextPaymentScheduleForSettlementsWithCustomers();
		EndIf;
		
		RecordPaymentScheduleForSettlements(
			TableOfPaymentObjects.Copy(PaymentLines),
			QueryText,
			Enums.CashFlowTypes.Inpayment,
			Enums.PaymentPlanningAreas.CustomersARAPAccounting,
			Queue);
	EndIf;
	
	If ReturnLines.Count() Then
		
		If NewOnlineARAPAccounting Then
			QueryText = RequestTextPaymentScheduleForRefundsToCustomersNewArchitecture();
		Else
			QueryText = RequestTextPaymentScheduleForRefundsToCustomers();
		EndIf;
		
		RecordPaymentScheduleForSettlements(
			TableOfPaymentObjects.Copy(ReturnLines),
			QueryText,
			Enums.CashFlowTypes.WriteOff,
			Enums.PaymentPlanningAreas.ReturnsToCustomers,
			Queue);
	EndIf;
	
EndProcedure

// Calculates and records the schedule for settlements with suppliers
//
// Parameters:
//    TableOfPaymentObjects - ValueTable - table with columns:
//        * PaymentObject - DefinedType.PaymentObject - paid object
//        * ARAPObject - DefinedType.ARAPObject - the object in the context of which calculations are performed
//    Queue - Number - queue number when updating data
//    SkipScheduleUpdate - Boolean
//
Procedure CalculatePaymentScheduleForSettlementsWithSuppliers(TableOfPaymentObjects, Queue = Undefined,
	SkipScheduleUpdate = False) Export
	
	NewOnlineARAPAccounting = GetFunctionalOption("NewOnlineARAPAccounting");
	
	NotProcessed = UnprocessedDocuments_();
	LinesToDelete = New Array;
	PaymentObjectsContracts = New Array;
	For Each TableRow In TableOfPaymentObjects Do
		If NotProcessed.Find(TypeOf(TableRow.PaymentObject)) <> Undefined Then
			LinesToDelete.Add(TableRow);
		EndIf;
		
		If TypeOf(TableRow.PaymentObject) = Type("CatalogRef.CounterpartyContracts")
			And Not SkipScheduleUpdate Then
			PaymentObjectsContracts.Add(TableRow.PaymentObject);
		EndIf;
	EndDo;
	For Each TableRow In LinesToDelete Do
		TableOfPaymentObjects.Delete(TableRow);
	EndDo;
	
	PaymentLines = New Array;
	ReturnLines = New Array;
	
	For Each TableRow In TableOfPaymentObjects Do
		If TypeOf(TableRow.PaymentObject) = Type("DocumentRef.ReturnOfGoodsToVendor") Then
			ReturnLines.Add(TableRow);
		Else
			PaymentLines.Add(TableRow);
		EndIf;
	EndDo;
	
	If PaymentLines.Count() Then
		
		If NewOnlineARAPAccounting Then
			QueryText = RequestTextPaymentScheduleForSettlementsWithSuppliersNewArchitecture();
		Else
			QueryText = RequestTextPaymentScheduleForSettlementsWithSuppliers();
		EndIf;
		
		RecordPaymentScheduleForSettlements(
			TableOfPaymentObjects.Copy(PaymentLines),
			QueryText,
			Enums.CashFlowTypes.WriteOff,
			Enums.PaymentPlanningAreas.VendorsARAPAccounting,
			Queue);
	EndIf;
	
	If ReturnLines.Count() Then
		
		If NewOnlineARAPAccounting Then
			QueryText = RequestTextPaymentScheduleForRefundsFromSuppliersNewArchitecture();
		Else
			QueryText = RequestTextPaymentScheduleForRefundsFromSuppliers();
		EndIf;
		
		RecordPaymentScheduleForSettlements(
			TableOfPaymentObjects.Copy(ReturnLines),
			QueryText,
			Enums.CashFlowTypes.Inpayment,
			Enums.PaymentPlanningAreas.ReturnsFromVendors,
			Queue);
	EndIf;
	
	If PaymentObjectsContracts.Count() Then
		ProlongationOfRegularPayments(PaymentObjectsContracts);
	EndIf;
	
EndProcedure

// Calculates and records the schedule for funds to be paid
//
// Parameters:
//    PaymentObjects - Array of DocumentRef.PaymentRequest - requests for spending money
//    Queue - Number - queue number when updating data
//
Procedure CalculatePaymentScheduleForCashToBePaid(PaymentObjects, Queue = Undefined) Export
	
	Requests = New Array;
	BusinessTripApprovalApplications = New Array;
	References = New Array;
	
	For Each PaymentObject In PaymentObjects Do
		If TypeOf(PaymentObject) = Type("DocumentRef.PaymentRequest") Then
			Requests.Add(PaymentObject);
		ElsIf TypeOf(PaymentObject) = Type("DocumentRef.ApplicationForBusinessTrip") Then
			BusinessTripApprovalApplications.Add(PaymentObject);
		ElsIf TypeOf(PaymentObject) = Type("DocumentRef.CashTransferReferenceOrder") Then
			References.Add(PaymentObject);
		EndIf;
	EndDo;
	
	If Requests.Count() Then
		MetadataObjectID = Common.MetadataObjectID("Document.PaymentRequest");
		QueryText = RequestTextPaymentScheduleForRequests();
		RecordScheduleOfPaymentsForCashToBePaid(Requests, QueryText, MetadataObjectID, Queue);
	EndIf;
	
	If BusinessTripApprovalApplications.Count() Then
		MetadataObjectID = Common.MetadataObjectID("Document.ApplicationForBusinessTrip");
		QueryText = RequestTextPaymentScheduleForBusinessTripRequests();
		RecordScheduleOfPaymentsForCashToBePaid(BusinessTripApprovalApplications, QueryText, MetadataObjectID, Queue);
	EndIf;
	
	If References.Count() Then
		MetadataObjectID = Common.MetadataObjectID("Document.CashTransferReferenceOrder");
		QueryText = RequestTextPaymentScheduleForPaymentOrders();
		RecordScheduleOfPaymentsForCashToBePaid(References, QueryText, MetadataObjectID, Queue);
	EndIf;
	
	
EndProcedure

// Calculates and records the schedule for funds in transit
//
// Parameters:
//    TableOfPaymentObjects - ValueTable - table with columns:
//        * PaymentObject - DefinedType.PaymentObject - paid object
//        * BankAccountCashAccount - CatalogRef.CompaniesBankAccounts, CatalogRef.CashAccounts - Bank account or cash register where funds are expected to be received
//    Queue - Number - queue number when updating data
//
Procedure CalculatePaymentScheduleForCashInTransit(TableOfPaymentObjects, Queue = Undefined) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Cash.Sender AS PaymentObject,
	|	Cash.Recipient AS BankAccountCashAccount,
	|	CASE Cash.CashTransferKind
	|		WHEN VALUE(Enum.CashTransferKinds.CashDepositToBank) THEN
	|			DATEADD(&DateOfCalculation, DAY, ISNULL(CAST(Cash.Sender AS Catalog.CashAccounts).CashCollectionTerm, 0))
	|		WHEN VALUE(Enum.CashTransferKinds.CashCollectionFromBank_) THEN
	|			DATEADD(&DateOfCalculation, DAY, ISNULL(CAST(Cash.Recipient AS Catalog.CashAccounts).CashCollectionTerm, 0))
	|		WHEN VALUE(Enum.CashTransferKinds.CashTransferToOtherAccount) THEN
	|			DATEADD(&DateOfCalculation, DAY, 1)
	|		WHEN VALUE(Enum.CashTransferKinds.TransferToAnotherCashAccount) THEN
	|			DATEADD(&DateOfCalculation, DAY, ISNULL(CAST(Cash.Sender AS Catalog.CashAccounts).CashCollectionTerm, 0))
	|	END AS PaymentDate,
	|	Cash.Organization AS PayerBeneficiary,
	|	VALUE(Enum.CashFlowTypes.Inpayment) AS ReceiptIssue,
	|	Cash.CashTransferKind AS AmountType,
	|	Cash.Currency AS Currency,
	|	Cash.SumBalance AS Sum,
	|	Cash.Organization AS Organization,
	|	Cash.Recipient.Department AS Department,
	|	Cash.Recipient.LineOfBusiness AS LineOfBusiness,
	|	
	|	CASE Cash.CashTransferKind
	|		WHEN VALUE(Enum.CashTransferKinds.CashDepositToBank) THEN
	|			VALUE(Enum.BusinessTransactions.CashReceiptFromCashRegisterToBankAccount)
	|		WHEN VALUE(Enum.CashTransferKinds.CashCollectionFromBank_) THEN
	|			VALUE(Enum.BusinessTransactions.CashCollectionFromBank)
	|		WHEN VALUE(Enum.CashTransferKinds.CashTransferToOtherAccount) THEN
	|			VALUE(Enum.BusinessTransactions.CashReceiptFromAnotherAccount)
	|		WHEN VALUE(Enum.CashTransferKinds.TransferToAnotherCashAccount) THEN
	|			VALUE(Enum.BusinessTransactions.CashReceiptFromAnotherCashAccount)
	|	END AS BusinessOperation,
	|
	|	CASE Cash.CashTransferKind
	|		WHEN VALUE(Enum.CashTransferKinds.CashDepositToBank) THEN
	|			VALUE(Catalog.CashFlowReportItems.CashDepositToBankAccount)
	|		WHEN VALUE(Enum.CashTransferKinds.CashCollectionFromBank_) THEN
	|			VALUE(Catalog.CashFlowReportItems.CashReceiptFromBank)
	|		WHEN VALUE(Enum.CashTransferKinds.CashTransferToOtherAccount) THEN
	|			VALUE(Catalog.CashFlowReportItems.TransferCashToAnotherAccount)
	|		WHEN VALUE(Enum.CashTransferKinds.TransferToAnotherCashAccount) THEN
	|			VALUE(Catalog.CashFlowReportItems.CashIssueToAnotherCashAccount)
	|	END AS CashFlowItem,
	|
	|	CASE
	|		WHEN VALUETYPE(Cash.Recipient) = TYPE(Catalog.CashAccounts)
	|			OR VALUETYPE(Cash.Sender) = TYPE(Catalog.CashRegisters)
	|			OR VALUETYPE(Cash.Recipient) = TYPE(Catalog.CashRegisters) THEN
	|			VALUE(Enum.PaymentForms.CashAccountPayment_)
	|		WHEN VALUETYPE(Cash.Recipient) = TYPE(Catalog.CompaniesBankAccounts) THEN
	|			VALUE(Enum.PaymentForms.BankAccountPayment)
	|	END AS PaymentMethod,
	|	VALUE(Enum.PaymentPlanningAreas.CashInTransit) AS PlanningArea,
	|	Cash.SumBalance AS DocumentAmount,
	|	UNDEFINED AS CorrespondingCurency,
	|	Cash.Currency AS SenderSCurrency
	|INTO BalanceInTransit
	|FROM
	|	AccumulationRegister.CashInTransit.Balance(,
	|		CashTransferKind IN (
	|			VALUE(Enum.CashTransferKinds.CashDepositToBank),
	|			VALUE(Enum.CashTransferKinds.CashCollectionFromBank_),
	|			VALUE(Enum.CashTransferKinds.CashTransferToOtherAccount),
	|			VALUE(Enum.CashTransferKinds.TransferToAnotherCashAccount)
	|		)
	|		AND Recipient IN (&BankAccountCashAccount)
	|		AND Sender IN (&PaymentObject)
	|	) AS Cash
	|	
	|WHERE
	|	Cash.SumBalance > 0
	|
	|UNION ALL
	|
	|SELECT
	|	Cash.Contract AS PaymentObject,
	|	Cash.Recipient AS BankAccountCashAccount,
	|	DATEADD(&DateOfCalculation, DAY, ISNULL(Cash.Contract.PaymentPeriod, 1)) AS PaymentDate,
	|	Cash.Counterparty AS PayerBeneficiary,
	|	VALUE(Enum.CashFlowTypes.Inpayment) AS ReceiptIssue,
	|	Cash.CashTransferKind AS AmountType,
	|	Cash.Currency AS Currency,
	|	Cash.SumBalance AS Sum,
	|	Cash.Organization AS Organization,
	|	CAST(Cash.Recipient AS Catalog.CompaniesBankAccounts).Department,
	|	CAST(Cash.Recipient AS Catalog.CompaniesBankAccounts).LineOfBusiness,
	|	VALUE(Enum.BusinessTransactions.CashRecieptByAcquiringTransactionsPayment),
	|	VALUE(Catalog.CashFlowReportItems.CashReceiptFromCustomer),
	|	CASE
	|		WHEN VALUETYPE(Cash.Recipient) = TYPE(Catalog.CashAccounts) THEN
	|			VALUE(Enum.PaymentForms.CashAccountPayment_)
	|		WHEN VALUETYPE(Cash.Recipient) = TYPE(Catalog.CompaniesBankAccounts) THEN
	|			VALUE(Enum.PaymentForms.BankAccountPayment)
	|	END AS PaymentMethod,
	|	VALUE(Enum.PaymentPlanningAreas.CashInTransit) AS PlanningArea,
	|	Cash.SumBalance AS DocumentAmount,
	|	UNDEFINED AS CorrespondingCurency,
	|	Cash.Currency AS SenderSCurrency
	|FROM
	|	AccumulationRegister.CashInTransit.Balance(,
	|		CashTransferKind = VALUE(Enum.CashTransferKinds.CashReceiptFromBankByAcquiring)
	|		AND Recipient IN (&BankAccountCashAccount)
	|		AND Contract IN (&PaymentObject)
	|	) AS Cash
	|	
	|WHERE
	|	Cash.SumBalance > 0
	|
	|UNION ALL
	|
	|SELECT
	|	Cash.Counterparty AS PaymentObject,
	|	Cash.Recipient AS BankAccountCashAccount,
	|	DATEADD(&DateOfCalculation, DAY, 1) AS PaymentDate,
	|	Cash.Counterparty AS PayerBeneficiary,
	|	VALUE(Enum.CashFlowTypes.Inpayment) AS ReceiptIssue,
	|	Cash.CashTransferKind AS AmountType,
	|	Cash.Recipient.CashCurrency AS Currency,
	|	
	|	SUM(Cash.SumBalance) AS Sum,
	|	
	|	Cash.Organization AS Organization,
	|	Cash.Recipient.Department,
	|	Cash.Recipient.LineOfBusiness,
	|	VALUE(Enum.BusinessTransactions.CurrencyConversion),
	|	UNDEFINED,
	|	CASE
	|		WHEN VALUETYPE(Cash.Recipient) = TYPE(Catalog.CashAccounts) THEN
	|			VALUE(Enum.PaymentForms.CashAccountPayment_)
	|		WHEN VALUETYPE(Cash.Recipient) = TYPE(Catalog.CompaniesBankAccounts) THEN
	|			VALUE(Enum.PaymentForms.BankAccountPayment)
	|	END AS PaymentMethod,
	|	VALUE(Enum.PaymentPlanningAreas.CashInTransit) AS PlanningArea,
	|	SUM(Cash.SumBalance) AS DocumentAmount,
	|	CASE WHEN COUNT(DISTINCT Cash.Currency) = 1 THEN
	|		MAX(Cash.Currency)
	|	END AS CorrespondingCurency,
	|	Cash.Currency AS SenderSCurrency
	|FROM
	|	AccumulationRegister.CashInTransit.Balance(,
	|		CashTransferKind IN (
	|			VALUE(Enum.CashTransferKinds.ForeignExchangeBuying),
	|			VALUE(Enum.CashTransferKinds.ForeignExchangeSelling)
	|		)
	|		AND Recipient IN (&BankAccountCashAccount)
	|		AND Counterparty IN (&PaymentObject)
	|	) AS Cash
	|	
	|WHERE
	|	Cash.SumBalance > 0
	|	
	|GROUP BY
	|	Cash.Counterparty,
	|	Cash.Recipient,
	|	Cash.Organization,
	|	Cash.CashTransferKind,
	|	Cash.Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AcquiringContracts.Ref AS PaymentObject,
	|	AcquiringContracts.Number AS Number,
	|	AcquiringContracts.Date AS Date
	|FROM
	|	Catalog.AcquiringContracts AS AcquiringContracts
	|WHERE
	|	AcquiringContracts.Ref IN(&PaymentObject)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BalanceInTransit.PaymentObject AS PaymentObject,
	|	BalanceInTransit.BankAccountCashAccount AS BankAccountCashAccount,
	|	BalanceInTransit.PaymentDate AS PaymentDate,
	|	BalanceInTransit.PayerBeneficiary AS PayerBeneficiary,
	|	BalanceInTransit.ReceiptIssue AS ReceiptIssue,
	|	BalanceInTransit.AmountType AS AmountType,
	|	BalanceInTransit.Currency AS Currency,
	|	BalanceInTransit.Sum AS Sum,
	|	BalanceInTransit.Organization AS Organization,
	|	BalanceInTransit.Department AS Department,
	|	BalanceInTransit.LineOfBusiness AS LineOfBusiness,
	|	BalanceInTransit.BusinessOperation AS BusinessOperation,
	|	BalanceInTransit.CashFlowItem AS CashFlowItem,
	|	BalanceInTransit.PaymentMethod AS PaymentMethod,
	|	BalanceInTransit.PlanningArea AS PlanningArea,
	|	BalanceInTransit.DocumentAmount AS DocumentAmount,
	|	BalanceInTransit.CorrespondingCurency AS CorrespondingCurency,
	|	BalanceInTransit.SenderSCurrency AS SenderSCurrency
	|FROM
	|	BalanceInTransit AS BalanceInTransit
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RelativeExchangeRatesSliceLast.Currency AS Currency,
	|	RelativeExchangeRatesSliceLast.CourseNumerator AS CourseNumerator,
	|	RelativeExchangeRatesSliceLast.CourseDenominator AS CourseDenominator
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(
	|			&DateOfCalculation,
	|			(Currency, BaseCurrency) IN
	|				(SELECT
	|					BalanceInTransit.SenderSCurrency,
	|					&BaseCurrency
	|				FROM
	|					BalanceInTransit AS BalanceInTransit
	|				UNION
	|				
	|				SELECT
	|					BalanceInTransit.Currency,
	|					&BaseCurrency
	|				FROM
	|					BalanceInTransit AS BalanceInTransit)) AS RelativeExchangeRatesSliceLast
	|";
	
	Query.SetParameter("PaymentObject", TableOfPaymentObjects.UnloadColumn("PaymentObject"));
	Query.SetParameter("BankAccountCashAccount", TableOfPaymentObjects.UnloadColumn("BankAccountCashAccount"));
	Query.SetParameter("DateOfCalculation", EndOfDay(CurrentSessionDate()));
	Query.SetParameter("BaseCurrency", SettingsValueCached.DefaultBaseCurrency());
	
	Results = Query.ExecuteBatch();
	SelectionOfInformationAboutContracts = Results[Results.UBound() - 2].Select();
	Selection                   = Results[Results.UBound() - 1].Select();
	ExchangeRates                = Results[Results.UBound()].Unload();
	
	For Each PaymentObjectLine In TableOfPaymentObjects Do
		
		TheStructureOfTheSearch = New Structure;
		TheStructureOfTheSearch.Insert("PaymentObject", PaymentObjectLine.PaymentObject);
		TheStructureOfTheSearch.Insert("BankAccountCashAccount", PaymentObjectLine.BankAccountCashAccount);
		
		RecordSet = InformationRegisters.ScheduleOfPayments.CreateRecordSet();
		RecordSet.Filter.PaymentObject.Set(PaymentObjectLine.PaymentObject);
		RecordSet.Filter.BankAccountCashAccount.Set(PaymentObjectLine.BankAccountCashAccount);
		RecordSet.Clear();
		
		ThisIsAcquiringContract = SelectionOfInformationAboutContracts.FindNext(New Structure("PaymentObject", PaymentObjectLine.PaymentObject));
		
		While Selection.FindNext(TheStructureOfTheSearch) Do
			
			Record = RecordSet.Add();
			FillPropertyValues(Record, Selection);
			
			Record.PaymentObjectType = Common.MetadataObjectID(Common.TableNameByRef(Selection.PaymentObject));
			
			If Not ValueIsFilled(Record.CashFlowItem) Then
				Record.CashFlowItem =
					Catalogs.CashFlowReportItems.CashFlowItemForBusinessTransaction(Record.BusinessOperation);
			EndIf;
			
			If ThisIsAcquiringContract Then
				FillPropertyValues(Record, SelectionOfInformationAboutContracts);
			EndIf;
			
			If Selection.AmountType = Enums.CashTransferKinds.ForeignExchangeBuying
				Or Selection.AmountType = Enums.CashTransferKinds.ForeignExchangeSelling Then
				
				SenderSCourseParameters = CurrencyExchangeRate(ExchangeRates, Selection.SenderSCurrency);
				RecipientSCourseParameters = CurrencyExchangeRate(ExchangeRates, Selection.Currency);
				
				Record.Sum = ProcessingOfExchangeRatesTM.ConvertAtRate(Record.Sum, SenderSCourseParameters, RecipientSCourseParameters);
				
			EndIf;
			
			Record.Id = New UUID();
			FillInOriginalAttributes(Record);
		EndDo;
		Selection.Reset();
		SelectionOfInformationAboutContracts.Reset();
		
		BeginTransaction();
		Try
			If Queue <> Undefined Then
				InfobaseUpdate.WriteData(RecordSet);
			Else
				RecordSet.Write();
			EndIf;
			CommitTransaction();
		Except
			RollbackTransaction();
			MessageText = NStr("vi = 'Không thể ghi lịch thanh toán cho:%1 do: %2';
								|ru = 'Не удалось записать график платежей по: %1 по причине: %2';
								|en = 'Cannot save a payment schedule for: %1. Reason: %2'; fa = 'Cannot save a payment schedule for: %1. Reason: %2';
								|it = 'Non è stato possibile salvare il grafico di pagamento per: %1 a causa: %2';
								|pl = 'Nie udało się zapisać harmonogramu płatności: %1 z powodu: %2';
								|tr = '%1 ile ilgili %2 nedenler sebebi ile ödeme planı kaydedilemedi'");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				MessageText, PaymentObjectLine.PaymentObject, DetailErrorDescription(ErrorInfo()));
			
			WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Warning,,
				PaymentObjectLine.PaymentObject, MessageText);
			Raise;
		EndTry;
	EndDo;
	
EndProcedure

// Calculates and records the acquiring schedule
//
Procedure CalculatePaymentScheduleForReceiptsFromBankForAcquiring() Export
	
	Query = New Query;
	Query.Text ="
	|SELECT
	|	Table.PaymentObject,
	|	Table.BankAccountCashAccount
	|FROM
	|	(SELECT
	|		RegisterData.Contract AS PaymentObject,
	|		RegisterData.Recipient AS BankAccountCashAccount,
	|		RegisterData.SumBalance AS Sum
	|	FROM
	|		AccumulationRegister.CashInTransit.Balance(,
	|			CashTransferKind = VALUE(Enum.CashTransferKinds.CashReceiptFromBankByAcquiring)
	|			AND Contract <> VALUE(Catalog.AcquiringContracts.EmptyRef)
	|		) AS RegisterData
	|	WHERE
	|		RegisterData.SumBalance > 0
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RegisterData.PaymentObject AS PaymentObject,
	|		RegisterData.BankAccountCashAccount AS BankAccountCashAccount,
	|		-RegisterData.Sum AS Sum
	|	FROM
	|		InformationRegister.ScheduleOfPayments AS RegisterData
	|	WHERE	
	|		RegisterData.AmountType = VALUE(Enum.CashTransferKinds.CashReceiptFromBankByAcquiring)
	|		AND RegisterData.ReceiptIssue = VALUE(Enum.CashFlowTypes.Inpayment)
	|	) AS Table
	|GROUP BY
	|	Table.PaymentObject,
	|	Table.BankAccountCashAccount
	|HAVING
	|	SUM(Table.Sum) <> 0
	|";
	
	Result = Query.Execute();
	
	If Not Result.IsEmpty() Then
		InformationRegisters.ScheduleOfPayments.CalculatePaymentScheduleForCashInTransit(Result.Unload());
	EndIf;
	
EndProcedure

// Calculate and record the schedule for the settlement of financial instruments
//
// Parameters:
//    PaymentObjects - Array of CatalogRef.LoanAndDepositContracts, CatalogRef.LeaseContract - contracts for which payment is planned
//    AddnlParameter_ - Arbitrary - additional data for calculation.
//    Queue - Number - queue number when updating data
//
Procedure CalculatePaymentScheduleForFinancialInstruments(PaymentObjects, AddnlParameter_ = Undefined, Queue = Undefined) Export
	
	LoanDepositAgreements_ = New Array;
	LeaseContract = New Array;
	For Each PaymentObject In PaymentObjects Do
		If TypeOf(PaymentObject) = Type("CatalogRef.LoanAndDepositContracts") Then
			LoanDepositAgreements_.Add(PaymentObject);
		ElsIf TypeOf(PaymentObject) = Type("CatalogRef.LeaseContract") Then
			LeaseContract.Add(PaymentObject);
		EndIf;
	EndDo;
	
	If LoanDepositAgreements_.Count() Then
		MetadataObjectID = Common.MetadataObjectID("Catalog.LoanAndDepositContracts");
		QueryText = RequestTextScheduleOfPaymentsUnderLoanAndDepositAgreements();
		RecordPaymentScheduleForFinancialInstruments(
			LoanDepositAgreements_, 
			QueryText, 
			MetadataObjectID, 
			Queue,
			3);
	EndIf;
	If LeaseContract.Count() Then
		MetadataObjectID = Common.MetadataObjectID("Catalog.LeaseContract");
		QueryText = RequestTextScheduleOfPaymentsUnderLeaseAgreements();
		RecordPaymentScheduleForFinancialInstruments(
			LeaseContract, 
			QueryText, 
			MetadataObjectID, 
			Queue,
			4,
			AddnlParameter_);
	EndIf;
EndProcedure

// Performs calculation and recording of the schedule for calculations on expected receipts
//
// Parameters:
//    SettlementDates_ - Array of Date - payment dates for which receipts are expected
//    InvalidPaymentDocuments - Array of DocumentRef - documents that are not planned to be recalculated
//    Queue - Number - queue number when updating data
//    PaymentObjects - Array of DocumentRef.PlannedCashReceipt - documents that need to be recalculated.
//
Procedure CalculatePaymentScheduleForExpectedCashReceipts(SettlementDates_, InvalidPaymentDocuments = Undefined, Queue = Undefined, PaymentObjects = Undefined) Export
	
	If ValueIsFilled(InvalidPaymentDocuments) Then
		For Each InvalidPaymentDocument In InvalidPaymentDocuments Do
			RecordSet = CreateRecordSet();
			RecordSet.Filter.PaymentObject.Set(InvalidPaymentDocument);
			SetPrivilegedMode(True);
			WriteSet(RecordSet, InvalidPaymentDocument, Queue);
			SetPrivilegedMode(False);
		EndDo;
	EndIf;
	
	QueryText = "
	|SELECT
	|	DocumentData.Ref                                                    AS PaymentObject,
	|	DocumentData.CashAccountBankAccount                                       AS BankAccountCashAccount,
	|	DocumentData.PaymentDate                                               AS PaymentDate,
	|	DocumentData.Organization                                               AS Organization,
	|	VALUE(Enum.CashFlowTypes.Inpayment)            AS ReceiptIssue,
	|	DocumentData.Currency                                                    AS Currency,
	|	
	|	DocumentData.DocumentAmount                                            AS Sum,
	|	
	|	DocumentData.CashFlowItem                             AS CashFlowItem,
	|	VALUE(Enum.PaymentPlanningAreas.PlannedCashReceipts)   AS PlanningArea,
	|	DocumentData.Department                                             AS Department,
	|	DocumentData.EmployeeResponsible                                             AS EmployeeResponsible,
	|	DocumentData.Number                                                     AS Number,
	|	DocumentData.Date                                                      AS Date,
	|
	|	DocumentData.DocumentAmount                                            AS DocumentAmount,
	|	DocumentData.PaymentMethod                                               AS PaymentMethod,
	|	DocumentData.PaymentDate                                               AS ScheduleRelevanceDate,
	|	ENDOFPERIOD(DocumentData.PaymentDate, DAY)                           AS EndOfPaymentDate,
	|	DocumentData.Counterparty AS PayerBeneficiary
	|INTO PlannedCashReceipts
	|FROM
	|	Document.PlannedCashReceipt AS DocumentData
	|WHERE
	|	DocumentData.Posted
	|	AND DocumentData.PaymentDate IN (&SettlementDates_)
	|	AND NOT DocumentData.Ref IN (&InvalidPaymentDocuments)
	|	AND (DocumentData.Ref IN (&PaymentObjects) OR &AllPaymentObjects)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	KeysOfExpectedReceipts.Organization AS Organization,
	|	KeysOfExpectedReceipts.CashFlowItem AS CashFlowItem,
	|	KeysOfExpectedReceipts.Currency AS Currency,
	|	KeysOfExpectedReceipts.PaymentDate AS PaymentDate,
	|	KeysOfExpectedReceipts.EndOfPaymentDate AS EndOfPaymentDate,
	|	KeysOfExpectedReceipts.PayerBeneficiary AS PayerBeneficiary
	|INTO TTFilterOfExpectedReceipts
	|FROM
	|	PlannedCashReceipts AS KeysOfExpectedReceipts
	|";
	
	TempTablesManager = New TempTablesManager;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = QueryText;
	Query.SetParameter("SettlementDates_", SettlementDates_);
	Query.SetParameter("InvalidPaymentDocuments", InvalidPaymentDocuments);
	Query.SetParameter("AllPaymentObjects", Not ValueIsFilled(PaymentObjects));
	Query.SetParameter("PaymentObjects", PaymentObjects);
	
	SetPrivilegedMode(True);
	Result = Query.ExecuteBatchWithIntermediateData()[0];
	SetPrivilegedMode(False);
	
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	QueryText = "
	|SELECT
	|	BEGINOFPERIOD(Cash.Period, DAY) AS PaymentDate,
	|	Cash.Organization AS Organization,
	|	Cash.CashAccount.CashCurrency AS Currency,
	|	Cash.CashAccount AS BankAccountCashAccount,
	|	VALUE(Enum.PaymentForms.CashAccountPayment_) AS PaymentMethod,
	|	Cash.CashFlowItem AS CashFlowItem,
	|	PlannedCashReceipts.PayerBeneficiary AS PayerBeneficiary,
	|	SUM(Cash.Sum) AS Sum
	|FROM
	|	AccumulationRegister.CashAccountBalance AS Cash
	|
	|INNER JOIN 
	|	InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
	|ON
	|	Cash.AccountingDimensionByPartners = RegisterAccountingAnalyticsForPartners.DimensionKey
	|
	|		INNER JOIN
	|			TTFilterOfExpectedReceipts AS PlannedCashReceipts
	|		ON
	|			PlannedCashReceipts.Organization = Cash.Organization
	|			AND PlannedCashReceipts.CashFlowItem = Cash.CashFlowItem
	|			AND PlannedCashReceipts.Currency = Cash.CashAccount.CashCurrency
	|			AND Cash.Period BETWEEN PlannedCashReceipts.PaymentDate AND PlannedCashReceipts.EndOfPaymentDate
	|			AND PlannedCashReceipts.PayerBeneficiary = RegisterAccountingAnalyticsForPartners.Counterparty
	|WHERE
	|	Cash.RecordType = VALUE(AccumulationRecordType.Receipt)	
	|GROUP BY
	|	BEGINOFPERIOD(Cash.Period, DAY),
	|	Cash.Organization,
	|	Cash.CashAccount,
	|	Cash.CashFlowItem,
	|	PlannedCashReceipts.PayerBeneficiary
	|
	|UNION ALL
	|
	|SELECT
	|	BEGINOFPERIOD(Cash.Period, DAY) AS PaymentDate,
	|	Cash.Organization AS Organization,
	|	Cash.BankAccount.CashCurrency AS Currency,
	|	Cash.BankAccount AS BankAccountCashAccount,
	|	VALUE(Enum.PaymentForms.BankAccountPayment) AS PaymentMethod,
	|	Cash.CashFlowItem AS CashFlowItem,
	|	PlannedCashReceipts.PayerBeneficiary AS PayerBeneficiary,
	|	SUM(Cash.Sum) AS Sum
	|FROM
	|	AccumulationRegister.BankAccountCash AS Cash
	|
	|INNER JOIN 
	|	InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
	|ON
	|	Cash.AccountingDimensionByPartners = RegisterAccountingAnalyticsForPartners.DimensionKey
	|
	|		INNER JOIN
	|			TTFilterOfExpectedReceipts AS PlannedCashReceipts
	|		ON
	|			PlannedCashReceipts.Organization = Cash.Organization
	|			AND PlannedCashReceipts.CashFlowItem = Cash.CashFlowItem
	|			AND PlannedCashReceipts.Currency = Cash.BankAccount.CashCurrency
	|			AND Cash.Period BETWEEN PlannedCashReceipts.PaymentDate AND PlannedCashReceipts.EndOfPaymentDate
	|			AND PlannedCashReceipts.PayerBeneficiary = RegisterAccountingAnalyticsForPartners.Counterparty
	|WHERE
	|	Cash.RecordType = VALUE(AccumulationRecordType.Receipt)	
	|GROUP BY
	|	BEGINOFPERIOD(Cash.Period, DAY),
	|	Cash.Organization,
	|	Cash.BankAccount,
	|	Cash.CashFlowItem,
	|	PlannedCashReceipts.PayerBeneficiary
	|";
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = QueryText;
	
	SetPrivilegedMode(True);
	ActualReceipts = Query.Execute().Unload();
	SetPrivilegedMode(False);

	OMID = Common.MetadataObjectID("Document.PlannedCashReceipt");
	
	Selection = Result.Select();
	While Selection.Next() Do
		
		OrderReceiptAmount = Selection.Sum;
		
		TheStructureOfTheSearch = New Structure("PaymentDate, Organization, Currency, CashFlowItem");
		FillPropertyValues(TheStructureOfTheSearch, Selection);
		If ValueIsFilled(Selection.PaymentMethod) Then
			TheStructureOfTheSearch.Insert("PaymentMethod", Selection.PaymentMethod);
		EndIf;
		If ValueIsFilled(Selection.BankAccountCashAccount) Then
			TheStructureOfTheSearch.Insert("BankAccountCashAccount", Selection.BankAccountCashAccount);
		EndIf;
		If ValueIsFilled(Selection.PayerBeneficiary) Then
			TheStructureOfTheSearch.Insert("PayerBeneficiary", Selection.PayerBeneficiary);
		EndIf;
		
		LinesToDelete = New Array;
		
		FactRows = ActualReceipts.FindRows(TheStructureOfTheSearch);
		If FactRows.Count() Then
			For Each FactLine_ In FactRows Do
				
				If FactLine_.Sum >= OrderReceiptAmount Then
					FactLine_.Sum = FactLine_.Sum - OrderReceiptAmount;
					OrderReceiptAmount = 0;
				Else
					OrderReceiptAmount = OrderReceiptAmount - FactLine_.Sum;
					FactLine_.Sum = 0;
				EndIf;
				
				If FactLine_.Sum = 0 Then
					LinesToDelete.Add(FactLine_);
				EndIf;
				
				If OrderReceiptAmount = 0 Then
					Break;
				EndIf;
			EndDo;
		EndIf;
		
		For Each RowToDelete In LinesToDelete Do
			ActualReceipts.Delete(RowToDelete);
		EndDo;
		
		RecordSet = CreateRecordSet();
		RecordSet.Filter.PaymentObject.Set(Selection.PaymentObject);
		
		If OrderReceiptAmount <> 0 Then
			Record = RecordSet.Add();
			FillPropertyValues(Record, Selection);
			Record.Sum = OrderReceiptAmount;
			Record.PaymentObjectType = OMID;
			Record.Id = New UUID();
			FillInOriginalAttributes(Record);
		EndIf;
		
		SetPrivilegedMode(True);
		WriteSet(RecordSet, Selection.PaymentObject, Queue);
		SetPrivilegedMode(False);
	EndDo;
	
EndProcedure

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Private

Procedure RecordPaymentScheduleForSettlements(TableOfPaymentObjects, QueryText, ReceiptIssue, PlanningArea, Queue)
	
	If Not TableOfPaymentObjects.Count() Then
		Return;
	EndIf;
	
	GraphFields = InitializeGraphFields();
	
	QueriesByType = New Map;
	SelectionsByType = New Map;
	
	For Each TableRow In TableOfPaymentObjects Do
		
		If Not ValueIsFilled(TableRow.PaymentObject) Then
			Continue;
		EndIf;
		
		PaymentObjectType = Common.TableNameByRef(TableRow.PaymentObject);
		If QueriesByType.Get(PaymentObjectType) = Undefined Then
			QueriesByType.Insert(PaymentObjectType,
				CashCached.RequestTextCacheOfPaymentDetails(PaymentObjectType, GraphFields));
		EndIf;
	EndDo;
	
	QuerySchema = New QuerySchema;
	For Each RequestByType In QueriesByType Do
		NewQuery = QuerySchema.QueryBatch.Add();
		NewQuery.SetQueryText(RequestByType.Value);
	EndDo;
	Query = New Query(QuerySchema.GetQueryText());
	If ValueIsFilled(Query.Text) Then
		Query.SetParameter("Ref", TableOfPaymentObjects.UnloadColumn("PaymentObject"));
		Result = Query.ExecuteBatch();
		Indus = 0;
		For Each RequestByType In QueriesByType Do
			SelectionsByType.Insert(RequestByType.Key, Result[Indus].Select());
			Indus = Indus + 1;
		EndDo;
	EndIf;
	
	Query = New Query;
	Query.Text = QueryText;
	
	Query.SetParameter("ARAPObjects", TableOfPaymentObjects.UnloadColumn("ARAPObject"));
	Query.SetParameter("CurrentDate", CurrentSessionDate());
	Selection = Query.Execute().Select();
	
	For Each TableRow In TableOfPaymentObjects Do
		
		If Not ValueIsFilled(TableRow.PaymentObject) Then
			Continue;
		EndIf;
		
		TheStructureOfTheSearch = New Structure("Ref", TableRow.PaymentObject);
		
		RecordSet = InformationRegisters.ScheduleOfPayments.CreateRecordSet();
		RecordSet.Filter.PaymentObject.Set(TableRow.PaymentObject);
		RecordSet.Filter.ReceiptIssue.Set(ReceiptIssue);
		
		PaymentObjectType = Common.TableNameByRef(TableRow.PaymentObject);
		
		SelectingBankingDetails_ = SelectionsByType.Get(PaymentObjectType);
		
		If SelectingBankingDetails_.FindNext(TheStructureOfTheSearch) Then
			GraphFields = InitializeGraphFields();
			FillPropertyValues(GraphFields, SelectingBankingDetails_);
		EndIf;
		
		While Selection.FindNext(TheStructureOfTheSearch) Do
			
			Record = RecordSet.Add();
			
			FillPropertyValues(Record, GraphFields);
			FillPropertyValues(Record, Selection);
			
			Record.PaymentObject = Selection.Ref;
			Record.ReceiptIssue = ReceiptIssue;
			Record.PlanningArea = PlanningArea;
			
			Record.BankAccountCashAccount = Undefined;
			If ValueIsFilled(GraphFields.PaymentMethod) Then
				If GraphFields.PaymentMethod = Enums.PaymentForms.BankAccountPayment
					Or GraphFields.PaymentMethod = Enums.PaymentForms.InstantPayments Then
					If ValueIsFilled(GraphFields.BankAccount) Then
						Record.BankAccountCashAccount = GraphFields.BankAccount;
					ElsIf ValueIsFilled(GraphFields.CompanyBankAccount) Then
						Record.BankAccountCashAccount = GraphFields.CompanyBankAccount;
					EndIf;
					
					If GraphFields.CompanyRecipient = Selection.Organization
						Or GraphFields.Consignee = Selection.Organization Then
						Record.BankAccountCashAccount = ?(ValueIsFilled(GraphFields.RecipientCompanyBankAccount),
						                                                 GraphFields.RecipientCompanyBankAccount,
						                                                 Undefined);
					EndIf;
					
				ElsIf GraphFields.PaymentMethod = Enums.PaymentForms.CashAccountPayment_
					And (ValueIsFilled(GraphFields.CashAccount)
					Or ValueIsFilled(GraphFields.CashAccountRecipient)) Then
					
					Record.BankAccountCashAccount = GraphFields.CashAccount;
					
					If GraphFields.CompanyRecipient = Selection.Organization
						Or GraphFields.Consignee = Selection.Organization Then
						Record.BankAccountCashAccount = ?(ValueIsFilled(GraphFields.CashAccountRecipient),
						                                                 GraphFields.CashAccountRecipient,
						                                                 Undefined);
					EndIf;
					
				EndIf;
			Else
				If ValueIsFilled(GraphFields.CashAccount) Then
					Record.BankAccountCashAccount = GraphFields.CashAccount;
				ElsIf ValueIsFilled(GraphFields.BankAccount) Then
					Record.BankAccountCashAccount = GraphFields.BankAccount;
				ElsIf ValueIsFilled(GraphFields.CompanyBankAccount) Then
					Record.BankAccountCashAccount = GraphFields.CompanyBankAccount;
				EndIf;
				
				If GraphFields.CompanyRecipient = Selection.Organization
					Or GraphFields.Consignee = Selection.Organization Then
					
					Record.BankAccountCashAccount = ?(ValueIsFilled(GraphFields.CashAccountRecipient),
						                                                 GraphFields.CashAccountRecipient,
						                                                 Undefined);
					
					If Not ValueIsFilled(Record.BankAccountCashAccount) Then
						Record.BankAccountCashAccount = ?(ValueIsFilled(GraphFields.RecipientCompanyBankAccount),
						                                                 GraphFields.RecipientCompanyBankAccount,
						                                                 Undefined);
					EndIf;
					
				EndIf;
				
			EndIf;
			
			If Not ValueIsFilled(GraphFields.CashFlowItem) Then
				If ValueIsFilled(GraphFields.CashFlowContract) Then
					Record.CashFlowItem = GraphFields.CashFlowContract;
				ElsIf ValueIsFilled(GraphFields.CashFlowAgreement) Then
					Record.CashFlowItem = GraphFields.CashFlowAgreement;
				Else
					Record.CashFlowItem =
						Catalogs.CashFlowReportItems.CashFlowItemForBusinessTransaction(GraphFields.BusinessOperation);
				EndIf;
			EndIf;
			
			Record.EmployeeResponsible = GraphFields.Manager;
			Record.PaymentObjectType = Common.MetadataObjectID(PaymentObjectType);
			Record.Id = New UUID();
			FillInOriginalAttributes(Record);
		EndDo;
		Selection.Reset();
		SelectingBankingDetails_.Reset();
		
		BeginTransaction();
		Try
			If Queue <> Undefined Then
				InfobaseUpdate.WriteData(RecordSet);
			Else
				RecordSet.Write();
			EndIf;
			CommitTransaction();
		Except
			RollbackTransaction();
			MessageText = NStr("vi = 'Không thể ghi lại lịch thanh toán cho: %Ref%  vì lý do: %Cause%';
								|ru = 'Не удалось записать график платежей по: %Ref% по причине: %Cause%';
								|en = 'Cannot save a payment schedule for: %Ref%. Reason: %Cause%'; fa = 'Cannot save a payment schedule for: %Ref%. Reason: %Cause%';
								|it = 'Non è stato possibile salvare il grafico di pagamento per: %Ref% a causa: %Cause%';
								|pl = 'Nie udało się zapisać harmonogramu płatności: %Ref% z powodu: %Cause%';
								|tr = '%Ref% ile ilgili %Cause% nedenler sebebi ile ödeme planı kaydedilemedi'");
			MessageText = StrReplace(MessageText, "%Ref%", TableRow.PaymentObject);
			MessageText = StrReplace(MessageText, "%Cause%", DetailErrorDescription(ErrorInfo()));
			
			WriteLogEvent(InfobaseUpdate.EventLogEvent(),
				EventLogLevel.Warning,,
				TableRow.PaymentObject, MessageText);
			Raise;
		EndTry;
	EndDo;
	
EndProcedure

Procedure RecordScheduleOfPaymentsForCashToBePaid(PaymentObjects, QueryText, MetadataObjectID, Queue)
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("PaymentObjects", PaymentObjects);
	
	Selection = Query.Execute().Select();
	
	For Each PaymentObject In PaymentObjects Do
		
		TheStructureOfTheSearch = New Structure("PaymentObject", PaymentObject);
		
		RecordSet = InformationRegisters.ScheduleOfPayments.CreateRecordSet();
		RecordSet.Filter.PaymentObject.Set(PaymentObject);
		
		While Selection.FindNext(TheStructureOfTheSearch) Do
			
			Record = RecordSet.Add();
			FillPropertyValues(Record, Selection);
			
			Record.PaymentObjectType = MetadataObjectID;
			Record.Id = New UUID();
			FillInOriginalAttributes(Record);
		EndDo;
		Selection.Reset();
		
		WriteSet(RecordSet, PaymentObject, Queue);
	EndDo;
	
EndProcedure

Procedure RecordPaymentScheduleForFinancialInstruments(PaymentObjects, QueryText, MetadataObjectID, Queue, QueryNumber, AddnlParameter_ = Undefined)
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("PaymentObjects", PaymentObjects);
	Query.SetParameter("AddnlParameter_", AddnlParameter_);
	
	SetPrivilegedMode(True);
	Result = Query.ExecuteBatchWithIntermediateData();
	SetPrivilegedMode(False);
	
	Selection = Result[QueryNumber].Select();
	SelectingBankingDetails_ = Result[QueryNumber + 1].Select();
	
	For Each PaymentObject In PaymentObjects Do
		
		If Not ValueIsFilled(PaymentObject) Then
			Continue;
		EndIf;
		
		TheStructureOfTheSearch = New Structure("PaymentObject", PaymentObject);
		
		RecordSet = InformationRegisters.ScheduleOfPayments.CreateRecordSet();
		RecordSet.Filter.PaymentObject.Set(PaymentObject);
		
		SelectingBankingDetails_.FindNext(TheStructureOfTheSearch);
		
		While Selection.FindNext(TheStructureOfTheSearch) Do
			
			Record = RecordSet.Add();
			
			FillPropertyValues(Record, SelectingBankingDetails_);
			FillPropertyValues(Record, Selection);
			
			Record.BankAccountCashAccount = Undefined;
			If ValueIsFilled(SelectingBankingDetails_.PaymentMethod) Then
				If SelectingBankingDetails_.PaymentMethod = Enums.PaymentForms.BankAccountPayment
					Or SelectingBankingDetails_.PaymentMethod = Enums.PaymentForms.InstantPayments Then
					If ValueIsFilled(SelectingBankingDetails_.BankAccount) Then
						Record.BankAccountCashAccount = SelectingBankingDetails_.BankAccount;
					EndIf;
				ElsIf SelectingBankingDetails_.PaymentMethod = Enums.PaymentForms.CashAccountPayment_
					And ValueIsFilled(SelectingBankingDetails_.CashAccount) Then
					Record.BankAccountCashAccount = SelectingBankingDetails_.CashAccount;
				EndIf;
			Else
				If ValueIsFilled(SelectingBankingDetails_.CashAccount) Then
					Record.BankAccountCashAccount = SelectingBankingDetails_.CashAccount;
				ElsIf ValueIsFilled(SelectingBankingDetails_.BankAccount) Then
					Record.BankAccountCashAccount = SelectingBankingDetails_.BankAccount;
				EndIf;
			EndIf;
			
			If TypeOf(PaymentObject) = Type("CatalogRef.LoanAndDepositContracts") Then
				If Selection.ReceiptIssue = Enums.CashFlowTypes.WriteOff
					And SelectingBankingDetails_.ContractKind = Enums.ContractKindsOfFinancialInstruments.LoanOrBorrowing
					Or Selection.ReceiptIssue = Enums.CashFlowTypes.Inpayment
					And (SelectingBankingDetails_.ContractKind = Enums.ContractKindsOfFinancialInstruments.Deposit
						Or SelectingBankingDetails_.ContractKind = Enums.ContractKindsOfFinancialInstruments.IssuedBorrowing) Then
					
					If Selection.AmountType = Enums.LoanAndDepositScheduleAmountTypes.PrincipalDebt Then
						Record.CashFlowItem = SelectingBankingDetails_.CashFlowItemOfPrincipalDebt;
					ElsIf Selection.AmountType = Enums.LoanAndDepositScheduleAmountTypes.Interests Then
						Record.CashFlowItem = SelectingBankingDetails_.CashFlowItemOfInterestPayment;
					ElsIf Selection.AmountType = Enums.LoanAndDepositScheduleAmountTypes.Fee Then
						Record.CashFlowItem = SelectingBankingDetails_.CashFlowItemOfFeePayment;
					EndIf;
				EndIf;
			EndIf;
			
			Record.PaymentObjectType = MetadataObjectID;
			Record.Id = New UUID();
			FillInOriginalAttributes(Record);
		EndDo;
		Selection.Reset();
		SelectingBankingDetails_.Reset();
		
		SetPrivilegedMode(True);
		WriteSet(RecordSet, PaymentObject, Queue);
		SetPrivilegedMode(False);
		
	EndDo;
	
EndProcedure

Procedure WriteSet(RecordSet, PaymentObject, Queue)
	
	BeginTransaction();
	Try
		If Queue <> Undefined Then
			InfobaseUpdate.WriteData(RecordSet);
		Else
			RecordSet.Write();
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		MessageText = NStr("vi = 'Không thể ghi lại lịch thanh toán cho: %Ref%  vì lý do: %Cause%';
							|ru = 'Не удалось записать график платежей по: %Ref% по причине: %Cause%';
							|en = 'Cannot save a payment schedule for: %Ref%. Reason: %Cause%'; fa = 'Cannot save a payment schedule for: %Ref%. Reason: %Cause%';
							|it = 'Non è stato possibile salvare il grafico di pagamento per: %Ref% a causa: %Cause%';
							|pl = 'Nie udało się zapisać harmonogramu płatności: %Ref% z powodu: %Cause%';
							|tr = '%Ref% ile ilgili %Cause% nedenler sebebi ile ödeme planı kaydedilemedi'");
		MessageText = StrReplace(MessageText, "%Ref%", PaymentObject);
		MessageText = StrReplace(MessageText, "%Cause%", DetailErrorDescription(ErrorInfo()));
	
		WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Warning,,
			PaymentObject, MessageText);
		Raise;
	EndTry;
	
EndProcedure

Function RequestTextPaymentScheduleForSettlementsWithCustomers()
	
	QueryText = "
	|SELECT
	|	Calculations.ARAPObject AS ARAPObject,
	|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Calculations.Currency AS Currency,
	|	Calculations.AmountDueBalance - Calculations.BeingPaidBalance AS AmountDue
	|INTO Balance
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting.Balance(,
	|			ARAPObject IN (&ARAPObjects)
	|		) AS Calculations
	|
	|WHERE
	|	Calculations.AmountDueBalance - Calculations.BeingPaidBalance > 0
	|
	|INDEX BY
	|	ARAPObject,
	|	AccountingDimensionByPartners,
	|	Currency
	|;
	|
	|/////////////////////////////////////////////////
	|SELECT
	|	Calculations.Period AS Period,
	|	Calculations.ARAPObject AS ARAPObject,
	|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Calculations.Currency AS Currency,
	|	Calculations.AmountDueReceipt AS AmountDue
	|INTO PaymentSchedule
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting.Turnovers(,,
	|			Day,
	|			(ARAPObject, AccountingDimensionByPartners, Currency) IN 
	|			(SELECT
	|				Balance.ARAPObject,
	|				Balance.AccountingDimensionByPartners,
	|				Balance.Currency
	|			FROM
	|				Balance AS Balance)
	|		) AS Calculations
	|
	|INDEX BY
	|	ARAPObject,
	|	AccountingDimensionByPartners,
	|	Currency
	|;
	|
	|/////////////////////////////////////////////////
	|SELECT
	|	PaymentSchedule.Period AS PaymentDate,
	|	PaymentSchedule.ARAPObject AS ARAPObject,
	|	PaymentSchedule.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	PaymentSchedule.Currency AS Currency,
	|	
	|	CASE WHEN MAX(Balance.AmountDue) - MAX(PaymentSchedule.AmountDue) - SUM(ISNULL(PaymentScheduleTotal.AmountDue, 0)) > 0
	|		THEN
	|			MAX(PaymentSchedule.AmountDue)
	|		ELSE
	|			MAX(Balance.AmountDue) - SUM(ISNULL(PaymentScheduleTotal.AmountDue, 0))
	|	END AS Sum
	|	
	|INTO PaymentScheduleCalculated
	|FROM
	|	PaymentSchedule AS PaymentSchedule
	|	
	|	LEFT JOIN
	|		PaymentSchedule AS PaymentScheduleTotal
	|	ON
	|		PaymentScheduleTotal.ARAPObject = PaymentSchedule.ARAPObject
	|		AND PaymentScheduleTotal.AccountingDimensionByPartners = PaymentSchedule.AccountingDimensionByPartners
	|		AND PaymentScheduleTotal.Currency = PaymentSchedule.Currency
	|		AND PaymentScheduleTotal.Period > PaymentSchedule.Period
	|		
	|	LEFT JOIN
	|		Balance AS Balance
	|	ON
	|		Balance.ARAPObject = PaymentSchedule.ARAPObject
	|		AND Balance.AccountingDimensionByPartners = PaymentSchedule.AccountingDimensionByPartners
	|		AND Balance.Currency = PaymentSchedule.Currency
	|		
	|GROUP BY
	|	PaymentSchedule.Period,
	|	PaymentSchedule.ARAPObject,
	|	PaymentSchedule.AccountingDimensionByPartners,
	|	PaymentSchedule.Currency
	|	
	|HAVING
	|	MAX(Balance.AmountDue) - SUM(ISNULL(PaymentScheduleTotal.AmountDue, 0)) > 0
	|;
	|
	|/////////////////////////////////////////////////
	|SELECT
	|	PaymentSchedule.PaymentDate AS PaymentDate,
	|	PaymentSchedule.ARAPObject.Object AS Ref,
	|	PaymentSchedule.AccountingDimensionByPartners.Counterparty AS PayerBeneficiary,
	|	PaymentSchedule.AccountingDimensionByPartners.Organization AS Organization,
	|	PaymentSchedule.Currency AS Currency,
	|	SUM(PaymentSchedule.Sum) AS Sum
	|FROM
	|	PaymentScheduleCalculated AS PaymentSchedule
	|GROUP BY
	|	PaymentSchedule.PaymentDate,
	|	PaymentSchedule.ARAPObject.Object,
	|	PaymentSchedule.AccountingDimensionByPartners.Counterparty,
	|	PaymentSchedule.AccountingDimensionByPartners.Organization,
	|	PaymentSchedule.Currency
	|";
	
	Return QueryText;
	
EndFunction

Function RequestTextPaymentScheduleForRefundsToCustomers()
	
	QueryText = "
	|SELECT
	|	Calculations.ARAPObject AS ARAPObject,
	|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Calculations.Currency AS Currency,
	|	-(Calculations.AmountDueBalance - Calculations.BeingPaidBalance) AS AmountDue
	|INTO Balance
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting.Balance(,
	|			ARAPObject IN (&ARAPObjects)
	|		) AS Calculations
	|
	|WHERE
	|	Calculations.AmountDueBalance - Calculations.BeingPaidBalance < 0
	|
	|INDEX BY
	|	ARAPObject,
	|	AccountingDimensionByPartners,
	|	Currency
	|;
	|
	|/////////////////////////////////////////////////
	|SELECT
	|	Calculations.Period AS Period,
	|	Calculations.ARAPObject AS ARAPObject,
	|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Calculations.Currency AS Currency,
	|	Calculations.AmountDueExpense AS AmountDue
	|INTO PaymentSchedule
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting.Turnovers(,,
	|			Day,
	|			(ARAPObject, AccountingDimensionByPartners, Currency) IN 
	|			(SELECT
	|				Balance.ARAPObject,
	|				Balance.AccountingDimensionByPartners,
	|				Balance.Currency
	|			FROM
	|				Balance AS Balance)
	|		) AS Calculations
	|
	|INDEX BY
	|	ARAPObject,
	|	AccountingDimensionByPartners,
	|	Currency
	|;
	|
	|/////////////////////////////////////////////////
	|SELECT
	|	PaymentSchedule.Period AS PaymentDate,
	|	PaymentSchedule.ARAPObject AS ARAPObject,
	|	PaymentSchedule.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	PaymentSchedule.Currency AS Currency,
	|	
	|	CASE WHEN MAX(Balance.AmountDue) - MAX(PaymentSchedule.AmountDue) - SUM(ISNULL(PaymentScheduleTotal.AmountDue, 0)) > 0
	|		THEN
	|			MAX(PaymentSchedule.AmountDue)
	|		ELSE
	|			MAX(Balance.AmountDue) - SUM(ISNULL(PaymentScheduleTotal.AmountDue, 0))
	|	END AS Sum
	|	
	|INTO PaymentScheduleCalculated
	|FROM
	|	PaymentSchedule AS PaymentSchedule
	|	
	|	LEFT JOIN
	|		PaymentSchedule AS PaymentScheduleTotal
	|	ON
	|		PaymentScheduleTotal.ARAPObject = PaymentSchedule.ARAPObject
	|		AND PaymentScheduleTotal.AccountingDimensionByPartners = PaymentSchedule.AccountingDimensionByPartners
	|		AND PaymentScheduleTotal.Currency = PaymentSchedule.Currency
	|		AND PaymentScheduleTotal.Period > PaymentSchedule.Period
	|		
	|	LEFT JOIN
	|		Balance AS Balance
	|	ON
	|		Balance.ARAPObject = PaymentSchedule.ARAPObject
	|		AND Balance.AccountingDimensionByPartners = PaymentSchedule.AccountingDimensionByPartners
	|		AND Balance.Currency = PaymentSchedule.Currency
	|		
	|GROUP BY
	|	PaymentSchedule.Period,
	|	PaymentSchedule.ARAPObject,
	|	PaymentSchedule.AccountingDimensionByPartners,
	|	PaymentSchedule.Currency
	|	
	|HAVING
	|	MAX(Balance.AmountDue) - SUM(ISNULL(PaymentScheduleTotal.AmountDue, 0)) > 0
	|;
	|
	|/////////////////////////////////////////////////
	|SELECT
	|	PaymentSchedule.PaymentDate AS PaymentDate,
	|	PaymentSchedule.ARAPObject.Object AS Ref,
	|	PaymentSchedule.AccountingDimensionByPartners.Counterparty AS PayerBeneficiary,
	|	PaymentSchedule.AccountingDimensionByPartners.Organization AS Organization,
	|	PaymentSchedule.Currency AS Currency,
	|	SUM(PaymentSchedule.Sum) AS Sum
	|FROM
	|	PaymentScheduleCalculated AS PaymentSchedule
	|GROUP BY
	|	PaymentSchedule.PaymentDate,
	|	PaymentSchedule.ARAPObject.Object,
	|	PaymentSchedule.AccountingDimensionByPartners.Counterparty,
	|	PaymentSchedule.AccountingDimensionByPartners.Organization,
	|	PaymentSchedule.Currency
	|";
	
	Return QueryText;
	
EndFunction

Function RequestTextPaymentScheduleForSettlementsWithCustomersNewArchitecture()
	
	QueryText = "
	|SELECT
	|	Calculations.ARAPObject AS ARAPObject,
	|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Calculations.Currency AS Currency,
	|	Calculations.AmountDueBalance - Calculations.BeingPaidBalance AS AmountDue
	|INTO Balance
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting.Balance(,
	|			ARAPObject IN (&ARAPObjects)
	|		) AS Calculations
	|
	|WHERE
	|	Calculations.AmountDueBalance - Calculations.BeingPaidBalance > 0
	|
	|INDEX BY
	|	ARAPObject,
	|	AccountingDimensionByPartners,
	|	Currency
	|;
	|
	|/////////////////////////////////////////////////
	|SELECT
	|	PaymentPlan_.PlannedRepaymentDate AS PlannedRepaymentDate,
	|	PaymentPlan_.ARAPObject.Date AS OccurrenceDate,
	|	PaymentPlan_.ARAPObject AS ARAPObject,
	|	PaymentPlan_.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	PaymentPlan_.Currency AS Currency,
	|	PaymentPlan_.AmountDueBalance AS AmountDue
	|INTO BalancesSettlementsWithCustomers
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingCashFlowPlan.Balance(, ARAPObject IN (&ARAPObjects)) AS PaymentPlan_
	|WHERE
	|	PaymentPlan_.AmountDueBalance > 0
	|
	|UNION ALL
	|
	|SELECT
	|	Calculations.PlannedRepaymentDate,
	|	Calculations.OccurrenceDate,
	|	Calculations.ARAPObject,
	|	Calculations.AccountingDimensionByPartners,
	|	Calculations.Currency,
	|	Calculations.DebtBalance
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates.Balance(, ARAPObject IN (&ARAPObjects)) AS Calculations
	|WHERE
	|	Calculations.DebtBalance > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|		WHEN BalancesSettlementsWithCustomers.PlannedRepaymentDate = DATETIME(1, 1, 1)
	|			THEN CASE
	|					WHEN BalancesSettlementsWithCustomers.OccurrenceDate = DATETIME(1, 1, 1)
	|						THEN CASE
	|								WHEN ISNULL(ARAPObjects.Date, DATETIME(1, 1, 1)) = DATETIME(1, 1, 1)
	|									THEN &CurrentDate
	|								ELSE ARAPObjects.Date
	|							END
	|					ELSE BalancesSettlementsWithCustomers.OccurrenceDate
	|				END
	|		ELSE BalancesSettlementsWithCustomers.PlannedRepaymentDate
	|	END AS Period,
	|	BalancesSettlementsWithCustomers.ARAPObject AS ARAPObject,
	|	BalancesSettlementsWithCustomers.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	BalancesSettlementsWithCustomers.Currency AS Currency,
	|	BalancesSettlementsWithCustomers.AmountDue AS AmountDue
	|INTO BalancesOfSettlementsWithPeriod
	|FROM
	|	BalancesSettlementsWithCustomers AS BalancesSettlementsWithCustomers
	|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON BalancesSettlementsWithCustomers.ARAPObject = ARAPObjects.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.Period AS Period,
	|	NestedQuery.ARAPObject AS ARAPObject,
	|	NestedQuery.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	NestedQuery.Currency AS Currency,
	|	SUM(NestedQuery.AmountDue) AS AmountDue
	|INTO PaymentSchedule
	|FROM BalancesOfSettlementsWithPeriod AS NestedQuery
	|GROUP BY
	|	NestedQuery.Period,
	|	NestedQuery.ARAPObject,
	|	NestedQuery.AccountingDimensionByPartners,
	|	NestedQuery.Currency
	|INDEX BY
	|	ARAPObject,
	|	AccountingDimensionByPartners,
	|	Currency
	|;
	|
	|/////////////////////////////////////////////////
	|SELECT
	|	PaymentSchedule.Period AS PaymentDate,
	|	PaymentSchedule.ARAPObject AS ARAPObject,
	|	PaymentSchedule.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	PaymentSchedule.Currency AS Currency,
	|	
	|	CASE WHEN MAX(Balance.AmountDue) - MAX(PaymentSchedule.AmountDue) - SUM(ISNULL(PaymentScheduleTotal.AmountDue, 0)) > 0
	|		THEN
	|			MAX(PaymentSchedule.AmountDue)
	|		ELSE
	|			MAX(Balance.AmountDue) - SUM(ISNULL(PaymentScheduleTotal.AmountDue, 0))
	|	END AS Sum
	|	
	|INTO PaymentScheduleCalculated
	|FROM
	|	PaymentSchedule AS PaymentSchedule
	|	
	|	LEFT JOIN
	|		PaymentSchedule AS PaymentScheduleTotal
	|	ON
	|		PaymentScheduleTotal.ARAPObject = PaymentSchedule.ARAPObject
	|		AND PaymentScheduleTotal.AccountingDimensionByPartners = PaymentSchedule.AccountingDimensionByPartners
	|		AND PaymentScheduleTotal.Currency = PaymentSchedule.Currency
	|		AND PaymentScheduleTotal.Period > PaymentSchedule.Period
	|		
	|	LEFT JOIN
	|		Balance AS Balance
	|	ON
	|		Balance.ARAPObject = PaymentSchedule.ARAPObject
	|		AND Balance.AccountingDimensionByPartners = PaymentSchedule.AccountingDimensionByPartners
	|		AND Balance.Currency = PaymentSchedule.Currency
	|		
	|GROUP BY
	|	PaymentSchedule.Period,
	|	PaymentSchedule.ARAPObject,
	|	PaymentSchedule.AccountingDimensionByPartners,
	|	PaymentSchedule.Currency
	|	
	|HAVING
	|	MAX(Balance.AmountDue) - SUM(ISNULL(PaymentScheduleTotal.AmountDue, 0)) > 0
	|;
	|
	|/////////////////////////////////////////////////
	|SELECT
	|	PaymentSchedule.PaymentDate AS PaymentDate,
	|	PaymentSchedule.ARAPObject.Object AS Ref,
	|	PaymentSchedule.AccountingDimensionByPartners.Counterparty AS PayerBeneficiary,
	|	PaymentSchedule.AccountingDimensionByPartners.Organization AS Organization,
	|	PaymentSchedule.Currency AS Currency,
	|	SUM(PaymentSchedule.Sum) AS Sum
	|FROM
	|	PaymentScheduleCalculated AS PaymentSchedule
	|GROUP BY
	|	PaymentSchedule.PaymentDate,
	|	PaymentSchedule.ARAPObject.Object,
	|	PaymentSchedule.AccountingDimensionByPartners.Counterparty,
	|	PaymentSchedule.AccountingDimensionByPartners.Organization,
	|	PaymentSchedule.Currency
	|";
	
	Return QueryText;
	
EndFunction

Function RequestTextPaymentScheduleForRefundsToCustomersNewArchitecture()
	
	QueryText = "
	|SELECT
	|	Calculations.ARAPObject AS ARAPObject,
	|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Calculations.Currency AS Currency,
	|	-(Calculations.AmountDueBalance - Calculations.BeingPaidBalance) AS AmountDue
	|INTO Balance
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting.Balance(,
	|			ARAPObject IN (&ARAPObjects)
	|		) AS Calculations
	|
	|WHERE
	|	Calculations.AmountDueBalance - Calculations.BeingPaidBalance < 0
	|
	|INDEX BY
	|	ARAPObject,
	|	AccountingDimensionByPartners,
	|	Currency
	|;
	|
	|/////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.Period AS Period,
	|	NestedQuery.ARAPObject AS ARAPObject,
	|	NestedQuery.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	NestedQuery.Currency AS Currency,
	|	SUM(NestedQuery.AmountDue) AS AmountDue
	|INTO PaymentSchedule
	|FROM (
	|	SELECT
	|		PaymentPlan_.PlannedRepaymentDate AS Period,
	|		PaymentPlan_.ARAPObject AS ARAPObject,
	|		PaymentPlan_.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		PaymentPlan_.Currency AS Currency,
	|		PaymentPlan_.AmountDueBalance AS AmountDue
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingCashFlowPlan.Balance(, ARAPObject IN (&ARAPObjects)) AS PaymentPlan_
	|	WHERE
	|		PaymentPlan_.AmountDueBalance > 0
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Calculations.PlannedRepaymentDate AS Period,
	|		Calculations.ARAPObject AS ARAPObject,
	|		Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		Calculations.Currency AS Currency,
	|		Calculations.DebtBalance AS AmountDue
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingByDueDates.Balance(, ARAPObject IN (&ARAPObjects)) AS Calculations
	|	WHERE
	|		Calculations.DebtBalance > 0) AS NestedQuery
	|GROUP BY
	|	NestedQuery.Period,
	|	NestedQuery.ARAPObject,
	|	NestedQuery.AccountingDimensionByPartners,
	|	NestedQuery.Currency
	|INDEX BY
	|	ARAPObject,
	|	AccountingDimensionByPartners,
	|	Currency
	|;
	|
	|/////////////////////////////////////////////////
	|SELECT
	|	PaymentSchedule.Period AS PaymentDate,
	|	PaymentSchedule.ARAPObject AS ARAPObject,
	|	PaymentSchedule.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	PaymentSchedule.Currency AS Currency,
	|	
	|	CASE WHEN MAX(Balance.AmountDue) - MAX(PaymentSchedule.AmountDue) - SUM(ISNULL(PaymentScheduleTotal.AmountDue, 0)) > 0
	|		THEN
	|			MAX(PaymentSchedule.AmountDue)
	|		ELSE
	|			MAX(Balance.AmountDue) - SUM(ISNULL(PaymentScheduleTotal.AmountDue, 0))
	|	END AS Sum
	|	
	|INTO PaymentScheduleCalculated
	|FROM
	|	PaymentSchedule AS PaymentSchedule
	|	
	|	LEFT JOIN
	|		PaymentSchedule AS PaymentScheduleTotal
	|	ON
	|		PaymentScheduleTotal.ARAPObject = PaymentSchedule.ARAPObject
	|		AND PaymentScheduleTotal.AccountingDimensionByPartners = PaymentSchedule.AccountingDimensionByPartners
	|		AND PaymentScheduleTotal.Currency = PaymentSchedule.Currency
	|		AND PaymentScheduleTotal.Period > PaymentSchedule.Period
	|		
	|	LEFT JOIN
	|		Balance AS Balance
	|	ON
	|		Balance.ARAPObject = PaymentSchedule.ARAPObject
	|		AND Balance.AccountingDimensionByPartners = PaymentSchedule.AccountingDimensionByPartners
	|		AND Balance.Currency = PaymentSchedule.Currency
	|		
	|GROUP BY
	|	PaymentSchedule.Period,
	|	PaymentSchedule.ARAPObject,
	|	PaymentSchedule.AccountingDimensionByPartners,
	|	PaymentSchedule.Currency
	|	
	|HAVING
	|	MAX(Balance.AmountDue) - SUM(ISNULL(PaymentScheduleTotal.AmountDue, 0)) > 0
	|;
	|
	|/////////////////////////////////////////////////
	|SELECT
	|	PaymentSchedule.PaymentDate AS PaymentDate,
	|	PaymentSchedule.ARAPObject.Object AS Ref,
	|	PaymentSchedule.AccountingDimensionByPartners.Counterparty AS PayerBeneficiary,
	|	PaymentSchedule.AccountingDimensionByPartners.Organization AS Organization,
	|	PaymentSchedule.Currency AS Currency,
	|	SUM(PaymentSchedule.Sum) AS Sum
	|FROM
	|	PaymentScheduleCalculated AS PaymentSchedule
	|GROUP BY
	|	PaymentSchedule.PaymentDate,
	|	PaymentSchedule.ARAPObject.Object,
	|	PaymentSchedule.AccountingDimensionByPartners.Counterparty,
	|	PaymentSchedule.AccountingDimensionByPartners.Organization,
	|	PaymentSchedule.Currency
	|";
	
	Return QueryText;
	
EndFunction

Function RequestTextPaymentScheduleForSettlementsWithSuppliers()
	
	QueryText = "
	|SELECT
	|	Calculations.ARAPObject AS ARAPObject,
	|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Calculations.Currency AS Currency,
	|	-(Calculations.AmountDueBalance - Calculations.BeingPaidBalance) AS AmountDue
	|INTO Balance
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting.Balance(,
	|			ARAPObject IN (&ARAPObjects)
	|		) AS Calculations
	|
	|WHERE
	|	Calculations.AmountDueBalance - Calculations.BeingPaidBalance < 0
	|
	|INDEX BY
	|	ARAPObject,
	|	AccountingDimensionByPartners,
	|	Currency
	|;
	|
	|/////////////////////////////////////////////////
	|SELECT
	|	Calculations.Period AS Period,
	|	Calculations.ARAPObject AS ARAPObject,
	|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Calculations.Currency AS Currency,
	|	Calculations.AmountDueExpense AS AmountDue
	|INTO PaymentSchedule
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting.Turnovers(,,
	|			Day,
	|			(ARAPObject, AccountingDimensionByPartners, Currency) IN 
	|			(SELECT
	|				Balance.ARAPObject,
	|				Balance.AccountingDimensionByPartners,
	|				Balance.Currency
	|			FROM
	|				Balance AS Balance)
	|		) AS Calculations
	|
	|INDEX BY
	|	ARAPObject,
	|	AccountingDimensionByPartners,
	|	Currency
	|;
	|
	|/////////////////////////////////////////////////
	|SELECT
	|	PaymentSchedule.Period AS PaymentDate,
	|	PaymentSchedule.ARAPObject AS ARAPObject,
	|	PaymentSchedule.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	PaymentSchedule.Currency AS Currency,
	|	
	|	CASE WHEN MAX(Balance.AmountDue) - MAX(PaymentSchedule.AmountDue) - SUM(ISNULL(PaymentScheduleTotal.AmountDue, 0)) > 0
	|		THEN
	|			MAX(PaymentSchedule.AmountDue)
	|		ELSE
	|			MAX(Balance.AmountDue) - SUM(ISNULL(PaymentScheduleTotal.AmountDue, 0))
	|	END AS Sum
	|	
	|INTO PaymentScheduleCalculated
	|FROM
	|	PaymentSchedule AS PaymentSchedule
	|	
	|	LEFT JOIN
	|		PaymentSchedule AS PaymentScheduleTotal
	|	ON
	|		PaymentScheduleTotal.ARAPObject = PaymentSchedule.ARAPObject
	|		AND PaymentScheduleTotal.AccountingDimensionByPartners = PaymentSchedule.AccountingDimensionByPartners
	|		AND PaymentScheduleTotal.Currency = PaymentSchedule.Currency
	|		AND PaymentScheduleTotal.Period > PaymentSchedule.Period
	|		
	|	LEFT JOIN
	|		Balance AS Balance
	|	ON
	|		Balance.ARAPObject = PaymentSchedule.ARAPObject
	|		AND Balance.AccountingDimensionByPartners = PaymentSchedule.AccountingDimensionByPartners
	|		AND Balance.Currency = PaymentSchedule.Currency
	|		
	|GROUP BY
	|	PaymentSchedule.Period,
	|	PaymentSchedule.ARAPObject,
	|	PaymentSchedule.AccountingDimensionByPartners,
	|	PaymentSchedule.Currency
	|	
	|HAVING
	|	MAX(Balance.AmountDue) - SUM(ISNULL(PaymentScheduleTotal.AmountDue, 0)) > 0
	|;
	|
	|/////////////////////////////////////////////////
	|SELECT
	|	PaymentSchedule.PaymentDate AS PaymentDate,
	|	PaymentSchedule.ARAPObject.Object AS Ref,
	|	PaymentSchedule.AccountingDimensionByPartners.Counterparty AS PayerBeneficiary,
	|	PaymentSchedule.AccountingDimensionByPartners.Organization AS Organization,
	|	PaymentSchedule.Currency AS Currency,
	|	SUM(PaymentSchedule.Sum) AS Sum
	|FROM
	|	PaymentScheduleCalculated AS PaymentSchedule
	|GROUP BY
	|	PaymentSchedule.PaymentDate,
	|	PaymentSchedule.ARAPObject.Object,
	|	PaymentSchedule.AccountingDimensionByPartners.Counterparty,
	|	PaymentSchedule.AccountingDimensionByPartners.Organization,
	|	PaymentSchedule.Currency
	|";
	
	Return QueryText;
	
EndFunction

Function RequestTextPaymentScheduleForRefundsFromSuppliers()
	
	QueryText = "
	|SELECT
	|	Calculations.ARAPObject AS ARAPObject,
	|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Calculations.Currency AS Currency,
	|	Calculations.AmountDueBalance - Calculations.BeingPaidBalance AS AmountDue
	|INTO Balance
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting.Balance(,
	|			ARAPObject IN (&ARAPObjects)
	|		) AS Calculations
	|
	|WHERE
	|	Calculations.AmountDueBalance - Calculations.BeingPaidBalance > 0
	|
	|INDEX BY
	|	ARAPObject,
	|	AccountingDimensionByPartners,
	|	Currency
	|;
	|
	|/////////////////////////////////////////////////
	|SELECT
	|	Calculations.Period AS Period,
	|	Calculations.ARAPObject AS ARAPObject,
	|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Calculations.Currency AS Currency,
	|	Calculations.AmountDueReceipt AS AmountDue
	|INTO PaymentSchedule
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting.Turnovers(,,
	|			Day,
	|			(ARAPObject, AccountingDimensionByPartners, Currency) IN 
	|			(SELECT
	|				Balance.ARAPObject,
	|				Balance.AccountingDimensionByPartners,
	|				Balance.Currency
	|			FROM
	|				Balance AS Balance)
	|		) AS Calculations
	|
	|INDEX BY
	|	ARAPObject,
	|	AccountingDimensionByPartners,
	|	Currency
	|;
	|
	|/////////////////////////////////////////////////
	|SELECT
	|	PaymentSchedule.Period AS PaymentDate,
	|	PaymentSchedule.ARAPObject AS ARAPObject,
	|	PaymentSchedule.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	PaymentSchedule.Currency AS Currency,
	|	
	|	CASE WHEN MAX(Balance.AmountDue) - MAX(PaymentSchedule.AmountDue) - SUM(ISNULL(PaymentScheduleTotal.AmountDue, 0)) > 0
	|		THEN
	|			MAX(PaymentSchedule.AmountDue)
	|		ELSE
	|			MAX(Balance.AmountDue) - SUM(ISNULL(PaymentScheduleTotal.AmountDue, 0))
	|	END AS Sum
	|	
	|INTO PaymentScheduleCalculated
	|FROM
	|	PaymentSchedule AS PaymentSchedule
	|	
	|	LEFT JOIN
	|		PaymentSchedule AS PaymentScheduleTotal
	|	ON
	|		PaymentScheduleTotal.ARAPObject = PaymentSchedule.ARAPObject
	|		AND PaymentScheduleTotal.AccountingDimensionByPartners = PaymentSchedule.AccountingDimensionByPartners
	|		AND PaymentScheduleTotal.Currency = PaymentSchedule.Currency
	|		AND PaymentScheduleTotal.Period > PaymentSchedule.Period
	|		
	|	LEFT JOIN
	|		Balance AS Balance
	|	ON
	|		Balance.ARAPObject = PaymentSchedule.ARAPObject
	|		AND Balance.AccountingDimensionByPartners = PaymentSchedule.AccountingDimensionByPartners
	|		AND Balance.Currency = PaymentSchedule.Currency
	|		
	|GROUP BY
	|	PaymentSchedule.Period,
	|	PaymentSchedule.ARAPObject,
	|	PaymentSchedule.AccountingDimensionByPartners,
	|	PaymentSchedule.Currency
	|	
	|HAVING
	|	MAX(Balance.AmountDue) - SUM(ISNULL(PaymentScheduleTotal.AmountDue, 0)) > 0
	|;
	|
	|/////////////////////////////////////////////////
	|SELECT
	|	PaymentSchedule.PaymentDate AS PaymentDate,
	|	PaymentSchedule.ARAPObject.Object AS Ref,
	|	PaymentSchedule.AccountingDimensionByPartners.Counterparty AS PayerBeneficiary,
	|	PaymentSchedule.AccountingDimensionByPartners.Organization AS Organization,
	|	PaymentSchedule.Currency AS Currency,
	|	SUM(PaymentSchedule.Sum) AS Sum
	|FROM
	|	PaymentScheduleCalculated AS PaymentSchedule
	|GROUP BY
	|	PaymentSchedule.PaymentDate,
	|	PaymentSchedule.ARAPObject.Object,
	|	PaymentSchedule.AccountingDimensionByPartners.Counterparty,
	|	PaymentSchedule.AccountingDimensionByPartners.Organization,
	|	PaymentSchedule.Currency
	|";
	
	Return QueryText;
	
EndFunction

Function RequestTextPaymentScheduleForSettlementsWithSuppliersNewArchitecture()
	
	QueryText = "
	|SELECT
	|	Calculations.ARAPObject AS ARAPObject,
	|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Calculations.Currency AS Currency,
	|	-(Calculations.AmountDueBalance - Calculations.BeingPaidBalance) AS AmountDue
	|INTO Balance
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting.Balance(,
	|			ARAPObject IN (&ARAPObjects)
	|		) AS Calculations
	|
	|WHERE
	|	Calculations.AmountDueBalance - Calculations.BeingPaidBalance < 0
	|
	|INDEX BY
	|	ARAPObject,
	|	AccountingDimensionByPartners,
	|	Currency
	|;
	|
	|/////////////////////////////////////////////////
	|SELECT
	|	PaymentPlan_.PlannedRepaymentDate AS PlannedRepaymentDate,
	|	PaymentPlan_.ARAPObject.Date AS OccurrenceDate,
	|	PaymentPlan_.ARAPObject AS ARAPObject,
	|	PaymentPlan_.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	PaymentPlan_.Currency AS Currency,
	|	PaymentPlan_.AmountDueBalance AS AmountDue
	|INTO BalancesSettlementsWithSuppliers
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingCashFlowPlan.Balance(,ARAPObject IN (&ARAPObjects)) AS PaymentPlan_
	|WHERE
	|	PaymentPlan_.AmountDueBalance <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	Calculations.PlannedRepaymentDate,
	|	Calculations.OccurrenceDate,
	|	Calculations.ARAPObject,
	|	Calculations.AccountingDimensionByPartners,
	|	Calculations.Currency,
	|	Calculations.DebtBalance
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDueDates.Balance(, ARAPObject IN (&ARAPObjects)) AS Calculations
	|WHERE
	|	Calculations.DebtBalance > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|		WHEN BalancesSettlementsWithSuppliers.PlannedRepaymentDate = DATETIME(1, 1, 1)
	|			THEN CASE
	|					WHEN BalancesSettlementsWithSuppliers.OccurrenceDate = DATETIME(1, 1, 1)
	|						THEN CASE
	|								WHEN ISNULL(ARAPObjects.Date, DATETIME(1, 1, 1)) = DATETIME(1, 1, 1)
	|									THEN &CurrentDate
	|								ELSE ARAPObjects.Date
	|							END
	|					ELSE BalancesSettlementsWithSuppliers.OccurrenceDate
	|				END
	|		ELSE BalancesSettlementsWithSuppliers.PlannedRepaymentDate
	|	END AS Period,
	|	BalancesSettlementsWithSuppliers.ARAPObject AS ARAPObject,
	|	BalancesSettlementsWithSuppliers.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	BalancesSettlementsWithSuppliers.Currency AS Currency,
	|	BalancesSettlementsWithSuppliers.AmountDue AS AmountDue
	|INTO BalancesOfSettlementsWithPeriod
	|FROM
	|	BalancesSettlementsWithSuppliers AS BalancesSettlementsWithSuppliers
	|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON BalancesSettlementsWithSuppliers.ARAPObject = ARAPObjects.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.Period AS Period,
	|	NestedQuery.ARAPObject AS ARAPObject,
	|	NestedQuery.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	NestedQuery.Currency AS Currency,
	|	SUM(NestedQuery.AmountDue) AS AmountDue
	|INTO PaymentSchedule
	|FROM BalancesOfSettlementsWithPeriod AS NestedQuery
	|GROUP BY
	|	NestedQuery.Period,
	|	NestedQuery.ARAPObject,
	|	NestedQuery.AccountingDimensionByPartners,
	|	NestedQuery.Currency
	|INDEX BY
	|	ARAPObject,
	|	AccountingDimensionByPartners,
	|	Currency
	|;
	|
	|/////////////////////////////////////////////////
	|SELECT
	|	PaymentSchedule.Period AS PaymentDate,
	|	PaymentSchedule.ARAPObject AS ARAPObject,
	|	PaymentSchedule.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	PaymentSchedule.Currency AS Currency,
	|	
	|	CASE WHEN MAX(Balance.AmountDue) - MAX(PaymentSchedule.AmountDue) - SUM(ISNULL(PaymentScheduleTotal.AmountDue, 0)) > 0
	|		THEN
	|			MAX(PaymentSchedule.AmountDue)
	|		ELSE
	|			MAX(Balance.AmountDue) - SUM(ISNULL(PaymentScheduleTotal.AmountDue, 0))
	|	END AS Sum
	|	
	|INTO PaymentScheduleCalculated
	|FROM
	|	PaymentSchedule AS PaymentSchedule
	|	
	|	LEFT JOIN
	|		PaymentSchedule AS PaymentScheduleTotal
	|	ON
	|		PaymentScheduleTotal.ARAPObject = PaymentSchedule.ARAPObject
	|		AND PaymentScheduleTotal.AccountingDimensionByPartners = PaymentSchedule.AccountingDimensionByPartners
	|		AND PaymentScheduleTotal.Currency = PaymentSchedule.Currency
	|		AND PaymentScheduleTotal.Period > PaymentSchedule.Period
	|		
	|	LEFT JOIN
	|		Balance AS Balance
	|	ON
	|		Balance.ARAPObject = PaymentSchedule.ARAPObject
	|		AND Balance.AccountingDimensionByPartners = PaymentSchedule.AccountingDimensionByPartners
	|		AND Balance.Currency = PaymentSchedule.Currency
	|		
	|GROUP BY
	|	PaymentSchedule.Period,
	|	PaymentSchedule.ARAPObject,
	|	PaymentSchedule.AccountingDimensionByPartners,
	|	PaymentSchedule.Currency
	|	
	|HAVING
	|	MAX(Balance.AmountDue) - SUM(ISNULL(PaymentScheduleTotal.AmountDue, 0)) > 0
	|;
	|
	|/////////////////////////////////////////////////
	|SELECT
	|	PaymentSchedule.PaymentDate AS PaymentDate,
	|	PaymentSchedule.ARAPObject.Object AS Ref,
	|	PaymentSchedule.AccountingDimensionByPartners.Counterparty AS PayerBeneficiary,
	|	PaymentSchedule.AccountingDimensionByPartners.Organization AS Organization,
	|	PaymentSchedule.Currency AS Currency,
	|	SUM(PaymentSchedule.Sum) AS Sum
	|FROM
	|	PaymentScheduleCalculated AS PaymentSchedule
	|GROUP BY
	|	PaymentSchedule.PaymentDate,
	|	PaymentSchedule.ARAPObject.Object,
	|	PaymentSchedule.AccountingDimensionByPartners.Counterparty,
	|	PaymentSchedule.AccountingDimensionByPartners.Organization,
	|	PaymentSchedule.Currency
	|";
	
	Return QueryText;
	
EndFunction

Function RequestTextPaymentScheduleForRefundsFromSuppliersNewArchitecture()
	
	QueryText = "
	|SELECT
	|	Calculations.ARAPObject AS ARAPObject,
	|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Calculations.Currency AS Currency,
	|	Calculations.AmountDueBalance - Calculations.BeingPaidBalance AS AmountDue
	|INTO Balance
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting.Balance(,
	|			ARAPObject IN (&ARAPObjects)
	|		) AS Calculations
	|
	|WHERE
	|	Calculations.AmountDueBalance - Calculations.BeingPaidBalance > 0
	|
	|INDEX BY
	|	ARAPObject,
	|	AccountingDimensionByPartners,
	|	Currency
	|;
	|
	|/////////////////////////////////////////////////
	|SELECT
	|	PaymentPlan_.PlannedRepaymentDate AS Period,
	|	PaymentPlan_.ARAPObject AS ARAPObject,
	|	PaymentPlan_.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	PaymentPlan_.Currency AS Currency,
	|	SUM(PaymentPlan_.AmountDueBalance) AS AmountDue
	|INTO PaymentSchedule
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingCashFlowPlan.Balance(, ARAPObject IN (&ARAPObjects)) AS PaymentPlan_
	|WHERE
	|	PaymentPlan_.AmountDueBalance <> 0
	|GROUP BY
	|	PaymentPlan_.PlannedRepaymentDate,
	|	PaymentPlan_.ARAPObject,
	|	PaymentPlan_.AccountingDimensionByPartners,
	|	PaymentPlan_.Currency
	|INDEX BY
	|	ARAPObject,
	|	AccountingDimensionByPartners,
	|	Currency
	|;
	|
	|/////////////////////////////////////////////////
	|SELECT
	|	PaymentSchedule.Period AS PaymentDate,
	|	PaymentSchedule.ARAPObject AS ARAPObject,
	|	PaymentSchedule.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	PaymentSchedule.Currency AS Currency,
	|	
	|	CASE WHEN MAX(Balance.AmountDue) - MAX(PaymentSchedule.AmountDue) - SUM(ISNULL(PaymentScheduleTotal.AmountDue, 0)) > 0
	|		THEN
	|			MAX(PaymentSchedule.AmountDue)
	|		ELSE
	|			MAX(Balance.AmountDue) - SUM(ISNULL(PaymentScheduleTotal.AmountDue, 0))
	|	END AS Sum
	|	
	|INTO PaymentScheduleCalculated
	|FROM
	|	PaymentSchedule AS PaymentSchedule
	|	
	|	LEFT JOIN
	|		PaymentSchedule AS PaymentScheduleTotal
	|	ON
	|		PaymentScheduleTotal.ARAPObject = PaymentSchedule.ARAPObject
	|		AND PaymentScheduleTotal.AccountingDimensionByPartners = PaymentSchedule.AccountingDimensionByPartners
	|		AND PaymentScheduleTotal.Currency = PaymentSchedule.Currency
	|		AND PaymentScheduleTotal.Period > PaymentSchedule.Period
	|		
	|	LEFT JOIN
	|		Balance AS Balance
	|	ON
	|		Balance.ARAPObject = PaymentSchedule.ARAPObject
	|		AND Balance.AccountingDimensionByPartners = PaymentSchedule.AccountingDimensionByPartners
	|		AND Balance.Currency = PaymentSchedule.Currency
	|		
	|GROUP BY
	|	PaymentSchedule.Period,
	|	PaymentSchedule.ARAPObject,
	|	PaymentSchedule.AccountingDimensionByPartners,
	|	PaymentSchedule.Currency
	|	
	|HAVING
	|	MAX(Balance.AmountDue) - SUM(ISNULL(PaymentScheduleTotal.AmountDue, 0)) > 0
	|;
	|
	|/////////////////////////////////////////////////
	|SELECT
	|	PaymentSchedule.PaymentDate AS PaymentDate,
	|	PaymentSchedule.ARAPObject.Object AS Ref,
	|	PaymentSchedule.AccountingDimensionByPartners.Counterparty AS PayerBeneficiary,
	|	PaymentSchedule.AccountingDimensionByPartners.Organization AS Organization,
	|	PaymentSchedule.Currency AS Currency,
	|	SUM(PaymentSchedule.Sum) AS Sum
	|FROM
	|	PaymentScheduleCalculated AS PaymentSchedule
	|GROUP BY
	|	PaymentSchedule.PaymentDate,
	|	PaymentSchedule.ARAPObject.Object,
	|	PaymentSchedule.AccountingDimensionByPartners.Counterparty,
	|	PaymentSchedule.AccountingDimensionByPartners.Organization,
	|	PaymentSchedule.Currency
	|";
	
	Return QueryText;
	
EndFunction

Function RequestTextPaymentScheduleForRequests()
	
	QueryText = "
	|SELECT
	|	Cash.PaymentRequest AS Request,
	|	Cash.BankAccountCashAccount AS BankAccountCashAccount,
	|	Cash.SumBalance AS ToBePaid
	|INTO Balance
	|FROM
	|	AccumulationRegister.CashToBePaid.Balance(,
	|			PaymentRequest IN (&PaymentObjects)
	|		) AS Cash
	|
	|WHERE
	|	Cash.SumBalance > 0
	|
	|INDEX BY
	|	PaymentRequest,
	|	BankAccountCashAccount
	|;
	|
	|/////////////////////////////////////////////////
	|SELECT
	|	Cash.Period AS Period,
	|	Cash.PaymentRequest AS Request,
	|	Cash.BankAccountCashAccount AS BankAccountCashAccount,
	|	Cash.SumReceipt AS ToBePaid
	|INTO PaymentSchedule
	|FROM
	|	AccumulationRegister.CashToBePaid.Turnovers(,,
	|			Day,
	|			(PaymentRequest, BankAccountCashAccount) IN
	|			(SELECT
	|				Balance.Request,
	|				Balance.BankAccountCashAccount
	|			FROM
	|				Balance AS Balance)
	|		) AS Cash
	|
	|INDEX BY
	|	PaymentRequest,
	|	BankAccountCashAccount
	|;
	|
	|/////////////////////////////////////////////////
	|SELECT
	|	PaymentSchedule.Period AS PaymentDate,
	|	PaymentSchedule.Request AS Ref,
	|	PaymentSchedule.BankAccountCashAccount AS BankAccountCashAccount,
	|	
	|	CASE WHEN MAX(Balance.ToBePaid) - MAX(PaymentSchedule.ToBePaid) - SUM(ISNULL(PaymentScheduleTotal.ToBePaid, 0)) > 0
	|		THEN
	|			MAX(PaymentSchedule.ToBePaid)
	|		ELSE
	|			MAX(Balance.ToBePaid) - SUM(ISNULL(PaymentScheduleTotal.ToBePaid, 0))
	|	END AS Sum
	|
	|INTO PaymentScheduleSummary
	|FROM
	|	PaymentSchedule AS PaymentSchedule
	|	
	|	LEFT JOIN
	|		PaymentSchedule AS PaymentScheduleTotal
	|	ON
	|		PaymentScheduleTotal.Request = PaymentSchedule.Request
	|		AND PaymentScheduleTotal.BankAccountCashAccount = PaymentSchedule.BankAccountCashAccount
	|		AND PaymentScheduleTotal.Period > PaymentSchedule.Period
	|		
	|	LEFT JOIN
	|		Balance AS Balance
	|	ON
	|		Balance.Request = PaymentSchedule.Request
	|		AND Balance.BankAccountCashAccount = PaymentSchedule.BankAccountCashAccount
	|		
	|GROUP BY
	|	PaymentSchedule.Period,
	|	PaymentSchedule.Request,
	|	PaymentSchedule.BankAccountCashAccount
	|	
	|HAVING
	|	MAX(Balance.ToBePaid) - SUM(ISNULL(PaymentScheduleTotal.ToBePaid, 0)) > 0
	|	
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ScheduleOfPayments.Ref AS PaymentObject,
	|	ScheduleOfPayments.BankAccountCashAccount AS BankAccountCashAccount,
	|	ScheduleOfPayments.PaymentDate AS PaymentDate,
	|	VALUE(Enum.CashFlowTypes.WriteOff) AS ReceiptIssue,
	|	CASE
	|		WHEN Request.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.CashIssueAsLoanToEmployee),
	|			VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
	|			)
	|		THEN
	|			Request.AdvanceHolder
	|		WHEN Request.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany),
	|			VALUE(Enum.BusinessTransactions.RefundToAnotherCompany),
	|			VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices)
	|			)
	|		THEN
	|			Request.CompanyRecipient
	|		ELSE
	|			Request.Counterparty
	|	END AS PayerBeneficiary,
	|	Request.Currency AS Currency,
	|	
	|	ScheduleOfPayments.Sum AS Sum,
	|	
	|	Request.CashFlowItem AS CashFlowItem,
	|	Request.BusinessOperation AS BusinessOperation,
	|	Request.Department AS Department,
	|	
	|	CASE WHEN ScheduleOfPayments.BankAccountCashAccount REFS Catalog.CashAccounts THEN
	|		CAST(ScheduleOfPayments.BankAccountCashAccount AS Catalog.CashAccounts).LineOfBusiness
	|	WHEN ScheduleOfPayments.BankAccountCashAccount REFS Catalog.CompaniesBankAccounts THEN
	|		CAST(ScheduleOfPayments.BankAccountCashAccount AS Catalog.CompaniesBankAccounts).LineOfBusiness
	|	WHEN ScheduleOfPayments.BankAccountCashAccount = UNDEFINED THEN
	|		UNDEFINED
	|	END AS LineOfBusiness,
	|	
	|	Request.PaymentPriority AS Priority,
	|	Request.WhoStated AS EmployeeResponsible,
	|	Request.Number AS Number,
	|	Request.Date AS Date,
	|	Request.Organization AS Organization,
	|	Request.DocumentAmount AS DocumentAmount,
	|	Request.Status AS Status,
	|	
	|	CASE
	|		WHEN Request.Status = VALUE(Enum.StatusesOfPaymentRequests.NotAgreedUpon) THEN
	|			VALUE(Enum.PaymentPlanningAreas.PaymentRequestsPendingApproval)
	|		ELSE
	|			VALUE(Enum.PaymentPlanningAreas.CashPaymentRequests)
	|	END AS PlanningArea,
	|	CASE
	|		WHEN Request.PaymentMethodOfPaymentRequest <> VALUE(Enum.PaymentForms.EmptyRef) THEN
	|			Request.PaymentMethodOfPaymentRequest
	|		WHEN VALUETYPE(ScheduleOfPayments.BankAccountCashAccount) = TYPE(Catalog.CompaniesBankAccounts) THEN
	|			VALUE(Enum.PaymentForms.BankAccountPayment)
	|		WHEN VALUETYPE(ScheduleOfPayments.BankAccountCashAccount) = TYPE(Catalog.CashAccounts) THEN
	|			VALUE(Enum.PaymentForms.CashAccountPayment_)
	|		ELSE
	|			Request.PaymentMethodOfPaymentRequest
	|	END AS PaymentMethod
	|	
	|FROM
	|	PaymentScheduleSummary AS ScheduleOfPayments
	|	
	|	INNER JOIN Document.PaymentRequest AS Request
	|	ON Request.Ref = ScheduleOfPayments.Ref
	|	
	|UNION ALL
	|	
	|SELECT
	|	ScheduleOfPayments.Ref AS PaymentObject,
	|	CASE
	|		WHEN Request.PaymentMethodOfPaymentRequest = VALUE(Enum.PaymentForms.CashAccountPayment_) THEN
	|			Request.CashAccountRecipient
	|		WHEN Request.PaymentMethodOfPaymentRequest = VALUE(Enum.PaymentForms.BankAccountPayment) THEN
	|			Request.BankAccountBeneficiary
	|		ELSE
	|			UNDEFINED
	|	END AS BankAccountCashAccount,
	
	|	ScheduleOfPayments.PaymentDate AS PaymentDate,
	|	VALUE(Enum.CashFlowTypes.Inpayment) AS ReceiptIssue,
	
	|	CASE
	|		WHEN Request.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices)
	|			)
	|		THEN
	|			Request.Organization
	|		ELSE
	|			Request.Counterparty
	|	END AS PayerBeneficiary,
	
	|	CASE
	|		WHEN Request.BusinessOperation = VALUE(Enum.BusinessTransactions.CurrencyConversion) THEN
	|			Request.CurrencyOfConversion
	|		ELSE
	|			Request.Currency
	|	END AS Currency,
	|	
	|	SUM(CASE
	|		WHEN Request.BusinessOperation = VALUE(Enum.BusinessTransactions.CurrencyConversion) THEN
	|			CASE
	|				WHEN Request.CurrencyOfConversion = Request.Organization.LocalAccountingCurrency THEN
	|					CASE WHEN Request.ConversionRateMultiplier <> 0 THEN
	|						ScheduleOfPayments.Sum * Request.ConversionRate / Request.ConversionRateMultiplier
	|					ELSE
	|						0
	|					END
	|				ELSE
	|					CASE WHEN Request.ConversionRate <> 0 THEN
	|						ScheduleOfPayments.Sum / Request.ConversionRate * Request.ConversionRateMultiplier
	|					ELSE
	|						0
	|					END
	|				END
	|			ELSE
	|				ScheduleOfPayments.Sum
	|		END) AS Sum,
	|	
	|	Request.CashFlowItem AS CashFlowItem,
	|	Request.BusinessOperation AS BusinessOperation,
	|	Request.Department AS Department,
	|	
	|	CASE
	|		WHEN Request.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices)
	|			) THEN
	|				CASE WHEN Request.PaymentMethodOfPaymentRequest = VALUE(Enum.PaymentForms.CashAccountPayment_) THEN
	|					Request.CashAccountRecipient.LineOfBusiness
	|				ELSE
	|					Request.BankAccountBeneficiary.LineOfBusiness
	|				END
	|		ELSE
	|			UNDEFINED
	|	END AS LineOfBusiness,
	|	
	|	Request.PaymentPriority AS Priority,
	|	Request.WhoStated AS EmployeeResponsible,
	|	Request.Number AS Number,
	|	Request.Date AS Date,
	|	
	|	CASE
	|		WHEN Request.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices)
	|			) THEN
	|				Request.CompanyRecipient
	|		ELSE
	|			Request.Organization
	|	END AS Organization,
	|	
	|	Request.DocumentAmount AS DocumentAmount,
	|	Request.Status AS Status,
	|	
	|	CASE
	|		WHEN Request.Status = VALUE(Enum.StatusesOfPaymentRequests.NotAgreedUpon) THEN
	|			VALUE(Enum.PaymentPlanningAreas.PaymentRequestsPendingApproval)
	|		ELSE
	|			VALUE(Enum.PaymentPlanningAreas.CashPaymentRequests)
	|	END AS PlanningArea,
	|	Request.PaymentMethodOfPaymentRequest AS PaymentMethod
	|	
	|FROM
	|	PaymentScheduleSummary AS ScheduleOfPayments
	|	
	|	INNER JOIN Document.PaymentRequest AS Request
	|	ON Request.Ref = ScheduleOfPayments.Ref
	|
	|	LEFT JOIN Constants
	|	ON TRUE
	|	
	|WHERE
	|	Request.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices),
	|		VALUE(Enum.BusinessTransactions.CurrencyConversion)
	|	)
	|
	|GROUP BY
	|	ScheduleOfPayments.Ref,
	|	Request.Ref,
	|	ScheduleOfPayments.PaymentDate
	|
	|UNION ALL
	|
	|SELECT
	|	ScheduleOfPayments.Ref AS PaymentObject,
	|	CASE
	|		WHEN Request.PaymentMethodOfPaymentRequest = VALUE(Enum.PaymentForms.CashAccountPayment_) THEN
	|			Request.CashAccountRecipient
	|		WHEN Request.PaymentMethodOfPaymentRequest = VALUE(Enum.PaymentForms.BankAccountPayment) THEN
	|			Request.BankAccountBeneficiary
	|		ELSE
	|			UNDEFINED
	|	END AS BankAccountCashAccount,
	
	|	ScheduleOfPayments.PaymentDate AS PaymentDate,
	|	VALUE(Enum.CashFlowTypes.Inpayment) AS ReceiptIssue,
	
	|	Request.Organization AS PayerBeneficiary,
	
	|	Request.Currency AS Currency,
	|	
	|	SUM(ScheduleOfPayments.Sum) AS Sum,
	|	
	|	Request.CashFlowItem AS CashFlowItem,
	|	Request.BusinessOperation AS BusinessOperation,
	|	Request.Department AS Department,
	|	
	|	CASE WHEN Request.PaymentMethodOfPaymentRequest = VALUE(Enum.PaymentForms.CashAccountPayment_) THEN
	|		Request.CashAccountRecipient.LineOfBusiness
	|	ELSE
	|		Request.BankAccountBeneficiary.LineOfBusiness
	|	END AS LineOfBusiness,
	|	
	|	Request.PaymentPriority AS Priority,
	|	Request.WhoStated AS EmployeeResponsible,
	|	Request.Number AS Number,
	|	Request.Date AS Date,
	|	
	|	Request.CompanyRecipient AS Organization,
	|	
	|	Request.DocumentAmount AS DocumentAmount,
	|	Request.Status AS Status,
	|	
	|	CASE
	|		WHEN Request.Status = VALUE(Enum.StatusesOfPaymentRequests.NotAgreedUpon) THEN
	|			VALUE(Enum.PaymentPlanningAreas.PaymentRequestsPendingApproval)
	|		ELSE
	|			VALUE(Enum.PaymentPlanningAreas.CashPaymentRequests)
	|	END AS PlanningArea,
	|	Request.PaymentMethodOfPaymentRequest AS PaymentMethod
	|	
	|FROM
	|	PaymentScheduleSummary AS ScheduleOfPayments
	|	
	|	INNER JOIN Document.PaymentRequest AS Request
	|	ON Request.Ref = ScheduleOfPayments.Ref
	|
	|	LEFT JOIN Constants
	|	ON TRUE
	|	
	|WHERE
	|	Request.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany),
	|		VALUE(Enum.BusinessTransactions.RefundToAnotherCompany)
	|	)
	|	AND NOT Request.ControlPaymentByARAPObjects
	|
	|GROUP BY
	|	ScheduleOfPayments.Ref,
	|	Request.Ref,
	|	ScheduleOfPayments.PaymentDate
	|";
	
	Return QueryText;
	
EndFunction

Function RequestTextPaymentScheduleForBusinessTripRequests()
	
	QueryText = "
	|SELECT
	|	Cash.PaymentRequest AS Request,
	|	Cash.BankAccountCashAccount AS BankAccountCashAccount,
	|	Cash.SumBalance AS ToBePaid
	|INTO Balance
	|FROM
	|	AccumulationRegister.CashToBePaid.Balance(,
	|			PaymentRequest IN (&PaymentObjects)
	|		) AS Cash
	|
	|WHERE
	|	Cash.SumBalance > 0
	|
	|INDEX BY
	|	PaymentRequest,
	|	BankAccountCashAccount
	|;
	|
	|/////////////////////////////////////////////////
	|SELECT
	|	Cash.Period AS Period,
	|	Cash.PaymentRequest AS Request,
	|	Cash.BankAccountCashAccount AS BankAccountCashAccount,
	|	Cash.SumReceipt AS ToBePaid
	|INTO PaymentSchedule
	|FROM
	|	AccumulationRegister.CashToBePaid.Turnovers(,,
	|			Day,
	|			(PaymentRequest, BankAccountCashAccount) IN
	|			(SELECT
	|				Balance.Request,
	|				Balance.BankAccountCashAccount
	|			FROM
	|				Balance AS Balance)
	|		) AS Cash
	|
	|INDEX BY
	|	PaymentRequest,
	|	BankAccountCashAccount
	|;
	|
	|/////////////////////////////////////////////////
	|SELECT
	|	PaymentSchedule.Period AS PaymentDate,
	|	PaymentSchedule.Request AS Ref,
	|	PaymentSchedule.BankAccountCashAccount AS BankAccountCashAccount,
	|	
	|	CASE WHEN MAX(Balance.ToBePaid) - MAX(PaymentSchedule.ToBePaid) - SUM(ISNULL(PaymentScheduleTotal.ToBePaid, 0)) > 0
	|		THEN
	|			MAX(PaymentSchedule.ToBePaid)
	|		ELSE
	|			MAX(Balance.ToBePaid) - SUM(ISNULL(PaymentScheduleTotal.ToBePaid, 0))
	|	END AS Sum
	|
	|INTO PaymentScheduleSummary
	|FROM
	|	PaymentSchedule AS PaymentSchedule
	|	
	|	LEFT JOIN
	|		PaymentSchedule AS PaymentScheduleTotal
	|	ON
	|		PaymentScheduleTotal.Request = PaymentSchedule.Request
	|		AND PaymentScheduleTotal.BankAccountCashAccount = PaymentSchedule.BankAccountCashAccount
	|		AND PaymentScheduleTotal.Period > PaymentSchedule.Period
	|		
	|	LEFT JOIN
	|		Balance AS Balance
	|	ON
	|		Balance.Request = PaymentSchedule.Request
	|		AND Balance.BankAccountCashAccount = PaymentSchedule.BankAccountCashAccount
	|		
	|GROUP BY
	|	PaymentSchedule.Period,
	|	PaymentSchedule.Request,
	|	PaymentSchedule.BankAccountCashAccount
	|	
	|HAVING
	|	MAX(Balance.ToBePaid) - SUM(ISNULL(PaymentScheduleTotal.ToBePaid, 0)) > 0
	|	
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ScheduleOfPayments.Ref AS PaymentObject,
	|	ScheduleOfPayments.BankAccountCashAccount AS BankAccountCashAccount,
	|	ScheduleOfPayments.PaymentDate AS PaymentDate,
	|	VALUE(Enum.CashFlowTypes.WriteOff) AS ReceiptIssue,
	|	Request.Employee AS PayerBeneficiary,
	|	Request.Currency AS Currency,
	|	
	|	ScheduleOfPayments.Sum AS Sum,
	|	
	|	Request.CashFlowItem AS CashFlowItem,
	|	VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder) AS BusinessOperation,
	|	Request.Department AS Department,
	|	
	|	CASE WHEN ScheduleOfPayments.BankAccountCashAccount REFS Catalog.CashAccounts THEN
	|		CAST(ScheduleOfPayments.BankAccountCashAccount AS Catalog.CashAccounts).LineOfBusiness
	|	WHEN ScheduleOfPayments.BankAccountCashAccount REFS Catalog.CompaniesBankAccounts THEN
	|		CAST(ScheduleOfPayments.BankAccountCashAccount AS Catalog.CompaniesBankAccounts).LineOfBusiness
	|	WHEN ScheduleOfPayments.BankAccountCashAccount = UNDEFINED THEN
	|		UNDEFINED
	|	END AS LineOfBusiness,
	|	
	|	Request.EmployeeResponsible AS EmployeeResponsible,
	|	Request.Number AS Number,
	|	Request.Date AS Date,
	|	Request.Organization AS Organization,
	|	Request.DocumentAmount AS DocumentAmount,
	|	
	|	CASE
	|		WHEN Request.Status IN (
	|			VALUE(Enum.EmployeeApplicationStatuses.IsPrepared),
	|			VALUE(Enum.EmployeeApplicationStatuses.Considered)
	|			) THEN
	|			VALUE(Enum.PaymentPlanningAreas.PaymentRequestsPendingApproval)
	|		ELSE
	|			VALUE(Enum.PaymentPlanningAreas.CashPaymentRequests)
	|	END AS PlanningArea,
	|	CASE
	|		WHEN VALUETYPE(ScheduleOfPayments.BankAccountCashAccount) = TYPE(Catalog.CompaniesBankAccounts) THEN
	|			VALUE(Enum.PaymentForms.BankAccountPayment)
	|		WHEN VALUETYPE(ScheduleOfPayments.BankAccountCashAccount) = TYPE(Catalog.CashAccounts) THEN
	|			VALUE(Enum.PaymentForms.CashAccountPayment_)
	|		ELSE
	|			Request.PaymentMethodOfPaymentRequest
	|	END AS PaymentMethod,
	|	Request.Status AS Status
	|	
	|FROM
	|	PaymentScheduleSummary AS ScheduleOfPayments
	|	
	|	INNER JOIN Document.ApplicationForBusinessTrip AS Request
	|	ON Request.Ref = ScheduleOfPayments.Ref
	|";
	
	Return QueryText;
	
EndFunction

Function RequestTextPaymentScheduleForPaymentOrders()
	
	QueryText = "
	|SELECT
	|	Cash.PaymentRequest AS Ref,
	|	Cash.BankAccountCashAccount AS BankAccountCashAccount,
	|	Cash.Recipient AS Recipient,
	|	Cash.Organization AS Organization,
	|	Cash.SumBalance AS Sum
	|	
	|INTO Cash
	|FROM
	|	AccumulationRegister.CashToBePaid.Balance(, PaymentRequest IN (&PaymentObjects)) AS Cash
	|	
	|WHERE
	|	Cash.PaymentRequest REFS Document.CashTransferReferenceOrder
	|	AND Cash.SumBalance > 0
	|
	|INDEX BY
	|	Ref
	|;
	|
	|///////////////////////////////////////////////////////////////////////
	|SELECT
	|	Cash.Ref AS PaymentObject,
	|	Cash.BankAccountCashAccount AS BankAccountCashAccount,
	|	ReferenceOrder.PaymentDate AS PaymentDate,
	|	VALUE(Enum.CashFlowTypes.WriteOff) AS ReceiptIssue,
	|	Cash.Recipient AS PayerBeneficiary,
	|	ReferenceOrder.Currency AS Currency,
	|	
	|	Cash.Sum AS Sum,
	|	
	|	ReferenceOrder.CashFlowItem AS CashFlowItem,
	|	ReferenceOrder.BusinessOperation AS BusinessOperation,
	|	ReferenceOrder.Department AS Department,
	|	ReferenceOrder.WhoDecided AS EmployeeResponsible,
	|	
	|	CASE ReferenceOrder.BusinessOperation
	|		WHEN VALUE(Enum.BusinessTransactions.CashDepositToBankAccount) THEN
	|			ReferenceOrder.CashAccount.LineOfBusiness
	|		WHEN VALUE(Enum.BusinessTransactions.CashCollectionToBank) THEN
	|			ReferenceOrder.CashAccount.LineOfBusiness
	|		WHEN VALUE(Enum.BusinessTransactions.CashIssueToAnotherCashAccount) THEN
	|			ReferenceOrder.CashAccount.LineOfBusiness
	|		WHEN VALUE(Enum.BusinessTransactions.TransferCashToAnotherAccount) THEN
	|			ReferenceOrder.BankAccount.LineOfBusiness
	|		WHEN VALUE(Enum.BusinessTransactions.CashReceiptFromBank) THEN
	|			ReferenceOrder.BankAccount.LineOfBusiness
	|		WHEN VALUE(Enum.BusinessTransactions.WithdrawalFromBankAccount) THEN
	|			ReferenceOrder.BankAccount.LineOfBusiness
	|	END AS LineOfBusiness,
	|
	|	ReferenceOrder.Number AS Number,
	|	ReferenceOrder.Date AS Date,
	|	ReferenceOrder.Organization AS Organization,
	|	ReferenceOrder.DocumentAmount AS DocumentAmount,
	|
	|	CASE
	|		WHEN ReferenceOrder.Status = VALUE(Enum.CashTransferOrderStatuses.NotApproved) THEN
	|			VALUE(Enum.PaymentPlanningAreas.ReferencesForCashTransferPendingApproval)
	|		ELSE
	|			VALUE(Enum.PaymentPlanningAreas.ReferencesForCashTransfer)
	|	END AS PlanningArea,
	|	CASE
	|		WHEN ReferenceOrder.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.CashDepositToBankAccount),
	|			VALUE(Enum.BusinessTransactions.CashCollectionToBank),
	|			VALUE(Enum.BusinessTransactions.CashIssueToAnotherCashAccount))
	|		THEN
	|			VALUE(Enum.PaymentForms.CashAccountPayment_)
	|		WHEN ReferenceOrder.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.TransferCashToAnotherAccount),
	|			VALUE(Enum.BusinessTransactions.CashReceiptFromBank),
	|			VALUE(Enum.BusinessTransactions.WithdrawalFromBankAccount))
	|		THEN
	|			VALUE(Enum.PaymentForms.BankAccountPayment)
	|	END AS PaymentMethod
	|	
	|FROM
	|	Cash AS Cash
	|	
	|	INNER JOIN
	|		Document.CashTransferReferenceOrder AS ReferenceOrder
	|	ON
	|		ReferenceOrder.Ref = Cash.Ref
	|
	|UNION ALL
	|
	|SELECT
	|	Cash.Ref AS PaymentObject,
	|	
	|	CASE ReferenceOrder.BusinessOperation
	|		WHEN VALUE(Enum.BusinessTransactions.CashDepositToBankAccount) THEN
	|			ReferenceOrder.BankAccountBeneficiary
	|		WHEN VALUE(Enum.BusinessTransactions.CashCollectionToBank) THEN
	|			ReferenceOrder.BankAccountBeneficiary
	|		WHEN VALUE(Enum.BusinessTransactions.CashIssueToAnotherCashAccount) THEN
	|			ReferenceOrder.CashAccountRecipient
	|		WHEN VALUE(Enum.BusinessTransactions.TransferCashToAnotherAccount) THEN
	|			ReferenceOrder.BankAccountBeneficiary
	|		WHEN VALUE(Enum.BusinessTransactions.CashReceiptFromBank) THEN
	|			ReferenceOrder.CashAccountRecipient
	|		WHEN VALUE(Enum.BusinessTransactions.WithdrawalFromBankAccount) THEN
	|			ReferenceOrder.CashAccountRecipient
	|	END AS BankAccountCashAccount,
	|	
	|	ReferenceOrder.PaymentDate AS PaymentDate,
	|	VALUE(Enum.CashFlowTypes.Inpayment) AS ReceiptIssue,
	|	Cash.Recipient AS PayerBeneficiary,
	|	ReferenceOrder.Currency AS Currency,
	|	
	|	Cash.Sum AS Sum,
	|	
	|	ReferenceOrder.CashFlowItem AS CashFlowItem,
	|	ReferenceOrder.BusinessOperation AS BusinessOperation,
	|	ReferenceOrder.Department AS Department,
	|	ReferenceOrder.WhoDecided AS EmployeeResponsible,
	|	
	|	CASE ReferenceOrder.BusinessOperation
	|		WHEN VALUE(Enum.BusinessTransactions.CashDepositToBankAccount) THEN
	|			ReferenceOrder.BankAccountBeneficiary.LineOfBusiness
	|		WHEN VALUE(Enum.BusinessTransactions.CashCollectionToBank) THEN
	|			ReferenceOrder.BankAccountBeneficiary.LineOfBusiness
	|		WHEN VALUE(Enum.BusinessTransactions.CashIssueToAnotherCashAccount) THEN
	|			ReferenceOrder.CashAccountRecipient.LineOfBusiness
	|		WHEN VALUE(Enum.BusinessTransactions.TransferCashToAnotherAccount) THEN
	|			ReferenceOrder.BankAccountBeneficiary.LineOfBusiness
	|		WHEN VALUE(Enum.BusinessTransactions.CashReceiptFromBank) THEN
	|			ReferenceOrder.CashAccountRecipient.LineOfBusiness
	|		WHEN VALUE(Enum.BusinessTransactions.WithdrawalFromBankAccount) THEN
	|			ReferenceOrder.CashAccountRecipient.LineOfBusiness
	|	END AS LineOfBusiness,
	|	
	|	ReferenceOrder.Number AS Number,
	|	ReferenceOrder.Date AS Date,
	|	ReferenceOrder.Organization AS Organization,
	|	ReferenceOrder.DocumentAmount AS DocumentAmount,
	|
	|	CASE WHEN ReferenceOrder.Status = VALUE(Enum.CashTransferOrderStatuses.NotApproved) THEN
	|		VALUE(Enum.PaymentPlanningAreas.ReferencesForCashTransferPendingApproval)
	|	ELSE
	|		VALUE(Enum.PaymentPlanningAreas.ReferencesForCashTransfer)
	|	END AS PlanningArea,
	|	CASE
	|		WHEN ReferenceOrder.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.CashIssueToAnotherCashAccount),
	|			VALUE(Enum.BusinessTransactions.CashReceiptFromBank),
	|			VALUE(Enum.BusinessTransactions.WithdrawalFromBankAccount))
	|		THEN
	|			VALUE(Enum.PaymentForms.CashAccountPayment_)
	|		WHEN ReferenceOrder.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.CashDepositToBankAccount),
	|			VALUE(Enum.BusinessTransactions.CashCollectionToBank),
	|			VALUE(Enum.BusinessTransactions.TransferCashToAnotherAccount))
	|		THEN
	|			VALUE(Enum.PaymentForms.BankAccountPayment)
	|	END AS PaymentMethod
	|
	|FROM
	|	Cash AS Cash
	|	
	|	INNER JOIN
	|		Document.CashTransferReferenceOrder AS ReferenceOrder
	|	ON
	|		ReferenceOrder.Ref = Cash.Ref
	|";
	
	Return QueryText;
	
EndFunction


Function RequestTextScheduleOfPaymentsUnderLoanAndDepositAgreements()
	
	QueryText = "
	|SELECT
	|	CatalogData.Ref                            AS PaymentObject,
	|	CatalogData.ContractKind                  AS ContractKind,
	|	CatalogData.ARAPCurrency              AS Currency,
	|	CatalogData.BankAccount                    AS BankAccount,
	|	CatalogData.CashAccount                             AS CashAccount,
	|	CatalogData.InterestBankAccount           AS InterestBankAccount,
	|	CatalogData.BankAccountOfFee            AS BankAccountOfFee,
	|	CatalogData.Counterparty                        AS PayerBeneficiary,
	|	CatalogData.Organization                       AS Organization,
	|	CatalogData.CashFlowItemOfReceiptIssuie        AS CashFlowItem,
	|	CatalogData.CashFlowItemOfPrincipalDebt           AS CashFlowItemOfPrincipalDebt,
	|	CatalogData.CashFlowItemOfInterestPayment                AS CashFlowItemOfInterestPayment,
	|	CatalogData.CashFlowItemOfFeePayment                 AS CashFlowItemOfFeePayment,
	|	CatalogData.Department                     AS Department,
	|	CatalogData.LineOfBusiness           AS LineOfBusiness,
	|	CatalogData.EmployeeResponsible                     AS EmployeeResponsible,
	|	CatalogData.Number                             AS Number,
	|	CatalogData.Date                              AS Date,
	|	CatalogData.TrancheAmount                      AS DocumentAmount,
	|	CatalogData.PaymentMethod                       AS PaymentMethod,
	|	CatalogData.Status                            AS Status,
	|	CASE CatalogData.ContractKind
	|		WHEN VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing) THEN
	|			VALUE(Enum.PaymentPlanningAreas.LoansOrBorrowingsReceived)
	|		WHEN VALUE(Enum.ContractKindsOfFinancialInstruments.Deposit) THEN
	|			VALUE(Enum.PaymentPlanningAreas.Deposits)
	|		WHEN VALUE(Enum.ContractKindsOfFinancialInstruments.IssuedBorrowing) THEN
	|			VALUE(Enum.PaymentPlanningAreas.IssuedBorrowings)
	|	END AS PlanningArea
	|INTO Contracts
	|FROM
	|	Catalog.LoanAndDepositContracts AS CatalogData
	|WHERE
	|	CatalogData.Ref IN (&PaymentObjects)
	|INDEX BY
	|	PaymentObject,
	|	ContractKind
	|;
	|
	|SELECT
	|	Calculations.Contract AS Contract,
	|	Calculations.Currency AS Currency,
	|	Calculations.AmountType AS AmountType,
	|	Calculations.SumExpense AS Sum
	|INTO ReceiptOfFunds
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP.Turnovers(,,,
	|		Contract IN (&PaymentObjects)
	|	) AS Calculations
	|WHERE
	|	Calculations.SumExpense > 0
	|;
	|
	|SELECT
	|	Calculations.Contract AS Contract,
	|	Calculations.Currency AS Currency,
	|	Calculations.AmountType AS AmountType,
	|	Calculations.SumReceipt - Calculations.BeingPaidReceipt + Calculations.BeingPaidExpense AS Sum
	|INTO DebitingFunds
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP.Turnovers(,,,
	|		Contract IN (&PaymentObjects)
	|	) AS Calculations
	|WHERE
	|	Calculations.SumReceipt - Calculations.BeingPaidReceipt + Calculations.BeingPaidExpense > 0
	|;
	|
	|SELECT // Tranches of the loan received
	|	Contracts.PaymentObject AS PaymentObject,
	|	VALUE(Enum.CashFlowTypes.Inpayment) AS ReceiptIssue,
	|	VALUE(Enum.LoanAndDepositScheduleAmountTypes.PrincipalDebt) AS AmountType,
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromLoansRepayment) AS BusinessOperation,
	|	Schedule.Period AS PaymentDate,
	|	CASE
	|		WHEN Schedule.AmountTotal - Schedule.Sum - ISNULL(ReceiptOfFunds.Sum, 0) < 0 THEN
	|			Schedule.AmountTotal - ISNULL(ReceiptOfFunds.Sum, 0)
	|		ELSE
	|			Schedule.Sum
	|	END AS Sum
	|	
	|FROM
	|	InformationRegister.ScheduleOfTrancheForLoansAndDeposits AS Schedule
	|		
	|		INNER JOIN Contracts
	|		ON Contracts.PaymentObject = Schedule.ScheduleOption.Owner
	|		
	|		LEFT JOIN ReceiptOfFunds
	|		ON ReceiptOfFunds.Contract = Contracts.PaymentObject
	|			AND ReceiptOfFunds.Currency = Contracts.Currency
	|			AND ReceiptOfFunds.AmountType = VALUE(Enum.LoanAndDepositScheduleAmountTypes.PrincipalDebt)
	|WHERE
	|	Contracts.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
	|	AND Schedule.ScheduleOption.Used
	|	AND NOT Schedule.ScheduleOption.DeletionMark
	|	AND Schedule.Sum > 0
	|	AND Schedule.AmountTotal - ISNULL(ReceiptOfFunds.Sum, 0) > 0
	|
	|UNION ALL
	|
	|SELECT // Tranches of the issued loan or deposit
	|	Contracts.PaymentObject AS PaymentObject,
	|	VALUE(Enum.CashFlowTypes.WriteOff) AS ReceiptIssue,
	|	VALUE(Enum.LoanAndDepositScheduleAmountTypes.PrincipalDebt) AS AmountType,
	|	CASE Contracts.ContractKind
	|		WHEN VALUE(Enum.ContractKindsOfFinancialInstruments.Deposit) THEN
	|			VALUE(Enum.BusinessTransactions.TransferToDeposits)
	|		WHEN VALUE(Enum.ContractKindsOfFinancialInstruments.IssuedBorrowing) THEN
	|			VALUE(Enum.BusinessTransactions.CashIssueAsLoanToCounterparty)
	|	END AS BusinessOperation,
	|	Schedule.Period AS PaymentDate,
	|	CASE
	|		WHEN Schedule.AmountTotal - Schedule.Sum - ISNULL(DebitingFunds.Sum, 0) < 0 THEN
	|			Schedule.AmountTotal - ISNULL(DebitingFunds.Sum, 0)
	|		ELSE
	|			Schedule.Sum
	|	END AS Sum
	|	
	|FROM
	|	InformationRegister.ScheduleOfTrancheForLoansAndDeposits AS Schedule
	|		
	|		INNER JOIN Contracts
	|		ON Contracts.PaymentObject = Schedule.ScheduleOption.Owner
	|		
	|		LEFT JOIN DebitingFunds
	|		ON DebitingFunds.Contract = Contracts.PaymentObject
	|			AND DebitingFunds.Currency = Contracts.Currency
	|			AND DebitingFunds.AmountType = VALUE(Enum.LoanAndDepositScheduleAmountTypes.PrincipalDebt)
	|WHERE
	|	Contracts.ContractKind IN (
	|		VALUE(Enum.ContractKindsOfFinancialInstruments.Deposit),
	|		VALUE(Enum.ContractKindsOfFinancialInstruments.IssuedBorrowing))
	|	AND Schedule.ScheduleOption.Used
	|	AND NOT Schedule.ScheduleOption.DeletionMark
	|	AND Schedule.Sum > 0
	|	AND Schedule.AmountTotal - ISNULL(DebitingFunds.Sum, 0) > 0
	|
	|UNION ALL
	|
	|SELECT // Payment of the received loan
	|	Contracts.PaymentObject AS PaymentObject,
	|	VALUE(Enum.CashFlowTypes.WriteOff) AS ReceiptIssue,
	|	VALUE(Enum.LoanAndDepositScheduleAmountTypes.PrincipalDebt) AS AmountType,
	|	VALUE(Enum.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived) AS BusinessOperation,
	|	Schedule.Period AS PaymentDate,
	|	CASE
	|		WHEN Schedule.AmountTotal - Schedule.Sum - ISNULL(DebitingFunds.Sum, 0) < 0 THEN
	|			Schedule.AmountTotal - ISNULL(DebitingFunds.Sum, 0)
	|		ELSE
	|			Schedule.Sum
	|	END AS Sum
	|
	|FROM
	|	InformationRegister.ScheduleOfPaymentForLoansAndDeposits AS Schedule
	|		
	|		INNER JOIN Contracts
	|		ON Contracts.PaymentObject = Schedule.ScheduleOption.Owner
	|		
	|		LEFT JOIN DebitingFunds
	|		ON DebitingFunds.Contract = Contracts.PaymentObject
	|			AND DebitingFunds.Currency = Contracts.Currency
	|			AND DebitingFunds.AmountType = VALUE(Enum.LoanAndDepositScheduleAmountTypes.PrincipalDebt)
	|	
	|WHERE
	|	Contracts.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
	|	AND Schedule.ScheduleOption.Used
	|	AND NOT Schedule.ScheduleOption.DeletionMark
	|	AND Schedule.Sum > 0
	|	AND Schedule.AmountTotal - ISNULL(DebitingFunds.Sum, 0) > 0
	|
	|UNION ALL
	|
	|SELECT // Payment of interest on the loan received
	|	Contracts.PaymentObject AS PaymentObject,
	|	VALUE(Enum.CashFlowTypes.WriteOff) AS ReceiptIssue,
	|	VALUE(Enum.LoanAndDepositScheduleAmountTypes.Interests) AS AmountType,
	|	VALUE(Enum.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived) AS BusinessOperation,
	|	Schedule.Period AS PaymentDate,
	|	CASE
	|		WHEN Schedule.InterestTotal - Schedule.Interests - ISNULL(DebitingFunds.Sum, 0) < 0 THEN
	|			Schedule.InterestTotal - ISNULL(DebitingFunds.Sum, 0)
	|		ELSE
	|			Schedule.Interests
	|	END AS Sum
	|
	|FROM
	|	InformationRegister.ScheduleOfPaymentForLoansAndDeposits AS Schedule
	|		
	|		INNER JOIN Contracts
	|		ON Contracts.PaymentObject = Schedule.ScheduleOption.Owner
	|		
	|		LEFT JOIN DebitingFunds
	|		ON DebitingFunds.Contract = Contracts.PaymentObject
	|			AND DebitingFunds.Currency = Contracts.Currency
	|			AND DebitingFunds.AmountType = VALUE(Enum.LoanAndDepositScheduleAmountTypes.Interests)
	|	
	|WHERE
	|	Contracts.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
	|	AND Schedule.ScheduleOption.Used
	|	AND NOT Schedule.ScheduleOption.DeletionMark
	|	AND Schedule.Interests > 0
	|	AND Schedule.InterestTotal - ISNULL(DebitingFunds.Sum, 0) > 0
	|
	|UNION ALL
	|
	|SELECT // Payment of the commission of the received loan
	|	Contracts.PaymentObject AS PaymentObject,
	|	VALUE(Enum.CashFlowTypes.WriteOff) AS ReceiptIssue,
	|	VALUE(Enum.LoanAndDepositScheduleAmountTypes.Fee) AS AmountType,
	|	VALUE(Enum.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived) AS BusinessOperation,
	|	Schedule.Period AS PaymentDate,
	|	CASE
	|		WHEN Schedule.FeeTotal - Schedule.Fee - ISNULL(DebitingFunds.Sum, 0) < 0 THEN
	|			Schedule.FeeTotal - ISNULL(DebitingFunds.Sum, 0)
	|		ELSE
	|			Schedule.Fee
	|	END AS Sum
	|
	|FROM
	|	InformationRegister.ScheduleOfPaymentForLoansAndDeposits AS Schedule
	|		
	|		INNER JOIN Contracts
	|		ON Contracts.PaymentObject = Schedule.ScheduleOption.Owner
	|		
	|		LEFT JOIN DebitingFunds
	|		ON DebitingFunds.Contract = Contracts.PaymentObject
	|			AND DebitingFunds.Currency = Contracts.Currency
	|			AND DebitingFunds.AmountType = VALUE(Enum.LoanAndDepositScheduleAmountTypes.Fee)
	|	
	|WHERE
	|	Contracts.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
	|	AND Schedule.ScheduleOption.Used
	|	AND NOT Schedule.ScheduleOption.DeletionMark
	|	AND Schedule.Fee > 0
	|	AND Schedule.FeeTotal - ISNULL(DebitingFunds.Sum, 0) > 0
	|
	|UNION ALL
	|
	|SELECT // Payment of the issued loan, deposit
	|	Contracts.PaymentObject AS PaymentObject,
	|	VALUE(Enum.CashFlowTypes.Inpayment) AS ReceiptIssue,
	|	VALUE(Enum.LoanAndDepositScheduleAmountTypes.PrincipalDebt) AS AmountType,
	|	CASE Contracts.ContractKind
	|		WHEN VALUE(Enum.ContractKindsOfFinancialInstruments.Deposit) THEN
	|			VALUE(Enum.BusinessTransactions.CashReceiptUnderDeposits)
	|		WHEN VALUE(Enum.ContractKindsOfFinancialInstruments.IssuedBorrowing) THEN
	|			VALUE(Enum.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty)
	|	END AS BusinessOperation,
	|	Schedule.Period AS PaymentDate,
	|	CASE
	|		WHEN Schedule.AmountTotal - Schedule.Sum - ISNULL(ReceiptOfFunds.Sum, 0) < 0 THEN
	|			Schedule.AmountTotal - ISNULL(ReceiptOfFunds.Sum, 0)
	|		ELSE
	|			Schedule.Sum
	|	END AS Sum
	|
	|FROM
	|	InformationRegister.ScheduleOfPaymentForLoansAndDeposits AS Schedule
	|		
	|		INNER JOIN Contracts
	|		ON Contracts.PaymentObject = Schedule.ScheduleOption.Owner
	|		
	|		LEFT JOIN ReceiptOfFunds
	|		ON ReceiptOfFunds.Contract = Contracts.PaymentObject
	|			AND ReceiptOfFunds.Currency = Contracts.Currency
	|			AND ReceiptOfFunds.AmountType = VALUE(Enum.LoanAndDepositScheduleAmountTypes.PrincipalDebt)
	|	
	|WHERE
	|	Contracts.ContractKind IN (
	|		VALUE(Enum.ContractKindsOfFinancialInstruments.Deposit),
	|		VALUE(Enum.ContractKindsOfFinancialInstruments.IssuedBorrowing))
	|	AND Schedule.ScheduleOption.Used
	|	AND NOT Schedule.ScheduleOption.DeletionMark
	|	AND Schedule.Sum > 0
	|	AND Schedule.AmountTotal - ISNULL(ReceiptOfFunds.Sum, 0) > 0
	|
	|UNION ALL
	|
	|SELECT // Payment of interest on the issued loan, deposit
	|	Contracts.PaymentObject AS PaymentObject,
	|	VALUE(Enum.CashFlowTypes.Inpayment) AS ReceiptIssue,
	|	VALUE(Enum.LoanAndDepositScheduleAmountTypes.Interests) AS AmountType,
	|	CASE Contracts.ContractKind
	|		WHEN VALUE(Enum.ContractKindsOfFinancialInstruments.Deposit) THEN
	|			VALUE(Enum.BusinessTransactions.CashReceiptUnderDeposits)
	|		WHEN VALUE(Enum.ContractKindsOfFinancialInstruments.IssuedBorrowing) THEN
	|			VALUE(Enum.BusinessTransactions.ReceiptOfInterestOfIssuedBorrowings)
	|	END AS BusinessOperation,
	|	Schedule.Period AS PaymentDate,
	|	CASE
	|		WHEN Schedule.InterestTotal - Schedule.Interests - ISNULL(ReceiptOfFunds.Sum, 0) < 0 THEN
	|			Schedule.InterestTotal - ISNULL(ReceiptOfFunds.Sum, 0)
	|		ELSE
	|			Schedule.Interests
	|	END AS Sum
	|
	|FROM
	|	InformationRegister.ScheduleOfPaymentForLoansAndDeposits AS Schedule
	|		
	|		INNER JOIN Contracts
	|		ON Contracts.PaymentObject = Schedule.ScheduleOption.Owner
	|		
	|		LEFT JOIN ReceiptOfFunds
	|		ON ReceiptOfFunds.Contract = Contracts.PaymentObject
	|			AND ReceiptOfFunds.Currency = Contracts.Currency
	|			AND ReceiptOfFunds.AmountType = VALUE(Enum.LoanAndDepositScheduleAmountTypes.Interests)
	|	
	|WHERE
	|	Contracts.ContractKind IN (
	|		VALUE(Enum.ContractKindsOfFinancialInstruments.Deposit),
	|		VALUE(Enum.ContractKindsOfFinancialInstruments.IssuedBorrowing))
	|	AND Schedule.ScheduleOption.Used
	|	AND NOT Schedule.ScheduleOption.DeletionMark
	|	AND Schedule.Interests > 0
	|	AND Schedule.InterestTotal - ISNULL(ReceiptOfFunds.Sum, 0) > 0
	|
	|UNION ALL
	|
	|SELECT // Payment of the commission of the issued loan, deposit
	|	Contracts.PaymentObject AS PaymentObject,
	|	VALUE(Enum.CashFlowTypes.Inpayment) AS ReceiptIssue,
	|	VALUE(Enum.LoanAndDepositScheduleAmountTypes.Fee) AS AmountType,
	|	CASE Contracts.ContractKind
	|		WHEN VALUE(Enum.ContractKindsOfFinancialInstruments.Deposit) THEN
	|			VALUE(Enum.BusinessTransactions.CashReceiptUnderDeposits)
	|		WHEN VALUE(Enum.ContractKindsOfFinancialInstruments.IssuedBorrowing) THEN
	|			VALUE(Enum.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty)
	|	END AS BusinessOperation,
	|	Schedule.Period AS PaymentDate,
	|	CASE
	|		WHEN Schedule.FeeTotal - Schedule.Fee - ISNULL(ReceiptOfFunds.Sum, 0) < 0 THEN
	|			Schedule.FeeTotal - ISNULL(ReceiptOfFunds.Sum, 0)
	|		ELSE
	|			Schedule.Fee
	|	END AS Sum
	|
	|FROM
	|	InformationRegister.ScheduleOfPaymentForLoansAndDeposits AS Schedule
	|		
	|		INNER JOIN Contracts
	|		ON Contracts.PaymentObject = Schedule.ScheduleOption.Owner
	|		
	|		LEFT JOIN ReceiptOfFunds
	|		ON ReceiptOfFunds.Contract = Contracts.PaymentObject
	|			AND ReceiptOfFunds.Currency = Contracts.Currency
	|			AND ReceiptOfFunds.AmountType = VALUE(Enum.LoanAndDepositScheduleAmountTypes.Fee)
	|	
	|WHERE
	|	Contracts.ContractKind IN (
	|		VALUE(Enum.ContractKindsOfFinancialInstruments.Deposit),
	|		VALUE(Enum.ContractKindsOfFinancialInstruments.IssuedBorrowing))
	|	AND Schedule.ScheduleOption.Used
	|	AND NOT Schedule.ScheduleOption.DeletionMark
	|	AND Schedule.Fee > 0
	|	AND Schedule.FeeTotal - ISNULL(ReceiptOfFunds.Sum, 0) > 0
	|;
	|
	|SELECT
	|	*
	|FROM
	|	Contracts
	|";
	
	Return QueryText;
	
EndFunction

Function RequestTextScheduleOfPaymentsUnderLeaseAgreements()
	
	QueryText = "
	|SELECT
	|	CatalogData.Ref                            AS PaymentObject,
	|	CatalogData.ARAPCurrency              AS Currency,
	|	CatalogData.BankAccount                    AS BankAccount,
	|	CatalogData.Counterparty                        AS PayerBeneficiary,
	|	CatalogData.Organization                       AS Organization,
	|	CatalogData.CashFlowItem     AS CashFlowItem,
	|	CatalogData.Department                     AS Department,
	|	CatalogData.LineOfBusiness           AS LineOfBusiness,
	|	CatalogData.EmployeeResponsible                     AS EmployeeResponsible,
	|	CatalogData.Number                             AS Number,
	|	CatalogData.Date                              AS Date,
	|	CatalogData.Status                            AS Status,
	|	VALUE(Enum.PaymentForms.BankAccountPayment)      AS PaymentMethod,
	|	VALUE(Enum.PaymentPlanningAreas.Lease) AS PlanningArea
	|INTO Contracts
	|FROM
	|	Catalog.LeaseContract AS CatalogData
	|WHERE
	|	CatalogData.Ref IN (&PaymentObjects)
	|INDEX BY
	|	PaymentObject
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT 1
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Calculations.Contract AS Contract,
	|	Calculations.Currency AS Currency,
	|	CASE
	|		WHEN Calculations.AmountType = VALUE(Enum.TypesOfLeasePayments.RentalServicePrepayment)
	|			THEN VALUE(Enum.TypesOfLeasePayments.RentalService)
	|		ELSE
	|			Calculations.AmountType
	|	END AS AmountType,
	|	SUM(Calculations.SumReceipt - Calculations.BeingPaidReceipt + Calculations.BeingPaidExpense) AS Sum
	|INTO DebitingFunds
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP.Turnovers(,,,
	|		Contract IN (&PaymentObjects)
	|	) AS Calculations
	|GROUP BY
	|	Calculations.Contract,
	|	Calculations.Currency,
	|	CASE
	|		WHEN Calculations.AmountType = VALUE(Enum.TypesOfLeasePayments.RentalServicePrepayment)
	|			THEN VALUE(Enum.TypesOfLeasePayments.RentalService)
	|		ELSE
	|			Calculations.AmountType
	|	END
	|
	|HAVING
	|	SUM(Calculations.SumReceipt - Calculations.BeingPaidReceipt + Calculations.BeingPaidExpense) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TermsOfLeaseContracts.EffectiveContractTerms AS EffectiveContractTerms,
	|	TermsOfLeaseContracts.Contract AS Contract
	|INTO TTTermsOfLeaseAgreements
	|FROM
	|	InformationRegister.TermsOfLeaseContracts.SliceLast(, Contract IN (SELECT Contracts.PaymentObject FROM Contracts)) AS TermsOfLeaseContracts
	|
	|WHERE
	|	NOT State = VALUE(Enum.CounterpartyContractStates.Closed)
	|
	|INDEX BY
	|	EffectiveContractTerms,
	|	Contract
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT // Payment for rental services
	|	Contracts.PaymentObject AS PaymentObject,
	|	VALUE(Enum.CashFlowTypes.WriteOff) AS ReceiptIssue,
	|	VALUE(Enum.TypesOfLeasePayments.RentalService) AS AmountType,
	|	VALUE(Enum.BusinessTransactions.PaymentToLessor) AS BusinessOperation,
	|	Schedule.Date AS PaymentDate,
	|	CASE
	|		WHEN Schedule.RentalServiceTotal - Schedule.RentalService - ISNULL(DebitingFunds.Sum, 0) < 0 THEN
	|			Schedule.RentalServiceTotal - ISNULL(DebitingFunds.Sum, 0)
	|		ELSE
	|			Schedule.RentalService
	|	END AS Sum
	|
	|FROM
	|	InformationRegister.LeaseServicesPaymentSchedule AS Schedule
	|		
	|		INNER JOIN Contracts
	|		ON Contracts.PaymentObject = Schedule.Contract
	|		
	|		LEFT JOIN DebitingFunds
	|		ON DebitingFunds.Contract = Contracts.PaymentObject
	|			AND DebitingFunds.Currency = Contracts.Currency
	|			AND DebitingFunds.AmountType = VALUE(Enum.TypesOfLeasePayments.RentalService)
	|		LEFT JOIN Document.OBEntryOfLeaseSettlements AS OBEntryOfLeaseSettlements
	|		ON Schedule.Recorder = OBEntryOfLeaseSettlements.Ref
	|	
	|WHERE
	|	Schedule.RentalService > 0
	|	AND Schedule.RentalServiceTotal - ISNULL(DebitingFunds.Sum, 0) > 0
	|	AND ((Schedule.EffectiveContractTerms, Schedule.Contract) IN 
	|			(SELECT 
	|				T.EffectiveContractTerms, 
	|				T.Contract 
	|			FROM 
	|				TTTermsOfLeaseAgreements AS T)
	|
	|		OR Schedule.EffectiveContractTerms IN (&AddnlParameter_)
	|			AND NOT TRUE IN (SELECT TRUE FROM TTTermsOfLeaseAgreements AS T))
	|	AND Schedule.Date >= ISNULL(OBEntryOfLeaseSettlements.Date, DATETIME(1,1,1))
	|
	|UNION ALL
	|
	|SELECT // Security payment
	|	Contracts.PaymentObject AS PaymentObject,
	|	VALUE(Enum.CashFlowTypes.WriteOff) AS ReceiptIssue,
	|	VALUE(Enum.TypesOfLeasePayments.DepositPayment) AS AmountType,
	|	VALUE(Enum.BusinessTransactions.PaymentToLessor) AS BusinessOperation,
	|	Schedule.Date AS PaymentDate,
	|	CASE
	|		WHEN Schedule.SecurityPaymentAmountTotal - Schedule.DepositPayment - ISNULL(DebitingFunds.Sum, 0) < 0 THEN
	|			Schedule.SecurityPaymentAmountTotal - ISNULL(DebitingFunds.Sum, 0)
	|		ELSE
	|			Schedule.DepositPayment
	|	END AS Sum
	|
	|FROM
	|	InformationRegister.LeaseServicesPaymentSchedule AS Schedule
	|		
	|		INNER JOIN Contracts
	|		ON Contracts.PaymentObject = Schedule.Contract
	|		
	|		LEFT JOIN DebitingFunds
	|		ON DebitingFunds.Contract = Contracts.PaymentObject
	|			AND DebitingFunds.Currency = Contracts.Currency
	|			AND DebitingFunds.AmountType = VALUE(Enum.TypesOfLeasePayments.DepositPayment)
	|		LEFT JOIN Document.OBEntryOfLeaseSettlements AS OBEntryOfLeaseSettlements
	|		ON Schedule.Recorder = OBEntryOfLeaseSettlements.Ref
	|	
	|WHERE
	|	Schedule.DepositPayment > 0
	|	AND Schedule.SecurityPaymentAmountTotal - ISNULL(DebitingFunds.Sum, 0) > 0
	|	AND ((Schedule.EffectiveContractTerms, Schedule.Contract) IN 
	|			(SELECT 
	|				T.EffectiveContractTerms, 
	|				T.Contract 
	|			FROM 
	|				TTTermsOfLeaseAgreements AS T)
	|
	|		OR Schedule.EffectiveContractTerms IN (&AddnlParameter_)
	|			AND NOT TRUE IN (SELECT TRUE FROM TTTermsOfLeaseAgreements AS T))
	|	AND Schedule.Date >= ISNULL(OBEntryOfLeaseSettlements.Date, DATETIME(1,1,1))
	|
	|UNION ALL
	|
	|SELECT // Purchase of rental items
	|	Contracts.PaymentObject AS PaymentObject,
	|	VALUE(Enum.CashFlowTypes.WriteOff) AS ReceiptIssue,
	|	VALUE(Enum.TypesOfLeasePayments.BuyoutValue) AS AmountType,
	|	VALUE(Enum.BusinessTransactions.PaymentToLessor) AS BusinessOperation,
	|	Schedule.Date AS PaymentDate,
	|	CASE
	|		WHEN Schedule.BuyoutValueTotal - Schedule.BuyoutValue - ISNULL(DebitingFunds.Sum, 0) < 0 THEN
	|			Schedule.BuyoutValueTotal - ISNULL(DebitingFunds.Sum, 0)
	|		ELSE
	|			Schedule.BuyoutValue
	|	END AS Sum
	|
	|FROM
	|	InformationRegister.LeaseServicesPaymentSchedule AS Schedule
	|		
	|		INNER JOIN Contracts
	|		ON Contracts.PaymentObject = Schedule.Contract
	|		
	|		LEFT JOIN DebitingFunds
	|		ON DebitingFunds.Contract = Contracts.PaymentObject
	|			AND DebitingFunds.Currency = Contracts.Currency
	|			AND DebitingFunds.AmountType = VALUE(Enum.TypesOfLeasePayments.BuyoutValue)
	|		LEFT JOIN Document.OBEntryOfLeaseSettlements AS OBEntryOfLeaseSettlements
	|		ON Schedule.Recorder = OBEntryOfLeaseSettlements.Ref
	|	
	|WHERE
	|	Schedule.BuyoutValue > 0
	|	AND Schedule.BuyoutValueTotal - ISNULL(DebitingFunds.Sum, 0) > 0
	|	AND ((Schedule.EffectiveContractTerms, Schedule.Contract) IN 
	|			(SELECT 
	|				T.EffectiveContractTerms, 
	|				T.Contract 
	|			FROM 
	|				TTTermsOfLeaseAgreements AS T)
	|
	|		OR Schedule.EffectiveContractTerms IN (&AddnlParameter_)
	|			AND NOT TRUE IN (SELECT TRUE FROM TTTermsOfLeaseAgreements AS T))
	|	AND Schedule.Date >= ISNULL(OBEntryOfLeaseSettlements.Date, DATETIME(1,1,1))
	|
	|UNION ALL
	|
	|SELECT // Advance payment of rental items
	|	Contracts.PaymentObject AS PaymentObject,
	|	VALUE(Enum.CashFlowTypes.WriteOff) AS ReceiptIssue,
	|	VALUE(Enum.TypesOfLeasePayments.BuyoutValuePrepayment) AS AmountType,
	|	VALUE(Enum.BusinessTransactions.PaymentToLessor) AS BusinessOperation,
	|	Schedule.Date AS PaymentDate,
	|	CASE
	|		WHEN Schedule.BuyoutValuePrepaymentTotal - Schedule.BuyoutValuePrepayment - ISNULL(DebitingFunds.Sum, 0) < 0 THEN
	|			Schedule.BuyoutValuePrepaymentTotal - ISNULL(DebitingFunds.Sum, 0)
	|		ELSE
	|			Schedule.BuyoutValuePrepayment
	|	END AS Sum
	|
	|FROM
	|	InformationRegister.LeaseServicesPaymentSchedule AS Schedule
	|		
	|		INNER JOIN Contracts
	|		ON Contracts.PaymentObject = Schedule.Contract
	|		
	|		LEFT JOIN DebitingFunds
	|		ON DebitingFunds.Contract = Contracts.PaymentObject
	|			AND DebitingFunds.Currency = Contracts.Currency
	|			AND DebitingFunds.AmountType = VALUE(Enum.TypesOfLeasePayments.BuyoutValuePrepayment)
	|		LEFT JOIN Document.OBEntryOfLeaseSettlements AS OBEntryOfLeaseSettlements
	|		ON Schedule.Recorder = OBEntryOfLeaseSettlements.Ref
	|	
	|WHERE
	|	Schedule.BuyoutValuePrepayment > 0
	|	AND Schedule.BuyoutValuePrepaymentTotal - ISNULL(DebitingFunds.Sum, 0) > 0
	|	AND ((Schedule.EffectiveContractTerms, Schedule.Contract) IN 
	|			(SELECT 
	|				T.EffectiveContractTerms, 
	|				T.Contract 
	|			FROM 
	|				TTTermsOfLeaseAgreements AS T)
	|
	|		OR Schedule.EffectiveContractTerms IN (&AddnlParameter_)
	|			AND NOT TRUE IN (SELECT TRUE FROM TTTermsOfLeaseAgreements AS T))
	|	AND Schedule.Date >= ISNULL(OBEntryOfLeaseSettlements.Date, DATETIME(1,1,1))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	*
	|FROM
	|	Contracts
	|";
	
	Return QueryText;
	
EndFunction
Function InitializeGraphFields()
	
	GraphFields = New Structure("Ref, BankAccount, CompanyBankAccount, CashAccount, CashFlowItem, LineOfBusiness,
		|BusinessOperation, Department, Priority, Manager, Number, Date, DocumentAmount, PaymentMethod,
		|CashFlowContract, CashFlowAgreement");
		
	GraphFields.Insert("Sum", "DocumentAmount");
	GraphFields.Insert("CompanyRecipient");
	GraphFields.Insert("RecipientCompanyBankAccount");
	GraphFields.Insert("Consignee");
	GraphFields.Insert("CashAccountRecipient");
	GraphFields.Insert("Status");
	
	Return GraphFields;
	
EndFunction

Function UnprocessedDocuments_()
	
	NotProcessed = New Array;
	NotProcessed.Add(Type("DocumentRef.BankAccountReceiptNote"));
	NotProcessed.Add(Type("DocumentRef.CashAccountReceiptNote"));
	NotProcessed.Add(Type("DocumentRef.CashVoucher"));
	NotProcessed.Add(Type("DocumentRef.BankAccountIssue"));
	NotProcessed.Add(Type("DocumentRef.PaymentCardTransaction"));
	
	Return NotProcessed;
	
EndFunction

Procedure FillInOriginalAttributes(Record)

	Record.OriginalBankAccountCashAccount = Record.BankAccountCashAccount;
	Record.PaymentDateOriginal = Record.PaymentDate;
	Record.InitialAmount_ = Record.Sum;

EndProcedure

Function CurrencyExchangeRate(ExchangeRates, Currency)

	CourseParameters = New Structure();
	CurrencyExchangeRate = ExchangeRates.Find(Currency, "Currency");
	CourseParameters.Insert("Currency", Currency);
	CourseParameters.Insert("CourseNumerator", CurrencyExchangeRate.CourseNumerator);
	CourseParameters.Insert("CourseDenominator", CurrencyExchangeRate.CourseDenominator);
	
	Return CourseParameters;

EndFunction

Procedure ProlongationOfRegularPayments(Contracts)
	
	Query = New Query;
	Query.Text = "SELECT
	|	RegularPaymentContracts.ContractSchedule AS ContractSchedule
	|FROM
	|	Catalog.CounterpartyContracts AS RegularPaymentContracts
	|WHERE
	|	RegularPaymentContracts.OptionOfDeterminingExecutionScheduleInContract
	|		= VALUE(Enum.OptionsForDeterminingExecutionScheduleInContract.RegularPayments)
	|	AND RegularPaymentContracts.ValidityEndDate = DATETIME(1, 1, 1)
	|	AND RegularPaymentContracts.Ref IN (&Contracts)
	|	AND RegularPaymentContracts.ContractSchedule <> VALUE(Document.ContractSchedule.EmptyRef)";
	
	Query.SetParameter("Contracts", Contracts);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		Documents.ContractSchedule.CreateFillInRegularPayments(Selection.ContractSchedule);
	EndDo;
	
EndProcedure

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export

	FullRegisterName = Metadata.InformationRegisters.ScheduleOfPayments.FullName();

	Handler = Handlers.Add();
	Handler.Procedure = "InformationRegisters.ScheduleOfPayments.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.27.27";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("aa598031-f852-41a7-a198-0adab2cdc360");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure =
		"InformationRegisters.ScheduleOfPayments.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Обновление ""%1"":';
			|vi = 'Update ""%1"":';
			|en = 'Update ""%1"":'; fa = 'Update ""%1"":';
			|it = 'Update ""%1"":';
			|pl = 'Update ""%1"":';
			|tr = 'Güncelleme ""%1"":'"), FullRegisterName));
	ListOfDescriptions.Add(StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = '- заполнение реквизитов ""%1"", ""%2"", ""%3"", ""%4"", ""%5"".';
			|vi = '- Fill in the ""%1"", ""%2"", ""%3"", ""%4"", and ""%5"" attributes.';
			|en = '- Fill in the ""%1"", ""%2"", ""%3"", ""%4"", and ""%5"" attributes.'; fa = '- Fill in the ""%1"", ""%2"", ""%3"", ""%4"", and ""%5"" attributes.';
			|it = '- Fill in the ""%1"", ""%2"", ""%3"", ""%4"", and ""%5"" attributes.';
			|pl = '- Fill in the ""%1"", ""%2"", ""%3"", ""%4"", and ""%5"" attributes.';
			|tr = '- ""%1"", ""%2"", ""%3"", ""%4"", ""%5"" özniteliklerinin doldurulması.'"),
		Metadata.InformationRegisters.ScheduleOfPayments.Attributes.Id.Name,
		Metadata.InformationRegisters.ScheduleOfPayments.Attributes.Status.Name,
		Metadata.InformationRegisters.ScheduleOfPayments.Attributes.OriginalBankAccountCashAccount.Name,
		Metadata.InformationRegisters.ScheduleOfPayments.Attributes.PaymentDateOriginal.Name,
		Metadata.InformationRegisters.ScheduleOfPayments.Attributes.InitialAmount_.Name));
	
	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	
	ItemsToRead = New Array;
	ItemsToRead.Add(FullRegisterName);
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(FullRegisterName);
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export

	IsEmptySet = CreateRecordSet();
	FullRegisterName = IsEmptySet.Metadata().FullName();
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullRegistersNames = FullRegisterName;
	SelectionParameters.SelectionMethod = InfobaseUpdate.SelectionMethodOfIndependentInfoRegistryMeasurements();
	
	AdditionalParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
	AdditionalParameters.Insert("IsIndependentInformationRegister", True);
	AdditionalParameters.Insert("FullRegisterName", FullRegisterName);
	
	Query = New Query;
	Query.Text = "
	|SELECT DISTINCT
	|	ScheduleOfPayments.PaymentObject
	|FROM
	|	InformationRegister.ScheduleOfPayments AS ScheduleOfPayments
	|WHERE
	|	ScheduleOfPayments.Id = """"
	|";
	
	RegisteredPaymentObjects = Query.Execute();
	InfobaseUpdate.MarkForProcessing(Parameters, RegisteredPaymentObjects, AdditionalParameters);
	
EndProcedure

// The update handler
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters 
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export

	RegisterMetadata = CreateRecordSet().Metadata();
	
	FullObjectName = RegisterMetadata.FullName();
	If Not InfobaseUpdate.HasDataToProcess(Parameters.Queue, FullObjectName) Then
		Parameters.ProcessingCompleted = True;
		Return;
	EndIf;
	
	PortionOfPaymentObjects = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If PortionOfPaymentObjects.Count() = 0 Then
		Parameters.ProcessingCompleted = False;
		Return;
	EndIf;
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Не удалось обработать задания по обработчику регистра сведений  ""%1"".';
			|vi = 'Cannot process the jobs of the ""%1"" information register handler.';
			|en = 'Cannot process the jobs of the ""%1"" information register handler.'; fa = 'Cannot process the jobs of the ""%1"" information register handler.';
			|it = 'Cannot process the jobs of the ""%1"" information register handler.';
			|pl = 'Cannot process the jobs of the ""%1"" information register handler.';
			|tr = '""%1"" bilgi kayıt işleyicisi kapsamında görevler işlenemedi.'"), FullObjectName));
		
	Query = New Query;
	Query.SetParameter("PortionOfPaymentObjects", PortionOfPaymentObjects);
	Query.Text = "
	|SELECT
	|	PortionOfPaymentObjects.PaymentObject
	|
	|INTO TableOfPaymentObjects
	|
	|FROM
	|	&PortionOfPaymentObjects AS PortionOfPaymentObjects
	|;
	|
	|SELECT
	|	TableOfPaymentObjects.PaymentObject,
	|	CASE
	|		WHEN VALUETYPE(TableOfPaymentObjects.PaymentObject) = TYPE(Catalog.Complaints)
	|		THEN CAST(TableOfPaymentObjects.PaymentObject AS Catalog.Complaints).Status
	|		WHEN VALUETYPE(TableOfPaymentObjects.PaymentObject) = TYPE(Document.RequestForReturnOfGoodsFromCustomer)
	|		THEN CAST(TableOfPaymentObjects.PaymentObject AS Document.RequestForReturnOfGoodsFromCustomer).Status
	|		WHEN VALUETYPE(TableOfPaymentObjects.PaymentObject) = TYPE(Document.PaymentRequest)
	|		THEN CAST(TableOfPaymentObjects.PaymentObject AS Document.PaymentRequest).Status
	|		WHEN VALUETYPE(TableOfPaymentObjects.PaymentObject) = TYPE(Document.CCDImport)
	|		THEN CAST(TableOfPaymentObjects.PaymentObject AS Document.CCDImport).Status
	|		WHEN VALUETYPE(TableOfPaymentObjects.PaymentObject) = TYPE(Document.MaterialProviderOrder2_5)
	|		THEN CAST(TableOfPaymentObjects.PaymentObject AS Document.MaterialProviderOrder2_5).Status
	|		WHEN VALUETYPE(TableOfPaymentObjects.PaymentObject) = TYPE(Document.SalesOrder)
	|		THEN CAST(TableOfPaymentObjects.PaymentObject AS Document.SalesOrder).Status
	|		WHEN VALUETYPE(TableOfPaymentObjects.PaymentObject) = TYPE(Catalog.LeaseContract)
	|		THEN CAST(TableOfPaymentObjects.PaymentObject AS Catalog.LeaseContract).Status
	|		WHEN VALUETYPE(TableOfPaymentObjects.PaymentObject) = TYPE(Catalog.CounterpartyContracts)
	|		THEN CAST(TableOfPaymentObjects.PaymentObject AS Catalog.CounterpartyContracts).Status
	|		WHEN VALUETYPE(TableOfPaymentObjects.PaymentObject) = TYPE(Catalog.LoanAndDepositContracts)
	|		THEN CAST(TableOfPaymentObjects.PaymentObject AS Catalog.LoanAndDepositContracts).Status
	|		WHEN VALUETYPE(TableOfPaymentObjects.PaymentObject) = TYPE(Catalog.IntercompanyContracts)
	|		THEN CAST(TableOfPaymentObjects.PaymentObject AS Catalog.IntercompanyContracts).Status
	|		WHEN VALUETYPE(TableOfPaymentObjects.PaymentObject) = TYPE(Catalog.AcquiringContracts)
	|		THEN CAST(TableOfPaymentObjects.PaymentObject AS Catalog.AcquiringContracts).Status
	|		WHEN VALUETYPE(TableOfPaymentObjects.PaymentObject) = TYPE(Document.PurchaseOrder)
	|		THEN CAST(TableOfPaymentObjects.PaymentObject AS Document.PurchaseOrder).Status
	|		WHEN VALUETYPE(TableOfPaymentObjects.PaymentObject) = TYPE(Document.PurchaseOrder)
	|		THEN CAST(TableOfPaymentObjects.PaymentObject AS Document.PurchaseOrder).Status
	|		WHEN VALUETYPE(TableOfPaymentObjects.PaymentObject) = TYPE(Document.ApplicationForBusinessTrip)
	|		THEN CAST(TableOfPaymentObjects.PaymentObject AS Document.ApplicationForBusinessTrip).Status
	|		WHEN VALUETYPE(TableOfPaymentObjects.PaymentObject) = TYPE(Document.CustomerInvoice)
	|		THEN CAST(TableOfPaymentObjects.PaymentObject AS Document.CustomerInvoice).Status
	|		WHEN VALUETYPE(TableOfPaymentObjects.PaymentObject) = TYPE(Document.CustomerInvoiceServicesAndAssets)
	|		THEN CAST(TableOfPaymentObjects.PaymentObject AS Document.CustomerInvoiceServicesAndAssets).Status
	|		WHEN VALUETYPE(TableOfPaymentObjects.PaymentObject) = TYPE(Document.CustomerBonusCertificate)
	|		THEN CAST(TableOfPaymentObjects.PaymentObject AS Document.CustomerBonusCertificate).Status
	|		WHEN VALUETYPE(TableOfPaymentObjects.PaymentObject) = TYPE(Document.SubcontractOrder2_5)
	|		THEN CAST(TableOfPaymentObjects.PaymentObject AS Document.SubcontractOrder2_5).Status
	|	END AS Status
	|FROM
	|	TableOfPaymentObjects
	|";
	
	ObjectsProcessed = 0;
	ObjectsWithIssuesCount = 0;
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Не удалось обработать задания по обработчику ""%1"".';
			|vi = 'Cannot process the jobs by the ""%1"" handler.';
			|en = 'Cannot process the jobs by the ""%1"" handler.'; fa = 'Cannot process the jobs by the ""%1"" handler.';
			|it = 'Cannot process the jobs by the ""%1"" handler.';
			|pl = 'Cannot process the jobs by the ""%1"" handler.';
			|tr = '""%1"" işleyicisi bazında görevler işlenemedi.'"), FullObjectName));
		
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		ExceptionReason = "";
			
		BeginTransaction();
		Try
			RecordSet = CreateRecordSet();
			RecordSet.Filter.PaymentObject.Set(Selection.PaymentObject);
			
			ExceptionReason = "Block";
			
			Block = New DataLock;
			LockItem = Block.Add(FullObjectName);
			LockItem.SetValue("PaymentObject", Selection.PaymentObject);
			LockItem.Mode = DataLockMode.Exclusive;
			Block.Lock();
			
			ExceptionReason = "DataProcessor data_";

			RecordSet.Read();
			
			For Each Record In RecordSet Do
				
				If Not ValueIsFilled(Record.Status) Then
					Record.Status = Selection.Status;
				EndIf;
				
				If Not ValueIsFilled(Record.Id) Then
					Record.Id = New UUID();
					Record.OriginalBankAccountCashAccount = Record.BankAccountCashAccount;
				EndIf;
					
				If Not ValueIsFilled(Record.PaymentDateOriginal) Then
					Record.PaymentDateOriginal = Record.PaymentDate;
				EndIf;
					
				If Not ValueIsFilled(Record.InitialAmount_) Then
					Record.InitialAmount_ = Record.Sum;
				EndIf;
			EndDo;
			
			ExceptionReason = "Record";
			
			If RecordSet.Modified() Then
				InfobaseUpdate.WriteRecordSet(RecordSet);
			Else
				InfobaseUpdate.MarkProcessingCompletion(RecordSet);
			EndIf;
			
			ObjectsProcessed = ObjectsProcessed + 1;
			
			CommitTransaction();
		Except
			RollbackTransaction();
			
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			
			FilterAsString = String(RecordSet.Filter);
			
			MessageText = NStr("ru = 'Не удалось обработать набор записей %Set%
				|%Register% по причине: %Cause%';
				|vi = 'Cannot process the %Set%
				|%Register% record set due to: %Cause%';
				|en = 'Cannot process the %Set%
				|%Register% record set due to: %Cause%'; fa = 'Cannot process the %Set%
				|%Register% record set due to: %Cause%';
				|it = 'Cannot process the %Set%
				|%Register% record set due to: %Cause%';
				|pl = 'Cannot process the %Set%
				|%Register% record set due to: %Cause%';
				|tr = '%Register%
				|%Set% kayıt kümesi şu nedenle işlenemedi: %Cause%'");
			MessageText = StrReplace(MessageText, "%Register%", FullObjectName);
			MessageText = StrReplace(MessageText, "%Set%", FilterAsString);
			MessageText = StrReplace(MessageText, "%Cause%",
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
				
			WriteLogEvent(InfobaseUpdate.EventLogEvent(),
				EventLogLevel.Warning,
				RegisterMetadata,
				FilterAsString,
				MessageText);

			If ExceptionReason = "DataProcessor data_" Then

				InfobaseUpdate.MarkProcessingCompletion(RecordSet);

			ElsIf ExceptionReason = "Record" Then

				Raise StrConcat(ListOfDescriptions, Chars.LF);
			EndIf;
		EndTry;
	EndDo;
	
	If ObjectsProcessed = 0 And ObjectsWithIssuesCount <> 0 Then

		ListOfDescriptions.Add(NStr("ru = 'Всего пропущено: %1';
									|vi = 'Skipped: %1';
									|en = 'Skipped: %1'; fa = 'Skipped: %1';
									|it = 'Всего пропущено: %1';
									|pl = 'Skipped: %1';
									|tr = 'Toplam atlanan: %1'"));
		MessageText = StrTemplate(StrConcat(ListOfDescriptions, Chars.LF), ObjectsWithIssuesCount);
		
		Raise MessageText;
	EndIf;

	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue,
		FullObjectName);

EndProcedure

#EndRegion

#EndRegion

#EndIf