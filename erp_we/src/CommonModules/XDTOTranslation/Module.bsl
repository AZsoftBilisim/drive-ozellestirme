
#Region Public

// The function translates an arbitrary XDTO object 
// between versions using the translation handlers registered in the system,
// determining the resulting version by the namespace of the resulting message.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  InitialObject - XDTODataObject - The object being translated.
//  ResultingVersion - String - The number of the resulting interface version, in the format PP. {P|PP}. ZZ. SS.
//  SourceVersionPackage - String - namespace of the message version.
//
// Returns:
//  XDTODataObject - the result of the translation of the object.
//
Function TranslateToVersion(Val InitialObject, Val ResultingVersion,
		Val SourceVersionPackage = "") Export
EndFunction

// The function translates an arbitrary XDTO object 
// between versions using the translation handlers registered in the system,
// determining the resulting version by the namespace of the resulting message.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  InitialObject - XDTODataObject - The object being translated.
//  ResultingVersionPackage - String - Namespace of the resulting version.
//  SourceVersionPackage - String - namespace of the message version.
//
// Returns:
//  XDTODataObject - the result of the translation of the object.
//
Function TranslateToNamespace(Val InitialObject,
		Val ResultingVersionPackage, Val SourceVersionPackage = "") Export
EndFunction

#EndRegion
