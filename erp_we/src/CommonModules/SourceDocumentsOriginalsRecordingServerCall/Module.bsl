///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region ObsoleteProceduresAndFunctions

// Deprecated. Instead, use "SourceDocumentsOriginalsRecordingClient.WriteOriginalsStatesAfterPrint". 
// Called to record the original states of print forms to the register after printing the form.
//
//	Parameters:
//  PrintObjects - ValueList - a list of references to print objects.
//  PrintList - ValueList - a list with template names and print form presentations.
//   Written1 - Boolean - indicates that the document state is written to the register.
//
Procedure WriteOriginalsStatesAfterPrint(PrintObjects, PrintList, Written1 = False) Export

	If GetFunctionalOption("UseSourceDocumentsOriginalsRecording") And Not Users.IsExternalUserSession() Then
		SourceDocumentsOriginalsRecording.WhenDeterminingTheListOfPrintedForms(PrintObjects, PrintList);
		If PrintList.Count() = 0 Then
			Return;
		EndIf;
		SourceDocumentsOriginalsRecording.WriteDocumentOriginalsStatesAfterPrintForm(PrintObjects, PrintList, Written1);
	EndIf;

EndProcedure

#EndRegion

#EndRegion

#Region Private

// Saves the new state of a source document.
//	
// Parameters:
//  WritingObjects - Array of Structure - Information on the current document state:
//                 * OverallState 						- Boolean - "True" if the current state is aggregated.
//                 * Ref 								- DocumentRef - A reference to the document whose source document's state should be changed.
//                 * SourceDocumentOriginalState - CatalogRef.SourceDocumentsOriginalsStates -
//                                                           Current state of the source document original.
//                 * SourceDocument 					- String - Source document ID. Required if the state is not aggregated.
//                 * FromOutside 								- Boolean - "True" if the source document was added manually. It's required if the current state is not aggregated. 
//               - DocumentRef - A reference to the document whose source document's state should be changed.
//  OriginalState - String - The state to be applied.
// 
// Returns:
//  String - "IsChanged" is the source document state is not repeated and was saved.
//           "NotIsChanged" 
//           "NotCarriedOut" 
//
Function SetNewOriginalState(Val WritingObjects, Val OriginalState) Export

	Return SourceDocumentsOriginalsRecording.SetNewOriginalState(WritingObjects, OriginalState);

EndFunction

// Returns a reference to the document by the spreadsheet document barcode
//
// Parameters:
//  Barcode - String - the scanned document barcode.
//
Procedure ProcessBarcode(Barcode) Export
	
	SourceDocumentsOriginalsRecording.ProcessBarcode(Barcode);

EndProcedure

// Returns a structure with the data on the source document's current aggregated state by reference.
//
//	Parameters:
//  DocumentRef - DocumentRef - The reference to the document whose aggregated state info should be received. 
//
//  Returns:
//    Structure - General information about the source document state:
//    * Ref - DocumentRef - document reference;
//    * SourceDocumentOriginalState - CatalogRef.SourceDocumentsOriginalsStates - the current
//        state of a document original.
//
Function OriginalStateInfoByRef(DocumentRef) Export

	Return SourceDocumentsOriginalsRecording.OriginalStateInfoByRef(DocumentRef);
	
EndFunction

// Fills in the drop-down choice list of states on the form.
// 
//	Parameters:
//  OriginalStatesChoiceList - ValueList - original states available to users and used when
//                                                    changing the original state.
//
Procedure FillOriginalStatesChoiceList(OriginalStatesChoiceList) Export
	
	OriginalStatesChoiceList.Clear();
	OriginalsStates = SourceDocumentsOriginalsRecording.UsedStates();
	
	For Each State In OriginalsStates Do

		If State.Ref = Catalogs.SourceDocumentsOriginalsStates.OriginalReceived Then 
			OriginalStatesChoiceList.Add(State.Description,,,PictureLib.SourceDocumentOriginalStateOriginalReceived);
		ElsIf State.Ref = Catalogs.SourceDocumentsOriginalsStates.FormPrinted Then
			OriginalStatesChoiceList.Add(State.Description,,,PictureLib.SourceDocumentOriginalStateOriginalNotReceived);
		Else
			OriginalStatesChoiceList.Add(State.Description);
		EndIf;

	EndDo;
EndProcedure

// Checks and returns a flag indicating whether the document by reference is a document with originals recording.
//
//	Parameters:
//  ObjectRef - DocumentRef - a reference to the document to be checked.
//
//	Returns:
//  Boolean - True if the document is an object with originals recording.
//
Function IsAccountingObject(ObjectRef) Export
	
	Return SourceDocumentsOriginalsRecording.IsAccountingObject(ObjectRef);

EndFunction

// Returns the record key of the source document's aggregated state by reference.
//
//	Parameters:
//  DocumentRef - DocumentRef - The reference to the document whose aggregated state record key should be received.
//
//	Returns:
//  InformationRegisterRecordKey.SourceDocumentsOriginalsStates - The record key of the source document's aggregated state.
//
Function OverallStateRecordKey(DocumentRef) Export

	Return SourceDocumentsOriginalsRecording.OverallStateRecordKey(DocumentRef);

EndFunction

// Returns the reference to the source document's original state by catalog by UUID.
//
//	Parameters:
//  CommandName - String- Name of the form command being executed. 
//
//  Returns:
//    CatalogRef.SourceDocumentsOriginalsStates - Reference to the source document state.
//
Function SourceDocumentOriginalStateByCommandName(Val CommandName) Export  
	
	UIDOfState = StrReplace(StrReplace(CommandName, "Command", ""), "_", "-");
	UIDOfState = New UUID(UIDOfState);
	Return Catalogs.SourceDocumentsOriginalsStates.GetRef(UIDOfState);
	
EndFunction

// Called to record original states of print forms in the register after printing the form.
//
//	Parameters:
//  PrintObjects - ValueList - List of references to print objects.
//  PrintList - ValueList - List with template names and print form presentations.
//   Written1 - Boolean - Indicates that the document state is written to the register.
//
Procedure WriteOriginalsStatesAfterPrintingForms(PrintObjects, PrintList, Written1 = False) Export

	If GetFunctionalOption("UseSourceDocumentsOriginalsRecording") And Not Users.IsExternalUserSession() Then
		SourceDocumentsOriginalsRecording.WhenDeterminingTheListOfPrintedForms(PrintObjects, PrintList);
		If PrintList.Count() = 0 Then
			Return;
		EndIf;
		SourceDocumentsOriginalsRecording.WriteDocumentOriginalsStatesAfterPrintForm(PrintObjects, PrintList, Written1);
	EndIf;

EndProcedure 

#EndRegion
