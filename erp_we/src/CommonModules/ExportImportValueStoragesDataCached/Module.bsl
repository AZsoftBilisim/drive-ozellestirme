////////////////////////////////////////////////////////////////////////////////
// Subsystem "Data upload and download".
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Returns a list of metadata objects that have properties that use the value Store type.
// 
// Returns: 
//	See ExportImportDataInternal.ReferencesToTypes
//
Function ListOfMetadataObjectsThatHaveValueStore() Export
	
	Types = CommonClientServer.ValueInArray(
		Type("ValueStorage"));
	
	Return ExportImportDataInternal.ReferencesToTypes(Types);
	
EndFunction

#EndRegion
