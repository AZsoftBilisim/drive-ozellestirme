#Region Private

Function DocumentCorrectionHyperlink(CorrectedDocument, CorrectiveDocument = Undefined) Export
	
	Return DocumentCorrection.DocumentCorrectionHyperlink(CorrectedDocument, CorrectiveDocument);
	
EndFunction

// Returns the document to be corrected (the first document in the chain) by correction
//
//	Parameters:
//		Patch - DocumentRef - Patch
//	
//	Returns:
//		DocumentRef -
//
Function CorrectedDocument(Val Patch) Export
	
	Return DocumentCorrection.CorrectedDocument(Patch);
	
EndFunction

// Returns the last correction document.
// 
// Parameters:
//  CorrectedDocument - DocumentRef - Document being corrected
// 
// Returns:
//  Undefined, Structure - The Last Corrective Document:
// 	* Ref - DocumentRef - link to the document
// 	* Number  - String - document number
// 	* Date - Date - Document date 
// 	* ReversedDocument - DocumentRef - Link to the document being cancelled
Function LastCorrectiveDocument(Val CorrectedDocument) Export
	
	Return DocumentCorrection.LastCorrectiveDocument(CorrectedDocument);
	
EndFunction

#EndRegion