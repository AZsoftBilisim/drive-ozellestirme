#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	SetParameters = PropertyManager.PropertySetParametersStructure();
	SetParameters.Used = Constants.UseCustomerInvoiceIntercompany.Get();
	
	PropertyManager.SetPropertySetParameters("Document_CustomerInvoiceIntercompany", SetParameters);

EndProcedure

#EndRegion

#EndIf
