#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
//  - ValueTableRow
//  - Undefined
//
Function AddReportCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.ProductionPlanProductsAndSemiFinishedProducts) 
			And GetFunctionalOption("UseProductionPlanning") Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.ProductionPlanProductsAndSemiFinishedProducts.FullName();
		ReportCommand.Presentation = NStr("vi = 'Kế hoạch sản xuất sản phẩm và bán thành phẩm';
											|ru = 'План производства продукции и полуфабрикатов';
											|en = 'Production plan for products and semi-finished products'; fa = 'برنامه تولید برای محصولات و محصولات نیمه‌ساخته';
											|it = 'Piano di produzione degli articoli e semi-lavorati';
											|pl = 'Plan wyprodukowania produkcji i półproduktów';
											|tr = 'İmal edilen ürünler ve yarı mamul ürünleri üretim planı'");
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.VariantKey = "ProductionPlanForProductsAndSemiFinishedProductsContext";
		
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
//   DisplayReportOptions - Boolean
//
Procedure CustomizeReportOptions(Settings, DisplayReportOptions) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ProductionPlanProductsAndSemiFinishedProducts);
	DescriptionOfReport.DefineFormSettings = True;
	ReportsOptions.SetOutputModeInReportPanels(Settings, DescriptionOfReport, DisplayReportOptions);
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ProductionPlanForProductsAndSemiFinishedProductsContext");
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf