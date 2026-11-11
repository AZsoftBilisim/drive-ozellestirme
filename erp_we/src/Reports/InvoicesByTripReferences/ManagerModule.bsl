// @strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//   ReportSettings - See ReportsOptions.DescriptionOfReport.
//
Procedure CustomizeReportOptions(Settings, ReportSettings) Export
	
	ReportSettings = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.InvoicesByTripReferences);
	ReportSettings.FunctionalOptions.Add("NotUseDeliveryManagement20");
	ReportSettings.DefineFormSettings = True;
	ReportsOptions.SetOutputModeInReportPanels(Settings, ReportSettings, False);
	TMReportOptionsOverridable.DisableReport(ReportSettings);
	
EndProcedure

#EndRegion

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//   VariantKey - String - 
//   
//	Returns:
//		ValueTableRow - description of the created team.
//
Function AddReportCommand(ReportsCommands, Parameters, VariantKey = "") Export
	
	ReportCommand = Undefined;
	
	If AccessRight("View", Metadata.Reports.InvoicesByTripReferences) Then
		
		ReportCommand = ReportsCommands.Add();
		
		If VariantKey = "InvoicesByTripReferences" Then
			
			Presentation = NStr("ru = 'Накладные по распоряжениям рейса';
								|vi = 'Invoices by trip references';
								|en = 'Invoices by trip references'; fa = 'فاکتورها بر اساس مراجع سفر';
								|it = 'Invoices by trip references';
								|pl = 'Invoices by trip references';
								|tr = 'Sefer talimatlarına göre irsaliyeler'"); 
			
		EndIf;
		
		ReportCommand.Manager = Metadata.Reports.InvoicesByTripReferences.FullName();
		ReportCommand.VariantKey = VariantKey;
		ReportCommand.Presentation = Presentation;
		ReportCommand.MultipleChoice = False;
		ReportCommand.WriteMode = "Post";
		ReportCommand.FunctionalOptions = "NotUseDeliveryManagement20";
		ReportCommand.Importance = "Ordinary";
		
		If ValueIsFilled(VariantKey) Then
			
			ReportCommand.VariantKey = VariantKey;
			
		EndIf;
		
	EndIf;
	
	Return ReportCommand;
	
EndFunction

#EndRegion

#EndRegion

#EndIf