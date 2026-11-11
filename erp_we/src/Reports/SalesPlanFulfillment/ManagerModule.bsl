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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.SalesPlanFulfillment);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Đánh giá trạng thái thực tế bán hàng theo kế hoạch.
		|Các đơn hàng nào của khách vẫn chưa được giao khỏi kho?';
		|ru = 'Оценка фактического состояния продаж товаров по плану.
		|Какие заказы клиентов еще не отгружены со склада?';
		|en = 'Evaluate actual state of goods sales according to the plan.
		|Check which sales orders have not been shipped from the warehouse yet.'; fa = 'Evaluate actual state of goods sales according to the plan.
		|Check which sales orders have not been shipped from the warehouse yet.';
		|it = 'Оценка фактического состояния продаж товаров по плану.
		|Какие заказы клиентов еще не отгружены со склада?';
		|pl = 'Ocena faktycznego statusu sprzedaży towarów według planu. 
		|Jakie zamówienia klientów jeszcze nie są wysłane z magazynu?';
		|tr = 'Plana göre ürün satışlarının fiilî durumunun değerlendirilmesi.
		|Hangi satış siparişleri henüz ambardan sevk edilmedi?'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "PaymentPlanFulfillmentByCustomers");
	OptionDetails.LongDesc = NStr("vi = 'Kiểm tra việc thực hiện kế hoạch thanh toán theo thu nhập thực tế.
		|Kế hoạch và thực tế giao hàng cho khách trong kỳ.';
		|ru = 'Проверка исполнения плана оплат по фактическому приходу денежных средств.
		|Плана и факт отгрузок клиенту за период.';
		|en = 'Check payment plan fulfillment against actual cash inflow.
		|View planned and actual shipments to the customer over the period.'; fa = 'Check payment plan fulfillment against actual cash inflow.
		|View planned and actual shipments to the customer over the period.';
		|it = 'Проверка исполнения плана оплат по фактическому приходу денежных средств.
		|Плана и факт отгрузок клиенту за период.';
		|pl = 'Weryfikacja wykonania planu płatności według faktycznej wpłaty środków pieniężnych-gotówki. 
		|Plan i fakt wysyłki klientowi za okres.';
		|tr = 'Fiilî nakit alımına dayalı olarak ödeme planının yürütülmesinin kontrol edilmesi.
		|Plan ve dönem için müşteriye yapılan sevkiyatların durumu.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "SalesForecastFulfillmentByCustomers");
	OptionDetails.LongDesc = NStr("vi = 'Biến động thực hiện thực tế so với kế hoạch theo từng khách hàng và mặt hàng.';
									|ru = 'Динамика фактического исполнения плана в разрезе клиентов и номенклатуры.';
									|en = 'Monitor plan fulfillment by customers and items.'; fa = 'Monitor plan fulfillment by customers and items.';
									|it = 'Динамика фактического исполнения плана в разрезе клиентов и номенклатуры.';
									|pl = 'Dynamika faktycznego wykonania planu w przekroju klientów i produktów.';
									|tr = 'Müşteriler ve öğe bağlamında fiilî plan yürütme dinamikleri.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "SalesForecastFulfillmentByManagers");
	OptionDetails.LongDesc = NStr("vi = 'Biến động thực hiện thực tế so với kế hoạch theo từng người quản lý và mặt hàng.';
									|ru = 'Динамика фактического исполнения плана в разрезе менеджеров и номенклатуры.';
									|en = 'Monitor plan fulfillment by managers and items.'; fa = 'Monitor plan fulfillment by managers and items.';
									|it = 'Динамика фактического исполнения плана в разрезе менеджеров и номенклатуры.';
									|pl = 'Dynamika faktycznego wykonania planu w przekroju menedżerów i produktów.';
									|tr = 'Yöneticiler ve öğe bağlamında fiilî plan yürütme dinamikleri.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "SalesForecastFulfillmentByDepartments");
	OptionDetails.LongDesc = NStr("vi = 'Biến động thực hiện kế hoạch trên thực tế theo từng bộ phận và mặt hàng.';
									|ru = 'Динамика фактического исполнения плана в разрезе подразделений и номенклатуры.';
									|en = 'Monitor plan fulfillment by business units and items.'; fa = 'Monitor plan fulfillment by business units and items.';
									|it = 'Динамика фактического исполнения плана в разрезе подразделений и номенклатуры.';
									|pl = 'Dynamika faktycznego wykonania planu w przekroju działów i produktów.';
									|tr = 'Departman ve öğe bağlamında fiilî plan yürütme dinamikleri.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "SalesForecastFulfillmentByWarehouses");
	OptionDetails.LongDesc = NStr("vi = 'Biến động thực hiện thực tế so với kế hoạch theo từng kho bãi và mặt hàng.';
									|ru = 'Динамика фактического исполнения плана в разрезе складов и номенклатуры.';
									|en = 'Monitor plan fulfillment by warehouses and items.'; fa = 'Monitor plan fulfillment by warehouses and items.';
									|it = 'Динамика фактического исполнения плана в разрезе складов и номенклатуры.';
									|pl = 'Dynamika faktycznego wykonania planu w przekroju magazynów i produktów.';
									|tr = 'Ambarlar ve öğe bağlamında fiilî plan yürütme dinamikleri.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ExecutionOfSalesPlanByStoreFormats");
	OptionDetails.LongDesc = NStr("vi = 'Biến động thực hiện thực tế so với kế hoạch theo từng khuôn dạng cửa hàng.';
									|ru = 'Динамика фактического исполнения плана в разрезе формата магазинов.';
									|en = 'Monitor plan fulfillment by retail formats.'; fa = 'Monitor plan fulfillment by retail formats.';
									|it = 'Динамика фактического исполнения плана в разрезе формата магазинов.';
									|pl = 'Dynamika faktycznego wykonania planu w kontekście formatu sklepów.';
									|tr = 'Mağaza formatı bağlamında fiilî plan yürütme dinamikleri.'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
