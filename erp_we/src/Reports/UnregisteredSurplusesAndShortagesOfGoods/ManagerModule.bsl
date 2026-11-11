#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// Returns:
//   ValueTableRow - new report command.
Function AddDesignCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.UnregisteredSurplusesAndShortagesOfGoods) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.UnregisteredSurplusesAndShortagesOfGoods.FullName();
		ReportCommand.Presentation = NStr("vi = 'Lập';
											|ru = 'Оформление';
											|en = 'Stock discrepancies'; fa = 'Stock discrepancies';
											|it = 'Formalizzazione';
											|pl = 'Stock discrepancies';
											|tr = 'Düzenleme'");
		
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Important";
		ReportCommand.VariantKey = "RegistrationOfSurplusShortagesContext";
		
		Return ReportCommand;
		
	EndIf;

	Return Undefined;

EndFunction

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// Returns:
//   ValueTableRow - new report command.
Function AddMakeRecalculationCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.UnregisteredSurplusesAndShortagesOfGoods) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.UnregisteredSurplusesAndShortagesOfGoods.FullName();
		ReportCommand.Presentation = NStr("vi = 'Lập';
											|ru = 'Оформление';
											|en = 'Stock discrepancies'; fa = 'Stock discrepancies';
											|it = 'Formattazione';
											|pl = 'Stock discrepancies';
											|tr = 'Düzenleme'");
		
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Important";
		ReportCommand.VariantKey = "RegistrationOfSurplusShortagesContext";
		
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.UnregisteredSurplusesAndShortagesOfGoods);
	DescriptionOfReport.DefineFormSettings = True;
	TMReportOptionsOverridable.DisableReport(DescriptionOfReport);
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf