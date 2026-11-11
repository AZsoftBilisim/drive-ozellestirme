#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// Returns:
//   ValueTableRow - new report command.
Function AddReportCommand(ReportsCommands) Export
	
	If AccessRight("View", Metadata.Reports.SpreadsheetOfIntangibleAssetsAndRDExpenses)
		And NonCurrentAssets.VNAManagementIsUsed_2_4()
		And Not NonCurrentAssetsInternal.ComplianceCAAccountingIsKept() Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.SpreadsheetOfIntangibleAssetsAndRDExpenses.FullName();
		ReportCommand.Presentation = NStr("vi = 'Báo cáo TSCĐ vô hình';
											|ru = 'Ведомость по НМА';
											|en = 'Intangible asset statement'; fa = 'Intangible asset statement';
											|it = 'Ведомость по НМА';
											|pl = 'Intangible asset statement';
											|tr = 'Maddi olmayan varlık bildirimi'");
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.AdditionalParameters.Insert("CommandName", "SpreadsheetOfIntangibleAssetsAndRDExpenses");
		ReportCommand.VariantKey = "StatementOnIA";
		
		Return ReportCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//   ComplianceCAAccountingIsKept - Boolean
//
Procedure CustomizeReportOptions(Settings, ComplianceCAAccountingIsKept) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.SpreadsheetOfIntangibleAssetsAndRDExpenses);
	DescriptionOfReport.DefineFormSettings = True;

	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.Enabled = Not ComplianceCAAccountingIsKept;
	OptionDetails.LongDesc = NStr("vi = 'Dữ liệu tóm tắt về chi phí và khấu hao Tài sản cố định vô hình và chi phí Nghiên cứu và phát triển là gì?';
									|ru = 'Какие сводные данные о стоимости и амортизации НМА и расходов на НИОКР?';
									|en = 'Take an overview of cost and amortization of intangible assets and R&D expenses.'; fa = 'Take an overview of cost and amortization of intangible assets and R&D expenses.';
									|it = 'Какие сводные данные о стоимости и амортизации НМА и расходов на НИОКР?';
									|pl = 'Jakie jest podsumowanie wartości i amortyzacji kosztów NMA i kosztów badań i rozwoju?';
									|tr = 'Maddi olmayan varlıklar ve Ar-Ge giderlerinin maliyeti ve amortismanı hakkında özet bilgi'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "StatementOnIA_Main");
	OptionDetails.Enabled = Not ComplianceCAAccountingIsKept;
	OptionDetails.DefaultVisibility = Not ComplianceCAAccountingIsKept;
	OptionDetails.LongDesc = NStr("vi = 'Dữ liệu tóm tắt về chi phí và khấu hao Tài sản cố định vô hình và chi phí Nghiên cứu và phát triển là gì?';
									|ru = 'Какие сводные данные о стоимости и амортизации НМА и расходов на НИОКР?';
									|en = 'Take an overview of cost and amortization of intangible assets and R&D expenses.'; fa = 'Take an overview of cost and amortization of intangible assets and R&D expenses.';
									|it = 'Какие сводные данные о стоимости и амортизации НМА и расходов на НИОКР?';
									|pl = 'Jakie jest podsumowanie wartości i amortyzacji kosztów NMA i kosztów badań i rozwoju?';
									|tr = 'Maddi olmayan varlıklar ve Ar-Ge giderlerinin maliyeti ve amortismanı hakkında özet bilgi'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "StatementOnNMA_BU");
	OptionDetails.Enabled = Not ComplianceCAAccountingIsKept;
	OptionDetails.DefaultVisibility = False;
	OptionDetails.LongDesc = NStr("vi = 'Dữ liệu tổng hợp nào về giá trị và khấu hao TSCĐ vô hình và chi phí nghiên cứu, triển khai trong kế toán doanh nghiệp?';
									|ru = 'Какие сводные данные о стоимости и амортизации НМА и расходов на НИОКР в бухгалтерском учете?';
									|en = 'Check summary data on the cost and amortization of intangible assets and R&D expenses in local accounting.'; fa = 'Check summary data on the cost and amortization of intangible assets and R&D expenses in local accounting.';
									|it = 'Какие сводные данные о стоимости и амортизации НМА и расходов на НИОКР в бухгалтерском учете?';
									|pl = 'Jakie jest podsumowanie wartości i amortyzacji kosztów NMA i kosztów badań i rozwoju w ewidencji księgowej?';
									|tr = 'Muhasebede maddi olmayan varlık ve Ar-Ge giderlerinin maliyeti ve amortismanı hakkında özet bilgi'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "StatementOnNMA_U");
	OptionDetails.Enabled = Not ComplianceCAAccountingIsKept;
	OptionDetails.DefaultVisibility = False;
	OptionDetails.LongDesc = NStr("vi = 'Dữ liệu tổng hợp nào về giá trị khấu hao TSCĐ vô hình và chi phí nghiên cứu, triển khai trong kế toán quản trị?';
									|ru = 'Какие сводные данные о стоимости и амортизации НМА и расходов на НИОКР в управленческом учете?';
									|en = 'Check summary data on the cost and amortization of intangible assets and R&D expenses in management accounting.'; fa = 'Check summary data on the cost and amortization of intangible assets and R&D expenses in management accounting.';
									|it = 'Какие сводные данные о стоимости и амортизации НМА и расходов на НИОКР в управленческом учете?';
									|pl = 'Jakie jest podsumowanie wartości i amortyzacji kosztów NMA i kosztów badań i rozwoju w ewidencji zarządczej?';
									|tr = 'Yönetim muhasebesinde maddi olmayan varlık ve Ar-Ge giderlerinin maliyeti ve amortismanı hakkında özet bilgi'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf