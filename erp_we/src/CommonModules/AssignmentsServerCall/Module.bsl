
#Region Private

// Server-side event handler for receiving data from the Target directory Selection.
//
Procedure AssignmentsProcessingOfSelectionDataAcquisition(ChoiceData, Parameters, StandardProcessing) Export
	
	StandardProcessing = False;
	ChoiceData = Catalogs.Assignments.FillInSelectionData(Parameters);
	
EndProcedure

Procedure AddPartnerExclusionSelection(FiltersStructure) Export
	
	Catalogs.Assignments.AddPartnerExclusionSelection(FiltersStructure);
	
EndProcedure

#EndRegion

