#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
//  Undefined, ValueTableRow - report command
Function AddReportCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.ARAPAccountingStatementByReturnablePackagingProvided) 
			And GetFunctionalOption("UseReusablePackage") Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.ARAPAccountingStatementByReturnablePackagingProvided.FullName();
		ReportCommand.Presentation = NStr("vi = 'Thẻ hạch toán theo bao bì';
											|ru = 'Карточка расчетов по таре';
											|en = 'Package settlement card'; fa = 'Package settlement card';
											|it = 'Carta di pagamento per imballaggio';
											|pl = 'Karta rozliczeń dla pojemników';
											|tr = 'Ambalaj mutabakat kartı'");
		
		ReportCommand.MultipleChoice = True;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.FunctionalOptions = "UseReusablePackage";
		
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ARAPAccountingStatementByReturnablePackagingProvided);
	DescriptionOfReport.DefineFormSettings = True;
	TMReportOptionsOverridable.DisableReport(DescriptionOfReport);
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf