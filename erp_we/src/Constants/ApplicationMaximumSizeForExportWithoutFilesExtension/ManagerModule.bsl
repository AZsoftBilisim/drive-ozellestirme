#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Internal

Function Value() Export
	
	CurrentValue = Get();
	If CurrentValue = 0 Then
		Return 1024;
	Else
		Return CurrentValue;
	EndIf;
	
EndFunction

#EndRegion
	
#EndIf