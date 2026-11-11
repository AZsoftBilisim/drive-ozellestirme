#Region Public

// Complements the structure of actions on the row of the table part ON changing the form element.
// 
// Parameters:
//  Form - Form - The form in which the tabular part is processed.
//  Item - FormField - Modified form element.
//  StructureOfActions - See BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions.
//
Procedure CompleteActionStructureWhenChangingElement(Form, Item, StructureOfActions) Export
	
	Return;
	
EndProcedure

// Complements the structure of actions to fill in the "VAT Rate" for setting up the committee's accounting.   
// 
// Parameters:
//  Object - FormDataStructure, DocumentObject - Document data.
//  StructureOfActions - See BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions.
//
Procedure AddActionOfFillingInVATRateForSettingUpAccounting(Object, StructureOfActions) Export
	
	
EndProcedure

// Complements the collection of cached product information by barcode.
//
// Parameters:
//	BarcodeInformation_ - See BatchProcessingOfTablePartClientServer.CachedInformationStructureByBarcode.
//
Procedure ToSupplementStructureOfCachedBarcodeInformation(BarcodeInformation_) Export
	
	
EndProcedure

#EndRegion

#Region Internal

Procedure FieldsOfActionLine(CurrentRow, StructureOfActions, CachedValues, AdditionalFillingParameters) Export

	
EndProcedure

#Region Localization


#EndRegion

#EndRegion

#Region Private

#EndRegion