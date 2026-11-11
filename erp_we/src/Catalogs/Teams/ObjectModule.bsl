#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);

EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	If Not IsFolder Then
		
		Organization = SettingsValueCached.GetDefaultOrganization(Organization);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
