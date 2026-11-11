#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the details of an object that is not recommended to edit
// by processing a batch update of account details.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Returns:
//  Array of String - a list of the names of the object's details.
Function AttributesToSkipInBatchProcessing() Export
EndFunction

#EndRegion

#EndIf