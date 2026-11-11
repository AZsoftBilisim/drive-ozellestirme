#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.DrillDownProductionOrderControlByReleaseLots);
	TMReportOptionsOverridable.DisableReport(DescriptionOfReport);
EndProcedure

#EndRegion

#EndIf