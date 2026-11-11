#Region Public

// Fills in the service details in the tabular part of the form depending on the localization
//
// Parameters:
//   Form               - ClientApplicationForm - form to fill in
//   FillParameters - Arbitrary     - the script and the fill parameters
//
Procedure FillInServiceDetails(Form, FillParameters = Undefined) Export
	
	
EndProcedure

#EndRegion

#Region Internal

// Description of collection string handlers:
// 
// Parameters:
//  StringHandlers - ValueList of String - Name of the handler for a row in the table part:
//  * Presentation - String - the export method is ready for execution.
//
Procedure WhenAddingCollectionLineHandlers(StringHandlers) Export
	
	
EndProcedure

// Description of the query texts that need to be executed to get all the necessary data required for 
// string processing.
// 
// Parameters:
//  Actions - See BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions.
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure AddQueryTextsOfDataSources(Actions, QueryDetails, CachedValues) Export
	
	
EndProcedure

Procedure FillInServiceDetailsForProductInLineTS(StructureOfActions, StructureOfFillingActions) Export
	
	
EndProcedure

Procedure WhenDefiningSampleFieldTemplateByActionKey(ActionKey, Template) Export
	
	
EndProcedure

Procedure WhenDefiningRequestTemplateUsingServiceDetailsOfTS(PartOfRequestTemplate, StructureOfActions, BatchProcessing) Export
	
	Return;
	
EndProcedure

#EndRegion

#Region Private


#EndRegion
