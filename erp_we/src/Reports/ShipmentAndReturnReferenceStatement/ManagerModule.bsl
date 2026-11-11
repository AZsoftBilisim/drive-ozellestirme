#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
// 	ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
// 	ValueTableRow:
// 		* Manager - String
// 		* Presentation - String
// 		* MultipleChoice - Boolean
// 		* Importance - String
// 		* VariantKey - String
// 		* HasVisibilityConditions - Boolean
//
Function AddReportCommand(ReportsCommands) Export
	
	If AccessRight("View", Metadata.Reports.ShipmentAndReturnReferenceStatement) 
		And GetFunctionalOption("UseSalesOrders") Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.ShipmentAndReturnReferenceStatement.FullName();
		ReportCommand.Presentation = NStr("vi = 'Bảng kê theo lệnh giao hàng';
											|ru = 'Ведомость по распоряжениям на отгрузку';
											|en = 'Shipment reference statement'; fa = 'صورت مرجع ارسال';
											|it = 'Shipment reference statement';
											|pl = 'Shipment reference statement';
											|tr = 'Sevkiyat talimatlarının beyanı'");
		
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.VariantKey = "ShipmentAndReturnReferenceStatement";
		ReportCommand.HasVisibilityConditions = False;
		
		Return ReportCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

#Region InterfaceImplementation

// Sets advanced report settings.
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ShipmentAndReturnReferenceStatement);
	DescriptionOfReport.Enabled = True;
	DescriptionOfReport.DefineFormSettings = True;
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.Enabled = True;
	OptionDetails.LongDesc = NStr("vi = 'Phân tích các chỉ số của lệnh giao hàng trong kỳ.
		|Những mặt hàng nào đã được đặt, đang trên đường vận chuyển, hoặc cần giao hàng?';
		|ru = 'Анализ показателей распоряжений на отгрузку за период.
		|Какие товары были заказаны, находятся в пути, требуют отгрузки?';
		|en = 'Analysis of shipment reference indicators for the period.
		|View goods that have been ordered, are in transit, or are pending shipment.'; fa = 'Analysis of shipment reference indicators for the period.
		|View goods that have been ordered, are in transit, or are pending shipment.';
		|it = 'Analysis of shipment reference indicators for the period.
		|View goods that have been ordered, are in transit, or are pending shipment.';
		|pl = 'Analysis of shipment reference indicators for the period.
		|View goods that have been ordered, are in transit, or are pending shipment.';
		|tr = 'Döneme ait sevkiyat sipariş göstergelerinin analizi.
		|Hangi ürünler sipariş edildi, hangi ürünler transitte veya hangi ürünler sevkiyat gerektiriyor?'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "StatementOfOrdersForShipment");
	OptionDetails.Enabled = True;
	OptionDetails.LongDesc = NStr("vi = 'Phân tích các chỉ số của lệnh giao hàng trong kỳ.
		|Những mặt hàng nào đã được đặt, đang trên đường vận chuyển, hoặc cần giao hàng?';
		|ru = 'Анализ показателей распоряжений на отгрузку за период.
		|Какие товары были заказаны, находятся в пути, требуют отгрузки?';
		|en = 'Analysis of shipment reference indicators for the period.
		|View goods that have been ordered, are in transit, or are pending shipment.'; fa = 'Analysis of shipment reference indicators for the period.
		|View goods that have been ordered, are in transit, or are pending shipment.';
		|it = 'Analysis of shipment reference indicators for the period.
		|View goods that have been ordered, are in transit, or are pending shipment.';
		|pl = 'Analysis of shipment reference indicators for the period.
		|View goods that have been ordered, are in transit, or are pending shipment.';
		|tr = 'Döneme ait sevkiyat sipariş göstergelerinin analizi.
		|Hangi ürünler sipariş edildi, hangi ürünler transitte veya hangi ürünler sevkiyat gerektiriyor?'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "StatementOfReturnOrders");
	OptionDetails.Enabled = True;
	OptionDetails.LongDesc = NStr("vi = 'Phân tích các chỉ tiêu của lệnh trả lại trong kỳ.
		|Những mặt hàng nào đã được yêu cầu trả lại, đang chờ nhập kho, hoặc đã được trả lại?';
		|ru = 'Анализ показателей распоряжений на возврат за период.
		|Какие товары были заявлены к возврату, ожидают приемки, возвращены?';
		|en = 'Analysis of return reference indicators for the period.
		|Which goods are requested for return, pending receipt, or returned?'; fa = 'Analysis of return reference indicators for the period.
		|Which goods are requested for return, pending receipt, or returned?';
		|it = 'Analysis of return reference indicators for the period.
		|Which goods are requested for return, pending receipt, or returned?';
		|pl = 'Analysis of return reference indicators for the period.
		|Which goods are requested for return, pending receipt, or returned?';
		|tr = 'Döneme ait iade talimatları göstergelerinin analizi.
		|Hangi ürünlere iade bildirildi, hangi ürünler kabul bekliyor veya hangi ürünler iade edildi?'");
	OptionDetails.FunctionalOptions = CommonClientServer.ValueInArray(
		Metadata.FunctionalOptions.UseRequestsForReturnOfGoodsFromCustomers.Name);
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "CancelledOrderLines");
	OptionDetails.Enabled = True;
	OptionDetails.LongDesc = NStr("vi = 'Phân tích các dòng bị hủy trong lệnh giao hàng và trả lại trong kỳ.
		|Những mặt hàng nào đã bị hủy, với số lượng và số tiền bao nhiêu?';
		|ru = 'Анализ отмененных строк распоряжений на отгрузку и возврат за период.
		|Какие товары были отменены, в каком количестве и на какую сумму?';
		|en = 'Analysis of cancelled shipment and return reference lines for the period.
		|What goods were canceled, in what quantity, and for what amount?'; fa = 'Analysis of cancelled shipment and return reference lines for the period.
		|What goods were canceled, in what quantity, and for what amount?';
		|it = 'Analysis of cancelled shipment and return reference lines for the period.
		|What goods were canceled, in what quantity, and for what amount?';
		|pl = 'Analysis of cancelled shipment and return reference lines for the period.
		|What goods were canceled, in what quantity, and for what amount?';
		|tr = 'Dönem içinde iptal edilen sevkiyat ve iade talimatlarının analizi.
		|Hangi ürünler, ne miktarda ve ne kadarlık bir tutarda iptal edildi?'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf