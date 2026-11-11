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
	
	OptionSettings = ReportsOptions.OptionDetails(Settings, ReportSettings, "PersonnelChanges");
	OptionSettings.LongDesc =
		NStr("ru = 'Приемы на работу, увольнения, переводы и перемещения между подразделениями.';
			|vi = 'Hiring, dismissals and transfers within business units.';
			|en = 'Hiring, dismissals and transfers within business units.'; fa = 'Hiring, dismissals and transfers within business units.';
			|it = 'Hiring, dismissals and transfers within business units.';
			|pl = 'Hiring, dismissals and transfers within business units.';
			|tr = 'İşe alımlar, işten çıkarmalar, transferler ve departmanlar arası yer değişiklikleri.'");
		
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf