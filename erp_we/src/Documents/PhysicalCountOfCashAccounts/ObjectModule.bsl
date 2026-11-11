#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	Author = Users.CurrentUser();
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	InitializeDocument(FillingData);
	
	If TypeOf(FillingData) = Type("DocumentRef." + Metadata().Name) Then
		
		DocumentCorrection.FillInCorrection(ThisObject, FillingData);
		
	EndIf;
	
	PhysicalCountOfCashAccountsLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
	If Not ValueIsFilled(EmployeeResponsible) Then
		EmployeeResponsible = Users.CurrentUser();
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.PhysicalCountOfCashAccounts.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	
	If CashAccounts.Count() > 0 Then
		CashAccounts.Clear();
	EndIf;
	
	LastNumberOfCashAccountReceiptNote      = "";
	LastNumberOfCashAccountIssueNote      = "";
	Author = Users.CurrentUser();
	EmployeeResponsible = Users.CurrentUser();
	
	InitializeDocument();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "CashAccounts");
	
	PhysicalCountOfCashAccountsLocalization.OnCopy(ThisObject, CopiedObject);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	NotCheckedAttributeArray.Add("CashAccounts.IncomeAndExpenseItem");
	For Each TSRow In CashAccounts Do
		If TSRow.DiscrepancyAmount <> 0 And Not ValueIsFilled(TSRow.IncomeAndExpenseItem) Then
			If TSRow.DiscrepancyAmount > 0 Then
				ErrorText = NStr("vi = 'Chưa chỉ ra ""Dạng thu nhập"" tại dòng %1.';
								|ru = 'Не указана ""Статья доходов"" в строке %1.';
								|en = 'Income item is not specified in line %1.'; fa = 'Income item is not specified in line %1.';
								|it = 'Alla riga %1 non è indicata la ""Voce delle entrate"".';
								|pl = 'Nie wskazano ""Rodzaj przychodów"" w wierszu%1.';
								|tr = '%1 satırında ""Gelir kalemi"" belirtilmedi.'");
			Else
				ErrorText = NStr("vi = 'Chưa chỉ ra ""Dạng chi phí"" tại dòng %1.';
								|ru = 'Не указана ""Статья расходов"" в строке %1.';
								|en = 'Expense item is not specified in line %1.'; fa = 'Expense item is not specified in line %1.';
								|it = 'Alla riga %1 non è indicata la ""Voce delle uscite"".';
								|pl = 'Nie wskazano ""Статья расходов"" w wierszu %1.';
								|tr = '%1 satırında ""Gider kalemi"" belirtilmedi.'");
			EndIf;
			CommonClientServer.MessageToUser(
				StrTemplate(ErrorText, TSRow.LineNumber),
				ThisObject,
				"CashAccounts[" + (TSRow.LineNumber - 1) + "].IncomeAndExpenseItem",
				,
				Cancel);
		EndIf;
	EndDo;
	
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

	Common.DeleteNotCheckedAttributesFromArray(
		CheckedAttributes,
		NotCheckedAttributeArray);
		
	CheckFillingOfTablePart(Cancel);
	
	ItemsAndDimensionsSelectionParameters = Documents.PhysicalCountOfCashAccounts.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	PhysicalCountOfCashAccountsLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	
	DocumentTable = CashAccounts.Unload(,"CashAccount, AccountInAccounting, ActualDataAmount");
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	DocumentTable.CashAccount AS CashAccount,
	|	DocumentTable.AccountInAccounting,
	|	DocumentTable.ActualDataAmount
	|INTO DocumentTable
	|FROM
	|	&DocumentTable AS DocumentTable
	|;
	|/////////////////////////////////////////////////////
	|
	|SELECT
	|	CurrencyExchangeRate.Currency AS Currency,
	|	CurrencyExchangeRate.CourseNumerator * LocalCurrencyExchangeRate.CourseDenominator / (CurrencyExchangeRate.CourseDenominator * LocalCurrencyExchangeRate.CourseNumerator) AS ConversionFactor_
	|INTO TableLocalExchangeRates
	|FROM InformationRegister.RelativeExchangeRates.SliceLast(&DocumentDate, BaseCurrency = &CurrencyOfComplianceAccounting) AS CurrencyExchangeRate
	|	INNER JOIN InformationRegister.RelativeExchangeRates.SliceLast(&DocumentDate, Currency = &CurrencyOfComplianceAccounting AND BaseCurrency = &CurrencyOfComplianceAccounting) AS LocalCurrencyExchangeRate
	|	ON (TRUE)
	|WHERE
	|	CurrencyExchangeRate.CourseDenominator <> 0
	|	AND LocalCurrencyExchangeRate.CourseNumerator <> 0
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	ISNULL(SUM(DocumentTable.AccountInAccounting
	|		* TableLocalExchangeRates.ConversionFactor_), 0) AS TotalAccountInAccounting,
	|	ISNULL(SUM(DocumentTable.ActualDataAmount
	|		* TableLocalExchangeRates.ConversionFactor_), 0) AS ActualTotalAmount
	|FROM
	|	DocumentTable
	|	
	|	INNER JOIN
	|		Catalog.CashAccounts AS CashAccounts
	|	ON
	|		CashAccounts.Ref = DocumentTable.CashAccount
	|	
	|		LEFT JOIN
	|			TableLocalExchangeRates
	|		ON
	|			TableLocalExchangeRates.Currency = CashAccounts.CashCurrency
	|";
	
	Query.SetParameter("DocumentTable", DocumentTable);
	Query.SetParameter("CurrencyOfComplianceAccounting", CurrencyOfComplianceAccounting);
	Query.SetParameter("DocumentDate", Date);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	FillPropertyValues(ThisObject, Selection);
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "CashAccounts");
	
	ItemsAndDimensionsSelectionParameters = Documents.PhysicalCountOfCashAccounts.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	PhysicalCountOfCashAccountsLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	PhysicalCountOfCashAccountsLocalization.OnWrite(ThisObject, Cancel);

EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	PhysicalCountOfCashAccountsLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	PhysicalCountOfCashAccountsLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

Procedure InitializeDocument(FillingData = Undefined)
	
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	
EndProcedure

Procedure CheckFillingOfTablePart(Cancel)
	
	Query = New Query("
	|SELECT
	|	Table.LineNumber AS LineNumber,
	|	Table.CashAccount AS CashAccount,
	|	Table.DiscrepancyAmount AS DiscrepancyAmount,
	|	Table.CashFlowItem AS CashFlowItem,
	|	Table.Department AS Department,
	|	Table.IncomeAndExpenseItem AS IncomeAndExpenseItem,
	|	Table.DimensionOfRevenue AS DimensionOfRevenue,
	|	Table.DimensionOfExpenses AS DimensionOfExpenses
	|	
	|INTO DocumentTable
	|FROM
	|	&DocumentTable AS Table
	|WHERE
	|	Table.CashAccount <> UNDEFINED
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(DocumentTable.LineNumber) AS LineNumber,
	|	DocumentTable.CashAccount AS CashAccount
	|FROM
	|	DocumentTable AS DocumentTable
	|	
	|GROUP BY
	|	DocumentTable.CashAccount
	|HAVING 
	|	COUNT(*) > 1
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.CashAccount AS CashAccount,
	|	CASE WHEN CashAccounts.Owner <> &Organization THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS DifferentOrganization,
	|	CASE WHEN CashAccounts.CashBook <> &CashBook THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS DifferentCashBook
	|FROM
	|	DocumentTable AS DocumentTable
	|	
	|	INNER JOIN
	|		Catalog.CashAccounts AS CashAccounts
	|	ON
	|		CashAccounts.Ref = DocumentTable.CashAccount
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentTable.LineNumber AS LineNumber,
	|	CASE WHEN DocumentTable.CashFlowItem = VALUE(Catalog.CashFlowReportItems.EmptyRef) THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END CFItemNotFilledIn,
	|	CASE WHEN DocumentTable.Department = VALUE(Catalog.BusinessStructure.EmptyRef) THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END DivisionNotFilledIn
	|FROM
	|	DocumentTable
	|WHERE
	|	DocumentTable.DiscrepancyAmount <> 0
	|");
	
	DocumentTable = CashAccounts.Unload();
	Query.SetParameter("DocumentTable", DocumentTable);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("CashBook", CashBook);
	
	ResultsArray = Query.ExecuteBatch();
	
	DuplicateRequestResult = ResultsArray[1];
	ResultOfCashierSRequest = ResultsArray[2];
	ResultOfTSQuery = ResultsArray[3];
	
	// We check duplicates of lines in the document
	Selection = DuplicateRequestResult.Select();
	While Selection.Next() Do
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Quỹ tiền mặt %1 lặp lại trong phần bảng';
				|ru = 'Касса %1 повторяется в табличной части';
				|en = 'The %1 cash account is duplicated in the table'; fa = 'The %1 cash account is duplicated in the table';
				|it = 'La cassa %1 si ripete all''interno della parte tabulare';
				|pl = 'Kasa %1 jest powtarzana części tabelarycznej';
				|tr = '%1 kasa tablo bölümünde tekrarlanıyor'"),
			Selection.CashAccount);
		CommonClientServer.MessageToUser(
			Text,
			ThisObject,
			"CashAccounts[" + (Selection.LineNumber - 1) + "].CashAccount",
			,
			Cancel);
	EndDo;
	
	UseBusinessUnits = GetFunctionalOption("UseBusinessUnits");
	
	Selection = ResultOfCashierSRequest.Select();
	While Selection.Next() Do
		
		// We check the compliance of the organization of the document and the organization of the cash register
		If Selection.DifferentOrganization Then
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Doanh nghiệp trong chứng từ %1 khác với doanh nghiệp %2';
					|ru = 'Организация документа %1 отличается от организации %2';
					|en = 'Company mentioned in the document %1 differs from company %2'; fa = 'Company mentioned in the document %1 differs from company %2';
					|it = 'L''azienda del documento %1 differisce dall''azienda %2';
					|pl = 'Firma dokumentu %1 różni się firmy %2';
					|tr = '%1 belgesinin iş yeri, %2 iş yerinden farklı'"),
				Selection.Document,
				Organization);
			CommonClientServer.MessageToUser(
				Text,
				ThisObject,
				"CashAccounts[" + (Selection.LineNumber - 1) + "].CashAccount",
				,
				Cancel);
		EndIf;
		
		// We check the correspondence of the cash register of the document and the cash register of the cash register
		If Selection.DifferentCashBook Then
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Sổ quỹ tiền mặt của chứng từ %1 khác với sổ quỹ tiền mặt %2';
					|ru = 'Кассовая книга документа %1 отличается от кассовой книги %2';
					|en = 'Cash book of document %1 differs from cash book %2'; fa = 'Cash book of document %1 differs from cash book %2';
					|it = 'Il libro di cassa del documento %1 è diversa dal libro di cassa %2';
					|pl = 'Księga kasowa dokumentu %1 różni się księgi kasowej %2';
					|tr = '%1 belgesinin kasa defteri %2 kasa defterinden farklı'"),
				Selection.Document,
				?(ValueIsFilled(CashBook), CashBook, NStr("vi = '<Sổ quỹ tiền mặt chính của doanh nghiệp>';
															|ru = '<Основная кассовая книга организации>';
															|en = '<Main company cash book>'; fa = '<Main company cash book>';
															|it = '<Libro cassa principale della società>';
															|pl = '<Główna księga kasowa firmy>';
															|tr = '<İş yerinin ana kasası>'")));
			CommonClientServer.MessageToUser(
				Text,
				ThisObject,
				"CashAccounts[" + (Selection.LineNumber - 1) + "].CashAccount",
				,
				Cancel);
		EndIf;
	EndDo;
	
	// Verification of filling in the details of the table. parts
	Selection = ResultOfTSQuery.Select();
	While Selection.Next() Do
		
		If Selection.CFItemNotFilledIn Then
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chưa chỉ ra ""Dạng lưu chuyển tiền tệ"" tại dòng %1';
					|ru = 'Не указана ""Статья движения денежных средств"" в строке %1';
					|en = '""Cash flow item"" is not specified in line %1'; fa = '""Cash flow item"" is not specified in line %1';
					|it = 'La ""Voce del flusso di cassa"" alla riga %1 non è indicata';
					|pl = 'Nie wskazano ""Kierunek ruchu środków pieniężnych"" w wierszu %1';
					|tr = '""Nakit akışı öğesi"" %1 satırında belirtilmedi'"), Selection.LineNumber);
			CommonClientServer.MessageToUser(
				Text,
				ThisObject,
				"CashAccounts[" + (Selection.LineNumber - 1) + "].CashFlowItem",
				,
				Cancel);
		EndIf;
		
		If Selection.DivisionNotFilledIn And UseBusinessUnits Then
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chưa chỉ ra ""Bộ phận"" tại dòng %1';
					|ru = 'Не указано ""Подразделение"" в строке %1';
					|en = '""Business unit"" is not specified in line %1'; fa = '""Business unit"" is not specified in line %1';
					|it = 'Alla riga %1 non è indicato il ""Reparto""';
					|pl = 'Nie wskazano ""Dział"" w wierszu %1';
					|tr = '%1 satırında ""Departman"" belirtilmedi'"), Selection.LineNumber);
			CommonClientServer.MessageToUser(
				Text,
				ThisObject,
				"CashAccounts[" + (Selection.LineNumber - 1) + "].Department",
				,
				Cancel);
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#EndIf
