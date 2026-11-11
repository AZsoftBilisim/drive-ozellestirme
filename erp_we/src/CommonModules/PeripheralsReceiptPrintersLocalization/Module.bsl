
#Region Public

#Region RegistrationParameters

// Saves device registration parameters
// 
// Parameters:
//  Result - Boolean
//  Id - CatalogRef.Peripherals - Device ID - 
//  RegistrationParameters - Structure -  
//
Procedure SaveDeviceRegistrationSettings(Result, Id, RegistrationParameters) Export
	
	
EndProcedure

// Returns registration parameters by device ID.
// 
// Parameters:
//  RegistrationParameters - See PeripheralsReceiptPrintersClientServer.CRERegistrationParameters
//  Id - CatalogRef.Peripherals 
//
Procedure DeviceRegistrationParameters(RegistrationParameters, Id) Export
	
	
EndProcedure

// Updates the parameters of the CCT registration
//
// Parameters:
//   RegistrationParametersTable - ValueTable - 
//   RegistrationParameters - ValueTable - 
//
Procedure UpdateCCTRegistrationParameters(RegistrationParametersTable, RegistrationParameters) Export
	
	
EndProcedure

// Returns whether the fiscal device supports checking the marking codes.
// 
// Parameters:
//  Result - Boolean - The fiscal device supports checking the marking codes
//  DeviceID - CatalogRef.Peripherals - Device ID
// 
Procedure FiscalDeviceSupportsVerificationOfMarkingCodes(Result, DeviceID) Export
	
	
EndProcedure

// Returns the FFD version for the fiscal device.
// 
// Parameters:
//  Result - String - FFD version supported by the device
//  DeviceID - CatalogRef.Peripherals - Device ID.
// 
Procedure FiscalDeviceSupportsFFDVersion(Result, DeviceID) Export
	
	
EndProcedure

// The function returns whether the fiscal device supports the vehicle PIOT.
// 
// Parameters:
//  DeviceID - CatalogRef.Peripherals - Device ID.
// 
// Returns:
//  Undefined - The fiscal device supports the vehicle PIoT
Function FiscalDeviceSupportsTSPIoT(DeviceID) Export
	
	
EndFunction

#EndRegion

// Checks whether tags are required.
//
// Parameters:
//  Result - Boolean
//  Parameters - Structure 
//  DeviceID - CatalogRef.Peripherals
//  ErrorDescription - String
// 
Procedure MandatoryAndCorrectFillingOfTagsWasChecked(Result, Parameters, DeviceID, ErrorDescription) Export
	
	
EndProcedure

// Leads to a format agreed with the Federal Tax Service.
//
// Parameters:
//  MainParameters - See PeripheralsReceiptPrintersClientServer.ParametersOfReceiptFiscalizationOperation
//  Rejection is Boolean
//  Error Descriptionline
//  FixedBasicParameters - Boolean
Procedure BringDataToRequiredFormat(MainParameters, FixedBasicParameters) Export
	
	
EndProcedure

#EndRegion
