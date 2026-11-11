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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ComparisonOfPartnersSegments);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Có bao nhiêu khách hàng trong phân khúc?
		|Khối lượng hàng bán theo phân khúc là bao nhiêu?
		|Có bao nhiêu vụ việc và trạng thái của vụ việc.';
		|ru = 'Сколько клиентов в сегментах?
		|Какой объем продаж по сегментам?
		|Какое количество сделок и их состояние.';
		|en = 'View how many customers there are in segments.
		|Track the sales volume by segments.
		|Check how many sales opportunities are registered, and what their states are.'; fa = 'View how many customers there are in segments.
		|Track the sales volume by segments.
		|Check how many sales opportunities are registered, and what their states are.';
		|it = 'Сколько клиентов в сегментах?
		|Какой объем продаж по сегментам?
		|Какое количество сделок и их состояние.';
		|pl = 'Ile klientów jest w segmentach?
		|Jaka jest objętość sprzedaż według segmentów? 
		|Jaka ilość transakcji i ich status.';
		|tr = 'Segmentlerde kaç müşteri var?
		|Segmentlere göre satış hacmi nedir?
		|Kaç satış fırsatı var ve bunların durumu nedir.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "Main");
	OptionDetails.LongDesc = NStr("vi = 'Có bao nhiêu khách hàng trong phân khúc?
		|Khối lượng hàng bán theo phân khúc là bao nhiêu?
		|Có bao nhiêu vụ việc và trạng thái của vụ việc.';
		|ru = 'Сколько клиентов в сегментах?
		|Какой объем продаж по сегментам?
		|Какое количество сделок и их состояние.';
		|en = 'View how many customers there are in segments.
		|Track the sales volume by segments.
		|Check how many sales opportunities are registered, and what their states are.'; fa = 'View how many customers there are in segments.
		|Track the sales volume by segments.
		|Check how many sales opportunities are registered, and what their states are.';
		|it = 'Сколько клиентов в сегментах?
		|Какой объем продаж по сегментам?
		|Какое количество сделок и их состояние.';
		|pl = 'Ile klientów jest w segmentach?
		|Jaka jest objętość sprzedaż według segmentów? 
		|Jaka ilość transakcji i ich status.';
		|tr = 'Segmentlerde kaç müşteri var?
		|Segmentlere göre satış hacmi nedir?
		|Kaç satış fırsatı var ve bunların durumu nedir.'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
