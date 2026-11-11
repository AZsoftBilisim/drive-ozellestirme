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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.PaymentsFromCustomersByDeadlines);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích công nợ phải thu khách hàng theo khoảng nợ.
		|Ví dụ: 0-7 ngày, 7-15 ngày, 15-30 ngày, hơn 30 ngày.';
		|ru = 'Анализ нашей задолженности клиентам с разбивкой по интервалам долга.
		|Например, 0-7 дней, 7-15 дней, 15-30 дней, более 30 дней.';
		|en = 'Analysis of customer payables broken down by debt intervals.
		|For example, 0-7 days, 7-15 days, 15-30 days, over 30 days.'; fa = 'Analysis of customer payables broken down by debt intervals.
		|For example, 0-7 days, 7-15 days, 15-30 days, over 30 days.';
		|it = 'Анализ нашей задолженности клиентам с разбивкой по интервалам долга.
		|Например, 0-7 дней, 7-15 дней, 15-30 дней, более 30 дней.';
		|pl = 'Analysis of customer payables broken down by debt intervals.
		|For example, 0-7 days, 7-15 days, 15-30 days, over 30 days.';
		|tr = 'Müşteri borçlarımızın borç aralığına göre analizi.
		|Örneğin 0-7 gün, 7-15 gün, 15-30 gün, 30 günden fazla.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "PaymentsFromCustomersByDeadlines");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích công nợ phải thu khách hàng theo khoảng nợ.
		|Ví dụ: 0-7 ngày, 7-15 ngày, 15-30 ngày, hơn 30 ngày.';
		|ru = 'Анализ нашей задолженности клиентам с разбивкой по интервалам долга.
		|Например, 0-7 дней, 7-15 дней, 15-30 дней, более 30 дней.';
		|en = 'Analysis of customer payables broken down by debt intervals.
		|For example, 0-7 days, 7-15 days, 15-30 days, over 30 days.'; fa = 'Analysis of customer payables broken down by debt intervals.
		|For example, 0-7 days, 7-15 days, 15-30 days, over 30 days.';
		|it = 'Анализ нашей задолженности клиентам с разбивкой по интервалам долга.
		|Например, 0-7 дней, 7-15 дней, 15-30 дней, более 30 дней.';
		|pl = 'Analysis of customer payables broken down by debt intervals.
		|For example, 0-7 days, 7-15 days, 15-30 days, over 30 days.';
		|tr = 'Müşteri borçlarımızın borç aralığına göre analizi.
		|Örneğin 0-7 gün, 7-15 gün, 15-30 gün, 30 günden fazla.'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
