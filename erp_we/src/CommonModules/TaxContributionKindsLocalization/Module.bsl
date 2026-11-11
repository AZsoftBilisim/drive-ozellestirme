
#Region Public

//Called when the directory is initially filled in.
//
// Parameters:
//  LanguagesCodes - Array - list of configuration languages. Relevant for multilingual configurations.
//  Items   - ValueTable - fill-in data. The composition of columns corresponds to the set of reference book details.
//  TabularSections - Structure - Key - Name of the table part of the object.
//                               Value-Uploads an empty table part to the table of values.
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export

	

EndProcedure

// Name of the predefined element.
// 
// Parameters:
//  PredefinedItemName - String - Name of the predefined element
// 
// Returns:
//  String - Name Of The Predefined Element
Function NameOfPredefinedElement(PredefinedItemName) Export
	
EndFunction


#EndRegion

#Region Internal

Procedure ChoiceFormOnCreateAtServer(Form, Cancel, StandardProcessing) Export
EndProcedure

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing) Export
EndProcedure

#EndRegion

#Region Private


#EndRegion
