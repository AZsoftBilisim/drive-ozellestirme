////////////////////////////////////////////////////////////////////////////////
// Procedures and functions of the subsystem "International Financial Accounting".
//  
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Returns the accounting currencies in the chart of accounts
// 
// Parameters:
// 	ChartOfAccounts - CatalogRef.FinancialAccountingChartsOfAccounts - The chart of accounts to get accounting currencies for.
// 	Organization - CatalogRef.Companies - The organization for which it is necessary to obtain accounting currencies.
// 	
// Returns:
//	Structure - See FinancialAccountingOfGeneralPurpose.AccountingCurrencies
//
Function AccountingCurrencies(ChartOfAccounts, Organization) Export

	Return FinancialAccountingOfGeneralPurpose.AccountingCurrencies(ChartOfAccounts, Organization);

EndFunction


// Returns the functional currency that is used in the organization on the specified chart of accounts.
// 
// Parameters:
// 	ChartOfAccounts - CatalogRef.FinancialAccountingChartsOfAccounts - The chart of accounts to get accounting currencies for.
// 	Organization - CatalogRef.Companies - The organization for which it is necessary to obtain accounting currencies.
// 	
// Returns:
//	CatalogRef.Currencies -
//
Function CurrencyFunctional(ChartOfAccounts, Organization) Export

	Return FinancialAccountingOfGeneralPurpose.AccountingCurrencies(ChartOfAccounts, Organization).Functional;

EndFunction

// Returns the register parameters to be reflected in international accounting.
//
// Parameters:
//	RegisterName - String - name of the register for which reflection parameters are returned.
//
// Returns:
//	Structure of KeyAndValue - Structure of returned parameters:
//		* Indicators - See FinancialAccountingServerCached.Indicators
//		* IndicatorsInCurrency - See FinancialAccountingServerCached.IndicatorsInCurrency
//		* QuantityIndicators - See FinancialAccountingServerCached.QuantityIndicators
//		* SourcesOfInvoiceRefinement - See FinancialAccountingServerCached.SourcesOfInvoiceRefinement
//		* SourcesOfDivisions - See FinancialAccountingServerCached.SourcesOfDivisions
//		* SourcesOfDirections - See FinancialAccountingServerCached.SourcesOfDirections
//		* SourcesOfExtdimension - See FinancialAccountingServerCached.SourcesOfExtdimension
Function RegisterParameters(RegisterName) Export

	ReflectionParameters = New Structure();
	ReflectionParameters.Insert("Indicators", FinancialAccountingServerCached.Indicators(RegisterName));
	ReflectionParameters.Insert("IndicatorsInCurrency", FinancialAccountingServerCached.IndicatorsInCurrency(RegisterName));
	ReflectionParameters.Insert("QuantityIndicators", FinancialAccountingServerCached.QuantityIndicators(RegisterName));
	ReflectionParameters.Insert("SourcesOfInvoiceRefinement", FinancialAccountingServerCached.SourcesOfInvoiceRefinement(RegisterName));
	ReflectionParameters.Insert("SourcesOfDivisions", FinancialAccountingServerCached.SourcesOfDivisions(RegisterName));
	ReflectionParameters.Insert("SourcesOfDirections", FinancialAccountingServerCached.SourcesOfDirections(RegisterName));
	ReflectionParameters.Insert("SourcesOfExtdimension", FinancialAccountingServerCached.SourcesOfExtdimension(RegisterName));
	
	Return ReflectionParameters;

EndFunction

// Determines the sources to clarify the account is available in the register and their properties.
//
// Parameters:
//  RegisterName - String - register name.
//
// Returns:
//  Map - The key is the name of the source of the invoice refinement. 
//				   Value - the structure of the properties of the invoice refinement source.
//
Function SourcesOfInvoiceRefinement(RegisterName) Export

	If IsBlankString(RegisterName) Or Metadata.AccumulationRegisters.Find(RegisterName) = Undefined Then
		Return Undefined;
	EndIf;
	
	SourceProperties = PropertiesOfInvoiceRefinementSource();
	SourcesOfInvoiceRefinement = AccumulationRegisters[RegisterName].SourcesOfInvoiceRefinement(SourceProperties);
	
	Return SourcesOfInvoiceRefinement;

EndFunction

// Defines the sources of register divisions and their properties.
//
// Parameters:
//  RegisterName - String - register name.
//
// Returns:
//  Map - The key is the name of the source. 
//				   Value - the structure of the source properties. 
//
Function SourcesOfDivisions(RegisterName) Export

	If IsBlankString(RegisterName) Or Metadata.AccumulationRegisters.Find(RegisterName) = Undefined Then
		Return Undefined;
	EndIf;
	
	SourcesOfDivisions = AccumulationRegisters[RegisterName].SourcesOfDivisions();
	
	Return SourcesOfDivisions;

EndFunction

// Defines the sources of register directions and their properties.
//
// Parameters:
//  RegisterName - String - register name.
//
// Returns:
//  Map - The key is the name of the source. 
//				   Value - the structure of the source properties. 
//
Function SourcesOfDirections(RegisterName) Export

	If IsBlankString(RegisterName) Or Metadata.AccumulationRegisters.Find(RegisterName) = Undefined Then
		Return Undefined;
	EndIf;
	
	SourcesOfDirections = AccumulationRegisters[RegisterName].SourcesOfDirections();
	
	Return SourcesOfDirections;

EndFunction

// Defines the sources of sub-content filling.
//
// Parameters:
//  RegisterName - String - register name.
//
// Returns:
//  Array - array of register attributes.
//
Function SourcesOfExtdimension(RegisterName) Export

	If IsBlankString(RegisterName) Or Metadata.AccumulationRegisters.Find(RegisterName) = Undefined Then
		Return Undefined;
	EndIf;

	SourcesOfExtdimension = AccumulationRegisters[RegisterName].SourcesOfExtdimension();
	
	Return SourcesOfExtdimension;

EndFunction

// Defines register metrics.
//
// Parameters:
//  RegisterName - String - register name.
//
// Returns:
//  Map of KeyAndValue - :
//   The key is Enumeration.Indicators of analytical registers - the name of the indicator
//   Value - Structure of the key Value - Description of the metric properties:
//    *Resources - Array of Structure-:
//     **Name - String - 
//     **SourceOfCurrency - Array of String -
//
Function Indicators(RegisterName) Export

	If IsBlankString(RegisterName) Or Metadata.AccumulationRegisters.Find(RegisterName) = Undefined Then
		Return Undefined;
	EndIf;

	PropertiesOfIndicators = PropertiesOfIndicators();
	If Metadata.AccumulationRegisters.Find(RegisterName) <> Undefined Then
		Indicators = AccumulationRegisters[RegisterName].Indicators(PropertiesOfIndicators);
	Else
		Indicators = Undefined;
	EndIf;
	
	Return Indicators;

EndFunction

// Identifies indicators in the currency of the register.
//
// Parameters:
//  RegisterName - String - register name.
//
// Returns:
//  Map - The key is the name of the indicator.
//				   Value - the structure of the properties of the indicator.
//
Function IndicatorsInCurrency(RegisterName) Export

	If IsBlankString(RegisterName) Or Metadata.AccumulationRegisters.Find(RegisterName) = Undefined Then
		Return Undefined;
	EndIf;

	PropertiesOfIndicators = PropertiesOfIndicatorsInCurrency();
	IndicatorsInCurrency = AccumulationRegisters[RegisterName].IndicatorsInCurrency(PropertiesOfIndicators);
	
	Return IndicatorsInCurrency;

EndFunction

// Determines the number.
//
// Parameters:
//  RegisterName - String - register name.
//
// Returns:
//  Map - The key is the name of the source. 
//				   Value - the structure of the source properties. 
//
Function QuantityIndicators(RegisterName) Export

	If IsBlankString(RegisterName) Or Metadata.AccumulationRegisters.Find(RegisterName) = Undefined Then
		Return Undefined;
	EndIf;
	
	QuantityIndicators = AccumulationRegisters[RegisterName].QuantityIndicators();
	
	Return QuantityIndicators;

EndFunction
// Gets the properties of an international accounting account
//
// Parameters:
//  Account - ChartOfAccountsRef.International - International chart of accounts account.
//
// Returns:
//  Structure - Account properties:
//		* Ref - ChartOfAccountsRef.International -
//		* Description - String -
//		* DescriptionInternational - String -
//		* LongDesc - String -
//		* Reclass - Boolean -
//		* ExcludeFromExchangeDifferenceCalculationInFunctionalCurrency - Boolean -
//		* Code - String -
//		* Parent - ChartOfAccountsRef.International -
//		* Kind - AccountType -
//		* OffBalance - Boolean -
//		* RestrictUseInPostings - Boolean
//		* Currency1 - Boolean -
//		* Quantitative - Boolean -
//		* AccountingByBusinessUnits - Boolean - 
//		* AccountingByLinesOfBusiness - Boolean -
//		* ExtDimensionCount - Number -
//		* ChartOfAccounts - CatalogRef.FinancialAccountingChartsOfAccounts -
//		* OptionForGeneratingTransactions - EnumRef.EntryGenerationOptions -
//		* ExtDimensionType1 - Undefined, ChartOfCharacteristicTypesRef.FinancialExtraDimensionTypes -
//		* ExtDimensionType1Description - Undefined, String -
//		* ExtDimensionType1ValueType - Undefined, TypeDescription -
//		* ExtDimensionType1TurnoversOnly - Boolean -
//		* ExtDimensionType2 - Undefined, ChartOfCharacteristicTypesRef.FinancialExtraDimensionTypes -
//		* ExtDimensionType2Description - Undefined, String -
//		* ExtDimensionType2ValueType - Undefined, TypeDescription -
//		* ExtDimensionType2TurnoversOnly - Boolean -
//		* ExtDimensionType3 - Undefined, ChartOfCharacteristicTypesRef.FinancialExtraDimensionTypes -
//		* ExtDimensionType3Description - Undefined, String -
//		* ExtDimensionType3ValueType - Undefined, TypeDescription -
//		* ExtDimensionType3TurnoversOnly - Boolean -
//
Function AccountProperties(Val Account) Export
	
	InvoiceData = New Structure;
	InvoiceData.Insert("Ref", ChartsOfAccounts.International.EmptyRef());
	InvoiceData.Insert("Description", "");
	InvoiceData.Insert("DescriptionInternational", "");
	InvoiceData.Insert("LongDesc", "");
	InvoiceData.Insert("Reclass", False);
	InvoiceData.Insert("ExcludeFromExchangeDifferenceCalculationInFunctionalCurrency", False);
	InvoiceData.Insert("Code", "");
	InvoiceData.Insert("Parent", ChartsOfAccounts.International.EmptyRef());
	InvoiceData.Insert("Kind", AccountType.ActivePassive);
	InvoiceData.Insert("OffBalance", False);
	InvoiceData.Insert("RestrictUseInPostings" , False);
	InvoiceData.Insert("Currency1", False);
	InvoiceData.Insert("Quantitative", False);
	InvoiceData.Insert("AccountingByBusinessUnits" , False);
	InvoiceData.Insert("AccountingByLinesOfBusiness", False);
	InvoiceData.Insert("ExtDimensionCount", 0);
	InvoiceData.Insert("ChartOfAccounts", Catalogs.FinancialAccountingChartsOfAccounts.EmptyRef());
	InvoiceData.Insert("OptionForGeneratingTransactions", Enums.EntryGenerationOptions.EmptyRef());
	
	InvoiceData.Insert("ExtDimensionType1", Undefined);
	InvoiceData.Insert("ExtDimensionType1Description", Undefined);
	InvoiceData.Insert("ExtDimensionType1ValueType", Undefined);
	InvoiceData.Insert("ExtDimensionType1TurnoversOnly", False);
	
	InvoiceData.Insert("ExtDimensionType2", Undefined);
	InvoiceData.Insert("ExtDimensionType2Description", Undefined);
	InvoiceData.Insert("ExtDimensionType2ValueType", Undefined);
	InvoiceData.Insert("ExtDimensionType2TurnoversOnly", False);
	
	InvoiceData.Insert("ExtDimensionType3", Undefined);
	InvoiceData.Insert("ExtDimensionType3Description", Undefined);
	InvoiceData.Insert("ExtDimensionType3ValueType", Undefined);
	InvoiceData.Insert("ExtDimensionType3TurnoversOnly", False);

	If Not ValueIsFilled(Account) Then
		Return InvoiceData;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Account", Account);
	
	Query.Text = 
	"SELECT
	|	LF.Ref AS Ref,
	|	LF.Description AS Description,
	|	LF.DescriptionInternational AS DescriptionInternational,
	|	LF.LongDesc AS LongDesc,
	|	LF.Reclass AS Reclass,
	|	LF.ExcludeFromExchangeDifferenceCalculationInFunctionalCurrency AS ExcludeFromExchangeDifferenceCalculationInFunctionalCurrency,
	|	LF.Code AS Code,
	|	LF.Parent AS Parent,
	|	LF.Type AS Kind,
	|	LF.OffBalance AS OffBalance,
	|	LF.RestrictUseInPostings AS RestrictUseInPostings,
	|	LF.Currency1 AS Currency1,
	|	LF.Quantitative AS Quantitative,
	|	LF.AccountingByBusinessUnits AS AccountingByBusinessUnits,
	|	LF.AccountingByLinesOfBusiness AS AccountingByLinesOfBusiness,
	|	LF.ChartOfAccounts AS ChartOfAccounts,
	|	LF.ChartOfAccounts.OptionForGeneratingTransactions AS OptionForGeneratingTransactions
	|FROM
	|	ChartOfAccounts.International AS LF
	|WHERE
	|	LF.Ref = &Account
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InternationalExtdimensionDay.LineNumber AS LineNumber,
	|	InternationalExtdimensionDay.ExtDimensionType AS ExtDimensionType,
	|	InternationalExtdimensionDay.ExtDimensionType.Description AS Description,
	|	InternationalExtdimensionDay.ExtDimensionType.ValueType AS ValueType,
	|	InternationalExtdimensionDay.TurnoversOnly AS TurnoversOnly
	|FROM
	|	ChartOfAccounts.International.ExtDimensionTypes AS InternationalExtdimensionDay
	|WHERE
	|	InternationalExtdimensionDay.Ref = &Account
	|
	|ORDER BY
	|	InternationalExtdimensionDay.LineNumber";
	
	ResultsArray = Query.ExecuteBatch(); 
	
	SelectedInvoice = ResultsArray[0]; // QueryResult - 
	Selection = SelectedInvoice.Select();
	If Selection.Next() Then
		FillPropertyValues(InvoiceData, Selection);
	EndIf;
	
	AccountExtDimensionTypes = ResultsArray[1]; // QueryResult - 
	SamplingExtdimensionSpecies = AccountExtDimensionTypes.Select();
	InvoiceData.ExtDimensionCount = SamplingExtdimensionSpecies.Count();
	
	ExtDimensionIndex = 0;
	While SamplingExtdimensionSpecies.Next() Do
		
		ExtDimensionIndex = ExtDimensionIndex + 1;
		
		InvoiceData.Insert("ExtDimensionType" + ExtDimensionIndex,                   SamplingExtdimensionSpecies.ExtDimensionType);
		InvoiceData.Insert("ExtDimensionType" + ExtDimensionIndex + "Description",  SamplingExtdimensionSpecies.Description);
		InvoiceData.Insert("ExtDimensionType" + ExtDimensionIndex + "ValueType",   SamplingExtdimensionSpecies.ValueType);
		InvoiceData.Insert("ExtDimensionType" + ExtDimensionIndex + "TurnoversOnly", SamplingExtdimensionSpecies.TurnoversOnly);
		
	EndDo;
	
	Return InvoiceData;
	
EndFunction

// Returns the types of the case attribute.
//
// Parameters:
//	RegisterName - String - register name.
//	AttributeName - String - attribute name.
//
// Returns:
//	Array - array of register attribute types.
//
Function TypesOfRegisterAttribute(RegisterName, AttributeName) Export

	TypesArray = New Array;
	Dimension = Metadata.AccumulationRegisters[RegisterName].Dimensions.Find(AttributeName);
	If Dimension <> Undefined Then
		TypesArray = Dimension.Type.Types();
	EndIf;
	
	Attribute = Metadata.AccumulationRegisters[RegisterName].Attributes.Find(AttributeName);
	If Attribute <> Undefined Then
		TypesArray = Attribute.Type.Types();
	EndIf;
	
	Return TypesArray;
	
EndFunction

// Returns status based on status priorities.
// 
// Parameters:
//	CurrentStatus - EnumRef.StatusesOfPostingsInFinancialAccounting - current status.
//	NewStatus - EnumRef.StatusesOfPostingsInFinancialAccounting - current status.
//
// Returns:
//	EnumRef.StatusesOfPostingsInFinancialAccounting - set the status.
//
Function DetermineStatus(CurrentStatus, NewStatus) Export

	CurStatusPriority = StatusPriority(CurrentStatus);
	PriorityOfNewStatus = StatusPriority(NewStatus);
	Return ?(CurStatusPriority = Undefined Or PriorityOfNewStatus < CurStatusPriority, NewStatus, CurrentStatus);

EndFunction

// Returns the maximum number of sub-accounts in the international chart of accounts
//
// Returns:
// 	Number - 
Function MaxExtDimensionCount() Export
	Return Metadata.ChartsOfAccounts.International.MaxExtDimensionCount;
EndFunction
#EndRegion

#Region Internal

Function CurrentExtdimension() Export
	
	QueryText = "
	|SELECT
	|	NegotiableExtdimensionTypes.ExtDimensionType AS ExtDimensionType
	|INTO TTNegotiableExtdimensionTypes
	|FROM
	|	ChartOfAccounts.International.ExtDimensionTypes AS NegotiableExtdimensionTypes
	|WHERE
	|	NegotiableExtdimensionTypes.TurnoversOnly
	|	AND NOT TRUE IN
	|	(SELECT TOP 1
	|		TRUE
	|	FROM
	|		ChartOfAccounts.International.ExtDimensionTypes AS AllKindsOfExtdimension
	|	WHERE
	|		AllKindsOfExtdimension.ExtDimensionType = NegotiableExtdimensionTypes.ExtDimensionType
	|		AND NOT AllKindsOfExtdimension.TurnoversOnly
	|	)
	|GROUP BY
	|	NegotiableExtdimensionTypes.ExtDimensionType
	|;
	|
	|SELECT
	|	NegotiableExtdimensionTypes.ExtDimensionType AS ExtDimensionType,
	|	NegotiableExtdimensionTypes.ExtDimensionType.ValueType AS ValueType
	|FROM
	|	TTNegotiableExtdimensionTypes AS NegotiableExtdimensionTypes
	|";
	
	Query = New Query(QueryText);
	Results = Query.ExecuteBatch();

	Return Results[1].Unload();

EndFunction

Function UsedSettingsForGeneratingTransactions(Period, ChartOfAccounts, Organization) Export
	
	Query = New Query();
	Query.Text = "
	|SELECT TOP 1
	|	OrganizationsAccountPlansCrossSection.PostingGenerationSetting AS PostingGenerationSetting
	|FROM
	|	InformationRegister.FinancialAccountingChartsOfAccountsForCompanies.SliceLast(&Period,
	|		ChartOfAccounts = &ChartOfAccounts
	|		AND Organization = &Organization
	|	) AS OrganizationsAccountPlansCrossSection
	|";
	
	Query.SetParameter("Period", Period);
	Query.SetParameter("ChartOfAccounts", ChartOfAccounts);
	Query.SetParameter("Organization", Organization);
	
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		Return Catalogs.FinancialAccountingPostingGenerationSetting.EmptyRef();
	Else
		Selection = Result.Select();
		Selection.Next();
		Return Selection.PostingGenerationSetting;
	EndIf;
	
EndFunction


#EndRegion

#Region Private

Function PropertiesOfInvoiceRefinementSource()

	// Decoding the source properties:
	// Field name is the name of the attribute of the accumulation register from which it is planned to receive the source of account refinement.
	
	Return "FieldName";

EndFunction

Function PropertiesOfIndicators()

	PropertiesOfIndicators = New Structure("PropertiesOfIndicators, ResourceProperties");
	
	// Decoding the properties of indicators:
	// Resources - an array of register resources associated with the indicator.
	PropertiesOfIndicators.PropertiesOfIndicators = "Resources";
	
	// Decoding resource properties:
	// Name - the name of the register resource.
	// The source of the currency is the source of the currency for the register resource.
	PropertiesOfIndicators.ResourceProperties = "Name, SourceOfCurrency";
	
	Return PropertiesOfIndicators;

EndFunction

Function PropertiesOfIndicatorsInCurrency()

	// Decoding the properties of indicators:
	// The source of the currency is the source of the currency for the register indicator.
	
	Return "SourceOfCurrency";

EndFunction

Function StatusPriority(Status)

	Return StatusPriorities().Get(Status);

EndFunction

Function StatusPriorities()

	StatusPriorities = New Map;
	StatusPriorities.Insert(Enums.StatusesOfPostingsInFinancialAccounting.DoubleEntryOfFinancialRegistersIsBroken, 0);
	StatusPriorities.Insert(Enums.StatusesOfPostingsInFinancialAccounting.PendingPostingInLocalAccounting, 1);
	StatusPriorities.Insert(Enums.StatusesOfPostingsInFinancialAccounting.ForManualPostingInAccounting, 2);
	StatusPriorities.Insert(Enums.StatusesOfPostingsInFinancialAccounting.RulesOfRecordingInAccountingAreNotdefined, 3);
	StatusPriorities.Insert(Enums.StatusesOfPostingsInFinancialAccounting.ForPostingInAccounting, 4);
	StatusPriorities.Insert(Enums.StatusesOfPostingsInFinancialAccounting.ManuallyPostedToAccounting, 5);
	StatusPriorities.Insert(Enums.StatusesOfPostingsInFinancialAccounting.PostedToAccounting, 6);
	
	Return StatusPriorities;

EndFunction
#EndRegion
