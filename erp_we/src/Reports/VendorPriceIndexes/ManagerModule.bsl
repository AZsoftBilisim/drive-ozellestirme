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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.VendorPriceIndexes);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Đánh giá hiệu quả của việc hạn chế giá mua
		|mà có tính đến đơn giá của nhà cung cấp riêng.';
		|ru = 'Оценка эффективности сдерживания закупочных цен
		|с учетом цен отдельных поставщиков.';
		|en = 'Estimate purchasing price regulation effectiveness
		|considering prices of certain vendors.'; fa = 'Estimate purchasing price regulation effectiveness
		|considering prices of certain vendors.';
		|it = 'Оценка эффективности сдерживания закупочных цен
		|с учетом цен отдельных поставщиков.';
		|pl = 'Ocena efektywności utrzymywania cen zakupu 
		|z ewidencją cen oddzielnych dostawców.';
		|tr = 'Farklı tedarikçilerin fiyatları dikkate alınarak
		|alım fiyatlarını sınırlandırma etkinliğinin değerlendirilmesi.'");
	OptionDetails.FunctionalOptions.Add("GenerateInventoryOwnerAttributesByVendors");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "VendorPriceIndexes");
	OptionDetails.LongDesc = NStr("vi = 'Đánh giá hiệu quả của việc hạn chế giá mua
		|mà có tính đến đơn giá của nhà cung cấp riêng.';
		|ru = 'Оценка эффективности сдерживания закупочных цен
		|с учетом цен отдельных поставщиков.';
		|en = 'Estimate purchasing price regulation effectiveness
		|considering prices of certain vendors.'; fa = 'Estimate purchasing price regulation effectiveness
		|considering prices of certain vendors.';
		|it = 'Оценка эффективности сдерживания закупочных цен
		|с учетом цен отдельных поставщиков.';
		|pl = 'Ocena efektywności utrzymywania cen zakupu 
		|z ewidencją cen oddzielnych dostawców.';
		|tr = 'Farklı tedarikçilerin fiyatları dikkate alınarak
		|alım fiyatlarını sınırlandırma etkinliğinin değerlendirilmesi.'");
	OptionDetails.FunctionalOptions.Add("GenerateInventoryOwnerAttributesByVendors");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
