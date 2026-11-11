// @strict-types

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
	
	DisplayReportOptions = False;
	
	ReportSettings = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ActiveCustomerRebates);
	ReportSettings.FunctionalOptions.Add(Metadata.FunctionalOptions.UseCustomerRebates.Name);
	ReportSettings.DefineFormSettings = True;
	
	OptionSettings = ReportsOptions.OptionDetails(
		Settings, ReportSettings, "CurrentRebatesForClient");
	OptionSettings.LongDesc = NStr("vi = 'Những điều kiện thưởng lũy kế nào đang có hiệu lực với đối tác và/hoặc khách hàng?';
									|ru = 'Какие условия ретро-бонусов действуют для контрагента и/или клиента?';
									|en = 'What rebate conditions apply to the counterparty and/or the customer?'; fa = 'What rebate conditions apply to the counterparty and/or the customer?';
									|it = 'Какие условия ретро-бонусов действуют для контрагента и/или клиента?';
									|pl = 'What rebate conditions apply to the counterparty and/or the customer?';
									|tr = 'Karşı taraf ve/veya müşteri için hangi retro bonus şartları geçerlidir?'");
	OptionSettings.Location.Insert(Metadata.Subsystems.CRMAndMarketing.Subsystems.CustomerRebates);
	
	ReportsOptions.SetOutputModeInReportPanels(Settings, ReportSettings, DisplayReportOptions);
	
	TMReportOptionsOverridable.DisableReportOption(
		Settings,
		ReportSettings,
		"CurrentRebatesForClientContext");
	
	TMReportOptionsOverridable.DisableReportOption(
		Settings,
		ReportSettings,
		"CurrentRebatesForCounterpartyContext");
	
EndProcedure

#EndRegion

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//   VariantKey - String - 
//   
//	Returns:
//		Undefined, ValueTableRow - description of the created team.
//
Function AddReportCommand(ReportsCommands, Parameters, VariantKey = "") Export
	
	If AccessRight("View", Metadata.Reports.ActiveCustomerRebates)
	   And GetFunctionalOption("UseCustomerRebates") Then
		
		ReportCommand = ReportsCommands.Add();
		Presentation = NStr("vi = 'Thưởng lũy kế đang có hiệu lực theo khách hàng';
							|ru = 'Действующие ретро-бонусы по клиенту';
							|en = 'Active rebates by customer'; fa = 'تخفیف‌های حجمی فعال بر اساس مشتری';
							|it = 'Действующие ретро-бонусы по клиенту';
							|pl = 'Active rebates by customer';
							|tr = 'Müşteriye göre geçerli retro-bonuslar'");
		ReportCommand.Manager = Metadata.Reports.ActiveCustomerRebates.FullName();
		ReportCommand.Presentation = Presentation;
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