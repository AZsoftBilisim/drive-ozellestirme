//////////////////////////////////////////////////////////////////////////////////////////////
// Document verification: methods that work on the server side, called from the client side.
//  
//////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Executes the "Check" command of the document. If there are no rights to change The Verification Status, it does nothing,
// otherwise it changes the value Of The Document Verification Status.
// See InformationRegisters.StatusOfDocumentVerification.SetStatusOfDocumentVerification.
//
// Parameters:
//  DocumentRef - DocumentRef - The document for which you want to change the Status of the check
//	(see Dimension "Document" of the register of information "Statusproverkidocuments") ;
//	ErrorData - Map - data matching (if not specified, error data is not recorded)
//
//	Return value:
//		Boolean - True if there is a right to change the document, False otherwise.
//
Procedure ExecuteCommandToChangeDocumentVerificationStatus(DocumentRef, ErrorData = Undefined) Export
	
	InformationRegisters.StatusOfDocumentVerification.SetStatusOfDocumentVerification(DocumentRef, ErrorData);
	
EndProcedure

#EndRegion