
////////////////////////////////////////////////////////////////////////////////
// Subsystem "Working with nomenclature".
// General module.The work of the nomenclature is undefined.
////////////////////////////////////////////////////////////////////////////////
//

#Region Public


#Region ProductSearchFormByBarcode

// A procedure that is called from the event handler for the append to the Server of the search nomenclature form by Barcode.
//
// Parameters:
//  Form  - ClientApplicationForm - search form for nomenclature by Barcode.
//
Procedure SearchForProductsByBarcodeWhenCreatingThemOnServer(Form) Export
	ProcessingOfItemsTM.SearchForProductsByBarcodeWhenCreatingThemOnServer(Form);
EndProcedure

// A procedure that is called from the event handler for processing the Checkfill of the search nomenclature form by Barcode.
//
// Parameters:
//  Form				 - ClientApplicationForm - search form for nomenclature by Barcode.
//  Cancel				 - Boolean - a sign of failure.
//  CheckedAttributes - Array - Verified banking details.
//
Procedure SearchForProductsByBarcodeProcessingFillInChecks(Form, Cancel, CheckedAttributes) Export
	ProcessingOfItemsTM.SearchForProductsByBarcodeProcessingFillInChecks(Form, Cancel, CheckedAttributes);
EndProcedure

// The entry of barcodes into the data base.
//
// Parameters:
//  ItemsBarcodes - ValueTable:
//   * ProductsIdentifier - String
//   * Barcode - String
//   * Count - Number
//   * Products - DefinedType.ItemsProcessingOfItems
//   * State - String
//   * UnitOfMeasure - Arbitrary
//   * Characteristic - DefinedType.CharacteristicProcessingOfItems
//   * ServiceProducts - String
//   * Registered - Boolean
//   * ItemVariantsAreUsed - Boolean
//   * SearchInTheServiceWasNotUsed - Boolean
//   * CannotFindProductInTheService - Boolean
//   * ItemVariantID - String
//   * RegisteredByDataProcessor - Boolean
//   * CharacteristicIsUsedInTheService - Boolean
//
Procedure RegisterBarcodes(ItemsBarcodes) Export
	ProcessingOfItemsTM.RegisterBarcodes(ItemsBarcodes);
EndProcedure

// This method is called after loading the service item found by barcode, when filling
// in the barcode table.
//
// Parameters:
//  BarcodeTableRow	 - FormDataCollectionItem - a row in the bar code Nomenclature table.
//  ProductsLink		 - DefinedType.ItemsProcessingOfItems - link to the created item.
//
Procedure SearchForProductsByBarcodeAfterLoadingProducts(BarcodeTableRow, ProductsLink) Export
	
EndProcedure

// Getting the item by barcodes.
//
// Parameters:
//  Barcodes			 - Array of String- array of barcodes (String).
//  BarcodeData_	 - ValueTable - summary data table with columns 
//                                           Barcode, Nomenclature, Measurement Unit, Characteristic.
//
Procedure GetProductsByBarcodes(Barcodes, BarcodeData_) Export
	
EndProcedure

// Adds additional properties to the collection of item barcode information.
// 
// Parameters:
//	 BarcodeData_ - Structure of KeyAndValue - a collection containing information about the item's barcode.
//
Procedure ItemSearchByBarcodeBarcodeData(BarcodeData_) Export
	ProcessingOfItemsTM.ItemSearchByBarcodeBarcodeData(BarcodeData_);
EndProcedure

#EndRegion


#EndRegion
