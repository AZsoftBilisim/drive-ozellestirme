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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.VATAccountingAnalysisOnPrepaymentsToVendorSettlement);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc =
		NStr("vi = 'Phân tích tính thuế GTGT khấu trừ khoản ứng trước đã xuất theo từng đối tác và chứng từ thanh toán';
			|ru = 'Анализ учета НДС по зачетам выданных авансов в разрезе контрагентов и документов оплаты';
			|en = 'Analyze VAT accounting by received prepayments with a breakdown by counterparties and AR/AP transactions'; fa = 'Analyze VAT accounting by received prepayments with a breakdown by counterparties and AR/AP transactions';
			|it = 'Анализ учета НДС по зачетам выданных авансов в разрезе контрагентов и документов оплаты';
			|pl = 'Analiza ewidencji VAT wg zaliczeń wydanych zaliczek w przekroju kontrahentów i dokumentów płatności';
			|tr = 'Cari hesaplarca verilen avansların ve ödeme belgelerinin mahsup edilmesine ilişkin KDV muhasebesinin analizi'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
