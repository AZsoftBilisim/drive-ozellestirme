
#Region Public

// Fills in the structure of parameters of the upload line in the TSD.
//
// Returns:
//  Structure
//
Function ParametersOfVTSDUploadLine() Export
	
	RowParameters = New Structure();
	
	RowParameters.Insert("Code");              // String
	RowParameters.Insert("SKU");          // String
	RowParameters.Insert("Barcode");         // String
	RowParameters.Insert("BarcodeBASE64");   // String
	RowParameters.Insert("PackageBarcode"); // String
	RowParameters.Insert("PackingBarcodeBase64"); // String
	RowParameters.Insert("Products");     // String
	RowParameters.Insert("Description");     // String
	RowParameters.Insert("UnitOfMeasure"); // String
	RowParameters.Insert("ProductCharacteristic"); // String
	RowParameters.Insert("ProductSeries"); // String
	RowParameters.Insert("Quality");          // String
	RowParameters.Insert("Price"        , 0);   // Number
	RowParameters.Insert("Balance"     , 0);   // Number
	RowParameters.Insert("Count"  , 0);   // Number
	RowParameters.Insert("Alcohol"    , False); // Boolean
	RowParameters.Insert("Labelled" , False); // Boolean
	RowParameters.Insert("CodeOfTypeOfAlcoholicProducts"); // String
	RowParameters.Insert("CodeOfAlcoholicProducts");
	RowParameters.Insert("ContainerCapacity"); // Number
	RowParameters.Insert("Strength");    // Number
	RowParameters.Insert("ManufacturerSTin");  // String
	RowParameters.Insert("ManufacturerSCheckpoint");  // String
	RowParameters.Insert("BarcodeBrandOfAlcoholicBeverages");  // String
	RowParameters.Insert("BarcodeBrandOfAlcoholicBeveragesBase64");  // String
	
	Return RowParameters; 
	
EndFunction

// Fills in the structure of operation parameters on the Equipment.
// 
// Returns:
//  Structure - VTSD Upload Parameters:
//   * TableOfGoods - Array of See PeripheralsPortableDataTerminalsServerClientServer.ParametersOfVTSDUploadLine.
//   * PartialUnloading - Boolean
//
Function VTSDUploadParameters() Export
	
	Parameters = New Structure();
	Parameters.Insert("TableOfGoods", New Array());
	Parameters.Insert("PartialUnloading", False);
	Return Parameters;
	
EndFunction

#EndRegion

