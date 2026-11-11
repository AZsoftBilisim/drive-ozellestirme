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

	If AccessRight("View", Metadata.Reports.ResultsOfApprovalOfRequestForReturnOfGoodsFromCustomer) 
			And GetFunctionalOption("UseInternalApprovalOfRequestsForReturnOfGoodsFromCustomers") Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.ResultsOfApprovalOfRequestForReturnOfGoodsFromCustomer.FullName();
		ReportCommand.Presentation = NStr("vi = 'Kết quả thống nhất';
											|ru = 'Результаты согласования';
											|en = 'Approval results'; fa = 'Approval results';
											|it = 'Risultati accordo';
											|pl = 'Wyniki uzgodnienia';
											|tr = 'Mutabakat sonuçları'");
		
		ReportCommand.MultipleChoice = True;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.AdditionalParameters.Insert("CommandName", "ResultsOfApprovalOfRequestForReturnOfGoodsFromCustomer");
		
		Return ReportCommand;
		
	EndIf;

	Return Undefined;

EndFunction

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
//  Undefined, ValueTableRow - report command
Function AddDocumentReportCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.ResultsOfApprovalOfRequestForReturnOfGoodsFromCustomer) 
			And GetFunctionalOption("UseInternalApprovalOfRequestsForReturnOfGoodsFromCustomers") Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.ResultsOfApprovalOfRequestForReturnOfGoodsFromCustomer.FullName();
		ReportCommand.Presentation = NStr("vi = 'Kết quả thống nhất';
											|ru = 'Результаты согласования';
											|en = 'Approval results'; fa = 'Approval results';
											|it = 'Risultati accordo';
											|pl = 'Wyniki uzgodnienia';
											|tr = 'Mutabakat sonuçları'");
		
		ReportCommand.MultipleChoice = True;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.AdditionalParameters.Insert("CommandName", "ResultsOfApprovalOfApplicationForReturnOfGoodsFromClientOnDocument");
		
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ResultsOfApprovalOfRequestForReturnOfGoodsFromCustomer);
	DescriptionOfReport.DefineFormSettings = True;
	TMReportOptionsOverridable.DisableReport(DescriptionOfReport);
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf