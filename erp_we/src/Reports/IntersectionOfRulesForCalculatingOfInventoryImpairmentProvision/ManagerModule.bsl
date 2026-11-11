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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.IntersectionOfRulesForCalculatingOfInventoryImpairmentProvision);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Những quy tắc nào giao nhau về điều kiện lọc?';
									|ru = 'Какие правила пересекаются по условиям отбора?';
									|en = 'What rules overlap by the filter criteria?'; fa = 'What rules overlap by the filter criteria?';
									|it = 'Какие правила пересекаются по условиям отбора?';
									|pl = 'Jakie reguły są przekraczane według warunków filtru?';
									|tr = 'Filtre açısından hangi koşullar kesişir?'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
