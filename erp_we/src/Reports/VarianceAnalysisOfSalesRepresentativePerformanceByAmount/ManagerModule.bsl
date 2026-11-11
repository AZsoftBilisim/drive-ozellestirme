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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.VarianceAnalysisOfSalesRepresentativePerformanceByAmount);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'So sánh các chỉ tiêu giá trị theo kế hoạch và thực tế của đại diện thương mại.';
									|ru = 'Сравнение плановых и фактических суммовых показателей торгового представителя.';
									|en = 'Comparison of scheduled and actual amount indicators of a sales representative.'; fa = 'Comparison of scheduled and actual amount indicators of a sales representative.';
									|it = 'Сравнение плановых и фактических суммовых показателей торгового представителя.';
									|pl = 'Porównanie planowych i faktycznych wartościowych wskaźników przedstawiciela handlowego.';
									|tr = 'Planlanan ve gerçekleşen satış temsilcisi toplam göstergelerinin karşılaştırılması.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "CompletingTasksByAmount");
	OptionDetails.LongDesc = NStr("vi = 'So sánh các chỉ tiêu giá trị theo kế hoạch và thực tế của đại diện thương mại.';
									|ru = 'Сравнение плановых и фактических суммовых показателей торгового представителя.';
									|en = 'Comparison of scheduled and actual amount indicators of a sales representative.'; fa = 'Comparison of scheduled and actual amount indicators of a sales representative.';
									|it = 'Сравнение плановых и фактических суммовых показателей торгового представителя.';
									|pl = 'Porównanie planowych i faktycznych wartościowych wskaźników przedstawiciela handlowego.';
									|tr = 'Planlanan ve gerçekleşen satış temsilcisi toplam göstergelerinin karşılaştırılması.'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
