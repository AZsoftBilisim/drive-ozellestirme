#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
// 	ReportsCommands - See AttachableCommandsOverridable.OnDefineCommandsAttachedToObject.Commands
// Returns:
// 	Undefined, ValueTableRow - description of the added command.
//
Function AddReportCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.InitialWIPOpeningBalancesAllocationAnalysis) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager           = Metadata.Reports.InitialWIPOpeningBalancesAllocationAnalysis.FullName();
		ReportCommand.Presentation      = NStr("vi = 'Phân tích phân bổ dư ban đầu của SXDD';
												|ru = 'Анализ распределения начальных остатков НЗП';
												|en = 'Initial WIP opening balance allocation analysis'; fa = 'تحلیل تسهیم مانده افتتاحیه اولیه کار در جریان ساخت';
												|it = 'Analisi della ripartizione dei saldi iniziali di produzione non completata';
												|pl = 'Analiza podziału początkowych pozostałości produkcji w toku';
												|tr = 'Devam eden imalatın açılış bakiyelerinin dağılımının analizi'");
		ReportCommand.MultipleChoice = True;
		ReportCommand.Importance           = "Ordinary";
		ReportCommand.VariantKey       = "AnalysisOfDistributionOfInitialResiduesOfUnfinishedProductionContext";
		ReportCommand.WriteMode        = "Post";
		
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.InitialWIPOpeningBalancesAllocationAnalysis);
	DescriptionOfReport.DefineFormSettings = True;
	TMReportOptionsOverridable.DisableReport(DescriptionOfReport);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf