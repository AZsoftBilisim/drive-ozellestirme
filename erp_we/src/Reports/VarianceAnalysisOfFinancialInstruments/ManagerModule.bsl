#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   VariantKey - String - Option Key
// 
// Returns:
//     ValueTableRow
//
Function AddReportCommand(ReportsCommands, VariantKey = "") Export
	
	Result = Undefined;
	
	If AccessRight("View", Metadata.Reports.VarianceAnalysisOfFinancialInstruments) Then
		
		ReportCommand = ReportsCommands.Add();
		ReportCommand.Manager = Metadata.Reports.VarianceAnalysisOfFinancialInstruments.FullName();
		ReportCommand.Presentation = NStr("vi = 'Phân tích kế hoạch thực tế';
											|ru = 'План-фактный анализ';
											|en = 'Variance analysis'; fa = 'Variance analysis';
											|it = 'Analisi degli indicatori preventivati e effettivi';
											|pl = 'Analiza planowa-faktyczna';
											|tr = 'Varyans analizi'");
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Ordinary";
		If ValueIsFilled(VariantKey) Then
			ReportCommand.VariantKey = VariantKey;
		EndIf;
		Result = ReportCommand;
	EndIf;
	
	Return Result;
	
EndFunction

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.VarianceAnalysisOfFinancialInstruments);
	DescriptionOfReport.DefineFormSettings = True;
	DescriptionOfReport.LongDesc = NStr("vi = 'Phân tích chênh lệch theo các khoản thanh toán và tính lãi thực tế
		|trong khuôn khổ hợp đồng đã ký.';
		|ru = 'Анализ отклонений по фактически произведенным оплатам и начислениям
		|в рамках заключенных договоров.';
		|en = 'Check variance analysis by actual payments and accruals
		|under concluded contracts.'; fa = 'Check variance analysis by actual payments and accruals
		|under concluded contracts.';
		|it = 'Анализ отклонений по фактически произведенным оплатам и начислениям
		|в рамках заключенных договоров.';
		|pl = 'Analiza odchyleń według faktycznie przeprowadzonych płatności i kwot doliczonych 
		|w ramach zawartych kontraktów.';
		|tr = 'Yapılan sözleşmeler kapsamında gerçekleşen ödemeler ve tahakkuklardaki
		|sapmaların analizi.'");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "PlanFactualAnalysisLoansDepositsContext");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf