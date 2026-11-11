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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ArticulationStatementFinancialAccounting);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Trình bày chi tiết phát sinh giữa các tài khoản.';
									|ru = 'Развернутое представление оборотов между счетами.';
									|en = 'Expanded presentation of turnovers between accounts.'; fa = 'Expanded presentation of turnovers between accounts.';
									|it = 'Развернутое представление оборотов между счетами.';
									|pl = 'Rozwinięta prezentacja obrotów między kontami.';
									|tr = 'Hesaplar arasındaki ciroların genişletilmiş görünümü.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ChessSheetInt");
	OptionDetails.LongDesc = NStr("vi = 'Trình bày chi tiết phát sinh giữa các tài khoản.';
									|ru = 'Развернутое представление оборотов между счетами.';
									|en = 'Expanded presentation of turnovers between accounts.'; fa = 'Expanded presentation of turnovers between accounts.';
									|it = 'Развернутое представление оборотов между счетами.';
									|pl = 'Rozwinięta prezentacja obrotów między kontami.';
									|tr = 'Hesaplar arasındaki ciroların genişletilmiş görünümü.'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
