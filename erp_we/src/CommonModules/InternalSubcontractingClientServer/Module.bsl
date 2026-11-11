////////////////////////////////////////////////////////////////////////////
// The "Internal Processing Client Server" module contains procedures and functions for 
// working with the internal processing mechanism.
//
////////////////////////////////////////////////////////////////////////////

#Region Public

#Region StructureOfActions

// Adds the action "Fill in the ownership of the available item" to the action structure
//
// Parameters:
//  Form             - ClientApplicationForm - the form in which the action structure is formed
//  StructureOfActions - Structure        - structure of actions
// 
Procedure AddActionFillInItemOwnerIsAvailable(Form, StructureOfActions) Export
	
	If Not Form.UseInternalSubcontracting Then
		Return;
	EndIf;
	
	StructureOfActions.Insert("FillInProductOwnerIsAvailable");
	
EndProcedure

#EndRegion

#EndRegion