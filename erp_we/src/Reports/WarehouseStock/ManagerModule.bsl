#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// Returns:
//   ValueTableRow - new report command.
Function AddCommandToRecalculateProducts(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.WarehouseStock) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.WarehouseStock.FullName();
		ReportCommand.Presentation = NStr("vi = 'Hàng hóa trong quy trình giao hàng';
											|ru = 'Товары в процессе отгрузки';
											|en = 'Goods being shipped'; fa = 'کالای در حال ارسال';
											|it = 'Merci nel processo della spedizione';
											|pl = 'Wiersze pozycji w trakcie wysyłki';
											|tr = 'Ürünler sevkiyat sürecinde'");
		
		ReportCommand.MultipleChoice = False;
		
		ReportCommand.AdditionalParameters.Insert("CommandName", "GoodsBeingShipped");
		
		ReportCommand.Importance = "Ordinary";
		ReportCommand.FunctionalOptions = "UseWarehouseManagemantSystemForGoodsIssue,UseGoodsTransferStatuses,UseStatusesOfGoodsServicesSales,UseGoodsAssemblyStatuses";
		ReportCommand.VariantKey = "ShippedGoodsByCurrencyConversion";
		
		Return ReportCommand;
		
	EndIf;

	Return Undefined;

EndFunction

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// Returns:
//   ValueTableRow - new report command.
Function AddProductMovementCommand(ReportsCommands) Export
	
	If AccessRight("View", Metadata.Reports.WarehouseStock) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.WarehouseStock.FullName();
		ReportCommand.Presentation = NStr("vi = 'Biến động hàng hóa đến kho';
											|ru = 'Движения товара на складах';
											|en = 'Goods movements in warehouses'; fa = 'Goods movements in warehouses';
											|it = 'Trasferimenti delle merci nei magazzini';
											|pl = 'Przemieszczenia towaru w magazynie';
											|tr = 'Ambarlardaki ürün hareketi'");
		
		
		ReportCommand.Importance = "Ordinary";
		ReportCommand.MultipleChoice = False;
		
		ReportCommand.AdditionalParameters.Insert("CommandName", "MovementOfGoods");
		
		ReportCommand.VariantKey = "ByProductContext";
		
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.WarehouseStock);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích biến động hàng hóa theo số lượng trong các kho của doanh nghiệp.';
									|ru = 'Анализ количественного движения товаров на складах предприятия.';
									|en = 'Analyze quantitative goods transfer within the enterprise warehouses.'; fa = 'Analyze quantitative goods transfer within the enterprise warehouses.';
									|it = 'Анализ количественного движения товаров на складах предприятия.';
									|pl = 'Analiza ilościowego przepływu towarów w magazynach firmy.';
									|tr = 'İşletmenin ambarlarındaki ürünlerin nicel hareketinin analizi.'");
	TMReportOptionsOverridable.SetImportanceOfReportOption(OptionDetails, "Important");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "WarehouseStock");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích biến động hàng hóa theo số lượng trong các kho của doanh nghiệp.';
									|ru = 'Анализ количественного движения товаров на складах предприятия.';
									|en = 'Analyze quantitative goods transfer within the enterprise warehouses.'; fa = 'Analyze quantitative goods transfer within the enterprise warehouses.';
									|it = 'Анализ количественного движения товаров на складах предприятия.';
									|pl = 'Analiza ilościowego przepływu towarów w magazynach firmy.';
									|tr = 'İşletmenin ambarlarındaki ürünlerin nicel hareketinin analizi.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "LeftoversInWarehouse");
	OptionDetails.LongDesc = NStr("vi = 'Số dư hàng hóa trong kho bãi và nhà kho trong công ty.';
									|ru = 'Остатки товаров на складах и в помещениях предприятия.';
									|en = 'Stock balance in warehouses and enterprise warerooms.'; fa = 'Stock balance in warehouses and enterprise warerooms.';
									|it = 'Остатки товаров на складах и в помещениях предприятия.';
									|pl = 'Stan magazynowy w magazynach i w pomieszczeniach firmy.';
									|tr = 'Ambarlardaki ve işletmenin tesislerindeki ürün bakiyeleri.'");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "BalancesAndTurnoverGroupedByWarehouse");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ShippedGoods");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ShippedGoodsByCurrencyConversion");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ByProductContext");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "StatementOfGoodsInWarehousesMobileClient");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích biến động hàng hóa theo số lượng trong các kho của doanh nghiệp.';
									|ru = 'Анализ количественного движения товаров на складах предприятия.';
									|en = 'Analyze quantitative goods transfer within the enterprise warehouses.'; fa = 'Analyze quantitative goods transfer within the enterprise warehouses.';
									|it = 'Анализ количественного движения товаров на складах предприятия.';
									|pl = 'Analiza ilościowego przepływu towarów w magazynach firmy.';
									|tr = 'İşletmenin ambarlarındaki ürünlerin nicel hareketinin analizi.'");
	OptionDetails.Description = NStr("vi = 'Hàng tồn trong kho (di động)';
									|ru = 'Ведомость по товарам на складах (моб.)';
									|en = 'Warehouse stock (mob. client)'; fa = 'موجودی انبار (کلاینت موبایل)';
									|it = 'Ведомость по товарам на складах (моб.)';
									|pl = 'Zestawienie według towarów w magazynach (mob.)';
									|tr = 'Ambarlardaki ürün listesi (mob.)'");
	OptionDetails.DefaultVisibility = True;
	OptionDetails.Purpose = Enums.ReportOptionPurposes.ForSmartphones;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf