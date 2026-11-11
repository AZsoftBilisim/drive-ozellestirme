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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.RevenueAndCOGSFromRetail);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích tài chính bán lẻ
		|theo bộ phận (cửa hàng), kho bãi và nhà cung cấp.';
		|ru = 'Финансовый анализ розничных продаж
		|по подразделениям (магазинам), складам и поставщикам.';
		|en = 'Financial analysis of retail sales 
		|by business units (stores), warehouses, and vendors'; fa = 'Financial analysis of retail sales 
		|by business units (stores), warehouses, and vendors';
		|it = 'Финансовый анализ розничных продаж
		|по подразделениям (магазинам), складам и поставщикам.';
		|pl = 'Analiza finansowa sprzedaży detalicznych 
		|według działów (sklepów), magazynów i dostawców.';
		|tr = 'Perakende satışların
		|departmanlara (mağazalara), ambarlara ve tedarikçilere göre finansal analizi.'");
	TMReportOptionsOverridable.SetImportanceOfReportOption(OptionDetails, "Important");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "DynamicsOfRetailSales");
	OptionDetails.LongDesc = NStr("vi = 'Khối lượng bán lẻ hàng tháng trong kỳ đã chọn.
		|Có thể phân tích theo kỳ - quý, tháng, tuần, ngày.';
		|ru = 'Помесячные объемы розничных продаж за выбранный период.
		|Возможен анализ по периодам - квартал, месяц, неделя, день.';
		|en = 'Monthly volume of retail sales for the selected period.
		|Analysis is available by the following periods - quarter, month, week, day.'; fa = 'Monthly volume of retail sales for the selected period.
		|Analysis is available by the following periods - quarter, month, week, day.';
		|it = 'Помесячные объемы розничных продаж за выбранный период.
		|Возможен анализ по периодам - квартал, месяц, неделя, день.';
		|pl = 'Miesięczne objętości sprzedaży detalicznych za wybrany okres. 
		|Jest możliwa analiza według okresów - kwartał, miesiąc, tydzień, dzień.';
		|tr = 'Seçilen dönem için aylık perakende satış hacimleri.
		|Dönemlere göre analiz mümkündür; çeyrek, ay, hafta, gün.'");
	OptionDetails.FunctionalOptions.Add("NotUseBusinessRegions");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "DynamicsOfRetailSalesBusinessRegions");
	OptionDetails.LongDesc = NStr("vi = 'Khối lượng bán lẻ hàng tháng trong kỳ đã chọn.
		|Có thể phân tích theo kỳ - quý, tháng, tuần, ngày.';
		|ru = 'Помесячные объемы розничных продаж за выбранный период.
		|Возможен анализ по периодам - квартал, месяц, неделя, день.';
		|en = 'Monthly volume of retail sales for the selected period.
		|Analysis is available by the following periods - quarter, month, week, day.'; fa = 'Monthly volume of retail sales for the selected period.
		|Analysis is available by the following periods - quarter, month, week, day.';
		|it = 'Помесячные объемы розничных продаж за выбранный период.
		|Возможен анализ по периодам - квартал, месяц, неделя, день.';
		|pl = 'Miesięczne objętości sprzedaży detalicznych za wybrany okres. 
		|Jest możliwa analiza według okresów - kwartał, miesiąc, tydzień, dzień.';
		|tr = 'Seçilen dönem için aylık perakende satış hacimleri.
		|Dönemlere göre analiz mümkündür; çeyrek, ay, hafta, gün.'");
	OptionDetails.FunctionalOptions.Add("UseBusinessRegions");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "RetailSalesByDivision");
	OptionDetails.LongDesc = NStr("vi = 'Cửa hàng nào đem lại lợi nhuận cao nhất?';
									|ru = 'Какие магазины принесли более всего валовой прибыли?';
									|en = 'Verify which stores generated more gross profit.'; fa = 'Verify which stores generated more gross profit.';
									|it = 'Какие магазины принесли более всего валовой прибыли?';
									|pl = 'Jakie sklepy wyprodukkowały największy zysk brutto?';
									|tr = 'En çok brüt kârı hangi mağazalar getirdi?'");
	TMReportOptionsOverridable.SetImportanceOfReportOption(OptionDetails, "Important");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "RetailSalesBySupplier");
	OptionDetails.LongDesc = NStr("vi = 'Hàng hóa đã nhận từ những nhà cung cấp nào
		|có lợi nhuận gộp lớn nhất trong bán lẻ?';
		|ru = 'По товарам от каких поставщиков получена
		|наибольшая валовая прибыль при розничных продажах?';
		|en = 'Check goods of which vendors generated 
		|the biggest gross profit from retail sales.'; fa = 'Check goods of which vendors generated 
		|the biggest gross profit from retail sales.';
		|it = 'По товарам от каких поставщиков получена
		|наибольшая валовая прибыль при розничных продажах?';
		|pl = 'Według towarów od jakich dostawców otrzymany 
		|największy zysk brutto przy sprzedaży detalicznej?';
		|tr = 'Perakende satışlarda
		|en yüksek brüt kârı hangi tedarikçiler sağlıyor?'");
	OptionDetails.FunctionalOptions.Add("GenerateInventoryOwnerAttributesByVendors");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
