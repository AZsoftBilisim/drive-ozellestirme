#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the default values for register resources.
// The key names of the structure should strictly correspond to the resource names in the register.
// 
// Returns:
// 	Structure - the structure of register resource values.
Function DefaultValues() Export
	
	StructureOfValues = New Structure;
	
	StructureOfValues.Insert("InventoryValuationMethod", Enums.InventoryValuationMethods.AveragePerMonth);
	StructureOfValues.Insert("ProductCostingByPlannedCost", False);
	StructureOfValues.Insert("ToGenerateLossAllowance", False);
	StructureOfValues.Insert("FrequencyOfLossAllowance", Enums.Periodicity.Month);
	StructureOfValues.Insert("RecognizeResearchExpensesInCurrentPeriod", False);
	StructureOfValues.Insert("ExpenseItemForRD", Undefined);
	StructureOfValues.Insert("ExpensesDimensionResearchExpenses", Undefined);
	StructureOfValues.Insert("DivisionIntoShortTermLongTermAssetsAndLiabilities", False);
	StructureOfValues.Insert("DurationOfCompanyOperatingCycle", 12);
	StructureOfValues.Insert("AccountingForRentAccordingToFSB252018", True);
	StructureOfValues.Insert("AccountingForDiscountedAccountsPayableToVendors", False);
	StructureOfValues.Insert("InterestExpenseWriteOffItem", Undefined);
	StructureOfValues.Insert("WriteOffsDimensionOfInterestExpense", Undefined);
	StructureOfValues.Insert("AccountForDiscountingOfProvisionsAndContingentLiabilities", False);
	StructureOfValues.Insert("ItemOfInterestExpenseWriteOffOfProvisionDiscounting", Undefined);
	StructureOfValues.Insert("AnalyticsOfInterestExpenseWriteOffOfProvisionDiscounting", Undefined);
	StructureOfValues.Insert("ApplicationDiscountingPeriod", 0);
	StructureOfValues.Insert("AccountingPoliciesExist", False);
	StructureOfValues.Insert("MonthOfFiscalYearBeginning", 1);
	StructureOfValues.Insert("ItemizeMaterialAndItemizedExpensesInInventoryCost", False);
	StructureOfValues.Insert("ReverseProvisionWhenWritingOffInventoryToExpenses", True);
	StructureOfValues.Insert("DebtEvaluationProcedure", Undefined);
	StructureOfValues.Insert("InterestIncomeItemOfFinancialLease", Undefined);
	StructureOfValues.Insert("InterestIncomeDimensionOfFinancialLease", Undefined);
	StructureOfValues.Insert("IncomeItemForFinancialLeaseServices", Undefined);
	StructureOfValues.Insert("IncomeDimensionForFinancialLeaseServices", Undefined);
	StructureOfValues.Insert("ItemizeVariancesByLinesOfBusiness", False);
	StructureOfValues.Insert("ItemizeVariancesByBusinessUnits", False);
	StructureOfValues.Insert("ItemizeVariancesByWarehousesStorageLocations", False);
	StructureOfValues.Insert("DoNotBreakDownToReceiptDocuments", False);
	StructureOfValues.Insert("AllocateVariancesInPreviousPeriods", True);
	StructureOfValues.Insert("WriteOffProductCostVariancesToCostOfGoodsSold", True);
	StructureOfValues.Insert("AccountingPolicyForFixedAssets", Enums.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards);
	StructureOfValues.Insert("ProcedureOfFixedAssetDepreciationCharge", Enums.DepreciationProcedure.FromDateOfRecognitionInAccounting);
	StructureOfValues.Insert("ProcedureOfIntangibleAssetAmortizationCharge", Enums.DepreciationProcedure.FromDateOfRecognitionInAccounting);
	StructureOfValues.Insert("LeasedAssetDepreciationChargeProcedureManag", Enums.DepreciationProcedure.FromDateOfRecognitionInAccounting);
	StructureOfValues.Insert("FixedAssetRevaluationMethod", Enums.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod);
	StructureOfValues.Insert("IntangibleAssetRevaluationMethod", Enums.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod);
	
	If GetFunctionalOption("LocalFAAccounting") Then
		StructureOfValues.Insert("FixedAssetAccountingProcedureInLocalAccounting", Enums.FixedAssetAccountingProcedureInLocalAccounting.Independent);
		StructureOfValues.Insert("ProcedureOfFixedAssetDepreciationChargeLocal", Enums.DepreciationProcedure.FromDateOfRecognitionInAccounting);
		StructureOfValues.Insert("ProcedureOfIntangibleAssetAmortizationChargeLocal", Enums.DepreciationProcedure.FromDateOfRecognitionInAccounting);
		StructureOfValues.Insert("LeasedFixedAssetDepreciationChargeProcedureLocal", Enums.DepreciationProcedure.FromDateOfRecognitionInAccounting);
	Else
		StructureOfValues.Insert("FixedAssetAccountingProcedureInLocalAccounting", Enums.FixedAssetAccountingProcedureInLocalAccounting.MatchesManagementAccounting);
		StructureOfValues.Insert("ProcedureOfFixedAssetDepreciationChargeLocal", Enums.DepreciationProcedure.FromDateOfRecognitionInAccounting);
		StructureOfValues.Insert("ProcedureOfIntangibleAssetAmortizationChargeLocal", Enums.DepreciationProcedure.FromDateOfRecognitionInAccounting);
		StructureOfValues.Insert("LeasedFixedAssetDepreciationChargeProcedureLocal", Enums.DepreciationProcedure.FromDateOfRecognitionInAccounting);
	EndIf;
	
	StructureOfValues.Insert("PostingOptionForImpairedFADepreciation", Enums.PostingOptionsForImpairedFADepreciation.AddImpairmentAdjustment);
	
	StructureOfValues.Insert("ProducesExcisableGoods", False);
	StructureOfValues.Insert("ImportsExcisableGoods", False);
	
	Return StructureOfValues
	
EndFunction

// Returns a representation of the beginning of the fiscal year
// 
// Parameters:
//  MonthOfFiscalYearBeginning - Number - Serial number of the month
// 
// Returns:
//  String - Presentation of the month of the beginning of the financial year
Function PresentationOfBeginningOfFinancialYear(MonthOfFiscalYearBeginning) Export
	
	If MonthOfFiscalYearBeginning = 1 Then
		Return NStr("vi = 'Tháng 1';
					|ru = 'Январь';
					|en = 'January'; fa = 'ژانویه';
					|it = 'Gennaio';
					|pl = 'Styczeń';
					|tr = 'Ocak'");
	ElsIf MonthOfFiscalYearBeginning = 2 Then
		Return NStr("vi = 'Tháng 2';
					|ru = 'Февраль';
					|en = 'February'; fa = 'فوریه';
					|it = 'Febbraio';
					|pl = 'Luty';
					|tr = 'Şubat'");
	ElsIf MonthOfFiscalYearBeginning = 3 Then
		Return NStr("vi = 'Tháng 3';
					|ru = 'Март';
					|en = 'March'; fa = 'مارس';
					|it = 'Marzo';
					|pl = 'Marzec';
					|tr = 'Mart'");
	ElsIf MonthOfFiscalYearBeginning = 4 Then
		Return NStr("vi = 'Tháng 4';
					|ru = 'Апрель';
					|en = 'April'; fa = 'آوریل';
					|it = 'Aprile';
					|pl = 'Kwiecień';
					|tr = 'Nisan'");
	ElsIf MonthOfFiscalYearBeginning = 5 Then
		Return NStr("vi = 'Tháng 5';
					|ru = 'Май';
					|en = 'May'; fa = 'مه';
					|it = 'Maggio';
					|pl = 'Maj';
					|tr = 'Mayıs'");
	ElsIf MonthOfFiscalYearBeginning = 6 Then
		Return NStr("vi = 'Tháng 6';
					|ru = 'Июнь';
					|en = 'June'; fa = 'ژوئن';
					|it = 'Giugno';
					|pl = 'Czerwiec';
					|tr = 'Haziran'");
	ElsIf MonthOfFiscalYearBeginning = 7 Then
		Return NStr("vi = 'Tháng 7';
					|ru = 'Июль';
					|en = 'July'; fa = 'ژوئیه';
					|it = 'Luglio';
					|pl = 'Lipiec';
					|tr = 'Temmuz'");
	ElsIf MonthOfFiscalYearBeginning = 8 Then
		Return NStr("vi = 'Tháng 8';
					|ru = 'Август';
					|en = 'August'; fa = 'اوت';
					|it = 'Agosto';
					|pl = 'Sierpień';
					|tr = 'Ağustos'");
	ElsIf MonthOfFiscalYearBeginning = 9 Then
		Return NStr("vi = 'Tháng 9';
					|ru = 'Сентябрь';
					|en = 'September'; fa = 'سپتامبر';
					|it = 'Settembre';
					|pl = 'Wrzesień';
					|tr = 'Eylül'");
	ElsIf MonthOfFiscalYearBeginning = 10 Then
		Return NStr("vi = 'Tháng 10';
					|ru = 'Октябрь';
					|en = 'October'; fa = 'اکتبر';
					|it = 'Ottobre';
					|pl = 'Październik';
					|tr = 'Ekim'");
	ElsIf MonthOfFiscalYearBeginning = 11 Then
		Return NStr("vi = 'Tháng 11';
					|ru = 'Ноябрь';
					|en = 'November'; fa = 'نوامبر';
					|it = 'Novembre';
					|pl = 'Listopad';
					|tr = 'Kasım'");
	ElsIf MonthOfFiscalYearBeginning = 12 Then
		Return NStr("vi = 'Tháng 12';
					|ru = 'Декабрь';
					|en = 'December'; fa = 'دسامبر';
					|it = 'Dicembre';
					|pl = 'Grudzień';
					|tr = 'Aralık'");
	Else
		Return NStr("vi = 'Không xác định';
					|ru = 'Неопределено';
					|en = 'Undefined'; fa = 'تعریف‌نشده';
					|it = 'Indefinito';
					|pl = 'Undefined';
					|tr = 'Tanımsız'");
	EndIf;
	
EndFunction

// Returns the request text based on the register data.
// 
// Returns:
// 	String - query text.
Function QueryTextCurrentTaxAccountingPolicySettings() Export
	QueryText = "SELECT ALLOWED
	|	CASE WHEN SliceTable.Period IS NULL THEN
	|		FALSE
	|	ELSE
	|		TRUE
	|	END AS AccountingPoliciesExist,
	|	SliceTable.Period AS Period,
	|	ParentOrganizations.BranchOffice AS Organization,
	|	SliceTable.InventoryValuationMethod AS InventoryValuationMethod,
	|	SliceTable.ToGenerateLossAllowance AS ToGenerateLossAllowance,
	|	SliceTable.FrequencyOfLossAllowance AS FrequencyOfLossAllowance,
	|	SliceTable.ProductCostingByPlannedCost AS ProductCostingByPlannedCost,
	|	SliceTable.RecognizeResearchExpensesInCurrentPeriod AS RecognizeResearchExpensesInCurrentPeriod,
	|	SliceTable.ExpenseItemForRD AS ExpenseItemForRD,
	|	SliceTable.ExpensesDimensionResearchExpenses AS ExpensesDimensionResearchExpenses,
	|	SliceTable.DivisionIntoShortTermLongTermAssetsAndLiabilities,
	|	SliceTable.DurationOfCompanyOperatingCycle,
	|	SliceTable.AccountingPolicyForFixedAssets AS AccountingPolicyForFixedAssets,
	|	SliceTable.ProcedureOfFixedAssetDepreciationCharge AS ProcedureOfFixedAssetDepreciationCharge,
	|	SliceTable.ProcedureOfIntangibleAssetAmortizationCharge AS ProcedureOfIntangibleAssetAmortizationCharge,
	|	SliceTable.LeasedAssetDepreciationChargeProcedureManag AS LeasedAssetDepreciationChargeProcedureManag,
	|	SliceTable.FixedAssetAccountingProcedureInLocalAccounting AS FixedAssetAccountingProcedureInLocalAccounting,
	|	SliceTable.ProcedureOfFixedAssetDepreciationChargeLocal AS ProcedureOfFixedAssetDepreciationChargeLocal,
	|	SliceTable.ProcedureOfIntangibleAssetAmortizationChargeLocal AS ProcedureOfIntangibleAssetAmortizationChargeLocal,
	|	SliceTable.LeasedFixedAssetDepreciationChargeProcedureLocal AS LeasedFixedAssetDepreciationChargeProcedureLocal,
	|	SliceTable.FixedAssetRevaluationMethod AS FixedAssetRevaluationMethod,
	|	SliceTable.IntangibleAssetRevaluationMethod AS IntangibleAssetRevaluationMethod,
	|	SliceTable.AccountingForRentAccordingToFSB252018 AS AccountingForRentAccordingToFSB252018,
	|	SliceTable.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|	SliceTable.MonthOfFiscalYearBeginning AS MonthOfFiscalYearBeginning,
	|	SliceTable.AccountingForDiscountedAccountsPayableToVendors AS AccountingForDiscountedAccountsPayableToVendors,
	|	SliceTable.InterestExpenseWriteOffItem AS InterestExpenseWriteOffItem,
	|	SliceTable.WriteOffsDimensionOfInterestExpense AS WriteOffsDimensionOfInterestExpense,
	|	SliceTable.ItemOfInterestExpenseWriteOffOfProvisionDiscounting AS ItemOfInterestExpenseWriteOffOfProvisionDiscounting,
	|	SliceTable.AnalyticsOfInterestExpenseWriteOffOfProvisionDiscounting AS AnalyticsOfInterestExpenseWriteOffOfProvisionDiscounting,
	|	SliceTable.AccountForDiscountingOfProvisionsAndContingentLiabilities AS AccountForDiscountingOfProvisionsAndContingentLiabilities,
	|	SliceTable.ApplicationDiscountingPeriod AS ApplicationDiscountingPeriod,
	|	SliceTable.ItemizeMaterialAndItemizedExpensesInInventoryCost,
	|	SliceTable.ReverseProvisionWhenWritingOffInventoryToExpenses,
	|	SliceTable.DebtEvaluationProcedure AS DebtEvaluationProcedure,
	|	SliceTable.InterestIncomeItemOfFinancialLease,
	|	SliceTable.InterestIncomeDimensionOfFinancialLease,
	|	SliceTable.IncomeItemForFinancialLeaseServices,
	|	SliceTable.IncomeDimensionForFinancialLeaseServices,
	|	SliceTable.ProducesExcisableGoods,
	|	SliceTable.ImportsExcisableGoods,
	|	SliceTable.ItemizeVariancesByLinesOfBusiness,
	|	SliceTable.ItemizeVariancesByBusinessUnits,
	|	SliceTable.ItemizeVariancesByWarehousesStorageLocations,
	|	SliceTable.WriteOffProductCostVariancesToCostOfGoodsSold,
	|	SliceTable.DrillDownProductCostToInitialCosts,
	|	SliceTable.DoNotBreakDownToReceiptDocuments,
	|	SliceTable.AllocateVariancesInPreviousPeriods
	|FROM
	|	TTParentOrganizations AS ParentOrganizations
	|		LEFT JOIN InformationRegister.FinancialAccountingPolicy.SliceLast(&Period, Organization IN
	|			(SELECT
	|				ParentOrganizations.Organization
	|			FROM
	|				TTParentOrganizations AS ParentOrganizations)) AS SliceTable
	|		ON ParentOrganizations.Organization = SliceTable.Organization
	|";
	Return QueryText
	
EndFunction

// Generates a text description of the set parameters.
// 
// Parameters:
// 	Organization - CatalogRef.Companies - link to the organization.
// 	ValidityDate - Date - period of validity of settings.
// 	CurrentSettings_ - Structure - the parameters of the accounting policies.
// 	All - Boolean - if True, it returns a description of all settings.
// Returns:
// 	String - Description of the current parameters in a string.
Function DescriptionOfActiveParameters(Organization, ValidityDate = Undefined, CurrentSettings_ = Undefined, All = False) Export
	
	If CurrentSettings_ = Undefined Then
		CurrentSettings_ = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate(
			"FinancialAccountingPolicy",
			Organization,
			ValidityDate,
			False);
	EndIf;
	StringPattern_ = "%1: %2." + Chars.LF;
	StringPatternBoolean = "%1." + Chars.LF;
	If Not ValueIsFilled(CurrentSettings_) Then
		SettingsDescriptionString = NStr("vi = 'Chưa xác định tham số.';
										|ru = 'Не заданы параметры.';
										|en = 'Parameters are not specified.'; fa = 'پارامترها مشخص نشده‌اند.';
										|it = 'I parametri non sono imposatti.';
										|pl = 'Nie są ustawione parametry.';
										|tr = 'Parametreler belirtilmedi.'");
		Return SettingsDescriptionString;
	EndIf;
	
	SettingsDescriptionString = StrTemplate(StringPattern_, 
		NStr("vi = 'Bắt đầu năm tài chính';
			|ru = 'Начало финансового года';
			|en = 'Fiscal year start'; fa = 'شروع سال مالی';
			|it = 'Avvio anno finanziario';
			|pl = 'Początek roku finansowego';
			|tr = 'Mali yılın başlangıcı'"),
		PresentationOfBeginningOfFinancialYear(CurrentSettings_.MonthOfFiscalYearBeginning));
	
	SettingsDescriptionString = SettingsDescriptionString 
		+ StrTemplate(StringPattern_, 
			NStr("vi = 'Phương pháp đánh giá giá trị hàng hóa';
				|ru = 'Метод оценки стоимости товаров';
				|en = 'Inventory valuation method'; fa = 'روش ارزیابی موجودی';
				|it = 'Metodo di valutazione del costo delle merci';
				|pl = 'Metoda oceny kosztów towarów';
				|tr = 'Stok değerleme yöntemi'"),
			CurrentSettings_.InventoryValuationMethod);
	
	If CurrentSettings_.ProductCostingByPlannedCost Then
		SettingsDescriptionString = SettingsDescriptionString
			+ StrTemplate(StringPatternBoolean,
				NStr("vi = 'Thành phẩm được ghi nhận theo giá trị dự tính';
					|ru = 'Готовая продукция учитывается по плановой стоимости';
					|en = 'Finished products are accounted for at standard cost'; fa = 'Finished products are accounted for at standard cost';
					|it = 'Prodotti pronti vengono registrati per costo pianificato';
					|pl = 'Gotowe wiersze pozycji są uwzględniane w planowanej wartości';
					|tr = 'İmal edilen ürünler standart maliyet üzerinden dikkate alınır'"));
	EndIf;
	
	If CurrentSettings_.InventoryValuationMethod = Enums.InventoryValuationMethods.MovingAverage Or All Then
		If CurrentSettings_.ItemizeVariancesByLinesOfBusiness Or All Then
			SettingsDescriptionString = SettingsDescriptionString
				+ StrTemplate(StringPatternBoolean,
					NStr("vi = 'Chênh lệch trong giá trị được tính theo mảng hoạt động';
						|ru = 'Отклонения в стоимости учитываются по направлениям деятельности';
						|en = 'Cost variances are recorded by lines of business'; fa = 'Cost variances are recorded by lines of business';
						|it = 'Cost variances are recorded by lines of business';
						|pl = 'Cost variances are recorded by lines of business';
						|tr = 'Değer farkları, iş koluna göre hesaplanır'"));
		EndIf;
		If CurrentSettings_.ItemizeVariancesByBusinessUnits Or All Then
			SettingsDescriptionString = SettingsDescriptionString
				+ StrTemplate(StringPatternBoolean,
					NStr("vi = 'Chênh lệnh trong giá trị được tính theo bộ phận';
						|ru = 'Отклонения в стоимости учитываются по подразделениям';
						|en = 'Cost variances are recorded by business units'; fa = 'Cost variances are recorded by business units';
						|it = 'Cost variances are recorded by business units';
						|pl = 'Cost variances are recorded by business units';
						|tr = 'Maliyet farkları, departmana göre hesaplanır'"));
		EndIf;
		If CurrentSettings_.ItemizeVariancesByWarehousesStorageLocations Or All Then
			SettingsDescriptionString = SettingsDescriptionString
				+ StrTemplate(StringPatternBoolean,
					NStr("vi = 'Chênh lệnh trong giá trị được tính theo kho bãi/nơi cất giữ';
						|ru = 'Отклонения в стоимости учитываются по складам/местам хранения';
						|en = 'Cost variances are recorded by warehouses/storage locations'; fa = 'Cost variances are recorded by warehouses/storage locations';
						|it = 'Cost variances are recorded by warehouses/storage locations';
						|pl = 'Cost variances are recorded by warehouses/storage locations';
						|tr = 'Maliyet farkları, ambara/saklama yerine göre hesaplanır'"));
		EndIf;
	EndIf;
	
	If CurrentSettings_.ProductCostingByPlannedCost Or All Then
		If CurrentSettings_.WriteOffProductCostVariancesToCostOfGoodsSold Or All Then
			SettingsDescriptionString = SettingsDescriptionString
				+ StrTemplate(StringPatternBoolean,
					NStr("vi = 'Chênh lệch trong giá trị của thành phẩm xuất xưởng được ghi giảm vào giá vốn hàng bán';
						|ru = 'Отклонения в стоимости выпущенной продукции списываются на себестоимость продаж';
						|en = 'Manufactured product cost variances are written off to cost of goods sold'; fa = 'Manufactured product cost variances are written off to cost of goods sold';
						|it = 'Manufactured product cost variances are written off to cost of goods sold';
						|pl = 'Manufactured product cost variances are written off to cost of goods sold';
						|tr = 'Üretilen ürünlerin maliyetindeki farklar, satılan malların maliyetine yazılır'"));
		Else
			SettingsDescriptionString = SettingsDescriptionString
				+ StrTemplate(StringPatternBoolean,
					NStr("vi = 'Chênh lệch trong giá trị của thành phẩm xuất xưởng được tính vào giá trị (đưa giá trị đến mức thực tế)';
						|ru = 'Отклонения в стоимости выпущенной продукции включаются в стоимость (доводя стоимость до фактической)';
						|en = 'Manufactured product cost variances are included in the cost (bringing the cost up to actual cost)'; fa = 'Manufactured product cost variances are included in the cost (bringing the cost up to actual cost)';
						|it = 'Manufactured product cost variances are included in the cost (bringing the cost up to actual cost)';
						|pl = 'Manufactured product cost variances are included in the cost (bringing the cost up to actual cost)';
						|tr = 'Üretilen ürünlerin maliyetindeki değişiklikler maliyete eklenir (maliyetin gerçek maliyete tekabül ettirilmesi)'"));
		EndIf;
	EndIf;
	
	If GetFunctionalOption("AccualInventoryImpairmentProvision") Or All Then
		If CurrentSettings_.ReverseProvisionWhenWritingOffInventoryToExpenses Or All Then
			SettingsDescriptionString = SettingsDescriptionString
				+ StrTemplate(StringPatternBoolean,
					NStr("vi = 'Khi ghi giảm vật tư vào chi phí, khôi phục dự phòng (giảm giá vốn hàng bán)';
						|ru = 'При списании запасов на расходы резервы восстанавливаются (уменьшают себестоимость продаж)';
						|en = 'When writing off inventory to expenses, provisions are reversed (reduce the cost of goods sold)'; fa = 'When writing off inventory to expenses, provisions are reversed (reduce the cost of goods sold)';
						|it = 'При списании запасов на расходы резервы восстанавливаются (уменьшают себестоимость продаж)';
						|pl = 'When writing off inventory to expenses, provisions are reversed (reduce the cost of goods sold)';
						|tr = 'Stoklar kayıttan düşüldüğünde, rezervler yenilenir (satışların maliyetini azaltır)'"));
		Else
			SettingsDescriptionString = SettingsDescriptionString
				+ StrTemplate(StringPatternBoolean,
					NStr("vi = 'Khi ghi giảm vật tư vào chi phí, số tiền chi phí được ghi giảm vào số tiền dự phòng';
						|ru = 'При списании запасов на расходы сумма расходов уменьшается на сумму резерва';
						|en = 'When writing off inventory to expenses, the expense amount is reduced by the provision amount'; fa = 'When writing off inventory to expenses, the expense amount is reduced by the provision amount';
						|it = 'При списании запасов на расходы сумма расходов уменьшается на сумму резерва';
						|pl = 'When writing off inventory to expenses, the expense amount is reduced by the provision amount';
						|tr = 'Stoklar kayıttan düşüldüğünde, gider tutarı rezervler tutarı kadar azalır'"));
		EndIf;
	EndIf;
	
	If CurrentSettings_.AllocateVariancesInPreviousPeriods Then
		SettingsDescriptionString = SettingsDescriptionString
			+ StrTemplate(StringPatternBoolean,
				NStr("ru = 'Расходы и отклонения распределяются на выбытия товаров в прошлых периодах по всей цепочке движения затрат';
					|vi = 'Expenses and variances are allocated to the disposal of goods in previous periods along the entire cost chain';
					|en = 'Expenses and variances are allocated to the disposal of goods in previous periods along the entire cost chain'; fa = 'Expenses and variances are allocated to the disposal of goods in previous periods along the entire cost chain';
					|it = 'Expenses and variances are allocated to the disposal of goods in previous periods along the entire cost chain';
					|pl = 'Expenses and variances are allocated to the disposal of goods in previous periods along the entire cost chain';
					|tr = 'Giderler ve farklar, maliyet hareketinin tüm zinciri boyunca geçmiş dönemlerdeki mal çıkışlarına dağıtılır'"));
	Else
		SettingsDescriptionString = SettingsDescriptionString
			+ StrTemplate(StringPatternBoolean,
				NStr("ru = 'Расходы и отклонения распределяются на выбытия товаров в прошлых периодах упрощенно: только на продажи, прочие расходы и остатки';
					|vi = 'Expenses and variances are allocated to the disposal of goods in previous periods in a simplified way: only to sales, other expenses, and balances';
					|en = 'Expenses and variances are allocated to the disposal of goods in previous periods in a simplified way: only to sales, other expenses, and balances'; fa = 'Expenses and variances are allocated to the disposal of goods in previous periods in a simplified way: only to sales, other expenses, and balances';
					|it = 'Expenses and variances are allocated to the disposal of goods in previous periods in a simplified way: only to sales, other expenses, and balances';
					|pl = 'Expenses and variances are allocated to the disposal of goods in previous periods in a simplified way: only to sales, other expenses, and balances';
					|tr = 'Giderler ve farklar, geçmiş dönemlerdeki mal çıkışlarına basitleştirilmiş şekilde dağıtılır: yalnızca satışlara, diğer giderlere ve bakiyelere.'"));
	EndIf;
	
	If CurrentSettings_.DivisionIntoShortTermLongTermAssetsAndLiabilities Or All Then
		
		SettingsDescriptionString = SettingsDescriptionString
			+ StrTemplate(StringPatternBoolean,
				NStr("vi = 'Sử dụng phân chia tài sản/nợ dài hạn';
					|ru = 'Используется выделение долгосрочных активов/обязательств';
					|en = 'Allocation of long-term assets/liabilities is used'; fa = 'Allocation of long-term assets/liabilities is used';
					|it = 'Viene utilizzata l''allocazione di attivi/passivi di lungo termine';
					|pl = 'Jest używane odróżnienie aktywów/zobowiązań długoterminowych';
					|tr = 'Duran varlıkların/yükümlülüklerin seçimi kullanılır'"));
		
		SettingsDescriptionString = SettingsDescriptionString
			+ StrTemplate(StringPattern_,
				NStr("vi = 'Thời lượng của chu kỳ hoạt động theo tháng';
					|ru = 'Длительность операционного цикла в месяцах';
					|en = 'Operating cycle duration in months'; fa = 'Operating cycle duration in months';
					|it = 'Lunghezza del ciclo operativo in mesi';
					|pl = 'Czas trwania cyklu operacyjnego w miesiącach';
					|tr = 'Ay cinsinden işletme döngüsü uzunluğu'"),
				CurrentSettings_.DurationOfCompanyOperatingCycle);

	EndIf;
	
	If GetFunctionalOption("UseNonCurrentAssets2_4") Then
		
		LocalFAAccounting = GetFunctionalOption("LocalFAAccounting");
				
		If LocalFAAccounting Or All Then
			
			If CurrentSettings_.AccountingPolicyForFixedAssets = Enums.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards Then
				SettingsDescriptionString = SettingsDescriptionString
					+ StrTemplate(StringPatternBoolean,
						NStr("vi = 'Kế toán tài sản cố định hữu hình và vô hình trong kế toán quản trị được thực hiện theo chuẩn mực kế toán quốc tế';
							|ru = 'Учет ОС и НМА в управленческом учете ведется по стандартам международного учета';
							|en = 'Fixed and intangible assets are accounted in management accounting as per financial accounting standards'; fa = 'Fixed and intangible assets are accounted in management accounting as per financial accounting standards';
							|it = 'La contabilizzazione di Capitali fissi e Beni immateriali in contabilità gestionale viene effettuata secondo gli standard contabili internazionali';
							|pl = 'Ewidencja środków trwałych i aktywów niematerialnych w ewidencji zarządczej jest prowadzona według standardów ewidencji międzynarodowej';
							|tr = 'Yönetim muhasebesinde Maddi Duran Varlıklar ve Sabit Kıymetler uluslararası muhasebe standartlarına uygun olarak muhasebeleştirilir'"));
			Else
				SettingsDescriptionString = SettingsDescriptionString
					+ StrTemplate(StringPatternBoolean,
						NStr("vi = 'Kế toán tài sản cố định hữu hình và vô hình trong kế toán quản trị được thực hiện theo chuẩn mực số 3 và số 4';
							|ru = 'Учет ОС и НМА в управленческом учете ведется по ПБУ 6/01 и 14/2007';
							|en = 'Fixed and intangible assets are accounted in management accounting as per PBU 6/01 and 14/2017'; fa = 'Fixed and intangible assets are accounted in management accounting as per PBU 6/01 and 14/2017';
							|it = 'La contabilizzazione di Capitali fissi e Beni immateriali in contabilità gestionale viene effettuata secondo il Regolamento per la gestione contabile 6/01 e 14/2007';
							|pl = 'Ewidencja środków trwałych i aktywów niematerialnych w ewidencji zarządczej jest prowadzona według regulaminu ewidencji księgowej 6/01 i 14/2007';
							|tr = 'Yönetim muhasebesinde Maddi Duran Varlıklar ve Sabit Kıymetler, MUY 6/01 ve 14/2007''ye uygun olarak muhasebeleştirilir'"));
			EndIf;
			
		EndIf;
		
		If CurrentSettings_.ProcedureOfFixedAssetDepreciationCharge = Enums.DepreciationProcedure.StartingNextMonth
			And CurrentSettings_.ProcedureOfIntangibleAssetAmortizationCharge = Enums.DepreciationProcedure.StartingNextMonth
			And CurrentSettings_.LeasedAssetDepreciationChargeProcedureManag = Enums.DepreciationProcedure.StartingNextMonth Or All Then
			
			SettingsDescriptionString = SettingsDescriptionString
				+ StrTemplate(StringPatternBoolean,
					NStr("vi = 'Khấu hao TSCĐHH và TSCĐVH trong kế toán quản trị được tính từ ngày đầu tháng kế tiếp tháng tiếp nhận vào kế toán';
						|ru = 'Амортизация ОС и НМА в управленческом учете начисляется с первого числа месяца, следующего за месяцем принятия к учету';
						|en = 'Fixed asset depreciation and intangible asset amortization in management accounting is charged from the first day of the month following the month of recognition'; fa = 'Fixed asset depreciation and intangible asset amortization in management accounting is charged from the first day of the month following the month of recognition';
						|it = 'L''ammortamento di immobilizzazioni e beni immateriali in contabilità gestionale viene calcolato dal primo giorno del mese seguente al mese di ricezione in contabilità';
						|pl = 'Amortyzacja środków trwałych i aktywów niematerialnych w ewidencji zarządczej jest naliczana od pierwszego dnia miesiąca, następnego po miesiącu przyjęcia do ewidencji';
						|tr = 'Yönetim muhasebesinde Maddi olmayan Duran Varlıkların ve Sabit Kıymetlerin amortismanı, muhasebeleştirmeye kabul edildiği ayı takip eden ayın ilk gününden itibaren tahakkuk edilir'"));
			
		ElsIf CurrentSettings_.ProcedureOfFixedAssetDepreciationCharge = Enums.DepreciationProcedure.FromDateOfRecognitionInAccounting
			And CurrentSettings_.ProcedureOfIntangibleAssetAmortizationCharge = Enums.DepreciationProcedure.FromDateOfRecognitionInAccounting
			And CurrentSettings_.LeasedAssetDepreciationChargeProcedureManag = Enums.DepreciationProcedure.FromDateOfRecognitionInAccounting Then
			
			SettingsDescriptionString = SettingsDescriptionString
				+ StrTemplate(StringPatternBoolean,
					NStr("vi = 'Khấu hao TSCĐHH và TSCĐVH trong kế toán quản trị được tính từ ngày tiếp nhận vào kế toán';
						|ru = 'Амортизация ОС и НМА в управленческом учете начисляется с даты принятия к учету';
						|en = 'Fixed asset depreciation and intangible asset amortization in management accounting is charged from the date of recognition'; fa = 'Fixed asset depreciation and intangible asset amortization in management accounting is charged from the date of recognition';
						|it = 'L''ammortamento di Immobilizzazioni e Beni immateriali viene calcolato dalla data di registrazione in contabilità';
						|pl = 'Amortyzacja środków trwałych i aktywów niematerialnych w ewidencji zarządczej jest naliczana od dnia przyjęcia do ewidencji';
						|tr = 'Yönetim muhasebesinde Maddi olmayan Duran Varlıkların ve Sabit Kıymetlerin amortismanı, muhasebeleştirme için kabul edildiği tarihten itibaren tahakkuk edilir'"));
					
		Else
			
			If CurrentSettings_.ProcedureOfFixedAssetDepreciationCharge = Enums.DepreciationProcedure.StartingNextMonth Then
			
				SettingsDescriptionString = SettingsDescriptionString
					+ StrTemplate(StringPatternBoolean,
						NStr("vi = 'Khấu hao TSCĐ sở hữu riêng trong kế toán quản trị được tính từ ngày đầu tháng kế tiếp tháng tiếp nhận vào kế toán';
							|ru = 'Амортизация собственных ОС в управленческом учете начисляется с первого числа месяца, следующего за месяцем принятия к учету';
							|en = 'Own fixed asset depreciation in management accounting is charged from the first day of the month following the month of recognition'; fa = 'Own fixed asset depreciation in management accounting is charged from the first day of the month following the month of recognition';
							|it = 'L''ammortamento delle immobilizzazioni proprie in contabilità gestionale viene calcolato dal primo giorno del mese seguente alla ricezione in contabilità';
							|pl = 'Amortyzacja własnych środków trwałych i w ewidencji zarządczej jest naliczana od pierwszego dnia miesiąca, następnego po miesiącu przyjęcia do ewidencji';
							|tr = 'Yönetim muhasebesinde Sabit kıymetlerin amortismanı, muhasebeleştirmeye kabul edildiği ayı takip eden ayın ilk gününden itibaren tahakkuk edilir'"));
			Else
				
				SettingsDescriptionString = SettingsDescriptionString
					+ StrTemplate(StringPatternBoolean,
						NStr("vi = 'Khấu hao TSCĐ sở hữu riêng trong kế toán quản trị được tính từ ngày tiếp nhận vào kế toán';
							|ru = 'Амортизация собственных ОС в управленческом учете начисляется с даты принятия к учету';
							|en = 'Own fixed asset depreciation in management accounting is charged from the date of recognition'; fa = 'Own fixed asset depreciation in management accounting is charged from the date of recognition';
							|it = 'L''ammortamento delle immobilizzazioni proprie viene calcolato dalla data di registrazione in contabilità';
							|pl = 'Amortyzacja własnych środków trwałych i w ewidencji zarządczej jest naliczana od dnia przyjęcia do ewidencji';
							|tr = 'Yönetim muhasebesinde Sabit kıymetlerin amortismanı, muhasebeleştirme için kabul tarihinden itibaren tahakkuk edilir'"));
						
			EndIf;
					
			If CurrentSettings_.LeasedAssetDepreciationChargeProcedureManag = Enums.DepreciationProcedure.StartingNextMonth Then
			
				SettingsDescriptionString = SettingsDescriptionString
					+ StrTemplate(StringPatternBoolean,
						NStr("vi = 'Khấu hao TSCĐ sở hữu riêng trong kế toán quản trị được tính từ ngày đầu tháng kế tiếp tháng tiếp nhận vào kế toán';
							|ru = 'Амортизация арендованных ОС в управленческом учете начисляется с первого числа месяца, следующего за месяцем принятия к учету';
							|en = 'Leased fixed asset depreciation in management accounting is charged from the first day of the month following the month of recognition'; fa = 'Leased fixed asset depreciation in management accounting is charged from the first day of the month following the month of recognition';
							|it = 'L''ammortamento delle immobilizzazioni affittate in contabilità gestionale viene calcolato dal primo giorno del mese seguente alla ricezione in contabilità';
							|pl = 'Amortyzacja własnych środków trwałych i w ewidencji zarządczej jest naliczana od pierwszego dnia miesiąca, następnego po miesiącu przyjęcia do ewidencji';
							|tr = 'Yönetim muhasebesinde kiralanan Sabit kıymetlerin amortismanı, muhasebeleştirmeye kabul edildiği ayı takip eden ayın ilk gününden itibaren tahakkuk edilir'"));
			Else
				
				SettingsDescriptionString = SettingsDescriptionString
					+ StrTemplate(StringPatternBoolean,
						NStr("vi = 'Khấu hao TSCĐ đã thuê trong kế toán quản trị được tính từ ngày tiếp nhận vào kế toán';
							|ru = 'Амортизация арендованных ОС в управленческом учете начисляется с даты принятия к учету';
							|en = 'Leased fixed asset depreciation in management accounting is charged from the date of recognition'; fa = 'Leased fixed asset depreciation in management accounting is charged from the date of recognition';
							|it = 'L''ammortamento delle immobilizzazioni affittate viene calcolato dalla data di registrazione in contabilità';
							|pl = 'Amortyzacja wydzierżawionych środków trwałych i w ewidencji zarządczej jest naliczana od dnia przyjęcia do ewidencji';
							|tr = 'Yönetim muhasebesinde kiralanan Sabit kıymetlerin amortismanı, muhasebeleştirme için kabul edildiği tarihten itibaren tahakkuk edilir'"));
						
			EndIf;
					
			If CurrentSettings_.ProcedureOfIntangibleAssetAmortizationCharge = Enums.DepreciationProcedure.StartingNextMonth Then
			
				SettingsDescriptionString = SettingsDescriptionString
					+ StrTemplate(StringPatternBoolean,
						NStr("vi = 'Khấu hao TSCĐVH trong kế toán quản trị được tính từ ngày đầu tháng kế tiếp tháng tiếp nhận vào kế toán';
							|ru = 'Амортизация НМА в управленческом учете начисляется с первого числа месяца, следующего за месяцем принятия к учету';
							|en = 'Intangible asset amortization in management accounting is charged from the first day of the month following the month of recognition'; fa = 'Intangible asset amortization in management accounting is charged from the first day of the month following the month of recognition';
							|it = 'L''ammortamento dei beni immateriali in contabilità gestionale viene calcolato dal primo giorno del mese seguente alla ricezione in contabilità';
							|pl = 'Amortyzacja aktywów niematerialnych w ewidencji zarządczej jest naliczana od pierwszego dnia miesiąca, następnego po miesiącu przyjęcia do ewidencji';
							|tr = 'Yönetim muhasebesinde Maddi olmayan Duran Varlıkların amortismanı, muhasebeye kabul edildiği ayı takip eden ayın ilk gününden itibaren tahakkuk edilir'"));
			Else
				
				SettingsDescriptionString = SettingsDescriptionString
					+ StrTemplate(StringPatternBoolean,
						NStr("vi = 'Khấu hao TSCĐVH trong kế toán quản trị được tính từ ngày tiếp nhận vào kế toán';
							|ru = 'Амортизация НМА в управленческом учете начисляется с даты принятия к учету';
							|en = 'Intangible asset amortization in management accounting is charged from the date of recognition'; fa = 'Intangible asset amortization in management accounting is charged from the date of recognition';
							|it = 'L''ammortamento di beni immateriali viene calcolato dalla data di registrazione in contabilità';
							|pl = 'Amortyzacja aktywów niematerialnych w ewidencji zarządczej jest naliczana od dnia przyjęcia do ewidencji';
							|tr = 'Yönetim muhasebesinde Maddi olmayan Duran Varlıkların amortismanı, muhasebe için kabul edildiği tarihten itibaren tahakkuk edilir'"));
						
			EndIf;
					
		EndIf;
		
		If Not LocalFAAccounting Or All Then
			
			If CurrentSettings_.FixedAssetAccountingProcedureInLocalAccounting = Enums.FixedAssetAccountingProcedureInLocalAccounting.Independent Or All Then
			
				SettingsDescriptionString = SettingsDescriptionString
					+ StrTemplate(StringPatternBoolean,
						NStr("vi = 'Kế toán TSCĐHH và TSCĐVH trong kế toán tài chính được tiến hành mà không phụ thuộc vào kế toán quản trị';
							|ru = 'Учет ОС и НМА в регламентированном учете ведется независимо от управленческого учета';
							|en = 'Accounting for fixed assets and intangible assets in local accounting is carried out independently from management accounting'; fa = 'Accounting for fixed assets and intangible assets in local accounting is carried out independently from management accounting';
							|it = 'La contabilità di immobilizzazioni e beni immateriali in contabilità regolatoria viene eseguita indipendentemente dalla contabilità gestionale';
							|pl = 'Ewidencja środków trwałych i aktywów niematerialnych w ewidencji reglamentowanej jest prowadzona niezależnie od ewidencji zarządczej';
							|tr = 'Sabit Kıymetler ve Maddi olmayan Duran Varlıklar yerel muhasebede yönetim muhasebesinden bağımsız olarak muhasebeleştirilir'"));
						
				If CurrentSettings_.ProcedureOfFixedAssetDepreciationChargeLocal = Enums.DepreciationProcedure.StartingNextMonth
					And CurrentSettings_.ProcedureOfIntangibleAssetAmortizationChargeLocal = Enums.DepreciationProcedure.StartingNextMonth
					And CurrentSettings_.LeasedFixedAssetDepreciationChargeProcedureLocal = Enums.DepreciationProcedure.StartingNextMonth Or All Then
					
					SettingsDescriptionString = SettingsDescriptionString
						+ StrTemplate(StringPatternBoolean,
							NStr("vi = 'Khấu hao TSCĐHH và TSCĐVH trong kế toán tài chính được tính từ ngày đầu tháng kế tiếp tháng tiếp nhận vào kế toán';
								|ru = 'Амортизация ОС и НМА в регламентированном учете начисляется с первого числа месяца, следующего за месяцем принятия к учету';
								|en = 'Fixed asset depreciation and intangible asset amortization in local accounting is charged from the first day of the month following the month of recognition'; fa = 'Fixed asset depreciation and intangible asset amortization in local accounting is charged from the first day of the month following the month of recognition';
								|it = 'L''ammortamento di immobilizzazioni e beni immateriali in contabilità regolatoria viene calcolato dal primo giorno del mese seguente al mese di ricezione in contabilità';
								|pl = 'Amortyzacja środków trwałych i aktywów niematerialnych w ewidencji reglamentowanej jest naliczana od pierwszego dnia miesiąca, następnego po miesiącu przyjęcia do ewidencji';
								|tr = 'Yerel muhasebede Maddi olmayan Duran Varlıkların ve Sabit kıymetlerin amortismanı muhasebeye kabul edildiği ayı takip eden ayın ilk gününden itibaren tahakkuk edilir'"));
					
				ElsIf CurrentSettings_.ProcedureOfFixedAssetDepreciationChargeLocal = Enums.DepreciationProcedure.FromDateOfRecognitionInAccounting
					And CurrentSettings_.ProcedureOfIntangibleAssetAmortizationChargeLocal = Enums.DepreciationProcedure.FromDateOfRecognitionInAccounting
					And CurrentSettings_.LeasedFixedAssetDepreciationChargeProcedureLocal = Enums.DepreciationProcedure.FromDateOfRecognitionInAccounting Then
					
					SettingsDescriptionString = SettingsDescriptionString
						+ StrTemplate(StringPatternBoolean,
							NStr("vi = 'Khấu hao TSCĐHH và TSCĐVH trong kế toán tài chính được tính từ ngày tiếp nhận vào kế toán';
								|ru = 'Амортизация ОС и НМА в регламентированном учете начисляется с даты принятия к учету';
								|en = 'Fixed asset depreciation and intangible asset amortization in local accounting is charged from the date of recognition'; fa = 'Fixed asset depreciation and intangible asset amortization in local accounting is charged from the date of recognition';
								|it = 'L''ammortamento di Immobilizzazioni e Beni immateriali in contabilità regolatoria viene calcolato dalla data di registrazione in contabilità';
								|pl = 'Amortyzacja środków trwałych i aktywów niematerialnych w ewidencji reglamentowanej jest naliczana od dnia przyjęcia do ewidencji';
								|tr = 'Yerel muhasebede Sabit kıymetlerin ve Maddi olmayan Duran Varlıkların amortismanı muhasebeye kabul tarihinden itibaren tahakkuk edilir'"));
							
				Else
					
					If CurrentSettings_.ProcedureOfFixedAssetDepreciationChargeLocal = Enums.DepreciationProcedure.StartingNextMonth Then
					
						SettingsDescriptionString = SettingsDescriptionString
							+ StrTemplate(StringPatternBoolean,
								NStr("vi = 'Khấu hao TSCĐ sở hữu riêng trong kế toán tài chính được tính từ ngày đầu tháng kế tiếp tháng tiếp nhận vào kế toán';
									|ru = 'Амортизация собственных ОС в регламентированном учете начисляется с первого числа месяца, следующего за месяцем принятия к учету';
									|en = 'Own fixed asset depreciation in local accounting is charged from the first day of the month following the month of recognition'; fa = 'Own fixed asset depreciation in local accounting is charged from the first day of the month following the month of recognition';
									|it = 'L''ammortamento delle immobilizzazioni proprie in contabilità regolatoria viene calcolato dal primo giorno del mese seguente alla ricezione in contabilità';
									|pl = 'Amortyzacja własnych środków trwałych i w ewidencji reglamentowanej jest naliczana od pierwszego dnia miesiąca, następnego po miesiącu przyjęcia do ewidencji';
									|tr = 'Yerel muhasebede Sabit kıymetlerin amortismanı, muhasebeye kabul edildiği ayı takip eden ayın ilk gününden itibaren tahakkuk edilir'"));
					Else
						
						SettingsDescriptionString = SettingsDescriptionString
							+ StrTemplate(StringPatternBoolean,
								NStr("vi = 'Khấu hao TSCĐ sở hữu riêng trong kế toán tài chính được tính từ ngày tiếp nhận vào kế toán';
									|ru = 'Амортизация собственных ОС в регламентированном учете начисляется с даты принятия к учету';
									|en = 'Own fixed asset depreciation in local accounting is charged from the date of recognition'; fa = 'Own fixed asset depreciation in local accounting is charged from the date of recognition';
									|it = 'L''ammortamento delle immobilizzazioni proprie in contabilità regolatoria viene calcolato dalla data di registrazione in contabilità';
									|pl = 'Amortyzacja własnych środków trwałych i w ewidencji reglamentowanej jest naliczana od dnia przyjęcia do ewidencji';
									|tr = 'Yerel muhasebede Sabit kıymetlerin amortismanı, muhasebeye kabul edildikleri tarihten itibaren tahakkuk edilir'"));
								
					EndIf;
							
					If CurrentSettings_.LeasedFixedAssetDepreciationChargeProcedureLocal = Enums.DepreciationProcedure.StartingNextMonth Then
					
						SettingsDescriptionString = SettingsDescriptionString
							+ StrTemplate(StringPatternBoolean,
								NStr("vi = 'Khấu hao TSCĐ đã thuê trong kế toán tài chính được tính từ ngày đầu tháng kế tiếp tháng tiếp nhận vào kế toán';
									|ru = 'Амортизация арендованных ОС в регламентированном учете начисляется с первого числа месяца, следующего за месяцем принятия к учету';
									|en = 'Leased fixed asset depreciation in local accounting is charged from the first day of the month following the month of recognition'; fa = 'Leased fixed asset depreciation in local accounting is charged from the first day of the month following the month of recognition';
									|it = 'L''ammortamento delle immobilizzazioni affittate in contabilità regolatoria viene calcolato dal primo giorno del mese seguente alla ricezione in contabilità';
									|pl = 'Amortyzacja wydzierżawionych środków trwałych i w ewidencji reglamentowanej jest naliczana od pierwszego dnia miesiąca, następnego po miesiącu przyjęcia do ewidencji';
									|tr = 'Yerel muhasebede kiralanan Sabit kıymetlerin amortismanı, muhasebeye kabul edildiği ayı takip eden ayın ilk gününden itibaren tahakkuk edilir'"));
					Else
						
						SettingsDescriptionString = SettingsDescriptionString
							+ StrTemplate(StringPatternBoolean,
								NStr("vi = 'Khấu hao TSCĐ đã thuê trong kế toán tài chính được tính từ ngày tiếp nhận vào kế toán';
									|ru = 'Амортизация арендованных ОС в регламентированном учете начисляется с даты принятия к учету';
									|en = 'Leased fixed asset depreciation in local accounting is charged from the date of recognition'; fa = 'Leased fixed asset depreciation in local accounting is charged from the date of recognition';
									|it = 'L''ammortamento delle immobilizzazioni affittate in contabilità regolatoria viene calcolato dalla data di registrazione in contabilità';
									|pl = 'Amortyzacja wydzierżawionych środków trwałych i w ewidencji reglamentowanej jest naliczana od dnia przyjęcia do ewidencji';
									|tr = 'Yerel muhasebede kiralanan Sabit kıymetlerin amortismanı, muhasebeye kabul edildikleri tarihten itibaren tahakkuk edilir'"));
								
					EndIf;
							
					If CurrentSettings_.ProcedureOfIntangibleAssetAmortizationChargeLocal = Enums.DepreciationProcedure.StartingNextMonth Then
					
						SettingsDescriptionString = SettingsDescriptionString
							+ StrTemplate(StringPatternBoolean,
								NStr("vi = 'Khấu hao TSCĐVH trong kế toán pháp quy được tính từ ngày đầu tháng kế tiếp tháng tiếp nhận vào kế toán';
									|ru = 'Амортизация НМА в регламентированном учете начисляется с первого числа месяца, следующего за месяцем принятия к учету';
									|en = 'Intangible asset amortization in local accounting is charged from the first day of the month following the month of recognition'; fa = 'Intangible asset amortization in local accounting is charged from the first day of the month following the month of recognition';
									|it = 'L''ammortamento dei beni immateriali in contabilità regolatoria viene calcolato dal primo giorno del mese seguente alla ricezione in contabilità';
									|pl = 'Amortyzacja aktywów niematerialnych w ewidencji reglamentowanej jest naliczana od pierwszego dnia miesiąca, następnego po miesiącu przyjęcia do ewidencji';
									|tr = 'Yerel muhasebede Maddi Duran olmayan Varlıkların amortismanı, muhasebeye kabul edildiği ayı takip eden ayın ilk gününden itibaren tahakkuk edilir'"));
					Else
						
						SettingsDescriptionString = SettingsDescriptionString
							+ StrTemplate(StringPatternBoolean,
								NStr("vi = 'Khấu hao TSCĐVH trong kế toán tài chính được tính từ ngày tiếp nhận vào kế toán';
									|ru = 'Амортизация НМА в регламентированном учете начисляется с даты принятия к учету';
									|en = 'Intangible asset amortization in local accounting is charged from the date of recognition'; fa = 'Intangible asset amortization in local accounting is charged from the date of recognition';
									|it = 'L''ammortamento di beni immateriali viene calcolato in contabilità regolatoria dalla data di registrazione in contabilità';
									|pl = 'Amortyzacja aktywów niematerialnych w ewidencji reglamentowanej jest naliczana od dnia przyjęcia do ewidencji';
									|tr = 'Yerel muhasebede Maddi Duran olmayan Varlıkların amortismanı, muhasebe için kabul edildiği tarihten itibaren tahakkuk edilir'"));
								
					EndIf;
							
				EndIf;
				
			Else
				
				SettingsDescriptionString = SettingsDescriptionString
					+ StrTemplate(StringPatternBoolean,
						NStr("vi = 'Kế toán TSCĐHH và TSCĐVH trong kế toán tài chính trùng với kế toán quản trị';
							|ru = 'Учет ОС и НМА в регламентированном учете совпадает с управленческим учетом';
							|en = 'Accounting of fixed assets and intangible assets in local accounting matches the management accounting'; fa = 'Accounting of fixed assets and intangible assets in local accounting matches the management accounting';
							|it = 'La contabilità di immobilizzazioni e beni immateriali in contabilità regolatoria corrisponde alla contabilità gestionale';
							|pl = 'Ewidencja środków trwałych i aktywów niematerialnych w ewidencji reglamentowanej jest zgodna z ewidencją zarządczą';
							|tr = 'Yerel muhasebede Sabit kıymetlerin ve Maddi olmayan Duran Varlıkların muhasebeleştirilmesi yönetim muhasebesi ile eşleşiyor'"));
						
			EndIf;
			
		EndIf;
		
		If GetFunctionalOption("UseFixedAssetImpairment") Then
			If CurrentSettings_.PostingOptionForImpairedFADepreciation
				= Enums.PostingOptionsForImpairedFADepreciation.AddImpairmentAdjustment Or All Then
				SettingsDescriptionString = SettingsDescriptionString + StrTemplate(StringPatternBoolean, NStr(
					"vi = 'Khấu hao TSCĐHH và TSCĐVH có giảm giá trị được tính trên giá trị có giảm giá. Điều chỉnh giảm giá được tính thêm';
					|ru = 'Амортизация ОС и НМА с обесценением начисляется на стоимость с учетом обесценения. Корректировка обесценения доначисляется';
					|en = 'Fixed and intangible assets depreciation with impairment is accumulated to the cost including impairment. The impairment adjustment is accrued additionally'; fa = 'Fixed and intangible assets depreciation with impairment is accumulated to the cost including impairment. The impairment adjustment is accrued additionally';
					|it = 'L''ammortamento di immobilizzazioni e beni immateriali con svalutazione viene calcolato sul costo considerando la svalutazione. L''aggiustamento di svalutazione viene aggiunto';
					|pl = 'Amortyzacja środków trwałych i aktywów niematerialnych z utratą wartości jest naliczana na wartość z uwzględnieniem utraty wartości. Korekta utraty wartości jest doliczana dodatkowo';
					|tr = 'Sabit kıymetler ve değer düşüklüğüne uğrayan Maddi Duran olmayan Varlıkların amortismanı, değer düşüklüğü dikkate alınarak maliyet bedeli üzerinden muhasebeleştirilir. Değer düşüklüğü düzeltmesi ekten tahakkuk edilir'"));
			Else
				SettingsDescriptionString = SettingsDescriptionString + StrTemplate(StringPatternBoolean, NStr(
					"vi = 'Khấu hao TSCĐHH và TSCĐVH có giảm giá trị được tính trên tổng giá trị. Điều chỉnh giảm giá đảo ngược';
					|ru = 'Амортизация ОС и НМА с обесценением начисляется на полную стоимость. Корректировка обесценения сторнируется';
					|en = 'Fixed and intangible assets depreciation with impairment is accumulated to the full cost. The impairment adjustment is reversed'; fa = 'Fixed and intangible assets depreciation with impairment is accumulated to the full cost. The impairment adjustment is reversed';
					|it = 'L''ammortamento di immobilizzazioni e beni immateriali con svalutazione viene calcolato sul costo complessivo. L''aggiustamento di svalutazione viene stornato';
					|pl = 'Amortyzacja środków trwałych i aktywów niematerialnych z utratą wartości jest naliczana na pełną wartość. Korekta utraty wartości jest stornowana';
					|tr = 'Sabit kıymetlerin amortismanı ve değer düşüklüğüne uğrayan Maddi olmayan Duran Varlıkların amortismanı maliyete yansıtılmaktadır. Değer düşüklüğü düzeltmesi tersine çevrilir'"));
			EndIf;
		EndIf;
		
		If CurrentSettings_.RecognizeResearchExpensesInCurrentPeriod Or All Then
			
			SettingsDescriptionString = SettingsDescriptionString
				+ StrTemplate(StringPatternBoolean,
					NStr("vi = 'Chi phí nghiên cứu được tính trong kỳ hiện tại';
						|ru = 'Расходы по исследованиям учитываются в текущем периоде';
						|en = 'Research expenses are recognized in the current period'; fa = 'Research expenses are recognized in the current period';
						|it = 'Spese di ricerche vengono registrate nel periodo corrente';
						|pl = 'Rozchody wg badań są uwzględniane w bieżącym okresie';
						|tr = 'Araştırma giderleri cari dönemde muhasebeleştirilir'"));
			
			SettingsDescriptionString = SettingsDescriptionString
				+ StrTemplate(StringPattern_,
					NStr("vi = 'Dạng chi phí nghiên cứu';
						|ru = 'Статья расходов по исследованиям';
						|en = 'Research expense item'; fa = 'Research expense item';
						|it = 'Voce di spese per ricerche';
						|pl = 'Rodzaj kosztu wg badań';
						|tr = 'Araştırma gider kalemi'"),
					CurrentSettings_.ExpenseItemForRD);
			
	
			SettingsDescriptionString = SettingsDescriptionString
				+ StrTemplate(StringPattern_,
					NStr("vi = 'Đối tượng phân tích chi phí theo nghiên cứu';
						|ru = 'Аналитика расходов по исследованиям';
						|en = 'Research expense dimension'; fa = 'Research expense dimension';
						|it = 'Analitica delle spese per ricerche';
						|pl = 'Analityka rozchodów wg badań';
						|tr = 'Araştırma giderleri boyutu'"),
					CurrentSettings_.ExpensesDimensionResearchExpenses);
	
		EndIf;
		
	EndIf;
	
	If CurrentSettings_.AccountingForDiscountedAccountsPayableToVendors 
		And GetFunctionalOption("NewOnlineARAPAccounting") Or All Then
			
			SettingsDescriptionString = SettingsDescriptionString
				+ StrTemplate(StringPatternBoolean,
					NStr("vi = 'Quản lý ghi nhận công nợ phải trả nhà cung cấp đã chiết khấu';
						|ru = 'Ведется учет дисконтированной кредиторской задолженности поставщикам';
						|en = 'Accounting for discounted accounts payable to vendors is kept'; fa = 'Accounting for discounted accounts payable to vendors is kept';
						|it = 'Viene tenuta la contabilità del debito scontato verso i fornitori';
						|pl = 'Jest prowadzona ewidencja dyskontowanego zobowiązania dostawcom';
						|tr = 'Tedarikçilere iskonto edilmiş borçlar muhasebeleştiriliyor'"));
			
			SettingsDescriptionString = SettingsDescriptionString
				+ StrTemplate(StringPattern_,
					NStr("vi = 'Dạng ghi giảm chi phí tính chiết khấu theo phần trăm';
						|ru = 'Статья списания процентных расходов дисконтирования';
						|en = 'Write-off item of discounting interest expenses'; fa = 'Write-off item of discounting interest expenses';
						|it = 'Voci di storno delle spese di interessi di sconto';
						|pl = 'Pozycja rozchodów kosztów odsetkowych dyskontowania';
						|tr = 'Gider yazma kalemi, iskonto faiz gideri'"),
					CurrentSettings_.InterestExpenseWriteOffItem);
			
 			
			SettingsDescriptionString = SettingsDescriptionString
				+ StrTemplate(StringPattern_,
					NStr("vi = 'Đối tượng phân tích ghi giảm chi phí tính chiết khấu theo phần trăm';
						|ru = 'Аналитика списания процентных расходов дисконтирования';
						|en = 'Write-off dimension of discounting interest expenses'; fa = 'Write-off dimension of discounting interest expenses';
						|it = 'Analisi dei dati di storno delle spese di interessi di sconto';
						|pl = 'Analityka rozchodów kosztów odsetkowych dyskontowania';
						|tr = 'Faiz giderlerinin gider yazılmasına ilişkin boyut'"),
					CurrentSettings_.WriteOffsDimensionOfInterestExpense);
			
	EndIf;
	
	If CurrentSettings_.ToGenerateLossAllowance Or All Then
		
		SettingsDescriptionString = SettingsDescriptionString
			+ StrTemplate(StringPatternBoolean,
				NStr("vi = 'Tạo dự phòng nợ xấu';
					|ru = 'Формируются резервы по сомнительным долгам';
					|en = 'Loss allowance is generated'; fa = 'Loss allowance is generated';
					|it = 'Формируются резервы по сомнительным долгам';
					|pl = 'Loss allowance is generated';
					|tr = 'Şüpheli borç karşılığı oluşturuluyor'"));
		
		SettingsDescriptionString = SettingsDescriptionString
			+ StrTemplate(StringPattern_,
				NStr("vi = 'Định kỳ dự phòng nợ xấu';
					|ru = 'Периодичность резервов по сомнительным долгам';
					|en = 'Frequency of loss allowance'; fa = 'تناوب ذخیره زیان';
					|it = 'Periodicità delle riserve per crediti di dubbia esigibilità';
					|pl = 'Częstotliwość rezerwy według wątpliwych zobowiązań';
					|tr = 'Şüpheli borç karşılıklarının sıklığı'"),
				CurrentSettings_.FrequencyOfLossAllowance);
		
	EndIf;
	If CurrentSettings_.ProducesExcisableGoods Or All Then
		
		SettingsDescriptionString = SettingsDescriptionString
			+ StrTemplate(StringPatternBoolean,
				NStr("vi = 'Sản xuất hàng hóa chịu thuế TTĐB (tính và phản ánh thuế TTĐB khi bán hàng)';
					|ru = 'Производит подакцизный товар (начисление и отражение акциза при продаже)';
					|en = 'Produces excisable goods (excise accrual and recording upon sale)'; fa = 'Produces excisable goods (excise accrual and recording upon sale)';
					|it = 'Produces excisable goods (excise accrual and recording upon sale)';
					|pl = 'Produces excisable goods (excise accrual and recording upon sale)';
					|tr = 'Tüketim vergisine tabi ürün üretir (satış sırasında tüketim vergisinin tahakkuku ve yansıması)'"));
	EndIf;
	
	If CurrentSettings_.ImportsExcisableGoods Or All Then
		
		SettingsDescriptionString = SettingsDescriptionString
			+ StrTemplate(StringPatternBoolean,
				NStr("vi = 'Kết nhập hàng hóa chịu thuế TTĐB (tính và phản ánh thuế TTĐB khi nhập khẩu)';
					|ru = 'Импортирует подакцизный товар (начисление и отражение акциза при импорте)';
					|en = 'Imports excisable goods (excise accrual and recording upon import)'; fa = 'Imports excisable goods (excise accrual and recording upon import)';
					|it = 'Imports excisable goods (excise accrual and recording upon import)';
					|pl = 'Imports excisable goods (excise accrual and recording upon import)';
					|tr = 'Tüketim vergisine tabi ürün ithal eder (ithalat sırasında tüketim vergisinin tahakkuku ve yansıması)'"));
			EndIf;
			
	DetailArray = New Array;
	If CurrentSettings_.ItemizeVariancesByLinesOfBusiness Or All Then
		DetailArray.Add(NStr("vi = 'theo mảng hoạt động';
							|ru = 'по направлениям деятельности';
							|en = 'by lines of business'; fa = 'by lines of business';
							|it = 'by lines of business';
							|pl = 'by lines of business';
							|tr = 'iş koluna göre'"));
	EndIf;
	If CurrentSettings_.ItemizeVariancesByBusinessUnits Or All Then
		DetailArray.Add(NStr("vi = 'theo bộ phận';
							|ru = 'по подразделениям';
							|en = 'by business units'; fa = 'by business units';
							|it = 'by business units';
							|pl = 'by business units';
							|tr = 'departmanlara göre'"));
	EndIf;
	If CurrentSettings_.ItemizeVariancesByWarehousesStorageLocations Or All Then
		DetailArray.Add(NStr("vi = 'theo kho bãi';
							|ru = 'по складам';
							|en = 'by warehouses'; fa = 'بر اساس انبارها';
							|it = 'by warehouses';
							|pl = 'by warehouses';
							|tr = 'ambara göre'"));
	EndIf;
	
	If CurrentSettings_.InventoryValuationMethod = Enums.InventoryValuationMethods.MovingAverage
		And DetailArray.Count() Or All Then
		
		SettingsDescriptionString = SettingsDescriptionString
			+ StrTemplate(StringPattern_,
				NStr("vi = 'Chi tiết chênh lệch';
					|ru = 'Детализация отклонений';
					|en = 'Variance details'; fa = 'جزئیات انحراف';
					|it = 'Variance details';
					|pl = 'Variance details';
					|tr = 'Fark detaylandırması'"),
				StrConcat(DetailArray, ", "));
		
	EndIf;
	
	DescriptionOfActiveParametersLocalization(SettingsDescriptionString, Organization, ValidityDate, CurrentSettings_, All);
	
	Return SettingsDescriptionString
	
EndFunction

// Returns the current values of the organization's debt assessment procedure as of the date.
// 
// Parameters:
// 	Organization - CatalogRef.Companies - link to the organization.
// 	Period - Date - period of validity of settings.
// 
// Returns:
//  ValueTable, Undefined - debt assessment table.
Function DebtEvaluationProcedure(Organization, Period) Export
	
	CurrentSettings_ = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate(
		"FinancialAccountingPolicy", Organization, Period, True);
	
	If CurrentSettings_ <> Undefined
		And CurrentSettings_.DebtEvaluationProcedure <> Undefined Then
			RepositoryProcedureForDebtAssessment = CurrentSettings_.DebtEvaluationProcedure; //ValueStorage
		Return RepositoryProcedureForDebtAssessment.Get();
	Else
		Return Undefined;
	EndIf;
	
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Private

#Region Other

// Returns the parameters of the selection of articles and analyst.
// 
// Parameters:
//  RecognizeResearchExpensesInCurrentPeriod - Boolean
//  AccountingForDiscountedAccountsPayableToVendors - Boolean
//  AccountingForProvisionsAndContingentLiabilities - Boolean
//  AccountingForFinancialLeases - Boolean
//  
// Returns:
//  Array of See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions
//
Function ItemsAndDimensionsSelectionParameters(RecognizeResearchExpensesInCurrentPeriod, AccountingForDiscountedAccountsPayableToVendors,
		AccountingForProvisionsAndContingentLiabilities, AccountingForFinancialLeases) Export
	
	ParametersArray = New Array;
	
	#Region ExpenseItemForRD
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Record";
	ChoiceParameters.AssetRef      = "ExpenseItemForRD";
	
	ChoiceParameters.AvailabilityByOperation = RecognizeResearchExpensesInCurrentPeriod = True;
	ChoiceParameters.HideArticleThatIsUnavailableDueToOperation = False;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "ExpensesDimensionResearchExpenses";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItemForRD");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("ExpensesDimensionResearchExpenses");
	
	ParametersArray.Add(ChoiceParameters);
	#EndRegion
	
	#Region InterestExpenseWriteOffItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Record";
	ChoiceParameters.AssetRef      = "InterestExpenseWriteOffItem";
	
	ChoiceParameters.AvailabilityByOperation = 
		AccountingForDiscountedAccountsPayableToVendors 
		And GetFunctionalOption("NewOnlineARAPAccounting");
	ChoiceParameters.HideArticleThatIsUnavailableDueToOperation = False;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "WriteOffsDimensionOfInterestExpense";
	
	ChoiceParameters.FormItems.AssetRef.Add("InterestExpenseWriteOffItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("WriteOffsDimensionOfInterestExpense");
	
	ParametersArray.Add(ChoiceParameters);
	#EndRegion 
	#Region ItemOfInterestExpenseWriteOffOfProvisionDiscounting
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Record";
	ChoiceParameters.AssetRef      = "ItemOfInterestExpenseWriteOffOfProvisionDiscounting";
	
	ChoiceParameters.AvailabilityByOperation = AccountingForProvisionsAndContingentLiabilities;
	ChoiceParameters.HideArticleThatIsUnavailableDueToOperation = False;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "AnalyticsOfInterestExpenseWriteOffOfProvisionDiscounting";
	
	ChoiceParameters.FormItems.AssetRef.Add("RecordItemOfInterestExpenseWriteOffOfProvisionDiscounting");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("RecordAnalyticsOfInterestExpenseWriteOffOfProvisionDiscounting");
	
	ParametersArray.Add(ChoiceParameters);
	#EndRegion
	
	#Region InterestIncomeItemOfFinancialLease
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Record";
	ChoiceParameters.AssetRef      = "InterestIncomeItemOfFinancialLease";
	
	ChoiceParameters.AvailabilityByOperation = AccountingForFinancialLeases;
	ChoiceParameters.HideArticleThatIsUnavailableDueToOperation = False;
	
	ChoiceParameters.ChoosingIncomeItem = True;
	ChoiceParameters.DimensionOfRevenue = "InterestIncomeDimensionOfFinancialLease";
	
	ChoiceParameters.FormItems.AssetRef.Add("RecordInterestIncomeItemOfFinancialLease");
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("RecordInterestIncomeDimensionOfFinancialLease");
	
	ParametersArray.Add(ChoiceParameters);
	#EndRegion 
	
	#Region IncomeItemForFinancialLeaseServices
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Record";
	ChoiceParameters.AssetRef      = "IncomeItemForFinancialLeaseServices";
	
	ChoiceParameters.AvailabilityByOperation = AccountingForFinancialLeases;
	ChoiceParameters.HideArticleThatIsUnavailableDueToOperation = False;
	
	ChoiceParameters.ChoosingIncomeItem = True;
	ChoiceParameters.DimensionOfRevenue = "IncomeDimensionForFinancialLeaseServices";
	
	ChoiceParameters.FormItems.AssetRef.Add("RecordIncomeItemForFinancialLeaseServices");
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("RecordIncomeDimensionForFinancialLeaseServices");
	
	ParametersArray.Add(ChoiceParameters);
	#EndRegion 
	Return ParametersArray;
	
EndFunction

Procedure DescriptionOfActiveParametersLocalization(SettingsDescriptionString, Organization, ValidityDate, CurrentSettings_, All = False)
	
	
EndProcedure

#EndRegion

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "InformationRegisters.FinancialAccountingPolicy.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.26.25";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("4db80397-fd9c-450a-a10c-cb025337de54");
	Handler.UpdateDataFillingProcedure = "InformationRegisters.FinancialAccountingPolicy.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Comment = NStr("ru = 'Обновляет регистр ""Учетная политика финансового учета"":
	|- заполняет новый реквизит ""Детализировать себестоимость продукции до исходных затрат""';
	|vi = 'Updates the ""Financial accounting policy"" register:
	|- Fills in the new ""Drill down product cost to initial costs"" attribute';
	|en = 'Updates the ""Financial accounting policy"" register:
	|- Fills in the new ""Drill down product cost to initial costs"" attribute'; fa = 'Updates the ""Financial accounting policy"" register:
	|- Fills in the new ""Drill down product cost to initial costs"" attribute';
	|it = 'Updates the ""Financial accounting policy"" register:
	|- Fills in the new ""Drill down product cost to initial costs"" attribute';
	|pl = 'Updates the ""Financial accounting policy"" register:
	|- Fills in the new ""Drill down product cost to initial costs"" attribute';
	|tr = '""Finansal muhasebe politikası"" kaydını günceller:
	|- Yeni ""Üretim maliyetini başlangıç maliyetlerine kadar detaylandır"" özniteliğini doldurur'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.InformationRegisters.FinancialAccountingPolicy.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.InformationRegisters.FinancialAccountingPolicy.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.InformationRegisters.FinancialAccountingPolicy.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");

EndProcedure

Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	AdditionalParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
	AdditionalParameters.IsIndependentInformationRegister = True;
	AdditionalParameters.FullRegisterName = "InformationRegister.FinancialAccountingPolicy";
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.Organization AS Organization
	|FROM
	|	InformationRegister.FinancialAccountingPolicy AS RegisterData
	|WHERE
	|	NOT RegisterData.DrillDownProductCostToInitialCostsResourceIsProcessed
	|";
	
	Data = Query.Execute().Unload();
	InfobaseUpdate.MarkForProcessing(Parameters, Data, AdditionalParameters);
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	ObjectMetadata = Metadata.InformationRegisters.FinancialAccountingPolicy;
	FullObjectName  = ObjectMetadata.FullName();

	AdditionalParameters = InfobaseUpdate.AdditionalProcessingDataSelectionParameters();
	AdditionalParameters.TempTableName = "TTDataToProcess";
	AdditionalParameters.SelectInBatches = False;
	
	TempTablesManager = New TempTablesManager;
	
	InfobaseUpdate.CreateTemporaryTableOfStandaloneInformationRegisterDimensionsToProcess(
		Parameters.Queue,
		FullObjectName,
		TempTablesManager,
		AdditionalParameters);
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
		
	Query.Text =
	"SELECT
	|	DataForProcessing.Period AS Period,
	|	DataForProcessing.Organization AS Organization
	|FROM
	|	TTDataToProcess AS DataForProcessing";
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		BeginTransaction();
		
		Try
			
			Block = New DataLock;

			LockItem = Block.Add(FullObjectName);
			LockItem.SetValue("Period", Selection.Period);
			LockItem.SetValue("Organization", Selection.Organization);
			
			Block.Lock();
			
			RecordSet = CreateRecordSet();
			RecordSet.Filter.Period.Set(Selection.Period);
			RecordSet.Filter.Organization.Set(Selection.Organization);
			RecordSet.Read();
			
			For Each RegisterRecord In RecordSet Do
								
				If Not RegisterRecord.DrillDownProductCostToInitialCostsResourceIsProcessed Then
					RegisterRecord.DrillDownProductCostToInitialCosts = True;
					RegisterRecord.DrillDownProductCostToInitialCostsResourceIsProcessed = True;
				EndIf;
				
			EndDo;
			
			If RecordSet.Modified() Then
				InfobaseUpdate.WriteData(RecordSet);
			Else
				InfobaseUpdate.MarkProcessingCompletion(RecordSet);
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ErrorPresentation = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			
			MessageText = NStr("vi = 'Не удалось записать данные в регистр %RegisterName% по причине: %Cause%';
								|ru = 'Не удалось записать данные в регистр %RegisterName% по причине: %Cause%';
								|en = 'Не удалось записать данные в регистр %RegisterName% по причине: %Cause%'; fa = 'Не удалось записать данные в регистр %RegisterName% по причине: %Cause%';
								|it = 'Не удалось записать данные в регистр %RegisterName% по причине: %Cause%';
								|pl = 'Nie udało się zapisać danych do rejestru %RegisterName% z powodu: %Cause%';
								|tr = 'Не удалось записать данные в регистр %RegisterName% по причине: %Cause%'");
			MessageText = StrReplace(MessageText, "%Cause%", ErrorPresentation);
			MessageText = StrReplace(MessageText, "%RegisterName%", FullObjectName);
			
			WriteLogEvent(
				InfobaseUpdate.EventLogEvent(), 
				EventLogLevel.Warning,
				ObjectMetadata, 
				Undefined, 
				MessageText);
			
			Raise;
			
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted = Not InfobaseUpdate.HasDataToProcess(Parameters.Queue, FullObjectName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
