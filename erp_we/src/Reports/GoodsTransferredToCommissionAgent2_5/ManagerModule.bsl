#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// Returns:
// 	ValueTableRow
Function AddReportCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.GoodsTransferredToCommissionAgent2_5) 
			And GetFunctionalOption("OnlyConsignmentSales25") Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.GoodsTransferredToCommissionAgent2_5.FullName();
		ReportCommand.Presentation = NStr("vi = 'Hàng hóa đã chuyển giao ký gửi';
											|ru = 'Товары, переданные на комиссию';
											|en = 'Consignment sales stock'; fa = 'موجودی فروش امانی';
											|it = 'Merci trasferiti alla commissione';
											|pl = 'Wiersze pozycji, przekazane do przeceny';
											|tr = 'Konsinyeye transfer edilen ürünler'");
		
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.VariantKey = "GoodsTransferredToCommissionAgent";
		ReportCommand.HasVisibilityConditions = True;
		
		AttachableCommands.AddCommandVisibilityCondition(ReportCommand,
			"BusinessOperation",
			Enums.BusinessTransactions.SalesViaCommissionAgent, 
			DataCompositionComparisonType.NotEqual);
		
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
	
	OptionDescription = NStr("vi = 'Hàng hóa đã chuyển giao ký gửi';
							|ru = 'Товары, переданные на комиссию';
							|en = 'Consignment sales stock'; fa = 'موجودی فروش امانی';
							|it = 'Товары, переданные на комиссию';
							|pl = 'Wiersze pozycji, przekazane do przeceny';
							|tr = 'Konsinyeye transfer edilen ürünler'");
	OptionDescription = ConsignmentSalesServer.AddCommissionPostfix25(OptionDescription);
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.GoodsTransferredToCommissionAgent2_5);
	DescriptionOfReport.DefineFormSettings = True;
	ReportsOptions.SetOutputModeInReportPanels(Settings, DescriptionOfReport, False);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.Description = OptionDescription;
	OptionDetails.LongDesc = NStr("vi = 'Có bao nhiêu hàng hóa đã chuyển giao cho người nhận ký gửi trong kỳ?
		|Người nhận ký gửi đã bán, ghi giảm, trả lại hoặc đặt bao nhiêu hàng trong kỳ này?';
		|ru = 'Сколько товаров было передано комиссионеру за период?
		|Сколько он продал, списал, вернул или заказал за тот же период?';
		|en = 'Check how many goods were transferred to the consignee for the period.
		|Verify how many of them they sold, wrote off, returned or ordered for the same period.'; fa = 'Check how many goods were transferred to the consignee for the period.
		|Verify how many of them they sold, wrote off, returned or ordered for the same period.';
		|it = 'Сколько товаров было передано комиссионеру за период?
		|Сколько он продал, списал, вернул или заказал за тот же период?';
		|pl = 'Ile towarów zostało przekazano do komisanta za okres? 
		|Ile on sprzedał, rozchodował, zwrócił lub zamówił za ten samy okres?';
		|tr = 'Dönem içinde konsinyeye ne kadar ürün transfer edildi?
		|Aynı dönemde ne kadar ürün sattı, ne kadarını kayıttan düştü, ne kadarını iade etti veya ne kadarını sipariş verdi?'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "GoodsTransferredToCommissionAgent");
	OptionDetails.FunctionalOptions.Add("NotBaseVersion");
	OptionDetails.Description = OptionDescription;
	OptionDetails.LongDesc = NStr("vi = 'Có bao nhiêu hàng hóa đã chuyển giao cho người nhận ký gửi trong kỳ?
		|Người nhận ký gửi đã bán, ghi giảm, trả lại hoặc đặt bao nhiêu hàng trong kỳ này?';
		|ru = 'Сколько товаров было передано комиссионеру за период?
		|Сколько он продал, списал, вернул или заказал за тот же период?';
		|en = 'Check how many goods were transferred to the consignee for the period.
		|Verify how many of them they sold, wrote off, returned or ordered for the same period.'; fa = 'Check how many goods were transferred to the consignee for the period.
		|Verify how many of them they sold, wrote off, returned or ordered for the same period.';
		|it = 'Сколько товаров было передано комиссионеру за период?
		|Сколько он продал, списал, вернул или заказал за тот же период?';
		|pl = 'Ile towarów zostało przekazano do komisanta za okres? 
		|Ile on sprzedał, rozchodował, zwrócił lub zamówił za ten samy okres?';
		|tr = 'Dönem içinde konsinyeye ne kadar ürün transfer edildi?
		|Aynı dönemde ne kadar ürün sattı, ne kadarını kayıttan düştü, ne kadarını iade etti veya ne kadarını sipariş verdi?'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "GoodsTransferredToCommissionAreBasic");
	OptionDetails.FunctionalOptions.Add("BaseVersion");
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf