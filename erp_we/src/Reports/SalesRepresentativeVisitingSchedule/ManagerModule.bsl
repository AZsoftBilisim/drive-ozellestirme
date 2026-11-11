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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.SalesRepresentativeVisitingSchedule);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Dự tính ghé thăm khách hàng nào, thời gian nào và theo nhiệm vụ nào?';
									|ru = 'Когда, по какому заданию и к какому клиенту планируется визит?';
									|en = 'Verify which customers should be visited. Find out jobs and time of visit.'; fa = 'Verify which customers should be visited. Find out jobs and time of visit.';
									|it = 'Когда, по какому заданию и к какому клиенту планируется визит?';
									|pl = 'Kiedy, według jakiego zadania i do jakiego klienta jesz zaplanowana wizyta?';
									|tr = 'Ziyaret ne zaman, hangi görev için ve hangi müşteriye planlanıyor?'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "SalesRepresentativeVisitingSchedule");
	OptionDetails.LongDesc = NStr("vi = 'Dự tính ghé thăm khách hàng nào, thời gian nào và theo nhiệm vụ nào?';
									|ru = 'Когда, по какому заданию и к какому клиенту планируется визит?';
									|en = 'Verify which customers should be visited. Find out jobs and time of visit.'; fa = 'Verify which customers should be visited. Find out jobs and time of visit.';
									|it = 'Когда, по какому заданию и к какому клиенту планируется визит?';
									|pl = 'Kiedy, według jakiego zadania i do jakiego klienta jesz zaplanowana wizyta?';
									|tr = 'Ziyaret ne zaman, hangi görev için ve hangi müşteriye planlanıyor?'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
