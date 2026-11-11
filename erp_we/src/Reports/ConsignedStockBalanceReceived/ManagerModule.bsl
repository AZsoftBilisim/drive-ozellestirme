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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ConsignedStockBalanceReceived);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Đã tiếp nhận từ người đặt ký gửi bao nhiêu hàng hóa, những mặt hàng nào và đơn giá nào?';
									|ru = 'Сколько, каких товаров от комитентов и по какой цене?';
									|en = 'Verify how many and which consignor goods are received and at what price.'; fa = 'Verify how many and which consignor goods are received and at what price.';
									|it = 'Сколько, каких товаров от комитентов и по какой цене?';
									|pl = 'Ile, jakich towarów od komitentów i według jakiej ceny?';
									|tr = 'Göndericilerden kaç adet, hangi ürünler ve hangi fiyata gelmektedir?'");
	OptionDetails.FunctionalOptions.Add("UsePurchaseCommission");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ConsignedStockBalanceReceived");
	OptionDetails.LongDesc = NStr("vi = 'Có những hàng hóa nào và bao nhiêu hàng hóa đã nhận từ người đặt ký gửi và đơn giá là bao nhiêu?
		|Hàng hóa đã được tiếp nhận ký gửi khi nào?';
		|ru = 'Сколько, каких товаров от комитентов и по какой цене?
		|Когда товары были приняты на комиссию?';
		|en = 'Verify how many goods and which of them are received from consignors, and at what price. 
		|Check when goods were received by consignees.'; fa = 'Verify how many goods and which of them are received from consignors, and at what price. 
		|Check when goods were received by consignees.';
		|it = 'Сколько, каких товаров от комитентов и по какой цене?
		|Когда товары были приняты на комиссию?';
		|pl = 'Ile, jakich towarów od komitentów i według jakiej ceny?
		| Kiedy wiersze pozycji zostały przyjęty do komisu?';
		|tr = 'Göndericilerden kaç adet, hangi ürünler ve hangi fiyata gelmektedir?
		|Ürünler ne zaman komisyon için kabul edilmiştir?'");
	OptionDetails.FunctionalOptions.Add("UsePurchaseCommission");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
