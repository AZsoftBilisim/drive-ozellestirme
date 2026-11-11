#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Fills in the Status selection list
//
// Parameters:
//  ChoiceData			 - ValueList	 - list of values to fill in
//
Procedure FillChoiceList(ChoiceData) Export
	
	ChoiceData.Clear();
	
	// Unconditional statuses
	ChoiceData.Add(Enums.StatusesOfOrdersForMaterialsForProduction.ForCompletion);
	ChoiceData.Add(Enums.StatusesOfOrdersForMaterialsForProduction.Closed);
	
EndProcedure

#EndRegion

#EndIf