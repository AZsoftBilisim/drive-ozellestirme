#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	LockForUpdate = True;
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	InformationRegisters.NumberOfRecordsOfARAPRecorders.ReflectNumberOfRecordsOfPaymentRegistrars(
		Filter.Recorder.Value, "VendorsARAPAccountingByDueDates", DataExchange.Load);
		
	If DataExchange.Load Then
		Return;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf