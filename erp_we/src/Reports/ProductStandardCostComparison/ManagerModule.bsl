#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ProductStandardCostComparison);
	DescriptionOfReport.DefineFormSettings = True;
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ProductStandardCostComparison");
	OptionDetails.LongDesc = NStr("vi = 'Chênh lệch trong chi phí dự tính theo sản phẩm xuất xưởng như thế nào?';
									|ru = 'Какова разница в плановых затратах по выпускаемой продукции?';
									|en = 'What is the difference in planned costs for the released products?'; fa = 'What is the difference in planned costs for the released products?';
									|it = 'What is the difference in planned costs for the released products?';
									|pl = 'What is the difference in planned costs for the released products?';
									|tr = 'İmal edilen ürünler için planlanan giderlerdeki fark nedir?'");
	OptionDetails.FunctionalOptions.Add("UseProductionManagement2_2");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport,
		"ComparisonOfProductStandardCostsByCalculationItems");
	OptionDetails.LongDesc = NStr("vi = 'Chênh lệch trong chi phí dự tính theo dạng tính giá thành và theo sản phẩm xuất xưởng như thế nào?';
									|ru = 'Какова разница в плановых затратах, по статьям калькуляций, по выпускаемой продукции?';
									|en = 'What is the difference in planned costs, by product cost elements, and by released products?'; fa = 'What is the difference in planned costs, by product cost elements, and by released products?';
									|it = 'What is the difference in planned costs, by product cost elements, and by released products?';
									|pl = 'What is the difference in planned costs, by product cost elements, and by released products?';
									|tr = 'Ürün maliyet öğesine ve imal edilen ürünlere göre planlanan giderlerdeki fark nelerdir?'");
	OptionDetails.FunctionalOptions.Add("UseProductionManagement2_2");
	
EndProcedure

#EndRegion

#Region CommandsInReportsSubmenu
// Adds a report command to the list of commands.
// 
// Parameters:
//  ReportsCommands - ValueTable - Description in the report variancereferenceable.Before adding the teamreferences.Teamsreferences
//
// Returns:
// 	ValueTableRow - the added Command is from:
//    *Manager - String -
//    *Presentation - String -
//    *MultipleChoice - Boolean - 
//    *Importance - String -
//    *VariantKey - String -
Function AddReportCommand(ReportsCommands) Export
	
	If AccessRight("View", Metadata.Reports.ProductStandardCostComparison) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Id 			= Metadata.Reports.ProductStandardCostComparison.FullName();
		ReportCommand.Manager				= "Report.ProductStandardCostComparison";
		ReportCommand.Presentation			= NStr("vi = 'So sánh tính giá thành kế hoạch';
													|ru = 'Сравнение плановых калькуляций';
													|en = 'Product standard cost comparison'; fa = 'مقایسه بهای استاندارد محصول';
													|it = 'Product standard cost comparison';
													|pl = 'Product standard cost comparison';
													|tr = 'Standart ürün maliyetlerinin karşılaştırılması'");
		ReportCommand.MultipleChoice		= False;
		ReportCommand.Importance				= "Ordinary";
		ReportCommand.FunctionalOptions	= "UseProductionManagement2_2";
		ReportCommand.WriteMode			= "Post";
		ReportCommand.VariantKey			= "ProductStandardCostComparison";
		ReportCommand.IsNonContextual			= True;
		ReportCommand.FormParameterName		= "CostObjectSelection";
		
		Return ReportCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
