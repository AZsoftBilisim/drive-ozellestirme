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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ProductRangeAndSalesTrends);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Làm thế nào để thay đổi điền danh điểm theo thời gian?';
									|ru = 'Как изменяется наполнение ассортимента со временем?';
									|en = 'Verify how the product range completeness change over time.'; fa = 'Verify how the product range completeness change over time.';
									|it = 'Как изменяется наполнение ассортимента со временем?';
									|pl = 'Jak się zmienia napełnienie asortymentu z czasem?';
									|tr = 'Ürün gamının içeriği zaman içinde nasıl değişir?'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ByCategories");
	OptionDetails.LongDesc = NStr("vi = 'Làm thế nào để thay đổi điền danh điểm theo thời gian?';
									|ru = 'Как изменяется наполнение ассортимента со временем?';
									|en = 'Verify how the product range completeness change over time.'; fa = 'Verify how the product range completeness change over time.';
									|it = 'Как изменяется наполнение ассортимента со временем?';
									|pl = 'Jak się zmienia napełnienie asortymentu z czasem?';
									|tr = 'Ürün gamının içeriği zaman içinde nasıl değişir?'");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ByProductContext");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
