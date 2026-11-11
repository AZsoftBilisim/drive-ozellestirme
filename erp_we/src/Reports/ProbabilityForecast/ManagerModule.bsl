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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ProbabilityForecast);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Xác suất giành được vụ việc trong từng giai đoạn của quy trình bán hàng là bao nhiêu?';
									|ru = 'Какая вероятность выигрыша сделок на каждом из этапов процесса продаж?';
									|en = 'Check the probability for winning sales opportunities on each stage of the sales process.'; fa = 'Check the probability for winning sales opportunities on each stage of the sales process.';
									|it = 'Какая вероятность выигрыша сделок на каждом из этапов процесса продаж?';
									|pl = 'Jakie jest prawdopodobieństwo wygrania transakcji na każdym etapie procesu sprzedaży?';
									|tr = 'Satış sürecinin her aşamasında satış fırsatı elde etme olasılığı nedir?'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "Main");
	OptionDetails.LongDesc = NStr("vi = 'Xác suất giành được vụ việc trong từng giai đoạn của quy trình bán hàng là bao nhiêu?';
									|ru = 'Какая вероятность выигрыша сделок на каждом из этапов процесса продаж?';
									|en = 'Check the probability for winning sales opportunities on each stage of the sales process.'; fa = 'Check the probability for winning sales opportunities on each stage of the sales process.';
									|it = 'Какая вероятность выигрыша сделок на каждом из этапов процесса продаж?';
									|pl = 'Jakie jest prawdopodobieństwo wygrania transakcji na każdym etapie procesu sprzedaży?';
									|tr = 'Satış sürecinin her aşamasında satış fırsatı elde etme olasılığı nedir?'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
