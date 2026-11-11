#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

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

#EndRegion

#Region EventHandlers

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
	FormSettingsComposer = ThisForm.Report.SettingsComposer;
	
	If Parameters.Property("CommandParameter") Then
		
		ThisForm.ReportSettings.OptionSelectionAllowed = False;
		
		GenerateReportParameters(Parameters.CommandParameter, ThisForm, Parameters);
			
	EndIf;
	
	ParametersForm = ThisForm.ParametersForm;
	
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

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	UserSettingsModified = False;
	
	SetRequiredSettings(SettingsComposer, UserSettingsModified);
	
	// Generate a report
	ReportSettings = SettingsComposer.GetSettings();
	
	DataCompositionSchema.DataSets.DataSet.Query = QueryText();
	
	DataCompositionClientServer.SetParameter(ReportSettings, "TextOpeningBalance", NStr("vi = 'Số dư đầu';
																						|ru = 'Начальный остаток';
																						|en = 'Opening balance'; fa = 'مانده ابتدای دوره';
																						|it = 'Saldo iniziale';
																						|pl = 'Saldo początkowe';
																						|tr = 'Açılış bakiyesi'"), True);
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	
	//A warning about the unfulfilled distribution of mutual settlements.
	ARAPAccountingServer.DisplayUpdateWarning(ResultDocument);
	
	OutputProcessor.Output(CompositionProcessor);
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure SetRequiredSettings(Var_SettingsComposer, UserSettingsModified)
	
	SegmentsServer.EnableSelectionByVSKDPartnerSegment(Var_SettingsComposer);
	
EndProcedure

Procedure ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer)
	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(FormSettingsComposer, "Counterparty");
	EndIf;
EndProcedure

Function QueryText()
	
	QueryText = "
	|SELECT ALLOWED DISTINCT
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
	|SELECT ALLOWED
	|	Companies.Ref AS Organization,
	|	CurrencyExchangeRate.Currency AS Currency,
	|	CASE &ReportData
	|		WHEN 4
	|			THEN 1
	|		WHEN 2
	|			THEN ISNULL(CurrencyExchangeRate.CourseNumerator, 1) * ISNULL(ManSExchangeRate.CourseDenominator, 1) / (ISNULL(CurrencyExchangeRate.CourseDenominator, 1) * ISNULL(ManSExchangeRate.CourseNumerator, 1))
	|		ELSE ISNULL(CurrencyExchangeRate.CourseNumerator, 1) / ISNULL(CurrencyExchangeRate.CourseDenominator, 1)
	|	END AS ZoomRatio
	|INTO ExchangeRates
	|FROM
	|	Catalog.Companies AS Companies
	|		LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast({(&EndOfPeriod)}) AS CurrencyExchangeRate
	|			ON Companies.LocalAccountingCurrency = CurrencyExchangeRate.BaseCurrency
	|		LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast({(&EndOfPeriod)}, Currency = &ManagementAccountingCurrency) AS ManSExchangeRate
	|			ON Companies.LocalAccountingCurrency = ManSExchangeRate.BaseCurrency
	|{WHERE
	|	Companies.Ref.* AS Organization}
	|
	|INDEX BY
	|	Organization,
	|	Currency
	|;
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
	|SELECT ALLOWED
	|	Calculations.Organization                 AS Organization,
	|	Calculations.Partner                     AS Partner,
	|	Calculations.Counterparty                  AS Counterparty,
	|	Calculations.Contract                     AS Contract,
	|	Calculations.LineOfBusiness     AS LineOfBusiness,
	|	Calculations.ARAPObject              AS ARAPObject,
	|	Calculations.Currency                      AS Currency,
	|	Calculations.ARAPDocument           AS ARAPDocument,
	|	Calculations.DocumentRecorder         AS DocumentRecorder,
	|	Calculations.OccurrenceDate           AS OccurrenceDate,
	|	Calculations.PlannedRepaymentDate      AS PlannedRepaymentDate,
	|	Calculations.ReversingEntry                      AS ReversingEntry,
	|	BEGINOFPERIOD(Calculations.Period, DAY) AS Period,
	|	MAX(Calculations.OperationProcedure)   AS OperationProcedure,
	|	
	|	SUM(Calculations.DebtOfSupplier)       AS DebtOfSupplier,
	|	SUM(Calculations.AccountsPayableOfCompany)              AS AccountsPayableOfCompany,
	|	//  The planned payment is summed up in the settlement currency, as it contains data on planned and actual settlements
	|	SUM(Calculations.SheduledPayment)       AS SheduledPayment,
	|	SUM(Calculations.ScheduledSupply)     AS ScheduledSupply,
	|	SUM(Calculations.WriteOffRevaluation)   AS WriteOffRevaluation,
	|	SUM(Calculations.Ordered)             AS Ordered,
	|	SUM(Calculations.Paid)             AS Paid,
	|	SUM(Calculations.Supplied_2)           AS Supplied_2,
	|	SUM(Calculations.SetOff)              AS SetOff
	|INTO TTCalculations
	|FROM (
	|	SELECT
	|		DimensionAccounting_1.Organization                                     AS Organization,
	|		DimensionAccounting_1.Partner                                         AS Partner,
	|		DimensionAccounting_1.Counterparty                                      AS Counterparty,
	|		DimensionAccounting_1.Contract                                         AS Contract,
	|		CASE WHEN NOT CalculationsByTermsBalance.ARAPObject.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness
	|			THEN DimensionAccounting_1.LineOfBusinessOfAnalytics
	|			ELSE CalculationsByTermsBalance.ARAPObject.LineOfBusiness
	|		END                                                          AS LineOfBusiness,
	|		CalculationsByTermsBalance.ARAPObject                          AS ARAPObject,
	|		CASE &ReportData
	|			WHEN 4
	|				THEN CalculationsByTermsBalance.Currency
	|			WHEN 2
	|				THEN &ManagementAccountingCurrency
	|			ELSE DimensionAccounting_1.Organization.LocalAccountingCurrency
	|		END                                                          AS Currency,
	|		CalculationsByTermsBalance.ARAPDocument                       AS ARAPDocument,
	|		CAST(&TextOpeningBalance AS STRING(17))                AS DocumentRecorder,
	|		CalculationsByTermsBalance.OccurrenceDate                       AS OccurrenceDate,
	|		CalculationsByTermsBalance.PlannedRepaymentDate                  AS PlannedRepaymentDate,
	|		&BeginOfPeriod                                                 AS Period,
	|		""""                                                           AS OperationProcedure,
	|		FALSE                                                           AS ReversingEntry,
	|		
	|		0                                                              AS Ordered,
	|		0                                                              AS Supplied_2,
	|		0                                                              AS SetOff,
	|		0                                                              AS Paid,
	|		0                                                              AS WriteOffRevaluation,
	|		CASE &ReportData
	|			WHEN 4
	|				THEN CalculationsByTermsBalance.PrepaymentOpeningBalance
	|			WHEN 2
	|				THEN CalculationsByTermsBalance.PrepaymentManOpeningBalance
	|			ELSE CalculationsByTermsBalance.PrepaymentLocalOpeningBalance
	|		END                                                          AS DebtOfSupplier,
	|		CASE &ReportData
	|			WHEN 4
	|				THEN CalculationsByTermsBalance.DebtOpeningBalance
	|			WHEN 2
	|				THEN CalculationsByTermsBalance.ARAPManOpeningBalance
	|			ELSE CalculationsByTermsBalance.DebtLocalOpeningBalance
	|		END                                                          AS AccountsPayableOfCompany,
	|		CASE &ReportData
	|			WHEN 4
	|				THEN CalculationsByTermsBalance.DebtOpeningBalance
	|			WHEN 2
	|				THEN CalculationsByTermsBalance.ARAPManOpeningBalance
	|			ELSE CalculationsByTermsBalance.DebtLocalOpeningBalance
	|		END
	|		- CASE &ReportData
	|			WHEN 4
	|				THEN CalculationsByTermsBalance.PrepaymentOpeningBalance
	|			WHEN 2
	|				THEN CalculationsByTermsBalance.PrepaymentManOpeningBalance
	|			ELSE CalculationsByTermsBalance.PrepaymentLocalOpeningBalance
	|		END AS SheduledPayment,
	|		0                                                              AS ScheduledSupply
	|	FROM
	|		AccumulationRegister.VendorsARAPAccountingByDueDates.BalanceAndTurnovers({&BeginOfPeriod},{&EndOfPeriod}, , ,
	|			AccountingDimensionByPartners IN
	|				(SELECT
	|					TT_AccountingDimensionByPartners.DimensionKey
	|				FROM
	|					TT_AccountingDimensionByPartners)) AS CalculationsByTermsBalance
	|			INNER JOIN TT_AccountingDimensionByPartners AS DimensionAccounting_1
	|				ON CalculationsByTermsBalance.AccountingDimensionByPartners = DimensionAccounting_1.DimensionKey
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DimensionAccounting_1.Organization                      AS Organization,
	|		DimensionAccounting_1.Partner                          AS Partner,
	|		DimensionAccounting_1.Counterparty                       AS Counterparty,
	|		DimensionAccounting_1.Contract                          AS Contract,
	|		CASE WHEN NOT PaymentPlanCalculationsBalance.ARAPObject.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness
	|			THEN DimensionAccounting_1.LineOfBusinessOfAnalytics
	|			ELSE PaymentPlanCalculationsBalance.ARAPObject.LineOfBusiness
	|		END                                           AS LineOfBusiness,
	|		PaymentPlanCalculationsBalance.ARAPObject          AS ARAPObject,
	|		CASE &ReportData
	|			WHEN 4
	|				THEN PaymentPlanCalculationsBalance.Currency
	|			WHEN 2
	|				THEN &ManagementAccountingCurrency
	|			ELSE DimensionAccounting_1.Organization.LocalAccountingCurrency
	|		END                                           AS Currency,
	|		PaymentPlanCalculationsBalance.DocumentPlan            AS DocumentPlan,
	|		CAST(&TextOpeningBalance AS STRING(17)) AS DocumentRecorder,
	|		PaymentPlanCalculationsBalance.OccurrenceDate       AS OccurrenceDate,
	|		PaymentPlanCalculationsBalance.PlannedRepaymentDate  AS PlannedRepaymentDate,
	|		&BeginOfPeriod                                  AS Period,
	|		""""                                            AS OperationProcedure,
	|		FALSE                                                           AS ReversingEntry,
	|		
	|		0                                               AS Ordered,
	|		0                                               AS Supplied_2,
	|		0                                               AS SetOff,
	|		0                                               AS Paid,
	|		0                                               AS WriteOffRevaluation,
	|		
	|		0                                               AS DebtOfSupplier,
	|		0                                               AS AccountsPayableOfCompany,
	|		(PaymentPlanCalculationsBalance.AmountDueOpeningBalance)
	|		* CurrencyExchangeRate.ZoomRatio                        AS SheduledPayment,
	|		0                                               AS ScheduledSupply
	|	FROM
	|		AccumulationRegister.VendorsARAPAccountingCashFlowPlan.BalanceAndTurnovers({&BeginOfPeriod},{&EndOfPeriod},,,NOT UnallocatedAdvancePayment
	|			AND AccountingDimensionByPartners IN
	|				(SELECT
	|					TT_AccountingDimensionByPartners.DimensionKey
	|				FROM
	|					TT_AccountingDimensionByPartners)) AS PaymentPlanCalculationsBalance
	|			INNER JOIN TT_AccountingDimensionByPartners AS DimensionAccounting_1
	|				ON PaymentPlanCalculationsBalance.AccountingDimensionByPartners = DimensionAccounting_1.DimensionKey
	|			LEFT JOIN ExchangeRates AS CurrencyExchangeRate
	|				ON (CurrencyExchangeRate.Currency = PaymentPlanCalculationsBalance.Currency)
	|					AND (CurrencyExchangeRate.Organization = DimensionAccounting_1.Organization)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DimensionAccounting_1.Organization                        AS Organization,
	|		DimensionAccounting_1.Partner                            AS Partner,
	|		DimensionAccounting_1.Counterparty                         AS Counterparty,
	|		DimensionAccounting_1.Contract                            AS Contract,
	|		CASE WHEN NOT CalculationsDeliveryPlanBalance.ARAPObject.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness
	|			THEN DimensionAccounting_1.LineOfBusinessOfAnalytics
	|			ELSE CalculationsDeliveryPlanBalance.ARAPObject.LineOfBusiness
	|		END                                             AS LineOfBusiness,
	|		CalculationsDeliveryPlanBalance.ARAPObject         AS ARAPObject,
	|		CASE &ReportData
	|			WHEN 4
	|				THEN CalculationsDeliveryPlanBalance.Currency
	|			WHEN 2
	|				THEN &ManagementAccountingCurrency
	|			ELSE DimensionAccounting_1.Organization.LocalAccountingCurrency
	|		END                                             AS Currency,
	|		CalculationsDeliveryPlanBalance.DocumentPlan           AS DocumentPlan,
	|		CAST(&TextOpeningBalance AS STRING(17))   AS DocumentRecorder,
	|		CalculationsDeliveryPlanBalance.OccurrenceDate      AS OccurrenceDate,
	|		CalculationsDeliveryPlanBalance.PlannedRepaymentDate AS PlannedRepaymentDate,
	|		&BeginOfPeriod                                    AS Period,
	|		""""                                              AS OperationProcedure,
	|		FALSE                                              AS ReversingEntry,
	|		
	|		0                                                 AS Ordered,
	|		0                                                 AS Supplied_2,
	|		0                                                 AS SetOff,
	|		0                                                 AS Paid,
	|		0                                                 AS WriteOffRevaluation,
	|		0                                                 AS DebtOfSupplier,
	|		0                                                 AS AccountsPayableOfCompany,
	|		0                                                 AS SheduledPayment,
	|		CalculationsDeliveryPlanBalance.SumOpeningBalance
	|			* CurrencyExchangeRate.ZoomRatio                      AS ScheduledSupply
	|	FROM
	|		AccumulationRegister.VendorsARAPAccountingPlannedDeliveries.BalanceAndTurnovers({&BeginOfPeriod},{&EndOfPeriod},,,NOT UnallocatedAdvancePayment
	|			AND AccountingDimensionByPartners IN
	|				(SELECT
	|					TT_AccountingDimensionByPartners.DimensionKey
	|				FROM
	|					TT_AccountingDimensionByPartners)) AS CalculationsDeliveryPlanBalance
	|			INNER JOIN TT_AccountingDimensionByPartners AS DimensionAccounting_1
	|				ON CalculationsDeliveryPlanBalance.AccountingDimensionByPartners = DimensionAccounting_1.DimensionKey
	|			LEFT JOIN ExchangeRates AS CurrencyExchangeRate
	|				ON (CurrencyExchangeRate.Currency = CalculationsDeliveryPlanBalance.Currency)
	|					AND (CurrencyExchangeRate.Organization = DimensionAccounting_1.Organization)
	|	WHERE
	|		NOT UnallocatedAdvancePayment
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DimensionAccounting_1.Organization                                     AS Organization,
	|		DimensionAccounting_1.Partner                                         AS Partner,
	|		DimensionAccounting_1.Counterparty                                      AS Counterparty,
	|		DimensionAccounting_1.Contract                                         AS Contract,
	|		CASE WHEN NOT CalculationsByTerms.ARAPObject.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness
	|			THEN DimensionAccounting_1.LineOfBusinessOfAnalytics
	|			ELSE CalculationsByTerms.ARAPObject.LineOfBusiness
	|		END                                                          AS LineOfBusiness,
	|		CalculationsByTerms.ARAPObject                                 AS ARAPObject,
	|		CASE &ReportData
	|			WHEN 4
	|				THEN CalculationsByTerms.Currency
	|			WHEN 2
	|				THEN &ManagementAccountingCurrency
	|			ELSE DimensionAccounting_1.Organization.LocalAccountingCurrency
	|		END                                                          AS Currency,
	|		CalculationsByTerms.ARAPDocument                              AS ARAPDocument,
	|		CalculationsByTerms.DocumentRecorder                            AS DocumentRecorder,
	|		CalculationsByTerms.OccurrenceDate                              AS OccurrenceDate,
	|		CalculationsByTerms.PlannedRepaymentDate                         AS PlannedRepaymentDate,
	|		CalculationsByTerms.Period                                         AS Period,
	|		CalculationsByTerms.OperationProcedure                                AS OperationProcedure,
	|		CalculationsByTerms.ReversingEntry                                         AS ReversingEntry,
	|		
	|		0                                                              AS Ordered,
	|		&SuppliedBySupplier                                         AS Supplied_2,
	|		&CreditedBySupplier                                            AS SetOff,
	|		&PaidToSupplier                                            AS Paid,
	|		&WriteOffRevaluation                                            AS WriteOffRevaluation,
	|		
	|		CASE WHEN CalculationsByTerms.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN
	|					CASE &ReportData
	|						WHEN 4
	|							THEN CalculationsByTerms.Prepayment
	|						WHEN 2
	|							THEN CalculationsByTerms.PrepaymentMan
	|						ELSE CalculationsByTerms.PrepaymentLocal
	|					END
	|			ELSE 
	|					- CASE &ReportData
	|						WHEN 4
	|							THEN CalculationsByTerms.Prepayment
	|						WHEN 2
	|							THEN CalculationsByTerms.PrepaymentMan
	|						ELSE CalculationsByTerms.PrepaymentLocal
	|					END
	|		END                                                          AS DebtOfSupplier,
	|		CASE WHEN CalculationsByTerms.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN
	|					CASE &ReportData
	|						WHEN 4
	|							THEN CalculationsByTerms.Debt
	|						WHEN 2
	|							THEN CalculationsByTerms.ARAPMan
	|						ELSE CalculationsByTerms.DebtLocal
	|					END
	|			ELSE
	|					- CASE &ReportData
	|						WHEN 4
	|							THEN CalculationsByTerms.Debt
	|						WHEN 2
	|							THEN CalculationsByTerms.ARAPMan
	|						ELSE CalculationsByTerms.DebtLocal
	|					END
	|		END                                                          AS AccountsPayableOfCompany,
	|		CASE WHEN CalculationsByTerms.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN
	|					CASE &ReportData
	|						WHEN 4
	|							THEN CalculationsByTerms.Debt
	|						WHEN 2
	|							THEN CalculationsByTerms.ARAPMan
	|						ELSE CalculationsByTerms.DebtLocal
	|					END
	|			ELSE
	|					- CASE &ReportData
	|						WHEN 4
	|							THEN CalculationsByTerms.Debt
	|						WHEN 2
	|							THEN CalculationsByTerms.ARAPMan
	|						ELSE CalculationsByTerms.DebtLocal
	|					END
	|		END
	|		- CASE WHEN CalculationsByTerms.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN
	|					CASE &ReportData
	|						WHEN 4
	|							THEN CalculationsByTerms.Prepayment
	|						WHEN 2
	|							THEN CalculationsByTerms.PrepaymentMan
	|						ELSE CalculationsByTerms.PrepaymentLocal
	|					END
	|			ELSE 
	|					- CASE &ReportData
	|						WHEN 4
	|							THEN CalculationsByTerms.Prepayment
	|						WHEN 2
	|							THEN CalculationsByTerms.PrepaymentMan
	|						ELSE CalculationsByTerms.PrepaymentLocal
	|			END
	|		END                                                          AS SheduledPayment,
	|		0                                                              AS ScheduledSupply
	|	FROM
	|		AccumulationRegister.VendorsARAPAccountingByDueDates AS CalculationsByTerms
	|			INNER JOIN TT_AccountingDimensionByPartners AS DimensionAccounting_1
	|				ON CalculationsByTerms.AccountingDimensionByPartners = DimensionAccounting_1.DimensionKey
	|	WHERE
	|		(CASE &ReportData
	|				WHEN 4
	|					THEN CalculationsByTerms.Debt
	|				WHEN 2
	|					THEN CalculationsByTerms.ARAPMan
	|				ELSE CalculationsByTerms.DebtLocal
	|			END <> 0
	|			OR CASE &ReportData
	|				WHEN 4
	|					THEN CalculationsByTerms.Prepayment
	|				WHEN 2
	|					THEN CalculationsByTerms.PrepaymentMan
	|				ELSE CalculationsByTerms.PrepaymentLocal
	|			END <> 0)
	|	{WHERE
	|		CalculationsByTerms.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod}
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DimensionAccounting_1.Organization               AS Organization,
	|		DimensionAccounting_1.Partner                   AS Partner,
	|		DimensionAccounting_1.Counterparty                AS Counterparty,
	|		DimensionAccounting_1.Contract                   AS Contract,
	|		CASE WHEN NOT PaymentPlanCalculations.ARAPObject.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness
	|			THEN DimensionAccounting_1.LineOfBusinessOfAnalytics
	|			ELSE PaymentPlanCalculations.ARAPObject.LineOfBusiness
	|		END                                    AS LineOfBusiness,
	|		PaymentPlanCalculations.ARAPObject          AS ARAPObject,
	|		CASE &ReportData
	|			WHEN 4
	|				THEN PaymentPlanCalculations.Currency
	|			WHEN 2
	|				THEN &ManagementAccountingCurrency
	|			ELSE DimensionAccounting_1.Organization.LocalAccountingCurrency
	|		END                                    AS Currency,
	|		PaymentPlanCalculations.DocumentPlan            AS DocumentPlan,
	|		PaymentPlanCalculations.DocumentRecorder     AS DocumentRecorder,
	|		PaymentPlanCalculations.OccurrenceDate       AS OccurrenceDate,
	|		PaymentPlanCalculations.PlannedRepaymentDate  AS PlannedRepaymentDate,
	|		MIN(PaymentPlanCalculations.Period)          AS Period,
	|		MIN(PaymentPlanCalculations.OperationProcedure) AS OperationProcedure,
	|		FALSE                                     AS ReversingEntry,
	|		
	|		0                                        AS Ordered,
	|		0                                        AS Supplied_2,
	|		0                                        AS SetOff,
	|		0                                        AS Paid,
	|		0                                        AS WriteOffRevaluation,
	|		
	|		0                                        AS DebtOfSupplier,
	|		0                                        AS AccountsPayableOfCompany,
	|		SUM(CASE WHEN PaymentPlanCalculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN PaymentPlanCalculations.AmountDue
	|			ELSE -PaymentPlanCalculations.AmountDue
	|		END * CurrencyExchangeRate.ZoomRatio)          AS SheduledPayment,
	|		0                                        AS ScheduledSupply
	|	FROM
	|		AccumulationRegister.VendorsARAPAccountingCashFlowPlan AS PaymentPlanCalculations
	|			INNER JOIN TT_AccountingDimensionByPartners AS DimensionAccounting_1
	|				ON PaymentPlanCalculations.AccountingDimensionByPartners = DimensionAccounting_1.DimensionKey
	|			LEFT JOIN ExchangeRates AS CurrencyExchangeRate
	|				ON (CurrencyExchangeRate.Currency = PaymentPlanCalculations.Currency)
	|					AND (CurrencyExchangeRate.Organization = DimensionAccounting_1.Organization)
	|	WHERE
	|		NOT PaymentPlanCalculations.UnallocatedAdvancePayment
	|	{WHERE
	|		PaymentPlanCalculations.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod}
	|
	|	GROUP BY
	|		DimensionAccounting_1.Organization,
	|		DimensionAccounting_1.Partner,
	|		DimensionAccounting_1.Counterparty,
	|		DimensionAccounting_1.Contract,
	|		CASE WHEN NOT PaymentPlanCalculations.ARAPObject.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness
	|			THEN DimensionAccounting_1.LineOfBusinessOfAnalytics
	|			ELSE PaymentPlanCalculations.ARAPObject.LineOfBusiness
	|		END,
	|		PaymentPlanCalculations.ARAPObject,
	|		CASE &ReportData
	|			WHEN 4
	|				THEN PaymentPlanCalculations.Currency
	|			WHEN 2
	|				THEN &ManagementAccountingCurrency
	|			ELSE DimensionAccounting_1.Organization.LocalAccountingCurrency
	|		END,
	|		PaymentPlanCalculations.DocumentPlan,
	|		PaymentPlanCalculations.DocumentRecorder,
	|		PaymentPlanCalculations.OccurrenceDate,
	|		PaymentPlanCalculations.PlannedRepaymentDate
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DimensionAccounting_1.Organization                  AS Organization,
	|		DimensionAccounting_1.Partner                      AS Partner,
	|		DimensionAccounting_1.Counterparty                   AS Counterparty,
	|		DimensionAccounting_1.Contract                      AS Contract,
	|		CASE WHEN NOT CalculationsDeliveryPlan.ARAPObject.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness
	|			THEN DimensionAccounting_1.LineOfBusinessOfAnalytics
	|			ELSE CalculationsDeliveryPlan.ARAPObject.LineOfBusiness
	|		END                                       AS LineOfBusiness,
	|		CalculationsDeliveryPlan.ARAPObject          AS ARAPObject,
	|		CASE &ReportData
	|			WHEN 4
	|				THEN CalculationsDeliveryPlan.Currency
	|			WHEN 2
	|				THEN &ManagementAccountingCurrency
	|			ELSE DimensionAccounting_1.Organization.LocalAccountingCurrency
	|		END                                       AS Currency,
	|		CalculationsDeliveryPlan.DocumentPlan            AS DocumentPlan,
	|		CalculationsDeliveryPlan.DocumentRecorder     AS DocumentRecorder,
	|		CalculationsDeliveryPlan.OccurrenceDate       AS OccurrenceDate,
	|		CalculationsDeliveryPlan.PlannedRepaymentDate  AS PlannedRepaymentDate,
	|		CalculationsDeliveryPlan.Period                  AS Period,
	|		CalculationsDeliveryPlan.OperationProcedure         AS OperationProcedure,
	|		FALSE                                     AS ReversingEntry,
	|		
	|		CASE WHEN CalculationsDeliveryPlan.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN CalculationsDeliveryPlan.Sum
	|			ELSE 0
	|		END * CurrencyExchangeRate.ZoomRatio              AS Ordered,
	|		0                                           AS Supplied_2,
	|		0                                           AS SetOff,
	|		0                                           AS Paid,
	|		0                                           AS WriteOffRevaluation,
	|		0                                           AS DebtOfSupplier,
	|		0                                           AS AccountsPayableOfCompany,
	|		0                                           AS SheduledPayment,
	|		CASE WHEN CalculationsDeliveryPlan.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN CalculationsDeliveryPlan.Sum
	|			ELSE -CalculationsDeliveryPlan.Sum
	|		END * CurrencyExchangeRate.ZoomRatio              AS ScheduledSupply
	|	FROM
	|		AccumulationRegister.VendorsARAPAccountingPlannedDeliveries AS CalculationsDeliveryPlan
	|			INNER JOIN TT_AccountingDimensionByPartners AS DimensionAccounting_1
	|				ON CalculationsDeliveryPlan.AccountingDimensionByPartners = DimensionAccounting_1.DimensionKey
	|			LEFT JOIN ExchangeRates AS CurrencyExchangeRate
	|				ON (CurrencyExchangeRate.Currency = CalculationsDeliveryPlan.Currency)
	|					AND (CurrencyExchangeRate.Organization = DimensionAccounting_1.Organization)
	|	WHERE
	|		NOT UnallocatedAdvancePayment
	|	{WHERE
	|		CalculationsDeliveryPlan.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod}) AS Calculations
	|
	|GROUP BY
	|	Calculations.Organization,
	|	Calculations.Partner,
	|	Calculations.Counterparty,
	|	Calculations.Contract,
	|	Calculations.LineOfBusiness,
	|	Calculations.ARAPObject,
	|	Calculations.Currency,
	|	Calculations.ARAPDocument,
	|	Calculations.DocumentRecorder,
	|	Calculations.OccurrenceDate,
	|	Calculations.PlannedRepaymentDate,
	|	Calculations.ReversingEntry,
	|	BEGINOFPERIOD(Calculations.Period, DAY)
	|;
	|
	|SELECT 
	|	Calculations.ARAPObject              AS ARAPObject,
	|	Calculations.DocumentRecorder         AS DocumentRecorder,
	|	Calculations.Organization                 AS Organization,
	|	Calculations.Period                      AS Period,
	|	
	|	CASE WHEN SUM(Calculations.Paid) = 0 
	|				AND SUM(Calculations.Supplied_2) = 0
	|				AND SUM(Calculations.WriteOffRevaluation) = 0
	|				AND SUM(Calculations.SetOff) = 0
	|		THEN
	|			//Routine of operations
	|			CASE WHEN SUM(Calculations.SheduledPayment) = 0 
	|					THEN SUM(Calculations.ScheduledSupply)
	|				ELSE SUM(Calculations.SheduledPayment)
	|			END
	|		ELSE 
	|			//Actual of operations
	|			CASE WHEN SUM(Calculations.Paid) > SUM(Calculations.Supplied_2) AND SUM(Calculations.Paid) > 0
	|					THEN SUM(Calculations.Paid)
	|				WHEN SUM(Calculations.Supplied_2) > SUM(Calculations.Paid) AND SUM(Calculations.Supplied_2) > 0
	|					THEN SUM(Calculations.Supplied_2)
	|				WHEN SUM(Calculations.Paid) < SUM(Calculations.Supplied_2) AND SUM(Calculations.Paid) < 0
	|					THEN SUM(Calculations.Paid)
	|				WHEN SUM(Calculations.Supplied_2) <= SUM(Calculations.Paid) AND SUM(Calculations.Supplied_2) < 0
	|					THEN SUM(Calculations.Supplied_2)
	|				// AZDN, the Registered Recording of the waybill by order
	|				WHEN SUM(Calculations.SetOff) <> 0
	|					THEN SUM(Calculations.SetOff)
	|				ELSE SUM(Calculations.WriteOffRevaluation)
	|			END
	|	END                               AS SumByDocument
	|
	|INTO TTAmountsAccordingToDocuments
	|FROM 
	|	TTCalculations AS Calculations
	|GROUP BY
	|	Calculations.ARAPObject,
	|	Calculations.DocumentRecorder,
	|	Calculations.Organization,
	|	Calculations.Period
	|;
	|SELECT ALLOWED
	|	Calculations.Organization                 AS Organization,
	|	Calculations.Partner                     AS Partner,
	|	Calculations.Counterparty                  AS Counterparty,
	|	Calculations.Contract                     AS Contract,
	|	Calculations.LineOfBusiness     AS LineOfBusiness,
	|	Calculations.ARAPObject              AS ARAPObject,
	|	Calculations.Currency                      AS Currency,
	|	Calculations.ARAPDocument           AS ARAPDocument,
	|	Calculations.DocumentRecorder         AS DocumentRecorder,
	|	Calculations.OccurrenceDate           AS OccurrenceDate,
	|	Calculations.PlannedRepaymentDate      AS PlannedRepaymentDate,
	|	Calculations.Period                      AS Period,
	|	Calculations.OperationProcedure             AS OperationProcedure,
	|	Calculations.ReversingEntry                      AS ReversingEntry,
	|	
	|	Calculations.DebtOfSupplier              AS DebtOfSupplier,
	|	Calculations.AccountsPayableOfCompany                     AS AccountsPayableOfCompany,
	|	Calculations.SheduledPayment              AS SheduledPayment,
	|	Calculations.ScheduledSupply            AS ScheduledSupply,
	|	
	|	Calculations.Ordered                    AS Ordered,
	|	Calculations.Paid                    AS Paid,
	|	Calculations.Supplied_2                  AS Supplied_2,
	|	Calculations.SetOff                     AS SetOff,
	|	Calculations.WriteOffRevaluation          AS WriteOffRevaluation,
	|	
	|	CASE WHEN Amounts.SumByDocument = 0 AND Calculations.DebtOfSupplier <> 0
	|			THEN Calculations.DebtOfSupplier
	|		WHEN Amounts.SumByDocument = 0 AND Calculations.AccountsPayableOfCompany <> 0
	|			THEN Calculations.AccountsPayableOfCompany
	|		ELSE Amounts.SumByDocument
	|	END                               AS SumByDocument
	|FROM TTCalculations AS Calculations
	|		LEFT JOIN TTAmountsAccordingToDocuments AS Amounts
	|			ON Amounts.ARAPObject = Calculations.ARAPObject
	|				AND Amounts.DocumentRecorder = Calculations.DocumentRecorder
	|				AND Amounts.Organization = Calculations.Organization
	|				AND Amounts.Period = Calculations.Period
	|WHERE
	|	Calculations.DebtOfSupplier <> 0
	|	OR Calculations.AccountsPayableOfCompany <> 0
	|	OR Calculations.SheduledPayment <> 0
	|	OR Calculations.ScheduledSupply <> 0
	|";
	
	QueryText = StrReplace(QueryText,"&SuppliedBySupplier", ARAPAccountingReports.TemplateOfShippedField());
	QueryText = StrReplace(QueryText,"&CreditedBySupplier", ARAPAccountingReports.TemplateOfCreditedField());
	QueryText = StrReplace(QueryText,"&PaidToSupplier", ARAPAccountingReports.TemplateForPaidField());
	QueryText = StrReplace(QueryText,"&WriteOffRevaluation", ARAPAccountingReports.TemplateForWriteOffRevaluationField());
	
	Return QueryText;
	
EndFunction

Procedure GenerateReportParameters(CommandParameter, ThisForm, Parameters)
	
	FormParameters = ThisForm.ParametersForm;
	
	If TypeOf(CommandParameter) = Type("Array") Then
		ThisIsArray = True;
		If CommandParameter.Count() > 0 Then
			TheFirstControl = CommandParameter[0];
		Else
			TheFirstControl = Undefined;
		EndIf;
	Else
		ThisIsArray = False;
		TheFirstControl = CommandParameter;
	EndIf;
	
	If TypeOf(TheFirstControl) = Type("CatalogRef.Partners") Then
		If ThisIsArray Then
			ThereAreSubordinatePartners = False;
			For Each CommandParameterElement In CommandParameter Do
				If PartnersAndCounterparties.ThereAreSubordinatePartners(CommandParameterElement) Then
					ThereAreSubordinatePartners = True;
					Break;
				EndIf;
			EndDo;
		Else
			ThereAreSubordinatePartners = PartnersAndCounterparties.ThereAreSubordinatePartners(CommandParameter);
		EndIf;
		
		If ThereAreSubordinatePartners Then
			FormParameters.PurposeUseKey = "Partners_Group";
			Parameters.PurposeUseKey = "Partners_Group";
		Else
			FormParameters.PurposeUseKey = CommandParameter;
			Parameters.PurposeUseKey = CommandParameter;
		EndIf;
		FilterValue = CommandParameter;
		DCComparisonType = DataCompositionComparisonType.Equal;
		If ThisIsArray Then
			FilterValue = New ValueList;
			FilterValue.LoadValues(CommandParameter);
			If ThereAreSubordinatePartners Then
				DCComparisonType = DataCompositionComparisonType.InListByHierarchy;
			Else
				DCComparisonType = DataCompositionComparisonType.InList;
			EndIf;
		Else
			If ThereAreSubordinatePartners Then
				DCComparisonType = DataCompositionComparisonType.InHierarchy;
			Else
				DCComparisonType = DataCompositionComparisonType.Equal;
			EndIf;
		EndIf;
		CommonClientServer.SetFilterItem(
			SettingsComposer.FixedSettings.Filter,
			"Partner",
			FilterValue,
			DCComparisonType,,
			True);
	ElsIf TypeOf(TheFirstControl) = Type("CatalogRef.CounterpartyContracts") 
		Or TypeOf(TheFirstControl) = Type("CatalogRef.IntercompanyContracts") Then
		FormParameters.PurposeUseKey = CommandParameter;
		Parameters.PurposeUseKey = CommandParameter;
		FilterValue = TheFirstControl;
		DCComparisonType = DataCompositionComparisonType.Equal;
		If ThisIsArray Then
			FilterValue = New ValueList;
			FilterValue.LoadValues(CommandParameter);
			DCComparisonType = DataCompositionComparisonType.InList;
		EndIf;
		CommonClientServer.SetFilterItem(
			SettingsComposer.FixedSettings.Filter, 
			"Contract",
			FilterValue,
			DCComparisonType,,
			True);
	Else
		ARAPObject = ARAPAccountingServer.GetARAPObjectsForSelectingReport(CommandParameter);
		FormParameters.PurposeUseKey = ARAPObject;
		Parameters.PurposeUseKey = ARAPObject;
		FilterValue = ARAPObject;
		DCComparisonType = DataCompositionComparisonType.Equal;
		If TypeOf(ARAPObject) = Type("Array") Then
			FilterValue = New ValueList;
			FilterValue.LoadValues(ARAPObject);
			DCComparisonType = DataCompositionComparisonType.InList;
		EndIf;
		CommonClientServer.SetFilterItem(
			SettingsComposer.FixedSettings.Filter, 
			"ARAPObject",
			FilterValue,
			DCComparisonType,,
			True);
	EndIf;
	
EndProcedure

#EndRegion

#EndIf