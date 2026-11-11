
#Region Public
#Region ActualDataQueryRules

// Returns a reference to the schema by type, section, and specified data source
// It is intended for depersonalized, link-independent cached retrieval of schemas from reference books-
// data acquisition rules If the schema is modified later in the code, then it will be returned from the cache.
// 
// Parameters:
//  SourceCatalogName - String - for example, " rules for getting Factapoindicatorsbudgetsreferences"
//  DataSourceSection - EnumRef.SectionsOfBudgetingDataSources - operational, international or
//                                                                                     local accounting.
//  DataSource - CatalogRef.BusinessTransactionsSettings, ChartOfCharacteristicTypesRef.AssetLiabilityItems - an object
//    containing the name of the SKD layout in the rule.
// 
// Returns:
// 	 DataCompositionSchema - The schema of the data collection is a scheme for obtaining the actual data corresponding to the source. 
//						   - Undefined - if the layout is not found.
//
Function DataLayoutRules(SourceCatalogName, DataSourceSection, DataSource) Export
	
	DataLayoutRules = Undefined;
	SchemaName = Undefined;
	
	SourceSections = Enums.SectionsOfBudgetingDataSources;
	
	If DataSourceSection = SourceSections.OperationalAccounting Then
		
		If ValueIsFilled(DataSource) Then
			SchemaName = NameOfTemplateBySourceValue(DataSource);
		EndIf;
		
	ElsIf DataSourceSection = SourceSections.LocalAccounting Then
		
		SchemaName = "LocalAccounting";
	ElsIf DataSourceSection = SourceSections.FinancialAccounting Then
		
		OptionForGeneratingTransactions = FinancialAccountingOfGeneralPurpose.OptionForGeneratingTransactionsByAccount(DataSource);
		If OptionForGeneratingTransactions  = Enums.EntryGenerationOptions.WithoutCorrespondence Then
			SchemaName = "FinancialAccountingWithoutCorrespondence";
		Else
			SchemaName = "FinancialAccountingWithCorrespondence";
		EndIf;
	Else
		Raise NStr("vi = 'Phần không hợp lệ của nguồn nhận dữ liệu.';
					|ru = 'Недопустимый раздел источника получения данных.';
					|en = 'Invalid section of data receipt source.'; fa = 'Invalid section of data receipt source.';
					|it = 'Argomento dell''origine dati non valido.';
					|pl = 'Niedopuszczalny rozdział źródła pobierania danych.';
					|tr = 'Veri alım kaynağının kabul edilemeyecek bölümü'");
	EndIf;
	
	DataLayoutRules = GettingCatalogTemplate(SourceCatalogName, SchemaName);
	
	Return DataLayoutRules;
	
EndFunction

// Returns a reference to the schema by type, section, and the specified data layout hash
// It is intended for depersonalized, link-independent cached retrieval of schemas from reference books-
// data acquisition rules If the schema is modified later in the code, then it will be returned from the cache.
// 
// Parameters:
//  SourceCatalogName - String - for example, " rules for getting Factapoindicatorsbudgetsreferences"
//  DataSourceSection - EnumRef.SectionsOfBudgetingDataSources - arbitrary data
//  HashOfDataCompositionSchema - String - hash sum of an arbitrary data layout scheme.
// 
// Returns:
// 	 DataCompositionSchema - The schema of the data collection is a scheme for obtaining the actual data corresponding to the source. 
//						   - Undefined - if the layout is not found.
//
Function ArbitraryDataLayoutSchemeRules(SourceCatalogName, DataSourceSection, HashOfDataCompositionSchema) Export
	
	DataLayoutRules = Undefined;
	
	If Not DataSourceSection = Enums.SectionsOfBudgetingDataSources.CustomQuery Then
		Raise NStr("vi = 'Phần không hợp lệ của nguồn nhận dữ liệu.';
					|ru = 'Недопустимый раздел источника получения данных.';
					|en = 'Invalid section of data receipt source.'; fa = 'Invalid section of data receipt source.';
					|it = 'Argomento dell''origine dati non valido.';
					|pl = 'Niedopuszczalny rozdział źródła pobierania danych.';
					|tr = 'Veri alım kaynağının kabul edilemeyecek bölümü'");
	EndIf;
	
	FoundDataSourceSchema = GettingStoredCatalogTemplate(SourceCatalogName, HashOfDataCompositionSchema);
	
	If Not FoundDataSourceSchema = Undefined Then
		DataLayoutRules = FoundDataSourceSchema;
	EndIf;
	
	Return DataLayoutRules;
	
EndFunction

// Returns a match between supported types and their names
// 
// Returns:
// 	 Map of KeyAndValue:
//		*Key - Type- type of supported metadata object
//		*Value - String - the Name Of The Catalog as it is specified in the Configurator.
//
Function SupportedCatalogDataSources() Export
	SupportedServices = New Map;
	SupportedServices.Insert(Type("CatalogRef.ActualDataQueryRulesByBudgetBalanceItems"), "ActualDataQueryRulesByBudgetBalanceItems");
	SupportedServices.Insert(Type("CatalogRef.ActualDataQueryRulesByBudgetFlowItems"),     "ActualDataQueryRulesByBudgetFlowItems");
	
	Return SupportedServices;
EndFunction

// Returns the default schema name in case no other schemas are found
// 
// Returns:
// 	 Map of KeyAndValue:
//		*Key - String - the Name Of The Catalog, as it is set in the Configurator
//		*Value - String - the Name Of The Data Layout Template.
//
Function DefaultSchemaNamesForDataSources() Export
	Defaults = New Map;
	Defaults.Insert("ActualDataQueryRulesByBudgetBalanceItems", "OtherAssetsLiabilities");
	Defaults.Insert("ActualDataQueryRulesByBudgetFlowItems", "");
	
	Return Defaults;
EndFunction

// Returns the layout from the specified reference list
//
// Parameters:
//  SourceCatalogName - String - for example, " rules for getting Factapoindicatorsbudgetsreferences"
//  TemplateName               - String - for example, "issued Balances".
//
// Returns:
//  SpreadsheetDocument, TextDocument - an object that can be a layout. 
//
Function GettingCatalogTemplate(SourceCatalogName, Val TemplateName = Undefined) Export

	Var TemplateYouAreLookingFor;
	
	If Not IsBlankString(TemplateName) Then
		If Metadata.Catalogs[SourceCatalogName].Templates.Find(TemplateName) = Undefined Then
			TemplateName = DefaultSchemaNamesForDataSources()[SourceCatalogName];
		EndIf;
		TemplateYouAreLookingFor = Catalogs[SourceCatalogName].GetTemplate(TemplateName);
	EndIf;
	
	Return TemplateYouAreLookingFor;

EndFunction

// Returns an array of supported source types for the layout name
// 
// Returns:
// 	 Array of Type - the type of supported metadata object.
//
Function SupportedTemplateNameSourceTypes() Export
	SupportedServices = New Array;
	SupportedServices.Add(Type("CatalogRef.BusinessTransactionsSettings"));
	SupportedServices.Add(Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems"));
	SupportedServices.Add(Type("EnumRef.BusinessTransactions"));
	
	Return SupportedServices;
EndFunction

// Returns the stored configuration from the specified directory
//
// Parameters:
//  SourceCatalogName  - String - for example, " rules for getting Factapoindicatorsbudgetsreferences"
//  SettingsHash - String - hash-sum of configured data layout selections.
//
// Returns:
//  DataCompositionSettingsComposer 
//
Function GetStoredCatalogSettings(SourceCatalogName, SettingsHash) Export
	
	Return DataSourcesServer.GetStoredCatalogSettings(SourceCatalogName, SettingsHash);
	
EndFunction

// Returns the stored layout from the specified reference list
//
// Parameters:
//  SourceCatalogName  - String - for example, " rules for getting Factapoindicatorsbudgetsreferences"
//  HashOfDataCompositionSchema - String - hash-sum of an arbitrary data layout scheme.
//
// Returns:
//  SpreadsheetDocument, TextDocument - an object that can be a layout. 
//
Function GettingStoredCatalogTemplate(SourceCatalogName, HashOfDataCompositionSchema) Export
	
	Return DataSourcesServer.GettingStoredCatalogTemplate(SourceCatalogName, HashOfDataCompositionSchema);
	
EndFunction

// Returns a description of the types of rules for getting actual data
//
// Returns:
//  TypeDescription
//
Function DescriptionOfRuleType() Export
	TypesOfRules = New Array;
	TypesOfRules.Add(Type("CatalogRef.ActualDataQueryRulesByBudgetBalanceItems"));
	TypesOfRules.Add(Type("CatalogRef.ActualDataQueryRulesByBudgetFlowItems"));
	
	Return New TypeDescription(TypesOfRules);
EndFunction 

// Returns a description of the types of the rule type for getting actual data
//
// Returns:
//  TypeDescription
//
Function DescriptionOfTypeOfBudgetingData() Export
	Return New TypeDescription("EnumRef.ActualBudgetingDataQueryRuleType");
EndFunction 

// Returns the sum metric expression for the rule for getting actual data.
// 
// Parameters:
//	SourceCatalogName      - String - For example, "The rules for obtaining the actual evidence of budgets." See DataSourcesCached.SupportedCatalogDataSources
//	DataSourceID - String - name of the supplied layout or hash sum of an arbitrary data layout scheme. The SKD must have a data set - a combined Fact
//	SourceOfCurrency               - String - values can be "Currency", "Valutor", "Valutare", "Salutational", "Coralita"
//	DataSourceSection        - EnumRef.SectionsOfBudgetingDataSources - operational, international, regulated accounting or arbitrary data
//	TotalType                     - EnumRef.TypesOfTotals - type of total account data, if it is the data source
//	TransactionAmountSource        - EnumRef.IndicatorsOfAnalyticalRegisters, Undefined - source of getting the amount from the analytical register
//  SourceOfForeignExchange             - Boolean - indicates that the amounts may be stored in different currencies.
//
// Returns:
//	String - the name of the field in the data source schema.
//
Function IndicatorExpressionAmounts(SourceCatalogName, DataSourceID, SourceOfCurrency, DataSourceSection, TotalType, TransactionAmountSource = Undefined, SourceOfForeignExchange = False) Export
	
	IndicatorExpressionAmounts = Undefined;
	
	SourcesOfSum = AmountIndicatorExpressions(SourceCatalogName, 
		DataSourceID, 
		DataSourceSection, 
		TotalType, 
		TransactionAmountSource,
		SourceOfForeignExchange);
	
	SourcesOfSum.Property(SourceOfCurrency, IndicatorExpressionAmounts);
	
	Return IndicatorExpressionAmounts;
	
EndFunction

// Returns all possible sum metric expressions for the rule for getting actual data.
// 
// Parameters:
//  SourceCatalogName      - String - For example, "The rules for obtaining the actual evidence of budgets." See DataSourcesCached.SupportedCatalogDataSources
//  DataSourceID - String - the name of the supplied Template or the hash sum of an arbitrary data layout scheme.
//                                          There should be a data set in the DCS - a combined fact.
//  DataSourceSection        - EnumRef.SectionsOfBudgetingDataSources - operational,
//      international, local accounting or arbitrary data.
//  TotalType                     - EnumRef.TypesOfTotals, Undefined - the type of total data for the invoice, if it
//                                                                               is the data source.
//  TransactionAmountSource        - EnumRef.IndicatorsOfAnalyticalRegisters, Undefined - the source
//      of receiving the amount from the analytical register.
//  SourceOfForeignExchange             - Boolean - indicates that the amounts may be stored in different currencies.
//
// Returns:
//	Structure - compared fact indicators and data source fields:
//		*Key     - String - name of the actual data metric
//		*Value - String - the name of the field in the data source schema.
// 
Function AmountIndicatorExpressions(SourceCatalogName, DataSourceID, DataSourceSection, TotalType = Undefined, TransactionAmountSource = Undefined, SourceOfForeignExchange = False) Export
	
	SourcesOfSum = New Structure;
	DataSourceSections = Enums.SectionsOfBudgetingDataSources;
	
	If DataSourceSection = DataSourceSections.OperationalAccounting
		And ValueIsFilled(DataSourceID) Then
		
		If GetFunctionalOption("SetUpRulesForObtainingActualDataByAssetAndLiabilityItems") Then
			RuleOnItemOfAssetsLiabilities = DataSourcesServer.ThisIsItemOfAssetsLiabilities(DataSourceID);
		Else
			RuleOnItemOfAssetsLiabilities = False;
		EndIf;
		
		If RuleOnItemOfAssetsLiabilities Then
			DataSource = ChartsOfCharacteristicTypes.AssetLiabilityItems[DataSourceID];
		ElsIf DataSourceID <> "CashFlowToPayment" Then
			SuppliedCircuit = GettingCatalogTemplate(SourceCatalogName, DataSourceID);
			DataSet = SourceDCSDataSet(SuppliedCircuit, SourceCatalogName, DataSourceID);
		EndIf;
		
		If SourceCatalogName = "ActualDataQueryRulesByBudgetBalanceItems" Then
			
			If RuleOnItemOfAssetsLiabilities Then
				RegisterIndicators = IndicatorsOfSumOfItemOfAssetsLiabilities(DataSource);
				SumSourceResources = RegisterIndicators.Get(TransactionAmountSource).Resources;
				
				For Each Resource In SumSourceResources Do
					AmountField = Resource["Name"];
					If Resource["SourceOfCurrency"] = "CurrencyOfMan" Then
						SourcesOfSum.Insert("CurrencyOfMan", AmountField);
					ElsIf Resource["SourceOfCurrency"] = "ComplCurrency" Then
						SourcesOfSum.Insert("ComplCurrency", AmountField);
					Else
						SourcesOfSum.Insert("Currency", AmountField);
					EndIf;
				EndDo;
			Else
				BudgetingServer.FillInSourcesOfAmountAccordingToScheme(SourcesOfSum, DataSet, True);
			EndIf;
			
		ElsIf SourceCatalogName = "ActualDataQueryRulesByBudgetFlowItems" Then
			
			If DataSourceID = "CashFlowToPayment" Then
				RegisterIndicators = RegisteredRecordsOfCashDisbursements();
			ElsIf RuleOnItemOfAssetsLiabilities Then
				RegisterIndicators = IndicatorsOfSumOfItemOfAssetsLiabilities(DataSource);
			Else
				RegisterIndicators = FinancialAccountingServerCached.Indicators(DataSourceID);
			EndIf;
			SumSourceResources = RegisterIndicators.Get(TransactionAmountSource).Resources;
			
			For Each Resource In SumSourceResources Do
				AmountField = Resource["Name"];
				If DataSourceID <> "CashFlowToPayment"
					And DataSet.Fields.Find(AmountField) = Undefined Then
					// The resource is not selected in the source
					Continue;
				EndIf;
				If Resource["SourceOfCurrency"] = "CurrencyOfMan" Then
					SourcesOfSum.Insert("CurrencyOfMan", AmountField);
				ElsIf Resource["SourceOfCurrency"] = "ComplCurrency" Then
					SourcesOfSum.Insert("ComplCurrency", AmountField);
				Else
					SourcesOfSum.Insert("Currency", AmountField);
				EndIf;
			EndDo;
			
		EndIf;
		
	ElsIf DataSourceSection = DataSourceSections.LocalAccounting Then
		
		SourcesOfSum.Insert("ComplCurrency", BudgetingServer.AccountingResourceField("Sum", TotalType));
		SourcesOfSum.Insert("CurrencyOfMan", BudgetingServer.AccountingResourceField("AmountOfUU", TotalType));
		If SourceOfForeignExchange Then
			SourcesOfSum.Insert("Currency", BudgetingServer.AccountingResourceField("AmountInCurrency", TotalType));
		EndIf;
		
	ElsIf DataSourceSection = DataSourceSections.FinancialAccounting Then
		
		SourcesOfSum.Insert("InternationalCurrency", BudgetingServer.AccountingResourceField("Sum", TotalType));
		If SourceOfForeignExchange Then
			SourcesOfSum.Insert("Currency", BudgetingServer.AccountingResourceField("AmountInCurrency", TotalType));
		EndIf;
		
	ElsIf DataSourceSection = DataSourceSections.CustomQuery Then
		
		ArbitraryScheme = GettingStoredCatalogTemplate(SourceCatalogName, DataSourceID);
		
		DataSet = SourceDCSDataSet(ArbitraryScheme, SourceCatalogName, DataSourceID);
	
		BudgetingServer.FillInSourcesOfAmountAccordingToScheme(SourcesOfSum, DataSet, True);
		
	EndIf;
	
	Return SourcesOfSum;
	
EndFunction

// Returns a quantitative indicator expression for the rule for getting actual data.
// 
// Parameters:
//  SourceCatalogName      - String - For example, "The rules for obtaining the actual evidence of budgets." See DataSourcesCached.SupportedCatalogDataSources
//  DataSourceID - String - name of the supplied layout or hash sum of an arbitrary data layout scheme
//  DataSourceSection        - EnumRef.SectionsOfBudgetingDataSources - operational,
//      international, local accounting or arbitrary data.
//  TotalType                     - EnumRef.TypesOfTotals - the type of total data for the account, if it is the data source.
//	TransactionAmountSource        - EnumRef.IndicatorsOfAnalyticalRegisters, Undefined - source of getting the amount from the analytical register
//
// Returns:
//	Structure - compared fact indicators and data source fields:
//		*Key     - String - name of the actual data metric
//		*Value - String - the name of the field in the data source schema.
// 
Function IndicatorExpressionQuantities(SourceCatalogName, DataSourceID, DataSourceSection, TotalType, TransactionAmountSource = Undefined) Export
	
	IndicatorExpressionQuantities = Undefined;
	
	SourcesOfQuantity = New Structure;
	DataSourceSections = Enums.SectionsOfBudgetingDataSources;
	
	If DataSourceSection = DataSourceSections.OperationalAccounting
		And ValueIsFilled(DataSourceID)
		And DataSourceID <> "CashFlowToPayment" Then
		
		If GetFunctionalOption("SetUpRulesForObtainingActualDataByAssetAndLiabilityItems") Then
			RuleOnItemOfAssetsLiabilities = DataSourcesServer.ThisIsItemOfAssetsLiabilities(DataSourceID);
		Else
			RuleOnItemOfAssetsLiabilities = False;
		EndIf;
		
		If RuleOnItemOfAssetsLiabilities Then
			DataSource = ChartsOfCharacteristicTypes.AssetLiabilityItems[DataSourceID];
			RegisterIndicators = IndicatorsOfNumberOfItemsOfAssetsLiabilities(DataSource);
			QuantitySourceResources = RegisterIndicators.Get(TransactionAmountSource);
			
			If QuantitySourceResources.Count() > 0 Then
				SourcesOfQuantity.Insert("Count", "Count");
			Else
				SourcesOfQuantity.Insert("Count", "0");
			EndIf;
		Else
			SuppliedCircuit = GettingCatalogTemplate(SourceCatalogName, DataSourceID);
			BudgetingServer.FillInSourcesOfQuantityAccordingToScheme(SourcesOfQuantity, SuppliedCircuit.DataSets[0]);
		EndIf;
			
	ElsIf DataSourceSection = DataSourceSections.LocalAccounting
			Or DataSourceSection = DataSourceSections.FinancialAccounting Then
		
		SourcesOfQuantity.Insert("Count", BudgetingServer.AccountingResourceField("Count", TotalType));
		
	ElsIf DataSourceSection = DataSourceSections.CustomQuery Then
		
		ArbitraryScheme = GettingStoredCatalogTemplate(SourceCatalogName, DataSourceID);
		BudgetingServer.FillInSourcesOfQuantityAccordingToScheme(SourcesOfQuantity, ArbitraryScheme.DataSets[0]);
		
	EndIf;
	
	SourcesOfQuantity.Property("Count", IndicatorExpressionQuantities);
	
	Return IndicatorExpressionQuantities;
	
EndFunction

// Returns service fields-dimensions that are not available for user selection
//
// Returns:
//	Array of String - array of service fields-dimensions.
//
Function ServiceFieldsOfCalculationTemplates() Export
	
	ServiceFields = New Array;
	
	ServiceFields.Add("SystemFields");
	ServiceFields.Add("DataParameters");
	
	// Period fields are not selection fields
	ServiceFields.Add("SecondPeriod");
	ServiceFields.Add("DayPeriod");
	ServiceFields.Add("WeekPeriod");
	ServiceFields.Add("TenDaysPeriod");
	ServiceFields.Add("MonthPeriod");
	ServiceFields.Add("QuarterPeriod");
	ServiceFields.Add("HalfYearPeriod");
	ServiceFields.Add("YearPeriod");
	ServiceFields.Add("RatePeriod");
	ServiceFields.Add("Period");
	
	// Auxiliary fields
	ServiceFields.Add("DataSourceID");
	ServiceFields.Add("BusinessOperation");
	ServiceFields.Add("Account");
	ServiceFields.Add("DataSource");
	ServiceFields.Add("CorDataSource");
	
	// Auxiliary parameter
	ServiceFields.Add("PrivilegedMode");
	ServiceFields.Add("SourcePrivilegedMode");
	
	// Field for generating correspondence registers
	ServiceFields.Add("FinRecordID");
	
	Return ServiceFields;
	
EndFunction

// Returns the correspondence of the sum indicators for the business of operation, depending on the types of accounting data Receipt and expense
//
// Parameters:
//  DataSource - CatalogRef.BusinessTransactionsSettings
//  ChoiceList - Boolean - True if a list of indicators is generated for the user to select
//
// Returns:
//	Map of KeyAndValue:
//	* Key - EnumRef.IndicatorsOfAnalyticalRegisters
//	* Value - String - the name of the field associated with the indicator.
//
Function AmountIndicatorsByDataSource(DataSource, ChoiceList = False) Export
	
	If TypeOf(DataSource) <> Type("CatalogRef.BusinessTransactionsSettings") Then
		Return Undefined;
	EndIf;
	
	TypesOfSourceAccountingData = Common.ObjectAttributesValues(DataSource, "Receipt, Expense");
	AccountingDataTypes = New Array;
	AccountingDataTypes.Add(TypesOfSourceAccountingData.Receipt);
	If TypesOfSourceAccountingData.Receipt <> TypesOfSourceAccountingData.Expense Then
		AccountingDataTypes.Add(TypesOfSourceAccountingData.Expense);
	EndIf;
	
	Indicators = New Map;
	
	PropertiesOfIndicators = "Resources";
	ResourceProperties = "Name, SourceOfCurrency";
	
	If AccountingDataTypes.Find(Enums.AccountingDataTypes.Cash) <> Undefined Then
		
		If Not LimitsByBudgetingDataServer.RegisterOfBudgetingLimitsIsUsed() Or Not ChoiceList Then
			
			ArrayOfResources = New Array;
			ArrayOfResources.Add(New Structure(ResourceProperties, "AmountToBePaidWithinLimit", "Currency"));
			Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.AmountToBePaidWithinLimit,
				New Structure(PropertiesOfIndicators, ArrayOfResources));
			
			ArrayOfResources = New Array;
			ArrayOfResources.Add(New Structure(ResourceProperties, "AmountToBePaidAboveLimit", "Currency"));
			Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.AmountToBePaidAboveLimit,
				New Structure(PropertiesOfIndicators, ArrayOfResources));
			
			ArrayOfResources = New Array;
			ArrayOfResources.Add(New Structure(ResourceProperties, "AmountToBePaid", "Currency"));
			Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.AmountToBePaid,
				New Structure(PropertiesOfIndicators, ArrayOfResources));
			
		EndIf;
		
		If AccountingDataTypes.Find(Enums.AccountingDataTypes.Counterparties) <> Undefined Then
			
			ArrayOfResources = New Array;
			ArrayOfResources.Add(New Structure(ResourceProperties, "ManPaymentAmount", "CurrencyOfMan"));
			ArrayOfResources.Add(New Structure(ResourceProperties, "PaymentAmountLocal", "ComplCurrency"));
			ArrayOfResources.Add(New Structure(ResourceProperties, "PaymentAmountShaft", "Currency"));
			Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.PayAmount, New Structure(PropertiesOfIndicators, ArrayOfResources));
			
			ArrayOfResources = New Array;
			ArrayOfResources.Add(New Structure(ResourceProperties, "AmountOfManSPostPayment", "CurrencyOfMan"));
			ArrayOfResources.Add(New Structure(ResourceProperties, "PostpaymentAmountLocal", "ComplCurrency"));
			ArrayOfResources.Add(New Structure(ResourceProperties, "AmountOfPostPaymentShaft", "Currency"));
			Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.PostpaymentAmount,
				New Structure(PropertiesOfIndicators, ArrayOfResources));
			
			ArrayOfResources = New Array;
			ArrayOfResources.Add(New Structure(ResourceProperties, "ManSPrepaymentAmount", "CurrencyOfMan"));
			ArrayOfResources.Add(New Structure(ResourceProperties, "PrepaymentAmountLocal", "ComplCurrency"));
			ArrayOfResources.Add(New Structure(ResourceProperties, "PrepaymentAmountVal", "Currency"));
			Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.PrepaymentAmountMan,
				New Structure(PropertiesOfIndicators, ArrayOfResources));
		
		Else
			
			ArrayOfResources = New Array;
			ArrayOfResources.Add(New Structure(ResourceProperties, "SumMan", "CurrencyOfMan"));
			ArrayOfResources.Add(New Structure(ResourceProperties, "SumCompl", "ComplCurrency"));
			ArrayOfResources.Add(New Structure(ResourceProperties, "SumCurr", "Currency"));
			Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.Sum,
				New Structure(PropertiesOfIndicators, ArrayOfResources));
			
		EndIf;
	
	EndIf;
	
	If AccountingDataTypes.Find(Enums.AccountingDataTypes.Products) <> Undefined
		And TypesOfSourceAccountingData.Expense <> Enums.AccountingDataTypes.Counterparties Then
		
		ArrayOfResources = New Array;
		ArrayOfResources.Add(New Structure(ResourceProperties, "ManagementCost", "CurrencyOfMan"));
		ArrayOfResources.Add(New Structure(ResourceProperties, "CostLocal", "ComplCurrency"));
		Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.Cost_,
			New Structure(PropertiesOfIndicators, ArrayOfResources));
		
		ArrayOfResources = New Array;
		ArrayOfResources.Add(New Structure(ResourceProperties, "CostLocal", "ComplCurrency"));
		Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.CostLocal,
			New Structure(PropertiesOfIndicators, ArrayOfResources));
		
		ArrayOfResources = New Array;
		ArrayOfResources.Add(New Structure(ResourceProperties, "CostMan", "CurrencyOfMan"));
		ArrayOfResources.Add(New Structure(ResourceProperties, "LocalCost", "ComplCurrency"));
		Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.Cost,
			New Structure(PropertiesOfIndicators, ArrayOfResources));
		
		ArrayOfResources = New Array;
		ArrayOfResources.Add(New Structure(ResourceProperties, "LocalCost", "ComplCurrency"));
		Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.LocalCost,
			New Structure(PropertiesOfIndicators, ArrayOfResources));
		
		ArrayOfResources = New Array;
		ArrayOfResources.Add(New Structure(ResourceProperties, "AmountOfAdditionalExpenseAmountOfMan", "CurrencyOfMan"));
		ArrayOfResources.Add(New Structure(ResourceProperties, "AmountOfAdditionalExpensesAmountOfLocal", "ComplCurrency"));
		Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.AdditExpenseAmount,
			New Structure(PropertiesOfIndicators, ArrayOfResources));
		
		If TypesOfSourceAccountingData.Expense = Enums.AccountingDataTypes.Products Then
		
			ArrayOfResources = New Array;
			ArrayOfResources.Add(New Structure(ResourceProperties, "ProvisionForImpairmentMan", "CurrencyOfMan"));
			ArrayOfResources.Add(New Structure(ResourceProperties, "ProvisionForImpairmentLocal", "ComplCurrency"));
			Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.ProvisionForImpairment,
				New Structure(PropertiesOfIndicators, ArrayOfResources));
				
			If TypesOfSourceAccountingData.Receipt = Enums.AccountingDataTypes.Counterparties Then
				
				ArrayOfResources = New Array;
				ArrayOfResources.Add(New Structure(ResourceProperties, "CostWithoutVATMan", "CurrencyOfMan"));
				Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.CostExcludingVAT_,
					New Structure(PropertiesOfIndicators, ArrayOfResources));
				
				ArrayOfResources = New Array;
				ArrayOfResources.Add(New Structure(ResourceProperties, "CostExcludingVATMan", "CurrencyOfMan"));
				Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.CostExcludingVAT,
					New Structure(PropertiesOfIndicators, ArrayOfResources));
				
				ArrayOfResources = New Array;
				ArrayOfResources.Add(New Structure(ResourceProperties, "VATAmountOfCostOfMan", "CurrencyOfMan"));
				Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.VATCostAmount,
					New Structure(PropertiesOfIndicators, ArrayOfResources));

				ArrayOfResources = New Array;
				ArrayOfResources.Add(New Structure(ResourceProperties, "VATAmountOfAdditionalExpenseAmountOfMan", "CurrencyOfMan"));
				Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.AmountVATAdditionalExpense,
					New Structure(PropertiesOfIndicators, ArrayOfResources));
				
				ArrayOfResources = New Array;
				ArrayOfResources.Add(New Structure(ResourceProperties, "AmountOfAdditionalExpensesAmountExcludingVATMan", "CurrencyOfMan"));
				Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.AdditionalExpensesAmountExcludingVAT,
					New Structure(PropertiesOfIndicators, ArrayOfResources));
			
			EndIf;
		
		EndIf;
		
	EndIf;
	
	If AccountingDataTypes.Find(Enums.AccountingDataTypes.Counterparties) <> Undefined
		And AccountingDataTypes.Find(Enums.AccountingDataTypes.Cash) = Undefined Then
		
		ArrayOfResources = New Array;
		ArrayOfResources.Add(New Structure(ResourceProperties, "SumMan", "CurrencyOfMan"));
		ArrayOfResources.Add(New Structure(ResourceProperties, "SumCompl", "ComplCurrency"));
		Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.Sum,
			New Structure(PropertiesOfIndicators, ArrayOfResources));
		
		ArrayOfResources = New Array;
		ArrayOfResources.Add(New Structure(ResourceProperties, "AmountExcludingVATMan", "CurrencyOfMan"));
		ArrayOfResources.Add(New Structure(ResourceProperties, "AmountExcludingVATCompl", "ComplCurrency"));
		Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.AmountExcludingVAT,
			New Structure(PropertiesOfIndicators, ArrayOfResources));
		
		ArrayOfResources = New Array;
		ArrayOfResources.Add(New Structure(ResourceProperties, "VATAmountMan", "CurrencyOfMan"));
		ArrayOfResources.Add(New Structure(ResourceProperties, "VATAmountCompl", "ComplCurrency"));
		Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.VATAmount,
			New Structure(PropertiesOfIndicators, ArrayOfResources));
		
	EndIf;

	If Indicators.Count() = 0 Then
		
		If AccountingDataTypes.Find(Enums.AccountingDataTypes.VAT) <> Undefined Then
		
			ArrayOfResources = New Array;
			ArrayOfResources.Add(New Structure(ResourceProperties, "VATAmountMan", "CurrencyOfMan"));
			ArrayOfResources.Add(New Structure(ResourceProperties, "VATAmountCompl", "ComplCurrency"));
			Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.VATAmount,
				New Structure(PropertiesOfIndicators, ArrayOfResources));
		
		Else
		
			ArrayOfResources = New Array;
			ArrayOfResources.Add(New Structure(ResourceProperties, "SumMan", "CurrencyOfMan"));
			ArrayOfResources.Add(New Structure(ResourceProperties, "SumCompl", "ComplCurrency"));
			Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.Sum,
				New Structure(PropertiesOfIndicators, ArrayOfResources));
		
		EndIf;
		
	EndIf;
	
	Return Indicators;
	
EndFunction

// Returns the correspondence of indicators of analytical registers to the sum resources of the data source
// of the transferred item of assets and liabilities for calculating the actual data of items and budget indicators.
//
// Parameters:
//  DataSource - ChartOfCharacteristicTypesRef.AssetLiabilityItems
//
// Returns:
//  Map of KeyAndValue:
//  * Key - EnumRef.IndicatorsOfAnalyticalRegisters
//  * Value - Array of Structure - LongDesc:
//   ** Name - String - the name of the resource associated with the indicator
//   ** SourceOfCurrency - String - string Presentation of the resource currency
//
Function IndicatorsOfSumOfItemOfAssetsLiabilities(DataSource) Export
	
	If TypeOf(DataSource) <> Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems") Then
		Return Undefined;
	EndIf;
	
	AmountIndicators_ = New Map();
	PropertiesOfIndicators = "Resources";
	ResourceProperties = "Name, SourceOfCurrency";
	
	AssetLiabilityItemManager = ChartsOfCharacteristicTypes.AssetLiabilityItems;
	SourceMetrics = AssetLiabilityItemManager.IndicatorsOfArticleOfAssetsLiabilities(DataSource);
	
	For Each KeyAndValue In SourceMetrics Do
		Factor = KeyAndValue.Key;
		DescriptionIndicator = KeyAndValue.Value;
		ArrayOfResources = New Array();
		
		For Each KeyAndValue In DescriptionIndicator Do
			ResourceGroup = KeyAndValue.Key;
			ResourceTable = KeyAndValue.Value;
			
			If ResourceGroup = AssetLiabilityItemManager.ManagementAccountingResourcesGroup() Then
				ResourceName = "SumMan";
				SourceOfCurrency = "CurrencyOfMan";
			ElsIf ResourceGroup = AssetLiabilityItemManager.RegulatedAccountingResourcesGroup() Then
				ResourceName = "SumCompl";
				SourceOfCurrency = "ComplCurrency";
			ElsIf ResourceGroup = AssetLiabilityItemManager.CurrencyAccountingResourcesGroup() Then
				ResourceName = "AmountInCurrency";
				SourceOfCurrency = "Currency";
			Else
				Continue;
			EndIf;
			
			If ResourceTable.Count() > 0 Then
				ArrayOfResources.Add(New Structure(ResourceProperties, ResourceName, SourceOfCurrency));
			EndIf;;
		EndDo;
		
		AmountIndicators_.Insert(Factor, New Structure(PropertiesOfIndicators, ArrayOfResources));
	EndDo;
	
	Return AmountIndicators_;
	
EndFunction

// Returns the default totals of operations, depending on the types of accounting data Receipt and expense (for the official register of correspondence)
//
// Parameters:
//  DataSource - CatalogRef.BusinessTransactionsSettings
//
// Returns:
//	Array of EnumRef.IndicatorsOfAnalyticalRegisters
//
Function DefaultAmountIndicatorsByDataSource(DataSource) Export
	
	If TypeOf(DataSource) <> Type("CatalogRef.BusinessTransactionsSettings") Then
		Return Undefined;
	EndIf;
	
	TypesOfSourceAccountingData = Common.ObjectAttributesValues(DataSource, "Receipt, Expense");
	AccountingDataTypes = New Array;
	AccountingDataTypes.Add(TypesOfSourceAccountingData.Receipt);
	AccountingDataTypes.Add(TypesOfSourceAccountingData.Expense);
	
	Indicators = New Array;
	
	If AccountingDataTypes.Find(Enums.AccountingDataTypes.Counterparties) <> Undefined
		And AccountingDataTypes.Find(Enums.AccountingDataTypes.Cash) <> Undefined Then
		
		Indicators.Add(Enums.IndicatorsOfAnalyticalRegisters.PostpaymentAmount);
		Indicators.Add(Enums.IndicatorsOfAnalyticalRegisters.PrepaymentAmountMan)
		
	Else
		
		Indicators.Add(Enums.IndicatorsOfAnalyticalRegisters.Sum);
		
	EndIf;
	
	Return Indicators;
	
EndFunction

// Returns the correspondence of quantitative indicators for a business of operation, depending on the types of accounting data Receipt and expense
//
// Parameters:
//  DataSource - CatalogRef.BusinessTransactionsSettings
//
// Returns:
//	Map of KeyAndValue:
//	* Key - EnumRef.IndicatorsOfAnalyticalRegisters
//	* Value - String - the name of the field associated with the indicator.
//
Function QuantityIndicatorsByDataSource(DataSource) Export
	
	If TypeOf(DataSource) <> Type("CatalogRef.BusinessTransactionsSettings") Then
		Return Undefined;
	EndIf;
	
	TypesOfSourceAccountingData = Common.ObjectAttributesValues(DataSource, "Receipt, Expense");
	AccountingDataTypes = New Array;
	AccountingDataTypes.Add(TypesOfSourceAccountingData.Receipt);
	AccountingDataTypes.Add(TypesOfSourceAccountingData.Expense);
	
	Indicators = New Map;
	
	If AccountingDataTypes.Find(Enums.AccountingDataTypes.Products) <> Undefined Then
		
		Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.Count, "Count");
		If TypesOfSourceAccountingData.Receipt = TypesOfSourceAccountingData.Expense Then
			Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.CorQuantity, "CorQuantity");
		EndIf;
		
	EndIf;
	
	Return Indicators;
	
EndFunction

// Returns the correspondence of the indicators of analytical registers to the quantitative resources of the data source
// of the transferred item of assets and liabilities for calculating the actual data of items and budget indicators.
//
// Parameters:
//  DataSource - ChartOfCharacteristicTypesRef.AssetLiabilityItems
//
// Returns:
//  Map of KeyAndValue:
//  * Key - EnumRef.IndicatorsOfAnalyticalRegisters
//  * Value - Array of String - the name of the resource associated with the indicator
//
Function IndicatorsOfNumberOfItemsOfAssetsLiabilities(DataSource) Export
	
	If TypeOf(DataSource) <> Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems") Then
		Return Undefined;
	EndIf;
	
	QuantityIndicators = New Map();
	
	AssetLiabilityItemManager = ChartsOfCharacteristicTypes.AssetLiabilityItems;
	SourceMetrics = AssetLiabilityItemManager.IndicatorsOfArticleOfAssetsLiabilities(DataSource);
	
	For Each KeyAndValue In SourceMetrics Do
		Factor = KeyAndValue.Key;
		DescriptionIndicator = KeyAndValue.Value;
		ArrayOfResources = New Array();
		
		For Each KeyAndValue In DescriptionIndicator Do
			ResourceGroup = KeyAndValue.Key;
			ResourceTable = KeyAndValue.Value;
			
			If ResourceGroup = AssetLiabilityItemManager.QuantitativeAccountingResourcesGroup() Then
				ResourceName = "Count";
			Else
				Continue;
			EndIf;
			
			If ResourceTable.Count() > 0 Then
				ArrayOfResources.Add(ResourceName);
			EndIf;
		EndDo;
		
		QuantityIndicators.Insert(Factor, ArrayOfResources);
	EndDo;
	
	Return QuantityIndicators;
	
EndFunction

// Returns an array of summary indicators related to controlling the cash expense limit.
//
// Returns:
//  Array of EnumRef.IndicatorsOfAnalyticalRegisters
//
Function RegisteredRecordsOfCashDisbursements() Export
	
	Indicators = New Map;
	
	PropertiesOfIndicators = "Resources";
	ResourceProperties = "Name, SourceOfCurrency";
	
	ArrayOfResources = New Array;
	ArrayOfResources.Add(New Structure(ResourceProperties, "AmountToBePaidWithinLimit", "PaymentCurrency"));
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.AmountToBePaidWithinLimit,
		New Structure(PropertiesOfIndicators, ArrayOfResources));
	
	ArrayOfResources = New Array;
	ArrayOfResources.Add(New Structure(ResourceProperties, "AmountToBePaidAboveLimit", "PaymentCurrency"));
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.AmountToBePaidAboveLimit,
		New Structure(PropertiesOfIndicators, ArrayOfResources));
	
	ArrayOfResources = New Array;
	ArrayOfResources.Add(New Structure(ResourceProperties, "AmountToBePaid", "PaymentCurrency"));
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.AmountToBePaid,
		New Structure(PropertiesOfIndicators, ArrayOfResources));
	
	Return Indicators;
	
EndFunction

// Returns the structure of analytics for the specified accounting data type
//
// Parameters:
//	TypeOfAccountingData - EnumRef.AccountingDataTypes - Type of Accounting Data
//
// Returns:
//	Structure:
//	* Department - Structure - Parameters of the Analytics Field:
//	  ** DataPath - String - the path to the analytics field.
//	  ** Type - TypeDescription - Type of the Analytics value.
//	  ** Title - String - Presentation of the analytics field.
//	  ** NameBalanced - String - the name of the field as the analytics box
//	  ** TitleBalanced - String - Presentation of the cor. analytics field
//
Function AnalyticsStructureByTypeOfAccountingData(TypeOfAccountingData) Export
	
	TemplateForAnalyticsFieldParameters = New Structure;
	TemplateForAnalyticsFieldParameters.Insert("DataPath");
	TemplateForAnalyticsFieldParameters.Insert("Type");
	TemplateForAnalyticsFieldParameters.Insert("Title");
	TemplateForAnalyticsFieldParameters.Insert("NameBalanced");
	TemplateForAnalyticsFieldParameters.Insert("TitleBalanced");
	
	StructureOfAnalytics = New Structure;
	
	// Department
	ParametersOfAnalyticsField = Common.CopyRecursive(TemplateForAnalyticsFieldParameters);
	ParametersOfAnalyticsField.DataPath = "Department";
	ParametersOfAnalyticsField.Type = New TypeDescription("CatalogRef.BusinessStructure");
	ParametersOfAnalyticsField.Title = NStr("vi = 'Bộ phận';
											|ru = 'Подразделение';
											|en = 'Business unit'; fa = 'Business unit';
											|it = 'Подразделение';
											|pl = 'Dział';
											|tr = 'Departman'");
	ParametersOfAnalyticsField.NameBalanced = "DebitBusinessUnit";
	ParametersOfAnalyticsField.TitleBalanced = NStr("vi = 'Đối ứng bộ phận';
													|ru = 'Кор. подразделение';
													|en = 'Cor. business unit'; fa = 'واحد تجاری مقابل';
													|it = 'Reparto corrispondente';
													|pl = 'Kor. dział';
													|tr = 'İlgili departman'");
	StructureOfAnalytics.Insert("Department", ParametersOfAnalyticsField);
	
	// LineOfBusiness
	ParametersOfAnalyticsField = Common.CopyRecursive(TemplateForAnalyticsFieldParameters);
	ParametersOfAnalyticsField.DataPath = "LineOfBusiness";
	ParametersOfAnalyticsField.Type = New TypeDescription("CatalogRef.LinesOfBusiness");
	ParametersOfAnalyticsField.Title = NStr("vi = 'Lĩnh vực hoạt động';
											|ru = 'Направление деятельности';
											|en = 'Line of business'; fa = 'خط کسب‌وکار';
											|it = 'Settore di attività';
											|pl = 'Rodzaj działalności';
											|tr = 'Faaliyet alanı'");
	ParametersOfAnalyticsField.NameBalanced = "CorLineOfBusiness";
	ParametersOfAnalyticsField.TitleBalanced = NStr("vi = 'Đối ứng lĩnh vực hoạt động';
													|ru = 'Кор. направление деятельности';
													|en = 'Cor. line of business'; fa = 'خط کسب‌وکار مقابل';
													|it = 'Settore di attività corrispondente';
													|pl = 'Kor.kierunek działalności';
													|tr = 'İlgili iş kolu'");
	StructureOfAnalytics.Insert("LineOfBusiness", ParametersOfAnalyticsField);
	
	// Products
	If TypeOfAccountingData = Enums.AccountingDataTypes.Products Then
		
		ParametersOfAnalyticsField = Common.CopyRecursive(TemplateForAnalyticsFieldParameters);
		ParametersOfAnalyticsField.DataPath = "ItemsLocationAttributes.Products";
		ParametersOfAnalyticsField.Type = New TypeDescription("CatalogRef.Products");
		ParametersOfAnalyticsField.Title = NStr("vi = 'Mặt hàng';
												|ru = 'Номенклатура';
												|en = 'Items'; fa = 'اقلام';
												|it = 'Номенклатура';
												|pl = 'Items';
												|tr = 'Ürün'");
		ParametersOfAnalyticsField.NameBalanced = "CorNomenclature";
		ParametersOfAnalyticsField.TitleBalanced = NStr("vi = 'Đối ứng mặt hàng';
														|ru = 'Кор. номенклатура';
														|en = 'Cor. products'; fa = 'Cor. products';
														|it = 'Кор. номенклатура';
														|pl = 'Cor. products';
														|tr = 'İlgili öğe'");
		StructureOfAnalytics.Insert("Products", ParametersOfAnalyticsField);
		
		ParametersOfAnalyticsField = Common.CopyRecursive(TemplateForAnalyticsFieldParameters);
		ParametersOfAnalyticsField.DataPath = "ItemsLocationAttributes.StorageLocation";
		ParametersOfAnalyticsField.Type = New TypeDescription("CatalogRef.BusinessStructure,CatalogRef.Partners,CatalogRef.Warehouses");
		ParametersOfAnalyticsField.Title = NStr("vi = 'Kho bãi';
												|ru = 'Склад';
												|en = 'Warehouse'; fa = 'Warehouse';
												|it = 'Склад';
												|pl = 'Warehouse';
												|tr = 'Ambar'");
		ParametersOfAnalyticsField.NameBalanced = "CorWarehouseCorCommissionAgentCorBusinessUnit";
		ParametersOfAnalyticsField.TitleBalanced = NStr("vi = 'Kho đối ứng';
														|ru = 'Кор. склад';
														|en = 'Cor. warehouse'; fa = 'Cor. warehouse';
														|it = 'Кор. склад';
														|pl = 'Cor. warehouse';
														|tr = 'Muhabir ambar'");
		StructureOfAnalytics.Insert("Warehouse", ParametersOfAnalyticsField);
		
		ParametersOfAnalyticsField = Common.CopyRecursive(TemplateForAnalyticsFieldParameters);
		ParametersOfAnalyticsField.DataPath = "InventoryOwnerAttribute";
		ParametersOfAnalyticsField.Type = New TypeDescription("CatalogRef.InventoryKinds");
		ParametersOfAnalyticsField.Title = NStr("vi = 'Dạng vật tư';
												|ru = 'Вид запасов';
												|en = 'Inventory owner attributes'; fa = 'ویژگی‌های مالک موجودی';
												|it = 'Tipologia di scorte';
												|pl = 'Rodzaj pozycji';
												|tr = 'Stok sahibinin öznitelikleri'");
		ParametersOfAnalyticsField.NameBalanced = "CorInventoryOwnerAttribute";
		ParametersOfAnalyticsField.TitleBalanced = NStr("vi = 'Đối ứng dạng hàng tồn kho';
														|ru = 'Кор. вид запасов';
														|en = 'Cor. inventory owner attributes'; fa = 'ویژگی‌های مالک موجودی مقابل';
														|it = 'Tipo di scorte di contropartita';
														|pl = 'Kor. rodzaj pozycji';
														|tr = 'Düzeltme stok sahibinin öznitelikleri'");
		StructureOfAnalytics.Insert("InventoryOwnerAttribute", ParametersOfAnalyticsField);
		
	// Counterparties
	ElsIf TypeOfAccountingData = Enums.AccountingDataTypes.Counterparties Then
		
		ParametersOfAnalyticsField = Common.CopyRecursive(TemplateForAnalyticsFieldParameters);
		ParametersOfAnalyticsField.DataPath = "AccountingDimensionByPartners.Partner";
		ParametersOfAnalyticsField.Type = New TypeDescription("CatalogRef.Partners");
		ParametersOfAnalyticsField.Title = NStr("vi = 'Bạn hàng';
												|ru = 'Партнер';
												|en = 'Partner'; fa = 'شریک تجاری';
												|it = 'Партнер';
												|pl = 'Partner';
												|tr = 'İş ortağı'");
		ParametersOfAnalyticsField.NameBalanced = "CorPartner";
		ParametersOfAnalyticsField.TitleBalanced = NStr("vi = 'Đối tác trung gian';
														|ru = 'Кор. партнер';
														|en = 'Cor. partner'; fa = 'شریک مقابل';
														|it = 'Partner corrispondente';
														|pl = 'Kor. partner';
														|tr = 'Muhabir iş ortağı'");
		StructureOfAnalytics.Insert("Partner", ParametersOfAnalyticsField);
		
		ParametersOfAnalyticsField = Common.CopyRecursive(TemplateForAnalyticsFieldParameters);
		ParametersOfAnalyticsField.DataPath = "AccountingDimensionByPartners.Counterparty";
		ParametersOfAnalyticsField.Type = New TypeDescription("CatalogRef.Counterparties,CatalogRef.Companies");
		ParametersOfAnalyticsField.Title = NStr("vi = 'Đối tác';
												|ru = 'Контрагент';
												|en = 'Counterparty'; fa = 'طرف حساب';
												|it = 'Контрагент';
												|pl = 'Counterparty';
												|tr = 'Cari hesap'");
		ParametersOfAnalyticsField.NameBalanced = "CorCounterparty";
		ParametersOfAnalyticsField.TitleBalanced = NStr("vi = 'Đối tác trung gian';
														|ru = 'Кор. контрагент';
														|en = 'Cor counterparty'; fa = 'طرف حساب مقابل';
														|it = 'Contraente corrispondente';
														|pl = 'Kor. kontrahent';
														|tr = 'İlgili cari hesap'");
		StructureOfAnalytics.Insert("Counterparty", ParametersOfAnalyticsField);
		
		ParametersOfAnalyticsField = Common.CopyRecursive(TemplateForAnalyticsFieldParameters);
		ParametersOfAnalyticsField.DataPath = "ARAPObject.Contract";
		ParametersOfAnalyticsField.Type = New TypeDescription("CatalogRef.LeaseContract,CatalogRef.IntercompanyContracts,CatalogRef.CounterpartyContracts,CatalogRef.LoanAndDepositContracts");
		ParametersOfAnalyticsField.Title = NStr("vi = 'Hợp đồng';
												|ru = 'Договор';
												|en = 'Contract'; fa = 'قرارداد';
												|it = 'Договор';
												|pl = 'Contract';
												|tr = 'Sözleşme'");
		ParametersOfAnalyticsField.NameBalanced = "CorContract";
		ParametersOfAnalyticsField.TitleBalanced = NStr("vi = 'Hợp đồng được điều chỉnh';
														|ru = 'Кор. договор';
														|en = 'Cor. contract'; fa = 'قرارداد مقابل';
														|it = 'Contratto corrispondente';
														|pl = 'Kor. umowa';
														|tr = 'İlgili sözleşme'");
		StructureOfAnalytics.Insert("Contract", ParametersOfAnalyticsField);
		
		ParametersOfAnalyticsField = Common.CopyRecursive(TemplateForAnalyticsFieldParameters);
		ParametersOfAnalyticsField.DataPath = "ARAPObject";
		ParametersOfAnalyticsField.Type = New TypeDescription("CatalogRef.ARAPObjects,CatalogRef.GiftCertificates");
		ParametersOfAnalyticsField.Title = NStr("vi = 'Đối tượng hạch toán';
												|ru = 'Объект расчетов';
												|en = 'AR/AP object'; fa = 'موضوع دریافتنی/پرداختنی';
												|it = 'Oggetto di regolamenti';
												|pl = 'Obiekt rozliczeń';
												|tr = 'Alacak/Borç nesnesi'");
		ParametersOfAnalyticsField.NameBalanced = "CorARAPObject";
		ParametersOfAnalyticsField.TitleBalanced = NStr("vi = 'Đối tượng hạch toán trung gian';
														|ru = 'Кор. объект расчетов';
														|en = 'Cor. AR/AP object'; fa = 'موضوع دریافتنی/پرداختنی مقابل';
														|it = 'Oggetto cor. di regolamenti';
														|pl = 'Kor. obiekt rozliczeń';
														|tr = 'İlgili Alacak/Borç nesnesi'");
		StructureOfAnalytics.Insert("ARAPObject", ParametersOfAnalyticsField);
		
		ParametersOfAnalyticsField = Common.CopyRecursive(TemplateForAnalyticsFieldParameters);
		ParametersOfAnalyticsField.DataPath = "ARAPDocument";
		ParametersOfAnalyticsField.Type = Metadata.DefinedTypes.ARAPDocument.Type;
		ParametersOfAnalyticsField.Title = NStr("vi = 'Chứng từ hạch toán';
												|ru = 'Расчетный документ';
												|en = 'AR/AP document'; fa = 'سند دریافتنی/پرداختنی';
												|it = 'Documento di regolamento';
												|pl = 'Dokument rozliczeniowy';
												|tr = 'Alacak/Borç belgesi'");
		ParametersOfAnalyticsField.NameBalanced = "CorSettlementDocument";
		ParametersOfAnalyticsField.TitleBalanced = NStr("vi = 'Chứng từ thanh toán đối ứng';
														|ru = 'Кор. расчетный документ';
														|en = 'Cor. AR/AP document'; fa = 'Cor. AR/AP document';
														|it = 'Кор. расчетный документ';
														|pl = 'Cor. AR/AP document';
														|tr = 'Muhabir alacak/borç belgesi'");
		StructureOfAnalytics.Insert("ARAPDocument", ParametersOfAnalyticsField);
	
	// Cash
	ElsIf TypeOfAccountingData = Enums.AccountingDataTypes.Cash Then
		
		ParametersOfAnalyticsField = Common.CopyRecursive(TemplateForAnalyticsFieldParameters);
		ParametersOfAnalyticsField.DataPath = "";
		ParametersOfAnalyticsField.Type = New TypeDescription("CatalogRef.CompaniesBankAccounts,CatalogRef.CashAccounts,CatalogRef.CashRegisters,CatalogRef.Counterparties,CatalogRef.Persons,CatalogRef.LoanAndDepositContracts,CatalogRef.POSTerminals");
		ParametersOfAnalyticsField.Title = NStr("vi = 'Tiền mặt, tiền gửi';
												|ru = 'Денежные средства';
												|en = 'Cash'; fa = 'صندوق';
												|it = 'Fondi monetari';
												|pl = 'Środki pieniężne';
												|tr = 'Nakit'");
		ParametersOfAnalyticsField.NameBalanced = "CorCash";
		ParametersOfAnalyticsField.TitleBalanced = NStr("vi = 'Vốn bằng tiền đối ứng';
														|ru = 'Кор. денежные средства';
														|en = 'Cor. cash'; fa = 'وجه نقد مقابل';
														|it = 'Fondi monetari corrispondenti';
														|pl = 'Kor. środki pieniężne';
														|tr = 'Nakit muhabir hesabı'");
		StructureOfAnalytics.Insert("Cash", ParametersOfAnalyticsField);
		
		ParametersOfAnalyticsField = Common.CopyRecursive(TemplateForAnalyticsFieldParameters);
		ParametersOfAnalyticsField.DataPath = "";
		ParametersOfAnalyticsField.Type = New TypeDescription("EnumRef.CashTypes");
		ParametersOfAnalyticsField.Title = NStr("vi = 'Kiểu vốn bằng tiền';
												|ru = 'Тип денежных средств';
												|en = 'Cash type'; fa = 'نوع وجه نقد';
												|it = 'Tipo di fondi monetari';
												|pl = 'Typ środków pieniężnych';
												|tr = 'Nakit tipi'");
		ParametersOfAnalyticsField.NameBalanced = "CorCashType";
		ParametersOfAnalyticsField.TitleBalanced = NStr("vi = 'Kiểu vốn bằng tiền đối ứng';
														|ru = 'Кор. тип денежных средств';
														|en = 'Cor. cash type'; fa = 'نوع وجه نقد مقابل';
														|it = 'Tipo corrispondente dei fondi monetari';
														|pl = 'Kor. typ środków pieniężnych';
														|tr = 'Nakit muhabir hesabı tipi'");
		StructureOfAnalytics.Insert("CashType", ParametersOfAnalyticsField);
		
		ParametersOfAnalyticsField = Common.CopyRecursive(TemplateForAnalyticsFieldParameters);
		ParametersOfAnalyticsField.DataPath = "CashFlowItem";
		ParametersOfAnalyticsField.Type = New TypeDescription("CatalogRef.CashFlowReportItems");
		ParametersOfAnalyticsField.Title = NStr("vi = 'Dạng lưu chuyển tiền tệ';
												|ru = 'Статья движения денежных средств';
												|en = 'Cash flow item'; fa = 'قلم جریان وجوه نقد';
												|it = 'Voce flussi di denaro';
												|pl = 'Kierunek ruchu środków pieniężnych';
												|tr = 'Nakit akışı öğesi'");
		ParametersOfAnalyticsField.NameBalanced = "CorCashFlowItem";
		ParametersOfAnalyticsField.TitleBalanced = NStr("vi = 'Dạng lưu chuyển tiền tệ đối ứng';
														|ru = 'Кор. статья движения денежных средств';
														|en = 'Cor. cash flow item'; fa = 'قلم جریان وجوه نقد مقابل';
														|it = 'Кор. статья движения денежных средств';
														|pl = 'Cor. cash flow item';
														|tr = 'Muhabir nakit akışı öğesi'");
		StructureOfAnalytics.Insert("CashFlowItem", ParametersOfAnalyticsField);
		
		ParametersOfAnalyticsField = Common.CopyRecursive(TemplateForAnalyticsFieldParameters);
		ParametersOfAnalyticsField.DataPath = "ProductCostElement";
		ParametersOfAnalyticsField.Type = New TypeDescription("CatalogRef.ProductCostElements");
		ParametersOfAnalyticsField.Title = NStr("vi = 'Dạng tính giá thành';
												|ru = 'Статья калькуляции';
												|en = 'Product cost element'; fa = 'عنصر بهای تمام‌شده محصول';
												|it = 'Voce di calcolo';
												|pl = 'Rodzaj kosztu';
												|tr = 'Ürün maliyet kalemi'");
		ParametersOfAnalyticsField.NameBalanced = "CorCostElement";
		ParametersOfAnalyticsField.TitleBalanced = NStr("vi = 'Đối ứng dạng tính giá thành';
														|ru = 'Кор. статья калькуляции';
														|en = 'Cor. product cost element'; fa = 'عنصر بهای تمام‌شده محصول مقابل';
														|it = 'Voce di calcolo di contropartita';
														|pl = 'Kor. pozycja kalkulacji';
														|tr = 'Karşıt ürün maliyet kalemi'");
		StructureOfAnalytics.Insert("ProductCostElement", ParametersOfAnalyticsField);
		
		ParametersOfAnalyticsField = Common.CopyRecursive(TemplateForAnalyticsFieldParameters);
		ParametersOfAnalyticsField.DataPath = "";
		ParametersOfAnalyticsField.Type = New TypeDescription("CatalogRef.BusinessStructure");
		ParametersOfAnalyticsField.Title = NStr("vi = 'Bộ phận thanh toán';
												|ru = 'Подразделение платежа';
												|en = 'Payment business unit'; fa = 'Payment business unit';
												|it = 'Payment business unit';
												|pl = 'Payment business unit';
												|tr = 'Ödeme departmanı'");
		ParametersOfAnalyticsField.NameBalanced = "CorDivisionOfPayment";
		ParametersOfAnalyticsField.TitleBalanced = NStr("vi = 'Bộ phận thanh toán đối ứng';
														|ru = 'Кор. подразделение платежа';
														|en = 'Cor. payment business unit'; fa = 'Cor. payment business unit';
														|it = 'Cor. payment business unit';
														|pl = 'Cor. payment business unit';
														|tr = 'İlgili ödeme departmanı'");
		StructureOfAnalytics.Insert("PaymentDivision", ParametersOfAnalyticsField);
	
	// IncomeExpenses
	ElsIf TypeOfAccountingData = Enums.AccountingDataTypes.IncomeExpenses Then
		
		ParametersOfAnalyticsField = Common.CopyRecursive(TemplateForAnalyticsFieldParameters);
		ParametersOfAnalyticsField.DataPath = "IncomeAndExpenseItem";
		ParametersOfAnalyticsField.Type = New TypeDescription("ChartOfCharacteristicTypesRef.ExpenseItems,ChartOfCharacteristicTypesRef.IncomeItems");
		ParametersOfAnalyticsField.Title = NStr("vi = 'Dạng thu nhập/chi phí';
												|ru = 'Статья доходов/расходов';
												|en = 'Item of income/expense'; fa = 'قلم درآمد/هزینه';
												|it = 'Voce di entrate/uscite';
												|pl = 'Rodzaj przychodów/wydatków';
												|tr = 'Gelir/gider kalemi'");
		ParametersOfAnalyticsField.NameBalanced = "CorIncomeExpenseItem";
		ParametersOfAnalyticsField.TitleBalanced = NStr("vi = 'Dạng thu nhập/chi phí đối ứng';
														|ru = 'Кор. статья доходов/расходов';
														|en = 'Cor. income/expense item'; fa = 'Cor. income/expense item';
														|it = 'Кор. статья доходов/расходов';
														|pl = 'Cor. income/expense item';
														|tr = 'Muhabir gelir/gider kalemi'");
		StructureOfAnalytics.Insert("IncomeAndExpenseItem", ParametersOfAnalyticsField);
		
		ParametersOfAnalyticsField = Common.CopyRecursive(TemplateForAnalyticsFieldParameters);
		ParametersOfAnalyticsField.DataPath = "DimensionOfRevenue";
		ParametersOfAnalyticsField.Type = Metadata.ChartsOfCharacteristicTypes.IncomeItems.Type;
		ParametersOfAnalyticsField.Title = NStr("vi = 'Đối tượng phân tích thu nhập';
												|ru = 'Аналитика доходов';
												|en = 'Income dimension'; fa = 'بُعد درآمد';
												|it = 'Analitica dei ricavi';
												|pl = 'Analityka dochodów';
												|tr = 'Gelir boyutu'");
		ParametersOfAnalyticsField.NameBalanced = "CorIncomeDimension";
		ParametersOfAnalyticsField.TitleBalanced = NStr("vi = 'Đối ứng chỉ số doanh thu';
														|ru = 'Кор. аналитика доходов';
														|en = 'Cor. income dimension'; fa = 'بُعد درآمد مقابل';
														|it = 'Analitica correttiva delle entrate';
														|pl = 'Kor. analityka przychodów';
														|tr = 'İlgili gelir boyutu'");
		StructureOfAnalytics.Insert("DimensionOfRevenue", ParametersOfAnalyticsField);
		
		ParametersOfAnalyticsField = Common.CopyRecursive(TemplateForAnalyticsFieldParameters);
		ParametersOfAnalyticsField.DataPath = "DimensionOfExpenses";
		ParametersOfAnalyticsField.Type = Metadata.ChartsOfCharacteristicTypes.ExpenseItems.Type;
		ParametersOfAnalyticsField.Title = NStr("vi = 'Đối tượng phân tích chi phí';
												|ru = 'Аналитика расходов';
												|en = 'Expense dimension'; fa = 'بُعد هزینه';
												|it = 'Analitica delle uscite';
												|pl = 'Analityka kosztów';
												|tr = 'Gider boyutu'");
		ParametersOfAnalyticsField.NameBalanced = "CorExpenditureDimension";
		ParametersOfAnalyticsField.TitleBalanced = NStr("vi = 'Đối ứng chỉ số chi phí';
														|ru = 'Кор. аналитика расходов';
														|en = 'Corr. expense dimension'; fa = 'بُعد هزینه مقابل';
														|it = 'Analitica di uscite di contropartita';
														|pl = 'Kor. analiza kosztów';
														|tr = 'İlgili gider boyutu'");
		StructureOfAnalytics.Insert("DimensionOfExpenses", ParametersOfAnalyticsField);
	
	// OtherAssetsLiabilities
	ElsIf TypeOfAccountingData = Enums.AccountingDataTypes.OtherAssetsLiabilities Then
		
		ParametersOfAnalyticsField = Common.CopyRecursive(TemplateForAnalyticsFieldParameters);
		ParametersOfAnalyticsField.DataPath = "AssetRef";
		ParametersOfAnalyticsField.Type = New TypeDescription("ChartOfCharacteristicTypesRef.AssetLiabilityItems");
		ParametersOfAnalyticsField.Title = NStr("vi = 'Dạng';
												|ru = 'Статья';
												|en = 'Item'; fa = 'قلم';
												|it = 'Статья';
												|pl = 'Item';
												|tr = 'Kalem'");
		ParametersOfAnalyticsField.NameBalanced = "CorArticleOfAssetsLiabilities";
		ParametersOfAnalyticsField.TitleBalanced = NStr("vi = 'Đối ứng dạng';
														|ru = 'Кор. статья';
														|en = 'Cor. item'; fa = 'قلم مقابل';
														|it = 'Voce corr.';
														|pl = 'Kor. artykuł';
														|tr = 'Muhabir kalem'");
		StructureOfAnalytics.Insert("AssetAndLiabilityItem", ParametersOfAnalyticsField);
		
		ParametersOfAnalyticsField = Common.CopyRecursive(TemplateForAnalyticsFieldParameters);
		ParametersOfAnalyticsField.DataPath = "AssetsLiabilitiesDimension";
		ParametersOfAnalyticsField.Type = Metadata.ChartsOfCharacteristicTypes.AssetLiabilityItems.Type;
		ParametersOfAnalyticsField.Title = NStr("vi = 'Chỉ số tài sản/nguồn vốn';
												|ru = 'Аналитика активов/пассивов';
												|en = 'Dimension of assets/liabilities'; fa = 'بُعد دارایی‌ها/بدهی‌ها';
												|it = 'Analitica di attivi/passivi';
												|pl = 'Analityka aktywów/pasywów';
												|tr = 'Varlık/yükümlülük boyutu'");
		ParametersOfAnalyticsField.NameBalanced = "CorDimensionOfAssetsLiabilities";
		ParametersOfAnalyticsField.TitleBalanced = NStr("vi = 'Đối ứng chỉ số tài sản/nguồn vốn';
														|ru = 'Кор. аналитика активов/пассивов';
														|en = 'Cor. dimension of assets/liabilities'; fa = 'بُعد دارایی‌ها/بدهی‌های مقابل';
														|it = 'Rettifica dell''analitica degli attivi/passivi';
														|pl = 'Kor. analiza aktywów/pasywów';
														|tr = 'İlgili varlık/yükümlülük boyutu'");
		StructureOfAnalytics.Insert("AssetsLiabilitiesDimension", ParametersOfAnalyticsField);
		
		ParametersOfAnalyticsField = Common.CopyRecursive(TemplateForAnalyticsFieldParameters);
		ParametersOfAnalyticsField.DataPath = "FinancialAccountingGroup";
		ParametersOfAnalyticsField.Type = New TypeDescription("CatalogRef.NonCurrentAssetsAccountingGroups");
		ParametersOfAnalyticsField.Title = NStr("vi = 'Nhóm kế toán tài chính';
												|ru = 'Группа финансового учета';
												|en = 'Financial accounting group'; fa = 'گروه حسابداری مالی';
												|it = 'Gruppo di contabilità finanziaria';
												|pl = 'Grupa ewidencji finansowej';
												|tr = 'Finansal muhasebe grubu'");
		ParametersOfAnalyticsField.NameBalanced = "CorFinancialAccountingGroup";
		ParametersOfAnalyticsField.TitleBalanced = NStr("vi = 'Đối ứng nhóm kế toán tài chính';
														|ru = 'Кор. группа финансового учета';
														|en = 'Cor. financial accounting group'; fa = 'گروه حسابداری مالی مقابل';
														|it = 'Gruppo corrispondente di contabilità finanziaria';
														|pl = 'Kor. grupa rachunkowości finansowej';
														|tr = 'Muhabir finansal muhasebe grubu'");
		StructureOfAnalytics.Insert("FinancialAccountingGroup", ParametersOfAnalyticsField);
		
		ParametersOfAnalyticsField = Common.CopyRecursive(TemplateForAnalyticsFieldParameters);
		ParametersOfAnalyticsField.DataPath = "Counterparty";
		ParametersOfAnalyticsField.Type = New TypeDescription("CatalogRef.Counterparties");
		ParametersOfAnalyticsField.Title = NStr("vi = 'Đối tác';
												|ru = 'Контрагент';
												|en = 'Counterparty'; fa = 'طرف حساب';
												|it = 'Контрагент';
												|pl = 'Counterparty';
												|tr = 'Cari hesap'");
		ParametersOfAnalyticsField.NameBalanced = "CorCounterparty";
		ParametersOfAnalyticsField.TitleBalanced = NStr("vi = 'Đối tác trung gian';
														|ru = 'Кор. контрагент';
														|en = 'Cor counterparty'; fa = 'طرف حساب مقابل';
														|it = 'Contraente corrispondente';
														|pl = 'Kor. kontrahent';
														|tr = 'İlgili cari hesap'");
		StructureOfAnalytics.Insert("Counterparty", ParametersOfAnalyticsField);
	
	// VAT
	ElsIf TypeOfAccountingData = Enums.AccountingDataTypes.VAT Then
		
		ParametersOfAnalyticsField = Common.CopyRecursive(TemplateForAnalyticsFieldParameters);
		ParametersOfAnalyticsField.DataPath = "Counterparty";
		ParametersOfAnalyticsField.Type = New TypeDescription("CatalogRef.Counterparties");
		ParametersOfAnalyticsField.Title = NStr("vi = 'Đối tác';
												|ru = 'Контрагент';
												|en = 'Counterparty'; fa = 'طرف حساب';
												|it = 'Контрагент';
												|pl = 'Counterparty';
												|tr = 'Cari hesap'");
		ParametersOfAnalyticsField.NameBalanced = "CorCounterparty";
		ParametersOfAnalyticsField.TitleBalanced = NStr("vi = 'Đối tác trung gian';
														|ru = 'Кор. контрагент';
														|en = 'Cor counterparty'; fa = 'طرف حساب مقابل';
														|it = 'Contraente corrispondente';
														|pl = 'Kor. kontrahent';
														|tr = 'İlgili cari hesap'");
		StructureOfAnalytics.Insert("Counterparty", ParametersOfAnalyticsField);
		
		ParametersOfAnalyticsField = Common.CopyRecursive(TemplateForAnalyticsFieldParameters);
		ParametersOfAnalyticsField.DataPath = "TaxInvoice";
		ParametersOfAnalyticsField.Type = Metadata.DefinedTypes.BasisForVATRecords.Type;
		ParametersOfAnalyticsField.Title = NStr("vi = 'Hóa đơn GTGT';
												|ru = 'Счет-фактура';
												|en = 'Tax invoice'; fa = 'فاکتور مالیاتی';
												|it = 'Счет-фактура';
												|pl = 'Tax invoice';
												|tr = 'Vergi faturası'");
		ParametersOfAnalyticsField.NameBalanced = "CorInvoice";
		ParametersOfAnalyticsField.TitleBalanced = NStr("vi = 'Hóa đơn GTGT đối ứng';
														|ru = 'Кор. счет=фактура';
														|en = 'Cor. tax invoice'; fa = 'Cor. tax invoice';
														|it = 'Кор. счет=фактура';
														|pl = 'Cor. tax invoice';
														|tr = 'Muhabir vergi faturası'");
		StructureOfAnalytics.Insert("TaxInvoice", ParametersOfAnalyticsField);
		
		ParametersOfAnalyticsField = Common.CopyRecursive(TemplateForAnalyticsFieldParameters);
		ParametersOfAnalyticsField.DataPath = "VATRate";
		ParametersOfAnalyticsField.Type = New TypeDescription("CatalogRef.VATRates");
		ParametersOfAnalyticsField.Title = NStr("vi = 'Thuế suất GTGT';
												|ru = 'Ставка НДС';
												|en = 'VAT rate'; fa = 'نرخ مالیات بر ارزش افزوده';
												|it = 'Aliquota IVA';
												|pl = 'Stawka VAT';
												|tr = 'KDV oranı'");
		ParametersOfAnalyticsField.NameBalanced = "CorVATRate";
		ParametersOfAnalyticsField.TitleBalanced = NStr("vi = 'Thuế suất Thuế GTGT đối ứng';
														|ru = 'Кор. ставка НДС';
														|en = 'Cor. VAT rate'; fa = 'نرخ مالیات بر ارزش افزوده مقابل';
														|it = 'Aliquota IVA corrispondente';
														|pl = 'Kor. stawka VAT';
														|tr = 'Muhabir KDV oranı'");
		StructureOfAnalytics.Insert("VATRate", ParametersOfAnalyticsField);
		
		ParametersOfAnalyticsField = Common.CopyRecursive(TemplateForAnalyticsFieldParameters);
		ParametersOfAnalyticsField.DataPath = "AssetTaxClass";
		ParametersOfAnalyticsField.Type = New TypeDescription("EnumRef.AssetKinds");
		ParametersOfAnalyticsField.Title = NStr("vi = 'Dạng giá trị';
												|ru = 'Вид ценности';
												|en = 'Asset tax class'; fa = 'طبقه مالیاتی دارایی';
												|it = 'Tipo dei beni';
												|pl = 'Rodzaj wartości';
												|tr = 'Varlık vergi sınıfı'");
		ParametersOfAnalyticsField.NameBalanced = "CorTypeOfValue";
		ParametersOfAnalyticsField.TitleBalanced = NStr("vi = 'Dạng giá trị đối ứng';
														|ru = 'Кор. вид ценности';
														|en = 'Cor. asset tax class'; fa = 'طبقه مالیاتی دارایی مقابل';
														|it = 'Tipo di valore di contropartita';
														|pl = 'Kor. rodzaj wartości';
														|tr = 'Muhabir varlık vergi sınıfı'");
		StructureOfAnalytics.Insert("AssetTaxClass", ParametersOfAnalyticsField);
	
	EndIf;
	
	DataSourcesLocalization.AddAnalyticsByAccountingDataType(TypeOfAccountingData, StructureOfAnalytics, TemplateForAnalyticsFieldParameters);
	
	Return StructureOfAnalytics;

EndFunction

// Returns the name of the budget item analytics field, depending on the type of accounting data.
//
// Parameters:
//  FieldName - String - the original name of the analytics field
//  FieldTitle - String - Presentation of the analytics field header
//  TypeOfAccountingData - EnumRef.AccountingDataTypes - the type of accounting data for which the name of the analytics field is defined.
//
// Returns:
//  String - modified analytics field depending on the type of accounting data.
//
Function FieldNameByAccountingDataType(FieldName, FieldTitle, TypeOfAccountingData) Export
	
	FieldParameters = New Structure("FieldName, FieldTitle", FieldName, FieldTitle);
	
	If FieldName = "LineOfBusiness" Then
		If TypeOfAccountingData = Enums.AccountingDataTypes.Cash Then
			FieldName = "LineOfBusinessCash";
			FieldTitle = NStr("vi = 'Giao dịch tiền mặt';
								|ru = 'Направление деятельности денежных средств';
								|en = 'Cash line of business'; fa = 'خط کسب‌وکار وجه نقد';
								|it = 'Settore di attività dei fondi monetari';
								|pl = 'Kierunek działania środków pieniężnych';
								|tr = 'Nakit iş kolu'")
		ElsIf TypeOfAccountingData = Enums.AccountingDataTypes.Counterparties
			Or TypeOfAccountingData = Enums.AccountingDataTypes.VAT Then
			FieldName = "CounterpartyLineOfBusiness";
			FieldTitle = NStr("vi = 'Lĩnh vực kinh doanh của đối tác';
								|ru = 'Направление деятельности контрагента';
								|en = 'Counterparty''s line of business'; fa = 'خط کسب‌وکار طرف حساب';
								|it = 'Settore di attività del contraente';
								|pl = 'Kierunek działalności kontrahenta';
								|tr = 'Cari hesabın iş kolu'")
		ElsIf TypeOfAccountingData = Enums.AccountingDataTypes.Products Then
			FieldName = "ProductLineOfBusiness";
			FieldTitle = NStr("vi = 'Lĩnh vực hoạt động mặt hàng';
								|ru = 'Направление деятельности номенклатуры';
								|en = 'Product line of business'; fa = 'خط کسب‌وکار محصول';
								|it = 'Settore di attività dell''elenco articoli';
								|pl = 'Kierunek działalności nomenklatury';
								|tr = 'Öğe iş kolu'")
		ElsIf TypeOfAccountingData = Enums.AccountingDataTypes.IncomeExpenses Then
			FieldName = "LineOfBusinessOfIncomeExpenses";
			FieldTitle = NStr("vi = 'Lĩnh vực hoạt động của thu nhập/chi phí';
								|ru = 'Направление деятельности доходов/расходов';
								|en = 'Line of business of income/expenses'; fa = 'Line of business of income/expenses';
								|it = 'Направление деятельности доходов/расходов';
								|pl = 'Line of business of income/expenses';
								|tr = 'Gelir/gider iş kolu'")
		Else
			FieldName = "LineOfBusinessOfAssetsLiabilities";
			FieldTitle = NStr("vi = 'Lĩnh vực hoạt động của tài sản/nguồn vốn';
								|ru = 'Направление деятельности активов/пассивов';
								|en = 'Line of business of assets/liabilities'; fa = 'Line of business of assets/liabilities';
								|it = 'Направление деятельности активов/пассивов';
								|pl = 'Line of business of assets/liabilities';
								|tr = 'Varlık/yükümlülük iş kolu'")
		EndIf;
		FieldParameters.FieldName = FieldName;
		FieldParameters.FieldTitle = FieldTitle;
	ElsIf FieldName = "Department" Then
		If TypeOfAccountingData = Enums.AccountingDataTypes.IncomeExpenses Then
			FieldName = "IncomeExpenseBusinessUnit";
			FieldTitle = NStr("vi = 'Đơn vị doanh thu/chi phí';
								|ru = 'Подразделение доходов/расходов';
								|en = 'Income/expense business unit'; fa = 'واحد تجاری درآمد/هزینه';
								|it = 'Reparto di ricavi/spese';
								|pl = 'Dział dochodów/wydatków';
								|tr = 'Departman gelirleri/giderleri'")
		ElsIf TypeOfAccountingData = Enums.AccountingDataTypes.OtherAssetsLiabilities Then
			FieldName = "DivisionOfAssetsLiabilities";
			FieldTitle = NStr("vi = 'Bộ phận tài sản/nguồn vốn';
								|ru = 'Подразделение активов/пассивов';
								|en = 'Business unit of assets/liabilities'; fa = 'Business unit of assets/liabilities';
								|it = 'Подразделение активов/пассивов';
								|pl = 'Business unit of assets/liabilities';
								|tr = 'Varlık/yükümlülük departmanı'")
		EndIf;
		FieldParameters.FieldName = FieldName;
		FieldParameters.FieldTitle = FieldTitle;
	EndIf;
	
	Return FieldParameters;
	
EndFunction

// Returns parameters of total and quantitative resources of balance registers.
//
// Returns:
//  Structure:
//  * LengthOfSum - Number
//  * SumAccuracy - Number
//  * LengthOfQuantity - Number
//  * QuantityAccuracy - Number
//
Function ParametersOfAmountAndQuantityOfResources() Export
	
	ResourcesParameters = New Structure;
	ResourcesParameters.Insert("LengthOfSum", 15);
	ResourcesParameters.Insert("SumAccuracy", 2);
	ResourcesParameters.Insert("LengthOfQuantity", 15);
	ResourcesParameters.Insert("QuantityAccuracy", 3);
	
	Return ResourcesParameters;
	
EndFunction

// Returns an array of indicators related to both balance registers at the same time and used only in pairs.
//
// Returns:
//  Array of EnumRef.IndicatorsOfAnalyticalRegisters
//
Function IndicatorsForCorrespondingRegisters() Export
	
	Indicators = New Array;
	Indicators.Add(Enums.IndicatorsOfAnalyticalRegisters.CostExcludingVAT_);
	Indicators.Add(Enums.IndicatorsOfAnalyticalRegisters.CostExcludingVAT);
	Indicators.Add(Enums.IndicatorsOfAnalyticalRegisters.AdditionalExpensesAmountExcludingVAT);
	Indicators.Add(Enums.IndicatorsOfAnalyticalRegisters.VATCostAmount);
	Indicators.Add(Enums.IndicatorsOfAnalyticalRegisters.AmountVATAdditionalExpense);
	
	Return Indicators;
	
EndFunction

// Returns the correspondence of indicators and their names for adding columns to the correspondence table of balance registers
//
// Returns:
//  Map of KeyAndValue:
//  * Key - EnumRef.IndicatorsOfAnalyticalRegisters - Factr
//  * Value - Structure:
//   ** Key - String - indicator type (upr, Local, shaft)
//   ** Value - String - Indicator Name
//
Function NamesOfSummaryIndicators() Export
	
	IndicatorsNames = New Map;
	IndicatorsNames.Insert(Enums.IndicatorsOfAnalyticalRegisters.Cost_,
		New Structure("Man, Compl, Curr", "ManagementCost", "CostLocal", "CostOfProductionShaft"));
	IndicatorsNames.Insert(Enums.IndicatorsOfAnalyticalRegisters.CostExcludingVAT_,
		New Structure("Man, Compl, Curr", "CostWithoutVATMan", "CostWithoutVATLocal",
		"CostPriceWithoutVATShaft"));
	IndicatorsNames.Insert(Enums.IndicatorsOfAnalyticalRegisters.Cost,
		New Structure("Man, Compl, Curr", "CostMan", "LocalCost", "CostShaft"));
	IndicatorsNames.Insert(Enums.IndicatorsOfAnalyticalRegisters.CostExcludingVAT,
		New Structure("Man, Compl, Curr", "CostExcludingVATMan", "CostExcludingVATLocal", "CostExclVATShaft"));
	IndicatorsNames.Insert(Enums.IndicatorsOfAnalyticalRegisters.Sum, New Structure("Man, Compl, Curr",
		"SumMan", "SumCompl", "SumCurr"));
	IndicatorsNames.Insert(Enums.IndicatorsOfAnalyticalRegisters.AmountExcludingVAT,
		New Structure("Man, Compl, Curr", "AmountExcludingVATMan", "AmountExcludingVATCompl", "VATExclusiveAmountVal"));
	IndicatorsNames.Insert(Enums.IndicatorsOfAnalyticalRegisters.AdditExpenseAmount,
		New Structure("Man, Compl, Curr", "AmountOfAdditionalExpenseAmountOfMan", "AmountOfAdditionalExpensesAmountOfLocal", "AmountOfAdditionalExpensesAmountOfShaft"));
	IndicatorsNames.Insert(Enums.IndicatorsOfAnalyticalRegisters.AdditionalExpensesAmountExcludingVAT,
		New Structure("Man, Compl, Curr", "AmountOfAdditionalExpensesAmountExcludingVATMan", "AmountOfAdditionalExpensesAmountExcludingVATLocal",
		"AdditionalExpenseAmountExcludingVATVal"));
	IndicatorsNames.Insert(Enums.IndicatorsOfAnalyticalRegisters.VATAmount, New Structure("Man, Compl, Curr",
		"VATAmountMan", "VATAmountCompl", "VATAmountShaft"));
	IndicatorsNames.Insert(Enums.IndicatorsOfAnalyticalRegisters.AmountVATAdditionalExpense,
		New Structure("Man, Compl, Curr", "VATAmountOfAdditionalExpenseAmountOfMan", "VATAmountOfAdditionalExpenseAmountLocal",
		"VATAmountOfAdditionalExpenseAmountShaft"));
	IndicatorsNames.Insert(Enums.IndicatorsOfAnalyticalRegisters.PayAmount,
		New Structure("Man, Compl, Curr", "ManPaymentAmount", "PaymentAmountLocal", "PaymentAmountShaft"));
	IndicatorsNames.Insert(Enums.IndicatorsOfAnalyticalRegisters.PostpaymentAmount,
		New Structure("Man, Compl, Curr", "AmountOfManSPostPayment", "PostpaymentAmountLocal", "AmountOfPostPaymentShaft"));
	IndicatorsNames.Insert(Enums.IndicatorsOfAnalyticalRegisters.PrepaymentAmountMan,
		New Structure("Man, Compl, Curr", "ManSPrepaymentAmount", "PrepaymentAmountLocal", "PrepaymentAmountVal"));
	IndicatorsNames.Insert(Enums.IndicatorsOfAnalyticalRegisters.ProvisionForImpairment,
		New Structure("Man, Compl, Curr", "ProvisionForImpairmentMan", "ProvisionForImpairmentLocal",
		"ReserveForImpairmentOfGross"));
	IndicatorsNames.Insert(Enums.IndicatorsOfAnalyticalRegisters.AmountSalesExpenses,
		New Structure("Man, Compl, Curr", "AmountOfExpensesForSaleOfMan", "AmountOfExpensesForSaleOfLocal",
		"AmountOfExpensesForSaleOfShaft"));
	IndicatorsNames.Insert(Enums.IndicatorsOfAnalyticalRegisters.TAmountSalesExpensesWithoutVAT,
		New Structure("Man, Compl, Curr", "AmountOfExpensesForSaleWithoutVATMan", "AmountOfExpensesForSaleWithoutVATLocal",
		"AmountOfExpensesForSaleWithoutVATVal"));
	IndicatorsNames.Insert(Enums.IndicatorsOfAnalyticalRegisters.VATCostAmount,
		New Structure("Man, Compl, Curr", "VATAmountOfCostOfMan", "VATAmountOfCostLocal", "VATAmountOfCostOfShaft"));

	Return IndicatorsNames;

EndFunction

// Returns an array of types of documents for the specified type of accounting data of operation
//
// Parameters:
//  TypeOfAccountingData - EnumRef.AccountingDataTypes - Type of Accounting Data
// Returns:
//  Array of CatalogRef.MetadataObjectIDs - array of document types
//
Function ArrayOfTypesOfDocumentsByTypeOfAccountingData(TypeOfAccountingData) Export
	
	AccumulationRegistersMetadata = Metadata.AccumulationRegisters;
	
	TypesOfLoggers = New Array;
	
	TypesOfBudgetingRecorders = AccumulationRegisters.ActualBudgetingData.CreateRecordSet().Filter.Recorder.ValueType.Types();
	
	For Each RegisterMetadata In AccumulationRegistersMetadata Do
		
		If RegisterMetadata.Attributes.Find("FinRecordID") = Undefined
			Or RegisterMetadata.Attributes.Find("BusinessTransactionSetting") = Undefined Then
			Continue;
		EndIf;
		
		If RegisterMetadata = AccumulationRegistersMetadata.CustomersARAPAccounting
			Or RegisterMetadata = AccumulationRegistersMetadata.VendorsARAPAccounting Then
			Continue;
		EndIf;
		
		Try
			MotionReflectionParameters = AccumulationRegisters[RegisterMetadata.Name].ParametersForReflectingRegisteredRecordsInFinancialAccounting(RegisterMetadata);
			If MotionReflectionParameters.TypeOfAccountingData <> TypeOfAccountingData Then
				Continue;
			EndIf;
		Except
			Continue;
		EndTry;
		
		If RegisterMetadata = AccumulationRegistersMetadata.CustomersARAPAccountingByDueDates Then
			RegisterMetadata = AccumulationRegistersMetadata.CustomersARAPAccounting;
		ElsIf RegisterMetadata = AccumulationRegistersMetadata.VendorsARAPAccountingByDueDates Then
			RegisterMetadata = AccumulationRegistersMetadata.VendorsARAPAccounting;
		EndIf;
		
		TypesOfRecordersByRegister = AccumulationRegisters[RegisterMetadata.Name].CreateRecordSet().Filter.Recorder.ValueType.Types();
		For Each TypeOfRegistrar In TypesOfRecordersByRegister Do
			If TypesOfLoggers.Find(TypeOfRegistrar) = Undefined
				And TypesOfBudgetingRecorders.Find(TypeOfRegistrar) <> Undefined Then
				TypesOfLoggers.Add(TypeOfRegistrar);
			EndIf;
		EndDo;
		
	EndDo;
	
	NamesOfUnusedDocuments = FinancialAccountingByBalanceSheetRegisterData.NamesOfUnusedDocuments();
	
	MetadataOfDocumentTypes = New Array;
	For Each TypeOfRegistrar In TypesOfLoggers Do
		TypeMetadata = Metadata.FindByType(TypeOfRegistrar);
		If Common.IsDocument(TypeMetadata)
			And NamesOfUnusedDocuments.Find(TypeMetadata.Name) = Undefined Then
			MetadataOfDocumentTypes.Add(TypeMetadata);
		EndIf;
	EndDo;
	DocumentsKindsArray = TMCommonUseClientServer.ConvertMatchOrStructureToArray(
		Common.MetadataObjectIDs(MetadataOfDocumentTypes), False);
	
	Return DocumentsKindsArray;
	
EndFunction

// Returns the correspondence of the types of documents that are used to control the cash flow limit.
//
// Parameters:
//  TypeOfAccountingData - EnumRef.AccountingDataTypes
//
// Returns:
//  Map of KeyAndValue:
//   *Key - CatalogRef.MetadataObjectIDs - type of document
//   *Value - String - Full name of the document
//
Function TypesOfDocumentsForControllingLimits(TypeOfAccountingData) Export
	
	DocumentsKinds = New Map;
	RegisterName = "";
	
	If TypeOfAccountingData = Enums.AccountingDataTypes.Cash Then
		RegisterName = Metadata.AccumulationRegisters.CashToBePaid.Name;
	EndIf;
	
	If Not IsBlankString(RegisterName) Then
	
		NamesOfUnusedDocuments = FinancialAccountingByBalanceSheetRegisterData.NamesOfUnusedDocuments();
		TypesOfLimitRegisterRegistrars = AccumulationRegisters.LimitsByBudgetingData.CreateRecordSet().Filter.Recorder.ValueType.Types();
		TypesOfRecordersByRegister = AccumulationRegisters[RegisterName].CreateRecordSet().Filter.Recorder.ValueType.Types();
		TypesOfLoggers = TMCommonUseClientServer.IntersectionOfArrays(TypesOfLimitRegisterRegistrars,
			TypesOfRecordersByRegister);
		For Each TypeOfRegistrar In TypesOfLoggers Do
			TypeMetadata = Metadata.FindByType(TypeOfRegistrar);
			If NamesOfUnusedDocuments.Find(TypeMetadata.Name) = Undefined Then
				DocumentsKinds.Insert(Common.MetadataObjectID(TypeMetadata),
					TypeMetadata.FullName());
			EndIf;
		EndDo;
		
	EndIf;
	
	Return DocumentsKinds;
	
EndFunction

// Returns an array of matches of the Arrival-Expense accounting data types for the rule for getting actual data
// with an arbitrary data source.
// The types of accounting data depend on the availability of requests in the request to the negotiable registers.
//
// Parameters:
//  RuleOfFact - CatalogRef.ActualDataQueryRulesByBudgetFlowItems - a rule with an arbitrary data source
//
// Returns:
//  Array of Structure:
//   *TypeOfAccountingDataReceipt - EnumRef.AccountingDataTypes - Receipt
//   *TypeOfAccountingDataExpense - EnumRef.AccountingDataTypes - Expense
//
Function TypesOfAccountingDataRulesWithArbitraryData(RuleOfFact) Export
	
	TypesOfAccountingDataRules = New Array;
	
	DCS = DataSourcesServer.DataLayoutRules(RuleOfFact);
	Parameter_CorTypeOfAccountingData = DataCompositionServer.GetDCSParameter(DCS, "CorTypeOfAccountingData");
	If Parameter_CorTypeOfAccountingData <> Undefined Then
		CorTypeOfAccountingData = Parameter_CorTypeOfAccountingData.Value;
		If TypeOf(CorTypeOfAccountingData) = Type("EnumRef.AccountingDataTypes") Then
			TypesOfAccountingDataRules.Add(New Structure("TypeOfAccountingDataExpense, TypeOfAccountingDataReceipt",
				Enums.AccountingDataTypes.Cash, CorTypeOfAccountingData));
		ElsIf TypeOf(CorTypeOfAccountingData) = Type("ValueList") Then
			For Each ListItem In CorTypeOfAccountingData Do
				If TypeOf(ListItem.Value) = Type("EnumRef.AccountingDataTypes") Then
					TypesOfAccountingDataRules.Add(New Structure("TypeOfAccountingDataExpense, TypeOfAccountingDataReceipt",
						Enums.AccountingDataTypes.Cash, ListItem.Value));
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	Return TypesOfAccountingDataRules;
	
EndFunction

// Returns a flag for using the DCS to calculate the fact according to the rules with the Budget Execution type, which is generated programmatically.
// 
// Parameters:
//  SourceOfRuleAmount - EnumRef.IndicatorsOfAnalyticalRegisters - rule amount indicator
//  Expense - EnumRef.AccountingDataTypes - data type Expense
//
// Returns:
//  Boolean - True if 
//
Function UsedSKD_BudgetExecution(SourceOfRuleAmount, Expense) Export
	
	DCSIsUsed = False;
	
	If (GetFunctionalOption("SettingUpRulesForObtainingFactsFromCorrespondingRegisters")
		Or LimitsByBudgetingDataServer.RegisterOfBudgetingLimitsIsUsed()) Then
		
		AmountIndicators = New Array;
		If Expense = Enums.AccountingDataTypes.Cash Then
			AmountIndicators = TMCommonUseClientServer.ConvertMatchOrStructureToArray(
				RegisteredRecordsOfCashDisbursements());
		EndIf;
		
		DCSIsUsed = (AmountIndicators.Find(SourceOfRuleAmount) <> Undefined);
	
	EndIf;
	
	Return DCSIsUsed;
	
EndFunction

// Returns a data layout diagram for calculating a fact based on a document when controlling budgeting limits.
//
// Parameters:
//  Expense - EnumRef.AccountingDataTypes - Expense
//  Receipt - EnumRef.AccountingDataTypes - Receipt
//
// Returns:
//  DataCompositionSchema
//
Function DCS_BudgetFulfillment(Expense, Receipt) Export
	
	DocumentsKinds = TypesOfDocumentsForControllingLimits(Expense);
	If DocumentsKinds.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	DataCompositionSchema = DataCompositionServer.EmptyCircuit();
	DataSetName = "RegisterRecords" + Common.EnumerationValueName(Expense)
		+ Common.EnumerationValueName(Receipt);
	DataSet = DataCompositionServer.AddEmptyDataSet(DataCompositionSchema,
		Type("DataCompositionSchemaDataSetQuery"),
		DataSetName);

	QueriesTexts = New Array;
	For Each DocumentKind In DocumentsKinds Do
		ManagerOfDocument = Common.ObjectManagerByFullName(DocumentKind.Value);
		QueryText = ManagerOfDocument.QueryTextFactSourceByTypeOfAccountingData(Expense, Receipt);
		If Not IsBlankString(QueryText) Then
			QueriesTexts.Add(QueryText);
		EndIf;
	EndDo;
	QueryText = StrConcat(QueriesTexts, TMCommonUse.QuerySeparatorInJoin());
	
	CorrespondencesTable = DataSourcesServer.TableOfCorrespondenceRegisters(New Structure("Expense, Receipt",
		Expense, Receipt));
	QueryFields = New Array;
	SelectedRequestFields = New Array;
	RequestConditionFields = New Array;
	For Each Column In CorrespondencesTable.Columns Do
		If StrFind(QueryText, " AS " + Column.Name) > 0 Then
			QueryFields.Add("NestedQuery." + Column.Name + " AS " + Column.Name);
			SelectedRequestFields.Add(Column.Name + ".*");
			RequestConditionFields.Add("NestedQuery." + Column.Name + ".* AS " + Column.Name);
			FinancialReportingServer.NewSetField(DataSet, Column.Name, Column.Name, Column.Title,
				Column.ValueType);
		EndIf;
	EndDo;
	If Expense = Enums.AccountingDataTypes.Cash Then
		AmountIndicators = RegisteredRecordsOfCashDisbursements();
		For Each KeyAndValue In AmountIndicators Do
			IndicatorName = KeyAndValue.Value.Resources[0].Name;
			QueryFields.Add("NestedQuery." + IndicatorName + " AS " + IndicatorName);
			SelectedRequestFields.Add(IndicatorName);
			FinancialReportingServer.NewSetField(DataSet, IndicatorName, IndicatorName, ,
				CurrencyRateOperations.MoneyFieldTypeDescription());
		EndDo;
	EndIf;
	
	QueryTextOfDataset = 
	"SELECT
	|	BEGINOFPERIOD(NestedQuery.Period, YEAR) AS YearPeriod,
	|	BEGINOFPERIOD(NestedQuery.Period, HALFYEAR) AS HalfYearPeriod,
	|	BEGINOFPERIOD(NestedQuery.Period, QUARTER) AS QuarterPeriod,
	|	BEGINOFPERIOD(NestedQuery.Period, MONTH) AS MonthPeriod,
	|	BEGINOFPERIOD(NestedQuery.Period, TENDAYS) AS TenDaysPeriod,
	|	BEGINOFPERIOD(NestedQuery.Period, WEEK) AS WeekPeriod,
	|	BEGINOFPERIOD(NestedQuery.Period, DAY) AS DayPeriod,
	|	BEGINOFPERIOD(NestedQuery.Period, DAY) AS RatePeriod,
	|	NestedQuery.Period AS SecondPeriod,
	|	NestedQuery.DataSource AS DataSource,
	|	&RequestFieldText AS QueryFields
	|{SELECT
	|	YearPeriod,
	|	HalfYearPeriod,
	|	QuarterPeriod,
	|	MonthPeriod,
	|	TenDaysPeriod,
	|	WeekPeriod,
	|	DayPeriod,
	|	RatePeriod,
	|	SecondPeriod,
	|	DataSource,
	|	(QueryFields)}
	|FROM
	|	&NestedQuery AS NestedQuery
	|WHERE
	|	&SourcePrivilegedMode = &PrivilegedMode
	|{WHERE
	|	(""DataSourceID"") AS DataSourceID,
	|	NestedQuery.Recorder AS Recorder,
	|	NestedQuery.DataSource AS DataSource,
	|	(BEGINOFPERIOD(NestedQuery.Period, DAY)) AS DayPeriod,
	|	(BEGINOFPERIOD(NestedQuery.Period, WEEK)) AS WeekPeriod,
	|	(BEGINOFPERIOD(NestedQuery.Period, TENDAYS)) AS TenDaysPeriod,
	|	(BEGINOFPERIOD(NestedQuery.Period, MONTH)) AS MonthPeriod,
	|	(BEGINOFPERIOD(NestedQuery.Period, QUARTER)) AS QuarterPeriod,
	|	(BEGINOFPERIOD(NestedQuery.Period, HALFYEAR)) AS HalfYearPeriod,
	|	(BEGINOFPERIOD(NestedQuery.Period, YEAR)) AS YearPeriod,
	|	(BEGINOFPERIOD(NestedQuery.Period, DAY)) AS RatePeriod,
	|	(&TextOfRequestConditionField)}";
	QueryTextOfDataset = StrReplace(QueryTextOfDataset, "&RequestFieldText AS QueryFields", StrConcat(
		QueryFields, "," + Chars.LF + Chars.Tab));
	QueryTextOfDataset = StrReplace(QueryTextOfDataset, "(QueryFields)", StrConcat(
		SelectedRequestFields, "," + Chars.LF + Chars.Tab));
	QueryTextOfDataset = StrReplace(QueryTextOfDataset, "(&TextOfRequestConditionField)", StrConcat(
		RequestConditionFields, "," + Chars.LF + Chars.Tab));
	QueryTextOfDataset = StrReplace(QueryTextOfDataset, "&NestedQuery", "(" + QueryText + ")");
	
	DataSet.Query = QueryTextOfDataset;
	
	FieldAliasesToAdjust = New Map;
	If Not GetFunctionalOption("SettingUpRulesForObtainingFactsFromCorrespondingRegisters") Then
		// Field aliases are used for reverse analytical registers
		If Receipt = Enums.AccountingDataTypes.IncomeExpenses Then
			FieldAliasesToAdjust.Insert("LineOfBusinessOfIncomeExpenses",
				"LineOfBusinessItems");
		ElsIf Receipt = Enums.AccountingDataTypes.OtherAssetsLiabilities Then
			FieldAliasesToAdjust.Insert("LineOfBusinessOfAssetsLiabilities",
				"LineOfBusinessItems");
			FieldAliasesToAdjust.Insert("DivisionOfAssetsLiabilities", "IncomeExpenseBusinessUnit");
		EndIf;
	EndIf;
	For Each CorrectedAlias In FieldAliasesToAdjust Do
		DataSet.Query = StrReplace(DataSet.Query, CorrectedAlias.Key, CorrectedAlias.Value);
	EndDo;
	
	DataCompositionServer.AddParameter(DataCompositionSchema, "Expense",
		New TypeDescription("EnumRef.AccountingDataTypes"), Expense);
	DataCompositionServer.AddParameter(DataCompositionSchema, "Receipt",
		New TypeDescription("EnumRef.AccountingDataTypes"), Receipt);
	DataCompositionServer.AddParameter(DataCompositionSchema, "IDOfUnusedFinRecord", ,
		DocumentsPosting.IDOfUnusedFinRecord());
	DataCompositionServer.AddParameter(DataCompositionSchema, "PrivilegedMode");
	DataCompositionServer.AddParameter(DataCompositionSchema, "SourcePrivilegedMode");

	Return DataCompositionSchema;

EndFunction

// Returns the layout diagram of the hierarchy of data sources for budgeting data
//
// Returns:
//  DataCompositionSchema
//
Function DCS_HierarchyOfBudgetingDataSources() Export
	
	Return ChartsOfCharacteristicTypes.BudgetFlowItemDimensions.GetTemplate("HierarchyOfBudgetingDataSources");
	
EndFunction

#EndRegion 
#Region BusinessTransactionsSettings

// For a business operation, returns a data layout scheme
// that can be used to get movements for the current business operation.
//
// Parameters:
//  BusinessOperation - CatalogRef.BusinessTransactionsSettings - a business operation 
//                        that needs to get a schema for getting data.
//
// Returns:
//   DataCompositionSchema - the scheme of obtaining data on the current business operation.
//
Function DataAcquisitionScheme(BusinessOperation) Export

	DataAcquisitionScheme = Undefined;
	NameOfDataSource = Common.ObjectAttributeValue(BusinessOperation, "DataSource");
	TemplatesForDataSources = Metadata.Catalogs.BusinessTransactionsSettings.Templates;
	DataSourceTemplate = TemplatesForDataSources.Find(NameOfDataSource); // MetadataObjectTemplate -
	If DataSourceTemplate <> Undefined Then
		SchemaName = DataSourceTemplate.Name; 
		DataAcquisitionScheme = Catalogs.BusinessTransactionsSettings.GetTemplate(SchemaName);
	EndIf;
	
	Return DataAcquisitionScheme;

EndFunction

// Defines the list of business operations reflected in the current accumulation register.
//
// Parameters:
//  RegisterName - String - Name of the accumulation register.
//
// Returns:
//    CatalogRef.BusinessTransactionsSettings - an array of business transactions reflected in the transferred accumulation register.
//
Function BusinessOperationsOfAnalyticalRegisters(RegisterName) Export
	
	Query = New Query;
	Query.Text = "SELECT
	|	BusinessTransactionsSettings.Ref
	|FROM
	|	Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|WHERE
	|	BusinessTransactionsSettings.DataSource = &RegisterName";
	Query.SetParameter("RegisterName", RegisterName);
	QueryResult = Query.Execute();
	If Not QueryResult.IsEmpty() Then
		Return QueryResult.Unload().UnloadColumn("Ref");
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// Returns a list of all accumulation registers used for storing analytical information.
//
// Returns:
//    ValueList of String - list of accumulation registers.
//
Function AvailableDataSources() Export
	
	List = New ValueList;
	List.Add(Metadata.AccumulationRegisters.RevenueAndCOGS.Name, Metadata.AccumulationRegisters.RevenueAndCOGS.Synonym);
	List.Add(Metadata.AccumulationRegisters.RecordsCashIncomeExpenses.Name, Metadata.AccumulationRegisters.RecordsCashIncomeExpenses.Synonym);
	List.Add(Metadata.AccumulationRegisters.RecordsCashCounterparty.Name, Metadata.AccumulationRegisters.RecordsCashCounterparty.Synonym);
	List.Add(Metadata.AccumulationRegisters.CashFlow.Name, Metadata.AccumulationRegisters.CashFlow.Synonym);
	List.Add(Metadata.AccumulationRegisters.RecordsIncomeExpensesOtherAssetsLiabilities.Name, Metadata.AccumulationRegisters.RecordsIncomeExpensesOtherAssetsLiabilities.Synonym);
	List.Add(Metadata.AccumulationRegisters.RecordsCounterpartyIncomeExpenses.Name, Metadata.AccumulationRegisters.RecordsCounterpartyIncomeExpenses.Synonym);
	List.Add(Metadata.AccumulationRegisters.RecordsCounterpartyCounterparty.Name, Metadata.AccumulationRegisters.RecordsCounterpartyCounterparty.Synonym);
	List.Add(Metadata.AccumulationRegisters.RegisterRecordsProductsIncomeExpenses.Name, Metadata.AccumulationRegisters.RegisterRecordsProductsIncomeExpenses.Synonym);
	List.Add(Metadata.AccumulationRegisters.RecordsProductsProducts.Name, Metadata.AccumulationRegisters.RecordsProductsProducts.Synonym);
	List.Add(Metadata.AccumulationRegisters.Purchases.Name, Metadata.AccumulationRegisters.Purchases.Synonym);
	
	List.Add(Metadata.AccumulationRegisters.OtherExpenses.Name, Metadata.AccumulationRegisters.OtherExpenses.Synonym);
	List.Add(Metadata.AccumulationRegisters.CustomersARAPAccountingByDocuments.Name, Metadata.AccumulationRegisters.CustomersARAPAccountingByDocuments.Synonym);
	List.Add(Metadata.AccumulationRegisters.VendorsARAPAccountingByDocuments.Name, Metadata.AccumulationRegisters.VendorsARAPAccountingByDocuments.Synonym);
	List.Add(Metadata.AccumulationRegisters.FixedAssetsDepreciationCharge.Name, Metadata.AccumulationRegisters.FixedAssetsDepreciationCharge.Synonym);
	List.Add(Metadata.AccumulationRegisters.IntangibleAssetsAmortizationCharge.Name, Metadata.AccumulationRegisters.IntangibleAssetsAmortizationCharge.Synonym);
	List.Add(Metadata.AccumulationRegisters.FACost.Name, Metadata.AccumulationRegisters.FACost.Synonym);
	List.Add(Metadata.AccumulationRegisters.IACost.Name, Metadata.AccumulationRegisters.IACost.Synonym);
	VATRegisters = VATAccountingERP.SourcesOfBusinessTransactionData();
	For Each Register In VATRegisters Do
		List.Add(Register.Value, Register.Presentation);	
	EndDo;
	
	Return List;
	
EndFunction

#EndRegion 

#EndRegion
#Region Private

Function NameOfTemplateBySourceValue(SourceOfTemplateName)
	
	TemplateName = Undefined;
	
	SupportedTypes = SupportedTemplateNameSourceTypes();
	SourceTypeOfTemplateName = TypeOf(SourceOfTemplateName);
	
	If SupportedTypes.Find(SourceTypeOfTemplateName) = Undefined Then
		Raise NStr("vi = 'Loại nguồn nhận dữ liệu không hợp lệ.';
					|ru = 'Недопустимый тип источника получения данных.';
					|en = 'Invalid type of data receipt source.'; fa = 'Invalid type of data receipt source.';
					|it = 'Tipo di origine dati non valido.';
					|pl = 'Niedopuszczalny typ źródła pobierania danych.';
					|tr = 'Veri alım kaynağının kabul edilemeyecek türü'");
	EndIf;
	
	If SourceTypeOfTemplateName = Type("EnumRef.BusinessTransactions") Then
		OperationName = Common.EnumerationValueName(SourceOfTemplateName);
		TemplateName = Common.ObjectAttributeValue(Catalogs.BusinessTransactionsSettings[OperationName], "DataSource");
		
	ElsIf SourceTypeOfTemplateName = Type("CatalogRef.BusinessTransactionsSettings") Then
		TemplateName = Common.ObjectAttributeValue(SourceOfTemplateName, "DataSource");
		
	ElsIf SourceTypeOfTemplateName = Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems") Then
		TemplateName = Common.ObjectAttributeValue(SourceOfTemplateName, "NameOfBudgetDataSource");
		
	EndIf;
		
	Return TemplateName;
		
EndFunction

Function SourceDCSDataSet(Val DataCompositionSchema, Val SourceCatalogName, Val DataSourceID)
	Var SourceDCSDataSet;
	
	SourceDCSDataSet = DataCompositionSchema.DataSets.Find("CombinedFact");
	If SourceDCSDataSet = Undefined Then
		If DataCompositionSchema.DataSets.Count() > 0 Then
			SourceDCSDataSet = DataCompositionSchema.DataSets[0];
		Else 
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không có một bộ dữ liệu nào trong hệ thống kiểm soát truy cập của thư mục ""%1"" của bố cục ""%2"".';
					|ru = 'В СКД справочника ""%1"" макета ""%2"" нет ни одного набора данных.';
					|en = 'There are no data sets in the DCS of the ""%1"" catalog of the ""%2"" template.'; fa = 'There are no data sets in the DCS of the ""%1"" catalog of the ""%2"" template.';
					|it = 'Non esiste un singolo ""%1"" set ""%2"" di dati nel Sistema di composizione dei dati layout.';
					|pl = 'W SKD katalogu ""%1"" makiety ""%2"" brak żadnego kompletu danych.';
					|tr = 'Veri Oluşturma Sistemi''nde ""%2"" maketinin ""%1"" kataloğu tek bir veri kümesi değil.'"), 
				SourceCatalogName,
				DataSourceID);
				
			Raise MessageText;
		EndIf;
	EndIf;

	Return SourceDCSDataSet;
EndFunction

#EndRegion
