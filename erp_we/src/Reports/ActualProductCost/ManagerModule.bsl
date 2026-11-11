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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ActualProductCost);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ActualCostOfProductionOfEnterprise");
	OptionDetails.LongDesc = NStr("vi = 'Chi phí thực tế đối với thành phẩm xuất xưởng của doanh nghiệp là bao nhiêu?';
									|ru = 'Каковы фактические затраты по выпущенной продукции предприятия?';
									|en = 'Verify the actual costs for the released enterprise products.'; fa = 'Verify the actual costs for the released enterprise products.';
									|it = 'Каковы фактические затраты по выпущенной продукции предприятия?';
									|pl = 'Jakie są faktyczne koszty dotyczące wypuszczonej produkcji przedsiębiorstwa?';
									|tr = 'İşletmenin imal edilen ürün üretiminin fiilî giderleri nelerdir?'");	
	OptionDetails.FunctionalOptions.Add("UseProductionManagement2_2");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ActualCostOfProductionOfOrganization");
	OptionDetails.LongDesc = NStr("vi = 'Chi phí thực tế đối với thành phẩm xuất xưởng của doanh nghiệp là bao nhiêu?';
									|ru = 'Каковы фактические затраты по выпущенной продукции организации?';
									|en = 'Verify the actual costs for the released company products.'; fa = 'Verify the actual costs for the released company products.';
									|it = 'Каковы фактические затраты по выпущенной продукции организации?';
									|pl = 'Jakie są faktyczne koszty dotyczące wypuszczonej produkcji firmy?';
									|tr = 'İş yerinin imal edilen ürün çıkışının fiilî giderleri nelerdir?'");	
	OptionDetails.FunctionalOptions.Add("UseProductionManagement2_2");
	OptionDetails.FunctionalOptions.Add("UseProductionByThirdParty2_5");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ActualCostOfProductionContext");
	OptionDetails.FunctionalOptions.Add("UseProductionManagement2_2");
	OptionDetails.FunctionalOptions.Add("UseProductionByThirdParty2_5");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ActualCostOfProductionContext");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ActualCostOfProductionReportToGiver");
	OptionDetails.FunctionalOptions.Add("UseProductionManagement2_2");
	OptionDetails.FunctionalOptions.Add("UseProductionByThirdParty2_5");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ActualCostOfProductionReportToGiver");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
