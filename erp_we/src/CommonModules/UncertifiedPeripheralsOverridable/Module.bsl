
#Region Public

// Establishes the availability of non-certified equipment
//  
// Parameters:
//  Available - Boolean - non-certified equipment is available.
//  StandardProcessing - Boolean - Standard treatment.
//
Procedure NonCertifiedEquipmentIsAvailable(Available, StandardProcessing) Export
	
EndProcedure

// Prepare the operation data before executing the command.
// 
// Parameters:
//  ConnectionParameters - Structure - Connection parameters.
//  Command - String - executed command.
//  OperationParametersList - Structure - The operation parameters.
//  OperationData - Structure
// 
Procedure PrepareOperationData(ConnectionParameters, Command, OperationParametersList, OperationData) Export
	
EndProcedure

// Process the operation data after executing the command.
// 
// Parameters:
//  ConnectionParameters - Structure - Connection parameters.
//  Command - String - executed command.
//  ExecutionResult - Structure - the result of the operation.
//  OperationData - Structure - The operation parameters.
// 
Procedure ProcessOperationData(ConnectionParameters, Command, ExecutionResult, OperationData) Export
	
EndProcedure

// Adds the supplied drivers to the list as part of the configuration.
// 
// Parameters:
//  Drivers - See UncertifiedPeripherals.NewTableOfNonCertifiedDrivers
//
Procedure RegisterDrivers(Drivers) Export
	
EndProcedure

#EndRegion
