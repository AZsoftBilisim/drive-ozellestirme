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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.PriceListForOrderPlacement);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Mẫu in bảng giá để giao cho đại diện thương mại.';
									|ru = 'Печатная форма прайс-листа для выдачи торговому представителю.';
									|en = 'Price list print form to issue to the sales representative.'; fa = 'Price list print form to issue to the sales representative.';
									|it = 'Печатная форма прайс-листа для выдачи торговому представителю.';
									|pl = 'Formularz wydruku cennika dla wydania przedstawicielu handlowemu.';
									|tr = 'Satış temsilcisine verilmesi için fiyat listesinin yazdırma formu.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "Main");
	OptionDetails.LongDesc = NStr("vi = 'Mẫu in bảng giá để giao cho đại diện thương mại.';
									|ru = 'Печатная форма прайс-листа для выдачи торговому представителю.';
									|en = 'Price list print form to issue to the sales representative.'; fa = 'Price list print form to issue to the sales representative.';
									|it = 'Печатная форма прайс-листа для выдачи торговому представителю.';
									|pl = 'Formularz wydruku cennika dla wydania przedstawicielu handlowemu.';
									|tr = 'Satış temsilcisine verilmesi için fiyat listesinin yazdırma formu.'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
