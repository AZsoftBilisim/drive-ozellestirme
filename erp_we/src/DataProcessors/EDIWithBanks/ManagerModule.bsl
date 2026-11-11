#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Retrieves extract data from a file.
// 
// Parameters:
//  BinaryData - BinaryData - binary data of the statement file
//  ExchangeFormat - EnumRef.ExchangeFormatWithBank - file format
//  Encoding - String - exchange file format
// 
// Returns:
//  Structure - extract data from the file:
// * Title - Structure - contains fields:
// ** Sender - String - bank name
// ** CreationDate - Date - date of statement creation
// ** StartDate - Date - start date of the statement period
// ** EndDate - Date - date of the end of the statement period
// * SettlementAccounts - Array of String - list of accounts for which the statement contains data
// * StatementDocuments - Array of Structure - operation data:
// ** Structure - See CashClientServer.DocumentLineTags
// * ParsingErrors - Array of String - errors detected when reading the statement
// * AccountList - Array of String - a list of accounts for which the statement contains data.
Function ReadExtractDataFromFile(BinaryData, ExchangeFormat, Encoding) Export
	
	StatementData = New Structure;
	StatementData.Insert("Title", CashServer.StatementTitle());
	StatementData.Insert("SettlementAccounts", New Array);
	StatementData.Insert("StatementDocuments", New Array);
	StatementData.Insert("ParsingErrors", New Array);
	
	If ExchangeFormat = Enums.ExchangeFormatWithBank.ISO20022 Then
		ReadISO20022StatementData(BinaryData, StatementData);
	ElsIf ExchangeFormat = Enums.ExchangeFormatWithBank.MT940 Then
		ReadMT940StatementData(BinaryData, StatementData, Encoding);
	Else
		EDIWithBanksLocalization.ReadExtractFromFile(BinaryData, ExchangeFormat, StatementData);
	EndIf;
		
	StatementData.Title.Insert("CreationTime", "");
	StatementData.Insert("AccountList", New Array);
	StatementDocuments = New Array;
	For Each Item In StatementData.SettlementAccounts Do
		StatementData.AccountList.Add(Item.CreateAccount_1);
	EndDo;
	StatementData.SettlementAccounts = CommonClientServer.CollapseArray(StatementData.SettlementAccounts);
	For Each Item In StatementData.StatementDocuments Do
		OperationData = CashClientServer.DocumentLineTags();
		FillPropertyValues(OperationData, Item);
		OperationData.Insert("ProcessingDate", Item.DateOfTransaction);
		If Item.PaymentDirection = "1" Then
			OperationData.Insert("WrittenOff", Item.DateOfTransaction);
			OperationData.DepartureDate = Format(Item.DateOfTransaction, "DLF=D;");
		Else
			OperationData.Insert("Received", Item.DateOfTransaction);
			OperationData.ArrivalDate_ = Format(Item.DateOfTransaction, "DLF=D;");
		EndIf;
		OperationData.PayerSWIFT = Item.PayerSWIFTBank;
		OperationData.PayerBank_1 = Item.PayerBank_;
		OperationData.BeneficiarySWIFT = Item.RecipientSWIFTBank;
		OperationData.RecipientBank_1 = Item.RecipientBank_;
		If ValueIsFilled(Item.Date) Then
			OperationData.Insert("DocDate", Item.Date);
			OperationData.Date = Format(Item.Date, "DLF=D;");
		EndIf;
		StatementDocuments.Add(OperationData);
	EndDo;
	StatementData.StatementDocuments = StatementDocuments;
	Return StatementData;
	
EndFunction

// Generates a table of Bank accounts with exchange settings
//
// Parameters:
//  Filter - Structure, Undefined - An additional selection.
//  Load - Boolean - Indicates whether invoices are being prepared for uploading or uploading payments.
// 
// Returns:
//  ValueTable - table of bank accounts.
//
Function TableOfAccounts(Filter, Load = False) Export
	
	Query = New Query;
	Query.Text = QueryTextSettingsOfAccounts();
	Query.SetParameter("Load", Load);
	
	If Filter <> Undefined Then
		
		DynamicFilters = New Array;
		
		For Each FilterElement In Filter Do
			
			If TypeOf(FilterElement.Value) = Type("String") Then
				
				DynamicFilters.Add(StrTemplate("AND BankAccounts.%1 LIKE &Filter%1", FilterElement.Key));
				Query.SetParameter(StrTemplate("Filter%1", FilterElement.Key), "%" + FilterElement.Value + "%");
				
			Else
				
				DynamicFilters.Add(StrTemplate("AND BankAccounts.%1 = &Filter%1", FilterElement.Key));
				Query.SetParameter(StrTemplate("Filter%1", FilterElement.Key), FilterElement.Value);
				
			EndIf;
			
		EndDo;
		
		Query.Text = StrReplace(Query.Text, "AND &AdditionalSelection", StrConcat(DynamicFilters, Chars.LF));
		
	Else
		Query.Text = StrReplace(Query.Text, "AND &AdditionalSelection", "");
	EndIf;
	
	TableOfAccounts = Query.Execute().Unload();
	
	Return TableOfAccounts;
	
EndFunction

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
	Query.SetParameter("RFPaymentsSupport", GetFunctionalOption("RFPaymentsSupport"));
	
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

// Uploads payments to a file
//
// Parameters:
//    ExportingParameters - Structure - Payment upload parameters
//    StorageAddress - UUID - address of the temporary storage where the upload data will be placed.
//
Procedure Unload(ExportingParameters, StorageAddress) Export
	
	If ExportingParameters.ExchangeFormat = Enums.ExchangeFormatWithBank.ISO20022 Then
		UnloadPaymentsInISO20022(ExportingParameters, StorageAddress);
	ElsIf ExportingParameters.ExchangeFormat = Enums.ExchangeFormatWithBank.ClientBankExchange1c Then
		UploadPaymentsTo1CClientBankExchange(ExportingParameters, StorageAddress);
	ElsIf ExportingParameters.ExchangeFormat = Enums.ExchangeFormatWithBank.MT940 Then
		UnloadPaymentsVMT940(ExportingParameters, StorageAddress);
	ElsIf ValueIsFilled(ExportingParameters.ExchangeFormat) Then
		FileBinaryData = Undefined;
		EDIWithBanksLocalization.UploadDocumentsToFile(
			ExportingParameters.DocumentsTable, ExportingParameters.ExchangeFormat, FileBinaryData);
		PutToTempStorage(FileBinaryData, StorageAddress);
	Else
		MessageTemplate = NStr("vi = 'Trong tài khoản ngân hàng %1 chưa chỉ ra định dạng trao đổi để kết xuất dữ liệu.';
								|ru = 'В банковском счете %1 не указан формат обмена для выгрузки данных.';
								|en = 'The exchange format for data export is not specified in the bank account %1.'; fa = 'The exchange format for data export is not specified in the bank account %1.';
								|it = 'В банковском счете %1 не указан формат обмена для выгрузки данных.';
								|pl = 'W rachunku bankowym %1 nie podano formatu wymiany do załadowania danych.';
								|tr = '%1 banka hesabı, veri yüklemek için bir değişim formatı belirtilmedi.'");
		MessageText = StrTemplate(MessageTemplate, ExportingParameters.BankAccount);
		Common.MessageToUser(MessageText, ExportingParameters.BankAccount);
	EndIf;
	
EndProcedure

// Uploads payments to the database
//
// Parameters:
//    ImportParameters - Structure - Parameters for uploading payments.
//    StorageAddress - String - The address where the table with uploaded documents will be placed
//
Procedure Load(ImportParameters, StorageAddress) Export
	
		If ImportParameters.ExchangeFormat = Enums.ExchangeFormatWithBank.ClientBankExchange1c Then
			
			PerformanceMeasurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement("DataProcessor.EDIWithBanks.ManagerModule.Load");
				StatementData = CashClientServer.Parse1CClientBankExchangeStatementFile(
					ImportParameters.StatementLines);
			
		Else
			
			PerformanceMeasurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement("DataProcessor.EDIWithBanks.ManagerModule.Load");
			StatementData = DataProcessors.EDIWithBanks.ReadExtractDataFromFile(
				ImportParameters.StatementLines, ImportParameters.ExchangeFormat, ImportParameters.Encoding);
			
		EndIf;
	
	If StatementData <> Undefined
		And (CashClientServer.ThereIsInvoiceInStatementFile(ImportParameters.BankAccount, StatementData)
		Or ImportParameters.DirectExchange) Then
		
		BankAccount = ImportParameters.BankAccount;
		AccountAttributes = Catalogs.CompaniesBankAccounts.GetCompanySBankAccountDetails(BankAccount);
		Currency = AccountAttributes.Currency;
		AccountNumber = TrimAll(AccountAttributes.AccountNumber);
		
		InformationRegisters.LastEDIWithBanks.CreateEntry(
			BankAccount, New Structure("ImportStartDate, ImportEndDate",
				ImportParameters.ImportStartDate, ImportParameters.ImportEndDate));
				
		RecordAccountBalancesBasedOnStatementData(
			BankAccount, AccountAttributes, StatementData, ImportParameters.ImportStartDate, ImportParameters.ImportEndDate);
		
		StatementDocuments = StatementData.StatementDocuments;
		DocumentsToImport = ImportParameters.DocumentsToImport;
		
		If Not StatementDocuments.Count() Then
			PerformanceMonitor.EndTimeConsumingOperationMeasurement(PerformanceMeasurement, 0);
			Return;
		EndIf;
		
		LineNumber = 0;
		For Each DocumentExtracts In StatementDocuments Do
			
			DocumentData = FindSplitPayment(DocumentsToImport, DocumentExtracts);
		
			If DocumentData <> Undefined Then
				
				DocumentData.StatementData = StrTemplate("%1
					|%2", DocumentData.StatementData, DocumentExtracts.StatementData);
				DocumentData.Sum = StrTemplate("%1 + %2", DocumentData.Sum, DocumentExtracts.Sum);
				Continue;
				
			EndIf;
			
			DocumentToDownload = DocumentsToImport.Add();
			FillPropertyValues(DocumentToDownload, DocumentExtracts);
			DocumentToDownload.BankAccount = BankAccount;
			DocumentToDownload.Currency = Currency;
			DocumentToDownload.CreateCounterparty = True;
			DocumentToDownload.ShortNumber = ObjectsPrefixesClientServer.DeleteLeadingZerosFromObjectNumber(DocumentToDownload.Number);
			DocumentToDownload["LineNumber"] = LineNumber;
			DocumentToDownload.Comment = NStr("vi = '# Tải xuống từ Ngân hàng Khách hàng';
												|ru = '#Загружен из Клиент-Банка';
												|en = '#Imported from Client Bank'; fa = '#Imported from Client Bank';
												|it = '#Загружен из Клиент-Банка';
												|pl = '#Wczytano z klienta banku';
												|tr = '#İstemci-Bankadan yüklendi'");
			
			// Elimination of duplication of payments with transfers between accounts of organizations.
			// The payer's account and the recipient's account are being checked in the current accounts section and the payment direction
			// using the data Attributes has been signed and the data has been accessed.
			VariousAccounts = DocumentToDownload.PayerAccount <> DocumentToDownload.BeneficiaryAccount;
			
			PaymentToRecipientSOrganization = 
				DocumentToDownload.PayerAccount = AccountNumber
				And VariousAccounts
				And CashClientServer.ThereIsInvoiceInStatementFile(DocumentToDownload.BeneficiaryAccount, StatementData)
				And Not ValueIsFilled(DocumentToDownload.DepartureDate)
				And ValueIsFilled(DocumentToDownload.ArrivalDate_);
			
			PaymentToPayerSOrganization =
				DocumentToDownload.BeneficiaryAccount = AccountNumber
				And VariousAccounts
				And CashClientServer.ThereIsInvoiceInStatementFile(DocumentToDownload.PayerAccount, StatementData)
				And ValueIsFilled(DocumentToDownload.DepartureDate)
				And Not ValueIsFilled(DocumentToDownload.ArrivalDate_);
			
			If PaymentToRecipientSOrganization
				Or PaymentToPayerSOrganization Then
				DocumentToDownload.ToImport = False;
			Else
				DocumentToDownload.ToImport = True;
			EndIf;
			
			LineNumber = LineNumber + 1;
		EndDo;
		
		EDIWithBanksServer.PrepareStatementLines(DocumentsToImport, BankAccount, AccountAttributes, ImportParameters);
		CheckDuplicatePaymentsStatements(DocumentsToImport);
		EDIWithBanksServer.UpdateDocuments(DocumentsToImport, BankAccount, ImportParameters);
		EDIWithBanksServer.CreateDocuments(DocumentsToImport, BankAccount, ImportParameters);
		UncheckEventFlag(DocumentsToImport, BankAccount, StatementData.Title);
		
		SettlementDates_ = New Array;
		For Each DocumentToDownload In DocumentsToImport Do
			If Not DocumentToDownload.Outgoing And SettlementDates_.Find(DocumentToDownload.DocDate) = Undefined Then
				SettlementDates_.Add(BegOfDay(DocumentToDownload.DocDate));
			EndIf;
		EndDo;
		InformationRegisters.ScheduleOfPayments.CalculatePaymentScheduleForExpectedCashReceipts(SettlementDates_);
		
		Filter = New Structure("ToImport", True);
		LinesToLoad = DocumentsToImport.FindRows(Filter);
		DocumentsTable = DocumentsToImport.Copy(LinesToLoad);
		
		PutToTempStorage(DocumentsTable, StorageAddress);
		
		PerformanceMonitor.EndTimeConsumingOperationMeasurement(PerformanceMeasurement, StatementDocuments.Count());
	Else
		PerformanceMonitor.EndTimeConsumingOperationMeasurement(PerformanceMeasurement, 1);
	EndIf;
	
EndProcedure

// Fills in the value of the field from the counterparty's data table.
// 
// Parameters:
//  DataTable - ValueTable - data containing the Name and checkpoint of the counterparty.
//  CurrentValue - String - the value of the field to be filled in.
//  Document - DocumentRef - the document for which the filling is performed.
//  Flag - Number - a sign that determines the choice of props from the data table of the counterparty of the data table: 0 - Name,
//                    1 - CHECKPOINT.
//
Procedure FillInAttributeValueForDocument(DataTable, CurrentValue, Document, Flag) Export

	Filter = New Structure("Document, Flag", Document, Flag);
	DataList = DataTable.FindRows(Filter);
	CurrentValue = ?(CurrentValue <> "", CurrentValue,
						?(DataList.Count() > 0, DataList[0].AttributeValue, ""));

EndProcedure

// Displays an error message about uploading a file to the user and writes it to the registration Log.
// 
// Parameters:
//  Account - CatalogRef.CompaniesBankAccounts - the invoice for which the error occurred.
//  FileName - String - name of the downloaded file.
//  ErrorInfo - ErrorInfo, Undefined - information about the error.
//
Procedure OutputFileUploadError(Account, FileName, ErrorInfo) Export

	TextTemplate1 = NStr("vi = 'Lỗi tải tệp  ""%1"" theo tài khoản %2:
								|%3';
								|ru = 'Ошибка загрузки файла ""%1"" по счету %2:
								|%3';
								|en = 'An error occurred when importing the ""%1"" file for the ""%2"" account:
								|%3'; fa = 'An error occurred when importing the ""%1"" file for the ""%2"" account:
								|%3';
								|it = 'An error occurred when importing the ""%1"" file for the ""%2"" account:
								|%3';
								|pl = 'An error occurred when importing the ""%1"" file for the ""%2"" account:
								|%3';
								|tr = '%2 muhasebesine göre ""%1"" dosyasından indirme hatası:
								|%3'");
	ErrorDetailedText = StrTemplate(
		TextTemplate1, FileName, Account, ?(ErrorInfo <> Undefined, ErrorProcessing.DetailErrorDescription(ErrorInfo), ""));
	Event = StrTemplate("%1 %2", NStr("vi = 'Tải thanh toán từ ngân hàng.';
										|ru = 'Загрузка платежей из банка.';
										|en = 'Import payments from the bank.'; fa = 'Import payments from the bank.';
										|it = 'Import payments from the bank.';
										|pl = 'Import payments from the bank.';
										|tr = 'Bankadan ödemelerin indirilmesi.'", Common.DefaultLanguageCode()),
						NStr("vi = 'Lỗi thực hiện';
							|ru = 'Ошибка выполнения';
							|en = 'Runtime error'; fa = 'خطای زمان اجرا';
							|it = 'Errore nell''esecuzione';
							|pl = 'Błąd wykonania';
							|tr = 'Uygulama hatası'", Common.DefaultLanguageCode()));
	WriteLogEvent(
		Event,
		EventLogLevel.Error, ,
		NStr("vi = 'Tải sao kê ngân hàng';
			|ru = 'Загрузка выписки банка';
			|en = 'Bank statement import'; fa = 'Bank statement import';
			|it = 'Загрузка выписки банка';
			|pl = 'Pobierz wyciąg bankowy';
			|tr = 'Banka ekstresini yükleme'"),
		ErrorDetailedText);
	
	ErrorTextBriefly = StrTemplate(
		TextTemplate1, FileName, Account, ?(ErrorInfo <> Undefined, ErrorProcessing.BriefErrorDescription(ErrorInfo), ""));
	Common.MessageToUser(ErrorTextBriefly);

EndProcedure

#EndRegion

#Region Private

#Region QueriesTexts

Function QueryTextSettingsOfAccounts()
	
	QueryText = "
	|SELECT ALLOWED
	|	BankAccounts.Ref                            AS Ref,
	|	BankAccounts.Owner                          AS Organization,
	|	BankAccounts.Description                      AS Description,
	|	BankAccounts.AccountNumber                        AS AccountNumber,
	|	BankAccounts.UseBankClientDataExchange          AS ExchangeThroughFile,
	|	
	|	CASE
	|		WHEN BankAccounts.UseBankClientDataExchange THEN
	|			CASE WHEN &Load THEN
	|				BankAccounts.ImportFile
	|			ELSE
	|				BankAccounts.ExportFile
	|			END
	|	END AS ConfigureExchange,
	|	CAST("""" AS STRING(255)) AS ExchangeSettingPresentation,
	|
	|	CASE
	|		WHEN BankAccounts.UseBankClientDataExchange THEN
	|			CASE WHEN &Load THEN
	|				BankAccounts.ImportFile
	|			ELSE
	|				BankAccounts.ExportFile
	|			END
	|		ELSE CAST("""" AS STRING(255))
	|	END AS RuleOfFileEDIWithBanks,
	|			BankAccounts.ExchangeFormat
	|		AS ExchangeFormat,
	|	BankAccounts.VersionOfUploadFormat             AS VersionOfUploadFormat,
	|	BankAccounts.Encoding                         AS Encoding,
	|	BankAccounts.Application                         AS Application,
	|	
	|	0                                                 AS ForExport,
	|	
	|	LastEDIWithBanks.ExportDate               AS LastExportDate,
	|	LastEDIWithBanks.ImportStartDate         AS LastImportStartDate,
	|	LastEDIWithBanks.ImportEndDate          AS EndDateOfLastUpload,
	|	UNDEFINED                                      AS ImportStartDate,
	|	UNDEFINED                                      AS ImportEndDate,
	|	CAST("""" AS STRING(30))                     AS LastStatement,
	|	
	|	CASE WHEN BankAccounts.ManualBankDetailsChange THEN
	|		BankAccounts.BankBIC
	|	ELSE
	|		BankAccounts.Bank.Code
	|	END AS BankBIC,
	|	CASE WHEN BankAccounts.ManualBankDetailsChange THEN
	|		BankAccounts.BankDescription
	|	ELSE
	|		BankAccounts.Bank
	|	END AS Bank,
	|	BankAccounts.Closed                            AS Closed,
	|	CASE
	|		WHEN &Load 
	|			THEN BankAccounts.UseDownloadDirectory
	|		ELSE BankAccounts.UseUploadDirectory
	|	END AS ImportFromDirectory,
	|	Companies.PBPCode AS PBPCode
	|	
	|FROM
	|	Catalog.CompaniesBankAccounts AS BankAccounts
	|	
	|	
	|	LEFT JOIN
	|		InformationRegister.LastEDIWithBanks AS LastEDIWithBanks
	|	ON
	|		LastEDIWithBanks.BankAccount = BankAccounts.Ref
	|
	|	INNER JOIN
	|		Catalog.Companies AS Companies
	|	ON
	|		BankAccounts.Owner = Companies.Ref
	|	
	|WHERE
	|	BankAccounts.BankEDIEnabled
	|	AND NOT BankAccounts.DeletionMark
	|	AND NOT BankAccounts.Closed
	|	AND NOT UseBankFeedsBankExchange
	|	AND &AdditionalSelection
	|	
	|ORDER BY
	|	BankAccounts.Description
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextDocumentsToExport()
	
	QueryText = "
	|SELECT ALLOWED
	|	NonCashFunds.Recorder AS Ref
	|
	|INTO PaymentOrders
	|
	|FROM
	|	AccumulationRegister.BankAccountCash AS NonCashFunds
	|	
	|	INNER JOIN
	|		Document.BankAccountIssue AS DocumentData
	|	ON
	|		DocumentData.Ref = NonCashFunds.Recorder
	|	
	|WHERE
	|	NonCashFunds.ToWriteOff <> 0
	|	AND (NonCashFunds.Period BETWEEN &StartDate AND &EndDate
	|		OR &EndDate = DATETIME(1,1,1) AND NonCashFunds.Period >= &StartDate)
	|	AND DocumentData.Posted
	|	AND NOT DocumentData.ProcessedByBank
	|	AND DocumentData.PaymentDocumentType IN (
	|		VALUE(Enum.TypesOfPaymentDocuments.PaymentOrder)
	|	)
	|	AND DocumentData.BankAccount IN(&ArrayOfAccounts_)
	|	AND (DocumentData.ExportDate = DATETIME(1,1,1) OR NOT &NotExportedOnly)
	|	
	|GROUP BY
	|	NonCashFunds.Recorder
	|;
	|//////////////////////////////////////////////////////////////////////////////
	|
	|SELECT ALLOWED
	|	NonCashFunds.Recorder AS Ref
	|
	|INTO PaymentRequirements
	|
	|FROM
	|	AccumulationRegister.BankAccountCash AS NonCashFunds
	|	
	|	INNER JOIN
	|		Document.BankAccountReceiptNote AS DocumentData
	|	ON
	|		DocumentData.Ref = NonCashFunds.Recorder
	|	
	|WHERE
	|	NonCashFunds.ToReceive_ <> 0
	|	AND (NonCashFunds.Period BETWEEN &StartDate AND &EndDate
	|		OR &EndDate = DATETIME(1,1,1) AND NonCashFunds.Period >= &StartDate)
	|	AND DocumentData.Posted
	|	AND NOT DocumentData.ProcessedByBank
	|	AND DocumentData.PaymentDocumentType = VALUE(Enum.TypesOfPaymentDocuments.PaymentDemand)
	|	AND DocumentData.BankAccount IN(&ArrayOfAccounts_)
	|	AND (DocumentData.ExportDate = DATETIME(1,1,1) OR NOT &NotExportedOnly)
	|	
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

Function RequestTextPaymentOrdersThirdParties() Export
	
	QueryText = "
	|
	|SELECT ALLOWED
	|	DocumentData.ExportDate                          AS ExportDate,
	|	DocumentData.Number                                 AS Number,
	|	CASE
	|		WHEN DocumentData.IncomingDocumentDate = DATETIME(1, 1, 1)
	|			THEN DocumentData.Date
	|		ELSE DocumentData.IncomingDocumentDate
	|	END                                                 AS Date,
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
	|	DocumentData.Organization.LegalEntityIndividual                          AS CompanyLegalEntityIndividual,
	
	// Organization and organization account
	
	|	CompanyBankAccount.AccountNumber AS CompanyBankAccount_,
	|	CompanyBankAccount.ThisIsAnIBAN AS OrganizationAndAccountAreIBAN,
	
	// Name of the organization
	|	CASE
	|		WHEN &RFPaymentsSupport THEN
	|			DocumentData.PayerSName
	|		WHEN CAST(DocumentData.PayerSName AS STRING(255)) <> """" THEN
	|			DocumentData.PayerSName
	|		WHEN CAST(CompanyBankAccount.CorrespondentText AS STRING(255)) <> """" THEN
	|			CompanyBankAccount.CorrespondentText
	|		ELSE DocumentData.Organization.Description
	|	END AS CompanyName,
	
	// Abbreviated name of the organization
	|	CASE
	|		WHEN &RFPaymentsSupport THEN
	|			DocumentData.PayerSName
	|		WHEN CAST(DocumentData.PayerSName AS STRING(255)) <> """" THEN
	|			DocumentData.PayerSName
	|		WHEN CAST(CompanyBankAccount.CorrespondentText AS STRING(255)) <> """" THEN
	|			CompanyBankAccount.CorrespondentText
	|		ELSE """"
	|	END AS OrganizationAbbreviatedName,
	
	// Name of the international organization
	|	CASE
	|		WHEN CAST(CompanyBankAccount.CorrespondentText AS STRING(255)) <> """" THEN
	|			CompanyBankAccount.CorrespondentText
	|		ELSE """"
	|	END AS CompanyNameInternational,
	
	// Inn of the organization
	|	CASE
	|		WHEN &RFPaymentsSupport THEN
	|			DocumentData.TINOfPayer
	|		ELSE
	|			DocumentData.Organization.TIN
	|	END AS CompanyTIN,
	
	// Organization'S checkpoint
	|	CASE
	|		WHEN &RFPaymentsSupport THEN
	|			DocumentData.PayerCRTR
	|		ELSE """"
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
	
	// Full name of the counterparty
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
	
	// Abbreviated name of the organization
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
	|			ELSE """"
	|			END
	|		ELSE
	|			CounterpartyBankAccounts.CorrespondentText
	|	END AS CounterpartyAbbreviatedName,
	
	// Abbreviated name of the organization
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
	// Counterparty's checkpoint
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
	|	"""" AS NameOfBankCommissionAccount,

	|	DocumentData.PaysheetNumber AS PaysheetNumber,
	|	DocumentData.PaysheetDate AS PaysheetDate
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

Function RequestTextPaymentOrdersInternal() Export
	
	QueryText = "
	|
	|SELECT
	|	DocumentData.ExportDate                          AS ExportDate,
	|	DocumentData.Number                                 AS Number,
	|	CASE
	|		WHEN DocumentData.IncomingDocumentDate = DATETIME(1, 1, 1)
	|			THEN DocumentData.Date
	|		ELSE DocumentData.IncomingDocumentDate
	|	END                                                 AS Date,
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
	|	DocumentData.Organization.LegalEntityIndividual                          AS CompanyLegalEntityIndividual,
	
	// Organization and organization account
	
	|	CompanyBankAccount.AccountNumber AS CompanyBankAccount_,
	|	CompanyBankAccount.ThisIsAnIBAN AS OrganizationAndAccountAreIBAN,
	
	// Name of the organization
	|	CASE
	|		WHEN &RFPaymentsSupport THEN
	|			DocumentData.PayerSName
	|		WHEN CAST(DocumentData.PayerSName AS STRING(255)) <> """" THEN
	|			DocumentData.PayerSName
	|		WHEN CAST(CompanyBankAccount.CorrespondentText AS STRING(255)) <> """" THEN
	|			CompanyBankAccount.CorrespondentText
	|		ELSE DocumentData.Organization.Description
	|	END AS CompanyName,
	
	// Abbreviated name of the organization
	|	CASE
	|		WHEN &RFPaymentsSupport THEN
	|			DocumentData.PayerSName
	|		WHEN CAST(DocumentData.PayerSName AS STRING(255)) <> """" THEN
	|			DocumentData.PayerSName
	|		WHEN CAST(CompanyBankAccount.CorrespondentText AS STRING(255)) <> """" THEN
	|			CompanyBankAccount.CorrespondentText
	|		ELSE """"
	|	END AS OrganizationAbbreviatedName,
	
	// Name of the international organization
	|	CASE
	|		WHEN CAST(CompanyBankAccount.CorrespondentText AS STRING(255)) <> """" THEN
	|			CompanyBankAccount.CorrespondentText
	|		ELSE """"
	|	END AS CompanyNameInternational,
	
	// Inn of the organization
	|	CASE
	|		WHEN &RFPaymentsSupport THEN
	|			DocumentData.TINOfPayer
	|		ELSE
	|			DocumentData.Organization.TIN
	|	END AS CompanyTIN,
	
	// Organization'S checkpoint
	|	CASE
	|		WHEN &RFPaymentsSupport THEN
	|			DocumentData.PayerCRTR
	|		ELSE """"
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
	
	// Full name of the counterparty
	|	CASE
	|		WHEN CAST(CounterpartyBankAccounts.CorrespondentText AS STRING(255)) <> """"
	|			THEN CounterpartyBankAccounts.CorrespondentText
	|		ELSE CounterpartyBankAccounts.Owner.Description
	|	END AS CounterpartyName_,
	
	// Abbreviated name of the organization
	|	CASE
	|		WHEN CAST(CounterpartyBankAccounts.CorrespondentText AS STRING(255)) <> """"
	|			THEN CounterpartyBankAccounts.CorrespondentText
	|		ELSE """"
	|	END AS CounterpartyAbbreviatedName,
	
	// Name of the international organization
	|	"""" AS CounterpartyNameInternational,
	|	CounterpartyBankAccounts.Owner.TIN AS CounterpartyTIN,
	// Organization'S checkpoint
	|	"""" AS CounterpartyCRTR,
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
	|	"""" AS NameOfBankCommissionAccount,

	|	"""" AS PaysheetNumber,
	|	DATETIME(1, 1, 1) AS PaysheetDate
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

Function RequestTextPaymentOrdersTransfers() Export
	
	QueryText = "
	|
	|SELECT
	|	DocumentData.ExportDate                          AS ExportDate,
	|	DocumentData.Number                                 AS Number,
	|	CASE
	|		WHEN DocumentData.IncomingDocumentDate = DATETIME(1, 1, 1)
	|			THEN DocumentData.Date
	|		ELSE DocumentData.IncomingDocumentDate
	|	END                                                 AS Date,
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
	|	DocumentData.Organization.LegalEntityIndividual                          AS CompanyLegalEntityIndividual,
	
	// Organization and organization account
	
	|	CompanyBankAccount.AccountNumber AS CompanyBankAccount_,
	|	CompanyBankAccount.ThisIsAnIBAN AS OrganizationAndAccountAreIBAN,
	
	// Name of the organization
	|	CASE
	|		WHEN &RFPaymentsSupport THEN
	|			DocumentData.PayerSName
	|		WHEN CAST(DocumentData.PayerSName AS STRING(255)) <> """" THEN
	|			DocumentData.PayerSName
	|		WHEN CAST(CompanyBankAccount.CorrespondentText AS STRING(255)) <> """" THEN
	|			CompanyBankAccount.CorrespondentText
	|		ELSE DocumentData.Organization.Description
	|	END AS CompanyName,
	
	// Abbreviated name of the organization
	|	CASE
	|		WHEN &RFPaymentsSupport THEN
	|			DocumentData.PayerSName
	|		WHEN CAST(DocumentData.PayerSName AS STRING(255)) <> """" THEN
	|			DocumentData.PayerSName
	|		WHEN CAST(CompanyBankAccount.CorrespondentText AS STRING(255)) <> """"
	|			THEN CompanyBankAccount.CorrespondentText
	|		ELSE """"
	|	END AS OrganizationAbbreviatedName,
	
	// Name of the international organization
	|	CASE
	|		WHEN CAST(CompanyBankAccount.CorrespondentText AS STRING(255)) <> """"
	|			THEN CompanyBankAccount.CorrespondentText
	|		ELSE """"
	|	END AS CompanyNameInternational,
	
	// Inn of the organization
	|	CASE
	|		WHEN &RFPaymentsSupport THEN
	|			DocumentData.TINOfPayer
	|		ELSE
	|			DocumentData.Organization.TIN
	|	END AS CompanyTIN,
	
	// Organization'S checkpoint
	|	CASE
	|		WHEN &RFPaymentsSupport THEN
	|			DocumentData.PayerCRTR
	|		ELSE """"
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
	|		WHEN CAST(CounterpartyBankAccounts.CorrespondentText AS STRING(255)) <> """"
	|			THEN CounterpartyBankAccounts.CorrespondentText
	|		ELSE CounterpartyBankAccounts.Owner.Description
	|	END AS CounterpartyName_,
	
	// Abbreviated name of the organization
	|	CASE
	|		WHEN CAST(CounterpartyBankAccounts.CorrespondentText AS STRING(255)) <> """"
	|			THEN CounterpartyBankAccounts.CorrespondentText
	|		ELSE """"
	|	END AS CounterpartyAbbreviatedName,
	
	// Name of the international organization
	|	"""" AS CounterpartyNameInternational,
	|	CounterpartyBankAccounts.Owner.TIN AS CounterpartyTIN,
	// Organization'S checkpoint
	|	"""" AS CounterpartyCRTR,
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
	|	"""" AS NameOfBankCommissionAccount,
	
	|	"""" AS PaysheetNumber,
	|	DATETIME(1, 1, 1) AS PaysheetDate
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

Function RequestTextPaymentRequirementsThirdParties() Export
	
	QueryText = "
	|
	|SELECT
	|	DocumentData.ExportDate                          AS ExportDate,
	|	DocumentData.Number                                 AS Number,
	|	CASE
	|		WHEN DocumentData.IncomingDocumentDate = DATETIME(1, 1, 1)
	|			THEN DocumentData.Date
	|		ELSE DocumentData.IncomingDocumentDate
	|	END                                                 AS Date,
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
	|	DocumentData.Organization.LegalEntityIndividual                          AS CompanyLegalEntityIndividual,
	
	// Organization and organization account
	
	|	CompanyBankAccount.AccountNumber AS CompanyBankAccount_,
	|	CompanyBankAccount.ThisIsAnIBAN AS OrganizationAndAccountAreIBAN,
	
	// Name of the organization
	|	CASE
	|		WHEN CAST(CompanyBankAccount.CorrespondentText AS STRING(255)) = """"
	|			THEN CompanyBankAccount.CorrespondentText
	|		ELSE DocumentData.Organization.Description
	|	END AS CompanyName,
	
	// Abbreviated name of the organization
	|	CASE
	|		WHEN CAST(CompanyBankAccount.CorrespondentText AS STRING(255)) <> """"
	|			THEN CompanyBankAccount.CorrespondentText
	|		ELSE """"
	|	END AS OrganizationAbbreviatedName,
	
	// Name of the international organization
	|	CASE
	|		WHEN CAST(CompanyBankAccount.CorrespondentText AS STRING(255)) <> """"
	|			THEN CompanyBankAccount.CorrespondentText
	|		ELSE """"
	|	END AS CompanyNameInternational,
	
	// Inn of the organization
	|	DocumentData.Organization.TIN AS CompanyTIN,
	
	// Organization'S checkpoint
	|	"""" AS CompanyCRTR,
	
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
	
	// Full name of the counterparty
	|	CASE
	|		WHEN CAST(CounterpartyBankAccounts.CorrespondentText AS STRING(255)) = """" THEN
	|		CASE
	|			WHEN DocumentData.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.CashReturnByAdvanceHolder))
	|			THEN
	|				DocumentData.AdvanceHolder.Description
	|			ELSE """"
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
	
	// Counterparty's checkpoint
	|	CASE
	|		WHEN CounterpartyBankAccounts.CorrespondentCRTR <> """" THEN
	|			CounterpartyBankAccounts.CorrespondentCRTR
	|		ELSE """"
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
	|	"""" AS NameOfBankCommissionAccount,
	
	|	"""" AS PaysheetNumber,
	|	DATETIME(1, 1, 1) AS PaysheetDate
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

Function RequestTextPaymentRequirementsInternal() Export
	
	QueryText = "
	|
	|SELECT
	|	DocumentData.ExportDate                          AS ExportDate,
	|	DocumentData.Number                                 AS Number,
	|	CASE
	|		WHEN DocumentData.IncomingDocumentDate = DATETIME(1, 1, 1)
	|			THEN DocumentData.Date
	|		ELSE DocumentData.IncomingDocumentDate
	|	END                                                 AS Date,
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
	|	DocumentData.Organization.LegalEntityIndividual                          AS CompanyLegalEntityIndividual,
	
	// Organization and organization account
	
	|	CompanyBankAccount.AccountNumber AS CompanyBankAccount_,
	|	CompanyBankAccount.ThisIsAnIBAN AS OrganizationAndAccountAreIBAN,
	
	// Name of the organization
	|	CASE
	|		WHEN CAST(CompanyBankAccount.CorrespondentText AS STRING(255)) <> """"
	|			THEN CompanyBankAccount.CorrespondentText
	|		ELSE DocumentData.Organization.Description
	|	END AS CompanyName,
	
	// Abbreviated name of the organization
	|	CASE
	|		WHEN CAST(CompanyBankAccount.CorrespondentText AS STRING(255)) <> """"
	|			THEN CompanyBankAccount.CorrespondentText
	|		ELSE """"
	|	END AS OrganizationAbbreviatedName,
	
	// Name of the international organization
	|	CASE
	|		WHEN CAST(CompanyBankAccount.CorrespondentText AS STRING(255)) <> """"
	|			THEN CompanyBankAccount.CorrespondentText
	|		ELSE """"
	|	END AS CompanyNameInternational,
	
	// Inn of the organization
	|	DocumentData.Organization.TIN AS CompanyTIN,
	
	// Organization'S checkpoint
	|	"""" AS CompanyCRTR,
	
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
	|		WHEN CAST(CounterpartyBankAccounts.CorrespondentText AS STRING(255)) <> """"
	|			THEN CounterpartyBankAccounts.CorrespondentText
	|		ELSE CounterpartyBankAccounts.Owner.Description
	|	END AS CounterpartyName_,
	
	// Abbreviated name of the organization
	|	CASE
	|		WHEN CAST(CounterpartyBankAccounts.CorrespondentText AS STRING(255)) <> """"
	|			THEN CounterpartyBankAccounts.CorrespondentText
	|		ELSE """"
	|	END AS CounterpartyAbbreviatedName,
	
	// Name of the international organization
	|	"""" AS CounterpartyNameInternational,

	|	CounterpartyBankAccounts.Owner.TIN AS CounterpartyTIN,
	// Organization'S checkpoint
	|	"""" AS CounterpartyCRTR,
	
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
	|	"""" AS NameOfBankCommissionAccount,
	
	|	"""" AS PaysheetNumber,
	|	DATETIME(1, 1, 1) AS PaysheetDate
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

Function QueryTextCurrencyConversion() Export
	
	QueryText = "
	|
	|SELECT
	|	DocumentData.ExportDate                          AS ExportDate,
	|	DocumentData.Number                                 AS Number,
	|	CASE
	|		WHEN DocumentData.IncomingDocumentDate = DATETIME(1, 1, 1)
	|			THEN DocumentData.Date
	|		ELSE DocumentData.IncomingDocumentDate
	|	END                                                 AS Date,
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
	|	DocumentData.Organization.LegalEntityIndividual                          AS CompanyLegalEntityIndividual,
	
	// Organization and organization account
	
	|	CompanyBankAccount.AccountNumber AS CompanyBankAccount_,
	|	CompanyBankAccount.ThisIsAnIBAN AS OrganizationAndAccountAreIBAN,
	
	// Name of the organization
	|	CASE
	|		WHEN &RFPaymentsSupport THEN
	|			DocumentData.PayerSName
	|		WHEN CAST(DocumentData.PayerSName AS STRING(255)) <> """" THEN
	|			DocumentData.PayerSName
	|		WHEN CAST(CompanyBankAccount.CorrespondentText AS STRING(255)) <> """" THEN
	|			CompanyBankAccount.CorrespondentText
	|		ELSE DocumentData.Organization.Description
	|	END AS CompanyName,
	
	// Abbreviated name of the organization
	|	CASE
	|		WHEN &RFPaymentsSupport THEN
	|			DocumentData.PayerSName
	|		WHEN CAST(DocumentData.PayerSName AS STRING(255)) <> """" THEN
	|			DocumentData.PayerSName
	|		WHEN CAST(CompanyBankAccount.CorrespondentText AS STRING(255)) <> """" THEN
	|			CompanyBankAccount.CorrespondentText
	|		ELSE """"
	|	END AS OrganizationAbbreviatedName,
	
	// Name of the international organization
	|	CASE
	|		WHEN CAST(CompanyBankAccount.CorrespondentText AS STRING(255)) <> """"
	|			THEN CompanyBankAccount.CorrespondentText
	|		ELSE """"
	|	END AS CompanyNameInternational,
	
	|	CASE
	|		WHEN &RFPaymentsSupport THEN
	|			DocumentData.TINOfPayer
	|		WHEN DocumentData.TINOfPayer = """" THEN
	|			DocumentData.Organization.TIN
	|		ELSE
	|			DocumentData.TINOfPayer
	|	END AS CompanyTIN,
	
	// Organization'S checkpoint
	|	CASE
	|		WHEN &RFPaymentsSupport THEN
	|			DocumentData.PayerCRTR
	|		WHEN DocumentData.PayerCRTR <> """" THEN
	|			DocumentData.PayerCRTR
	|		ELSE """"
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
	|		WHEN CAST(CounterpartyBankAccounts.CorrespondentText AS STRING(255)) <> """"
	|			THEN CounterpartyBankAccounts.CorrespondentText
	|		ELSE CounterpartyBankAccounts.Owner.Description
	|	END AS CounterpartyName_,
	
	// Abbreviated name of the organization
	|	CASE
	|		WHEN CAST(CounterpartyBankAccounts.CorrespondentText AS STRING(255)) <> """"
	|			THEN CounterpartyBankAccounts.CorrespondentText
	|		ELSE """"
	|	END AS CounterpartyAbbreviatedName,
	
	// Name of the international organization
	|	"""" AS CounterpartyNameInternational,

	|	CounterpartyBankAccounts.Owner.TIN AS CounterpartyTIN,
	// Organization'S checkpoint
	|	"""" AS CounterpartyCRTR,

	|	CounterpartyContactInformation.Presentation AS CounterpartyAddressInternational,
	|	CounterpartyContactInformation.FieldValues AS CounterpartyAddressAndFieldValues,
	|	CounterpartyContactInformation.Value AS CounterpartyAddressInternationalValue,
	|	CounterpartyContactInformation.Country AS CounterpartyCountry,
	|	CounterpartyContactInformation.State AS CounterpartyRegion,
	|	CounterpartyContactInformation.City AS CounterpartyCity,
	
	|	&CounterpartySBankAccountData,

	
	// Conversion fee
	|	CASE
	|		WHEN DocumentData.BankAccountForFeeWriteOff <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|			DocumentData.BankAccountForFeeWriteOff.AccountNumber
	|		ELSE
	|			CompanyBankAccount.AccountNumber
	|	END AS CommissionAccountNumber,
	|	
	|	CASE
	|		WHEN DocumentData.BankAccountForFeeWriteOff <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|			CASE WHEN DocumentData.BankAccountForFeeWriteOff.ManualBankDetailsChange THEN DocumentData.BankAccountForFeeWriteOff.BankBIC
	|			ELSE DocumentData.BankAccountForFeeWriteOff.Bank.Code END
	|		ELSE
	|			CASE WHEN CompanyBankAccount.ManualBankDetailsChange THEN CompanyBankAccount.BankBIC
	|			ELSE CompanyBankAccount.Bank.Code END
	|	END AS CommissionAccountBIC,
	|	
	|	CASE
	|		WHEN DocumentData.BankAccountForFeeWriteOff <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef) THEN
	|			CASE WHEN DocumentData.BankAccountForFeeWriteOff.ManualBankDetailsChange THEN DocumentData.BankAccountForFeeWriteOff.BankDescription
	|			ELSE DocumentData.BankAccountForFeeWriteOff.Bank.Description END
	|		ELSE
	|			CASE WHEN CompanyBankAccount.ManualBankDetailsChange THEN CompanyBankAccount.BankDescription
	|			ELSE CompanyBankAccount.Bank.Description END
	|	END AS NameOfBankCommissionAccount,
	
	|	"""" AS PaysheetNumber,
	|	DATETIME(1, 1, 1) AS PaysheetDate
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


#EndRegion

#Region Upload0

Procedure UploadPaymentsTo1CClientBankExchange(ExportingParameters, StorageAddress)
	
	DocumentsTable = ExportingParameters.DocumentsTable;
	
	DocumentsCount = DocumentsTable.Count();
	
	If Not DocumentsCount Then
		Return;
	EndIf;
	
	DocumentsTable.Sort("Date");
	BegPeriod = DocumentsTable[0].Date;
	NdPeriod = DocumentsTable[DocumentsCount-1].Date;
	
	UploadBankAccounts = ExportingParameters.BankAccount;
	
	DischargeFlow = New TextDocument();
	
	// Forming the title
	DischargeFlow.AddLine("1CClientBankExchange");
	
	CurrentSessionDate = CurrentSessionDate();
	If CurrentSessionDate >= '20200601' Then
		FormatVersion = "1.03";
	ElsIf CurrentSessionDate>= '20140101' Then
		FormatVersion = "1.02";
	Else
		FormatVersion = "1.01";
	EndIf;
	
	DischargeFlow.AddLine("FormatVersion=" + FormatVersion);
	DischargeFlow.AddLine("Encoding="     + ?(ValueIsFilled(ExportingParameters.Encoding), ExportingParameters.Encoding, "Windows"));
	DischargeFlow.AddLine("Sender="   + Metadata.Synonym);
	DischargeFlow.AddLine("Recipient="    + TrimAll(ExportingParameters.Application));
	DischargeFlow.AddLine("CreationDate="  + Format(CurrentSessionDate(), "DF=dd.MM.yyyy"));
	DischargeFlow.AddLine("CreationTime=" + Format(CurrentSessionDate(), "DF=HH:mm:ss"));
	DischargeFlow.AddLine("StartDate="    + Format(BegPeriod, "DF=dd.MM.yyyy"));
	DischargeFlow.AddLine("EndDate="     + Format(NdPeriod, "DF=dd.MM.yyyy"));
	
	If TypeOf(UploadBankAccounts) = Type("ValueTable") Then
		For Each RegularBankAccount In UploadBankAccounts Do 
			DischargeFlow.AddLine("CreateAccount_1=" + RegularBankAccount.AccountNumber);
		EndDo;
	Else
		DischargeFlow.AddLine("CreateAccount_1=" + UploadBankAccounts.AccountNumber);
	EndIf;
	
	DocumentsKinds = New Map;
	DocumentsKinds.Insert(Enums.TypesOfPaymentDocuments.PaymentOrder, "Billing_ instructions_");
	DocumentsKinds.Insert(Enums.TypesOfPaymentDocuments.PaymentDemand, "Billing_ request");
	
	For Each DocumentKind In DocumentsKinds Do
		If DocumentsTable.Find(DocumentKind.Key, "DocumentKind") <> Undefined Then
			DischargeFlow.AddLine("Document=" + DocumentKind.Value);
		EndIf;
	EndDo;
	
	// Output the marked sections of documents
	For Each SectionLine In DocumentsTable Do
		Buffer = SectionDocument(SectionLine);
		NumberOfWorkingSections = StrLineCount(Buffer);
		For Cnt = 1 To NumberOfWorkingSections Do
			DischargeFlow.AddLine(StrGetLine(Buffer, Cnt));
		EndDo;
	EndDo;
	
	DischargeFlow.AddLine("EndOfFile");
	
	TempFileName = GetTempFileName("txt");
	
	// We set the encoding in text, otherwise there are problems on the server in Linux and in a bundle of English-language Windows + English-language SQL.
	If ExportingParameters.Encoding = "DOS" Then
		Encoding = "cp866";        // Encoding of the text.OEM;
	Else
		Encoding = "windows-1251"; // Encoding of the text.ANSI;
	EndIf;
	
	DischargeFlow.Write(TempFileName, Encoding);
	
	PutToTempStorage(New BinaryData(TempFileName), StorageAddress);
	
	Try
		DeleteFiles(TempFileName);
	Except
		WriteLogEvent(
			StrTemplate("%1 %2", NStr("vi = 'Tải lên các khoản thanh toán vào ngân hàng.';
										|ru = 'Выгрузка платежей в банк.';
										|en = 'Export payments to the bank.'; fa = 'Export payments to the bank.';
										|it = 'Выгрузка платежей в банк.';
										|pl = 'Eksport płatności do banku.';
										|tr = 'Ödemelerin bankaya yüklenmesi.'", Common.DefaultLanguageCode()),
				NStr("vi = 'Xóa tệp tạm thời';
					|ru = 'Удаление временного файла';
					|en = 'Delete temporary file'; fa = 'Delete temporary file';
					|it = 'Удаление временного файла';
					|pl = 'Usuwanie pliku tymczasowego';
					|tr = 'Geçici dosyayı silme'", Common.DefaultLanguageCode())),
			EventLogLevel.Error,,,
			DetailErrorDescription(ErrorInfo()));
	EndTry;

EndProcedure

Function SectionDocument(DocumentStructure)
	
	Buffer = "";
	
	Section3 = ExportStructure();
	FillInExportValue(Section3, DocumentStructure);
	
	AddToLine(Buffer, "SectionDocument=" + DocumentStructure.DocumentKind);
	
	For Each DetailsToUpload In Section3 Do
		Value = AdjustValue(DetailsToUpload.Value);
		If Not IsBlankString(Value) Then
			AddToLine(Buffer, DetailsToUpload.Key + "=" + Value);
		EndIf;
	EndDo;
	
	AddToLine(Buffer, "DocumentEnd");
	
	Return Buffer;
	
EndFunction

Function AdjustValue(Value)
	
	If TypeOf(Value) = Type("String") Then
		Return TrimAll(Value);
		
	ElsIf TypeOf(Value) = Type("Number") Then
		Return Format(Value, "NDS=.; NGS=' '; NG=0");
		
	ElsIf TypeOf(Value) = Type("Date") Then
		Return Format(Value, "DF=dd.MM.yyyy");
		
	Else
		Return "";
	EndIf;
	
EndFunction

Procedure AddToLine(Buffer, NewRow, Separator = "")
	
	If IsBlankString(Buffer) Then
		Buffer = NewRow;
	Else
		ThereIsAlreadyErrorPhraseInFile = StrFind(Buffer, NStr("vi = 'Lỗi trong tệp.';
																|ru = 'Ошибка в файле.';
																|en = 'File error.'; fa = 'File error.';
																|it = 'Ошибка в файле.';
																|pl = 'Błąd w pliku.';
																|tr = 'Dosyada hata.'")) > 0;
		If ThereIsAlreadyErrorPhraseInFile Then
			NewRow = StrReplace(NewRow, NStr("vi = 'Lỗi trong tệp.';
											|ru = 'Ошибка в файле.';
											|en = 'File error.'; fa = 'File error.';
											|it = 'Ошибка в файле.';
											|pl = 'Błąd w pliku.';
											|tr = 'Dosyada hata.'"), "");
		EndIf;
		
		Template = NStr("vi = '%1%2%3';
						|ru = '%1%2%3';
						|en = '%1%2%3'; fa = '%1%2%3';
						|it = '%1%2%3';
						|pl = '%1%2%3';
						|tr = '%1%2%3'");
		Buffer  = StringFunctionsClientServer.SubstituteParametersToString(
					Template,
					Buffer,
					?(IsBlankString(Separator), Chars.LF, Separator),
					NewRow);
	EndIf;
	
EndProcedure

Procedure FillInExportValue(ExportString_, SelectionForExport)
	
	AttributesOfParties = AttributesOfPaymentParties();
	FillInAttributesOfPaymentParties(AttributesOfParties, SelectionForExport);
	
	ExportString_.Number = ObjectsPrefixesClientServer.NumberForPrinting(SelectionForExport.Number, True, True);
	ExportString_.Date           = Format(SelectionForExport.Date, "DF=dd.MM.yyyy");
	ExportString_.Sum          = Format(SelectionForExport.Sum, "NFD=2; NDS=.; NGS=' '; NG=0");
	ExportString_.PayerAccount = AttributesOfParties.PayerBankAccount;
	ExportString_.BeneficiaryAccount = AttributesOfParties.RecipientBankAccount;
	ExportString_.PaymentKind     = SelectionForExport.PaymentKind;
	
	IndirectPaymentsFromPayer   = ValueIsFilled(AttributesOfParties.PayerBankForSettlements);
	IndirectPaymentsFromRecipient    = ValueIsFilled(AttributesOfParties.RecipientBankForSettlements);
	
	// PaymentKind_
	If SelectionForExport.DocumentKind = Enums.TypesOfPaymentDocuments.PaymentOrder Then
		ExportString_.PaymentKind_  = "01";
	ElsIf SelectionForExport.DocumentKind = Enums.TypesOfPaymentDocuments.LetterOfCredit Then
		ExportString_.PaymentKind_  = "08";
	ElsIf SelectionForExport.DocumentKind = Enums.TypesOfPaymentDocuments.CollectionOrder_2 Then
		ExportString_.PaymentKind_  = "06";
	ElsIf SelectionForExport.DocumentKind = Enums.TypesOfPaymentDocuments.PaymentDemand Then
		ExportString_.PaymentKind_  = "02";
	Else
		ExportString_.PaymentKind_  = "00";
	EndIf;
	
	// Payment ID code
	ExportString_.Code = SelectionForExport.Code;
	
	// Payer1
	ExportString_.Payer1 = AttributesOfParties.PayerNaim;
	
	// Payer, Payerinn
	ExportString_.PayerTIN = AttributesOfParties.PayerTIN;
	ExportString_.Payer = "TIN " + AttributesOfParties.PayerTIN + " " + ExportString_.Payer1;
	
	// Payeraccount, Payerbank1, Payerbank2, Payerbik, Payercount,Payer2, Payer3, Payer4.
	If IndirectPaymentsFromPayer Then
		ExportString_.Payer2        = AttributesOfParties.PayerBankAccount;
		ExportString_.Payer3        = AttributesOfParties.PayerBank_;
		ExportString_.Payer4        = AttributesOfParties.PayerCityOfBank;
		ExportString_.Payer         = CashServer.NameOfPayerPayee(
			ExportString_.Payer, Not IndirectPaymentsFromPayer, ExportString_.Payer2, ExportString_.Payer3, ExportString_.Payer4);
		If IsBlankString(AttributesOfParties.PayerCorrespondentAccount) Then
			ExportString_.PayerBankAccount = AttributesOfParties.PayerBankAccountForSettlements;
		Else
			ExportString_.PayerBankAccount = AttributesOfParties.PayerCorrespondentAccount;
		EndIf;
		ExportString_.PayerBank_1    = AttributesOfParties.PayerBankForSettlements;
		ExportString_.PayerBank_2    = AttributesOfParties.PayerCityOfBankSRC;
		ExportString_.PayerBIC      = AttributesOfParties.BankSBICRCPayer;
		ExportString_.PayerCorAccount  = AttributesOfParties.PayerCorrespondentAccountOfBankSRC;
	Else
		ExportString_.PayerBankAccount = AttributesOfParties.PayerBankAccount;
		ExportString_.PayerBank_1    = AttributesOfParties.PayerBank_;
		ExportString_.PayerBank_2    = AttributesOfParties.PayerCityOfBank;
		ExportString_.PayerBIC      = AttributesOfParties.BankBICPayer;
		ExportString_.PayerCorAccount  = AttributesOfParties.PayerCorrespondentAccount;
	EndIf;
	
	// Recipient1
	RecipientPositionVKSymbol = StrFind(AttributesOfParties.RecipientNaim, Chars.CR);
	If RecipientPositionVKSymbol = 0 Then
		ExportString_.Recipient1 = AttributesOfParties.RecipientNaim;
	EndIf;
	
	// Recipient, Payeeinn
	ExportString_.BeneficiaryTIN = AttributesOfParties.BeneficiaryTIN;
	ExportString_.Recipient = "TIN " + AttributesOfParties.BeneficiaryTIN + " " + ExportString_.Recipient1;
	
	// PayeeAccount, Payeebank1, Payeebank2, Payeebik, PayeeAccount, Payee2, Payee3, Payee4.
	If IndirectPaymentsFromRecipient Then
		ExportString_.Recipient2        = AttributesOfParties.RecipientBankAccount;
		ExportString_.Recipient3        = AttributesOfParties.RecipientBank_;
		ExportString_.Recipient4        = AttributesOfParties.RecipientCityOfBank;
		ExportString_.Recipient         = CashServer.NameOfPayerPayee(
			ExportString_.Recipient, Not IndirectPaymentsFromRecipient, ExportString_.Recipient2, ExportString_.Recipient3, ExportString_.Recipient4);
		If IsBlankString(AttributesOfParties.RecipientCorrespondentAccount) Then
			ExportString_.RecipientBankAccount = AttributesOfParties.RecipientBankAccountForSettlements;
		Else
			ExportString_.RecipientBankAccount = AttributesOfParties.RecipientCorrespondentAccount;
		EndIf;
		ExportString_.RecipientBank_1 = EDIWithBanksServer.NameOfPayeeSBank(
			AttributesOfParties.RecipientBankForSettlements, AttributesOfParties.RecipientBankForSettlementsNameOfRCC);
		ExportString_.RecipientBank_2    = AttributesOfParties.RecipientCityOfBankSRC;
		ExportString_.BeneficiaryBIC      = AttributesOfParties.RecipientOfBankSBICRC;
		ExportString_.BeneficiaryCorAccount  = AttributesOfParties.RecipientCorrespondentAccountOfBankSRC;
	Else
		ExportString_.RecipientBankAccount = AttributesOfParties.RecipientBankAccount;
		ExportString_.RecipientBank_1 = EDIWithBanksServer.NameOfPayeeSBank(
			AttributesOfParties.RecipientBank_, AttributesOfParties.RecipientBankNameOfRCC);
		ExportString_.RecipientBank_2    = AttributesOfParties.RecipientCityOfBank;
		ExportString_.BeneficiaryBIC      = AttributesOfParties.BankSBICRecipient;
		ExportString_.BeneficiaryCorAccount  = AttributesOfParties.RecipientCorrespondentAccount;
	EndIf;
	
	If Not ValueIsFilled(ExportString_.KPPPayer) Then
		ExportString_.KPPPayer = SelectionForExport.PayerCRTR;
	EndIf;
	
	If Not ValueIsFilled(ExportString_.BeneficiaryCRTR) Then
		ExportString_.BeneficiaryCRTR = SelectionForExport.RecipientCRTR;
	EndIf;
	
	// The status of the supplier, the payer of the CHECKPOINT, the recipient of the CHECKPOINT, the indicator of the OKATO/OKTMO indicator of the basis of the indicator of the period
	// Exponentnumber exponentdate exponenttype Code.
	If SelectionForExport.TransferOfTaxesAndContributions Then
		ExportString_.AuthorStatus = SelectionForExport.AuthorStatus;
		
		If Not ValueIsFilled(ExportString_.KPPPayer) Then
			ExportString_.KPPPayer = "0";
		EndIf;
		
		If Not ValueIsFilled(ExportString_.BeneficiaryCRTR) Then
			ExportString_.BeneficiaryCRTR = "0";
		EndIf;
		
		If IsBlankString(SelectionForExport.BCCode) Then
			ExportString_.IndicatorBCC = "0";
		Else
			ExportString_.IndicatorBCC = SelectionForExport.BCCode;
		EndIf;
		
		If IsBlankString(SelectionForExport.RNCPSRNCMTCode) Then
			ExportString_.RNCPS = "0";
		Else
			ExportString_.RNCPS = TrimAll(SelectionForExport.RNCPSRNCMTCode);
		EndIf;
		
		If IsBlankString(SelectionForExport.BasisIndicator) Then
			ExportString_.BasisIndicator = "0";
		Else
			ExportString_.BasisIndicator = SelectionForExport.BasisIndicator;
		EndIf;
		
		If IsBlankString(SelectionForExport.PeriodIndicator) Or (SelectionForExport.PeriodIndicator = "  .  .    ") Then
			ExportString_.PeriodIndicator = "0";
		Else
			ExportString_.PeriodIndicator = SelectionForExport.PeriodIndicator;
		EndIf;
		
		If IsBlankString(SelectionForExport.NumberIndicator) Then
			ExportString_.NumberIndicator = "0";
		Else
			ExportString_.NumberIndicator = SelectionForExport.NumberIndicator;
		EndIf;
		
		If Not ValueIsFilled(SelectionForExport.DateIndicator) Then
			ExportString_.DateIndicator = "0";
		Else
			ExportString_.DateIndicator = SelectionForExport.DateIndicator;
		EndIf;
	EndIf;
	
	// Payment code
	ExportString_.TypeIndicator = "" + SelectionForExport.PaymentCode;
	
	// Code of the type of income
	ExportString_.PaymentPurposeCode = "" + SelectionForExport.IncomeKindCode;
	
	// RankingInPriority
	ExportString_.RankingInPriority = "" + SelectionForExport.RankingInPriorityOfPayment;
	
	// Appointment of payment, Appointment of payment 1 Appointment of payment 2 Appointment of payment 3 Appointment of payment 4 Appointment of payment 5 Appointment of payment 6.
	ExportString_.PaymentPurposes = StrReplace(SelectionForExport.PaymentPurposes, Chars.LF + Chars.CR, " ");
	ExportString_.PaymentPurposes = StrReplace(
		StrReplace(StrReplace(ExportString_.PaymentPurposes, Chars.LF, " "), Chars.CR, " "), Chars.FF, " ");
	NumberOfInventoryItemLines = StrLineCount(SelectionForExport.PaymentPurposes);
	
	If NumberOfInventoryItemLines > 6 Then
		NumberOfInventoryItemLines = 6;
	EndIf;
	
	For Cnt = 1 To NumberOfInventoryItemLines Do
		ExportString_["PaymentPurposes" + Cnt] = StrGetLine(SelectionForExport.PaymentPurposes, Cnt);
	EndDo;
	
	For Cnt = (NumberOfInventoryItemLines + 1) To 6 Do
		ExportString_["PaymentPurposes" + Cnt] = "";
	EndDo;
	
EndProcedure

Function ExportStructure()
	
	ExportStructure = New Structure;
	
	ExportStructure.Insert("ToExport",              ""); // "_"
	ExportStructure.Insert("Readiness",             ""); // "Ready"
	
	ExportStructure.Insert("DocNumber",               ""); // "Document No."
	ExportStructure.Insert("Number",                  ""); // "Number"
	ExportStructure.Insert("Date",                   ""); // "Date"
	ExportStructure.Insert("Operation",               ""); // "Operation"
	ExportStructure.Insert("BankAccountOfCompany",        ""); // "E-mail address of the organization"
	ExportStructure.Insert("CompanyAccountNumber",  ""); // "R/s of the organization"
	ExportStructure.Insert("Sum",                  ""); // "Amount"
	
	ExportStructure.Insert("Counterparty",             ""); // "Counterparty"
	ExportStructure.Insert("AccountOfCounterparty",        ""); // "Counterparty's R/s"
	ExportStructure.Insert("CounterpartyAccountNumber",  ""); // "Counterparty's email address"
	
	ExportStructure.Insert("ReceiptDate",          ""); // "The date of the forms. receipts"
	ExportStructure.Insert("ReceiptTime",         ""); // "The time of forms. receipts"
	ExportStructure.Insert("ReceiptContent",    ""); // "Contents of the receipt"
	
	ExportStructure.Insert("PayerAccount",         ""); // "Payer's settlement account"
	ExportStructure.Insert("Payer",             ""); // "Payer"
	ExportStructure.Insert("PayerTIN",          ""); // "Payer's INN"
	ExportStructure.Insert("Payer1",            ""); // "Name of the payer"
	ExportStructure.Insert("Payer2",            ""); // "Payer's settlement account"
	ExportStructure.Insert("Payer3",            ""); // "Payer's Bank"
	ExportStructure.Insert("Payer4",            ""); // "City of the payer's bank"
	ExportStructure.Insert("PayerBankAccount",     ""); // "Payer's bank account"
	ExportStructure.Insert("PayerBank_1",        ""); // "RC of the payer's bank"
	ExportStructure.Insert("PayerBank_2",        ""); // "City of the payer's bank RC"
	ExportStructure.Insert("PayerBIC",          ""); // "BIC RC of the payer's bank"
	ExportStructure.Insert("PayerCorAccount",      ""); // "The account of the RC bank of boards."
	
	ExportStructure.Insert("BeneficiaryAccount",         ""); // "Recipient's current account"
	ExportStructure.Insert("Recipient",             ""); // "Recipient"
	ExportStructure.Insert("BeneficiaryTIN",          ""); // "Recipient's INN"
	ExportStructure.Insert("Recipient1",            ""); // "Name of the recipient"
	ExportStructure.Insert("Recipient2",            ""); // "Recipient's current account"
	ExportStructure.Insert("Recipient3",            ""); // "Recipient's Bank"
	ExportStructure.Insert("Recipient4",            ""); // "City of the recipient's bank"
	ExportStructure.Insert("RecipientBankAccount",     ""); // "Account of the recipient's bank"
	ExportStructure.Insert("RecipientBank_1",        ""); // "RC of the recipient's bank"
	ExportStructure.Insert("RecipientBank_2",        ""); // "City of the recipient bank's RC"
	ExportStructure.Insert("BeneficiaryBIC",          ""); // "BIC RC of the recipient's bank"
	ExportStructure.Insert("BeneficiaryCorAccount",      ""); // "Korschet RC Bank floor."
	
	ExportStructure.Insert("PaymentKind",             ""); // "Type of payment"
	ExportStructure.Insert("PaymentPurposeCode",          ""); // "Income type code"
	ExportStructure.Insert("PaymentKind_",              ""); // "Type of payment"
	ExportStructure.Insert("TransferOfTaxesAndContributions",    ""); // "Transfer to the budget",
	ExportStructure.Insert("KindOfFundsTransferToBudget", ""); // "Type of transfer to the budget",
	
	ExportStructure.Insert("AuthorStatus",      ""); // "Status of the originator"
	ExportStructure.Insert("KPPPayer",          ""); // "Payer's checkpoint"
	ExportStructure.Insert("BeneficiaryCRTR",          ""); // "Recipient's checkpoint"
	ExportStructure.Insert("IndicatorBCC",          ""); // "KBK indicator"
	ExportStructure.Insert("RNCPS",                  ""); // "OKATO/OKTMO"
	ExportStructure.Insert("BasisIndicator",    ""); // "Base indicator"
	ExportStructure.Insert("PeriodIndicator",      ""); // "Period indicator"
	ExportStructure.Insert("NumberIndicator",       ""); // "Document number indicator"
	ExportStructure.Insert("DateIndicator",         ""); // "Document date indicator"
	ExportStructure.Insert("TypeIndicator",         ""); // "Payment type indicator"
	
	ExportStructure.Insert("PaymentTerm",            ""); // "Validity period of the letter of credit"
	ExportStructure.Insert("RankingInPriority",            ""); // "Order of payment"
	
	ExportStructure.Insert("PaymentPurposes",      ""); // "Purpose of payment"
	ExportStructure.Insert("PaymentPurposes1",     ""); // "Purpose of payment, page 1"
	ExportStructure.Insert("PaymentPurposes2",     ""); // "Purpose of payment, page 2"
	ExportStructure.Insert("PaymentPurposes3",     ""); // "Purpose of payment, page 3"
	ExportStructure.Insert("PaymentPurposes4",     ""); // "Purpose of payment, page 4"
	ExportStructure.Insert("PaymentPurposes5",     ""); // "Purpose of payment, page 5"
	ExportStructure.Insert("PaymentPurposes6",     ""); // "Purpose of payment, page 6"
	
	ExportStructure.Insert("AcceptanceTerm",            ""); // "Acceptance period"
	ExportStructure.Insert("KindOfLetterOfCredit",         ""); // "Type of letter of credit"
	ExportStructure.Insert("PaymentTerm1",         ""); // "Payment terms, page 1"
	ExportStructure.Insert("PaymentTerm2",         ""); // "Payment terms, page 2"
	ExportStructure.Insert("PaymentTerm3",         ""); // "Payment terms, page 3"
	ExportStructure.Insert("PaymentByView",         ""); // "Payment by submission"
	ExportStructure.Insert("AdditionConditions",          ""); // "Additional conditions"
	ExportStructure.Insert("PurchaseCommercialInvoiceNumber",   ""); // "Supplier's account No."
	ExportStructure.Insert("DateOfSendingDoc",         ""); // "Date of sending documents"
	
	ExportStructure.Insert("Document",               ""); // "Source"
	ExportStructure.Insert("SectionDocument",         ""); // "Unloading"
	
	ExportStructure.Insert("ErrorsDescription",         ""); // "Remarks"
	ExportStructure.Insert("DocumentType",           ""); // "Type of pl. document"
	
	ExportStructure.Insert("Code",                    ""); // "Unique payment identifier"
	
	Return ExportStructure;
	
EndFunction

Procedure UnloadPaymentsInISO20022(ExportingParameters, StorageAddress)
	
	DocumentsTable = ExportingParameters.DocumentsTable;
	
	DocumentsCount = DocumentsTable.Count();
	
	If Not DocumentsCount Then
		Return;
	EndIf;
	
	DocumentsTable.Sort("Date");
	ErrorText = "";
	
	TypeNames = ISO20022TypeNames(ExportingParameters.VersionOfUploadFormat);
	Factory = CashCached.ISO20022Factory(ExportingParameters.VersionOfUploadFormat);
	Namespace = "urn:iso:std:iso:20022:tech:xsd:" + ExportingParameters.VersionOfUploadFormat;

	MessagePain001 = CMLObject(Factory, "Document", Namespace);
	MessageTitle = CMLObject(Factory, TypeNames.CustomerCreditTransferInitiation, Namespace);
	SectionGroupHeader = CMLObject(Factory, TypeNames.GroupHeader, Namespace);
	DocumentID_2 = StrReplace(String(New UUID()), "-", "");
	FillInXDTOProperty(SectionGroupHeader, "MsgId", DocumentID_2, True, ErrorText);
	FillInXDTOProperty(SectionGroupHeader, "CreDtTm", CurrentSessionDate(), True, ErrorText);
	DocumentsCount = String(DocumentsTable.Count());
	FillInXDTOProperty(SectionGroupHeader, "NbOfTxs", DocumentsCount, True, ErrorText);
	TotalAmount_1 = DocumentsTable.Total("Sum");
	FillInXDTOProperty(SectionGroupHeader, "CtrlSum", TotalAmount_1, True, ErrorText);
	IdentificationOfInitiator = CMLObject(Factory, TypeNames.PartyIdentification, Namespace);
	FillInXDTOProperty(SectionGroupHeader, "InitgPty", IdentificationOfInitiator, True, ErrorText);
	FillInXDTOProperty(MessageTitle, "GrpHdr", SectionGroupHeader, True, ErrorText);
	For Each Document In DocumentsTable Do
		UploadDocumentISO20022(Factory, TypeNames, Namespace, MessageTitle, Document, ErrorText);
	EndDo;
	
	FillInXDTOProperty(MessagePain001, "CstmrCdtTrfInitn", MessageTitle, True, ErrorText);

	MessagePain001.Validate();
	
	If ValueIsFilled(ErrorText) Then
		Raise ErrorText;
	EndIf;
		
	BinaryData = BinaryDataFromXDTO(Factory, MessagePain001);
	PutToTempStorage(BinaryData, StorageAddress);
	
EndProcedure

Function ISO20022TypeNames(VersionOfUploadFormat)
	
	ReturnValue = New Structure;
	If VersionOfUploadFormat = "pain.001.001.03" Then
		ReturnValue.Insert("CustomerCreditTransferInitiation", "CustomerCreditTransferInitiationV03");
		ReturnValue.Insert("GroupHeader", "GroupHeader32");
		ReturnValue.Insert("PartyIdentification", "PartyIdentification32");
		ReturnValue.Insert("PaymentInstruction", "PaymentInstructionInformation3");
		ReturnValue.Insert("Party", "Party6Choice");
		ReturnValue.Insert("OrganisationIdentification", "OrganisationIdentification4");
		ReturnValue.Insert("CashAccount", "CashAccount16");
		ReturnValue.Insert("BranchAndFinancialInstitutionIdentification", "BranchAndFinancialInstitutionIdentification4");
		ReturnValue.Insert("FinancialInstitutionIdentification", "FinancialInstitutionIdentification7");
		ReturnValue.Insert("BIC", "BIC");
		ReturnValue.Insert("CreditTransferTransaction", "CreditTransferTransactionInformation10");
		ReturnValue.Insert("RemittanceInformation", "RemittanceInformation5");
	ElsIf VersionOfUploadFormat = "pain.001.001.04" Then
		ReturnValue.Insert("CustomerCreditTransferInitiation", "CustomerCreditTransferInitiationV04");
		ReturnValue.Insert("GroupHeader", "GroupHeader48");
		ReturnValue.Insert("PartyIdentification", "PartyIdentification43");
		ReturnValue.Insert("PaymentInstruction", "PaymentInstruction6");
		ReturnValue.Insert("Party", "Party11Choice");
		ReturnValue.Insert("OrganisationIdentification", "OrganisationIdentification8");
		ReturnValue.Insert("CashAccount", "CashAccount24");
		ReturnValue.Insert("BranchAndFinancialInstitutionIdentification", "BranchAndFinancialInstitutionIdentification5");
		ReturnValue.Insert("FinancialInstitutionIdentification", "FinancialInstitutionIdentification8");
		ReturnValue.Insert("BIC", "BICFI");
		ReturnValue.Insert("CreditTransferTransaction", "CreditTransferTransaction1");
		ReturnValue.Insert("RemittanceInformation", "RemittanceInformation7");
	ElsIf VersionOfUploadFormat = "pain.001.001.05" Then
		ReturnValue.Insert("CustomerCreditTransferInitiation", "CustomerCreditTransferInitiationV05");
		ReturnValue.Insert("GroupHeader", "GroupHeader48");
		ReturnValue.Insert("PartyIdentification", "PartyIdentification43");
		ReturnValue.Insert("PaymentInstruction", "PaymentInstruction9");
		ReturnValue.Insert("Party", "Party11Choice");
		ReturnValue.Insert("OrganisationIdentification", "OrganisationIdentification8");
		ReturnValue.Insert("CashAccount", "CashAccount24");
		ReturnValue.Insert("BranchAndFinancialInstitutionIdentification", "BranchAndFinancialInstitutionIdentification5");
		ReturnValue.Insert("FinancialInstitutionIdentification", "FinancialInstitutionIdentification8");
		ReturnValue.Insert("BIC", "BICFI");
		ReturnValue.Insert("CreditTransferTransaction", "CreditTransferTransaction6");
		ReturnValue.Insert("RemittanceInformation", "RemittanceInformation7");
	Else
		Raise NStr("vi = 'Phiên bản định dạng kết xuất không được hỗ trợ';
					|ru = 'Неподдерживаемая версия формата выгрузки';
					|en = 'Unsupported export format version'; fa = 'Unsupported export format version';
					|it = 'Неподдерживаемая версия формата выгрузки';
					|pl = 'Nieobsługiwana wersja formatu wyciągu';
					|tr = 'Desteklenmeyen yükleme formatı sürümü'")
	EndIf;
	
	Return ReturnValue;
	
EndFunction

Procedure UploadDocumentISO20022(
	Factory,
	TypeNames,
	Namespace,
	MessageTitle,
	Document,
	ErrorText)
	
	OperationID = StrReplace(String(Document.Ref.UUID()), "-", "");
	PaymentHeaderSection = CMLObject(Factory, TypeNames.PaymentInstruction, Namespace);
	FillInXDTOProperty(PaymentHeaderSection, "PmtInfId", OperationID, True, ErrorText);
	FillInXDTOProperty(PaymentHeaderSection, "PmtMtd", "TRF", True, ErrorText);
	FillInXDTOProperty(PaymentHeaderSection, "NbOfTxs", "1", True, ErrorText);
	FillInXDTOProperty(PaymentHeaderSection, "CtrlSum", Document.Sum, True, ErrorText);
	FillInXDTOProperty(PaymentHeaderSection, "ReqdExctnDt", Document.Date, True, ErrorText);
	
	TransactionSection = CMLObject(Factory, TypeNames.CreditTransferTransaction, Namespace);
	UnloadDebtorVISO20022(Factory, TypeNames, Namespace, PaymentHeaderSection, Document, ErrorText);
	DownloadCommissionInformationInISO20022(PaymentHeaderSection, Document, ErrorText);
	UploadDocumentIDs(Factory, TypeNames, Namespace, TransactionSection, Document, ErrorText);

	SumSection = CMLObject(Factory, "AmountType3Choice", Namespace);
	SumValueSection = CMLObject(Factory, "ActiveOrHistoricCurrencyAndAmount", Namespace);
	FillInXDTOProperty(SumValueSection, "__content", Document.Sum, True, ErrorText);
	FillInXDTOProperty(SumValueSection, "Ccy", Document.ISOCurrencyCode_, True, ErrorText);
	FillInXDTOProperty(SumSection, "InstdAmt", SumValueSection, True, ErrorText);
	FillInXDTOProperty(TransactionSection, "Amt", SumSection, True, ErrorText);
	
	UnloadLenderISO20022(Factory, TypeNames, Namespace, TransactionSection, Document, ErrorText);
	If ValueIsFilled(Document.RankingInPriorityOfPayment) Then
		SectionPriority_ = CMLObject(Factory, "Purpose2Choice", Namespace);
		FillInXDTOProperty(SectionPriority_, "Cd", String(Document.RankingInPriorityOfPayment), True, ErrorText);
		FillInXDTOProperty(TransactionSection, "Purp", SectionPriority_, , ErrorText);
	EndIf;
	
	DownloadISO20022DocumentCode(Factory, Namespace, TransactionSection, Document, ErrorText);
	UploadISO20022RevenueTypeCode(Factory, Namespace, TransactionSection, Document, ErrorText);
	UploadTaxDetailsISO20022(Factory, Namespace, TransactionSection, Document, ErrorText);
	
	PaymentInformationSection = CMLObject(Factory, TypeNames.RemittanceInformation, Namespace);
	ArrayOfPaymentDestinationStrings = ArrayOfPaymentDestinationStringsForISO(Document.PaymentPurposes);
	For Each String In ArrayOfPaymentDestinationStrings Do
		If Not IsBlankString(String) Then
			PaymentInformationSection.Ustrd.Add(String);
		EndIf;
	EndDo;
	FillInXDTOProperty(TransactionSection, "RmtInf", PaymentInformationSection, , ErrorText);
	
	PaymentHeaderSection.CdtTrfTxInf.Add(TransactionSection);
	MessageTitle.PmtInf.Add(PaymentHeaderSection);
	
EndProcedure

Procedure UploadDocumentIDs(
	Factory,
	TypeNames,
	Namespace,
	TransactionSection,
	Document,
	ErrorText)

	PaymentIDSection = CMLObject(Factory, "PaymentIdentification1", Namespace);
	DocumentID = StrReplace(String(Document.Ref.UUID()), "-", "");
	FillInXDTOProperty(PaymentIDSection, "InstrId", DocumentID, True, ErrorText);
	DocumentNumber = ObjectsPrefixesClientServer.NumberForPrinting(Document.Number, True, True);
	FillInXDTOProperty(PaymentIDSection, "EndToEndId", DocumentNumber, True, ErrorText);
	FillInXDTOProperty(TransactionSection, "PmtId", PaymentIDSection, True, ErrorText);
	
EndProcedure

Procedure DownloadISO20022DocumentCode(Factory, Namespace, TransactionSection, Document, ErrorText)
	
	If ValueIsFilled(Document.Code) Then
		RegulatorSection = CMLObject(Factory, "RegulatoryReporting3", Namespace);
		RegulatorDetailSection = CMLObject(Factory, "StructuredRegulatoryReporting3", Namespace);
		FillInXDTOProperty(RegulatorDetailSection, "Cd", Document.Code, , ErrorText);
		RegulatorSection.Dtls.Add(RegulatorDetailSection);
		TransactionSection.RgltryRptg.Add(RegulatorSection);
	EndIf;
	
EndProcedure

Procedure UploadTaxDetailsISO20022(Factory, Namespace, TransactionSection, Document, ErrorText)
	
	If Document.TransferOfTaxesAndContributions Then
		SectionTax = CMLObject(Factory, "TaxInformation3", Namespace);
		RecipientCRTR = ?(ValueIsFilled(Document.RecipientCRTR), Document.RecipientCRTR, "0");
		LenderSection = CMLObject(Factory, "TaxParty1", Namespace);
		FillInXDTOProperty(LenderSection, "TaxTp", RecipientCRTR, , ErrorText);
		FillInXDTOProperty(SectionTax, "Cdtr", LenderSection, , ErrorText);
		PayerCRTR = ?(ValueIsFilled(Document.PayerCRTR), Document.PayerCRTR, "0");
		DebtorSection = CMLObject(Factory, "TaxParty2", Namespace);
		FillInXDTOProperty(DebtorSection, "TaxTp", PayerCRTR, , ErrorText);
		FillInXDTOProperty(SectionTax, "Dbtr", DebtorSection, , ErrorText);
		FillInXDTOProperty(SectionTax, "AdmstnZn", Document.RNCPSRNCMTCode, , ErrorText);
		FillInXDTOProperty(SectionTax, "RefNb", Document.NumberIndicator, , ErrorText);
		If ValueIsFilled(Document.DateIndicator) And Document.DateIndicator <> "0" Then
			FillInXDTOProperty(SectionTax, "Dt", DateFromRFString(Document.DateIndicator), , ErrorText);
		EndIf;
		DownloadISO20022TaxTranscript(SectionTax, Document, Factory, Namespace, ErrorText);
		FillInXDTOProperty(TransactionSection, "Tax", SectionTax, , ErrorText);
	EndIf;
	
EndProcedure

Procedure DownloadISO20022TaxTranscript(SectionTax, Document, Factory, Namespace, ErrorText)
	
	SectionTaxDecryption = CMLObject(Factory, "TaxRecord1", Namespace);
	FillInXDTOProperty(SectionTaxDecryption, "Tp", Document.PaymentCode, , ErrorText);
	FillInXDTOProperty(SectionTaxDecryption, "Ctgy", Document.BasisIndicator, , ErrorText);
	FillInXDTOProperty(SectionTaxDecryption, "DbtrSts", Document.AuthorStatus, , ErrorText);
	FillInXDTOProperty(SectionTaxDecryption, "CtgyDtls", Document.BCCode, , ErrorText);

	If ValueIsFilled(Document.PeriodIndicator) Then
		If StrFind(Document.PeriodIndicator, ".") > 0 Then
			SectionPeriod = CMLObject(Factory, "TaxPeriod1", Namespace);
			Year = Number(Mid(Document.PeriodIndicator, 7));
			BegOfYear = Date(Year, 1, 1);
			FillInXDTOProperty(SectionPeriod, "Yr", BegOfYear, , ErrorText);
			Period = Mid(Document.PeriodIndicator, 1, 2);
			If Period = "MS" Then
				Month = Mid(Document.PeriodIndicator, 4, 2);
				FillInXDTOProperty(SectionPeriod, "Tp", "MM" + Month, , ErrorText);
			ElsIf Period = "KV" Then
				Quarter = Mid(Document.PeriodIndicator, 5, 1);
				FillInXDTOProperty(SectionPeriod, "Tp", "QTR" + Quarter, , ErrorText);
			ElsIf Period = "PL_" Then
				HalfYear = Mid(Document.PeriodIndicator, 5, 1);
				FillInXDTOProperty(SectionPeriod, "Tp", "HLF" + HalfYear, , ErrorText);
			ElsIf Period = "GD" Then
				// when the annual is not specified
			Else // the exact date is specified
				SectionDate = CMLObject(Factory, "DatePeriodDetails", Namespace);
				Date = DateFromRFString(Document.PeriodIndicator);
				FillInXDTOProperty(SectionDate, "FrDt", Date, , ErrorText);
				FillInXDTOProperty(SectionDate, "ToDt", Date, , ErrorText);
				FillInXDTOProperty(SectionPeriod, "FrToDt", SectionDate, , ErrorText);
			EndIf;
			FillInXDTOProperty(SectionTaxDecryption, "Prd", SectionPeriod, , ErrorText);
		ElsIf Document.PeriodIndicator <> "0" Then // for customs payments
			RecipientSection = CMLObject(Factory, "TaxParty1", Namespace);
			FillInXDTOProperty(RecipientSection, "RegnId", Document.PeriodIndicator, , ErrorText);
			FillInXDTOProperty(SectionTax, "Cdtr", RecipientSection, , ErrorText);
		EndIf;
	EndIf;
	
	SectionTax.Rcrd.Add(SectionTaxDecryption);
		
EndProcedure

Function DateFromRFString(DateAsString)
	
	Return Date(Number(Mid(DateAsString, 7)), Number(Mid(DateAsString, 4, 2)), Number(Mid(DateAsString, 1, 2)));
	
EndFunction

Procedure UploadISO20022RevenueTypeCode(Factory, Namespace, TransactionSection, Document, ErrorText)
	
	If ValueIsFilled(Document.IncomeKindCode) Then
		IncomeTypeCodeSection = CMLObject(Factory, "RegulatoryReporting3", Namespace);
		DetailSection = CMLObject(Factory, "StructuredRegulatoryReporting3", Namespace);
		FillInXDTOProperty(DetailSection, "Dt", "PTCD", , ErrorText);
		FillInXDTOProperty(DetailSection, "Cd", Document.IncomeKindCode, , ErrorText);
		IncomeTypeCodeSection.Dtls.Add(DetailSection);
		TransactionSection.RgltryRptg.Add(IncomeTypeCodeSection);
	EndIf;
	
EndProcedure

Procedure DownloadCommissionInformationInISO20022(PaymentHeaderSection, Document, ErrorText)
	
	FeeType = Undefined;
	If ValueIsFilled(Document.TransferFeeType) Then
		If Document.TransferFeeType = Enums.TypesOfBankFeesForTransfers.BEN Then
			FeeType = "CRED";
		ElsIf Document.TransferFeeType = Enums.TypesOfBankFeesForTransfers.OUR Then
			FeeType = "DEBT";
		ElsIf Document.TransferFeeType = Enums.TypesOfBankFeesForTransfers.SHA Then
			FeeType = "SHAR";
		EndIf;
		If ValueIsFilled(FeeType) Then
			FillInXDTOProperty(PaymentHeaderSection, "ChrgBr", FeeType, , ErrorText);
		EndIf;
	EndIf;
	
EndProcedure

Procedure UnloadDebtorVISO20022(
	Factory,
	TypeNames,
	Namespace,
	PaymentHeaderSection,
	Document,
	ErrorText)
	
	CompanyName = ?(ValueIsFilled(Document.CompanyNameInternational),
		Document.CompanyNameInternational, Document.CompanyHiring);
	SectionHeadingDebtor = CMLObject(Factory, TypeNames.PartyIdentification, Namespace);
	FillInXDTOProperty(SectionHeadingDebtor, "Nm", CompanyName, True, ErrorText);
	If ValueIsFilled(Document.CompanyTIN) Then
		ISOMemberID = ISOMemberID(
			Factory, TypeNames, Namespace, Document.CompanyTIN, ErrorText);
		FillInXDTOProperty(SectionHeadingDebtor, "Id", ISOMemberID, , ErrorText);
	EndIf;
	FillInXDTOProperty(PaymentHeaderSection, "Dbtr", SectionHeadingDebtor, True, ErrorText);
	
	PayerSAccountSection = ISOAccount(Factory, TypeNames, Namespace, Document.CompanyBankAccount_,
									Document.BankAccountOfIBANCompany, ErrorText);
	FillInXDTOProperty(PaymentHeaderSection, "DbtrAcct", PayerSAccountSection, True, ErrorText);

	PayerBank = CMLObject(
		Factory, TypeNames.BranchAndFinancialInstitutionIdentification, Namespace);
	BankIDPayer = CMLObject(Factory, TypeNames.FinancialInstitutionIdentification, Namespace);
	If ValueIsFilled(Document.SwiftBankCompany) Then
		FillInXDTOProperty(
			BankIDPayer, TypeNames.BIC, Document.SwiftBankCompany, True, ErrorText);
	Else
		
		If ValueIsFilled(Document.CompanyBankBIC) Then
			NationalBankCode = CMLObject(Factory, "GenericFinancialIdentification1", Namespace);
			FillInXDTOProperty(NationalBankCode, "Id", Document.CompanyBankBIC, True, ErrorText);
			FillInXDTOProperty(BankIDPayer, "Othr", NationalBankCode, True, ErrorText);
		Else
			Raise NStr("vi = 'Chưa điền mã định danh ngân hàng của doanh nghiệp (Mã ngân hàng / SWIFT)';
						|ru = 'Не заполнен идентификатор банка организации (БИК / SWIFT)';
						|en = 'Company''s bank ID (Bank code / SWIFT) is not filled in'; fa = 'Company''s bank ID (Bank code / SWIFT) is not filled in';
						|it = 'Не заполнен идентификатор банка организации (БИК / SWIFT)';
						|pl = 'Nie wypełniono identyfikatora banku firmy (BIC / SWIFT)';
						|tr = 'İş yerinin banka tanımlayıcısı (BIC / SWIFT) doldurulmadı'");
		EndIf;
		
	EndIf;
	BankDescription = ?(ValueIsFilled(Document.CompanyBankInternational),
						Document.CompanyBankInternational, Document.CompanyBank);
	FillInXDTOProperty(BankIDPayer, "Nm", BankDescription, True, ErrorText);
	FillInXDTOProperty(PayerBank, "FinInstnId", BankIDPayer, True, ErrorText);
	FillInXDTOProperty(PaymentHeaderSection, "DbtrAgt", PayerBank, True, ErrorText);

EndProcedure

Procedure UnloadLenderISO20022(Factory, TypeNames, Namespace, TransactionSection, Document, ErrorText)
	
	UnloadRecipientSBankISO20022(Factory, TypeNames, Namespace, TransactionSection, Document, ErrorText);
	
	Recipient = CMLObject(Factory, TypeNames.PartyIdentification, Namespace);
	RecipientSName = ?(ValueIsFilled(Document.CounterpartyNameInternational),
								Document.CounterpartyNameInternational, Document.CounterpartyName);
	// European banks use the version of the pain.001.001.03 format and add TIN/KPP to the recipient's name
	If StrEndsWith(Namespace, "pain.001.001.03") And Document.ISOCurrencyCode_ = "RUB" Then
		RecipientSName = Document.CounterpartyTIN
			+ ?(ValueIsFilled(Document.RecipientCRTR), "/" + Document.RecipientCRTR, "") + " "
			+ RecipientSName;
		Balance = Mid(RecipientSName, 71);
		// RUB payment - the taxpayer identification number or INN (and KPP) is inserted in the tag
		// Creditor/Name before the name. If the Creditor's name is too long, the remainder of the name
		// must be written in the PstlAdr/AdrLine tag without any spaces (without a hyphen).
		If ValueIsFilled(Balance) Then
			SectionPostalAddress = CMLObject(Factory, "PostalAddress6", Namespace);
			AddAddressToSectionWithBreakdown(SectionPostalAddress, Balance);
			FillInXDTOProperty(Recipient, "PstlAdr", SectionPostalAddress, , ErrorText);
		EndIf;
	EndIf;
	FillInXDTOProperty(Recipient, "Nm", RecipientSName, , ErrorText);
	If ValueIsFilled(Document.CounterpartyTIN) Then
		SectionRecipientID = ISOMemberID(
			Factory, TypeNames, Namespace, Document.CounterpartyTIN, ErrorText);
		FillInXDTOProperty(Recipient, "Id", SectionRecipientID, , ErrorText);
	EndIf;
	FillInXDTOProperty(TransactionSection, "Cdtr", Recipient, , ErrorText);
	
	AccountRecipient = ISOAccount(Factory, TypeNames, Namespace, Document.CounterpartyBankAccount_,
								Document.CounterpartySBankAccountIBAN, ErrorText);
	FillInXDTOProperty(TransactionSection, "CdtrAcct", AccountRecipient, , ErrorText);
	
EndProcedure

Procedure UnloadRecipientSBankISO20022(
	Factory,
	TypeNames,
	Namespace,
	TransactionSection,
	Document,
	ErrorText)
	
	RecipientBank = CMLObject(
		Factory, TypeNames.BranchAndFinancialInstitutionIdentification, Namespace);
	IDRecipientBank = CMLObject(Factory, TypeNames.FinancialInstitutionIdentification, Namespace);
	If ValueIsFilled(Document.SwiftBankCounterparty) Then
		FillInXDTOProperty(IDRecipientBank, TypeNames.BIC, Document.SwiftBankCounterparty, True, ErrorText);
	Else
		
		If ValueIsFilled(Document.CounterpartyBankBIC) Then
			NationalBankCode = CMLObject(Factory, "GenericFinancialIdentification1", Namespace);
			FillInXDTOProperty(NationalBankCode, "Id", Document.CounterpartyBankBIC, True, ErrorText);
			FillInXDTOProperty(IDRecipientBank, "Othr", NationalBankCode, True, ErrorText);
		Else
			Raise NStr("vi = 'Chưa điền mã định danh của ngân hàng nhận (Mã ngân hàng / SWIFT)';
						|ru = 'Не заполнен идентификатор банка получателя (БИК / SWIFT)';
						|en = 'Payee’s bank ID (Bank code / SWIFT) is not filled in'; fa = 'Payee’s bank ID (Bank code / SWIFT) is not filled in';
						|it = 'Не заполнен идентификатор банка получателя (БИК / SWIFT)';
						|pl = 'Nie wypełniono identyfikatora banku odbiorcy (BIC / SWIFT)';
						|tr = 'Alıcı banka tanımlayıcısı (BIC / SWIFT) doldurulmadı'");
		EndIf;
		
	EndIf;
	BankDescription = ?(ValueIsFilled(Document.CounterpartyBankInternational),
						Document.CounterpartyBankInternational, Document.CounterpartyBank);
	If Document.ISOCurrencyCode_ = "RUB" Then
		// RUB payment - full name of the Creditor's Agent + city + BIC of the Creditor Agent (9 digits)
		// + correspondent account of the Creditor's Agent in the Central Bank of the Russian Federation
		// (20 digits, starts with 301). The last three digits of the BIC and the correspondent account
		// must coincide.
		BankCity = ?(ValueIsFilled(Document.CounterpartyBankCityInternational),
						Document.CounterpartyBankCityInternational, Document.CityOfCounterpartyBank);
		BankDescription = BankDescription + " " + BankCity + " " + Document.CounterpartyBankBIC + " "
							+ Document.CounterpartyCorrBankAccount;
	EndIf;
	FillInXDTOProperty(IDRecipientBank, "Nm", BankDescription, , ErrorText);
	FillInXDTOProperty(RecipientBank, "FinInstnId", IDRecipientBank, True, ErrorText);
	FillInXDTOProperty(TransactionSection, "CdtrAgt", RecipientBank, True, ErrorText);
	
	If ValueIsFilled(Document.CounterpartyCorrBankAccount) Then
		IntermediaryBankAccount = ISOAccount(Factory, TypeNames, Namespace, Document.CounterpartyCorrBankAccount,
										Document.CounterpartySBankAccountIBAN, ErrorText);
		FillInXDTOProperty(TransactionSection, "CdtrAgtAcct", IntermediaryBankAccount, True, ErrorText);
	EndIf;
	
EndProcedure

Function BinaryDataFromXDTO(Factory, Ed__)

	NewXMLEntry = New XMLWriter;
	MemoryStream = New MemoryStream();
	NewXMLEntry.OpenStream(MemoryStream, "UTF-8");
	NewXMLEntry.WriteXMLDeclaration();
	TypeAssignment = XMLTypeAssignment.Explicit;
	Factory.WriteXML(NewXMLEntry, Ed__, , , , TypeAssignment);
	NewXMLEntry.Close();
	Return MemoryStream.CloseAndGetBinaryData();

EndFunction

Function ArrayOfPaymentDestinationStringsForISO(PaymentPurposes)

	ReturnArray = New Array;
	ISOFormatStringLimitation = 140;

	For Counter = 1 To StrLineCount(PaymentPurposes) Do
		CurRow = StrGetLine(PaymentPurposes, Counter);
		If StrLen(CurRow) > ISOFormatStringLimitation Then
			While StrLen(CurRow) > 0 Do
				QuantityPerSlice = Min(ISOFormatStringLimitation, StrLen(CurRow));
				PieceOfString = Mid(CurRow, 1, QuantityPerSlice);
				ReturnArray.Add(PieceOfString);
				If StrLen(CurRow) <= ISOFormatStringLimitation Then
					Break;
				EndIf;
				CurRow = Mid(CurRow, QuantityPerSlice + 1);
			EndDo;
		Else
			ReturnArray.Add(CurRow);
		EndIf;
	EndDo;

	Return ReturnArray;

EndFunction

Procedure AddAddressToSectionWithBreakdown(SectionPostalAddress, Address)

	For Counter = 1 To StrLineCount(Address) Do
		CurRow = StrGetLine(Address, Counter);
		While StrLen(CurRow) > 70 Do
			LineSlice = Mid(CurRow, 1, 70);
			SectionPostalAddress.AdrLine.Add(LineSlice);
			CurRow = Mid(CurRow, 71);
		EndDo;
		SectionPostalAddress.AdrLine.Add(CurRow);
	EndDo;

EndProcedure

Function ISOMemberID(Factory, TypeNames, Namespace, TIN, ErrorText)

	IdHeaderSection = CMLObject(Factory, TypeNames.Party, Namespace);
	SectionHeaderOrg = CMLObject(Factory, TypeNames.OrganisationIdentification, Namespace);
	SectionTitleOrgID = CMLObject(Factory, "GenericOrganisationIdentification1", Namespace);
	FillInXDTOProperty(SectionTitleOrgID, "Id", TIN, True, ErrorText);
	SectionHeaderOrg.Othr.Add(SectionTitleOrgID);
	FillInXDTOProperty(IdHeaderSection, "OrgId", SectionHeaderOrg, False, ErrorText);
	Return IdHeaderSection;

EndFunction

Function ISOAccount(Factory, TypeNames, Namespace, AccountNumber, ThisIsAnIBAN, ErrorText)

	SectionHeaderInvoice = CMLObject(Factory, TypeNames.CashAccount, Namespace);
	SectionHeaderIDInvoice = CMLObject(Factory, "AccountIdentification4Choice", Namespace);
	If ThisIsAnIBAN Then
		FillInXDTOProperty(SectionHeaderIDInvoice, "IBAN", AccountNumber, True, ErrorText);
	Else
		SectionHeaderInvoiceType = CMLObject(Factory, "GenericAccountIdentification1", Namespace);
		FillInXDTOProperty(SectionHeaderInvoiceType, "Id", AccountNumber, True, ErrorText);
		SectionTitleInvoiceTypeName = CMLObject(Factory, "AccountSchemeName1Choice", Namespace);
		FillInXDTOProperty(SectionTitleInvoiceTypeName, "Cd", "BBAN", True, ErrorText);
		FillInXDTOProperty(SectionHeaderInvoiceType, "SchmeNm", SectionTitleInvoiceTypeName, True, ErrorText);
		FillInXDTOProperty(SectionHeaderIDInvoice, "Othr", SectionHeaderInvoiceType, True, ErrorText);
	EndIf;
	FillInXDTOProperty(SectionHeaderInvoice, "Id", SectionHeaderIDInvoice, True, ErrorText);
	
	Return SectionHeaderInvoice;

EndFunction

Procedure SetXDTOValue(XDTODataObject, PropertyName, Value, ErrorText)

	// Checking whether the length matches the facet for strings
	If TypeOf(Value) = Type("String") Then
		Properties = XDTODataObject.Properties(); // XDTOPropertyCollection
		SetableProperty = Properties.Get(PropertyName);
		Facets = SetableProperty.Type.Facets;
		If Facets <> Undefined Then
			FacetMaximumLength = Facets.Get(XDTOFacetType.MaxLength);
			If FacetMaximumLength <> Undefined Then
				MaxLength = Number(FacetMaximumLength.Value);
				If StrLen(Value) > MaxLength Then
					ErrorTemplate = NStr("vi = 'Lỗi đặt thuộc tính %1
						|Giá trị được đặt: %2
						|Độ dài hiện tại của dòng: %3 
						|Độ dài được phép của dòg: %4';
						|ru = 'Ошибка установки свойства %1
						|Устанавливаемое значение: %2
						|Текущая длина строки: %3 
						|Допустимая длина строки: %4';
						|en = 'Property setting error %1
						|Value to be set: %2
						|Current string length: %3 
						|Allowed string length: %4'; fa = 'Property setting error %1
						|Value to be set: %2
						|Current string length: %3 
						|Allowed string length: %4';
						|it = 'Ошибка установки свойства %1
						|Устанавливаемое значение: %2
						|Текущая длина строки: %3 
						|Допустимая длина строки: %4';
						|pl = 'Błąd ustawienia właściwości %1
						|Ustawiana wartość: %2
						|Bieżąca długość wiersza: %3 
						|Dopuszczalna długość wiersza: %4';
						|tr = 'Özellik ayar hatası %1
						|Ayarlanan değer: %2
						|Mevcut satır uzunluğu: %3 
						|Mevcut satır uzunluğu: %4'");
					ErrorText = StrTemplate(ErrorTemplate, XDTODataObject.Type().Name + "."
						+ PropertyName, Value, StrLen(Value), MaxLength);
					Return;
				EndIf;
			EndIf;
			FacetMinimumLength = Facets.Get(XDTOFacetType.MinLength);
			If FacetMinimumLength <> Undefined Then
				MinimumLength = Number(FacetMinimumLength.Value);
				If StrLen(Value) < MinimumLength Then
					ErrorTemplate = NStr("vi = 'Lỗi đặt thuộc tính %1
						|Giá trị được đặt: %2
						|Độ dài hiện tại của dòng: %3 
						|Độ dài tối thiểu của dòng: %4';
						|ru = 'Ошибка установки свойства %1
						|Устанавливаемое значение: %2
						|Текущая длина строки: %3 
						|Минимальная длина строки: %4';
						|en = 'Property setting error %1
						|Value to be set: %2
						|Current string length: %3 
						|Minimum string length: %4'; fa = 'Property setting error %1
						|Value to be set: %2
						|Current string length: %3 
						|Minimum string length: %4';
						|it = 'Ошибка установки свойства %1
						|Устанавливаемое значение: %2
						|Текущая длина строки: %3 
						|Минимальная длина строки: %4';
						|pl = 'Błąd ustawienia właściwości %1
						|Ustawiana wartość: %2
						|Bieżąca długość wiersza: %3 
						|Maksymalna długość wiersza: %4';
						|tr = 'Özellik ayar hatası %1
						|Ayarlanan değer: %2
						|Mevcut satır uzunluğu: %3 
						|Minimum satır uzunluğu: %4'");
					ErrorText = StrTemplate(ErrorTemplate, XDTODataObject.Type().Name + "."
						+ PropertyName, Value, StrLen(Value), MinimumLength);
					Return;
				EndIf;
			EndIf;
		EndIf;
	EndIf;

	Try
		XDTODataObject.Set(PropertyName, Value);
	Except
		MessageTemplate = NStr("vi = 'Thực hiện giao dịch: Điền XDTO.
			|Lỗi đặt giá trị thuộc tính ""%1"".';
			|ru = 'Выполнение операции: Заполнение XDTO.
			|Ошибка установки значения свойства ""%1"".';
			|en = 'Performing the operation: XDTO filling.
			|An error occurred when setting the value of the ""%1"" property.'; fa = 'Performing the operation: XDTO filling.
			|An error occurred when setting the value of the ""%1"" property.';
			|it = 'Выполнение операции: Заполнение XDTO.
			|Ошибка установки значения свойства ""%1"".';
			|pl = 'Wykonanie operacji: Wypełnienie XDTO.
			|Błąd ustawienia wartości ""%1"".';
			|tr = 'İşlemin gerçekleştirilmesi: XDTO dolduruluyor.
			|""%1"" Özellik değeri ayarlanırken hata oluştu.'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, PropertyName);
		ErrorText = ?(ValueIsFilled(ErrorText), ErrorText + Chars.LF
			+ MessageText, MessageText);

		WriteToLog_(MessageText + Chars.LF + DetailErrorDescription(ErrorInfo()));
	EndTry

EndProcedure

Procedure WriteToLog_(Comment, Level = Undefined, WriteParameters = Undefined)
	
	If WriteParameters = Undefined Then
		WriteParameters = NewLogEntryOptions();
	EndIf;
	
	EventImportanceLevel = ?(TypeOf(Level) = Type("EventLogLevel"), Level,
							EventLogLevel.Error);
	FullNameOfEvent = NStr("vi = 'Kết xuất các khoản thanh toán vào ngân hàng. Tạo tệp xml.';
							|ru = 'Выгрузка платежей в банк. Формирование xml файла.';
							|en = 'Payment export to the bank. XML file generation.'; fa = 'Payment export to the bank. XML file generation.';
							|it = 'Выгрузка платежей в банк. Формирование xml файла.';
							|pl = 'Wyciąg płatności do banku. Tworzenie pliku xml.';
							|tr = 'Ödemelerin bankaya yüklenmesi. Xml dosyasının oluşturulması.'");
	WriteLogEvent(FullNameOfEvent, EventImportanceLevel, WriteParameters.MetadataObject,
		WriteParameters.Data, Comment, WriteParameters.TransactionMode);
	
EndProcedure

Function NewLogEntryOptions()
	
	Parameters = New Structure;
	Parameters.Insert("MetadataObject", Undefined);
	Parameters.Insert("Data", Undefined);
	Parameters.Insert("TransactionMode", Undefined);
	
	Return Parameters;
	
EndFunction

Procedure FillInXDTOProperty(
	XDTODataObject,
	PropertyName,
	Value,
	Required = False,
	ErrorText = "",
	SetEmptyValues = False) Export

	If TypeOf(Value) = Type("XDTODataValue")
			Or TypeOf(Value) = Type("XDTODataObject") Then
		SetXDTOValue(XDTODataObject, PropertyName, Value, ErrorText);
	Else
		If Required Or ValueIsFilled(Value)
				Or SetEmptyValues Then
			SetXDTOValue(XDTODataObject, PropertyName, Value, ErrorText);
		EndIf;
	EndIf;

EndProcedure

Function CMLObject(Factory, Path, NamespaceURI)

	If TypeOf(Path) = Type("String") Then
		ObjectType = CMLObjectType(Factory, NamespaceURI, Path);
	Else
		ObjectType = Path;
	EndIf;

	If ObjectType = Undefined Then
		Return Undefined;
	EndIf;

	NewObject = Factory.Create(ObjectType);

	Return NewObject;

EndFunction

Function CMLObjectType(Factory, NamespaceURI, Path)

	PathArray = PathElementsOfTypeXDTO(Path, ".");

	TheFirstControl = PathArray[0];
	If Left(TheFirstControl, 1) = "{" And Right(TheFirstControl, 1) = "}" Then
		PackageName_ = Mid(TheFirstControl, 2, StrLen(TheFirstControl) - 2);
		Collection = Factory.Packages.Get(PackageName_).RootProperties;
	Else
		ObjectType = Factory.Type(NamespaceURI, TheFirstControl);
		Collection = ObjectType.Properties;
	EndIf;

	PathArray.Delete(0);
	While PathArray.Count() > 0 Do

		If Collection = Undefined Then
			Return Undefined;
		EndIf;

		Property = Collection.Get(PathArray[0]);
		If Property = Undefined Then
			Return Undefined;
		EndIf;

		ObjectType = Property.Type;
		PathArray.Delete(0);
		Try
			Collection = ObjectType.Properties;
		Except
			Collection = Undefined;
		EndTry;

	EndDo;

	Return ObjectType;

EndFunction

Function PathElementsOfTypeXDTO(Val String, Separator)
	
	Result = New Array;
	If IsBlankString(String) Then
		Return Result;
	EndIf;
	
	StartingPositionOfFirstElement = StrFind(String, "{");
	ConPositionOfFirstElement = StrFind(String, "}");
	If StartingPositionOfFirstElement > 0 And ConPositionOfFirstElement > 0 Then
		TheFirstControl = Mid(String, StartingPositionOfFirstElement, ConPositionOfFirstElement);
		Result.Add(TrimAll(TheFirstControl));
		String = TrimAll(Mid(String,ConPositionOfFirstElement + 2));
	EndIf;
	
	While True Do
		Position = StrFind(String, Separator);
		If Position = 0 Then
			Break;
		EndIf;
		
		Result.Add(TrimAll(Left(String,Position - 1)));
		String = TrimAll(Mid(String,Position + 1));
	EndDo;
	
	Result.Add(TrimAll(String));
	
	Return Result;
	
EndFunction 

Procedure UnloadPaymentsVMT940(ExportingParameters, StorageAddress)

	DocumentsTable = ExportingParameters.DocumentsTable;
	
	DocumentsCount = DocumentsTable.Count();
	
	If Not DocumentsCount Then
		Return;
	EndIf;
	
	DocumentsTable.Sort("Date");
	BegPeriod = DocumentsTable[0].Date;
	NdPeriod = DocumentsTable[DocumentsCount - 1].Date;
	
	UploadBankAccounts = ExportingParameters.BankAccount;
	
	DischargeFlow = New TextDocument();
	
	AccountNumber = Common.ObjectAttributeValue(UploadBankAccounts, "AccountNumber");
	
	// Forming the title
	DischargeFlow.AddLine(":20:" + Format(CurrentSessionDate(), "DF=yyMMdd"));
	DischargeFlow.AddLine(":25:" + AccountNumber);
	
	For Each SectionLine In DocumentsTable Do
		UploadDocumentVMT940(DischargeFlow, SectionLine, AccountNumber);
	EndDo;
	
	TempFileName = GetTempFileName("txt");
	
	// We set the encoding in text, otherwise there are problems on the server in Linux and in a bundle of English-language Windows + English-language SQL.
	If ExportingParameters.Encoding = "DOS" Then
		Encoding = "cp866";		// Encoding of the text.OEM;
	Else
		Encoding = "windows-1251";	// Encoding of the text.ANSI;
	EndIf;
	
	DischargeFlow.Write(TempFileName, Encoding);
	
	PutToTempStorage(New BinaryData(TempFileName), StorageAddress);
	
	Try
		DeleteFiles(TempFileName);
	Except
		WriteLogEvent(
			NStr("vi = 'Tải lên các khoản thanh toán vào ngân hàng. Xóa tệp tạm thời';
				|ru = 'Выгрузка платежей в банк. Удаление временного файла';
				|en = 'Export payments to the bank. Delete temporary file'; fa = 'Export payments to the bank. Delete temporary file';
				|it = 'Выгрузка платежей в банк. Удаление временного файла';
				|pl = 'Eksport płatności do banku. Usunięcie pliku tymczasowego';
				|tr = 'Ödemelerin bankaya yüklenmesi. Geçici dosyayı silme'", Common.DefaultLanguageCode()),
			EventLogLevel.Error, , ,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;

EndProcedure 

Procedure UploadDocumentVMT940(DischargeFlow, SectionLine ,AccountNumber) 

	DischargeFlow.AddLine(":28From1:" 
				+ ObjectsPrefixesClientServer.NumberForPrinting(SectionLine.Number, True, True));					// Statement number/Page number
	
	NameOfCurrency = Common.ObjectAttributeValue(SectionLine.Currency, "Description");
	DischargeFlow.AddLine(":61:" 
				+ Format(CurrentSessionDate(), "DF=yyMMdd")																// YYMMDD
				+ Format(CurrentSessionDate(), "DF=MMdd")																// MMDD
				+ ?(TypeOf(SectionLine.Ref) = Type("DocumentRef.BankAccountIssue"), "C", "D")	// C–Credit, D-Debit
				+ Right(NameOfCurrency, 1)																			// The third letter of the ISO currency code
				+ Format(SectionLine.Sum, "NFD=2; NDS=.; NGS=' '; NG=0")												// Transaction amount
				+ "FTRF"																								// Transaction type Code
				+ "NONREF");																							// Client Link
									
	DischargeFlow.AddLine(":86:"
				+ ?(SectionLine.PaymentPurposes = "", "", "?20" + SectionLine.PaymentPurposes)					// Additional payment details
				+ ?(SectionLine.SwiftBankCounterparty = "",
							"?30" + SectionLine.CounterpartyBankBIC, "?30" + SectionLine.SwiftBankCounterparty)			// Identification code of the counterparty's bank
				+ "?31" + SectionLine.CounterpartyBankAccount_																// Payment counterparty's account
				+ "?32" + SectionLine.CounterpartyName);																	// Name of the counterparty

EndProcedure

Function AttributesOfPaymentParties()

	Result = New Structure;
	Result.Insert("PayerNaim");
	Result.Insert("PayerTIN");
	Result.Insert("PayerBankAccount");
	Result.Insert("PayerBank_");
	Result.Insert("BankBICPayer");
	Result.Insert("PayerCorrespondentAccount");
	Result.Insert("PayerCityOfBank");
	Result.Insert("PayerBankForSettlements");
	Result.Insert("PayerCityOfBankSRC");
	Result.Insert("BankSBICRCPayer");
	Result.Insert("PayerCorrespondentAccountOfBankSRC");
	Result.Insert("PayerBankAccountForSettlements");
	
	Result.Insert("RecipientNaim");
	Result.Insert("BeneficiaryTIN");
	Result.Insert("RecipientBankAccount");
	Result.Insert("RecipientBank_");
	Result.Insert("RecipientBankNameOfRCC");
	Result.Insert("BankSBICRecipient");
	Result.Insert("RecipientCorrespondentAccount");
	Result.Insert("RecipientCityOfBank");
	Result.Insert("RecipientBankForSettlements");
	Result.Insert("RecipientBankForSettlementsNameOfRCC");
	Result.Insert("RecipientCityOfBankSRC");
	Result.Insert("RecipientOfBankSBICRC");
	Result.Insert("RecipientCorrespondentAccountOfBankSRC");
	Result.Insert("RecipientBankAccountForSettlements");
	
	Return Result;

EndFunction

Procedure FillInAttributesOfPaymentParties(AttributesOfParties, FillingData)

	If FillingData.DocumentKind = Enums.TypesOfPaymentDocuments.PaymentDemand Then
		
		AttributesOfParties.PayerNaim = FillingData.CounterpartyName;
		AttributesOfParties.PayerTIN = FillingData.CounterpartyTIN;
		AttributesOfParties.PayerBankAccount = FillingData.CounterpartyBankAccount_;
		AttributesOfParties.PayerBank_ = FillingData.CounterpartyBank;
		AttributesOfParties.BankBICPayer = FillingData.CounterpartyBankBIC;
		AttributesOfParties.PayerCorrespondentAccount = FillingData.CounterpartyCorrBankAccount;
		AttributesOfParties.PayerCityOfBank = FillingData.CityOfCounterpartyBank;
		AttributesOfParties.PayerBankForSettlements = FillingData.CounterpartyBankForPayments;
		AttributesOfParties.PayerCityOfBankSRC = FillingData.CityOfBankSC;
		AttributesOfParties.BankSBICRCPayer = FillingData.CounterpartyBankBICProcessingCentre;
		AttributesOfParties.PayerCorrespondentAccountOfBankSRC = FillingData.CorrAccountOfBankSC;
		AttributesOfParties.PayerBankAccountForSettlements = FillingData.CounterpartyBankAccountForSettlements;
		
		AttributesOfParties.RecipientNaim = FillingData.CompanyHiring;
		AttributesOfParties.BeneficiaryTIN = FillingData.CompanyTIN;
		AttributesOfParties.RecipientBankAccount = FillingData.CompanyBankAccount_;
		AttributesOfParties.RecipientBank_ = FillingData.CompanyBank;
		AttributesOfParties.RecipientBankNameOfRCC = FillingData.CompanyBankNameCSC;
		AttributesOfParties.BankSBICRecipient = FillingData.CompanyBankBIC;
		AttributesOfParties.RecipientCorrespondentAccount = FillingData.CompanyAccount;
		AttributesOfParties.RecipientCityOfBank = FillingData.CompanyCityOfBank;
		AttributesOfParties.RecipientBankForSettlements = FillingData.CompanyBankForPayments;
		AttributesOfParties.RecipientBankForSettlementsNameOfRCC = FillingData.CompanyTransferBankNameCSC;
		AttributesOfParties.RecipientCityOfBankSRC = FillingData.CompanyCityOfBankSC;
		AttributesOfParties.RecipientOfBankSBICRC = FillingData.CompanyBankBICProcessingCentre;
		AttributesOfParties.RecipientCorrespondentAccountOfBankSRC = FillingData.CompanyCorrAccountOfBankSC;
		AttributesOfParties.RecipientBankAccountForSettlements = FillingData.OrganizationBankAccountForSettlements;
		
	Else
		
		AttributesOfParties.PayerNaim = FillingData.CompanyHiring;
		AttributesOfParties.PayerTIN = FillingData.CompanyTIN;
		AttributesOfParties.PayerBankAccount = FillingData.CompanyBankAccount_;
		AttributesOfParties.PayerBank_ = FillingData.CompanyBank;
		AttributesOfParties.BankBICPayer = FillingData.CompanyBankBIC;
		AttributesOfParties.PayerCorrespondentAccount = FillingData.CompanyAccount;
		AttributesOfParties.PayerCityOfBank = FillingData.CompanyCityOfBank;
		AttributesOfParties.PayerBankForSettlements = FillingData.CompanyBankForPayments;
		AttributesOfParties.PayerCityOfBankSRC = FillingData.CompanyCityOfBankSC;
		AttributesOfParties.BankSBICRCPayer = FillingData.CompanyBankBICProcessingCentre;
		AttributesOfParties.PayerCorrespondentAccountOfBankSRC = FillingData.CompanyCorrAccountOfBankSC;
		AttributesOfParties.PayerBankAccountForSettlements = FillingData.OrganizationBankAccountForSettlements;
		
		AttributesOfParties.RecipientNaim = FillingData.CounterpartyName;
		AttributesOfParties.BeneficiaryTIN = FillingData.CounterpartyTIN;
		AttributesOfParties.RecipientBankAccount = FillingData.CounterpartyBankAccount_;
		AttributesOfParties.RecipientBank_ = FillingData.CounterpartyBank;
		AttributesOfParties.RecipientBankNameOfRCC = FillingData.CounterpartyBankPaymentProcessingCentre;
		AttributesOfParties.BankSBICRecipient = FillingData.CounterpartyBankBIC;
		AttributesOfParties.RecipientCorrespondentAccount = FillingData.CounterpartyCorrBankAccount;
		AttributesOfParties.RecipientCityOfBank = FillingData.CityOfCounterpartyBank;
		AttributesOfParties.RecipientBankForSettlements = FillingData.CounterpartyBankForPayments;
		AttributesOfParties.RecipientBankForSettlementsNameOfRCC = FillingData.CounterpartyBankForPaymentsPaymentProcessingCentre;
		AttributesOfParties.RecipientCityOfBankSRC = FillingData.CityOfBankSC;
		AttributesOfParties.RecipientOfBankSBICRC = FillingData.CounterpartyBankBICProcessingCentre;
		AttributesOfParties.RecipientCorrespondentAccountOfBankSRC = FillingData.CorrAccountOfBankSC;
		AttributesOfParties.RecipientBankAccountForSettlements = FillingData.CounterpartyBankAccountForSettlements;
		
	EndIf;

EndProcedure


#EndRegion


#Region Load

Procedure ReadISO20022StatementData(FileBinaryData, Result)
	
	Try
		XMLObject = New XMLReader;
		MemoryStream = FileBinaryData.OpenStreamForRead();
		XMLObject.OpenStream(MemoryStream);
		XMLObject.Read();
		Ed__ = XDTOFactory.ReadXML(XMLObject);
		
		
		If TypeOf(Ed__.BkToCstmrStmt.Stmt) = Type("XDTODataObject") Then
			Extracts = New Array;
			Extracts.Add(Ed__.BkToCstmrStmt.Stmt);
		Else
			Extracts = Ed__.BkToCstmrStmt.Stmt;
		EndIf;
		DateCreatedByString = XDTOPropertyValue(Ed__, "BkToCstmrStmt.GrpHdr.CreDtTm");
		Result.Title.CreationDate = XMLValue(Type("Date"), DateCreatedByString);
		
		For Each Statement_ In Extracts Do
			CurrentAccountData = CashClientServer.CurrentAccountData_();
			CurrentAccountData.StartDate = XMLValue(Type("Date"), Statement_.FrToDt.FrDtTm);
			CurrentAccountData.EndDate = XMLValue(Type("Date"), Statement_.FrToDt.ToDtTm);
			AccountHolderDetails = AccountHolderDetails(Statement_.Acct);
			CurrentAccountData.CreateAccount_1 = AccountHolderDetails.AccountNumber;
			Result.Title.Sender = XDTOPropertyValue(AccountHolderDetails, "Svcr.FinInstnId.Nm");
			Result.Title.StartDate = CurrentAccountData.StartDate;
			Result.Title.EndDate = CurrentAccountData.EndDate;
			
			ReadBalancesAndRevolutionsISO20022(Statement_, CurrentAccountData);
			
			Result.SettlementAccounts.Add(CurrentAccountData);
			SetOfStatementProperties = Statement_.Properties(); // XDTOPropertyCollection
			If SetOfStatementProperties.Get("Ntry") <> Undefined Then
				If TypeOf(Statement_.Ntry) = Type("XDTODataObject") Then
					Operations = New Array;
					Operations.Add(Statement_.Ntry);
				Else
					Operations = Statement_.Ntry;
				EndIf;
				For Each Operation In Operations Do
					ReadISO20022Operation(Operation, Result.StatementDocuments, AccountHolderDetails);
				EndDo;
			EndIf;
		EndDo
	Except
		Result.ParsingErrors.Add(BriefErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

Function AccountHolderDetails(Acct)
			
	AccountHolder = New Structure;
	IBANCode = XDTOPropertyValue(Acct, "Id.IBAN");
	IDCode = XDTOPropertyValue(Acct, "Id.Othr.Id");
	AccountHolder.Insert("AccountNumber", ?(ValueIsFilled(IBANCode), IBANCode, IDCode));
	AccountHolder.Insert("Description", XDTOPropertyValue(Acct, "Ownr.Nm"));
	OrgIdPayer = XDTOPropertyValue(Acct, "Ownr.Id.OrgId.Othr.Id");
	PrvtIdPayer = XDTOPropertyValue(Acct, "Ownr.Id.PrvtId.Othr.Id");
	AccountHolder.Insert("TIN", ?(ValueIsFilled(OrgIdPayer), OrgIdPayer, PrvtIdPayer));
	AccountHolder.Insert("Country", XDTOPropertyValue(Acct, "Ownr.PstlAdr.Ctry"));
	AccountHolder.Insert("SWIFTBank", XDTOPropertyValue(Acct, "Svcr.FinInstnId.BIC"));
	AccountHolder.Insert("Bank", XDTOPropertyValue(Acct, "Svcr.FinInstnId.Nm"));
	
	Return AccountHolder
			
EndFunction

Procedure ReadBalancesAndRevolutionsISO20022(Statement_, CurrentAccountData)
	
	// Balance
	If TypeOf(Statement_.Bal) = Type("XDTODataObject") Then
		Balances = New Array;
		Balances.Add(Statement_.Bal);
	Else
		Balances = Statement_.Bal;
	EndIf;
	For Each Balance In Balances Do
		
		SetOfCdOrPrtryProperties = Balance.Tp.CdOrPrtry.Properties(); // XDTOPropertyCollection
		If SetOfCdOrPrtryProperties.Get("Cd") <> Undefined Then
			SumByLine = Balance.Amt.Sequence().GetText(0);
			If Balance.Tp.CdOrPrtry.Cd = "OPBD" Then
				CurrentAccountData.OpeningBalance = XMLValue(Type("Number"), SumByLine);
			ElsIf Balance.Tp.CdOrPrtry.Cd = "CLBD" Then
				CurrentAccountData.ClosingBalance = XMLValue(Type("Number"), SumByLine);
			EndIf;
		EndIf;
	EndDo;
	
	// Turnovers
	SetOfStatementProperties = Statement_.Properties(); // XDTOPropertyCollection
	If SetOfStatementProperties.Get("TxsSummry") <> Undefined Then
		
		SetOfTxsSummryProperties = Statement_.TxsSummry.Properties(); // XDTOPropertyCollection
		If SetOfTxsSummryProperties.Get("TtlCdtNtries") <> Undefined Then
			
			TtlCdtNtriesPropertySet = Statement_.TxsSummry.TtlCdtNtries.Properties(); // XDTOPropertyCollection
			If TtlCdtNtriesPropertySet.Get("Sum") <> Undefined Then
				CurrentAccountData.TotalReceived_ = XMLValue(Type("Number"), Statement_.TxsSummry.TtlCdtNtries.Sum);
			EndIf;
			
		EndIf;
		
		If SetOfTxsSummryProperties.Get("TtlDbtNtries") <> Undefined Then
			
			TtlDbtNtriesPropertySet = Statement_.TxsSummry.TtlDbtNtries.Properties(); // XDTOPropertyCollection
			If TtlDbtNtriesPropertySet.Get("Sum") <> Undefined Then
				CurrentAccountData.TotalDebited = XMLValue(Type("Number"), Statement_.TxsSummry.TtlDbtNtries.Sum);
			EndIf;
			
		EndIf;
	EndIf;
	
EndProcedure

Procedure ReadISO20022Operation(Operation, StatementDocuments, AccountHolderDetails)
			
	// If the payment is not executed, it is skipped
	If Operation.Sts <> "BOOK" Then
		Return;
	EndIf;
	OperationData = CashServer.LoadedOperationData();
	SumByLine = Operation.Amt.Sequence().GetText(0);
	OperationData.Sum = XMLValue(Type("Number"), SumByLine);
	OperationData.PaymentDirection = ?(Operation.CdtDbtInd = "DBIT", "1", "2");
	DateOfTransaction = XDTOPropertyValue(Operation, "BookgDt.Dt");
	If DateOfTransaction <> Undefined Then
		OperationData.DateOfTransaction = XMLValue(Type("Date"), DateOfTransaction);
	EndIf;
	DocumentDate = XDTOPropertyValue(Operation, "ValDt.Dt");
	If DocumentDate <> Undefined Then
		OperationData.Date = XMLValue(Type("Date"), DocumentDate);
	Else
		OperationData.Date = OperationData.DateOfTransaction;
	EndIf;
	OperationData.Id = XDTOPropertyValue(Operation, "AcctSvcrRef");
	OperationData.Insert("PaymentKind_", XDTOPropertyValue(Operation, "BkTxCd.Prtry.Cd"));
	SetOfOperationProperties = Operation.Properties(); // XDTOPropertyCollection
	If SetOfOperationProperties.Get("NtryDtls") <> Undefined Then
		
		If TypeOf(Operation.NtryDtls) = Type("XDTODataObject") Then
			Transaction = Operation.NtryDtls;
		Else
			Transaction = Operation.NtryDtls[0];
		EndIf;
		SetOfTransactionProperties = Transaction.Properties(); // XDTOPropertyCollection
		If SetOfTransactionProperties.Get("TxDtls") <> Undefined Then
			If TypeOf(Transaction.TxDtls) = Type("XDTODataObject") Then
				TransactionDetail = Transaction.TxDtls;
			Else
				TransactionDetail = Transaction.TxDtls[0];
			EndIf;
			OperationData.Number = XDTOPropertyValue(TransactionDetail, "Refs.EndToEndId");
			RankingInPriorityOfPayment = XDTOPropertyValue(TransactionDetail, "Purp.Prtry");
			If ValueIsFilled(RankingInPriorityOfPayment) Then
				OperationData.Insert("RankingInPriorityOfPayment", Number(RankingInPriorityOfPayment));
			EndIf;
			
			ReadISO20022PayerData(TransactionDetail, OperationData, AccountHolderDetails);
			ReadISO20022RecipientData(TransactionDetail, OperationData, AccountHolderDetails);
		
			ReadISO20022PaymentCodeAndPurpose(TransactionDetail, OperationData);
			
			ReadTaxDetailsOfRussianFederation(OperationData, TransactionDetail);
			
		EndIf;
	EndIf;
	
	StatementDocuments.Add(OperationData);
		
EndProcedure

Procedure ReadTaxDetailsOfRussianFederation(OperationData, TransactionDetail)
	
	// The code of the customs authority for customs payments
	OperationData.Insert("PeriodIndicator", XDTOPropertyValue(TransactionDetail, "Tax.Cdtr.RegnId"));
	OperationData.Insert("BeneficiaryCRTR", XDTOPropertyValue(TransactionDetail, "Tax.Cdtr.TaxTp"));
	OperationData.Insert("KPPPayer", XDTOPropertyValue(TransactionDetail, "Tax.Dbtr.TaxTp"));
	OperationData.Insert("RNCPS", XDTOPropertyValue(TransactionDetail, "Tax.AdmstnZn"));
	OperationData.Insert("NumberIndicator", XDTOPropertyValue(TransactionDetail, "Tax.RefNb"));
	DateIndicatorByString = XDTOPropertyValue(TransactionDetail, "Tax.Dt");
	If ValueIsFilled(DateIndicatorByString) Then
		OperationData.Insert("IndicatorDocDate", XMLValue(Type("Date"), DateIndicatorByString));
		OperationData.Insert("DateIndicator", DateIndicatorByString);
	EndIf;
	TransactionProperties = TransactionDetail.Properties(); // XDTOPropertyCollection
	If TransactionProperties.Get("Rcrd") <> Undefined Then
		If TypeOf(TransactionDetail.Rcrd) = Type("XDTODataObject") Then
			AdditionalDetails_0 = TransactionDetail.Rcrd;
		Else
			AdditionalDetails_0 = TransactionDetail.Rcrd[0];
		EndIf;
		OperationData.Insert("TypeIndicator", XDTOPropertyValue(AdditionalDetails_0, "Tp"));
		OperationData.Insert("BasisIndicator", XDTOPropertyValue(AdditionalDetails_0, "Ctgy"));
		OperationData.Insert("IndicatorBCC", XDTOPropertyValue(AdditionalDetails_0, "CtgyDtls"));
		OperationData.Insert("AuthorStatus", XDTOPropertyValue(AdditionalDetails_0, "DbtrSts"));
		YearOfTaxPeriodByLine = XDTOPropertyValue(AdditionalDetails_0, "Prd.Yr");
		If ValueIsFilled(YearOfTaxPeriodByLine) Then
			DateOfTaxPeriod = XMLValue(Type("Date"), YearOfTaxPeriodByLine);
			TypeOfTaxPeriod = XDTOPropertyValue(AdditionalDetails_0, "Prd.Tp");
			If ValueIsFilled(TypeOfTaxPeriod) Then
				If StrStartsWith(TypeOfTaxPeriod, "MM") Then
					PeriodIndicator = "MS." + Mid(TypeOfTaxPeriod, 3) + Year(DateOfTaxPeriod);
				ElsIf StrStartsWith(TypeOfTaxPeriod, "HLF") Then
					PeriodIndicator = "PL_.0" + Mid(TypeOfTaxPeriod, 4) + Year(DateOfTaxPeriod);
				ElsIf StrStartsWith(TypeOfTaxPeriod, "QTR") Then
					PeriodIndicator = "KV.0" + Mid(TypeOfTaxPeriod, 4) + Year(DateOfTaxPeriod);
				EndIf;
			Else
				PeriodIndicator = Format(DateOfTaxPeriod, "DF=dd.MM.yyyy;");
			EndIf;
			OperationData.Insert("PeriodIndicator", PeriodIndicator);
		EndIf;
		ExactDate = XDTOPropertyValue(AdditionalDetails_0, "Prd.FrToDt.FrDt");
		If ValueIsFilled(ExactDate) Then
			OperationData.Insert("PeriodIndicator", Format(ExactDate, "DF=dd.MM.yyyy;"));
		EndIf;
	EndIf;

EndProcedure

Procedure ReadISO20022PaymentCodeAndPurpose(TransactionDetail, OperationData)
		
		Document_Details = XDTOPropertyValue(TransactionDetail, "RmtInf");
		
		If Document_Details <> Undefined Then // document details
		
			DocumentProperties = Document_Details.Properties(); // XDTOPropertyCollection
			
			If DocumentProperties.Get("Ustrd") <> Undefined Then // Purpose of payment
				If TypeOf(Document_Details.Ustrd) = Type("String") Then
					PurposeOfPayment = New Array;
					PurposeOfPayment.Add(Document_Details.Ustrd);
				Else
					PurposeOfPayment = Document_Details.Ustrd;
				EndIf;
				FullPurposeOfPayment = "";
				For Each PaymentPurposes In PurposeOfPayment Do
					FullPurposeOfPayment = ?(IsBlankString(FullPurposeOfPayment), "",
												FullPurposeOfPayment + Chars.LF);
					FullPurposeOfPayment = FullPurposeOfPayment + PaymentPurposes;
				EndDo;
				OperationData.PaymentPurposes = FullPurposeOfPayment;
			EndIf;
			
			If DocumentProperties.Get("Strd") <> Undefined Then
				If TypeOf(Document_Details.Strd) = Type("XDTODataObject") Then
					StructuralDetails_ = Document_Details.Strd;
				Else
					StructuralDetails_ = Document_Details.Strd[0];
				EndIf;
				OperationData.Insert("Code", XDTOPropertyValue(StructuralDetails_, "CdtrRefInf.Ref"));
			EndIf;
		EndIf;
		
EndProcedure

Procedure ReadISO20022PayerData(TransactionDetail, OperationData, AccountHolderDetails)
		
	Debtor = XDTOPropertyValue(TransactionDetail, "RltdPties.Dbtr");
	If Debtor = Undefined And OperationData.PaymentDirection = "1" Then
		OperationData.Payer = AccountHolderDetails.Description;
		OperationData.PayerTIN = AccountHolderDetails.TIN;
		OperationData.PayerCountry = AccountHolderDetails.Country;
		OperationData.PayerAccount = AccountHolderDetails.AccountNumber;
		OperationData.PayerSWIFTBank = AccountHolderDetails.SWIFTBank;
		OperationData.PayerBank_ = AccountHolderDetails.Bank;
	Else
		OperationData.Payer = XDTOPropertyValue(TransactionDetail, "RltdPties.Dbtr.Nm");
		PayerId = XDTOPropertyValue(TransactionDetail, "RltdPties.Dbtr.Id.OrgId.Othr.Id");
		BICPayer = XDTOPropertyValue(TransactionDetail, "RltdPties.Dbtr.Id.OrgId.BICOrBEI");
		OperationData.PayerTIN = ?(ValueIsFilled(PayerId), PayerId, BICPayer);
	
		CountryCode = XDTOPropertyValue(TransactionDetail, "RltdPties.Dbtr.CtryOfRes");
		If ValueIsFilled(CountryCode) Then
			CountryInformation = ContactsManager.WorldCountryClassifierDataByCode(
				CountryCode, "CodeAlpha2");
			If ValueIsFilled(CountryInformation) Then
				OperationData.PayerCountry = CountryInformation.Description;
			EndIf;
		EndIf;
	
		AccountNumber = XDTOPropertyValue(TransactionDetail, "RltdPties.DbtrAcct.Id.Othr.Id");
		IBANCode = XDTOPropertyValue(TransactionDetail, "RltdPties.DbtrAcct.Id.IBAN");
		OperationData.PayerAccount = ?(ValueIsFilled(AccountNumber), AccountNumber, IBANCode);
		OperationData.PayerSWIFTBank = XDTOPropertyValue(TransactionDetail, "RltdAgts.DbtrAgt.FinInstnId.BIC");
		OperationData.PayerBank_ = XDTOPropertyValue(TransactionDetail, "RltdAgts.DbtrAgt.FinInstnId.Nm");
	EndIf;
	
EndProcedure

Procedure ReadISO20022RecipientData(TransactionDetail, OperationData, AccountHolderDetails)
		
	Lender = XDTOPropertyValue(TransactionDetail, "RltdPties.Cdtr");
	If Lender = Undefined And OperationData.PaymentDirection = "2" Then
		OperationData.Recipient = AccountHolderDetails.Description;
		OperationData.BeneficiaryTIN = AccountHolderDetails.TIN;
		OperationData.RecipientCountry = AccountHolderDetails.Country;
		OperationData.BeneficiaryAccount = AccountHolderDetails.AccountNumber;
		OperationData.RecipientSWIFTBank = AccountHolderDetails.SWIFTBank;
		OperationData.RecipientBank_ = AccountHolderDetails.Bank;
	Else
		OperationData.Recipient = XDTOPropertyValue(TransactionDetail, "RltdPties.Cdtr.Nm");
		RecipientId = XDTOPropertyValue(TransactionDetail, "RltdPties.Cdtr.Id.OrgId.Othr.Id");
		BICRecipient = XDTOPropertyValue(TransactionDetail, "RltdPties.Cdtr.Id.OrgId.BICOrBEI");
		OperationData.BeneficiaryTIN = ?(ValueIsFilled(RecipientId), RecipientId, BICRecipient);
		
		CountryCode = XDTOPropertyValue(TransactionDetail, "RltdPties.Cdtr.CtryOfRes");
		If ValueIsFilled(CountryCode) Then
			CountryInformation = ContactsManager.WorldCountryClassifierDataByCode(
				CountryCode, "CodeAlpha2");
			If ValueIsFilled(CountryInformation) Then
				OperationData.RecipientCountry = CountryInformation.Description;
			EndIf;
		EndIf;
		
		AccountNumber = XDTOPropertyValue(TransactionDetail, "RltdPties.CdtrAcct.Id.Othr.Id");
		IBANCode = XDTOPropertyValue(TransactionDetail, "RltdPties.CdtrAcct.Id.IBAN");
		OperationData.BeneficiaryAccount = ?(ValueIsFilled(AccountNumber), AccountNumber, IBANCode);
		
		OperationData.RecipientSWIFTBank = XDTOPropertyValue(TransactionDetail, "RltdAgts.CdtrAgt.FinInstnId.BIC");
		OperationData.RecipientBank_ = XDTOPropertyValue(TransactionDetail, "RltdAgts.CdtrAgt.FinInstnId.Nm");
	EndIf;

EndProcedure

Function XDTOPropertyValue(XDTODataObject, Path)
	
	If TypeOf(XDTODataObject) <> Type("XDTODataObject") Then
		Return Undefined;
	EndIf;
	
	RowsArray = StringFunctionsClientServer.SplitStringIntoWordArray(Path, ".");
	
	PropertiesCollection = XDTODataObject.Properties(); // XDTOPropertyCollection
	
	If PropertiesCollection.Get(RowsArray[0]) = Undefined Then
		Return Undefined
	EndIf;
	
	If RowsArray.Count() = 1 Then
		Value = XDTODataObject[RowsArray[0]];
		If TypeOf(Value) = Type("XDTODataObject") And Value.Properties().Count() = 0 Then
			Return Undefined;
		EndIf;
		Return Value;
	Else
		PropertiesSet = XDTODataObject.Properties(); // XDTOPropertyCollection
		Property = PropertiesSet.Get(RowsArray[0]);
		If Property = Undefined Then
			Return Undefined;
		EndIf;
		If Property.UpperBound = 1 Then
			UnderXDTOObject = XDTODataObject.GetXDTO(Property);
		Else
			List = XDTODataObject.GetList(Property);
			If List.Count() = 0 Then
				Return Undefined;
			Else
				UnderXDTOObject = List[0];
			EndIf;
		EndIf;
		RowsArray.Delete(0);
		NewRow = "";
		For Each Item In RowsArray Do
			NewRow = NewRow + ?(IsBlankString(NewRow), "", ".") + Item;
		EndDo;
		Return XDTOPropertyValue(UnderXDTOObject, NewRow);
	EndIf;
	
EndFunction

Procedure ReadMT940StatementData(FileBinaryData, Result, Encoding)

	Try
		FileName = GetTempFileName();
		FileBinaryData.Write(FileName);
		
		FileLines = New Array;
		
		StatementFile = New File(FileName);
		
		If Encoding = "DOS" Then
			FileEncoding = "cp866";        // Encoding of the text.OEM;
		Else
			FileEncoding = "windows-1251"; // Encoding of the text.ANSI;
		EndIf;
		
		ReaderStream = New TextReader(FileName, FileEncoding,,, False);
		
		TextToParse = ReaderStream.Read();
		
		ArrayOfExtractPages = StringFunctionsClientServer.SplitStringIntoSubstringsArray(TextToParse, ":20:");
		
		For StatementArrayString = 0 To ArrayOfExtractPages.Count() - 1 Do
			
			CurrentAccountData = CashClientServer.CurrentAccountData_();
			
			CurrentStatementBlock = ArrayOfExtractPages.Get(StatementArrayString);
			
			If Left(CurrentStatementBlock, 3) = "{1:" Or CurrentStatementBlock = "" Then
				Continue;
			EndIf;
			
			StringWithTag25 = StrGetLine(CurrentStatementBlock, 2);
			
			If StrFind(StringWithTag25, ":25:") Then
				If StrFind(StringWithTag25, "/") Then
					CurrentAccountData.CreateAccount_1 = TrimAll(Mid(StringWithTag25, StrFind(StringWithTag25, "/") + 1));
				Else
					CurrentAccountData.CreateAccount_1 = TrimAll(Mid(StringWithTag25, 5));
				EndIf;
			EndIf;
			
			ArrayByTag60F = StringFunctionsClientServer.SplitStringIntoSubstringsArray(CurrentStatementBlock, ":60F:");
			ArrayByTag60M = StringFunctionsClientServer.SplitStringIntoSubstringsArray(CurrentStatementBlock, ":60M:");
				
			If ArrayByTag60F.Count() > 1 Or ArrayByTag60M.Count() > 1 Then
				
				ArrayByTag60 = ?(ArrayByTag60F.Count() > 1, ArrayByTag60F, ArrayByTag60M);
				
				StringWithTag60 = StrGetLine(ArrayByTag60[1], 1);
				
				DateOfDischarge = GetMT940DischargeDate(StringWithTag60, 2);
				
				CurrencyLine = Mid(StringWithTag60, 8, 3);
				
				Balance = Number(Mid(StringWithTag60, 11));
				
				CurrentAccountData.StartDate		 = DateOfDischarge;
				CurrentAccountData.EndDate		 = DateOfDischarge;
				CurrentAccountData.OpeningBalance = Balance;
				
			EndIf;
			
			ArrayByTag62F = StringFunctionsClientServer.SplitStringIntoSubstringsArray(CurrentStatementBlock, ":62F:");
			ArrayByTag62M = StringFunctionsClientServer.SplitStringIntoSubstringsArray(CurrentStatementBlock, ":62M:");
				
			If ArrayByTag62F.Count() > 1 Or ArrayByTag62M.Count() > 1 Then
				
				ArrayByTag62 = ?(ArrayByTag62F.Count() > 1, ArrayByTag62F, ArrayByTag62M);
				
				StringWithTag62 = StrGetLine(ArrayByTag62[1], 1);
				
				Balance = Number(Mid(StringWithTag62, 11));

				CurrentAccountData.ClosingBalance = Balance;
				
			EndIf;
			
			Result.Title.Sender = CurrentAccountData.CreateAccount_1;
			Result.Title.StartDate = CurrentAccountData.StartDate;
			Result.Title.EndDate = CurrentAccountData.EndDate;
			
			Result.SettlementAccounts.Add(CurrentAccountData);
			
			ArrayByTag61 = StringFunctionsClientServer.SplitStringIntoSubstringsArray(CurrentStatementBlock, ":61:");
			
			For ArrayStringByTag61 = 0 To ArrayByTag61.Count() - 1 Do
				
				CurrentStatementLine = ArrayByTag61.Get(ArrayStringByTag61);
			
				ArrayByTag86 = StringFunctionsClientServer.SplitStringIntoSubstringsArray(CurrentStatementLine, ":86:");
				
				ReadOperationMT940(ArrayByTag86, Result.StatementDocuments, CurrentAccountData);
				
			EndDo;
			
		EndDo;
		
		FileSystem.DeleteTempFile(FileName);
		
	Except
		Result.ParsingErrors.Add(ErrorProcessing.BriefErrorDescription(ErrorInfo()));
	EndTry;

EndProcedure

Function GetMT940DischargeDate(DateInLine, InitialNumberOfSymbol);
	
	DateLine = Mid(DateInLine, InitialNumberOfSymbol, 6);
	
	Return Date("20" + Left(DateLine, 2) + Right(DateLine, 4));
	
EndFunction

Procedure ReadOperationMT940(ArrayByTag86, StatementDocuments, AccountHolderDetails)
	
	If ArrayByTag86.Count() = 1 Then
		Return;
	EndIf;
	
	Data61tags = TrimAll(ArrayByTag86.Get(0));
	
	CharCode7  = CharCode(Data61tags, 7);
	CharCode11 = CharCode(Data61tags, 11);
	
	If (CharCode7 >= 65 And CharCode7 <= 90) Then
		
		RecordType = Mid(Data61tags, 7, 1);
		DebitCreditSymbol = 7;
		
	ElsIf (CharCode11 >= 65 And CharCode11 <= 90) Then
		
		RecordType = Mid(Data61tags, 11, 1);
		DebitCreditSymbol = 11;
		
	Else
		
		Return;
		
	EndIf;
	
	CodeOfSumCountSymbol = CharCode(Data61tags, DebitCreditSymbol + 1);
	
	If (CodeOfSumCountSymbol >= 65 And CodeOfSumCountSymbol <= 90) Then
		
		SymbolOfBeginningOfCountOfSum = DebitCreditSymbol + 2;
		
	Else
		
		SymbolOfBeginningOfCountOfSum = DebitCreditSymbol + 1;
		
	EndIf;
	
	OperationData = CashServer.LoadedOperationData();
	
	NumberOfCharactersBetweenNAndComma = StrFind(Data61tags, ",") - SymbolOfBeginningOfCountOfSum;
	
	If StrFind(Data61tags, "//") > 0 Then
		Number = TrimAll(Mid(Data61tags, StrFind(Data61tags, "//") + 2));
	Else
		Number = "";
	EndIf;
	
	OperationData.DateOfTransaction 	  = GetMT940DischargeDate(Data61tags, 1);
	OperationData.Date				  = OperationData.DateOfTransaction;
	OperationData.PaymentDirection = ?(RecordType = "D", "1", "2");
	OperationData.Number			  = Number;
	Try
		OperationData.Sum		  = Number(Mid(Data61tags, SymbolOfBeginningOfCountOfSum, NumberOfCharactersBetweenNAndComma + 3));
	Except
		OperationData.Sum		  = 0;
	EndTry;
	
	LineByTag86 = StrReplace(ArrayByTag86.Get(ArrayByTag86.Count() - 1), Chars.LF, "");
	
	If StrFind(LineByTag86, "~") > 0 Then
		SearchChar = "~";
	Else
		SearchChar = "?";
	EndIf;
	
	ArrayOfStringsByTag = StringFunctionsClientServer.SplitStringIntoSubstringsArray(LineByTag86, SearchChar);
	
	StatementStructure = New Structure;
	StatementStructure.Insert("Description");
	StatementStructure.Insert("TIN");
	StatementStructure.Insert("Country");
	StatementStructure.Insert("AccountNumber");
	StatementStructure.Insert("SWIFTBank");
	StatementStructure.Insert("Bank");
	
	For Each ArrayElement In ArrayOfStringsByTag Do
		If Left(ArrayElement, 2) = "30" Then
			OperationData.Id = GetStringWithoutTag(ArrayElement);
		ElsIf Left(ArrayElement, 2) = "31" Then
			StatementStructure.AccountNumber = GetStringWithoutTag(ArrayElement); 
		ElsIf Left(ArrayElement, 2) = "32" Or Left(ArrayElement, 2) = "33" Then
			StatementStructure.Description = GetStringWithoutTag(ArrayElement);
		EndIf;
	EndDo;
	
	FillInDetailsOfPayerMT940(OperationData, StatementStructure, AccountHolderDetails);
	FillInDetailsOfRecipientMT940(OperationData, StatementStructure, AccountHolderDetails);
	
	StatementDocuments.Add(OperationData);
	
EndProcedure

Procedure FillInDetailsOfPayerMT940(OperationData, StatementStructure, AccountHolderDetails)
	
	If OperationData.PaymentDirection = "1" Then
		OperationData.Payer = "";
		OperationData.PayerTIN = "";
		OperationData.PayerCountry = "";
		OperationData.PayerAccount = AccountHolderDetails.CreateAccount_1;
		OperationData.PayerSWIFTBank = "";
		OperationData.PayerBank_ = "";
	Else
		OperationData.Payer = StatementStructure.Description;
		OperationData.PayerTIN = StatementStructure.TIN;
		OperationData.PayerCountry = StatementStructure.Country;
		OperationData.PayerAccount = StatementStructure.AccountNumber;
		OperationData.PayerSWIFTBank = StatementStructure.SWIFTBank;
		OperationData.PayerBank_ = StatementStructure.Bank;
	EndIf;
	
EndProcedure

Procedure FillInDetailsOfRecipientMT940(OperationData, StatementStructure, AccountHolderDetails)
	
	If OperationData.PaymentDirection = "2" Then
		OperationData.Recipient = "";
		OperationData.BeneficiaryTIN = "";
		OperationData.RecipientCountry = "";
		OperationData.BeneficiaryAccount = AccountHolderDetails.CreateAccount_1;
		OperationData.RecipientSWIFTBank = "";
		OperationData.RecipientBank_ = "";
	Else
		OperationData.Recipient = StatementStructure.Description;
		OperationData.BeneficiaryTIN = StatementStructure.TIN;
		OperationData.RecipientCountry = StatementStructure.Country;
		OperationData.BeneficiaryAccount = StatementStructure.AccountNumber;
		OperationData.RecipientSWIFTBank = StatementStructure.SWIFTBank;
		OperationData.RecipientBank_ = StatementStructure.Bank;
	EndIf;

EndProcedure


Function GetStringWithoutTag(StringWithTag)
	
	Return(Right(StringWithTag, StrLen(StringWithTag) - 2));
	
EndFunction

Procedure UncheckEventFlag(DocumentsToImport, BankAccount, StatementTitle)
	
	// We remove the sign of the bank for missing documents in the statement
	Query = New Query;
	Query.Text = "
	|SELECT
	|	DocumentData.Ref AS Ref
	|FROM
	|	Document.BankAccountReceiptNote AS DocumentData
	|WHERE
	|	DocumentData.ProcessedByBank
	|	AND DocumentData.BankAccount = &BankAccount
	|	AND DocumentData.BankPostingDate BETWEEN &StrtDate AND &FinishDate
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref
	|FROM
	|	Document.BankAccountIssue AS DocumentData
	|WHERE
	|	DocumentData.ProcessedByBank
	|	AND DocumentData.BankAccount = &BankAccount
	|	AND DocumentData.BankPostingDate BETWEEN &StrtDate AND &FinishDate
	|";
	
	Query.SetParameter("StrtDate", BegOfDay(StatementTitle.StartDate));
	Query.SetParameter("FinishDate", EndOfDay(StatementTitle.EndDate));
	Query.SetParameter("BankAccount", BankAccount);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		RowInImportTable = DocumentsToImport.FindRows(New Structure("Document", Selection.Ref));
		If RowInImportTable.Count() = 0 Then
			
			Try
				
				DocumentObject = Selection.Ref.GetObject(); // DocumentObject
				DocumentObject.ProcessedByBank = False;
				DocumentObject.BankPostingDate = Undefined;
				DocumentObject.AdditionalProperties.Insert("EDIWithBanks", True);
				DocumentObject.Write(DocumentWriteMode.UndoPosting);
				
			Except
				
				ErrorDescription = ErrorInfo();
				Event = NStr("vi = 'Dữ liệu';
							|ru = 'Данные';
							|en = 'Data'; fa = 'داده';
							|it = 'Данные';
							|pl = 'Dane';
							|tr = 'Veriler'", Common.DefaultLanguageCode())
					+ "." + NStr("vi = 'Hủy bỏ';
								|ru = 'Отмена проведения';
								|en = 'Cancel posting'; fa = 'لغو ثبت';
								|it = 'Отмена проведения';
								|pl = 'Anuluj księgowanie';
								|tr = 'Gönderim iptali'", Common.DefaultLanguageCode());
				WriteLogEvent(Event,
					EventLogLevel.Error,
					Selection.Ref.Metadata(),
					Selection.Ref,
					ErrorDescription.Description);
			EndTry;
		EndIf;
	EndDo;
	
EndProcedure

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

Procedure RecordAccountBalancesBasedOnStatementData(BankAccount, AccountAttributes, StatementData, ImportStartDate, ImportEndDate)
	
	If StatementData <> Undefined Then
		
		SettlementAccounts = StatementData.SettlementAccounts;
		AccountNumber = AccountAttributes.AccountNumber;
		PersonalAccountNumber = "";
		PersonalAccountSection = "";
		
		
		For Each SettlementAccount In SettlementAccounts Do
			
			SamePersonalAccountNumber =
				StructureKeyAndAccountAttributesMatch(PersonalAccountNumber, SettlementAccount, "PersonalAccountNumber");
			SameSectionOfPersonalAccount =
				StructureKeyAndAccountAttributesMatch(PersonalAccountSection, SettlementAccount, "PersonalAccountSection");
			
			If AccountNumber = SettlementAccount.CreateAccount_1
				And SamePersonalAccountNumber
				And SameSectionOfPersonalAccount Then
				
				WriteParameters = New Structure;
				
				OpeningBalance = CashClientServer.ConvertToNumber(SettlementAccount.OpeningBalance);
				ClosingBalance = CashClientServer.ConvertToNumber(SettlementAccount.ClosingBalance);
				Inpayment = CashClientServer.ConvertToNumber(SettlementAccount.TotalReceived_);
				WriteOff = CashClientServer.ConvertToNumber(SettlementAccount.TotalDebited);
				
				StartDate = CashClientServer.GetDateFromString(SettlementAccount.StartDate);
				EndDate = CashClientServer.GetDateFromString(SettlementAccount.EndDate);
				
				If Not ValueIsFilled(StartDate) Then
					StartDate = ImportStartDate;
				EndIf;
				
				If Not ValueIsFilled(EndDate) Then
					EndDate = ImportEndDate;
				EndIf;
				
				If ValueIsFilled(StartDate) And ValueIsFilled(EndDate)
					And BegOfDay(StartDate) = BegOfDay(EndDate) Then
					
					WriteParameters.Insert("OpeningBalance", OpeningBalance);
					WriteParameters.Insert("Inpayment", Inpayment);
					WriteParameters.Insert("WriteOff", WriteOff);
					WriteParameters.Insert("ClosingBalance", ClosingBalance);
					
					InformationRegisters.BankAccountBalanceAccordingToStatementData.CreateEntry(
						StartDate, BankAccount, WriteParameters);
				ElsIf ValueIsFilled(StartDate) And ValueIsFilled(EndDate) Then
					
					While StartDate <= EndDate Do
						
						Inpayment = 0;
						WriteOff = 0;
						
						For Each DocumentLine In StatementData.StatementDocuments Do
							
							If Not StructureKeyAndAccountAttributesMatch(PersonalAccountSection, DocumentLine, "AnalyticalSectionCode") Then
								Continue;
							EndIf;
							
							DocumentAmount = StringFunctionsClientServer.StringToNumber(DocumentLine.Sum);
							
							If DocumentLine.PayerAccount = AccountNumber
								And StructureKeyAndAccountAttributesMatch(PersonalAccountNumber, DocumentLine, "PayerPersonalAccount") Then
								
								DateOfDeduction = CashClientServer.GetDateFromString(DocumentLine.DepartureDate);
								
								If StartDate = DateOfDeduction Then
									WriteOff = WriteOff + ?(DocumentAmount = Undefined, 0, DocumentAmount);
								EndIf;
								
							EndIf;
							
							If DocumentLine.BeneficiaryAccount = AccountNumber
								And StructureKeyAndAccountAttributesMatch(PersonalAccountNumber, DocumentLine, "PayeePersonalAccount") Then
								
								DateOfReceipt = CashClientServer.GetDateFromString(DocumentLine.ArrivalDate_);
								
								If StartDate = DateOfReceipt Then
									Inpayment = Inpayment + ?(DocumentAmount = Undefined, 0, DocumentAmount);
								EndIf;
								
							EndIf;
							
						EndDo;
						
						WriteParameters.Insert("OpeningBalance", OpeningBalance);
						WriteParameters.Insert("Inpayment", Inpayment);
						WriteParameters.Insert("WriteOff", WriteOff);
						WriteParameters.Insert("ClosingBalance", 
							?(OpeningBalance = Undefined, Undefined, OpeningBalance + Inpayment - WriteOff));
						
						InformationRegisters.BankAccountBalanceAccordingToStatementData.CreateEntry(
							StartDate, BankAccount, WriteParameters);
						
						StartDate = StartDate + 86400;
						OpeningBalance = WriteParameters.ClosingBalance;
						
					EndDo;
					
				Else
					If ValueIsFilled(StartDate) Then
						WriteParameters.Insert("OpeningBalance", OpeningBalance);
						InformationRegisters.BankAccountBalanceAccordingToStatementData.CreateEntry(
							StartDate, BankAccount, WriteParameters);
					EndIf;
					
					If ValueIsFilled(EndDate) Then
						WriteParameters.Insert("ClosingBalance", ClosingBalance);
						InformationRegisters.BankAccountBalanceAccordingToStatementData.CreateEntry(
							EndDate, BankAccount, WriteParameters);
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	Return;
	
EndProcedure

Function FindSplitPayment(DocumentsTable, DocumentLine)

	FilterParameters = CashClientServer.DocumentLineTags();
	FilterParameters.Delete("Sum");
	FilterParameters.Delete("StatementData");
	FilterParameters.Delete("MUNICIPALTERRITORIESCLASSIFIER");
	FillPropertyValues(FilterParameters, DocumentLine);
	
	For Each CurrentFilter In FilterParameters Do
		
		TableColumn2 = DocumentsTable.Columns.Find(CurrentFilter.Key);
		
		If TableColumn2 <> Undefined Then
			FilterParameters.Insert(CurrentFilter.Key, TableColumn2.ValueType.AdjustValue(CurrentFilter.Value));
		EndIf;
		
	EndDo;
	
	FoundRows = DocumentsTable.FindRows(FilterParameters);
	
	If FoundRows.Count() = 0 Then
		Return Undefined;
	Else
		Return FoundRows[0];
	EndIf;

EndFunction

Procedure CheckDuplicatePaymentsStatements(DocumentsToImport)

	DuplicatePayments = DocumentsToImport.Copy(, 
		"Outgoing, ToImport, BankAccount, Number, Date, BeneficiaryAccount, PayerAccount, BeneficiaryTIN, PayerTIN, DepartureDate, ArrivalDate_, PaymentDocumentType");
	DuplicatePayments.Columns.Add("TotalPayments", New TypeDescription("Number"));
	DuplicatePayments.FillValues(1, "TotalPayments");
	DuplicatePayments.GroupBy("Outgoing, ToImport, BankAccount, Number, Date, BeneficiaryAccount, PayerAccount, BeneficiaryTIN, PayerTIN, DepartureDate, ArrivalDate_, PaymentDocumentType", "TotalPayments");
	
	DuplicateErrors = New Array;
	
	For Each TableRow In DuplicatePayments Do
		
		If TableRow.TotalPayments > 1
			And TableRow.ToImport Then
			
			ErrorText = StrTemplate(
				NStr("vi = 'Tồn tại một số thanh toán giống nhau với số %1 ngày %2 theo tài khoản đối tác %3';
					|ru = 'Существует несколько одинаковых платежей с номером %1 от %2 по счету контрагента %3';
					|en = 'There are several identical payments with number %1 dated %2 on the ""%3"" counterparty''s account'; fa = 'There are several identical payments with number %1 dated %2 on the ""%3"" counterparty''s account';
					|it = 'There are several identical payments with number %1 dated %2 on the ""%3"" counterparty''s account';
					|pl = 'There are several identical payments with number %1 dated %2 on the ""%3"" counterparty''s account';
					|tr = '%3 cari hesabı için %2 muhasebesinden %1 numaralı birkaç aynı ödeme mevcuttur'"),
				TableRow.Number, TableRow.Date, ?(TableRow.Outgoing, TableRow.BeneficiaryAccount, TableRow.PayerAccount));
			DuplicateErrors.Add(ErrorText);
			
		EndIf;
		
	EndDo;
	
	If DuplicateErrors.Count() > 0 Then
		
		MessageText = StrConcat(DuplicateErrors, Chars.LF);
		Raise MessageText;
		
	EndIf;

EndProcedure

Function StructureKeyAndAccountAttributesMatch(AccountAttribute, CurrentStructure, KeyName)

	ThereIsStructureField = CommonClientServer.HasAttributeOrObjectProperty(CurrentStructure, KeyName);
	Return (ThereIsStructureField And AccountAttribute = CurrentStructure[KeyName])
		Or (ThereIsStructureField And CurrentStructure[KeyName] = Undefined)
		Or Not ThereIsStructureField;

EndFunction

#EndRegion


#EndRegion

#EndIf
