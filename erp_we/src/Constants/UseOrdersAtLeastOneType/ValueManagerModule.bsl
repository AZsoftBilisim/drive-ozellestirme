#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	SetParameters = PropertyManager.PropertySetParametersStructure();
	SetParameters.Used = GetFunctionalOption("UseOrderSupplyWithAssignment");
	PropertyManager.SetPropertySetParameters("Document_InventoryAssignmentAdjustment", SetParameters);
	
EndProcedure

#EndRegion

#EndIf
