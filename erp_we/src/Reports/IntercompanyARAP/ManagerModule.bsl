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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.IntercompanyARAP);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Kiểm soát hạch toán công nợ giữa các doanh nghiệp thuộc doanh nghiệp.';
									|ru = 'Контроль взаиморасчетов между организациями, входящими в состав предприятия.';
									|en = 'Control mutual intercompany AR/AP open items that are a part of an enterprise.'; fa = 'Control mutual intercompany AR/AP open items that are a part of an enterprise.';
									|it = 'Контроль взаиморасчетов между организациями, входящими в состав предприятия.';
									|pl = 'Kontrola rozliczeń wzajemnych między firmami, wchodzącymi do składu przedsiębiorstwa.';
									|tr = 'İşletmenin içeriğine dahil olan iş yerleri arasındaki mutabakat kontrolü.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ProcurementPayments");
	OptionDetails.LongDesc = NStr("vi = 'Kiểm soát hạch toán công nợ giữa các doanh nghiệp thuộc tập đoàn.
		|Doanh nghiệp mua đang nợ doanh nghiệp bán bao nhiêu?
		|Nợ giảm hay tăng trong kỳ đã chọn?';
		|ru = 'Контроль взаиморасчетов между организациями, входящими в состав предприятия.
		|Сколько организация-покупатель должна организации-продавцу?
		|Уменьшился или увеличился долг за выбранный период?';
		|en = 'Control mutual intercompany AR/AP open items that are a part of an enterprise.
		|Verify the debt of the customer company to the seller company.
		|Check if the debt has increased or decreased over the selected period.'; fa = 'Control mutual intercompany AR/AP open items that are a part of an enterprise.
		|Verify the debt of the customer company to the seller company.
		|Check if the debt has increased or decreased over the selected period.';
		|it = 'Контроль взаиморасчетов между организациями, входящими в состав предприятия.
		|Сколько организация-покупатель должна организации-продавцу?
		|Уменьшился или увеличился долг за выбранный период?';
		|pl = 'Kontrola rozliczeń wzajemnych między firmami, wchodzącymi do składu przedsiębiorstwa. 
		|Ile firma-nabywca jest dłużna firmie sprzedawcy? 
		| Zmniejszyło czy zwiększyło się zobowiązanie za wybrany okres?';
		|tr = 'İşletmenin bir parçası olan iş yerleri arasındaki mutabakatların kontrolü.
		|Müşteri iş yerinin satıcı iş yerine ne kadar borcu var?
		|Seçilen dönemde borç azaldı mı arttı mı?'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "SalesPayments");
	OptionDetails.LongDesc = NStr("vi = 'Kiểm soát hạch toán công nợ giữa các doanh nghiệp thuộc thành phần doanh nghiệp.
		|Doanh nghiệp bán cần thu bao nhiêu từ doanh nghiệp mua?
		|Nợ giảm hay tăng trong kỳ đã chọn?';
		|ru = 'Контроль взаиморасчетов между организациями, входящими в состав предприятия.
		|Сколько организация-продавец должна получить от организации-покупателя?
		|Уменьшился или увеличился долг за выбранный период?';
		|en = 'Control mutual intercompany AR/AP open items that are a part of an enterprise.
		|What is the debt of the customer company to the seller company?
		|Has the debt increased or decreased for the selected period?'; fa = 'Control mutual intercompany AR/AP open items that are a part of an enterprise.
		|What is the debt of the customer company to the seller company?
		|Has the debt increased or decreased for the selected period?';
		|it = 'Контроль взаиморасчетов между организациями, входящими в состав предприятия.
		|Сколько организация-продавец должна получить от организации-покупателя?
		|Уменьшился или увеличился долг за выбранный период?';
		|pl = 'Kontrola rozliczeń wzajemnych między firmami, wchodzącymi do składu przedsiębiorstwa.
		|Ile firma-sprzedawca powinna otrzymać od firmy nabywcy? 
		| Zmniejszyło czy zwiększyło się zobowiązanie za wybrany okres?';
		|tr = 'İşletmenin bir parçası olan iş yerleri arasındaki mutabakatların kontrolü.
		|Satıcı iş yerinin müşteri iş yerinden ne kadar alacağı var?
		|Seçilen dönemde borç azaldı mı arttı mı?'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
