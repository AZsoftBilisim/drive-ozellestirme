#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
#Region Variables


#EndRegion

#Region Public

#Region Upload0

// Fills in the "Bank accounts" part of the table with account settings for uploading payments.
//
Procedure FillInUploadInvoiceTable() Export
	
	TableOfAccounts = DataProcessors.EDIWithBanks.TableOfAccounts(Undefined);
	
	
	BankAccounts.Load(TableOfAccounts);
	
EndProcedure

// Uploads payments to a file for all selected accounts
//
// Parameters:
//    FormID - UUID - ID of the form calling the method.
//
Procedure ExportPayments(FormID = "") Export
	
	Filter = New Structure("Check", True);
	UnloadedBankAccounts = BankAccounts.Unload(BankAccounts.FindRows(Filter));
	InformationAboutMergingFiles = InformationAboutMergingFiles(UnloadedBankAccounts);
	
	If InformationAboutMergingFiles.AccountsWithoutRules.Count() <> 0 Then
		// A typical algorithm for unloading invoices
		For Each Account In InformationAboutMergingFiles.AccountsWithoutRules Do
			If Not Account.Check
				Or Not ValueIsFilled(Account.ConfigureExchange)
				Or Account.Exporting
			Then
				Continue;
			EndIf;
			
			UnloadAccountPayments(Account, FormID);
		EndDo;
	EndIf;
	
	If InformationAboutMergingFiles.NumberOfAccountsInRule.Count() <> 0 Then
		// Unloading in portions, with unification according to the rules
		UploadPaymentsInChunksAccordingToRules(InformationAboutMergingFiles, FormID);
	EndIf;
	
	UpdateInformationAboutUploadedFiles(InformationAboutMergingFiles);
	
	
EndProcedure

// Uploads payments to the file in chunks according to the rules
//
// Parameters:
//    InformationAboutMergingFiles - Structure - information for the discharge of payment flows
//    FormID - UUID - ID of the form calling the method.
//
Procedure UploadPaymentsInChunksAccordingToRules(InformationAboutMergingFiles, FormID = "") Export
	
	DischargeStreams = InformationAboutMergingFiles.DischargeStreams;
	NumberOfAccountsInRule = InformationAboutMergingFiles.NumberOfAccountsInRule;
	
	For Each DischargeFlow In DischargeStreams Do
		LinesToUpload = DocumentsToBeUploadedByInvoice(DischargeFlow.Accounts);
		If LinesToUpload.Count() Then
			ExportingParameters = New Structure;
			ExportingParameters.Insert("BankAccount", DischargeFlow.Accounts[0].Ref);
			ExportingParameters.Insert("ConfigureExchange", DischargeFlow.Rule);
			ExportingParameters.Insert("Encoding", DischargeFlow.Accounts[0].Encoding);
			ExportingParameters.Insert("Application", DischargeFlow.Accounts[0].Application);
			ExportingParameters.Insert("ExchangeFormat", DischargeFlow.Accounts[0].ExchangeFormat);
			ExportingParameters.Insert("VersionOfUploadFormat", DischargeFlow.Accounts[0].VersionOfUploadFormat);
			
			DocumentsTable = DocumentsToExport.Unload(LinesToUpload);
			ExportingParameters.Insert("DocumentsTable", DocumentsTable);
			
			ChangeAccountDetails(DischargeFlow.Accounts,
				New Structure("Exported, DocumentStorageAddress", False, PutToTempStorage(DocumentsTable, FormID)));
				
			ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(FormID);
			ExecutionParameters.WaitCompletion = 0;
			ExecutionParameters.BackgroundJobDescription =
				NStr("vi = 'Tải thanh toán lên ngân hàng';
					|ru = 'Выгрузка платежей в банк';
					|en = 'Export payments to bank'; fa = 'خروج اطلاعات پرداخت‌ها به بانک';
					|it = 'Upload dei pagamenti in banca';
					|pl = 'Wyeksportowanie przelewów do banku';
					|tr = 'Ödemelerin bankaya yüklenmesi'");
		
			Result = TimeConsumingOperations.ExecuteInBackground(
				"DataProcessors.EDIWithBanks.Unload",
				ExportingParameters,
				ExecutionParameters);
			
			ChangeAccountDetails(DischargeFlow.Accounts, 
				New Structure("FileStorageAddress", Result.ResultAddress));
			
			If Result.Status = "Error" Then
				
				TextTemplate1 = NStr("vi = 'Lỗi kết xuất theo quy tắc %1:
								|%2';
								|ru = 'Ошибка выгрузки по правилу %1:
								|%2';
								|en = 'Export error by the %1 rule:
								|%2'; fa = 'Export error by the %1 rule:
								|%2';
								|it = 'Export error by the %1 rule:
								|%2';
								|pl = 'Export error by the %1 rule:
								|%2';
								|tr = '%1 kuralına göre dışa aktarırken hata:
								|%2'");
				ErrorText = StrTemplate(
					TextTemplate1, 
					DischargeFlow.Rule, 
					?(Result.ErrorInfo <> Undefined, ErrorProcessing.BriefErrorDescription(Result.ErrorInfo), ""));
				Common.MessageToUser(ErrorText);
				
			EndIf;
			
			If Result.Status <> "Error"
				And Result.Status <> "Completed2" Then
				ChangeAccountDetails(DischargeFlow.Accounts, 
					New Structure("Exporting", True));
			EndIf;
			
			If Result.Status = "Completed2" Then
				ChangeAccountDetails(DischargeFlow.Accounts, 
					New Structure("SaveFile", True));
			Else
				ChangeAccountDetails(DischargeFlow.Accounts, 
					New Structure("DataExportedID, UploadData_0",
						Result.JobID, PutToTempStorage(Result, FormID)));
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

// Uploads payments to a file for the specified invoice
//
// Parameters:
//    Account - FormDataCollectionItem - Bank account list line
//    FormID - UUID - ID of the form calling the method.
//
Procedure UnloadAccountPayments(Account, FormID = "") Export
	
	Account.Exported = False;
	
	LinesToUpload = DocumentsToBeUploadedByInvoice_(Account);
	If LinesToUpload.Count() Then
		ExportingParameters = New Structure;
		ExportingParameters.Insert("BankAccount", Account["Ref"]);
		ExportingParameters.Insert("ConfigureExchange", Account.ConfigureExchange);
		ExportingParameters.Insert("Encoding", Account.Encoding);
		ExportingParameters.Insert("Application", Account.Application);
		ExportingParameters.Insert("ExchangeFormat", Account.ExchangeFormat);
		ExportingParameters.Insert("VersionOfUploadFormat", Account.VersionOfUploadFormat);
		DocumentsTable = DocumentsToExport.Unload(LinesToUpload);
		ExportingParameters.Insert("DocumentsTable", DocumentsTable);
		
		Account.DocumentStorageAddress = PutToTempStorage(DocumentsTable, FormID);
		
		ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(FormID);
		ExecutionParameters.WaitCompletion = 0;
		ExecutionParameters.BackgroundJobDescription =
			NStr("vi = 'Tải thanh toán lên ngân hàng';
				|ru = 'Выгрузка платежей в банк';
				|en = 'Export payments to bank'; fa = 'خروج اطلاعات پرداخت‌ها به بانک';
				|it = 'Upload dei pagamenti in banca';
				|pl = 'Wyeksportowanie przelewów do banku';
				|tr = 'Ödemelerin bankaya yüklenmesi'");
	
		Result = TimeConsumingOperations.ExecuteInBackground(
			"DataProcessors.EDIWithBanks.Unload",
			ExportingParameters,
			ExecutionParameters);
		
		Account.FileStorageAddress = Result.ResultAddress;
		
		If Result.Status = "Error" Then
			
			TextTemplate1 = NStr("vi = 'Lỗi kết xuất theo tài khoản %1:
								|%2';
								|ru = 'Ошибка выгрузки по счету %1:
								|%2';
								|en = 'Export error by account %1:
								|%2'; fa = 'Export error by account %1:
								|%2';
								|it = 'Export error by account %1:
								|%2';
								|pl = 'Export error by account %1:
								|%2';
								|tr = '%1 hesabına göre dışa aktarırken hata: 
								|%2'");
			ErrorText = StrTemplate(
				TextTemplate1, Account.Ref, ?(Result.ErrorInfo <> Undefined, ErrorProcessing.BriefErrorDescription(Result.ErrorInfo), ""));
			Common.MessageToUser(ErrorText);
			
		EndIf;
		
		If Result.Status <> "Error"
			And Result.Status <> "Completed2" Then
			Account.Exporting = True;
		EndIf;
		
		If Result.Status = "Completed2" Then
			Account.SaveFile = True;
		Else
			Account.DataExportedID = Result.JobID;
			Account.UploadData_0 = PutToTempStorage(Result, FormID);
		EndIf;
	EndIf;
	
EndProcedure

// Generates a Table document with a report on uploaded payments
//
// Returns:
//    SpreadsheetDocument - upload report.
//
Function PrintingUploadReport(SelectedRows) Export
	
	ReportField = Undefined;
	
	For Each SelectedRow In SelectedRows Do
		
		If ReportField = Undefined Then
			ReportField = New SpreadsheetDocument;
			ReportField.PageOrientation = PageOrientation.Landscape;
		EndIf;
		
		Account = BankAccounts.Get(SelectedRow);
		
		If Account.Exported Then
			If IsTempStorageURL(Account.DocumentStorageAddress) Then
				UploadedDocuments = GetFromTempStorage(Account.DocumentStorageAddress);
				If UploadedDocuments <> Undefined Then
					FilterByAccount = New Structure("BankAccount", Account.Ref);
					AccountDocuments = UploadedDocuments.Copy(FilterByAccount);
					DisplayUploadReportSection(ReportField, AccountDocuments, Account.Ref, Account.Exported);
				EndIf;
			EndIf;
		Else
			Filter = New Structure;
			Filter.Insert("ToExport", True);
			Filter.Insert("BankAccount", Account.Ref);
			DocumentsToBeUploadedByInvoice_ = DocumentsToExport.Unload(Filter);
			If DocumentsToBeUploadedByInvoice_.Count() Then
				DisplayUploadReportSection(ReportField, DocumentsToBeUploadedByInvoice_, Account.Ref, Account.Exported);
			EndIf;
		EndIf;
	EndDo;
	
	Return ReportField;
	
EndFunction

// Records the upload date in the uploaded documents, information about the last upload to the Bank account.
//
Procedure RecordDatePaymentsWereUploaded() Export
	
	For Each Account In BankAccounts Do
		
		If Account.Exported Then
			If IsTempStorageURL(Account.DocumentStorageAddress) Then
				UploadedDocuments = GetFromTempStorage(Account.DocumentStorageAddress);
				If TypeOf(UploadedDocuments) = Type("ValueTable") Then
			
					For Each UploadedDocument In UploadedDocuments Do
						DocumentObject = UploadedDocument["Ref"].GetObject(); // DocumentObject
						DocumentObject.ExportDate = CurrentSessionDate();
						DocumentObject.Write();
					EndDo;
				EndIf;
			EndIf;
			
			InformationRegisters.LastEDIWithBanks.CreateEntry(Account.Ref, New Structure("ExportDate", CurrentSessionDate()));
			Account.LastExportDate = CurrentSessionDate();
		EndIf;
	EndDo;
	
EndProcedure

// Fills in the table part "Documents to be uploaded" with payment orders and requirements.
//
// Parameters:
//     DocumentsFilter - ValueTable - Table of documents to upload.
//
Procedure FillInPaymentTable(DocumentsFilter = Undefined) Export
	
	DocumentsTable = DataProcessors.EDIWithBanks.TableOfDocumentsToUpload(AccountList,
																		ExportStartDate,
																		ExportEndDate,
																		NotExportedOnly);
	
	FillInInformationAboutRecipientsPayers(DocumentsTable);
	
	DocumentsToExport.Load(DocumentsTable);
	DocumentsToExport.Sort("Date");
	
	If DocumentsFilter <> Undefined Then
		For Each DocumentForExport In DocumentsToExport Do
		
			Filter = New Structure("Ref", DocumentForExport.Ref);
			FoundRows = DocumentsFilter.FindRows(Filter);
			
			If FoundRows.Count() = 0 Then
				DocumentForExport.ToExport = False;
			EndIf;
		EndDo;
	EndIf;
	
	CheckDocumentsForUpload();
	
EndProcedure

#EndRegion

#Region Load

// Fills in the "Bank accounts" part of the table with the account settings for uploading payments.
//
// Parameters:
//  Filter - Structure, Undefined - selection for the list of accounts.
//
Procedure FillInDownloadInvoiceTable(Filter = Undefined) Export
	
	TableOfAccounts = DataProcessors.EDIWithBanks.TableOfAccounts(Filter, True);
	
	For Each Account In TableOfAccounts Do
		Account.LastStatement = Format(Account.LastImportStartDate, "DLF=D")
			+ " - "
			+ Format(Account.EndDateOfLastUpload, "DLF=D");
		Account.AccountNumber = TrimAll(Account.AccountNumber);
	EndDo;
	
	
	BankAccounts.Load(TableOfAccounts);
	
EndProcedure

// Performs the uploading of payments files for all selected accounts
//
// Parameters:
//    FormID - UUID - ID of the form calling the method.
//
Procedure ImportPayments(FormID = "") Export
	
	IsFileInfobase = Common.FileInfobase();
	
	For Each Account In BankAccounts Do
		
		If Not Account.Check Or Not ValueIsFilled(Account.ConfigureExchange) Or Account.Downloading 
			Or Account.DirectExchange Then
			Continue;
		Else
			
			ToDelete_ = New Array;
			
			FilterParameters = New Structure("BankAccount", Account.Ref);
			ListOfFiles = Files.FindRows(FilterParameters);
			
			For Each FileString In ListOfFiles Do
				
				If Not IsTempStorageURL(FileString.FileStorageAddress) Then
					ToDelete_.Add(FileString);
				EndIf;
				
			EndDo;
			
			For Each ArrayRow In ToDelete_ Do
				Files.Delete(ArrayRow);
			EndDo;
			
		EndIf;
		
		UploadInvoicePayments(Account, FormID, IsFileInfobase);
		
	EndDo;
	
EndProcedure

// Performs the uploading of payment files for the specified account
//
// Parameters:
//    Account - FormDataCollectionItem - Bank account list line
//    FormID - UUID - ID of the form calling the method.
//    SequentialLoading - Boolean - the mode of enabling sequential download.
//
Procedure UploadInvoicePayments(Account, FormID = "", SequentialLoading = False) Export
	
	ImportParameters = New Structure;
	ImportParameters.Insert("BankAccount",        Account.Ref);
	ImportParameters.Insert("DirectExchange",           Account.DirectExchange);
	ImportParameters.Insert("ImportStartDate",    Account.ImportStartDate);
	ImportParameters.Insert("ImportEndDate",     Account.ImportEndDate);
	ImportParameters.Insert("ExchangeFormat",          Account.ExchangeFormat);

	ImportParameters.Insert("CreateCounterparties", CreateCounterparties);
	ImportParameters.Insert("PostDocuments",    PostDocuments);
	ImportParameters.Insert("Encoding",             Account.Encoding);
	ImportParameters.Insert("CounterpartyFillingModeByQRPayment", CounterpartyFillingModeByQRPayment);
	
	Account.Imported = False;
	
	FilterParameters = New Structure("BankAccount", Account.Ref);
	FilesData = Files.FindRows(FilterParameters);
	
	For Each CurrentLineOfFile In FilesData Do
	
		ImportParameters.Insert("StatementLines", GetFromTempStorage(CurrentLineOfFile.FileStorageAddress));
		ImportParameters.Insert("DocumentsToImport", DocumentsToImport.UnloadColumns());
		ImportParameters.Insert("CreditingConfirmationFile", CurrentLineOfFile.CreditingConfirmationFile);
		ImportParameters.Insert("ArticlesOfCashFlowOfOperations", Undefined);
		
		ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(FormID);
		JobKey = StrTemplate("%1_%2_%3_%4_%5_%6",
			NStr("vi = 'Tải xuống sao kê ngân hàng';
				|ru = 'Загрузка выписки банка';
				|en = 'Bank statement import'; fa = 'Bank statement import';
				|it = 'Загрузка выписки банка';
				|pl = 'Pobierz wyciąg bankowy';
				|tr = 'Banka ekstresini yükleme'"),
			Account.Ref.UUID(),
			Users.CurrentUser().UUID(),
			Account.ImportStartDate,
			Account.ImportEndDate,
			New UUID);
		ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Tải xuống sao kê ngân hàng';
															|ru = 'Загрузка выписки банка';
															|en = 'Bank statement import'; fa = 'Bank statement import';
															|it = 'Загрузка выписки банка';
															|pl = 'Pobierz wyciąg bankowy';
															|tr = 'Banka ekstresini yükleme'");
		ExecutionParameters.BackgroundJobKey = JobKey;
		ExecutionParameters.WaitCompletion = 
			?(SequentialLoading, Undefined, ExecutionParameters.WaitCompletion);
	
		Result = TimeConsumingOperations.ExecuteInBackground(
			"DataProcessors.EDIWithBanks.Load",
			ImportParameters,
			ExecutionParameters);
		
		CurrentLineOfFile.DocumentStorageAddress = Result.ResultAddress;
		
		If Result.Status = "Error" Then
			DataProcessors.EDIWithBanks.OutputFileUploadError(
				Account.Ref, CurrentLineOfFile.FileName, Result.ErrorInfo);
		EndIf;
		
		If Result.Status <> "Error" Then
			Account.Downloading = True;
		EndIf;
		
		If Result.Status <> "Running" Then
			CurrentLineOfFile.SaveFile = True;
		Else
			CurrentLineOfFile.ImportID = Result.JobID;
		EndIf;
		
		Account.DownloadData = Common.ValueToXMLString(Result);
	
	EndDo;
	
	Filter = New Structure("BankAccount, SaveFile", Account.Ref, False);
	NotUploadedFiles = Files.FindRows(Filter);
	
	If NotUploadedFiles.Count() = 0 Then
		Account.Check = False;
	EndIf;
	
EndProcedure

// Generates a Table document with a report on uploaded payments
// 
// Parameters:
//  SelectedRows - Array of Number - select row.
// 
// Returns:
//  SpreadsheetDocument - download report.
Function PrintingDownloadReport(SelectedRows) Export
	
	ReportField = Undefined;
	
	For Each SelectedRow In SelectedRows Do
		
		Account = BankAccounts.Get(SelectedRow);
		
		FilterParameters = New Structure("BankAccount", Account.Ref);
		ListOfFiles = Files.FindRows(FilterParameters);
		
		UploadedDocumentsOnAccount = DocumentsToImport.UnloadColumns();
		
		For Each FileData In ListOfFiles Do
			
			If IsTempStorageURL(FileData.DocumentStorageAddress) Then
			
				UploadedDocumentsByFile = GetFromTempStorage(FileData.DocumentStorageAddress);
				
				If UploadedDocumentsByFile <> Undefined
					And TypeOf(UploadedDocumentsByFile) = Type("ValueTable")
					And UploadedDocumentsByFile.Count() Then
					TMCommonUse.AddRowsToTable(UploadedDocumentsOnAccount, UploadedDocumentsByFile);
				EndIf;
			
			EndIf;
			
		EndDo;
		
		If UploadedDocumentsOnAccount.Count() Then
			
			If ReportField = Undefined Then
				ReportField = New SpreadsheetDocument;
				ReportField.PageOrientation = PageOrientation.Landscape;
			EndIf;
			
			DisplayDownloadReportSection(ReportField, UploadedDocumentsOnAccount, Account.Ref, Account.Imported);
			
		EndIf;
		
	EndDo;
	
	Return ReportField;
	
EndFunction

#EndRegion

#EndRegion

#Region Private


#Region UploadingInChunksAccordingToPoolingRules

Function InformationAboutMergingFiles(UnloadedBankAccounts)
	
	NewThread = New Structure("Rule, Accounts");
	
	NumberOfAccountsInRule = New Map;
	DischargeStreams = New Array;
	AccountsWithoutRules = New Array;
	
	InformationAboutMergingFiles = New Structure("
		|CurRule,
		|AddressOfCurUploadStream, 
		|TotalAccountsInCurStream, 
		|UnloadedInvoicesToCurStream,
		|NumberOfAccountsInRule,
		|AccountsWithoutRules,
		|DischargeStreams");
		
	InformationAboutMergingFiles.Insert("CurRule", "");
	InformationAboutMergingFiles.Insert("TotalAccountsInCurStream", 0);
	InformationAboutMergingFiles.Insert("TotalAccountsInCurStream", 0);
	InformationAboutMergingFiles.Insert("NumberOfAccountsInRule", NumberOfAccountsInRule);
	InformationAboutMergingFiles.Insert("AccountsWithoutRules", AccountsWithoutRules);
	InformationAboutMergingFiles.Insert("DischargeStreams", DischargeStreams);
		
	For Each Account In UnloadedBankAccounts Do
		If IsBlankString(Account.RuleOfFileEDIWithBanks) Then
			AccountsWithoutRules.Add(Account);
		Else
			Count = NumberOfAccountsInRule.Get(Account.RuleOfFileEDIWithBanks);
			If Count = Undefined Then
				InformationAboutMergingFiles["NumberOfAccountsInRule"].Insert(
					Account.RuleOfFileEDIWithBanks, 1);
			Else
				InformationAboutMergingFiles["NumberOfAccountsInRule"].Insert(
					Account.RuleOfFileEDIWithBanks, Count + 1);
			EndIf;
		EndIf;
	EndDo;
	
	For Each Rule In NumberOfAccountsInRule Do 
		FlowRule = Rule.Key;
		
		CurrentThread = CommonClientServer.CopyStructure(NewThread);
		CurrentThread.Insert("Rule", Rule.Key);
		CurrentThread.Insert("Accounts", UnloadedBankAccounts.Copy(
			UnloadedBankAccounts.FindRows(New Structure("RuleOfFileEDIWithBanks", Rule.Key))));
		
		InformationAboutMergingFiles["DischargeStreams"].Add(CurrentThread);
	EndDo;
	
	Return InformationAboutMergingFiles;
	
EndFunction

Procedure ChangeAccountDetails(Accounts, ParametersToChange)
	
	For Each Account In Accounts Do
		FillPropertyValues(Account, ParametersToChange);
	EndDo;
	
EndProcedure

Procedure UpdateInformationAboutUploadedFiles(Val InformationAboutMergingFiles)
	
	For Each DischargeFlow In InformationAboutMergingFiles.DischargeStreams Do 
		For Each UploadedInvoice In DischargeFlow.Accounts Do 
			Filter = New Structure("Ref", UploadedInvoice["Ref"]);
			FoundRows = BankAccounts.FindRows(Filter);
			For Each FoundRow In FoundRows Do 
				FillPropertyValues(FoundRow, UploadedInvoice);
			EndDo;
		EndDo;
	EndDo;
	
	For Each UploadedInvoice In InformationAboutMergingFiles.AccountsWithoutRules Do 
		Filter = New Structure("Ref", UploadedInvoice["Ref"]);
		FoundRows = BankAccounts.FindRows(Filter);
		For Each FoundRow In FoundRows Do 
			FillPropertyValues(FoundRow, UploadedInvoice);
		EndDo;
	EndDo;
	
EndProcedure

#EndRegion


Procedure CheckDocumentsForUpload()
	
	// Basic banking details
	Checks = New Map;
	Checks.Insert("Number",   NStr("vi = 'Số chứng từ';
									|ru = 'Номер документа';
									|en = 'Document number'; fa = 'شماره سند';
									|it = 'Номер документа';
									|pl = 'Numer dokumentu';
									|tr = 'Belge numarası'"));
	Checks.Insert("Date",    NStr("vi = 'Ngày chứng từ';
									|ru = 'Дата документа';
									|en = 'Document date'; fa = 'تاریخ سند';
									|it = 'Дата документа';
									|pl = 'Data dokumentu';
									|tr = 'Belge tarihi'"));
	Checks.Insert("Sum",   NStr("vi = 'Số tiền chứng từ';
								|ru = 'Сумма документа';
								|en = 'Document amount'; fa = 'مبلغ سند';
								|it = 'Сумма документа';
								|pl = 'Wartość dokumentu';
								|tr = 'Belge tutarı'"));
	
	// Details of the organization
	PDOrganizationChecks = New Map;
	PDOrganizationChecks.Insert("CompanyBankAccount_",          NStr("vi = 'Tài khoản ngân hàng của doanh nghiệp';
																	|ru = 'Банковский счет организации';
																	|en = 'Company bank account'; fa = 'حساب بانکی شرکت';
																	|it = 'Банковский счет организации';
																	|pl = 'Konto bankowe firmy';
																	|tr = 'İş yeri banka hesabı'"));
	PDOrganizationChecks.Insert("CompanyHiring",              NStr("vi = 'Tên gọi doanh nghiệp';
																	|ru = 'Наименование организации';
																	|en = 'Company name'; fa = 'نام شرکت';
																	|it = 'Наименование организации';
																	|pl = 'Nazwa firmy';
																	|tr = 'İş yeri tanımı'"));
	PDOrganizationChecks.Insert("CompanyTIN",               NStr("vi = 'MST của doanh nghiệp';
																|ru = 'ИНН организации';
																|en = 'Company TIN'; fa = 'شناسه مالیاتی شرکت';
																|it = 'ИНН организации';
																|pl = 'NIP firmy';
																|tr = 'İş yerine ait VKN'"));
	
	// Details of the organization indirect payments
	NPROrganizationChecks = New Map;
	NPROrganizationChecks.Insert("CompanyBankAccount_",         NStr("vi = 'Tài khoản ngân hàng của doanh nghiệp';
																	|ru = 'Банковский счет организации';
																	|en = 'Company bank account'; fa = 'حساب بانکی شرکت';
																	|it = 'Банковский счет организации';
																	|pl = 'Konto bankowe firmy';
																	|tr = 'İş yeri banka hesabı'"));
	NPROrganizationChecks.Insert("CompanyBankForPayments",  NStr("vi = 'Ngân hàng để hạch toán của doanh nghiệp';
																|ru = 'Банк для расчетов организации';
																|en = 'Bank for company payments'; fa = 'بانک برای پرداخت‌های شرکت';
																|it = 'Банк для расчетов организации';
																|pl = 'Bank dla rozliczeń firmy';
																|tr = 'İş yeri ödemeleri için banka'"));
	NPROrganizationChecks.Insert("CompanyCityOfBank",       NStr("vi = 'Thành phố ngân hàng của doanh nghiệp';
																|ru = 'Город банка организации';
																|en = 'City of company bank'; fa = 'شهر بانک شرکت';
																|it = 'Город банка организации';
																|pl = 'Miasto banku firmy';
																|tr = 'İş yeri bankası şehri'"));
	NPROrganizationChecks.Insert("CompanyBankBICProcessingCentre",       NStr("vi = 'Mã ngân hàng trung ương của doanh nghiệp';
																				|ru = 'БИК РЦ банка организации';
																				|en = 'Company''s bank settlement center bank code'; fa = 'کد بانک مرکز تسویه بانک شرکت';
																				|it = 'БИК РЦ банка организации';
																				|pl = 'BIC RC banku firmy';
																				|tr = 'İş yeri BIC banka Hesaplama Kasa Merkezi'"));
	
	// Counterparty's Bank details
	VerificationOfPDCounterparty = New Map;
	VerificationOfPDCounterparty.Insert("CounterpartyBankAccount_",           NStr("vi = 'Tài khoản ngân hàng của đối tác';
																					|ru = 'Банковский счет контрагента';
																					|en = 'Bank account of the counterparty'; fa = 'حساب بانکی طرف حساب';
																					|it = 'Банковский счет контрагента';
																					|pl = 'Rachunek bankowy kontrahenta';
																					|tr = 'Cari hesaba ait banka hesabı'"));
	VerificationOfPDCounterparty.Insert("CounterpartyName",               NStr("vi = 'Đối tác';
																				|ru = 'Контрагент';
																				|en = 'Counterparty'; fa = 'طرف حساب';
																				|it = 'Контрагент';
																				|pl = 'Counterparty';
																				|tr = 'Cari hesap'"));
	VerificationOfPDCounterparty.Insert("CounterpartyTIN",                NStr("vi = 'MST đối tác';
																				|ru = 'ИНН контрагента';
																				|en = 'Counterparty TIN'; fa = 'شناسه مالیاتی طرف حساب';
																				|it = 'ИНН контрагента';
																				|pl = 'NIP kontrahenta';
																				|tr = 'Cari hesabın VKN'"));
	
	// Counterparty's details indirect settlements
	ChecksOfNPRCounterparty = New Map;
	ChecksOfNPRCounterparty.Insert("CounterpartyBankAccount_",          NStr("vi = 'Tài khoản ngân hàng của đối tác';
																			|ru = 'Банковский счет контрагента';
																			|en = 'Bank account of the counterparty'; fa = 'حساب بانکی طرف حساب';
																			|it = 'Банковский счет контрагента';
																			|pl = 'Rachunek bankowy kontrahenta';
																			|tr = 'Cari hesaba ait banka hesabı'"));
	ChecksOfNPRCounterparty.Insert("CounterpartyBankForPayments",   NStr("vi = 'Ngân hàng để hạch toán với đối tác';
																		|ru = 'Банк для расчетов контрагента';
																		|en = 'Bank for counterparty payments'; fa = 'Bank for counterparty payments';
																		|it = 'Банк для расчетов контрагента';
																		|pl = 'Bank dla rozliczeń kontrahentem';
																		|tr = 'Cari hesap ödemeleri için banka'"));
	ChecksOfNPRCounterparty.Insert("CityOfCounterpartyBank",        NStr("vi = 'Thành phố của ngân hàng đối tác';
																		|ru = 'Город банка контрагента';
																		|en = 'City of counterparty bank'; fa = 'شهر بانک طرف حساب';
																		|it = 'Город банка контрагента';
																		|pl = 'Miasto banku kontrahenta';
																		|tr = 'Cari hesap banka şehri'"));
	ChecksOfNPRCounterparty.Insert("CounterpartyBankBICProcessingCentre",        NStr("vi = 'Mã ngân hàng của đối tác';
																						|ru = 'БИК РЦ банка контрагента';
																						|en = 'Counterparty bank settlement center bank code'; fa = 'Counterparty bank settlement center bank code';
																						|it = 'БИК РЦ банка контрагента';
																						|pl = 'BIC Centrum rozliczeniowego kontrahenta';
																						|tr = 'Cari hesap bankasının BIC Hesaplama Kasa Merkezi'"));
	
	ISOVerification = New Map;
	ISOVerification.Insert("SwiftBankCompany", NStr("vi = 'Tên định danh của ngân hàng doanh nghiệp';
													|ru = 'Идентификатор банка организации';
													|en = 'Company bank ID'; fa = 'Company bank ID';
													|it = 'Идентификатор банка организации';
													|pl = 'Identyfikator banku firmy';
													|tr = 'İş yeri bankasının tanımlayıcısı'"));
	ISOVerification.Insert("CompanyBankBIC", NStr("vi = 'Tên định danh của ngân hàng doanh nghiệp';
													|ru = 'Идентификатор банка организации';
													|en = 'Company bank ID'; fa = 'Company bank ID';
													|it = 'Идентификатор банка организации';
													|pl = 'Identyfikator banku firmy';
													|tr = 'İş yeri bankasının tanımlayıcısı'"));
	ISOVerification.Insert("SwiftBankCounterparty", NStr("vi = 'Tên định danh của ngân hàng nhận';
														|ru = 'Идентификатор банка получателя';
														|en = 'Beneficiary bank ID'; fa = 'Beneficiary bank ID';
														|it = 'Идентификатор банка получателя';
														|pl = 'Identyfikator banku odbiorcy';
														|tr = 'Alıcı bankasının tanımlayıcısı'"));
	ISOVerification.Insert("CounterpartyBankBIC", NStr("vi = 'Tên định danh của ngân hàng nhận';
														|ru = 'Идентификатор банка получателя';
														|en = 'Beneficiary bank ID'; fa = 'Beneficiary bank ID';
														|it = 'Идентификатор банка получателя';
														|pl = 'Identyfikator banku odbiorcy';
														|tr = 'Alıcı bankasının tanımlayıcısı'"));
	
	FCVerification = New Map;
	FCVerification.Insert("CompanyTIN",               NStr("vi = 'MST của doanh nghiệp';
															|ru = 'ИНН организации';
															|en = 'Company TIN'; fa = 'شناسه مالیاتی شرکت';
															|it = 'ИНН организации';
															|pl = 'NIP firmy';
															|tr = 'İş yerine ait VKN'"));
	FCVerification.Insert("CompanyHiring",              NStr("vi = 'Tên gọi doanh nghiệp';
															|ru = 'Наименование организации';
															|en = 'Company name'; fa = 'نام شرکت';
															|it = 'Наименование организации';
															|pl = 'Nazwa firmy';
															|tr = 'İş yeri tanımı'"));
	FCVerification.Insert("CompanyBankAccount_",          NStr("vi = 'Tài khoản ngân hàng của doanh nghiệp';
																|ru = 'Банковский счет организации';
																|en = 'Company bank account'; fa = 'حساب بانکی شرکت';
																|it = 'Банковский счет организации';
																|pl = 'Konto bankowe firmy';
																|tr = 'İş yeri banka hesabı'"));
	FCVerification.Insert("CounterpartyBankAccount_",           NStr("vi = 'Tài khoản ngân hàng của đối tác';
																	|ru = 'Банковский счет контрагента';
																	|en = 'Bank account of the counterparty'; fa = 'حساب بانکی طرف حساب';
																	|it = 'Банковский счет контрагента';
																	|pl = 'Rachunek bankowy kontrahenta';
																	|tr = 'Cari hesaba ait banka hesabı'"));
	FCVerification.Insert("CounterpartyName",               NStr("vi = 'Đối tác';
																|ru = 'Контрагент';
																|en = 'Counterparty'; fa = 'طرف حساب';
																|it = 'Контрагент';
																|pl = 'Counterparty';
																|tr = 'Cari hesap'"));
	FCVerification.Insert("CounterpartyTIN",                NStr("vi = 'MST đối tác';
																|ru = 'ИНН контрагента';
																|en = 'Counterparty TIN'; fa = 'شناسه مالیاتی طرف حساب';
																|it = 'ИНН контрагента';
																|pl = 'NIP kontrahenta';
																|tr = 'Cari hesabın VKN'"));
	FCVerification.Insert("PersonalAccount",                  NStr("vi = 'Số tài khoản cá nhân';
																	|ru = 'Номер лицевого счета';
																	|en = 'Personal account number'; fa = 'شماره حساب شخصی';
																	|it = 'Numero conto personale';
																	|pl = 'Numer konta osobistego';
																	|tr = 'Kişisel hesap numarası'"));
	FCVerification.Insert("PaymentPurposes",            NStr("vi = 'Mục đích thanh toán';
															|ru = 'Назначение платежа';
															|en = 'Purpose of payment'; fa = 'بابت پرداخت';
															|it = 'Assegnazione del pagamento';
															|pl = 'Tytuł płatności';
															|tr = 'Ödeme amacı'"));
	
	For Each DocumentForExport In DocumentsToExport Do
		
		ErrorString = "";
		
		Account = BankAccounts.Find(DocumentForExport.BankAccount, "Ref");
		
		If Account.ExchangeFormat = PredefinedValue("Enum.ExchangeFormatWithBank.ClientBankExchange1c") Then
			
			ErrorString = ErrorString + EmptyRequiredFieldsInList(DocumentForExport, Checks);
			
			If Not ValueIsFilled(DocumentForExport.CompanyBankForPayments) Then
				CheckingOrganizationSAccount = PDOrganizationChecks;
			Else
				CheckingOrganizationSAccount = NPROrganizationChecks;
			EndIf;
			
			ErrorString = ErrorString + EmptyRequiredFieldsInList(DocumentForExport, CheckingOrganizationSAccount);
			
			If Not ValueIsFilled(DocumentForExport.CounterpartyBankForPayments) Then
				CheckingCounterpartySAccount = VerificationOfPDCounterparty;
			Else
				CheckingCounterpartySAccount = ChecksOfNPRCounterparty;
			EndIf;
			For Each Validation In CheckingCounterpartySAccount Do
				If DocumentForExport.LegalEntityIndividual = Enums.LegalEntityIndividual.LegalEntityNonResident
					And Validation.Key = "CounterpartyTIN" Then
					Continue;
				EndIf;
					
				If Not ValueIsFilled(DocumentForExport[Validation.Key]) Then
					ErrorString = ErrorString + " " + Validation.Value + ",";
				EndIf;
			EndDo;
			
		ElsIf Account.ExchangeFormat = PredefinedValue("Enum.ExchangeFormatWithBank.ISO20022") Then
			
			If Not ValueIsFilled(DocumentForExport.SwiftBankCompany)
				And Not ValueIsFilled(DocumentForExport.CompanyBankBIC) Then
				
				Text = NStr("vi = 'Mã định danh ngân hàng của doanh nghiệp (Mã ngân hàng / SWIFT)';
							|ru = 'Идентификатор банка организации (БИК / SWIFT)';
							|en = 'Company''s bank ID (Bank code / SWIFT)'; fa = 'Company''s bank ID (Bank code / SWIFT)';
							|it = 'Идентификатор банка организации (БИК / SWIFT)';
							|pl = 'Identyfikatora banku firmy (BIC / SWIFT)';
							|tr = 'İş yeri bankasının tanımlayıcısı (BIC / SWIFT)'");
				ErrorString = ErrorString + " " + Text + ",";
				
			EndIf;
					
			If Not ValueIsFilled(DocumentForExport.SwiftBankCounterparty)
				And Not ValueIsFilled(DocumentForExport.CounterpartyBankBIC) Then
				
				Text = NStr("vi = 'Mã định danh của ngân hàng nhận (Mã ngân hàng / SWIFT)';
							|ru = 'Идентификатор банка получателя (БИК / SWIFT)';
							|en = 'Payee’s bank ID (Bank code / SWIFT)'; fa = 'Payee’s bank ID (Bank code / SWIFT)';
							|it = 'Идентификатор банка получателя (БИК / SWIFT)';
							|pl = 'Identyfikator banku odbiorcy (BIC / SWIFT)';
							|tr = 'Alıcı bankasının tanımlayıcısı (BIC / SWIFT)'");
				ErrorString = ErrorString + " " + Text + ",";
				
			EndIf;
			
			
		EndIf;
		
		If ValueIsFilled(ErrorString) Then
			ErrorString = Left(ErrorString, StrLen(ErrorString) - 1);
			DocumentForExport.HasError = True;
			DocumentForExport.ToExport = False;
			DocumentForExport.ErrorsDescription = NStr("vi = 'Chưa điền thông tin thanh toán:';
														|ru = 'Не заполнены реквизиты платежа:';
														|en = 'Payment details are not filled:'; fa = 'Payment details are not filled:';
														|it = 'Не заполнены реквизиты платежа:';
														|pl = 'Nie są wypełnione szczegóły płatności:';
														|tr = 'Ödeme bilgileri doldurulmadı:'") + ErrorString;
		EndIf;
		
		
	EndDo;
	
EndProcedure

Function DocumentsToBeUploadedByInvoice(Accounts)
	
	DocumentsToBeUploadedByInvoice = New Array;
	
	For Each Account In Accounts Do 
		Filter = New Structure;
		Filter.Insert("ToExport", True);
		Filter.Insert("BankAccount", Account["Ref"]);
		
		FoundDocuments = DocumentsToExport.FindRows(Filter);
		
		For Each FoundDocument In FoundDocuments Do 
			DocumentsToBeUploadedByInvoice.Add(FoundDocument);
		EndDo;
	EndDo;
	
	Return DocumentsToBeUploadedByInvoice;
	
EndFunction

Function DocumentsToBeUploadedByInvoice_(Account)
	
	Filter = New Structure;
	Filter.Insert("ToExport", True);
	Filter.Insert("BankAccount", Account["Ref"]);
	
	Return DocumentsToExport.FindRows(Filter);
	
EndFunction

Procedure DisplayUploadReportSection(ReportField, Var_Documents, BankAccount, Exported)
	
	ReportTemplate = GetTemplate("ExportReport");
	
	Header    = ReportTemplate.GetArea("Header");
	String   = ReportTemplate.GetArea("String");
	Footer   = ReportTemplate.GetArea("Footer");
	Names_  = ReportTemplate.GetArea("CompanyName");
	
	AccountAttributes = Catalogs.CompaniesBankAccounts.GetCompanySBankAccountDetails(BankAccount);
	
	Names_.Parameters.CompanyName = String(AccountAttributes.Organization);
	ReportField.Put(Names_);
	
	If Exported Then
		Header.Parameters.ReportName = NStr("vi = 'Báo cáo về chứng từ đã kết xuất';
											|ru = 'Отчет о выгруженных документах';
											|en = 'Report on the exported documents'; fa = 'Report on the exported documents';
											|it = 'Отчет о выгруженных документах';
											|pl = 'Prześlij raport o dokumencie';
											|tr = 'Dışa aktarılan belgeler hakkında rapor'");
	Else
		Header.Parameters.ReportName = NStr("vi = 'Chứng từ để dỡ hàng';
											|ru = 'Документы к выгрузке';
											|en = 'Documents to export'; fa = 'اسناد قابل خروج';
											|it = 'Документы к выгрузке';
											|pl = 'Dokumenty do wyładowania';
											|tr = 'Dışa aktarılacak belgeler'");
	EndIf;
	Header.Parameters.NameOfReceiptAmount = NStr("vi = 'Thu';
												|ru = 'Поступление';
												|en = 'Incoming payment'; fa = 'دریافت ورودی';
												|it = 'Поступление';
												|pl = 'Wpływ';
												|tr = 'Giriş'");
	Header.Parameters.NameOfDebitedAmount    = NStr("vi = 'Chi';
													|ru = 'Списание';
													|en = 'Stock shortage'; fa = 'کسری موجودی';
													|it = 'Списание';
													|pl = 'Spisanie';
													|tr = 'Gider yazma'");
	
	OBRBankAccount = "";
	Indus = 0; TotalAmountOfP = 0; TotalAmountOfP_ = 0;
	
	Var_Documents.Sort("Date");
	BegPeriod = Var_Documents[0].Date;
	NdPeriod = Var_Documents[Var_Documents.Count() - 1].Date;
	
	Currency = ?(ValueIsFilled(AccountAttributes.Currency), TrimAll(String(AccountAttributes.Currency)), NStr("vi = 'không có tiền tệ';
																												|ru = 'валюта не указана';
																												|en = 'currency not specified'; fa = 'currency not specified';
																												|it = 'валюта не указана';
																												|pl = 'nie podano waluty';
																												|tr = 'para birimi belirtilmedi'"));
	BeginningOfReportingPeriod = Format(BegPeriod, "DLF=D");
	EndOfReportingPeriod = Format(NdPeriod, "DLF=D");
	
	Header.Parameters.PeriodDetails =
		StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'theo tài khoản %1 (%2) từ %3 đến %4';
																		|ru = 'по счету %1 (%2) с %3 по %4';
																		|en = 'by account %1 (%2) from %3 to %4'; fa = 'by account %1 (%2) from %3 to %4';
																		|it = 'по счету %1 (%2) с %3 по %4';
																		|pl = 'wg konta %1 (%2) od %3 do %4';
																		|tr = 'hesabı için %1 (%2) %3 tarihinden %4 kadar'"),
			AccountAttributes.AccountNumber,
			Currency,
			BeginningOfReportingPeriod,
			EndOfReportingPeriod);
	ReportField.Put(Header);
	
	For Each SourceRow1 In Var_Documents Do
		
		Currency = ?(ValueIsFilled(SourceRow1.Currency), TrimAll(String(SourceRow1.Currency)), NStr("vi = 'không có tiền tệ';
																									|ru = 'валюта не указана';
																									|en = 'currency not specified'; fa = 'currency not specified';
																									|it = 'валюта не указана';
																									|pl = 'nie podano waluty';
																									|tr = 'para birimi belirtilmedi'"));
		
		If SourceRow1.DocumentKind = Enums.TypesOfPaymentDocuments.PaymentDemand Then
			
			String.Parameters.Recipient = SourceRow1.CompanyHiring;
			String.Parameters.BeneficiaryAccount = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 (%2)';
																												|ru = '%1 (%2)';
																												|en = '%1 (%2)'; fa = '%1 (%2)';
																												|it = '%1 (%2)';
																												|pl = '%1 (%2)';
																												|tr = '%1 (%2)'"),
				SourceRow1.CompanyBankAccount_,
				Currency);
			
			String.Parameters.Payer = SourceRow1.Counterparty;
			String.Parameters.PayerAccount = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 (%2)';
																											|ru = '%1 (%2)';
																											|en = '%1 (%2)'; fa = '%1 (%2)';
																											|it = '%1 (%2)';
																											|pl = '%1 (%2)';
																											|tr = '%1 (%2)'"),
				SourceRow1.CounterpartyBankAccount_,
				Currency);
				
			String.Parameters.AmountReceived_  = SourceRow1.Sum;
			String.Parameters.AmountDebited = "";
			TotalAmountOfP = TotalAmountOfP + SourceRow1.Sum;
		Else
			
			String.Parameters.Payer = SourceRow1.CompanyHiring;
			String.Parameters.PayerAccount = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 (%2)';
																											|ru = '%1 (%2)';
																											|en = '%1 (%2)'; fa = '%1 (%2)';
																											|it = '%1 (%2)';
																											|pl = '%1 (%2)';
																											|tr = '%1 (%2)'"),
				SourceRow1.CompanyBankAccount_,
				Currency);
			
			String.Parameters.Recipient = SourceRow1.Counterparty;
			String.Parameters.BeneficiaryAccount = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 (%2)';
																												|ru = '%1 (%2)';
																												|en = '%1 (%2)'; fa = '%1 (%2)';
																												|it = '%1 (%2)';
																												|pl = '%1 (%2)';
																												|tr = '%1 (%2)'"),
				SourceRow1.CounterpartyBankAccount_,
				Currency);
				
			String.Parameters.AmountReceived_ = "";
			String.Parameters.AmountDebited = SourceRow1.Sum;
			TotalAmountOfP_ = TotalAmountOfP_ + SourceRow1.Sum;
		EndIf;
		
		String.Parameters.Document = SourceRow1["Ref"];
		Indus = Indus + 1;
		String.Parameters["IndexOf"] = Indus;
		
		ReportField.Put(String);
		
	EndDo;
	
	Footer.Parameters.TotalAmountOfP = TotalAmountOfP;
	Footer.Parameters.TotalAmountOfP_ = TotalAmountOfP_;
	
	ReportField.Put(Footer);
	
	ReportField.ShowGroups = False;
	ReportField.ShowHeaders   = False;
	ReportField.ShowGrid       = False;
	ReportField.ReadOnly        = True;
	
EndProcedure

Procedure DisplayDownloadReportSection(ReportField, Var_Documents, BankAccount, Imported)
	
	ReportTemplate = GetTemplate("ImportReport");
	
	ThereIsCalculationSection = False;
	
	Header   = ReportTemplate.GetArea("Header");
	String  = ReportTemplate.GetArea("String");
	Footer  = ReportTemplate.GetArea("Footer");
	Balance = ReportTemplate.GetArea("Balance");
	Names_ = ReportTemplate.GetArea("CompanyName");
	
	AccountAttributes = Catalogs.CompaniesBankAccounts.GetCompanySBankAccountDetails(BankAccount);
	
	Names_.Parameters.CompanyName = String(AccountAttributes.Organization);
	ReportField.Put(Names_);
	
	If Imported Then
		Header.Parameters.ReportName = NStr("vi = 'Báo cáo về chứng từ đã kết nhập';
											|ru = 'Отчет о загруженных документах';
											|en = 'Report on the imported documents'; fa = 'Report on the imported documents';
											|it = 'Отчет о загруженных документах';
											|pl = 'Raport przesyłania dokumentów';
											|tr = 'İçe aktarılan belgeler hakkında rapor'");
	Else
		Header.Parameters.ReportName = NStr("vi = 'Chứng từ sao kê';
											|ru = 'Документы выписки';
											|en = 'Statement documents'; fa = 'Statement documents';
											|it = 'Документы выписки';
											|pl = 'Dokumenty oświadczenia';
											|tr = 'Ekstre belgeleri'");
	EndIf;
	
	OBRBankAccount = "";
	Indus = 0; TotalAmountOfP = 0; TotalAmountOfP_ = 0;
	
	Var_Documents.Sort("Date");
	BegPeriod = Var_Documents[0].DocDate;
	NdPeriod = Var_Documents[Var_Documents.Count() - 1].DocDate;
	
	Currency = ?(ValueIsFilled(AccountAttributes.Currency), TrimAll(String(AccountAttributes.Currency)), NStr("vi = 'không có tiền tệ';
																												|ru = 'валюта не указана';
																												|en = 'currency not specified'; fa = 'currency not specified';
																												|it = 'валюта не указана';
																												|pl = 'nie podano waluty';
																												|tr = 'para birimi belirtilmedi'"));
	BeginningOfReportingPeriod = Format(BegPeriod, "DLF=D");
	EndOfReportingPeriod = Format(NdPeriod, "DLF=D");
	
	DetailsOfTreasuryAccount = New Array;
	
	If ValueIsFilled(AccountAttributes.PersonalAccountNumber) Then
		DetailsOfTreasuryAccount.Add(AccountAttributes.PersonalAccountNumber);
	EndIf;
	
	If ValueIsFilled(AccountAttributes.PersonalAccountSection) Then
		DetailsOfTreasuryAccount.Add(AccountAttributes.PersonalAccountSection);
	EndIf;
	
	TextOfPersonalAccountSection = StrConcat(DetailsOfTreasuryAccount, "/");
	
	Header.Parameters.PeriodDetails = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'theo tài khoản %1%2 (%3) từ %4 đến %5';
																									|ru = 'по счету %1%2 (%3) с %4 по %5';
																									|en = 'by account %1%2 (%3) from %4 to %5'; fa = 'by account %1%2 (%3) from %4 to %5';
																									|it = 'by account %1%2 (%3) from %4 to %5';
																									|pl = 'by account %1%2 (%3) from %4 to %5';
																									|tr = 'hesabı için %1%2 (%3) %4 tarihinden %5 tarihine kadar'"),
		TrimAll(AccountAttributes.AccountNumber),
		?(IsBlankString(TextOfPersonalAccountSection), "", "/" + TextOfPersonalAccountSection),
		Currency,
		BeginningOfReportingPeriod,
		EndOfReportingPeriod);
	ReportField.Put(Header);
	
	For Each SourceRow1 In Var_Documents Do
		
		Currency = ?(ValueIsFilled(SourceRow1.Currency), TrimAll(String(SourceRow1.Currency)), NStr("vi = 'không có tiền tệ';
																									|ru = 'валюта не указана';
																									|en = 'currency not specified'; fa = 'currency not specified';
																									|it = 'валюта не указана';
																									|pl = 'nie podano waluty';
																									|tr = 'para birimi belirtilmedi'"));
		
		If SourceRow1.ReceivedAmount > 0 Then
			
			String.Parameters.Counterparty =
				?(IsBlankString(SourceRow1.Payer1), SourceRow1.Payer, SourceRow1.Payer1);
			String.Parameters.Account = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 (%2)';
																										|ru = '%1 (%2)';
																										|en = '%1 (%2)'; fa = '%1 (%2)';
																										|it = '%1 (%2)';
																										|pl = '%1 (%2)';
																										|tr = '%1 (%2)'"),
				SourceRow1.PayerAccount,
				Currency);
				
			String.Parameters.AmountReceived_ = SourceRow1.ReceivedAmount;
			String.Parameters.AmountDebited    = "";
			String.Parameters.Date             = Format(SourceRow1.DocDate, "DLF=D");
			TotalAmountOfP                       = TotalAmountOfP + SourceRow1.ReceivedAmount;
			
		ElsIf SourceRow1.AmountCredited > 0 Then

			String.Parameters.Counterparty =
				?(IsBlankString(SourceRow1.Recipient1), SourceRow1.Recipient, SourceRow1.Recipient1);
			String.Parameters.Account = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 (%2)';
																										|ru = '%1 (%2)';
																										|en = '%1 (%2)'; fa = '%1 (%2)';
																										|it = '%1 (%2)';
																										|pl = '%1 (%2)';
																										|tr = '%1 (%2)'"),
				SourceRow1.BeneficiaryAccount,
				Currency);
				
			String.Parameters.AmountDebited    = SourceRow1.AmountCredited;
			String.Parameters.AmountReceived_ = "";
			String.Parameters.Date             =
				?(IsBlankString(SourceRow1.Date), Format(SourceRow1.DocDate, "DLF=D"), SourceRow1.Date);
			TotalAmountOfP_                       = TotalAmountOfP_ + SourceRow1.AmountCredited;

		Else
			Continue;
		EndIf;
		
		If Imported Then
			Doc = SourceRow1.Document;
			If ValueIsFilled(Doc) Then
				String.Parameters.Document     = Doc;
				AreaRow = String.Areas["String"]; // SpreadsheetDocumentRange 
				AreaRow.TextColor = StyleColors.FormTextColor;
			Else
				String.Parameters.Document     = NStr("vi = 'CHƯA KẾT NHẬP';
														|ru = 'НЕ ЗАГРУЖЕН';
														|en = 'NOT IMPORTED'; fa = 'NOT IMPORTED';
														|it = 'НЕ ЗАГРУЖЕН';
														|pl = 'NIE WCZYTANY';
														|tr = 'YÜKLENMEDİ'");
				If ValueIsFilled(SourceRow1.ImportErrors) Then
					String.Parameters.Document = String.Parameters.Document + ": " + SourceRow1.ImportErrors;
				EndIf;
				AreaRow = String.Areas["String"]; // SpreadsheetDocumentRange
				AreaRow.TextColor = StyleColors.NegativeTextColor;
			EndIf;
		EndIf;
		
		String.Parameters.Number             = SourceRow1.Number;
		String.Parameters.PaymentPurposes = SourceRow1.PaymentPurposes;
		
		Indus = Indus + 1;
		String.Parameters["IndexOf"] = Indus;
		
		ReportField.Put(String);
		
	EndDo;
	
	Footer.Parameters.TotalAmountOfP = TotalAmountOfP;
	Footer.Parameters.TotalAmountOfP_ = TotalAmountOfP_;
	
	ReportField.Put(Footer);
	ReportField.ShowGroups = False;
	ReportField.ShowHeaders   = False;
	ReportField.ShowGrid       = False;
	ReportField.ReadOnly        = True;
	
EndProcedure

Procedure FillInInformationAboutRecipientsPayers(PaymentTable_3)

	DocumentsArray = PaymentTable_3.UnloadColumn("Ref");
	CounterpartyData_ = CashServer.InformationAboutRecipientPayerAccordingToDocuments(DocumentsArray);
	
	For Each TableRow In PaymentTable_3 Do
		
		If TypeOf(TableRow.CounterpartyBankAccount) = Type("CatalogRef.CompaniesBankAccounts") Then
			
			If TableRow.Operation = Enums.BusinessTransactions.CurrencyConversion Then
				DataProcessors.EDIWithBanks.FillInAttributeValueForDocument(
					CounterpartyData_,
					TableRow.CounterpartyName,
					TableRow.Ref,
					4);
			Else
				DataProcessors.EDIWithBanks.FillInAttributeValueForDocument(
					CounterpartyData_,
					TableRow.CounterpartyName,
					TableRow.Ref,
					2);
			EndIf;
			
		Else
			DataProcessors.EDIWithBanks.FillInAttributeValueForDocument(
				CounterpartyData_,
				TableRow.CounterpartyName,
				TableRow.Ref,
				0);
		EndIf;
		
		If TableRow.Operation = Enums.BusinessTransactions.CurrencyConversion Then
			
			DataProcessors.EDIWithBanks.FillInAttributeValueForDocument(
				CounterpartyData_,
				TableRow.CounterpartyNameInternational,
				TableRow.Ref,
				6);
			DataProcessors.EDIWithBanks.FillInAttributeValueForDocument(
				CounterpartyData_,
				TableRow.RecipientCRTR,
				TableRow.Ref,
				7);
			
		Else
			
			DataProcessors.EDIWithBanks.FillInAttributeValueForDocument(
				CounterpartyData_,
				TableRow.CounterpartyNameInternational,
				TableRow.Ref,
				3);
				
			DataProcessors.EDIWithBanks.FillInAttributeValueForDocument(
				CounterpartyData_,
				TableRow.RecipientCRTR,
				TableRow.Ref,
				1);
			
		EndIf;
		
		DataProcessors.EDIWithBanks.FillInAttributeValueForDocument(
			CounterpartyData_,
			TableRow.CompanyNameInternational,
			TableRow.Ref,
			6);
		
		If Not GetFunctionalOption("RFPaymentsSupport")
			Or TableRow.DocumentKind = Enums.TypesOfPaymentDocuments.PaymentDemand Then
			
			DataProcessors.EDIWithBanks.FillInAttributeValueForDocument(
				CounterpartyData_,
				TableRow.CompanyHiring,
				TableRow.Ref,
				4);
			DataProcessors.EDIWithBanks.FillInAttributeValueForDocument(
				CounterpartyData_,
				TableRow.PayerCRTR,
				TableRow.Ref,
				7);
			
		EndIf;
		
		TableRow.CompanyTIN = TrimAll(TableRow.CompanyTIN);
		TableRow.PayerCRTR = TrimAll(TableRow.PayerCRTR);
		TableRow.CompanyHiring = TrimAll(TableRow.CompanyHiring);
		
	EndDo;

EndProcedure

Function EmptyRequiredFieldsInList(DocumentData, Attributes)

	ErrorString = "";
	
	For Each CurrentAttribute In Attributes Do
		
		If Not ValueIsFilled(DocumentData[CurrentAttribute.Key]) Then
			ErrorString = ErrorString + " " + CurrentAttribute.Value + ",";
		EndIf;
		
	EndDo;
	
	Return ErrorString;

EndFunction


#EndRegion

#EndIf
