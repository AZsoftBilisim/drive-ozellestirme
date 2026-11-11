#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	ArrayOfExcludedValues = New Array;
	
	If Not GetFunctionalOption("GenerateFinancialAccountingEntriesByLocalAccountingData") Then
		
		ArrayOfExcludedValues.Add(Enums.StatusesOfPostingsInFinancialAccounting.PendingPostingInLocalAccounting);
		
	EndIf;
	
	If ArrayOfExcludedValues.Count() > 0 Then
		
		StandardProcessing = False;
		
		GeneralPurposeTMServerCall.SelectableEnumerationValues(
			"StatusesOfPostingsInFinancialAccounting",
			ChoiceData,
			Parameters,
			ArrayOfExcludedValues);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
