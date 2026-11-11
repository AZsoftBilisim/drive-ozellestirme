#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns object details that can be edited
// by processing group changes to details.
//
// Returns:
//  Array - a list of the names of the object's details.
//
Function AttributesToEditInBatchProcessing() Export
	
	Return FilesOperations.AttributesToEditInBatchProcessing();
	
EndFunction

#EndRegion

#EndIf
