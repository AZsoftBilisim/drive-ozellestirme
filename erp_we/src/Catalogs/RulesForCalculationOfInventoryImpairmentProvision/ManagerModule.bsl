#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public
	
// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	Reports.ApplicationOfRulesForCalculationOfInventoryImpairmentProvision.AddRuleApplicationControlCommand(ReportsCommands);
	
EndProcedure

// Generates a table of required reserves according to the settings specified in the reserve formation rule
// 
// Parameters:
//  Rule - CatalogRef.RulesForCalculationOfInventoryImpairmentProvision - The rule for calculating reserves, within which the table is formed
//  CalculationOfReserves - Boolean - Indication of the need to calculate summary indicators
// 	ParametersStructure - Structure - the structure containing the parameters of the formation of the table                   
// Returns:
// 	ValueTable - A table containing a list of items to be calculated according to this rule
//
Function CreateTableOfBalancesAccordingToRule(Rule, CalculationOfReserves, ParametersStructure) Export
	
	ResidueLayoutScheme = Catalogs.RulesForCalculationOfInventoryImpairmentProvision.GetTemplate("InventoryCost");
	
	AddSummaryIndicatorsToDCSRequest(ResidueLayoutScheme, CalculationOfReserves, ParametersStructure);
	
	DataCompositionSettings = ResidueLayoutScheme.DefaultSettings;
	
	RuleDetails = Common.ObjectAttributesValues(Rule, 
							"StorageOfDataCompositionSettings,PriceKind,Priority,Owner,LocalAccounting,ManagementAccounting", 
							True);
	UserSettings = RuleDetails.StorageOfDataCompositionSettings.Get(); 
	
	FillInDCSSelectionsBasedOnUserSettings(DataCompositionSettings, UserSettings);
	
	StructureOfDCSParameters = New Structure;
	StructureOfDCSParameters.Insert("Priority", RuleDetails.Priority);
	StructureOfDCSParameters.Insert("PriceKind", RuleDetails.PriceKind);
	StructureOfDCSParameters.Insert("Organization", RuleDetails.Owner);	
	
	If Not ParametersStructure.Property("LocalAccounting") Then
		StructureOfDCSParameters.Insert("LocalAccounting", RuleDetails.LocalAccounting);
	EndIf;
	
	If Not ParametersStructure.Property("ManagementAccounting") Then
		
		Period = GetPeriodFromParameterStructure(ParametersStructure);
		ManagementAccountingOfOrganizationsIsConducted = CalculationOfCostCached.CompanyManagementAccounting(Period);
		
		If ManagementAccountingOfOrganizationsIsConducted Then
			StructureOfDCSParameters.Insert("ManagementAccounting", RuleDetails.ManagementAccounting);
		Else
			StructureOfDCSParameters.Insert("ManagementAccounting", False);
		EndIf;
		
	EndIf;
	
	For Each StructureItem In ParametersStructure Do
		StructureOfDCSParameters.Insert(StructureItem.Key, StructureItem.Value);
	EndDo;
	
	CurrencySet = Constants.CreateSet("LocalAccountingCurrency, ManagementAccountingCurrency");
	CurrencySet.Read();
	
	StructureOfDCSParameters.Insert("CurrencyOfComplianceAccounting", CurrencySet.LocalAccountingCurrency);
	StructureOfDCSParameters.Insert("CurrencyOfManAccounting", CurrencySet.ManagementAccountingCurrency);
	StructureOfDCSParameters.Insert("BaseCurrency", SettingsValueCached.DefaultBaseCurrency());
	
	FilterItems1 = CommonClientServer.FindFilterItemsAndGroups(DataCompositionSettings.Filter, "ProductSegment");
	SegmentSelectionIsUsed = False;
	
	For Each FilterElement In FilterItems1 Do
		If FilterElement.Use Then  
			SegmentSelectionIsUsed = True;
			Break;
		EndIf;
	EndDo;
	
	If SegmentSelectionIsUsed Then
		StructureOfDCSParameters.Insert("FilterByProductSegmentIsUsed", True);
	EndIf;
	
	FillInDCSParameters(DataCompositionSettings, StructureOfDCSParameters);
	
	TableOfReserves = GenerateTableOfValuesFromDCS(ResidueLayoutScheme, DataCompositionSettings);
	
	Return TableOfReserves;
	
EndFunction

// Places the table of reserves, formed by the method of forming a table of statistics, in a temporary table
// 
// Parameters:
// 	TableOfBalancesByRule - ValueTable - table of reserves
// 	TempTablesManager - TempTablesManager
// 	PutParameters - Structure - Structure containing fields:
//	  * TempTableName - String - the basis of the names of temporary tables from which the final one is formed
//	  * TemporaryTableNumber - Number - the largest number of the temporary balance table
//
Procedure PutTableOfBalancesInTemporaryTable(TableOfBalancesByRule, TempTablesManager, PutParameters) Export
	
	Query = New Query;
	QueryText = RequestTextIsStoredInTemporaryTable();
	
	If PutParameters.Property("TemporaryTableNumber") Then
		TempTableName = TempTableName(PutParameters.TempTableName, PutParameters.TemporaryTableNumber);
	Else
		TempTableName = PutParameters.TempTableName;
	EndIf;
	
	Query.Text = StrReplace(QueryText, "TemporaryTableOfBalances", TempTableName);  
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("BalanceTable", TableOfBalancesByRule);
	Query.Execute();
	
EndProcedure

// Generates a list of variable balance tables according to the rules for the formation of reserves for impairment
// 
// Parameters:
//  RuleSelection - QueryResultSelection - selection from the request of the current rules for the formation of reserves
//  Period - Date - The period of formation of balances
//  TempTablesManager - TempTablesManager - Temporary table manager, in which temporary tables of balances are created
//  CalculationOfReserves - Boolean - Indication of the need to calculate summary indicators
// 
// Returns:
//  Number - number of generated temporary tables
//
Function CreateTemporaryTablesOfBalancesByRules(RuleSelection, Period, TempTablesManager, CalculationOfReserves = False) Export

	KeyOperation = "Catalog.RulesForCalculationOfInventoryImpairmentProvision.ManagerModule.CreateTemporaryTablesOfBalancesByRules";
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(KeyOperation);
	NumberOfProcessedData = 0;
	
	TemporaryTableNumber = 0;
	
	While RuleSelection.Next() Do
		
		TemporaryTableNumber = TemporaryTableNumber + 1;
					
		ParametersStructure = New Structure;
		ParametersStructure.Insert("Period", Period);
		ParametersStructure.Insert("Rule", RuleSelection.Rule);
		ParametersStructure.Insert("LocalAccounting", RuleSelection.LocalAccounting);
		ParametersStructure.Insert("ManagementAccounting", RuleSelection.ManagementAccounting);
		
		TableOfBalancesByRule = CreateTableOfBalancesAccordingToRule(RuleSelection.Rule, CalculationOfReserves, ParametersStructure);
		
		NumberOfProcessedData = NumberOfProcessedData + TableOfBalancesByRule.Count();
				
		PutParameters = New Structure;
		PutParameters.Insert("TempTableName", "TableOfBalancesByRule");
		PutParameters.Insert("TemporaryTableNumber", TemporaryTableNumber);
		PutTableOfBalancesInTemporaryTable(TableOfBalancesByRule, TempTablesManager, PutParameters);
		
	EndDo;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, NumberOfProcessedData / 1000);
	
	Return TemporaryTableNumber;
		
EndFunction

// Creates a temporary table in which data from an arbitrary number of tables of balances are grouped according to the rules.
// 
// Parameters:
//  TempTablesManager - TempTablesManager - temporary table Manager
// 	PutParameters - Structure - Structure containing fields:
//	  * TempTableName - String - the basis of the names of temporary tables from which the final one is formed
//	  * TemporaryTableNumber - Number - the largest number of the temporary balance table
//
Procedure MergeTemporaryBalanceTablesIntoSummaryTable(TempTablesManager, PutParameters) Export
	
	QueryingResultingTemporaryTable = GenerateFinalReserveRequest(PutParameters);
	QueryingResultingTemporaryTable.TempTablesManager = TempTablesManager;
	QueryingResultingTemporaryTable.Execute();
	
EndProcedure

// Creates operators for the query scheme for combining temporary tables of balances into the final one.
// 
// Parameters:
//  QuerySchema - QuerySchema - the scheme of the request for combining temporary tables of balances into the final one
//  OriginalTableName - String - the basis of the names of temporary tables from which the final one is formed
//  MaximumTemporaryTableNumber - Number - the largest number of the temporary balance table
//
Procedure GenerateTemporaryTableJoinOperators(QuerySchema, OriginalTableName, MaximumTemporaryTableNumber) Export
	
	QueryPackage = QuerySchema.QueryBatch[0];
	OriginalOperator = QueryPackage.Operators[0];
	
	For TemporaryTableNumber = 1 To MaximumTemporaryTableNumber Do
		
		NewQueryOperator = QueryPackage.Operators.Add();
		
		TempTableName = Catalogs.RulesForCalculationOfInventoryImpairmentProvision.TempTableName(OriginalTableName, TemporaryTableNumber);
		QuerySchemaSource = NewQueryOperator.Sources.Add(Type("QuerySchemaTempTableDescription"), TempTableName);
		
		For Each TheQueryBox In OriginalOperator.SelectedFields Do
			FieldAlias = QueryPackage.Columns[OriginalOperator.SelectedFields.IndexOf(TheQueryBox)].Alias;
			QuerySchemaSource.Source.AvailableFields.Add(FieldAlias);
			NewQueryOperator.SelectedFields.Add(StrReplace(TheQueryBox, "BalanceTable", TempTableName));
		EndDo;

	EndDo;
	
	QueryPackage.Operators.Delete(0);
	
EndProcedure

// Forms the name of the temporary table of balances, combining the basis of the name and the number of the temporary table.
// 
// Parameters:
//  OriginalName - String - the basis of the temporary table name
//  TemporaryTableNumber - Number - temporary table number
// 
// Returns:
//  String - name of the temporary table
//
Function TempTableName(OriginalName, TemporaryTableNumber) Export
	Return StrTemplate("%1%2", OriginalName, Format(TemporaryTableNumber, "NG="));
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
	|	ValueAllowed(Owner)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion
	
#EndRegion

#EndIf

#Region EventHandlers

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	// StandardSubsystems.Core
	NationalLanguageSupportServer.ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing, Metadata.Catalogs.ProductCostElements);
	// End StandardSubsystems.Core		
EndProcedure

#EndIf

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	// StandardSubsystems.Core
	NationalLanguageSupportClientServer.PresentationFieldsGetProcessing(Fields, StandardProcessing);
	// End StandardSubsystems.Core
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	// StandardSubsystems.Core
	NationalLanguageSupportClientServer.PresentationGetProcessing(Data, Presentation, StandardProcessing);
	// End StandardSubsystems.Core
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

Procedure AddSummaryIndicatorsToDCSRequest(ResidueLayoutScheme, CalculationOfReserves, ParametersStructure)
	
	ExpressionOfSelectionByPeriod = New QuerySchemaExpression("&Period");
	
	FormulaOfActualCostOfLocal = 
		"Balance.LocalCostBalance 
		| + Balance.AddExpensesLocalBalance 
		| + Balance.LaborCostsLocalBalance
		| + Balance.ItemizedFixedCostsComplBalance
		| + Balance.ItemizedVariableCostsComplBalance";
	
	LocalNetSellingValueFormula = 
		"Balance.CountBalance 
		| * CASE WHEN Prices.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|			OR Prices.Package = Keys.StorageUnit 
		|		THEN 1
		|		ELSE Keys.WeightToUnitRatio
		|	END
		| * ISNULL(Prices.Price, 0)
		| * CASE
		|		WHEN ISNULL(Prices.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) 
		|			THEN 1 
		|		ELSE CASE 
		|				WHEN Prices.Package.Numerator = 0 
		|					THEN 1 
		|				ELSE Prices.Package.Denominator / Prices.Package.Numerator 
		|			END 
		|	END
		| * CASE
		|		WHEN NOT Prices.Currency IS NULL AND NOT Prices.Currency = &CurrencyOfComplianceAccounting
		|			THEN ISNULL(ExchangeRatePrices.CourseNumerator, 0) / ISNULL(ExchangeRatePrices.CourseDenominator, 1)
		|		ELSE 1
		|	END";
					
	LocalReserveBalanceFormula = "Balance.ProvisionForImpairmentLocalBalance";
					
	LocalReserveCalculationFormula = 
		"CASE 
		|	WHEN Balance.CostLocal < &NetSaleValueOfLocal
		|		THEN Balance.ProvisionForImpairmentLocalBalance
		|	ELSE Balance.CostLocal - (&NetSaleValueOfLocal - Balance.ProvisionForImpairmentLocalBalance)
		|END";
	
	ReportPeriod = GetPeriodFromParameterStructure(ParametersStructure);
	ManagementAccountingOfOrganizationsIsConducted = CalculationOfCostCached.CompanyManagementAccounting(ReportPeriod);
	
	If ManagementAccountingOfOrganizationsIsConducted Then
		
		FormulaOfActualCostOfMan = 
			"Balance.CostManBalance 
			| + Balance.AddExpensesManBalance 
			| + Balance.LaborCostsManBalance
			| + Balance.ItemizedFixedCostsManagBalance
			| + Balance.ItemizedVariableCostsManagBalance";
		
		ManSNetSellingValueFormula = 
			"Balance.CountBalance 
			| * CASE WHEN Prices.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
			|			OR Prices.Package = Keys.StorageUnit 
			|		THEN 1
			|		ELSE Keys.WeightToUnitRatio
			|	END
			| * ISNULL(Prices.Price, 0)
			| * CASE
			|		WHEN ISNULL(Prices.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) 
			|			THEN 1 
			|		ELSE CASE 
			|				WHEN Prices.Package.Numerator = 0 
			|					THEN 1 
			|				ELSE Prices.Package.Denominator / Prices.Package.Numerator 
			|			END 
			|	END
			| * CASE
			|		WHEN Prices.Currency = &CurrencyOfManAccounting
			|			OR ISNULL(ExchangeRatePrices.CourseDenominator, 0) * CurrencyExchangeRateManAccounting.CourseNumerator = 0
			|			THEN 1
			|		ELSE ExchangeRatePrices.CourseNumerator * CurrencyExchangeRateManAccounting.CourseDenominator 
			|				/ (ExchangeRatePrices.CourseDenominator * CurrencyExchangeRateManAccounting.CourseNumerator)
			|	END";
						
		ManReserveBalanceFormula = "Balance.ProvisionForImpairmentManBalance";
	
		ManReserveCalculationFormula = 
			"CASE 
			|	WHEN Balance.ManagementCost < &NetSellingValueOfMan
			|		THEN Balance.ProvisionForImpairmentManBalance
			|	ELSE Balance.ManagementCost - (&NetSellingValueOfMan - Balance.ProvisionForImpairmentManBalance)
			|END";
		
	Else
		
		FormulaOfActualCostOfMan = "0";
		ManSNetSellingValueFormula = "0";
		ManReserveCalculationFormula = "0";
		ManReserveBalanceFormula = "0";
		
	EndIf;
				
	LocalReserveCalculationFormula = StrReplace(LocalReserveCalculationFormula, "&NetSaleValueOfLocal", LocalNetSellingValueFormula);
	ManReserveCalculationFormula = StrReplace(ManReserveCalculationFormula, "&NetSellingValueOfMan", ManSNetSellingValueFormula);
	
	Schema = New QuerySchema;
	Schema.SetQueryText(ResidueLayoutScheme.DataSets[0].Query);
	
	QueryPackageBalance = Schema.QueryBatch[1];
	QueryOperatorBalance = QueryPackageBalance.Operators[0];
	
	RequestPackageKeys = Schema.QueryBatch[2];
	RequestOperatorKeys = RequestPackageKeys.Operators[0];
	
	RequestPackageCalculationOfReserves = Schema.QueryBatch[3];
	RequestOperatorCalculationOfReserves = RequestPackageCalculationOfReserves.Operators[0];
	DataSourceCalculationOfReserves = RequestOperatorCalculationOfReserves.Sources[0];
	
	If PriceManagementSystemServerCall.UsePriceManagementSystem25(ReportPeriod) Then
			
		RequestOperatorKeys.SelectedFields.Add(
				"CASE
				|	WHEN Keys.Products.ProductKind.SettingsOfPriceKeyByItemVariant = VALUE(Enum.FilterOptionForPriceKey.DontUse)
				|		THEN VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
				|	ELSE Keys.Characteristic.ItemsCharacteristicForPricing
				|END",
				RequestPackageKeys.Columns.IndexOf(RequestPackageKeys.Columns.Find("Characteristic")));
			
		RequestOperatorKeys.SelectedFields.Add(
				"CASE
				|	WHEN Keys.Products.ProductKind.SettingsOfPriceKeyByBatch = VALUE(Enum.FilterOptionForPriceKey.DontUse)
				|		THEN VALUE(Catalog.ItemsBatchesForPricing.EmptyRef)
				|	ELSE ISNULL(Keys.Series.ItemsBatchForPricing, VALUE(Catalog.ItemsBatchesForPricing.EmptyRef))
				|END",
				RequestPackageKeys.Columns.IndexOf(RequestPackageKeys.Columns.Find("Series")));
		
		SourceOfPrices = RequestOperatorCalculationOfReserves.Sources.Add("InformationRegister.ItemsPrices25.SliceLast", "Prices");
		SourceOfPrices.Source.Parameters[0].Expression = ExpressionOfSelectionByPeriod;
		SourceOfPrices.Source.Parameters[1].Expression = New QuerySchemaExpression(
			"PriceKind = &PriceKind AND PricingPackage = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)");
		DataSourceCalculationOfReserves.Joins.Add(SourceOfPrices,
			"Keys.Products = Prices.Products
			|AND Keys.Characteristic = Prices.PricingVariant
			|AND Keys.Series = Prices.PricingBatch");
	
	Else
		
		SourceOfPrices = RequestOperatorCalculationOfReserves.Sources.Add("InformationRegister.ItemsPrices.SliceLast", "Prices");
		SourceOfPrices.Source.Parameters[0].Expression = ExpressionOfSelectionByPeriod;
		SourceOfPrices.Source.Parameters[1].Expression = New QuerySchemaExpression("PriceKind = &PriceKind");
		DataSourceCalculationOfReserves.Joins.Add(SourceOfPrices,
			"Keys.Products = Prices.Products
			|AND Keys.Characteristic = Prices.Characteristic");
	
	EndIf;
	
	If CalculationOfReserves = True Then
		DataSourceCalculationOfReserves.Joins[DataSourceCalculationOfReserves.Joins.Count() - 1].JoinType = QuerySchemaJoinType.Inner;
	EndIf;
	
	SourceOfExchangeRates = RequestOperatorCalculationOfReserves.Sources.Add("InformationRegister.RelativeExchangeRates.SliceLast", "ExchangeRatePrices");
	SourceOfExchangeRates.Source.Parameters[0].Expression = ExpressionOfSelectionByPeriod;
	SourceOfExchangeRates.Source.Parameters[1].Expression = New QuerySchemaExpression("BaseCurrency = &BaseCurrency");
	DataSourceCalculationOfReserves.Joins.Add(SourceOfExchangeRates, "Prices.Currency = ExchangeRatePrices.Currency");
	
	QueryOperatorBalance.SelectedFields.Set(
			QueryPackageBalance.Columns.IndexOf(QueryPackageBalance.Columns.Find("CostLocal")),
			New QuerySchemaExpression(FormulaOfActualCostOfLocal));
	
	QueryOperatorBalance.SelectedFields.Set(
			QueryPackageBalance.Columns.IndexOf(QueryPackageBalance.Columns.Find("ManagementCost")),
			New QuerySchemaExpression(FormulaOfActualCostOfMan));
	
	QueryOperatorBalance.SelectedFields.Set(
			QueryPackageBalance.Columns.IndexOf(QueryPackageBalance.Columns.Find("ProvisionForImpairmentLocalBalance")),
			New QuerySchemaExpression(LocalReserveBalanceFormula));
	
	QueryOperatorBalance.SelectedFields.Set(
			QueryPackageBalance.Columns.IndexOf(QueryPackageBalance.Columns.Find("ProvisionForImpairmentManBalance")),
			New QuerySchemaExpression(ManReserveBalanceFormula));
	
	RequestOperatorCalculationOfReserves.SelectedFields.Set(
			RequestPackageCalculationOfReserves.Columns.IndexOf(RequestPackageCalculationOfReserves.Columns.Find("NetSaleValueOfLocal")),
			New QuerySchemaExpression(LocalNetSellingValueFormula));
	
	RequestOperatorCalculationOfReserves.SelectedFields.Set(
			RequestPackageCalculationOfReserves.Columns.IndexOf(RequestPackageCalculationOfReserves.Columns.Find("NetSellingValueOfMan")),
			New QuerySchemaExpression(ManSNetSellingValueFormula));
					
	If ParametersStructure.Property("LocalAccounting")
		And ParametersStructure.LocalAccounting
		Then
		
		RequestOperatorCalculationOfReserves.SelectedFields.Set(
			RequestPackageCalculationOfReserves.Columns.IndexOf(RequestPackageCalculationOfReserves.Columns.Find("ProvisionForImpairmentLocal")),
			New QuerySchemaExpression(StrTemplate("-1 * (%1)", LocalReserveCalculationFormula)));
			
		RequestOperatorCalculationOfReserves.SelectedFields.Set(
			RequestPackageCalculationOfReserves.Columns.IndexOf(RequestPackageCalculationOfReserves.Columns.Find("ProvisionForImpairmentOfLocalRevenue")),
			New QuerySchemaExpression(LocalReserveCalculationFormula));
			
	EndIf;
		
	If ParametersStructure.Property("ManagementAccounting")
		And ParametersStructure.ManagementAccounting
		Then
				
		RequestOperatorCalculationOfReserves.SelectedFields.Set(
			RequestPackageCalculationOfReserves.Columns.IndexOf(RequestPackageCalculationOfReserves.Columns.Find("ProvisionForImpairmentMan")),
			New QuerySchemaExpression(StrTemplate("-1 * (%1)", ManReserveCalculationFormula)));
			
		RequestOperatorCalculationOfReserves.SelectedFields.Set(
			RequestPackageCalculationOfReserves.Columns.IndexOf(RequestPackageCalculationOfReserves.Columns.Find("ProvisionForImpairmentOfManRevenue")),
			New QuerySchemaExpression(ManReserveCalculationFormula));
			
	EndIf;
	
	RequestOperatorCalculationOfReserves.SelectedFields.Set(
			RequestPackageCalculationOfReserves.Columns.IndexOf(RequestPackageCalculationOfReserves.Columns.Find("PriceIsIndicated")),
			New QuerySchemaExpression("NOT Prices.Price IS NULL"));
		
	If ParametersStructure.Property("OnlyNonZeroSums")
		And ParametersStructure.OnlyNonZeroSums
		Then
		
		RequestPackageSummary = Schema.QueryBatch[4];
		LocalQueryOperator = RequestPackageSummary.Operators[0];
		LocalQueryOperator.Filter.Add(New QuerySchemaExpression("ProvisionForImpairmentLocal <> 0"));
		
		If ManagementAccountingOfOrganizationsIsConducted Then
			ManRequestOperator = RequestPackageSummary.Operators[1];
			ManRequestOperator.Filter.Add(New QuerySchemaExpression("ProvisionForImpairmentMan <> 0"));
		EndIf;
		
	EndIf;
	
	If CalculationOfReserves = True Then
		Schema.QueryBatch.Delete(5);
	Else
		Schema.QueryBatch.Delete(4);			
	EndIf;
	
	ResidueLayoutScheme.DataSets[0].Query = Schema.GetQueryText();
	
EndProcedure


// Creates selection elements in the layout settings and fills them according to the selections in the user settings
// 
// Parameters:
// 	DataCompositionSettings - DataCompositionSettings - layout settings where you need to fill in the parameters
// 	UserSettings - DataCompositionSettings - layout settings containing selections to be copied
//
Procedure FillInDCSSelectionsBasedOnUserSettings(DataCompositionSettings, UserSettings)
	
	If UserSettings <> Undefined Then
			
		Filter = DataCompositionSettings.Filter;
		FillInDCSSelectionElementsRecursively(Filter, UserSettings.Filter);
		
	EndIf;
	
EndProcedure

// Recursively fills in the receiver selection elements from the source selection elements.
// 
// Parameters:
// 	FilterReceiver - DataCompositionFilter, DataCompositionFilterItemGroup - receiver of selection data for filling
// 	FilterSource - DataCompositionFilter, DataCompositionFilterItemGroup - source of selection data to fill in
Procedure FillInDCSSelectionElementsRecursively(FilterReceiver, FilterSource)
	
	For Each FilterElement In FilterSource.Items Do
	
		If TypeOf(FilterElement) = Type("DataCompositionFilterItemGroup") Then
			NewElementOfSelection = FilterReceiver.Items.Add(Type("DataCompositionFilterItemGroup"));
			FillPropertyValues(NewElementOfSelection, FilterElement);
			FillInDCSSelectionElementsRecursively(NewElementOfSelection, FilterElement);
		Else
			NewElementOfSelection = FilterReceiver.Items.Add(Type("DataCompositionFilterItem"));
			FillPropertyValues(NewElementOfSelection, FilterElement);
		EndIf;
		
	EndDo;
	
EndProcedure

// Creates data parameters in the layout settings and sets values in them
// 
// Parameters:
// 	DataCompositionSettings - DataCompositionSettings - layout settings where you need to fill in the parameters
// 	ParametersStructure - Structure - a structure containing the names and values of the parameters to be added to the layout settings:
//  
Procedure FillInDCSParameters(DataCompositionSettings, ParametersStructure)

	DataParameters = DataCompositionSettings.DataParameters;
	
	For Each Parameter In ParametersStructure Do
			
		NewDataParameter = DataParameters.Items.Add();
		NewDataParameter.Parameter = New DataCompositionParameter(Parameter.Key);
		
		DataParameters.SetParameterValue(Parameter.Key, Parameter.Value);

	EndDo;
	
	ReportPeriod = GetPeriodFromParameterStructure(ParametersStructure); 
		
	NewDataParameter = DataParameters.Items.Add();
	NewDataParameter.Parameter = New DataCompositionParameter("ReportPeriod");
		
	DataParameters.SetParameterValue("ReportPeriod", ReportPeriod);
	
EndProcedure

// Outputs the result of the SKD layout to the table of values
// 
// Parameters:
// 	DataCompositionSchema - DataCompositionSchema - initial SKD
// 	DataCompositionSettings - DataCompositionSettings - SKD settings
// Returns:
// 	ValueTable - the resulting table
//
Function GenerateTableOfValuesFromDCS(DataCompositionSchema, DataCompositionSettings)
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, 
							DataCompositionSettings,
							,
							,
							Type("DataCompositionValueCollectionTemplateGenerator"));
		
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate);
	
	DataTable = New ValueTable;
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	OutputProcessor.SetObject(DataTable);
	OutputProcessor.Output(CompositionProcessor);
	
	Return DataTable;
	
EndFunction

Function GenerateFinalReserveRequest(PutParameters)
	
	FinalRequest = New Query;
	Schema = New QuerySchema;
	QueryText = RequestTextIsStoredInTemporaryTable();
	QueryText = StrReplace(QueryText, "&BalanceTable", PutParameters.TempTableName);
	Schema.SetQueryText(QueryText);
	
	GenerateTemporaryTableJoinOperators(Schema, PutParameters.TempTableName, PutParameters.TemporaryTableNumber); 
	
	FinalRequest.Text = Schema.GetQueryText();
	
	Return FinalRequest;
	
EndFunction

Function RequestTextIsStoredInTemporaryTable()
	
	// When changing the composition of the fields, you also need to change the fields in:
	// - Report.The intersectionedit is the calculation of reserves like the depreciation of reserves.The text of the request for the Unified group has been corrected()
	QueryText = 
	"SELECT
	|	BalanceTable.Period AS Period,
	|	BalanceTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	BalanceTable.Warehouse AS Warehouse,
	|	BalanceTable.AccountingSection AS AccountingSection,
	|	BalanceTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	BalanceTable.InventoryType AS InventoryType,
	|	BalanceTable.Organization AS Organization,
	|	BalanceTable.Lot AS Lot,
	|	BalanceTable.LotVendorAttributes AS LotVendorAttributes,
	|	BalanceTable.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	BalanceTable.VATActivityType AS VATActivityType,
	|	BalanceTable.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	BalanceTable.Rule AS Rule,
	|	BalanceTable.Priority AS Priority,
	|	BalanceTable.PriceKind AS PriceKind,
	|	BalanceTable.LocalAccounting AS LocalAccounting,
	|	BalanceTable.BusinessOperation AS BusinessOperation,
	|	BalanceTable.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	BalanceTable.CalculationOfCost AS CalculationOfCost,
	|	BalanceTable.ProvisionForImpairmentLocal AS ProvisionForImpairmentLocal,
	|	BalanceTable.ProvisionForImpairmentMan AS ProvisionForImpairmentMan,
	|	BalanceTable.ProvisionForImpairmentOfLocalRevenue AS ProvisionForImpairmentOfLocalRevenue,
	|	BalanceTable.ProvisionForImpairmentOfManRevenue AS ProvisionForImpairmentOfManRevenue,
	|	BalanceTable.PriceIsIndicated AS PriceIsIndicated,
	|	BalanceTable.CountBalance AS CountBalance,
	|	BalanceTable.CostLocal AS CostLocal,
	|	BalanceTable.ManagementCost AS ManagementCost,
	|	BalanceTable.NetSaleValueOfLocal AS NetSaleValueOfLocal,
	|	BalanceTable.NetSellingValueOfMan AS NetSellingValueOfMan,
	|	BalanceTable.RecordType AS RecordType	
	|INTO TemporaryTableOfBalances
	|FROM
	|	&BalanceTable AS BalanceTable";
	
	Return QueryText
				
EndFunction

Function GetPeriodFromParameterStructure(ParametersStructure)
	
	Period = '00010101';
	
	If ParametersStructure.Property("Period") Then
		
		If TypeOf(ParametersStructure.Period) = Type("Boundary") Then 
			Period= ParametersStructure.Period.Value
		Else
			Period = ParametersStructure.Period;
		EndIf;
		
	EndIf;
	
	Return Period;
	
EndFunction

#EndRegion

#EndIf
