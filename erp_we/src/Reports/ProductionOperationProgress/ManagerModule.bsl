#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
//  - ValueTableRow
//  - Undefined
//
Function AddReportCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.ProductionOperationProgress) Then
		
		ReportCommand = ReportsCommands.Add();
		ReportCommand.Id       = Metadata.Reports.ProductionOperationProgress.FullName();
		ReportCommand.Manager            = "Report.ProductionOperationProgress";
		ReportCommand.Presentation       = NStr("vi = 'Tiến độ thực hiện các giao dịch sản xuất';
												|ru = 'Ход выполнения производственных операций';
												|en = 'Routing operation progress'; fa = 'پیشرفت عملیات مسیریابی';
												|it = 'Processo di esecuzione delle operazioni di produzione';
												|pl = 'Postęp operacji produkcyjnych';
												|tr = 'Rota işlemlerinin ilerleme durumu'");
		ReportCommand.MultipleChoice  = False;
		ReportCommand.Importance            = "Ordinary";
		ReportCommand.FunctionalOptions = "UseManufacturingExecutionSystem,UseOperationManagement";
		ReportCommand.VariantKey        = "ProgressOfStageOperationsContext";
		
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ProductionOperationProgress);
	DescriptionOfReport.DefineFormSettings = True;
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Theo dõi quá trình thực hiện các giao dịch trong công đoạn';
									|ru = 'Отслеживание хода выполнения операций этапа';
									|en = 'Stage operation procedure tracking'; fa = 'Stage operation procedure tracking';
									|it = 'Отслеживание хода выполнения операций этапа';
									|pl = 'Identyfikowalność toku wykonania operacji etapu';
									|tr = 'Aşama işlemlerinin ilerlemesinin takibi'");
	
	OptionDetails.FunctionalOptions.Add("UseManufacturingExecutionSystem");
	OptionDetails.FunctionalOptions.Add("UseOperationManagement");
	
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ProgressOfStageOperationsContext");
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf