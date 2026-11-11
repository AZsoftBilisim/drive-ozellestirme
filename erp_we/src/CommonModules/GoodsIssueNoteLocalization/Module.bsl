#Region Public

// Parameters:
//  Var_ThisObject - ClientApplicationForm
//  Cancel - Boolean
//  CheckedAttributes - Array of String - Verified Bank details
Procedure FillCheckProcessing(Var_ThisObject, Cancel, CheckedAttributes) Export 
	
	
EndProcedure

// Set the conditional design.
// 
// Parameters:
//  DocumentForm - ClientApplicationForm -
Procedure SetConditionalAppearance(DocumentForm) Export

	
EndProcedure

#Region MarkedProducts

// Defines the accounting of labeled products.
// 
// Returns:
//  Boolean - Labeled products are used
Function MarkedProductsAreUsed() Export
	
	Return WarehousesLocalization.MarkedProductsAreUsed();
	
EndFunction

Procedure FillInCacheOfBarcodesOfPackages(Form, Settings = Undefined, Initialize = False) Export
	
	
EndProcedure

// To establish a sign of the use of labeled products.
// 
// Parameters:
//  Form - See WarehousesLocalization.EstablishSignOfUseOfLabeledProducts.Form
Procedure EstablishSignOfUseOfLabeledProducts(Form) Export
	
	WarehousesLocalization.EstablishSignOfUseOfLabeledProducts(Form);
	
EndProcedure

// Definition of the feature of the on-time accounting of products as of the date.
// 
// Parameters:
//  ProductType         - Arbitrary - Product Type
//  OnDate               - Date - Date Of Control
//  PieceByPieceAccountingIsConducted - Boolean - True if the product brands are individually recorded.
Procedure DefinitionOfFeatureOfOccasionalAccountingOfProductsOnDate(ProductType, OnDate, PieceByPieceAccountingIsConducted) Export
	
	PieceByPieceAccountingIsConducted = False;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region FillingControl


#EndRegion

#EndRegion
