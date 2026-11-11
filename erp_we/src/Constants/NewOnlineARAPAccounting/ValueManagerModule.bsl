#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	If Constants.NotNewOnlineARAPAccounting.Get() = Value Then
		Constants.NotNewOnlineARAPAccounting.Set(Not Value);
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
