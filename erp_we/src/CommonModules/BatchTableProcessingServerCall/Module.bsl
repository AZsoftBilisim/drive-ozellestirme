////////////////////////////////////////////////////////////////////////////////
// The module provides the client with an interface to the server side of the functionality
// of the tabular processing mechanism.
////////////////////////////////////////////////////////////////////////////////
//

#Region Private

// This function should be called only from the client module of the batch processing of the individual client part.
// 
// Parameters:
//  CurrentRow - See BatchProcessingOfTablePartServer.ProcessTSString.CurrentRow
//  StructureOfActions - See BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure ProcessTSString(CurrentRow, StructureOfActions, CachedValues) Export
	
	If CachedValues = Undefined 
		Or Not CachedValues.Count() Then
			CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	EndIf;
	
	BatchProcessingOfTablePartServer.ProcessTSString(
		CurrentRow,
		StructureOfActions,
		CachedValues);
	
EndProcedure

// Returns data about the package.
// 
// Parameters:
//  Products - CatalogRef.Products - The nomenclature for which you want to get the packing coefficient.
//  Package - CatalogRef.PackagesAndUnitsOfMeasure - The package for which you want to get the packing coefficient.
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
// 
// Returns:
//  See Catalogs.PackagesAndUnitsOfMeasure.CoefficientWeightVolumeOtherPackingDetails
//
Function PackingInformation(Products, Package, CachedValues) Export 
	
	Return BatchProcessingOfTablePartServer.PackingInformation(Products, Package, CachedValues);
	
EndFunction

#EndRegion
