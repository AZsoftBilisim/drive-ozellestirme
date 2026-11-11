// @strict-types


#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
//  - ValueTableRow
//  - Undefined
//
Function AddPurchasePlanTeam(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.PurchasePlan) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Id               = Metadata.Reports.PurchasePlan.FullName();
		ReportCommand.Presentation               = NStr("vi = 'Kế hoạch mua hàng';
														|ru = 'План закупок';
														|en = 'Purchase plan'; fa = 'برنامه خرید';
														|it = 'Piano di acquisti';
														|pl = 'Plan zakupów';
														|tr = 'Satın alma planı'");
		ReportCommand.Manager                    = "Report.PurchasePlan";
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance      = "Important";
		
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
//   DisplayReportOptions - Boolean
//
Procedure CustomizeReportOptions(Settings, DisplayReportOptions) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.PurchasePlan);
	DescriptionOfReport.DefineFormSettings = True;
	ReportsOptions.SetOutputModeInReportPanels(Settings, DescriptionOfReport, DisplayReportOptions);
	TMReportOptionsOverridable.DisableReport(DescriptionOfReport);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
