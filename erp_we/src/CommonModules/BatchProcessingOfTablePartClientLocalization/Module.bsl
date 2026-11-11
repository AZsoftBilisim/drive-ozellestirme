
#Region Internal

// Returns an indication that the rows of the table part need to be processed on the server.
// 
// Parameters:
//  CurrentRow - See BatchProcessingOfTablePartServer.ProcessTSString.CurrentRow
//  StructureOfActions - See BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
// Returns:
//  Boolean - Server Call Required
Function ServerCallRequired(CurrentRow, StructureOfActions, CachedValues) Export


	Return False;
	
EndFunction

Procedure ProcessTSString(CurrentRow, StructureOfActions, CachedValues) Export

	
EndProcedure

Procedure FillInServiceDetailsForProductInLineTS(CurrentRow, StructureOfActions, CachedValues) Export
	
	Return;
	
EndProcedure


#EndRegion
