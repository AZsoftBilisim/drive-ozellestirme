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
	
	ReportSettings.DefineFormSettings = True;

	// Option 1: Full headcount
	Variant = ReportsOptions.OptionDetails(Settings, ReportSettings, "Headcount");
	Variant.LongDesc = NStr("ru = 'Штатное расписание.';
							|vi = 'Headcount.';
							|en = 'Headcount.'; fa = 'Headcount.';
							|it = 'Headcount.';
							|pl = 'Headcount.';
							|tr = 'Kadro planı.'");

	// Option 2: Headcount without employees
	Variant = ReportsOptions.OptionDetails(Settings, ReportSettings, "HeadcountWithoutEmployees");
	Variant.LongDesc = NStr("ru = 'Штатное расписание без сотрудников.';
							|vi = 'Headcount without employees.';
							|en = 'Headcount without employees.'; fa = 'Headcount without employees.';
							|it = 'Headcount without employees.';
							|pl = 'Headcount without employees.';
							|tr = 'Çalışansız kadro planı.'");
	
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf