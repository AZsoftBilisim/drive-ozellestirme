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
	
	ReflectionParameters.ManResources.Add("VATManag");
	ReflectionParameters.LocalResources.Add("VAT");
	
	ReflectionParameters.ThisIsVATRegister = True;
	ReflectionParameters.TypeOfAccountingData = Enums.AccountingDataTypes.VAT;
	ReflectionParameters.DataPathDopSettingUpHouseholdOfOperation = StrReplace(
		"CASE
		|		WHEN DataSourceAlias.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.SaleToCustomer)
		|			THEN CASE
		|				WHEN DataSourceAlias.Recorder REFS Document.CustomerInvoiceServicesAndAssets
		|					OR DataSourceAlias.Recorder REFS Document.ReversingEntry
		|					AND CAST(DataSourceAlias.Recorder AS Document.ReversingEntry).ReversedDocument REFS Document.CustomerInvoiceServicesAndAssets
		|					OR DataSourceAlias.Recorder REFS Document.SaleAdjustment
		|					AND CAST(DataSourceAlias.Recorder AS Document.SaleAdjustment).DocumentBasis REFS Document.CustomerInvoiceServicesAndAssets
		|					THEN VALUE(Catalog.BusinessTransactionsSettings.OtherServicesSale)
		|				WHEN DataSourceAlias.Recorder REFS Document.SaleAdjustment
		|					THEN VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
		|				ELSE DataSourceAlias.BusinessTransactionSetting
		|			END
		|		ELSE DataSourceAlias.BusinessTransactionSetting
		|	END",
		"DataSourceAlias",
		ReflectionParameters.DataSourceAlias);
	IdentifyIndicators(ReflectionParameters);
	
	ReflectionParameters.DebitCondition = StrReplace(
		"DataSourceAlias.EntryType = VALUE(Enum.VATRegisterRecordTypes.Incoming)",
		"DataSourceAlias",
		ReflectionParameters.DataSourceAlias);
	
	ReflectionParameters.ConditionCredit = StrReplace(
		"DataSourceAlias.EntryType = VALUE(Enum.VATRegisterRecordTypes.Outgoing)",
		"DataSourceAlias",
		ReflectionParameters.DataSourceAlias);
	
	If RegisterMetadata = Undefined Then
		RegisterMetadata = CreateRecordSet().Metadata();
	EndIf;
	
	FinancialAccountingByBalanceSheetRegisterData.FillReflectionParametersByRegisterMetadata(ReflectionParameters, RegisterMetadata);
	
	Return ReflectionParameters;
	
EndFunction

// Determines the sources to clarify the account is available in the register and their properties.
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
//
// Returns:
//  Map - The key is the name of the source. 
//                 Value - the structure of the source properties. 
//
Function SourcesOfDivisions() Export

	SourcesOfDivisions = New Map;
	
	Return SourcesOfDivisions;
	
EndFunction

// Defines the sources of register directions and their properties.
//
// Returns:
//  Map - The key is the name of the source. 
//                 Value - the structure of the source properties. 
//
Function SourcesOfDirections() Export
	
	Result = New Map;
	
	Return Result;

EndFunction

// Defines the sources of sub-content filling.
//
// Returns:
//  Array - array of register attributes.
//
Function SourcesOfExtdimension() Export

	ExtDimensionArray = New Array;
	ExtDimensionArray.Add("Counterparty");
	ExtDimensionArray.Add("TaxInvoice");
	ExtDimensionArray.Add("AssetTaxClass");
	ExtDimensionArray.Add("VATRate");

	Return New Structure("ExtDimensionDr, ExtDimensionCr", ExtDimensionArray, ExtDimensionArray);
	
EndFunction

// Identifies indicators in the currency of the register.
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
	RegisterName = Metadata.AccumulationRegisters.VATRegisterRecords.Name;
	NameOfChangeTable = "ChangesTableVATRegisterRecords"; 
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

#Region Private

// Defines register indicators
//
// Parameters:
//  ReflectionParameters - See ParametersForReflectingRegisteredRecordsInFinancialAccounting
//
Procedure IdentifyIndicators(ReflectionParameters)
	
	// amount of VAT
	IndicatorReflectionParameters = Enums.IndicatorsOfAnalyticalRegisters.IndicatorReflectionParameters();
	IndicatorReflectionParameters.ManResources.Add("VATManag");
	IndicatorReflectionParameters.LocalResources.Add("VAT");
	IndicatorReflectionParameters.ResourcesQuantity.Add("0");
	IndicatorReflectionParameters.DataPathRecordFinID = StrReplace(
		"CASE
		|		WHEN DataSourceAlias.ARAPObject <> VALUE(Catalog.ARAPObjects.EmptyRef)
		|			THEN DataSourceAlias.ARAPObject.UUID
		|		ELSE DataSourceAlias.FinRecordID
		|	END",
		"DataSourceAlias",
		FinancialAccountingByBalanceSheetRegisterData.DefaultDataSourceAlias());
	IndicatorReflectionParameters.DataPathRowId = "FinRecordID";
	ReflectionParameters.Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.VATAmount, IndicatorReflectionParameters);
	
EndProcedure

#EndRegion

#EndIf
