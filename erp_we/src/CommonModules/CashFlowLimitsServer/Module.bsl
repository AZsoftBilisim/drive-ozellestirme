
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
	
	// Posting
	If Properties.WriteMode = DocumentWriteMode.Posting Then
		
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.CashToBePaid);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.CashFlowLimits);
		
		If TypeOf(Document) = Type("DocumentObject.PaymentRequest")
			Or TypeOf(Document) = Type("DocumentObject.ApplicationForBusinessTrip") Then
			Parameters.ThereAreDerivedMotions = True;
		EndIf;
		
		ControlLimits =
			GetFunctionalOption("ControlExcessOfCashFlowLimits")
			And ((TypeOf(Document) = Type("DocumentObject.PaymentRequest")
				And Document.Status <> Enums.StatusesOfPaymentRequests.IsRejected
				And Not Document.OverLimits)
				Or
				(TypeOf(Document) = Type("DocumentObject.ApplicationForBusinessTrip")
				And (Document.Status <> Enums.EmployeeApplicationStatuses.IsRejected
					And Document.Status <> Enums.EmployeeApplicationStatuses.Withdrawn)
				And Document.FundsIssueToAdvanceHolder.Count()
				And Not Document.OverLimits));
		
		If ControlLimits Then
			Parameters.ControlRegistersOfChanges.Add(Metadata.AccumulationRegisters.CashFlowLimits);
		EndIf;
	EndIf;
	
	// Control
	If Properties.WriteMode <> DocumentWriteMode.Write Then
		
		If Not Properties.IsNew
			And (TypeOf(Document) = Type("DocumentObject.PaymentRequest")
				Or TypeOf(Document) = Type("DocumentObject.BankAccountReceiptNote")
					And GetFunctionalOption("UsePaymentRequests"))
		Or Properties.WriteMode = DocumentWriteMode.Posting
			And ((TypeOf(Document) = Type("DocumentObject.PaymentCardTransaction")
				Or TypeOf(Document) = Type("DocumentObject.CashTransferReferenceOrder")
				Or TypeOf(Document) = Type("DocumentObject.CashVoucher")
				Or TypeOf(Document) = Type("DocumentObject.BankAccountIssue"))
				And (GetFunctionalOption("UsePaymentRequests")
					Or GetFunctionalOption("UseApplicationsForBusinessTrip"))
			)
		Or DocumentCorrection.ThisIsCorrectiveDocument(Document)
		Then
			Parameters.ControlRegistersOfChanges.Add(Metadata.AccumulationRegisters.CashToBePaid);
		EndIf;
	EndIf;
	
	Return Parameters;
	
EndFunction

// Returns the text of the queries to reverse the movements when correcting documents
// 
// Parameters:
// 	MetadataOfDocument - MetadataObjectDocument - Metadata of the document that is being held.
// 
// Returns:
// 	Map - Correspondence of the full register name to the text of the reversal request
//
Function TextsOfCancellationRequests(MetadataOfDocument) Export
	
	DocumentRegisterRecords = MetadataOfDocument.RegisterRecords;

	QueriesTexts = New Map();
	
	RegisterMetadata = Metadata.AccumulationRegisters.CashToBePaid;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata, MetadataOfDocument));
	EndIf;
		
	RegisterMetadata = Metadata.AccumulationRegisters.CashFlowLimits;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata, MetadataOfDocument));
	EndIf;
			
	Return QueriesTexts;
	
EndFunction

// Procedure for forming movements in subordinate registers of planning and control of funds.
//
// Parameters:
//	TablesForRegisteredRecords - Structure - document data tables
//	RegisterRecords - RegisterRecordsCollection - collection of document movement record sets
//	Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "CashToBePaid");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "CashFlowLimits");
	
EndProcedure

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

// Forms the text of the requests for control changes, the recorded movements of the registers.
//
// Parameters:
//  Query - Query - a query that stores the parameters used in the query list
//  QueryTexts - ValueList - list of query texts and their names.
//  Document - DocumentObject - a recordable document.
//
Procedure InitializeChangeControlData(Query, QueryTexts, Document) Export
	
	#Region CashToBePaid
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "CashFlowsPayableChange") Then
		
		PreliminaryRequest = New Query;
		PreliminaryRequest.TempTablesManager = Query.TempTablesManager;
		PreliminaryRequest.Text =
		"SELECT
		|	CashToBePaidTurnovers.PaymentRequest AS PaymentRequest,
		|	CashToBePaidTurnovers.BankAccountCashAccount AS BankAccountCashAccount,
		|	CashToBePaidTurnovers.Recipient AS Recipient,
		|	CashToBePaidTurnovers.Organization AS Organization,
		|	CashToBePaidTurnovers.SumReceipt AS AmountPlanned
		|INTO Scheduled
		|FROM
		|	AccumulationRegister.CashToBePaid.Turnovers(
		|			,
		|			,
		|			,
		|			(PaymentRequest, BankAccountCashAccount, Recipient, Organization) IN
		|				(SELECT
		|					Table.PaymentRequest,
		|					Table.BankAccountCashAccount,
		|					Table.Recipient,
		|					Table.Organization
		|				FROM
		|					CashFlowsPayableChange AS Table)) AS CashToBePaidTurnovers
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	BalanceTable.PaymentRequest AS PaymentRequest,
		|	BalanceTable.BankAccountCashAccount AS BankAccountCashAccount,
		|	BalanceTable.Recipient AS Recipient,
		|	BalanceTable.Organization AS Organization,
		|	BalanceTable.SumBalance AS Sum
		|INTO Negative_Balance
		|FROM
		|	AccumulationRegister.CashToBePaid.Balance(
		|			,
		|			(PaymentRequest, BankAccountCashAccount, Recipient, Organization) IN
		|				(SELECT
		|					Table.PaymentRequest,
		|					Table.BankAccountCashAccount,
		|					Table.Recipient,
		|					Table.Organization
		|				FROM
		|					CashFlowsPayableChange AS Table)) AS BalanceTable
		|WHERE
		|	BalanceTable.SumBalance < 0
		|";
		
		PreliminaryRequest.Execute();
		Query.TempTablesManager = PreliminaryRequest.TempTablesManager;
		
		QueryText =
		"SELECT
		|	Negative_Balance.PaymentRequest AS PaymentRequest,
		|	Negative_Balance.BankAccountCashAccount AS BankAccountCashAccount,
		|	Negative_Balance.Recipient AS Recipient,
		|	Negative_Balance.Organization AS Organization,
		|	Negative_Balance.Sum AS Sum,
		|	Request.Organization AS OrganizationOfApplication,
		|	CASE
		|		WHEN Request.BusinessOperation IN (
		|				VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder), 
		|				VALUE(Enum.BusinessTransactions.CashIssueAsLoanToEmployee))
		|			THEN Request.AdvanceHolder
		|		WHEN Request.BusinessOperation IN (
		|				VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany), 
		|				VALUE(Enum.BusinessTransactions.RefundToAnotherCompany), 
		|				VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices))
		|			THEN Request.CompanyRecipient
		|		ELSE Request.Counterparty
		|	END AS ApplicationRecipient,
		|	Request.Currency AS Currency,
		|	Request.BusinessOperation AS BusinessOperation,
		|	Request.PersonsList AS PersonsList,
		|	Request.ListOfCounterparties_ AS ListOfCounterparties_,
		|	CASE
		|		WHEN Scheduled.AmountPlanned IS NULL AND ISNULL(Request.DeletionMark, FALSE) = FALSE
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS ThereIsConsumptionOfAdditionalAttributes
		|FROM
		|	Negative_Balance AS Negative_Balance
		|		LEFT JOIN Document.PaymentRequest AS Request
		|		ON Negative_Balance.PaymentRequest = Request.Ref
		|		LEFT JOIN Scheduled AS Scheduled
		|		ON Negative_Balance.PaymentRequest = Scheduled.PaymentRequest
		|			AND Negative_Balance.BankAccountCashAccount = Scheduled.BankAccountCashAccount
		|			AND Negative_Balance.Recipient = Scheduled.Recipient
		|			AND Negative_Balance.Organization = Scheduled.Organization
		|WHERE
		|	Negative_Balance.PaymentRequest REFS Document.PaymentRequest
		|
		|UNION ALL
		|
		|SELECT
		|	Negative_Balance.PaymentRequest,
		|	Negative_Balance.BankAccountCashAccount,
		|	Negative_Balance.Recipient,
		|	Negative_Balance.Organization,
		|	Negative_Balance.Sum,
		|	Request.Organization,
		|	Request.Employee,
		|	Request.Currency,
		|	VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder),
		|	FALSE,
		|	FALSE,
		|	CASE
		|		WHEN Scheduled.AmountPlanned IS NULL AND ISNULL(Request.DeletionMark, FALSE) = FALSE
		|			THEN TRUE
		|		ELSE FALSE
		|	END
		|FROM
		|	Negative_Balance AS Negative_Balance
		|		LEFT JOIN Document.ApplicationForBusinessTrip AS Request
		|		ON Negative_Balance.PaymentRequest = Request.Ref
		|		LEFT JOIN Scheduled AS Scheduled
		|		ON Negative_Balance.PaymentRequest = Scheduled.PaymentRequest
		|			AND Negative_Balance.BankAccountCashAccount = Scheduled.BankAccountCashAccount
		|			AND Negative_Balance.Recipient = Scheduled.Recipient
		|			AND Negative_Balance.Organization = Scheduled.Organization
		|WHERE
		|	Negative_Balance.PaymentRequest REFS Document.ApplicationForBusinessTrip
		|
		|UNION ALL
		|
		|SELECT
		|	Negative_Balance.PaymentRequest,
		|	Negative_Balance.BankAccountCashAccount,
		|	Negative_Balance.Recipient,
		|	Negative_Balance.Organization,
		|	Negative_Balance.Sum,
		|	Request.Organization,
		|	Request.Organization,
		|	Request.Currency,
		|	Request.BusinessOperation,
		|	FALSE,
		|	FALSE,
		|	CASE
		|		WHEN Scheduled.AmountPlanned IS NULL AND ISNULL(Request.DeletionMark, FALSE) = FALSE
		|			THEN TRUE
		|		ELSE FALSE
		|	END
		|FROM
		|	Negative_Balance AS Negative_Balance
		|		LEFT JOIN Document.CashTransferReferenceOrder AS Request
		|		ON Negative_Balance.PaymentRequest = Request.Ref
		|		LEFT JOIN Scheduled AS Scheduled
		|		ON Negative_Balance.PaymentRequest = Scheduled.PaymentRequest
		|			AND Negative_Balance.BankAccountCashAccount = Scheduled.BankAccountCashAccount
		|			AND Negative_Balance.Recipient = Scheduled.Recipient
		|			AND Negative_Balance.Organization = Scheduled.Organization
		|WHERE
		|	Negative_Balance.PaymentRequest REFS Document.CashTransferReferenceOrder
		|";
		
		QueryTexts.Add(QueryText, "ErrorsCashPayable");
		
	EndIf;
	
	#EndRegion
	
	#Region CashFlowLimits
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "CashFlowLimitsChange") Then
		
		QueryTexts.Add(
			"SELECT ALLOWED
			|	ExpenseLimits.Ref.PointInTime AS PointInTime,
			|	ExpenseLimits.CashFlowItem AS CashFlowItem,
			|	ExpenseLimits.ThereIsLimit AS ThereIsLimit
			|INTO TemporaryTableCFItems
			|FROM
			|	Document.CashFlowLimits.Limits AS ExpenseLimits
			|		INNER JOIN CashFlowLimitsChange AS Table
			|		ON (ExpenseLimits.Ref.Organization = Table.Organization
			|				OR NOT &UseCashFlowLimitsByCompanies)
			|			AND (ExpenseLimits.Ref.Department = Table.Department
			|				OR NOT &UseCashFlowLimitsByBusinessUnit)
			|			AND ExpenseLimits.CashFlowItem = Table.CashFlowItem
			|WHERE
			|	&ControlExcessOfCashFlowLimits
			|	AND NOT Table.CashFlowItem IS NULL
			|	AND ExpenseLimits.Ref.Period BETWEEN BEGINOFPERIOD(&CashFlowLimitPeriod, MONTH) AND ENDOFPERIOD(&CashFlowLimitPeriod, MONTH)
			|	AND ExpenseLimits.Ref.Posted");
		
		QueryTexts.Add(
			"SELECT
			|	TemporaryTableCFItems.CashFlowItem
			|INTO TemporaryTableCFItemsLimitIsNotLimited
			|FROM
			|	TemporaryTableCFItems AS TemporaryTableCFItems
			|		LEFT JOIN TemporaryTableCFItems AS Filter
			|		ON TemporaryTableCFItems.CashFlowItem = Filter.CashFlowItem
			|			AND TemporaryTableCFItems.PointInTime < Filter.PointInTime
			|WHERE
			|	Filter.PointInTime IS NULL
			|	AND NOT TemporaryTableCFItems.ThereIsLimit");
		
		QueryTexts.Add(
			"SELECT
			|	Table.CashFlowItem,
			|	Table.Organization,
			|	Table.Department
			|INTO LimitChanges
			|FROM
			|	CashFlowLimitsChange AS Table
			|		LEFT JOIN TemporaryTableCFItemsLimitIsNotLimited AS ArticlesDDSLimitIsNotLimited
			|		ON Table.CashFlowItem = ArticlesDDSLimitIsNotLimited.CashFlowItem
			|WHERE
			|	ArticlesDDSLimitIsNotLimited.CashFlowItem IS NULL
			|	AND Table.CashFlowItem <> VALUE(Catalog.CashFlowReportItems.EmptyRef)");
		
		QueryText =
			"SELECT ALLOWED
			|	TableOfRevolutions.CashFlowItem AS CashFlowItem,
			|	TableOfRevolutions.Organization AS Organization,
			|	TableOfRevolutions.Department AS Department,
			|	TableOfRevolutions.ConsumptionWithinLimitTurnover - TableOfRevolutions.LimitTurnover AS ExceedingLimit
			|FROM
			|	AccumulationRegister.CashFlowLimits.Turnovers(
			|			BEGINOFPERIOD(&CashFlowLimitPeriod, MONTH),
			|			ENDOFPERIOD(&CashFlowLimitPeriod, MONTH),
			|			,
			|			(CashFlowItem, Organization, Department) IN
			|				(SELECT
			|					LimitChanges.CashFlowItem,
			|					LimitChanges.Organization,
			|					LimitChanges.Department
			|				FROM
			|					LimitChanges)) AS TableOfRevolutions
			|WHERE
			|	&ControlExcessOfCashFlowLimits
			|	AND TableOfRevolutions.ConsumptionWithinLimitTurnover - TableOfRevolutions.LimitTurnover > 0";
		
		If TypeOf(Document) = Type("DocumentObject.PaymentRequest")
			And ValueIsFilled(Document.PaymentDate) Then
			Period = Document.PaymentDate;
		ElsIf ValueIsFilled(Document.RequiredPaymentDate) Then
			Period = Document.RequiredPaymentDate;
		Else
			Period = Document.Date;
		EndIf;
		
		Query.SetParameter("CashFlowLimitPeriod", Period);
		Query.SetParameter("UseCashFlowLimitsByCompanies",
			GetFunctionalOption("UseCashFlowLimitsByCompanies"));
		Query.SetParameter("UseCashFlowLimitsByBusinessUnit",
			GetFunctionalOption("UseCashFlowLimitsByBusinessUnit"));
		Query.SetParameter("ControlExcessOfCashFlowLimits",
			GetFunctionalOption("ControlExcessOfCashFlowLimits"));
		
		QueryTexts.Add(QueryText, "ErrorsCashFlowLimits");
		
	EndIf;
	
	#EndRegion
	
EndProcedure

// Displays messages to the user if there are errors in monitoring changes to recorded register movements.
//
// Parameters:
//  ControlResults - Structure - table with the results of the control changes
//  Document - DocumentObject - recordable document
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReportChangeControlResults(ControlResults, Document, Cancel) Export
	
	#Region CashToBePaid
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "CashFlowsPayableChange") Then
		
		ThereAreDiscrepanciesOfProps = False;
		
		For Each ErrorString In ControlResults.ErrorsCashPayable Do
			
			MessageText = "";
			ThisIsApplicationForSpendingCash =
				TypeOf(ErrorString.PaymentRequest) = Type("DocumentRef.PaymentRequest");
			
			If ThisIsApplicationForSpendingCash
				And ErrorString.ThereIsConsumptionOfAdditionalAttributes Then
				
				MessageText = StrTemplate(NStr("vi = 'Theo giấy đề nghị %1 và chứng từ thanh toán có sai lệch trong các mục tin.';
												|ru = 'По заявке %1 и документу оплаты имеются расхождения в реквизитах.';
												|en = 'The %1 request and the AR/AP transaction have discrepancies in details.'; fa = 'The %1 request and the AR/AP transaction have discrepancies in details.';
												|it = 'По заявке %1 и документу оплаты имеются расхождения в реквизитах.';
												|pl = 'The %1 request and the AR/AP transaction have discrepancies in details.';
												|tr = '%1 talebi ve ödeme belgesine göre özniteliklerde tutarsızlıklar mevcut.'"),
						ErrorString.PaymentRequest);
				ThereAreDiscrepanciesOfProps = True;
				
			EndIf;
			
			If ThisIsApplicationForSpendingCash And ErrorString.Organization <> ErrorString.OrganizationOfApplication Then
				
				MessageText = MessageText + ?(Not IsBlankString(MessageText), Chars.LF, "")
					+ StrTemplate(NStr("vi = 'Doanh nghiệp %1 trong chứng từ thanh toán không tương ứng với doanh nghiệp %2 trong yêu cầu';
										|ru = 'Организация %1 в документе оплаты не соответствует организации %2 в заявке';
										|en = 'Company %1 in the AR/AP transaction does not correspond to company %2 in the request'; fa = 'Company %1 in the AR/AP transaction does not correspond to company %2 in the request';
										|it = 'L''azienda %1 all''interno del documento di pagamento non corrisponde all''azienda %2 della richiesta';
										|pl = 'Firma %1 w dokumencie płatności nie odpowiada firmie %2 w zgłoszeniu';
										|tr = 'Ödeme belgesindeki %1 iş yeri, başvurudaki %2 iş yeriyle eşleşmiyor.'"),
					ErrorString.Organization, ErrorString.OrganizationOfApplication);
				ThereAreDiscrepanciesOfProps = True;
			EndIf;
			
			If ThisIsApplicationForSpendingCash And ErrorString.Recipient <> ErrorString.ApplicationRecipient
				And ErrorString.BusinessOperation <> Enums.BusinessTransactions.SalaryPayment
				And Not (ErrorString.BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder
				And ErrorString.PersonsList)
				And Not (ErrorString.BusinessOperation = Enums.BusinessTransactions.PaymentToVendor
				And ErrorString.ListOfCounterparties_) Then
				
				MessageText = MessageText + ?(Not IsBlankString(MessageText), Chars.LF, "")
					+ StrTemplate(NStr("vi = 'Người nhận %1 trong chứng từ thanh toán không khớp với người nhận %2 trong yêu cầu';
										|ru = 'Получатель %1 в документе оплаты не соответствует получателю %2 в заявке';
										|en = 'The %1 recipient in the AR/AP transaction does not match the %2 recipient in the request'; fa = 'The %1 recipient in the AR/AP transaction does not match the %2 recipient in the request';
										|it = 'Il destinatario %1 del documento di pagamento non corrisponde al destinatario %2 della richiesta';
										|pl = 'Odbiorca %1 w dokumencie płatności nie pasuje do odbiorcy %2 w zgłoszeniu';
										|tr = 'Ödeme belgesindeki %1 alıcısı, başvurudaki %2 alıcısıyla eşleşmiyor.'"),
						ErrorString.Recipient, ErrorString.ApplicationRecipient);
				ThereAreDiscrepanciesOfProps = True;
			EndIf;
			
			If Not ThereAreDiscrepanciesOfProps Then
				If ThisIsApplicationForSpendingCash Then
					
					MessageText = StrTemplate(NStr("vi = 'Số tiền được trả so với yêu cầu %1 vượt quá số tiền được xác nhận trong yêu cầu bởi %2 %3';
													|ru = 'По заявке %1 оплачено больше, чем утверждено в заявке, на %2 %3';
													|en = 'Amount paid against the %1 request exceeds the amount confirmed in the request by %2 %3'; fa = 'Amount paid against the %1 request exceeds the amount confirmed in the request by %2 %3';
													|it = 'Secondo la domanda %1 è stato pagato di più di quanto affermato nella richiesta, pari a %2 %3';
													|pl = 'Na zgłoszenie %1 opłacono więcej, niż zatwierdzono w zgłoszeniu, na %2 %3';
													|tr = '%1 uygulamasına göre ödeneni %2 %3 başvurusundan daha fazla onaylanan'"),
						ErrorString.PaymentRequest, -ErrorString.Sum, ErrorString.Currency);
				Else
					
					MessageText = StrTemplate(NStr("vi = 'Số tiền được trả so với chứng từ %1 vượt quá số tiền được xác nhận trong tham chiếu theo %2 %3';
													|ru = 'По документу %1 оплачено больше, чем утверждено в распоряжении, на %2 %3';
													|en = 'Amount paid against document %1 exceeds the amount confirmed in the reference by %2 %3'; fa = 'Amount paid against document %1 exceeds the amount confirmed in the reference by %2 %3';
													|it = 'Secondo il documento %1 è stato pagato di più di quanto affermato nella disposizione, pari a %2 %3';
													|pl = 'W dokumencie %1 opłacono więcej, niż zatwierdzono w zamówieniu, na %2 %3';
													|tr = '%1 belgesine göre ödeneni %2 %3 uygulamasından daha fazla onaylanan'"),
						ErrorString.PaymentRequest, -ErrorString.Sum, ErrorString.Currency);
				EndIf;
			EndIf;
			
			CommonClientServer.MessageToUser(MessageText, Document, ,, Cancel);
			
			If ThereAreDiscrepanciesOfProps Then
				Break;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	#EndRegion
	
	#Region CashFlowLimits
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "CashFlowLimitsChange") Then
		
		MessageTemplate = NStr("vi = 'Vượt quá giới hạn chi phí theo mục %1 đối với số tiền %2 %3';
								|ru = 'Превышен лимит расхода по статье %1 на сумму %2 %3';
								|en = 'Expense limit by item %1 is exceeded for the amount of %2 %3'; fa = 'Expense limit by item %1 is exceeded for the amount of %2 %3';
								|it = 'Superato il limite di spesa per l''articolo %1 per l''importo %2 %3';
								|pl = 'Został przekroczony limit zużycia wg pozycji %1 w wysokości %2 %3';
								|tr = '%1 maddesinin %2%3 tutarına göre aşılan gider limiti'");
		ManagementAccountingCurrency = Constants.ManagementAccountingCurrency.Get();
		
		For Each ErrorString In ControlResults.ErrorsCashFlowLimits Do
			
			MessageText = StrTemplate(MessageTemplate, ErrorString.CashFlowItem,
				ErrorString.ExceedingLimit, ManagementAccountingCurrency);
			
			CommonClientServer.MessageToUser(MessageText, Document);
			
		EndDo;
		
		If ValueIsFilled(ControlResults.ErrorsCashFlowLimits)
			And Not Document.OverLimits
			And GetFunctionalOption("ControlExcessOfCashFlowLimits") Then
			Cancel = True;
		EndIf;
		
	EndIf;
	
	#EndRegion
	
EndProcedure

// Occurs before writing the registers the document.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  TempTablesManager - TempTablesManager - temporary table Manager
//      used for storing register change control tables
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure BeforeRecordingDocumentRegisteredRecords(Document, TempTablesManager, Cancel) Export
	
	Return; // empty handler
	
EndProcedure

// Occurs after execution of the write registers of the instrument.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  TempTablesManager - TempTablesManager - temporary table Manager
//      used for storing register change control tables
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure AfterRecordingDocumentRegisteredRecords(Document, TempTablesManager, Cancel) Export
	If (TypeOf(Document) = Type("DocumentObject.PaymentRequest")
		Or TypeOf(Document) = Type("DocumentObject.ApplicationForBusinessTrip"))
		And Document.Closed_ Then
		Documents.PaymentRequest.CloseApplications(Document.Ref, True);
	EndIf;
	Return;
	
EndProcedure

#EndRegion

#EndRegion


