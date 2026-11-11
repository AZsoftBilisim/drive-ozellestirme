#Region Public

#Region EventHandlers

// Called from the corresponding directory handler
//
// Parameters:
//  Object - CatalogObject.Warehouses - processed object
//  Cancel - Boolean - If this parameter is set to True in the body of the handler procedure,
//                   it will refuse to continue working after completing the fill check.
//  CheckedAttributes - Array of String - Array of paths to the details to be checked for.
//
Procedure FillCheckProcessing(Object, Cancel, CheckedAttributes) Export
	
	Return;
	
EndProcedure

#EndRegion

#Region MarkedProducts

// Defines the accounting of labeled products.
// 
// Returns:
//  Boolean - Labeled products are used
Function MarkedProductsAreUsed() Export
	
	Result = False;
	Return Result;
	
EndFunction

// Receives the types of labeled products for the goods contained in the document
//
// Parameters:
// 	DocumentRef - DocumentRef - a document whose types of labeled products must be obtained.
//
// Returns:
// 	Array of EnumRef - Array of types of products.
//
Function DocumentProductsTypes(DocumentRef) Export
	
	Result = New Array();
	Return Result;
	
EndFunction

// To establish a sign of the use of labeled products.
// 
// Parameters:
//  Form - ClientApplicationForm:
//		* Object - DocumentObject - The main props of the form
//		* ParametersOfIntegrationOfStateIS - FixedMap of KeyAndValue
Procedure EstablishSignOfUseOfLabeledProducts(Form) Export
	
	ThereAreLabeledProducts              = False;
	TurnoverOfUnmarkedBalancesIsAllowed = True;
	DocumentContainsStamps                = False;

	
	AccordingToDocumentItIsPossibleToUseProductsWithoutStamps = TurnoverOfUnmarkedBalancesIsAllowed And Not DocumentContainsStamps;
	
	Form.ThereAreLabeledProducts     = ThereAreLabeledProducts And Not AccordingToDocumentItIsPossibleToUseProductsWithoutStamps;
	Form.UsePackingLists = Form.UsePackingLists And (Not ThereAreLabeledProducts And Not AccordingToDocumentItIsPossibleToUseProductsWithoutStamps);

EndProcedure

#Region AddItemsFromSalesOrderGoodsIssue

// To form the structure of the barcodes of the waybill packages.
//
// Returns:
// 	ValueTable - To Form The Structure Of The Barcodes Of The Waybill Packages:
// 		* RowIsSelected - Boolean - the line is selected.
// 		* Products - CatalogRef.Products - Nomenclature.
// 		* Characteristic - CatalogRef.ItemsCharacteristics - characteristic.
// 		* Series - CatalogRef.ItemsBatches - series.
// 		* PackageBarcode - CatalogRef - The barcode of the package.
//
Function ToFormStructureOfBarcodesOfWaybillPackages() Export
	
	Table = New ValueTable();
	
	Return Table;
	
EndFunction

// Distribute the stamps.
// 
// Parameters:
//  BarcodesOfWaybillPackages - See WarehousesLocalization.ToFormStructureOfBarcodesOfWaybillPackages
//  TableOfBarcodesOfPackages - ValueTable
//  GoodsTable - ValueTable
Procedure DistributeStamps(BarcodesOfWaybillPackages,
							TableOfBarcodesOfPackages,
							GoodsTable) Export
	
	
EndProcedure

// Add the marking details.
// 
// Parameters:
//  Form - ClientApplicationForm
Procedure AddMarkingAttributes(Form) Export
	
	
EndProcedure

// Adds a check and selection status column to the form in the tabular part
//
// Parameters:
//   Form               - ClientApplicationForm                   - embedding form
//   Settings - Structure                          - application form integration parameters
//
Procedure AddStatusColumnForSelectionCheck(Form, Settings) Export
	
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion

#Region Internal

Procedure ItemManagement_CatalogPanel_(Items, ThereIsDataToDisplay) Export

		
EndProcedure


#EndRegion
