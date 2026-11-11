#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	SetParameters = PropertyManager.PropertySetParametersStructure();
	SetParameters.Used = Constants.UseTransferOrders.Get();
	
	PropertyManager.SetPropertySetParameters("Document_TransferOrder", SetParameters);

EndProcedure

#EndRegion

#EndIf
