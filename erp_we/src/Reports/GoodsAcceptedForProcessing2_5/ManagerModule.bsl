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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.GoodsAcceptedForProcessing2_5);
	DescriptionOfReport.DefineFormSettings = True;
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích biến động hàng hóa được tiếp nhận để gia công theo các giao dịch.
									|Bao nhiêu sản phẩm đã được tiếp nhận, sản xuất, tiêu dùng, chuyển giao, ghi giảm, mua lại?
									|Bao nhiêu sản phẩm cần ghi giảm, mua lại?
									|Theo mục nào, cần tạo bảng kê dành cho người đặt gia công?';
									|ru = 'Анализ движения товаров, принятых в переработку, по операциям.
									|Сколько было принято, произведено, израсходовано, передано, списано, выкуплено?
									|Сколько необходимо списать, выкупить?
									|По каким позициям необходимо оформить отчеты давальцу?';
									|en = 'Analyze transfers of goods received for subcontracting by operations.
									|Check how many goods were received, produced, spent, transferred, adjusted, and redeemed.
									|Check how many goods you need to adjust and redeem.
									|Specify items to register ""Consumption reports — Subcontracting services delivered"".'; fa = 'Analyze transfers of goods received for subcontracting by operations.
									|Check how many goods were received, produced, spent, transferred, adjusted, and redeemed.
									|Check how many goods you need to adjust and redeem.
									|Specify items to register ""Consumption reports — Subcontracting services delivered"".';
									|it = 'Анализ движения товаров, принятых в переработку, по операциям.
									|Сколько было принято, произведено, израсходовано, передано, списано, выкуплено?
									|Сколько необходимо списать, выкупить?
									|По каким позициям необходимо оформить отчеты давальцу?';
									|pl = 'Analiza przepływu towarów, przyjętych do przetworzenia, według operacji.
									|Ile zostało przyjęte, wyprodukowano, zużyto, przekazano, wykupiono?
									|Ile należy rozchodować, wykupić?
									|Według jakich pozycji należy utworzyć raporty do właścicieli surowyców?';
									|tr = 'İşlemlere göre işlenmek üzere kabul edilen ürünlerin hareketinin analizi.
									|Ne kadarı kabul edildi, ne kadarı üretildi, ne kadarı harcandı, transfer edildi, ne kadarı kayıttan düşüldü, ne kadarı itfa edildi?
									|Ne kadarı kayıtta düşülmeli, itfa edilmelidir?
									|Hangi pozisyonlar için ""Tüketim raporları - Verilen fason hizmetleri"" düzenlemek gerekir?'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "GoodsAcceptedForProcessing");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích biến động hàng hóa được tiếp nhận để gia công theo các giao dịch.
									|Bao nhiêu sản phẩm đã được tiếp nhận, sản xuất, tiêu dùng, chuyển giao, ghi giảm, mua lại?
									|Bao nhiêu sản phẩm cần ghi giảm, mua lại?
									|Theo mục nào, cần tạo bảng kê dành cho người đặt gia công?';
									|ru = 'Анализ движения товаров, принятых в переработку, по операциям.
									|Сколько было принято, произведено, израсходовано, передано, списано, выкуплено?
									|Сколько необходимо списать, выкупить?
									|По каким позициям необходимо оформить отчеты давальцу?';
									|en = 'Analyze transfers of goods received for subcontracting by operations.
									|Check how many goods were received, produced, spent, transferred, adjusted, and redeemed.
									|Check how many goods you need to adjust and redeem.
									|Specify items to register ""Consumption reports — Subcontracting services delivered"".'; fa = 'Analyze transfers of goods received for subcontracting by operations.
									|Check how many goods were received, produced, spent, transferred, adjusted, and redeemed.
									|Check how many goods you need to adjust and redeem.
									|Specify items to register ""Consumption reports — Subcontracting services delivered"".';
									|it = 'Анализ движения товаров, принятых в переработку, по операциям.
									|Сколько было принято, произведено, израсходовано, передано, списано, выкуплено?
									|Сколько необходимо списать, выкупить?
									|По каким позициям необходимо оформить отчеты давальцу?';
									|pl = 'Analiza przepływu towarów, przyjętych do przetworzenia, według operacji.
									|Ile zostało przyjęte, wyprodukowano, zużyto, przekazano, wykupiono?
									|Ile należy rozchodować, wykupić?
									|Według jakich pozycji należy utworzyć raporty do właścicieli surowyców?';
									|tr = 'İşlemlere göre işlenmek üzere kabul edilen ürünlerin hareketinin analizi.
									|Ne kadarı kabul edildi, ne kadarı üretildi, ne kadarı harcandı, transfer edildi, ne kadarı kayıttan düşüldü, ne kadarı itfa edildi?
									|Ne kadarı kayıtta düşülmeli, itfa edilmelidir?
									|Hangi pozisyonlar için ""Tüketim raporları - Verilen fason hizmetleri"" düzenlemek gerekir?'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
