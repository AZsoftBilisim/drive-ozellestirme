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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.StatusOfCustomersARAP);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Trạng thái hạch toán hiện tại với khách hàng.
		|Nợ phải thu khách hàng bây giờ là bao nhiêu? Dự tính giao hàng với số tiền là bao nhiêu?
		|Số tiền dự tính thu của khách hàng là bao nhiêu?';
		|ru = 'Текущее состояние расчетов с клиентами.
		|Какой долг клиента сейчас? На какую сумму планируется отгрузка?
		|На какую сумма ожидается оплата от клиента?';
		|en = 'The current customer AR/AP.
		|Check the customer receivables. Verify the amount of goods to be shipped.
		|Track the amount of customer''s payment.'; fa = 'The current customer AR/AP.
		|Check the customer receivables. Verify the amount of goods to be shipped.
		|Track the amount of customer''s payment.';
		|it = 'Текущее состояние расчетов с клиентами.
		|Какой долг клиента сейчас? На какую сумму планируется отгрузка?
		|На какую сумма ожидается оплата от клиента?';
		|pl = 'Bieżący status rozliczeń z klientami. 
		|Jakie zobowiązanie klient ma teraz? Na jaką wartość jest planowana wysyłka? 
		|Na jaką wartość jest oczekiwana płatność od klienta?';
		|tr = 'Müşterilere yapılan ödemelerin mevcut durumu.
		|Müşterinin şu anki borcu nedir? Sevkiyat ne kadar tutar için planlanıyor?
		|Müşterinin ne kadar ödemesi bekleniyor?'");
	TMReportOptionsOverridable.SetImportanceOfReportOption(OptionDetails, "Important");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "StatusOfCustomersARAP");
	OptionDetails.LongDesc = NStr("vi = 'Trạng thái hạch toán hiện tại với khách hàng.
		|Nợ phải thu khách hàng bây giờ là bao nhiêu? Dự tính giao hàng với số tiền là bao nhiêu?
		|Số tiền dự tính thu của khách hàng là bao nhiêu?';
		|ru = 'Текущее состояние расчетов с клиентами.
		|Какой долг клиента сейчас? На какую сумму планируется отгрузка?
		|На какую сумма ожидается оплата от клиента?';
		|en = 'The current customer AR/AP.
		|Check the customer receivables. Verify the amount of goods to be shipped.
		|Track the amount of customer''s payment.'; fa = 'The current customer AR/AP.
		|Check the customer receivables. Verify the amount of goods to be shipped.
		|Track the amount of customer''s payment.';
		|it = 'Текущее состояние расчетов с клиентами.
		|Какой долг клиента сейчас? На какую сумму планируется отгрузка?
		|На какую сумма ожидается оплата от клиента?';
		|pl = 'Bieżący status rozliczeń z klientami. 
		|Jakie zobowiązanie klient ma teraz? Na jaką wartość jest planowana wysyłka? 
		|Na jaką wartość jest oczekiwana płatność od klienta?';
		|tr = 'Müşterilere yapılan ödemelerin mevcut durumu.
		|Müşterinin şu anki borcu nedir? Sevkiyat ne kadar tutar için planlanıyor?
		|Müşterinin ne kadar ödemesi bekleniyor?'");
	TMReportOptionsOverridable.SetImportanceOfReportOption(OptionDetails, "Important");
	OptionDetails.FunctionalOptions.Add("NotBaseVersion");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "StatusOfSettlementsWithClientsIsBasic");
	OptionDetails.FunctionalOptions.Add("BaseVersion");
	OptionDetails.LongDesc = NStr("vi = 'Trạng thái hạch toán hiện tại với khách hàng.
		|Nợ phải thu khách hàng bây giờ là bao nhiêu? Dự tính giao hàng với số tiền là bao nhiêu?
		|Số tiền dự tính thu của khách hàng là bao nhiêu?';
		|ru = 'Текущее состояние расчетов с клиентами.
		|Какой долг клиента сейчас? На какую сумму планируется отгрузка?
		|На какую сумма ожидается оплата от клиента?';
		|en = 'The current customer AR/AP.
		|Check the customer receivables. Verify the amount of goods to be shipped.
		|Track the amount of customer''s payment.'; fa = 'The current customer AR/AP.
		|Check the customer receivables. Verify the amount of goods to be shipped.
		|Track the amount of customer''s payment.';
		|it = 'Текущее состояние расчетов с клиентами.
		|Какой долг клиента сейчас? На какую сумму планируется отгрузка?
		|На какую сумма ожидается оплата от клиента?';
		|pl = 'Bieżący status rozliczeń z klientami. 
		|Jakie zobowiązanie klient ma teraz? Na jaką wartość jest planowana wysyłka? 
		|Na jaką wartość jest oczekiwana płatność od klienta?';
		|tr = 'Müşterilere yapılan ödemelerin mevcut durumu.
		|Müşterinin şu anki borcu nedir? Sevkiyat ne kadar tutar için planlanıyor?
		|Müşterinin ne kadar ödemesi bekleniyor?'");

	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "StateOfCalculationsForObjectOfCalculationsContext");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "StateOfCalculationsForObjectOfCalculationsContextBasic");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "StatusOfSettlementsWithClientContext");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "StateOfSettlementsWithClientContextBasic");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "StatusOfSettlementsWithClientsContext");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "StateOfSettlementsWithCustomersContextBasic");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "CalculationStateForCalculationObjectSimplifiedContext");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "StateOfCalculationsForObjectOfCalculationsSimplifiedContextBasic");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
