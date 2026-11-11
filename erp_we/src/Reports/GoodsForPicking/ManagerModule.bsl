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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.GoodsForPicking);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích trạng thái lựa chọn hàng hóa từ các ô hàng';
									|ru = 'Анализ состояния выполнения отбора товаров из складских ячеек';
									|en = 'Analysis of the state of the selection of goods from storage bins'; fa = 'Analysis of the state of the selection of goods from storage bins';
									|it = 'Анализ состояния выполнения отбора товаров из складских ячеек';
									|pl = 'Analiza stanu wykonania wyboru towarów z komórek magazynowych';
									|tr = 'Ambar hücrelerinden ürün filtre durumunun analizi'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "PerformingSelectionOfGoodsByWarehouseContext");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích trạng thái lựa chọn hàng hóa từ các ô hàng';
									|ru = 'Анализ состояния выполнения отбора товаров из складских ячеек';
									|en = 'Analysis of the state of the selection of goods from storage bins'; fa = 'Analysis of the state of the selection of goods from storage bins';
									|it = 'Анализ состояния выполнения отбора товаров из складских ячеек';
									|pl = 'Analiza stanu wykonania wyboru towarów z komórek magazynowych';
									|tr = 'Ambar hücrelerinden ürün filtre durumunun analizi'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
