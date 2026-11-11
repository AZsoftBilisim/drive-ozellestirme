#Region Public

// Creates an incident type description structure that needs to be filled in and passed to the Create Type Record function.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  TypeName	 - String - Name of the incident type. The name must be unique, for example: Configure1.Subsystem1.Incident 1.
// 
// Returns:
//   - Structure - Structure Fields:
// 		* IncidentType - String - type name
//		* IncidentLevel - String - "Information", "Warning" (default), "Error", " Critical Error"
//		* Subsystem - String - subsystem from the point of view of the CCC
//		* InformationBaseContext - Boolean - to determine the context of the connection. By default, no.
//		* CheckProcedure - String - the name of the procedure that will be called periodically if there are open incidents of the specified type to check
//			their relevance. If "Auto" is specified, a check on the "Current" field from the open incident register will be used.
//		* MinutesBetweenIncidents - Number - limit the frequency of sending incidents. Default 0: do not restrict
//		* Tags - Structure - With Fields:
//		   ** Equipment - Boolean - 
//		   ** Enabled - Boolean - 
//		   ** Performance - Boolean - 
//		   ** ApplicationError - Boolean - 
//		   ** Additional - String - you can place any tags separated by a space in the string.
//
Function CreateIncidentTypeDescription(TypeName) Export
EndFunction

// Creates a record of the incident type and places it in the dictionary. If the type is already registered in the dictionary, it will be overwritten.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  DictionaryOfTypes - Map of KeyAndValue:
//  * Key - String - name of the incident type
//  * Value - See CreateIncidentTypeDescription
//  LongDesc - Structure:
//  * IncidentType - String
//  * IncidentLevel - String
//  * Subsystem - String
//  * InformationBaseContext - Boolean
//  * CheckProcedure - String
//  * MinutesBetweenIncidents - Number
//  * Tags - Structure:
//    ** Equipment - Boolean
//    ** Enabled - Boolean
//    ** Performance - Boolean
//    ** ApplicationError - Boolean
//    ** Additional - String
Procedure CreateRecordLike(Val DictionaryOfTypes, Val LongDesc) Export
EndProcedure

// Registers types of incidents in information security.
// @skip-warning EmptyMethod - a feature of the implementation.
//
Procedure RegisterIncidentTypesInQCC() Export
EndProcedure

// Opens the incident. If the CCC address is not specified, it does nothing. If an incident is sent more often 
// than the restrictions specified in the type, such a link will be ignored without raising exceptions. 
// If specified Asynchronously=If true, the method will be executed using the background job manager.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  IncidentType - String - ID of the incident type. Must be among the registered types.
//  IncidentCode - String - String ID of the incident. Must be unique within the type. If it is repeated, 
//  						it is considered that the incident is repeated again and the counter of its triggers in the CCC will increase.
//  MessageText - String - the text of the incident message.
//  Asynchronously - Boolean - asynchronous execution flag.
//
Procedure OpenIncident(Val IncidentType, Val IncidentCode, Val MessageText, Val Asynchronously = False) Export
EndProcedure

// Marks the incident in the Open incident register as irrelevant. 
// The incident will be closed in the CCC at the next call of the relevance check.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  IncidentType - String - ID of the incident type.
//  IncidentCode - String - The incident ID. 
//
Procedure MarkIncidentAsIrrelevant(Val IncidentType, Val IncidentCode) Export
EndProcedure

// Sends the tag to the CCN using InputStatistics/InputStatisticsDate (SENDING THE TAG SYNCHRONOUSLY).
// When arrays are specified in the parameters of the Counter ID/Counter value, the entire
// array is Transferred in one call.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  TagID - String - The ID of the meter to the CCC, separated by dots
//  TagValue - Number - The value of the counter on the transferred (specified) time
//  Data - Map of KeyAndValue:
//	 * Key - String - the ID of the meter
//	 * Value - Number - the counter value (if specified, takes precedence)
//  TagDate - Date - If specified, InputStatisticsDate is used, otherwise-InputStatistics.
//
Procedure SendStatistics(Val TagID, Val TagValue, Val Data = Undefined, Val TagDate = Undefined) Export
EndProcedure

#EndRegion

#Region Internal

// Called from the routine procedure of the Monitoring Committee
// @skip-warning EmptyMethod - a feature of the implementation.
// 
Procedure ExecuteQCCMonitoring() Export
EndProcedure

// See SaaSOperations.OnDefineSharedDataExceptions
// 
// Parameters:
//	Exceptions - Array of MetadataObject - Exceptions.
//
Procedure OnDefineSharedDataExceptions(Exceptions) Export

	Exceptions.Add(Metadata.InformationRegisters.IncidentsSendingSpeedLimit);
	Exceptions.Add(Metadata.InformationRegisters.OpenedIncidents);
	Exceptions.Add(Metadata.InformationRegisters.IncidentsDeferredChecks);
	Exceptions.Add(Metadata.Constants.QCCIncidentsTypesRelevant);
	
EndProcedure

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.
// 
// Parameters:
// 	Types - See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.Types
// 
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	Types.Add(Metadata.InformationRegisters.IncidentsSendingSpeedLimit);
	Types.Add(Metadata.InformationRegisters.OpenedIncidents);
	Types.Add(Metadata.InformationRegisters.IncidentsDeferredChecks);
	Types.Add(Metadata.Constants.QCCIncidentsTypesRelevant);
	
EndProcedure

// See ScheduledJobsOverridable.OnDefineScheduledJobSettings
// Parameters:
//	Settings - See ScheduledJobsOverridable.OnDefineScheduledJobSettings.Settings
Procedure OnDefineScheduledJobSettings(Settings) Export
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.QCCMonitoring;
	Setting.UseExternalResources = True;
	
EndProcedure

#EndRegion