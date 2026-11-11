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

	If AccessRight("View", Metadata.Reports.PurchaseApprovalResults) 
			And GetFunctionalOption("UsePurchaseOrderApproval") Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.PurchaseApprovalResults.FullName();
		ReportCommand.Presentation = NStr("vi = 'Kết quả thống nhất';
											|ru = 'Результаты согласования';
											|en = 'Approval results'; fa = 'Approval results';
											|it = 'Risultati accordo';
											|pl = 'Wyniki uzgodnienia';
											|tr = 'Mutabakat sonuçları'");
		
		ReportCommand.MultipleChoice = True;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.FunctionalOptions = "UsePurchaseOrderApproval";
		ReportCommand.AdditionalParameters.Insert("CommandName", "PurchaseApprovalResults");
		
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
Function AddDocumentReportCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.PurchaseApprovalResults) 
			And GetFunctionalOption("UsePurchaseOrderApproval") Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.PurchaseApprovalResults.FullName();
		ReportCommand.Presentation = NStr("vi = 'Kết quả thống nhất';
											|ru = 'Результаты согласования';
											|en = 'Approval results'; fa = 'Approval results';
											|it = 'Risultati accordo';
											|pl = 'Wyniki uzgodnienia';
											|tr = 'Mutabakat sonuçları'");
		
		ReportCommand.MultipleChoice = True;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.FunctionalOptions = "UsePurchaseOrderApproval";
		ReportCommand.AdditionalParameters.Insert("CommandName", "ResultsOfApprovalOfPurchaseByDocument");
		
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.PurchaseApprovalResults);
	DescriptionOfReport.DefineFormSettings = True;
	TMReportOptionsOverridable.DisableReport(DescriptionOfReport);
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf