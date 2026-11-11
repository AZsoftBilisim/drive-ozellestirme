// @strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//   ReportSettings - See ReportsOptions.DescriptionOfReport.
//
Procedure CustomizeReportOptions(Settings, ReportSettings) Export
	
	ReportSettings = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.TripRoute);
	ReportSettings.FunctionalOptions.Add("NotUseDeliveryManagement20");
	ReportSettings.DefineFormSettings = True;
	ReportsOptions.SetOutputModeInReportPanels(Settings, ReportSettings, False);
	TMReportOptionsOverridable.DisableReport(ReportSettings);
	
EndProcedure

#EndRegion

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//   VariantKey - String - 
//   
//	Returns:
//		ValueTableRow - description of the created team.
//
Function AddReportCommand(ReportsCommands, Parameters, VariantKey = "") Export
	
	ReportCommand = Undefined;
	
	If AccessRight("View", Metadata.Reports.TripRoute) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.TripRoute.FullName();
		ReportCommand.Presentation = NStr("ru = 'Маршрут рейса';
											|vi = 'Trip route';
											|en = 'Trip route'; fa = 'مسیر سفر';
											|it = 'Trip route';
											|pl = 'Trip route';
											|tr = 'Sefer rotası'");
		ReportCommand.MultipleChoice = False;
		ReportCommand.IsNonContextual = False;
		ReportCommand.WriteMode = "Post";
		ReportCommand.FunctionalOptions = "NotUseDeliveryManagement20";
		ReportCommand.Importance = "Ordinary";
		
	EndIf;
	
	Return ReportCommand;
	
EndFunction

#EndRegion

#EndRegion

#EndIf