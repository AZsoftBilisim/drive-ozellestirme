////////////////////////////////////////////////////////////////////////////////
// Procedures of the subsystem "Production"
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region Settings

// Gets the settings of the "Production" subsystem"
// 
// Returns:
//   - Structure - settings of the subsystem "Production".
//
Function SubsystemSettingsProduction() Export
	
	Return ProductionServer.SubsystemSettingsProduction();
	
EndFunction

// Returns parameters of the production division
//
// Parameters:
//  Department	- CatalogRef.BusinessStructure - The Department that you want to get parameters for.
//
// Returns:
//   Structure   - contains the parameters of the production unit.
//
Function ProductionBusinessUnitDescription(Department) Export

	Return ProductionServer.ProductionBusinessUnitDescription(Department);
	
EndFunction

// Determines the price of output by default
// 
// Returns:
//  CatalogRef.TypesOfPrices - the type of price of the planned cost.
//
Function TypeOfPricePlannedCost_() Export
	
	PriceKind = Catalogs.TypesOfPrices.TypeOfPricePlannedCostOfInventory();
	Return PriceKind;
	
EndFunction


// Returns a list of distribution options that are involved in generating the cost of production
// 
// Returns:
// 	Array - list of production distribution options
Function GetProductionDistributionOptions() Export
	
	VariantList = New Array();
	VariantList.Add(Enums.CostAllocationOptions.ToProductionCosts);
	VariantList.Add(Enums.CostAllocationOptions.ToProductionCostDirect);
	VariantList.Add(Enums.CostAllocationOptions.ToCostCenters);
	Return VariantList;
	
EndFunction

// Returns the currency of the planned production cost.
//
// Returns:
//   CatalogRef.Currencies - 
//
Function PlannedPriceCurrencyOfProductsMaterialsAndLabor() Export
	
	Return Constants.PlannedPriceCurrencyOfProductsMaterialsAndLabor.Get();

EndFunction

#EndRegion

#EndRegion
