#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var ReportDate, DateOfRemainingGoods, ReportData, FilterByPartnerSegmentIsUsed, Calendar, LineMutualSettlementsState, LineDebtIsNotOverdue, DebtClassificationOption;

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
	
	#Region UpdatingSettlements
	SetPrivilegedMode(True);
	FilterFields = ARAPAllocationServerCall.DefaultSelectionFields();
	FilterFields.Period = "ReportDate";
	AuxProperties = SettingsComposer.UserSettings.AdditionalProperties;
	JobName = ARAPAllocationServerCall.NameOfCustomerSettlementBackgroundJob();
	ARAPAllocationServerCall.RestoreSelectionCalculations(SettingsComposer, FilterFields, AuxProperties, JobName);
	SetPrivilegedMode(False);
	#EndRegion
	
	// We will prepare and output a report.
	TemplateComposer = New DataCompositionTemplateComposer;
	
	DataCompositionSettings = SettingsComposer.GetSettings();
		
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, DataCompositionSettings, DetailsData);
		
	CompositionProcessor = New DataCompositionProcessor;
	
	ReportPeriod = TMReportFunctionsClientServer.CalculationBoundary(SettingsComposer, FilterFields.Period);
	PaymentTable_3 = Payments_2();
	
	ExternalDataSets = New Structure("PaymentTable_3", PaymentTable_3);
	CompositionProcessor.Initialize(CompositionTemplate, ExternalDataSets, DetailsData, True);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	
	#Region CheckingSettlements
	InformationRegisters.JobsForAllocatingCustomersARAP.DisplayRelevanceOfCalculation(ResultDocument, AuxProperties);
	#EndRegion
	
	//A warning about the unfulfilled distribution of mutual settlements.
	ARAPAccountingServer.DisplayUpdateWarning(ResultDocument);
	
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

Procedure SetRequiredSettings(Var_SettingsComposer, UserSettingsModified)
	
	SetReportDate(Var_SettingsComposer, UserSettingsModified);
	EstablishDebtClassificationOption(Var_SettingsComposer, UserSettingsModified);
	SetCalendar(Var_SettingsComposer, UserSettingsModified);
	
	SegmentsServer.EnableSelectionByVSKDPartnerSegment(Var_SettingsComposer);
	
	CurrentDate = CurrentSessionDate();
	BalanceDateStartOfDay = BegOfDay(CurrentDate);
	BalanceDateEndOfDay = EndOfDay(CurrentDate);
	
	ReportDateParameter = DataCompositionClientServer.GetParameter(Var_SettingsComposer, "ReportDate");
	If ReportDateParameter <> Undefined Then
		If Not ValueIsFilled(ReportDateParameter.Value) Then
			ReportDate = CurrentDate;
		Else
			If TypeOf(ReportDateParameter.Value) = Type("Date") Then
				ReportDate = ReportDateParameter.Value;
			Else
				ReportDate = ReportDateParameter.Value.Date;
			EndIf;
		EndIf;
	EndIf;
	
	BalanceDateParameter = DataCompositionClientServer.GetParameter(Var_SettingsComposer, "DateOfRemainingGoods");
	If BalanceDateParameter <> Undefined Then
		If Not ValueIsFilled(BalanceDateParameter.Value) Then
			DateOfRemainingGoods = BalanceDateStartOfDay;
		Else
			If TypeOf(BalanceDateParameter.Value) = Type("Date")
				Or TypeOf(BalanceDateParameter.Value) = Type("Boundary") Then
				DateOfRemainingGoods = BalanceDateParameter.Value;
			Else
				DateOfRemainingGoods = BalanceDateParameter.Value.Date;
			EndIf;
		EndIf;
	EndIf;

	ReportDataParameter = DataCompositionClientServer.GetParameter(Var_SettingsComposer, "ReportData");
	If ReportDataParameter <> Undefined Then
		If ReportDataParameter.Use Then
			ReportData = ReportDataParameter.Value;
		Else
			ReportData = 1;
		EndIf;
	EndIf;
	
	ThisParameterIsUsedToSelectPartnersBySegment = DataCompositionClientServer.GetParameter(Var_SettingsComposer, "FilterByPartnerSegmentIsUsed");
	If ThisParameterIsUsedToSelectPartnersBySegment <> Undefined Then
		If ThisParameterIsUsedToSelectPartnersBySegment.Use Then
			FilterByPartnerSegmentIsUsed = ThisParameterIsUsedToSelectPartnersBySegment.Value;
		Else
			FilterByPartnerSegmentIsUsed = False;
		EndIf;
	EndIf;
	
	CalendarParameter = DataCompositionClientServer.GetParameter(Var_SettingsComposer, "Calendar");
	If CalendarParameter <> Undefined Then
		If CalendarParameter.Use Then
			Calendar = CalendarParameter.Value;
		Else
			Calendar = Constants.MainEnterpriseCalendar.Get();
		EndIf;
	EndIf;
	
	LineMutualSettlementsState = NStr("vi = 'Trạng thái hạch toán đối trừ';
										|ru = 'Состояние взаиморасчетов';
										|en = 'AR/AP state'; fa = 'وضعیت دریافتنی/پرداختنی';
										|it = 'Lo stato di conti reciproci';
										|pl = 'Status rozliczeń wzajemnych';
										|tr = 'Karşılıklı anlaşmaların durumu'");
	LineDebtIsNotOverdue = NStr("vi = 'Chưa quá hạn';
								|ru = 'Не просрочено';
								|en = 'Not overdue'; fa = 'معوق نشده';
								|it = 'Non scaduto';
								|pl = 'Nie przeterminowano';
								|tr = 'Vadesi geçmemiş'");
	
	ParameterDebtClassificationOption = DataCompositionClientServer.GetParameter(Var_SettingsComposer, "DebtClassificationOption");
	If ParameterDebtClassificationOption <> Undefined Then
		If ParameterDebtClassificationOption.Use Then
			DebtClassificationOption = ParameterDebtClassificationOption.Value;
		Else
			DebtClassificationOption = GeneralPurposeTMServerCall.DefaultDebtClassificationOption();
		EndIf;
	EndIf;
EndProcedure

Procedure EstablishDebtClassificationOption(Var_SettingsComposer, UserSettingsModified)
	ParameterDebtClassificationOption = DataCompositionClientServer.GetParameter(Var_SettingsComposer, "DebtClassificationOption");
	
	If Not ValueIsFilled(ParameterDebtClassificationOption.Value) Then
		DataCompositionClientServer.SetParameter(Var_SettingsComposer, "DebtClassificationOption", GeneralPurposeTMServerCall.DefaultDebtClassificationOption());
		
		UserSettingsModified = True;
	EndIf;
EndProcedure

Procedure SetReportDate(Var_SettingsComposer, UserSettingsModified)
	ReportDateParameter = DataCompositionClientServer.GetParameter(Var_SettingsComposer, "ReportDate");
	ReportDateParameter.Use = True;
	
	BalanceDateParameter = DataCompositionClientServer.GetParameter(Var_SettingsComposer, "DateOfRemainingGoods");
	BalanceDateParameter.Use = True;
	
	If TypeOf(ReportDateParameter.Value) = Type("StandardBeginningDate") Then
		If Not ValueIsFilled(ReportDateParameter.Value.Date) Then
			ReportDateParameter.Value.Date = EndOfDay(CurrentSessionDate());
			UserSettingsModified = True;
		EndIf;
		BalanceDateParameter.Value = New Boundary(EndOfDay(ReportDateParameter.Value.Date), BoundaryType.Including);
	Else
		If Not ValueIsFilled(ReportDateParameter.Value) Then
			ReportDateParameter.Value = EndOfDay(CurrentSessionDate());
			UserSettingsModified = True;
		EndIf;
		BalanceDateParameter.Value = New Boundary(EndOfDay(ReportDateParameter.Value), BoundaryType.Including);
	EndIf;
EndProcedure

Procedure SetCalendar(Var_SettingsComposer, UserSettingsModified)
	ParameterDebtClassificationOption = DataCompositionClientServer.GetParameter(Var_SettingsComposer, "DebtClassificationOption");
	CalendarParameter = DataCompositionClientServer.GetParameter(Var_SettingsComposer, "Calendar");
	
	If ParameterDebtClassificationOption.Value.Calendar.IsEmpty() Then
		MainEnterpriseCalendar = Constants.MainEnterpriseCalendar.Get();
		If Not MainEnterpriseCalendar.IsEmpty() Then
			DataCompositionClientServer.SetParameter(Var_SettingsComposer, "Calendar", MainEnterpriseCalendar);
		
			UserSettingsModified = True;
		EndIf;
	Else
		DataCompositionClientServer.SetParameter(Var_SettingsComposer, "Calendar", ParameterDebtClassificationOption.Value.Calendar);
		
		UserSettingsModified = True;
	EndIf;
EndProcedure

Procedure ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer)
	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(FormSettingsComposer, "Counterparty");
	EndIf;
	
	If Not Constants.UseSeveralDebtClassifications.Get() Then
		DataCompositionServer.RemoveParameterFromUserReportSettings(FormSettingsComposer, "DebtClassificationOption");
	EndIf;
EndProcedure

Function Payments_2()
	
	TemporaryTable = New TempTablesManager;
	ARAPAccountingServer.CalculateCustomerPaymentDates(TemporaryTable, ReportDate);
	
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED DISTINCT
	|	Segments.Partner AS Partner,
	|	Segments.Segment AS PartnersSegment,
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
	|		WHEN 3
	|			THEN ISNULL(CurrencyExchangeRate.CourseNumerator, 1) / ISNULL(CurrencyExchangeRate.CourseDenominator, 1)
	|	END AS ZoomRatio
	|INTO ExchangeRates
	|FROM
	|	Catalog.Companies AS Companies
	|		LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast({(&DateOfRemainingGoods)}) AS CurrencyExchangeRate
	|			ON Companies.LocalAccountingCurrency = CurrencyExchangeRate.BaseCurrency
	|		LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast({(&DateOfRemainingGoods)}, Currency = &ManagementAccountingCurrency) AS ManSExchangeRate
	|			ON Companies.LocalAccountingCurrency = ManSExchangeRate.BaseCurrency
	|
	|INDEX BY
	|	Organization,
	|	Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT ALLOWED
	|	Calculations.AccountingDimensionByPartners,
	|	Calculations.SalesOrder,
	|	Calculations.SalesOrder.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	CASE
	|		WHEN &ReportData = 1
	|			THEN &ManagementAccountingCurrency 
	|		WHEN &ReportData = 3
	|			THEN DimensionAccounting_1.Organization.LocalAccountingCurrency
	|	END AS Currency,
	|	Calculations.ARAPDocument,
	|	Balance.PaymentDate AS PaymentDate,
	|	-(Calculations.ForReturnBalance + Calculations.PrepaymentBalance) AS AccountsPayableOfCompany,
	|	CASE
	|		WHEN &ReportData = 1
	|			THEN CASE
	|					WHEN Calculations.ARAPManBalance + Calculations.PrepaymentManBalance < 0
	|						THEN -(Calculations.ARAPManBalance + Calculations.PrepaymentManBalance)
	|					ELSE 0
	|				END
	|		WHEN &ReportData = 3
	|			THEN CASE
	|					WHEN Calculations.DebtLocalBalance + Calculations.PrepaymentLocalBalance < 0
	|						THEN -(Calculations.DebtLocalBalance + Calculations.PrepaymentLocalBalance)
	|					ELSE 0
	|				END
	|	END AS OurDebtInTheReportCurrency,
	|
	|	CASE WHEN Calculations.DebtBalance > ISNULL(Balance.AmountDue, Calculations.DebtBalance)
	|		THEN Balance.AmountDue
	|		ELSE Calculations.DebtBalance
	|	END AS CustomerAccountsReceivable,
	|	
	|	CASE
	|		WHEN &ReportData = 1
	|			THEN CASE WHEN Calculations.DebtBalance > ISNULL(Balance.AmountDue, Calculations.DebtBalance)
	|				THEN CAST((Calculations.ARAPManBalance / Calculations.DebtBalance * Balance.AmountDue) AS NUMBER(31,2))
	|				ELSE Calculations.ARAPManBalance
	|			END
	|		WHEN &ReportData = 3
	|			THEN CASE WHEN Calculations.DebtBalance > ISNULL(Balance.AmountDue, Calculations.DebtBalance)
	|				THEN CAST((Calculations.DebtLocalBalance / Calculations.DebtBalance * Balance.AmountDue) AS NUMBER(31,2))
	|				ELSE Calculations.DebtLocalBalance
	|			END
	|	END AS CustomerDebtInTheReportCurrency,
	|	0 AS ToShip,
	|	0 AS ForShipmentInTheReportCurrency,
	|	DimensionAccounting_1.Partner,
	|	DimensionAccounting_1.Organization,
	|	DimensionAccounting_1.Counterparty,
	|	DimensionAccounting_1.Contract,
	|	CASE WHEN NOT Calculations.SalesOrder.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness
	|		THEN DimensionAccounting_1.LineOfBusiness
	|		ELSE Calculations.SalesOrder.LineOfBusiness
	|	END AS LineOfBusiness,
	|	SelectionByPartnerSegment.PartnersSegment AS PartnersSegment
	|INTO TableOfArrearsOverdue
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDocuments.Balance(&DateOfRemainingGoods, ) AS Calculations
	|		
	|	INNER JOIN InformationRegister.AccountingDimensionByPartners AS DimensionAccounting_1
	|	ON Calculations.AccountingDimensionByPartners = DimensionAccounting_1.DimensionKey
	|
	|	LEFT JOIN CustomerBalanceTable AS Balance
	|	ON Calculations.AccountingDimensionByPartners = Balance.AccountingDimensionByPartners
	|		AND Calculations.SalesOrder = Balance.SalesOrder
	|		AND Calculations.ARAPDocument = Balance.ARAPDocument
	|		AND Calculations.Currency = Balance.Currency
	|
	|	LEFT JOIN SelectionByPartnerSegment AS SelectionByPartnerSegment
	|	ON DimensionAccounting_1.Partner = SelectionByPartnerSegment.Partner
	|		AND SelectionByPartnerSegment.FilterByPartnerSegmentIsUsed = &FilterByPartnerSegmentIsUsed 
	|WHERE
	|	DimensionAccounting_1.Partner <> VALUE(Catalog.Partners.OurEnterprise)
	|
	|UNION ALL
	|
	|SELECT
	|	Calculations.AccountingDimensionByPartners,
	|	Calculations.ARAPObject,
	|	Calculations.ARAPObject.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	CASE
	|		WHEN &ReportData = 1
	|			THEN &ManagementAccountingCurrency 
	|		WHEN &ReportData = 3
	|			THEN DimensionAccounting_1.Organization.LocalAccountingCurrency
	|	END AS Currency,
	|	NULL AS ARAPDocument,
	|	DATETIME(1,1,1) AS PaymentDate,
	|	0 AS AccountsPayableOfCompany,
	|	0 AS OurDebtInTheReportCurrency,
	|	0 AS CustomerAccountsReceivable,
	|	0 AS CustomerDebtInTheReportCurrency,
	|	CASE
	|		WHEN Calculations.ToShipBalance < 0
	|			THEN -Calculations.ToShipBalance
	|		ELSE 0
	|	END AS ToShip,
	|	CASE
	|		WHEN Calculations.ToShipBalance < 0
	|			THEN -Calculations.ToShipBalance
	|		ELSE 0
	|	END * CurrencyExchangeRate.ZoomRatio AS ForShipmentInTheReportCurrency,
	|	DimensionAccounting_1.Partner,
	|	DimensionAccounting_1.Organization,
	|	DimensionAccounting_1.Counterparty,
	|	DimensionAccounting_1.Contract,
	|	CASE WHEN NOT Calculations.ARAPObject.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness
	|		THEN DimensionAccounting_1.LineOfBusiness
	|		ELSE Calculations.ARAPObject.LineOfBusiness
	|	END AS LineOfBusiness,
	|	SelectionByPartnerSegment.PartnersSegment AS PartnersSegment
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting.Balance(&DateOfRemainingGoods, ) AS Calculations
	|		
	|	INNER JOIN InformationRegister.AccountingDimensionByPartners AS DimensionAccounting_1
	|	ON Calculations.AccountingDimensionByPartners = DimensionAccounting_1.DimensionKey
	|
	|	LEFT JOIN ExchangeRates AS CurrencyExchangeRate
	|	ON (CurrencyExchangeRate.Currency = Calculations.Currency)
	|		AND (CurrencyExchangeRate.Organization = DimensionAccounting_1.Organization)
	|
	|	LEFT JOIN SelectionByPartnerSegment AS SelectionByPartnerSegment
	|	ON DimensionAccounting_1.Partner = SelectionByPartnerSegment.Partner
	|		AND SelectionByPartnerSegment.FilterByPartnerSegmentIsUsed = &FilterByPartnerSegmentIsUsed 
	|WHERE
	|	DimensionAccounting_1.Partner <> VALUE(Catalog.Partners.OurEnterprise)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.AccountingDimensionByPartners,
	|	Table.SalesOrder,
	|	Table.ARAPDocument,
	|	Table.Currency,
	|	Table.PartnersSegment,
	|	SUM(Table.CustomerAccountsReceivable) AS CustomerAccountsReceivable,
	|	SUM(Table.CustomerDebtInTheReportCurrency) AS CustomerDebtInTheReportCurrency
	|INTO TotalOverdue
	|FROM TableOfArrearsOverdue AS Table
	|GROUP BY
	|	AccountingDimensionByPartners,
	|	SalesOrder,
	|	ARAPDocument,
	|	Currency,
	|	PartnersSegment
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT ALLOWED
	|	Calculations.AccountingDimensionByPartners,
	|	Calculations.SalesOrder,
	|	Calculations.SalesOrder.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	CASE
	|		WHEN &ReportData = 1
	|			THEN &ManagementAccountingCurrency 
	|		WHEN &ReportData = 3
	|			THEN DimensionAccounting_1.Organization.LocalAccountingCurrency
	|	END AS Currency,
	|	Calculations.ARAPDocument,
	|	&ReportDate AS PaymentDate,
	|	-(Calculations.ForReturnBalance + Calculations.PrepaymentBalance) AS AccountsPayableOfCompany,
	|	CASE
	|		WHEN &ReportData = 1
	|			THEN CASE
	|					WHEN Calculations.ARAPManBalance + Calculations.PrepaymentManBalance < 0
	|						THEN -(Calculations.ARAPManBalance + Calculations.PrepaymentManBalance)
	|					ELSE 0
	|				END
	|		WHEN &ReportData = 3
	|			THEN CASE
	|					WHEN Calculations.DebtLocalBalance + Calculations.PrepaymentLocalBalance < 0
	|						THEN -(Calculations.DebtLocalBalance + Calculations.PrepaymentLocalBalance)
	|					ELSE 0
	|				END
	|	END AS OurDebtInTheReportCurrency,
	|
	|	(Calculations.DebtBalance - ISNULL(Balance.CustomerAccountsReceivable, Calculations.DebtBalance)) AS CustomerAccountsReceivable,
	|	
	|	CASE
	|		WHEN &ReportData = 1
	|			THEN (Calculations.ARAPManBalance - Balance.CustomerDebtInTheReportCurrency)
	|		WHEN &ReportData = 3
	|			THEN (Calculations.DebtLocalBalance - Balance.CustomerDebtInTheReportCurrency)
	|	END AS CustomerDebtInTheReportCurrency,
	|	0 AS ToShip,
	|	0 AS ForShipmentInTheReportCurrency,
	|	DimensionAccounting_1.Partner,
	|	DimensionAccounting_1.Organization,
	|	DimensionAccounting_1.Counterparty,
	|	DimensionAccounting_1.Contract,
	|	CASE WHEN NOT Calculations.SalesOrder.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness
	|		THEN DimensionAccounting_1.LineOfBusiness
	|		ELSE Calculations.SalesOrder.LineOfBusiness
	|	END AS LineOfBusiness,
	|	SelectionByPartnerSegment.PartnersSegment AS PartnersSegment
	|INTO TableOfArrears
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDocuments.Balance(&DateOfRemainingGoods, ) AS Calculations
	|		
	|	INNER JOIN InformationRegister.AccountingDimensionByPartners AS DimensionAccounting_1
	|	ON Calculations.AccountingDimensionByPartners = DimensionAccounting_1.DimensionKey
	|
	|	LEFT JOIN SelectionByPartnerSegment AS SelectionByPartnerSegment
	|	ON DimensionAccounting_1.Partner = SelectionByPartnerSegment.Partner
	|		AND SelectionByPartnerSegment.FilterByPartnerSegmentIsUsed = &FilterByPartnerSegmentIsUsed
	|
	|	LEFT JOIN TotalOverdue AS Balance
	|	ON Calculations.AccountingDimensionByPartners = Balance.AccountingDimensionByPartners
	|		AND Calculations.SalesOrder = Balance.SalesOrder
	|		AND Calculations.ARAPDocument = Balance.ARAPDocument
	|		AND Calculations.Currency = Balance.Currency
	|		AND CASE WHEN &FilterByPartnerSegmentIsUsed THEN SelectionByPartnerSegment.PartnersSegment = Balance.PartnersSegment ELSE TRUE END
	|WHERE
	|	DimensionAccounting_1.Partner <> VALUE(Catalog.Partners.OurEnterprise)
	|	AND (Calculations.DebtBalance - ISNULL(Balance.CustomerAccountsReceivable, Calculations.DebtBalance)) <> 0
	|
	|UNION ALL
	|
	|SELECT 
	|	Calculations.AccountingDimensionByPartners,
	|	Calculations.SalesOrder,
	|	Calculations.FinancialAccountingGroup,
	|	Calculations.Currency,
	|	Calculations.ARAPDocument,
	|	Calculations.PaymentDate,
	|	Calculations.AccountsPayableOfCompany,
	|	Calculations.OurDebtInTheReportCurrency,
	|
	|	Calculations.CustomerAccountsReceivable,
	|	
	|	Calculations.CustomerDebtInTheReportCurrency,
	|	Calculations.ToShip,
	|	Calculations.ForShipmentInTheReportCurrency,
	|	Calculations.Partner,
	|	Calculations.Organization,
	|	Calculations.Counterparty,
	|	Calculations.Contract,
	|	Calculations.LineOfBusiness,
	|	Calculations.PartnersSegment
	|FROM
	|	TableOfArrearsOverdue AS Calculations
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	TableOfArrears.PaymentDate AS StartDate,
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
	|	WorkSchedules.Date BETWEEN TableOfArrears.PaymentDate AND &ReportDate
	|	AND TableOfArrears.PaymentDate <> DATETIME(1, 1, 1)
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
	|	&LineMutualSettlementsState AS GroupingEverything,
	|	TableOfArrears.AccountingDimensionByPartners,
	|	TableOfArrears.SalesOrder,
	|	TableOfArrears.Contract AS Contract,
	|	TableOfArrears.LineOfBusiness AS LineOfBusiness,
	|	TableOfArrears.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	TableOfArrears.Currency,
	|	TableOfArrears.ARAPDocument AS ARAPDocument,
	|	TableOfArrears.PaymentDate AS PaymentDate,
	|	TableOfArrears.Partner,
	|	TableOfArrears.Organization,
	|	TableOfArrears.Counterparty,
	|	TableOfArrears.AccountsPayableOfCompany,
	|	TableOfArrears.CustomerAccountsReceivable,
	|	TableOfArrears.ToShip,
	|	TableOfArrears.OurDebtInTheReportCurrency,
	|	TableOfArrears.CustomerDebtInTheReportCurrency,
	|	TableOfArrears.ForShipmentInTheReportCurrency,
	|	CASE
	|		WHEN NOT DateDifferences.DaysCount IS NULL 
	|			THEN CASE
	|					WHEN DateDifferences.DaysCount > 0
	|						THEN DateDifferences.DaysCount
	|					ELSE 0
	|				END
	|		ELSE CASE
	|				WHEN TableOfArrears.PaymentDate = DATETIME(1, 1, 1)
	|					THEN 0
	|				ELSE CASE
	|						WHEN DATEDIFF(TableOfArrears.PaymentDate, &ReportDate, DAY) > 0
	|							THEN DATEDIFF(TableOfArrears.PaymentDate, &ReportDate, DAY)
	|						ELSE 0
	|					END
	|			END
	|	END AS DaysCount,
	|	CASE
	|		WHEN CASE
	|				WHEN NOT DateDifferences.DaysCount IS NULL 
	|					THEN CASE
	|							WHEN DateDifferences.DaysCount > 0
	|								THEN DateDifferences.DaysCount
	|							ELSE 0
	|						END
	|				ELSE CASE
	|						WHEN TableOfArrears.PaymentDate = DATETIME(1, 1, 1)
	|							THEN 0
	|						ELSE CASE
	|								WHEN DATEDIFF(TableOfArrears.PaymentDate, &ReportDate, DAY) > 0
	|									THEN DATEDIFF(TableOfArrears.PaymentDate, &ReportDate, DAY)
	|								ELSE 0
	|							END
	|					END
	|			END = 0
	|			THEN 0
	|		ELSE TableOfArrears.CustomerAccountsReceivable
	|	END AS OverdueCustomerDebt,
	|	CASE
	|		WHEN CASE
	|				WHEN NOT DateDifferences.DaysCount IS NULL 
	|					THEN CASE
	|							WHEN DateDifferences.DaysCount > 0
	|								THEN DateDifferences.DaysCount
	|							ELSE 0
	|						END
	|				ELSE CASE
	|						WHEN TableOfArrears.PaymentDate = DATETIME(1, 1, 1)
	|							THEN 0
	|						ELSE CASE
	|								WHEN DATEDIFF(TableOfArrears.PaymentDate, &ReportDate, DAY) > 0
	|									THEN DATEDIFF(TableOfArrears.PaymentDate, &ReportDate, DAY)
	|								ELSE 0
	|							END
	|					END
	|			END = 0
	|			THEN 0
	|		ELSE TableOfArrears.CustomerDebtInTheReportCurrency
	|	END AS OverdueCustomerDebtInReportCurrency,
	|	ISNULL(Intervals.IntervalName, &LineDebtIsNotOverdue) AS IntervalName,
	|	ISNULL(Intervals.LineNumber, 0) AS IntervalNumber,
	|	ISNULL(Intervals.LowerBoundOfInterval, 0) AS LowerBoundOfInterval,
	|	TableOfArrears.PartnersSegment AS PartnersSegment
	|FROM
	|	TableOfArrears AS TableOfArrears
	|		{LEFT JOIN DateDifferences AS DateDifferences
	|		ON (DateDifferences.StartDate = TableOfArrears.PaymentDate)
	|		LEFT JOIN Catalog.TimeBucketsForAgingAnalysis.Intervals AS Intervals
	|		ON (Intervals.Ref = &DebtClassificationOption)
	|			AND (CASE
	|				WHEN NOT DateDifferences.DaysCount IS NULL 
	|					THEN CASE
	|							WHEN DateDifferences.DaysCount > 0
	|								THEN DateDifferences.DaysCount
	|							ELSE 0
	|						END
	|				ELSE CASE
	|						WHEN TableOfArrears.PaymentDate = DATETIME(1, 1, 1)
	|							THEN 0
	|						ELSE CASE
	|								WHEN DATEDIFF(TableOfArrears.PaymentDate, &ReportDate, DAY) > 0
	|									THEN DATEDIFF(TableOfArrears.PaymentDate, &ReportDate, DAY)
	|								ELSE 0
	|							END
	|					END
	|			END BETWEEN Intervals.LowerBoundOfInterval AND Intervals.UpperBoundOfInterval)}";
	
	Query.TempTablesManager = TemporaryTable;
	Query.SetParameter("ReportDate", ReportDate);
	Query.SetParameter("DateOfRemainingGoods", DateOfRemainingGoods);
	Query.SetParameter("ReportData", ReportData);
	Query.SetParameter("FilterByPartnerSegmentIsUsed", FilterByPartnerSegmentIsUsed);
	Query.SetParameter("Calendar", Calendar);
	Query.SetParameter("LineMutualSettlementsState", LineMutualSettlementsState);
	Query.SetParameter("LineDebtIsNotOverdue", LineDebtIsNotOverdue);
	Query.SetParameter("DebtClassificationOption", DebtClassificationOption);
	Query.SetParameter("ManagementAccountingCurrency", SettingsValueCached.ManagementAccountingCurrency());
	
	Return Query.Execute().Unload();
EndFunction

#EndRegion

#EndIf