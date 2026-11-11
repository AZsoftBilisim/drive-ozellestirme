#Region Public

// Returns the structure of the product to fill in the tabular part of the form for processing the print of the price tags.
// 
// Returns:
//  Structure
Function ProductForPrinting() Export
	
	ProductStructure_2 = New Structure();
	
	ProductStructure_2.Insert("PlItems");
	ProductStructure_2.Insert("PlVariant");
	ProductStructure_2.Insert("PlPackagingUnit");
	ProductStructure_2.Insert("CompanyCEL");
	ProductStructure_2.Insert("Barcode");
	ProductStructure_2.Insert("Price");
	ProductStructure_2.Insert("Count");
	
	Return ProductStructure_2;
	
EndFunction

// Returns a list of predefined fields in the form of a match that must be taken into account when filling in the product table
// to be able to work with predefined templates.
// 
// Returns:
//  Map of UUID - A list of predefined fields.
Function ListOfPredefinedFields() Export
	
	MatchingPredefinedFields = New Map;
	
	MatchingPredefinedFields.Insert("Organization", "e5b5c498-eafe-4c7b-87cd-0818bb6d41a4");
	MatchingPredefinedFields.Insert("Products", "0a750c7e-cd83-4a96-b03a-db046e65e2da");
	MatchingPredefinedFields.Insert("Characteristic", "87fc9c5d-ae15-48a4-bf69-3d56050b80ec");
	MatchingPredefinedFields.Insert("Barcode", "87fc9c5d-ae15-48a4-bf69-3d56050b80ec");
	MatchingPredefinedFields.Insert("Price", "6897bd06-07c0-41aa-b0c9-ac8cc2825a16");
	MatchingPredefinedFields.Insert("OldPrice", "4ae76b8d-97f5-418d-89a1-87b46d9e846f");
	MatchingPredefinedFields.Insert("UnitOfMeasure", "c750502d-3013-4ecd-a71e-fd6f05787786");
	
	Return MatchingPredefinedFields;
	
EndFunction

#EndRegion