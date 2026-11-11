#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// StandardSubsystems.ReportsOptions

// Placement settings in the report panel.
//
// Parameters:
//  Settings - ValueTable - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings
//       It can be used to get settings for a variant of this report using the Variationreports function.Obisnuieste().
//   DescriptionOfReport - ValueTreeRow - The settings of this report
//       that have already been generated using the Report Options function.The description of the report() and ready to be changed.
//       See "Properties for changing" the procedures for variationsreportable.Set up Report Variants().
//
// Description:
//   See ReportsOptionsOverridable.CustomizeReportsOptions.
//
// Auxiliary methods:
//	Setting the variant = Report variationsreferences.Description of the variant (Settings, Report settings, "<Variant Name>");
//	Report variationsreferences.Set the output mode of the Report panel (Settings, Report settings, True/False);
//
// Examples:
//
//  1. Setting the description of the option.
//	Option Setups = Report variationsreferences.Description of the variant (Settings, Report settings, "<Variant Name>");
//	Option settings.Description = NStr("ru = '<Description>'");
//
//  2. Disabling the report option.
//	Option Setups = Report variationsreferences.Description of the variant (Settings, Report settings, "<Variant Name>");
//	Option settings.Enabled = False.
//
Procedure CustomizeReportOptions(Settings, DescriptionOfReport) Export
	
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ProhibitionOfShipmentOnCreditAndDelay");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ProhibitionOfCreditShipment");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ProhibitionOfShipmentByDelay");
	
EndProcedure // CustomizeReportOptions

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndIf