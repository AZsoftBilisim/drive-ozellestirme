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

	If AccessRight("View", Metadata.Reports.StateOfSettlementsWithConsignors) 
			And GetFunctionalOption("UsePurchaseCommission") Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.StateOfSettlementsWithConsignors.FullName();
		ReportCommand.Presentation = NStr("vi = 'Trạng thái hạch toán với người đặt ký gửi';
											|ru = 'Состояние расчетов с комитентами';
											|en = 'Consignor AR/AP'; fa = 'دریافتنی/پرداختنی امانت‌گذار';
											|it = 'Stato dei regolamenti con i committenti';
											|pl = 'Stan rozliczeń z komitentami';
											|tr = 'Göndericiler ile uzlaşmaların durumu'");
		
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Ordinary";
		
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.StateOfSettlementsWithConsignors);
	DescriptionOfReport.DefineFormSettings = True;
	ReportsOptions.SetOutputModeInReportPanels(Settings, DescriptionOfReport, False);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Chúng ta đang nợ người đặt ký gửi bao nhiêu cho hàng hóa đã bán?
		|Người đặt ký gửi đang nợ chúng ta bao nhiêu, ví dụ, tiền hoa hồng ký gửi?';
		|ru = 'Сколько мы должны комитенту за реализованные товары?
		|Сколько комитент должен нам, например, по вознаграждениям?';
		|en = 'Verify how much we owe a consignor for the sold goods.
		|Check how much the consignor owes us, for example, for commissions.'; fa = 'Verify how much we owe a consignor for the sold goods.
		|Check how much the consignor owes us, for example, for commissions.';
		|it = 'Сколько мы должны комитенту за реализованные товары?
		|Сколько комитент должен нам, например, по вознаграждениям?';
		|pl = 'Ile jesteśmy dłużni komitentowi za sprzedane wiersze pozycji? 
		|Ile komitent jest dłużny nam, na przykład, według wynagrodzeń?';
		|tr = 'Satılan ürünler için göndericiye ne kadar borcumuz var?
		|Örneğin, ücret olarak göndericinin bize ne kadar borcu var?'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "StateOfSettlementsWithConsignors");
	OptionDetails.LongDesc = NStr("vi = 'Chúng ta đang nợ người đặt ký gửi bao nhiêu cho hàng hóa đã bán?
		|Người đặt ký gửi đang nợ chúng ta bao nhiêu, ví dụ, tiền hoa hồng ký gửi?';
		|ru = 'Сколько мы должны комитенту за реализованные товары?
		|Сколько комитент должен нам, например, по вознаграждениям?';
		|en = 'Verify how much we owe a consignor for the sold goods.
		|Check how much the consignor owes us, for example, for commissions.'; fa = 'Verify how much we owe a consignor for the sold goods.
		|Check how much the consignor owes us, for example, for commissions.';
		|it = 'Сколько мы должны комитенту за реализованные товары?
		|Сколько комитент должен нам, например, по вознаграждениям?';
		|pl = 'Ile jesteśmy dłużni komitentowi za sprzedane wiersze pozycji? 
		|Ile komitent jest dłużny nam, na przykład, według wynagrodzeń?';
		|tr = 'Satılan ürünler için göndericiye ne kadar borcumuz var?
		|Örneğin, ücret olarak göndericinin bize ne kadar borcu var?'");
	OptionDetails.FunctionalOptions.Add("UseNonBasePurchaseCommission");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "StatusOfSettlementsWithCommitteesIsBasic");
	OptionDetails.FunctionalOptions.Add("UseBasePurchaseCommission");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "StateOfSettlementsWithCommitteesContext");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "StateOfSettlementsWithCommitteesContextBasic");
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf