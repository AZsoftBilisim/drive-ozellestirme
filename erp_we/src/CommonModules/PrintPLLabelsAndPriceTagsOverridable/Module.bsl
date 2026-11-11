#Region Public

// Called when creating a form for processing the print of the label of the price tags.
//
// Parameters:
//   Form - ClientApplicationForm - processing form
//
Procedure FormPrintsLabelsAndPriceTagsWhenCreatedOnServer(Form) Export
	
EndProcedure

// Called when creating the form of the template element, the label of the price tags is called.
//
// Parameters:
//   Form - ClientApplicationForm - processing form
//
Procedure FormTemplatesOfLabelsAndPriceTagsOfBPOWhenCreatingOnServer(Form) Export
	
EndProcedure

// Returns data for building templates and printed forms.
// 
// Parameters:
//  PrintParameters - Structure - Fields to Fill - Array -
//  FieldsForFillIn - Array of Structure - Fields to fill in
//  ProductsForPrinting - Array Structure
// 
// Returns:
//  Array of Structure - Data for the formation of printed forms
Function DataForFormationOfPrintedForms(PrintParameters, FieldsForFillIn, ProductsForPrinting = Undefined) Export
	
	
	
EndFunction

// Returns the layout of the standard data layout scheme for processing and printing data.
//  Parameters:
//   TypeOfPriceTag - String
// 
// Returns:
//  DataCompositionSchema
Function DataLayoutTemplate(TypeOfPriceTag = "") Export
	
	
	
EndFunction

// When determining the redefinition of the selection of goods.
// 
// Parameters:
//  Use - Boolean - Use
Procedure WhenDeterminingRedefinitionOfSelectionOfGoods(Use) Export
	
	Use = False;
	
EndProcedure

// When determining the redefinition of the selection by barcode.
// 
// Parameters:
//  Use - Boolean - Use
Procedure WhenDeterminingWhetherToOverrideBarcodeMatching(Use) Export
	
	Use = False;
	
EndProcedure

// When determining the redefinition of working with TSD.
// 
// Parameters:
//  Use - Boolean - Use
Procedure WhenDeterminingRedefinitionOfVTSDUpload(Use) Export
	
	Use = False;
	
EndProcedure

// When determining the redefinition of the selection of goods.
// 
// Parameters:
//  Use - Boolean - Use
Procedure WhenDeterminingRedefinitionOfSelection(Use) Export
	
	Use = True;
	
EndProcedure

// Called when the price type changes on the form.
// 
// Parameters:
//   Form - ClientApplicationForm - processing form
Procedure WhenChangingPriceType(Form) Export
	
EndProcedure

// Called when the price type changes on the form.
// 
// Parameters:
//   Templates - Array of Structure - Array Of Templates
Procedure UpdateLabelTemplates(Templates) Export
	
EndProcedure

// Supplements the columns of the table of product values if necessary
//
// Parameters:
//  StandardProcessing - Boolean - indicates standard processing.
//  TableOfProductValues - ValueTable - template for a table of values with columns.
//
Procedure TableOfProductValues(StandardProcessing, TableOfProductValues) Export
	
EndProcedure

// Additional overridable actions with the managed form in the label editor
// at the "Opening" event.
//
// Parameters:
//  Var_ThisObject - ClientApplicationForm - 
//  Cancel - Boolean - A sign of refusal to create a form
//  Parameters - FormDataStructure - Shape parameter
//  StandardProcessing - Boolean - Indicates whether standard processing is being performed
//
Procedure LabelEditorFormOfEditingTemplateWhenCreatingOnServer(Var_ThisObject, Cancel, Parameters, StandardProcessing) Export
	
EndProcedure
#EndRegion
