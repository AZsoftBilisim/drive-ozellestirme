#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	If TypeOf(FillingData) = Type("DocumentRef." + Metadata().Name) Then
		DocumentCorrection.FillInCorrection(ThisObject, FillingData);
	EndIf;
	
	// A selection of articles and analyst
	ItemsAndDimensionsSelectionParameters = Documents.PostingPayrollExpensesInFinancialAccounting2_5.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	// End Article Selection and Analytics
	//++ WE
	If GetFunctionalOption("PayrollAndHumanResourcesWE") Then
		Raise NStr("ru = 'Нельзя вводить документ ""Отражение зарплаты в финансовом учете"" вручную. Документ вводится автоматически.';
					|vi = 'Cannot create the ""Post payroll expenses to accounting"" document manually. The document is created automatically.';
					|en = 'Cannot create the ""Post payroll expenses to accounting"" document manually. The document is created automatically.'; fa = 'Cannot create the ""Post payroll expenses to accounting"" document manually. The document is created automatically.';
					|it = 'Cannot create the ""Post payroll expenses to accounting"" document manually. The document is created automatically.';
					|pl = 'Cannot create the ""Post payroll expenses to accounting"" document manually. The document is created automatically.';
					|tr = '""Maaşların finansal muhasebeye yansıtılması"" belgesi manuel olarak girilemez. Belge otomatik olarak oluşturulur.'");
	EndIf;
	//-- WE
	
	InitializeDocument(FillingData);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	AttributesNotToCheck = New Array;
	
	If Not AccrualsAndTaxesDetailedByPersons Then
		AttributesNotToCheck.Add("Accruals.Individual");
		AttributesNotToCheck.Add("PayrollTaxes.Individual");
		AttributesNotToCheck.Add("DutiesOfTaxAgent.Individual");
	EndIf;
	
	// Checking reflection settings
	CheckReflectionSettings(AttributesNotToCheck, Cancel);
	
	CheckAvailabilityOfDistributionBase(Cancel);
	
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);
	
	// Checking the reflection settings for other expenses/income/liabilities is performed by a universal mechanism
	
	// A selection of articles and analyst
	ItemsAndDimensionsSelectionParameters = Documents.PostingPayrollExpensesInFinancialAccounting2_5.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	// End Selection of articles and analysts
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	
	TSRow = "Accruals,PayrollTaxes,DutiesOfTaxAgent,Deductions";
	TMCommonUse.ClearDocumentIDs(ThisObject, TSRow);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	FillInTabularPartsAccordingToDocumentDetails();
	
	TSRow = "Accruals,PayrollTaxes,DutiesOfTaxAgent,Deductions";
	TMCommonUse.FillInDocumentIDs(ThisObject, TSRow);
	
	// A selection of articles and analyst
	ItemsAndDimensionsSelectionParameters = Documents.PostingPayrollExpensesInFinancialAccounting2_5.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	// End Selection of articles and analysts
	
	//Setting up accounting accounts
	GLAccountSettingsServer.BeforeWrite(ThisObject,
		Documents.PostingPayrollExpensesInFinancialAccounting2_5.AccountingAccountSettings_());
	//++ WE
	If WriteMode = DocumentWriteMode.UndoPosting
		And DocumentsPayrollAndHumanResourcesServer.DocumentIsUsedInCalculatingPOData(Ref) Then
		
		DocumentsPayrollAndHumanResourcesServer.ReportErrorsCancellationOfEvent(Ref, Cancel);	
	EndIf;	
	//-- WE
		
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

Procedure InitializeDocument(FillingData = Undefined)
	
	Date          = CurrentSessionDate();
	Organization   = SettingsValueCached.GetDefaultOrganization(Organization);
	If Not ValueIsFilled(Currency) Then
		Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	EndIf;
	EmployeeResponsible = Users.CurrentUser();
	
	If Not ValueIsFilled(CalculationsPeriod) Then
		CalculationsPeriod = BegOfMonth(Date);
	EndIf;
	
EndProcedure

Procedure FillInTabularPartsAccordingToDocumentDetails()
	
	TypeOfCalculationsIsSpecifiedInHeader    = ValueIsFilled(ARAPType);
	DivisionIsIndicatedInHeader = ValueIsFilled(Department);
	
	For Each TableRow In Accruals Do
		If TypeOfCalculationsIsSpecifiedInHeader And Not TableRow.ARAPType = ARAPType Then
			TableRow.ARAPType = ARAPType;
		EndIf;
		If DivisionIsIndicatedInHeader And Not TableRow.Department = Department Then
			TableRow.Department = Department;
		EndIf;
		If Not AccrualsAndTaxesDetailedByPersons And ValueIsFilled(TableRow.Individual) Then
			TableRow.Individual = Undefined;
		EndIf;
	EndDo;
	
	For Each TableRow In PayrollTaxes Do
		If DivisionIsIndicatedInHeader And Not TableRow.Department = Department Then
			TableRow.Department = Department;
		EndIf;
		If Not AccrualsAndTaxesDetailedByPersons And ValueIsFilled(TableRow.Individual) Then
			TableRow.Individual = Undefined;
		EndIf;
	EndDo;
	
	For Each TableRow In DutiesOfTaxAgent Do
		If TypeOfCalculationsIsSpecifiedInHeader And Not TableRow.ARAPType = ARAPType Then
			TableRow.ARAPType = ARAPType;
		EndIf;
		If DivisionIsIndicatedInHeader And Not TableRow.Department = Department Then
			TableRow.Department = Department;
		EndIf;
		If Not AccrualsAndTaxesDetailedByPersons And ValueIsFilled(TableRow.Individual) Then
			TableRow.Individual = Undefined;
		EndIf;
	EndDo;
	
	For Each TableRow In Deductions Do
		If TypeOfCalculationsIsSpecifiedInHeader And Not TableRow.ARAPType = ARAPType Then
			TableRow.ARAPType = ARAPType;
		EndIf;
		If DivisionIsIndicatedInHeader And Not TableRow.Department = Department Then
			TableRow.Department = Department;
		EndIf;
	EndDo;
	
EndProcedure

Procedure CheckReflectionSettings(AttributesNotToCheck, Cancel)
	
	OptionsForReflectingAccruals = Documents.PostingPayrollExpensesInFinancialAccounting2_5.OptionsForReflectingAccruals();
	
	// Accruals
	For Each TableRow In Accruals Do
		
		ReflectionOptionParameters = OptionsForReflectingAccruals[TableRow.PostingOption];
		If ReflectionOptionParameters = Undefined Or Not ReflectionOptionParameters.CheckFilling Then
			Continue;
		EndIf;
		
		If Not CheckCorrectReflectionSettings(ReflectionOptionParameters.AttributeProperties, TableRow) Then
			DataPath = CommonClientServer.PathToTabularSection(
					"Accruals", TableRow.LineNumber, "RecordingSettingPresentation");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Đã điền sai các cài đặt định khoản (dòng %1 của bảng ""Tính toán"")';
						|ru = 'Настройки отражения заполнены некорректно (строка %1 таблицы ""Начисления"")';
						|en = 'Record settings are not filled in correctly (line %1 of the table ""Accruals"")'; fa = 'Record settings are not filled in correctly (line %1 of the table ""Accruals"")';
						|it = 'Impostazioni di visualizzazione sono compilate in modo scorretto (la riga %1 della tabella ""Maturazioni"")';
						|pl = 'Ustawienia odzwierciedlenia są wypełnione niepoprawnie (wiers %1 tabeli ""Naliczenia"")';
						|tr = 'Yansıtma ayarları yanlış dolduruldu (""Tahakkuklar"" tablosu %1 satırı)'"),
					TableRow.LineNumber);
			Common.MessageToUser(MessageText, ThisObject, DataPath, , Cancel);
		EndIf;
		
	EndDo;
	
	// Taxes, contributions (from the organization)
	For Each TableRow In PayrollTaxes Do
		
		ReflectionOptionParameters = OptionsForReflectingAccruals[TableRow.PostingOption];
		If ReflectionOptionParameters = Undefined Or Not ReflectionOptionParameters.CheckFilling Then
			Continue;
		EndIf;
		
		If Not CheckCorrectReflectionSettings(ReflectionOptionParameters.AttributeProperties, TableRow) Then
			DataPath = CommonClientServer.PathToTabularSection(
					"PayrollTaxes", TableRow.LineNumber, "RecordingSettingPresentation");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Đã điền sai các cài đặt định khoản (dòng %1 của bảng ""Các khoản trích theo lương (từ doanh nghiệp)"")';
						|ru = 'Настройки отражения заполнены некорректно (строка %1 таблицы ""Налоги, взносы (с организации)"")';
						|en = 'Record settings are not filled in correctly (line %1 of the table ""Payroll taxes"")'; fa = 'Record settings are not filled in correctly (line %1 of the table ""Payroll taxes"")';
						|it = 'Impostazioni di visualizzazione sono compilate in modo scorretto (la riga %1 della tabella ""Tasse, imposte (dovute dall''azienda)"")';
						|pl = 'Ustawienie odzwierciedlenia są wypełnione niepoprawnie (wiersz %1tabeli ""Podatki, składki (z firmy)"")';
						|tr = 'Kaydetme ayarları yanlış dolduruldu (""Vergiler, katkılar (iş yerinden)"" tablosunun %1 satırı)'"),
					TableRow.LineNumber);
			Common.MessageToUser(MessageText, ThisObject, DataPath, , Cancel);
		EndIf;
		
	EndDo;
	
	For Each PostingOption In OptionsForReflectingAccruals Do
		ReflectionOptionParameters = PostingOption.Value;
		If Not ReflectionOptionParameters.CheckFilling Then
			Continue;
		EndIf;
		For Each Attribute In ReflectionOptionParameters.AttributeProperties Do
			AttributesNotToCheck.Add("Accruals." + Attribute.Key);
			AttributesNotToCheck.Add("PayrollTaxes." + Attribute.Key);
		EndDo;
	EndDo;
	
	// Deductions
	OptionsForReflectingDeductions = Documents.PostingPayrollExpensesInFinancialAccounting2_5.OptionsForReflectingDeductions();
	
	For Each TableRow In Deductions Do
		
		ReflectionOptionParameters = OptionsForReflectingDeductions[TableRow.PostingOption];
		If ReflectionOptionParameters = Undefined Or Not ReflectionOptionParameters.CheckFilling Then
			Continue;
		EndIf;
		
		If Not CheckCorrectReflectionSettings(ReflectionOptionParameters.AttributeProperties, TableRow) Then
			DataPath = CommonClientServer.PathToTabularSection(
					"Deductions", TableRow.LineNumber, "RecordingSettingPresentation");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Đã điền sai các cài đặt định khoản (dòng %1 của bảng ""Giữ lại"")';
						|ru = 'Настройки отражения заполнены некорректно (строка %1 таблицы ""Удержания"")';
						|en = 'Record settings are not filled in correctly (line %1 of the table ""Deductions"")'; fa = 'Record settings are not filled in correctly (line %1 of the table ""Deductions"")';
						|it = 'Impostazioni di visualizzazione sono compilate in modo scorretto (la riga %1 della tabella ""Trattenute"")';
						|pl = 'Ustawienia odzwierciedlenia są wypełnione niepoprawnie (wiers %1 tabeli ""Potrącenia"")';
						|tr = 'Kaydetme ayarları yanlış dolduruldu (""Stopajlar"" tablosunun %1 satırı)'"),
					TableRow.LineNumber);
			Common.MessageToUser(MessageText, ThisObject, DataPath, , Cancel);
		EndIf;
		
	EndDo;
	
	For Each PostingOption In OptionsForReflectingDeductions Do
		ReflectionOptionParameters = PostingOption.Value;
		If Not ReflectionOptionParameters.CheckFilling Then
			Continue;
		EndIf;
		For Each Attribute In ReflectionOptionParameters.AttributeProperties Do
			AttributesNotToCheck.Add("Deductions." + Attribute.Key);
		EndDo;
	EndDo;
	
EndProcedure

Function CheckCorrectReflectionSettings(Attributes, TableRow)
	
	Result = True;
	
	For Each ListItem In Attributes Do
		
		Name = ListItem.Key;
		Attribute = ListItem.Value;
		
		If Not Attribute.Used Or Not Attribute.AttributeIsRequired Then
			Continue;
		ElsIf ValueIsFilled(TableRow[Name]) Then
			Continue;
		EndIf;
		
		Result = False;
		Break;
		
	EndDo;
	
	Return Result;
	
EndFunction

Procedure CheckAvailabilityOfDistributionBase(Cancel)
	
	DataSources = New Structure;
	
	Columns = "LineNumber, Department, Individual, AllocationBaseType";
	
	Filter = New Structure("PostingOption",
		Enums.AccrualsDeductionsRecordOptions.AllocateToProduction);
	
	DataSources.Insert("Accruals",
		New Structure("Table, DataPath, Presentation",
			Accruals.Unload(Filter, Columns),
			"Accruals[%1].RecordingSettingPresentation",
			NStr("vi = 'Trích theo lương';
				|ru = 'Начисления';
				|en = 'Accruals'; fa = 'اقلام تعهدی';
				|it = 'Accrediti maturati';
				|pl = 'Accruals';
				|tr = 'Tahakkuklar'")));
	
	DataSources.Insert("PayrollTaxes",
		New Structure("Table, DataPath, Presentation",
			PayrollTaxes.Unload(Filter, Columns),
			"PayrollTaxes[%1].RecordingSettingPresentation",
			NStr("vi = 'Các khoản trích theo lương (từ doanh nghiệp)';
				|ru = 'Налоги, взносы (с организации)';
				|en = 'Payroll taxes'; fa = 'مالیات‌های حقوق و دستمزد';
				|it = 'Imposte, tasse (dovute dall''azienda)';
				|pl = 'Podatki, składki (z firmy)';
				|tr = 'Vergiler, primler (iş yerleri ile)'")));
	
	Query = New Query;
	
	Query.SetParameter("Organization",   Organization);
	Query.SetParameter("BeginOfPeriod", BegOfMonth(CalculationsPeriod));
	Query.SetParameter("EndOfPeriod",  EndOfMonth(CalculationsPeriod));
	
	For Each DataSource In DataSources Do
		Query.SetParameter(DataSource.Key, DataSource.Value.Table);
	EndDo;
	
	Query.Text = 
	"SELECT
	|	0 AS Order,
	|	""Accruals"" AS Source,
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.Department AS Department,
	|	DocumentTable.Individual AS Individual,
	|	DocumentTable.AllocationBaseType AS AllocationBaseType
	|INTO TTAccruals
	|FROM
	|	&Accruals AS DocumentTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	1 AS Order,
	|	""PayrollTaxes"" AS Source,
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.Department AS Department,
	|	DocumentTable.Individual AS Individual,
	|	DocumentTable.AllocationBaseType AS AllocationBaseType
	|INTO TTTaxesOrganizationFees
	|FROM
	|	&PayrollTaxes AS DocumentTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Order,
	|	Source,
	|	LineNumber,
	|	Department,
	|	Individual,
	|	AllocationBaseType
	|INTO TTDocumentData_
	|FROM
	|	TTAccruals AS Table
	|
	|UNION ALL
	|
	|SELECT
	|	Order,
	|	Source,
	|	LineNumber,
	|	Department,
	|	Individual,
	|	AllocationBaseType
	|FROM
	|	TTTaxesOrganizationFees AS Table
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// We will get the periods of distribution bases by production Lot references,
	// for which there was a reversal of the s/n reflection in the current period.
	|SELECT
	|	CancelledLaborCostsOfUnfinishedProduction.Organization         AS Organization,
	|	CancelledLaborCostsOfUnfinishedProduction.ProductionLot  AS ProductionLot,
	|	BEGINOFPERIOD(BatchOutput.Period, MONTH) AS StartDate,
	|	ENDOFPERIOD(BatchOutput.Period, MONTH)  AS EndDate
	|INTO PeriodsOfBatchDistributionBaseWithReversal
	|FROM
	|	InformationRegister.DocumentsRegistry AS ReversingDocuments
	|	
	|	INNER JOIN Document.PostingPayrollExpensesInFinancialAccounting2_5 AS ReversedDocuments
	|	ON ReversedDocuments.Ref = ReversingDocuments.ReversedDocument
	|	
	|	INNER JOIN AccumulationRegister.WIPLaborCosts AS CancelledLaborCostsOfUnfinishedProduction
	|	ON CancelledLaborCostsOfUnfinishedProduction.Recorder = ReversedDocuments.Ref
	|	
	|	INNER JOIN AccumulationRegister.WIPLaborCosts AS BatchOutput
	|	ON BatchOutput.Organization = CancelledLaborCostsOfUnfinishedProduction.Organization
	|	AND BatchOutput.ProductionLot = CancelledLaborCostsOfUnfinishedProduction.ProductionLot
	|	AND BatchOutput.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND NOT BatchOutput.StandardCost = 0
	|	AND BatchOutput.Period < &BeginOfPeriod
	|
	|WHERE
	|	ReversingDocuments.Organization = &Organization
	|	AND ReversingDocuments.IBDocumentDate BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND ReversingDocuments.ReverseTransactionCorrection
	|	AND NOT ReversingDocuments.AdditionalRecord
	|	AND ReversingDocuments.Posted
	|
	|GROUP BY
	|	CancelledLaborCostsOfUnfinishedProduction.Organization,
	|	CancelledLaborCostsOfUnfinishedProduction.ProductionLot,
	|	BEGINOFPERIOD(BatchOutput.Period, MONTH),
	|	ENDOFPERIOD(BatchOutput.Period, MONTH)
	|
	|INDEX BY
	|	Organization,
	|	ProductionLot
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LaborCostsOfUnfinishedProduction.Department               AS Department,
	|	LaborCostsOfUnfinishedProduction.Individual              AS Individual,
	|	SUM(LaborCostsOfUnfinishedProduction.StandardCost) AS StandardCost,
	|	SUM(LaborCostsOfUnfinishedProduction.Duration)         AS Duration
	|INTO TTDistributionBase
	|FROM
	|	(SELECT
	|		LaborCostsOfUnfinishedProduction.Department AS Department,
	|		LaborCostsOfUnfinishedProduction.Employee AS Individual,
	|		LaborCostsOfUnfinishedProduction.StandardCost AS StandardCost,
	|		CASE
	|			WHEN NOT ActivityKinds.LaborInputMultiplier = 0
	|				THEN CAST(LaborCostsOfUnfinishedProduction.Count * ActivityKinds.LaborInput / ActivityKinds.LaborInputMultiplier AS NUMBER(15,3))
	|			ELSE 0
	|		END AS Duration
	|	FROM
	|		AccumulationRegister.WIPLaborCosts AS LaborCostsOfUnfinishedProduction
	|		
	|		LEFT JOIN Catalog.EmployeeWorkKinds AS ActivityKinds
	|		ON LaborCostsOfUnfinishedProduction.WorkKind = ActivityKinds.Ref
	|	WHERE
	|		(LaborCostsOfUnfinishedProduction.Department, LaborCostsOfUnfinishedProduction.Employee) IN
	|			(SELECT
	|				Department,
	|				Individual
	|			FROM
	|				TTDocumentData_)
	|		AND LaborCostsOfUnfinishedProduction.Organization = &Organization
	|		AND LaborCostsOfUnfinishedProduction.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	
	|	UNION ALL
	|	
	// Let's add the data of past periods, suspended in the current one.
	|	SELECT
	|		LaborCostsOfUnfinishedProduction.Department AS Department,
	|		LaborCostsOfUnfinishedProduction.Employee AS Individual,
	|		LaborCostsOfUnfinishedProduction.StandardCost AS StandardCost,
	|		CASE
	|			WHEN NOT ActivityKinds.LaborInputMultiplier = 0
	|				THEN CAST(LaborCostsOfUnfinishedProduction.Count * ActivityKinds.LaborInput / ActivityKinds.LaborInputMultiplier AS NUMBER(15,3))
	|			ELSE 0
	|		END AS Duration
	|	FROM
	|		PeriodsOfBatchDistributionBaseWithReversal AS DistributionBasePeriods
	|		
	|		INNER JOIN AccumulationRegister.WIPLaborCosts AS LaborCostsOfUnfinishedProduction
	|		ON LaborCostsOfUnfinishedProduction.Organization = DistributionBasePeriods.Organization
	|		AND LaborCostsOfUnfinishedProduction.ProductionLot = DistributionBasePeriods.ProductionLot
	|		AND LaborCostsOfUnfinishedProduction.Period BETWEEN DistributionBasePeriods.StartDate AND DistributionBasePeriods.EndDate
	|		
	|		LEFT JOIN Catalog.EmployeeWorkKinds AS ActivityKinds
	|		ON LaborCostsOfUnfinishedProduction.WorkKind = ActivityKinds.Ref
	|		
	|	WHERE
	|		(LaborCostsOfUnfinishedProduction.Department, LaborCostsOfUnfinishedProduction.Employee) IN
	|			(SELECT
	|				Department,
	|				Individual
	|			FROM
	|				TTDocumentData_)
	|	) AS LaborCostsOfUnfinishedProduction
	|
	|GROUP BY
	|	LaborCostsOfUnfinishedProduction.Department,
	|	LaborCostsOfUnfinishedProduction.Individual
	|
	|INDEX BY
	|	Department,
	|	Individual
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	DocumentData.Order,
	|	DocumentData.Source,
	|	DocumentData.LineNumber,
	|	DocumentData.Department,
	|	DocumentData.Individual,
	|	CASE
	|		WHEN AllocationBase.Department IS NULL
	|			THEN UNDEFINED
	|		ELSE 0
	|	END AS ZoomRatio
	|FROM
	|	TTDocumentData_ AS DocumentData
	|	LEFT JOIN TTDistributionBase AS AllocationBase
	|	ON DocumentData.Department = AllocationBase.Department
	|		AND DocumentData.Individual = AllocationBase.Individual
	|
	|WHERE
	|	DocumentData.Department <> VALUE(Catalog.BusinessStructure.EmptyRef)
	|	AND (DocumentData.AllocationBaseType = VALUE(Enum.TypesOfCostAllocatingBase.StandardRemunerationLevel)
	|			AND ISNULL(AllocationBase.StandardCost, 0) = 0
	|		OR 
	|		DocumentData.AllocationBaseType = VALUE(Enum.TypesOfCostAllocatingBase.WorkPerformanceDuration)
	|			AND ISNULL(AllocationBase.Duration, 0) = 0
	|	)
	|
	|ORDER BY
	|	DocumentData.Order,
	|	DocumentData.LineNumber
	|";
	
	If Not AccrualsAndTaxesDetailedByPersons Then
		Query.Text = StrReplace(Query.Text, "DocumentTable.Individual", "VALUE(Catalog.Persons.EmptyRef)");
		Query.Text = StrReplace(Query.Text, "LaborCostsOfUnfinishedProduction.Employee", "VALUE(Catalog.Persons.EmptyRef)");
	EndIf;
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	If AccrualsAndTaxesDetailedByPersons Then
		ThereIsNoOutputMessageTemplate = NStr("vi = 'Sản lượng của nhân viên %2 trong bộ phận ""%1"" không được ghi lại (dòng%4 của bảng ""%3"")';
												|ru = 'Выработка сотрудника %2 в подразделении ""%1"" не регистрировалась (строка %4 таблицы ""%3"")';
												|en = 'Work output for employee %2 in the business unit ""%1"" was not registered (line %4 of the table ""%3"")'; fa = 'Work output for employee %2 in the business unit ""%1"" was not registered (line %4 of the table ""%3"")';
												|it = 'La produttività del dipendente %2 del reparto ""%1"" non è stata registrata (riga %4 della tabella ""%3"")';
												|pl = 'Wydajność pracownika %2 w dziale ""%1"" nie została zarejestrowana (wiersz %4 tabeli ""%3"")';
												|tr = '""%1"" departmanındaki%2 zaman çizelgesi bazlı ücretlendirmeli (""%3"" tablosunun %4 satırı)'");
		MessageTemplateEmptyCoefficient = NStr("vi = 'Chưa xác định hệ số phân bổ công việc của nhân viên %2 trong bộ phận ""%1"" (dòng %4 của bảng ""%3"")';
												|ru = 'Не задан коэффициент распределения работ сотрудника %2 в подразделении ""%1"" (строка %4 таблицы ""%3"")';
												|en = 'The employee''s work distribution factor %2in the business unit ""%1"" is not set (line %4 of the table ""%3"")'; fa = 'The employee''s work distribution factor %2in the business unit ""%1"" is not set (line %4 of the table ""%3"")';
												|it = 'Non è stato impostato il coefficiente di ripartizione di lavori del dipendente %2 del reparto ""%1"" (riga %4 della tabella ""%3"")';
												|pl = 'Nie zadano współczynnika podziału robót pracownika %2 w dziale ""%1"" (wiersz %4 tabeli ""%3"")';
												|tr = '""%1"" departmanındaki %2 çalışanının iş dağıtım katsayısı belirtilmedi (""%3"" tablosunun %4 satırı)'");
	Else
		ThereIsNoOutputMessageTemplate = NStr("vi = 'Sản xuất trong bộ phận ""%1"" không được ghi lại (dòng %4 của bảng ""%3"")';
												|ru = 'Выработка в подразделении ""%1"" не регистрировалась (строка %4 таблицы ""%3"")';
												|en = 'Work output in the ""%1"" business unit was not registered (line %4 of the table ""%3"")'; fa = 'Work output in the ""%1"" business unit was not registered (line %4 of the table ""%3"")';
												|it = 'La produttività nel reparto ""%1"" non è stata registrata (riga %4 della tabella ""%3"")';
												|pl = 'Wydajność w dziale ""%1"" nie została zarejestrowana (wiersz %4 tabeli ""%3"")';
												|tr = '""%1"" departmanındaki çıktı kaydedilmedi (""%3"" tablosunun %4 satırı)'");
		MessageTemplateEmptyCoefficient = NStr("vi = 'Chưa xác định hệ số phân bổ công việc trong bộ phận ""%1"" (dòng %4 của bảng ""%3"")';
												|ru = 'Не задан коэффициент распределения работ в подразделении ""%1"" (строка %4 таблицы ""%3"")';
												|en = 'The work distribution factor is not set in the business unit ""%1"" (line %4 of the table ""%3"")'; fa = 'The work distribution factor is not set in the business unit ""%1"" (line %4 of the table ""%3"")';
												|it = 'Non è stato impostato il coefficiente di ripartizione di lavori nel reparto ""%1"" (riga %4 della tabella ""%3"")';
												|pl = 'Nie zadano współczynnika podziału robót w dziale ""%1"" (wiersz %4 tabeli ""%3"")';
												|tr = '""%1"" departmanındaki iş dağıtım katsayısı belirtilmedi (""%3"" tablosunun %4 satırı)'");
	EndIf;
	
	Selection = Result.Select();
	While Selection.Next() Do
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			?(Selection.ZoomRatio = Undefined, ThereIsNoOutputMessageTemplate, MessageTemplateEmptyCoefficient),
			Selection.Department, Selection.Individual, DataSources[Selection.Source].Presentation, Selection.LineNumber);
		
		DataPath = StrTemplate(DataSources[Selection.Source].DataPath, Format(Selection.LineNumber-1, "NZ=0; NG=;"));
		
		Common.MessageToUser(MessageText, ThisObject, DataPath,, Cancel);
		
	EndDo;
	
EndProcedure

#EndRegion

#EndIf