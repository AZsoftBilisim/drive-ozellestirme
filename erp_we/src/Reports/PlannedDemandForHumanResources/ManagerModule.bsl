#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
//  ValueTableRow, Undefined - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
Function AddReportCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.PlannedDemandForHumanResources) 
			And GetFunctionalOption("UseProductionPlanning") Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.PlannedDemandForHumanResources.FullName();
		ReportCommand.Presentation = NStr("vi = 'Nhu cầu nhân công';
											|ru = 'Потребность в трудовых ресурсах';
											|en = 'Planned demand for human resources'; fa = 'نیاز برنامه‌ریزی‌شده به منابع انسانی';
											|it = 'Fabbisogno di risorse umane';
											|pl = 'Zapotrzebowanie zasobów pracy';
											|tr = 'İş kaynaklarında gereksinim'");
		
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.VariantKey = "PlannedLaborCosts_";
		
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
//   DisplayReportOptions - Boolean
//
Procedure CustomizeReportOptions(Settings, DisplayReportOptions) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.PlannedDemandForHumanResources);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Đánh giá nhu cầu về nguồn lực lao động để thực hiện kế hoạch sản xuất.';
									|ru = 'Оценка потребности в трудовых ресурсах для исполнения планов производства.';
									|en = 'Evaluate the workforce demand required to fulfill production plans.'; fa = 'Evaluate the workforce demand required to fulfill production plans.';
									|it = 'Оценка потребности в трудовых ресурсах для исполнения планов производства.';
									|pl = 'Ocena zapotrzebowania w zasobach roboczych dla wykonania planów produkcji.';
									|tr = 'Üretim planlarının yürütülmesi için işgücü kaynaklarına olan ihtiyacın değerlendirilmesi.'");
	ReportsOptions.SetOutputModeInReportPanels(Settings, DescriptionOfReport, DisplayReportOptions);
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "PlannedLaborCosts_");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "DecodingContext");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "Details");
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf