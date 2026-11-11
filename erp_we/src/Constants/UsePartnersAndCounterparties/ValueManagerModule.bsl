#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	ValueManager = Constants.UsePartnersAsCounterparties.CreateValueManager();
	ValueManager.Value = Not Value;
	ValueManager.DataExchange.Load = True;
	ValueManager.Write();
	
EndProcedure

#EndRegion

#EndIf