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

	If AccessRight("View", Metadata.Reports.ScheduleOfHumanResourceOccupancyByProductionOrders) 
			And GetFunctionalOption("DynamicStructureOfProductionOrders") Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.ScheduleOfHumanResourceOccupancyByProductionOrders.FullName();
		ReportCommand.Presentation = NStr("vi = 'Lịch biểu bận việc của các nguồn lực lao động theo đơn hàng';
											|ru = 'График занятости трудовых ресурсов по заказам';
											|en = 'Schedule of human resource occupancy by orders'; fa = 'Schedule of human resource occupancy by orders';
											|it = 'Schedule of human resource occupancy by orders';
											|pl = 'Schedule of human resource occupancy by orders';
											|tr = 'Siparişlere göre işgücü kaynakları doluluk grafiği'");
		
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ScheduleOfHumanResourceOccupancyByProductionOrders);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.Description = NStr("vi = 'Lịch biểu bận việc của các nguồn lực lao động theo dạng công việc';
									|ru = 'График занятости трудовых ресурсов по видам работ';
									|en = 'Schedule of human resource occupancy by activity kinds'; fa = 'برنامه اشغال منابع انسانی بر اساس انواع فعالیت';
									|it = 'График занятости трудовых ресурсов по видам работ';
									|pl = 'Harmonogram zatrudnienia zasobów pracy według rodzajów prac';
									|tr = 'İş türüne göre işgücü kaynaklarının meşguliyet programı'");
	OptionDetails.LongDesc = NStr("vi = 'Đánh giá nhu cầu về các nguồn lực lao động cần thiết để thực hiện đơn hàng sản xuất.';
									|ru = 'Оценка потребности в трудовых ресурсах необходимых для исполнения заказов на производство.';
									|en = 'Estimate demand for human resources required for production orders.'; fa = 'Estimate demand for human resources required for production orders.';
									|it = 'Оценка потребности в трудовых ресурсах необходимых для исполнения заказов на производство.';
									|pl = 'Ocena zapotrzebowania zasobów pracy, potrzebnych do wykonania zleceń produkcyjnych.';
									|tr = 'Üretim emirlerinin yürütülmesi için gerekli işçilik kaynaklarına olan ihtiyacın değerlendirilmesi.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ByBusinessUnits");
	OptionDetails.Description = NStr("vi = 'Lịch làm việc của các nguồn lực lao động theo bộ phận';
									|ru = 'График занятости трудовых ресурсов по подразделениям';
									|en = 'Schedule of human resource occupancy by business units'; fa = 'برنامه اشغال منابع انسانی بر اساس واحدهای تجاری';
									|it = 'График занятости трудовых ресурсов по подразделениям';
									|pl = 'Harmonogram zatrudnienia zasobów pracy według działów';
									|tr = 'Departmanlara göre işgücü kaynaklarının meşguliyet programı'");
	TMReportOptionsOverridable.DisableReport(DescriptionOfReport);
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf