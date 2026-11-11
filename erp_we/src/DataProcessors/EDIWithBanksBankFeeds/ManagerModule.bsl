#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// The function performs the loading of transactions
// 
// Parameters:
//  ImportParameters - Structure - Boot parameter
// 
// Returns:
// Array of Structure - The result of the query:
// * ResponseStatus - String
// * FillParameters - String
// * ErrorsArray - Array of String
// * Number_Transactions - Number
//
Function ImportTransactions(ImportParameters) Export
	
	BankAccountsTable = ImportParameters.BankAccounts;
	StartDate = ImportParameters.StartDate;                                            
	EndDate = ?(ValueIsFilled(ImportParameters.EndDate), 
							ImportParameters.EndDate, EndOfDay(CurrentSessionDate()));

	StatusesOfResponse = BankFeedsDictionaryInternal.StatusesOfResponse();
	ListOfProcessingResults = New Array();
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
	"DataProcessor.EDIWithBanksBankFeeds.Form.ImportTransactions.ImportDocuments");
	Number_Transactions = 0;
		
	For Each CurLineOfBankAccounts In BankAccountsTable Do
		
		FillParameters = GenerateFillingParameters(CurLineOfBankAccounts);
		
		QueryExecutionResult = New Structure();
		QueryExecutionResult.Insert("ResponseStatus", StatusesOfResponse.NoResponseReceived); 
		QueryExecutionResult.Insert("FillParameters", FillParameters);
		QueryExecutionResult.Insert("ErrorsArray", New Array());
		QueryExecutionResult.Insert("Number_Transactions", 0);
		
		QueryOptions = ExchangeWithBankFeedsServer.ConvertToRequestParameters(FillParameters);
	
		StatusOfConsent = InformationRegisters.ConnectionsToBankFeedsBanks.StatusOfConsentForCurrentConnection(QueryOptions, FillParameters);
		
		If Not StatusOfConsent.ConsentIsActive Then

			QueryExecutionResult.ErrorsArray.Add(StatusOfConsent.ConnectionInfo);
			
			ListOfProcessingResults.Add(QueryExecutionResult);

			Break;
		EndIf;	
	
		If Not ValueIsFilled(QueryOptions.InvoiceId) Then
			
			ErrorText  = StringFunctionsClientServer.SubstituteParametersToString(
			        NStr("vi = 'Tài khoản ngân hàng:%1 không được kết nối với %2:%3. Chưa kết nhập giao dịch';
						|ru = 'Банковский счет:%1 не подключен к %2:%3. Загрузка транзакций не выполнена';
						|en = 'The %1 bank account is not connected to %2:%3. Transactions are not imported'; fa = 'The %1 bank account is not connected to %2:%3. Transactions are not imported';
						|it = 'Банковский счет:%1 не подключен к %2:%3. Загрузка транзакций не выполнена';
						|pl = 'The %1 bank account is not connected to %2:%3. Transactions are not imported';
						|tr = 'Banka hesabı:%1, %2:%3 dahiline bağlı değil. İşlemin yüklenmesi gerçekleştirilmedi'"),
					CurLineOfBankAccounts.BankAccount, "BankFeeds", QueryOptions.Service);
		
			QueryExecutionResult.ResponseStatus = StatusesOfResponse.NoResponseReceived; 
			QueryExecutionResult.FillParameters = FillParameters;
			QueryExecutionResult.ErrorsArray.Add(ErrorText);
			
			ListOfProcessingResults.Add(QueryExecutionResult);
			
			Break;
			
		EndIf;	
	
		ResponseParametersFromService = ExchangeWithBankFeedsServer.GetTransactions(
												QueryOptions, 
												?(ValueIsFilled(StartDate), BegOfDay(StartDate), 
													BegOfDay(CurLineOfBankAccounts.ImportStartDate)),
												EndOfDay(EndDate));
		
		ErrorsArray = ResponseParametersFromService.ErrorsArray;
		If ErrorsArray.Count() = 0 Then
			
			CreateDocumentsOnReceivedTransactions(
				ResponseParametersFromService.TransactionsTable, 
				FillParameters, ImportParameters
				);
			
		EndIf; 
		
		QueryExecutionResult.ResponseStatus = ResponseParametersFromService.ResponseStatus; 
		QueryExecutionResult.FillParameters = ResponseParametersFromService.FillParameters;
		QueryExecutionResult.ErrorsArray = ResponseParametersFromService.ErrorsArray;
		QueryExecutionResult.Number_Transactions = ResponseParametersFromService.TransactionsTable.Count();  
		
		Number_Transactions = Number_Transactions + QueryExecutionResult.Number_Transactions;
		
		ListOfProcessingResults.Add(QueryExecutionResult);
	
	EndDo;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, Number_Transactions);
	
	Return ListOfProcessingResults;
	
EndFunction	

// This function uploads payment documents
// 
// Parameters:
//  ExportingParameters - Structure - Boot parameter
// 
// Returns:
// Array of Structure - Array of query results:
// * ResponseStatus - String
// * FillParameters - String
// * LinkToPaymentConfirmation - String
// * PaymentDocumentData - String
// * ErrorsArray - Array of String
//
Function ExportPaymentDocuments(ExportingParameters) Export
	
	ListOfResponses = New Array;
	TableOfPaymentDocumentsForUploading = ExportingParameters.DocumentsToExport;
	Filter = New Structure("BankAccount", ""); 
	StatusesOfResponse = BankFeedsDictionaryInternal.StatusesOfResponse();
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"DataProcessor.EDIWithBanksBankFeeds.Form.ExportPaymentDocuments.Unload");
		
	For Each CurRowTableOfBankAccounts In ExportingParameters.BankAccounts Do
		
		QueryOptions = ExchangeWithBankFeedsServer.ConvertToRequestParameters(CurRowTableOfBankAccounts);        
		
		QueryExecutionResult = New Structure();
		QueryExecutionResult.Insert("ResponseStatus", StatusesOfResponse.NoResponseReceived); 
		QueryExecutionResult.Insert("FillParameters", QueryOptions);
		QueryExecutionResult.Insert("LinkToPaymentConfirmation", "");
		QueryExecutionResult.Insert("PaymentDocumentData", "");
		QueryExecutionResult.Insert("ErrorsArray", New Array());
		
		StatusOfConsent = InformationRegisters.ConnectionsToBankFeedsBanks.StatusOfConsentForCurrentConnection(
														QueryOptions, CurRowTableOfBankAccounts);
		
		If Not StatusOfConsent.ConsentIsActive Then

			QueryExecutionResult.ErrorsArray.Add(StatusOfConsent.ConnectionInfo);
			
			ListOfResponses.Add(QueryExecutionResult);

			Break;  
			
		EndIf;	
		
		Filter.BankAccount = CurRowTableOfBankAccounts.Ref;
		
		FoundRowsTableOfPaymentDocumentsForUploading = TableOfPaymentDocumentsForUploading.FindRows(Filter);
		
		For Each CurCurrentRowTableOfPaymentDocumentsForUnloading In FoundRowsTableOfPaymentDocumentsForUploading Do
			
			ResponseParametersFromService = ExchangeWithBankFeedsServer.SendPaymentDocument(
				Common.ValueTableRowToStructure(CurCurrentRowTableOfPaymentDocumentsForUnloading),
				QueryOptions);
		
			ErrorsArray = ResponseParametersFromService.ErrorsArray;
			If ErrorsArray.Count() = 0 Then
			
			EndIf; 
			
			ListOfResponses.Add(ResponseParametersFromService);
			
		EndDo;	
		
	EndDo;	
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, ListOfResponses.Count());
	
	Return ListOfResponses;
	
EndFunction	

// The function checks the Status of payment documents
// 
// Parameters:
//  ParametersOfPayments - Structure - Boot parameter
// 
// Returns:
// Array of Structure - List Of Responses:
// * Organization - String
//
Function CheckingStatusOfPaymentDocuments(ParametersOfPayments) Export
	
	TableOfPaymentDocuments = ParametersOfPayments.DocumentsToExport;
	ListOfResponses = New Array;
	
	BankAccounts = ParametersOfPayments.BankAccounts; 
	ListCompanies = ParametersOfPayments.BankAccounts.Copy(,"Organization");
	CompanyArray = New Array();
	For Each CurLineIsListOfOrganizations In ListCompanies Do
		CompanyArray.Add(CurLineIsListOfOrganizations.Organization);
	EndDo;	
	
	CompanyArray = CommonClientServer.CollapseArray(CompanyArray);
	FilterByOrganization = New Structure("Organization");
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"DataProcessor.EDIWithBanksBankFeeds.Form.ExportPaymentDocuments.CheckingStatusOfPaymentDocuments");	
	
	For Each CurLineIsArrayOfOrganizations In CompanyArray Do
		FilterByOrganization.Organization = CurLineIsArrayOfOrganizations;
		
		  BankAccountLinesFound = BankAccounts.FindRows(FilterByOrganization);
		  
		If BankAccountLinesFound.Count() > 0 Then
			
			CurRowTableOfBankAccounts = BankAccountLinesFound[0];	
			
			QueryOptions = ExchangeWithBankFeedsServer.ConvertToRequestParameters(CurRowTableOfBankAccounts);        

			ResponseParametersFromService = ExchangeWithBankFeedsServer.GetStatusesOfPaymentDocuments(QueryOptions);
			
			ErrorsArray = ResponseParametersFromService.ErrorsArray;
			If ErrorsArray.Count() = 0 Then
			
			 	 TableOfSelectedPaymentDocumentsInDatabase = TableOfPaymentDocuments.Copy(FilterByOrganization);
			  
				 If ResponseParametersFromService.PaymentTableInService.Count() > 0
					  And TableOfSelectedPaymentDocumentsInDatabase.Count() > 0 Then
						CheckStatusOfPaymentsSentWithPaymentsInService(TableOfSelectedPaymentDocumentsInDatabase, 
							ResponseParametersFromService.PaymentTableInService);
				 EndIf;	
			
					ResponseParametersFromService.PaymentTableInService = "";
			
					ListOfResponses.Add(ResponseParametersFromService);
					
			EndIf; 

		EndIf;	
			
	EndDo;	
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, ListOfResponses.Count());
		
	Return ListOfResponses;
	
EndFunction	

// Fills in the value of the field from the counterparty's data table.
// 
// Parameters:
//  DataTable - ValueTable - data containing the Name and checkpoint of the counterparty.
//  CurrentValue - String - the value of the field to be filled in.
//  Document - DocumentRef - the document for which the filling is performed.
//  Flag - Number - a sign that determines the choice of props from the data table of the counterparty of the data table: 0 - Name,
//                    1 - CHECKPOINT.
//
Procedure FillInCounterpartyDetails(DataTable, CurrentValue, Document, Flag) Export

	Filter = New Structure("Document, Flag", Document, Flag);
	CounterpartyData = DataTable.FindRows(Filter);
	CurrentValue = ?(CurrentValue <> "", CurrentValue,
						?(CounterpartyData.Count() > 0, CounterpartyData[0].AttributeValue, ""));

EndProcedure

// Creates a table of documents to be uploaded to the Bank
//
// Parameters:
//    ArrayOfAccounts_ - Array - account for the selection of payments to be unloaded
//    StartDate - Date - Start of the document selection period
//    EndDate - Date - End of the document selection period
//    NotExportedOnly - Boolean - Flag for selecting only payments that were not uploaded earlier.
//
// Returns:
//    ValueTable - table of documents.
//
Function TableOfDocumentsToUpload(
	ArrayOfAccounts_ = Undefined,
	StartDate = '00010101',
	EndDate = '00010101',
	NotExportedOnly = False) Export
	
	Query = New Query;
	Query.Text = QueryTextDocumentsToExport();
	
	Query.SetParameter("ArrayOfAccounts_", ArrayOfAccounts_);
	Query.SetParameter("StartDate", StartDate);
	Query.SetParameter("EndDate", EndDate);
	Query.SetParameter("NotExportedOnly", NotExportedOnly);
	
	PaymentFields = InitializePaymentFields();
	
	Schema = New QuerySchema;
	Schema.SetQueryText(Query.Text);
	
	QueryBatch = Schema.QueryBatch[2]; // QuerySchemaSelectQuery
	QueryFields = QueryBatch.Columns;
	
	For Each KeyAndValue In PaymentFields Do
		If ValueIsFilled(KeyAndValue.Value) Then
			TheQueryBox = QueryFields.Find(KeyAndValue.Value);
			If TheQueryBox <> Undefined Then
				TheQueryBox.Alias = KeyAndValue.Key;
			EndIf;
		EndIf;
	EndDo;
	
	Query.Text = Schema.GetQueryText();
	
	Table = Query.Execute().Unload();
	
	Return Table;
	
EndFunction

#EndRegion

#Region Private

Procedure CheckStatusOfPaymentsSentWithPaymentsInService(TableOfPaymentDocumentsIn1CDatabase, PaymentDocumentsInService)

	ArrayOfAcceptedPayments = New Array;			
	For Each CurLineIsPaymentDocumentsInService In PaymentDocumentsInService Do
		If CurLineIsPaymentDocumentsInService.status <> "accepted" Then	
			Continue;
		EndIf;	
			
		ArrayOfAcceptedPayments.Add(CurLineIsPaymentDocumentsInService.Ref);
			
	EndDo;	 
		
	FilterSelection = New Structure("Ref");
	For Each CurLineIsArrayOfAcceptedPayments In ArrayOfAcceptedPayments Do
		
		FilterSelection.Ref = CurLineIsArrayOfAcceptedPayments;
		
		FoundRows = PaymentDocumentsInService.FindRows(FilterSelection);
		For Each CurCurrentRowFoundRows In FoundRows Do
			If CurLineIsPaymentDocumentsInService.status = "accepted" Then	
				Continue;
			EndIf;	
			
			CurCurrentRowFoundRows.Ref = Documents.BankAccountIssue.EmptyRef();
			
		EndDo;	
		
	EndDo;	

	Query = New Query();
	Query.SetParameter("TableOfPaymentDocumentsIn1CDatabase", TableOfPaymentDocumentsIn1CDatabase);
	Query.SetParameter("PaymentDocumentsInService", PaymentDocumentsInService);
	Query.Text = 
	"SELECT
	|	PaymentDocumentsInService.id AS id,
	|	PaymentDocumentsInService.status AS status,
	|	PaymentDocumentsInService.Ref AS Ref
	|INTO PaymentDocumentsInService
	|FROM
	|	&PaymentDocumentsInService AS PaymentDocumentsInService
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfPaymentDocumentsIn1CDatabase.Ref AS Ref
	|INTO TableOfPaymentDocumentsIn1CDatabase
	|FROM
	|	&TableOfPaymentDocumentsIn1CDatabase AS TableOfPaymentDocumentsIn1CDatabase
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BankFeedsTransactionStatuses.Object AS Object,
	|	BankFeedsTransactionStatuses.TransactionID AS TransactionID,
	|	BankFeedsTransactionStatuses.Status AS Status
	|INTO DocumentsAwaitingStatusChange
	|FROM
	|	InformationRegister.BankFeedsTransactionStatuses AS BankFeedsTransactionStatuses
	|WHERE
	|	BankFeedsTransactionStatuses.Status = VALUE(Enum.BankFeedsPaymentDocumentStatuses.processing)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfPaymentDocumentsIn1CDatabase.Ref AS PaymentDocument,
	|	PaymentDocumentsInService.status AS Status,
	|	PaymentDocumentsInService.id AS IdOfServiceEntry
	|FROM
	|	TableOfPaymentDocumentsIn1CDatabase AS TableOfPaymentDocumentsIn1CDatabase
	|		LEFT JOIN PaymentDocumentsInService AS PaymentDocumentsInService
	|		ON TableOfPaymentDocumentsIn1CDatabase.Ref = PaymentDocumentsInService.Ref
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentsAwaitingStatusChange.Object,
	|	PaymentDocumentsInService.status,
	|	PaymentDocumentsInService.id
	|FROM
	|	DocumentsAwaitingStatusChange AS DocumentsAwaitingStatusChange
	|		LEFT JOIN PaymentDocumentsInService AS PaymentDocumentsInService
	|		ON DocumentsAwaitingStatusChange.Object = PaymentDocumentsInService.Ref
	|
	|ORDER BY
	|	Status";

	Result = Query.Execute().Select();
	
	// Status views = 
	// processing - In the process of execution
	// accepted - The payment was accepted by the provider
	// rejected - The payment was canceled by the provider
	// failed - the payment was canceled, it is not clear why
	// unknown - payment error 
	// deleted - the payment was deleted
	//
	While Result.Next() Do  
		If Not ValueIsFilled(Result.Status) Then
			Continue;
		EndIf;	

		PaymentDocument = Result.PaymentDocument;
		
		BeginTransaction();
		Try
		
			Block = New DataLock;
			LockItem = Block.Add("InformationRegister.BankFeedsTransactionStatuses");
			LockItem.Mode = DataLockMode.Exclusive;
			LockItem.SetValue("Object", PaymentDocument);
			Block.Lock();
			
			Set = InformationRegisters.BankFeedsTransactionStatuses.CreateRecordSet();
			Set.Filter.IDType.Set(Enums.BankFeedsIDTypes.ByPaymentOrder);
			Set.Filter.Object.Set(PaymentDocument);
			
			Record = Set.Add();
			
			Record.Object = PaymentDocument;
			Record.IDType = Enums.BankFeedsIDTypes.ByPaymentOrder;
			
			Record.Status = Enums.BankFeedsPaymentDocumentStatuses[Result.Status];
			Record.TransactionID = Result.IdOfServiceEntry;
			
			DocumentObject = PaymentDocument.GetObject();
			DocumentObject.ExportDate = CurrentSessionDate();
			
			DocumentObject.Write();
			Set.Write(True);
			
			CommitTransaction();
		
		Except
			RollbackTransaction();
			ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
			WriteLogEvent(NStr("vi = 'Bản ghi trạng thái';
								|ru = 'Запись статусов';
								|en = 'Status recording'; fa = 'Status recording';
								|it = 'Запись статусов';
								|pl = 'Status recording';
								|tr = 'Durumların kaydedilmesi'", Common.DefaultLanguageCode()), 
														EventLogLevel.Error, , , ErrorDescription);
			
			Raise;
		EndTry;
		
	EndDo;
	
EndProcedure

Function QueryTextDocumentsToExport()
	
	QueryText = 
	"SELECT ALLOWED
	|	NonCashFunds.Recorder AS Ref
	|INTO PaymentOrders
	|FROM
	|	AccumulationRegister.BankAccountCash AS NonCashFunds
	|		INNER JOIN Document.BankAccountIssue AS DocumentData
	|		ON (DocumentData.Ref = NonCashFunds.Recorder)
	|WHERE
	|	NonCashFunds.ToWriteOff <> 0
	|	AND (NonCashFunds.Period BETWEEN &StartDate AND &EndDate
	|	OR &EndDate = DATETIME(1, 1, 1)
	|	AND NonCashFunds.Period >= &StartDate)
	|	AND DocumentData.Posted
	|	AND NOT DocumentData.ProcessedByBank
	|	AND DocumentData.PaymentDocumentType IN (VALUE(Enum.TypesOfPaymentDocuments.PaymentOrder),
	|		VALUE(Enum.TypesOfPaymentDocuments.MandatorySaleReferenceOrder))
	|	AND DocumentData.BankAccount IN (&ArrayOfAccounts_)
	|	AND (DocumentData.ExportDate = DATETIME(1, 1, 1)
	|	OR NOT &NotExportedOnly)
	|GROUP BY
	|	NonCashFunds.Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	NonCashFunds.Recorder AS Ref
	|INTO PaymentRequirements
	|FROM
	|	AccumulationRegister.BankAccountCash AS NonCashFunds
	|		INNER JOIN Document.BankAccountReceiptNote AS DocumentData
	|		ON (DocumentData.Ref = NonCashFunds.Recorder)
	|WHERE
	|	NonCashFunds.ToReceive_ <> 0
	|	AND (NonCashFunds.Period BETWEEN &StartDate AND &EndDate
	|	OR &EndDate = DATETIME(1, 1, 1)
	|	AND NonCashFunds.Period >= &StartDate)
	|	AND DocumentData.Posted
	|	AND NOT DocumentData.ProcessedByBank
	|	AND DocumentData.PaymentDocumentType = """"
	|	AND DocumentData.BankAccount IN (&ArrayOfAccounts_)
	|	AND (DocumentData.ExportDate = DATETIME(1, 1, 1)
	|	OR NOT &NotExportedOnly)
	|GROUP BY
	|	NonCashFunds.Recorder
	|;
	|//////////////////////////////////////////////////////////////////////////////
	|";
	
	QueryText = QueryText
		+ RequestTextPaymentOrdersThirdParties() + "UNION ALL"
		+ RequestTextPaymentOrdersInternal() + "UNION ALL"
		+ RequestTextPaymentOrdersTransfers() + "UNION ALL"
		+ RequestTextPaymentRequirementsThirdParties() + "UNION ALL"
		+ RequestTextPaymentRequirementsInternal() + "UNION ALL"
		+ QueryTextCurrencyConversion()
		;
	
	Return QueryText;
	
EndFunction

Function RequestTextPaymentOrdersThirdParties() 
	
	QueryText = "
	|
	|SELECT ALLOWED
	|	DocumentData.ExportDate                          AS ExportDate,
	|	DocumentData.Number                                 AS Number,
	|	DocumentData.Date                                  AS Date,
	|	DocumentData.DocumentAmount                        AS Sum,
	|	DocumentData.Currency                                AS Currency,
	|	DocumentData.Currency.Description                   AS ISOCurrencyCode_,
	|	DocumentData.Currency.Code                            AS CurrencyCode_,
	|	DocumentData.PaymentPurposes                     AS PaymentPurposes,
	|	DocumentData.BusinessOperation                 AS Operation,
	|	DocumentData.Organization                           AS Organization,
	|	DocumentData.BankAccount                        AS BankAccount,
	|	DocumentData.CounterpartyBankAccount             AS CounterpartyBankAccount,
	|	DocumentData.Comment                           AS Comment,
	|	DocumentData.PaymentDocumentType                AS DocumentKind,
	|	DocumentData.PaymentKind                            AS PaymentKind,
	|	DocumentData.Ref                                AS Ref,
	|	DocumentData.PaymentID                  AS Code,
	|	DocumentData.KeyOfTransactionWithForeignCurrency                   AS KeyOfTransactionWithForeignCurrency,
	|	DocumentData.EmployeeResponsible                         AS EmployeeResponsible,
	|	DocumentData.EmployeeResponsible.Individual          AS Individual,
	|	DocumentData.TransferFeeType                  AS TransferFeeType,
	|	PRESENTATION(DocumentData.TransferFeeType)   AS TypeOfTransferFeeName,
	|	DocumentData.InformationForRegulatoryBodies      AS InformationForRegulatoryBodies,
	|	CASE
	|		WHEN DocumentData.PaymentDocumentType = VALUE(Enum.TypesOfPaymentDocuments.PaymentOrder)
	|			THEN ""01""
	|		WHEN DocumentData.PaymentDocumentType = VALUE(Enum.TypesOfPaymentDocuments.LetterOfCredit)
	|			THEN ""08""
	|		WHEN DocumentData.PaymentDocumentType = VALUE(Enum.TypesOfPaymentDocuments.CollectionOrder_2)
	|			THEN ""06""
	|		WHEN DocumentData.PaymentDocumentType = VALUE(Enum.TypesOfPaymentDocuments.PaymentDemand)
	|			THEN ""02""
	|		ELSE ""00""
	|	END AS PaymentKind_,
	|	
	|	
	|	CASE
	|		WHEN DocumentData.ExportDate = DATETIME(1,1,1)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ToExport,
	|	
	|	CompanyBankAccount.CashCurrency                AS WriteOffCurrency,
	|	CompanyBankAccount.CashCurrency.Description   AS WriteOffCurrencyISOCode,
	|	CompanyBankAccount.CashCurrency.Code            AS CurrencyOfDebitingCode,
	|	DocumentData.DocumentAmount                                 AS DebitingCurrencyAmount,
	|	
	|	CounterpartyBankAccounts.CashCurrency              AS TransferCurrency,
	|	CounterpartyBankAccounts.CashCurrency.Description AS CurrencyOfTranslationISOCode,
	|	CounterpartyBankAccounts.CashCurrency.Code          AS TransferCurrencyCode,
	|	DocumentData.DocumentAmount                                 AS TransferCurrencyAmount,
	
	// Organization and organization account
	
	|	CompanyBankAccount.AccountNumber AS CompanyBankAccount_,
	|	CompanyBankAccount.ThisIsAnIBAN AS OrganizationAndAccountAreIBAN,
	
	|	CASE
	|		WHEN CAST(DocumentData.PayerSName AS STRING(255)) = """" THEN
	|			CASE
	|				WHEN (CAST(CompanyBankAccount.CorrespondentText AS STRING(255))) = """"
	|					THEN DocumentData.Organization.Description
	|				ELSE CompanyBankAccount.CorrespondentText
	|			END
	|	ELSE
	|		DocumentData.PayerSName
	|	END AS CompanyName,
	
	|	CASE
	|		WHEN CAST(DocumentData.PayerSName AS STRING(255)) = """" THEN
	|			CASE
	|				WHEN (CAST(CompanyBankAccount.CorrespondentText AS STRING(255))) = """"
	|					THEN DocumentData.Organization.AbbreviatedDescription
	|				ELSE CompanyBankAccount.CorrespondentText
	|			END
	|	ELSE
	|		DocumentData.PayerSName
	|	END AS OrganizationAbbreviatedName,
	
	|	CASE
	|		WHEN (CAST(CompanyBankAccount.CorrespondentText AS STRING(255))) = """"
	|			THEN DocumentData.Organization.DescriptionInternational
	|		ELSE CompanyBankAccount.CorrespondentText
	|	END AS CompanyNameInternational,
	|	CASE
	|		WHEN DocumentData.TINOfPayer = """" THEN
	|			DocumentData.Organization.TIN
	|		ELSE
	|			DocumentData.TINOfPayer
	|	END AS CompanyTIN,
	|	CASE
	|		WHEN DocumentData.PayerCRTR = """" THEN
	|			CASE
	|				WHEN DocumentData.RegistrationWithTaxAuthority IN (
	|					"""",
	|					UNDEFINED)
	|				THEN DocumentData.Organization.CRTR
	|			END
	|	ELSE
	|		DocumentData.PayerCRTR
	|	END AS CompanyCRTR,
	|	OrganizationContactInformation.Presentation AS OrganizationAddressInternational,
	|	OrganizationContactInformation.FieldValues AS OrganizationAddressAndFieldValues,
	|	OrganizationContactInformation.Value AS OrganizationAddressInternationalSignificance,
	|	OrganizationContactInformation.Country AS OrganizationCountryName,
	|	OrganizationContactInformation.State AS OrganizationRegion,
	|	OrganizationContactInformation.City AS OrganizationCity,
	
	|	&OrganizationSBankAccountData,
	
	// Counterparty and counterparty account
	
	|	CounterpartyBankAccounts.AccountNumber AS CounterpartyBankAccount_,
	|	CounterpartyBankAccounts.ThisIsAnIBAN AS CounterpartyToAccountIsIBAN,
	
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CashIssueAsLoanToEmployee) THEN
	|			DocumentData.AdvanceHolder
	|		WHEN DocumentData.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder),
	|			VALUE(Enum.BusinessTransactions.SalaryPaymentToBankAccounts)) THEN
	|			CounterpartyBankAccounts.Owner
	|		ELSE
	|			DocumentData.Counterparty
	|	END AS Counterparty,
	
	|	CASE
	|		WHEN DocumentData.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder),
	|			VALUE(Enum.BusinessTransactions.CashIssueAsLoanToEmployee),
	|			VALUE(Enum.BusinessTransactions.SalaryPaymentToBankAccounts))
	|		THEN
	|			VALUE(Enum.LegalEntityIndividual.Person)
	|		ELSE
	|			DocumentData.Counterparty.LegalEntityIndividual
	|	END AS LegalEntityIndividual,
	
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CashIssueAsLoanToEmployee) THEN
	|			DocumentData.AdvanceHolder.Description
	|		WHEN DocumentData.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder),
	|			VALUE(Enum.BusinessTransactions.SalaryPaymentToBankAccounts)) THEN
	|			CounterpartyBankAccounts.Owner.Description
	|		ELSE
	|			DocumentData.Counterparty.Description
	|	END AS CounterpartyName_,
	
	|	CASE
	|		WHEN CAST(CounterpartyBankAccounts.CorrespondentText AS STRING(255)) = """" THEN
	|		CASE
	|			WHEN DocumentData.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder),
	|				VALUE(Enum.BusinessTransactions.CashIssueAsLoanToEmployee),
	|				VALUE(Enum.BusinessTransactions.SalaryPaymentToBankAccounts))
	|				AND VALUETYPE(CounterpartyBankAccounts.Owner) = TYPE(Catalog.Persons)
	|			THEN
	|				DocumentData.AdvanceHolder.Description
	|			WHEN DocumentData.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder),
	|				VALUE(Enum.BusinessTransactions.SalaryPaymentToBankAccounts)) THEN
	|				CAST(CounterpartyBankAccounts.Owner AS Catalog.Counterparties).DescriptionFull
	|			ELSE
	|				DocumentData.Counterparty.DescriptionFull
	|			END
	|		ELSE
	|			CounterpartyBankAccounts.CorrespondentText
	|	END AS CounterpartyAbbreviatedName,
	
	|	CASE
	|		WHEN DocumentData.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder),
	|			VALUE(Enum.BusinessTransactions.CashIssueAsLoanToEmployee),
	|			VALUE(Enum.BusinessTransactions.SalaryPaymentToBankAccounts))
	|			AND VALUETYPE(CounterpartyBankAccounts.Owner) = TYPE(Catalog.Persons) 
	|		THEN
	|			DocumentData.AdvanceHolder.Description
	|		WHEN DocumentData.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder),
	|			VALUE(Enum.BusinessTransactions.SalaryPaymentToBankAccounts)) THEN
	|			CAST(CounterpartyBankAccounts.Owner AS Catalog.Counterparties).DescriptionInternational
	|		ELSE
	|			DocumentData.Counterparty.DescriptionInternational
	|	END AS CounterpartyNameInternational,
	|	CASE
	|		WHEN CounterpartyBankAccounts.CorrespondentTIN = """" THEN
	|			CASE
	|				WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CashIssueAsLoanToEmployee) THEN
	|					DocumentData.AdvanceHolder.TIN
	|				WHEN DocumentData.BusinessOperation IN (
	|					VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder),
	|					VALUE(Enum.BusinessTransactions.SalaryPaymentToBankAccounts)) THEN
	|					CounterpartyBankAccounts.Owner.TIN
	|				ELSE
	|					DocumentData.Counterparty.TIN
	|			END
	|		ELSE
	|			CounterpartyBankAccounts.CorrespondentTIN
	|	END AS CounterpartyTIN,
	|	ISNULL(CounterpartyBankAccounts.CorrespondentCRTR, """") AS CounterpartyCRTR,
	|	CounterpartyContactInformation.Presentation AS CounterpartyAddressInternational,
	|	CounterpartyContactInformation.FieldValues AS CounterpartyAddressAndFieldValues,
	|	CounterpartyContactInformation.Value AS CounterpartyAddressInternationalValue,
	|	CounterpartyContactInformation.Country AS CounterpartyCountry,
	|	CounterpartyContactInformation.State AS CounterpartyRegion,
	|	CounterpartyContactInformation.City AS CounterpartyCity,
	
	|	&CounterpartySBankAccountData,
	
	|	
	|	"""" AS CommissionAccountNumber,
	|	"""" AS CommissionAccountBIC,
	|	"""" AS NameOfBankCommissionAccount
	|	
	|FROM
	|	Document.BankAccountIssue AS DocumentData
	|	
	|	INNER JOIN
	|		PaymentOrders AS PaymentOrders
	|	ON
	|		DocumentData.Ref = PaymentOrders.Ref
	|	
	|	
	|	LEFT JOIN
	|		Catalog.Companies.ContactInformation AS OrganizationContactInformation
	|	ON
	|		OrganizationContactInformation.Ref = DocumentData.Organization
	|		AND OrganizationContactInformation.Kind = VALUE(Catalog.ContactInformationKinds.InternationalAddressOfCompany)
	|	
	|	LEFT JOIN
	|		Catalog.Counterparties.ContactInformation AS CounterpartyContactInformation
	|	ON
	|		CounterpartyContactInformation.Ref = DocumentData.Counterparty
	|		AND CounterpartyContactInformation.Kind = VALUE(Catalog.ContactInformationKinds.InternationalAddressOfCounterparty)
	|	
	|	LEFT JOIN
	|		Catalog.CompaniesBankAccounts AS CompanyBankAccount
	|	ON
	|		CompanyBankAccount.Ref = DocumentData.BankAccount
	|	LEFT JOIN Catalog.BankClassifier AS BanksOfOrganizations
	|		ON CompanyBankAccount.Bank = BanksOfOrganizations.Ref
	|	LEFT JOIN Catalog.WorldCountries AS CountriesOfBankingOrganizations
	|		ON BanksOfOrganizations.CountryCode = CountriesOfBankingOrganizations.Code
	|	LEFT JOIN Catalog.BankClassifier AS BanksForSettlementsOfOrganizations
	|		ON CompanyBankAccount.TransferBank = BanksForSettlementsOfOrganizations.Ref
	|	LEFT JOIN Catalog.WorldCountries AS CountriesOfBanksForSettlementsOfOrganizations
	|		ON BanksForSettlementsOfOrganizations.CountryCode = CountriesOfBanksForSettlementsOfOrganizations.Code
	|	
	|	LEFT JOIN
	|		Catalog.CounterpartyBankAccounts AS CounterpartyBankAccounts
	|	ON
	|		CounterpartyBankAccounts.Ref = DocumentData.CounterpartyBankAccount
	|	LEFT JOIN Catalog.BankClassifier AS CounterpartyBanks
	|		ON CounterpartyBankAccounts.Bank = CounterpartyBanks.Ref
	|	LEFT JOIN Catalog.WorldCountries AS CounterpartyBankCountries
	|		ON CounterpartyBanks.CountryCode = CounterpartyBankCountries.Code
	|	LEFT JOIN Catalog.BankClassifier AS BanksForCounterpartySettlements
	|		ON CounterpartyBankAccounts.TransferBank = BanksForCounterpartySettlements.Ref
	|	LEFT JOIN Catalog.WorldCountries AS BankCountriesForCounterpartySettlements
	|		ON BanksForCounterpartySettlements.CountryCode = BankCountriesForCounterpartySettlements.Code
	|	
	|WHERE
	|	DocumentData.BusinessOperation NOT IN (
	|		VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany),
	|		VALUE(Enum.BusinessTransactions.RefundToAnotherCompany),
	|		VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices),
	|		VALUE(Enum.BusinessTransactions.TransferCashToAnotherAccount),
	|		VALUE(Enum.BusinessTransactions.CurrencyConversion)
	|		)
	|";
	
	QueryText = StrReplace(QueryText, "&OrganizationSBankAccountData", TextDetailsOfOrganizationSBankAccount());
	QueryText = StrReplace(QueryText, "&CounterpartySBankAccountData", TextDetailsOfCounterpartySBankAccount());
	QueryText = StrReplace(QueryText, "DocumentData.AdvanceHolder.Description", "DocumentData.AdvanceHolder.LASTFIRSTNAME");
	Return QueryText;
	
EndFunction

Function RequestTextPaymentOrdersInternal() 
	
	QueryText = "
	|
	|SELECT
	|	DocumentData.ExportDate                          AS ExportDate,
	|	DocumentData.Number                                 AS Number,
	|	DocumentData.Date                                  AS Date,
	|	DocumentData.DocumentAmount                        AS Sum,
	|	DocumentData.Currency                                AS Currency,
	|	DocumentData.Currency.Description                   AS ISOCurrencyCode_,
	|	DocumentData.Currency.Code                            AS CurrencyCode_,
	|	DocumentData.PaymentPurposes                     AS PaymentPurposes,
	|	DocumentData.BusinessOperation                 AS Operation,
	|	DocumentData.Organization                           AS Organization,
	|	DocumentData.BankAccount                        AS BankAccount,
	|	DocumentData.BankAccountBeneficiary              AS CounterpartyBankAccount,
	|	DocumentData.Comment                           AS Comment,
	|	DocumentData.PaymentDocumentType                AS DocumentKind,
	|	DocumentData.PaymentKind                            AS PaymentKind,
	|	DocumentData.Ref                                AS Ref,
	|	DocumentData.PaymentID                  AS Code,
	|	DocumentData.KeyOfTransactionWithForeignCurrency                   AS KeyOfTransactionWithForeignCurrency,
	|	DocumentData.EmployeeResponsible                         AS EmployeeResponsible,
	|	DocumentData.EmployeeResponsible.Individual          AS Individual,
	|	DocumentData.TransferFeeType                  AS TransferFeeType,
	|	PRESENTATION(DocumentData.TransferFeeType)   AS TypeOfTransferFeeName,
	|	DocumentData.InformationForRegulatoryBodies      AS InformationForRegulatoryBodies,
	|	CASE
	|		WHEN DocumentData.PaymentDocumentType = VALUE(Enum.TypesOfPaymentDocuments.PaymentOrder)
	|			THEN ""01""
	|		WHEN DocumentData.PaymentDocumentType = VALUE(Enum.TypesOfPaymentDocuments.LetterOfCredit)
	|			THEN ""08""
	|		WHEN DocumentData.PaymentDocumentType = VALUE(Enum.TypesOfPaymentDocuments.CollectionOrder_2)
	|			THEN ""06""
	|		WHEN DocumentData.PaymentDocumentType = VALUE(Enum.TypesOfPaymentDocuments.PaymentDemand)
	|			THEN ""02""
	|		ELSE ""00""
	|	END AS PaymentKind_,
	|	
	|	
	|	CASE
	|		WHEN DocumentData.ExportDate = DATETIME(1,1,1)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ToExport,
	|	
	|	CompanyBankAccount.CashCurrency                AS WriteOffCurrency,
	|	CompanyBankAccount.CashCurrency.Description   AS WriteOffCurrencyISOCode,
	|	CompanyBankAccount.CashCurrency.Code            AS CurrencyOfDebitingCode,
	|	DocumentData.DocumentAmount                                 AS DebitingCurrencyAmount,
	|	
	|	CounterpartyBankAccounts.CashCurrency              AS TransferCurrency,
	|	CounterpartyBankAccounts.CashCurrency.Description AS CurrencyOfTranslationISOCode,
	|	CounterpartyBankAccounts.CashCurrency.Code          AS TransferCurrencyCode,
	|	DocumentData.DocumentAmount                                 AS TransferCurrencyAmount,
	
	// Organization and organization account
	
	|	CompanyBankAccount.AccountNumber AS CompanyBankAccount_,
	|	CompanyBankAccount.ThisIsAnIBAN AS OrganizationAndAccountAreIBAN,
	
	|	CASE
	|		WHEN CAST(DocumentData.PayerSName AS STRING(255)) = """" THEN
	|			CASE
	|				WHEN (CAST(CompanyBankAccount.CorrespondentText AS STRING(255))) = """"
	|					THEN DocumentData.Organization.Description
	|				ELSE CompanyBankAccount.CorrespondentText
	|			END
	|	ELSE
	|		DocumentData.PayerSName
	|	END AS CompanyName,
	
	|	CASE
	|		WHEN CAST(DocumentData.PayerSName AS STRING(255)) = """" THEN
	|			CASE
	|				WHEN (CAST(CompanyBankAccount.CorrespondentText AS STRING(255))) = """"
	|					THEN DocumentData.Organization.AbbreviatedDescription
	|				ELSE CompanyBankAccount.CorrespondentText
	|			END
	|	ELSE
	|		DocumentData.PayerSName
	|	END AS OrganizationAbbreviatedName,
	
	|	CASE
	|		WHEN (CAST(CompanyBankAccount.CorrespondentText AS STRING(255))) = """"
	|			THEN DocumentData.Organization.DescriptionInternational
	|		ELSE CompanyBankAccount.CorrespondentText
	|	END AS CompanyNameInternational,
	|	CASE
	|		WHEN DocumentData.TINOfPayer = """" THEN
	|			DocumentData.Organization.TIN
	|		ELSE
	|			DocumentData.TINOfPayer
	|	END AS CompanyTIN,
	
	|	CASE
	|		WHEN DocumentData.PayerCRTR = """" THEN
	|			CASE
	|				WHEN DocumentData.RegistrationWithTaxAuthority IN (
	|					"""",
	|					UNDEFINED)
	|				THEN DocumentData.Organization.CRTR
	|			END
	|	ELSE
	|		DocumentData.PayerCRTR
	|	END AS CompanyCRTR,
	|	OrganizationContactInformation.Presentation AS OrganizationAddressInternational,
	|	OrganizationContactInformation.FieldValues AS OrganizationAddressAndFieldValues,
	|	OrganizationContactInformation.Value AS OrganizationAddressInternationalSignificance,
	|	OrganizationContactInformation.Country AS OrganizationCountryName,
	|	OrganizationContactInformation.State AS OrganizationRegion,
	|	OrganizationContactInformation.City AS OrganizationCity,
	
	|	&OrganizationSBankAccountData,

	// Counterparty and counterparty account
	
	|	CounterpartyBankAccounts.AccountNumber AS CounterpartyBankAccount_,
	|	CounterpartyBankAccounts.ThisIsAnIBAN AS CounterpartyToAccountIsIBAN,
	|
	|	CounterpartyBankAccounts.Owner AS Counterparty,
	|	VALUE(Enum.LegalEntityIndividual.Entity) AS LegalEntityIndividual,
	
	|	CASE
	|		WHEN (CAST(CounterpartyBankAccounts.CorrespondentText AS STRING(255))) = """"
	|			THEN CounterpartyBankAccounts.Owner.Description
	|		ELSE CounterpartyBankAccounts.CorrespondentText
	|	END AS CounterpartyName_,
	
	|	CASE
	|		WHEN (CAST(CounterpartyBankAccounts.CorrespondentText AS STRING(255))) = """"
	|			THEN CounterpartyBankAccounts.Owner.AbbreviatedDescription
	|		ELSE CounterpartyBankAccounts.CorrespondentText
	|	END AS CounterpartyAbbreviatedName,
	
	|	CounterpartyBankAccounts.Owner.DescriptionInternational AS CounterpartyNameInternational,
	|	CounterpartyBankAccounts.Owner.TIN AS CounterpartyTIN,
	|	CounterpartyBankAccounts.Owner.CRTR AS CounterpartyCRTR,
	|	CounterpartyContactInformation.Presentation AS CounterpartyAddressInternational,
	|	CounterpartyContactInformation.FieldValues AS CounterpartyAddressAndFieldValues,
	|	CounterpartyContactInformation.Value AS CounterpartyAddressInternationalValue,
	|	CounterpartyContactInformation.Country AS CounterpartyCountry,
	|	CounterpartyContactInformation.State AS CounterpartyRegion,
	|	CounterpartyContactInformation.City AS CounterpartyCity,
	
	|	&CounterpartySBankAccountData,
	
	|	
	|	"""" AS CommissionAccountNumber,
	|	"""" AS CommissionAccountBIC,
	|	"""" AS NameOfBankCommissionAccount
	|	
	|FROM
	|	Document.BankAccountIssue AS DocumentData
	|	
	|	INNER JOIN PaymentOrders AS PaymentOrders
	|	ON DocumentData.Ref = PaymentOrders.Ref
	|	
	
	|	LEFT JOIN Catalog.Companies.ContactInformation AS OrganizationContactInformation
	|	ON OrganizationContactInformation.Ref = DocumentData.Organization
	|		AND OrganizationContactInformation.Kind = VALUE(Catalog.ContactInformationKinds.InternationalAddressOfCompany)
	|	
	|	LEFT JOIN Catalog.Companies.ContactInformation AS CounterpartyContactInformation
	|	ON CounterpartyContactInformation.Ref = DocumentData.BankAccountBeneficiary.Owner
	|		AND CounterpartyContactInformation.Kind = VALUE(Catalog.ContactInformationKinds.InternationalAddressOfCompany)
	|	
	|	LEFT JOIN Catalog.CompaniesBankAccounts AS CompanyBankAccount
	|	ON CompanyBankAccount.Ref = DocumentData.BankAccount
	|	LEFT JOIN Catalog.BankClassifier AS BanksOfOrganizations
	|	ON CompanyBankAccount.Bank = BanksOfOrganizations.Ref
	|	LEFT JOIN Catalog.WorldCountries AS CountriesOfBankingOrganizations
	|	ON BanksOfOrganizations.CountryCode = CountriesOfBankingOrganizations.Code
	|	LEFT JOIN Catalog.BankClassifier AS BanksForSettlementsOfOrganizations
	|	ON CompanyBankAccount.TransferBank = BanksForSettlementsOfOrganizations.Ref
	|	LEFT JOIN Catalog.WorldCountries AS CountriesOfBanksForSettlementsOfOrganizations
	|	ON BanksForSettlementsOfOrganizations.CountryCode = CountriesOfBanksForSettlementsOfOrganizations.Code
	|	
	|	LEFT JOIN Catalog.CompaniesBankAccounts AS CounterpartyBankAccounts
	|	ON CounterpartyBankAccounts.Ref = DocumentData.BankAccountBeneficiary
	|	LEFT JOIN Catalog.BankClassifier AS CounterpartyBanks
	|	ON CounterpartyBankAccounts.Bank = CounterpartyBanks.Ref
	|	LEFT JOIN Catalog.WorldCountries AS CounterpartyBankCountries
	|	ON CounterpartyBanks.CountryCode = CounterpartyBankCountries.Code
	|	LEFT JOIN Catalog.BankClassifier AS BanksForCounterpartySettlements
	|	ON CounterpartyBankAccounts.TransferBank = BanksForCounterpartySettlements.Ref
	|	LEFT JOIN Catalog.WorldCountries AS BankCountriesForCounterpartySettlements
	|	ON BanksForCounterpartySettlements.CountryCode = BankCountriesForCounterpartySettlements.Code
	|	
	|WHERE
	|	DocumentData.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany),
	|		VALUE(Enum.BusinessTransactions.RefundToAnotherCompany),
	|		VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices)
	|		)
	|";
	
	QueryText = StrReplace(QueryText, "&OrganizationSBankAccountData", TextDetailsOfOrganizationSBankAccount());
	QueryText = StrReplace(QueryText, "&CounterpartySBankAccountData", TextDetailsOfCounterpartySBankAccount());
	
	Return QueryText;
	
EndFunction

Function RequestTextPaymentOrdersTransfers()
	
	QueryText = "
	|
	|SELECT
	|	DocumentData.ExportDate                          AS ExportDate,
	|	DocumentData.Number                                 AS Number,
	|	DocumentData.Date                                  AS Date,
	|	DocumentData.DocumentAmount                        AS Sum,
	|	DocumentData.Currency                                AS Currency,
	|	DocumentData.Currency.Description                   AS ISOCurrencyCode_,
	|	DocumentData.Currency.Code                            AS CurrencyCode_,
	|	DocumentData.PaymentPurposes                     AS PaymentPurposes,
	|	DocumentData.BusinessOperation                 AS Operation,
	|	DocumentData.Organization                           AS Organization,
	|	DocumentData.BankAccount                        AS BankAccount,
	|	DocumentData.BankAccountBeneficiary              AS CounterpartyBankAccount,
	|	DocumentData.Comment                           AS Comment,
	|	DocumentData.PaymentDocumentType                AS DocumentKind,
	|	DocumentData.PaymentKind                            AS PaymentKind,
	|	DocumentData.Ref                                AS Ref,
	|	DocumentData.PaymentID                  AS Code,
	|	DocumentData.KeyOfTransactionWithForeignCurrency                   AS KeyOfTransactionWithForeignCurrency,
	|	DocumentData.EmployeeResponsible                         AS EmployeeResponsible,
	|	DocumentData.EmployeeResponsible.Individual          AS Individual,
	|	DocumentData.TransferFeeType                  AS TransferFeeType,
	|	PRESENTATION(DocumentData.TransferFeeType)   AS TypeOfTransferFeeName,
	|	DocumentData.InformationForRegulatoryBodies      AS InformationForRegulatoryBodies,
	|	CASE
	|		WHEN DocumentData.PaymentDocumentType = VALUE(Enum.TypesOfPaymentDocuments.PaymentOrder)
	|			THEN ""01""
	|		WHEN DocumentData.PaymentDocumentType = VALUE(Enum.TypesOfPaymentDocuments.LetterOfCredit)
	|			THEN ""08""
	|		WHEN DocumentData.PaymentDocumentType = VALUE(Enum.TypesOfPaymentDocuments.CollectionOrder_2)
	|			THEN ""06""
	|		WHEN DocumentData.PaymentDocumentType = VALUE(Enum.TypesOfPaymentDocuments.PaymentDemand)
	|			THEN ""02""
	|		ELSE ""00""
	|	END AS PaymentKind_,
	|	
	|	
	|	CASE
	|		WHEN DocumentData.ExportDate = DATETIME(1,1,1)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ToExport,
	|	
	|	CompanyBankAccount.CashCurrency                AS WriteOffCurrency,
	|	CompanyBankAccount.CashCurrency.Description   AS WriteOffCurrencyISOCode,
	|	CompanyBankAccount.CashCurrency.Code            AS CurrencyOfDebitingCode,
	|	DocumentData.DocumentAmount                                 AS DebitingCurrencyAmount,
	|	
	|	CounterpartyBankAccounts.CashCurrency              AS TransferCurrency,
	|	CounterpartyBankAccounts.CashCurrency.Description AS CurrencyOfTranslationISOCode,
	|	CounterpartyBankAccounts.CashCurrency.Code          AS TransferCurrencyCode,
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CurrencyConversion) THEN
	|			DocumentData.ConversionAmount
	|		ELSE
	|			DocumentData.DocumentAmount
	|	END AS TransferCurrencyAmount,
	
	// Organization and organization account
	
	|	CompanyBankAccount.AccountNumber AS CompanyBankAccount_,
	|	CompanyBankAccount.ThisIsAnIBAN AS OrganizationAndAccountAreIBAN,
	
	|	CASE
	|		WHEN (CAST(CompanyBankAccount.CorrespondentText AS STRING(255))) = """"
	|			THEN DocumentData.Organization.Description
	|		ELSE CompanyBankAccount.CorrespondentText
	|	END AS CompanyName,
	
	|	CASE
	|		WHEN (CAST(CompanyBankAccount.CorrespondentText AS STRING(255))) = """"
	|			THEN DocumentData.Organization.AbbreviatedDescription
	|		ELSE CompanyBankAccount.CorrespondentText
	|	END AS OrganizationAbbreviatedName,
	
	|	CASE
	|		WHEN (CAST(CompanyBankAccount.CorrespondentText AS STRING(255))) = """"
	|			THEN DocumentData.Organization.DescriptionInternational
	|		ELSE CompanyBankAccount.CorrespondentText
	|	END AS CompanyNameInternational,
	|	DocumentData.Organization.TIN AS CompanyTIN,
	|	DocumentData.Organization.CRTR AS CompanyCRTR,
	|	OrganizationContactInformation.Presentation AS OrganizationAddressInternational,
	|	OrganizationContactInformation.FieldValues AS OrganizationAddressAndFieldValues,
	|	OrganizationContactInformation.Value AS OrganizationAddressInternationalSignificance,
	|	OrganizationContactInformation.Country AS OrganizationCountryName,
	|	OrganizationContactInformation.State AS OrganizationRegion,
	|	OrganizationContactInformation.City AS OrganizationCity,
	
	|	&OrganizationSBankAccountData,

	// Counterparty and counterparty account
	
	|	CounterpartyBankAccounts.AccountNumber AS CounterpartyBankAccount_,
	|	CounterpartyBankAccounts.ThisIsAnIBAN AS CounterpartyToAccountIsIBAN,
	|	CounterpartyBankAccounts.Owner AS Counterparty,
	|	VALUE(Enum.LegalEntityIndividual.Entity) AS LegalEntityIndividual,
	
	|	CASE
	|		WHEN CAST(CounterpartyBankAccounts.CorrespondentText AS STRING(255)) = """"
	|			THEN CounterpartyBankAccounts.Owner.Description
	|		ELSE CounterpartyBankAccounts.CorrespondentText
	|	END AS CounterpartyName_,
	
	|	CASE
	|		WHEN (CAST(CounterpartyBankAccounts.CorrespondentText AS STRING(255))) = """"
	|			THEN CounterpartyBankAccounts.Owner.AbbreviatedDescription
	|		ELSE CounterpartyBankAccounts.CorrespondentText
	|	END AS CounterpartyAbbreviatedName,
	
	|	CounterpartyBankAccounts.Owner.DescriptionInternational AS CounterpartyNameInternational,
	|	CounterpartyBankAccounts.Owner.TIN AS CounterpartyTIN,
	|	CounterpartyBankAccounts.Owner.CRTR AS CounterpartyCRTR,
	|	OrganizationContactInformation.Presentation AS CounterpartyAddressInternational,
	|	OrganizationContactInformation.FieldValues AS CounterpartyAddressAndFieldValues,
	|	OrganizationContactInformation.Value AS CounterpartyAddressInternationalValue,
	|	OrganizationContactInformation.Country AS CounterpartyCountry,
	|	OrganizationContactInformation.State AS CounterpartyRegion,
	|	OrganizationContactInformation.City AS CounterpartyCity,
	
	|	&CounterpartySBankAccountData,
	
	|	
	|	"""" AS CommissionAccountNumber,
	|	"""" AS CommissionAccountBIC,
	|	"""" AS NameOfBankCommissionAccount
	|	
	|FROM
	|	Document.BankAccountIssue AS DocumentData
	|	
	|	INNER JOIN PaymentOrders AS PaymentOrders
	|	ON DocumentData.Ref = PaymentOrders.Ref
	|	
	|	
	|	LEFT JOIN Catalog.Companies.ContactInformation AS OrganizationContactInformation
	|	ON OrganizationContactInformation.Ref = DocumentData.Organization
	|		AND OrganizationContactInformation.Kind = VALUE(Catalog.ContactInformationKinds.InternationalAddressOfCompany)
	|	
	|	LEFT JOIN Catalog.CompaniesBankAccounts AS CompanyBankAccount
	|	ON CompanyBankAccount.Ref = DocumentData.BankAccount
	|	LEFT JOIN Catalog.BankClassifier AS BanksOfOrganizations
	|	ON CompanyBankAccount.Bank = BanksOfOrganizations.Ref
	|	LEFT JOIN Catalog.WorldCountries AS CountriesOfBankingOrganizations
	|	ON BanksOfOrganizations.CountryCode = CountriesOfBankingOrganizations.Code
	|	LEFT JOIN Catalog.BankClassifier AS BanksForSettlementsOfOrganizations
	|	ON CompanyBankAccount.TransferBank = BanksForSettlementsOfOrganizations.Ref
	|	LEFT JOIN Catalog.WorldCountries AS CountriesOfBanksForSettlementsOfOrganizations
	|	ON BanksForSettlementsOfOrganizations.CountryCode = CountriesOfBanksForSettlementsOfOrganizations.Code
	|	
	|	LEFT JOIN Catalog.CompaniesBankAccounts AS CounterpartyBankAccounts
	|	ON CounterpartyBankAccounts.Ref = DocumentData.BankAccountBeneficiary
	|	LEFT JOIN Catalog.BankClassifier AS CounterpartyBanks
	|	ON CounterpartyBankAccounts.Bank = CounterpartyBanks.Ref
	|	LEFT JOIN Catalog.WorldCountries AS CounterpartyBankCountries
	|	ON CounterpartyBanks.CountryCode = CounterpartyBankCountries.Code
	|	LEFT JOIN Catalog.BankClassifier AS BanksForCounterpartySettlements
	|	ON CounterpartyBankAccounts.TransferBank = BanksForCounterpartySettlements.Ref
	|	LEFT JOIN Catalog.WorldCountries AS BankCountriesForCounterpartySettlements
	|	ON BanksForCounterpartySettlements.CountryCode = BankCountriesForCounterpartySettlements.Code
	|	
	|WHERE
	|	DocumentData.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.TransferCashToAnotherAccount)
	|	)
	|";
	
	QueryText = StrReplace(QueryText, "&OrganizationSBankAccountData", TextDetailsOfOrganizationSBankAccount());
	QueryText = StrReplace(QueryText, "&CounterpartySBankAccountData", TextDetailsOfCounterpartySBankAccount());
	
	Return QueryText;
	
EndFunction

Function RequestTextPaymentRequirementsThirdParties()
	
	QueryText = "
	|
	|SELECT
	|	DocumentData.ExportDate                          AS ExportDate,
	|	DocumentData.Number                                 AS Number,
	|	DocumentData.Date                                  AS Date,
	|	DocumentData.DocumentAmount                        AS Sum,
	|	DocumentData.Currency                                AS Currency,
	|	DocumentData.Currency.Description                   AS ISOCurrencyCode_,
	|	DocumentData.Currency.Code                            AS CurrencyCode_,
	|	DocumentData.PaymentPurposes                     AS PaymentPurposes,
	|	DocumentData.BusinessOperation                 AS Operation,
	|	DocumentData.Organization                           AS Organization,
	|	DocumentData.BankAccount                        AS BankAccount,
	|	DocumentData.CounterpartyBankAccount             AS CounterpartyBankAccount,
	|	DocumentData.Comment                           AS Comment,
	|	DocumentData.PaymentDocumentType                AS DocumentKind,
	|	""""                                                  AS PaymentKind,
	|	DocumentData.Ref                                AS Ref,
	|	DocumentData.PaymentID                  AS Code,
	|	DocumentData.KeyOfTransactionWithForeignCurrency                   AS KeyOfTransactionWithForeignCurrency,
	|	DocumentData.EmployeeResponsible                         AS EmployeeResponsible,
	|	DocumentData.EmployeeResponsible.Individual          AS Individual,
	|	UNDEFINED                                          AS TransferFeeType,
	|	""""                                                  AS TypeOfTransferFeeName,
	|	""""                                                  AS InformationForRegulatoryBodies,
	|	CASE
	|		WHEN DocumentData.PaymentDocumentType = VALUE(Enum.TypesOfPaymentDocuments.PaymentOrder)
	|			THEN ""01""
	|		WHEN DocumentData.PaymentDocumentType = VALUE(Enum.TypesOfPaymentDocuments.LetterOfCredit)
	|			THEN ""08""
	|		WHEN DocumentData.PaymentDocumentType = VALUE(Enum.TypesOfPaymentDocuments.CollectionOrder_2)
	|			THEN ""06""
	|		WHEN DocumentData.PaymentDocumentType = VALUE(Enum.TypesOfPaymentDocuments.PaymentDemand)
	|			THEN ""02""
	|		ELSE ""00""
	|	END AS PaymentKind_,
	|	
	|	
	|	CASE
	|		WHEN DocumentData.ExportDate = DATETIME(1,1,1)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ToExport,
	|	
	|	CompanyBankAccount.CashCurrency                AS WriteOffCurrency,
	|	CompanyBankAccount.CashCurrency.Description   AS WriteOffCurrencyISOCode,
	|	CompanyBankAccount.CashCurrency.Code            AS CurrencyOfDebitingCode,
	|	DocumentData.DocumentAmount                                 AS DebitingCurrencyAmount,
	|	
	|	CounterpartyBankAccounts.CashCurrency              AS TransferCurrency,
	|	CounterpartyBankAccounts.CashCurrency.Description AS CurrencyOfTranslationISOCode,
	|	CounterpartyBankAccounts.CashCurrency.Code          AS TransferCurrencyCode,
	|	DocumentData.DocumentAmount                                 AS TransferCurrencyAmount,
	
	// Organization and organization account
	
	|	CompanyBankAccount.AccountNumber AS CompanyBankAccount_,
	|	CompanyBankAccount.ThisIsAnIBAN AS OrganizationAndAccountAreIBAN,
	|	CASE
	|		WHEN (CAST(CompanyBankAccount.CorrespondentText AS STRING(255))) = """"
	|			THEN DocumentData.Organization.Description
	|		ELSE CompanyBankAccount.CorrespondentText
	|	END AS CompanyName,
	
	|	CASE
	|		WHEN (CAST(CompanyBankAccount.CorrespondentText AS STRING(255))) = """"
	|			THEN DocumentData.Organization.AbbreviatedDescription
	|		ELSE CompanyBankAccount.CorrespondentText
	|	END AS OrganizationAbbreviatedName,
	
	|	CASE
	|		WHEN (CAST(CompanyBankAccount.CorrespondentText AS STRING(255))) = """"
	|			THEN DocumentData.Organization.DescriptionInternational
	|		ELSE CompanyBankAccount.CorrespondentText
	|	END AS CompanyNameInternational,
	
	|	DocumentData.Organization.TIN AS CompanyTIN,
	|	DocumentData.Organization.CRTR AS CompanyCRTR,
	
	|	OrganizationContactInformation.Presentation AS OrganizationAddressInternational,
	|	OrganizationContactInformation.FieldValues AS OrganizationAddressAndFieldValues,
	|	OrganizationContactInformation.Value AS OrganizationAddressInternationalSignificance,
	|	OrganizationContactInformation.Country AS OrganizationCountryName,
	|	OrganizationContactInformation.State AS OrganizationRegion,
	|	OrganizationContactInformation.City AS OrganizationCity,
	|	
	|	&OrganizationSBankAccountData,
	
	// Counterparty and counterparty account
	
	|	CounterpartyBankAccounts.AccountNumber AS CounterpartyBankAccount_,
	|	CounterpartyBankAccounts.ThisIsAnIBAN AS CounterpartyToAccountIsIBAN,
	|	CASE
	|		WHEN DocumentData.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.CashReturnByAdvanceHolder))
	|		THEN
	|			DocumentData.AdvanceHolder
	|		ELSE
	|			DocumentData.Counterparty
	|	END AS Counterparty,
	
	|	CASE
	|		WHEN DocumentData.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.CashReturnByAdvanceHolder))
	|		THEN
	|			VALUE(Enum.LegalEntityIndividual.Person)
	|		ELSE
	|			DocumentData.Counterparty.LegalEntityIndividual
	|	END AS LegalEntityIndividual,
	
	|	CASE
	|		WHEN DocumentData.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.CashReturnByAdvanceHolder))
	|		THEN
	|			DocumentData.AdvanceHolder.Description
	|		ELSE
	|			DocumentData.Counterparty.Description
	|	END AS CounterpartyName_,
	
	|	CASE
	|		WHEN CAST(CounterpartyBankAccounts.CorrespondentText AS STRING(255)) = """" THEN
	|		CASE
	|			WHEN DocumentData.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.CashReturnByAdvanceHolder))
	|			THEN
	|				DocumentData.AdvanceHolder.Description
	|			ELSE
	|				DocumentData.Counterparty.DescriptionFull
	|			END
	|		ELSE
	|			CounterpartyBankAccounts.CorrespondentText
	|	END AS CounterpartyAbbreviatedName,
	
	|	CASE
	|		WHEN DocumentData.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.CashReturnByAdvanceHolder))
	|		THEN
	|			DocumentData.AdvanceHolder.Description
	|		ELSE
	|			DocumentData.Counterparty.DescriptionInternational
	|	END AS CounterpartyNameInternational,
	
	|	CASE
	|		WHEN CounterpartyBankAccounts.CorrespondentTIN = """" THEN
	|			CASE
	|				WHEN DocumentData.BusinessOperation IN (
	|					VALUE(Enum.BusinessTransactions.CashReturnByAdvanceHolder))
	|				THEN
	|					DocumentData.AdvanceHolder.TIN
	|				ELSE
	|					DocumentData.Counterparty.TIN
	|			END
	|		ELSE
	|			CounterpartyBankAccounts.CorrespondentTIN
	|	END AS CounterpartyTIN,
	
	|	CASE
	|		WHEN CounterpartyBankAccounts.CorrespondentCRTR = """" THEN
	|			DocumentData.Counterparty.CRTR
	|		ELSE
	|			CounterpartyBankAccounts.CorrespondentCRTR
	|	END AS CounterpartyCRTR,
	
	|	CounterpartyContactInformation.Presentation AS CounterpartyAddressInternational,
	|	CounterpartyContactInformation.FieldValues AS CounterpartyAddressAndFieldValues,
	|	CounterpartyContactInformation.Value AS CounterpartyAddressInternationalValue,
	|	CounterpartyContactInformation.Country AS CounterpartyCountry,
	|	CounterpartyContactInformation.State AS CounterpartyRegion,
	|	CounterpartyContactInformation.City AS CounterpartyCity,
	
	|	&CounterpartySBankAccountData,
	
	|	
	|	"""" AS CommissionAccountNumber,
	|	"""" AS CommissionAccountBIC,
	|	"""" AS NameOfBankCommissionAccount
	|	
	|FROM
	|	Document.BankAccountReceiptNote AS DocumentData
	|	
	|	INNER JOIN PaymentRequirements AS PaymentRequirements
	|	ON DocumentData.Ref = PaymentRequirements.Ref
	|	
	|	
	|	LEFT JOIN Catalog.Companies.ContactInformation AS OrganizationContactInformation
	|	ON OrganizationContactInformation.Ref = DocumentData.Organization
	|		AND OrganizationContactInformation.Kind = VALUE(Catalog.ContactInformationKinds.InternationalAddressOfCompany)
	|	
	|	LEFT JOIN Catalog.Counterparties.ContactInformation AS CounterpartyContactInformation
	|	ON CounterpartyContactInformation.Ref = DocumentData.Counterparty
	|		AND CounterpartyContactInformation.Kind = VALUE(Catalog.ContactInformationKinds.InternationalAddressOfCounterparty)
	|	
	|	LEFT JOIN Catalog.CompaniesBankAccounts AS CompanyBankAccount
	|	ON CompanyBankAccount.Ref = DocumentData.BankAccount
	|	LEFT JOIN Catalog.BankClassifier AS BanksOfOrganizations
	|	ON CompanyBankAccount.Bank = BanksOfOrganizations.Ref
	|	LEFT JOIN Catalog.WorldCountries AS CountriesOfBankingOrganizations
	|	ON BanksOfOrganizations.CountryCode = CountriesOfBankingOrganizations.Code
	|	LEFT JOIN Catalog.BankClassifier AS BanksForSettlementsOfOrganizations
	|	ON CompanyBankAccount.TransferBank = BanksForSettlementsOfOrganizations.Ref
	|	LEFT JOIN Catalog.WorldCountries AS CountriesOfBanksForSettlementsOfOrganizations
	|	ON BanksForSettlementsOfOrganizations.CountryCode = CountriesOfBanksForSettlementsOfOrganizations.Code
	|	
	|	LEFT JOIN Catalog.CounterpartyBankAccounts AS CounterpartyBankAccounts
	|	ON CounterpartyBankAccounts.Ref = DocumentData.CounterpartyBankAccount
	|	LEFT JOIN Catalog.BankClassifier AS CounterpartyBanks
	|	ON CounterpartyBankAccounts.Bank = CounterpartyBanks.Ref
	|	LEFT JOIN Catalog.WorldCountries AS CounterpartyBankCountries
	|	ON CounterpartyBanks.CountryCode = CounterpartyBankCountries.Code
	|	LEFT JOIN Catalog.BankClassifier AS BanksForCounterpartySettlements
	|	ON CounterpartyBankAccounts.TransferBank = BanksForCounterpartySettlements.Ref
	|	LEFT JOIN Catalog.WorldCountries AS BankCountriesForCounterpartySettlements
	|	ON BanksForCounterpartySettlements.CountryCode = BankCountriesForCounterpartySettlements.Code
	|	
	|WHERE
	|	DocumentData.BusinessOperation NOT IN (
	|		VALUE(Enum.BusinessTransactions.CashReceiptFromOtherCompany),
	|		VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany),
	|		VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices),
	|		VALUE(Enum.BusinessTransactions.CurrencyConversion)
	|		)
	|";
	
	QueryText = StrReplace(QueryText, "&OrganizationSBankAccountData", TextDetailsOfOrganizationSBankAccount());
	QueryText = StrReplace(QueryText, "&CounterpartySBankAccountData", TextDetailsOfCounterpartySBankAccount());
	QueryText = StrReplace(QueryText, "DocumentData.AdvanceHolder.Description", "DocumentData.AdvanceHolder.LASTFIRSTNAME");
	Return QueryText;
	
EndFunction

Function RequestTextPaymentRequirementsInternal()
	
	QueryText = "
	|
	|SELECT
	|	DocumentData.ExportDate                          AS ExportDate,
	|	DocumentData.Number                                 AS Number,
	|	DocumentData.Date                                  AS Date,
	|	DocumentData.DocumentAmount                        AS Sum,
	|	DocumentData.Currency                                AS Currency,
	|	DocumentData.Currency.Description                   AS ISOCurrencyCode_,
	|	DocumentData.Currency.Code                            AS CurrencyCode_,
	|	DocumentData.PaymentPurposes                     AS PaymentPurposes,
	|	DocumentData.BusinessOperation                 AS Operation,
	|	DocumentData.Organization                           AS Organization,
	|	DocumentData.BankAccount                        AS BankAccount,
	|	DocumentData.SenderBankAccount             AS CounterpartyBankAccount,
	|	DocumentData.Comment                           AS Comment,
	|	DocumentData.PaymentDocumentType                AS DocumentKind,
	|	""""                                                  AS PaymentKind,
	|	DocumentData.Ref                                AS Ref,
	|	DocumentData.PaymentID                  AS Code,
	|	DocumentData.KeyOfTransactionWithForeignCurrency                   AS KeyOfTransactionWithForeignCurrency,
	|	DocumentData.EmployeeResponsible                         AS EmployeeResponsible,
	|	DocumentData.EmployeeResponsible.Individual          AS Individual,
	|	UNDEFINED                                          AS TransferFeeType,
	|	""""                                                  AS TypeOfTransferFeeName,
	|	""""                                                  AS InformationForRegulatoryBodies,
	|	CASE
	|		WHEN DocumentData.PaymentDocumentType = VALUE(Enum.TypesOfPaymentDocuments.PaymentOrder)
	|			THEN ""01""
	|		WHEN DocumentData.PaymentDocumentType = VALUE(Enum.TypesOfPaymentDocuments.LetterOfCredit)
	|			THEN ""08""
	|		WHEN DocumentData.PaymentDocumentType = VALUE(Enum.TypesOfPaymentDocuments.CollectionOrder_2)
	|			THEN ""06""
	|		WHEN DocumentData.PaymentDocumentType = VALUE(Enum.TypesOfPaymentDocuments.PaymentDemand)
	|			THEN ""02""
	|		ELSE ""00""
	|	END AS PaymentKind_,
	|	
	|	
	|	CASE
	|		WHEN DocumentData.ExportDate = DATETIME(1,1,1)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ToExport,
	|	
	|	CompanyBankAccount.CashCurrency                AS WriteOffCurrency,
	|	CompanyBankAccount.CashCurrency.Description   AS WriteOffCurrencyISOCode,
	|	CompanyBankAccount.CashCurrency.Code            AS CurrencyOfDebitingCode,
	|	DocumentData.DocumentAmount                                 AS DebitingCurrencyAmount,
	|	
	|	CounterpartyBankAccounts.CashCurrency              AS TransferCurrency,
	|	CounterpartyBankAccounts.CashCurrency.Description AS CurrencyOfTranslationISOCode,
	|	CounterpartyBankAccounts.CashCurrency.Code          AS TransferCurrencyCode,
	|	DocumentData.DocumentAmount                                 AS TransferCurrencyAmount,
	
	// Organization and organization account
	
	|	CompanyBankAccount.AccountNumber AS CompanyBankAccount_,
	|	CompanyBankAccount.ThisIsAnIBAN AS OrganizationAndAccountAreIBAN,
	|	CASE
	|		WHEN (CAST(CompanyBankAccount.CorrespondentText AS STRING(255))) = """"
	|			THEN DocumentData.Organization.Description
	|		ELSE CompanyBankAccount.CorrespondentText
	|	END AS CompanyName,
	
	|	CASE
	|		WHEN (CAST(CompanyBankAccount.CorrespondentText AS STRING(255))) = """"
	|			THEN DocumentData.Organization.AbbreviatedDescription
	|		ELSE CompanyBankAccount.CorrespondentText
	|	END AS OrganizationAbbreviatedName,
	
	|	CASE
	|		WHEN (CAST(CompanyBankAccount.CorrespondentText AS STRING(255))) = """"
	|			THEN DocumentData.Organization.DescriptionInternational
	|		ELSE CompanyBankAccount.CorrespondentText
	|	END AS CompanyNameInternational,
	
	|	DocumentData.Organization.TIN AS CompanyTIN,
	|	DocumentData.Organization.CRTR AS CompanyCRTR,
	
	|	OrganizationContactInformation.Presentation AS OrganizationAddressInternational,
	|	OrganizationContactInformation.FieldValues AS OrganizationAddressAndFieldValues,
	|	OrganizationContactInformation.Value AS OrganizationAddressInternationalSignificance,
	|	OrganizationContactInformation.Country AS OrganizationCountryName,
	|	OrganizationContactInformation.State AS OrganizationRegion,
	|	OrganizationContactInformation.City AS OrganizationCity,
	
	|	&OrganizationSBankAccountData,
	
	// Counterparty and counterparty account
	
	|	CounterpartyBankAccounts.AccountNumber AS CounterpartyBankAccount_,
	|	CounterpartyBankAccounts.ThisIsAnIBAN AS CounterpartyToAccountIsIBAN,	
	|	CounterpartyBankAccounts.Owner AS Counterparty,
	|	VALUE(Enum.LegalEntityIndividual.Entity) AS LegalEntityIndividual,
	
	|	CASE
	|		WHEN (CAST(CounterpartyBankAccounts.CorrespondentText AS STRING(255))) = """"
	|			THEN CounterpartyBankAccounts.Owner.Description
	|		ELSE CounterpartyBankAccounts.CorrespondentText
	|	END AS CounterpartyName_,
	
	|	CASE
	|		WHEN (CAST(CounterpartyBankAccounts.CorrespondentText AS STRING(255))) = """"
	|			THEN CounterpartyBankAccounts.Owner.AbbreviatedDescription
	|		ELSE CounterpartyBankAccounts.CorrespondentText
	|	END AS CounterpartyAbbreviatedName,
	
	|	CounterpartyBankAccounts.Owner.DescriptionInternational AS CounterpartyNameInternational,

	|	CounterpartyBankAccounts.Owner.TIN AS CounterpartyTIN,
	|	CounterpartyBankAccounts.Owner.CRTR AS CounterpartyCRTR,
	
	|	CounterpartyContactInformation.Presentation AS CounterpartyAddressInternational,
	|	CounterpartyContactInformation.FieldValues AS CounterpartyAddressAndFieldValues,
	|	CounterpartyContactInformation.Value AS CounterpartyAddressInternationalValue,
	|	CounterpartyContactInformation.Country AS CounterpartyCountry,
	|	CounterpartyContactInformation.State AS CounterpartyRegion,
	|	CounterpartyContactInformation.City AS CounterpartyCity,
	
	|	&CounterpartySBankAccountData,
	
	|	
	|	"""" AS CommissionAccountNumber,
	|	"""" AS CommissionAccountBIC,
	|	"""" AS NameOfBankCommissionAccount
	|	
	|FROM
	|	Document.BankAccountReceiptNote AS DocumentData
	|	
	|	INNER JOIN PaymentRequirements AS PaymentRequirements
	|	ON DocumentData.Ref = PaymentRequirements.Ref
	|	
	|	
	|	LEFT JOIN Catalog.Companies.ContactInformation AS OrganizationContactInformation
	|	ON OrganizationContactInformation.Ref = DocumentData.Organization
	|		AND OrganizationContactInformation.Kind = VALUE(Catalog.ContactInformationKinds.InternationalAddressOfCompany)
	|	
	|	LEFT JOIN Catalog.Companies.ContactInformation AS CounterpartyContactInformation
	|	ON CounterpartyContactInformation.Ref = DocumentData.SenderBankAccount.Owner
	|		AND CounterpartyContactInformation.Kind = VALUE(Catalog.ContactInformationKinds.InternationalAddressOfCompany)
	|	
	|	LEFT JOIN Catalog.CompaniesBankAccounts AS CompanyBankAccount
	|	ON CompanyBankAccount.Ref = DocumentData.BankAccount
	|	LEFT JOIN Catalog.BankClassifier AS BanksOfOrganizations
	|	ON CompanyBankAccount.Bank = BanksOfOrganizations.Ref
	|	LEFT JOIN Catalog.WorldCountries AS CountriesOfBankingOrganizations
	|	ON BanksOfOrganizations.CountryCode = CountriesOfBankingOrganizations.Code
	|	LEFT JOIN Catalog.BankClassifier AS BanksForSettlementsOfOrganizations
	|	ON CompanyBankAccount.TransferBank = BanksForSettlementsOfOrganizations.Ref
	|	LEFT JOIN Catalog.WorldCountries AS CountriesOfBanksForSettlementsOfOrganizations
	|	ON BanksForSettlementsOfOrganizations.CountryCode = CountriesOfBanksForSettlementsOfOrganizations.Code
	|	
	|	LEFT JOIN Catalog.CompaniesBankAccounts AS CounterpartyBankAccounts
	|	ON CounterpartyBankAccounts.Ref = DocumentData.SenderBankAccount
	|	LEFT JOIN Catalog.BankClassifier AS CounterpartyBanks
	|	ON CounterpartyBankAccounts.Bank = CounterpartyBanks.Ref
	|	LEFT JOIN Catalog.WorldCountries AS CounterpartyBankCountries
	|	ON CounterpartyBanks.CountryCode = CounterpartyBankCountries.Code
	|	LEFT JOIN Catalog.BankClassifier AS BanksForCounterpartySettlements
	|	ON CounterpartyBankAccounts.TransferBank = BanksForCounterpartySettlements.Ref
	|	LEFT JOIN Catalog.WorldCountries AS BankCountriesForCounterpartySettlements
	|	ON BanksForCounterpartySettlements.CountryCode = BankCountriesForCounterpartySettlements.Code
	|	
	|WHERE
	|	DocumentData.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.CashReceiptFromOtherCompany),
	|		VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany),
	|		VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices)
	|		)
	|";
	
	QueryText = StrReplace(QueryText, "&OrganizationSBankAccountData", TextDetailsOfOrganizationSBankAccount());
	QueryText = StrReplace(QueryText, "&CounterpartySBankAccountData", TextDetailsOfCounterpartySBankAccount());
	
	Return QueryText;
	
EndFunction

Function TextDetailsOfOrganizationSBankAccount()
	
	Return "
	|	CASE WHEN CompanyBankAccount.ManualBankDetailsChange THEN CompanyBankAccount.BankDescription
	|		ELSE CompanyBankAccount.Bank.Description END AS CompanyBank,
	|	ISNULL(CompanyBankAccount.Bank.CashSettlementCenterBIC.Description, """") AS CompanyBankNameCSC,
	|	CompanyBankAccount.BankNameInt AS CompanyBankInternational,
	|	CASE WHEN CompanyBankAccount.ManualBankDetailsChange THEN CompanyBankAccount.BankCity
	|		ELSE CompanyBankAccount.Bank.City END AS CompanyCityOfBank,
	|	CASE WHEN CompanyBankAccount.ManualBankDetailsChange THEN CompanyBankAccount.BankCityInt
	|		ELSE CompanyBankAccount.Bank.CityInternationalFormat END AS OrganizationCityBankInternational,
	|	CASE WHEN CompanyBankAccount.ManualBankDetailsChange THEN CompanyBankAccount.BankBIC
	|		ELSE CompanyBankAccount.Bank.Code END AS CompanyBankBIC,
	|	CASE WHEN CompanyBankAccount.ManualBankDetailsChange THEN CompanyBankAccount.BankSWIFTCode
	|		ELSE CompanyBankAccount.Bank.SWIFTBIC END AS SwiftBankCompany,
	|	CASE WHEN CompanyBankAccount.ManualBankDetailsChange THEN CompanyBankAccount.BankCorrAccount
	|		ELSE CompanyBankAccount.Bank.CorrAccount END AS OrganizationCorrespondentBankAccount,
	|	CompanyBankAccount.BankAccountForPayments AS OrganizationBankAccountForSettlements,
	|	CASE WHEN CompanyBankAccount.ManualBankDetailsChange THEN CompanyBankAccount.BankAddress
	|		ELSE CompanyBankAccount.Bank.Address END AS OrganizationBankAddress,
	|	CASE WHEN CompanyBankAccount.ManualBankDetailsChange THEN CompanyBankAccount.BankAddressInt
	|		ELSE CompanyBankAccount.Bank.InternationalAddress END AS OrganizationBankAddressInternational,
	|	CASE WHEN CompanyBankAccount.ManualBankDetailsChange THEN CompanyBankAccount.CountryOfBank.Description
	|		ELSE CountriesOfBankingOrganizations.Description END AS OrganizationCountryBank,
	|	CASE WHEN CompanyBankAccount.ManualBankDetailsChange THEN CompanyBankAccount.CountryOfBank.Code
	|		ELSE BanksOfOrganizations.CountryCode END AS OrganizationBankCountryCode,
	|	CASE WHEN CompanyBankAccount.ManualBankDetailsChange THEN CompanyBankAccount.CountryOfBank.CodeAlpha2
	|		ELSE CountriesOfBankingOrganizations.CodeAlpha2 END AS OrganizationBankCountryISOCode,
	|	CASE WHEN CompanyBankAccount.ManualBankDetailsChange THEN CompanyBankAccount.BankPhones
	|		ELSE CompanyBankAccount.Bank.Phones END AS OrganizationPhoneNumbersOfBank,
	|	CompanyBankAccount.ThisIsAnIBAN AS BankAccountOfIBANCompany,
	|	CASE WHEN CompanyBankAccount.TransferBankDetailsManualEdit THEN CompanyBankAccount.TransferBankDescription
	|		ELSE CompanyBankAccount.TransferBank.Description END AS CompanyBankForPayments,
	|	ISNULL(CompanyBankAccount.TransferBank.CashSettlementCenterBIC.Description, """") AS CompanyTransferBankNameCSC,
	|	CompanyBankAccount.BankNameForPaymentsInt AS OrganizationBankForSettlementsInternational,
	|	CASE WHEN CompanyBankAccount.TransferBankDetailsManualEdit THEN CompanyBankAccount.TransferBankCity
	|		ELSE CompanyBankAccount.TransferBank.City END AS OrganizationOfCityBankForSettlements,
	|	CASE WHEN CompanyBankAccount.TransferBankDetailsManualEdit THEN CompanyBankAccount.BankCityForPaymentsInt
	|		ELSE CompanyBankAccount.TransferBank.CityInternationalFormat END AS OrganizationOfCityBankForSettlementsInternational,
	|	CASE WHEN CompanyBankAccount.TransferBankDetailsManualEdit THEN CompanyBankAccount.TransferBankBIC
	|		ELSE CompanyBankAccount.TransferBank.Code END AS OrganizationOfBankSBICForSettlements,
	|	CASE WHEN CompanyBankAccount.TransferBankDetailsManualEdit THEN CompanyBankAccount.BankSWIFTCodeForPayments
	|		ELSE CompanyBankAccount.TransferBank.SWIFTBIC END AS OrganizationOfSwiftBankForSettlements,
	|	CASE WHEN CompanyBankAccount.TransferBankDetailsManualEdit THEN CompanyBankAccount.TransferBankCorrAccount
	|		ELSE CompanyBankAccount.TransferBank.CorrAccount END AS OrganizationCorrBankAccountForSettlements,
	|	CASE WHEN CompanyBankAccount.TransferBankDetailsManualEdit THEN CompanyBankAccount.TransferBankAddress
	|		ELSE CompanyBankAccount.TransferBank.Address END AS OrganizationBankAddressForSettlements,
	|	CASE WHEN CompanyBankAccount.TransferBankDetailsManualEdit THEN CompanyBankAccount.BankAddressForPaymentInt
	|		ELSE CompanyBankAccount.TransferBank.InternationalAddress END AS OrganizationBankAddressForSettlementsInternational,
	|	CASE WHEN CompanyBankAccount.TransferBankDetailsManualEdit THEN CompanyBankAccount.CountryOfBankForPayments.Description
	|		ELSE CountriesOfBanksForSettlementsOfOrganizations.Description END AS OrganizationCountryOfBankForSettlements,
	|	CASE WHEN CompanyBankAccount.TransferBankDetailsManualEdit THEN CompanyBankAccount.CountryOfBankForPayments.Code
	|		ELSE BanksForSettlementsOfOrganizations.CountryCode END AS OrganizationCountryOfBankForSettlementsCode,
	|	CASE WHEN CompanyBankAccount.TransferBankDetailsManualEdit THEN CompanyBankAccount.CountryOfBankForPayments.CodeAlpha2
	|		ELSE CountriesOfBanksForSettlementsOfOrganizations.CodeAlpha2 END AS OrganizationCountryBankForSettlementsISOCode,
	|	CASE WHEN CompanyBankAccount.TransferBankDetailsManualEdit THEN CompanyBankAccount.TransferBankPhones
	|		ELSE CompanyBankAccount.TransferBank.Phones END AS OrganizationOfBankAccountsForSettlements";
	
EndFunction

Function TextDetailsOfCounterpartySBankAccount()
	
	Return "
	|	CASE WHEN CounterpartyBankAccounts.ManualBankDetailsChange THEN CounterpartyBankAccounts.BankDescription
	|		ELSE CounterpartyBankAccounts.Bank.Description END AS CounterpartyBank,
	|	ISNULL(CounterpartyBankAccounts.Bank.CashSettlementCenterBIC.Description, """") AS CounterpartyBankPaymentProcessingCentre,
	|	CounterpartyBankAccounts.BankNameInt AS CounterpartyBankInternational,
	|	CASE WHEN CounterpartyBankAccounts.ManualBankDetailsChange THEN CounterpartyBankAccounts.BankCity
	|		ELSE CounterpartyBankAccounts.Bank.City END AS CityOfCounterpartyBank,
	|	CASE WHEN CounterpartyBankAccounts.ManualBankDetailsChange THEN CounterpartyBankAccounts.BankCityInt
	|		ELSE CounterpartyBankAccounts.Bank.CityInternationalFormat END AS CounterpartyBankCityInternational,
	|	CASE WHEN CounterpartyBankAccounts.ManualBankDetailsChange THEN CounterpartyBankAccounts.BankBIC
	|		ELSE CounterpartyBankAccounts.Bank.Code END AS CounterpartyBankBIC,
	|	CASE WHEN CounterpartyBankAccounts.ManualBankDetailsChange THEN CounterpartyBankAccounts.BankSWIFTCode
	|		ELSE CounterpartyBankAccounts.Bank.SWIFTBIC END AS SwiftBankCounterparty,
	|	CASE WHEN CounterpartyBankAccounts.ManualBankDetailsChange THEN CounterpartyBankAccounts.BankCorrAccount
	|		ELSE CounterpartyBankAccounts.Bank.CorrAccount END AS CounterpartyCorrespondentBankAccount,
	|	CounterpartyBankAccounts.BankAccountForPayments AS CounterpartyBankAccountForSettlements,
	|	CASE WHEN CounterpartyBankAccounts.ManualBankDetailsChange THEN CounterpartyBankAccounts.BankAddress
	|		ELSE CounterpartyBankAccounts.Bank.Address END AS CounterpartyBankAddress,
	|	CASE WHEN CounterpartyBankAccounts.ManualBankDetailsChange THEN CounterpartyBankAccounts.BankAddressInt
	|		ELSE CounterpartyBankAccounts.Bank.InternationalAddress END AS CounterpartyBankAddressInternational,
	|	CASE WHEN CounterpartyBankAccounts.ManualBankDetailsChange THEN CounterpartyBankAccounts.CountryOfBank.Description
	|		ELSE CounterpartyBankCountries.Description END AS CounterpartyBankCountry,
	|	CASE WHEN CounterpartyBankAccounts.ManualBankDetailsChange THEN CounterpartyBankAccounts.CountryOfBank.Code
	|		ELSE CounterpartyBanks.CountryCode END AS CounterpartyBankCountryCode,
	|	CASE WHEN CounterpartyBankAccounts.ManualBankDetailsChange THEN CounterpartyBankAccounts.CountryOfBank.CodeAlpha2
	|		ELSE CounterpartyBankCountries.CodeAlpha2 END AS CounterpartyBankCountryIsocode,
	|	CASE WHEN CounterpartyBankAccounts.ManualBankDetailsChange THEN CounterpartyBankAccounts.BankPhones
	|		ELSE CounterpartyBankAccounts.Bank.Phones END AS CounterpartyPhoneNumbersOfBank,
	|	CounterpartyBankAccounts.ThisIsAnIBAN AS CounterpartySBankAccountIBAN,
	|	CASE WHEN CounterpartyBankAccounts.TransferBankDetailsManualEdit THEN CounterpartyBankAccounts.TransferBankDescription
	|		ELSE CounterpartyBankAccounts.TransferBank.Description END AS CounterpartyBankForPayments,
	|	ISNULL(CounterpartyBankAccounts.TransferBank.CashSettlementCenterBIC.Description, """") AS CounterpartyBankForPaymentsPaymentProcessingCentre,
	|	CounterpartyBankAccounts.BankNameForPaymentsInt AS CounterpartyBankForSettlementsInternational,
	|	CASE WHEN CounterpartyBankAccounts.TransferBankDetailsManualEdit THEN CounterpartyBankAccounts.TransferBankCity
	|		ELSE CounterpartyBankAccounts.TransferBank.City END AS CounterpartyCityBankForSettlements,
	|	CASE WHEN CounterpartyBankAccounts.TransferBankDetailsManualEdit THEN CounterpartyBankAccounts.BankCityForPaymentsInt
	|		ELSE CounterpartyBankAccounts.TransferBank.CityInternationalFormat END AS CounterpartyCityBankForSettlementsInternational,
	|	CASE WHEN CounterpartyBankAccounts.TransferBankDetailsManualEdit THEN CounterpartyBankAccounts.TransferBankBIC
	|		ELSE CounterpartyBankAccounts.TransferBank.Code END AS CounterpartyOfBankSBICForSettlements,
	|	CASE WHEN CounterpartyBankAccounts.TransferBankDetailsManualEdit THEN CounterpartyBankAccounts.BankSWIFTCodeForPayments
	|		ELSE CounterpartyBankAccounts.TransferBank.SWIFTBIC END AS SWIFTBankCounterpartyForSettlements,
	|	CASE WHEN CounterpartyBankAccounts.TransferBankDetailsManualEdit THEN CounterpartyBankAccounts.TransferBankCorrAccount
	|		ELSE CounterpartyBankAccounts.TransferBank.CorrAccount END AS CounterpartyCorrBankAccountForSettlements,
	|	CASE WHEN CounterpartyBankAccounts.TransferBankDetailsManualEdit THEN CounterpartyBankAccounts.TransferBankAddress
	|		ELSE CounterpartyBankAccounts.TransferBank.Address END AS CounterpartyAddressOfBankForSettlements,
	|	CASE WHEN CounterpartyBankAccounts.TransferBankDetailsManualEdit THEN CounterpartyBankAccounts.BankAddressForPaymentInt
	|		ELSE CounterpartyBankAccounts.TransferBank.InternationalAddress END AS CounterpartyBankAddressForSettlementsInternational,
	|	CASE WHEN CounterpartyBankAccounts.TransferBankDetailsManualEdit THEN CounterpartyBankAccounts.CountryOfBankForPayments.Description
	|		ELSE BankCountriesForCounterpartySettlements.Description END AS CounterpartyCountryOfBankForSettlements,
	|	CASE WHEN CounterpartyBankAccounts.TransferBankDetailsManualEdit THEN CounterpartyBankAccounts.CountryOfBankForPayments.Code
	|		ELSE BanksForCounterpartySettlements.CountryCode END AS CounterpartyCountryOfBankForSettlementsCode,
	|	CASE WHEN CounterpartyBankAccounts.TransferBankDetailsManualEdit THEN CounterpartyBankAccounts.CountryOfBankForPayments.CodeAlpha2
	|		ELSE BankCountriesForCounterpartySettlements.CodeAlpha2 END AS CounterpartyBankCountryForSettlementsISOCode,
	|	CASE WHEN CounterpartyBankAccounts.TransferBankDetailsManualEdit THEN CounterpartyBankAccounts.TransferBankPhones
	|		ELSE CounterpartyBankAccounts.TransferBank.Phones END AS CounterpartyPhoneNumbersOfBankForSettlements";
	
EndFunction

Function QueryTextCurrencyConversion()
	
	QueryText = "
	|
	|SELECT
	|	DocumentData.ExportDate                          AS ExportDate,
	|	DocumentData.Number                                 AS Number,
	|	DocumentData.Date                                  AS Date,
	|	DocumentData.DocumentAmount                        AS Sum,
	|	DocumentData.Currency                                AS Currency,
	|	DocumentData.Currency.Description                   AS ISOCurrencyCode_,
	|	DocumentData.Currency.Code                            AS CurrencyCode_,
	|	DocumentData.PaymentPurposes                     AS PaymentPurposes,
	|	DocumentData.BusinessOperation                 AS Operation,
	|	DocumentData.Organization                           AS Organization,
	|	DocumentData.BankAccount                        AS BankAccount,
	|	DocumentData.BankAccountBeneficiary              AS CounterpartyBankAccount,
	|	DocumentData.Comment                           AS Comment,
	|	DocumentData.PaymentDocumentType                AS DocumentKind,
	|	DocumentData.PaymentKind                            AS PaymentKind,
	|	DocumentData.Ref                                AS Ref,
	|	DocumentData.PaymentID                  AS Code,
	|	DocumentData.KeyOfTransactionWithForeignCurrency                   AS KeyOfTransactionWithForeignCurrency,
	|	DocumentData.EmployeeResponsible                         AS EmployeeResponsible,
	|	DocumentData.EmployeeResponsible.Individual          AS Individual,
	|	DocumentData.TransferFeeType                  AS TransferFeeType,
	|	PRESENTATION(DocumentData.TransferFeeType)   AS TypeOfTransferFeeName,
	|	DocumentData.InformationForRegulatoryBodies      AS InformationForRegulatoryBodies,
	|	CASE
	|		WHEN DocumentData.PaymentDocumentType = VALUE(Enum.TypesOfPaymentDocuments.PaymentOrder)
	|			THEN ""01""
	|		WHEN DocumentData.PaymentDocumentType = VALUE(Enum.TypesOfPaymentDocuments.LetterOfCredit)
	|			THEN ""08""
	|		WHEN DocumentData.PaymentDocumentType = VALUE(Enum.TypesOfPaymentDocuments.CollectionOrder_2)
	|			THEN ""06""
	|		WHEN DocumentData.PaymentDocumentType = VALUE(Enum.TypesOfPaymentDocuments.PaymentDemand)
	|			THEN ""02""
	|		ELSE ""00""
	|	END AS PaymentKind_,
	|	
	|	
	|	CASE
	|		WHEN DocumentData.ExportDate = DATETIME(1,1,1)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ToExport,
	|	
	|	CompanyBankAccount.CashCurrency                AS WriteOffCurrency,
	|	CompanyBankAccount.CashCurrency.Description   AS WriteOffCurrencyISOCode,
	|	CompanyBankAccount.CashCurrency.Code            AS CurrencyOfDebitingCode,
	|	DocumentData.DocumentAmount                                 AS DebitingCurrencyAmount,
	|	
	|	CounterpartyBankAccounts.CashCurrency              AS TransferCurrency,
	|	CounterpartyBankAccounts.CashCurrency.Description AS CurrencyOfTranslationISOCode,
	|	CounterpartyBankAccounts.CashCurrency.Code          AS TransferCurrencyCode,
	|	DocumentData.ConversionAmount                               AS TransferCurrencyAmount,
	
	// Organization and organization account
	
	|	CompanyBankAccount.AccountNumber AS CompanyBankAccount_,
	|	CompanyBankAccount.ThisIsAnIBAN AS OrganizationAndAccountAreIBAN,
	|	CASE
	|		WHEN CAST(DocumentData.PayerSName AS STRING(255)) = """" THEN
	|			CASE
	|				WHEN (CAST(CompanyBankAccount.CorrespondentText AS STRING(255))) = """"
	|					THEN DocumentData.Organization.Description
	|				ELSE CompanyBankAccount.CorrespondentText
	|			END
	|	ELSE
	|		DocumentData.PayerSName
	|	END AS CompanyName,
	
	|	CASE
	|		WHEN CAST(DocumentData.PayerSName AS STRING(255)) = """" THEN
	|			CASE
	|				WHEN (CAST(CompanyBankAccount.CorrespondentText AS STRING(255))) = """"
	|					THEN DocumentData.Organization.AbbreviatedDescription
	|				ELSE CompanyBankAccount.CorrespondentText
	|			END
	|	ELSE
	|		DocumentData.PayerSName
	|	END AS OrganizationAbbreviatedName,
	
	|	CASE
	|		WHEN (CAST(CompanyBankAccount.CorrespondentText AS STRING(255))) = """"
	|			THEN DocumentData.Organization.DescriptionInternational
	|		ELSE CompanyBankAccount.CorrespondentText
	|	END AS CompanyNameInternational,
	
	|	CASE
	|		WHEN DocumentData.TINOfPayer = """" THEN
	|			DocumentData.Organization.TIN
	|		ELSE
	|			DocumentData.TINOfPayer
	|	END AS CompanyTIN,
	
	|	CASE
	|		WHEN DocumentData.PayerCRTR = """" THEN
	|			CASE
	|				WHEN DocumentData.RegistrationWithTaxAuthority IN (
	|					"""",
	|					UNDEFINED)
	|				THEN DocumentData.Organization.CRTR
	|			END
	|	ELSE
	|		DocumentData.PayerCRTR
	|	END AS CompanyCRTR,
	
	|	OrganizationContactInformation.Presentation AS OrganizationAddressInternational,
	|	OrganizationContactInformation.FieldValues AS OrganizationAddressAndFieldValues,
	|	OrganizationContactInformation.Value AS OrganizationAddressInternationalSignificance,
	|	OrganizationContactInformation.Country AS OrganizationCountryName,
	|	OrganizationContactInformation.State AS OrganizationRegion,
	|	OrganizationContactInformation.City AS OrganizationCity,
	
	|	&OrganizationSBankAccountData,

	// Counterparty and counterparty account
	
	|	CounterpartyBankAccounts.AccountNumber AS CounterpartyBankAccount_,
	|	CounterpartyBankAccounts.ThisIsAnIBAN AS CounterpartyToAccountIsIBAN,
	|	CounterpartyBankAccounts.Owner AS Counterparty,
	|	VALUE(Enum.LegalEntityIndividual.Entity) AS LegalEntityIndividual,
	
	|	CASE
	|		WHEN (CAST(CounterpartyBankAccounts.CorrespondentText AS STRING(255))) = """"
	|			THEN CounterpartyBankAccounts.Owner.Description
	|		ELSE CounterpartyBankAccounts.CorrespondentText
	|	END AS CounterpartyName_,
	
	|	CASE
	|		WHEN (CAST(CounterpartyBankAccounts.CorrespondentText AS STRING(255))) = """"
	|			THEN CounterpartyBankAccounts.Owner.AbbreviatedDescription
	|		ELSE CounterpartyBankAccounts.CorrespondentText
	|	END AS CounterpartyAbbreviatedName,
	
	|	CounterpartyBankAccounts.Owner.DescriptionInternational AS CounterpartyNameInternational,

	|	CounterpartyBankAccounts.Owner.TIN AS CounterpartyTIN,
	|	CounterpartyBankAccounts.Owner.CRTR AS CounterpartyCRTR,

	
	|	CounterpartyContactInformation.Presentation AS CounterpartyAddressInternational,
	|	CounterpartyContactInformation.FieldValues AS CounterpartyAddressAndFieldValues,
	|	CounterpartyContactInformation.Value AS CounterpartyAddressInternationalValue,
	|	CounterpartyContactInformation.Country AS CounterpartyCountry,
	|	CounterpartyContactInformation.State AS CounterpartyRegion,
	|	CounterpartyContactInformation.City AS CounterpartyCity,
	
	|	&CounterpartySBankAccountData,
	
	
	// Conversion fee
	|	CASE
	|		WHEN DocumentData.ConditionOfConversionTransaction = 1 THEN
	|			DocumentData.BankAccountForFeeWriteOff.AccountNumber
	|		ELSE
	|			CompanyBankAccount.AccountNumber
	|	END AS CommissionAccountNumber,
	|	
	|	CASE
	|		WHEN DocumentData.ConditionOfConversionTransaction = 1 THEN
	|			CASE WHEN DocumentData.BankAccountForFeeWriteOff.ManualBankDetailsChange THEN DocumentData.BankAccountForFeeWriteOff.BankBIC
	|			ELSE DocumentData.BankAccountForFeeWriteOff.Bank.Code END
	|		ELSE
	|			CASE WHEN CompanyBankAccount.ManualBankDetailsChange THEN CompanyBankAccount.BankBIC
	|			ELSE CompanyBankAccount.Bank.Code END
	|	END AS CommissionAccountBIC,
	|	
	|	CASE
	|		WHEN DocumentData.ConditionOfConversionTransaction = 1 THEN
	|			CASE WHEN DocumentData.BankAccountForFeeWriteOff.ManualBankDetailsChange THEN DocumentData.BankAccountForFeeWriteOff.BankDescription
	|			ELSE DocumentData.BankAccountForFeeWriteOff.Bank.Description END
	|		ELSE
	|			CASE WHEN CompanyBankAccount.ManualBankDetailsChange THEN CompanyBankAccount.BankDescription
	|			ELSE CompanyBankAccount.Bank.Description END
	|	END AS NameOfBankCommissionAccount
	|	
	|FROM
	|	Document.BankAccountIssue AS DocumentData
	|	
	|	INNER JOIN PaymentOrders AS PaymentOrders
	|	ON DocumentData.Ref = PaymentOrders.Ref
	|	
	
	|	LEFT JOIN Catalog.Companies.ContactInformation AS OrganizationContactInformation
	|	ON OrganizationContactInformation.Ref = DocumentData.Organization
	|		AND OrganizationContactInformation.Kind = VALUE(Catalog.ContactInformationKinds.InternationalAddressOfCompany)
	|	
	|	LEFT JOIN Catalog.Companies.ContactInformation AS CounterpartyContactInformation
	|	ON CounterpartyContactInformation.Ref = DocumentData.BankAccountBeneficiary.Owner
	|		AND CounterpartyContactInformation.Kind = VALUE(Catalog.ContactInformationKinds.InternationalAddressOfCompany)
	|	
	|	LEFT JOIN Catalog.CompaniesBankAccounts AS CompanyBankAccount
	|	ON CompanyBankAccount.Ref = DocumentData.BankAccount
	|	LEFT JOIN Catalog.BankClassifier AS BanksOfOrganizations
	|	ON CompanyBankAccount.Bank = BanksOfOrganizations.Ref
	|	LEFT JOIN Catalog.WorldCountries AS CountriesOfBankingOrganizations
	|	ON BanksOfOrganizations.CountryCode = CountriesOfBankingOrganizations.Code
	|	LEFT JOIN Catalog.BankClassifier AS BanksForSettlementsOfOrganizations
	|	ON CompanyBankAccount.TransferBank = BanksForSettlementsOfOrganizations.Ref
	|	LEFT JOIN Catalog.WorldCountries AS CountriesOfBanksForSettlementsOfOrganizations
	|	ON BanksForSettlementsOfOrganizations.CountryCode = CountriesOfBanksForSettlementsOfOrganizations.Code
	|	
	|	LEFT JOIN Catalog.CompaniesBankAccounts AS CounterpartyBankAccounts
	|	ON CounterpartyBankAccounts.Ref = DocumentData.BankAccountBeneficiary
	|	LEFT JOIN Catalog.BankClassifier AS CounterpartyBanks
	|	ON CounterpartyBankAccounts.Bank = CounterpartyBanks.Ref
	|	LEFT JOIN Catalog.WorldCountries AS CounterpartyBankCountries
	|	ON CounterpartyBanks.CountryCode = CounterpartyBankCountries.Code
	|	LEFT JOIN Catalog.BankClassifier AS BanksForCounterpartySettlements
	|	ON CounterpartyBankAccounts.TransferBank = BanksForCounterpartySettlements.Ref
	|	LEFT JOIN Catalog.WorldCountries AS BankCountriesForCounterpartySettlements
	|	ON BanksForCounterpartySettlements.CountryCode = BankCountriesForCounterpartySettlements.Code
	|	
	|WHERE
	|	DocumentData.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.CurrencyConversion)
	|		)
	|";
	
	QueryText = StrReplace(QueryText, "&OrganizationSBankAccountData", TextDetailsOfOrganizationSBankAccount());
	QueryText = StrReplace(QueryText, "&CounterpartySBankAccountData", TextDetailsOfCounterpartySBankAccount());
	
	Return QueryText;
	
EndFunction


Function InitializePaymentFields()
	
	Fields = New Structure;
	Fields.Insert("CompanyHiring",                "OrganizationAbbreviatedName");
	Fields.Insert("CounterpartyName",                 "CounterpartyAbbreviatedName");
	
	Fields.Insert("PayerCRTR",                 "CompanyCRTR");

	Fields.Insert("CompanyCityOfBankSC",        "OrganizationOfCityBankForSettlements");
	Fields.Insert("CompanyBankBICProcessingCentre",          "OrganizationOfBankSBICForSettlements");
	Fields.Insert("CompanyAccount",            "OrganizationCorrespondentBankAccount");
	Fields.Insert("CompanyCorrAccountOfBankSC",     "OrganizationCorrBankAccountForSettlements");
	
	Fields.Insert("RecipientCRTR",                  "CounterpartyCRTR");

	Fields.Insert("CityOfBankSC",         "CounterpartyCityBankForSettlements");
	Fields.Insert("CounterpartyBankBICProcessingCentre",           "CounterpartyOfBankSBICForSettlements");
	Fields.Insert("CounterpartyCorrBankAccount",             "CounterpartyCorrespondentBankAccount");
	Fields.Insert("CorrAccountOfBankSC",      "CounterpartyCorrBankAccountForSettlements");
	
	Return Fields;
	
EndFunction

Function FieldsOfDocumentsToUpload()
	
	Fields = New Structure;
	
	Fields.Insert("DateOfTransaction", "ProcessingDate");
	Fields.Insert("DocumentDate", "Date");
	Fields.Insert("DocumentNumber", "Number");
	Fields.Insert("DocumentAmount", "Sum");
	Fields.Insert("Comment", "Comment");
	Fields.Insert("DocumentKind", "Operation");
	Fields.Insert("PaymentPurposes", "PaymentPurposes");
	Fields.Insert("UniquePaymentId", "Code");
	Fields.Insert("IncomeKindCode", "PaymentPurposeCode");
	
	Fields.Insert("Payer_Name", "Payer");
	Fields.Insert("Payer_InternationalName", "PayerInternationalName");
	Fields.Insert("Payer_AddressStructured_Country_ISOCode", "PayerCountry");
	Fields.Insert("Payer_INN", "PayerTIN");
	Fields.Insert("Payer__Account", "PayerAccount");
	
	Fields.Insert("Payer_Bank",               "PayerBank_1");
	Fields.Insert("Payer_Bank_City",         "PayerBank_2");
	Fields.Insert("Payer_Bank_BIK",           "PayerBIC");
	Fields.Insert("Payer_Bank_SWIFT",         "PayerSWIFT");
	Fields.Insert("Payer_Bank_CorrespondentAccount",      "PayerCorAccount");
	Fields.Insert("Payer_Bank_InternationalName", "PayerBank_3");
	Fields.Insert("Payer_Bank_Address",         "PayerBank_4");
	Fields.Insert("Payer_Bank_Country_ISOCode", "PayerBank_5");
	
	Fields.Insert("Recipient_Name", "Recipient");
	Fields.Insert("Recipient_InternationalName", "RecipientInternationalName");
	Fields.Insert("Recipient_AddressStructured_Country_ISOCode", "RecipientCountry");
	Fields.Insert("Recipient_INN", "BeneficiaryTIN");
	Fields.Insert("Recipient_KPP", "BeneficiaryCRTR");
	Fields.Insert("Recipient__Account", "BeneficiaryAccount");
	
	Fields.Insert("Recipient_Bank",               "RecipientBank_1");
	Fields.Insert("Recipient_Bank_City",         "RecipientBank_2");
	Fields.Insert("Recipient_Bank_BIK",           "BeneficiaryBIC");
	Fields.Insert("Recipient_Bank_SWIFT",         "BeneficiarySWIFT");
	Fields.Insert("Recipient_Bank_CorrespondentAccount",      "BeneficiaryCorAccount");
	Fields.Insert("Recipient_Bank_InternationalName", "RecipientBank_3");
	Fields.Insert("Recipient_Bank_Address",         "RecipientBank_4");
	Fields.Insert("Recipient_Bank_Country_ISOCode", "RecipientBank_5");
	
	Fields.Insert("PaymentToBudget_StatusOfOriginator",     "AuthorStatus");
	Fields.Insert("PaymentToBudget_KBKIndicator",         "IndicatorBCC");
	Fields.Insert("PaymentToBudget_OCTMO",                 "RNCPS");
	Fields.Insert("PaymentToBudget_BasisIndicator",   "BasisIndicator");
	Fields.Insert("PaymentToBudget_PeriodIndicator",     "PeriodIndicator");
	Fields.Insert("PaymentToBudget_NumberIndicator",      "NumberIndicator");
	Fields.Insert("PaymentToBudget_DateIndicator",        "DateIndicator");
	Fields.Insert("PaymentToBudget_PayoutCode",             "TypeIndicator");
	
	Return Fields;
	
EndFunction

Function GenerateFillingParameters(CurLineOfBankAcounts)
	
	FillParameters = Common.ValueTableRowToStructure(CurLineOfBankAcounts);
	
	Return FillParameters;
	
EndFunction	 

Procedure CreateDocumentsOnReceivedTransactions(TransactionsTable, FillParameters, ImportParameters)

	DocumentsToImport = PrepareTransactionTable(TransactionsTable, FillParameters);

	BankAccount = FillParameters.BankAccount;
	AccountAttributes = Catalogs.CompaniesBankAccounts.GetCompanySBankAccountDetails(BankAccount);
	
	DocumentsToImport.FillValues(BankAccount, "BankAccount");
	DocumentsToImport.FillValues(True, "ThisIsBankFeedsImport");
	
	EDIWithBanksServer.PrepareStatementLines(DocumentsToImport, BankAccount, AccountAttributes, ImportParameters);
	EDIWithBanksServer.UpdateDocuments(DocumentsToImport, BankAccount, ImportParameters);
	
	EDIWithBanksServer.CreateDocuments(DocumentsToImport, FillParameters.BankAccount, ImportParameters);
		
EndProcedure

Function PrepareTransactionTable(TransactionsTable, ImportParameters)
	
	// Documents
	FieldsOfDocumentsToUpload = FieldsOfDocumentsToUpload();
    DocumentsToUploadTable = DataProcessors.EDIWithBanksBankFeeds.Create().DocumentsToImport.UnloadColumns();
	
	ListOfMatchingCategoriesWhenReceivingCash = 
		BankFeedsDictionaryInternal.ListOfComplianceOfCategoryToBusinessOfOperationUponReceiptOfCash();
	ListOfMatchingCategoriesWhenDebitingCash = 
		BankFeedsDictionaryInternal.ListOfMatchingCategoriesToBusinessOfOperationsWhenWritingOffCash();
	
	LineNumber = 0;
	For Each TableRow In TransactionsTable Do
		
		DocumentTransaction = DocumentsToUploadTable.Add();
		DocumentTransaction[FieldsOfDocumentsToUpload.DocumentDate] = TableRow.CreationDate;
		DocumentTransaction[FieldsOfDocumentsToUpload.DateOfTransaction] = TableRow.CreationDate;
		DocumentTransaction[FieldsOfDocumentsToUpload.PaymentPurposes]  = TableRow.PaymentPurposes;
		DocumentTransaction[FieldsOfDocumentsToUpload.DocumentNumber]  = TableRow.BankNumber;  
		DocumentTransaction[FieldsOfDocumentsToUpload.Comment] = NStr("vi = '#Được kết nhập từ';
																		|ru = '#Загружен из';
																		|en = '#Imported from'; fa = '#Imported from';
																		|it = '#Загружен из';
																		|pl = '#Imported from';
																		|tr = '#Şuradan yüklendi'") + " BankFeeds";
		
		DocumentTransaction["Currency"] = Catalogs.Currencies.FindByDescription(TableRow.Currency);
		DocumentTransaction[FieldsOfDocumentsToUpload.DocumentAmount]   = TableRow.Sum;
		DocumentTransaction[FieldsOfDocumentsToUpload.UniquePaymentId]  = TableRow.TransactionID;

		DocumentTransaction.ToImport = True;       
		DocumentTransaction.CreateCounterparty = True;
		DocumentTransaction.LineNumber = LineNumber;
		LineNumber = LineNumber + 1;
		Outgoing = TableRow.PaymentDirection = "1";
		
		// 1 - written off. 2 - admission
		If Outgoing Then
			DocumentTransaction.DepartureDate = DocumentTransaction.ProcessingDate; 
			
			DocumentTransaction.OperationKind = ListOfMatchingCategoriesWhenDebitingCash[TableRow.category];
			
			If TypeOf(ImportParameters.Bank) = Type("CatalogRef.CompaniesBankAccounts") Then
				
				Bank_Address = ImportParameters.Bank.BankAddressInt;
				Bank_City = ImportParameters.Bank.BankCityInt;
				BankCorrespondentAccount = ImportParameters.Bank.BankAccountForPayments;
				BankInternationalName = ImportParameters.Bank.BankNameInt;
				
			Else
				
				Bank_Address = ImportParameters.Bank.Address;
				Bank_City = ImportParameters.Bank.City;
				BankCorrespondentAccount = ImportParameters.Bank.CorrAccount;
				BankInternationalName = ImportParameters.Bank.InternationalDescription;
				
			EndIf;	
			
			CompanyParameters = Common.ObjectAttributesValues(
				ImportParameters.Organization,"Description,DescriptionInternational");

			// The payer is an company                     
			DocumentTransaction[FieldsOfDocumentsToUpload.Payer_Bank] = BankInternationalName;
			DocumentTransaction[FieldsOfDocumentsToUpload.Payer_Bank_Address] = Bank_Address;
			DocumentTransaction[FieldsOfDocumentsToUpload.Payer_Bank_BIK] = "";
			DocumentTransaction[FieldsOfDocumentsToUpload.Payer_Bank_City] = Bank_City;
			DocumentTransaction[FieldsOfDocumentsToUpload.Payer_Bank_CorrespondentAccount] = BankCorrespondentAccount;
			DocumentTransaction[FieldsOfDocumentsToUpload.Payer_Bank_InternationalName] = BankInternationalName;
			DocumentTransaction[FieldsOfDocumentsToUpload.Payer_Bank_Country_ISOCode] = "";
			DocumentTransaction[FieldsOfDocumentsToUpload.Payer_Name] = CompanyParameters.Description;
			DocumentTransaction[FieldsOfDocumentsToUpload.Payer_InternationalName] = 
				CompanyParameters.DescriptionInternational;
			DocumentTransaction[FieldsOfDocumentsToUpload.Payer__Account] = ImportParameters.AccountNumber;   
			
			// iban to whom the payment was sent
			If TableRow.extra.Property("payee") Then
				DocumentTransaction[FieldsOfDocumentsToUpload.Recipient__Account] = TableRow.extra.payee; 
			EndIf;	
			
			If TableRow.extra.Property("posting_date") Then
				DocumentTransaction.DepartureDate = TableRow.extra.posting_date;
			EndIf;	
			
			// name to whom the payment was sent
			If TableRow.extra.Property("payee_information") Then
				DocumentTransaction[FieldsOfDocumentsToUpload.Recipient_Name] = TableRow.extra.payee_information; 
				DocumentTransaction[FieldsOfDocumentsToUpload.Recipient_InternationalName] = TableRow.extra.payee_information;
			EndIf;	
			
			If TableRow.ThereIsMerchant Then
				
				DocumentTransaction[FieldsOfDocumentsToUpload.Recipient_Name] = TableRow.NameMerchant; 
				DocumentTransaction[FieldsOfDocumentsToUpload.Recipient_InternationalName] = TableRow.NameMerchant;
				
			EndIf;	
			
			If Not ValueIsFilled(DocumentTransaction[FieldsOfDocumentsToUpload.Recipient_Name]) Then
				DocumentTransaction.CreateCounterparty = False;
			EndIf;	
			
			ReceivedLink = Documents.BankAccountIssue.EmptyRef();

			// If there is a UID, we are trying to get a link using the UID			
			Try
				
				UIDIsAbbreviated = TableRow.end_to_end_id;
				
				If ValueIsFilled(UIDIsAbbreviated)
					And StrLen(UIDIsAbbreviated) = 32 Then
					
					 Id = ExchangeWithBankFeedsServer.AssembleUIDFor1C(UIDIsAbbreviated);
					 
					 ReceivedLink = Documents.BankAccountIssue.GetRef(Id);
					
				EndIf;	
				
			Except
				
				LREvent =NStr("vi = 'Xác định ID chứng từ';
								|ru = 'Определение идентификатора документа';
								|en = 'Define document ID'; fa = 'Define document ID';
								|it = 'Определение идентификатора документа';
								|pl = 'Define document ID';
								|tr = 'Belge kimliğinin tanımlanması'") + "BankFeeds"; 
			
				WriteLogEvent(
				LREvent,
				,,,
				ErrorInfo());
				
			EndTry;
			
			If ValueIsFilled(ReceivedLink) Then

				DocumentTransaction.DocumentIsFoundInBase = True;
				DocumentTransaction.Document = ReceivedLink; 
				
			EndIf;	
			
		// Inpayment
		Else
			DocumentTransaction.ArrivalDate_ = DocumentTransaction.ProcessingDate;  
			
			DocumentTransaction.OperationKind = ListOfMatchingCategoriesWhenReceivingCash[TableRow.category];
			
			If TypeOf(ImportParameters.Bank) = Type("CatalogRef.CompaniesBankAccounts") Then
				
				Bank_Address = ImportParameters.Bank.BankAddressInt;
				Bank_City = ImportParameters.Bank.BankCityInt;
				BankCorrespondentAccount = ImportParameters.Bank.BankAccountForPayments;
				BankInternationalName = ImportParameters.Bank.BankNameInt;
				
			Else
				
				Bank_Address = ImportParameters.Bank.Address;
				Bank_City = ImportParameters.Bank.City;
				BankCorrespondentAccount = ImportParameters.Bank.CorrAccount;
				BankInternationalName = ImportParameters.Bank.InternationalDescription;
				
			EndIf;	
			
			// The recipient is an company
			DocumentTransaction[FieldsOfDocumentsToUpload.Recipient_Bank_Address]  = Bank_Address;
			DocumentTransaction[FieldsOfDocumentsToUpload.Recipient_Bank_BIK] = "";
			DocumentTransaction[FieldsOfDocumentsToUpload.Recipient_Bank_City]  = Bank_City;
			DocumentTransaction[FieldsOfDocumentsToUpload.Recipient_Bank_CorrespondentAccount] = BankCorrespondentAccount;
			DocumentTransaction[FieldsOfDocumentsToUpload.Recipient_Bank_InternationalName] = 
				BankInternationalName;
				
			CompanyDetails = Common.ObjectAttributesValues(ImportParameters.Organization, 
																		"Description, DescriptionInternational");	
			DocumentTransaction[FieldsOfDocumentsToUpload.Recipient_Name]   = CompanyDetails.Description;
			DocumentTransaction[FieldsOfDocumentsToUpload.Recipient_InternationalName]  = 
				CompanyDetails.DescriptionInternational;
			DocumentTransaction[FieldsOfDocumentsToUpload.Recipient__Account] = ImportParameters.AccountNumber;
			
			// iban from whom the payment was received
			If TableRow.extra.Property("payer") Then
				DocumentTransaction[FieldsOfDocumentsToUpload.Payer__Account] = TableRow.extra.payer; 
			EndIf;
			
			If TableRow.extra.Property("posting_date") Then
				DocumentTransaction.ArrivalDate_ = TableRow.extra.posting_date;
			EndIf;	
			
			// name from whom the payment was received
			If TableRow.extra.Property("payer_information") Then
				DocumentTransaction[FieldsOfDocumentsToUpload.Payer_Name] = TableRow.extra.payer_information; 
				DocumentTransaction[FieldsOfDocumentsToUpload.Payer_InternationalName] = TableRow.extra.payer_information;
				DocumentTransaction.Payer = TableRow.extra.payer_information;
			EndIf;	
			
			If Not ValueIsFilled(DocumentTransaction[FieldsOfDocumentsToUpload.Payer_Name]) Then
				DocumentTransaction.CreateCounterparty = False;
			EndIf;	
			
		EndIf;
	EndDo;
	
	Return DocumentsToUploadTable;
	
EndFunction 	

#EndRegion

#EndIf
