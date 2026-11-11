//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ErrorsOfProductsCostingCalculation);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ErrorsOfProductsCostingCalculation");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ErrorsOfProductsCostingCalculation");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
