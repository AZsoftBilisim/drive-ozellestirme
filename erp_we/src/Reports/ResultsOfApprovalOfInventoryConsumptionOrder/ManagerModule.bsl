#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// Returns:
// 	ValueTableRow
Function AddReportCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.ResultsOfApprovalOfInventoryConsumptionOrder) 
			And GetFunctionalOption("UseApprovalOfInventoryConsumptionOrders") Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.ResultsOfApprovalOfInventoryConsumptionOrder.FullName();
		ReportCommand.Presentation = NStr("vi = 'Kết quả thống nhất';
											|ru = 'Результаты согласования';
											|en = 'Approval results '; fa = 'نتایج تأیید';
											|it = 'Risultati accordo';
											|pl = 'Wyniki uzgodnienia';
											|tr = 'Mutabakat sonuçları'");
		
		ReportCommand.MultipleChoice = True;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.FunctionalOptions = "UseApprovalOfInventoryConsumptionOrders";
		ReportCommand.AdditionalParameters.Insert("CommandName", "ResultsOfApprovalOfOrdersForDomesticConsumption");
		
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
Function AddInternalConsumptionOrderApprovalResultsCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.ResultsOfApprovalOfInventoryConsumptionOrder) 
			And GetFunctionalOption("UseApprovalOfInventoryConsumptionOrders") Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.ResultsOfApprovalOfInventoryConsumptionOrder.FullName();
		ReportCommand.Presentation = NStr("vi = 'Kết quả thống nhất';
											|ru = 'Результаты согласования';
											|en = 'Approval results '; fa = 'نتایج تأیید';
											|it = 'Risultati accordo';
											|pl = 'Wyniki uzgodnienia';
											|tr = 'Mutabakat sonuçları'");
		
		ReportCommand.MultipleChoice = True;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.FunctionalOptions = "UseApprovalOfInventoryConsumptionOrders";
		ReportCommand.AdditionalParameters.Insert("CommandName", "ResultsOfApprovalOfOrdersForDomesticConsumptionAccordingToDocument");
		
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ResultsOfApprovalOfInventoryConsumptionOrder);
	DescriptionOfReport.DefineFormSettings = True;
	TMReportOptionsOverridable.DisableReport(DescriptionOfReport);
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf