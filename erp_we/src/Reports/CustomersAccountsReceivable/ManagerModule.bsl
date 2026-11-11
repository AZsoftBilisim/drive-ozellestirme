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
	
	DescriptionCustomerAccounts = NStr("vi = 'Trạng thái hạch toán hiện tại với khách hàng.
		|Công nợ hiện tại của khách hàng là bao nhiêu? Dự tính giao hàng với số tiền là bao nhiêu?
		|Số tiền dự tính nhận thanh toán từ khách hàng là bao nhiêu?';
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
		|tr = 'Müşterilerle yapılan ödemelerin mevcut durumu.
		|Müşterinin şu anki borcu nedir? Sevkiyat ne kadar tutar için planlanıyor?
		|Müşterinin ne kadar ödemesi bekleniyor?'");
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.CustomersAccountsReceivable);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = DescriptionCustomerAccounts;
	TMReportOptionsOverridable.SetImportanceOfReportOption(OptionDetails, "Important");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "CustomersAccountsReceivable");
	OptionDetails.LongDesc = DescriptionCustomerAccounts;
	TMReportOptionsOverridable.SetImportanceOfReportOption(OptionDetails, "Important");
	OptionDetails.FunctionalOptions.Add("NotBaseVersion");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "CustomerDebtBasic");
	OptionDetails.LongDesc = DescriptionCustomerAccounts;
	OptionDetails.FunctionalOptions.Add("BaseVersion");
	
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "CustomerDebtOnObjectOfSettlement");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "CustomerDebtOnObjectOfSettlementsBasic");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "CustomerDebtContext");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "CustomerDebtContextBasic");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "CustomersDebtContext");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "CustomersDebtContextBasic");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "CustomerDebtReasonsForBanningShipments");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "CustomerDebtMobileCustomer");
	OptionDetails.LongDesc = DescriptionCustomerAccounts;
	OptionDetails.Description = NStr("vi = 'Nợ phải thu khách hàng (di động)';
									|ru = 'Задолженность клиентов (моб.)';
									|en = 'Customer AR/AP open items (mob. client)'; fa = 'اقلام باز دریافتنی/پرداختنی مشتری (کلاینت موبایل)';
									|it = 'Задолженность клиентов (моб.)';
									|pl = 'Zadłużenie klientów (mob.)';
									|tr = 'Müşteri alacakları/borçları (mob.)'");
	OptionDetails.DefaultVisibility = True;
	OptionDetails.Purpose = Enums.ReportOptionPurposes.ForSmartphones;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
