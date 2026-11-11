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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.AccountCardFinancialAccounting);
	DescriptionOfReport.DefineFormSettings = True;
	ReportsOptions.SetOutputModeInReportPanels(Settings, DescriptionOfReport, DisplayReportOptions);
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích chi tiết bút toán theo tài khoản kế toán.';
									|ru = 'Детальный анализ проводок по счетам учета.';
									|en = 'Detailed ledger account entry analysis.'; fa = 'Detailed ledger account entry analysis.';
									|it = 'Детальный анализ проводок по счетам учета.';
									|pl = 'Analiza szczegółowa wpisów księgowych według kont księgowych.';
									|tr = 'Defterikebir hesapları kapsamında girişlerin detaylı analizi.'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "AccountCardFinancialAccounting");
	OptionDetails.LongDesc = NStr("vi = 'Tài khoản đối ứng cho kỳ đã chọn trong đó sử dụng tài khoản được chọn.';
									|ru = 'Корреспонденции счетов за выбранный период, в которых был использован выбранный счет.';
									|en = 'Account correspondences for the selected period when the selected account was used.'; fa = 'Account correspondences for the selected period when the selected account was used.';
									|it = 'Корреспонденции счетов за выбранный период, в которых был использован выбранный счет.';
									|pl = 'Korespondencje rachunków za wybrany okres, w których został użyty wybrany rachunek.';
									|tr = 'Seçilen hesabın kullanıldığı, seçilen döneme ait hesapların çift taraflı kaydı.'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "SummaryTransactions");
	OptionDetails.LongDesc = NStr("vi = 'Đối ứng tổng hợp giữa các tài khoản trong kỳ đã chọn.';
									|ru = 'Сводные корреспонденции между счетами за выбранный период.';
									|en = 'Summary correspondence between accounts for the selected period.'; fa = 'Summary correspondence between accounts for the selected period.';
									|it = 'Сводные корреспонденции между счетами за выбранный период.';
									|pl = 'Skonsolidowane korespondencje między rachunkami za wybrany okres.';
									|tr = 'Seçilen dönem için hesaplar arasındaki özet yazışmalar.'");
	OptionDetails.FunctionalOptions.Add(Metadata.FunctionalOptions.FinancialAccountingEntriesWithCorrespondence.Name);
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "TransactionReportInternational");
	OptionDetails.LongDesc = NStr("vi = 'Hiển thị bút toán theo tài khoản kế toán.';
									|ru = 'Вывод проводок по счетам учета.';
									|en = 'Ledger account entry display.'; fa = 'Ledger account entry display.';
									|it = 'Вывод проводок по счетам учета.';
									|pl = 'Wyprowadzenie wpisów księgowych według kont księgowych.';
									|tr = 'Defterikebir hesap girişi görüntüleme.'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
