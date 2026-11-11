//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Adds a report command to the list of commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// Returns:
//   ValueTableRow - new report command.
Function AddReportCommand(ReportsCommands) Export
	
	If AccessRight("View", Metadata.Reports.GoodsInStorageBins) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.GoodsInStorageBins.FullName();
		ReportCommand.Presentation = NStr("vi = 'Hàng hóa trong ô hàng';
											|ru = 'Товары в ячейках';
											|en = 'Goods in storage bins'; fa = 'کالاها در محل‌های نگهداری';
											|it = 'Merci nelle celle';
											|pl = 'Wiersze pozycji w komórkach';
											|tr = 'Hücrelerdeki ürünler'");
		
		
		ReportCommand.Importance = "Ordinary";
		ReportCommand.MultipleChoice = False;
		
		ReportCommand.AdditionalParameters.Insert("CommandName", "RemainingGoodsByShelfLives");
		
		ReportCommand.VariantKey = "ByProductContext";
		
		Return ReportCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Adds a report command to the list of commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// Returns:
//   ValueTableRow - new report command.
Function AddProductMovementReportCommand(ReportsCommands) Export
	
	If AccessRight("View", Metadata.Reports.GoodsInStorageBins) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.GoodsInStorageBins.FullName();
		ReportCommand.Presentation = NStr("vi = 'Biến động hàng hóa trong ô';
											|ru = 'Движения товара в ячейках';
											|en = 'Goods movements in bins'; fa = 'Goods movements in bins';
											|it = 'Movimenti delle merci nelle celle';
											|pl = 'Ruch towarów w komórkach';
											|tr = 'Hücrelerde ürün hareketi'");
		
		
		ReportCommand.Importance = "Ordinary";
		ReportCommand.MultipleChoice = False;
		
		ReportCommand.AdditionalParameters.Insert("CommandName", "RemainingGoodsByShelfLives");
		
		ReportCommand.VariantKey = "MovementOfGoodsInContextCell";
		
		Return ReportCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.GoodsInStorageBins);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Những hàng hóa nào đang được xếp vào ô hàng?';
									|ru = 'Какие товары размещены по складским ячейкам?';
									|en = 'Which goods are placed in the storage bins?'; fa = 'Which goods are placed in the storage bins?';
									|it = 'Какие товары размещены по складским ячейкам?';
									|pl = 'Jakie wiersze pozycji są rozmieszczone w komórkach magazynowych?';
									|tr = 'Ambar hücrelerine hangi ürünler yerleştirildi?'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "MovementOfGoodsInsideWarehouse");
	OptionDetails.LongDesc = NStr("vi = 'Những hàng hóa nào đang được xếp vào ô hàng?
		|Dự tính lấy ra trực tiếp hoặc xếp vào những mặt hàng nào?';
		|ru = 'Какие товары размещены по складским ячейкам?
		|Какие товары запланированы к непосредственной выемке или размещению?';
		|en = 'Items in storage bins.
		|Items in Pick lists and Put-away lists.'; fa = 'Items in storage bins.
		|Items in Pick lists and Put-away lists.';
		|it = 'Какие товары размещены по складским ячейкам?
		|Какие товары запланированы к непосредственной выемке или размещению?';
		|pl = 'Jakie wiersze pozycji są rozmieszczone w komórkach magazynowych?
		|Jakie wiersze pozycji są zaplanowane do bezpośredniego wyjęcia lub rozmieszczenia?';
		|tr = 'Ambar hücrelerine hangi ürünler yerleştirildi?
		|Derhal toplama veya yerleştirme için hangi ürünler planlandı?'");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "MovementOfGoodsInContextCell");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "MovementOfGoodsInBlockedCells");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ByProductContext");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ByStorageAreaContext");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ByWarehouseGroupOfProductRange");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ByCellContext");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
