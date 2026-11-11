#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// 
// Returns:
//     ValueTableRow
//
Function AddReportCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.CheckRelatedBudgetBalancesAndTurnovers) 
			And GetFunctionalOption("UseBudgeting") Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.CheckRelatedBudgetBalancesAndTurnovers.FullName();
		ReportCommand.Presentation = NStr("vi = 'Kiểm tra quy tắc tính';
											|ru = 'Проверить правило расчета';
											|en = 'Check calculation rule'; fa = 'Check calculation rule';
											|it = 'Check calculation rule';
											|pl = 'Check calculation rule';
											|tr = 'Hesaplama kuralını kontrol et'");
		
		ReportCommand.MultipleChoice = True;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.VariantKey = "CheckRelatedBudgetBalancesAndTurnovers";
		
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
//   DisplayReportOptions - Boolean - True if you want to display the default version of the report.
//
Procedure CustomizeReportOptions(Settings, DisplayReportOptions) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.CheckRelatedBudgetBalancesAndTurnovers);
	DescriptionOfReport.DefineFormSettings = True;
	ReportsOptions.SetOutputModeInReportPanels(Settings, DescriptionOfReport, DisplayReportOptions);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Kiểm tra kết quả theo quy tắc tính số dư và phát sinh liên quan của ngân sách.';
									|ru = 'Проверка результата по правилам расчета связанных остатков и оборотов бюджетов.';
									|en = 'Validate calculation results for related budget balances and turnovers according to configured rules.'; fa = 'Validate calculation results for related budget balances and turnovers according to configured rules.';
									|it = 'Validate calculation results for related budget balances and turnovers according to configured rules.';
									|pl = 'Validate calculation results for related budget balances and turnovers according to configured rules.';
									|tr = 'İlgili bakiyelerin ve bütçe cirolarının hesaplanmasına ilişkin kurallara göre sonucun kontrolü.'");

EndProcedure

#EndRegion

#EndRegion

#EndIf