#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns a list of details that can be edited
// by processing group changes to objects.
// Returns:
//  Array - list of names of Attributes of the object:
//		* AttributeToLock - String - Name of the blocked account.
//
Function AttributesToEditInBatchProcessing() Export
	
	Return FilesOperations.AttributesToEditInBatchProcessing();
	
EndFunction

#EndRegion

#EndIf
