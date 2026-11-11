#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Fills in the document status selection list
//
// Parameters:
//  ChoiceData - ValueList - a list of values to fill in.
//  EstablishedStatus - EnumRef.StatusesOfProductionStages2_2 - current status of the document
Procedure FillChoiceList(ChoiceData, EstablishedStatus) Export
	
	ChoiceData.Clear();
	
	ChoiceData.Add(Enums.StatusesOfProductionStages2_2.BeingGenerated);
	ChoiceData.Add(Enums.StatusesOfProductionStages2_2.Generated1);
	ChoiceData.Add(Enums.StatusesOfProductionStages2_2.ForCompletion);
	ChoiceData.Add(Enums.StatusesOfProductionStages2_2.Initiated);
	ChoiceData.Add(Enums.StatusesOfProductionStages2_2.Completed);
	
	If ChoiceData.FindByValue(EstablishedStatus) = Undefined Then
		
		ChoiceData.Add(EstablishedStatus, EstablishedStatus);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf

