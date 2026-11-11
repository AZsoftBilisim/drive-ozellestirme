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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ProductionOperationParameters);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Giá trị của tham số giao dịch sản xuất có chênh lệch so với tiêu chuẩn.';
									|ru = 'Значения параметров производственных операций с отклонениями от нормативов.';
									|en = 'Production operation parameter values with variances from standards.'; fa = 'Production operation parameter values with variances from standards.';
									|it = 'Значения параметров производственных операций с отклонениями от нормативов.';
									|pl = 'Wartości parametrów operacji produkcyjnych z odchyleniami od normatywów.';
									|tr = 'Standartlardan sapmalar ile üretim operasyonlarının parametrelerinin değerleri.'");
	OptionDetails.FunctionalOptions.Add("UseManufacturingExecutionSystem");
	OptionDetails.FunctionalOptions.Add("UseOperationManagement");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
