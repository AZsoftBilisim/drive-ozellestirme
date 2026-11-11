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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ComparisonOfSalesOfSamePeriods);
	DescriptionOfReport.DefineFormSettings = True;
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích cấu trúc và thay đổi doanh thu trong nhiều kỳ - năm, tháng,
		|tuần, ngày.';
		|ru = 'Анализ структуры и изменений выручки за несколько периодов - лет, месяцев,
		|недель, дней.';
		|en = 'Analysis of revenue structure and changes for several periods: years, months,
		|weeks, and days.'; fa = 'Analysis of revenue structure and changes for several periods: years, months,
		|weeks, and days.';
		|it = 'Анализ структуры и изменений выручки за несколько периодов - лет, месяцев,
		|недель, дней.';
		|pl = 'Analiza struktury i zmian przychodu za kilka okresów - lat, miesięcy, 
		|tygodni, dni.';
		|tr = 'Yıllar, aylar,
		|haftalar, günler gibi çeşitli dönemler için gelirdeki yapının ve değişikliklerin analizi.'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ComparisonOfSalesOfTheSamePeriods");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích cấu trúc và thay đổi doanh thu trong nhiều kỳ - năm, tháng,
		|tuần, ngày.';
		|ru = 'Анализ структуры и изменений выручки за несколько периодов - лет, месяцев,
		|недель, дней.';
		|en = 'Analysis of revenue structure and changes for several periods: years, months,
		|weeks, and days.'; fa = 'Analysis of revenue structure and changes for several periods: years, months,
		|weeks, and days.';
		|it = 'Анализ структуры и изменений выручки за несколько периодов - лет, месяцев,
		|недель, дней.';
		|pl = 'Analiza struktury i zmian przychodu za kilka okresów - lat, miesięcy, 
		|tygodni, dni.';
		|tr = 'Yıllar, aylar,
		|haftalar, günler gibi çeşitli dönemler için gelirdeki yapının ve değişikliklerin analizi.'");
	OptionDetails.FunctionalOptions.Add("NotUseBusinessRegions");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ComparisonOfSalesOfSimilarPeriodsBusinessRegions");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích cấu trúc và thay đổi doanh thu trong nhiều kỳ - năm, tháng,
		|tuần, ngày.';
		|ru = 'Анализ структуры и изменений выручки за несколько периодов - лет, месяцев,
		|недель, дней.';
		|en = 'Analysis of revenue structure and changes for several periods: years, months,
		|weeks, and days.'; fa = 'Analysis of revenue structure and changes for several periods: years, months,
		|weeks, and days.';
		|it = 'Анализ структуры и изменений выручки за несколько периодов - лет, месяцев,
		|недель, дней.';
		|pl = 'Analiza struktury i zmian przychodu za kilka okresów - lat, miesięcy, 
		|tygodni, dni.';
		|tr = 'Yıllar, aylar,
		|haftalar, günler gibi çeşitli dönemler için gelirdeki yapının ve değişikliklerin analizi.'");
	OptionDetails.FunctionalOptions.Add("UseBusinessRegions");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ComparisonOfSalesOfSimilarPeriodsMobileClient");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích cấu trúc và thay đổi doanh thu trong nhiều kỳ - năm, tháng,
		|tuần, ngày.';
		|ru = 'Анализ структуры и изменений выручки за несколько периодов - лет, месяцев,
		|недель, дней.';
		|en = 'Analysis of revenue structure and changes for several periods: years, months,
		|weeks, and days.'; fa = 'Analysis of revenue structure and changes for several periods: years, months,
		|weeks, and days.';
		|it = 'Анализ структуры и изменений выручки за несколько периодов - лет, месяцев,
		|недель, дней.';
		|pl = 'Analiza struktury i zmian przychodu za kilka okresów - lat, miesięcy, 
		|tygodni, dni.';
		|tr = 'Yıllar, aylar,
		|haftalar, günler gibi çeşitli dönemler için gelirdeki yapının ve değişikliklerin analizi.'");
	OptionDetails.Description = NStr("vi = 'So sánh doanh thu bán hàng giữa các kỳ tương tự (di động)';
									|ru = 'Сравнение продаж аналогичных периодов (моб.)';
									|en = 'Current vs previous sales comparison (mob. client)'; fa = 'مقایسه فروش جاری با قبلی (کلاینت موبایل)';
									|it = 'Сравнение продаж аналогичных периодов (моб.)';
									|pl = 'Porównanie sprzedaży analogicznych okresów (mob.)';
									|tr = 'Benzer dönemlerin satışlarının karşılaştırılması (mob.)'");
	OptionDetails.DefaultVisibility = True;
	OptionDetails.Purpose = Enums.ReportOptionPurposes.ForSmartphones;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
