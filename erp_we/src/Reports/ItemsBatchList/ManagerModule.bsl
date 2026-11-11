#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
//  Undefined
Function AddReportCommand(ReportsCommands) Export
	
	If AccessRight("View", Metadata.Reports.ItemsBatchList) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.ItemsBatchList.FullName();
		ReportCommand.Presentation = NStr("vi = 'Biến động theo sê-ri hàng hóa';
											|ru = 'Движения по сериям товара';
											|en = 'Movements by goods batch'; fa = 'جابه‌جایی‌ها بر اساس بچ کالا';
											|it = 'Movimenti secondo le serie della merce';
											|pl = 'Przepływy wg serii towarów';
											|tr = 'Ürün partisine göre hareket'");
		
		ReportCommand.Handler = "ReportManagementTMClient.StatementOfProductSeries_";
		
		
		ReportCommand.Importance = "Ordinary";
		ReportCommand.MultipleChoice = True;
		
		ReportCommand.AdditionalParameters.Insert("CommandName", "StatementOfProductSeries_");
		
		ReportCommand.VariantKey = "StatementOfProductSeries";
		
		Return ReportCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//   UseProduction - Boolean
//
Procedure CustomizeReportOptions(Settings, UseProduction) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ItemsBatchList);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.FunctionalOptions.Add("UseItemsBatch");
	OptionDetails.LongDesc = ?(UseProduction,
									NStr("vi = 'Phân tích tổng hợp biến động sê-ri mặt hàng trong kho và trong sản xuất.';
										|ru = 'Сводный анализ движения серии номенклатуры на складах и в производстве.';
										|en = 'Summary analysis of transfer of item batch across warehouses and production.'; fa = 'Summary analysis of transfer of item batch across warehouses and production.';
										|it = 'Сводный анализ движения серии номенклатуры на складах и в производстве.';
										|pl = 'Skonsolidowana analiza przepływu serii produktów w magazynach i w produkcji.';
										|tr = 'Ürün partisinin ambarlardaki ve üretimdeki hareketinin özet analizi.'"),
									NStr("vi = 'Phân tích tổng hợp biến động sê-ri mặt hàng trong kho.';
										|ru = 'Сводный анализ движения серии номенклатуры на складах.';
										|en = 'Summary analysis of transfer of item batch in warehouses.'; fa = 'Summary analysis of transfer of item batch in warehouses.';
										|it = 'Сводный анализ движения серии номенклатуры на складах.';
										|pl = 'Skonsolidowana analiza przepływu serii produktów w magazynach.';
										|tr = 'Ürün partisinin ambarlardaki hareketinin özet analizi.'"));
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ItemsBatchList");
	OptionDetails.FunctionalOptions.Add("UseItemsBatch");
	OptionDetails.LongDesc = ?(UseProduction,
									NStr("vi = 'Phân tích tổng hợp biến động sê-ri mặt hàng trong kho và trong sản xuất.';
										|ru = 'Сводный анализ движения серии номенклатуры на складах и в производстве.';
										|en = 'Summary analysis of transfer of item batch across warehouses and production.'; fa = 'Summary analysis of transfer of item batch across warehouses and production.';
										|it = 'Сводный анализ движения серии номенклатуры на складах и в производстве.';
										|pl = 'Skonsolidowana analiza przepływu serii produktów w magazynach i w produkcji.';
										|tr = 'Ürün partisinin ambarlardaki ve üretimdeki hareketinin özet analizi.'"),
									NStr("vi = 'Phân tích tổng hợp biến động sê-ri mặt hàng trong kho.';
										|ru = 'Сводный анализ движения серии номенклатуры на складах.';
										|en = 'Summary analysis of transfer of item batch in warehouses.'; fa = 'Summary analysis of transfer of item batch in warehouses.';
										|it = 'Сводный анализ движения серии номенклатуры на складах.';
										|pl = 'Skonsolidowana analiza przepływu serii produktów w magazynach.';
										|tr = 'Ürün partisinin ambarlardaki hareketinin özet analizi.'"));
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "StatementOfProductSeries");
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf