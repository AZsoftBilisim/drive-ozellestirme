// @strict-types

#Region Public

// Called when creating a list of available returned data and when receiving data. 
// Defines the list of returned data connected to the subsystem.
// @skip-warning EmptyMethod - Overridable method.
// 
// Parameters:
//  AvailableReturnData - Map of KeyAndValue - fillable available returned data:
//    * Key - String - data ID.
//    * Value - See AsyncDataReceipt.NewDescriptionOfReturnedData
//
Procedure SetAvailableReturnData(AvailableReturnData) Export
EndProcedure

// Called during the initial processing of an incoming request. Allows you to execute the application logic
// associated with validating an incoming request and, if necessary, refuse to process the request.
// @skip-warning EmptyMethod - Overridable method.
// 
// Parameters:
//  DataID - String - data ID. Can be overridden during processing.
//                                 Specified as the file name returned in the result.
//  Parameters - BinaryData - passed parameters for getting data.
//  Cancel - Boolean - The returned parameter. Indicates that authorization was denied. If authorization is refused, set to Denial = True.
//  ErrorMessage - String - Return parameter. Text of the error message when authorization was denied.
//  
Procedure AuthorizeRequest(DataID, Parameters, Cancel, ErrorMessage) Export
EndProcedure

#EndRegion