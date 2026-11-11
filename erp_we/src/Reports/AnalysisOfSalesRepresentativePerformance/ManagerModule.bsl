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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.AnalysisOfSalesRepresentativePerformance);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích mức độ thực hiện thành công của các đại diện thương mại với nhiệm vụ được giao.
		|Báo cáo chỉ được dùng trong sơ đồ làm việc có giao nhiệm vụ cho đại diện thương mại.';
		|ru = 'Анализ того, насколько успешно торговые представители справляются с поставленными заданиями.
		|Отчет используется только при схеме работы с выдачей заданий торговым представителям.';
		|en = 'Analyze how successfully sales representatives perform their jobs. 
		|Use the report only if you assign sales representative tasks.'; fa = 'Analyze how successfully sales representatives perform their jobs. 
		|Use the report only if you assign sales representative tasks.';
		|it = 'Анализ того, насколько успешно торговые представители справляются с поставленными заданиями.
		|Отчет используется только при схеме работы с выдачей заданий торговым представителям.';
		|pl = 'Analiza tego, na ile pomyślnie przedstawiciele poradzają sobie z postawionymi zadaniami. 
		|Raport jest używany tylko przy schemacie z wydaniem zadań przedstawicielom handlowym.';
		|tr = 'Satış temsilcilerinin atanan görevlerle ne kadar başarılı olduğuna dair analiz.
		|Rapor yalnızca satış temsilcilerine görevlerin verilmesiyle ilgili iş planında kullanılır.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "Main");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích mức độ thực hiện thành công của các đại diện thương mại với nhiệm vụ được giao.
		|Báo cáo chỉ được dùng trong sơ đồ làm việc có giao nhiệm vụ cho đại diện thương mại.';
		|ru = 'Анализ того, насколько успешно торговые представители справляются с поставленными заданиями.
		|Отчет используется только при схеме работы с выдачей заданий торговым представителям.';
		|en = 'Analyze how successfully sales representatives perform their jobs. 
		|Use the report only if you assign sales representative tasks.'; fa = 'Analyze how successfully sales representatives perform their jobs. 
		|Use the report only if you assign sales representative tasks.';
		|it = 'Анализ того, насколько успешно торговые представители справляются с поставленными заданиями.
		|Отчет используется только при схеме работы с выдачей заданий торговым представителям.';
		|pl = 'Analiza tego, na ile pomyślnie przedstawiciele poradzają sobie z postawionymi zadaniami. 
		|Raport jest używany tylko przy schemacie z wydaniem zadań przedstawicielom handlowym.';
		|tr = 'Satış temsilcilerinin atanan görevlerle ne kadar başarılı olduğuna dair analiz.
		|Rapor yalnızca satış temsilcilerine görevlerin verilmesiyle ilgili iş planında kullanılır.'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
