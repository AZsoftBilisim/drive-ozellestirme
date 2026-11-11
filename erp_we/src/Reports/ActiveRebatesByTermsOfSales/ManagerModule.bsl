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
	
	ReportSettings = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ActiveRebatesByTermsOfSales);
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
//		ValueTableRow - description of the created team.
//
Function AddReportCommand(ReportsCommands, VariantKey = "") Export
	
	If AccessRight("View", Metadata.Reports.ActiveRebatesByTermsOfSales)
	   And GetFunctionalOption("UseCustomerRebates") Then
		
		ReportCommand = ReportsCommands.Add();
		Presentation = NStr("vi = 'Thưởng lũy kế đang có hiệu lực theo thỏa thuận';
							|ru = 'Действующие ретро-бонусы по соглашению';
							|en = 'Active rebates by terms of sales'; fa = 'تخفیف‌های حجمی فعال بر اساس شرایط فروش';
							|it = 'Действующие ретро-бонусы по соглашению';
							|pl = 'Active rebates by terms of sales';
							|tr = 'Anlaşmaya göre geçerli retro-bonuslar'");
		ReportCommand.Presentation = Presentation;
		ReportCommand.Manager = Metadata.Reports.ActiveRebatesByTermsOfSales.FullName();
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