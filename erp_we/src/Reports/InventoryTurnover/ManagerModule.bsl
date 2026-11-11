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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.InventoryTurnover);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Tốc độ quay vòng hàng hóa như thế nào?';
									|ru = 'Какая оборачиваемость у товаров?';
									|en = 'What is the goods turnover?'; fa = 'What is the goods turnover?';
									|it = 'Какая оборачиваемость у товаров?';
									|pl = 'Jaki jest obrót towarów?';
									|tr = 'Ürünlerin cirosu nedir?'");
	TMReportOptionsOverridable.SetImportanceOfReportOption(OptionDetails, "Important");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "InventoryTurnover");
	OptionDetails.LongDesc = NStr("vi = 'Trong các kho nào có tốc độ quay vòng hàng hóa thấp?
		|Số dư hiện tại và mức vật tư của mặt hàng được ưa thích là bao nhiêu?';
		|ru = 'На каких складах оборачиваемость товаров низкая?
		|Каковы текущие остатки и уровень запасов интересующих товаров?';
		|en = 'Check which warehouses have low goods turnover.
		|Verify the current stock balance and its level.'; fa = 'Check which warehouses have low goods turnover.
		|Verify the current stock balance and its level.';
		|it = 'На каких складах оборачиваемость товаров низкая?
		|Каковы текущие остатки и уровень запасов интересующих товаров?';
		|pl = 'W jakich magazynach obrót towarów jest niski? 
		|Jakie są bieżące ostatki i poziom zapasów interesujących towarów?';
		|tr = 'Hangi ambarlarda ürün cirosu düşük?
		|Söz konusu ürünün cari bakiyeleri ve stok seviyeleri nedir?'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
