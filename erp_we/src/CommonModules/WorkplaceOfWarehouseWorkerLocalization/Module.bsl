
#Region Public

#Region MarkedProducts

// Returns the "Scanned Stamps" table.
//
// Returns:
// 	ValueTable:
// 		* BarcodeMarking - CatalogRef - The barcode of the package.
// 		* BarcodeMarkingValue - String
// 		* ThisIsNestedPackage - Boolean
// 		* PackageType - EnumRef.PackageTypes
//
Function TableScannedStamps() Export

	ScannedStamps = New ValueTable;
	
	Return ScannedStamps;

EndFunction

// Returns a list of scanned product brands
//
// Parameters:
//	TableScannedStamps - See TableScannedStamps
//	WSBrandValues - XDTODataValue - List of "Top-level labeling tables" of the WMSMobileClientExchange XDTO package* 
//	ServiceVersion - String - WMSMobileClientExchange service version*
//
// Returns:
//	See TableScannedStamps
//
Function ScannedStamps(TableScannedStamps, WSBrandValues, ServiceVersion) Export
	
	
	Return TableScannedStamps;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region MarkedProducts

// The result of the marking check.
// 
// Parameters:
//  ScannedGoods - ValueTable - a product table that corresponds to the tabular part of the task being performed
// and contains information about scanned products in the selection, placement, movement, and selection verification operations.
// Recalculation operations store the original information about the goods in the document "recalculation of Goods".
//  ScannedStampValues - ValueTable - Scanned stamp values
// 
// Returns:
// 	ValueTable -- Result Of The Marking Check:
// 		* BarcodeValue - String
// 		* ValueAccepted - Boolean
// 		* ControlResult - String
// 		* PackageBarcode - CatalogRef - The barcode of the package.
// 		* ThisIsNestedPackage - Boolean
// 		* ExtraGoods - Boolean
// 		* NoData1 - Boolean
//
Function ResultOfMarkingCheck(ScannedGoods, ScannedStampValues) Export
	
	ResultOfMarkingCheck = New ValueTable;
	
	Return ResultOfMarkingCheck;
	
EndFunction // The result of the labeling check()


#EndRegion

#EndRegion
