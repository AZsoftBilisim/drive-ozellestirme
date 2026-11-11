
#Region Public

// Updates statistics for items sold together
//
Procedure UpdateDataOnProductsSoldJointly() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.UpdateItemsSoldTogether);
	
	SetPrivilegedMode(True);
	
	UpdateRegisterEntries(
		Enums.AnalysisOptionsForItemsSoldTogether.Wholesale,
		SearchForAssociations(DataSourceForWholesaleTradeAnalysis()));
	
	UpdateRegisterEntries(
		Enums.AnalysisOptionsForItemsSoldTogether.RetailSale,
		SearchForAssociations(DataSourceForRetailAnalysis()));
	
EndProcedure

// Returns a table of statistics for the item sold together.
//
// Parameters:
//  Goods - ValueTable - table with columns:
//   * Products - CatalogRef.Products - Nomenclature.
//   * Characteristic - CatalogRef.ItemsCharacteristics - Characteristics of the item.
//  AnalysisOption - EnumRef.AnalysisOptionsForItemsSoldTogether - Analysis option.
//
// Returns:
//  ValueTable - table with columns:
//   * Products - CatalogRef.Products - Nomenclature.
//   * Characteristic - CatalogRef.ItemsCharacteristics - Characteristics of the item.
//   * Support - Number - Percent of cases.
//   * CaseCount - Number - Number of cases.
//
Function GetDataOnProductsSoldJointly(Goods, AnalysisOption) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Goods.Products   AS Products,
	|	Goods.Characteristic AS Characteristic
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductsSoldTogether.ProductsResult   AS Products,
	|	ProductsSoldTogether.ItemVariantConsequence AS Characteristic,
	|	ProductsSoldTogether.Support          AS Support,
	|	ProductsSoldTogether.CaseCount       AS CaseCount
	|FROM
	|	InformationRegister.ProductsSoldTogether AS ProductsSoldTogether
	|WHERE
	|	ProductsSoldTogether.AnalysisOption = &AnalysisOption
	|	AND (ProductsSoldTogether.ProductsPrerequisite, ProductsSoldTogether.ItemVariantPrerequisite) IN
	|			(SELECT
	|				Goods.Products,
	|				Goods.Characteristic
	|			FROM
	|				Goods AS Goods)";
	
	Query.SetParameter("Goods", Goods);
	Query.SetParameter("AnalysisOption", AnalysisOption);
	
	Result = Query.Execute().Unload();
	Return Result;
	
EndFunction

#EndRegion

#Region Internal

// Adds a request to the request package to get the data needed to fill in the indication of the availability of items 
// sold jointly when processing rows in the table part.
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure CompleteQueryTextToGetDataOnItemSoldJointly(StructureOfActions, QueryDetails, CachedValues) Export
	
	AnalysisOption = Undefined;
	
	If BatchProcessingOfTablePartServer.YouNeedToPerformAction(
			"FillInFlagForWhetherThereIsProductSoldJointly",
			StructureOfActions,
			CachedValues,
			AnalysisOption) Then
				
		QueryText = "
		|SELECT
		|	Goods.IdOfTTRow AS IdOfTTRow,
		|	TRUE IN
		|		(SELECT TOP 1
		|			TRUE
		|		FROM
		|			InformationRegister.ProductsSoldTogether AS ProductsSoldTogether
		|		WHERE
		|			ProductsSoldTogether.ProductsPrerequisite = Goods.Products
		|			AND ProductsSoldTogether.AnalysisOption = &AnalysisOption
		|			AND ProductsSoldTogether.ItemVariantPrerequisite = Goods.Characteristic) AS ItemIsSoldJointly
		|FROM
		|	TTDataSource AS Goods";
		
		QueryDetails.QueriesTexts.Add(QueryText, "ProductsSoldTogether");
		QueryDetails.QueryOptions.Insert("AnalysisOption", AnalysisOption);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function DataSourceForWholesaleTradeAnalysis()
	
	FrequencyForInventoryAnalysis = Constants.FrequencyForInventoryAnalysis.Get();
	NumberOfPeriodsForItemsSoldTogetherAnalisys = Constants.NumberOfPeriodsForItemsSoldTogetherAnalisys.Get();
	
	StartDate    = TMCommonUseClientServer.CalculatePeriodEndDate(CurrentSessionDate(), FrequencyForInventoryAnalysis, -NumberOfPeriodsForItemsSoldTogetherAnalisys) + 1;
	EndDate = EndOfDay(CurrentSessionDate());
	
	Query = New Query(
	"SELECT
	|	Goods.Ref         AS Document,
	|	Goods.Products   AS Products,
	|	Goods.Characteristic AS Characteristic
	|FROM
	|	Document.CustomerInvoice.Goods AS Goods
	|WHERE
	|	Goods.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|	AND Goods.Ref.Posted
	|	AND Goods.Ref.Date BETWEEN &StartDate AND &EndDate
	|");
	
	Query.Parameters.Insert("StartDate", StartDate);
	Query.Parameters.Insert("EndDate", EndDate);
	
	QueryResult = Query.Execute();
	
	Return QueryResult;
	
EndFunction

Function DataSourceForRetailAnalysis()
	
	FrequencyForInventoryAnalysis = Constants.FrequencyForInventoryAnalysis.Get();
	NumberOfPeriodsForItemsSoldTogetherAnalisys = Constants.NumberOfPeriodsForItemsSoldTogetherAnalisys.Get();
	
	StartDate    = TMCommonUseClientServer.CalculatePeriodEndDate(CurrentSessionDate(), FrequencyForInventoryAnalysis, -NumberOfPeriodsForItemsSoldTogetherAnalisys);
	EndDate = EndOfDay(CurrentSessionDate());
	
	Query = New Query(
	"SELECT
	|	Goods.Ref         AS Document,
	|	Goods.Products   AS Products,
	|	Goods.Characteristic AS Characteristic
	|FROM
	|	Document.CashRegisterReceipt.Goods AS Goods
	|WHERE
	|	Goods.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|	AND Goods.Ref.Posted
	|	AND Goods.Ref.Date BETWEEN &StartDate AND &EndDate
	|");
	
	Query.Parameters.Insert("StartDate", StartDate);
	Query.Parameters.Insert("EndDate", EndDate);
	
	QueryResult = Query.Execute();
	
	Return QueryResult;
	
EndFunction

Function SearchForAssociations(DataSource)
	
	Analysis = New DataAnalysis;
	Analysis.AnalysisType = Type("DataAnalysisAssociationRules");
	Analysis.DataSource = DataSource;
	
	Analysis.ColumnsSetting.Document.ColumnType       = DataAnalysisColumnTypeAssociationRules.Object;
	Analysis.ColumnsSetting.Products.ColumnType   = DataAnalysisColumnTypeAssociationRules.Item;
	Analysis.ColumnsSetting.Characteristic.ColumnType = DataAnalysisColumnTypeAssociationRules.Item;
	
	Analysis.Parameters.MinSupport.Value = Constants.MinimumRateOfCases.Get();
	Analysis.Parameters.MinImportance.Value     = Constants.MinimumSignificance.Get();
	Analysis.Parameters.MinConfidence.Value  = Constants.MinimumCredibility.Get();
	Analysis.Parameters.PruneRulesType.Value = AssociationRulesPruneType.Covered;
	
	AnalysisResult = Analysis.Execute();
	
	Return AnalysisResult;
	
EndFunction

Function UpdateRegisterEntries(AnalysisOption, AnalysisResult)
	
	Set = InformationRegisters.ProductsSoldTogether.CreateRecordSet();
	Set.Filter.AddedAutomatically.Value = True;
	Set.Filter.AddedAutomatically.Use = True;
	Set.Filter.AnalysisOption.Value = AnalysisOption;
	Set.Filter.AnalysisOption.Use = True;
	
	SetTable = Set.UnloadColumns();
	SetTable.Indexes.Add(
		"ProductsPrerequisite,
		|ItemVariantPrerequisite,
		|ProductsResult,
		|ItemVariantConsequence");
	
	For Each Rule In AnalysisResult.Rules Do
		
		If Rule.Antecedent.Count() = 1 Then
		
			For Each Antecedent In Rule.Antecedent Do
				
				For Each Consequent In Rule.Consequent Do
					
					Filter = New Structure;
					Filter.Insert("ProductsPrerequisite", Antecedent.Products.Value);
					Filter.Insert("ItemVariantPrerequisite", Antecedent.Characteristic.Value);
					Filter.Insert("ProductsResult", Consequent.Products.Value);
					Filter.Insert("ItemVariantConsequence", Consequent.Characteristic.Value);
					
					If SetTable.FindRows(Filter).Count() = 0 Then
					
						Record = SetTable.Add();
						
						Record.AnalysisOption            = AnalysisOption;
						Record.AddedAutomatically    = True;
						
						Record.ProductsPrerequisite   = Antecedent.Products.Value;
						Record.ItemVariantPrerequisite = Antecedent.Characteristic.Value;
						Record.ProductsResult     = Consequent.Products.Value;
						Record.ItemVariantConsequence   = Consequent.Characteristic.Value;
						
						Record.Support            = Rule.Support;
						Record.CaseCount         = Rule.CaseCount;
					
					EndIf;
					
				EndDo;
				
			EndDo;
		
		EndIf;
		
	EndDo;
	
	Set.Load(SetTable);
	Set.Write();
	
EndFunction

#EndRegion
