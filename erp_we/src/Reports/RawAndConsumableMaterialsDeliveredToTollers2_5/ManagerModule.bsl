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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.RawAndConsumableMaterialsDeliveredToTollers2_5);
	DescriptionOfReport.DefineFormSettings = True;
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích bản ghi kết chuyển của hàng hóa đã chuyển cho người nhận gia công theo các giao dịch.
									|Bao nhiêu sản phẩm đã được chuyển giao, sản xuất, tiêu thụ, chuyển giao vào kho, ghi giảm?';
									|ru = 'Анализ движения товаров, переданных переработчикам, по операциям.
									|Сколько было передано, произведено, израсходовано, передано на склад, списано?';
									|en = 'Analyze transfers of goods transferred to subcontractors by operations.
									|Check how many goods were transferred, produced, spent, transferred to the warehouse, and adjusted.'; fa = 'Analyze transfers of goods transferred to subcontractors by operations.
									|Check how many goods were transferred, produced, spent, transferred to the warehouse, and adjusted.';
									|it = 'Анализ движения товаров, переданных переработчикам, по операциям.
									|Сколько было передано, произведено, израсходовано, передано на склад, списано?';
									|pl = 'Analiza przepływu towarów, przekazanych przetwórcom, według operacji.
									|Ile zostało przekazano, wyprodukowano, zużyto, przekazano do magazynu, spisane?';
									|tr = 'заказ переработчикFason üreticilere işleme göre aktarılan ürünlerin hareketinin analizi.
									|Ne kadarı transfer edildi, ne kadarı üretildi, ne kadarı tüketildi, ne kadarı ambara transfer edildi, ne kadarı silindi?'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "RawAndConsumableMaterialsDeliveredToTollers");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích bản ghi kết chuyển của hàng hóa đã chuyển cho người nhận gia công theo các giao dịch.
									|Bao nhiêu sản phẩm đã được chuyển giao, sản xuất, tiêu thụ, chuyển giao vào kho, ghi giảm?';
									|ru = 'Анализ движения товаров, переданных переработчикам, по операциям.
									|Сколько было передано, произведено, израсходовано, передано на склад, списано?';
									|en = 'Analyze transfers of goods transferred to subcontractors by operations.
									|Check how many goods were transferred, produced, spent, transferred to the warehouse, and adjusted.'; fa = 'Analyze transfers of goods transferred to subcontractors by operations.
									|Check how many goods were transferred, produced, spent, transferred to the warehouse, and adjusted.';
									|it = 'Анализ движения товаров, переданных переработчикам, по операциям.
									|Сколько было передано, произведено, израсходовано, передано на склад, списано?';
									|pl = 'Analiza przepływu towarów, przekazanych przetwórcom, według operacji.
									|Ile zostało przekazano, wyprodukowano, zużyto, przekazano do magazynu, spisane?';
									|tr = 'заказ переработчикFason üreticilere işleme göre aktarılan ürünlerin hareketinin analizi.
									|Ne kadarı transfer edildi, ne kadarı üretildi, ne kadarı tüketildi, ne kadarı ambara transfer edildi, ne kadarı silindi?'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
