#Region Public

// Returns the structure of the details cache by budget type.
//
// Parameters:
//  ReportKind  - CatalogRef.BudgetProfiles - link to the report view.
//
// Returns:
//   Structure - Cache Of Details For Budget View Elements:
//    *CacheOfAdditionalBankingDetails - See the description of the Financial Reporting Server.Additional Session caseshreferences
//    *AttributeCache    - See the description of the Financial Reporting Server.Additional Session caseshreferences
//
Function CacheOfBudgetItemDetails(ReportKind) Export
	
	CacheAdditionalBankingDetails = FinancialReportingServer.CacheAdditionalDetails(ReportKind);
	AttributeCache   = CacheOfDetailsForBudgetViewElements(ReportKind);
	CacheOfBudgetItemDetails = New Structure;
	CacheOfBudgetItemDetails.Insert("CacheOfAdditionalBankingDetails", CacheAdditionalBankingDetails);
	CacheOfBudgetItemDetails.Insert("AttributeCache", AttributeCache);
	
	Return CacheOfBudgetItemDetails;
	
EndFunction

// The function returns parameters for displaying the budget view.
// 
// Parameters:
//  BudgetProfile  - CatalogRef.BudgetProfiles - the type of budget that parameters are defined for.
//  GenerationMode  - EnumRef.ModesOfBudgetReportGeneration - formation option.
// Returns:
// 	Structure - LongDesc:
// * ColumnStructureOfDataTable - See ColumnsOfDataTable_
// * InputListDescriptionStructure - Structure - Contains:
// 		** Dimensions - Array -
// 		** ColumnSettings - Structure -
// 		** InputSettings - See ListCellInputSettings
// * StructureOfReportDescription - See DescriptionOfReport
// * OutputTree - See NewOutputTree
// * DataDCS - Structure - Contains:
// 		** DCSSummary - DataCompositionSchema -
// 		** DCSPlanningData - DataCompositionSchema -
// 		** DCSDocumentData - DataCompositionSchema -
// 		** DCSPreliminaryCalculation - DataCompositionSchema -
// 		** DCSActualDataPrivileged - DataCompositionSchema -
// 		** DCSPlanningDataPrivileged - DataCompositionSchema -
// 		** Parameters - Structure -
//
Function GetParametersForDisplayingBudgetView(BudgetProfile, GenerationMode) Export
	
	If Not ValueIsFilled(BudgetProfile) Then
		Return Undefined;
	EndIf;
	
	// Generating the report columns.
	ColumnStructureOfDataTable = ColumnsOfDataTable_(BudgetProfile);
	
	// Generating data sources and cell structure.
	StructureOfReportDescription = DescriptionOfReport(BudgetProfile, ColumnStructureOfDataTable, GenerationMode);
	
	// We generate SKD based on sources.
	DataDCS = GetDCSFromSourceDescriptions(BudgetProfile,
			StructureOfReportDescription,
			ColumnStructureOfDataTable,
			GenerationMode);
	
	// We get a tree of groupings for the report output.
	OutputTree = OutputTree(BudgetProfile, StructureOfReportDescription.CellStructure, StructureOfReportDescription.CellParameters);
	
	// result.
	ResultingStructure = New Structure;
	ResultingStructure.Insert("ColumnStructureOfDataTable", ColumnStructureOfDataTable);
	ResultingStructure.Insert("StructureOfReportDescription", StructureOfReportDescription);
	ResultingStructure.Insert("DataDCS", DataDCS);
	ResultingStructure.Insert("OutputTree", OutputTree);
	ResultingStructure.Insert("DataCache", New Structure);
	
	If GenerationMode = Enums.ModesOfBudgetReportGeneration.Document
	 Or GenerationMode = Enums.ModesOfBudgetReportGeneration.PrintBudget Then
		
		InputListDescriptionStructure = InputListParametersByCellRows(BudgetProfile,
				ColumnStructureOfDataTable,
				StructureOfReportDescription,
				OutputTree);
		
		ResultingStructure.Insert("InputListDescriptionStructure", InputListDescriptionStructure);
		
	EndIf;
	
	Return ResultingStructure;
	
EndFunction

// The function returns a tree of elements of the budget type
// 
//
// Parameters:
//  BudgetProfile - CatalogRef.BudgetProfiles - the budget categories for which you want to build a tree.
//  DisplayComplexTableItems  - Boolean - indicates that you want to display elements that are subordinate to the "cell settings" element.
//
// Returns:
//   ValueTree - Contains mainly the fields of the Catalog "Elements of Financial Reports":
//   	* ReportItem - CatalogRef.FinancialReportItems - link to the report element.
//   	* ItemKind - EnumRef.FinancialReportItemKinds - Type of element.
//   	* AddressOfItemStructure - String - 
//   	* Comment - String -
//   	* ReverseSign - Boolean - 
//   	* HasSettings - Boolean - 
//   	* Parent - CatalogRef.FinancialReportItems -
//   	* ItemIndicatorDimensionType - String - 
//   	* Description - String - 
//   	* DimensionValue - Characteristic.BudgetFlowItemDimensions -
//   	* ValueBudgetItem - CatalogRef.BudgetFlowItems - 
//   	* NameForPrinting - String -
//   	* DimensionType - EnumRef.TypesOfBudgetReportDimensions -
//   	* DisplayWithParent - Boolean -
//   	* AdditionalFieldPresentation - String -
//   	* PresentationIsForPrintingOnly - String -
//   	* PrivilegedMode - Boolean -
//   	* SourceAllElements - Boolean -
//
Function BudgetItemTree(BudgetProfile, DisplayComplexTableItems = False) Export
	
	SetPrivilegedMode(True);
	
	If DisplayComplexTableItems Then
		TypeOfCacheElement = Enums.BudgetCacheKinds["ItemTreeWithAdditionalItems"];
	Else
		TypeOfCacheElement = Enums.BudgetCacheKinds["ItemTreeWithoutAdditionalItems"];
	EndIf;
	
	CacheValue = InformationRegisters.CacheOfAuxiliaryBudgetProfileData.GetCacheValue(BudgetProfile, TypeOfCacheElement);
	If CacheValue <> Undefined Then
		SetPrivilegedMode(False);
		Return CacheValue;
	EndIf;
	
	FinReports = FinancialReportingServer;
	TreeDiagram = Catalogs.BudgetProfiles.GetTemplate("ReportItemTree");
	TreeComposer = FinReports.SchemaComposer(TreeDiagram);
	FinReports.SetLayoutParameter(TreeComposer, "DisplayComplexTableItems", DisplayComplexTableItems);
	FinReports.SetLayoutParameter(TreeComposer, "ReportKind", BudgetProfile);
	FinReports.SetLayoutParameter(TreeComposer, "AttributeCache", FinReports.CacheAdditionalDetails(BudgetProfile));
	FinReports.SetLayoutParameter(TreeComposer, "CacheOfAdditionalFields", FinReports.CacheAdditionalElementFields(BudgetProfile));
	
	Result = FinReports.UploadDCSResults(TreeDiagram, TreeComposer,,True);
	
	InformationRegisters.CacheOfAuxiliaryBudgetProfileData.SetCacheValue(BudgetProfile, TypeOfCacheElement, Result);
	
	SetPrivilegedMode(False);
	
	Return Result;
	
EndFunction

// Returns the parameters of these types of budget
//
// Parameters:
// 	BudgetProfile - CatalogRef.BudgetProfiles - the type of budget that data parameters are defined for.
// 
// Returns:
//	Structure - data parameters for the budget type, keys:
//		* Periodicity_ - Array - array of periods to which the data table should be decrypted
//		* Dimensions - Array of String - array of used dimensions
//		* DimensionKinds - Array of ChartOfCharacteristicTypesRef.ItemAttributesOfFinancialReports -
Function ColumnsOfDataTable_(BudgetProfile) Export
	
	SetPrivilegedMode(True);
	
	TypeOfCacheElement = Enums.BudgetCacheKinds.ColumnStructure1;
	Value = InformationRegisters.CacheOfAuxiliaryBudgetProfileData.GetCacheValue(BudgetProfile, TypeOfCacheElement);
	If Value <> Undefined Then
		SetPrivilegedMode(False);
		Return Value;
	EndIf;
	
	BudgetItemTree = BudgetItemTree(BudgetProfile, True);
	AttributeCache = FinancialReportingServer.CacheAdditionalDetails(BudgetProfile);
	AddAttributes = ChartsOfCharacteristicTypes.ItemAttributesOfFinancialReports;
	
	ResultingStructure = New Structure;
	ResultingStructure.Insert("Periodicity_", New Array);
	ResultingStructure.Insert("Dimensions", New Array);
	ResultingStructure.Insert("DimensionKinds", New Array);
	
	ItemKind = Enums.FinancialReportItemKinds.Dimension;
	PickedRows = BudgetItemTree.Rows.FindRows(New Structure("ItemKind", ItemKind), True);
	
	DimensionsTypes = Enums.TypesOfBudgetReportDimensions;
	
	For Each MeasurementString_ In PickedRows Do
		
		DimensionType = FinancialReportingServer.ValueOfAdditionalProps(
			MeasurementString_.ReportItem, 
			AddAttributes.DimensionType,
			AttributeCache);
		
		If DimensionType = DimensionsTypes.Period Then
			Periodicity = FinancialReportingServer.ValueOfAdditionalProps(
				MeasurementString_.ReportItem, 
				AddAttributes.Periodicity,
				AttributeCache);
			
			If ResultingStructure.Periodicity_.Find(Periodicity) = Undefined Then
				ResultingStructure.Periodicity_.Add(Periodicity);
			EndIf;
			
		ElsIf DimensionType = DimensionsTypes.RegisterDimension Then
			DimensionName = FinancialReportingServer.ValueOfAdditionalProps(
				MeasurementString_.ReportItem, 
				AddAttributes.DimensionName,
				AttributeCache);
			
			If ResultingStructure.Dimensions.Find(DimensionName) = Undefined Then
				ResultingStructure.Dimensions.Add(DimensionName);
			EndIf;
			
		ElsIf DimensionType = DimensionsTypes.Dimension Then
			Dimension = FinancialReportingServer.ValueOfAdditionalProps(
				MeasurementString_.ReportItem, 
				AddAttributes.DimensionKind,
				AttributeCache);
			
			If ResultingStructure.DimensionKinds.Find(Dimension) = Undefined Then
				ResultingStructure.DimensionKinds.Add(Dimension);
			EndIf;
			
		ElsIf DimensionType = DimensionsTypes.FixedDimension Then
			Dimension = FinancialReportingServer.ValueOfAdditionalProps(
				MeasurementString_.ReportItem, 
				AddAttributes.DimensionKind,
				AttributeCache);
			
			If ResultingStructure.DimensionKinds.Find(Dimension) = Undefined Then
				ResultingStructure.DimensionKinds.Add(Dimension);
			EndIf;
			
		ElsIf DimensionType = DimensionsTypes.Scenario Then
			
			If ResultingStructure.Dimensions.Find("Scenario") = Undefined Then
				ResultingStructure.Dimensions.Add("Scenario");
			EndIf;
			
		ElsIf DimensionType = DimensionsTypes.Organization Then
			
			If ResultingStructure.Dimensions.Find("Organization") = Undefined Then
				ResultingStructure.Dimensions.Add("Organization");
			EndIf;
			
		ElsIf DimensionType = DimensionsTypes.Department Then
			
			If ResultingStructure.Dimensions.Find("Department") = Undefined Then
				ResultingStructure.Dimensions.Add("Department");
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	FinancialReportItems.Ref
	|FROM
	|	Catalog.FinancialReportItems.ItemKindAttributes AS FinancialReportItemsItemKindAttributes
	|		INNER JOIN Catalog.FinancialReportItems AS FinancialReportItems
	|		ON FinancialReportItemsItemKindAttributes.Ref = FinancialReportItems.Ref
	|			AND (FinancialReportItemsItemKindAttributes.Attribute = &TypeOfIndicators_)
	|			AND (FinancialReportItemsItemKindAttributes.Value IN (&DisplayedIndicators))
	|			AND (FinancialReportItems.Owner = &Owner)";
	
	Query.SetParameter("Owner", BudgetProfile);
	Query.SetParameter("TypeOfIndicators_", ChartsOfCharacteristicTypes.ItemAttributesOfFinancialReports.DisplayedIndicators);
	
	DisplayedIndicators = New ValueList;
	DisplayedIndicators.Add(Enums.TypesOfDisplayedBudgetReportIndicators.Count);
	DisplayedIndicators.Add(Enums.TypesOfDisplayedBudgetReportIndicators.QuantityAndAmount);
	
	Query.SetParameter("DisplayedIndicators", DisplayedIndicators);
	
	ThereIsQuantity = Not Query.Execute().IsEmpty();
	
	// the currency is always used for recalculations
	If ResultingStructure.Dimensions.Find("Currency") = Undefined Then
		ResultingStructure.Dimensions.Add("Currency");
	EndIf;
	
	If ThereIsQuantity Then
		If ResultingStructure.Dimensions.Find("UnitOfMeasure") = Undefined Then
			ResultingStructure.Dimensions.Add("UnitOfMeasure");
		EndIf;
	EndIf;
	
	InformationRegisters.CacheOfAuxiliaryBudgetProfileData.SetCacheValue(BudgetProfile, TypeOfCacheElement, ResultingStructure);
	
	SetPrivilegedMode(False);
	
	Return ResultingStructure;
	
EndFunction

// LongDesc
// 
// Parameters:
// 	BudgetProfile - CatalogRef.BudgetProfiles -
// 	ColumnStructure1 - See ColumnsOfDataTable_
// Returns:
// 	Structure - Contains:
// 		* BudgetProfile - CatalogRef.BudgetProfiles -
// 		* ColumnStructure1 - See ColumnsOfDataTable_
// 		* BudgetItemTree - See BudgetReportingCacheCalculationServer.BudgetItemTree
// 		* SettingsTable - ValueTable, Undefined - 
// 			Table of values. Used to refine the source properties of a complex table.
// 			It is uncertain. If you need to check the report factapostructure = False, then the value = It is uncertain.
// 		* CacheOfBudgetTableSettings - Map -
//
Function NewDescriptionOfStructureOfBudgetElements(BudgetProfile, ColumnStructure1)
	
	DescriptionOfStructureOfBudgetElements = New Structure;
	DescriptionOfStructureOfBudgetElements.Insert("BudgetProfile", BudgetProfile);
	DescriptionOfStructureOfBudgetElements.Insert("ColumnStructure1", ColumnStructure1);
	DescriptionOfStructureOfBudgetElements.Insert("BudgetItemTree", BudgetItemTree(BudgetProfile, True));
	DescriptionOfStructureOfBudgetElements.Insert("SettingsTable", Undefined);
	DescriptionOfStructureOfBudgetElements.Insert("CacheOfBudgetTableSettings", New Map);
	
	Return DescriptionOfStructureOfBudgetElements
	
EndFunction

// Returns a description of budget sources in the form of an array
//
// Parameters:
//  BudgetProfile  - CatalogRef.BudgetProfiles - type of budget to get a description of sources for
//  ColumnStructure1  - See ColumnsOfDataTable_
//  GenerationMode  - EnumRef.ModesOfBudgetReportGeneration - assign sources (document, report,
//  						fill-in, etc.).
//  RecursiveRetrievalOfSourcesForArticles - Boolean - If True, all article operands will be included recursively in the source data
//  						(only for checking the use
//  						of the actual data boundary). The default value is False.
//
// Returns:
//   Array of See NewSource - description of sources in the form of an array.
//
Function GetDescriptionOfDataSources(BudgetProfile, ColumnStructure1, GenerationMode, RecursiveRetrievalOfSourcesForArticles = False) Export
	
	Sources = New Array; // Array of See NewSource -
	AttributeCache = FinancialReportingServer.CacheAdditionalDetails(BudgetProfile);
	
	CacheStructure = New Structure;
	CacheStructure.Insert("CacheOfAdditionalBankingDetails", AttributeCache);
	CacheStructure.Insert("AttributeCache", CacheOfDetailsForBudgetViewElements(BudgetProfile));
	
	ParametersForFillingSources = New Structure;
	ParametersForFillingSources.Insert("RecursiveRetrievalOfSourcesForArticles", RecursiveRetrievalOfSourcesForArticles);
	ParametersForFillingSources.Insert("CheckWhetherFactIsNecessaryBasedOnReportStructure", False);
	ParametersForFillingSources.Insert("GenerationMode", GenerationMode);
	
	DescriptionOfStructureOfBudgetElements = NewDescriptionOfStructureOfBudgetElements(BudgetProfile, ColumnStructure1);
	
	If Not Common.ObjectAttributeValue(BudgetProfile, "UseToEnterPlan")
		And ColumnStructure1.Dimensions.Find("Scenario") <> Undefined Then
		// For the Report generation mode, the scenario dimension can be output to the report structure.
		// Then the need to get the actual data depends on the selected scenarios that are displayed in the report settings.
		ParametersForFillingSources.CheckWhetherFactIsNecessaryBasedOnReportStructure = True;
		DescriptionOfStructureOfBudgetElements.SettingsTable = ElementsForConfiguringBudgetViewCells(BudgetProfile);
	EndIf;
	
	ItemsKinds = Enums.FinancialReportItemKinds.TypesOfDataSourceElements();
	For Each ItemKind In ItemsKinds Do
		FillSourcesByElementType(Sources,
			CacheStructure,
			DescriptionOfStructureOfBudgetElements,
			ItemKind,
			ParametersForFillingSources);
	EndDo;
	
	TableForCheckingStoredRules = New ValueTable;
	TableForCheckingStoredRules.Columns.Add("ItemIndicator", New TypeDescription("CatalogRef.BudgetFlowItems, CatalogRef.BudgetBalanceItems"));
	TableForCheckingStoredRules.Columns.Add("Id", Common.StringTypeDetails(150));
	
	For Each Source In Sources Do
		
		Source.Insert("AssumesActualData", 
			SourcePresumablyNeedsActualData(Source, GenerationMode, Catalogs.BudgetingScenarios.ActualData));
		Source.Insert("AssumesBudgetExecution", 
			SourcePresumablyNeedsActualData(Source, GenerationMode, Catalogs.BudgetingScenarios.BudgetFulfillment));
		
		If Not Source.SourceType = Enums.BudgetingDataSourceTypes.Balance Then
			Source.Insert("InfluencingArticlesAndFactualData", "");
			Source.Insert("AffectingItemsInvolvesBudgetExecution", "");
		Else
			Source.Insert("InfluencingArticlesAndFactualData",
				SourcePresumablyNeedsActualData(Source, GenerationMode, Catalogs.BudgetingScenarios.ActualData, True));
			Source.Insert("AffectingItemsInvolvesBudgetExecution", 
				SourcePresumablyNeedsActualData(Source, GenerationMode, Catalogs.BudgetingScenarios.BudgetFulfillment, True));
		EndIf;
			
		// These properties are used only to obtain properties assuming factually correct/Presupposes the fulfillment of the budget
		Source.Delete("GettingPlanForBudgetStructure");
		Source.Delete("GettingFactsAboutBudgetStructure");
		Source.Delete("GettingBudgetExecutionByBudgetStructure");
		Source.Delete("GettingScriptFromReportHeader");
		
		If Source.SourceType <> Enums.BudgetingDataSourceTypes.Turnovers
			And Source.SourceType <> Enums.BudgetingDataSourceTypes.Balance Then
			Continue;
		EndIf;
		
		If Source.AssumesActualData = "Assumed"
			Or Source.AssumesActualData = "DeterminedByReportSettings"
			Or Source.AssumesBudgetExecution = "Assumed"
			Or Source.AssumesBudgetExecution = "DeterminedByReportSettings" Then
			
			For Each Object In Source.Objects Do
				
				NewRow = TableForCheckingStoredRules.Add();
				NewRow.ItemIndicator = Object;
				NewRow.Id = Source.Id;
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
	Query = New Query;
	Query.Text =
	"SELECT
		|	Table.ItemIndicator,
		|	Table.Id
		|INTO CheckTable
		|FROM
		|	&CheckTable AS Table
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CheckTable.Id,
		|	ActualDataQueryRulesByBudgetFlowItems.CachingOfRuleResults AS ThereAreStoredRules,
		|	NOT ActualDataQueryRulesByBudgetFlowItems.CachingOfRuleResults AS ThereAreOnLineRules
		|INTO TableWithFlags
		|FROM
		|	CheckTable AS CheckTable
		|		LEFT JOIN Catalog.BudgetFlowItems AS BudgetFlowItems
		|		ON CheckTable.ItemIndicator = BudgetFlowItems.Ref
		|		LEFT JOIN Catalog.ActualDataQueryRulesByBudgetFlowItems AS ActualDataQueryRulesByBudgetFlowItems
		|		ON CheckTable.ItemIndicator = ActualDataQueryRulesByBudgetFlowItems.BudgetFlowItem
		|WHERE
		|	CheckTable.ItemIndicator REFS Catalog.BudgetFlowItems
		|	AND NOT BudgetFlowItems.Ref IS NULL
		|	AND NOT ActualDataQueryRulesByBudgetFlowItems.DeletionMark
		|
		|UNION ALL
		|
		|SELECT
		|	CheckTable.Id,
		|	ISNULL(RulesForObtainingFactsForRelatedArticles.CachingOfRuleResults, FALSE) AS ThereAreStoredRules,
		|	TRUE AS ThereAreOnLineRules
		|FROM
		|	CheckTable AS CheckTable
		|		LEFT JOIN Catalog.BudgetBalanceItems AS BudgetBalanceItems
		|		ON CheckTable.ItemIndicator = BudgetBalanceItems.Ref
		|		LEFT JOIN Catalog.RuleForCalculatingRelatedBudgetBalancesAndTurnovers AS CalculationsRules
		|			LEFT JOIN Catalog.ActualDataQueryRulesByBudgetFlowItems AS RulesForObtainingFactsForRelatedArticles
		|			ON CalculationsRules.Source = RulesForObtainingFactsForRelatedArticles.BudgetFlowItem
		|				AND (NOT RulesForObtainingFactsForRelatedArticles.DeletionMark)
		|		ON CheckTable.ItemIndicator = CalculationsRules.Receiver
		|			AND (NOT CalculationsRules.DeletionMark)
		|			AND (CalculationsRules.Status = VALUE(Enum.BudgetingRuleStatuses.Valid))
		|WHERE
		|	CheckTable.ItemIndicator REFS Catalog.BudgetBalanceItems
		|	AND NOT BudgetBalanceItems.Ref IS NULL
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TableWithFlags.Id,
		|	MAX(TableWithFlags.ThereAreStoredRules) AS ThereAreStoredRules,
		|	MAX(TableWithFlags.ThereAreOnLineRules) AS ThereAreOnLineRules
		|FROM
		|	TableWithFlags AS TableWithFlags
		|
		|GROUP BY
		|	TableWithFlags.Id";
	
	Query.SetParameter("CheckTable", TableForCheckingStoredRules);
	
	FlagsForStoringRules = Query.Execute().Unload();
	For Each Source In Sources Do
		If Source.AssumesActualData = "NotAssumed"
			And Source.AssumesBudgetExecution = "NotAssumed" Then
			Source.Insert("ThereAreStoredRules", False);
			Source.Insert("ThereAreOnLineRules", False);
			Continue;
		EndIf;
		StringOfFlags = FlagsForStoringRules.Find(Source.Id, "Id");
		If StringOfFlags = Undefined Then
			Source.Insert("ThereAreStoredRules", False);
			Source.Insert("ThereAreOnLineRules", True);
		Else
			Source.Insert("ThereAreStoredRules", StringOfFlags.ThereAreStoredRules);
			Source.Insert("ThereAreOnLineRules", StringOfFlags.ThereAreOnLineRules);
		EndIf;
	EndDo;
	
	Return Sources;
	
EndFunction

// Returns a description of budget sources in the form of an array
//
// Parameters:
//  BudgetProfile  - CatalogRef.BudgetProfiles - type of budget to get a description of sources for
//  ColumnStructure1  - Structure -
//  GenerationMode - EnumRef.ModesOfBudgetReportGeneration -
//
// Returns:
//   Array of See NewSourceOfGroupingPeriod - description of sources in the form of an array.
//
Function SourcesOfGroupingPeriods(BudgetProfile, ColumnStructure1, GenerationMode) Export
	
	Sources = New Array;
	AttributeCache = FinancialReportingServer.CacheAdditionalDetails(BudgetProfile);
	BudgetItemTree = BudgetItemTree(BudgetProfile, True);
	
	ItemsKinds = Enums.FinancialReportItemKinds.TypesOfSourceAndDimensionElements();
	For Each ItemKind In ItemsKinds Do
		FillInGroupingPeriodsByElementType(Sources, AttributeCache, BudgetItemTree, ColumnStructure1, ItemKind);
	EndDo;
	
	Return Sources;
	
EndFunction

#Region GettingStructureOfBudgetReportCells

// LongDesc
// 
// Parameters:
// 	BudgetProfile - CatalogRef.BudgetProfiles - LongDesc
// Returns:
// 	ValueTable - Contains:
// 		* Ref - CatalogRef.FinancialReportItems -
// 		* ItemKind - EnumRef.FinancialReportItemKinds -
//
Function GetBudgetViewTables(BudgetProfile) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
		|	FinancialReportItems.Ref,
		|	FinancialReportItems.ItemKind
		|FROM
		|	Catalog.FinancialReportItems AS FinancialReportItems
		|WHERE
		|	FinancialReportItems.Owner = &Owner
		|	AND FinancialReportItems.ItemKind IN(&ItemKind)";
		
	List = New ValueList;
	List.Add(Enums.FinancialReportItemKinds.TableIndicatorsInColumns);
	List.Add(Enums.FinancialReportItemKinds.TableIndicatorsInRows);
	List.Add(Enums.FinancialReportItemKinds.ComplexTable);
	
	Query.SetParameter("Owner", BudgetProfile);
	Query.SetParameter("ItemKind", List);
	
	Return Query.Execute().Unload();
	
EndFunction

Function GetFinalElementsOfTree(Item, All = False, Result = Undefined) Export
	
	If Result = Undefined Then
		If All Then
			Result = FiniteElementTree();
		Else
			Result = New Array;
		EndIf;
	EndIf;
	
	For Each TreeRow In Item.Rows Do
		If TreeRow.ItemKind = Enums.FinancialReportItemKinds.TableIndicatorsInColumns
			Or TreeRow.ItemKind = Enums.FinancialReportItemKinds.TableIndicatorsInRows
			Or TreeRow.ItemKind = Enums.FinancialReportItemKinds.ComplexTable
			Or TreeRow.ItemKind = Enums.FinancialReportItemKinds.ReportHeader
			Or TreeRow.ItemKind = Enums.FinancialReportItemKinds.EditedText
			Or TreeRow.ItemKind = Enums.FinancialReportItemKinds.UneditedText Then
			Continue;
		EndIf;
		If All Then
			NewRow = AddRowToFiniteElementTree(Result, TreeRow);
			GetFinalElementsOfTree(TreeRow, All, NewRow);
		Else
			If Not TreeRow.Rows.Count() Then
				Result.Add(TreeRow);
			EndIf;
			GetFinalElementsOfTree(TreeRow, All, Result);
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

Function PartOfFormulaWithTotalAndOperand(Formula, OperandName, BeginningOfFormula, EndOfFormula) Export
	Var LocalEndingOfFormula, LocalOriginOfFormula;
	
	NumberOfOccurrences = StrOccurrenceCount(Upper(Formula), Upper(OperandName));
	SearchString = Formula;
	BeginningOfFormula = 0; EndOfFormula = 0;
	
	For Cnt = 1 To NumberOfOccurrences Do
		PartsOfFormula = CalculatePartOfFormulaWithTotalAndOperand(SearchString, OperandName, LocalOriginOfFormula, LocalEndingOfFormula);
		BeginningOfFormula = EndOfFormula + LocalOriginOfFormula;
		EndOfFormula = EndOfFormula + LocalEndingOfFormula;
		If PartsOfFormula <> Undefined Then
			Return PartsOfFormula
		EndIf;
		SearchString = Mid(SearchString, LocalEndingOfFormula);
		EndOfFormula = EndOfFormula - 1;
	EndDo;
	
	Return Undefined;
	
EndFunction

Function EndOfFormula(Formula, EndOfFormula) Export
	
	Result = "";
	Cnt = EndOfFormula;
	While Cnt < StrLen(Formula) Do
		Char = Mid(Formula, Cnt, 1);
		If Char = ")" Then
			Break;
		EndIf;
		Result = Result + Char;
		Cnt = Cnt + 1;
	EndDo;
	
	EndOfFormula = Cnt;
	
	Return Result;
	
EndFunction

Function RowReplaceCaseInsensitive(Val String, Val SearchSubstring, Val ReplaceSubstring) Export
	
	SearchSubstring = String(SearchSubstring);
	If IsBlankString(SearchSubstring) Then
		Return String;
	EndIf;
	
	If StrLen(String) < StrLen(SearchSubstring) Then
		Return String;
	EndIf;
	
	SearchSubstring = Upper(SearchSubstring);
	SearchSubstringLength = StrLen(SearchSubstring);
	
	Result = "";
	PassedEntireLine = False;
	
	While Not PassedEntireLine Do
		If Upper(Left(String, SearchSubstringLength)) = SearchSubstring Then
			Result = Result + ReplaceSubstring;
			String = Mid(String, SearchSubstringLength + 1);
		Else
			Result = Result + Left(String, 1);
			String = Mid(String, 2);
		EndIf;
		PassedEntireLine = String = "";
	EndDo;
	
	Return Result;
	
EndFunction

Procedure AddTechnicalInformationToDateDifferenceFunction(Formula) Export
	
	PeriodVariables = BudgetReportingClientServer.VariablesOfBudgetingPeriods();
	
	Formula = RowReplaceCaseInsensitive(Formula, "DateDiff(", "DateDiff(PeriodParameters_1, ");
	Formula = RowReplaceCaseInsensitive(Formula, PeriodVariables.DataPeriodStart.Name, "BeginOfPeriod");
	Formula = RowReplaceCaseInsensitive(Formula, PeriodVariables.DataPeriodEnd.Name,  "EndOfPeriod");
	Formula = RowReplaceCaseInsensitive(Formula, PeriodVariables.ActualDataLimit.Name,   "ActualDataLimit");
	Formula = RowReplaceCaseInsensitive(Formula, PeriodVariables.PeriodOfGrouping.Name,   "PeriodOfGrouping");
	
EndProcedure

Function ColumnTypeOfCellStructure(Name, Dimension = False) Export
	
	TypesArray = New Array;
	Classifier = Undefined;
	
	If Name = "MainItem"
		Or Name = "ReverseSign"
		Or Name = "UsageFlag_" Then
		TypesArray.Add(Type("Boolean"));
	ElsIf Name = "String" Or Name = "Column" Then
		TypesArray.Add(Type("CatalogRef.FinancialReportItems"));
	ElsIf Name = "ItemKind" Then
		TypesArray.Add(Type("EnumRef.FinancialReportItemKinds"));
	ElsIf Name = "BudgetFlowItem" Then
		TypesArray.Add(Type("CatalogRef.BudgetFlowItems"));
		TypesArray.Add(Type("CatalogRef.BudgetBalanceItems"));
	ElsIf Name = "NonFinancialItem" Then
		TypesArray.Add(Type("CatalogRef.NonFinancialItemsOfBudgets"));
	ElsIf Name = "BudgetBalanceItem" Then
		TypesArray.Add(Type("CatalogRef.BudgetBalanceItems"));
	ElsIf Name = "EditedValue" Then
		TypesArray.Add(Type("String"));
		Classifier = New StringQualifiers(150);
	ElsIf StrFind(Name, "Period") Then
		TypesArray.Add(Type("Date"));
	ElsIf Name = "Flag" Then
		TypesArray.Add(Type("String"));
		Classifier = New StringQualifiers(20);
	ElsIf Name = "Organization" Then
		TypesArray.Add(Type("CatalogRef.Companies"));
	ElsIf Name = "Department" Then
		TypesArray.Add(Type("CatalogRef.BusinessStructure"));
	ElsIf Name = "Scenario" Then
		TypesArray.Add(Type("CatalogRef.BudgetingScenarios"));
	ElsIf Name = "UnitOfMeasure" Then
		TypesArray.Add(Type("CatalogRef.PackagesAndUnitsOfMeasure"));
	ElsIf Name = "Currency" Then
		TypesArray.Add(Type("CatalogRef.Currencies"));
	ElsIf StrFind(Name, "Dimension") Then
		TypesArray = BudgetingServer.AllTypesOfAnalytics();
	ElsIf Dimension Then
		Return Name.ValueType;
	ElsIf Name = "Count" Or Name = "Sum" Then
		TypesArray.Add(Type("Number"));
	ElsIf Name = "LineNumber" Then
		TypesArray.Add(Type("Number"));
	ElsIf Name = "Formula" Then
		TypesArray.Add(Type("String"));
	ElsIf Name = "ID_Source1" Then
		TypesArray.Add(Type("String"));
		Classifier = New StringQualifiers(30);
	ElsIf Name = "EditedValueType" Then
		TypesArray.Add(Type("String"));
		Classifier = New StringQualifiers(15);
	ElsIf Name = "SourceField" Then
		TypesArray.Add(Type("String"));
		Classifier = New StringQualifiers(50);
	ElsIf Name = "OperandName" Then
		TypesArray.Add(Type("String"));
		Classifier = New StringQualifiers(150);
	ElsIf Name = "OperandType" Then
		TypesArray.Add(Type("EnumRef.FinancialReportItemKinds"));
	ElsIf Name = "OperandString"
		Or Name = "OperandColumn_" Then
		TypesArray.Add(Type("CatalogRef.FinancialReportItems"));
	ElsIf Name = "GeneralMeasurements"
		Or Name = "ListOfOperands" Then
		TypesArray.Add(Type("String"));
		Classifier = New StringQualifiers(1000);
	ElsIf Name = "SourcesOfCalculation"
		Or Name = "Note" Then
		TypesArray.Add(Type("String"));
		Classifier = New StringQualifiers(1000);
	ElsIf Name = "ExcludeEnteredDocumentDataDuringCalculation" Then
		TypesArray.Add(Type("Boolean"));
	Else
		Raise NStr("vi = 'Kiểu cột cấu trúc ô không xác định';
					|ru = 'Неизвестный тип колонки структуры ячеек';
					|en = 'Unknown cell structure column type'; fa = 'Unknown cell structure column type';
					|it = 'Tipo sconosciuto di colonna della struttura delle celle';
					|pl = 'Nieznany typ kolumny struktury komórek';
					|tr = 'Bilinmeyen hücre yapısı sütun türü'");
	EndIf;
	
	If ValueIsFilled(Classifier) Then
		Return New TypeDescription(TypesArray,,,,Classifier);
	Else
		Return New TypeDescription(TypesArray);
	EndIf;
	
EndFunction

Function ThisIsFixedElement(Val CurElementString) Export
	
	If TypeOf(CurElementString) = Type("String") Then
		AddressOfItemStructure = CurElementString;
		ItemKind = GetFromTempStorage(AddressOfItemStructure).ItemKind;
	Else
		ItemKind = CurElementString.ItemKind;
		AddressOfItemStructure = CurElementString.AddressOfItemStructure;
	EndIf;
	
	If ItemKind = Enums.FinancialReportItemKinds.Dimension Then
		DimensionType = FinancialReportingServerCall.ValueOfAdditionalProps(
			AddressOfItemStructure, "DimensionType");
		If DimensionType = Enums.TypesOfBudgetReportDimensions.FixedDimension Then
			Return True;
		ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.Organization Then
			Return True;
		ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.Department Then
			Return True;
		ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.Scenario Then
			Return True;
		ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.Period Then
			PeriodValue = FinancialReportingServerCall.ValueOfAdditionalProps(
				AddressOfItemStructure,
				"PeriodValue");
			If PeriodValue <> Undefined Then
				Return True;
			EndIf;
		EndIf;
	ElsIf ItemKind = Enums.FinancialReportItemKinds.RowColumn Then
		Return True;
	ElsIf ItemKind = Enums.FinancialReportItemKinds.Group Then
		Return True;
	ElsIf ItemKind = Enums.FinancialReportItemKinds.Columns Then
		Return True;
	ElsIf ItemKind = Enums.FinancialReportItemKinds.Rows Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

#EndRegion 

#Region GeneratingDCSForDataAcquisition

Procedure AddSchemaParameter(DCS, Name) Export
	
	If DCS.Parameters.Find(Name) = Undefined Then
		NewParameter1 = DCS.Parameters.Add();
		NewParameter1.Name = Name;
	EndIf;
	
EndProcedure

#EndRegion

#Region GeneratingTreeForReportOutput

// LongDesc
// 
// Parameters:
// 	TableParameters - Structure - LongDesc:
// 		* DisplayGroupingTitle - Boolean -
// 		* GroupHeader - String -
// 		* DisplayHeadersVertically - Boolean -
// 		* DisplayColumnNumbering - Boolean -
// 		* DisplayRowsNumbering - Boolean -
// 		* AppearanceItems - ValueTable -
// 		* RegisteredRows - ValueTable -
// 		* DesigningColumns - ValueTable -
// 		* DrillDownOfAppearanceItemFilterFields - ValueTable -
// 	CacheAdditionalBankingDetails - ValueTable -
// Returns:
// 	ValueTable - LongDesc:
// * String - Arbitrary -
// * LineNumber - Number -
// * Column - Arbitrary -
// * ColumnNumber - Number -
// * Count - Number -
// * Sum - Number -
// * Value - Arbitrary -
// * FlagCount - Boolean -
// * FlagSum - Boolean -
// * FlagValue - Boolean -
// * AreaName - String -
// * TableNumber - Number  -
//
Function ReportDataForFormatting(TableParameters, CacheAdditionalBankingDetails) Export
	
	FinReports = FinancialReportingServer;
	
	Table = New ValueTable;
	Table.Columns.Add("String");
	Table.Columns.Add("LineNumber");
	Table.Columns.Add("Column");
	Table.Columns.Add("ColumnNumber");
	Table.Columns.Add("Count");
	Table.Columns.Add("Sum");
	Table.Columns.Add("Value");
	Table.Columns.Add("FlagCount");
	Table.Columns.Add("FlagSum");
	Table.Columns.Add("FlagValue");
	Table.Columns.Add("AreaName");
	Table.Columns.Add("TableNumber");
	
	ItemArray = New Array;
	If TableParameters.Property("RegisteredRows")
		And TableParameters.Property("DesigningColumns") Then
		CommonClientServer.SupplementArray(ItemArray, TableParameters.RegisteredRows.UnloadColumn("ReportItem"));
		CommonClientServer.SupplementArray(ItemArray, TableParameters.DesigningColumns.UnloadColumn("ReportItem"));
	EndIf;
	
	ArrayOfDimensions_ = New Array;
	
	For Each ReportItem In ItemArray Do
		
		If Not ValueIsFilled(ReportItem) Then
			Continue;
		EndIf;
		
		DimensionType = FinReports.ValueOfAdditionalProps(ReportItem, "DimensionType", CacheAdditionalBankingDetails);
		
		If DimensionType = Undefined Then
			// Not a measurement
			Continue;
		EndIf;
		
		If DimensionType = Enums.TypesOfBudgetReportDimensions.Period Then
			Periodicity = FinReports.ValueOfAdditionalProps(ReportItem, "Periodicity", CacheAdditionalBankingDetails);
			DimensionName = FinancialReportingClientServer.PeriodStrings(Periodicity).Period;
			
		ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.Dimension Then
			DimensionKind = FinReports.ValueOfAdditionalProps(ReportItem, "DimensionKind", CacheAdditionalBankingDetails);
			DimensionName = FinancialReportingCached.NameOfBudgetReportField(DimensionKind);
			
		ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.RegisterDimension Then
			DimensionName = FinReports.ValueOfAdditionalProps(ReportItem, "DimensionName", CacheAdditionalBankingDetails);
			
		ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.Organization Then
			DimensionName = "Organization";
			
		ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.Department Then
			DimensionName = "Department";
			
		ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.Scenario Then
			DimensionName = "Scenario";
			
		ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.Currency Then
			DimensionName = "Currency";
			
		ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.FixedDimension Then
			DimensionKind = FinReports.ValueOfAdditionalProps(ReportItem, "DimensionKind", CacheAdditionalBankingDetails);
			DimensionName = FinancialReportingCached.NameOfBudgetReportField(DimensionKind);
			
		EndIf;
		
		If ArrayOfDimensions_.Find(DimensionName) = Undefined Then
			ArrayOfDimensions_.Add(DimensionName);
		EndIf;
		
	EndDo;
	
	For Each DimensionName In ArrayOfDimensions_ Do
		Table.Columns.Add(DimensionName);
	EndDo;
	
	Return Table;
	
EndFunction

// A tree in a table of values
// 
// Parameters:
// 	Tree - ValueTree, ValueTreeRow -
// 	Table - ValueTable, Undefined -
// 	Level - Number -
// Returns:
// 	ValueTable, Undefined - LongDesc
Function ConvertTreeToTable(Tree, Table = Undefined, Level = 0) Export
	
	If Table = Undefined Then
		Table = New ValueTable;
		For Each Column In Tree.Columns Do
			Table.Columns.Add(Column.Name);
		EndDo;
	EndIf;
	
	For Each TreeRow In Tree.Rows Do
		
		Whitespace = "";
		For Cnt = 1 To Level Do
			Whitespace = Whitespace + " - ";
		EndDo;
		
		NewRow = Table.Add();
		FillPropertyValues(NewRow, TreeRow);
		NewRow[0] = Whitespace + String(NewRow[0]);
		ConvertTreeToTable(TreeRow, Table, Level + 1);
		
	EndDo;
	
	Return Table;
	
EndFunction

#EndRegion 

#Region StructureOfBudgetProfileDescription


// LongDesc
// 
// Parameters:
// 	BudgetProfile - CatalogRef.BudgetProfiles - LongDesc
// 	ColumnStructureOfDataTable - Structure, Boolean, Undefined - LongDesc:
// * DimensionKinds - Array -
// * Dimensions - Array -
// * Periodicity_ - Array -
// 	GenerationMode - EnumRef.ModesOfBudgetReportGeneration - LongDesc
// Returns:
// 	Structure - LongDesc:
// * DataSources - See GetDescriptionOfDataSources
// * SourcesOfGroupingPeriods - See BudgetReportingCacheCalculationServer.SourcesOfGroupingPeriods
// * CellStructure - ValueTable - table with columns:
//    **MainItem - Boolean - Flag of the main element.
//    **String - CatalogRef.FinancialReportItems - Budget line.
//    **Column - CatalogRef.FinancialReportItems - Column of the budget.
// * CellStructureIndexes - Array of String - Array of index field names.
// * SourceFields_2 - ValueTable - The table of the fields:
//    **ResourceName - String -
//    **Auxiliary_ - Boolean - 
// * CellParameters - ValueTable - 
// * FillingInMissingNFPMeasurements - ValueTable -
// * SourcesOfMeasurementValues - ValueTable -
// * SelectionOfNFPMeasurements - ValueTable -
// * TableOfSubordinationOfElements - ValueTable, ValueTree - contains columns:
//    **Parent - CatalogRef.FinancialReportItems - 
//    **Ref - CatalogRef.FinancialReportItems - 
//    **ItemKind - EnumRef.FinancialReportItemKinds - 
//
Function DescriptionOfReport(BudgetProfile, ColumnStructureOfDataTable, GenerationMode) Export
	
	SetPrivilegedMode(True);
	
	Postfix = ?(GenerationMode = Enums.ModesOfBudgetReportGeneration.PrintBudget,
						Enums.ModesOfBudgetReportGeneration.Document,
						GenerationMode);
	TypeOfCacheElement = Enums.BudgetCacheKinds.StructureOfBudgetProfileDescription;
	
	Value = InformationRegisters.CacheOfAuxiliaryBudgetProfileData.GetCacheValue(BudgetProfile, TypeOfCacheElement, Postfix);
	
	If Value <> Undefined Then
		SetPrivilegedMode(False);
		Return Value;
	EndIf;
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("Budgeting.CalculatingAndObtainingDescriptionStructure");

	Result = CalculatingAndObtainingDescriptionStructure(BudgetProfile, ColumnStructureOfDataTable, GenerationMode, TypeOfCacheElement, Postfix);
	
	DataVolume = Result.CellStructure.Count();
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, DataVolume);
	
	SetPrivilegedMode(False);
	
	Return Result;
	
EndFunction

// Returns the result of a query on the operand table that requires calculating cell data
// 
// Parameters:
// 	StructureDescriptionOfReport - See BudgetReportingCacheCalculationServer.DescriptionOfReport
//
// Returns:
// 	QueryResult, Undefined -
Function TableOfOperandsRequiringCalculationOfCellData(StructureDescriptionOfReport) Export
	
	TableToCheck_ = StructureDescriptionOfReport.CellStructure.Copy(, "MainItem, String, Column, ItemKind, OperandType, ID_Source1");
	TableToCheck_.GroupBy("MainItem, String, Column, ItemKind, OperandType, ID_Source1");
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	CellStructure.MainItem,
	|	CellStructure.String,
	|	CellStructure.Column,
	|	CellStructure.ItemKind,
	|	CellStructure.OperandType
	|INTO CellStructure
	|FROM
	|	&CellStructure AS CellStructure
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfSubordination.Parent,
	|	TableOfSubordination.Ref
	|INTO TableOfSubordination
	|FROM
	|	&TableOfSubordination AS TableOfSubordination
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CellStructure.String,
	|	CellStructure.Column,
	|	CellStructure.MainItem,
	|	CellStructure.OperandType,
	|	CellStructure.ItemKind,
	|	MAX(TableOfRows.Ref) IS NULL  AS FinalItem
	|INTO CalculationAndSummaryElements
	|FROM
	|	CellStructure AS CellStructure
	|		LEFT JOIN TableOfSubordination AS TableOfRows
	|		ON (CellStructure.String = TableOfRows.Parent
	|				OR CellStructure.Column = TableOfRows.Parent)
	|
	|GROUP BY
	|	CellStructure.String,
	|	CellStructure.Column,
	|	CellStructure.MainItem,
	|	CellStructure.OperandType,
	|	CellStructure.ItemKind
	|
	|HAVING
	|	NOT(MAX(TableOfRows.Ref) IS NULL 
	|			AND CellStructure.MainItem
	|			AND CellStructure.ItemKind IN (&ListOfEditingElements))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	CalculationAndSummaryElements.String,
	|	CalculationAndSummaryElements.Column,
	|	CalculationAndSummaryElements.MainItem,
	|	CalculationAndSummaryElements.OperandType,
	|	CalculationAndSummaryElements.ItemKind,
	|	CalculationAndSummaryElements.FinalItem
	|INTO JointOutputValidationTable
	|FROM
	|	CalculationAndSummaryElements AS CalculationAndSummaryElements
	|WHERE
	|	NOT(CalculationAndSummaryElements.MainItem
	|					AND CalculationAndSummaryElements.ItemKind IN (&ListOfArbitraryAndGroups)
	|				OR NOT CalculationAndSummaryElements.MainItem
	|					AND CalculationAndSummaryElements.OperandType IN (&CellReference)
	|				OR CalculationAndSummaryElements.ItemKind = &NonFinancialItem)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	JointOutputValidationTable.String,
	|	JointOutputValidationTable.Column,
	|	JointOutputValidationTable.MainItem,
	|	JointOutputValidationTable.OperandType,
	|	JointOutputValidationTable.ItemKind,
	|	JointOutputValidationTable.FinalItem
	|FROM
	|	JointOutputValidationTable AS JointOutputValidationTable
	|		LEFT JOIN TableOfSubordination AS TableOfSubordination
	|		ON JointOutputValidationTable.String = TableOfSubordination.Parent
	|		LEFT JOIN Catalog.FinancialReportItems.ItemKindAttributes AS FinancialReportItemsItemKindAttributes
	|		ON (TableOfSubordination.Ref = FinancialReportItemsItemKindAttributes.Ref)
	|			AND (FinancialReportItemsItemKindAttributes.Attribute = &OutputPropsWithParent)
	|WHERE
	|	ISNULL(FinancialReportItemsItemKindAttributes.Value, FALSE) = FALSE";
	
	ListOfEditingElements = New ValueList;
	ListOfEditingElements.Add(Enums.FinancialReportItemKinds.BudgetFlowItem);
	ListOfEditingElements.Add(Enums.FinancialReportItemKinds.EditedValue);
	
	ListOfArbitraryAndGroups = New ValueList;
	ListOfArbitraryAndGroups.Add(Enums.FinancialReportItemKinds.DerivedItem);
	ListOfArbitraryAndGroups.Add(Enums.FinancialReportItemKinds.Group);
	ListOfArbitraryAndGroups.Add(Enums.FinancialReportItemKinds.GroupFormula);
	
	Query.SetParameter("CellStructure", TableToCheck_);
	Query.SetParameter("TableOfSubordination", StructureDescriptionOfReport.TableOfSubordinationOfElements);
	Query.SetParameter("ListOfEditingElements", ListOfEditingElements);
	Query.SetParameter("ListOfArbitraryAndGroups", ListOfArbitraryAndGroups);
	Query.SetParameter("CellReference", Enums.FinancialReportItemKinds.TableCell);
	Query.SetParameter("NonFinancialItem", Enums.FinancialReportItemKinds.NonFinancialItem);
	Query.SetParameter("OutputPropsWithParent", ChartsOfCharacteristicTypes.ItemAttributesOfFinancialReports.DisplayWithParent);
	
	Result = Query.Execute();
	Return Result;
	
EndFunction

#EndRegion 

#Region SourcesOfMeasurementValues_

// The constructor table of the elements
//
// Returns:
// 	ValueTable - contains columns:
// 		* Item - CatalogRef.FinancialReportItems, String - a report item or the address of its storage in temporary storage.
// 		* Column - CatalogRef.FinancialReportItems, String - a report item or the address of its storage in temporary storage.
// 		* String  - CatalogRef.FinancialReportItems, String - a report item or the address of its storage in temporary storage.
//
Function NewTableOfElements() Export
	
	TableOfElements = New ValueTable();
	TableOfElements.Columns.Add("Item");
	TableOfElements.Columns.Add("Column");
	TableOfElements.Columns.Add("String");
	
	Return TableOfElements;
	
EndFunction

// Source table constructor
// 
// Returns:
// 	ValueTable - contains columns:
// 		* ItemKind - Arbitrary -
// 		* Item - Arbitrary - 
// 		* Parent - Arbitrary - 
// 		* Description - Arbitrary - 
//
Function NewSourceTable() Export
	
	TableOfSources = New ValueTable;
	TableOfSources.Columns.Add("ItemKind");
	TableOfSources.Columns.Add("Item");
	TableOfSources.Columns.Add("Parent");
	TableOfSources.Columns.Add("Description");
	
	Return TableOfSources;
	
EndFunction

// Returns the sources of the values for the elements of financial statements when using types of budgets.
// 
// Parameters:
//	Cache - ValueTable, Undefined - child element cache for the current element
//	TreeRow - ValueTreeRow - value tree string
//	FillType - Boolean - flag for filling in
//	WithoutDerivatives - Boolean - False when you want to include derived metrics.
//
// Returns:
//	ValueTable - Calculated Value Sources:
//	* ItemKind - EnumRef.FinancialReportItemKinds -
//	* Item - CatalogRef.FinancialReportItems - Item
//	* Parent - CatalogRef.FinancialReportItems - parent element
//	* Description - String - Representation of the element.
// 
Function SourcesOfElementValues(Cache, TreeRow, FillType = False, WithoutDerivatives = False) Export
	
	TableOfSources = NewSourceTable();
	
	TableComplex_ = False;
	SourceOfSubordinates = Undefined;
	
	Table = FinancialReportingServer.RootItem(TreeRow,
		Enums.FinancialReportItemKinds.ComplexTable);
	If Table <> Undefined Then
		TableComplex_ = True;
	EndIf;
	
	TheseAreLines = FinancialReportingServer.RootItem(TreeRow,
		Enums.FinancialReportItemKinds.Columns) = Undefined;
	
	TypesOfValueElements = New Array;
	TypesOfValueElements.Add(Enums.FinancialReportItemKinds.BudgetFlowItem);
	TypesOfValueElements.Add(Enums.FinancialReportItemKinds.BudgetBalanceItem);
	TypesOfValueElements.Add(Enums.FinancialReportItemKinds.NonFinancialItem);
	If Not FillType Then
		TypesOfValueElements.Add(Enums.FinancialReportItemKinds.EditedValue);
	EndIf;
	If Not FillType And Not WithoutDerivatives Then
		TypesOfValueElements.Add(Enums.FinancialReportItemKinds.DerivedItem);
	EndIf;
	
	If Not TableComplex_ Then
		// 1. Defining the list of parent elements
		Parent = TreeRow;
		While Parent <> Undefined Do
			If TypesOfValueElements.Find(Parent.ItemKind) <> Undefined Then
				NewRow = TableOfSources.Add();
				NewRow.Item = 
					?(ValueIsFilled(Parent.AddressOfItemStructure), Parent.AddressOfItemStructure, Parent.ReportItem);
				NewRow.ItemKind = Parent.ItemKind;
				NewRow.Description = Parent.NameForPrinting;
			EndIf;
			Parent = FinancialReportingClientServer.RowParent(Parent);
		EndDo;
		
		// 2. Define the list of subordinate elements
		SubordinateSourcesOfSimpleTableElementValues(
			FinancialReportingServer.SubordinateRows(TreeRow),
			TableOfSources,
			TypesOfValueElements);
		
		// 3. Define the list of transposed elements
		SourceOfSubordinates = Undefined;
		
		Table = FinancialReportingServer.RootItem(TreeRow,
			Enums.FinancialReportItemKinds.TableIndicatorsInRows);
		If Table = Undefined Then
			Table = FinancialReportingServer.RootItem(TreeRow,
				Enums.FinancialReportItemKinds.TableIndicatorsInColumns);
		EndIf;
		
		If Table <> Undefined Then //Dimensions can be selected without a table
			
			If TheseAreLines Then
				SourceOfSubordinates = FinancialReportingServer.SubordinateItem(
					Table,
					"ItemKind",
					Enums.FinancialReportItemKinds.Columns);
			Else
				SourceOfSubordinates = FinancialReportingServer.SubordinateItem(
					Table,
					"ItemKind",
					Enums.FinancialReportItemKinds.Rows);
			EndIf;
		
			SubordinateSourcesOfSimpleTableElementValues(
				FinancialReportingServer.SubordinateRows(SourceOfSubordinates),
				TableOfSources,
				TypesOfValueElements);
		EndIf;
		
	Else
		
		// 1. Define the table of elements
		
		CellsSettings = FinancialReportingServer.SubordinateItem(
			Table,
			"ItemKind",
			Enums.FinancialReportItemKinds.CellsSettings);
		
		TableOfElements = GetTableOfElements(CellsSettings, Cache);
		
		SearchByAddress = ValueIsFilled(CellsSettings.AddressOfItemStructure);
		
		// 2. Finding related elements
		
		EntireTreeBranch = New Array;
		EntireTreeBranch.Add(TreeRow);
		SubordinateSourcesOfComplexTableElementValues(TreeRow.Rows, EntireTreeBranch);
		
		For Each ProcessingString In EntireTreeBranch Do
			
			SearchItem = ?(SearchByAddress, ProcessingString.AddressOfItemStructure, ProcessingString.ReportItem);
			TheStructureOfTheSearch = New Structure(?(TheseAreLines, "String", "Column"), SearchItem);
			
			If ValueIsFilled(SearchItem) Then
				ObjectAttributes = MapItemDetailsByLinkOrAddress(SearchItem, "NameForPrinting", Cache);
				NameOfSearchElement = ObjectAttributes.NameForPrinting;
			Else
				NameOfSearchElement = "";
			EndIf;
			
			FoundRows = TableOfElements.FindRows(TheStructureOfTheSearch);
			For Each FoundRow In FoundRows Do
				
				Item = FoundRow.Item;
				
				ObjectAttributes = MapItemDetailsByLinkOrAddress(Item, "ItemKind, NameForPrinting", Cache);
				
				If TypesOfValueElements.Find(ObjectAttributes.ItemKind) = Undefined Then
					Continue;
				EndIf;
				
				Parent = ?(TheseAreLines, FoundRow.Column, FoundRow.String);
				FoundItemListString = TableOfSources.Find(Parent, "Item");
				If FoundItemListString = Undefined Then
					FoundItemListString = TableOfSources.Add();
					FoundItemListString.Item = Parent;
					DetailsParent = MapItemDetailsByLinkOrAddress(Parent, "ItemKind, NameForPrinting", Cache);
					FoundItemListString.ItemKind = DetailsParent.ItemKind;
					FoundItemListString.Description = DetailsParent.NameForPrinting;
				EndIf;
				NewRow = TableOfSources.Add();
				NewRow.ItemKind = ObjectAttributes.ItemKind;
				NewRow.Item = Item;
				NewRow.Parent = Parent;
				NewRow.Description = ObjectAttributes.NameForPrinting + " (" + NameOfSearchElement + ")";
				
			EndDo;
		
		EndDo;
		
	EndIf;
	
	// 4. Filter out the NPOs that do not support the selected analytics
	LinkAddress = ?(ValueIsFilled(TreeRow.AddressOfItemStructure), TreeRow.AddressOfItemStructure, TreeRow.ReportItem);
	DimensionType = FinancialReportingServerCall.ValueOfAdditionalProps(LinkAddress, "DimensionType");
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	
	If DimensionType = Enums.TypesOfBudgetReportDimensions.Dimension
		Or DimensionType = Enums.TypesOfBudgetReportDimensions.FixedDimension Then
		DimensionKind = FinancialReportingServerCall.ValueOfAdditionalProps(LinkAddress, "DimensionKind");
	ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.RegisterDimension Then
		DimensionName = FinancialReportingServerCall.ValueOfAdditionalProps(LinkAddress, "DimensionName");
	EndIf;
	
	ForDeletion = New Array;
	For Each Item In TableOfSources Do
		
		ItemKind = MapItemDetailsByLinkOrAddress(Item.Item, "ItemKind", Cache).ItemKind;
		If ItemKind = Enums.FinancialReportItemKinds.NonFinancialItem Then
			NonFinancialItem = FinancialReportingServerCall.ValueOfAdditionalProps(Item.Item, "NonFinancialItem");
			AttributesList = "ByScenarios, ByCompanies, ByBusinessUnits";
			For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
				AttributesList = AttributesList + ", DimensionKind" + DimensionNumber;
			EndDo;
			Attributes = Common.ObjectAttributesValues(NonFinancialItem, AttributesList);
			
			NFPIsAvailable = False;
			If DimensionType = Enums.TypesOfBudgetReportDimensions.Dimension
				Or DimensionType = Enums.TypesOfBudgetReportDimensions.FixedDimension Then
				For Cnt = 1 To MaximumNumberOfAnalysts Do
					If Attributes["DimensionKind" + Cnt] = DimensionKind Then
						NFPIsAvailable = True;
						Break;
					EndIf;
				EndDo;
			ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.RegisterDimension Then
				DimensionName = FinancialReportingServerCall.ValueOfAdditionalProps(LinkAddress, "DimensionName");
				If DimensionName = "Scenario" And Attributes.ByScenarios Then
					NFPIsAvailable = True;
				ElsIf DimensionName = "Department" And Attributes.ByBusinessUnits Then
					NFPIsAvailable = True;
				ElsIf DimensionName = "Organization" And Attributes.ByCompanies Then
					NFPIsAvailable = True;
				EndIf;
			EndIf;
			If Not NFPIsAvailable Then
				ForDeletion.Add(Item);
			EndIf;
		EndIf;
		
	EndDo;
	
	For Each ArrayElement In ForDeletion Do
		TableOfSources.Delete(ArrayElement);
	EndDo;
	
	Result = TableOfSources.CopyColumns(); // See NewSourceTable
	AugmentSourcesWithOperandsRecursively(TableOfSources, TypesOfValueElements, TableOfElements, Result, Cache, FillType);
	
	Return Result;
	
EndFunction

// Returns the sources of default values for the elements of financial statements when using types of budgets.
// 
// Parameters:
//	Cache - ValueTable, Undefined - child element cache for the current element
//	TreeStringAddressOfReportElements - ValueTreeRow, String - the string tree of values or an address in the temporary repository
//	ItemAddressInStorage - String -
//	FillType - Boolean - flag for filling in
//	WithoutDerivatives - Boolean - False when you want to include derived metrics.
//
// Returns:
//	ValueTable - Calculated Value Sources:
//	* Source - CatalogRef.FinancialReportItems, String - item or its address in temporary storage
//	* ItemKind - EnumRef.FinancialReportItemKinds -
// 
Function SourcesOfDefaultValues(Cache, TreeStringAddressOfReportElements, ItemAddressInStorage = Undefined, FillType = False, WithoutDerivatives = False) Export
	
	If TypeOf(TreeStringAddressOfReportElements) = Type("ValueTreeRow") Then
		TreeRow = TreeStringAddressOfReportElements;
	Else
		ItemsTree = GetFromTempStorage(TreeStringAddressOfReportElements);
		TreeRow = FinancialReportingServer.SubordinateItem(ItemsTree, "AddressOfItemStructure", ItemAddressInStorage);
	EndIf;
	
	TableOfSources = SourcesOfElementValues(Cache, TreeRow, FillType, WithoutDerivatives);
	
	CalculatedValueSources = ArticlesAndIndicatorsOfElementValues(TableOfSources, True);
	
	Return CalculatedValueSources;
	
EndFunction

#EndRegion 

#Region Other

// Searches for layout selection elements by the passed name of the layout field
// 
// Parameters:
// 	SourceSelection - DataCompositionFilterItemGroup, DataCompositionSettings - Source of selection.
// 	TagName - String - Name of the layout field.
// 	FoundSelection - ValueList, Array, Undefined - The array into which to place the found items selection.
// 	TakingIntoAccountNested - Boolean - Flag for searching with nested fields.
// 	UsedOnly - Boolean - Flag for searching only for used selection elements.
// Returns:
// 	Boolean - True if suitable selection elements are found.
Function FindSelectionByName(SourceSelection, TagName, FoundSelection = Undefined, TakingIntoAccountNested = False, UsedOnly = True) Export
	
	If SourceSelection = Undefined Then
		Return False;
	EndIf;
	
	LayoutField = New DataCompositionField(TagName);
	
	If TypeOf(SourceSelection) = Type("DataCompositionFilterItemGroup") Then
		FilterItems1 = SourceSelection.Items;
	Else
		Filter = SourceSelection.Filter; // DataCompositionFilter
		FilterItems1 = Filter.Items;
	EndIf;
	
	For Each FilterElement In FilterItems1 Do
		If TypeOf(FilterElement) = Type("DataCompositionFilterItemGroup") Then
			If FindSelectionByName(FilterElement, TagName, FoundSelection, TakingIntoAccountNested, UsedOnly) Then
				
				If FoundSelection = Undefined Then
					Return True;
				EndIf;
				
			EndIf;
		Else
			If TakingIntoAccountNested Then
				
				FieldName = String(FilterElement.LeftValue);
				PointPosition = StrFind(FieldName, ".");
				If PointPosition Then
					FieldName = Left(FieldName, PointPosition - 1);
				EndIf;
				LeftValue = New DataCompositionField(FieldName);
				
				If TypeOf(FilterElement.RightValue) = Type("DataCompositionField") Then
					
					FieldName = String(FilterElement.RightValue);
					PointPosition = StrFind(FieldName, ".");
					If PointPosition Then
						FieldName = Left(FieldName, PointPosition - 1);
					EndIf;
					RightValue = New DataCompositionField(FieldName);
					
				Else
					
					RightValue = FilterElement.RightValue;
					
				EndIf;
			Else
				
				LeftValue = FilterElement.LeftValue;
				RightValue = FilterElement.RightValue;
				
			EndIf;
			
			If (LeftValue = LayoutField
				Or RightValue = LayoutField)
				And (FilterElement.Use Or Not UsedOnly) Then
				
				If FoundSelection = Undefined Then
					Return True;
				EndIf;
				
				FoundSelection.Add(FilterElement);
				
			EndIf;
			
		EndIf;
	EndDo;
	
	If FoundSelection = Undefined Then
		Return False;
	Else
		Return FoundSelection.Count() > 0;
	EndIf;
	
EndFunction

Function FilterAvailabilityParameters(ReportRow = Undefined, DefinitionParameters = Undefined, CacheStructure = Undefined) Export
	
	If CacheStructure = Undefined Then
		CacheOfAdditionalBankingDetails = Undefined;
		AttributeCache = New Map;
	Else
		CacheOfAdditionalBankingDetails = CacheStructure.CacheOfAdditionalBankingDetails;
		AttributeCache = CacheStructure.AttributeCache;
	EndIf;
	
	AvailabilityOfFilters = New Structure("Organization, Department, Scenario", True, True, True);
	Column = Undefined; String = Undefined;
	
	If DefinitionParameters = Undefined Then
		
		CellsSettings = FinancialReportingServer.RootItem(ReportRow,
			Enums.FinancialReportItemKinds.CellsSettings);
		If CellsSettings = Undefined Then
			
			TableRows = FinancialReportingServer.RootItem(ReportRow,
				Enums.FinancialReportItemKinds.Rows);
			TableColumns1 = FinancialReportingServer.RootItem(ReportRow,
				Enums.FinancialReportItemKinds.Columns);
			If TableRows = Undefined And TableColumns1 = Undefined Then
				// this is a report with no structure
				String = ReportRow;
				Column = Undefined;
			ElsIf TableRows <> Undefined Then
				String = ReportRow;
				Table = FinancialReportingServer.RootItem(ReportRow, Enums.FinancialReportItemKinds.TableIndicatorsInRows);
				Column = FinancialReportingServer.SubordinateItem(Table, "ItemKind", Enums.FinancialReportItemKinds.Columns);
			ElsIf TableColumns1 <> Undefined Then
				Table = FinancialReportingServer.RootItem(ReportRow, Enums.FinancialReportItemKinds.TableIndicatorsInColumns);
				String = FinancialReportingServer.SubordinateItem(Table, "ItemKind", Enums.FinancialReportItemKinds.Rows);
				Column = ReportRow;
			EndIf;
			
		Else
			
			If TypeOf(AttributeCache) = Type("Map") Then
				SettingsTable1 = BudgetReportingDisplayServer.Attachable_ValueFromAnalytics(
					AttributeCache,
					CellsSettings.ReportItem,
					"TableItems"); // See NewTableOfElements
			ElsIf TypeOf(AttributeCache) = Type("ValueTable") Then
				SettingsTable1 = ValueOfBudgetViewElementSProps(
					CellsSettings.ReportItem,
					"TableItems",
					 AttributeCache); // See NewTableOfElements
			EndIf;
			
			CellDefinitionString = SettingsTable1.Find(ReportRow.ReportItem, "Item");
			If CellDefinitionString = Undefined Then
				Parent = ReportRow.Parent;
				CellDefinitionString = SettingsTable1.Find(Parent.ReportItem, "Item");
			EndIf;
			Table = FinancialReportingServer.RootItem(ReportRow, Enums.FinancialReportItemKinds.ComplexTable);
			String = FinancialReportingServer.SubordinateItem(Table, "ReportItem", CellDefinitionString.String);
			Column = FinancialReportingServer.SubordinateItem(Table, "ReportItem", CellDefinitionString.Column);
			
		EndIf;
		
	Else
		
		ItemTableAddress = Undefined; AddressOfReportItems = Undefined;
		TableOfElements = Undefined; ItemsTree = Undefined;
		If DefinitionParameters.Property("ItemTableAddress", ItemTableAddress) Then
			TableOfElements = GetFromTempStorage(ItemTableAddress); // See NewTableOfElements
		EndIf;
		If DefinitionParameters.Property("AddressOfReportItems", AddressOfReportItems) Then
			ItemsTree = GetFromTempStorage(AddressOfReportItems);
		EndIf;
		
		If TableOfElements = Undefined Then
			
			TreeItem = ItemsTree.Rows.Find(DefinitionParameters.AddressOfEditedItem, "AddressOfItemStructure", True);
			RootItem = FinancialReportingServer.RootItem(TreeItem,
				Enums.FinancialReportItemKinds.TableIndicatorsInRows);
			SourceOfSubordinates = Undefined;
			If RootItem <> Undefined Then
				SourceOfSubordinates = FinancialReportingServer.SubordinateItem(RootItem,
					"ItemKind",
					Enums.FinancialReportItemKinds.Columns);
				Column = TreeItem;
				String = SourceOfSubordinates;
			EndIf;
			
			If RootItem = Undefined Then
				
				RootItem = FinancialReportingServer.RootItem(TreeItem,
					Enums.FinancialReportItemKinds.TableIndicatorsInColumns);
				If RootItem <> Undefined Then
					SourceOfSubordinates = FinancialReportingServer.SubordinateItem(RootItem,
						"ItemKind",
						Enums.FinancialReportItemKinds.Rows);
					Column = SourceOfSubordinates;
					String = TreeItem;
				EndIf;
				
			EndIf;
			
			If RootItem = Undefined Then
				
				String = TreeItem;
				Column = Undefined;
				
			EndIf;
			
		Else
			
			MatrixCell = TableOfElements.Find(DefinitionParameters.AddressOfEditedItem, "Item");
			
			String = ItemsTree.Rows.Find(MatrixCell.String, "AddressOfItemStructure", True);
			Column = ItemsTree.Rows.Find(MatrixCell.Column, "AddressOfItemStructure", True);
			
		EndIf;
		
	EndIf;
	
	Result = New Structure;
	
	For Each KeyAndValue In AvailabilityOfFilters Do
		
		SearchableType = KeyAndValue.Key;
		
		ThereAreCellsWithUndefinedElement = True;
		If ThereIsCertainElementInParentRows(String, SearchableType, CacheOfAdditionalBankingDetails) Then
			ThereAreCellsWithUndefinedElement = False;
		ElsIf Not ThereIsUndefinedElementOfTypeInSubordinateStrings(String, SearchableType, CacheOfAdditionalBankingDetails) Then
			ThereAreCellsWithUndefinedElement = False;
		EndIf;
		
		// the dimension is not defined in the rows - let's check the columns
		If ThereAreCellsWithUndefinedElement And Column <> Undefined Then
			
			ThereAreCellsWithUndefinedElement = True;
			If ThereIsCertainElementInParentRows(Column, SearchableType, CacheOfAdditionalBankingDetails) Then
				ThereAreCellsWithUndefinedElement = False;
			ElsIf Not ThereIsUndefinedElementOfTypeInSubordinateStrings(Column, SearchableType, CacheOfAdditionalBankingDetails) Then
				ThereAreCellsWithUndefinedElement = False;
			EndIf;
			
		EndIf;
		
		Result.Insert(KeyAndValue.Key, ThereAreCellsWithUndefinedElement);
		
	EndDo;
	
	Return Result;
	
EndFunction

Function NumberOfAdditionalFieldsToCalculateTreeDepth(TreeRow) Export
	
	If TreeRow.ItemKind = Enums.FinancialReportItemKinds.Dimension Then
		AdditionalFields = TreeRow.AdditionalFields;
		If AdditionalFields.Count() Then
			Return AdditionalFields.FindRows(New Structure("InSeparateColumn", True)).Count();
		EndIf;
	EndIf;
	
	Return 0;
	
EndFunction

Function SubordinateElementsOfBudgetView(BudgetProfile) Export
	
	DCS = Catalogs.BudgetProfiles.GetTemplate("AllSubordinateItems");
	Composer = FinancialReportingServer.SchemaComposer(DCS);
	FinancialReportingServer.SetLayoutParameter(Composer, "BudgetProfile", BudgetProfile);
	Result = FinancialReportingServer.UploadDCSResults(DCS, Composer);
	Result.Indexes.Add("Parent");
	
	Return Result;
	
EndFunction

Function CalculateDepthOfLevels(TreeRows, SubjectToAdditionalFields = False, Val Depth = 1, PreviousFlag = False) Export
	
	If Not PreviousFlag Then
		FinalLevelDepth = 1;
	Else
		FinalLevelDepth = Depth;
	EndIf;
	
	Result = FinalLevelDepth;
	ChildItems = FinancialReportingServer.SubordinateRows(TreeRows);
	For Each TreeRow In ChildItems Do
		
		Supplement = 0;
		
		If TreeRow.DisplayWithParent Then
			Supplement = 1;
		EndIf;
		
		If SubjectToAdditionalFields Then
			Supplement = Supplement + NumberOfAdditionalFieldsToCalculateTreeDepth(TreeRow);
			If TreeRow.DisplayWithParent And Not PreviousFlag Then
				// Additional fields of the first of the combined elements
				// are not taken into account in the total number of columns.
				Supplement = Supplement + NumberOfAdditionalFieldsToCalculateTreeDepth(TreeRow.Parent);
			EndIf;
		EndIf;
		
		CurLevelDepth = FinalLevelDepth + Supplement;
		
		Result = Max(Result, CurLevelDepth);
		Result = Max(Result, CalculateDepthOfLevels(TreeRow, SubjectToAdditionalFields, CurLevelDepth, TreeRow.DisplayWithParent));
		
	EndDo;
	
	Return Result;
	
EndFunction

// Returns the sources of the values by type of budget
// 
// Parameters:
// 	BudgetProfile - CatalogRef.BudgetProfiles - LongDesc
// Returns:
// 	ValueTable - LongDesc:
// 		* ReportItem - CatalogRef.FinancialReportItems -
// 		* Source - CatalogRef.FinancialReportItems -
// 		* Object - Characteristic.ItemAttributesOfFinancialReports, String -
// 		* TypeOfCalculatedIndicatorValue - Undefined, String, Characteristic.ItemAttributesOfFinancialReports -
// 		* AddedDocumentValues - Boolean -
//
Function SourcesOfBudgetTypeValues(BudgetProfile) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
		|	FinancialReportItemsValueSources.Ref AS ReportItem,
		|	FinancialReportItemsValueSources.Source,
		|	CASE
		|		WHEN FinancialReportItemsValueSources.Source.ItemKind = VALUE(Enum.FinancialReportItemKinds.BudgetFlowItem)
		|			THEN DetailsArticle.Value
		|		WHEN FinancialReportItemsValueSources.Source.ItemKind = VALUE(Enum.FinancialReportItemKinds.BudgetBalanceItem)
		|			THEN DetailsIndicator.Value
		|		WHEN FinancialReportItemsValueSources.Source.ItemKind = VALUE(Enum.FinancialReportItemKinds.NonFinancialItem)
		|			THEN NFPDetails.Value
		|		WHEN FinancialReportItemsValueSources.Source.ItemKind = VALUE(Enum.FinancialReportItemKinds.EditedValue)
		|			THEN FinancialReportItemsValueSources.Source.NameForPrinting
		|	END AS Object,
		|	ISNULL(DetailsTypeOfCalculatedIndicatorValue.Value, UNDEFINED) AS TypeOfCalculatedIndicatorValue,
		|	FinancialReportItemsValueSources.AddedDocumentValues
		|FROM
		|	Catalog.FinancialReportItems.ValueSources AS FinancialReportItemsValueSources
		|		LEFT JOIN Catalog.FinancialReportItems.ItemKindAttributes AS DetailsArticle
		|		ON FinancialReportItemsValueSources.Source = DetailsArticle.Ref
		|			AND (DetailsArticle.Attribute = &AttributeBudgetItem)
		|		LEFT JOIN Catalog.FinancialReportItems.ItemKindAttributes AS DetailsIndicator
		|		ON FinancialReportItemsValueSources.Source = DetailsIndicator.Ref
		|			AND (DetailsIndicator.Attribute = &Props_Indicator)
		|		LEFT JOIN Catalog.FinancialReportItems.ItemKindAttributes AS NFPDetails
		|		ON FinancialReportItemsValueSources.Source = NFPDetails.Ref
		|			AND (NFPDetails.Attribute = &Props_NFP)
		|		LEFT JOIN Catalog.FinancialReportItems.ItemKindAttributes AS DetailsTypeOfCalculatedIndicatorValue
		|		ON FinancialReportItemsValueSources.Source = DetailsTypeOfCalculatedIndicatorValue.Ref
		|			AND (DetailsTypeOfCalculatedIndicatorValue.Attribute = &Props_TypeOfCalculatedIndicatorValue)
		|WHERE
		|	FinancialReportItemsValueSources.Ref.Owner = &BudgetProfile";
	
	Query.SetParameter("BudgetProfile", BudgetProfile);
	Query.SetParameter("AttributeBudgetItem", ChartsOfCharacteristicTypes.ItemAttributesOfFinancialReports.BudgetFlowItem);
	Query.SetParameter("Props_Indicator", ChartsOfCharacteristicTypes.ItemAttributesOfFinancialReports.BudgetBalanceItem);
	Query.SetParameter("Props_NFP", ChartsOfCharacteristicTypes.ItemAttributesOfFinancialReports.NonFinancialItem);
	Query.SetParameter("Props_TypeOfCalculatedIndicatorValue", ChartsOfCharacteristicTypes.ItemAttributesOfFinancialReports.IndicatorValueType);
	
	SettingsTable = Query.Execute().Unload();
	SettingsTable.Indexes.Add("ReportItem");
	
	Return SettingsTable;
	
EndFunction

#EndRegion 

#EndRegion 

#Region Private

#Region GetDescriptionOfDataSources

// Returns the status of the need to get actual data / budget execution
//
// Parameters:
// 	Source - Structure - Data source of the budget type. contains in the number:
// 		* Id - Number -
// 	GenerationMode - EnumRef.ModesOfBudgetReportGeneration - The mode of formation of the budget report.
// 	Scenario - CatalogRef.BudgetingScenarios - Scenario (actual Data or budget Execution) for which the need to get data is checked.
// 	ForInfluencingItemsOfCalculatedIndicator - Boolean - If True, then the method is called to determine THE Status of articles affecting the calculated indicator.
// 				The default value is False.
//
// Returnable value:
// 	The Line is the Status of the need to receive data:
// 				"Assumed" - the actual data should be received from the source.
// 				"Not intended" - the actual data should not be received.
// 				"Determined by the report setting" - is set by selecting according to the scenario in the budget report.
//
Function SourcePresumablyNeedsActualData(Source, GenerationMode, Scenario, ForInfluencingItemsOfCalculatedIndicator = False)
	
	SourcesTypes = Enums.BudgetingDataSourceTypes;
	
	If Source.Objects = Undefined Then
		Return "NotAssumed";
	EndIf;
	
	If Source.SourceType = SourcesTypes.Balance
	   And Not ForInfluencingItemsOfCalculatedIndicator Then
		Return "Assumed";
	EndIf;
	
	If Source.SourceType = SourcesTypes.NonFinancial Then
		Return "Assumed";
	EndIf;
	
	If Source.SourceType = SourcesTypes.EditedValue Then
		Return "NotAssumed";
	EndIf;
	
	If Source.Id = "Document" Then
		Return "NotAssumed";
	EndIf;
	
	FilterValues = New Array;
	
	If FindSelectionByName(Source.AdditionalSelection, "Scenario", FilterValues) Then
		
		ThereIsSelectionAccordingToScript = FilterValues.Count() > 0;
		If FilterValues.Count() = 1 Then
			For Each FilterValue In FilterValues Do
				
				If FilterValue.ComparisonType = DataCompositionComparisonType.Equal
					And TypeOf(FilterValue.RightValue) = Type("String")
					And Lower(FilterValue.RightValue) = Lower("<FillIn_scene>")
					And GenerationMode = Enums.ModesOfBudgetReportGeneration.Report Then
					
					// In the form of a budget for a data source, there is no measurement with the scenario type,
					// or there is a scenario measurement from register revolutions (measurement type = Register measurement)
					
					If Scenario = Catalogs.BudgetingScenarios.ActualData Then
						If Source.GettingFactsAboutBudgetStructure Then
							Return "Assumed";
						EndIf;
					ElsIf Scenario = Catalogs.BudgetingScenarios.BudgetFulfillment Then
						If Source.GettingBudgetExecutionByBudgetStructure Then
							Return "Assumed";
						EndIf;
					EndIf;
					
					Return "DeterminedByReportSettings";
					
				EndIf;
				
				If FilterValue.ComparisonType = DataCompositionComparisonType.Equal
					And TypeOf(FilterValue.RightValue) = Type("String")
					And Lower(FilterValue.RightValue) = Lower("<FillIn_scene>")
					And GenerationMode <> Enums.ModesOfBudgetReportGeneration.Report Then
					
					ThereIsSelectionAccordingToScript = False;
					
				EndIf;
				
				If FilterValue.ComparisonType = DataCompositionComparisonType.Equal
					And FilterValue.RightValue = Scenario Then
					
					Return "Assumed";
					
				EndIf;
				
				If FilterValue.ComparisonType = DataCompositionComparisonType.NotEqual
					And FilterValue.RightValue <> Scenario Then
					
					Return "Assumed";
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
		// If there is a complex selection, then we will get a scenario using the SKD.
		// If the selection is specified in a group, in a group from the list, then when changing the parent for predefined scenarios, you will need to reset the settings cache.
		If ThereIsSelectionAccordingToScript Then
			If ScriptIsRequiredUnderConditionOfAdditionalSelectionOfDataSource(Scenario, Source.AdditionalSelection.Filter) Then
				Return "Assumed";
			Else
				Return "NotAssumed";
			EndIf;
		EndIf;
		
	EndIf;
	
	If Scenario = Catalogs.BudgetingScenarios.ActualData Then
		If Source.GettingFactsAboutBudgetStructure Then
			Return "Assumed";
		ElsIf Source.GettingScriptFromReportHeader Then
			Return "DeterminedByReportSettings";
		EndIf;
	ElsIf Scenario = Catalogs.BudgetingScenarios.BudgetFulfillment Then
		If Source.GettingBudgetExecutionByBudgetStructure Then
			Return "Assumed";
		ElsIf Source.GettingScriptFromReportHeader Then
			Return "DeterminedByReportSettings";
		EndIf;
	EndIf;
	
	Return "NotAssumed";
	
EndFunction

Function ExpressingDataSourceGroupingPeriod(ReportItem, ColumnStructure1, AttributeCache)
	
	AddAttributes = ChartsOfCharacteristicTypes.ItemAttributesOfFinancialReports;
	
	PeriodOfShift = FinancialReportingServer.ValueOfAdditionalProps(
																ReportItem, 
																AddAttributes.PeriodOfShift,
																AttributeCache);
	
	If ValueIsFilled(PeriodOfShift) Then
		OffsetFrequency = FinancialReportingServer.ValueOfAdditionalProps(
																ReportItem, 
																AddAttributes.OffsetFrequency,
																AttributeCache);
		If Not ValueIsFilled(OffsetFrequency) Then
			OffsetFrequency = Undefined;
		EndIf;
	Else
		PeriodOfShift = Undefined;
	EndIf;
	
	If ColumnStructure1.Periodicity_.Count() Then
		
		MinimumPeriodicity = BudgetReportingClientServer.MinimumPeriodicity(ColumnStructure1.Periodicity_);
		
		FieldText = "PlanningPeriod";
		
		If ValueIsFilled(PeriodOfShift) And ValueIsFilled(OffsetFrequency) Then
			
			FieldText = StringFunctionsClientServer.SubstituteParametersToString(
				"DATEADD(%1, %2, %3)",
				"PlanningPeriod",
				FinancialReportingClientServerCached.PeriodicityByString(OffsetFrequency),
				PeriodOfShift);
			
		EndIf;
		
		If MinimumPeriodicity = Enums.Periodicity.Week Then
			
			FieldText = StringFunctionsClientServer.SubstituteParametersToString(
				"CASE
				|	WHEN BEGINOFPERIOD(%1, %2) < &BeginOfPeriod
				|		THEN &BeginOfPeriod ELSE BEGINOFPERIOD(%1, %2)
				|END",
				FieldText,
				FinancialReportingClientServerCached.PeriodicityByString(MinimumPeriodicity));
			
		Else
			
			FieldText = StringFunctionsClientServer.SubstituteParametersToString(
				"BEGINOFPERIOD(%1, %2)",
				FieldText,
				FinancialReportingClientServerCached.PeriodicityByString(MinimumPeriodicity));
			
		EndIf;
		
	Else
		
		FieldText = "Undefined";
		
	EndIf;
	
	Return FieldText;
	
EndFunction

Function ExpressingPeriodBoundaryOfDataSource(SourceType, FieldName, ReportItem, ColumnStructure1, AttributeCache)
	
	AddAttributes = ChartsOfCharacteristicTypes.ItemAttributesOfFinancialReports;
	ThisIsBoundaryOfActualData = False;
	
	PeriodOfShift = FinancialReportingServer.ValueOfAdditionalProps(
		ReportItem,
		AddAttributes.PeriodOfShift,
		AttributeCache);
	
	If ValueIsFilled(PeriodOfShift) Then
		OffsetFrequency = FinancialReportingServer.ValueOfAdditionalProps(
			ReportItem, 
			AddAttributes.OffsetFrequency,
			AttributeCache);
		If Not ValueIsFilled(OffsetFrequency) Then
			OffsetFrequency = Undefined;
		EndIf;
	Else
		PeriodOfShift = Undefined;
	EndIf;
	
	If SourceType = Enums.BudgetingDataSourceTypes.NonFinancial Then
		Formula = "&" + FieldName;
	Else
		
		Formula = ?(FieldName = "BeginOfPeriod", "LowerBoundOfData", "UpperBoundOfData");
		Formula = FinancialReportingServer.ValueOfAdditionalProps(
			ReportItem,
			AddAttributes[Formula],
			AttributeCache);
		
		Formula = Lower(Formula); // Preparing a formula for case-sensitive search
		
		PeriodVariables = BudgetReportingClientServer.VariablesOfBudgetingPeriods();
		ThisIsBoundaryOfActualData = StrFind(Formula, Lower(PeriodVariables.ActualDataLimit.Name));
		
		Formula = StrReplace(Formula, Lower(PeriodVariables.DataPeriodStart.Name), "&BeginOfPeriod");
		Formula = StrReplace(Formula, Lower(PeriodVariables.DataPeriodEnd.Name), "&EndOfPeriod");
		Formula = StrReplace(Formula, Lower(PeriodVariables.ActualDataLimit.Name), "&ActualDataLimit");
		
		// for comparability of formulas, we will remove auxiliary user characters
		RemoveExtraSpacesFromFormula(Formula);
		
	EndIf;
	
	If ValueIsFilled(PeriodOfShift) And ValueIsFilled(OffsetFrequency) Then
		
		SignOffset = "-";
		
		Formula = StringFunctionsClientServer.SubstituteParametersToString(
			"DATEADD(%1, %2, %3%4)",
			Formula,
			FinancialReportingClientServerCached.PeriodicityByString(OffsetFrequency),
			SignOffset,
			PeriodOfShift);
		
	EndIf;
	
	If FieldName = "EndOfPeriod" Then
		If Not ValueIsFilled(OffsetFrequency) Then
			PeriodBringingToEnd = "Day";
		Else
			PeriodBringingToEnd = FinancialReportingClientServerCached.PeriodicityByString(OffsetFrequency);
		EndIf;
		If ThisIsBoundaryOfActualData Then
			PeriodBringingToEnd = "Day";
		EndIf;
		Formula = StringFunctionsClientServer.SubstituteParametersToString(
			"ENDOFPERIOD(%1, %2)",
			Formula,
			PeriodBringingToEnd);
	EndIf;
	
	Return Formula;
	
EndFunction

Procedure RemoveExtraSpacesFromFormula(Formula)
	
	// The same period expression in different articles can be written with different formatting of the formula string.
	// In order to understand when defining data sources that they can be the same expression, we give transformations.
	
	Formula = StrReplace(Formula, Chars.LF, " ");
	Formula = StrReplace(Formula, Chars.Tab, " ");
	Formula = TrimAll(Formula);
	
	// The parameter names are enclosed in []. We do not make substitutions inside tags.
	OperandStartTag = "[";
	OperandEndTag = "]";
	
	RestOfFormula = Formula;
	PartsOfFormula = New Array;
	
	NumberOfOperandStartSymbol = StrFind(RestOfFormula, OperandStartTag);
	While NumberOfOperandStartSymbol > 0 Do
		
		PartsOfFormula.Add(Mid(RestOfFormula, 1, NumberOfOperandStartSymbol - 1));
		
		RestOfFormula = Mid(RestOfFormula, NumberOfOperandStartSymbol);
		OperandEndCharacterNumber = StrFind(RestOfFormula, OperandEndTag);
		
		If OperandEndCharacterNumber = 0 Then
			PartsOfFormula.Add(RestOfFormula);
			RestOfFormula = "";
		Else
			PartsOfFormula.Add(Mid(RestOfFormula, 1, OperandEndCharacterNumber));
			RestOfFormula = Mid(RestOfFormula, OperandEndCharacterNumber + 1);
		EndIf;
		
		NumberOfOperandStartSymbol = StrFind(RestOfFormula, OperandStartTag);
		
	EndDo;
	If Not IsBlankString(RestOfFormula) Then
		PartsOfFormula.Add(RestOfFormula);
	EndIf;
	
	PartsOfFormulaAccordingToWords = New Array;
	For Each PartOfFormula In PartsOfFormula Do
		PartOfFormula = TrimAll(PartOfFormula);
		If Left(PartOfFormula, 1) = OperandStartTag Then
			PartsOfFormulaAccordingToWords.Add(PartOfFormula);
		Else
			OperatorsOfFormulaPart = StrSplit(PartOfFormula, " ", False);
			For Each Operator In OperatorsOfFormulaPart Do
				PartsOfFormulaAccordingToWords.Add(Operator);
			EndDo;
		EndIf;
	EndDo;
	
	// For example, "CHOOSING WHEN(-1=1) THEN 1 OTHERWISE 2 IS THE END/1"
	// Analyzing parts of the formula, we collect the formula back
	CharactersOnLeftThatDoNotRequireSeparator = New Array;
	CharactersOnLeftThatDoNotRequireSeparator.Add("(");
	CharactersOnLeftThatDoNotRequireSeparator.Add(",");
	CharactersOnLeftThatDoNotRequireSeparator.Add("+");
	CharactersOnLeftThatDoNotRequireSeparator.Add("-");
	CharactersOnLeftThatDoNotRequireSeparator.Add("*");
	CharactersOnLeftThatDoNotRequireSeparator.Add("/");
	CharactersOnLeftThatDoNotRequireSeparator.Add("=");
	CharactersOnLeftThatDoNotRequireSeparator.Add("<");
	CharactersOnLeftThatDoNotRequireSeparator.Add(">");
	
	CharactersOnRightThatDoNotRequireSeparator = New Array;
	CharactersOnRightThatDoNotRequireSeparator.Add(")");
	CharactersOnRightThatDoNotRequireSeparator.Add(",");
	CharactersOnRightThatDoNotRequireSeparator.Add("+");
	CharactersOnRightThatDoNotRequireSeparator.Add("-");
	CharactersOnRightThatDoNotRequireSeparator.Add("*");
	CharactersOnRightThatDoNotRequireSeparator.Add("/");
	CharactersOnRightThatDoNotRequireSeparator.Add("=");
	CharactersOnRightThatDoNotRequireSeparator.Add("<");
	CharactersOnRightThatDoNotRequireSeparator.Add(">");
	
	Formula = "";
	ArrivingPartOfFormula = "";
	For Each PartOfFormula In PartsOfFormulaAccordingToWords Do
		If Formula = "" Then
			Formula = PartOfFormula;
		Else
			SeparatorRequired = True;
			For Each SPECCHARACTER In CharactersOnLeftThatDoNotRequireSeparator Do
				If Right(ArrivingPartOfFormula, 1) = SPECCHARACTER Then
					SeparatorRequired = False;
					Break;
				EndIf;
			EndDo;
			If SeparatorRequired Then
				For Each SPECCHARACTER In CharactersOnRightThatDoNotRequireSeparator Do
					If Left(PartOfFormula, 1) = SPECCHARACTER Then
						SeparatorRequired = False;
						Break;
					EndIf;
				EndDo;
			EndIf;
			Formula = Formula + ?(SeparatorRequired, " ", "") + PartOfFormula;
		EndIf;
		ArrivingPartOfFormula = PartOfFormula;
	EndDo;
	
EndProcedure

Procedure RemoveCertainDimensionsFromSelection(ReportRow, AdditionalSelection, CacheStructure)
	
	List = New ValueList;
	SelectionParameters_2 = FilterAvailabilityParameters(ReportRow, , CacheStructure);
	For Each KeyAndValue In SelectionParameters_2 Do
		If Not SelectionParameters_2[KeyAndValue.Key] Then
			FindSelectionByName(AdditionalSelection, KeyAndValue.Key, List);
		EndIf;
	EndDo;
	
	For Each FilterElement In List Do
		Filter = AdditionalSelection.Filter; // DataCompositionFilter
		Filter.Items.Delete(FilterElement.Value);
	EndDo;
	
EndProcedure

// the constructor function create a source
// 
// Returns:
// 	Structure - LongDesc:
// * PrivilegedMode - Boolean -
// * ItemsList - Array of CatalogRef.FinancialReportItems -
// * GettingScriptFromReportHeader - Arbitrary -
// * GettingBudgetExecutionByBudgetStructure - Arbitrary -
// * GettingFactsAboutBudgetStructure - Arbitrary -
// * GettingPlanForBudgetStructure - Arbitrary -
// * ThereAreTargets_ - Boolean -
// * Id - String -
// * OffsetFrequency - Arbitrary -
// * PeriodOfShift - Arbitrary -
// * AdditionalSelection - DataCompositionSettings -
// * ExpressionEndOfPeriod - String -
// * ExpressionStartOfPeriod - String -
// * ExpressionOfGroupingPeriod - String -
// * Objects - Array -
// * SourceType - EnumRef.BudgetingDataSourceTypes -
Function NewSource()
	
	SourceStructure_ = New Structure;
	
	SourceStructure_.Insert("SourceType", Enums.BudgetingDataSourceTypes.EmptyRef());
	SourceStructure_.Insert("Objects", New Array);
	SourceStructure_.Insert("CalculationsRules", New Array);
	SourceStructure_.Insert("ExpressionOfGroupingPeriod", "");
	SourceStructure_.Insert("ExpressionStartOfPeriod", "");
	SourceStructure_.Insert("ExpressionEndOfPeriod", "");
	SourceStructure_.Insert("AdditionalSelection", New DataCompositionSettings);
	SourceStructure_.Insert("PeriodOfShift");
	SourceStructure_.Insert("OffsetFrequency");
	SourceStructure_.Insert("Id", "");
	SourceStructure_.Insert("ThereAreTargets_", False);
	SourceStructure_.Insert("GettingPlanForBudgetStructure");
	SourceStructure_.Insert("GettingFactsAboutBudgetStructure");
	SourceStructure_.Insert("GettingBudgetExecutionByBudgetStructure");
	SourceStructure_.Insert("GettingScriptFromReportHeader");
	SourceStructure_.Insert("ItemsList", New Array); // this is an array of report elements
	SourceStructure_.Insert("PrivilegedMode", False);
	
	Return SourceStructure_;
	
EndFunction

Procedure AddSource_(CacheStructure, FoundSource, SelectedString)
	
	AddAttributes = ChartsOfCharacteristicTypes.ItemAttributesOfFinancialReports;
	CacheOfAdditionalBankingDetails = CacheStructure.CacheOfAdditionalBankingDetails;
	ReportItem = SelectedString.ReportItem;
	
	FoundSource.ItemsList.Add(ReportItem);
	
	If FoundSource.Objects = Undefined Then
		Return;
	EndIf;
	
	ItemKind = Common.ObjectAttributeValue(ReportItem, "ItemKind");
	
	If ItemKind = Enums.FinancialReportItemKinds.BudgetFlowItem Then
		AccountingObject = FinancialReportingServer.ValueOfAdditionalProps(
			ReportItem,
			AddAttributes.BudgetFlowItem,
			CacheOfAdditionalBankingDetails);
	ElsIf ItemKind = Enums.FinancialReportItemKinds.BudgetBalanceItem Then
		AccountingObject = FinancialReportingServer.ValueOfAdditionalProps(
			ReportItem,
			AddAttributes.BudgetBalanceItem,
			CacheOfAdditionalBankingDetails);
	ElsIf ItemKind = Enums.FinancialReportItemKinds.NonFinancialItem Then
		AccountingObject = FinancialReportingServer.ValueOfAdditionalProps(
			ReportItem,
			AddAttributes.NonFinancialItem,
			CacheOfAdditionalBankingDetails);
	ElsIf ItemKind = Enums.FinancialReportItemKinds.EditedValue Then
		AccountingObject = SelectedString.NameForPrinting;
	EndIf;
	
	If FoundSource.Objects.Find(AccountingObject) = Undefined Then
		FoundSource.Objects.Add(AccountingObject);
	EndIf;
	
	CalculationsRules = New Array;
	If ItemKind = Enums.FinancialReportItemKinds.BudgetFlowItem Then
		CalculationsRules = Common.ObjectAttributeValue(
			ReportItem, "CalculationsRules.Rule").Unload().UnloadColumn("Rule");
	ElsIf ItemKind = Enums.FinancialReportItemKinds.BudgetBalanceItem Then
		CalculationsRules = Catalogs.RuleForCalculatingRelatedBudgetBalancesAndTurnovers.RulesForCalculatingBudgetIndicatorItem(
			AccountingObject);
	EndIf;
	CommonClientServer.SupplementArray(FoundSource.CalculationsRules, CalculationsRules, True);
	
EndProcedure

Procedure AddSource(CacheStructure, Sources, SelectedString, ColumnStructure1, AdditionalSourceParameters)
	
	SourceDocument_ = AdditionalSourceParameters.SourceDocument_;
	GettingPlanForBudgetStructure = AdditionalSourceParameters.GettingPlanForBudgetStructure;
	GettingFactsAboutBudgetStructure = AdditionalSourceParameters.GettingFactsAboutBudgetStructure;
	GettingBudgetExecutionByBudgetStructure = AdditionalSourceParameters.GettingBudgetExecutionByBudgetStructure;
	GettingScriptFromReportHeader   = AdditionalSourceParameters.GettingScriptFromReportHeader;
	
	ReportItem = SelectedString.ReportItem;
	
	AddAttributes = ChartsOfCharacteristicTypes.ItemAttributesOfFinancialReports;
	CacheOfAdditionalBankingDetails = CacheStructure.CacheOfAdditionalBankingDetails;
	
	SourceStructure_ = NewSource();
	
	ItemKind = Common.ObjectAttributeValue(ReportItem, "ItemKind");
	
	CalculationsRules = New Array;
	
	If ItemKind = Enums.FinancialReportItemKinds.BudgetFlowItem Then
		AccountingObject = FinancialReportingServer.ValueOfAdditionalProps(
			ReportItem,
			AddAttributes.BudgetFlowItem,
			CacheOfAdditionalBankingDetails);
		Array = CommonClientServer.ValueInArray(AccountingObject);
		CalculationsRules = Common.ObjectAttributeValue(
			ReportItem, "CalculationsRules.Rule").Unload().UnloadColumn("Rule");
	ElsIf ItemKind = Enums.FinancialReportItemKinds.BudgetBalanceItem Then
		AccountingObject = FinancialReportingServer.ValueOfAdditionalProps(
			ReportItem,
			AddAttributes.BudgetBalanceItem,
			CacheOfAdditionalBankingDetails);
		Array = CommonClientServer.ValueInArray(AccountingObject);
		CalculationsRules = Catalogs.RuleForCalculatingRelatedBudgetBalancesAndTurnovers.RulesForCalculatingBudgetIndicatorItem(
			AccountingObject);
	ElsIf ItemKind = Enums.FinancialReportItemKinds.NonFinancialItem Then
		AccountingObject = FinancialReportingServer.ValueOfAdditionalProps(
			ReportItem,
			AddAttributes.NonFinancialItem,
			CacheOfAdditionalBankingDetails);
		Array = CommonClientServer.ValueInArray(AccountingObject);
	ElsIf ItemKind = Enums.FinancialReportItemKinds.EditedValue Then
		AccountingObject = Common.ObjectAttributeValue(ReportItem, "NameForPrinting");
		Array = CommonClientServer.ValueInArray(AccountingObject);
	Else
		Array = Undefined;
	EndIf;
	
	SourcesTypes = Enums.BudgetingDataSourceTypes;
	
	If SourceDocument_ Then
		If ItemKind = Enums.FinancialReportItemKinds.EditedValue Then
			SourceStructure_.Insert("SourceType", SourcesTypes.EditedValue);
		Else
			SourceStructure_.Insert("SourceType", SourcesTypes.Real);
		EndIf;
	ElsIf ItemKind = Enums.FinancialReportItemKinds.EditedValue Then
		SourceStructure_.Insert("SourceType", SourcesTypes.EditedValue);
	ElsIf ItemKind = Enums.FinancialReportItemKinds.BudgetFlowItem
		Or ItemKind = Enums.FinancialReportItemKinds.AllBudgetFlowItems Then
		SourceStructure_.Insert("SourceType", SourcesTypes.Turnovers);
	ElsIf ItemKind = Enums.FinancialReportItemKinds.BudgetBalanceItem
		Or ItemKind = Enums.FinancialReportItemKinds.AllBudgetBalanceItems Then
		SourceStructure_.Insert("SourceType", SourcesTypes.Balance);
	ElsIf ItemKind = Enums.FinancialReportItemKinds.NonFinancialItem Then
		SourceStructure_.Insert("SourceType", SourcesTypes.NonFinancial);
	EndIf;
	
	SourceStructure_.Insert("Objects", Array);
	SourceStructure_.Insert("CalculationsRules", CalculationsRules);
	
	SourceStructure_.Insert("ExpressionOfGroupingPeriod", ExpressingDataSourceGroupingPeriod(
		ReportItem,
		ColumnStructure1,
		CacheOfAdditionalBankingDetails));
	
	SourceStructure_.Insert("ExpressionStartOfPeriod", ExpressingPeriodBoundaryOfDataSource(
		SourceStructure_.SourceType, 
		"BeginOfPeriod",
		ReportItem, 
		ColumnStructure1, 
		CacheOfAdditionalBankingDetails));
	
	SourceStructure_.Insert("ExpressionEndOfPeriod", ExpressingPeriodBoundaryOfDataSource(
		SourceStructure_.SourceType, 
		"EndOfPeriod",
		ReportItem, 
		ColumnStructure1, 
		CacheOfAdditionalBankingDetails));
	
	PeriodOfShift = FinancialReportingServer.ValueOfAdditionalProps(
		ReportItem, 
		AddAttributes.PeriodOfShift,
		CacheOfAdditionalBankingDetails);
	OffsetFrequency = FinancialReportingServer.ValueOfAdditionalProps(
		ReportItem, 
		AddAttributes.OffsetFrequency,
		CacheOfAdditionalBankingDetails);
	SourceStructure_.Insert("PeriodOfShift", PeriodOfShift);
	SourceStructure_.Insert("OffsetFrequency", OffsetFrequency);
	
	ItemFilter = Common.ObjectAttributeValue(ReportItem, "AdditionalSelection").Get();
	RemoveCertainDimensionsFromSelection(SelectedString, ItemFilter, CacheStructure);
	SourceStructure_.Insert("AdditionalSelection", ItemFilter);
	
	If SourceDocument_ Then
		If ItemKind = Enums.FinancialReportItemKinds.EditedValue Then
			SourceStructure_.Insert("Id", "Document_Values");
		Else
			SourceStructure_.Insert("Id", "Document");
		EndIf;
	Else
		SourceStructure_.Insert("Id", "ID_" + Format(Sources.Count(), "NZ=; NG=0"));
	EndIf;
	
	SourceStructure_.Insert("ThereAreTargets_", False);
	If SourceStructure_.SourceType = Enums.BudgetingDataSourceTypes.Turnovers Then
		ReportElementArticle = FinancialReportingServer.ValueOfAdditionalProps(
			ReportItem, 
			AddAttributes.BudgetFlowItem,
			CacheOfAdditionalBankingDetails);
		If TypeOf(ReportElementArticle) = Type("CatalogRef.BudgetBalanceItems") Then
			SourceStructure_.Insert("ThereAreTargets_", True);
		EndIf;
	EndIf;
	SourceStructure_.Insert("GettingPlanForBudgetStructure", GettingPlanForBudgetStructure);
	SourceStructure_.Insert("GettingFactsAboutBudgetStructure", GettingFactsAboutBudgetStructure);
	SourceStructure_.Insert("GettingBudgetExecutionByBudgetStructure", GettingBudgetExecutionByBudgetStructure);
	SourceStructure_.Insert("GettingScriptFromReportHeader",   GettingScriptFromReportHeader);
	
	SourceStructure_.Insert("ItemsList", New Array);
	SourceStructure_.ItemsList.Add(ReportItem);
	SourceStructure_.Insert("PrivilegedMode", 
		?(SelectedString.PrivilegedMode = Undefined, False, SelectedString.PrivilegedMode));
	
	Sources.Add(SourceStructure_);
	
EndProcedure

Function CompareSources(CacheStructure, Source, SelectedString, ColumnStructure1, AdditionalSourceParameters)
	
	SourceDocument_ = AdditionalSourceParameters.SourceDocument_;
	GettingPlanForBudgetStructure = AdditionalSourceParameters.GettingPlanForBudgetStructure;
	GettingFactsAboutBudgetStructure = AdditionalSourceParameters.GettingFactsAboutBudgetStructure;
	GettingBudgetExecutionByBudgetStructure = AdditionalSourceParameters.GettingBudgetExecutionByBudgetStructure;
	GettingScriptFromReportHeader   = AdditionalSourceParameters.GettingScriptFromReportHeader;
	
	SourcesTypes = Enums.BudgetingDataSourceTypes;
	
	ReportItem = SelectedString.ReportItem;
	
	AddAttributes = ChartsOfCharacteristicTypes.ItemAttributesOfFinancialReports;
	CacheOfAdditionalBankingDetails = CacheStructure.CacheOfAdditionalBankingDetails;
	AttributeCache = CacheStructure.AttributeCache;
	
	TypeOfComparisonElement = ValueOfBudgetViewElementSProps(ReportItem, "ItemKind", AttributeCache);
	
	If TypeOfComparisonElement = Enums.FinancialReportItemKinds.BudgetFlowItem Then
		
		If SourceDocument_ Then
			If Source.SourceType <> SourcesTypes.Real Then
				Return False;
			EndIf;
		Else
			If Source.SourceType <> SourcesTypes.Turnovers Then
				Return False;
			EndIf;
		EndIf;
		
		ReportElementArticle = FinancialReportingServer.ValueOfAdditionalProps(ReportItem,
			AddAttributes.BudgetFlowItem,
			CacheOfAdditionalBankingDetails);
		
		If TypeOf(ReportElementArticle) = Type("CatalogRef.BudgetBalanceItems") Then
			ThereAreTargets_ = True;
		Else
			ThereAreTargets_ = False;
		EndIf;
		If ThereAreTargets_ <> Source.ThereAreTargets_ Then
			Return False;
		EndIf;
		
		If GettingPlanForBudgetStructure <> Source.GettingPlanForBudgetStructure
			Or GettingFactsAboutBudgetStructure <> Source.GettingFactsAboutBudgetStructure
			Or GettingBudgetExecutionByBudgetStructure <> Source.GettingBudgetExecutionByBudgetStructure
			Or GettingScriptFromReportHeader <> Source.GettingScriptFromReportHeader Then
			Return False;
		EndIf;
		
		If Source.Objects = Undefined Then
			// We do not combine these articles and all articles, because the behavior is different
			Return False;
		EndIf;
		
		CalculationsRules = Common.ObjectAttributeValue(ReportItem,
			"CalculationsRules.Rule").Unload().UnloadColumn("Rule");
		If CalculationsRules.Count() = 0 And Source.CalculationsRules.Count() > 0
			Or CalculationsRules.Count() > 0 And Source.CalculationsRules.Count() = 0 Then
			Return False;
		EndIf;
		
	ElsIf TypeOfComparisonElement = Enums.FinancialReportItemKinds.AllBudgetFlowItems Then
		
		If Source.SourceType <> SourcesTypes.Turnovers Then
			Return False;
		EndIf;
		
		If GettingPlanForBudgetStructure <> Source.GettingPlanForBudgetStructure
			Or GettingFactsAboutBudgetStructure <> Source.GettingFactsAboutBudgetStructure
			Or GettingBudgetExecutionByBudgetStructure <> Source.GettingBudgetExecutionByBudgetStructure
			Or GettingScriptFromReportHeader <> Source.GettingScriptFromReportHeader Then
			Return False;
		EndIf;
		
		If Not Source.Objects = Undefined Then
			// We do not combine these articles and all articles, because the behavior is different
			Return False;
		EndIf;
		
	ElsIf TypeOfComparisonElement = Enums.FinancialReportItemKinds.NonFinancialItem Then
		
		If Source.SourceType <> SourcesTypes.NonFinancial Then
			Return False;
		EndIf;
		
		If GettingPlanForBudgetStructure <> Source.GettingPlanForBudgetStructure
			Or GettingFactsAboutBudgetStructure <> Source.GettingFactsAboutBudgetStructure
			Or GettingBudgetExecutionByBudgetStructure <> Source.GettingBudgetExecutionByBudgetStructure
			Or GettingScriptFromReportHeader <> Source.GettingScriptFromReportHeader Then
			Return False;
		EndIf;
		
	ElsIf TypeOfComparisonElement = Enums.FinancialReportItemKinds.EditedValue Then
		
		If Source.SourceType <> SourcesTypes.EditedValue Then
			Return False;
		EndIf;
		
	ElsIf TypeOfComparisonElement = Enums.FinancialReportItemKinds.BudgetBalanceItem
		Or TypeOfComparisonElement = Enums.FinancialReportItemKinds.AllBudgetBalanceItems Then
		
		If Source.SourceType <> SourcesTypes.Balance Then
			Return False;
		EndIf;
		
		If GettingPlanForBudgetStructure <> Source.GettingPlanForBudgetStructure
			Or GettingFactsAboutBudgetStructure <> Source.GettingFactsAboutBudgetStructure
			Or GettingBudgetExecutionByBudgetStructure <> Source.GettingBudgetExecutionByBudgetStructure
			Or GettingScriptFromReportHeader <> Source.GettingScriptFromReportHeader Then
			Return False;
		EndIf;
		
		If TypeOfComparisonElement = Enums.FinancialReportItemKinds.BudgetBalanceItem Then
			If Source.Objects = Undefined Then
				// We do not combine these indicators and all indicators, because the behavior is different
				Return False;
			EndIf;
		Else // AllBudgetBalanceItems
			If Not Source.Objects = Undefined Then
				// We do not combine these indicators and all indicators, because the behavior is different
				Return False;
			EndIf;
		EndIf;
		
	Else
		
		Raise NStr("vi = 'Loại nguồn dữ liệu không chính xác';
					|ru = 'Неверный тип источника данных';
					|en = 'Incorrect data source type'; fa = 'Incorrect data source type';
					|it = 'Tipo di origine dei dati errato';
					|pl = 'Nieprawidłowy typ źródła danych';
					|tr = 'Geçersiz veri kaynağı türü'");
		
	EndIf;
	
	If Not SourceDocument_ Then
		
		ExpressionOfGroupingPeriod = ExpressingDataSourceGroupingPeriod(
			ReportItem,
			ColumnStructure1,
			CacheOfAdditionalBankingDetails);
		
		If ExpressionOfGroupingPeriod <> Source.ExpressionOfGroupingPeriod Then
			Return False;
		EndIf;
		
		ExpressionStartOfPeriod = ExpressingPeriodBoundaryOfDataSource(
			Source.SourceType, 
			"BeginOfPeriod",
			ReportItem, 
			ColumnStructure1, 
			CacheOfAdditionalBankingDetails);
		
		If ExpressionStartOfPeriod <> Source.ExpressionStartOfPeriod Then
			Return False;
		EndIf;
		
		ExpressionEndOfPeriod = ExpressingPeriodBoundaryOfDataSource(
			Source.SourceType, 
			"EndOfPeriod",
			ReportItem, 
			ColumnStructure1, 
			CacheOfAdditionalBankingDetails);
		
		If ExpressionEndOfPeriod <> Source.ExpressionEndOfPeriod Then
			Return False;
		EndIf;
		
		SelectionRepository = ValueOfBudgetViewElementSProps(
				ReportItem, "AdditionalSelection", AttributeCache); // ValueStorage
		ItemFilter = SelectionRepository.Get(); // DataCompositionSettings, DataCompositionFilterItemCollection - 
		RemoveCertainDimensionsFromSelection(SelectedString, ItemFilter, CacheStructure);
		
		If Not CompareSelections(Source.AdditionalSelection, ItemFilter) Then
			Return False;
		EndIf;
		
	EndIf;
	
	SelectedStringPrivilegedMode = FinancialReportingServer.ValueOfAdditionalProps(ReportItem,
		AddAttributes.PrivilegedMode,
		CacheOfAdditionalBankingDetails);
	
	If SelectedStringPrivilegedMode = Undefined Then
		SelectedStringPrivilegedMode = False;
	EndIf;
	
	If SelectedStringPrivilegedMode <> Source.PrivilegedMode Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

Function FindSource(CacheStructure, Sources, SelectedString, ColumnStructure1, AdditionalSourceParameters)
	
	For Each Source In Sources Do
		If CompareSources(CacheStructure, Source, SelectedString, ColumnStructure1, AdditionalSourceParameters) Then
			Return Source;
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

Procedure FillSourcesByElementType(Sources, CacheStructure, DescriptionOfStructureOfBudgetElements, ItemKind, ParametersForFillingSources)
	
	ColumnStructure1 = DescriptionOfStructureOfBudgetElements.ColumnStructure1;
	BudgetItemTree = DescriptionOfStructureOfBudgetElements.BudgetItemTree;
	
	RecursiveRetrievalOfSourcesForArticles = ParametersForFillingSources.RecursiveRetrievalOfSourcesForArticles;
	GenerationMode = ParametersForFillingSources.GenerationMode;
	
	PickedRows = BudgetItemTree.Rows.FindRows(New Structure("ItemKind", ItemKind), True);
	
	ScriptsInStructureForElements = SignsForSettingBudgetStructureScenarios(PickedRows,
		ItemKind,
		CacheStructure,
		DescriptionOfStructureOfBudgetElements,
		ParametersForFillingSources);
	
	For Each SelectedString In PickedRows Do
		
		If ItemKind = Enums.FinancialReportItemKinds.AllBudgetFlowItems Then
			
			RootItem = FinancialReportingServer.RootItem(SelectedString,
				Enums.FinancialReportItemKinds.BudgetBalanceItem);
			If RootItem <> Undefined Then
				Continue;
			EndIf;
			RootItem = FinancialReportingServer.RootItem(SelectedString,
				Enums.FinancialReportItemKinds.AllBudgetBalanceItems);
			If RootItem <> Undefined Then
				Continue;
			EndIf;
			
			RootItem = FinancialReportingServer.RootItem(SelectedString,
				Enums.FinancialReportItemKinds.CellsSettings);
			If RootItem = Undefined Then
				RootItem = FinancialReportingServer.RootItem(SelectedString,
					Enums.FinancialReportItemKinds.ComplexTable);
				If RootItem <> Undefined Then
					Continue;
				EndIf;
			EndIf;
			
		EndIf;
		
		If ItemKind = Enums.FinancialReportItemKinds.AllBudgetBalanceItems Then
			
			RootItem = FinancialReportingServer.RootItem(SelectedString,
				Enums.FinancialReportItemKinds.CellsSettings);
			If RootItem = Undefined Then
				RootItem = FinancialReportingServer.RootItem(SelectedString,
					Enums.FinancialReportItemKinds.ComplexTable);
				If RootItem <> Undefined Then
					Continue;
				EndIf;
			EndIf;
			
		EndIf;
		
		SourceDocument_ = False;
		
		If (GenerationMode = Enums.ModesOfBudgetReportGeneration.Document
				Or GenerationMode = Enums.ModesOfBudgetReportGeneration.PrintBudget)
			And ItemKind = Enums.FinancialReportItemKinds.BudgetFlowItem Then
			
			Parent = SelectedString.Parent;
			If Not ValueIsFilled(Parent) 
				Or Not Parent.ItemKind = Enums.FinancialReportItemKinds.DerivedItem Then
				SourceDocument_ = True;
			EndIf;
			
		EndIf;
		
		If (GenerationMode = Enums.ModesOfBudgetReportGeneration.Document
				Or GenerationMode = Enums.ModesOfBudgetReportGeneration.PrintBudget)
			And ItemKind = Enums.FinancialReportItemKinds.EditedValue Then
			
			SourceDocument_ = True;
			
		EndIf;
		
		If GenerationMode <> Enums.ModesOfBudgetReportGeneration.FillType Then
			Parent = SelectedString.Parent;
			If ValueIsFilled(Parent) 
				And Parent.ItemKind = Enums.FinancialReportItemKinds.BudgetFlowItem
				And Not RecursiveRetrievalOfSourcesForArticles Then
				// The filling mechanisms should not be involved in the sources.
				Continue;
			EndIf;
		EndIf;
		
		AdditionalSourceParameters = New Structure;
		AdditionalSourceParameters.Insert("SourceDocument_", SourceDocument_);
		AdditionalSourceParameters.Insert("GettingPlanForBudgetStructure", False);
		AdditionalSourceParameters.Insert("GettingFactsAboutBudgetStructure", False);
		AdditionalSourceParameters.Insert("GettingBudgetExecutionByBudgetStructure", False);
		AdditionalSourceParameters.Insert("GettingScriptFromReportHeader", False);
		
		SourceElement_ = BudgetSourceElement(SelectedString, ItemKind, CacheStructure);
		ElementScenarios = Undefined;
		If Not SourceElement_ = Undefined Then
			ElementScenarios = ScriptsInStructureForElements.Get(SourceElement_);
		EndIf;
		If Not ElementScenarios = Undefined Then
			FillPropertyValues(AdditionalSourceParameters, ElementScenarios);
		EndIf;
		
		FoundSource = FindSource(
			CacheStructure,
			Sources,
			SelectedString,
			ColumnStructure1,
			AdditionalSourceParameters); // See NewSource
		If FoundSource = Undefined Then
			AddSource(CacheStructure, Sources, SelectedString, ColumnStructure1, AdditionalSourceParameters);
		Else
			AddSource_(CacheStructure, FoundSource, SelectedString);
		EndIf;
		
	EndDo;
	
EndProcedure

Function BudgetSourceElement(ElementViewString, ItemKind, CacheStructure)
	SourceElement_ = Undefined;
	If ItemKind = Enums.FinancialReportItemKinds.AllBudgetFlowItems
		Or ItemKind = Enums.FinancialReportItemKinds.BudgetFlowItem Then
		// The reference of the reference book of budget articles, if all articles are an empty link.
		SourceElement_ = FinancialReportingServer.ValueOfAdditionalProps(ElementViewString.ReportItem,
			"BudgetFlowItem",
			CacheStructure.CacheOfAdditionalBankingDetails);
	ElsIf ItemKind = Enums.FinancialReportItemKinds.AllBudgetBalanceItems
		Or ItemKind = Enums.FinancialReportItemKinds.BudgetBalanceItem Then
		// The reference of the Budget indicator directory, if all indicators are an empty link.
		SourceElement_ = FinancialReportingServer.ValueOfAdditionalProps(ElementViewString.ReportItem,
			"BudgetBalanceItem",
			CacheStructure.CacheOfAdditionalBankingDetails);
	ElsIf ItemKind = Enums.FinancialReportItemKinds.NonFinancialItem Then
		SourceElement_ = FinancialReportingServer.ValueOfAdditionalProps(ElementViewString.ReportItem,
			"NonFinancialItem",
			CacheStructure.CacheOfAdditionalBankingDetails);
	EndIf;
	
	Return SourceElement_;
EndFunction

Function ScriptIsRequiredUnderConditionOfAdditionalSelectionOfDataSource(Scenario, FilterSource1)
	
	ScenarioSelectionDCS = DataCompositionServer.EmptyCircuit();
	DataSet = DataCompositionServer.AddEmptyDataSet(ScenarioSelectionDCS,
		Type("DataCompositionSchemaDataSetQuery"), "Query");
	DataSet.Query =
	"SELECT
	|	BudgetingScenarios.Ref AS Scenario
	|FROM
	|	Catalog.BudgetingScenarios AS BudgetingScenarios
	|WHERE
	|	BudgetingScenarios.Ref = &ScenarioForAccessingDatabaseData";
	FinancialReportingServer.NewSetField(DataSet, "Scenario", "Scenario", , New TypeDescription("CatalogRef.BudgetingScenarios"));
	DataCompositionServer.AddParameter(ScenarioSelectionDCS, "ScenarioForAccessingDatabaseData", New TypeDescription("CatalogRef.BudgetingScenarios"), Scenario);
	Settings = BudgetingServer.InitializedDefaultSettings(ScenarioSelectionDCS);
	DataCompositionClientServer.DisableOutputOfTotals(Settings);
	
	FinancialReportingServer.CopyFilter(FilterSource1, Settings.Filter, True,,, True);
	
	GroupingSettings = FinancialReportingServer.NewGrouping(Settings.Structure);
	FinancialReportingServer.NewDimensionField(GroupingSettings, "Scenario");
	
	DataAcquisitionTemplate = FinancialReportingServer.PrepareLayoutTemplateForUploadingDCS(ScenarioSelectionDCS, Settings);
	ScenarioDataWithSelection = FinancialReportingServer.UploadDCSResultsFromTemplate(DataAcquisitionTemplate);
	
	Return ScenarioDataWithSelection.Count() > 0;
	
EndFunction

Function SignsForSettingBudgetStructureScenarios(ElementViewStrings, ItemKind, CacheStructure, DescriptionOfStructureOfBudgetElements, ParametersForFillingSources)
	
	AttributesForSettingScriptsBySource = New Map;
	
	RecursiveRetrievalOfSourcesForArticles = ParametersForFillingSources.RecursiveRetrievalOfSourcesForArticles;
	CheckWhetherFactIsNecessaryBasedOnReportStructure = ParametersForFillingSources.CheckWhetherFactIsNecessaryBasedOnReportStructure;
	GenerationMode = ParametersForFillingSources.GenerationMode;
	
	If Not CheckWhetherFactIsNecessaryBasedOnReportStructure Then
		Return AttributesForSettingScriptsBySource;
	EndIf;
	
	If Not ItemKind = Enums.FinancialReportItemKinds.AllBudgetFlowItems
		And Not ItemKind = Enums.FinancialReportItemKinds.AllBudgetBalanceItems
		And Not ItemKind = Enums.FinancialReportItemKinds.BudgetFlowItem
		And Not ItemKind = Enums.FinancialReportItemKinds.BudgetBalanceItem
		And Not ItemKind = Enums.FinancialReportItemKinds.NonFinancialItem Then
		Return AttributesForSettingScriptsBySource;
	EndIf;
	
	For Each SelectedString In ElementViewStrings Do
		
		If ItemKind = Enums.FinancialReportItemKinds.AllBudgetFlowItems Then
			
			RootItem = FinancialReportingServer.RootItem(SelectedString,
				Enums.FinancialReportItemKinds.BudgetBalanceItem);
			If RootItem <> Undefined Then
				Continue;
			EndIf;
			RootItem = FinancialReportingServer.RootItem(SelectedString,
				Enums.FinancialReportItemKinds.AllBudgetBalanceItems);
			If RootItem <> Undefined Then
				Continue;
			EndIf;
			
			RootItem = FinancialReportingServer.RootItem(SelectedString,
				Enums.FinancialReportItemKinds.CellsSettings);
			If RootItem = Undefined Then
				RootItem = FinancialReportingServer.RootItem(SelectedString,
					Enums.FinancialReportItemKinds.ComplexTable);
				If RootItem <> Undefined Then
					Continue;
				EndIf;
			EndIf;
			
		EndIf;
		
		If ItemKind = Enums.FinancialReportItemKinds.AllBudgetBalanceItems Then
			
			RootItem = FinancialReportingServer.RootItem(SelectedString,
				Enums.FinancialReportItemKinds.CellsSettings);
			If RootItem = Undefined Then
				RootItem = FinancialReportingServer.RootItem(SelectedString,
					Enums.FinancialReportItemKinds.ComplexTable);
				If RootItem <> Undefined Then
					Continue;
				EndIf;
			EndIf;
			
		EndIf;
		
		If GenerationMode <> Enums.ModesOfBudgetReportGeneration.FillType Then
			Parent = SelectedString.Parent;
			If ValueIsFilled(Parent) 
				And Parent.ItemKind = Enums.FinancialReportItemKinds.BudgetFlowItem
				And Not RecursiveRetrievalOfSourcesForArticles Then
				// The filling mechanisms should not be involved in the sources.
				Continue;
			EndIf;
		EndIf;
		
		SourceElement_ = BudgetSourceElement(SelectedString, ItemKind, CacheStructure);
		
		SourceAssignmentAttributes = AttributesForSettingScriptsBySource.Get(SourceElement_);
		If SourceAssignmentAttributes = Undefined Then
			SourceAssignmentAttributes = New Structure;
			SourceAssignmentAttributes.Insert("GettingPlanForBudgetStructure", False); // The planned data scenario is specified.
			SourceAssignmentAttributes.Insert("GettingFactsAboutBudgetStructure", False); // The actual data scenario is specified.
			SourceAssignmentAttributes.Insert("GettingBudgetExecutionByBudgetStructure", False); // The budget execution scenario is specified.
			SourceAssignmentAttributes.Insert("GettingScriptFromReportHeader", False); // The scenario formed on the basis of turnover and balances is indicated (indicated in the header of the report).
		EndIf;
		
		AddBudgetStructureToScenarioTaskAttributes(SourceAssignmentAttributes,
			SelectedString,
			DescriptionOfStructureOfBudgetElements,
			CacheStructure);
		
		AttributesForSettingScriptsBySource.Insert(SourceElement_, SourceAssignmentAttributes);
		
	EndDo;
	
	Return AttributesForSettingScriptsBySource;
	
EndFunction

// Complements the structure for specifying scenario attributes for budget type lines.
//
// Parameters:
// 	SourceAssignmentAttributes - Structure - Structure of signs of specifying scenarios in the budget:
// 	 *GettingPlanForBudgetStructure - Boolean - The planned data scenario is specified.
// 	 *GettingFactsAboutBudgetStructure - Boolean - The actual data scenario is specified.
// 	 *GettingBudgetExecutionByBudgetStructure - Boolean - The budget execution scenario is specified.
// 	 *GettingScriptFromReportHeader - Boolean - The scenario formed on the basis of turnover and balances is indicated (indicated in the header of the report).
// 	SelectedString - ValueTreeRow of ValueTree - 
// 	DescriptionOfStructureOfBudgetElements - Structure - Structure of descriptions of the type of budget for which sources are filled in:
// 	 *ColumnStructure1 - Structure - The structure of columns of the budget type.
// 	 *BudgetItemTree - ValueTree - A tree of budget view elements.
// 	 *SettingsTable - ValueTable - Used to refine the source properties of a complex table.
// 	                  - It is uncertain. If you need to check the report factapostructure = False, then the value = It is uncertain.
// 	CacheStructure - Structure - Cached data.
//
Procedure AddBudgetStructureToScenarioTaskAttributes(SourceAssignmentAttributes, SelectedString, DescriptionOfStructureOfBudgetElements, CacheStructure)
	
	SettingsTable = DescriptionOfStructureOfBudgetElements.SettingsTable; // See NewTableOfElements
	CacheOfBudgetTableSettings = DescriptionOfStructureOfBudgetElements.CacheOfBudgetTableSettings;
	
	ParametersForSettingScripts = New Structure;
	ParametersForSettingScripts.Insert("ThereIsScriptForSource", False);
	ParametersForSettingScripts.Insert("ThereIsScenarioPlannedData", False);
	ParametersForSettingScripts.Insert("ThereIsScriptActualData", False);
	ParametersForSettingScripts.Insert("ThereIsScenarioBudgetExecution", False);
	ParametersForSettingScripts.Insert("ThereIsScriptFromReportHeader", False);
	
	ContinueAnalysis = True;
	
	If ContinueAnalysis Then
		RootItem = FinancialReportingServer.RootItem(SelectedString,
			Enums.FinancialReportItemKinds.TableIndicatorsInRows);
			
		If RootItem = Undefined Then
			RootItem = FinancialReportingServer.RootItem(SelectedString,
				Enums.FinancialReportItemKinds.TableIndicatorsInColumns);
		EndIf;
		
		If RootItem <> Undefined Then
			// Scenarios can be set perpendicular to the indicators, i.e. if the indicators are in rows, then in columns,
			// if the indicators are in columns, then the scenarios are in rows.
			ColumnsInRelationToIndicator = Undefined;
			For Each TreeRow In RootItem.Rows Do
				If TreeRow.ItemKind = Enums.FinancialReportItemKinds.Columns
					And RootItem.ItemKind = Enums.FinancialReportItemKinds.TableIndicatorsInRows Then
					
					ColumnsInRelationToIndicator = TreeRow;
				ElsIf TreeRow.ItemKind = Enums.FinancialReportItemKinds.Rows
					And RootItem.ItemKind = Enums.FinancialReportItemKinds.TableIndicatorsInColumns Then
					
					ColumnsInRelationToIndicator = TreeRow;
				EndIf;
			EndDo;
			If Not ParametersForSettingScripts.ThereIsScriptForSource
			   And Not ColumnsInRelationToIndicator = Undefined Then
				// We get cached flags for columns of a simple table
				SavedBudgetTableSettings = CacheOfBudgetTableSettings.Get(RootItem.ReportItem);
				If Not SavedBudgetTableSettings = Undefined Then
					ColumnPropertiesOfSimpleTable = SavedBudgetTableSettings.ColumnPropertiesOfSimpleTable;
					For Each KeyAndValue In ParametersForSettingScripts Do
						ScriptFlagInColumns = ColumnPropertiesOfSimpleTable[KeyAndValue.Key];
						If ScriptFlagInColumns = True Then
							ParametersForSettingScripts[KeyAndValue.Key] = ScriptFlagInColumns;
						EndIf;
					EndDo;
				Else
					TreeElementsContainScripts(ColumnsInRelationToIndicator, ParametersForSettingScripts, "Down", CacheStructure);
					
					ColumnPropertiesOfSimpleTable = Common.CopyRecursive(ParametersForSettingScripts);
					SavedBudgetTableSettings = New Structure;
					SavedBudgetTableSettings.Insert("ColumnPropertiesOfSimpleTable", ColumnPropertiesOfSimpleTable);
					SavedBudgetTableSettings.Insert("TreeRowsByElementsOfComplexTable", Undefined);
					CacheOfBudgetTableSettings.Insert(RootItem.ReportItem, SavedBudgetTableSettings)
				EndIf;
			EndIf;
			If Not ParametersForSettingScripts.ThereIsScriptForSource Then
				// Scenarios can be set either only in columns or only in rows.
				// If the scenarios are specified together with the indicator, then they can be either only higher or only lower than the current indicator.
				TreeElementsContainScripts(SelectedString, ParametersForSettingScripts, "Up", CacheStructure);
			EndIf;
			If Not ParametersForSettingScripts.ThereIsScriptForSource Then
				// Scenarios can be set either only in columns or only in rows.
				// If the scenarios are specified together with the indicator, then they can be either only higher or only lower than the current indicator.
				If SelectedString.Parent <> Undefined
					And SelectedString.Parent.ItemKind = Enums.FinancialReportItemKinds.DerivedItem Then
					CheckString = SelectedString.Parent;
				Else
					CheckString = SelectedString;
				EndIf;
				TreeElementsContainScripts(CheckString, ParametersForSettingScripts, "Down", CacheStructure);
			EndIf;
			
			ContinueAnalysis = False;
		EndIf;
	EndIf;
	
	If ContinueAnalysis Then
		If Not SettingsTable = Undefined Then
			// We check it as a complex table.
			
			RootItem = FinancialReportingServer.RootItem(SelectedString, Enums.FinancialReportItemKinds.ComplexTable);
			
			If Not RootItem = Undefined Then
				
				// We get the cached correspondence of the table elements to the rows of the tree of a complex table
				SavedBudgetTableSettings = CacheOfBudgetTableSettings.Get(RootItem.ReportItem);
				If SavedBudgetTableSettings = Undefined Then
					TreeRowsByElementsOfComplexTable = New ValueTable;
					TreeRowsByElementsOfComplexTable.Columns.Add("ReportItem");
					TreeRowsByElementsOfComplexTable.Columns.Add("TreeRow");
					FillTreeRowsByElementsOfComplexTableRecursively(TreeRowsByElementsOfComplexTable, RootItem);
					TreeRowsByElementsOfComplexTable.Indexes.Add("ReportItem");
					
					SavedBudgetTableSettings = New Structure;
					SavedBudgetTableSettings.Insert("ColumnPropertiesOfSimpleTable", Undefined);
					SavedBudgetTableSettings.Insert("TreeRowsByElementsOfComplexTable", TreeRowsByElementsOfComplexTable);
					CacheOfBudgetTableSettings.Insert(RootItem.ReportItem, SavedBudgetTableSettings)
				Else
					TreeRowsByElementsOfComplexTable = SavedBudgetTableSettings.TreeRowsByElementsOfComplexTable;
				EndIf;
				
				CellOfComplexTable = SettingsTable.Find(SelectedString.ReportItem, "Item");
				If CellOfComplexTable = Undefined Then
					ParentOfReportElement = ValueOfBudgetViewElementSProps(SelectedString.ReportItem, "Parent", CacheStructure.AttributeCache);
					If ValueIsFilled(ParentOfReportElement) Then
						CellOfComplexTable = SettingsTable.Find(ParentOfReportElement, "Item");
					EndIf;
				EndIf;
				If CellOfComplexTable = Undefined Then
					LanguageCode = Common.DefaultLanguageCode();
					ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Không thể lấy ô mục báo cáo trên bảng phức tạp %1.';
							|ru = 'Не удалось получить ячейку сложной таблицы по элементу отчета %1.';
							|en = 'Cannot get complex table cell by report item %1.'; fa = 'Cannot get complex table cell by report item %1.';
							|it = 'Impossibile ottenere la cella della tabella complessa per articolo del report %1.';
							|pl = 'Nie udało się otrzymać komórki skomplikowanej tabeli według elementu raportu %1.';
							|tr = '%1 rapor öğesine göre karmaşık tablo hücreleri alınamıyor.'", LanguageCode),
						DescriptionOfStructureOfBudgetElements.BudgetProfile);
					WriteLogEvent(
						NStr("vi = 'Nhận mô tả loại ngân sách';
							|ru = 'Получение описания вида бюджета';
							|en = 'Receiving budget profile description'; fa = 'Receiving budget profile description';
							|it = 'Ricezione della descrizione del tipo di bilancio';
							|pl = 'Otrzymania opisu rodzaju budżetu';
							|tr = 'Bütçe profili ayrıntılarının alımı'", LanguageCode),
						EventLogLevel.Error,
						Metadata.Catalogs.BudgetProfiles,
						DescriptionOfStructureOfBudgetElements.BudgetProfile,
						ExceptionText);
					Raise ExceptionText;
				EndIf;
				
				If Not CellOfComplexTable = Undefined Then
					RowTreeColumn = Undefined;
					StringTreeString  = Undefined;
					ReportElementString = TreeRowsByElementsOfComplexTable.Find(CellOfComplexTable.Column, "ReportItem");
					If Not ReportElementString = Undefined Then
						RowTreeColumn = ReportElementString.TreeRow;
					EndIf;
					ReportElementString = TreeRowsByElementsOfComplexTable.Find(CellOfComplexTable.String,  "ReportItem");
					If Not ReportElementString = Undefined Then
						StringTreeString  = ReportElementString.TreeRow;
					EndIf;
					
					If Not ParametersForSettingScripts.ThereIsScriptForSource
						And Not RowTreeColumn = Undefined Then
						TreeElementsContainScripts(RowTreeColumn, ParametersForSettingScripts, "Up", CacheStructure);
					EndIf;
					If Not ParametersForSettingScripts.ThereIsScriptForSource
						And Not RowTreeColumn = Undefined Then
						TreeElementsContainScripts(RowTreeColumn, ParametersForSettingScripts, "Down", CacheStructure);
					EndIf;
					If Not ParametersForSettingScripts.ThereIsScriptForSource
						And Not StringTreeString = Undefined Then
						TreeElementsContainScripts(StringTreeString, ParametersForSettingScripts, "Up", CacheStructure);
					EndIf;
					If Not ParametersForSettingScripts.ThereIsScriptForSource
						And Not StringTreeString = Undefined Then
						TreeElementsContainScripts(StringTreeString, ParametersForSettingScripts, "Down", CacheStructure);
					EndIf;
					
					ContinueAnalysis = False;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	If ContinueAnalysis Then
		// Indicator outside the table
		If Not ParametersForSettingScripts.ThereIsScriptForSource Then
			TreeElementsContainScripts(SelectedString, ParametersForSettingScripts, "Up", CacheStructure);
		EndIf;
		
		If Not ParametersForSettingScripts.ThereIsScriptForSource Then
			If SelectedString.Parent <> Undefined
				And SelectedString.Parent.ItemKind = Enums.FinancialReportItemKinds.DerivedItem Then
				CheckString = SelectedString.Parent;
			Else
				CheckString = SelectedString;
			EndIf;
			TreeElementsContainScripts(CheckString, ParametersForSettingScripts, "Down", CacheStructure);
		EndIf;
	EndIf;
	
	SourceAssignmentAttributes.GettingPlanForBudgetStructure =
		Max(SourceAssignmentAttributes.GettingPlanForBudgetStructure, ParametersForSettingScripts.ThereIsScenarioPlannedData);
	SourceAssignmentAttributes.GettingFactsAboutBudgetStructure =
		Max(SourceAssignmentAttributes.GettingFactsAboutBudgetStructure, ParametersForSettingScripts.ThereIsScriptActualData);
	SourceAssignmentAttributes.GettingBudgetExecutionByBudgetStructure =
		Max(SourceAssignmentAttributes.GettingBudgetExecutionByBudgetStructure, ParametersForSettingScripts.ThereIsScenarioBudgetExecution);
	SourceAssignmentAttributes.GettingScriptFromReportHeader =
		Max(SourceAssignmentAttributes.GettingScriptFromReportHeader, ParametersForSettingScripts.ThereIsScriptFromReportHeader);
	
EndProcedure

Procedure FillTreeRowsByElementsOfComplexTableRecursively(TreeRowsByElementsOfComplexTable, TreeRow)
	For Each NestedTreeLine In TreeRow.Rows Do
		SettingString = TreeRowsByElementsOfComplexTable.Add();
		SettingString.ReportItem = NestedTreeLine.ReportItem;
		SettingString.TreeRow  = NestedTreeLine;
		
		FillTreeRowsByElementsOfComplexTableRecursively(TreeRowsByElementsOfComplexTable, NestedTreeLine);
	EndDo;
EndProcedure

Procedure TreeElementsContainScripts(Val TreeItem, ParametersForSettingScripts, Direction, CacheStructure)
	
	If Direction = "Down" Then
		// Traversing either the columns of a tree ((or rows) of a perpendicular structure),
		// or a scenario can be set as a dimension in a simple table inside an indicator.
		For Each TreeRow In TreeItem.Rows Do
			If ParametersForSettingScripts.ThereIsScriptForSource
				And ParametersForSettingScripts.ThereIsScriptActualData
				And ParametersForSettingScripts.ThereIsScenarioBudgetExecution
				And ParametersForSettingScripts.ThereIsScenarioPlannedData Then
				Return; // We are completing the recursive traversal, because all the required elements have been found.
			EndIf;
			If TreeRow.ItemKind = Enums.FinancialReportItemKinds.Dimension
				And TreeRow.DimensionType = Enums.TypesOfBudgetReportDimensions.Scenario Then
				
				ParametersForSettingScripts.ThereIsScriptForSource = True;
				Scenario = FinancialReportingServer.ValueOfAdditionalProps(TreeRow.ReportItem, "Scenario", CacheStructure.CacheOfAdditionalBankingDetails);
				If Scenario = Catalogs.BudgetingScenarios.ActualData Then
					ParametersForSettingScripts.ThereIsScriptActualData = True;
				ElsIf Scenario = Catalogs.BudgetingScenarios.BudgetFulfillment Then
					ParametersForSettingScripts.ThereIsScenarioBudgetExecution = True;
				Else
					ParametersForSettingScripts.ThereIsScenarioPlannedData = True;
				EndIf;
				
			ElsIf TreeRow.ItemKind = Enums.FinancialReportItemKinds.Dimension
				And TreeRow.DimensionType = Enums.TypesOfBudgetReportDimensions.RegisterDimension
				And FinancialReportingServer.ValueOfAdditionalProps(TreeRow.ReportItem, "DimensionName", CacheStructure.CacheOfAdditionalBankingDetails) = "Scenario" Then
				
				ParametersForSettingScripts.ThereIsScriptForSource = True;
				ParametersForSettingScripts.ThereIsScriptFromReportHeader = True;
				
			Else
				
				TreeElementsContainScripts(TreeRow, ParametersForSettingScripts, Direction, CacheStructure);
				
			EndIf;
		EndDo;
		
	Else // "Up."
		
		If TreeItem.ItemKind = Enums.FinancialReportItemKinds.Dimension
			And TreeItem.DimensionType = Enums.TypesOfBudgetReportDimensions.Scenario Then
			
			ParametersForSettingScripts.ThereIsScriptForSource = True;
			Scenario = FinancialReportingServer.ValueOfAdditionalProps(TreeItem.ReportItem, "Scenario", CacheStructure.CacheOfAdditionalBankingDetails);
			If Scenario = Catalogs.BudgetingScenarios.ActualData Then
				ParametersForSettingScripts.ThereIsScriptActualData = True;
			ElsIf Scenario = Catalogs.BudgetingScenarios.BudgetFulfillment Then
				ParametersForSettingScripts.ThereIsScenarioBudgetExecution = True;
			Else
				ParametersForSettingScripts.ThereIsScenarioPlannedData = True;
			EndIf;
		ElsIf TreeItem.ItemKind = Enums.FinancialReportItemKinds.Dimension
			And TreeItem.DimensionType = Enums.TypesOfBudgetReportDimensions.RegisterDimension
			And FinancialReportingServer.ValueOfAdditionalProps(TreeItem.ReportItem, "DimensionName", CacheStructure.CacheOfAdditionalBankingDetails) = "Scenario" Then
			
			ParametersForSettingScripts.ThereIsScriptForSource = True;
			ParametersForSettingScripts.ThereIsScriptFromReportHeader = True;
		EndIf;
		
		// The scenario can be set as a measurement above the metric.
		If ParametersForSettingScripts.ThereIsScriptForSource
			And ParametersForSettingScripts.ThereIsScriptActualData
			And ParametersForSettingScripts.ThereIsScenarioBudgetExecution
			And ParametersForSettingScripts.ThereIsScenarioPlannedData Then
			Return; // We are completing the recursive traversal, because all the required elements have been found.
		EndIf;
		
		Parent = TreeItem.Parent;
		If Parent = Undefined
			Or Parent.ItemKind = Enums.FinancialReportItemKinds.Rows
			Or Parent.ItemKind = Enums.FinancialReportItemKinds.Columns
			Or Parent.ItemKind = Enums.FinancialReportItemKinds.CellsSettings Then
			Return; // We have reached the end. If the indicator is out of the table, then the parent can be = It is uncertain.
		EndIf;
		
		TreeElementsContainScripts(Parent, ParametersForSettingScripts, "Up", CacheStructure);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region SourcesOfGroupingPeriods

Function ExpressionOfGroupingPeriodRule(FieldName, ReportItem, ColumnStructure1, AttributeCache)
	
	MinimumPeriodicity = BudgetReportingClientServer.MinimumPeriodicity(ColumnStructure1.Periodicity_);
	
	AddAttributes = ChartsOfCharacteristicTypes.ItemAttributesOfFinancialReports;
	If FieldName = "EndOfPeriod" Then
		Formula = "GroupingPeriodEnd";
	Else
		Formula = "GroupingPeriodStart";
	EndIf;
	Formula = FinancialReportingServer.ValueOfAdditionalProps(
		ReportItem,
		AddAttributes[Formula],
		AttributeCache);
	
	PeriodVariables = BudgetReportingClientServer.VariablesOfBudgetingPeriods();
	GroupingPeriodReplacementExpression = "LeftTableOfPeriods."
		+ FinancialReportingClientServer.PeriodStrings(MinimumPeriodicity).Period;
	
	// Redefining the grouping period expression. The beginning of the data period and the end of the data period can be overridden by expressions.
	// This redefinition should be taken into account when calculating the grouping period.
	AdditionalDetailsStartOfPeriod = AddAttributes.LowerBoundOfData;
	AdditionalDetailsEndOfPeriod = AddAttributes.UpperBoundOfData;
	PeriodStartExpression = FinancialReportingServer.ValueOfAdditionalProps(
																ReportItem, 
																AdditionalDetailsStartOfPeriod,
																AttributeCache);
	ExpressionEndOfPeriod = FinancialReportingServer.ValueOfAdditionalProps(
																ReportItem, 
																AdditionalDetailsEndOfPeriod,
																AttributeCache);
	Formula = StrReplace(Lower(Formula), Lower(PeriodVariables.DataPeriodStart.Name), PeriodStartExpression);
	Formula = StrReplace(Lower(Formula), Lower(PeriodVariables.DataPeriodEnd.Name), ExpressionEndOfPeriod);
	
	Formula = StrReplace(Lower(Formula), Lower(PeriodVariables.DataPeriodStart.Name), "&BeginOfPeriod");
	Formula = StrReplace(Formula, Lower(PeriodVariables.DataPeriodEnd.Name), "&EndOfPeriod");
	Formula = StrReplace(Formula, Lower(PeriodVariables.ActualDataLimit.Name),  "&ActualDataLimit");
	Formula = StrReplace(Formula, Lower(PeriodVariables.PeriodOfGrouping.Name),  GroupingPeriodReplacementExpression);
	
	// for comparability of formulas, we will remove auxiliary user characters
	RemoveExtraSpacesFromFormula(Formula);
	
	Return Formula;
	
EndFunction

Function CompareRulesForGroupingPeriods(AttributeCache, Source, SelectedString, ColumnStructure1)
	
	ReportItem = SelectedString.ReportItem;
	
	ExpressionBeginningOfGroupingPeriod = ExpressionOfGroupingPeriodRule(
																"BeginOfPeriod",
																ReportItem, 
																ColumnStructure1, 
																AttributeCache);
	
	If ExpressionBeginningOfGroupingPeriod <> Source.ExpressionBeginningOfGroupingPeriod Then
		Return False;
	EndIf;
	
	EndOfGroupingPeriodExpression = ExpressionOfGroupingPeriodRule(
																"EndOfPeriod",
																ReportItem, 
																ColumnStructure1, 
																AttributeCache);
	
	If EndOfGroupingPeriodExpression <> Source.EndOfGroupingPeriodExpression Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

// Constructor of the source structure for the grouping period
// 
// Returns:
// 	Structure - LongDesc:
// * ItemsList - Array -
// * Id - String -
// * EndOfGroupingPeriodExpression - String -
// * ExpressionBeginningOfGroupingPeriod - String -
Function NewSourceOfGroupingPeriod()
	
	SourceStructure_ = New Structure;
	
	SourceStructure_.Insert("ExpressionBeginningOfGroupingPeriod", "");
	SourceStructure_.Insert("EndOfGroupingPeriodExpression",  "");
	SourceStructure_.Insert("Id", "");
	SourceStructure_.Insert("ItemsList", New Array);
	
	Return SourceStructure_;
	
EndFunction

Procedure AddRuleForGroupingPeriod(AttributeCache, Sources, SelectedString, ColumnStructure1)
	
	ReportItem = SelectedString.ReportItem;
	
	SourceStructure_ = NewSourceOfGroupingPeriod();
	
	SourceStructure_.ExpressionBeginningOfGroupingPeriod = ExpressionOfGroupingPeriodRule(
																		"BeginOfPeriod",
																		ReportItem, 
																		ColumnStructure1, 
																		AttributeCache);
	
	SourceStructure_.EndOfGroupingPeriodExpression  = ExpressionOfGroupingPeriodRule(
																		"EndOfPeriod",
																		ReportItem, 
																		ColumnStructure1, 
																		AttributeCache);
																	
	SourceStructure_.Id = "ID_" + Format(Sources.Count(), "NZ=; NG=0");
	SourceStructure_.ItemsList.Add(ReportItem);
	
	Sources.Add(SourceStructure_);
	
EndProcedure

Function FindRuleForGroupingPeriod(AttributeCache, Sources, SelectedString, ColumnStructure1)
	
	For Each Source In Sources Do
		If CompareRulesForGroupingPeriods(AttributeCache, Source, SelectedString, ColumnStructure1) Then
			Return Source; // See NewSource
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

Procedure FillInGroupingPeriodsByElementType(Sources, AttributeCache, BudgetItemTree, ColumnStructure1, ItemKind)
	
	PickedRows = BudgetItemTree.Rows.FindRows(New Structure("ItemKind", ItemKind), True);
	For Each SelectedString In PickedRows Do
		
		If ItemKind = Enums.FinancialReportItemKinds.AllBudgetFlowItems Then
			
			RootItem = FinancialReportingServer.RootItem(SelectedString,
				Enums.FinancialReportItemKinds.BudgetBalanceItem);
			If RootItem <> Undefined Then
				Continue;
			EndIf;
			RootItem = FinancialReportingServer.RootItem(SelectedString,
				Enums.FinancialReportItemKinds.AllBudgetBalanceItems);
			If RootItem <> Undefined Then
				Continue;
			EndIf;
			
		EndIf;
		
		FoundSource = FindRuleForGroupingPeriod(
			AttributeCache,
			Sources,
			SelectedString,
			ColumnStructure1); // See NewSourceOfGroupingPeriod
		If FoundSource = Undefined Then
			AddRuleForGroupingPeriod(AttributeCache, Sources, SelectedString, ColumnStructure1);
		Else
			FoundSource.ItemsList.Add(SelectedString.ReportItem);
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region GettingStructureOfBudgetReportCells

// Returns a table of value sources
// 
// Parameters:
// 	CellStructureOfCells - ValueTableRow - Row in the cell Structure table.
// 	DimensionName - String - Dimension name.
// Returns:
// 	Array of Structure - array of structures with properties:
// 	 *Source - String - ID of the source.
// 	 *Object - CatalogRef.BudgetFlowItems - 
// 				- CatalogRef.BudgetBalanceItems - 
// 				- CatalogRef.NonFinancialItemsOfBudgets - data source.
Function SourcesValuesFromCellOfCellStructureByDimensionName(CellStructureOfCells, DimensionName)
	ValueSources = CellStructureOfCells["Source" + DimensionName];
	Return ValueSources;
EndFunction

// Returns the structure of NFP measurement source tables
// 
// Parameters:
// 	CellStructure - ValueTable - 
// 	ArrayOfMeasurementColumns - Array -
// 	DataSources - Array of See NewSource -
// 	BudgetProfile - CatalogRef.BudgetProfiles -
// Returns:
// 	Structure - LongDesc:
// * NFPMeasurementFillTable - Undefined, ValueTable -
// * NFPMeasurementSelectionTable - Undefined, ValueTable -
Function FillInTableOfNFPMeasurementSources(CellStructure, ArrayOfMeasurementColumns, DataSources, BudgetProfile)
	
	NFPList = CellStructure.FindRows(New Structure("ItemKind", Enums.FinancialReportItemKinds.NonFinancialItem));
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	
	If Not NFPList.Count() Then
		
		Return New Structure("NFPMeasurementFillTable, NFPMeasurementSelectionTable");
		
	EndIf;
	
	Query = New Query;
	TestAnalyst = "";
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		TestAnalyst = TestAnalyst + ?(TestAnalyst = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"NonFinancialItemsOfBudgets.DimensionKind%1 AS DimensionKind%1",
				DimensionNumber);
	EndDo;
	Query.Text =
	"SELECT
	|	FinancialReportItemsItemKindAttributes.Value
	|INTO NFP
	|FROM
	|	Catalog.FinancialReportItems.ItemKindAttributes AS FinancialReportItemsItemKindAttributes
	|WHERE
	|	FinancialReportItemsItemKindAttributes.Ref.Owner = &Owner
	|	AND FinancialReportItemsItemKindAttributes.Attribute = &Attribute
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NonFinancialItemsOfBudgets.Ref AS Ref,
	|	&TestAnalyst,
	|	NonFinancialItemsOfBudgets.ByCompanies AS ByCompanies,
	|	NonFinancialItemsOfBudgets.ByBusinessUnits AS ByBusinessUnits,
	|	NonFinancialItemsOfBudgets.ByScenarios AS ByScenarios
	|FROM
	|	NFP AS NFP
	|		INNER JOIN Catalog.NonFinancialItemsOfBudgets AS NonFinancialItemsOfBudgets
	|		ON NFP.Value = NonFinancialItemsOfBudgets.Ref";
	Query.Text = StrReplace(Query.Text, "&TestAnalyst", TestAnalyst);
	
	Query.SetParameter("Owner", BudgetProfile);
	Query.SetParameter("Attribute", ChartsOfCharacteristicTypes.ItemAttributesOfFinancialReports.NonFinancialItem);
	AttributeCache = Query.Execute().Unload();
	
	NFPMeasurementFillTable = New ValueTable;
	NFPMeasurementFillTable.Columns.Add("NonFinancialItem", New TypeDescription("CatalogRef.NonFinancialItemsOfBudgets"));
	NFPMeasurementFillTable.Columns.Add("DimensionName", New TypeDescription("String"));
	NFPMeasurementFillTable.Columns.Add("AddressOfValueFillingSource", New TypeDescription("String"));
	RowOfColumns = "NonFinancialItem, DimensionName, AddressOfValueFillingSource";
	FillInSearchStructure = New Structure(RowOfColumns);
	NFPMeasurementFillTable.Indexes.Add(RowOfColumns);
	
	NFPMeasurementSelectionTable = New ValueTable;
	NFPMeasurementSelectionTable.Columns.Add("NonFinancialItem", New TypeDescription("CatalogRef.NonFinancialItemsOfBudgets"));
	NFPMeasurementSelectionTable.Columns.Add("DimensionName", New TypeDescription("String"));
	NFPMeasurementSelectionTable.Columns.Add("AddressForFillingInValues", New TypeDescription("String"));
	RowOfColumns = "NonFinancialItem, DimensionName, AddressForFillingInValues";
	SelectionSearchStructure = New Structure(RowOfColumns);
	NFPMeasurementSelectionTable.Indexes.Add(RowOfColumns);
	
	ArrayOfSources = New Array;
	For Each Source In DataSources Do
		ArrayOfSources.Add(Source.Id);
	EndDo;
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	
	For Each Cell In NFPList Do
		NFPDetails = AttributeCache.Find(Cell.NonFinancialItem, "Ref");
		For Each Dimension In ArrayOfMeasurementColumns Do
			NeedExtension = True;
			If Dimension = "Organization" Then
				If NFPDetails.ByCompanies Then
					NeedExtension = False;
				EndIf;
			ElsIf Dimension = "Department" Then
				If NFPDetails.ByBusinessUnits Then
					NeedExtension = False;
				EndIf;
			ElsIf Dimension = "Scenario" Then
				If NFPDetails.ByScenarios Then
					NeedExtension = False;
				EndIf;
			EndIf;
			For Cnt = 1 To MaximumNumberOfAnalysts Do
				FieldName = FinancialReportingCached.NameOfBudgetReportField(NFPDetails["DimensionKind" + Cnt]);
				If FieldName = Dimension Then
					NeedExtension = False;
					Break;
				EndIf;
			EndDo;
			ValueSources = SourcesValuesFromCellOfCellStructureByDimensionName(Cell, Dimension);
			If ValueIsFilled(ValueSources) Then
				If NeedExtension Then
					For Each ValueSource In ValueSources Do
						FillInSearchStructure.NonFinancialItem = Cell.NonFinancialItem;
						FillInSearchStructure.DimensionName = Dimension;
						FillInSearchStructure.AddressOfValueFillingSource = ValueSource.Source;
						If Not NFPMeasurementFillTable.FindRows(FillInSearchStructure).Count() Then
							FillPropertyValues(NFPMeasurementFillTable.Add(), FillInSearchStructure);
						EndIf;
					EndDo;
				Else
					ListOfSources = New Array;
					For Each ValueSource In ValueSources Do
						ListOfSources.Add(ValueSource.Source);
					EndDo;
					If Not CommonClientServer.ValueListsAreEqual(ArrayOfSources, ListOfSources) Then
						For Each ValueSource In ValueSources Do
							SelectionSearchStructure.NonFinancialItem = Cell.NonFinancialItem;
							SelectionSearchStructure.DimensionName = Dimension;
							SelectionSearchStructure.AddressForFillingInValues = ValueSource.Source;
							If Not NFPMeasurementSelectionTable.FindRows(SelectionSearchStructure).Count() Then
								FillPropertyValues(NFPMeasurementSelectionTable.Add(), SelectionSearchStructure);
							EndIf;
						EndDo;
					Else
						SelectionSearchStructure.NonFinancialItem = Cell.NonFinancialItem;
						SelectionSearchStructure.DimensionName = Dimension;
						SelectionSearchStructure.AddressForFillingInValues = "";
						If Not NFPMeasurementSelectionTable.FindRows(SelectionSearchStructure).Count() Then
							FillPropertyValues(NFPMeasurementSelectionTable.Add(), SelectionSearchStructure);
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	
	ProcessingColumns = "DimensionName, NonFinancialItem";
	Copy = NFPMeasurementSelectionTable.Copy(, ProcessingColumns);
	Copy.GroupBy(ProcessingColumns);
	NFPMeasurementSelectionTable.Indexes.Add(ProcessingColumns);
	TheStructureOfTheSearch = New Structure(ProcessingColumns);
	
	ArrayOnDelete = New Array;
	For Each FIlterRow In Copy Do
		FillPropertyValues(TheStructureOfTheSearch, FIlterRow);
		FoundRows = NFPMeasurementSelectionTable.FindRows(TheStructureOfTheSearch);
		For Each FoundRow In FoundRows Do
			If FoundRow.AddressForFillingInValues = "" Then
				CommonClientServer.SupplementArray(ArrayOnDelete, FoundRows);
				Break;
			EndIf;
		EndDo;
	EndDo;
	
	For Each TableRow In ArrayOnDelete Do
		NFPMeasurementSelectionTable.Delete(TableRow);
	EndDo;
	
	Return New Structure("NFPMeasurementFillTable, NFPMeasurementSelectionTable", NFPMeasurementFillTable, NFPMeasurementSelectionTable);
	
EndFunction

Function FiniteElementTree()
	
	Result = New ValueTree;
	Result.Columns.Add("Ref");
	Result.Columns.Add("ItemKind");
	
	Return Result;
	
EndFunction

Function AddRowToFiniteElementTree(Result, TreeRow)
	
	NewRow = Result.Rows.Add();
	NewRow.Ref = TreeRow.ReportItem;
	NewRow.ItemKind = TreeRow.ItemKind;
	
	Return NewRow;
	
EndFunction

// LongDesc
// 
// Parameters:
// 	ItemsTree - See BudgetItemTree
// 	ParentElement - CatalogRef.FinancialReportItems -
// 	DisplayHiddenTreeColumns - Boolean -
// Returns:
// 	Structure - the structure of the rows that consist of the wood elements of the budget and the "Link" column, as well as the columns containing the "link" column:
// * Rows - ValueTree - consists of columns:
// 		** ReportItem - CatalogRef.FinancialReportItems -
// 		** ItemKind - EnumRef.FinancialReportItemKinds -
// 		** Ref - CatalogRef.FinancialReportItems -
// * Columns - ValueTree - consists of columns:
// 		** Ref - CatalogRef.FinancialReportItems -
//
Function GetFinalElements(ItemsTree, ParentElement, DisplayHiddenTreeColumns)
	
	If ParentElement = Catalogs.FinancialReportItems.EmptyRef() Then
		Rows = GetFinalElementsOfTree(ItemsTree, True);
		Columns = New ValueTree;
		Columns.Columns.Add("Ref");
		Columns.Rows.Add().Ref = ParentElement;
	Else
		Header = ItemsTree.Rows.Find(ParentElement, "ReportItem");
		Item = Header.Rows.Find(Enums.FinancialReportItemKinds.Rows, "ItemKind");
		Rows = GetFinalElementsOfTree(Item, True);
		Item = Header.Rows.Find(Enums.FinancialReportItemKinds.Columns, "ItemKind");
		Columns = GetFinalElementsOfTree(Item, DisplayHiddenTreeColumns);
		If Not DisplayHiddenTreeColumns Then
			ColumnTree = FiniteElementTree();
			For Each Column In Columns Do
				AddRowToFiniteElementTree(ColumnTree, Column);
			EndDo;
			Columns = ColumnTree;
		EndIf;
	EndIf;
	
	Return New Structure("Rows, Columns", Rows, Columns);
	
EndFunction

Procedure FillInRowOfCellStructureAccordingToTreeData(Parameters, NewRow, Val Item)
	
	GenerationMode = Parameters.GenerationMode;
	AttributeCache = Parameters.AttributeCache;
	CacheOfAdditionalBankingDetails = Parameters.CacheOfAdditionalBankingDetails;
	
	While ValueIsFilled(Item) Do
		TypeOfComparisonElement = ValueOfBudgetViewElementSProps(Item, "ItemKind", AttributeCache);
		If TypeOfComparisonElement = Enums.FinancialReportItemKinds.AllBudgetFlowItems Then
			NewRow.FlagBudgetFlowItem = "fill";
		ElsIf TypeOfComparisonElement = Enums.FinancialReportItemKinds.AllBudgetBalanceItems Then
			NewRow.FlagBudgetBalanceItem = "fill";
		ElsIf TypeOfComparisonElement = Enums.FinancialReportItemKinds.BudgetFlowItem Then
			NewRow.BudgetFlowItem = FinancialReportingServer.ValueOfAdditionalProps(Item, "BudgetFlowItem", CacheOfAdditionalBankingDetails);
			NewRow.FlagBudgetFlowItem = "pick";
		ElsIf TypeOfComparisonElement = Enums.FinancialReportItemKinds.BudgetBalanceItem Then
			NewRow.BudgetBalanceItem = FinancialReportingServer.ValueOfAdditionalProps(Item, "BudgetBalanceItem", CacheOfAdditionalBankingDetails);
			NewRow.FlagBudgetBalanceItem = "pick";
		ElsIf TypeOfComparisonElement = Enums.FinancialReportItemKinds.NonFinancialItem Then
			NewRow.NonFinancialItem = FinancialReportingServer.ValueOfAdditionalProps(Item, "NonFinancialItem", CacheOfAdditionalBankingDetails);
			NewRow.FlagNonFinancialItem = "pick";
		ElsIf TypeOfComparisonElement = Enums.FinancialReportItemKinds.Dimension Then
			DimensionType = FinancialReportingServer.ValueOfAdditionalProps(Item, "DimensionType", CacheOfAdditionalBankingDetails);
			
			If DimensionType = Enums.TypesOfBudgetReportDimensions.Organization Then
				
				Value = FinancialReportingServer.ValueOfAdditionalProps(Item, "Organization", CacheOfAdditionalBankingDetails);
				NewRow.Organization = Value;
				NewRow.FlagOrganization = "pick";
				
			ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.Department Then
				
				Value = FinancialReportingServer.ValueOfAdditionalProps(Item, "Department", CacheOfAdditionalBankingDetails);
				NewRow.Department = Value;
				NewRow.FlagDepartment = "pick";
				
			ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.Scenario Then
				
				Value = FinancialReportingServer.ValueOfAdditionalProps(Item, "Scenario", CacheOfAdditionalBankingDetails);
				NewRow.Scenario = Value;
				NewRow.FlagScenario = "pick";
				
			ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.Currency Then
				
				Value = FinancialReportingServer.ValueOfAdditionalProps(Item, "Currency", CacheOfAdditionalBankingDetails);
				NewRow.Currency = Value;
				NewRow.FlagCurrency = "pick";
				
			ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.FixedDimension Then
				
				ThisIsDimensionOther = FinancialReportingServer.ValueOfAdditionalProps(Item, "ThisIsDimensionOther", CacheOfAdditionalBankingDetails);
				DimensionKind = FinancialReportingServer.ValueOfAdditionalProps(Item, "DimensionKind", CacheOfAdditionalBankingDetails);
				EnableEdit = FinancialReportingServer.ValueOfAdditionalProps(Item, "EnableEdit", CacheOfAdditionalBankingDetails);
				NameOfAnalytics = FinancialReportingCached.NameOfBudgetReportField(DimensionKind);
				Value = ValueOfBudgetViewElementSProps(Item, "DimensionValue", AttributeCache);
				
				If ThisIsDimensionOther Then
					NewRow[NameOfAnalytics] = Undefined;
					If EnableEdit = True Then
						
						If GenerationMode = Enums.ModesOfBudgetReportGeneration.FillType
							Or GenerationMode = Enums.ModesOfBudgetReportGeneration.Document Then
							
							If GenerationMode = Enums.ModesOfBudgetReportGeneration.FillType Then
								NewRow["Flag" + NameOfAnalytics] = "fill";
							Else
								NewRow["Flag" + NameOfAnalytics] = "document";
							EndIf;
							
							SourceAllElements = FinancialReportingServerCall.ValueOfAdditionalProps(Item, "SourceAllElements");
							
							If Not GenerationMode = Enums.ModesOfBudgetReportGeneration.FillType 
								Or SourceAllElements = Undefined Or Not SourceAllElements Then
								
								If GenerationMode = Enums.ModesOfBudgetReportGeneration.FillType Then
									TheStructureOfTheSearch = New Structure("ReportItem, AddedDocumentValues", Item, False);
								Else
									TheStructureOfTheSearch = New Structure("ReportItem, AddedDocumentValues", Item, True);
								EndIf;
								NewRow["Source" + NameOfAnalytics] = ArrayOfSourcesForReportElement(Item,
									Parameters, TheStructureOfTheSearch);
							Else
								ArrayOfSources = New Array;
								SourceProperties = New Structure;
								SourceProperties.Insert("Source", "AllItems");
								SourceProperties.Insert("Object",   Undefined);
								SourceProperties.Insert("TypeOfCalculatedIndicatorValue", Undefined);
								ArrayOfSources.Add(SourceProperties);
								NewRow["Source" + NameOfAnalytics] = ArrayOfSources;
							EndIf;
							
						ElsIf GenerationMode = Enums.ModesOfBudgetReportGeneration.PrintBudget Then
							
							NewRow["Flag" + NameOfAnalytics] = "document";
							
						Else
							
							NewRow["Flag" + NameOfAnalytics] = "fill";
							
							SourceAllElements = FinancialReportingServerCall.ValueOfAdditionalProps(Item, "SourceAllElements");
							
							If SourceAllElements = Undefined Or Not SourceAllElements Then
								TheStructureOfTheSearch = New Structure("ReportItem, AddedDocumentValues", Item, True);
								NewRow["Source" + NameOfAnalytics] = ArrayOfSourcesForReportElement(Item,
									Parameters, TheStructureOfTheSearch);
							Else
								ArrayOfSources = New Array;
								SourceProperties = New Structure;
								SourceProperties.Insert("Source", "AllItems");
								SourceProperties.Insert("Object",   Undefined);
								SourceProperties.Insert("TypeOfCalculatedIndicatorValue", Undefined);
								ArrayOfSources.Add(SourceProperties);
								NewRow["Source" + NameOfAnalytics] = ArrayOfSources;
							EndIf;
							
						EndIf;
					Else
						
						NewRow["Flag" + NameOfAnalytics] = "otheritems";
						
					EndIf;
				Else
					NewRow[NameOfAnalytics] = Value;
					NewRow["Flag" + NameOfAnalytics] = "pick";
				EndIf;
				NewRow["Parent" + NameOfAnalytics] = ValueOfBudgetViewElementSProps(Item, "Parent", AttributeCache);
				
			ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.Dimension Then
				
				DimensionKind = FinancialReportingServer.ValueOfAdditionalProps(Item, "DimensionKind", CacheOfAdditionalBankingDetails);
				NameOfAnalytics = FinancialReportingCached.NameOfBudgetReportField(DimensionKind);
				NewRow["Flag" + NameOfAnalytics] = "fill";
				
				SourceAllElements = FinancialReportingServerCall.ValueOfAdditionalProps(Item, "SourceAllElements");
				
				If SourceAllElements = Undefined Or Not SourceAllElements Then
					NewRow["Source" + NameOfAnalytics] = ArrayOfSourcesForReportElement(Item, Parameters);
				Else
					ArrayOfSources = New Array;
					SourceProperties = New Structure;
					SourceProperties.Insert("Source", "AllItems");
					SourceProperties.Insert("Object",   Undefined);
					SourceProperties.Insert("TypeOfCalculatedIndicatorValue", Undefined);
					ArrayOfSources.Add(SourceProperties);
					NewRow["Source" + NameOfAnalytics] = ArrayOfSources;
				EndIf;
				
			ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.RegisterDimension Then
				
				DimensionName = FinancialReportingServer.ValueOfAdditionalProps(Item, "DimensionName", CacheOfAdditionalBankingDetails);
				NewRow["Flag" + DimensionName] = "fill";
				NewRow["Source" + DimensionName] = ArrayOfSourcesForReportElement(Item, Parameters);
				
			ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.Period Then
				
				Period = FinancialReportingServer.ValueOfAdditionalProps(Item, "Periodicity", CacheOfAdditionalBankingDetails);
				PeriodStrings = FinancialReportingClientServer.PeriodStrings(Period);
				NewRow[PeriodStrings.FlagPeriod] = "fill";

				PeriodValue = FinancialReportingServer.ValueOfAdditionalProps(Item, "PeriodValue", CacheOfAdditionalBankingDetails);
				If PeriodValue = Undefined Then
					NewRow[PeriodStrings.PeriodExpression] = -1;
				Else
					NewRow[PeriodStrings.PeriodExpression] = PeriodValue;
				EndIf;
				
				OrderedPeriodicities = Enums.Periodicity.OrderedPeriodicities();
				FoundIndex = OrderedPeriodicities.Find(Period);
				
				For Cnt = FoundIndex + 1 To OrderedPeriodicities.UBound() Do
					Period = OrderedPeriodicities[Cnt];
					PeriodStrings = FinancialReportingClientServer.PeriodStrings(Period);
					If NewRow.Owner().Columns.Find(PeriodStrings.Period) <> Undefined Then
						If NewRow[PeriodStrings.FlagPeriod] <> "fill" Then
							NewRow[PeriodStrings.FlagPeriod] = "fill";
							NewRow[PeriodStrings.PeriodExpression] = -1;
						EndIf;
					EndIf;
				EndDo;
				
			EndIf;
			
		EndIf;
		Item = ValueOfBudgetViewElementSProps(Item, "Parent", AttributeCache);
	EndDo;
	
EndProcedure

Function ArrayOfSourcesForReportElement(ReportItem, Parameters, TheStructureOfTheSearch = Undefined)

	CacheDataSourcesOfReportElements = Parameters.CacheDataSourcesOfReportElements;
	If CacheDataSourcesOfReportElements.Get(ReportItem) <> Undefined Then
		Return Common.CopyRecursive(CacheDataSourcesOfReportElements[ReportItem]);
	EndIf;

	CacheSourcesOfValues = Parameters.ValueSources;
	DataSources = Parameters.DataSources;
	
	ArrayOfSources = New Array;
	If TheStructureOfTheSearch = Undefined Then
		TheStructureOfTheSearch = New Structure("ReportItem", ReportItem);
	EndIf;
	ValueSources = CacheSourcesOfValues.FindRows(TheStructureOfTheSearch);
	
	For Each ValueSource In ValueSources Do
		For Each DataSource In DataSources Do
			If DataSource.ItemsList.Find(ValueSource.Source) <> Undefined Then
				SourceProperties = New Structure;
				SourceProperties.Insert("Source", DataSource.Id);
				SourceProperties.Insert("Object",   ValueSource.Object);
				SourceProperties.Insert("TypeOfCalculatedIndicatorValue", ValueSource.TypeOfCalculatedIndicatorValue);
				ArrayOfSources.Add(SourceProperties);
			EndIf;
		EndDo;
	EndDo;
	CacheDataSourcesOfReportElements.Insert(ReportItem, Common.CopyRecursive(ArrayOfSources));
	
	Return ArrayOfSources;
	
EndFunction

Procedure FillInCellStructure(Parameters, Columns)
	
	For Each Column In Columns.Rows Do
		StringTree = Parameters.StringTree;
		FillCellStructureRecursively(Parameters, StringTree, Column.Ref);
		FillInCellStructure(Parameters, Column);
	EndDo;
	
EndProcedure

Function CurrencyForEnteringAnalytics(NewRow, CacheOfArticleDetails)
	
	ObjectOfCurrencyAccounting = Undefined;
	If ValueIsFilled(NewRow.BudgetBalanceItem) Then
		ObjectOfCurrencyAccounting = NewRow.BudgetBalanceItem;
	ElsIf ValueIsFilled(NewRow.BudgetFlowItem) Then
		ObjectOfCurrencyAccounting = NewRow.BudgetFlowItem;
	Else
		Return Undefined;
	EndIf;
	
	CurrencyAccountingDetails = CacheOfArticleDetails[ObjectOfCurrencyAccounting];
	If CurrencyAccountingDetails = Undefined Then
	
		Attributes = New Structure("DimensionCurrencyFilling, RecordByCurrency, 
								|DimensionCurrencies, CurrencyIsDeterminedByDimension", "DimensionCurrencies.CurrencyFilling");
		
		CurrencyAccountingDetails = Common.ObjectAttributesValues(ObjectOfCurrencyAccounting, Attributes);
		
		CacheOfArticleDetails.Insert(ObjectOfCurrencyAccounting, CurrencyAccountingDetails);
		
	EndIf;
	
	If Not CurrencyAccountingDetails.RecordByCurrency Then
		Return Undefined;
	EndIf;
	
	If Not CurrencyAccountingDetails.CurrencyIsDeterminedByDimension Then
		Return Undefined;
	EndIf;
	
	FieldName = FinancialReportingCached.NameOfBudgetReportField(CurrencyAccountingDetails.DimensionCurrencies);
	If NewRow.Owner().Columns.Find(FieldName) <> Undefined Then
		Simple = NewRow[FieldName];
		If ValueIsFilled(Simple)
			And TypeOf(Simple) <> Type("String") Then
			Return NewRow[FieldName][CurrencyAccountingDetails.DimensionCurrencyFilling];
		EndIf;
	EndIf;
	
	Return Undefined
	
EndFunction

Function AnalyticsInputUnit(NewRow, CacheOfArticleDetails)
	
	AccountingObject = Undefined;
	If ValueIsFilled(NewRow.BudgetBalanceItem) Then
		AccountingObject = NewRow.BudgetBalanceItem;
	ElsIf ValueIsFilled(NewRow.BudgetFlowItem) Then
		AccountingObject = NewRow.BudgetFlowItem;
	Else
		Return Undefined;
	EndIf;
	
	AccountingDetails = CacheOfArticleDetails[AccountingObject];
	If AccountingDetails = Undefined Then
	
		Attributes = New Structure("AnalyticsFillingInUnit, RecordByQuantity, 
									|DimensionUnitsOfMeasurement, UnitOfMeasureIsDeterminedByDimension,
									|UnitOfMeasure", 
									"DimensionUnitsOfMeasurement.UnitOfMeasureFilling");
		
		AccountingDetails = Common.ObjectAttributesValues(AccountingObject, Attributes);
		
		CacheOfArticleDetails.Insert(AccountingObject, AccountingDetails);
		
	EndIf;
	
	If Not AccountingDetails.RecordByQuantity Then
		Return Undefined;
	EndIf;
	
	If Not AccountingDetails.UnitOfMeasureIsDeterminedByDimension Then
		Return AccountingDetails.UnitOfMeasure;
	EndIf;
	
	FieldName = FinancialReportingCached.NameOfBudgetReportField(AccountingDetails.DimensionUnitsOfMeasurement);
	If NewRow.Owner().Columns.Find(FieldName) <> Undefined Then
		Simple = NewRow[FieldName];
		If ValueIsFilled(Simple)
			And TypeOf(Simple) <> Type("String") Then
			Return NewRow[FieldName][AccountingDetails.AnalyticsFillingInUnit];
		EndIf;
	EndIf;
	
	Return Undefined
	
EndFunction

Procedure FillInSumQuantityAttributesOfFormula(BudgetProfile, CellStructure)
	
	DCS = Catalogs.BudgetProfiles.GetTemplate("AllSubordinateItems");
	Composer = FinancialReportingServer.SchemaComposer(DCS);
	FinancialReportingServer.NewFilter(Composer.Settings.Filter, "ItemKind", Enums.FinancialReportItemKinds.Group);
	FinancialReportingServer.SetLayoutParameter(Composer, "BudgetProfile", BudgetProfile);
	Result = FinancialReportingServer.UploadDCSResults(DCS, Composer);
	
	Query = New Query();
	Manager = New TempTablesManager;
	Query.TempTablesManager = Manager;
	Query.Text =
	"SELECT
	|	ParentSubordinateTable.Parent,
	|	ParentSubordinateTable.Ref
	|INTO ChildItems
	|FROM
	|	&ChildItems AS ParentSubordinateTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CAST(CellStructure.String AS Catalog.FinancialReportItems) AS String,
	|	CAST(CellStructure.Column AS Catalog.FinancialReportItems) AS Column,
	|	CellStructure.ItemKind AS ItemKind,
	|	CellStructure.FlagSum,
	|	CellStructure.FlagCount,
	|	CellStructure.TableComplex_
	|INTO CellStructure
	|FROM
	|	&CellStructure AS CellStructure
	|
	|INDEX BY
	|	String,
	|	Column
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfBasicElements.String,
	|	TableOfBasicElements.Column,
	|	ChildItems.Ref AS SubordinateItem,
	|	TableOfBasicElements.TableComplex_
	|INTO TableOfElementsWithSubordinatesByRows
	|FROM
	|	CellStructure AS TableOfBasicElements
	|		LEFT JOIN ChildItems AS ChildItems
	|		ON TableOfBasicElements.String = ChildItems.Parent
	|WHERE
	|	TableOfBasicElements.ItemKind = VALUE(Enum.FinancialReportItemKinds.Group)
	|
	|GROUP BY
	|	TableOfBasicElements.Column,
	|	TableOfBasicElements.String,
	|	ChildItems.Ref,
	|	TableOfBasicElements.TableComplex_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfBasicElements.String,
	|	TableOfBasicElements.Column,
	|	ChildItems.Ref AS SubordinateItem,
	|	TableOfBasicElements.TableComplex_
	|INTO TableOfElementsWithSubordinatesByColumns
	|FROM
	|	CellStructure AS TableOfBasicElements
	|		LEFT JOIN ChildItems AS ChildItems
	|		ON TableOfBasicElements.Column = ChildItems.Parent
	|WHERE
	|	TableOfBasicElements.ItemKind = VALUE(Enum.FinancialReportItemKinds.Group)
	|
	|GROUP BY
	|	TableOfBasicElements.Column,
	|	TableOfBasicElements.String,
	|	ChildItems.Ref,
	|	TableOfBasicElements.TableComplex_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfBasicElements.String,
	|	TableOfBasicElements.Column,
	|	MAX(SubordinateElementsInTable.FlagSum) AS FlagSum,
	|	MAX(SubordinateElementsInTable.FlagCount) AS FlagCount,
	|	TableOfBasicElements.TableComplex_
	|INTO TableOfBasicElements
	|FROM
	|	TableOfElementsWithSubordinatesByRows AS TableOfBasicElements
	|		LEFT JOIN CellStructure AS SubordinateElementsInTable
	|		ON TableOfBasicElements.Column = SubordinateElementsInTable.Column
	|			AND TableOfBasicElements.SubordinateItem = SubordinateElementsInTable.String
	|
	|GROUP BY
	|	TableOfBasicElements.Column,
	|	TableOfBasicElements.String,
	|	TableOfBasicElements.TableComplex_
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfBasicElements.String,
	|	TableOfBasicElements.Column,
	|	MAX(SubordinateElementsInTable.FlagSum),
	|	MAX(SubordinateElementsInTable.FlagCount),
	|	TableOfBasicElements.TableComplex_
	|FROM
	|	TableOfElementsWithSubordinatesByColumns AS TableOfBasicElements
	|		LEFT JOIN CellStructure AS SubordinateElementsInTable
	|		ON TableOfBasicElements.String = SubordinateElementsInTable.String
	|			AND TableOfBasicElements.SubordinateItem = SubordinateElementsInTable.Column
	|
	|GROUP BY
	|	TableOfBasicElements.Column,
	|	TableOfBasicElements.String,
	|	TableOfBasicElements.TableComplex_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfBasicElements.String,
	|	TableOfBasicElements.Column,
	|	MAX(CASE
	|			WHEN TableOfBasicElements.TableComplex_
	|				THEN TRUE
	|			WHEN TableOfBasicElements.String.ItemKind = TableOfBasicElements.Column.ItemKind
	|					AND &ThereAreSums
	|				THEN TRUE
	|			ELSE TableOfBasicElements.FlagSum
	|		END) AS FlagSum,
	|	MAX(CASE
	|			WHEN TableOfBasicElements.TableComplex_
	|				THEN FALSE
	|			WHEN TableOfBasicElements.String.ItemKind = TableOfBasicElements.Column.ItemKind
	|				THEN FALSE
	|			ELSE TableOfBasicElements.FlagCount
	|		END) AS FlagCount
	|INTO GroupFlags_
	|FROM
	|	TableOfBasicElements AS TableOfBasicElements
	|
	|GROUP BY
	|	TableOfBasicElements.String,
	|	TableOfBasicElements.Column
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CellStructure.String,
	|	CellStructure.Column,
	|	ISNULL(RowParents_.Parent, VALUE(Catalog.FinancialReportItems.EmptyRef)) AS ParentRow,
	|	ISNULL(ColumnParents.Parent, VALUE(Catalog.FinancialReportItems.EmptyRef)) AS ParentColumn
	|INTO OnlyFormulas
	|FROM
	|	CellStructure AS CellStructure
	|		LEFT JOIN ChildItems AS RowParents_
	|		ON (RowParents_.Ref = CellStructure.String)
	|		LEFT JOIN ChildItems AS ColumnParents
	|		ON (ColumnParents.Ref = CellStructure.Column)
	|WHERE
	|	CellStructure.ItemKind = VALUE(Enum.FinancialReportItemKinds.GroupFormula)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OnlyFormulas.String,
	|	OnlyFormulas.Column,
	|	GroupFlags_.FlagSum AS FlagSum,
	|	GroupFlags_.FlagCount AS FlagCount
	|INTO AllFlags
	|FROM
	|	OnlyFormulas AS OnlyFormulas
	|		LEFT JOIN GroupFlags_ AS GroupFlags_
	|		ON OnlyFormulas.Column = GroupFlags_.Column
	|			AND OnlyFormulas.ParentRow = GroupFlags_.String
	|
	|UNION ALL
	|
	|SELECT
	|	OnlyFormulas.String,
	|	OnlyFormulas.Column,
	|	GroupFlags_.FlagSum,
	|	GroupFlags_.FlagCount
	|FROM
	|	OnlyFormulas AS OnlyFormulas
	|		LEFT JOIN GroupFlags_ AS GroupFlags_
	|		ON OnlyFormulas.String = GroupFlags_.String
	|			AND OnlyFormulas.ParentColumn = GroupFlags_.Column
	|
	|UNION ALL
	|
	|SELECT
	|	OnlyFormulas.String,
	|	OnlyFormulas.Column,
	|	GroupFlags_.FlagSum,
	|	GroupFlags_.FlagCount
	|FROM
	|	OnlyFormulas AS OnlyFormulas
	|		LEFT JOIN GroupFlags_ AS GroupFlags_
	|		ON OnlyFormulas.ParentRow = GroupFlags_.String
	|			AND OnlyFormulas.ParentColumn = GroupFlags_.Column
	|
	|UNION ALL
	|
	|SELECT
	|	GroupFlags_.String,
	|	GroupFlags_.Column,
	|	GroupFlags_.FlagSum,
	|	GroupFlags_.FlagCount
	|FROM
	|	GroupFlags_ AS GroupFlags_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllFlags.String,
	|	AllFlags.Column,
	|	MAX(AllFlags.FlagSum) AS FlagSum,
	|	MAX(AllFlags.FlagCount) AS FlagCount
	|FROM
	|	AllFlags AS AllFlags
	|
	|GROUP BY
	|	AllFlags.String,
	|	AllFlags.Column";
	
	CellStructureColumns = "String, Column, ItemKind, FlagCount, FlagSum, TableComplex_";
	PartOfCellStructure = CellStructure.Copy(New Structure("MainItem", True), CellStructureColumns);
	ThereAreSums = PartOfCellStructure.FindRows(New Structure("FlagSum", True)).Count() > 0;
	Query.SetParameter("ThereAreSums", ThereAreSums);
	Query.SetParameter("CellStructure", PartOfCellStructure);
	Query.SetParameter("ChildItems", Result);
	
	CellStructure.Indexes.Add("String, Column");
	QueryResult = Query.Execute();
	LinesToCalculate = QueryResult.Select();
	
	While LinesToCalculate.Next() Do
		TheStructureOfTheSearch = New Structure("String, Column", LinesToCalculate.String, LinesToCalculate.Column);
		FoundRows = CellStructure.FindRows(TheStructureOfTheSearch);
		For Each FoundRow In FoundRows Do
			FillPropertyValues(FoundRow, LinesToCalculate, "FlagSum, FlagCount");
		EndDo;
	EndDo;
	
EndProcedure

Function FillCellStructureRecursively(Parameters, StringTree, Column)
	
	CellStructure = Parameters.CellStructure; // See NewCellStructure
	DataSources = Parameters.DataSources;
	SourcesOfGroupingPeriods = Parameters.SourcesOfGroupingPeriods;
	Parent = Parameters.Parent;
	SettingsTable = Parameters.SettingsTable;
	
	CacheOfAdditionalBankingDetails = Parameters.CacheOfAdditionalBankingDetails;
	AttributeCache = Parameters.AttributeCache;
	CacheOfCurrencyItemDetails = Parameters.CacheOfCurrencyItemDetails;
	CacheOfArticleDetailsEd = Parameters.CacheOfArticleDetailsEd;
	
	AddedRows = New Array;
	
	For Each TreeRow In StringTree.Rows Do
		
		String = TreeRow.Ref;
		//@skip-check query-in-loop
		SubordinateRows = FillCellStructureRecursively(Parameters, TreeRow, Column);
		
		If TreeRow.ItemKind = Enums.FinancialReportItemKinds.Rows Then
			Continue;
		EndIf;
		
		// defining the base cell element
		Item = Undefined;
		CalculateBySubordinates = 0;
		// 0 - do not count
		// 1 - amount by measurement
		// 2 - group processing
		
		StringTypeOfComparisonElement = ValueOfBudgetViewElementSProps(String, "ItemKind", AttributeCache);
		
		If ValueIsFilled(Column) Then
			ColumnViewOfComparisonElement = ValueOfBudgetViewElementSProps(Column, "ItemKind", AttributeCache);
		Else
			ColumnViewOfComparisonElement = Undefined;
		EndIf;
		
		If StringTypeOfComparisonElement = Enums.FinancialReportItemKinds.GroupFormula
			Or ColumnViewOfComparisonElement = Enums.FinancialReportItemKinds.GroupFormula Then
			CalculateBySubordinates = 2;
		
		ElsIf StringTypeOfComparisonElement = Enums.FinancialReportItemKinds.Group
			Or ColumnViewOfComparisonElement = Enums.FinancialReportItemKinds.Group Then
			CalculateBySubordinates = 2;
		
		ElsIf Not ValueIsFilled(Parent)
			Or ValueOfBudgetViewElementSProps(Parent, "ItemKind", AttributeCache)
				= Enums.FinancialReportItemKinds.TableIndicatorsInRows Then
			
			Item = String;
			While ValueIsFilled(Item) Do
				TypeOfComparisonElement = ValueOfBudgetViewElementSProps(Item, "ItemKind", AttributeCache);
				If TypeOfComparisonElement = Enums.FinancialReportItemKinds.BudgetFlowItem
					Or TypeOfComparisonElement = Enums.FinancialReportItemKinds.BudgetBalanceItem
					Or TypeOfComparisonElement = Enums.FinancialReportItemKinds.AllBudgetFlowItems
					Or TypeOfComparisonElement = Enums.FinancialReportItemKinds.AllBudgetBalanceItems
					Or TypeOfComparisonElement = Enums.FinancialReportItemKinds.DerivedItem 
					Or TypeOfComparisonElement = Enums.FinancialReportItemKinds.NonFinancialItem
					Or TypeOfComparisonElement = Enums.FinancialReportItemKinds.EditedValue Then
					Break;
				EndIf;
				Item = ValueOfBudgetViewElementSProps(Item, "Parent", AttributeCache);
			EndDo;
			
			If Not ValueIsFilled(Item) Then
				CalculateBySubordinates = 1;
			EndIf;
			
		ElsIf ValueOfBudgetViewElementSProps(Parent, "ItemKind", AttributeCache)
					= Enums.FinancialReportItemKinds.TableIndicatorsInColumns Then
			
			Item = Column;
			While ValueIsFilled(Item) Do
				TypeOfComparisonElement = ValueOfBudgetViewElementSProps(Item, "ItemKind", AttributeCache);
				If TypeOfComparisonElement = Enums.FinancialReportItemKinds.BudgetFlowItem
					Or TypeOfComparisonElement = Enums.FinancialReportItemKinds.BudgetBalanceItem
					Or TypeOfComparisonElement = Enums.FinancialReportItemKinds.AllBudgetFlowItems
					Or TypeOfComparisonElement = Enums.FinancialReportItemKinds.AllBudgetBalanceItems
					Or TypeOfComparisonElement = Enums.FinancialReportItemKinds.DerivedItem
					Or TypeOfComparisonElement = Enums.FinancialReportItemKinds.NonFinancialItem
					Or TypeOfComparisonElement = Enums.FinancialReportItemKinds.EditedValue Then
					Break;
				EndIf;
				Item = ValueOfBudgetViewElementSProps(Item, "Parent", AttributeCache);
			EndDo;
			
			If Not ValueIsFilled(Item) Then
				CalculateBySubordinates = 1;
			EndIf;
			
		ElsIf Parent.ItemKind = Enums.FinancialReportItemKinds.ComplexTable Then
			
			TheStructureOfTheSearch = New Structure("String, Column, Parent", String, Column, Parent);
			FoundRows = SettingsTable.FindRows(TheStructureOfTheSearch);
			
			If FoundRows.Count() Then
				Item = FoundRows[0].Item;
			EndIf;
			
		EndIf;
		
		If Not ValueIsFilled(Item) Then
			If Not CalculateBySubordinates Then
				Continue;
			EndIf;
			If Not CalculateBySubordinates = 2 Then
				If Not ItIsPossibleToSummarizeSubordinateStrings(SubordinateRows) Then
					Continue;
				EndIf;
				If Not SubordinateRows.Count() Then
					Continue;
				EndIf;
			EndIf;
		EndIf;
		
		NewRow = CellStructure.Add();
		AddedRows.Add(NewRow);
		NewRow.String = String;
		NewRow.Column = Column;
		
		NewRow.TableComplex_ = Parameters.TableComplex_;
		
		If ValueIsFilled(Item) Then
			
			NewRow.ItemKind = ValueOfBudgetViewElementSProps(Item, "ItemKind", AttributeCache);
			
			If NewRow.ItemKind = Enums.FinancialReportItemKinds.NonFinancialItem
				Or NewRow.ItemKind = Enums.FinancialReportItemKinds.EditedValue Then
				
				NewRow.FlagValue = True;
				
			Else
				
				NewRow.ReverseSign = ValueOfBudgetViewElementSProps(Item, "ReverseSign", AttributeCache);
				Indicators = FinancialReportingServer.ValueOfAdditionalProps(Item, "DisplayedIndicators", CacheOfAdditionalBankingDetails);
				
				NewRow.FlagSum = True;
				If Indicators = Enums.TypesOfDisplayedBudgetReportIndicators.Count Then
					NewRow.FlagSum = False;
					NewRow.FlagCount = True;
				ElsIf Indicators = Enums.TypesOfDisplayedBudgetReportIndicators.QuantityAndAmount Then
					NewRow.FlagCount = True;
				EndIf;
				
			EndIf;
			
			If NewRow.ItemKind = Enums.FinancialReportItemKinds.AllBudgetFlowItems Then
				NewRow.FlagBudgetFlowItem = "fill";
			ElsIf NewRow.ItemKind = Enums.FinancialReportItemKinds.AllBudgetBalanceItems Then
				NewRow.FlagBudgetBalanceItem = "fill";
			ElsIf NewRow.ItemKind = Enums.FinancialReportItemKinds.BudgetFlowItem Then
				NewRow.BudgetFlowItem = FinancialReportingServer.ValueOfAdditionalProps(Item, "BudgetFlowItem", CacheOfAdditionalBankingDetails);
				NewRow.FlagBudgetFlowItem = "pick";
			ElsIf NewRow.ItemKind = Enums.FinancialReportItemKinds.BudgetBalanceItem Then
				NewRow.BudgetBalanceItem = FinancialReportingServer.ValueOfAdditionalProps(Item, "BudgetBalanceItem", CacheOfAdditionalBankingDetails);
				NewRow.FlagBudgetBalanceItem = "pick";
			ElsIf NewRow.ItemKind = Enums.FinancialReportItemKinds.NonFinancialItem Then
				NewRow.NonFinancialItem = FinancialReportingServer.ValueOfAdditionalProps(Item, "NonFinancialItem", CacheOfAdditionalBankingDetails);
				NewRow.FlagNonFinancialItem = "pick";
			ElsIf NewRow.ItemKind = Enums.FinancialReportItemKinds.EditedValue Then
				NewRow.EditedValue = Item.NameForPrinting;
				NewRow.FlagEditedValue = "pick";
			EndIf;
			
		Else
			NewRow.ItemKind = Enums.FinancialReportItemKinds.DerivedItem;
		EndIf;
		
		FillInRowOfCellStructureAccordingToTreeData(Parameters, NewRow, String);
		FillInRowOfCellStructureAccordingToTreeData(Parameters, NewRow, Column);
		
		WithdrawalCurrency = CurrencyForEnteringAnalytics(NewRow, CacheOfCurrencyItemDetails);
		
		If NewRow.Owner().Columns.Find("UnitOfMeasure") <> Undefined Then
			NewRow.UnitOfMeasure = AnalyticsInputUnit(NewRow, CacheOfArticleDetailsEd);
		EndIf;
		
		If NewRow.ItemKind = Enums.FinancialReportItemKinds.BudgetFlowItem
			Or NewRow.ItemKind = Enums.FinancialReportItemKinds.BudgetBalanceItem Then
			
			Indicators = FinancialReportingServer.ValueOfAdditionalProps(Item, "DisplayedIndicators", CacheOfAdditionalBankingDetails);
			
			If Indicators = Enums.TypesOfDisplayedBudgetReportIndicators.QuantityAndAmount
				Or Indicators = Enums.TypesOfDisplayedBudgetReportIndicators.Sum Then
				Currency = NewRow.Currency;
				If ValueIsFilled(Currency)
					And ValueIsFilled(WithdrawalCurrency) Then
					If Currency <> WithdrawalCurrency Then
						NewRow.FlagSum = False;
						NewRow.FlagCount = False;
					EndIf;
				EndIf;
			EndIf;
			
		EndIf;
		
		//@skip-check query-in-loop
		FillInInformationAboutDataSource(NewRow,
			DataSources,
			SourcesOfGroupingPeriods,
			Item,
			SubordinateRows,
			Parameters);
		
	EndDo;
	
	Return AddedRows;
	
EndFunction

Function ItIsPossibleToSummarizeSubordinateStrings(SubordinateRows)
	
	PreviousSourceField = Undefined;
	For Each String In SubordinateRows Do
		If PreviousSourceField <> Undefined
			And String.SourceField <> PreviousSourceField Then
			
			Return False;
			
		EndIf;
		PreviousSourceField = String.SourceField;
	EndDo;
	
	Return True;
	
EndFunction

Function CalculatePartOfFormulaWithTotalAndOperand(Formula, OperandName, BeginningOfFormula, EndOfFormula)
	
	FoundPosition = StrFind(Upper(Formula), Upper(OperandName));
	EndOfFormula = FoundPosition + StrLen(OperandName);
	
	// checking that the "TOTAL" is applied to the operand
	FunctionNameWithParenthesis = Upper("TOTAL(");
	NumberOfPositionsWithBracket = StrLen(FunctionNameWithParenthesis);
	NumberOfPositionsWithoutParenthesis = NumberOfPositionsWithBracket - 1;
	
	BeginningOfFormula = 0;
	Cnt = FoundPosition - NumberOfPositionsWithBracket;
	Found4 = False;
	While Cnt > 0 Do
		If Upper(Mid(Formula, Cnt, NumberOfPositionsWithBracket)) = FunctionNameWithParenthesis Then
			BeginningOfFormula = Cnt;
			Found4 = True;
			Break;
		EndIf;
		VerificationPosition = Cnt + NumberOfPositionsWithoutParenthesis;
		If TrimAll(Mid(Formula, VerificationPosition, 1)) <> "" Then
			Return Undefined; // a symbol is inserted before the operand and the total function
		EndIf;
		Cnt = Cnt - 1;
	EndDo;
	
	If Not Found4 Then
		Return Undefined;
	EndIf;
	
	Return Mid(Formula, BeginningOfFormula, EndOfFormula - BeginningOfFormula);
	
EndFunction

// This method changes the composition of rows in the "cell Structure" table in the budget type description structure.
//
// Parameters:
//  Formula - Arbitrary - Formula
//  StructureOfPeriodFlags - Structure - Structure of period flags
//  OperandString_ - ValueTableRow - Operand string
//  ColumnNamesForFormulas - Map of KeyAndValue - Column names for formulas
// 
// Returns:
//  Array of ValueTableRow
//
Function AddTechnicalInformationToSummaryFunction(Formula, StructureOfPeriodFlags, OperandString_, ColumnNamesForFormulas)
	Var BeginningOfFormula, EndOfFormula;
	
	ListOfAdded = New Array;
	
	OperandName = "[" + OperandString_.OperandName + "]";
	PartOfFunction = PartOfFormulaWithTotalAndOperand(Formula, OperandName, BeginningOfFormula, EndOfFormula);
	
	MatchingFunctionNames = New Map;
	PartsOfFunctionPreparedForCalculation = New Map;
	
	While PartOfFunction <> Undefined Do
		
		SecondPartOfFormula = EndOfFormula(Formula, EndOfFormula);
		
		BeautifulOperandName = StrReplace(PartOfFunction + SecondPartOfFormula + ")", """", "'");
		SearchRow = "," + " " + " ";
		While StrFind(BeautifulOperandName, SearchRow) <> 0 Do
			BeautifulOperandName = StrReplace(BeautifulOperandName, SearchRow, ", ");
		EndDo;
		SearchRow = " " + ",";
		While StrFind(BeautifulOperandName, SearchRow) <> 0 Do
			BeautifulOperandName = StrReplace(BeautifulOperandName, SearchRow, ",");
		EndDo;
		SearchRow = "] ";
		While StrFind(BeautifulOperandName, SearchRow) <> 0 Do
			BeautifulOperandName = StrReplace(BeautifulOperandName, SearchRow, "]");
		EndDo;
		SearchRow = " [";
		While StrFind(BeautifulOperandName, SearchRow) <> 0 Do
			BeautifulOperandName = StrReplace(BeautifulOperandName, SearchRow, "[");
		EndDo;
		BeautifulOperandName = StrReplace(BeautifulOperandName, "[", "'");
		BeautifulOperandName = StrReplace(BeautifulOperandName, "]", "'");
		
		PartOfFormulaAdded = Not PartsOfFunctionPreparedForCalculation.Get(BeautifulOperandName) = Undefined;
		
		// The repeating parts of the formula will be calculated once
		// They are assigned a single total identifier.
		If Not PartOfFormulaAdded Then
			NewOperand = OperandString_.Owner().Add();
			
			FillPropertyValues(NewOperand, OperandString_);
			
			NewOperand.OperandName = "Total_" + New UUID;
			
			ListOfAdded.Add(NewOperand);
			MatchingFunctionNames.Insert(NewOperand.OperandName, BeautifulOperandName);
			PartsOfFunctionPreparedForCalculation.Insert(BeautifulOperandName, NewOperand.OperandName);
		EndIf;
		
		RealFirstPartOfFormula = "TOTAL(CellData_, CellParameters, PeriodParameters_1, Prefix, Postfix, DataString1, CalculationLog, CacheOfBudgetItemDetails, """ + NewOperand.OperandName + """";
		
		MeasurementList = TrimAll(SecondPartOfFormula);
		MeasurementList = TrimAll(Mid(MeasurementList, 2)); // the comma is cut off
		MeasurementList = Left(MeasurementList, StrLen(MeasurementList) - 1); //the last quotation mark is cut off
		MeasurementList = Mid(MeasurementList, 2); // the first quotation mark is cut off
		ArrayOfDimensionHeaders = StringFunctionsClientServer.SplitStringIntoSubstringsArray(Upper(MeasurementList),,True, True);
		ResultingArray = New Array;
		For Each DimensionName In ArrayOfDimensionHeaders Do
			ColumnName = ColumnNamesForFormulas.Get(Upper(DimensionName));
			If ColumnName <> Undefined Then
				Column = OperandString_.Owner().Columns[ColumnName];
				
				// For the totaled indicators, we will clear the measurement flags of the report for summation
				// when calculating cell data.
				If StructureOfPeriodFlags <> Undefined And
					BudgetReportingClientServer.ThisIsPeriodField(Column.Name) Then
					StructureOfPeriodFlags.Insert("Flag" + Column.Name, "fill");
				EndIf;
				If OperandString_.OperandType <> Enums.FinancialReportItemKinds.NonFinancialItem Then
					NewOperand["Flag" + Column.Name] = "";
				EndIf;
				
				ResultingArray.Add(Column.Name);
			EndIf;
		EndDo;
		ListOfRealMeasurements = StrConcat(ResultingArray, ",");
		RealSecondPartOfFormula = StrReplace(SecondPartOfFormula, MeasurementList, ListOfRealMeasurements);
		
		NewPartOfFunction = RealFirstPartOfFormula + RealSecondPartOfFormula;
		Formula = Left(Formula, BeginningOfFormula - 1) + NewPartOfFunction + Mid(Formula, EndOfFormula);
		PartOfFunction = PartOfFormulaWithTotalAndOperand(Formula, OperandName, BeginningOfFormula, EndOfFormula);
		
	EndDo;
	
	// If the operand is also used outside the TOTAL function, we will leave it
	// otherwise - we will delete it.
	If StrFind(Formula, OperandName) Then
		ListOfAdded.Add(OperandString_);
	Else
		OperandString_.Owner().Delete(OperandString_);
	EndIf;
	
	For Each OperandString_ In ListOfAdded Do
		FormulaName = MatchingFunctionNames.Get(OperandString_.OperandName);
		If FormulaName <> Undefined Then
			Formula = StrReplace(Formula, OperandString_.OperandName, FormulaName);
			OperandString_.OperandName = FormulaName;
		EndIf;
	EndDo;
	
	Return ListOfAdded;
	
EndFunction

Procedure FillInOperandString(OperandData, OperandString_, CacheOfAdditionalBankingDetails)
	
	If OperandString_.OperandType = Enums.FinancialReportItemKinds.AllBudgetFlowItems Then
		
		OperandString_.BudgetFlowItem = Undefined;
		OperandString_.FlagBudgetFlowItem = "";
		Attributes = FinancialReportingServerCall.AdditionalAttributesValues(
														OperandData.Operand, "DisplayedIndicators");
		OperandString_.FlagSum = Attributes.DisplayedIndicators = Enums.TypesOfDisplayedBudgetReportIndicators.Sum;
		OperandString_.FlagCount = Attributes.DisplayedIndicators = Enums.TypesOfDisplayedBudgetReportIndicators.Count;
		
	ElsIf OperandString_.OperandType = Enums.FinancialReportItemKinds.AllBudgetBalanceItems Then
		
		OperandString_.BudgetBalanceItem = Undefined;
		OperandString_.FlagBudgetBalanceItem = "";
		Attributes = FinancialReportingServerCall.AdditionalAttributesValues(
														OperandData.Operand, "DisplayedIndicators");
		OperandString_.FlagSum = Attributes.DisplayedIndicators = Enums.TypesOfDisplayedBudgetReportIndicators.Sum;
		OperandString_.FlagCount = Attributes.DisplayedIndicators = Enums.TypesOfDisplayedBudgetReportIndicators.Count;
		
	ElsIf OperandString_.OperandType = Enums.FinancialReportItemKinds.BudgetFlowItem Then
		
		BudgetFlowItem = FinancialReportingServer.ValueOfAdditionalProps(
														OperandData.Operand, "BudgetFlowItem", CacheOfAdditionalBankingDetails);
		DisplayedIndicators = FinancialReportingServer.ValueOfAdditionalProps(
														OperandData.Operand, "DisplayedIndicators", CacheOfAdditionalBankingDetails);
		OperandString_.BudgetFlowItem = BudgetFlowItem;
		OperandString_.FlagBudgetFlowItem = "pick";
		OperandString_.FlagSum = DisplayedIndicators = Enums.TypesOfDisplayedBudgetReportIndicators.Sum;
		OperandString_.FlagCount = DisplayedIndicators = Enums.TypesOfDisplayedBudgetReportIndicators.Count;
		
	ElsIf OperandString_.OperandType = Enums.FinancialReportItemKinds.BudgetBalanceItem Then
		
		BudgetBalanceItem = FinancialReportingServer.ValueOfAdditionalProps(
														OperandData.Operand, "BudgetBalanceItem", CacheOfAdditionalBankingDetails);
		DisplayedIndicators = FinancialReportingServer.ValueOfAdditionalProps(
														OperandData.Operand, "DisplayedIndicators", CacheOfAdditionalBankingDetails);
		OperandString_.BudgetBalanceItem = BudgetBalanceItem;
		OperandString_.FlagBudgetBalanceItem = "pick";
		OperandString_.FlagSum = DisplayedIndicators = Enums.TypesOfDisplayedBudgetReportIndicators.Sum;
		OperandString_.FlagCount = DisplayedIndicators = Enums.TypesOfDisplayedBudgetReportIndicators.Count;
		
	ElsIf OperandString_.OperandType = Enums.FinancialReportItemKinds.NonFinancialItem Then
		
		NonFinancialItem = FinancialReportingServer.ValueOfAdditionalProps(
														OperandData.Operand, "NonFinancialItem", CacheOfAdditionalBankingDetails);
		OperandString_.NonFinancialItem = NonFinancialItem;
		OperandString_.FlagNonFinancialItem = "pick";
		OperandString_.FlagValue = True;
		
	ElsIf OperandString_.OperandType = Enums.FinancialReportItemKinds.EditedValue Then
		
		OperandString_.EditedValue = Common.ObjectAttributeValue(OperandData.Operand,
			"NameForPrinting");
		OperandString_.FlagEditedValue = "pick";
		OperandString_.FlagValue = True;
		
	ElsIf OperandString_.OperandType = Enums.FinancialReportItemKinds.TableCell Then
		
		CellRow = FinancialReportingServer.ValueOfAdditionalProps(
														OperandData.Operand, "CellRow", CacheOfAdditionalBankingDetails);
		CellColumn = FinancialReportingServer.ValueOfAdditionalProps(
														OperandData.Operand, "CellColumn", CacheOfAdditionalBankingDetails);
		OperandString_.OperandString = CellRow;
		OperandString_.OperandColumn_ = CellColumn;
		
	EndIf;
	
EndProcedure

Function FillCellsOfFormulaOperands(Parameters, NewRow, DataSources, SourcesOfGroupingPeriods, Operands)
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	CacheOfAdditionalBankingDetails = Parameters.CacheOfAdditionalBankingDetails;
	StructureOfPeriodFlags = New Structure;
	OperandFlags = New Array;
	
	MonetaryNFP = Undefined;
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
		|	FinancialReportItemsItemKindAttributes.Ref AS Operand
		|FROM
		|	Catalog.FinancialReportItems.ItemKindAttributes AS FinancialReportItemsItemKindAttributes
		|		INNER JOIN Catalog.NonFinancialItemsOfBudgets AS NonFinancialItemsOfBudgets
		|		ON FinancialReportItemsItemKindAttributes.Value = NonFinancialItemsOfBudgets.Ref
		|			AND (FinancialReportItemsItemKindAttributes.Attribute = &ElementTypeDetails)
		|			AND (FinancialReportItemsItemKindAttributes.Ref.ItemKind = VALUE(Enum.FinancialReportItemKinds.NonFinancialItem))
		|			AND (NonFinancialItemsOfBudgets.IndicatorKind = VALUE(Enum.NonFinancialItemKinds.Cash_))
		|WHERE
		|	FinancialReportItemsItemKindAttributes.Ref IN(&Operands)";
	
	Query.SetParameter("ElementTypeDetails",ChartsOfCharacteristicTypes.ItemAttributesOfFinancialReports.NonFinancialItem);
	OperandAnalysis_ = New Map;
	
	KindsOfOperands = Common.ObjectsAttributeValue(Operands.UnloadColumn("Operand"), "ItemKind");
	For Each OperandData In Operands Do
		
		OperandString_ = NewRow.Owner().Add();
		
		OperandType = KindsOfOperands.Get(OperandData.Operand);
		If OperandType = Enums.FinancialReportItemKinds.TableCell Then
			FillPropertyValues(OperandString_, NewRow, "String, Column, ItemKind");
		Else
			FillPropertyValues(OperandString_, NewRow,,"Formula, ID_Source1, SourceField, FlagSum, FlagCount, FlagValue, ReverseSign");
		EndIf;
		FillInInformationAboutDataSource(OperandString_,
			DataSources,
			SourcesOfGroupingPeriods,
			OperandData.Operand,
			Undefined,
			Parameters);
		
		OperandString_.OperandName = OperandData.Id;
		OperandString_.OperandType = OperandType;
		OperandString_.MainItem = False;
		OperandString_.CalculationFilling = "total";
		
		If OperandType = Enums.FinancialReportItemKinds.NonFinancialItem
			And OperandString_.FlagCurrency = "pick" Then
			If MonetaryNFP = Undefined Then
				Query.SetParameter("Operands", Operands);
				MonetaryNFP = Query.Execute().Unload();
			EndIf;
			If MonetaryNFP.Find(OperandData.Operand,"Operand") = Undefined Then
				OperandString_.FlagCurrency = "";
			EndIf;
		EndIf;
		
		If StrFind(Upper(NewRow.Formula), "TOTAL(") Then
			AddedTotals = AddTechnicalInformationToSummaryFunction(NewRow.Formula,
					StructureOfPeriodFlags,
					OperandString_,
					Parameters.ColumnNamesForFormulas);
			For Each OperandString_ In AddedTotals Do
				If Not StrFind(Upper(OperandString_.OperandName), "TOTAL(") Then
					NewRow.ListOfOperands = NewRow.ListOfOperands + " [" + OperandString_.OperandName + "]";
				EndIf;
				FillInOperandString(OperandData, OperandString_, CacheOfAdditionalBankingDetails);
			EndDo;
			ArrayOfOperandStrings = AddedTotals;
		Else
			NewRow.ListOfOperands = NewRow.ListOfOperands + " [" + OperandString_.OperandName + "]";
			FillInOperandString(OperandData, OperandString_, CacheOfAdditionalBankingDetails);
			If NewRow.FlagSum And NewRow.FlagCount Then
				FillPropertyValues(OperandString_, NewRow, "FlagSum,FlagCount");
			EndIf;
			ArrayOfOperandStrings = CommonClientServer.ValueInArray(OperandString_);
		EndIf;
			
		For Each OperandString_ In ArrayOfOperandStrings Do
			If NewRow.CalculationFilling = "filltype" Then
				// If there is no accounting for analytics on the operand
				// , then the filter for analytics is ignored when filling in.
				
				For Each DimensionKind In Parameters.DescriptionOfReport.DimensionKinds Do
					SelectByValue = False;
					If OperandString_.OperandType = Enums.FinancialReportItemKinds.BudgetFlowItem Then
						For Cnt = 1 To MaximumNumberOfAnalysts Do
							DimensionARTICLES__ = BudgetReportingDisplayServer.Attachable_ValueFromAnalytics(Parameters.CacheAnalystArticles, 
																										OperandString_.BudgetFlowItem,
																										"DimensionKind" + Cnt);
							If DimensionARTICLES__ = DimensionKind Then
								SelectByValue = True;
							EndIf;
						EndDo;
					EndIf;
					If OperandString_.OperandType = Enums.FinancialReportItemKinds.BudgetBalanceItem Then
						For Cnt = 1 To MaximumNumberOfAnalysts Do
							DimensionARTICLES__ = BudgetReportingDisplayServer.Attachable_ValueFromAnalytics(Parameters.CacheAnalystArticles, 
																										OperandString_.BudgetBalanceItem,
																										"DimensionKind" + Cnt);
							If DimensionARTICLES__ = DimensionKind Then
								SelectByValue = True;
							EndIf;
						EndDo;
					EndIf;
					If OperandString_.OperandType = Enums.FinancialReportItemKinds.NonFinancialItem Then
						For Cnt = 1 To MaximumNumberOfAnalysts Do
							DimensionARTICLES__ = BudgetReportingDisplayServer.Attachable_ValueFromAnalytics(Parameters.CacheAnalystArticles, 
																										OperandString_.NonFinancialItem,
																										"DimensionKind" + Cnt);
							If DimensionARTICLES__ = DimensionKind Then
								SelectByValue = True;
							EndIf;
						EndDo;
					EndIf;
					If Not SelectByValue Then
						OperandString_["Flag" + FinancialReportingCached.NameOfBudgetReportField(DimensionKind)] = "";
					EndIf;
				EndDo;
			EndIf;
			
			OperandStructure = New Structure("FlagSum, FlagCount");
			FillPropertyValues(OperandStructure, OperandString_);
			OperandFlags.Add(OperandStructure);
			
			OperandAnalysis_1 = New Array;
			ItemKind = KindsOfOperands.Get(OperandData.Operand);
			SourceAttributeName = "";
			If ItemKind = Enums.FinancialReportItemKinds.BudgetFlowItem Then
				SourceAttributeName = "BudgetFlowItem";
			ElsIf ItemKind = Enums.FinancialReportItemKinds.BudgetBalanceItem Then
				SourceAttributeName = "BudgetBalanceItem";
			ElsIf ItemKind = Enums.FinancialReportItemKinds.NonFinancialItem Then
				SourceAttributeName = "NonFinancialItem";
			EndIf;
			If ValueIsFilled(SourceAttributeName) Then
				SourceAnalytics = OperandString_[SourceAttributeName];
				For Cnt = 1 To MaximumNumberOfAnalysts Do
					DimensionARTICLES__ = BudgetReportingDisplayServer.Attachable_ValueFromAnalytics(Parameters.CacheAnalystArticles, 
																										SourceAnalytics,
																										"DimensionKind" + Cnt);
					
					If ValueIsFilled(DimensionARTICLES__) Then
						OperandAnalysis_1.Add(DimensionARTICLES__);
					EndIf;
				EndDo;
				OperandAnalysis_.Insert(OperandString_.OperandName, OperandAnalysis_1);
			EndIf;
			
		EndDo;
		
	EndDo;
	
	For Each KeyAndValue In StructureOfPeriodFlags Do
		
		NewRow[KeyAndValue.Key] = KeyAndValue.Value;
		
	EndDo;
	
	NewRow.OperandAnalysis_ = OperandAnalysis_;
	
	Return OperandFlags;
	
EndFunction

// LongDesc
// 
// Parameters:
// 	ColumnTree - ValueTree - consists of:
// 		* Ref - CatalogRef.FinancialReportItems -
// 		* Code - Number - 
// 	TableRowColumn - ValueTable - LongDesc:
// * String - CatalogRef.FinancialReportItems, Arbitrary -
// * Column - CatalogRef.FinancialReportItems, Arbitrary -
// 	FixedLine - CatalogRef.FinancialReportItems -
Procedure BypassSubordinateColumns(ColumnTree, TableRowColumn, FixedLine)
	
	For Each TreeRow In ColumnTree.Rows Do
		
		If TreeRow.ItemKind = Enums.FinancialReportItemKinds.GroupFormula Then
			Continue;
		EndIf;
		
		If TreeRow.ItemKind = Enums.FinancialReportItemKinds.DerivedItem
			Or TreeRow.ItemKind = Enums.FinancialReportItemKinds.BudgetFlowItem
			Or TreeRow.ItemKind = Enums.FinancialReportItemKinds.BudgetBalanceItem
			Or TreeRow.ItemKind = Enums.FinancialReportItemKinds.NonFinancialItem
			Or TreeRow.ItemKind = Enums.FinancialReportItemKinds.EditedValue Then
			Line1_2 = TableRowColumn.Add();
			Line1_2.Column = TreeRow.Ref;
			Line1_2.String = FixedLine;
			Continue;
		EndIf;
		
		If TreeRow.ItemKind = Enums.FinancialReportItemKinds.Group 
			And TreeRow.Rows.Find(Enums.FinancialReportItemKinds.GroupFormula, "ItemKind") <> Undefined Then
			Line1_2 = TableRowColumn.Add();
			Line1_2.Column = TreeRow.Ref;
			Line1_2.String = FixedLine;
			Continue;
		EndIf;
		
		If Not TreeRow.Rows.Count() Then
			Line1_2 = TableRowColumn.Add();
			Line1_2.Column = TreeRow.Ref;
			Line1_2.String = FixedLine;
			Continue;
		EndIf;
		
		BypassSubordinateColumns(TreeRow, TableRowColumn, FixedLine);
		
	EndDo;
	
EndProcedure

// Fills in information about data sources in the cell structure row.
// 
// Parameters:
// 	NewRow - ValueTableRow - Row of the Cell Structuration table:
// 	 *String - CatalogRef.FinancialReportItems - Budget line.
// 	 *Column - CatalogRef.FinancialReportItems - Column of the budget.
// 	DataSources - Array of Structure - Array of data sources.
// 	SourcesOfGroupingPeriods - Array of Structure - An array of sources and periods.
// 	Item - CatalogRef.FinancialReportItems - Report item.
// 	SubordinateRows - Array of ValueTableRow - Array Of Subordinate Strings:
// 	 *String - CatalogRef.FinancialReportItems - Budget line.
// 	 *Column - CatalogRef.FinancialReportItems - Column of the budget.
// 	Parameters - Structure - The structure of the report parameters.
Procedure FillInInformationAboutDataSource(NewRow, DataSources, SourcesOfGroupingPeriods, Item, SubordinateRows, Parameters)
	
	RequiresSource = True;
	NewRow.MainItem = True;
	CacheOfAdditionalBankingDetails = Parameters.CacheOfAdditionalBankingDetails;
	AttributeCache = Parameters.AttributeCache;
	CacheOfSubordinateFormulaElements = Parameters.CacheOfSubordinateFormulaElements;
	
	StringTypeOfComparisonElement = ValueOfBudgetViewElementSProps(NewRow.String, "ItemKind", AttributeCache);
	If ValueIsFilled(NewRow.Column) Then
		ColumnViewOfComparisonElement = ValueOfBudgetViewElementSProps(NewRow.Column, "ItemKind", AttributeCache);
	Else
		ColumnViewOfComparisonElement = Undefined;
	EndIf;
	
	If ValueIsFilled(Item) Then
		TypeOfComparisonElement = ValueOfBudgetViewElementSProps(Item, "ItemKind", AttributeCache);
	Else
		TypeOfComparisonElement = Undefined;
	EndIf;
	
	If StringTypeOfComparisonElement = Enums.FinancialReportItemKinds.GroupFormula
		Or ColumnViewOfComparisonElement = Enums.FinancialReportItemKinds.GroupFormula Then
		
		RequiresSource = False;
		
		TableRowColumn = New ValueTable;
		TableRowColumn.Columns.Add("String");
		TableRowColumn.Columns.Add("Column");
		
		Query = New Query;
		
		If ColumnViewOfComparisonElement = Enums.FinancialReportItemKinds.GroupFormula Then
			
			ColumnTree = CacheOfSubordinateFormulaElements[NewRow.Column];
			If ColumnTree = Undefined Then
			
				Query.Text = 
				"SELECT
				|	FinancialReportItems.Ref AS Ref,
				|	FinancialReportItems.Code AS Code,
				|	FinancialReportItems.ItemKind
				|FROM
				|	Catalog.FinancialReportItems AS FinancialReportItems
				|WHERE
				|	FinancialReportItems.Ref IN HIERARCHY(&Parent)
				|	AND NOT FinancialReportItems.Ref = &Parent
				|	AND NOT FinancialReportItems.Ref = &Ref
				|
				|ORDER BY
				|	Code HIERARCHY";
				
				Group = ValueOfBudgetViewElementSProps(NewRow.Column, "Parent", AttributeCache);
				Query.SetParameter("Parent", Group);
				Query.SetParameter("Ref", NewRow.Column);
				QueryResult = Query.Execute();
				ColumnTree = QueryResult.Unload(QueryResultIteration.ByGroupsWithHierarchy);
				
				CacheOfSubordinateFormulaElements.Insert(NewRow.Column, ColumnTree);
				
			EndIf;
				
			BypassSubordinateColumns(ColumnTree, TableRowColumn, NewRow.String);
			NewRow.ReverseSign = ValueOfBudgetViewElementSProps(NewRow.Column, "ReverseSign", AttributeCache);
			
			TypeOfFormula = FinancialReportingServer.ValueOfAdditionalProps(
																		NewRow.Column, "GroupFormula", CacheOfAdditionalBankingDetails);
			
		Else
			
			TableOfRows = CacheOfSubordinateFormulaElements[NewRow.String];
			If TableOfRows = Undefined Then
				
				Query.Text = 
				"SELECT
				|	FinancialReportItems.Ref,
				|	FinancialReportItems.Code AS Code
				|FROM
				|	Catalog.FinancialReportItems AS FinancialReportItems
				|WHERE
				|	FinancialReportItems.Parent IN
				|			(SELECT TOP 1
				|				Filter.Parent
				|			FROM
				|				Catalog.FinancialReportItems AS Filter
				|			WHERE
				|				Filter.Ref = &Ref)
				|	AND NOT FinancialReportItems.ItemKind = VALUE(Enum.FinancialReportItemKinds.GroupFormula)
				|
				|ORDER BY
				|	Code";
				
				Query.SetParameter("Ref", NewRow.String);
				QueryResult = Query.Execute();
				TableOfRows = QueryResult.Unload();
				
				CacheOfSubordinateFormulaElements.Insert(NewRow.String, TableOfRows);
				
			EndIf;
			
			For Each SelectionDetailRecords In TableOfRows Do
				
				LineForCalculatingTotals = SelectionDetailRecords.Ref;
				
				CacheOfSubordinatesOutputWithParent = Parameters.CacheOfSubordinatesOutputWithParent;
				DownstreamElement = CacheOfSubordinatesOutputWithParent.Get(LineForCalculatingTotals);
				While DownstreamElement <> Undefined Do
					LineForCalculatingTotals = DownstreamElement;
					DownstreamElement = CacheOfSubordinatesOutputWithParent.Get(LineForCalculatingTotals);
				EndDo;
				
				Line1_2 = TableRowColumn.Add();
				Line1_2.Column = NewRow.Column;
				Line1_2.String = LineForCalculatingTotals;
			EndDo;
			
			TypeOfFormula = FinancialReportingServer.ValueOfAdditionalProps(
																		NewRow.String, "GroupFormula", CacheOfAdditionalBankingDetails);
			
			NewRow.ReverseSign = ValueOfBudgetViewElementSProps(NewRow.String, "ReverseSign", AttributeCache);
			
		EndIf;
		
		If Not TableRowColumn.Count() Then
			Formula = "";
		Else
			For Each String In TableRowColumn Do
				
				OperandString_ = NewRow.Owner().Add();
				FillPropertyValues(OperandString_, NewRow, "String, Column");
				OperandString_.OperandCalculationProcedure = TableRowColumn.IndexOf(String);
				OperandString_.OperandName = ValueOfBudgetViewElementSProps(String.String, "NameForPrinting", AttributeCache) + 
					?(ValueIsFilled(String.Column), "; " + ValueOfBudgetViewElementSProps(String.Column, "NameForPrinting", AttributeCache), "");
				OperandString_.OperandType = Enums.FinancialReportItemKinds.TableCell;
				OperandString_.ItemKind = Enums.FinancialReportItemKinds.GroupFormula;
				OperandString_.MainItem = False;
				OperandString_.OperandString = String.String;
				OperandString_.OperandColumn_ = String.Column;
				
			EndDo;
			Formula = Enums.BudgetingFormulaKinds.FunctionName(TypeOfFormula) + "(ArrayOfValues)";
		EndIf;
		
		NewRow.Formula = Formula;
		NewRow.ItemKind = Enums.FinancialReportItemKinds.GroupFormula;
		NewRow.CalculationFilling = "total";
		
	ElsIf StringTypeOfComparisonElement = Enums.FinancialReportItemKinds.Group
		Or ColumnViewOfComparisonElement = Enums.FinancialReportItemKinds.Group Then
		
		RequiresSource = False;
		
		Query = New Query;
		Query.Text = 
		"SELECT TOP 1
		|	FinancialReportItems.Ref
		|FROM
		|	Catalog.FinancialReportItems AS FinancialReportItems
		|WHERE
		|	FinancialReportItems.Parent = &Ref
		|	AND FinancialReportItems.ItemKind = VALUE(Enum.FinancialReportItemKinds.GroupFormula)";
		
		FormulaString = Undefined;
		FormulaColumn = Undefined;
		
		If ColumnViewOfComparisonElement = Enums.FinancialReportItemKinds.Group Then
			
			LinkToFormula = CacheOfSubordinateFormulaElements[NewRow.Column];
			If LinkToFormula = Undefined Then
				Query.SetParameter("Ref", NewRow.Column);
				QueryResult = Query.Execute();
				SelectionDetailRecords = QueryResult.Select();
				While SelectionDetailRecords.Next() Do
					LinkToFormula = SelectionDetailRecords.Ref;
				EndDo;
				If Not ValueIsFilled(LinkToFormula) Then
					LinkToFormula = Catalogs.FinancialReportItems.EmptyRef();
				EndIf;
				CacheOfSubordinateFormulaElements.Insert(NewRow.Column, LinkToFormula);
			EndIf;
			
			FormulaString = NewRow.String;
			FormulaColumn = LinkToFormula;
			
		Else
			
			LinkToFormula = CacheOfSubordinateFormulaElements[NewRow.String];
			If LinkToFormula = Undefined Then
				Query.SetParameter("Ref", NewRow.String);
				QueryResult = Query.Execute();
				SelectionDetailRecords = QueryResult.Select();
				While SelectionDetailRecords.Next() Do
					LinkToFormula = SelectionDetailRecords.Ref;
				EndDo;
				If Not ValueIsFilled(LinkToFormula) Then
					LinkToFormula = Catalogs.FinancialReportItems.EmptyRef();
				EndIf;
				CacheOfSubordinateFormulaElements.Insert(NewRow.String, LinkToFormula);
			EndIf;
			
			FormulaString = LinkToFormula;
			FormulaColumn = NewRow.Column;
			
		EndIf;
		
		If Not ValueIsFilled(LinkToFormula) Then
			Formula = "";
		Else
			
			OperandString_ = NewRow.Owner().Add();
			FillPropertyValues(OperandString_, NewRow, "String, Column");
			OperandString_.OperandName = NStr("vi = 'Công thức nhóm';
												|ru = 'Формула по группе';
												|en = 'Group formula'; fa = 'فرمول گروه';
												|it = 'Formula secondo il gruppo';
												|pl = 'Formuła według grupy';
												|tr = 'Gruba göre formül'");
			OperandString_.OperandType = Enums.FinancialReportItemKinds.TableCell;
			OperandString_.ItemKind = Enums.FinancialReportItemKinds.Group;
			OperandString_.MainItem = False;
			OperandString_.OperandString = FormulaString;
			OperandString_.OperandColumn_ = FormulaColumn;
			Formula = "[" + OperandString_.OperandName + "]";
			
		EndIf;
		
		NewRow.Formula = Formula;
		NewRow.ItemKind = Enums.FinancialReportItemKinds.Group;
		NewRow.CalculationFilling = "total";
		
	ElsIf Not ValueIsFilled(Item) Then // calculation by subordinate lines
		
		RequiresSource = False;
		
		NewRow.FlagCount = False;
		NewRow.FlagSum = False;
		
		Formula = "";
		SequenceNumberOfLine = 0;
		For Each String In SubordinateRows Do
			
			SequenceNumberOfLine = SequenceNumberOfLine + 1;
			OperandString_ = NewRow.Owner().Add();
			FillPropertyValues(OperandString_, NewRow, "String, Column");
			OperandString_.OperandName = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chuỗi lồng nhau #%1';
					|ru = 'Вложенная строка #%1';
					|en = 'Nested line %1'; fa = 'Nested line %1';
					|it = 'Riga allegata #%1';
					|pl = 'Wiersz włożony #%1';
					|tr = '#%1 iç içe geçmiş satırları'"),
				SequenceNumberOfLine);
			OperandString_.OperandType = Enums.FinancialReportItemKinds.TableCell;
			OperandString_.MainItem = False;
			OperandString_.OperandString = String.String;
			OperandString_.OperandColumn_ = String.Column;
			Formula = Formula + "SUM([" + OperandString_.OperandName + "]) + ";
			
			NewRow.FlagCount = NewRow.FlagCount Or String.FlagCount;
			NewRow.FlagSum = NewRow.FlagSum Or String.FlagSum;
			
		EndDo;
		
		Formula = Left(Formula, StrLen(Formula) - 3);
		NewRow.Formula = Formula;
		NewRow.ItemKind = Enums.FinancialReportItemKinds.DerivedItem;
		NewRow.CalculationFilling = "total";
		
	ElsIf TypeOfComparisonElement = Enums.FinancialReportItemKinds.DerivedItem Then
		
		RequiresSource = False;
		
		Formula = FinancialReportingServer.ValueOfAdditionalProps(Item, "Formula", CacheOfAdditionalBankingDetails);
		If StrFind(Upper(Formula), "TOTAL(")
			Or StrFind(Upper(Formula), "DATEDIFF(") Then
			NewRow.FormulaPresentation = Formula;
		EndIf;
		NewRow.Formula = Formula;
		OperandFlags = FillCellsOfFormulaOperands(Parameters, NewRow, 
															DataSources, SourcesOfGroupingPeriods, Item.FormulaOperands);
		If StrFind(Upper(NewRow.Formula), "DATEDIFF(") Then
			AddTechnicalInformationToDateDifferenceFunction(NewRow.Formula);
		EndIf;
		
		NewRow.CalculationFilling = "total";
		
		OperandsOfSumFlag = False;
		OperandsFlagNumber = False;
		For Each SubordinateRow In OperandFlags Do
			OperandsOfSumFlag = OperandsOfSumFlag Or SubordinateRow.FlagSum;
			OperandsFlagNumber = OperandsFlagNumber Or SubordinateRow.FlagCount;
		EndDo;
		
		If OperandsFlagNumber And Not OperandsOfSumFlag Then
			FlagSum = False;
			FlagCount = True;
		Else
			FlagSum = True;
			FlagCount = False;
		EndIf;
		
		NewRow.FlagCount = FlagCount;
		NewRow.FlagSum = FlagSum;
			
	ElsIf TypeOfComparisonElement = Enums.FinancialReportItemKinds.BudgetFlowItem Then
		
		NewRow.SourceField = "Turnover";
		CalculationFilling = FinancialReportingServer.ValueOfAdditionalProps(Item, "FillingMethod", CacheOfAdditionalBankingDetails);
		
		NewRow.CalculationFilling = "";
		If SubordinateRows <> Undefined 
			And SubordinateRows.Count() Then
			NewRow.CalculationFilling = "total";
		ElsIf CalculationFilling = 1 Then
			NewRow.CalculationFilling = "recalculate";
		ElsIf CalculationFilling = 2 Then
			NewRow.CalculationFilling = "filltype";
		ElsIf CalculationFilling = 3 Then
			NewRow.CalculationFilling = "calculation";
		EndIf;
		
		If Not ValueIsFilled(CalculationFilling)
			And Not ValueIsFilled(NewRow.CalculationFilling) Then
			CurrentItem = NewRow.String;
			ItemKind = StringTypeOfComparisonElement;
			While ItemKind <> Undefined
				And ItemKind <> Enums.FinancialReportItemKinds.Rows Do
				If ItemKind = Enums.FinancialReportItemKinds.Dimension Then
					SourceAllElements = FinancialReportingServer.ValueOfAdditionalProps(CurrentItem, "SourceAllElements", CacheOfAdditionalBankingDetails);
					If SourceAllElements = True Then
						NewRow.CalculationFilling = "filltype";
						Break;
					EndIf;
				EndIf;
				CurrentItem = ValueOfBudgetViewElementSProps(CurrentItem, "Parent", AttributeCache);
				If ValueIsFilled(CurrentItem) Then
					ItemKind = ValueOfBudgetViewElementSProps(CurrentItem, "ItemKind", AttributeCache);
				Else
					ItemKind = Undefined;
				EndIf;
			EndDo;
		EndIf;
		If Not ValueIsFilled(NewRow.CalculationFilling)
			And ValueIsFilled(ColumnViewOfComparisonElement) Then
			CurrentItem = NewRow.Column;
			ItemKind = ColumnViewOfComparisonElement;
			While ItemKind <> Undefined
				And ItemKind <> Enums.FinancialReportItemKinds.Columns Do
				If ItemKind = Enums.FinancialReportItemKinds.Dimension Then
					SourceAllElements = FinancialReportingServer.ValueOfAdditionalProps(CurrentItem, "SourceAllElements", CacheOfAdditionalBankingDetails);
					If SourceAllElements = True Then
						NewRow.CalculationFilling = "filltype";
						Break;
					EndIf;
				EndIf;
				CurrentItem = ValueOfBudgetViewElementSProps(CurrentItem, "Parent", AttributeCache);
				If ValueIsFilled(CurrentItem) Then
					ItemKind = ValueOfBudgetViewElementSProps(CurrentItem, "ItemKind", AttributeCache);
				Else
					ItemKind = Undefined;
				EndIf;
			EndDo;;
		EndIf;
			
		// Formulas are not provided for operands.
		If Parameters <> Undefined Then
			
			FormationModes = Enums.ModesOfBudgetReportGeneration;
			
			AddCalculationFormula = NewRow.CalculationFilling = "recalculate" And 
				(Parameters.GenerationMode = FormationModes.Document 
					Or Parameters.GenerationMode = FormationModes.PrintBudget);
			AddCalculationFormula = AddCalculationFormula Or 
				(NewRow.CalculationFilling = "filltype" And Parameters.GenerationMode = FormationModes.FillType);
			AddCalculationFormula = AddCalculationFormula Or 
				(NewRow.CalculationFilling = "recalculate" And Parameters.GenerationMode = FormationModes.FillType);
			
			If AddCalculationFormula Then
				
				If NewRow.CalculationFilling = "filltype" Then
					NewRow.FlagBudgetFlowItem = ""; // the article is needed only for reference, selections on it are not needed
				EndIf;
				
				If Parameters.GenerationMode = FormationModes.FillType Then
					NewRow.ItemKind = Enums.FinancialReportItemKinds.DerivedItem;
				EndIf;
				
				Formula = FinancialReportingServer.ValueOfAdditionalProps(Item, "Formula", CacheOfAdditionalBankingDetails);
				If StrFind(Upper(Formula), "TOTAL(")
					Or StrFind(Upper(Formula), "DATEDIFF(") Then
					NewRow.FormulaPresentation = Formula;
				EndIf;
				NewRow.Formula = Formula;
				FillCellsOfFormulaOperands(Parameters, NewRow, DataSources, SourcesOfGroupingPeriods, Item.FormulaOperands);
				If StrFind(Upper(NewRow.Formula), "DATEDIFF(") Then
					AddTechnicalInformationToDateDifferenceFunction(NewRow.Formula);
				EndIf;
				
			EndIf;
		
		EndIf;
		
		ReadValueOfAdditionalDetailsExcludeDataOfEnteredDocumentDuringCalculation(NewRow,
			Item,
			CacheOfAdditionalBankingDetails);
		
	ElsIf TypeOfComparisonElement = Enums.FinancialReportItemKinds.AllBudgetFlowItems Then
		
		NewRow.SourceField = "Turnover";
		NewRow.CalculationFilling = "total";
		
	ElsIf TypeOfComparisonElement = Enums.FinancialReportItemKinds.BudgetBalanceItem
		Or TypeOfComparisonElement = Enums.FinancialReportItemKinds.AllBudgetBalanceItems Then
		
		IndicatorType = FinancialReportingServer.ValueOfAdditionalProps(Item, "IndicatorValueType", CacheOfAdditionalBankingDetails);
		If IndicatorType = Enums.ValueTypesOfBudgetReportIndicators.OpeningBalance Then
			NewRow.SourceField = "OpeningBalance";
		ElsIf IndicatorType = Enums.ValueTypesOfBudgetReportIndicators.ClosingBalance Then
			NewRow.SourceField = "ClosingBalance";
		ElsIf IndicatorType = Enums.ValueTypesOfBudgetReportIndicators.Receipt Then
			NewRow.SourceField = "Receipt";
		ElsIf IndicatorType = Enums.ValueTypesOfBudgetReportIndicators.Expense Then
			NewRow.SourceField = "Expense";
		ElsIf IndicatorType = Enums.ValueTypesOfBudgetReportIndicators.Turnover Then
			NewRow.SourceField = "Turnover";
		EndIf;
		
		NewRow.CalculationFilling = "total";
		
		ReadValueOfAdditionalDetailsExcludeDataOfEnteredDocumentDuringCalculation(NewRow,
			Item,
			CacheOfAdditionalBankingDetails);
		
	ElsIf TypeOfComparisonElement = Enums.FinancialReportItemKinds.NonFinancialItem Then
		
		NewRow.CalculationFilling = "total";
		NewRow.SourceField = "IndicatorValue";
		
	ElsIf TypeOfComparisonElement = Enums.FinancialReportItemKinds.EditedValue Then
		
		NewRow.CalculationFilling = "";
		NewRow.SourceField = "IndicatorValue";
		NewRow.EditedValueType = 
			FinancialReportingServer.ValueOfAdditionalProps(Item, "EditedValueType", CacheOfAdditionalBankingDetails);
		NewRow.ID_Source1 = "Document_Values";
		RequiresSource = False;
		
	EndIf;
	
	If RequiresSource Then
		
		// "All items" are included in the "budget indicator".
		If TypeOfComparisonElement = Enums.FinancialReportItemKinds.AllBudgetFlowItems Then
			
			FoundItem = Undefined;
			RootItem = Item;
			While ValueIsFilled(RootItem) Do
				If RootItem.ItemKind = Enums.FinancialReportItemKinds.BudgetBalanceItem
					Or RootItem.ItemKind = Enums.FinancialReportItemKinds.AllBudgetBalanceItems Then
					Break;
				EndIf;
				RootItem = RootItem.Parent;
			EndDo;
			If Not ValueIsFilled(RootItem) Then
				RootItem = Item;
				While ValueIsFilled(RootItem) Do
					If RootItem.ItemKind = Enums.FinancialReportItemKinds.BudgetBalanceItem
						Or RootItem.ItemKind = Enums.FinancialReportItemKinds.AllBudgetBalanceItems Then
						Break;
					EndIf;
					RootItem = RootItem.Parent;
				EndDo;
				If ValueIsFilled(RootItem) Then
					FoundItem = RootItem;
				EndIf;
			Else
				FoundItem = RootItem;
			EndIf;
			
		EndIf;
		
		SearchItem = Item;
		If FoundItem <> Undefined Then
			SearchItem = FoundItem;
		EndIf;
		
		For Each Source In DataSources Do
			If Source.ItemsList.Find(SearchItem) <> Undefined Then
				NewRow.ID_Source1 = Source.Id;
				Break;
			EndIf;
		EndDo;
		
		For Each Source In SourcesOfGroupingPeriods Do
			If Source.ItemsList.Find(SearchItem) <> Undefined Then
				NewRow.Id_OfSource = Source.Id;
				Break;
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure

Function GetDimensionName(CacheAdditionalBankingDetails, Item)
	
	ItemKind = Common.ObjectAttributeValue(Item, "ItemKind");
	If ItemKind = Enums.FinancialReportItemKinds.AllBudgetFlowItems Then
		Return "BudgetFlowItem";
	ElsIf ItemKind = Enums.FinancialReportItemKinds.AllBudgetBalanceItems Then
		Return "BudgetBalanceItem";
	ElsIf ItemKind = Enums.FinancialReportItemKinds.BudgetFlowItem Then
		Return "BudgetFlowItem";
	ElsIf ItemKind = Enums.FinancialReportItemKinds.BudgetBalanceItem Then
		Return "BudgetBalanceItem";
	ElsIf ItemKind = Enums.FinancialReportItemKinds.Dimension Then
		DimensionType = FinancialReportingServer.ValueOfAdditionalProps(Item, "DimensionType", CacheAdditionalBankingDetails);
		
		If DimensionType = Enums.TypesOfBudgetReportDimensions.Organization Then
			Return "Organization";
			
		ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.Period Then
			Periodicity = FinancialReportingServer.ValueOfAdditionalProps(Item, "Periodicity", CacheAdditionalBankingDetails);
			PeriodStrings = FinancialReportingClientServer.PeriodStrings(Periodicity);
			Return PeriodStrings.Period;
			
		ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.Department Then
			Return "Department";
			
		ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.Scenario Then
			Return "Scenario";
			
		ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.FixedDimension Then
			DimensionKind = FinancialReportingServer.ValueOfAdditionalProps(Item, "DimensionKind", CacheAdditionalBankingDetails);
			NameOfAnalytics = FinancialReportingCached.NameOfBudgetReportField(DimensionKind);
			Return NameOfAnalytics;
			
		ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.Dimension Then
			DimensionKind = FinancialReportingServer.ValueOfAdditionalProps(Item, "DimensionKind", CacheAdditionalBankingDetails);
			NameOfAnalytics = FinancialReportingCached.NameOfBudgetReportField(DimensionKind);
			Return NameOfAnalytics;
			
		ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.RegisterDimension Then
			DimensionName = FinancialReportingServer.ValueOfAdditionalProps(Item, "DimensionName", CacheAdditionalBankingDetails);
			Return DimensionName;
			
		EndIf;
	Else
		Error = NStr("vi = 'Đơn vị tính không xác định:%1';
					|ru = 'Неизвестное измерение: %1';
					|en = 'Unknown dimension: %1'; fa = 'Unknown dimension: %1';
					|it = 'Misurazione sconosciuta: %1';
					|pl = 'Nieznany pomiar: %1';
					|tr = 'Bilinmeyen ölçüm: %1'");
		Error = StringFunctionsClientServer.SubstituteParametersToString(Error, Item);
		Raise Error;
	EndIf;
	
EndFunction

Function GetFullListOfCellDimensions(CacheAdditionalBankingDetails, Val String, Val Column)
	
	Array = New Array;
	
	If ValueIsFilled(String) Then
		RowData = Common.ObjectAttributesValues(String, "ItemKind, Parent");
	Else
		RowData = Undefined;
	EndIf;
	
	While ValueIsFilled(String)
		And Not RowData.ItemKind = Enums.FinancialReportItemKinds.Rows Do
		
		If RowData.ItemKind = Enums.FinancialReportItemKinds.Dimension
			Or RowData.ItemKind = Enums.FinancialReportItemKinds.AllBudgetFlowItems
			Or RowData.ItemKind = Enums.FinancialReportItemKinds.AllBudgetBalanceItems Then
			
			AddDimension_ = True;
			DimensionType = FinancialReportingServer.ValueOfAdditionalProps(String, "DimensionType", CacheAdditionalBankingDetails);
			If DimensionType = Enums.TypesOfBudgetReportDimensions.FixedDimension Then
				EnableEdit = FinancialReportingServer.ValueOfAdditionalProps(String, "EnableEdit", CacheAdditionalBankingDetails);
				If Not EnableEdit = True Then
					// Fixed analytics is uniquely determined by the row and column of the cell
					AddDimension_ = False;
				EndIf;
			EndIf;
			If DimensionType = Enums.TypesOfBudgetReportDimensions.Organization Then
				DimensionValue = FinancialReportingServer.ValueOfAdditionalProps(Column, "Organization", CacheAdditionalBankingDetails);
				If ValueIsFilled(DimensionValue) Then
					AddDimension_ = False;
				EndIf;
			ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.Currency Then
				DimensionValue = FinancialReportingServer.ValueOfAdditionalProps(Column, "Currency", CacheAdditionalBankingDetails);
				If ValueIsFilled(DimensionValue) Then
					AddDimension_ = False;
				EndIf;
			ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.Scenario Then
				DimensionValue = FinancialReportingServer.ValueOfAdditionalProps(Column, "Scenario", CacheAdditionalBankingDetails);
				If ValueIsFilled(DimensionValue) Then
					AddDimension_ = False;
				EndIf;
			EndIf;
			If DimensionType = Enums.TypesOfBudgetReportDimensions.Period Then
				PeriodExpression = FinancialReportingServer.ValueOfAdditionalProps(String, "PeriodValue", CacheAdditionalBankingDetails);
				If PeriodExpression <> Undefined Then
					AddDimension_ = False;
				EndIf;
			EndIf;
			
			If AddDimension_ Then
				DimensionName = GetDimensionName(CacheAdditionalBankingDetails, String);
				Array.Add(DimensionName);
			EndIf;
			
		EndIf;
		
		String = RowData.Parent;
		If ValueIsFilled(String) Then
			RowData = Common.ObjectAttributesValues(String, "ItemKind, Parent");
		Else
			RowData = Undefined;
		EndIf;
		
	EndDo;
	
	If ValueIsFilled(Column) Then
		ColumnData = Common.ObjectAttributesValues(Column, "ItemKind, Parent");
	Else
		ColumnData = Undefined;
	EndIf;
	
	While ValueIsFilled(Column)
		And Not ColumnData.ItemKind = Enums.FinancialReportItemKinds.Columns Do
		
		If ColumnData.ItemKind = Enums.FinancialReportItemKinds.Dimension
			Or ColumnData.ItemKind = Enums.FinancialReportItemKinds.AllBudgetFlowItems
			Or ColumnData.ItemKind = Enums.FinancialReportItemKinds.AllBudgetBalanceItems Then
			
			AddDimension_ = True;
			DimensionType = FinancialReportingServer.ValueOfAdditionalProps(Column, "DimensionType", CacheAdditionalBankingDetails);
			If DimensionType = Enums.TypesOfBudgetReportDimensions.FixedDimension Then
				EnableEdit = FinancialReportingServer.ValueOfAdditionalProps(Column, "EnableEdit", CacheAdditionalBankingDetails);
				If Not EnableEdit = True Then
					// Fixed analytics is uniquely determined by the row and column of the cell
					AddDimension_ = False;
				EndIf;
			EndIf;
			If DimensionType = Enums.TypesOfBudgetReportDimensions.Organization Then
				DimensionValue = FinancialReportingServer.ValueOfAdditionalProps(Column, "Organization", CacheAdditionalBankingDetails);
				If ValueIsFilled(DimensionValue) Then
					AddDimension_ = False;
				EndIf;
			ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.Currency Then
				DimensionValue = FinancialReportingServer.ValueOfAdditionalProps(Column, "Currency", CacheAdditionalBankingDetails);
				If ValueIsFilled(DimensionValue) Then
					AddDimension_ = False;
				EndIf;
			ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.Scenario Then
				DimensionValue = FinancialReportingServer.ValueOfAdditionalProps(Column, "Scenario", CacheAdditionalBankingDetails);
				If ValueIsFilled(DimensionValue) Then
					AddDimension_ = False;
				EndIf;
			EndIf;
			If DimensionType = Enums.TypesOfBudgetReportDimensions.Period Then
				PeriodExpression = FinancialReportingServer.ValueOfAdditionalProps(Column, "PeriodValue", CacheAdditionalBankingDetails);
				If PeriodExpression <> Undefined Then
					AddDimension_ = False;
				EndIf;
			EndIf;
			
			If AddDimension_ Then
				DimensionName = GetDimensionName(CacheAdditionalBankingDetails, Column);
				Array.Add(DimensionName);
			EndIf;
			
		EndIf;
		
		Column = ColumnData.Parent;
		If ValueIsFilled(Column) Then
			ColumnData = Common.ObjectAttributesValues(Column, "ItemKind, Parent");
		Else
			ColumnData = Undefined;
		EndIf;
		
	EndDo;
	
	Return Array;
	
EndFunction

Function GetFullListOfOperandDimensions(CacheAdditionalBankingDetails, Val OperandAnalysis, Val String, Val Column)
	
	Array = New Array;
	
	If ValueIsFilled(String) Then
		RowData = Common.ObjectAttributesValues(String, "ItemKind, Parent");
	Else
		RowData = Undefined;
	EndIf;
	
	While ValueIsFilled(String)
		And Not RowData.ItemKind = Enums.FinancialReportItemKinds.Rows Do
		
		If RowData.ItemKind = Enums.FinancialReportItemKinds.Dimension
			Or RowData.ItemKind = Enums.FinancialReportItemKinds.AllBudgetFlowItems
			Or RowData.ItemKind = Enums.FinancialReportItemKinds.AllBudgetBalanceItems Then
			
			AddDimension_ = True;
			DimensionType = FinancialReportingServer.ValueOfAdditionalProps(String, "DimensionType", CacheAdditionalBankingDetails);
			If DimensionType = Enums.TypesOfBudgetReportDimensions.FixedDimension Then
				EnableEdit = FinancialReportingServer.ValueOfAdditionalProps(String, "EnableEdit", CacheAdditionalBankingDetails);
				If Not EnableEdit = True Then
					// Fixed analytics is uniquely determined by the row and column of the cell
					AddDimension_ = False;
				Else
					DimensionKind = FinancialReportingServer.ValueOfAdditionalProps(String, "DimensionKind", CacheAdditionalBankingDetails);
					If OperandAnalysis.Find(DimensionKind) = Undefined Then
						AddDimension_ = False;
					EndIf;
				EndIf;
			ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.Dimension Then
				DimensionKind = FinancialReportingServer.ValueOfAdditionalProps(String, "DimensionKind", CacheAdditionalBankingDetails);
				If OperandAnalysis.Find(DimensionKind) = Undefined Then
					AddDimension_ = False;
				EndIf;
			EndIf;
			If DimensionType = Enums.TypesOfBudgetReportDimensions.Organization Then
				DimensionValue = FinancialReportingServer.ValueOfAdditionalProps(Column, "Organization", CacheAdditionalBankingDetails);
				If ValueIsFilled(DimensionValue) Then
					AddDimension_ = False;
				EndIf;
			ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.Currency Then
				DimensionValue = FinancialReportingServer.ValueOfAdditionalProps(Column, "Currency", CacheAdditionalBankingDetails);
				If ValueIsFilled(DimensionValue) Then
					AddDimension_ = False;
				EndIf;
			ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.Scenario Then
				DimensionValue = FinancialReportingServer.ValueOfAdditionalProps(Column, "Scenario", CacheAdditionalBankingDetails);
				If ValueIsFilled(DimensionValue) Then
					AddDimension_ = False;
				EndIf;
			EndIf;
			If DimensionType = Enums.TypesOfBudgetReportDimensions.Period Then
				PeriodExpression = FinancialReportingServer.ValueOfAdditionalProps(String, "PeriodValue", CacheAdditionalBankingDetails);
				If PeriodExpression <> Undefined Then
					AddDimension_ = False;
				EndIf;
			EndIf;
			
			If AddDimension_ Then
				DimensionName = GetDimensionName(CacheAdditionalBankingDetails, String);
				Array.Add(DimensionName);
			EndIf;
			
		EndIf;
		
		String = RowData.Parent;
		If ValueIsFilled(String) Then
			RowData = Common.ObjectAttributesValues(String, "ItemKind, Parent");
		Else
			RowData = Undefined;
		EndIf;
		
	EndDo;
	
	If ValueIsFilled(Column) Then
		ColumnData = Common.ObjectAttributesValues(Column, "ItemKind, Parent");
	Else
		ColumnData = Undefined;
	EndIf;
	
	While ValueIsFilled(Column)
		And Not ColumnData.ItemKind = Enums.FinancialReportItemKinds.Columns Do
		
		If ColumnData.ItemKind = Enums.FinancialReportItemKinds.Dimension
			Or ColumnData.ItemKind = Enums.FinancialReportItemKinds.AllBudgetFlowItems
			Or ColumnData.ItemKind = Enums.FinancialReportItemKinds.AllBudgetBalanceItems Then
			
			AddDimension_ = True;
			DimensionType = FinancialReportingServer.ValueOfAdditionalProps(Column, "DimensionType", CacheAdditionalBankingDetails);
			If DimensionType = Enums.TypesOfBudgetReportDimensions.FixedDimension Then
				EnableEdit = FinancialReportingServer.ValueOfAdditionalProps(Column, "EnableEdit", CacheAdditionalBankingDetails);
				If Not EnableEdit = True Then
					// Fixed analytics is uniquely determined by the row and column of the cell
					AddDimension_ = False;
				Else
					DimensionKind = FinancialReportingServer.ValueOfAdditionalProps(Column, "DimensionKind", CacheAdditionalBankingDetails);
					If OperandAnalysis.Find(DimensionKind) = Undefined Then
						AddDimension_ = False;
					EndIf;
				EndIf;
			EndIf;
			If DimensionType = Enums.TypesOfBudgetReportDimensions.Organization Then
				DimensionValue = FinancialReportingServer.ValueOfAdditionalProps(Column, "Organization", CacheAdditionalBankingDetails);
				If ValueIsFilled(DimensionValue) Then
					AddDimension_ = False;
				EndIf;
			ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.Currency Then
				DimensionValue = FinancialReportingServer.ValueOfAdditionalProps(Column, "Currency", CacheAdditionalBankingDetails);
				If ValueIsFilled(DimensionValue) Then
					AddDimension_ = False;
				EndIf;
			ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.Scenario Then
				DimensionValue = FinancialReportingServer.ValueOfAdditionalProps(Column, "Scenario", CacheAdditionalBankingDetails);
				If ValueIsFilled(DimensionValue) Then
					AddDimension_ = False;
				EndIf;
			EndIf;
			If DimensionType = Enums.TypesOfBudgetReportDimensions.Period Then
				PeriodExpression = FinancialReportingServer.ValueOfAdditionalProps(Column, "PeriodValue", CacheAdditionalBankingDetails);
				If PeriodExpression <> Undefined Then
					AddDimension_ = False;
				EndIf;
			EndIf;
			
			If AddDimension_ Then
				DimensionName = GetDimensionName(CacheAdditionalBankingDetails, Column);
				Array.Add(DimensionName);
			EndIf;
			
		EndIf;
		
		Column = ColumnData.Parent;
		If ValueIsFilled(Column) Then
			ColumnData = Common.ObjectAttributesValues(Column, "ItemKind, Parent");
		Else
			ColumnData = Undefined;
		EndIf;
		
	EndDo;
	
	Return Array;
	
EndFunction

Function RelatedRecalculatedRows(CellStructure, Cell, ReferenceCells = Undefined)
	
	TheStructureOfTheSearch = New Structure("OperandString, OperandColumn_", Cell.String, Cell.Column);
	CellsWithLinks = CellStructure.FindRows(TheStructureOfTheSearch);
	
	If ReferenceCells = Undefined Then
		ReferenceCells = New ValueTable;
		ReferenceCells.Columns.Add("String");
		ReferenceCells.Columns.Add("Column");
		ReferenceCells.Columns.Add("GeneralMeasurements");
		ReferenceCells.Columns.Add("OperandAnalysis_");
		ReferenceCells.Indexes.Add("String, Column");
	EndIf;
	
	For Each CellWithLink In CellsWithLinks Do
		SearchLinks = New Structure("String, Column");
		FillPropertyValues(SearchLinks, CellWithLink);
		If ReferenceCells.FindRows(SearchLinks).Count() Then
			Continue;
		EndIf;
		SearchLinks.Insert("MainItem", True);
		SearchLinks.Insert("CalculationFilling", "recalculate");
		FoundRow = CellStructure.FindRows(SearchLinks);
		If Not FoundRow.Count() Then
			Continue;
		EndIf;
		NewCell = ReferenceCells.Add();
		FillPropertyValues(NewCell, FoundRow[0]);
		NewCell.GeneralMeasurements = CellWithLink.GeneralMeasurements;
		NewCell.OperandAnalysis_ = CellWithLink.OperandAnalysis_;
		RelatedRecalculatedRows(CellStructure, NewCell, ReferenceCells);
	EndDo;
	
	Return ReferenceCells;
	
EndFunction

// The constructor function of the structure of cells
// 
// Parameters:
// 	DescriptionOfReport - Structure -
// 	ArrayOfMainColumns - Undefined - LongDesc
// 	ArrayOfColumnsInSourceTable - Undefined - LongDesc
// Returns:
// 	ValueTable - LongDesc:
// * MainItem - Boolean - 
// * String - CatalogRef.FinancialReportItems -
// * Column - CatalogRef.FinancialReportItems -
// * CalculationFilling - String -
// * TableComplex_ - Boolean -
// * ItemKind - EnumRef.FinancialReportItemKinds -
// * ReverseSign - Boolean - 
// * BudgetFlowItem - CatalogRef.BudgetFlowItems, CatalogRef.BudgetBalanceItems -
// * NonFinancialItem - CatalogRef.NonFinancialItemsOfBudgets -
// * BudgetBalanceItem - CatalogRef.BudgetBalanceItems -
// * EditedValue - String -
// * FlagBudgetFlowItem - String -
// * FlagBudgetBalanceItem - String -
// * FlagNonFinancialItem - String -
// * FlagEditedValue - String -
// * FlagCount - Boolean -
// * FlagSum - Boolean -
// * FlagValue - Boolean -
// * Formula - String -
// * FormulaPresentation - String -
// * ID_Source1 - String -
// * Id_OfSource - String -
// * SourceField - String -
// * ExcludeEnteredDocumentDataDuringCalculation - Boolean -
// * OperandName - String -
// * OperandType - EnumRef.FinancialReportItemKinds -
// * OperandString - CatalogRef.FinancialReportItems -
// * OperandColumn_ - CatalogRef.FinancialReportItems -
// * GeneralMeasurements - String -
// * ListOfOperands - String -
// * EditedValueType - String -
// * OperandCalculationProcedure - Number -
// * RowIndex - Number -
// * RelatedCells - Arbitrary -
// * OperandAnalysis_ - Arbitrary -
Function NewCellStructure(DescriptionOfReport, ArrayOfMainColumns = Undefined, ArrayOfColumnsInSourceTable = Undefined)
	
	If ArrayOfMainColumns = Undefined Then
		ArrayOfMainColumns = New Array;
	EndIf;
	If ArrayOfColumnsInSourceTable = Undefined Then
		ArrayOfColumnsInSourceTable = New Array;
	EndIf;
	
	CellStructure = New ValueTable;
	
	CellStructure.Columns.Add("MainItem", 		ColumnTypeOfCellStructure("MainItem"));
	CellStructure.Columns.Add("String", 				ColumnTypeOfCellStructure("String"));
	CellStructure.Columns.Add("Column", 				ColumnTypeOfCellStructure("Column"));
	ArrayOfMainColumns.Add("MainItem");
	ArrayOfMainColumns.Add("String");
	ArrayOfMainColumns.Add("Column");
	
	CellStructure.Columns.Add("CalculationFilling", 	ColumnTypeOfCellStructure("Flag"));
	CellStructure.Columns.Add("TableComplex_", 		ColumnTypeOfCellStructure("UsageFlag_"));
	
	CellStructure.Columns.Add("ItemKind", 			ColumnTypeOfCellStructure("ItemKind"));
	CellStructure.Columns.Add("ReverseSign", 		ColumnTypeOfCellStructure("ReverseSign"));
	ArrayOfMainColumns.Add("ItemKind");
	
	CellStructure.Columns.Add("BudgetFlowItem", 			ColumnTypeOfCellStructure("BudgetFlowItem"));
	CellStructure.Columns.Add("NonFinancialItem", 	ColumnTypeOfCellStructure("NonFinancialItem"));
	CellStructure.Columns.Add("BudgetBalanceItem", 		ColumnTypeOfCellStructure("BudgetBalanceItem"));
	CellStructure.Columns.Add("EditedValue", 	ColumnTypeOfCellStructure("EditedValue"));
	ArrayOfMainColumns.Add("BudgetFlowItem");
	ArrayOfMainColumns.Add("NonFinancialItem");
	ArrayOfMainColumns.Add("BudgetBalanceItem");
	ArrayOfMainColumns.Add("EditedValue");
	
	CellStructure.Columns.Add("FlagBudgetFlowItem", 			ColumnTypeOfCellStructure("Flag"));
	CellStructure.Columns.Add("FlagBudgetBalanceItem", 		ColumnTypeOfCellStructure("Flag"));
	CellStructure.Columns.Add("FlagNonFinancialItem", 	ColumnTypeOfCellStructure("Flag"));
	ArrayOfMainColumns.Add("FlagBudgetFlowItem");
	ArrayOfMainColumns.Add("FlagBudgetBalanceItem");
	ArrayOfMainColumns.Add("FlagNonFinancialItem");
	CellStructure.Columns.Add("FlagEditedValue", ColumnTypeOfCellStructure("Flag"));
	ArrayOfMainColumns.Add("FlagEditedValue");
	
	For Each Dimension In DescriptionOfReport.Periodicity_ Do
		LinesOfPerid = FinancialReportingClientServer.PeriodStrings(Dimension);
		PeriodName = FinancialReportingClientServerCached.PeriodicityByString(Dimension);
		CellStructure.Columns.Add(LinesOfPerid.Period, ColumnTypeOfCellStructure("Period"), PeriodName);
		CellStructure.Columns.Add(LinesOfPerid.FlagPeriod, ColumnTypeOfCellStructure("Flag"));
		CellStructure.Columns.Add(LinesOfPerid.PeriodExpression, ColumnTypeOfCellStructure("Count"));
		ArrayOfMainColumns.Add(LinesOfPerid.PeriodExpression);
		ArrayOfMainColumns.Add(LinesOfPerid.Period);
		ArrayOfMainColumns.Add(LinesOfPerid.FlagPeriod);
	EndDo;
	
	For Each Dimension In DescriptionOfReport.Dimensions Do
		CellStructure.Columns.Add(Dimension, ColumnTypeOfCellStructure(Dimension), Dimension);
		CellStructure.Columns.Add("Flag" + Dimension, ColumnTypeOfCellStructure("Flag"));
		CellStructure.Columns.Add("Source" + Dimension);
		ArrayOfMainColumns.Add(Dimension);
		ArrayOfMainColumns.Add("Flag" + Dimension);
		ArrayOfColumnsInSourceTable.Add("Source" + Dimension);
	EndDo;
	
	For Each Dimension In DescriptionOfReport.DimensionKinds Do
		DimensionName = FinancialReportingCached.NameOfBudgetReportField(Dimension);
		DimensionType = BudgetingServer.AllTypesOfAnalytics();
		CellStructure.Columns.Add(DimensionName, DimensionType, String(Dimension));
		CellStructure.Columns.Add("Flag" + DimensionName, ColumnTypeOfCellStructure("Flag"));
		CellStructure.Columns.Add("Source" + DimensionName);
		CellStructure.Columns.Add("Parent" + DimensionName, ColumnTypeOfCellStructure("String"));
		ArrayOfMainColumns.Add(DimensionName);
		ArrayOfMainColumns.Add("Flag" + DimensionName);
		ArrayOfMainColumns.Add("Parent" + DimensionName);
		ArrayOfColumnsInSourceTable.Add("Source" + DimensionName);
	EndDo;
	
	CellStructure.Columns.Add("FlagCount", 	ColumnTypeOfCellStructure("UsageFlag_"));
	CellStructure.Columns.Add("FlagSum", 		ColumnTypeOfCellStructure("UsageFlag_"));
	CellStructure.Columns.Add("FlagValue", 	ColumnTypeOfCellStructure("UsageFlag_"));
	
	CellStructure.Columns.Add("Formula", 			ColumnTypeOfCellStructure("Formula"));
	CellStructure.Columns.Add("FormulaPresentation", ColumnTypeOfCellStructure("Formula"));
	
	CellStructure.Columns.Add("ID_Source1", 		ColumnTypeOfCellStructure("ID_Source1"));
	CellStructure.Columns.Add("Id_OfSource", ColumnTypeOfCellStructure("ID_Source1"));
	CellStructure.Columns.Add("SourceField", 		ColumnTypeOfCellStructure("SourceField"));
	ArrayOfMainColumns.Add("ID_Source1");
	ArrayOfMainColumns.Add("Id_OfSource");
	
	ColumnType = ColumnTypeOfCellStructure("ExcludeEnteredDocumentDataDuringCalculation");
	CellStructure.Columns.Add("ExcludeEnteredDocumentDataDuringCalculation", ColumnType);
	ArrayOfMainColumns.Add("ExcludeEnteredDocumentDataDuringCalculation");
	
	CellStructure.Columns.Add("OperandName", 		ColumnTypeOfCellStructure("OperandName"));
	CellStructure.Columns.Add("OperandType", 		ColumnTypeOfCellStructure("OperandType"));
	CellStructure.Columns.Add("OperandString", 	ColumnTypeOfCellStructure("OperandString"));
	CellStructure.Columns.Add("OperandColumn_", 	ColumnTypeOfCellStructure("OperandColumn_"));
	CellStructure.Columns.Add("GeneralMeasurements", 	ColumnTypeOfCellStructure("GeneralMeasurements"));
	CellStructure.Columns.Add("ListOfOperands", 	ColumnTypeOfCellStructure("ListOfOperands"));
	CellStructure.Columns.Add("EditedValueType", ColumnTypeOfCellStructure("EditedValueType"));
	ArrayOfMainColumns.Add("OperandType");
	
	// for ordering operands of formulas like "execution", "rejection"
	CellStructure.Columns.Add("OperandCalculationProcedure", 	ColumnTypeOfCellStructure("Count"));
	CellStructure.Columns.Add("RowIndex", 			ColumnTypeOfCellStructure("Count"));
	ArrayOfMainColumns.Add("OperandCalculationProcedure");
	ArrayOfMainColumns.Add("RowIndex");
	
	// table of cell values to be recalculated
	CellStructure.Columns.Add("RelatedCells");
	
	CellStructure.Columns.Add("OperandAnalysis_");
	
	Return CellStructure;
	
EndFunction

// LongDesc
// 
// Parameters:
// 	BudgetProfile - CatalogRef.BudgetProfiles - LongDesc
// 	DataSources - Array of Structure - LongDesc
// 	SourcesOfGroupingPeriods - Array - LongDesc
// 	DescriptionOfReport - Arbitrary, Structure, Undefined, Boolean - LongDesc:
// * DimensionKinds - Array -
// * Dimensions - Array -
// * Periodicity_ - Array -
// 	GenerationMode - EnumRef.ModesOfBudgetReportGeneration - LongDesc
// Returns:
// 	Structure - LongDesc:
// * CellStructure - ValueTable -
// * CellParameters - ValueTable - 
// * FillingInMissingNFPMeasurements - ValueTable -
// * SourcesOfMeasurementValues - ValueTable -
// * SelectionOfNFPMeasurements - ValueTable -
//
Function DescriptionOfCells(BudgetProfile, DataSources, SourcesOfGroupingPeriods, DescriptionOfReport, GenerationMode)
	
	ItemsTree = BudgetItemTree(BudgetProfile, False);
	
#Region Preparing_table

	ArrayOfMainColumns = New Array;
	ArrayOfColumnsInSourceTable = New Array;

	CellStructure = NewCellStructure(DescriptionOfReport, ArrayOfMainColumns, ArrayOfColumnsInSourceTable);
	
	// Matching the column ID (for the type of analytics, this is the analytics ID, not the column name).
	// It is used in the comparison of table columns and parts of expressions used in formulas (for example, the "Total" function).
	ColumnNamesForFormulas = New Map;
	ColumnNamesOverride = New Array;
	For Each DimensionKind In DescriptionOfReport.DimensionKinds Do
		ColumnNameOfCellStructure = FinancialReportingCached.NameOfBudgetReportField(DimensionKind);
		IDOfAnalyticsType = Common.ObjectAttributeValue(DimensionKind, "Id");
		ColumnNamesOverride.Add(ColumnNameOfCellStructure);
		ColumnNamesForFormulas.Insert(Upper(IDOfAnalyticsType), ColumnNameOfCellStructure);
	EndDo;
	For Each Periodicity In DescriptionOfReport.Periodicity_ Do
		PeriodName = FinancialReportingClientServerCached.PeriodicityByString(Periodicity);
		PeriodStrings = FinancialReportingClientServer.PeriodStrings(Periodicity);
		ColumnName = PeriodStrings.Period;
		ColumnNamesOverride.Add(ColumnName);
		ColumnNamesForFormulas.Insert(Upper(PeriodName), ColumnName);
	EndDo;
	For Each TableColumn2 In CellStructure.Columns Do
		If Not ColumnNamesOverride.Find(TableColumn2.Name) = Undefined Then
			Continue;
		EndIf;
		ColumnNamesForFormulas.Insert(Upper(TableColumn2.Name), TableColumn2.Name);
	EndDo;
	ColumnNamesOverride = Undefined;
	
#EndRegion
	
#Region FillingIn_table
	
	If GenerationMode = Enums.ModesOfBudgetReportGeneration.FillType Then
		DisplayHiddenTreeColumns = False;
	Else
		DisplayHiddenTreeColumns = True;
	EndIf;

	Items = GetFinalElements(ItemsTree, Catalogs.FinancialReportItems.EmptyRef(), DisplayHiddenTreeColumns);
	
	CacheAdditionalDetails = FinancialReportingServer.CacheAdditionalDetails(BudgetProfile);
	
	Parameters = New Structure;
	Parameters.Insert("GenerationMode",					GenerationMode);
	Parameters.Insert("CellStructure",					CellStructure);
	Parameters.Insert("SettingsTable",					ElementsForConfiguringBudgetViewCells(BudgetProfile));
	Parameters.Insert("ValueSources",					SourcesOfBudgetTypeValues(BudgetProfile));
	Parameters.Insert("DataSources",					DataSources);
	Parameters.Insert("SourcesOfGroupingPeriods",		SourcesOfGroupingPeriods);
	Parameters.Insert("CacheOfAdditionalBankingDetails",					CacheAdditionalDetails);
	Parameters.Insert("DescriptionOfReport",					DescriptionOfReport);
	Parameters.Insert("StringTree",						Items.Rows);
	Parameters.Insert("Parent",							Undefined);
	Parameters.Insert("TableComplex_",					False);
	Parameters.Insert("AttributeCache",						CacheOfDetailsForBudgetViewElements(BudgetProfile));
	Parameters.Insert("CacheAnalystArticles",					New Map);
	Parameters.Insert("CacheOfCurrencyItemDetails",			New Map);
	Parameters.Insert("CacheOfArticleDetailsEd",			New Map);
	Parameters.Insert("CacheOfSubordinateFormulaElements",		New Map);
	Parameters.Insert("ColumnNamesForFormulas", 			ColumnNamesForFormulas);
	Parameters.Insert("CacheOfSubordinatesOutputWithParent", GetCacheOfChildElementsOutputWithParent(BudgetProfile));
	Parameters.Insert("CacheDataSourcesOfReportElements", New Map);
	
	FillInCellStructure(Parameters, Items.Columns);
	
	Tables = GetBudgetViewTables(BudgetProfile);
	For Each Table In Tables Do
		Items = GetFinalElements(ItemsTree, Table.Ref, DisplayHiddenTreeColumns);
		Parameters.Insert("StringTree", Items.Rows);
		Parameters.Insert("Columns", Items.Columns);
		Parameters.Insert("Parent", Table.Ref);
		Parameters.Insert("TableComplex_", Table.ItemKind = Enums.FinancialReportItemKinds.ComplexTable);
		FillInCellStructure(Parameters, Items.Columns);
	EndDo;
	
	FillInSumQuantityAttributesOfFormula(BudgetProfile, CellStructure);
	
#EndRegion
	
#Region CalculationOf_fields_By_which_WillBe_research_data_with_report_report

	CellStructure.Indexes.Add("MainItem, String, Column");
	
	For Each Cell In CellStructure Do
		
		If Cell.OperandType = Enums.FinancialReportItemKinds.TableCell Then
			
			Array1 = GetFullListOfCellDimensions(CacheAdditionalDetails,
														Cell.OperandString, Cell.OperandColumn_);
			Array2 = GetFullListOfCellDimensions(CacheAdditionalDetails,
														Cell.String, Cell.Column);
			
			Result = "";
			For Each Item In Array1 Do
				If Array2.Find(Item) <> Undefined Then
					Result = Result + ?(IsBlankString(Result), "", ",") + Item;
				EndIf;
			EndDo;
			
			Cell.GeneralMeasurements = Result;
			
		ElsIf (Cell.ItemKind = Enums.FinancialReportItemKinds.DerivedItem
				Or Cell.ItemKind = Enums.FinancialReportItemKinds.GroupFormula
				Or Cell.ItemKind = Enums.FinancialReportItemKinds.Group)
				And Cell.MainItem Then
				
			SharedCells = GetFullListOfCellDimensions(CacheAdditionalDetails, 
																Cell.String, Cell.Column);
			Result = "";
			For Each Item In SharedCells Do
				Result = Result + ?(IsBlankString(Result), "", ",") + Item;
			EndDo;
			Cell.GeneralMeasurements = Result;
			
			If Not Cell.OperandAnalysis_ = Undefined Then
				For Each OperandNameAndAnalyst In Cell.OperandAnalysis_ Do
					OperandName = OperandNameAndAnalyst.Key;
					SharedCells = GetFullListOfOperandDimensions(CacheAdditionalDetails,
						OperandNameAndAnalyst.Value,
						Cell.String,
						Cell.Column);
					
					Result = "";
					For Each Item In SharedCells Do
						Result = Result + ?(IsBlankString(Result), "", ",") + Item;
					EndDo;
					
					Cell.OperandAnalysis_.Insert(OperandName, Result);
				EndDo;
			EndIf;
			
		EndIf;
		
	EndDo;

#EndRegion
	
	IndexCalculationFilling = CellStructure.Indexes.Add("String, Column, MainItem, CalculationFilling");
	IndexOfOperands = CellStructure.Indexes.Add("OperandString, OperandColumn_");
	
	For Each Cell In CellStructure Do
		If Cell.MainItem Then
			Cell.RelatedCells = RelatedRecalculatedRows(CellStructure, Cell);
		EndIf;
		Cell.RowIndex = CellStructure.IndexOf(Cell);
	EndDo;
	
	CellStructure.Indexes.Delete(IndexCalculationFilling);
	CellStructure.Indexes.Delete(IndexOfOperands);
	
	ColumnsOfSourceTable = StrConcat(ArrayOfColumnsInSourceTable, ",");
	ColumnsOfSourceTable = "String, Column" + ?(ValueIsFilled(ColumnsOfSourceTable), ", ", "") + ColumnsOfSourceTable;
	TableOfSources = CellStructure.Copy(New Structure("MainItem", True), ColumnsOfSourceTable);
	
	TableOfSourceNames = CellStructure.CopyColumns("String, Column");
	
	TableOfSourceNames.Columns.Add("Dimension", ColumnTypeOfCellStructure("OperandName"));
	
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.BudgetFlowItems"));
	TypesArray.Add(Type("CatalogRef.BudgetBalanceItems"));
	
	TableOfSourceNames.Columns.Add("BudgetFlowItem", New TypeDescription(TypesArray));
	TableOfSourceNames.Columns.Add("BudgetBalanceItem", New TypeDescription("CatalogRef.BudgetBalanceItems"));
	TableOfSourceNames.Columns.Add("NonFinancialItem", New TypeDescription("CatalogRef.NonFinancialItemsOfBudgets"));
	TableOfSourceNames.Columns.Add("EditedValue", ColumnTypeOfCellStructure("EditedValue"));
	TableOfSourceNames.Columns.Add("ID_Source1", ColumnTypeOfCellStructure("ID_Source1"));
	TableOfSourceNames.Columns.Add("SourceKind", New TypeDescription("EnumRef.FinancialReportItemKinds"));
	TableOfSourceNames.Columns.Add("BudgetBalanceItemType", New TypeDescription("EnumRef.BudgetBalanceItemType"));
	
	ArrayOfMeasurementColumns = New Array;
	For Each Dimension In DescriptionOfReport.Dimensions Do
		ArrayOfMeasurementColumns.Add(Dimension);
	EndDo;
	
	For Each Dimension In DescriptionOfReport.DimensionKinds Do
		DimensionName = FinancialReportingCached.NameOfBudgetReportField(Dimension);
		ArrayOfMeasurementColumns.Add(DimensionName);
	EndDo;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	BudgetBalanceItems.Ref,
		|	BudgetBalanceItems.IndicatorType
		|FROM
		|	Catalog.BudgetBalanceItems AS BudgetBalanceItems";
	
	QueryResult = Query.Execute();
	CacheOfIndicatorDetails_ = QueryResult.Unload();
	CacheOfIndicatorDetails_.Indexes.Add("Ref");
	
	FillInSourceNameTable(ArrayOfMeasurementColumns, TableOfSourceNames, TableOfSources, CacheOfIndicatorDetails_);
	TableOfSourceNames.Indexes.Add("ID_Source1");
	TableOfSourceNames.Indexes.Add("ID_Source1, Dimension");
	TableOfSourceNames.Indexes.Add("NonFinancialItem, Dimension");
	
	TablesOfNFPSources = FillInTableOfNFPMeasurementSources(CellStructure, ArrayOfMeasurementColumns, DataSources, BudgetProfile);
	
	RemainingColumns = New Array;
	RemainingColumns.Add("RowIndex");
	
	For Each Column In CellStructure.Columns Do
		If ArrayOfMainColumns.Find(Column.Name) = Undefined
			And ArrayOfColumnsInSourceTable.Find(Column.Name) = Undefined Then
			RemainingColumns.Add(Column.Name);
		EndIf;
	EndDo;
	
	ArrayOfMainColumns.Add("CalculationFilling");
	
	MinimumCellStructure = CellStructure.Copy(,StrConcat(ArrayOfMainColumns, ","));
	CellParameters = CellStructure.Copy(,StrConcat(RemainingColumns, ","));
	CellParameters.Indexes.Add("RowIndex");
	CellStructure = MinimumCellStructure;
	
	CellStructure.Indexes.Add("RowIndex");
	CellStructure.Indexes.Add("MainItem, String");
	CellStructure.Indexes.Add("MainItem, String, Column");
	CellStructure.Indexes.Add("String, Column, MainItem"); 
	
	Result = New Structure();
	Result.Insert("CellStructure", CellStructure);
	Result.Insert("CellParameters", CellParameters);
	Result.Insert("SourcesOfMeasurementValues", TableOfSourceNames); 
	Result.Insert("FillingInMissingNFPMeasurements", TablesOfNFPSources.NFPMeasurementFillTable);
	Result.Insert("SelectionOfNFPMeasurements", TablesOfNFPSources.NFPMeasurementSelectionTable);

	Return Result;
	
EndFunction

#EndRegion

#Region GeneratingDCSForDataAcquisition

Function DataSetField(Set, Field, DataPath = "", Title = "", DataType = Undefined)
	SetField =  Set.Fields.Find(Field);
	If SetField = Undefined Then
		SetField = FinancialReportingServer.NewSetField(Set, Field, DataPath, Title, DataType);
	EndIf;
	Return SetField;
EndFunction

Procedure AddDataTableFieldsByDescription(Set, LongDesc, ResourceFields)
	
	DataSetField(Set, "ID_Source1", , ,New TypeDescription("String",, New StringQualifiers(30)));
	DataSetField(Set, "BudgetFlowItem", , ,ColumnTypeOfCellStructure("BudgetFlowItem"));
	DataSetField(Set, "BudgetBalanceItem", , ,ColumnTypeOfCellStructure("BudgetBalanceItem"));
	DataSetField(Set, "NonFinancialItem", , ,ColumnTypeOfCellStructure("NonFinancialItem"));
	DataSetField(Set, "DocumentData", , ,New TypeDescription("Boolean"));
	
	If LongDesc.Periodicity_.Count() Then
		DataSetField(Set, "Period", , , New TypeDescription("Date"));
	EndIf;
	
	For Each Dimension In LongDesc.Dimensions Do
		DataSetField(Set, Dimension, , ,ColumnTypeOfCellStructure(Dimension));
	EndDo;
	
	AllTypesOfAnalytics = BudgetingServer.AllTypesOfAnalytics();
	
	For Each Var_659_Dimension In LongDesc.DimensionKinds Do
		FieldName = FinancialReportingCached.NameOfBudgetReportField(Var_659_Dimension);
		AnalyticsHeader = String(Var_659_Dimension);
		DataSetField(Set, FieldName, FieldName, AnalyticsHeader, AllTypesOfAnalytics);
	EndDo;
	
	For Each KeyAndValue In ResourceFields Do
		
		If KeyAndValue.Key = "Note" Then
			DataSetField(Set, KeyAndValue.Key, KeyAndValue.Key, , ColumnTypeOfCellStructure("Note"));
		ElsIf KeyAndValue.Key = "IndicatorValue" Then
			TypesArray = New Array;
			TypesArray.Add(Type("Number"));
			TypesArray.Add(Type("String"));
			TypesArray.Add(Type("Boolean"));
			TypesArray.Add(Type("Date"));
			TypesArray.Add(Type("CatalogRef.VATRates"));
			DataSetField(Set, KeyAndValue.Key, KeyAndValue.Key, , New TypeDescription(TypesArray, New NumberQualifiers(35, 6), New StringQualifiers(150)));
		Else
			DataSetField(Set, KeyAndValue.Key, KeyAndValue.Key, , ColumnTypeOfCellStructure("Sum"));
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure AddResourcesAndCalculatedFields(DCS, ColumnStructure1, SourceFields_2, Balance)
	
	If ColumnStructure1 <> Undefined Then
		Periodicity_ = New Array;
		For Each Periodicity In ColumnStructure1.Periodicity_ Do
			Periodicity_.Add(FinancialReportingClientServer.PeriodStrings(Periodicity).Period);
		EndDo;
	EndIf;
	
	FinReports = FinancialReportingServer;
	
	FinReports.NewResource(DCS, "SerialNumber", , "MIN(SerialNumber)");
	FinReports.NewResource(DCS, "Note", ,     "MAX(Note)");
	
	SetFields = New Structure;
	SetFields.Insert("SumOpeningBalance");
	SetFields.Insert("SumReceipt");
	SetFields.Insert("SumExpense");
	SetFields.Insert("SumCurrOpeningBalance");
	SetFields.Insert("SumCurrReceipt");
	SetFields.Insert("SumCurrExpense");
	SetFields.Insert("CountOpeningBalance");
	SetFields.Insert("CountReceipt");
	SetFields.Insert("CountExpense");
	
	RemoveUnusedKeysFromStructure(SetFields, SourceFields_2);
	
	For Each KeyAndValue In SetFields Do
		
		If SourceFields_2.Find(KeyAndValue.Key) <> Undefined Then
			FinReports.NewResource(DCS, KeyAndValue.Key, , 	"SUM(ISNULL(" + KeyAndValue.Key + ", 0))");
		EndIf;
		
	EndDo;
	
	If Balance Then
		
		If SourceFields_2.Find("SumClosingBalance") <> Undefined Then
			FinReports.NewCalculatedResource(DCS, "SumClosingBalance", "0", , "SUM(ISNULL(SumOpeningBalance, 0)) +
																			|SUM(ISNULL(SumReceipt, 0)) -
																			|SUM(ISNULL(SumExpense, 0))");
		EndIf;
		If SourceFields_2.Find("SumCurrClosingBalance") <> Undefined Then
			FinReports.NewCalculatedResource(DCS, "SumCurrClosingBalance", "0", , "SUM(ISNULL(SumCurrOpeningBalance, 0)) +
																			|SUM(ISNULL(SumCurrReceipt, 0)) -
																			|SUM(ISNULL(SumCurrExpense, 0))");
		EndIf;
		If SourceFields_2.Find("CountClosingBalance") <> Undefined Then
			FinReports.NewCalculatedResource(DCS, "CountClosingBalance", "0", , "SUM(ISNULL(CountOpeningBalance, 0)) +
																				 |SUM(ISNULL(CountReceipt, 0)) -
																				 |SUM(ISNULL(CountExpense, 0))");
		EndIf;
		
	Else
		
		If SourceFields_2.Find("SumClosingBalance") <> Undefined Then
			FinReports.NewCalculatedResource(DCS, "SumClosingBalance", "0", , "0");
		EndIf;
		If SourceFields_2.Find("SumCurrClosingBalance") <> Undefined Then
			FinReports.NewCalculatedResource(DCS, "SumCurrClosingBalance", "0", , "0");
		EndIf;
		If SourceFields_2.Find("CountClosingBalance") <> Undefined Then
			FinReports.NewCalculatedResource(DCS, "CountClosingBalance", "0", , "0");
		EndIf;
		
	EndIf;
	
	If Balance And Periodicity_.Count() Then
		
		If SourceFields_2.Find("SumOpeningBalance") <> Undefined Then
			ResourceExpressionPattern = 
				"EvalExpression(""%1"",,,""First"",""First"") +
				|IsNull(EvalExpression(""%2"",,,""First"",""Previous""), 0) - 
				|IsNull(EvalExpression(""%3"",,,""First"",""Previous""), 0)";
			ResourceExpression = StrTemplate(ResourceExpressionPattern, 
				"SUM(ISNULL(SumOpeningBalance, 0))",
				"SUM(ISNULL(SumReceipt, 0))",
				"SUM(ISNULL(SumExpense, 0))");
			NewResource = FinReports.NewResource(DCS, "SumOpeningBalance", , ResourceExpression);
			CommonClientServer.SupplementArray(NewResource.Groups, Periodicity_);
		EndIf;
		
		If SourceFields_2.Find("SumCurrOpeningBalance") <> Undefined Then
			ResourceExpressionPattern = 
				"EvalExpression(""%1"",,,""First"",""First"") +
				|IsNull(EvalExpression(""%2"",,,""First"",""Previous""), 0) - 
				|IsNull(EvalExpression(""%3"",,,""First"",""Previous""), 0)";
			ResourceExpression = StrTemplate(ResourceExpressionPattern, 
				"SUM(ISNULL(SumCurrOpeningBalance, 0))",
				"SUM(ISNULL(SumCurrReceipt, 0))",
				"SUM(ISNULL(SumCurrExpense, 0))");
			NewResource = FinReports.NewResource(DCS, "SumCurrOpeningBalance", , ResourceExpression);
			CommonClientServer.SupplementArray(NewResource.Groups, Periodicity_);
		EndIf;
		
		If SourceFields_2.Find("SumClosingBalance") <> Undefined Then
			ResourceExpressionPattern = 
				"EvalExpression(""%1"",,,""First"",""First"") +
				|EvalExpression(""%2"",,,""First"",""Current"") - 
				|EvalExpression(""%3"",,,""First"",""Current"")";
			ResourceExpression = StrTemplate(ResourceExpressionPattern, 
				"SUM(ISNULL(SumOpeningBalance, 0))",
				"SUM(ISNULL(SumReceipt, 0))",
				"SUM(ISNULL(SumExpense, 0))");
			NewResource = FinReports.NewResource(DCS, "SumClosingBalance", , ResourceExpression);
			CommonClientServer.SupplementArray(NewResource.Groups, Periodicity_);
		EndIf;
		
		If SourceFields_2.Find("SumCurrClosingBalance") <> Undefined Then
			ResourceExpressionPattern = 
				"EvalExpression(""%1"",,,""First"",""First"") +
				|EvalExpression(""%2"",,,""First"",""Current"") - 
				|EvalExpression(""%3"",,,""First"",""Current"")";
			ResourceExpression = StrTemplate(ResourceExpressionPattern, 
				"SUM(ISNULL(SumCurrOpeningBalance, 0))",
				"SUM(ISNULL(SumCurrReceipt, 0))",
				"SUM(ISNULL(SumCurrExpense, 0))");
			NewResource = FinReports.NewResource(DCS, "SumCurrClosingBalance", , ResourceExpression);
			CommonClientServer.SupplementArray(NewResource.Groups, Periodicity_);
		EndIf;
		
		If SourceFields_2.Find("CountOpeningBalance") <> Undefined Then
			ResourceExpressionPattern = 
				"EvalExpression(""%1"",,,""First"",""First"") +
				|IsNull(EvalExpression(""%2"",,,""First"",""Previous""), 0) - 
				|IsNull(EvalExpression(""%3"",,,""First"",""Previous""), 0)";
			ResourceExpression = StrTemplate(ResourceExpressionPattern, 
				"SUM(ISNULL(CountOpeningBalance, 0))",
				"SUM(ISNULL(CountReceipt, 0))",
				"SUM(ISNULL(CountExpense, 0))");
			NewResource = FinReports.NewResource(DCS, "CountOpeningBalance", , ResourceExpression);
			CommonClientServer.SupplementArray(NewResource.Groups, Periodicity_);
		EndIf;
		
		If SourceFields_2.Find("CountClosingBalance") <> Undefined Then
			ResourceExpressionPattern = 
				"EvalExpression(""%1"",,,""First"",""First"") +
				|EvalExpression(""%2"",,,""First"",""Current"") - 
				|EvalExpression(""%3"",,,""First"",""Current"")";
			ResourceExpression = StrTemplate(ResourceExpressionPattern, 
				"SUM(ISNULL(CountOpeningBalance, 0))",
				"SUM(ISNULL(CountReceipt, 0))",
				"SUM(ISNULL(CountExpense, 0))");
			NewResource = FinReports.NewResource(DCS, "CountClosingBalance", , ResourceExpression);
			CommonClientServer.SupplementArray(NewResource.Groups, Periodicity_);
		EndIf;
	
	EndIf;
	
	If SourceFields_2.Find("SumTurnover") <> Undefined Then
		FinReports.NewCalculatedResource(DCS, "SumTurnover", "0",,
		"SUM(ISNULL(SumReceipt, 0)) - SUM(ISNULL(SumExpense, 0))");
	EndIf;
	
	If SourceFields_2.Find("SumCurrTurnover") <> Undefined Then
		FinReports.NewCalculatedResource(DCS, "SumCurrTurnover", "0",,
		"SUM(ISNULL(SumCurrReceipt, 0)) - SUM(ISNULL(SumCurrExpense, 0))");
	EndIf;
	
	If SourceFields_2.Find("CountTurnover") <> Undefined Then
		FinReports.NewCalculatedResource(DCS, "CountTurnover", "0",,
		"SUM(ISNULL(CountReceipt, 0)) - SUM(ISNULL(CountExpense, 0))");
	EndIf;
	
	FinReports.NewSelectionField(DCS.DefaultSettings, "SerialNumber");
	FinReports.NewSelectionField(DCS.DefaultSettings, "Note");
	
	SetFields = New Structure("SumOpeningBalance, SumReceipt, SumExpense,
								|SumCurrOpeningBalance, SumCurrReceipt, SumCurrExpense,
								|CountOpeningBalance, CountReceipt, CountExpense,
								|SumTurnover, SumCurrTurnover, CountTurnover, 
								|SumClosingBalance, SumCurrClosingBalance, CountClosingBalance");
								
	For Each KeyAndValue In SetFields Do
		
		If SourceFields_2.Find(KeyAndValue.Key) <> Undefined Then
			FinReports.NewSelectionField(DCS.DefaultSettings, KeyAndValue.Key);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure AddGroupingResourcesByMaximumFrequency(DCS, SourceFields_2, TimeFenceField, Group)
	
	ResourceGroupingFields = New Array;
	For Each GroupingField In Group.GroupFields.Items Do
		If TypeOf(GroupingField) = Type("DataCompositionGroupField") Then
			ResourceGroupingFields.Add(TrimAll(GroupingField.Field));
		EndIf;
	EndDo;
	
	FinReports = FinancialReportingServer;
	
	If SourceFields_2.Find("SumOpeningBalance") <> Undefined Then
		ResourceExpressionPattern = 
			"TargetValueMonitoring.GetLastArrayValue(EvalExpressionWithGroupArray(""%1"",""%2""), True)";
		ResourceExpression = StrTemplate(ResourceExpressionPattern, 
			"SUM(ISNULL(SumOpeningBalance, 0))",
			TimeFenceField);
		NewResource = FinReports.NewResource(DCS, "SumOpeningBalance", , ResourceExpression);
		CommonClientServer.SupplementArray(NewResource.Groups, ResourceGroupingFields);
	EndIf;
	
	If SourceFields_2.Find("SumCurrOpeningBalance") <> Undefined Then
		ResourceExpressionPattern = 
			"TargetValueMonitoring.GetLastArrayValue(EvalExpressionWithGroupArray(""%1"",""%2""), True)";
		ResourceExpression = StrTemplate(ResourceExpressionPattern, 
			"SUM(ISNULL(SumCurrOpeningBalance, 0))",
			TimeFenceField);
		NewResource = FinReports.NewResource(DCS, "SumCurrOpeningBalance", , ResourceExpression);
		CommonClientServer.SupplementArray(NewResource.Groups, ResourceGroupingFields);
	EndIf;
	
	If SourceFields_2.Find("SumClosingBalance") <> Undefined Then
		ResourceExpressionPattern = 
			"TargetValueMonitoring.GetLastArrayValue(EvalExpressionWithGroupArray(""%1"",""%2""), TRUE) + SUM(ISNULL(SumReceipt, 0)) - SUM(ISNULL(SumExpense, 0))";
		ResourceExpression = StrTemplate(ResourceExpressionPattern, 
			"SUM(ISNULL(SumOpeningBalance, 0))",
			TimeFenceField);
		NewResource = FinReports.NewResource(DCS, "SumClosingBalance", , ResourceExpression);
		CommonClientServer.SupplementArray(NewResource.Groups, ResourceGroupingFields);
	EndIf;
	
	If SourceFields_2.Find("SumCurrClosingBalance") <> Undefined Then
		ResourceExpressionPattern = 
			"TargetValueMonitoring.GetLastArrayValue(EvalExpressionWithGroupArray(""%1"",""%2""), TRUE) + SUM(ISNULL(SumCurrReceipt, 0)) - SUM(ISNULL(SumCurrExpense, 0))";
		ResourceExpression = StrTemplate(ResourceExpressionPattern, 
			"SUM(ISNULL(SumCurrOpeningBalance, 0))",
			TimeFenceField);
		NewResource = FinReports.NewResource(DCS, "SumCurrClosingBalance", , ResourceExpression);
		CommonClientServer.SupplementArray(NewResource.Groups, ResourceGroupingFields);
	EndIf;
	
EndProcedure

// Adds a string of layout fields
// 
// Parameters:
// 	Table - ValueTable - LongDesc:
// * Expression - String -
// * Presentation - String -
// * SelectingBankingDetails - Boolean -
Procedure AddRowOfLayoutFields(Table, Expression, Presentation, SelectingBankingDetails = False)
	
	TableRow = Table.Add();
	TableRow.Expression = Expression;
	TableRow.Presentation = Presentation;
	TableRow.SelectingBankingDetails = SelectingBankingDetails;
	
EndProcedure

Procedure AddSubordinateSetByBudgetRegister(DestinationParameters,
												SourceParameters,
												GenerationMode,
												DataReceiptMode,
												ActualDataStored = False)
	
	DCSPlanningData = DestinationParameters.DCSPlanningData;
	BasicCombinedSet = DestinationParameters.BasicCombinedSet;
	ParametersForInstallation_ = DestinationParameters.ParametersForInstallation_;
	Source = SourceParameters.Source; // See NewSource
	ColumnStructureOfDataTable = SourceParameters.ColumnStructureOfDataTable;
	Analysts = SourceParameters.Analysts;
	
	ForMetric = (Source.SourceType = Enums.BudgetingDataSourceTypes.Balance);
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	
	CalculationsRules = New Array;
	If Not ActualDataStored And GenerationMode = Enums.ModesOfBudgetReportGeneration.FillType
		Or ForMetric Then
		CalculationsRules = Source.CalculationsRules;
	EndIf;
	RequestAccordingToCalculationRules = BudgetingServer.GenerateRequestToDataSourceAccordingToCalculationRules(CalculationsRules,
		?(ActualDataStored, "StoredFact", "Plan"));
	
	#Region NSIRelatedIndicators
	
	QueryTextSelectionFields1 = New Map();
	
	TableOfLayoutFields = New ValueTable();
	TableOfLayoutFields.Columns.Add("Expression", New TypeDescription("String"));
	TableOfLayoutFields.Columns.Add("Presentation", New TypeDescription("String"));
	TableOfLayoutFields.Columns.Add("SelectingBankingDetails", New TypeDescription("Boolean"));
	
	QueryTextMasterData = "";
	If ForMetric Then
		QueryTextSelectionFields1.Insert("NumberOfUsedDimensions", "Data.BudgetBalanceItem.NumberOfUsedDimensions");
		
		For Cnt = 1 To MaximumNumberOfAnalysts Do
			QueryTextSelectionFields1.Insert("DimensionKind" + Cnt, "Data.BudgetBalanceItem.DimensionKind" + Cnt);
		EndDo;
		
		If IsBlankString(RequestAccordingToCalculationRules.QueryText) Then
		
			If Source.Objects <> Undefined Then
			
				ParameterName = "SelectedBudgetIndicators" + Source.Id;
				NSIConditions = StrTemplate("CalculationsRules.Receiver IN (&%1)", ParameterName);
			
 				List = New ValueList;
				List.LoadValues(Source.Objects);
				ParametersForInstallation_.Insert(ParameterName, List);
			
			Else
				NSIConditions = "TRUE";
			EndIf;
			
			QueryTextMasterData = StrReplace(BudgetingServer.GetQueryTextToSourceOfIndicatorDataWithoutCalculationRules(),
				"&ConditionText", NSIConditions);
			QueryTextMasterData = RequestSchemes.SetRoomToTemporaryTable(QueryTextMasterData, "Data");
			
		EndIf;
		
	EndIf;
	
	#EndRegion 
	
	#Region GettingDataWithBroadcastAnalytics
	
	QueryText =
	"SELECT
	|	&SelectionFields1
	|FROM
	|	&DataSource AS Data";
	
	QueryTextSelectionFields1.Insert("ID_Source1", """" + Source.Id + """");
	QueryTextSelectionFields1.Insert("BudgetFlowItem", "Data.BudgetFlowItem");
	If ForMetric Then
		QueryTextSelectionFields1.Insert("BudgetBalanceItem", "Data.BudgetBalanceItem");
		QueryTextSelectionFields1.Insert("RecordByCurrency", "Data.BudgetBalanceItem.RecordByCurrency");
		QueryTextSelectionFields1.Insert("CurrencyIsDeterminedByDimension", "Data.BudgetBalanceItem.CurrencyIsDeterminedByDimension");
		QueryTextSelectionFields1.Insert("DimensionAddressCurrency", "Data.BudgetBalanceItem.DimensionAddressCurrency");
		QueryTextSelectionFields1.Insert("CurrencyPopulationSource", "Data.BudgetBalanceItem.DimensionCurrencies.CurrencyFilling");
	Else
		QueryTextSelectionFields1.Insert("BudgetBalanceItem", "UNDEFINED");
		QueryTextSelectionFields1.Insert("RecordByCurrency", "Data.BudgetFlowItem.RecordByCurrency");
		QueryTextSelectionFields1.Insert("CurrencyIsDeterminedByDimension", "Data.BudgetFlowItem.CurrencyIsDeterminedByDimension");
		QueryTextSelectionFields1.Insert("DimensionAddressCurrency", "Data.BudgetFlowItem.DimensionAddressCurrency");
		QueryTextSelectionFields1.Insert("CurrencyPopulationSource", "Data.BudgetFlowItem.DimensionCurrencies.CurrencyFilling");
	EndIf;
	
	AddRowOfLayoutFields(TableOfLayoutFields, "ID_Source1", "ID_Source1");
	AddRowOfLayoutFields(TableOfLayoutFields, "BudgetBalanceItem", "BudgetBalanceItem", True);
	AddRowOfLayoutFields(TableOfLayoutFields, "BudgetFlowItem", "BudgetFlowItem", True);
	AddRowOfLayoutFields(TableOfLayoutFields, "RecordByCurrency", "RecordByCurrency");
	AddRowOfLayoutFields(TableOfLayoutFields, "CurrencyIsDeterminedByDimension", "CurrencyIsDeterminedByDimension");
	AddRowOfLayoutFields(TableOfLayoutFields, "DimensionAddressCurrency", "DimensionAddressCurrency");
	AddRowOfLayoutFields(TableOfLayoutFields, "CurrencyPopulationSource", "CurrencyPopulationSource");
	
	If ColumnStructureOfDataTable.Dimensions.Find("UnitOfMeasure") <> Undefined Then
		QueryTextSelectionFields1.Insert("RecordByQuantity", "Data.BudgetFlowItem.RecordByQuantity");
		QueryTextSelectionFields1.Insert("UnitOfMeasureIsDeterminedByDimension",
			"Data.BudgetFlowItem.UnitOfMeasureIsDeterminedByDimension");
		QueryTextSelectionFields1.Insert("QuantityDimensionAddress", "Data.BudgetFlowItem.QuantityDimensionAddress");
		QueryTextSelectionFields1.Insert("SourceFillingInUnit",
			"Data.BudgetFlowItem.DimensionUnitsOfMeasurement.UnitOfMeasureFilling");
		QueryTextSelectionFields1.Insert("UnitOfMeasure", "Data.BudgetFlowItem.UnitOfMeasure");
		
		AddRowOfLayoutFields(TableOfLayoutFields, "RecordByQuantity", "RecordByQuantity");
		AddRowOfLayoutFields(TableOfLayoutFields, "UnitOfMeasureIsDeterminedByDimension",
			"UnitOfMeasureIsDeterminedByDimension");
		AddRowOfLayoutFields(TableOfLayoutFields, "QuantityDimensionAddress", "QuantityDimensionAddress");
		AddRowOfLayoutFields(TableOfLayoutFields, "SourceFillingInUnit",
			"SourceFillingInUnit");
		AddRowOfLayoutFields(TableOfLayoutFields, "UnitOfMeasure", "UnitOfMeasure");
	EndIf;
	
	If ActualDataStored Then
		If Not ForMetric And GetFunctionalOption(
			"SettingUpRulesForObtainingFactsFromCorrespondingRegisters") Then
			ExpressionOfScriptField = "CASE WHEN Rule.RuleType = VALUE(Enum.ActualBudgetingDataQueryRuleType.BudgetFulfillment) THEN VALUE(Catalog.BudgetingScenarios.BudgetFulfillment) ELSE VALUE(Catalog.BudgetingScenarios.ActualData) END";
		Else
			ExpressionOfScriptField = "VALUE(Catalog.BudgetingScenarios.ActualData)";
		EndIf;
	EndIf;
	
	If ColumnStructureOfDataTable.Dimensions.Find("Scenario") = Undefined Then
		If ActualDataStored Then
			QueryTextSelectionFields1.Insert("Scenario", ExpressionOfScriptField);
		Else
			QueryTextSelectionFields1.Insert("Scenario", "Data.Scenario");
		EndIf;
		AddRowOfLayoutFields(TableOfLayoutFields, "Scenario", "Scenario", True);
	EndIf;
	
	For Each Dimension In ColumnStructureOfDataTable.Dimensions Do
		If Not StrFind(Dimension, "Dimension") Then
			If Dimension = "UnitOfMeasure" Then
				// Units of measurement are formed at the level
				// of the overall layout.
			ElsIf Dimension = "Scenario" And ActualDataStored Then
				QueryTextSelectionFields1.Insert("Scenario", ExpressionOfScriptField);
				AddRowOfLayoutFields(TableOfLayoutFields, "Scenario", "Scenario", True);
			ElsIf Dimension = "Currency" Then
				If ActualDataStored Then
					QueryTextSelectionFields1.Insert("StorageCurrency",
						"CASE WHEN Data.AmountInCurrencyTurnover <> 0 THEN Data.Currency ELSE UNDEFINED END");
				Else
					QueryTextSelectionFields1.Insert("StorageCurrency", "Data.Currency");
				EndIf;
				AddRowOfLayoutFields(TableOfLayoutFields, "StorageCurrency", "StorageCurrency");
			Else
				QueryTextSelectionFields1.Insert(Dimension, "Data." + Dimension);
				AddRowOfLayoutFields(TableOfLayoutFields, Dimension, Dimension, True);
			EndIf;
		EndIf;
	EndDo;
	
	// For indicators, we output all the analytics for calculating the currency.
	For Cnt = 1 To MaximumNumberOfAnalysts Do
		QueryTextSelectionFields1.Insert("Dimension" + Cnt, "Data.Dimension" + Cnt);
		AddRowOfLayoutFields(TableOfLayoutFields, "Dimension" + Cnt, "Dimension" + Cnt, True);
	EndDo;
	
	If ColumnStructureOfDataTable.Periodicity_.Count() Then
		
		If ActualDataStored Then
			ExpressionOfPeriodicity = StrReplace(Source.ExpressionOfGroupingPeriod, "PlanningPeriod", "DayPeriod");
		Else
			ExpressionOfPeriodicity = Source.ExpressionOfGroupingPeriod;
		EndIf;
		
		QueryTextSelectionFields1.Insert("Period", ExpressionOfPeriodicity);
		AddRowOfLayoutFields(TableOfLayoutFields, "Period", "Period");
		
	EndIf;
	
	For Each Var_700_Dimension In ColumnStructureOfDataTable.DimensionKinds Do
		
		ParameterName = FinancialReportingCached.NameOfBudgetReportField(Var_700_Dimension);
		
		NameOfAnalyticsViewParameter_ = "DimensionKind" + ParameterName;
		ParametersForInstallation_.Insert(NameOfAnalyticsViewParameter_, Var_700_Dimension);
		
		ExpressionParameters = BudgetingServer.TemplateForParametersForGettingTextOfFieldWithConditionForTypeOfAnalytics();
		If ForMetric Then
			ExpressionParameters.ExpressionNumberOfAnalyticsUsed = "Data.BudgetBalanceItem.NumberOfUsedDimensions";
			ExpressionParameters.ExpressionViewAnalyticsWithoutIndex = "Data.BudgetBalanceItem.DimensionKind";
		Else
			ExpressionParameters.ExpressionNumberOfAnalyticsUsed = "Data.BudgetFlowItem.NumberOfUsedDimensions";
			ExpressionParameters.ExpressionViewAnalyticsWithoutIndex = "Data.BudgetFlowItem.DimensionKind";
		EndIf;
		ExpressionParameters.ExpressingAnalyticsValueWithoutIndex = "Data.Dimension";
		ExpressionParameters.NameOfAnalyticsViewParameter = NameOfAnalyticsViewParameter_;
			
		FieldText = BudgetingServer.TextOfFieldWithConditionByTypeOfAnalytics(ExpressionParameters);
			
		QueryTextSelectionFields1.Insert(ParameterName, FieldText);
		AddRowOfLayoutFields(TableOfLayoutFields, ParameterName, ParameterName);
		
	EndDo;
	
	IndicatorText = "
		|CASE
		|	WHEN &FunctionalCurrency = VALUE(Enum.AccountingKindsInFunctionalCurrency.InManagementAccountingCurrency_) THEN
		|		SumManTurnover
		|	WHEN &FunctionalCurrency = VALUE(Enum.AccountingKindsInFunctionalCurrency.InCurrencyOfLocal) THEN
		|		SumComplTurnover
		|END";
	
	If Not ForMetric Then
		
		QueryTextSelectionFields1.Insert("SumReceipt", IndicatorText);
		QueryTextSelectionFields1.Insert("SumExpense", "0");
		QueryTextSelectionFields1.Insert("GrossParishAmount", "AmountInCurrencyTurnover");
		QueryTextSelectionFields1.Insert("AmountGrossExpense", "0");
		QueryTextSelectionFields1.Insert("CountReceipt", "CountTurnover");
		QueryTextSelectionFields1.Insert("CountExpense", "0");
		
	Else
		
		QueryTextSelectionFields1.Insert("SumReceipt", StringFunctionsClientServer.SubstituteParametersToString(
			"CASE WHEN NOT Data.Expense THEN %1 ELSE 0 END", IndicatorText));
		QueryTextSelectionFields1.Insert("SumExpense", StringFunctionsClientServer.SubstituteParametersToString(
			"CASE WHEN Data.Expense THEN %1 ELSE 0 END", IndicatorText));
		QueryTextSelectionFields1.Insert("GrossParishAmount",
			"CASE WHEN NOT Data.Expense THEN AmountInCurrencyTurnover ELSE 0 END");
		QueryTextSelectionFields1.Insert("AmountGrossExpense",
			"CASE WHEN Data.Expense THEN AmountInCurrencyTurnover ELSE 0 END");
		QueryTextSelectionFields1.Insert("SumOpeningBalance", "NULL");
		QueryTextSelectionFields1.Insert("AmountOfStorageShaftOpeningBalance", "NULL");
		QueryTextSelectionFields1.Insert("CountReceipt",
			"CASE WHEN NOT Data.Expense THEN CountTurnover ELSE 0 END");
		QueryTextSelectionFields1.Insert("CountExpense",
			"CASE WHEN Data.Expense THEN CountTurnover ELSE 0 END");
		QueryTextSelectionFields1.Insert("CountOpeningBalance", "NULL");
		
	EndIf;
	
	AddRowOfLayoutFields(TableOfLayoutFields, "SumReceipt", "SumReceipt");
	AddRowOfLayoutFields(TableOfLayoutFields, "SumExpense", "SumExpense");
	AddRowOfLayoutFields(TableOfLayoutFields, "GrossParishAmount", "GrossParishAmount");
	AddRowOfLayoutFields(TableOfLayoutFields, "AmountGrossExpense", "AmountGrossExpense");
	AddRowOfLayoutFields(TableOfLayoutFields, "CountReceipt", "CountReceipt");
	AddRowOfLayoutFields(TableOfLayoutFields, "CountExpense", "CountExpense");
	If ForMetric Then
		AddRowOfLayoutFields(TableOfLayoutFields, "SumOpeningBalance", "SumOpeningBalance");
		AddRowOfLayoutFields(TableOfLayoutFields, "AmountOfStorageShaftOpeningBalance", "AmountOfStorageShaftOpeningBalance");
		AddRowOfLayoutFields(TableOfLayoutFields, "CountOpeningBalance", "CountOpeningBalance");
	EndIf;
	
	AddRowOfLayoutFields(TableOfLayoutFields, "RatePeriod", "RatePeriod");
	QueryTextSelectionFields1.Insert("RatePeriod", "Data.DayPeriod");
	
	If Not IsBlankString(RequestAccordingToCalculationRules.QueryText) Or Not IsBlankString(QueryTextMasterData) Then
		DataSourceText = "(
			|SELECT
			|	*
			|FROM
			|	Data AS Data
			|WHERE
			|	&ConditionsForReceiverTableAndLineUpFields)";
		For Each QueryParameter In RequestAccordingToCalculationRules.QueryOptions Do
			DataCompositionServer.AddParameter(DCSPlanningData, QueryParameter.Key, , QueryParameter.Value, True,
				True);
		EndDo;
		If Not IsBlankString(RequestAccordingToCalculationRules.QueryTextTT) Then
			If ForMetric Then
				RequestAccordingToCalculationRules.QueryTextTT = StrReplace(RequestAccordingToCalculationRules.QueryTextTT, "&ExpressionStartOfPeriod",
					Source.ExpressionStartOfPeriod);
				RequestAccordingToCalculationRules.QueryTextTT = StrReplace(RequestAccordingToCalculationRules.QueryTextTT, "&ExpressionEndOfPeriod",
					Source.ExpressionEndOfPeriod);
			EndIf;
			RequestAccordingToCalculationRules.QueryTextTT = RequestAccordingToCalculationRules.QueryTextTT
				+ Common.QueryBatchSeparator();
		EndIf;
		If Not IsBlankString(RequestAccordingToCalculationRules.QueryText) Then
			If ForMetric Then
				RequestAccordingToCalculationRules.QueryText = StrReplace(RequestAccordingToCalculationRules.QueryText, "&ExpressionStartOfPeriod",
					Source.ExpressionStartOfPeriod);
				RequestAccordingToCalculationRules.QueryText = StrReplace(RequestAccordingToCalculationRules.QueryText, "&ExpressionEndOfPeriod",
					Source.ExpressionEndOfPeriod);
			EndIf;
			RequestAccordingToCalculationRules.QueryText = RequestAccordingToCalculationRules.QueryText
				+ Common.QueryBatchSeparator();
		EndIf;
	ElsIf ActualDataStored Then
		TablePeriodicity = "AUTO";
		DataSourceText = "AccumulationRegister.ActualBudgetingData.Turnovers(
			|		{&ExpressionStartOfPeriod AS BeginOfPeriod_},
			|		{&ExpressionEndOfPeriod AS EndOfPeriod_},
			|		&TablePeriodicity,
			|		&SourceTableConditionsAndAlignmentFields)
			|";
		DataSourceText = StrReplace(DataSourceText, "&ExpressionStartOfPeriod", Source.ExpressionStartOfPeriod);
		DataSourceText = StrReplace(DataSourceText, "&ExpressionEndOfPeriod", Source.ExpressionEndOfPeriod);
		DataSourceText = StrReplace(DataSourceText, "&TablePeriodicity", TablePeriodicity);
	Else
		TablePeriodicity = "AUTO";
		DataSourceText = "AccumulationRegister.BudgetTurnovers.Turnovers(
			|		{&DateEmpty}, 
			|		{&UpdateDate}, &TablePeriodicity,
			|			PlanningPeriod BETWEEN &ExpressionStartOfPeriod AND &ExpressionEndOfPeriod
			|			AND &SourceTableConditionsAndAlignmentFields)
			|";
		DataSourceText = StrReplace(DataSourceText, "&ExpressionStartOfPeriod", Source.ExpressionStartOfPeriod);
		DataSourceText = StrReplace(DataSourceText, "&ExpressionEndOfPeriod", Source.ExpressionEndOfPeriod);
		DataSourceText = StrReplace(DataSourceText, "&TablePeriodicity", TablePeriodicity);
	EndIf;
	
	ConditionsForSourceTable = New Map;
	LayoutConditionsForVirtualSourceTable = New Map;
	If RequestAccordingToCalculationRules.SourcesTypes.Count() = 0 Then
		SourcesTypes = CommonClientServer.ValueInArray("BudgetTurnovers");
	Else
		SourcesTypes = RequestAccordingToCalculationRules.SourcesTypes;
	EndIf;
	For Each SourceType In SourcesTypes Do
		ConditionsForSourceTable.Insert(SourceType, New Array);
		LayoutConditionsForVirtualSourceTable.Insert(SourceType, New Array);
	EndDo;
	ConditionsAccordingToReceiverTable = New Array;
	LayoutConditionsForReceiverVirtualTable = New Array;
	
	DimensionsBySourceType = New Map;
	AddConditionForCompany = True;
	For Each SourceType In SourcesTypes Do
		SourceTypeValue = Enums.DataSourceTypesForBudgeting[SourceType];
		DimensionsBySourceType.Insert(SourceType,
			BudgetingCached.MatchingBudgetingDimensionsBySourceType(SourceTypeValue));
		If AddConditionForCompany
			And Enums.DataSourceTypesForBudgeting.BySourceTypeRecordsAreKeptForCompany(SourceTypeValue) Then
			AddConditionForCompany = False;
		EndIf;
	EndDo;
	
	If AddConditionForCompany Then
		QueryTextByCompanies = 
		"SELECT TOP 1
		|	Companies.Ref AS Ref
		|INTO TT_Companies
		|FROM
		|	Catalog.Companies AS Companies
		|{WHERE
		|	Companies.Ref.* AS Company_Id}";
		QueryTextByCompanies = StrReplace(QueryTextByCompanies, "Id", Source.Id);
		RequestAccordingToCalculationRules.QueryTextTT = RequestAccordingToCalculationRules.QueryTextTT + 
			QueryTextByCompanies + Common.QueryBatchSeparator();
	EndIf;
	
	If Source.Objects <> Undefined
		// In the request generated according to the calculation rules, there is already a selection by budget items
		And IsBlankString(RequestAccordingToCalculationRules.QueryText) Then
		
		If Not ForMetric Then
			ParameterName = "SelectedBudgetItems" + Source.Id;
			Expression = "BudgetFlowItem IN (&" + ParameterName + ")";
			ConditionsForSourceTable["BudgetTurnovers"].Add(Expression);
			
			List = New ValueList;
			List.LoadValues(Source.Objects);
			ParametersForInstallation_.Insert(ParameterName, List);
		EndIf;
		
	EndIf;
	
	For Each Dimension In ColumnStructureOfDataTable.Dimensions Do
		FilterByDimensions = Undefined;
		If Dimension = "UnitOfMeasure" Then
			// Units of measurement are formed at the level
			// of the overall layout.
			Continue;
		EndIf;
		If ActualDataStored And Dimension = "Scenario" Then
			Continue;
		EndIf;
		If Source.Property(Dimension, FilterByDimensions)
			And ValueIsFilled(FilterByDimensions) Then
			
			ParameterName = "Selected_" + Dimension + Source.Id;
			For Each SourceType In SourcesTypes Do
				DimensionBySourceType = DimensionsBySourceType.Get(SourceType)[Dimension];
				If DimensionBySourceType <> Undefined Then
					Expression = "" + StrReplace(DimensionBySourceType, "TableName.", "") + " " + "IN (&"
						+ ParameterName + ")";
					ConditionsForSourceTable[SourceType].Add(Expression);
				EndIf;
			EndDo;
			
			List = New ValueList;
			List.LoadValues(FilterByDimensions);
			ParametersForInstallation_.Insert(ParameterName, List);
			
		EndIf;
	EndDo;
	
	If Not ForMetric Then 
		For Each Dimension In ColumnStructureOfDataTable.DimensionKinds Do
			FilterByDimensions = Undefined;
			NameOfAnalytics = FinancialReportingCached.NameOfBudgetReportField(Dimension);
			If Source.Property(NameOfAnalytics, FilterByDimensions)
				And ValueIsFilled(FilterByDimensions) Then
				
				NameOfAnalyticsViewParameter_ = "DimensionKind" + NameOfAnalytics;
				ParametersForInstallation_.Insert(NameOfAnalyticsViewParameter_, Dimension);
				
				ExpressionParameters = BudgetingServer.TemplateForParametersForGettingTextOfFieldWithConditionForTypeOfAnalytics();
				ExpressionParameters.ExpressionNumberOfAnalyticsUsed = "BudgetFlowItem.NumberOfUsedDimensions";
				ExpressionParameters.ExpressionViewAnalyticsWithoutIndex = "BudgetFlowItem.DimensionKind";
				ExpressionParameters.ExpressingAnalyticsValueWithoutIndex = "Dimension";
				ExpressionParameters.NameOfAnalyticsViewParameter = NameOfAnalyticsViewParameter_;
				
				AnalyticsText = BudgetingServer.TextOfFieldWithConditionByTypeOfAnalytics(ExpressionParameters);
				
				ParameterName = "Selected_" + NameOfAnalytics + Source.Id;
				
				Expression = "" + AnalyticsText + " " + "IN (&" + ParameterName + ")";
				If IsBlankString(RequestAccordingToCalculationRules.QueryText) Then
					ConditionsForSourceTable["BudgetTurnovers"].Add(Expression);
				Else
					ConditionsAccordingToReceiverTable.Add(Expression);
				EndIf;
				
				List = New ValueList;
				List.LoadValues(FilterByDimensions);
				ParametersForInstallation_.Insert(ParameterName, List);
				
			EndIf;
		EndDo;
	EndIf;
	
	If Not ActualDataStored Then
		For Each SourceType In SourcesTypes Do
			LayoutConditionsForVirtualSourceTable[SourceType].Add("(Status).* AS Status");
		EndDo;
	EndIf;
	
	FiltersStructure = New Structure("Scenario, Organization, StorageCurrency, Department, Status");
	For Cnt = 1 To MaximumNumberOfAnalysts Do
		FiltersStructure.Insert("Dimension" + Cnt);
	EndDo;
	
	For Each KeyAndValue In FiltersStructure Do
		
		If FindSelectionByName(Source.AdditionalSelection, KeyAndValue.Key,, True) Then
			If ActualDataStored Then
				If KeyAndValue.Key = "Scenario" Then
					Expression = "(VALUE(Catalog.BudgetingScenarios.ActualData)).* AS" + " " + KeyAndValue.Key + "_" + Source.Id;
					If Not IsBlankString(QueryTextMasterData) Then
						LayoutConditionsForReceiverVirtualTable.Add(Expression);
					Else
						LayoutConditionsForVirtualSourceTable["BudgetTurnovers"].Add(Expression);
					EndIf;
					Continue;
				EndIf;
			EndIf;
			
			Expression = StringFunctionsClientServer.SubstituteParametersToString(
				"(%1).* AS %1_%2",
				KeyAndValue.Key,
				Source.Id);
			If Not IsBlankString(RequestAccordingToCalculationRules.QueryText) And StrFind(KeyAndValue.Key, "Dimension") > 0
				Or Not IsBlankString(QueryTextMasterData) Then
				If KeyAndValue.Key = "StorageCurrency" Then
					Expression = "(Currency).* AS" + " " + KeyAndValue.Key + "_" + Source.Id;
				EndIf;
				LayoutConditionsForReceiverVirtualTable.Add(Expression);
			Else
				For Each SourceType In SourcesTypes Do
					DimensionBySourceType = DimensionsBySourceType.Get(SourceType)[KeyAndValue.Key];
					If DimensionBySourceType <> Undefined Then
						ExpressionBySourceType = StrReplace(Expression, "(" + KeyAndValue.Key + ").*", "(" + StrReplace(
							DimensionBySourceType, "TableName.", "") + ").*");
						LayoutConditionsForVirtualSourceTable[SourceType].Add(ExpressionBySourceType);
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		
	EndDo;
	
	// Selection by the value of analytics in the parameters of the virtual table is possible only for revolutions.
	If Not ForMetric Then
		For Each Var_700_Dimension In Analysts Do
			
			ParameterName = FinancialReportingCached.NameOfBudgetReportField(Var_700_Dimension);
			If FindSelectionByName(Source.AdditionalSelection, ParameterName,, True) Then
				
				NameOfAnalyticsViewParameter_ = "DimensionKind" + ParameterName;
				
				ExpressionParameters = BudgetingServer.TemplateForParametersForGettingTextOfFieldWithConditionForTypeOfAnalytics();
				ExpressionParameters.ExpressionNumberOfAnalyticsUsed = "BudgetFlowItem.NumberOfUsedDimensions";
				ExpressionParameters.ExpressionViewAnalyticsWithoutIndex = "BudgetFlowItem.DimensionKind";
				ExpressionParameters.ExpressingAnalyticsValueWithoutIndex = "Dimension";
				ExpressionParameters.NameOfAnalyticsViewParameter = NameOfAnalyticsViewParameter_;
				
				FieldText = BudgetingServer.TextOfFieldWithConditionByTypeOfAnalytics(ExpressionParameters);
				
				Expression = StringFunctionsClientServer.SubstituteParametersToString(
					"(%1).* AS %2_%3",
					FieldText,
					ParameterName,
					Source.Id);
				If Not IsBlankString(RequestAccordingToCalculationRules.QueryText) Then
					LayoutConditionsForReceiverVirtualTable.Add(Expression);
				Else
					LayoutConditionsForVirtualSourceTable["BudgetTurnovers"].Add(Expression);
				EndIf;
				
				ParametersForInstallation_.Insert(NameOfAnalyticsViewParameter_, Var_700_Dimension);
				AddSchemaParameter(DCSPlanningData, NameOfAnalyticsViewParameter_);
				
			EndIf;
			
		EndDo;
	EndIf;
	
	SourceTableConditionsAndAlignmentFields = New Map;
	For Each SourceType In SourcesTypes Do
		If ConditionsForSourceTable[SourceType].Count() = 0 Then
			SourceTableConditionsAndAlignmentFields.Insert(SourceType, "TRUE");
		Else
			SeparatorAnd = Chars.LF + Chars.Tab + Chars.Tab + Chars.Tab + " And ";
			SourceTableConditionsAndAlignmentFields.Insert(SourceType, StrConcat(
				ConditionsForSourceTable[SourceType], SeparatorAnd));
		EndIf;
	EndDo;
	If ConditionsAccordingToReceiverTable.Count() = 0 Then
		ConditionsForReceiverTableAndLineUpFields = "TRUE";
	Else
		SeparatorAnd = Chars.LF + Chars.Tab + Chars.Tab + Chars.Tab + " And ";
		ConditionsForReceiverTableAndLineUpFields = StrConcat(ConditionsAccordingToReceiverTable, SeparatorAnd);
	EndIf;
	For Each SourceType In SourcesTypes Do
		If LayoutConditionsForVirtualSourceTable[SourceType].Count() > 0 Then
			Expression = StrConcat(LayoutConditionsForVirtualSourceTable[SourceType], ", ");
			SourceTableConditionsAndAlignmentFields[SourceType] = StringFunctionsClientServer.SubstituteParametersToString(
				"%1 {%2}",
				SourceTableConditionsAndAlignmentFields[SourceType],
				Expression);
		EndIf;
	EndDo;
	If LayoutConditionsForReceiverVirtualTable.Count() > 0 Then
		Expression = StrConcat(LayoutConditionsForReceiverVirtualTable, ", ");
		ConditionsForReceiverTableAndLineUpFields = StringFunctionsClientServer.SubstituteParametersToString(
			"%1
			|{WHERE %2}",
			ConditionsForReceiverTableAndLineUpFields,
			Expression);
	EndIf;
	If Not IsBlankString(RequestAccordingToCalculationRules.QueryText) Then
		For Each SourceType In SourcesTypes Do
			NameOfTableConditionParameter = "&SourceTableConditionsAndAlignmentFields" + ?(SourceType = "BudgetTurnovers", "",
				"_" + SourceType);
			RequestAccordingToCalculationRules.QueryText = StrReplace(RequestAccordingToCalculationRules.QueryText,
				NameOfTableConditionParameter, SourceTableConditionsAndAlignmentFields[SourceType]);
			If Not IsBlankString(RequestAccordingToCalculationRules.QueryTextTT) Then
				RequestAccordingToCalculationRules.QueryTextTT = StrReplace(RequestAccordingToCalculationRules.QueryTextTT,
					NameOfTableConditionParameter, SourceTableConditionsAndAlignmentFields[SourceType]);
			EndIf;
		EndDo;
		DataSourceText = StrReplace(DataSourceText, "&ConditionsForReceiverTableAndLineUpFields",
			ConditionsForReceiverTableAndLineUpFields);
	ElsIf Not IsBlankString(QueryTextMasterData) Then
		DataSourceText = StrReplace(DataSourceText, "&ConditionsForReceiverTableAndLineUpFields",
			ConditionsForReceiverTableAndLineUpFields);
	Else
		DataSourceText = StrReplace(DataSourceText, "&SourceTableConditionsAndAlignmentFields",
			SourceTableConditionsAndAlignmentFields["BudgetTurnovers"]);
	EndIf;
	
	SelectionFields1 = "";
	For Each SynonymAndExpression In QueryTextSelectionFields1 Do
		SelectionFields1 = SelectionFields1 + ?(SelectionFields1 = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"%1 AS %2",
				SynonymAndExpression.Value,
				SynonymAndExpression.Key);
	EndDo;
	QueryText = StrReplace(QueryText, "&SelectionFields1", SelectionFields1);
	QueryText = StrReplace(QueryText, "&DataSource", DataSourceText);
	
	If Not ActualDataStored And 
		(GenerationMode = Enums.ModesOfBudgetReportGeneration.Document
		Or GenerationMode = Enums.ModesOfBudgetReportGeneration.PrintBudget) Then
		If IsBlankString(RequestAccordingToCalculationRules.QueryText) Then
			QueryTextExceptions = QueryText;
			QueryTextExceptions = StrReplace(QueryTextExceptions, IndicatorText, "-" + IndicatorText);
			QueryTextExceptions = StrReplace(QueryTextExceptions, "AmountInCurrencyTurnover", "-AmountInCurrencyTurnover");
			QueryTextExceptions = StrReplace(QueryTextExceptions, "CountTurnover", "-CountTurnover");
			QueryTextExceptions = QueryTextExceptions + Chars.LF + "WHERE %1"; // @query-part
		Else
			PositionIndexBy = StrFind(RequestAccordingToCalculationRules.QueryText, "INDEX BY"); // @query-part
			QueryTextExceptions = StrReplace(Left(RequestAccordingToCalculationRules.QueryText, PositionIndexBy - 1),
				"INTO Data", ""); // @query-part
			ExceptionQueryTexts = StringFunctionsClientServer.SplitStringIntoSubstringsArray(QueryTextExceptions,
				TMCommonUse.QuerySeparatorInJoin());
			For Counter = 0 To ExceptionQueryTexts.UBound() Do
				QueryTextExceptions = ExceptionQueryTexts[Counter];
				QueryTextExceptions = StrReplace(QueryTextExceptions, "AliasOfSourceTable.SumManTurnover",
					"-AliasOfSourceTable.SumManTurnover");
				QueryTextExceptions = StrReplace(QueryTextExceptions, "AliasOfSourceTable.SumComplTurnover",
					"-AliasOfSourceTable.SumComplTurnover");
				QueryTextExceptions = StrReplace(QueryTextExceptions, "AliasOfSourceTable.ScenarioAmountTurnover",
					"-AliasOfSourceTable.ScenarioAmountTurnover");
				QueryTextExceptions = StrReplace(QueryTextExceptions, "AliasOfSourceTable.AmountInCurrencyTurnover",
					"-AliasOfSourceTable.AmountInCurrencyTurnover");
				QueryTextExceptions = StrReplace(QueryTextExceptions, "AliasOfSourceTable.CountTurnover",
					"-AliasOfSourceTable.CountTurnover");
				QueryTextExceptions = QueryTextExceptions + Chars.LF + "AND %1"; // @query-part
				ExceptionQueryTexts[Counter] = QueryTextExceptions;
			EndDo;
			QueryTextExceptions = StrConcat(ExceptionQueryTexts, TMCommonUse.QuerySeparatorInJoin());
		EndIf;
		QueryTextExceptions = StringFunctionsClientServer.SubstituteParametersToString(QueryTextExceptions,
			"(Recorder = &Document OR &Action = VALUE(Enum.TypesOfBudgetEntryFormActions.CorrectBudgetEntryForm))"); // @query-part
		If Not IsBlankString(RequestAccordingToCalculationRules.QueryText) Then
			RequestAccordingToCalculationRules.QueryText = Left(RequestAccordingToCalculationRules.QueryText, PositionIndexBy
				- 1) + TMCommonUse.QuerySeparatorInJoin() + QueryTextExceptions + Chars.LF
				+ Chars.Tab + Mid(RequestAccordingToCalculationRules.QueryText, PositionIndexBy);
		Else
			QueryText = QueryText + TMCommonUse.QuerySeparatorInJoin() + QueryTextExceptions;
		EndIf;
		
	EndIf;
	
	#EndRegion 
	
	#Region AdditionalSelection_Data
	
	RequestSource = QueryText;
	QueryText = ?(IsBlankString(QueryTextMasterData), "", QueryTextMasterData + Common.QueryBatchSeparator())
		+ RequestAccordingToCalculationRules.QueryTextTT + RequestAccordingToCalculationRules.QueryText +
		"SELECT ALLOWED
		|	* 
		|FROM
		|	&RequestSource AS PreliminaryCalculation
		|";
	QueryText = StrReplace(QueryText, "&RequestSource", "(" + RequestSource + ")");
	
	TableOfLayoutConditionFields = New ValueTable();
	TableOfLayoutConditionFields.Columns.Add("Expression", New TypeDescription("String"));
	TableOfLayoutConditionFields.Columns.Add("Presentation", New TypeDescription("String"));
	TableOfLayoutConditionFields.Columns.Add("SelectingBankingDetails", New TypeDescription("Boolean"));
	
	// Additional selection taking into account the translation of analytics from the article to the indicator
	If ForMetric Then
		For Each Dimension In ColumnStructureOfDataTable.DimensionKinds Do
			FilterByDimensions = Undefined;
			NameOfAnalytics = FinancialReportingCached.NameOfBudgetReportField(Dimension);
			If Source.Property(NameOfAnalytics, FilterByDimensions)
				And ValueIsFilled(FilterByDimensions) Then
				
				NameOfAnalyticsViewParameter_ = "DimensionKind" + NameOfAnalytics;
				ParametersForInstallation_.Insert(NameOfAnalyticsViewParameter_, Dimension);
				
				ExpressionParameters = BudgetingServer.TemplateForParametersForGettingTextOfFieldWithConditionForTypeOfAnalytics();
				ExpressionParameters.ExpressionNumberOfAnalyticsUsed = "PreliminaryCalculation.NumberOfUsedDimensions";
				ExpressionParameters.ExpressionViewAnalyticsWithoutIndex = "PreliminaryCalculation.DimensionKind";
				ExpressionParameters.ExpressingAnalyticsValueWithoutIndex = "PreliminaryCalculation.Dimension";
				ExpressionParameters.NameOfAnalyticsViewParameter = NameOfAnalyticsViewParameter_;
				
				AnalyticsText = BudgetingServer.TextOfFieldWithConditionByTypeOfAnalytics(ExpressionParameters);
				
				ParameterName = "Selected_" + NameOfAnalytics + Source.Id;
				
				Expression = StrTemplate("%1 IN (&%2)", AnalyticsText, ParameterName);
				AddRowOfLayoutFields(TableOfLayoutConditionFields, Expression, "");
				
				List = New ValueList;
				List.LoadValues(FilterByDimensions);
				ParametersForInstallation_.Insert(ParameterName, List);
				
			EndIf;
		EndDo;
		
		For Each Var_700_Dimension In Analysts Do
			
			ParameterName = FinancialReportingCached.NameOfBudgetReportField(Var_700_Dimension);
			If FindSelectionByName(Source.AdditionalSelection, ParameterName,, True) Then
				
				NameOfAnalyticsViewParameter_ = "DimensionKind" + ParameterName;
				
				ExpressionParameters = BudgetingServer.TemplateForParametersForGettingTextOfFieldWithConditionForTypeOfAnalytics();
				ExpressionParameters.ExpressionNumberOfAnalyticsUsed = "PreliminaryCalculation.NumberOfUsedDimensions";
				ExpressionParameters.ExpressionViewAnalyticsWithoutIndex = "PreliminaryCalculation.DimensionKind";
				ExpressionParameters.ExpressingAnalyticsValueWithoutIndex = "PreliminaryCalculation.Dimension";
				ExpressionParameters.NameOfAnalyticsViewParameter = NameOfAnalyticsViewParameter_;
				
				FieldText = BudgetingServer.TextOfFieldWithConditionByTypeOfAnalytics(ExpressionParameters);
				
				AddRowOfLayoutFields(TableOfLayoutConditionFields,
						FieldText,
						ParameterName + "_" + Source.Id);
				
				ParametersForInstallation_.Insert(NameOfAnalyticsViewParameter_, Var_700_Dimension);
				AddSchemaParameter(DCSPlanningData, NameOfAnalyticsViewParameter_);
				
			EndIf;
			
		EndDo;
	EndIf;
	
	If Not DataReceiptMode = Enums.BudgetingDataReceiptMode.Allowed Then
		QueryText = RequestSchemes.SetSelectionOfAllowedRecordsInEntireRequest(QueryText, False);
	EndIf;
	If TableOfLayoutFields.Count() > 0
		Or TableOfLayoutConditionFields.Count() > 0 Then
		
		QuerySchema = New QuerySchema();
		QuerySchema.SetQueryText(QueryText);
		PackageIndex = ?(QueryTextMasterData = "", 0, 1);
		If Not IsBlankString(RequestAccordingToCalculationRules.QueryTextTT) Then
			PackageIndex = PackageIndex + StrOccurrenceCount(RequestAccordingToCalculationRules.QueryTextTT, ";");
		EndIf;
		If Not IsBlankString(RequestAccordingToCalculationRules.QueryText) Then
			PackageIndex = PackageIndex + 1;
		EndIf;
		ModifiedRequest = QuerySchema.QueryBatch.Get(PackageIndex);
		If TypeOf(ModifiedRequest) = Type("QuerySchemaTableDropQuery") Then
			Raise NStr("vi = 'Không thể thêm tham số vào bảng hủy truy vấn.';
						|ru = 'Невозможно добавить поля в запрос уничтожения таблицы.';
						|en = 'Cannot add fields to the table removal query.'; fa = 'Cannot add fields to the table removal query.';
						|it = 'Impossibile aggiungere i campi nella query di eliminazione della tabella.';
						|pl = 'Nie można dodać pól do żądania zniszczenia tabeli.';
						|tr = 'Tablo yıkma isteğine alan eklenemez.'"); 
		EndIf;
		
		For Each CDString In TableOfLayoutFields Do
			DCField = ModifiedRequest.DataCompositionSelectionFields.Add(CDString.Expression); // QuerySchemaDataCompositionSelectionField -
			DCField.Alias = CDString.Presentation;
			DCField.UseAttributes = CDString.SelectingBankingDetails;
		EndDo;
		
		SelectOperator = ModifiedRequest.Operators.Get(0);
		For Each CDString In TableOfLayoutConditionFields Do
			DCField = SelectOperator.DataCompositionFilterExpressions.Add(CDString.Expression); // QuerySchemaDataCompositionFilterExpression
			DCField.Alias = CDString.Presentation;
			DCField.UseAttributes = CDString.SelectingBankingDetails;
		EndDo;
		
		QueryText = QuerySchema.GetQueryText();
	EndIf;
	
	#EndRegion 
	
	SourceType = Type("DataCompositionSchemaDataSetQuery");
	If ActualDataStored Then
		Name = "Set_Fact_Revolutions_" + Source.Id;
		QueryText = StrReplace(QueryText, "AS BeginOfPeriod_", "");
		QueryText = StrReplace(QueryText, "AS EndOfPeriod_", "");
	Else
		Name = "Set_Plan_Revolutions_" + Source.Id;
	EndIf;
	DCSSet = DataCompositionServer.AddEmptyDataSet(BasicCombinedSet, SourceType, Name);
	DCSSet.Query = QueryText;
	
EndProcedure

Procedure RemoveUnusedKeysFromStructure(Structure, ArrayOfAvailable)
	
	ForDeletion = New Array;
	For Each KeysAndValue In Structure Do
		If ArrayOfAvailable.Find(KeysAndValue.Key) = Undefined Then
			ForDeletion.Add(KeysAndValue.Key);
		EndIf;
	EndDo;
	
	For Each Var_Key In ForDeletion Do
		Structure.Delete(Var_Key);
	EndDo;
	
EndProcedure

Procedure AddSubordinateSetAccordingToRegisterOfOpeningBalances(DestinationParameters, SourceParameters,
	GenerationMode, DataReceiptMode)
	
	DCSPlanningData = DestinationParameters.DCSPlanningData;
	BasicCombinedSet = DestinationParameters.BasicCombinedSet;
	ParametersForInstallation_ = DestinationParameters.ParametersForInstallation_;
	Source = SourceParameters.Source; // See NewSource
	ColumnStructureOfDataTable = SourceParameters.ColumnStructureOfDataTable;
	Analysts = SourceParameters.Analysts;
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	
	#Region MasterDATAOfIndicators
	
	QueryTextSelectionFields1 = New Map();
	
	TableOfLayoutFields = New ValueTable();
	TableOfLayoutFields.Columns.Add("Expression", New TypeDescription("String"));
	TableOfLayoutFields.Columns.Add("Presentation", New TypeDescription("String"));
	TableOfLayoutFields.Columns.Add("SelectingBankingDetails", New TypeDescription("Boolean"));
	
	QueryTextSelectionFields1.Insert("NumberOfUsedDimensions", "Data.BudgetBalanceItem.NumberOfUsedDimensions");
	
	For Cnt = 1 To MaximumNumberOfAnalysts Do
		QueryTextSelectionFields1.Insert("DimensionKind" + Cnt, "Data.BudgetBalanceItem.DimensionKind" + Cnt);
	EndDo;
	
	QueryTextTemporaryTable = StrConcat(
		InformationRegisters.OpeningBalanceOfEstimates.QueryTextsCurrentBalanceDatesByScenario(False, False,
			True), Common.QueryBatchSeparator());
	
	QueryTextTemporaryTable = StrReplace(QueryTextTemporaryTable, "&StartingDateOfBalances",
		Source.ExpressionStartOfPeriod);
	
	#EndRegion 
	
	#Region GettingDataWithBroadcastAnalytics
	
	QueryText =
	"SELECT
	|	&SelectionFields11
	|FROM
	|	InformationRegister.OpeningBalanceOfEstimates AS Data
	|WHERE
	|	Data.DateOfRemainingGoods = &StartingDateOfBalances
	|	AND TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				CurrentBalanceDatesByScenario
	|			WHERE
	|				CurrentBalanceDatesByScenario.DateOfRemainingGoods = Data.DateOfRemainingGoods
	|				AND CurrentBalanceDatesByScenario.BudgetBalanceItem = Data.BudgetBalanceItem
	|				AND CurrentBalanceDatesByScenario.Scenario = Data.Scenario)
	|	AND &SourceTableConditionsAndLayoutFields
	|
	|UNION ALL
	|
	|SELECT
	|	&SelectionFields12
	|FROM
	|	InformationRegister.OpeningBalanceOfEstimates AS Data
	|		LEFT JOIN BudgetingScenarios AS BudgetingScenarios
	|		ON (TRUE)
	|WHERE
	|	Data.DateOfRemainingGoods = &StartingDateOfBalances
	|	AND TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				CurrentBalanceDates
	|			WHERE
	|				CurrentBalanceDates.DateOfRemainingGoods = Data.DateOfRemainingGoods
	|				AND CurrentBalanceDates.BudgetBalanceItem = Data.BudgetBalanceItem)
	|	AND NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					CurrentBalanceDatesByScenario
	|				WHERE
	|					CurrentBalanceDatesByScenario.DateOfRemainingGoods = Data.DateOfRemainingGoods
	|					AND CurrentBalanceDatesByScenario.BudgetBalanceItem = Data.BudgetBalanceItem
	|					AND CurrentBalanceDatesByScenario.Scenario = BudgetingScenarios.Scenario)
	|	AND Data.Scenario = VALUE(Catalog.BudgetingScenarios.EmptyRef)
	|	AND &SourceTableConditionsAndLayoutFields";
	QueryTextSelectionFields1.Insert("ID_Source1", """" + Source.Id + """");
	QueryTextSelectionFields1.Insert("BudgetBalanceItem", "Data.BudgetBalanceItem");
	QueryTextSelectionFields1.Insert("RecordByCurrency", "Data.BudgetBalanceItem.RecordByCurrency");
	QueryTextSelectionFields1.Insert("CurrencyIsDeterminedByDimension", "Data.BudgetBalanceItem.CurrencyIsDeterminedByDimension");
	QueryTextSelectionFields1.Insert("DimensionAddressCurrency", "Data.BudgetBalanceItem.DimensionAddressCurrency");
	QueryTextSelectionFields1.Insert("CurrencyPopulationSource", "Data.BudgetBalanceItem.DimensionCurrencies.CurrencyFilling");
	
	AddRowOfLayoutFields(TableOfLayoutFields, "ID_Source1", "ID_Source1");
	AddRowOfLayoutFields(TableOfLayoutFields, "BudgetBalanceItem", "BudgetBalanceItem", True);
	AddRowOfLayoutFields(TableOfLayoutFields, "RecordByCurrency", "RecordByCurrency");
	AddRowOfLayoutFields(TableOfLayoutFields, "CurrencyIsDeterminedByDimension", "CurrencyIsDeterminedByDimension");
	AddRowOfLayoutFields(TableOfLayoutFields, "DimensionAddressCurrency", "DimensionAddressCurrency");
	AddRowOfLayoutFields(TableOfLayoutFields, "CurrencyPopulationSource", "CurrencyPopulationSource");
	
	If ColumnStructureOfDataTable.Dimensions.Find("UnitOfMeasure") <> Undefined Then
		QueryTextSelectionFields1.Insert("RecordByQuantity", "Data.BudgetBalanceItem.RecordByQuantity");
		QueryTextSelectionFields1.Insert("UnitOfMeasureIsDeterminedByDimension",
			"Data.BudgetBalanceItem.UnitOfMeasureIsDeterminedByDimension");
		QueryTextSelectionFields1.Insert("QuantityDimensionAddress", "Data.BudgetBalanceItem.QuantityDimensionAddress");
		QueryTextSelectionFields1.Insert("SourceFillingInUnit",
			"Data.BudgetBalanceItem.DimensionUnitsOfMeasurement.UnitOfMeasureFilling");
		QueryTextSelectionFields1.Insert("UnitOfMeasure", "Data.BudgetBalanceItem.UnitOfMeasure");
		
		AddRowOfLayoutFields(TableOfLayoutFields, "RecordByQuantity", "RecordByQuantity");
		AddRowOfLayoutFields(TableOfLayoutFields, "UnitOfMeasureIsDeterminedByDimension",
			"UnitOfMeasureIsDeterminedByDimension");
		AddRowOfLayoutFields(TableOfLayoutFields, "QuantityDimensionAddress", "QuantityDimensionAddress");
		AddRowOfLayoutFields(TableOfLayoutFields, "SourceFillingInUnit",
			"SourceFillingInUnit");
		AddRowOfLayoutFields(TableOfLayoutFields, "UnitOfMeasure", "UnitOfMeasure");
	EndIf;
	
	If ColumnStructureOfDataTable.Dimensions.Find("Scenario") = Undefined Then
		QueryTextSelectionFields1.Insert("Scenario", "Data.Scenario");
		AddRowOfLayoutFields(TableOfLayoutFields, "Scenario", "Scenario", True);
	EndIf;
	
	For Each Dimension In ColumnStructureOfDataTable.Dimensions Do
		If Not StrFind(Dimension, "Dimension") Then
			If Dimension = "UnitOfMeasure" Then
				// Units of measurement are formed at the level
				// of the overall layout.
			ElsIf Dimension = "Currency" Then
				QueryTextSelectionFields1.Insert("StorageCurrency", "Data.Currency");
				AddRowOfLayoutFields(TableOfLayoutFields, "StorageCurrency", "StorageCurrency");
			Else
				QueryTextSelectionFields1.Insert(Dimension, "Data." + Dimension);
				AddRowOfLayoutFields(TableOfLayoutFields, Dimension, Dimension, True);
			EndIf;
		EndIf;
	EndDo;
	
	// For indicators, we output all the analytics for calculating the currency.
	For Cnt = 1 To MaximumNumberOfAnalysts Do
		QueryTextSelectionFields1.Insert("Dimension" + Cnt, "Data.Dimension" + Cnt);
		AddRowOfLayoutFields(TableOfLayoutFields, "Dimension" + Cnt, "Dimension" + Cnt, True);
	EndDo;
	
	If ColumnStructureOfDataTable.Periodicity_.Count() Then
		
		ExpressionOfPeriodicity = StrReplace(Source.ExpressionOfGroupingPeriod, "PlanningPeriod", "DateOfRemainingGoods");
		QueryTextSelectionFields1.Insert("Period", ExpressionOfPeriodicity);
		AddRowOfLayoutFields(TableOfLayoutFields, "Period", "Period");
		
	EndIf;
	
	For Each Var_763_Dimension In ColumnStructureOfDataTable.DimensionKinds Do
		
		ParameterName = FinancialReportingCached.NameOfBudgetReportField(Var_763_Dimension);
		
		NameOfAnalyticsViewParameter_ = "DimensionKind" + ParameterName;
		ParametersForInstallation_.Insert(NameOfAnalyticsViewParameter_, Var_763_Dimension);
		
		ExpressionParameters = BudgetingServer.TemplateForParametersForGettingTextOfFieldWithConditionForTypeOfAnalytics();
		ExpressionParameters.ExpressionNumberOfAnalyticsUsed = "Data.BudgetBalanceItem.NumberOfUsedDimensions";
		ExpressionParameters.ExpressionViewAnalyticsWithoutIndex = "Data.BudgetBalanceItem.DimensionKind";
		ExpressionParameters.ExpressingAnalyticsValueWithoutIndex = "Data.Dimension";
		ExpressionParameters.NameOfAnalyticsViewParameter = NameOfAnalyticsViewParameter_;
		
		FieldText = BudgetingServer.TextOfFieldWithConditionByTypeOfAnalytics(ExpressionParameters);
		
		QueryTextSelectionFields1.Insert(ParameterName, FieldText);
		AddRowOfLayoutFields(TableOfLayoutFields, ParameterName, ParameterName);
		
	EndDo;
	
	IndicatorText = "
		|CASE
		|	WHEN &FunctionalCurrency = VALUE(Enum.AccountingKindsInFunctionalCurrency.InManagementAccountingCurrency_) THEN
		|		SumMan
		|	WHEN &FunctionalCurrency = VALUE(Enum.AccountingKindsInFunctionalCurrency.InCurrencyOfLocal) THEN
		|		SumCompl
		|END";
	
	QueryTextSelectionFields1.Insert("SumOpeningBalance", IndicatorText);
	QueryTextSelectionFields1.Insert("AmountOfStorageShaftOpeningBalance", "AmountInCurrency");
	QueryTextSelectionFields1.Insert("CountOpeningBalance", "Count");
	
	AddRowOfLayoutFields(TableOfLayoutFields, "SumOpeningBalance", "SumOpeningBalance");
	AddRowOfLayoutFields(TableOfLayoutFields, "AmountOfStorageShaftOpeningBalance",
		"AmountOfStorageShaftOpeningBalance");
	AddRowOfLayoutFields(TableOfLayoutFields, "CountOpeningBalance", "CountOpeningBalance");
	
	AddRowOfLayoutFields(TableOfLayoutFields, "RatePeriod", "RatePeriod");
	QueryTextSelectionFields1.Insert("RatePeriod", "Data.DateOfRemainingGoods");
	
	KeySelectionFields = "BudgetBalanceItem,Scenario";
	ConditionsForSourceTable = New Structure("Other," + KeySelectionFields, New Array);
	TableLayoutConditions = New Structure("Other," + KeySelectionFields, New Array);
	
	If Source.Objects <> Undefined Then
		
		ParameterName = "SelectedBudgetIndicators" + Source.Id;
		Expression = "OpeningBalanceOfEstimates.BudgetBalanceItem IN (&" + ParameterName + ")";
		ConditionsForSourceTable.BudgetBalanceItem = Expression;
		
		List = New ValueList;
		List.LoadValues(Source.Objects);
		ParametersForInstallation_.Insert(ParameterName, List);
		
	EndIf;
	
	For Each Dimension In ColumnStructureOfDataTable.Dimensions Do
		FilterByDimensions = Undefined;
		If Dimension = "UnitOfMeasure" Then
			// Units of measurement are formed at the level
			// of the overall layout.
			Continue;
		EndIf;
		If Source.Property(Dimension, FilterByDimensions)
			And ValueIsFilled(FilterByDimensions) Then
			
			ParameterName = "Selected_" + Dimension + Source.Id;
			If Dimension = "Scenario" Then
				Expression = "BudgetingScenarios.Ref IN (&" + ParameterName + ")";
				ConditionsForSourceTable.Scenario = Expression;
			Else
				Expression = "Data." + Dimension + " " + "IN (&" + ParameterName + ")";
				ConditionsForSourceTable.Other.Add(Expression);
			EndIf;
			
			List = New ValueList;
			List.LoadValues(FilterByDimensions);
			ParametersForInstallation_.Insert(ParameterName, List);
			
		EndIf;
	EndDo;
	
	For Each Dimension In ColumnStructureOfDataTable.DimensionKinds Do
		FilterByDimensions = Undefined;
		NameOfAnalytics = FinancialReportingCached.NameOfBudgetReportField(Dimension);
		If Source.Property(NameOfAnalytics, FilterByDimensions)
			And ValueIsFilled(FilterByDimensions) Then
			
			NameOfAnalyticsViewParameter_ = "DimensionKind" + NameOfAnalytics;
			ParametersForInstallation_.Insert(NameOfAnalyticsViewParameter_, Dimension);
			
			ExpressionParameters = BudgetingServer.TemplateForParametersForGettingTextOfFieldWithConditionForTypeOfAnalytics();
			ExpressionParameters.ExpressionNumberOfAnalyticsUsed = "BudgetBalanceItem.NumberOfUsedDimensions";
			ExpressionParameters.ExpressionViewAnalyticsWithoutIndex = "BudgetBalanceItem.DimensionKind";
			ExpressionParameters.ExpressingAnalyticsValueWithoutIndex = "Dimension";
			ExpressionParameters.NameOfAnalyticsViewParameter = NameOfAnalyticsViewParameter_;
			
			AnalyticsText = BudgetingServer.TextOfFieldWithConditionByTypeOfAnalytics(ExpressionParameters);
			
			ParameterName = "Selected_" + NameOfAnalytics + Source.Id;
			
			Expression = "Data." + AnalyticsText + " " + "IN (&" + ParameterName + ")";
			ConditionsForSourceTable.Other.Add(Expression);
			
			List = New ValueList;
			List.LoadValues(FilterByDimensions);
			ParametersForInstallation_.Insert(ParameterName, List);
			
		EndIf;
	EndDo;
	
	FiltersStructure = New Structure("Scenario, Organization, StorageCurrency, Department, Status");
	For Cnt = 1 To MaximumNumberOfAnalysts Do
		FiltersStructure.Insert("Dimension" + Cnt);
	EndDo;
	
	For Each KeyAndValue In FiltersStructure Do
		
		If FindSelectionByName(Source.AdditionalSelection, KeyAndValue.Key,, True) Then
			If KeyAndValue.Key = "StorageCurrency" Then
				Expression = "(Data.Currency).* AS" + " " + KeyAndValue.Key + "_" + Source.Id;
				TableLayoutConditions.Other.Add(Expression);
				Continue;
			EndIf;
			
			If KeyAndValue.Key = "Scenario" Then
				Expression = StringFunctionsClientServer.SubstituteParametersToString("(BudgetingScenarios.Ref).* AS %1_%2",
					KeyAndValue.Key, Source.Id);
				TableLayoutConditions.Scenario = Expression;
			Else
				Expression = StringFunctionsClientServer.SubstituteParametersToString("(Data.%1).* AS %1_%2", KeyAndValue.Key,
					Source.Id);
				TableLayoutConditions.Other.Add(Expression);
			EndIf;
		EndIf;
		
	EndDo;
	
	For Each Var_763_Dimension In Analysts Do
		
		ParameterName = FinancialReportingCached.NameOfBudgetReportField(Var_763_Dimension);
		If FindSelectionByName(Source.AdditionalSelection, ParameterName,, True) Then
			
			NameOfAnalyticsViewParameter_ = "DimensionKind" + ParameterName;
			
			ExpressionParameters = BudgetingServer.TemplateForParametersForGettingTextOfFieldWithConditionForTypeOfAnalytics();
			ExpressionParameters.ExpressionNumberOfAnalyticsUsed = "Data.BudgetBalanceItem.NumberOfUsedDimensions";
			ExpressionParameters.ExpressionViewAnalyticsWithoutIndex = "Data.BudgetBalanceItem.DimensionKind";
			ExpressionParameters.ExpressingAnalyticsValueWithoutIndex = "Data.Dimension";
			ExpressionParameters.NameOfAnalyticsViewParameter = NameOfAnalyticsViewParameter_;
			
			FieldText = BudgetingServer.TextOfFieldWithConditionByTypeOfAnalytics(ExpressionParameters);
			
			Expression = StringFunctionsClientServer.SubstituteParametersToString(
				"(%1).* AS %2_%3",
				FieldText,
				ParameterName,
				Source.Id);
			TableLayoutConditions.Other.Add(Expression);
			
			ParametersForInstallation_.Insert(NameOfAnalyticsViewParameter_, Var_763_Dimension);
			AddSchemaParameter(DCSPlanningData, NameOfAnalyticsViewParameter_);
			
		EndIf;
		
	EndDo;
	
	For Each KeySelectionField In StrSplit(KeySelectionFields, ",") Do
		If Not IsBlankString(ConditionsForSourceTable[KeySelectionField]) Then
			ConditionText = ConditionsForSourceTable[KeySelectionField];
		Else
			ConditionText = "TRUE";
		EndIf;
		If Not IsBlankString(TableLayoutConditions[KeySelectionField]) Then
			ConditionText = StringFunctionsClientServer.SubstituteParametersToString(
				"%1
				|{WHERE %2}",
				ConditionText,
				TableLayoutConditions[KeySelectionField]);
		EndIf;
		QueryTextTemporaryTable = StrReplace(QueryTextTemporaryTable, "&Condition" + KeySelectionField,
			ConditionText);
	EndDo;
	If ConditionsForSourceTable.Other.Count() = 0 Then
		SourceTableConditionsAndLayoutFields = "TRUE";
	Else
		SeparatorAnd = Chars.LF + Chars.Tab + Chars.Tab + Chars.Tab + " And ";
		SourceTableConditionsAndLayoutFields = StrConcat(ConditionsForSourceTable.Other, SeparatorAnd);
	EndIf;
	If TableLayoutConditions.Other.Count() > 0 Then
		Expression = StrConcat(TableLayoutConditions.Other, ", ");
		SourceTableConditionsAndLayoutFields = StringFunctionsClientServer.SubstituteParametersToString(
			"%1
			|{WHERE %2}",
			SourceTableConditionsAndLayoutFields,
			Expression);
	EndIf;
	QueryText = StrReplace(QueryText, "&StartingDateOfBalances", Source.ExpressionStartOfPeriod);
	QueryText = StrReplace(QueryText, "&SourceTableConditionsAndLayoutFields", SourceTableConditionsAndLayoutFields);
	
	SelectionFields11 = New Array;
	SelectionFields12 = New Array;
	For Each SynonymAndExpression In QueryTextSelectionFields1 Do
		SelectionFields11.Add(StringFunctionsClientServer.SubstituteParametersToString("%1 AS %2",
			SynonymAndExpression.Value, SynonymAndExpression.Key));
		SelectionFields12.Add(StringFunctionsClientServer.SubstituteParametersToString("%1 AS %2",
			?(SynonymAndExpression.Key = "Scenario", "BudgetingScenarios.Scenario", SynonymAndExpression.Value),
			SynonymAndExpression.Key));
		If SynonymAndExpression.Key = "SumOpeningBalance"
			Or SynonymAndExpression.Key = "AmountOfStorageShaftOpeningBalance"
			Or SynonymAndExpression.Key = "CountOpeningBalance" Then
			Continue;
		EndIf;
	EndDo;
	QueryText = StrReplace(QueryText, "&SelectionFields11", StrConcat(SelectionFields11, "," + Chars.LF + Chars.Tab));
	QueryText = StrReplace(QueryText, "&SelectionFields12", StrConcat(SelectionFields12, "," + Chars.LF + Chars.Tab));
	
	#EndRegion 
	
	#Region AdditionalSelection_Data
	
	RequestSource = QueryText;
	QueryText = QueryTextTemporaryTable + Common.QueryBatchSeparator() + 
		"SELECT ALLOWED
		|	* 
		|FROM
		|	&RequestSource AS PreliminaryCalculation
		|";
	QueryText = StrReplace(QueryText, "&RequestSource", "(" + RequestSource + ")");
	
	If Not DataReceiptMode = Enums.BudgetingDataReceiptMode.Allowed Then
		QueryText = RequestSchemes.SetSelectionOfAllowedRecordsInEntireRequest(QueryText, False);
	EndIf;
	If TableOfLayoutFields.Count() > 0 Then
		
		QuerySchema = New QuerySchema();
		QuerySchema.SetQueryText(QueryText);
		ModifiedRequest = QuerySchema.QueryBatch.Get(3);
		If TypeOf(ModifiedRequest) = Type("QuerySchemaTableDropQuery") Then
			Raise NStr("vi = 'Không thể thêm tham số vào bảng hủy truy vấn.';
						|ru = 'Невозможно добавить поля в запрос уничтожения таблицы.';
						|en = 'Cannot add fields to the table removal query.'; fa = 'Cannot add fields to the table removal query.';
						|it = 'Impossibile aggiungere i campi nella query di eliminazione della tabella.';
						|pl = 'Nie można dodać pól do żądania zniszczenia tabeli.';
						|tr = 'Tablo yıkma isteğine alan eklenemez.'"); 
		EndIf;
		
		For Each CDString In TableOfLayoutFields Do
			DCField = ModifiedRequest.DataCompositionSelectionFields.Add(CDString.Expression); // QuerySchemaDataCompositionSelectionField -
			DCField.Alias = CDString.Presentation;
			DCField.UseAttributes = CDString.SelectingBankingDetails;
		EndDo;
		
		QueryText = QuerySchema.GetQueryText();
	EndIf;
	
	#EndRegion 
	
	SourceType = Type("DataCompositionSchemaDataSetQuery");
	Name = "Set_Plan_OpeningBalances_" + Source.Id;
	DCSSet = DataCompositionServer.AddEmptyDataSet(BasicCombinedSet, SourceType, Name);
	DCSSet.Query = QueryText;
	
EndProcedure

// LongDesc
// 
// Parameters:
// 	DataSources - Array of See NewSource -
// 	SourceFields_2 - ValueTable -
// 	ColumnStructureOfDataTable - Arbitrary, Boolean, Structure, Undefined - LongDesc:
// * DimensionKinds - Array -
// * Dimensions - Array -
// * Periodicity_ - Array -
// 	Analysts - Array - LongDesc
// 	ParametersForInstallation_ - Structure - LongDesc
// 	FormationModes - Structure - LongDesc:
// * PrivilegedMode - Boolean -
// * GenerationMode - EnumRef.ModesOfBudgetReportGeneration -
// * DataReceiptMode - EnumRef.BudgetingDataReceiptMode -
// Returns:
// 	DataCompositionSchema -
Function GetDCSPlanningData(DataSources, SourceFields_2, ColumnStructureOfDataTable, Analysts, ParametersForInstallation_, FormationModes)
	
	GenerationMode = FormationModes.GenerationMode;
	DataReceiptMode = FormationModes.DataReceiptMode;
	If FormationModes.Property("PrivilegedMode") Then 
		PrivilegedMode = FormationModes.PrivilegedMode;
	Else
		PrivilegedMode = False;
	EndIf;
	
	FinReports = FinancialReportingServer;
	DCSPlanningData = DataCompositionServer.EmptyCircuit();
	
	BasicCombinedSet = DataCompositionServer.AddEmptyDataSet(
		DCSPlanningData,
		Type("DataCompositionSchemaDataSetUnion"),
		"Data");
	
	ResourceFields = New Structure;
	ResourceFields.Insert("SumReceipt");
	ResourceFields.Insert("SumExpense");
	ResourceFields.Insert("SumCurrReceipt");
	ResourceFields.Insert("SumCurrExpense");
	ResourceFields.Insert("CountReceipt");
	ResourceFields.Insert("CountExpense");
	ResourceFields.Insert("SumOpeningBalance");
	ResourceFields.Insert("SumCurrOpeningBalance");
	ResourceFields.Insert("CountOpeningBalance");
	
	RemoveUnusedKeysFromStructure(ResourceFields, SourceFields_2);
	
	AddDataTableFieldsByDescription(BasicCombinedSet, ColumnStructureOfDataTable, ResourceFields);
	
	OpeningBalancesAreUsed = False;
	
	// filling in data source sets
	For Each Source In DataSources Do
		
		If Source.PrivilegedMode = Undefined And PrivilegedMode 
			Or (Not Source.PrivilegedMode = Undefined And Not Source.PrivilegedMode = PrivilegedMode) Then
			Continue;
		EndIf;
		
		If Source.SourceType = Enums.BudgetingDataSourceTypes.Turnovers
			Or Source.SourceType = Enums.BudgetingDataSourceTypes.Balance Then
			
			DestinationParameters = New Structure;
			DestinationParameters.Insert("DCSPlanningData", DCSPlanningData);
			DestinationParameters.Insert("BasicCombinedSet", BasicCombinedSet);
			DestinationParameters.Insert("ParametersForInstallation_", ParametersForInstallation_);
			SourceParameters = New Structure;
			SourceParameters.Insert("Source", Source);
			SourceParameters.Insert("ColumnStructureOfDataTable", ColumnStructureOfDataTable);
			SourceParameters.Insert("Analysts", Analysts);
			
			AddSubordinateSetByBudgetRegister(DestinationParameters,
				SourceParameters,
				GenerationMode,
				DataReceiptMode);
			
			AdditionalSelection = Source.AdditionalSelection;
			If AdditionalSelection <> Undefined Then
				FinancialReportingServer.CopyFilter(AdditionalSelection.Filter,
						DCSPlanningData.DefaultSettings.Filter,
						True,,
						"_" + Source.Id);
			EndIf;
			
		EndIf;
		
		If Source.SourceType = Enums.BudgetingDataSourceTypes.Balance Then
			AddSubordinateSetAccordingToRegisterOfOpeningBalances(DestinationParameters, SourceParameters, GenerationMode,
				DataReceiptMode);
			OpeningBalancesAreUsed = True;
		EndIf;
		
	EndDo;
	
	PeriodName = "Undefined";
	If ColumnStructureOfDataTable.Periodicity_.Count() Then
		PeriodName = "Period";
	EndIf;
	
	ExpressionOfCalculatedField =
	"CASE WHEN NOT RecordByQuantity THEN VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|	WHEN NOT UnitOfMeasureIsDeterminedByDimension THEN UnitOfMeasure
	|	ELSE
	|		CAST(BudgetReportingDisplayServer.Attachable_ValueFromAnalytics(
	|			&CacheAnalystValues,
	|			%1,
	|			SourceFillingInUnit), ""Catalog.PackagesAndUnitsOfMeasure"")
	|	END";
	SupplementExpressionOfCalculatedFieldWithTranslationByNumber(
		ExpressionOfCalculatedField,
		"QuantityDimensionAddress",
		"Dimension",
		Undefined,
		3);
	FinReports.NewCalculatedField(DCSPlanningData,
		"UnitOfMeasure",
		ExpressionOfCalculatedField,,,
		New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	
	ResourceFieldsQuantity = New Array;
	ResourceFieldsQuantity.Add("CountReceipt");
	ResourceFieldsQuantity.Add("CountExpense");
	If OpeningBalancesAreUsed Then
		ResourceFieldsQuantity.Add("CountOpeningBalance");
	EndIf;
	
	For Each ResourceFieldQuantity In ResourceFieldsQuantity Do
		
		If ResourceFields.Property(ResourceFieldQuantity) Then
		
			ExpressionOfCalculatedField = StrReplace(StringFunctionsClientServer.SubstituteParametersToString(
				"CASE WHEN (NOT RecordByQuantity OR NOT UnitOfMeasureIsDeterminedByDimension) THEN %1
				|	ELSE &TextFillingSourceUnits
				|	END", ResourceFieldQuantity), "&TextFillingSourceUnits",
				TextOfFillingSourceConditionUnits(ResourceFieldQuantity));
			SupplementExpressionOfCalculatedFieldWithTranslationByNumber(
				ExpressionOfCalculatedField,
				"QuantityDimensionAddress",
				"Dimension",
				Undefined,
				3);
			FinReports.NewCalculatedField(DCSPlanningData,
				ResourceFieldQuantity,
				ExpressionOfCalculatedField,,,
				New TypeDescription("Number", New NumberQualifiers(15,3)));
		
		EndIf;
	
	EndDo;
	
	ExpressionOfCalculatedField =
	"CASE WHEN BudgetBalanceItem = UNDEFINED
	|	OR (NOT RecordByCurrency OR NOT CurrencyIsDeterminedByDimension) THEN StorageCurrency
	|	ELSE
	|		CAST(BudgetReportingDisplayServer.Attachable_ValueFromAnalytics(
	|			&CacheAnalystValues,
	|			%1, 
	|			CurrencyPopulationSource,
	|			StorageCurrency), ""Catalog.Currencies"")
	|	END";
	SupplementExpressionOfCalculatedFieldWithTranslationByNumber(
		ExpressionOfCalculatedField,
		"DimensionAddressCurrency",
		"Dimension",
		Undefined,
		3);
	FinReports.NewCalculatedField(DCSPlanningData,
		"Currency",
		ExpressionOfCalculatedField,,,
		New TypeDescription("CatalogRef.Currencies"));
		
	FinReports.NewCalculatedField(
		DCSPlanningData, "StorageCurrency", ExpressionOfCalculatedField,,, New TypeDescription("CatalogRef.Currencies"));
	
	ResourceFieldsCurrency = New Map;
	ResourceFieldsCurrency.Insert("SumCurrReceipt", "GrossParishAmount");
	ResourceFieldsCurrency.Insert("SumCurrExpense", "AmountGrossExpense");
	If OpeningBalancesAreUsed Then
		ResourceFieldsCurrency.Insert("SumCurrOpeningBalance", "AmountOfStorageShaftOpeningBalance");
	EndIf;
	
	For Each CurrencyResourceField In ResourceFieldsCurrency Do
	
		If ResourceFields.Property(CurrencyResourceField.Key) Then
			
			MoneyType = TMCommonUse.MoneyFieldTypeDescription();
			TypeBitDepth = MoneyType.NumberQualifiers.Digits;
			TypeBitFraction = MoneyType.NumberQualifiers.FractionDigits;
			
			ExpressionOfCalculatedField =
			"CASE WHEN BudgetBalanceItem = UNDEFINED
			|	OR (NOT RecordByCurrency OR NOT CurrencyIsDeterminedByDimension) THEN ISNULL(%ResourceName%, 0)
			|	ELSE
			|		CAST(BudgetReportingDisplayServer.Attachable_ConvertAtRate(
			|								ISNULL(%ResourceName%, 0),
			|								%PeriodName%,
			|								StorageCurrency,
			|								Scenario,
			|								&CacheOfScheduledCourses,
			|								&CacheAnalystValues,
			|								%1,
			|								CurrencyPopulationSource), ""Number(%TypeBitDepth, %TypeOfCutPart)"")
			|	END";
			
			ExpressionOfCalculatedField = StrReplace(ExpressionOfCalculatedField, "%ResourceName%", CurrencyResourceField.Value);
			ExpressionOfCalculatedField = StrReplace(ExpressionOfCalculatedField, "%PeriodName%", PeriodName);
			ExpressionOfCalculatedField = StrReplace(ExpressionOfCalculatedField,
					"%TypeBitDepth",
					Format(TypeBitDepth, "NZ=0; NG=0;"));
			ExpressionOfCalculatedField = StrReplace(ExpressionOfCalculatedField,
					"%TypeOfCutPart",
					Format(TypeBitFraction, "NZ=0; NG=0;"));
			SupplementExpressionOfCalculatedFieldWithTranslationByNumber(
				ExpressionOfCalculatedField,
				"DimensionAddressCurrency",
				"Dimension",
				Undefined,
				8);
			
			FinReports.NewCalculatedField(DCSPlanningData,
				CurrencyResourceField.Key,
				ExpressionOfCalculatedField,,,
				MoneyType);
		EndIf;
		
	EndDo;
	
	AddSchemaParameter(DCSPlanningData, "BeginOfPeriod");
	AddSchemaParameter(DCSPlanningData, "EndOfPeriod");
	
	AddSchemaParameter(DCSPlanningData, "CacheOfScheduledCourses");
	AddSchemaParameter(DCSPlanningData, "CacheAnalystValues");
	
	// configuring the SKD
	For Each KeyAndValue In ResourceFields Do
		FinReports.NewResource(DCSPlanningData, KeyAndValue.Key, , 		"SUM(" + KeyAndValue.Key + ")");
		FinReports.NewSelectionField(DCSPlanningData.DefaultSettings, KeyAndValue.Key);
	EndDo;
	
	GroupingScheduledTasks = AddFieldsToSummaryTableByDescription(DCSPlanningData, ColumnStructureOfDataTable);
	
	If ColumnStructureOfDataTable.Periodicity_.Count() Then
		FinReports.NewDimensionField(GroupingScheduledTasks, "Period");
	EndIf;
	
	FinReports.NewDimensionField(GroupingScheduledTasks, "StorageCurrency");
	FinReports.NewDimensionField(GroupingScheduledTasks, "RatePeriod");
	
	DataCompositionClientServer.DisableOutputOfTotals(DCSPlanningData.DefaultSettings);
	
	Return DCSPlanningData;
	
EndFunction

// Gets the fact. SKD data
// 
// Parameters:
// 	DataSources - Array of See NewSource -
// 	SourceFields_2 - ValueTable - LongDesc
// 	ColumnStructureOfDataTable - Arbitrary, Boolean, Structure, Undefined - LongDesc:
// * DimensionKinds - Array -
// * Dimensions - Array -
// * Periodicity_ - Array -
// 	Analysts - Array - LongDesc
// 	ParametersForInstallation_ - Structure - LongDesc
// 	FormationModes - Structure - LongDesc:
// * GenerationMode - EnumRef.ModesOfBudgetReportGeneration -
// * DataReceiptMode - EnumRef.BudgetingDataReceiptMode - 
// Returns:
// 	DataCompositionSchema - LongDesc
Function GetDCSActualData(DataSources, SourceFields_2, ColumnStructureOfDataTable, Analysts, ParametersForInstallation_, FormationModes)
	
	GenerationMode = FormationModes.GenerationMode;
	DataReceiptMode = FormationModes.DataReceiptMode;
	If FormationModes.Property("PrivilegedMode") Then 
		PrivilegedMode = FormationModes.PrivilegedMode;
	Else
		PrivilegedMode = False;
	EndIf;
	
	FinReports = FinancialReportingServer;
	DCSActualData = DataCompositionServer.EmptyCircuit();
	
	BasicCombinedSet = DataCompositionServer.AddEmptyDataSet(
		DCSActualData,
		Type("DataCompositionSchemaDataSetUnion"),
		"Data");
	
	ResourceFields = New Structure;
	ResourceFields.Insert("SumReceipt");
	ResourceFields.Insert("SumExpense");
	ResourceFields.Insert("SumCurrReceipt");
	ResourceFields.Insert("SumCurrExpense");
	ResourceFields.Insert("CountReceipt");
	ResourceFields.Insert("CountExpense");
	
	RemoveUnusedKeysFromStructure(ResourceFields, SourceFields_2);
	
	AddDataTableFieldsByDescription(BasicCombinedSet, ColumnStructureOfDataTable, ResourceFields);
	
	// filling in data source sets
	For Each Source In DataSources Do
		
		// Only for the stored fact. A stored fact does not imply budget execution.
		If Source.AssumesActualData = "NotAssumed" Then
			Continue;
		EndIf;
		
		If Source.PrivilegedMode = Undefined And PrivilegedMode 
			Or Not Source.PrivilegedMode = PrivilegedMode Then
			Continue;
		EndIf;
		
		If Source.SourceType = Enums.BudgetingDataSourceTypes.Turnovers
		 Or Source.SourceType = Enums.BudgetingDataSourceTypes.Balance Then
			
			DestinationParameters = New Structure;
			DestinationParameters.Insert("DCSPlanningData",        DCSActualData);
			DestinationParameters.Insert("BasicCombinedSet", BasicCombinedSet);
			DestinationParameters.Insert("ParametersForInstallation_",      ParametersForInstallation_);
			SourceParameters = New Structure;
			SourceParameters.Insert("Source",                      Source);
			SourceParameters.Insert("ColumnStructureOfDataTable", ColumnStructureOfDataTable);
			SourceParameters.Insert("Analysts",                     Analysts);
			
			AddSubordinateSetByBudgetRegister(DestinationParameters,
			                                             SourceParameters,
			                                             GenerationMode,
			                                             DataReceiptMode,
			                                             True);
			
			AdditionalSelection = Source.AdditionalSelection;
			If AdditionalSelection <> Undefined Then
				FinancialReportingServer.CopyFilter(AdditionalSelection.Filter,
				                                            DCSActualData.DefaultSettings.Filter,
				                                            True,
				                                            ,
				                                            "_" + Source.Id);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	ExpressionOfCalculatedField =
	"CASE WHEN NOT RecordByQuantity THEN VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|	WHEN NOT UnitOfMeasureIsDeterminedByDimension THEN UnitOfMeasure
		|	ELSE
		|		CAST(BudgetReportingDisplayServer.Attachable_ValueFromAnalytics(
		|			&CacheAnalystValues,
		|			%1, 
		|			SourceFillingInUnit), ""Catalog.PackagesAndUnitsOfMeasure"")
		|	END";
	SupplementExpressionOfCalculatedFieldWithTranslationByNumber(
			ExpressionOfCalculatedField,
			"QuantityDimensionAddress",
			"Dimension",
			Undefined,
			3);
	FinReports.NewCalculatedField(DCSActualData,
	                               "UnitOfMeasure",
	                               ExpressionOfCalculatedField,,,
	                               New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	
	If ResourceFields.Property("CountReceipt") Then
		
		ExpressionOfCalculatedField = StrReplace(
			"CASE WHEN (NOT RecordByQuantity OR NOT UnitOfMeasureIsDeterminedByDimension) THEN CountReceipt
			|	ELSE &TextFillingSourceUnits
			|	END", "&TextFillingSourceUnits", TextOfFillingSourceConditionUnits("CountReceipt"));
		SupplementExpressionOfCalculatedFieldWithTranslationByNumber(
			ExpressionOfCalculatedField,
			"QuantityDimensionAddress",
			"Dimension",
			Undefined,
			3);
		FinReports.NewCalculatedField(DCSActualData,
			"CountReceipt",
			ExpressionOfCalculatedField,,,
			New TypeDescription("Number", New NumberQualifiers(15,3)));
		
	EndIf;
	
	If ResourceFields.Property("CountExpense") Then
		
		ExpressionOfCalculatedField = StrReplace(
			"CASE WHEN (NOT RecordByQuantity OR NOT UnitOfMeasureIsDeterminedByDimension) THEN CountExpense
			|	ELSE &TextFillingSourceUnits
			|	END", "&TextFillingSourceUnits", TextOfFillingSourceConditionUnits("CountExpense"));
		SupplementExpressionOfCalculatedFieldWithTranslationByNumber(
			ExpressionOfCalculatedField,
			"QuantityDimensionAddress",
			"Dimension",
			Undefined,
			3);
		FinReports.NewCalculatedField(DCSActualData,
			"CountExpense",
			ExpressionOfCalculatedField,,,
			New TypeDescription("Number", New NumberQualifiers(15,3)));
		
	EndIf;
	
	FinReports.NewCalculatedField(DCSActualData, "Currency", "StorageCurrency");
	
	If ResourceFields.Property("SumCurrReceipt") Then
		
		FinReports.NewCalculatedField(DCSActualData, "SumCurrReceipt", "GrossParishAmount");
		
	EndIf;
	
	If ResourceFields.Property("SumCurrExpense") Then
		
		FinReports.NewCalculatedField(DCSActualData, "SumCurrExpense", "AmountGrossExpense");
		
	EndIf;
	
	AddSchemaParameter(DCSActualData, "BeginOfPeriod");
	AddSchemaParameter(DCSActualData, "EndOfPeriod");
	
	AddSchemaParameter(DCSActualData, "CacheAnalystValues");
	
	// configuring the SKD
	For Each KeyAndValue In ResourceFields Do
		FinReports.NewResource(DCSActualData, KeyAndValue.Key, , "SUM(" + KeyAndValue.Key + ")");
		FinReports.NewSelectionField(DCSActualData.DefaultSettings, KeyAndValue.Key);
	EndDo;
	
	GroupingScheduledTasks = AddFieldsToSummaryTableByDescription(DCSActualData, ColumnStructureOfDataTable);
	
	If ColumnStructureOfDataTable.Periodicity_.Count() Then
		FinReports.NewDimensionField(GroupingScheduledTasks, "Period");
	EndIf;
	
	FinReports.NewDimensionField(GroupingScheduledTasks, "StorageCurrency");
	FinReports.NewDimensionField(GroupingScheduledTasks, "RatePeriod");
	
	DataCompositionClientServer.DisableOutputOfTotals(DCSActualData.DefaultSettings);
	
	Return DCSActualData;
	
EndFunction

Function AddFieldsToSummaryTableByDescription(DCS, ColumnStructureOfDataTable)
	
	CalculationMeasurements_ = New Structure;
	CalculationMeasurements_.Insert("BudgetFlowItem");
	CalculationMeasurements_.Insert("BudgetBalanceItem");
	
	For Each Dimension In ColumnStructureOfDataTable.Dimensions Do
		CalculationMeasurements_.Insert(Dimension);
	EndDo;
	
	For Each Dimension In ColumnStructureOfDataTable.DimensionKinds Do
		DimensionName = FinancialReportingCached.NameOfBudgetReportField(Dimension);
		CalculationMeasurements_.Insert(DimensionName);
	EndDo;
	
	NewGrouping = FinancialReportingServer.NewGrouping(DCS.DefaultSettings.Structure, "ID_Source1");
	
	For Each KeyAndValue In CalculationMeasurements_ Do
		FinancialReportingServer.NewDimensionField(NewGrouping, KeyAndValue.Key);
	EndDo;
	
	Return NewGrouping;
	
EndFunction

Function GetDCSTotals(DataSources, SourceFields_2, ColumnStructureOfDataTable)
	
	FinReports = FinancialReportingServer;
	DCSSummaryData = DataCompositionServer.EmptyCircuit();
	
	BasicCombinedSet = DataCompositionServer.AddEmptyDataSet(
		DCSSummaryData,
		Type("DataCompositionSchemaDataSetObject"),
		"Data");
	
	ResourceFields = New Structure;
	ResourceFields.Insert("SumOpeningBalance");
	ResourceFields.Insert("SumReceipt");
	ResourceFields.Insert("SumExpense");
	ResourceFields.Insert("SumCurrOpeningBalance");
	ResourceFields.Insert("SumCurrReceipt");
	ResourceFields.Insert("SumCurrExpense");
	ResourceFields.Insert("CountOpeningBalance");
	ResourceFields.Insert("CountReceipt");
	ResourceFields.Insert("CountExpense");
	ResourceFields.Insert("IndicatorValue");
	
	RemoveUnusedKeysFromStructure(ResourceFields, SourceFields_2);
	ResourceFields.Insert("SerialNumber"); 
	ResourceFields.Insert("Note");
	ResourceFields.Insert("NFPIndex"); 
	
	BasicCombinedSet.ObjectName = "PreliminaryCalculation";
	
	AddDataTableFieldsByDescription(BasicCombinedSet, ColumnStructureOfDataTable, ResourceFields);
	TypifyAnalyticsColumns(DCSSummaryData, ColumnStructureOfDataTable);
	
	If ThereIsEditableValue(DataSources) Then
		FinReports.NewSetField(BasicCombinedSet, "EditedValue",,,ColumnTypeOfCellStructure("EditedValue"));
	EndIf;
	
	AddResourcesAndCalculatedFields(DCSSummaryData, ColumnStructureOfDataTable, SourceFields_2, True);
	
	NewGrouping = AddFieldsToSummaryTableByDescription(DCSSummaryData, ColumnStructureOfDataTable);
	FinancialReportingServer.NewDimensionField(NewGrouping, "NonFinancialItem");
	If ResourceFields.Property("IndicatorValue") Then
		FinReports.NewResource(DCSSummaryData, "IndicatorValue",  , "MAX(IndicatorValue)");
		FinReports.NewSelectionField(DCSSummaryData.DefaultSettings, "IndicatorValue");
	EndIf;
	FinReports.NewResource(DCSSummaryData, "NFPIndex", , "MAX(NFPIndex)");
	FinReports.NewSelectionField(DCSSummaryData.DefaultSettings, "NFPIndex");
	
	Periodicity_ = Enums.Periodicity.OrderedPeriodicities(True);
	Periodicity_.Sort("Order DESC");
	
	MaximumPeriodicity = True;
	
	For Each RowOfPeriodicity In Periodicity_ Do
		
		Dimension = RowOfPeriodicity.Periodicity;
		
		If ColumnStructureOfDataTable.Periodicity_.Find(Dimension) = Undefined Then
			Continue;
		EndIf;
		
		PeriodName     = FinancialReportingClientServerCached.PeriodicityByString(Dimension);
		PeriodColumn = FinancialReportingClientServer.PeriodStrings(Dimension).Period;
		
		If MaximumPeriodicity Then
			AddGroupingResourcesByMaximumFrequency(DCSSummaryData, SourceFields_2, PeriodColumn, NewGrouping);
			MaximumPeriodicity = False;
		EndIf;
		
		NewCalculatedField = DCSSummaryData.CalculatedFields.Add();
		NewCalculatedField.DataPath = PeriodColumn;

		If Dimension = Enums.Periodicity.Week Then
			NewCalculatedField.Expression = "CASE WHEN
											|	BEGINOFPERIOD(Period, &PeriodName) < &BeginOfPeriod THEN
											|		&BeginOfPeriod
											|	ELSE
											|		BEGINOFPERIOD(Period, &PeriodName)
											|	END";
			AddSchemaParameter(DCSSummaryData, "BeginOfPeriod");
		Else
			NewCalculatedField.Expression = "BEGINOFPERIOD(Period, &PeriodName)";
		EndIf;
		NewCalculatedField.Expression = StrReplace(NewCalculatedField.Expression, "&PeriodName", """" + PeriodName + """");
		
		NewCalculatedField.ValueType = New TypeDescription("Date");
		
		GroupingPeriod_ = FinReports.NewGrouping(NewGrouping.Structure, PeriodColumn);
		FinReports.NewOrder(GroupingPeriod_, PeriodColumn);
		CurrentIndex = Periodicity_.IndexOf(RowOfPeriodicity);
		UBound = CurrentIndex - 1;
		For Cnt = 0 To UBound Do
			Dimension = Periodicity_[UBound - Cnt].Periodicity;
			If ColumnStructureOfDataTable.Periodicity_.Find(Dimension) = Undefined Then
				Continue;
			EndIf;
			PeriodColumn = FinancialReportingClientServer.PeriodStrings(Dimension).Period;
			FinReports.NewDimensionField(GroupingPeriod_, PeriodColumn);
		EndDo;
		
	EndDo;
	
	If ColumnStructureOfDataTable.Periodicity_.Count() Then
		
		MinimumPeriodicity = BudgetReportingClientServer.MinimumPeriodicity(ColumnStructureOfDataTable.Periodicity_);
		
		Order = DCSSummaryData.DefaultSettings.Order.Items.Add(Type("DataCompositionOrderItem"));
		Order.Field = New DataCompositionField(FinancialReportingClientServer.PeriodStrings(MinimumPeriodicity).Period);
		Order.OrderType = DataCompositionSortDirection.Asc;
		Order.Use = True;
		
		FinReports.SetFilter(DCSSummaryData.DefaultSettings.Filter, "Period", , DataCompositionComparisonType.Filled);
		
	EndIf;
	
	FinReports.SetOutputParameter(DCSSummaryData.DefaultSettings, "HorizontalOverallPlacement", 
																				DataCompositionTotalPlacement.None);
	FinReports.SetOutputParameter(DCSSummaryData.DefaultSettings, "VerticalOverallPlacement", 
																				DataCompositionTotalPlacement.None);
	
	Return DCSSummaryData;
	
EndFunction

Function GetDCSTotalsRevolutions(DataSources, SourceFields_2, ColumnStructureOfDataTable, ThereAreStoredRules, ThereIsPrivilegedMode)
	
	FinReports = FinancialReportingServer;
	DCSSummaryData = DataCompositionServer.EmptyCircuit();
	
	BasicCombinedSet = DataCompositionServer.AddEmptyDataSet(
		DCSSummaryData,
		Type("DataCompositionSchemaDataSetUnion"),
		"Data");
	
	ResourceFields = New Structure;
	ResourceFields.Insert("SumOpeningBalance");
	ResourceFields.Insert("SumReceipt");
	ResourceFields.Insert("SumExpense");
	ResourceFields.Insert("SumCurrOpeningBalance");
	ResourceFields.Insert("SumCurrReceipt");
	ResourceFields.Insert("SumCurrExpense");
	ResourceFields.Insert("CountOpeningBalance");
	ResourceFields.Insert("CountReceipt");
	ResourceFields.Insert("CountExpense");
	ResourceFields.Insert("IndicatorValue");
	
	RemoveUnusedKeysFromStructure(ResourceFields, SourceFields_2);
	ResourceFields.Insert("SerialNumber"); 
	ResourceFields.Insert("Note");
	
	AddDataTableFieldsByDescription(BasicCombinedSet, ColumnStructureOfDataTable, ResourceFields);
	TypifyAnalyticsColumns(DCSSummaryData, ColumnStructureOfDataTable);

	If ThereIsEditableValue(DataSources) Then
		FinReports.NewSetField(BasicCombinedSet, "EditedValue",,,ColumnTypeOfCellStructure("EditedValue"));
	EndIf;
	
	For IterationNumber = 1 To 2 Do
		
		DataKey = ?(IterationNumber = 1, "ScheduledData", "PlanDataPrivileged");
		If IterationNumber = 2 And Not ThereIsPrivilegedMode Then
			Continue;
		EndIf;
		
		ScheduledData = DataCompositionServer.AddEmptyDataSet(
			BasicCombinedSet,
			Type("DataCompositionSchemaDataSetObject"),
			DataKey);
		
		ResourceFields = New Structure;
		ResourceFields.Insert("SumReceipt");
		ResourceFields.Insert("SumExpense");
		ResourceFields.Insert("SumCurrReceipt");
		ResourceFields.Insert("SumCurrExpense");
		ResourceFields.Insert("CountReceipt");
		ResourceFields.Insert("CountExpense");
		
		RemoveUnusedKeysFromStructure(ResourceFields, SourceFields_2);
		ResourceFields.Insert("SerialNumber"); 
		ResourceFields.Insert("Note");
		AddDataTableFieldsByDescription(ScheduledData, ColumnStructureOfDataTable, ResourceFields);
		ScheduledData.ObjectName = DataKey;
		
	EndDo;

	If ThereAreStoredRules Then
	
		For IterationNumber = 1 To 2 Do
			
			DataKey = ?(IterationNumber = 1, "StoredActualData", "StoredActualDataPrivileged");
			If IterationNumber = 2 And Not ThereIsPrivilegedMode Then
				Continue;
			EndIf;
			
			StoredActualData = DataCompositionServer.AddEmptyDataSet(
				BasicCombinedSet,
				Type("DataCompositionSchemaDataSetObject"),
				DataKey);
			
			ResourceFields = New Structure;
			ResourceFields.Insert("SumReceipt");
			ResourceFields.Insert("SumExpense");
			ResourceFields.Insert("SumCurrReceipt");
			ResourceFields.Insert("SumCurrExpense");
			ResourceFields.Insert("CountReceipt");
			ResourceFields.Insert("CountExpense");
			
			RemoveUnusedKeysFromStructure(ResourceFields, SourceFields_2);
			ResourceFields.Insert("SerialNumber");
			ResourceFields.Insert("Note");
			AddDataTableFieldsByDescription(StoredActualData, ColumnStructureOfDataTable, ResourceFields);
			StoredActualData.ObjectName = DataKey;
		
		EndDo;
		
	EndIf;
	
	ActualData = DataCompositionServer.AddEmptyDataSet(
		BasicCombinedSet,
		Type("DataCompositionSchemaDataSetObject"),
		"ActualData");
	
	ResourceFields = New Structure;
	ResourceFields.Insert("SumOpeningBalance");
	ResourceFields.Insert("SumReceipt");
	ResourceFields.Insert("SumExpense");
	ResourceFields.Insert("SumCurrOpeningBalance");
	ResourceFields.Insert("SumCurrReceipt");
	ResourceFields.Insert("SumCurrExpense");
	ResourceFields.Insert("CountOpeningBalance");
	ResourceFields.Insert("CountReceipt");
	ResourceFields.Insert("CountExpense");
	ResourceFields.Insert("IndicatorValue");
	
	RemoveUnusedKeysFromStructure(ResourceFields, SourceFields_2);
	ResourceFields.Insert("NFPIndex"); 
	
	AddDataTableFieldsByDescription(ActualData, ColumnStructureOfDataTable, ResourceFields);
	ActualData.ObjectName = "ActualData";
	
	AddResourcesAndCalculatedFields(DCSSummaryData, ColumnStructureOfDataTable, SourceFields_2, False);
	
	NewGrouping = AddFieldsToSummaryTableByDescription(DCSSummaryData, ColumnStructureOfDataTable);
	FinancialReportingServer.NewDimensionField(NewGrouping, "NonFinancialItem");
	If ResourceFields.Property("IndicatorValue") Then
		FinReports.NewResource(DCSSummaryData, "IndicatorValue",  , "MAX(IndicatorValue)");
		FinReports.NewSelectionField(DCSSummaryData.DefaultSettings, "IndicatorValue");
	EndIf;
	FinReports.NewResource(DCSSummaryData, "NFPIndex", , "MAX(NFPIndex)");
	FinReports.NewSelectionField(DCSSummaryData.DefaultSettings, "NFPIndex");
	
	Periodicity_ = Enums.Periodicity.OrderedPeriodicities(True);
	Periodicity_.Sort("Order DESC");
	
	For Each RowOfPeriodicity In Periodicity_ Do
		
		Dimension = RowOfPeriodicity.Periodicity;
		
		If ColumnStructureOfDataTable.Periodicity_.Find(Dimension) = Undefined Then
			Continue;
		EndIf;
		
		PeriodName    = FinancialReportingClientServerCached.PeriodicityByString(Dimension);
		ColumnPeriod = FinancialReportingClientServer.PeriodStrings(Dimension).Period;
		
		NewCalculatedField = DCSSummaryData.CalculatedFields.Add();
		NewCalculatedField.DataPath = ColumnPeriod;
		If Dimension = Enums.Periodicity.Week Then
			NewCalculatedField.Expression = "CASE WHEN
											|	BEGINOFPERIOD(Period, &PeriodName) < &BeginOfPeriod THEN
											|		&BeginOfPeriod
											|	ELSE
											|		BEGINOFPERIOD(Period, &PeriodName)
											|	END";
			AddSchemaParameter(DCSSummaryData, "BeginOfPeriod");
		Else
			NewCalculatedField.Expression = "BEGINOFPERIOD(Period, &PeriodName)";
		EndIf;
		NewCalculatedField.Expression = StrReplace(NewCalculatedField.Expression, "&PeriodName", """" + PeriodName + """");
		
		NewCalculatedField.ValueType = New TypeDescription("Date");
		
		GroupingPeriod_ = FinReports.NewGrouping(NewGrouping.Structure, ColumnPeriod);
		FinReports.NewOrder(GroupingPeriod_, ColumnPeriod);
		CurrentIndex = Periodicity_.IndexOf(RowOfPeriodicity);
		UBound = CurrentIndex - 1;
		For Cnt = 0 To UBound Do
			Dimension = Periodicity_[UBound - Cnt].Periodicity;
			If ColumnStructureOfDataTable.Periodicity_.Find(Dimension) = Undefined Then
				Continue;
			EndIf;
			ColumnPeriod = FinancialReportingClientServer.PeriodStrings(Dimension).Period;
			FinReports.NewDimensionField(GroupingPeriod_, ColumnPeriod);
		EndDo;
		
	EndDo;
	
	If ColumnStructureOfDataTable.Periodicity_.Count() Then
		FinReports.SetFilter(DCSSummaryData.DefaultSettings.Filter, "Period", , DataCompositionComparisonType.Filled);
	EndIf;
	
	FinReports.SetOutputParameter(DCSSummaryData.DefaultSettings, "HorizontalOverallPlacement", 
																				DataCompositionTotalPlacement.None);
	FinReports.SetOutputParameter(DCSSummaryData.DefaultSettings, "VerticalOverallPlacement", 
																				DataCompositionTotalPlacement.None);
	
	Return DCSSummaryData;
	
EndFunction

Function GetDCSPreliminaryFinalCalculation(DataSources, SourceFields_2, ColumnStructureOfDataTable, ThereAreStoredRules, ThereIsPrivilegedMode)
	
	FinReports = FinancialReportingServer;
	DCSSummaryData = DataCompositionServer.EmptyCircuit();
	
	BasicCombinedSet = DataCompositionServer.AddEmptyDataSet(
		DCSSummaryData,
		Type("DataCompositionSchemaDataSetUnion"),
		"Data");
	
	ResourceFields = New Structure;
	ResourceFields.Insert("SumOpeningBalance");
	ResourceFields.Insert("SumReceipt");
	ResourceFields.Insert("SumExpense");
	ResourceFields.Insert("SumCurrOpeningBalance");
	ResourceFields.Insert("SumCurrReceipt");
	ResourceFields.Insert("SumCurrExpense");
	ResourceFields.Insert("CountOpeningBalance");
	ResourceFields.Insert("CountReceipt");
	ResourceFields.Insert("CountExpense");
	ResourceFields.Insert("IndicatorValue");
	
	RemoveUnusedKeysFromStructure(ResourceFields, SourceFields_2);
	ResourceFields.Insert("SerialNumber");
	ResourceFields.Insert("Note");
	
	AddDataTableFieldsByDescription(BasicCombinedSet, ColumnStructureOfDataTable, ResourceFields);
	If ThereIsEditableValue(DataSources) Then
		FinReports.NewSetField(BasicCombinedSet, "EditedValue",,,ColumnTypeOfCellStructure("EditedValue"));
	EndIf;
	
	For IterationNumber = 1 To 2 Do
		
		DataKey = ?(IterationNumber = 1, "ScheduledData", "PlanDataPrivileged");
		If IterationNumber = 2 And Not ThereIsPrivilegedMode Then
			Continue;
		EndIf;
		
		ScheduledData = DataCompositionServer.AddEmptyDataSet(
			BasicCombinedSet,
			Type("DataCompositionSchemaDataSetObject"),
			DataKey);
		
		ResourceFields = New Structure;
		ResourceFields.Insert("SumOpeningBalance");
		ResourceFields.Insert("SumReceipt");
		ResourceFields.Insert("SumExpense");
		ResourceFields.Insert("SumCurrOpeningBalance");
		ResourceFields.Insert("SumCurrReceipt");
		ResourceFields.Insert("SumCurrExpense");
		ResourceFields.Insert("CountOpeningBalance");
		ResourceFields.Insert("CountReceipt");
		ResourceFields.Insert("CountExpense");
		
		RemoveUnusedKeysFromStructure(ResourceFields, SourceFields_2);
		ResourceFields.Insert("SerialNumber"); 
		ResourceFields.Insert("Note");
		
		AddDataTableFieldsByDescription(ScheduledData, ColumnStructureOfDataTable, ResourceFields);
		ScheduledData.ObjectName = DataKey;
		
	EndDo;
	
	If ThereAreStoredRules Then
		
		For IterationNumber = 1 To 2 Do
			
			DataKey = ?(IterationNumber = 1, "StoredActualData", "StoredActualDataPrivileged");
			If IterationNumber = 2 And Not ThereIsPrivilegedMode Then
				Continue;
			EndIf;
			
			StoredActualData = DataCompositionServer.AddEmptyDataSet(
				BasicCombinedSet,
				Type("DataCompositionSchemaDataSetObject"),
				DataKey);
			
			ResourceFields = New Structure;
			ResourceFields.Insert("SumReceipt");
			ResourceFields.Insert("SumExpense");
			ResourceFields.Insert("SumCurrReceipt");
			ResourceFields.Insert("SumCurrExpense");
			ResourceFields.Insert("CountReceipt");
			ResourceFields.Insert("CountExpense");
			
			RemoveUnusedKeysFromStructure(ResourceFields, SourceFields_2);
			ResourceFields.Insert("SerialNumber");
			ResourceFields.Insert("Note");
			
			AddDataTableFieldsByDescription(StoredActualData, ColumnStructureOfDataTable, ResourceFields);
			StoredActualData.ObjectName = DataKey;
		
		EndDo;
		
	EndIf;
	
	ActualData = DataCompositionServer.AddEmptyDataSet(
		BasicCombinedSet,
		Type("DataCompositionSchemaDataSetObject"),
		"ActualData");
	
	ResourceFields = New Structure;
	ResourceFields.Insert("SumOpeningBalance");
	ResourceFields.Insert("SumReceipt");
	ResourceFields.Insert("SumExpense");
	ResourceFields.Insert("SumCurrOpeningBalance");
	ResourceFields.Insert("SumCurrReceipt");
	ResourceFields.Insert("SumCurrExpense");
	ResourceFields.Insert("CountOpeningBalance");
	ResourceFields.Insert("CountReceipt");
	ResourceFields.Insert("CountExpense");
	ResourceFields.Insert("IndicatorValue");
	
	RemoveUnusedKeysFromStructure(ResourceFields, SourceFields_2);
	ResourceFields.Insert("SerialNumber"); 
	ResourceFields.Insert("Note");
	ResourceFields.Insert("NFPIndex"); 
	
	AddDataTableFieldsByDescription(ActualData, ColumnStructureOfDataTable, ResourceFields);
	ActualData.ObjectName = "ActualData";
	
	AddResourcesAndCalculatedFields(DCSSummaryData, Undefined, SourceFields_2, False);
	
	NewGrouping = AddFieldsToSummaryTableByDescription(DCSSummaryData, ColumnStructureOfDataTable);
	FinancialReportingServer.NewDimensionField(NewGrouping, "NonFinancialItem");
	If ResourceFields.Property("IndicatorValue") Then
		FinReports.NewResource(DCSSummaryData, "IndicatorValue",  , "MAX(IndicatorValue)");
		FinReports.NewSelectionField(DCSSummaryData.DefaultSettings, "IndicatorValue");
	EndIf;
	FinReports.NewResource(DCSSummaryData, "NFPIndex", , "MAX(NFPIndex)");
	FinReports.NewSelectionField(DCSSummaryData.DefaultSettings, "NFPIndex");
	
	If ColumnStructureOfDataTable.Periodicity_.Count() Then
		
		MinimumPeriodicity = BudgetReportingClientServer.MinimumPeriodicity(ColumnStructureOfDataTable.Periodicity_);
		PeriodName = FinancialReportingClientServerCached.PeriodicityByString(MinimumPeriodicity);
		
		GroupingPeriod = FinReports.NewGrouping(NewGrouping.Structure, "Period");
		NewField = GroupingPeriod.GroupFields.Items[0];
		NewField.AdditionType = DataCompositionPeriodAdditionType[PeriodName];
		NewField.BeginOfPeriod = New DataCompositionField("DataParameters.BeginOfPeriod");
		NewField.EndOfPeriod 	= New DataCompositionField("DataParameters.EndOfPeriod");
		
		AddSchemaParameter(DCSSummaryData, "BeginOfPeriod");
		AddSchemaParameter(DCSSummaryData, "EndOfPeriod");
		
		Order = DCSSummaryData.DefaultSettings.Order.Items.Add(Type("DataCompositionOrderItem"));
		Order.Field = New DataCompositionField("Period");
		Order.OrderType = DataCompositionSortDirection.Asc;
		Order.Use = True;
		
	EndIf;
	
	FinReports.SetOutputParameter(DCSSummaryData.DefaultSettings, "HorizontalOverallPlacement", 
																				DataCompositionTotalPlacement.None);
	FinReports.SetOutputParameter(DCSSummaryData.DefaultSettings, "VerticalOverallPlacement", 
																				DataCompositionTotalPlacement.None);
	
	Return DCSSummaryData;
	
EndFunction

// LongDesc
// 
// Parameters:
// 	DataSources - Array of See NewSource -
// 	SourceFields_2 - ValueTable -
// 	ColumnStructureOfDataTable - Arbitrary, Boolean, Structure, Undefined - LongDesc:
// * DimensionKinds - Array -
// * Dimensions - Array -
// * Periodicity_ - Array -
// 	Analysts - Array -
// 	HeaderDimensions - Array -
// 	ParametersForInstallation_ - Structure -
// 	DCSSummaryData - DataCompositionSchema -
// Returns:
// 	Structure - LongDesc
Function GetDocumentDCS(DataSources, SourceFields_2, ColumnStructureOfDataTable, 
												Analysts, HeaderDimensions, ParametersForInstallation_, DCSSummaryData)
	
	SourcesTypes = Enums.BudgetingDataSourceTypes;
	
	FinReports = FinancialReportingServer;
	DCSDocumentData = New Structure;
	
	// The document data consists of many SCDs, the results of which should be combined into a final one.
	For Each Source In DataSources Do
		
		If Source.SourceType = SourcesTypes.NonFinancial Then
			// the data of the document is supplemented by the sources of balances and turnover
			Continue;
		EndIf;
		
		If Source.SourceType = SourcesTypes.EditedValue Then
			DCSDocumentBySource = GetDCsOfDocumentValues(Source,
					ColumnStructureOfDataTable,
					Analysts,
					HeaderDimensions,
					ParametersForInstallation_);
		Else
			DCSDocumentBySource = GetDocumentDataDCS(Source,
					ColumnStructureOfDataTable,
					Analysts,
					HeaderDimensions,
					ParametersForInstallation_);
		EndIf;
		
		Name = "DocumentData_" + Source.Id;
		DCSDocumentData.Insert(Name, DCSDocumentBySource);
		
		SubordinatedSet = Undefined;
		If Name = "DocumentData_Document" Then
			// The sources of articles and targets are divided into separate sources. A set of "Data documents_The document" should be one.
			DataSetAssociation = DCSSummaryData.DataSets[0]; // DataCompositionTemplateDataSetUnion
			SubordinatedSet = DataSetAssociation.Items.Find(Name);
		EndIf;
		If SubordinatedSet = Undefined Then
			SubordinatedSet = DataCompositionServer.AddEmptyDataSet(
				DCSSummaryData.DataSets[0],
				Type("DataCompositionSchemaDataSetObject"),
				Name);
		EndIf;
		
		ResourceFields = New Structure;
		ResourceFields.Insert("SumReceipt");
		ResourceFields.Insert("SumExpense");
		ResourceFields.Insert("SumCurrReceipt");
		ResourceFields.Insert("SumCurrExpense");
		ResourceFields.Insert("CountReceipt");
		ResourceFields.Insert("CountExpense");
		ResourceFields.Insert("IndicatorValue");
		
		RemoveUnusedKeysFromStructure(ResourceFields, SourceFields_2);
		ResourceFields.Insert("SerialNumber"); ResourceFields.Insert("Note"); ResourceFields.Insert("AlwaysOutputFlag");
		
		AddDataTableFieldsByDescription(SubordinatedSet, ColumnStructureOfDataTable, ResourceFields);
		If Source.SourceType = SourcesTypes.EditedValue Then
			FinReports.NewSetField(SubordinatedSet, "EditedValue");
		EndIf;
		
		SubordinatedSet.ObjectName = Name;
		
	EndDo;
	
	FinReports.NewResource(DCSSummaryData, "AlwaysOutputFlag");
	FinReports.NewSelectionField(DCSSummaryData.DefaultSettings, "AlwaysOutputFlag");
	
	Return DCSDocumentData;
	
EndFunction

Function GetDocumentDataDCS(Source, ColumnStructureOfDataTable, Analysts, HeaderDimensions, ParametersForInstallation_)
	
	FinReports = FinancialReportingServer;
	DCS = DataCompositionServer.EmptyCircuit();
	
	DocumentDataSet = DataCompositionServer.AddEmptyDataSet(DCS,
		Type("DataCompositionSchemaDataSetQuery"), "BudgetEntryFormInstance_Data");
	DocumentDataSet.Query = 
	"SELECT
	|	BudgetFlowItemsDimension.BudgetFlowItem AS BudgetFlowItem,
	|	&Document_Scenario AS Scenario,
	|	&Status AS Status,
	|	&Document_Organization AS Organization,
	|	&Document_Department AS Department,
	|	&TextOfDimensionsFields,
	|	BudgetFlowItemsDimension.Currency AS Currency,
	|	&TextOfLinkSettingsFields,
	|	&TextOfArticleParameterFields,
	|	BEGINOFPERIOD(&UpdateDate, DAY) AS DayPeriod,
	|	BudgetFlowItemTurnovers.PlanningPeriod AS PlanningPeriod,
	|	BudgetFlowItemTurnovers.SerialNumber AS SerialNumber,
	|	BudgetFlowItemTurnovers.Note AS Note,
	|	BudgetFlowItemTurnovers.Sum AS Sum,
	|	BudgetFlowItemTurnovers.AmountInCurrency AS AmountInCurrency,
	|	BudgetFlowItemTurnovers.Count AS Count
	|FROM
	|	BudgetFlowItemsDimension AS BudgetFlowItemsDimension
	|		INNER JOIN BudgetFlowItemTurnovers AS BudgetFlowItemTurnovers
	|		ON BudgetFlowItemsDimension.RowID = BudgetFlowItemTurnovers.RowID";
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	ArrayOfAnalystFields = New Array;
	For Cnt = 1 To MaximumNumberOfAnalysts Do
		ArrayOfAnalystFields.Add(StringFunctionsClientServer.SubstituteParametersToString(
			"BudgetFlowItemsDimension.Dimension%1 AS Dimension%1", Cnt)); //@ query-part
	EndDo;
	TextOfDimensionsFields = StrConcat(ArrayOfAnalystFields, "," + Chars.LF + Chars.Tab);
	DocumentDataSet.Query = StrReplace(DocumentDataSet.Query, "&TextOfDimensionsFields", TextOfDimensionsFields);
	
	ThereAreTypesOfProducts = 
		ColumnStructureOfDataTable.DimensionKinds.Count()
		Or ColumnStructureOfDataTable.Dimensions.Find("UnitOfMeasure") <> Undefined;
		
	If Not ThereAreTypesOfProducts Then
		
		For Each Dimension In Analysts Do
			NameOfAnalytics = FinancialReportingCached.NameOfBudgetReportField(Dimension);
			If FindSelectionByName(Source.AdditionalSelection, NameOfAnalytics,, True) Then
				ThereAreTypesOfProducts = True;
				Break;
			EndIf;
		EndDo;
		
	EndIf;
	
	TextOfArticleParameterFields = "";
	TextOfLinkSettingsFields = "";
	
	If ThereAreTypesOfProducts Then
	
		DocumentDataSet.Query = DocumentDataSet.Query + "
		|	LEFT JOIN ItemParameterCache AS ItemParameterCache
		|	ON BudgetFlowItemsDimension.BudgetFlowItem = ItemParameterCache.BudgetFlowItem"; // @query-part
		
		ArticleParameterFields = New Array;
		ArticleParameterFields.Add("ItemParameterCache.NumberOfUsedDimensions");
		For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
			ArticleParameterFields.Add(StringFunctionsClientServer.SubstituteParametersToString(
				"ItemParameterCache.DimensionKind%1", DimensionNumber));
		EndDo;
		ArticleParameterFields.Add("ItemParameterCache.Article2ByQuantity");
		ArticleParameterFields.Add("ItemParameterCache.ArticleUnitOfMeasurementIsDeterminedByAnalytics");
		ArticleParameterFields.Add("ItemParameterCache.ArticleAddressAndQuantity");
		ArticleParameterFields.Add("ItemParameterCache.ArticleSourceFillingInUnitOfMeasurement");
		ArticleParameterFields.Add("ItemParameterCache.ArticleUnitOfMeasurement");
		TextOfArticleParameterFields = StrConcat(ArticleParameterFields, "," + Chars.LF + Chars.Tab);
		DocumentDataSet.Query = StrReplace(DocumentDataSet.Query, "&TextOfArticleParameterFields",
			TextOfArticleParameterFields);
		
		For Each Field In ArticleParameterFields Do
			FinReports.NewSetField(DocumentDataSet, Mid(Field, StrFind(Field, ".") + 1));
		EndDo;
		
	Else
		
		DocumentDataSet.Query = StrReplace(DocumentDataSet.Query, "&TextOfArticleParameterFields,", "");
		
	EndIf;
	
	If Source.SourceType = Enums.BudgetingDataSourceTypes.Balance Then
		
		DocumentDataSet.Query = DocumentDataSet.Query + "
		|	LEFT JOIN RelationshipSettings AS RelationshipSettings
		|	ON BudgetFlowItemsDimension.BudgetFlowItem = RelationshipSettings.BudgetFlowItem"; // @query-part
		
		LinkSettingsFields = New Array;
		LinkSettingsFields.Add("RelationshipSettings.BudgetBalanceItem");
		LinkSettingsFields.Add("RelationshipSettings.IndicatorNumberOfAnalyticsUsed");
		For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
			LinkSettingsFields.Add(StringFunctionsClientServer.SubstituteParametersToString(
				"RelationshipSettings.IndicatorTypeOfAnalytics%1", DimensionNumber));
		EndDo;
		LinkSettingsFields.Add("RelationshipSettings.RecordByCurrency");
		LinkSettingsFields.Add("RelationshipSettings.DimensionAddressCurrency");
		LinkSettingsFields.Add("RelationshipSettings.CurrencyPopulationSource");
		LinkSettingsFields.Add("RelationshipSettings.CurrencyIsDeterminedByDimension");
		LinkSettingsFields.Add("RelationshipSettings.IndicatorIsTakenIntoAccountByQuantity");
		LinkSettingsFields.Add("RelationshipSettings.IndicatorUnitOfMeasurementIsDeterminedByAnalytics");
		LinkSettingsFields.Add("RelationshipSettings.AnalyticsAddressQuantityIndicator");
		LinkSettingsFields.Add("RelationshipSettings.IndicatorSourceFillingInUnitOfMeasurement");
		LinkSettingsFields.Add("RelationshipSettings.IndicatorUnitOfMeasurement");
		TextOfLinkSettingsFields = StrConcat(LinkSettingsFields, "," + Chars.LF + Chars.Tab);
		DocumentDataSet.Query = StrReplace(DocumentDataSet.Query, "&TextOfLinkSettingsFields",
			TextOfLinkSettingsFields);
		
		For Each Field In LinkSettingsFields Do
			FinReports.NewSetField(DocumentDataSet, Mid(Field, StrFind(Field, ".") + 1));
		EndDo;
		
		DocumentDataSet.Query = RequestSchemes.SetRoomToTemporaryTable(DocumentDataSet.Query,
			"DocumentData");
		DocumentDataSet.Query = RequestSchemes.SetIndexingOfQueryFields(DocumentDataSet.Query,
			"BudgetFlowItem,BudgetBalanceItem");
		
		CalculationsRules = Source.CalculationsRules;
		RequestAccordingToCalculationRules = BudgetingServer.GenerateRequestToDataSourceAccordingToCalculationRules(CalculationsRules,
			"Document");
		QueryText = RequestAccordingToCalculationRules.QueryText;
		If IsBlankString(QueryText) Then
			QueryText = StrReplace(BudgetingServer.GetQueryTextToSourceOfIndicatorDataWithoutCalculationRules(),
				"&ConditionText", "TRUE");
			TableDetails = RequestSchemes.TableDetails(Type("QuerySchemaTempTableDescription"), "DocumentData",
				"AliasOfSourceTable", "BudgetFlowItem,BudgetBalanceItem", QueryText);
			IConnectionShort = RequestSchemes.IConnectionShort(TableDetails,
				"CalculationsRules.Source = AliasOfSourceTable.BudgetFlowItem
				|	AND CalculationsRules.Receiver = AliasOfSourceTable.BudgetBalanceItem",
			QuerySchemaJoinType.LeftOuter);
			QueryText = RequestSchemes.AddConnectionToRequest(QueryText, "CalculationsRules", IConnectionShort);
		EndIf;
		QueryText = StrReplace(QueryText, "ScenarioAmountTurnover", "Sum");
		QueryText = StrReplace(QueryText, "AmountInCurrencyTurnover", "AmountInCurrency");
		QueryText = StrReplace(QueryText, "CountTurnover", "Count");
		
		If Not IsBlankString(TextOfArticleParameterFields) Then
			TextOfArticleParameterFields = StrReplace(TextOfArticleParameterFields, "ItemParameterCache", "AliasOfSourceTable");
		EndIf;
		TextOfLinkSettingsFields = StrReplace(TextOfLinkSettingsFields, "RelationshipSettings", "AliasOfSourceTable");
		QueryText = StrReplace(QueryText, Chars.LF + "FROM", ?(IsBlankString(TextOfArticleParameterFields), "", "," // @query-part
			+ Chars.LF + Chars.Tab + TextOfArticleParameterFields) + "," + Chars.LF + Chars.Tab + TextOfLinkSettingsFields
			+ Chars.LF + "FROM"); // @query-part
		
		FieldsToDelete_ = New Array;
		FieldsToDelete_.Add("SumManTurnover");
		FieldsToDelete_.Add("SumComplTurnover");
		For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
			FieldsToDelete_.Add(StringFunctionsClientServer.SubstituteParametersToString("Dimension%1Source1",
				DimensionNumber));
		EndDo;
		QueryText = RequestSchemes.RemoveFieldsFromRequest(QueryText, FieldsToDelete_);
		
		DocumentDataSet.Query = DocumentDataSet.Query + Common.QueryBatchSeparator()
			+ QueryText;
		
		For Each QueryParameter In RequestAccordingToCalculationRules.QueryOptions Do
			DataCompositionServer.AddParameter(DCS, QueryParameter.Key, , QueryParameter.Value, True, True);
		EndDo;
		
		FinReports.SetFilter(DCS.DefaultSettings.Filter, "BudgetBalanceItem", , DataCompositionComparisonType.Filled);
		
		FinReports.NewSetField(DocumentDataSet, "Expense");
		FinReports.NewSetField(DocumentDataSet, "Currency", "StorageCurrency");
		
	Else
		
		DocumentDataSet.Query = StrReplace(DocumentDataSet.Query, "&TextOfLinkSettingsFields,", "");
		
		FinReports.NewSetField(DocumentDataSet, "Currency");
		
	EndIf;
	
	FinReports.NewSetField(DocumentDataSet, "RowID");
	FinReports.NewSetField(DocumentDataSet, "BudgetFlowItem", , , ColumnTypeOfCellStructure("BudgetFlowItem"));
	FinReports.NewSetField(DocumentDataSet, "Status", , , New TypeDescription("EnumRef.PlanStatuses"));
	FinReports.NewSetField(DocumentDataSet, "Scenario", , , ColumnTypeOfCellStructure("Scenario"));
	FinReports.NewSetField(DocumentDataSet, "Organization", , , ColumnTypeOfCellStructure("Organization"));
	FinReports.NewSetField(DocumentDataSet, "Department", , , ColumnTypeOfCellStructure("Department"));
	For Cnt = 1 To MaximumNumberOfAnalysts Do
		FinReports.NewSetField(DocumentDataSet, "Dimension" + Cnt, , , ColumnTypeOfCellStructure("Dimension"));
	EndDo;
	FinReports.NewSetField(DocumentDataSet, "PlanningPeriod", , , New TypeDescription("Date"));
	FinReports.NewSetField(DocumentDataSet, "DayPeriod", , , New TypeDescription("Date"));
	FinReports.NewSetField(DocumentDataSet, "SerialNumber");
	FinReports.NewSetField(DocumentDataSet, "Note");
	FinReports.NewSetField(DocumentDataSet, "Count");
	FinReports.NewSetField(DocumentDataSet, "Sum");
	FinReports.NewSetField(DocumentDataSet, "AmountInCurrency");
	
	If Source.SourceType = Enums.BudgetingDataSourceTypes.Balance Then
		
		FinReports.NewCalculatedField(DCS, "CountReceipt", "CASE WHEN NOT Expense THEN Count ELSE 0 END");
		FinReports.NewCalculatedField(DCS, "CountExpense", "CASE WHEN Expense THEN Count ELSE 0 END");
		
		FinReports.NewCalculatedField(DCS, "SumReceipt", "CASE WHEN NOT Expense THEN Sum ELSE 0 END");
		FinReports.NewCalculatedField(DCS, "SumExpense", "CASE WHEN Expense THEN Sum ELSE 0 END");
		
		TextsAnalyst = New Map;
		
		For Cnt = 1 To MaximumNumberOfAnalysts Do
			AnalyticsText = StringFunctionsClientServer.SubstituteParametersToString("Dimension%1", Cnt);
			FinReports.NewCalculatedField(DCS, AnalyticsText, AnalyticsText);
			TextsAnalyst.Insert(Cnt, AnalyticsText);
		EndDo;
		
		// The calculated Unit of measurement field.
		ExpressionOfCalculatedField =
		"CASE WHEN NOT IndicatorIsTakenIntoAccountByQuantity THEN VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|	WHEN NOT IndicatorUnitOfMeasurementIsDeterminedByAnalytics THEN IndicatorUnitOfMeasurement
		|	ELSE
		|		CAST(BudgetReportingDisplayServer.Attachable_ValueFromAnalytics(
		|			&CacheAnalystValues,
		|			%1,
		|			IndicatorSourceFillingInUnitOfMeasurement), ""Catalog.PackagesAndUnitsOfMeasure"")
		|	END";
		
		SupplementExpressionOfCalculatedFieldWithTranslationByNumber(
			ExpressionOfCalculatedField,
			"AnalyticsAddressQuantityIndicator",
			"",
			TextsAnalyst,
			3);
		
		FinReports.NewCalculatedField(DCS,
		                               "UnitOfMeasure",
		                               ExpressionOfCalculatedField,,,
		                               New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
		
		// The calculated Currency field.
		ExpressionOfCalculatedField =
		"CASE WHEN NOT RecordByCurrency OR NOT CurrencyIsDeterminedByDimension THEN StorageCurrency
		|	ELSE
		|		CAST(BudgetReportingDisplayServer.Attachable_ValueFromAnalytics(
		|			&CacheAnalystValues,
		|			%1,
		|			CurrencyPopulationSource,
		|			StorageCurrency), ""Catalog.Currencies"")
		|	END";
		
		SupplementExpressionOfCalculatedFieldWithTranslationByNumber(
			ExpressionOfCalculatedField,
			"DimensionAddressCurrency",
			"",
			TextsAnalyst,
			3);
		
		FinReports.NewCalculatedField(DCS,
		                               "Currency",
		                               ExpressionOfCalculatedField,,,
		                               New TypeDescription("CatalogRef.Currencies"));
		
		MoneyType = TMCommonUse.MoneyFieldTypeDescription();
		TypeBitDepth = MoneyType.NumberQualifiers.Digits;
		TypeBitFraction = MoneyType.NumberQualifiers.FractionDigits;
		
		// The calculated field totals the input.
		ExpressionOfCalculatedField =
		"CASE WHEN NOT Expense THEN
		|	CASE WHEN NOT RecordByCurrency OR NOT CurrencyIsDeterminedByDimension THEN AmountInCurrency
		|	ELSE
		|		CAST(BudgetReportingDisplayServer.Attachable_ConvertAtRate(
		|								AmountInCurrency,
		|								PlanningPeriod,
		|								StorageCurrency,
		|								&Document_Scenario,
		|								&CacheOfScheduledCourses,
		|								&CacheAnalystValues,
		|								%1,
		|								CurrencyPopulationSource), ""Number(%TypeBitDepth, %TypeOfCutPart)"")
		|	END
		|END";
		
		ExpressionOfCalculatedField = StrReplace(ExpressionOfCalculatedField,
				"%TypeBitDepth",
				Format(TypeBitDepth, "NZ=0; NG=0;"));
		ExpressionOfCalculatedField = StrReplace(ExpressionOfCalculatedField,
				"%TypeOfCutPart",
				Format(TypeBitFraction, "NZ=0; NG=0;"));
		SupplementExpressionOfCalculatedFieldWithTranslationByNumber(
			ExpressionOfCalculatedField,
			"DimensionAddressCurrency",
			"",
			TextsAnalyst,
			8);
		
		FinReports.NewCalculatedField(DCS,
		                               "SumCurrReceipt",
		                               ExpressionOfCalculatedField,,,
		                               MoneyType);
		
		// The calculated field totals the expense.
		ExpressionOfCalculatedField =
		"CASE WHEN Expense THEN 
		|	CASE WHEN NOT RecordByCurrency OR NOT CurrencyIsDeterminedByDimension THEN AmountInCurrency
		|	ELSE
		|		CAST(BudgetReportingDisplayServer.Attachable_ConvertAtRate(
		|								AmountInCurrency
		|								PlanningPeriod,
		|								StorageCurrency,
		|								&Document_Scenario,
		|								&CacheOfScheduledCourses,
		|								&CacheAnalystValues,
		|								%1,
		|								CurrencyPopulationSource), ""Number(%TypeBitDepth, %TypeOfCutPart)"")
		|	END
		|END";
		
		ExpressionOfCalculatedField = StrReplace(ExpressionOfCalculatedField,
				"%TypeBitDepth",
				Format(TypeBitDepth, "NZ=0; NG=0;"));
		ExpressionOfCalculatedField = StrReplace(ExpressionOfCalculatedField,
				"%TypeOfCutPart",
				Format(TypeBitFraction, "NZ=0; NG=0;"));
		SupplementExpressionOfCalculatedFieldWithTranslationByNumber(
			ExpressionOfCalculatedField,
			"DimensionAddressCurrency",
			"",
			TextsAnalyst,
			8);
		
		FinReports.NewCalculatedField(DCS,
		                               "SumCurrExpense",
		                               ExpressionOfCalculatedField,,,
		                               MoneyType);
		
		AddSchemaParameter(DCS, "CacheOfScheduledCourses");
		AddSchemaParameter(DCS, "CacheAnalystValues");
		
	Else
		
		ExpressionOfCalculatedField =
		"CASE WHEN NOT Article2ByQuantity THEN VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|	WHEN NOT ArticleUnitOfMeasurementIsDeterminedByAnalytics THEN ArticleUnitOfMeasurement
		|	ELSE
		|		CAST(BudgetReportingDisplayServer.Attachable_ValueFromAnalytics(
		|			&CacheAnalystValues, 
		|			%1, 
		|			ArticleSourceFillingInUnitOfMeasurement), ""Catalog.PackagesAndUnitsOfMeasure"")
		|	END";
		
		SupplementExpressionOfCalculatedFieldWithTranslationByNumber(
			ExpressionOfCalculatedField,
			"ArticleAddressAndQuantity",
			"Dimension",
			Undefined,
			3);
			
		FinReports.NewCalculatedField(DCS,
		                               "UnitOfMeasure",
		                               ExpressionOfCalculatedField,,,
		                               New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
		
		AddSchemaParameter(DCS, "CacheAnalystValues");
		
		FinReports.NewCalculatedField(DCS, "SumReceipt", "Sum");
		FinReports.NewCalculatedField(DCS, "SumExpense", "0");
		FinReports.NewCalculatedField(DCS, "SumCurrReceipt", "AmountInCurrency");
		FinReports.NewCalculatedField(DCS, "SumCurrExpense", "0");
		FinReports.NewCalculatedField(DCS, "CountReceipt", "Count");
		FinReports.NewCalculatedField(DCS, "CountExpense", "0");
		
	EndIf;
	
	NewCalculatedField = DCS.CalculatedFields.Add();
	NewCalculatedField.DataPath = "ID_Source1";
	NewCalculatedField.Expression = """" + Source.Id + """";
	
	If Source.SourceType = Enums.BudgetingDataSourceTypes.Turnovers
	 Or Source.SourceType = Enums.BudgetingDataSourceTypes.Balance Then
		NewCalculatedField = DCS.CalculatedFields.Add();
		NewCalculatedField.DataPath = "DocumentData";
		NewCalculatedField.Expression = "TRUE";
	EndIf;
	
	Group = FinReports.NewGrouping(DCS.DefaultSettings.Structure, "ID_Source1");
	If Source.SourceType = Enums.BudgetingDataSourceTypes.Balance Then
		FinReports.NewDimensionField(Group, "BudgetBalanceItem");
	EndIf;
	FinReports.NewDimensionField(Group, "BudgetFlowItem");
	
	If Source.SourceType = Enums.BudgetingDataSourceTypes.Turnovers
	 Or Source.SourceType = Enums.BudgetingDataSourceTypes.Balance Then
		FinReports.NewDimensionField(Group, "DocumentData");
	EndIf;
	
	For Each Var_929_Dimension In ColumnStructureOfDataTable.Dimensions Do
		
		If Not StrFind(Var_929_Dimension, "Dimension")
			And Not Var_929_Dimension = "Currency"
			And Not Var_929_Dimension = "UnitOfMeasure" Then
			
			NewCalculatedField = DCS.CalculatedFields.Add();
			NewCalculatedField.DataPath = Var_929_Dimension;
			NewCalculatedField.Expression = "&Document_" + Var_929_Dimension;
			AddSchemaParameter(DCS, "Document_" + Var_929_Dimension);
			
		EndIf;
		
		FinReports.NewDimensionField(Group, Var_929_Dimension);
		
	EndDo;
	
	For Each DimensionKind In ColumnStructureOfDataTable.DimensionKinds Do
		
		FieldName = FinancialReportingCached.NameOfBudgetReportField(DimensionKind);
		NameOfAnalyticsViewParameter_ = "DimensionKind" + FieldName;
		
		If HeaderDimensions.Find(DimensionKind) = Undefined Then
		
			ExpressionParameters = BudgetingServer.TemplateForParametersForGettingTextOfFieldWithConditionForTypeOfAnalytics();
			ExpressionParameters.ExpressingAnalyticsValueWithoutIndex = "Dimension";
			ExpressionParameters.NameOfAnalyticsViewParameter = NameOfAnalyticsViewParameter_;
			If Source.SourceType = Enums.BudgetingDataSourceTypes.Balance Then
				ExpressionParameters.ExpressionNumberOfAnalyticsUsed = "IndicatorNumberOfAnalyticsUsed";
				ExpressionParameters.ExpressionViewAnalyticsWithoutIndex = "IndicatorTypeOfAnalytics";
			Else
				ExpressionParameters.ExpressionNumberOfAnalyticsUsed = "NumberOfUsedDimensions";
				ExpressionParameters.ExpressionViewAnalyticsWithoutIndex = "DimensionKind";
			EndIf;
			
			FieldText = BudgetingServer.TextOfFieldWithConditionByTypeOfAnalytics(ExpressionParameters);
			
		Else
			
			FieldText = "&Document_" + FieldName;
			
		EndIf;
		
		NewCalculatedField = DCS.CalculatedFields.Add();
		NewCalculatedField.DataPath = FieldName;
		NewCalculatedField.Expression = FieldText;
		NewCalculatedField.ValueType = BudgetingServer.AllTypesOfAnalytics();
		
		AddSchemaParameter(DCS, NameOfAnalyticsViewParameter_);
		ParametersForInstallation_.Insert(NameOfAnalyticsViewParameter_, DimensionKind);
		
		FinReports.NewDimensionField(Group, FieldName);
		
	EndDo;
	
	FiltersStructure = New Structure("Scenario, Organization, Department");
	For Cnt = 1 To MaximumNumberOfAnalysts Do
		FiltersStructure.Insert("Dimension" + Cnt);
	EndDo;
	
	For Each KeyAndValue In FiltersStructure Do
		
		If FindSelectionByName(Source.AdditionalSelection, KeyAndValue.Key, , True)
			And ColumnStructureOfDataTable.Dimensions.Find(KeyAndValue.Key) = Undefined Then
			
			Var_929_Dimension = KeyAndValue.Key;
			NewCalculatedField = DCS.CalculatedFields.Add();
			NewCalculatedField.DataPath = Var_929_Dimension;
			NewCalculatedField.Expression = "&Document_" + Var_929_Dimension;
			AddSchemaParameter(DCS, "Document_" + Var_929_Dimension);
			
		EndIf;
		
	EndDo;
	
	For Each Dimension In Analysts Do
		
		NameOfAnalytics = FinancialReportingCached.NameOfBudgetReportField(Dimension);
		If FindSelectionByName(Source.AdditionalSelection, NameOfAnalytics, , True)
			And ColumnStructureOfDataTable.DimensionKinds.Find(Dimension) = Undefined Then
			
			FieldName = FinancialReportingCached.NameOfBudgetReportField(Dimension);
			
			If HeaderDimensions.Find(Dimension) = Undefined Then
			
				NameOfAnalyticsViewParameter_ = "DimensionKind" + FieldName;
				
				ExpressionParameters = BudgetingServer.TemplateForParametersForGettingTextOfFieldWithConditionForTypeOfAnalytics();
				ExpressionParameters.ExpressingAnalyticsValueWithoutIndex = "Dimension";
				ExpressionParameters.NameOfAnalyticsViewParameter = NameOfAnalyticsViewParameter_;
				If Source.SourceType = Enums.BudgetingDataSourceTypes.Balance Then
					ExpressionParameters.ExpressionNumberOfAnalyticsUsed = "IndicatorNumberOfAnalyticsUsed";
					ExpressionParameters.ExpressionViewAnalyticsWithoutIndex = "IndicatorTypeOfAnalytics";
				Else
					ExpressionParameters.ExpressionNumberOfAnalyticsUsed = "NumberOfUsedDimensions";
					ExpressionParameters.ExpressionViewAnalyticsWithoutIndex = "DimensionKind";
				EndIf;
				
				FieldText = BudgetingServer.TextOfFieldWithConditionByTypeOfAnalytics(ExpressionParameters);
				
				AddSchemaParameter(DCS, NameOfAnalyticsViewParameter_);
				ParametersForInstallation_.Insert(NameOfAnalyticsViewParameter_, Dimension);
				
			Else
				
				FieldText = "&Document_" + FieldName;
				AddSchemaParameter(DCS, "Document_" + FieldName);
				
			EndIf;
		
			NewCalculatedField = DCS.CalculatedFields.Add();
			NewCalculatedField.DataPath = FieldName;
			NewCalculatedField.Expression = FieldText;
			
		EndIf;
		
	EndDo;
	
	MinimumPeriodicity = BudgetReportingClientServer.MinimumPeriodicity(ColumnStructureOfDataTable.Periodicity_);
	
	NewCalculatedField = DCS.CalculatedFields.Add();
	NewCalculatedField.DataPath = "Period";
	If Source.Id = "Document" Then
		NewCalculatedField.Expression = "PlanningPeriod";
	Else
		// If there is no period dimension, then the data period is considered to be the beginning of the document period.
		If Upper(Source.ExpressionOfGroupingPeriod) = "UNDEFINED" Then
			NewCalculatedField.Expression = "&BeginOfPeriod";
		Else
			NewCalculatedField.Expression = BudgetingServer.ConvertToDCSExpression(Source.ExpressionOfGroupingPeriod);
		EndIf;
	EndIf;
	
	NewCalculatedField = DCS.CalculatedFields.Add();
	NewCalculatedField.DataPath = "BeginOfPeriod";
	If Source.Id = "Document" Then
		NewCalculatedField.Expression = "&BeginOfPeriod";
	Else
		NewCalculatedField.Expression = BudgetingServer.ConvertToDCSExpression(Source.ExpressionStartOfPeriod);
	EndIf;
	
	NewCalculatedField = DCS.CalculatedFields.Add();
	NewCalculatedField.DataPath = "EndOfPeriod";
	If Source.Id = "Document" Then
		NewCalculatedField.Expression = "&EndOfPeriod";
	Else
		NewCalculatedField.Expression = BudgetingServer.ConvertToDCSExpression(Source.ExpressionEndOfPeriod);
	EndIf;
	
	If MinimumPeriodicity <> Undefined Then
		FinReports.NewDimensionField(Group, "Period");
	EndIf;
	
	FinReports.NewResource(DCS, "SumReceipt");
	FinReports.NewResource(DCS, "SumExpense");
	FinReports.NewResource(DCS, "SumCurrReceipt");
	FinReports.NewResource(DCS, "SumCurrExpense");
	FinReports.NewResource(DCS, "CountReceipt");
	FinReports.NewResource(DCS, "CountExpense");
	FinReports.NewResource(DCS, "SerialNumber", "MIN");
	FinReports.NewResource(DCS, "Note", "MAX");
	
	FinReports.NewSelectionField(DCS.DefaultSettings, "SumReceipt");
	FinReports.NewSelectionField(DCS.DefaultSettings, "SumExpense");
	FinReports.NewSelectionField(DCS.DefaultSettings, "SumCurrReceipt");
	FinReports.NewSelectionField(DCS.DefaultSettings, "SumCurrExpense");
	FinReports.NewSelectionField(DCS.DefaultSettings, "CountReceipt");
	FinReports.NewSelectionField(DCS.DefaultSettings, "CountExpense");
	FinReports.NewSelectionField(DCS.DefaultSettings, "SerialNumber");
	FinReports.NewSelectionField(DCS.DefaultSettings, "Note");
	
	FinReports.SetOutputParameter(DCS.DefaultSettings,
	                                   "HorizontalOverallPlacement",
	                                   DataCompositionTotalPlacement.None);
	FinReports.SetOutputParameter(DCS.DefaultSettings,
	                                   "VerticalOverallPlacement",
	                                   DataCompositionTotalPlacement.None);
	
	If Source.Id <> "Document" Then
		
		If Source.SourceType = Enums.BudgetingDataSourceTypes.Turnovers Then
			If Source.Objects.Count() Then
				FinReports.SetFilter(DCS.DefaultSettings.Filter,
				                          "BudgetFlowItem",
				                          ArrayToList(Source.Objects),
				                          DataCompositionComparisonType.InList);
			EndIf;
		ElsIf Source.SourceType = Enums.BudgetingDataSourceTypes.Balance Then
			If Source.Objects.Count() Then
				FinReports.SetFilter(DCS.DefaultSettings.Filter,
				                          "BudgetBalanceItem",
				                          ArrayToList(Source.Objects),
				                          DataCompositionComparisonType.InList);
			EndIf;
		EndIf;
		
		// Selection by period
		FilterValue = New DataCompositionField("BeginOfPeriod");
		Filter = FinReports.NewFilter(DCS.DefaultSettings.Filter, "Period", FilterValue);
		Filter.ComparisonType = DataCompositionComparisonType.GreaterOrEqual;
		
		FilterValue = New DataCompositionField("EndOfPeriod");
		Filter = FinReports.NewFilter(DCS.DefaultSettings.Filter, "Period", FilterValue);
		Filter.ComparisonType = DataCompositionComparisonType.LessOrEqual;
		
		AddSchemaParameter(DCS, "BeginOfPeriod");
		AddSchemaParameter(DCS, "EndOfPeriod");
		AddSchemaParameter(DCS, "ActualDataLimit");
		
		For Each Var_929_Dimension In ColumnStructureOfDataTable.Dimensions Do
			
			AdditionalFilter = Undefined;
			If Source.Property(Var_929_Dimension, AdditionalFilter) Then
				FinReports.SetFilter(DCS.DefaultSettings.Filter,
						Var_929_Dimension,
						ArrayToList(AdditionalFilter),
						DataCompositionComparisonType.InList);
			EndIf;
			
		EndDo;
		
		For Each Var_929_Dimension In ColumnStructureOfDataTable.DimensionKinds Do
			
			FieldName = FinancialReportingCached.NameOfBudgetReportField(Var_929_Dimension);
			AdditionalFilter = Undefined;
			If Source.Property(FieldName, AdditionalFilter) Then
				FinReports.SetFilter(DCS.DefaultSettings.Filter,
						FieldName,
						ArrayToList(AdditionalFilter),
						DataCompositionComparisonType.InList);
			EndIf;
			
		EndDo;
		
		AdditionalSelection = Source.AdditionalSelection;
		If AdditionalSelection <> Undefined Then
			FinReports.CopyFilter(AdditionalSelection.Filter, DCS.DefaultSettings.Filter, True);
		EndIf;
		
	EndIf;
	
	FinReports.NewFilter(DCS.DefaultSettings.Filter, "BudgetFlowItem", , , DataCompositionComparisonType.Filled);
	
	Return DCS;
	
EndFunction

Procedure SupplementExpressionOfCalculatedFieldWithTranslationByNumber(ExpressionOfCalculatedField, AnalyticsAddressExpression, AddressSubstitutionExpression = "", TextsAnalyst = Undefined, OfIndents = 1)
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	
	TemplateForExpressingAnalyticsAddressMetric = Chars.LF;
	For Cnt = 1 To OfIndents + 1 Do
		TemplateForExpressingAnalyticsAddressMetric = TemplateForExpressingAnalyticsAddressMetric + Chars.Tab;
	EndDo;
	TemplateForExpressingAnalyticsAddressMetric = TemplateForExpressingAnalyticsAddressMetric
		+ "WHEN %1 = %2 THEN %3";
	
	ExpressingAnalyticsAddressMetric = "";
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		If AddressSubstitutionExpression = "" Then
			SubstitutionExpression = TextsAnalyst[DimensionNumber];
		Else
			SubstitutionExpression = AddressSubstitutionExpression + DimensionNumber;
		EndIf;
		ExpressingAnalyticsAddressMetric = ExpressingAnalyticsAddressMetric
			+ StringFunctionsClientServer.SubstituteParametersToString(TemplateForExpressingAnalyticsAddressMetric,
				AnalyticsAddressExpression,
				DimensionNumber,
				SubstitutionExpression);
	EndDo;
	
	// Expression SELECTION %1 END. The margins are used to format the text of the query expression.
	TemplateForExpressingAnalyticsAddressMetric = "CASE %1" + Chars.LF;
	For Cnt = 1 To OfIndents Do
		TemplateForExpressingAnalyticsAddressMetric = TemplateForExpressingAnalyticsAddressMetric + Chars.Tab;
	EndDo;
	TemplateForExpressingAnalyticsAddressMetric = TemplateForExpressingAnalyticsAddressMetric
		+ "END";
	ExpressingAnalyticsAddressMetric = StringFunctionsClientServer.SubstituteParametersToString(
		TemplateForExpressingAnalyticsAddressMetric,
		ExpressingAnalyticsAddressMetric);
	
	ExpressionOfCalculatedField = StringFunctionsClientServer.SubstituteParametersToString(
		ExpressionOfCalculatedField,
		ExpressingAnalyticsAddressMetric);
	
EndProcedure

// Key operation: "Budgeting.Resetcachedcontent"
//
Function GetDCSFromSourceDescriptions(BudgetProfile, StructureOfReportDescription, ColumnStructureOfDataTable, GenerationMode)
	
	SetPrivilegedMode(True);
	
	Postfix = ?(GenerationMode = Enums.ModesOfBudgetReportGeneration.PrintBudget,
						Enums.ModesOfBudgetReportGeneration.Document,
						GenerationMode);
	
	TypeOfCacheElement = Enums.BudgetCacheKinds.CompositionSchemas;
	Value = InformationRegisters.CacheOfAuxiliaryBudgetProfileData.GetCacheValue(BudgetProfile, TypeOfCacheElement, Postfix);
	
	If Value <> Undefined Then
		SetPrivilegedMode(False);
		Return Value
	EndIf;
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("Budgeting.CalculationAndReceiptOfDCSSources");

	Result = CalculationAndReceiptOfDCSSources(BudgetProfile, StructureOfReportDescription, ColumnStructureOfDataTable, GenerationMode, TypeOfCacheElement, Postfix);
	
	DataVolume = StructureOfReportDescription.DataSources.Count();
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, DataVolume);
	
	SetPrivilegedMode(False);
	
	Return Result;
	
EndFunction

Function CalculationAndReceiptOfDCSSources(BudgetProfile, StructureOfReportDescription, ColumnStructureOfDataTable, GenerationMode, TypeOfCacheElement, Postfix)
	
	DataSources = StructureOfReportDescription.DataSources; // Array of See NewSource
	SourceFields_2 = StructureOfReportDescription.SourceFields_2;
	DataReceiptMode = Common.ObjectAttributeValue(BudgetProfile, "DataReceiptMode");
	If Not ValueIsFilled(DataReceiptMode) Then
		DataReceiptMode = Enums.BudgetingDataReceiptMode.Allowed;
	EndIf;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	BudgetFlowItemDimensions.Ref
		|FROM
		|	ChartOfCharacteristicTypes.BudgetFlowItemDimensions AS BudgetFlowItemDimensions";

	Analysts = Query.Execute().Unload().UnloadColumn("Ref");
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	BudgetProfilesHeaderDimensions.DimensionKind
		|FROM
		|	Catalog.BudgetProfiles.HeaderDimensions AS BudgetProfilesHeaderDimensions
		|WHERE
		|	BudgetProfilesHeaderDimensions.Ref = &BudgetProfile";
	Query.SetParameter("BudgetProfile", BudgetProfile);
	
	HeaderDimensions = Query.Execute().Unload().UnloadColumn("DimensionKind");
	
	IsBalance = False; 
	ThereAreStoredRules = False; 
	ThereIsPrivilegedMode = False;
	
	For Each Source In DataSources Do
		IsBalance = IsBalance Or Source.SourceType = Enums.BudgetingDataSourceTypes.Balance;
		ThereAreStoredRules = ThereAreStoredRules Or Source.ThereAreStoredRules;

		ThereIsPrivilegedMode = ThereIsPrivilegedMode Or 
			(Not Source.PrivilegedMode = Undefined And Source.PrivilegedMode);
		If IsBalance And ThereAreStoredRules And ThereIsPrivilegedMode Then
			Break;
		EndIf;
	EndDo;
	
	ParametersForInstallation_ = New Structure;
	
	ParametersForInstallation_.Insert("FunctionalCurrency",
		Common.ObjectAttributeValue(BudgetProfile, "Owner.FunctionalCurrency"));
	
	FormationModes = New Structure("GenerationMode, DataReceiptMode", GenerationMode, DataReceiptMode);
	DCSPlanningData = GetDCSPlanningData(DataSources,
			SourceFields_2,
			ColumnStructureOfDataTable,
			Analysts,
			ParametersForInstallation_,
			FormationModes);
		
	If ThereIsPrivilegedMode Then
		
		FormationModes.Insert("PrivilegedMode", True); 
		DCSPlanningDataPrivileged = GetDCSPlanningData(DataSources,
				SourceFields_2,
				ColumnStructureOfDataTable,
				Analysts,
				ParametersForInstallation_,
				FormationModes);
	EndIf;
	
	If ThereAreStoredRules Then
		
		FormationModes = New Structure("GenerationMode, DataReceiptMode", GenerationMode, DataReceiptMode);  
		DCSActualData = GetDCSActualData(DataSources,
				SourceFields_2,
				ColumnStructureOfDataTable,
				Analysts,
				ParametersForInstallation_,
				FormationModes);
			
		If ThereIsPrivilegedMode Then
			FormationModes.Insert("PrivilegedMode", True); 
			DCSActualDataPrivileged = GetDCSActualData(DataSources,
					SourceFields_2,
					ColumnStructureOfDataTable,
					Analysts,
					ParametersForInstallation_,
					FormationModes);
		EndIf;
	EndIf;
	
	If IsBalance Then
		DCSPreliminaryCalculation = GetDCSPreliminaryFinalCalculation(DataSources,
				SourceFields_2,
				ColumnStructureOfDataTable,
				ThereAreStoredRules,
				ThereIsPrivilegedMode);
		DCSSummaryData = GetDCSTotals(DataSources, SourceFields_2, ColumnStructureOfDataTable);
		If GenerationMode = Enums.ModesOfBudgetReportGeneration.Document
			Or GenerationMode = Enums.ModesOfBudgetReportGeneration.PrintBudget Then
			DCSDocumentData = GetDocumentDCS(DataSources,
					SourceFields_2,
					ColumnStructureOfDataTable,
					Analysts,
					HeaderDimensions,
					ParametersForInstallation_,
					DCSPreliminaryCalculation);
			If ThereIsEditableValue(DataSources) Then
				FinancialReportingServer.NewDimensionField(
					DCSPreliminaryCalculation.DefaultSettings.Structure[0],
					"EditedValue");
				FinancialReportingServer.NewDimensionField(
					DCSSummaryData.DefaultSettings.Structure[0],
					"EditedValue");
			EndIf;
			FinancialReportingServer.NewSetField(DCSSummaryData.DataSets[0], "AlwaysOutputFlag");
			FinancialReportingServer.NewResource(DCSSummaryData, "AlwaysOutputFlag");
			FinancialReportingServer.NewSelectionField(DCSSummaryData.DefaultSettings, "AlwaysOutputFlag");
		EndIf;
	Else
		DCSPreliminaryCalculation = Undefined;
		DCSSummaryData = GetDCSTotalsRevolutions(DataSources,
				SourceFields_2,
				ColumnStructureOfDataTable, 
				ThereAreStoredRules,
				ThereIsPrivilegedMode);
		If GenerationMode = Enums.ModesOfBudgetReportGeneration.Document
			Or GenerationMode = Enums.ModesOfBudgetReportGeneration.PrintBudget Then
			DCSDocumentData = GetDocumentDCS(DataSources,
					SourceFields_2,
					ColumnStructureOfDataTable, 
					Analysts,
					HeaderDimensions,
					ParametersForInstallation_,
					DCSSummaryData);
			If ThereIsEditableValue(DataSources) Then
				FinancialReportingServer.NewDimensionField(
					DCSSummaryData.DefaultSettings.Structure[0],
					"EditedValue");
			EndIf;
		EndIf;
	EndIf;
	If IsBalance Then
		FinancialReportingServer.NewSetField(DCSPreliminaryCalculation.DataSets[0],
		                                           "DocumentData",,,
		                                           New TypeDescription("Boolean"));
		FinancialReportingServer.NewDimensionField(
					DCSPreliminaryCalculation.DefaultSettings.Structure[0],
					"DocumentData");
	EndIf;
	FinancialReportingServer.NewSetField(DCSSummaryData.DataSets[0],
	                                           "DocumentData",,,
	                                           New TypeDescription("Boolean"));
	FinancialReportingServer.NewDimensionField(
					DCSSummaryData.DefaultSettings.Structure[0],
					"DocumentData");
	
	// Layout parameters.
	For Each Parameter In ParametersForInstallation_ Do
		If TypeOf(Parameter.Value) = Type("ValueList") Then
			
			LayoutParameter = DCSPlanningData.Parameters.Find(Parameter.Key);
			If LayoutParameter = Undefined Then
				LayoutParameter = DCSPlanningData.Parameters.Add();
				LayoutParameter.Name = Parameter.Key;
			EndIf;
			LayoutParameter.ValueListAllowed = True;
			
			If ThereIsPrivilegedMode Then
				LayoutParameter = DCSPlanningDataPrivileged.Parameters.Find(Parameter.Key);
				If LayoutParameter = Undefined Then
					LayoutParameter = DCSPlanningDataPrivileged.Parameters.Add();
					LayoutParameter.Name = Parameter.Key;
				EndIf;
				LayoutParameter.ValueListAllowed = True;
			EndIf;
			
			LayoutParameter = DCSSummaryData.Parameters.Find(Parameter.Key);
			If LayoutParameter = Undefined Then
				LayoutParameter = DCSSummaryData.Parameters.Add();
				LayoutParameter.Name = Parameter.Key;
			EndIf;
			LayoutParameter.ValueListAllowed = True;
			
			If ThereAreStoredRules Then
				
				LayoutParameter = DCSActualData.Parameters.Find(Parameter.Key);
				If LayoutParameter = Undefined Then
					LayoutParameter = DCSActualData.Parameters.Add();
					LayoutParameter.Name = Parameter.Key;
				EndIf;
				LayoutParameter.ValueListAllowed = True;
				
				If ThereIsPrivilegedMode Then
					LayoutParameter = DCSActualDataPrivileged.Parameters.Find(Parameter.Key);
					If LayoutParameter = Undefined Then
						LayoutParameter = DCSActualDataPrivileged.Parameters.Add();
						LayoutParameter.Name = Parameter.Key;
					EndIf;
					LayoutParameter.ValueListAllowed = True;
				EndIf;

			EndIf;
			
			If GenerationMode = Enums.ModesOfBudgetReportGeneration.Document 
				Or GenerationMode = Enums.ModesOfBudgetReportGeneration.PrintBudget Then
				For Each KeyAndValue In DCSDocumentData Do
					DocumentDCS = KeyAndValue.Value; // DataCompositionSchema
					LayoutParameter = DocumentDCS.Parameters.Find(Parameter.Key);
					If LayoutParameter = Undefined Then
						LayoutParameter = DocumentDCS.Parameters.Add();
						LayoutParameter.Name = Parameter.Key;
					EndIf;
					LayoutParameter.ValueListAllowed = True;
				EndDo;
			EndIf;
			
		EndIf;
	EndDo;
	
	ExpressionOfCalculatedField =
		"CASE WHEN NonFinancialItem = UNDEFINED THEN VALUE(Catalog.NonFinancialItemsOfBudgets.EmptyRef)
		|ELSE ISNULL(NonFinancialItem, VALUE(Catalog.NonFinancialItemsOfBudgets.EmptyRef)) END";
	FinancialReportingServer.NewCalculatedField(DCSSummaryData,
	                                                "NonFinancialItem",
	                                                ExpressionOfCalculatedField);
	
	// It is necessary to clear the budget item for the calculated indicator of budgets for the correct mapping of analytics when displaying
	// the data cell table.
	ExpressionOfCalculatedField =
	"CASE WHEN ValueIsFilled(BudgetBalanceItem) AND BudgetBalanceItem.IndicatorType = VALUE(Enum.BudgetBalanceItemType.Estimated_) THEN UNDEFINED
	|WHEN NOT ValueIsFilled(BudgetFlowItem) THEN UNDEFINED
	|ELSE BudgetFlowItem END";
	FinancialReportingServer.NewCalculatedField(DCSSummaryData,
	                                                "BudgetFlowItem",
	                                                ExpressionOfCalculatedField);
	
	ExpressionOfCalculatedField = "CASE WHEN NOT ValueIsFilled(EditedValue) THEN """" ELSE EditedValue END";
	FinancialReportingServer.NewCalculatedField(DCSSummaryData,
	                                                "EditedValue",
	                                                ExpressionOfCalculatedField);
	
	ExpressionOfCalculatedField =
	"CASE WHEN BudgetBalanceItem = UNDEFINED THEN VALUE(Catalog.BudgetBalanceItems.EmptyRef)
	|ELSE ISNULL(BudgetBalanceItem, VALUE(Catalog.BudgetBalanceItems.EmptyRef)) END";
	FinancialReportingServer.NewCalculatedField(DCSSummaryData,
	                                                "BudgetBalanceItem",
	                                                ExpressionOfCalculatedField);
	
	If DCSSummaryData.DefaultSettings.Structure[0].Structure.Count() > 0 Then;
		For Each StructureItem In DCSSummaryData.DefaultSettings.Structure[0].Structure Do
			DataCompositionFilter = StructureItem.Filter; // DataCompositionFilter 
			OrGroup = DataCompositionFilter.Items.Add(Type("DataCompositionFilterItemGroup")); // DataCompositionFilterItemGroup
			OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
			OrGroup.Application = DataCompositionFilterApplicationType.Hierarchy;
			FillInSelectionGroupDCSTotals(OrGroup, SourceFields_2, GenerationMode);
		EndDo;
	Else
		DataCompositionFilter = DCSSummaryData.DefaultSettings.Structure[0].Filter; // DataCompositionFilter 
		OrGroup = DataCompositionFilter.Items.Add(Type("DataCompositionFilterItemGroup"));  // DataCompositionFilterItemGroup
		OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
		OrGroup.Application = DataCompositionFilterApplicationType.Hierarchy;
		FillInSelectionGroupDCSTotals(OrGroup, SourceFields_2, GenerationMode);
	EndIf;
	
	Result = New Structure();
	Result.Insert("DCSSummary", DCSSummaryData);
	Result.Insert("DCSPlanningData", DCSPlanningData);
	Result.Insert("DCSDocumentData",DCSDocumentData); 
	Result.Insert("DCSPreliminaryCalculation", DCSPreliminaryCalculation);
	Result.Insert("Parameters", ParametersForInstallation_);
	
	If ThereAreStoredRules Then
		Result.Insert("DCSActualData", DCSActualData);
		If ThereIsPrivilegedMode Then
			Result.Insert("DCSActualDataPrivileged", DCSActualDataPrivileged);
		EndIf;
	EndIf;
	
	If ThereIsPrivilegedMode Then
		Result.Insert("DCSPlanningDataPrivileged", DCSPlanningDataPrivileged);
	EndIf;
	
	InformationRegisters.CacheOfAuxiliaryBudgetProfileData.SetCacheValue(BudgetProfile, TypeOfCacheElement, Result, Postfix);	
	
	Return Result;
	
EndFunction

Procedure FillInSelectionGroupDCSTotals(FilterGroup, SourceFields_2, GenerationMode)
	
	If GenerationMode = Enums.ModesOfBudgetReportGeneration.Document
		Or GenerationMode = Enums.ModesOfBudgetReportGeneration.PrintBudget Then
		
		NewElementOfSelection = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
		NewElementOfSelection.LeftValue = New DataCompositionField("AlwaysOutputFlag");
		NewElementOfSelection.ComparisonType = DataCompositionComparisonType.Filled;
		
		NewElementOfSelection = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
		NewElementOfSelection.LeftValue = New DataCompositionField("Note");
		NewElementOfSelection.ComparisonType = DataCompositionComparisonType.Filled;
		
	EndIf;
	
	// Cut off the "empty values".
	For Each FieldString In SourceFields_2.FindRows(New Structure("Auxiliary_", False)) Do
		
		NewElementOfSelection = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
		NewElementOfSelection.LeftValue = New DataCompositionField(FieldString.ResourceName);
		NewElementOfSelection.ComparisonType = DataCompositionComparisonType.Filled;
		
	EndDo;
	
EndProcedure

Function ThereIsEditableValue(DataSources)
	
	If DataSources = Undefined Then
		Return False;
	EndIf;
	
	For Each Source In DataSources Do
		If Source.SourceType = Enums.BudgetingDataSourceTypes.EditedValue Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

Function GetDCsOfDocumentValues(Source, ColumnStructureOfDataTable, Analysts, HeaderDimensions, ParametersForInstallation_)
	
	FinReports = FinancialReportingServer;
	DCS = DataCompositionServer.EmptyCircuit();
	
	SetOfDocumentValues = DataCompositionServer.AddEmptyDataSet(DCS,
		Type("DataCompositionSchemaDataSetQuery"), "InstanceOfBudget_Values");
	SetOfDocumentValues.Query = 
	"SELECT
	|	DimensionValues_.EditedValue AS EditedValue,
	|	&TextOfAnalyticsViewFields,
	|	&TextOfDimensionsFields,
	|	DimensionValues_.NumberOfUsedDimensions AS NumberOfUsedDimensions,
	|	BudgetFlowItemTurnovers.PlanningPeriod AS PlanningPeriod,
	|	BudgetFlowItemTurnovers.SerialNumber AS SerialNumber,
	|	BudgetFlowItemTurnovers.Note AS Note,
	|	BudgetFlowItemTurnovers.Value AS Value
	|FROM
	|	DimensionValues_ AS DimensionValues_
	|		INNER JOIN BudgetFlowItemTurnovers AS BudgetFlowItemTurnovers
	|		ON DimensionValues_.RowID = BudgetFlowItemTurnovers.RowID";
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	AllTypesOfAnalytics = BudgetingServer.AllTypesOfAnalytics();
	
	ArrayOfAnalystFields = New Array;
	ArrayOfAnalyticsTypeFields = New Array;
	FinReports.NewSetField(SetOfDocumentValues, "RowID");
	For Cnt = 1 To MaximumNumberOfAnalysts Do
		ArrayOfAnalystFields.Add(StringFunctionsClientServer.SubstituteParametersToString(
			"DimensionValues_.Dimension%1 AS Dimension%1", Cnt)); //@ query-part
		ArrayOfAnalyticsTypeFields.Add(StringFunctionsClientServer.SubstituteParametersToString(
			"DimensionValues_.DimensionKind%1 AS DimensionKind%1", Cnt)); //@ query-part
		FinReports.NewSetField(SetOfDocumentValues, "Dimension" + Cnt,,,AllTypesOfAnalytics);
		FinReports.NewSetField(SetOfDocumentValues, "DimensionKind" + Cnt);
	EndDo;
	TextOfDimensionsFields = StrConcat(ArrayOfAnalystFields, "," + Chars.LF + Chars.Tab);
	TextOfAnalyticsViewFields = StrConcat(ArrayOfAnalyticsTypeFields, "," + Chars.LF + Chars.Tab);
	SetOfDocumentValues.Query = StrReplace(SetOfDocumentValues.Query, "&TextOfDimensionsFields", TextOfDimensionsFields);
	SetOfDocumentValues.Query = StrReplace(SetOfDocumentValues.Query, "&TextOfAnalyticsViewFields",
		TextOfAnalyticsViewFields);
	
	FinReports.NewSetField(SetOfDocumentValues, "NumberOfUsedDimensions");
	FinReports.NewSetField(SetOfDocumentValues, "EditedValue", , ,
		ColumnTypeOfCellStructure("EditedValue"));
	
	FinReports.NewSetField(SetOfDocumentValues, "PlanningPeriod", , , New TypeDescription("Date"));
	FinReports.NewSetField(SetOfDocumentValues, "SerialNumber");
	FinReports.NewSetField(SetOfDocumentValues, "Note");
	FinReports.NewSetField(SetOfDocumentValues, "RowID");
	FinReports.NewSetField(SetOfDocumentValues, "Value", "IndicatorValue");
	
	NewCalculatedField = DCS.CalculatedFields.Add();
	NewCalculatedField.DataPath = "ID_Source1";
	NewCalculatedField.Expression = """" + Source.Id + """";
	
	Group = FinReports.NewGrouping(DCS.DefaultSettings.Structure, "ID_Source1");
	FinReports.NewDimensionField(Group, "EditedValue");
	
	For Each DimensionKind In ColumnStructureOfDataTable.DimensionKinds Do
		
		FieldName = FinancialReportingCached.NameOfBudgetReportField(DimensionKind);
		
		NameOfAnalyticsViewParameter_ = "DimensionKind" + FieldName;
		
		If HeaderDimensions.Find(DimensionKind) = Undefined Then
			
			ExpressionParameters = BudgetingServer.TemplateForParametersForGettingTextOfFieldWithConditionForTypeOfAnalytics();
			ExpressionParameters.ExpressionNumberOfAnalyticsUsed = "NumberOfUsedDimensions";
			ExpressionParameters.ExpressionViewAnalyticsWithoutIndex = "DimensionKind";
			ExpressionParameters.ExpressingAnalyticsValueWithoutIndex = "Dimension";
			ExpressionParameters.NameOfAnalyticsViewParameter = NameOfAnalyticsViewParameter_;
			
			FieldText = BudgetingServer.TextOfFieldWithConditionByTypeOfAnalytics(ExpressionParameters);
			
		Else
			
			FieldText = "&Document_" + FieldName;
			
		EndIf;
		
		NewCalculatedField = DCS.CalculatedFields.Add();
		NewCalculatedField.DataPath = FieldName;
		NewCalculatedField.Expression = FieldText;
		
		AddSchemaParameter(DCS, NameOfAnalyticsViewParameter_);
		ParametersForInstallation_.Insert(NameOfAnalyticsViewParameter_, DimensionKind);
		
		FinReports.NewDimensionField(Group, FieldName);
		
	EndDo;
	
	NewCalculatedField = DCS.CalculatedFields.Add();
	NewCalculatedField.DataPath = "Period";
	NewCalculatedField.Expression = "PlanningPeriod";
	
	MinimumPeriodicity = BudgetReportingClientServer.MinimumPeriodicity(ColumnStructureOfDataTable.Periodicity_);
	If MinimumPeriodicity <> Undefined Then
		FinReports.NewDimensionField(Group, "Period");
	EndIf;
	
	FinReports.NewFilter(DCS.DefaultSettings.Filter, "EditedValue", , , DataCompositionComparisonType.Filled);
	
	FinReports.NewResource(DCS, "IndicatorValue", "MAX");
	FinReports.NewResource(DCS, "SerialNumber", "MIN");
	FinReports.NewResource(DCS, "Note", "MAX");
	
	FinReports.NewSelectionField(DCS.DefaultSettings, "IndicatorValue");
	FinReports.NewSelectionField(DCS.DefaultSettings, "SerialNumber");
	FinReports.NewSelectionField(DCS.DefaultSettings, "Note");
	
	FinReports.SetOutputParameter(DCS.DefaultSettings,
	                                   "HorizontalOverallPlacement",
	                                   DataCompositionTotalPlacement.None);
	FinReports.SetOutputParameter(DCS.DefaultSettings,
	                                   "VerticalOverallPlacement",
	                                   DataCompositionTotalPlacement.None);
	
	Return DCS;
	
EndFunction

Function TextOfFillingSourceConditionUnits(IndicatorText) Export
	
	UnitParameterTemplate = New Structure("ConditionText, TextNumerator, TextDenominator");
	
	UnitsOfMeasurementParameters = New Structure;
	
	AttributesOfUnitsOfMeasurement = StringFunctionsClientServer.SplitStringIntoSubstringsArray(
		"UnitForReports, WeightUnitOfMeasure, LengthUnitOfMeasure, VolumeUnitOfMeasure, AreaUnitOfMeasure", ",", , True);
	
	For Each AttributesOfUnitOfMeasurement In AttributesOfUnitsOfMeasurement Do
		UnitOfMeasurementParameters = Common.CopyRecursive(UnitParameterTemplate);
		If AttributesOfUnitOfMeasurement = "UnitForReports" Then
			ConditionText = "CAST(BudgetReportingDisplayServer.Attachable_ValueFromAnalytics(
				|			&CacheAnalystValues,
				|			%1,
				|			SourceFillingInUnit), ""Catalog.PackagesAndUnitsOfMeasure"") <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)";
			TextNumerator = "1";
			TextDenominator = "CAST(BudgetReportingDisplayServer.Attachable_ValueFromAnalytics(
				|			&CacheAnalystValues,
				|			%1,
				|			""UnitFactorForReports""), ""NUMBER(15,3)"")";
		Else
			MeasureOfMeasurement = StrReplace(AttributesOfUnitOfMeasurement, "UnitOfMeasure", "");
			ConditionText = StrReplace("CAST(BudgetReportingDisplayServer.Attachable_ValueFromAnalytics(
				|			&CacheAnalystValues,
				|			%1,
				|			&Use), ""Boolean"") = TRUE", "&Use",
				StringFunctionsClientServer.SubstituteParametersToString("""%1Use""", MeasureOfMeasurement));
			TextNumerator = StrReplace("CAST(BudgetReportingDisplayServer.Attachable_ValueFromAnalytics(
				|			&CacheAnalystValues,
				|			%1,
				|			&Numerator), ""NUMBER(15,3)"")", "&Numerator",
				StringFunctionsClientServer.SubstituteParametersToString("""%1Numerator""", MeasureOfMeasurement));
			TextDenominator = StrReplace("CAST(BudgetReportingDisplayServer.Attachable_ValueFromAnalytics(
				|			&CacheAnalystValues,
				|			%1,
				|			&Denominator), ""NUMBER(15,3)"")", "&Denominator",
				StringFunctionsClientServer.SubstituteParametersToString("""%1Denominator""", MeasureOfMeasurement));
		EndIf;
		UnitOfMeasurementParameters.ConditionText = ConditionText;
		UnitOfMeasurementParameters.TextNumerator = TextNumerator;
		UnitOfMeasurementParameters.TextDenominator = TextDenominator;
		UnitsOfMeasurementParameters.Insert(AttributesOfUnitOfMeasurement, UnitOfMeasurementParameters);
	EndDo;
	
	FragmentOfCalculatedFieldExpression =
		"		WHEN SourceFillingInUnit = ""%1""
		|			AND %2 
		|		THEN %3 * %4 / %5";
	
	ArrayOfExpressionsForCalculatedField = New Array;
	For Each KeyAndValue In UnitsOfMeasurementParameters Do
		ArrayOfExpressionsForCalculatedField.Add(StringFunctionsClientServer.SubstituteParametersToString(
			FragmentOfCalculatedFieldExpression, KeyAndValue.Key, KeyAndValue.Value.ConditionText, IndicatorText,
			KeyAndValue.Value.TextNumerator, KeyAndValue.Value.TextDenominator));
	EndDo;
	
	ExpressionOfCalculatedField =  StringFunctionsClientServer.SubstituteParametersToString("
		|	CASE
		|		%1
		|		ELSE %2
		|	END", StrConcat(ArrayOfExpressionsForCalculatedField, Chars.LF + Chars.Tab), IndicatorText);
	
	Return ExpressionOfCalculatedField;
	
EndFunction

#EndRegion

#Region GeneratingTreeForReportOutput

Function AddOutputTreeGrouping(PlaceAdded, DimensionName, ReportItem, ItemKind)
	
	If DimensionName = "Table" Or DimensionName = "TextBlock" Then
		
		If TypeOf(PlaceAdded) <> Type("ValueTree") Then
			PlaceAdded = PlaceAdded.Owner();
		EndIf;
		
	Else
		
		InTable = False;
		CheckString = PlaceAdded;
		
		If TypeOf(CheckString) <> Type("ValueTree") Then
			While ValueIsFilled(CheckString) Do
				If CheckString.DimensionName = "Table" Then
					InTable = True;
					Break;
				EndIf;
				CheckString = CheckString.Parent;
			EndDo;
		EndIf;
		
		If Not InTable Then
			
			If TypeOf(CheckString) <> Type("ValueTree") Then
				PlaceAdded = PlaceAdded.Owner();
			EndIf;
			
			Table = PlaceAdded.Rows.Add();
			Table.DimensionName = "Table";
			Table.Rows.Add().DimensionName = "Columns";
			Table.TableParameters.Insert("DisplayColumnNumbering", False);
			Table.TableParameters.Insert("DisplayRowsNumbering", False);
			
			PlaceAdded = Table.Rows.Add();
			PlaceAdded.DimensionName = "Rows";
			
		EndIf;
		
	EndIf;
	
	NewGrouping = PlaceAdded.Rows.Add();
	NewGrouping.DimensionName = DimensionName;
	NewGrouping.ReportItem = ReportItem;
	NewGrouping.ItemKind = ItemKind;
	
	Return NewGrouping;
	
EndFunction

Procedure FillInAdditionalDimensionFieldsInOutputTree(BudgetProfile, OutputTree)
	
	Query = New Query;
	Query.Text = 
	"SELECT
		|	TabularSection.Attribute,
		|	CASE
		|		WHEN TabularSection.TitleOutput
		|			THEN TabularSection.Description
		|		ELSE """"
		|	END AS Title,
		|	TabularSection.Ref AS ReportItem,
		|	TabularSection.InSeparateColumn
		|FROM
		|	Catalog.FinancialReportItems AS Catalog
		|		INNER JOIN Catalog.FinancialReportItems.AdditionalFields AS TabularSection
		|		ON (TabularSection.Ref = Catalog.Ref)
		|			AND (Catalog.Owner = &BudgetProfile)
		|TOTALS BY
		|	ReportItem";
	
	Query.SetParameter("BudgetProfile", BudgetProfile);
	QueryResult = Query.Execute();
	SamplingElements = QueryResult.Select(QueryResultIteration.ByGroups);
	
	While SamplingElements.Next() Do
		TreeRow = OutputTree.Rows.Find(SamplingElements.ReportItem, "ReportItem", True);
		TreeRow.AdditionalFields.Columns.Add("Attribute");
		TreeRow.AdditionalFields.Columns.Add("AttributeName");
		TreeRow.AdditionalFields.Columns.Add("Title");
		TreeRow.AdditionalFields.Columns.Add("InSeparateColumn");
		TreeRow.AdditionalFields.Indexes.Add("InSeparateColumn");
		SelectionAdditionalDetails = SamplingElements.Select();
		While SelectionAdditionalDetails.Next() Do
			NewRow = TreeRow.AdditionalFields.Add();
			FillPropertyValues(NewRow, SelectionAdditionalDetails);
			Letters = "abcdefghijklmnopqrstuvwxyzабвгдеёжзийклмнопрстуфхцчшщъыьэюя";
			Digits = "0123456789";
			AdditionalChars = "_";
			AllowedChars = Letters + Digits + AdditionalChars;
			AttributeName = "";
			SearchName = Lower(NewRow.Attribute);
			SearchName = StrReplace(SearchName, " ", "");
			For Cnt = 1 To StrLen(NewRow.Attribute) Do
				Char = Mid(SearchName, Cnt, 1);
				If Not StrFind(AllowedChars, Char) Then
					AttributeName = AttributeName + "_";
				Else
					AttributeName = AttributeName + Char;
				EndIf;
			EndDo;
			NewRow.AttributeName = AttributeName;
		EndDo;
	EndDo;
	
EndProcedure

Procedure CreateRecursivelyGroupingOutputTree(BudgetProfile, CacheAdditionalBankingDetails, Val PlaceAdded, Items)
	
	FinReports = FinancialReportingServer;
	
	For Each Item In Items.Rows Do
		
		NewGrouping = Undefined;
		
		If Item.ItemKind = Enums.FinancialReportItemKinds.ReportHeader 
			Or Item.ItemKind = Enums.FinancialReportItemKinds.EditedText
			Or Item.ItemKind = Enums.FinancialReportItemKinds.UneditedText Then
			
			NewGrouping = AddOutputTreeGrouping(PlaceAdded, "TextBlock", 
																Item.ReportItem, Item.ItemKind);
			NewGrouping.NameForPrinting = FinReports.ValueOfAdditionalProps(Item.ReportItem,
																"Text", CacheAdditionalBankingDetails);
			NewGrouping.OnlyForPrinting = FinReports.ValueOfAdditionalProps(Item.ReportItem,
																"OnlyForPrinting", CacheAdditionalBankingDetails);
			
		ElsIf Item.ItemKind = Enums.FinancialReportItemKinds.AllBudgetBalanceItems Then
			NewGrouping = AddOutputTreeGrouping(PlaceAdded, "BudgetBalanceItem", 
																Item.ReportItem, Item.ItemKind);
			
		ElsIf Item.ItemKind = Enums.FinancialReportItemKinds.AllBudgetFlowItems Then
			NewGrouping = AddOutputTreeGrouping(PlaceAdded, "BudgetFlowItem", 
																Item.ReportItem, Item.ItemKind);
			
		ElsIf Item.ItemKind = Enums.FinancialReportItemKinds.BudgetBalanceItem Then
			BudgetBalanceItem = FinReports.ValueOfAdditionalProps(Item.ReportItem, "BudgetBalanceItem", CacheAdditionalBankingDetails);
			NewGrouping = AddOutputTreeGrouping(PlaceAdded, "BudgetBalanceItem", 
																Item.ReportItem, Item.ItemKind);
			NewGrouping.FixedValue = BudgetBalanceItem;
			NewGrouping.NameForPrinting = Item.NameForPrinting;
			
		ElsIf Item.ItemKind = Enums.FinancialReportItemKinds.BudgetFlowItem Then
			BudgetFlowItem = FinReports.ValueOfAdditionalProps(Item.ReportItem, "BudgetFlowItem", CacheAdditionalBankingDetails);
			NewGrouping = AddOutputTreeGrouping(PlaceAdded, "BudgetFlowItem", 
																Item.ReportItem, Item.ItemKind);
			NewGrouping.FixedValue = BudgetFlowItem;
			NewGrouping.NameForPrinting = Item.NameForPrinting;
			
		ElsIf Item.ItemKind = Enums.FinancialReportItemKinds.NonFinancialItem Then
			NonFinancialItem = FinReports.ValueOfAdditionalProps(Item.ReportItem, "NonFinancialItem", CacheAdditionalBankingDetails);
			NewGrouping = AddOutputTreeGrouping(PlaceAdded, "NonFinancialItem", 
																Item.ReportItem, Item.ItemKind);
			NewGrouping.FixedValue = NonFinancialItem;
			NewGrouping.NameForPrinting = Item.NameForPrinting;
			
		ElsIf Item.ItemKind = Enums.FinancialReportItemKinds.EditedValue Then
			NewGrouping = AddOutputTreeGrouping(PlaceAdded, "EditedValue", 
																Item.ReportItem, Item.ItemKind);
			NewGrouping.FixedValue = Item.NameForPrinting;
			NewGrouping.NameForPrinting = Item.NameForPrinting;
			
		ElsIf Item.ItemKind = Enums.FinancialReportItemKinds.Dimension Then
			
			DimensionType = FinReports.ValueOfAdditionalProps(Item.ReportItem, "DimensionType", CacheAdditionalBankingDetails);
			ValueOfFilter = Undefined; ThisIsDimensionOther = Undefined; DimensionKind = Undefined;
			
			If DimensionType = Enums.TypesOfBudgetReportDimensions.Period Then
				Periodicity = FinReports.ValueOfAdditionalProps(Item.ReportItem, "Periodicity", CacheAdditionalBankingDetails);
				DimensionName = FinancialReportingClientServer.PeriodStrings(Periodicity).Period;
				
			ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.Dimension Then
				DimensionKind = FinReports.ValueOfAdditionalProps(Item.ReportItem, "DimensionKind", CacheAdditionalBankingDetails);
				DimensionName = FinancialReportingCached.NameOfBudgetReportField(DimensionKind);
				
			ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.RegisterDimension Then
				DimensionName = FinReports.ValueOfAdditionalProps(Item.ReportItem, "DimensionName", CacheAdditionalBankingDetails);
				
			ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.Organization Then
				Organization = FinReports.ValueOfAdditionalProps(Item.ReportItem, "Organization", CacheAdditionalBankingDetails);
				DimensionName = "Organization";
				ValueOfFilter = Organization;
				
			ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.Department Then
				Department = FinReports.ValueOfAdditionalProps(Item.ReportItem, "Department", CacheAdditionalBankingDetails);
				DimensionName = "Department";
				ValueOfFilter = Department;
				
			ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.Scenario Then
				Scenario = FinReports.ValueOfAdditionalProps(Item.ReportItem, "Scenario", CacheAdditionalBankingDetails);
				DimensionName = "Scenario";
				ValueOfFilter = Scenario;
				
			ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.Currency Then
				Currency = FinReports.ValueOfAdditionalProps(Item.ReportItem, "Currency", CacheAdditionalBankingDetails);
				DimensionName = "Currency";
				ValueOfFilter = Currency;
				
			ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.FixedDimension Then
				DimensionKind = FinReports.ValueOfAdditionalProps(Item.ReportItem, "DimensionKind", CacheAdditionalBankingDetails);
				ThisIsDimensionOther = FinReports.ValueOfAdditionalProps(Item.ReportItem, "ThisIsDimensionOther", CacheAdditionalBankingDetails);
				EnableEdit = FinReports.ValueOfAdditionalProps(Item.ReportItem, "EnableEdit", CacheAdditionalBankingDetails);
				DimensionName = FinancialReportingCached.NameOfBudgetReportField(DimensionKind);
				If ThisIsDimensionOther Then
					NameOfOther = BudgetReportingClientServer.PresentationOfOtherBudgetingAnalytics(DimensionKind, "OtherItems");
					ValueOfFilter = BudgetingClientServer.EmptyDimensionValue();
				Else
					FilterValueType = Common.ObjectAttributeValue(DimensionKind, "ValueType");
					ValueOfFilter    = BudgetingClientServer.ReducedAnalyticsValue(
						Common.ObjectAttributeValue(Item.ReportItem, "DimensionValue"), FilterValueType);
				EndIf;
				
			EndIf;
				
			NewGrouping = AddOutputTreeGrouping(PlaceAdded, DimensionName, Item.ReportItem, Item.ItemKind);
			NewGrouping.FixedValue = ValueOfFilter;
			If ThisIsDimensionOther = True Then
				NewGrouping.NameForPrinting = NameOfOther;
			EndIf;
			NewGrouping.DimensionKind = DimensionKind;
			NewGrouping.ThisIsDimensionOther = ThisIsDimensionOther;
			NewGrouping.EditedValues = EnableEdit = True;
			
			DisplayWithParent = FinReports.ValueOfAdditionalProps(Item.ReportItem, "DisplayWithParent", CacheAdditionalBankingDetails);
			If DisplayWithParent = True Then
				PlaceAdded.OutputTogetherWithSubordinate = True;
				NewGrouping.DisplayWithParent = True;
			EndIf;
			
			ShowItemHierarchy = FinReports.ValueOfAdditionalProps(Item.ReportItem, "ShowItemHierarchy", CacheAdditionalBankingDetails);
			If ShowItemHierarchy = True Then
				NewGrouping.ShowItemHierarchy = True;
			EndIf;
			
			PresentationExpression = FinReports.ValueOfAdditionalProps(Item.ReportItem, "PresentationExpression", CacheAdditionalBankingDetails);
			If Not IsBlankString(PresentationExpression) Then
				NewGrouping.PresentationExpression = PresentationExpression;
			EndIf;
			
			SortingExpression = FinReports.ValueOfAdditionalProps(Item.ReportItem, "SortingExpression", CacheAdditionalBankingDetails);
			If Not IsBlankString(SortingExpression) Then
				NewGrouping.SortingExpression = SortingExpression;
			EndIf;
			
		ElsIf Item.ItemKind = Enums.FinancialReportItemKinds.TableIndicatorsInColumns
			Or Item.ItemKind = Enums.FinancialReportItemKinds.TableIndicatorsInRows
			Or Item.ItemKind = Enums.FinancialReportItemKinds.ComplexTable Then
			
			Table = AddOutputTreeGrouping(PlaceAdded, "Table", Item.ReportItem, Item.ItemKind);
			Table.DisplayTitleInReport = Item.DisplayItemTitle;
			Table.NameForPrinting = Item.NameForPrinting;
			
			DisplayGroupingTitle = FinReports.ValueOfAdditionalProps(Item.ReportItem, "DisplayGroupingTitle", CacheAdditionalBankingDetails);
			GroupHeader = FinReports.ValueOfAdditionalProps(Item.ReportItem, "GroupHeader", CacheAdditionalBankingDetails);
			DisplayHeadersVertically = FinReports.ValueOfAdditionalProps(Item.ReportItem, "DisplayHeadersVertically", CacheAdditionalBankingDetails);
			
			Table.TableParameters.Insert("DisplayGroupingTitle", DisplayGroupingTitle = True);
			Table.TableParameters.Insert("GroupHeader", 	GroupHeader);
			Table.TableParameters.Insert("DisplayHeadersVertically", DisplayHeadersVertically = True);
			
			CreateRecursivelyGroupingOutputTree(BudgetProfile, CacheAdditionalBankingDetails, Table, Item);
			
		ElsIf Item.ItemKind = Enums.FinancialReportItemKinds.Rows Then
			
			Table = AddOutputTreeGrouping(PlaceAdded, "Rows", Item.ReportItem, Item.ItemKind);
			CreateRecursivelyGroupingOutputTree(BudgetProfile, CacheAdditionalBankingDetails, Table, Item);
			
		ElsIf Item.ItemKind = Enums.FinancialReportItemKinds.Columns Then
			
			Table = AddOutputTreeGrouping(PlaceAdded, "Columns", Item.ReportItem, Item.ItemKind);
			CreateRecursivelyGroupingOutputTree(BudgetProfile, CacheAdditionalBankingDetails, Table, Item);
			
		ElsIf Item.ItemKind = Enums.FinancialReportItemKinds.DerivedItem
			Or Item.ItemKind = Enums.FinancialReportItemKinds.RowColumn
			Or Item.ItemKind = Enums.FinancialReportItemKinds.Group
			Or Item.ItemKind = Enums.FinancialReportItemKinds.GroupFormula Then
			
			Output = True;
			If Item.ItemKind = Enums.FinancialReportItemKinds.Group Then
				If Item.DisplayItemTitle = False Then
					NewGrouping = PlaceAdded;
					Output = False;
				EndIf;
			EndIf;
			
			If Output Then
				
				NewGrouping = AddOutputTreeGrouping(PlaceAdded, 
					FinancialReportingCached.NameOfBudgetReportField(Item.ReportItem), 
					Item.ReportItem, Item.ItemKind);
				
				NewGrouping.NameForPrinting = Item.NameForPrinting;
				
			EndIf;
			
		ElsIf Item.ItemKind = Enums.FinancialReportItemKinds.CellsSettings Then
			
			DisplayColumnNumbering = FinReports.ValueOfAdditionalProps(Item.ReportItem,
			                                                                        "DisplayColumnNumbering",
			                                                                        CacheAdditionalBankingDetails);
			DisplayRowsNumbering = FinReports.ValueOfAdditionalProps(Item.ReportItem,
			                                                                      "DisplayRowsNumbering",
			                                                                      CacheAdditionalBankingDetails);
			Table = FinancialReportingServer.ElementTable(PlaceAdded);
			
			Table.TableParameters.Insert("DisplayColumnNumbering", DisplayColumnNumbering = True);
			Table.TableParameters.Insert("DisplayRowsNumbering", 	DisplayRowsNumbering = True);
			
			ElementTables = Common.ObjectAttributesValues(Item.ReportItem, 
				"AppearanceItems, RegisteredRows, DesigningColumns, DrillDownOfAppearanceItemFilterFields");
			
			Table.TableParameters.Insert("AppearanceItems", 		ElementTables.AppearanceItems.Unload());
			Table.TableParameters.Insert("RegisteredRows", 			ElementTables.RegisteredRows.Unload());
			Table.TableParameters.Insert("DesigningColumns", 		ElementTables.DesigningColumns.Unload());
			Table.TableParameters.Insert("DrillDownOfAppearanceItemFilterFields", 	ElementTables.DrillDownOfAppearanceItemFilterFields.Unload());
			
			Table.TableParameters.Insert("ReportDataForFormatting", 	ReportDataForFormatting(Table.TableParameters, CacheAdditionalBankingDetails));
			
		EndIf;
		
		If NewGrouping <> Undefined Then
			
			CreateRecursivelyGroupingOutputTree(BudgetProfile, CacheAdditionalBankingDetails, NewGrouping, Item);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure SignsOfAccountingByTreeRows(Rows, AccountingFlags, ThereIsSum, ThereIsQuantity, ThereIsValue)
	
	For Each String In Rows Do
		
		FoundColumn = AccountingFlags.Find(String.ReportItem);
		
		If FoundColumn <> Undefined Then
			ThereIsSum = ThereIsSum Or FoundColumn.FlagSum;
			ThereIsQuantity = ThereIsQuantity Or FoundColumn.FlagCount;
			ThereIsValue = ThereIsValue Or FoundColumn.FlagValue;
		EndIf;
		
		If ThereIsSum And ThereIsQuantity And ThereIsValue Then
			Return;
		EndIf;
		
		SignsOfAccountingByTreeRows(String.Rows, AccountingFlags, ThereIsSum, ThereIsQuantity, ThereIsValue);
		
	EndDo;
	
EndProcedure

Procedure AddQuantityColumnsToColumns(Table, AccountingParametersByColumn, AddLine = Undefined)
	
	If AddLine = Undefined Then
		AddLine = Table.Rows.Find("Columns");
	EndIf;
	
	If Not AddLine.Rows.Count() Then
		
		AccountingFlags = AccountingParametersByColumn.SignsOfAccountingByColumn.ColumnsTable1;
		ThereIsQuantityInReport = AccountingParametersByColumn.ThereIsQuantity;
		ThereIsValueInReport = AccountingParametersByColumn.ThereIsValue;
		
		If AddLine.DimensionName = "Columns" Then
			Rows = Table.Rows.Find("Rows").Rows;
			ThereIsSum = False;
			ThereIsQuantity = False;
			ThereIsValue = False;
			// calculation of flags for a simple table
			SignsOfAccountingByTreeRows(Rows, 
				AccountingParametersByColumn.SignsOfAccountingByColumn.TableOfRows, ThereIsSum, ThereIsQuantity, ThereIsValue);
		ElsIf AddLine.DimensionName = "EditedValue" Then
			ThereIsSum = False;
			ThereIsQuantity = False;
			ThereIsValue = True;
		Else
			FoundColumn = AccountingFlags.Find(AddLine.ReportItem);
			If FoundColumn <> Undefined Then
				ThereIsSum = FoundColumn.FlagSum;
				ThereIsQuantity = FoundColumn.FlagCount;
				ThereIsValue = FoundColumn.FlagValue;
			Else
				ThereIsSum = False;
				ThereIsQuantity = False;
				ThereIsValue = False;
			EndIf;
		EndIf;
		
		If ThereIsQuantity Then
			NewRow = AddLine.Rows.Add();
			NewRow.DimensionName = "#Factor_Count";
			NewRow.NameForPrinting = NStr("vi = 'Số lượng';
											|ru = 'Количество';
											|en = 'Quantity'; fa = 'مقدار';
											|it = 'Quantità';
											|pl = 'Ilość';
											|tr = 'Miktar'");
		EndIf;
		
		If ThereIsValue Then
			NewRow = AddLine.Rows.Add();
			NewRow.DimensionName = "#Factor_Value";
			NewRow.NameForPrinting = NStr("vi = 'Giá trị';
											|ru = 'Значение';
											|en = 'Value'; fa = 'مقدار';
											|it = 'Valore';
											|pl = 'Wartość';
											|tr = 'Değer'");
		EndIf;
		
		AddAmount = False;
		
		ThereAreAdditionalColumns = ThereIsQuantity Or ThereIsValue;
		
		If ThereIsSum And ThereAreAdditionalColumns Then
			AddAmount = True;
		ElsIf Not ThereAreAdditionalColumns And AddLine.DimensionName = "Columns" Then
			AddAmount = True;
		ElsIf Not ThereAreAdditionalColumns And (ThereIsQuantityInReport Or ThereIsValueInReport) Then
			AddAmount = True;
		ElsIf AddLine.ShowItemHierarchy
			And ChartsOfCharacteristicTypes.BudgetFlowItemDimensions.HierarchyOfAnalyticsValuesIsUsed(
			AddLine.DimensionKind, True) Then
			AddAmount = True;
		EndIf;
		
		If AddAmount Then
			NewRow = AddLine.Rows.Add();
			NewRow.DimensionName = "#Factor_Sum";
			NewRow.NameForPrinting = NStr("vi = 'Tổng số';
											|ru = 'Сумма';
											|en = 'Amount'; fa = 'مبلغ';
											|it = 'Importo';
											|pl = 'Wartość';
											|tr = 'Tutar'");
		EndIf;
		
		Return;
	EndIf;
	
	For Each String In AddLine.Rows Do
		AddQuantityColumnsToColumns(Table, AccountingParametersByColumn, String);
	EndDo;
	
EndProcedure

Function SignsOfAccountingByColumnsAndRows(CellStructure, CellParameters)
	
	Query = New Query;
	Query.Text = 
	"SELECT
		|	CellStructure.RowIndex AS RowIndex,
		|	CellStructure.String,
		|	CellStructure.Column
		|INTO TableCellStructure
		|FROM
		|	&CellStructure AS CellStructure
		|WHERE
		|	CellStructure.MainItem
		|
		|INDEX BY
		|	RowIndex
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CellParameters.RowIndex AS RowIndex,
		|	CellParameters.FlagSum,
		|	CellParameters.FlagCount,
		|	CellParameters.FlagValue
		|INTO TableCellParameters
		|FROM
		|	&CellParameters AS CellParameters
		|
		|INDEX BY
		|	RowIndex
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CellStructure.String,
		|	CellStructure.Column,
		|	CellParameters.FlagSum,
		|	CellParameters.FlagCount,
		|	CellParameters.FlagValue
		|INTO CellStructure
		|FROM
		|	TableCellStructure AS CellStructure
		|		INNER JOIN TableCellParameters AS CellParameters
		|		ON CellStructure.RowIndex = CellParameters.RowIndex
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CellStructure.Column,
		|	MAX(CellStructure.FlagSum) AS FlagSum,
		|	MAX(CellStructure.FlagCount) AS FlagCount,
		|	MAX(CellStructure.FlagValue) AS FlagValue
		|FROM
		|	CellStructure AS CellStructure
		|
		|GROUP BY
		|	CellStructure.Column
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CellStructure.String,
		|	MAX(CellStructure.FlagSum) AS FlagSum,
		|	MAX(CellStructure.FlagCount) AS FlagCount,
		|	MAX(CellStructure.FlagValue) AS FlagValue
		|FROM
		|	CellStructure AS CellStructure
		|
		|GROUP BY
		|	CellStructure.String";
	
	Query.SetParameter("CellStructure", CellStructure.Copy(, "RowIndex, MainItem, String, Column"));
	Query.SetParameter("CellParameters", CellParameters.Copy(, "RowIndex, FlagSum, FlagCount, FlagValue"));
	
	Array = Query.ExecuteBatch();
	ColumnsTable1 = Array[3].Unload(); // ValueTable
	ColumnsTable1.Indexes.Add("Column");
	
	TableOfRows = Array[4].Unload();  // ValueTable
	TableOfRows.Indexes.Add("String");
	
	Return New Structure("ColumnsTable1, TableOfRows", ColumnsTable1, TableOfRows);
	
EndFunction

// Key operation: "Budgeting.Calculationcashrecievementreferences"
//
Function OutputTree(BudgetProfile, CellStructure, CellParameters)
	
	SetPrivilegedMode(True);
	
	TypeOfCacheElement = Enums.BudgetCacheKinds.OutputTree;
	Value = InformationRegisters.CacheOfAuxiliaryBudgetProfileData.GetCacheValue(BudgetProfile, TypeOfCacheElement);
	If Value <> Undefined Then
		SetPrivilegedMode(False);
		Return Value;
	EndIf;
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("Budgeting.CacheCalculationGettingTreeForReportOutput");
	
	OutputTree = CacheCalculationGettingTreeForReportOutput(BudgetProfile, CellStructure, CellParameters, TypeOfCacheElement);
	
	DataVolume = NumberOfValueTreeElements(OutputTree);
	
	SetPrivilegedMode(False);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, DataVolume);
	
	Return OutputTree;
	
EndFunction

// Output tree constructor function
// 
// Returns:
// 	ValueTree - LongDesc:
// * DimensionName - String -
// * ItemKind - EnumRef.FinancialReportItemKinds -
// * ReportItem - CatalogRef.FinancialReportItems -
// * DimensionKind - ChartOfCharacteristicTypesRef.ItemAttributesOfFinancialReports -
// * NameForPrinting - String -
// * FixedValue - Arbitrary -
// * DisplayTitleInReport - Boolean -
// * ThisIsDimensionOther - Boolean -
// * EditedValues - Boolean -
// * OutputTogetherWithSubordinate - Boolean -
// * DisplayWithParent - Boolean -
// * AdditionalFields - ValueTable -
// * TableParameters - Structure - Contains:
// 		** DisplayGroupingTitle - Boolean -
// 		** GroupHeader - String -
// 		** DisplayHeadersVertically - Boolean -
// 		** DisplayColumnNumbering - Boolean -
// 		** DisplayRowsNumbering - Boolean -
// 		** AppearanceItems - ValueTable -
// 		** RegisteredRows - ValueTable -
// 		** DesigningColumns - ValueTable -
// 		** DrillDownOfAppearanceItemFilterFields - ValueTable -
// 		** ReportDataForFormatting - See ReportDataForFormatting
// * OnlyForPrinting - Boolean -
Function NewOutputTree() Export
	
	OutputTree = New ValueTree;
	OutputTree.Columns.Add("DimensionName");
	OutputTree.Columns.Add("ItemKind");
	OutputTree.Columns.Add("ReportItem");
	OutputTree.Columns.Add("DimensionKind");
	OutputTree.Columns.Add("NameForPrinting");
	OutputTree.Columns.Add("PresentationExpression");
	OutputTree.Columns.Add("SortingExpression");
	OutputTree.Columns.Add("FixedValue");
	OutputTree.Columns.Add("DisplayTitleInReport");
	OutputTree.Columns.Add("ThisIsDimensionOther", 			New TypeDescription("Boolean"));
	OutputTree.Columns.Add("EditedValues", 			New TypeDescription("Boolean"));
	OutputTree.Columns.Add("OutputTogetherWithSubordinate", 	New TypeDescription("Boolean"));
	OutputTree.Columns.Add("DisplayWithParent", 	New TypeDescription("Boolean"));
	OutputTree.Columns.Add("AdditionalFields", 			New TypeDescription("ValueTable"));
	OutputTree.Columns.Add("TableParameters", 				New TypeDescription("Structure"));
	OutputTree.Columns.Add("OnlyForPrinting", 				New TypeDescription("Number", New NumberQualifiers(5,0)));
	OutputTree.Columns.Add("ShowItemHierarchy",		New TypeDescription("Boolean"));
	
	Return OutputTree;
	
EndFunction

Function CacheCalculationGettingTreeForReportOutput(BudgetProfile, CellStructure, CellParameters, TypeOfCacheElement) Export
	
	BudgetViewTree = BudgetItemTree(BudgetProfile, False);
	
	SignsOfAccountingByColumn = SignsOfAccountingByColumnsAndRows(CellStructure, CellParameters);
	TableOfColumnAttributes = SignsOfAccountingByColumn.ColumnsTable1;
	
	ThereIsSum 		= TableOfColumnAttributes.Find(True, "FlagSum") <> Undefined;
	ThereIsQuantity 	= TableOfColumnAttributes.Find(True, "FlagCount") <> Undefined;
	ThereIsValue 	= TableOfColumnAttributes.Find(True, "FlagValue") <> Undefined;
	
	AccountingParametersByColumn = New Structure();
	AccountingParametersByColumn.Insert("SignsOfAccountingByColumn", SignsOfAccountingByColumn);
	AccountingParametersByColumn.Insert("ThereIsSum", ThereIsSum);
	AccountingParametersByColumn.Insert("ThereIsQuantity", ThereIsQuantity);
	AccountingParametersByColumn.Insert("ThereIsValue", ThereIsValue);
	
	OutputTree = NewOutputTree();
	
	CacheOfAdditionalBankingDetails = FinancialReportingServer.CacheAdditionalDetails(BudgetProfile);
	
	// Filling the tree with groupings
	CreateRecursivelyGroupingOutputTree(BudgetProfile, CacheOfAdditionalBankingDetails, OutputTree, BudgetViewTree);
	
	FillInAdditionalDimensionFieldsInOutputTree(BudgetProfile, OutputTree);
	
	// Adding additional columns and filling
	// in auxiliary information.
	For Each OutputItem In OutputTree.Rows Do
		
		If OutputItem.DimensionName = "Table" Then
			OutputItem.TableParameters.Insert("NumberOfAdditionalColumns", CalculateDepthOfLevels(OutputItem, True) - 1);
			If ValueIsFilled(OutputItem.ReportItem) Then
				If OutputItem.ItemKind = Enums.FinancialReportItemKinds.ComplexTable Then
					Continue;
				EndIf;
			EndIf;
			AddQuantityColumnsToColumns(OutputItem, AccountingParametersByColumn);
		EndIf;
		
	EndDo;
	
	InformationRegisters.CacheOfAuxiliaryBudgetProfileData.SetCacheValue(BudgetProfile, TypeOfCacheElement, OutputTree);
	
	Return OutputTree;
	
EndFunction

#EndRegion

#Region StructureOfBudgetProfileDescription

Function CheckUseOfNonFixedElementsInDimensionsAndOperands(BudgetProfile, StructureDescriptionOfReport)
	
	ResultOperands = TableOfOperandsRequiringCalculationOfCellData(StructureDescriptionOfReport);
	DoesNotRequireCalculationOfCellData = ResultOperands.IsEmpty();
	
	Return DoesNotRequireCalculationOfCellData;
	
EndFunction

Function GetAdditionalFilterValues(Table, ColumnName)
	
	Copy = Table.Copy(,ColumnName + ", Flag" + ColumnName);
	Copy.GroupBy(ColumnName + ", Flag" + ColumnName);
	
	Result = New Array;
	
	For Each Value In Copy Do
		If Value["Flag" + ColumnName] <> "pick" Then
			Return Undefined;
		EndIf;
		If Not ValueIsFilled(Value[ColumnName]) Then
			Return Undefined;
		EndIf;
		Result.Add(Value[ColumnName]);
	EndDo;
	
	If Result.Count() Then
		Return CommonClientServer.CollapseArray(Result);
	EndIf;
	
	Return Undefined;
	
EndFunction

Procedure AugmentDataSourcesWithPredefinedValues(DataSources, ColumnStructureOfDataTable, CellStructure)
	
	For Each Source In DataSources Do
		
		FoundRows = CellStructure.Copy(New Structure("ID_Source1", Source.Id));
		
		For Each Dimension In ColumnStructureOfDataTable.Dimensions Do
			
			DifferentValues = GetAdditionalFilterValues(FoundRows, Dimension);
			If DifferentValues <> Undefined Then
				
				Source.Insert(Dimension, DifferentValues);
				
			EndIf;
			
		EndDo;
		
		For Each Dimension In ColumnStructureOfDataTable.DimensionKinds Do
			
			FieldName = FinancialReportingCached.NameOfBudgetReportField(Dimension);
			DifferentValues = GetAdditionalFilterValues(FoundRows, FieldName);
			If DifferentValues <> Undefined Then
				
				Source.Insert(FieldName, DifferentValues);
				
			EndIf;
			
		EndDo;
		
	EndDo
	
EndProcedure

Function ReportSourceFields(ColumnStructure1, CellStructure, CellParameters)
	
	Query = New Query();
	Query.Text =
	"SELECT
	|	CellStructure.RowIndex AS RowIndex
	|INTO CellStructure
	|FROM
	|	&CellStructure AS CellStructure
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CellParameters.RowIndex AS RowIndex,
	|	CellParameters.FlagSum AS FlagSum,
	|	CellParameters.FlagCount AS FlagCount,
	|	CellParameters.FlagValue AS FlagValue,
	|	CellParameters.SourceField AS SourceField
	|INTO CellParameters
	|FROM
	|	&CellParameters AS CellParameters
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CellParameters.RowIndex AS RowIndex,
	|	CellParameters.FlagSum AS FlagSum,
	|	CellParameters.FlagCount AS FlagCount,
	|	CellParameters.FlagValue AS FlagValue,
	|	CellParameters.SourceField AS SourceField
	|INTO PreliminarySourceFields
	|FROM
	|	CellStructure AS CellStructure
	|		INNER JOIN CellParameters AS CellParameters
	|		ON CellStructure.RowIndex = CellParameters.RowIndex
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	""OpeningBalance"" AS SourceField
	|INTO TypesOfSourceFields
	|
	|UNION ALL
	|
	|SELECT
	|	""ClosingBalance""
	|
	|UNION ALL
	|
	|SELECT
	|	""Receipt""
	|
	|UNION ALL
	|
	|SELECT
	|	""Expense""
	|
	|UNION ALL
	|
	|SELECT
	|	""Turnover""
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PreliminarySourceFields.RowIndex AS RowIndex,
	|	PreliminarySourceFields.FlagSum AS FlagSum,
	|	PreliminarySourceFields.FlagCount AS FlagCount,
	|	PreliminarySourceFields.FlagValue AS FlagValue,
	|	ISNULL(TypesOfSourceFields.SourceField, PreliminarySourceFields.SourceField) AS SourceField,
	|	CASE
	|		WHEN TypesOfSourceFields.SourceField <> PreliminarySourceFields.SourceField
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS Auxiliary_
	|INTO CellTable
	|FROM
	|	PreliminarySourceFields AS PreliminarySourceFields
	|		LEFT JOIN TypesOfSourceFields AS TypesOfSourceFields
	|		ON (PreliminarySourceFields.SourceField = TypesOfSourceFields.SourceField
	|				OR PreliminarySourceFields.SourceField = ""Turnover""
	|					AND TypesOfSourceFields.SourceField IN (""Receipt"", ""Expense"")
	|				OR PreliminarySourceFields.SourceField = ""ClosingBalance""
	|					AND TypesOfSourceFields.SourceField IN (""OpeningBalance"", ""Receipt"", ""Expense"")
	|				OR PreliminarySourceFields.SourceField = ""OpeningBalance""
	|					AND TypesOfSourceFields.SourceField IN (""Receipt"", ""Expense""))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	""Sum"" + CellStructure.SourceField AS ResourceName,
	|	CellStructure.Auxiliary_ AS Auxiliary_
	|INTO ResourceNames
	|FROM
	|	CellTable AS CellStructure
	|WHERE
	|	CellStructure.FlagSum
	|	AND CellStructure.SourceField <> """"
	|
	|UNION ALL
	|
	|SELECT
	|	""SumCurr"" + CellStructure.SourceField,
	|	CellStructure.Auxiliary_
	|FROM
	|	CellTable AS CellStructure
	|WHERE
	|	CellStructure.FlagSum
	|	AND CellStructure.SourceField <> """"
	|
	|UNION ALL
	|
	|SELECT
	|	""Count"" + CellStructure.SourceField,
	|	CellStructure.Auxiliary_
	|FROM
	|	CellTable AS CellStructure
	|WHERE
	|	CellStructure.FlagCount
	|	AND CellStructure.SourceField <> """"
	|
	|UNION ALL
	|
	|SELECT
	|	""IndicatorValue"",
	|	CellStructure.Auxiliary_
	|FROM
	|	CellTable AS CellStructure
	|WHERE
	|	CellStructure.FlagValue
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ResourceNames.ResourceName AS ResourceName,
	|	MIN(ResourceNames.Auxiliary_) AS Auxiliary_
	|FROM
	|	ResourceNames AS ResourceNames
	|
	|GROUP BY
	|	ResourceNames.ResourceName";
	
	Query.SetParameter("CellStructure", CellStructure.Copy(, "RowIndex"));
	Query.SetParameter("CellParameters", CellParameters.Copy(, "RowIndex, FlagSum, FlagCount, FlagValue, SourceField"));
	
	Return Query.Execute().Unload();

EndFunction

Function CalculatingAndObtainingDescriptionStructure(BudgetProfile, ColumnStructureOfDataTable, GenerationMode, TypeOfCacheElement, Postfix)
	// Getting data sources.
	DataSources = GetDescriptionOfDataSources(BudgetProfile, ColumnStructureOfDataTable, GenerationMode);
	
	// We get data sources of groupings by period.
	SourcesOfGroupingPeriods = SourcesOfGroupingPeriods(BudgetProfile, ColumnStructureOfDataTable, GenerationMode);
	
	// We get the cell structure.
	DescriptionOfCells = DescriptionOfCells(BudgetProfile,
			DataSources,
			SourcesOfGroupingPeriods,
			ColumnStructureOfDataTable,
			GenerationMode);
	
	CellStructure 						= DescriptionOfCells.CellStructure;
	CellParameters 						= DescriptionOfCells.CellParameters;
	SourcesOfMeasurementValues 			= DescriptionOfCells.SourcesOfMeasurementValues;
	FillingInMissingNFPMeasurements = DescriptionOfCells.FillingInMissingNFPMeasurements;
	SelectionOfNFPMeasurements 					= DescriptionOfCells.SelectionOfNFPMeasurements;
	
	// Addition of sources with permanent filters.
	AugmentDataSourcesWithPredefinedValues(DataSources, ColumnStructureOfDataTable, CellStructure);
	
	ArrayOfIndexes = New Array;
	For Each TableRow In CellStructure Do
		
		GeneralMeasurements = CellParameters[TableRow.RowIndex].GeneralMeasurements;
		
		If ValueIsFilled(GeneralMeasurements)
			And ArrayOfIndexes.Find(GeneralMeasurements) = Undefined Then
			
			ArrayOfIndexes.Add(GeneralMeasurements);
			
		EndIf;
	EndDo;
	
	SourceFields_2 = ReportSourceFields(ColumnStructureOfDataTable, CellStructure, CellParameters);
	TableOfSubordination = SubordinateElementsOfBudgetView(BudgetProfile);
	
	Result = New Structure;
	Result.Insert("DataSources", 						DataSources);
	Result.Insert("SourcesOfGroupingPeriods", 			SourcesOfGroupingPeriods);
	Result.Insert("CellStructure", 						CellStructure);
	Result.Insert("CellParameters", 						CellParameters);
	Result.Insert("CellStructureIndexes", 				ArrayOfIndexes);
	Result.Insert("SourceFields_2", 						SourceFields_2);
	Result.Insert("SourcesOfMeasurementValues", 			SourcesOfMeasurementValues);
	Result.Insert("FillingInMissingNFPMeasurements", 	FillingInMissingNFPMeasurements);
	Result.Insert("SelectionOfNFPMeasurements", 					SelectionOfNFPMeasurements);
	Result.Insert("TableOfSubordinationOfElements",			TableOfSubordination);
	
	// In case the report has a "rigid" structure, the attribute 
	// is saved so as not to perform additional calculations during output.
	DoesNotRequireCalculationOfCellData = CheckUseOfNonFixedElementsInDimensionsAndOperands(BudgetProfile, Result);
	
	Result.Insert("DoesNotRequireCalculationOfCellData",			DoesNotRequireCalculationOfCellData);
	
	InformationRegisters.CacheOfAuxiliaryBudgetProfileData.SetCacheValue(BudgetProfile, TypeOfCacheElement, Result, Postfix);
	
	Return Result;
EndFunction

#EndRegion

#Region InputListDescriptionStructure

Function TextOfIncompatibleElements()
	
	Return NStr("vi = 'Các dòng phụ có các yếu tố không tương thích';
				|ru = 'В подчиненных строках есть несовместимые элементы';
				|en = 'There are incompatible items in the subordinate lines'; fa = 'There are incompatible items in the subordinate lines';
				|it = 'Nelle righe subordinate ci sono elementi incompatibili';
				|pl = 'W wierszach podporządkowanych są nieodpowiednie elementy';
				|tr = 'Alt satırlarda uyumsuz öğeler var'");
	
EndFunction

// Returns a template of parameters for generating a header in the current user's language.
// The "Header" property of the "column Settings" structure is used in
// the budget Instance document Manager module in the "calculate elements of the budget add-on list" method
// to generate a hint for entering an empty value.
//
// Returns:
//  Structure - The structure of the properties for forming the header in the user's language:
//   *ItemKind - EnumRef.FinancialReportItemKinds - The only required parameter.
//                                                                       Or Budget articles or Measurement or Fixed analytics.
//   *DimensionType  - EnumRef.TypesOfBudgetReportDimensions -  Optional parameter.
//                    It is uncertain.
//   *Periodicity - EnumRef.Periodicity - Optional parameter.
//                    It is uncertain.
//   *DimensionKind  - ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions - Optional parameter.
//                    It is uncertain.
//
Function TemplateForInputListFormationParameters()
	Result = New Structure;
	
	// Required parameters:
	Result.Insert("ItemKind");
	
	// Optional parameters:
	Result.Insert("DimensionType");
	Result.Insert("Periodicity");
	Result.Insert("DimensionKind");
	
	Return Result;
EndFunction

Function InputListItemParameters(BudgetInformationForCalculation, ReportItem, OverlyingColumns) Export
	
	CacheAdditionalBankingDetails 	= BudgetInformationForCalculation.CacheAdditionalBankingDetails;
	HeaderDimensions 		= BudgetInformationForCalculation.HeaderDimensions;
	
	If ReportItem.ItemKind = Enums.FinancialReportItemKinds.BudgetFlowItem Then
		TypesArray = New Array;
		TypesArray.Add(Type("CatalogRef.BudgetFlowItems"));
		TypesArray.Add(Type("CatalogRef.BudgetBalanceItems"));
		ValueType = New TypeDescription(TypesArray);
		
		ParametersForCreatingInputList = TemplateForInputListFormationParameters();
		ParametersForCreatingInputList.ItemKind = ReportItem.ItemKind;
		
		Result = New Structure("ParametersForCreatingInputList, ValueType");
		Result.ParametersForCreatingInputList = ParametersForCreatingInputList;
		Result.ValueType = ValueType;
		Return Result;
	EndIf;
	
	If ReportItem.ItemKind = Enums.FinancialReportItemKinds.Dimension Then
		
		DimensionType = FinancialReportingServer.ValueOfAdditionalProps(
													ReportItem.ReportItem, "DimensionType", CacheAdditionalBankingDetails);
		
		If DimensionType = Enums.TypesOfBudgetReportDimensions.Period Then
														
			Periodicity = FinancialReportingServer.ValueOfAdditionalProps(
				ReportItem.ReportItem, "Periodicity", CacheAdditionalBankingDetails);
			
			ValueType = New TypeDescription("Date");
			
			ParametersForCreatingInputList = TemplateForInputListFormationParameters();
			ParametersForCreatingInputList.ItemKind   = ReportItem.ItemKind;
			ParametersForCreatingInputList.DimensionType  = DimensionType;
			ParametersForCreatingInputList.Periodicity = Periodicity;
			
			Result = New Structure("ParametersForCreatingInputList, ValueType");
			Result.ParametersForCreatingInputList = ParametersForCreatingInputList;
			Result.ValueType = ValueType;
			Return Result;
			
		ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.Currency Then
			
			ValueType = New TypeDescription("CatalogRef.Currencies");
			
			ParametersForCreatingInputList = TemplateForInputListFormationParameters();
			ParametersForCreatingInputList.ItemKind  = ReportItem.ItemKind;
			ParametersForCreatingInputList.DimensionType = DimensionType;
			Result = New Structure("ParametersForCreatingInputList, ValueType");
			Result.ParametersForCreatingInputList = ParametersForCreatingInputList;
			Result.ValueType = ValueType;
			Return Result;
			
		EndIf;
		
	EndIf;
	
	DimensionKind = FinancialReportingServer.ValueOfAdditionalProps(
		ReportItem.ReportItem, "DimensionKind", CacheAdditionalBankingDetails);
		
	ValueType = DimensionKind.ValueType;
	
	ParametersForCreatingInputList = TemplateForInputListFormationParameters();
	ParametersForCreatingInputList.ItemKind  = ReportItem.ItemKind;
	ParametersForCreatingInputList.DimensionKind = DimensionKind;
	
	Result = New Structure("ParametersForCreatingInputList, ValueType");
	Result.ParametersForCreatingInputList = ParametersForCreatingInputList;
	Result.ValueType = ValueType;
	
	If ValueType.Types().Find(Type("CatalogRef.ObjectsPropertiesValues")) <> Undefined Then
		
		ChoiceParameters = New Structure("Filter, Value", 
					"Owner", Common.ObjectAttributeValue(DimensionKind, "AdditionalProperty"));
		Result.Insert("ChoiceParameters", ChoiceParameters);
		
	Else
		
		MatchingRelatedElements = FinancialReportingCached.MatchingSelectionsByOwner();
		RelationshipStructure = Undefined;
		
		For Each Type In ValueType.Types() Do
			
			LinkedTypes = MatchingRelatedElements[Type];
			If LinkedTypes = Undefined Then
				Continue;
			EndIf;
			
			For Each KeyAndValue In OverlyingColumns Do
				If Not TypeOf(KeyAndValue.Value) = Type("Map") Then // Skip the link search for simple types of editable value
					For Each TypeOfOverlyingColumn In KeyAndValue.Value.ValueType.Types() Do
						CommunicationParameters = LinkedTypes.Find(TypeOfOverlyingColumn, "Type");
						If CommunicationParameters <> Undefined Then
							RelationshipStructure = New Structure("DataPath, Filter", 
									"Items.BudgetEditList.CurrentData." + KeyAndValue.Key, CommunicationParameters.Attribute);
							Break;
						EndIf;
					EndDo;
				EndIf;
			EndDo;
			
			If RelationshipStructure <> Undefined Then
				Break;
			EndIf;
			
			For Each AnalyticsLine_ In HeaderDimensions Do
				If Not TypeOf(AnalyticsLine_) = Type("Map") Then // Skip the link search for simple types of editable value
					For Each TypeOfOverlyingColumn In AnalyticsLine_.ValueType.Types() Do
						CommunicationParameters = LinkedTypes.Find(TypeOfOverlyingColumn, "Type");
						If CommunicationParameters <> Undefined Then
							RelationshipStructure = New Structure("DataPath, Filter", 
									"Object.Dimension" + AnalyticsLine_.LineNumber, CommunicationParameters.Attribute);
							Break;
						EndIf;
					EndDo;
				EndIf;
			EndDo;
			
			If RelationshipStructure <> Undefined Then
				Break;
			EndIf;
			
		EndDo;
		
		If RelationshipStructure <> Undefined Then
			Result.Insert("ChoiceParameterLinks", RelationshipStructure);
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function InputListColumnsAvailableForBudgetLine(BudgetInformationForCalculation, ReportItem, OverlyingElements)
	
	TableComplex_ 			= BudgetInformationForCalculation.TableComplex_;
	CacheAdditionalBankingDetails 		= BudgetInformationForCalculation.CacheAdditionalBankingDetails;
	StructureOfReportDescription = BudgetInformationForCalculation.StructureOfReportDescription;
	
	CurLevelElements = New Structure();
	CurLevelElements.Insert("Periodicity_", 	New Array);
	CurLevelElements.Insert("BaseLines", 	New Array);
	CurLevelElements.Insert("AccumulatedSelection", Common.CopyRecursive(OverlyingElements.AccumulatedSelection));
	CurLevelElements.Insert("ColumnSettings", Common.CopyRecursive(OverlyingElements.ColumnSettings));
	CurLevelElements.Insert("Dimensions", OverlyingElements.Dimensions);
	
	CellStructure = StructureOfReportDescription.CellStructure;
	CellParameters = StructureOfReportDescription.CellParameters;
	
	CommonClientServer.SupplementArray(
		CurLevelElements.Periodicity_,
		OverlyingElements.Periodicity_);
	
	CurLevelElements.BaseLines.Add(ReportItem.ReportItem);
	
	MatchingColumnArticles = New Map;
	FoundRows = CellStructure.FindRows(New Structure("MainItem, String", True, ReportItem.ReportItem));
	ThereIsEditedArticle = False;
	
	For Each FoundRow In FoundRows Do
		CellDescription = New Structure("BudgetFlowItem, IndicatorName, EditedValue", 
										FoundRow.BudgetFlowItem, Undefined, FoundRow.EditedValue);
		// If a complex table: different cells may have different indicators
		// for a simple table: one column is one indicator.
		ParametersString1 = CellParameters.Find(FoundRow.RowIndex, "RowIndex");
		If TableComplex_ Then
			If ParametersString1.FlagValue Then
				IndicatorName = "Value";
			ElsIf ParametersString1.FlagCount Then
				IndicatorName = "Count";
			Else
				IndicatorName = "Sum";
			EndIf;
			CellDescription.Insert("IndicatorName", IndicatorName);
		EndIf;
		If ParametersString1.FlagValue Then
			If FoundRow.ItemKind = Enums.FinancialReportItemKinds.EditedValue Then
				TypesOfMetricValues = New Map;
				If Not CurLevelElements.ColumnSettings.Property("TypesOfMetricValues", TypesOfMetricValues) Then
					TypesOfMetricValues = New Map;
					CurLevelElements.ColumnSettings.Insert("TypesOfMetricValues", TypesOfMetricValues);
				EndIf;
				TypesOfMetricValues.Insert(FoundRow.Column, ParametersString1.EditedValueType);
			EndIf;
		EndIf;
		MatchingColumnArticles.Insert(FoundRow.Column, CellDescription);
		If ValueIsFilled(FoundRow.BudgetFlowItem) Or ValueIsFilled(FoundRow.EditedValue) Then
			ThereIsEditedArticle = True;
		EndIf;
	EndDo;
	
	If Not ReportItem.Rows.Count() Then
		If Not ThereIsEditedArticle Then
			Return Undefined;
		EndIf;
	EndIf;
	
	If TableComplex_ Then
		CurLevelElements.Insert("BudgetFlowItems", MatchingColumnArticles);
	EndIf;
	
	If ReportItem.ItemKind = Enums.FinancialReportItemKinds.Dimension Then
		
		DimensionType = FinancialReportingServer.ValueOfAdditionalProps(
													ReportItem.ReportItem, "DimensionType", CacheAdditionalBankingDetails);
		If DimensionType = Enums.TypesOfBudgetReportDimensions.Period Then
			
			Periodicity = FinancialReportingServer.ValueOfAdditionalProps(
													ReportItem.ReportItem, "Periodicity", CacheAdditionalBankingDetails);
			CurLevelElements.Periodicity_.Add(Periodicity);
			CurLevelElements.ColumnSettings.Insert(FinancialReportingClientServer.PeriodStrings(Periodicity).Period,
				InputListItemParameters(BudgetInformationForCalculation, ReportItem, OverlyingElements.ColumnSettings));
			
			Return CurLevelElements;
			
		EndIf;
		
	EndIf;
	
	If ReportItem.ItemKind = Enums.FinancialReportItemKinds.Dimension
		Or ReportItem.ItemKind = Enums.FinancialReportItemKinds.BudgetFlowItem Then
		
		If ValueIsFilled(CurLevelElements.Dimensions) Then
			CurLevelElements.Dimensions = CurLevelElements.Dimensions + ",";
		Else
			CurLevelElements.Dimensions = "";
		EndIf;
		CurLevelElements.Dimensions = CurLevelElements.Dimensions + ReportItem.DimensionName;
		
		If ValueIsFilled(ReportItem.FixedValue)
			Or ReportItem.ThisIsDimensionOther Then
			RecordedValue = ReportItem.FixedValue;
			If ValueIsFilled(ReportItem.DimensionKind) Then
				RecordedValue = BudgetingClientServer.ReducedAnalyticsValue(
					RecordedValue, Common.ObjectAttributeValue(ReportItem.DimensionKind, "ValueType"));
			EndIf;
			CurLevelElements.AccumulatedSelection.Insert(ReportItem.DimensionName, RecordedValue);
			CurLevelElements.ColumnSettings.Insert(ReportItem.DimensionName, 
				InputListItemParameters(BudgetInformationForCalculation, ReportItem, OverlyingElements.ColumnSettings));
		EndIf;
		
		Return CurLevelElements;
		
	EndIf;
	
	If ReportItem.ItemKind = Enums.FinancialReportItemKinds.RowColumn Then
		
		Return CurLevelElements;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// LongDesc
// 
// Parameters:
// 	BudgetInformationForCalculation - See BudgetInformationForCalculation
// 	InputListString - Arbitrary -
// 	Dimensions - Array of String -
// 	AccumulatedSelection - Structure -
// Returns:
// 	Structure - description of the value:
// 	* Value - ValueList -
//
Function ListCellInputSettings(BudgetInformationForCalculation, InputListString, Dimensions, AccumulatedSelection)
	
	StructureOfReportDescription = BudgetInformationForCalculation.StructureOfReportDescription;
	ColumnStructure1 		= BudgetInformationForCalculation.ColumnStructureOfDataTable;
	CellStructure			= StructureOfReportDescription.CellStructure; // See NewCellStructure
	
	MeasurementTable = CellStructure.Copy(
							New Structure("MainItem, String", True, InputListString));
	
	ArrayOfDimensions_ = StringFunctionsClientServer.SplitStringIntoSubstringsArray(Dimensions);
	InputSettings = New Structure();
	
	For Each Dimension In ArrayOfDimensions_ Do
		
		TableCopy = MeasurementTable.Copy();
		TableCopy.GroupBy(Dimension + ", Flag" + Dimension);
		
		ListOfRowsWithHierarchy = BudgetReportingDisplayServer.ListOfSubordinateElements(InputListString, 
															BudgetInformationForCalculation.SubordinateElementsOfBudgetView);
		
		OptionalParameters = BudgetReportingDisplayServer.OptionalParametersForGettingSelectionOfCells();
		OptionalParameters.Column       = Undefined;
		OptionalParameters.String        = ListOfRowsWithHierarchy;
		OptionalParameters.SearchIndexes = Undefined;
		OptionalParameters.AddFlag = True;
		Selection = BudgetReportingDisplayServer.GetSelectionOfCellsHierarchically(StructureOfReportDescription.CellStructure, Dimension,
			AccumulatedSelection, OptionalParameters);
		
		ArrayOfSelectedValues = New ValueList;
		For Each TableRow In Selection Do
			If TableRow["Flag" + Dimension] = "pick" Then
				ArrayOfSelectedValues.Add(TableRow[Dimension]);
			ElsIf TableRow["Flag" + Dimension] = "otheritems" Then
				If ColumnStructure1.Dimensions.Find(Dimension) <> Undefined Then
					ArrayOfSelectedValues.Add(
						BudgetingClientServer.EmptyDimensionValue(),
						BudgetReportingClientServer.PresentationOfOtherBudgetingAnalytics(Dimension, "OtherItems"));
				Else
					For Each DimensionKind In ColumnStructure1.DimensionKinds Do
						DimensionName = FinancialReportingCached.NameOfBudgetReportField(DimensionKind);
						If DimensionName = Dimension Then
							ArrayOfSelectedValues.Add(
								BudgetingClientServer.EmptyDimensionValue(),
								BudgetReportingClientServer.PresentationOfOtherBudgetingAnalytics(DimensionKind, "OtherItems"));
							Break;
						EndIf;
					EndDo;
				EndIf;
			ElsIf TableRow["Flag" + Dimension] = "document" Then
				ArrayOfSelectedValues = Undefined;
				Break;
			ElsIf TableRow["Flag" + Dimension] = "fill" Then //Period
				ArrayOfSelectedValues = Undefined;
				Break;
			EndIf;
		EndDo;
		
		InputSettings.Insert(Dimension, ArrayOfSelectedValues);
		
	EndDo;
	
	Return InputSettings;
	
EndFunction

Function EditDimensionListIsDifferent(ComparisonElement1, ComparisonElement2, TableComplex_)
	
	If ComparisonElement1 = Undefined
		Or ComparisonElement2 = Undefined Then
		Return False;
	EndIf;
	
	If ComparisonElement1 = TextOfIncompatibleElements()
		Or ComparisonElement2 = TextOfIncompatibleElements() Then
		Return True;
	EndIf;
	
	If ComparisonElement1.Dimensions <> ComparisonElement2.Dimensions Then
		Return True;
	EndIf;
	
	MinimumPeriodicity1 = BudgetReportingClientServer.MinimumPeriodicity(ComparisonElement1.Periodicity_);
	MinimumPeriodicity2 = BudgetReportingClientServer.MinimumPeriodicity(ComparisonElement2.Periodicity_);
	
	If MinimumPeriodicity1 <> MinimumPeriodicity2 Then
		Return True;
	EndIf;
	
	If TableComplex_ Then
		For Each KeyAndValue In ComparisonElement1.BudgetFlowItems Do
			ArticlesSettings2 = ComparisonElement2.BudgetFlowItems[KeyAndValue.Key];
			If ArticlesSettings2 = Undefined Then
				Return True;
			EndIf;
			If KeyAndValue.Value = Undefined Then
				Return True;
			EndIf;
			If ArticlesSettings2.BudgetFlowItem <> KeyAndValue.Value.BudgetFlowItem
				Or ArticlesSettings2.IndicatorName <> KeyAndValue.Value.IndicatorName
				Or ArticlesSettings2.EditedValue <> KeyAndValue.Value.EditedValue Then
				Return True;
			EndIf;
		EndDo;
	EndIf;
	
	Return False;
	
EndFunction

Function CalculateColumnsOfInputList(BudgetInformationForCalculation, TreeItems, ResultingMap, OverlyingElements = Undefined)
	
	TableComplex_ = BudgetInformationForCalculation.TableComplex_;
	
	If OverlyingElements = Undefined Then
		
		OverlyingElements = New Structure();
		OverlyingElements.Insert("Periodicity_", New Array);
		OverlyingElements.Insert("AccumulatedSelection", New Structure);
		OverlyingElements.Insert("Dimensions", "");
		OverlyingElements.Insert("ColumnSettings", New Structure());
		OverlyingElements.Insert("BaseLines", New Array); 
		
	EndIf;
	
	ItemArray = New Array;
	LevelCompliance = New Map;
	
	For Each ReportItem In TreeItems.Rows Do
		
		PreviousLevelColumns = Undefined;
		CurLevelElements = InputListColumnsAvailableForBudgetLine(BudgetInformationForCalculation, ReportItem, OverlyingElements);
		
		If ReportItem.Rows.Count() Then
			
			NumberOfRecordsBeforeValidation = ResultingMap.Count();
			
			PreviousLevelColumns = CalculateColumnsOfInputList(BudgetInformationForCalculation,
				ReportItem,
				ResultingMap,
				?(CurLevelElements = Undefined, OverlyingElements, CurLevelElements));
			
			If PreviousLevelColumns = Undefined Then
				If NumberOfRecordsBeforeValidation <> ResultingMap.Count() Then
					ItemArray.Add(TextOfIncompatibleElements());
				Else
					ItemArray.Add(PreviousLevelColumns);
				EndIf;
				Continue;
			EndIf;
			
		EndIf;
		
		If PreviousLevelColumns <> Undefined Then
			ItemArray.Add(PreviousLevelColumns);
			If CurLevelElements <> Undefined Then
				PreviousLevelColumns.AccumulatedSelection = CurLevelElements.AccumulatedSelection;
			Else
				PreviousLevelColumns.AccumulatedSelection = OverlyingElements.AccumulatedSelection;
			EndIf;
			LevelCompliance.Insert(ReportItem.ReportItem, PreviousLevelColumns);
		ElsIf CurLevelElements <> Undefined Then
			ItemArray.Add(CurLevelElements);
			LevelCompliance.Insert(ReportItem.ReportItem, CurLevelElements);
		EndIf;
		
	EndDo;
	
	For Each KeyAndValue In LevelCompliance Do
		
		MinimumPeriodicity = BudgetReportingClientServer.MinimumPeriodicity(KeyAndValue.Value.Periodicity_);
		Dimensions = "";
		
		If MinimumPeriodicity <> Undefined Then
			Dimensions = FinancialReportingClientServer.PeriodStrings(MinimumPeriodicity).Period;
		EndIf;
		
		If ValueIsFilled(KeyAndValue.Value.Dimensions) Then
			Dimensions = Dimensions + ?(ValueIsFilled(Dimensions), ",", "") + KeyAndValue.Value.Dimensions;
		EndIf;
		
		InputSettings = ListCellInputSettings(BudgetInformationForCalculation, 
													KeyAndValue.Key, Dimensions, 
													KeyAndValue.Value.AccumulatedSelection);
		
		ArrayOfDimensions_ = StringFunctionsClientServer.SplitStringIntoSubstringsArray(Dimensions);
		
		StringDescriptionStructure = New Structure();
		StringDescriptionStructure.Insert("Dimensions", ArrayOfDimensions_);
		StringDescriptionStructure.Insert("ColumnSettings", KeyAndValue.Value.ColumnSettings);
		StringDescriptionStructure.Insert("InputSettings", InputSettings);
		StringDescriptionStructure.Insert("BaseLines", KeyAndValue.Value.BaseLines);
		
		If TableComplex_ Then
			StringDescriptionStructure.Insert("BudgetFlowItems", KeyAndValue.Value.BudgetFlowItems);
		EndIf;
		
		ResultingMap.Insert(KeyAndValue.Key, StringDescriptionStructure);
		
	EndDo;
	
	For Cnt = 1 To ItemArray.UBound() Do
		If EditDimensionListIsDifferent(ItemArray[Cnt-1], ItemArray[Cnt], TableComplex_) Then
			Return Undefined;
		EndIf;
	EndDo;
	
	If ItemArray.Count() = 1 And ItemArray[0] = TextOfIncompatibleElements() Then
		Return Undefined;
	EndIf;
	
	DefiningElement = Undefined;
	For Each Item In ItemArray Do
		If Item <> Undefined And Item <> TextOfIncompatibleElements() Then
			DefiningElement = Item;
			Break;
		EndIf;
	EndDo;
	
	If DefiningElement = Undefined Then
		Return Undefined;
	EndIf;
	
	BaseLines = New Array;
	For Each ArrayElement In ItemArray Do
		If ArrayElement = Undefined Or ArrayElement = TextOfIncompatibleElements() Then
			Continue;
		EndIf;
		CommonClientServer.SupplementArray(BaseLines, ArrayElement.BaseLines);
	EndDo;
	
	DefiningElement.BaseLines = BaseLines;
	
	// Let's establish the connections of the selection parameters by the lower elements
	MatchingRelatedElements = FinancialReportingCached.MatchingSelectionsByOwner();
	Cnt = 0;
	
	For Each SettingUpColumn In DefiningElement.ColumnSettings Do
		Cnt = Cnt + 1;
		SettingUpColumn = SettingUpColumn.Value;
		If TypeOf(SettingUpColumn) <>  Type("Structure") Or SettingUpColumn.Property("ChoiceParameterLinks") Then
			Continue;
		EndIf;
		
		ValueType = SettingUpColumn.ValueType.Types();
		RelationshipStructure = Undefined;
		
		For Each Type In ValueType Do
			
			LinkedTypes = MatchingRelatedElements[Type];
			If LinkedTypes = Undefined Then
				Continue;
			EndIf;
			
			IndexOf = 0;
			For Each KeyAndValue In DefiningElement.ColumnSettings Do
				IndexOf = IndexOf + 1;
				If Cnt >= IndexOf Then
					Continue;
				EndIf;
				If Not TypeOf(KeyAndValue.Value) = Type("Map") Then // Skip the link search for simple types of editable value
					For Each TypeOfUnderlyingColumn In KeyAndValue.Value.ValueType.Types() Do
						CommunicationParameters = LinkedTypes.Find(TypeOfUnderlyingColumn, "Type");
						If CommunicationParameters <> Undefined Then
							RelationshipStructure = New Structure("DataPath, Filter", 
									"Items.BudgetEditList.CurrentData." + KeyAndValue.Key, CommunicationParameters.Attribute);
							Break;
						EndIf;
					EndDo;
				EndIf;
				
				If RelationshipStructure <> Undefined Then
					Break;
				EndIf;
			EndDo;
			
			If RelationshipStructure <> Undefined Then
				SettingUpColumn.Insert("ChoiceParameterLinks", RelationshipStructure);
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	Return DefiningElement;
	
EndFunction

Procedure InputColumnParameters(BudgetProfile, ReportItem, ColumnStructure1, StructureOfReportDescription, CacheAdditionalBankingDetails, ParametersOfTableElements)
	
	BudgetInformationForCalculation = BudgetInformationForCalculation(BudgetProfile, ReportItem, ColumnStructure1, StructureOfReportDescription, CacheAdditionalBankingDetails);
	
	For Each ReportItem In ReportItem.Rows Do
		
		If ReportItem.DimensionName = "Rows" Then
			
			CalculateColumnsOfInputList(BudgetInformationForCalculation, ReportItem, ParametersOfTableElements);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function InputListParametersByCellRows(BudgetProfile, ColumnStructureOfDataTable, StructureOfReportDescription, OutputTree)
	
	SetPrivilegedMode(True);
	
	TypeOfCacheElement = Enums.BudgetCacheKinds.InputListParameters;
	Value = InformationRegisters.CacheOfAuxiliaryBudgetProfileData.GetCacheValue(BudgetProfile, TypeOfCacheElement);
	
	If Value <> Undefined Then
		SetPrivilegedMode(False);
		Return Value;
	EndIf;
	
	CacheAdditionalBankingDetails = FinancialReportingServer.CacheAdditionalDetails(BudgetProfile);
	StringParameters = New Map;
	
	For Each ReportItem In OutputTree.Rows Do
		
		If ReportItem.DimensionName = "Table" Then
			
			InputColumnParameters(BudgetProfile, ReportItem, ColumnStructureOfDataTable, 
										StructureOfReportDescription, CacheAdditionalBankingDetails, StringParameters);
			
		EndIf;
		
	EndDo;
	
	InformationRegisters.CacheOfAuxiliaryBudgetProfileData.SetCacheValue(BudgetProfile, TypeOfCacheElement, StringParameters);
	
	SetPrivilegedMode(False);
	
	Return StringParameters;
	
EndFunction

// The structure of the information on the budget to calculate
// 
// Parameters:
// 	BudgetProfile - CatalogRef.BudgetProfiles -
// 	ReportItem - ValueTreeRow - LongDesc:
// * DimensionName - String -
// * ItemKind - Arbitrary -
// * ReportItem - Arbitrary -
// * DimensionKind - Arbitrary -
// * NameForPrinting - String -
// * FixedValue - Arbitrary -
// * DisplayTitleInReport - Boolean -
// * ThisIsDimensionOther - Boolean -
// * EditedValues - Boolean -
// * OutputTogetherWithSubordinate - Boolean -
// * DisplayWithParent - Boolean -
// * AdditionalFields - ValueTable -
// * TableParameters - Structure - Contains:
// 		** DisplayGroupingTitle - Boolean -
// 		** GroupHeader - String -
// 		** DisplayHeadersVertically - Boolean -
// 		** DisplayColumnNumbering - Boolean -
// 		** DisplayRowsNumbering - Boolean -
// 		** AppearanceItems - ValueTable -
// 		** RegisteredRows - ValueTable -
// 		** DesigningColumns - ValueTable -
// 		** DrillDownOfAppearanceItemFilterFields - ValueTable -
// 		** ReportDataForFormatting - See ReportDataForFormatting
// * OnlyForPrinting - Boolean -
// 	ColumnStructure1 - See ColumnsOfDataTable_
// 	StructureOfReportDescription - Structure, Boolean, Undefined - LongDesc:
// * DoesNotRequireCalculationOfCellData - Boolean -
// * TableOfSubordinationOfElements - ValueTable, ValueTree - contains columns:
// ** Parent - CatalogRef.FinancialReportItems - 
// ** Ref - CatalogRef.FinancialReportItems - 
// ** ItemKind - EnumRef.FinancialReportItemKinds - 
// * SourceFields_2 - ValueTable -
// * CellStructureIndexes - Array -
// 	CacheAdditionalBankingDetails - ValueTable - LongDesc
// Returns:
// 	Structure - LongDesc:
// * SubordinateElementsOfBudgetView - ValueTable, ValueTree -
// * TableComplex_ - Boolean -
// * HeaderDimensions - ValueTable - consists of:
// 		** LineNumber - Number -
// 		** ValueType - TypeDescription - type of value for the Analytics view
// * StructureOfReportDescription - Structure -
// * CacheAdditionalBankingDetails - ValueTable -
Function BudgetInformationForCalculation(BudgetProfile, ReportItem, ColumnStructure1, StructureOfReportDescription, CacheAdditionalBankingDetails)
	
	TableComplex_ = ReportItem.ItemKind = Enums.FinancialReportItemKinds.ComplexTable;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	TabularSection.LineNumber AS LineNumber,
	|	TabularSection.DimensionKind.ValueType AS ValueType
	|FROM
	|	Catalog.BudgetProfiles.HeaderDimensions AS TabularSection
	|WHERE
	|	TabularSection.Ref = &BudgetProfile";
	
	Query.SetParameter("BudgetProfile", BudgetProfile);
	
	QueryResult = Query.Execute();
	HeaderDimensions = QueryResult.Unload();
	
	BudgetInformationForCalculation = New Structure;
	BudgetInformationForCalculation.Insert("CacheAdditionalBankingDetails", CacheAdditionalBankingDetails);
	BudgetInformationForCalculation.Insert("ColumnStructureOfDataTable", ColumnStructure1);
	BudgetInformationForCalculation.Insert("StructureOfReportDescription", StructureOfReportDescription);
	BudgetInformationForCalculation.Insert("HeaderDimensions", HeaderDimensions);
	BudgetInformationForCalculation.Insert("TableComplex_", TableComplex_);
	BudgetInformationForCalculation.Insert("SubordinateElementsOfBudgetView", SubordinateElementsOfBudgetView(BudgetProfile));
	
	Return BudgetInformationForCalculation;
	
EndFunction

#EndRegion

#Region SourcesOfMeasurementValues_

// Returns a table of elements
// 
// Parameters:
// 	CellsSettings - See FinancialReportingServer.SubordinateItem
// 	Cache - Undefined, ValueTable -
// Returns:
// 	See NewTableOfElements
//
Function GetTableOfElements(CellsSettings, Cache)
	
	TableOfElements = NewTableOfElements();
	
	If ValueIsFilled(CellsSettings.AddressOfItemStructure) Then
		TableOfElements =
			GetFromTempStorage(CellsSettings.AddressOfItemStructure).TableItems;
	ElsIf Not ValueIsFilled(CellsSettings.ReportItem) Then
		CellsSettings.AddressOfItemStructure = BudgetReportingClientServer.PlaceItemInStorage(
			CellsSettings,
			New UUID);
		TableOfElements =
			GetFromTempStorage(CellsSettings.AddressOfItemStructure).TableItems;
	Else
		TableOfElements = Catalogs.FinancialReportItems.FieldValueOfElementFromCache(
			CellsSettings.ReportItem,
			"TableItems",
			Cache);
	EndIf;
	
	Return TableOfElements;
	
EndFunction

Procedure SubordinateSourcesOfComplexTableElementValues(ChildItems, ItemsList)
	
	For Each TreeRow In ChildItems Do
		
		ItemsList.Add(TreeRow);
		
		SubordinateSourcesOfComplexTableElementValues(
			FinancialReportingServer.SubordinateRows(TreeRow), ItemsList);
		
	EndDo;
	
EndProcedure

Procedure SubordinateSourcesOfSimpleTableElementValues(ChildItems, ItemsList, TypesOfValueElements)
	
	For Each TreeRow In ChildItems Do
		
		If TypesOfValueElements <> Undefined
			And TypesOfValueElements.Find(TreeRow.ItemKind) <> Undefined Then
			
			NewRow = ItemsList.Add();
			NewRow.Item = 
				?(ValueIsFilled(TreeRow.AddressOfItemStructure), TreeRow.AddressOfItemStructure, TreeRow.ReportItem);
			NewRow.ItemKind = TreeRow.ItemKind;
			NewRow.Description = TreeRow.NameForPrinting;
			
		EndIf;
			
		SubordinateSourcesOfSimpleTableElementValues(
			FinancialReportingServer.SubordinateRows(TreeRow), ItemsList, TypesOfValueElements);
		
	EndDo;
	
EndProcedure

Procedure ProcessSourceOperands(ListItem, TypesOfValueElements, TableOfElements, Result, Cache, FillType)
	
	Item = ListItem.Item;
	
	SearchForOperandAt = False;
	ElementStructure = MapItemDetailsByLinkOrAddress(Item, "ItemKind, FormulaOperands", Cache);
	If TypeOf(Item) = Type("String") Then
		SearchForOperandAt = True;
	EndIf;
	
	NewRow = Result.Add();
	FillPropertyValues(NewRow, ListItem);
	
	If ElementStructure.ItemKind = Enums.FinancialReportItemKinds.DerivedItem
		Or (ElementStructure.ItemKind = Enums.FinancialReportItemKinds.BudgetFlowItem And FillType) Then
		
		If FillType Then
			NewRow.ItemKind = Enums.FinancialReportItemKinds.DerivedItem;
		EndIf;
		
		ThereAreSources = False;
		
		For Each OperandString_ In ElementStructure.FormulaOperands Do
			
			If SearchForOperandAt And ValueIsFilled(OperandString_.AddressOfItemStructure) Then
				OperandStructure = GetFromTempStorage(OperandString_.AddressOfItemStructure);
				OperandReference = OperandString_.AddressOfItemStructure;
			Else
				OperandStructure = New Structure;
				OperandStructure.Insert("ItemKind", 
					Catalogs.FinancialReportItems.FieldValueOfElementFromCache(OperandString_.Operand, "ItemKind", Cache));
				OperandReference = OperandString_.Operand;
			EndIf;
			
			If TypesOfValueElements.Find(OperandStructure.ItemKind) <> Undefined Then
				NewRow = Result.Add();
				NewRow.ItemKind = OperandStructure.ItemKind;
				NewRow.Item = OperandReference;
				NewRow.Parent = Item;
				NewRow.Description = "[" + OperandString_.Id + "]";
				ThereAreSources = True;
			EndIf;
			
		EndDo;
		
		If Not ThereAreSources Then
			Result.Delete(NewRow);
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure AugmentSourcesWithOperandsRecursively(ItemsList, TypesOfValueElements, TableOfElements, Result, Cache, FillType)
	
	For Each ListItem In ItemsList Do
		ProcessSourceOperands(ListItem, TypesOfValueElements, TableOfElements, Result, Cache, FillType);
	EndDo;
	
EndProcedure

Function ArticlesAndIndicatorsOfElementValues(TableOfSources, IncludeNonFinancial)
	
	ValueSources = New ValueTable;
	ValueSources.Columns.Add("Source");
	ValueSources.Columns.Add("ItemKind");
	
	For Each RowOfAvailableItems In TableOfSources Do
		
		If RowOfAvailableItems.ItemKind = Enums.FinancialReportItemKinds.NonFinancialItem Then
			
			If IncludeNonFinancial Then
				NewRow = ValueSources.Add();
				NewRow.Source = RowOfAvailableItems.Item;
				NewRow.ItemKind = RowOfAvailableItems.ItemKind;
			EndIf;
			
		ElsIf RowOfAvailableItems.ItemKind = Enums.FinancialReportItemKinds.BudgetFlowItem
			Or RowOfAvailableItems.ItemKind = Enums.FinancialReportItemKinds.BudgetBalanceItem
			Or RowOfAvailableItems.ItemKind = Enums.FinancialReportItemKinds.EditedValue Then
			
			NewRow = ValueSources.Add();
			NewRow.Source = RowOfAvailableItems.Item;
			NewRow.ItemKind = RowOfAvailableItems.ItemKind;
			
		EndIf;
		
	EndDo;
	
	Return ValueSources;
	
EndFunction

// Returns a structure containing the requested values for the details or table parts of the financial report element.
// 
// Parameters:
// 	Item - CatalogRef.FinancialReportItems - link to the report element.
// 			- String - The address of the value store containing the settings of an element of the financial report that has not yet been recorded in the database.
// 	AttributesNames - String - Listing the names of details or table parts.
// 	Cache - See Catalogs.FinancialReportItems.NewCacheOfFinancialReportItems
// Returns:
// 	Structure - structure of Attributes or tabular parts of a financial report element:
// 	 *ItemKind - EnumRef.FinancialReportItemKinds - Type of element.
// 	 *NameForPrinting - String - Name of the element displayed to the user.
// 	 *ReverseSign - Boolean - Reverse sign flag (makes sense for some types of elements).
// 	 *Comment - String - comment.
// 	 *AdditionalSelection - ValueStorage - Storage that contains data layout settings (if there is a selection).
// 	 *HasSettings - Boolean - Flag for settings (selection).
// 	 *DimensionValue - Characteristic.BudgetFlowItemDimensions - the value of analytics.
// 	 *LinkedItem1 - CatalogRef.FinancialReportItems - Related item.
// 	 					- String - the address of the temporary storage containing the data of the linked item.
// 	 *ItemKindAttributes - ValueTable - Table part:
// 	   **Attribute - ChartOfCharacteristicTypesRef.ItemAttributesOfFinancialReports - details of the report element.
// 	   **Value - Characteristic.ItemAttributesOfFinancialReports - the value of the props.
// 	 *FormulaOperands - ValueTable - Table part:
// 	   **Id - String - ID of the operand.
// 	   **Operand - CatalogRef.FinancialReportItems - Element of the operand.
// 	 					- String - the address of the temporary storage containing the data of the operand element.
// 	 *TableItems - ValueTable - Table part:
// 	   **String - CatalogRef.FinancialReportItems, String - Budget line.
// 	   **Column - CatalogRef.FinancialReportItems, String - Column of the budget.
// 	   **Item - CatalogRef.FinancialReportItems, String - element at the intersection.
// 	 *AdditionalFields - ValueTable - Table part:
// 	   **Attribute - String - name of the prop.
// 	   **Description - String - Performance.
// 	   **TitleOutput - Boolean - Indicates whether the header is output.
// 	   **InSeparateColumn - Boolean - Indicates whether the value is displayed in a separate column.
// 	 *AppearanceItems - ValueTable - Table part:
// 	   **Appearance - ValueStorage - contains the style settings.
// 	   **Condition - ValueStorage - contains settings for the layout.
// 	   **CreatedAreaType - EnumRef.DesignedAreaTypesOfBudgetReports - type of area.
// 	   **AppearanceItemKey - UUID - ID of the design element.
// 	 *RegisteredRows - ValueTable - Table part:
// 	   **ReportItem - CatalogRef.FinancialReportItems, String - the element being designed.
// 	   **AppearanceItemKey - UUID - ID of the element to be created.
// 	 *DesigningColumns - ValueTable - Table part:
// 	   **ReportItem - CatalogRef.FinancialReportItems, String - the element being designed.
// 	   **AppearanceItemKey - UUID - ID of the element to be created.
// 	 *DrillDownOfAppearanceItemFilterFields - ValueTable - Table part:
// 	   **ReportItem - CatalogRef.FinancialReportItems, String - design element.
// 	   **AppearanceItemKey - UUID - ID of the design element.
// 	   **FilterFieldName - String - Name of the selection field.
// 	   **ResourceName - String - Name of the resource field.
// 	 *ValueSources - ValueTable - Table part:
// 	   **Source - CatalogRef.FinancialReportItems, String - Report item.
// 	   **AddedDocumentValues - Boolean - Flag indicating that the source of values is data being added
// 	   				to the budget instance.
//
Function MapItemDetailsByLinkOrAddress(Item, AttributesNames, Cache)
	
	If TypeOf(Item) = Type("String") Then
		ObjectAttributes = GetFromTempStorage(Item);
	Else
		Structure = New Structure(AttributesNames);
		ObjectAttributes = New Structure;
		For Each KeyAndValue In Structure Do
			ObjectAttributes.Insert(KeyAndValue.Key,
				Catalogs.FinancialReportItems.FieldValueOfElementFromCache(Item, KeyAndValue.Key, Cache));
		EndDo;
	EndIf;
	
	Return ObjectAttributes;
	
EndFunction

Procedure TypifyAnalyticsColumns(DCS, LongDesc)
	
	FinReports = FinancialReportingServer;
	
	For Each DimensionKind In LongDesc.DimensionKinds Do
		FieldName = FinancialReportingCached.NameOfBudgetReportField(DimensionKind);
		ColumnType = ColumnTypeOfCellStructure(DimensionKind, True);
		AnalyticsHeader = String(DimensionKind);
		
		FieldExpression = BudgetingServer.ExpressingAnalyticsValueBySourceAndType(FieldName, DimensionKind);
		
		FinReports.NewCalculatedField(DCS, FieldName, FieldExpression, AnalyticsHeader,,ColumnType);
	EndDo;
	
EndProcedure

Function NumberOfValueTreeElements(ValueTree, Cnt=0)
	
	For Each Page1 In ValueTree.Rows Do
		Cnt = Cnt + 1;
		Cnt = NumberOfValueTreeElements(Page1, Cnt);
	EndDo;
	
	Return Cnt;

EndFunction

#EndRegion

#Region OtherItems

Function ThereIsUndefinedElementOfTypeInSubordinateStrings(TreeRow, SearchType_, CacheOfAdditionalBankingDetails)
	
	SubordinateRows = FinancialReportingServer.SubordinateRows(TreeRow);
	If Not SubordinateRows.Count() Then
		Return True;
	EndIf;
	
	For Each SubordinateRow In SubordinateRows Do
		
		If MeasurementTypeMatchesOneYouAreLookingFor(SubordinateRow, SearchType_, CacheOfAdditionalBankingDetails) Then
			Continue;
		EndIf;
		
		If SubordinateRow.ItemKind = Enums.FinancialReportItemKinds.GroupFormula Then
			Continue;
		EndIf;
		
		If ThereIsUndefinedElementOfTypeInSubordinateStrings(SubordinateRow, SearchType_, CacheOfAdditionalBankingDetails) Then
			Return True;
		EndIf;
		
	EndDo;
	
	Return False;
	
EndFunction

Function ThereIsCertainElementInParentRows(Val TreeRow, SearchType_, CacheOfAdditionalBankingDetails)
	
	ParentRow = TreeRow;
	While ParentRow <> Undefined Do
		
		If MeasurementTypeMatchesOneYouAreLookingFor(ParentRow, SearchType_, CacheOfAdditionalBankingDetails) Then
			Return True;
		EndIf;
		
		ParentRow = FinancialReportingClientServer.RowParent(ParentRow);
		
	EndDo;
	
	Return False;
	
EndFunction

// Returns selection elements with the Use = True attribute
//
// Parameters:
//  ElementOfComparisonSelection - DataCompositionFilterItem, DataCompositionFilterItemGroup -
//
// Returns:
//  Boolean
//
Function ThereAreSignificantSelectionElements(ElementOfComparisonSelection)
	
	For Each FilterElement In ElementOfComparisonSelection.Items Do
		If FilterElement.Use Then
			Return True;
		EndIf;
		If TypeOf(FilterElement) = Type("DataCompositionFilterItemGroup") Then
			If ThereAreSignificantSelectionElements(FilterElement.Items) Then
				Return True;
			EndIf;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

Procedure FillInSourceNameTable(ArrayOfMeasurementColumns, TableOfSourceNames, TableOfSources, CacheOfIndicatorDetails)
	
	For Each RowOfCells In TableOfSources Do
		
		For Each DimensionName In ArrayOfMeasurementColumns Do
			ValueSources = SourcesValuesFromCellOfCellStructureByDimensionName(RowOfCells, DimensionName);
			If Not ValueIsFilled(ValueSources) Then
				Continue;
			EndIf;
			For Each Source In ValueSources Do
				
				DefaultProperties = New Structure;
				DefaultProperties.Insert("SourceKind", Enums.FinancialReportItemKinds.EmptyRef());
				DefaultProperties.Insert("BudgetBalanceItemType", Enums.BudgetBalanceItemType.EmptyRef());
				
				TheStructureOfTheSearch = New Structure();
				TheStructureOfTheSearch.Insert("String"); 
				TheStructureOfTheSearch.Insert("Column"); 
				TheStructureOfTheSearch.Insert("BudgetFlowItem", Undefined); 
				TheStructureOfTheSearch.Insert("BudgetBalanceItem", Catalogs.BudgetBalanceItems.EmptyRef()); 
				TheStructureOfTheSearch.Insert("NonFinancialItem", Catalogs.NonFinancialItemsOfBudgets.EmptyRef());
				TheStructureOfTheSearch.Insert("EditedValue", "");
				TheStructureOfTheSearch.Insert("Dimension"); 
				TheStructureOfTheSearch.Insert("ID_Source1");
				
				FillPropertyValues(TheStructureOfTheSearch, RowOfCells, "String, Column");
				
				TheStructureOfTheSearch.Dimension = DimensionName;
				TheStructureOfTheSearch.ID_Source1 = Source.Source;
				If TypeOf(Source.Object) = Type("CatalogRef.BudgetFlowItems") Then
					TheStructureOfTheSearch.BudgetFlowItem = Source.Object;
					
					DefaultProperties.SourceKind = Enums.FinancialReportItemKinds.BudgetFlowItem;
				ElsIf TypeOf(Source.Object) = Type("CatalogRef.BudgetBalanceItems") Then
					IndicatorType = ValueOfBudgetViewElementSProps(Source.Object,
							"IndicatorType", CacheOfIndicatorDetails);
					If IndicatorType = Enums.BudgetBalanceItemType.Estimated_ Then
						TheStructureOfTheSearch.BudgetBalanceItem = Source.Object;
						
						DefaultProperties.SourceKind = Enums.FinancialReportItemKinds.BudgetBalanceItem;
						DefaultProperties.BudgetBalanceItemType = Enums.BudgetBalanceItemType.Estimated_;
					Else
						// The target indicator in mapping, obtaining planned data and document data behaves like an article.
						TheStructureOfTheSearch.BudgetFlowItem = Source.Object;
						
						DefaultProperties.SourceKind = Enums.FinancialReportItemKinds.BudgetBalanceItem;
						DefaultProperties.BudgetBalanceItemType = Enums.BudgetBalanceItemType.SpecialPurpose;
					EndIf;
				ElsIf TypeOf(Source.Object) = Type("CatalogRef.NonFinancialItemsOfBudgets") Then
					TheStructureOfTheSearch.NonFinancialItem = Source.Object;
					
					DefaultProperties.SourceKind = Enums.FinancialReportItemKinds.NonFinancialItem;
				ElsIf TypeOf(Source.Object) = Type("String") Then //editable value
					TheStructureOfTheSearch.EditedValue = Source.Object;
					
					DefaultProperties.SourceKind = Enums.FinancialReportItemKinds.EditedValue;
				ElsIf Source.Source = "AllItems" Then
					// Sampling from all analytics elements
				Else
					Raise NStr("vi = 'Loại đối tượng nguồn giá trị không xác định';
								|ru = 'Неизвестный тип объекта источника значений';
								|en = 'Unknown value source object type'; fa = 'Unknown value source object type';
								|it = 'Tipo sconosciuto di oggetto di origine del valore';
								|pl = 'Nieznany tyb obiektu źródła wartości';
								|tr = 'Bilinmeyen değer kaynağı nesne türü'")
				EndIf;
				
				NewRow = TableOfSourceNames.Add();
				FillPropertyValues(NewRow, TheStructureOfTheSearch);
				FillPropertyValues(NewRow, DefaultProperties);
				
			EndDo;
		EndDo;
		
	EndDo;
	
	TableColumnsArray = New Array;
	For Each TableColumn2 In TableOfSourceNames.Columns Do
		TableColumnsArray.Add(TableColumn2.Name);
	EndDo;
	TableOfSourceNames.GroupBy(StrConcat(TableColumnsArray, ","));
	
EndProcedure

// Returns the cached value of the budget type element's details.
//
// Parameters:
//	Ref       - CatalogRef.FinancialReportItems - Element of the budget view.
//	AttributeName - String - Name of the budget type element's details.
//	Cache          - ValueTable - table of Attributes of budget view elements (see the function of cache Requirements of Budget view elements).
//
// Returns:
//	Arbitrary - The value of the props of the budget type element.
//
Function ValueOfBudgetViewElementSProps(Ref, AttributeName, Cache) Export
	
	Return Cache.Find(Ref, "Ref")[AttributeName];
	
EndFunction

// Returns a cache of details for financial report elements by budget type.
//
// Parameters:
// 	BudgetProfile - CatalogRef.BudgetProfiles - The type of budget for which elements you need to get a cache of details.
//
// Returns:
// 	ValueTable - Table of details of elements of financial reports by type of budget.
//
Function CacheOfDetailsForBudgetViewElements(BudgetProfile) Export
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	FinancialReportItems.Ref,
		|	FinancialReportItems.NameForPrinting,
		|	FinancialReportItems.ItemKind,
		|	FinancialReportItems.ReverseSign,
		|	FinancialReportItems.Parent,
		|	FinancialReportItems.DimensionValue,
		|	FinancialReportItems.AdditionalSelection,
		|	FinancialReportItems.TableItems.(
		|		Ref,
		|		LineNumber,
		|		String,
		|		Column,
		|		Item
		|	)
		|FROM
		|	Catalog.FinancialReportItems AS FinancialReportItems
		|WHERE
		|	FinancialReportItems.Owner = &Owner";
	
	Query.SetParameter("Owner", BudgetProfile);
	
	QueryResult = Query.Execute();
	
	Cache = QueryResult.Unload();
	Cache.Indexes.Add("Ref");
	
	For Each CellsSettings In Cache.FindRows(New Structure("ItemKind",
		Enums.FinancialReportItemKinds.CellsSettings)) Do
		TableItems = CellsSettings.TableItems; // ValueTable 
		TableItems.Indexes.Add("Item");
	EndDo;
	
	Return Cache;
	
EndFunction

// Returns the matching of elements that are output together with the parent.
// Required to specify the correct row / column for calculating totals using the formula
// in the fill in data source Method if the analysts are grouped
// (then the cell Data table shows the end rows and columns).
//
// Parameters:
// 	BudgetProfile - CatalogRef.BudgetProfiles - The type of budget for which elements you need to get a cache of details.
//
// Returns:
// 	Map - Matches the parent type of analytics or measurement and the one displayed with it in the same dimension:
// 	 *Key - CatalogRef.FinancialReportItems - Parent row/column (type of analytics or dimension).
// 	 *Value - CatalogRef.FinancialReportItems - the row/column displayed together with the parent (type of analytics or dimension).
//
Function GetCacheOfChildElementsOutputWithParent(BudgetProfile)
	CacheValue = New Map;
	
	Query = New Query;
	Query.SetParameter("BudgetProfile", BudgetProfile);
	Query.SetParameter("DisplayWithParent", ChartsOfCharacteristicTypes.ItemAttributesOfFinancialReports.DisplayWithParent);
	Query.Text = "SELECT
	|	FinancialReportItems.Ref AS Ref,
	|	FinancialReportItems.Parent AS Parent
	|FROM
	|	Catalog.FinancialReportItems AS FinancialReportItems
	|		INNER JOIN Catalog.FinancialReportItems.ItemKindAttributes AS FinancialReportItemsItemKindAttributes
	|		ON FinancialReportItems.Ref = FinancialReportItemsItemKindAttributes.Ref
	|			AND FinancialReportItemsItemKindAttributes.Attribute = &DisplayWithParent
	|			AND FinancialReportItemsItemKindAttributes.Value = TRUE
	|WHERE
	|	FinancialReportItems.Owner = &BudgetProfile";
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		CacheValue.Insert(Selection.Parent, Selection.Ref);
	EndDo;
	
	Return CacheValue;
EndFunction

Function ArrayToList(Array) 
	
	List = New ValueList;
	List.LoadValues(Array);
	
	Return List;
	
EndFunction

// The procedure returns a selection by name 
// . the procedure is not recursive, because it is called from
// a compare Selection that has already processed group traversal.
//
// Parameters:
//  FilterElement - DataCompositionFilterItem - the desired selection
//  FilterItems1 - DataCompositionFilterItemCollection - selection, where we are looking
//  FoundItem - DataCompositionFilterItem, DataCompositionFilterItemGroup - the selection element found.
//  
// Returns:
//  Boolean - 
//
Function FindSelection(FilterElement, FilterItems1, FoundItem)
	
	For Each ComparisonSelectionElement In FilterItems1 Do
		If TypeOf(ComparisonSelectionElement) <> TypeOf(FilterElement) Then
			Continue;
		EndIf;
		
		If TypeOf(ComparisonSelectionElement) = Type("DataCompositionFilterItem") Then
			If ComparisonSelectionElement.Use = FilterElement.Use
				And ComparisonSelectionElement.RightValue = FilterElement.RightValue
				And ComparisonSelectionElement.LeftValue = FilterElement.LeftValue
				And ComparisonSelectionElement.ComparisonType = FilterElement.ComparisonType
				And ComparisonSelectionElement.Application = FilterElement.Application Then
				
				FoundItem = ComparisonSelectionElement;
				Return True;
				
			EndIf;
		Else
			If ComparisonSelectionElement.Use = FilterElement.Use
				And ComparisonSelectionElement.GroupType = FilterElement.GroupType
				And ComparisonSelectionElement.Application = FilterElement.Application Then
				
				FoundItem = ComparisonSelectionElement; // Groups of elements of the assembled, assembled, assembled elements -
				Return True;
				
			EndIf;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

Function CompareSelections(SourceSelection, ElementOfComparisonSelection)
	
	If SourceSelection = Undefined
		And ElementOfComparisonSelection = Undefined Then
		Return True;
	EndIf;
	
	If SourceSelection = Undefined Then
		Return Not ThereAreSignificantSelectionElements(ElementOfComparisonSelection.Filter);
	EndIf;
	
	If ElementOfComparisonSelection = Undefined Then
		Return Not ThereAreSignificantSelectionElements(SourceSelection.Filter);
	EndIf;
	
	If TypeOf(SourceSelection) = Type("DataCompositionFilterItemCollection") Then
		SelectionElementsSource = SourceSelection;
	Else
		SelectionElementsSource = SourceSelection.Filter.Items;
	EndIf;
	
	If TypeOf(ElementOfComparisonSelection) = Type("DataCompositionFilterItemCollection") Then
		ElementsOfComparisonSelection = ElementOfComparisonSelection;
	Else
		ElementsOfComparisonSelection = ElementOfComparisonSelection.Filter.Items;
	EndIf;
	
	For Each FilterElement In SelectionElementsSource Do
		FoundItem = Undefined; // DataCompositionFilterItem, DataCompositionFilterItemGroup - 
		If Not FindSelection(FilterElement, ElementsOfComparisonSelection, FoundItem) Then
			Return False;
		EndIf;
		If TypeOf(FilterElement) = Type("DataCompositionFilterItemGroup") Then
			If Not CompareSelections(FilterElement.Items, FoundItem.Items) Then
				Return False;
			EndIf;
		EndIf;
	EndDo;
	
	For Each FilterElement In ElementsOfComparisonSelection Do
		FoundItem = Undefined; // DataCompositionFilterItem, DataCompositionFilterItemGroup -
		If Not FindSelection(FilterElement, SelectionElementsSource, FoundItem) Then
			Return False;
		EndIf;
		If TypeOf(FilterElement) = Type("DataCompositionFilterItemGroup") Then
			If Not CompareSelections(FilterElement.Items, FoundItem.Items) Then
				Return False;
			EndIf;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction

Function MeasurementTypeMatchesOneYouAreLookingFor(ElementString, SearchType_, CacheOfAdditionalBankingDetails)
	
	If ElementString.ItemKind = Enums.FinancialReportItemKinds.Dimension Then
		
		DesiredDimension = Enums.TypesOfBudgetReportDimensions[SearchType_];
		DimensionName = Undefined;
		
		If ValueIsFilled(ElementString.AddressOfItemStructure)
			Or ValueIsFilled(ElementString.ReportItem) Then
			
			If ValueIsFilled(ElementString.AddressOfItemStructure) Then
				DimensionName = FinancialReportingServerCall.ValueOfAdditionalProps(ElementString.AddressOfItemStructure, "DimensionType");
			ElsIf Not ValueIsFilled(CacheOfAdditionalBankingDetails) Then
				DimensionName = FinancialReportingServerCall.ValueOfAdditionalProps(ElementString.ReportItem, "DimensionType");
			Else
				DimensionName = FinancialReportingServer.ValueOfAdditionalProps(ElementString.ReportItem, "DimensionType", CacheOfAdditionalBankingDetails);
			EndIf;
			
		EndIf;
		
		If DesiredDimension = DimensionName Then
			Return True;
		EndIf;
		
	EndIf;
	
	Return False;
	
EndFunction

// Returns the settings for the budget view table cells.
//
// Parameters:
// 	BudgetProfile - CatalogRef.BudgetProfiles - The type of budget that you want to get the cell settings for.
//
// Returns:
// 	ValueTable - Table of cell settings by budget type:
// 	 *Item - CatalogRef.FinancialReportItems - The element of the budget.
// 	 *String - CatalogRef.FinancialReportItems - Budget line.
// 	 *Column - CatalogRef.FinancialReportItems - Column of the budget.
// 	 *Parent - CatalogRef.FinancialReportItems -  The parent element of the budget.
//
Function ElementsForConfiguringBudgetViewCells(BudgetProfile) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
		|	FinancialReportItems.Item,
		|	FinancialReportItems.String,
		|	FinancialReportItems.Column,
		|	FinancialReportItems.Ref.Parent AS Parent
		|FROM
		|	Catalog.FinancialReportItems.TableItems AS FinancialReportItems
		|WHERE
		|	FinancialReportItems.Ref.Owner = &BudgetProfile";
	
	Query.SetParameter("BudgetProfile", BudgetProfile);
	SettingsTable = Query.Execute().Unload();
	SettingsTable.Indexes.Add("String, Column, Parent");
	
	Return SettingsTable;
	
EndFunction

Procedure ReadValueOfAdditionalDetailsExcludeDataOfEnteredDocumentDuringCalculation(PlaceWhereValueIsSet,
				FinancialReportElement, CacheOfAdditionalBankingDetails)
	
	AddAttributes = ChartsOfCharacteristicTypes.ItemAttributesOfFinancialReports;
	AdditionalAttribute5  = AddAttributes.ExcludeEnteredDocumentDataDuringCalculation;
	Value = FinancialReportingServer.ValueOfAdditionalProps(FinancialReportElement,
			AdditionalAttribute5,
			CacheOfAdditionalBankingDetails);
	If TypeOf(Value) = Type("Boolean") Then
		PlaceWhereValueIsSet["ExcludeEnteredDocumentDataDuringCalculation"] = Value;
	EndIf;
	
EndProcedure

#EndRegion 

#EndRegion

