#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	SetParameters = PropertyManager.PropertySetParametersStructure();
	SetParameters.Used = Value;
	PropertyManager.SetPropertySetParameters("Document_CommercialProposalForCustomer", SetParameters);
	
EndProcedure

#EndRegion

#EndIf