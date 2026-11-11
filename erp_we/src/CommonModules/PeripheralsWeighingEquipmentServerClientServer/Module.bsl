
#Region Public

// Fills in the structure of operation parameters on the Equipment.
//
// Parameters:
//  TareWeight - Number
// 
// Returns:
//  Structure:
//   * TareWeight - Number
//
Function OperationParametersElectronicScales(TareWeight = 0) Export
	
	Parameters = New Structure();
	Parameters.Insert("TareWeight", TareWeight);
	Return Parameters;
	
EndFunction

// Fills in the structure of operation parameters on the Equipment.
// 
// Returns:
//  Structure
//
Function OperationParametersScalesWithLabelPrinting() Export
	
	Parameters = New Structure();
	Parameters.Insert("TableOfGoods", New Array());  // Array of Structures, see the parameterstrackingrelease and printingethe Labels() 
	Parameters.Insert("PartialUnloading", False);
	Return Parameters;
	
EndFunction

// Fills in the structure of unloading a commodity item on a scale with label printing.
// 
// Returns:
//  Structure      
//
Function ParametersOfUnloadingLineInScalesWithLabelPrinting() Export
	
	AdditionalPrices = New Structure();  // Additional Prices
	AdditionalPrices.Insert("Price1");
	AdditionalPrices.Insert("Price2");
	AdditionalPrices.Insert("Price3");
	AdditionalPrices.Insert("Price4");
	
	RowParameters = New Structure();
	RowParameters.Insert("PLU"); // The number, Necessarily - the index of the goods on the scales.
	RowParameters.Insert("Code"); // The number,Necessarily, is the product code that is printed on the label barcode.
	RowParameters.Insert("Barcode");
	RowParameters.Insert("Description"); // String,Optional
	RowParameters.Insert("DescriptionFull");  // String,Optional
	RowParameters.Insert("GoodsSoldByWeight", True);
	RowParameters.Insert("UnitWeightOfPieceGoods"); // Number, Optional - Unit weight of the piece product.
	RowParameters.Insert("Price", 0);  // Number,Optional - The price of the goods on the scale per kilogram.
	RowParameters.Insert("ProductDescription_3");  // String,Optional - Text description of the product (product composition, list of ingredients, etc.)
	RowParameters.Insert("ShelfLife", 0); // Number,Optional - Duration of storage/shelf life of the product, in days  
	RowParameters.Insert("LabelFormat"); // Number, Optional - Label format number
	RowParameters.Insert("ButtonProduct");  // number,optional - the button number of the item on the scale
	RowParameters.Insert("AdditionalPrices", AdditionalPrices); // Structure - Additional Prices
	
	Return RowParameters;
	
EndFunction

// Fills in the structure of operation parameters on the Equipment.
// 
// Returns:
//  Structure
//
Function ParametersOfImageUnloadingOperationScalesWithLabelPrinting() Export
	
	Parameters = New Structure();
	Parameters.Insert("TableOfImages", New Array());
	Return Parameters;
	
EndFunction         

// Fills in the structure of uploading images to scales with label printing.
// 
// Returns:
//  Structure      
//
Function LineParametersForUploadingImagesToScalesWithLabelPrinting() Export
	
	AdditionalPrices = New Structure();  // Additional Prices
	RowParameters = New Structure();
	RowParameters.Insert("PLU"); // The number, Necessarily - the index of the goods on the scales.
	RowParameters.Insert("Code"); // The number,Necessarily, is the product code that is printed on the label barcode.
	RowParameters.Insert("Image");
	
	Return RowParameters;
	
EndFunction

#EndRegion