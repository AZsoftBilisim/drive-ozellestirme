////////////////////////////////////////////////////////////////////////////////////////
// Comparison of the nomenclature of the Counteragent Service Clientserver:
// a mechanism for comparing the nomenclature of counterparties with the nomenclature of the information base.
//
///////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Returns a flag for different data between the package and the base unit of measurement.
//
// Parameters:
//  PackingProperties - See ProductCrossReferencesMappingClientServer.NewPackagingProperties.
//
// Returns:
//  Boolean - the attribute indicates that the package is different from the base unit of measurement.
//
Function PackagingAndBaseUnitAreDifferent(PackingProperties) Export
	
	Return Not ((PackingProperties.NumberOfPackages = 1 And PackingProperties.QuantityInBaseUnitOfMeasure = 1
		Or PackingProperties.NumberOfPackages = 0 And PackingProperties.QuantityInBaseUnitOfMeasure = 0)
		And PackingProperties.PackageName = PackingProperties.BaseUnitOfMeasureDescription);
		
EndFunction


#EndRegion

