#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// StandardSubsystems.ReportsOptions

// The configuration options for that report.
// See ReportsOptionsOverridable.CustomizeReportsOptions
//
Procedure CustomizeReportOptions(Settings, DescriptionOfReport) Export
	
	TMReportOptionsOverridable.DisableReport(DescriptionOfReport);
	
EndProcedure

// End StandardSubsystems.ReportsOptions

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   
// Returns:
// 	ValueTableRow -
//
Function AddReportCommand(ReportsCommands) Export
	
	If AccessRight("View", Metadata.Reports.AssetCard) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.AssetCard.FullName();
		ReportCommand.Presentation = NStr("vi = 'Thẻ tài sản đang vận hành';
											|ru = 'Карточка объекта эксплуатации';
											|en = 'Asset maintenance'; fa = 'نگهداری دارایی';
											|it = 'Scheda oggetto in uso';
											|pl = 'Karta obiektu eksploatacji';
											|tr = 'İşlem nesnesi kartı'");
		
		ReportCommand.MultipleChoice = True;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.FunctionalOptions = "UseRMManagement";
		ReportCommand.VariantKey = "AssetCard";
		
		Return ReportCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

#EndRegion

#EndIf