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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ComparisonOfSalesOfTwoPeriods);
	DescriptionOfReport.DefineFormSettings = True;
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích biến động doanh thu trong kỳ so sánh
		|theo kết quả tăng/giảm.';
		|ru = 'Анализ колебаний выручки в сравниваемых периодах
		|по полученному приросту/спаду.';
		|en = 'Analysis of revenue fluctuations in the compared periods
		|by the resulting increase/decrease.'; fa = 'Analysis of revenue fluctuations in the compared periods
		|by the resulting increase/decrease.';
		|it = 'Анализ колебаний выручки в сравниваемых периодах
		|по полученному приросту/спаду.';
		|pl = 'Analiza wahań utargu w porównywanych okresach
		|wg otrzymanego przyrostu/spadku.';
		|tr = 'Karşılaştırılan dönemlerde
		|ortaya çıkan artış/azalış bazında gelir dalgalanmalarının analizi.'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "SalesRankOfTwoPeriods");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích xu hướng bán hàng so với kỳ trước?
		|Giảm hoặc tăng doanh thu?';
		|ru = 'Анализ тренда продаж по сравнению с прошлым периодом?
		|Понижаются или повышаются продажи?';
		|en = 'Analyze the sales trend compared to the previous period.
		|Track if the sales increase or decrease.'; fa = 'Analyze the sales trend compared to the previous period.
		|Track if the sales increase or decrease.';
		|it = 'Анализ тренда продаж по сравнению с прошлым периодом?
		|Понижаются или повышаются продажи?';
		|pl = 'Analiza trendu sprzedaży w porównaniu z przeszłym okresem?
		|Zmniejsza się czy zwiększa się sprzedaż?';
		|tr = 'Bir önceki döneme göre satış trendinin analizi?
		|Satışlar azalıyor mu artıyor mu?'");
	OptionDetails.FunctionalOptions.Add("NotUseBusinessRegions");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "SalesRatingOfTwoPeriodsBusinessRegions");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích xu hướng bán hàng so với kỳ trước?
		|Giảm hoặc tăng doanh thu?';
		|ru = 'Анализ тренда продаж по сравнению с прошлым периодом?
		|Понижаются или повышаются продажи?';
		|en = 'Analyze the sales trend compared to the previous period.
		|Track if the sales increase or decrease.'; fa = 'Analyze the sales trend compared to the previous period.
		|Track if the sales increase or decrease.';
		|it = 'Анализ тренда продаж по сравнению с прошлым периодом?
		|Понижаются или повышаются продажи?';
		|pl = 'Analiza trendu sprzedaży w porównaniu z przeszłym okresem?
		|Zmniejsza się czy zwiększa się sprzedaż?';
		|tr = 'Bir önceki döneme göre satış trendinin analizi?
		|Satışlar azalıyor mu artıyor mu?'");
	OptionDetails.FunctionalOptions.Add("UseBusinessRegions");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "CompareRevenuesOfTwoPeriods");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích bán hàng tổng hợp theo hai kỳ
		|theo khu vực kinh doanh và dạng mặt hàng.';
		|ru = 'Сводный анализ продаж по двум периодам
		|по бизнес-регионам и видам номенклатуры.';
		|en = 'Summary analysis of sales for two periods
		|by business regions and kinds of products.'; fa = 'Summary analysis of sales for two periods
		|by business regions and kinds of products.';
		|it = 'Сводный анализ продаж по двум периодам
		|по бизнес-регионам и видам номенклатуры.';
		|pl = 'Skonsolodowana analiza sprzedaży według dwuch okresów 
		|według regionów biznesowych i rodzajów produktów.';
		|tr = 'Satışların iş bölgelerine ve ürün türlerine göre iki döneme göre
		|özet analizi.'");
	OptionDetails.FunctionalOptions.Add("NotUseBusinessRegions");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ComparisonOfRevenueOfTwoPeriodsBusinessRegions");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích bán hàng tổng hợp theo hai kỳ
		|theo khu vực kinh doanh và dạng mặt hàng.';
		|ru = 'Сводный анализ продаж по двум периодам
		|по бизнес-регионам и видам номенклатуры.';
		|en = 'Summary analysis of sales for two periods
		|by business regions and kinds of products.'; fa = 'Summary analysis of sales for two periods
		|by business regions and kinds of products.';
		|it = 'Сводный анализ продаж по двум периодам
		|по бизнес-регионам и видам номенклатуры.';
		|pl = 'Skonsolodowana analiza sprzedaży według dwuch okresów 
		|według regionów biznesowych i rodzajów produktów.';
		|tr = 'Satışların iş bölgelerine ve ürün türlerine göre iki döneme göre
		|özet analizi.'");
	OptionDetails.FunctionalOptions.Add("UseBusinessRegions");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
