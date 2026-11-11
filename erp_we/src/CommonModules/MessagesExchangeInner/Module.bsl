
#Region Public

// @skip-warning EmptyMethod - a feature of the implementation.
// Returns:
//	ExchangePlanRef.MessagesExchange - link to the node.
Function ThisNode() Export
EndFunction

// See DataExchangeOverridable.OnDataExport
// @skip-warning EmptyMethod - a feature of the implementation.
// 
Procedure OnDataExport(StandardProcessing, Recipient, MessageFileName,
		MessageData, TransactionItemsCount,
		EventLogEventName, SentObjectsCount) Export
EndProcedure

// See DataExchangeOverridable.OnDataImport
// @skip-warning EmptyMethod - a feature of the implementation.
// 
Procedure OnDataImport(StandardProcessing, Sender,
		MessageFileName, MessageData, TransactionItemsCount,
		EventLogEventName, ReceivedObjectsCount) Export
EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Parameters:
//	Handlers - See InfobaseUpdate.NewUpdateHandlerTable
//
Procedure OnAddUpdateHandlers(Handlers) Export
EndProcedure

// See BatchEditObjectsOverridable.OnDefineObjectsWithEditableAttributes
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Parameters:
//	Objects - See BatchEditObjectsOverridable.OnDefineObjectsWithEditableAttributes.Objects
//
Procedure OnDefineObjectsWithEditableAttributes(Objects) Export
EndProcedure

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport
// 
// Parameters:
//	Types - See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.Types
//
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	If SaaSOperationsCached.IsSeparatedConfiguration() Then
		ExportImportData.AddTypeExcludedFromUploadingUploads(
			Types,
			Metadata.Catalogs.DataAreaMessages,
			ExportImportData.ActionWithLinksDoNotChange());	
	EndIf;
	
	ExportImportData.AddTypeExcludedFromUploadingUploads(
		Types,
		Metadata.Catalogs.SystemMessages,
		ExportImportData.ActionWithLinksDoNotChange());	
	
	ExportImportData.AddTypeExcludedFromUploadingUploads(
		Types,
		Metadata.ExchangePlans.MessagesExchange,
		ExportImportData.ActionWithLinksDoNotChange());	
	
EndProcedure

// See CommonOverridable.OnDefineSupportedInterfaceVersions.SupportedVersions
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Parameters:
//	SupportedVersionsStructure - See CommonOverridable.OnDefineSupportedInterfaceVersions.SupportedVersions 
//
Procedure OnDefineSupportedInterfaceVersions(Val SupportedVersionsStructure) Export
EndProcedure

// Sets the code of this endpoint, if not set.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
Procedure InstallCodeOfThisEndpoint() Export
EndProcedure

// Transfers the settings of the messaging transport to a new register.
// @skip-warning EmptyMethod - a feature of the implementation.
//
Procedure MigrateMessagingTransportSettings() Export
EndProcedure

#EndRegion

#Region Internal

// A routine task handler for sending and receiving system messages.
// @skip-warning EmptyMethod - a feature of the implementation.
//
Procedure SendAndReceiveMessagesForRoutineTasks() Export
EndProcedure

#EndRegion

