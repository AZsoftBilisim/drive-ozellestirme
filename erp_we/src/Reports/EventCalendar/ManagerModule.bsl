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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.EventCalendar);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Danh sách hồ sơ hiện tại - đã quá hạn và dự tính.';
									|ru = 'Список текущих дел - просроченных и запланированных.';
									|en = 'To-do list - overdue and planned.'; fa = 'To-do list - overdue and planned.';
									|it = 'Список текущих дел - просроченных и запланированных.';
									|pl = 'Listy bieżących spraw - zaległych i zaplanowanych.';
									|tr = 'Yapılacaklar listesi; vadesi geçmiş ve planlanmış.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "Main");
	OptionDetails.LongDesc = NStr("vi = 'Danh sách hồ sơ hiện tại - đã quá hạn và dự tính.';
									|ru = 'Список текущих дел - просроченных и запланированных.';
									|en = 'To-do list - overdue and planned.'; fa = 'To-do list - overdue and planned.';
									|it = 'Список текущих дел - просроченных и запланированных.';
									|pl = 'Listy bieżących spraw - zaległych i zaplanowanych.';
									|tr = 'Yapılacaklar listesi; vadesi geçmiş ve planlanmış.'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
