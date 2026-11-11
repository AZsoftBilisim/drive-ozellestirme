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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ProductionPlanFulfillment);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Đã thực hiện kế hoạch sản xuất chưa?
		|Kế hoạch đã thực hiện theo thực tế như thế nào?';
		|ru = 'Выполнен ли план производства?
		|Насколько выполнен по факту?';
		|en = 'Is the production plan fulfilled? 
		|To what extent is it actually fulfilled?'; fa = 'Is the production plan fulfilled? 
		|To what extent is it actually fulfilled?';
		|it = 'Выполнен ли план производства?
		|Насколько выполнен по факту?';
		|pl = 'Czy jest wykonany plan produkcji? 
		|Na ile jest wykonany faktycznie?';
		|tr = 'Üretim planı tamamlandı mı?
		|Fiilî olarak ne kadarı tamamlandı?'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ProductionPlanFulfillment");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ProductionPlanFulfillmentByDepartments");
	OptionDetails.Enabled = False;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ProductionPlanFulfillmentByDepartments");
	OptionDetails.Enabled = True;
	OptionDetails.LongDesc = NStr("vi = 'Đánh giá trạng thái thực tế sản xuất sản phẩm theo kế hoạch.
		|Còn chưa tiếp nhận những đơn hàng nào vào kho?';
		|ru = 'Оценка фактического состояния производства продукции по плану.
		|Какие заказы на производство еще не поступили на склад?';
		|en = 'Compare actual production plan fulfillment by business units and monitor deviations. 
		|'; fa = 'Compare actual production plan fulfillment by business units and monitor deviations. 
		|';
		|it = 'Оценка фактического состояния производства продукции по плану.
		|Какие заказы на производство еще не поступили на склад?';
		|pl = 'Ocena faktycznego stanu wyprodukowania produkcji według planu. 
		|Jakie zlecenia produkcyjne jeszcze nie wpłynęły do magazynu?';
		|tr = 'Plana göre fiilî üretim durumunun değerlendirilmesi.
		|Hangi üretim emirleri henüz ambara ulaşmadı?'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
