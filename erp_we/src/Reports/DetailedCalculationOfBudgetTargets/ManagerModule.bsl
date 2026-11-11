#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// StandardSubsystems.ReportsOptions

// The configuration options for that report.
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//   DescriptionOfReport - See ReportsOptions.DescriptionOfReport.
//
Procedure CustomizeReportOptions(Settings, DescriptionOfReport) Export
	
	// Disabling contextual options
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "DetailedCalculationOfBudgetTargets");
	
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndIf