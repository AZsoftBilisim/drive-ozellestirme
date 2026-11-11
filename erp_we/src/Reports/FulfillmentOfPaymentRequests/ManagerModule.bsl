#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// 
// Returns:
//     ValueTableRow
//
Function AddReportCommand(ReportsCommands) Export
	
	If AccessRight("View", Metadata.Reports.FulfillmentOfPaymentRequests) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.FulfillmentOfPaymentRequests.FullName();
		ReportCommand.Presentation = NStr("vi = 'Thanh toán thực tế của giấy đề nghị';
											|ru = 'Фактическая оплата заявки';
											|en = 'Actual request payment '; fa = 'پرداخت واقعی درخواست';
											|it = 'Фактическая оплата заявки';
											|pl = 'Rzeczywista płatność wniosku';
											|tr = 'Talebin fiili ödemesi'");
		
		ReportCommand.Order       = 60;
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.VariantKey = "FulfillmentOfPaymentRequests";
		
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.FulfillmentOfPaymentRequests);
	DescriptionOfReport.DefineFormSettings = True;
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "FulfillmentOfPaymentRequests");
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf