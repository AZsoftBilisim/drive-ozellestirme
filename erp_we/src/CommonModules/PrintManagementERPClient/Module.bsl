
#Region Public

// Called after the handler is executed when opening the document printing form (General Form.Print documents).
//
// Parameters:
//  Form - ClientApplicationForm - General Form.Print documents.
//
Procedure PrintDocumentsAfterOpen(Form) Export
	
	
EndProcedure


#Region ProductionOrder2_2

// Opens a form for forming a printed form for the production stage.
//
// Parameters:
//  CommandDetails - Structure - information about the command being executed.
//
// Returns:
//	Undefined
//
Function PrintJobForProduction(CommandDetails) Export
	
	FormParameters = New Structure("PrintObjects", CommandDetails.PrintObjects);
	
	OpenForm(
		"Document.ProductionStage2_2.Form.PrintParametersProductionJob",
		FormParameters,
		CommandDetails.Form);
	
EndFunction

// Opens a form for forming a printed form for the batch of the production stage.
//
// Parameters:
//  CommandDetails - Structure - information about the command being executed.
//
// Returns:
//	Undefined
//
Function PrintingProductionBatchSheets(CommandDetails) Export
	
	OpenForm(
		"Document.ProductionStage2_2.Form.PrintAccompanyingSheetForProductionLot",
		New Structure("PrintObjects", CommandDetails.PrintObjects),
		CommandDetails.Form);
	
EndFunction

#EndRegion

#Region WorkCenters

// Opens a form for creating a work center label or displays a printed form.
//
// Parameters:
//  CommandDetails - Structure - information about the command being executed.
//
// Returns:
//	Undefined
//
Function PrintWorkCenterLabel(CommandDetails) Export
	
	If CommandDetails.Form.FormName = "Catalog.WorkCenters.Form.ItemForm" Then
	
		OpenForm(
			"Catalog.WorkCenters.Form.PrintParametersWorkCenterLabel",
			New Structure("PrintObjects", CommandDetails.PrintObjects),
			CommandDetails.Form);
		
	EndIf;
	
EndFunction

#EndRegion

#EndRegion

#Region Private


#EndRegion
