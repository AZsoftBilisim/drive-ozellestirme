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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.CashTransactionControl);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Kiểm soát tính chính xác của giao dịch với vốn bằng tiền:
		|- người nhận tạm ứng,
		|- giao dịch với thẻ thanh toán,
		|- đổi tiền,
		| - điều chuyển nội bộ giữa các doanh nghiệp,
		|- điều chuyển giữa các doanh nghiệp.';
		|ru = 'Контроль корректности операций с денежными средствами:
		|- подотчетные лица,
		|- эквайринг (операции с платежными картами),
		|- конвертация валют,
		|- перемещения внутри организации,
		|- перемещения между организациями.';
		|en = 'Control accuracy of cash transactions:
		|- advance holders,
		|- acquiring (payment card transactions),
		|- currency conversion,
		|- transfers inside the company,
		|- transfers between companies.'; fa = 'Control accuracy of cash transactions:
		|- advance holders,
		|- acquiring (payment card transactions),
		|- currency conversion,
		|- transfers inside the company,
		|- transfers between companies.';
		|it = 'Контроль корректности операций с денежными средствами:
		|- подотчетные лица,
		|- эквайринг (операции с платежными картами),
		|- конвертация валют,
		|- перемещения внутри организации,
		|- перемещения между организациями.';
		|pl = 'Kontrola poprawności operacji ze środkami pieniężnymi-gotówką: 
		|- zaliczkobiorca,
		|- acquiring (operacje z kartami płatniczymi),
		|- konwersja walut,
		|- przemieszczenia wewnątrz firmy,
		|- przemieszczenia między firmami.';
		|tr = 'Nakit işlemlerinin doğruluğu üzerinde kontrol:
		|- sorumlu kişiler,
		|- PoS bankacılık (ödeme kartlarıyla yapılan işlemler),
		|- para birimi dönüştürücü,
		|- iş yeri içindeki hareketler,
		|- iş yerleri arasındaki hareketler.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "CashTransactionControl");
	OptionDetails.LongDesc = NStr("vi = 'Kiểm soát tổng hợp tính chính xác các giao dịch vốn bằng tiền.';
									|ru = 'Сводный контроль корректности операций с денежными средствами.';
									|en = 'Control the accuracy of cash transactions.'; fa = 'Control the accuracy of cash transactions.';
									|it = 'Сводный контроль корректности операций с денежными средствами.';
									|pl = 'Skonsolidowana kontrola poprawności operacji ze środkami pieniężnymi-gotówką.';
									|tr = 'Nakit işlemlerin doğruluğu üzerinde özet kontrol.'");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ControlOfAdvanceHoldersCash");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ControlOfCashTransactionsMobileClient");
	OptionDetails.LongDesc = NStr("vi = 'Kiểm soát tổng hợp tính chính xác các giao dịch vốn bằng tiền.';
									|ru = 'Сводный контроль корректности операций с денежными средствами.';
									|en = 'Control the accuracy of cash transactions.'; fa = 'Control the accuracy of cash transactions.';
									|it = 'Сводный контроль корректности операций с денежными средствами.';
									|pl = 'Skonsolidowana kontrola poprawności operacji ze środkami pieniężnymi-gotówką.';
									|tr = 'Nakit işlemlerin doğruluğu üzerinde özet kontrol.'");
	OptionDetails.Description = NStr("vi = 'Kiểm soát các giao dịch tiền mặt, tiền gửi (di động)';
									|ru = 'Контроль операций с денежными средствами (моб.)';
									|en = 'Cash transaction control (mob. client)'; fa = 'کنترل تراکنش نقدی (کلاینت موبایل)';
									|it = 'Контроль операций с денежными средствами (моб.)';
									|pl = 'Kontrola operacji ze środkami pieniężnymi (mob.)';
									|tr = 'Nakit işlemlerinin kontrolü (mob.)'");
	OptionDetails.DefaultVisibility = True;
	OptionDetails.Purpose = Enums.ReportOptionPurposes.ForSmartphones;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
