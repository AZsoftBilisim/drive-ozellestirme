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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.StatementOfFutureExpenseCommitments);
	DescriptionOfReport.LongDesc = NStr("vi = 'Bảng kê dự phòng chi phí trả trước.';
										|ru = 'Ведомость по резервам предстоящих расходов.';
										|en = 'Statement of provisions and contingent liabilities.'; fa = 'Statement of provisions and contingent liabilities.';
										|it = 'Ведомость по резервам предстоящих расходов.';
										|pl = 'Zestawienie według rezerw przyszłych wydatków.';
										|tr = 'Karşılıklar ve şarta bağlı yükümlülükler tablosu.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "FutureExpenseCommitments");
	OptionDetails.Description = NStr("vi = 'Bảng kê dự phòng';
									|ru = 'Ведомость по резервам';
									|en = 'Reserve statement '; fa = 'صورت ذخیره';
									|it = 'Ведомость по резервам';
									|pl = 'Zestawienie według rezerw';
									|tr = 'Karşılıklar tablosu'");
	OptionDetails.LongDesc = NStr("vi = 'Bảng kê dự phòng chi phí trả trước.';
									|ru = 'Ведомость по резервам предстоящих расходов.';
									|en = 'Statement of provisions and contingent liabilities.'; fa = 'Statement of provisions and contingent liabilities.';
									|it = 'Ведомость по резервам предстоящих расходов.';
									|pl = 'Zestawienie według rezerw przyszłych wydatków.';
									|tr = 'Karşılıklar ve şarta bağlı yükümlülükler tablosu.'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
