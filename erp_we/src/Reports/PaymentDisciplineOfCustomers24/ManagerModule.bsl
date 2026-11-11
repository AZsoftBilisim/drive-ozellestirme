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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.PaymentDisciplineOfCustomers24);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Bao lâu, trong bao nhiêu ngày và khách hàng nào trì hoãn thanh toán?';
									|ru = 'Как часто, на сколько дней и какие клиенты задерживают оплаты?';
									|en = 'How often, for how many days and which customers delay payment?'; fa = 'How often, for how many days and which customers delay payment?';
									|it = 'Как часто, на сколько дней и какие клиенты задерживают оплаты?';
									|pl = 'Jak często, na ile dni i jakie klienty opóźniają płatności?';
									|tr = 'Ne sıklıkta, kaç gün ve hangi müşteriler ödemelerini geciktiriyor?'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "PaymentDisciplineOfCustomers");
	OptionDetails.LongDesc = NStr("vi = 'Kiểm soát công nợ quá hạn của khách hàng trong kỳ đã chọn.
		|Khách hàng thường trì hoãn thanh toán không, trì hoãn bao nhiêu ngày và có những khách hàng nào như vậy?';
		|ru = 'Контроль просроченной задолженности у клиентов в течении выбранного периода.
		|Как часто, на сколько дней и какие клиенты задерживают оплаты?';
		|en = 'Control total receivables overdue within the selected period.
		|Check how often, for how many days and which customers delay payments.'; fa = 'Control total receivables overdue within the selected period.
		|Check how often, for how many days and which customers delay payments.';
		|it = 'Контроль просроченной задолженности у клиентов в течении выбранного периода.
		|Как часто, на сколько дней и какие клиенты задерживают оплаты?';
		|pl = 'Kontrola przeterminowanych długów u klientów w ciągu wybranego okresu. 
		|Jak często, na ile dni i jakie klienty opóźniają płatności?';
		|tr = 'Seçilen dönemde müşterilerin vadesi geçmiş borçlarının kontrolü.
		|Ne sıklıkta, kaç gün ve hangi müşteriler ödemelerini geciktiriyor?'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
