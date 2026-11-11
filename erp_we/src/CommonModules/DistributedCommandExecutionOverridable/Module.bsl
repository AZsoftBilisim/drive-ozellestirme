// @strict-types

#Region Public

// Called when a message is received about file Transfer from another data area.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//	FileName - String - full name of the file to be transmitted.
//	CallID - UUID - to identify a specific call
//	SenderCode - Number - code of the data area from which the file was transmitted.
//	CallParameters - Structure - additional call parameters,
//						*Code (Number), *Body (String).
//	Processed - Boolean - indicates whether the message was processed successfully.
//
Procedure ProcessFileTransferRequest(FileName, CallID, SenderCode, CallParameters, Processed) Export

EndProcedure

// Called when a "Success" receipt is received for Transferring a file from another data area.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//	CallID - UUID - to identify a specific call
//	SenderCode - Number - code of the data area from which the file was transmitted.
//	CallParameters - Structure - additional call parameters,
//						*Code (Number), *Body (String).
//	Processed - Boolean - indicates whether the message was processed successfully.
//
Procedure ProcessResponseToFileTransfer(CallID, SenderCode, CallParameters, Processed) Export

EndProcedure

// Called when an "Error" receipt is received for Transferring a file from another data area.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//	CallID - UUID - to identify a specific call
//	SenderCode - Number - code of the data area from which the file was transmitted.
//	ErrorText - String - description of the error that occurred 
//	Processed - Boolean - indicates whether the message was processed successfully.
//
Procedure HandleFileTransferError(CallID, SenderCode, ErrorText, Processed) Export

EndProcedure

#EndRegion