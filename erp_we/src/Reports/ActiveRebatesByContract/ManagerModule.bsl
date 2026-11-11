//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//   ReportSettings - See ReportsOptions.DescriptionOfReport.
//
Procedure CustomizeReportOptions(Settings, ReportSettings) Export
	
	ReportSettings = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ActiveRebatesByContract);
	ReportSettings.FunctionalOptions.Add(Metadata.FunctionalOptions.UseCustomerRebates.Name);
	ReportSettings.DefineFormSettings = True;
	ReportsOptions.SetOutputModeInReportPanels(Settings, ReportSettings, False);
	TMReportOptionsOverridable.DisableReport(ReportSettings);
	
EndProcedure

#EndRegion

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   VariantKey - String - 
//   
//	Returns:
//		Undefined, ValueTableRow - description of the created team.
//
Function AddReportCommand(ReportsCommands, VariantKey = "") Export
	
	If AccessRight("View", Metadata.Reports.ActiveRebatesByContract)
	   And GetFunctionalOption("UseCustomerRebates") Then
		
		ReportCommand = ReportsCommands.Add();
		Presentation = NStr("vi = 'Thưởng lũy kế đang có hiệu lực theo hợp đồng';
							|ru = 'Действующие ретро-бонусы по договору';
							|en = 'Active rebates by contract'; fa = 'تخفیف‌های حجمی فعال بر اساس قرارداد';
							|it = 'Действующие ретро-бонусы по договору';
							|pl = 'Active rebates by contract';
							|tr = 'Sözleşme üzerinde etkin retro-bonuslar'");
		ReportCommand.Presentation = Presentation;
		ReportCommand.Manager = Metadata.Reports.ActiveRebatesByContract.FullName();
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Ordinary";
		
		If ValueIsFilled(VariantKey) Then
			
			ReportCommand.VariantKey = VariantKey;
			
		EndIf;
		
		Return ReportCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

#EndRegion

#EndIf