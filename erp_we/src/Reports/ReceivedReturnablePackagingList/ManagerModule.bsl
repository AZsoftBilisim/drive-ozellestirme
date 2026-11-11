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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ReceivedReturnablePackagingList);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích tổng hợp phát sinh việc tiếp nhận bao bì từ nhà cung cấp trong kỳ nhất định.';
									|ru = 'Сводный анализ оборотов принятой от поставщиков тары за определенный период.';
									|en = 'Summary analysis of turnovers of the packaging received from vendors for the specified period.'; fa = 'Summary analysis of turnovers of the packaging received from vendors for the specified period.';
									|it = 'Сводный анализ оборотов принятой от поставщиков тары за определенный период.';
									|pl = 'Skonsolidowana analiza obrotów przyjętej od dostawców tary   za określony okres.';
									|tr = 'Belirli bir süre için tedarikçilerden kabul edilen ambalaj cirolarının özet analizi.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ReceivedReturnablePackagingList");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích tổng hợp phát sinh bao bì đã nhận từ nhà cung cấp trong kỳ nhất định.
		|Giá trị và số lượng bao bì là bao nhiêu?';
		|ru = 'Сводный анализ оборотов принятой от поставщиков тары за определенный период.
		|Какова ее стоимость и количество?';
		|en = 'Summary analysis of turnovers of the packaging received from vendors for the specified period.
		|Check its cost and quantity.'; fa = 'Summary analysis of turnovers of the packaging received from vendors for the specified period.
		|Check its cost and quantity.';
		|it = 'Сводный анализ оборотов принятой от поставщиков тары за определенный период.
		|Какова ее стоимость и количество?';
		|pl = 'Skonsolidowana analiza obrotów przyjętej od dostawców tary   za określony okres. 
		| Jaka jest jej wartość i ilość?';
		|tr = 'Belirli bir süre için tedarikçilerden kabul edilen ambalaj cirolarının özet analizi.
		|Maliyeti ve miktarı nedir?'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
