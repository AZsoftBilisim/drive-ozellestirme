
#Region Internal

// Get the xmlpackage for the operation.
// 
// Parameters:
//  OperationParametersList - Structure - Parameters
// 
// Returns:
//  String - Get the Xmlpackage for the operation
//
Function GetXMLPacketForOperation(OperationParametersList) Export
	
	Return PeripheralsPaymentSystemsServerClientServer.GetXMLPacketForOperation(OperationParametersList);
	
EndFunction
 
#EndRegion

