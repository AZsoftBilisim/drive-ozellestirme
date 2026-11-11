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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.AnalysisOfVariancesInGoodsCost);
	DescriptionOfReport.DefineFormSettings = True;
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích chênh lệch trong giá trị hàng hóa.';
									|ru = 'Анализ отклонений в стоимости товаров.';
									|en = 'Analysis of variances in goods cost.'; fa = 'Analysis of variances in goods cost.';
									|it = 'Analysis of variances in goods cost.';
									|pl = 'Analysis of variances in goods cost.';
									|tr = 'Ürün maliyetinde fark analizi.'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "AnalysisOfDeviationsInCostOfGoodsByOrganizations");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích chênh lệch trong giá trị hàng hóa theo doanh nghiệp.';
									|ru = 'Анализ отклонений в стоимости товаров по организациям.';
									|en = 'Analysis of variances in goods cost by companies.'; fa = 'Analysis of variances in goods cost by companies.';
									|it = 'Analysis of variances in goods cost by companies.';
									|pl = 'Analysis of variances in goods cost by companies.';
									|tr = 'İş yerlerine göre ürün maliyetlerinde fark analizi.'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "AnalysisOfDeviationsInCostOfGoodsByEnterprise");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích chênh lệch trong giá trị hàng hóa theo doanh nghiệp.';
									|ru = 'Анализ отклонений в стоимости товаров по предприятию.';
									|en = 'Analysis of variances in goods cost by enterprise.'; fa = 'Analysis of variances in goods cost by enterprise.';
									|it = 'Analysis of variances in goods cost by enterprise.';
									|pl = 'Analysis of variances in goods cost by enterprise.';
									|tr = 'İşletmelere göre ürün maliyetlerinde fark analizi.'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
