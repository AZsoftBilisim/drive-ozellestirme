#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	If Constants.NewOnlineARAPAccounting.Get() = Value Then
		Constants.NewOnlineARAPAccounting.Set(Not Value);
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
