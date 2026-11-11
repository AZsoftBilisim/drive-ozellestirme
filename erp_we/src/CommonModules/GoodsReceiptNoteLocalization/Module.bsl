#Region Public

// Processing the fill check.
// 
// Parameters:
//  Form - ClientApplicationForm
//  Cancel - Boolean
//  CheckedAttributes - Array of String - Verified Bank details
Procedure FillCheckProcessing(Form, Cancel, CheckedAttributes) Export 
	
	
EndProcedure

// Filling processing.
// 
// Parameters:
//  DocumentObject - DocumentObject.GoodsReceiptNote -
//  FillingData - Structure -
//  StandardProcessing - Boolean -
Procedure Filling(DocumentObject, FillingData, StandardProcessing)Export


EndProcedure

// When created on the server.
// 
// Parameters:
//  Form - ClientApplicationForm
//  Cancel - Boolean
//  StandardProcessing - Boolean
Procedure OnCreateAtServer(Form, Cancel, StandardProcessing) Export
	
	
EndProcedure
	 
#Region MarkedProducts

// Defines the accounting of labeled products.
// 
// Returns:
//  Boolean - Labeled products are used
Function MarkedProductsAreUsed() Export
	
	Return WarehousesLocalization.MarkedProductsAreUsed();
	
EndFunction

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


#EndRegion