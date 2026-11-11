#Region Internal

#Region System


Procedure ConnectedEquipment_DataExchangeWithServer() Export
	
	EquipmentManagerClient.DataExchangeWithServer();
	
EndProcedure

Procedure ConnectedEquipment_LogInAtServer() Export
	
	If CommonCELClient.LoggingSubsystemIsUsed() Then
		ModuleLoggingOfOperationsOfBPOClient = CommonCELClient.CommonModule("LoggingOfCELOperationsClient");
		ModuleLoggingOfOperationsOfBPOClient.LogInAtServer();
	EndIf;
	
EndProcedure

Procedure ConnectedEquipment_RecordLogATServerAtEnd() Export
	
	If CommonCELClient.LoggingSubsystemIsUsed() Then
		ModuleLoggingOfOperationsOfBPOClient = CommonCELClient.CommonModule("LoggingOfCELOperationsClient");
		ModuleLoggingOfOperationsOfBPOClient.LogInAtServer();
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion