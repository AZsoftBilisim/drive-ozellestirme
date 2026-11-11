#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// The configuration options for that report.
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings
// 	 DescriptionOfReport - See ReportsOptions.DescriptionOfReport.
//
Procedure CustomizeReportOptions(Settings, DescriptionOfReport) Export
	
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "BudgetReportFormulaDrillDown");
	
EndProcedure

#EndRegion

#EndIf