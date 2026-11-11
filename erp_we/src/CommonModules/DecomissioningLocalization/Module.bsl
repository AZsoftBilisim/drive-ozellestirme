////////////////////////////////////////////////////////////////////////////////
// Procedures used to localize the Decommissioning document.
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Private

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	
EndProcedure

Procedure AddRequestTexts(Query, QueryTexts, Registers) Export

	
EndProcedure

Procedure FillCheckProcessing(Object, Cancel, CheckedAttributes) Export
	
	
EndProcedure

#EndRegion

#Region ConductingLocalAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	QueryText = "";


	Return QueryText;

EndFunction

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	

EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	

EndProcedure


#EndRegion

#Region Form

Procedure ConfigureDependentFormElements(Form, ChangedBankingDetails) Export
	
	
EndProcedure

#EndRegion

#EndRegion
