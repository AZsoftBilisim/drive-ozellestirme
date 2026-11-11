
#Region Public

// Fills in the structure of parameters for recording an RFID tag.
// 
// Returns:
//  Structure
//
Function RFIDTagRecordingParameters() Export; 
	
	Result = New Structure();
	Result.Insert("TID"       , Undefined);
	Result.Insert("EPC"       , Undefined);
	Result.Insert("Data"    , Undefined);
	Result.Insert("MemoryBank", "EPC");
	Result.Insert("Timeout"   , 0);
	Return Result;
	
EndFunction

// To start the opening session of the RFID reader.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - device ID, if undefined, a choice will be offered.
//   OperationParametersList       - Structure - parameters for performing the operation.
//   AdditionalParameters - Structure - additional commands.
//
Procedure StartOpeningRFIDReaderSession(NotificationOnCompletion, ClientID, DeviceID, OperationParametersList = Undefined, AdditionalParameters = Undefined) Export
	
	ParametersCommandExecution = EquipmentManagerClientServer.ParametersCommandExecution("OpenSessionRFID", Undefined, AdditionalParameters, False, False);
		
	EquipmentManagerClient.StartCommandExecution(NotificationOnCompletion, ClientID, DeviceID, 
		OperationParametersList, ParametersCommandExecution);
	
EndProcedure

// To begin closing session of the RFID reader.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - device ID, if undefined, a choice will be offered.
//   OperationParametersList       - Structure - parameters for performing the operation.
//   AdditionalParameters - Structure - additional commands.
//
Procedure StartClosingRFIDReaderSession(NotificationOnCompletion, ClientID, DeviceID, OperationParametersList = Undefined, AdditionalParameters = Undefined) Export
	
	ParametersCommandExecution = EquipmentManagerClientServer.ParametersCommandExecution("CloseSessionRFID", Undefined, AdditionalParameters, False, False);
		
	EquipmentManagerClient.StartCommandExecution(NotificationOnCompletion, ClientID, DeviceID, 
		OperationParametersList, ParametersCommandExecution);
	
EndProcedure

// Start recording data to the RFID tag.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - device ID, if undefined, a choice will be offered.
//   OperationParametersList       - Structure - parameters for performing the operation.
//   AdditionalParameters - Structure - additional commands.
//
Procedure StartRecordingDataToRFIDTag(NotificationOnCompletion, ClientID, DeviceID, OperationParametersList, AdditionalParameters = Undefined) Export
	
	ParametersCommandExecution = EquipmentManagerClientServer.ParametersCommandExecution("SaveDataTagRFID", Undefined, AdditionalParameters, False, False);
		
	EquipmentManagerClient.StartCommandExecution(NotificationOnCompletion, ClientID, DeviceID, 
		OperationParametersList, ParametersCommandExecution);
	
EndProcedure

// Generate an external event for the RFID emulator.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - device ID, if undefined, a choice will be offered.
//   OperationParametersList       - Structure - parameters for performing the operation.
//   AdditionalParameters - Structure - additional commands.
//
Procedure GenerateExternalEvent(NotificationOnCompletion, ClientID, DeviceID, OperationParametersList = Undefined, AdditionalParameters = Undefined) Export
	
	ParametersCommandExecution = EquipmentManagerClientServer.ParametersCommandExecution("ExternalEvent", Undefined, AdditionalParameters, False, False);
		
	EquipmentManagerClient.StartCommandExecution(NotificationOnCompletion, ClientID, DeviceID, 
		OperationParametersList, ParametersCommandExecution);
	
EndProcedure


#EndRegion
