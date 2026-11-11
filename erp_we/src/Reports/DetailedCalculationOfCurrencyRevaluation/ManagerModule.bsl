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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.DetailedCalculationOfCurrencyRevaluation);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.FunctionalOptions.Add("NotBaseVersion");
	OptionDetails.LongDesc = NStr("vi = 'Chỗ nào phát sinh chênh lệch tỷ giá?
		|Tại sao cần đánh giá lại?';
		|ru = 'Откуда возникают курсовые разницы?
		|Почему требуется переоценка?';
		|en = 'Check where exchange differences come from.
		|Find out why revaluation is required.'; fa = 'Check where exchange differences come from.
		|Find out why revaluation is required.';
		|it = 'Откуда возникают курсовые разницы?
		|Почему требуется переоценка?';
		|pl = 'Skąd powstają różnice kursowe? 
		|Czemu jest wymagane przeszacowanie?';
		|tr = 'Kur farkları nereden kaynaklanmaktadır?
		|Yeniden değerleme neden gereklidir?'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
