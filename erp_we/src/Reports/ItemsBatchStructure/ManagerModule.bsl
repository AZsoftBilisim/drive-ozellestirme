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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ItemsBatchStructure);
	DescriptionOfReport.DefineFormSettings = True;
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ItemsBatchStructure");
	OptionDetails.FunctionalOptions.Add("AssemblyDisassemblyAndItemsBatchesAreUsed");
	OptionDetails.LongDesc = ?(UseProduction,
									NStr("vi = 'Những số sê-ri nào được sử dụng khi phát hành sê-ri hàng hóa?';
										|ru = 'Какие серии использовались при выпуске серии изделия?';
										|en = 'Check which batches were used to release the item batch.'; fa = 'Check which batches were used to release the item batch.';
										|it = 'Какие серии использовались при выпуске серии изделия?';
										|pl = 'Jakie serie były używane podczas wyprodukowania serii wyrobu?';
										|tr = 'Nihai ürün partisinin üretiminde hangi partiler kullanıldı?'"),
									NStr("vi = 'Những sê-ri nào được sử dụng khi đóng bộ hàng hóa theo sê-ri?';
										|ru = 'Какие серии использовались при сборке серии комплекта?';
										|en = 'Verify which batches were used to assemble the kit batch.'; fa = 'Verify which batches were used to assemble the kit batch.';
										|it = 'Какие серии использовались при сборке серии комплекта?';
										|pl = 'Jakie serie byży używane przy montażu serii kompletu?';
										|tr = 'Set partisinin montajı sırasında hangi partiler kullanıldı?'"));
	
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "SeriesStructureProductContext");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
