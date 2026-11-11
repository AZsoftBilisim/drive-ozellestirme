#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	UserSettingsModified = False;
	
	SetRequiredSettings(SettingsComposer, UserSettingsModified);
	
	// Generate a report
	ReportSettings = SettingsComposer.GetSettings();
	
	SelectedFieldsArray = New Array;
	FindSelectedFieldsRecursively(ReportSettings.Selection.Items, SelectedFieldsArray);
	IncludeShippingPlan = False;
	IncludePaymentPlan = False;
	For Each SelectedField In SelectedFieldsArray Do 
		If String(SelectedField.Field) = "ToShip" Then
			IncludeShippingPlan = True;
		EndIf;
		If String(SelectedField.Field) = "CustomerAccountsReceivable"
			Or String(SelectedField.Field) = "OverdueCustomerDebt" Then
			IncludePaymentPlan = True;
		EndIf;
	EndDo;
	DataCompositionClientServer.SetParameter(ReportSettings, "IncludeShippingPlan", IncludeShippingPlan);
	DataCompositionClientServer.SetParameter(ReportSettings, "IncludePaymentPlan", IncludePaymentPlan);
	
	DataCompositionSchema.DataSets.DataSet.Query = QueryText();
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	
	// A warning about the unfulfilled distribution of mutual settlements.
	ARAPAccountingServer.DisplayUpdateWarning(ResultDocument);
	
	OutputProcessor.Output(CompositionProcessor);
	
	DataCompositionServer.CreateReportDiagrams(SettingsComposer, ResultDocument);
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
	
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
	Settings.Events.BeforeLoadVariantAtServer = True;
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - Report form:
//   	* Parameters - Structure:
//   		** CommandDetails - Structure:
//   			*** AdditionalParameters - Structure
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	Parameters = ThisForm.Parameters;
	
	If Parameters.Property("CommandParameter") Then 
		
		ThisForm.ReportSettings.OptionSelectionAllowed = False;
		
		ARAPObjects = Documents.ARAPAccountingScheduleAdjustment.ObjectsOfAdjustmentCalculations(Parameters.CommandParameter);
		FilterValue = New ValueList;
		FilterValue.LoadValues(ARAPObjects);
		CommonClientServer.SetFilterItem(
			SettingsComposer.FixedSettings.Filter,
			"ARAPObject",
			FilterValue,
			DataCompositionComparisonType.InList,,
			True);
		
	EndIf;
	
EndProcedure

// Called in the report form handler of the same name after executing the form code.
//
// More detailed - See ReportsOverridable.BeforeLoadVariantAtServer
//
Procedure BeforeLoadVariantAtServer(ThisForm, NewDCSettings) Export
	Report = ThisForm.Report;
	FormSettingsComposer = Report.SettingsComposer;
	
	// Changing settings by functional options
	ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer);
	
	// Setting default values
	SetRequiredSettings(FormSettingsComposer, True);
	
	NewDCSettings = FormSettingsComposer.Settings;
EndProcedure

#EndRegion

#Region Private

Procedure SetRequiredSettings(Var_SettingsComposer, UserSettingsModified)
	
	SetCalendar(Var_SettingsComposer, UserSettingsModified);
	SegmentsServer.EnableSelectionByVSKDPartnerSegment(Var_SettingsComposer);
	SetReportDate(Var_SettingsComposer, UserSettingsModified);
	EstablishDebtClassificationOption(Var_SettingsComposer, UserSettingsModified);
	SetStringParametersOfReport(Var_SettingsComposer, UserSettingsModified);
	
EndProcedure

Procedure SetReportDate(Var_SettingsComposer, UserSettingsModified)
	BalanceDateParameter = DataCompositionClientServer.GetParameter(Var_SettingsComposer, "ReportDate");
	BalanceDateParameter.Use = True;
	
	ReportDateParameterBorder = DataCompositionClientServer.GetParameter(Var_SettingsComposer, "DateOfReportBorder");
	ReportDateParameterBorder.Use = True;
	
	If TypeOf(BalanceDateParameter.Value) = Type("StandardBeginningDate") Then
		If Not ValueIsFilled(BalanceDateParameter.Value.Date) Then
			BalanceDateParameter.Value.Date = EndOfDay(CurrentSessionDate());
			UserSettingsModified = True;
		EndIf;
		ReportDateParameterBorder.Value = New Boundary(EndOfDay(BalanceDateParameter.Value.Date), BoundaryType.Including);
	Else
		If Not ValueIsFilled(BalanceDateParameter.Value) Then
			BalanceDateParameter.Value = EndOfDay(CurrentSessionDate());
			UserSettingsModified = True;
		EndIf;
		ReportDateParameterBorder.Value = New Boundary(EndOfDay(BalanceDateParameter.Value), BoundaryType.Including);
	EndIf;
EndProcedure

Procedure EstablishDebtClassificationOption(Var_SettingsComposer, UserSettingsModified)
	ParameterDebtClassificationOption = DataCompositionClientServer.GetParameter(Var_SettingsComposer, "DebtClassificationOption");
	If Not ValueIsFilled(ParameterDebtClassificationOption.Value) Then
		Query = New Query;
		Query.Text = "SELECT TOP 1
			|	TimeBucketsForAgingAnalysis.Ref
			|FROM
			|	Catalog.TimeBucketsForAgingAnalysis AS TimeBucketsForAgingAnalysis
			|WHERE
			|	NOT TimeBucketsForAgingAnalysis.DeletionMark";
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			UserSettingsModified = True;
			ParameterDebtClassificationOption.Value = Selection.Ref;
		EndIf;
	EndIf;
EndProcedure

Procedure ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer)
	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(FormSettingsComposer, "Counterparty");
	EndIf;
EndProcedure

Procedure SetStringParametersOfReport(Var_SettingsComposer, UserSettingsModified)
	
	UserSettingsModified = True;
	
	DebtStringParameterIsNotControlled = DataCompositionClientServer.GetParameter(Var_SettingsComposer, "DebtLineIsNotControlled");
	DebtStringParameterIsNotControlled.Value = NStr("vi = 'Không kiểm soát';
													|ru = 'Не контролируется';
													|en = 'Not controlled'; fa = 'کنترل‌نشده';
													|it = 'Не контролируется';
													|pl = 'Not controlled';
													|tr = 'Kontrol edilmiyor'");
	
	ParameterStringDebtIsNotOverdue = DataCompositionClientServer.GetParameter(Var_SettingsComposer, "LineDebtIsNotOverdue");
	ParameterStringDebtIsNotOverdue.Value = NStr("vi = 'Chưa quá hạn';
												|ru = 'Не просрочено';
												|en = 'Not overdue'; fa = 'معوق نشده';
												|it = 'Non scaduto';
												|pl = 'Nie przeterminowano';
												|tr = 'Vadesi geçmemiş'");
	
	ParameterStringIsStateOfVARAPAccounts = DataCompositionClientServer.GetParameter(Var_SettingsComposer, "LineMutualSettlementsState");
	ParameterStringIsStateOfVARAPAccounts.Value = NStr("vi = 'Trạng thái hạch toán công nợ';
														|ru = 'Состояние взаиморасчетов';
														|en = 'AR/AP state'; fa = 'وضعیت دریافتنی/پرداختنی';
														|it = 'Lo stato di conti reciproci';
														|pl = 'Status rozliczeń wzajemnych';
														|tr = 'Karşılıklı uzlaşmaların durumu'");
	
EndProcedure

Function QueryText()
	
	QueryText = "SELECT ALLOWED DISTINCT
	|	Segments.Partner AS Partner,
	|	TRUE AS FilterByPartnerSegmentIsUsed
	|INTO SelectionByPartnerSegment
	|FROM
	|	InformationRegister.SegmentPartners AS Segments
	|{WHERE
	|	Segments.Segment.* AS PartnersSegment,
	|	Segments.Partner.* AS Partner}
	|
	|INDEX BY
	|	Partner,
	|	FilterByPartnerSegmentIsUsed
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	DimensionAccounting_1.Organization AS Organization,
	|	DimensionAccounting_1.Partner AS Partner,
	|	DimensionAccounting_1.Counterparty AS Counterparty,
	|	DimensionAccounting_1.Contract AS Contract,
	|	DimensionAccounting_1.LineOfBusiness AS LineOfBusinessOfAnalytics,
	|	DimensionAccounting_1.DimensionKey AS DimensionKey
	|INTO TT_AccountingDimensionByPartners
	|FROM
	|	InformationRegister.AccountingDimensionByPartners AS DimensionAccounting_1
	|WHERE
	|		DimensionAccounting_1.Partner <> VALUE(Catalog.Partners.OurEnterprise)
	|{WHERE
	|		DimensionAccounting_1.Organization.* AS Organization,
	|		DimensionAccounting_1.Partner.* AS Partner,
	|		DimensionAccounting_1.Counterparty.* AS Counterparty,
	|		DimensionAccounting_1.Contract.* AS Contract,
	|		(DimensionAccounting_1.Partner IN
	|				(SELECT
	|					SelectionByPartnerSegment.Partner
	|				FROM
	|					SelectionByPartnerSegment
	|				WHERE
	|					SelectionByPartnerSegment.FilterByPartnerSegmentIsUsed = &FilterByPartnerSegmentIsUsed))}
	|INDEX BY
	|	DimensionKey
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	Companies.Ref AS Organization,
	|	CurrencyExchangeRate.Currency AS Currency,
	|	CASE &ReportData
	|		WHEN 0
	|			THEN 1
	|		WHEN 2
	|			THEN ISNULL(CurrencyExchangeRate.CourseNumerator, 1) * ISNULL(ManSExchangeRate.CourseDenominator, 1) / (ISNULL(CurrencyExchangeRate.CourseDenominator, 1) * ISNULL(ManSExchangeRate.CourseNumerator, 1))
	|		ELSE ISNULL(CurrencyExchangeRate.CourseNumerator, 1) / ISNULL(CurrencyExchangeRate.CourseDenominator, 1)
	|	END AS ZoomRatio
	|INTO ExchangeRates
	|FROM
	|	Catalog.Companies AS Companies
	|		LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast({(&ReportDate)}) AS CurrencyExchangeRate
	|			ON Companies.LocalAccountingCurrency = CurrencyExchangeRate.BaseCurrency
	|		LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast({(&ReportDate)}, Currency = &ManagementAccountingCurrency) AS ManSExchangeRate
	|			ON Companies.LocalAccountingCurrency = ManSExchangeRate.BaseCurrency
	|{WHERE
	|	Companies.Ref.* AS Organization}
	|
	|INDEX BY
	|	Organization,
	|	Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	DimensionAccounting_1.Organization AS Organization,
	|	DimensionAccounting_1.Partner AS Partner,
	|	DimensionAccounting_1.Counterparty AS Counterparty,
	|	DimensionAccounting_1.Contract AS Contract,
	|	CASE WHEN NOT CalculationsByTerms.ARAPObject.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness
	|			THEN DimensionAccounting_1.LineOfBusinessOfAnalytics
	|			ELSE CalculationsByTerms.ARAPObject.LineOfBusiness
	|	END AS LineOfBusiness,
	|	CalculationsByTerms.ARAPObject AS ARAPObject,
	|	CASE &ReportData
	|		WHEN 0
	|			THEN CalculationsByTerms.Currency
	|		WHEN 2
	|			THEN &ManagementAccountingCurrency
	|		ELSE DimensionAccounting_1.Organization.LocalAccountingCurrency
	|	END AS Currency,
	|	CalculationsByTerms.ARAPDocument AS ARAPDocument,
	|	CalculationsByTerms.PlannedRepaymentDate AS PlannedRepaymentDate,
	|	CalculationsByTerms.OccurrenceDate AS OccurrenceDate,
	|	CASE &ReportData
	|		WHEN 0
	|			THEN CalculationsByTerms.PrepaymentBalance
	|		WHEN 2
	|			THEN CalculationsByTerms.PrepaymentManBalance
	|		ELSE CalculationsByTerms.PrepaymentLocalBalance
	|	END AS AccountsPayableOfCompany,
	|	CASE
	|		WHEN CalculationsByTerms.PlannedRepaymentDate < BEGINOFPERIOD(&ReportDate, DAY)
	|				AND CalculationsByTerms.PlannedRepaymentDate > DATETIME(1, 1, 1)
	|			THEN CASE &ReportData
	|					WHEN 0
	|						THEN CalculationsByTerms.PrepaymentBalance
	|					WHEN 2
	|						THEN CalculationsByTerms.PrepaymentManBalance
	|					ELSE CalculationsByTerms.PrepaymentLocalBalance
	|				END
	|		ELSE 0
	|	END AS OurDebtOverdue,
	|	CASE
	|		WHEN CalculationsByTerms.PlannedRepaymentDate = DATETIME(1, 1, 1)
	|			THEN CASE &ReportData
	|					WHEN 0
	|						THEN CalculationsByTerms.PrepaymentBalance
	|					WHEN 2
	|						THEN CalculationsByTerms.PrepaymentManBalance
	|					ELSE CalculationsByTerms.PrepaymentLocalBalance
	|				END
	|		ELSE 0
	|	END AS OurDebtIsNotControlled,
	|	CASE &ReportData
	|		WHEN 0
	|			THEN CalculationsByTerms.DebtBalance
	|		WHEN 2
	|			THEN CalculationsByTerms.ARAPManBalance
	|		ELSE CalculationsByTerms.DebtLocalBalance
	|	END AS CustomerAccountsReceivable,
	|	CASE
	|		WHEN CalculationsByTerms.PlannedRepaymentDate < BEGINOFPERIOD(&ReportDate, DAY)
	|			THEN CASE &ReportData
	|					WHEN 0
	|						THEN CalculationsByTerms.DebtBalance
	|					WHEN 2
	|						THEN CalculationsByTerms.ARAPManBalance
	|					ELSE CalculationsByTerms.DebtLocalBalance
	|				END
	|		ELSE 0
	|	END AS OverdueCustomerDebt,
	|	0 AS ToShip
	|INTO TableOfArrears
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates.Balance(&DateOfReportBorder,
	|		AccountingDimensionByPartners IN
	|				(SELECT
	|					TT_AccountingDimensionByPartners.DimensionKey
	|				FROM
	|					TT_AccountingDimensionByPartners)) AS CalculationsByTerms
	|		INNER JOIN TT_AccountingDimensionByPartners AS DimensionAccounting_1
	|			ON CalculationsByTerms.AccountingDimensionByPartners = DimensionAccounting_1.DimensionKey
	|WHERE
	|	(&IncludeDebt = 0
	|			OR &IncludeDebt = 1)
	|
	|UNION ALL
	|
	|SELECT
	|	DimensionAccounting_1.Organization,
	|	DimensionAccounting_1.Partner,
	|	DimensionAccounting_1.Counterparty,
	|	DimensionAccounting_1.Contract,
	|	CASE WHEN NOT PaymentPlanCalculations.ARAPObject.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness
	|		THEN DimensionAccounting_1.LineOfBusinessOfAnalytics
	|		ELSE PaymentPlanCalculations.ARAPObject.LineOfBusiness
	|	END,
	|	PaymentPlanCalculations.ARAPObject,
	|	CASE &ReportData
	|		WHEN 0
	|			THEN PaymentPlanCalculations.Currency
	|		WHEN 2
	|			THEN &ManagementAccountingCurrency
	|		ELSE DimensionAccounting_1.Organization.LocalAccountingCurrency
	|	END,
	|	PaymentPlanCalculations.DocumentPlan,
	|	PaymentPlanCalculations.PlannedRepaymentDate,
	|	PaymentPlanCalculations.OccurrenceDate,
	|	0,
	|	0,
	|	0,
	|	PaymentPlanCalculations.AmountDueBalance * CurrencyExchangeRate.ZoomRatio,
	|	CASE
	|		WHEN PaymentPlanCalculations.PlannedRepaymentDate < BEGINOFPERIOD(&ReportDate, DAY)
	|			THEN PaymentPlanCalculations.AmountDueBalance * CurrencyExchangeRate.ZoomRatio
	|		ELSE 0
	|	END,
	|	0
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingCashFlowPlan.Balance(&DateOfReportBorder,
	|		AccountingDimensionByPartners IN
	|				(SELECT
	|					TT_AccountingDimensionByPartners.DimensionKey
	|				FROM
	|					TT_AccountingDimensionByPartners)
	|		AND VALUETYPE(DocumentPlan) IN (&TypesOfPlanDocuments)) AS PaymentPlanCalculations
	|		INNER JOIN TT_AccountingDimensionByPartners AS DimensionAccounting_1
	|			ON PaymentPlanCalculations.AccountingDimensionByPartners = DimensionAccounting_1.DimensionKey
	|		LEFT JOIN ExchangeRates AS CurrencyExchangeRate
	|			ON (CurrencyExchangeRate.Currency = PaymentPlanCalculations.Currency)
	|			AND (CurrencyExchangeRate.Organization = DimensionAccounting_1.Organization)
	|WHERE
	|	(&IncludeDebt = 0
	|			OR &IncludeDebt = 2)
	|	AND &IncludePaymentPlan
	|
	|UNION ALL
	|
	|SELECT
	|	DimensionAccounting_1.Organization,
	|	DimensionAccounting_1.Partner,
	|	DimensionAccounting_1.Counterparty,
	|	DimensionAccounting_1.Contract,
	|	CASE WHEN NOT CalculationsShipmentPlan.ARAPObject.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness
	|		THEN DimensionAccounting_1.LineOfBusinessOfAnalytics
	|		ELSE CalculationsShipmentPlan.ARAPObject.LineOfBusiness
	|	END,
	|	CalculationsShipmentPlan.ARAPObject,
	|	CASE &ReportData
	|		WHEN 0
	|			THEN CalculationsShipmentPlan.Currency
	|		WHEN 2
	|			THEN &ManagementAccountingCurrency
	|		ELSE DimensionAccounting_1.Organization.LocalAccountingCurrency
	|	END,
	|	CalculationsShipmentPlan.DocumentPlan,
	|	CalculationsShipmentPlan.PlannedRepaymentDate,
	|	CalculationsShipmentPlan.OccurrenceDate,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	CalculationsShipmentPlan.SumBalance * CurrencyExchangeRate.ZoomRatio
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingPlannedShipments.Balance(&DateOfReportBorder, NOT UnallocatedAdvancePayment
	|		AND AccountingDimensionByPartners IN
	|				(SELECT
	|					TT_AccountingDimensionByPartners.DimensionKey
	|				FROM
	|					TT_AccountingDimensionByPartners)) AS CalculationsShipmentPlan
	|		INNER JOIN TT_AccountingDimensionByPartners AS DimensionAccounting_1
	|			ON CalculationsShipmentPlan.AccountingDimensionByPartners = DimensionAccounting_1.DimensionKey
	|		LEFT JOIN ExchangeRates AS CurrencyExchangeRate
	|			ON (CurrencyExchangeRate.Currency = CalculationsShipmentPlan.Currency)
	|				AND (CurrencyExchangeRate.Organization = DimensionAccounting_1.Organization)
	|WHERE
	|	(&IncludeDebt = 0
	|			OR &IncludeDebt = 2)
	|	AND &IncludeShippingPlan
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	TableOfArrears.PlannedRepaymentDate AS StartDate,
	|	WorkSchedules.Date AS EndDate,
	|	CASE
	|		WHEN WorkSchedules.DayKind = VALUE(Enum.BusinessCalendarDaysKinds.Work)
	|				OR WorkSchedules.DayKind = VALUE(Enum.BusinessCalendarDaysKinds.Preholiday)
	|			THEN 1
	|		ELSE 0
	|	END AS WorkingDay
	|INTO Schedules
	|FROM
	|	TableOfArrears AS TableOfArrears
	|		LEFT JOIN InformationRegister.BusinessCalendarData AS WorkSchedules
	|		ON (WorkSchedules.BusinessCalendar = &Calendar)
	|WHERE
	|	WorkSchedules.Date BETWEEN TableOfArrears.PlannedRepaymentDate AND &ReportDate
	|	AND TableOfArrears.PlannedRepaymentDate <> DATETIME(1, 1, 1)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.StartDate AS StartDate,
	|	NestedQuery.EndDate AS EndDate,
	|	ISNULL(SUM(Schedules.WorkingDay), 0) AS DaysCount
	|INTO DateDifferences
	|FROM
	|	Schedules AS NestedQuery
	|		LEFT JOIN Schedules AS Schedules
	|		ON NestedQuery.StartDate = Schedules.StartDate
	|			AND NestedQuery.EndDate > Schedules.EndDate
	|WHERE
	|	NestedQuery.EndDate = BEGINOFPERIOD(&ReportDate, DAY)
	|
	|GROUP BY
	|	NestedQuery.StartDate,
	|	NestedQuery.EndDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	CAST(&LineMutualSettlementsState AS STRING(150)) AS GroupingEverything,
	|	TableOfArrears.Organization                        AS Organization,
	|	TableOfArrears.Partner                            AS Partner,
	|	TableOfArrears.Counterparty                         AS Counterparty,
	|	TableOfArrears.Contract                            AS Contract,
	|	TableOfArrears.LineOfBusiness            AS LineOfBusiness,
	|	TableOfArrears.ARAPObject                     AS ARAPObject,
	|	TableOfArrears.Currency                             AS Currency,
	|	TableOfArrears.ARAPDocument                  AS ARAPDocument,
	|
	|	TableOfArrears.PlannedRepaymentDate             AS PlannedRepaymentDate,
	|	TableOfArrears.OccurrenceDate                  AS OccurrenceDate,
	|
	|	SUM(TableOfArrears.AccountsPayableOfCompany)                     AS AccountsPayableOfCompany,
	|	SUM(TableOfArrears.OurDebtOverdue)           AS OurDebtOverdue,
	|	SUM(TableOfArrears.OurDebtIsNotControlled)     AS OurDebtIsNotControlled,
	|	SUM(TableOfArrears.CustomerAccountsReceivable)                 AS CustomerAccountsReceivable,
	|	SUM(TableOfArrears.OverdueCustomerDebt)       AS OverdueCustomerDebt,
	|	SUM(TableOfArrears.ToShip)                   AS ToShip,
	|
	|	MAX(CASE
	|		WHEN NOT DateDifferences.DaysCount IS NULL
	|			THEN CASE
	|					WHEN DateDifferences.DaysCount > 0
	|						AND TableOfArrears.AccountsPayableOfCompany > 0
	|						THEN DateDifferences.DaysCount
	|					ELSE 0
	|				END
	|		ELSE CASE
	|				WHEN TableOfArrears.AccountsPayableOfCompany = 0
	|						OR TableOfArrears.PlannedRepaymentDate = DATETIME(1, 1, 1)
	|					THEN 0
	|				ELSE CASE
	|						WHEN DATEDIFF(TableOfArrears.PlannedRepaymentDate, &ReportDate, DAY) > 0
	|							THEN DATEDIFF(TableOfArrears.PlannedRepaymentDate, &ReportDate, DAY)
	|						ELSE 0
	|					END
	|			END
	|	END) AS DaysCount,
	|
	|	CASE 
	|		WHEN TableOfArrears.PlannedRepaymentDate = DATETIME(1, 1, 1)
	|			THEN CAST(&DebtLineIsNotControlled AS STRING(150))
	|		ELSE ISNULL(Intervals.IntervalName, CAST(&LineDebtIsNotOverdue AS STRING(150))) 
	|	END AS IntervalName,
	|	CASE 
	|		WHEN TableOfArrears.PlannedRepaymentDate = DATETIME(1, 1, 1)
	|			THEN -1
	|		ELSE ISNULL(Intervals.LineNumber, 0)
	|	END AS IntervalNumber,
	|	CASE 
	|		WHEN TableOfArrears.PlannedRepaymentDate = DATETIME(1, 1, 1)
	|			THEN -1
	|		ELSE ISNULL(Intervals.LowerBoundOfInterval, 0)
	|	END AS LowerBoundOfInterval
	|INTO IntervalArrears
	|FROM
	|	TableOfArrears AS TableOfArrears
	|		{LEFT JOIN DateDifferences AS DateDifferences
	|		ON (DateDifferences.StartDate = TableOfArrears.PlannedRepaymentDate)
	|		LEFT JOIN Catalog.TimeBucketsForAgingAnalysis.Intervals AS Intervals
	|		ON (Intervals.Ref = &DebtClassificationOption)
	|			AND (CASE
	|				WHEN NOT DateDifferences.DaysCount IS NULL
	|					THEN CASE
	|							WHEN DateDifferences.DaysCount > 0
	|								AND TableOfArrears.AccountsPayableOfCompany > 0
	|								THEN DateDifferences.DaysCount
	|							ELSE 0
	|						END
	|				ELSE CASE
	|						WHEN TableOfArrears.AccountsPayableOfCompany = 0
	|								OR TableOfArrears.PlannedRepaymentDate = DATETIME(1, 1, 1)
	|							THEN 0
	|						ELSE CASE
	|								WHEN DATEDIFF(TableOfArrears.PlannedRepaymentDate, &ReportDate, DAY) > 0
	|									THEN DATEDIFF(TableOfArrears.PlannedRepaymentDate, &ReportDate, DAY)
	|								ELSE 0
	|							END
	|					END
	|			END BETWEEN Intervals.LowerBoundOfInterval AND Intervals.UpperBoundOfInterval)}
	|GROUP BY
	|	TableOfArrears.Organization,
	|	TableOfArrears.Partner,
	|	TableOfArrears.Counterparty,
	|	TableOfArrears.Contract,
	|	TableOfArrears.LineOfBusiness,
	|	TableOfArrears.ARAPObject,
	|	TableOfArrears.Currency,
	|	TableOfArrears.ARAPDocument,
	|	TableOfArrears.PlannedRepaymentDate,
	|	TableOfArrears.OccurrenceDate,
	|	Intervals.IntervalName,
	|	Intervals.LineNumber,
	|	Intervals.LowerBoundOfInterval
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	Table.GroupingEverything                      AS GroupingEverything,
	|	Table.Organization                           AS Organization,
	|	Table.Partner                               AS Partner,
	|	Table.Counterparty                            AS Counterparty,
	|	Table.Contract                               AS Contract,
	|	Table.LineOfBusiness               AS LineOfBusiness,
	|	Table.ARAPObject                        AS ARAPObject,
	|	Table.Currency                                AS Currency,
	|	Table.ARAPDocument                     AS ARAPDocument,
	|
	|	Table.PlannedRepaymentDate                AS PlannedRepaymentDate,
	|	Table.OccurrenceDate                     AS OccurrenceDate,
	|
	|	Table.AccountsPayableOfCompany                               AS AccountsPayableOfCompany,
	|	Table.OurDebtOverdue                     AS OurDebtOverdue,
	|	Table.OurDebtIsNotControlled               AS OurDebtIsNotControlled,
	|	Table.CustomerAccountsReceivable                           AS CustomerAccountsReceivable,
	|	Table.OverdueCustomerDebt                 AS OverdueCustomerDebt,
	|	Table.ToShip                             AS ToShip,
	|
	|	Table.DaysCount                        AS DaysCount,
	|
	|	Table.IntervalName                 AS IntervalName,
	|	Table.IntervalNumber                        AS IntervalNumber,
	|	Table.LowerBoundOfInterval                AS LowerBoundOfInterval
	|{SELECT
	|	GroupingEverything,
	|	Organization.*,
	|	Partner.*,
	|	Counterparty.*,
	|	Contract.*,
	|	LineOfBusiness.*,
	|	ARAPObject.*,
	|	Currency.*,
	|	ARAPDocument.*,
	|	PlannedRepaymentDate,
	|	OccurrenceDate,
	|	AccountsPayableOfCompany,
	|	OurDebtOverdue,
	|	OurDebtIsNotControlled,
	|	CustomerAccountsReceivable,
	|	OverdueCustomerDebt,
	|	ToShip,
	|	DaysCount,
	|	IntervalName,
	|	IntervalNumber,
	|	LowerBoundOfInterval}
	|FROM IntervalArrears AS Table
	|{WHERE
	|	GroupingEverything          AS GroupingEverything,
	|	Organization.*             AS Organization,
	|	Partner.*                 AS Partner,
	|	Counterparty.*              AS Counterparty,
	|	Contract.*                 AS Contract,
	|	LineOfBusiness.* AS LineOfBusiness,
	|	ARAPObject.*          AS ARAPObject,
	|	Currency.*                  AS Currency,
	|	ARAPDocument.*       AS ARAPDocument,
	|	
	|	PlannedRepaymentDate    AS PlannedRepaymentDate,
	|	OccurrenceDate         AS OccurrenceDate,
	|	
	|	AccountsPayableOfCompany                   AS AccountsPayableOfCompany,
	|	OurDebtOverdue         AS OurDebtOverdue,
	|	OurDebtIsNotControlled   AS OurDebtIsNotControlled,
	|	CustomerAccountsReceivable               AS CustomerAccountsReceivable,
	|	OverdueCustomerDebt     AS OverdueCustomerDebt,
	|	ToShip                 AS ToShip,
	|	DaysCount            AS DaysCount,
	|	
	|	IntervalName     AS IntervalName,
	|	IntervalNumber            AS IntervalNumber,
	|	LowerBoundOfInterval    AS LowerBoundOfInterval}
	|";

	QueryText = StrReplace(QueryText,"&TypesOfPlanDocuments", GetPlanDocumentTypes());
	
	Return QueryText;
EndFunction

Function GetPlanDocumentTypes()
	
	TextOfDocumentTypes = ""; 
	
	TextOfDocumentTypes = TextOfDocumentTypes + "TYPE(Document.MaterialProviderOrder2_5), ";
	TextOfDocumentTypes = TextOfDocumentTypes + "TYPE(Document.SalesOrder), ";
	TextOfDocumentTypes = TextOfDocumentTypes + "TYPE(Document.RequestForReturnOfGoodsFromCustomer), ";
	TextOfDocumentTypes = TextOfDocumentTypes + "TYPE(Document.ContractSchedule)";
	
	Return TextOfDocumentTypes;
EndFunction

Procedure SetCalendar(Var_SettingsComposer, UserSettingsModified)
	
	ParameterDebtClassificationOption = DataCompositionClientServer.GetParameter(Var_SettingsComposer, "DebtClassificationOption");
	DebtClassificationOption = ParameterDebtClassificationOption.Value;
	Calendar = Catalogs.BusinessCalendars.EmptyRef();
	If TypeOf(DebtClassificationOption) = Type("CatalogRef.TimeBucketsForAgingAnalysis")
		And ValueIsFilled(DebtClassificationOption) Then
			Calendar = Common.ObjectAttributeValue(DebtClassificationOption, "Calendar");
	EndIf;
	
	DataCompositionClientServer.SetParameter(Var_SettingsComposer, "Calendar", Calendar);
	

EndProcedure

Procedure FindSelectedFieldsRecursively(ItemsCollection, ItemArray)

	For Each Item In ItemsCollection Do
		
		If TypeOf(Item) = Type("DataCompositionSelectedField") Then
			If Item.Use Then
				ItemArray.Add(Item);
			EndIf;
		Else
			FindSelectedFieldsRecursively(Item.Items, ItemArray);
		EndIf;
		
	EndDo;

EndProcedure

#EndRegion

#EndIf