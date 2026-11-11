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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.AssemblyDisassemblyPlanFulfillment);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Đã thực hiện kế hoạch đóng bộ (tách bộ) chưa?
		|Đã thực hiện kế hoạch theo thực tế như thế nào?';
		|ru = 'Выполнен ли план сборок (разборок)?
		|Насколько выполнен по факту?';
		|en = 'Is the kitting plan fulfilled? 
		|To what extent is it actually fulfilled?'; fa = 'Is the kitting plan fulfilled? 
		|To what extent is it actually fulfilled?';
		|it = 'Выполнен ли план сборок (разборок)?
		|Насколько выполнен по факту?';
		|pl = 'Czy jest wykonany plan montaży (demontaży)? 
		|Na ile jest wykonany faktycznie?';
		|tr = 'Montaj (demontaj) planı tamamlandı mı?
		|Fiilî olarak ne kadar tamamlandı?'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ExecutionOfPlanOfAssemblyDisassemblyByWarehouses");
	OptionDetails.LongDesc = NStr("vi = 'Đánh giá trạng thái thực tế đóng bộ (tách bộ) hàng hóa theo kế hoạch.
									|Những đơn hàng đóng bộ (tách bộ) nào vẫn chưa được tiếp nhận vào kho?';
									|ru = 'Оценка фактического состояния сборки (разборки) товаров по плану.
									|Какие заказы на сборку (разборку) еще не поступили на склад?';
									|en = 'Monitor execution of warehouse kitting plans and identify incomplete operations.'; fa = 'Monitor execution of warehouse kitting plans and identify incomplete operations.';
									|it = 'Оценка фактического состояния сборки (разборки) товаров по плану.
									|Какие заказы на сборку (разборку) еще не поступили на склад?';
									|pl = 'Ocena faktycznego statusu montażu (demontażu) towarów według planu. 
									|Jakie zlecenia na montaż (demontaż) jeszcze nie wpłynęły do magazynu?';
									|tr = 'Plana göre ürünlerin fiilî montaj (demontaj) durumunun değerlendirilmesi.
									|Hangi montaj (demontaj) siparişleri henüz ambara ulaşmadı?'");
	Subsystem = Metadata.FindByFullName("Subsystem.Warehouse.Subsystem.InternalInventoryTransfers");
	OptionDetails.Location.Delete(Subsystem);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
