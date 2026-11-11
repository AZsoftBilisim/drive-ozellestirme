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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.GrossProfitByPaidCustomerInvoices);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	TMReportOptionsOverridable.SetImportanceOfReportOption(OptionDetails, "Important");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "GrossProfitOnFullyPaidShipments");
	OptionDetails.LongDesc = NStr("vi = 'Những bộ phận và người bán hàng nào mang lại doanh thu cao nhất về mặt thanh toán?';
									|ru = 'Какие подразделения и менеджеры принесли более всего прибыли по оплате?';
									|en = 'Check which business units and sales persons generated more payment profit.'; fa = 'Check which business units and sales persons generated more payment profit.';
									|it = 'Какие подразделения и менеджеры принесли более всего прибыли по оплате?';
									|pl = 'Jakie działy i menedżery wyprodukowały najwięcej zysku z płatności?';
									|tr = 'Hangi departmanlar ve yöneticiler ödemede daha fazla kâr sağladı?'");
	OptionDetails.FunctionalOptions.Add("NotBaseVersion");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "GrossProfitOnFullyPaidShipmentsBasic");
	OptionDetails.LongDesc = NStr("vi = 'Những khách hàng nào đem lại lợi nhuận nhiều nhất?';
									|ru = 'Какие клиенты принесли более всего прибыли по оплате?';
									|en = 'Which customers generated more profit from payment?'; fa = 'Which customers generated more profit from payment?';
									|it = 'Какие клиенты принесли более всего прибыли по оплате?';
									|pl = 'Jakie klienty wyprodukowały najwięcej zysku z płatności?';
									|tr = 'Ödemelerden en fazla kârı hangi müşteriler getirdi?'");
	OptionDetails.FunctionalOptions.Add("BaseVersion");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "GrossProfitOnPartiallyPaidShipments");
	OptionDetails.LongDesc = NStr("vi = 'Những bộ phận và quản lý đã kiếm được nhiều lợi nhuận nhất khi thanh toán một phần?';
									|ru = 'Какие подразделения и менеджеры принесли более всего прибыли по частичной оплате?';
									|en = 'Check which business units and sales persons generated more partial payment profit.'; fa = 'Check which business units and sales persons generated more partial payment profit.';
									|it = 'Какие подразделения и менеджеры принесли более всего прибыли по частичной оплате?';
									|pl = 'Jakie działy i menedżery wyprodukowały najwięcej zysku z częściowej płatności?';
									|tr = 'Kısmi ödemeden en fazla kârı hangi departmanlar ve yöneticiler getirdi?'");
	OptionDetails.FunctionalOptions.Add("NotBaseVersion");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "GrossProfitOnPartiallyPaidShipmentsBasic");
	OptionDetails.LongDesc = NStr("vi = 'Những khách hàng nào mang lại lợi nhuận cao nhất khi thanh toán một phần?';
									|ru = 'Какие клиенты принесли более всего прибыли по частичной оплате?';
									|en = 'Which customers have generated more partial payment profit?'; fa = 'Which customers have generated more partial payment profit?';
									|it = 'Какие клиенты принесли более всего прибыли по частичной оплате?';
									|pl = 'Jakie klienty wyprodukowały najwięcej zysku z częściowej płatności?';
									|tr = 'Kısmi ödemeden en fazla kârı hangi müşteriler getirdi?'");
	OptionDetails.FunctionalOptions.Add("BaseVersion");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "GrossProfitOnFullyPaidShipmentsMobileClient");
	OptionDetails.LongDesc = NStr("vi = 'Những bộ phận và người bán hàng nào mang lại doanh thu cao nhất về mặt thanh toán?';
									|ru = 'Какие подразделения и менеджеры принесли более всего прибыли по оплате?';
									|en = 'Check which business units and sales persons generated more payment profit.'; fa = 'Check which business units and sales persons generated more payment profit.';
									|it = 'Какие подразделения и менеджеры принесли более всего прибыли по оплате?';
									|pl = 'Jakie działy i menedżery wyprodukowały najwięcej zysku z płatności?';
									|tr = 'Hangi departmanlar ve yöneticiler ödemede daha fazla kâr sağladı?'");
	OptionDetails.Description = NStr("vi = 'Lợi nhuận gộp theo các khoản thanh toán đầy đủ khi giao hàng (di động)';
									|ru = 'Валовая прибыль по полной оплате отгрузок (моб.)';
									|en = 'Gross profit by full shipment payment (mob. client)'; fa = 'سود ناخالص بر اساس پرداخت کامل ارسال (کلاینت موبایل)';
									|it = 'Валовая прибыль по полной оплате отгрузок (моб.)';
									|pl = 'Zysk brutto przy pełnej spłacie przesyłek (mob.)';
									|tr = 'Tam sevkiyat ödemesine göre brüt kâr (mob.)'");
	OptionDetails.DefaultVisibility = True;
	OptionDetails.Purpose = Enums.ReportOptionPurposes.ForSmartphones;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
