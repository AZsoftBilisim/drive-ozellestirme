#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// Returns:
//   ValueTableRow - new report command.
Function AddReportCommand(ReportsCommands) Export
	
	If AccessRight("View", Metadata.Reports.FixedAssetsStatementManagementAccounting)
		And NonCurrentAssets.VNAManagementIsUsed_2_4()
		And Not NonCurrentAssetsInternal.ComplianceCAAccountingIsKept() Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.FixedAssetsStatementManagementAccounting.FullName();
		ReportCommand.Presentation = NStr("vi = 'Báo cáo TSCĐ hữu hình';
											|ru = 'Ведомость по ОС';
											|en = 'Fixed assets statement'; fa = 'صورت دارایی‌های ثابت';
											|it = 'Elenco Capitale Fisso';
											|pl = 'Zestawienie według ŚT';
											|tr = 'Sabit kıymet tablosu'");
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.AdditionalParameters.Insert("CommandName", "FixedAssetsStatementManagementAccounting");
		ReportCommand.VariantKey = "StatementOfAssets";
		
		Return ReportCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//  ComplianceCAAccountingIsKept - Boolean
//
Procedure CustomizeReportOptions(Settings, ComplianceCAAccountingIsKept) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.FixedAssetsStatementManagementAccounting);
	DescriptionOfReport.DefineFormSettings = True;
		
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.Enabled = Not ComplianceCAAccountingIsKept;
	OptionDetails.LongDesc = NStr("vi = 'Dữ liệu tóm tắt về chi phí và khấu hao tài sản cố định là gì?';
									|ru = 'Какие сводные данные о стоимости и амортизации основных средств?';
									|en = 'Take an overview of cost and depreciation of fixed assets.'; fa = 'Take an overview of cost and depreciation of fixed assets.';
									|it = 'Какие сводные данные о стоимости и амортизации основных средств?';
									|pl = 'Jakie są dane sumaryczne dotyczące wartości i amortyzacji środków trwałych?';
									|tr = 'Sabit kıymetlerin maliyeti ve amortismanı hakkında özet bilgi'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "StatementOfAssets");
	OptionDetails.Enabled = Not ComplianceCAAccountingIsKept;
	OptionDetails.DefaultVisibility = Not ComplianceCAAccountingIsKept;
	OptionDetails.LongDesc = NStr("vi = 'Dữ liệu tóm tắt về chi phí và khấu hao tài sản cố định là gì?';
									|ru = 'Какие сводные данные о стоимости и амортизации основных средств?';
									|en = 'Take an overview of cost and depreciation of fixed assets.'; fa = 'Take an overview of cost and depreciation of fixed assets.';
									|it = 'Какие сводные данные о стоимости и амортизации основных средств?';
									|pl = 'Jakie są dane sumaryczne dotyczące wartości i amortyzacji środków trwałych?';
									|tr = 'Sabit kıymetlerin maliyeti ve amortismanı hakkında özet bilgi'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "StatementOnOS_BU");
	OptionDetails.Enabled = Not ComplianceCAAccountingIsKept;
	OptionDetails.DefaultVisibility = False;
	OptionDetails.LongDesc = NStr("vi = 'Dữ liệu tổng hợp nào về giá trị và khấu hao tài sản cố định trong kế toán doanh nghiệp?';
									|ru = 'Какие сводные данные о стоимости и амортизации основных средств в бухгалтерском учете?';
									|en = 'Check summary data on the cost and depreciation of fixed assets in local accounting.'; fa = 'Check summary data on the cost and depreciation of fixed assets in local accounting.';
									|it = 'Какие сводные данные о стоимости и амортизации основных средств в бухгалтерском учете?';
									|pl = 'Jakie są dane sumaryczne dotyczące wartości i amortyzacji środków trwałych w ewidencji księgowej?';
									|tr = 'Genel muhasebede sabit kıymetlerin maliyeti ve amortismanı hakkında özet bilgi'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "StatementOnOS_U");
	OptionDetails.Enabled = Not ComplianceCAAccountingIsKept;
	OptionDetails.DefaultVisibility = False;
	OptionDetails.LongDesc = NStr("vi = 'Dữ liệu tổng hợp nào về giá trị và khấu hao tài sản cố định trong kế toán quản trị?';
									|ru = 'Какие сводные данные о стоимости и амортизации основных средств в управленческом учете?';
									|en = 'Check summary data on the cost and depreciation of fixed assets in management accounting.'; fa = 'Check summary data on the cost and depreciation of fixed assets in management accounting.';
									|it = 'Какие сводные данные о стоимости и амортизации основных средств в управленческом учете?';
									|pl = 'Jakie są dane sumaryczne dotyczące wartości i amortyzacji środków trwałych w ewidencji zarządczej?';
									|tr = 'Yönetim muhasebesinde sabit kıymetlerin maliyeti ve amortismanı hakkında özet bilgi'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf