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
	
	SourcesOfInvoiceRefinement.Insert(Enums.AccountSpecificationSourceTypes.FinancialAccountingGroupOfProducts,
		New Structure(SourceProperties, "HFCProducts"));
		
	SourcesOfInvoiceRefinement.Insert(Enums.AccountSpecificationSourceTypes.FinancialAccountingGroupOfARAP,
		New Structure(SourceProperties, "HFCCalculations"));
		
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
	SourcesOfDivisions.Insert(Enums.SourcesOfBusinessUnitsOfAnalyticalRegister.OrderDocument, "OrderDivision");

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
	Result.Insert(SourcesOfDirections.ProductLineOfBusiness, "ProductLineOfBusiness");
	Result.Insert(SourcesOfDirections.CounterpartyLineOfBusiness, "CounterpartyLineOfBusiness");

	Return Result;

EndFunction

// Defines the sources of sub-content filling.
//
//
// Returns:
//  Array - array of register attributes.
//
Function SourcesOfExtdimension() Export

	ExtDimensionArray = New Array;
	ExtDimensionArray.Add("Products");
	ExtDimensionArray.Add("Characteristic");
	ExtDimensionArray.Add("Warehouse");
	ExtDimensionArray.Add("InventoryType");
	ExtDimensionArray.Add("InventoryOwnerAttribute");
	ExtDimensionArray.Add("Partner");
	ExtDimensionArray.Add("Counterparty");
	ExtDimensionArray.Add("Vendor");
	ExtDimensionArray.Add("Terms");
	ExtDimensionArray.Add("Contract");
	ExtDimensionArray.Add("OrderDocument");
	ExtDimensionArray.Add("AdvanceHolder");
	ExtDimensionArray.Add("HFCProducts");
	ExtDimensionArray.Add("ItemsType");

	Return New Structure("ExtDimensionDr, ExtDimensionCr", ExtDimensionArray, ExtDimensionArray);
	
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
	
	IndicatorsInCurrency.Insert(Enums.IndicatorsOfAnalyticalRegisters.AmountInARAPCurrency, New Structure(PropertiesOfIndicators, "ARAPCurrency"));
	IndicatorsInCurrency.Insert(Enums.IndicatorsOfAnalyticalRegisters.AmountInDocumentCurrency, New Structure(PropertiesOfIndicators, "DocumentCurrency"));
	
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
	
	QuantityIndicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.Count, "Count");
	
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
	ArrayOfResources.Add(New Structure(ResourceProperties, "Sum", "CurrencyOfMan"));
    ArrayOfResources.Add(New Structure(ResourceProperties, "SumCompl", "ComplCurrency"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "AmountInARAPCurrency", "ARAPCurrency"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "AmountInDocumentCurrency", "DocumentCurrency"));
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.Sum, New Structure(PropertiesOfIndicators, ArrayOfResources));
	
	ArrayOfResources = New Array;
	ArrayOfResources.Add(New Structure(ResourceProperties, "AmountExcludingVAT", "CurrencyOfMan"));
    ArrayOfResources.Add(New Structure(ResourceProperties, "LocalAmountExcludingVAT", "ComplCurrency"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "AmountExcludingVATInARAPCurrency", "ARAPCurrency"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "AmountExcludingVATInDocumentCurrency", "DocumentCurrency"));
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.AmountExcludingVAT, New Structure(PropertiesOfIndicators, ArrayOfResources));
	
	ArrayOfResources = New Array;
	ArrayOfResources.Add(New Structure(ResourceProperties, "VATAmount", "CurrencyOfMan"));
    ArrayOfResources.Add(New Structure(ResourceProperties, "VATAmountCompl", "ComplCurrency"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "AmountOfNDSInCurrencyOfMutualSettlements", "ARAPCurrency"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "NDSAmountInDocumentCurrency", "DocumentCurrency"));
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.VATAmount, New Structure(PropertiesOfIndicators, ArrayOfResources));
	
	ArrayOfResources = New Array;
	ArrayOfResources.Add(New Structure(ResourceProperties, "Cost", "CurrencyOfMan"));
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.Cost, New Structure(PropertiesOfIndicators, ArrayOfResources));
	
	ArrayOfResources = New Array;
	ArrayOfResources.Add(New Structure(ResourceProperties, "CostExcludingVAT", "CurrencyOfMan"));
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.CostExcludingVAT, New Structure(PropertiesOfIndicators, ArrayOfResources));
	
	ArrayOfResources = New Array;
    ArrayOfResources.Add(New Structure(ResourceProperties, "LocalCost", "ComplCurrency"));
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.LocalCost, New Structure(PropertiesOfIndicators, ArrayOfResources));
	
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
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(Department)
	|	AND ValueAllowed(Partner)
	|	AND ValueAllowed(Warehouse)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndIf
