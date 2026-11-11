#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
//  Undefined, ValueTableRow - Add a report command
//
Function AddReportCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.ErrorsOfPostingTemplatesSetup) 
			And GetFunctionalOption("UseFinancialAccounting") Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.ErrorsOfPostingTemplatesSetup.FullName();
		ReportCommand.Presentation = NStr("vi = 'Lỗi tùy chỉnh bút toán';
											|ru = 'Ошибки настройки шаблонов проводок';
											|en = 'Errors of posting template setup'; fa = 'خطاهای تنظیم الگوی ثبت قطعی';
											|it = 'Errori di impostazione dei modelli delle registrazioni';
											|pl = 'Błąd konfiguracji szablonów dekretowania';
											|tr = 'Kayıt şablonu ayarları hataları'");
		
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Ordinary";
		
		Return ReportCommand;
		
	EndIf;

	Return Undefined;

EndFunction

#EndRegion

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ErrorsOfPostingTemplatesSetup);
	DescriptionOfReport.DefineFormSettings = True;
	TMReportOptionsOverridable.DisableReport(DescriptionOfReport);
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf