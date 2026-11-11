
#Region Internal

// Prepare the operation data before executing the command.
// 
// Parameters:
//  ConnectionParameters - Structure - Connection parameters.
//  Command - String - executed command.
//  OperationParametersList - Structure - The operation parameters.
// 
// Returns:
//  Structure
Function PrepareOperationData(ConnectionParameters, Command, OperationParametersList) Export
	
	OperationData = UncertifiedPeripheralsClientServer.OperationData();
	OperationData.Result = True;
	
	UncertifiedPeripheralsOverridable.PrepareOperationData(ConnectionParameters, Command, OperationParametersList, OperationData);
	
	Return OperationData;
	
EndFunction

// Process the operation data after executing the command.
// 
// Parameters:
//  ConnectionParameters - Structure - Connection parameters.
//  Command - String - executed command.
//  ExecutionResult - Structure - the result of the operation.
//  OperationData - Structure - The operation parameters.
// 
Procedure ProcessOperationData(ConnectionParameters, Command, ExecutionResult, OperationData) Export
	
	UncertifiedPeripheralsOverridable.ProcessOperationData(ConnectionParameters, Command, ExecutionResult, OperationData);
	
EndProcedure

#EndRegion
