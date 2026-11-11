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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ReleasedProductsCostAnalysis);
	DescriptionOfReport.DefineFormSettings = True;
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích giá thành xuất xưởng thực tế sau khi đóng tháng.';
									|ru = 'Анализ фактической себестоимости выпущенной продукции после закрытия месяца.';
									|en = 'Analysis of actual cost of released products after month-end closing.'; fa = 'Analysis of actual cost of released products after month-end closing.';
									|it = 'Анализ фактической себестоимости выпущенной продукции после закрытия месяца.';
									|pl = 'Analiza kosztu rzeczywistego wyprodukowanej produkcji po zamknięciu miesiąca.';
									|tr = 'Ay sonu kapanışından sonra gerçekleşen imal edilen ürün maliyetinin analizi.'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ReleasedProductsCostAnalysis");
	OptionDetails.LongDesc = NStr("vi = 'Giá thành sản xuất của một sản phẩm là bao nhiêu?
		|Tổng giá thành của toàn bộ thành phẩm trong kỳ theo doanh nghiệp là bao nhiêu?';
		|ru = 'Какова себестоимость единицы произведенной продукции?
		|Какова совокупная себестоимость всей выпущенной продукции за период по организациям?';
		|en = 'Track the cost of manufactured product item.
		|Check the overall cost of all products manufactured for the period by companies.'; fa = 'Track the cost of manufactured product item.
		|Check the overall cost of all products manufactured for the period by companies.';
		|it = 'Какова себестоимость единицы произведенной продукции?
		|Какова совокупная себестоимость всей выпущенной продукции за период по организациям?';
		|pl = 'Jakie są koszty własne jednostki wyprodukowanej produkcji? 
		|Jakie całkowite koszty własne całej wyprodukowanej produkcji za okres według firm?';
		|tr = 'İmal edilen ürün birim maliyeti nedir?
		|İş yerlerine göre dönem için tüm imal edilen ürünlerin toplam maliyeti nedir?'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "AnalysisOfReleasedProductCostByEnterprise");
	OptionDetails.LongDesc = NStr("vi = 'Giá thành sản xuất của một sản phẩm là bao nhiêu?
		|Tổng giá thành của toàn bộ thành phẩm trong kỳ theo doanh nghiệp là bao nhiêu?';
		|ru = 'Какова себестоимость единицы произведенной продукции?
		|Какова совокупная себестоимость всей выпущенной продукции за период по предприятию?';
		|en = 'Track the cost of manufactured product item.
		|Check the overall cost of all products manufactured for the period by the enterprise.'; fa = 'Track the cost of manufactured product item.
		|Check the overall cost of all products manufactured for the period by the enterprise.';
		|it = 'Какова себестоимость единицы произведенной продукции?
		|Какова совокупная себестоимость всей выпущенной продукции за период по предприятию?';
		|pl = 'Jakie są koszty własne jednostki wyprodukowanej produkcji? 
		|Jakie całkowite koszty własne całej wyprodukowanej produkcji za okres w przedsiębiorstwie?';
		|tr = 'İmal edilen ürünün birim maliyeti nedir?
		|İş yerine göre dönem için tüm imal edilen ürünlerin toplam maliyeti nedir?'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ComparisonOfCostOfManufacturedProductsByOrders");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích giá thành riêng của thành phẩm xuất xưởng theo tập đoàn.';
									|ru = 'Позаказный анализ удельной себестоимости выпущенной продукции по организациям.';
									|en = 'Order analysis of the issued product unit cost by companies.'; fa = 'Order analysis of the issued product unit cost by companies.';
									|it = 'Позаказный анализ удельной себестоимости выпущенной продукции по организациям.';
									|pl = 'Analiza według zamówień właściwych kosztów własnych wyprodukowanej produkcji według firm.';
									|tr = 'İmal edilen ürünlerin birim maliyetinin iş yerlerine göre sipariş bazında analizi.'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "CompareReleasedProductCostByOrdersByEnterprise");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích giá thành riêng của thành phẩm xuất xưởng theo tập đoàn.';
									|ru = 'Позаказный анализ удельной себестоимости выпущенной продукции по предприятию.';
									|en = 'Order analysis of the issued product unit cost by the enterprise.'; fa = 'Order analysis of the issued product unit cost by the enterprise.';
									|it = 'Позаказный анализ удельной себестоимости выпущенной продукции по предприятию.';
									|pl = 'Analiza według zamówień właściwych kosztów własnych wyprodukowanej produkcji w przedsiębiorstwie.';
									|tr = 'İmal edilen ürünlerin birim maliyetinin işletmelere göre sipariş bazında analizi.'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ProductionAtPlannedCostByCompany");
	OptionDetails.LongDesc = NStr("vi = 'Xuất xưởng thành phẩm theo giá trị dự tính theo doanh nghiệp.';
									|ru = 'Выпуск продукции по плановой стоимости по организациям.';
									|en = 'Product release at the standard cost by company.'; fa = 'Product release at the standard cost by company.';
									|it = 'Product release at the standard cost by company.';
									|pl = 'Product release at the standard cost by company.';
									|tr = 'İş yeri dahilinde planlanan değerde üretim çıkışı.'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ProductionAtPlannedCostOfEnterprise");
	OptionDetails.LongDesc = NStr("vi = 'Xuất xưởng thành phẩm theo giá trị dự tính theo doanh nghiệp.';
									|ru = 'Выпуск продукции по плановой стоимости по предприятию.';
									|en = 'Product release at the standard cost by enterprise.'; fa = 'Product release at the standard cost by enterprise.';
									|it = 'Product release at the standard cost by enterprise.';
									|pl = 'Product release at the standard cost by enterprise.';
									|tr = 'İşletme dahilinde planlanan değerde üretim çıkışı.'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
