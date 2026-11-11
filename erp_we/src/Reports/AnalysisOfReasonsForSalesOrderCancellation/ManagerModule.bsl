//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings
//   DisplayReportOptions - Boolean -
//
Procedure CustomizeReportOptions(Settings, DisplayReportOptions) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.AnalysisOfReasonsForSalesOrderCancellation);
	ReportsOptions.SetOutputModeInReportPanels(Settings, DescriptionOfReport, DisplayReportOptions);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Vì những nguyên nhân thường gặp nào mà đơn hàng chỉ được thực hiện một phần hoặc không được thực hiện đầy đủ?';
									|ru = 'По каким причинам чаще всего заказы выполняются частично или не выполняются полностью?';
									|en = 'Check the reasons why the orders are fulfilled partially or incompletely.'; fa = 'Check the reasons why the orders are fulfilled partially or incompletely.';
									|it = 'По каким причинам чаще всего заказы выполняются частично или не выполняются полностью?';
									|pl = 'Z jakich przyczyn najczęściej zamówienia są wykonywane częściowo lub nie wykonywane w całości?';
									|tr = 'Siparişlerin kısmen veya tamamen karşılanmamasının en yaygın nedenleri nelerdir?'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ReasonsForCancelingCustomerOrdersWithoutPriceGroups");
	OptionDetails.LongDesc = NStr("vi = 'Do những nguyên nhân nào mà các đơn hàng được thực hiện một phần hoặc không thực hiện toàn bộ?
		|Người quản lý nào có nhiều đơn hàng đã thực hiện không đầy đủ?';
		|ru = 'По каким причинам чаще всего заказы выполняются частично или не выполняются полностью?
		|У каких менеджеров более всего выполненных не полностью заказов?';
		|en = 'Check the reasons why the orders are fulfilled partially or incompletely.
		|Verify which sales persons have the highest number of partially fulfilled orders.'; fa = 'Check the reasons why the orders are fulfilled partially or incompletely.
		|Verify which sales persons have the highest number of partially fulfilled orders.';
		|it = 'По каким причинам чаще всего заказы выполняются частично или не выполняются полностью?
		|У каких менеджеров более всего выполненных не полностью заказов?';
		|pl = 'Z jakich przyczyn zamówienia najczęściej są wykonywane częściowo lub nie wykonane w całości? 
		|U jakich menedżerów jest najwięcej zamówień nie wykonanych zamówień?';
		|tr = 'Siparişlerin kısmen veya tamamen karşılanmamasının en yaygın nedenleri nelerdir?
		|En çok eksik siparişler hangi yöneticilerde mevcut?'");
	OptionDetails.FunctionalOptions.Add("NotUsePriceGroups");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ReasonsForCancelingOrdersFromCustomersWithPriceGroups");
	OptionDetails.LongDesc = NStr("vi = 'Do những nguyên nhân nào mà các đơn hàng được thực hiện một phần hoặc không thực hiện toàn bộ?
		|Người quản lý nào có nhiều đơn hàng đã thực hiện không đầy đủ?';
		|ru = 'По каким причинам чаще всего заказы выполняются частично или не выполняются полностью?
		|У каких менеджеров более всего выполненных не полностью заказов?';
		|en = 'Check the reasons why the orders are fulfilled partially or incompletely.
		|Verify which sales persons have the highest number of partially fulfilled orders.'; fa = 'Check the reasons why the orders are fulfilled partially or incompletely.
		|Verify which sales persons have the highest number of partially fulfilled orders.';
		|it = 'По каким причинам чаще всего заказы выполняются частично или не выполняются полностью?
		|У каких менеджеров более всего выполненных не полностью заказов?';
		|pl = 'Z jakich przyczyn zamówienia najczęściej są wykonywane częściowo lub nie wykonane w całości? 
		|U jakich menedżerów jest najwięcej zamówień nie wykonanych zamówień?';
		|tr = 'Siparişlerin kısmen veya tamamen karşılanmamasının en yaygın nedenleri nelerdir?
		|En çok eksik siparişler hangi yöneticilerde mevcut?'");
	OptionDetails.FunctionalOptions.Add("UsePriceGroups");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
