//@strict-types

#Region Public

// This procedure is used to set parameters for selecting the expenditure item of the research and development Agency.
//
// Parameters:
//	Item - FormField - the element for which the selection parameters are set:
//	*ChoiceParameters - FixedArray -
//	RecognitionType - EnumRef.RDExpenseRecognitionTypes, Undefined - type of expense recognition
//
Procedure SetParametersForSelectingExpenseItem(Item, RecognitionType = Undefined) Export
	
	ItemsAC = New Array();
	ItemsAC.Add("DistributionOfTheCompletionOfTheStageCostItemOfTheBU");
	ItemsAC.Add("DistributionByResearchItemOfExpenditureOfTheBU");
	ItemsAC.Add("ItemOfExpenditureForTheCompletionOfTheStage");
	ItemsAC.Add("ItemOfExpenditureOfTheBUPoResearch");
	
	ItemsTA = New Array();
	ItemsTA.Add("DistributionOfStageCompletionItemOfExpenditureNU");
	ItemsTA.Add("DistributionByResearchExpenditureItemTA");
	ItemsTA.Add("ItemOfExpenditureNuseachievementOfTheStage");
	ItemsTA.Add("TAExpenditureItemForResearch");

	ItemsMA = New Array();
	ItemsMA.Add("DistributionOfTheCompletionOfTheStageItemOfExpenditureOfTheUU");
	ItemsMA.Add("DistributionByResearchItemOfExpenditureOfTheUU");
	ItemsMA.Add("ItemOfExpenditureAtTheEndOfTheStage");
	ItemsMA.Add("ItemOfExpenditureOfTheUUPoForResearch");
	
	ArticleSelectionParameters = New Array();

	If RecognitionType = PredefinedValue("Enum.RDExpenseRecognitionTypes.RecognitionAsIntangibleAssets") Then
		ArticleSelectionParameters.Add(New ChoiceParameter("Filter.CostAllocationOptionLocal", PredefinedValue("Enum.CostAllocationOptions.ToNonCurrentAssetCost")));
		ArticleSelectionParameters.Add(New ChoiceParameter("Filter.IntangibleAssetsAndRDExpenses", True));
		ArticleSelectionParameters.Add(New ChoiceParameter("Filter.ResearchAndDevelopmentExpenses", False));
	ElsIf RecognitionType = PredefinedValue("Enum.RDExpenseRecognitionTypes.MoveToAnotherTheme") Then
		ArticleSelectionParameters.Add(New ChoiceParameter("Filter.ResearchAndDevelopmentExpenses", True));
	ElsIf RecognitionType = PredefinedValue("Enum.RDExpenseRecognitionTypes.IncludeInProductionCosts") Then
		DistributionOptions = New Array;
		DistributionOptions.Add(PredefinedValue("Enum.CostAllocationOptions.ToProductionCostDirect"));
		DistributionOptions.Add(PredefinedValue("Enum.CostAllocationOptions.ToProductionCosts"));
		If ItemsAC.Find(Item.Name) <> Undefined Then
			ArticleSelectionParameters.Add(New ChoiceParameter("Filter.CostAllocationOptionLocal", DistributionOptions));
		ElsIf ItemsTA.Find(Item.Name) <> Undefined Then
			ArticleSelectionParameters.Add(New ChoiceParameter("Filter.CostAllocationOptionTax", DistributionOptions));
		ElsIf ItemsMA.Find(Item.Name) <> Undefined Then
			ArticleSelectionParameters.Add(New ChoiceParameter("Filter.CostAllocationOptionManag", DistributionOptions));
		EndIf;
	ElsIf RecognitionType = PredefinedValue("Enum.RDExpenseRecognitionTypes.CloseTopic") Then
		ExpenseActivityTypes = New Array();
		ExpenseActivityTypes.Add(PredefinedValue("Enum.ExpenseActivityTypes.CoreAndOtherActivity"));
		ExpenseActivityTypes.Add(PredefinedValue("Enum.ExpenseActivityTypes.OtherActivity"));
		ArticleSelectionParameters.Add(New ChoiceParameter("Filter.ExpenseTypeCategory", ExpenseActivityTypes));
	ElsIf RecognitionType = PredefinedValue("Enum.RDExpenseRecognitionTypes.RecognitionAsDeferredExpenses") Then
		ExpenseActivityTypes = New Array();
		ExpenseActivityTypes.Add(PredefinedValue("Enum.ExpenseActivityTypes.CoreActivity"));
		ArticleSelectionParameters.Add(New ChoiceParameter("Filter.ExpenseTypeCategory", ExpenseActivityTypes));
		ArticleSelectionParameters.Add(New ChoiceParameter("Filter.CostAllocationOptionLocal", PredefinedValue("Enum.CostAllocationOptions.ToDeferredExpenses")));
	Else
		DistributionOptions = New Array;
		DistributionOptions.Add(PredefinedValue("Enum.CostAllocationOptions.ToLinesOfBusiness"));
		DistributionOptions.Add(PredefinedValue("Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly"));
		ArticleSelectionParameters.Add(New ChoiceParameter("Filter.CostAllocationOptionLocal", DistributionOptions));
	EndIf;

	Item.ChoiceParameters = New FixedArray(ArticleSelectionParameters);
	
EndProcedure

#EndRegion 