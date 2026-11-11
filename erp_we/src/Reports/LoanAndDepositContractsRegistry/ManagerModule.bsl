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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.LoanAndDepositContractsRegistry);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Các mục tin trong hợp đồng tín dụng và tiền gửi.';
									|ru = 'Реквизиты договоров кредитов и депозитов.';
									|en = 'Credit and deposit contract details.'; fa = 'Credit and deposit contract details.';
									|it = 'Реквизиты договоров кредитов и депозитов.';
									|pl = 'Atrybuty kontraktów pożyczek i depozytów.';
									|tr = 'Kredi ve mevduat sözleşmelerinin öznitelikleri.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "RegisterOfLoanDepositAgreements");
	OptionDetails.LongDesc = NStr("vi = 'Hợp đồng có kiểu chỉ định với các mục tin,
		|số tiền dự tính thanh toán và tính toán, thanh toán và tính toán thực tế,
		|chênh lệch và số dư nợ theo hợp đồng.';
		|ru = 'Договоры указанного типа с реквизитами,
		|суммами плана оплат и начислений, фактом оплат и начислений,
		|отклонениями и остатком долга по договору.';
		|en = 'View contracts of the specified type with details,
		|amounts of payment and accrual plan, actual payments and accruals,
		|variances and remaining debt under the contract.'; fa = 'View contracts of the specified type with details,
		|amounts of payment and accrual plan, actual payments and accruals,
		|variances and remaining debt under the contract.';
		|it = 'Договоры указанного типа с реквизитами,
		|суммами плана оплат и начислений, фактом оплат и начислений,
		|отклонениями и остатком долга по договору.';
		|pl = 'Kontrakty wskazanego typu z atrybutami, 
		|wartościami planu płatności i naliczania, faktem płatności i naliczania, 
		|odchyleniami i długu bieżącego według kontraktu.';
		|tr = 'Öznitelikler,
		|ödeme ve tahakkuk planı tutarları, ödemeler ve tahakkuklar,
		|sapmalar ve sözleşme kapsamındaki borç bakiyesi ile belirtilen türden sözleşmeler.'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
