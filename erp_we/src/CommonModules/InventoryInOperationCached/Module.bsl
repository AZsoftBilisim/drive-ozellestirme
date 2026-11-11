////////////////////////////////////////////////////////////////////////////////
// Procedures and functions of the TMC subsystem in operation.
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Determines whether it is possible to account for the series in operation.
// 
// Returns:
//  Boolean - True if there is an accounting policy with series accounting enabled in operation
Function ItIsPossibleToTakeIntoAccountSeriesInOperation() Export
	
	Return InventoryInOperationServer.ItIsPossibleToTakeIntoAccountSeriesInOperation();
	
EndFunction


#EndRegion
