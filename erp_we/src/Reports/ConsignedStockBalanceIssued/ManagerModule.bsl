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
	
	PostfixCommissionSchemes = ConsignmentSalesServer.PostfixCommissionSchemes();
	OptionDescription = StringFunctionsClientServer.SubstituteParametersToString(
	NStr("vi = 'Số dư hàng hóa đã chuyển giao đi ký gửi (%1)';
		|ru = 'Остатки товаров, переданных на комиссию (%1)';
		|en = 'Remaining consignment stock (%1)'; fa = 'Remaining consignment stock (%1)';
		|it = 'Остатки товаров, переданных на комиссию (%1)';
		|pl = 'Remaining consignment stock (%1)';
		|tr = 'Konsinye stok bakiyesi (%1)'"),
	PostfixCommissionSchemes);
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ConsignedStockBalanceIssued);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.Description = OptionDescription;
	OptionDetails.LongDesc = NStr("vi = 'Đã tiếp nhận từ người đặt ký gửi bao nhiêu hàng hóa, những mặt hàng nào và đơn giá nào?';
									|ru = 'Сколько, каких товаров у комиссионеров и по какой цене?';
									|en = 'See how many goods and which of them are transferred to consignees, and at what price.'; fa = 'See how many goods and which of them are transferred to consignees, and at what price.';
									|it = 'Сколько, каких товаров у комиссионеров и по какой цене?';
									|pl = 'Ile, jakich towarów jest u komisantów i według jakiej ceny?';
									|tr = 'Kaç adet, hangi ürünler, hangi fiyattan konsinyede mevcut?'");
	OptionDetails.FunctionalOptions.Add("ConsignmentSaleIsUsed20");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ConsignedStockBalanceIssued");
	OptionDetails.Description = OptionDescription;
	OptionDetails.LongDesc = NStr("vi = 'Người nhận bán ký gửi có bao nhiêu hàng hóa, những hàng hóa nào và đơn giá là bao nhiêu?
		|Hàng hóa đã được chuyển giao vào ký gửi khi nào?';
		|ru = 'Сколько, каких товаров у комиссионеров и по какой цене?
		|Когда товары были переданы на комиссию?';
		|en = 'See how many goods and which of them are transferred to consignees, and at what price.
		|Track when goods were transferred to consignees.'; fa = 'See how many goods and which of them are transferred to consignees, and at what price.
		|Track when goods were transferred to consignees.';
		|it = 'Сколько, каких товаров у комиссионеров и по какой цене?
		|Когда товары были переданы на комиссию?';
		|pl = 'Ile, jakich towarów jest u komisantów i według jakiej ceny? 
		|Kiedy wiersze pozycji zostały przekazane do komisu?';
		|tr = 'Kaç adet, hangi ürünler, hangi fiyattan konsinyede mevcut? 
		|Ürünler konsinyeye ne zaman transfer edildi?'");
	OptionDetails.FunctionalOptions.Add("ConsignmentSaleIsUsed20");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
