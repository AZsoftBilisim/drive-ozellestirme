#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	EmployeeResponsible = Users.CurrentUser();
	
	Organization = Common.CommonSettingsStorageLoad("CurrentCompany", "");
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	ChartOfAccounts = Catalogs.FinancialAccountingChartsOfAccounts.DefaultChartOfAccounts();
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	TypesOfSingleOperations = New Array();
	TypesOfSingleOperations.Add(Enums.PeriodEndTransactionsTypesFinancialAccounting.ClosingOfGLAccountsOfIncomeAndExpenses);
	TypesOfSingleOperations.Add(Enums.PeriodEndTransactionsTypesFinancialAccounting.ReclassificationOfLongTermAssetsAndLiabilities);
	
	If TypesOfSingleOperations.Find(OperationType) <> Undefined Then
		CheckDuplicateCurPeriodDocuments(Cancel);
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	AdditionalProperties.Insert("IsNew", IsNew());
	AdditionalProperties.Insert("WriteMode", WriteMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	TransactionGenerationSettingsFilledIn();
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	TransactionTypes = Enums.PeriodEndTransactionsTypesFinancialAccounting;
	
	If OperationType = TransactionTypes.ReclassificationOfLongTermAssetsAndLiabilities Then
		ReclassificationOfLongTermAssetsAndLiabilities(Cancel);
		
	ElsIf OperationType = TransactionTypes.ClosingOfGLAccountsOfIncomeAndExpenses Then
		ClosingIncomeExpenseAccounts(Cancel);
		
	Else
		ExchangeDifferenceCalculation();
		
	EndIf;
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	If Not Cancel
	   And Not AdditionalProperties.Property("CompletingMonthClosingStage") Then
		CreateTasksForEndOfMonthWhenEventIsCanceled();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure TransactionGenerationSettingsFilledIn()
	
	Filter = New Structure("ChartOfAccounts, Organization", ChartOfAccounts, Organization);
	TransactionGenerationSettings = InformationRegisters.FinancialAccountingChartsOfAccountsForCompanies.SliceLast(EndOfDay(Date),Filter);
	If TransactionGenerationSettings.Count() Then
		ConfiguringFormationOfBusinessTransactions = TransactionGenerationSettings[0].PostingGenerationSetting;
	Else
		Text = StrTemplate(
					NStr("vi = 'Đối với doanh nghiệp ""%1"" chưa đặt tùy chỉnh tạo bút toán theo hệ thống tài khoản ""%2""';
						|ru = 'Для организации ""%1"" не задана настройка формирования проводок по плану счетов ""%2""';
						|en = 'The posting schema according to chart of accounts ""%2"" is not specified for company ""%1""'; fa = 'The posting schema according to chart of accounts ""%2"" is not specified for company ""%1""';
						|it = 'Per l''organizzazione ""%1"" non è data l''impostazione di creazione delle transazioni in base al piano dei conti ""%2""';
						|pl = 'Dla firmy ""%1"" nie zadano ustawienia formowania księgowań wg planów kont ""%2""';
						|tr = '""%1"" iş yeri, ""%2"" hesap planına işlem oluşturacak şekilde yapılandırılmadı'"),
					Organization,
					ChartOfAccounts);
		Raise Text;
	EndIf;
	
	If OperationType = Enums.PeriodEndTransactionsTypesFinancialAccounting.ClosingOfGLAccountsOfIncomeAndExpenses Then
		Attributes = Common.ObjectAttributesValues(ConfiguringFormationOfBusinessTransactions,
			"ClosingOfIncomeAndExpenseAccounts,GLAccountOfIncome,GLAccountOfExpenses,GLAccountOfRetainedProfitLoss,IncomeAccounts,ExpenseAccounts,AccountsOfProfitLoss");
		
		If Attributes.ClosingOfIncomeAndExpenseAccounts = Enums.ClosingOfIncomeAndExpenseAccounts.EmptyRef() Then
			Text = StrTemplate(
				NStr("vi = 'Đối với doanh nghiệp ""%1"" trong tùy chỉnh tạo bút toán ""%2"" theo hệ thống tài khoản ""%3"" chưa đặt định kỳ đóng tài khoản thu nhập và chi phí';
					|ru = 'Для организации ""%1"" в настройке формирования проводок ""%2"" по плану счетов ""%3"" не задана периодичность закрытия счетов доходов и расходов';
					|en = 'The frequency of closing income and expense accounts is not set for the ""%1"" company in the ""%2"" posting schema for the ""%3"" chart of accounts'; fa = 'The frequency of closing income and expense accounts is not set for the ""%1"" company in the ""%2"" posting schema for the ""%3"" chart of accounts';
					|it = 'Для организации ""%1"" в настройке формирования проводок ""%2"" по плану счетов ""%3"" не задана периодичность закрытия счетов доходов и расходов';
					|pl = 'The frequency of closing income and expense accounts is not set for the ""%1"" company in the ""%2"" posting schema for the ""%3"" chart of accounts';
					|tr = '""%1"" iş yeri için ""%2"" hareketlerinin ""%3"" hesap planına göre oluşturulma ayarında, gelir ve gider hesaplarının kapanış sıklığı belirlenmedi'"),
				Organization,
				ConfiguringFormationOfBusinessTransactions,
				ChartOfAccounts);
			Raise Text;
		EndIf;
		
		If Not (ValueIsFilled(Attributes.GLAccountOfIncome) And ValueIsFilled(Attributes.IncomeAccounts)
			Or ValueIsFilled(Attributes.GLAccountOfExpenses) And ValueIsFilled(Attributes.ExpenseAccounts)
			Or ValueIsFilled(Attributes.GLAccountOfRetainedProfitLoss) And ValueIsFilled(Attributes.AccountsOfProfitLoss)) Then
			
			Text = StrTemplate(
						NStr("vi = 'Đối với doanh nghiệp ""%1"" trong tùy chỉnh tạo bút toán ""%2"" theo hệ thống tài khoản ""%3"" chưa đặt tài khoản đóng kỳ';
							|ru = 'Для организации ""%1"" в настройке формирования проводок ""%2"" по плану счетов ""%3"" не заданы счета закрытия периода';
							|en = 'Period-end closing accounts are not set for the company ""%1"" in posting schema ""%2"" for the chart of accounts ""%3""'; fa = 'Period-end closing accounts are not set for the company ""%1"" in posting schema ""%2"" for the chart of accounts ""%3""';
							|it = 'Per l''organizzazione ""%1"" nell''impostazione di creazione delle transazioni ""%2"" in base al piano dei conti ""%3"" non sono dati i conti di chiusura del periodo';
							|pl = 'Dla firmy ""%1"" w ustawieniu utworzenia wpisów ""%2"" wg planu kont ""%3"" nie zadano konta zamknięcia okresu';
							|tr = '""%1"" iş yeri için, ""%3"" hesap planı için ""%2"" girişlerinin oluşturulması ayarında tanımlanan dönem sonu kapanış hesabı yok'"),
						Organization,
						ConfiguringFormationOfBusinessTransactions,
						ChartOfAccounts);
						
			AdditionalProperties.Insert("ConfiguringGenerationOfTransactionsWithErrors", ConfiguringFormationOfBusinessTransactions);
			
			Raise Text;
			
		EndIf;
		
	ElsIf OperationType = Enums.PeriodEndTransactionsTypesFinancialAccounting.ExchangeDifferenceCalculationPresentationCurrency
		Or OperationType = Enums.PeriodEndTransactionsTypesFinancialAccounting.ExchangeDifferenceCalculationFunctionalCurrency Then
		Attributes = Common.ObjectAttributesValues(ConfiguringFormationOfBusinessTransactions,
			"ForeignExchangeGain,GLAccountOfExchangeLoss,IncomeFromTranslationToPresentationCurrency,ExpensesDifferencesArisingFromConversionToPresentationCurrency");
		
		If Not ValueIsFilled(Attributes.ForeignExchangeGain) 
				Or Not ValueIsFilled(Attributes.GLAccountOfExchangeLoss)
				Or Not ValueIsFilled(Attributes.IncomeFromTranslationToPresentationCurrency) 
				Or Not ValueIsFilled(Attributes.ExpensesDifferencesArisingFromConversionToPresentationCurrency) Then
			
			Text = StrTemplate(
						NStr("vi = 'Đối với doanh nghiệp ""%1"" trong tùy chỉnh tạo bút toán ""%2"" theo hệ thống tài khoản ""%3"" chưa đặt tài khoản kế toán chênh lệch tỷ giá';
							|ru = 'Для организации ""%1"" в настройке формирования проводок ""%2"" по плану счетов ""%3"" не заданы счета учета курсовых разниц';
							|en = 'Ledger accounts of exchange rate differences are not set for the company ""%1"" in posting schema ""%2"" for the chart of accounts ""%3""'; fa = 'Ledger accounts of exchange rate differences are not set for the company ""%1"" in posting schema ""%2"" for the chart of accounts ""%3""';
							|it = 'Per l''organizzazione ""%1"" nell''impostazione di creazione delle transazioni ""%2"" in base al piano dei conti ""%3"" non è data la contabilità delle differenze di cambio';
							|pl = 'Dla firmy ""%1"" w ustawieniu utworzenia wpisów księgowych ""%2"" wg planu kont ""%3"" nie zadano kont księgowych różnic kursowych';
							|tr = '""%1"" iş yeri için, ""%3"" hesap planı için ""%2"" işlemlerinin oluşturulmasında tanımlanmış döviz hesabı yok'"),
						Organization,
						ConfiguringFormationOfBusinessTransactions,
						ChartOfAccounts);
			
			AdditionalProperties.Insert("ConfiguringGenerationOfTransactionsWithErrors", ConfiguringFormationOfBusinessTransactions);
			Raise Text;
			
		EndIf;

	EndIf;
	
EndProcedure

Procedure CheckDuplicateCurPeriodDocuments(Cancel)
	
	Query = New Query(
		"SELECT TOP 1
		|	T.Ref
		|FROM
		|	Document.PeriodEndTransactionFinancialAccounting AS T
		|WHERE
		|	T.Posted
		|	AND T.ChartOfAccounts = &ChartOfAccounts
		|	AND T.Organization = &Organization
		|	AND T.Date BETWEEN &PeriodBeginning AND &PeriodEnd
		|	AND NOT T.Ref = &CurrentDocument
		|	AND T.OperationType = &OperationType");
	
	Query.SetParameter("ChartOfAccounts", ChartOfAccounts);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("CurrentDocument", Ref);
	Query.SetParameter("PeriodBeginning", BegOfMonth(Date));
	Query.SetParameter("PeriodEnd", EndOfMonth(Date));
	Query.SetParameter("OperationType", OperationType);
	
	Result = Query.Execute();
	
	If Not Result.IsEmpty() Then
		Common.MessageToUser(
			NStr("vi = 'Trong kỳ chỉ ra đã có chứng từ tương đương. Chưa thực hiện giao dịch.';
				|ru = 'В указанном периоде уже существует аналогичный документ. Операция не выполнена.';
				|en = 'There is a similar document in the specified period. Operation is not executed.'; fa = 'There is a similar document in the specified period. Operation is not executed.';
				|it = 'Nel periodo indicato esiste già un documento analogo. L''operazione non è stata completata.';
				|pl = 'W podanym okresie już istnieje analogiczny dokument. Operacja nie powiodła się.';
				|tr = 'Belirtilen dönemde benzer bir belge zaten mevcut. İşlem tamamlanmadı'"),,,,
			Cancel);
	EndIf;
	
EndProcedure

Procedure ClosingIncomeExpenseAccounts(Cancel)
	
	OnDate = EndOfMonth(Date);
	
	TimeFenceForClosingAccounts = New Array();
	TimeFenceForClosingAccounts.Add(Enums.ClosingOfIncomeAndExpenseAccounts.Monthly);
	
	If OnDate = EndOfYear(OnDate) Then
		TimeFenceForClosingAccounts.Add(Enums.ClosingOfIncomeAndExpenseAccounts.AtYearEnd);
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("ChartOfAccounts", ChartOfAccounts);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Date", OnDate);
	Query.SetParameter("Boundary", New Boundary(OnDate, BoundaryType.Including));
	Query.SetParameter("TimeFenceForClosingAccounts", TimeFenceForClosingAccounts);
	
	Replace = True;
	
	Query.Text = TextOfRequestToCloseIncomeExpenseAccounts("GLAccountOfIncome", "IncomeAccounts", NStr("vi = 'Đóng thu nhập';
																										|ru = 'Закрытие доходов';
																										|en = 'Close income'; fa = 'Close income';
																										|it = 'Chiusura delle entrate';
																										|pl = 'Zamknięcie dochodów';
																										|tr = 'Gelirlerin kapatılması'"));
	RecordTransactionsForClosingIncomeExpenseAccounts(Query, Cancel, Replace);
	
	Query.Text = TextOfRequestToCloseIncomeExpenseAccounts("GLAccountOfExpenses", "ExpenseAccounts", NStr("vi = 'Đóng chi phí';
																											|ru = 'Закрытие расходов';
																											|en = 'Close expenses'; fa = 'Close expenses';
																											|it = 'Chiusura delle uscite';
																											|pl = 'Zamknięcie rozchodów';
																											|tr = 'Giderlerin kapatılması'"));
	RecordTransactionsForClosingIncomeExpenseAccounts(Query, Cancel, Replace);
	
	Query.Text = TextOfRequestToCloseIncomeExpenseAccounts("GLAccountOfRetainedProfitLoss", "AccountsOfProfitLoss", NStr("vi = 'Lãi\lỗ chưa phân bổ';
																														|ru = 'Нераспредленная прибыль\убыток';
																														|en = 'Retained profit\loss'; fa = 'Retained profit\loss';
																														|it = 'Utile\perdite non distribuiti';
																														|pl = 'Niepodzielony zysk\strata';
																														|tr = 'Dağıtılmamış kâr\zarar'"));
	RecordTransactionsForClosingIncomeExpenseAccounts(Query, Cancel, Replace);
	
	RegisterRecords.International.Write = False;
	RegisterRecords.InternationalWithoutCorrespondence.Write = False;
	
EndProcedure

Procedure ExchangeDifferenceCalculation()
	
	CurrencyOfInternationalAccounting = FinancialAccountingOfGeneralPurpose.AccountingCurrencies(ChartOfAccounts, Organization);
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	FunctionalCurrency = ProcessingOfExchangeRatesTM.GetCurrencyRate(CurrencyOfInternationalAccounting.Functional, Date, LocalAccountingCurrency);
	PresentationCurrency = ProcessingOfExchangeRatesTM.GetCurrencyRate(CurrencyOfInternationalAccounting.Presentations, Date, LocalAccountingCurrency);
	
	OnDate = EndOfDay(Date);
	Query = New Query;
	Query.SetParameter("ChartOfAccounts", ChartOfAccounts);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("LocalAccountingCurrency", LocalAccountingCurrency);
	Query.SetParameter("Date", OnDate);
	Query.SetParameter("Boundary", New Boundary(OnDate, BoundaryType.Including));
	Query.SetParameter("CourseNumeratorFV", FunctionalCurrency.CourseNumerator);
	Query.SetParameter("CourseDenominatorFV", FunctionalCurrency.CourseDenominator);
	Query.SetParameter("CourseNumeratorVP", PresentationCurrency.CourseNumerator);
	Query.SetParameter("CourseDenominatorVP", PresentationCurrency.CourseDenominator);
	Query.SetParameter("PresentationCurrency", CurrencyOfInternationalAccounting.Presentations);
	Query.SetParameter("FunctionalCurrency", CurrencyOfInternationalAccounting.Functional);
	
	TransactionTypes = Enums.PeriodEndTransactionsTypesFinancialAccounting;
	CountInBatch = 1000;
	If OperationType = TransactionTypes.ExchangeDifferenceCalculationPresentationCurrency Then
		Query.Text = TextOfExchangeRateRequestCurrencyOfPresentation();
		TotalServings = 
			Documents.PeriodEndTransactionFinancialAccounting.NotTranslatedIntoPresentationCurrency(ChartOfAccounts, Organization, Date)
			/ CountInBatch;
	Else
		Query.Text = ExchangeRateRequestTextFunctionalCurrency();
		TotalServings = 
			Documents.PeriodEndTransactionFinancialAccounting.UncoveredExchangeDifferences(ChartOfAccounts, Organization, Date)
			/ CountInBatch;
	EndIf;
	
	Replace = True;
	For PortionNumber = 0 To TotalServings Do
		
		QueryResult = Query.Execute();
		If QueryResult.IsEmpty() Then
			Break;
		EndIf;

		// Traversing a portion of the query result
		Selection = QueryResult.Select();
		While Selection.Next() Do
			
			If Selection.OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithCorrespondence Then
				Postings = GenerateTransactionsWithCorrespondenceByExchangeRateDifference(Selection);
			Else
				Postings = GenerateTransactionsWithoutCorrespondenceOnExchangeRateDifference(Selection);
			EndIf;
			
			For Each AccountingEntry In Postings Do
				If OperationType = TransactionTypes.ExchangeDifferenceCalculationPresentationCurrency Then
					AccountingEntry.Content = NStr("vi = 'Điều chỉnh tiền tệ trình bày';
													|ru = 'Корректировка курса валюты представления';
													|en = 'Adjustment of presentation currency exchange rate'; fa = 'Adjustment of presentation currency exchange rate';
													|it = 'Correzione del corso di valute visualizzazioni';
													|pl = 'Korekcja kursu waluty prezentacji';
													|tr = 'Sunum para birimi kurunun düzeltilmesi'");
					AccountingEntry.Sum = 0;
				Else
					AccountingEntry.Content = NStr("vi = 'Chênh lệch tỷ giá';
													|ru = 'Курсовая разница';
													|en = 'Exchange difference'; fa = 'Exchange difference';
													|it = 'Differenza di cambio';
													|pl = 'Różnice kursowe';
													|tr = 'Döviz kuru farkı'");
					If Selection.Currency = CurrencyOfInternationalAccounting.Presentations Then
						AccountingEntry.PresentationAmount = 0;
					Else
						AccountingEntry.PresentationAmount = ProcessingOfExchangeRatesTMClientServer.ConvertAtRate(AccountingEntry.Sum,FunctionalCurrency,PresentationCurrency);
					EndIf;
				EndIf;
			EndDo;
			
		EndDo;// serving processing
		
		RegisterRecords.International.Write(Replace);
		If Replace Then
			RegisterRecords.International.Clear();
		EndIf;
		
		RegisterRecords.InternationalWithoutCorrespondence.Write(Replace);
		If Replace Then
			RegisterRecords.InternationalWithoutCorrespondence.Clear();
		EndIf;
		Replace = False;
		
	EndDo;// for all portions
	
	RegisterRecords.International.Write = False;
	RegisterRecords.InternationalWithoutCorrespondence.Write = False;
	
EndProcedure

Procedure ReclassificationOfLongTermAssetsAndLiabilities(Cancel)
	
	OperationData = New Structure("Date,Ref,Organization,ChartOfAccounts");
	FillPropertyValues(OperationData, ThisObject);
	
	TableOfTransactions = FinancialAccountingPostingServer.TransactionsForRoutineOperations(OperationData);
	
	RecordSet = RegisterRecords.International;
	RecordSet.Clear();
	
	ErrorsMessages = New Array();
	
	For Each TransactionData In TableOfTransactions Do
		If TransactionData.Status = Enums.StatusesOfPostingsInFinancialAccounting.PostedToAccounting
		 Or TransactionData.Status = Enums.StatusesOfPostingsInFinancialAccounting.ManuallyPostedToAccounting Then
			NewEntry = RecordSet.Add();
			NewEntry.Active = True;
			FillPropertyValues(NewEntry, TransactionData);
			RecordSet.InstallExtdimension(NewEntry, TransactionData, "Dr");
			RecordSet.InstallExtdimension(NewEntry, TransactionData, "Cr");
		Else
			ErrorsMessages.Add(TransactionData.Comment);
		EndIf;
	EndDo;
	
	If ErrorsMessages.Count() > 0 Then
		Raise StrConcat(ErrorsMessages, Chars.LF);
	EndIf;
	
	RecordSet.Write = True;
	
EndProcedure

// Parameters:
// 	Selection - QueryResultSelection - LongDesc:
// 	 *AccountExtDimensionTypes - ValueTable - :
// 	  **LineNumber - Number - 
// Returns:
// 	Array of AccountingRegisterRecord.International - 
Function GenerateTransactionsWithCorrespondenceByExchangeRateDifference(Selection)
	
	ArrayOfTransactions = New Array;
	
	AccountingEntry = RegisterRecords.International.Add();
	AccountingEntry.Active = True;
	AccountingEntry.Period = Selection.Period;
	AccountingEntry.Organization = Selection.Organization;
	AccountingEntry.ChartOfAccounts = Selection.ChartOfAccounts;

	If Selection.ExchangeDifference > 0 Then// reflect the profit
		Account = "Dr";
		Balanced = "Cr";
		BalancedAccount = Selection.Income;
		BalancedExtDimension = Selection.IncomeItem;
		CorViewOfExtdimension = Selection.ExtDimensionTypeIncomeItems;
		Cor = Selection.IncomeForeignExchange;
		If Selection.RevenueByDivision Then
			Department = Selection.Department;
		EndIf;
		If Selection.RevenuesByDirection Then
			LineOfBusiness = Selection.LineOfBusiness;
		EndIf;
	Else// reflect the losses
		Account = "Cr";
		Balanced = "Dr";
		BalancedAccount = Selection.Expenses;
		BalancedExtDimension = Selection.ExpenseItem;
		CorViewOfExtdimension = Selection.ExtDimensionTypeExpenseItems;
		Cor = Selection.ExpensesForeignExchange;
		If Selection.ExpensesByDivision Then
			Department = Selection.Department;
		EndIf;
		If Selection.ExpensesByDestinations Then
			LineOfBusiness = Selection.LineOfBusiness;
		EndIf;
		
	EndIf;
	
	// fill in the invoice and the analysis of the occurrence of the exchange rate difference
	AccountingEntry["Account"+Account] = Selection.Account;
	AccountingEntry["Currency"+Account] = Selection.Currency;
	AccountingEntry["Department"+Account] = Selection.Department;
	AccountingEntry["LineOfBusiness"+Account] = Selection.LineOfBusiness;
	AccountExtDimensionTypes = Selection.AccountExtDimensionTypes.Unload(); // TabularSection - 
	For Each TableRow In AccountExtDimensionTypes Do
		If Account = "Dr" Then
			AccountingEntry.ExtDimensionsDr[TableRow.ExtDimensionType] = ExtDimensionValueOfExchangeRateDifferenceAccount(TableRow, Selection);
		Else
			AccountingEntry.ExtDimensionsCr[TableRow.ExtDimensionType] = ExtDimensionValueOfExchangeRateDifferenceAccount(TableRow, Selection);
		EndIf;
	EndDo;
	
	// fill in the account of accounting for profit / loss from the exchange rate difference
	If Not Selection.OffBalance Then
		AccountingEntry["Account" + Balanced] = BalancedAccount;
		If Cor Then
			AccountingEntry["Currency"+Balanced] = Selection.Currency;
		EndIf;
		AccountingEntry["Department"+Balanced] = Department;
		AccountingEntry["LineOfBusiness"+Balanced] = LineOfBusiness;
		
		If ValueIsFilled(BalancedExtDimension) Then
			If Balanced = "Dr" Then
				AccountingEntry.ExtDimensionsDr[CorViewOfExtdimension] = BalancedExtDimension;
			Else
				AccountingEntry.ExtDimensionsCr[CorViewOfExtdimension] = BalancedExtDimension;
			EndIf;
		EndIf;
	EndIf;
	
	AccountingEntry.Sum = Max(Selection.ExchangeDifference, -Selection.ExchangeDifference);
	AccountingEntry.PresentationAmount = AccountingEntry.Sum;
	
	ArrayOfTransactions.Add(AccountingEntry);
	
	Return ArrayOfTransactions;
	
EndFunction

// Parameters:
// 	Selection - QueryResultSelection - LongDesc:
// 	 *AccountExtDimensionTypes - ValueTable - :
// 	  **LineNumber - Number - 
// Returns:
// 	Array of AccountingRegisterRecord.InternationalWithoutCorrespondence - 
Function GenerateTransactionsWithoutCorrespondenceOnExchangeRateDifference(Selection)
	
	ArrayOfTransactions = New Array;
	
	// Add a transaction on the exchange rate difference account
	AccountingEntry = RegisterRecords.InternationalWithoutCorrespondence.Add();
	FillPropertyValues(AccountingEntry, Selection);
	AccountingEntry.Active = True;
	If Selection.ExchangeDifference > 0 Then
		AccountingEntry.RecordType = AccountingRecordType.Debit;
	Else
		AccountingEntry.RecordType = AccountingRecordType.Credit;
	EndIf;
	AccountExtDimensionTypes = Selection.AccountExtDimensionTypes.Unload(); // TabularSection - 
	For Each TableRow In AccountExtDimensionTypes Do
		AccountingEntry.ExtDimensions[TableRow.ExtDimensionType] = ExtDimensionValueOfExchangeRateDifferenceAccount(TableRow, Selection);
	EndDo;
	AccountingEntry.Sum = Max(Selection.ExchangeDifference, -Selection.ExchangeDifference);
	AccountingEntry.PresentationAmount = AccountingEntry.Sum;
	ArrayOfTransactions.Add(AccountingEntry);	
	
	// Add a transaction for income/expenses
	If Not Selection.OffBalance Then
		AccountingEntry = RegisterRecords.InternationalWithoutCorrespondence.Add();
		FillPropertyValues(AccountingEntry, Selection, , "Account");
		If Selection.ExchangeDifference > 0 Then 
			AccountingEntry.RecordType = AccountingRecordType.Credit;
			AccountingEntry.Account = Selection.Income;
			If ValueIsFilled(Selection.IncomeItem) Then
				AccountingEntry.ExtDimensions[Selection.ExtDimensionTypeIncomeItems] = Selection.IncomeItem;
			EndIf;
			If Not Selection.IncomeForeignExchange Then
				AccountingEntry.Currency = Undefined;
				AccountingEntry.CurrencyAmount = 0;
			EndIf;
		Else
			AccountingEntry.RecordType = AccountingRecordType.Debit;
			AccountingEntry.Account = Selection.Expenses;
			If ValueIsFilled(Selection.ExpenseItem) Then
				AccountingEntry.ExtDimensions[Selection.ExtDimensionTypeExpenseItems] = Selection.ExpenseItem;
			EndIf;
			If Not Selection.ExpensesForeignExchange Then
				AccountingEntry.Currency = Undefined;
				AccountingEntry.CurrencyAmount = 0;
			EndIf;
		EndIf;
		AccountingEntry.Sum = Max(Selection.ExchangeDifference, -Selection.ExchangeDifference);
		AccountingEntry.PresentationAmount = AccountingEntry.Sum;
		ArrayOfTransactions.Add(AccountingEntry);
	EndIf;
	
	Return ArrayOfTransactions;
	
EndFunction

Function ExtDimensionValueOfExchangeRateDifferenceAccount(ExtDimensionTypesString, Selection)
	
	ExtraDimensionValue = Undefined;
	ThisIsProfit = Selection.ExchangeDifference > 0;
	
	If Not ExtDimensionTypesString.TurnoversOnly Then
		ExtraDimensionValue = Selection["ExtDimension" + ExtDimensionTypesString.LineNumber];
	ElsIf ExtDimensionTypesString.ExtDimensionType = ChartsOfCharacteristicTypes.FinancialExtraDimensionTypes.CashFlowReportItems Then
		If ThisIsProfit Then
			ExtraDimensionValue = Catalogs.CashFlowReportItems.ExchangeRateDifferencesProfit_;
		Else
			ExtraDimensionValue = Catalogs.CashFlowReportItems.ExchangeDifferencesLoss;
		EndIf;
	EndIf;
	
	Return ExtraDimensionValue;
	
EndFunction

Procedure RecordTransactionsForClosingIncomeExpenseAccounts(Query, Cancel, Replace)
	
	QueryResult = Query.ExecuteBatch();
	
	If QueryResult[4].IsEmpty() Then
		Return;
	EndIf;
	
	ExtDimensionTypes = QueryResult[3].Unload(); // ValueTable - 
	ExtDimensionTypes.Indexes.Add("Account");
	
	SetOfRecordsWithoutCorrespondence = RegisterRecords.InternationalWithoutCorrespondence;
	SetOfRecordsWithoutCorrespondence.Clear();
	
	SetOfRecordsWithCorrespondence = RegisterRecords.International;
	SetOfRecordsWithCorrespondence.Clear();
	
	Selection = QueryResult[4].Select();
	While Selection.Next() Do
		If Selection.OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithoutCorrespondence Then
			GenerateTransactionsWithoutCorrespondenceForClosingIncomeExpenseAccounts(
				Selection, ExtDimensionTypes, SetOfRecordsWithoutCorrespondence);
		Else
			GenerateTransactionWithCorrespondenceOnClosingAccountsForIncomeExpenses(
				Selection, ExtDimensionTypes, SetOfRecordsWithCorrespondence);
		EndIf;
	EndDo;
	
	SetOfRecordsWithoutCorrespondence.Write(Replace);
	SetOfRecordsWithCorrespondence.Write(Replace);
	
	Replace = False;
	
EndProcedure

Procedure GenerateTransactionWithCorrespondenceOnClosingAccountsForIncomeExpenses(Selection, ExtDimensionTypes, RecordSet)
	
	NewEntry = RecordSet.Add();
	FillPropertyValues(NewEntry, Selection);
	InstallExtDimensionInCorrespondenceTransaction(NewEntry, Selection, "Dr", ExtDimensionTypes);
	InstallExtDimensionInCorrespondenceTransaction(NewEntry, Selection, "Cr", ExtDimensionTypes);
	
EndProcedure

Procedure GenerateTransactionsWithoutCorrespondenceForClosingIncomeExpenseAccounts(Selection, ExtDimensionTypes, RecordSet)
	
	NewEntry = RecordSet.Add();
	FillPropertyValues(NewEntry, Selection, "Period, ChartOfAccounts, Organization, Sum, PresentationAmount, Content");
	NewEntry.RecordType = AccountingRecordType.Debit;
	NewEntry.Department = Selection.DepartmentDr;
	NewEntry.LineOfBusiness = Selection.LineOfBusinessDr;
	NewEntry.Account = Selection.AccountDr;
	SetExtDimensionToEntryWithoutCorrespondence(NewEntry, Selection, "Dr", ExtDimensionTypes);
	NewEntry.Currency = Selection.CurrencyDr;
	NewEntry.CurrencyAmount = Selection.CurrencyAmountDr;
	
	NewEntry = RecordSet.Add();
	FillPropertyValues(NewEntry, Selection, "Period, ChartOfAccounts, Organization, Sum, PresentationAmount, Content");
	NewEntry.RecordType = AccountingRecordType.Credit;
	NewEntry.Department = Selection.DepartmentCr;
	NewEntry.LineOfBusiness = Selection.LineOfBusinessCr;
	NewEntry.Account = Selection.AccountCr;
	SetExtDimensionToEntryWithoutCorrespondence(NewEntry, Selection, "Cr", ExtDimensionTypes);
	NewEntry.Currency = Selection.CurrencyCr;
	NewEntry.CurrencyAmount = Selection.CurrencyAmountCr;
	
EndProcedure

// Fills in the subconto not by matching the subconto numbers, but by matching the types
Procedure InstallExtDimensionInCorrespondenceTransaction(NewEntry, Data, RecordType, ExtDimensionTypes)
	
	Filter = New Structure("Account", Data["Account" + RecordType]);
	AccountExtDimensionTypes = ExtDimensionTypes.FindRows(Filter);
	MaxExtDimensionCount = FinancialAccountingServerCached.MaxExtDimensionCount();
	NameExtdimension = "ExtDimension" + RecordType;
	For Each ExtDimensionType In AccountExtDimensionTypes Do
		For ExtDimensionNumber = 1 To MaxExtDimensionCount Do
			NewMeaningOfExtdimension = Data[NameExtdimension + ExtDimensionNumber];
			TypesMatch = False;
			For Each TypeOfSpeciesExtdimension In ExtDimensionType.ValueType.Types() Do
				If TypeOfSpeciesExtdimension = TypeOf(NewMeaningOfExtdimension) Then
					TypesMatch = True;
					Break;
				EndIf;
			EndDo;
			If TypesMatch Then
				NewEntry["ExtDimensions" + RecordType][ExtDimensionType.ExtDimensionType] = NewMeaningOfExtdimension;
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

// Fills in the subconto not by matching the subconto numbers, but by matching the types
Procedure SetExtDimensionToEntryWithoutCorrespondence(NewEntry, Data, RecordType, ExtDimensionTypes)
	
	Filter = New Structure("Account", Data["Account" + RecordType]);
	AccountExtDimensionTypes = ExtDimensionTypes.FindRows(Filter);
	MaxExtDimensionCount = FinancialAccountingServerCached.MaxExtDimensionCount();
	ExtDimensionNameInData = "ExtDimension" + RecordType;
	For Each ExtDimensionType In AccountExtDimensionTypes Do
		For ExtDimensionNumber = 1 To MaxExtDimensionCount Do
			NewMeaningOfExtdimension = Data[ExtDimensionNameInData + ExtDimensionNumber];
			TypesMatch = False;
			For Each TypeOfSpeciesExtdimension In ExtDimensionType.ValueType.Types() Do
				If TypeOfSpeciesExtdimension = TypeOf(NewMeaningOfExtdimension) Then
					TypesMatch = True;
					Break;
				EndIf;
			EndDo;
			If TypesMatch Then
				NewEntry["ExtDimensions"][ExtDimensionType.ExtDimensionType] = NewMeaningOfExtdimension;
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

Function TextOfRequestToCloseIncomeExpenseAccounts(NameOfInvoiceField_1, NameOfMainPartOfAccounts, ContentOfTransaction)
	
	QueryText = 
	"SELECT
	|	ConfiguringFormationOfTransactionsForOrganizationsInt.ChartOfAccounts,
	|	ConfiguringFormationOfTransactionsForOrganizationsInt.Organization,
	|	ConfiguringFormationOfTransactionsForOrganizationsInt.PostingGenerationSetting,
	|	TransactionGenerationSettings.GLAccountOfIncome AS GLAccount,
	|	TransactionGenerationSettings.GLAccountOfIncome.Type AS AccountKind,
	|	TransactionGenerationSettings.GLAccountOfIncome.AccountingByBusinessUnits AS AccountingByBusinessUnits,
	|	TransactionGenerationSettings.GLAccountOfIncome.AccountingByLinesOfBusiness AS AccountingByDirection
	|INTO TTClosingAccount
	|FROM
	|	InformationRegister.FinancialAccountingChartsOfAccountsForCompanies.SliceLast(&Date, 
	|			ChartOfAccounts = &ChartOfAccounts AND Organization = &Organization) AS ConfiguringFormationOfTransactionsForOrganizationsInt
	|	INNER JOIN
	|		Catalog.FinancialAccountingPostingGenerationSetting AS TransactionGenerationSettings
	|	ON
	|		ConfiguringFormationOfTransactionsForOrganizationsInt.PostingGenerationSetting = TransactionGenerationSettings.Ref
	|WHERE
	|	TransactionGenerationSettings.ClosingOfIncomeAndExpenseAccounts IN (&TimeFenceForClosingAccounts)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTClosingAccount.PostingGenerationSetting,
	|	AccountsToClose.Account,
	|	AccountsToClose.Account.AccountingByBusinessUnits AS AccountingByBusinessUnits,
	|	AccountsToClose.Account.AccountingByLinesOfBusiness AS AccountingByDirection
	|INTO TTAccountsToClose
	|FROM
	|	TTClosingAccount AS TTClosingAccount
	|		INNER JOIN Catalog.FinancialAccountingPostingGenerationSetting.IncomeAccounts AS AccountsToClose
	|		ON TTClosingAccount.PostingGenerationSetting = AccountsToClose.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VALUE(Enum.EntryGenerationOptions.WithCorrespondence) AS OptionForGeneratingTransactions,
	|	InternationalBalance.Account,
	|	InternationalBalance.ChartOfAccounts,
	|	InternationalBalance.Organization,
	|	CASE WHEN InternationalBalance.Account.AccountingByBusinessUnits
	|		THEN InternationalBalance.Department
	|		ELSE UNDEFINED
	|	END AS Department,
	|	CASE WHEN InternationalBalance.Account.AccountingByLinesOfBusiness
	|		THEN InternationalBalance.LineOfBusiness
	|		ELSE UNDEFINED
	|	END AS LineOfBusiness,
	|	CASE
	|		WHEN InternationalBalance.Account.Currency1
	|			THEN InternationalBalance.Currency
	|		ELSE UNDEFINED
	|	END AS Currency,
	|	InternationalBalance.ExtDimension1 AS ExtDimension1,
	|	InternationalBalance.ExtDimension2 AS ExtDimension2,
	|	InternationalBalance.ExtDimension3 AS ExtDimension3,
	|	InternationalBalance.SumBalanceDr - InternationalBalance.SumBalanceCr AS Sum,
	|	InternationalBalance.SumBalanceDr AS SumDr,
	|	InternationalBalance.SumBalanceCr AS SumCr,
	|	InternationalBalance.PresentationAmountBalanceDr - InternationalBalance.PresentationAmountBalanceCr AS PresentationAmount,
	|	InternationalBalance.PresentationAmountBalanceDr AS PresentationAmountDr,
	|	InternationalBalance.PresentationAmountBalanceCr AS PresentationAmountCr,
	|	InternationalBalance.CurrencyAmountBalanceDr - InternationalBalance.CurrencyAmountBalanceCr AS CurrencyAmount,
	|	InternationalBalance.CurrencyAmountBalanceDr AS CurrencyAmountDr,
	|	InternationalBalance.CurrencyAmountBalanceCr AS CurrencyAmountCr,
	|	InternationalBalance.Account.Type AS AccountType
	|INTO TTAccountBalances
	|FROM
	|	AccountingRegister.International.Balance(
	|			&Boundary,
	|			Account IN (SELECT T.Account FROM TTAccountsToClose AS T),
	|			,
	|			ChartOfAccounts = &ChartOfAccounts AND Organization = &Organization) AS InternationalBalance
	|			
	|UNION ALL
	|
	|SELECT
	|	VALUE(Enum.EntryGenerationOptions.WithoutCorrespondence) AS OptionForGeneratingTransactions,
	|	Balance.Account,
	|	Balance.ChartOfAccounts,
	|	Balance.Organization,
	|	CASE WHEN Balance.Account.AccountingByBusinessUnits
	|		THEN Balance.Department
	|		ELSE UNDEFINED
	|	END AS Department,
	|	CASE WHEN Balance.Account.AccountingByLinesOfBusiness
	|		THEN Balance.LineOfBusiness
	|		ELSE UNDEFINED
	|	END AS LineOfBusiness,
	|	CASE
	|		WHEN Balance.Account.Currency1
	|			THEN Balance.Currency
	|		ELSE UNDEFINED
	|	END AS Currency,
	|	Balance.ExtDimension1 AS ExtDimension1,
	|	Balance.ExtDimension2 AS ExtDimension2,
	|	Balance.ExtDimension3 AS ExtDimension3,
	|	Balance.SumBalanceDr - Balance.SumBalanceCr AS Sum,
	|	Balance.SumBalanceDr AS SumDr,
	|	Balance.SumBalanceCr AS SumCr,
	|	Balance.PresentationAmountBalanceDr - Balance.PresentationAmountBalanceCr AS PresentationAmount,
	|	Balance.PresentationAmountBalanceDr AS PresentationAmountDr,
	|	Balance.PresentationAmountBalanceCr AS PresentationAmountCr,
	|	Balance.CurrencyAmountBalanceDr - Balance.CurrencyAmountBalanceCr AS CurrencyAmount,
	|	Balance.CurrencyAmountBalanceDr AS CurrencyAmountDr,
	|	Balance.CurrencyAmountBalanceCr AS CurrencyAmountCr,
	|	Balance.Account.Type AS AccountType
	|FROM
	|	AccountingRegister.InternationalWithoutCorrespondence.Balance(
	|			&Boundary,
	|			Account IN (SELECT T.Account FROM TTAccountsToClose AS T),
	|			,
	|			ChartOfAccounts = &ChartOfAccounts AND Organization = &Organization) AS Balance
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Accounts.GLAccount AS Account,
	|	ExtDimensionTypes.LineNumber AS LineNumber,
	|	ExtDimensionTypes.ExtDimensionType AS ExtDimensionType,
	|	ExtDimensionTypes.ExtDimensionType.Description AS Description,
	|	ExtDimensionTypes.ExtDimensionType.ValueType AS ValueType,
	|	ExtDimensionTypes.TurnoversOnly AS TurnoversOnly
	|FROM
	|	TTClosingAccount AS Accounts
	|	LEFT JOIN ChartOfAccounts.International.ExtDimensionTypes AS ExtDimensionTypes
	|	ON Accounts.GLAccount = ExtDimensionTypes.Ref
	|WHERE
	|	NOT ExtDimensionTypes.Ref IS NULL
	|
	|UNION ALL
	|
	|SELECT
	|	Accounts.Account AS Account,
	|	ExtDimensionTypes.LineNumber AS LineNumber,
	|	ExtDimensionTypes.ExtDimensionType AS ExtDimensionType,
	|	ExtDimensionTypes.ExtDimensionType.Description AS Description,
	|	ExtDimensionTypes.ExtDimensionType.ValueType AS ValueType,
	|	ExtDimensionTypes.TurnoversOnly AS TurnoversOnly
	|FROM
	|	TTAccountsToClose AS Accounts
	|	LEFT JOIN ChartOfAccounts.International.ExtDimensionTypes AS ExtDimensionTypes
	|	ON Accounts.Account = ExtDimensionTypes.Ref
	|WHERE
	|	NOT ExtDimensionTypes.Ref IS NULL
	|
	|ORDER BY
	|	Account,
	|	LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|// Close the accounts
	|SELECT
	|	&Date AS Period,
	|	&Ref AS Recorder,
	|	AccountBalances.OptionForGeneratingTransactions AS OptionForGeneratingTransactions,
	|	AccountBalances.ChartOfAccounts AS ChartOfAccounts,
	|	AccountBalances.Organization AS Organization,
	|	
	|	CASE
	|		WHEN AccountBalances.Sum > 0
	|		 OR (AccountBalances.Sum = 0 AND AccountBalances.PresentationAmount > 0)
	|		 OR (AccountBalances.Sum = 0 AND AccountBalances.PresentationAmount = 0 AND AccountBalances.CurrencyAmount > 0)
	|			THEN CASE
	|				WHEN ClosingAccount.AccountingByBusinessUnits
	|					THEN AccountBalances.Department
	|				ELSE UNDEFINED
	|			END
	|		ELSE AccountBalances.Department
	|	END AS DepartmentDr,
	|	
	|	CASE
	|		WHEN AccountBalances.Sum > 0
	|		 OR (AccountBalances.Sum = 0 AND AccountBalances.PresentationAmount > 0)
	|		 OR (AccountBalances.Sum = 0 AND AccountBalances.PresentationAmount = 0 AND AccountBalances.CurrencyAmount > 0)
	|			THEN CASE
	|				WHEN ClosingAccount.AccountingByDirection
	|					THEN AccountBalances.LineOfBusiness
	|				ELSE UNDEFINED
	|			END
	|		ELSE AccountBalances.LineOfBusiness
	|	END AS LineOfBusinessDr,
	|	
	|	CASE
	|		WHEN AccountBalances.Sum > 0
	|		 OR (AccountBalances.Sum = 0 AND AccountBalances.PresentationAmount > 0)
	|		 OR (AccountBalances.Sum = 0 AND AccountBalances.PresentationAmount = 0 AND AccountBalances.CurrencyAmount > 0)
	|			THEN UNDEFINED
	|		ELSE AccountBalances.Currency
	|	END AS CurrencyDr,
	|	
	|	CASE
	|		WHEN AccountBalances.Sum > 0
	|		 OR (AccountBalances.Sum = 0 AND AccountBalances.PresentationAmount > 0)
	|		 OR (AccountBalances.Sum = 0 AND AccountBalances.PresentationAmount = 0 AND AccountBalances.CurrencyAmount > 0)
	|			THEN 0
	|		ELSE -AccountBalances.CurrencyAmount
	|	END AS CurrencyAmountDr,
	|	
	|	CASE
	|		WHEN AccountBalances.Sum > 0
	|		 OR (AccountBalances.Sum = 0 AND AccountBalances.PresentationAmount > 0)
	|		 OR (AccountBalances.Sum = 0 AND AccountBalances.PresentationAmount = 0 AND AccountBalances.CurrencyAmount > 0)
	|			THEN ClosingAccount.GLAccount
	|		ELSE AccountBalances.Account
	|	END AS AccountDr,
	|	
	|	AccountBalances.ExtDimension1 AS ExtDimensionDr1,
	|	AccountBalances.ExtDimension2 AS ExtDimensionDr2,
	|	AccountBalances.ExtDimension3 AS ExtDimensionDr3,
	|	
	|	CASE
	|		WHEN AccountBalances.Sum > 0
	|		 OR (AccountBalances.Sum = 0 AND AccountBalances.PresentationAmount > 0)
	|		 OR (AccountBalances.Sum = 0 AND AccountBalances.PresentationAmount = 0 AND AccountBalances.CurrencyAmount > 0)
	|			THEN AccountBalances.Department
	|		ELSE CASE
	|			WHEN ClosingAccount.AccountingByBusinessUnits
	|				THEN AccountBalances.Department
	|			ELSE UNDEFINED
	|		END
	|	END AS DepartmentCr,
	|	
	|	CASE
	|		WHEN AccountBalances.Sum > 0
	|		 OR (AccountBalances.Sum = 0 AND AccountBalances.PresentationAmount > 0)
	|		 OR (AccountBalances.Sum = 0 AND AccountBalances.PresentationAmount = 0 AND AccountBalances.CurrencyAmount > 0)
	|			THEN AccountBalances.LineOfBusiness
	|		ELSE CASE
	|			WHEN ClosingAccount.AccountingByDirection
	|				THEN AccountBalances.LineOfBusiness
	|			ELSE UNDEFINED
	|		END
	|	END AS LineOfBusinessCr,
	|	
	|	CASE
	|		WHEN AccountBalances.Sum > 0
	|		 OR (AccountBalances.Sum = 0 AND AccountBalances.PresentationAmount > 0)
	|		 OR (AccountBalances.Sum = 0 AND AccountBalances.PresentationAmount = 0 AND AccountBalances.CurrencyAmount > 0)
	|			THEN AccountBalances.Currency
	|		ELSE UNDEFINED
	|	END AS CurrencyCr,
	|	
	|	CASE
	|		WHEN AccountBalances.Sum > 0
	|		 OR (AccountBalances.Sum = 0 AND AccountBalances.PresentationAmount > 0)
	|		 OR (AccountBalances.Sum = 0 AND AccountBalances.PresentationAmount = 0 AND AccountBalances.CurrencyAmount > 0)
	|			THEN AccountBalances.CurrencyAmount
	|		ELSE 0
	|	END AS CurrencyAmountCr,
	|	
	|	CASE
	|		WHEN AccountBalances.Sum > 0
	|		 OR (AccountBalances.Sum = 0 AND AccountBalances.PresentationAmount > 0)
	|		 OR (AccountBalances.Sum = 0 AND AccountBalances.PresentationAmount = 0 AND AccountBalances.CurrencyAmount > 0)
	|			THEN AccountBalances.Account
	|		ELSE ClosingAccount.GLAccount
	|	END AS AccountCr,
	|	
	|	AccountBalances.ExtDimension1 AS ExtDimensionCr1,
	|	AccountBalances.ExtDimension2 AS ExtDimensionCr2,
	|	AccountBalances.ExtDimension3 AS ExtDimensionCr3,
	|	
	|	CASE
	|		WHEN AccountBalances.Sum < 0
	|			THEN -AccountBalances.Sum
	|		ELSE AccountBalances.Sum
	|	END AS Sum,
	|	
	|	CASE
	|		WHEN AccountBalances.Sum < 0
	|		 OR (AccountBalances.Sum = 0 AND AccountBalances.PresentationAmount < 0)
	|			THEN -AccountBalances.PresentationAmount
	|		ELSE AccountBalances.PresentationAmount
	|	END AS PresentationAmount,
	|	
	|	0 AS CurrencyAmount,
	|	
	|	&Content AS Content,
	|	UNDEFINED AS PostingTemplate,
	|	UNDEFINED AS PostingType,
	|	AccountBalances.AccountType
	|FROM
	|	TTAccountBalances AS AccountBalances
	|	LEFT JOIN TTClosingAccount AS ClosingAccount
	|	ON TRUE";
	
	QueryText = StrReplace(QueryText, "GLAccountOfIncome" , NameOfInvoiceField_1);
	QueryText = StrReplace(QueryText, "IncomeAccounts"		, NameOfMainPartOfAccounts);
	QueryText = StrReplace(QueryText, "&Content", """"+ContentOfTransaction+"""");
	
	Return QueryText;
	
EndFunction

Function ExchangeRateRequestTextFunctionalCurrency()
	
	QueryText = 
	"SELECT
	|	ConfiguringFormationOfTransactionsForOrganizationsInt.ChartOfAccounts AS ChartOfAccounts,
	|	ConfiguringFormationOfTransactionsForOrganizationsInt.Organization AS Organization,
	|	ConfiguringFormationOfTransactionsForOrganizationsInt.PostingGenerationSetting,
	|	TransactionGenerationSettings.ForeignExchangeGain AS ForeignExchangeGain,
	|	TransactionGenerationSettings.IncomeItemForExchangeDifferences AS IncomeItemForExchangeDifferences,
	|	VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.IncomeItems) AS ExtDimensionTypeIncomeItems,
	|	TransactionGenerationSettings.GLAccountOfExchangeLoss AS GLAccountOfExchangeLoss,
	|	TransactionGenerationSettings.ExpenseItemForExchangeLoss AS ExpenseItemForExchangeLoss,
	|	VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.ExpenseItems) AS ExtDimensionTypeExpenseItems,
	|	TransactionGenerationSettings.ForeignExchangeGain.Currency1 AS IncomeForeignExchange,
	|	TransactionGenerationSettings.GLAccountOfExchangeLoss.Currency1 AS ExpensesForeignExchange
	|INTO TTAccountsKr
	|FROM
	|	InformationRegister.FinancialAccountingChartsOfAccountsForCompanies.SliceLast(&Date, 
	|			ChartOfAccounts = &ChartOfAccounts AND Organization = &Organization) AS ConfiguringFormationOfTransactionsForOrganizationsInt
	|		INNER JOIN Catalog.FinancialAccountingPostingGenerationSetting AS TransactionGenerationSettings
	|		ON ConfiguringFormationOfTransactionsForOrganizationsInt.PostingGenerationSetting = TransactionGenerationSettings.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CurrencyRatesCut.Period,
	|	CurrencyRatesCut.Currency AS Currency,
	|	CurrencyRatesCut.CourseNumerator,
	|	CurrencyRatesCut.CourseDenominator
	|INTO TTExchangeRate
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(&Date, BaseCurrency = &LocalAccountingCurrency) AS CurrencyRatesCut
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ContractCourse.Contract AS Contract,
	|	ContractCourse.CourseNumerator AS CourseNumerator,
	|	ContractCourse.CourseDenominator AS CourseDenominator
	|INTO ContractTTCourses
	|FROM
	|	InformationRegister.ARAPAccountingExchangeRatesForContracts.SliceLast(&Date) AS ContractCourse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VALUE(Enum.EntryGenerationOptions.WithCorrespondence) AS OptionForGeneratingTransactions,
	|	InternationalBalance.Account,
	|	InternationalBalance.ChartOfAccounts,
	|	InternationalBalance.Organization,
	|	InternationalBalance.Department,
	|	InternationalBalance.LineOfBusiness,
	|	InternationalBalance.Currency,
	|	CASE
	|		WHEN InternationalExtdimensionDay1.Currency1
	|			THEN InternationalBalance.ExtDimension1
	|		ELSE NULL
	|	END AS ExtDimension1,
	|	CASE
	|		WHEN InternationalExtdimensionDay2.Currency1
	|			THEN InternationalBalance.ExtDimension2
	|		ELSE NULL
	|	END AS ExtDimension2,
	|	CASE
	|		WHEN InternationalExtdimensionDay3.Currency1
	|			THEN InternationalBalance.ExtDimension3
	|		ELSE NULL
	|	END AS ExtDimension3,
	|	SUM(InternationalBalance.SumBalance) AS SumBalance,
	|	SUM(InternationalBalance.CurrencyAmountBalance) AS CurrencyAmountBalance
	|INTO TTAccountBalances
	|FROM
	|	AccountingRegister.International.Balance(
	|			&Boundary,
	|			Account.Currency1
	|				AND NOT Account.ExcludeFromExchangeDifferenceCalculationInFunctionalCurrency,
	|			,
	|			ChartOfAccounts = &ChartOfAccounts AND Organization = &Organization) AS InternationalBalance
	|		LEFT JOIN ChartOfAccounts.International.ExtDimensionTypes AS InternationalExtdimensionDay1
	|		ON InternationalBalance.Account = InternationalExtdimensionDay1.Ref
	|			AND (InternationalExtdimensionDay1.LineNumber = 1)
	|		LEFT JOIN ChartOfAccounts.International.ExtDimensionTypes AS InternationalExtdimensionDay2
	|		ON InternationalBalance.Account = InternationalExtdimensionDay2.Ref
	|			AND (InternationalExtdimensionDay2.LineNumber = 2)
	|		LEFT JOIN ChartOfAccounts.International.ExtDimensionTypes AS InternationalExtdimensionDay3
	|		ON InternationalBalance.Account = InternationalExtdimensionDay3.Ref
	|			AND (InternationalExtdimensionDay3.LineNumber = 3)
	|
	|GROUP BY
	|	InternationalBalance.Account,
	|	CASE
	|		WHEN InternationalExtdimensionDay1.Currency1
	|			THEN InternationalBalance.ExtDimension1
	|		ELSE NULL
	|	END,
	|	CASE
	|		WHEN InternationalExtdimensionDay2.Currency1
	|			THEN InternationalBalance.ExtDimension2
	|		ELSE NULL
	|	END,
	|	CASE
	|		WHEN InternationalExtdimensionDay3.Currency1
	|			THEN InternationalBalance.ExtDimension3
	|		ELSE NULL
	|	END,
	|	InternationalBalance.ChartOfAccounts,
	|	InternationalBalance.Organization,
	|	InternationalBalance.Department,
	|	InternationalBalance.LineOfBusiness,
	|	InternationalBalance.Currency
	|	
	|UNION ALL
	|
	|SELECT
	|	VALUE(Enum.EntryGenerationOptions.WithoutCorrespondence) AS OptionForGeneratingTransactions,
	|	Balance.Account,
	|	Balance.ChartOfAccounts,
	|	Balance.Organization,
	|	Balance.Department,
	|	Balance.LineOfBusiness,
	|	Balance.Currency,
	|	CASE
	|		WHEN InternationalExtdimensionDay1.Currency1
	|			THEN Balance.ExtDimension1
	|		ELSE NULL
	|	END AS ExtDimension1,
	|	CASE
	|		WHEN InternationalExtdimensionDay2.Currency1
	|			THEN Balance.ExtDimension2
	|		ELSE NULL
	|	END AS ExtDimension2,
	|	CASE
	|		WHEN InternationalExtdimensionDay3.Currency1
	|			THEN Balance.ExtDimension3
	|		ELSE NULL
	|	END AS ExtDimension3,
	|	SUM(Balance.SumBalance) AS SumBalance,
	|	SUM(Balance.CurrencyAmountBalance) AS CurrencyAmountBalance
	|FROM
	|	AccountingRegister.InternationalWithoutCorrespondence.Balance(
	|			&Boundary,
	|			Account.Currency1
	|				AND NOT Account.ExcludeFromExchangeDifferenceCalculationInFunctionalCurrency,
	|			,
	|			ChartOfAccounts = &ChartOfAccounts AND Organization = &Organization) AS Balance
	|		LEFT JOIN ChartOfAccounts.International.ExtDimensionTypes AS InternationalExtdimensionDay1
	|		ON Balance.Account = InternationalExtdimensionDay1.Ref
	|			AND (InternationalExtdimensionDay1.LineNumber = 1)
	|		LEFT JOIN ChartOfAccounts.International.ExtDimensionTypes AS InternationalExtdimensionDay2
	|		ON Balance.Account = InternationalExtdimensionDay2.Ref
	|			AND (InternationalExtdimensionDay2.LineNumber = 2)
	|		LEFT JOIN ChartOfAccounts.International.ExtDimensionTypes AS InternationalExtdimensionDay3
	|		ON Balance.Account = InternationalExtdimensionDay3.Ref
	|			AND (InternationalExtdimensionDay3.LineNumber = 3)
	|
	|GROUP BY
	|	Balance.Account,
	|	CASE
	|		WHEN InternationalExtdimensionDay1.Currency1
	|			THEN Balance.ExtDimension1
	|		ELSE NULL
	|	END,
	|	CASE
	|		WHEN InternationalExtdimensionDay2.Currency1
	|			THEN Balance.ExtDimension2
	|		ELSE NULL
	|	END,
	|	CASE
	|		WHEN InternationalExtdimensionDay3.Currency1
	|			THEN Balance.ExtDimension3
	|		ELSE NULL
	|	END,
	|	Balance.ChartOfAccounts,
	|	Balance.Organization,
	|	Balance.Department,
	|	Balance.LineOfBusiness,
	|	Balance.Currency
	|INDEX BY SETS
	|	(
	|		(ExtDimension1, ExtDimension2, ExtDimension3),
	|		(ExtDimension2),
	|		(ExtDimension3)
	|	)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CounterpartyContracts.Ref                                             AS Contract,
	|	CounterpartyContracts.ContractRateOption                               AS ContractRateOption,
	|	CounterpartyContracts.ARAPCurrency                               AS ARAPCurrency,
	|	ISNULL(ExchangeRatesOfSettlementsUnderContractsCutOfLatest.CourseNumerator, 1)   AS CourseNumerator,
	|	ISNULL(ExchangeRatesOfSettlementsUnderContractsCutOfLatest.CourseDenominator, 1) AS CourseDenominator
	|INTO TTContracts
	|FROM
	|	Catalog.CounterpartyContracts AS CounterpartyContracts
	|		LEFT JOIN ContractTTCourses AS ExchangeRatesOfSettlementsUnderContractsCutOfLatest
	|		ON CounterpartyContracts.Ref = ExchangeRatesOfSettlementsUnderContractsCutOfLatest.Contract
	|WHERE
	|	CounterpartyContracts.Ref IN
	|			(SELECT
	|				TTAccountBalances.ExtDimension1
	|			FROM
	|				TTAccountBalances
	|		
	|			UNION ALL
	|		
	|			SELECT
	|				TTAccountBalances.ExtDimension2
	|			FROM
	|				TTAccountBalances
	|		
	|			UNION ALL
	|		
	|			SELECT
	|				TTAccountBalances.ExtDimension3
	|			FROM
	|				TTAccountBalances)
	|
	|UNION ALL
	|
	|SELECT
	|	IntercompanyContracts.Ref                                       AS Contract,
	|	IntercompanyContracts.ContractRateOption                         AS ContractRateOption,
	|	IntercompanyContracts.ARAPCurrency                         AS ARAPCurrency,
	|	ISNULL(ExchangeRatesOfSettlementsUnderContractsCutOfLatest.CourseNumerator, 1)   AS CourseNumerator,
	|	ISNULL(ExchangeRatesOfSettlementsUnderContractsCutOfLatest.CourseDenominator, 1) AS CourseDenominator
	|FROM
	|	Catalog.IntercompanyContracts AS IntercompanyContracts
	|		LEFT JOIN ContractTTCourses AS ExchangeRatesOfSettlementsUnderContractsCutOfLatest
	|		ON IntercompanyContracts.Ref = ExchangeRatesOfSettlementsUnderContractsCutOfLatest.Contract
	|WHERE
	|	IntercompanyContracts.Ref IN
	|			(SELECT
	|				TTAccountBalances.ExtDimension1
	|			FROM
	|				TTAccountBalances
	|		
	|			UNION ALL
	|		
	|			SELECT
	|				TTAccountBalances.ExtDimension2
	|			FROM
	|				TTAccountBalances
	|		
	|			UNION ALL
	|		
	|			SELECT
	|				TTAccountBalances.ExtDimension3
	|			FROM
	|				TTAccountBalances)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccountBalances.OptionForGeneratingTransactions                         AS OptionForGeneratingTransactions,
	|	AccountBalances.Account                                                AS Account,
	|	AccountBalances.ChartOfAccounts                                          AS ChartOfAccounts,
	|	AccountBalances.Organization                                         AS Organization,
	|	AccountBalances.Department                                       AS Department,
	|	AccountBalances.LineOfBusiness                             AS LineOfBusiness,
	|	AccountBalances.ExtDimension1                                           AS ExtDimension1,
	|	AccountBalances.ExtDimension2                                           AS ExtDimension2,
	|	AccountBalances.ExtDimension3                                           AS ExtDimension3,
	|	AccountBalances.Currency                                              AS Currency,
	|	AccountBalances.CurrencyAmountBalance                                AS CurrencyAmountBalance,
	|	AccountBalances.SumBalance                                        AS SumBalance,
	|	ISNULL(
	|		ISNULL(
	|			TTContracts1.ContractRateOption,
	|			TTContracts2.ContractRateOption),
	|		ISNULL(
	|			TTContracts3.ContractRateOption,
	|			VALUE(Enum.ContractRateOptions.Mutable))) AS ContractRateOption,
	|	ISNULL(
	|		ISNULL(
	|			TTContracts1.CourseNumerator,
	|			TTContracts2.CourseNumerator),
	|		ISNULL(
	|			TTContracts3.CourseNumerator,
	|			1))                                                       AS CourseNumerator,
	|	ISNULL(
	|		ISNULL(
	|			TTContracts1.CourseDenominator,
	|			TTContracts2.CourseDenominator),
	|		ISNULL(
	|			TTContracts3.CourseDenominator,
	|			1))                                                       AS CourseDenominator,
	|	ISNULL(
	|		ISNULL(
	|			TTContracts1.ARAPCurrency,
	|			TTContracts2.ARAPCurrency),
	|		ISNULL(
	|			TTContracts3.ARAPCurrency,
	|			UNDEFINED))                                            AS ARAPCurrency
	|INTO AccountBalancesWithContractExchangeRateTT
	|FROM
	|	TTAccountBalances AS AccountBalances
	|		LEFT JOIN TTContracts AS TTContracts1
	|		ON AccountBalances.ExtDimension1 = TTContracts1.Contract
	|		LEFT JOIN TTContracts AS TTContracts2
	|		ON AccountBalances.ExtDimension2 = TTContracts2.Contract
	|		LEFT JOIN TTContracts AS TTContracts3
	|		ON AccountBalances.ExtDimension3 = TTContracts3.Contract
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTBalancesWithRateOfContract.OptionForGeneratingTransactions AS OptionForGeneratingTransactions,
	|	TTBalancesWithRateOfContract.Account                        AS Account,
	|	TTBalancesWithRateOfContract.ChartOfAccounts                  AS ChartOfAccounts,
	|	TTBalancesWithRateOfContract.Organization                 AS Organization,
	|	TTBalancesWithRateOfContract.Department               AS Department,
	|	TTBalancesWithRateOfContract.LineOfBusiness     AS LineOfBusiness,
	|	TTBalancesWithRateOfContract.ExtDimension1                   AS ExtDimension1,
	|	TTBalancesWithRateOfContract.ExtDimension2                   AS ExtDimension2,
	|	TTBalancesWithRateOfContract.ExtDimension3                   AS ExtDimension3,
	|	TTBalancesWithRateOfContract.Currency                      AS Currency,
	|	TTBalancesWithRateOfContract.CurrencyAmountBalance        AS CurrencyAmountBalance,
	|	TTBalancesWithRateOfContract.SumBalance                AS SumBalance,
	|	TTBalancesWithRateOfContract.ContractRateOption        AS ContractRateOption,
	|	CASE
	|		WHEN TTBalancesWithRateOfContract.ContractRateOption = VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|				AND TTBalancesWithRateOfContract.Currency = TTBalancesWithRateOfContract.ARAPCurrency
	|			THEN TTBalancesWithRateOfContract.CourseNumerator
	|		ELSE TTExchangeRate.CourseNumerator
	|	END                                                AS CourseNumerator,
	|	CASE
	|		WHEN TTBalancesWithRateOfContract.ContractRateOption = VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|				AND TTBalancesWithRateOfContract.Currency = TTBalancesWithRateOfContract.ARAPCurrency
	|			THEN TTBalancesWithRateOfContract.CourseDenominator
	|		ELSE TTExchangeRate.CourseDenominator
	|	END                                                AS CourseDenominator,
	|	CASE
	|		WHEN TTBalancesWithRateOfContract.ContractRateOption = VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|				AND &FunctionalCurrency = TTBalancesWithRateOfContract.ARAPCurrency
	|			THEN TTBalancesWithRateOfContract.CourseNumerator
	|		ELSE &CourseNumeratorFV
	|	END                                            AS RateIsNumeratorOfFunctionalCurrency,
	|	CASE
	|		WHEN TTBalancesWithRateOfContract.ContractRateOption = VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|				AND &FunctionalCurrency = TTBalancesWithRateOfContract.ARAPCurrency
	|			THEN TTBalancesWithRateOfContract.CourseDenominator
	|		ELSE &CourseDenominatorFV
	|	END                                            AS ExchangeRateDenominator_FunctionalCurrency
	|INTO TTAccountBalancesWithExchangeRates
	|FROM
	|	AccountBalancesWithContractExchangeRateTT AS TTBalancesWithRateOfContract
	|		LEFT JOIN TTExchangeRate AS TTExchangeRate
	|		ON TTBalancesWithRateOfContract.Currency = TTExchangeRate.Currency
	|WHERE
	|	TTBalancesWithRateOfContract.ContractRateOption <> VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1000
	|	&Date AS Period,
	|	AccountBalances.OptionForGeneratingTransactions AS OptionForGeneratingTransactions,
	|	AccountBalances.Account,
	|	AccountBalances.Account.Type AS AccountType,
	|	AccountBalances.Account.OffBalance AS OffBalance,
	|	AccountBalances.ChartOfAccounts,
	|	AccountBalances.Organization,
	|	CASE WHEN AccountBalances.Account.AccountingByBusinessUnits
	|		THEN AccountBalances.Department
	|		ELSE UNDEFINED
	|	END AS Department,
	|	CASE WHEN AccountBalances.Account.AccountingByLinesOfBusiness
	|		THEN AccountBalances.LineOfBusiness
	|		ELSE UNDEFINED
	|	END AS LineOfBusiness,
	|	AccountBalances.Account.ExtDimensionTypes.(
	|		LineNumber AS LineNumber,
	|		ExtDimensionType AS ExtDimensionType,
	|		TurnoversOnly AS TurnoversOnly
	|	) AS AccountExtDimensionTypes,
	|	AccountBalances.ExtDimension1,
	|	AccountBalances.ExtDimension2,
	|	AccountBalances.ExtDimension3,
	|	AccountBalances.CourseNumerator,
	|	AccountBalances.CourseDenominator,
	|	AccountBalances.Currency AS Currency,
	|	AccountBalances.CurrencyAmountBalance,
	|	CAST(AccountBalances.CurrencyAmountBalance * AccountBalances.CourseNumerator / AccountBalances.CourseDenominator / AccountBalances.RateIsNumeratorOfFunctionalCurrency * AccountBalances.ExchangeRateDenominator_FunctionalCurrency AS NUMBER(31,2)) AS ValSumFV,
	|	AccountBalances.SumBalance,
	|	(CAST(AccountBalances.CurrencyAmountBalance * AccountBalances.CourseNumerator / AccountBalances.CourseDenominator / AccountBalances.RateIsNumeratorOfFunctionalCurrency * AccountBalances.ExchangeRateDenominator_FunctionalCurrency AS NUMBER(31,2))) - AccountBalances.SumBalance AS ExchangeDifference,
	|	AccountBalances.Account.Order AS AccountOrder,
	|	TTAccountsKr.ForeignExchangeGain AS Income,
	|	TTAccountsKr.IncomeItemForExchangeDifferences AS IncomeItem,
	|	TTAccountsKr.ExtDimensionTypeIncomeItems,
	|	ISNULL(TTAccountsKr.IncomeForeignExchange, FALSE) AS IncomeForeignExchange,
	|	ISNULL(TTAccountsKr.ForeignExchangeGain.AccountingByBusinessUnits, FALSE) AS RevenueByDivision,
	|	ISNULL(TTAccountsKr.ForeignExchangeGain.AccountingByLinesOfBusiness, FALSE) AS RevenuesByDirection,
	|	TTAccountsKr.GLAccountOfExchangeLoss AS Expenses,
	|	TTAccountsKr.ExpenseItemForExchangeLoss AS ExpenseItem,
	|	TTAccountsKr.ExtDimensionTypeExpenseItems,
	|	ISNULL(TTAccountsKr.ExpensesForeignExchange, FALSE) AS ExpensesForeignExchange,
	|	ISNULL(TTAccountsKr.GLAccountOfExchangeLoss.AccountingByBusinessUnits, FALSE) AS ExpensesByDivision,
	|	ISNULL(TTAccountsKr.GLAccountOfExchangeLoss.AccountingByLinesOfBusiness, FALSE) AS ExpensesByDestinations
	|FROM
	|	TTAccountBalancesWithExchangeRates AS AccountBalances
	|		LEFT JOIN TTAccountsKr AS TTAccountsKr
	|		ON AccountBalances.ChartOfAccounts = TTAccountsKr.ChartOfAccounts
	|			AND AccountBalances.Organization = TTAccountsKr.Organization
	|WHERE
	|	(CAST(AccountBalances.CurrencyAmountBalance * AccountBalances.CourseNumerator / AccountBalances.CourseDenominator / AccountBalances.RateIsNumeratorOfFunctionalCurrency * AccountBalances.ExchangeRateDenominator_FunctionalCurrency AS NUMBER(31,2))) - AccountBalances.SumBalance <> 0
	|
	|ORDER BY
	|	AccountOrder";
	
	Return QueryText;
	
EndFunction

Function TextOfExchangeRateRequestCurrencyOfPresentation()
	
	QueryText = 
	"SELECT
	|	ConfiguringFormationOfTransactionsForOrganizationsInt.ChartOfAccounts,
	|	ConfiguringFormationOfTransactionsForOrganizationsInt.Organization,
	|	ConfiguringFormationOfTransactionsForOrganizationsInt.PostingGenerationSetting,
	|	TransactionGenerationSettings.IncomeFromTranslationToPresentationCurrency AS Income,
	|	TransactionGenerationSettings.IncomeExpenseItemForRecalculationVariances AS IncomeItem,
	|	VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.IncomeItems) AS ExtDimensionTypeIncomeItems,
	|	TransactionGenerationSettings.ExpensesDifferencesArisingFromConversionToPresentationCurrency AS Expenses,
	|	TransactionGenerationSettings.ExpenseItemForTranslationsReserve AS ExpenseItem,
	|	VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.ExpenseItems) AS ExtDimensionTypeExpenseItems,
	|	TransactionGenerationSettings.IncomeFromTranslationToPresentationCurrency.Currency1 AS IncomeForeignExchange,
	|	TransactionGenerationSettings.ExpensesDifferencesArisingFromConversionToPresentationCurrency.Currency1 AS ExpensesForeignExchange
	|INTO TTAccountAccounting
	|FROM
	|	InformationRegister.FinancialAccountingChartsOfAccountsForCompanies.SliceLast(&Date, ChartOfAccounts = &ChartOfAccounts AND Organization = &Organization) AS ConfiguringFormationOfTransactionsForOrganizationsInt
	|		INNER JOIN Catalog.FinancialAccountingPostingGenerationSetting AS TransactionGenerationSettings
	|		ON ConfiguringFormationOfTransactionsForOrganizationsInt.PostingGenerationSetting = TransactionGenerationSettings.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ConfiguringFormationOfTransactionsForOrganizationsInt.ChartOfAccounts,
	|	ConfiguringFormationOfTransactionsForOrganizationsInt.Organization,
	|	ConfiguringFormationOfTransactionsForOrganizationsInt.PostingGenerationSetting,
	|	ExcludeTransactionGenerationSettingsFromEAPRecalculation.Account
	|INTO TTAccountExceptions
	|FROM
	|	InformationRegister.FinancialAccountingChartsOfAccountsForCompanies.SliceLast(&Date, ChartOfAccounts = &ChartOfAccounts AND Organization = &Organization) AS ConfiguringFormationOfTransactionsForOrganizationsInt
	|		INNER JOIN Catalog.FinancialAccountingPostingGenerationSetting.ExcludeFromRecalculationToPresentationCurrency AS ExcludeTransactionGenerationSettingsFromEAPRecalculation
	|		ON ConfiguringFormationOfTransactionsForOrganizationsInt.PostingGenerationSetting = ExcludeTransactionGenerationSettingsFromEAPRecalculation.Ref
	|
	|UNION
	|
	|SELECT
	|	TTAccountAccounting.ChartOfAccounts,
	|	TTAccountAccounting.Organization,
	|	TTAccountAccounting.PostingGenerationSetting,
	|	TTAccountAccounting.Income
	|FROM
	|	TTAccountAccounting AS TTAccountAccounting
	|
	|UNION
	|
	|SELECT
	|	TTAccountAccounting.ChartOfAccounts,
	|	TTAccountAccounting.Organization,
	|	TTAccountAccounting.PostingGenerationSetting,
	|	TTAccountAccounting.Expenses
	|FROM
	|	TTAccountAccounting AS TTAccountAccounting
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CurrencyRatesCut.Period,
	|	CurrencyRatesCut.Currency,
	|	CurrencyRatesCut.CourseNumerator,
	|	CurrencyRatesCut.CourseDenominator
	|INTO TTExchangeRate
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(&Date, BaseCurrency = &LocalAccountingCurrency) AS CurrencyRatesCut
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ContractCourse.Contract AS Contract,
	|	ContractCourse.CourseNumerator AS CourseNumerator,
	|	ContractCourse.CourseDenominator AS CourseDenominator
	|INTO ContractTTCourses
	|FROM
	|	InformationRegister.ARAPAccountingExchangeRatesForContracts.SliceLast(&Date) AS ContractCourse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VALUE(Enum.EntryGenerationOptions.WithCorrespondence) AS OptionForGeneratingTransactions,
	|	InternationalBalance.Account,
	|	InternationalBalance.ChartOfAccounts,
	|	InternationalBalance.Organization,
	|	InternationalBalance.Department,
	|	InternationalBalance.LineOfBusiness,
	|	InternationalBalance.Currency,
	|	CASE
	|		WHEN InternationalExtdimensionDay1.Currency1
	|			THEN InternationalBalance.ExtDimension1
	|		ELSE NULL
	|	END AS ExtDimension1,
	|	CASE
	|		WHEN InternationalExtdimensionDay2.Currency1
	|			THEN InternationalBalance.ExtDimension2
	|		ELSE NULL
	|	END AS ExtDimension2,
	|	CASE
	|		WHEN InternationalExtdimensionDay3.Currency1
	|			THEN InternationalBalance.ExtDimension3
	|		ELSE NULL
	|	END AS ExtDimension3,
	|	SUM(InternationalBalance.SumBalance) AS SumBalance,
	|	SUM(InternationalBalance.CurrencyAmountBalance) AS CurrencyAmountBalance,
	|	SUM(InternationalBalance.PresentationAmountBalance) AS PresentationAmountBalance
	|INTO TTAccountBalances
	|FROM
	|	AccountingRegister.International.Balance(
	|			&Boundary,
	|			NOT Account IN (SELECT TTAccountExceptions.Account FROM TTAccountExceptions),
	|			,
	|			ChartOfAccounts = &ChartOfAccounts AND Organization = &Organization) AS InternationalBalance
	|		LEFT JOIN ChartOfAccounts.International.ExtDimensionTypes AS InternationalExtdimensionDay1
	|		ON InternationalBalance.Account = InternationalExtdimensionDay1.Ref
	|			AND (InternationalExtdimensionDay1.LineNumber = 1)
	|		LEFT JOIN ChartOfAccounts.International.ExtDimensionTypes AS InternationalExtdimensionDay2
	|		ON InternationalBalance.Account = InternationalExtdimensionDay2.Ref
	|			AND (InternationalExtdimensionDay2.LineNumber = 2)
	|		LEFT JOIN ChartOfAccounts.International.ExtDimensionTypes AS InternationalExtdimensionDay3
	|		ON InternationalBalance.Account = InternationalExtdimensionDay3.Ref
	|			AND (InternationalExtdimensionDay3.LineNumber = 3)
	|
	|GROUP BY
	|	InternationalBalance.Account,
	|	CASE
	|		WHEN InternationalExtdimensionDay1.Currency1
	|			THEN InternationalBalance.ExtDimension1
	|		ELSE NULL
	|	END,
	|	CASE
	|		WHEN InternationalExtdimensionDay2.Currency1
	|			THEN InternationalBalance.ExtDimension2
	|		ELSE NULL
	|	END,
	|	CASE
	|		WHEN InternationalExtdimensionDay3.Currency1
	|			THEN InternationalBalance.ExtDimension3
	|		ELSE NULL
	|	END,
	|	InternationalBalance.ChartOfAccounts,
	|	InternationalBalance.Organization,
	|	InternationalBalance.Department,
	|	InternationalBalance.LineOfBusiness,
	|	InternationalBalance.Currency
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(Enum.EntryGenerationOptions.WithoutCorrespondence) AS OptionForGeneratingTransactions,
	|	Balance.Account,
	|	Balance.ChartOfAccounts,
	|	Balance.Organization,
	|	Balance.Department,
	|	Balance.LineOfBusiness,
	|	Balance.Currency,
	|	CASE
	|		WHEN InternationalExtdimensionDay1.Currency1
	|			THEN Balance.ExtDimension1
	|		ELSE NULL
	|	END AS ExtDimension1,
	|	CASE
	|		WHEN InternationalExtdimensionDay2.Currency1
	|			THEN Balance.ExtDimension2
	|		ELSE NULL
	|	END AS ExtDimension2,
	|	CASE
	|		WHEN InternationalExtdimensionDay3.Currency1
	|			THEN Balance.ExtDimension3
	|		ELSE NULL
	|	END AS ExtDimension3,
	|	SUM(Balance.SumBalance) AS SumBalance,
	|	SUM(Balance.CurrencyAmountBalance) AS CurrencyAmountBalance,
	|	SUM(Balance.PresentationAmountBalance) AS PresentationAmountBalance
	|FROM
	|	AccountingRegister.InternationalWithoutCorrespondence.Balance(
	|			&Boundary,
	|			NOT Account IN (SELECT TTAccountExceptions.Account FROM TTAccountExceptions),
	|			,
	|			ChartOfAccounts = &ChartOfAccounts AND Organization = &Organization) AS Balance
	|		LEFT JOIN ChartOfAccounts.International.ExtDimensionTypes AS InternationalExtdimensionDay1
	|		ON Balance.Account = InternationalExtdimensionDay1.Ref
	|			AND (InternationalExtdimensionDay1.LineNumber = 1)
	|		LEFT JOIN ChartOfAccounts.International.ExtDimensionTypes AS InternationalExtdimensionDay2
	|		ON Balance.Account = InternationalExtdimensionDay2.Ref
	|			AND (InternationalExtdimensionDay2.LineNumber = 2)
	|		LEFT JOIN ChartOfAccounts.International.ExtDimensionTypes AS InternationalExtdimensionDay3
	|		ON Balance.Account = InternationalExtdimensionDay3.Ref
	|			AND (InternationalExtdimensionDay3.LineNumber = 3)
	|
	|GROUP BY
	|	Balance.Account,
	|	CASE
	|		WHEN InternationalExtdimensionDay1.Currency1
	|			THEN Balance.ExtDimension1
	|		ELSE NULL
	|	END,
	|	CASE
	|		WHEN InternationalExtdimensionDay2.Currency1
	|			THEN Balance.ExtDimension2
	|		ELSE NULL
	|	END,
	|	CASE
	|		WHEN InternationalExtdimensionDay3.Currency1
	|			THEN Balance.ExtDimension3
	|		ELSE NULL
	|	END,
	|	Balance.ChartOfAccounts,
	|	Balance.Organization,
	|	Balance.Department,
	|	Balance.LineOfBusiness,
	|	Balance.Currency
	|INDEX BY SETS
	|	(
	|		(ExtDimension1, ExtDimension2, ExtDimension3),
	|		(ExtDimension2),
	|		(ExtDimension3)
	|	)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CounterpartyContracts.Ref                                             AS Contract,
	|	CounterpartyContracts.ContractRateOption                               AS ContractRateOption,
	|	CounterpartyContracts.ARAPCurrency                               AS ARAPCurrency,
	|	ISNULL(ExchangeRatesOfSettlementsUnderContractsCutOfLatest.CourseNumerator, 1)   AS CourseNumerator,
	|	ISNULL(ExchangeRatesOfSettlementsUnderContractsCutOfLatest.CourseDenominator, 1) AS CourseDenominator
	|INTO TTContracts
	|FROM
	|	Catalog.CounterpartyContracts AS CounterpartyContracts
	|		LEFT JOIN ContractTTCourses AS ExchangeRatesOfSettlementsUnderContractsCutOfLatest
	|		ON CounterpartyContracts.Ref = ExchangeRatesOfSettlementsUnderContractsCutOfLatest.Contract
	|WHERE
	|	CounterpartyContracts.Ref IN
	|			(SELECT
	|				TTAccountBalances.ExtDimension1
	|			FROM
	|				TTAccountBalances
	|		
	|			UNION ALL
	|		
	|			SELECT
	|				TTAccountBalances.ExtDimension2
	|			FROM
	|				TTAccountBalances
	|		
	|			UNION ALL
	|		
	|			SELECT
	|				TTAccountBalances.ExtDimension3
	|			FROM
	|				TTAccountBalances)
	|
	|UNION ALL
	|
	|SELECT
	|	IntercompanyContracts.Ref                                       AS Contract,
	|	IntercompanyContracts.ContractRateOption                         AS ContractRateOption,
	|	IntercompanyContracts.ARAPCurrency                         AS ARAPCurrency,
	|	ISNULL(ExchangeRatesOfSettlementsUnderContractsCutOfLatest.CourseNumerator, 1)   AS CourseNumerator,
	|	ISNULL(ExchangeRatesOfSettlementsUnderContractsCutOfLatest.CourseDenominator, 1) AS CourseDenominator
	|FROM
	|	Catalog.IntercompanyContracts AS IntercompanyContracts
	|		LEFT JOIN ContractTTCourses AS ExchangeRatesOfSettlementsUnderContractsCutOfLatest
	|		ON IntercompanyContracts.Ref = ExchangeRatesOfSettlementsUnderContractsCutOfLatest.Contract
	|WHERE
	|	IntercompanyContracts.Ref IN
	|			(SELECT
	|				TTAccountBalances.ExtDimension1
	|			FROM
	|				TTAccountBalances
	|		
	|			UNION ALL
	|		
	|			SELECT
	|				TTAccountBalances.ExtDimension2
	|			FROM
	|				TTAccountBalances
	|		
	|			UNION ALL
	|		
	|			SELECT
	|				TTAccountBalances.ExtDimension3
	|			FROM
	|				TTAccountBalances)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccountBalances.OptionForGeneratingTransactions                         AS OptionForGeneratingTransactions,
	|	AccountBalances.Account                                                AS Account,
	|	AccountBalances.ChartOfAccounts                                          AS ChartOfAccounts,
	|	AccountBalances.Organization                                         AS Organization,
	|	AccountBalances.Department                                       AS Department,
	|	AccountBalances.LineOfBusiness                             AS LineOfBusiness,
	|	AccountBalances.ExtDimension1                                           AS ExtDimension1,
	|	AccountBalances.ExtDimension2                                           AS ExtDimension2,
	|	AccountBalances.ExtDimension3                                           AS ExtDimension3,
	|	AccountBalances.Currency                                              AS Currency,
	|	AccountBalances.CurrencyAmountBalance                                AS CurrencyAmountBalance,
	|	AccountBalances.SumBalance                                        AS SumBalance,
	|	AccountBalances.PresentationAmountBalance                           AS PresentationAmountBalance,
	|	ISNULL(
	|		ISNULL(
	|			TTContracts1.ContractRateOption,
	|			TTContracts2.ContractRateOption),
	|		ISNULL(
	|			TTContracts3.ContractRateOption,
	|			VALUE(Enum.ContractRateOptions.Mutable))) AS ContractRateOption,
	|	ISNULL(
	|		ISNULL(
	|			TTContracts1.CourseNumerator,
	|			TTContracts2.CourseNumerator),
	|		ISNULL(
	|			TTContracts3.CourseNumerator,
	|			1))                                                       AS CourseNumerator,
	|	ISNULL(
	|		ISNULL(
	|			TTContracts1.CourseDenominator,
	|			TTContracts2.CourseDenominator),
	|		ISNULL(
	|			TTContracts3.CourseDenominator,
	|			1))                                                       AS CourseDenominator,
	|	ISNULL(
	|		ISNULL(
	|			TTContracts1.ARAPCurrency,
	|			TTContracts2.ARAPCurrency),
	|		ISNULL(
	|			TTContracts3.ARAPCurrency,
	|			UNDEFINED))                                            AS ARAPCurrency
	|INTO AccountBalancesWithContractExchangeRateTT
	|FROM
	|	TTAccountBalances AS AccountBalances
	|		LEFT JOIN TTContracts AS TTContracts1
	|		ON AccountBalances.ExtDimension1 = TTContracts1.Contract
	|		LEFT JOIN TTContracts AS TTContracts2
	|		ON AccountBalances.ExtDimension2 = TTContracts2.Contract
	|		LEFT JOIN TTContracts AS TTContracts3
	|		ON AccountBalances.ExtDimension3 = TTContracts3.Contract
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTBalancesWithRateOfContract.OptionForGeneratingTransactions AS OptionForGeneratingTransactions,
	|	TTBalancesWithRateOfContract.Account                        AS Account,
	|	TTBalancesWithRateOfContract.ChartOfAccounts                  AS ChartOfAccounts,
	|	TTBalancesWithRateOfContract.Organization                 AS Organization,
	|	TTBalancesWithRateOfContract.Department               AS Department,
	|	TTBalancesWithRateOfContract.LineOfBusiness     AS LineOfBusiness,
	|	TTBalancesWithRateOfContract.ExtDimension1                   AS ExtDimension1,
	|	TTBalancesWithRateOfContract.ExtDimension2                   AS ExtDimension2,
	|	TTBalancesWithRateOfContract.ExtDimension3                   AS ExtDimension3,
	|	TTBalancesWithRateOfContract.Currency                      AS Currency,
	|	TTBalancesWithRateOfContract.CurrencyAmountBalance        AS CurrencyAmountBalance,
	|	TTBalancesWithRateOfContract.SumBalance                AS SumBalance,
	|	TTBalancesWithRateOfContract.PresentationAmountBalance   AS PresentationAmountBalance,
	|	TTBalancesWithRateOfContract.ContractRateOption        AS ContractRateOption,
	|	CASE
	|		WHEN TTBalancesWithRateOfContract.ContractRateOption = VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|				AND &PresentationCurrency = TTBalancesWithRateOfContract.ARAPCurrency
	|			THEN TTBalancesWithRateOfContract.CourseNumerator
	|		ELSE &CourseNumeratorVP
	|	END                                                AS ExchangeRateNumeratorOfPresentationCurrency,
	|	CASE
	|		WHEN TTBalancesWithRateOfContract.ContractRateOption = VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|				AND &PresentationCurrency = TTBalancesWithRateOfContract.ARAPCurrency
	|			THEN TTBalancesWithRateOfContract.CourseDenominator
	|		ELSE &CourseDenominatorVP
	|	END                                                AS ExchangeRateDenominatorOfPresentationCurrency,
	|	CASE
	|		WHEN TTBalancesWithRateOfContract.ContractRateOption = VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|				AND &FunctionalCurrency = TTBalancesWithRateOfContract.ARAPCurrency
	|			THEN TTBalancesWithRateOfContract.CourseNumerator
	|		ELSE &CourseNumeratorFV
	|	END                                            AS RateIsNumeratorOfFunctionalCurrency,
	|	CASE
	|		WHEN TTBalancesWithRateOfContract.ContractRateOption = VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|				AND &FunctionalCurrency = TTBalancesWithRateOfContract.ARAPCurrency
	|			THEN TTBalancesWithRateOfContract.CourseDenominator
	|		ELSE &CourseDenominatorFV
	|	END                                            AS ExchangeRateDenominator_FunctionalCurrency
	|INTO TTAccountBalancesWithExchangeRates
	|FROM
	|	AccountBalancesWithContractExchangeRateTT AS TTBalancesWithRateOfContract
	|WHERE
	|	TTBalancesWithRateOfContract.ContractRateOption <> VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1000
	|	&Date AS Period,
	|	AccountBalances.OptionForGeneratingTransactions,
	|	AccountBalances.Account,
	|	AccountBalances.Account.Type AS AccountType,
	|	AccountBalances.Account.Currency1 AS Currency1,
	|	AccountBalances.Account.OffBalance AS OffBalance,
	|	AccountBalances.ChartOfAccounts,
	|	AccountBalances.Organization,
	|	CASE WHEN AccountBalances.Account.AccountingByBusinessUnits
	|		THEN AccountBalances.Department
	|		ELSE UNDEFINED
	|	END AS Department,
	|	CASE WHEN AccountBalances.Account.AccountingByLinesOfBusiness
	|		THEN AccountBalances.LineOfBusiness
	|		ELSE UNDEFINED
	|	END AS LineOfBusiness,
	|	AccountBalances.Account.ExtDimensionTypes.(
	|		LineNumber AS LineNumber,
	|		ExtDimensionType AS ExtDimensionType,
	|		TurnoversOnly AS TurnoversOnly
	|	) AS AccountExtDimensionTypes,
	|	AccountBalances.ExtDimension1,
	|	AccountBalances.ExtDimension2,
	|	AccountBalances.ExtDimension3,
	|	AccountBalances.Currency,
	|	AccountBalances.SumBalance,
	|	CAST(AccountBalances.SumBalance * AccountBalances.RateIsNumeratorOfFunctionalCurrency / AccountBalances.ExchangeRateDenominator_FunctionalCurrency / AccountBalances.ExchangeRateNumeratorOfPresentationCurrency * AccountBalances.ExchangeRateDenominatorOfPresentationCurrency AS NUMBER(31,2)) AS EAPAmount,
	|	AccountBalances.PresentationAmountBalance AS EAPAmountBalance,
	|	(CAST(AccountBalances.SumBalance * AccountBalances.RateIsNumeratorOfFunctionalCurrency / AccountBalances.ExchangeRateDenominator_FunctionalCurrency / AccountBalances.ExchangeRateNumeratorOfPresentationCurrency * AccountBalances.ExchangeRateDenominatorOfPresentationCurrency AS NUMBER(31,2))) - AccountBalances.PresentationAmountBalance AS ExchangeDifference,
	|	AccountBalances.Account.Order AS AccountOrder,
	|	TTAccountAccounting.Income,
	|	ISNULL(TTAccountAccounting.IncomeForeignExchange,FALSE) AS IncomeForeignExchange,
	|	ISNULL(TTAccountAccounting.Income.AccountingByBusinessUnits, FALSE) AS RevenueByDivision,
	|	ISNULL(TTAccountAccounting.Income.AccountingByLinesOfBusiness, FALSE) AS RevenuesByDirection,
	|	TTAccountAccounting.IncomeItem,
	|	TTAccountAccounting.ExtDimensionTypeIncomeItems,
	|	TTAccountAccounting.Expenses,
	|	ISNULL(TTAccountAccounting.ExpensesForeignExchange,FALSE) AS ExpensesForeignExchange,
	|	ISNULL(TTAccountAccounting.Expenses.AccountingByBusinessUnits, FALSE) AS ExpensesByDivision,
	|	ISNULL(TTAccountAccounting.Expenses.AccountingByLinesOfBusiness, FALSE) AS ExpensesByDestinations,
	|	TTAccountAccounting.ExpenseItem,
	|	TTAccountAccounting.ExtDimensionTypeExpenseItems
	|FROM
	|	TTAccountBalancesWithExchangeRates AS AccountBalances
	|		LEFT JOIN TTAccountAccounting AS TTAccountAccounting
	|		ON AccountBalances.ChartOfAccounts = TTAccountAccounting.ChartOfAccounts
	|			AND AccountBalances.Organization = TTAccountAccounting.Organization
	|WHERE
	|	ISNULL(AccountBalances.Currency, VALUE(Catalog.Currencies.EmptyRef)) <> &PresentationCurrency
	|	AND (CAST(AccountBalances.SumBalance * AccountBalances.RateIsNumeratorOfFunctionalCurrency / AccountBalances.ExchangeRateDenominator_FunctionalCurrency / AccountBalances.ExchangeRateNumeratorOfPresentationCurrency * AccountBalances.ExchangeRateDenominatorOfPresentationCurrency AS NUMBER(31,2))) - AccountBalances.PresentationAmountBalance <> 0
	|
	|ORDER BY
	|	AccountOrder";
	
	Return QueryText;
	
EndFunction

Procedure CreateTasksForEndOfMonthWhenEventIsCanceled()
	
	If OperationType = Enums.PeriodEndTransactionsTypesFinancialAccounting.ReclassificationOfLongTermAssetsAndLiabilities
		And Documents.PeriodEndTransactionFinancialAccounting.ThereAreReclassifiableNonCurrentAssetsLiabilities(Organization, Date) Then
		
		InformationRegisters.JobsForMonthEndClosing.CreateRegisterEntry(
			BegOfMonth(Date),
			Ref,
			Organization,
			Catalogs.MonthEndClosingOperations.ReclassificationOfLongTermAssetsAndLiabilitiesInt);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
