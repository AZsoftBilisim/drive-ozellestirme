
#Region Internal

#Region ObjectEventHandlers

// Called from the corresponding directory handler
//
// Parameters:
//  Object - CatalogObject.ProductCostElements - processed object
//  Cancel - Boolean - If this parameter is set to True in the body of the handler procedure,
//                   it will refuse to continue working after completing the fill check.
//  CheckedAttributes - Array of String - Array of paths to the details to be checked for.
//
Procedure FillCheckProcessing(Object, Cancel, CheckedAttributes) Export
	
	
EndProcedure

// Called from the corresponding directory handler
//
// Parameters:
//  Object - CatalogObject.ProductCostElements - processed object
//  FillingData - Arbitrary - The value that is used as the basis for filling in.
//  StandardProcessing - Boolean - This parameter is passed to indicate that standard (system) event processing is performed.
//
Procedure Filling(Object, FillingData, StandardProcessing) Export
	
	
EndProcedure

// Called from the corresponding directory handler
//
// Parameters:
//  Object - CatalogObject.ProductCostElements - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//
Procedure BeforeWrite(Object, Cancel) Export
	
	
EndProcedure

// Called from the corresponding directory handler
//
// Parameters:
//  Object - CatalogObject.ProductCostElements - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure, the record will not be executed and an exception will be thrown.
//
Procedure OnWrite(Object, Cancel) Export
EndProcedure

#EndRegion


#Region FormEventHandlers

// Called from the corresponding handler of the Form of the directory
//
// Parameters:
// 	Form - ClientApplicationForm - Reference Form
//
Procedure OnReadCreateAtServer(Form) Export
EndProcedure

// Called from the corresponding object form handler
//
// Parameters:
// 	TagName - String - Control name
// 	Form - ClientApplicationForm - Form of the plan of types of characteristics
//
Procedure OnChangeAttribute(TagName, Form) Export
EndProcedure

// Called from the corresponding object form handler
//
// Parameters:
// 	CommandName - String - Command name
// 	Form - ClientApplicationForm - Reference Form
//
Procedure ExecuteCommand(CommandName, Form) Export
	Return;
EndProcedure

#EndRegion

#EndRegion

