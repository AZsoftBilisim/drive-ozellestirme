#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// Returns:
//   ValueTableRow - new report command.
Function AddReportCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.SalesProfitabilityAssessment2_5) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.SalesProfitabilityAssessment2_5.FullName();
		ReportCommand.Presentation = NStr("vi = 'Đánh giá lợi nhuận bán hàng';
											|ru = 'Оценка рентабельности продажи';
											|en = 'Sales profitability assessment'; fa = 'ارزیابی سودآوری فروش';
											|it = 'Valutazione della redditività della vendita';
											|pl = 'Ocena opłacalności sprzedaży';
											|tr = 'Satışların kârlılık değeri'");
		
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Important";
		
		UseDiscountAdjustmentsInSales = GetFunctionalOption("UseDiscountAdjustmentsInSales");
		UseDiscountsMarkupsInSales = GetFunctionalOption("UseDiscountsMarkupsInSales");
		If Not UseDiscountAdjustmentsInSales
			And Not UseDiscountsMarkupsInSales Then
			VariantKey = "AssessmentOfProfitabilityOfSalesWithoutDiscounts";
		ElsIf UseDiscountAdjustmentsInSales And Not UseDiscountsMarkupsInSales Then
			VariantKey = "EstimateReturnOnSalesOnlyManualDiscountsContext";
		ElsIf Not UseDiscountAdjustmentsInSales And UseDiscountsMarkupsInSales Then
			VariantKey = "AssessingProfitabilityOfSellingOnlyAutoDiscounts";
		Else
			VariantKey = "EvaluationOfReturnOnSalesContext";
		EndIf;
		ReportCommand.VariantKey = VariantKey;
		
		Return ReportCommand;
		
	EndIf;

	Return Undefined;

EndFunction

#EndRegion

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.SalesProfitabilityAssessment2_5);
	DescriptionOfReport.DefineFormSettings = True;
	TMReportOptionsOverridable.DisableReport(DescriptionOfReport);
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf