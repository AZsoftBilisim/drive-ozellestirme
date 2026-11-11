#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	SetParameters = PropertyManager.PropertySetParametersStructure();
	SetParameters.Used = Constants.UseInternalSubcontracting.Get();
	
	PropertyManager.SetPropertySetParameters("Document_ConsumptionReportSubcontractingServicesDeliveredIntercompany", SetParameters);
	
EndProcedure

#EndRegion

#EndIf

