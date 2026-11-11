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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.FulfillmentOfInventoryConsumptionPlan);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Đánh giá trạng thái thực tế tiêu dùng hàng hóa nội bộ theo kế hoạch.
		|Những đơn hàng tiêu dùng nội bộ nào vẫn chưa được giao khỏi kho?';
		|ru = 'Оценка фактического состояния внутренних потреблений товаров по плану.
		|Какие заказы на внутреннее потребление еще не отгружены со склада?';
		|en = 'Evaluate actual state of inventory consumption according to the plan.
		|Check which inventory consumption orders have not been shipped from the warehouse yet.'; fa = 'Evaluate actual state of inventory consumption according to the plan.
		|Check which inventory consumption orders have not been shipped from the warehouse yet.';
		|it = 'Оценка фактического состояния внутренних потреблений товаров по плану.
		|Какие заказы на внутреннее потребление еще не отгружены со склада?';
		|pl = 'Ocena faktycznego statusu sprzedaży towarów konsumpcji wewnętrznych według planu. 
		|Jakie zamówienia klientów jeszcze nie są wysłane z magazynu?';
		|tr = 'Plana göre stok tüketiminin gerçek durumunun değerlendirilmesi.
		|Hangi stok tüketim siparişleri henüz ambardan sevk edilmedi?'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ExecutionOfInternalConsumptionPlanByDivisions");
	OptionDetails.LongDesc = NStr("vi = 'Biến động thực hiện kế hoạch trên thực tế theo từng bộ phận và mặt hàng.';
									|ru = 'Динамика фактического исполнения плана в разрезе подразделений и номенклатуры.';
									|en = 'Monitor plan fulfillment by business units and items.'; fa = 'Monitor plan fulfillment by business units and items.';
									|it = 'Динамика фактического исполнения плана в разрезе подразделений и номенклатуры.';
									|pl = 'Dynamika faktycznego wykonania planu w przekroju działów i produktów.';
									|tr = 'Departmanlar ve öğe bağlamında fiilî plan yürütme dinamikleri.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ExecutionOfPlanOfInternalConsumptionByWarehouses");
	OptionDetails.LongDesc = NStr("vi = 'Biến động thực hiện thực tế so với kế hoạch theo từng kho bãi và mặt hàng.';
									|ru = 'Динамика фактического исполнения плана в разрезе складов и номенклатуры.';
									|en = 'Monitor plan fulfillment by warehouses and items.'; fa = 'Monitor plan fulfillment by warehouses and items.';
									|it = 'Динамика фактического исполнения плана в разрезе складов и номенклатуры.';
									|pl = 'Dynamika faktycznego wykonania planu w przekroju magazynów i produktów.';
									|tr = 'Ambarlar ve öğe bağlamında fiilî plan yürütme dinamikleri.'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
