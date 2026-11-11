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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.BalanceSheetStatementControl);
	DescriptionOfReport.DefineFormSettings = True;
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "BalanceControlContext");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "BalanceControl");
	OptionDetails.LongDesc = NStr("vi = 'Kiểm soát các chỉ tiêu tài chính theo tháng, dạng tài sản/nguồn vốn và chứng từ.';
									|ru = 'Контроль финансовых показателей по месяцам, статьям активов/пассивов и документам.';
									|en = 'Control over financial indicators by months, asset/liability items, and documents.'; fa = 'Control over financial indicators by months, asset/liability items, and documents.';
									|it = 'Контроль финансовых показателей по месяцам, статьям активов/пассивов и документам.';
									|pl = 'Kontrola wskaźników finansowych według miesięcy, pozycji aktywów/zobowiązań i dokumentów.';
									|tr = 'Aylara, varlık/yükümlülük kalemlerine ve belgelere göre finansal göstergelerin kontrolü.'");
	OptionDetails.FunctionalOptions.Add("NotBaseVersion");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
