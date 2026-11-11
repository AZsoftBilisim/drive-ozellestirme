
#Region Public

// Defines a list of exchange plans that use the functionality of the data exchange subsystem.
//
// See DataExchangeOverridable.GetExchangePlans
//
Procedure GetExchangePlans(SubsystemExchangePlans) Export
	
	
EndProcedure

// Handler for registering changes for the initial data upload.
// 
// See DataExchangeOverridable.InitialDataExportChangesRegistration
//
Procedure InitialDataExportChangesRegistration(Val Recipient, StandardProcessing, Filter) Export
	
	
EndProcedure

// Handler for uploading data.
// See DataExchangeOverridable.OnDataExport
Procedure OnDataExport(StandardProcessing,
								Recipient,
								MessageFileName,
								MessageData,
								TransactionItemsCount,
								EventLogEventName,
								SentObjectsCount) Export
	
EndProcedure


// Handler for when data is loaded.
// See DataExchangeOverridable.OnDataImport
Procedure OnDataImport(StandardProcessing,
								Sender,
								MessageFileName,
								MessageData,
								TransactionItemsCount,
								EventLogEventName,
								ReceivedObjectsCount) Export
	
EndProcedure

// Retrieves available versions of the universal EnterpriseData format.
//
// See DataExchangeOverridable.OnGetAvailableFormatVersions
//
Procedure OnGetAvailableFormatVersions(FormatVersions) Export
	
	
EndProcedure

// Handler in case of collision of data changes.
// See DataExchangeOverridable.OnDataChangeConflict
//
Procedure OnDataChangeConflict(Val DataElement, ItemReceive, Val Sender, Val GetDataFromMasterNode) Export
	
	
EndProcedure

// Handler for the initial configuration of the IB after creating the rib node.
// Called when the subordinate rib node is first started (including the APM).
//
Procedure OnSetUpSubordinateDIBNode() Export
	
	
EndProcedure


// Retrieves available extensions for the universal EnterpriseData format.
// See DataExchangeOverridable.OnGetAvailableFormatExtensions
//
Procedure OnGetAvailableFormatExtensions(FormatExtensions) Export
EndProcedure

#EndRegion