
Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	If Parameters.Property("StocktakingRecord") Then
		
		StandardProcessing = False;
		
		ChoiceData = New ValueList;
		ChoiceData.Add(Enums.WaysToRepayCostOfInventory.OnCommissioning);
		ChoiceData.Add(Enums.WaysToRepayCostOfInventory.ByDate);
		If Parameters.StocktakingRecord Then
			ChoiceData.Add(Enums.WaysToRepayCostOfInventory.ByAssetActivity);
		EndIf;
		
	EndIf;
	
	If Parameters.Property("MethodOfRepaymentOfCostOfAC") Then
		
		StandardProcessing = False;
		
		ChoiceData = New ValueList;
		ChoiceData.Add(Enums.WaysToRepayCostOfInventory.OnCommissioning);
		ChoiceData.Add(Parameters.MethodOfRepaymentOfCostOfAC);
		
	EndIf;
	
EndProcedure
