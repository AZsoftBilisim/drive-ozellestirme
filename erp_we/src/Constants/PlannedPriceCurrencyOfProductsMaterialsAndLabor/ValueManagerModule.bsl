#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

// Throws an exception with the error text in cases where the constant is required but not enabled.
//
Procedure ReportConstantNotFilledAndRaiseException() Export
	
	ExceptionText = NStr("vi = 'Chưa đặt tiền tệ giá vốn dự tính của mặt hàng. Tiền tệ được thiết lập trong menu ""Danh mục và quản trị"" - ""Sản xuất"".';
						|ru = 'Не задана валюта плановой себестоимости продукции. Валюта устанавливается в разделе ""НСИ и администрирование"" - ""Производство"".';
						|en = 'Standard product cost currency is not specified. The currency is set in section ""Master data and settings"" - ""Manufacturing"".'; fa = 'Standard product cost currency is not specified. The currency is set in section ""Master data and settings"" - ""Manufacturing"".';
						|it = 'La valuta del costo di produzione pianificato non è specificata. La valuta è impostata nella sezione ""Dati principali e amministrazione"" - ""Produzione""';
						|pl = 'Waluta planowanych kosztów produkcji nie została określona. Waluta jest określona w sekcji ""Normatywne informacje i administracja"" - ""Produkcja"".';
						|tr = 'Planlanan imal edilen ürünler maliyetinin para birimi ayarlanmadı. Para birimi ""Master veri ve yönetim"" - ""Üretim"" bölümünde ayarlanır.'");
	Raise ExceptionText;
	
EndProcedure

#EndRegion

#EndIf