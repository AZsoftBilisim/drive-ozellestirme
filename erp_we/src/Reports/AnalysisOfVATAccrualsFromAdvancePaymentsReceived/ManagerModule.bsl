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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.AnalysisOfVATAccrualsFromAdvancePaymentsReceived);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc =
		NStr("vi = 'Phân tích tính thuế GTGT từ khoản ứng trước đã nhận theo từng đối tác và chứng từ thanh toán';
			|ru = 'Анализ начислений НДС с полученных авансов в разрезе контрагентов и документов оплаты';
			|en = 'Analyze VAT accruals from prepayments from customer broken down by counterparties and AR/AP transactions'; fa = 'Analyze VAT accruals from prepayments from customer broken down by counterparties and AR/AP transactions';
			|it = 'Анализ начислений НДС с полученных авансов в разрезе контрагентов и документов оплаты';
			|pl = 'Analiza naliczeń VAT z otrzymanych zaliczek w przekroju kontrahentów i dokumentów płatności';
			|tr = 'Cari hesaplardan alınan avanslardan KDV tahakkuklarının ve ödeme belgelerinin analizi'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
