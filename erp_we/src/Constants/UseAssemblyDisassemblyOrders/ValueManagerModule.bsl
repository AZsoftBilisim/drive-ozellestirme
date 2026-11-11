#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	SetParameters = PropertyManager.PropertySetParametersStructure();
	SetParameters.Used = Constants.UseAssemblyDisassemblyOrders.Get();
	
	PropertyManager.SetPropertySetParameters("Document_ByAssemblyDisassemblyOrder", SetParameters);

EndProcedure

#EndRegion

#EndIf
