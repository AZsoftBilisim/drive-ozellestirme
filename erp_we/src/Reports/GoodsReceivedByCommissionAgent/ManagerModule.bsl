#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// Returns:
//   ValueTableRow - new report command.
Function AddReportCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.GoodsReceivedByCommissionAgent) 
			And GetFunctionalOption("UsePurchaseCommission") Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.GoodsReceivedByCommissionAgent.FullName();
		ReportCommand.Presentation = NStr("vi = 'Hàng hóa đã tiếp nhận để bán ký gửi';
											|ru = 'Товары, принятые на комиссию';
											|en = 'Goods received by consignee'; fa = 'کالای دریافت‌شده توسط امانت‌دار';
											|it = 'Beni accettati per la commissione';
											|pl = 'Wiersze pozycji, przyjęte do komisu';
											|tr = 'Konsinye olarak kabul edilen mallar'");
		
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.VariantKey = "GoodsReceivedByCommissionAgent";		
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.GoodsReceivedByCommissionAgent);
	DescriptionOfReport.DefineFormSettings = True;
	ReportsOptions.SetOutputModeInReportPanels(Settings, DescriptionOfReport, False);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Có bao nhiêu hàng hóa đã được tiếp nhận từ người đặt ký gửi trong kỳ?';
									|ru = 'Сколько товаров было принято от комитентов за период?';
									|en = 'Verify how many goods were received from consignors for the period.'; fa = 'Verify how many goods were received from consignors for the period.';
									|it = 'Сколько товаров было принято от комитентов за период?';
									|pl = 'Ile towarów zostało przyjęto od komitentów za okres?';
									|tr = 'Dönem içinde göndericilerden ne kadar ürün kabul edildi?'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "GoodsReceivedByCommissionAgent");
	OptionDetails.LongDesc = NStr("vi = 'Có bao nhiêu hàng hóa đã được tiếp nhận từ người đặt ký gửi trong kỳ?
		|Chúng ta đã bán, ghi giảm, trả lại hoặc đặt bao nhiêu hàng trong kỳ này?';
		|ru = 'Сколько товаров было принято от комитентов за период?
		|Сколько мы продали, списали, вернули или заказали за тот же период?';
		|en = 'Check how many goods were received from consignors for the period.
		|Verify how many of them we sold, consumed, returned, or ordered for the same period.'; fa = 'Check how many goods were received from consignors for the period.
		|Verify how many of them we sold, consumed, returned, or ordered for the same period.';
		|it = 'Сколько товаров было принято от комитентов за период?
		|Сколько мы продали, списали, вернули или заказали за тот же период?';
		|pl = 'Ile towarów zostało przyjęto od komitentów za okres? 
		|Ile sprzedaliśmy, rozchodowaliśmy, zwrócili lub zamówili za ten samy okres?';
		|tr = 'Dönem içinde göndericilerden ne kadar ürün kabul edildi?
		|Aynı dönemde ne kadar sattık, ne kadarını kayıttan düştük, ne kadarını iade ettik veya ne kadar sipariş ettik?'");
	OptionDetails.FunctionalOptions.Add("UseNonBasePurchaseCommission");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ProductsAcceptedForCommissionBasic");
	OptionDetails.FunctionalOptions.Add("UseBasePurchaseCommission");
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf