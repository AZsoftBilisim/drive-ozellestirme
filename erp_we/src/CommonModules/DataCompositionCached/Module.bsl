#Region Public

#Region MethodsAndExpressionsOfDataLayoutSystem

// Returns a unique ID based on the object reference
// Intended for use in SKD expressions.
//
// Parameters:
//	ObjectReference - AnyRef - any link
//
// Returns:
//	UUID
//
Function UUID(ObjectReference) Export
	UUID = Undefined;
	
	If Common.IsReference(TypeOf(ObjectReference)) Then
		UUID = ObjectReference.UUID();
	EndIf;
	
	Return UUID;
EndFunction

// Returns a string representation of the document for use in SCD expressions
//
// Parameters:
//	Document - DocumentRef - link to the document
//	Number -String - document number
//	Date - Date - Document date
//
// Returns:
//	String - presentation of the document.
//
Function PresentationOfDocument(Document, Number = Undefined, Date = Undefined) Export
	PresentationOfDocument = "";
	
	If Common.IsReference(TypeOf(Document)) Then
		PresentationOfDocument = TMCommonUse.GetDocumentPresentation(Document, Number, Date);
	EndIf;
	
	Return PresentationOfDocument;
EndFunction

Function PeriodBoundary(Date, BorderViewValueName) Export
	Return New Boundary(Date, BoundaryType[BorderViewValueName]);
EndFunction

// Returns an unprintable character by name
//
// Parameters:
//	SymbolName - String - the name of a non-printable character as it is specified in the system enumeration of Characters.
//
// Returns:
//	String - symbol value
//
Function SymbolValue(SymbolName) Export
	ReturnedCharacter = "";
	
	If SymbolName = "CR" Then
		ReturnedCharacter = Chars.CR;
	ElsIf SymbolName = "VTab" Then
		ReturnedCharacter = Chars.VTab;
	ElsIf SymbolName = "NBSP" Then
		ReturnedCharacter = Chars.NBSp;
	ElsIf SymbolName = "LF" Then
		ReturnedCharacter = Chars.LF;
	ElsIf SymbolName = "PF" Then
		ReturnedCharacter = Chars.FF;
	ElsIf SymbolName = "Tab" Then
		ReturnedCharacter = Chars.Tab;
	EndIf;
	
	Return ReturnedCharacter
EndFunction

// Replace The Full Analogue for use in DCS Expressions
//
// Parameters:
//  String          - String - original string. 
//  SearchSubstring - String - The substring you are looking for. 
//  ReplaceSubstring - String - Substring to replace the search substring with. 
//
// Returns:
//  String - obtained as a result of replacement.
//
Function RowReplaceLayout(String, SearchSubstring, ReplaceSubstring) Export
	Return StrReplace(String, SearchSubstring, ReplaceSubstring);
EndFunction

#EndRegion 
	
#EndRegion 