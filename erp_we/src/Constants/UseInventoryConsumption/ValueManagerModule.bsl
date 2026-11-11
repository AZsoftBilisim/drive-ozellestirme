#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	SetParameters = PropertyManager.PropertySetParametersStructure();
	SetParameters.Used = Constants.UseInventoryConsumption.Get();
	
	PropertyManager.SetPropertySetParameters("Document_InventoryConsumption", SetParameters);

EndProcedure

#EndRegion

#EndIf
