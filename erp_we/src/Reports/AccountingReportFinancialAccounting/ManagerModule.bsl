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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.AccountingReportFinancialAccounting);
	DescriptionOfReport.DefineFormSettings = True;
	ReportsOptions.SetOutputModeInReportPanels(Settings, DescriptionOfReport, DisplayReportOptions);
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích số dư và phát sinh theo tài khoản kế toán tài chính quốc tế.';
									|ru = 'Анализ сальдо и оборотов по счетам международного финансового учета.';
									|en = 'Analysis of financial accounting account balance and turnovers.'; fa = 'Analysis of financial accounting account balance and turnovers.';
									|it = 'Анализ сальдо и оборотов по счетам международного финансового учета.';
									|pl = 'Analiza saldo i obrotów wedłu kont międzynarodowej ewidencji finansowej';
									|tr = 'Uluslararası finansal muhasebe hesaplarındaki bakiyelerin ve ciroların analizi.'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "AnalysisOfCounterpartySettlements");
	OptionDetails.DefaultVisibility = False;
	OptionDetails.LongDesc = NStr("vi = 'Phân tích tổng hợp hạch toán công nợ với đối tác (khách hàng và nhà cung cấp, người phải thu và người phải trả).';
									|ru = 'Сводный анализ взаиморасчетов с контрагентами (клиентами и поставщиками, дебиторами и кредиторами).';
									|en = 'Summary analysis of AR/AP accounting with counterparties (customers and vendors, debtors and creditors).'; fa = 'Summary analysis of AR/AP accounting with counterparties (customers and vendors, debtors and creditors).';
									|it = 'Сводный анализ взаиморасчетов с контрагентами (клиентами и поставщиками, дебиторами и кредиторами).';
									|pl = 'Skonsolidowana analiza rozliczeń wzajemnych z kontrahentami (nabywcami i dostawcami, dłużnikami i wierzycielami).';
									|tr = 'Cari hesaplarla (müşterilerle ve tedarikçilerle, borçlularla ve alacaklılarla) mutabakatın özet analizi.'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "AnalysisOfExtdimensionInternational");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích số dư và phát sinh theo một hoặc nhiều khoản mục được chọn.';
									|ru = 'Анализ остатков и оборотов по выбранным одному или нескольким субконто.';
									|en = 'Analyze balance and turnover for the selected one or multiple extra dimensions.'; fa = 'Analyze balance and turnover for the selected one or multiple extra dimensions.';
									|it = 'Анализ остатков и оборотов по выбранным одному или нескольким субконто.';
									|pl = 'Analiza sald i obrotów według wybranych jednego lub kilku subkonto.';
									|tr = 'Seçilen bir veya daha fazla ekstra boyut kapsamında bakiyelerin ve ciroların analizi.'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "OSV_International");
	OptionDetails.LongDesc = NStr("vi = 'Số dư vào đầu và cuối kỳ, phát sinh vào kỳ theo tất cả tài khoản kế toán';
									|ru = 'Остатки на начало и конец периода, а также обороты за период по всем счетам учета';
									|en = 'Balance as of the period start and end and all ledger account turnovers for the period'; fa = 'Balance as of the period start and end and all ledger account turnovers for the period';
									|it = 'Остатки на начало и конец периода, а также обороты за период по всем счетам учета';
									|pl = 'Salda na początek i koniec okresu, a także obroty za okres według wszystkich kont księgowych';
									|tr = 'Tüm muhasebe hesapları kapsamında dönem başı ve dönem sonu bakiyeleri ve ayrıca dönem ciroları'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "OSV_OnAccountOfInternational");
	OptionDetails.LongDesc = NStr("vi = 'Số dư vào đầu và cuối kỳ, phát sinh trong kỳ theo tài khoản kế toán được chọn.';
									|ru = 'Остатки на начало и конец периода, а также обороты за период по выбранному счету учета.';
									|en = 'Balance as of the period start and end and selected ledger account turnovers for the period.'; fa = 'Balance as of the period start and end and selected ledger account turnovers for the period.';
									|it = 'Остатки на начало и конец периода, а также обороты за период по выбранному счету учета.';
									|pl = 'Salda na początek i koniec okresu, a także obroty za okres według wybranego konta księgowego.';
									|tr = 'Seçilen defterikebir hesabı kapsamında dönem başı ve dönem sonu bakiyeleri ve ayrıca dönem ciroları.'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
