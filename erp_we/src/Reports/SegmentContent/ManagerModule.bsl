#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// Returns:
//   ValueTableRow - new report command.
Function AddReportCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.SegmentContent) 
			And (GetFunctionalOption("UseProductSegments")
				Or GetFunctionalOption("UsePartnersSegments")) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.SegmentContent.FullName();
		ReportCommand.Presentation = NStr("vi = 'Thành phần phân khúc';
											|ru = 'Состав сегмента';
											|en = 'Segment content'; fa = 'محتوای بخش';
											|it = 'Componenti del segmento';
											|pl = 'Skład segmentu';
											|tr = 'Segment içeriği'");
		
		ReportCommand.MultipleChoice = False;
		ReportCommand["Importance"]         = "Ordinary";
		ReportCommand.FunctionalOptions = "UseProductSegments,UsePartnersSegments";
		
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.SegmentContent);
	TMReportOptionsOverridable.DisableReport(DescriptionOfReport);
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf