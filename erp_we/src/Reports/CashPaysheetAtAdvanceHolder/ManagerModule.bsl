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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.CashPaysheetAtAdvanceHolder);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "CashPaysheetAtAdvanceHolder");
	OptionDetails.LongDesc = NStr("vi = 'Bao nhiêu tiền đang được nắm giữ bởi người nhận tạm ứng?';
									|ru = 'Сколько денежных средств на руках у подотчетных лиц?';
									|en = 'Check how much cash advance holders have.'; fa = 'Check how much cash advance holders have.';
									|it = 'Сколько денежных средств на руках у подотчетных лиц?';
									|pl = 'Ile środków pieniężnych gotówki jest u zalichkobiorców?';
									|tr = 'Sorumlu kişilerin elinde ne kadar nakit var?'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
