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

// Called in the report form handler of the same name after executing the form code.
//
// More detailed - See ReportsOverridable.BeforeLoadVariantAtServer
//
Procedure BeforeLoadVariantAtServer(ThisForm, NewDCSettings) Export
	
	Report = ThisForm.Report;
	FormSettingsComposer = Report.SettingsComposer;
	
	// Setting default values
	ConfigureDefaultSelectionParameters(FormSettingsComposer);
	
	NewDCSettings = FormSettingsComposer.Settings;

EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	StandardProcessing = False;
	UserSettingsModified = False;

	#Region UpdatingSettlements
	If Not GetFunctionalOption("NewOnlineARAPAccounting") Then
		SetPrivilegedMode(True);
		FilterFields = ARAPAllocationServerCall.DefaultSelectionFields();
		AuxProperties = SettingsComposer.UserSettings.AdditionalProperties;
		ARAPAllocationServerCall.RestoreSelectionCalculations(SettingsComposer, FilterFields, AuxProperties, "CustomersARAPAccounting");
		SetPrivilegedMode(False);
	EndIf;
	#EndRegion
	
	DataCompositionSchema.DataSets.WorkingCapital.Query = RequestTextDynamicsOfWorkingCapital();
	
	PeriodicityParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "Periodicity");
	If Not ValueIsFilled(PeriodicityParameter.Value) Then
		Raise NStr("vi = 'Chưa điền tham số ""Định kỳ""';
					|ru = 'Не заполнен параметр ""Периодичность""';
					|en = 'Parameter ""Frequency"" is not filled in'; fa = 'Parameter ""Frequency"" is not filled in';
					|it = 'Il parametro ""Periodicità"" non è compilato';
					|pl = 'Parametr ""Okresowość"" nie jest wypełniony';
					|tr = '""Sıklık"" parametresi doldurulmamış'");
	EndIf;
	
	SetRequiredSettings(UserSettingsModified);
	
	ReportSettings = SettingsComposer.GetSettings();
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	
	DataCompositionServer.SetLayoutTemplateHeaders(StructureOfDynamicHeaders(), CompositionTemplate);
	
	// Check that at least one report grouping is enabled
	If CompositionTemplate.DataSets.Count() = 0 Then
		Raise NStr("vi = 'Chưa lập báo cáo. Hãy bật ít nhất một gom nhóm hoặc bảng.';
					|ru = 'Отчет не сформирован. Включите хотя бы одну группировку или таблицу.';
					|en = 'Report is not generated. Enable at least one grouping or table.'; fa = 'Report is not generated. Enable at least one grouping or table.';
					|it = 'Report non generato. Includi almeno un raggruppamento o una tabella.';
					|pl = 'Raport nie został wygenerowany. Dodaj, co najmniej, jedną grupę lub tabelę.';
					|tr = 'Rapor oluşturulmadı. En az bir gruplamayı veya tabloyu dahil edin.'");
	EndIf;
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	#Region CheckingSettlements
	If Not GetFunctionalOption("NewOnlineARAPAccounting") Then
		InformationRegisters.JobsForAllocatingCustomersARAP.DisplayRelevanceOfCalculation(ResultDocument, AuxProperties);
	EndIf;
	#EndRegion

	OutputProcessor.Output(CompositionProcessor);
	
	DataCompositionServer.HideAuxiliaryReportParameters(DataCompositionSchema, SettingsComposer, ResultDocument, AuxiliaryReportParameters());
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function TextTimeSettlementRegistrars()
	
	If Not GetFunctionalOption("NewOnlineARAPAccounting") Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT DISTINCT
	|	CalculationsByTerms.Recorder AS Recorder,
	|	CalculationsByTerms.AccountingDimensionByPartners.Organization AS Organization,
	|	CalculationsByTerms.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	CalculationsByTerms.ARAPObject AS ARAPObject,
	|	CalculationsByTerms.ARAPDocument AS ARAPDocument,
	|	CalculationsByTerms.Currency AS Currency,
	|	CalculationsByTerms.DocumentRecorder AS DocumentRecorder
	|INTO RegistrarsOfSettlementsByTerms
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates AS CalculationsByTerms
	|WHERE
	|	(CalculationsByTerms.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod OR &EndOfPeriod = DATETIME(1, 1, 1))
	|	 AND VALUETYPE(CalculationsByTerms.DocumentRecorder) IN 
	|		(TYPE(Document.OBEntry),
	|		TYPE(Document.OBEntryARAP))
	|{WHERE
	|	CalculationsByTerms.AccountingDimensionByPartners.Organization.*
	|}
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	CalculationsByTerms.Recorder,
	|	CalculationsByTerms.AccountingDimensionByPartners.Organization AS Organization,
	|	CalculationsByTerms.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	CalculationsByTerms.ARAPObject AS ARAPObject,
	|	CalculationsByTerms.ARAPDocument AS ARAPDocument,
	|	CalculationsByTerms.Currency AS Currency,
	|	CalculationsByTerms.DocumentRecorder
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDueDates AS CalculationsByTerms
	|WHERE
	|	(CalculationsByTerms.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod OR &EndOfPeriod = DATETIME(1, 1, 1))
	|	 AND VALUETYPE(CalculationsByTerms.DocumentRecorder) IN 
	|		(TYPE(Document.OBEntry),
	|		TYPE(Document.OBEntryARAP))
	|{WHERE
	|	CalculationsByTerms.AccountingDimensionByPartners.Organization.*
	|}
	|
	|INDEX BY
	|	Recorder
	|;
	|";

	Return QueryText;
	
EndFunction

Function TextTableOfGiftCertificates()
	
	If Not GetFunctionalOption("NewOnlineARAPAccounting") Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT 
	|	GiftCertificates.Ref AS Ref,
	|	GiftCertificates.Owner AS GiftCertificateKind,
	|	GiftCertificates.Owner.Currency AS Currency,
	|	ISNULL(ActivatingGiftCertificates.Organization, VALUE(Catalog.Companies.EmptyRef)) AS Organization	
	|INTO TableOfGiftCertificates
	|FROM
	|	Catalog.GiftCertificates AS GiftCertificates
	|LEFT JOIN InformationRegister.ActivatingGiftCertificates AS ActivatingGiftCertificates
	|	ON ActivatingGiftCertificates.GiftCertificate = GiftCertificates.Ref
	|WHERE
	|	NOT GiftCertificates.Owner.GiftCardAccounting25
	|
	|INDEX BY
	|	Ref
	|;
	|";

	Return QueryText;
	
EndFunction

Function TextCompletedClosingOfMonth()
	QueryText = "
	|SELECT DISTINCT
	|	Rows.Organization,
	|	BEGINOFPERIOD(Operation.Date, MONTH) AS MonthPeriod
	|INTO
	|	ClosingOfMonth
	|FROM
	|	Document.InventoryCostCalculation AS Operation
	|	INNER JOIN Document.InventoryCostCalculation.Companies AS Rows
	|		ON Rows.Ref = Operation.Ref
	|WHERE
	|	(Operation.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod OR &EndOfPeriod = DATETIME(1,1,1))
	|	AND Operation.Posted
	|	AND Operation.EntryType = VALUE(Enum.LotRecordTypes.EmptyRef)
	|	AND NOT Operation.PreliminaryCalculation
	|;
	|";

	Return QueryText;
EndFunction

Function QueryTextInventoryCost()
	
	QueryText = "
	|SELECT ALLOWED
	|	VALUE(Enum.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName) AS IndicatorType,
	|	CASE WHEN CostAccounting_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock) 
	|					AND Dimension.StorageLocation.WarehouseStore = VALUE(Enum.TypesOfWarehouses.RetailStore) THEN
	|		VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceGoodsInRetailSales)
	|	WHEN CostAccounting_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock) 
	|			AND Dimension.StorageLocation.WarehouseStore = VALUE(Enum.TypesOfWarehouses.WholesaleWarehouse) THEN
	|		VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceGoodsAtWholesaleWarehouses)
	|	WHEN CostAccounting_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		OR CostAccounting_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress) THEN
	|		VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceCurrentPeriodExpenses)
	|	WHEN CostAccounting_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller) THEN
	|		VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceGoodsTransferredToTolling)
	|	ELSE
	|		VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceGoodsTransferredToCommissionAgent)
	|	END AS Factor,
	|	
	|	CostAccounting_.Organization AS Organization,
	|	&ManagementAccountingCurrency AS Currency,
	|	NULL AS Partner,
	|	Dimension.Products AS Dimension,
	|
	|	CASE WHEN NOT Warehouses.Department IS NULL THEN
	|		Warehouses.Department
	|	WHEN NOT Departments.Ref IS NULL THEN
	|		Departments.Ref
	|	ELSE
	|		VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END AS Department,
	|	
	|	CostAccounting_.SecondPeriod AS SecondPeriod,
	|	CostAccounting_.DayPeriod AS DayPeriod,
	|	CostAccounting_.WeekPeriod AS WeekPeriod,
	|	CostAccounting_.TenDaysPeriod AS TenDaysPeriod,
	|	CostAccounting_.MonthPeriod AS MonthPeriod,
	|	CostAccounting_.QuarterPeriod AS QuarterPeriod,
	|	CostAccounting_.HalfYearPeriod AS HalfYearPeriod,
	|	CostAccounting_.YearPeriod AS YearPeriod,
	|	
	|	CASE WHEN CostAccounting_.Recorder = UNDEFINED THEN
	|		NULL
	|	ELSE
	|		CostAccounting_.Recorder
	|	END AS Recorder,
	|	
	|	CostAccounting_.CostOpeningBalance
	|	+ CostAccounting_.AddExpensesForGoodsOpeningBalance
	|	+ CostAccounting_.LaborCostsOpeningBalance
	|	+ CostAccounting_.ItemizedFixedCostsIncludingVATOpeningBalance
	|	+ CostAccounting_.ItemizedVariableCostsIncludingVATOpeningBalance AS SumOpeningBalance,
	|
	|	CostAccounting_.CostClosingBalance
	|	+ CostAccounting_.AddExpensesForGoodsClosingBalance
	|	+ CostAccounting_.LaborCostsClosingBalance
	|	+ CostAccounting_.ItemizedFixedCostsIncludingVATClosingBalance
	|	+ CostAccounting_.ItemizedVariableCostsIncludingVATClosingBalance AS SumClosingBalance
	|	
	|INTO WorkingCapital	
	|FROM
	|	AccumulationRegister.InventoryCost.BalanceAndTurnovers({&BeginOfPeriod}, {&EndOfPeriod}, Auto,,
	|		AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		AND AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.MaterialsReceivedForProcessing)
	|	) AS CostAccounting_
	|
	|	LEFT JOIN
	|		Catalog.InventoryLocationAttributeKeys AS Dimension
	|	ON
	|		CostAccounting_.ItemsLocationAttributes = Dimension.Ref
	|
	|	LEFT JOIN
	|		Catalog.Warehouses AS Warehouses
	|	ON
	|		Dimension.StorageLocation = Warehouses.Ref
	|
	|	LEFT JOIN
	|		Catalog.BusinessStructure AS Departments
	|	ON
	|		Dimension.StorageLocation = Departments.Ref
	|";

	Return QueryText;
	
EndFunction

Function QueryTextCash()
	
	QueryText = "
	|SELECT
	|	VALUE(Enum.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName) AS IndicatorType,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceCashAccountBalance) AS Factor,
	|	
	|	Cash.Organization,
	|	CASE WHEN &ReportCurrency = Cash.Organization.LocalAccountingCurrency THEN
	|		Cash.Organization.LocalAccountingCurrency
	|	WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
	|		&ManagementAccountingCurrency
	|	ELSE
	|		Cash.CashAccount.CashCurrency
	|	END AS Currency,
	|	NULL AS Partner,
	|	Cash.CashAccount AS Dimension,
	|	Cash.CashAccount.Department AS Department,
	|	
	|	Cash.SecondPeriod AS SecondPeriod,
	|	Cash.DayPeriod AS DayPeriod,
	|	Cash.WeekPeriod AS WeekPeriod,
	|	Cash.TenDaysPeriod AS TenDaysPeriod,
	|	Cash.MonthPeriod AS MonthPeriod,
	|	Cash.QuarterPeriod AS QuarterPeriod,
	|	Cash.HalfYearPeriod AS HalfYearPeriod,
	|	Cash.YearPeriod AS YearPeriod,
	|	
	|	CASE WHEN Cash.Recorder = UNDEFINED THEN
	|		NULL
	|	ELSE
	|		Cash.Recorder
	|	END AS Recorder,
	|
	|	CASE WHEN &ReportCurrency = Cash.Organization.LocalAccountingCurrency THEN
	|		Cash.SumComplOpeningBalance
	|	WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
	|		Cash.SumManOpeningBalance
	|	ELSE
	|		Cash.SumOpeningBalance
	|	END AS SumOpeningBalance,
	|
	|	CASE WHEN &ReportCurrency = Cash.Organization.LocalAccountingCurrency THEN
	|		Cash.SumComplClosingBalance
	|	WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
	|		Cash.SumManClosingBalance
	|	ELSE
	|		Cash.SumClosingBalance
	|	END AS SumClosingBalance
	|
	|FROM
	|	AccumulationRegister.CashAccountBalance.BalanceAndTurnovers({&BeginOfPeriod}, {&EndOfPeriod}, Auto) AS Cash
	|	
	|UNION ALL
	|
	|SELECT
	|	VALUE(Enum.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName) AS IndicatorType,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceCashInTransit) AS Factor,
	|	
	|	Cash.Organization,
	|	CASE WHEN &ReportCurrency = Cash.Organization.LocalAccountingCurrency THEN
	|		Cash.Organization.LocalAccountingCurrency
	|	WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
	|		&ManagementAccountingCurrency
	|	ELSE
	|		Cash.Currency
	|	END AS Currency,
	|	Cash.Counterparty AS Partner,
	|	Cash.Recipient AS Dimension,
	|	Cash.Recipient.Department AS Department,
	|	
	|	Cash.SecondPeriod AS SecondPeriod,
	|	Cash.DayPeriod AS DayPeriod,
	|	Cash.WeekPeriod AS WeekPeriod,
	|	Cash.TenDaysPeriod AS TenDaysPeriod,
	|	Cash.MonthPeriod AS MonthPeriod,
	|	Cash.QuarterPeriod AS QuarterPeriod,
	|	Cash.HalfYearPeriod AS HalfYearPeriod,
	|	Cash.YearPeriod AS YearPeriod,
	|	
	|	CASE WHEN Cash.Recorder = UNDEFINED THEN
	|		NULL
	|	ELSE
	|		Cash.Recorder
	|	END AS Recorder,
	|	
	|	CASE WHEN &ReportCurrency = Cash.Organization.LocalAccountingCurrency THEN
	|		Cash.SumComplOpeningBalance
	|	WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
	|		Cash.SumManOpeningBalance
	|	ELSE
	|		Cash.SumOpeningBalance
	|	END AS SumOpeningBalance,
	|
	|	CASE WHEN &ReportCurrency = Cash.Organization.LocalAccountingCurrency THEN
	|		Cash.SumComplClosingBalance
	|	WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
	|		Cash.SumManClosingBalance
	|	ELSE
	|		Cash.SumClosingBalance
	|	END AS SumClosingBalance
	|FROM
	|	AccumulationRegister.CashInTransit.BalanceAndTurnovers({&BeginOfPeriod}, {&EndOfPeriod}, Auto) AS Cash
	|WHERE
	|	VALUETYPE(Cash.Recipient) IN (TYPE(Catalog.CashAccounts), TYPE(Catalog.CashRegisters))
	|	
	|UNION ALL
	|
	|SELECT
	|	VALUE(Enum.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName) AS IndicatorType,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceCashAccountBalance) AS Factor,
	|	
	|	Cash.Organization,
	|	CASE WHEN &ReportCurrency = Cash.Organization.LocalAccountingCurrency THEN
	|		Cash.Organization.LocalAccountingCurrency
	|	WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
	|		&ManagementAccountingCurrency
	|	ELSE
	|		Cash.CashRegister.CashCurrency
	|	END AS Currency,
	|	NULL AS Partner,
	|	Cash.CashRegister AS Dimension,
	|	Cash.CashRegister.Department AS Department,
	|	
	|	Cash.SecondPeriod AS SecondPeriod,
	|	Cash.DayPeriod AS DayPeriod,
	|	Cash.WeekPeriod AS WeekPeriod,
	|	Cash.TenDaysPeriod AS TenDaysPeriod,
	|	Cash.MonthPeriod AS MonthPeriod,
	|	Cash.QuarterPeriod AS QuarterPeriod,
	|	Cash.HalfYearPeriod AS HalfYearPeriod,
	|	Cash.YearPeriod AS YearPeriod,
	|	
	|	CASE WHEN Cash.Recorder = UNDEFINED THEN
	|		NULL
	|	ELSE
	|		Cash.Recorder
	|	END AS Recorder,
	|
	|	CASE WHEN &ReportCurrency = Cash.Organization.LocalAccountingCurrency THEN
	|		Cash.SumComplOpeningBalance
	|	WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
	|		Cash.SumManOpeningBalance
	|	ELSE
	|		Cash.SumOpeningBalance
	|	END AS SumOpeningBalance,
	|
	|	CASE WHEN &ReportCurrency = Cash.Organization.LocalAccountingCurrency THEN
	|		Cash.SumComplClosingBalance
	|	WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
	|		Cash.SumManClosingBalance
	|	ELSE
	|		Cash.SumClosingBalance
	|	END AS SumClosingBalance
	|
	|FROM
	|	AccumulationRegister.CashInCashRegistersCR.BalanceAndTurnovers({&BeginOfPeriod}, {&EndOfPeriod}, Auto) AS Cash
	|	
	|UNION ALL
	|
	|SELECT
	|	VALUE(Enum.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName) AS IndicatorType,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceBankAccountCash) AS Factor,
	|	
	|	Cash.Organization,
	|	CASE WHEN &ReportCurrency = Cash.Organization.LocalAccountingCurrency THEN
	|		Cash.Organization.LocalAccountingCurrency
	|	WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
	|		&ManagementAccountingCurrency
	|	ELSE
	|		Cash.BankAccount.CashCurrency
	|	END AS Currency,
	|	NULL AS Partner,
	|	Cash.BankAccount AS Dimension,
	|	Cash.BankAccount.Department AS Department,
	|	
	|	Cash.SecondPeriod AS SecondPeriod,
	|	Cash.DayPeriod AS DayPeriod,
	|	Cash.WeekPeriod AS WeekPeriod,
	|	Cash.TenDaysPeriod AS TenDaysPeriod,
	|	Cash.MonthPeriod AS MonthPeriod,
	|	Cash.QuarterPeriod AS QuarterPeriod,
	|	Cash.HalfYearPeriod AS HalfYearPeriod,
	|	Cash.YearPeriod AS YearPeriod,
	|	
	|	CASE WHEN Cash.Recorder = UNDEFINED THEN
	|		NULL
	|	ELSE
	|		Cash.Recorder
	|	END AS Recorder,
	|
	|	CASE WHEN &ReportCurrency = Cash.Organization.LocalAccountingCurrency THEN
	|		Cash.SumComplOpeningBalance
	|	WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
	|		Cash.SumManOpeningBalance
	|	ELSE
	|		Cash.SumOpeningBalance
	|	END AS SumOpeningBalance,
	|
	|	CASE WHEN &ReportCurrency = Cash.Organization.LocalAccountingCurrency THEN
	|		Cash.SumComplClosingBalance
	|	WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
	|		Cash.SumManClosingBalance
	|	ELSE
	|		Cash.SumClosingBalance
	|	END AS SumClosingBalance
	|
	|FROM
	|	AccumulationRegister.BankAccountCash.BalanceAndTurnovers({&BeginOfPeriod}, {&EndOfPeriod}, Auto) AS Cash
	|	
	|UNION ALL
	|
	|SELECT
	|	VALUE(Enum.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName) AS IndicatorType,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceCashInTransit) AS Factor,
	|	
	|	Cash.Organization,
	|	CASE WHEN &ReportCurrency = Cash.Organization.LocalAccountingCurrency THEN
	|		Cash.Organization.LocalAccountingCurrency
	|	WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
	|		&ManagementAccountingCurrency
	|	ELSE
	|		Cash.Currency
	|	END AS Currency,
	|	Cash.Counterparty AS Partner,
	|	Cash.Recipient AS Dimension,
	|	Cash.Recipient.Department AS Department,
	|	
	|	Cash.SecondPeriod AS SecondPeriod,
	|	Cash.DayPeriod AS DayPeriod,
	|	Cash.WeekPeriod AS WeekPeriod,
	|	Cash.TenDaysPeriod AS TenDaysPeriod,
	|	Cash.MonthPeriod AS MonthPeriod,
	|	Cash.QuarterPeriod AS QuarterPeriod,
	|	Cash.HalfYearPeriod AS HalfYearPeriod,
	|	Cash.YearPeriod AS YearPeriod,
	|	
	|	CASE WHEN Cash.Recorder = UNDEFINED THEN
	|		NULL
	|	ELSE
	|		Cash.Recorder
	|	END AS Recorder,
	|	
	|	CASE WHEN &ReportCurrency = Cash.Organization.LocalAccountingCurrency THEN
	|		Cash.SumComplOpeningBalance
	|	WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
	|		Cash.SumManOpeningBalance
	|	ELSE
	|		Cash.SumOpeningBalance
	|	END AS SumOpeningBalance,
	|
	|	CASE WHEN &ReportCurrency = Cash.Organization.LocalAccountingCurrency THEN
	|		Cash.SumComplClosingBalance
	|	WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
	|		Cash.SumManClosingBalance
	|	ELSE
	|		Cash.SumClosingBalance
	|	END AS SumClosingBalance
	|FROM
	|	AccumulationRegister.CashInTransit.BalanceAndTurnovers({&BeginOfPeriod}, {&EndOfPeriod}, Auto, RegisterRecords) AS Cash
	|WHERE
	|	VALUETYPE(Cash.Recipient) = TYPE(Catalog.CompaniesBankAccounts)
	|	
	|UNION ALL
	|
	|SELECT
	|	VALUE(Enum.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName) AS IndicatorType,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceCashInTransit) AS Factor,
	|	
	|	Cash.Organization,
	|	Cash.BankAccount.CashCurrency AS Currency,
	|	NULL AS Partner,
	|	Cash.BankAccount AS Dimension,
	|	Cash.BankAccount.Department AS Department,
	|	
	|	Cash.SecondPeriod AS SecondPeriod,
	|	Cash.DayPeriod AS DayPeriod,
	|	Cash.WeekPeriod AS WeekPeriod,
	|	Cash.TenDaysPeriod AS TenDaysPeriod,
	|	Cash.MonthPeriod AS MonthPeriod,
	|	Cash.QuarterPeriod AS QuarterPeriod,
	|	Cash.HalfYearPeriod AS HalfYearPeriod,
	|	Cash.YearPeriod AS YearPeriod,
	|	
	|	CASE WHEN Cash.Recorder = UNDEFINED THEN
	|		NULL
	|	ELSE
	|		Cash.Recorder
	|	END AS Recorder,
	|	
	|	Cash.ToReceive_OpeningBalance AS SumOpeningBalance,
	|	Cash.ToReceive_ClosingBalance AS SumClosingBalance
	|
	|FROM
	|	AccumulationRegister.BankAccountCash.BalanceAndTurnovers({&BeginOfPeriod}, {&EndOfPeriod}, Auto) AS Cash
	|";

	Return QueryText;
	
EndFunction

Function QueryTextAdvanceHolderCash()
	
	QueryText = "
	|SELECT
	|	CASE WHEN Cash.SumOpeningBalance > 0 THEN
	|		VALUE(Enum.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName)
	|	ELSE
	|		VALUE(Enum.KindsOfBalanceSheetStatementItems.Liabilities)
	|	END AS IndicatorType,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceAdvanceHolderCash) AS Factor,
	|	
	|	Cash.Organization,
	|	CASE WHEN &ReportCurrency = Cash.Organization.LocalAccountingCurrency THEN
	|		Cash.Organization.LocalAccountingCurrency
	|	WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
	|		&ManagementAccountingCurrency
	|	ELSE
	|		Cash.Currency
	|	END AS Currency,
	|	NULL AS Partner,
	|	Cash.AdvanceHolder AS Dimension,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	|	
	|	Cash.SecondPeriod AS SecondPeriod,
	|	Cash.DayPeriod AS DayPeriod,
	|	Cash.WeekPeriod AS WeekPeriod,
	|	Cash.TenDaysPeriod AS TenDaysPeriod,
	|	Cash.MonthPeriod AS MonthPeriod,
	|	Cash.QuarterPeriod AS QuarterPeriod,
	|	Cash.HalfYearPeriod AS HalfYearPeriod,
	|	Cash.YearPeriod AS YearPeriod,
	|	
	|	CASE WHEN Cash.Recorder = UNDEFINED THEN
	|		NULL
	|	ELSE
	|		Cash.Recorder
	|	END AS Recorder,
	|	
	|	CASE WHEN &ReportCurrency = Cash.Organization.LocalAccountingCurrency THEN
	|		Cash.SumComplOpeningBalance
	|	WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
	|		Cash.SumManOpeningBalance
	|	ELSE
	|		Cash.SumOpeningBalance
	|	END AS SumOpeningBalance,
	|	0 AS SumClosingBalance
	|FROM
	|	AccumulationRegister.AdvanceHolderCash.BalanceAndTurnovers({&BeginOfPeriod}, {&EndOfPeriod}, Auto) AS Cash
	|	
	|UNION ALL
	|	
	|SELECT
	|	CASE WHEN Cash.SumClosingBalance > 0 THEN
	|		VALUE(Enum.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName)
	|	ELSE
	|		VALUE(Enum.KindsOfBalanceSheetStatementItems.Liabilities)
	|	END AS IndicatorType,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceAdvanceHolderCash) AS Factor,
	|	
	|	Cash.Organization,
	|	CASE WHEN &ReportCurrency = Cash.Organization.LocalAccountingCurrency THEN
	|		Cash.Organization.LocalAccountingCurrency
	|	WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
	|		&ManagementAccountingCurrency
	|	ELSE
	|		Cash.Currency
	|	END AS Currency,
	|	NULL AS Partner,
	|	Cash.AdvanceHolder AS Dimension,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	|	
	|	Cash.SecondPeriod AS SecondPeriod,
	|	Cash.DayPeriod AS DayPeriod,
	|	Cash.WeekPeriod AS WeekPeriod,
	|	Cash.TenDaysPeriod AS TenDaysPeriod,
	|	Cash.MonthPeriod AS MonthPeriod,
	|	Cash.QuarterPeriod AS QuarterPeriod,
	|	Cash.HalfYearPeriod AS HalfYearPeriod,
	|	Cash.YearPeriod AS YearPeriod,
	|	
	|	CASE WHEN Cash.Recorder = UNDEFINED THEN
	|		NULL
	|	ELSE
	|		Cash.Recorder
	|	END AS Recorder,
	|	
	|	0 AS SumOpeningBalance,
	|	CASE WHEN &ReportCurrency = Cash.Organization.LocalAccountingCurrency THEN
	|		Cash.SumComplClosingBalance
	|	WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
	|		Cash.SumManClosingBalance
	|	ELSE
	|		Cash.SumClosingBalance
	|	END AS SumClosingBalance
	|FROM
	|	AccumulationRegister.AdvanceHolderCash.BalanceAndTurnovers({&BeginOfPeriod}, {&EndOfPeriod}, Auto) AS Cash
	|";

	Return QueryText;
	
EndFunction

Function QueryTextOtherExpenses()
	
	QueryText = "
	|SELECT
	|	VALUE(Enum.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName) AS IndicatorType,
	|	CASE WHEN OtherExpenses.ExpenseItem.CostAllocationOptionManag
	|		= VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|	THEN
	|		VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceDeferredExpenses)
	|	ELSE
	|		VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceCurrentPeriodExpenses)
	|	END AS Factor,
	|	
	|	OtherExpenses.Organization AS Organization,
	|	&ManagementAccountingCurrency AS Currency,
	|	NULL AS Partner,
	|	OtherExpenses.ExpenseItem AS Dimension,
	|	OtherExpenses.Department AS Department,
	|	
	|	OtherExpenses.SecondPeriod AS SecondPeriod,
	|	OtherExpenses.DayPeriod AS DayPeriod,
	|	OtherExpenses.WeekPeriod AS WeekPeriod,
	|	OtherExpenses.TenDaysPeriod AS TenDaysPeriod,
	|	OtherExpenses.MonthPeriod AS MonthPeriod,
	|	OtherExpenses.QuarterPeriod AS QuarterPeriod,
	|	OtherExpenses.HalfYearPeriod AS HalfYearPeriod,
	|	OtherExpenses.YearPeriod AS YearPeriod,
	|	
	|	CASE WHEN OtherExpenses.Recorder = UNDEFINED THEN
	|		NULL
	|	ELSE
	|		OtherExpenses.Recorder
	|	END AS Recorder,
	|	
	|	OtherExpenses.SumOpeningBalance AS SumOpeningBalance,
	|	OtherExpenses.SumClosingBalance AS SumClosingBalance
	|FROM
	|	AccumulationRegister.OtherExpenses.BalanceAndTurnovers({&BeginOfPeriod}, {&EndOfPeriod}, Auto) AS OtherExpenses
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(Enum.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName) AS IndicatorType,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceCurrentPeriodExpenses) AS Factor,
	|	
	|	OtherExpenses.Organization AS Organization,
	|	&ManagementAccountingCurrency AS Currency,
	|	NULL AS Partner,
	|	OtherExpenses.ExpenseItem AS Dimension,
	|	OtherExpenses.Department AS Department,
	|	
	|	OtherExpenses.SecondPeriod AS SecondPeriod,
	|	OtherExpenses.DayPeriod AS DayPeriod,
	|	OtherExpenses.WeekPeriod AS WeekPeriod,
	|	OtherExpenses.TenDaysPeriod AS TenDaysPeriod,
	|	OtherExpenses.MonthPeriod AS MonthPeriod,
	|	OtherExpenses.QuarterPeriod AS QuarterPeriod,
	|	OtherExpenses.HalfYearPeriod AS HalfYearPeriod,
	|	OtherExpenses.YearPeriod AS YearPeriod,
	|	
	|	CASE WHEN OtherExpenses.Recorder = UNDEFINED THEN
	|		NULL
	|	ELSE
	|		OtherExpenses.Recorder
	|	END AS Recorder,
	|	
	|	OtherExpenses.CostOpeningBalance AS SumOpeningBalance,
	|	OtherExpenses.CostClosingBalance AS SumClosingBalance
	|FROM
	|	AccumulationRegister.ItemisedExpensesLots.BalanceAndTurnovers({&BeginOfPeriod}, {&EndOfPeriod}, Auto) AS OtherExpenses
	|";

	Return QueryText;
	
EndFunction

Function QueryTextCustomersARAPAccounting()
	
	QueryText = "
	|SELECT
	|	VALUE(Enum.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName) AS IndicatorType,
	|	CASE WHEN RegisterAccountingAnalyticsForPartners.Partner = VALUE(Catalog.Partners.OurEnterprise) THEN
	|		VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceOwnCompaniesARAP)
	|	ELSE
	|		VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceCustomersAccountsReceivable)
	|	END AS Factor,
	|	
	|	RegisterAccountingAnalyticsForPartners.Organization,
	|	CASE WHEN &ReportCurrency = RegisterAccountingAnalyticsForPartners.Organization.LocalAccountingCurrency THEN
	|		RegisterAccountingAnalyticsForPartners.Organization.LocalAccountingCurrency
	|	WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
	|		&ManagementAccountingCurrency
	|	ELSE
	|		CustomersARAPAccounting.Currency
	|	END AS Currency,
	|	RegisterAccountingAnalyticsForPartners.Partner AS Partner,
	|	CustomersARAPAccounting.ARAPObject AS Dimension,
	|	ISNULL(CustomersARAPAccounting.ARAPObject.Department,
	|		VALUE(Catalog.BusinessStructure.EmptyRef)) AS Department,
	|	
	|	CustomersARAPAccounting.SecondPeriod AS SecondPeriod,
	|	CustomersARAPAccounting.DayPeriod AS DayPeriod,
	|	CustomersARAPAccounting.WeekPeriod AS WeekPeriod,
	|	CustomersARAPAccounting.TenDaysPeriod AS TenDaysPeriod,
	|	CustomersARAPAccounting.MonthPeriod AS MonthPeriod,
	|	CustomersARAPAccounting.QuarterPeriod AS QuarterPeriod,
	|	CustomersARAPAccounting.HalfYearPeriod AS HalfYearPeriod,
	|	CustomersARAPAccounting.YearPeriod AS YearPeriod,
	|	
	|	CASE 
	|		WHEN CustomersARAPAccounting.Recorder = UNDEFINED THEN
	|			NULL
	|		WHEN NOT RegistrarsOfSettlementsByTerms.DocumentRecorder IS NULL THEN
	|			RegistrarsOfSettlementsByTerms.DocumentRecorder
	|		ELSE
	|			CustomersARAPAccounting.Recorder
	|	END AS Recorder,
	|	
	|	CASE WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
	|		CustomersARAPAccounting.ARAPManOpeningBalance
	|	WHEN &ReportCurrency = RegisterAccountingAnalyticsForPartners.Organization.LocalAccountingCurrency THEN
	|		CustomersARAPAccounting.DebtLocalOpeningBalance
	|	ELSE
	|		CustomersARAPAccounting.DebtOpeningBalance
	|	END AS SumOpeningBalance,
	|	
	|	CASE WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
	|		CustomersARAPAccounting.ARAPManClosingBalance
	|	WHEN &ReportCurrency = RegisterAccountingAnalyticsForPartners.Organization.LocalAccountingCurrency THEN
	|		CustomersARAPAccounting.DebtLocalClosingBalance
	|	ELSE
	|		CustomersARAPAccounting.DebtClosingBalance
	|	END AS SumClosingBalance
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates.BalanceAndTurnovers({&BeginOfPeriod}, {&EndOfPeriod}, Auto) AS CustomersARAPAccounting
	|
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
	|	ON
	|		CustomersARAPAccounting.AccountingDimensionByPartners = RegisterAccountingAnalyticsForPartners.DimensionKey
	|		
	|	LEFT JOIN
	|		RegistrarsOfSettlementsByTerms AS RegistrarsOfSettlementsByTerms
	|	ON
	|		CustomersARAPAccounting.Recorder = RegistrarsOfSettlementsByTerms.Recorder
	|		AND CustomersARAPAccounting.AccountingDimensionByPartners = RegistrarsOfSettlementsByTerms.AccountingDimensionByPartners
	|		AND CustomersARAPAccounting.ARAPObject = RegistrarsOfSettlementsByTerms.ARAPObject
	|		AND CustomersARAPAccounting.Currency = RegistrarsOfSettlementsByTerms.Currency
	|		AND CustomersARAPAccounting.ARAPDocument = RegistrarsOfSettlementsByTerms.ARAPDocument
	|	
	|UNION ALL
	|
	|SELECT
	|	VALUE(Enum.KindsOfBalanceSheetStatementItems.Liabilities) AS IndicatorType,
	|	CASE WHEN RegisterAccountingAnalyticsForPartners.Partner = VALUE(Catalog.Partners.OurEnterprise) THEN
	|		VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceAccountsPayblesIntercompnay)
	|	ELSE
	|		VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalancePrepaymentsFromCustomerLayout)
	|	END AS Factor,
	|	
	|	RegisterAccountingAnalyticsForPartners.Organization,
	|	CASE WHEN &ReportCurrency = RegisterAccountingAnalyticsForPartners.Organization.LocalAccountingCurrency THEN
	|		RegisterAccountingAnalyticsForPartners.Organization.LocalAccountingCurrency
	|	WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
	|		&ManagementAccountingCurrency
	|	ELSE
	|		CustomersARAPAccounting.Currency
	|	END AS Currency,
	|	RegisterAccountingAnalyticsForPartners.Partner AS Partner,
	|	CustomersARAPAccounting.ARAPObject AS Dimension,
	|	ISNULL(CustomersARAPAccounting.ARAPObject.Department,
	|		VALUE(Catalog.BusinessStructure.EmptyRef)) AS Department,
	|	
	|	CustomersARAPAccounting.SecondPeriod AS SecondPeriod,
	|	CustomersARAPAccounting.DayPeriod AS DayPeriod,
	|	CustomersARAPAccounting.WeekPeriod AS WeekPeriod,
	|	CustomersARAPAccounting.TenDaysPeriod AS TenDaysPeriod,
	|	CustomersARAPAccounting.MonthPeriod AS MonthPeriod,
	|	CustomersARAPAccounting.QuarterPeriod AS QuarterPeriod,
	|	CustomersARAPAccounting.HalfYearPeriod AS HalfYearPeriod,
	|	CustomersARAPAccounting.YearPeriod AS YearPeriod,
	|	
	|	CASE 
	|		WHEN CustomersARAPAccounting.Recorder = UNDEFINED THEN
	|			NULL
	|		WHEN NOT RegistrarsOfSettlementsByTerms.DocumentRecorder IS NULL THEN
	|			RegistrarsOfSettlementsByTerms.DocumentRecorder
	|		ELSE
	|			CustomersARAPAccounting.Recorder
	|	END AS Recorder,
	|	
	|	CASE WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
	|		-CustomersARAPAccounting.PrepaymentManOpeningBalance
	|	WHEN &ReportCurrency = RegisterAccountingAnalyticsForPartners.Organization.LocalAccountingCurrency THEN
	|		-CustomersARAPAccounting.PrepaymentLocalOpeningBalance
	|	ELSE
	|		-CustomersARAPAccounting.PrepaymentOpeningBalance
	|	END AS SumOpeningBalance,
	|	
	|	CASE WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
	|		-CustomersARAPAccounting.PrepaymentManClosingBalance
	|	WHEN &ReportCurrency = RegisterAccountingAnalyticsForPartners.Organization.LocalAccountingCurrency THEN
	|		-CustomersARAPAccounting.PrepaymentLocalClosingBalance
	|	ELSE
	|		-CustomersARAPAccounting.PrepaymentClosingBalance
	|	END AS SumClosingBalance
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates.BalanceAndTurnovers({&BeginOfPeriod}, {&EndOfPeriod}, Auto) AS CustomersARAPAccounting
	|
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
	|	ON
	|		CustomersARAPAccounting.AccountingDimensionByPartners = RegisterAccountingAnalyticsForPartners.DimensionKey
	|		
	|	LEFT JOIN
	|		RegistrarsOfSettlementsByTerms AS RegistrarsOfSettlementsByTerms
	|	ON
	|		CustomersARAPAccounting.Recorder = RegistrarsOfSettlementsByTerms.Recorder
	|		AND CustomersARAPAccounting.AccountingDimensionByPartners = RegistrarsOfSettlementsByTerms.AccountingDimensionByPartners
	|		AND CustomersARAPAccounting.ARAPObject = RegistrarsOfSettlementsByTerms.ARAPObject
	|		AND CustomersARAPAccounting.Currency = RegistrarsOfSettlementsByTerms.Currency
	|		AND CustomersARAPAccounting.ARAPDocument = RegistrarsOfSettlementsByTerms.ARAPDocument
	|	
	|UNION ALL
	|
	|SELECT
	|	VALUE(Enum.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName) AS IndicatorType,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceCustomersAccountsReceivable) AS Factor,
	|	
	|	RegisterAccountingAnalyticsForPartners.Organization,
	|	CustomersARAPAccounting.Currency AS Currency,
	|	RegisterAccountingAnalyticsForPartners.Partner AS Partner,
	|	CustomersARAPAccounting.ARAPObject AS Dimension,
	|	ISNULL(CustomersARAPAccounting.ARAPObject.Department,
	|		VALUE(Catalog.BusinessStructure.EmptyRef)) AS Department,
	|	
	|	CustomersARAPAccounting.SecondPeriod AS SecondPeriod,
	|	CustomersARAPAccounting.DayPeriod AS DayPeriod,
	|	CustomersARAPAccounting.WeekPeriod AS WeekPeriod,
	|	CustomersARAPAccounting.TenDaysPeriod AS TenDaysPeriod,
	|	CustomersARAPAccounting.MonthPeriod AS MonthPeriod,
	|	CustomersARAPAccounting.QuarterPeriod AS QuarterPeriod,
	|	CustomersARAPAccounting.HalfYearPeriod AS HalfYearPeriod,
	|	CustomersARAPAccounting.YearPeriod AS YearPeriod,
	|	
	|	CASE WHEN CustomersARAPAccounting.Recorder = UNDEFINED THEN
	|		NULL
	|	ELSE
	|		CustomersARAPAccounting.Recorder
	|	END AS Recorder,
	|	
	|	-CustomersARAPAccounting.BeingPaidOpeningBalance AS SumOpeningBalance,
	|	-CustomersARAPAccounting.BeingPaidClosingBalance AS SumClosingBalance
	|
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting.BalanceAndTurnovers({&BeginOfPeriod}, {&EndOfPeriod}, Auto) AS CustomersARAPAccounting
	|
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
	|	ON
	|		CustomersARAPAccounting.AccountingDimensionByPartners = RegisterAccountingAnalyticsForPartners.DimensionKey
	|	
	|UNION ALL
	|
	|SELECT
	|	VALUE(Enum.KindsOfBalanceSheetStatementItems.Liabilities) AS IndicatorType,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalancePrepaymentsFromCustomerLayout) AS Factor,
	|	
	|	TableOfGiftCertificates.Organization,
	|	TableOfGiftCertificates.Currency AS Currency,
	|	VALUE(Catalog.Partners.RetailCustomer) AS Partner,
	|	TableOfGiftCertificates.GiftCertificateKind AS Dimension,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	|	
	|	BalanceAndTurnovers.SecondPeriod AS SecondPeriod,
	|	BalanceAndTurnovers.DayPeriod AS DayPeriod,
	|	BalanceAndTurnovers.WeekPeriod AS WeekPeriod,
	|	BalanceAndTurnovers.TenDaysPeriod AS TenDaysPeriod,
	|	BalanceAndTurnovers.MonthPeriod AS MonthPeriod,
	|	BalanceAndTurnovers.QuarterPeriod AS QuarterPeriod,
	|	BalanceAndTurnovers.HalfYearPeriod AS HalfYearPeriod,
	|	BalanceAndTurnovers.YearPeriod AS YearPeriod,
	|	
	|	CASE WHEN BalanceAndTurnovers.Recorder = UNDEFINED THEN
	|		NULL
	|	ELSE
	|		BalanceAndTurnovers.Recorder
	|	END AS Recorder,
	|	
	|	-BalanceAndTurnovers.SumOpeningBalance AS SumOpeningBalance,
	|	-BalanceAndTurnovers.SumClosingBalance AS SumClosingBalance
	|
	|FROM
	|	AccumulationRegister.GiftCertificates.BalanceAndTurnovers(
	|			{(&BeginOfPeriod)},
	|			{(&EndOfPeriod)},
	|			Auto,
	|			,
	|			GiftCertificate IN
	|				(SELECT
	|					T.Ref
	|				FROM
	|					TableOfGiftCertificates AS T)) AS BalanceAndTurnovers
	|		LEFT JOIN TableOfGiftCertificates AS TableOfGiftCertificates
	|		ON TableOfGiftCertificates.Ref = BalanceAndTurnovers.GiftCertificate
	|";
	
	#Region OldCalculationArchitecture
	If Not GetFunctionalOption("NewOnlineARAPAccounting") Then
		QueryText = "
		|SELECT
		|	VALUE(Enum.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName) AS IndicatorType,
		|	CASE WHEN RegisterAccountingAnalyticsForPartners.Partner = VALUE(Catalog.Partners.OurEnterprise) THEN
		|		VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceOwnCompaniesARAP)
		|	ELSE
		|		VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceCustomersAccountsReceivable)
		|	END AS Factor,
		|	
		|	RegisterAccountingAnalyticsForPartners.Organization,
		|	CASE WHEN &ReportCurrency = RegisterAccountingAnalyticsForPartners.Organization.LocalAccountingCurrency THEN
		|		RegisterAccountingAnalyticsForPartners.Organization.LocalAccountingCurrency
		|	WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
		|		&ManagementAccountingCurrency
		|	ELSE
		|		CustomersARAPAccounting.Currency
		|	END AS Currency,
		|	RegisterAccountingAnalyticsForPartners.Partner AS Partner,
		|	CustomersARAPAccounting.SalesOrder AS Dimension,
		|	ISNULL(CustomersARAPAccounting.SalesOrder.Department,
		|		VALUE(Catalog.BusinessStructure.EmptyRef)) AS Department,
		|	
		|	CustomersARAPAccounting.SecondPeriod AS SecondPeriod,
		|	CustomersARAPAccounting.DayPeriod AS DayPeriod,
		|	CustomersARAPAccounting.WeekPeriod AS WeekPeriod,
		|	CustomersARAPAccounting.TenDaysPeriod AS TenDaysPeriod,
		|	CustomersARAPAccounting.MonthPeriod AS MonthPeriod,
		|	CustomersARAPAccounting.QuarterPeriod AS QuarterPeriod,
		|	CustomersARAPAccounting.HalfYearPeriod AS HalfYearPeriod,
		|	CustomersARAPAccounting.YearPeriod AS YearPeriod,
		|	
		|	CASE WHEN CustomersARAPAccounting.Recorder = UNDEFINED THEN
		|		NULL
		|	ELSE
		|		CustomersARAPAccounting.Recorder
		|	END AS Recorder,
		|	
		|	CASE WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
		|		CustomersARAPAccounting.ARAPManOpeningBalance
		|	WHEN &ReportCurrency = RegisterAccountingAnalyticsForPartners.Organization.LocalAccountingCurrency THEN
		|		CustomersARAPAccounting.DebtLocalOpeningBalance
		|	ELSE
		|		CustomersARAPAccounting.DebtOpeningBalance
		|	END AS SumOpeningBalance,
		|	
		|	CASE WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
		|		CustomersARAPAccounting.ARAPManClosingBalance
		|	WHEN &ReportCurrency = RegisterAccountingAnalyticsForPartners.Organization.LocalAccountingCurrency THEN
		|		CustomersARAPAccounting.DebtLocalClosingBalance
		|	ELSE
		|		CustomersARAPAccounting.DebtClosingBalance
		|	END AS SumClosingBalance
		|FROM
		|	AccumulationRegister.CustomersARAPAccountingByDocuments.BalanceAndTurnovers({&BeginOfPeriod}, {&EndOfPeriod}, Auto) AS CustomersARAPAccounting
		|
		|	LEFT JOIN
		|		InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
		|	ON
		|		CustomersARAPAccounting.AccountingDimensionByPartners = RegisterAccountingAnalyticsForPartners.DimensionKey
		|	
		|UNION ALL
		|
		|SELECT
		|	VALUE(Enum.KindsOfBalanceSheetStatementItems.Liabilities) AS IndicatorType,
		|	CASE WHEN RegisterAccountingAnalyticsForPartners.Partner = VALUE(Catalog.Partners.OurEnterprise) THEN
		|		VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceAccountsPayblesIntercompnay)
		|	ELSE
		|		VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalancePrepaymentsFromCustomerLayout)
		|	END AS Factor,
		|	
		|	RegisterAccountingAnalyticsForPartners.Organization,
		|	CASE WHEN &ReportCurrency = RegisterAccountingAnalyticsForPartners.Organization.LocalAccountingCurrency THEN
		|		RegisterAccountingAnalyticsForPartners.Organization.LocalAccountingCurrency
		|	WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
		|		&ManagementAccountingCurrency
		|	ELSE
		|		CustomersARAPAccounting.Currency
		|	END AS Currency,
		|	RegisterAccountingAnalyticsForPartners.Partner AS Partner,
		|	CustomersARAPAccounting.SalesOrder AS Dimension,
		|	ISNULL(CustomersARAPAccounting.SalesOrder.Department,
		|		VALUE(Catalog.BusinessStructure.EmptyRef)) AS Department,
		|	
		|	CustomersARAPAccounting.SecondPeriod AS SecondPeriod,
		|	CustomersARAPAccounting.DayPeriod AS DayPeriod,
		|	CustomersARAPAccounting.WeekPeriod AS WeekPeriod,
		|	CustomersARAPAccounting.TenDaysPeriod AS TenDaysPeriod,
		|	CustomersARAPAccounting.MonthPeriod AS MonthPeriod,
		|	CustomersARAPAccounting.QuarterPeriod AS QuarterPeriod,
		|	CustomersARAPAccounting.HalfYearPeriod AS HalfYearPeriod,
		|	CustomersARAPAccounting.YearPeriod AS YearPeriod,
		|	
		|	CASE WHEN CustomersARAPAccounting.Recorder = UNDEFINED THEN
		|		NULL
		|	ELSE
		|		CustomersARAPAccounting.Recorder
		|	END AS Recorder,
		|	
		|	CASE WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
		|		CustomersARAPAccounting.PrepaymentManOpeningBalance
		|	WHEN &ReportCurrency = RegisterAccountingAnalyticsForPartners.Organization.LocalAccountingCurrency THEN
		|		CustomersARAPAccounting.PrepaymentLocalOpeningBalance
		|	ELSE
		|		CustomersARAPAccounting.PrepaymentOpeningBalance
		|	END AS SumOpeningBalance,
		|	
		|	CASE WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
		|		CustomersARAPAccounting.PrepaymentManClosingBalance
		|	WHEN &ReportCurrency = RegisterAccountingAnalyticsForPartners.Organization.LocalAccountingCurrency THEN
		|		CustomersARAPAccounting.PrepaymentLocalClosingBalance
		|	ELSE
		|		CustomersARAPAccounting.PrepaymentClosingBalance
		|	END AS SumClosingBalance
		|FROM
		|	AccumulationRegister.CustomersARAPAccountingByDocuments.BalanceAndTurnovers({&BeginOfPeriod}, {&EndOfPeriod}, Auto) AS CustomersARAPAccounting
		|
		|	LEFT JOIN
		|		InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
		|	ON
		|		CustomersARAPAccounting.AccountingDimensionByPartners = RegisterAccountingAnalyticsForPartners.DimensionKey
		|	
		|UNION ALL
		|
		|SELECT
		|	VALUE(Enum.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName) AS IndicatorType,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceCustomersAccountsReceivable) AS Factor,
		|	
		|	RegisterAccountingAnalyticsForPartners.Organization,
		|	CustomersARAPAccounting.Currency AS Currency,
		|	RegisterAccountingAnalyticsForPartners.Partner AS Partner,
		|	CustomersARAPAccounting.ARAPObject AS Dimension,
		|	ISNULL(CustomersARAPAccounting.ARAPObject.Department,
		|		VALUE(Catalog.BusinessStructure.EmptyRef)) AS Department,
		|	
		|	CustomersARAPAccounting.SecondPeriod AS SecondPeriod,
		|	CustomersARAPAccounting.DayPeriod AS DayPeriod,
		|	CustomersARAPAccounting.WeekPeriod AS WeekPeriod,
		|	CustomersARAPAccounting.TenDaysPeriod AS TenDaysPeriod,
		|	CustomersARAPAccounting.MonthPeriod AS MonthPeriod,
		|	CustomersARAPAccounting.QuarterPeriod AS QuarterPeriod,
		|	CustomersARAPAccounting.HalfYearPeriod AS HalfYearPeriod,
		|	CustomersARAPAccounting.YearPeriod AS YearPeriod,
		|	
		|	CASE WHEN CustomersARAPAccounting.Recorder = UNDEFINED THEN
		|		NULL
		|	ELSE
		|		CustomersARAPAccounting.Recorder
		|	END AS Recorder,
		|	
		|	-CustomersARAPAccounting.BeingPaidOpeningBalance AS SumOpeningBalance,
		|	-CustomersARAPAccounting.BeingPaidClosingBalance AS SumClosingBalance
		|
		|FROM
		|	AccumulationRegister.CustomersARAPAccounting.BalanceAndTurnovers({&BeginOfPeriod}, {&EndOfPeriod}, Auto) AS CustomersARAPAccounting
		|
		|	LEFT JOIN
		|		InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
		|	ON
		|		CustomersARAPAccounting.AccountingDimensionByPartners = RegisterAccountingAnalyticsForPartners.DimensionKey
		|	
		|UNION ALL
		|
		|SELECT
		|	VALUE(Enum.KindsOfBalanceSheetStatementItems.Liabilities) AS IndicatorType,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalancePrepaymentsFromCustomerLayout) AS Factor,
		|	
		|	BalanceAndTurnovers.GiftCertificate.Organization,
		|	BalanceAndTurnovers.GiftCertificate.Owner.Currency AS Currency,
		|	VALUE(Catalog.Partners.RetailCustomer) AS Partner,
		|	BalanceAndTurnovers.GiftCertificate.Owner AS Dimension,
		|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
		|	
		|	BalanceAndTurnovers.SecondPeriod AS SecondPeriod,
		|	BalanceAndTurnovers.DayPeriod AS DayPeriod,
		|	BalanceAndTurnovers.WeekPeriod AS WeekPeriod,
		|	BalanceAndTurnovers.TenDaysPeriod AS TenDaysPeriod,
		|	BalanceAndTurnovers.MonthPeriod AS MonthPeriod,
		|	BalanceAndTurnovers.QuarterPeriod AS QuarterPeriod,
		|	BalanceAndTurnovers.HalfYearPeriod AS HalfYearPeriod,
		|	BalanceAndTurnovers.YearPeriod AS YearPeriod,
		|	
		|	CASE WHEN BalanceAndTurnovers.Recorder = UNDEFINED THEN
		|		NULL
		|	ELSE
		|		BalanceAndTurnovers.Recorder
		|	END AS Recorder,
		|	
		|	-BalanceAndTurnovers.SumOpeningBalance AS SumOpeningBalance,
		|	-BalanceAndTurnovers.SumClosingBalance AS SumClosingBalance
		|
		|FROM
		|	AccumulationRegister.GiftCertificates.BalanceAndTurnovers({&BeginOfPeriod}, {&EndOfPeriod}, Auto) AS BalanceAndTurnovers
		|
		|";
	EndIf;
	#EndRegion

	Return QueryText;
	
EndFunction

Function QueryTextVendorsARAPAccounting()
	
	QueryText = "
	|SELECT
	|	VALUE(Enum.KindsOfBalanceSheetStatementItems.Liabilities) AS IndicatorType,
	|	CASE WHEN RegisterAccountingAnalyticsForPartners.Partner = VALUE(Catalog.Partners.OurEnterprise) THEN
	|		VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceAccountsPayblesIntercompnay)
	|	ELSE
	|		VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceVendorAccountsReceivable)
	|	END AS Factor,
	|	
	|	RegisterAccountingAnalyticsForPartners.Organization,
	|	CASE WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
	|		&ManagementAccountingCurrency
	|	WHEN &ReportCurrency = RegisterAccountingAnalyticsForPartners.Organization.LocalAccountingCurrency THEN
	|		RegisterAccountingAnalyticsForPartners.Organization.LocalAccountingCurrency
	|	ELSE
	|		VendorsARAPAccounting.Currency
	|	END AS Currency,
	|	RegisterAccountingAnalyticsForPartners.Partner AS Partner,
	|	VendorsARAPAccounting.ARAPObject AS Dimension,
	|	ISNULL(VendorsARAPAccounting.ARAPObject.Department,
	|		VALUE(Catalog.BusinessStructure.EmptyRef)) AS Department,
	|	
	|	VendorsARAPAccounting.SecondPeriod AS SecondPeriod,
	|	VendorsARAPAccounting.DayPeriod AS DayPeriod,
	|	VendorsARAPAccounting.WeekPeriod AS WeekPeriod,
	|	VendorsARAPAccounting.TenDaysPeriod AS TenDaysPeriod,
	|	VendorsARAPAccounting.MonthPeriod AS MonthPeriod,
	|	VendorsARAPAccounting.QuarterPeriod AS QuarterPeriod,
	|	VendorsARAPAccounting.HalfYearPeriod AS HalfYearPeriod,
	|	VendorsARAPAccounting.YearPeriod AS YearPeriod,
	|	
	|	CASE 
	|		WHEN VendorsARAPAccounting.Recorder = UNDEFINED THEN
	|			NULL
	|		WHEN NOT RegistrarsOfSettlementsByTerms.DocumentRecorder IS NULL THEN
	|			RegistrarsOfSettlementsByTerms.DocumentRecorder
	|		ELSE
	|			VendorsARAPAccounting.Recorder
	|	END AS Recorder,
	|	
	|	CASE WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
	|		-VendorsARAPAccounting.ARAPManOpeningBalance
	|	WHEN &ReportCurrency = RegisterAccountingAnalyticsForPartners.Organization.LocalAccountingCurrency THEN
	|		-VendorsARAPAccounting.DebtLocalOpeningBalance
	|	ELSE
	|		-VendorsARAPAccounting.DebtOpeningBalance
	|	END AS SumOpeningBalance,
	|
	|	CASE WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
	|		-VendorsARAPAccounting.ARAPManClosingBalance
	|	WHEN &ReportCurrency = RegisterAccountingAnalyticsForPartners.Organization.LocalAccountingCurrency THEN
	|		-VendorsARAPAccounting.DebtLocalClosingBalance
	|	ELSE
	|		-VendorsARAPAccounting.DebtClosingBalance
	|	END AS SumClosingBalance
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDueDates.BalanceAndTurnovers({&BeginOfPeriod}, {&EndOfPeriod}, Auto) AS VendorsARAPAccounting
	|
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
	|	ON
	|		VendorsARAPAccounting.AccountingDimensionByPartners = RegisterAccountingAnalyticsForPartners.DimensionKey
	|		
	|	LEFT JOIN
	|		RegistrarsOfSettlementsByTerms AS RegistrarsOfSettlementsByTerms
	|	ON
	|		VendorsARAPAccounting.Recorder = RegistrarsOfSettlementsByTerms.Recorder
	|		AND VendorsARAPAccounting.AccountingDimensionByPartners = RegistrarsOfSettlementsByTerms.AccountingDimensionByPartners
	|		AND VendorsARAPAccounting.ARAPObject = RegistrarsOfSettlementsByTerms.ARAPObject
	|		AND VendorsARAPAccounting.Currency = RegistrarsOfSettlementsByTerms.Currency
	|		AND VendorsARAPAccounting.ARAPDocument = RegistrarsOfSettlementsByTerms.ARAPDocument
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(Enum.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName) AS IndicatorType,
	|	CASE WHEN RegisterAccountingAnalyticsForPartners.Partner = VALUE(Catalog.Partners.OurEnterprise) THEN
	|		VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceOwnCompaniesARAP)
	|	ELSE
	|		VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalancePrepaymentsToVendor_)
	|	END AS Factor,
	|	
	|	RegisterAccountingAnalyticsForPartners.Organization,
	|	CASE WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
	|		&ManagementAccountingCurrency
	|	WHEN &ReportCurrency = RegisterAccountingAnalyticsForPartners.Organization.LocalAccountingCurrency THEN
	|		RegisterAccountingAnalyticsForPartners.Organization.LocalAccountingCurrency
	|	ELSE
	|		VendorsARAPAccounting.Currency
	|	END AS Currency,
	|	RegisterAccountingAnalyticsForPartners.Partner AS Partner,
	|	VendorsARAPAccounting.ARAPObject AS Dimension,
	|	ISNULL(VendorsARAPAccounting.ARAPObject.Department,
	|		VALUE(Catalog.BusinessStructure.EmptyRef)) AS Department,
	|	
	|	VendorsARAPAccounting.SecondPeriod AS SecondPeriod,
	|	VendorsARAPAccounting.DayPeriod AS DayPeriod,
	|	VendorsARAPAccounting.WeekPeriod AS WeekPeriod,
	|	VendorsARAPAccounting.TenDaysPeriod AS TenDaysPeriod,
	|	VendorsARAPAccounting.MonthPeriod AS MonthPeriod,
	|	VendorsARAPAccounting.QuarterPeriod AS QuarterPeriod,
	|	VendorsARAPAccounting.HalfYearPeriod AS HalfYearPeriod,
	|	VendorsARAPAccounting.YearPeriod AS YearPeriod,
	|	
	|	CASE 
	|		WHEN VendorsARAPAccounting.Recorder = UNDEFINED THEN
	|			NULL
	|		WHEN NOT RegistrarsOfSettlementsByTerms.DocumentRecorder IS NULL THEN
	|			RegistrarsOfSettlementsByTerms.DocumentRecorder
	|		ELSE
	|			VendorsARAPAccounting.Recorder
	|	END AS Recorder,
	|	
	|	CASE WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
	|		VendorsARAPAccounting.PrepaymentManOpeningBalance
	|	WHEN &ReportCurrency = RegisterAccountingAnalyticsForPartners.Organization.LocalAccountingCurrency THEN
	|		VendorsARAPAccounting.PrepaymentLocalOpeningBalance
	|	ELSE
	|		VendorsARAPAccounting.PrepaymentOpeningBalance
	|	END AS SumOpeningBalance,
	|
	|	CASE WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
	|		VendorsARAPAccounting.PrepaymentManClosingBalance
	|	WHEN &ReportCurrency = RegisterAccountingAnalyticsForPartners.Organization.LocalAccountingCurrency THEN
	|		VendorsARAPAccounting.PrepaymentLocalClosingBalance
	|	ELSE
	|		VendorsARAPAccounting.PrepaymentClosingBalance
	|	END AS SumClosingBalance
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDueDates.BalanceAndTurnovers({&BeginOfPeriod}, {&EndOfPeriod}, Auto) AS VendorsARAPAccounting
	|
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
	|	ON
	|		VendorsARAPAccounting.AccountingDimensionByPartners = RegisterAccountingAnalyticsForPartners.DimensionKey
	|		
	|	LEFT JOIN
	|		RegistrarsOfSettlementsByTerms AS RegistrarsOfSettlementsByTerms
	|	ON
	|		VendorsARAPAccounting.Recorder = RegistrarsOfSettlementsByTerms.Recorder
	|		AND VendorsARAPAccounting.AccountingDimensionByPartners = RegistrarsOfSettlementsByTerms.AccountingDimensionByPartners
	|		AND VendorsARAPAccounting.ARAPObject = RegistrarsOfSettlementsByTerms.ARAPObject
	|		AND VendorsARAPAccounting.Currency = RegistrarsOfSettlementsByTerms.Currency
	|		AND VendorsARAPAccounting.ARAPDocument = RegistrarsOfSettlementsByTerms.ARAPDocument
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(Enum.KindsOfBalanceSheetStatementItems.Liabilities) AS IndicatorType,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceVendorAccountsReceivable) AS Factor,
	|	
	|	Calculations.InventoryOwnerAttribute.Organization,
	|	Calculations.InventoryOwnerAttribute.Currency AS Currency,
	|	Calculations.InventoryOwnerAttribute.GoodsOwner AS Partner,
	|	Calculations.ItemsLocationAttributes.Products AS Dimension,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	|	
	|	Calculations.SecondPeriod AS SecondPeriod,
	|	Calculations.DayPeriod AS DayPeriod,
	|	Calculations.WeekPeriod AS WeekPeriod,
	|	Calculations.TenDaysPeriod AS TenDaysPeriod,
	|	Calculations.MonthPeriod AS MonthPeriod,
	|	Calculations.QuarterPeriod AS QuarterPeriod,
	|	Calculations.HalfYearPeriod AS HalfYearPeriod,
	|	Calculations.YearPeriod AS YearPeriod,
	|	
	|	CASE WHEN Calculations.Recorder = UNDEFINED THEN
	|		NULL
	|	ELSE
	|		Calculations.Recorder
	|	END AS Recorder,
	|	
	|	CASE WHEN Calculations.RevenueAmountOpeningBalance > 0 THEN
	|		-Calculations.RevenueAmountOpeningBalance
	|	ELSE
	|		0
	|	END AS SumOpeningBalance,
	|
	|	CASE WHEN Calculations.RevenueAmountClosingBalance > 0 THEN
	|		-Calculations.RevenueAmountClosingBalance
	|	ELSE
	|		0
	|	END AS SumClosingBalance
	|FROM
	|	AccumulationRegister.GoodsToBeRegisteredInReportsToConsignor.BalanceAndTurnovers({&BeginOfPeriod}, {&EndOfPeriod}, Auto) AS Calculations
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(Enum.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName) AS IndicatorType,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalancePrepaymentsToVendor_) AS Factor,
	|	
	|	Calculations.InventoryOwnerAttribute.Organization,
	|	Calculations.InventoryOwnerAttribute.Currency AS Currency,
	|	Calculations.InventoryOwnerAttribute.GoodsOwner AS Partner,
	|	Calculations.ItemsLocationAttributes.Products AS Dimension,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	|	
	|	Calculations.SecondPeriod AS SecondPeriod,
	|	Calculations.DayPeriod AS DayPeriod,
	|	Calculations.WeekPeriod AS WeekPeriod,
	|	Calculations.TenDaysPeriod AS TenDaysPeriod,
	|	Calculations.MonthPeriod AS MonthPeriod,
	|	Calculations.QuarterPeriod AS QuarterPeriod,
	|	Calculations.HalfYearPeriod AS HalfYearPeriod,
	|	Calculations.YearPeriod AS YearPeriod,
	|	
	|	CASE WHEN Calculations.Recorder = UNDEFINED THEN
	|		NULL
	|	ELSE
	|		Calculations.Recorder
	|	END AS Recorder,
	|	
	|	CASE WHEN Calculations.RevenueAmountOpeningBalance < 0 THEN
	|		-Calculations.RevenueAmountOpeningBalance
	|	ELSE
	|		0
	|	END AS SumOpeningBalance,
	|
	|	CASE WHEN Calculations.RevenueAmountClosingBalance < 0 THEN
	|		-Calculations.RevenueAmountClosingBalance
	|	ELSE
	|		0
	|	END AS SumClosingBalance
	|FROM
	|	AccumulationRegister.GoodsToBeRegisteredInReportsToConsignor.BalanceAndTurnovers({&BeginOfPeriod}, {&EndOfPeriod}, Auto) AS Calculations
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(Enum.KindsOfBalanceSheetStatementItems.Liabilities) AS IndicatorType,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceVendorAccountsReceivable) AS Factor,
	|	
	|	Calculations.DocumentInflow.Organization,
	|	Calculations.DocumentInflow.ARAPCurrency AS Currency,
	|	Calculations.Partner,
	|	Calculations.Products AS Dimension,
	|	Calculations.DocumentInflow.Department AS Department,
	|	
	|	Calculations.SecondPeriod AS SecondPeriod,
	|	Calculations.DayPeriod AS DayPeriod,
	|	Calculations.WeekPeriod AS WeekPeriod,
	|	Calculations.TenDaysPeriod AS TenDaysPeriod,
	|	Calculations.MonthPeriod AS MonthPeriod,
	|	Calculations.QuarterPeriod AS QuarterPeriod,
	|	Calculations.HalfYearPeriod AS HalfYearPeriod,
	|	Calculations.YearPeriod AS YearPeriod,
	|	
	|	CASE WHEN Calculations.Recorder = UNDEFINED THEN
	|		NULL
	|	ELSE
	|		Calculations.Recorder
	|	END AS Recorder,
	|	
	|	CASE WHEN Calculations.SumOpeningBalance > 0 THEN
	|		-Calculations.SumOpeningBalance
	|	ELSE
	|		0
	|	END AS SumOpeningBalance,
	|
	|	CASE WHEN Calculations.SumClosingBalance > 0 THEN
	|		-Calculations.SumClosingBalance
	|	ELSE
	|		0
	|	END AS SumClosingBalance
	|FROM
	|	AccumulationRegister.ReceivedReturnablePackaging.BalanceAndTurnovers({&BeginOfPeriod}, {&EndOfPeriod}, Auto,, NOT DepositIsRequired) AS Calculations
	|";
	
	#Region OldCalculationArchitecture
	If Not GetFunctionalOption("NewOnlineARAPAccounting") Then
		QueryText = "	
		|SELECT
		|	VALUE(Enum.KindsOfBalanceSheetStatementItems.Liabilities) AS IndicatorType,
		|	CASE WHEN RegisterAccountingAnalyticsForPartners.Partner = VALUE(Catalog.Partners.OurEnterprise) THEN
		|		VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceAccountsPayblesIntercompnay)
		|	ELSE
		|		VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceVendorAccountsReceivable)
		|	END AS Factor,
		|	
		|	RegisterAccountingAnalyticsForPartners.Organization,
		|	CASE WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
		|		&ManagementAccountingCurrency
		|	WHEN &ReportCurrency = RegisterAccountingAnalyticsForPartners.Organization.LocalAccountingCurrency THEN
		|		RegisterAccountingAnalyticsForPartners.Organization.LocalAccountingCurrency
		|	ELSE
		|		VendorsARAPAccounting.Currency
		|	END AS Currency,
		|	RegisterAccountingAnalyticsForPartners.Partner AS Partner,
		|	VendorsARAPAccounting.PurchaseOrder AS Dimension,
		|	ISNULL(VendorsARAPAccounting.PurchaseOrder.Department,
		|		VALUE(Catalog.BusinessStructure.EmptyRef)) AS Department,
		|	
		|	VendorsARAPAccounting.SecondPeriod AS SecondPeriod,
		|	VendorsARAPAccounting.DayPeriod AS DayPeriod,
		|	VendorsARAPAccounting.WeekPeriod AS WeekPeriod,
		|	VendorsARAPAccounting.TenDaysPeriod AS TenDaysPeriod,
		|	VendorsARAPAccounting.MonthPeriod AS MonthPeriod,
		|	VendorsARAPAccounting.QuarterPeriod AS QuarterPeriod,
		|	VendorsARAPAccounting.HalfYearPeriod AS HalfYearPeriod,
		|	VendorsARAPAccounting.YearPeriod AS YearPeriod,
		|	
		|	CASE WHEN VendorsARAPAccounting.Recorder = UNDEFINED THEN
		|		NULL
		|	ELSE
		|		VendorsARAPAccounting.Recorder
		|	END AS Recorder,
		|	
		|	CASE WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
		|		VendorsARAPAccounting.ARAPManOpeningBalance
		|	WHEN &ReportCurrency = RegisterAccountingAnalyticsForPartners.Organization.LocalAccountingCurrency THEN
		|		VendorsARAPAccounting.DebtLocalOpeningBalance
		|	ELSE
		|		VendorsARAPAccounting.DebtOpeningBalance
		|	END AS SumOpeningBalance,
		|
		|	CASE WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
		|		VendorsARAPAccounting.ARAPManClosingBalance
		|	WHEN &ReportCurrency = RegisterAccountingAnalyticsForPartners.Organization.LocalAccountingCurrency THEN
		|		VendorsARAPAccounting.DebtLocalClosingBalance
		|	ELSE
		|		VendorsARAPAccounting.DebtClosingBalance
		|	END AS SumClosingBalance
		|FROM
		|	AccumulationRegister.VendorsARAPAccountingByDocuments.BalanceAndTurnovers({&BeginOfPeriod}, {&EndOfPeriod}, Auto) AS VendorsARAPAccounting
		|
		|	LEFT JOIN
		|		InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
		|	ON
		|		VendorsARAPAccounting.AccountingDimensionByPartners = RegisterAccountingAnalyticsForPartners.DimensionKey
		|
		|UNION ALL
		|
		|SELECT
		|	VALUE(Enum.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName) AS IndicatorType,
		|	CASE WHEN RegisterAccountingAnalyticsForPartners.Partner = VALUE(Catalog.Partners.OurEnterprise) THEN
		|		VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceOwnCompaniesARAP)
		|	ELSE
		|		VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalancePrepaymentsToVendor_)
		|	END AS Factor,
		|	
		|	RegisterAccountingAnalyticsForPartners.Organization,
		|	CASE WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
		|		&ManagementAccountingCurrency
		|	WHEN &ReportCurrency = RegisterAccountingAnalyticsForPartners.Organization.LocalAccountingCurrency THEN
		|		RegisterAccountingAnalyticsForPartners.Organization.LocalAccountingCurrency
		|	ELSE
		|		VendorsARAPAccounting.Currency
		|	END AS Currency,
		|	RegisterAccountingAnalyticsForPartners.Partner AS Partner,
		|	VendorsARAPAccounting.PurchaseOrder AS Dimension,
		|	ISNULL(VendorsARAPAccounting.PurchaseOrder.Department,
		|		VALUE(Catalog.BusinessStructure.EmptyRef)) AS Department,
		|	
		|	VendorsARAPAccounting.SecondPeriod AS SecondPeriod,
		|	VendorsARAPAccounting.DayPeriod AS DayPeriod,
		|	VendorsARAPAccounting.WeekPeriod AS WeekPeriod,
		|	VendorsARAPAccounting.TenDaysPeriod AS TenDaysPeriod,
		|	VendorsARAPAccounting.MonthPeriod AS MonthPeriod,
		|	VendorsARAPAccounting.QuarterPeriod AS QuarterPeriod,
		|	VendorsARAPAccounting.HalfYearPeriod AS HalfYearPeriod,
		|	VendorsARAPAccounting.YearPeriod AS YearPeriod,
		|	
		|	CASE WHEN VendorsARAPAccounting.Recorder = UNDEFINED THEN
		|		NULL
		|	ELSE
		|		VendorsARAPAccounting.Recorder
		|	END AS Recorder,
		|	
		|	CASE WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
		|		VendorsARAPAccounting.PrepaymentManOpeningBalance
		|	WHEN &ReportCurrency = RegisterAccountingAnalyticsForPartners.Organization.LocalAccountingCurrency THEN
		|		VendorsARAPAccounting.PrepaymentLocalOpeningBalance
		|	ELSE
		|		VendorsARAPAccounting.PrepaymentOpeningBalance
		|	END AS SumOpeningBalance,
		|
		|	CASE WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
		|		VendorsARAPAccounting.PrepaymentManClosingBalance
		|	WHEN &ReportCurrency = RegisterAccountingAnalyticsForPartners.Organization.LocalAccountingCurrency THEN
		|		VendorsARAPAccounting.PrepaymentLocalClosingBalance
		|	ELSE
		|		VendorsARAPAccounting.PrepaymentClosingBalance
		|	END AS SumClosingBalance
		|FROM
		|	AccumulationRegister.VendorsARAPAccountingByDocuments.BalanceAndTurnovers({&BeginOfPeriod}, {&EndOfPeriod}, Auto) AS VendorsARAPAccounting
		|
		|	LEFT JOIN
		|		InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
		|	ON
		|		VendorsARAPAccounting.AccountingDimensionByPartners = RegisterAccountingAnalyticsForPartners.DimensionKey
		|
		|UNION ALL
		|
		|SELECT
		|	VALUE(Enum.KindsOfBalanceSheetStatementItems.Liabilities) AS IndicatorType,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceVendorAccountsReceivable) AS Factor,
		|	
		|	Calculations.InventoryOwnerAttribute.Organization,
		|	Calculations.InventoryOwnerAttribute.Currency AS Currency,
		|	Calculations.InventoryOwnerAttribute.GoodsOwner AS Partner,
		|	Calculations.ItemsLocationAttributes.Products AS Dimension,
		|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
		|	
		|	Calculations.SecondPeriod AS SecondPeriod,
		|	Calculations.DayPeriod AS DayPeriod,
		|	Calculations.WeekPeriod AS WeekPeriod,
		|	Calculations.TenDaysPeriod AS TenDaysPeriod,
		|	Calculations.MonthPeriod AS MonthPeriod,
		|	Calculations.QuarterPeriod AS QuarterPeriod,
		|	Calculations.HalfYearPeriod AS HalfYearPeriod,
		|	Calculations.YearPeriod AS YearPeriod,
		|	
		|	CASE WHEN Calculations.Recorder = UNDEFINED THEN
		|		NULL
		|	ELSE
		|		Calculations.Recorder
		|	END AS Recorder,
		|	
		|	CASE WHEN Calculations.RevenueAmountOpeningBalance > 0 THEN
		|		-Calculations.RevenueAmountOpeningBalance
		|	ELSE
		|		0
		|	END AS SumOpeningBalance,
		|
		|	CASE WHEN Calculations.RevenueAmountClosingBalance > 0 THEN
		|		-Calculations.RevenueAmountClosingBalance
		|	ELSE
		|		0
		|	END AS SumClosingBalance
		|FROM
		|	AccumulationRegister.GoodsToBeRegisteredInReportsToConsignor.BalanceAndTurnovers({&BeginOfPeriod}, {&EndOfPeriod}, Auto) AS Calculations
		|
		|UNION ALL
		|
		|SELECT
		|	VALUE(Enum.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName) AS IndicatorType,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalancePrepaymentsToVendor_) AS Factor,
		|	
		|	Calculations.InventoryOwnerAttribute.Organization,
		|	Calculations.InventoryOwnerAttribute.Currency AS Currency,
		|	Calculations.InventoryOwnerAttribute.GoodsOwner AS Partner,
		|	Calculations.ItemsLocationAttributes.Products AS Dimension,
		|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
		|	
		|	Calculations.SecondPeriod AS SecondPeriod,
		|	Calculations.DayPeriod AS DayPeriod,
		|	Calculations.WeekPeriod AS WeekPeriod,
		|	Calculations.TenDaysPeriod AS TenDaysPeriod,
		|	Calculations.MonthPeriod AS MonthPeriod,
		|	Calculations.QuarterPeriod AS QuarterPeriod,
		|	Calculations.HalfYearPeriod AS HalfYearPeriod,
		|	Calculations.YearPeriod AS YearPeriod,
		|	
		|	CASE WHEN Calculations.Recorder = UNDEFINED THEN
		|		NULL
		|	ELSE
		|		Calculations.Recorder
		|	END AS Recorder,
		|	
		|	CASE WHEN Calculations.RevenueAmountOpeningBalance < 0 THEN
		|		-Calculations.RevenueAmountOpeningBalance
		|	ELSE
		|		0
		|	END AS SumOpeningBalance,
		|
		|	CASE WHEN Calculations.RevenueAmountClosingBalance < 0 THEN
		|		-Calculations.RevenueAmountClosingBalance
		|	ELSE
		|		0
		|	END AS SumClosingBalance
		|FROM
		|	AccumulationRegister.GoodsToBeRegisteredInReportsToConsignor.BalanceAndTurnovers({&BeginOfPeriod}, {&EndOfPeriod}, Auto) AS Calculations
		|
		|UNION ALL
		|
		|SELECT
		|	VALUE(Enum.KindsOfBalanceSheetStatementItems.Liabilities) AS IndicatorType,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceVendorAccountsReceivable) AS Factor,
		|	
		|	Calculations.DocumentInflow.Organization,
		|	Calculations.DocumentInflow.ARAPCurrency AS Currency,
		|	Calculations.Partner,
		|	Calculations.Products AS Dimension,
		|	Calculations.DocumentInflow.Department AS Department,
		|	
		|	Calculations.SecondPeriod AS SecondPeriod,
		|	Calculations.DayPeriod AS DayPeriod,
		|	Calculations.WeekPeriod AS WeekPeriod,
		|	Calculations.TenDaysPeriod AS TenDaysPeriod,
		|	Calculations.MonthPeriod AS MonthPeriod,
		|	Calculations.QuarterPeriod AS QuarterPeriod,
		|	Calculations.HalfYearPeriod AS HalfYearPeriod,
		|	Calculations.YearPeriod AS YearPeriod,
		|	
		|	CASE WHEN Calculations.Recorder = UNDEFINED THEN
		|		NULL
		|	ELSE
		|		Calculations.Recorder
		|	END AS Recorder,
		|	
		|	CASE WHEN Calculations.SumOpeningBalance > 0 THEN
		|		-Calculations.SumOpeningBalance
		|	ELSE
		|		0
		|	END AS SumOpeningBalance,
		|
		|	CASE WHEN Calculations.SumClosingBalance > 0 THEN
		|		-Calculations.SumClosingBalance
		|	ELSE
		|		0
		|	END AS SumClosingBalance
		|FROM
		|	AccumulationRegister.ReceivedReturnablePackaging.BalanceAndTurnovers({&BeginOfPeriod}, {&EndOfPeriod}, Auto,, NOT DepositIsRequired) AS Calculations
		|";
	EndIf;
	#EndRegion

	Return QueryText;
	
EndFunction

Function QueryTextFinancialInstrumentsARAP()
	
	QueryText = "
	|SELECT
	|	VALUE(Enum.KindsOfBalanceSheetStatementItems.Liabilities) AS IndicatorType,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceLoansPayables) AS Factor,
	|	Dimension.Organization,
	|	CASE WHEN &ReportCurrency = Dimension.Organization.LocalAccountingCurrency THEN
	|		Dimension.Organization.LocalAccountingCurrency
	|	WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
	|		&ManagementAccountingCurrency
	|	ELSE
	|		Calculations.Contract.ARAPCurrency
	|	END AS Currency,
	|	Dimension.Partner AS Partner,
	|	Calculations.Contract AS Dimension,
	|	Calculations.Contract.Department AS Department,
	|
	|	Calculations.SecondPeriod AS SecondPeriod,
	|	Calculations.DayPeriod AS DayPeriod,
	|	Calculations.WeekPeriod AS WeekPeriod,
	|	Calculations.TenDaysPeriod AS TenDaysPeriod,
	|	Calculations.MonthPeriod AS MonthPeriod,
	|	Calculations.QuarterPeriod AS QuarterPeriod,
	|	Calculations.HalfYearPeriod AS HalfYearPeriod,
	|	Calculations.YearPeriod AS YearPeriod,
	|	CASE WHEN Calculations.Recorder = UNDEFINED THEN
	|		NULL
	|	ELSE
	|		Calculations.Recorder
	|	END AS Recorder,
	|	
	|	CASE WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
	|		Calculations.SumManOpeningBalance
	|	WHEN &ReportCurrency = Dimension.Organization.LocalAccountingCurrency THEN
	|		Calculations.SumComplOpeningBalance
	|	ELSE
	|		Calculations.SumOpeningBalance
	|	END AS SumOpeningBalance,
	|	
	|	CASE WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
	|		Calculations.SumManClosingBalance
	|	WHEN &ReportCurrency = Dimension.Organization.LocalAccountingCurrency THEN
	|		Calculations.SumComplClosingBalance
	|	ELSE
	|		Calculations.SumClosingBalance
	|	END AS SumClosingBalance
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP.BalanceAndTurnovers({&BeginOfPeriod}, {&EndOfPeriod}, Auto) AS Calculations
	|
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS Dimension
	|	ON
	|		Calculations.AccountingDimensionByPartners = Dimension.DimensionKey
	|WHERE
	|	Calculations.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(Enum.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName) AS IndicatorType,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceDepositsInBanks) AS Factor,
	|	Dimension.Organization,
	|	CASE WHEN &ReportCurrency = Dimension.Organization.LocalAccountingCurrency THEN
	|		Dimension.Organization.LocalAccountingCurrency
	|	WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
	|		&ManagementAccountingCurrency
	|	ELSE
	|		Calculations.Contract.ARAPCurrency
	|	END AS Currency,
	|	Dimension.Partner,
	|	Calculations.Contract AS Dimension,
	|	Calculations.Contract.Department AS Department,
	|
	|	Calculations.SecondPeriod,
	|	Calculations.DayPeriod,
	|	Calculations.WeekPeriod,
	|	Calculations.TenDaysPeriod,
	|	Calculations.MonthPeriod,
	|	Calculations.QuarterPeriod,
	|	Calculations.HalfYearPeriod,
	|	Calculations.YearPeriod,
	|	CASE WHEN Calculations.Recorder = UNDEFINED THEN
	|		NULL
	|	ELSE
	|		Calculations.Recorder
	|	END,
	|	CASE WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
	|		Calculations.SumManOpeningBalance
	|	WHEN &ReportCurrency = Dimension.Organization.LocalAccountingCurrency THEN
	|		Calculations.SumComplOpeningBalance
	|	ELSE
	|		Calculations.SumOpeningBalance
	|	END AS SumOpeningBalance,
	|	
	|	CASE WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
	|		Calculations.SumManClosingBalance
	|	WHEN &ReportCurrency = Dimension.Organization.LocalAccountingCurrency THEN
	|		Calculations.SumComplClosingBalance
	|	ELSE
	|		Calculations.SumClosingBalance
	|	END AS SumClosingBalance
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP.BalanceAndTurnovers({&BeginOfPeriod}, {&EndOfPeriod}, Auto) AS Calculations
	|
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS Dimension
	|	ON
	|		Calculations.AccountingDimensionByPartners = Dimension.DimensionKey
	|WHERE
	|	Calculations.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.Deposit)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(Enum.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName) AS IndicatorType,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.IssuedBorrowings) AS Factor,
	|	Dimension.Organization,
	|	CASE WHEN &ReportCurrency = Dimension.Organization.LocalAccountingCurrency THEN
	|		Dimension.Organization.LocalAccountingCurrency
	|	WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
	|		&ManagementAccountingCurrency
	|	ELSE
	|		Calculations.Contract.ARAPCurrency
	|	END AS Currency,
	|	Dimension.Partner,
	|	Calculations.Contract AS Dimension,
	|	Calculations.Contract.Department AS Department,
	|
	|	Calculations.SecondPeriod,
	|	Calculations.DayPeriod,
	|	Calculations.WeekPeriod,
	|	Calculations.TenDaysPeriod,
	|	Calculations.MonthPeriod,
	|	Calculations.QuarterPeriod,
	|	Calculations.HalfYearPeriod,
	|	Calculations.YearPeriod,
	|	CASE WHEN Calculations.Recorder = UNDEFINED THEN
	|		NULL
	|	ELSE
	|		Calculations.Recorder
	|	END,
	|	CASE WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
	|		Calculations.SumManOpeningBalance
	|	WHEN &ReportCurrency = Dimension.Organization.LocalAccountingCurrency THEN
	|		Calculations.SumComplOpeningBalance
	|	ELSE
	|		Calculations.SumOpeningBalance
	|	END AS SumOpeningBalance,
	|	
	|	CASE WHEN &ReportCurrency = &ManagementAccountingCurrency THEN
	|		Calculations.SumManClosingBalance
	|	WHEN &ReportCurrency = Dimension.Organization.LocalAccountingCurrency THEN
	|		Calculations.SumComplClosingBalance
	|	ELSE
	|		Calculations.SumClosingBalance
	|	END AS SumClosingBalance
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP.BalanceAndTurnovers({&BeginOfPeriod}, {&EndOfPeriod}, Auto) AS Calculations
	|
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS Dimension
	|	ON
	|		Calculations.AccountingDimensionByPartners = Dimension.DimensionKey
	|WHERE
	|	Calculations.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.IssuedBorrowing)";

	Return QueryText;
	
EndFunction

Function QueryTextOtherAssetsLiabilities()
	
	QueryText = "
	|SELECT
	|	CASE 
	|		WHEN RegisterData.AssetRef.AssetLiability = VALUE(Enum.KindsOfBalanceSheetStatementItems.AssetLiability)
	|			THEN CASE 
	|					WHEN RegisterData.SumClosingBalance > 0 THEN
	|						VALUE(Enum.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName)
	|					ELSE
	|						VALUE(Enum.KindsOfBalanceSheetStatementItems.Liabilities)
	|				END
	|		ELSE
	|			RegisterData.AssetRef.AssetLiability
	|	END AS IndicatorType,
	|	RegisterData.AssetRef AS Factor,
	|	
	|	RegisterData.Organization,
	|	&ManagementAccountingCurrency AS Currency,
	|	NULL AS Partner,
	|	RegisterData.Dimension AS Dimension,
	|	ISNULL(Departments.Ref, VALUE(Catalog.BusinessStructure.EmptyRef)) AS Department,
	|	
	|	RegisterData.SecondPeriod AS SecondPeriod,
	|	RegisterData.DayPeriod AS DayPeriod,
	|	RegisterData.WeekPeriod AS WeekPeriod,
	|	RegisterData.TenDaysPeriod AS TenDaysPeriod,
	|	RegisterData.MonthPeriod AS MonthPeriod,
	|	RegisterData.QuarterPeriod AS QuarterPeriod,
	|	RegisterData.HalfYearPeriod AS HalfYearPeriod,
	|	RegisterData.YearPeriod AS YearPeriod,
	|	
	|	CASE WHEN RegisterData.Recorder = UNDEFINED THEN
	|		NULL
	|	ELSE
	|		RegisterData.Recorder
	|	END AS Recorder,
	|	
	|	RegisterData.SumOpeningBalance AS SumOpeningBalance,
	|	RegisterData.SumClosingBalance AS SumClosingBalance
	|FROM
	|	AccumulationRegister.OtherAssetsLiabilities.BalanceAndTurnovers({&BeginOfPeriod}, {&EndOfPeriod}, Auto) AS RegisterData
	|
	|	LEFT JOIN
	|		Catalog.BusinessStructure AS Departments
	|	ON
	|		RegisterData.Dimension = Departments.Ref
	|WHERE
	|	RegisterData.AssetRef IN (&ItemsOfOtherAssetsLiabilities) OR NOT RegisterData.AssetRef.Predefined
	|";

	Return QueryText;
	
EndFunction

Function QueryTextProfitLoss()
	
	QueryText = "
	|SELECT
	|	VALUE(Enum.KindsOfBalanceSheetStatementItems.Liabilities) AS IndicatorType,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ProfitAndLoss) AS Factor,
	|	
	|	Dimension.Organization,
	|	&ManagementAccountingCurrency AS Currency,
	|	Dimension.Partner AS Partner,
	|	DimensionOfProductItem.Products AS Dimension,
	|	RegisterData.Department AS Department,
	|	
	|	RegisterData.SecondPeriod AS SecondPeriod,
	|	RegisterData.DayPeriod AS DayPeriod,
	|	RegisterData.WeekPeriod AS WeekPeriod,
	|	RegisterData.TenDaysPeriod AS TenDaysPeriod,
	|	RegisterData.MonthPeriod AS MonthPeriod,
	|	RegisterData.QuarterPeriod AS QuarterPeriod,
	|	RegisterData.HalfYearPeriod AS HalfYearPeriod,
	|	RegisterData.YearPeriod AS YearPeriod,
	|	
	|	CASE WHEN RegisterData.Recorder = UNDEFINED THEN
	|		NULL
	|	ELSE
	|		RegisterData.Recorder
	|	END AS Recorder,
	|	
	|	0 AS SumOpeningBalance,
	|	(CASE WHEN RegisterData.InventoryType <> VALUE(Enum.InventoryTypes.ConsignedGoods) THEN
	|		- RegisterData.RevenueAmountTurnover + RegisterData.CostTurnover
	|	ELSE
	|		0
	|	END
	|	+ RegisterData.AddExpensesForGoodsTurnover
	|	) AS SumClosingBalance
	|FROM
	|	AccumulationRegister.RevenueAndCOGS.Turnovers({&BeginOfPeriod}, {&EndOfPeriod}, Auto) AS RegisterData
	|
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS Dimension
	|	ON
	|		RegisterData.AccountingDimensionByPartners = Dimension.DimensionKey
	|
	|	LEFT JOIN
	|		Catalog.InventoryLocationAttributeKeys AS DimensionOfProductItem
	|	ON
	|		RegisterData.ItemsLocationAttributes = DimensionOfProductItem.Ref
	|
	|	LEFT JOIN ClosingOfMonth AS ClosingOfMonth
	|		ON ClosingOfMonth.Organization = Dimension.Organization
	|		AND ClosingOfMonth.MonthPeriod = RegisterData.MonthPeriod
	|WHERE
	|	ClosingOfMonth.Organization IS NULL
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(Enum.KindsOfBalanceSheetStatementItems.Liabilities) AS IndicatorType,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ProfitAndLoss) AS Factor,
	|	
	|	RegisterData.Organization,
	|	&ManagementAccountingCurrency AS Currency,
	|	NULL AS Partner,
	|	RegisterData.IncomeItem AS Dimension,
	|	RegisterData.Department AS Department,
	|	
	|	RegisterData.SecondPeriod AS SecondPeriod,
	|	RegisterData.DayPeriod AS DayPeriod,
	|	RegisterData.WeekPeriod AS WeekPeriod,
	|	RegisterData.TenDaysPeriod AS TenDaysPeriod,
	|	RegisterData.MonthPeriod AS MonthPeriod,
	|	RegisterData.QuarterPeriod AS QuarterPeriod,
	|	RegisterData.HalfYearPeriod AS HalfYearPeriod,
	|	RegisterData.YearPeriod AS YearPeriod,
	|	
	|	CASE WHEN RegisterData.Recorder = UNDEFINED THEN
	|		NULL
	|	ELSE
	|		RegisterData.Recorder
	|	END AS Recorder,
	|	
	|	0 AS SumOpeningBalance,
	|	- RegisterData.SumTurnover AS SumClosingBalance
	|FROM
	|	AccumulationRegister.OtherIncome.Turnovers({&BeginOfPeriod}, {&EndOfPeriod}, Auto) AS RegisterData
	|";

	Return QueryText;
	
EndFunction

Function RequestTextDynamicsOfWorkingCapital()
	
	QueryText = TextTimeSettlementRegistrars()
		+ TextTableOfGiftCertificates()
		+ TextCompletedClosingOfMonth()
		+ QueryTextInventoryCost()
		+ "UNION ALL" + QueryTextCash()
		+ "UNION ALL" + QueryTextAdvanceHolderCash()
		+ "UNION ALL" + QueryTextOtherExpenses()
		+ "UNION ALL" + QueryTextCustomersARAPAccounting()
		+ "UNION ALL" + QueryTextVendorsARAPAccounting()
		+ "UNION ALL" + QueryTextFinancialInstrumentsARAP()
		+ "UNION ALL" + QueryTextProfitLoss();
		
	If Not GetFunctionalOption("BaseVersion") Then
		QueryText = QueryText + "UNION ALL" + QueryTextOtherAssetsLiabilities();
	EndIf;
	
	QueryText = QueryText + ";" + "
	|///////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	CurrencyExchangeRate.Currency AS Currency,
	|	CurrencyExchangeRate.BaseCurrency AS BaseCurrency,
	|	(CurrencyExchangeRate.CourseNumerator * ReportCurrencyRate.CourseDenominator)
	| / (CurrencyExchangeRate.CourseDenominator * ReportCurrencyRate.CourseNumerator) AS ConversionFactor_
	|
	|INTO ExchangeRates
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast({&EndOfPeriod}) AS CurrencyExchangeRate
	|
	|	INNER JOIN
	|		InformationRegister.RelativeExchangeRates.SliceLast({&EndOfPeriod}, Currency = &ReportCurrency) AS ReportCurrencyRate
	|	ON
	|		CurrencyExchangeRate.BaseCurrency = ReportCurrencyRate.BaseCurrency
	|
	|WHERE
	|	CurrencyExchangeRate.CourseDenominator <> 0
	|	AND ReportCurrencyRate.CourseNumerator <> 0
	|;
	|///////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&LineBalanceIsNotBroken AS AssetsMinusLiabilities,
	|	WorkingCapital.IndicatorType AS IndicatorType,
	|	WorkingCapital.Factor AS Factor,
	|	WorkingCapital.Organization,
	|	WorkingCapital.Currency AS Currency,
	|	WorkingCapital.Partner AS Partner,
	|	WorkingCapital.Dimension AS Dimension,
	|	WorkingCapital.Department AS Department,
	|	
	|	CASE WHEN &ReportCurrency = VALUE(Catalog.Currencies.EmptyRef) THEN
	|		WorkingCapital.Currency
	|	ELSE
	|		&ReportCurrency
	|	END AS ReportCurrency,
	|	
	|	WorkingCapital.SecondPeriod AS SecondPeriod,
	|	WorkingCapital.DayPeriod AS DayPeriod,
	|	WorkingCapital.WeekPeriod AS WeekPeriod,
	|	WorkingCapital.TenDaysPeriod AS TenDaysPeriod,
	|	WorkingCapital.MonthPeriod AS MonthPeriod,
	|	WorkingCapital.QuarterPeriod AS QuarterPeriod,
	|	WorkingCapital.HalfYearPeriod AS HalfYearPeriod,
	|	WorkingCapital.YearPeriod AS YearPeriod,
	|	WorkingCapital.Recorder AS Recorder,
	|	VALUETYPE(WorkingCapital.Recorder) AS TypeOfRegistrar,
	|	
	|	SUM(WorkingCapital.SumOpeningBalance) AS SumOpeningBalance,
	|	SUM(WorkingCapital.SumClosingBalance) AS SumClosingBalance,
	|	SUM(WorkingCapital.SumClosingBalance - WorkingCapital.SumOpeningBalance) AS Update,
	|
	|	CASE WHEN SUM(WorkingCapital.SumClosingBalance - WorkingCapital.SumOpeningBalance) > 0 THEN
	|		SUM(WorkingCapital.SumClosingBalance - WorkingCapital.SumOpeningBalance)
	|	ELSE
	|		0
	|	END AS Increase,
	|	CASE WHEN SUM(WorkingCapital.SumClosingBalance - WorkingCapital.SumOpeningBalance) < 0 THEN
	|		-SUM(WorkingCapital.SumClosingBalance - WorkingCapital.SumOpeningBalance)
	|	ELSE
	|		0
	|	END AS Decrease,
	|	
	|	SUM(CAST(WorkingCapital.SumOpeningBalance
	|		* ISNULL(ExchangeRates.ConversionFactor_, 1) AS NUMBER(31,2))
	|	) AS AmountInitialBalanceInCurrency,
	|
	|	SUM(CAST(WorkingCapital.SumClosingBalance
	|		* ISNULL(ExchangeRates.ConversionFactor_, 1) AS NUMBER(31,2))
	|	) AS AmountFinalBalanceInCurrency,
	|
	|	SUM(CAST((WorkingCapital.SumClosingBalance - WorkingCapital.SumOpeningBalance)
	|		* ISNULL(ExchangeRates.ConversionFactor_, 1) AS NUMBER(31,2))
	|	) AS ChangeInCurrency
	|FROM
	|	WorkingCapital AS WorkingCapital
	|	
	|	LEFT JOIN
	|		ExchangeRates AS ExchangeRates
	|	ON
	|		WorkingCapital.Currency = ExchangeRates.Currency
	|		AND WorkingCapital.Organization.LocalAccountingCurrency = ExchangeRates.BaseCurrency
	|WHERE
	|	NOT WorkingCapital.Currency IS NULL
	|
	|GROUP BY
	|	WorkingCapital.IndicatorType,
	|	WorkingCapital.Factor,
	|	WorkingCapital.Organization,
	|	WorkingCapital.Currency,
	|	WorkingCapital.Partner,
	|	WorkingCapital.Dimension,
	|	WorkingCapital.Department,
	|	CASE WHEN &ReportCurrency = VALUE(Catalog.Currencies.EmptyRef) THEN
	|		WorkingCapital.Currency
	|	ELSE
	|		&ReportCurrency
	|	END,
	|	WorkingCapital.SecondPeriod,
	|	WorkingCapital.DayPeriod,
	|	WorkingCapital.WeekPeriod,
	|	WorkingCapital.TenDaysPeriod,
	|	WorkingCapital.MonthPeriod,
	|	WorkingCapital.QuarterPeriod,
	|	WorkingCapital.HalfYearPeriod,
	|	WorkingCapital.YearPeriod,
	|	WorkingCapital.Recorder,
	|	VALUETYPE(WorkingCapital.Recorder)
	|	
	|HAVING
	|	SUM(WorkingCapital.SumOpeningBalance) <> 0
	|	OR SUM(WorkingCapital.SumClosingBalance) <> 0
	|	OR SUM(WorkingCapital.SumClosingBalance - WorkingCapital.SumOpeningBalance) <> 0
	|";
	
	Return QueryText;
	
EndFunction

Procedure SetRequiredSettings(UserSettingsModified)
	
	DataCompositionServer.SetUpDynamicPeriod(DataCompositionSchema, SettingsComposer);
	
	ManagementAccountingCurrency = Constants.ManagementAccountingCurrency.Get();
	
	If SettingsComposer.Settings.AdditionalProperties.Property("VariantKey")
		And SettingsComposer.Settings.AdditionalProperties.VariantKey = "ControlOfInputOfBalances" Then
		StartOfPeriodParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "BeginOfPeriod");
		If StartOfPeriodParameter <> Undefined Then
			DataCompositionClientServer.SetParameter(SettingsComposer, "BeginOfPeriod", Date('00010101'));
		EndIf;
		EndOfPeriodParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "EndOfPeriod");
		DateParameter_ = DataCompositionClientServer.GetParameter(SettingsComposer, "OnDate");
		If EndOfPeriodParameter <> Undefined And DateParameter_ <> Undefined Then
			If ValueIsFilled(DateParameter_.Value) Then
				DataCompositionClientServer.SetParameter(SettingsComposer, "EndOfPeriod", EndOfDay(DateParameter_.Value));
			Else
				DataCompositionClientServer.SetParameter(SettingsComposer, "OnDate", EndOfDay(CurrentSessionDate()));
				DataCompositionClientServer.SetParameter(SettingsComposer, "EndOfPeriod", EndOfDay(CurrentSessionDate()));
			EndIf;
		EndIf;
	EndIf;
	
	ParameterStringSummary = DataCompositionClientServer.GetParameter(SettingsComposer, "LineSummary_");
	If ParameterStringSummary <> Undefined Then
		DataCompositionClientServer.SetParameter(SettingsComposer, "LineSummary_", NStr("vi = 'Tổng hợp';
																						|ru = 'Сводно';
																						|en = 'Overall'; fa = 'Overall';
																						|it = 'Riassuntivo';
																						|pl = 'Overall';
																						|tr = 'Özet'"));
	EndIf;
	
	ParameterStringAssetsMinusLiabilities = DataCompositionClientServer.GetParameter(SettingsComposer, "LineAssetsMinusLiabilities");
	If ParameterStringAssetsMinusLiabilities <> Undefined Then
		DataCompositionClientServer.SetParameter(SettingsComposer, "LineAssetsMinusLiabilities", NStr("vi = 'Tài sản trừ đi nguồn vốn';
																										|ru = 'Активы минус пассивы';
																										|en = 'Assets minus liabilities'; fa = 'دارایی‌ها منهای بدهی‌ها';
																										|it = 'Attività meno passività';
																										|pl = 'Aktywa minus pasywa';
																										|tr = 'Aktifler eksi pasifler'"));
	EndIf;
	
	StringBalanceParameterIsNotBroken = DataCompositionClientServer.GetParameter(SettingsComposer, "LineBalanceIsNotBroken");
	If StringBalanceParameterIsNotBroken <> Undefined Then
		DataCompositionClientServer.SetParameter(SettingsComposer, "LineBalanceIsNotBroken", NStr("vi = 'Không vi phạm cân bằng';
																									|ru = 'Баланс не нарушен';
																									|en = 'Balance is not violated'; fa = 'توازن نقض نشده است';
																									|it = 'Saldo non compromesso';
																									|pl = 'Saldo jest prawidłowe';
																									|tr = 'Bakiye ihlal edilmedi'"));
	EndIf;
	
	ParameterCurrencyOfManagementAccounting = DataCompositionClientServer.GetParameter(SettingsComposer, "ManagementAccountingCurrency");
	If ParameterCurrencyOfManagementAccounting <> Undefined 
		And Not ValueIsFilled(ParameterCurrencyOfManagementAccounting.Value) Then
		DataCompositionClientServer.SetParameter(SettingsComposer, "ManagementAccountingCurrency", ManagementAccountingCurrency);
		
		UserSettingsModified = True;
	EndIf;
	
	ItemParameterOfOtherAssetsLiabilities = DataCompositionClientServer.GetParameter(SettingsComposer, "ItemsOfOtherAssetsLiabilities");
	If ItemParameterOfOtherAssetsLiabilities <> Undefined Then
		
		ItemsOfOtherAssetsLiabilities = New ValueList;
		ItemsOfOtherAssetsLiabilities.Add(ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceTargetFinancing);
		ItemsOfOtherAssetsLiabilities.Add(ChartsOfCharacteristicTypes.AssetLiabilityItems.ProfitAndLoss);
		ItemsOfOtherAssetsLiabilities.Add(ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceOtherLiabilities);
		ItemsOfOtherAssetsLiabilities.Add(ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceOtherAssets);
		ItemsOfOtherAssetsLiabilities.Add(ChartsOfCharacteristicTypes.AssetLiabilityItems.Taxes);
		ItemsOfOtherAssetsLiabilities.Add(ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceDepositedSalary);
		ItemsOfOtherAssetsLiabilities.Add(ChartsOfCharacteristicTypes.AssetLiabilityItems.Payroll);
		ItemsOfOtherAssetsLiabilities.Add(ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceFixedAssets);
		ItemsOfOtherAssetsLiabilities.Add(ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceLeasing);
		DataCompositionClientServer.SetParameter(SettingsComposer, "ItemsOfOtherAssetsLiabilities", ItemsOfOtherAssetsLiabilities);
		
	EndIf;
	
	ReportCurrencyParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "ReportCurrency");
	If ReportCurrencyParameter <> Undefined 
		And Not ValueIsFilled(ReportCurrencyParameter.Value) Then
		DataCompositionClientServer.SetParameter(SettingsComposer, "ReportCurrency", ManagementAccountingCurrency);
		
		UserSettingsModified = True;
	EndIf;
	
	ParameterNewCalculationArchitecture = DataCompositionClientServer.GetParameter(SettingsComposer, "NewSettlementArchitecture");
	If ParameterNewCalculationArchitecture <> Undefined 
		And Not ValueIsFilled(ParameterNewCalculationArchitecture.Value) Then
		DataCompositionClientServer.SetParameter(SettingsComposer, "NewSettlementArchitecture", Constants.NewOnlineARAPAccounting.Get());
		
		UserSettingsModified = True;
	EndIf;
EndProcedure

Function StructureOfDynamicHeaders()
	DynamicHeaders = New Structure;
	
	ParameterTypeOfAnalysis = DataCompositionClientServer.GetParameter(SettingsComposer, "AnalysisType");
	AvailableSetting = ReportsClientServer.FindAvailableSetting(SettingsComposer.Settings, ParameterTypeOfAnalysis);
	If AvailableSetting <> Undefined Then
		PresentationOfParameterValue = AvailableSetting.AvailableValues[ParameterTypeOfAnalysis.Value];
		DynamicHeaders.Insert("AnalysisType", PresentationOfParameterValue);
	EndIf;
	
	PeriodicityParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "Periodicity");
	AvailableSetting = ReportsClientServer.FindAvailableSetting(SettingsComposer.Settings, PeriodicityParameter);
	If AvailableSetting <> Undefined Then
		PresentationOfParameterValue = AvailableSetting.AvailableValues.FindByValue(PeriodicityParameter.Value);
		DynamicHeaders.Insert("Periodicity", PresentationOfParameterValue);
	EndIf;
	
	Return DynamicHeaders;
EndFunction

Function AuxiliaryReportParameters()
	AuxiliaryParameters = New Array;
	
	AuxiliaryParameters.Add("AnalysisType");
	AuxiliaryParameters.Add("Periodicity");
	If SettingsComposer.Settings.AdditionalProperties.Property("VariantKey")
		And SettingsComposer.Settings.AdditionalProperties.VariantKey <> "ControlOfInputOfBalances" Then
		AuxiliaryParameters.Add("OnDate");
	EndIf;
	
	DataCompositionServer.AddAuxiliaryReportParametersForFunctionalOptions(AuxiliaryParameters);
	
	Return AuxiliaryParameters;
EndFunction

Procedure ConfigureDefaultSelectionParameters(FormSettingsComposer, UserSettings = False)
	
	ManagementAccountingCurrency = Constants.ManagementAccountingCurrency.Get();
	
	Parameter = ParameterSetting(FormSettingsComposer, "ReportCurrency", UserSettings);
	If Parameter <> Undefined Then
		Parameter.Use = True;
		If Not ValueIsFilled(Parameter.Value) Then
			Parameter.Value = ManagementAccountingCurrency;
		EndIf;
	EndIf;
	
EndProcedure

// Parameters:
// 	FormSettingsComposer - DataCompositionSettingsComposer - 
// 	ParameterName - String - LongDesc
// 	Custom - Boolean - LongDesc
// Returns:
// 	Undefined - LongDesc
Function ParameterSetting(FormSettingsComposer, ParameterName, Custom = False)
	
	DataParameter = FormSettingsComposer.Settings.DataParameters.Items.Find(ParameterName);
	If DataParameter <> Undefined Then
		CustomSettingParameter = FormSettingsComposer.UserSettings.Items.Find(DataParameter.UserSettingID);
		If Custom And CustomSettingParameter <> Undefined Then
			Return CustomSettingParameter;
		Else
			Return DataParameter;
		EndIf;
	EndIf;
	Return Undefined;
	
EndFunction

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - report form.
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	Parameters = ThisForm.Parameters;
	If Parameters.Property("CommandParameter") Then
		
		ThisForm.ParametersForm.PurposeUseKey = Parameters.CommandParameter;
		ThisForm.ParametersForm.Filter.Insert("Factor", Parameters.CommandParameter);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf