#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	StandardProcessing = False;
	
	ArrayOfExcludedValues = New Array;
	ArrayOfExcludedValues.Add(PredefinedValue("Enum.CostAllocationOptions.OnOtherAssets")); // obsolete value.
	
	If Not GetFunctionalOption("UseProduction") Then
		ArrayOfExcludedValues.Add(PredefinedValue("Enum.CostAllocationOptions.ToProductionCosts"));
		ArrayOfExcludedValues.Add(PredefinedValue("Enum.CostAllocationOptions.ToProductionCostDirect"));
	EndIf;
	
	If GetFunctionalOption("BaseVersion") Then
		ArrayOfExcludedValues.Add(PredefinedValue("Enum.CostAllocationOptions.ToDeferredExpenses"));
	EndIf;
	
	If GetFunctionalOption("TradeManagement") Then
		ArrayOfExcludedValues.Add(PredefinedValue("Enum.CostAllocationOptions.ToNonCurrentAssetCost"));
	EndIf;
	
	If Not GetFunctionalOption("UseAccountingByExpenseObjects") Then
		ArrayOfExcludedValues.Add(PredefinedValue("Enum.CostAllocationOptions.ToCostCenters"));
	EndIf;
	
	If Parameters.Property("ExpensesOccur") Then
		If Not (Parameters.ExpensesOccur = Enums.ExpenseTypes.PurchaseOfGoods Or Parameters.ExpensesOccur = Enums.ExpenseTypes.WarehouseStorage) Then
			ArrayOfExcludedValues.Add(PredefinedValue("Enum.CostAllocationOptions.ToInventoryCost"));
		EndIf;
		If Not Parameters.ExpensesOccur = Enums.ExpenseTypes.ManufactureOfProducts Then
			ArrayOfExcludedValues.Add(PredefinedValue("Enum.CostAllocationOptions.ToProductionCostDirect"));
		EndIf;
		If Not Parameters.ExpensesOccur = Enums.ExpenseTypes.SalesOfGoods Then
			ArrayOfExcludedValues.Add(PredefinedValue("Enum.CostAllocationOptions.ToCostOfGoodsSold"));
		EndIf;
		If Not Parameters.ExpensesOccur = Enums.ExpenseTypes.CalculationOfNonCurrentAssetsVAlue Then
			ArrayOfExcludedValues.Add(PredefinedValue("Enum.CostAllocationOptions.ToNonCurrentAssetCost"));
		EndIf;
		If Not (Parameters.ExpensesOccur = Enums.ExpenseTypes.OtherExpenses Or Parameters.ExpensesOccur = Enums.ExpenseTypes.CalculationOfNonCurrentAssetsVAlue) Then
			ArrayOfExcludedValues.Add(PredefinedValue("Enum.CostAllocationOptions.ToProductionCosts"));
		EndIf;
		If Not Parameters.ExpensesOccur = Enums.ExpenseTypes.ExpenseToCostCenters Then
			ArrayOfExcludedValues.Add(PredefinedValue("Enum.CostAllocationOptions.ToCostCenters"));
		EndIf;
	EndIf;
	
	If Parameters.Property("CostAllocationOptionLocal") Then
		If Parameters.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToLinesOfBusiness Or 
				Parameters.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToCurrentPeriodExpensesDirectly Or
				Parameters.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToDeferredExpenses Or 
				Parameters.CostAllocationOptionLocal = Enums.CostAllocationOptions.DoNotAllocate Then
			ArrayOfExcludedValues.Add(PredefinedValue("Enum.CostAllocationOptions.ToCostOfGoodsSold"));
			ArrayOfExcludedValues.Add(PredefinedValue("Enum.CostAllocationOptions.ToCostCenters"));
		EndIf;
		If Parameters.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToLinesOfBusiness Then
			If Parameters.Property("ExpensesOccur") 
				And (Parameters.ExpensesOccur = Enums.ExpenseTypes.PurchaseOfGoods 
					Or Parameters.ExpensesOccur = Enums.ExpenseTypes.WarehouseStorage) 
				Then
				ArrayOfExcludedValues.Add(PredefinedValue("Enum.CostAllocationOptions.DoNotAllocate"));
			EndIf;
		EndIf;
		If Parameters.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToDeferredExpenses Then
			ArrayOfExcludedValues.Add(PredefinedValue("Enum.CostAllocationOptions.ToInventoryCost"));
			ArrayOfExcludedValues.Add(PredefinedValue("Enum.CostAllocationOptions.ToProductionCostDirect"));
		EndIf;
		If Parameters.CostAllocationOptionLocal = Enums.CostAllocationOptions.DoNotAllocate Then
			ArrayOfExcludedValues.Add(PredefinedValue("Enum.CostAllocationOptions.ToInventoryCost"));
			ArrayOfExcludedValues.Add(PredefinedValue("Enum.CostAllocationOptions.ToProductionCostDirect"));
		EndIf;
	EndIf;
	
	GeneralPurposeTMServerCall.SelectableEnumerationValues(
		"CostAllocationOptions",
		ChoiceData,
		Parameters,
		ArrayOfExcludedValues);
		
EndProcedure

#EndRegion

#Region Public
// Returns an indication of the use of distribution rules for distribution options. 
// 
// Parameters:
//  CostAllocationOption - EnumRef.CostAllocationOptions - Cost allocation option
//  DistributionOptionKey - String - Determines for which type of accounting to analyze the rule usage attribute
// 
// Returns:
//  Boolean - True = uses, False = does not use
//
Function VariantUsesAllocationRule(CostAllocationOption, DistributionOptionKey = Undefined) Export
	
	If DistributionOptionKey <> Undefined And DistributionOptionKey = "CashDistributionOption" Then
		Return VariantUsesTaAllocationRule(CostAllocationOption);
	EndIf;
	
	OptionsWithAllocationRules = New Array;
	OptionsWithAllocationRules.Add(Enums.CostAllocationOptions.ToProductionCosts);
	OptionsWithAllocationRules.Add(Enums.CostAllocationOptions.ToDeferredExpenses);
	OptionsWithAllocationRules.Add(Enums.CostAllocationOptions.ToInventoryCost);
	
	If GetFunctionalOption("GenerateFinancialResult") Then
		OptionsWithAllocationRules.Add(Enums.CostAllocationOptions.ToLinesOfBusiness);
	EndIf;
	
	Return Not OptionsWithAllocationRules.Find(CostAllocationOption) = Undefined;
	
EndFunction
		
// Returns an indication of the use of distribution rules for distribution options for tax accounting.
// 
// Parameters:
//  CostAllocationOption - EnumRef.CostAllocationOptions - Cost allocation option
// 
// Returns:
//  Boolean - True = uses, False = does not use
//
Function VariantUsesTaAllocationRule(CostAllocationOption) Export
	
	OptionsWithAllocationRules = New Array;
	OptionsWithAllocationRules.Add(Enums.CostAllocationOptions.ToProductionCosts);
	OptionsWithAllocationRules.Add(Enums.CostAllocationOptions.ToDeferredExpenses);
	OptionsWithAllocationRules.Add(Enums.CostAllocationOptions.ToInventoryCost);
	
	Return Not OptionsWithAllocationRules.Find(CostAllocationOption) = Undefined;
	
EndFunction

// Returns an indication that there are no distribution settings for the distribution option. 
// 
// Parameters:
//  CostAllocationOption - EnumRef.CostAllocationOptions - Cost allocation option
// 
// Returns:
//  Boolean - True = there are no settings, False = there are settings
//
Function OptionWithoutDistribution(CostAllocationOption) Export
	
	OptionsWithoutDistribution = New Array;
	OptionsWithoutDistribution.Add(Enums.CostAllocationOptions.ToNonCurrentAssetCost);
	OptionsWithoutDistribution.Add(Enums.CostAllocationOptions.ToCostCenters);
	OptionsWithoutDistribution.Add(Enums.CostAllocationOptions.OnOtherAssets);
	OptionsWithoutDistribution.Add(Enums.CostAllocationOptions.DoNotAllocate);
	OptionsWithoutDistribution.Add(Enums.CostAllocationOptions.ToCurrentPeriodExpensesDirectly);
	
	If Not GetFunctionalOption("GenerateFinancialResult") Then
		OptionsWithoutDistribution.Add(Enums.CostAllocationOptions.ToLinesOfBusiness);
	EndIf;
	
	Return Not OptionsWithoutDistribution.Find(CostAllocationOption) = Undefined;
	
EndFunction

// Returns an indication that there are no distribution settings for the distribution option for tax accounting. 
// 
// Parameters:
//  CostAllocationOption - EnumRef.CostAllocationOptions - Cost allocation option
// 
// Returns:
//  Boolean - True = there are no settings, False = there are settings
//
Function OptionWithoutTaDistribution(CostAllocationOption) Export
	
	OptionsWithoutDistribution = New Array;
	OptionsWithoutDistribution.Add(Enums.CostAllocationOptions.ToNonCurrentAssetCost);
	OptionsWithoutDistribution.Add(Enums.CostAllocationOptions.ToCostCenters);
	OptionsWithoutDistribution.Add(Enums.CostAllocationOptions.OnOtherAssets);
	OptionsWithoutDistribution.Add(Enums.CostAllocationOptions.DoNotAllocate);
	OptionsWithoutDistribution.Add(Enums.CostAllocationOptions.ToLinesOfBusiness); 
	OptionsWithoutDistribution.Add(Enums.CostAllocationOptions.ToCurrentPeriodExpensesDirectly);
	
	Return Not OptionsWithoutDistribution.Find(CostAllocationOption) = Undefined;
	
EndFunction
#EndRegion