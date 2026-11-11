// @strict-types

#Region Public

// Returns the storage ID as a string.
// @skip-check module-empty-method - a feature of the implementation.
// @skip-warning - Backward compatibility.
// 
// Returns:
//	String - storage ID. 
//
Function StorageID() Export
EndFunction

// Returns a new structure for the description of the returned data.
// @skip-check module-empty-method - a feature of the implementation.
// @skip-warning - Backward compatibility.
// 
// Returns:
//	Structure:
//	 * ModuleManager_ - CommonModule, CatalogsManager, ReportsManager - module for the data acquisition Manager.
//	 * Description - String - name of the returned data.
//	 * LongDesc - String - detailed description of the returned data.
//	 * ResultTypes - Array of String - types of returned data.
//	 
Function NewDescriptionOfReturnedData() Export
EndFunction

// Returns a list of available data
// @skip-check module-empty-method - a feature of the implementation.
// @skip-warning - Backward compatibility.
// 
// Returns:
//	Map of KeyAndValue - list of available returned data:
//	 * Key - String - data ID.
//	 * Value - See AsyncDataReceipt.NewDescriptionOfReturnedData
//	
Function AvailableReturnData() Export
EndFunction

// See JobsQueueOverridable.OnDefineHandlerAliases.
// @skip-check module-empty-method - a feature of the implementation.
// @skip-warning - Backward compatibility.
// 
// Parameters:
//  NamesAndAliasesMap - See JobsQueueOverridable.OnDefineHandlerAliases.NamesAndAliasesMap
// 
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export
EndProcedure

#Region JobsQueueHandlers

// Generates data for the response based on the received parameters.
// @skip-check module-empty-method - a feature of the implementation.
// @skip-warning - Backward compatibility.
//
// Parameters:
//	DataID - String - the identifier of the data you want to retrieve.
//	ParameterId_ - UUID - ID of the data acquisition parameters file.
//
Procedure PrepareData(DataID, ParameterId_) Export
EndProcedure

#EndRegion

#EndRegion
 
