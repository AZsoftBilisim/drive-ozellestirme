#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// 
// Returns:
//   ValueTableRow - description of the report command
//
Function AddReportCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.PartnersSegmentOverlaps) 
			And GetFunctionalOption("UsePartnersSegments") Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.PartnersSegmentOverlaps.FullName();
		ReportCommand.Presentation = NStr("vi = 'Giao thoa giữa các phân khúc';
											|ru = 'Пересечения сегмента';
											|en = 'Segment overlaps'; fa = 'Segment overlaps';
											|it = 'Sovrapposizioni del segmento';
											|pl = 'Przecięcie segmentu';
											|tr = 'Segment kesişimleri'");
		
		ReportCommand.MultipleChoice = False;
		ReportCommand["Importance"] = "SeeAlso";
		
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.PartnersSegmentOverlaps);
	DescriptionOfReport.DefineFormSettings = True;
	TMReportOptionsOverridable.DisableReport(DescriptionOfReport);
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf