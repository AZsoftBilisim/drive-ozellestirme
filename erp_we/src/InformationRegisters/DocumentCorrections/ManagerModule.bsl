#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the document to be corrected (the first document in the chain) by correction
//
//	Parameters:
//		Patch - DocumentRef - Patch
//	
//	Returns:
//		DocumentRef -
//
Function CorrectedDocument(Val Patch) Export
	
	CorrectedDocument = Undefined;
	
	Query = New Query;
	Query.SetParameter("Patch", Patch);
	
	Query.Text = 
	
	"SELECT
	|	DocumentCorrections.CorrectedDocument
	|FROM
	|	InformationRegister.DocumentCorrections AS DocumentCorrections
	|WHERE
	|	DocumentCorrections.Recorder = &Patch";
	
	Result = Query.Execute();
	
	If Not Result.IsEmpty() Then
	
		Selection = Result.Select();
		Selection.Next();
		CorrectedDocument = Selection.CorrectedDocument;	
	EndIf;
	
	Return CorrectedDocument;
	
EndFunction

// Returns document corrections
//
// Parameters:
//	CorrectedDocument - DocumentRef - The document for which corrections are required
//
// Returns:
// 	Array of DocumentRef - Array of document corrections.
//
Function CorrectionsOfDocument(Val CorrectedDocument) Export
	
	CorrectionsOfDocument = New Array;
	
	Query = New Query;
	Query.SetParameter("CorrectedDocument", CorrectedDocument);

	Query.Text = 
	
	"SELECT
	|	DocumentCorrections.Recorder
	|FROM
	|	InformationRegister.DocumentCorrections AS DocumentCorrections
	|WHERE
	|	DocumentCorrections.CorrectedDocument = &CorrectedDocument
	|";
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		CorrectionsOfDocument.Add(Selection.Recorder);	
	EndDo;
	
	Return CorrectionsOfDocument;
	
EndFunction

// Returns document corrections by correction document type
//
// Parameters:
//	CorrectedDocuments - Array of DocumentRef - documents that require corrections
//	CorrectionType - String - type of correction document
//
// Returns:
// 	Array of DocumentRef - An array of document corrections.
//
Function CorrectionsOfDocumentsByTypeOfCorrection(Val CorrectedDocuments, Val CorrectionType) Export
	
	DocumentCorrections = New Array;
	
	Query = New Query;
	
	Query.Text = 
	
	"SELECT
	|	DocumentCorrections.Recorder
	|FROM
	|	InformationRegister.DocumentCorrections AS DocumentCorrections
	|WHERE
	|	DocumentCorrections.CorrectedDocument IN (&CorrectedDocuments)";	
	
	FilterTemplate = "AND DocumentCorrections.Recorder Ref %1";
	FilterText1 = StrTemplate(FilterTemplate, CorrectionType);
	
	Query.Text = Query.Text + FilterText1;
	
	Query.SetParameter("CorrectedDocuments", CorrectedDocuments);

	Result = Query.Execute();
	
	If Not Result.IsEmpty() Then
		Selection = Result.Select();
		
		While Selection.Next() Do
			DocumentCorrections.Add(Selection.Recorder);	
		EndDo;
	
	EndIf;
	
	Return DocumentCorrections;
	
EndFunction

// Function-constructor of parameters for checking the case of corrections of documents.
// 
// Returns:
// 	Structure - LongDesc:
// * Ref - DocumentRef, Undefined - Recorders of the register of information corrections of documents
// * Date - Date
// * CorrectedDocument - DocumentRef, Undefined - See DefinedType.CorrectedDocuments
//
Function DocumentCorrectionVerificationParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("Ref", Undefined);
	Parameters.Insert("Date", Date(1, 1, 1));
	Parameters.Insert("CorrectedDocument", Undefined);
	
	Return Parameters;
	
EndFunction

// Checks whether the Recorders parameters have changed relative to the stored entries in the Document Correction register.
//
// Parameters:
//  CheckParameters - See DocumentCorrectionVerificationParameters
// 
// Returns:
//  Boolean - True - the parameters have changed, False - not.
//
Function ParametersForCorrectingDocumentsHaveChanged(CheckParameters) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	DocumentCorrections.Period,
		|	DocumentCorrections.CorrectedDocument
		|FROM
		|	InformationRegister.DocumentCorrections AS DocumentCorrections
		|WHERE
		|	DocumentCorrections.Active = TRUE
		|	AND DocumentCorrections.Recorder = &Recorder
		|	AND DocumentCorrections.CorrectedDocument = &CorrectedDocument
		|	AND DocumentCorrections.Period = &Period";
		
	Query.SetParameter("Recorder", CheckParameters.Ref);
	Query.SetParameter("CorrectedDocument", CheckParameters.CorrectedDocument);
	Query.SetParameter("Period", CheckParameters.Date);
	Result = Query.Execute().IsEmpty();
	
	Return Result;
	
EndFunction

// Returns the correction document after the date of the document being checked.
//
// Parameters:
//  CheckParameters - See DocumentCorrectionVerificationParameters
// 
// Returns:
//  DocumentRef, Undefined - Recorders of the register of Register entries.Correctedocuments
//
Function CorrectionAfterDocumentDate(CheckParameters) Export
	
	SetPrivilegedMode(True);
	
	CorrectionAfterDocumentDate = Undefined;
	
	// Determine the presence of corrections greater than the date of the document
	Query = New Query;
	Query.Text = 
		"SELECT TOP 1
		|	DocumentCorrections.Recorder
		|FROM
		|	InformationRegister.DocumentCorrections AS DocumentCorrections
		|WHERE
		|	DocumentCorrections.CorrectedDocument = &CorrectedDocument
		|	AND NOT DocumentCorrections.Recorder = &Ref
		|	AND DocumentCorrections.Period >= &Date
		|
		|ORDER BY
		|	DocumentCorrections.Period DESC";
	
	Query.SetParameter("Ref", CheckParameters.Ref);
	Date = ?(
		Not ValueIsFilled(CheckParameters.Ref) And CheckParameters.Date = BegOfDay(CurrentSessionDate()),
		CurrentSessionDate(),
		CheckParameters.Date);
	Query.SetParameter("Date", Date);
	Query.SetParameter("CorrectedDocument", CheckParameters.CorrectedDocument);
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		CorrectionAfterDocumentDate = Selection.Recorder;
	EndIf;
	
	Return CorrectionAfterDocumentDate;
	
EndFunction

// Returns an indication of whether the document has current corrections as of the date 
//
// Parameters:
//	CorrectedDocument - DocumentRef - Document being corrected
//	ReversedDocument - DocumentRef - the document being cancelled
//	Date - Date - Date of verification
//
// Returns:
// 	Boolean - If True, there are actual corrections for the document being canceled
//
Function AvailabilityOfCorrectionsAsOfDocumentDate(CorrectedDocument, ReversedDocument, Date) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	DocumentCorrectionsSliceLast.CorrectedDocument AS CorrectedDocument,
		|	DocumentCorrectionsSliceLast.LastChainDocument AS LastChainDocument
		|FROM
		|	InformationRegister.DocumentCorrections.SliceLast(
		|		&Period, CorrectedDocument = &CorrectedDocument) AS DocumentCorrectionsSliceLast
		|WHERE
		|	NOT DocumentCorrectionsSliceLast.LastChainDocument = UNDEFINED
		|	AND NOT DocumentCorrectionsSliceLast.LastChainDocument = &ReversedDocument
		|	AND NOT DocumentCorrectionsSliceLast.LastChainDocument.Date < &DateOfDocumentBeingCancelled";
	
	Query.SetParameter("Period", Date);
	Query.SetParameter("CorrectedDocument", CorrectedDocument);
	Query.SetParameter("ReversedDocument", ReversedDocument);
	Query.SetParameter("DateOfDocumentBeingCancelled", Common.ObjectAttributeValue(ReversedDocument, "Date"));
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

#EndRegion

#EndIf