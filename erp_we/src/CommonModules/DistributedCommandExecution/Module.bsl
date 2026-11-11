// @strict-types

#Region Public

// Calls the Commands of the specified additional processing and passes the parameters to it,
// registers a message for the MS with the results of the execution.
// Important! Called as a background task.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//	ProcessingID - String - indicates the processing, the command which you want to run.
//	CommandID - String - name of the command (as specified in processing) to execute.
//	OperationID - String - allows you to identify individual calls (for example, for logging).
//	InformManager - Boolean - indicates the need to inform the service Manager about the result of the command execution.
//
Procedure ExecuteAdditionalProcessingCommand(ProcessingID, CommandID, OperationID, InformManager = False) Export
EndProcedure 

// Calls the Command to Transfer the file from the Cur data area to any other 
// data area of the service.
// Important! If any of the parameters are passed incorrectly, an exception is raised.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//	FileName - String - full name of the file to be transmitted.
//	RecipientCode - Number - code of the data area to transfer the file to.
//	FastTransfer - Boolean - specifies that you need to use quick messages to transfer the file. 
//	CallParameters - Structure - Additional call parameters:
//		* Code - Number - response code,
//		* Body - String - response body.
//
// Returns:
//   UUID - the call ID.
//
Function TransferFileToApplication(FileName, RecipientCode, FastTransfer = False, CallParameters = Undefined) Export
EndFunction

// Sends a receipt message to the recipient region about the receipt (End of processing,
// and so on) of the previously received file.
// Important! If any of the parameters are passed incorrectly, an exception is raised.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//	CallID - UUID - previously issued by the function performtransmitfile to the App
//	RecipientCode - Number - code of the data area to send the receipt to.
//	FastTransfer - Boolean - specifies that you need to use quick messages to transfer the file. 
//	CallParameters - Structure - Additional call parameters:
//	  * Code - Number - response code,
//	  * Body - String - response body.
//
Procedure SendFileTransferReceipt(CallID, RecipientCode, FastTransfer = False, CallParameters = Undefined) Export
EndProcedure

// See JobsQueueOverridable.OnDefineHandlerAliases
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Parameters:
//	NamesAndAliasesMap - See JobsQueueOverridable.OnDefineHandlerAliases.NamesAndAliasesMap
//
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export 
EndProcedure

#EndRegion