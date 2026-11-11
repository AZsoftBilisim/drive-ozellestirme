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

	If AccessRight("View", Metadata.Reports.CompareSchedulesOfPaymentsAndAccrualsOfCreditDepositLoanContracts) 
			And GetFunctionalOption("UseLoanAndDepositContracts") Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Handler = "ReportManagementTMClient.ComparisonOfArbitraryGraphs";
		ReportCommand.Manager = Metadata.Reports.CompareSchedulesOfPaymentsAndAccrualsOfCreditDepositLoanContracts.FullName();
		ReportCommand.Presentation = NStr("vi = 'So sánh lịch biểu';
											|ru = 'Сравнение графиков';
											|en = 'Compare charts'; fa = 'Compare charts';
											|it = 'Confronto dei grafici';
											|pl = 'Porównanie wykresów';
											|tr = 'Planların karşılaştırılması'");
		
		ReportCommand.MultipleChoice = True;
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.CompareSchedulesOfPaymentsAndAccrualsOfCreditDepositLoanContracts);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích chênh lệch giữa hai phương án lịch biểu theo hợp đồng.';
									|ru = 'Анализ отклонений между двумя вариантами графиков по договорам.';
									|en = 'Analyze variances between two contract schedule options.'; fa = 'Analyze variances between two contract schedule options.';
									|it = 'Анализ отклонений между двумя вариантами графиков по договорам.';
									|pl = 'Analiza odchyleń między dwoma wariantami harmonogramów według kontraktów.';
									|tr = 'Sözleşme programlarının iki seçeneği arasındaki sapmaların analizi.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "CompareChartOptions");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích chênh lệch giữa hai phương án lịch biểu theo hợp đồng.';
									|ru = 'Анализ отклонений между двумя вариантами графиков по договорам.';
									|en = 'Analyze variances between two contract schedule options.'; fa = 'Analyze variances between two contract schedule options.';
									|it = 'Анализ отклонений между двумя вариантами графиков по договорам.';
									|pl = 'Analiza odchyleń między dwoma wariantami harmonogramów według kontraktów.';
									|tr = 'Sözleşme programlarının iki seçeneği arasındaki sapmaların analizi.'");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ComparisonOfChartOptionsContext");
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf