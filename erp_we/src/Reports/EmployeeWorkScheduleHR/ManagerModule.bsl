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
	
	OptionSettings = ReportsOptions.OptionDetails(Settings, ReportSettings, "ByDays");
	OptionSettings.LongDesc =
		NStr("ru = 'Расписание (по дням)';
			|vi = 'Schedule (by day)';
			|en = 'Schedule (by day)'; fa = 'زمان‌بندی (بر اساس روز)';
			|it = 'Schedule (by day)';
			|pl = 'Schedule (by day)';
			|tr = 'Program (günlere göre)'");
	
	OptionSettings = ReportsOptions.OptionDetails(Settings, ReportSettings, "ByShifts");
	OptionSettings.LongDesc =
		NStr("ru = 'Расписание (по сменам)';
			|vi = 'Schedule (by shift)';
			|en = 'Schedule (by shift)'; fa = 'زمان‌بندی (بر اساس شیفت)';
			|it = 'Schedule (by shift)';
			|pl = 'Schedule (by shift)';
			|tr = 'Program (vardiyalara göre)'");

EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf