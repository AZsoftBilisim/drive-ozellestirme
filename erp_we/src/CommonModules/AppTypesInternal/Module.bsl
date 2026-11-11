
#Region Internal

// See CommonOverridable.OnDefineSupportedInterfaceVersions.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Parameters:
//  SupportedVersionsStructure - See CommonOverridable.OnDefineSupportedInterfaceVersions.SupportedVersions
// 
Procedure OnDefineSupportedInterfaceVersions(Val SupportedVersionsStructure) Export
	
EndProcedure

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.
// 
// Parameters:
//  Types - See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.Types
// 
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	Types.Add(Metadata.InformationRegisters.DataAreasAppTypes);
EndProcedure

// See CommonOverridable.OnAddClientParametersOnStart.
Procedure OnAddClientParametersOnStart(Parameters) Export
	Parameters.Insert("AppTypePresentation", AppTypesServer.CurrentAppTypePresentation());
EndProcedure

// See CommonOverridable.OnAddClientParameters.
Procedure OnAddClientParameters(Parameters) Export
	Parameters.Insert("AppTypePresentation", AppTypesServer.CurrentAppTypePresentation());
EndProcedure

// Fills the transmitted array with common modules that are handlers for the interfaces of received messages.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  HandlersArray - Array of CommonModule - a collection of modules containing handlers.
//
Procedure RecordingIncomingMessageInterfaces(HandlersArray) Export
	
EndProcedure

// Fills the transmitted array with common modules that are handlers of the interfaces of the sent messages.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  HandlersArray - Array of CommonModule - collection of modules containing handlers..
//
Procedure RecordingOutgoingMessageInterfaces(HandlersArray) Export
	
EndProcedure

// Called when installing the basic application view.
//
// Parameters:
//  ProcessingResult - Structure - method processing results (returned data):
//   * Error - Boolean - indicates a processing error.
//   * Message - String - processing error message.
//
Procedure InstallingBasicAppType(ProcessingResult) Export
	
	AppTypesOverridable.OnBasicAppTypeInstalling(ProcessingResult);
	
EndProcedure

// Called when the data area is attached or the application migration Ends.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  ApplicationKind - Undefined, XDTODataObject - message body.
//
Procedure SetAppTypeByMessage(ApplicationKind) Export
	
EndProcedure

#EndRegion