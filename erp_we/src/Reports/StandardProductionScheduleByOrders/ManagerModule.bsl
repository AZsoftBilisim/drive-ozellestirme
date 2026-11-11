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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.StandardProductionScheduleByOrders);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Xem lịch trình sản xuất tiêu chuẩn.';
									|ru = 'Просмотр нормативного графика производства продукции.';
									|en = 'View the standard production schedule.'; fa = 'View the standard production schedule.';
									|it = 'Просмотр нормативного графика производства продукции.';
									|pl = 'View the standard production schedule.';
									|tr = 'Просмотр нормативного графика производства продукции.'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "StandardProductionScheduleByOrders");
	OptionDetails.LongDesc = NStr("vi = 'Ngày mong muốn để bắt đầu sản xuất/xuất xưởng sản phẩm và bán thành phẩm theo đơn hàng là gì?
										|Cần thực hiện những bước nào trong khoảng thời gian này?
										|Khối lượng sản phẩm nào dự kiến sẽ được sản xuất?';
										|ru = 'Какие желаемые даты запуска/выпуска продукции и полуфабрикатов по заказам?
										|Какие этапы необходимо выполнить за период?
										|Какой объем номенклатуры запланирован к производству?';
										|en = 'What are the desired launch/release dates of manufactured products and semi-finished products under orders?
										|What stages need to be completed during the period?
										|What volume of products is planned for production?'; fa = 'What are the desired launch/release dates of manufactured products and semi-finished products under orders?
										|What stages need to be completed during the period?
										|What volume of products is planned for production?';
										|it = 'Какие желаемые даты запуска/выпуска продукции и полуфабрикатов по заказам?
										|Какие этапы необходимо выполнить за период?
										|Какой объем номенклатуры запланирован к производству?';
										|pl = 'What are the desired launch/release dates of manufactured products and semi-finished products under orders?
										|What stages need to be completed during the period?
										|What volume of products is planned for production?';
										|tr = 'Какие желаемые даты запуска/выпуска продукции и полуфабрикатов по заказам?
										|Какие этапы необходимо выполнить за период?
										|Какой объем номенклатуры запланирован к производству?'");
	
EndProcedure

#EndRegion

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

	If AccessRight("View", Metadata.Reports.StandardProductionScheduleByOrders) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.StandardProductionScheduleByOrders.FullName();
		ReportCommand.Presentation = NStr("vi = 'Lịch biểu sản xuất tiêu chuẩn theo đơn hàng';
											|ru = 'Нормативный график производства по заказам';
											|en = 'Standard production schedule by orders'; fa = 'زمان‌بندی استاندارد تولید بر اساس سفارش‌ها';
											|it = 'Standard production schedule by orders';
											|pl = 'Standard production schedule by orders';
											|tr = 'Siparişlere göre standart üretim programı'");
		
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.VariantKey = "StandardProductionScheduleByOrders";
		
		Return ReportCommand;
		
	EndIf;

	Return Undefined;

EndFunction

#EndRegion

#EndRegion

#EndIf
