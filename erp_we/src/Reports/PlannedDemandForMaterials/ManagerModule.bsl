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

	If AccessRight("View", Metadata.Reports.PlannedDemandForMaterials) 
			And GetFunctionalOption("UseProductionPlanning") Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.PlannedDemandForMaterials.FullName();
		ReportCommand.Presentation = NStr("vi = 'Nhu cầu nguyên vật liệu';
											|ru = 'Потребность в материалах';
											|en = 'Planned demand for materials'; fa = 'نیاز برنامه‌ریزی‌شده به مواد';
											|it = 'Fabbisogno di materiali';
											|pl = 'Zapotrzebowanie na materiały';
											|tr = 'Malzeme ihtiyacı'");
		
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.VariantKey = "PlannedNeedForMaterialsContext";
		
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.PlannedDemandForMaterials);
	DescriptionOfReport.DefineFormSettings = True;
	ReportsOptions.SetOutputModeInReportPanels(Settings, DescriptionOfReport, DisplayReportOptions);
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "PlannedNeedForMaterialsContext");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "DecodingContext");
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf