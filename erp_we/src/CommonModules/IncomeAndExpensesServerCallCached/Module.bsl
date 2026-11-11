
#Region Internal

#Region ArticleSelectionAndAnalytics

// Parameters:
//  AssetRef - ChartOfCharacteristicTypesRef.ExpenseItems, ChartOfCharacteristicTypesRef.IncomeItems, ChartOfCharacteristicTypesRef.AssetLiabilityItems -
// 
// Returns:
//  Structure - Article Details Values:
// * ValueType - TypeDescription - 
// * ControlDimensionFilling - Boolean - 
// * DimensionOfExpensesOrderImplementation - Boolean - 
// * WithoutDimension - Boolean - 
//
Function ArticleDetailsValues(AssetRef) Export
	
	Result = New Structure;
	Result.Insert("ValueType", New TypeDescription("Undefined"));
	Result.Insert("ControlDimensionFilling", False);
	Result.Insert("DimensionOfExpensesOrderImplementation",  False);
	Result.Insert("WithoutDimension", False);
	
	If Not ValueIsFilled(AssetRef) Then
		Return Result;
	EndIf;
	
	ArticleDetailsValues = New Structure();
	If TypeOf(AssetRef) =  Type("ChartOfCharacteristicTypesRef.ExpenseItems") Then
		ArticleDetailsValues = Common.ObjectAttributesValues(AssetRef, 
						"ValueType,
						|ControlDimensionFilling,
						|DimensionOfExpensesOrderImplementation");
	ElsIf TypeOf(AssetRef) = Type("ChartOfCharacteristicTypesRef.IncomeItems") Then
		ArticleDetailsValues = Common.ObjectAttributesValues(AssetRef, 
						"ValueType,
						|ControlDimensionFilling");
	ElsIf TypeOf(AssetRef) = Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems") Then
		ArticleDetailsValues = Common.ObjectAttributesValues(AssetRef, 
						"ValueType,
						|WithoutDimension");
	EndIf;
	FillPropertyValues(Result, ArticleDetailsValues);
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion