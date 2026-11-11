#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// See ReportsOptionsOverridable.BeforeAddReportCommands.
Procedure BeforeAddReportCommands(ReportsCommands, Parameters, StandardProcessing) Export
	
	AddCommandsDemoScriptsOfObject(ReportsCommands);
	
EndProcedure

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ObjectDemoScenarios);
	DescriptionOfReport.Enabled = False;
	
EndProcedure

#EndRegion

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   
//	Returns:
//		ValueTableRow - description of the created team.
//
Function AddCommandsDemoScriptsOfObject(ReportsCommands) Export
	
	If AccessRight("View", Metadata.Reports.ObjectDemoScenarios)
		And GetFunctionalOption("UseDemoScenarios") Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.ObjectDemoScenarios.FullName();
		ReportCommand.Presentation = NStr("vi = 'Mô tả các quy trình';
											|ru = 'Описание процессов';
											|en = 'Process details'; fa = 'جزئیات فرایند';
											|it = 'Описание процессов';
											|pl = 'Process details';
											|tr = 'Süreç açıklaması'");
		
		ReportCommand.MultipleChoice = False; // FormCommand 
		ReportCommand["Importance"]        = "SeeAlso";
		
		Return ReportCommand;
		
	EndIf;

	Return Undefined;

EndFunction

#EndRegion

#EndIf