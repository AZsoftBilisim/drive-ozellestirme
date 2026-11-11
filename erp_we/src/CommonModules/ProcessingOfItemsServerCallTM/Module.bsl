////////////////////////////////////////////////////////////////////////////////
// Subsystem "Working with nomenclature".
// General module.The work of the nomenclature of the Callserverout.
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Caches information about item barcodes, based on the data found in the information database, based on the transmitted
// collection of barcodes.
//
// Parameters:
//	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//	Barcodes - Array of String - barcodes for which you need to get information.
//
Procedure GetBarcodeData(CachedValues, Barcodes) Export
	
	InformationRegisters.ItemsBarcodes.GetDataOnBarcodesAdvanced(CachedValues, Barcodes);
	
EndProcedure

#EndRegion