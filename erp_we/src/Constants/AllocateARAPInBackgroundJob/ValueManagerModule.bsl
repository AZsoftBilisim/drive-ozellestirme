#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Value = False Then
		DeferredJobs.Run(Metadata.InformationRegisters.JobsForARAPAllocating.Name);
	EndIf;
	
EndProcedure

#EndRegion

#EndIf