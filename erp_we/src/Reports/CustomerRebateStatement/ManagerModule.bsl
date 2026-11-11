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
	
	ReportSettings = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.CustomerRebateStatement);
	ReportSettings.FunctionalOptions.Add(Metadata.FunctionalOptions.UseCustomerRebates.Name);
	ReportSettings.DefineFormSettings = True;
	
	OptionSettings = ReportsOptions.OptionDetails(Settings, ReportSettings, "CustomerRebateStatement");
	OptionSettings.LongDesc = NStr("vi = 'Có bao nhiêu tiền thưởng đã tính và cấp cho khách hàng trong kỳ chỉ định?
									  |Có bao nhiêu tiền thưởng đang chờ ký thông báo thưởng hoặc thống nhất chứng từ ghi giảm?
									  |Số dư thưởng lũy kế đã tính theo khách hàng là bao nhiêu?';
									  |ru = 'Сколько бонусов начислено и выдано клиентам за указанный период?
									  |Какие суммы бонусов ожидают подписания актов финансовой премии или согласования документов списания?
									  |Какой остаток начисленных ретро-бонусов по клиентам?';
									  |en = 'How many rebates were accrued and issued to customers during the specified period?
									  |What rebate amounts are pending signing of financial bonus certificates or approval of write-off documents?
									  |What is the balance of accrued rebates by customers?'; fa = 'How many rebates were accrued and issued to customers during the specified period?
									  |What rebate amounts are pending signing of financial bonus certificates or approval of write-off documents?
									  |What is the balance of accrued rebates by customers?';
									  |it = 'Сколько бонусов начислено и выдано клиентам за указанный период?
									  |Какие суммы бонусов ожидают подписания актов финансовой премии или согласования документов списания?
									  |Какой остаток начисленных ретро-бонусов по клиентам?';
									  |pl = 'How many rebates were accrued and issued to customers during the specified period?
									  |What rebate amounts are pending signing of financial bonus certificates or approval of write-off documents?
									  |What is the balance of accrued rebates by customers?';
									  |tr = 'Belirtilen dönem için müşterilere kaç ikramiye tahakkuk ettirilmiş ve verilmiştir? 
									  |Mali ikramiye belgelerinin imzalanmasını veya mahsup belgelerinin onaylanmasını bekleyen ikramiye tutarları nedir? 
									  |Müşteriler tarafından tahakkuk ettirilen retro ikramiye bakiyesi nedir?'");
	OptionSettings.Location.Insert(Metadata.Subsystems.CRMAndMarketing.Subsystems.CustomerRebates);
	
	ReportsOptions.SetOutputModeInReportPanels(Settings, ReportSettings, DisplayReportOptions);
	
	TMReportOptionsOverridable.DisableReportOption(
		Settings,
		ReportSettings,
		"StatementOnCustomerRebatesContext");
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//   VariantKey - String - 
//   
//	Returns:
//		ValueTableRow - description of the created team.
//
Function AddReportCommand(ReportsCommands, Parameters, VariantKey = "") Export
	
	If AccessRight("View", Metadata.Reports.CustomerRebateStatement)
	   And GetFunctionalOption("UseCustomerRebates") Then
		
		ReportCommand = ReportsCommands.Add();
		Presentation = NStr("vi = 'Bảng kê thưởng lũy kế đã tính';
							|ru = 'Ведомость по начисленным ретро-бонусам';
							|en = 'Accrued rebate statement'; fa = 'Accrued rebate statement';
							|it = 'Ведомость по начисленным ретро-бонусам';
							|pl = 'Accrued rebate statement';
							|tr = 'Tahakkuk eden retro-bonus tablosu'");
		ReportCommand.Manager = Metadata.Reports.CustomerRebateStatement.FullName();
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

#EndIf