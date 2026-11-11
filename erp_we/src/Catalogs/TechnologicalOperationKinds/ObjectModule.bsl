#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnCopy(CopiedObject)
	
	PropertiesSet = Undefined;
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If IsFolder Then
		Return;
	EndIf;
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteObjectKind(ThisObject, "Document_ProductionOperation2_2");
	// End StandardSubsystems.Properties
	
EndProcedure

#EndRegion

#EndIf
