////////////////////////////////////////////////////////////////////////////////
// The module "Activity Directionsclientserver" contains procedures
// related to the interactive work of the user in the forms of documents.
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Outdated. You must use the assignationclientserver.The structure of the action to add addendesreferences
// It is intended for use in forms and documents in event handlers that lead to a change in the assignment in
// the row of the table part of the document. Adds an action to the structure of actions, which is worked out by the mechanisms
// for processing table parts (See BatchProcessingOfTablePartClient.ProcessTSString)
// Performing such
// an action updates the assignment in the row of the tabular part of the document, in accordance with the changed direction of activity.
//
// Parameters:
//  Form - ClientApplicationForm - A form in which you need to perform an action to process a row in the table part.
//  StructureOfActions - Structure - The structure of actions used by the mechanisms of processing table parts (See BatchProcessingOfTablePartClient.ProcessTSString)
//                                  .
//
Procedure StructureOfInsertActionsWhenAddingRow(Form, StructureOfActions) Export
	
	AssignmentsClientServer.StructureOfInsertActionsWhenAddingRow(Form, StructureOfActions, True);
	
EndProcedure

// Outdated. You must use the assignationclientserver.Fill in the assignment of the form separately
// Fills in the invisible Destination field in documents based on the completed field Separately.
// 
// Parameters:
//  Form - ClientApplicationForm - A form in which you need to perform an action to process a row in the table part.
//  CurrentRow - FormDataCollectionItem - the line where you need to fill in the assignment based on the separate flag.
//
Procedure FillAssignmentByFlagSeparately(Form, CurrentRow) Export
	
	AssignmentsClientServer.FillAssignmentByFlagSeparately(Form, CurrentRow, True);
	
EndProcedure

#EndRegion

