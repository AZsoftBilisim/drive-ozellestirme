#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not Value Then
		Try
			InformationRegisters.StatusOfMigrationToPriceManagementSystemVersion25.CreateRecordSet().Write();
		Except
			Cancel = True;
		EndTry;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
#EndIf
