#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns a list of details that can be edited
// by processing group changes to objects.
//
// Returns:
//  Array - a list of the names of the object's details.
Function AttributesToEditInBatchProcessing() Export
	
	Return FilesOperations.AttributesToEditInBatchProcessing();
	
EndFunction

#EndRegion

#EndIf
