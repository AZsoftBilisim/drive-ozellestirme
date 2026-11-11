
#Region Public

#Region EventHandlers

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - The object being processed.
//  FillingData - Arbitrary - The value that is used as the basis for filling in.
//  StandardProcessing - Boolean - This parameter is passed to indicate that standard (system) event processing is performed.
//
Procedure Filling(Object, FillingData, StandardProcessing) Export
	
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - CatalogObject.CounterpartyBankAccounts - The object being processed.
//  Cancel - Boolean - If this parameter is set to True in the body of the handler procedure,
//                   it will refuse to continue working after completing the fill check.
//  CheckedAttributes - Array of String- Array of paths to the details to be checked for.
//
Procedure FillCheckProcessing(Object, Cancel, CheckedAttributes) Export
	
	Return;
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//
Procedure BeforeWrite(Object, Cancel) Export
	
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - CatalogObject - processed object
//  CopiedObject - CatalogObject - The source directory that is the source of copying.
//
Procedure OnCopy(Object, CopiedObject) Export
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#EndRegion
