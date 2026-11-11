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


	If AccessRight("View", Metadata.Reports.ErrorsInAllocatioOfWIPCostBalances) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager           = Metadata.Reports.ErrorsInAllocatioOfWIPCostBalances.FullName();
		ReportCommand.Presentation      = NStr("vi = 'Lỗi trong dữ liệu phân bổ của số dư SXDD';
												|ru = 'Ошибки в данных распределения остатков НЗП';
												|en = 'Errors in WIP balance distribution data'; fa = 'خطاها در داده‌های توزیع مانده کار در جریان ساخت';
												|it = 'Errori nei dati della ripartizione dei saldi della produzione non completata';
												|pl = 'Błędy w danych podziału pozostałości produkcji w toku';
												|tr = 'Devam eden imalat bakiyelerinin dağıtım verileri hataları'");
		ReportCommand.MultipleChoice = True;
		ReportCommand.Importance           = "Ordinary";
		ReportCommand.VariantKey       = "ErrorsInDistributionDataOfUnfinishedProductionResiduesContext";
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ErrorsInAllocatioOfWIPCostBalances);
	DescriptionOfReport.DefineFormSettings = True;
	TMReportOptionsOverridable.DisableReport(DescriptionOfReport);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf