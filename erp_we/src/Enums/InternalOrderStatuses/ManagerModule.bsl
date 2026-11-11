#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Fills in the status selection list, depending on the enabled options
//
// Parameters:
//  ChoiceData			 - ValueList of EnumRef.InternalOrderStatuses - list of values to fill in
//  UseStatusOnApproval - Boolean	 - indicates whether THE "Agreement" Status SHOULD be USED.
//
Procedure FillChoiceList(ChoiceData, UseStatusOnApproval) Export
	
	ChoiceData.Clear();
	
	If UseStatusOnApproval Then
		ChoiceData.Add(Enums.InternalOrderStatuses.AwaitingApproval);
	EndIf;
	
	// Unconditional statuses
	ChoiceData.Add(Enums.InternalOrderStatuses.ForCompletion);
	ChoiceData.Add(Enums.InternalOrderStatuses.Closed);
	
EndProcedure

#EndRegion

#EndIf
