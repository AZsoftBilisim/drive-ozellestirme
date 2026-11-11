#Region Internal

#Region ObjectEventHandlers

// Called from the corresponding handler for the feature types plan
//
// Parameters:
//  Object - ChartOfCharacteristicTypesObject.ExpenseItems - processed object
//  Cancel - Boolean - If this parameter is set to True in the body of the handler procedure,
//                   it will refuse to continue working after completing the fill check.
//  CheckedAttributes - Array - Array of paths to the details to be checked for.
//
Procedure FillCheckProcessing(Object, Cancel, CheckedAttributes) Export
	
	
EndProcedure

// Called from the corresponding handler for the feature types plan
//
// Parameters:
//  Object - ChartOfCharacteristicTypesObject.ExpenseItems - processed object
//  FillingData - Arbitrary - The value that is used as the basis for filling in.
//  StandardProcessing - Boolean - This parameter is passed to indicate that standard (system) event processing is performed.
//
Procedure Filling(Object, FillingData, StandardProcessing) Export
	
	
EndProcedure

// Called from the corresponding handler for the feature types plan
//
// Parameters:
//  Object - ChartOfCharacteristicTypesObject.ExpenseItems - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//
Procedure BeforeWrite(Object, Cancel) Export
	
	
EndProcedure

// Called from the corresponding handler for the feature types plan
//
// Parameters:
//  Object - ChartOfCharacteristicTypesObject.ExpenseItems - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure, the record will not be executed and an exception will be thrown.
//
Procedure OnWrite(Object, Cancel) Export
EndProcedure

#EndRegion

#Region MethodsOfManagerModule

// Registers data for the update handler.
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
EndProcedure

#EndRegion

#Region FormEventHandlers

// Called from the corresponding handler of the plan form for types of characteristics
//
// Parameters:
// 	Form - ClientApplicationForm - Form of the plan of types of characteristics
//
Procedure OnReadCreateAtServer(Form) Export
EndProcedure

// Called from the corresponding object form handler
//
// Parameters:
// 	TagName - String - Name of the form element
// 	Form - ClientApplicationForm - Form of the plan of types of characteristics
//
Procedure OnChangeAttribute(TagName, Form) Export
EndProcedure

// Called from the corresponding object form handler
//
// Parameters:
// 	CommandName - String - Command name
// 	ThisForm - ClientApplicationForm - Form of the plan of types of characteristics
//
Procedure ExecuteCommand(CommandName, ThisForm) Export
EndProcedure

#EndRegion

#EndRegion

