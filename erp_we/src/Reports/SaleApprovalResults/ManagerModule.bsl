#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// Returns:
//   ValueTableRow - new report command.
Function AddCustomerOrderApprovalResultsCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.SaleApprovalResults) 
			And (GetFunctionalOption("UseInternalSalesOrderApproval")
				Or GetFunctionalOption("UseInternalApprovalOfTermsOfSales")) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.SaleApprovalResults.FullName();
		ReportCommand.Presentation = NStr("vi = 'Kết quả thống nhất';
											|ru = 'Результаты согласования';
											|en = 'Approval results'; fa = 'Approval results';
											|it = 'Risultati accordo';
											|pl = 'Wyniki uzgodnienia';
											|tr = 'Mutabakat sonuçları'");
		
		ReportCommand.MultipleChoice = True;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.FunctionalOptions = "UseInternalSalesOrderApproval";
		ReportCommand.AdditionalParameters.Insert("CommandName", "CustomerOrderApprovalResults");
		
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
//
Function AddSalesApprovalResultsCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.SaleApprovalResults) 
			And (GetFunctionalOption("UseInternalSalesOrderApproval")
				Or GetFunctionalOption("UseInternalApprovalOfTermsOfSales")) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.SaleApprovalResults.FullName();
		ReportCommand.Presentation = NStr("vi = 'Kết quả thống nhất';
											|ru = 'Результаты согласования';
											|en = 'Approval results'; fa = 'Approval results';
											|it = 'Risultati accordo';
											|pl = 'Wyniki uzgodnienia';
											|tr = 'Mutabakat sonuçları'");
		
		ReportCommand.MultipleChoice = True;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.FunctionalOptions = "UseInternalSalesOrderApproval,UseInternalApprovalOfTermsOfSales";
		ReportCommand.AdditionalParameters.Insert("CommandName", "SaleApprovalResults");
		
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
Function AddCustomerAgreementNegotiationResultsCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.SaleApprovalResults) 
			And (GetFunctionalOption("UseInternalSalesOrderApproval")
				Or GetFunctionalOption("UseInternalApprovalOfTermsOfSales")) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.SaleApprovalResults.FullName();
		ReportCommand.Presentation = NStr("vi = 'Kết quả thống nhất';
											|ru = 'Результаты согласования';
											|en = 'Approval results'; fa = 'Approval results';
											|it = 'Risultati accordo';
											|pl = 'Wyniki uzgodnienia';
											|tr = 'Mutabakat sonuçları'");
		
		ReportCommand.MultipleChoice = True;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.FunctionalOptions = "UseInternalApprovalOfTermsOfSales";
		ReportCommand.AdditionalParameters.Insert("CommandName", "ResultsOfAgreementApprovalWithClients");
		
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.SaleApprovalResults);
	DescriptionOfReport.DefineFormSettings = True;
	TMReportOptionsOverridable.DisableReport(DescriptionOfReport);
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf