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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.SalesPipeline);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Hiệu quả của từng giai đoạn bán hàng như thế nào?';
									|ru = 'Какова эффективность каждой стадии продажи?';
									|en = 'Check the efficiency of each sale stage.'; fa = 'Check the efficiency of each sale stage.';
									|it = 'Какова эффективность каждой стадии продажи?';
									|pl = 'Jaka jest efektywność każdego stadium sprzedaży?';
									|tr = 'Satışın her evresinin etkinliği nedir?'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "Main");
	OptionDetails.LongDesc = NStr("vi = 'Hiệu quả của từng giai đoạn bán hàng như thế nào?';
									|ru = 'Какова эффективность каждой стадии продажи?';
									|en = 'Check the efficiency of each sale stage.'; fa = 'Check the efficiency of each sale stage.';
									|it = 'Какова эффективность каждой стадии продажи?';
									|pl = 'Jaka jest efektywność każdego stadium sprzedaży?';
									|tr = 'Satışın her evresinin etkinliği nedir?'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
