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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ProductRangeCompleteness);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Trong danh điểm có vai trò gì, thời gian tồn tại trong danh điểm là bao lâu?';
									|ru = 'Какова роль, стадия жизни товара в ассортименте?';
									|en = 'Track the role, life cycle stage of goods in the product range.'; fa = 'Track the role, life cycle stage of goods in the product range.';
									|it = 'Какова роль, стадия жизни товара в ассортименте?';
									|pl = 'Jaka ról, stadium życia towaru w asortymencie?';
									|tr = 'Ürün gamındaki ürünün rolü, yaşam eğrisi nedir?'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ProductRangeCompleteness");
	OptionDetails.LongDesc = NStr("vi = 'Trong danh điểm có vai trò gì, thời gian tồn tại bao lâu?
		|Hàng hóa được phép trong các khuôn dạng cửa hàng nào và đơn giá như thế nào?';
		|ru = 'Какова роль, стадия жизни товара в ассортименте?
		|В каких форматах магазинов товар представлен и по какой цене?';
		|en = 'Track the role, life cycle stage of goods in the product range.
		|Check the retail formats and price of the goods.'; fa = 'Track the role, life cycle stage of goods in the product range.
		|Check the retail formats and price of the goods.';
		|it = 'Какова роль, стадия жизни товара в ассортименте?
		|В каких форматах магазинов товар представлен и по какой цене?';
		|pl = 'Jaka ról, stadium życia towaru w asortymencie? 
		|W jakich formatach sklepów towar jest przedstawiony i według jakiej ceny?';
		|tr = 'Ürün gamındaki ürünün rolü, yaşam eğrisi nedir?
		|Ürün hangi mağaza formatlarında ve hangi fiyata sunulmaktadır?'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
