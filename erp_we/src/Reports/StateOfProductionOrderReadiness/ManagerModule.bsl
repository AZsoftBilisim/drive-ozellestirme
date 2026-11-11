#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.StateOfProductionOrderReadiness);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Bức tranh tổng thể về trạng thái thực hiện các đơn hàng.';
									|ru = 'Общая картина состояния выполнения заказов.';
									|en = 'Overall picture of the order fulfillment state.'; fa = 'Overall picture of the order fulfillment state.';
									|it = 'Overall picture of the order fulfillment state.';
									|pl = 'Overall picture of the order fulfillment state.';
									|tr = 'Siparişlerin tamamlanma durumunun genel tablosu.'");
	
	TMReportOptionsOverridable.SetImportanceOfReportOption(OptionDetails, "Important");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "StateOfReadinessByStages");
	OptionDetails.Description = NStr("vi = 'Báo cáo tóm tắt về tình trạng sẵn sàng của các đơn hàng (TOP-5 công đoạn)';
									|ru = 'Сводка о готовности заказов (ТОП-5 этапов)';
									|en = 'Summary of order readiness (TOP 5 stages)'; fa = 'خلاصه آمادگی سفارش (5 مرحله برتر)';
									|it = 'Summary of order readiness (TOP 5 stages)';
									|pl = 'Summary of order readiness (TOP 5 stages)';
									|tr = 'Siparişlerin tamamlanma özeti (İLK 5 aşama)'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "SummaryOfOrderAvailability");
	OptionDetails.Description = NStr("vi = 'Báo cáo tóm tắt về tình trạng sẵn sàng của các đơn hàng theo lĩnh vực hoạt động';
									|ru = 'Сводка о готовности заказов по направлениям деятельности';
									|en = 'Summary of order readiness by line of business'; fa = 'خلاصه آمادگی سفارش بر اساس خط کسب‌وکار';
									|it = 'Summary of order readiness by line of business';
									|pl = 'Summary of order readiness by line of business';
									|tr = 'Faaliyet alanlarına göre siparişlerin tamamlanma özeti'");
	
EndProcedure

#EndRegion

#EndIf