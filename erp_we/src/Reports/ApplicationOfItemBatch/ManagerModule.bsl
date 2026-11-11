//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//   UseProduction - Boolean
//
Procedure CustomizeReportOptions(Settings, UseProduction) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ApplicationOfItemBatch);
	DescriptionOfReport.DefineFormSettings = True;
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ApplicationOfItemBatch");
	OptionDetails.FunctionalOptions.Add("AssemblyDisassemblyAndItemsBatchesAreUsed");
	OptionDetails.LongDesc = ?(UseProduction,
									NStr("vi = 'Những mặt hàng nào có sử dụng sê-ri?';
										|ru = 'В каких изделиях использовалась серия номенклатуры?';
										|en = 'Check in which finished products the item batch was used.'; fa = 'Check in which finished products the item batch was used.';
										|it = 'В каких изделиях использовалась серия номенклатуры?';
										|pl = 'W jakich wyrobach była używana seria produktów?';
										|tr = 'Ürün partisi hangi nihai ürünlerde kullanıldı?'"),
									NStr("vi = 'Bộ đóng gói nào có sử dụng sê-ri mặt hàng?';
										|ru = 'В каких комплектах использовалась серия номенклатуры?';
										|en = 'In which kits item batch was used?'; fa = 'In which kits item batch was used?';
										|it = 'В каких комплектах использовалась серия номенклатуры?';
										|pl = 'W jakich kompletach była używana seria produktów?';
										|tr = 'Ürün partisi hangi setlerde kullanıldı?'"));
	
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ApplicationSeriesProductContext");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
