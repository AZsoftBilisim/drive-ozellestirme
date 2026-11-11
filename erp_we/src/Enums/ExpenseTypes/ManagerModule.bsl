
#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	StandardProcessing = False;
	
	ArrayOfExcludedValues = New Array;
	// Obsolete values
	ArrayOfExcludedValues.Add(PredefinedValue("Enum.ExpenseTypes.TypeOfExpensesProduction"));
	If Not GetFunctionalOption("UseNonCurrentAssets2_2")
		And Not GetFunctionalOption("UseNonCurrentAssets2_4") Then
		ArrayOfExcludedValues.Add(PredefinedValue("Enum.ExpenseTypes.CalculationOfNonCurrentAssetsVAlue"));
	EndIf;
	If GetFunctionalOption("TradeManagement") Then
		ArrayOfExcludedValues.Add(PredefinedValue("Enum.ExpenseTypes.CalculationOfNonCurrentAssetsVAlue"));
	EndIf;
	If GetFunctionalOption("TradeManagement") Or Not GetFunctionalOption("UseProduction") Then
		ArrayOfExcludedValues.Add(PredefinedValue("Enum.ExpenseTypes.ManufactureOfProducts"));
	Else
	EndIf;
	
	If Not GetFunctionalOption("UseAccountingByExpenseObjects") Then
		ArrayOfExcludedValues.Add(PredefinedValue("Enum.ExpenseTypes.ExpenseToCostCenters"));
	EndIf;
	
	GeneralPurposeTMServerCall.SelectableEnumerationValues(
		"ExpenseTypes",
		ChoiceData,
		Parameters,
		ArrayOfExcludedValues);
	
EndProcedure

#EndRegion

