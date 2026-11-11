
#Region Public

// Returns the value of a constant by name
//
// Parameters:
// 	Name - String - Name of the constant
// 
// Returns:
//	Arbitrary - The value of the constant
// 
Function ConstantValue(Name) Export
	Return GeneralPurposeTMServerCall.ConstantValue(Name);
EndFunction

// Returns the value of a constant by name
//
// Parameters:
// 	DocumentNameOrID - String - 
// 					- CatalogRef.MetadataObjectIDs - 
// 					- CatalogRef.ExtensionObjectIDs -  The name or identifier of the document metadata.
// 
// Returns:
//	String - Document synonym
// 
Function DocumentSynonym(DocumentNameOrID) Export
	Return GeneralPurposeTMServerCall.DocumentSynonym(DocumentNameOrID);
EndFunction

// Returns a flag indicating that the user has set the interface language
// corresponding to the main language of the information base.
//
// Returns:
//  Boolean
//
Function IsMainLanguage() Export
	
	Return GeneralPurposeTMServerCall.IsMainLanguage();
	
EndFunction


#EndRegion
