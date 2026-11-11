
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Add an entry.
// 
// Parameters:
//  Job - BackgroundJob
//  Container - DataProcessorObject.ExportImportDataContainerManager
//  ThreadType - EnumRef.ExportImportDataThreadTypes
Procedure AddRecord(Job, Container, ThreadType) Export
	
	Return;
	
EndProcedure

// Delete the entry.
// 
// Parameters:
//  JobID - UUID
Procedure DeleteRecord(JobID) Export
	
	Return;
	
EndProcedure

// You need to complete the flow.
// 
// Parameters:
//  JobID - UUID
// 
// Returns:
//  Boolean - Need To Complete The Flow
Function NeedToCompleteThread(JobID) Export
	
	Return False;
	
EndFunction

// Check the running threads.
Procedure CheckOperationOfRunningThreads() Export
	
	Return;
	
EndProcedure

#EndRegion

#EndIf
