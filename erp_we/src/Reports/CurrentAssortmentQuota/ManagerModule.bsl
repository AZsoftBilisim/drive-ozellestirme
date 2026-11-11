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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.CurrentAssortmentQuota);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Thành phần và khối lượng hạn ngạch trong danh điểm hàng hóa.';
									|ru = 'Состав и объемы квот товаров ассортимента.';
									|en = 'Content and volume of product range quotas.'; fa = 'Content and volume of product range quotas.';
									|it = 'Состав и объемы квот товаров ассортимента.';
									|pl = 'Skład i objętości kwot towarów asortymentu.';
									|tr = 'Ürün gamı kotasının içeriği ve hacimleri.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "PresenceOfBrandInCategories");
	OptionDetails.LongDesc = NStr("vi = 'Các thể loại hàng hóa nào có nhãn hiệu khác nhau?';
									|ru = 'В каких категориях товаров присутствуют различные марки?';
									|en = 'Check in which product categories various brands exist.'; fa = 'Check in which product categories various brands exist.';
									|it = 'В каких категориях товаров присутствуют различные марки?';
									|pl = 'W jakich kategoriach towarów są różne marki?';
									|tr = 'Hangi ürün kategorilerinde farklı markalar vardır?'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "CurrentAssortmentQuota");
	OptionDetails.LongDesc = NStr("vi = 'Hạn ngạch nào áp dụng cho các sản phẩm đối với khuôn dạng cửa hàng khác nhau?';
									|ru = 'Какие квоты действуют на товары для различных форматов магазинов?';
									|en = 'Check which quotas for goods are valid for different retail formats.'; fa = 'Check which quotas for goods are valid for different retail formats.';
									|it = 'Какие квоты действуют на товары для различных форматов магазинов?';
									|pl = 'Jakie kwoty obowiązują dla towarów dla różnych formatów sklepów?';
									|tr = 'Farklı mağaza biçimleri için ürünlere ilişkin hangi kotalar geçerlidir?'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
