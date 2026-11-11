//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//   UseProduction - Boolean
//
Procedure CustomizeReportOptions(Settings, UseProduction) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ItemBatchMovement);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.FunctionalOptions.Add("UseItemsBatch");
	OptionDetails.DefaultVisibility = False;
	OptionDetails.LongDesc = ?(UseProduction,
									NStr("vi = 'Phân tích chi tiết biến động sê-ri hàng hóa trong kho và trong sản xuất.';
										|ru = 'Детальный анализ движения серии номенклатуры на складах и в производстве.';
										|en = 'Detailed analysis of movement of item batch in warehouses and production.'; fa = 'Detailed analysis of movement of item batch in warehouses and production.';
										|it = 'Детальный анализ движения серии номенклатуры на складах и в производстве.';
										|pl = 'Szczegółowa analiza przepływu serii produktów w magazynach i w produkcji.';
										|tr = 'Bir ürün partisinin ambarlarda ve üretimdeki akışının ayrıntılı analizi.'"),
									NStr("vi = 'Phân tích chi tiết biến động sê-ri mặt hàng trong kho.';
										|ru = 'Детальный анализ движения серии номенклатуры на складах.';
										|en = 'Detailed analysis of movement of item batch in warehouses.'; fa = 'Detailed analysis of movement of item batch in warehouses.';
										|it = 'Детальный анализ движения серии номенклатуры на складах.';
										|pl = 'Szczegółowa analiza przepływu serii produktów w magazynach.';
										|tr = 'Bir ürün partisinin ambarlardaki akışı.'"));
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ItemBatchMovement");
	OptionDetails.FunctionalOptions.Add("UseItemsBatch");
	OptionDetails.LongDesc = ?(UseProduction,
									NStr("vi = 'Phân tích chi tiết biến động sê-ri hàng hóa trong kho và trong sản xuất.';
										|ru = 'Детальный анализ движения серии номенклатуры на складах и в производстве.';
										|en = 'Detailed analysis of movement of item batch in warehouses and production.'; fa = 'Detailed analysis of movement of item batch in warehouses and production.';
										|it = 'Детальный анализ движения серии номенклатуры на складах и в производстве.';
										|pl = 'Szczegółowa analiza przepływu serii produktów w magazynach i w produkcji.';
										|tr = 'Bir ürün partisinin ambarlarda ve üretimdeki akışının ayrıntılı analizi.'"),
									NStr("vi = 'Phân tích chi tiết biến động sê-ri mặt hàng trong kho.';
										|ru = 'Детальный анализ движения серии номенклатуры на складах.';
										|en = 'Detailed analysis of movement of item batch in warehouses.'; fa = 'Detailed analysis of movement of item batch in warehouses.';
										|it = 'Детальный анализ движения серии номенклатуры на складах.';
										|pl = 'Szczegółowa analiza przepływu serii produktów w magazynach.';
										|tr = 'Bir ürün partisinin ambarlardaki akışı.'"));
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ProductSeriesMovementContext");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
