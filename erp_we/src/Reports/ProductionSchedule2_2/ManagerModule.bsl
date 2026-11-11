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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ProductionSchedule2_2);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Xem lịch sản xuất.';
									|ru = 'Просмотр графика производства продукции.';
									|en = 'View the production schedule.'; fa = 'View the production schedule.';
									|it = 'Просмотр графика производства продукции.';
									|pl = 'Przegląd harmonogramu wyprodukowania produkcji.';
									|tr = 'İmal edilen ürün üretim programını görüntüleme.'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ScheduleOfProductionByOrders");
	OptionDetails.LongDesc = NStr("vi = 'Ngày nào xuất xưởng/ra mắt sản phẩm?
										|Đơn hàng được thực hiện khi nào?
										|Khối lượng xuất xưởng dự tính trong bộ phận là bao nhiêu?
										|Cần thực hiện những công đoạn nào trong bộ phận trong kỳ?';
										|ru = 'Какие даты выпуска/запуска продукции?
										|Когда будут выполнены заказы?
										|Какой объем выпуска запланирован в подразделении?
										|Какие этапы необходимо выполнить в подразделении за период?';
										|en = 'Check product release/launch dates.
										|Verify when the orders will be fulfilled.
										|Track the planned output volume in the business unit.
										|Analyze which steps must be performed in the business unit over a period.'; fa = 'Check product release/launch dates.
										|Verify when the orders will be fulfilled.
										|Track the planned output volume in the business unit.
										|Analyze which steps must be performed in the business unit over a period.';
										|it = 'Какие даты выпуска/запуска продукции?
										|Когда будут выполнены заказы?
										|Какой объем выпуска запланирован в подразделении?
										|Какие этапы необходимо выполнить в подразделении за период?';
										|pl = 'Jakie daty wypuszczenia/uruchomienia produkcji? 
										|Kiedy będą wykonane zamówienia? 
										|Jaka objętość wypuszczenia jest zaplanowana w dziale? 
										|Jakie etapy należy wykonać w dziale za okres?';
										|tr = 'Ürün üretim/başlatma tarihleri ​​nelerdir?
										|Siparişler ne zaman tamamlanacak?
										|Departmanda planlanan üretim hacmi nedir?
										|Dönem için departmanda hangi aşamaların tamamlanması gerekiyor?'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ProductionScheduleOfManufacturedProductsByDivision");
	OptionDetails.Description = NStr("vi = 'Lịch biểu sản xuất của sản phẩm theo bộ phận';
									|ru = 'График производства продукции по подразделениям';
									|en = 'Schedule of production by business units'; fa = 'Schedule of production by business units';
									|it = 'График производства продукции по подразделениям';
									|pl = 'Schedule of production by business units';
									|tr = 'Departmanlara göre imal edilen ürünler üretim programı'");
	
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

	If AccessRight("View", Metadata.Reports.ProductionSchedule2_2) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.ProductionSchedule2_2.FullName();
		ReportCommand.Presentation = NStr("vi = 'Lịch biểu sản xuất của sản phẩm';
											|ru = 'График производства продукции';
											|en = 'Production schedule'; fa = 'برنامه زمان‌بندی تولید';
											|it = 'График производства продукции';
											|pl = 'Production schedule';
											|tr = 'İmal edilen ürünler programı'");
		
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.VariantKey = "ScheduleOfProductionByOrders";
		
		Return ReportCommand;
		
	EndIf;

	Return Undefined;

EndFunction

#EndRegion

#EndRegion

#EndIf
