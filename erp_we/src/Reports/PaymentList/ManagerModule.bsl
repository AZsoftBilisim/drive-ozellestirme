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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.PaymentList);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Danh sách thu và chi tiền dự tính.';
									|ru = 'Реестр запланированных поступлений и списаний денежных средств.';
									|en = 'View planned cash inflows and outflows.'; fa = 'View planned cash inflows and outflows.';
									|it = 'Реестр запланированных поступлений и списаний денежных средств.';
									|pl = 'Rejestr zaplanowanych wpłat i rozchodów środków pieniężnych-gotówki.';
									|tr = 'Planlanan nakit girişinin ve gider yazılmasının kaydı.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "PaymentRequests");
	OptionDetails.LongDesc = NStr("vi = 'Danh sách giấy đề nghị đã duyệt cần thanh toán.';
									|ru = 'Реестр заявок, утвержденных к оплате.';
									|en = 'Registry of requests confirmed for payment.'; fa = 'Registry of requests confirmed for payment.';
									|it = 'Реестр заявок, утвержденных к оплате.';
									|pl = 'Rejestr wniosków, zatwierdzonych do płatności.';
									|tr = 'Ödeme için onaylanan taleplerin kaydı.'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
