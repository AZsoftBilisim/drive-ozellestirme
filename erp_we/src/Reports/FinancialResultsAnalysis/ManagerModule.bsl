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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.FinancialResultsAnalysis);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích lãi và lỗ theo dạng và lĩnh vực hoạt động.';
									|ru = 'Анализ прибылей и убытков по статьям и направлениям деятельности.';
									|en = 'Analysis of profits and losses by items and lines of business.'; fa = 'Analysis of profits and losses by items and lines of business.';
									|it = 'Анализ прибылей и убытков по статьям и направлениям деятельности.';
									|pl = 'Analiza zysków i strat według pozycji i rodzajów działalności.';
									|tr = 'Kâr ve zararların kalemler ve iş kollarına göre analizi.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ProfitAndLossStatementByDirection");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích kết quả hoạt động kinh doanh từng giai đoạn theo lĩnh vực hoạt động.';
									|ru = 'Постатейный анализ финансовых результатов по направлениям деятельности.';
									|en = 'Itemized analysis of profitability & cost by lines of business.'; fa = 'Itemized analysis of profitability & cost by lines of business.';
									|it = 'Постатейный анализ финансовых результатов по направлениям деятельности.';
									|pl = 'Analiza według pozycji rezultatów finansowych według rodzajów działalności.';
									|tr = 'İş kollarına göre kârlılık ve maliyetin kalem bazında analizi.'");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ByLinesOfBusiness");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
