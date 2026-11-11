
#Region Public

// Executes the command of the hardware driver that is not included in the library
//
// Parameters:
//  Object - AddInObject
//  ConnectionParameters - Structure
//  Command - String - the command passed when calling the hardware method
//  OperationData - See UncertifiedPeripheralsClientServer.OperationData
//  ExecutionResult - See EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware
//
// Returns:
//  Boolean - result of operation, if False is requested, the driver method will get the error asinx
Async Function ExecuteCommandAsync(Object, ConnectionParameters, Command, OperationData, ExecutionResult) Export
	
EndFunction

// Registers the names of external driver events that will trigger a general alert to process it 
// in various forms.
//
// Parameters:
//  EquipmentType - EnumRef.PeripheralTypes
//  EventNames - Array of String - names of events that will trigger the alert
//  ConnectionParameters - Structure
//
Procedure RegisterEventsForNotification(EquipmentType, EventNames, ConnectionParameters) Export
	
EndProcedure

// Performs event handling caused by an external hardware driver
// 
// Parameters:
//  ConnectionParameters - Structure
//  Event - String
//  Data - String
//  StandardProcessing - Boolean
//
Procedure ProcessEvent(ConnectionParameters, Event, Data, StandardProcessing) Export
	
EndProcedure

#EndRegion

