#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		
		Return;
		
	EndIf;
    
	ScheduledJobsServer.SetScheduledJobUsage(Metadata.ScheduledJobs.SupportNewsReader, Not IsBlankString(Value));

EndProcedure

#EndRegion

#EndIf