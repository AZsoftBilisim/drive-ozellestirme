
#Region Private

// Server handler for the event processingreceiving form enum Selectionopenable system worksystem Start.
//
Procedure FormsOpenedWhenSystemStartsProcessingSelectionDataAcquisition(ChoiceData, Parameters, StandardProcessing) Export
	
	If GetFunctionalOption("BaseVersion") Then
		StandardProcessing = False;
		OpenFormsOnApplicationStart.FormsUsedWhenStartingSystem(ChoiceData, Parameters);
	EndIf;
	
EndProcedure

// Returns the name of the form to open in order to configure the program on first launch.
//
// Returns:
//  String - Initial program setup form
Function InitialProgramSetupForm() Export
	
	// Let's return the name of the first launch assistant form
	SetPrivilegedMode(True);
	
	FormName = "";
	Return FormName;
	
EndFunction

#EndRegion
