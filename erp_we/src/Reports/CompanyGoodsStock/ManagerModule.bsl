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
	
	If AccessRight("View", Metadata.Reports.CompanyGoodsStock) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.CompanyGoodsStock.FullName();
		ReportCommand.Presentation = NStr("vi = 'Biến động hàng hóa trong doanh nghiệp';
											|ru = 'Движения товара в организациях';
											|en = 'Transfers of goods in companies'; fa = 'انتقال‌های کالا در شرکت‌ها';
											|it = 'Trasferimento delle merci nelle società';
											|pl = 'Przemieszczenia towarów w firmach';
											|tr = 'İş yerlerinde ürün hareketi'");
		
		
		ReportCommand.Importance = "Ordinary";
		ReportCommand.MultipleChoice = False;
		
		ReportCommand.AdditionalParameters.Insert("CommandName", "ListOfProductsOfOrganizations");
		
		ReportCommand.VariantKey = "ByProductContext";
		
		ReportCommand.FunctionalOptions = "UseMultipleCompanies";
		
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.CompanyGoodsStock);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Kiểm soát số dư và biến động hàng hóa theo doanh nghiệp.';
									|ru = 'Контроль остатков и движений товаров по организациям.';
									|en = 'Control stock balance and goods transfers by companies.'; fa = 'Control stock balance and goods transfers by companies.';
									|it = 'Контроль остатков и движений товаров по организациям.';
									|pl = 'Kontrola stanu magazynowego i przepływów towarów według firm.';
									|tr = 'İş yerlerine göre bakiyelerin ve ürün hareketinin kontrolü.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "MovementOfGoodsOfOrganizations");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích biến động hàng hóa trong kho bãi và doanh nghiệp.
		|Doanh nghiệp nào và kho bãi nào có hàng hóa và đã có biến động trong kỳ?';
		|ru = 'Анализ движений товаров на складах и организациях.
		|В какой организации и по какому складу есть товар и были движения за период?';
		|en = 'Analyze goods transfer in warehouses and companies.
		|Shows which company and warehouse have goods available and transfers over the period.'; fa = 'Analyze goods transfer in warehouses and companies.
		|Shows which company and warehouse have goods available and transfers over the period.';
		|it = 'Анализ движений товаров на складах и организациях.
		|В какой организации и по какому складу есть товар и были движения за период?';
		|pl = 'Analiza przepływów towarów w magazynach i firmach. 
		|W jakiej firmie i według jakiego magazynu jest towar i były przepływy za okres?';
		|tr = 'Ambar ve iş yerlerindeki stok transferi analizi.
		|Hangi iş yerinde ve hangi ambarda ürünün mevcut olduğunu ve dönem içinde transferlerin olup olmadığını tanımlar.'");
	ReportSubsystem = Metadata.FindByFullName("Subsystem.Sales.Subsystem.WholesaleSalesInPastPeriods");
	OptionDetails.Location.Insert(ReportSubsystem);
	TMReportOptionsOverridable.SetImportanceOfReportOption(OptionDetails, "Important");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "CompanyGoodsAvailableForSale");
	OptionDetails.LongDesc = NStr("vi = 'Những hàng hóa nào trong kho được phép bán nhân danh doanh nghiệp đã chọn?';
									|ru = 'Какие товары доступны на складах для продажи от имени выбранной организации?';
									|en = 'Which goods are available for sale in warehouses on behalf of the selected company?'; fa = 'Which goods are available for sale in warehouses on behalf of the selected company?';
									|it = 'Какие товары доступны на складах для продажи от имени выбранной организации?';
									|pl = 'Jakie wiersze pozycji są dostępne w magazynach dla sprzedaży w imieniu wybranej firmy?';
									|tr = 'Seçilen iş yeri adına ambarlarda satılabilir ürünler nelerdir?'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "MovementOfGoodsTransferred");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích biến động hàng hóa đã chuyển giao vào cất giữ.
		|Bạn hàng nào và theo hợp đồng nào có hàng hóa của chúng ta và có biến động trong kỳ?';
		|ru = 'Анализ движений товаров, переданных на хранение.
		|У каких партнеров и по каким договорам есть наш товар и были движения за период?';
		|en = 'Analyze transfer of VMI.
		|Check partners and contracts for our goods and transfers over the period.'; fa = 'Analyze transfer of VMI.
		|Check partners and contracts for our goods and transfers over the period.';
		|it = 'Анализ движений товаров, переданных на хранение.
		|У каких партнеров и по каким договорам есть наш товар и были движения за период?';
		|pl = 'Analiza ruchów towarów, przekazanych do przechowywania.
		|U takich partnerów i według jakich umów jest nasz produkt i czy nastąpiły zmiany w tym okresie?';
		|tr = 'Depolanmak üzere transfer edilen ürün akışı analizi.
		|Ürünlerimiz hangi iş ortakları ve hangi sözleşmeler kapsamında bulunuyor ve dönem içinde herhangi bir hareket oldu mu?'");
	OptionDetails.FunctionalOptions.Add("UseTransferToCustodyWithRightOfSale");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "MovementOfGoodsTransferredToCommission25");
	OptionDescription = NStr("vi = 'Bảng kê hàng hóa đã chuyển giao đi ký gửi';
							|ru = 'Ведомость по переданным на комиссию товарам';
							|en = 'Consignment sales stock statement'; fa = 'صورت موجودی فروش امانی';
							|it = 'Ведомость по переданным на комиссию товарам';
							|pl = 'Zestawienie wg towarów, przekazanych do komisu';
							|tr = 'Konsinye stok ekstresi'");
	OptionDescription = ConsignmentSalesServer.AddCommissionPostfix25(OptionDescription);
	OptionDetails.Description = OptionDescription;
	OptionDetails.LongDesc = NStr("vi = 'Phân tích biến động hàng hóa đã chuyển giao vào ký gửi.
		|Bạn hàng nào và theo hợp đồng nào có hàng hóa của chúng ta và có biến động trong kỳ?';
		|ru = 'Анализ движений товаров, переданных на комиссию.
		|У каких партнеров и по каким договорам есть наш товар и были движения за период?';
		|en = 'Analyze transfers of consignment sales stock.
		|Check partners and contracts for our goods and transfers over the period.'; fa = 'Analyze transfers of consignment sales stock.
		|Check partners and contracts for our goods and transfers over the period.';
		|it = 'Анализ движений товаров, переданных на комиссию.
		|У каких партнеров и по каким договорам есть наш товар и были движения за период?';
		|pl = 'Analiza ruchów towarów, przekazanych do komisu.
		|U takich partnerów i według jakich umów jest nasz produkt i czy nastąpiły zmiany w tym okresie?';
		|tr = 'Komisyon karşılığı transfer edilen ürün akışının analizi.
		|Ürünlerimiz hangi iş ortakları ve hangi sözleşmeler kapsamında bulunuyor ve dönem içinde herhangi bir akış var mıydı?'");
	OptionDetails.FunctionalOptions.Add("UseSalesCommission");
	ReportSubsystem = Metadata.FindByFullName("Subsystem.Sales.Subsystem.ConsignmentSales");
	OptionDetails.Location.Insert(ReportSubsystem);
	OptionDetails.DefaultVisibility = True;
	
	DisableOptionForMovingGoodsTransferredToProcessors = True;
	DisableOptionForMovingGoodsTransferredToProcessors = False;
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "MovementOfGoodsTransferredToProcessors");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích biến động hàng hóa đang lưu kho tại bên nhận gia công.
									|Bạn hàng nào và theo hợp đồng nào có hàng hóa của chúng ta và có biến động trong kỳ?';
									|ru = 'Анализ движений товаров, хранящихся у переработчиков.
									|У каких переработчиков и по каким договорам есть наш товар и были движения за период?';
									|en = 'Analyze transfers of goods stored at subcontractors.
									|Check subcontractors and contracts for our goods and transfers over the period.'; fa = 'Analyze transfers of goods stored at subcontractors.
									|Check subcontractors and contracts for our goods and transfers over the period.';
									|it = 'Анализ движений товаров, хранящихся у переработчиков.
									|У каких переработчиков и по каким договорам есть наш товар и были движения за период?';
									|pl = 'Analiza ruchów towarów, przechowywanych u przetwórców.
									|U jakich przetwórców i według jakich umów jest nasz towar i czy nastąpiły ruchy w tym okresi?';
									|tr = 'İşleyiciler tarafından depolanan ürün akışının analizi.
									|Ürünlerimiz hangi fasonlarda ve hangi sözleşmeler kapsamında bulunuyor ve dönem içinde herhangi bir akış var mıydı?'");
	OptionDetails.FunctionalOptions.Add("UseProductionByThirdParty2_5");
	
	TMReportOptionsOverridable.ChangePlacementOfReportVariant(OptionDetails.Location, "Insert", "Production.TransferToRecycling2_5");
	TMReportOptionsOverridable.ChangePlacementOfReportVariant(OptionDetails.Location, "Insert", "Production.TransferToProcessing2_5WithHeaders");
	
	OptionDetails.DefaultVisibility = True;
	If DisableOptionForMovingGoodsTransferredToProcessors Then
		TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "MovementOfGoodsTransferredToProcessors");
	EndIf;
	
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "CompanyStockBalance");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ByProductContext");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ByProductContextBasic");
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf