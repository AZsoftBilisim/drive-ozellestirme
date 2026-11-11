
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	AssetRef = Parameters.DefaultValue;
	Items.AssetRef.ChoiceParameters = Parameters.ArticleItemSelectionOptions;
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "";
	ChoiceParameters.AssetRef = "AssetRef";
	ChoiceParameters.ArticleType = "ArticleType";
	ChoiceParameters.DefaultValue = Parameters.DefaultValue;
	
	ChoiceParameters.ChoosingExpenseItem = Parameters.ChoosingExpenseItem;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	ChoiceParameters.ChoosingIncomeItem  = Parameters.ChoosingIncomeItem;
	ChoiceParameters.DimensionOfRevenue = "DimensionOfRevenue";
	ChoiceParameters.SelectingItemOfAssetsLiabilities = Parameters.SelectingItemOfAssetsLiabilities;
	ChoiceParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesDimension";
	
	ChoiceParameters.FormItems.AssetRef.Add("AssetRef");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DimensionOfExpenses");
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("DimensionOfRevenue");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("AssetsLiabilitiesDimension");
	
	IncomeAndExpensesServer.OnCreateAtServer(ThisForm, ChoiceParameters);
	
EndProcedure

#EndRegion


#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AssetRefStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisForm, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure AssetRefOnChange(Item)
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisForm, Item);
EndProcedure

&AtClient
Procedure DimensionOfExpensesOnChange(Item)
	IncomeAndExpensesClientServer.DimensionOfExpensesOnChange(ThisForm, Item);
EndProcedure

&AtClient
Procedure DimensionOfRevenueOnChange(Item)
	IncomeAndExpensesClientServer.DimensionOfRevenueOnChange(ThisForm, Item);
EndProcedure

&AtClient
Procedure AssetsLiabilitiesDimensionOnChange(Item)
	IncomeAndExpensesClientServer.AssetsLiabilitiesDimensionOnChange(ThisForm, Item);
EndProcedure

&AtClient
Procedure DimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisForm, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure DimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisForm, Item, Text, ChoiceData, Parameters, StandardProcessing);
EndProcedure

&AtClient
Procedure DimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisForm, Item, Text, ChoiceData, Parameters, StandardProcessing);
EndProcedure

#EndRegion

#Region CommandHandlers

&AtClient
Procedure Select(Command)
	
	ClearMessages();
	
	If CheckFilling() Then
		Result = New Structure();
		Result.Insert("AssetRef", AssetRef);
		Result.Insert("DimensionOfExpenses",        DimensionOfExpenses);
		Result.Insert("DimensionOfRevenue",         DimensionOfRevenue);
		Result.Insert("AssetsLiabilitiesDimension", AssetsLiabilitiesDimension);
		NotifyChoice(Result);
	EndIf;
	
EndProcedure


#EndRegion

