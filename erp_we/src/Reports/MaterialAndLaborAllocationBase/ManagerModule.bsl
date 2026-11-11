#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// Returns:
//	ValueTableRow - description of the report command.
Function AddReportCommand(ReportsCommands) Export
	
	If AccessRight("View", Metadata.Reports.MaterialAndLaborAllocationBase) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Id               = Metadata.Reports.MaterialAndLaborAllocationBase.FullName();
		ReportCommand.Manager                    = "Report.MaterialAndLaborAllocationBase";
		ReportCommand.Presentation               = NStr("vi = 'phân bổ vật liệu (công việc)';
														|ru = 'Распределение материала (работы)';
														|en = 'Material (work) allocation'; fa = 'Material (work) allocation';
														|it = 'Allocazione del materiale (lavoro)';
														|pl = 'Dystrybucja materiałów (prac)';
														|tr = 'Malzeme dağıtımı (iş)'");
		
		ReportCommand.MultipleChoice          = False;
		ReportCommand.Importance                    = "Ordinary";
		ReportCommand.FunctionalOptions         = "UseProductionManagement2_2";
		ReportCommand.WriteMode                 = "NotWrite";
		ReportCommand.VariantKey                = "MaterialDistribution";
		
		Return ReportCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// Returns:
//	ValueTableRow - description of the report command.
Function AddWasteReturnDistributionCommand(ReportsCommands) Export
	
	If AccessRight("View", Metadata.Reports.MaterialAndLaborAllocationBase) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Id               = Metadata.Reports.MaterialAndLaborAllocationBase.FullName();
		ReportCommand.Manager                    = "Report.MaterialAndLaborAllocationBase";
		ReportCommand.Presentation               = NStr("vi = 'Phân bổ phế liệu thu hồi';
														|ru = 'Распределение возвратного отхода';
														|en = 'Recyclable waste allocation'; fa = 'تسهیم ضایعات قابل بازیافت';
														|it = 'Allocazione dei rifiuti riciclabili';
														|pl = 'Dystrybucja odpadów zwrotnych';
														|tr = 'Geri dönüştürülebilir atık dağıtımı'");
		
		ReportCommand.MultipleChoice          = False;
		ReportCommand.Importance                    = "Ordinary";
		ReportCommand.FunctionalOptions         = "UseProductionManagement2_2";
		ReportCommand.WriteMode                 = "Post";
		ReportCommand.VariantKey                = "MaterialDistribution";
		
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.MaterialAndLaborAllocationBase);
	DescriptionOfReport.DefineFormSettings = True;
	TMReportOptionsOverridable.DisableReport(DescriptionOfReport);
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf