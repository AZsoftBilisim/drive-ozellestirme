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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.FulfillmentAnalysisOfProductRange);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Kiểm soát việc tuân thủ yêu cầu chính sách danh điểm.
		|Những hạn mức nào được ấn định cho hàng hóa? Những mặt hàng nào được trưng bày tại cửa hàng?';
		|ru = 'Контроль соблюдения требований ассортиментной политики.
		|Какие квоты назначены на товары? Какие товары представлены в магазинах?';
		|en = 'Control compliance with the requirements of the product range policy.
		|Check which quotas are set for the goods and what kind of goods are present in stores.'; fa = 'Control compliance with the requirements of the product range policy.
		|Check which quotas are set for the goods and what kind of goods are present in stores.';
		|it = 'Контроль соблюдения требований ассортиментной политики.
		|Какие квоты назначены на товары? Какие товары представлены в магазинах?';
		|pl = 'Kontrola przestrzegania wymagań polityki asortymentowej. 
		|Jakie kwoty są naznaczone na wiersze pozycji? Jakie wiersze pozycji są przedstawione w sklepach?';
		|tr = 'Ürün gamı politikasının gerekliliklerine uygunluğun izlenmesi.
		|Ürünlere hangi kotalar atanır? Mağazalarda hangi ürünler var?'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "FulfillmentAnalysisOfProductRange");
	OptionDetails.DefaultVisibility = True;
	OptionDetails.LongDesc = NStr("vi = 'Số lượng hàng hóa có tương ứng với hạn mức đã đặt hay không:
		|- theo cách nhập vào danh điểm,
		|- theo số lượng có sẵn tại cửa hàng?';
		|ru = 'Соответствует ли количество товаров установленным квотам:
		|- по вводу в ассортимент,
		|- по наличию в магазинах?';
		|en = 'Check if the goods quantity corresponds to the set quotas:
		|- by adding to product range;
		|- by availability in stores.'; fa = 'Check if the goods quantity corresponds to the set quotas:
		|- by adding to product range;
		|- by availability in stores.';
		|it = 'Соответствует ли количество товаров установленным квотам:
		|- по вводу в ассортимент,
		|- по наличию в магазинах?';
		|pl = 'Czy odpowiada ilość towarów ustalonym kwotom: 
		|- według wprowadzenia do asortymentu, 
		|- według dyspozycji w sklepie?';
		|tr = 'Ürünlerin miktarı belirlenen kotaları karşılıyor mu:
		|- ürün gamına girişe göre,
		|- mağazalardaki mevcudiyete göre?'");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ByCategoryContext");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
