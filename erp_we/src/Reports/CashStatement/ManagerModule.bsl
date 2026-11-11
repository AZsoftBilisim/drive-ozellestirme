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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.CashStatement);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "CashStatement");
	OptionDetails.LongDesc = NStr("vi = 'Có bao nhiêu tiền trong các tài khoản thanh toán và quỹ tiền mặt, bao nhiêu tiền đang chuyển?';
									|ru = 'Сколько денежных средств на расчетных счетах и в кассах, в пути?';
									|en = 'Check how much cash is on accounts, cash accounts, and in transit.'; fa = 'Check how much cash is on accounts, cash accounts, and in transit.';
									|it = 'Сколько денежных средств на расчетных счетах и в кассах, в пути?';
									|pl = 'Ile środków pieniężnych jest na rachunkach bieżących i w kasach, w drodze?';
									|tr = 'Cari hesaplarda, kasalarda ve nakil halinde ne kadar nakit var?'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "StatementOfFundsMobileClient");
	OptionDetails.LongDesc = NStr("vi = 'Có bao nhiêu tiền trong các tài khoản thanh toán và quỹ tiền mặt, bao nhiêu tiền đang chuyển?';
									|ru = 'Сколько денежных средств на расчетных счетах и в кассах, в пути?';
									|en = 'Check how much cash is on accounts, cash accounts, and in transit.'; fa = 'Check how much cash is on accounts, cash accounts, and in transit.';
									|it = 'Сколько денежных средств на расчетных счетах и в кассах, в пути?';
									|pl = 'Ile środków pieniężnych jest na rachunkach bieżących i w kasach, w drodze?';
									|tr = 'Cari hesaplarda, kasalarda ve nakil halinde ne kadar nakit var?'");
	OptionDetails.Description = NStr("vi = 'Sổ quỹ tiền mặt (di động)';
									|ru = 'Ведомость по денежным средствам (моб.)';
									|en = 'Cash statement (mob. client)'; fa = 'صورت نقدی (کلاینت موبایل)';
									|it = 'Ведомость по денежным средствам (моб.)';
									|pl = 'Zestawienie według środków pieniężnych (mob.)';
									|tr = 'Nakit ekstresi (mob.)'");
	OptionDetails.DefaultVisibility = True;
	OptionDetails.Purpose = Enums.ReportOptionPurposes.ForSmartphones;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
