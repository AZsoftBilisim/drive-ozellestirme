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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.VendorPayablesByDeadlines);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích công nợ phải trả nhà cung cấp theo khoảng nợ.
		|Ví dụ, 0-7 ngày, 7-15 ngày, 15-30 ngày, hơn 30 ngày.';
		|ru = 'Анализ задолженности перед поставщиками с разбивкой по интервалам долга.
		|Например, 0-7 дней, 7-15 дней, 15-30 дней, более 30 дней.';
		|en = 'Accounts payable analysis by debt intervals. 
		|For example, 0-7 days, 7-15 days, 15-30 days, over 30 days.'; fa = 'Accounts payable analysis by debt intervals. 
		|For example, 0-7 days, 7-15 days, 15-30 days, over 30 days.';
		|it = 'Анализ задолженности перед поставщиками с разбивкой по интервалам долга.
		|Например, 0-7 дней, 7-15 дней, 15-30 дней, более 30 дней.';
		|pl = 'Analiza zobowiązania przed dostawcami z podziałem według interwałów zobowiązania. 
		|Na przykład, 0-7 dni, 7-15 dni, 15-30 dni, więcej 30 dni.';
		|tr = 'Borç aralığına göre tedarikçilerle borç analizi.
		|Örneğin 0-7 gün, 7-15 gün, 15-30 gün, 30 günden fazla.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "VendorPayablesByDeadlines");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích công nợ phải trả nhà cung cấp theo khoảng nợ.
		|Ví dụ, 0-7 ngày, 7-15 ngày, 15-30 ngày, hơn 30 ngày.';
		|ru = 'Анализ задолженности перед поставщиками с разбивкой по интервалам долга.
		|Например, 0-7 дней, 7-15 дней, 15-30 дней, более 30 дней.';
		|en = 'Accounts payable analysis by debt intervals. 
		|For example, 0-7 days, 7-15 days, 15-30 days, over 30 days.'; fa = 'Accounts payable analysis by debt intervals. 
		|For example, 0-7 days, 7-15 days, 15-30 days, over 30 days.';
		|it = 'Анализ задолженности перед поставщиками с разбивкой по интервалам долга.
		|Например, 0-7 дней, 7-15 дней, 15-30 дней, более 30 дней.';
		|pl = 'Analiza zobowiązania przed dostawcami z podziałem według interwałów zobowiązania. 
		|Na przykład, 0-7 dni, 7-15 dni, 15-30 dni, więcej 30 dni.';
		|tr = 'Borç aralığına göre tedarikçilerle borç analizi.
		|Örneğin 0-7 gün, 7-15 gün, 15-30 gün, 30 günden fazla.'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
