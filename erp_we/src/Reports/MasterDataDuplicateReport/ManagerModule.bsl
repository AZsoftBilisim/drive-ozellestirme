#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.MasterDataDuplicateReport);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("ru = 'Отчет по правилам поиска дублей НСИ';
									|vi = 'Report on rules for searching for master data duplicates';
									|en = 'Report on rules for searching for master data duplicates'; fa = 'Report on rules for searching for master data duplicates';
									|it = 'Report on rules for searching for master data duplicates';
									|pl = 'Report on rules for searching for master data duplicates';
									|tr = 'Master veri yinelenen öğe arama kurallarına göre rapor'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf