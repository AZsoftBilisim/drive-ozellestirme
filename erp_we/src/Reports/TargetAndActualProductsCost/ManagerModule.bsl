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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.TargetAndActualProductsCost);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "PlannedActualCost");
	OptionDetails.LongDesc = NStr("vi = 'Các chi phí theo kế hoạch và thực tế của thành phẩm xuất xưởng theo từng dạng chi phí là gì?';
									|ru = 'Каковы плановые и фактические затраты по выпущенной продукции в разрезе видов затрат?';
									|en = 'Verify the planned and actual costs for the released products by cost kinds.'; fa = 'Verify the planned and actual costs for the released products by cost kinds.';
									|it = 'Каковы плановые и фактические затраты по выпущенной продукции в разрезе видов затрат?';
									|pl = 'Jakie są planowe i faktyczne wydatki według wypuszczonej produkcji w przekroju rodzajów wydatków?';
									|tr = 'Gider türüne göre üretilen ürünler için planlanan ve gerçekleşen maliyetler nelerdir?'");
	OptionDetails.FunctionalOptions.Add("UseProductionManagement2_2");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
