
#Region Public

// Decomposes the magnetic card track data according to templates.
// Parameters:
//  TrackData - Array -- array of strings. Values obtained from tracks.
//  TrackParameters - Array - an array of structures containing device configuration parameters, where:
//   * Use - Boolean - indicates whether the track is being used.
//   * TrackNumber - Number - the sequence number of track 1-3.
//
// Returns:
//  Array of Structure:
//   * Template - CatalogRef.MagneticStripeCardTemplates - ;
//   * TrackData - Structure:
//  	** Field - String
//  	** Simple - Arbitrary - 
//
Function DecryptMagneticCardCode(TrackData, TrackParameters) Export;
	
	Return EquipmentInputDevicesServerCall.DecryptMagneticCardCode(TrackData, TrackParameters);
	
EndFunction            

// Generate an external event for the input device.
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
