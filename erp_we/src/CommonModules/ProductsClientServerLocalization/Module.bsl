
#Region Public

// Fills in the values of import accounting details and traceability according to the nomenclature data.
//
// Parameters:
//	Products - CatalogObject.Products, FormDataStructure - the item item being processed.
//	TraceabilityDetails - See ProductsClientServer.DefaultTraceabilityDetails.
//
Procedure FillInImportAndTraceabilityDetails(Products, TraceabilityDetails) Export
	
	
	Return;
	
EndProcedure

// Fills in the value of the 'VESTIUCHETPOGTD' props according to the nomenclature.
//
// Parameters:
//	Products - CatalogObject.Products, FormDataStructure - the item item being processed.
//
Procedure FillKeepRecordsOfCCD(Products) Export
	
	
	Return;
	
EndProcedure

#EndRegion

#Region Internal

Procedure UseSeriesStatusCanBeSpecified(Use, SeriesSpecificationParameters) Export
	
	
EndProcedure

#Region QualityCertificates

// Returns a collection of current Rosaccreditation Status values.
//
// Returns:
//	Array of EnumRef - a collection of the values of the current Statuses of Rosaccreditation.
//
Function ValidStatusesOfRosaccreditation() Export
	
	Response = New Array;
	
	Return Response;
	
EndFunction

// Returns a collection of invalid Rosaccreditation Status values.
//
// Returns:
//	Array of EnumRef - a collection of values of invalid Statuses of Rosaccreditation.
//
Function InvalidStatusesOfRosaccreditation() Export
	
	Response = New Array;
	
	Return Response;
	
EndFunction

#EndRegion

#EndRegion
