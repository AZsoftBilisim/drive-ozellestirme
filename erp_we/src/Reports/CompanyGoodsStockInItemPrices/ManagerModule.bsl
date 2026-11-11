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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.CompanyGoodsStockInItemPrices);
	DescriptionOfReport.DefineFormSettings = True;
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích sự luân chuyển và định giá hàng hóa trong kho và doanh nghiệp theo dạng giá.';
									|ru = 'Анализ движений и оценка стоимости товаров на складах и организациях по виду цен.';
									|en = 'Movement analysis and valuation of goods in warehouses and companies by the price type.'; fa = 'Movement analysis and valuation of goods in warehouses and companies by the price type.';
									|it = 'Анализ движений и оценка стоимости товаров на складах и организациях по виду цен.';
									|pl = 'Analiza ruchu i wycena towarów w magazynach i firmach według rodzaju cen.';
									|tr = 'Ambar ve iş yerlerine akış analizi ve fiyat türüne göre ürün maliyetinin değerlendirilmesi.'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "CompanyGoodsStockInItemPrices");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích biến động và đánh giá giá trị hàng hóa trong kho và doanh nghiệp theo dạng giá.
									|Trong doanh nghiệp nào, kho bãi nào có hàng hóa và giá trị là bao nhiêu?';
									|ru = 'Анализ движений и оценка стоимости товаров на складах и организациях по виду цен.
									|В какой организации, по какому складу есть товар и какова его стоимость?';
									|en = 'Analyze movement and estimate the cost of goods in warehouses and companies by the price type.
									|Check in what company and in what warehouse there are goods and what its cost is.'; fa = 'Analyze movement and estimate the cost of goods in warehouses and companies by the price type.
									|Check in what company and in what warehouse there are goods and what its cost is.';
									|it = 'Анализ движений и оценка стоимости товаров на складах и организациях по виду цен.
									|В какой организации, по какому складу есть товар и какова его стоимость?';
									|pl = 'Analiza ruchu i wycena towarów w magazynach i firmach według rodzaju cen.
									|W której firmie, w którym magazynie jest produkt i jaka jest jego wartość?';
									|tr = 'Ürünlerin ambar ve iş yerlerindeki akışının analizi ve fiyat türüne göre maliyet değerlendirmesi.
									|Ürün hangi iş yerinde, hangi ambarda ve maliyeti nedir?'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "MovementOfGoodsTransferred");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích biến động và đánh giá giá trị hàng hóa đã chuyển vào cất giữ.
									|Những bạn hàng nào có hàng hóa của chúng ta và đánh giá giá trị hàng hóa đó?';
									|ru = 'Анализ движений и оценка стоимости переданных на хранение товаров.
									|У каких партнеров есть наш товар и какова его оценка стоимости?';
									|en = 'Analyze and estimate filled up VMI.
									|Check what partners have our goods and what its estimation is.'; fa = 'Analyze and estimate filled up VMI.
									|Check what partners have our goods and what its estimation is.';
									|it = 'Анализ движений и оценка стоимости переданных на хранение товаров.
									|У каких партнеров есть наш товар и какова его оценка стоимости?';
									|pl = 'Analiza ruchów i ocena kosztów wysłanych na składowanie towarów.
									|U jakich partnerów jest nasz produkt i jaka jest jego ocena kosztów?';
									|tr = 'Akış analizi ve ambar için transfer edilen ürünlerin değerinin değerlendirilmesi.
									|Ürünümüz hangi iş ortaklarında var ve tahmini değeri nedir?'");
	ReportSubsystem = Metadata.FindByFullName("Subsystem.Sales.Subsystem.RetailSales");
	OptionDetails.Location.Delete(ReportSubsystem);
	ReportSubsystem = Metadata.FindByFullName("Subsystem.Sales.Subsystem.WholesaleSalesInPastPeriods");
	OptionDetails.Location.Insert(ReportSubsystem);
	OptionDetails.FunctionalOptions.Add("UseTransferToCustodyWithRightOfSale");
	OptionDetails.DefaultVisibility = True;
	
	OptionDescription = NStr("vi = 'Hàng hóa được chuyển giao vào ký gửi theo đơn giá mặt hàng';
							|ru = 'Переданные на комиссию товары в ценах номенклатуры';
							|en = 'Valuation of consignment sales stock'; fa = 'ارزش‌گذاری موجودی فروش امانی';
							|it = 'Переданные на комиссию товары в ценах номенклатуры';
							|pl = 'Wydane do komisu towary w cenach produktów';
							|tr = 'Konsinye satış ürünlerinin fiyatları'");
	OptionDescription = ConsignmentSalesServer.AddCommissionPostfix25(OptionDescription);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "MovementOfGoodsTransferredToCommission25");
	OptionDetails.Description = OptionDescription;
	OptionDetails.LongDesc = NStr("vi = 'Phân tích biến động và đánh giá giá trị hàng hóa đã chuyển vào ký gửi.
									|Những bạn hàng nào có hàng hóa của chúng ta và đánh giá giá trị những hàng hóa đó?';
									|ru = 'Анализ движений и оценка стоимости переданных на комиссию товаров.
									|У каких партнеров есть наш товар и какова его оценка стоимости?';
									|en = 'Estimate the value of transferred consignment stock.
									|Check which partners have our stock and what its value is.'; fa = 'Estimate the value of transferred consignment stock.
									|Check which partners have our stock and what its value is.';
									|it = 'Анализ движений и оценка стоимости переданных на комиссию товаров.
									|У каких партнеров есть наш товар и какова его оценка стоимости?';
									|pl = 'Analiza ruchów i ocena wartości przekazanych do komisu towarów.
									|Kto z partnerów ma nasz towar i jaka jest jego ocena wartości?';
									|tr = 'Akış analizi ve komisyon için transfer edilen ürünlerin değerinin değerlendirilmesi.
									|Ürünlerimiz hangi iş ortaklarında var ve tahmini değeri nedir?'");
	OptionDetails.FunctionalOptions.Add("UseSalesCommission");
	ReportSubsystem = Metadata.FindByFullName("Subsystem.Sales.Subsystem.RetailSales");
	OptionDetails.Location.Delete(ReportSubsystem);
	ReportSubsystem = Metadata.FindByFullName("Subsystem.Sales.Subsystem.ConsignmentSales");
	OptionDetails.Location.Insert(ReportSubsystem);
	OptionDetails.DefaultVisibility = True;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
