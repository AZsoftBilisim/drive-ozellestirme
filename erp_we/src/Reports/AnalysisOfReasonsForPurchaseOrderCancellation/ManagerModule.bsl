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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.AnalysisOfReasonsForPurchaseOrderCancellation);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Do những nguyên nhân nào mà các đơn hàng được thực hiện một phần hoặc không thực hiện toàn bộ?
		|Nhà cung cấp nào có nhiều đơn hàng đã thực hiện không đầy đủ?';
		|ru = 'По каким причинам чаще всего заказы выполняются частично или не выполняются полностью?
		|У каких поставщиков более всего выполненных не полностью заказов?';
		|en = 'Check the reasons why the orders are fulfilled partially or incompletely.
		|Verify which vendors have the highest number of partially fulfilled orders.'; fa = 'Check the reasons why the orders are fulfilled partially or incompletely.
		|Verify which vendors have the highest number of partially fulfilled orders.';
		|it = 'По каким причинам чаще всего заказы выполняются частично или не выполняются полностью?
		|У каких поставщиков более всего выполненных не полностью заказов?';
		|pl = 'Z jakich przyczyn zamówienia najczęściej są wykonywane częściowo lub nie wykonane w całości?
		| U jakich dostawców jest najwięcej zamówień nie wykonanych w całości?';
		|tr = 'Siparişlerin kısmen veya tamamen karşılanmamasının en yaygın nedenleri nelerdir?
		|En çok eksik siparişler hangi tedarikçilerde mevcuttur?'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "RatingOfReasonsForPurchaseOrderCancellation");
	OptionDetails.LongDesc = NStr("vi = 'Tỷ lệ nguyên nhân hủy bỏ đơn hàng từ phía chúng ta và từ phía nhà cung cấp.';
									|ru = 'Соотношение причин отмены с нашей стороны и со стороны поставщика.';
									|en = 'Ratio of cancellation reasons from our side and vendor side.'; fa = 'Ratio of cancellation reasons from our side and vendor side.';
									|it = 'Соотношение причин отмены с нашей стороны и со стороны поставщика.';
									|pl = 'Współczynnik przyczyn anulowania z naszej strony i ze strony dostawcy.';
									|tr = 'Bizim tarafımızdan tedarikçi tarafına iptal nedenlerinin oranı.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "StatisticsOnCancellationsOfOrdersToSuppliers");
	OptionDetails.LongDesc = NStr("vi = 'Tỷ lệ các dòng đặt hàng và hủy bỏ trong đơn hàng đặt nhà cung cấp.';
									|ru = 'Соотношение заказанных и отмененных строк в заказах поставщикам.';
									|en = 'Ratio of ordered and canceled lines in purchase orders.'; fa = 'Ratio of ordered and canceled lines in purchase orders.';
									|it = 'Соотношение заказанных и отмененных строк в заказах поставщикам.';
									|pl = 'Współczynnik zamówionych i anulowanych wierszy w zamówieniach zakupu.';
									|tr = 'Satın alma siparişlerinde sipariş edilen ve iptal edilen satırların oranı.'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
