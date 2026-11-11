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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.GoodsPlacementInBinLocationWarehouse);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Nhà kho nào vẫn còn chỗ trống (trống hoặc chưa được xếp đầy hàng hóa)?';
									|ru = 'Какие складские помещения простаивают (пусты или заполнены недостаточно)?';
									|en = 'Which warerooms are out of action (empty or not full enough)?'; fa = 'Which warerooms are out of action (empty or not full enough)?';
									|it = 'Какие складские помещения простаивают (пусты или заполнены недостаточно)?';
									|pl = 'Jakie pomieszczenia magazynowe mają przestoje (puste lub zapełnione niedostatecznie)?';
									|tr = 'Hangi depolar kullanım dışındadır (boş veya eksik dolduruldu)?'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "GoodsPlacementInBinLocationWarehouse");
	OptionDetails.LongDesc = NStr("vi = 'Những nhà kho nào vẫn còn chỗ trống (trống hoặc chưa được xếp đầy hàng hóa)?
		|Những khu vực nào đã đầy và cần mở rộng?';
		|ru = 'Какие складские помещения простаивают (пусты или заполнены недостаточно)?
		|Какие области переполнены и требуют расширения?';
		|en = 'Check which warerooms are out of action (empty or not full enough).
		|Verify which areas are overloaded and require extension.'; fa = 'Check which warerooms are out of action (empty or not full enough).
		|Verify which areas are overloaded and require extension.';
		|it = 'Какие складские помещения простаивают (пусты или заполнены недостаточно)?
		|Какие области переполнены и требуют расширения?';
		|pl = 'Jakie pomieszczenia magazynowe mają przestoje (puste lub zapełnione niedostatecznie)?
		| Jakie obszare są przepełnione i wymagają rozszerzenia?';
		|tr = 'Hangi depolar kullanım dışındadır (boş veya eksik dolduruldu)?
		|Hangi alanlar aşırı yüklü ve genişletme gerektiriyor?'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
