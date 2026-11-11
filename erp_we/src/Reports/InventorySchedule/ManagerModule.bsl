//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//   DisplayReportOptions - Boolean
//
Procedure CustomizeReportOptions(Settings, DisplayReportOptions) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.InventorySchedule);
	ReportsOptions.SetOutputModeInReportPanels(Settings, DescriptionOfReport, DisplayReportOptions);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Số dư hiện tại của hàng hóa trong kho là bao nhiêu?
		|Khi nào dự tính giao hàng và tiếp nhận hàng hóa?';
		|ru = 'Каковы текущие остатки товаров на складах? 
		|Когда планируются отгрузки и поступления товаров?';
		|en = 'Check the current stock balance in warehouses.
		|Verify when shipment and delivery are planned.'; fa = 'Check the current stock balance in warehouses.
		|Verify when shipment and delivery are planned.';
		|it = 'Каковы текущие остатки товаров на складах? 
		|Когда планируются отгрузки и поступления товаров?';
		|pl = 'Jaki jest bieżący stan magazynowy? 
		|Kiedy są planowane wysyłki i wpływ towarów?';
		|tr = 'Ambarlardaki mevcut ürün bakiyeleri nelerdir? 
		|Sevkiyatlar ve ürün girişleri ne zaman planlanır?'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "UseAssignmentsWithoutOrder");
	OptionDetails.FunctionalOptions.Add("UseAssignmentsWithoutOrder");
	OptionDetails.LongDesc = NStr("vi = 'Số dư hiện tại của hàng hóa trong kho là bao nhiêu?
		|Khi nào dự tính giao hàng và tiếp nhận hàng hóa?';
		|ru = 'Каковы текущие остатки товаров на складах? 
		|Когда планируются отгрузки и поступления товаров?';
		|en = 'Check the current stock balance in warehouses.
		|Verify when shipment and delivery are planned.'; fa = 'Check the current stock balance in warehouses.
		|Verify when shipment and delivery are planned.';
		|it = 'Каковы текущие остатки товаров на складах? 
		|Когда планируются отгрузки и поступления товаров?';
		|pl = 'Jaki jest bieżący stan magazynowy? 
		|Kiedy są planowane wysyłki i wpływ towarów?';
		|tr = 'Ambarlardaki mevcut ürün bakiyeleri nelerdir? 
		|Sevkiyatlar ve ürün girişleri ne zaman planlanır?'");
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.InventorySchedule);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "NotUseAssignmentsWithoutOrder");
	OptionDetails.FunctionalOptions.Add("NotUseAssignmentsWithoutOrder");
	OptionDetails.LongDesc = NStr("vi = 'Số dư hiện tại của hàng hóa trong kho là bao nhiêu?
		|Khi nào dự tính giao hàng và tiếp nhận hàng hóa?';
		|ru = 'Каковы текущие остатки товаров на складах? 
		|Когда планируются отгрузки и поступления товаров?';
		|en = 'Check the current stock balance in warehouses.
		|Verify when shipment and delivery are planned.'; fa = 'Check the current stock balance in warehouses.
		|Verify when shipment and delivery are planned.';
		|it = 'Каковы текущие остатки товаров на складах? 
		|Когда планируются отгрузки и поступления товаров?';
		|pl = 'Jaki jest bieżący stan magazynowy? 
		|Kiedy są planowane wysyłki i wpływ towarów?';
		|tr = 'Ambarlardaki mevcut ürün bakiyeleri nelerdir? 
		|Sevkiyatlar ve ürün girişleri ne zaman planlanır?'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
