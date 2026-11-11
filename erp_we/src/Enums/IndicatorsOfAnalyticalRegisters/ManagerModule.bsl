#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the structure of parameters for reflecting the indicator in budgeting.
//
// Returns:
//	Structure
//
Function IndicatorReflectionParameters() Export
	
	ReflectionParameters = New Structure;
	ReflectionParameters.Insert("ManResources", New Array);
	ReflectionParameters.Insert("LocalResources", New Array);
	ReflectionParameters.Insert("ShaftResources", New Array);
	ReflectionParameters.Insert("ResourcesQuantity", New Array);
	ReflectionParameters.Insert("ExpressionIsDebit", "");
	ReflectionParameters.Insert("ExpressionIsLoan", "");
	ReflectionParameters.Insert("DataPathRecordFinID", "");
	ReflectionParameters.Insert("DataPathRowId", "");
	ReflectionParameters.Insert("CorDataSources", New Array);
	
	Return ReflectionParameters;
	
EndFunction

// Returns an array of redefined fields depending on the metric.
//
// Returns:
//	Array of String
//
Function SampleFieldsBasedOnIndicatorDescription() Export
	
	SelectionFields1 = New Array();
	SelectionFields1.Add("Factor");
	SelectionFields1.Add("FinRecordID");
	SelectionFields1.Add("RowID");
	SelectionFields1.Add("ThisIsDebit");
	SelectionFields1.Add("ThisIsLoan");
	SelectionFields1.Add("SumMan");
	SelectionFields1.Add("SumCompl");
	SelectionFields1.Add("SumCurr");
	SelectionFields1.Add("Count");
	SelectionFields1.Add("ThisIsReverseTransaction");
	SelectionFields1.Add("ResourceValueCondition");
	
	Return SelectionFields1;
	
EndFunction

#EndRegion

#EndIf