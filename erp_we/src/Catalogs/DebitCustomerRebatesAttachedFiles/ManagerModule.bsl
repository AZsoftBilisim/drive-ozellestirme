//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// Returns a list of details that can be edited
// by processing group changes to objects.
//
// Returns:
//	Array of String - a list of the names of the object's details.
//
Function AttributesToEditInBatchProcessing() Export
	
	Return FilesOperations.AttributesToEditInBatchProcessing();
	
EndFunction

// Defining access rights
//
// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowRead
	|WHERE
	|	ObjectReadingAllowed(FileOwner)
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	ObjectUpdateAllowed(FileOwner)";

EndProcedure

#EndRegion

#EndRegion

#EndIf
