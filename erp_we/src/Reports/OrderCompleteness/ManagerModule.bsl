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
Function AddStaffingCommandByOrder(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.OrderCompleteness) 
			And GetFunctionalOption("DynamicStructureOfProductionOrders") Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.OrderCompleteness.FullName();
		ReportCommand.Presentation = NStr("vi = 'Hoàn thiện đơn hàng';
											|ru = 'Укомплектованность заказа';
											|en = 'Order completeness'; fa = 'کامل‌بودن سفارش';
											|it = 'Grado di completamento dell''ordine';
											|pl = 'Skompletowanie zamówienia';
											|tr = 'Emir toplama'");
		
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.VariantKey = "ByOrder";
		
		Return ReportCommand;
		
	EndIf;

	Return Undefined;

EndFunction

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
Function AddStaffingTeamByProduct(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.OrderCompleteness) 
			And GetFunctionalOption("DynamicStructureOfProductionOrders") Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.OrderCompleteness.FullName();
		ReportCommand.Presentation = NStr("vi = 'Hoàn thiện đơn hàng sản xuất';
											|ru = 'Укомплектованность заказов на производство';
											|en = 'Production order completeness'; fa = 'کامل‌بودن سفارش تولید';
											|it = 'Grado di completamento degli ordini di produzione';
											|pl = 'Skompletowanie zleceń produkcyjnych';
											|tr = 'Üretim emri toplama'");
		
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.VariantKey = "RemainingGoodsByShelfLives";
		
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.OrderCompleteness);
	DescriptionOfReport.DefineFormSettings = True;
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ForAllOrders");
	OptionDetails.LongDesc = NStr("vi = 'Đánh giá mức độ hoàn thiện đơn hàng thông qua nguyên vật liệu và bán thành phẩm.
		|Đơn hàng nào có vấn đề về đảm bảo?
		|Phần nguyên vật liệu và bán thành phẩm nào đang có sẵn, sẽ có hoặc không có đúng hạn?';
		|ru = 'Оценка укомплектованности заказов материалами и полуфабрикатами.
		|По каким заказам есть проблемы с обеспечением?
		|Какая часть материалов и полуфабрикатов есть в наличии, будет или не будет в срок?';
		|en = 'Estimate whether orders are equipped with materials and semi-finished products.
		|Check what orders have supply issues.
		|Verify if all materials and semi-finished products are available. If not, check if they will be supplied on time.'; fa = 'Estimate whether orders are equipped with materials and semi-finished products.
		|Check what orders have supply issues.
		|Verify if all materials and semi-finished products are available. If not, check if they will be supplied on time.';
		|it = 'Оценка укомплектованности заказов материалами и полуфабрикатами.
		|По каким заказам есть проблемы с обеспечением?
		|Какая часть материалов и полуфабрикатов есть в наличии, будет или не будет в срок?';
		|pl = 'Ocena skompletowania zamówień materiałami i półproduktami.
		|Dla jakich zamówień są problemy z zaopatrzeniem?
		|Jaka część materiałów i półproduktów jest na stanie, będzie w terminie czy nie?';
		|tr = 'Malzeme ve yarı mamul siparişlerinin tamlığının değerlendirilmesi.
		|Hangi siparişlerde sipariş karşılama sorunu mevcut?
		|Malzemelerin ve yarı mamullerin hangi bölümü mevcut, zamanında gelecek mi, gelmeyecek mi?'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ByOrder");
	OptionDetails.Description = NStr("vi = 'Hoàn thiện đơn hàng sản xuất';
									|ru = 'Укомплектованность заказа на производство';
									|en = 'Production order completeness'; fa = 'کامل‌بودن سفارش تولید';
									|it = 'Укомплектованность заказа на производство';
									|pl = 'Skompletowanie zlecenia produkcyjnego';
									|tr = 'Üretim emrinin tamamlanması'");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích mức độ hoàn thiện đơn hàng thông qua nguyên vật liệu và bán thành phẩm.
		|Những nguyên vật liệu và bán thành phẩm nào có vấn đề về đảm bảo?
		|Nguyên vật liệu và bán thành phẩm nào đang có sẵn, sẽ có hoặc không có đúng hạn?';
		|ru = 'Анализ укомплектованности заказа материалами и полуфабрикатами.
		|По каким материалам и полуфабрикатам есть проблемы с обеспечением?
		|Какие материалы и полуфабрикаты есть в наличии, будут или не будут в срок?';
		|en = 'Analyze whether orders are equipped with materials and semi-finished products.
		|Check what materials and semi-finished products have supply issues.
		|Verify what materials and semi-finished product are available. If not, check if they will be supplied on time.'; fa = 'Analyze whether orders are equipped with materials and semi-finished products.
		|Check what materials and semi-finished products have supply issues.
		|Verify what materials and semi-finished product are available. If not, check if they will be supplied on time.';
		|it = 'Анализ укомплектованности заказа материалами и полуфабрикатами.
		|По каким материалам и полуфабрикатам есть проблемы с обеспечением?
		|Какие материалы и полуфабрикаты есть в наличии, будут или не будут в срок?';
		|pl = 'Analiza skompletowania zamówienia materiałami i półproduktami.
		|Dla jakich materiałów i półproduktów są problemy z zaopatrzeniem?
		|Jakie materiały i półprodukty są na stanie, będą w terminie czy nie?';
		|tr = 'Malzeme ve yarı mamullerle siparişin tamlığının analizi.
		|Hangi malzeme ve yarı mamullerde sipariş karşılama sorunu mevcut?
		|Hangi malzeme ve yarı mamuller mevcut, zamanında gelecek mi, gelmeyecek mi?'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "RemainingGoodsByShelfLives");
	OptionDetails.Description = NStr("vi = 'Mức độ hoàn thiện đơn hàng sản xuất theo mặt hàng';
									|ru = 'Укомплектованность заказов на производство по номенклатуре';
									|en = 'Production order completeness by items'; fa = 'کامل‌بودن سفارش تولید بر اساس اقلام';
									|it = 'Укомплектованность заказов на производство по номенклатуре';
									|pl = 'Skompletowanie zleceń produkcyjnych według produktu';
									|tr = 'Öğeye göre üretim emirlerinin tamamlanması'");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích mức độ hoàn thiện đơn hàng theo mặt hàng đã chọn
		|Những đơn hàng nào có vấn đề về đảm bảo?';
		|ru = 'Анализ укомплектованности заказов по выбранной номенклатуре
		|По каким заказам есть проблемы с обеспечением?';
		|en = 'Analyze order completeness by the selected items
		|Check what orders have supply issues.'; fa = 'Analyze order completeness by the selected items
		|Check what orders have supply issues.';
		|it = 'Анализ укомплектованности заказов по выбранной номенклатуре
		|По каким заказам есть проблемы с обеспечением?';
		|pl = 'Analiza skompletowania zamówień według wybranego produktu
		|Dla jakich zamówień są problemy z zaopatrzeniem?';
		|tr = 'Seçilen öğe için siparişlerin tamlığının analizi
		|Hangi siparişlerde sipariş karşılama sorunu mevcut?'");
	
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "BySourcesAndDatesContext");
	
	TMReportOptionsOverridable.DisableReport(DescriptionOfReport);
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf