
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

	If AccessRight("View", Metadata.Reports.MonitorProductionOrder)
		And GetFunctionalOption("StandardOrderStructureScheduleIsUsed") Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.MonitorProductionOrder.FullName();
		ReportCommand.Presentation = NStr("vi = 'Màn hình kiểm soát đơn hàng';
											|ru = 'Мониторинг заказа';
											|en = 'Monitor order'; fa = 'پایش سفارش';
											|it = 'Мониторинг заказа';
											|pl = 'Monitorowanie zamówienia';
											|tr = 'Sipariş takibi'");
		
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.VariantKey = "Main";
		
		Return ReportCommand;
		
	EndIf;

	Return Undefined;

EndFunction

#EndRegion

#EndRegion

#Region Internal

#EndRegion

#EndIf