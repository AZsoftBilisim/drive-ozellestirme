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

	If AccessRight("View", Metadata.Reports.SaleContent) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.SaleContent.FullName();
		ReportCommand.Presentation = NStr("vi = 'Thành phần bán hàng';
											|ru = 'Состав продажи';
											|en = 'Sale content'; fa = 'محتوای فروش';
											|it = 'Componenti della vendita';
											|pl = 'Skład sprzedaży';
											|tr = 'Satış kompozisyonu'");
		
		ReportCommand.MultipleChoice = False;
		ReportCommand["Importance"]  = "Ordinary";
		ReportCommand.VariantKey = "SaleContent";
		
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.SaleContent);
	DescriptionOfReport.DefineFormSettings = True;
	TMReportOptionsOverridable.DisableReport(DescriptionOfReport);
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf