///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2018, 1C-Soft LLC
// All rights reserved. This program and accompanying materials are provided 
// in accordance with the terms of the Attribution 4.0 International (CC BY 4.0) license
// The license text is available at the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
// @strict-types

#Region Public

////////////////////////////////////////////////////////////////////////////////
// Messaging

// Returns the State of using backup of data areas.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Returns:
//   Boolean - True if backup is used.
//
Function BackupIsUsed() Export
EndFunction

////////////////////////////////////////////////////////////////////////////////
// User activity in the data area.

// Sets whether the user is active in the Cur area.
// The attribute is the value of the jointly divided constant of the date of the last startaclient session.
// @skip-warning EmptyMethod - a feature of the implementation.
//
Procedure SetUserActivityFlagInArea() Export
EndProcedure

// Returns the correspondence of Russian field names of software system settings
// to English from the Service Manager's XDTO package ZoneBackupControl.
// (type: {http://www.1c.ru/SaaS/1.0/XMLSchema/ZoneBackupControl }Settings).
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Returns:
//   FixedMap of KeyAndValue - Matching Russian Names Of Settings Fields To English:
//   * Key - String
//   * Value - String
//
Function MatchingRussianNamesOfSettingsFieldsToEnglish() Export
EndFunction

// Determines whether the application supports backup functionality.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Returns:
//  Boolean - True if the application supports backup functionality.
//
Function ServiceManagerSupportsBackup() Export
EndFunction

// Returns the proxy of the backup control web service.
// The calling code must independently set the privileged mode.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Returns: 
//   WSProxy - proxy of the service manager.
// 
Function BackupControlProxy() Export
EndFunction

// Returns the subsystem name to be used in the event names of the logging Log.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Returns:
//   String - name of the subsystem.
//
Function SubsystemNameForLogEvents() Export
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Background job

// Returns the name of the background task for uploading an area to a file.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Returns:
//   String - name of the background task.
//
Function NameOfBackgroundBackup() Export
EndFunction

// See JobsQueueOverridable.OnDefineHandlerAliases.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Parameters:
// 	NamesAndAliasesMap - See JobsQueueOverridable.OnDefineHandlerAliases.NamesAndAliasesMap
// 
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export
EndProcedure

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.
// 
// Parameters:
// 	Types - See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.Types
// 
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	Types.Add(Metadata.Constants.BackUpDataArea);
	Types.Add(Metadata.Constants.LastClientSessionStartDate);
	
EndProcedure

// See CommonOverridable.OnDefineSupportedInterfaceVersions.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Parameters:
// 	SupportedVersionsStructure - See CommonOverridable.OnDefineSupportedInterfaceVersions.SupportedVersions
// 
Procedure OnDefineSupportedInterfaceVersions(Val SupportedVersionsStructure) Export
EndProcedure

// See SaaSOperationsOverridable.OnFillIIBParametersTable.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Parameters:
//	ParametersTable - See SaaSOperations.IBParameters
//
Procedure OnFillIIBParametersTable(ParametersTable) Export
EndProcedure

// See JobsQueueOverridable.OnDefineErrorHandlers.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Parameters:
// 	ErrorHandlers - See JobsQueueOverridable.OnDefineErrorHandlers.ErrorHandlers
// 
Procedure OnDefineErrorHandlers(ErrorHandlers) Export
EndProcedure

// See MessageInterfacesSaaSOverridable.FillInReceivedMessageHandlers.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Parameters:
// 	HandlersArray - See MessageInterfacesSaaSOverridable.FillInReceivedMessageHandlers.HandlersArray
// 
Procedure RecordingIncomingMessageInterfaces(HandlersArray) Export
EndProcedure

// See MessageInterfacesSaaSOverridable.FillInHandlersForSendingMessages.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Parameters:
// 	HandlersArray - See MessageInterfacesSaaSOverridable.FillInHandlersForSendingMessages.HandlersArray
// 
Procedure RecordingOutgoingMessageInterfaces(HandlersArray) Export
EndProcedure

// See CommonOverridable.OnAddClientParameters.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Parameters:
// 	Parameters - See CommonOverridable.OnAddClientParameters.Parameters
// 
Procedure OnAddClientParameters(Parameters) Export
EndProcedure

#EndRegion
