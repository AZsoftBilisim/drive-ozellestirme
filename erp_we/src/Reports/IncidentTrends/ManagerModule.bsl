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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.IncidentTrends);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Biến động giao tiếp của người sử dụng về sự cố trong kỳ.';
									|ru = 'Динамика обращений пользователей по инцидентам за период.';
									|en = 'Trends of user support tickets on incidents for the period.'; fa = 'Trends of user support tickets on incidents for the period.';
									|it = 'Динамика обращений пользователей по инцидентам за период.';
									|pl = 'Dynamika zgłoszeń użytkowników w sprawie incydentów za okres.';
									|tr = 'Dönem boyunca olaylar için kullanıcı başvurularının dinamikleri.'");
	OptionDetails.FunctionalOptions.Add("UseIncidents");
	OptionDetails.Location.Insert(ReportsOptionsClientServer.HomePageID());
	OptionDetails.DefaultVisibility = True;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
