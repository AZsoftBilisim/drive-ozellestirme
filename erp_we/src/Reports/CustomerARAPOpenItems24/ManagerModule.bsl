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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.CustomerARAPOpenItems24);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Diễn giải hạch toán công nợ đến chứng từ trong nguồn ghi.
		|Các chứng từ nào đã tạo biến động hạch toán hiện tại?
		|Hạch toán công nợ đã thay đổi như thế nào trong kỳ?';
		|ru = 'Расшифровка взаиморасчетов до документов регистраторов.
		|Какие документы сформировали текущее сальдо расчетов?
		|Как изменялись взаиморасчеты за период?';
		|en = 'Drill down AR/AP items to recorder document level.
		|Check which documents generated the current AR/AP open items.
		|Verify how AR/AP items changed over the period.'; fa = 'Drill down AR/AP items to recorder document level.
		|Check which documents generated the current AR/AP open items.
		|Verify how AR/AP items changed over the period.';
		|it = 'Расшифровка взаиморасчетов до документов регистраторов.
		|Какие документы сформировали текущее сальдо расчетов?
		|Как изменялись взаиморасчеты за период?';
		|pl = 'Szczegóły rozliczeń wzajemnych do dokumentów rejestratorów. 
		|Jakie dokumenty ukształtowały saldo bieżące rozliczeń? 
		|Jak zmieniały się rozliczenia wzajemne za okres?';
		|tr = 'Alacak/borç muhasebesinin kayıt belgelerine detaylandırılması.
		|Mevcut ödeme bakiyesini hangi belgeler oluşturmuştur?
		|Alacak/borç muhasebesi dönem boyunca nasıl değişmiştir?'");
	TMReportOptionsOverridable.SetImportanceOfReportOption(OptionDetails, "Important");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "Card");
	OptionDetails.LongDesc = NStr("vi = 'Diễn giải hạch toán công nợ đến chứng từ trong nguồn ghi.
		|Các chứng từ nào đã tạo biến động hạch toán hiện tại?
		|Hạch toán công nợ đã thay đổi như thế nào trong kỳ?';
		|ru = 'Расшифровка взаиморасчетов до документов регистраторов.
		|Какие документы сформировали текущее сальдо расчетов?
		|Как изменялись взаиморасчеты за период?';
		|en = 'Drill down AR/AP items to recorder document level.
		|Check which documents generated the current AR/AP open items.
		|Verify how AR/AP items changed over the period.'; fa = 'Drill down AR/AP items to recorder document level.
		|Check which documents generated the current AR/AP open items.
		|Verify how AR/AP items changed over the period.';
		|it = 'Расшифровка взаиморасчетов до документов регистраторов.
		|Какие документы сформировали текущее сальдо расчетов?
		|Как изменялись взаиморасчеты за период?';
		|pl = 'Szczegóły rozliczeń wzajemnych do dokumentów rejestratorów. 
		|Jakie dokumenty ukształtowały saldo bieżące rozliczeń? 
		|Jak zmieniały się rozliczenia wzajemne za okres?';
		|tr = 'Alacak/borç muhasebesinin kayıt belgelerine detaylandırılması.
		|Mevcut ödeme bakiyesini hangi belgeler oluşturmuştur?
		|Alacak/borç muhasebesi dönem boyunca nasıl değişmiştir?'");
	TMReportOptionsOverridable.SetImportanceOfReportOption(OptionDetails, "Important");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
