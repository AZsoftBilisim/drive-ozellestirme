
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	SetParameters = PropertyManager.PropertySetParametersStructure();
	SetParameters.Used = Constants.UseConstructionObjects.Get();
	
	PropertyManager.SetPropertySetParameters("Catalog_ConstructionObjects", SetParameters);

EndProcedure

#EndRegion

#EndIf
