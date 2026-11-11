#Region Public

#Region ObjectEventHandlers

// Called from the corresponding object module handler
//
// Parameters:
//  Object - CatalogObject.LinesOfBusiness - processed object
//  Cancel - Boolean - If this parameter is set to True in the body of the handler procedure,
//                   it will refuse to continue working after completing the fill check.
//  CheckedAttributes - Array of String - Array of paths to the details to be checked for.
//
Procedure FillCheckProcessing(Object, Cancel, CheckedAttributes) Export
	
	
EndProcedure

// Called from the corresponding object module handler
//
// Parameters:
//  Object - CatalogObject.LinesOfBusiness - processed object
//  FillingData - Arbitrary - The value that is used as the basis for filling in.
//  StandardProcessing - Boolean - This parameter is passed to indicate that standard (system) event processing is performed.
//
Procedure Filling(Object, FillingData, StandardProcessing) Export
	
	
EndProcedure

// Called from the corresponding object module handler
//
// Parameters:
//  Object - CatalogObject.LinesOfBusiness - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//
Procedure BeforeWrite(Object, Cancel) Export
	
	
EndProcedure

// Called from the corresponding object module handler
//
// Parameters:
//  Object - CatalogObject.LinesOfBusiness - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure, the record will not be executed and an exception will be thrown.
//
Procedure OnWrite(Object, Cancel) Export
EndProcedure

#EndRegion

#Region MethodsOfManagerModule

// Complements the array of blocked object Attributes (See Catalogs.LinesOfBusiness.GetObjectAttributesToLock)
// .
//
// Parameters:
// 	AttributesToLock - Array of String - The locking details of the object
//
Procedure AddBlockedItemDetails(AttributesToLock) Export
EndProcedure

#EndRegion

#Region FormEventHandlers

// Called from the corresponding method of the object Form
//
// Parameters:
//  Form - ClientApplicationForm
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
// 	Form - ClientApplicationForm - Form of the plan of types of characteristics
//
Procedure ExecuteCommand(CommandName, Form) Export
EndProcedure

#EndRegion

// Called from the corresponding element Form handler
// 
// Parameters:
//  Form - ClientApplicationForm -
Procedure WhenCreatingElementFormOnServer(Form) Export

EndProcedure

// Called from the corresponding element Form handler
// 
// Parameters:
//  Form - ClientApplicationForm -
// 	CurrentObject - CatalogObject.LinesOfBusiness -
//
Procedure OnReadAtServerItemForm(Form, CurrentObject) Export
	

EndProcedure

#EndRegion

