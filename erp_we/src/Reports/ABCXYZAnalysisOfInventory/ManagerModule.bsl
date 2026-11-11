#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// Returns:
//  ValueTableRow, Undefined - description of the added command.
Function AddReportCommand(ReportsCommands) Export
	
	If AccessRight("View", Metadata.Reports.ABCXYZAnalysisOfInventory) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.ABCXYZAnalysisOfInventory.FullName();
		ReportCommand.Presentation = NStr("vi = 'Phân tích ABC/XYZ mặt hàng';
											|ru = 'ABC/XYZ-анализ номенклатуры';
											|en = 'ABC/XYZ analysis of inventory'; fa = 'تحلیل ABC/XYZ موجودی';
											|it = 'ABC/XYZ-analisi di nomenclatura';
											|pl = 'ABC/XYZ-аnaliza wykazu towarów';
											|tr = 'ABC/XYZ stok analizi'");
		
		ReportCommand.Handler = "ReportManagementTMClient.ABCXYZAnalysisOfInventory";
		
		
		ReportCommand.Importance = "Ordinary";
		ReportCommand.MultipleChoice = False;
		
		ReportCommand.AdditionalParameters.Insert("CommandName", "RemainingGoodsByShelfLives");
		
		ReportCommand.VariantKey =                    "ByProductContext";
		
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
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ABCXYZAnalysisOfInventory);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Những hàng hóa nào đang được bán ra tốt và ổn định? 
		|Những hàng hóa nào có tốc độ lưu chuyển thấp và bán ra không ổn định?';
		|ru = 'Какие товары хорошо и стабильно продаются? 
		|Какие имеют низкий товарооборот и продаются нестабильно?';
		|en = 'Track which goods are sold well and consistently.
		|Verify which goods are sold poorly and inconsistently.'; fa = 'Track which goods are sold well and consistently.
		|Verify which goods are sold poorly and inconsistently.';
		|it = 'Какие товары хорошо и стабильно продаются? 
		|Какие имеют низкий товарооборот и продаются нестабильно?';
		|pl = 'Jakie wiersze pozycji są sprzedawane dobrze i stabilnie? 
		|Jakie mają niski obrót towarowy i sprzedawane nie stabilnie?';
		|tr = 'Hangi ürünler iyi ve sabit olarak satılıyor? 
		|Hangilerinin ticari ciroları düşük, satışları istikrarsız?'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "InventoryByWarehouse");
	OptionDetails.LongDesc = NStr("vi = 'Những hàng hóa nào đang được bán ra tốt và ổn định? 
		|Những hàng hóa nào có tốc độ lưu chuyển thấp và bán ra không ổn định?';
		|ru = 'Какие товары хорошо и стабильно продаются? 
		|Какие имеют низкий товарооборот и продаются нестабильно?';
		|en = 'Track which goods are sold well and consistently.
		|Verify which goods are sold poorly and inconsistently.'; fa = 'Track which goods are sold well and consistently.
		|Verify which goods are sold poorly and inconsistently.';
		|it = 'Какие товары хорошо и стабильно продаются? 
		|Какие имеют низкий товарооборот и продаются нестабильно?';
		|pl = 'Jakie wiersze pozycji są sprzedawane dobrze i stabilnie? 
		|Jakie mają niski obrót towarowy i sprzedawane nie stabilnie?';
		|tr = 'Hangi ürünler iyi ve sabit olarak satılıyor? 
		|Hangilerinin ticari ciroları düşük, satışları istikrarsız?'");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ByProductContext");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf