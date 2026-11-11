//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//   DisplayReportOptions - Boolean
//
Procedure CustomizeReportOptions(Settings, DisplayReportOptions) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.AccountingReportWithCorrespondenceFinancialAccounting);
	DescriptionOfReport.DefineFormSettings = True;
	ReportsOptions.SetOutputModeInReportPanels(Settings, DescriptionOfReport, DisplayReportOptions);
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "AccountAnalysisInternational");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích phát sinh giữa tài khoản được chọn và tất cả tài khoản còn lại.';
									|ru = 'Анализ оборотов между выбранным счетом и всеми остальными счетами.';
									|en = 'Analyze turnovers between the selected account and all the other accounts.'; fa = 'Analyze turnovers between the selected account and all the other accounts.';
									|it = 'Анализ оборотов между выбранным счетом и всеми остальными счетами.';
									|pl = 'Analiza obrotów między wybranym kontem i wszystkimi pozostałymi kontami.';
									|tr = 'Seçilen hesap ile diğer tüm hesaplar arasındaki ciro analizi.'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "OSVOnAccountWithCorrespondenceInternational");
	OptionDetails.LongDesc = NStr("vi = 'Số dư vào đầu và cuối kỳ, phát sinh tài khoản được chọn theo từng tài khoản đối ứng.';
									|ru = 'Остатки на начало и конец периода, а также обороты выбранного счета в разрезе корреспондирующих счетов.';
									|en = 'Balance as of the period start and end and selected account turnovers by offsetting accounts.'; fa = 'Balance as of the period start and end and selected account turnovers by offsetting accounts.';
									|it = 'Остатки на начало и конец периода, а также обороты выбранного счета в разрезе корреспондирующих счетов.';
									|pl = 'Salda na początek i koniec okresu, a także obroty wybranego konta w przekroju kont korespondencyjnych.';
									|tr = 'Dönemin başındaki ve sonundaki bakiyeler ile muhabir hesaplar bağlamında seçilen hesabın cirosu.'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
