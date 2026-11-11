#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.AnalysisOfPassingGoodsQualityControl);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Tồn kho hàng hóa đang trong quá trình kiểm soát chất lượng là bao nhiêu?
		|Số lượng hàng hóa đã vượt qua kiểm soát chất lượng thành công là bao nhiêu?
		|Số lượng hàng hóa bị đánh giá là không đạt chất lượng theo kết quả kiểm soát chất lượng là bao nhiêu?';
		|ru = 'Каков остаток товаров на контроле качества?
		|Какое количество товаров успешно прошло контроль качества?
		|Какое количество товаров было признано некачественным по результатам контроля качества?';
		|en = 'What is the balance of goods under quality control?
		|How many goods have successfully passed quality control?
		|How many goods were considered low-quality based on the quality control results?'; fa = 'What is the balance of goods under quality control?
		|How many goods have successfully passed quality control?
		|How many goods were considered low-quality based on the quality control results?';
		|it = 'What is the balance of goods under quality control?
		|How many goods have successfully passed quality control?
		|How many goods were considered low-quality based on the quality control results?';
		|pl = 'What is the balance of goods under quality control?
		|How many goods have successfully passed quality control?
		|How many goods were considered low-quality based on the quality control results?';
		|tr = 'Kalite kontroldeki ürün bakiyesi nedir? 
		| Kaç ürün kalite kontrolünden başarıyla geçti? 
		| Kalite kontrol sonuçlarına göre kaç ürün kalitesiz olarak kabul edildi?'");
	TMReportOptionsOverridable.SetImportanceOfReportOption(OptionDetails, "Important");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf