#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// 
// Returns:
//   ValueTableRow: See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//  
Function AddRuleApplicationControlCommand(ReportsCommands) Export
	
	If AccessRight("View", Metadata.Reports.ApplicationOfRulesForCalculationOfInventoryImpairmentProvision) 
			And (GetFunctionalOption("AccualInventoryImpairmentProvision")) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.ApplicationOfRulesForCalculationOfInventoryImpairmentProvision.FullName();
		ReportCommand.Presentation = NStr("vi = 'Kiểm soát việc áp dụng quy tắc';
											|ru = 'Контроль применения правила';
											|en = 'Rule application control'; fa = 'Rule application control';
											|it = 'Controllo applicazione delle regole';
											|pl = 'Kontrola zastosowania reguły';
											|tr = 'Kural uygulama kontrolü'");
		
		ReportCommand.MultipleChoice = True;

		Return ReportCommand;
		
	EndIf;
	
EndFunction

#EndRegion

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ApplicationOfRulesForCalculationOfInventoryImpairmentProvision);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Quy tắc đã chọn bao gồm số dư vật tư nào?';
									|ru = 'Какие остатки запасов подпадают под выбранное правило?';
									|en = 'What inventory balances apply to the selected rule?'; fa = 'What inventory balances apply to the selected rule?';
									|it = 'Какие остатки запасов подпадают под выбранное правило?';
									|pl = 'Jakie salda zapasów podlegają wybranej regule?';
									|tr = 'Hangi stok bakiyeleri seçilen kurala tabidir?'");
	
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "Main");
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf