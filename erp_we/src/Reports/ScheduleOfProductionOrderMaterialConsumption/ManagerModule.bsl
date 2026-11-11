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

	If AccessRight("View", Metadata.Reports.ScheduleOfProductionOrderMaterialConsumption) 
			And GetFunctionalOption("DynamicStructureOfProductionOrders") Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.ScheduleOfProductionOrderMaterialConsumption.FullName();
		ReportCommand.Presentation = NStr("vi = 'Lịch biểu tiêu thụ nguyên vật liệu';
											|ru = 'График потребления материалов';
											|en = 'Material consumption schedule'; fa = 'Material consumption schedule';
											|it = 'Piano di consumo dei materiali';
											|pl = 'Harmonogram zużycia materiałów';
											|tr = 'Malzeme sarfiyat programı'");
		
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.VariantKey = "Main";
		
		Return ReportCommand;
		
	EndIf;

	Return Undefined;

EndFunction

#EndRegion

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ScheduleOfProductionOrderMaterialConsumption);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.Description = NStr("vi = 'Lịch biểu nhu cầu nguyên vật liệu theo đơn hàng';
									|ru = 'График потребления материалов по заказам';
									|en = 'Order material consumption schedule'; fa = 'Order material consumption schedule';
									|it = 'График потребления материалов по заказам';
									|pl = 'Harmonogram zużycia materiałów według zamówień';
									|tr = 'Siparişler için malzeme tüketim programı'");
	OptionDetails.LongDesc = NStr("vi = 'Đánh giá nhu cầu nguyên vật liệu và bán thành phẩm cần thiết để thực hiện đơn hàng sản xuất.';
									|ru = 'Оценка потребности в материалах и полуфабрикатах необходимых для исполнения заказов на производство.';
									|en = 'Estimate demand for materials and semi-finished products required for production orders.'; fa = 'Estimate demand for materials and semi-finished products required for production orders.';
									|it = 'Оценка потребности в материалах и полуфабрикатах необходимых для исполнения заказов на производство.';
									|pl = 'Ocena zapotrzebowania materiałów i półproduktów, potrzebnych do wykonania zleceń produkcyjnych.';
									|tr = 'Üretim emirlerinin yürütülmesi için gerekli malzeme ve yarı mamul ürünlere olan ihtiyacın değerlendirilmesi.'");
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf