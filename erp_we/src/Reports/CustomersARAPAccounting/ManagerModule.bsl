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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.CustomersARAPAccounting);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích chi tiết hạch toán công nợ với khách hàng.
		|Công nợ thay đổi như thế nào trong kỳ chỉ định?
		| Số dư hạch toán hiện tại là bao nhiêu?';
		|ru = 'Детальный анализ взаиморасчетов с клиентами.
		|Как изменялась задолженность за указанный период?
		|Какое текущее сальдо расчетов?';
		|en = 'Analyze customer AR/AP in detail.
		|Verify how the debt changed over the specified period.
		|Check the current AR/AP balance.'; fa = 'Analyze customer AR/AP in detail.
		|Verify how the debt changed over the specified period.
		|Check the current AR/AP balance.';
		|it = 'Детальный анализ взаиморасчетов с клиентами.
		|Как изменялась задолженность за указанный период?
		|Какое текущее сальдо расчетов?';
		|pl = 'Szczegółowa analiza rozliczeń wzajemnych z klientami. 
		|Jak zmieniało się zobowiązanie za wskazany okres? 
		|Jakie jest bieżące saldo rozliczeń?';
		|tr = 'Müşterilerle yapılan mutabakatların ayrıntılı analizi.
		|Belirtilen dönemde borç nasıl değişti?
		|Mevcut ödemeler bakiyesi nedir?'");
	TMReportOptionsOverridable.SetImportanceOfReportOption(OptionDetails, "Important");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "CustomersARAPAccounting");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích chi tiết hạch toán công nợ với khách hàng.
		|Công nợ thay đổi như thế nào trong kỳ chỉ định?
		| Số dư hạch toán hiện tại là bao nhiêu?';
		|ru = 'Детальный анализ взаиморасчетов с клиентами.
		|Как изменялась задолженность за указанный период?
		|Какое текущее сальдо расчетов?';
		|en = 'Analyze customer AR/AP in detail.
		|Verify how the debt changed over the specified period.
		|Check the current AR/AP balance.'; fa = 'Analyze customer AR/AP in detail.
		|Verify how the debt changed over the specified period.
		|Check the current AR/AP balance.';
		|it = 'Детальный анализ взаиморасчетов с клиентами.
		|Как изменялась задолженность за указанный период?
		|Какое текущее сальдо расчетов?';
		|pl = 'Szczegółowa analiza rozliczeń wzajemnych z klientami. 
		|Jak zmieniało się zobowiązanie za wskazany okres? 
		|Jakie jest bieżące saldo rozliczeń?';
		|tr = 'Müşterilerle yapılan mutabakatların ayrıntılı analizi.
		|Belirtilen dönemde borç nasıl değişti?
		|Mevcut ödemeler bakiyesi nedir?'");
	TMReportOptionsOverridable.SetImportanceOfReportOption(OptionDetails, "Important");
	OptionDetails.FunctionalOptions.Add("NotBaseVersion");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "CustomersARAPAccountingBasic");
	OptionDetails.FunctionalOptions.Add("BaseVersion");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích chi tiết hạch toán công nợ với khách hàng.
		|Công nợ thay đổi như thế nào trong kỳ chỉ định?
		| Số dư hạch toán hiện tại là bao nhiêu?';
		|ru = 'Детальный анализ взаиморасчетов с клиентами.
		|Как изменялась задолженность за указанный период?
		|Какое текущее сальдо расчетов?';
		|en = 'Analyze customer AR/AP in detail.
		|Verify how the debt changed over the specified period.
		|Check the current AR/AP balance.'; fa = 'Analyze customer AR/AP in detail.
		|Verify how the debt changed over the specified period.
		|Check the current AR/AP balance.';
		|it = 'Детальный анализ взаиморасчетов с клиентами.
		|Как изменялась задолженность за указанный период?
		|Какое текущее сальдо расчетов?';
		|pl = 'Szczegółowa analiza rozliczeń wzajemnych z klientami. 
		|Jak zmieniało się zobowiązanie za wskazany okres? 
		|Jakie jest bieżące saldo rozliczeń?';
		|tr = 'Müşterilerle yapılan mutabakatların ayrıntılı analizi.
		|Belirtilen dönemde borç nasıl değişti?
		|Mevcut ödemeler bakiyesi nedir?'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
