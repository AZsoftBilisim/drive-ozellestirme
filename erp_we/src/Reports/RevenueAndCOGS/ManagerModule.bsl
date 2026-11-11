#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// Returns:
// 	ValueTableRow
Function AddSalesTeam(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.RevenueAndCOGS) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.RevenueAndCOGS.FullName();
		ReportCommand.Presentation = NStr("vi = 'Bán hàng';
											|ru = 'Продажи';
											|en = 'Sales'; fa = 'فروش';
											|it = 'Vendite';
											|pl = 'Sales';
											|tr = 'Satışlar'");
		
		ReportCommand.MultipleChoice = True;
		ReportCommand.Importance = "SeeAlso";
		ReportCommand.FunctionalOptions = "UseCustomerPartnerDataContext";
		ReportCommand.AdditionalParameters.Insert("CommandName", "Sales");
		ReportCommand.VariantKey = "SalesDynamicsContext";
		
		Return ReportCommand;
		
	EndIf;

	Return Undefined;

EndFunction

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// Returns:
// 	ValueTableRow
Function AddOrderSalesTeam(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.RevenueAndCOGS) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.RevenueAndCOGS.FullName();
		ReportCommand.Presentation = NStr("vi = 'Bán hàng theo đơn hàng';
											|ru = 'Продажи по заказу';
											|en = 'Sales by order'; fa = 'فروش بر اساس سفارش';
											|it = 'Vendite secondo l''ordine';
											|pl = 'Sprzedaż według zamówienia';
											|tr = 'Siparişe göre satışlar'");
		
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Important";
		ReportCommand.AdditionalParameters.Insert("CommandName", "SalesByOrder");
		ReportCommand.VariantKey = "SalesByOrderContext";
		
		Return ReportCommand;
		
	EndIf;

	Return Undefined;

EndFunction

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// Returns:
// 	ValueTableRow
Function AddSalesBySegmentCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.RevenueAndCOGS) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.RevenueAndCOGS.FullName();
		ReportCommand.Presentation = NStr("vi = 'Bán hàng theo phân khúc';
											|ru = 'Продажи по сегменту';
											|en = 'Sales by segment'; fa = 'Sales by segment';
											|it = 'Vendite per segmento';
											|pl = 'Sprzedaż według segmentów';
											|tr = 'Segmente göre satışlar'");
		
		ReportCommand.MultipleChoice = True;
		ReportCommand.Importance = "SeeAlso";
		ReportCommand.AdditionalParameters.Insert("CommandName", "SalesBySegment");
		ReportCommand.VariantKey = "SalesDynamicsContext";
		
		Return ReportCommand;
		
	EndIf;

	Return Undefined;

EndFunction

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// Returns:
// 	ValueTableRow
Function AddProductSalesTeam(ReportsCommands) Export
	
	If AccessRight("View", Metadata.Reports.RevenueAndCOGS) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.RevenueAndCOGS.FullName();
		ReportCommand.Presentation = NStr("vi = 'Bán hàng';
											|ru = 'Продажи номенклатуры';
											|en = 'Product sales'; fa = 'فروش محصولات';
											|it = 'Nomenclatura vendite';
											|pl = 'Sprzedaż nomenklatury';
											|tr = 'Öğe satışları'");
		
		
		ReportCommand.Importance = "Ordinary";
		ReportCommand.MultipleChoice = False;
		
		ReportCommand.AdditionalParameters.Insert("CommandName", "SalesByProducts");
		
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
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings
//   UseMultipleKindsOfProducts - Boolean -
//
Procedure CustomizeReportOptions(Settings, UseMultipleKindsOfProducts) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.RevenueAndCOGS);
	DescriptionOfReport.DefineFormSettings = True;
	
	// Common.
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích tài chính về doanh thu bán hàng theo doanh nghiệp, khách hàng, người quản lý, 
		|kho bãi, mặt hàng.';
		|ru = 'Финансовый анализ продаж по аналитикам организации, клиенты, менеджеры, 
		|склады, номенклатура и другим.';
		|en = 'Financial analysis of sales by company dimensions, customers, managers, 
		|warehouses, products, etc.'; fa = 'Financial analysis of sales by company dimensions, customers, managers, 
		|warehouses, products, etc.';
		|it = 'Финансовый анализ продаж по аналитикам организации, клиенты, менеджеры, 
		|склады, номенклатура и другим.';
		|pl = 'Analiza finansowa sprzedaży według analityk firmy, klienty, menedżery, 
		|magazyny, produkty i innym.';
		|tr = 'İş yeri boyutlarına, müşterilere, yöneticilere, 
		|ambarlara, öğelere ve diğer seçeneklere göre satışların finansal analizi.'");
	TMReportOptionsOverridable.SetImportanceOfReportOption(OptionDetails, "Important");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "SalesDynamics");
	OptionDetails.LongDesc = NStr("vi = 'Khối lượng bán hàng hàng tháng trong kỳ đã chọn theo dạng mặt hàng.
									 |Có thể phân tích theo kỳ - quý, tháng, tuần, ngày.';
									 |ru = 'Помесячные объемы продаж за выбранный период по видам номенклатуры.
									 |Возможен анализ по периодам - квартал, месяц, неделя, день.';
									 |en = 'Monthly sales volume for the selected period by item kinds.
									 |Analysis is available by the following periods - quarter, month, week, day.'; fa = 'Monthly sales volume for the selected period by item kinds.
									 |Analysis is available by the following periods - quarter, month, week, day.';
									 |it = 'Помесячные объемы продаж за выбранный период по видам номенклатуры.
									 |Возможен анализ по периодам - квартал, месяц, неделя, день.';
									 |pl = 'Miesięczne objętości sprzedaży za wybrany okres według rodzajów produktów. 
									 |Jest możliwa analiza według okresów - kwartał, miesiąc, tydzień, dzień.';
									 |tr = 'Öğe türlerine göre seçilen dönem için aylık satış hacimleri.
									 |Dönemlere göre analiz mümkündür; çeyrek, ay, hafta, gün.'");
	OptionDetails.Description = NStr("vi = 'Biến động bán hàng theo dạng mặt hàng';
									|ru = 'Динамика продаж по видам номенклатуры';
									|en = 'Sales trends by item kinds'; fa = 'Sales trends by item kinds';
									|it = 'Динамика продаж по видам номенклатуры';
									|pl = 'Sales trends by item kinds';
									|tr = 'Öğe türlerine göre satış dinamikleri'");
	OptionDetails.FunctionalOptions.Add("UseMultipleKindsOfProducts");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "SalesDynamicsBusinessRegions");
	OptionDetails.LongDesc = ?(UseMultipleKindsOfProducts, 
									NStr("vi = 'Khối lượng bán hàng hàng tháng trong kỳ đã chọn theo khu vực kinh doanh và dạng mặt hàng.
										 |Có thể phân tích theo kỳ - quý, tháng, tuần, ngày.';
										 |ru = 'Помесячные объемы продаж за выбранный период по бизнес-регионам и видам номенклатуры.
										 |Возможен анализ по периодам - квартал, месяц, неделя, день.';
										 |en = 'Monthly sales volume for the selected period by business regions and item kinds.
										 |Analysis is available by the following periods - quarter, month, week, day.'; fa = 'Monthly sales volume for the selected period by business regions and item kinds.
										 |Analysis is available by the following periods - quarter, month, week, day.';
										 |it = 'Помесячные объемы продаж за выбранный период по бизнес-регионам и видам номенклатуры.
										 |Возможен анализ по периодам - квартал, месяц, неделя, день.';
										 |pl = 'Miesięczne objętości sprzedaży za wybrany okres według regionów biznesowych i rodzajów produktów. 
										 |Jest możliwa analiza według okresów - kwartał, miesiąc, tydzień, dzień.';
										 |tr = 'İş bölgeleri ve öğe türlerine göre seçilen dönem kapsamında aylık satış hacimleri.
										 |Çeyrek, ay, hafta, gün gibi dönemler bazında analiz etmek mümkündür.'"),
									NStr("vi = 'Khối lượng bán hàng hàng tháng trong kỳ đã chọn theo khu vực kinh doanh.
										 |Có thể phân tích theo kỳ - quý, tháng, tuần, ngày.';
										 |ru = 'Помесячные объемы продаж за выбранный период по бизнес-регионам.
										 |Возможен анализ по периодам - квартал, месяц, неделя, день.';
										 |en = 'Monthly sales volume for the selected period by business regions.
										 |Analysis is available by the following periods: a quarter, a month, a week, a day.'; fa = 'Monthly sales volume for the selected period by business regions.
										 |Analysis is available by the following periods: a quarter, a month, a week, a day.';
										 |it = 'Помесячные объемы продаж за выбранный период по бизнес-регионам.
										 |Возможен анализ по периодам - квартал, месяц, неделя, день.';
										 |pl = 'Monthly sales volume for the selected period by business regions.
										 |Analysis is available by the following periods: a quarter, a month, a week, a day.';
										 |tr = 'İş bölgelerine göre seçilen dönem kapsamında aylık satış hacimleri.
										 |Dönemlere göre analiz mümkündür; çeyrek, ay, hafta, gün.'"));
	OptionDetails.Description = ?(UseMultipleKindsOfProducts, 
										NStr("vi = 'Biến động bán hàng theo khu vực kinh doanh và dạng mặt hàng';
											|ru = 'Динамика продаж по бизнес-регионам и видам номенклатуры';
											|en = 'Sales trends by business regions and item kinds'; fa = 'Sales trends by business regions and item kinds';
											|it = 'Динамика продаж по бизнес-регионам и видам номенклатуры';
											|pl = 'Sales trends by business regions and item kinds';
											|tr = 'İş bölgelerine ve öğe türlerine göre satış dinamikleri'"),
										NStr("vi = 'Biến động bán hàng theo khu vực kinh doanh';
											|ru = 'Динамика продаж по бизнес-регионам';
											|en = 'Sales trends by business regions'; fa = 'Sales trends by business regions';
											|it = 'Динамика продаж по бизнес-регионам';
											|pl = 'Sales trends by business regions';
											|tr = 'İş bölgelerine göre satış dinamikleri'"));
	Subsystem = Metadata.FindByFullName("Subsystem.Sales.Subsystem.WholesaleSalesInPastPeriods");
	OptionDetails.Location.Insert(Subsystem);
	OptionDetails.FunctionalOptions.Add("UseBusinessRegions");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "SalesByPartnersBasic");
	OptionDetails.LongDesc = NStr("vi = 'Những khách hàng nào đem lại lợi nhuận cao nhất?';
									|ru = 'По каким клиентам получена наибольшая валовая прибыль?';
									|en = 'Check which customers brought the biggest gross profit.'; fa = 'Check which customers brought the biggest gross profit.';
									|it = 'По каким клиентам получена наибольшая валовая прибыль?';
									|pl = 'Według jakich klientów jest otrzymany największy zysk brutto?';
									|tr = 'Hangi müşteriler en yüksek brüt kârı sağladı?'");
	OptionDetails.FunctionalOptions.Add("BaseVersion");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "SalesBySupplier");
	OptionDetails.LongDesc = NStr("vi = 'Đối với hàng hóa từ nhà cung cấp nào đã nhận lãi gộp cao nhất?';
									|ru = 'По товарам от каких поставщиков получена наибольшая валовая прибыль?';
									|en = 'Verify goods of which vendors generated the biggest gross profit.'; fa = 'Verify goods of which vendors generated the biggest gross profit.';
									|it = 'По товарам от каких поставщиков получена наибольшая валовая прибыль?';
									|pl = 'Według towarów od jakich dostawców jest otrzymany największy zysk brutto?';
									|tr = 'Hangi tedarikçilerden ürünler için en yüksek brüt kâr sağlandı?'");
	Subsystem = Metadata.FindByFullName("Subsystem.FinancialResultAndControlling.Subsystem.FinancialResult");
	OptionDetails.Location.Delete(Subsystem);
	
	// By company.
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "SalesSummary");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích bán hàng tổng hợp theo bộ phận (cửa hàng), 
		|người quản lý và mặt hàng.';
		|ru = 'Сводный анализ продаж по подразделениям (магазинам), 
		|менеджерам и номенклатуре.';
		|en = 'Summary analysis of sales by business units (stores), 
		|sales persons, and items.'; fa = 'Summary analysis of sales by business units (stores), 
		|sales persons, and items.';
		|it = 'Сводный анализ продаж по подразделениям (магазинам), 
		|менеджерам и номенклатуре.';
		|pl = 'Skonsolidowana analiza według działów (sklepów), 
		|menedżerów i produktów.';
		|tr = 'Departmanlara (mağazalara), 
		|yöneticilere ve öğeye göre özet satış analizi.'");
	Subsystem = Metadata.FindByFullName("Subsystem.Sales.Subsystem.WholesaleSalesInPastPeriods");
	OptionDetails.Location.Insert(Subsystem, "Important");
	Subsystem = Metadata.FindByFullName("Subsystem.FinancialResultAndControlling.Subsystem.FinancialResult");
	OptionDetails.Location.Insert(Subsystem);
	OptionDetails.FunctionalOptions.Add("NotBaseVersion");
	OptionDetails.FunctionalOptions.Add("UseCustomerInvoiceIntercompany");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "SalesSummaryBasic");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích bán hàng tổng hợp theo doanh nghiệp, bộ phận (cửa hàng), 
		|người quản lý và mặt hàng.';
		|ru = 'Сводный анализ продаж по организациям, подразделениям (магазинам), 
		|менеджерам и номенклатуре.';
		|en = 'Summary analysis of sales by companies, business units (stores), 
		|sales persons, and items.'; fa = 'Summary analysis of sales by companies, business units (stores), 
		|sales persons, and items.';
		|it = 'Сводный анализ продаж по организациям, подразделениям (магазинам), 
		|менеджерам и номенклатуре.';
		|pl = 'Skonsolidowana analiza sprzedaży według firmy, działów (sklepów), 
		|menedżerów i produktów.';
		|tr = 'İş yerlerine, departmanlara (mağazalara), 
		|yöneticilere ve öğeye göre özet satış analizi.'");
	OptionDetails.FunctionalOptions.Add("BaseVersion");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "SalesDynamicsContext");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ByProductContext");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "SalesByOrderContext");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "SalesByEnterpriseTransactions");
	OptionDetails.LongDesc = NStr("vi = 'Những loại giao dịch và giao dịch nào có doanh số cao nhất cho khách hàng trong tập đoàn?';
									|ru = 'По каким видам сделок и сделкам больше всего продаж клиентам по предприятию?';
									|en = 'Verify which sales opportunities and sales opportunity kinds bring the most sales to customers across the enterprise.'; fa = 'Verify which sales opportunities and sales opportunity kinds bring the most sales to customers across the enterprise.';
									|it = 'По каким видам сделок и сделкам больше всего продаж клиентам по предприятию?';
									|pl = 'Według jakich rodzajów umowy i umów jest najwięcej sprzedaży klientom w firmie?';
									|tr = 'Hangi satış fırsatları ve satış fırsatı türleri işletme genelinde müşterilere en fazla satışı sağlamaktadır?'");
	Subsystem = Metadata.FindByFullName("Subsystem.Sales.Subsystem.WholesaleSalesInPastPeriods");
	OptionDetails.Location.Delete(Subsystem);
	Subsystem = Metadata.FindByFullName("Subsystem.FinancialResultAndControlling.Subsystem.FinancialResult");
	OptionDetails.Location.Delete(Subsystem);
	Subsystem = Metadata.FindByFullName("Subsystem.CRMAndMarketing.Subsystem.OpportunityProcessingReports");
	OptionDetails.Location.Insert(Subsystem);
	OptionDetails.FunctionalOptions.Add("UseSalesOpportunitiesToCustomer");
	OptionDetails.FunctionalOptions.Add("UseCustomerInvoiceIntercompany");
	OptionDetails.DefaultVisibility = True;
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "SalesByEnterprisePartners");
	OptionDetails.LongDesc = NStr("vi = 'Đối với khách hàng nào nhận được lợi nhuận gộp cao nhất cho công ty?';
									|ru = 'По каким клиентам получена наибольшая валовая прибыль по предприятию?';
									|en = 'Check which customers brought the biggest gross profit by enterprise.'; fa = 'Check which customers brought the biggest gross profit by enterprise.';
									|it = 'По каким клиентам получена наибольшая валовая прибыль по предприятию?';
									|pl = 'Według jakich klientów jest otrzymany największy zysk brutto w przedsiębiorstwie?';
									|tr = 'İşletme için en yüksek brüt kârı hangi müşteriler sağlıyor?'");
	Subsystem = Metadata.FindByFullName("Subsystem.FinancialResultAndControlling.Subsystem.FinancialResult");
	OptionDetails.Location.Delete(Subsystem);
	OptionDetails.FunctionalOptions.Add("NotBaseVersion");
	OptionDetails.FunctionalOptions.Add("UseCustomerInvoiceIntercompany");
	
	// By organizations.
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "SalesOfOrganizations");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích bán hàng tổng hợp theo doanh nghiệp, bộ phận (cửa hàng), 
		|người quản lý và mặt hàng.';
		|ru = 'Сводный анализ продаж по организациям, подразделениям (магазинам), 
		|менеджерам и номенклатуре.';
		|en = 'Summary analysis of sales by companies, business units (stores), 
		|sales persons, and items.'; fa = 'Summary analysis of sales by companies, business units (stores), 
		|sales persons, and items.';
		|it = 'Сводный анализ продаж по организациям, подразделениям (магазинам), 
		|менеджерам и номенклатуре.';
		|pl = 'Skonsolidowana analiza sprzedaży według firmy, działów (sklepów), 
		|menedżerów i produktów.';
		|tr = 'İş yerlerine, departmanlara (mağazalara), 
		|yöneticilere ve öğeye göre özet satış analizi.'");
	Subsystem = Metadata.FindByFullName("Subsystem.FinancialResultAndControlling.Subsystem.FinancialResult");
	OptionDetails.Location.Insert(Subsystem);
	OptionDetails.FunctionalOptions.Add("NotBaseVersion");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "SalesByTransactionsByOrganizations");
	OptionDetails.LongDesc = NStr("vi = 'Những loại giao dịch và giao dịch nào có doanh số cao nhất cho khách hàng theo doanh nghiệp?';
									|ru = 'По каким видам сделок и сделкам больше всего продаж клиентам по организациям?';
									|en = 'Verify which sales opportunities and sales opportunity kinds bring the most sales to customers by companies.'; fa = 'Verify which sales opportunities and sales opportunity kinds bring the most sales to customers by companies.';
									|it = 'По каким видам сделок и сделкам больше всего продаж клиентам по организациям?';
									|pl = 'Według jakich rodzajów umowy i umowy jest najwięcej sprzedaży klientom według firm?';
									|tr = 'Hangi satış fırsatları ve satış fırsatı türleri iş yeri genelinde müşterilere en fazla satışı sağlamaktadır?'");
	Subsystem = Metadata.FindByFullName("Subsystem.Sales.Subsystem.WholesaleSalesInPastPeriods");
	OptionDetails.Location.Delete(Subsystem);
	Subsystem = Metadata.FindByFullName("Subsystem.FinancialResultAndControlling.Subsystem.FinancialResult");
	OptionDetails.Location.Delete(Subsystem);
	Subsystem = Metadata.FindByFullName("Subsystem.CRMAndMarketing.Subsystem.OpportunityProcessingReports");
	OptionDetails.Location.Insert(Subsystem);
	OptionDetails.FunctionalOptions.Add("UseSalesOpportunitiesToCustomer");
	OptionDetails.DefaultVisibility = True;
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "SalesByOrganizationPartners");
	OptionDetails.LongDesc = NStr("vi = 'Đối với những khách hàng nào nhận được lợi nhuận gộp cao nhất của các doanh nghiệp?';
									|ru = 'По каким клиентам получена наибольшая валовая прибыль по организациям?';
									|en = 'Check which customers brought the biggest gross profit by the companies.'; fa = 'Check which customers brought the biggest gross profit by the companies.';
									|it = 'По каким клиентам получена наибольшая валовая прибыль по организациям?';
									|pl = 'Według jakich klientów jest otrzymany największy zysk brutto według firm?';
									|tr = 'İş yerine göre en yüksek brüt kârı hangi müşteriler sağlıyor?'");
	Subsystem = Metadata.FindByFullName("Subsystem.FinancialResultAndControlling.Subsystem.FinancialResult");
	OptionDetails.Location.Delete(Subsystem);
	OptionDetails.FunctionalOptions.Add("NotBaseVersion");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "SalesSummaryMobileClient");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích bán hàng tổng hợp theo bộ phận (cửa hàng), 
		|người quản lý và mặt hàng.';
		|ru = 'Сводный анализ продаж по подразделениям (магазинам), 
		|менеджерам и номенклатуре.';
		|en = 'Summary analysis of sales by business units (stores), 
		|sales persons, and items.'; fa = 'Summary analysis of sales by business units (stores), 
		|sales persons, and items.';
		|it = 'Сводный анализ продаж по подразделениям (магазинам), 
		|менеджерам и номенклатуре.';
		|pl = 'Skonsolidowana analiza według działów (sklepów), 
		|menedżerów i produktów.';
		|tr = 'Departmanlara (mağazalara), 
		|yöneticilere ve öğeye göre özet satış analizi.'");
	OptionDetails.Description = NStr("vi = 'Lợi nhuận gộp của tập đoàn (di động)';
									|ru = 'Валовая прибыль предприятия (моб.)';
									|en = 'Enterprise gross profit (mob. client)'; fa = 'سود ناخالص سازمان (کلاینت موبایل)';
									|it = 'Валовая прибыль предприятия (моб.)';
									|pl = 'Zysk brutto przedsiębiorstwa (mob.)';
									|tr = 'İşletmenin brüt kârı (mob.)'");
	OptionDetails.DefaultVisibility = True;
	OptionDetails.Purpose = Enums.ReportOptionPurposes.ForSmartphones;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf