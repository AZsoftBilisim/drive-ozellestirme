#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//  ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
//  ValueTableRow, Undefined - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
Function AddReportCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.PlannedDemandForWorkCenterTypes) 
			And GetFunctionalOption("UseProductionPlanning") Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.PlannedDemandForWorkCenterTypes.FullName();
		ReportCommand.Presentation = NStr("vi = 'Nhu cầu về các dạng NLSX';
											|ru = 'Потребность в видах РЦ';
											|en = 'Planned demand for work center types'; fa = 'نیاز برنامه‌ریزی‌شده به انواع مرکز کار';
											|it = 'Fabbisogno di tipi di centri di lavoro';
											|pl = 'Zapotrzebowanie w rodzajach CP';
											|tr = 'İM türlerinde gereksinim'");
		
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.VariantKey = "PlannedNeedForTypesOfRCTs";
		
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.PlannedDemandForWorkCenterTypes);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Đánh giá nhu cầu theo các dạng NLSX để thực hiện kế hoạch sản xuất và so sánh với mức độ khả dụng để xác định thâm hụt.';
									|ru = 'Оценка потребности в видах РЦ для исполнения планов производства и сопоставление с доступностью для определения дефицита.';
									|en = 'Analyze workload and demand for work center types to identify production capacity shortages.'; fa = 'Analyze workload and demand for work center types to identify production capacity shortages.';
									|it = 'Оценка потребности в видах РЦ для исполнения планов производства и сопоставление с доступностью для определения дефицита.';
									|pl = 'Ocena zapotrzebowania w rodzajach CP dla wykonania planów produkcji i porównanie z dostępnością dla określenia deficytu.';
									|tr = 'Üretim planlarının yürütülmesi için İM türlerine olan ihtiyacın değerlendirilmesi ve açığı belirlemek için mevcudiyet ile karşılaştırılması.'");
	ReportsOptions.SetOutputModeInReportPanels(Settings, DescriptionOfReport, DisplayReportOptions);
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "Details");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "PlannedNeedForTypesOfRCTs");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "DecodingContext");
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf