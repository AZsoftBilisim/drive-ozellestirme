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
	Settings.Events.BeforeLoadVariantAtServer = True;
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

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	UserSettingsModified = False;
	
	SetRequiredSettings(SettingsComposer, UserSettingsModified);
	
	// Generate a report
	ReportSettings = SettingsComposer.GetSettings();
	
	DataCompositionSchema.DataSets.DataSet.Query = QueryText();
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	
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
	SetReportDate(Var_SettingsComposer, UserSettingsModified);
	
EndProcedure

Procedure SetReportDate(Var_SettingsComposer, UserSettingsModified)
	
	ReportDateParameterBorder = DataCompositionClientServer.GetParameter(Var_SettingsComposer, "PeriodEndBoundary");
	ReportDateParameterBorder.Use = True;

	PeriodParameter = DataCompositionClientServer.GetParameter(Var_SettingsComposer, "Period");
	Period = PeriodParameter.Value; // StandardPeriod
	If PeriodParameter.Use And ValueIsFilled(Period.StartDate) Then
		ReportDateParameterBorder.Value = New Boundary(EndOfDay(Period.EndDate), BoundaryType.Including);
	Else
		ReportDateParameterBorder.Value = Date(1,1,1)
	EndIf;
	
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
	|		WHEN 1
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
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|//Balances on actual debt at the end of the reporting period
	|SELECT ALLOWED
	|	DimensionAccounting_1.Organization                                     AS Organization,
	|	DimensionAccounting_1.Partner                                         AS Partner,
	|	DimensionAccounting_1.Counterparty                                      AS Counterparty,
	|	DimensionAccounting_1.Contract                                         AS Contract,
	|	CASE WHEN NOT CalculationsByTerms.ARAPObject.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness
	|		THEN DimensionAccounting_1.LineOfBusinessOfAnalytics
	|		ELSE CalculationsByTerms.ARAPObject.LineOfBusiness
	|	END                                                          AS LineOfBusiness,
	|	CalculationsByTerms.ARAPObject                                 AS ARAPObject,
	|	CalculationsByTerms.ARAPDocument                              AS ARAPDocument,
	|	CASE &ReportData
	|		WHEN 1
	|			THEN &ManagementAccountingCurrency
	|		ELSE DimensionAccounting_1.Organization.LocalAccountingCurrency
	|	END                                                          AS Currency,
	|	
	|	CASE
	|		WHEN DATEDIFF(CalculationsByTerms.PlannedRepaymentDate, &EndOfPeriod, DAY) < 0
	|			OR CalculationsByTerms.PlannedRepaymentDate < &BeginOfPeriod
	|			OR CalculationsByTerms.PlannedRepaymentDate > &EndOfPeriod
	|			THEN 0
	|		ELSE DATEDIFF(CalculationsByTerms.PlannedRepaymentDate, &EndOfPeriod, DAY)
	|	END                                                          AS OverduePeriod,
	|	CASE
	|		WHEN CalculationsByTerms.PlannedRepaymentDate >= &BeginOfPeriod
	|				AND CalculationsByTerms.PlannedRepaymentDate <= &EndOfPeriod
	|				AND DATEDIFF(CalculationsByTerms.PlannedRepaymentDate, &EndOfPeriod, DAY) > 0 
	|				AND NOT CalculationsByTerms.ARAPDocument REFS Document.ARAPAdjustment
	|			THEN
	|				CASE &ReportData
	|					WHEN 1
	|						THEN CalculationsByTerms.ARAPManBalance
	|					ELSE CalculationsByTerms.DebtLocalBalance
	|				END 
	|		ELSE 0
	|	END                                                          AS OverdueCustomerDebtInPeriod,
	|	CASE &ReportData
	|		WHEN 1
	|			THEN CalculationsByTerms.ARAPManBalance
	|		ELSE CalculationsByTerms.DebtLocalBalance
	|	END                                                          AS CustomerAccountsReceivable,
	|	CASE 
	|		WHEN CalculationsByTerms.PlannedRepaymentDate < &EndOfPeriod
	|			THEN CASE &ReportData
	|					WHEN 1
	|						THEN CalculationsByTerms.ARAPManBalance
	|					ELSE CalculationsByTerms.DebtLocalBalance
	|				END
	|		ELSE 0 
	|	END                                                          AS OverdueCustomerDebt
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates.Balance({&PeriodEndBoundary},
	|		AccountingDimensionByPartners IN
	|				(SELECT
	|					TT_AccountingDimensionByPartners.DimensionKey
	|				FROM
	|					TT_AccountingDimensionByPartners)) AS CalculationsByTerms
	|		INNER JOIN TT_AccountingDimensionByPartners AS DimensionAccounting_1
	|			ON DimensionAccounting_1.DimensionKey = CalculationsByTerms.AccountingDimensionByPartners
	|WHERE
	|	CalculationsByTerms.DebtLocalBalance > 0
	|	AND (&IncludeDebt = 0 OR &IncludeDebt = 1)
	|
	|UNION ALL
	|
	|//Planned debt balances at the end of the reporting period
	|SELECT
	|	DimensionAccounting_1.Organization               AS Organization,
	|	DimensionAccounting_1.Partner                   AS Partner,
	|	DimensionAccounting_1.Counterparty                AS Counterparty,
	|	DimensionAccounting_1.Contract                   AS Contract,
	|	CASE WHEN NOT PaymentPlanCalculations.ARAPObject.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness
	|		THEN DimensionAccounting_1.LineOfBusinessOfAnalytics
	|		ELSE PaymentPlanCalculations.ARAPObject.LineOfBusiness
	|	END                                    AS LineOfBusiness,
	|	PaymentPlanCalculations.ARAPObject          AS ARAPObject,
	|	PaymentPlanCalculations.DocumentPlan            AS ARAPDocument,
	|	CASE &ReportData
	|		WHEN 1
	|			THEN &ManagementAccountingCurrency
	|		ELSE DimensionAccounting_1.Organization.LocalAccountingCurrency
	|	END                                    AS Currency,
	|	
	|	CASE
	|		WHEN DATEDIFF(PaymentPlanCalculations.PlannedRepaymentDate, &EndOfPeriod, DAY) < 0
	|			OR PaymentPlanCalculations.PlannedRepaymentDate < &BeginOfPeriod
	|			OR PaymentPlanCalculations.PlannedRepaymentDate > &EndOfPeriod
	|			THEN 0
	|		ELSE DATEDIFF(PaymentPlanCalculations.PlannedRepaymentDate, &EndOfPeriod, DAY)
	|	END                                    AS OverduePeriod,
	|	CASE
	|		WHEN PaymentPlanCalculations.PlannedRepaymentDate >= &BeginOfPeriod
	|				AND PaymentPlanCalculations.PlannedRepaymentDate <= &EndOfPeriod
	|				AND DATEDIFF(PaymentPlanCalculations.PlannedRepaymentDate, &EndOfPeriod, DAY) > 0 
	|			THEN PaymentPlanCalculations.AmountDueBalance * CurrencyExchangeRate.ZoomRatio
	|		ELSE 0
	|	END                                    AS OverdueCustomerDebtInPeriod,
	|	PaymentPlanCalculations.AmountDueBalance
	|		* CurrencyExchangeRate.ZoomRatio             AS CustomerAccountsReceivable,
	|	CASE 
	|		WHEN PaymentPlanCalculations.PlannedRepaymentDate < &EndOfPeriod
	|			THEN PaymentPlanCalculations.AmountDueBalance * CurrencyExchangeRate.ZoomRatio
	|		ELSE 0 
	|	END                                    AS OverdueCustomerDebt
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingCashFlowPlan.Balance({&PeriodEndBoundary},
	|		AccountingDimensionByPartners IN
	|				(SELECT
	|					TT_AccountingDimensionByPartners.DimensionKey
	|				FROM
	|					TT_AccountingDimensionByPartners)
	|		AND VALUETYPE(DocumentPlan) IN (&TypesOfPlanDocuments)) AS PaymentPlanCalculations
	|		INNER JOIN TT_AccountingDimensionByPartners AS DimensionAccounting_1
	|			ON DimensionAccounting_1.DimensionKey = PaymentPlanCalculations.AccountingDimensionByPartners
	|		LEFT JOIN ExchangeRates AS CurrencyExchangeRate
	|			ON (CurrencyExchangeRate.Currency = PaymentPlanCalculations.Currency)
	|				AND (CurrencyExchangeRate.Organization = DimensionAccounting_1.Organization)
	|WHERE
	|	PaymentPlanCalculations.AmountDueBalance > 0
	|	AND (&IncludeDebt = 0 OR &IncludeDebt = 2)
	|
	|UNION ALL
	|
	|//Turnover on actual debt
	|SELECT
	|	Dimension.Organization                  AS Organization,
	|	Dimension.Partner                      AS Partner,
	|	Dimension.Counterparty                   AS Counterparty,
	|	Dimension.Contract                      AS Contract,
	|	CASE WHEN NOT CalculationsRevolutions.ARAPObject.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness
	|		THEN Dimension.LineOfBusiness
	|		ELSE CalculationsRevolutions.ARAPObject.LineOfBusiness
	|	END                                  AS LineOfBusiness,
	|	CalculationsRevolutions.ARAPObject          AS ARAPObject,
	|	CalculationsRevolutions.ARAPDocument       AS ARAPDocument,
	|	CASE &ReportData
	|		WHEN 1
	|			THEN &ManagementAccountingCurrency
	|		ELSE Dimension.Organization.LocalAccountingCurrency
	|	END                                  AS Currency,
	|	
	|	CASE
	|		WHEN DATEDIFF(CalculationsRevolutions.PlannedRepaymentDate, CalculationsRevolutions.Period, DAY) < 0
	|			THEN 0
	|		ELSE DATEDIFF(CalculationsRevolutions.PlannedRepaymentDate, CalculationsRevolutions.Period, DAY)
	|	END                                  AS OverduePeriod,
	|	
	|	CASE
	|		WHEN CalculationsRevolutions.PlannedRepaymentDate >= &BeginOfPeriod
	|				AND CalculationsRevolutions.PlannedRepaymentDate <= &EndOfPeriod
	|				AND NOT CalculationsRevolutions.ARAPDocument REFS Document.ARAPAdjustment
	|			THEN CASE &ReportData
	|					WHEN 1
	|						THEN CalculationsRevolutions.ARAPMan
	|					ELSE CalculationsRevolutions.DebtLocal
	|				END
	|		ELSE 0
	|	END                                  AS OverdueCustomerDebtInPeriod,
	|	0                                      AS CustomerAccountsReceivable,
	|	0                                      AS OverdueCustomerDebt
	|	
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates AS CalculationsRevolutions
	|		INNER JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
	|			ON Dimension.DimensionKey = CalculationsRevolutions.AccountingDimensionByPartners
	|WHERE
	|	CalculationsRevolutions.DebtLocal > 0
	|	AND CalculationsRevolutions.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND CalculationsRevolutions.Period >= &BeginOfPeriod
	|	AND CalculationsRevolutions.Period <= &EndOfPeriod
	|	AND (&IncludeDebt = 0 OR &IncludeDebt = 1)
	|{WHERE
	|	Dimension.Organization.* AS Organization,
	|	Dimension.Partner.* AS Partner,
	|	Dimension.Counterparty.* AS Counterparty,
	|	Dimension.Contract.* AS Contract,
	|	(CASE WHEN NOT CalculationsRevolutions.ARAPObject.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness
	|		THEN Dimension.LineOfBusiness
	|		ELSE CalculationsRevolutions.ARAPObject.LineOfBusiness
	|	END).* AS LineOfBusiness,
	|	(Dimension.Partner IN
	|			(SELECT
	|				SelectionByPartnerSegment.Partner
	|			FROM
	|				SelectionByPartnerSegment
	|			WHERE
	|				SelectionByPartnerSegment.FilterByPartnerSegmentIsUsed = &FilterByPartnerSegmentIsUsed))}
	|
	|UNION ALL
	|
	|SELECT
	|	Dimension.Organization                                   AS Organization,
	|	Dimension.Partner                                       AS Partner,
	|	Dimension.Counterparty                                    AS Counterparty,
	|	Dimension.Contract                                       AS Contract,
	|	CASE WHEN NOT CalculationsRevolutions.ARAPObject.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness
	|		THEN Dimension.LineOfBusiness
	|		ELSE CalculationsRevolutions.ARAPObject.LineOfBusiness
	|	END                                                   AS LineOfBusiness,
	|	CalculationsRevolutions.ARAPObject                           AS ARAPObject,
	|	CalculationsRevolutions.DocumentPlan                             AS ARAPDocument,
	|	CASE &ReportData
	|		WHEN 1
	|			THEN &ManagementAccountingCurrency
	|		ELSE CalculationsRevolutions.AccountingDimensionByPartners.Organization.LocalAccountingCurrency
	|	END                                                   AS Currency,
	|	
	|	CASE
	|		WHEN DATEDIFF(CalculationsRevolutions.PlannedRepaymentDate,
	|				CalculationsRevolutions.Period, DAY) < 0
	|			THEN 0
	|		ELSE DATEDIFF(CalculationsRevolutions.PlannedRepaymentDate,
	|				CalculationsRevolutions.Period, DAY)
	|	END                                                   AS OverduePeriod,
	|	
	|	CASE
	|		WHEN CalculationsRevolutions.PlannedRepaymentDate >= &BeginOfPeriod
	|				AND CalculationsRevolutions.PlannedRepaymentDate <= &EndOfPeriod
	|			THEN CalculationsRevolutions.AmountDue * CurrencyExchangeRate.ZoomRatio
	|		ELSE 0
	|	END                                                   AS OverdueCustomerDebtInPeriod,
	|	0                                                       AS CustomerAccountsReceivable,
	|	0                                                       AS OverdueCustomerDebt
	|	
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingCashFlowPlan AS CalculationsRevolutions
	|		LEFT JOIN ExchangeRates AS CurrencyExchangeRate
	|			ON (CurrencyExchangeRate.Currency = CalculationsRevolutions.Currency)
	|				AND (CurrencyExchangeRate.Organization = CalculationsRevolutions.AccountingDimensionByPartners.Organization)
	|		INNER JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
	|			ON Dimension.DimensionKey = CalculationsRevolutions.AccountingDimensionByPartners
	|WHERE
	|	CalculationsRevolutions.AmountDue > 0
	|	AND CalculationsRevolutions.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND CalculationsRevolutions.Period >= &BeginOfPeriod
	|	AND CalculationsRevolutions.Period <= &EndOfPeriod
	|	AND (&IncludeDebt = 0 OR &IncludeDebt = 2)
	|{WHERE
	|	Dimension.Organization.* AS Organization,
	|	Dimension.Partner.* AS Partner,
	|	Dimension.Counterparty.* AS Counterparty,
	|	Dimension.Contract.* AS Contract,
	|	(CASE WHEN NOT CalculationsRevolutions.ARAPObject.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness
	|		THEN Dimension.LineOfBusiness
	|		ELSE CalculationsRevolutions.ARAPObject.LineOfBusiness
	|	END).* AS LineOfBusiness,
	|	(Dimension.Partner IN
	|			(SELECT
	|				SelectionByPartnerSegment.Partner
	|			FROM
	|				SelectionByPartnerSegment
	|			WHERE
	|				SelectionByPartnerSegment.FilterByPartnerSegmentIsUsed = &FilterByPartnerSegmentIsUsed))}";
	
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

#EndRegion

#EndIf