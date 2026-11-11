#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// StandardSubsystems.ReportsOptions

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//   ReportSettings - See ReportsOptions.DescriptionOfReport.
//
Procedure CustomizeReportOptions(Settings, ReportSettings) Export

	ReportSettings.DefineFormSettings = True;

	OptionSettings = ReportsOptions.OptionDetails(Settings, ReportSettings, "ReportCardByDay");
	OptionSettings.LongDesc = NStr("ru = 'Табель (по дням)';
									|vi = 'Timesheet (by day)';
									|en = 'Timesheet (by day)'; fa = 'برگه کارکرد (روزانه)';
									|it = 'Timesheet (by day)';
									|pl = 'Timesheet (by day)';
									|tr = 'Puantaj (günlük)'");

EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf