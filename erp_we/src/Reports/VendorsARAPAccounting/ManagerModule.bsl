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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.VendorsARAPAccounting);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích chi tiết hạch toán công nợ với nhà cung cấp.
		|Công nợ thay đổi như thế nào trong kỳ?
		|Cán cân thanh toán hiện tại là bao nhiêu?';
		|ru = 'Детальный анализ взаиморасчетов с поставщиками.
		|Как изменялась задолженность за указанный период?
		|Какое текущее сальдо расчетов?';
		|en = 'Detailed analysis of vendor AR/AP.
		|Check how the debt has changed over the specified period.
		|Verify the current AR/AP balance.'; fa = 'Detailed analysis of vendor AR/AP.
		|Check how the debt has changed over the specified period.
		|Verify the current AR/AP balance.';
		|it = 'Детальный анализ взаиморасчетов с поставщиками.
		|Как изменялась задолженность за указанный период?
		|Какое текущее сальдо расчетов?';
		|pl = 'Szczegółowa analiza rozliczeń wzajemnych z dostawcami. 
		|Jak zmieniało się zobowiązanie za wskazany okres? 
		|Jakie jest bieżące saldo rozliczeń?';
		|tr = 'Müşteriler ve tedarikçilerle alacak/borç muhasebesinin detaylı analizi.
		|Belirlenen dönemde borç nasıl değişmiştir?
		|Mevcut alacak/borç muhasebesi bakiyesi nedir?'");
	TMReportOptionsOverridable.SetImportanceOfReportOption(OptionDetails, "Important");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "VendorsARAPAccounting");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích chi tiết hạch toán công nợ với nhà cung cấp.
		|Công nợ thay đổi như thế nào trong kỳ?
		|Cán cân thanh toán hiện tại là bao nhiêu?';
		|ru = 'Детальный анализ взаиморасчетов с поставщиками.
		|Как изменялась задолженность за указанный период?
		|Какое текущее сальдо расчетов?';
		|en = 'Detailed analysis of vendor AR/AP.
		|Check how the debt has changed over the specified period.
		|Verify the current AR/AP balance.'; fa = 'Detailed analysis of vendor AR/AP.
		|Check how the debt has changed over the specified period.
		|Verify the current AR/AP balance.';
		|it = 'Детальный анализ взаиморасчетов с поставщиками.
		|Как изменялась задолженность за указанный период?
		|Какое текущее сальдо расчетов?';
		|pl = 'Szczegółowa analiza rozliczeń wzajemnych z dostawcami. 
		|Jak zmieniało się zobowiązanie za wskazany okres? 
		|Jakie jest bieżące saldo rozliczeń?';
		|tr = 'Müşteriler ve tedarikçilerle alacak/borç muhasebesinin detaylı analizi.
		|Belirlenen dönemde borç nasıl değişmiştir?
		|Mevcut alacak/borç muhasebesi bakiyesi nedir?'");
	TMReportOptionsOverridable.SetImportanceOfReportOption(OptionDetails, "Important");
	OptionDetails.FunctionalOptions.Add("NotBaseVersion");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "SettlementsWithSuppliersBasic");
	OptionDetails.FunctionalOptions.Add("BaseVersion");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích chi tiết hạch toán công nợ với nhà cung cấp.
		|Công nợ thay đổi như thế nào trong kỳ?
		|Cán cân thanh toán hiện tại là bao nhiêu?';
		|ru = 'Детальный анализ взаиморасчетов с поставщиками.
		|Как изменялась задолженность за указанный период?
		|Какое текущее сальдо расчетов?';
		|en = 'Detailed analysis of vendor AR/AP.
		|Check how the debt has changed over the specified period.
		|Verify the current AR/AP balance.'; fa = 'Detailed analysis of vendor AR/AP.
		|Check how the debt has changed over the specified period.
		|Verify the current AR/AP balance.';
		|it = 'Детальный анализ взаиморасчетов с поставщиками.
		|Как изменялась задолженность за указанный период?
		|Какое текущее сальдо расчетов?';
		|pl = 'Szczegółowa analiza rozliczeń wzajemnych z dostawcami. 
		|Jak zmieniało się zobowiązanie za wskazany okres? 
		|Jakie jest bieżące saldo rozliczeń?';
		|tr = 'Müşteriler ve tedarikçilerle alacak/borç muhasebesinin detaylı analizi.
		|Belirlenen dönemde borç nasıl değişmiştir?
		|Mevcut alacak/borç muhasebesi bakiyesi nedir?'");
		
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.VendorARAPOpenItems24);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Diễn giải hạch toán công nợ đến chứng từ nguồn ghi.
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
	OptionDetails.LongDesc = NStr("vi = 'Diễn giải hạch toán công nợ đến chứng từ nguồn ghi.
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.VendorsARAPStatement);
	DescriptionOfReport.DefineFormSettings = True;
	DescriptionStatementOfSettlementsWithSuppliers = NStr("vi = 'Phân tích chi tiết hạch toán công nợ với nhà cung cấp.
		|Công nợ thay đổi như thế nào trong kỳ?
		|Cán cân thanh toán hiện tại là bao nhiêu?';
		|ru = 'Детальный анализ взаиморасчетов с поставщиками.
		|Как изменялась задолженность за указанный период?
		|Какое текущее сальдо расчетов?';
		|en = 'Detailed analysis of vendor AR/AP.
		|Check how the debt has changed over the specified period.
		|Verify the current AR/AP balance.'; fa = 'Detailed analysis of vendor AR/AP.
		|Check how the debt has changed over the specified period.
		|Verify the current AR/AP balance.';
		|it = 'Детальный анализ взаиморасчетов с поставщиками.
		|Как изменялась задолженность за указанный период?
		|Какое текущее сальдо расчетов?';
		|pl = 'Szczegółowa analiza rozliczeń wzajemnych z dostawcami. 
		|Jak zmieniało się zobowiązanie za wskazany okres? 
		|Jakie jest bieżące saldo rozliczeń?';
		|tr = 'Müşteriler ve tedarikçilerle alacak/borç muhasebesinin detaylı analizi.
		|Belirlenen dönemde borç nasıl değişmiştir?
		|Mevcut alacak/borç muhasebesi bakiyesi nedir?'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = DescriptionStatementOfSettlementsWithSuppliers;
	TMReportOptionsOverridable.SetImportanceOfReportOption(OptionDetails, "Important");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "Statement");
	OptionDetails.LongDesc = DescriptionStatementOfSettlementsWithSuppliers;
	TMReportOptionsOverridable.SetImportanceOfReportOption(OptionDetails, "Important");
	OptionDetails.FunctionalOptions.Add("NotBaseVersion");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "StatementBasic");
	OptionDetails.LongDesc = DescriptionStatementOfSettlementsWithSuppliers;
	OptionDetails.FunctionalOptions.Add("BaseVersion");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "MobileClientStatement");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích chi tiết hạch toán công nợ với nhà cung cấp.
		|Công nợ thay đổi như thế nào trong kỳ?
		|Cán cân thanh toán hiện tại là bao nhiêu?';
		|ru = 'Детальный анализ взаиморасчетов с поставщиками.
		|Как изменялась задолженность за указанный период?
		|Какое текущее сальдо расчетов?';
		|en = 'Detailed analysis of vendor AR/AP.
		|Check how the debt has changed over the specified period.
		|Verify the current AR/AP balance.'; fa = 'Detailed analysis of vendor AR/AP.
		|Check how the debt has changed over the specified period.
		|Verify the current AR/AP balance.';
		|it = 'Детальный анализ взаиморасчетов с поставщиками.
		|Как изменялась задолженность за указанный период?
		|Какое текущее сальдо расчетов?';
		|pl = 'Szczegółowa analiza rozliczeń wzajemnych z dostawcami. 
		|Jak zmieniało się zobowiązanie za wskazany okres? 
		|Jakie jest bieżące saldo rozliczeń?';
		|tr = 'Müşteriler ve tedarikçilerle alacak/borç muhasebesinin detaylı analizi.
		|Belirlenen dönemde borç nasıl değişmiştir?
		|Mevcut alacak/borç muhasebesi bakiyesi nedir?'");
	OptionDetails.Description = NStr("vi = 'Bảng kê hạch toán với nhà cung cấp (di động)';
									|ru = 'Ведомость с поставщиками (моб.)';
									|en = 'Statement of vendor AR/AP (mob. client)'; fa = 'صورت دریافتنی/پرداختنی فروشنده (کلاینت موبایل)';
									|it = 'Ведомость с поставщиками (моб.)';
									|pl = 'Zestawienie z dostawcami (mob.)';
									|tr = 'Tedarikçilerle beyan (mob.)'");
	OptionDetails.DefaultVisibility = True;
	OptionDetails.Purpose = Enums.ReportOptionPurposes.ForSmartphones;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
