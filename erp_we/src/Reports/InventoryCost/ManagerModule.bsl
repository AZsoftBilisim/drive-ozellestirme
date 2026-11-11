//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.InventoryCost);
	DescriptionOfReport.DefineFormSettings = True;
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích giá vốn hàng hóa và số tiền vận chuyển.';
									|ru = 'Анализ себестоимости товаров и сумм ТЗР.';
									|en = 'Analysis of inventory cost and additional expenses.'; fa = 'Analysis of inventory cost and additional expenses.';
									|it = 'Анализ себестоимости товаров и сумм ТЗР.';
									|pl = 'Analiza kosztów własnych towarów i kosztów transportowo-zaopatrzeniowych.';
									|tr = 'Stok maliyetinin ve NTM tutarlarının analizi.'");
	
	// Common.
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "CostOfGoodsBasic");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích giá vốn hàng hóa và số tiền chi phí vận chuyển và mua sắm theo tập đoàn,
		|được phân bổ cho giá vốn hàng bán.';
		|ru = 'Анализ себестоимости товаров и сумм ТЗР по предприятию,
		|распределенных на себестоимость реализованных товаров.';
		|en = 'Analysis of inventory cost and additional expenses by the enterprise
		|allocated to cost of sold goods.'; fa = 'Analysis of inventory cost and additional expenses by the enterprise
		|allocated to cost of sold goods.';
		|it = 'Анализ себестоимости товаров и сумм ТЗР по предприятию,
		|распределенных на себестоимость реализованных товаров.';
		|pl = 'Analiza kosztów własnych towarów i kosztów transportowo-zaopatrzeniowych w przedsiębiorstwie, 
		|przydzielonych do kosztów własnych realizowanych towarów.';
		|tr = 'İşletmeye göre satılan ürün maliyetine dağıtılan
		|stok maliyetinin ve NTM tutarlarının analizi.'");
	OptionDetails.FunctionalOptions.Add("BaseVersion");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "CostOfGoodsForOperationsBasic");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích giá vốn và số tiền chi phí vận chuyển và mua sắm trong tập đoàn theo từng giao dịch.';
									|ru = 'Анализ себестоимости товаров и сумм ТЗР по предприятию в разрезе операций.';
									|en = 'Analysis of inventory cost and additional expenses by enterprise by transactions.'; fa = 'Analysis of inventory cost and additional expenses by enterprise by transactions.';
									|it = 'Анализ себестоимости товаров и сумм ТЗР по предприятию в разрезе операций.';
									|pl = 'Analiza kosztów własnych towarów i kosztów transportowo-zaopatrzeniowych w przedsiębiorstwie w przekroju operacji.';
									|tr = 'İşlem kapsamında işletmeye göre stok maliyetinin ve NTM tutarlarının analizi.'");
	OptionDetails.FunctionalOptions.Add("BaseVersion");
	
	// By organizations.
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "CostOfGoodsByOrganization");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích giá vốn hàng hóa và số tiền chi phí vận chuyển theo doanh nghiệp,
		|được phân bổ cho giá vốn hàng bán.';
		|ru = 'Анализ себестоимости товаров и сумм ТЗР по организациям,
		|распределенных на себестоимость реализованных товаров.';
		|en = 'Analyze the inventory cost and additional expenses by companies
		|allocated to cost of sold goods.'; fa = 'Analyze the inventory cost and additional expenses by companies
		|allocated to cost of sold goods.';
		|it = 'Анализ себестоимости товаров и сумм ТЗР по организациям,
		|распределенных на себестоимость реализованных товаров.';
		|pl = 'Analiza kosztów własnych towarów i kosztów transportowo-zaopatrzeniowych według firm, 
		|przydzielonych na koszt własny realizowanych towarów.';
		|tr = 'İş yerlerine göre satılan ürün maliyetine dağıtılan
		|stok maliyetinin ve NTM tutarlarının analizi.'");
	OptionDetails.FunctionalOptions.Add("NotBaseVersion");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "CostOfGoodsForOperationsByOrganizations");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích giá vốn và số tiền chi phí vận chuyển và mua sắm của doanh nghiệp theo từng giao dịch.';
									|ru = 'Анализ себестоимости товаров и сумм ТЗР по организациям в разрезе операций.';
									|en = 'Analysis of inventory cost and additional expenses by companies by transactions.'; fa = 'Analysis of inventory cost and additional expenses by companies by transactions.';
									|it = 'Анализ себестоимости товаров и сумм ТЗР по организациям в разрезе операций.';
									|pl = 'Analiza kosztów własnych i kosztów transportowo-zaopatrzeniowych według firm w przekroju operacji.';
									|tr = 'İşlem kapsamında iş yerlerine göre stok maliyetinin ve NTM tutarlarının analizi.'");
	OptionDetails.FunctionalOptions.Add("NotBaseVersion");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "CompanyPurchaseTrends");
	TMReportOptionsOverridable.ChangePlacementOfReportVariant(OptionDetails.Location, "Delete", "FinancialResultAndControlling.CostOfInventory");
	TMReportOptionsOverridable.ChangePlacementOfReportVariant(OptionDetails.Location, "Insert", "Purchases.Purchases");
	OptionDetails.LongDesc = NStr("vi = 'Khối lượng mua sắm hàng tháng trong kỳ đã chọn theo nhà cung cấp và mặt hàng.
		|Có thể phân tích theo kỳ - quý, tháng, tuần, ngày.';
		|ru = 'Помесячные объемы закупок за выбранный период по поставщикам и номенклатуре.
		|Возможен анализ по периодам - квартал, месяц, неделя, день.';
		|en = 'Monthly purchase volume for the selected period by vendors and by items.
		|Analysis is available by the following periods: quarter, month, week, day.'; fa = 'Monthly purchase volume for the selected period by vendors and by items.
		|Analysis is available by the following periods: quarter, month, week, day.';
		|it = 'Помесячные объемы закупок за выбранный период по поставщикам и номенклатуре.
		|Возможен анализ по периодам - квартал, месяц, неделя, день.';
		|pl = 'Miesięczne objętości zakupów za wybrany okres według dostawców i produktów. 
		|Jest możliwa analiza według okresów - kwartał, miesiąc, tydzień, dzień.';
		|tr = 'Seçilen dönem için tedarikçilere ve ürünleree göre aylık satın alma hacimleri.
		|Analiz şu dönemlere göre yapılabilir: çeyrek, ay, hafta, gün.'");
	OptionDetails.FunctionalOptions.Add("NotBaseVersion");
	
	// By company.
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "CostOfGoodsForEnterprise");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích giá vốn hàng hóa và số tiền chi phí vận chuyển và mua sắm theo tập đoàn,
		|được phân bổ cho giá vốn hàng bán.';
		|ru = 'Анализ себестоимости товаров и сумм ТЗР по предприятию,
		|распределенных на себестоимость реализованных товаров.';
		|en = 'Analysis of inventory cost and additional expenses by the enterprise
		|allocated to cost of sold goods.'; fa = 'Analysis of inventory cost and additional expenses by the enterprise
		|allocated to cost of sold goods.';
		|it = 'Анализ себестоимости товаров и сумм ТЗР по предприятию,
		|распределенных на себестоимость реализованных товаров.';
		|pl = 'Analiza kosztów własnych towarów i kosztów transportowo-zaopatrzeniowych w przedsiębiorstwie, 
		|przydzielonych do kosztów własnych realizowanych towarów.';
		|tr = 'İşletmeye göre satılan ürün maliyetine dağıtılan
		|stok maliyetinin ve NTM tutarlarının analizi.'");
	OptionDetails.FunctionalOptions.Add("NotBaseVersion");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "CostOfGoodsForOperationsOnEnterprise");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích giá vốn và số tiền chi phí vận chuyển và mua sắm trong tập đoàn theo từng giao dịch.';
									|ru = 'Анализ себестоимости товаров и сумм ТЗР по предприятию в разрезе операций.';
									|en = 'Analysis of inventory cost and additional expenses by enterprise by transactions.'; fa = 'Analysis of inventory cost and additional expenses by enterprise by transactions.';
									|it = 'Анализ себестоимости товаров и сумм ТЗР по предприятию в разрезе операций.';
									|pl = 'Analiza kosztów własnych towarów i kosztów transportowo-zaopatrzeniowych w przedsiębiorstwie w przekroju operacji.';
									|tr = 'İşlem kapsamında işletmeye göre stok maliyetinin ve NTM tutarlarının analizi.'");
	OptionDetails.FunctionalOptions.Add("NotBaseVersion");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "EnterprisePurchaseTrends");
	TMReportOptionsOverridable.ChangePlacementOfReportVariant(OptionDetails.Location, "Delete", "FinancialResultAndControlling.CostOfInventory");
	TMReportOptionsOverridable.ChangePlacementOfReportVariant(OptionDetails.Location, "Insert", "Purchases.Purchases");
	OptionDetails.DefaultVisibility = True;
	OptionDetails.LongDesc = NStr("vi = 'Khối lượng mua sắm hàng tháng trong kỳ đã chọn theo nhà cung cấp và mặt hàng.
		|Có thể phân tích theo kỳ - quý, tháng, tuần, ngày.';
		|ru = 'Помесячные объемы закупок за выбранный период по поставщикам и номенклатуре.
		|Возможен анализ по периодам - квартал, месяц, неделя, день.';
		|en = 'Monthly purchase volume for the selected period by vendors and by items.
		|Analysis is available by the following periods: quarter, month, week, day.'; fa = 'Monthly purchase volume for the selected period by vendors and by items.
		|Analysis is available by the following periods: quarter, month, week, day.';
		|it = 'Помесячные объемы закупок за выбранный период по поставщикам и номенклатуре.
		|Возможен анализ по периодам - квартал, месяц, неделя, день.';
		|pl = 'Miesięczne objętości zakupów za wybrany okres według dostawców i produktów. 
		|Jest możliwa analiza według okresów - kwartał, miesiąc, tydzień, dzień.';
		|tr = 'Seçilen dönem için tedarikçilere ve ürünleree göre aylık satın alma hacimleri.
		|Analiz şu dönemlere göre yapılabilir: çeyrek, ay, hafta, gün.'");
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

Procedure AddDefaultParameters(DefaultParameters) Export
	
	DefaultParameters.Insert("GenerateInventoryOwnerAttributesByFinancialAccountingGroups", Constants.GenerateInventoryOwnerAttributesByFinancialAccountingGroups.Get());
	DefaultParameters.Insert("ExcludedBusinessTransactions", CostCalculationAppliedAlgorithms.EconomicOperationsOfMovements());
	DefaultParameters.Insert("TypesOfTaxationVATIsIncludedInCost", VATAccountingERP.ActivitiesVATIsIncludedInCost());
	
EndProcedure

Function TempTablesQueryText(SourceDebuggingMode = False) Export
	
	QueryTexts = New Array;
	QueryTexts.Add(QueryTextSelectionByProductSegment());
	QueryTexts.Add(QueryTextTTCost_());
	QueryTexts.Add(QueryTextBalanceAndRegisteredRecords(SourceDebuggingMode));
	QueryTexts.Add(QueryTextVT_BalancesAndRegisteredRecordsForSelectionOfDetailsOfInitialCosts());
	QueryTexts.Add(QueryTextTT_DetailingInitialCosts(SourceDebuggingMode));
	
	QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	If SourceDebuggingMode Then
		QueryText = StrReplace(QueryText, "//DebugMode", "");
	Else
		QueryText = StrReplace(QueryText, "InventoryCost.Organization IN (&CompanyArray)", "TRUE");
		QueryText = StrReplace(QueryText, "InventoryCostBalance.Organization IN (&CompanyArray)", "TRUE");
		QueryText = StrReplace(QueryText, "CostDetails.Organization IN (&CompanyArray)", "TRUE");
	EndIf;
	
	Return QueryText;
	
EndFunction

Function QueryTextSamples() Export
	
	QueryText =
	"SELECT
	|	BalanceAndRegisteredRecords.SecondPeriod AS SecondPeriod,
	|	BalanceAndRegisteredRecords.DayPeriod AS DayPeriod,
	|	BalanceAndRegisteredRecords.WeekPeriod AS WeekPeriod,
	|	BalanceAndRegisteredRecords.TenDaysPeriod AS TenDaysPeriod,
	|	BalanceAndRegisteredRecords.MonthPeriod AS MonthPeriod,
	|	BalanceAndRegisteredRecords.QuarterPeriod AS QuarterPeriod,
	|	BalanceAndRegisteredRecords.HalfYearPeriod AS HalfYearPeriod,
	|	BalanceAndRegisteredRecords.YearPeriod AS YearPeriod,
	|	BalanceAndRegisteredRecords.VariancePeriod AS VariancePeriod,
	|	BalanceAndRegisteredRecords.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	BalanceAndRegisteredRecords.Products AS Products,
	|	(CASE
	|		WHEN &QuantityUnits = 0 THEN BalanceAndRegisteredRecords.StorageUnit
	|		WHEN &QuantityUnits = 1 THEN BalanceAndRegisteredRecords.UnitForReports
	|	END) AS ReportUnitOfMeasurement,
	|	BalanceAndRegisteredRecords.StorageUnit AS StorageUnit,
	|	BalanceAndRegisteredRecords.UnitForReports AS UnitForReports,
	|	BalanceAndRegisteredRecords.UnitFactorForReports AS UnitFactorForReports,
	|	BalanceAndRegisteredRecords.Characteristic AS Characteristic,
	|	BalanceAndRegisteredRecords.Series AS Series,
	|	BalanceAndRegisteredRecords.Warehouse AS Warehouse,
	|	BalanceAndRegisteredRecords.Purpose AS Purpose,
	|	BalanceAndRegisteredRecords.LineOfBusiness AS LineOfBusiness,
	|	BalanceAndRegisteredRecords.Department AS Department,
	|	BalanceAndRegisteredRecords.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	BalanceAndRegisteredRecords.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	BalanceAndRegisteredRecords.Organization AS Organization,
	|	BalanceAndRegisteredRecords.Lot AS Lot,
	|	BalanceAndRegisteredRecords.LotVendorAttributes AS LotVendorAttributes,
	|	BalanceAndRegisteredRecords.AccountingSection AS AccountingSection,
	|	BalanceAndRegisteredRecords.VATActivityType AS VATActivityType,
	|	BalanceAndRegisteredRecords.BusinessOperation AS BusinessOperation,
	|	BalanceAndRegisteredRecords.IncomeItem AS IncomeItem,
	|	BalanceAndRegisteredRecords.ExpenseItem AS ExpenseItem,
	|	BalanceAndRegisteredRecords.IncomeAndExpenseItem AS IncomeAndExpenseItem,
	|	BalanceAndRegisteredRecords.DimensionOfRevenue AS DimensionOfRevenue,
	|	BalanceAndRegisteredRecords.DimensionOfExpenses AS DimensionOfExpenses,
	|	BalanceAndRegisteredRecords.DimensionOfIncomeExpense AS DimensionOfIncomeExpense,
	|	BalanceAndRegisteredRecords.Contract AS Contract,
	|	BalanceAndRegisteredRecords.OrderDocument AS OrderDocument,
	|	BalanceAndRegisteredRecords.Partner AS Partner,
	|	BalanceAndRegisteredRecords.Counterparty AS Counterparty,
	|	BalanceAndRegisteredRecords.Terms AS Terms,
	|	BalanceAndRegisteredRecords.InventoryType AS InventoryType,
	|	BalanceAndRegisteredRecords.BusinessOperationCatalog AS BusinessOperationCatalog,
	|	BalanceAndRegisteredRecords.EconomicOperationOfParish AS EconomicOperationOfParish,
	|	BalanceAndRegisteredRecords.EconomicOperationOfExpenditure AS EconomicOperationOfExpenditure,
	|	BalanceAndRegisteredRecords.CostDefiningMethod AS CostDefiningMethod,
	|	BalanceAndRegisteredRecords.CostCalculationDate AS CostCalculationDate,
	|	(CASE
	|		WHEN BalanceAndRegisteredRecords.Document = UNDEFINED THEN NULL
	|		ELSE BalanceAndRegisteredRecords.Document END) AS Document,
	|	BalanceAndRegisteredRecords.CountOpeningBalance AS CountOpeningBalance,
	|	BalanceAndRegisteredRecords.CountClosingBalance AS CountClosingBalance,
	|	BalanceAndRegisteredRecords.WeightOpeningBalance AS WeightOpeningBalance,
	|	BalanceAndRegisteredRecords.WeightClosingBalance AS WeightClosingBalance,
	|	BalanceAndRegisteredRecords.VolumeM3OpeningBalance AS VolumeM3OpeningBalance,
	|	BalanceAndRegisteredRecords.VolumeM3ClosingBalance AS VolumeM3ClosingBalance,
	|	BalanceAndRegisteredRecords.CostOfAdmissionOpeningBalance AS CostOfAdmissionOpeningBalance,
	|	BalanceAndRegisteredRecords.CostOfAdmissionClosingBalance AS CostOfAdmissionClosingBalance,
	|	BalanceAndRegisteredRecords.AddExpensesForGoodsOpeningBalance AS AddExpensesForGoodsOpeningBalance,
	|	BalanceAndRegisteredRecords.AddExpensesForGoodsClosingBalance AS AddExpensesForGoodsClosingBalance,
	|	BalanceAndRegisteredRecords.LaborCostsOpeningBalance AS LaborCostsOpeningBalance,
	|	BalanceAndRegisteredRecords.LaborCostsClosingBalance AS LaborCostsClosingBalance,
	|	BalanceAndRegisteredRecords.ItemizedFixedOpeningBalance AS ItemizedFixedOpeningBalance,
	|	BalanceAndRegisteredRecords.ItemizedFixedClosingBalance AS ItemizedFixedClosingBalance,
	|	BalanceAndRegisteredRecords.ItemizedVariableOpeningBalance AS ItemizedVariableOpeningBalance,
	|	BalanceAndRegisteredRecords.ItemizedVariableClosingBalance AS ItemizedVariableClosingBalance,
	|	BalanceAndRegisteredRecords.Cost_OpeningBalance AS Cost_OpeningBalance,
	|	BalanceAndRegisteredRecords.Cost_ClosingBalance AS Cost_ClosingBalance,
	|	BalanceAndRegisteredRecords.TaxAccountingOpeningBalance AS TaxAccountingOpeningBalance,
	|	BalanceAndRegisteredRecords.TaxAccountingClosingBalance AS TaxAccountingClosingBalance,
	|	BalanceAndRegisteredRecords.PermanentDifferenceOpeningBalance AS PermanentDifferenceOpeningBalance,
	|	BalanceAndRegisteredRecords.PermanentDifferenceClosingBalance AS PermanentDifferenceClosingBalance,
	|	BalanceAndRegisteredRecords.CostTDOpeningBalance AS CostTDOpeningBalance,
	|	BalanceAndRegisteredRecords.CostTDClosingBalance AS CostTDClosingBalance,
	|	BalanceAndRegisteredRecords.AITOpeningBalance AS AITOpeningBalance,
	|	BalanceAndRegisteredRecords.AITClosingBalance AS AITClosingBalance,
	|	BalanceAndRegisteredRecords.OffBalanceCostOpeningBalance AS OffBalanceCostOpeningBalance,
	|	BalanceAndRegisteredRecords.OffBalanceCostClosingBalance AS OffBalanceCostClosingBalance,
	|	BalanceAndRegisteredRecords.CountReceipt AS CountReceipt,
	|	BalanceAndRegisteredRecords.CountExpense AS CountExpense,
	|	BalanceAndRegisteredRecords.WeightReceipt AS WeightReceipt,
	|	BalanceAndRegisteredRecords.WeightExpense AS WeightExpense,
	|	BalanceAndRegisteredRecords.VolumeM3Receipt AS VolumeM3Receipt,
	|	BalanceAndRegisteredRecords.VolumeM3Expense AS VolumeM3Expense,
	|	BalanceAndRegisteredRecords.CostOfAdmissionReceipt AS CostOfAdmissionReceipt,
	|	BalanceAndRegisteredRecords.CostOfAdmissionExpense AS CostOfAdmissionExpense,
	|	BalanceAndRegisteredRecords.AddExpensesForGoodsReceipt AS AddExpensesForGoodsReceipt,
	|	BalanceAndRegisteredRecords.AddExpensesForGoodsExpense AS AddExpensesForGoodsExpense,
	|	BalanceAndRegisteredRecords.LaborCostsReceipt AS LaborCostsReceipt,
	|	BalanceAndRegisteredRecords.LaborCostsExpense AS LaborCostsExpense,
	|	BalanceAndRegisteredRecords.ItemizedFixedReceipt AS ItemizedFixedReceipt,
	|	BalanceAndRegisteredRecords.ItemizedFixedExpense AS ItemizedFixedExpense,
	|	BalanceAndRegisteredRecords.ItemizedVariableReceipt AS ItemizedVariableReceipt,
	|	BalanceAndRegisteredRecords.ItemizedVariableExpense AS ItemizedVariableExpense,
	|	BalanceAndRegisteredRecords.Cost_Receipt AS Cost_Receipt,
	|	BalanceAndRegisteredRecords.Cost_Expense AS Cost_Expense,
	|	BalanceAndRegisteredRecords.TaxAccountingReceipt AS TaxAccountingReceipt,
	|	BalanceAndRegisteredRecords.TaxAccountingExpense AS TaxAccountingExpense,
	|	BalanceAndRegisteredRecords.PermanentDifferenceReceipt AS PermanentDifferenceReceipt,
	|	BalanceAndRegisteredRecords.PermanentDifferenceExpense AS PermanentDifferenceExpense,
	|	BalanceAndRegisteredRecords.CostTDReceipt AS CostTDReceipt,
	|	BalanceAndRegisteredRecords.CostTDExpense AS CostTDExpense,
	|	BalanceAndRegisteredRecords.AITReceipt AS AITReceipt,
	|	BalanceAndRegisteredRecords.AITExpense AS AITExpense,
	|	BalanceAndRegisteredRecords.OffBalanceCostReceipt AS OffBalanceCostReceipt,
	|	BalanceAndRegisteredRecords.OffBalanceCostExpense AS OffBalanceCostExpense,
	|
	|	NULL AS ItemOfExpenditureInitial,
	|	VALUE(Enum.AssetKinds.EmptyRef) AS AssetTaxClass,
	|	NULL AS SourceProducts_,
	|	NULL AS InitialCharacteristic,
	|	NULL AS SourceReceiptDocument,
	|
	|	0 AS DetailingCostOfAdmissionOpeningBalance,
	|	0 AS DetailingCostOfAdmissionClosingBalance,
	|	0 AS DetailingAdditionalExpensesOpeningBalance,
	|	0 AS DetailingAdditionalExpensesClosingBalance,
	|	0 AS DetailItemByItemConstantsOpeningBalance,
	|	0 AS DetailItemByItemConstantsClosingBalance,
	|	0 AS DetailItemByItemVariablesOpeningBalance,
	|	0 AS DetailItemByItemVariablesClosingBalance,
	|	0 AS DetailingCostOpeningBalance,
	|	0 AS DetailingCostClosingBalance,
	|	0 AS DetailingCostOfAdmissionReceipt,
	|	0 AS DetailingCostOfAdmissionExpense,
	|	0 AS DetailingAdditionalExpensesReceipt,
	|	0 AS DetailingAdditionalExpensesExpense,
	|	0 AS DetailItemByItemConstantsReceipt,
	|	0 AS DetailItemByItemConstantsExpense,
	|	0 AS DetailItemByItemVariablesReceipt,
	|	0 AS DetailItemByItemVariablesExpense,
	|	0 AS DetailingCostReceipt,
	|	0 AS DetailingCostExpense
	|{SELECT
	|	SecondPeriod,
	|	DayPeriod,
	|	WeekPeriod,
	|	TenDaysPeriod,
	|	MonthPeriod,
	|	QuarterPeriod,
	|	HalfYearPeriod,
	|	YearPeriod,
	|	VariancePeriod,
	|	ItemsLocationAttributes.*,
	|	Products.*,
	|	ReportUnitOfMeasurement.*,
	|	StorageUnit.*,
	|	UnitForReports.*,
	|	UnitFactorForReports,
	|	Characteristic.*,
	|	Series.*,
	|	Warehouse.*,
	|	Purpose.*,
	|	LineOfBusiness.*,
	|	Department.*,
	|	InventoryOwnerAttribute.*,
	|	FinancialAccountingGroup.*,
	|	Organization.*,
	|	Lot.*,
	|	LotVendorAttributes.*,
	|	AccountingSection,
	|	VATActivityType,
	|	BusinessOperation.*,
	|	AssetTaxClass.*,
	|	IncomeItem.*,
	|	ExpenseItem.*,
	|	IncomeAndExpenseItem.*,
	|	DimensionOfRevenue.*,
	|	DimensionOfExpenses.*,
	|	DimensionOfIncomeExpense.*,
	|	Contract.*,
	|	OrderDocument.*,
	|	Partner.*,
	|	Counterparty.*,
	|	Terms.*,
	|	InventoryType.*,
	|	BusinessOperationCatalog.*,
	|	EconomicOperationOfParish.*,
	|	EconomicOperationOfExpenditure.*,
	|	CostDefiningMethod,
	|	CostCalculationDate,
	|	Document.*,
	|	CountOpeningBalance,
	|	CountClosingBalance,
	|	WeightOpeningBalance,
	|	WeightClosingBalance,
	|	VolumeM3OpeningBalance,
	|	VolumeM3ClosingBalance,
	|	CostOfAdmissionOpeningBalance,
	|	CostOfAdmissionClosingBalance,
	|	AddExpensesForGoodsOpeningBalance,
	|	AddExpensesForGoodsClosingBalance,
	|	LaborCostsOpeningBalance,
	|	LaborCostsClosingBalance,
	|	ItemizedFixedOpeningBalance,
	|	ItemizedFixedClosingBalance,
	|	ItemizedVariableOpeningBalance,
	|	ItemizedVariableClosingBalance,
	|	Cost_OpeningBalance,
	|	Cost_ClosingBalance,
	|	TaxAccountingOpeningBalance,
	|	TaxAccountingClosingBalance,
	|	PermanentDifferenceOpeningBalance,
	|	PermanentDifferenceClosingBalance,
	|	CostTDOpeningBalance,
	|	CostTDClosingBalance,
	|	AITOpeningBalance,
	|	AITClosingBalance,
	|	OffBalanceCostOpeningBalance,
	|	OffBalanceCostClosingBalance,
	|	CountReceipt,
	|	CountExpense,
	|	WeightReceipt,
	|	WeightExpense,
	|	VolumeM3Receipt,
	|	VolumeM3Expense,
	|	CostOfAdmissionReceipt,
	|	CostOfAdmissionExpense,
	|	AddExpensesForGoodsReceipt,
	|	AddExpensesForGoodsExpense,
	|	LaborCostsReceipt,
	|	LaborCostsExpense,
	|	ItemizedFixedReceipt,
	|	ItemizedFixedExpense,
	|	ItemizedVariableReceipt,
	|	ItemizedVariableExpense,
	|	Cost_Receipt,
	|	Cost_Expense,
	|	TaxAccountingReceipt,
	|	TaxAccountingExpense,
	|	PermanentDifferenceReceipt,
	|	PermanentDifferenceExpense,
	|	CostTDReceipt,
	|	CostTDExpense,
	|	AITReceipt,
	|	AITExpense,
	|	OffBalanceCostReceipt,
	|	OffBalanceCostExpense,
	|	ItemOfExpenditureInitial.*,
	|	SourceProducts_.*,
	|	InitialCharacteristic.*,
	|	SourceReceiptDocument.*,
	|	DetailingCostOfAdmissionOpeningBalance,
	|	DetailingCostOfAdmissionClosingBalance,
	|	DetailingAdditionalExpensesOpeningBalance,
	|	DetailingAdditionalExpensesClosingBalance,
	|	DetailItemByItemConstantsOpeningBalance,
	|	DetailItemByItemConstantsClosingBalance,
	|	DetailItemByItemVariablesOpeningBalance,
	|	DetailItemByItemVariablesClosingBalance,
	|	DetailingCostOpeningBalance,
	|	DetailingCostClosingBalance,
	|	DetailingCostOfAdmissionReceipt,
	|	DetailingCostOfAdmissionExpense,
	|	DetailingAdditionalExpensesReceipt,
	|	DetailingAdditionalExpensesExpense,
	|	DetailItemByItemConstantsReceipt,
	|	DetailItemByItemConstantsExpense,
	|	DetailItemByItemVariablesReceipt,
	|	DetailItemByItemVariablesExpense,
	|	DetailingCostReceipt,
	|	DetailingCostExpense
	|	}
	|FROM
	|	BalanceAndRegisteredRecords AS BalanceAndRegisteredRecords
	|{WHERE
	|	BalanceAndRegisteredRecords.DayPeriod,
	|	BalanceAndRegisteredRecords.WeekPeriod,
	|	BalanceAndRegisteredRecords.TenDaysPeriod,
	|	BalanceAndRegisteredRecords.MonthPeriod,
	|	BalanceAndRegisteredRecords.QuarterPeriod,
	|	BalanceAndRegisteredRecords.HalfYearPeriod,
	|	BalanceAndRegisteredRecords.YearPeriod,
	|	BalanceAndRegisteredRecords.VariancePeriod,
	|	BalanceAndRegisteredRecords.ItemsLocationAttributes.*,
	|	BalanceAndRegisteredRecords.Products.*,
	|	BalanceAndRegisteredRecords.StorageUnit.*,
	|	BalanceAndRegisteredRecords.UnitForReports.*,
	|	BalanceAndRegisteredRecords.UnitFactorForReports,
	|	BalanceAndRegisteredRecords.Characteristic.*,
	|	BalanceAndRegisteredRecords.Series.*,
	|	BalanceAndRegisteredRecords.Warehouse.*,
	|	BalanceAndRegisteredRecords.Purpose.*,
	|	BalanceAndRegisteredRecords.LineOfBusiness.*,
	|	BalanceAndRegisteredRecords.Department.*,
	|	BalanceAndRegisteredRecords.InventoryOwnerAttribute.*,
	|	BalanceAndRegisteredRecords.FinancialAccountingGroup.*,
	|	BalanceAndRegisteredRecords.Organization.*,
	|	BalanceAndRegisteredRecords.Lot.*,
	|	BalanceAndRegisteredRecords.LotVendorAttributes.*,
	|	BalanceAndRegisteredRecords.AccountingSection,
	|	BalanceAndRegisteredRecords.VATActivityType,
	|	BalanceAndRegisteredRecords.BusinessOperation.*,
	|	BalanceAndRegisteredRecords.IncomeItem.*,
	|	BalanceAndRegisteredRecords.ExpenseItem.*,
	|	BalanceAndRegisteredRecords.IncomeAndExpenseItem.*,
	|	BalanceAndRegisteredRecords.DimensionOfRevenue.*,
	|	BalanceAndRegisteredRecords.DimensionOfExpenses.*,
	|	BalanceAndRegisteredRecords.DimensionOfIncomeExpense.*,
	|	BalanceAndRegisteredRecords.Contract.*,
	|	BalanceAndRegisteredRecords.OrderDocument.*,
	|	BalanceAndRegisteredRecords.Partner.*,
	|	BalanceAndRegisteredRecords.Counterparty.*,
	|	BalanceAndRegisteredRecords.Terms.*,
	|	BalanceAndRegisteredRecords.InventoryType.*,
	|	BalanceAndRegisteredRecords.BusinessOperationCatalog.*,
	|	BalanceAndRegisteredRecords.EconomicOperationOfParish.*,
	|	BalanceAndRegisteredRecords.EconomicOperationOfExpenditure.*,
	|	BalanceAndRegisteredRecords.CostDefiningMethod,
	|	BalanceAndRegisteredRecords.CostCalculationDate,
	|	BalanceAndRegisteredRecords.Document,
	|	BalanceAndRegisteredRecords.CountOpeningBalance,
	|	BalanceAndRegisteredRecords.CountClosingBalance,
	|	BalanceAndRegisteredRecords.WeightOpeningBalance,
	|	BalanceAndRegisteredRecords.WeightClosingBalance,
	|	BalanceAndRegisteredRecords.VolumeM3OpeningBalance,
	|	BalanceAndRegisteredRecords.VolumeM3ClosingBalance,
	|	BalanceAndRegisteredRecords.CostOfAdmissionOpeningBalance,
	|	BalanceAndRegisteredRecords.CostOfAdmissionClosingBalance,
	|	BalanceAndRegisteredRecords.AddExpensesForGoodsOpeningBalance,
	|	BalanceAndRegisteredRecords.AddExpensesForGoodsClosingBalance,
	|	BalanceAndRegisteredRecords.LaborCostsOpeningBalance,
	|	BalanceAndRegisteredRecords.LaborCostsClosingBalance,
	|	BalanceAndRegisteredRecords.ItemizedFixedOpeningBalance,
	|	BalanceAndRegisteredRecords.ItemizedFixedClosingBalance,
	|	BalanceAndRegisteredRecords.ItemizedVariableOpeningBalance,
	|	BalanceAndRegisteredRecords.ItemizedVariableClosingBalance,
	|	BalanceAndRegisteredRecords.Cost_OpeningBalance,
	|	BalanceAndRegisteredRecords.Cost_ClosingBalance,
	|	BalanceAndRegisteredRecords.TaxAccountingOpeningBalance,
	|	BalanceAndRegisteredRecords.TaxAccountingClosingBalance,
	|	BalanceAndRegisteredRecords.PermanentDifferenceOpeningBalance,
	|	BalanceAndRegisteredRecords.PermanentDifferenceClosingBalance,
	|	BalanceAndRegisteredRecords.CostTDOpeningBalance,
	|	BalanceAndRegisteredRecords.CostTDClosingBalance,
	|	BalanceAndRegisteredRecords.AITOpeningBalance,
	|	BalanceAndRegisteredRecords.AITClosingBalance,
	|	BalanceAndRegisteredRecords.OffBalanceCostOpeningBalance,
	|	BalanceAndRegisteredRecords.OffBalanceCostClosingBalance,
	|	BalanceAndRegisteredRecords.CountReceipt,
	|	BalanceAndRegisteredRecords.CountExpense,
	|	BalanceAndRegisteredRecords.WeightReceipt,
	|	BalanceAndRegisteredRecords.WeightExpense,
	|	BalanceAndRegisteredRecords.VolumeM3Receipt,
	|	BalanceAndRegisteredRecords.VolumeM3Expense,
	|	BalanceAndRegisteredRecords.CostOfAdmissionReceipt,
	|	BalanceAndRegisteredRecords.CostOfAdmissionExpense,
	|	BalanceAndRegisteredRecords.AddExpensesForGoodsReceipt,
	|	BalanceAndRegisteredRecords.AddExpensesForGoodsExpense,
	|	BalanceAndRegisteredRecords.LaborCostsReceipt,
	|	BalanceAndRegisteredRecords.LaborCostsExpense,
	|	BalanceAndRegisteredRecords.ItemizedFixedReceipt,
	|	BalanceAndRegisteredRecords.ItemizedFixedExpense,
	|	BalanceAndRegisteredRecords.ItemizedVariableReceipt,
	|	BalanceAndRegisteredRecords.ItemizedVariableExpense,
	|	BalanceAndRegisteredRecords.Cost_Receipt,
	|	BalanceAndRegisteredRecords.Cost_Expense,
	|	BalanceAndRegisteredRecords.TaxAccountingReceipt,
	|	BalanceAndRegisteredRecords.TaxAccountingExpense,
	|	BalanceAndRegisteredRecords.PermanentDifferenceReceipt,
	|	BalanceAndRegisteredRecords.PermanentDifferenceExpense,
	|	BalanceAndRegisteredRecords.CostTDReceipt,
	|	BalanceAndRegisteredRecords.CostTDExpense,
	|	BalanceAndRegisteredRecords.AITReceipt,
	|	BalanceAndRegisteredRecords.AITExpense,
	|	BalanceAndRegisteredRecords.OffBalanceCostReceipt,
	|	BalanceAndRegisteredRecords.OffBalanceCostExpense
	|	}
	|
	|UNION ALL
	|
	|SELECT
	|	TT_BalanceAndRegisteredRecords.MonthPeriod AS SecondPeriod,
	|	TT_BalanceAndRegisteredRecords.MonthPeriod AS DayPeriod,
	|	TT_BalanceAndRegisteredRecords.MonthPeriod AS WeekPeriod,
	|	TT_BalanceAndRegisteredRecords.MonthPeriod AS TenDaysPeriod,
	|	TT_BalanceAndRegisteredRecords.MonthPeriod AS MonthPeriod,
	|	BEGINOFPERIOD(TT_BalanceAndRegisteredRecords.MonthPeriod, QUARTER) AS QuarterPeriod,
	|	BEGINOFPERIOD(TT_BalanceAndRegisteredRecords.MonthPeriod, HALFYEAR) AS HalfYearPeriod,
	|	BEGINOFPERIOD(TT_BalanceAndRegisteredRecords.MonthPeriod, YEAR) AS YearPeriod,
	|	DATETIME(1,1,1) AS VariancePeriod,
	|	TT_BalanceAndRegisteredRecords.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TT_BalanceAndRegisteredRecords.Products AS Products,
	|	(CASE
	|		WHEN &QuantityUnits = 0 THEN TT_BalanceAndRegisteredRecords.StorageUnit
	|		WHEN &QuantityUnits = 1 THEN TT_BalanceAndRegisteredRecords.UnitForReports
	|	END) AS ReportUnitOfMeasurement,
	|	TT_BalanceAndRegisteredRecords.StorageUnit AS StorageUnit,
	|	TT_BalanceAndRegisteredRecords.UnitForReports AS UnitForReports,
	|	TT_BalanceAndRegisteredRecords.UnitFactorForReports AS UnitFactorForReports,
	|	TT_BalanceAndRegisteredRecords.Characteristic AS Characteristic,
	|	TT_BalanceAndRegisteredRecords.Series AS Series,
	|	TT_BalanceAndRegisteredRecords.Warehouse AS Warehouse,
	|	TT_BalanceAndRegisteredRecords.Purpose AS Purpose,
	|	TT_BalanceAndRegisteredRecords.LineOfBusiness AS LineOfBusiness,
	|	NULL AS Department,
	|	TT_BalanceAndRegisteredRecords.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TT_BalanceAndRegisteredRecords.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	TT_BalanceAndRegisteredRecords.Organization AS Organization,
	|	TT_BalanceAndRegisteredRecords.Lot AS Lot,
	|	TT_BalanceAndRegisteredRecords.LotVendorAttributes AS LotVendorAttributes,
	|	TT_BalanceAndRegisteredRecords.AccountingSection AS AccountingSection,
	|	TT_BalanceAndRegisteredRecords.VATActivityType AS VATActivityType,
	|	NULL AS BusinessOperation,
	|	NULL AS IncomeItem,
	|	NULL AS ExpenseItem,
	|	NULL AS IncomeAndExpenseItem,
	|	NULL AS DimensionOfRevenue,
	|	NULL AS DimensionOfExpenses,
	|	NULL AS DimensionOfIncomeExpense,
	|	NULL AS Contract,
	|	NULL AS OrderDocument,
	|	NULL AS Partner,
	|	NULL AS Counterparty,
	|	NULL AS Terms,
	|	NULL AS InventoryType,
	|	NULL AS BusinessOperationCatalog,
	|	NULL AS EconomicOperationOfParish,
	|	NULL AS EconomicOperationOfExpenditure,
	|	NULL AS CostDefiningMethod,
	|	NULL AS CostCalculationDate,
	|	NULL AS Document,
	|	0 AS CountOpeningBalance,
	|	0 AS CountClosingBalance,
	|	0 AS WeightOpeningBalance,
	|	0 AS WeightClosingBalance,
	|	0 AS VolumeM3OpeningBalance,
	|	0 AS VolumeM3ClosingBalance,
	|	0 AS CostOfAdmissionOpeningBalance,
	|	0 AS CostOfAdmissionClosingBalance,
	|	0 AS AddExpensesForGoodsOpeningBalance,
	|	0 AS AddExpensesForGoodsClosingBalance,
	|	0 AS LaborCostsOpeningBalance,
	|	0 AS LaborCostsClosingBalance,
	|	0 AS ItemizedFixedOpeningBalance,
	|	0 AS ItemizedFixedClosingBalance,
	|	0 AS ItemizedVariableOpeningBalance,
	|	0 AS ItemizedVariableClosingBalance,
	|	0 AS Cost_OpeningBalance,
	|	0 AS Cost_ClosingBalance,
	|	0 AS TaxAccountingOpeningBalance,
	|	0 AS TaxAccountingClosingBalance,
	|	0 AS PermanentDifferenceOpeningBalance,
	|	0 AS PermanentDifferenceClosingBalance,
	|	0 AS CostTDOpeningBalance,
	|	0 AS CostTDClosingBalance,
	|	0 AS AITOpeningBalance,
	|	0 AS AITClosingBalance,
	|	0 AS OffBalanceCostOpeningBalance,
	|	0 AS OffBalanceCostClosingBalance,
	|	0 AS CountReceipt,
	|	0 AS CountExpense,
	|	0 AS WeightReceipt,
	|	0 AS WeightExpense,
	|	0 AS VolumeM3Receipt,
	|	0 AS VolumeM3Expense,
	|	0 AS CostOfAdmissionReceipt,
	|	0 AS CostOfAdmissionExpense,
	|	0 AS AddExpensesForGoodsReceipt,
	|	0 AS AddExpensesForGoodsExpense,
	|	0 AS LaborCostsReceipt,
	|	0 AS LaborCostsExpense,
	|	0 AS ItemizedFixedReceipt,
	|	0 AS ItemizedFixedExpense,
	|	0 AS ItemizedVariableReceipt,
	|	0 AS ItemizedVariableExpense,
	|	0 AS Cost_Receipt,
	|	0 AS Cost_Expense,
	|	0 AS TaxAccountingReceipt,
	|	0 AS TaxAccountingExpense,
	|	0 AS PermanentDifferenceReceipt,
	|	0 AS PermanentDifferenceExpense,
	|	0 AS CostTDReceipt,
	|	0 AS CostTDExpense,
	|	0 AS AITReceipt,
	|	0 AS AITExpense,
	|	0 AS OffBalanceCostReceipt,
	|	0 AS OffBalanceCostExpense,
	|
	|	GranularityGrouped.ItemOfExpenditureInitial AS ItemOfExpenditureInitial,
	|	GranularityGrouped.AssetTaxClass AS AssetTaxClass,
	|	GranularityGrouped.SourceProducts_ AS SourceProducts_,
	|	GranularityGrouped.InitialCharacteristic AS InitialCharacteristic,
	|	GranularityGrouped.SourceReceiptDocument AS SourceReceiptDocument,
	|
	|	(GranularityGrouped.InitialMaterialCostsPerUnit
	|	+ (CASE WHEN TT_BalanceAndRegisteredRecords.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|		THEN GranularityGrouped.InitialVATPerUnit ELSE 0 END)
	|	+ (CASE WHEN TT_BalanceAndRegisteredRecords.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|		THEN GranularityGrouped.InitialVATPerUnitAtBeginning ELSE 0 END)
	|	+ GranularityGrouped.InitialMaterialCostsPerUnitAtBeginning)
	|		* TT_BalanceAndRegisteredRecords.CountOpeningBalance AS DetailingCostOfAdmissionOpeningBalance,
	|	(GranularityGrouped.InitialMaterialCostsPerUnit
	|	+ (CASE WHEN TT_BalanceAndRegisteredRecords.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|		THEN GranularityGrouped.InitialVATPerUnit ELSE 0 END)
	|	+ (CASE WHEN TT_BalanceAndRegisteredRecords.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|		THEN GranularityGrouped.InitialVATPerUnitAtEnd ELSE 0 END)
	|	+ GranularityGrouped.InitialMaterialCostsPerUnitAtEnd)
	|		* TT_BalanceAndRegisteredRecords.CountClosingBalance AS DetailingCostOfAdmissionClosingBalance,
	|	(GranularityGrouped.InitialAdditionalCostsPerUnit
	|	+ GranularityGrouped.InitialAdditionalCostsPerUnitAtBeginning)
	|		* TT_BalanceAndRegisteredRecords.CountOpeningBalance AS DetailingAdditionalExpensesOpeningBalance,
	|	GranularityGrouped.InitialAdditionalCostsPerUnitForPeriod
	|		* CASE WHEN TT_BalanceAndRegisteredRecords.CountReceipt = 0 AND TT_BalanceAndRegisteredRecords.CountExpense = 0
	|			THEN TT_BalanceAndRegisteredRecords.CountClosingBalance
	|			ELSE 0 
	|		END +
	|	(GranularityGrouped.InitialAdditionalCostsPerUnit
	|	+ GranularityGrouped.InitialAdditionalUnitCostsAtEnd)
	|		* TT_BalanceAndRegisteredRecords.CountClosingBalance AS DetailingAdditionalExpensesClosingBalance,
	|	(GranularityGrouped.InitialArticleByArticleConstantsPerUnit
	|	+ GranularityGrouped.InitialArticleByArticleConstantsPerUnitAtBeginning)
	|		* TT_BalanceAndRegisteredRecords.CountOpeningBalance AS DetailItemByItemConstantsOpeningBalance,
	|	(GranularityGrouped.InitialArticleByArticleConstantsPerUnit
	|	+ GranularityGrouped.InitialArticleByArticleConstantsPerUnitAtEnd)
	|		* TT_BalanceAndRegisteredRecords.CountClosingBalance AS DetailItemByItemConstantsClosingBalance,
	|	(GranularityGrouped.InitialArticleByArticleVariablesPerUnit
	|	+ GranularityGrouped.InitialArticleByArticleVariablesPerUnitAtBeginning)
	|		* TT_BalanceAndRegisteredRecords.CountOpeningBalance AS DetailItemByItemVariablesOpeningBalance,
	|	(GranularityGrouped.InitialArticleByArticleVariablesPerUnit
	|	+ GranularityGrouped.OriginalLineByLineVariablesAreOneAtEnd)
	|		* TT_BalanceAndRegisteredRecords.CountClosingBalance AS DetailItemByItemVariablesClosingBalance,
	|	(GranularityGrouped.InitialMaterialCostsPerUnit
	|	+ (CASE WHEN TT_BalanceAndRegisteredRecords.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|		THEN GranularityGrouped.InitialVATPerUnit ELSE 0 END)
	|	+ (CASE WHEN TT_BalanceAndRegisteredRecords.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|		THEN GranularityGrouped.InitialVATPerUnitAtBeginning ELSE 0 END)
	|	+ GranularityGrouped.InitialMaterialCostsPerUnitAtBeginning
	|	+ GranularityGrouped.InitialAdditionalCostsPerUnit
	|	+ GranularityGrouped.InitialAdditionalCostsPerUnitAtBeginning
	|	+ GranularityGrouped.InitialArticleByArticleConstantsPerUnit
	|	+ GranularityGrouped.InitialArticleByArticleConstantsPerUnitAtBeginning
	|	+ GranularityGrouped.InitialArticleByArticleVariablesPerUnit
	|	+ GranularityGrouped.InitialArticleByArticleVariablesPerUnitAtBeginning)
	|		* TT_BalanceAndRegisteredRecords.CountOpeningBalance AS DetailingCostOpeningBalance,
	|	GranularityGrouped.InitialAdditionalCostsPerUnitForPeriod
	|		* CASE WHEN TT_BalanceAndRegisteredRecords.CountReceipt = 0 AND TT_BalanceAndRegisteredRecords.CountExpense = 0 
	|			THEN TT_BalanceAndRegisteredRecords.CountClosingBalance
	|			ELSE 0 
	|		END +
	|	(GranularityGrouped.InitialMaterialCostsPerUnit
	|	+ (CASE WHEN TT_BalanceAndRegisteredRecords.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|		THEN GranularityGrouped.InitialVATPerUnit ELSE 0 END)
	|	+ (CASE WHEN TT_BalanceAndRegisteredRecords.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|		THEN GranularityGrouped.InitialVATPerUnitAtEnd ELSE 0 END)
	|	+ GranularityGrouped.InitialMaterialCostsPerUnitAtEnd
	|	+ GranularityGrouped.InitialAdditionalCostsPerUnit
	|	+ GranularityGrouped.InitialAdditionalUnitCostsAtEnd
	|	+ GranularityGrouped.InitialArticleByArticleConstantsPerUnit
	|	+ GranularityGrouped.InitialArticleByArticleConstantsPerUnitAtEnd
	|	+ GranularityGrouped.InitialArticleByArticleVariablesPerUnit
	|	+ GranularityGrouped.OriginalLineByLineVariablesAreOneAtEnd)
	|		* TT_BalanceAndRegisteredRecords.CountClosingBalance AS DetailingCostClosingBalance,
	|	(GranularityGrouped.InitialMaterialCostsPerUnit
	|	+ (CASE WHEN TT_BalanceAndRegisteredRecords.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|		THEN GranularityGrouped.InitialVATPerUnit ELSE 0 END)
	|	+ (CASE WHEN TT_BalanceAndRegisteredRecords.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|		THEN GranularityGrouped.InitialVATPerUnitForPeriod ELSE 0 END)
	|	+ GranularityGrouped.InitialMaterialCostsPerUnitForPeriod)
	|		* CASE WHEN TT_BalanceAndRegisteredRecords.CountReceipt = 0 AND TT_BalanceAndRegisteredRecords.AddExpensesForGoodsReceipt <> 0
	|			THEN GranularityGrouped.LotQuantity
	|			ELSE TT_BalanceAndRegisteredRecords.CountReceipt END AS DetailingCostOfAdmissionReceipt,
	|	(GranularityGrouped.InitialMaterialCostsPerUnit
	|	+ (CASE WHEN TT_BalanceAndRegisteredRecords.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|		THEN GranularityGrouped.InitialVATPerUnit ELSE 0 END)
	|	+ (CASE WHEN TT_BalanceAndRegisteredRecords.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|		THEN GranularityGrouped.InitialVATPerUnitForPeriod ELSE 0 END)
	|	+ GranularityGrouped.InitialMaterialCostsPerUnitForPeriod)
	|		* TT_BalanceAndRegisteredRecords.CountExpense AS DetailingCostOfAdmissionExpense,
	|	(GranularityGrouped.InitialAdditionalCostsPerUnit
	|	+ GranularityGrouped.InitialAdditionalCostsPerUnitForPeriod)
	|		* CASE WHEN TT_BalanceAndRegisteredRecords.CountReceipt = 0 AND TT_BalanceAndRegisteredRecords.AddExpensesForGoodsReceipt <> 0
	|			THEN GranularityGrouped.LotQuantity
	|			ELSE TT_BalanceAndRegisteredRecords.CountReceipt END AS DetailingAdditionalExpensesReceipt,
	|	(GranularityGrouped.InitialAdditionalCostsPerUnit
	|	+ GranularityGrouped.InitialAdditionalCostsPerUnitForPeriod)
	|		* TT_BalanceAndRegisteredRecords.CountExpense AS DetailingAdditionalExpensesExpense,
	|	(GranularityGrouped.InitialArticleByArticleConstantsPerUnit
	|	+ GranularityGrouped.InitialArticleByArticleConstantsPerUnitForPeriod)
	|		* CASE WHEN TT_BalanceAndRegisteredRecords.CountReceipt = 0 AND TT_BalanceAndRegisteredRecords.AddExpensesForGoodsReceipt <> 0
	|			THEN GranularityGrouped.LotQuantity
	|			ELSE TT_BalanceAndRegisteredRecords.CountReceipt END AS DetailItemByItemConstantsReceipt,
	|	(GranularityGrouped.InitialArticleByArticleConstantsPerUnit
	|	+ GranularityGrouped.InitialArticleByArticleConstantsPerUnitForPeriod)
	|		* TT_BalanceAndRegisteredRecords.CountExpense AS DetailItemByItemConstantsExpense,
	|	(GranularityGrouped.InitialArticleByArticleVariablesPerUnit
	|	+ GranularityGrouped.InitialItemByItemVariablesPerUnitForPeriod)
	|		* CASE WHEN TT_BalanceAndRegisteredRecords.CountReceipt = 0 AND TT_BalanceAndRegisteredRecords.AddExpensesForGoodsReceipt <> 0
	|			THEN GranularityGrouped.LotQuantity
	|			ELSE TT_BalanceAndRegisteredRecords.CountReceipt END AS DetailItemByItemVariablesReceipt,
	|	(GranularityGrouped.InitialArticleByArticleVariablesPerUnit
	|	+ GranularityGrouped.InitialItemByItemVariablesPerUnitForPeriod)
	|		* TT_BalanceAndRegisteredRecords.CountExpense AS DetailItemByItemVariablesExpense,
	|	(GranularityGrouped.InitialMaterialCostsPerUnit
	|	+ (CASE WHEN TT_BalanceAndRegisteredRecords.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|		THEN GranularityGrouped.InitialVATPerUnit ELSE 0 END)
	|	+ (CASE WHEN TT_BalanceAndRegisteredRecords.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|		THEN GranularityGrouped.InitialVATPerUnitForPeriod ELSE 0 END)
	|	+ GranularityGrouped.InitialMaterialCostsPerUnitForPeriod
	|	+ GranularityGrouped.InitialAdditionalCostsPerUnit
	|	+ GranularityGrouped.InitialAdditionalCostsPerUnitForPeriod
	|	+ GranularityGrouped.InitialArticleByArticleConstantsPerUnit
	|	+ GranularityGrouped.InitialArticleByArticleConstantsPerUnitForPeriod
	|	+ GranularityGrouped.InitialArticleByArticleVariablesPerUnit
	|	+ GranularityGrouped.InitialItemByItemVariablesPerUnitForPeriod)
	|		* CASE WHEN TT_BalanceAndRegisteredRecords.CountReceipt = 0 AND TT_BalanceAndRegisteredRecords.AddExpensesForGoodsReceipt <> 0
	|			THEN GranularityGrouped.LotQuantity
	|			ELSE TT_BalanceAndRegisteredRecords.CountReceipt END AS DetailingCostReceipt,
	|	(GranularityGrouped.InitialMaterialCostsPerUnit
	|	+ (CASE WHEN TT_BalanceAndRegisteredRecords.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|		THEN GranularityGrouped.InitialVATPerUnit ELSE 0 END)
	|	+ (CASE WHEN TT_BalanceAndRegisteredRecords.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|		THEN GranularityGrouped.InitialVATPerUnitForPeriod ELSE 0 END)
	|	+ GranularityGrouped.InitialMaterialCostsPerUnitForPeriod
	|	+ GranularityGrouped.InitialAdditionalCostsPerUnit
	|	+ GranularityGrouped.InitialAdditionalCostsPerUnitForPeriod
	|	+ GranularityGrouped.InitialArticleByArticleConstantsPerUnit
	|	+ GranularityGrouped.InitialArticleByArticleConstantsPerUnitForPeriod
	|	+ GranularityGrouped.InitialArticleByArticleVariablesPerUnit
	|	+ GranularityGrouped.InitialItemByItemVariablesPerUnitForPeriod)
	|		* TT_BalanceAndRegisteredRecords.CountExpense AS DetailingCostExpense
	|FROM
	|	TT_DetailingInitialCosts AS GranularityGrouped
	|		INNER JOIN VT_BalancesAndRegisteredRecordsForSelectionOfDetailsOfInitialCosts AS TT_BalanceAndRegisteredRecords
	|		ON TT_BalanceAndRegisteredRecords.Products = GranularityGrouped.Products
	|			AND TT_BalanceAndRegisteredRecords.Characteristic = GranularityGrouped.Characteristic
	|			AND TT_BalanceAndRegisteredRecords.InventoryOwnerAttribute = GranularityGrouped.InventoryOwnerAttribute
	|			AND TT_BalanceAndRegisteredRecords.Organization = GranularityGrouped.Organization
	|			AND TT_BalanceAndRegisteredRecords.Lot = GranularityGrouped.Lot
	|			AND TT_BalanceAndRegisteredRecords.LotVendorAttributes = GranularityGrouped.LotVendorAttributes
	|			AND (GranularityGrouped.ItemsLocationAttributes = UNDEFINED
	|				OR GranularityGrouped.ItemsLocationAttributes = TT_BalanceAndRegisteredRecords.ItemsLocationAttributes)
	|			AND (GranularityGrouped.InitialCostPeriod = DATETIME(1, 1, 1)
	|				OR GranularityGrouped.InitialCostPeriod = TT_BalanceAndRegisteredRecords.MonthPeriod)
	|{WHERE
	|	TT_BalanceAndRegisteredRecords.MonthPeriod AS DayPeriod,
	|	TT_BalanceAndRegisteredRecords.MonthPeriod AS WeekPeriod,
	|	TT_BalanceAndRegisteredRecords.MonthPeriod AS TenDaysPeriod,
	|	TT_BalanceAndRegisteredRecords.MonthPeriod AS MonthPeriod,
	|	TT_BalanceAndRegisteredRecords.MonthPeriod AS QuarterPeriod,
	|	TT_BalanceAndRegisteredRecords.MonthPeriod AS HalfYearPeriod,
	|	TT_BalanceAndRegisteredRecords.MonthPeriod AS YearPeriod,
	|	DATETIME(1,1,1) AS VariancePeriod,
	|	TT_BalanceAndRegisteredRecords.ItemsLocationAttributes.*,
	|	TT_BalanceAndRegisteredRecords.Products.*,
	|	TT_BalanceAndRegisteredRecords.StorageUnit.*,
	|	TT_BalanceAndRegisteredRecords.UnitForReports.*,
	|	TT_BalanceAndRegisteredRecords.UnitFactorForReports,
	|	TT_BalanceAndRegisteredRecords.Characteristic.*,
	|	TT_BalanceAndRegisteredRecords.Series.*,
	|	TT_BalanceAndRegisteredRecords.Warehouse.*,
	|	TT_BalanceAndRegisteredRecords.Purpose.*,
	|	TT_BalanceAndRegisteredRecords.LineOfBusiness.*,
	|	TT_BalanceAndRegisteredRecords.InventoryOwnerAttribute.*,
	|	TT_BalanceAndRegisteredRecords.FinancialAccountingGroup.*,
	|	TT_BalanceAndRegisteredRecords.Organization.*,
	|	TT_BalanceAndRegisteredRecords.Lot.*,
	|	TT_BalanceAndRegisteredRecords.LotVendorAttributes.*,
	|	TT_BalanceAndRegisteredRecords.AccountingSection,
	|	TT_BalanceAndRegisteredRecords.VATActivityType,
	|	(ISNULL(GranularityGrouped.SourceProducts_, VALUE(Catalog.Products.EmptyRef))).* AS SourceProducts_,
	|	(ISNULL(GranularityGrouped.InitialCharacteristic, VALUE(Catalog.ItemsCharacteristics.EmptyRef))).* AS InitialCharacteristic,
	|	(ISNULL(GranularityGrouped.SourceReceiptDocument, UNDEFINED)).* AS SourceReceiptDocument,
	|	(ISNULL(GranularityGrouped.ItemOfExpenditureInitial, VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef))).* AS ItemOfExpenditureInitial}
	|
	|";
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region Private

#Region QueriesTexts

Function QueryTextSelectionByProductSegment()
	
	QueryText =
	"SELECT ALLOWED DISTINCT
	|	Segments.Products AS Products,
	|	Segments.Characteristic AS Characteristic,
	|	TRUE AS FilterByProductSegmentIsUsed
	|INTO SelectionByProductSegment
	|FROM
	|	InformationRegister.SegmentProducts AS Segments
	|{WHERE
	|	Segments.Segment.* AS ProductSegment,
	|	Segments.Products.* AS Products,
	|	Segments.Characteristic.* AS Characteristic}
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	FilterByProductSegmentIsUsed";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTCost_()
	
	QueryText =
	"SELECT ALLOWED
	|	InventoryCost.Period AS SecondPeriod,
	|	BEGINOFPERIOD(InventoryCost.Period, DAY) AS DayPeriod,
	|	BEGINOFPERIOD(InventoryCost.Period, WEEK) AS WeekPeriod,
	|	BEGINOFPERIOD(InventoryCost.Period, TENDAYS) AS TenDaysPeriod,
	|	BEGINOFPERIOD(InventoryCost.Period, MONTH) AS MonthPeriod,
	|	BEGINOFPERIOD(InventoryCost.Period, QUARTER) AS QuarterPeriod,
	|	BEGINOFPERIOD(InventoryCost.Period, HALFYEAR) AS HalfYearPeriod,
	|	BEGINOFPERIOD(InventoryCost.Period, YEAR) AS YearPeriod,
	|	BEGINOFPERIOD(InventoryCost.VariancePeriod, MONTH) AS VariancePeriod,
	|	InventoryCost.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	DimensionOfProductItem.Products AS Products,
	|	DimensionOfProductItem.Products.UnitOfMeasure AS StorageUnit,
	|	DimensionOfProductItem.Products.UnitForReports AS UnitForReports,
	|	DimensionOfProductItem.Products.UnitFactorForReports AS UnitFactorForReports,
	|	DimensionOfProductItem.Characteristic AS Characteristic,
	|	DimensionOfProductItem.Series AS Series,
	|	DimensionOfProductItem.StorageLocation AS Warehouse,
	|	DimensionOfProductItem.Purpose AS Purpose,
	|	DimensionOfProductItem.Purpose.LineOfBusiness AS LineOfBusiness,
	|	InventoryCost.Department AS Department,
	|	InventoryCost.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|		THEN InventoryCost.InventoryOwnerAttribute.FinancialAccountingGroup
	|		ELSE DimensionOfProductItem.Products.FinancialAccountingGroup
	|	END AS FinancialAccountingGroup,
	|	InventoryCost.Organization,
	|	InventoryCost.Lot,
	|	InventoryCost.LotVendorAttributes,
	|	InventoryCost.AccountingSection,
	|	InventoryCost.VATActivityType,
	|	InventoryCost.BusinessOperation,
	|	InventoryCost.IncomeItem,
	|	InventoryCost.ExpenseItemOfWriteOff AS ExpenseItem,
	|	CASE
	|		WHEN NOT InventoryCost.IncomeItem.Ref IS NULL
	|			THEN InventoryCost.IncomeItem
	|		WHEN NOT InventoryCost.ExpenseItemOfWriteOff.Ref IS NULL
	|			THEN InventoryCost.ExpenseItemOfWriteOff
	|	END AS IncomeAndExpenseItem,
	|	InventoryCost.DimensionOfRevenue,
	|	InventoryCost.DimensionOfExpenses,
	|	CASE
	|		WHEN NOT VALUETYPE(InventoryCost.DimensionOfRevenue) IS NULL
	|			THEN InventoryCost.DimensionOfRevenue
	|		WHEN NOT VALUETYPE(InventoryCost.DimensionOfExpenses) IS NULL
	|			THEN InventoryCost.DimensionOfExpenses
	|	END AS DimensionOfIncomeExpense,
	|	RevenueAndCOGS.Contract AS Contract,
	|	RevenueAndCOGS.SalesOrder AS OrderDocument,
	|	(CASE
	|		WHEN NOT Register3.Partner IS NULL THEN Register3.Partner
	|		ELSE PartnerAnalytics_.Partner END) AS Partner,
	|	(CASE
	|		WHEN NOT RegistryKey.Key IS NULL 
	|			AND VALUETYPE(RegistryKey.Key) = TYPE(Catalog.Counterparties)
	|			THEN RegistryKey.Key
	|		ELSE PartnerAnalytics_.Counterparty END) AS Counterparty,
	|	RevenueAndCOGS.Terms AS Terms,
	|	RevenueAndCOGS.InventoryType AS InventoryType,
	|	BsnsTransactionsSettings.Ref AS BusinessOperationCatalog,
	|	InventoryCost.RecordType = VALUE(AccumulationRecordType.Receipt) AS EconomicOperationOfParish,
	|	InventoryCost.RecordType = VALUE(AccumulationRecordType.Expense) AS EconomicOperationOfExpenditure,
	|	InventoryCost.CostDefiningMethod AS CostDefiningMethod,
	|	InventoryCost.CostCalculationDate AS CostCalculationDate,
	|	InventoryCost.Recorder AS Document,
	|	CASE
	|		WHEN InventoryCost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN 1
	|		ELSE 0
	|	END * InventoryCost.Count AS CountReceipt,
	|	CASE
	|		WHEN InventoryCost.RecordType = VALUE(AccumulationRecordType.Expense)
	|		THEN 1
	|		ELSE 0
	|	END * InventoryCost.Count AS CountExpense,
	|	CASE
	|		WHEN InventoryCost.RecordType = VALUE(AccumulationRecordType.Expense)
	|		THEN 0
	|		WHEN &ReportData = 1
	|		THEN InventoryCost.Cost + InventoryCost.OffBalanceCost
	|		WHEN &ReportData = 2
	|		THEN InventoryCost.CostExcludingVAT + InventoryCost.OffBalanceCost
	|		WHEN &ReportData = 3
	|		THEN InventoryCost.CostMan + InventoryCost.OffBalanceCost
	|		WHEN &ReportData = 4
	|		THEN InventoryCost.LocalCost + InventoryCost.OffBalanceCostLocal
	|		WHEN &ByEnterprise
	|		THEN InventoryCost.Cost + InventoryCost.OffBalanceCost
	|		ELSE InventoryCost.CostMan + InventoryCost.OffBalanceCost
	|	END AS CostOfAdmissionReceipt,
	|	CASE
	|		WHEN InventoryCost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN 0
	|		WHEN &ReportData = 1
	|		THEN InventoryCost.Cost + InventoryCost.OffBalanceCost
	|		WHEN &ReportData = 2
	|		THEN InventoryCost.CostExcludingVAT + InventoryCost.OffBalanceCost
	|		WHEN &ReportData = 3
	|		THEN InventoryCost.CostMan + InventoryCost.OffBalanceCost
	|		WHEN &ReportData = 4
	|		THEN InventoryCost.LocalCost + InventoryCost.OffBalanceCostLocal
	|		WHEN &ByEnterprise
	|		THEN InventoryCost.Cost + InventoryCost.OffBalanceCost
	|		ELSE InventoryCost.CostMan + InventoryCost.OffBalanceCost
	|	END AS CostOfAdmissionExpense,
	|	CASE
	|		WHEN InventoryCost.RecordType = VALUE(AccumulationRecordType.Expense)
	|		THEN 0
	|		WHEN &ReportData = 1
	|		THEN InventoryCost.AddExpensesForGoods
	|		WHEN &ReportData = 2
	|		THEN InventoryCost.AdditionalExpensesExcludingVAT
	|		WHEN &ReportData = 3
	|		THEN InventoryCost.AddExpensesMan
	|		WHEN &ReportData = 4
	|		THEN InventoryCost.AddExpensesLocal
	|		WHEN &ByEnterprise
	|		THEN InventoryCost.AdditionalExpensesExcludingVAT
	|		ELSE InventoryCost.AddExpensesMan
	|	END AS AddExpensesForGoodsReceipt,
	|	CASE
	|		WHEN InventoryCost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN 0
	|		WHEN &ReportData = 1
	|		THEN InventoryCost.AddExpensesForGoods
	|		WHEN &ReportData = 2
	|		THEN InventoryCost.AdditionalExpensesExcludingVAT
	|		WHEN &ReportData = 3
	|		THEN InventoryCost.AddExpensesMan
	|		WHEN &ReportData = 4
	|		THEN InventoryCost.AddExpensesLocal
	|		WHEN &ByEnterprise
	|		THEN InventoryCost.AdditionalExpensesExcludingVAT
	|		ELSE InventoryCost.AddExpensesMan
	|	END AS AddExpensesForGoodsExpense,
	|	CASE
	|		WHEN InventoryCost.RecordType = VALUE(AccumulationRecordType.Expense)
	|		THEN 0
	|		WHEN &ReportData = 1
	|		THEN InventoryCost.LaborCosts
	|		WHEN &ReportData = 2
	|		THEN InventoryCost.LaborCosts
	|		WHEN &ReportData = 3
	|		THEN InventoryCost.LaborCostsMan
	|		WHEN &ReportData = 4
	|		THEN InventoryCost.LaborCostsLocal
	|		WHEN &ByEnterprise
	|		THEN InventoryCost.LaborCosts
	|		ELSE InventoryCost.LaborCostsMan
	|	END AS LaborCostsReceipt,
	|	CASE
	|		WHEN InventoryCost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN 0
	|		WHEN &ReportData = 1
	|		THEN InventoryCost.LaborCosts
	|		WHEN &ReportData = 2
	|		THEN InventoryCost.LaborCosts
	|		WHEN &ReportData = 3
	|		THEN InventoryCost.LaborCostsMan
	|		WHEN &ReportData = 4
	|		THEN InventoryCost.LaborCostsLocal
	|		WHEN &ByEnterprise
	|		THEN InventoryCost.LaborCosts
	|		ELSE InventoryCost.LaborCostsMan
	|	END AS LaborCostsExpense,
	|	CASE
	|		WHEN InventoryCost.RecordType = VALUE(AccumulationRecordType.Expense)
	|		THEN 0
	|		WHEN &ReportData = 1
	|		THEN InventoryCost.ItemizedFixedCostsIncludingVAT
	|		WHEN &ReportData = 2
	|		THEN InventoryCost.ItemizedFixedCostsExcludingVAT
	|		WHEN &ReportData = 3
	|		THEN InventoryCost.ItemizedFixedCostsManag
	|		WHEN &ReportData = 4
	|		THEN InventoryCost.ItemizedFixedCostsCompl
	|		WHEN &ByEnterprise
	|		THEN InventoryCost.ItemizedFixedCostsExcludingVAT
	|		ELSE InventoryCost.ItemizedFixedCostsManag
	|	END AS ItemizedFixedReceipt,
	|	CASE
	|		WHEN InventoryCost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN 0
	|		WHEN &ReportData = 1
	|		THEN InventoryCost.ItemizedFixedCostsIncludingVAT
	|		WHEN &ReportData = 2
	|		THEN InventoryCost.ItemizedFixedCostsExcludingVAT
	|		WHEN &ReportData = 3
	|		THEN InventoryCost.ItemizedFixedCostsManag
	|		WHEN &ReportData = 4
	|		THEN InventoryCost.ItemizedFixedCostsCompl
	|		WHEN &ByEnterprise
	|		THEN InventoryCost.ItemizedFixedCostsExcludingVAT
	|		ELSE InventoryCost.ItemizedFixedCostsManag
	|	END AS ItemizedFixedExpense,
	|	CASE
	|		WHEN InventoryCost.RecordType = VALUE(AccumulationRecordType.Expense)
	|		THEN 0
	|		WHEN &ReportData = 1
	|		THEN InventoryCost.ItemizedVariableCostsIncludingVAT
	|		WHEN &ReportData = 2
	|		THEN InventoryCost.ItemizedVariableCostsExcludingVAT
	|		WHEN &ReportData = 3
	|		THEN InventoryCost.ItemizedVariableCostsManag
	|		WHEN &ReportData = 4
	|		THEN InventoryCost.ItemizedVariableCostsCompl
	|		WHEN &ByEnterprise
	|		THEN InventoryCost.ItemizedVariableCostsExcludingVAT
	|		ELSE InventoryCost.ItemizedVariableCostsManag
	|	END AS ItemizedVariableReceipt,
	|	CASE
	|		WHEN InventoryCost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN 0
	|		WHEN &ReportData = 1
	|		THEN InventoryCost.ItemizedVariableCostsIncludingVAT
	|		WHEN &ReportData = 2
	|		THEN InventoryCost.ItemizedVariableCostsExcludingVAT
	|		WHEN &ReportData = 3
	|		THEN InventoryCost.ItemizedVariableCostsManag
	|		WHEN &ReportData = 4
	|		THEN InventoryCost.ItemizedVariableCostsCompl
	|		WHEN &ByEnterprise
	|		THEN InventoryCost.ItemizedVariableCostsExcludingVAT
	|		ELSE InventoryCost.ItemizedVariableCostsManag
	|	END AS ItemizedVariableExpense,
	|	CASE
	|		WHEN InventoryCost.RecordType = VALUE(AccumulationRecordType.Expense)
	|		THEN 0
	|		WHEN &ReportData = 1
	|		THEN InventoryCost.Cost + InventoryCost.AddExpensesForGoods + InventoryCost.OffBalanceCost + InventoryCost.LaborCosts + InventoryCost.ItemizedFixedCostsIncludingVAT + InventoryCost.ItemizedVariableCostsIncludingVAT
	|		WHEN &ReportData = 2
	|		THEN InventoryCost.CostExcludingVAT + InventoryCost.AdditionalExpensesExcludingVAT + InventoryCost.OffBalanceCost + InventoryCost.LaborCosts + InventoryCost.ItemizedFixedCostsExcludingVAT + InventoryCost.ItemizedVariableCostsExcludingVAT
	|		WHEN &ReportData = 3
	|		THEN InventoryCost.CostMan + InventoryCost.AddExpensesMan + InventoryCost.OffBalanceCost + InventoryCost.LaborCostsMan + InventoryCost.ItemizedFixedCostsManag + InventoryCost.ItemizedVariableCostsManag
	|		WHEN &ReportData = 4
	|		THEN InventoryCost.LocalCost + InventoryCost.AddExpensesLocal + InventoryCost.OffBalanceCostLocal + InventoryCost.LaborCostsLocal + InventoryCost.ItemizedFixedCostsCompl + InventoryCost.ItemizedVariableCostsCompl
	|		WHEN &ByEnterprise
	|		THEN InventoryCost.CostExcludingVAT + InventoryCost.AdditionalExpensesExcludingVAT + InventoryCost.OffBalanceCost + InventoryCost.LaborCosts + InventoryCost.ItemizedFixedCostsExcludingVAT + InventoryCost.ItemizedVariableCostsExcludingVAT
	|		ELSE InventoryCost.CostMan + InventoryCost.AddExpensesMan + InventoryCost.OffBalanceCost + InventoryCost.LaborCostsMan + InventoryCost.ItemizedFixedCostsManag + InventoryCost.ItemizedVariableCostsManag
	|	END AS Cost_Receipt,
	|	CASE
	|		WHEN InventoryCost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN 0
	|		WHEN &ReportData = 1
	|		THEN InventoryCost.Cost + InventoryCost.AddExpensesForGoods + InventoryCost.OffBalanceCost + InventoryCost.LaborCosts + InventoryCost.ItemizedFixedCostsIncludingVAT + InventoryCost.ItemizedVariableCostsIncludingVAT
	|		WHEN &ReportData = 2
	|		THEN InventoryCost.CostExcludingVAT + InventoryCost.AdditionalExpensesExcludingVAT + InventoryCost.OffBalanceCost + InventoryCost.LaborCosts + InventoryCost.ItemizedFixedCostsExcludingVAT + InventoryCost.ItemizedVariableCostsExcludingVAT
	|		WHEN &ReportData = 3
	|		THEN InventoryCost.CostMan + InventoryCost.AddExpensesMan + InventoryCost.OffBalanceCost + InventoryCost.LaborCostsMan + InventoryCost.ItemizedFixedCostsManag + InventoryCost.ItemizedVariableCostsManag
	|		WHEN &ReportData = 4
	|		THEN InventoryCost.LocalCost + InventoryCost.AddExpensesLocal + InventoryCost.OffBalanceCostLocal + InventoryCost.LaborCostsLocal + InventoryCost.ItemizedFixedCostsCompl + InventoryCost.ItemizedVariableCostsCompl
	|		WHEN &ByEnterprise
	|		THEN InventoryCost.CostExcludingVAT + InventoryCost.AdditionalExpensesExcludingVAT + InventoryCost.OffBalanceCost + InventoryCost.LaborCosts + InventoryCost.ItemizedFixedCostsExcludingVAT + InventoryCost.ItemizedVariableCostsExcludingVAT
	|		ELSE InventoryCost.CostMan + InventoryCost.AddExpensesMan + InventoryCost.OffBalanceCost + InventoryCost.LaborCostsMan + InventoryCost.ItemizedFixedCostsManag + InventoryCost.ItemizedVariableCostsManag
	|	END AS Cost_Expense,
	|	CASE
	|		WHEN &ReportData = 4 AND InventoryCost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN InventoryCost.LocalCost + InventoryCost.AddExpensesLocal + InventoryCost.OffBalanceCostLocal + InventoryCost.LaborCostsLocal + InventoryCost.ItemizedFixedCostsCompl + InventoryCost.ItemizedVariableCostsCompl - InventoryCost.PermanentDifference - InventoryCost.CostTD
	|		ELSE 0
	|	END AS TaxAccountingReceipt,
	|	CASE
	|		WHEN &ReportData = 4 AND InventoryCost.RecordType = VALUE(AccumulationRecordType.Expense)
	|		THEN InventoryCost.LocalCost + InventoryCost.AddExpensesLocal + InventoryCost.OffBalanceCostLocal + InventoryCost.LaborCostsLocal + InventoryCost.ItemizedFixedCostsCompl + InventoryCost.ItemizedVariableCostsCompl - InventoryCost.PermanentDifference - InventoryCost.CostTD
	|		ELSE 0
	|	END AS TaxAccountingExpense,
	|	CASE
	|		WHEN &ReportData = 4 AND InventoryCost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN InventoryCost.PermanentDifference
	|		ELSE 0
	|	END AS PermanentDifferenceReceipt,
	|	CASE
	|		WHEN &ReportData = 4 AND InventoryCost.RecordType = VALUE(AccumulationRecordType.Expense)
	|		THEN InventoryCost.PermanentDifference
	|		ELSE 0
	|	END AS PermanentDifferenceExpense,
	|	CASE
	|		WHEN &ReportData = 4 AND InventoryCost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN InventoryCost.CostTD
	|		ELSE 0
	|	END AS CostTDReceipt,
	|	CASE
	|		WHEN &ReportData = 4 AND InventoryCost.RecordType = VALUE(AccumulationRecordType.Expense)
	|		THEN InventoryCost.CostTD
	|		ELSE 0
	|	END AS CostTDExpense,
	|	CASE
	|		WHEN &ReportData = 4 AND InventoryCost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN InventoryCost.CostOfPersonalIncomeTax
	|		ELSE 0
	|	END AS AITReceipt,
	|	CASE
	|		WHEN &ReportData = 4 AND InventoryCost.RecordType = VALUE(AccumulationRecordType.Expense)
	|		THEN InventoryCost.CostOfPersonalIncomeTax
	|		ELSE 0
	|	END AS AITExpense,
	|	CASE
	|		WHEN InventoryCost.RecordType = VALUE(AccumulationRecordType.Expense)
	|		THEN 0
	|		WHEN &ReportData = 1 OR &ReportData = 2 OR &ReportData = 3
	|		THEN InventoryCost.OffBalanceCost
	|		WHEN &ReportData = 4
	|		THEN InventoryCost.OffBalanceCostLocal
	|		ELSE 0
	|	END AS OffBalanceCostReceipt,
	|	CASE
	|		WHEN InventoryCost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN 0
	|		WHEN &ReportData = 1 OR &ReportData = 2 OR &ReportData = 3
	|		THEN InventoryCost.OffBalanceCost
	|		WHEN &ReportData = 4
	|		THEN InventoryCost.OffBalanceCostLocal
	|		ELSE 0
	|	END AS OffBalanceCostExpense
	|{SELECT
	|	SecondPeriod,
	|	DayPeriod,
	|	WeekPeriod,
	|	TenDaysPeriod,
	|	MonthPeriod,
	|	QuarterPeriod,
	|	HalfYearPeriod,
	|	YearPeriod,
	|	VariancePeriod,
	|	ItemsLocationAttributes.*,
	|	Products.*,
	|	StorageUnit.*,
	|	UnitForReports.*,
	|	UnitFactorForReports,
	|	Characteristic.*,
	|	Series.*,
	|	Warehouse.*,
	|	Purpose.*,
	|	LineOfBusiness.*,
	|	Department.*,
	|	InventoryOwnerAttribute.*,
	|	FinancialAccountingGroup.*,
	|	Organization.*,
	|	Lot.*,
	|	LotVendorAttributes.*,
	|	AccountingSection,
	|	VATActivityType,
	|	BusinessOperation.*,
	|	IncomeItem.*,
	|	ExpenseItem.*,
	|	IncomeAndExpenseItem.*,
	|	DimensionOfRevenue.*,
	|	DimensionOfExpenses.*,
	|	DimensionOfIncomeExpense.*,
	|	Contract.*,
	|	OrderDocument.*,
	|	Partner.*,
	|	Counterparty.*,
	|	Terms.*,
	|	InventoryType.*,
	|	BusinessOperationCatalog.*,
	|	EconomicOperationOfParish.*,
	|	EconomicOperationOfExpenditure.*,
	|	CostDefiningMethod,
	|	CostCalculationDate,
	|	Document.*,
	|	CountReceipt,
	|	CountExpense,
	|	UnitFactorForReports AS CountReceipt,
	|	UnitFactorForReports AS CountExpense,
	|	CountReceipt AS WeightReceipt,
	|	CountExpense AS WeightExpense,
	|	CountReceipt AS VolumeM3Receipt,
	|	CountExpense AS VolumeM3Expense,
	|	StorageUnit AS WeightReceipt,
	|	StorageUnit AS WeightExpense,
	|	StorageUnit AS VolumeM3Receipt,
	|	StorageUnit AS VolumeM3Expense,
	|	Products AS WeightReceipt,
	|	Products AS WeightExpense,
	|	Products AS VolumeM3Receipt,
	|	Products AS VolumeM3Expense,
	|	CostOfAdmissionReceipt,
	|	CostOfAdmissionExpense,
	|	AddExpensesForGoodsReceipt,
	|	AddExpensesForGoodsExpense,
	|	OffBalanceCostReceipt,
	|	OffBalanceCostExpense,
	|	LaborCostsReceipt,
	|	LaborCostsExpense,
	|	ItemizedFixedReceipt,
	|	ItemizedFixedExpense,
	|	ItemizedVariableReceipt,
	|	ItemizedVariableExpense,
	|	Cost_Receipt,
	|	Cost_Expense,
	|	TaxAccountingReceipt,
	|	TaxAccountingExpense,
	|	PermanentDifferenceReceipt,
	|	PermanentDifferenceExpense,
	|	CostTDReceipt,
	|	CostTDExpense,
	|	AITReceipt,
	|	AITExpense}
	|
	|INTO TTCostPrice
	|FROM
	|	AccumulationRegister.InventoryCost AS InventoryCost
	|		{LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionOfProductItem
	|		ON InventoryCost.ItemsLocationAttributes = DimensionOfProductItem.Ref}
	|		{LEFT JOIN Catalog.KeysForLotVendorAttributes AS DimensionOfLots
	|		ON (DimensionOfLots.Ref = InventoryCost.LotVendorAttributes)}
	|		{LEFT JOIN AccumulationRegister.RevenueAndCOGS AS RevenueAndCOGS
	|		ON InventoryCost.FinRecordID = RevenueAndCOGS.FinRecordID}
	|		{LEFT JOIN InformationRegister.AccountingDimensionByPartners AS PartnerAnalytics_
	|		ON InventoryCost.AccountingDimensionByPartners = PartnerAnalytics_.DimensionKey
	|			AND InventoryCost.AccountingDimensionByPartners <> VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef)}
	|		{LEFT JOIN InformationRegister.DocumentsRegistry AS Register3
	|		ON Register3.Ref = InventoryCost.Recorder
	|			AND NOT Register3.AdditionalRecord
	|			AND (InventoryCost.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.ExternalReceipt)
	// To return goods to the supplier, we connect via the utility. operations,
	// because deviations in the cost of goods (income) may be formed with an empty operationaccounting for the cost.
	|				OR InventoryCost.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsToVendor))
	|		LEFT JOIN Catalog.DocumentRegistryKeys AS RegistryKey
	|		ON Register3.Counterparty = RegistryKey.Ref
	|		}
	|		{LEFT JOIN Catalog.BusinessTransactionsSettings AS BsnsTransactionsSettings
	|		ON (BsnsTransactionsSettings.BusinessOperation = InventoryCost.BusinessOperation)}
	|WHERE
	|	InventoryCost.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND InventoryCost.Organization IN (&CompanyArray)
	|	AND NOT (InventoryCost.BusinessOperation IN (&ExcludedBusinessTransactions) AND &ExcludeBusinessTransactions)
	|	AND InventoryCost.BusinessOperation <> VALUE(Enum.BusinessTransactions.WriteOffVariancesToAllocate)
	|{WHERE
	|	(InventoryCost.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod),
	|	((DimensionOfProductItem.Products, DimensionOfProductItem.Characteristic) IN
	|			(SELECT
	|				SelectionByProductSegment.Products,
	|				SelectionByProductSegment.Characteristic
	|			FROM
	|				SelectionByProductSegment
	|			WHERE
	|				SelectionByProductSegment.FilterByProductSegmentIsUsed = &FilterByProductSegmentIsUsed)),
	|	DimensionOfProductItem.Products.* AS Products,
	|	DimensionOfProductItem.Products.UnitOfMeasure.* AS UnitOfMeasure,
	|	DimensionOfProductItem.Products.UnitForReports.* AS UnitForReports,
	|	DimensionOfProductItem.Characteristic.* AS Characteristic,
	|	DimensionOfProductItem.Series.* AS Series,
	|	DimensionOfProductItem.StorageLocation.* AS Warehouse,
	|	DimensionOfProductItem.Purpose.* AS Purpose,
	|	DimensionOfProductItem.Purpose.LineOfBusiness.* AS LineOfBusiness,
	|	InventoryCost.Department.* AS Department,
	|	InventoryCost.Organization.* AS Organization,
	|	InventoryCost.InventoryOwnerAttribute.* AS InventoryOwnerAttribute,
	|	InventoryCost.Lot.* AS Lot,
	|	(BEGINOFPERIOD(InventoryCost.Period, DAY)) AS DayPeriod,
	|	(BEGINOFPERIOD(InventoryCost.Period, WEEK)) AS WeekPeriod,
	|	(BEGINOFPERIOD(InventoryCost.Period, TENDAYS)) AS TenDaysPeriod,
	|	(BEGINOFPERIOD(InventoryCost.Period, MONTH)) AS MonthPeriod,
	|	(BEGINOFPERIOD(InventoryCost.Period, QUARTER)) AS QuarterPeriod,
	|	(BEGINOFPERIOD(InventoryCost.Period, HALFYEAR)) AS HalfYearPeriod,
	|	(BEGINOFPERIOD(InventoryCost.Period, YEAR)) AS YearPeriod,
	|	(BEGINOFPERIOD(InventoryCost.VariancePeriod, MONTH)) AS VariancePeriod,
	|	(CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|		THEN InventoryCost.InventoryOwnerAttribute.FinancialAccountingGroup
	|		ELSE DimensionOfProductItem.Products.FinancialAccountingGroup
	|	END).* AS FinancialAccountingGroup,
	|	InventoryCost.ItemsLocationAttributes.* AS ItemsLocationAttributes,
	|	InventoryCost.LotVendorAttributes.* AS LotVendorAttributes,
	|	InventoryCost.AccountingSection AS AccountingSection,
	|	InventoryCost.VATActivityType AS VATActivityType,
	|	InventoryCost.BusinessOperation AS BusinessOperation,
	|	InventoryCost.IncomeItem.* AS IncomeItem,
	|	InventoryCost.ExpenseItemOfWriteOff.* AS ExpenseItem,
	|	(CASE
	|		WHEN NOT InventoryCost.IncomeItem.Ref IS NULL
	|		THEN InventoryCost.IncomeItem
	|		WHEN NOT InventoryCost.ExpenseItemOfWriteOff.Ref IS NULL
	|		THEN InventoryCost.ExpenseItemOfWriteOff
	|	END).* AS IncomeAndExpenseItem,
	|	InventoryCost.DimensionOfRevenue.* AS DimensionOfRevenue,
	|	InventoryCost.DimensionOfExpenses.* AS DimensionOfExpenses,
	|	(CASE
	|		WHEN NOT VALUETYPE(InventoryCost.DimensionOfRevenue) IS NULL
	|		THEN InventoryCost.DimensionOfRevenue
	|		WHEN NOT VALUETYPE(InventoryCost.DimensionOfExpenses) IS NULL
	|		THEN InventoryCost.DimensionOfExpenses
	|	END).* AS DimensionOfIncomeExpense,
	|	RevenueAndCOGS.Contract.* AS Contract,
	|	RevenueAndCOGS.SalesOrder.* AS OrderDocument,
	|	(CASE
	|		WHEN NOT Register3.Partner IS NULL THEN Register3.Partner
	|		ELSE PartnerAnalytics_.Partner END).* AS Partner,
	|	(CASE WHEN NOT RegistryKey.Key IS NULL AND VALUETYPE(RegistryKey.Key) = TYPE(Catalog.Counterparties)
	|		THEN RegistryKey.Key ELSE PartnerAnalytics_.Counterparty END).* AS Counterparty,
	|	RevenueAndCOGS.Terms.* AS Terms,
	|	RevenueAndCOGS.InventoryType.* AS InventoryType,
	|	BsnsTransactionsSettings.Ref.* AS BusinessOperationCatalog,
	|	InventoryCost.RecordType = VALUE(AccumulationRecordType.Receipt) AS EconomicOperationOfParish,
	|	InventoryCost.RecordType = VALUE(AccumulationRecordType.Expense) AS EconomicOperationOfExpenditure,
	|	InventoryCost.CostDefiningMethod AS CostDefiningMethod,
	|	InventoryCost.CostCalculationDate AS CostCalculationDate,
	|	InventoryCost.Recorder AS Document}";

	Return QueryText;
	
EndFunction

Function QueryTextBalanceAndRegisteredRecords(SourceDebuggingMode)
	
	NestedRequestTexts = New Array;
	
	#Region InitializationOfTemporaryTableOfBalancesAndRegisteredRecordsPreliminary
	QueryText =
	"SELECT TOP 0
	|	//The ""Initialization"" tab mode AS A data SourceData,
	|	DATETIME(1, 1, 1) AS SecondPeriod,
	|	DATETIME(1, 1, 1) AS DayPeriod,
	|	DATETIME(1, 1, 1) AS WeekPeriod,
	|	DATETIME(1, 1, 1) AS TenDaysPeriod,
	|	DATETIME(1, 1, 1) AS MonthPeriod,
	|	DATETIME(1, 1, 1) AS QuarterPeriod,
	|	DATETIME(1, 1, 1) AS HalfYearPeriod,
	|	DATETIME(1, 1, 1) AS YearPeriod,
	|
	|	DATETIME(1, 1, 1) AS VariancePeriod,
	|
	|	UNDEFINED AS ItemsLocationAttributes,
	|	UNDEFINED AS Products,
	|	UNDEFINED AS StorageUnit,
	|	UNDEFINED AS UnitForReports,
	|	0 AS UnitFactorForReports,
	|	UNDEFINED AS Characteristic,
	|	UNDEFINED AS Series,
	|	UNDEFINED AS Warehouse,
	|	UNDEFINED AS Purpose,
	|	UNDEFINED AS LineOfBusiness,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	|	UNDEFINED AS InventoryOwnerAttribute,
	|	UNDEFINED AS FinancialAccountingGroup,
	|	UNDEFINED AS Organization,
	|	UNDEFINED AS Lot,
	|	UNDEFINED AS LotVendorAttributes,
	|	UNDEFINED AS AccountingSection,
	|	UNDEFINED AS VATActivityType,
	|	VALUE(Enum.BusinessTransactions.EmptyRef) AS BusinessOperation,
	|	VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef) AS IncomeItem,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
	|	UNDEFINED AS IncomeAndExpenseItem,
	|	UNDEFINED AS DimensionOfRevenue,
	|	UNDEFINED AS DimensionOfExpenses,
	|	UNDEFINED AS DimensionOfIncomeExpense,
	|	UNDEFINED AS Contract,
	|	VALUE(Document.SalesOrder.EmptyRef) AS OrderDocument,
	|	VALUE(Catalog.Partners.EmptyRef) AS Partner,
	|	VALUE(Catalog.Counterparties.EmptyRef) AS Counterparty,
	|	VALUE(Catalog.TermsOfSale.EmptyRef) AS Terms,
	|	VALUE(Enum.InventoryTypes.EmptyRef) AS InventoryType,
	|	VALUE(Catalog.BusinessTransactionsSettings.EmptyRef) AS BusinessOperationCatalog,
	|	FALSE AS EconomicOperationOfParish,
	|	FALSE AS EconomicOperationOfExpenditure,
	|	VALUE(Enum.WaysToCalculateInventoryCost.EmptyRef) AS CostDefiningMethod,
	|	DATETIME(1,1,1,0,0,0) AS CostCalculationDate,
	|	UNDEFINED AS Document,
	|	0 AS CountOpeningBalance,
	|	0 AS CountClosingBalance,
	|	0 AS CostOfAdmissionOpeningBalance,
	|	0 AS CostOfAdmissionClosingBalance,
	|	0 AS AddExpensesForGoodsOpeningBalance,
	|	0 AS AddExpensesForGoodsClosingBalance,
	|	0 AS LaborCostsOpeningBalance,
	|	0 AS LaborCostsClosingBalance,
	|	0 AS ItemizedFixedOpeningBalance,
	|	0 AS ItemizedFixedClosingBalance,
	|	0 AS ItemizedVariableOpeningBalance,
	|	0 AS ItemizedVariableClosingBalance,
	|	0 AS Cost_OpeningBalance,
	|	0 AS Cost_ClosingBalance,
	|	0 AS TaxAccountingOpeningBalance,
	|	0 AS TaxAccountingClosingBalance,
	|	0 AS PermanentDifferenceOpeningBalance,
	|	0 AS PermanentDifferenceClosingBalance,
	|	0 AS CostTDOpeningBalance,
	|	0 AS CostTDClosingBalance,
	|	0 AS OffBalanceCostOpeningBalance,
	|	0 AS OffBalanceCostClosingBalance,
	|	0 AS AITOpeningBalance,
	|	0 AS AITClosingBalance,
	|	0 AS CountReceipt,
	|	0 AS CountExpense,
	|	0 AS CostOfAdmissionReceipt,
	|	0 AS CostOfAdmissionExpense,
	|	0 AS AddExpensesForGoodsReceipt,
	|	0 AS AddExpensesForGoodsExpense,
	|	0 AS LaborCostsReceipt,
	|	0 AS LaborCostsExpense,
	|	0 AS ItemizedFixedReceipt,
	|	0 AS ItemizedFixedExpense,
	|	0 AS ItemizedVariableReceipt,
	|	0 AS ItemizedVariableExpense,
	|	0 AS Cost_Receipt,
	|	0 AS Cost_Expense,
	|	0 AS TaxAccountingReceipt,
	|	0 AS TaxAccountingExpense,
	|	0 AS PermanentDifferenceReceipt,
	|	0 AS PermanentDifferenceExpense,
	|	0 AS CostTDReceipt,
	|	0 AS CostTDExpense,
	|	0 AS OffBalanceCostReceipt,
	|	0 AS OffBalanceCostExpense,
	|	0 AS AITReceipt,
	|	0 AS AITExpense
	|INTO BalanceAndRegisteredRecordsPreliminary";
	If SourceDebuggingMode Then
		NestedRequestTexts.Add(QueryText);
	EndIf;
	#EndRegion
	
	#Region Balance
	QueryText =
	"SELECT
	|	//Balance Tab settings AS A DATA source,
	|	InventoryCostBalance.SecondPeriod AS SecondPeriod,
	|	InventoryCostBalance.DayPeriod AS DayPeriod,
	// Filling in the Period fields... should be the same in all subqueries.
	// Using the Period START expression allows you to create Period fields... on the same principle.
	// Without this, the periods from the virtual table of turnover balances may differ from the periods obtained through the expressions of the BEGINNING of the PERIOD,
	// which will result in incorrect grouping by the Period... field, because the period obtained from the virtual table of TURNOVER balances begins
	// on the date of the beginning of the period and will differ from the period obtained through the expression of the BEGINNING of the PERIOD, if the beginning of the period is not equal to the beginning of the month, 
	// the beginning of the week, etc. etc.
	|	BEGINOFPERIOD(InventoryCostBalance.WeekPeriod, WEEK) AS WeekPeriod,
	|	BEGINOFPERIOD(InventoryCostBalance.TenDaysPeriod, TENDAYS) AS TenDaysPeriod,
	|	BEGINOFPERIOD(InventoryCostBalance.MonthPeriod, MONTH) AS MonthPeriod,
	|	BEGINOFPERIOD(InventoryCostBalance.QuarterPeriod, QUARTER) AS QuarterPeriod,
	|	BEGINOFPERIOD(InventoryCostBalance.HalfYearPeriod, HALFYEAR) AS HalfYearPeriod,
	|	BEGINOFPERIOD(InventoryCostBalance.YearPeriod, YEAR) AS YearPeriod,
	|
	|	DATETIME(1,1,1) AS VariancePeriod,
	|
	|	InventoryCostBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	DimensionOfProductItem.Products AS Products,
	|	DimensionOfProductItem.Products.UnitOfMeasure AS StorageUnit,
	|	DimensionOfProductItem.Products.UnitForReports AS UnitForReports,
	|	DimensionOfProductItem.Products.UnitFactorForReports AS UnitFactorForReports,
	|	DimensionOfProductItem.Characteristic AS Characteristic,
	|	DimensionOfProductItem.Series AS Series,
	|	DimensionOfProductItem.StorageLocation AS Warehouse,
	|	DimensionOfProductItem.Purpose AS Purpose,
	|	DimensionOfProductItem.Purpose.LineOfBusiness AS LineOfBusiness,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	|	InventoryCostBalance.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN InventoryCostBalance.InventoryOwnerAttribute.FinancialAccountingGroup
	|		ELSE DimensionOfProductItem.Products.FinancialAccountingGroup
	|	END AS FinancialAccountingGroup,
	|	InventoryCostBalance.Organization AS Organization,
	|	InventoryCostBalance.Lot AS Lot,
	|	InventoryCostBalance.LotVendorAttributes AS LotVendorAttributes,
	|	InventoryCostBalance.AccountingSection AS AccountingSection,
	|	InventoryCostBalance.VATActivityType AS VATActivityType,
	|	VALUE(Enum.BusinessTransactions.EmptyRef) AS BusinessOperation,
	|	VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef) AS IncomeItem,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
	|	UNDEFINED AS IncomeAndExpenseItem,
	|	UNDEFINED AS DimensionOfRevenue,
	|	UNDEFINED AS DimensionOfExpenses,
	|	UNDEFINED AS DimensionOfIncomeExpense,
	|	UNDEFINED AS Contract,
	|	VALUE(Document.SalesOrder.EmptyRef) AS OrderDocument,
	|	VALUE(Catalog.Partners.EmptyRef) AS Partner,
	|	VALUE(Catalog.Counterparties.EmptyRef) AS Counterparty,
	|	VALUE(Catalog.TermsOfSale.EmptyRef) AS Terms,
	|	VALUE(Enum.InventoryTypes.EmptyRef) AS InventoryType,
	|	VALUE(Catalog.BusinessTransactionsSettings.EmptyRef) AS BusinessOperationCatalog,
	|	FALSE AS EconomicOperationOfParish,
	|	FALSE AS EconomicOperationOfExpenditure,
	|	VALUE(Enum.WaysToCalculateInventoryCost.EmptyRef) AS CostDefiningMethod,
	|	DATETIME(1,1,1,0,0,0) AS CostCalculationDate,
	|	InventoryCostBalance.Recorder AS Document,
	|	InventoryCostBalance.CountOpeningBalance AS CountOpeningBalance,
	|	InventoryCostBalance.CountClosingBalance AS CountClosingBalance,
	|	CASE
	|		WHEN &ReportData = 1
	|		THEN InventoryCostBalance.CostOpeningBalance + InventoryCostBalance.OffBalanceCostOpeningBalance
	|		WHEN &ReportData = 2
	|		THEN InventoryCostBalance.CostExcludingVATOpeningBalance + InventoryCostBalance.OffBalanceCostOpeningBalance
	|		WHEN &ReportData = 3
	|		THEN InventoryCostBalance.CostManOpeningBalance + InventoryCostBalance.OffBalanceCostOpeningBalance
	|		WHEN &ReportData = 4
	|		THEN InventoryCostBalance.LocalCostOpeningBalance + InventoryCostBalance.OffBalanceCostLocalOpeningBalance
	|		WHEN &ByEnterprise
	|		THEN InventoryCostBalance.CostExcludingVATOpeningBalance + InventoryCostBalance.OffBalanceCostOpeningBalance
	|		ELSE InventoryCostBalance.CostManOpeningBalance + InventoryCostBalance.OffBalanceCostOpeningBalance
	|	END AS CostOfAdmissionOpeningBalance,
	|	CASE
	|		WHEN &ReportData = 1
	|		THEN InventoryCostBalance.CostClosingBalance + InventoryCostBalance.OffBalanceCostClosingBalance
	|		WHEN &ReportData = 2
	|		THEN InventoryCostBalance.CostExcludingVATClosingBalance + InventoryCostBalance.OffBalanceCostClosingBalance
	|		WHEN &ReportData = 3
	|		THEN InventoryCostBalance.CostManClosingBalance + InventoryCostBalance.OffBalanceCostClosingBalance
	|		WHEN &ReportData = 4
	|		THEN InventoryCostBalance.LocalCostClosingBalance + InventoryCostBalance.OffBalanceCostLocalClosingBalance
	|		WHEN &ByEnterprise
	|		THEN InventoryCostBalance.CostExcludingVATClosingBalance + InventoryCostBalance.OffBalanceCostClosingBalance
	|		ELSE InventoryCostBalance.CostManClosingBalance + InventoryCostBalance.OffBalanceCostClosingBalance
	|	END AS CostOfAdmissionClosingBalance,
	|	CASE
	|		WHEN &ReportData = 1
	|		THEN InventoryCostBalance.AddExpensesForGoodsOpeningBalance
	|		WHEN &ReportData = 2
	|		THEN InventoryCostBalance.AdditionalExpensesExcludingVATOpeningBalance
	|		WHEN &ReportData = 3
	|		THEN InventoryCostBalance.AddExpensesManOpeningBalance
	|		WHEN &ReportData = 4
	|		THEN InventoryCostBalance.AddExpensesLocalOpeningBalance
	|		WHEN &ByEnterprise
	|		THEN InventoryCostBalance.AdditionalExpensesExcludingVATOpeningBalance
	|		ELSE InventoryCostBalance.AddExpensesManOpeningBalance
	|	END AS AddExpensesForGoodsOpeningBalance,
	|	CASE
	|		WHEN &ReportData = 1
	|		THEN InventoryCostBalance.AddExpensesForGoodsClosingBalance
	|		WHEN &ReportData = 2
	|		THEN InventoryCostBalance.AdditionalExpensesExcludingVATClosingBalance
	|		WHEN &ReportData = 3
	|		THEN InventoryCostBalance.AddExpensesManClosingBalance
	|		WHEN &ReportData = 4
	|		THEN InventoryCostBalance.AddExpensesLocalClosingBalance
	|		WHEN &ByEnterprise
	|		THEN InventoryCostBalance.AdditionalExpensesExcludingVATClosingBalance
	|		ELSE InventoryCostBalance.AddExpensesManClosingBalance
	|	END AS AddExpensesForGoodsClosingBalance,
	|	CASE
	|		WHEN &ReportData = 1
	|		THEN InventoryCostBalance.LaborCostsOpeningBalance
	|		WHEN &ReportData = 2
	|		THEN InventoryCostBalance.LaborCostsOpeningBalance
	|		WHEN &ReportData = 3
	|		THEN InventoryCostBalance.LaborCostsManOpeningBalance
	|		WHEN &ReportData = 4
	|		THEN InventoryCostBalance.LaborCostsLocalOpeningBalance
	|		WHEN &ByEnterprise
	|		THEN InventoryCostBalance.LaborCostsOpeningBalance
	|		ELSE InventoryCostBalance.LaborCostsManOpeningBalance
	|	END AS LaborCostsOpeningBalance,
	|	CASE
	|		WHEN &ReportData = 1
	|		THEN InventoryCostBalance.LaborCostsClosingBalance
	|		WHEN &ReportData = 2
	|		THEN InventoryCostBalance.LaborCostsClosingBalance
	|		WHEN &ReportData = 3
	|		THEN InventoryCostBalance.LaborCostsManClosingBalance
	|		WHEN &ReportData = 4
	|		THEN InventoryCostBalance.LaborCostsLocalClosingBalance
	|		WHEN &ByEnterprise
	|		THEN InventoryCostBalance.LaborCostsClosingBalance
	|		ELSE InventoryCostBalance.LaborCostsManClosingBalance
	|	END AS LaborCostsClosingBalance,
	|	CASE
	|		WHEN &ReportData = 1
	|		THEN InventoryCostBalance.ItemizedFixedCostsIncludingVATOpeningBalance
	|		WHEN &ReportData = 2
	|		THEN InventoryCostBalance.ItemizedFixedCostsExcludingVATOpeningBalance
	|		WHEN &ReportData = 3
	|		THEN InventoryCostBalance.ItemizedFixedCostsManagOpeningBalance
	|		WHEN &ReportData = 4
	|		THEN InventoryCostBalance.ItemizedFixedCostsComplOpeningBalance
	|		WHEN &ByEnterprise
	|		THEN InventoryCostBalance.ItemizedFixedCostsExcludingVATOpeningBalance
	|		ELSE InventoryCostBalance.ItemizedFixedCostsManagOpeningBalance
	|	END AS ItemizedFixedOpeningBalance,
	|	CASE
	|		WHEN &ReportData = 1
	|		THEN InventoryCostBalance.ItemizedFixedCostsIncludingVATClosingBalance
	|		WHEN &ReportData = 2
	|		THEN InventoryCostBalance.ItemizedFixedCostsExcludingVATClosingBalance
	|		WHEN &ReportData = 3
	|		THEN InventoryCostBalance.ItemizedFixedCostsManagClosingBalance
	|		WHEN &ReportData = 4
	|		THEN InventoryCostBalance.ItemizedFixedCostsComplClosingBalance
	|		WHEN &ByEnterprise
	|		THEN InventoryCostBalance.ItemizedFixedCostsExcludingVATClosingBalance
	|		ELSE InventoryCostBalance.ItemizedFixedCostsManagClosingBalance
	|	END AS ItemizedFixedClosingBalance,
	|	CASE
	|		WHEN &ReportData = 1
	|		THEN InventoryCostBalance.ItemizedVariableCostsIncludingVATOpeningBalance
	|		WHEN &ReportData = 2
	|		THEN InventoryCostBalance.ItemizedVariableCostsExcludingVATOpeningBalance
	|		WHEN &ReportData = 3
	|		THEN InventoryCostBalance.ItemizedVariableCostsManagOpeningBalance
	|		WHEN &ReportData = 4
	|		THEN InventoryCostBalance.ItemizedVariableCostsComplOpeningBalance
	|		WHEN &ByEnterprise
	|		THEN InventoryCostBalance.ItemizedVariableCostsExcludingVATOpeningBalance
	|		ELSE InventoryCostBalance.ItemizedVariableCostsManagOpeningBalance
	|	END AS ItemizedVariableOpeningBalance,
	|	CASE
	|		WHEN &ReportData = 1
	|		THEN InventoryCostBalance.ItemizedVariableCostsIncludingVATClosingBalance
	|		WHEN &ReportData = 2
	|		THEN InventoryCostBalance.ItemizedVariableCostsExcludingVATClosingBalance
	|		WHEN &ReportData = 3
	|		THEN InventoryCostBalance.ItemizedVariableCostsManagClosingBalance
	|		WHEN &ReportData = 4
	|		THEN InventoryCostBalance.ItemizedVariableCostsComplClosingBalance
	|		WHEN &ByEnterprise
	|		THEN InventoryCostBalance.ItemizedVariableCostsExcludingVATClosingBalance
	|		ELSE InventoryCostBalance.ItemizedVariableCostsManagClosingBalance
	|	END AS ItemizedVariableClosingBalance,
	|	CASE
	|		WHEN &ReportData = 1
	|		THEN InventoryCostBalance.CostOpeningBalance + InventoryCostBalance.AddExpensesForGoodsOpeningBalance + InventoryCostBalance.OffBalanceCostOpeningBalance + InventoryCostBalance.LaborCostsOpeningBalance + InventoryCostBalance.ItemizedFixedCostsIncludingVATOpeningBalance + InventoryCostBalance.ItemizedVariableCostsIncludingVATOpeningBalance
	|		WHEN &ReportData = 2
	|		THEN InventoryCostBalance.CostExcludingVATOpeningBalance + InventoryCostBalance.AdditionalExpensesExcludingVATOpeningBalance + InventoryCostBalance.OffBalanceCostOpeningBalance + InventoryCostBalance.LaborCostsOpeningBalance + InventoryCostBalance.ItemizedFixedCostsExcludingVATOpeningBalance + InventoryCostBalance.ItemizedVariableCostsExcludingVATOpeningBalance
	|		WHEN &ReportData = 3
	|		THEN InventoryCostBalance.CostManOpeningBalance + InventoryCostBalance.AddExpensesManOpeningBalance + InventoryCostBalance.OffBalanceCostOpeningBalance + InventoryCostBalance.LaborCostsManOpeningBalance + InventoryCostBalance.ItemizedFixedCostsManagOpeningBalance + InventoryCostBalance.ItemizedVariableCostsManagOpeningBalance
	|		WHEN &ReportData = 4
	|		THEN InventoryCostBalance.LocalCostOpeningBalance + InventoryCostBalance.AddExpensesLocalOpeningBalance + InventoryCostBalance.OffBalanceCostLocalOpeningBalance + InventoryCostBalance.LaborCostsLocalOpeningBalance + InventoryCostBalance.ItemizedFixedCostsComplOpeningBalance + InventoryCostBalance.ItemizedVariableCostsComplOpeningBalance
	|		WHEN &ByEnterprise
	|		THEN InventoryCostBalance.CostExcludingVATOpeningBalance + InventoryCostBalance.AdditionalExpensesExcludingVATOpeningBalance + InventoryCostBalance.OffBalanceCostOpeningBalance + InventoryCostBalance.LaborCostsOpeningBalance + InventoryCostBalance.ItemizedFixedCostsExcludingVATOpeningBalance + InventoryCostBalance.ItemizedVariableCostsExcludingVATOpeningBalance
	|		ELSE InventoryCostBalance.CostManOpeningBalance + InventoryCostBalance.AddExpensesManOpeningBalance + InventoryCostBalance.OffBalanceCostOpeningBalance + InventoryCostBalance.LaborCostsManOpeningBalance + InventoryCostBalance.ItemizedFixedCostsManagOpeningBalance + InventoryCostBalance.ItemizedVariableCostsManagOpeningBalance
	|	END AS Cost_OpeningBalance,
	|	CASE
	|		WHEN &ReportData = 1
	|		THEN InventoryCostBalance.CostClosingBalance + InventoryCostBalance.AddExpensesForGoodsClosingBalance + InventoryCostBalance.OffBalanceCostClosingBalance + InventoryCostBalance.LaborCostsClosingBalance + InventoryCostBalance.ItemizedFixedCostsIncludingVATClosingBalance + InventoryCostBalance.ItemizedVariableCostsIncludingVATClosingBalance
	|		WHEN &ReportData = 2
	|		THEN InventoryCostBalance.CostExcludingVATClosingBalance + InventoryCostBalance.AdditionalExpensesExcludingVATClosingBalance + InventoryCostBalance.OffBalanceCostClosingBalance + InventoryCostBalance.LaborCostsClosingBalance + InventoryCostBalance.ItemizedFixedCostsExcludingVATClosingBalance + InventoryCostBalance.ItemizedVariableCostsExcludingVATClosingBalance
	|		WHEN &ReportData = 3
	|		THEN InventoryCostBalance.CostManClosingBalance + InventoryCostBalance.AddExpensesManClosingBalance + InventoryCostBalance.OffBalanceCostClosingBalance + InventoryCostBalance.LaborCostsManClosingBalance + InventoryCostBalance.ItemizedFixedCostsManagClosingBalance + InventoryCostBalance.ItemizedVariableCostsManagClosingBalance
	|		WHEN &ReportData = 4
	|		THEN InventoryCostBalance.LocalCostClosingBalance + InventoryCostBalance.AddExpensesLocalClosingBalance + InventoryCostBalance.OffBalanceCostLocalClosingBalance + InventoryCostBalance.LaborCostsLocalClosingBalance + InventoryCostBalance.ItemizedFixedCostsComplClosingBalance + InventoryCostBalance.ItemizedVariableCostsComplClosingBalance
	|		WHEN &ByEnterprise
	|		THEN InventoryCostBalance.CostExcludingVATClosingBalance + InventoryCostBalance.AdditionalExpensesExcludingVATClosingBalance + InventoryCostBalance.OffBalanceCostClosingBalance + InventoryCostBalance.LaborCostsClosingBalance + InventoryCostBalance.ItemizedFixedCostsExcludingVATClosingBalance + InventoryCostBalance.ItemizedVariableCostsExcludingVATClosingBalance
	|		ELSE InventoryCostBalance.CostManClosingBalance + InventoryCostBalance.AddExpensesManClosingBalance + InventoryCostBalance.OffBalanceCostClosingBalance + InventoryCostBalance.LaborCostsManClosingBalance + InventoryCostBalance.ItemizedFixedCostsManagClosingBalance + InventoryCostBalance.ItemizedVariableCostsManagClosingBalance
	|	END AS Cost_ClosingBalance,
	|	CASE
	|		WHEN &ReportData = 4
	|		THEN InventoryCostBalance.LocalCostOpeningBalance + InventoryCostBalance.AddExpensesLocalOpeningBalance + InventoryCostBalance.OffBalanceCostLocalOpeningBalance + InventoryCostBalance.LaborCostsLocalOpeningBalance + InventoryCostBalance.ItemizedFixedCostsComplOpeningBalance + InventoryCostBalance.ItemizedVariableCostsComplOpeningBalance - InventoryCostBalance.PermanentDifferenceOpeningBalance - InventoryCostBalance.CostTDOpeningBalance
	|		ELSE 0
	|	END AS TaxAccountingOpeningBalance,
	|	CASE
	|		WHEN &ReportData = 4
	|		THEN InventoryCostBalance.LocalCostClosingBalance + InventoryCostBalance.AddExpensesLocalClosingBalance + InventoryCostBalance.OffBalanceCostLocalClosingBalance + InventoryCostBalance.LaborCostsLocalClosingBalance + InventoryCostBalance.ItemizedFixedCostsComplClosingBalance + InventoryCostBalance.ItemizedVariableCostsComplClosingBalance - InventoryCostBalance.PermanentDifferenceClosingBalance - InventoryCostBalance.CostTDClosingBalance
	|		ELSE 0
	|	END AS TaxAccountingClosingBalance,
	|	CASE
	|		WHEN &ReportData = 4
	|		THEN InventoryCostBalance.PermanentDifferenceOpeningBalance
	|		ELSE 0
	|	END AS PermanentDifferenceOpeningBalance,
	|	CASE
	|		WHEN &ReportData = 4
	|		THEN InventoryCostBalance.PermanentDifferenceClosingBalance
	|		ELSE 0
	|	END AS PermanentDifferenceClosingBalance,
	|	CASE
	|		WHEN &ReportData = 4
	|		THEN InventoryCostBalance.CostTDOpeningBalance
	|		ELSE 0
	|	END AS CostTDOpeningBalance,
	|	CASE
	|		WHEN &ReportData = 4
	|		THEN InventoryCostBalance.CostTDClosingBalance
	|		ELSE 0
	|	END AS CostTDClosingBalance,
	|	CASE
	|		WHEN &ReportData = 1 OR &ReportData = 2 OR &ReportData = 3
	|		THEN InventoryCostBalance.OffBalanceCostOpeningBalance
	|		WHEN &ReportData = 4
	|		THEN InventoryCostBalance.OffBalanceCostLocalOpeningBalance
	|		ELSE 0
	|	END AS OffBalanceCostOpeningBalance,
	|	CASE
	|		WHEN &ReportData = 1 OR &ReportData = 2 OR &ReportData = 3
	|		THEN InventoryCostBalance.OffBalanceCostClosingBalance
	|		WHEN &ReportData = 4
	|		THEN InventoryCostBalance.OffBalanceCostLocalClosingBalance
	|		ELSE 0
	|	END AS OffBalanceCostClosingBalance,
	|	CASE
	|		WHEN &ReportData = 4
	|			THEN InventoryCostBalance.CostOfPersonalIncomeTaxOpeningBalance
	|		ELSE 0
	|	END AS AITOpeningBalance,
	|	CASE
	|		WHEN &ReportData = 4
	|			THEN InventoryCostBalance.CostOfPersonalIncomeTaxClosingBalance
	|		ELSE 0
	|	END AS AITClosingBalance,
	|	0 AS CountReceipt,
	|	0 AS CountExpense,
	|	0 AS CostOfAdmissionReceipt,
	|	0 AS CostOfAdmissionExpense,
	|	0 AS AddExpensesForGoodsReceipt,
	|	0 AS AddExpensesForGoodsExpense,
	|	0 AS LaborCostsReceipt,
	|	0 AS LaborCostsExpense,
	|	0 AS ItemizedFixedReceipt,
	|	0 AS ItemizedFixedExpense,
	|	0 AS ItemizedVariableReceipt,
	|	0 AS ItemizedVariableExpense,
	|	0 AS Cost_Receipt,
	|	0 AS Cost_Expense,
	|	0 AS TaxAccountingReceipt,
	|	0 AS TaxAccountingExpense,
	|	0 AS PermanentDifferenceReceipt,
	|	0 AS PermanentDifferenceExpense,
	|	0 AS CostTDReceipt,
	|	0 AS CostTDExpense,
	|	0 AS OffBalanceCostReceipt,
	|	0 AS OffBalanceCostExpense,
	|	0 AS AITReceipt,
	|	0 AS AITExpense
	|{SELECT
	|	SecondPeriod,
	|	DayPeriod,
	|	WeekPeriod,
	|	TenDaysPeriod,
	|	MonthPeriod,
	|	QuarterPeriod,
	|	HalfYearPeriod,
	|	YearPeriod,
	|	VariancePeriod,
	|	ItemsLocationAttributes.*,
	|	Products.*,
	|	StorageUnit.*,
	|	UnitForReports.*,
	|	UnitFactorForReports,
	|	Characteristic.*,
	|	Series.*,
	|	Warehouse.*,
	|	Purpose.*,
	|	LineOfBusiness.*,
	|	Department.*,
	|	InventoryOwnerAttribute.*,
	|	FinancialAccountingGroup.*,
	|	Organization.*,
	|	Lot.*,
	|	LotVendorAttributes.*,
	|	AccountingSection,
	|	VATActivityType,
	|	BusinessOperation.*,
	|	IncomeItem.*,
	|	ExpenseItem.*,
	|	IncomeAndExpenseItem.*,
	|	DimensionOfRevenue.*,
	|	DimensionOfExpenses.*,
	|	DimensionOfIncomeExpense.*,
	|	Contract.*,
	|	OrderDocument.*,
	|	Partner.*,
	|	Counterparty.*,
	|	Terms.*,
	|	InventoryType.*,
	|	BusinessOperationCatalog.*,
	|	EconomicOperationOfParish.*,
	|	EconomicOperationOfExpenditure.*,
	|	CostDefiningMethod,
	|	CostCalculationDate,
	|	Document.*,
	|	UnitFactorForReports AS CountOpeningBalance,
	|	UnitFactorForReports AS CountClosingBalance,
	|	CountOpeningBalance AS CountOpeningBalance,
	|	CountClosingBalance AS CountClosingBalance,
	|	CountOpeningBalance AS WeightOpeningBalance,
	|	CountClosingBalance AS WeightClosingBalance,
	|	CountOpeningBalance AS VolumeM3OpeningBalance,
	|	CountClosingBalance AS VolumeM3ClosingBalance,
	|	StorageUnit AS WeightOpeningBalance,
	|	StorageUnit AS WeightClosingBalance,
	|	StorageUnit AS VolumeM3OpeningBalance,
	|	StorageUnit AS VolumeM3ClosingBalance,
	|	Products AS WeightOpeningBalance,
	|	Products AS WeightClosingBalance,
	|	Products AS VolumeM3OpeningBalance,
	|	Products AS VolumeM3ClosingBalance,
	|	CostOfAdmissionOpeningBalance,
	|	CostOfAdmissionClosingBalance,
	|	AddExpensesForGoodsOpeningBalance,
	|	AddExpensesForGoodsClosingBalance,
	|	LaborCostsOpeningBalance,
	|	LaborCostsClosingBalance,
	|	ItemizedFixedOpeningBalance,
	|	ItemizedFixedClosingBalance,
	|	ItemizedVariableOpeningBalance,
	|	ItemizedVariableClosingBalance,
	|	Cost_OpeningBalance,
	|	Cost_ClosingBalance,
	|	TaxAccountingOpeningBalance,
	|	TaxAccountingClosingBalance,
	|	PermanentDifferenceOpeningBalance,
	|	PermanentDifferenceClosingBalance,
	|	CostTDOpeningBalance,
	|	CostTDClosingBalance,
	|	OffBalanceCostOpeningBalance,
	|	OffBalanceCostClosingBalance,
	|	AITOpeningBalance,
	|	AITClosingBalance,
	|	UnitFactorForReports AS CountReceipt,
	|	UnitFactorForReports AS CountExpense,
	|	CountReceipt AS CountReceipt,
	|	CountExpense AS CountExpense,
	|	CountReceipt AS WeightReceipt,
	|	CountExpense AS WeightExpense,
	|	CountReceipt AS VolumeM3Receipt,
	|	CountExpense AS VolumeM3Expense,
	|	StorageUnit AS WeightReceipt,
	|	StorageUnit AS WeightExpense,
	|	StorageUnit AS VolumeM3Receipt,
	|	StorageUnit AS VolumeM3Expense,
	|	Products AS WeightReceipt,
	|	Products AS WeightExpense,
	|	Products AS VolumeM3Receipt,
	|	Products AS VolumeM3Expense,
	|	CostOfAdmissionReceipt,
	|	CostOfAdmissionExpense,
	|	AddExpensesForGoodsReceipt,
	|	AddExpensesForGoodsExpense,
	|	LaborCostsReceipt,
	|	LaborCostsExpense,
	|	ItemizedFixedReceipt,
	|	ItemizedFixedExpense,
	|	ItemizedVariableReceipt,
	|	ItemizedVariableExpense,
	|	Cost_Receipt,
	|	Cost_Expense,
	|	TaxAccountingReceipt,
	|	TaxAccountingExpense,
	|	PermanentDifferenceReceipt,
	|	PermanentDifferenceExpense,
	|	CostTDReceipt,
	|	CostTDExpense,
	|	OffBalanceCostReceipt,
	|	OffBalanceCostExpense,
	|	AITReceipt,
	|	AITExpense}
	|FROM
	|	AccumulationRegister.InventoryCost.BalanceAndTurnovers(
	|			&BeginOfPeriod {(&BeginOfPeriod)}, 
	|			&EndOfPeriod {(&EndOfPeriod)}, 
	|			Auto, , 
	|			{
	|				((ItemsLocationAttributes.Products, ItemsLocationAttributes.Characteristic) IN
	|					(SELECT
	|						SelectionByProductSegment.Products,
	|						SelectionByProductSegment.Characteristic
	|					FROM
	|						SelectionByProductSegment
	|					WHERE
	|						SelectionByProductSegment.FilterByProductSegmentIsUsed = &FilterByProductSegmentIsUsed)),
	|				(ItemsLocationAttributes.Products).* AS Products, 
	|				(ItemsLocationAttributes.Products.UnitOfMeasure).* AS UnitOfMeasure, 
	|				(ItemsLocationAttributes.Products.UnitForReports).* AS UnitForReports, 
	|				(ItemsLocationAttributes.Characteristic).* AS Characteristic, 
	|				(ItemsLocationAttributes.Series).* AS Series, 
	|				(ItemsLocationAttributes.StorageLocation).* AS Warehouse, 
	|				(ItemsLocationAttributes.Purpose).* AS Purpose, 
	|				(ItemsLocationAttributes.Purpose.LineOfBusiness).* AS LineOfBusiness, 
	|				(Organization).* AS Organization, 
	|				(InventoryOwnerAttribute).* AS InventoryOwnerAttribute,
	|				(Lot).* AS Lot,
	|				(AccountingSection) AS AccountingSection,
	|				(VATActivityType) AS VATActivityType
	|			}
	|	) AS InventoryCostBalance
	|		{LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionOfProductItem
	|		ON InventoryCostBalance.ItemsLocationAttributes = DimensionOfProductItem.Ref}
	|		{LEFT JOIN Catalog.KeysForLotVendorAttributes AS DimensionOfLots
	|		ON (DimensionOfLots.Ref = InventoryCostBalance.LotVendorAttributes)}
	|WHERE
	|	InventoryCostBalance.Organization IN (&CompanyArray)
	|{WHERE
	|	InventoryCostBalance.DayPeriod AS DayPeriod,
	|	InventoryCostBalance.WeekPeriod AS WeekPeriod,
	|	InventoryCostBalance.TenDaysPeriod AS TenDaysPeriod,
	|	InventoryCostBalance.MonthPeriod AS MonthPeriod,
	|	InventoryCostBalance.QuarterPeriod AS QuarterPeriod,
	|	InventoryCostBalance.HalfYearPeriod AS HalfYearPeriod,
	|	InventoryCostBalance.YearPeriod AS YearPeriod,
	|	DATETIME(1,1,1) AS VariancePeriod,
	|	(CASE
	|			WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|				THEN InventoryCostBalance.InventoryOwnerAttribute.FinancialAccountingGroup
	|			ELSE DimensionOfProductItem.Products.FinancialAccountingGroup
	|		END).* AS FinancialAccountingGroup}";
	NestedRequestTexts.Add(QueryText);
	#EndRegion
	
	#Region Turnovers
	QueryText =
	"SELECT
	|	//The ""Revolutions"" tab mode AS A data source,
	|	InventoryCost.SecondPeriod AS SecondPeriod,
	|	InventoryCost.DayPeriod AS DayPeriod,
	|	InventoryCost.WeekPeriod AS WeekPeriod,
	|	InventoryCost.TenDaysPeriod AS TenDaysPeriod,
	|	InventoryCost.MonthPeriod AS MonthPeriod,
	|	InventoryCost.QuarterPeriod AS QuarterPeriod,
	|	InventoryCost.HalfYearPeriod AS HalfYearPeriod,
	|	InventoryCost.YearPeriod AS YearPeriod,
	|	InventoryCost.VariancePeriod AS VariancePeriod,
	|	InventoryCost.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	InventoryCost.Products AS Products,
	|	InventoryCost.StorageUnit AS StorageUnit,
	|	InventoryCost.UnitForReports AS UnitForReports,
	|	InventoryCost.UnitFactorForReports AS UnitFactorForReports,
	|	InventoryCost.Characteristic AS Characteristic,
	|	InventoryCost.Series AS Series,
	|	InventoryCost.Warehouse AS Warehouse,
	|	InventoryCost.Purpose AS Purpose,
	|	InventoryCost.LineOfBusiness AS LineOfBusiness,
	|	InventoryCost.Department AS Department,
	|	InventoryCost.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	InventoryCost.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	InventoryCost.Organization,
	|	InventoryCost.Lot,
	|	InventoryCost.LotVendorAttributes,
	|	InventoryCost.AccountingSection,
	|	InventoryCost.VATActivityType,
	|	InventoryCost.BusinessOperation,
	|	InventoryCost.IncomeItem,
	|	InventoryCost.ExpenseItem AS ExpenseItem,
	|	InventoryCost.IncomeAndExpenseItem AS IncomeAndExpenseItem,
	|	InventoryCost.DimensionOfRevenue,
	|	InventoryCost.DimensionOfExpenses,
	|	InventoryCost.DimensionOfIncomeExpense AS DimensionOfIncomeExpense,
	|	InventoryCost.Contract AS Contract,
	|	InventoryCost.OrderDocument AS OrderDocument,
	|	InventoryCost.Partner AS Partner,
	|	InventoryCost.Counterparty AS Counterparty,
	|	InventoryCost.Terms AS Terms,
	|	InventoryCost.InventoryType AS InventoryType,
	|	InventoryCost.BusinessOperationCatalog AS BusinessOperationCatalog,
	|	InventoryCost.EconomicOperationOfParish AS EconomicOperationOfParish,
	|	InventoryCost.EconomicOperationOfExpenditure AS EconomicOperationOfExpenditure,
	|	InventoryCost.CostDefiningMethod AS CostDefiningMethod,
	|	InventoryCost.CostCalculationDate AS CostCalculationDate,
	|	InventoryCost.Document AS Document,
	|	0 AS CountOpeningBalance,
	|	0 AS CountClosingBalance,
	|	0 AS CostOfAdmissionOpeningBalance,
	|	0 AS CostOfAdmissionClosingBalance,
	|	0 AS AddExpensesForGoodsOpeningBalance,
	|	0 AS AddExpensesForGoodsClosingBalance,
	|	0 AS LaborCostsOpeningBalance,
	|	0 AS LaborCostsClosingBalance,
	|	0 AS ItemizedFixedOpeningBalance,
	|	0 AS ItemizedFixedClosingBalance,
	|	0 AS ItemizedVariableOpeningBalance,
	|	0 AS ItemizedVariableClosingBalance,
	|	0 AS Cost_OpeningBalance,
	|	0 AS Cost_ClosingBalance,
	|	0 AS TaxAccountingOpeningBalance,
	|	0 AS TaxAccountingClosingBalance,
	|	0 AS PermanentDifferenceOpeningBalance,
	|	0 AS PermanentDifferenceClosingBalance,
	|	0 AS CostTDOpeningBalance,
	|	0 AS CostTDClosingBalance,
	|	0 AS OffBalanceCostOpeningBalance,
	|	0 AS OffBalanceCostClosingBalance,
	|	0 AS AITOpeningBalance,
	|	0 AS AITClosingBalance,
	|	InventoryCost.CountReceipt AS CountReceipt,
	|	InventoryCost.CountExpense AS CountExpense,
	|	InventoryCost.CostOfAdmissionReceipt AS CostOfAdmissionReceipt,
	|	InventoryCost.CostOfAdmissionExpense AS CostOfAdmissionExpense,
	|	InventoryCost.AddExpensesForGoodsReceipt AS AddExpensesForGoodsReceipt,
	|	InventoryCost.AddExpensesForGoodsExpense AS AddExpensesForGoodsExpense,
	|	InventoryCost.LaborCostsReceipt AS LaborCostsReceipt,
	|	InventoryCost.LaborCostsExpense AS LaborCostsExpense,
	|	InventoryCost.ItemizedFixedReceipt AS ItemizedFixedReceipt,
	|	InventoryCost.ItemizedFixedExpense AS ItemizedFixedExpense,
	|	InventoryCost.ItemizedVariableReceipt AS ItemizedVariableReceipt,
	|	InventoryCost.ItemizedVariableExpense AS ItemizedVariableExpense,
	|	InventoryCost.Cost_Receipt AS Cost_Receipt,
	|	InventoryCost.Cost_Expense AS Cost_Expense,
	|	InventoryCost.TaxAccountingReceipt AS TaxAccountingReceipt,
	|	InventoryCost.TaxAccountingExpense AS TaxAccountingExpense,
	|	InventoryCost.PermanentDifferenceReceipt AS PermanentDifferenceReceipt,
	|	InventoryCost.PermanentDifferenceExpense AS PermanentDifferenceExpense,
	|	InventoryCost.CostTDReceipt AS CostTDReceipt,
	|	InventoryCost.CostTDExpense AS CostTDExpense,
	|	InventoryCost.OffBalanceCostReceipt AS OffBalanceCostReceipt,
	|	InventoryCost.OffBalanceCostExpense AS OffBalanceCostExpense,
	|	InventoryCost.AITReceipt AS AITReceipt,
	|	InventoryCost.AITExpense AS AITExpense
	|FROM
	|	TTCostPrice AS InventoryCost";
	NestedRequestTexts.Add(QueryText);
	#EndRegion
	
	NestedQueryString = StrConcat(NestedRequestTexts, 
		TMCommonUse.QuerySeparatorInJoin(False));
	
	#Region PlacementInFinalTemporaryTable
	QueryText =
	"SELECT ALLOWED
	|	BalanceAndRegisteredRecords.SecondPeriod AS SecondPeriod,
	|	BalanceAndRegisteredRecords.DayPeriod AS DayPeriod,
	|	BalanceAndRegisteredRecords.WeekPeriod AS WeekPeriod,
	|	BalanceAndRegisteredRecords.TenDaysPeriod AS TenDaysPeriod,
	|	BalanceAndRegisteredRecords.MonthPeriod AS MonthPeriod,
	|	BalanceAndRegisteredRecords.QuarterPeriod AS QuarterPeriod,
	|	BalanceAndRegisteredRecords.HalfYearPeriod AS HalfYearPeriod,
	|	BalanceAndRegisteredRecords.YearPeriod AS YearPeriod,
	|	BalanceAndRegisteredRecords.VariancePeriod AS VariancePeriod,
	|	BalanceAndRegisteredRecords.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	BalanceAndRegisteredRecords.Products AS Products,
	|	BalanceAndRegisteredRecords.StorageUnit AS StorageUnit,
	|	BalanceAndRegisteredRecords.UnitForReports AS UnitForReports,
	|	BalanceAndRegisteredRecords.UnitFactorForReports AS UnitFactorForReports,
	|	BalanceAndRegisteredRecords.Characteristic AS Characteristic,
	|	BalanceAndRegisteredRecords.Series AS Series,
	|	BalanceAndRegisteredRecords.Warehouse AS Warehouse,
	|	BalanceAndRegisteredRecords.Purpose AS Purpose,
	|	BalanceAndRegisteredRecords.LineOfBusiness AS LineOfBusiness,
	|	BalanceAndRegisteredRecords.Department AS Department,
	|	BalanceAndRegisteredRecords.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	BalanceAndRegisteredRecords.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	BalanceAndRegisteredRecords.Organization AS Organization,
	|	BalanceAndRegisteredRecords.Lot AS Lot,
	|	BalanceAndRegisteredRecords.LotVendorAttributes AS LotVendorAttributes,
	|	BalanceAndRegisteredRecords.AccountingSection AS AccountingSection,
	|	BalanceAndRegisteredRecords.VATActivityType AS VATActivityType,
	|	BalanceAndRegisteredRecords.BusinessOperation AS BusinessOperation,
	|	BalanceAndRegisteredRecords.IncomeItem AS IncomeItem,
	|	BalanceAndRegisteredRecords.ExpenseItem AS ExpenseItem,
	|	BalanceAndRegisteredRecords.IncomeAndExpenseItem AS IncomeAndExpenseItem,
	|	BalanceAndRegisteredRecords.DimensionOfRevenue AS DimensionOfRevenue,
	|	BalanceAndRegisteredRecords.DimensionOfExpenses AS DimensionOfExpenses,
	|	BalanceAndRegisteredRecords.DimensionOfIncomeExpense AS DimensionOfIncomeExpense,
	|	BalanceAndRegisteredRecords.Contract AS Contract,
	|	BalanceAndRegisteredRecords.OrderDocument AS OrderDocument,
	|	BalanceAndRegisteredRecords.Partner AS Partner,
	|	BalanceAndRegisteredRecords.Counterparty AS Counterparty,
	|	BalanceAndRegisteredRecords.Terms AS Terms,
	|	BalanceAndRegisteredRecords.InventoryType AS InventoryType,
	|	BalanceAndRegisteredRecords.BusinessOperationCatalog AS BusinessOperationCatalog,
	|	BalanceAndRegisteredRecords.EconomicOperationOfParish AS EconomicOperationOfParish,
	|	BalanceAndRegisteredRecords.EconomicOperationOfExpenditure AS EconomicOperationOfExpenditure,
	|	BalanceAndRegisteredRecords.CostDefiningMethod,
	|	BalanceAndRegisteredRecords.CostCalculationDate,
	|	(CASE
	|		WHEN BalanceAndRegisteredRecords.Document = UNDEFINED THEN NULL
	|		ELSE BalanceAndRegisteredRecords.Document END) AS Document,
	|	SUM(CASE
	|		WHEN &QuantityUnits = 0
	|		THEN 1
	|		WHEN &QuantityUnits = 1 AND BalanceAndRegisteredRecords.UnitFactorForReports <> 0
	|		THEN 1 / BalanceAndRegisteredRecords.UnitFactorForReports
	|		ELSE 0
	|	END * BalanceAndRegisteredRecords.CountOpeningBalance) AS CountOpeningBalance,
	|	SUM(CASE
	|		WHEN &QuantityUnits = 0
	|		THEN 1
	|		WHEN &QuantityUnits = 1 AND BalanceAndRegisteredRecords.UnitFactorForReports <> 0
	|		THEN 1 / BalanceAndRegisteredRecords.UnitFactorForReports
	|		ELSE 0
	|	END * BalanceAndRegisteredRecords.CountClosingBalance) AS CountClosingBalance,
	|	SUM(BalanceAndRegisteredRecords.CountOpeningBalance * &QueryTextPackageWeight) AS WeightOpeningBalance,
	|	SUM(BalanceAndRegisteredRecords.CountClosingBalance * &QueryTextPackageWeight) AS WeightClosingBalance,
	|	SUM(BalanceAndRegisteredRecords.CountOpeningBalance * &QueryTextPackageVolume) AS VolumeM3OpeningBalance,
	|	SUM(BalanceAndRegisteredRecords.CountClosingBalance * &QueryTextPackageVolume) AS VolumeM3ClosingBalance,
	|	SUM(BalanceAndRegisteredRecords.CostOfAdmissionOpeningBalance)AS CostOfAdmissionOpeningBalance,
	|	SUM(BalanceAndRegisteredRecords.CostOfAdmissionClosingBalance)AS CostOfAdmissionClosingBalance,
	|	SUM(BalanceAndRegisteredRecords.AddExpensesForGoodsOpeningBalance)AS AddExpensesForGoodsOpeningBalance,
	|	SUM(BalanceAndRegisteredRecords.AddExpensesForGoodsClosingBalance)AS AddExpensesForGoodsClosingBalance,
	|	SUM(BalanceAndRegisteredRecords.OffBalanceCostOpeningBalance)AS OffBalanceCostOpeningBalance,
	|	SUM(BalanceAndRegisteredRecords.OffBalanceCostClosingBalance)AS OffBalanceCostClosingBalance,
	|	SUM(BalanceAndRegisteredRecords.LaborCostsOpeningBalance)AS LaborCostsOpeningBalance,
	|	SUM(BalanceAndRegisteredRecords.LaborCostsClosingBalance)AS LaborCostsClosingBalance,
	|	SUM(BalanceAndRegisteredRecords.ItemizedFixedOpeningBalance)AS ItemizedFixedOpeningBalance,
	|	SUM(BalanceAndRegisteredRecords.ItemizedFixedClosingBalance)AS ItemizedFixedClosingBalance,
	|	SUM(BalanceAndRegisteredRecords.ItemizedVariableOpeningBalance)AS ItemizedVariableOpeningBalance,
	|	SUM(BalanceAndRegisteredRecords.ItemizedVariableClosingBalance)AS ItemizedVariableClosingBalance,
	|	SUM(BalanceAndRegisteredRecords.Cost_OpeningBalance)AS Cost_OpeningBalance,
	|	SUM(BalanceAndRegisteredRecords.Cost_ClosingBalance)AS Cost_ClosingBalance,
	|	SUM(BalanceAndRegisteredRecords.TaxAccountingOpeningBalance)AS TaxAccountingOpeningBalance,
	|	SUM(BalanceAndRegisteredRecords.TaxAccountingClosingBalance)AS TaxAccountingClosingBalance,
	|	SUM(BalanceAndRegisteredRecords.PermanentDifferenceOpeningBalance)AS PermanentDifferenceOpeningBalance,
	|	SUM(BalanceAndRegisteredRecords.PermanentDifferenceClosingBalance)AS PermanentDifferenceClosingBalance,
	|	SUM(BalanceAndRegisteredRecords.CostTDOpeningBalance)AS CostTDOpeningBalance,
	|	SUM(BalanceAndRegisteredRecords.CostTDClosingBalance)AS CostTDClosingBalance,
	|	SUM(BalanceAndRegisteredRecords.AITOpeningBalance)AS AITOpeningBalance,
	|	SUM(BalanceAndRegisteredRecords.AITClosingBalance)AS AITClosingBalance,
	|	SUM(CASE
	|		WHEN &QuantityUnits = 0
	|		THEN 1
	|		ELSE 1 / BalanceAndRegisteredRecords.UnitFactorForReports
	|	END * BalanceAndRegisteredRecords.CountReceipt)AS CountReceipt,
	|	SUM(CASE
	|		WHEN &QuantityUnits = 0
	|		THEN 1
	|		ELSE 1 / BalanceAndRegisteredRecords.UnitFactorForReports
	|	END * BalanceAndRegisteredRecords.CountExpense) AS CountExpense,
	|	SUM(BalanceAndRegisteredRecords.CountReceipt * &QueryTextPackageWeight) AS WeightReceipt,
	|	SUM(BalanceAndRegisteredRecords.CountExpense * &QueryTextPackageWeight) AS WeightExpense,
	|	SUM(BalanceAndRegisteredRecords.CountReceipt * &QueryTextPackageVolume) AS VolumeM3Receipt,
	|	SUM(BalanceAndRegisteredRecords.CountExpense * &QueryTextPackageVolume) AS VolumeM3Expense,
	|	SUM(BalanceAndRegisteredRecords.CostOfAdmissionReceipt)AS CostOfAdmissionReceipt,
	|	SUM(BalanceAndRegisteredRecords.CostOfAdmissionExpense)AS CostOfAdmissionExpense,
	|	SUM(BalanceAndRegisteredRecords.AddExpensesForGoodsReceipt)AS AddExpensesForGoodsReceipt,
	|	SUM(BalanceAndRegisteredRecords.AddExpensesForGoodsExpense)AS AddExpensesForGoodsExpense,
	|	SUM(BalanceAndRegisteredRecords.OffBalanceCostReceipt)AS OffBalanceCostReceipt,
	|	SUM(BalanceAndRegisteredRecords.OffBalanceCostExpense)AS OffBalanceCostExpense,
	|	SUM(BalanceAndRegisteredRecords.LaborCostsReceipt)AS LaborCostsReceipt,
	|	SUM(BalanceAndRegisteredRecords.LaborCostsExpense)AS LaborCostsExpense,
	|	SUM(BalanceAndRegisteredRecords.ItemizedFixedReceipt)AS ItemizedFixedReceipt,
	|	SUM(BalanceAndRegisteredRecords.ItemizedFixedExpense)AS ItemizedFixedExpense,
	|	SUM(BalanceAndRegisteredRecords.ItemizedVariableReceipt)AS ItemizedVariableReceipt,
	|	SUM(BalanceAndRegisteredRecords.ItemizedVariableExpense)AS ItemizedVariableExpense,
	|	SUM(BalanceAndRegisteredRecords.Cost_Receipt)AS Cost_Receipt,
	|	SUM(BalanceAndRegisteredRecords.Cost_Expense)AS Cost_Expense,
	|	SUM(BalanceAndRegisteredRecords.TaxAccountingReceipt)AS TaxAccountingReceipt,
	|	SUM(BalanceAndRegisteredRecords.TaxAccountingExpense)AS TaxAccountingExpense,
	|	SUM(BalanceAndRegisteredRecords.PermanentDifferenceReceipt)AS PermanentDifferenceReceipt,
	|	SUM(BalanceAndRegisteredRecords.PermanentDifferenceExpense)AS PermanentDifferenceExpense,
	|	SUM(BalanceAndRegisteredRecords.CostTDReceipt)AS CostTDReceipt,
	|	SUM(BalanceAndRegisteredRecords.CostTDExpense)AS CostTDExpense,
	|	SUM(BalanceAndRegisteredRecords.AITReceipt)AS AITReceipt,
	|	SUM(BalanceAndRegisteredRecords.AITExpense)AS AITExpense
	|{SELECT
	|	SecondPeriod,
	|	DayPeriod,
	|	WeekPeriod,
	|	TenDaysPeriod,
	|	MonthPeriod,
	|	QuarterPeriod,
	|	HalfYearPeriod,
	|	YearPeriod,
	|	VariancePeriod,
	|	ItemsLocationAttributes.*,
	|	Products.*,
	|	StorageUnit.*,
	|	UnitForReports.*,
	|	UnitFactorForReports,
	|	Characteristic.*,
	|	Series.*,
	|	Warehouse.*,
	|	Purpose.*,
	|	LineOfBusiness.*,
	|	Department.*,
	|	InventoryOwnerAttribute.*,
	|	FinancialAccountingGroup.*,
	|	Organization.*,
	|	Lot.*,
	|	LotVendorAttributes.*,
	|	AccountingSection,
	|	VATActivityType,
	|	BusinessOperation.*,
	|	IncomeItem.*,
	|	ExpenseItem.*,
	|	IncomeAndExpenseItem.*,
	|	DimensionOfRevenue.*,
	|	DimensionOfExpenses.*,
	|	DimensionOfIncomeExpense.*,
	|	Contract.*,
	|	OrderDocument.*,
	|	Partner.*,
	|	Counterparty.*,
	|	Terms.*,
	|	InventoryType.*,
	|	BusinessOperationCatalog.*,
	|	EconomicOperationOfParish.*,
	|	EconomicOperationOfExpenditure.*,
	|	CostDefiningMethod,
	|	CostCalculationDate,
	|	Document.*,
	|	CountOpeningBalance,
	|	CountClosingBalance,
	|	WeightOpeningBalance,
	|	WeightClosingBalance,
	|	VolumeM3OpeningBalance,
	|	VolumeM3ClosingBalance,
	|	CostOfAdmissionOpeningBalance,
	|	CostOfAdmissionClosingBalance,
	|	AddExpensesForGoodsOpeningBalance,
	|	AddExpensesForGoodsClosingBalance,
	|	OffBalanceCostOpeningBalance,
	|	OffBalanceCostClosingBalance,
	|	LaborCostsOpeningBalance,
	|	LaborCostsClosingBalance,
	|	ItemizedFixedOpeningBalance,
	|	ItemizedFixedClosingBalance,
	|	ItemizedVariableOpeningBalance,
	|	ItemizedVariableClosingBalance,
	|	Cost_OpeningBalance,
	|	Cost_ClosingBalance,
	|	TaxAccountingOpeningBalance,
	|	TaxAccountingClosingBalance,
	|	PermanentDifferenceOpeningBalance,
	|	PermanentDifferenceClosingBalance,
	|	CostTDOpeningBalance,
	|	CostTDClosingBalance,
	|	AITOpeningBalance,
	|	AITClosingBalance,
	|	CountReceipt,
	|	CountExpense,
	|	WeightReceipt,
	|	WeightExpense,
	|	VolumeM3Receipt,
	|	VolumeM3Expense,
	|	CostOfAdmissionReceipt,
	|	CostOfAdmissionExpense,
	|	AddExpensesForGoodsReceipt,
	|	AddExpensesForGoodsExpense,
	|	OffBalanceCostReceipt,
	|	OffBalanceCostExpense,
	|	LaborCostsReceipt,
	|	LaborCostsExpense,
	|	ItemizedFixedReceipt,
	|	ItemizedFixedExpense,
	|	ItemizedVariableReceipt,
	|	ItemizedVariableExpense,
	|	Cost_Receipt,
	|	Cost_Expense,
	|	TaxAccountingReceipt,
	|	TaxAccountingExpense,
	|	PermanentDifferenceReceipt,
	|	PermanentDifferenceExpense,
	|	CostTDReceipt,
	|	CostTDExpense,
	|	AITReceipt,
	|	AITExpense}
	|
	|INTO BalanceAndRegisteredRecords
	|FROM
	|	BalanceAndRegisteredRecordsPreliminary AS BalanceAndRegisteredRecords
	|
	|GROUP BY
	|	BalanceAndRegisteredRecords.SecondPeriod,
	|	BalanceAndRegisteredRecords.DayPeriod,
	|	BalanceAndRegisteredRecords.WeekPeriod,
	|	BalanceAndRegisteredRecords.TenDaysPeriod,
	|	BalanceAndRegisteredRecords.MonthPeriod,
	|	BalanceAndRegisteredRecords.QuarterPeriod,
	|	BalanceAndRegisteredRecords.HalfYearPeriod,
	|	BalanceAndRegisteredRecords.YearPeriod,
	|	BalanceAndRegisteredRecords.VariancePeriod,
	|	BalanceAndRegisteredRecords.ItemsLocationAttributes,
	|	BalanceAndRegisteredRecords.Products,
	|	BalanceAndRegisteredRecords.StorageUnit,
	|	BalanceAndRegisteredRecords.UnitForReports,
	|	BalanceAndRegisteredRecords.UnitFactorForReports,
	|	BalanceAndRegisteredRecords.Characteristic,
	|	BalanceAndRegisteredRecords.Series,
	|	BalanceAndRegisteredRecords.Warehouse,
	|	BalanceAndRegisteredRecords.Purpose,
	|	BalanceAndRegisteredRecords.LineOfBusiness,
	|	BalanceAndRegisteredRecords.Department,
	|	BalanceAndRegisteredRecords.InventoryOwnerAttribute,
	|	BalanceAndRegisteredRecords.FinancialAccountingGroup,
	|	BalanceAndRegisteredRecords.Organization,
	|	BalanceAndRegisteredRecords.Lot,
	|	BalanceAndRegisteredRecords.LotVendorAttributes,
	|	BalanceAndRegisteredRecords.AccountingSection,
	|	BalanceAndRegisteredRecords.VATActivityType,
	|	BalanceAndRegisteredRecords.BusinessOperation,
	|	BalanceAndRegisteredRecords.IncomeItem,
	|	BalanceAndRegisteredRecords.ExpenseItem,
	|	BalanceAndRegisteredRecords.IncomeAndExpenseItem,
	|	BalanceAndRegisteredRecords.DimensionOfRevenue,
	|	BalanceAndRegisteredRecords.DimensionOfExpenses,
	|	BalanceAndRegisteredRecords.DimensionOfIncomeExpense,
	|	BalanceAndRegisteredRecords.Contract,
	|	BalanceAndRegisteredRecords.OrderDocument,
	|	BalanceAndRegisteredRecords.Partner,
	|	BalanceAndRegisteredRecords.Counterparty,
	|	BalanceAndRegisteredRecords.Terms,
	|	BalanceAndRegisteredRecords.InventoryType,
	|	BalanceAndRegisteredRecords.BusinessOperationCatalog,
	|	BalanceAndRegisteredRecords.EconomicOperationOfParish,
	|	BalanceAndRegisteredRecords.EconomicOperationOfExpenditure,
	|	BalanceAndRegisteredRecords.CostDefiningMethod,
	|	BalanceAndRegisteredRecords.CostCalculationDate,
	|	(CASE
	|		WHEN BalanceAndRegisteredRecords.Document = UNDEFINED THEN NULL
	|		ELSE BalanceAndRegisteredRecords.Document END) // Document
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	InventoryOwnerAttribute,
	|	Organization,
	|	Lot,
	|	LotVendorAttributes,
	|	MonthPeriod";
	#EndRegion
	
	If SourceDebuggingMode Then
		
		QueryTexts = New Array;
		QueryTexts.Add(NestedQueryString);
		QueryTexts.Add(QueryText);
		QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
		
	Else
		QueryText = StrReplace(QueryText, "BalanceAndRegisteredRecordsPreliminary", "(" + NestedQueryString + ")");
	EndIf;
	
	QueryText = StrReplace(QueryText, "&QueryTextPackageWeight",
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight("BalanceAndRegisteredRecords.StorageUnit", "BalanceAndRegisteredRecords.Products"));
		
	QueryText = StrReplace(QueryText, "&QueryTextPackageVolume",
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume("BalanceAndRegisteredRecords.StorageUnit", "BalanceAndRegisteredRecords.Products"));
	
	Return QueryText;
	
EndFunction

Function QueryTextVT_BalancesAndRegisteredRecordsForSelectionOfDetailsOfInitialCosts()
	
	QueryText =
	"SELECT
	|	BalanceAndTurnovers.MonthPeriod AS MonthPeriod,
	|	BalanceAndTurnovers.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	BalanceAndTurnovers.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	BalanceAndTurnovers.Organization AS Organization,
	|	BalanceAndTurnovers.Lot AS Lot,
	|	BalanceAndTurnovers.LotVendorAttributes AS LotVendorAttributes,
	|	BalanceAndTurnovers.AccountingSection AS AccountingSection,
	|	BalanceAndTurnovers.VATActivityType AS VATActivityType,
	|	BalanceAndTurnovers.Products AS Products,
	|	BalanceAndTurnovers.StorageUnit AS StorageUnit,
	|	BalanceAndTurnovers.UnitForReports AS UnitForReports,
	|	BalanceAndTurnovers.UnitFactorForReports AS UnitFactorForReports,
	|	BalanceAndTurnovers.Characteristic AS Characteristic,
	|	BalanceAndTurnovers.Series AS Series,
	|	BalanceAndTurnovers.Warehouse AS Warehouse,
	|	BalanceAndTurnovers.Purpose AS Purpose,
	|	BalanceAndTurnovers.LineOfBusiness AS LineOfBusiness,
	|	BalanceAndTurnovers.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	SUM(BalanceAndTurnovers.CountOpeningBalance) AS CountOpeningBalance,
	|	SUM(BalanceAndTurnovers.CountClosingBalance) AS CountClosingBalance,
	|	SUM(BalanceAndTurnovers.CountReceipt) AS CountReceipt,
	|	SUM(BalanceAndTurnovers.CountExpense) AS CountExpense,
	|	SUM(BalanceAndTurnovers.AddExpensesForGoodsReceipt) AS AddExpensesForGoodsReceipt
	|INTO VT_BalancesAndRegisteredRecordsForSelectionOfDetailsOfInitialCosts
	|FROM
	|	(SELECT
	|		InventoryCostBalance.Period AS MonthPeriod,
	|		InventoryCostBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		InventoryCostBalance.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|		InventoryCostBalance.Organization AS Organization,
	|		InventoryCostBalance.Lot AS Lot,
	|		InventoryCostBalance.LotVendorAttributes AS LotVendorAttributes,
	|		InventoryCostBalance.AccountingSection AS AccountingSection,
	|		InventoryCostBalance.VATActivityType AS VATActivityType,
	|		InventoryCostBalance.ItemsLocationAttributes.Products AS Products,
	|		InventoryCostBalance.ItemsLocationAttributes.Products.UnitOfMeasure AS StorageUnit,
	|		InventoryCostBalance.ItemsLocationAttributes.Products.UnitForReports AS UnitForReports,
	|		InventoryCostBalance.ItemsLocationAttributes.Products.UnitFactorForReports AS UnitFactorForReports,
	|		InventoryCostBalance.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		InventoryCostBalance.ItemsLocationAttributes.Series AS Series,
	|		InventoryCostBalance.ItemsLocationAttributes.StorageLocation AS Warehouse,
	|		InventoryCostBalance.ItemsLocationAttributes.Purpose AS Purpose,
	|		InventoryCostBalance.ItemsLocationAttributes.Purpose.LineOfBusiness AS LineOfBusiness,
	|		CASE
	|			WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|				THEN InventoryCostBalance.InventoryOwnerAttribute.FinancialAccountingGroup
	|			ELSE InventoryCostBalance.ItemsLocationAttributes.Products.FinancialAccountingGroup
	|		END AS FinancialAccountingGroup,
	|		InventoryCostBalance.CountOpeningBalance AS CountOpeningBalance,
	|		InventoryCostBalance.CountClosingBalance AS CountClosingBalance,
	|		0 AS CountReceipt,
	|		0 AS CountExpense,
	|		0 AS AddExpensesForGoodsReceipt
	|	FROM
	|		AccumulationRegister.InventoryCost.BalanceAndTurnovers(
	|				&BeginOfPeriod {(&BeginOfPeriod)},
	|				&EndOfPeriod {(&EndOfPeriod)},
	|				Month, ,
	|				{
	|					(
	|						(ItemsLocationAttributes.Products, ItemsLocationAttributes.Characteristic) IN
	|						(SELECT
	|							SelectionByProductSegment.Products,
	|							SelectionByProductSegment.Characteristic
	|						FROM
	|							SelectionByProductSegment
	|						WHERE
	|							SelectionByProductSegment.FilterByProductSegmentIsUsed = &FilterByProductSegmentIsUsed
	|						)
	|					),
	|					(ItemsLocationAttributes.Products).* AS Products,
	|					(ItemsLocationAttributes.Products.UnitOfMeasure).* AS UnitOfMeasure,
	|					(ItemsLocationAttributes.Products.UnitForReports).* AS UnitForReports,
	|					(ItemsLocationAttributes.Characteristic).* AS Characteristic,
	|					(ItemsLocationAttributes.Series).* AS Series,
	|					(ItemsLocationAttributes.StorageLocation).* AS Warehouse,
	|					(ItemsLocationAttributes.Purpose).* AS Purpose,
	|					(ItemsLocationAttributes.Purpose.LineOfBusiness).* AS LineOfBusiness,
	|					(Organization).* AS Organization,
	|					(InventoryOwnerAttribute).* AS InventoryOwnerAttribute,
	|					(Lot).* AS Lot,
	|					(AccountingSection) AS AccountingSection,
	|					(VATActivityType) AS VATActivityType,
	|					VALUE(Enum.BusinessTransactions.EmptyRef) AS BusinessOperation,
	|					VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef) AS IncomeItem,
	|					VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
	|					UNDEFINED AS IncomeAndExpenseItem,
	|					UNDEFINED AS DimensionOfRevenue,
	|					UNDEFINED AS DimensionOfExpenses,
	|					UNDEFINED AS DimensionOfIncomeExpense,
	|					UNDEFINED AS Contract,
	|					VALUE(Document.SalesOrder.EmptyRef) AS OrderDocument,
	|					VALUE(Catalog.Partners.EmptyRef) AS Partner,
	|					VALUE(Catalog.Counterparties.EmptyRef) AS Counterparty,
	|					VALUE(Catalog.TermsOfSale.EmptyRef) AS Terms,
	|					VALUE(Enum.InventoryTypes.EmptyRef) AS InventoryType,
	|					VALUE(Catalog.BusinessTransactionsSettings.EmptyRef) AS BusinessOperationCatalog,
	|					FALSE AS EconomicOperationOfParish,
	|					FALSE AS EconomicOperationOfExpenditure
	|				}
	|				
	|		) AS InventoryCostBalance
	|WHERE
	|	InventoryCostBalance.Organization IN (&CompanyArray)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		InventoryCost.MonthPeriod,
	|		InventoryCost.ItemsLocationAttributes,
	|		InventoryCost.InventoryOwnerAttribute,
	|		InventoryCost.Organization,
	|		InventoryCost.Lot,
	|		InventoryCost.LotVendorAttributes,
	|		InventoryCost.AccountingSection,
	|		InventoryCost.VATActivityType,
	|		InventoryCost.Products,
	|		InventoryCost.StorageUnit,
	|		InventoryCost.UnitForReports,
	|		InventoryCost.UnitFactorForReports,
	|		InventoryCost.Characteristic,
	|		InventoryCost.Series,
	|		InventoryCost.Warehouse,
	|		InventoryCost.Purpose,
	|		InventoryCost.LineOfBusiness,
	|		InventoryCost.FinancialAccountingGroup,
	|		SUM(0),
	|		SUM(0),
	|		SUM(InventoryCost.CountReceipt),
	|		SUM(InventoryCost.CountExpense),
	|		SUM(CASE
	|			WHEN &ReportData < 1 OR &ReportData > 4
	|			THEN 0
	|			ELSE InventoryCost.AddExpensesForGoodsReceipt
	|		END)
	|	FROM
	|		TTCostPrice AS InventoryCost
	|	
	|	GROUP BY
	|		InventoryCost.MonthPeriod,
	|		InventoryCost.ItemsLocationAttributes,
	|		InventoryCost.InventoryOwnerAttribute,
	|		InventoryCost.Organization,
	|		InventoryCost.Lot,
	|		InventoryCost.LotVendorAttributes,
	|		InventoryCost.AccountingSection,
	|		InventoryCost.VATActivityType,
	|		InventoryCost.Products,
	|		InventoryCost.StorageUnit,
	|		InventoryCost.UnitForReports,
	|		InventoryCost.UnitFactorForReports,
	|		InventoryCost.Characteristic,
	|		InventoryCost.Series,
	|		InventoryCost.Warehouse,
	|		InventoryCost.Purpose,
	|		InventoryCost.LineOfBusiness,
	|		InventoryCost.FinancialAccountingGroup) AS BalanceAndTurnovers
	|
	|GROUP BY
	|	BalanceAndTurnovers.MonthPeriod,
	|	BalanceAndTurnovers.ItemsLocationAttributes,
	|	BalanceAndTurnovers.InventoryOwnerAttribute,
	|	BalanceAndTurnovers.Organization,
	|	BalanceAndTurnovers.Lot,
	|	BalanceAndTurnovers.LotVendorAttributes,
	|	BalanceAndTurnovers.AccountingSection,
	|	BalanceAndTurnovers.VATActivityType,
	|	BalanceAndTurnovers.Products,
	|	BalanceAndTurnovers.StorageUnit,
	|	BalanceAndTurnovers.UnitForReports,
	|	BalanceAndTurnovers.UnitFactorForReports,
	|	BalanceAndTurnovers.Characteristic,
	|	BalanceAndTurnovers.Series,
	|	BalanceAndTurnovers.Warehouse,
	|	BalanceAndTurnovers.Purpose,
	|	BalanceAndTurnovers.LineOfBusiness,
	|	BalanceAndTurnovers.FinancialAccountingGroup
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	InventoryOwnerAttribute,
	|	Organization,
	|	Lot,
	|	LotVendorAttributes,
	|	MonthPeriod,
	|	ItemsLocationAttributes";
	
	Return QueryText;
	
EndFunction

Function QueryTextTT_DetailingInitialCosts(SourceDebuggingMode)

	NestedRequestTexts = New Array;
	
	#Region InitializationOfTemporaryTableDetailingOfInitialExpensesPreliminary
	QueryText =
	"SELECT TOP 0
	|	//The ""Initialization"" tab mode AS A data SourceData,
	|	DATETIME(1, 1, 1) AS InitialCostPeriod,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	UNDEFINED AS Products,
	|	UNDEFINED AS StorageUnit,
	|	UNDEFINED AS UnitForReports,
	|	UNDEFINED AS UnitFactorForReports,
	|	UNDEFINED AS Characteristic,
	|	UNDEFINED AS InventoryOwnerAttribute,
	|	UNDEFINED AS Organization,
	|	UNDEFINED AS Lot,
	|	UNDEFINED AS LotVendorAttributes,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ItemOfExpenditureInitial,
	|	UNDEFINED AS AssetTaxClass,
	|	UNDEFINED AS LotVendorAttributesOfReceiptDocument,
	|	UNDEFINED AS SourceProducts_,
	|	UNDEFINED AS InitialCharacteristic,
	|	UNDEFINED AS SourceReceiptDocument,
	|	0 AS InitialMaterialCostsPerUnit,
	|	0 AS InitialArticleByArticleConstantsPerUnit,
	|	0 AS InitialArticleByArticleVariablesPerUnit,
	|	0 AS InitialAdditionalCostsPerUnit,
	|	0 AS InitialVATPerUnit,
	|	0 AS InitialMaterialCostsPerUnitAtBeginning,
	|	0 AS InitialArticleByArticleConstantsPerUnitAtBeginning,
	|	0 AS InitialArticleByArticleVariablesPerUnitAtBeginning,
	|	0 AS InitialAdditionalCostsPerUnitAtBeginning,
	|	0 AS InitialVATPerUnitAtBeginning,
	|	0 AS InitialMaterialCostsPerUnitAtEnd,
	|	0 AS InitialArticleByArticleConstantsPerUnitAtEnd,
	|	0 AS OriginalLineByLineVariablesAreOneAtEnd,
	|	0 AS InitialAdditionalUnitCostsAtEnd,
	|	0 AS InitialVATPerUnitAtEnd,
	|	0 AS InitialMaterialCostsPerUnitForPeriod,
	|	0 AS InitialArticleByArticleConstantsPerUnitForPeriod,
	|	0 AS InitialItemByItemVariablesPerUnitForPeriod,
	|	0 AS InitialAdditionalCostsPerUnitForPeriod,
	|	0 AS InitialVATPerUnitForPeriod,
	|	0 AS LotQuantity
	|INTO DetailingInitialCostsPreliminary";
	If SourceDebuggingMode Then
		NestedRequestTexts.Add(QueryText);
	EndIf;
	#EndRegion
	
	#Region ItemizeGoodsLotCost
	QueryText =
	"SELECT
	|	//Settings for ""Detailing the highest values of product items"" AS A data SourceData,
	|	DATETIME(1, 1, 1) AS InitialCostPeriod,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	CostDetails.Products AS Products,
	|	CostDetails.Products.UnitOfMeasure AS StorageUnit,
	|	CostDetails.Products.UnitForReports AS UnitForReports,
	|	CostDetails.Products.UnitFactorForReports AS UnitFactorForReports,
	|	CostDetails.Characteristic AS Characteristic,
	|	CostDetails.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	CostDetails.Organization AS Organization,
	|	CostDetails.Lot AS Lot,
	|	CostDetails.LotVendorAttributes AS LotVendorAttributes,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ItemOfExpenditureInitial,
	|	CostDetails.LotVendorAttributesOfReceiptDocument.AssetTaxClass AS AssetTaxClass,
	|	CostDetails.InventoryLocationAttributesOfReceiptDocument AS LotVendorAttributesOfReceiptDocument,
	|	CostDetails.InventoryLocationAttributesOfReceiptDocument.Products AS SourceProducts_,
	|	CostDetails.InventoryLocationAttributesOfReceiptDocument.Characteristic AS InitialCharacteristic,
	|	CostDetails.DocumentInflow AS SourceReceiptDocument,
	|	CASE
	|		WHEN &ReportData = 1
	|			THEN CostDetails.CostInclVAT
	|		WHEN &ReportData = 2
	|			THEN CostDetails.CostExcludingVAT
	|		WHEN &ReportData = 3
	|			THEN CostDetails.CostExcludingVATMan
	|		WHEN &ReportData = 4
	|			THEN CostDetails.CostExcludingVATLocal
	|	END AS InitialMaterialCostsPerUnit,
	|	0 AS InitialArticleByArticleConstantsPerUnit,
	|	0 AS InitialArticleByArticleVariablesPerUnit,
	|	0 AS InitialAdditionalCostsPerUnit,
	|	CASE
	|		WHEN &ReportData = 3
	|			THEN CostDetails.VATManag
	|		WHEN &ReportData = 4
	|			THEN CostDetails.VATLocal
	|	END AS InitialVATPerUnit,
	|	0 AS InitialMaterialCostsPerUnitAtBeginning,
	|	0 AS InitialArticleByArticleConstantsPerUnitAtBeginning,
	|	0 AS InitialArticleByArticleVariablesPerUnitAtBeginning,
	|	0 AS InitialAdditionalCostsPerUnitAtBeginning,
	|	0 AS InitialVATPerUnitAtBeginning,
	|	0 AS InitialMaterialCostsPerUnitAtEnd,
	|	0 AS InitialArticleByArticleConstantsPerUnitAtEnd,
	|	0 AS OriginalLineByLineVariablesAreOneAtEnd,
	|	0 AS InitialAdditionalUnitCostsAtEnd,
	|	0 AS InitialVATPerUnitAtEnd,
	|	0 AS InitialMaterialCostsPerUnitForPeriod,
	|	0 AS InitialArticleByArticleConstantsPerUnitForPeriod,
	|	0 AS InitialItemByItemVariablesPerUnitForPeriod,
	|	0 AS InitialAdditionalCostsPerUnitForPeriod,
	|	0 AS InitialVATPerUnitForPeriod,
	|	0 AS LotQuantity
	|{SELECT
	|	Products.*,
	|	StorageUnit.*,
	|	UnitForReports.*,
	|	UnitFactorForReports,
	|	Characteristic.*,
	|	InventoryOwnerAttribute.*,
	|	Organization.*,
	|	Lot.*,
	|	LotVendorAttributes.*,
	|	ItemOfExpenditureInitial.*,
	|	LotVendorAttributesOfReceiptDocument.*,
	|	SourceProducts_.*,
	|	InitialCharacteristic.*,
	|	SourceReceiptDocument.*}
	|FROM
	|	InformationRegister.ItemizeGoodsLotCost AS CostDetails
	|WHERE
	|	&Output_Details
	|	AND CostDetails.Organization IN (&CompanyArray)
	|	AND (CostDetails.Products, CostDetails.Characteristic, CostDetails.InventoryOwnerAttribute, CostDetails.Organization, CostDetails.Lot, CostDetails.LotVendorAttributes) IN
	|			(SELECT
	|				BalanceAndRegisteredRecords.Products,
	|				BalanceAndRegisteredRecords.Characteristic,
	|				BalanceAndRegisteredRecords.InventoryOwnerAttribute,
	|				BalanceAndRegisteredRecords.Organization,
	|				BalanceAndRegisteredRecords.Lot,
	|				BalanceAndRegisteredRecords.LotVendorAttributes
	|			FROM
	|				VT_BalancesAndRegisteredRecordsForSelectionOfDetailsOfInitialCosts AS BalanceAndRegisteredRecords)
	|{WHERE
	|	CostDetails.Products.* AS Products,
	|	CostDetails.Products.UnitOfMeasure.* AS UnitOfMeasure,
	|	CostDetails.Products.UnitForReports.* AS UnitForReports,
	|	CostDetails.Characteristic.* AS Characteristic,
	|	CostDetails.Organization.* AS Organization,
	|	CostDetails.InventoryOwnerAttribute.* AS InventoryOwnerAttribute,
	|	CostDetails.Lot.* AS Lot}";
	NestedRequestTexts.Add(QueryText);
	#EndRegion
	
	#Region ItemizeLotCostItemizedAndOtherCosts
	QueryText =
	"SELECT
	|	//Settings for ""Detailing the cost of item partypartiesstateynesatrats"" AS A data source,
	|	DATETIME(1, 1, 1) AS InitialCostPeriod,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	CostDetails.Products AS Products,
	|	CostDetails.Products.UnitOfMeasure AS StorageUnit,
	|	CostDetails.Products.UnitForReports AS UnitForReports,
	|	CostDetails.Products.UnitFactorForReports AS UnitFactorForReports,
	|	CostDetails.Characteristic AS Characteristic,
	|	CostDetails.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	CostDetails.Organization AS Organization,
	|	CostDetails.Lot AS Lot,
	|	CostDetails.LotVendorAttributes AS LotVendorAttributes,
	|	CASE
	|		WHEN CostDetails.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			THEN CostDetails.LotVendorAttributesOfReceiptDocument.AssetTaxClass
	|		ELSE CostDetails.ExpenseItem
	|	END AS ItemOfExpenditureInitial,
	|	CostDetails.LotVendorAttributesOfReceiptDocument.AssetTaxClass AS AssetTaxClass,
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS LotVendorAttributesOfReceiptDocument,
	|	VALUE(Catalog.Products.EmptyRef) AS SourceProducts_,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS InitialCharacteristic,
	|	CostDetails.DocumentInflow AS SourceReceiptDocument,
	|	0 AS InitialMaterialCostsPerUnit,
	|	CASE
	|		WHEN NOT(&ReportData = 4
	|							AND ISNULL(CostDetails.ExpenseItem.CostAllocationOptionLocal, VALUE(Enum.CostAllocationOptions.EmptyRef)) = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|						OR NOT &ReportData = 4
	|							AND ISNULL(CostDetails.ExpenseItem.CostAllocationOptionManag, VALUE(Enum.CostAllocationOptions.EmptyRef)) = VALUE(Enum.CostAllocationOptions.ToInventoryCost))
	|				AND 
	|					ISNULL(CostDetails.ExpenseItem.ProductionCostType, VALUE(Enum.ProductionCostType.EmptyRef)) = VALUE(Enum.ProductionCostType.Constant)
	|					OR
	|					FALSE
	|			THEN CASE
	|					WHEN &ReportData = 1
	|						THEN CostDetails.CostInclVAT
	|					WHEN &ReportData = 2
	|						THEN CostDetails.CostExcludingVAT
	|					WHEN &ReportData = 3
	|						THEN CostDetails.CostExcludingVATMan
	|					WHEN &ReportData = 4
	|						THEN CostDetails.CostExcludingVATLocal
	|				END
	|		ELSE 0
	|	END AS InitialArticleByArticleConstantsPerUnit,
	|	CASE
	|		WHEN NOT(&ReportData = 4
	|							AND ISNULL(CostDetails.ExpenseItem.CostAllocationOptionLocal, VALUE(Enum.CostAllocationOptions.EmptyRef)) = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|						OR NOT &ReportData = 4
	|							AND ISNULL(CostDetails.ExpenseItem.CostAllocationOptionManag, VALUE(Enum.CostAllocationOptions.EmptyRef)) = VALUE(Enum.CostAllocationOptions.ToInventoryCost))
	|				AND 
	|					ISNULL(CostDetails.ExpenseItem.ProductionCostType, VALUE(Enum.ProductionCostType.EmptyRef)) = VALUE(Enum.ProductionCostType.Variables1)
	|					OR
	|					FALSE
	|			THEN CASE
	|					WHEN &ReportData = 1
	|						THEN CostDetails.CostInclVAT
	|					WHEN &ReportData = 2
	|						THEN CostDetails.CostExcludingVAT
	|					WHEN &ReportData = 3
	|						THEN CostDetails.CostExcludingVATMan
	|					WHEN &ReportData = 4
	|						THEN CostDetails.CostExcludingVATLocal
	|				END
	|		ELSE 0
	|	END AS InitialArticleByArticleVariablesPerUnit,
	|	CASE
	|		WHEN ISNULL(CostDetails.ExpenseItem, VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)) = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				OR &ReportData = 4
	|					AND ISNULL(CostDetails.ExpenseItem.CostAllocationOptionLocal, VALUE(Enum.CostAllocationOptions.ToInventoryCost)) = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|				OR NOT &ReportData = 4
	|					AND ISNULL(CostDetails.ExpenseItem.CostAllocationOptionManag, VALUE(Enum.CostAllocationOptions.ToInventoryCost)) = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|			THEN CASE
	|					WHEN &ReportData = 1
	|						THEN CostDetails.CostInclVAT
	|					WHEN &ReportData = 2
	|						THEN CostDetails.CostExcludingVAT
	|					WHEN &ReportData = 3
	|						THEN CostDetails.CostExcludingVATMan
	|					WHEN &ReportData = 4
	|						THEN CostDetails.CostExcludingVATLocal
	|				END
	|		ELSE 0
	|	END AS InitialAdditionalCostsPerUnit,
	|	CASE
	|		WHEN ISNULL(CostDetails.ExpenseItem, VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)) = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				OR &ReportData = 4
	|					AND ISNULL(CostDetails.ExpenseItem.CostAllocationOptionLocal, VALUE(Enum.CostAllocationOptions.ToInventoryCost)) = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|				OR NOT &ReportData = 4
	|					AND ISNULL(CostDetails.ExpenseItem.CostAllocationOptionManag, VALUE(Enum.CostAllocationOptions.ToInventoryCost)) = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|			THEN CASE
	|					WHEN &ReportData = 3
	|						THEN CostDetails.VATManag
	|					WHEN &ReportData = 4
	|						THEN CostDetails.VATLocal
	|				END
	|		ELSE 0
	|	END AS InitialVATPerUnit,
	|	0 AS InitialMaterialCostsPerUnitAtBeginning,
	|	0 AS InitialArticleByArticleConstantsPerUnitAtBeginning,
	|	0 AS InitialArticleByArticleVariablesPerUnitAtBeginning,
	|	0 AS InitialAdditionalCostsPerUnitAtBeginning,
	|	0 AS InitialVATPerUnitAtBeginning,
	|	0 AS InitialMaterialCostsPerUnitAtEnd,
	|	0 AS InitialArticleByArticleConstantsPerUnitAtEnd,
	|	0 AS OriginalLineByLineVariablesAreOneAtEnd,
	|	0 AS InitialAdditionalUnitCostsAtEnd,
	|	0 AS InitialVATPerUnitAtEnd,
	|	0 AS InitialMaterialCostsPerUnitForPeriod,
	|	0 AS InitialArticleByArticleConstantsPerUnitForPeriod,
	|	0 AS InitialItemByItemVariablesPerUnitForPeriod,
	|	0 AS InitialAdditionalCostsPerUnitForPeriod,
	|	0 AS InitialVATPerUnitForPeriod,
	|	0 AS LotQuantity
	|FROM
	|	InformationRegister.ItemizeLotCostItemizedAndOtherCosts AS CostDetails
	|WHERE
	|	&Output_Details
	|	AND CostDetails.Organization IN (&CompanyArray)
	|	AND CostDetails.RegistrationPeriod <= ENDOFPERIOD(&EndOfPeriod, MONTH)
	|	AND (CostDetails.Products, CostDetails.Characteristic, CostDetails.InventoryOwnerAttribute, CostDetails.Organization, CostDetails.Lot, CostDetails.LotVendorAttributes) IN
	|			(SELECT
	|				BalanceAndRegisteredRecords.Products,
	|				BalanceAndRegisteredRecords.Characteristic,
	|				BalanceAndRegisteredRecords.InventoryOwnerAttribute,
	|				BalanceAndRegisteredRecords.Organization,
	|				BalanceAndRegisteredRecords.Lot,
	|				BalanceAndRegisteredRecords.LotVendorAttributes
	|			FROM
	|				VT_BalancesAndRegisteredRecordsForSelectionOfDetailsOfInitialCosts AS BalanceAndRegisteredRecords)
	|{WHERE
	|	((CostDetails.Products, CostDetails.Characteristic) IN
	|			(SELECT
	|				SelectionByProductSegment.Products,
	|				SelectionByProductSegment.Characteristic
	|			FROM
	|				SelectionByProductSegment
	|			WHERE
	|				SelectionByProductSegment.FilterByProductSegmentIsUsed = &FilterByProductSegmentIsUsed)),
	|	CostDetails.Products.* AS Products,
	|	CostDetails.Products.UnitOfMeasure.* AS UnitOfMeasure,
	|	CostDetails.Products.UnitForReports.* AS UnitForReports,
	|	CostDetails.Characteristic.* AS Characteristic,
	|	CostDetails.Organization.* AS Organization,
	|	CostDetails.InventoryOwnerAttribute.* AS InventoryOwnerAttribute,
	|	CostDetails.Lot.* AS Lot}";
	NestedRequestTexts.Add(QueryText);
	#EndRegion
	
	#Region DetailingCostOfGoodsItemByItemExpenses_InitialBalances
	QueryText =
	"SELECT
	|	//Mode settings""Detailing the cost of high-cost products and statesnotesreferences_Initial statistics"" AS A source of data,
	|	DATETIME(1, 1, 1) AS InitialCostPeriod,
	|	CostDetails.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	CostDetails.ItemsLocationAttributes.Products AS Products,
	|	CostDetails.ItemsLocationAttributes.Products.UnitOfMeasure AS StorageUnit,
	|	CostDetails.ItemsLocationAttributes.Products.UnitForReports AS UnitForReports,
	|	CostDetails.ItemsLocationAttributes.Products.UnitFactorForReports AS UnitFactorForReports,
	|	CostDetails.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	CostDetails.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	CostDetails.Organization AS Organization,
	|	CostDetails.Lot AS Lot,
	|	CostDetails.LotVendorAttributes AS LotVendorAttributes,
	|	CASE
	|		WHEN CostDetails.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			THEN CostDetails.LotVendorAttributesOfReceiptDocument.AssetTaxClass
	|		ELSE CostDetails.ExpenseItem
	|	END AS ItemOfExpenditureInitial,
	|	CASE
	|		WHEN CostDetails.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			THEN CostDetails.LotVendorAttributesOfReceiptDocument.AssetTaxClass
	|		ELSE CostDetails.ExpenseItem
	|	END AS AssetTaxClass,
	|	CostDetails.LotVendorAttributesOfReceiptDocument AS LotVendorAttributesOfReceiptDocument,
	|	CostDetails.InventoryLocationAttributesOfReceiptDocument.Products AS SourceProducts_,
	|	CostDetails.InventoryLocationAttributesOfReceiptDocument.Characteristic AS InitialCharacteristic,
	|	CostDetails.DocumentInflow AS SourceReceiptDocument,
	|	0 AS InitialMaterialCostsPerUnit,
	|	0 AS InitialArticleByArticleConstantsPerUnit,
	|	0 AS InitialArticleByArticleVariablesPerUnit,
	|	0 AS InitialAdditionalCostsPerUnit,
	|	0 AS InitialVATPerUnit,
	|	0 AS InitialMaterialCostsPerUnitAtBeginning,
	|	CASE
	|		WHEN NOT(&ReportData = 4
	|							AND ISNULL(CostDetails.ExpenseItem.CostAllocationOptionLocal, VALUE(Enum.CostAllocationOptions.EmptyRef)) = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|						OR NOT &ReportData = 4
	|							AND ISNULL(CostDetails.ExpenseItem.CostAllocationOptionManag, VALUE(Enum.CostAllocationOptions.EmptyRef)) = VALUE(Enum.CostAllocationOptions.ToInventoryCost))
	|				AND 
	|					ISNULL(CostDetails.ExpenseItem.ProductionCostType, VALUE(Enum.ProductionCostType.EmptyRef)) = VALUE(Enum.ProductionCostType.Constant)
	|					OR
	|					FALSE
	|			THEN CASE
	|					WHEN &ReportData = 1
	|						THEN CostDetails.CostInclVAT
	|					WHEN &ReportData = 2
	|						THEN CostDetails.CostExcludingVAT
	|					WHEN &ReportData = 3
	|						THEN CostDetails.CostExcludingVATMan
	|					WHEN &ReportData = 4
	|						THEN CostDetails.CostExcludingVATLocal
	|				END
	|		ELSE 0
	|	END AS InitialArticleByArticleConstantsPerUnitAtBeginning,
	|	CASE
	|		WHEN NOT(&ReportData = 4
	|							AND ISNULL(CostDetails.ExpenseItem.CostAllocationOptionLocal, VALUE(Enum.CostAllocationOptions.EmptyRef)) = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|						OR NOT &ReportData = 4
	|							AND ISNULL(CostDetails.ExpenseItem.CostAllocationOptionManag, VALUE(Enum.CostAllocationOptions.EmptyRef)) = VALUE(Enum.CostAllocationOptions.ToInventoryCost))
	|				AND 
	|					ISNULL(CostDetails.ExpenseItem.ProductionCostType, VALUE(Enum.ProductionCostType.EmptyRef)) = VALUE(Enum.ProductionCostType.Variables1)
	|					OR
	|					FALSE
	|			THEN CASE
	|					WHEN &ReportData = 1
	|						THEN CostDetails.CostInclVAT
	|					WHEN &ReportData = 2
	|						THEN CostDetails.CostExcludingVAT
	|					WHEN &ReportData = 3
	|						THEN CostDetails.CostExcludingVATMan
	|					WHEN &ReportData = 4
	|						THEN CostDetails.CostExcludingVATLocal
	|				END
	|		ELSE 0
	|	END AS InitialArticleByArticleVariablesPerUnitAtBeginning,
	|	CASE
	|		WHEN ISNULL(CostDetails.ExpenseItem, VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)) = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				OR &ReportData = 4
	|					AND ISNULL(CostDetails.ExpenseItem.CostAllocationOptionLocal, VALUE(Enum.CostAllocationOptions.EmptyRef)) = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|				OR NOT &ReportData = 4
	|					AND ISNULL(CostDetails.ExpenseItem.CostAllocationOptionManag, VALUE(Enum.CostAllocationOptions.EmptyRef)) = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|			THEN CASE
	|					WHEN &ReportData = 1
	|						THEN CostDetails.CostInclVAT
	|					WHEN &ReportData = 2
	|						THEN CostDetails.CostExcludingVAT
	|					WHEN &ReportData = 3
	|						THEN CostDetails.CostExcludingVATMan
	|					WHEN &ReportData = 4
	|						THEN CostDetails.CostExcludingVATLocal
	|				END
	|		ELSE 0
	|	END AS InitialAdditionalCostsPerUnitAtBeginning,
	|	CASE
	|		WHEN ISNULL(CostDetails.ExpenseItem, VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)) = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				OR &ReportData = 4
	|					AND ISNULL(CostDetails.ExpenseItem.CostAllocationOptionLocal, VALUE(Enum.CostAllocationOptions.EmptyRef)) = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|				OR NOT &ReportData = 4
	|					AND ISNULL(CostDetails.ExpenseItem.CostAllocationOptionManag, VALUE(Enum.CostAllocationOptions.EmptyRef)) = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|			THEN CASE
	|					WHEN &ReportData = 3
	|						THEN CostDetails.VATManag
	|					WHEN &ReportData = 4
	|						THEN CostDetails.VATLocal
	|				END
	|		ELSE 0
	|	END AS InitialVATPerUnitAtBeginning,
	|	0 AS InitialMaterialCostsPerUnitAtEnd,
	|	0 AS InitialArticleByArticleConstantsPerUnitAtEnd,
	|	0 AS OriginalLineByLineVariablesAreOneAtEnd,
	|	0 AS InitialAdditionalUnitCostsAtEnd,
	|	0 AS InitialVATPerUnitAtEnd,
	|	0 AS InitialMaterialCostsPerUnitForPeriod,
	|	0 AS InitialArticleByArticleConstantsPerUnitForPeriod,
	|	0 AS InitialItemByItemVariablesPerUnitForPeriod,
	|	0 AS InitialAdditionalCostsPerUnitForPeriod,
	|	0 AS VATInitialPerUnitForPeriod,
	|	CostDetails.LotQuantity AS LotQuantity
	|FROM
	|	InformationRegister.ItemizeGoodsCostItemizedAndOtherCosts AS CostDetails
	|WHERE
	|	&Output_Details
	|	AND CostDetails.Organization IN (&CompanyArray)
	|	AND CostDetails.Period BETWEEN BEGINOFPERIOD(DATEADD(&BeginOfPeriod, SECOND, -1), MONTH) AND ENDOFPERIOD(DATEADD(&BeginOfPeriod, SECOND, -1), MONTH)
	|	AND (CostDetails.ItemsLocationAttributes.Products, CostDetails.ItemsLocationAttributes.Characteristic, CostDetails.InventoryOwnerAttribute, CostDetails.Organization, CostDetails.Lot, CostDetails.LotVendorAttributes) IN
	|			(SELECT
	|				BalanceAndRegisteredRecords.Products,
	|				BalanceAndRegisteredRecords.Characteristic,
	|				BalanceAndRegisteredRecords.InventoryOwnerAttribute,
	|				BalanceAndRegisteredRecords.Organization,
	|				BalanceAndRegisteredRecords.Lot,
	|				BalanceAndRegisteredRecords.LotVendorAttributes
	|			FROM
	|				VT_BalancesAndRegisteredRecordsForSelectionOfDetailsOfInitialCosts AS BalanceAndRegisteredRecords)
	|{WHERE
	|	((CostDetails.ItemsLocationAttributes.Products, CostDetails.ItemsLocationAttributes.Characteristic) IN
	|			(SELECT
	|				SelectionByProductSegment.Products,
	|				SelectionByProductSegment.Characteristic
	|			FROM
	|				SelectionByProductSegment
	|			WHERE
	|				SelectionByProductSegment.FilterByProductSegmentIsUsed = &FilterByProductSegmentIsUsed)),
	|	CostDetails.ItemsLocationAttributes.Products.* AS Products,
	|	CostDetails.ItemsLocationAttributes.Products.UnitOfMeasure.* AS UnitOfMeasure,
	|	CostDetails.ItemsLocationAttributes.Products.UnitForReports.* AS UnitForReports,
	|	CostDetails.ItemsLocationAttributes.Characteristic.* AS Characteristic,
	|	CostDetails.Organization.* AS Organization,
	|	CostDetails.InventoryOwnerAttribute.* AS InventoryOwnerAttribute,
	|	CostDetails.Lot.* AS Lot}";
	NestedRequestTexts.Add(QueryText);
	#EndRegion
	
	#Region DetailingCostOfGoodsItemByItemExpenses_FinalBalances
	QueryText =
	"SELECT
	|	//Settings for ""Detailing the cost of high-value goods and states_concern_states"" AS A data source_data,
	|	DATETIME(1, 1, 1) AS InitialCostPeriod,
	|	CostDetails.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	CostDetails.ItemsLocationAttributes.Products AS Products,
	|	CostDetails.ItemsLocationAttributes.Products.UnitOfMeasure AS StorageUnit,
	|	CostDetails.ItemsLocationAttributes.Products.UnitForReports AS UnitForReports,
	|	CostDetails.ItemsLocationAttributes.Products.UnitFactorForReports AS UnitFactorForReports,
	|	CostDetails.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	CostDetails.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	CostDetails.Organization AS Organization,
	|	CostDetails.Lot AS Lot,
	|	CostDetails.LotVendorAttributes AS LotVendorAttributes,
	|	CASE
	|		WHEN CostDetails.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			THEN CostDetails.LotVendorAttributesOfReceiptDocument.AssetTaxClass
	|		ELSE CostDetails.ExpenseItem
	|	END AS ItemOfExpenditureInitial,
	|	CASE
	|		WHEN CostDetails.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			THEN CostDetails.LotVendorAttributesOfReceiptDocument.AssetTaxClass
	|		ELSE CostDetails.ExpenseItem
	|	END AS AssetTaxClass,
	|	CostDetails.LotVendorAttributesOfReceiptDocument AS LotVendorAttributesOfReceiptDocument,
	|	CostDetails.InventoryLocationAttributesOfReceiptDocument.Products AS SourceProducts_,
	|	CostDetails.InventoryLocationAttributesOfReceiptDocument.Characteristic AS InitialCharacteristic,
	|	CostDetails.DocumentInflow AS SourceReceiptDocument,
	|	0 AS InitialMaterialCostsPerUnit,
	|	0 AS InitialArticleByArticleConstantsPerUnit,
	|	0 AS InitialArticleByArticleVariablesPerUnit,
	|	0 AS InitialAdditionalCostsPerUnit,
	|	0 AS InitialVATPerUnit,
	|	0 AS InitialMaterialCostsPerUnitAtBeginning,
	|	0 AS InitialArticleByArticleConstantsPerUnitAtBeginning,
	|	0 AS InitialArticleByArticleVariablesPerUnitAtBeginning,
	|	0 AS InitialAdditionalCostsPerUnitAtBeginning,
	|	0 AS InitialVATPerUnitAtBeginning,
	|	0 AS InitialMaterialCostsPerUnitAtEnd,
	|	CASE
	|		WHEN NOT(&ReportData = 4
	|							AND ISNULL(CostDetails.ExpenseItem.CostAllocationOptionLocal, VALUE(Enum.CostAllocationOptions.EmptyRef)) = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|						OR NOT &ReportData = 4
	|							AND ISNULL(CostDetails.ExpenseItem.CostAllocationOptionManag, VALUE(Enum.CostAllocationOptions.EmptyRef)) = VALUE(Enum.CostAllocationOptions.ToInventoryCost))
	|				AND 
	|					ISNULL(CostDetails.ExpenseItem.ProductionCostType, VALUE(Enum.ProductionCostType.EmptyRef)) = VALUE(Enum.ProductionCostType.Constant)
	|					OR
	|					FALSE
	|			THEN CASE
	|					WHEN &ReportData = 1
	|						THEN CostDetails.CostInclVAT
	|					WHEN &ReportData = 2
	|						THEN CostDetails.CostExcludingVAT
	|					WHEN &ReportData = 3
	|						THEN CostDetails.CostExcludingVATMan
	|					WHEN &ReportData = 4
	|						THEN CostDetails.CostExcludingVATLocal
	|				END
	|		ELSE 0
	|	END AS InitialArticleByArticleConstantsPerUnitAtEnd,
	|	CASE
	|		WHEN NOT(&ReportData = 4
	|							AND ISNULL(CostDetails.ExpenseItem.CostAllocationOptionLocal, VALUE(Enum.CostAllocationOptions.EmptyRef)) = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|						OR NOT &ReportData = 4
	|							AND ISNULL(CostDetails.ExpenseItem.CostAllocationOptionManag, VALUE(Enum.CostAllocationOptions.EmptyRef)) = VALUE(Enum.CostAllocationOptions.ToInventoryCost))
	|				AND 
	|					ISNULL(CostDetails.ExpenseItem.ProductionCostType, VALUE(Enum.ProductionCostType.EmptyRef)) = VALUE(Enum.ProductionCostType.Variables1)
	|					OR
	|					FALSE
	|			THEN CASE
	|					WHEN &ReportData = 1
	|						THEN CostDetails.CostInclVAT
	|					WHEN &ReportData = 2
	|						THEN CostDetails.CostExcludingVAT
	|					WHEN &ReportData = 3
	|						THEN CostDetails.CostExcludingVATMan
	|					WHEN &ReportData = 4
	|						THEN CostDetails.CostExcludingVATLocal
	|				END
	|		ELSE 0
	|	END AS OriginalLineByLineVariablesAreOneAtEnd,
	|	CASE
	|		WHEN ISNULL(CostDetails.ExpenseItem, VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)) = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				OR &ReportData = 4
	|					AND ISNULL(CostDetails.ExpenseItem.CostAllocationOptionLocal, VALUE(Enum.CostAllocationOptions.EmptyRef)) = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|				OR NOT &ReportData = 4
	|					AND ISNULL(CostDetails.ExpenseItem.CostAllocationOptionManag, VALUE(Enum.CostAllocationOptions.EmptyRef)) = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|			THEN CASE
	|					WHEN &ReportData = 1
	|						THEN CostDetails.CostInclVAT
	|					WHEN &ReportData = 2
	|						THEN CostDetails.CostExcludingVAT
	|					WHEN &ReportData = 3
	|						THEN CostDetails.CostExcludingVATMan
	|					WHEN &ReportData = 4
	|						THEN CostDetails.CostExcludingVATLocal
	|				END
	|		ELSE 0
	|	END AS InitialAdditionalUnitCostsAtEnd,
	|	CASE
	|		WHEN ISNULL(CostDetails.ExpenseItem, VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)) = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				OR &ReportData = 4
	|					AND ISNULL(CostDetails.ExpenseItem.CostAllocationOptionLocal, VALUE(Enum.CostAllocationOptions.EmptyRef)) = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|				OR NOT &ReportData = 4
	|					AND ISNULL(CostDetails.ExpenseItem.CostAllocationOptionManag, VALUE(Enum.CostAllocationOptions.EmptyRef)) = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|			THEN CASE
	|					WHEN &ReportData = 3
	|						THEN CostDetails.VATManag
	|					WHEN &ReportData = 4
	|						THEN CostDetails.VATLocal
	|				END
	|		ELSE 0
	|	END AS InitialVATPerUnitAtEnd,
	|	0 AS InitialMaterialCostsPerUnitForPeriod,
	|	0 AS InitialArticleByArticleConstantsPerUnitForPeriod,
	|	0 AS InitialItemByItemVariablesPerUnitForPeriod,
	|	0 AS InitialAdditionalCostsPerUnitForPeriod,
	|	0 AS InitialVATPerUnitForPeriod,
	|	CostDetails.LotQuantity AS LotQuantity
	|FROM
	|	InformationRegister.ItemizeGoodsCostItemizedAndOtherCosts AS CostDetails
	|WHERE
	|	&Output_Details
	|	AND CostDetails.Organization IN (&CompanyArray)
	|	AND CostDetails.Period BETWEEN BEGINOFPERIOD(&EndOfPeriod, MONTH) AND ENDOFPERIOD(&EndOfPeriod, MONTH)
	|	AND (CostDetails.ItemsLocationAttributes.Products, CostDetails.ItemsLocationAttributes.Characteristic, CostDetails.InventoryOwnerAttribute, CostDetails.Organization, CostDetails.Lot, CostDetails.LotVendorAttributes) IN
	|			(SELECT
	|				BalanceAndRegisteredRecords.Products,
	|				BalanceAndRegisteredRecords.Characteristic,
	|				BalanceAndRegisteredRecords.InventoryOwnerAttribute,
	|				BalanceAndRegisteredRecords.Organization,
	|				BalanceAndRegisteredRecords.Lot,
	|				BalanceAndRegisteredRecords.LotVendorAttributes
	|			FROM
	|				VT_BalancesAndRegisteredRecordsForSelectionOfDetailsOfInitialCosts AS BalanceAndRegisteredRecords)
	|{WHERE
	|	((CostDetails.ItemsLocationAttributes.Products, CostDetails.ItemsLocationAttributes.Characteristic) IN
	|			(SELECT
	|				SelectionByProductSegment.Products,
	|				SelectionByProductSegment.Characteristic
	|			FROM
	|				SelectionByProductSegment
	|			WHERE
	|				SelectionByProductSegment.FilterByProductSegmentIsUsed = &FilterByProductSegmentIsUsed)),
	|	CostDetails.ItemsLocationAttributes.Products.* AS Products,
	|	CostDetails.ItemsLocationAttributes.Products.UnitOfMeasure.* AS UnitOfMeasure,
	|	CostDetails.ItemsLocationAttributes.Products.UnitForReports.* AS UnitForReports,
	|	CostDetails.ItemsLocationAttributes.Characteristic.* AS Characteristic,
	|	CostDetails.Organization.* AS Organization,
	|	CostDetails.InventoryOwnerAttribute.* AS InventoryOwnerAttribute,
	|	CostDetails.Lot.* AS Lot}";
	NestedRequestTexts.Add(QueryText);
	#EndRegion
	
	#Region DetailingCostOfGoodsItemByItemExpenses_Turnover
	QueryText =
	"SELECT
	|	//Settings for ""Detailing the cost of high-value goods and stateing_references"" AS A data source_data,
	|	BEGINOFPERIOD(CostDetails.Period, MONTH) AS InitialCostPeriod,
	|	CostDetails.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	CostDetails.ItemsLocationAttributes.Products AS Products,
	|	CostDetails.ItemsLocationAttributes.Products.UnitOfMeasure AS StorageUnit,
	|	CostDetails.ItemsLocationAttributes.Products.UnitForReports AS UnitForReports,
	|	CostDetails.ItemsLocationAttributes.Products.UnitFactorForReports AS UnitFactorForReports,
	|	CostDetails.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	CostDetails.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	CostDetails.Organization AS Organization, 
	|	CostDetails.Lot AS Lot,
	|	CostDetails.LotVendorAttributes AS LotVendorAttributes,
	|	CASE
	|		WHEN CostDetails.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			THEN CostDetails.LotVendorAttributesOfReceiptDocument.AssetTaxClass
	|		ELSE CostDetails.ExpenseItem
	|	END AS ItemOfExpenditureInitial,
	|	CASE
	|		WHEN CostDetails.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			THEN CostDetails.LotVendorAttributesOfReceiptDocument.AssetTaxClass
	|		ELSE CostDetails.ExpenseItem
	|	END AS AssetTaxClass,
	|	CostDetails.LotVendorAttributesOfReceiptDocument AS LotVendorAttributesOfReceiptDocument,
	|	CostDetails.InventoryLocationAttributesOfReceiptDocument.Products AS SourceProducts_,
	|	CostDetails.InventoryLocationAttributesOfReceiptDocument.Characteristic AS InitialCharacteristic,
	|	CostDetails.DocumentInflow AS SourceReceiptDocument,
	|	0 AS InitialMaterialCostsPerUnit,
	|	0 AS InitialArticleByArticleConstantsPerUnit,
	|	0 AS InitialArticleByArticleVariablesPerUnit,
	|	0 AS InitialAdditionalCostsPerUnit,
	|	0 AS InitialVATPerUnit,
	|	0 AS InitialMaterialCostsPerUnitAtBeginning,
	|	0 AS InitialArticleByArticleConstantsPerUnitAtBeginning,
	|	0 AS InitialArticleByArticleVariablesPerUnitAtBeginning,
	|	0 AS InitialAdditionalCostsPerUnitAtBeginning,
	|	0 AS InitialVATPerUnitAtBeginning,
	|	0 AS InitialMaterialCostsPerUnitAtEnd,
	|	0 AS InitialArticleByArticleConstantsPerUnitAtEnd,
	|	0 AS OriginalLineByLineVariablesAreOneAtEnd,
	|	0 AS InitialAdditionalUnitCostsAtEnd,
	|	0 AS InitialVATPerUnitAtEnd,
	|	0 AS InitialMaterialCostsPerUnitForPeriod,
	|	CASE
	|		WHEN NOT(&ReportData = 4
	|							AND ISNULL(CostDetails.ExpenseItem.CostAllocationOptionLocal, VALUE(Enum.CostAllocationOptions.EmptyRef)) = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|						OR NOT &ReportData = 4
	|							AND ISNULL(CostDetails.ExpenseItem.CostAllocationOptionManag, VALUE(Enum.CostAllocationOptions.EmptyRef)) = VALUE(Enum.CostAllocationOptions.ToInventoryCost))
	|				AND 
	|					ISNULL(CostDetails.ExpenseItem.ProductionCostType, VALUE(Enum.ProductionCostType.EmptyRef)) = VALUE(Enum.ProductionCostType.Constant)
	|					OR
	|					FALSE
	|			THEN CASE
	|					WHEN &ReportData = 1
	|						THEN CostDetails.CostInclVAT
	|					WHEN &ReportData = 2
	|						THEN CostDetails.CostExcludingVAT
	|					WHEN &ReportData = 3
	|						THEN CostDetails.CostExcludingVATMan
	|					WHEN &ReportData = 4
	|						THEN CostDetails.CostExcludingVATLocal
	|				END
	|		ELSE 0
	|	END AS InitialArticleByArticleConstantsPerUnitForPeriod,
	|	CASE
	|		WHEN NOT(&ReportData = 4
	|							AND ISNULL(CostDetails.ExpenseItem.CostAllocationOptionLocal, VALUE(Enum.CostAllocationOptions.EmptyRef)) = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|						OR NOT &ReportData = 4
	|							AND ISNULL(CostDetails.ExpenseItem.CostAllocationOptionManag, VALUE(Enum.CostAllocationOptions.EmptyRef)) = VALUE(Enum.CostAllocationOptions.ToInventoryCost))
	|				AND 
	|					ISNULL(CostDetails.ExpenseItem.ProductionCostType, VALUE(Enum.ProductionCostType.EmptyRef)) = VALUE(Enum.ProductionCostType.Variables1)
	|					OR
	|					FALSE
	|			THEN CASE
	|					WHEN &ReportData = 1
	|						THEN CostDetails.CostInclVAT
	|					WHEN &ReportData = 2
	|						THEN CostDetails.CostExcludingVAT
	|					WHEN &ReportData = 3
	|						THEN CostDetails.CostExcludingVATMan
	|					WHEN &ReportData = 4
	|						THEN CostDetails.CostExcludingVATLocal
	|				END
	|		ELSE 0
	|	END AS InitialItemByItemVariablesPerUnitForPeriod,
	|	CASE
	|		WHEN ISNULL(CostDetails.ExpenseItem, VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)) = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				OR &ReportData = 4
	|					AND ISNULL(CostDetails.ExpenseItem.CostAllocationOptionLocal, VALUE(Enum.CostAllocationOptions.EmptyRef)) = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|				OR NOT &ReportData = 4
	|					AND ISNULL(CostDetails.ExpenseItem.CostAllocationOptionManag, VALUE(Enum.CostAllocationOptions.EmptyRef)) = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|			THEN CASE
	|					WHEN &ReportData = 1
	|						THEN CostDetails.CostInclVAT
	|					WHEN &ReportData = 2
	|						THEN CostDetails.CostExcludingVAT
	|					WHEN &ReportData = 3
	|						THEN CostDetails.CostExcludingVATMan
	|					WHEN &ReportData = 4
	|						THEN CostDetails.CostExcludingVATLocal
	|				END
	|		ELSE 0
	|	END AS InitialAdditionalCostsPerUnitForPeriod,
	|	CASE
	|		WHEN ISNULL(CostDetails.ExpenseItem, VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)) = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				OR &ReportData = 4
	|					AND ISNULL(CostDetails.ExpenseItem.CostAllocationOptionLocal, VALUE(Enum.CostAllocationOptions.EmptyRef)) = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|				OR NOT &ReportData = 4
	|					AND ISNULL(CostDetails.ExpenseItem.CostAllocationOptionManag, VALUE(Enum.CostAllocationOptions.EmptyRef)) = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|			THEN CASE
	|					WHEN &ReportData = 3
	|						THEN CostDetails.VATManag
	|					WHEN &ReportData = 4
	|						THEN CostDetails.VATLocal
	|				END
	|		ELSE 0
	|	END AS InitialVATPerUnitForPeriod,
	|	CostDetails.LotQuantity AS LotQuantity
	|FROM
	|	InformationRegister.ItemizeGoodsCostItemizedAndOtherCosts AS CostDetails
	|WHERE
	|	&Output_Details
	|	AND CostDetails.Organization IN (&CompanyArray)
	|	AND CostDetails.Period BETWEEN BEGINOFPERIOD(&BeginOfPeriod, MONTH) AND ENDOFPERIOD(&EndOfPeriod, MONTH)
	|	AND (CostDetails.ItemsLocationAttributes.Products, CostDetails.ItemsLocationAttributes.Characteristic, CostDetails.InventoryOwnerAttribute, CostDetails.Organization, CostDetails.Lot, CostDetails.LotVendorAttributes) IN
	|			(SELECT
	|				BalanceAndRegisteredRecords.Products,
	|				BalanceAndRegisteredRecords.Characteristic,
	|				BalanceAndRegisteredRecords.InventoryOwnerAttribute,
	|				BalanceAndRegisteredRecords.Organization,
	|				BalanceAndRegisteredRecords.Lot,
	|				BalanceAndRegisteredRecords.LotVendorAttributes
	|			FROM
	|				VT_BalancesAndRegisteredRecordsForSelectionOfDetailsOfInitialCosts AS BalanceAndRegisteredRecords)
	|{WHERE
	|	((CostDetails.ItemsLocationAttributes.Products, CostDetails.ItemsLocationAttributes.Characteristic) IN
	|			(SELECT
	|				SelectionByProductSegment.Products,
	|				SelectionByProductSegment.Characteristic
	|			FROM
	|				SelectionByProductSegment
	|			WHERE
	|				SelectionByProductSegment.FilterByProductSegmentIsUsed = &FilterByProductSegmentIsUsed)),
	|	CostDetails.ItemsLocationAttributes.Products.* AS Products,
	|	CostDetails.ItemsLocationAttributes.Products.UnitOfMeasure.* AS UnitOfMeasure,
	|	CostDetails.ItemsLocationAttributes.Products.UnitForReports.* AS UnitForReports,
	|	CostDetails.ItemsLocationAttributes.Characteristic.* AS Characteristic,
	|	CostDetails.Organization.* AS Organization,
	|	CostDetails.InventoryOwnerAttribute.* AS InventoryOwnerAttribute,
	|	CostDetails.Lot.* AS Lot}";
	NestedRequestTexts.Add(QueryText);
	#EndRegion
	
	NestedQueryString = StrConcat(NestedRequestTexts, TMCommonUse.QuerySeparatorInJoin(True));
	
	#Region PlacementInFinalTemporaryTable
	QueryText =
	"SELECT ALLOWED
	|	NestedQuery.InitialCostPeriod AS InitialCostPeriod,
	|	NestedQuery.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	NestedQuery.Products AS Products,
	|	NestedQuery.StorageUnit AS StorageUnit,
	|	NestedQuery.UnitForReports AS UnitForReports,
	|	NestedQuery.UnitFactorForReports AS UnitFactorForReports,
	|	NestedQuery.Characteristic AS Characteristic,
	|	NestedQuery.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	NestedQuery.Organization AS Organization,
	|	NestedQuery.Lot AS Lot,
	|	NestedQuery.LotVendorAttributes AS LotVendorAttributes,
	|	NestedQuery.ItemOfExpenditureInitial AS ItemOfExpenditureInitial,
	|	NestedQuery.AssetTaxClass AS AssetTaxClass,
	|	NestedQuery.LotVendorAttributesOfReceiptDocument AS LotVendorAttributesOfReceiptDocument,
	|	NestedQuery.SourceProducts_ AS SourceProducts_,
	|	NestedQuery.InitialCharacteristic AS InitialCharacteristic,
	|	NestedQuery.SourceReceiptDocument AS SourceReceiptDocument,
	|	SUM(NestedQuery.InitialMaterialCostsPerUnit) AS InitialMaterialCostsPerUnit,
	|	SUM(NestedQuery.InitialArticleByArticleConstantsPerUnit) AS InitialArticleByArticleConstantsPerUnit,
	|	SUM(NestedQuery.InitialArticleByArticleVariablesPerUnit) AS InitialArticleByArticleVariablesPerUnit,
	|	SUM(NestedQuery.InitialAdditionalCostsPerUnit) AS InitialAdditionalCostsPerUnit,
	|	SUM(NestedQuery.InitialVATPerUnit) AS InitialVATPerUnit,
	|	SUM(NestedQuery.InitialMaterialCostsPerUnitAtBeginning) AS InitialMaterialCostsPerUnitAtBeginning,
	|	SUM(NestedQuery.InitialArticleByArticleConstantsPerUnitAtBeginning) AS InitialArticleByArticleConstantsPerUnitAtBeginning,
	|	SUM(NestedQuery.InitialArticleByArticleVariablesPerUnitAtBeginning) AS InitialArticleByArticleVariablesPerUnitAtBeginning,
	|	SUM(NestedQuery.InitialAdditionalCostsPerUnitAtBeginning) AS InitialAdditionalCostsPerUnitAtBeginning,
	|	SUM(NestedQuery.InitialVATPerUnitAtBeginning) AS InitialVATPerUnitAtBeginning,
	|	SUM(NestedQuery.InitialMaterialCostsPerUnitAtEnd) AS InitialMaterialCostsPerUnitAtEnd,
	|	SUM(NestedQuery.InitialArticleByArticleConstantsPerUnitAtEnd) AS InitialArticleByArticleConstantsPerUnitAtEnd,
	|	SUM(NestedQuery.OriginalLineByLineVariablesAreOneAtEnd) AS OriginalLineByLineVariablesAreOneAtEnd,
	|	SUM(NestedQuery.InitialAdditionalUnitCostsAtEnd) AS InitialAdditionalUnitCostsAtEnd,
	|	SUM(NestedQuery.InitialVATPerUnitAtEnd) AS InitialVATPerUnitAtEnd,
	|	SUM(NestedQuery.InitialMaterialCostsPerUnitForPeriod) AS InitialMaterialCostsPerUnitForPeriod,
	|	SUM(NestedQuery.InitialArticleByArticleConstantsPerUnitForPeriod) AS InitialArticleByArticleConstantsPerUnitForPeriod,
	|	SUM(NestedQuery.InitialItemByItemVariablesPerUnitForPeriod) AS InitialItemByItemVariablesPerUnitForPeriod,
	|	SUM(NestedQuery.InitialAdditionalCostsPerUnitForPeriod) AS InitialAdditionalCostsPerUnitForPeriod,
	|	SUM(NestedQuery.InitialVATPerUnitForPeriod) AS InitialVATPerUnitForPeriod,
	|	SUM(NestedQuery.LotQuantity) AS LotQuantity
	|INTO TT_DetailingInitialCosts
	|{SELECT
	|	InitialCostPeriod,
	|	ItemsLocationAttributes.*,
	|	Products.*,
	|	StorageUnit.*,
	|	UnitForReports.*,
	|	UnitFactorForReports,
	|	Characteristic.*,
	|	InventoryOwnerAttribute.*,
	|	Organization.*,
	|	Lot.*,
	|	LotVendorAttributes.*,
	|	ItemOfExpenditureInitial.*,
	|	AssetTaxClass.*,
	|	LotVendorAttributesOfReceiptDocument.*,
	|	SourceProducts_.*,
	|	InitialCharacteristic.*,
	|	SourceReceiptDocument.*,
	|	InitialMaterialCostsPerUnit,
	|	InitialArticleByArticleConstantsPerUnit,
	|	InitialArticleByArticleVariablesPerUnit,
	|	InitialAdditionalCostsPerUnit,
	|	InitialVATPerUnit,
	|	InitialMaterialCostsPerUnitAtBeginning,
	|	InitialArticleByArticleConstantsPerUnitAtBeginning,
	|	InitialArticleByArticleVariablesPerUnitAtBeginning,
	|	InitialAdditionalCostsPerUnitAtBeginning,
	|	InitialVATPerUnitAtBeginning,
	|	InitialMaterialCostsPerUnitAtEnd,
	|	InitialArticleByArticleConstantsPerUnitAtEnd,
	|	OriginalLineByLineVariablesAreOneAtEnd,
	|	InitialAdditionalUnitCostsAtEnd,
	|	InitialVATPerUnitAtEnd,
	|	InitialMaterialCostsPerUnitForPeriod,
	|	InitialArticleByArticleConstantsPerUnitForPeriod,
	|	InitialItemByItemVariablesPerUnitForPeriod,
	|	InitialAdditionalCostsPerUnitForPeriod,
	|	InitialVATPerUnitForPeriod,
	|	LotQuantity}
	|FROM
	|	DetailingInitialCostsPreliminary AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.StorageUnit,
	|	NestedQuery.UnitForReports,
	|	NestedQuery.InitialCharacteristic,
	|	NestedQuery.ItemOfExpenditureInitial,
	|	NestedQuery.AssetTaxClass,
	|	NestedQuery.ItemsLocationAttributes,
	|	NestedQuery.InitialCostPeriod,
	|	NestedQuery.Lot,
	|	NestedQuery.Characteristic,
	|	NestedQuery.InventoryOwnerAttribute,
	|	NestedQuery.Organization,
	|	NestedQuery.SourceReceiptDocument,
	|	NestedQuery.Products,
	|	NestedQuery.LotVendorAttributesOfReceiptDocument,
	|	NestedQuery.LotVendorAttributes,
	|	NestedQuery.SourceProducts_,
	|	NestedQuery.UnitFactorForReports";
	#EndRegion
	
	If SourceDebuggingMode Then
		
		QueryTexts = New Array;
		QueryTexts.Add(NestedQueryString);
		QueryTexts.Add(QueryText);
		QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
		
	Else
		QueryText = StrReplace(QueryText, "DetailingInitialCostsPreliminary", "(" + NestedQueryString + ")");
	EndIf;
	
	Return QueryText;
	
EndFunction


#EndRegion

#EndRegion

#EndIf
