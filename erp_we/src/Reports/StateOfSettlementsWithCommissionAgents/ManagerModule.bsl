#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
//  Undefined, ValueTableRow - report command
Function AddReportCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.StateOfSettlementsWithCommissionAgents) 
			And GetFunctionalOption("UseSalesCommission") Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.StateOfSettlementsWithCommissionAgents.FullName();
		ReportCommand.Presentation = NStr("vi = 'Trạng thái hạch toán với người bán ký gửi';
											|ru = 'Состояние расчетов с комиссионерами';
											|en = 'Consignee AR/AP'; fa = 'دریافتنی/پرداختنی امانت‌دار';
											|it = 'Stato dei regolamenti con commissionari';
											|pl = 'Stan rozliczeń z komisantami';
											|tr = 'Komisyon acenteleri ile anlaşmaların durumu'");
		
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.HasVisibilityConditions = True;
		
		AttachableCommands.AddCommandVisibilityCondition(ReportCommand,
			"BusinessOperation",
			Enums.BusinessTransactions.SalesViaCommissionAgent, 
			DataCompositionComparisonType.NotEqual);
		
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
	
	PostfixCommissionSchemes = ConsignmentSalesServer.PostfixCommissionSchemes();
	OptionDescription = StringFunctionsClientServer.SubstituteParametersToString(
	NStr("vi = 'Trạng thái hạch toán với người nhận ký gửi (%1)';
		|ru = 'Состояние расчетов с комиссионерами (%1)';
		|en = 'Consignee AR/AP (%1)'; fa = 'Consignee AR/AP (%1)';
		|it = 'Состояние расчетов с комиссионерами (%1)';
		|pl = 'Consignee AR/AP (%1)';
		|tr = 'Konsinyeler ile mutabakatların durumu (%1)'"),
	PostfixCommissionSchemes);
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.StateOfSettlementsWithCommissionAgents);
	DescriptionOfReport.DefineFormSettings = True;
	ReportsOptions.SetOutputModeInReportPanels(Settings, DescriptionOfReport, False);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.Description = OptionDescription;
	OptionDetails.LongDesc = NStr("vi = 'Người nhận ký gửi đang nợ chúng ta bao nhiêu tiền cho hàng hóa đã bán?
		|Chúng ta đang nợ người nhận ký gửi bao nhiêu (ví dụ: tiền hoa hồng ký gửi)?';
		|ru = 'Сколько комиссионер должен нам за проданные товары?
		|Сколько мы должны комиссионеру, например, по вознаграждениям?';
		|en = 'Track how much a consignee owes us for the sold goods.
		|Verify how much we owe a consignee (for example, fees).'; fa = 'Track how much a consignee owes us for the sold goods.
		|Verify how much we owe a consignee (for example, fees).';
		|it = 'Сколько комиссионер должен нам за проданные товары?
		|Сколько мы должны комиссионеру, например, по вознаграждениям?';
		|pl = 'Ile komisant jest nam dłużny za sprzedane wiersze pozycji? 
		|Ile jesteśmy dłużni komisantowi, na przykład, według wynagrodzeń?';
		|tr = 'Satılan ürünler için konsinye bize ne kadar borçludur?
		|Örneğin ücret için konsinyeye ne kadar borcumuz var?'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "StateOfSettlementsWithCommissionAgents");
	OptionDetails.Description = OptionDescription;
	OptionDetails.LongDesc = NStr("vi = 'Người nhận ký gửi đang nợ chúng ta bao nhiêu tiền cho hàng hóa đã bán?
		|Chúng ta đang nợ người nhận ký gửi bao nhiêu (ví dụ: tiền hoa hồng ký gửi)?';
		|ru = 'Сколько комиссионер должен нам за проданные товары?
		|Сколько мы должны комиссионеру, например, по вознаграждениям?';
		|en = 'Track how much a consignee owes us for the sold goods.
		|Verify how much we owe a consignee (for example, fees).'; fa = 'Track how much a consignee owes us for the sold goods.
		|Verify how much we owe a consignee (for example, fees).';
		|it = 'Сколько комиссионер должен нам за проданные товары?
		|Сколько мы должны комиссионеру, например, по вознаграждениям?';
		|pl = 'Ile komisant jest nam dłużny za sprzedane wiersze pozycji? 
		|Ile jesteśmy dłużni komisantowi, na przykład, według wynagrodzeń?';
		|tr = 'Satılan ürünler için konsinye bize ne kadar borçludur?
		|Örneğin ücret için konsinyeye ne kadar borcumuz var?'");
	OptionDetails.FunctionalOptions.Add("UseNonBaseSalesCommission");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "StatusOfSettlementsWithCommissionAgentsIsBasic");
	OptionDetails.FunctionalOptions.Add("UseBaseSalesCommission");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "StatusOfSettlementsWithCommissionAgentsContext");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "StateOfSettlementsWithCommissionAgentsContext");
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf