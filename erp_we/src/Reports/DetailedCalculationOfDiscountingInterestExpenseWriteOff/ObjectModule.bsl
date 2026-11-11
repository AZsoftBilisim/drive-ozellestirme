#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	ReportSettings = SettingsComposer.GetSettings();
	
	PeriodParameter = ReportSettings.DataParameters.Items.Find("ReportPeriod");
	DocumentParameter = ReportSettings.DataParameters.Items.Find("Document");
	ContractParameter = ReportSettings.DataParameters.Items.Find("Contract");
	ReportDataParameter = ReportSettings.DataParameters.Items.Find("ReportData");
	
	DiscountDataTable = GetDiscountData(
		PeriodParameter.Value,
		ReportDataParameter.Value,
		?(ContractParameter.Use, ContractParameter.Value, Undefined),
		?(DocumentParameter.Use, DocumentParameter.Value, Undefined),
		Undefined);
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);

	ExternalDataSets = New Structure;
	ExternalDataSets.Insert("DiscountDataTable", DiscountDataTable);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, ExternalDataSets, DetailsData, True);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
EndProcedure

#EndRegion

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - See ReportsClientServer.GetDefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	Settings.Events.OnCreateAtServer = True;
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - Report form
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	Parameters = ThisForm.Parameters;
	
	If Parameters.Property("CommandParameter") Then
		If TypeOf(Parameters.CommandParameter) = Type("Array") Then
			ReferencesArrray = Parameters.CommandParameter;
		Else
			ReferencesArrray = CommonClientServer.ValueInArray(Parameters.CommandParameter);
		EndIf;
		
		If Not ThisForm.ParametersForm.Filter.Property("Document") Then
			ThisForm.ParametersForm.Filter.Insert("Document", 
				GetDiscountDocuments(ReferencesArrray));
			If ReferencesArrray.Count() > 0 Then
				Ref = ReferencesArrray[0];
				ThisForm.ParametersForm.Filter.Insert("ReportPeriod", 
					BegOfMonth(Common.ObjectAttributeValue(Ref, "Date")))
			EndIf;
		EndIf;
	ElsIf Parameters.Property("MonthEndTransactions") And Parameters.MonthEndTransactions Then
		
		ThisForm.ParametersForm.Filter.Insert("Document", 
			GetDiscountDocuments(Undefined, Parameters.CompanyArray, Parameters.Period));
		ThisForm.ParametersForm.Filter.Insert("ReportPeriod", Parameters.Period);
		ThisForm.CurrentVariantKey = "ContextOption_";
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure GenerateReport(SpreadsheetDocument, Period, FilterDocuments, ReportData, FilterARAPObject, ThereIsDataToDisplay) Export
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.Clear();
	
	Template = GetTemplate("Template");
	
	HeaderAreaTwoColumns = Template.GetArea("HeaderAreaTwoColumns");
	HeaderAreaOneColumn = Template.GetArea("HeaderAreaOneColumn");
	Area_TableHeader = Template.GetArea("Area_TableHeader");
	AreaRow = Template.GetArea("AreaRow");
	BasementArea = Template.GetArea("BasementArea");
	
	DiscountDataTable = GetDiscountData(Period, ReportData,, FilterDocuments, FilterARAPObject);
	ColumnsSum = "ActualDebtWithoutVAT, 
		|DiscountedDebtWithoutVAT, 
		|CalculatedInterestBalance,
		|ChangeInInterestAmount,
		|FixActualDebtExcludingVAT, 
		|FixedDiscountedDebtExcludingVAT, 
		|FixCalculatedInterestBalance,
		|FixedChangeInInterestAmount,
		|DiscountingAmountBalance";
	DimensionsTable = DiscountDataTable.Copy(,"ARAPDocument, ARAPObject, Organization," + ColumnsSum);
	DimensionsTable.GroupBy("ARAPDocument, ARAPObject, Organization", ColumnsSum);
	
	DiscountDataTable.Indexes.Add("ARAPDocument, ARAPObject");
	
	Filter = New Structure("ARAPDocument, ARAPObject");
	
	For Each DimensionString In DimensionsTable Do
		
		FillPropertyValues(Filter, DimensionString);
		PaymentScheduleLines = DiscountDataTable.FindRows(Filter);
		
		PaymentScheduleLine_ = PaymentScheduleLines[0];
		ActualDebtDiffers = DimensionString.ActualDebtWithoutVAT <> DimensionString.FixActualDebtExcludingVAT;
		DiscountRateDiffers = PaymentScheduleLine_.DiscountRate <> PaymentScheduleLine_.FixedDiscountRate;
		DiscountedDebtDiffers = DimensionString.DiscountedDebtWithoutVAT <> DimensionString.FixedDiscountedDebtExcludingVAT;
		CalculatedBalanceOfInterestDiffers = DimensionString.CalculatedInterestBalance <> DimensionString.FixCalculatedInterestBalance;
		ChangeInAmountOfInterestDiffers = DimensionString.ChangeInInterestAmount <> DimensionString.FixedChangeInInterestAmount;
		OutputFixed = PaymentScheduleLine_.DeduceDifferences
			And ( ActualDebtDiffers
			Or DiscountRateDiffers 
			Or DiscountedDebtDiffers
			Or CalculatedBalanceOfInterestDiffers
			Or ChangeInAmountOfInterestDiffers);
		
		SectionHeader = ?(OutputFixed, HeaderAreaTwoColumns, HeaderAreaOneColumn);
		
		SectionHeader.Parameters.Fill(PaymentScheduleLine_);
		SectionHeader.Parameters.Fill(DimensionString);
		SectionHeader.Parameters.ReportingMonth = Format(PaymentScheduleLine_.ReportingDate, NStr("vi = 'ДФ=''ММММ ""năm"" гггг''';
																									|ru = 'ДФ=''ММММ гггг ""г.""''';
																									|en = 'DF=''MMMM yyyy'''; fa = 'DF=''MMMM yyyy''';
																									|it = 'ДФ=''ММММ гггг ""a.""''';
																									|pl = 'DF=''ММММ yyyy ""r.""''';
																									|tr = 'DF=''MMMM yyyy ""yıl.""'''"));
		If OutputFixed Then
			
			SectionHeader.Areas.ActualArrears.BackColor = ?(ActualDebtDiffers, WebColors.Yellow, New Color);
			SectionHeader.Areas.DiscountRate.BackColor = ?(DiscountRateDiffers, WebColors.Yellow, New Color);
			SectionHeader.Areas.DiscountedDebt.BackColor = ?(DiscountedDebtDiffers, WebColors.Yellow, New Color);
			SectionHeader.Areas.CalculatedInterestBalance.BackColor = ?(CalculatedBalanceOfInterestDiffers, WebColors.Yellow, New Color);
			SectionHeader.Areas.ChangeInInterestAmount.BackColor = ?(ChangeInAmountOfInterestDiffers, WebColors.Yellow, New Color);
			
		EndIf;
		
		SpreadsheetDocument.Put(SectionHeader);
		Area_TableHeader.Parameters.ReportingDate = Format(PaymentScheduleLine_.ReportingDate, "DLF=D");
		If ReportData = 1 Then
			Area_TableHeader.Parameters.Currency = PaymentScheduleLine_.Currency;
		ElsIf ReportData = 2 Then
			Area_TableHeader.Parameters.Currency = SettingsValueCached.ManagementAccountingCurrency();
		ElsIf ReportData = 3 Then
			Area_TableHeader.Parameters.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(DimensionString.Organization);
		EndIf;
		SpreadsheetDocument.Put(Area_TableHeader);
		
		For Each PaymentScheduleLine_ In PaymentScheduleLines Do
			
			AreaRow.Parameters.Fill(PaymentScheduleLine_);
			AreaRow.Parameters.PlannedRepaymentDate = Format(PaymentScheduleLine_.PlannedRepaymentDate, "DLF=D");
			If PaymentScheduleLine_.PlannedRepaymentDate > PaymentScheduleLine_.ReportingDate Then
				AreaRow.Areas.PlannedRepaymentDate.BackColor = New Color;
			ElsIf OutputFixed Then
				AreaRow.Areas.PlannedRepaymentDate.BackColor = WebColors.Yellow;
			EndIf;
			
			SpreadsheetDocument.Put(AreaRow);
			
		EndDo;
		
		BasementArea.Parameters.Fill(DimensionString);
		BasementArea.Parameters.ReportingDate = Format(PaymentScheduleLine_.ReportingDate, "DLF=D");
		SpreadsheetDocument.Put(BasementArea);
		
		ThereIsDataToDisplay = True;
		
	EndDo;
	
EndProcedure

Function FixedDataRequestText()
	QueryText = 
		"SELECT ALLOWED
		|	DiscountInterestExpense.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	DiscountInterestExpense.ARAPObject AS ARAPObject,
		|	DiscountInterestExpense.Currency AS Currency,
		|	DiscountInterestExpense.ARAPDocument AS ARAPDocument,
		|	DiscountInterestExpense.DiscountRate AS DiscountRate,
		|	CASE &ReportData
		|		WHEN 1
		|			THEN DiscountInterestExpense.ActualDebtWithoutVAT
		|		WHEN 2
		|			THEN DiscountInterestExpense.ActualDebtWithoutVATMan
		|		ELSE DiscountInterestExpense.ActualDebtWithoutVATCompl
		|	END AS ActualDebtWithoutVAT,
		|	CASE &ReportData
		|		WHEN 1
		|			THEN DiscountInterestExpense.DiscountedDebtWithoutVAT
		|		WHEN 2
		|			THEN DiscountInterestExpense.DiscountedDebtWithoutVATMan
		|		ELSE DiscountInterestExpense.DiscountedDebtWithoutVATCompl
		|	END AS DiscountedDebtWithoutVAT,
		|	CASE &ReportData
		|		WHEN 1
		|			THEN DiscountInterestExpense.CalculatedInterestBalance
		|		WHEN 2
		|			THEN DiscountInterestExpense.CalculatedInterestBalanceMan
		|		ELSE DiscountInterestExpense.CalculatedInterestBalanceCompl
		|	END AS CalculatedInterestBalance,
		|	DiscountInterestExpense.Period AS Period,
		|	VALUETYPE(DiscountInterestExpense.Recorder) = TYPE(Document.CalculationOfDiscountInterestExpenses) AS ThisIsCalculationOfInterestExpense,
		|	DimensionKeysOfAccountingByPartners.Organization AS Organization
		|INTO TTWriteOff
		|FROM
		|	AccumulationRegister.DiscountInterestExpense AS DiscountInterestExpense
		|		INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS DimensionKeysOfAccountingByPartners
		|		ON DiscountInterestExpense.AccountingDimensionByPartners = DimensionKeysOfAccountingByPartners.Ref
		|WHERE
		|	DiscountInterestExpense.Active
		|	AND DiscountInterestExpense.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND DiscountInterestExpense.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND VALUETYPE(DiscountInterestExpense.Recorder) IN (TYPE(Document.PurchaseAdjustment), TYPE(Document.CalculationOfDiscountInterestExpenses))
		|	AND &FilterByContract
		|	AND &FilterByDocument
		|	AND &SelectionByCalculationObject
		|
		|INDEX BY
		|	AccountingDimensionByPartners,
		|	ARAPObject,
		|	Currency,
		|	ARAPDocument,
		|	Period,
		|	ThisIsCalculationOfInterestExpense
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	TTWriteOff.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	TTWriteOff.ARAPObject AS ARAPObject,
		|	TTWriteOff.Currency AS Currency,
		|	TTWriteOff.ARAPDocument AS ARAPDocument,
		|	MAX(TTWriteOff.Period) AS Period,
		|	MAX(TTWriteOff.ThisIsCalculationOfInterestExpense) AS ThisIsCalculationOfInterestExpense
		|INTO TTPeriods
		|FROM
		|	TTWriteOff AS TTWriteOff
		|
		|GROUP BY
		|	TTWriteOff.AccountingDimensionByPartners,
		|	TTWriteOff.ARAPObject,
		|	TTWriteOff.Currency,
		|	TTWriteOff.ARAPDocument
		|
		|INDEX BY
		|	AccountingDimensionByPartners,
		|	ARAPObject,
		|	Currency,
		|	ARAPDocument,
		|	Period,
		|	ThisIsCalculationOfInterestExpense
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TTWriteOff.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	TTWriteOff.ARAPObject AS ARAPObject,
		|	TTWriteOff.Currency AS Currency,
		|	TTWriteOff.ARAPDocument AS ARAPDocument,
		|	TTWriteOff.DiscountRate AS DiscountRate,
		|	TTWriteOff.ActualDebtWithoutVAT AS ActualDebtWithoutVAT,
		|	TTWriteOff.DiscountedDebtWithoutVAT AS DiscountedDebtWithoutVAT,
		|	TTWriteOff.CalculatedInterestBalance AS CalculatedInterestBalance,
		|	TTWriteOff.Period AS Period,
		|	TTWriteOff.ThisIsCalculationOfInterestExpense AS ThisIsCalculationOfInterestExpense,
		|	TTWriteOff.Organization AS Organization
		|INTO TTAdditionalCharge
		|FROM
		|	TTWriteOff AS TTWriteOff
		|		INNER JOIN TTPeriods AS TTPeriods
		|		ON TTWriteOff.AccountingDimensionByPartners = TTPeriods.AccountingDimensionByPartners
		|			AND TTWriteOff.ARAPObject = TTPeriods.ARAPObject
		|			AND TTWriteOff.Currency = TTPeriods.Currency
		|			AND TTWriteOff.ARAPDocument = TTPeriods.ARAPDocument
		|			AND TTWriteOff.Period = TTPeriods.Period
		|			AND TTWriteOff.ThisIsCalculationOfInterestExpense = TTPeriods.ThisIsCalculationOfInterestExpense
		|
		|INDEX BY
		|	AccountingDimensionByPartners,
		|	ARAPObject,
		|	Currency,
		|	ARAPDocument
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DiscountInterestExpenseBalance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	DiscountInterestExpenseBalance.ARAPObject AS ARAPObject,
		|	CASE &ReportData
		|		WHEN 1
		|			THEN DiscountInterestExpenseBalance.Currency
		|		WHEN 2
		|			THEN &ManagementAccountingCurrency
		|		ELSE DimensionKeysOfAccountingByPartners.Organization.LocalAccountingCurrency
		|	END                                                          AS Currency,
		|	DiscountInterestExpenseBalance.Currency AS ARAPCurrency,
		|	DiscountInterestExpenseBalance.ARAPDocument AS ARAPDocument,
		|	CASE &ReportData
		|		WHEN 1
		|			THEN DiscountInterestExpenseBalance.DiscountingAmountBalance
		|		WHEN 2
		|			THEN DiscountInterestExpenseBalance.DiscountingAmountManBalance
		|		ELSE DiscountInterestExpenseBalance.DiscountingAmountComplBalance
		|	END AS DiscountingAmountBalance,
		|	DimensionKeysOfAccountingByPartners.Counterparty AS Counterparty,
		|	DimensionKeysOfAccountingByPartners.Contract AS Contract,
		|	CounterpartyContracts.DiscountRate AS DiscountRate,
		|	CounterpartyContracts.VATRate AS VATRate
		|INTO TTBalance
		|FROM
		|	AccumulationRegister.DiscountInterestExpense.Balance(
		|			&EndOfPeriodExcluding,
		|			(AccountingDimensionByPartners, Currency, ARAPObject, ARAPDocument) IN
		|				(SELECT
		|					TTAdditionalCharge.AccountingDimensionByPartners,
		|					TTAdditionalCharge.Currency,
		|					TTAdditionalCharge.ARAPObject,
		|					TTAdditionalCharge.ARAPDocument
		|				FROM
		|					TTAdditionalCharge)) AS DiscountInterestExpenseBalance
		|		LEFT JOIN Catalog.DimensionKeysOfAccountingByPartners AS DimensionKeysOfAccountingByPartners
		|			LEFT JOIN Catalog.CounterpartyContracts AS CounterpartyContracts
		|			ON DimensionKeysOfAccountingByPartners.Contract = CounterpartyContracts.Ref
		|		ON DiscountInterestExpenseBalance.AccountingDimensionByPartners = DimensionKeysOfAccountingByPartners.Ref
		|
		|INDEX BY
		|	AccountingDimensionByPartners,
		|	ARAPObject,
		|	Currency,
		|	ARAPDocument
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TTBalance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	TTBalance.Currency AS Currency,
		|	TTBalance.ARAPObject AS ARAPObject,
		|	TTBalance.ARAPDocument AS ARAPDocument,
		|	TTBalance.DiscountingAmountBalance AS DiscountingAmountBalance,
		|	TTBalance.Counterparty AS Counterparty,
		|	TTBalance.Contract AS Contract,
		|	TTBalance.DiscountRate AS DiscountRate,
		|	ISNULL(TTAdditionalCharge.DiscountRate, 0) AS FixedDiscountRate,
		|	ISNULL(TTAdditionalCharge.ActualDebtWithoutVAT, 0) AS FixActualDebtExcludingVAT,
		|	ISNULL(TTAdditionalCharge.DiscountedDebtWithoutVAT, 0) AS FixedDiscountedDebtExcludingVAT,
		|	ISNULL(TTAdditionalCharge.CalculatedInterestBalance, 0) AS FixCalculatedInterestBalance,
		|	TTAdditionalCharge.Period AS FixationPeriod,
		|	TTBalance.DiscountingAmountBalance - ISNULL(TTAdditionalCharge.CalculatedInterestBalance, 0) AS FixedChangeInInterestAmount,
		|	&ReportingDate AS ReportingDate,
		|	TTBalance.VATRate AS VATRate,
		|	TTAdditionalCharge.Organization AS Organization
		|FROM
		|	TTBalance AS TTBalance
		|		LEFT JOIN TTAdditionalCharge AS TTAdditionalCharge
		|		ON TTBalance.AccountingDimensionByPartners = TTAdditionalCharge.AccountingDimensionByPartners
		|			AND TTBalance.ARAPCurrency = TTAdditionalCharge.Currency
		|			AND TTBalance.ARAPObject = TTAdditionalCharge.ARAPObject
		|			AND TTBalance.ARAPDocument = TTAdditionalCharge.ARAPDocument";
	
	Return QueryText
	
EndFunction

Function RequestTextForGraphData()
	
	QueryText = 
		"SELECT
		|	DocumentAmountsInAccountingCurrency.Recorder AS Recorder,
		|	CASE
		|		WHEN SUM(DocumentAmountsInAccountingCurrency.AmountARAP) = 0
		|			THEN 0
		|		ELSE CAST(SUM(DocumentAmountsInAccountingCurrency.AmountARAP - DocumentAmountsInAccountingCurrency.AmountVATARAP) / SUM(DocumentAmountsInAccountingCurrency.AmountARAP) AS NUMBER(11, 10))
		|	END AS CoefficientOfAmountWithoutVAT
		|INTO TTCoefficientsOfVATAmount
		|FROM
		|	InformationRegister.DocumentAmountsInAccountingCurrency AS DocumentAmountsInAccountingCurrency
		|WHERE
		|	DocumentAmountsInAccountingCurrency.Active
		|	AND DocumentAmountsInAccountingCurrency.Recorder IN
		|			(SELECT
		|				TTWriteOff.ARAPDocument
		|			FROM
		|				TTWriteOff)
		|
		|GROUP BY
		|	DocumentAmountsInAccountingCurrency.Recorder
		|
		|INDEX BY
		|	Recorder
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	VendorsARAPAccountingByDueDatesBalance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	VendorsARAPAccountingByDueDatesBalance.ARAPObject AS ARAPObject,
		|	CASE &ReportData
		|		WHEN 1
		|			THEN VendorsARAPAccountingByDueDatesBalance.Currency
		|		WHEN 2
		|			THEN &ManagementAccountingCurrency
		|		ELSE DimensionKeysOfAccountingByPartners.Organization.LocalAccountingCurrency
		|	END                                                          AS Currency,
		|	VendorsARAPAccountingByDueDatesBalance.ARAPDocument AS ARAPDocument,
		|	VendorsARAPAccountingByDueDatesBalance.PlannedRepaymentDate AS PlannedRepaymentDate,
		|	VendorsARAPAccountingByDueDatesBalance.OccurrenceDate AS PurchaseDate,
		|	CASE &ReportData
		|		WHEN 1
		|			THEN VendorsARAPAccountingByDueDatesBalance.DebtBalance
		|		WHEN 2
		|			THEN VendorsARAPAccountingByDueDatesBalance.ARAPManBalance
		|		ELSE VendorsARAPAccountingByDueDatesBalance.DebtLocalBalance
		|	END AS DebtBalance,
		|	VendorsARAPAccountingByDueDatesBalance.DebtBalance AS DebtBalanceOfSettlements,
		|	CAST(CASE &ReportData
		|		WHEN 1
		|			THEN VendorsARAPAccountingByDueDatesBalance.DebtBalance
		|		WHEN 2
		|			THEN VendorsARAPAccountingByDueDatesBalance.ARAPManBalance
		|		ELSE VendorsARAPAccountingByDueDatesBalance.DebtLocalBalance
		|	END * TTCoefficientsOfVATAmount.CoefficientOfAmountWithoutVAT AS NUMBER(31, 2)) AS ActualDebtWithoutVAT,
		|	CASE
		|		WHEN VendorsARAPAccountingByDueDatesBalance.PlannedRepaymentDate > &ReportingDate
		|			THEN DATEDIFF(&ReportingDate, VendorsARAPAccountingByDueDatesBalance.PlannedRepaymentDate, DAY)
		|		ELSE 1
		|	END AS NumberOfDaysBeforePayment
		|FROM
		|	AccumulationRegister.VendorsARAPAccountingByDueDates.Balance(
		|			&EndOfPeriod,
		|			(AccountingDimensionByPartners, Currency, ARAPObject, ARAPDocument) IN
		|				(SELECT
		|					TTWriteOff.AccountingDimensionByPartners,
		|					TTWriteOff.Currency,
		|					TTWriteOff.ARAPObject,
		|					TTWriteOff.ARAPDocument
		|				FROM
		|					TTWriteOff)) AS VendorsARAPAccountingByDueDatesBalance
		|		LEFT JOIN TTCoefficientsOfVATAmount AS TTCoefficientsOfVATAmount
		|		ON VendorsARAPAccountingByDueDatesBalance.ARAPDocument = TTCoefficientsOfVATAmount.Recorder
		|		INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS DimensionKeysOfAccountingByPartners
		|		ON VendorsARAPAccountingByDueDatesBalance.AccountingDimensionByPartners = DimensionKeysOfAccountingByPartners.Ref";

	Return QueryText
	
EndFunction

Function GetDiscountData(PeriodParameter, ReportData, Contract = Undefined, Document = Undefined, ARAPObject = Undefined)
	
	If PeriodParameter = Undefined Then
		Period = Date(1,1,1);
	Else
		Period = PeriodParameter;
	EndIf;
	
	Query = New Query;
	Query.Text = FixedDataRequestText();
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("BeginOfPeriod", BegOfMonth(Period));
	Query.SetParameter("EndOfPeriod", EndOfMonth(Period));
	Query.SetParameter("EndOfPeriodExcluding", New Boundary(EndOfMonth(Period), BoundaryType.Excluding));
	Query.SetParameter("ReportingDate", BegOfDay(EndOfMonth(Period)));
	Query.SetParameter("ReportData", ReportData);
	Query.SetParameter("ManagementAccountingCurrency", SettingsValueCached.ManagementAccountingCurrency());
	
	If Contract <> Undefined Then
		Query.SetParameter("Contract", Contract);
		Query.Text = StrReplace(Query.Text, "&FilterByContract", "DimensionKeysOfAccountingByPartners.Contract = &Contract");
	Else
		Query.SetParameter("FilterByContract", True);
	EndIf;
	
	If Document <> Undefined Then
		Query.SetParameter("Document", Document);
		Query.Text = StrReplace(Query.Text, "&FilterByDocument", "DiscountInterestExpense.ARAPDocument IN (&Document)");
	Else 
		Query.SetParameter("FilterByDocument", True);
	EndIf;
	
	If ARAPObject <> Undefined Then
		Query.SetParameter("ARAPObject", ARAPObject);
		Query.Text = StrReplace(Query.Text, "&SelectionByCalculationObject", "DiscountInterestExpense.ARAPObject = &ARAPObject");
	Else 
		Query.SetParameter("SelectionByCalculationObject", True);
	EndIf;
	
	QueryResult = Query.Execute();
	TableFixedData = QueryResult.Unload();
	
	Query.Text = RequestTextForGraphData();
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	
	ChartDataTable = QueryResult.Unload();
	KeyFieldColumns = "AccountingDimensionByPartners, ARAPObject, Currency, ARAPDocument" ;
	ChartDataTable.Indexes.Add(KeyFieldColumns);
	
	ResultTable1 = TableFixedData.CopyColumns();
	ResultTable1.Columns.Add("PurchaseDate", Common.DateTypeDetails(DateFractions.Date));
	ResultTable1.Columns.Add("PlannedRepaymentDate", Common.DateTypeDetails(DateFractions.Date));
	ResultTable1.Columns.Add("ActualDebtWithoutVAT", Common.TypeDescriptionNumber(31, 2));
	ResultTable1.Columns.Add("NumberOfDaysBeforePayment", Common.TypeDescriptionNumber(10));
	ResultTable1.Columns.Add("CalculatedInterestBalance", TMCommonUse.DescriptionOfTypesByType(Type("Number")));
	ResultTable1.Columns.Add("CalculatedBalanceOfInterestSettlements", TMCommonUse.DescriptionOfTypesByType(Type("Number")));
	ResultTable1.Columns.Add("DiscountedDebtWithoutVAT", Common.TypeDescriptionNumber(31, 2));
	ResultTable1.Columns.Add("ChangeInInterestAmount", Common.TypeDescriptionNumber(31, 2));
	ResultTable1.Columns.Add("DeduceDifferences", New TypeDescription("Boolean"));
	
	Filter = New Structure(KeyFieldColumns);
	ColumnsSum = 	"DiscountingAmountBalance,
					|FixActualDebtExcludingVAT,
					|FixedDiscountedDebtExcludingVAT,
					|FixCalculatedInterestBalance,
					|FixedChangeInInterestAmount";
	
	For Each FixString In TableFixedData Do 
		
		FillPropertyValues(Filter, FixString);
		NewRow = ResultTable1.Add();
		StringWithFixedValues = NewRow;
		FillPropertyValues(NewRow, FixString);
		
		GraphLines = ChartDataTable.FindRows(Filter);
		FillInCurLine                    = True;
		ActualDebtWithoutVAT            = 0;
		CalculatedInterestBalance              = 0;
		CalculatedBalanceOfInterestSettlements = 0;
		ControlCalculatedInterestBalance      = 0;
		GraphLineWithMaximumPercentages     = Undefined;
		
		For Each PlotLine In GraphLines Do 
			
			If FillInCurLine Then
				FillInCurLine = False;
			Else
				NewRow = ResultTable1.Add();
				FillPropertyValues(NewRow, FixString,, ColumnsSum);
			EndIf;
			
			
			FillPropertyValues(NewRow, PlotLine,, KeyFieldColumns);
			DebtBalanceOfSettlements = PlotLine.DebtBalanceOfSettlements;
			If TypeOf(FixString.ARAPDocument) = Type("DocumentRef.SourceDocument") Then
				VATRate = VATAccountingERPClientServer.ValueOfVATRate(FixString.VATRate) / 100;
				NewRow.ActualDebtWithoutVAT = Round(PlotLine.DebtBalance / (1 + VATRate), 2);
				DebtBalanceOfSettlements = Round(DebtBalanceOfSettlements / (1 + VATRate), 2);
			EndIf;
			
			NewRow.CalculatedInterestBalance = NewRow.ActualDebtWithoutVAT 
				*(1 - 1 / Pow(1+NewRow.DiscountRate/100, NewRow.NumberOfDaysBeforePayment/365));
			NewRow.CalculatedBalanceOfInterestSettlements = DebtBalanceOfSettlements 
				*(1 - 1 / Pow(1+NewRow.DiscountRate/100, NewRow.NumberOfDaysBeforePayment/365));
			
			If GraphLineWithMaximumPercentages = Undefined 
				Or NewRow.CalculatedInterestBalance > GraphLineWithMaximumPercentages.CalculatedInterestBalance Then
				GraphLineWithMaximumPercentages = NewRow;
			EndIf;
			
			ActualDebtWithoutVAT                        = ActualDebtWithoutVAT + NewRow.ActualDebtWithoutVAT;
			CalculatedInterestBalance                          = CalculatedInterestBalance + NewRow.CalculatedInterestBalance;
			CalculatedBalanceOfInterestSettlements             = CalculatedBalanceOfInterestSettlements + NewRow.CalculatedBalanceOfInterestSettlements;
			NewRow.CalculatedBalanceOfInterestSettlements = Round(NewRow.CalculatedBalanceOfInterestSettlements, 2);
			If NewRow.CalculatedBalanceOfInterestSettlements = 0 Then
				NewRow.CalculatedInterestBalance          = 0;
			Else
				NewRow.CalculatedInterestBalance          = Round(NewRow.CalculatedInterestBalance, 2);
			EndIf;
			ControlCalculatedInterestBalance                  = ControlCalculatedInterestBalance + NewRow.CalculatedInterestBalance;
			NewRow.DiscountedDebtWithoutVAT       = NewRow.ActualDebtWithoutVAT - NewRow.CalculatedInterestBalance;
		
		EndDo;
		
		CalculatedInterestBalance = Round(CalculatedInterestBalance, 2);
		CalculatedBalanceOfInterestSettlements = Round(CalculatedBalanceOfInterestSettlements, 2);
		If CalculatedBalanceOfInterestSettlements = 0 Then
			CalculatedInterestBalance = 0
		EndIf;
		InterestAdjustment = CalculatedInterestBalance - ControlCalculatedInterestBalance;
		If InterestAdjustment <> 0 Then
			GraphLineWithMaximumPercentages.CalculatedInterestBalance = GraphLineWithMaximumPercentages.CalculatedInterestBalance 
				+ InterestAdjustment;
			GraphLineWithMaximumPercentages.DiscountedDebtWithoutVAT = GraphLineWithMaximumPercentages.DiscountedDebtWithoutVAT 
				- InterestAdjustment;
		EndIf;
		
		DiscountedDebtWithoutVAT = ActualDebtWithoutVAT - CalculatedInterestBalance;
		
		StringWithFixedValues.ChangeInInterestAmount = FixString.DiscountingAmountBalance 
			- CalculatedInterestBalance;
		
		DeduceDifferences = 
			FixString.DiscountRate <> FixString.FixedDiscountRate
			Or ActualDebtWithoutVAT <> FixString.FixActualDebtExcludingVAT
			Or DiscountedDebtWithoutVAT <> FixString.FixedDiscountedDebtExcludingVAT
			Or CalculatedInterestBalance <> FixString.FixCalculatedInterestBalance
			Or StringWithFixedValues.ChangeInInterestAmount <> FixString.FixedChangeInInterestAmount;
		
		StringWithFixedValues.DeduceDifferences = DeduceDifferences;
		
	EndDo;
	
	Return ResultTable1;
	
EndFunction

Function GetDiscountDocuments(RoutineOperations, Companies = Undefined, Period = Undefined)
	Query = New Query;
	If Companies <> Undefined And Period <> Undefined Then
		Query.SetParameter("Companies", Companies);
		Query.SetParameter("Period", EndOfMonth(Period));
		Query.Text = 
			"SELECT
			|	DiscountInterestExpense.ARAPDocument AS ARAPDocument
			|FROM
			|	AccumulationRegister.DiscountInterestExpense AS DiscountInterestExpense
			|		LEFT JOIN Document.CalculationOfDiscountInterestExpenses AS CalculationOfDiscountInterestExpenses
			|		ON DiscountInterestExpense.Recorder = CalculationOfDiscountInterestExpenses.Ref
			|WHERE
			|	DiscountInterestExpense.Active
			|	AND CalculationOfDiscountInterestExpenses.Organization IN(&Companies)
			|	AND CalculationOfDiscountInterestExpenses.Date = &Period";
	Else
		Query.SetParameter("Recorders", RoutineOperations);
		Query.Text = 
			"SELECT
			|	DiscountInterestExpense.ARAPDocument AS ARAPDocument
			|FROM
			|	AccumulationRegister.DiscountInterestExpense AS DiscountInterestExpense
			|WHERE
			|	DiscountInterestExpense.Active
			|	AND DiscountInterestExpense.Recorder IN(&Recorders)";
	EndIf;
	Return Query.Execute().Unload().UnloadColumn("ARAPDocument");
EndFunction

#EndRegion

#EndIf