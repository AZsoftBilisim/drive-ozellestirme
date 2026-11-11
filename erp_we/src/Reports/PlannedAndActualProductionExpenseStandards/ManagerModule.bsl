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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.PlannedAndActualProductionExpenseStandards);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Định mức chi phí sản xuất theo kế hoạch và thực tế.';
									|ru = 'Плановые и фактические нормативы производственных расходов.';
									|en = 'Standard and actual production overheads.'; fa = 'Standard and actual production overheads.';
									|it = 'Плановые и фактические нормативы производственных расходов.';
									|pl = 'Planowe i faktyczne normatywy wydatków produkcyjnych.';
									|tr = 'Standart ve gerçek üretim maliyetleri.'");
											
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "PlannedAndActualProductionExpenseStandards");
	OptionDetails.LongDesc = NStr("vi = 'Định mức chi phí sản xuất theo kế hoạch và thực tế.';
									|ru = 'Плановые и фактические нормативы производственных расходов.';
									|en = 'Standard and actual production overheads.'; fa = 'Standard and actual production overheads.';
									|it = 'Плановые и фактические нормативы производственных расходов.';
									|pl = 'Planowe i faktyczne normatywy wydatków produkcyjnych.';
									|tr = 'Standart ve gerçek üretim maliyetleri.'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
