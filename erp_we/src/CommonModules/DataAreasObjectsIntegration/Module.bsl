// @strict-types

#Region Public

// See JobsQueueOverridable.OnDefineHandlerAliases
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
// 	NamesAndAliasesMap - See JobsQueueOverridable.OnDefineHandlerAliases.NamesAndAliasesMap
//
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export
EndProcedure

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport
//
// Parameters:
//	Types - See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.Types
//
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	Types.Add(Metadata.InformationRegisters.ObjectsToSend);
	Types.Add(Metadata.InformationRegisters.AccountingSystemsSettings);
	Types.Add(Metadata.InformationRegisters.ObjectsIntegrationStates);
	
EndProcedure

// Adds an object to be sent to an external accounting system.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  AccountingSystem - DefinedType.DataAreasIntegrationAccountingSystems - accounting system.
//  ObjectID - String - the object ID must meet 
//						 the requirements for naming operating system files (length-50).  
//  Handler - String - ID of the object handler (length-50).
//  ObjectData - BinaryData - object data to be sent (if not specified, data will be requested before sending).
//
Procedure AddPlaceToSend(AccountingSystem, ObjectID,
		Handler, ObjectData = Undefined) Export
EndProcedure

// Deletes an object from the objects to be sent to the accounting system.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  AccountingSystem - DefinedType.DataAreasIntegrationAccountingSystems - accounting system.
//  ObjectID - String - the object identifier (length - 50).
//  Handler - String - ID of the object handler (length-50).
//
Procedure DeleteItemToSend(AccountingSystem,
		ObjectID = Undefined, Handler = Undefined) Export
EndProcedure

// Performs notification of the external accounting system in accordance with the notification settings.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  AccountingSystem - DefinedType.DataAreasIntegrationAccountingSystems, CatalogRef - accounting system.
//  ObjectID - String - the object identifier (length - 50).
//  RaiseException1 - Boolean - indicates whether an exception is thrown when the notification was sent unsuccessfully.
//
Procedure NotifyObjectChanged(AccountingSystem, ObjectID,
		RaiseException1 = False) Export
EndProcedure

// Returns the settings of the external accounting system.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  AccountingSystem - DefinedType.DataAreasIntegrationAccountingSystems, CatalogRef - accounting system.
//  SettingsKeys - String, Array of String - keys of settings to return values for.
//
// Returns:
//  Structure - Account System Settings:
//	* NotifyAboutChanges - Boolean - indicates whether notifications are used when creating or changing data in the app.
//	* ServiceAddress - String - address of the service for receiving notifications about changes.
//	* AuthenticationMethod - EnumRef.AuthenticationMethods - authentication method in the notification receiving service.
//	* Login - String - login for authentication in the notification reception service (used for basic authentication).
//	* Password - String - authentication password in the notification receiving service (used for basic authentication).
//	* UseCertificate - Boolean - indicates whether the certificate is used when establishing a connection to the notification receiving service.
//	* CertificateName - String - name of the certificate file.
//	* CertificatePassword - String -  certificate password (used if the use Certificate property is set).
//	* CertificateData - BinaryData - binary data of the certificate in base64 (used if the use Certificate property is set).
//	* SignData - Boolean - indicates whether the data signature is used when sending it to the notification receiving service.
//	* SignatureKey - String - the secret word to sign data that is submitted. The signature is performed using the HMACSHA256 algorithm.
//
Function Settings(AccountingSystem, Val SettingsKeys = Undefined) Export
EndFunction

// Returns a template for placing the results of the Command execution
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Returns:
//  ValueTable - template for executing a Command to return results:
//	* ObjectID - String - object identifier.
//	* Handler - String - ID of the handler.
//
Function NewCommandExecutionResults() Export
EndFunction

#Region JobsQueueHandlers

// Executes the command received from the accounting system.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Parameters:
//	AccountingSystem - DefinedType.DataAreasIntegrationAccountingSystems - accounting system.
//	ParameterId_ - String - ID of the command execution parameters file (length 36).
//
Procedure ExecuteCommand(AccountingSystem, ParameterId_) Export
EndProcedure

// Generates a data package to be received by the accounting system.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//	AccountingSystem - DefinedType.DataAreasIntegrationAccountingSystems - the accounting system
//				   for which data is prepared.
//
Procedure PrepareData(AccountingSystem) Export
EndProcedure

// Processes the data packet received from the accounting system.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//	AccountingSystem - DefinedType.DataAreasIntegrationAccountingSystems - the accounting system
//				   for which data is prepared.
//  FileID - String - ID of the file to process (length 36).
//
Procedure ProcessData__(AccountingSystem, FileID) Export
EndProcedure

#EndRegion

#EndRegion
