#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// StandardSubsystems.ReportsOptions

// The configuration options for that report.
// More detailed - See ReportsOptionsOverridable.CustomizeReportsOptions.
//
Procedure CustomizeReportOptions(Settings, DescriptionOfReport) Export
	
	// Setting placement, default visibility, importance
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "Main");
	TMReportOptionsOverridable.SetImportanceOfReportOption(OptionDetails, "SeeAlso");
	
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndIf