#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
#Region Public

// Determines the sources to clarify the account is available in the register and their properties.
//
//
// Parameters:
//  SourceProperties - String - "Field name" - the name of the attribute of the accumulation register, from which you plan to get the source
//                               of account refinement.
//
// Returns:
//  Map - The key is the name of the source of the invoice refinement. 
//                 Value - the structure of the properties of the invoice refinement source.
//
Function SourcesOfInvoiceRefinement(SourceProperties) Export
	
	SourcesOfInvoiceRefinement = New Map;
	
	SourcesOfInvoiceRefinement.Insert(Enums.AccountSpecificationSourceTypes.FinancialAccountingGroupOfProductsCr,
		New Structure(SourceProperties, "HFCProducts"));
	
	SourcesOfInvoiceRefinement.Insert(Enums.AccountSpecificationSourceTypes.FinancialAccountingGroupOfProductsDr,
		New Structure(SourceProperties, "CorHFCProducts"));
	
	Return SourcesOfInvoiceRefinement;
	
EndFunction

// Defines the sources of register divisions and their properties.
//
//
// Returns:
//  Map - The key is the name of the source. 
//                 Value - the structure of the source properties. 
//
Function SourcesOfDivisions() Export

	SourcesOfDivisions = New Map;
	
	SourcesOfDivisions.Insert(Enums.SourcesOfBusinessUnitsOfAnalyticalRegister.BusinessOperation, "Department");
	SourcesOfDivisions.Insert(Enums.SourcesOfBusinessUnitsOfAnalyticalRegister.ItemsLocationAttributes, "WarehouseDivision");
	SourcesOfDivisions.Insert(Enums.SourcesOfBusinessUnitsOfAnalyticalRegister.CorItemsLocationAttributes, "CorWarehouseDivision");
	
	Return SourcesOfDivisions;
	
EndFunction

// Defines the sources of register directions and their properties.
//
//
// Returns:
//  Map - The key is the name of the source. 
//                 Value - the structure of the source properties. 
//
Function SourcesOfDirections() Export

	Result = New Map;
	
	SourcesOfDirections = Enums.SourceOfLinesOfBusinessOfAnalyticalRegister;
	Result.Insert(SourcesOfDirections.LineOfBusiness, "LineOfBusiness");
	Result.Insert(SourcesOfDirections.CorLineOfBusiness, "CorLineOfBusiness");

	Return Result;

EndFunction

// Defines the sources of sub-content filling.
//
//
// Returns:
//  Array - array of register attributes.
//
Function SourcesOfExtdimension() Export

	ExtDimensionArrayCr = New Array;
	ExtDimensionArrayCr.Add("Products");
	ExtDimensionArrayCr.Add("Characteristic");
	ExtDimensionArrayCr.Add("Warehouse");
	ExtDimensionArrayCr.Add("InventoryType");
	ExtDimensionArrayCr.Add("InventoryOwnerAttribute");
	ExtDimensionArrayCr.Add("HFCProducts");
	ExtDimensionArrayCr.Add("ItemsType");
	ExtDimensionArrayCr.Add("CorCompany");
	ExtDimensionArrayCr.Add("Vendor");
	ExtDimensionArrayCr.Add("Custodian");
	
	ExtDimensionArrayDr = New Array;
	ExtDimensionArrayDr.Add("CorNomenclature");
	ExtDimensionArrayDr.Add("CorCharacteristics");
	ExtDimensionArrayDr.Add("CorWarehouseCorCommissionAgentCorBusinessUnit");
	ExtDimensionArrayDr.Add("CorInventoryType");
	ExtDimensionArrayDr.Add("CorInventoryOwnerAttribute");
	ExtDimensionArrayDr.Add("CorHFCProducts");
	ExtDimensionArrayDr.Add("CorTypeProducts");
	ExtDimensionArrayDr.Add("CorCompany");
	ExtDimensionArrayDr.Add("CorSupplier");
	ExtDimensionArrayDr.Add("KorGuardian");
	
	Return New Structure("ExtDimensionDr, ExtDimensionCr", ExtDimensionArrayDr, ExtDimensionArrayCr);
	
EndFunction

// Identifies indicators in the currency of the register.
//
//
// Parameters:
//  PropertiesOfIndicators - String - "Sourcecurrency" - the currency source for the register indicator.
//
// Returns:
//  Map - The key is the name of the indicator.
//                 Value - the structure of the properties of the indicator.
//
Function IndicatorsInCurrency(PropertiesOfIndicators) Export

	IndicatorsInCurrency = New Map;
	
	// not required
	
	Return IndicatorsInCurrency;

EndFunction

// Identifies indicators in the currency of the register.
//
//
// Returns:
//  Map - The key is the name of the indicator.
//                 Value - the structure of the properties of the indicator.
//
Function QuantityIndicators() Export

	QuantityIndicators = New Map;
	
	QuantityIndicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.Count, 	"Count");
	QuantityIndicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.CorQuantity, 	"CorQuantity");
	
	Return QuantityIndicators;

EndFunction

// Defines register metrics.
//
//
// Parameters:
//  Properties - Structure - containing the keys of the properties of Indicators, properties of Resources.
//
// Returns:
//  Map - The key is the name of the indicator.
//                 Value - the structure of the properties of the indicator.
//
Function Indicators(Properties) Export

	Indicators = New Map;
	
	PropertiesOfIndicators = Properties.PropertiesOfIndicators;
	ResourceProperties = Properties.ResourceProperties;
	
	ArrayOfResources = New Array;
	ArrayOfResources.Add(New Structure(ResourceProperties, "CostMan", "CurrencyOfMan"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "LocalCost", "ComplCurrency"));
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.Sum, New Structure(PropertiesOfIndicators, ArrayOfResources));
	
	ArrayOfResources = New Array;
	ArrayOfResources.Add(New Structure(ResourceProperties, "CostExcludingVAT", "CurrencyOfMan"));
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.AmountExcludingVAT, New Structure(PropertiesOfIndicators, ArrayOfResources));
	
	ArrayOfResources = New Array;
	ArrayOfResources.Add(New Structure(ResourceProperties, "LocalCost", "ComplCurrency"));
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.SumCompl, New Structure(PropertiesOfIndicators, ArrayOfResources));
	
	ArrayOfResources = New Array;
	ArrayOfResources.Add(New Structure(ResourceProperties, "ProvisionForImpairmentMan", "CurrencyOfMan"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "ProvisionForImpairmentLocal", "ComplCurrency"));
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.ProvisionForImpairment, New Structure(PropertiesOfIndicators, ArrayOfResources));
	
	Return Indicators;
	
EndFunction

#EndRegion
#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#Region InfobaseUpdate

#EndRegion

#EndIf
