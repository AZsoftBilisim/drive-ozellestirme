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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.VarianceAnalysisOfSalesRepresentativePerformanceByQuantity);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'So sánh các chỉ tiêu số lượng theo kế hoạch và thực tế của đại diện thương mại.';
									|ru = 'Сравнение плановых и фактических количественных показателей торгового представителя.';
									|en = 'Comparison of target and actual quantitative indicators of a sales representative.'; fa = 'Comparison of target and actual quantitative indicators of a sales representative.';
									|it = 'Сравнение плановых и фактических количественных показателей торгового представителя.';
									|pl = 'Porównanie planowych i faktycznych ilościowych wskaźników przedstawiciela handlowego.';
									|tr = 'Satış temsilcisinin planlanan ve gerçekleşen nicel göstergelerinin karşılaştırılması.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "JobExecutionByProducts");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích thực hiện nhiệm vụ của đại diện thương mại.';
									|ru = 'Анализ исполнения заданий торговыми представителями.';
									|en = 'Analysis of how sales representatives have performed their jobs.'; fa = 'Analysis of how sales representatives have performed their jobs.';
									|it = 'Анализ исполнения заданий торговыми представителями.';
									|pl = 'Analiza wykonania zadań przez przedstawicieli handlowych.';
									|tr = 'Satış temsilcileri tarafından görev yürütme analizi.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "CompletingTasksForRepresentatives");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích thực hiện nhiệm vụ của đại diện thương mại chi tiết đến mặt hàng.';
									|ru = 'Анализ исполнения заданий торговыми представителями с точностью до номенклатуры.';
									|en = 'Analyze how sales representatives performed their jobs, detailed by items.'; fa = 'Analyze how sales representatives performed their jobs, detailed by items.';
									|it = 'Анализ исполнения заданий торговыми представителями с точностью до номенклатуры.';
									|pl = 'Analiza wykonania zadań przez przedstawicieli handlowych z dokładnością do produktów.';
									|tr = 'Satış temsilcileri tarafından görevlerin yürütülmesinin öğe doğruluğu ile analizi.'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
