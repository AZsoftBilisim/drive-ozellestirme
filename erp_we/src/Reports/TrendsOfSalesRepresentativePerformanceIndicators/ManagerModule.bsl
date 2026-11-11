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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.TrendsOfSalesRepresentativePerformanceIndicators);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích tổng hợp biến động các chỉ tiêu thể hiện hiệu suất làm việc của đại diện thương mại.';
									|ru = 'Сводный анализ изменения показателей, характеризующих эффективность работы торговых представителей.';
									|en = 'Analyze the change of indicators showing efficiency of sales representatives.'; fa = 'Analyze the change of indicators showing efficiency of sales representatives.';
									|it = 'Сводный анализ изменения показателей, характеризующих эффективность работы торговых представителей.';
									|pl = 'Skonsolidowana analiza zmiany wskaźników, charakteryzujących efektywność pracy przedstawicieli handlowych.';
									|tr = 'Satış temsilcilerinin performansını karakterize eden göstergelerdeki değişikliklerin özet analizi.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "DynamicsOfIndicatorsOfSalesRepresentatives");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích tổng hợp biến động các chỉ tiêu thể hiện hiệu suất làm việc của đại diện thương mại.';
									|ru = 'Сводный анализ изменения показателей, характеризующих эффективность работы торговых представителей.';
									|en = 'Analyze the change of indicators showing efficiency of sales representatives.'; fa = 'Analyze the change of indicators showing efficiency of sales representatives.';
									|it = 'Сводный анализ изменения показателей, характеризующих эффективность работы торговых представителей.';
									|pl = 'Skonsolidowana analiza zmiany wskaźników, charakteryzujących efektywność pracy przedstawicieli handlowych.';
									|tr = 'Satış temsilcilerinin performansını karakterize eden göstergelerdeki değişikliklerin özet analizi.'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
