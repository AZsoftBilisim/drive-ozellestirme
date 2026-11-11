#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	StatusID = New UUID;
	For Each Record In ThisObject Do
		Record.StatusID = StatusID;
	EndDo;
	
	If Not AdditionalProperties.Property("DocumentProperties") Then
		InfobaseUpdate.CheckObjectProcessed(ThisObject);
	EndIf;

EndProcedure

#EndRegion

#EndIf
