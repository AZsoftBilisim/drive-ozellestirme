#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	ScheduledJobsServer.SetScheduledJobUsage(
		Metadata.ScheduledJobs.QCCMonitoring, 
		Not IsBlankString(Value) And Not Common.FileInfobase());
	
EndProcedure

#EndRegion

#EndIf