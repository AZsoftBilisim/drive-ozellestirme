#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// Returns:
//   ValueTableRow - From:
//    *Manager - String -
//    *Presentation - String -
//    *MultipleChoice - Boolean - 
//    *Importance - String -
//    *VariantKey - String -
Function AddReportCommand(ReportsCommands) Export
	
	If Not GetFunctionalOption("DynamicStructureOfProductionOrders") Then
		Return Undefined;
	EndIf;
	
	ReportCommand = ReportsCommands.Add();
	
	ReportCommand.Manager = Metadata.Reports.ControlOfProductionByOrder.FullName();
	ReportCommand.Presentation = NStr("vi = 'Kiểm soát sản xuất theo đơn hàng';
										|ru = 'Контроль производства по заказу';
										|en = 'Control of production by order'; fa = 'کنترل تولید بر اساس سفارش';
										|it = 'Control of production by order';
										|pl = 'Control of production by order';
										|tr = 'Siparişe göre üretim kontrolü'");
	
	ReportCommand.MultipleChoice = False;
	ReportCommand.Importance = "Ordinary";
	ReportCommand.VariantKey = "ProductionControl";
	
	Return ReportCommand;
	
EndFunction

#EndRegion

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ControlOfProductionByOrder);
	DescriptionOfReport.DefineFormSettings = True;
	TMReportOptionsOverridable.DisableReport(DescriptionOfReport);
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf