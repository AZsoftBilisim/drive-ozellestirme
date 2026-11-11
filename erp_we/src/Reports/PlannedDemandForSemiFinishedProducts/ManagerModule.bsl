#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
//  ValueTableRow, Undefined - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
Function AddReportCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.PlannedDemandForSemiFinishedProducts) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.PlannedDemandForSemiFinishedProducts.FullName();
		ReportCommand.Presentation = NStr("vi = 'Nhu cầu của bán thành phẩm';
											|ru = 'Потребность в полуфабрикатах';
											|en = 'Planned demand for semi-finished products'; fa = 'نیاز برنامه‌ریزی‌شده به محصولات نیمه‌ساخته';
											|it = 'Fabbisogno di semilavorati';
											|pl = 'Zapotrzebowanie w półproduktach';
											|tr = 'Yarı mamul ürünlere gereksinim'");
		
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.VariantKey = "PlannedDemandForSemiFinishedProductsContext";
		
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.PlannedDemandForSemiFinishedProducts);
	DescriptionOfReport.DefineFormSettings = True;
	ReportsOptions.SetOutputModeInReportPanels(Settings, DescriptionOfReport, DisplayReportOptions);
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "PlannedDemandForSemiFinishedProductsContext");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "DecodingContext");
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf