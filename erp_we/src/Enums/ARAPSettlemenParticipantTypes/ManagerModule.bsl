
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	If GetFunctionalOption("UseMultipleCompanies") Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	ChoiceData = New ValueList;
	ChoiceData.Add(Enums.ARAPSettlemenParticipantTypes.Client);
	ChoiceData.Add(Enums.ARAPSettlemenParticipantTypes.Vendor);
	
EndProcedure

#EndRegion

#EndIf