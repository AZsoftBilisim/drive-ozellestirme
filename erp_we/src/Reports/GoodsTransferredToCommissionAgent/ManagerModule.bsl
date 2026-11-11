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

	If AccessRight("View", Metadata.Reports.GoodsTransferredToCommissionAgent) 
			And GetFunctionalOption("UseSalesCommission") Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.GoodsTransferredToCommissionAgent.FullName();
		ReportCommand.Presentation = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Hàng hóa đã chuyển giao đi ký gửi (%1)';
				|ru = 'Товары, переданные на комиссию (%1)';
				|en = 'Consignment sales stock (%1)'; fa = 'Consignment sales stock (%1)';
				|it = 'Товары, переданные на комиссию (%1)';
				|pl = 'Consignment sales stock (%1)';
				|tr = 'Konsinyeye transfer edilen ürünler (%1)'"),
			ConsignmentSalesServer.PostfixCommissionSchemes20());
		
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
	
	PostfixCommissionSchemes = ConsignmentSalesServer.PostfixCommissionSchemes();
	OptionDescription = StringFunctionsClientServer.SubstituteParametersToString(
	NStr("vi = 'Hàng hóa đã chuyển giao đi ký gửi (%1)';
		|ru = 'Товары, переданные на комиссию (%1)';
		|en = 'Consignment sales stock (%1)'; fa = 'Consignment sales stock (%1)';
		|it = 'Товары, переданные на комиссию (%1)';
		|pl = 'Consignment sales stock (%1)';
		|tr = 'Konsinye satış ürünleri (%1)'"),
	PostfixCommissionSchemes);
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.GoodsTransferredToCommissionAgent);
	DescriptionOfReport.DefineFormSettings = True;
	ReportsOptions.SetOutputModeInReportPanels(Settings, DescriptionOfReport, False);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.Description = OptionDescription;
	OptionDetails.LongDesc = NStr("vi = 'Có bao nhiêu hàng hóa đã chuyển giao cho người nhận ký gửi trong kỳ?';
									|ru = 'Сколько товаров было передано комиссионеру за период?';
									|en = 'Check how many goods were transferred to the consignee for the period.'; fa = 'Check how many goods were transferred to the consignee for the period.';
									|it = 'Сколько товаров было передано комиссионеру за период?';
									|pl = 'Ile towarów zostało przekazano do komisanta za okres?';
									|tr = 'Dönem içinde konsinyeye ne kadar ürün transfer edildi?'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "GoodsTransferredToCommissionAgent");
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
	OptionDetails.FunctionalOptions.Add("UseNonBaseSalesCommission");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "GoodsTransferredToCommissionAreBasic");
	OptionDetails.FunctionalOptions.Add("UseBaseSalesCommission");
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf