#Region Public

// Constructor for Catalog form parameters.Controlled parties.The form of the selection.
// Returns:
//  Structure:
//  * Source - String, Undefined - symbol for the context of opening the selection form
//  * Products - CatalogRef.Products, Undefined - The item for obtaining Balances if the source is a "Document.Adjustments to the assignment of goods"
//  * Characteristic - CatalogRef.ItemsCharacteristics, Undefined - a characteristic for obtaining Balances if the source is a "Document.Adjustments to the assignment of goods"
//  * Warehouse - CatalogRef.Warehouses, Undefined - a warehouse for receiving Balances if the source is a "Document.Adjustments to the assignment of goods"
//  * Purpose - CatalogRef.Assignments, Undefined - The assignment is to get Balances if the source is a "Document.Adjustments to the assignment of goods"
//  * Package - CatalogRef.PackagesAndUnitsOfMeasure, Undefined - A packaging unit to obtain Balances if the source is a "Document.Adjustments to the assignment of goods"
Function NewSelectionFormParametersControlledBatches() Export
	
	New_Parameters = New Structure();
	New_Parameters.Insert("Source", Undefined);
	New_Parameters.Insert("Purpose", Undefined);
	New_Parameters.Insert("Products", Undefined);
	New_Parameters.Insert("Warehouse", Undefined);
	New_Parameters.Insert("Package", Undefined);
	New_Parameters.Insert("Characteristic", Undefined);
	
	Return New_Parameters;
	
EndFunction

#EndRegion