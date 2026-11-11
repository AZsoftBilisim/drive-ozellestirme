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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.WarehouseStockInItemPrices);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích biến động và đánh giá giá trị hàng hóa trong kho theo dạng giá đã chọn.';
									|ru = 'Анализ движений и оценка стоимости товаров на складах по выбранному виду цен.';
									|en = 'Analyze transfer and estimate warehouse stock by the selected price type.'; fa = 'Analyze transfer and estimate warehouse stock by the selected price type.';
									|it = 'Анализ движений и оценка стоимости товаров на складах по выбранному виду цен.';
									|pl = 'Analiza przepływu i ocena wartości towarów w magazynach według wybranego rodzaju cen.';
									|tr = 'Seçilen fiyat türü için ambarlardaki hareketlerin analizi ve ürün maliyetinin değerlendirilmesi.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ListOfProductPrices");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích biến động và đánh giá giá trị hàng hóa trong kho theo dạng giá đã chọn.';
									|ru = 'Анализ движений и оценка стоимости товаров на складах по выбранному виду цен.';
									|en = 'Analyze transfer and estimate warehouse stock by the selected price type.'; fa = 'Analyze transfer and estimate warehouse stock by the selected price type.';
									|it = 'Анализ движений и оценка стоимости товаров на складах по выбранному виду цен.';
									|pl = 'Analiza przepływu i ocena wartości towarów w magazynach według wybranego rodzaju cen.';
									|tr = 'Seçilen fiyat türü için ambarlardaki hareketlerin analizi ve ürün maliyetinin değerlendirilmesi.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "EstimateStockBalance");
	OptionDetails.LongDesc = NStr("vi = 'Đánh giá giá trị số dư hàng hóa trong kho theo dạng giá được chọn.';
									|ru = 'Оценка стоимости остатков товаров на складах по выбранному виду цен.';
									|en = 'Warehouse stock valuation by the selected price type.'; fa = 'Warehouse stock valuation by the selected price type.';
									|it = 'Оценка стоимости остатков товаров на складах по выбранному виду цен.';
									|pl = 'Ocena wartości stanu magazynowego w magazynach według wybranego rodzaju cen.';
									|tr = 'Seçilen fiyat türü için ambarlardaki ürün bakiyesinin maliyetinin değerlendirilmesi.'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
