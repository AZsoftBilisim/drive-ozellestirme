#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
//  Undefined
Function AddReportCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.AnalysisOfReasonsForPurchaseOrderCancellationAccordingToDocument) 
			And GetFunctionalOption("UseReasonsForPurchaseOrderCancellations") Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.AnalysisOfReasonsForPurchaseOrderCancellationAccordingToDocument.FullName();
		ReportCommand.Presentation = NStr("vi = 'Phân tích nguyên nhân hủy bỏ';
											|ru = 'Анализ причин отмены';
											|en = 'Analysis of cancellation reasons'; fa = 'تحلیل دلایل لغو';
											|it = 'Analisi delle cause dell''annullamento';
											|pl = 'Analiza przyczyn anulowania';
											|tr = 'İptal nedenlerinin analizi'");
		
		ReportCommand.MultipleChoice = True;
		ReportCommand.Importance = "Ordinary";
		
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.AnalysisOfReasonsForPurchaseOrderCancellationAccordingToDocument);
	TMReportOptionsOverridable.DisableReport(DescriptionOfReport);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf