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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.GoodsForIssue);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích trạng thái của các lệnh giao hàng.';
									|ru = 'Анализ состояний распоряжений на отгрузку.';
									|en = 'Analyze shipment reference states.'; fa = 'Analyze shipment reference states.';
									|it = 'Анализ состояний распоряжений на отгрузку.';
									|pl = 'Analiza statusów zamówień do wysyłki.';
									|tr = 'Sevkiyat siparişlerinin durumunun analizi.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ExecutionOfAssemblyShipmentOfGoods");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích trạng thái của các lệnh giao hàng.';
									|ru = 'Анализ состояний распоряжений на отгрузку.';
									|en = 'Analyze shipment reference states.'; fa = 'Analyze shipment reference states.';
									|it = 'Анализ состояний распоряжений на отгрузку.';
									|pl = 'Analiza statusów zamówień do wysyłki.';
									|tr = 'Sevkiyat siparişlerinin durumunun analizi.'");
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.GoodsForIssue);
	DescriptionOfReport.DefineFormSettings = True;
	TMReportOptionsOverridable.DisableReport(DescriptionOfReport);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
