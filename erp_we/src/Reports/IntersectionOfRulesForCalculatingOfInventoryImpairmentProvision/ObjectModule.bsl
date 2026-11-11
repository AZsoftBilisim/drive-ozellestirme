#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	ReportSettings = SettingsComposer.GetSettings();
	ReportParameters = GetReportParameters(ReportSettings);
	TempTablesManager = New TempTablesManager;
	
	If CalculationOfCostCached.BatchAccountingVersion22(ReportParameters.ReportPeriod) Then
	
		If ReportParameters.FormationOption = 1 Then
			RequestResultForRules = GetCurrentRules(ReportParameters.ReportPeriod, ReportParameters.Organization);
		Else
			RequestResultForRules = GetGroupsOfPotentiallyOverlappingRules(ReportParameters.ReportPeriod, ReportParameters.Organization, ReportParameters.FormationOption);
		EndIf;
		
		If RequestResultForRules.IsEmpty() Then
			CreateEmptyTableForDCS(TempTablesManager);
		Else
			If ReportParameters.FormationOption = 1 Then
				CreateTemporaryTableForDCSWithoutSearchingForIntersections(TempTablesManager, RequestResultForRules, ReportParameters.ReportPeriod);
			Else	
				CreateTemporaryTableForDCS(TempTablesManager, RequestResultForRules, ReportParameters.ReportPeriod);
			EndIf;
		EndIf;

	Else
		CreateEmptyTableForDCS(TempTablesManager);
	EndIf;
		
	// Let's compose and output the query result into a tabular document
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);

	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate,, DetailsData,,, TempTablesManager);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	
	OutputProcessor.Output(CompositionProcessor);
	
EndProcedure

#EndRegion

#Region Private

Function GetReportParameters(ReportSettings)
	
	ParametersStructure = New Structure("Organization,ReportPeriod,FormationOption");
	
	DataParameters = ReportSettings.DataParameters;
	ParameterOrganization = DataParameters.FindParameterValue(New DataCompositionParameter("Organization"));
	PeriodParameter = DataParameters.FindParameterValue(New DataCompositionParameter("ReportPeriod"));
	OptionParameter = DataParameters.FindParameterValue(New DataCompositionParameter("FormationOption"));
	
	If Not ParameterOrganization.Use Or Not ValueIsFilled(ParameterOrganization.Value) Then
		ParametersStructure.Organization = PredefinedValue("Catalog.Companies.EmptyRef");
	Else
		ParametersStructure.Organization = ParameterOrganization.Value;
	EndIf;
	
	If Not ValueIsFilled(PeriodParameter.Value) Then
		ParametersStructure.ReportPeriod = EndOfMonth(CurrentSessionDate());
	Else
		ParametersStructure.ReportPeriod = EndOfMonth(PeriodParameter.Value);
	EndIf;
	
	If Not ValueIsFilled(OptionParameter.Value) Then
		ParametersStructure.FormationOption = 1;
	Else
		ParametersStructure.FormationOption = OptionParameter.Value;
	EndIf;
	
	Return ParametersStructure;
	
EndFunction

Function GetCurrentRules(ReportPeriod, Organization)
	
	RequestRules = New Query(RequestTextForCurrentRules());
	RequestRules.SetParameter("ReportPeriod", ReportPeriod);
	RequestRules.SetParameter("Organization", Organization);
	RequestRules.SetParameter("CompanyManagementAccounting", CalculationOfCostCached.CompanyManagementAccounting(ReportPeriod));
		
	Return RequestRules.Execute();
	
EndFunction
	
Function GetGroupsOfPotentiallyOverlappingRules(ReportPeriod, Organization, FormationOption)
	
	RequestingRuleGroups = New Query;
	QueryText = RequestTextForRuleGroups();
	
	If FormationOption = 2 Then
		
		// With the "All intersections" formation option, grouping by priority should not be performed
		
		Schema = New QuerySchema;
		Schema.SetQueryText(QueryText);
		
		QueryFields = Schema.QueryBatch[0].Operators[0].SelectedFields;
		PriorityField = QueryFields.IndexOf(QueryFields.Find("RulesForCalculationOfInventoryImpairmentProvision.Priority"));
		QueryFields.Set(PriorityField, New QuerySchemaExpression("-1")); 
		
		QueryText = Schema.GetQueryText();
		
	EndIf;
	
	RequestingRuleGroups.Text = QueryText;	
	RequestingRuleGroups.SetParameter("ReportPeriod", ReportPeriod);
	RequestingRuleGroups.SetParameter("Organization", Organization);
	RequestingRuleGroups.SetParameter("CompanyManagementAccounting", CalculationOfCostCached.CompanyManagementAccounting(ReportPeriod));
	
	Return RequestingRuleGroups.Execute();
	
EndFunction

Procedure CreateEmptyTableForDCS(TempTablesManager)
	
	QueryingEmptyTemporaryTable = New Query;
	QueryingEmptyTemporaryTable.Text = QueryTextOfEmptySummaryTable();
	QueryingEmptyTemporaryTable.TempTablesManager = TempTablesManager;
	QueryingEmptyTemporaryTable.Execute();
		
EndProcedure

Procedure CreateTemporaryTableForDCSWithoutSearchingForIntersections(TempTablesManager, RequestResultForRules, ReportPeriod)
	
	RuleSelection = RequestResultForRules.Select(QueryResultIteration.ByGroups);
	
	NumberOfTemporaryTables = Catalogs.RulesForCalculationOfInventoryImpairmentProvision.CreateTemporaryTablesOfBalancesByRules(RuleSelection, ReportPeriod, TempTablesManager);
	
	PutParameters = New Structure;
	PutParameters.Insert("TempTableName", "TableOfBalancesByRule");
	PutParameters.Insert("TemporaryTableNumber", NumberOfTemporaryTables);
	Catalogs.RulesForCalculationOfInventoryImpairmentProvision.MergeTemporaryBalanceTablesIntoSummaryTable(TempTablesManager, PutParameters);
		
EndProcedure

Procedure CreateTemporaryTableForDCS(TempTablesManager, QueryResultByRuleGroup, ReportPeriod)
	
	SelectingGroupsOfRules = QueryResultByRuleGroup.Select(QueryResultIteration.ByGroups);
	NumberOfMergedTable = 0;
	
	While SelectingGroupsOfRules.Next() Do
		
		// Let's form a temporary table of overlapping records within a group
		// of potentially duplicate rules
		
		NumberOfMergedTable = NumberOfMergedTable + 1;
		RuleSelection = SelectingGroupsOfRules.Select();
		
		NumberOfTemporaryTables = Catalogs.RulesForCalculationOfInventoryImpairmentProvision.CreateTemporaryTablesOfBalancesByRules(RuleSelection, ReportPeriod, TempTablesManager);
	
		CombinedRequest = CreateCombinedRequestForGroupOfRules(NumberOfTemporaryTables, NumberOfMergedTable);
		CombinedRequest.TempTablesManager = TempTablesManager;
		CombinedRequest.Execute();
			
	EndDo;
	
	// Let's combine the intersecting records obtained for all groups
	
	PutParameters = New Structure;
	PutParameters.Insert("TempTableName", "IntersectingRemnants");
	PutParameters.Insert("TemporaryTableNumber", NumberOfMergedTable);
	Catalogs.RulesForCalculationOfInventoryImpairmentProvision.MergeTemporaryBalanceTablesIntoSummaryTable(TempTablesManager, PutParameters);
		
EndProcedure

Function CreateCombinedRequestForGroupOfRules(MaximumTemporaryTableNumber, NumberOfMergedTable)
	
	CombinedRequest = New Query;
	Schema = New QuerySchema;
	Schema.SetQueryText(RequestTextCombinedByRuleGroup());
	
	LastRequestPacket = Schema.QueryBatch[Schema.QueryBatch.Count() - 1];
	LastRequestPacket.PlacementTable = Catalogs.RulesForCalculationOfInventoryImpairmentProvision.TempTableName("IntersectingRemnants", NumberOfMergedTable);
	
	Catalogs.RulesForCalculationOfInventoryImpairmentProvision.GenerateTemporaryTableJoinOperators(Schema, "TableOfBalancesByRule", MaximumTemporaryTableNumber); 
	
	For TemporaryTableNumber = 1 To MaximumTemporaryTableNumber Do

		TempTableName = Catalogs.RulesForCalculationOfInventoryImpairmentProvision.TempTableName("TableOfBalancesByRule", TemporaryTableNumber);
		TTDestructionRequest = Schema.QueryBatch.Add(Type("QuerySchemaTableDropQuery"));
		TTDestructionRequest.TableName = TempTableName;
		
	EndDo;
	
	TTDestructionRequest = Schema.QueryBatch.Add(Type("QuerySchemaTableDropQuery"));
	TTDestructionRequest.TableName = "MergingRemainderTables";
	TTDestructionRequest = Schema.QueryBatch.Add(Type("QuerySchemaTableDropQuery"));
	TTDestructionRequest.TableName = "RecordsWithMultipleRules";
		
	CombinedRequest.Text = Schema.GetQueryText();
	
	Return CombinedRequest;
	
EndFunction

Function RequestTextForCurrentRules()
	
	QueryText = 
	"SELECT ALLOWED
	|	RulesForCalculationOfInventoryImpairmentProvision.Ref AS Rule,
	|	RulesForCalculationOfInventoryImpairmentProvision.Owner AS Organization,
	|	RulesForCalculationOfInventoryImpairmentProvision.Priority AS Priority,
	|	RulesForCalculationOfInventoryImpairmentProvision.LocalAccounting AS LocalAccounting,
	|	(CASE
	|		WHEN &CompanyManagementAccounting
	|			THEN RulesForCalculationOfInventoryImpairmentProvision.ManagementAccounting
	|		ELSE FALSE END) AS ManagementAccounting,
	|	RulesForCalculationOfInventoryImpairmentProvision.StorageOfDataCompositionSettings AS DataCompositionSettings
	|INTO CurrentRules
	|FROM
	|	Catalog.RulesForCalculationOfInventoryImpairmentProvision AS RulesForCalculationOfInventoryImpairmentProvision
	|WHERE
	|	NOT RulesForCalculationOfInventoryImpairmentProvision.DeletionMark
	|	AND CASE
	|			WHEN RulesForCalculationOfInventoryImpairmentProvision.ValidOnDate = DATETIME(1, 1, 1)
	|				THEN TRUE
	|			ELSE RulesForCalculationOfInventoryImpairmentProvision.ValidOnDate <= ENDOFPERIOD(&ReportPeriod, MONTH)
	|		END
	|	AND CASE
	|			WHEN RulesForCalculationOfInventoryImpairmentProvision.ValidToDate = DATETIME(1, 1, 1)
	|				THEN TRUE
	|			ELSE RulesForCalculationOfInventoryImpairmentProvision.ValidToDate >= BEGINOFPERIOD(&ReportPeriod, MONTH)
	|		END
	|	AND CASE
	|			WHEN &Organization = VALUE(Catalog.Companies.EmptyRef)
	|				THEN TRUE
	|			ELSE RulesForCalculationOfInventoryImpairmentProvision.Owner = &Organization
	|		END
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CurrentRules.Organization AS Organization,
	|	CurrentRules.Priority AS Priority,
	|	TRUE AS LocalAccounting,
	|	FALSE AS ManagementAccounting,
	|	CurrentRules.Rule AS Rule,
	|	CurrentRules.DataCompositionSettings AS DataCompositionSettings
	|FROM
	|	CurrentRules AS CurrentRules
	|WHERE
	|	CurrentRules.LocalAccounting
	|
	|UNION ALL
	|
	|SELECT
	|	CurrentRules.Organization AS Organization,
	|	CurrentRules.Priority AS Priority,
	|	FALSE AS LocalAccounting,
	|	TRUE AS ManagementAccounting,
	|	CurrentRules.Rule AS Rule,
	|	CurrentRules.DataCompositionSettings AS DataCompositionSettings
	|FROM
	|	CurrentRules AS CurrentRules
	|WHERE
	|	CurrentRules.ManagementAccounting";
	
	Return QueryText
	
EndFunction

Function RequestTextForRuleGroups()
	
	QueryText = 
	"SELECT ALLOWED
	|	RulesForCalculationOfInventoryImpairmentProvision.Ref AS Rule,
	|	RulesForCalculationOfInventoryImpairmentProvision.Owner AS Organization,
	|	RulesForCalculationOfInventoryImpairmentProvision.Priority AS Priority,
	|	RulesForCalculationOfInventoryImpairmentProvision.LocalAccounting AS LocalAccounting,
	|	(CASE
	|		WHEN &CompanyManagementAccounting
	|			THEN RulesForCalculationOfInventoryImpairmentProvision.ManagementAccounting
	|		ELSE FALSE END) AS ManagementAccounting,
	|	RulesForCalculationOfInventoryImpairmentProvision.StorageOfDataCompositionSettings AS DataCompositionSettings
	|INTO CurrentRules
	|FROM
	|	Catalog.RulesForCalculationOfInventoryImpairmentProvision AS RulesForCalculationOfInventoryImpairmentProvision
	|WHERE
	|	NOT RulesForCalculationOfInventoryImpairmentProvision.DeletionMark
	|	AND CASE
	|			WHEN RulesForCalculationOfInventoryImpairmentProvision.ValidOnDate = DATETIME(1, 1, 1)
	|				THEN TRUE
	|			ELSE RulesForCalculationOfInventoryImpairmentProvision.ValidOnDate <= ENDOFPERIOD(&ReportPeriod, MONTH)
	|		END
	|	AND CASE
	|			WHEN RulesForCalculationOfInventoryImpairmentProvision.ValidToDate = DATETIME(1, 1, 1)
	|				THEN TRUE
	|			ELSE RulesForCalculationOfInventoryImpairmentProvision.ValidToDate >= BEGINOFPERIOD(&ReportPeriod, MONTH)
	|		END
	|	AND CASE
	|			WHEN &Organization = VALUE(Catalog.Companies.EmptyRef)
	|				THEN TRUE
	|			ELSE RulesForCalculationOfInventoryImpairmentProvision.Owner = &Organization
	|		END
	|
	|INDEX BY
	|	Organization,
	|	Priority,
	|	LocalAccounting,
	|	ManagementAccounting
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CurrentRules.Organization AS Organization,
	|	CurrentRules.Priority AS Priority,
	|	TRUE AS LocalAccounting
	|INTO SetsOfPropsWithMultipleRules
	|FROM
	|	CurrentRules AS CurrentRules
	|WHERE
	|	CurrentRules.LocalAccounting
	|
	|GROUP BY
	|	CurrentRules.Organization,
	|	CurrentRules.Priority
	|
	|HAVING
	|	COUNT(DISTINCT CurrentRules.Rule) > 1
	|
	|UNION ALL
	|
	|SELECT
	|	CurrentRules.Organization,
	|	CurrentRules.Priority,
	|	FALSE
	|FROM
	|	CurrentRules AS CurrentRules
	|WHERE
	|	CurrentRules.ManagementAccounting
	|
	|GROUP BY
	|	CurrentRules.Organization,
	|	CurrentRules.Priority
	|
	|HAVING
	|	COUNT(DISTINCT CurrentRules.Rule) > 1
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetsOfPropsWithMultipleRules.Organization AS Organization,
	|	SetsOfPropsWithMultipleRules.Priority AS Priority,
	|	SetsOfPropsWithMultipleRules.LocalAccounting AS LocalAccounting,
	|	RECORDAUTONUMBER() AS SetID
	|INTO SetsWithIDs
	|FROM
	|	SetsOfPropsWithMultipleRules AS SetsOfPropsWithMultipleRules
	|
	|INDEX BY
	|	Organization,
	|	Priority,
	|	LocalAccounting
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetsWithIDs.SetID AS SetID,
	|	SetsWithIDs.Organization AS Organization,
	|	SetsWithIDs.Priority AS Priority,
	|	SetsWithIDs.LocalAccounting AS LocalAccounting,
	|	NOT SetsWithIDs.LocalAccounting AS ManagementAccounting,
	|	CurrentRules.Rule AS Rule,
	|	CurrentRules.DataCompositionSettings AS DataCompositionSettings
	|FROM
	|	CurrentRules AS CurrentRules
	|		INNER JOIN SetsWithIDs AS SetsWithIDs
	|		ON CurrentRules.Organization = SetsWithIDs.Organization
	|			AND CurrentRules.Priority = SetsWithIDs.Priority
	|			AND (CASE
	|				WHEN SetsWithIDs.LocalAccounting
	|					THEN CurrentRules.LocalAccounting
	|				ELSE CurrentRules.ManagementAccounting
	|			END)
	|TOTALS
	|	MAX(Organization),
	|	MAX(Priority),
	|	MAX(LocalAccounting)
	|BY
	|	SetID";
	
	Return QueryText
				
EndFunction

Function RequestTextCombinedByRuleGroup()
	
	// The fields of the final selection must match the fields in:
	// - Catalog.Rules for the formation of reserves and the devaluation of reserves.The text of the request to visit the up-to-date table()
	QueryText = 
	"SELECT
	|	BalanceTable.Period AS Period,
	|	BalanceTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	BalanceTable.AccountingSection AS AccountingSection,
	|	BalanceTable.Warehouse AS Warehouse,
	|	BalanceTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	BalanceTable.InventoryType AS InventoryType,
	|	BalanceTable.Organization AS Organization,
	|	BalanceTable.Lot AS Lot,
	|	BalanceTable.LotVendorAttributes AS LotVendorAttributes,
	|	BalanceTable.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	BalanceTable.VATActivityType AS VATActivityType,
	|	ISNULL(BalanceTable.AccountingDimensionByPartners, VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef)) AS AccountingDimensionByPartners,
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
	|INTO MergingRemainderTables
	|FROM
	|	BalanceTable AS BalanceTable
	|
	|INDEX BY
	|	FinancialAccountingDimension,
	|	LotVendorAttributes,
	|	Lot,
	|	VATActivityType,
	|	AccountingDimensionByPartners,
	|	InventoryOwnerAttribute,
	|	ItemsLocationAttributes,
	|	AccountingSection,
	|	InventoryType,
	|	Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MergingRemainderTables.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	MergingRemainderTables.AccountingSection AS AccountingSection,
	|	MergingRemainderTables.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	MergingRemainderTables.InventoryType AS InventoryType,
	|	MergingRemainderTables.Organization AS Organization,
	|	MergingRemainderTables.Lot AS Lot,
	|	MergingRemainderTables.LotVendorAttributes AS LotVendorAttributes,
	|	MergingRemainderTables.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	MergingRemainderTables.VATActivityType AS VATActivityType,
	|	ISNULL(MergingRemainderTables.AccountingDimensionByPartners, VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef)) AS AccountingDimensionByPartners
	|INTO RecordsWithMultipleRules
	|FROM
	|	MergingRemainderTables AS MergingRemainderTables
	|
	|GROUP BY
	|	MergingRemainderTables.AccountingSection,
	|	MergingRemainderTables.ItemsLocationAttributes,
	|	MergingRemainderTables.InventoryOwnerAttribute,
	|	MergingRemainderTables.InventoryType,
	|	MergingRemainderTables.FinancialAccountingDimension,
	|	MergingRemainderTables.LotVendorAttributes,
	|	MergingRemainderTables.VATActivityType,
	|	MergingRemainderTables.Lot,
	|	MergingRemainderTables.AccountingDimensionByPartners,
	|	MergingRemainderTables.Organization,
	|	MergingRemainderTables.LocalAccounting
	|
	|HAVING
	|	COUNT(DISTINCT MergingRemainderTables.Rule) > 1
	|
	|INDEX BY
	|	LotVendorAttributes,
	|	Organization,
	|	Lot,
	|	FinancialAccountingDimension,
	|	AccountingSection,
	|	InventoryOwnerAttribute,
	|	VATActivityType,
	|	InventoryType,
	|	AccountingDimensionByPartners,
	|	ItemsLocationAttributes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MergingRemainderTables.Period AS Period,
	|	MergingRemainderTables.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	MergingRemainderTables.AccountingSection AS AccountingSection,
	|	MergingRemainderTables.Warehouse AS Warehouse,
	|	MergingRemainderTables.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	MergingRemainderTables.InventoryType AS InventoryType,
	|	MergingRemainderTables.Organization AS Organization,
	|	MergingRemainderTables.Lot AS Lot,
	|	MergingRemainderTables.LotVendorAttributes AS LotVendorAttributes,
	|	MergingRemainderTables.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	MergingRemainderTables.VATActivityType AS VATActivityType,
	|	MergingRemainderTables.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	MergingRemainderTables.Rule AS Rule,
	|	MergingRemainderTables.Priority AS Priority,
	|	MergingRemainderTables.PriceKind AS PriceKind,
	|	MergingRemainderTables.LocalAccounting AS LocalAccounting,
	|	MergingRemainderTables.BusinessOperation AS BusinessOperation,
	|	MergingRemainderTables.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	MergingRemainderTables.CalculationOfCost AS CalculationOfCost,
	|	MergingRemainderTables.ProvisionForImpairmentLocal AS ProvisionForImpairmentLocal,
	|	MergingRemainderTables.ProvisionForImpairmentMan AS ProvisionForImpairmentMan,
	|	MergingRemainderTables.ProvisionForImpairmentOfLocalRevenue AS ProvisionForImpairmentOfLocalRevenue,
	|	MergingRemainderTables.ProvisionForImpairmentOfManRevenue AS ProvisionForImpairmentOfManRevenue,
	|	MergingRemainderTables.PriceIsIndicated AS PriceIsIndicated,
	|	MergingRemainderTables.CountBalance AS CountBalance,
	|	MergingRemainderTables.CostLocal AS CostLocal,
	|	MergingRemainderTables.ManagementCost AS ManagementCost,
	|	MergingRemainderTables.NetSaleValueOfLocal AS NetSaleValueOfLocal,
	|	MergingRemainderTables.NetSellingValueOfMan AS NetSellingValueOfMan,
	|	MergingRemainderTables.RecordType AS RecordType
	|INTO IntersectingRemnants
	|FROM
	|	MergingRemainderTables AS MergingRemainderTables
	|		INNER JOIN RecordsWithMultipleRules AS RecordsWithMultipleRules
	|		ON MergingRemainderTables.ItemsLocationAttributes = RecordsWithMultipleRules.ItemsLocationAttributes
	|			AND MergingRemainderTables.AccountingSection = RecordsWithMultipleRules.AccountingSection
	|			AND MergingRemainderTables.InventoryOwnerAttribute = RecordsWithMultipleRules.InventoryOwnerAttribute
	|			AND MergingRemainderTables.InventoryType = RecordsWithMultipleRules.InventoryType
	|			AND MergingRemainderTables.Organization = RecordsWithMultipleRules.Organization
	|			AND MergingRemainderTables.Lot = RecordsWithMultipleRules.Lot
	|			AND MergingRemainderTables.LotVendorAttributes = RecordsWithMultipleRules.LotVendorAttributes
	|			AND MergingRemainderTables.FinancialAccountingDimension = RecordsWithMultipleRules.FinancialAccountingDimension
	|			AND MergingRemainderTables.VATActivityType = RecordsWithMultipleRules.VATActivityType
	|			AND MergingRemainderTables.AccountingDimensionByPartners = RecordsWithMultipleRules.AccountingDimensionByPartners
	|";
	
	Return QueryText
				
EndFunction

Function QueryTextOfEmptySummaryTable()
	
	QueryText = 
	"SELECT
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ItemsLocationAttributes,
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) AS AccountingSection,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS InventoryOwnerAttribute,
	|	VALUE(Enum.InventoryTypes.EmptyRef) AS InventoryType,
	|	VALUE(Catalog.Companies.EmptyRef) AS Organization,
	|	UNDEFINED AS Lot,
	|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS LotVendorAttributes,
	|	UNDEFINED AS FinancialAccountingDimension,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATActivityType,
	|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) AS AccountingDimensionByPartners,
	|	VALUE(Catalog.RulesForCalculationOfInventoryImpairmentProvision.EmptyRef) AS Rule,
	|	0 AS Priority,
	|	VALUE(Catalog.TypesOfPrices.EmptyRef) AS PriceKind,
	|	FALSE AS LocalAccounting
	|INTO TemporaryTableOfBalances
	|WHERE
	|	FALSE";
	
	Return QueryText
				
EndFunction

#EndRegion

#EndIf