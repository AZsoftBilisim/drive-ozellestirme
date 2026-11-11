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
	
	#If Not MobileStandaloneServer Then
		
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.PerformanceDashboard);
	DescriptionOfReport.Location.Clear();
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "PerformanceDashboard");
	OptionDetails.LongDesc = NStr("vi = 'Kiểm soát các chỉ số chính (mục tiêu) của doanh nghiệp.';
									|ru = 'Контроль ключевых (целевых) показателей деятельности предприятия.';
									|en = 'Control key (target) values of enterprise activity.'; fa = 'Control key (target) values of enterprise activity.';
									|it = 'Контроль ключевых (целевых) показателей деятельности предприятия.';
									|pl = 'Kontrola kluczowych (celowych) wskaźników działalności przedsiębiorstwa.';
									|tr = 'İşletmenin temel (hedef) performans göstergelerinin kontrolü.'");
	
	#EndIf
	
EndProcedure

#EndRegion

#EndRegion

#EndIf