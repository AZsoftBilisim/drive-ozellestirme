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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ItemPriceIndexes);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Đánh giá hiệu quả của việc hạn chế giá mua
		|mà không tính đến đơn giá của nhà cung cấp riêng.';
		|ru = 'Оценка эффективности сдерживания закупочных цен
		|без учета цен отдельных поставщиков.';
		|en = 'Estimate purchasing price regulation effectiveness 
		|not considering prices of certain vendors.'; fa = 'Estimate purchasing price regulation effectiveness 
		|not considering prices of certain vendors.';
		|it = 'Оценка эффективности сдерживания закупочных цен
		|без учета цен отдельных поставщиков.';
		|pl = 'Ocena efektywności utrzymywania cen zakupu 
		|bez ewidencji cen oddzielnych dostawców.';
		|tr = 'Farklı tedarikçilerin fiyatları dikkate alınmadan
		|alım fiyatlarını sınırlandırma etkinliğinin değerlendirilmesi.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ItemPriceIndexes");
	OptionDetails.LongDesc = NStr("vi = 'Đánh giá hiệu quả của việc hạn chế giá mua
		|mà không tính đến đơn giá của nhà cung cấp riêng.';
		|ru = 'Оценка эффективности сдерживания закупочных цен
		|без учета цен отдельных поставщиков.';
		|en = 'Estimate purchasing price regulation effectiveness 
		|not considering prices of certain vendors.'; fa = 'Estimate purchasing price regulation effectiveness 
		|not considering prices of certain vendors.';
		|it = 'Оценка эффективности сдерживания закупочных цен
		|без учета цен отдельных поставщиков.';
		|pl = 'Ocena efektywności utrzymywania cen zakupu 
		|bez ewidencji cen oddzielnych dostawców.';
		|tr = 'Farklı tedarikçilerin fiyatları dikkate alınmadan
		|alım fiyatlarını sınırlandırma etkinliğinin değerlendirilmesi.'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
