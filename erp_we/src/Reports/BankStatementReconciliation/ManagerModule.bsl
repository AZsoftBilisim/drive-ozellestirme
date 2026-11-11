//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.BankStatementReconciliation);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "DailyReport");
	OptionDetails.LongDesc = NStr("vi = 'Có chênh lệch trong dữ liệu của hệ thống với bảng kê ngân hàng được đã kết nhập hay không?';
									|ru = 'Есть ли расхождения данных системы с загруженными выписками банка?';
									|en = 'Control any possible discrepancies between the application data and the imported bank statements.'; fa = 'Control any possible discrepancies between the application data and the imported bank statements.';
									|it = 'Есть ли расхождения данных системы с загруженными выписками банка?';
									|pl = 'Czy jest odchylenie danych systemu z pobranymi wyciągami banku?';
									|tr = 'Sistem verileri ile yüklenen banka ekstreleri arasında herhangi bir tutarsızlık var mı?'");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "StatementByDayOneAccount");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
