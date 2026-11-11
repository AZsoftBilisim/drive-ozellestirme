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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.PriceList);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Đặt đơn giá nào cho hàng hóa?';
									|ru = 'Какие цены установлены на товары?';
									|en = 'What prices are set for goods?'; fa = 'What prices are set for goods?';
									|it = 'Какие цены установлены на товары?';
									|pl = 'Jakie ceny są ustalone na wiersze pozycji?';
									|tr = 'Ürünler için hangi fiyatlar belirlendi?'");
	OptionDetails.FunctionalOptions.Add("UsePriceManagementSystem20");
	TMReportOptionsOverridable.SetImportanceOfReportOption(OptionDetails, "Important");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "PriceList");
	OptionDetails.LongDesc = NStr("vi = 'Tạo bảng giá theo đơn giá đã chọn, 
		|khi cần thiết chỉ đối với hàng hóa có sẵn.';
		|ru = 'Формирование прайс-листа по выбранным ценам, 
		|при необходимости только товары в наличии.';
		|en = 'Generate price lists by the selected prices,
		|only available goods if required.'; fa = 'Generate price lists by the selected prices,
		|only available goods if required.';
		|it = 'Формирование прайс-листа по выбранным ценам, 
		|при необходимости только товары в наличии.';
		|pl = 'Tworzenie cennika według wybranych cen, 
		|w razie konieczności tylko obecne wiersze pozycji.';
		|tr = 'Seçilen fiyatlarda fiyat listesi oluşturulması, 
		|gerektiğinde sadece stoktaki ürünler.'");
	TMReportOptionsOverridable.SetImportanceOfReportOption(OptionDetails, "Important");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ByProductContext");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "PriceListContext");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
