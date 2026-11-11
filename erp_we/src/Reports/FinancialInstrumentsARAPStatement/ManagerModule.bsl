#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
//	ValueTableRow, Undefined - the generated command to output to the submenu.
Function AddReportCommand(ReportsCommands) Export
	
	Result = Undefined;
	
	If AccessRight("View", Metadata.Reports.FinancialInstrumentsARAPStatement) Then
		
		ReportCommand = ReportsCommands.Add();
		ReportCommand.Manager = Metadata.Reports.FinancialInstrumentsARAPStatement.FullName();
		ReportCommand.Presentation = NStr("vi = 'Bảng kê hạch toán';
											|ru = 'Ведомость расчетов';
											|en = 'Accounts payables and receivables'; fa = 'حساب‌های پرداختنی و دریافتنی';
											|it = 'Elenco regolamenti dei conti';
											|pl = 'Oświadczenie o płatności';
											|tr = 'Mutabakat tablosu'");
		ReportCommand.MultipleChoice = True;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.VariantKey = "StatementOfSettlementsOnFinancialInstrumentsContext";
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.FinancialInstrumentsARAPStatement);
	DescriptionOfReport.DefineFormSettings = True;
	DescriptionOfReport.LongDesc = NStr("vi = 'Kiểm soát thu và chi tiền theo các công cụ tài chính.';
										|ru = 'Контроль поступлений и списаний денежных средств по финансовым инструментам.';
										|en = 'Control incoming and outgoing payments by financial instruments.'; fa = 'Control incoming and outgoing payments by financial instruments.';
										|it = 'Контроль поступлений и списаний денежных средств по финансовым инструментам.';
										|pl = 'Kontrola wpłat i rozchodów środków pieniężnych-gotówki według instrumentów finansowych.';
										|tr = 'Finansal araçlar kapsamında nakit girişlerinin ve gider yazmalarının kontrolü.'");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "StatementOfSettlementsOnFinancialInstrumentsContext");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf