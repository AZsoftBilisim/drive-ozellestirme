
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Fills in the parameters for reflecting register movements in financial accounting
//
// Parameters:
//  RegisterMetadata - MetadataObjectAccumulationRegister - Metadata of the accumulation register
//  RegistrationForReflection - Boolean - Flag for getting parameters to register for accounting
//
// Returns:
// 	See FinancialAccountingByBalanceSheetRegisterData.ParametersForReflectingRegisteredRecordsInFinancialAccounting
//
Function ParametersForReflectingRegisteredRecordsInFinancialAccounting(RegisterMetadata = Undefined, RegistrationForReflection = False) Export
	
	ReflectionParameters = FinancialAccountingByBalanceSheetRegisterData.ParametersForReflectingRegisteredRecordsInFinancialAccounting(RegistrationForReflection);
	
	If RegistrationForReflection Then
		Return ReflectionParameters;
	EndIf;
	
	ReflectionParameters.DataPathConfigurationObject = StrReplace(
		"CASE
		|		WHEN DataSourceAlias.ARAPObject <> VALUE(Catalog.ARAPObjects.EmptyRef)
		|			THEN DataSourceAlias.ARAPObject.FinancialAccountingGroup
		|		ELSE UNDEFINED
		|	END",
		"DataSourceAlias",
		ReflectionParameters.DataSourceAlias);
	ReflectionParameters.DataPathAccountingLocation = "Department";
	ReflectionParameters.PathToDataLineOfBusiness = "LineOfBusiness";
	ReflectionParameters.PathToDataDivision = "Department";
	ReflectionParameters.ManResources.Add("VATManag");
	ReflectionParameters.LocalResources.Add("VAT");
	
	ReflectionParameters.ThisIsVATRegister = True;
	ReflectionParameters.TypeOfAccountingData = Enums.AccountingDataTypes.VAT;
	ReflectionParameters.StructureOfAnalytics = Common.CopyRecursive(DataSourcesCached.AnalyticsStructureByTypeOfAccountingData(ReflectionParameters.TypeOfAccountingData));
	ReflectionParameters.StructureOfAnalytics.TaxInvoice.DataPath = "DocumentPayments";
	ReflectionParameters.StructureOfAnalytics.AssetTaxClass.Insert("Value", Enums.AssetKinds.PrepaymentsFromCustomer);
	
	If RegisterMetadata = Undefined Then
		RegisterMetadata = CreateRecordSet().Metadata();
	EndIf;
	
	FinancialAccountingByBalanceSheetRegisterData.FillReflectionParametersByRegisterMetadata(ReflectionParameters, RegisterMetadata);
	
	Return ReflectionParameters;
	
EndFunction

// Determines the sources to clarify the account is available in the register and their properties.
// More detailed See FinancialAccountingServerCached.SourcesOfInvoiceRefinement
//
// Parameters:
//  SourceProperties - String - "Field name" - the name of the attribute of the accumulation register, from which you plan to get the source of account refinement.
//
// Returns:
//  Map - The key is the name of the source of the invoice refinement. 
//                 Value - the structure of the properties of the invoice refinement source.
//
Function SourcesOfInvoiceRefinement(SourceProperties) Export
	
	SourcesOfInvoiceRefinement = New Map;
	
	// Clarification sources are not available.
	
	Return SourcesOfInvoiceRefinement;
	
EndFunction

// Defines the sources of register divisions and their properties.
// More detailed See FinancialAccountingServerCached.SourcesOfDivisions
//
// Returns:
//  Map - The key is the name of the source. 
//                 Value - the structure of the source properties. 
//
Function SourcesOfDivisions() Export

	SourcesOfDivisions = New Map;
	SourcesOfDivisions.Insert(Enums.SourcesOfBusinessUnitsOfAnalyticalRegister.Department, "Department");
	
	Return SourcesOfDivisions;
	
EndFunction

// Defines the sources of register directions and their properties.
// More detailed See FinancialAccountingServerCached.SourcesOfDirections
//
// Returns:
//  Map - The key is the name of the source. 
//                 Value - the structure of the source properties. 
//
Function SourcesOfDirections() Export

	Result = New Map;
	
	SourcesOfDirections = Enums.SourceOfLinesOfBusinessOfAnalyticalRegister;
	Result.Insert(SourcesOfDirections.LineOfBusiness, "LineOfBusiness");

	Return Result;

EndFunction

// Defines the sources of sub-content filling.
// More detailed See FinancialAccountingServerCached.SourcesOfExtdimension
//
// Returns:
//  Structure - Sources of filling in The ExtDimension. Contains keys:
//  	* ExtDimensionDr - Array of String -
//  	* ExtDimensionCr - Array of String -
//
Function SourcesOfExtdimension() Export
	
	ExtDimensionArray = New Array;
	ExtDimensionArray.Add("Organization");
	ExtDimensionArray.Add("Counterparty");
	ExtDimensionArray.Add("DocumentPayments");
	ExtDimensionArray.Add("Department");
	ExtDimensionArray.Add("LineOfBusiness");
	ExtDimensionArray.Add("VATRate");

	Return New Structure("ExtDimensionDr, ExtDimensionCr", ExtDimensionArray, ExtDimensionArray);
	
EndFunction

// Identifies indicators in the currency of the register.
// More detailed See FinancialAccountingServerCached.IndicatorsInCurrency
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
	
	// Indicators in the currency are not provided.
	
	Return IndicatorsInCurrency;

EndFunction

// Identifies indicators in the currency of the register.
// More detailed See FinancialAccountingServerCached.QuantityIndicators.
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
// More detailed See FinancialAccountingServerCached.Indicators
//
// Parameters:
//  Properties - Structure - containing keys for property Indicators and resource Properties
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
	ArrayOfResources.Add(New Structure(ResourceProperties, "VATManag", "CurrencyOfMan"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "VAT", "ComplCurrency"));
	
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.VATAmount, New Structure(PropertiesOfIndicators, ArrayOfResources));
	
	Return Indicators;
	
EndFunction

// Collects the structure from the request texts for further verification of the ban date.
// 
// Parameters:
// 	Query - Query - Request to check the date of the ban, you can set the parameters
// Returns:
// 	Structure - See MonthEndTransactionsServer.InitializeStructureOfQueryTexts
Function RequestTextMonitoringBanDate(Query) Export
	RegisterName = Metadata.AccumulationRegisters.VATPrepaymentsFromCustomer.Name;
	NameOfChangeTable = "ChangesTableVATPrepaymentsFromCustomer"; 
	StructureOfQueryTexts_ = DocumentsPosting.RequestTextTemplateBanDateControl(Query, 
		RegisterName, 
		NameOfChangeTable, 
		"FinancialOutline");
	Return StructureOfQueryTexts_

EndFunction

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

#EndRegion

#EndIf
