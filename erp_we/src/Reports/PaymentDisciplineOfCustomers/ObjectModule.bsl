#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var ReportPeriod, BeginOfPeriod, EndOfPeriod, ReportData, FilterByPartnerSegmentIsUsed;
	
#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	UserSettingsModified = False;
	StandardProcessing = False;
	SetRequiredSettings(UserSettingsModified);
	
	#Region UpdatingSettlements
	SetPrivilegedMode(True);
	FilterFields = ARAPAllocationServerCall.DefaultSelectionFields();
	AuxProperties = SettingsComposer.UserSettings.AdditionalProperties;
	JobName = ARAPAllocationServerCall.NameOfCustomerSettlementBackgroundJob();
	ARAPAllocationServerCall.RestoreSelectionCalculations(SettingsComposer, FilterFields, AuxProperties, JobName);
	SetPrivilegedMode(False);
	#EndRegion
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
	
	// We will prepare and output a report.
	TemplateComposer = New DataCompositionTemplateComposer;
	
	DataCompositionSettings = SettingsComposer.GetSettings();
		
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, DataCompositionSettings, DetailsData);
		
	DataCompositionServer.SetLayoutTemplateHeaders(StructureOfFieldHeaders(), CompositionTemplate);
	
	CompositionProcessor = New DataCompositionProcessor;
	
	ReportPeriod = TMReportFunctionsClientServer.CalculationBoundary(SettingsComposer, FilterFields.Period);
	PaymentTable_3 = PaymentsForReport();
	
	ExternalDataSets = New Structure("PaymentTable_3", PaymentTable_3);
	CompositionProcessor.Initialize(CompositionTemplate, ExternalDataSets, DetailsData, True);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	#Region CheckingSettlements
	InformationRegisters.JobsForAllocatingCustomersARAP.DisplayRelevanceOfCalculation(ResultDocument, AuxProperties);
	#EndRegion
	ARAPAccountingServer.DisplayWarningAboutEndOfOfflinePaymentSupport(ResultDocument);
	OutputProcessor.BeginOutput();
	OutputProcessor.Output(CompositionProcessor, True);
	OutputProcessor.EndOutput();
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
	
	ReportIsBlank = ReportsServer.ReportIsBlank(ThisObject, CompositionProcessor);
	SettingsComposer.UserSettings.AdditionalProperties.Insert("ReportIsBlank", ReportIsBlank);
	
EndProcedure

#EndRegion

#Region Private

Function StructureOfFieldHeaders()
	StructureOfFieldHeaders = New Structure;
	
	StructureOfUnitFieldHeaders_ = DataCompositionServer.UnitFieldHeaders(SettingsComposer);
	CommonClientServer.SupplementStructure(StructureOfFieldHeaders, StructureOfUnitFieldHeaders_, False);
	
	Return StructureOfFieldHeaders;
EndFunction

Procedure SetRequiredSettings(UserSettingsModified)
	
	SetReportPeriods(SettingsComposer, UserSettingsModified);
	
	ReportDataParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "ReportData");
	ReportData = ReportDataParameter.Value;
	
	ThisParameterIsUsedToSelectPartnersBySegment = DataCompositionClientServer.GetParameter(SettingsComposer, "FilterByPartnerSegmentIsUsed");
	If ThisParameterIsUsedToSelectPartnersBySegment <> Undefined Then
		If ThisParameterIsUsedToSelectPartnersBySegment.Use Then
			FilterByPartnerSegmentIsUsed = ThisParameterIsUsedToSelectPartnersBySegment.Value;
		Else
			FilterByPartnerSegmentIsUsed = False;
		EndIf;
	EndIf;
	
	SegmentsServer.EnableSelectionByVSKDPartnerSegment(SettingsComposer);
	
EndProcedure

Procedure SetReportPeriods(Var_SettingsComposer, UserSettingsModified)
	
	BeginOfPeriod = Date(1, 1, 1);
	EndOfPeriod = Date(1, 1, 1);
	
	SettingUpPeriod = DataCompositionClientServer.GetParameter(Var_SettingsComposer, "Period");
	Period = SettingUpPeriod.Value; // StandardPeriod
	
	If ValueIsFilled(Period.StartDate) Then
		BeginOfPeriod = Period.StartDate;
	Else
		BeginOfPeriod = BegOfDay(CurrentSessionDate());
		Period.StartDate = BeginOfPeriod;
		UserSettingsModified = True;
	EndIf;
	
	If ValueIsFilled(Period.EndDate) Then
		EndOfPeriod = Period.EndDate;
	Else
		EndOfPeriod = EndOfDay(CurrentSessionDate());
		Period.EndDate = EndOfPeriod;
		UserSettingsModified = True;
	EndIf;
	
EndProcedure

Function PaymentsForReport()
	
	TemporaryTable = New TempTablesManager;
	ARAPAccountingServer.CalculateCustomerPaymentDates(TemporaryTable, EndOfPeriod);
	
	Query = New Query("
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
	|
	|INDEX BY
	|	Organization,
	|	Currency
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	PaymentTable_3.AccountingDimensionByPartners,
	|	PaymentTable_3.Partner,
	|	PaymentTable_3.BusinessRegion,
	|	PaymentTable_3.Organization,
	|	PaymentTable_3.ARAPDocument,
	|	PaymentTable_3.SalesOrder,
	|	PaymentTable_3.Manager,
	|	CASE &ReportData
	|		WHEN 1
	|			THEN &ManagementAccountingCurrency
	|		ELSE PaymentTable_3.Organization.LocalAccountingCurrency
	|	END AS Currency,
	|	PaymentTable_3.OverduePeriod,
	|	PaymentTable_3.PaymentDate,
	|	PaymentTable_3.Recorder,
	|	SUM(PaymentTable_3.PaymentAmount * SettlementCurrencyRates.CourseNumerator * AccountingCurrencyRates.CourseDenominator / (SettlementCurrencyRates.CourseDenominator * AccountingCurrencyRates.CourseNumerator)) AS PaymentAmount,
	|	0 AS CustomerAccountsReceivable,
	|	0 AS OverdueCustomerDebt
	|FROM
	|	(SELECT
	|		PaymentTable_3.AccountingDimensionByPartners,
	|		PaymentTable_3.Partner AS Partner,
	|		PaymentTable_3.BusinessRegion AS BusinessRegion,
	|		PaymentTable_3.Organization AS Organization,
	|		PaymentTable_3.ARAPDocument AS ARAPDocument,
	|		PaymentTable_3.SalesOrder AS SalesOrder,
	|		PaymentTable_3.Manager AS Manager,
	|		PaymentTable_3.Currency AS Currency,
	|		PaymentTable_3.SettlementCurrency AS SettlementCurrency,
	|		PaymentTable_3.OverduePeriod AS OverduePeriod,
	|		PaymentTable_3.PaymentDate AS PaymentDate,
	|		PaymentTable_3.PaymentAmount AS PaymentAmount,
	|		PaymentTable_3.Recorder AS Recorder,
	|		MAX(AccountingCurrencyRates.Period) AS AccountingCourseDate,
	|		MAX(SettlementCurrencyRates.Period) AS SettlementCourseDate
	|	FROM
	|		(SELECT
	|			DimensionByPartners.DimensionKey AS AccountingDimensionByPartners,
	|			DimensionByPartners.Partner AS Partner,
	|			DimensionByPartners.Partner.BusinessRegion AS BusinessRegion,
	|			DimensionByPartners.Organization AS Organization,
	|			CASE &ReportData
	|				WHEN 1
	|					THEN &ManagementAccountingCurrency
	|				ELSE DimensionByPartners.Organization.LocalAccountingCurrency
	|			END AS Currency,
	|			CustomersARAPAccountingByDocumentsTurnovers.ARAPDocument AS ARAPDocument,
	|			CustomersARAPAccountingByDocumentsTurnovers.SalesOrder AS SalesOrder,
	|			CustomersARAPAccountingByDocumentsTurnovers.SalesOrder.Manager AS Manager,
	|			CustomersARAPAccountingByDocumentsTurnovers.Currency AS SettlementCurrency,
	|			CASE
	|				WHEN DATEDIFF(PaymentDatesForDocuments.PaymentDate, CustomersARAPAccountingByDocumentsTurnovers.DayPeriod, DAY) < 0
	|					THEN 0
	|				ELSE DATEDIFF(PaymentDatesForDocuments.PaymentDate, CustomersARAPAccountingByDocumentsTurnovers.DayPeriod, DAY)
	|			END AS OverduePeriod,
	|			PaymentDatesForDocuments.PaymentDate AS PaymentDate,
	|			PaymentDatesForDocuments.Debt AS PaymentAmount,
	|			CustomersARAPAccountingByDocumentsTurnovers.Recorder AS Recorder
	|		FROM
	|			AccumulationRegister.CustomersARAPAccountingByDocuments.Turnovers(, , Auto, {(AccountingDimensionByPartners.Partner IN
	|					(SELECT
	|						SelectionByPartnerSegment.Partner
	|					FROM
	|						SelectionByPartnerSegment
	|					WHERE
	|						SelectionByPartnerSegment.FilterByPartnerSegmentIsUsed = &FilterByPartnerSegmentIsUsed))}
	|				) AS CustomersARAPAccountingByDocumentsTurnovers
	|				INNER JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|				ON CustomersARAPAccountingByDocumentsTurnovers.AccountingDimensionByPartners = DimensionByPartners.DimensionKey
	|
	|				INNER JOIN AccumulationRegister.CustomersARAPAccountingByDocuments AS PaymentDatesForDocuments
	|				ON CustomersARAPAccountingByDocumentsTurnovers.AccountingDimensionByPartners = PaymentDatesForDocuments.AccountingDimensionByPartners
	|					AND CustomersARAPAccountingByDocumentsTurnovers.SalesOrder = PaymentDatesForDocuments.SalesOrder
	|					AND CustomersARAPAccountingByDocumentsTurnovers.ARAPDocument = PaymentDatesForDocuments.ARAPDocument
	|					AND CustomersARAPAccountingByDocumentsTurnovers.Currency = PaymentDatesForDocuments.Currency
	|					AND CustomersARAPAccountingByDocumentsTurnovers.Recorder = PaymentDatesForDocuments.Recorder
	|		WHERE
	|			DimensionByPartners.Partner <> VALUE(Catalog.Partners.OurEnterprise)
	|			AND (CustomersARAPAccountingByDocumentsTurnovers.Recorder REFS Document.BankAccountReceiptNote
	|					OR CustomersARAPAccountingByDocumentsTurnovers.Recorder REFS Document.CashAccountReceiptNote
	|					OR CustomersARAPAccountingByDocumentsTurnovers.Recorder REFS Document.PaymentCardTransaction)
	|			AND NOT CustomersARAPAccountingByDocumentsTurnovers.ARAPDocument REFS Document.ARAPAdjustment
	|			AND PaymentDatesForDocuments.PaymentDate <> DATETIME(1, 1, 1)
	|			AND PaymentDatesForDocuments.Debt > 0
	|			AND PaymentDatesForDocuments.RecordType = VALUE(AccumulationRecordType.Expense)
	|			AND CustomersARAPAccountingByDocumentsTurnovers.Currency <>
	|				CASE &ReportData
	|					WHEN 1
	|						THEN &ManagementAccountingCurrency
	|					ELSE DimensionByPartners.Organization.LocalAccountingCurrency
	|				END
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			DimensionByPartners.DimensionKey AS AccountingDimensionByPartners,
	|			DimensionByPartners.Partner,
	|			DimensionByPartners.Partner.BusinessRegion,
	|			DimensionByPartners.Organization,
	|			CASE &ReportData
	|				WHEN 1
	|					THEN &ManagementAccountingCurrency
	|				ELSE DimensionByPartners.Organization.LocalAccountingCurrency
	|			END,
	|			CustomersARAPAccountingByDocumentsBalance.ARAPDocument,
	|			CustomersARAPAccountingByDocumentsBalance.SalesOrder,
	|			CustomersARAPAccountingByDocumentsBalance.SalesOrder.Manager,
	|			CustomersARAPAccountingByDocumentsBalance.Currency,
	|			DATEDIFF(Balance.PaymentDate, &EndOfPeriod, DAY),
	|			&EndOfPeriod,
	|			CustomersARAPAccountingByDocumentsBalance.DebtBalance,
	|			NULL
	|		FROM
	|			AccumulationRegister.CustomersARAPAccountingByDocuments.Balance(&EndOfPeriod, {(AccountingDimensionByPartners.Partner IN
	|					(SELECT
	|						SelectionByPartnerSegment.Partner
	|					FROM
	|						SelectionByPartnerSegment
	|					WHERE
	|						SelectionByPartnerSegment.FilterByPartnerSegmentIsUsed = &FilterByPartnerSegmentIsUsed))}
	|			) AS CustomersARAPAccountingByDocumentsBalance
	|				INNER JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|				ON CustomersARAPAccountingByDocumentsBalance.AccountingDimensionByPartners = DimensionByPartners.DimensionKey
	|
	|				LEFT JOIN CustomerBalanceTable AS Balance
	|				ON CustomersARAPAccountingByDocumentsBalance.AccountingDimensionByPartners = Balance.AccountingDimensionByPartners
	|					AND CustomersARAPAccountingByDocumentsBalance.SalesOrder = Balance.SalesOrder
	|					AND CustomersARAPAccountingByDocumentsBalance.ARAPDocument = Balance.ARAPDocument
	|					AND CustomersARAPAccountingByDocumentsBalance.Currency = Balance.Currency
	|					AND Balance.PaymentDate < DATEADD(&EndOfPeriod, DAY, -1)
	|					AND Balance.PaymentDate >= &BeginOfPeriod
	|		WHERE
	|			DimensionByPartners.Partner <> VALUE(Catalog.Partners.OurEnterprise)
	|			AND NOT CustomersARAPAccountingByDocumentsBalance.ARAPDocument REFS Document.ARAPAdjustment
	|			AND (Balance.PaymentDate <> DATETIME(1, 1, 1) OR Balance.SalesOrder IS NULL)
	|			AND CustomersARAPAccountingByDocumentsBalance.DebtBalance > 0
	|			AND CustomersARAPAccountingByDocumentsBalance.Currency <>
	|				CASE &ReportData
	|					WHEN 1
	|						THEN &ManagementAccountingCurrency
	|					ELSE DimensionByPartners.Organization.LocalAccountingCurrency
	|				END
	|		) AS PaymentTable_3
	|			LEFT JOIN InformationRegister.RelativeExchangeRates AS SettlementCurrencyRates
	|			ON PaymentTable_3.PaymentDate >= SettlementCurrencyRates.Period
	|				AND PaymentTable_3.SettlementCurrency = SettlementCurrencyRates.Currency
	|				AND PaymentTable_3.Organization.LocalAccountingCurrency = SettlementCurrencyRates.BaseCurrency
	|			LEFT JOIN InformationRegister.RelativeExchangeRates AS AccountingCurrencyRates
	|			ON PaymentTable_3.PaymentDate >= AccountingCurrencyRates.Period
	|				AND PaymentTable_3.Currency = SettlementCurrencyRates.Currency
	|				AND PaymentTable_3.Organization.LocalAccountingCurrency = AccountingCurrencyRates.BaseCurrency
	|	
	|	GROUP BY
	|		PaymentTable_3.AccountingDimensionByPartners,
	|		PaymentTable_3.Partner,
	|		PaymentTable_3.BusinessRegion,
	|		PaymentTable_3.Organization,
	|		PaymentTable_3.ARAPDocument,
	|		PaymentTable_3.SalesOrder,
	|		PaymentTable_3.Manager,
	|		PaymentTable_3.Currency,
	|		PaymentTable_3.SettlementCurrency,
	|		PaymentTable_3.OverduePeriod,
	|		PaymentTable_3.PaymentDate,
	|		PaymentTable_3.PaymentAmount,
	|		PaymentTable_3.Recorder) AS PaymentTable_3
	|		LEFT JOIN InformationRegister.RelativeExchangeRates AS SettlementCurrencyRates
	|		ON PaymentTable_3.SettlementCourseDate = SettlementCurrencyRates.Period
	|			AND PaymentTable_3.SettlementCurrency = SettlementCurrencyRates.Currency
	|			AND PaymentTable_3.Organization.LocalAccountingCurrency = SettlementCurrencyRates.BaseCurrency
	|		LEFT JOIN InformationRegister.RelativeExchangeRates AS AccountingCurrencyRates
	|		ON PaymentTable_3.AccountingCourseDate = AccountingCurrencyRates.Period
	|			AND PaymentTable_3.Currency = SettlementCurrencyRates.Currency
	|			AND PaymentTable_3.Organization.LocalAccountingCurrency = AccountingCurrencyRates.BaseCurrency
	|
	|GROUP BY
	|	PaymentTable_3.AccountingDimensionByPartners,
	|	PaymentTable_3.Partner,
	|	PaymentTable_3.BusinessRegion,
	|	PaymentTable_3.Organization,
	|	PaymentTable_3.ARAPDocument,
	|	PaymentTable_3.SalesOrder,
	|	PaymentTable_3.Manager,
	|	PaymentTable_3.Currency,
	|	PaymentTable_3.OverduePeriod,
	|	PaymentTable_3.PaymentDate,
	|	PaymentTable_3.Recorder
	|
	|UNION ALL
	|
	|SELECT
	|	DimensionByPartners.DimensionKey AS AccountingDimensionByPartners,
	|	DimensionByPartners.Partner,
	|	DimensionByPartners.Partner.BusinessRegion,
	|	DimensionByPartners.Organization,
	|	CustomersARAPAccountingByDocumentsTurnovers.ARAPDocument,
	|	CustomersARAPAccountingByDocumentsTurnovers.SalesOrder,
	|	CustomersARAPAccountingByDocumentsTurnovers.SalesOrder.Manager,
	|	CustomersARAPAccountingByDocumentsTurnovers.Currency,
	|	CASE
	|		WHEN DATEDIFF(PaymentDatesForDocuments.PaymentDate, CustomersARAPAccountingByDocumentsTurnovers.DayPeriod, DAY) < 0
	|			THEN 0
	|		ELSE DATEDIFF(PaymentDatesForDocuments.PaymentDate, CustomersARAPAccountingByDocumentsTurnovers.DayPeriod, DAY)
	|	END,
	|	PaymentDatesForDocuments.PaymentDate,
	|	CustomersARAPAccountingByDocumentsTurnovers.Recorder,
	|	PaymentDatesForDocuments.Debt,
	|	0 AS CustomerAccountsReceivable,
	|	0 AS OverdueCustomerDebt
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDocuments.Turnovers(, , Auto, {(AccountingDimensionByPartners.Partner IN
	|			(SELECT
	|				SelectionByPartnerSegment.Partner
	|			FROM
	|				SelectionByPartnerSegment
	|			WHERE
	|				SelectionByPartnerSegment.FilterByPartnerSegmentIsUsed = &FilterByPartnerSegmentIsUsed))}
	|	) AS CustomersARAPAccountingByDocumentsTurnovers
	|		INNER JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON CustomersARAPAccountingByDocumentsTurnovers.AccountingDimensionByPartners = DimensionByPartners.DimensionKey
	|
	|		INNER JOIN AccumulationRegister.CustomersARAPAccountingByDocuments AS PaymentDatesForDocuments
	|		ON CustomersARAPAccountingByDocumentsTurnovers.AccountingDimensionByPartners = PaymentDatesForDocuments.AccountingDimensionByPartners
	|			AND CustomersARAPAccountingByDocumentsTurnovers.SalesOrder = PaymentDatesForDocuments.SalesOrder
	|			AND CustomersARAPAccountingByDocumentsTurnovers.ARAPDocument = PaymentDatesForDocuments.ARAPDocument
	|			AND CustomersARAPAccountingByDocumentsTurnovers.Currency = PaymentDatesForDocuments.Currency
	|			AND CustomersARAPAccountingByDocumentsTurnovers.Recorder = PaymentDatesForDocuments.Recorder
	|WHERE
	|	DimensionByPartners.Partner <> VALUE(Catalog.Partners.OurEnterprise)
	|	AND (CustomersARAPAccountingByDocumentsTurnovers.Recorder REFS Document.BankAccountReceiptNote
	|			OR CustomersARAPAccountingByDocumentsTurnovers.Recorder REFS Document.CashAccountReceiptNote
	|			OR CustomersARAPAccountingByDocumentsTurnovers.Recorder REFS Document.PaymentCardTransaction)
	|	AND NOT CustomersARAPAccountingByDocumentsTurnovers.ARAPDocument REFS Document.ARAPAdjustment
	|	AND PaymentDatesForDocuments.PaymentDate <> DATETIME(1, 1, 1)
	|	AND PaymentDatesForDocuments.Debt > 0
	|	AND PaymentDatesForDocuments.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND CustomersARAPAccountingByDocumentsTurnovers.Currency = 
	|			CASE &ReportData
	|				WHEN 1
	|					THEN &ManagementAccountingCurrency
	|				ELSE DimensionByPartners.Organization.LocalAccountingCurrency
	|			END
	|
	|UNION ALL
	|
	|SELECT
	|	DimensionByPartners.DimensionKey AS AccountingDimensionByPartners,
	|	DimensionByPartners.Partner,
	|	DimensionByPartners.Partner.BusinessRegion,
	|	DimensionByPartners.Organization,
	|	CustomersARAPAccountingByDocumentsBalance.ARAPDocument,
	|	CustomersARAPAccountingByDocumentsBalance.SalesOrder,
	|	CustomersARAPAccountingByDocumentsBalance.SalesOrder.Manager,
	|	CustomersARAPAccountingByDocumentsBalance.Currency,
	|	DATEDIFF(Balance.PaymentDate, &EndOfPeriod, DAY),
	|	&EndOfPeriod,
	|	NULL,
	|	CustomersARAPAccountingByDocumentsBalance.DebtBalance,
	|	0 AS CustomerAccountsReceivable,
	|	0 AS OverdueCustomerDebt
	|
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDocuments.Balance(&EndOfPeriod, {(AccountingDimensionByPartners.Partner IN
	|			(SELECT
	|				SelectionByPartnerSegment.Partner
	|			FROM
	|				SelectionByPartnerSegment
	|			WHERE
	|				SelectionByPartnerSegment.FilterByPartnerSegmentIsUsed = &FilterByPartnerSegmentIsUsed))}
	|	) AS CustomersARAPAccountingByDocumentsBalance
	|		INNER JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON CustomersARAPAccountingByDocumentsBalance.AccountingDimensionByPartners = DimensionByPartners.DimensionKey
	|
	|		INNER JOIN CustomerBalanceTable AS Balance
	|		ON CustomersARAPAccountingByDocumentsBalance.AccountingDimensionByPartners = Balance.AccountingDimensionByPartners
	|			AND CustomersARAPAccountingByDocumentsBalance.SalesOrder = Balance.SalesOrder
	|			AND CustomersARAPAccountingByDocumentsBalance.ARAPDocument = Balance.ARAPDocument
	|			AND CustomersARAPAccountingByDocumentsBalance.Currency = Balance.Currency
	|			AND Balance.PaymentDate < DATEADD(&EndOfPeriod, DAY, -1)
	|			AND Balance.PaymentDate >= &BeginOfPeriod
	|WHERE
	|	DimensionByPartners.Partner <> VALUE(Catalog.Partners.OurEnterprise)
	|	AND NOT CustomersARAPAccountingByDocumentsBalance.ARAPDocument REFS Document.ARAPAdjustment
	|	AND CustomersARAPAccountingByDocumentsBalance.DebtBalance > 0
	|	AND CustomersARAPAccountingByDocumentsBalance.Currency = 
	|			CASE &ReportData
	|				WHEN 1
	|					THEN &ManagementAccountingCurrency
	|				ELSE DimensionByPartners.Organization.LocalAccountingCurrency
	|			END
	|
	|UNION ALL
	|
	|SELECT
	|	DimensionByPartners.DimensionKey AS AccountingDimensionByPartners,
	|	DimensionByPartners.Partner AS Partner,
	|	DimensionByPartners.Partner.BusinessRegion AS BusinessRegion,
	|	DimensionByPartners.Organization AS Organization,
	|	CustomersARAPAccountingByDocuments.ARAPDocument AS ARAPDocument,
	|	CustomersARAPAccountingByDocuments.SalesOrder AS SalesOrder,
	|	CustomersARAPAccountingByDocuments.SalesOrder.Manager AS Manager,
	|	CASE &ReportData
	|		WHEN 1
	|			THEN &ManagementAccountingCurrency
	|		ELSE DimensionByPartners.Organization.LocalAccountingCurrency
	|	END AS Currency,
	|	0,
	|	ISNULL(Balance.PaymentDate, &EndOfPeriod) AS PaymentDate,
	|	NULL,
	|	0 AS PaymentAmount,
	|	SUM(Balance.DebtBalance * CurrencyExchangeRate.ZoomRatio) AS CustomerAccountsReceivable,
	|	SUM(CASE
	|			WHEN ISNULL(Balance.PaymentDate, DATETIME(1, 1, 1)) = DATETIME(1, 1, 1)
	|				THEN 0
	|			ELSE CASE
	|					WHEN DATEDIFF(ISNULL(Balance.PaymentDate, &EndOfPeriod), &EndOfPeriod, DAY) > 0
	|						THEN Balance.DebtBalance * CurrencyExchangeRate.ZoomRatio
	|					ELSE 0
	|				END
	|		END) AS OverdueCustomerDebt
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDocuments.Balance(&EndOfPeriod, {(AccountingDimensionByPartners.Partner IN
	|			(SELECT
	|				SelectionByPartnerSegment.Partner
	|			FROM
	|				SelectionByPartnerSegment
	|			WHERE
	|				SelectionByPartnerSegment.FilterByPartnerSegmentIsUsed = &FilterByPartnerSegmentIsUsed))}
	|	) AS CustomersARAPAccountingByDocuments
	|		INNER JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON CustomersARAPAccountingByDocuments.AccountingDimensionByPartners = DimensionByPartners.DimensionKey
	|
	|		LEFT JOIN ExchangeRates AS CurrencyExchangeRate
	|		ON CustomersARAPAccountingByDocuments.Currency = CurrencyExchangeRate.Currency
	|			AND (CurrencyExchangeRate.Organization = DimensionByPartners.Organization)
	|
	|		LEFT JOIN CustomerBalanceTable AS Balance
	|		ON CustomersARAPAccountingByDocuments.AccountingDimensionByPartners = Balance.AccountingDimensionByPartners
	|			AND CustomersARAPAccountingByDocuments.SalesOrder = Balance.SalesOrder
	|			AND CustomersARAPAccountingByDocuments.ARAPDocument = Balance.ARAPDocument
	|			AND CustomersARAPAccountingByDocuments.Currency = Balance.Currency
	|WHERE
	|	DimensionByPartners.Partner <> VALUE(Catalog.Partners.OurEnterprise)
	|
	|GROUP BY
	|	DimensionByPartners.DimensionKey,
	|	DimensionByPartners.Partner,
	|	DimensionByPartners.Partner.BusinessRegion,
	|	DimensionByPartners.Organization,
	|	CustomersARAPAccountingByDocuments.ARAPDocument,
	|	CustomersARAPAccountingByDocuments.Currency,
	|	CustomersARAPAccountingByDocuments.SalesOrder,
	|	CustomersARAPAccountingByDocuments.SalesOrder.Manager,
	|	ISNULL(Balance.PaymentDate, &EndOfPeriod)
	|");
	
	
	Query.TempTablesManager = TemporaryTable;
	Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", EndOfPeriod);
	Query.SetParameter("ReportData", ReportData);
	Query.SetParameter("FilterByPartnerSegmentIsUsed", FilterByPartnerSegmentIsUsed);
	Query.SetParameter("ManagementAccountingCurrency", Constants.ManagementAccountingCurrency.Get());
	
	Return Query.Execute().Unload();
	
EndFunction

#EndRegion

#EndIf