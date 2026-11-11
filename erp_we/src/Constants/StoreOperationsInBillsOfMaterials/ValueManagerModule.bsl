#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	Constants.UseImportOfProductionMasterData.Set(Value And Not Common.DataSeparationEnabled());
	
EndProcedure

#EndRegion

#EndIf