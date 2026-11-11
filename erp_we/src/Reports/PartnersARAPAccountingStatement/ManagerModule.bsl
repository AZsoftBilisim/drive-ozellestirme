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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.PartnersARAPAccountingStatement);
	DescriptionStatementOfSettlementsWithPartners = NStr("vi = 'Phân tích tổng hợp hạch toán công nợ với khách hàng và nhà cung cấp.
											|Công nợ thay đổi như thế nào trong kỳ?
											|Số dư hạch toán hiện tại là bao nhiêu?';
											|ru = 'Сводный анализ взаиморасчетов с клиентами и поставщиками.
											|Как изменялась задолженность за указанный период?
											|Какое текущее сальдо расчетов?';
											|en = 'Summary analysis of AR/AP with customers and vendors.
											|Check how the debt has changed over the specified period.
											|Verify the current AR/AP balance.'; fa = 'Summary analysis of AR/AP with customers and vendors.
											|Check how the debt has changed over the specified period.
											|Verify the current AR/AP balance.';
											|it = 'Сводный анализ взаиморасчетов с клиентами и поставщиками.
											|Как изменялась задолженность за указанный период?
											|Какое текущее сальдо расчетов?';
											|pl = 'Skonsolidowana analiza rozliczeń wzajemnych z klientami i dostawcami. 
											|Jak zmieniało się zobowiązanie za wskazany okres? 
											|Jakie jest bieżące saldo rozliczeń?';
											|tr = 'Müşteriler ve tedarikçilerle alacak/borç muhasebesinin özet analizi.
											|Belirlenen dönemde borç nasıl değişmiştir?
											|Mevcut alacak/borç muhasebesi bakiyesi nedir?'");
	DescriptionOfReport.DefineFormSettings = True;
	ReportsOptions.SetOutputModeInReportPanels(Settings, DescriptionOfReport, False);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "PartnersARAPAccounting");
	OptionDetails.LongDesc = DescriptionStatementOfSettlementsWithPartners;
	OptionDetails.DefaultVisibility = False;
	OptionDetails.FunctionalOptions.Add("NotBaseVersion");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "SettlementsWithPartnersAreBasic");
	OptionDetails.LongDesc = DescriptionStatementOfSettlementsWithPartners;
	OptionDetails.DefaultVisibility = False;
	OptionDetails.FunctionalOptions.Add("BaseVersion");
	
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ByCounterpartiesContext");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ForCounterpartiesContextBasic");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ByPartnersContext");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ByPartnersContextBasic");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ReconciliationOfSettlements");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ReconciliationOfMutualSettlementsContextBasic");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "OnDebtOffsetContext");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ForDebtOffsetContextBasic");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
