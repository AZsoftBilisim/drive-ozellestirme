
#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	StandardProcessing = False;
		
	ArrayOfExcludedValues = New Array;
	
	If Not GetFunctionalOption("EnterpriseManagement") Then
		ArrayOfExcludedValues.Add(PredefinedValue("Enum.SectionsOfBudgetingDataSources.FinancialAccounting"));
	EndIf;

	GeneralPurposeTMServerCall.SelectableEnumerationValues(
		"SectionsOfBudgetingDataSources",
		ChoiceData,
		Parameters,
		ArrayOfExcludedValues);
	
EndProcedure

#EndRegion

