#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If StandardSubsystemsServer.IsBaseConfigurationVersion() And Not Value Then
		Cancel = True;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
