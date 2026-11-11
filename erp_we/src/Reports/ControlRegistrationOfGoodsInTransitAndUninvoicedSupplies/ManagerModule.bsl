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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ControlRegistrationOfGoodsInTransitAndUninvoicedSupplies);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Những hàng hóa nào đang đi đường?
		|Những mặt hàng nào đã tiếp nhận vào kho mà chưa có hóa đơn?
		|Những mặt hàng nào đang đi đường hoặc hàng hóa chưa có hóa đơn mà cần lập tờ khai hải quan nhập khẩu?';
		|ru = 'Какие товары находятся в пути?
		|Какие товары поступили на склад неотфактурованными?
		|По каким товарам в пути или неотфактурованным товарам, необходимо оформить таможенную декларацию на импорт?';
		|en = 'Check which goods are in transit.
		|Check which goods received were not invoiced.
		|Check which goods in transit or not invoiced goods require customs import declarations.'; fa = 'Check which goods are in transit.
		|Check which goods received were not invoiced.
		|Check which goods in transit or not invoiced goods require customs import declarations.';
		|it = 'Какие товары находятся в пути?
		|Какие товары поступили на склад неотфактурованными?
		|По каким товарам в пути или неотфактурованным товарам, необходимо оформить таможенную декларацию на импорт?';
		|pl = 'Jakie wiersze pozycji znajdują się w drodze? 
		|Jakie wiersze pozycji wpłynęły do magazynu jako niefakturowane? 
		|Według jakich towarów w drodze lub niefakturowanych towarów, należy sporządzić deklarację celną na import?';
		|tr = 'Hangi ürünler transit halindedir?
		|Hangi ürünler faturasız olarak ambara girdi?
		|Hangi transit ürünler veya faturasız ürünler için ithalat gümrük beyannamesi gerekir?'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ControlRegistrationOfGoodsInTransitAndUninvoicedSupplies");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
