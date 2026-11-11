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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.FulfillmentOfProcurementPlan);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Đánh giá trạng thái thực tế mua hàng theo sơ đồ.
		|Những đơn hàng nào đặt nhà cung cấp vẫn chưa được tiếp nhận vào kho?';
		|ru = 'Оценка фактического состояния закупок товаров по плану.
		|Какие заказы поставщикам еще не поступили на склад?';
		|en = 'Evaluate actual state of goods purchase according to the plan.
		|Check which purchase orders have not been delivered to the warehouse yet.'; fa = 'Evaluate actual state of goods purchase according to the plan.
		|Check which purchase orders have not been delivered to the warehouse yet.';
		|it = 'Оценка фактического состояния закупок товаров по плану.
		|Какие заказы поставщикам еще не поступили на склад?';
		|pl = 'Ocena faktycznego statusu zakupów towarów według planu. 
		|Jakie zamówienia zakupu jeszcze nie wpłynęły do magazynu?';
		|tr = 'Plana göre ürün alımlarının fiilî durumunun değerlendirilmesi.
		|Hangi satın alma siparişleri henüz ambara ulaşmadı?'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "PurchasePlanFulfillmentByDepartments");
	OptionDetails.LongDesc = NStr("vi = 'Biến động thực hiện kế hoạch trên thực tế theo từng bộ phận và mặt hàng.';
									|ru = 'Динамика фактического исполнения плана в разрезе подразделений и номенклатуры.';
									|en = 'Monitor plan fulfillment by business units and items.'; fa = 'Monitor plan fulfillment by business units and items.';
									|it = 'Динамика фактического исполнения плана в разрезе подразделений и номенклатуры.';
									|pl = 'Dynamika faktycznego wykonania planu w przekroju działów i produktów.';
									|tr = 'Departman ve öğe bağlamında fiilî plan yürütme dinamikleri.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "PurchasePlanFulfillmentBySuppliers");
	OptionDetails.LongDesc = NStr("vi = 'Biến động thực hiện thực tế so với kế hoạch theo từng nhà cung cấp và mặt hàng.';
									|ru = 'Динамика фактического исполнения плана в разрезе поставщиков и номенклатуры.';
									|en = 'Monitor plan fulfillment by vendors and by items.'; fa = 'Monitor plan fulfillment by vendors and by items.';
									|it = 'Динамика фактического исполнения плана в разрезе поставщиков и номенклатуры.';
									|pl = 'Dynamika faktycznego wykonania planu w przekroju dostawców i produktów.';
									|tr = 'Tedarikçiler ve öğe bağlamında fiilî plan yürütme dinamikleri.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "PurchasePlanFulfillmentByWarehouses");
	OptionDetails.LongDesc = NStr("vi = 'Biến động thực hiện thực tế so với kế hoạch theo từng kho bãi và mặt hàng.';
									|ru = 'Динамика фактического исполнения плана в разрезе складов и номенклатуры.';
									|en = 'Monitor plan fulfillment by warehouses and items.'; fa = 'Monitor plan fulfillment by warehouses and items.';
									|it = 'Динамика фактического исполнения плана в разрезе складов и номенклатуры.';
									|pl = 'Dynamika faktycznego wykonania planu w przekroju magazynów i produktów.';
									|tr = 'Ambarlar ve öğe bağlamında fiilî plan yürütme dinamikleri.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "PaymentPlanFulfillmentBySuppliers");
	OptionDetails.LongDesc = NStr("vi = 'Kiểm tra việc thực hiện kế hoạch theo chi phí thực tế.
		|Kế hoạch và thực tế giao hàng từ nhà cung cấp trong kỳ.';
		|ru = 'Проверка исполнения плана по фактическому расходу денежных средств.
		|План и факт поставок от поставщика за период.';
		|en = 'Check payment plan fulfillment against actual cash outflow.
		|View planned and actual shipments from the vendor over the period.'; fa = 'Check payment plan fulfillment against actual cash outflow.
		|View planned and actual shipments from the vendor over the period.';
		|it = 'Проверка исполнения плана по фактическому расходу денежных средств.
		|План и факт поставок от поставщика за период.';
		|pl = 'Weryfikacja wykonania planu według faktycznego rozchodu środków pieniężnych. 
		|Plan i fakt dostaw od dostawców za okres.';
		|tr = 'Fiili nakit çıkışına göre ödeme planının yerine getirilip getirilmediğini kontrol edin.
		|Plan ve dönem için tedarikçiden yapılan teslimatların durumu.'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
