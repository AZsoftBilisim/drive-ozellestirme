#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// For the "report Options" subsystem when working in the service model.
// Returns:
//  Array of Structure - Contains an array of structures with properties:
//     * ReportVariant - Structure - Version of the report.
//        Name - String - Name of the report variant.
//        View - Row - View of the report variant.
//
Function SettingVariants() Export
	
	Result = New Array;
	
	Variant = New Structure;
	Variant.Insert("Name",           "BalanceSheet");
	Variant.Insert("Presentation", NStr("vi = 'Bảng cân đối kế toán ngân sách';
										|ru = 'Оборотно-сальдовая ведомость по показателям бюджетов';
										|en = 'Trial balance for budget balance items'; fa = 'تراز آزمایشی برای اقلام مانده بودجه';
										|it = 'Bilancio di verifica sugli indici dei budget';
										|pl = 'Zestawienie obrotowo-saldowe wg wskaźników budżetowych';
										|tr = 'Bütçe kalemine göre geçici mizan'"));
	Result.Add(Variant);
	
	Variant = New Structure;
	Variant.Insert("Name",           "BalanceSheetByBudgetIndicator");
	Variant.Insert("Presentation", NStr("vi = 'Bảng cân đối số phát sinh theo mục';
										|ru = 'Оборотно-сальдовая ведомость по показателю бюджетов';
										|en = 'Trial balance for the budget balance item'; fa = 'تراز آزمایشی برای قلم مانده بودجه';
										|it = 'Bilancio di verifica sull''indice dei budget';
										|pl = 'Zestawienie obrotowo-saldowe wg wskaźnika budżetowego';
										|tr = 'Bütçe kalemine göre geçici mizan'"));
	Result.Add(Variant);
	
	Variant = New Structure;
	Variant.Insert("Name",           "Details");
	Variant.Insert("Presentation", NStr("vi = 'Bảng cân đối kế toán ngân sách';
										|ru = 'Оборотно-сальдовая ведомость по показателям бюджетов';
										|en = 'Trial balance for budget balance items'; fa = 'تراز آزمایشی برای اقلام مانده بودجه';
										|it = 'Bilancio di verifica sugli indici dei budget';
										|pl = 'Zestawienie obrotowo-saldowe wg wskaźników budżetowych';
										|tr = 'Bütçe kalemine göre geçici mizan'"));
	Result.Add(Variant);
	
	Return Result;
	
EndFunction

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

	If AccessRight("View", Metadata.Reports.TrialBalanceForBudgetBalanceItems) 
			And GetFunctionalOption("UseBudgeting") Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.TrialBalanceForBudgetBalanceItems.FullName();
		ReportCommand.Presentation = NStr("vi = 'Bảng cân đối số phát sinh';
											|ru = 'Оборотно-сальдовая ведомость';
											|en = 'Trial balance'; fa = 'تراز آزمایشی';
											|it = 'Bilancio di verifica';
											|pl = 'Zestawienie obrotowo-saldowe';
											|tr = 'Geçici Mizan'");
		
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Important";
		ReportCommand.VariantKey = "BalanceSheetByBudgetIndicator";
		
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.TrialBalanceForBudgetBalanceItems);
	DescriptionOfReport.DefineFormSettings = True;
	ReportsOptions.SetOutputModeInReportPanels(Settings, DescriptionOfReport, DisplayReportOptions);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'So sánh phát sinh và số dư của các chỉ tiêu theo kế hoạch và thực tế trong kỳ.';
									|ru = 'Сравнение плановых и фактических сальдо и оборотов по показателям за период.';
									|en = 'Compare planned and actual balance and turnovers for the balance items over the period.'; fa = 'Compare planned and actual balance and turnovers for the balance items over the period.';
									|it = 'Сравнение плановых и фактических сальдо и оборотов по показателям за период.';
									|pl = 'Porównanie planowych i faktycznych sald i obrotów według wskaźników za okres.';
									|tr = 'Planlanan ve fiilî bakiyelerin ve ciroların dönem göstergelerine göre karşılaştırılması.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "BalanceSheet");
	OptionDetails.LongDesc = NStr("vi = 'So sánh phát sinh và số dư của các chỉ tiêu theo kế hoạch và thực tế trong kỳ.';
									|ru = 'Сравнение плановых и фактических сальдо и оборотов по показателям за период.';
									|en = 'Compare planned and actual balance and turnovers for the balance items over the period.'; fa = 'Compare planned and actual balance and turnovers for the balance items over the period.';
									|it = 'Сравнение плановых и фактических сальдо и оборотов по показателям за период.';
									|pl = 'Porównanie planowych i faktycznych sald i obrotów według wskaźników za okres.';
									|tr = 'Planlanan ve fiilî bakiyelerin ve ciroların dönem göstergelerine göre karşılaştırılması.'");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "BalanceSheetByBudgetIndicator");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "Details");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf