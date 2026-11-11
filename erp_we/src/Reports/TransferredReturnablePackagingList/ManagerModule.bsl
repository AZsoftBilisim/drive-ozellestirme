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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.TransferredReturnablePackagingList);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích tổng hợp phát sinh việc chuyển giao bao bì luân chuyển cho khách hàng trong kỳ nhất định.';
									|ru = 'Сводный анализ оборотов переданной клиентам возвратной тары за определенный период.';
									|en = 'Summary analysis of turnovers of returnable packaging transferred to customers for the specified period.'; fa = 'Summary analysis of turnovers of returnable packaging transferred to customers for the specified period.';
									|it = 'Сводный анализ оборотов переданной клиентам возвратной тары за определенный период.';
									|pl = 'Skonsolidowana analiza obrotów przekazanej klientom tary zwrotnej za określony okres.';
									|tr = 'Belirli bir süre için müşterilere teslim edilen iade edilebilir ambalaj cirosunun özet analizi.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "TransferredReturnablePackagingList");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích tổng hợp phát sinh bao bì luân chuyển đã chuyển giao cho khách hàng trong kỳ nhất định.
		|Giá trị và số lượng bao bì là bao nhiêu?';
		|ru = 'Сводный анализ оборотов переданной клиентам возвратной тары за определенный период.
		|Какова ее стоимость и количество?';
		|en = 'Summary analysis of turnovers of returnable packaging transferred to customers for the specified period.
		|Verify its cost and quantity.'; fa = 'Summary analysis of turnovers of returnable packaging transferred to customers for the specified period.
		|Verify its cost and quantity.';
		|it = 'Сводный анализ оборотов переданной клиентам возвратной тары за определенный период.
		|Какова ее стоимость и количество?';
		|pl = 'Skonsolidowana analiza obrotów przekazanej klientom tary zwrotnej za określony okres. 
		| Jaka jest jej wartość i ilość?';
		|tr = 'Belirli bir süre için müşterilere teslim edilen iade edilebilir ambalaj cirosunun özet analizi.
		|Maliyeti ve miktarı nedir?'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
