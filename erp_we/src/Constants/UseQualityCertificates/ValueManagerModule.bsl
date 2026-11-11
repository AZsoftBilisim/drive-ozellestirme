#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	SetParameters = PropertyManager.PropertySetParametersStructure();
	SetParameters.Used = Constants.UseQualityCertificates.Get();
	
	PropertyManager.SetPropertySetParameters("Catalog_QualityCertificates", SetParameters);

EndProcedure

#EndRegion

#EndIf
