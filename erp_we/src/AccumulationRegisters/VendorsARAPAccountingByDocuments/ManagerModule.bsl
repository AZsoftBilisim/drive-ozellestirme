#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public
#Region SourceDetails
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
	
	SourcesOfDivisions.Insert(Enums.SourcesOfBusinessUnitsOfAnalyticalRegister.OrderDocument, "Department");

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
	ExtDimensionArray.Add("Partner");
	ExtDimensionArray.Add("Counterparty");
	ExtDimensionArray.Add("OrderDocument");
	ExtDimensionArray.Add("Contract");

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
	
	IndicatorsInCurrency.Insert(Enums.IndicatorsOfAnalyticalRegisters.AmountInARAPCurrency, New Structure(PropertiesOfIndicators, "Currency"));
	
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
	ArrayOfResources.Add(New Structure(ResourceProperties, "PrepaymentMan", "CurrencyOfMan"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "PrepaymentLocal", "ComplCurrency"));
    ArrayOfResources.Add(New Structure(ResourceProperties, "Prepayment", "Currency"));
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.Sum, New Structure(PropertiesOfIndicators, ArrayOfResources));
	
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
	"AttachAdditionalTables
	|ThisList AS T
	|LEFT JOIN InformationRegister.AccountingDimensionByPartners AS T1 
	|	ON T.AccountingDimensionByPartners = T1.DimensionKey
	|;
	|AllowReadUpdate
	|WHERE
	|	ValueAllowed(T1.Organization)
	|	AND ValueAllowed(T1.Partner)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#EndIf