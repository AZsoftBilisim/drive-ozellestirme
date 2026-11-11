///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2018, 1C-Soft LLC
// All rights reserved. This program and accompanying materials are provided 
// in accordance with the terms of the Attribution 4.0 International (CC BY 4.0) license
// The license text is available at the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Get data descriptors for the specified conditions.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  DataKind - String - name of the type of data to be delivered.
//  Filter - Array - elements must contain the Code (string) and Value (string) fields.
//
// Returns:
//    XDTODataObject - type ArrayOfDescriptor.
//
Function DescriptorsOfSuppliedDataFromManager(Val DataKind, Val Filter = Undefined) Export  
EndFunction

// Initiates data processing.
//
// It can be used in conjunction with the descriptors provided by the Data Manager to 
// manually initiate the data processing process. After calling the method, the system 
// will behave as if it has just received a notification about the availability of new data, 
// with the specified descriptor - the available new data will be called, and then, if necessary, 
// Process new data for the corresponding handlers.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//   Descriptor - XDTODataObject - Descriptor.
//
Procedure UploadAndProcessData(Val Descriptor) Export
EndProcedure
	
// Puts the data in the Catalog of the supplied data.
//
// The data is stored either in the volume on the disk or in the field of the Supplied data table, 
// depending on the constant to store the file in the disk and the availability of free volumes. The data 
// can be retrieved later by searching for Attributes, or by specifying 
// a unique identifier that was passed to the Descriptor field.FileGUID. If the database 
// already has data with the same type of data and a set of key characteristics, the new data 
// replaces the old ones. This uses updating an existing Catalog item, rather 
// than deleting and creating a new one.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//   Descriptor - XDTODataObject - Descriptor or structure with fields.
//	 	"Data view, data Additions, file ID, Characteristics",
//    	where Characteristics are an array of structures with the fields "Code, Value, Key".
//   PathToFile - String - full name of the extracted file.
//
Procedure SaveSuppliedDataToCache(Val Descriptor, Val PathToFile) Export
EndProcedure

// Deletes the file from the cache.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  LinkOrID - CatalogRef.SuppliedData - link to the supplied data,
//                         - UUID - unique identifier.
//
Procedure DeleteSuppliedDataFromCache(Val LinkOrID) Export
EndProcedure

// Retrieves a data descriptor from the cache.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  LinkOrID - CatalogRef.SuppliedData - link to the supplied data,
//                         - UUID - unique identifier,
//  InFormOfXDTO - Boolean - how to return values.
//
// Returns:
//    XDTODataObject - type ArrayOfDescriptor.
//
Function DescriptorOfSuppliedDataFromCache(Val LinkOrID, Val InFormOfXDTO = False) Export
EndFunction

// Returns binary data of the attached file.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  LinkOrID - CatalogRef.SuppliedData - link to the supplied data,
//                         - UUID - unique identifier.
//
// Returns:
//  BinaryData - binary data of the supplied data.
//
Function SuppliedDataFromCache(Val LinkOrID) Export
EndFunction

// Checks whether data with the specified key characteristics is in the cache.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//   Descriptor - XDTODataObject - Descriptor.
//
// Returns:
//  Boolean - the presence of the descriptor in the cache.
//
Function AvailableInCache(Val Descriptor) Export
EndFunction

// Returns an array of references to data that meets the specified conditions.
//
// Parameters:
//  DataKind - String - name of the type of data to be delivered.
//  Filter - Array - elements must contain the Code (string) and Value (string) fields.
//
// Returns:
//    Array of AnyRef - array of data references.
//
Function ReferencesSuppliedDataFromCache(Val DataKind, Val Filter = Undefined) Export

	Return New Array();
	
EndFunction

// Get data for the specified conditions.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  DataKind - String - name of the type of data to be delivered.
//  Filter - Array - elements must contain the Code (string) and Value (string) fields.
//  InFormOfXDTO - Boolean - how to return values.
//
// Returns:
//    XDTODataObject - type ArrayOfDescriptor or
//    An array of structures with the fields "Data type, Data addition, File identifier, Characteristics",
//    where Characteristics are an array of structures with the fields "Code, Value, Key".
//	  To get the file itself, you need to call Get the supplied cache data.
//
//
Function DescriptorsOfSuppliedDataFromCache(Val DataKind, Val Filter = Undefined, Val InFormOfXDTO = False) Export
EndFunction	

// Returns a custom Presentation of the supplied data descriptor.
// It can be used when displaying messages in the registration Log.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  Descriptor - XDTODataObject - type Descriptor or structure with fields.
//	 	"Data view, data Additions, file ID, Characteristics",
//    	where Characteristics are an array of structures with the fields "Code, Value".
//	JSONDescriptor - Boolean - indicates that the handle is in JSON format
//
// Returns:
//  String - a custom representation of the descriptor.
//
Function GetDataDescription(Val Descriptor, Val JSONDescriptor = False) Export
EndFunction

// Returns the registered handlers of the supplied data.
// Used to start the validation procedures and load the new supplied data. It can
// also be used to get a list of supported types of supplied data.
//
// Returns:
//	ValueTable - table with columns:
//		* DataKind - String - code of the data type processed by the handler.
//		* HandlerCode - String - used when restoring data processing after a failure.
//		* Handler - CommonModule - a module containing the following export procedures:
//			Available New Data (Descriptor, Upload)  
//			Process New data(Descriptor, File path)
//			Processing Data is changed (Descriptor)
//
Function GetHandlers() Export
	
	Handlers = New ValueTable;
	Handlers.Columns.Add("DataKind");
	Handlers.Columns.Add("Handler");
	Handlers.Columns.Add("HandlerCode");
	
	CTLSubsystemsIntegration.OnDefineSuppliedDataHandlers(Handlers);
	SuppliedDataOverridable.GetHandlersForSuppliedData(Handlers);
	
	Return Handlers;
	
EndFunction	

///////////////////////////////////////////////////////////////////////////////////
// Updating information in data areas.

// Returns a list of data areas to which the supplied data has not yet been copied.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// In the case of the first call to the function, the full set of available areas is returned.
// On a subsequent call, when recovering from a crash, only
// the unprocessed areas will be returned. After copying the data to the area, the Processed area should be called.
//
// Parameters:
//  FileID - UUID - ID of the supplied data file,
//  HandlerCode - String - handler code,
//  IncludingUndivided - Boolean - if True, the area with the code -1 is added to all available areas.
// 
// Returns:
//  Array of Number - areas requiring processing.
//
Function AreasRequiringProcessing(Val FileID, Val HandlerCode, Val IncludingUndivided = False) Export
EndFunction

// Removes an area from the unprocessed list. Disables session partitioning (if it was enabled),
// because when partitioning is enabled, writing to an undivided register is prohibited.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  FileID - UUID - the supplied data file,
//  HandlerCode - String - handler code,
//  DataArea - Number - ID of the processed area.
// 
Procedure AreaProcessed(Val FileID, Val HandlerCode, Val DataArea) Export
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Event handlers of configuration subsystems.

// See JobsQueueOverridable.OnDefineHandlerAliases.
// @skip-warning EmptyMethod - a feature of the implementation.
//
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export
EndProcedure

// See MessagesExchangeOverridable.GetMessagesChannelsHandlers.
// @skip-warning EmptyMethod - a feature of the implementation.
//
Procedure OnDefineMessagesChannelsHandlers(Handlers) Export
EndProcedure

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.
// 
// Parameters:
// 	Types - See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.Types
// 
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	Types.Add(Metadata.InformationRegisters.SuppliedDataRequiringProcessingInAreas);
	
EndProcedure

#Region OutdatedProgrammingInterface

// Deprecated. You should use the supplied data.Request data
// Initiate notification of all supplied data available in the MS (with the exception of
// those marked "Notification ban".
// @skip-warning EmptyMethod - a feature of the implementation.
//
Procedure RequestAllData() Export
EndProcedure

#EndRegion

#EndRegion
