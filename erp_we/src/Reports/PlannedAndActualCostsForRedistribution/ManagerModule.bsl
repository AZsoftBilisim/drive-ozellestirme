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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.PlannedAndActualCostsForRedistribution);
	DescriptionOfReport.DefineFormSettings = True;
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "PlannedAndActualCostsOfRedistributionOfEnterprise");
	OptionDetails.LongDesc = NStr("vi = 'Chi phí xuất xưởng dự tính và thực tế trong tập đoàn là bao nhiêu?
		|Những đối tượng nào có chênh lệch?';
		|ru = 'Каковы плановые и фактические затраты по выпущенной продукции предприятия?
		|По каким объектам произошли отклонения?';
		|en = 'Check planned and actual costs for the released enterprise products.
		|Verify which objects have variances.'; fa = 'Check planned and actual costs for the released enterprise products.
		|Verify which objects have variances.';
		|it = 'Каковы плановые и фактические затраты по выпущенной продукции предприятия?
		|По каким объектам произошли отклонения?';
		|pl = 'Jakie są planowe i faktyczne wydatki według wypuszczonej produkcji przedsiębiorstwa? 
		|Według jakich obiektów wystąpiły odchylenia?';
		|tr = 'İşletmenin ürettiği imal edilen ürünler için planlanan ve gerçekleşen giderler nelerdir?
		|Hangi nesneler için sapmalar meydana geldi?'");
	OptionDetails.FunctionalOptions.Add("UseProductionManagement2_2");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "PlannedAndActualCostsOfRedistributionOfOrganization");
	OptionDetails.LongDesc = NStr("vi = 'Chi phí xuất xưởng dự tính và thực tế trong tập đoàn là bao nhiêu?
		|Những đối tượng nào có chênh lệch?';
		|ru = 'Каковы плановые и фактические затраты по выпущенной продукции предприятия?
		|По каким объектам произошли отклонения?';
		|en = 'Check planned and actual costs for the released enterprise products.
		|Verify which objects have variances.'; fa = 'Check planned and actual costs for the released enterprise products.
		|Verify which objects have variances.';
		|it = 'Каковы плановые и фактические затраты по выпущенной продукции предприятия?
		|По каким объектам произошли отклонения?';
		|pl = 'Jakie są planowe i faktyczne wydatki według wypuszczonej produkcji przedsiębiorstwa? 
		|Według jakich obiektów wystąpiły odchylenia?';
		|tr = 'İşletmenin ürettiği imal edilen ürünler için planlanan ve gerçekleşen giderler nelerdir?
		|Hangi nesneler için sapmalar meydana geldi?'");
	OptionDetails.FunctionalOptions.Add("UseProductionManagement2_2");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
