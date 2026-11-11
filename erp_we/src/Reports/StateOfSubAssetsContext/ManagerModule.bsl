#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   
// Returns:
//	ValueTableRow - new report command.
Function AddReportCommand(ReportsCommands) Export
	
	If AccessRight("View", Metadata.Reports.StateOfSubAssetsContext)
		And GetFunctionalOption("UseRMManagement") Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.StateOfSubAssetsContext.FullName();
		ReportCommand.Presentation = NStr("vi = 'Trạng thái nút';
											|ru = 'Состояние узла';
											|en = 'Sub-asset state'; fa = 'وضعیت زیردارایی';
											|it = 'Stato del nodo';
											|pl = 'Stan węzła';
											|tr = 'Alt varlık durumu'");
		ReportCommand.Importance = "Ordinary";
		ReportCommand.MultipleChoice = True;
		ReportCommand.AdditionalParameters.Insert("CommandName", "StateOfNodeOfObjectOfOperation");
		ReportCommand.VariantKey = "StateOfNodeOfObjectOfOperationContext";
		
		Return ReportCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.StateOfSubAssetsContext);
	DescriptionOfReport.FunctionalOptions.Add("UseSubAssets");
	DescriptionOfReport.DefineFormSettings = True;
	TMReportOptionsOverridable.DisableReport(DescriptionOfReport);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf