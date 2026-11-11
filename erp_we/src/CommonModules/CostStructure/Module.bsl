
#Region Public

//Initializes the report settings for generating the report.
// Returns:
//	Structure - the report settings.
Function InitializeReportSettings(Report, CurrentVariantKey, ReportObject) Export
	
	ReportSettings = ReportsOptions.ReportFormSettings(Report, CurrentVariantKey, ReportObject); // Structure
	
	ReportSettings.Insert("ReadCreateFromUserSettingsImmediatelyCheckBox", False);
	ReportSettings.Insert("OptionSelectionAllowed", False);
	ReportSettings.Insert("SchemaModified", False);
	ReportSettings.Insert("PredefinedOptions", Undefined);
	ReportSettings.Insert("SchemaURL",   "");
	ReportSettings.Insert("SchemaKey",    "");
	ReportSettings.Insert("Contextual",  False);
	ReportSettings.Insert("FullName",    "");
	ReportSettings.Insert("Description", "");
	ReportSettings.Insert("ReportRef",  Undefined);
	ReportSettings.Insert("External",      False);
	ReportSettings.Insert("Safe",   False);
	
	Return ReportSettings;
	
EndFunction

// Builds a cost tree for the item.
//
// Parameters:
//  TreeParameters - See CostStructure.CostTreeParameters
//
Procedure BuildCostTree(TreeParameters) Export
	
	// StandardSubsystems.PerformanceMeasurement
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement("CommonModule.CostStructure.BuildCostTree");
	TreeParameters.Insert("RowsCount", 0);
	// End StandardSubsystems.PerformanceMeasurement
	
	If TreeParameters.Result = Undefined Then
		EmptyCostTree(TreeParameters);
	EndIf;
	
	FillInCostTree(TreeParameters);
	
	// StandardSubsystems.PerformanceMeasurement
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, TreeParameters.RowsCount / 1000);
	// End StandardSubsystems.PerformanceMeasurement
	
EndProcedure

// Builds a cost tree for the item in the background.
//
// Parameters:
// 	Parameters - Structure - description of report generation parameters:
//		* TreeParameters - See CostStructure.CostTreeParameters
//	StorageAddress - String - the address of the temporary storage.
Procedure BuildCostTreeInBackground(Parameters, StorageAddress) Export
	
	TreeParameters = Parameters.TreeParameters; // See CostStructure.CostTreeParameters
	BuildCostTree(TreeParameters);
	
	Result = New Structure("CostPriceTree, Success");
	Result.CostPriceTree	= TreeParameters.Result;
	Result.Success					= True;
	
	PutToTempStorage(Result, StorageAddress);
	
EndProcedure

// The procedure replenishes the parameters of the cost tree necessary to start the level separation.
//
// Parameters:
//  TreeParameters - See CostStructure.CostTreeParameters
//
Procedure FillInParametersOfCostTree(TreeParameters) Export
	
	If TreeParameters.ResultTypeValueTree
		+ TreeParameters.ResultTypeTempTableManager + TreeParameters.ResultTypeTableOfValues <> 1 Then
			
		Raise NStr("ru = 'Должен быть определен один тип результата дерева себестоимости.';
					|vi = 'Define one type of cost tree result.';
					|en = 'Define one type of cost tree result.'; fa = 'Define one type of cost tree result.';
					|it = 'Define one type of cost tree result.';
					|pl = 'Define one type of cost tree result.';
					|tr = 'Maliyet ağacı için bir sonuç türü belirlenmelidir.'");
	EndIf;
	
	TreeParameters.Insert("GlobalTempTables", New Array());
	TreeParameters.Insert("NodeSelectionTable", EmptyNodeSelectionTable(TreeParameters.FieldsStructure));
	TreeParameters.Insert("NodeSelectionTable_ColumnNames",
		CostCalculationAppliedAlgorithms.GetColumnNamesAsString(TreeParameters.NodeSelectionTable, "",
			True));
	TreeParameters.Insert("NodeSelectionTable_ColumnNamesWithSynonyms",
		CostCalculationAppliedAlgorithms.AddSynonymsToColumns(
			TreeParameters.NodeSelectionTable_ColumnNames, "T"));
			
	TreeParameters.Insert("MapOfNodes", New Map());
	If TreeParameters.TempTablesManager = Undefined Then
		TreeParameters.TempTablesManager = New TempTablesManager;
	EndIf;
	
	If TreeParameters.ResultTypeTempTableManager Then
		TreeParameters.Insert("AddedTempTableOfResultsOfUncoupling", False);
	EndIf;
	
	QueryTextProductCosts(TreeParameters);
	TreeParameters.Insert("QueryTextNodesThatNeedToBeSeparated",
		QueryTextTemplateSearchResults(True, TreeParameters));
	
	TreeParameters.ReportParameters.Insert("ItemInclusionExclusionOfNDSVCost",
		NStr("ru = 'Включение / Исключение НДС в стоимости';
			|vi = 'Include / Exclude VAT in / from cost';
			|en = 'Include / Exclude VAT in / from cost'; fa = 'Include / Exclude VAT in / from cost';
			|it = 'Include / Exclude VAT in / from cost';
			|pl = 'Include / Exclude VAT in / from cost';
			|tr = 'KDV''nin fiyata dahil edilmesi / hariç tutulması'"));
	TreeParameters.ReportParameters.Insert("ItemLooping",
		NStr("ru = 'Зацикливание разузлования';
			|vi = 'Explosion looping';
			|en = 'Explosion looping'; fa = 'Explosion looping';
			|it = 'Explosion looping';
			|pl = 'Explosion looping';
			|tr = 'Ayrıştırma döngüsü'"));
	
	Diagnostics = New Structure();
	Diagnostics.Insert("LogEventGroup", NStr("ru = 'Формирование дерева себестоимости.';
											|vi = 'Generate a cost tree.';
											|en = 'Generate a cost tree.'; fa = 'Generate a cost tree.';
											|it = 'Generate a cost tree.';
											|pl = 'Generate a cost tree.';
											|tr = 'Maliyet ağacı oluşturma.'"));
	Diagnostics.Insert("HasErrors", False);
	Diagnostics.Insert("Errors", Undefined);
	Diagnostics.Insert("MeasurementsOfQueryExecutionByNodeLevels", New Array());
	TreeParameters.Insert("Diagnostics", Diagnostics);
	
	TreeParameters.Insert("HigherLevelNodes", New Map());
	TreeParameters.Insert("UpstreamNodesAdded", False);
	
	FillInIndexToCheckLooping(TreeParameters, False);
	
	TreeParameters.GlobalTempTables.Add("NodeTable_");
	TreeParameters.GlobalTempTables.Add("Result");
	TreeParameters.GlobalTempTables.Add("TTInterconnectedCompanies");
	
EndProcedure

// The procedure loads the node selection table into the temp table of the tree parameter temp table manager.
//
// Parameters:
//  TreeParameters - See CostStructure.CostTreeParameters
//
Procedure LoadNodeSelectionTableIntoTempTable(TreeParameters) Export
	
	ArrayOfIndexSets = New Array();
	If TreeParameters.VariantsOfConnectionConditionsByNodeParameters.ProductsBatch = 1 Then
		ArrayOfIndexSets.Add("ProductsBatch");
	EndIf;
	ArrayOfIndexSets.Add("NodeID");

	TreeParameters.GlobalTempTables.Add("NodeSelectionTable");
	CostCalculationAppliedAlgorithms.PutTableOfValuesInTemporaryTable(
		TreeParameters.TempTablesManager,
		"NodeSelectionTable", TreeParameters.NodeSelectionTable,
		TreeParameters.NodeSelectionTable_ColumnNames,
		ArrayOfIndexSets);

EndProcedure

// Called before opening the cost tree node.
//
// Parameters:
//  TreeParameters - See CostStructure.CostTreeParameters.
//
Procedure CostTreeBeforeDeployment(TreeParameters) Export
	
	// StandardSubsystems.PerformanceMeasurement
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"CommonModule.CostStructure.CostTreeBeforeDeployment");
	TreeParameters.Insert("RowsCount", 0);
	// End StandardSubsystems.PerformanceMeasurement
	
	Catalogs.Companies.GetRelatedCompanies(TreeParameters.TempTablesManager);
	PlaceTableOfSelectionsOfIWTNodesTableOfNodes(TreeParameters);
	FindOutLevelOfNodesOfCostTree(TreeParameters, TreeParameters.Result);
	
	// StandardSubsystems.PerformanceMeasurement
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, TreeParameters.RowsCount / 100);
	// End StandardSubsystems.PerformanceMeasurement
	
EndProcedure

#Region CostTreeParameters

// The parameters of the tree building cost
// 
// Returns:
// Structure:
//  * DynamicReading - Boolean - True if the levels of the cost tree are obtained sequentially.
//  * ResultTypeValueTree - Boolean - True if the result type is tree values.
//  * ResultTypeTempTableManager - Boolean - True if the result type is managementmodern tables.
//  * ResultTypeTableOfValues - Boolean - True if the result type is an assignment table.
//  * Result - Arbitrary - During initialization, it is determined later, for the possibility of Transferring parameters to the background.
//              - ValueTree - the tree of values in which the result of the untangling will be placed,
//                                 in the case when the type of resultsreferences.
//              - ValueTable - the table of values in which the result of the undifferentiation will be placed,
//                                 in the case when the type of resultatablity of the values.
//  * TempTablesManager - Undefined - When initializing parameters, it is determined later, for the possibility of Transferring parameters to the background.
//                             - TempTablesManager - In the case when the
//                              result type is managed by two temporary tables, the result of the partitioning is returned as a temp table in this manager.
//  * AddSemiFinishedProductsToResult - Boolean - Whether intermediate semi-finished products will be added to the result.
//                                       If the result is a tree value, then semi-finished products are always added.
//  * VariantsOfConnectionConditionsByNodeParameters - Structure - structure of connection options.
//  * InteractiveSetup - Boolean - True if the settings can be changed interactively.
//  * DCSchema - DataCompositionSchema - The data layout scheme used.
//  * DCSettings - DataCompositionSettings - The data layout settings used.
//  * TablesCounter - Number - Counter of generated tables.
//  * NodeLevel - Number - The level of the current node.
//  * IncludePersonalIncomeTaxCost - Boolean - Determines the need to include VAT in the cost.
//  * ExcludeVATFromCost - Boolean - Determines the need to exclude VAT from the cost.
//  * FieldsStructure - Structure - Defines the structure of fields and their types of the cost tree.
//  * MaximumDepthOfNodulation - Number - Limiting the maximum depth of separation, additional protection against looping.
//  * ToOutputErrors - Boolean - Determines whether it is necessary to display to the user the error of the node.
//  * ReportParameters - Structure - The structure of the report parameters.
//  * IndexToCheckForLooping - Undefined - When initializing parameters, it is determined later.
//                                  - String - List of columns that need indexing.
//  * NodeSelectionTable - Undefined - When initializing parameters, it is determined later.
//                        - ValueTable - The table according to which the data will be selected from the registers.
//
Function CostTreeParameters() Export
	
	ResultTypes = New TypeDescription("ValueTree,ValueTable");
	TreeParameters = New Structure;
	
	#Region GeneralTreeParameters
	
	TreeParameters.Insert("DynamicReading",	True);
	TreeParameters.Insert("Result",				ResultTypes.AdjustValue(Undefined));
	TreeParameters.Insert("AddSemiFinishedProductsToResult", True);
	
	TreeParameters.Insert("DCSchema", Reports.ProductsCostTree.GetTemplate("MainDataCompositionSchema"));
	TreeParameters.Insert("DCSettings", TreeParameters.DCSchema.DefaultSettings);
	TreeParameters.Insert("TablesCounter", 0);
	
	TreeParameters.Insert("NodeLevel", 1);
	TreeParameters.Insert("InteractiveSetup", False);
	TreeParameters.Insert("IncludePersonalIncomeTaxCost", False);
	TreeParameters.Insert("ExcludeVATFromCost", False);
	TreeParameters.Insert("TempTablesManager", Undefined);
	TreeParameters.Insert("ResultTypeValueTree", False);
	TreeParameters.Insert("ResultTypeTempTableManager", False);
	TreeParameters.Insert("ResultTypeTableOfValues", False);
	TreeParameters.Insert("FieldsStructure", StructureOfCostTreeFields());
	TreeParameters.Insert("MaximumDepthOfNodulation", 1000);
	TreeParameters.Insert("ToOutputErrors", True);
	TreeParameters.Insert("IndexToCheckForLooping", Undefined);
	TreeParameters.Insert("NodeSelectionTable", Undefined);

	#EndRegion
	
	#Region GeneralReportParameters
	
	ReportParameters = New Structure();
	ReportParameters.Insert("StartDate", Date('00010101'));
	ReportParameters.Insert("EndDate", Date('00010101'));
	ReportParameters.Insert("Companies", New Array());
	ReportParameters.Insert("Departments", New Array());
	ReportParameters.Insert("Recorders", New Array());
	ReportParameters.Insert("DeployAdditionalCosts", True);
	ReportParameters.Insert("ManagementAccountingCurrency", Catalogs.Currencies.EmptyRef());
	ReportParameters.Insert("Cost_Data", 1);
	ReportParameters.Insert("ForTheWholePeriod", True);
	ReportParameters.Insert("ByAllCompanies", True);
	ReportParameters.Insert("ByAllBusinessUnits", True);
	ReportParameters.Insert("DecryptionOfDocumentRegisteredRecords", False);
	ReportParameters.Insert("NumberOfSelectionNodes", 0);
	
	TreeParameters.Insert("ReportParameters", ReportParameters);
	
	#EndRegion
	
	#Region VariantsOfConnectionConditionsByNodeParameters
	// Comment 204.
	// 3 options for each connection:
	//    0. According to the column in all rows, the value is empty and does not require connection, the connection condition is not necessary.
	//    1. The column in all rows of the selection is filled with the value, the condition of the connection for equality.
	//    2. According to the column in some rows of the selection table, a connection is required, in some not,
	//      the connection condition is via OR, depending on the fullness.
	VariantsOfConnectionConditionsByNodeParameters = New Structure();
	VariantsOfConnectionConditionsByNodeParameters.Insert("ManufacturedProduct", 1);
	VariantsOfConnectionConditionsByNodeParameters.Insert("ProductsBatch", 1);
	VariantsOfConnectionConditionsByNodeParameters.Insert("ItemVariant", 1);
	VariantsOfConnectionConditionsByNodeParameters.Insert("ProductionSeries_", 0);
	VariantsOfConnectionConditionsByNodeParameters.Insert("AssignmentOfProducts", 0);
	VariantsOfConnectionConditionsByNodeParameters.Insert("ProductBatchAccountingDimension", 0);
	
	TreeParameters.Insert("VariantsOfConnectionConditionsByNodeParameters", VariantsOfConnectionConditionsByNodeParameters);
	#EndRegion
	
	Return TreeParameters;
	
EndFunction

// Defines options for connection conditions for node parameters based on the selection table.
//
// Parameters:
//   TreeParameters - Structure - A structure containing a table of node selections and options for connection conditions.
//
Procedure SetOptionsForConnectionConditionsByNodeParameters(TreeParameters) Export
	TreeParameters.ReportParameters.NumberOfSelectionNodes = TreeParameters.NodeSelectionTable.Count();
	NumberOfSelectionLines = TreeParameters.ReportParameters.NumberOfSelectionNodes;
	ForAllProducts = 0;
	ForAllParties = 0;
	AccordingToAllCharacteristics = 0;
	ForAllSeries = 0;
	ForAllAppointments = 0;
	AccordingToAllPartyAnalysts = 0;
	For Each FIlterRow In TreeParameters.NodeSelectionTable Do
		ForAllProducts = ForAllProducts + ?(FIlterRow.ForAllProducts, 1, 0);
		ForAllParties = ForAllParties + ?(FIlterRow.ForAllParties, 1, 0);
		AccordingToAllCharacteristics = AccordingToAllCharacteristics + ?(FIlterRow.AccordingToAllCharacteristics, 1, 0);
		ForAllSeries = ForAllSeries + ?(FIlterRow.ForAllSeries, 1, 0);
		ForAllAppointments = ForAllAppointments + ?(FIlterRow.ForAllAppointments, 1, 0);
		AccordingToAllPartyAnalysts = AccordingToAllPartyAnalysts + ?(FIlterRow.AccordingToAllPartyAnalysts, 1, 0);
	EndDo;
	
	#Region VariantsOfConnectionConditionsByNodeParameters
	TreeParameters.VariantsOfConnectionConditionsByNodeParameters.ManufacturedProduct = 
		?(ForAllProducts = NumberOfSelectionLines, 0,
			?(ForAllProducts = 0, 1, 2));
	TreeParameters.VariantsOfConnectionConditionsByNodeParameters.ProductsBatch = 
		?(ForAllParties = NumberOfSelectionLines, 0,
			?(ForAllParties = 0, 1, 2));
	TreeParameters.VariantsOfConnectionConditionsByNodeParameters.ItemVariant = 
		?(AccordingToAllCharacteristics = NumberOfSelectionLines, 0,
			?(AccordingToAllCharacteristics = 0, 1, 2));
	TreeParameters.VariantsOfConnectionConditionsByNodeParameters.ProductionSeries_ = 
		?(ForAllSeries = NumberOfSelectionLines, 0,
			?(ForAllSeries = 0, 1, 2));
	TreeParameters.VariantsOfConnectionConditionsByNodeParameters.AssignmentOfProducts = 
		?(ForAllAppointments = NumberOfSelectionLines, 0,
			?(ForAllAppointments = 0, 1, 2));
	TreeParameters.VariantsOfConnectionConditionsByNodeParameters.ProductBatchAccountingDimension = 
		?(AccordingToAllPartyAnalysts = NumberOfSelectionLines, 0,
			?(AccordingToAllPartyAnalysts = 0, 1, 2));
	#EndRegion
EndProcedure

// Returns the structure of cost types that can be used in the generated cost tree.
// 
// Returns:
// Structure:
//  * TypeOfCostsManufacturedProducts - String - Type of production costs.
//  * TypeOfCostsMaterial - String - The type of material costs.
//  * CostTypeLaborCosts - String - Type of costs labor costs.
//  * TypeOfCostsArticleByArticle - String - The type of costs is article-by-article.
//  * TypeOfCostsAdditionalExpensesAmount - String - The cost type is additional. expenses.
//
Function TypesOfCostsOfCostTree() Export
	CostTypes = New Structure();
	CostTypes.Insert("TypeOfCostsManufacturedProducts",		NStr("vi = 'Sản phẩm';
																	|ru = 'Продукция';
																	|en = 'Manufactured product'; fa = 'محصول تولیدی';
																	|it = 'Продукция';
																	|pl = 'Manufactured product';
																	|tr = 'İmal edilen ürünler'"));
	CostTypes.Insert("TypeOfCostsMaterial",	NStr("vi = 'Nguyên vật liệu';
													|ru = 'Материальные';
													|en = 'Material costs'; fa = 'هزینه‌های مواد';
													|it = 'Материальные';
													|pl = 'Materiałowe';
													|tr = 'Malzeme'"));
	CostTypes.Insert("CostTypeLaborCosts",	NStr("vi = 'Công lao động';
													|ru = 'Трудозатраты';
													|en = 'Labor costs'; fa = 'هزینه‌های دستمزد';
													|it = 'Costi di manodopera';
													|pl = 'Nakłady pracy';
													|tr = 'İş gücü maliyetleri'"));
	CostTypes.Insert("TypeOfCostsArticleByArticle",		NStr("vi = 'Theo công đoạn';
																|ru = 'Постатейные';
																|en = 'Itemized costs'; fa = 'Itemized costs';
																|it = 'Dettagliati per voce';
																|pl = 'Itemized costs';
																|tr = 'Ayrıntılı'"));
	CostTypes.Insert("TypeOfCostsAdditionalExpensesAmount",		NStr("vi = 'Chi phí bổ sung';
																		|ru = 'Доп. расходы';
																		|en = 'Additional expenses'; fa = 'هزینه‌های تکمیلی';
																		|it = 'Spese aggiuntive';
																		|pl = 'Rozchody dodatkowe';
																		|tr = 'Ek giderler'"));
	Return CostTypes;
EndFunction
	
#EndRegion

#EndRegion

#Region Private

// Fills in the cost tree
//
// Parameters:
//  TreeParameters - See CostStructure.CostTreeParameters.
//
Procedure FillInCostTree(TreeParameters)
	
	If TreeParameters.NodeSelectionTable = Undefined Then
		FillInParametersOfCostTree(TreeParameters);
	EndIf;
	
	Catalogs.Companies.GetRelatedCompanies(TreeParameters.TempTablesManager);
	
	// The set of fields for indexing must take into account the variants of the connection conditions.
	ArrayOfIndexSets = New Array();
	If TreeParameters.VariantsOfConnectionConditionsByNodeParameters.ProductsBatch = 1 Then
		ArrayOfIndexSets.Add("ProductsBatch");
	EndIf;
	ArrayOfIndexSets.Add("NodeID");
		
	CostCalculationAppliedAlgorithms.PutTableOfValuesInTemporaryTable(
		TreeParameters.TempTablesManager,
		"NodeSelectionTable", TreeParameters.NodeSelectionTable,
		TreeParameters.NodeSelectionTable_ColumnNames,
		ArrayOfIndexSets);
	
	TreeParameters.ReportParameters.NumberOfSelectionNodes = TreeParameters.NodeSelectionTable.Count();
	Query = RequestReleasedProducts(False, TreeParameters);
	CalculationParameters = New Structure;
	CalculationParameters.Insert("QueryExecutionResult", "");
	BeginTime = CurrentUniversalDateInMilliseconds();
	IssuedProducts = CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(
		CalculationParameters, Query,,, True, NStr("ru = 'Заполнить дерево себестоимости';
													|vi = 'Fill cost tree';
													|en = 'Fill cost tree'; fa = 'Fill cost tree';
													|it = 'Fill cost tree';
													|pl = 'Fill cost tree';
													|tr = 'Maliyet ağacını doldur'"));
		
	Duration = (CurrentUniversalDateInMilliseconds() - BeginTime) / 1000;
	Template = NStr("ru = 'Уровень узлов: %1
			|Общее время: %2
			|Количество узлов отбора: %3
			|%4';
			|vi = 'Node level: %1
			|Total time: %2
			|Number of filter nodes: %3
			|%4';
			|en = 'Node level: %1
			|Total time: %2
			|Number of filter nodes: %3
			|%4'; fa = 'Node level: %1
			|Total time: %2
			|Number of filter nodes: %3
			|%4';
			|it = 'Node level: %1
			|Total time: %2
			|Number of filter nodes: %3
			|%4';
			|pl = 'Node level: %1
			|Total time: %2
			|Number of filter nodes: %3
			|%4';
			|tr = 'Düğüm seviyesi:%1
			|Toplam süre:%2 
			|Seçim düğümü sayısı: %3
			|%4'");
	ProtocolText_ = StrTemplate(Template,
		TreeParameters.NodeLevel,
		CostCalculationProtocol.TimePresentation(Duration),
		TreeParameters.ReportParameters.NumberOfSelectionNodes,
		CalculationParameters.QueryExecutionResult);
	TreeParameters.Diagnostics.MeasurementsOfQueryExecutionByNodeLevels.Add(ProtocolText_);
	EventName = NStr("ru = 'Выполнение запроса по уровню узлов';
					|vi = 'Query execution by node level';
					|en = 'Query execution by node level'; fa = 'Query execution by node level';
					|it = 'Query execution by node level';
					|pl = 'Query execution by node level';
					|tr = 'Düğüm seviyesine göre sorgu yürütme'");
	WriteLogEvent(TreeParameters.Diagnostics.LogEventGroup + EventName,
		EventLogLevel.Information,,,
		ProtocolText_);
		
	DestroyTemporaryTables(TreeParameters);
		
	TreeParameters.InteractiveSetup = False;
	TreeParameters.Insert("NodeLevel", 1);
	
	If TreeParameters.ResultTypeValueTree Then
		Result = TreeParameters.Result.Rows;
	ElsIf TreeParameters.ResultTypeTableOfValues Then
		Result = TreeParameters.Result;
	Else
		Result = New ValueTable;
		InitializeCostTreeFields(Result, TreeParameters.FieldsStructure);
		TreeParameters.Insert("TableFields",
			CostCalculationAppliedAlgorithms.GetColumnNamesAsString(Result, "Id", True));
		TreeParameters.Insert("TablesNames", New Array());
	EndIf;
	
	TreeParameters.NodeSelectionTable.Clear();
	IssuedProducts = IssuedProducts.Select();
	While IssuedProducts.Next() Do
		
		NewNodeId = String(New UUID());
		
		If TreeParameters.ResultTypeValueTree
			Or TreeParameters.AddSemiFinishedProductsToResult
			Or Not IssuedProducts.ExplosionIsRequired Then
			StringBatch = Result.Add(); // ValueTreeRow
			FillPropertyValues(StringBatch, IssuedProducts);
			
			StringBatch.Id	= New UUID();
			StringBatch.NodeID = NewNodeId;
			StringBatch.LineKind		= Enums.KindsOfCostTreeRows.ProductsBatch;
			
			StringBatch.AccountingDimensionFinishedProduct			= IssuedProducts.ProductsAccountingDimension;
			StringBatch.BatchAccountingDimensionFinishedProduct	= IssuedProducts.ProductBatchAccountingDimension;
			StringBatch.BatchFinishedProduct					= IssuedProducts.ProductsBatch;
			
			StringBatch.Products			= IssuedProducts.ManufacturedProduct;
			StringBatch.Characteristic			= IssuedProducts.ItemVariant;
			StringBatch.Series					= IssuedProducts.ProductionSeries_;
			StringBatch.Purpose				= IssuedProducts.AssignmentOfProducts;
			StringBatch.Currency					= IssuedProducts.Currency;
			StringBatch.Lot					= IssuedProducts.ProductsBatch;
			StringBatch.LotVendorAttributes	= IssuedProducts.ProductBatchAccountingDimension;
			StringBatch.UnitOfMeasure		= IssuedProducts.UnitOfMeasurementProducts;
			
			StringBatch.Count	= IssuedProducts.NumberOfProducts_1;
			StringBatch.Sum		= IssuedProducts.TotalOutput;
			StringBatch.OffBalanceSheetAmount = IssuedProducts.AmountOffBalanceSheetProducts;
			
			If TreeParameters.ResultTypeValueTree And IssuedProducts.ExplosionIsRequired 
				And IssuedProducts.NumberOfProducts_1 <> 0 Then
						
				TreeParameters.MapOfNodes.Insert(StringBatch.NodeID, 
					StringBatch);
			EndIf;
		EndIf;
		
		If (IssuedProducts.ExplosionIsRequired Or IssuedProducts.ItIsRequiredToUnpackAdditionalExpenseAmount)
			And TreeParameters.ResultTypeValueTree
			And TreeParameters.DynamicReading
			And IssuedProducts.NumberOfProducts_1 <> 0 Then
			
			StringBatch.Rows.Add();
			
		ElsIf IssuedProducts.ExplosionIsRequired
			And IssuedProducts.NumberOfProducts_1 <> 0 Then //checking for a suspended issue in the selected period
			
			NewSelectionLine = TreeParameters.NodeSelectionTable.Add();
			FillPropertyValues(NewSelectionLine, IssuedProducts);
			NewSelectionLine.Level = TreeParameters.NodeLevel;
			NewSelectionLine.Cost_Data = TreeParameters.ReportParameters.Cost_Data;

			NewSelectionLine.NodeID = NewNodeId;
			HigherLevelNodes = New Array();
			TreeParameters.HigherLevelNodes.Insert(NewNodeId, HigherLevelNodes);
			If Not ValueIsFilled(NewSelectionLine.IdOfFirstLevelNode) Then
				NewSelectionLine.IdOfFirstLevelNode = NewNodeId;
			EndIf;
			NewSelectionLine.NodeOfFirstLevel_AnalyticsOfManufacturedProductAccounting = IssuedProducts.ProductsAccountingDimension;
			NewSelectionLine.ExpenseAccountingAnalytics = IssuedProducts.ProductsAccountingDimension;
			NewSelectionLine.NodeOfFirstLevel_LotReferenceOfManufacturedProducts = IssuedProducts.ProductsBatch;
			NewSelectionLine.NodeOfFirstLevelIs_BatchAccountingAnalysisOfManufacturedProductsLotsVendorAttributes = IssuedProducts.ProductBatchAccountingDimension;
			// Comment 406.
			// When uncoupling semi-finished products, selection for the intended purpose is not necessary,
			// because the semi-finished product can be released without an appointment or with an indication of another appointment.
			// Therefore, we fill in the value in the selection table, but turn off the selection by appointment.
			NewSelectionLine.ForAllAppointments = True;
			
			NewSelectionLine.Denominator = Max(-IssuedProducts.Denominator, IssuedProducts.Denominator);
			NewSelectionLine.ProductsQuantity = Max(-IssuedProducts.NumberOfProducts_1, IssuedProducts.NumberOfProducts_1);
			NewSelectionLine.DeployAdditionalCosts = TreeParameters.ReportParameters.DeployAdditionalCosts;
			NewSelectionLine.DateOfOriginalLotReference_BeginningOfMonth = BegOfMonth(NewSelectionLine.OriginalBatchDate);
			NewSelectionLine.DateOfOriginalLotReference_EndOfMonth = EndOfMonth(NewSelectionLine.OriginalBatchDate);
			
			NewSelectionLine.Sum = IssuedProducts.TotalOutput;
			NewSelectionLine.OffBalanceSheetAmount = IssuedProducts.AmountOffBalanceSheetProducts;
			
			If TreeParameters.ResultTypeValueTree Then
				ResultTable2 = StringBatch;
			Else
				ResultTable2 = Result;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If TreeParameters.ResultTypeTempTableManager Then
		CostCalculationAppliedAlgorithms.PutTableOfValuesInTemporaryTable(
			TreeParameters.TempTablesManager,
			"PreliminaryResult",
			Result,
			TreeParameters.TableFields);
		TreeParameters.GlobalTempTables.Add("PreliminaryResult");
		Result.Clear();
	EndIf;
	
	TreeParameters.ReportParameters.NumberOfSelectionNodes = TreeParameters.NodeSelectionTable.Count();
	If TreeParameters.ReportParameters.NumberOfSelectionNodes > 0 Then
		#Region VariantsOfConnectionConditionsByNodeParameters
		TreeParameters.VariantsOfConnectionConditionsByNodeParameters.ManufacturedProduct = 1;
		TreeParameters.VariantsOfConnectionConditionsByNodeParameters.ProductsBatch = 1;
		TreeParameters.VariantsOfConnectionConditionsByNodeParameters.ItemVariant = 1;
		TreeParameters.VariantsOfConnectionConditionsByNodeParameters.ManufacturedProduct = 1;
		TreeParameters.VariantsOfConnectionConditionsByNodeParameters.ProductionSeries_ = 1;
		TreeParameters.VariantsOfConnectionConditionsByNodeParameters.AssignmentOfProducts = 0;
		TreeParameters.VariantsOfConnectionConditionsByNodeParameters.ProductBatchAccountingDimension = 1;
		
		ArrayOfIndexSets = New Array();
		ArrayOfIndexSets.Add("ProductsBatch");
		ArrayOfIndexSets.Add("NodeID");
		
		ArrayOfIndexSets.Add(TreeParameters.IndexToCheckForLooping);
		#EndRegion
		
		// Comment 520.
		// The array of registrars should be filled in only at the first step of uncoupling.
		TreeParameters.ReportParameters.Recorders = New Array();
		
		CostCalculationAppliedAlgorithms.PutTableOfValuesInTemporaryTable(
			TreeParameters.TempTablesManager,
			"NodeSelectionTable", TreeParameters.NodeSelectionTable,
			TreeParameters.NodeSelectionTable_ColumnNames,
			ArrayOfIndexSets);
			
		ArrayOfIndexSets = New Array();
		PlaceTableOfSelectionsOfIWTNodesTableOfNodes(TreeParameters);

		FindOutLevelOfNodesOfCostTree(TreeParameters, ResultTable2);
	EndIf;
	
	If TreeParameters.ResultTypeTempTableManager Then
		
		MergedTempTables = "PreliminaryResult";
		If CostCalculationAppliedAlgorithms.TemporaryTableExists(TreeParameters.TempTablesManager,
			"PreliminaryResult2") Then
				
			MergedTempTables = "PreliminaryResult,PreliminaryResult2";
		EndIf;
		
		// The columns have different types in the tables, so to use the add query method,
		// fill in the tables separately, and combine them at the end.
		CostCalculationAppliedAlgorithms.MergeTemporaryTables(TreeParameters.TempTablesManager,
			MergedTempTables, "Result",
			TreeParameters.TableFields, "", "", True); //@Query-part
			
	EndIf;
	
	ToDisplayErrorsOfDisentanglement(TreeParameters);
	
EndProcedure

Procedure FillInIndexToCheckLooping(TreeParameters, CheckTTIndexingNodeTable)
	
	ArrayOfIndexedColumns = New Array();
	ArrayOfIndexedColumns.Add("IdOfFirstLevelNode"); //@Query-part
	ArrayOfIndexedColumns.Add("ExpenseAccountingAnalytics"); //@Query-part
	ArrayOfIndexedColumns.Add("BatchCost"); //@Query-part
	
	// See comment 204.
	If TreeParameters.VariantsOfConnectionConditionsByNodeParameters.ProductsBatch = 1 Then
		ArrayOfIndexedColumns.Add("ProductsBatch"); //@Query-part
	EndIf;
	If TreeParameters.VariantsOfConnectionConditionsByNodeParameters.ProductBatchAccountingDimension = 1 Then
		ArrayOfIndexedColumns.Add("ProductBatchAccountingDimension"); //@Query-part
	EndIf;
	If TreeParameters.VariantsOfConnectionConditionsByNodeParameters.ManufacturedProduct = 1 Then
		ArrayOfIndexedColumns.Add("ManufacturedProduct"); //@Query-part
	EndIf;
	If TreeParameters.VariantsOfConnectionConditionsByNodeParameters.ItemVariant = 1 Then
		ArrayOfIndexedColumns.Add("ItemVariant"); //@Query-part
	EndIf;
	If TreeParameters.VariantsOfConnectionConditionsByNodeParameters.ProductionSeries_ = 1 Then
		ArrayOfIndexedColumns.Add("ProductionSeries_"); //@Query-part
	EndIf;
	If TreeParameters.VariantsOfConnectionConditionsByNodeParameters.AssignmentOfProducts = 1 Then
		ArrayOfIndexedColumns.Add("AssignmentOfProducts"); //@Query-part
	EndIf;
	
	ArrayOfIndexedColumns.Add("NodeID"); //@Query-part
	NewRowOfIndexedColumns = StrConcat(ArrayOfIndexedColumns, ",");
	ReindexTTNodeTable = CheckTTIndexingNodeTable
		And TreeParameters.IndexToCheckForLooping <> Undefined
		And NewRowOfIndexedColumns <> TreeParameters.IndexToCheckForLooping;
	
	TreeParameters.Insert("IndexToCheckForLooping", NewRowOfIndexedColumns);
	
	If ReindexTTNodeTable Then
		SourceName = "NodeTable_";
		DestinationName = "NodeTableCopy";
		CostCalculationAppliedAlgorithms.CopyTemporaryTable(TreeParameters.TempTablesManager,
			SourceName, DestinationName);
		CostCalculationAppliedAlgorithms.DestroyTemporaryTables(TreeParameters.TempTablesManager,
			SourceName);
		CostCalculationAppliedAlgorithms.CopyTemporaryTable(TreeParameters.TempTablesManager,
			DestinationName, SourceName, NewRowOfIndexedColumns) 
	EndIf;
	
EndProcedure

Procedure PlaceTableOfSelectionsOfIWTNodesTableOfNodes(TreeParameters)

	FillInIndexToCheckLooping(TreeParameters, False);
	
	// Comment 510.
	// A table of nodes is needed to track looping.
	CostCalculationAppliedAlgorithms.PutTableOfValuesInTemporaryTable(
		TreeParameters.TempTablesManager,
		"NodeTable_", TreeParameters.NodeSelectionTable,
		TreeParameters.NodeSelectionTable_ColumnNames,
		TreeParameters.IndexToCheckForLooping);
	
EndProcedure

Procedure ToDisplayErrorsOfDisentanglement(TreeParameters)
	If TreeParameters.ToOutputErrors Then
		CommonClientServer.ReportErrorsToUser(TreeParameters.Diagnostics.Errors);
	EndIf;
EndProcedure

Procedure DestroyTemporaryTables(TreeParameters)
	
	TextsOfDestructionOfTemporaryTables = New Array();
	For Each TempTable In TreeParameters.TempTablesManager.Tables Do
		If TreeParameters.GlobalTempTables.Find(TempTable.FullName) = Undefined Then
			TextsOfDestructionOfTemporaryTables.Add("DROP " + TempTable.FullName);
		EndIf;
	EndDo;
	
	If TextsOfDestructionOfTemporaryTables.Count() = 0 Then
		Return;
	EndIf;
	
	Query = New Query();
	Query.TempTablesManager = TreeParameters.TempTablesManager;
	Query.Text = StrConcat(TextsOfDestructionOfTemporaryTables, ";");
	Query.Execute();
	
EndProcedure

Procedure AddDataToTempTable(TempTableManager, TempTableName, Data, ColumnsNames)
	Query = New Query();
	Query.TempTablesManager = TempTableManager;
	Template = "
		|SELECT
		|	%1
		|ADD %2
		|FROM &QueryParameterTableOfValues AS T
		|"; //@Query-part

	ColumnNamesWithSynonyms = CostCalculationAppliedAlgorithms.AddSynonymsToColumns(ColumnsNames, "T");
	Query.Text = StrTemplate(Template, ColumnNamesWithSynonyms, TempTableName);
	Query.SetParameter("QueryParameterTableOfValues", Data);
	Query.Execute();
EndProcedure

Procedure CalculateExpenseOfBatches(Query, TreeParameters)
	QueryTextArray = New Array();
	QueryTextArray.Add(Query.Text);
	QueryTextArray.Add(QueryTextBatchEXPENSE());
	Query.Text = StrConcat(QueryTextArray, Common.QueryBatchSeparator());
	
	Explanation = NStr("ru = 'Материальные затраты узлов';
						|vi = 'Material costs of sub-assets';
						|en = 'Material costs of sub-assets'; fa = 'Material costs of sub-assets';
						|it = 'Material costs of sub-assets';
						|pl = 'Material costs of sub-assets';
						|tr = 'Alt varlıkların malzeme giderleri'");
	EventName = NStr("ru = 'Расчет расхода партий в НЗП по уровню узлов';
					|vi = 'Calculation of lot expenses in WIP by sub-asset level';
					|en = 'Calculation of lot expenses in WIP by sub-asset level'; fa = 'Calculation of lot expenses in WIP by sub-asset level';
					|it = 'Calculation of lot expenses in WIP by sub-asset level';
					|pl = 'Calculation of lot expenses in WIP by sub-asset level';
					|tr = 'Alt varlık seviyesine göre TMÜ’deki lot tüketiminin hesaplanması'");
	QueryResult = ExecuteRequestWithMeasurementForProtocol(Query, TreeParameters, Explanation, EventName);
	
	LastQueryIndex = QueryResult.UBound();
	RetirementFromUnfinishedProductionForBalance = QueryResult[LastQueryIndex - 2].Unload();
	PrimaryGNZPParties = QueryResult[LastQueryIndex - 1].Unload();
	PrimaryGNZPParties.Indexes.Add("AnalystID");
	BatchEXPENSE = QueryResult[LastQueryIndex].Unload();
	
	For Each RetirementLine In RetirementFromUnfinishedProductionForBalance Do
		FilterStructure1 = New Structure("AnalystID", RetirementLine.AnalystID);
		Receipt_Lines = PrimaryGNZPParties.FindRows(FilterStructure1);
		
		// The total Balance by batch should be calculated by the month of expenditure, taking into account the possible expenditure in previous months.
		QuantityBalanceByBatch = 0;
		SelectedBatchLines = New Array;
		For Each ArrivalLine In Receipt_Lines Do
			If ArrivalLine.Period > RetirementLine.Period Or ArrivalLine.Count = 0 Then
				Continue;
			EndIf;
			
			SelectedBatchLines.Add(ArrivalLine);
			QuantityBalanceByBatch = QuantityBalanceByBatch + ArrivalLine.Count;
		EndDo;
		
		NumberOfRetirements = RetirementLine.Count;
		For Each ArrivalLine In SelectedBatchLines Do
			
			// In the work-in-progress section, accounting by average.
			// We take from each batch the number of disposals, relative to the Balance ratio of the batch, in the total Balance.
			CountExpense = NumberOfRetirements * ArrivalLine.Count / QuantityBalanceByBatch;
			
			BatchExpenseLine = BatchEXPENSE.Add();
			FillPropertyValues(BatchExpenseLine, ArrivalLine);
			BatchExpenseLine.Period = RetirementLine.Period;
			BatchExpenseLine.Count = CountExpense;
			
			ArrivalLine.Count = ArrivalLine.Count - CountExpense;
			RetirementLine.Count = RetirementLine.Count - CountExpense;
		EndDo;
	EndDo;
	
	CostCalculationAppliedAlgorithms.PutTableOfValuesInTemporaryTable(
		Query.TempTablesManager,
		"BatchEXPENSE",
		BatchEXPENSE,
		"NodeID,Period,Organization,ItemsLocationAttributes,LotVendorAttributes,Lot,
			|CorItemsLocationAttributes,CorLot,Count",
		"NodeID,Organization,ItemsLocationAttributes,Lot,Period");
EndProcedure

Function ExecuteRequestWithMeasurementForProtocol(Query, TreeParameters, Explanation, EventName)
	CalculationParameters = New Structure;
	CalculationParameters.Insert("QueryExecutionResult", "");
	BeginTime = CurrentUniversalDateInMilliseconds();
	QueryResult = CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(
		CalculationParameters, Query,,, True, Explanation);
		
	Duration = (CurrentUniversalDateInMilliseconds() - BeginTime) / 1000;
	Template = NStr("ru = 'Уровень узлов: %1
			|Общее время: %2
			|Количество узлов отбора: %3
			|%4';
			|vi = 'Node level: %1
			|Total time: %2
			|Number of filter nodes: %3
			|%4';
			|en = 'Node level: %1
			|Total time: %2
			|Number of filter nodes: %3
			|%4'; fa = 'Node level: %1
			|Total time: %2
			|Number of filter nodes: %3
			|%4';
			|it = 'Node level: %1
			|Total time: %2
			|Number of filter nodes: %3
			|%4';
			|pl = 'Node level: %1
			|Total time: %2
			|Number of filter nodes: %3
			|%4';
			|tr = 'Alt varlık seviyesi:%1
			|Toplam süre:%2 
			|Seçim yapılan alt varlık sayısı: %3
			|%4'");
	ProtocolText_ = StrTemplate(Template,
		TreeParameters.NodeLevel,
		CostCalculationProtocol.TimePresentation(Duration),
		TreeParameters.ReportParameters.NumberOfSelectionNodes,
		CalculationParameters.QueryExecutionResult);
	TreeParameters.Diagnostics.MeasurementsOfQueryExecutionByNodeLevels.Add(ProtocolText_);
	
	WriteLogEvent(TreeParameters.Diagnostics.LogEventGroup + EventName,
		EventLogLevel.Information,,,
		ProtocolText_);
	
	Return QueryResult;
EndFunction

Function NodesCost(TreeParameters, DeductAdditionalExpenses, AddGroupingByNodeIds)
	
	RowTotalsByNodeId = "";
	If AddGroupingByNodeIds Then
		RowTotalsByNodeId = "
			|TOTALS BY
			|	NodeID
			|"; //@Query-part
	EndIf;
	
	Query = RequestReleasedProducts(True, TreeParameters);
	Query.SetParameter("AddSemiFinishedProductsToResult", TreeParameters.AddSemiFinishedProductsToResult);
	Query.SetParameter("NodeLevel", TreeParameters.NodeLevel);
	
	CalculateExpenseOfBatches(Query, TreeParameters);
	
	QueryTextArray = New Array();
	QueryTextArray.Add(QueryTextNodulationResultsPreliminary(DeductAdditionalExpenses, TreeParameters));
	QueryTextArray.Add(QueryTextNodulationResults(TreeParameters));
	QueryTextArray.Add("DROP NodulationResultsPreliminary"); //@Query-part
	QueryTextArray.Add(TreeParameters.QueryTextProductCosts + RowTotalsByNodeId);
	If TreeParameters.ResultTypeTempTableManager Then
		QueryTextArray.Add(
			TreeParameters.QueryTextNodesThatNeedToBeSeparated + RowTotalsByNodeId);
	EndIf;
	Query.Text = StrConcat(QueryTextArray, Common.QueryBatchSeparator());
	
	If TreeParameters.ResultTypeValueTree Then
		Query.Text = StrReplace(Query.Text, "ADD PreliminaryResult2", ""); //@Query-part
		
	ElsIf TreeParameters.ResultTypeTempTableManager Then
		If Not TreeParameters.AddedTempTableOfResultsOfUncoupling Then
			Query.Text = StrReplace(Query.Text, "ADD PreliminaryResult2",
				"INTO PreliminaryResult2"); //@Query-part
			TreeParameters.GlobalTempTables.Add("PreliminaryResult2");
			TreeParameters.AddedTempTableOfResultsOfUncoupling = True;
		EndIf;
	EndIf;
	
	Explanation = NStr("ru = 'Себестоимость узлов';
						|vi = 'Node cost';
						|en = 'Node cost'; fa = 'Node cost';
						|it = 'Node cost';
						|pl = 'Node cost';
						|tr = 'Düğümlerin maliyeti'");
	EventName = NStr("ru = 'Выполнение запроса по уровню узлов';
					|vi = 'Query execution by node level';
					|en = 'Query execution by node level'; fa = 'Query execution by node level';
					|it = 'Query execution by node level';
					|pl = 'Query execution by node level';
					|tr = 'Düğüm seviyesine göre sorgu yürütme'");
	QueryResult = ExecuteRequestWithMeasurementForProtocol(Query, TreeParameters, Explanation, EventName);
	
	If TypeOf(QueryResult) = Type("Array") Then
		QueryResult = QueryResult[QueryResult.UBound()];
	EndIf;
	
	PrincipleOfBypass = ?(AddGroupingByNodeIds,
		QueryResultIteration.ByGroups, QueryResultIteration.Linear);
	Return QueryResult.Select(PrincipleOfBypass);
	
EndFunction

Procedure FindOutLevelOfNodesOfCostTree(TreeParameters, ResultTable2)
	
	TreeParameters.NodeLevel = TreeParameters.NodeLevel + 1;
	
	DeductAdditionalExpenses = TreeParameters.ReportParameters.DeployAdditionalCosts And Not (TreeParameters.NodeLevel = 1);
	// See comment 3970.
	AddGroupingByNodeIds = TreeParameters.ResultTypeValueTree 
		And Not TreeParameters.InteractiveSetup
		And Not TreeParameters.DynamicReading;
		
	ProductCosts = NodesCost(TreeParameters, DeductAdditionalExpenses,
		AddGroupingByNodeIds);
	DestroyTemporaryTables(TreeParameters);
	
	// See comment 759.
	MapOfNodes = Undefined;
	If TreeParameters.ResultTypeValueTree Then
		MapOfNodes = New Map();
	EndIf;
	
	TreeParameters.NodeSelectionTable.Clear();
	Result = Undefined;
	If Not TreeParameters.ResultTypeValueTree Then
		Result = ResultTable2
	EndIf;
	
	UpstreamNodesToDelete = New Map();
	While ProductCosts.Next() Do
		If TreeParameters.ResultTypeValueTree Then
			Result = TreeParameters.MapOfNodes[ProductCosts.NodeID].Rows;
		EndIf;
		
		If AddGroupingByNodeIds Then
			CurrentBatch = ProductCosts.Select();
			While CurrentBatch.Next() Do
				BatchResultTable = ToProcessExpensesForManufacturedProducts(Result, CurrentBatch,
					MapOfNodes, TreeParameters, UpstreamNodesToDelete);
			EndDo;
		Else
			BatchResultTable = ToProcessExpensesForManufacturedProducts(Result, ProductCosts,
				MapOfNodes, TreeParameters, UpstreamNodesToDelete);
		EndIf;
	EndDo;
	
	TreeParameters.ReportParameters.NumberOfSelectionNodes = TreeParameters.NodeSelectionTable.Count();
	If TreeParameters.ReportParameters.NumberOfSelectionNodes > 0 And Not TreeParameters.DynamicReading Then
		
		#Region VariantsOfConnectionConditionsByNodeParameters
		TreeParameters.VariantsOfConnectionConditionsByNodeParameters.ManufacturedProduct = 1;
		TreeParameters.VariantsOfConnectionConditionsByNodeParameters.ProductsBatch = 1;
		TreeParameters.VariantsOfConnectionConditionsByNodeParameters.ItemVariant = 1;
		TreeParameters.VariantsOfConnectionConditionsByNodeParameters.ManufacturedProduct = 1;
		TreeParameters.VariantsOfConnectionConditionsByNodeParameters.ProductionSeries_ = 1;
		TreeParameters.VariantsOfConnectionConditionsByNodeParameters.AssignmentOfProducts = 0;
		TreeParameters.VariantsOfConnectionConditionsByNodeParameters.ProductBatchAccountingDimension = 1;
		
		// The set of fields for indexing must take into account the variants of the connection conditions.
		IndexSetsOfNodeSelectionTable = New Array();
		IndexSetsOfNodeSelectionTable.Add("ProductsBatch");
		IndexSetsOfNodeSelectionTable.Add("NodeID");
		
		#EndRegion
		
		If TreeParameters.ResultTypeValueTree Then
			// Comment 759.
			// There is no need to store the correspondence of nodes for the entire tree,
			// for optimization we update the correspondence when each level of the tree is untangled.
			TreeParameters.MapOfNodes = MapOfNodes;
		EndIf;
		
		// It is not necessary to store the higher nodes of the previous levels, since they are located in the temp table of the higher nodes.
		For Each UpperNode In UpstreamNodesToDelete Do
			TreeParameters.HigherLevelNodes.Delete(UpperNode.Key);
		EndDo;
			
		CheckCalculationParameters(TreeParameters);
		PlaceUpstreamNodesInTempTable(TreeParameters);
		ThereAreLinesForUntangling = AddNodeSelectionTableToTemporary(
			TreeParameters, IndexSetsOfNodeSelectionTable);
		If TreeParameters.Diagnostics.HasErrors Or Not ThereAreLinesForUntangling Then
			Return;
		EndIf;
		
		// See comment 520.
		TreeParameters.ReportParameters.Recorders = New Array();
		
		FindOutLevelOfNodesOfCostTree(TreeParameters, BatchResultTable);
	EndIf;
	
EndProcedure

Function ToProcessExpensesForManufacturedProducts(Result, CurParty, MapOfNodes, TreeParameters, UpstreamNodesToDelete)
	
	BatchResultTable = Undefined;

	NewNodeId = String(New UUID);
	If TreeParameters.ResultTypeValueTree
		And (TreeParameters.AddSemiFinishedProductsToResult Or Not CurParty.ExplosionIsRequired) Then

		StringBatch = Result.Add(); // ValueTreeRow
		FillPropertyValues(StringBatch, CurParty);

		StringBatch.Id	= New UUID;

		If TreeParameters.ResultTypeValueTree
			And (CurParty.ExplosionIsRequired Or CurParty.ItIsRequiredToUnpackAdditionalExpenseAmount) Then
				
			MapOfNodes.Insert(NewNodeId, StringBatch);
		EndIf;

	EndIf;

	If (CurParty.ExplosionIsRequired Or CurParty.ItIsRequiredToUnpackAdditionalExpenseAmount)
		And TreeParameters.ResultTypeValueTree
		And TreeParameters.DynamicReading Then
		
		// Comment 649.
		// Adding an empty line in the value tree
		// is necessary so that during dynamic reading, 
		// it is possible to click on + and get the location for the selected position.
		// When decomposing, the subordinate rows must first be cleared.
		StringBatch.Rows.Add();

	ElsIf (CurParty.ExplosionIsRequired Or CurParty.ItIsRequiredToUnpackAdditionalExpenseAmount) Then
			
		NewSelectionLine = TreeParameters.NodeSelectionTable.Add();
		FillPropertyValues(NewSelectionLine, CurParty);
		
		NewSelectionLine.NodeOfFirstLevel_AnalyticsOfManufacturedProductAccounting = CurParty.ProductsAccountingDimension;
		NewSelectionLine.NodeOfFirstLevelIs_BatchAccountingAnalysisOfManufacturedProductsLotsVendorAttributes = CurParty.ProductBatchAccountingDimension;
		NewSelectionLine.NodeOfFirstLevel_LotReferenceOfManufacturedProducts = CurParty.ProductsBatch;
		
		NewSelectionLine.ManufacturedProduct = CurParty.Products;
		NewSelectionLine.ItemVariant = CurParty.Characteristic;
		NewSelectionLine.ProductionSeries_ = CurParty.Series;
		// See comment 406, 204.
		NewSelectionLine.ForAllAppointments = True;
		NewSelectionLine.AssignmentOfProducts = CurParty.Purpose;
		NewSelectionLine.ProductsBatch = CurParty.Lot;
		
		NewSelectionLine.ProductBatchAccountingDimension = CurParty.BatchAccountingDimensionCost;
		NewSelectionLine.ExpenseAccountingAnalytics = CurParty.CostAccountingDimension;

		// For the denominator and quantity of products, we take the value module
		// so that the sign of the quantity and cost amounts is determined by the numerator,
		// which will be > 0 at the time of release, and at the storno < 0
		NewSelectionLine.Numerator = CurParty.Count;
		NewSelectionLine.ProductsQuantity = Max(-CurParty.Count, CurParty.Count);
		NewSelectionLine.DateOfOriginalLotReference_BeginningOfMonth = BegOfMonth(NewSelectionLine.OriginalBatchDate);
		NewSelectionLine.DateOfOriginalLotReference_EndOfMonth = EndOfMonth(NewSelectionLine.OriginalBatchDate);
		NewSelectionLine.AccountingDimensionFinishedProduct = CurParty.CostAccountingDimension;
		
		NewSelectionLine.Cost_Data = TreeParameters.ReportParameters.Cost_Data;
		
		// Before changing the UID of the split line, we add an array of all higher-level nodes to the correspondence.
		NewSelectionLine.Level = TreeParameters.NodeLevel;
		HigherLevelNodes = Common.CopyRecursive(
			TreeParameters.HigherLevelNodes.Get(NewSelectionLine.NodeID));
		HigherLevelNodes.Add(NewSelectionLine.NodeID);
		UpstreamNodesToDelete.Insert(NewSelectionLine.NodeID);
		TreeParameters.HigherLevelNodes.Insert(NewNodeId, HigherLevelNodes);
		NewSelectionLine.NodeID = NewNodeId;
		
		NewSelectionLine.EndDate = TreeParameters.ReportParameters.EndDate;
		NewSelectionLine.DeployAdditionalCosts = TreeParameters.ReportParameters.DeployAdditionalCosts;

		If TreeParameters.ResultTypeValueTree Then
			BatchResultTable = StringBatch;
		Else
			BatchResultTable = Result;
		EndIf;
	EndIf;
	
	Return BatchResultTable;
	
EndFunction

Procedure PlaceUpstreamNodesInTempTable(TreeParameters)
	
	TableOfParentNodes = New ValueTable();
	TableOfParentNodes.Columns.Add("UpperNode", TreeParameters.FieldsStructure.NodeID);
	TableOfParentNodes.Columns.Add("SourceNode", TreeParameters.FieldsStructure.NodeID);
	
	For Each Node In TreeParameters.HigherLevelNodes Do
		For Each UpperNode In Node.Value Do
			NewRow = TableOfParentNodes.Add();
			NewRow.UpperNode = UpperNode;
			NewRow.SourceNode = Node.Key;
		EndDo;
	EndDo;
	
	ColumnsNames = "
		|T.UpperNode AS UpperNode,
		|T.SourceNode AS SourceNode
		|";
	
	If TreeParameters.UpstreamNodesAdded Then
		AddDataToTempTable(TreeParameters.TempTablesManager, "HigherLevelNodes",
			TableOfParentNodes,
			ColumnsNames);
	Else
		CostCalculationAppliedAlgorithms.PutTableOfValuesInTemporaryTable(
			TreeParameters.TempTablesManager,
			"HigherLevelNodes",
			TableOfParentNodes,
			ColumnsNames,
			"SourceNode, UpperNode");
		
	EndIf;
	
EndProcedure

Procedure CheckCalculationParameters(TreeParameters)
	
	If TreeParameters.MaximumDepthOfNodulation > 0
		And TreeParameters.NodeLevel > TreeParameters.MaximumDepthOfNodulation Then
		
		ProtocolText_ = StrTemplate(
			NStr("ru = 'Превышена максимальная глубина разузлования дерева себестоимости (%1)';
				|vi = 'The maximum explosion depth of the cost tree is exceeded (%1)';
				|en = 'The maximum explosion depth of the cost tree is exceeded (%1)'; fa = 'The maximum explosion depth of the cost tree is exceeded (%1)';
				|it = 'The maximum explosion depth of the cost tree is exceeded (%1)';
				|pl = 'The maximum explosion depth of the cost tree is exceeded (%1)';
				|tr = 'Maliyet ağacı ayrıştırma maksimum derinliği aşıldı (%1)'"),
			TreeParameters.MaximumDepthOfNodulation);
		
		ErrorsGroup1 = NStr("ru = 'Проверка глубины разузлования';
							|vi = 'Check explosion depth';
							|en = 'Check explosion depth'; fa = 'Check explosion depth';
							|it = 'Check explosion depth';
							|pl = 'Check explosion depth';
							|tr = 'Ayrıştırma derinliği kontrolü'");
		WriteLogEvent(TreeParameters.Diagnostics.LogEventGroup + ErrorsGroup1,
			EventLogLevel.Error,,,
			ProtocolText_);
			
		CommonClientServer.AddUserError(TreeParameters.Diagnostics.Errors,
			"", ProtocolText_, ErrorsGroup1);
		TreeParameters.Diagnostics.HasErrors = True;
		Return;
	EndIf;
	
EndProcedure

// The function checks and excludes possible looping of the junction.
Function AddNodeSelectionTableToTemporary(TreeParameters, IndexSetsOfNodeSelectionTable)
	
	FillInIndexToCheckLooping(TreeParameters, True);
	
	CostCalculationAppliedAlgorithms.PutTableOfValuesInTemporaryTable(
		TreeParameters.TempTablesManager,
		"NodeSelectionTablePreliminary", TreeParameters.NodeSelectionTable,
		TreeParameters.NodeSelectionTable_ColumnNames,
		TreeParameters.IndexToCheckForLooping);
	
	// 1. We destroy the TT table of node selections, if it exists.
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(TreeParameters.TempTablesManager,
		"NodeSelectionTable");
	
	Query = New Query();
	Query.TempTablesManager = TreeParameters.TempTablesManager;
	QueriesTexts = New Array();
	
	// 2. Looking for possible looping.
	QueryText = "
		|SELECT
		|	&ColumnNamesWithSynonyms AS ColumnNamesWithSynonyms,
		|	TRUE IN (
		|		SELECT TOP 1 TRUE
		|	
		|		FROM NodeTable_ AS NodeTable_
		|		INNER JOIN HigherLevelNodes AS HigherLevelNodes
		|		ON NodeTable_.IdOfFirstLevelNode = T.IdOfFirstLevelNode
		|			AND NodeTable_.ExpenseAccountingAnalytics =  T.ExpenseAccountingAnalytics
		|			AND NodeTable_.BatchCost = T.BatchCost
		|			AND &AdditionalConnectionConditions
		|		
		|			AND T.NodeID = HigherLevelNodes.SourceNode
		|			AND HigherLevelNodes.UpperNode = NodeTable_.NodeID
		|	) AS Looping
		|
		|INTO NodeSelectionTablePreliminary2
		|
		|FROM NodeSelectionTablePreliminary AS T
		|";
	
	#Region VariantsOfConnectionConditionsByNodeParameters
	// See comment 204.
	ConnectionConditions = New Array();
		
	If TreeParameters.VariantsOfConnectionConditionsByNodeParameters.ProductsBatch = 1 Then
		ConnectionConditions.Add("AND NodeTable_.ProductsBatch = T.ProductsBatch"); //@Query-part
	EndIf;
	If TreeParameters.VariantsOfConnectionConditionsByNodeParameters.ProductBatchAccountingDimension = 1 Then
		ConnectionConditions.Add(
			"AND NodeTable_.ProductBatchAccountingDimension = T.ProductBatchAccountingDimension"); //@Query-part
	EndIf;
	If TreeParameters.VariantsOfConnectionConditionsByNodeParameters.ManufacturedProduct = 1 Then
		ConnectionConditions.Add("AND NodeTable_.ManufacturedProduct = T.ManufacturedProduct"); //@Query-part
	EndIf;
	If TreeParameters.VariantsOfConnectionConditionsByNodeParameters.ItemVariant = 1 Then
		ConnectionConditions.Add("AND NodeTable_.ItemVariant = T.ItemVariant"); //@Query-part
	EndIf;
	If TreeParameters.VariantsOfConnectionConditionsByNodeParameters.ProductionSeries_ = 1 Then
		ConnectionConditions.Add("AND NodeTable_.ProductionSeries_ = T.ProductionSeries_"); //@Query-part
	EndIf;
	If TreeParameters.VariantsOfConnectionConditionsByNodeParameters.AssignmentOfProducts = 1 Then
		ConnectionConditions.Add("AND NodeTable_.AssignmentOfProducts = T.AssignmentOfProducts"); //@Query-part
	EndIf;
	
	QueryText = StrReplace(QueryText, "AND &AdditionalConnectionConditions",
		?(ConnectionConditions.Count() = 0,
			"",
			StrConcat(ConnectionConditions, Chars.LF))); //@Query-part
	#EndRegion
	
	QueriesTexts.Add(QueryText);
	
	// 3. Add to the TT table of node selections only the rows for which there is no looping.
	QueryText = "
		|SELECT
		|	&ColumnNamesWithSynonyms AS ColumnNamesWithSynonyms
		|INTO NodeSelectionTable
		|FROM NodeSelectionTablePreliminary2 AS T
		|WHERE
		|	NOT T.Looping
		|";
	
	ArrayOfIndexSets = New Array;
	For Each Set In IndexSetsOfNodeSelectionTable Do
		ArrayOfIndexSets.Add("(" + Set + ")");
	EndDo;
	IndexingFieldText = "
		|INDEX BY SETS
		|(
		|" + StrConcat(ArrayOfIndexSets, "," + Chars.LF) + "
		|)"; //@Query-part
		
	QueriesTexts.Add(QueryText + IndexingFieldText);
	
	// 4. Add to the TT table nodes only the rows for which there is no looping.
	QueryText = "
		|SELECT
		|	&ColumnNamesWithSynonyms AS ColumnNamesWithSynonyms
		|ADD NodeTable_
		|FROM NodeSelectionTablePreliminary2 AS T
		|WHERE
		|	NOT T.Looping
		|";
	QueriesTexts.Add(QueryText);
	
	// Comment 975.
	// 5. We collect a temp table on looping, as a result we will present it as a nomenclature looping.
	QueryText = "
		|SELECT
		|	&ColumnNamesWithSynonyms AS ColumnNamesWithSynonyms
		|INTO LoopingNodes
		|FROM NodeSelectionTablePreliminary2 AS T
		|WHERE
		|	T.Looping
		|";
	
	QueriesTexts.Add(QueryText);
	
	QueryText = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	QueryText = StrReplace(QueryText, "&ColumnNamesWithSynonyms AS ColumnNamesWithSynonyms",
		TreeParameters.NodeSelectionTable_ColumnNamesWithSynonyms);
	Query.Text = QueryText;
	
	CalculationParameters = New Structure;
	CalculationParameters.Insert("QueryExecutionResult", "");
	BeginTime = CurrentUniversalDateInMilliseconds();
	CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(
		CalculationParameters, Query,,, False, NStr("ru = 'Добавить таблицу отбора узлов во временную';
													|vi = 'Add a node filter table to the temporary one';
													|en = 'Add a node filter table to the temporary one'; fa = 'Add a node filter table to the temporary one';
													|it = 'Add a node filter table to the temporary one';
													|pl = 'Add a node filter table to the temporary one';
													|tr = 'Düğüm seçim tablosunu geçici tabloya ekle'"));
	Duration = (CurrentUniversalDateInMilliseconds() - BeginTime) / 1000;
	ErrorsGroup1 = NStr("ru = 'Проверка зацикливания';
						|vi = 'Looping check';
						|en = 'Looping check'; fa = 'Looping check';
						|it = 'Looping check';
						|pl = 'Looping check';
						|tr = 'Döngü kontrolü'");
	Template = NStr("ru = 'Уровень узлов: %1
		|Общее время: %2
		|Количество узлов отбора: %3
		|%4';
		|vi = 'Node level: %1
		|Total time: %2
		|Number of filter nodes: %3
		|%4';
		|en = 'Node level: %1
		|Total time: %2
		|Number of filter nodes: %3
		|%4'; fa = 'Node level: %1
		|Total time: %2
		|Number of filter nodes: %3
		|%4';
		|it = 'Node level: %1
		|Total time: %2
		|Number of filter nodes: %3
		|%4';
		|pl = 'Node level: %1
		|Total time: %2
		|Number of filter nodes: %3
		|%4';
		|tr = 'Düğüm seviyesi:%1
		|Toplam süre:%2 
		|Seçim düğümü sayısı: %3
		|%4'");
	ProtocolText_ = ErrorsGroup1 + Chars.LF + StrTemplate(Template,
		TreeParameters.NodeLevel,
		CostCalculationProtocol.TimePresentation(Duration),
		TreeParameters.ReportParameters.NumberOfSelectionNodes,
		CalculationParameters.QueryExecutionResult);
	TreeParameters.Diagnostics.MeasurementsOfQueryExecutionByNodeLevels.Add(ProtocolText_);
	
	WriteLogEvent(TreeParameters.Diagnostics.LogEventGroup + ErrorsGroup1,
		EventLogLevel.Information,,,
		ProtocolText_);
	
	// 6. Check if there are rows in the TT table of node selections: True - There are rows, we continue to unify.
	//	
	//	False - there are no lines to untangle.
	Return CostCalculationAppliedAlgorithms.TemporaryTableSize(Query.TempTablesManager,
		"NodeSelectionTable") > 0;
	
EndFunction

Function QueryTextBatchEXPENSE()
	
	QueryTexts = New Array;
	
	#Region DisposalOfUnfinishedProductionByProduct
	QueryText = "
		|SELECT ALLOWED
		|	IssuedProducts.NodeID AS NodeID,
		|	IssuedProducts.IdOfFirstLevelNode AS IdOfFirstLevelNode,
		|	IssuedProducts.NodeOfFirstLevel_AnalyticsOfManufacturedProductAccounting AS NodeOfFirstLevel_AnalyticsOfManufacturedProductAccounting,
		|	IssuedProducts.NodeOfFirstLevel_LotReferenceOfManufacturedProducts AS NodeOfFirstLevel_LotReferenceOfManufacturedProducts,
		|	IssuedProducts.NodeOfFirstLevelIs_BatchAccountingAnalysisOfManufacturedProductsLotsVendorAttributes AS NodeOfFirstLevelIs_BatchAccountingAnalysisOfManufacturedProductsLotsVendorAttributes,
		|	MAX(IssuedProducts.OriginalBatchDate) AS OriginalBatchDate,
		|	MAX(IssuedProducts.SourceNodeNeedsToBeDisconnected) AS SourceNodeNeedsToBeDisconnected,
		|	IssuedProducts.ExpenseAccountingAnalytics AS ExpenseAccountingAnalytics,
		|
		|	MAX(IssuedProducts.DeployAdditionalCosts) AS DeployAdditionalCosts,
		|	BEGINOFPERIOD(InventoryCost.Period, MONTH) AS Period,
		|	IssuedProducts.Organization AS Organization,
		|	IssuedProducts.ProductsBatch AS ProductsBatch,
		|	IssuedProducts.ProductBatchAccountingDimension AS ProductBatchAccountingDimension,
		|	IssuedProducts.ProductsAccountingDimension AS ProductsAccountingDimension,
		|	MAX(IssuedProducts.Numerator) AS Numerator,
		|	MAX(IssuedProducts.Denominator) AS Denominator,
		|	InventoryCost.Lot AS Lot,
		|	InventoryCost.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	InventoryCost.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	SUM(InventoryCost.Count) AS Count,
		// The cost according to the parameter ""Data of the cost""
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.Cost
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.CostExcludingVAT
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.CostMan
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.LocalCost
		|		END)												AS Material_,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.LaborCosts
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.LaborCosts
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.LaborCostsMan
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.LaborCostsLocal
		|		END)												AS LaborCosts,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.ItemizedFixedCostsIncludingVAT
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.ItemizedFixedCostsExcludingVAT
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.ItemizedFixedCostsManag
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.ItemizedFixedCostsCompl
		|		END)												AS ItemizedFixed,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.ItemizedVariableCostsIncludingVAT
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.ItemizedVariableCostsExcludingVAT
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.ItemizedVariableCostsManag
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.ItemizedVariableCostsCompl
		|		END)												AS ItemizedVariable,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.AddExpensesForGoods
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.AdditionalExpensesExcludingVAT
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.AddExpensesMan
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.AddExpensesLocal
		|		END)												AS AddExpensesForGoods,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.OffBalanceCost
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.OffBalanceCost
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.OffBalanceCost
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.OffBalanceCostLocal
		|		END)												AS OffBalanceSheetCostAmount,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.Cost
		|				+ InventoryCost.LaborCosts
		|				+ InventoryCost.ItemizedFixedCostsIncludingVAT
		|				+ InventoryCost.ItemizedVariableCostsIncludingVAT
		|				+ InventoryCost.AddExpensesForGoods
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.CostExcludingVAT
		|				+ InventoryCost.LaborCosts
		|				+ InventoryCost.ItemizedFixedCostsExcludingVAT
		|				+ InventoryCost.ItemizedVariableCostsExcludingVAT
		|				+ InventoryCost.AdditionalExpensesExcludingVAT
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.CostMan
		|				+ InventoryCost.LaborCostsMan
		|				+ InventoryCost.ItemizedFixedCostsManag
		|				+ InventoryCost.ItemizedVariableCostsManag
		|				+ InventoryCost.AddExpensesMan
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.LocalCost
		|				+ InventoryCost.LaborCostsLocal
		|				+ InventoryCost.ItemizedFixedCostsCompl
		|				+ InventoryCost.ItemizedVariableCostsCompl
		|				+ InventoryCost.AddExpensesLocal
		|		END)												AS CostAmount,
		|	SUM(CASE
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.CostOfPersonalIncomeTax
		|			ELSE 0
		|		END)												AS AIT,
		|
		// Costs with VAT
		|	SUM(InventoryCost.Cost)					AS TangibleIncludingVAT,
		|	SUM(InventoryCost.LaborCosts)				AS LaborCostsIncludingVAT,
		|	SUM(InventoryCost.ItemizedFixedCostsIncludingVAT)	AS ItemizedFixedCostsIncludingVAT,
		|	SUM(InventoryCost.ItemizedVariableCostsIncludingVAT)	AS ItemizedVariableCostsIncludingVAT,
		|	SUM(InventoryCost.AddExpensesForGoods)					AS AdditionalExpensesIncludingVAT,
		|
		// Costs without VAT
		|	SUM(InventoryCost.CostExcludingVAT)				AS TangibleExcludingVAT,
		|	SUM(InventoryCost.ItemizedFixedCostsExcludingVAT)	AS ItemizedFixedCostsExcludingVAT,
		|	SUM(InventoryCost.ItemizedVariableCostsExcludingVAT)	AS ItemizedVariableCostsExcludingVAT,
		|	SUM(InventoryCost.AdditionalExpensesExcludingVAT)			AS AdditionalExpensesExcludingVAT,
		|
		// The Cost of Upr
		|	SUM(InventoryCost.CostMan)				AS MaterialMan,
		|	SUM(InventoryCost.LaborCostsMan)				AS LaborCostsMan,
		|	SUM(InventoryCost.ItemizedFixedCostsManag)	AS ItemizedFixedCostsManag,
		|	SUM(InventoryCost.ItemizedVariableCostsManag)	AS ItemizedVariableCostsManag,
		|	SUM(InventoryCost.AddExpensesMan)				AS AddExpensesMan,
		|	SUM(InventoryCost.OffBalanceCost)		AS CostOffBalanceSheetMan,
		|
		// Regl Costs
		|	SUM(InventoryCost.LocalCost)				AS TangibleCompl,
		|	SUM(InventoryCost.LaborCostsLocal)			AS LaborCostsLocal,
		|	SUM(InventoryCost.ItemizedFixedCostsCompl)	AS ItemizedFixedCostsCompl,
		|	SUM(InventoryCost.ItemizedVariableCostsCompl)	AS ItemizedVariableCostsCompl,
		|	SUM(InventoryCost.AddExpensesLocal)				AS AddExpensesLocal,
		|	SUM(InventoryCost.OffBalanceCostLocal)	AS OffBalanceCostLocal,
		|
		// Tax accounting
		|	SUM(InventoryCost.LocalCost
		|		+ InventoryCost.LaborCostsLocal
		|		+ InventoryCost.ItemizedFixedCostsCompl
		|		+ InventoryCost.ItemizedVariableCostsCompl
		|		+ InventoryCost.AddExpensesLocal
		|		- InventoryCost.PermanentDifference
		|		- InventoryCost.CostTD)			AS TaxAccounting,
		|	SUM(InventoryCost.PermanentDifference)			AS PermanentDifference,
		|	SUM(InventoryCost.CostTD)			AS CostTD
		|
		|INTO DisposalOfUnfinishedProductionByProduct
		|FROM
		|	IssuedProducts AS IssuedProducts
		|		INNER JOIN AccumulationRegister.InventoryCost AS InventoryCost
		|		ON InventoryCost.Organization = IssuedProducts.Organization
		|			AND IssuedProducts.ProductsBatch = InventoryCost.Recorder
		|			AND IssuedProducts.ProductsAccountingDimension = InventoryCost.CorItemsLocationAttributes
		|			AND IssuedProducts.ProductsBatch = InventoryCost.CorLot
		|			AND IssuedProducts.ProductBatchAccountingDimension = InventoryCost.LotVendorAttributesCorr
		|			AND (InventoryCost.Period <= &EndDate OR &EndDate = DATETIME(1,1,1))
		|WHERE
		|	InventoryCost.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND VALUETYPE(InventoryCost.Lot) = TYPE(Catalog.ProductionLots)
		|	AND NOT InventoryCost.Lot = VALUE(Catalog.ProductionLots.EmptyRef)
		|
		|GROUP BY
		|	BEGINOFPERIOD(InventoryCost.Period, MONTH),
		|	IssuedProducts.Organization,
		|	IssuedProducts.ProductsBatch,
		|	IssuedProducts.ProductBatchAccountingDimension,
		|	IssuedProducts.ProductsAccountingDimension,
		|	InventoryCost.Lot,
		|	InventoryCost.InventoryOwnerAttribute,
		|	InventoryCost.ItemsLocationAttributes,
		|
		|	IssuedProducts.NodeID,
		|	IssuedProducts.IdOfFirstLevelNode,
		|	IssuedProducts.ExpenseAccountingAnalytics,
		|	IssuedProducts.NodeOfFirstLevel_AnalyticsOfManufacturedProductAccounting,
		|	IssuedProducts.NodeOfFirstLevel_LotReferenceOfManufacturedProducts,
		|	IssuedProducts.NodeOfFirstLevelIs_BatchAccountingAnalysisOfManufacturedProductsLotsVendorAttributes
		|
		|INDEX BY
		|	NodeID,
		|	Lot,
		|	ItemsLocationAttributes,
		|	Period
		|";
		
		QueryTexts.Add(QueryText);
	#EndRegion

	#Region RetiredCostsAreSummarized
		QueryText = "
		|SELECT
		|	T.NodeID AS NodeID,
		|	T.Organization AS Organization,
		|	MAX(T.Period) AS Period,
		|	T.ItemsLocationAttributes,
		|	T.Lot AS Lot,
		|	T.ProductBatchAccountingDimension AS LotVendorAttributes
		|INTO RetiredCostsAreSummarized
		|FROM
		|	DisposalOfUnfinishedProductionByProduct AS T
		|WHERE
		|	T.Count <> 0
		|
		|GROUP BY
		|	T.NodeID,
		|	T.Organization,
		|	T.ItemsLocationAttributes,
		|	T.Lot,
		|	T.ProductBatchAccountingDimension
		|
		|INDEX BY
		|	Lot,
		|	ItemsLocationAttributes,
		|	LotVendorAttributes,
		|	Organization,
		|	NodeID
		|";
		QueryTexts.Add(QueryText);
	#EndRegion
		
	#Region ProductionLots
		QueryText = "
		|SELECT DISTINCT
		|	T.NodeID AS NodeID,
		|	T.Lot AS Lot
		|INTO ProductionLots
		|FROM
		|	RetiredCostsAreSummarized AS T
		|INDEX BY
		|	Lot,
		|	NodeID
		|";
		QueryTexts.Add(QueryText);
	#EndRegion
		
	#Region DisposalFromUnfinishedProduction
	QueryText = "
		|SELECT ALLOWED
		|	Disposal.NodeID AS NodeID,
		|	T.Organization AS Organization,
		|	BEGINOFPERIOD(T.Period, MONTH) AS Period,
		|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	T.Lot AS Lot,
		|	SUM(T.CountExpense) AS Count
		|INTO DisposalFromUnfinishedProduction
		|FROM
		|	AccumulationRegister.InventoryCost.Turnovers(,, Month,
		|		Lot IN (
		|			SELECT
		|				T.Lot
		|			FROM
		|				ProductionLots AS T)
		|		AND (ItemsLocationAttributes, Organization) IN (
		|			SELECT
		|				Disposal.ItemsLocationAttributes,
		|				Disposal.Organization AS Organization
		|			FROM
		|				RetiredCostsAreSummarized AS Disposal)
		|	) AS T
		|
		|	INNER JOIN RetiredCostsAreSummarized AS Disposal
		|	ON T.ItemsLocationAttributes = Disposal.ItemsLocationAttributes
		|		AND T.Lot = Disposal.Lot
		|		AND T.Organization = Disposal.Organization
		|
		|WHERE
		|	T.Period <= ENDOFPERIOD(Disposal.Period, MONTH)
		|
		|GROUP BY
		|	Disposal.NodeID,
		|	T.Organization,
		|	BEGINOFPERIOD(T.Period, MONTH),
		|	T.ItemsLocationAttributes,
		|	T.Lot
		|
		|INDEX BY
		|	NodeID,
		|	Lot
		|";
	QueryTexts.Add(QueryText);
	#EndRegion
	
	#Region RetirementFromUnfinishedProductionForBalance
		QueryText = "SELECT ALLOWED
		|	Disposal.NodeID AS NodeID,
		|	T.Organization AS Organization,
		|	BEGINOFPERIOD(T.Period, MONTH) AS Period,
		|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	T.Lot AS Lot,
		|	SUM(T.CountExpense) AS Count
		|INTO RetirementFromUnfinishedProductionForBalance
		|FROM
		|	AccumulationRegister.InventoryCost.Turnovers(,, Month,
		|		Lot IN (
		|			SELECT
		|				T.Lot
		|			FROM
		|				ProductionLots AS T)
		|		AND (ItemsLocationAttributes, Organization) IN (
		|			SELECT
		|				Disposal.ItemsLocationAttributes,
		|				Disposal.Organization AS Organization
		|			FROM
		|				RetiredCostsAreSummarized AS Disposal)
		|	) AS T
		|
		|	INNER JOIN RetiredCostsAreSummarized AS Disposal
		|	ON T.ItemsLocationAttributes = Disposal.ItemsLocationAttributes
		|		AND T.Lot = Disposal.Lot
		|		AND T.Organization = Disposal.Organization
		|
		|WHERE
		|	T.Period <= ENDOFPERIOD(Disposal.Period, MONTH)
		|
		|GROUP BY
		|	Disposal.NodeID,
		|	T.Organization,
		|	BEGINOFPERIOD(T.Period, MONTH),
		|	T.ItemsLocationAttributes,
		|	T.Lot
		|
		|INDEX BY
		|	NodeID,
		|	Lot
		|";
		QueryTexts.Add(QueryText);
	#EndRegion
		
	#Region PrimaryGNZPParties
		QueryText = "
		|SELECT ALLOWED
		|	PP.NodeID AS NodeID,
		|	BEGINOFPERIOD(InventoryCost.Period, MONTH) AS Period,
		|	InventoryCost.Organization					AS Organization,
		|	InventoryCost.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
		// Primary party analytics.
		|	InventoryCost.ItemsLocationAttributes 	AS ItemsLocationAttributes,
		|	InventoryCost.LotVendorAttributes 			AS LotVendorAttributes,
		|	InventoryCost.Lot 						AS Lot,
		// Analytics in the WIP.
		|	InventoryCost.CorItemsLocationAttributes 	AS CorItemsLocationAttributes,
		|	InventoryCost.CorLot						AS CorLot,
		|
		|	MAX(CASE
		|		WHEN InventoryCost.VATActivityType IN (&TypesOfTaxationVATIsNotIncludedInCost)
		|		 AND InventoryCost.CorVATActivityTypes IN (&TypesOfTaxationVATIsIncludedInCost)
		|			THEN TRUE
		|		ELSE FALSE END) AS IncludePersonalIncomeTaxCost,
		|	MAX(CASE
		|		WHEN InventoryCost.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
		|		 AND InventoryCost.CorVATActivityTypes IN (&TypesOfTaxationVATIsNotIncludedInCost)
		|			THEN TRUE
		|		ELSE FALSE END) AS ExcludeVATFromCost,
		
		|	SUM(InventoryCost.Count) 				AS Count,
		// The cost according to the parameter ""Data of the cost""
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.Cost
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.CostExcludingVAT
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.CostMan
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.LocalCost
		|		END)												AS Material_,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.LaborCosts
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.LaborCosts
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.LaborCostsMan
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.LaborCostsLocal
		|		END)												AS LaborCosts,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.ItemizedFixedCostsIncludingVAT
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.ItemizedFixedCostsExcludingVAT
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.ItemizedFixedCostsManag
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.ItemizedFixedCostsCompl
		|		END)												AS ItemizedFixed,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.ItemizedVariableCostsIncludingVAT
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.ItemizedVariableCostsExcludingVAT
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.ItemizedVariableCostsManag
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.ItemizedVariableCostsCompl
		|		END)												AS ItemizedVariable,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.AddExpensesForGoods
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.AdditionalExpensesExcludingVAT
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.AddExpensesMan
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.AddExpensesLocal
		|		END)												AS AddExpensesForGoods,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.OffBalanceCost
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.OffBalanceCost
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.OffBalanceCost
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.OffBalanceCostLocal
		|		END)												AS OffBalanceSheetCostAmount,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.Cost
		|				+ InventoryCost.LaborCosts
		|				+ InventoryCost.ItemizedFixedCostsIncludingVAT
		|				+ InventoryCost.ItemizedVariableCostsIncludingVAT
		|				+ InventoryCost.AddExpensesForGoods
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.CostExcludingVAT
		|				+ InventoryCost.LaborCosts
		|				+ InventoryCost.ItemizedFixedCostsExcludingVAT
		|				+ InventoryCost.ItemizedVariableCostsExcludingVAT
		|				+ InventoryCost.AdditionalExpensesExcludingVAT
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.CostMan
		|				+ InventoryCost.LaborCostsMan
		|				+ InventoryCost.ItemizedFixedCostsManag
		|				+ InventoryCost.ItemizedVariableCostsManag
		|				+ InventoryCost.AddExpensesMan
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.LocalCost
		|				+ InventoryCost.LaborCostsLocal
		|				+ InventoryCost.ItemizedFixedCostsCompl
		|				+ InventoryCost.ItemizedVariableCostsCompl
		|				+ InventoryCost.AddExpensesLocal
		|		END)												AS CostAmount,
		|	SUM(CASE
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.CostOfPersonalIncomeTax
		|			ELSE 0
		|		END)												AS AIT,
		|
		// Costs with VAT
		|	SUM(InventoryCost.Cost)					AS TangibleIncludingVAT,
		|	SUM(InventoryCost.LaborCosts)				AS LaborCostsIncludingVAT,
		|	SUM(InventoryCost.ItemizedFixedCostsIncludingVAT)	AS ItemizedFixedCostsIncludingVAT,
		|	SUM(InventoryCost.ItemizedVariableCostsIncludingVAT)	AS ItemizedVariableCostsIncludingVAT,
		|	SUM(InventoryCost.AddExpensesForGoods)					AS AdditionalExpensesIncludingVAT,
		|
		// Costs without VAT
		|	SUM(InventoryCost.CostExcludingVAT)				AS TangibleExcludingVAT,
		|	SUM(InventoryCost.ItemizedFixedCostsExcludingVAT)	AS ItemizedFixedCostsExcludingVAT,
		|	SUM(InventoryCost.ItemizedVariableCostsExcludingVAT)	AS ItemizedVariableCostsExcludingVAT,
		|	SUM(InventoryCost.AdditionalExpensesExcludingVAT)			AS AdditionalExpensesExcludingVAT,
		|
		// The Cost of Upr
		|	SUM(InventoryCost.CostMan)				AS MaterialMan,
		|	SUM(InventoryCost.LaborCostsMan)				AS LaborCostsMan,
		|	SUM(InventoryCost.ItemizedFixedCostsManag)	AS ItemizedFixedCostsManag,
		|	SUM(InventoryCost.ItemizedVariableCostsManag)	AS ItemizedVariableCostsManag,
		|	SUM(InventoryCost.AddExpensesMan)				AS AddExpensesMan,
		|	SUM(InventoryCost.OffBalanceCost)		AS CostOffBalanceSheetMan,
		|
		// Regl Costs
		|	SUM(InventoryCost.LocalCost)				AS TangibleCompl,
		|	SUM(InventoryCost.LaborCostsLocal)			AS LaborCostsLocal,
		|	SUM(InventoryCost.ItemizedFixedCostsCompl)	AS ItemizedFixedCostsCompl,
		|	SUM(InventoryCost.ItemizedVariableCostsCompl)	AS ItemizedVariableCostsCompl,
		|	SUM(InventoryCost.AddExpensesLocal)				AS AddExpensesLocal,
		|	SUM(InventoryCost.OffBalanceCostLocal)	AS OffBalanceCostLocal,
		|
		// Tax accounting
		|	SUM(InventoryCost.LocalCost
		|		+ InventoryCost.LaborCostsLocal
		|		+ InventoryCost.ItemizedFixedCostsCompl
		|		+ InventoryCost.ItemizedVariableCostsCompl
		|		+ InventoryCost.AddExpensesLocal
		|		- InventoryCost.PermanentDifference
		|		- InventoryCost.CostTD)			AS TaxAccounting,
		|	SUM(InventoryCost.PermanentDifference)			AS PermanentDifference,
		|	SUM(InventoryCost.CostTD)			AS CostTD
		|
		|INTO PrimaryGNZPParties
		|FROM
		|	AccumulationRegister.InventoryCost AS InventoryCost
		|		INNER JOIN ProductionLots AS PP
		|		ON InventoryCost.CorLot = PP.Lot
		|		INNER JOIN RetiredCostsAreSummarized AS Disposal
		|		ON InventoryCost.CorItemsLocationAttributes = Disposal.ItemsLocationAttributes
		|			AND InventoryCost.CorLot = Disposal.Lot
		|			AND InventoryCost.Period <= ENDOFPERIOD(Disposal.Period, MONTH)
		|			AND InventoryCost.Organization = Disposal.Organization
		|			AND PP.NodeID = Disposal.NodeID
		|WHERE
		|	InventoryCost.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND (InventoryCost.Period <= &EndDate OR &EndDate = DATETIME(1,1,1))
		|
		|GROUP BY
		|	PP.NodeID,
		|	BEGINOFPERIOD(InventoryCost.Period, MONTH),
		|	InventoryCost.Organization,
		|	InventoryCost.InventoryOwnerAttribute,
		|	InventoryCost.ItemsLocationAttributes,
		|	InventoryCost.LotVendorAttributes,
		|	InventoryCost.Lot,
		|	InventoryCost.CorItemsLocationAttributes,
		|	InventoryCost.CorLot
		|
		|HAVING SUM(InventoryCost.Count) > 0
		|
		|UNION ALL
		|
		// Fix. cost
		|SELECT
		|	PP.NodeID AS NodeID,
		|	BEGINOFPERIOD(InventoryCost.Period, MONTH)	AS Period,
		|	InventoryCost.Organization					AS Organization,
		|	InventoryCost.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
		|	InventoryCost.ItemsLocationAttributes 	AS ItemsLocationAttributes,
		|	InventoryCost.LotVendorAttributes 			AS LotVendorAttributes,
		|	InventoryCost.Recorder					AS Lot,
		
		|	InventoryCost.ItemsLocationAttributes		AS CorItemsLocationAttributes,
		|	InventoryCost.Lot							AS CorLot,
		|	FALSE												AS IncludePersonalIncomeTaxCost,
		|	FALSE												AS ExcludeVATFromCost,
		
		|	SUM(InventoryCost.Count),
		// The cost according to the parameter ""Data of the cost""
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.Cost
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.CostExcludingVAT
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.CostMan
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.LocalCost
		|		END)												AS Material_,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.LaborCosts
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.LaborCosts
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.LaborCostsMan
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.LaborCostsLocal
		|		END)												AS LaborCosts,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.ItemizedFixedCostsIncludingVAT
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.ItemizedFixedCostsExcludingVAT
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.ItemizedFixedCostsManag
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.ItemizedFixedCostsCompl
		|		END)												AS ItemizedFixed,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.ItemizedVariableCostsIncludingVAT
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.ItemizedVariableCostsExcludingVAT
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.ItemizedVariableCostsManag
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.ItemizedVariableCostsCompl
		|		END)												AS ItemizedVariable,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.AddExpensesForGoods
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.AdditionalExpensesExcludingVAT
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.AddExpensesMan
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.AddExpensesLocal
		|		END)												AS AddExpensesForGoods,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.OffBalanceCost
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.OffBalanceCost
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.OffBalanceCost
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.OffBalanceCostLocal
		|		END)												AS OffBalanceSheetCostAmount,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.Cost
		|				+ InventoryCost.LaborCosts
		|				+ InventoryCost.ItemizedFixedCostsIncludingVAT
		|				+ InventoryCost.ItemizedVariableCostsIncludingVAT
		|				+ InventoryCost.AddExpensesForGoods
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.CostExcludingVAT
		|				+ InventoryCost.LaborCosts
		|				+ InventoryCost.ItemizedFixedCostsExcludingVAT
		|				+ InventoryCost.ItemizedVariableCostsExcludingVAT
		|				+ InventoryCost.AdditionalExpensesExcludingVAT
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.CostMan
		|				+ InventoryCost.LaborCostsMan
		|				+ InventoryCost.ItemizedFixedCostsManag
		|				+ InventoryCost.ItemizedVariableCostsManag
		|				+ InventoryCost.AddExpensesMan
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.LocalCost
		|				+ InventoryCost.LaborCostsLocal
		|				+ InventoryCost.ItemizedFixedCostsCompl
		|				+ InventoryCost.ItemizedVariableCostsCompl
		|				+ InventoryCost.AddExpensesLocal
		|		END)												AS CostAmount,
		|	SUM(CASE
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.CostOfPersonalIncomeTax
		|			ELSE 0
		|		END)												AS AIT,
		|
		// Costs with VAT
		|	SUM(InventoryCost.Cost)					AS TangibleIncludingVAT,
		|	SUM(InventoryCost.LaborCosts)				AS LaborCostsIncludingVAT,
		|	SUM(InventoryCost.ItemizedFixedCostsIncludingVAT)	AS ItemizedFixedCostsIncludingVAT,
		|	SUM(InventoryCost.ItemizedVariableCostsIncludingVAT)	AS ItemizedVariableCostsIncludingVAT,
		|	SUM(InventoryCost.AddExpensesForGoods)					AS AdditionalExpensesIncludingVAT,
		|
		// Costs without VAT
		|	SUM(InventoryCost.CostExcludingVAT)				AS TangibleExcludingVAT,
		|	SUM(InventoryCost.ItemizedFixedCostsExcludingVAT)	AS ItemizedFixedCostsExcludingVAT,
		|	SUM(InventoryCost.ItemizedVariableCostsExcludingVAT)	AS ItemizedVariableCostsExcludingVAT,
		|	SUM(InventoryCost.AdditionalExpensesExcludingVAT)			AS AdditionalExpensesExcludingVAT,
		|
		// The Cost of Upr
		|	SUM(InventoryCost.CostMan)				AS MaterialMan,
		|	SUM(InventoryCost.LaborCostsMan)				AS LaborCostsMan,
		|	SUM(InventoryCost.ItemizedFixedCostsManag)	AS ItemizedFixedCostsManag,
		|	SUM(InventoryCost.ItemizedVariableCostsManag)	AS ItemizedVariableCostsManag,
		|	SUM(InventoryCost.AddExpensesMan)				AS AddExpensesMan,
		|	SUM(InventoryCost.OffBalanceCost)		AS CostOffBalanceSheetMan,
		|
		// Regl Costs
		|	SUM(InventoryCost.LocalCost)				AS TangibleCompl,
		|	SUM(InventoryCost.LaborCostsLocal)			AS LaborCostsLocal,
		|	SUM(InventoryCost.ItemizedFixedCostsCompl)	AS ItemizedFixedCostsCompl,
		|	SUM(InventoryCost.ItemizedVariableCostsCompl)	AS ItemizedVariableCostsCompl,
		|	SUM(InventoryCost.AddExpensesLocal)				AS AddExpensesLocal,
		|	SUM(InventoryCost.OffBalanceCostLocal)	AS OffBalanceCostLocal,
		|
		// Tax accounting
		|	SUM(InventoryCost.LocalCost
		|		+ InventoryCost.LaborCostsLocal
		|		+ InventoryCost.ItemizedFixedCostsCompl
		|		+ InventoryCost.ItemizedVariableCostsCompl
		|		+ InventoryCost.AddExpensesLocal
		|		- InventoryCost.PermanentDifference
		|		- InventoryCost.CostTD)			AS TaxAccounting,
		|	SUM(InventoryCost.PermanentDifference)			AS PermanentDifference,
		|	SUM(InventoryCost.CostTD)			AS CostTD
		|
		|FROM
		|	AccumulationRegister.InventoryCost AS InventoryCost
		|		INNER JOIN ProductionLots AS PP
		|		ON InventoryCost.Lot = PP.Lot
		|		INNER JOIN RetiredCostsAreSummarized AS Disposal
		|		ON InventoryCost.ItemsLocationAttributes = Disposal.ItemsLocationAttributes
		|			AND InventoryCost.Lot = Disposal.Lot
		|			AND InventoryCost.Period <= ENDOFPERIOD(Disposal.Period, MONTH)
		|			AND InventoryCost.Organization = Disposal.Organization
		|			AND PP.NodeID = Disposal.NodeID
		|WHERE
		|	InventoryCost.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)
		|	AND InventoryCost.Count < 0
		|	AND (InventoryCost.Period <= &EndDate OR &EndDate = DATETIME(1,1,1))
		|
		|GROUP BY
		|	PP.NodeID,
		|	BEGINOFPERIOD(InventoryCost.Period, MONTH),
		|	InventoryCost.Organization,
		|	InventoryCost.InventoryOwnerAttribute,
		|	InventoryCost.ItemsLocationAttributes,
		|	InventoryCost.LotVendorAttributes,
		|	InventoryCost.Recorder,
		|	InventoryCost.Lot
		|
		|UNION ALL
		|
		// Processor services
		|SELECT
		|	PP.NodeID AS NodeID,
		|	BEGINOFPERIOD(InventoryCost.Period, MONTH)	AS Period,
		|	InventoryCost.Organization					AS Organization,
		|	InventoryCost.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
		|	InventoryCost.ItemsLocationAttributes		AS ItemsLocationAttributes,
		|	InventoryCost.LotVendorAttributes			AS LotVendorAttributes,
		|	ISNULL(Adjusting.DocumentBasis,
		|		InventoryCost.Recorder)				AS Lot,
		
		|	InventoryCost.ItemsLocationAttributes		AS CorItemsLocationAttributes,
		|	InventoryCost.Lot							AS CorLot,
		|	FALSE												AS IncludePersonalIncomeTaxCost,
		|	FALSE												AS ExcludeVATFromCost,
		
		|	SUM(InventoryCost.Count),
		// The cost according to the parameter ""Data of the cost""
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.Cost
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.CostExcludingVAT
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.CostMan
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.LocalCost
		|		END)												AS Material_,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.LaborCosts
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.LaborCosts
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.LaborCostsMan
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.LaborCostsLocal
		|		END)												AS LaborCosts,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.ItemizedFixedCostsIncludingVAT
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.ItemizedFixedCostsExcludingVAT
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.ItemizedFixedCostsManag
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.ItemizedFixedCostsCompl
		|		END)												AS ItemizedFixed,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.ItemizedVariableCostsIncludingVAT
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.ItemizedVariableCostsExcludingVAT
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.ItemizedVariableCostsManag
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.ItemizedVariableCostsCompl
		|		END)												AS ItemizedVariable,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.AddExpensesForGoods
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.AdditionalExpensesExcludingVAT
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.AddExpensesMan
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.AddExpensesLocal
		|		END)												AS AddExpensesForGoods,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.OffBalanceCost
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.OffBalanceCost
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.OffBalanceCost
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.OffBalanceCostLocal
		|		END)												AS OffBalanceSheetCostAmount,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.Cost
		|				+ InventoryCost.LaborCosts
		|				+ InventoryCost.ItemizedFixedCostsIncludingVAT
		|				+ InventoryCost.ItemizedVariableCostsIncludingVAT
		|				+ InventoryCost.AddExpensesForGoods
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.CostExcludingVAT
		|				+ InventoryCost.LaborCosts
		|				+ InventoryCost.ItemizedFixedCostsExcludingVAT
		|				+ InventoryCost.ItemizedVariableCostsExcludingVAT
		|				+ InventoryCost.AdditionalExpensesExcludingVAT
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.CostMan
		|				+ InventoryCost.LaborCostsMan
		|				+ InventoryCost.ItemizedFixedCostsManag
		|				+ InventoryCost.ItemizedVariableCostsManag
		|				+ InventoryCost.AddExpensesMan
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.LocalCost
		|				+ InventoryCost.LaborCostsLocal
		|				+ InventoryCost.ItemizedFixedCostsCompl
		|				+ InventoryCost.ItemizedVariableCostsCompl
		|				+ InventoryCost.AddExpensesLocal
		|		END)												AS CostAmount,
		|	SUM(CASE
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.CostOfPersonalIncomeTax
		|			ELSE 0
		|		END)												AS AIT,
		|
		// Costs with VAT
		|	SUM(InventoryCost.Cost)					AS TangibleIncludingVAT,
		|	SUM(InventoryCost.LaborCosts)				AS LaborCostsIncludingVAT,
		|	SUM(InventoryCost.ItemizedFixedCostsIncludingVAT)	AS ItemizedFixedCostsIncludingVAT,
		|	SUM(InventoryCost.ItemizedVariableCostsIncludingVAT)	AS ItemizedVariableCostsIncludingVAT,
		|	SUM(InventoryCost.AddExpensesForGoods)					AS AdditionalExpensesIncludingVAT,
		|
		// Costs without VAT
		|	SUM(InventoryCost.CostExcludingVAT)				AS TangibleExcludingVAT,
		|	SUM(InventoryCost.ItemizedFixedCostsExcludingVAT)	AS ItemizedFixedCostsExcludingVAT,
		|	SUM(InventoryCost.ItemizedVariableCostsExcludingVAT)	AS ItemizedVariableCostsExcludingVAT,
		|	SUM(InventoryCost.AdditionalExpensesExcludingVAT)			AS AdditionalExpensesExcludingVAT,
		|
		// The Cost of Upr
		|	SUM(InventoryCost.CostMan)				AS MaterialMan,
		|	SUM(InventoryCost.LaborCostsMan)				AS LaborCostsMan,
		|	SUM(InventoryCost.ItemizedFixedCostsManag)	AS ItemizedFixedCostsManag,
		|	SUM(InventoryCost.ItemizedVariableCostsManag)	AS ItemizedVariableCostsManag,
		|	SUM(InventoryCost.AddExpensesMan)				AS AddExpensesMan,
		|	SUM(InventoryCost.OffBalanceCost)		AS CostOffBalanceSheetMan,
		|
		// Regl Costs
		|	SUM(InventoryCost.LocalCost)				AS TangibleCompl,
		|	SUM(InventoryCost.LaborCostsLocal)			AS LaborCostsLocal,
		|	SUM(InventoryCost.ItemizedFixedCostsCompl)	AS ItemizedFixedCostsCompl,
		|	SUM(InventoryCost.ItemizedVariableCostsCompl)	AS ItemizedVariableCostsCompl,
		|	SUM(InventoryCost.AddExpensesLocal)				AS AddExpensesLocal,
		|	SUM(InventoryCost.OffBalanceCostLocal)	AS OffBalanceCostLocal,
		|
		// Tax accounting
		|	SUM(InventoryCost.LocalCost
		|		+ InventoryCost.LaborCostsLocal
		|		+ InventoryCost.ItemizedFixedCostsCompl
		|		+ InventoryCost.ItemizedVariableCostsCompl
		|		+ InventoryCost.AddExpensesLocal
		|		- InventoryCost.PermanentDifference
		|		- InventoryCost.CostTD)			AS TaxAccounting,
		|	SUM(InventoryCost.PermanentDifference)			AS PermanentDifference,
		|	SUM(InventoryCost.CostTD)			AS CostTD
		|
		|FROM
		|	AccumulationRegister.InventoryCost AS InventoryCost
		|
		|	INNER JOIN ProductionLots AS PP
		|		ON InventoryCost.Lot = PP.Lot
		|
		|	LEFT JOIN Document.PurchaseAdjustment AS Adjusting
		|		ON Adjusting.Ref = InventoryCost.Recorder
		|	
		|WHERE
		|	VALUETYPE(InventoryCost.Recorder) IN (
		|		TYPE(Document.PurchaseAdjustment),
		|		TYPE(Document.SubcontractorReport2_5))
		|	AND InventoryCost.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
		|	AND InventoryCost.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
		|	AND (InventoryCost.Period <= &EndDate OR &EndDate = DATETIME(1,1,1))
		|
		|GROUP BY
		|	PP.NodeID,
		|	BEGINOFPERIOD(InventoryCost.Period, MONTH),
		|	InventoryCost.Organization,
		|	InventoryCost.InventoryOwnerAttribute,
		|	InventoryCost.ItemsLocationAttributes,
		|	InventoryCost.LotVendorAttributes,
		|	ISNULL(Adjusting.DocumentBasis,
		|		InventoryCost.Recorder), // Lot
		|	InventoryCost.Lot
		|
		|UNION ALL
		|
		// Initial balances
		|SELECT
		|	PP.NodeID AS NodeID,
		|	BEGINOFPERIOD(InventoryCost.Period, MONTH)	AS Period,
		|	InventoryCost.Organization					AS Organization,
		|	InventoryCost.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
		|	InventoryCost.ItemsLocationAttributes		AS ItemsLocationAttributes,
		|	InventoryCost.LotVendorAttributes			AS LotVendorAttributes,
		|	InventoryCost.Recorder					AS Lot,
		
		|	InventoryCost.ItemsLocationAttributes		AS CorItemsLocationAttributes,
		|	InventoryCost.Lot							AS CorLot,
		|	FALSE												AS IncludePersonalIncomeTaxCost,
		|	FALSE												AS ExcludeVATFromCost,
		
		|	SUM(InventoryCost.Count),
		// The cost according to the parameter ""Data of the cost""
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.Cost
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.CostExcludingVAT
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.CostMan
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.LocalCost
		|		END)												AS Material_,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.LaborCosts
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.LaborCosts
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.LaborCostsMan
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.LaborCostsLocal
		|		END)												AS LaborCosts,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.ItemizedFixedCostsIncludingVAT
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.ItemizedFixedCostsExcludingVAT
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.ItemizedFixedCostsManag
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.ItemizedFixedCostsCompl
		|		END)												AS ItemizedFixed,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.ItemizedVariableCostsIncludingVAT
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.ItemizedVariableCostsExcludingVAT
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.ItemizedVariableCostsManag
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.ItemizedVariableCostsCompl
		|		END)												AS ItemizedVariable,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.AddExpensesForGoods
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.AdditionalExpensesExcludingVAT
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.AddExpensesMan
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.AddExpensesLocal
		|		END)												AS AddExpensesForGoods,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.OffBalanceCost
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.OffBalanceCost
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.OffBalanceCost
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.OffBalanceCostLocal
		|		END)												AS OffBalanceSheetCostAmount,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.Cost
		|				+ InventoryCost.LaborCosts
		|				+ InventoryCost.ItemizedFixedCostsIncludingVAT
		|				+ InventoryCost.ItemizedVariableCostsIncludingVAT
		|				+ InventoryCost.AddExpensesForGoods
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.CostExcludingVAT
		|				+ InventoryCost.LaborCosts
		|				+ InventoryCost.ItemizedFixedCostsExcludingVAT
		|				+ InventoryCost.ItemizedVariableCostsExcludingVAT
		|				+ InventoryCost.AdditionalExpensesExcludingVAT
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.CostMan
		|				+ InventoryCost.LaborCostsMan
		|				+ InventoryCost.ItemizedFixedCostsManag
		|				+ InventoryCost.ItemizedVariableCostsManag
		|				+ InventoryCost.AddExpensesMan
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.LocalCost
		|				+ InventoryCost.LaborCostsLocal
		|				+ InventoryCost.ItemizedFixedCostsCompl
		|				+ InventoryCost.ItemizedVariableCostsCompl
		|				+ InventoryCost.AddExpensesLocal
		|		END)												AS CostAmount,
		|	SUM(CASE
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.CostOfPersonalIncomeTax
		|			ELSE 0
		|		END)												AS AIT,
		|
		// Costs with VAT
		|	SUM(InventoryCost.Cost)					AS TangibleIncludingVAT,
		|	SUM(InventoryCost.LaborCosts)				AS LaborCostsIncludingVAT,
		|	SUM(InventoryCost.ItemizedFixedCostsIncludingVAT)	AS ItemizedFixedCostsIncludingVAT,
		|	SUM(InventoryCost.ItemizedVariableCostsIncludingVAT)	AS ItemizedVariableCostsIncludingVAT,
		|	SUM(InventoryCost.AddExpensesForGoods)					AS AdditionalExpensesIncludingVAT,
		|
		// Costs without VAT
		|	SUM(InventoryCost.CostExcludingVAT)				AS TangibleExcludingVAT,
		|	SUM(InventoryCost.ItemizedFixedCostsExcludingVAT)	AS ItemizedFixedCostsExcludingVAT,
		|	SUM(InventoryCost.ItemizedVariableCostsExcludingVAT)	AS ItemizedVariableCostsExcludingVAT,
		|	SUM(InventoryCost.AdditionalExpensesExcludingVAT)			AS AdditionalExpensesExcludingVAT,
		|
		// The Cost of Upr
		|	SUM(InventoryCost.CostMan)				AS MaterialMan,
		|	SUM(InventoryCost.LaborCostsMan)				AS LaborCostsMan,
		|	SUM(InventoryCost.ItemizedFixedCostsManag)	AS ItemizedFixedCostsManag,
		|	SUM(InventoryCost.ItemizedVariableCostsManag)	AS ItemizedVariableCostsManag,
		|	SUM(InventoryCost.AddExpensesMan)				AS AddExpensesMan,
		|	SUM(InventoryCost.OffBalanceCost)		AS CostOffBalanceSheetMan,
		|
		// Regl Costs
		|	SUM(InventoryCost.LocalCost)				AS TangibleCompl,
		|	SUM(InventoryCost.LaborCostsLocal)			AS LaborCostsLocal,
		|	SUM(InventoryCost.ItemizedFixedCostsCompl)	AS ItemizedFixedCostsCompl,
		|	SUM(InventoryCost.ItemizedVariableCostsCompl)	AS ItemizedVariableCostsCompl,
		|	SUM(InventoryCost.AddExpensesLocal)				AS AddExpensesLocal,
		|	SUM(InventoryCost.OffBalanceCostLocal)	AS OffBalanceCostLocal,
		|
		// Tax accounting
		|	SUM(InventoryCost.LocalCost
		|		+ InventoryCost.LaborCostsLocal
		|		+ InventoryCost.ItemizedFixedCostsCompl
		|		+ InventoryCost.ItemizedVariableCostsCompl
		|		+ InventoryCost.AddExpensesLocal
		|		- InventoryCost.PermanentDifference
		|		- InventoryCost.CostTD)			AS TaxAccounting,
		|	SUM(InventoryCost.PermanentDifference)			AS PermanentDifference,
		|	SUM(InventoryCost.CostTD)			AS CostTD
		|
		|FROM
		|	AccumulationRegister.InventoryCost AS InventoryCost
		|		INNER JOIN ProductionLots AS PP
		|		ON InventoryCost.Lot = PP.Lot
		|		INNER JOIN RetiredCostsAreSummarized AS Disposal
		|		ON InventoryCost.ItemsLocationAttributes = Disposal.ItemsLocationAttributes
		|			AND InventoryCost.Lot = Disposal.Lot
		|			AND InventoryCost.Period <= ENDOFPERIOD(Disposal.Period, MONTH)
		|			AND InventoryCost.Organization = Disposal.Organization
		|			AND PP.NodeID = Disposal.NodeID
		|WHERE
		|	InventoryCost.BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryProductionLotCosts)
		|	AND (InventoryCost.Period <= &EndDate OR &EndDate = DATETIME(1,1,1))
		|
		|GROUP BY
		|	PP.NodeID,
		|	BEGINOFPERIOD(InventoryCost.Period, MONTH),
		|	InventoryCost.Organization,
		|	InventoryCost.InventoryOwnerAttribute,
		|	InventoryCost.ItemsLocationAttributes,
		|	InventoryCost.LotVendorAttributes,
		|	InventoryCost.Recorder,
		|	InventoryCost.Lot
		|
		|INDEX BY
		|	NodeID,
		|	Lot
		|";
		QueryTexts.Add(QueryText);
	#EndRegion

	#Region ResultsOfPartiesVNZP
	QueryText = "
		|SELECT
		|	MAX(PP.Period) AS MonthOfPrimaryLotReferenceVNZP,
		|	PP.NodeID AS NodeID,
		|	PP.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	PP.Lot AS Lot,
		|	PP.LotVendorAttributes AS LotVendorAttributes,
		|	PP.CorItemsLocationAttributes AS CorItemsLocationAttributes,
		|	PP.CorLot AS CorLot,
		|	PP.Organization AS Organization,
		|	MAX(PP.IncludePersonalIncomeTaxCost) AS IncludePersonalIncomeTaxCost,
		|	MAX(PP.ExcludeVATFromCost) AS ExcludeVATFromCost,
		|
		|	SUM(PP.Count) AS Count,
		|	SUM(PP.Material_) AS Material_,
		|	SUM(PP.LaborCosts) AS LaborCosts,
		|	SUM(PP.ItemizedFixed) AS ItemizedFixed,
		|	SUM(PP.ItemizedVariable) AS ItemizedVariable,
		|	SUM(PP.AddExpensesForGoods) AS AddExpensesForGoods,
		|	SUM(PP.OffBalanceSheetCostAmount) AS OffBalanceSheetCostAmount,
		|	SUM(PP.CostAmount) AS CostAmount,
		|	SUM(PP.AIT) AS AIT,
		|
		// Costs with VAT
		|	SUM(PP.TangibleIncludingVAT) AS TangibleIncludingVAT,
		|	SUM(PP.LaborCostsIncludingVAT) AS LaborCostsIncludingVAT,
		|	SUM(PP.ItemizedFixedCostsIncludingVAT) AS ItemizedFixedCostsIncludingVAT,
		|	SUM(PP.ItemizedVariableCostsIncludingVAT) AS ItemizedVariableCostsIncludingVAT,
		|	SUM(PP.AdditionalExpensesIncludingVAT) AS AdditionalExpensesIncludingVAT,
		|
		// Costs without VAT
		|	SUM(PP.TangibleExcludingVAT) AS TangibleExcludingVAT,
		|	SUM(PP.ItemizedFixedCostsExcludingVAT) AS ItemizedFixedCostsExcludingVAT,
		|	SUM(PP.ItemizedVariableCostsExcludingVAT) AS ItemizedVariableCostsExcludingVAT,
		|	SUM(PP.AdditionalExpensesExcludingVAT) AS AdditionalExpensesExcludingVAT,
		|
		// The Cost of Upr
		|	SUM(PP.MaterialMan) AS MaterialMan,
		|	SUM(PP.LaborCostsMan) AS LaborCostsMan,
		|	SUM(PP.ItemizedFixedCostsManag) AS ItemizedFixedCostsManag,
		|	SUM(PP.ItemizedVariableCostsManag) AS ItemizedVariableCostsManag,
		|	SUM(PP.AddExpensesMan) AS AddExpensesMan,
		|	SUM(PP.CostOffBalanceSheetMan) AS CostOffBalanceSheetMan,

		// Regl Costs
		|	SUM(PP.TangibleCompl) AS TangibleCompl,
		|	SUM(PP.LaborCostsLocal) AS LaborCostsLocal,
		|	SUM(PP.ItemizedFixedCostsCompl) AS ItemizedFixedCostsCompl,
		|	SUM(PP.ItemizedVariableCostsCompl) AS ItemizedVariableCostsCompl,
		|	SUM(PP.AddExpensesLocal) AS AddExpensesLocal,
		|	SUM(PP.OffBalanceCostLocal) AS OffBalanceCostLocal,

		// Tax accounting
		|	SUM(PP.TaxAccounting) AS TaxAccounting,
		|	SUM(PP.PermanentDifference) AS PermanentDifference,
		|	SUM(PP.CostTD) AS CostTD
		|
		|INTO ResultsOfPartiesVNZP
		|FROM
		|	PrimaryGNZPParties AS PP
		|
		|GROUP BY
		|	PP.NodeID,
		|	PP.ItemsLocationAttributes,
		|	PP.Lot,
		|	PP.LotVendorAttributes,
		|	PP.CorItemsLocationAttributes,
		|	PP.CorLot,
		|	PP.Organization
		|
		|INDEX BY
		|	NodeID,
		|	Organization,
		|	ItemsLocationAttributes,
		|	Lot,
		|	LotVendorAttributes,
		|	CorItemsLocationAttributes,
		|	CorLot
		|";
	QueryTexts.Add(QueryText);
	#EndRegion
	
	#Region AnalystIDs
	QueryText = "
		|SELECT DISTINCT
		|	RECORDAUTONUMBER() AS AnalystID,
		|	RetirementFromUnfinishedProductionForBalance.NodeID AS NodeID,
		|	RetirementFromUnfinishedProductionForBalance.Organization AS Organization,
		|	RetirementFromUnfinishedProductionForBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	RetirementFromUnfinishedProductionForBalance.Lot AS Lot
		|INTO AnalystIDs
		|FROM
		|	RetirementFromUnfinishedProductionForBalance AS RetirementFromUnfinishedProductionForBalance
		|";
	QueryTexts.Add(QueryText);
	#EndRegion
	
	#Region SamplingRetirementFromUnfinishedProductionForBalance
	QueryText = "
		|SELECT
		|	AnalystIDs.AnalystID AS AnalystID,
		|	RetirementFromUnfinishedProductionForBalance.NodeID AS NodeID,
		|	RetirementFromUnfinishedProductionForBalance.Organization AS Organization,
		|	RetirementFromUnfinishedProductionForBalance.Period AS Period,
		|	RetirementFromUnfinishedProductionForBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	RetirementFromUnfinishedProductionForBalance.Lot AS Lot,
		|	RetirementFromUnfinishedProductionForBalance.Count AS Count
		|FROM
		|	RetirementFromUnfinishedProductionForBalance AS RetirementFromUnfinishedProductionForBalance  
		|		INNER JOIN AnalystIDs AS AnalystIDs
		|		ON RetirementFromUnfinishedProductionForBalance.NodeID = AnalystIDs.NodeID
		|			AND RetirementFromUnfinishedProductionForBalance.Organization = AnalystIDs.Organization
		|			AND RetirementFromUnfinishedProductionForBalance.ItemsLocationAttributes = AnalystIDs.ItemsLocationAttributes
		|			AND RetirementFromUnfinishedProductionForBalance.Lot = AnalystIDs.Lot
		|
		|ORDER BY
		|	Period
		|";
	QueryTexts.Add(QueryText);
	#EndRegion
	
	#Region SamplingOfPrimaryPartiesOfGNZP
	QueryText = "
		|SELECT
		|	AnalystIDs.AnalystID AS AnalystID,
		|	PrimaryGNZPParties.NodeID AS NodeID,
		|	PrimaryGNZPParties.Period AS Period,
		|	PrimaryGNZPParties.Organization AS Organization,
		|	PrimaryGNZPParties.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	PrimaryGNZPParties.LotVendorAttributes AS LotVendorAttributes,
		|	PrimaryGNZPParties.Lot AS Lot,
		|	PrimaryGNZPParties.CorItemsLocationAttributes AS CorItemsLocationAttributes,
		|	PrimaryGNZPParties.CorLot AS CorLot,
		|	PrimaryGNZPParties.Count AS Count
		|FROM
		|	PrimaryGNZPParties AS PrimaryGNZPParties 
		|		INNER JOIN AnalystIDs AS AnalystIDs
		|		ON PrimaryGNZPParties.NodeID = AnalystIDs.NodeID
		|			AND PrimaryGNZPParties.Organization = AnalystIDs.Organization
		|			AND PrimaryGNZPParties.CorItemsLocationAttributes = AnalystIDs.ItemsLocationAttributes
		|			AND PrimaryGNZPParties.CorLot = AnalystIDs.Lot
		|
		|ORDER BY
		|	Period
		|";
	QueryTexts.Add(QueryText);
	#EndRegion
	
	#Region SamplingExpenseOfBatches
	QueryText = "
		|SELECT TOP 0
		|	0 AS AnalystID,
		|	PrimaryGNZPParties.NodeID AS NodeID,
		|	PrimaryGNZPParties.Period AS Period,
		|	PrimaryGNZPParties.Organization AS Organization,
		|	PrimaryGNZPParties.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	PrimaryGNZPParties.LotVendorAttributes AS LotVendorAttributes,
		|	PrimaryGNZPParties.Lot AS Lot,
		|	PrimaryGNZPParties.CorItemsLocationAttributes AS CorItemsLocationAttributes,
		|	PrimaryGNZPParties.CorLot AS CorLot,
		|	PrimaryGNZPParties.Count AS Count
		|FROM
		|	PrimaryGNZPParties AS PrimaryGNZPParties
		|";
	QueryTexts.Add(QueryText);
	#EndRegion
	
	QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	Return QueryText;
	
EndFunction

Function QueryTextNodulationResultsPreliminary(DeductAdditionalExpenses, TreeParameters)
	
	QueryTexts = New Array;
	
	#Region TextMaterialCosts
	
	#Region PreliminaryConsumptionOfBatches
	QueryText = "
		|SELECT
		|	Disposal.NodeID			AS NodeID,
		|	Disposal.Organization					AS Organization,
		|	Disposal.Period						AS Period,
		|	MAX(PP.MonthOfPrimaryLotReferenceVNZP)	AS MonthOfPrimaryLotReferenceVNZP,
		|	PP.ItemsLocationAttributes		AS ItemsLocationAttributes,
		|	PP.LotVendorAttributes				AS LotVendorAttributes,
		|	PP.Lot							AS Lot,
		|	Disposal.CorItemsLocationAttributes	AS CorItemsLocationAttributes,
		|	Disposal.CorLot						AS CorLot,
		|
		|	MAX(PP.IncludePersonalIncomeTaxCost) AS IncludePersonalIncomeTaxCost,
		|	MAX(PP.ExcludeVATFromCost) AS ExcludeVATFromCost,
		|
		|	SUM(Disposal.Count) AS Count,
		|
		// The cost according to the parameter ""Data of the cost""
		|	SUM(
		|		CAST(Disposal.Count / PP.Count * PP.Material_ AS NUMBER(23, 10))) AS Material_,
		|	SUM(
		|		CAST(Disposal.Count / PP.Count * PP.LaborCosts AS NUMBER(23, 10))) AS LaborCosts,
		|	SUM(
		|		CAST(Disposal.Count / PP.Count * PP.ItemizedFixed AS NUMBER(23, 10))) AS ItemizedFixed,
		|	SUM(
		|		CAST(Disposal.Count / PP.Count * PP.ItemizedVariable AS NUMBER(23, 10))) AS ItemizedVariable,
		|	SUM(
		|		CAST(Disposal.Count / PP.Count * PP.AddExpensesForGoods AS NUMBER(23, 10))) AS AddExpensesForGoods,
		|	SUM(
		|		CAST(Disposal.Count / PP.Count * PP.OffBalanceSheetCostAmount AS NUMBER(23, 10))) AS OffBalanceSheetCostAmount,
		|	SUM(
		|		CAST(Disposal.Count / PP.Count * PP.CostAmount AS NUMBER(23, 10))) AS CostAmount,
		|	SUM(
		|		CAST(Disposal.Count / PP.Count * PP.AIT AS NUMBER(23, 10))) AS AIT,
		
		// Costs with VAT
		|	SUM(
		|		CAST(Disposal.Count / PP.Count * PP.TangibleIncludingVAT AS NUMBER(23, 10))) AS TangibleIncludingVAT,
		|	SUM(
		|		CAST(Disposal.Count / PP.Count * PP.LaborCostsIncludingVAT AS NUMBER(23, 10))) AS LaborCostsIncludingVAT,
		|	SUM(
		|		CAST(Disposal.Count / PP.Count * PP.ItemizedFixedCostsIncludingVAT AS NUMBER(23, 10))) AS ItemizedFixedCostsIncludingVAT,
		|	SUM(
		|		CAST(Disposal.Count / PP.Count * PP.ItemizedVariableCostsIncludingVAT AS NUMBER(23, 10))) AS ItemizedVariableCostsIncludingVAT,
		|	SUM(
		|		CAST(Disposal.Count / PP.Count * PP.AdditionalExpensesIncludingVAT AS NUMBER(23, 10))) AS AdditionalExpensesIncludingVAT,
		
		// Costs without VAT
		|	SUM(
		|		CAST(Disposal.Count / PP.Count * PP.TangibleExcludingVAT AS NUMBER(23, 10))) AS TangibleExcludingVAT,
		|	SUM(
		|		CAST(Disposal.Count / PP.Count * PP.ItemizedFixedCostsExcludingVAT AS NUMBER(23, 10))) AS ItemizedFixedCostsExcludingVAT,
		|	SUM(
		|		CAST(Disposal.Count / PP.Count * PP.ItemizedVariableCostsExcludingVAT AS NUMBER(23, 10))) AS ItemizedVariableCostsExcludingVAT,
		|	SUM(
		|		CAST(Disposal.Count / PP.Count * PP.AdditionalExpensesExcludingVAT AS NUMBER(23, 10))) AS AdditionalExpensesExcludingVAT,
		
		// The Cost of Upr
		|	SUM(
		|		CAST(Disposal.Count / PP.Count * PP.MaterialMan AS NUMBER(23, 10))) AS MaterialMan,
		|	SUM(
		|		CAST(Disposal.Count / PP.Count * PP.LaborCostsMan AS NUMBER(23, 10))) AS LaborCostsMan,
		|	SUM(
		|		CAST(Disposal.Count / PP.Count * PP.ItemizedFixedCostsManag AS NUMBER(23, 10))) AS ItemizedFixedCostsManag,
		|	SUM(
		|		CAST(Disposal.Count / PP.Count * PP.ItemizedVariableCostsManag AS NUMBER(23, 10))) AS ItemizedVariableCostsManag,
		|	SUM(
		|		CAST(Disposal.Count / PP.Count * PP.AddExpensesMan AS NUMBER(23, 10))) AS AddExpensesMan,
		|	SUM(
		|		CAST(Disposal.Count / PP.Count * PP.CostOffBalanceSheetMan AS NUMBER(23, 10))) AS CostOffBalanceSheetMan,
		
		// Regl Costs
		|	SUM(
		|		CAST(Disposal.Count / PP.Count * PP.TangibleCompl AS NUMBER(23, 10))) AS TangibleCompl,
		|	SUM(
		|		CAST(Disposal.Count / PP.Count * PP.LaborCostsLocal AS NUMBER(23, 10))) AS LaborCostsLocal,
		|	SUM(
		|		CAST(Disposal.Count / PP.Count * PP.ItemizedFixedCostsCompl AS NUMBER(23, 10))) AS ItemizedFixedCostsCompl,
		|	SUM(
		|		CAST(Disposal.Count / PP.Count * PP.ItemizedVariableCostsCompl AS NUMBER(23, 10))) AS ItemizedVariableCostsCompl,
		|	SUM(
		|		CAST(Disposal.Count / PP.Count * PP.AddExpensesLocal AS NUMBER(23, 10))) AS AddExpensesLocal,
		|	SUM(
		|		CAST(Disposal.Count / PP.Count * PP.OffBalanceCostLocal AS NUMBER(23, 10))) AS OffBalanceCostLocal,
		|
		// Tax accounting
		|	SUM(
		|		CAST(Disposal.Count / PP.Count * PP.TaxAccounting AS NUMBER(23, 10))) AS TaxAccounting,
		|	SUM(
		|		CAST(Disposal.Count / PP.Count * PP.PermanentDifference AS NUMBER(23, 10))) AS PermanentDifference,
		|	SUM(
		|		CAST(Disposal.Count / PP.Count * PP.CostTD AS NUMBER(23, 10))) AS CostTD
		|
		|INTO PreliminaryConsumptionOfBatches
		|FROM
		|	DisposalFromUnfinishedProduction AS DisposalFromUnfinishedProduction
		|		INNER JOIN BatchEXPENSE AS Disposal
		|		ON DisposalFromUnfinishedProduction.NodeID = Disposal.NodeID
		|			AND DisposalFromUnfinishedProduction.Organization = Disposal.Organization
		|			AND DisposalFromUnfinishedProduction.ItemsLocationAttributes = Disposal.CorItemsLocationAttributes
		|			AND DisposalFromUnfinishedProduction.Lot = Disposal.CorLot
		|			AND DisposalFromUnfinishedProduction.Period = Disposal.Period
		|
		|		INNER JOIN ResultsOfPartiesVNZP AS PP
		|		ON Disposal.NodeID = PP.NodeID
		|			AND Disposal.Organization = PP.Organization
		|			AND Disposal.ItemsLocationAttributes = PP.ItemsLocationAttributes
		|			AND Disposal.Lot = PP.Lot
		|			AND Disposal.LotVendorAttributes = PP.LotVendorAttributes
		|			AND Disposal.CorItemsLocationAttributes = PP.CorItemsLocationAttributes
		|			AND Disposal.CorLot = PP.CorLot
		|
		|GROUP BY
		|	Disposal.NodeID,
		|	Disposal.Organization,
		|	Disposal.Period,
		|	Disposal.CorItemsLocationAttributes,
		|	Disposal.CorLot,
		|	PP.LotVendorAttributes,
		|	PP.ItemsLocationAttributes,
		|	PP.Lot
		|
		|INDEX BY SETS
		|(
		|	(NodeID, CorItemsLocationAttributes, CorLot, ItemsLocationAttributes,
		|		LotVendorAttributes, Lot, Organization, Period),
		|	(NodeID, CorLot, Organization, ItemsLocationAttributes, LotVendorAttributes, Lot),
		|	(NodeID, Lot)
		|)
		|";
	QueryTexts.Add(QueryText);
	#EndRegion
	
	#Region PrimaryPartiesConsolidated
		QueryText = "
		|SELECT DISTINCT
		|	T.NodeID AS NodeID,
		|	T.Organization AS Organization,
		|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	T.LotVendorAttributes AS LotVendorAttributes,
		|	T.Lot AS Lot
		|INTO PrimaryPartiesConsolidated
		|FROM
		|	PreliminaryConsumptionOfBatches AS T
		|
		|INDEX BY
		|	NodeID,
		|	Lot
		|";
		QueryTexts.Add(QueryText);
	#EndRegion
		
	#Region BatchesOfSemiFinishedProducts
		QueryText = "
		|SELECT DISTINCT
		|	PP.NodeID AS NodeID,
		|	CASE WHEN &Cost_Data < 3
		|		THEN UNDEFINED
		|		ELSE InventoryCost.Organization
		|	END AS Organization,
		|	PP.Lot AS Lot,
		|	PP.LotVendorAttributes,
		|	PP.ItemsLocationAttributes
		|INTO BatchesOfSemiFinishedProducts
		|FROM
		|	PrimaryPartiesConsolidated AS PP
		|
		|	INNER JOIN AccumulationRegister.InventoryCost AS InventoryCost
		|		ON InventoryCost.Recorder = PP.Lot
		|		AND InventoryCost.LotVendorAttributes = PP.LotVendorAttributes
		|		AND (InventoryCost.Period <= &EndDate OR &EndDate = DATETIME(1,1,1))
		|
		// Adding branches of the parent company, branches with the same parent company, and the parent company of the branch.
		|	LEFT JOIN TTInterconnectedCompanies AS TTInterconnectedCompanies
		|		ON InventoryCost.Organization = TTInterconnectedCompanies.Organization1
		|			AND PP.Organization = TTInterconnectedCompanies.Organization2
		|
		|	LEFT JOIN InformationRegister.LotVendorAttributes AS PartyAccountingAnalysts
		|		ON InventoryCost.LotVendorAttributes = PartyAccountingAnalysts.DimensionKey
		|
		|WHERE
		|	InventoryCost.RecordType = VALUE(AccumulationRecordType.Receipt)
		|	AND InventoryCost.BusinessOperation IN (VALUE(Enum.BusinessTransactions.ProductsRelease),
		|													VALUE(Enum.BusinessTransactions.ProductsReleaseToWarehouse),
		|													VALUE(Enum.BusinessTransactions.ProductsReleaseToBusinessUnit),
		|													VALUE(Enum.BusinessTransactions.WorkAcceptanceAndTransferBetweenBranchOffices),
		|													VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredIntercompany))
		|	AND NOT PartyAccountingAnalysts.RowCode = 0
		|	AND (InventoryCost.Organization = PP.Organization
		|		OR TTInterconnectedCompanies.Organization1 IS NOT NULL)
		|
		|INDEX BY
		|	NodeID,
		|	Lot
		|";
		QueryTexts.Add(QueryText);
	#EndRegion
	
	#Region InclusionExclusionOfVATInCost
		QueryText = "
		|SELECT
		|	PP.NodeID AS NodeID,
		|	InventoryCost.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	InventoryCost.Lot AS Lot,
		|	CASE WHEN InventoryCost.RecordType = VALUE(AccumulationRecordType.Expense)
		|		THEN -1
		|		ELSE 1
		|	END
		|	*
		|	CASE
		|		WHEN &Cost_Data = 3
		|			THEN InventoryCost.CostMan
		|		WHEN &Cost_Data = 4
		|			THEN InventoryCost.LocalCost
		|	END AS Cost
		|INTO TTInclusionExclusionOfCostVAT
		|FROM
		|	AccumulationRegister.InventoryCost AS InventoryCost
		|		INNER JOIN DisposalFromUnfinishedProduction AS PP
		|		ON &Cost_Data > 2
		|			AND InventoryCost.ItemsLocationAttributes = PP.ItemsLocationAttributes
		|			AND InventoryCost.Lot = PP.Lot
		|			AND (InventoryCost.EntryType = VALUE(Enum.LotRecordTypes.InclusionExclusionOfVATInCost))
		|			AND (InventoryCost.Period <= &EndDate
		|				OR &EndDate = DATETIME(1, 1, 1))
		|
		|INDEX BY
		|	NodeID,
		|	ItemsLocationAttributes,
		|	Lot
		|";
		QueryTexts.Add(QueryText);
	#EndRegion
	
	#Region TTReleasedAnalyticsManufacturedProductsForSelections
	
	QueryText = "
		|SELECT DISTINCT
		|	IssuedProducts.Organization AS Organization,
		|	IssuedProducts.ProductsAccountingDimension AS ProductsAccountingDimension,
		|	IssuedProducts.ProductsBatch AS ProductsBatch,
		|	IssuedProducts.ProductBatchAccountingDimension AS ProductBatchAccountingDimension
		|INTO TTReleasedAnalyticsManufacturedProductsForSelections
		|FROM
		|	IssuedProducts AS IssuedProducts
		|		
		|INDEX BY
		|	ProductsAccountingDimension,
		|	ProductsBatch,
		|	ProductBatchAccountingDimension,
		|	Organization	
		|";
	QueryTexts.Add(QueryText);
	
	#EndRegion
	
	#EndRegion
	
	#Region TTOtherWorkInProgressExpenses__
	
	QueryText = "
		|SELECT ALLOWED
		|	OtherExpensesOfUnfinishedProduction.Organization AS Organization,
		|	OtherExpensesOfUnfinishedProduction.Recorder AS Recorder,
		|	OtherExpensesOfUnfinishedProduction.LotVendorAttributesCorr AS LotVendorAttributesCorr,
		|	OtherExpensesOfUnfinishedProduction.ProductsAccountingDimension AS ProductsAccountingDimension,
		|	OtherExpensesOfUnfinishedProduction.ExpenseItem AS ExpenseItem,
		|	OtherExpensesOfUnfinishedProduction.ProductCostElement AS ProductCostElement,
		|	OtherExpensesOfUnfinishedProduction.Department AS Department,
		|	SUM(CASE
		|			WHEN ExpenseItems.ProductionCostType = VALUE(Enum.ProductionCostType.Variables1)
		|				THEN 0
		|			WHEN &Cost_Data = 1
		|				THEN OtherExpensesOfUnfinishedProduction.Cost
		|			WHEN &Cost_Data = 2
		|				THEN OtherExpensesOfUnfinishedProduction.CostExcludingVAT
		|			WHEN &Cost_Data = 3
		|				THEN OtherExpensesOfUnfinishedProduction.CostMan
		|			WHEN &Cost_Data = 4
		|				THEN OtherExpensesOfUnfinishedProduction.LocalCost
		|		END) AS ItemizedFixed,
		|	SUM(CASE
		|			WHEN ExpenseItems.ProductionCostType = VALUE(Enum.ProductionCostType.Constant)
		|				THEN 0
		|			WHEN &Cost_Data = 1
		|				THEN OtherExpensesOfUnfinishedProduction.Cost
		|			WHEN &Cost_Data = 2
		|				THEN OtherExpensesOfUnfinishedProduction.CostExcludingVAT
		|			WHEN &Cost_Data = 3
		|				THEN OtherExpensesOfUnfinishedProduction.CostMan
		|			WHEN &Cost_Data = 4
		|				THEN OtherExpensesOfUnfinishedProduction.LocalCost
		|		END) AS ItemizedVariable,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN OtherExpensesOfUnfinishedProduction.Cost
		|			WHEN &Cost_Data = 2
		|				THEN OtherExpensesOfUnfinishedProduction.CostExcludingVAT
		|			WHEN &Cost_Data = 3
		|				THEN OtherExpensesOfUnfinishedProduction.CostMan
		|			WHEN &Cost_Data = 4
		|				THEN OtherExpensesOfUnfinishedProduction.LocalCost
		|		END) AS CostAmount,
		|	SUM(CASE
		|			WHEN &Cost_Data = 4
		|				THEN OtherExpensesOfUnfinishedProduction.CostOfPersonalIncomeTax
		|			ELSE 0
		|		END) AS AIT,
		|	SUM(CASE
		|			WHEN ExpenseItems.ProductionCostType = VALUE(Enum.ProductionCostType.Variables1)
		|				THEN 0
		|			ELSE OtherExpensesOfUnfinishedProduction.Cost
		|		END) AS ItemizedFixedCostsIncludingVAT,
		|	SUM(CASE
		|			WHEN ExpenseItems.ProductionCostType = VALUE(Enum.ProductionCostType.Constant)
		|				THEN 0
		|			ELSE OtherExpensesOfUnfinishedProduction.Cost
		|		END) AS ItemizedVariableCostsIncludingVAT,
		|	SUM(CASE
		|			WHEN ExpenseItems.ProductionCostType = VALUE(Enum.ProductionCostType.Variables1)
		|				THEN 0
		|			ELSE OtherExpensesOfUnfinishedProduction.CostExcludingVAT
		|		END) AS ItemizedFixedCostsExcludingVAT,
		|	SUM(CASE
		|			WHEN ExpenseItems.ProductionCostType = VALUE(Enum.ProductionCostType.Constant)
		|				THEN 0
		|			ELSE OtherExpensesOfUnfinishedProduction.CostExcludingVAT
		|		END) AS ItemizedVariableCostsExcludingVAT,
		|	SUM(CASE
		|			WHEN ExpenseItems.ProductionCostType = VALUE(Enum.ProductionCostType.Variables1)
		|				THEN 0
		|			ELSE OtherExpensesOfUnfinishedProduction.CostMan
		|		END) AS ItemizedFixedCostsManag,
		|	SUM(CASE
		|			WHEN ExpenseItems.ProductionCostType = VALUE(Enum.ProductionCostType.Constant)
		|				THEN 0
		|			ELSE OtherExpensesOfUnfinishedProduction.CostMan
		|		END) AS ItemizedVariableCostsManag,
		|	SUM(CASE
		|			WHEN ExpenseItems.ProductionCostType = VALUE(Enum.ProductionCostType.Variables1)
		|				THEN 0
		|			ELSE OtherExpensesOfUnfinishedProduction.LocalCost
		|		END) AS ItemizedFixedCostsCompl,
		|	SUM(CASE
		|			WHEN ExpenseItems.ProductionCostType = VALUE(Enum.ProductionCostType.Constant)
		|				THEN 0
		|			ELSE OtherExpensesOfUnfinishedProduction.LocalCost
		|		END) AS ItemizedVariableCostsCompl,
		|	SUM(OtherExpensesOfUnfinishedProduction.LocalCost - OtherExpensesOfUnfinishedProduction.PermanentDifference - OtherExpensesOfUnfinishedProduction.CostTD) AS TaxAccounting,
		|	SUM(OtherExpensesOfUnfinishedProduction.PermanentDifference) AS PermanentDifference,
		|	SUM(OtherExpensesOfUnfinishedProduction.CostTD) AS CostTD
		|INTO TTOtherWorkInProgressExpenses__
		|FROM
		|	AccumulationRegister.OtherWorkInProgressExpenses AS OtherExpensesOfUnfinishedProduction
		|		INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
		|		ON (OtherExpensesOfUnfinishedProduction.ExpenseItem = ExpenseItems.Ref)
		|WHERE
		|	TRUE IN
		|			(SELECT TOP 1
		|				TRUE
		|			FROM
		|				TTReleasedAnalyticsManufacturedProductsForSelections AS T
		|			WHERE
		|				T.ProductsAccountingDimension = OtherExpensesOfUnfinishedProduction.ProductsAccountingDimension
		|				AND T.ProductsBatch = OtherExpensesOfUnfinishedProduction.Recorder
		|				AND T.ProductBatchAccountingDimension = OtherExpensesOfUnfinishedProduction.LotVendorAttributesCorr
		|				AND T.Organization = OtherExpensesOfUnfinishedProduction.Organization)
		|	AND NOT OtherExpensesOfUnfinishedProduction.ReversingEntry
		|
		|GROUP BY
		|	OtherExpensesOfUnfinishedProduction.Organization,
		|	OtherExpensesOfUnfinishedProduction.ExpenseItem,
		|	OtherExpensesOfUnfinishedProduction.ProductCostElement,
		|	OtherExpensesOfUnfinishedProduction.ProductsAccountingDimension,
		|	OtherExpensesOfUnfinishedProduction.Recorder,
		|	OtherExpensesOfUnfinishedProduction.LotVendorAttributesCorr,
		|	OtherExpensesOfUnfinishedProduction.Department
		|
		|INDEX BY
		|	ProductsAccountingDimension,
		|	Recorder,
		|	LotVendorAttributesCorr,
		|	Organization
		|";
		
	QueryTexts.Add(QueryText);
	
	#EndRegion
	
	#Region TTWIPLaborCostsOfWorkInProgress
	
	QueryText = "
		|SELECT
		|	LaborCostsOfUnfinishedProduction.Organization						AS Organization,
		|	LaborCostsOfUnfinishedProduction.Recorder						AS Recorder,
		|	LaborCostsOfUnfinishedProduction.LotVendorAttributesCorr			AS LotVendorAttributesCorr,
		|	LaborCostsOfUnfinishedProduction.CorDimensionOfProductsAccounting		AS CorDimensionOfProductsAccounting,
		|	LaborCostsOfUnfinishedProduction.WorkKind						AS WorkKind,
		|	LaborCostsOfUnfinishedProduction.ProductCostElement				AS ProductCostElement,
		|	LaborCostsOfUnfinishedProduction.Department					AS Department,
		|	SUM(LaborCostsOfUnfinishedProduction.Count) AS Count,
		|
		// The cost according to the parameter ""Data of the cost""
		|	SUM(CASE
		|		WHEN &Cost_Data = 1
		|			THEN LaborCostsOfUnfinishedProduction.Cost
		|		WHEN &Cost_Data = 2
		|			THEN LaborCostsOfUnfinishedProduction.Cost
		|		WHEN &Cost_Data = 3
		|			THEN LaborCostsOfUnfinishedProduction.Cost
		|		WHEN &Cost_Data = 4
		|			THEN LaborCostsOfUnfinishedProduction.LocalCost
		|	END) AS Cost,
		|	SUM(CASE
		|			WHEN &Cost_Data = 4
		|				THEN LaborCostsOfUnfinishedProduction.CostOfPersonalIncomeTax
		|			ELSE 0
		|		END) AS CostOfPersonalIncomeTax,
		|
		// Regl Costs
		|	SUM(LaborCostsOfUnfinishedProduction.LocalCost) AS LocalCost,
		|
		// Tax accounting
		|	SUM(LaborCostsOfUnfinishedProduction.LocalCost
		|		- LaborCostsOfUnfinishedProduction.PermanentDifference
		|		- LaborCostsOfUnfinishedProduction.CostTD) AS TaxAccounting,
		|	SUM(LaborCostsOfUnfinishedProduction.PermanentDifference) AS PermanentDifference,
		|	SUM(LaborCostsOfUnfinishedProduction.CostTD) AS CostTD
		|
		|INTO TTWIPLaborCostsOfWorkInProgress
		|
		|FROM
		|	AccumulationRegister.WIPLaborCosts AS LaborCostsOfUnfinishedProduction
		|WHERE
		|	TRUE IN (SELECT TOP 1 TRUE
		|		FROM TTReleasedAnalyticsManufacturedProductsForSelections AS T
		|		WHERE T.Organization = LaborCostsOfUnfinishedProduction.Organization
		|			AND T.ProductsBatch = LaborCostsOfUnfinishedProduction.Recorder
		|			AND T.ProductBatchAccountingDimension = LaborCostsOfUnfinishedProduction.LotVendorAttributesCorr
		|			AND T.ProductsAccountingDimension = LaborCostsOfUnfinishedProduction.CorDimensionOfProductsAccounting
		|	)
		|	AND NOT LaborCostsOfUnfinishedProduction.ReversingEntry
		|
		|GROUP BY
		|	LaborCostsOfUnfinishedProduction.Organization,
		|	LaborCostsOfUnfinishedProduction.WorkKind,
		|	LaborCostsOfUnfinishedProduction.ProductCostElement,
		|	LaborCostsOfUnfinishedProduction.CorDimensionOfProductsAccounting,
		|	LaborCostsOfUnfinishedProduction.Recorder,
		|	LaborCostsOfUnfinishedProduction.LotVendorAttributesCorr,
		|	LaborCostsOfUnfinishedProduction.Department
		|
		|INDEX BY
		|	Recorder,
		|	CorDimensionOfProductsAccounting,
		|	LotVendorAttributesCorr,
		|	Organization
		|";
		QueryTexts.Add(QueryText);
	
	#EndRegion

	MergeRequestTexts = New Array;
	
	#Region TextMaterialCostsAssociation

	TextMaterialCostsAssociation = "
		|SELECT
		|	UnfinishedProductionByProduct.NodeID AS NodeID,
		|	UnfinishedProductionByProduct.IdOfFirstLevelNode AS IdOfFirstLevelNode,
		|	UnfinishedProductionByProduct.NodeOfFirstLevel_AnalyticsOfManufacturedProductAccounting AS NodeOfFirstLevel_AnalyticsOfManufacturedProductAccounting,
		|	UnfinishedProductionByProduct.NodeOfFirstLevel_LotReferenceOfManufacturedProducts AS NodeOfFirstLevel_LotReferenceOfManufacturedProducts,
		|	UnfinishedProductionByProduct.NodeOfFirstLevelIs_BatchAccountingAnalysisOfManufacturedProductsLotsVendorAttributes AS NodeOfFirstLevelIs_BatchAccountingAnalysisOfManufacturedProductsLotsVendorAttributes,
		|	UnfinishedProductionByProduct.OriginalBatchDate AS OriginalBatchDate,
		|	UnfinishedProductionByProduct.DeployAdditionalCosts AS DeployAdditionalCosts,
		|	UnfinishedProductionByProduct.SourceNodeNeedsToBeDisconnected AS SourceNodeNeedsToBeDisconnected,
		|
		|	BatchesOfMaterials.MonthOfPrimaryLotReferenceVNZP			AS MonthOfPrimaryLotReferenceVNZP,
		|
		|	UnfinishedProductionByProduct.Organization							AS Organization,
		|	UnfinishedProductionByProduct.ProductsBatch						AS BatchFinishedProduct,
		|	UnfinishedProductionByProduct.ProductBatchAccountingDimension		AS BatchAccountingDimensionFinishedProduct,
		|	UnfinishedProductionByProduct.ExpenseAccountingAnalytics					AS AccountingDimensionFinishedProduct,
		|	BatchesOfMaterials.Lot								AS BatchCost,
		|	BatchesOfMaterials.LotVendorAttributes				AS BatchAccountingDimensionCost,
		|	BatchesOfMaterials.IncludePersonalIncomeTaxCost				AS IncludePersonalIncomeTaxCost,
		|	BatchesOfMaterials.ExcludeVATFromCost			AS ExcludeVATFromCost,
		|	BatchesOfMaterials.ItemsLocationAttributes			AS CostAccountingDimension,
		|	DimensionCosts_.Products						AS Cost_,
		|	DimensionCosts_.Products.UnitOfMeasure 		AS UnitOfMeasurementCost,
		|	DimensionCosts_.Characteristic						AS CostCharacteristics,
		|	DimensionCosts_.Series								AS CostSeries,
		|	DimensionCosts_.Purpose							AS DestinationCost,
		|	DimensionCosts_.ProductCostElement					AS ProductCostElement,
		|	DimensionCosts_.StorageLocation                       AS Department,
		|	(CASE
		|		WHEN UnfinishedProductionByProduct.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider)
		|			THEN FALSE
		// For recyclable waste, no separation is required. 
		|		WHEN DimensionCosts_.ProductCostElement.ExpenseType = VALUE(Enum.CostTypes.RecyclableWaste)
		|			THEN FALSE
		// It is not necessary to find out the expenses of the processor, if the report is generated in the currency of the regulatory/ upr. accounting, according to the giver, it is not necessary
		|		WHEN &Cost_Data > 3
		|			AND UnfinishedProductionByProduct.Organization = CAST(BatchesOfMaterials.Lot AS Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany).MaterialProvider
		|				THEN FALSE
		|		WHEN BatchesOfSemiFinishedProducts.Lot IS NOT NULL
		|				AND (BatchesOfSemiFinishedProducts.Organization = UnfinishedProductionByProduct.Organization
		//						Adding branches of the parent company, branches with the same parent company, and the parent company of the branch.
		|						OR TTInterconnectedCompanies.Organization1 IS NOT NULL
		|						OR &Cost_Data < 3)
		|			THEN TRUE
		|		ELSE FALSE END) 								AS ExplosionIsRequired,
		|	(CASE
		|		WHEN UnfinishedProductionByProduct.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider)
		|			THEN FALSE
		// It is not necessary to find out the expenses of the processor, if the report is generated in the currency of the regulatory/ upr. accounting, according to the giver, it is not necessary
		|		WHEN &Cost_Data > 3
		|			AND UnfinishedProductionByProduct.Organization = CAST(BatchesOfMaterials.Lot AS Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany).MaterialProvider
		|				THEN FALSE
		|		WHEN UnfinishedProductionByProduct.DeployAdditionalCosts
		|			THEN TRUE
		|		ELSE FALSE END) 								AS ItIsRequiredToUnpackAdditionalExpenseAmount,
		|	&TypeOfCostsMaterial								AS ExpenseType,
		|	BatchesOfMaterials.Count
		|		* CAST(UnfinishedProductionByProduct.Count / DisposalSummary.Count AS NUMBER(31,10))
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS CostQuantity,
		|
		// The cost according to the parameter ""Data of the cost""
		|	BatchesOfMaterials.Material_
		|		* CAST(UnfinishedProductionByProduct.Count / DisposalSummary.Count AS NUMBER(31,10))
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS Material_,
		|	BatchesOfMaterials.LaborCosts
		|		* CAST(UnfinishedProductionByProduct.Count / DisposalSummary.Count AS NUMBER(31,10))
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS LaborCosts,
		|	BatchesOfMaterials.ItemizedFixed
		|		* CAST(UnfinishedProductionByProduct.Count / DisposalSummary.Count AS NUMBER(31,10))
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS ItemizedFixed,
		|	BatchesOfMaterials.ItemizedVariable
		|		* CAST(UnfinishedProductionByProduct.Count / DisposalSummary.Count AS NUMBER(31,10))
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS ItemizedVariable,
		|	BatchesOfMaterials.AddExpensesForGoods
		|		* CAST(UnfinishedProductionByProduct.Count / DisposalSummary.Count AS NUMBER(31,10))
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS AddExpensesForGoods,
		|	BatchesOfMaterials.OffBalanceSheetCostAmount
		|		* CAST(UnfinishedProductionByProduct.Count / DisposalSummary.Count AS NUMBER(31,10))
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS OffBalanceSheetCostAmount,
		|	BatchesOfMaterials.CostAmount
		|		* CAST(UnfinishedProductionByProduct.Count / DisposalSummary.Count AS NUMBER(31,10))
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS CostAmount,
		|	BatchesOfMaterials.AIT
		|		* CAST(UnfinishedProductionByProduct.Count / DisposalSummary.Count AS NUMBER(31,10))
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS AIT,
		|
		// Costs with VAT
		|	BatchesOfMaterials.TangibleIncludingVAT
		|		* CAST(UnfinishedProductionByProduct.Count / DisposalSummary.Count AS NUMBER(31,10))
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS TangibleIncludingVAT,
		|	BatchesOfMaterials.LaborCostsIncludingVAT
		|		* CAST(UnfinishedProductionByProduct.Count / DisposalSummary.Count AS NUMBER(31,10))
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS LaborCostsIncludingVAT,
		|	BatchesOfMaterials.ItemizedFixedCostsIncludingVAT
		|		* CAST(UnfinishedProductionByProduct.Count / DisposalSummary.Count AS NUMBER(31,10))
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS ItemizedFixedCostsIncludingVAT,
		|	BatchesOfMaterials.ItemizedVariableCostsIncludingVAT
		|		* CAST(UnfinishedProductionByProduct.Count / DisposalSummary.Count AS NUMBER(31,10))
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS ItemizedVariableCostsIncludingVAT,
		|	BatchesOfMaterials.AdditionalExpensesIncludingVAT
		|		* CAST(UnfinishedProductionByProduct.Count / DisposalSummary.Count AS NUMBER(31,10))
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS AdditionalExpensesIncludingVAT,
		|
		// Costs without VAT
		|	BatchesOfMaterials.TangibleExcludingVAT
		|		* CAST(UnfinishedProductionByProduct.Count / DisposalSummary.Count AS NUMBER(31,10))
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS TangibleExcludingVAT,
		|	BatchesOfMaterials.ItemizedFixedCostsExcludingVAT
		|		* CAST(UnfinishedProductionByProduct.Count / DisposalSummary.Count AS NUMBER(31,10))
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS ItemizedFixedCostsExcludingVAT,
		|	BatchesOfMaterials.ItemizedVariableCostsExcludingVAT
		|		* CAST(UnfinishedProductionByProduct.Count / DisposalSummary.Count AS NUMBER(31,10))
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS ItemizedVariableCostsExcludingVAT,
		|	BatchesOfMaterials.AdditionalExpensesExcludingVAT
		|		* CAST(UnfinishedProductionByProduct.Count / DisposalSummary.Count AS NUMBER(31,10))
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS AdditionalExpensesExcludingVAT,
		|
		// The Cost of Upr
		|	BatchesOfMaterials.MaterialMan
		|		* CAST(UnfinishedProductionByProduct.Count / DisposalSummary.Count AS NUMBER(31,10))
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS MaterialMan,
		|	BatchesOfMaterials.LaborCostsMan
		|		* CAST(UnfinishedProductionByProduct.Count / DisposalSummary.Count AS NUMBER(31,10))
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10))	AS LaborCostsMan,
		|	BatchesOfMaterials.ItemizedFixedCostsManag
		|		* CAST(UnfinishedProductionByProduct.Count / DisposalSummary.Count AS NUMBER(31,10))
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS ItemizedFixedCostsManag,
		|	BatchesOfMaterials.ItemizedVariableCostsManag
		|		* CAST(UnfinishedProductionByProduct.Count / DisposalSummary.Count AS NUMBER(31,10))
		|		* CAST(UnfinishedProductionByProduct.Numerator	/ UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS ItemizedVariableCostsManag,
		|	BatchesOfMaterials.AddExpensesMan
		|		* CAST(UnfinishedProductionByProduct.Count / DisposalSummary.Count AS NUMBER(31,10))
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS AddExpensesMan,
		|	BatchesOfMaterials.CostOffBalanceSheetMan
		|		* CAST(UnfinishedProductionByProduct.Count / DisposalSummary.Count AS NUMBER(31,10))
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator  AS NUMBER(31,10)) AS CostOffBalanceSheetMan,
		|
		// Regl Costs
		|	BatchesOfMaterials.TangibleCompl
		|		* CAST(UnfinishedProductionByProduct.Count / DisposalSummary.Count AS NUMBER(31,10))
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS TangibleCompl,
		|	BatchesOfMaterials.LaborCostsLocal
		|		* CAST(UnfinishedProductionByProduct.Count / DisposalSummary.Count AS NUMBER(31,10))
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS LaborCostsLocal,
		|	BatchesOfMaterials.ItemizedFixedCostsCompl
		|		* CAST(UnfinishedProductionByProduct.Count / DisposalSummary.Count AS NUMBER(31,10))
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS ItemizedFixedCostsCompl,
		|	BatchesOfMaterials.ItemizedVariableCostsCompl
		|		* CAST(UnfinishedProductionByProduct.Count / DisposalSummary.Count AS NUMBER(31,10))
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS ItemizedVariableCostsCompl,
		|	BatchesOfMaterials.AddExpensesLocal
		|		* CAST(UnfinishedProductionByProduct.Count / DisposalSummary.Count AS NUMBER(31,10))
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS AddExpensesLocal,
		|	BatchesOfMaterials.OffBalanceCostLocal
		|		* CAST(UnfinishedProductionByProduct.Count / DisposalSummary.Count AS NUMBER(31,10))
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS OffBalanceCostLocal,
		|
		// Tax accounting
		|	BatchesOfMaterials.TaxAccounting
		|		* CAST(UnfinishedProductionByProduct.Count / DisposalSummary.Count AS NUMBER(31,10))
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS TaxAccounting,
		|	BatchesOfMaterials.PermanentDifference
		|		* CAST(UnfinishedProductionByProduct.Count / DisposalSummary.Count AS NUMBER(31,10))
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS PermanentDifference,
		|	BatchesOfMaterials.CostTD
		|		* CAST(UnfinishedProductionByProduct.Count / DisposalSummary.Count AS NUMBER(31,10))
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS CostTD,
		|
		// Inclusion exclusion of VAT in the cost
		|	CASE
		|		WHEN TTInclusionExclusionOfCostVAT.Cost IS NULL
		|			THEN 0
		|		ELSE TTInclusionExclusionOfCostVAT.Cost * (CAST(UnfinishedProductionByProduct.Count / DisposalSummary.Count AS NUMBER(31, 10))) * (CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31, 10)))
		|	END AS InclusionExclusionOfVATInCost
		|INTO NodulationResultsPreliminary
		|FROM
		|	DisposalOfUnfinishedProductionByProduct AS UnfinishedProductionByProduct
		|		INNER JOIN PreliminaryConsumptionOfBatches AS BatchesOfMaterials
		|		ON UnfinishedProductionByProduct.Period = BatchesOfMaterials.Period
		|			AND UnfinishedProductionByProduct.ItemsLocationAttributes = BatchesOfMaterials.CorItemsLocationAttributes
		|			AND UnfinishedProductionByProduct.Lot = BatchesOfMaterials.CorLot
		|			AND UnfinishedProductionByProduct.NodeID = BatchesOfMaterials.NodeID
		|
		|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS DimensionCosts_
		|		ON UnfinishedProductionByProduct.ItemsLocationAttributes = DimensionCosts_.DimensionKey
		|		LEFT JOIN DisposalFromUnfinishedProduction AS DisposalSummary
		|		ON UnfinishedProductionByProduct.Period = DisposalSummary.Period
		|			AND UnfinishedProductionByProduct.ItemsLocationAttributes = DisposalSummary.ItemsLocationAttributes
		|			AND UnfinishedProductionByProduct.Lot = DisposalSummary.Lot
		|			AND UnfinishedProductionByProduct.NodeID = DisposalSummary.NodeID
		|
		|		LEFT JOIN BatchesOfSemiFinishedProducts AS BatchesOfSemiFinishedProducts
		|		ON BatchesOfMaterials.Lot = BatchesOfSemiFinishedProducts.Lot
		|			AND BatchesOfMaterials.LotVendorAttributes = BatchesOfSemiFinishedProducts.LotVendorAttributes
		|			AND BatchesOfMaterials.ItemsLocationAttributes = BatchesOfSemiFinishedProducts.ItemsLocationAttributes
		|			AND (NOT UnfinishedProductionByProduct.ProductsBatch = BatchesOfSemiFinishedProducts.Lot
		|				OR NOT UnfinishedProductionByProduct.ProductBatchAccountingDimension = BatchesOfSemiFinishedProducts.LotVendorAttributes
		|				OR NOT UnfinishedProductionByProduct.ProductsAccountingDimension = BatchesOfSemiFinishedProducts.ItemsLocationAttributes)
		|			AND UnfinishedProductionByProduct.NodeID = BatchesOfSemiFinishedProducts.NodeID
		|
		// Adding branches of the parent company, branches with the same parent company, and the parent company of the branch.
		|		LEFT JOIN TTInterconnectedCompanies AS TTInterconnectedCompanies
		|		ON BatchesOfSemiFinishedProducts.Organization = TTInterconnectedCompanies.Organization1
		|			AND UnfinishedProductionByProduct.Organization = TTInterconnectedCompanies.Organization2
		|
		|		LEFT JOIN TTInclusionExclusionOfCostVAT AS TTInclusionExclusionOfCostVAT
		|		ON UnfinishedProductionByProduct.ItemsLocationAttributes = TTInclusionExclusionOfCostVAT.ItemsLocationAttributes
		|			AND UnfinishedProductionByProduct.Lot = TTInclusionExclusionOfCostVAT.Lot
		|			AND UnfinishedProductionByProduct.NodeID = TTInclusionExclusionOfCostVAT.NodeID
		|";
	
	MergeRequestTexts.Add(TextMaterialCostsAssociation);
	#EndRegion	
	
	#Region TextMaterialsInitialRemnantsOfUnfinishedProductionAssociation
	TextMaterialsInitialRemnantsOfUnfinishedProductionAssociation = "
		|SELECT
		|	UnfinishedProductionByProduct.NodeID AS NodeID,
		|	UnfinishedProductionByProduct.IdOfFirstLevelNode AS IdOfFirstLevelNode,
		|	UnfinishedProductionByProduct.NodeOfFirstLevel_AnalyticsOfManufacturedProductAccounting AS NodeOfFirstLevel_AnalyticsOfManufacturedProductAccounting,
		|	UnfinishedProductionByProduct.NodeOfFirstLevel_LotReferenceOfManufacturedProducts AS NodeOfFirstLevel_LotReferenceOfManufacturedProducts,
		|	UnfinishedProductionByProduct.NodeOfFirstLevelIs_BatchAccountingAnalysisOfManufacturedProductsLotsVendorAttributes AS NodeOfFirstLevelIs_BatchAccountingAnalysisOfManufacturedProductsLotsVendorAttributes,
		|	UnfinishedProductionByProduct.OriginalBatchDate AS OriginalBatchDate,
		|	UnfinishedProductionByProduct.DeployAdditionalCosts AS DeployAdditionalCosts,
		|	UnfinishedProductionByProduct.SourceNodeNeedsToBeDisconnected AS SourceNodeNeedsToBeDisconnected,
		|
		|	DATETIME(1, 1, 1)									AS MonthOfPrimaryLotReferenceVNZP,
		|
		|	UnfinishedProductionByProduct.Organization							AS Organization,
		|	UnfinishedProductionByProduct.ProductsBatch						AS BatchFinishedProduct,
		|	UnfinishedProductionByProduct.ProductBatchAccountingDimension		AS BatchAccountingDimensionFinishedProduct,
		|	UnfinishedProductionByProduct.ExpenseAccountingAnalytics					AS AccountingDimensionFinishedProduct,
		|	UnfinishedProductionByProduct.Lot								AS BatchCost,
		|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS BatchAccountingDimensionCost,
		|	FALSE												AS IncludePersonalIncomeTaxCost,
		|	FALSE												AS ExcludeVATFromCost,
		|	UnfinishedProductionByProduct.ItemsLocationAttributes			AS CostAccountingDimension,
		|	DimensionCosts_.Products						AS Cost_,
		|	DimensionCosts_.Products.UnitOfMeasure 		AS UnitOfMeasurementCost,
		|	DimensionCosts_.Characteristic						AS CostCharacteristics,
		|	DimensionCosts_.Series								AS CostSeries,
		|	DimensionCosts_.Purpose							AS DestinationCost,
		|	DimensionCosts_.ProductCostElement					AS ProductCostElement,
		|	DimensionCosts_.StorageLocation                       AS Department,
		|	FALSE												AS ExplosionIsRequired,
		|	FALSE												AS ItIsRequiredToUnpackAdditionalExpenseAmount,
		|	&TypeOfCostsMaterial								AS ExpenseType,
		|	UnfinishedProductionByProduct.Count
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS CostQuantity,
		|
		// The cost according to the parameter ""Data of the cost""
		|	UnfinishedProductionByProduct.Material_
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS Material_,
		|	UnfinishedProductionByProduct.LaborCosts
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS LaborCosts,
		|	UnfinishedProductionByProduct.ItemizedFixed
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS ItemizedFixed,
		|	UnfinishedProductionByProduct.ItemizedVariable
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS ItemizedVariable,
		|	UnfinishedProductionByProduct.AddExpensesForGoods
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS AddExpensesForGoods,
		|	UnfinishedProductionByProduct.OffBalanceSheetCostAmount
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS OffBalanceSheetCostAmount,
		|	UnfinishedProductionByProduct.CostAmount
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS CostAmount,
		|	UnfinishedProductionByProduct.AIT
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS AIT,
		|
		// Costs with VAT
		|	UnfinishedProductionByProduct.TangibleIncludingVAT
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS TangibleIncludingVAT,
		|	UnfinishedProductionByProduct.LaborCostsIncludingVAT
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS LaborCostsIncludingVAT,
		|	UnfinishedProductionByProduct.ItemizedFixedCostsIncludingVAT
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS ItemizedFixedCostsIncludingVAT,
		|	UnfinishedProductionByProduct.ItemizedVariableCostsIncludingVAT
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS ItemizedVariableCostsIncludingVAT,
		|	UnfinishedProductionByProduct.AdditionalExpensesIncludingVAT
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS AdditionalExpensesIncludingVAT,
		|
		// Costs without VAT
		|	UnfinishedProductionByProduct.TangibleExcludingVAT
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS TangibleExcludingVAT,
		|	UnfinishedProductionByProduct.ItemizedFixedCostsExcludingVAT
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS ItemizedFixedCostsExcludingVAT,
		|	UnfinishedProductionByProduct.ItemizedVariableCostsExcludingVAT
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS ItemizedVariableCostsExcludingVAT,
		|	UnfinishedProductionByProduct.AdditionalExpensesExcludingVAT
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS AdditionalExpensesExcludingVAT,
		|
		// The Cost of Upr
		|	UnfinishedProductionByProduct.MaterialMan
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS MaterialMan,
		|	UnfinishedProductionByProduct.LaborCostsMan
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS LaborCostsMan,
		|	UnfinishedProductionByProduct.ItemizedFixedCostsManag
		|		* CAST(UnfinishedProductionByProduct.Numerator	/ UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS ItemizedFixedCostsManag,
		|	UnfinishedProductionByProduct.ItemizedVariableCostsManag
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS ItemizedVariableCostsManag,
		|	UnfinishedProductionByProduct.AddExpensesMan
		|		* CAST(UnfinishedProductionByProduct.Numerator	/ UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS AddExpensesMan,
		|	UnfinishedProductionByProduct.CostOffBalanceSheetMan
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS CostOffBalanceSheetMan,
		|
		// Regl Costs
		|	UnfinishedProductionByProduct.TangibleCompl
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS TangibleCompl,
		|	UnfinishedProductionByProduct.LaborCostsLocal
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS LaborCostsLocal,
		|	UnfinishedProductionByProduct.ItemizedFixedCostsCompl
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS ItemizedFixedCostsCompl,
		|	UnfinishedProductionByProduct.ItemizedVariableCostsCompl
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS ItemizedVariableCostsCompl,
		|	UnfinishedProductionByProduct.AddExpensesLocal
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS AddExpensesLocal,
		|	UnfinishedProductionByProduct.OffBalanceCostLocal
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS OffBalanceCostLocal,
		|
		// Tax accounting
		|	UnfinishedProductionByProduct.TaxAccounting
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS TaxAccounting,
		|	UnfinishedProductionByProduct.PermanentDifference
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS PermanentDifference,
		|	UnfinishedProductionByProduct.CostTD
		|		* CAST(UnfinishedProductionByProduct.Numerator / UnfinishedProductionByProduct.Denominator AS NUMBER(31,10)) AS CostTD,
		|
		// Inclusion exclusion of VAT in the cost
		|	0 AS InclusionExclusionOfVATInCost
		|
		|FROM
		|	DisposalOfUnfinishedProductionByProduct AS UnfinishedProductionByProduct
		|		LEFT JOIN PreliminaryConsumptionOfBatches AS BatchesOfMaterials
		|	    ON UnfinishedProductionByProduct.Period = BatchesOfMaterials.Period
		|			AND UnfinishedProductionByProduct.ItemsLocationAttributes = BatchesOfMaterials.CorItemsLocationAttributes
		|			AND UnfinishedProductionByProduct.Lot = BatchesOfMaterials.CorLot
		|			AND UnfinishedProductionByProduct.NodeID = BatchesOfMaterials.NodeID
		|
		|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS DimensionCosts_
		|		ON UnfinishedProductionByProduct.ItemsLocationAttributes = DimensionCosts_.DimensionKey
		|WHERE
		|	BatchesOfMaterials.Lot IS NULL
		|";
	
	MergeRequestTexts.Add(TextMaterialsInitialRemnantsOfUnfinishedProductionAssociation);
	
	#EndRegion
	
	#Region TextLaborCostsAssociation
	TextLaborCostsAssociation = "
		|SELECT
		|	IssuedProducts.NodeID AS NodeID,
		|	IssuedProducts.IdOfFirstLevelNode AS IdOfFirstLevelNode,
		|	IssuedProducts.NodeOfFirstLevel_AnalyticsOfManufacturedProductAccounting AS NodeOfFirstLevel_AnalyticsOfManufacturedProductAccounting,
		|	IssuedProducts.NodeOfFirstLevel_LotReferenceOfManufacturedProducts AS NodeOfFirstLevel_LotReferenceOfManufacturedProducts,
		|	IssuedProducts.NodeOfFirstLevelIs_BatchAccountingAnalysisOfManufacturedProductsLotsVendorAttributes AS NodeOfFirstLevelIs_BatchAccountingAnalysisOfManufacturedProductsLotsVendorAttributes,
		|	IssuedProducts.OriginalBatchDate AS OriginalBatchDate,
		|	IssuedProducts.DeployAdditionalCosts AS DeployAdditionalCosts,
		|	IssuedProducts.SourceNodeNeedsToBeDisconnected AS SourceNodeNeedsToBeDisconnected,
		|
		|	DATETIME(1, 1, 1)								AS MonthOfPrimaryLotReferenceVNZP,
		|
		|	LaborCostsOfUnfinishedProduction.Organization						AS Organization,
		|	LaborCostsOfUnfinishedProduction.Recorder						AS BatchFinishedProduct,
		|	LaborCostsOfUnfinishedProduction.LotVendorAttributesCorr			AS BatchAccountingDimensionFinishedProduct,
		|	IssuedProducts.ExpenseAccountingAnalytics		AS AccountingDimensionFinishedProduct,
		|	UNDEFINED									AS BatchCost,
		|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS BatchAccountingDimensionCost,
		|	FALSE											AS IncludePersonalIncomeTaxCost,
		|	FALSE											AS ExcludeVATFromCost,
		|	LaborCostsOfUnfinishedProduction.WorkKind						AS DimensionCost_,
		|	LaborCostsOfUnfinishedProduction.WorkKind						AS Cost_,
		|	CatActivityKinds.UnitOfMeasure					AS UnitOfMeasurementCost,
		|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS CostCharacteristics,
		|	VALUE(Catalog.ItemsBatches.EmptyRef) AS CostSeries,
		|	VALUE(Catalog.Assignments.EmptyRef) AS DestinationCost,
		|	LaborCostsOfUnfinishedProduction.ProductCostElement				AS ProductCostElement,
		|	LaborCostsOfUnfinishedProduction.Department					AS Department,
		|	FALSE											AS ExplosionIsRequired,
		|	FALSE											AS ItIsRequiredToUnpackAdditionalExpenseAmount,
		|	&CostTypeLaborCosts							AS ExpenseType,
		|	CAST(LaborCostsOfUnfinishedProduction.Count 
		|		* IssuedProducts.Numerator / IssuedProducts.Denominator AS NUMBER(31,10)) AS CostQuantity,
		|
		// The cost according to the parameter ""Data of the cost""
		|	0												AS Material_,
		|	CAST(LaborCostsOfUnfinishedProduction.Cost 
		|		* IssuedProducts.Numerator / IssuedProducts.Denominator AS NUMBER(31,10)) AS LaborCosts,
		|	0												AS ItemizedFixed,
		|	0												AS ItemizedVariable,
		|	0												AS AddExpensesForGoods,
		|	0												AS OffBalanceSheetCostAmount,
		|	CAST(LaborCostsOfUnfinishedProduction.Cost
		|		* IssuedProducts.Numerator / IssuedProducts.Denominator AS NUMBER(31,10)) AS CostAmount,
		|	CAST(LaborCostsOfUnfinishedProduction.CostOfPersonalIncomeTax 
		|		* IssuedProducts.Numerator / IssuedProducts.Denominator AS NUMBER(31,10)) AS AIT,
		|
		// Costs with VAT
		|	0												AS TangibleIncludingVAT,
		|	CAST(LaborCostsOfUnfinishedProduction.Cost
		|		* IssuedProducts.Numerator / IssuedProducts.Denominator AS NUMBER(31,10)) AS LaborCostsIncludingVAT,
		|	0												AS ItemizedFixedCostsIncludingVAT,
		|	0												AS ItemizedVariableCostsIncludingVAT,
		|	0												AS AdditionalExpensesIncludingVAT,
		|
		// Costs without VAT
		|	0												AS TangibleExcludingVAT,
		|	0												AS ItemizedFixedCostsExcludingVAT,
		|	0												AS ItemizedVariableCostsExcludingVAT,
		|	0												AS AdditionalExpensesExcludingVAT,
		|
		// The Cost of Upr
		|	0												AS MaterialMan,
		|	CAST(LaborCostsOfUnfinishedProduction.Cost
		|		* IssuedProducts.Numerator / IssuedProducts.Denominator AS NUMBER(31,10)) AS LaborCostsMan,
		|	0												AS ItemizedFixedCostsManag,
		|	0												AS ItemizedVariableCostsManag,
		|	0												AS AddExpensesMan,
		|	0												AS CostOffBalanceSheetMan,
		|
		// Regl Costs
		|	0												AS TangibleCompl,
		|	CAST(LaborCostsOfUnfinishedProduction.LocalCost
		|		* IssuedProducts.Numerator / IssuedProducts.Denominator AS NUMBER(31,10)) AS LaborCostsLocal,
		|	0												AS ItemizedFixedCostsCompl,
		|	0												AS ItemizedVariableCostsCompl,
		|	0												AS AddExpensesLocal,
		|	0												AS OffBalanceCostLocal,
		|
		// Tax accounting
		|	CAST(LaborCostsOfUnfinishedProduction.TaxAccounting 
		|		* IssuedProducts.Numerator / IssuedProducts.Denominator AS NUMBER(31,10)) AS TaxAccounting,
		|	CAST(LaborCostsOfUnfinishedProduction.PermanentDifference
		|		* IssuedProducts.Numerator / IssuedProducts.Denominator AS NUMBER(31,10)) AS PermanentDifference,
		|	CAST(LaborCostsOfUnfinishedProduction.CostTD
		|		* IssuedProducts.Numerator / IssuedProducts.Denominator AS NUMBER(31,10)) AS CostTD,
		|		
		// Inclusion exclusion of VAT in the cost
		|	0 AS InclusionExclusionOfVATInCost
		|
		|FROM
		|	IssuedProducts AS IssuedProducts
		|
		|		INNER JOIN TTWIPLaborCostsOfWorkInProgress AS LaborCostsOfUnfinishedProduction
		|		ON LaborCostsOfUnfinishedProduction.Organization = IssuedProducts.Organization
		|			AND IssuedProducts.ProductsBatch = LaborCostsOfUnfinishedProduction.Recorder
		|			AND IssuedProducts.ProductBatchAccountingDimension = LaborCostsOfUnfinishedProduction.LotVendorAttributesCorr
		|			AND IssuedProducts.ProductsAccountingDimension = LaborCostsOfUnfinishedProduction.CorDimensionOfProductsAccounting

		|		LEFT JOIN Catalog.EmployeeWorkKinds AS CatActivityKinds
		|		ON CatActivityKinds.Ref = LaborCostsOfUnfinishedProduction.WorkKind
		|
		|";
	
	MergeRequestTexts.Add(TextLaborCostsAssociation);
	
	#EndRegion
	
	#Region TextOtherExpensesConsolidation
	TextOtherExpensesConsolidation = "
		|SELECT
		|	IssuedProducts.NodeID AS NodeID,
		|	IssuedProducts.IdOfFirstLevelNode AS IdOfFirstLevelNode,
		|	IssuedProducts.NodeOfFirstLevel_AnalyticsOfManufacturedProductAccounting AS NodeOfFirstLevel_AnalyticsOfManufacturedProductAccounting,
		|	IssuedProducts.NodeOfFirstLevel_LotReferenceOfManufacturedProducts AS NodeOfFirstLevel_LotReferenceOfManufacturedProducts,
		|	IssuedProducts.NodeOfFirstLevelIs_BatchAccountingAnalysisOfManufacturedProductsLotsVendorAttributes AS NodeOfFirstLevelIs_BatchAccountingAnalysisOfManufacturedProductsLotsVendorAttributes,
		|	MAX(IssuedProducts.OriginalBatchDate) AS OriginalBatchDate,
		|	MAX(IssuedProducts.DeployAdditionalCosts) AS DeployAdditionalCosts,
		|	MAX(IssuedProducts.SourceNodeNeedsToBeDisconnected) AS SourceNodeNeedsToBeDisconnected,
		|
		|	DATETIME(1, 1, 1)							AS MonthOfPrimaryLotReferenceVNZP,
		|
		|	OtherExpensesOfUnfinishedProduction.Organization				AS Organization,
		|	OtherExpensesOfUnfinishedProduction.Recorder				AS BatchFinishedProduct,
		|	OtherExpensesOfUnfinishedProduction.LotVendorAttributesCorr	AS BatchAccountingDimensionFinishedProduct,
		|	IssuedProducts.ExpenseAccountingAnalytics	AS AccountingDimensionFinishedProduct,
		|	UNDEFINED								AS BatchCost,
		|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS BatchAccountingDimensionCost,
		|	FALSE										AS IncludePersonalIncomeTaxCost,
		|	FALSE										AS ExcludeVATFromCost,
		|	OtherExpensesOfUnfinishedProduction.ExpenseItem				AS DimensionCost_,
		|	OtherExpensesOfUnfinishedProduction.ExpenseItem				AS Cost_,
		|	UNDEFINED								AS UnitOfMeasurementCost,
		|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS CostCharacteristics,
		|	VALUE(Catalog.ItemsBatches.EmptyRef) AS CostSeries,
		|	VALUE(Catalog.Assignments.EmptyRef) AS DestinationCost,
		|	OtherExpensesOfUnfinishedProduction.ProductCostElement			AS ProductCostElement,
		|	OtherExpensesOfUnfinishedProduction.Department				AS Department,
		|	FALSE										AS ExplosionIsRequired,
		|	FALSE										AS ItIsRequiredToUnpackAdditionalExpenseAmount,
		|	&TypeOfCostsArticleByArticle						AS ExpenseType,
		|	0											AS CostQuantity,
		|
		// The cost according to the parameter ""Data of the cost""
		|	0											AS Material_,
		|	0											AS LaborCosts,
		|	CAST(SUM(OtherExpensesOfUnfinishedProduction.ItemizedFixed * IssuedProducts.Numerator / IssuedProducts.Denominator) AS NUMBER(31,10)) AS ItemizedFixed,
		|	CAST(SUM(OtherExpensesOfUnfinishedProduction.ItemizedVariable * IssuedProducts.Numerator / IssuedProducts.Denominator) AS NUMBER(31,10)) AS ItemizedVariable,
		|	0											AS AddExpensesForGoods,
		|	0											AS OffBalanceSheetCostAmount,
		|	CAST(SUM(OtherExpensesOfUnfinishedProduction.CostAmount * IssuedProducts.Numerator / IssuedProducts.Denominator) AS NUMBER(31,10)) AS CostAmount,
		|	CAST(SUM(OtherExpensesOfUnfinishedProduction.AIT * IssuedProducts.Numerator / IssuedProducts.Denominator) AS NUMBER(31,10)) AS AIT,
		|
		// Costs with VAT
		|	0											AS TangibleIncludingVAT,
		|	0											AS LaborCostsIncludingVAT,
		|	CAST(SUM(OtherExpensesOfUnfinishedProduction.ItemizedFixedCostsIncludingVAT * IssuedProducts.Numerator / IssuedProducts.Denominator) AS NUMBER(31,10)) AS ItemizedFixedCostsIncludingVAT,
		|	CAST(SUM(OtherExpensesOfUnfinishedProduction.ItemizedVariableCostsIncludingVAT * IssuedProducts.Numerator / IssuedProducts.Denominator) AS NUMBER(31,10)) AS ItemizedVariableCostsIncludingVAT,
		|	0											AS AdditionalExpensesIncludingVAT,
		|
		// Costs without VAT
		|	0											AS TangibleExcludingVAT,
		|	CAST(SUM(OtherExpensesOfUnfinishedProduction.ItemizedFixedCostsExcludingVAT * IssuedProducts.Numerator / IssuedProducts.Denominator) AS NUMBER(31,10)) AS ItemizedFixedCostsExcludingVAT,
		|	CAST(SUM(OtherExpensesOfUnfinishedProduction.ItemizedVariableCostsExcludingVAT * IssuedProducts.Numerator / IssuedProducts.Denominator) AS NUMBER(31,10)) AS ItemizedVariableCostsExcludingVAT,
		|	0											AS AdditionalExpensesExcludingVAT,
		|
		// The Cost of Upr
		|	0											AS MaterialMan,
		|	0											AS LaborCostsMan,
		|	CAST(SUM(OtherExpensesOfUnfinishedProduction.ItemizedFixedCostsManag * IssuedProducts.Numerator / IssuedProducts.Denominator) AS NUMBER(31,10)) AS ItemizedFixedCostsManag,
		|	CAST(SUM(OtherExpensesOfUnfinishedProduction.ItemizedVariableCostsManag * IssuedProducts.Numerator / IssuedProducts.Denominator) AS NUMBER(31,10)) AS ItemizedVariableCostsManag,
		|	0											AS AddExpensesMan,
		|	0											AS CostOffBalanceSheetMan,
		|
		// Regl Costs
		|	0											AS TangibleCompl,
		|	0											AS LaborCostsLocal,
		|	CAST(SUM(OtherExpensesOfUnfinishedProduction.ItemizedFixedCostsCompl * IssuedProducts.Numerator / IssuedProducts.Denominator) AS NUMBER(31,10)) AS ItemizedFixedCostsCompl,
		|	CAST(SUM(OtherExpensesOfUnfinishedProduction.ItemizedVariableCostsCompl * IssuedProducts.Numerator / IssuedProducts.Denominator) AS NUMBER(31,10)) AS ItemizedVariableCostsCompl,
		|	0											AS AddExpensesLocal,
		|	0											AS OffBalanceCostLocal,
		|
		// Tax accounting
		|	CAST(SUM(OtherExpensesOfUnfinishedProduction.TaxAccounting * IssuedProducts.Numerator / IssuedProducts.Denominator) AS NUMBER(31,10)) AS TaxAccounting,
		|	CAST(SUM(OtherExpensesOfUnfinishedProduction.PermanentDifference * IssuedProducts.Numerator / IssuedProducts.Denominator) AS NUMBER(31,10)) AS PermanentDifference,
		|	CAST(SUM(OtherExpensesOfUnfinishedProduction.CostTD * IssuedProducts.Numerator / IssuedProducts.Denominator) AS NUMBER(31,10)) AS CostTD,
		|
		// Inclusion exclusion of VAT in the cost
		|	0 AS InclusionExclusionOfVATInCost
		|
		|FROM
		|	IssuedProducts AS IssuedProducts
		|		INNER JOIN TTOtherWorkInProgressExpenses__ AS OtherExpensesOfUnfinishedProduction
		|		ON IssuedProducts.Organization = OtherExpensesOfUnfinishedProduction.Organization
		|			AND IssuedProducts.ProductsBatch = OtherExpensesOfUnfinishedProduction.Recorder
		|			AND IssuedProducts.ProductBatchAccountingDimension = OtherExpensesOfUnfinishedProduction.LotVendorAttributesCorr
		|			AND IssuedProducts.ProductsAccountingDimension = OtherExpensesOfUnfinishedProduction.ProductsAccountingDimension
		|
		|GROUP BY
		|	OtherExpensesOfUnfinishedProduction.Organization,
		|	OtherExpensesOfUnfinishedProduction.Recorder,
		|	OtherExpensesOfUnfinishedProduction.LotVendorAttributesCorr,
		|	OtherExpensesOfUnfinishedProduction.ExpenseItem,
		|	OtherExpensesOfUnfinishedProduction.ProductCostElement,
		|	OtherExpensesOfUnfinishedProduction.Department,
		|
		|	IssuedProducts.NodeID,
		|	IssuedProducts.IdOfFirstLevelNode,
		|	IssuedProducts.ExpenseAccountingAnalytics,
		|	IssuedProducts.NodeOfFirstLevel_AnalyticsOfManufacturedProductAccounting,
		|	IssuedProducts.NodeOfFirstLevel_LotReferenceOfManufacturedProducts,
		|	IssuedProducts.NodeOfFirstLevelIs_BatchAccountingAnalysisOfManufacturedProductsLotsVendorAttributes
		|";
	
	If Not TreeParameters.ResultTypeValueTree Then
		// Comment 3970.
		// Filling in the columns below is necessary only if a tree
		// is formed or if
		// a tree is required or if a tree is required, no data separation is required in this request.
		RemoveNodeId(TextOtherExpensesConsolidation, "IssuedProducts");
	EndIf;
	MergeRequestTexts.Add(TextOtherExpensesConsolidation);
	
	#EndRegion
	
	#Region TextOfAdditionalCostsAssociation
	
	If DeductAdditionalExpenses Then
			
		TextOfAdditionalCostsAssociation = "
			|SELECT
			|	NodeSelectionTable.NodeID AS NodeID,
			|	NodeSelectionTable.IdOfFirstLevelNode AS IdOfFirstLevelNode,
			|	NodeSelectionTable.NodeOfFirstLevel_AnalyticsOfManufacturedProductAccounting AS NodeOfFirstLevel_AnalyticsOfManufacturedProductAccounting,
			|	NodeSelectionTable.NodeOfFirstLevel_LotReferenceOfManufacturedProducts AS NodeOfFirstLevel_LotReferenceOfManufacturedProducts,
			|	NodeSelectionTable.NodeOfFirstLevelIs_BatchAccountingAnalysisOfManufacturedProductsLotsVendorAttributes AS NodeOfFirstLevelIs_BatchAccountingAnalysisOfManufacturedProductsLotsVendorAttributes,
			|	MAX(NodeSelectionTable.OriginalBatchDate) AS OriginalBatchDate,
			|	MAX(NodeSelectionTable.DeployAdditionalCosts) AS DeployAdditionalCosts,
			|	MAX(NodeSelectionTable.ExplosionIsRequired) AS SourceNodeNeedsToBeDisconnected,
			|
			|	DATETIME(1, 1, 1)						AS MonthOfPrimaryLotReferenceVNZP,
			|
			|	CostDetails.Organization							AS Organization,
			|	CostDetails.Lot									AS BatchFinishedProduct,
			|	CostDetails.LotVendorAttributes					AS BatchAccountingDimensionFinishedProduct,
			|	NodeSelectionTable.ExpenseAccountingAnalytics						AS AccountingDimensionFinishedProduct,
			|	CostDetails.DocumentInflow AS BatchCost,
			|	CostDetails.LotVendorAttributesOfReceiptDocument AS BatchAccountingDimensionCost,
			|	FALSE										AS IncludePersonalIncomeTaxCost,
			|	FALSE										AS ExcludeVATFromCost,
			|	CostDetails.DimensionOfExpenses	AS DimensionCost_,
			|	CASE
			|		WHEN CostDetails.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
			|			THEN ISNULL(CostDetails.LotVendorAttributesOfReceiptDocument.AssetTaxClass, VALUE(Enum.AssetKinds.EmptyRef))
			|		ELSE CostDetails.ExpenseItem
			|	END AS Cost_,
			|	UNDEFINED								AS UnitOfMeasurementCost,
			|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS CostCharacteristics,
			|	VALUE(Catalog.ItemsBatches.EmptyRef) AS CostSeries,
			|	VALUE(Catalog.Assignments.EmptyRef) AS DestinationCost,
			|	NodeSelectionTable.ProductCostElement		AS ProductCostElement,
			|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
			|	FALSE										AS ExplosionIsRequired,
			|	FALSE										AS ItIsRequiredToUnpackAdditionalExpenseAmount,
			|	&TypeOfCostsAdditionalExpensesAmount						AS ExpenseType,
			|	0											AS CostQuantity,
			|
			// The cost according to the parameter ""Data of the cost""
			|	0											AS Material_,
			|	0											AS LaborCosts,
			|	0											AS ItemizedFixed,
			|	0											AS ItemizedVariable,
			|	SUM(CASE
			|		WHEN &Cost_Data = 1
			|			THEN CostDetails.CostInclVAT
			|		WHEN &Cost_Data = 2
			|			THEN CostDetails.CostExcludingVAT
			|		WHEN &Cost_Data = 3
			|			THEN CostDetails.CostExcludingVATMan
			|			+ (CASE WHEN NodeSelectionTable.IncludePersonalIncomeTaxCost
			|				THEN CostDetails.VATManag ELSE 0 END)
			|		WHEN &Cost_Data = 4
			|			THEN CostDetails.CostExcludingVATLocal
			|			+ (CASE WHEN NodeSelectionTable.IncludePersonalIncomeTaxCost
			|				THEN CostDetails.VATLocal ELSE 0 END)
			|	END * NodeSelectionTable.ProductsQuantity) AS AddExpensesForGoods,
			|	0											AS OffBalanceSheetCostAmount,
			|	SUM(CASE
			|		WHEN &Cost_Data = 1
			|			THEN CostDetails.CostInclVAT
			|		WHEN &Cost_Data = 2
			|			THEN CostDetails.CostExcludingVAT
			|		WHEN &Cost_Data = 3
			|			THEN CostDetails.CostExcludingVATMan
			|			+ (CASE WHEN NodeSelectionTable.IncludePersonalIncomeTaxCost
			|				THEN CostDetails.VATManag ELSE 0 END)
			|		WHEN &Cost_Data = 4
			|			THEN CostDetails.CostExcludingVATLocal
			|			+ (CASE WHEN NodeSelectionTable.IncludePersonalIncomeTaxCost
			|				THEN CostDetails.VATLocal ELSE 0 END)
			|	END * NodeSelectionTable.ProductsQuantity) AS CostAmount,
			|	0											AS AIT,
			|
			// Costs with VAT
			|	0											AS TangibleIncludingVAT,
			|	0											AS LaborCostsIncludingVAT,
			|	0											AS ItemizedFixedCostsIncludingVAT,
			|	0											AS ItemizedVariableCostsIncludingVAT,
			|	SUM(CostDetails.CostInclVAT
			|			* NodeSelectionTable.ProductsQuantity) AS AdditionalExpensesIncludingVAT,
			|
			// Costs without VAT
			|	0											AS TangibleExcludingVAT,
			|	0											AS ItemizedFixedCostsExcludingVAT,
			|	0											AS ItemizedVariableCostsExcludingVAT,
			|	SUM(CostDetails.CostExcludingVAT
			|			* NodeSelectionTable.ProductsQuantity) AS AdditionalExpensesExcludingVAT,
			|
			// The Cost of Upr
			|	0											AS MaterialMan,
			|	0											AS LaborCostsMan,
			|	0											AS ItemizedFixedCostsManag,
			|	0											AS ItemizedVariableCostsManag,
			|	SUM((CostDetails.CostExcludingVATMan
			|			+ (CASE WHEN NodeSelectionTable.IncludePersonalIncomeTaxCost 
			|				THEN CostDetails.VATManag ELSE 0 END))
			|			* NodeSelectionTable.ProductsQuantity) AS AddExpensesMan,
			|	0											AS CostOffBalanceSheetMan,
			|
			// Regl Costs
			|	0											AS TangibleCompl,
			|	0											AS LaborCostsLocal,
			|	0											AS ItemizedFixedCostsCompl,
			|	0											AS ItemizedVariableCostsCompl,
			|	SUM((CostDetails.CostExcludingVATLocal 
			|			+ (CASE WHEN NodeSelectionTable.IncludePersonalIncomeTaxCost
			|				THEN CostDetails.VATLocal ELSE 0 END))
			|			* NodeSelectionTable.ProductsQuantity) AS AddExpensesLocal,
			|	0											AS OffBalanceCostLocal,
			|
			// Tax accounting
			|	0 AS TaxAccounting,
			|	0 AS PermanentDifference,
			|	0 AS CostTD,
			|
			// Inclusion exclusion of VAT in the cost
			|	0 AS InclusionExclusionOfVATInCost
			|
			|FROM
			|	NodeSelectionTable AS NodeSelectionTable
			|		INNER JOIN InformationRegister.ItemizeLotCostItemizedAndOtherCosts AS CostDetails
			|		ON CostDetails.Lot = NodeSelectionTable.ProductsBatch
			|			AND CostDetails.LotVendorAttributes = NodeSelectionTable.ProductBatchAccountingDimension
			|			AND CostDetails.Products = NodeSelectionTable.ManufacturedProduct
			|			AND CostDetails.Characteristic = NodeSelectionTable.ItemVariant
			|WHERE
			|	ISNULL(CostDetails.InventoryOwnerAttribute.InventoryType, UNDEFINED) <> VALUE(Enum.InventoryTypes.OwnGoodsInTransit)
			|	AND NOT CostDetails.PreviousRedistributionCosts
			|	AND NOT CASE
			|			WHEN &Cost_Data = 1
			|				THEN CostDetails.CostInclVAT
			|			WHEN &Cost_Data = 2
			|				THEN CostDetails.CostExcludingVAT
			|			WHEN &Cost_Data = 3
			|				THEN CostDetails.CostExcludingVATMan
			|			WHEN &Cost_Data = 4
			|				THEN CostDetails.CostExcludingVATLocal
			|		END = 0
			|	AND CASE
			|		WHEN CostDetails.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
			|			THEN TRUE	
			|		WHEN &Cost_Data = 4
			|			THEN CostDetails.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
			|		ELSE CostDetails.ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
			|	END 
			|
			|GROUP BY
			|	NodeSelectionTable.ExpenseAccountingAnalytics,
			|	NodeSelectionTable.ProductCostElement,
			|
			|	CostDetails.Organization,
			|	CostDetails.Lot,
			|	CostDetails.LotVendorAttributes,
			|	CostDetails.DocumentInflow,
			|	CostDetails.LotVendorAttributesOfReceiptDocument,
			|	CostDetails.DimensionOfExpenses,
			|	CASE
			|		WHEN CostDetails.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
			|			THEN ISNULL(CostDetails.LotVendorAttributesOfReceiptDocument.AssetTaxClass, VALUE(Enum.AssetKinds.EmptyRef))
			|		ELSE CostDetails.ExpenseItem
			|	END,
			|
			|	NodeSelectionTable.NodeID,
			|	NodeSelectionTable.IdOfFirstLevelNode,
			|	NodeSelectionTable.NodeOfFirstLevel_AnalyticsOfManufacturedProductAccounting,
			|	NodeSelectionTable.NodeOfFirstLevel_LotReferenceOfManufacturedProducts,
			|	NodeSelectionTable.NodeOfFirstLevelIs_BatchAccountingAnalysisOfManufacturedProductsLotsVendorAttributes
			|
			|UNION ALL
			|
			|SELECT
			|	NodeSelectionTable.NodeID AS NodeID,
			|	NodeSelectionTable.IdOfFirstLevelNode AS IdOfFirstLevelNode,
			|	NodeSelectionTable.NodeOfFirstLevel_AnalyticsOfManufacturedProductAccounting AS NodeOfFirstLevel_AnalyticsOfManufacturedProductAccounting,
			|	NodeSelectionTable.NodeOfFirstLevel_LotReferenceOfManufacturedProducts AS NodeOfFirstLevel_LotReferenceOfManufacturedProducts,
			|	NodeSelectionTable.NodeOfFirstLevelIs_BatchAccountingAnalysisOfManufacturedProductsLotsVendorAttributes AS NodeOfFirstLevelIs_BatchAccountingAnalysisOfManufacturedProductsLotsVendorAttributes,
			|	MAX(NodeSelectionTable.OriginalBatchDate) AS OriginalBatchDate,
			|	MAX(NodeSelectionTable.DeployAdditionalCosts) AS DeployAdditionalCosts,
			|	MAX(NodeSelectionTable.ExplosionIsRequired) AS SourceNodeNeedsToBeDisconnected,
			|
			|	DATETIME(1, 1, 1)						AS MonthOfPrimaryLotReferenceVNZP,
			|
			|	CostDetails.Organization							AS Organization,
			|	CostDetails.Lot									AS BatchFinishedProduct,
			|	CostDetails.LotVendorAttributes					AS BatchAccountingDimensionFinishedProduct,
			|	NodeSelectionTable.ExpenseAccountingAnalytics						AS AccountingDimensionFinishedProduct,
			|	CostDetails.DocumentInflow AS BatchCost,
			|	CostDetails.LotVendorAttributesOfReceiptDocument AS BatchAccountingDimensionCost,
			|	FALSE										AS IncludePersonalIncomeTaxCost,
			|	FALSE										AS ExcludeVATFromCost,
			|	CostDetails.DimensionOfExpenses	AS DimensionCost_,
			|	CASE
			|		WHEN CostDetails.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
			|			THEN ISNULL(CostDetails.LotVendorAttributesOfReceiptDocument.AssetTaxClass, VALUE(Enum.AssetKinds.EmptyRef))
			|		ELSE CostDetails.ExpenseItem
			|	END AS Cost_,
			|	UNDEFINED								AS UnitOfMeasurementCost,
			|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS CostCharacteristics,
			|	VALUE(Catalog.ItemsBatches.EmptyRef) AS CostSeries,
			|	VALUE(Catalog.Assignments.EmptyRef) AS DestinationCost,
			|	NodeSelectionTable.ProductCostElement		AS ProductCostElement,
			|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
			|	FALSE										AS ExplosionIsRequired,
			|	FALSE										AS ItIsRequiredToUnpackAdditionalExpenseAmount,
			|	&TypeOfCostsAdditionalExpensesAmount						AS ExpenseType,
			|	0											AS CostQuantity,
			|
			// The cost according to the parameter ""Data of the cost""
			|	0											AS Material_,
			|	0											AS LaborCosts,
			|	0											AS ItemizedFixed,
			|	0											AS ItemizedVariable,
			|	SUM(CASE
			|		WHEN &Cost_Data = 1
			|			THEN CostDetails.CostInclVAT
			|		WHEN &Cost_Data = 2
			|			THEN CostDetails.CostExcludingVAT
			|		WHEN &Cost_Data = 3
			|			THEN CostDetails.CostExcludingVATMan
			|			+ (CASE WHEN NodeSelectionTable.IncludePersonalIncomeTaxCost
			|				THEN CostDetails.VATManag ELSE 0 END)
			|		WHEN &Cost_Data = 4
			|			THEN CostDetails.CostExcludingVATLocal
			|			+ (CASE WHEN NodeSelectionTable.IncludePersonalIncomeTaxCost
			|				THEN CostDetails.VATLocal ELSE 0 END)
			|	END * NodeSelectionTable.ProductsQuantity)				AS AddExpensesForGoods,
			|	0											AS OffBalanceSheetCostAmount,
			|	SUM(CASE
			|		WHEN &Cost_Data = 1
			|			THEN CostDetails.CostInclVAT
			|		WHEN &Cost_Data = 2
			|			THEN CostDetails.CostExcludingVAT
			|		WHEN &Cost_Data = 3
			|			THEN CostDetails.CostExcludingVATMan
			|			+ (CASE WHEN NodeSelectionTable.IncludePersonalIncomeTaxCost
			|				THEN CostDetails.VATManag ELSE 0 END)
			|		WHEN &Cost_Data = 4
			|			THEN CostDetails.CostExcludingVATLocal
			|			+ (CASE WHEN NodeSelectionTable.IncludePersonalIncomeTaxCost
			|				THEN CostDetails.VATLocal ELSE 0 END)
			|	END * NodeSelectionTable.ProductsQuantity)				AS CostAmount,
			|	0											AS AIT,
			|
			// Costs with VAT
			|	0											AS TangibleIncludingVAT,
			|	0											AS LaborCostsIncludingVAT,
			|	0											AS ItemizedFixedCostsIncludingVAT,
			|	0											AS ItemizedVariableCostsIncludingVAT,
			|	SUM(CostDetails.CostInclVAT
			|			* NodeSelectionTable.ProductsQuantity) AS AdditionalExpensesIncludingVAT,
			|
			// Costs without VAT
			|	0											AS TangibleExcludingVAT,
			|	0											AS ItemizedFixedCostsExcludingVAT,
			|	0											AS ItemizedVariableCostsExcludingVAT,
			|	SUM(CostDetails.CostExcludingVAT
			|			* NodeSelectionTable.ProductsQuantity) AS AdditionalExpensesExcludingVAT,
			|
			// The Cost of Upr
			|	0											AS MaterialMan,
			|	0											AS LaborCostsMan,
			|	0											AS ItemizedFixedCostsManag,
			|	0											AS ItemizedVariableCostsManag,
			|	SUM((CostDetails.CostExcludingVATMan
			|			+ (CASE WHEN NodeSelectionTable.IncludePersonalIncomeTaxCost
			|				THEN CostDetails.VATManag ELSE 0 END))
			|			* NodeSelectionTable.ProductsQuantity) AS AddExpensesMan,
			|	0											AS CostOffBalanceSheetMan,
			|
			// Regl Costs
			|	0											AS TangibleCompl,
			|	0											AS LaborCostsLocal,
			|	0											AS ItemizedFixedCostsCompl,
			|	0											AS ItemizedVariableCostsCompl,
			|	SUM((CostDetails.CostExcludingVATLocal
			|			+ (CASE WHEN NodeSelectionTable.IncludePersonalIncomeTaxCost
			|				THEN CostDetails.VATLocal ELSE 0 END))
			|			* NodeSelectionTable.ProductsQuantity) AS AddExpensesLocal,
			|	0											AS OffBalanceCostLocal,
			|
			// Tax accounting
			|	0 AS TaxAccounting,
			|	0 AS PermanentDifference,
			|	0 AS CostTD,
			|
			// Inclusion exclusion of VAT in the cost
			|	0 AS InclusionExclusionOfVATInCost
			|FROM
			|	NodeSelectionTable AS NodeSelectionTable
			|		INNER JOIN InformationRegister.ItemizeGoodsCostItemizedAndOtherCosts AS CostDetails
			|		ON CostDetails.Period BETWEEN NodeSelectionTable.DateOfOriginalLotReference_BeginningOfMonth AND NodeSelectionTable.DateOfOriginalLotReference_EndOfMonth
			|			AND CostDetails.Lot = NodeSelectionTable.ProductsBatch
			|			AND CostDetails.LotVendorAttributes = NodeSelectionTable.ProductBatchAccountingDimension
			|			AND CostDetails.ItemsLocationAttributes = NodeSelectionTable.ExpenseAccountingAnalytics
			|WHERE
			|	CostDetails.AccountingSection IN (
			|		VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock),
			|		VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts))
			|	AND NOT CASE
			|			WHEN &Cost_Data = 1
			|				THEN CostDetails.CostInclVAT
			|			WHEN &Cost_Data = 2
			|				THEN CostDetails.CostExcludingVAT
			|			WHEN &Cost_Data = 3
			|				THEN CostDetails.CostExcludingVATMan
			|			WHEN &Cost_Data = 4
			|				THEN CostDetails.CostExcludingVATLocal
			|		END = 0
			|	AND CASE
			|		WHEN CostDetails.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
			|			THEN TRUE	
			|		WHEN &Cost_Data = 4
			|			THEN CostDetails.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
			|		ELSE CostDetails.ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
			|	END 
			|
			|GROUP BY
			|	NodeSelectionTable.ProductCostElement,
			|	NodeSelectionTable.ExpenseAccountingAnalytics,
			|
			|	CostDetails.Organization,
			|	CostDetails.Lot,
			|	CostDetails.ItemsLocationAttributes,
			|	CostDetails.LotVendorAttributes,
			|	CostDetails.DocumentInflow,
			|	CostDetails.LotVendorAttributesOfReceiptDocument,
			|	CostDetails.DimensionOfExpenses,
			|	CASE
			|		WHEN CostDetails.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
			|			THEN ISNULL(CostDetails.LotVendorAttributesOfReceiptDocument.AssetTaxClass, VALUE(Enum.AssetKinds.EmptyRef))
			|		ELSE CostDetails.ExpenseItem
			|	END,
			|
			|	NodeSelectionTable.NodeID,
			|	NodeSelectionTable.IdOfFirstLevelNode,
			|	NodeSelectionTable.NodeOfFirstLevel_AnalyticsOfManufacturedProductAccounting,
			|	NodeSelectionTable.NodeOfFirstLevel_LotReferenceOfManufacturedProducts,
			|	NodeSelectionTable.NodeOfFirstLevelIs_BatchAccountingAnalysisOfManufacturedProductsLotsVendorAttributes
			|";
		
		If Not TreeParameters.ResultTypeValueTree Then
			RemoveNodeId(TextOfAdditionalCostsAssociation, "NodeSelectionTable");
		EndIf;
		MergeRequestTexts.Add(TextOfAdditionalCostsAssociation);
	
	EndIf;
	
	#EndRegion

	QueryTexts.Add(StrConcat(MergeRequestTexts, TMCommonUse.QuerySeparatorInJoin()));
	QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	Return QueryText;
	
EndFunction

Function QueryTextNodulationResults(TreeParameters)
	
	QueriesTexts = New Array();
	QueryTextsMerging = New Array();
	
	QueryText = "
		|SELECT
		|	T.IdOfFirstLevelNode AS IdOfFirstLevelNode,
		|	T.NodeOfFirstLevelIs_BatchAccountingAnalysisOfManufacturedProductsLotsVendorAttributes AS NodeOfFirstLevelIs_BatchAccountingAnalysisOfManufacturedProductsLotsVendorAttributes,
		|	T.NodeOfFirstLevel_AnalyticsOfManufacturedProductAccounting AS NodeOfFirstLevel_AnalyticsOfManufacturedProductAccounting,
		|	T.NodeOfFirstLevel_LotReferenceOfManufacturedProducts AS NodeOfFirstLevel_LotReferenceOfManufacturedProducts,
		|	T.SourceNodeNeedsToBeDisconnected AS SourceNodeNeedsToBeDisconnected,
		|	T.OriginalBatchDate AS OriginalBatchDate,
		|	T.MonthOfPrimaryLotReferenceVNZP AS MonthOfPrimaryLotReferenceVNZP,
		|
		|	T.NodeID AS NodeID,
		|
		|	T.AccountingDimensionFinishedProduct AS AccountingDimensionFinishedProduct,
		|	T.CostAccountingDimension AS CostAccountingDimension,
		|	T.BatchAccountingDimensionCost AS BatchAccountingDimensionCost,
		|	T.BatchAccountingDimensionFinishedProduct AS BatchAccountingDimensionFinishedProduct,
		|	T.BatchFinishedProduct AS BatchFinishedProduct,
		|
		|	T.Cost_ AS Cost_,
		|	T.CostCharacteristics AS CostCharacteristics,
		|	T.CostSeries AS CostSeries,
		|	T.DestinationCost AS DestinationCost,
		|	T.BatchCost AS BatchCost,
		|
		|	T.Organization AS Organization,
		|	T.Department AS Department,
		|	T.ExpenseType AS ExpenseType,
		|	T.ExplosionIsRequired
		|		AND CAST(T.CostQuantity AS NUMBER(19, 3)) <> 0
		|		AND (T.CostAmount <> 0 OR T.OffBalanceSheetCostAmount <> 0) AS ExplosionIsRequired,
		|	T.ItIsRequiredToUnpackAdditionalExpenseAmount
		|		AND CAST(T.CostQuantity AS NUMBER(19, 3)) <> 0
		|		AND CAST(T.AddExpensesForGoods AS NUMBER(19, 2)) <> 0 AS ItIsRequiredToUnpackAdditionalExpenseAmount,
		|
		|	T.UnitOfMeasurementCost AS UnitOfMeasurementCost,
		|	T.ProductCostElement AS ProductCostElement,
		|
		|	T.CostQuantity AS CostQuantity,
		// Comment 3970.
		// We add the amount of inclusion/exclusion of VAT, within the Local accounting, as a separate line.
		|	CAST(T.CostAmount AS NUMBER(19, 2)) AS CostAmount,
		|	CAST(T.InclusionExclusionOfVATInCost AS NUMBER(19, 2)) AS AmountInclusionExclusionOfVATInCost,
		|	CAST(T.OffBalanceSheetCostAmount AS NUMBER(19, 2)) AS OffBalanceSheetCostAmount,
		|	CAST(T.Material_ AS NUMBER(19, 2)) AS Material_,
		|	CAST(T.LaborCosts AS NUMBER(19, 2)) AS LaborCosts,
		|	CAST(T.ItemizedFixed AS NUMBER(19, 2)) AS ItemizedFixed,
		|	CAST(T.ItemizedVariable AS NUMBER(19, 2)) AS ItemizedVariable,
		|	CAST(T.AddExpensesForGoods AS NUMBER(19, 2)) AS AddExpensesForGoods,
		|	T.AIT AS AIT,
		|	T.TangibleIncludingVAT AS TangibleIncludingVAT,
		|	T.LaborCostsIncludingVAT AS LaborCostsIncludingVAT,
		|	T.ItemizedFixedCostsIncludingVAT AS ItemizedFixedCostsIncludingVAT,
		|	T.ItemizedVariableCostsIncludingVAT AS ItemizedVariableCostsIncludingVAT,
		|	T.AdditionalExpensesIncludingVAT AS AdditionalExpensesIncludingVAT,
		|	T.TangibleExcludingVAT AS TangibleExcludingVAT,
		|	T.ItemizedFixedCostsExcludingVAT AS ItemizedFixedCostsExcludingVAT,
		|	T.ItemizedVariableCostsExcludingVAT AS ItemizedVariableCostsExcludingVAT,
		|	T.AdditionalExpensesExcludingVAT AS AdditionalExpensesExcludingVAT,
		|	T.MaterialMan AS MaterialMan,
		|	T.LaborCostsMan AS LaborCostsMan,
		|	T.ItemizedFixedCostsManag AS ItemizedFixedCostsManag,
		|	T.ItemizedVariableCostsManag AS ItemizedVariableCostsManag,
		|	T.AddExpensesMan AS AddExpensesMan,
		|	T.CostOffBalanceSheetMan AS CostOffBalanceSheetMan,
		|	T.TangibleCompl AS TangibleCompl,
		|	T.LaborCostsLocal AS LaborCostsLocal,
		|	T.ItemizedFixedCostsCompl AS ItemizedFixedCostsCompl,
		|	T.ItemizedVariableCostsCompl AS ItemizedVariableCostsCompl,
		|	T.AddExpensesLocal AS AddExpensesLocal,
		|	T.OffBalanceCostLocal AS OffBalanceCostLocal,
		|	CAST(T.TaxAccounting AS NUMBER(19, 2)) AS TaxAccounting,
		|	T.PermanentDifference AS PermanentDifference,
		|	T.CostTD AS CostTD
		|
		|INTO NodulationResults
		|
		|FROM NodulationResultsPreliminary AS T
		|";
	
	QueryTextsMerging.Add(QueryText);
	
	#Region InclusionExclusionOfVAT
	// See comment 3970.	
	QueryText = "
		|SELECT
		|	T.IdOfFirstLevelNode AS IdOfFirstLevelNode,
		|	T.NodeOfFirstLevelIs_BatchAccountingAnalysisOfManufacturedProductsLotsVendorAttributes AS NodeOfFirstLevelIs_BatchAccountingAnalysisOfManufacturedProductsLotsVendorAttributes,
		|	T.NodeOfFirstLevel_AnalyticsOfManufacturedProductAccounting AS NodeOfFirstLevel_AnalyticsOfManufacturedProductAccounting,
		|	T.NodeOfFirstLevel_LotReferenceOfManufacturedProducts AS NodeOfFirstLevel_LotReferenceOfManufacturedProducts,
		|	MAX(T.SourceNodeNeedsToBeDisconnected) AS SourceNodeNeedsToBeDisconnected,
		|	DATETIME(1, 1, 1) AS OriginalBatchDate,
		|	DATETIME(1, 1, 1) AS MonthOfPrimaryLotReferenceVNZP,
		|
		|	T.NodeID AS NodeID,
		|
		|	T.AccountingDimensionFinishedProduct AS AccountingDimensionFinishedProduct,
		|	NULL AS CostAccountingDimension,
		|	NULL AS BatchAccountingDimensionCost,
		|	T.BatchAccountingDimensionFinishedProduct AS BatchAccountingDimensionFinishedProduct,
		|	T.BatchFinishedProduct AS BatchFinishedProduct,
		|
		|	&ItemInclusionExclusionOfNDSVCost AS Cost_,
		|	NULL AS CostCharacteristics,
		|	NULL AS CostSeries,
		|	NULL AS DestinationCost,
		|	NULL AS BatchCost,
		|
		|	T.Organization AS Organization,
		|	T.Department AS Department,
		|	NULL AS ExpenseType,
		|	FALSE AS ExplosionIsRequired,
		|	FALSE AS ItIsRequiredToUnpackAdditionalExpenseAmount,
		|
		|	NULL AS UnitOfMeasure,
		|	MAX(T.ProductCostElement) AS ProductCostElement,
		|
		|	0 AS CostQuantity,
		|	CAST(SUM(T.InclusionExclusionOfVATInCost) AS NUMBER(19, 2)) AS CostAmount,
		|	0 AS InclusionExclusionOfVATInCost,
		|	0 AS OffBalanceSheetCostAmount,
		|	CAST(SUM(T.InclusionExclusionOfVATInCost) AS NUMBER(19, 2)) AS Material_,
		|	0 AS LaborCosts,
		|	0 AS ItemizedFixed,
		|	0 AS ItemizedVariable,
		|	0 AS AddExpensesForGoods,
		|	0 AS AIT,
		|	0 AS TangibleIncludingVAT,
		|	0 AS LaborCostsIncludingVAT,
		|	0 AS ItemizedFixedCostsIncludingVAT,
		|	0 AS ItemizedVariableCostsIncludingVAT,
		|	0 AS AdditionalExpensesIncludingVAT,
		|	0 AS TangibleExcludingVAT,
		|	0 AS ItemizedFixedCostsExcludingVAT,
		|	0 AS ItemizedVariableCostsExcludingVAT,
		|	0 AS AdditionalExpensesExcludingVAT,
		|	CAST(SUM(T.InclusionExclusionOfVATInCost) AS NUMBER(19, 2)) AS MaterialMan,
		|	0 AS LaborCostsMan,
		|	0 AS ItemizedFixedCostsManag,
		|	0 AS ItemizedVariableCostsManag,
		|	0 AS AddExpensesMan,
		|	0 AS CostOffBalanceSheetMan,
		|	CAST(SUM(T.InclusionExclusionOfVATInCost) AS NUMBER(19, 2)) AS TangibleCompl,
		|	0 AS LaborCostsLocal,
		|	0 AS ItemizedFixedCostsCompl,
		|	0 AS ItemizedVariableCostsCompl,
		|	0 AS AddExpensesLocal,
		|	0 AS OffBalanceCostLocal,
		|	CAST(SUM(T.InclusionExclusionOfVATInCost) AS NUMBER(19, 2)) AS TaxAccounting,
		|	0 AS PermanentDifference,
		|	0 AS CostTD
		|FROM
		|	NodulationResultsPreliminary AS T
		|WHERE
		|	T.InclusionExclusionOfVATInCost <> 0
		|
		|GROUP BY
		|	T.IdOfFirstLevelNode,
		|	T.NodeID,
		|	T.NodeOfFirstLevelIs_BatchAccountingAnalysisOfManufacturedProductsLotsVendorAttributes,
		|	T.NodeOfFirstLevel_AnalyticsOfManufacturedProductAccounting,
		|	T.NodeOfFirstLevel_LotReferenceOfManufacturedProducts,
		|	T.AccountingDimensionFinishedProduct,
		|	T.BatchFinishedProduct,
		|	T.BatchAccountingDimensionFinishedProduct,
		|	T.Organization,
		|	T.Department
		|
		|HAVING
		|	CAST(SUM(T.InclusionExclusionOfVATInCost) AS NUMBER(19, 2)) <> 0
		|";
	If Not TreeParameters.ResultTypeValueTree Then
		RemoveNodeId(QueryText, "T");
	EndIf;
		
	QueryTextsMerging.Add(QueryText);
	
	#EndRegion
	
	#Region Looping
	
	// On the first pass, there is no temp table of nodes by looping.
	If CostCalculationAppliedAlgorithms.TemporaryTableExists(TreeParameters.TempTablesManager,
		"LoopingNodes") Then
			
		QueryText = "
			|SELECT
			|	UZ.IdOfFirstLevelNode AS IdOfFirstLevelNode,
			|	UZ.NodeOfFirstLevelIs_BatchAccountingAnalysisOfManufacturedProductsLotsVendorAttributes AS NodeOfFirstLevelIs_BatchAccountingAnalysisOfManufacturedProductsLotsVendorAttributes,
			|	UZ.NodeOfFirstLevel_AnalyticsOfManufacturedProductAccounting AS NodeOfFirstLevel_AnalyticsOfManufacturedProductAccounting,
			|	UZ.NodeOfFirstLevel_LotReferenceOfManufacturedProducts AS NodeOfFirstLevel_LotReferenceOfManufacturedProducts,
			|	UZ.ExplosionIsRequired AS SourceNodeNeedsToBeDisconnected,
			|	UZ.OriginalBatchDate AS OriginalBatchDate,
			|	DATETIME(1, 1, 1) AS MonthOfPrimaryLotReferenceVNZP,
			|
			|	"""" AS NodeID,
			|
			|	UZ.AccountingDimensionFinishedProduct AS AccountingDimensionFinishedProduct,
			|	NULL AS CostAccountingDimension,
			|	NULL AS BatchAccountingDimensionCost,
			|	NULL AS BatchAccountingDimensionFinishedProduct,
			|	UZ.ProductsBatch AS BatchFinishedProduct,
			|
			|	&ItemLooping AS Cost_,
			|	NULL AS CostCharacteristics,
			|	NULL AS CostSeries,
			|	NULL AS DestinationCost,
			|	NULL AS BatchCost,
			|
			|	UZ.Organization AS Organization,
			|	UZ.Department AS Department,
			|	NULL AS ExpenseType,
			|	FALSE AS ExplosionIsRequired,
			|	FALSE AS ItIsRequiredToUnpackAdditionalExpenseAmount,
			|
			|	NULL AS UnitOfMeasure,
			|	UZ.ProductCostElement AS ProductCostElement,
			|
			|	0 AS CostQuantity,
			|	UZ.Sum AS CostAmount,
			|	UZ.AmountInclusionExclusionOfVATInCost AS InclusionExclusionOfVATInCost,
			|	UZ.OffBalanceSheetAmount AS OffBalanceSheetCostAmount,
			|	UZ.Material_ AS Material_,
			|	UZ.LaborCosts AS LaborCosts,
			|	UZ.ItemizedFixed AS ItemizedFixed,
			|	UZ.ItemizedVariable AS ItemizedVariable,
			|	UZ.AddExpensesForGoods AS AddExpensesForGoods,
			|	0 AS AIT,
			|	0 AS TangibleIncludingVAT,
			|	0 AS LaborCostsIncludingVAT,
			|	0 AS ItemizedFixedCostsIncludingVAT,
			|	0 AS ItemizedVariableCostsIncludingVAT,
			|	0 AS AdditionalExpensesIncludingVAT,
			|	0 AS TangibleExcludingVAT,
			|	0 AS ItemizedFixedCostsExcludingVAT,
			|	0 AS ItemizedVariableCostsExcludingVAT,
			|	0 AS AdditionalExpensesExcludingVAT,
			|	0 AS MaterialMan,
			|	0 AS LaborCostsMan,
			|	0 AS ItemizedFixedCostsManag,
			|	0 AS ItemizedVariableCostsManag,
			|	0 AS AddExpensesMan,
			|	0 AS CostOffBalanceSheetMan,
			|	0 AS TangibleCompl,
			|	0 AS LaborCostsLocal,
			|	0 AS ItemizedFixedCostsCompl,
			|	0 AS ItemizedVariableCostsCompl,
			|	0 AS AddExpensesLocal,
			|	0 AS OffBalanceCostLocal,
			|	UZ.TaxAccounting AS TaxAccounting,
			|	UZ.PermanentDifference AS PermanentDifference,
			|	UZ.CostTD AS CostTD
			|FROM
			|	LoopingNodes AS UZ
			|";
		QueryTextsMerging.Add(QueryText);
	EndIf;
	
	#EndRegion
	
	MergeRequest = StrConcat(QueryTextsMerging,
		TMCommonUse.QuerySeparatorInJoin());
	
	QueriesTexts.Add(MergeRequest);
	
	QueryText = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	
	Return QueryText;
	
EndFunction

Procedure QueryTextProductCosts(TreeParameters)
	
	QueriesTexts = New Array();
	QueryTextsMerging = New Array();
	QueryTextsMerging.Add(QueryTextTemplateSearchResults(False, TreeParameters));

	#Region ChangeInValue
	
	TreeParameters.ReportParameters.Insert("ItemChangeInValueDuringStorage",
		NStr("vi = 'Thay đổi giá trị khi lưu';
			|ru = 'Изменение стоимости при хранении';
			|en = 'Cost change at storage'; fa = 'Cost change at storage';
			|it = 'Modifica del costo durante lo stoccaggio';
			|pl = 'Zmiana wartości podczas przechowywania';
			|tr = 'Depolama sırasında değer değişimi'"));
	TreeParameters.ReportParameters.Insert("ItemAveragingOfValueInWorkInProgress",
		NStr("vi = 'Tính trung bình giá trị trong sản xuất dở dang';
			|ru = 'Усреднение стоимости в незавершенном производстве';
			|en = 'Cost averaging in work-in-progress'; fa = 'Cost averaging in work-in-progress';
			|it = 'Усреднение стоимости в незавершенном производстве';
			|pl = 'Cost averaging in work-in-progress';
			|tr = 'Devam eden imalattaki maliyet ortalaması'"));
	
	QueryText = "
		|SELECT
		|	T.IdOfFirstLevelNode AS IdOfFirstLevelNode,
		|	T.NodeID AS NodeID,
		|
		|	NULL AS BatchFinishedProduct,
		|	T.NodeOfFirstLevel_LotReferenceOfManufacturedProducts AS ProductsBatch,
		|	NULL AS ProductCostElement,
		|	NULL AS Organization,
		|	NULL AS Department,
		|	T.NodeOfFirstLevelIs_BatchAccountingAnalysisOfManufacturedProductsLotsVendorAttributes AS ProductBatchAccountingDimension,
		|	T.NodeOfFirstLevel_AnalyticsOfManufacturedProductAccounting AS ProductsAccountingDimension,
		|
		|	T.AccountingDimensionFinishedProduct AS AccountingDimensionFinishedProduct,
		|	-SUM(T.CostAmount) AS CostAmount,
		|	-SUM(T.Material_) AS Material_,
		|	-SUM(T.TaxAccounting) AS TaxAccounting,
		|	-SUM(T.LaborCosts) AS LaborCosts,
		|	-SUM(T.ItemizedFixed) AS ItemizedFixed,
		|	-SUM(T.ItemizedVariable) AS ItemizedVariable,
		|	-SUM(T.AddExpensesForGoods) AS AddExpensesForGoods,
		|	-SUM(T.OffBalanceSheetCostAmount) AS OffBalanceSheetCostAmount,
		|	-SUM(T.AIT) AS AIT
		|INTO TTChangeInCostPreliminary
		|FROM
		|	NodulationResults AS T
		|
		|WHERE
		|	T.SourceNodeNeedsToBeDisconnected
		|
		|GROUP BY
		|	T.IdOfFirstLevelNode,
		|	T.NodeID,
		|	T.AccountingDimensionFinishedProduct,
		|	T.NodeOfFirstLevel_LotReferenceOfManufacturedProducts,
		|	T.NodeOfFirstLevelIs_BatchAccountingAnalysisOfManufacturedProductsLotsVendorAttributes,
		|	T.NodeOfFirstLevel_AnalyticsOfManufacturedProductAccounting
		|
		|UNION ALL
		|
		|SELECT
		|	DD.IdOfFirstLevelNode AS IdOfFirstLevelNode,
		|	DD.NodeID AS NodeID,
		|
		|	DD.ProductsBatch AS BatchFinishedProduct,
		|	DD.NodeOfFirstLevel_LotReferenceOfManufacturedProducts AS ProductsBatch,
		|	DD.ProductCostElement AS ProductCostElement,
		|	DD.Organization AS Organization,
		|	DD.Department AS Department,
		|	DD.NodeOfFirstLevelIs_BatchAccountingAnalysisOfManufacturedProductsLotsVendorAttributes AS ProductBatchAccountingDimension,
		|	DD.NodeOfFirstLevel_AnalyticsOfManufacturedProductAccounting AS ProductsAccountingDimension,
		|
		|	DD.ExpenseAccountingAnalytics AS AccountingDimensionFinishedProduct,
		|	DD.Sum,
		|	DD.Material_,
		|	DD.TaxAccounting,
		|	DD.LaborCosts,
		|	DD.ItemizedFixed,
		|	DD.ItemizedVariable,
		|	DD.AddExpensesForGoods,
		|	DD.OffBalanceSheetAmount,
		|	0
		|FROM
		|	NodeSelectionTable AS DD
		|WHERE
		|	DD.ExplosionIsRequired
		|";
	QueriesTexts.Add(QueryText);
	
	QueryText = "
		|SELECT
		|	DATETIME(1, 1, 1) AS OriginalBatchDate,
		|	VALUE(Enum.KindsOfCostTreeRows.LotCosts) AS LineKind,
		|	T.IdOfFirstLevelNode AS IdOfFirstLevelNode,
		|	T.NodeID AS NodeID,
		|
		|	T.ProductsAccountingDimension AS ProductsAccountingDimension,
		|	T.AccountingDimensionFinishedProduct AS AccountingDimensionFinishedProduct,
		|	NULL AS CostAccountingDimension,
		|	NULL AS LotVendorAttributes,
		|	T.ProductBatchAccountingDimension AS ProductBatchAccountingDimension,
		|	NULL AS BatchAccountingDimensionFinishedProduct,
		|	NULL AS BatchAccountingDimensionCost,
		|	MAX(T.Organization) AS Organization,
		|	MAX(T.Department) AS Department,
		|	NULL AS ExpenseType,
		|	FALSE AS ExplosionIsRequired,
		|	FALSE AS ItIsRequiredToUnpackAdditionalExpenseAmount,
		|	NULL AS UnitOfMeasure,
		|	CASE
		|		WHEN SUM(T.CostAmount) = SUM(T.AddExpensesForGoods)
		|			THEN &ItemChangeInValueDuringStorage
		|		ELSE &ItemAveragingOfValueInWorkInProgress
		|	END AS Products,
		|	NULL AS Characteristic,
		|	NULL AS Series,
		|	NULL AS Purpose,
		|	VALUE(Catalog.Currencies.EmptyRef) AS Currency,
		|	MAX(T.ProductCostElement) AS ProductCostElement,
		|	CAST(&NodeLevel AS NUMBER) AS Level,
		|	NULL AS Lot,
		|	T.ProductsBatch AS ProductsBatch,
		|	MAX(T.BatchFinishedProduct) AS BatchFinishedProduct,
		|	NULL AS BatchCost,
		|
		|	0 AS Count,
		|	0 AS Numerator,
		|	0 AS Denominator,
		|	SUM(T.CostAmount) AS Sum,
		|	SUM(T.OffBalanceSheetCostAmount) AS OffBalanceSheetAmount,
		|	SUM(T.Material_) AS Material_,
		|	SUM(T.LaborCosts) AS LaborCosts,
		|	SUM(T.ItemizedFixed) AS ItemizedFixed,
		|	SUM(T.ItemizedVariable) AS ItemizedVariable,
		|	SUM(T.AddExpensesForGoods) AS AddExpensesForGoods,
		|	SUM(T.AIT) AS AIT,
		|	0 AS TangibleIncludingVAT,
		|	0 AS LaborCostsIncludingVAT,
		|	0 AS ItemizedFixedCostsIncludingVAT,
		|	0 AS ItemizedVariableCostsIncludingVAT,
		|	0 AS AdditionalExpensesIncludingVAT,
		|	0 AS TangibleExcludingVAT,
		|	0 AS ItemizedFixedCostsExcludingVAT,
		|	0 AS ItemizedVariableCostsExcludingVAT,
		|	0 AS AdditionalExpensesExcludingVAT,
		|	0 AS MaterialMan,
		|	0 AS LaborCostsMan,
		|	0 AS ItemizedFixedCostsManag,
		|	0 AS ItemizedVariableCostsManag,
		|	0 AS AddExpensesMan,
		|	0 AS CostOffBalanceSheetMan,
		|	0 AS TangibleCompl,
		|	0 AS LaborCostsLocal,
		|	0 AS ItemizedFixedCostsCompl,
		|	0 AS ItemizedVariableCostsCompl,
		|	0 AS AddExpensesLocal,
		|	0 AS OffBalanceCostLocal,
		|	SUM(T.TaxAccounting) AS TaxAccounting,
		|	0 AS PermanentDifference,
		|	0 AS CostTD,
		|	0 AS AmountInclusionExclusionOfVATInCost
		|FROM
		|	TTChangeInCostPreliminary AS T
		|
		|GROUP BY
		|	T.IdOfFirstLevelNode,
		|	T.NodeID,
		|	T.AccountingDimensionFinishedProduct,
		|	T.ProductsAccountingDimension,
		|	T.ProductBatchAccountingDimension,
		|	T.ProductsBatch
		|
		|HAVING
		|	SUM(T.CostAmount) <> 0
		|";
		
	If Not TreeParameters.ResultTypeValueTree Then
		// See comment 3970.
		RemoveNodeId(QueryText, "T");
	EndIf;
	
	QueryTextsMerging.Add(QueryText);
	#EndRegion
	
	QueriesTexts.Add(StrConcat(QueryTextsMerging,
		TMCommonUse.QuerySeparatorInJoin()));
	
	TreeParameters.Insert("QueryTextProductCosts",
		StrConcat(QueriesTexts, Common.QueryBatchSeparator()));
	
EndProcedure

Procedure RemoveNodeId(QueryText, TableName)
	// See comment 3970.
	QueryText = StrReplace(QueryText,
		TableName + ".IdOfFirstLevelNode,", ""); //@Query-part
	QueryText = StrReplace(QueryText,
		TableName + ".NodeID,", ""); //@Query-part
	QueryText = StrReplace(QueryText,
		TableName + ".IdOfFirstLevelNode", """"""); //@Query-part
	QueryText = StrReplace(QueryText,
		TableName + ".NodeID", """"""); //@Query-part
EndProcedure

Function QueryTextTemplateSearchResults(RequestForSelection, TreeParameters)
	
	// The order and filling of the columns
	// must repeat the order and filling of the columns in the table of the structure formed here by the field of interstitiousness()
	If RequestForSelection Or TreeParameters.ResultTypeValueTree Then
		QueryText = "
			|SELECT
			|	CASE WHEN T.ExplosionIsRequired OR T.ItIsRequiredToUnpackAdditionalExpenseAmount
			|		THEN T.MonthOfPrimaryLotReferenceVNZP
			|		ELSE T.OriginalBatchDate
			|	END AS OriginalBatchDate,
			|	CASE WHEN T.ExplosionIsRequired
			|		THEN VALUE(Enum.KindsOfCostTreeRows.SemiFinishedProductLot)
			|		ELSE VALUE(Enum.KindsOfCostTreeRows.LotCosts)
			|	END AS LineKind,
			|	T.IdOfFirstLevelNode AS IdOfFirstLevelNode,
			|	T.NodeID AS NodeID,
			|	T.NodeOfFirstLevel_AnalyticsOfManufacturedProductAccounting AS ProductsAccountingDimension,
			|	T.AccountingDimensionFinishedProduct AS AccountingDimensionFinishedProduct,
			|	T.CostAccountingDimension AS CostAccountingDimension,
			|	T.BatchAccountingDimensionCost AS LotVendorAttributes,
			|	T.NodeOfFirstLevelIs_BatchAccountingAnalysisOfManufacturedProductsLotsVendorAttributes AS ProductBatchAccountingDimension,
			|	T.BatchAccountingDimensionFinishedProduct AS BatchAccountingDimensionFinishedProduct,
			|	T.BatchAccountingDimensionCost AS BatchAccountingDimensionCost,
			|	T.Organization AS Organization,
			|	T.Department AS Department,
			|	T.ExpenseType AS ExpenseType,
			|	T.ExplosionIsRequired AS ExplosionIsRequired,
			|	T.ItIsRequiredToUnpackAdditionalExpenseAmount AS ItIsRequiredToUnpackAdditionalExpenseAmount,
			|	T.UnitOfMeasurementCost AS UnitOfMeasure,
			|	T.Cost_ AS Products,
			|	T.CostCharacteristics AS Characteristic,
			|	T.CostSeries AS Series,
			|	T.DestinationCost AS Purpose,
			|	VALUE(Catalog.Currencies.EmptyRef) AS Currency,
			|	T.ProductCostElement AS ProductCostElement,
			|	CAST(&NodeLevel AS NUMBER(15, 0)) AS Level,
			|	T.BatchCost AS Lot,
			|	T.NodeOfFirstLevel_LotReferenceOfManufacturedProducts AS ProductsBatch,
			|	T.BatchFinishedProduct AS BatchFinishedProduct,
			|	T.BatchCost AS BatchCost,
			|	CAST(T.CostQuantity AS NUMBER(19,6)) AS Count,
			|	CAST(CASE WHEN T.ExplosionIsRequired
			|		THEN T.CostQuantity
			|		ELSE 0
			|	END AS NUMBER(19,6)) AS Numerator,
			|	CAST(0 AS NUMBER(19,6)) AS Denominator,
			|	CAST(T.CostAmount AS NUMBER(19,6)) AS Sum,
			|	CAST(T.OffBalanceSheetCostAmount AS NUMBER(19,6)) AS OffBalanceSheetAmount,
			|	CAST(T.Material_ AS NUMBER(19,6)) AS Material_,
			|	CAST(T.LaborCosts AS NUMBER(19,6)) AS LaborCosts,
			|	CAST(T.ItemizedFixed AS NUMBER(19,6)) AS ItemizedFixed,
			|	CAST(T.ItemizedVariable AS NUMBER(19,6)) AS ItemizedVariable,
			|	CAST(T.AddExpensesForGoods AS NUMBER(19,6)) AS AddExpensesForGoods,
			|	CAST(T.AIT AS NUMBER(19,6)) AS AIT,
			|	CAST(T.TangibleIncludingVAT AS NUMBER(19,6)) AS TangibleIncludingVAT,
			|	CAST(T.LaborCostsIncludingVAT AS NUMBER(19,6)) AS LaborCostsIncludingVAT,
			|	CAST(T.ItemizedFixedCostsIncludingVAT AS NUMBER(19,6)) AS ItemizedFixedCostsIncludingVAT,
			|	CAST(T.ItemizedVariableCostsIncludingVAT AS NUMBER(19,6)) AS ItemizedVariableCostsIncludingVAT,
			|	CAST(T.AdditionalExpensesIncludingVAT AS NUMBER(19,6)) AS AdditionalExpensesIncludingVAT,
			|	CAST(T.TangibleExcludingVAT AS NUMBER(19,6)) AS TangibleExcludingVAT,
			|	CAST(T.ItemizedFixedCostsExcludingVAT AS NUMBER(19,6)) AS ItemizedFixedCostsExcludingVAT,
			|	CAST(T.ItemizedVariableCostsExcludingVAT AS NUMBER(19,6)) AS ItemizedVariableCostsExcludingVAT,
			|	CAST(T.AdditionalExpensesExcludingVAT AS NUMBER(19,6)) AS AdditionalExpensesExcludingVAT,
			|	CAST(T.MaterialMan AS NUMBER(19,6)) AS MaterialMan,
			|	CAST(T.LaborCostsMan AS NUMBER(19,6)) AS LaborCostsMan,
			|	CAST(T.ItemizedFixedCostsManag AS NUMBER(19,6)) AS ItemizedFixedCostsManag,
			|	CAST(T.ItemizedVariableCostsManag AS NUMBER(19,6)) AS ItemizedVariableCostsManag,
			|	CAST(T.AddExpensesMan AS NUMBER(19,6)) AS AddExpensesMan,
			|	CAST(T.CostOffBalanceSheetMan AS NUMBER(19,6)) AS CostOffBalanceSheetMan,
			|	CAST(T.TangibleCompl AS NUMBER(19,6)) AS TangibleCompl,
			|	CAST(T.LaborCostsLocal AS NUMBER(19,6)) AS LaborCostsLocal,
			|	CAST(T.ItemizedFixedCostsCompl AS NUMBER(19,6)) AS ItemizedFixedCostsCompl,
			|	CAST(T.ItemizedVariableCostsCompl AS NUMBER(19,6)) AS ItemizedVariableCostsCompl,
			|	CAST(T.AddExpensesLocal AS NUMBER(19,6)) AS AddExpensesLocal,
			|	CAST(T.OffBalanceCostLocal AS NUMBER(19,6)) AS OffBalanceCostLocal,
			|	CAST(T.TaxAccounting AS NUMBER(19,6)) AS TaxAccounting,
			|	CAST(T.PermanentDifference AS NUMBER(19,6)) AS PermanentDifference,
			|	CAST(T.CostTD AS NUMBER(19,6)) AS CostTD,
			|	CAST(T.AmountInclusionExclusionOfVATInCost AS NUMBER(19,6)) AS AmountInclusionExclusionOfVATInCost
			|
			|ADD PreliminaryResult2
			|
			|FROM NodulationResults AS T
			|
			|WHERE
			|	&FilterCriterion
			|";
	Else
		QueryText = "
			|SELECT
			// If this is not a selection, at the moment the value of this column is no longer used anywhere,
			// it makes no sense to waste time on inclusion in the grouping.
			|	DATETIME(1, 1, 1) AS OriginalBatchDate,
			|	CASE WHEN MAX(T.ExplosionIsRequired)
			|		THEN VALUE(Enum.KindsOfCostTreeRows.SemiFinishedProductLot)
			|		ELSE VALUE(Enum.KindsOfCostTreeRows.LotCosts)
			|	END AS LineKind,
			// See comment 3970.
			|	"""" AS IdOfFirstLevelNode,
			|	"""" AS NodeID,
			|	T.NodeOfFirstLevel_AnalyticsOfManufacturedProductAccounting AS ProductsAccountingDimension,
			|	T.AccountingDimensionFinishedProduct AS AccountingDimensionFinishedProduct,
			|	T.CostAccountingDimension AS CostAccountingDimension,
			|	T.BatchAccountingDimensionCost AS LotVendorAttributes,
			|	T.NodeOfFirstLevelIs_BatchAccountingAnalysisOfManufacturedProductsLotsVendorAttributes AS ProductBatchAccountingDimension,
			|	T.BatchAccountingDimensionFinishedProduct AS BatchAccountingDimensionFinishedProduct,
			|	T.BatchAccountingDimensionCost AS BatchAccountingDimensionCost,
			|	T.Organization AS Organization,
			|	T.Department AS Department,
			|	T.ExpenseType AS ExpenseType,
			|	MAX(T.ExplosionIsRequired) AS ExplosionIsRequired,
			|	MAX(T.ItIsRequiredToUnpackAdditionalExpenseAmount) AS ItIsRequiredToUnpackAdditionalExpenseAmount,
			|	T.UnitOfMeasurementCost AS UnitOfMeasure,
			|	T.Cost_ AS Products,
			|	T.CostCharacteristics AS Characteristic,
			|	T.CostSeries AS Series,
			|	T.DestinationCost AS Purpose,
			|	VALUE(Catalog.Currencies.EmptyRef) AS Currency,
			|	T.ProductCostElement AS ProductCostElement,
			|	CAST(&NodeLevel AS NUMBER(15, 0)) AS Level,
			|	T.BatchCost AS Lot,
			|	T.NodeOfFirstLevel_LotReferenceOfManufacturedProducts AS ProductsBatch,
			|	T.BatchFinishedProduct AS BatchFinishedProduct,
			|	T.BatchCost AS BatchCost,
			|	
			|	CAST(SUM(T.CostQuantity) AS NUMBER(19,6)) AS Count,
			|	CAST(CASE WHEN MAX(T.ExplosionIsRequired)
			|		THEN SUM(T.CostQuantity)
			|		ELSE 0
			|	END AS NUMBER(19,6)) AS Numerator,
			|	CAST(0 AS NUMBER(19,6)) AS Denominator,
			|	CAST(SUM(T.CostAmount) AS NUMBER(19,6)) AS Sum,
			|	CAST(SUM(T.OffBalanceSheetCostAmount) AS NUMBER(19,6)) AS OffBalanceSheetAmount,
			|	CAST(SUM(T.Material_) AS NUMBER(19,6)) AS Material_,
			|	CAST(SUM(T.LaborCosts) AS NUMBER(19,6)) AS LaborCosts,
			|	CAST(SUM(T.ItemizedFixed) AS NUMBER(19,6)) AS ItemizedFixed,
			|	CAST(SUM(T.ItemizedVariable) AS NUMBER(19,6)) AS ItemizedVariable,
			|	CAST(SUM(T.AddExpensesForGoods) AS NUMBER(19,6)) AS AddExpensesForGoods,
			|	CAST(SUM(T.AIT) AS NUMBER(19,6)) AS AIT,
			|	CAST(SUM(T.TangibleIncludingVAT) AS NUMBER(19,6)) AS TangibleIncludingVAT,
			|	CAST(SUM(T.LaborCostsIncludingVAT) AS NUMBER(19,6)) AS LaborCostsIncludingVAT,
			|	CAST(SUM(T.ItemizedFixedCostsIncludingVAT) AS NUMBER(19,6)) AS ItemizedFixedCostsIncludingVAT,
			|	CAST(SUM(T.ItemizedVariableCostsIncludingVAT) AS NUMBER(19,6)) AS ItemizedVariableCostsIncludingVAT,
			|	CAST(SUM(T.AdditionalExpensesIncludingVAT) AS NUMBER(19,6)) AS AdditionalExpensesIncludingVAT,
			|	CAST(SUM(T.TangibleExcludingVAT) AS NUMBER(19,6)) AS TangibleExcludingVAT,
			|	CAST(SUM(T.ItemizedFixedCostsExcludingVAT) AS NUMBER(19,6)) AS ItemizedFixedCostsExcludingVAT,
			|	CAST(SUM(T.ItemizedVariableCostsExcludingVAT) AS NUMBER(19,6)) AS ItemizedVariableCostsExcludingVAT,
			|	CAST(SUM(T.AdditionalExpensesExcludingVAT) AS NUMBER(19,6)) AS AdditionalExpensesExcludingVAT,
			|	CAST(SUM(T.MaterialMan) AS NUMBER(19,6)) AS MaterialMan,
			|	CAST(SUM(T.LaborCostsMan) AS NUMBER(19,6)) AS LaborCostsMan,
			|	CAST(SUM(T.ItemizedFixedCostsManag) AS NUMBER(19,6)) AS ItemizedFixedCostsManag,
			|	CAST(SUM(T.ItemizedVariableCostsManag) AS NUMBER(19,6)) AS ItemizedVariableCostsManag,
			|	CAST(SUM(T.AddExpensesMan) AS NUMBER(19,6)) AS AddExpensesMan,
			|	CAST(SUM(T.CostOffBalanceSheetMan) AS NUMBER(19,6)) AS CostOffBalanceSheetMan,
			|	CAST(SUM(T.TangibleCompl) AS NUMBER(19,6)) AS TangibleCompl,
			|	CAST(SUM(T.LaborCostsLocal) AS NUMBER(19,6)) AS LaborCostsLocal,
			|	CAST(SUM(T.ItemizedFixedCostsCompl) AS NUMBER(19,6)) AS ItemizedFixedCostsCompl,
			|	CAST(SUM(T.ItemizedVariableCostsCompl) AS NUMBER(19,6)) AS ItemizedVariableCostsCompl,
			|	CAST(SUM(T.AddExpensesLocal) AS NUMBER(19,6)) AS AddExpensesLocal,
			|	CAST(SUM(T.OffBalanceCostLocal) AS NUMBER(19,6)) AS OffBalanceCostLocal,
			|	CAST(SUM(T.TaxAccounting) AS NUMBER(19,6)) AS TaxAccounting,
			|	CAST(SUM(T.PermanentDifference) AS NUMBER(19,6)) AS PermanentDifference,
			|	CAST(SUM(T.CostTD) AS NUMBER(19,6)) AS CostTD,
			|	CAST(SUM(T.AmountInclusionExclusionOfVATInCost) AS NUMBER(19,6)) AS AmountInclusionExclusionOfVATInCost
			|
			|ADD PreliminaryResult2
			|
			|FROM NodulationResults AS T
			|
			|WHERE
			|	&FilterCriterion
			|
			|GROUP BY
			|	CASE WHEN T.ExplosionIsRequired
			|		THEN VALUE(Enum.KindsOfCostTreeRows.SemiFinishedProductLot)
			|		ELSE VALUE(Enum.KindsOfCostTreeRows.LotCosts)
			|	END, // LineKind
			|	T.Organization,
			|	T.Department,
			|	T.NodeOfFirstLevel_AnalyticsOfManufacturedProductAccounting,
			|	T.NodeOfFirstLevelIs_BatchAccountingAnalysisOfManufacturedProductsLotsVendorAttributes,
			|	T.NodeOfFirstLevel_LotReferenceOfManufacturedProducts,
			|	T.AccountingDimensionFinishedProduct,
			|	T.BatchAccountingDimensionFinishedProduct,
			|	T.BatchFinishedProduct,
			|	T.BatchAccountingDimensionCost,
			|	T.BatchCost,
			|	T.Cost_,
			|	T.CostCharacteristics,
			|	T.ProductCostElement,
			|	T.UnitOfMeasurementCost,
			|
			|	T.CostSeries,
			|	T.DestinationCost,
			|	T.CostAccountingDimension,
			|	T.ExpenseType
			|";
	EndIf;
	
	If RequestForSelection Then
		QueryText = StrReplace(QueryText, "&FilterCriterion",
			"T.ExplosionIsRequired OR T.ItIsRequiredToUnpackAdditionalExpenseAmount"); //@Query-part
		QueryText = StrReplace(QueryText, "ADD PreliminaryResult2", ""); //@Query-part
	Else
		QueryText = StrReplace(QueryText, "&FilterCriterion",
			"&AddSemiFinishedProductsToResult OR NOT T.ExplosionIsRequired"); //@Query-part
	EndIf;
	
	Return QueryText;
EndFunction

#Region RequestForManufacturedProducts

Function RequestTemplateForManufacturedProducts(ThereIsSelectionAccordingToNodeSelectionTable, PlacingIWT, TreeParameters)
	
	QueriesTexts = New Array();
	
	QueryText = "
		|SELECT ALLOWED
		|	InventoryCost.Organization				AS Organization,
		|	InventoryCost.Lot						AS ProductsBatch,
		|	InventoryCost.LotVendorAttributes		AS ProductBatchAccountingDimension,
		|	SUM(InventoryCost.Count)			AS Numerator
		|INTO TableFilters
		|FROM
		|	AccumulationRegister.InventoryCost AS InventoryCost
		|WHERE
		|	&DecryptionOfDocumentRegisteredRecords
		|	AND InventoryCost.AccountingSection IN (VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock),
		|										VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts),
		|										VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping),
		|										VALUE(Enum.SectionsOfInventoryCostAccounting.VendorManagedInventoryToRegisterWriteOff),
		|										VALUE(Enum.SectionsOfInventoryCostAccounting.VendorManagedInventoryTransferredToPartners),
		|										VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller))
		|	AND NOT InventoryCost.Lot = UNDEFINED
		|	AND InventoryCost.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND InventoryCost.Recorder IN (&Recorders)
		|	AND (InventoryCost.Period BETWEEN &StartDate AND &EndDate OR &EndDate = DATETIME(1,1,1))
		|{WHERE
		|	InventoryCost.Organization.*	AS Organization,
		|	InventoryCost.Lot.*		AS ProductsBatch
		|}
		|GROUP BY
		|	InventoryCost.Organization,
		|	InventoryCost.Lot,
		|	InventoryCost.LotVendorAttributes
		|	
		|INDEX BY
		|	Organization,
		|	ProductsBatch,
		|	ProductBatchAccountingDimension
		|";
	QueriesTexts.Add(QueryText);
	
	#Region InventoryCost
	
	SelectionConditionAccordingToSelectionTable = "NOT InventoryCost.Lot = UNDEFINED";
	If ThereIsSelectionAccordingToNodeSelectionTable Then
		QueryText = "
		|SELECT DISTINCT
		|	T.ProductsBatch AS ProductsBatch
		|
		|INTO SelectionOfManufacturedProductsAndLotReferences
		|FROM NodeSelectionTable AS T
		|
		|INDEX BY
		|	ProductsBatch
		|";
		
		SelectionConditionAccordingToSelectionTable = "
		|TRUE IN (SELECT TOP 1 TRUE
		|		FROM SelectionOfManufacturedProductsAndLotReferences AS SelectionOfManufacturedProductsAndLotReferences
		|		WHERE InventoryCost.Lot = SelectionOfManufacturedProductsAndLotReferences.ProductsBatch
		|)
		|";
		
		QueriesTexts.Add(QueryText);
	EndIf;
	
	QueryText = "
		|SELECT ALLOWED
		|	InventoryCost.Period AS Period,
		|	InventoryCost.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	InventoryCost.AccountingSection AS AccountingSection,
		|	InventoryCost.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	InventoryCost.Organization AS Organization,
		|	InventoryCost.Lot AS Lot,
		|	InventoryCost.LotVendorAttributes AS LotVendorAttributes,
		|	InventoryCost.FinancialAccountingDimension AS FinancialAccountingDimension,
		|	InventoryCost.VATActivityType AS VATActivityType,
		|	InventoryCost.CorItemsLocationAttributes AS CorItemsLocationAttributes,
		|	
		|	InventoryCost.Count AS Count,
		|	InventoryCost.Cost AS Cost,
		|	InventoryCost.CostExcludingVAT AS CostExcludingVAT,
		|	InventoryCost.CostMan AS CostMan,
		|	InventoryCost.LocalCost AS LocalCost,
		|	InventoryCost.LaborCosts AS LaborCosts,
		|	InventoryCost.LaborCostsMan AS LaborCostsMan,
		|	InventoryCost.LaborCostsLocal AS LaborCostsLocal,
		|	InventoryCost.ItemizedFixedCostsIncludingVAT AS ItemizedFixedCostsIncludingVAT,
		|	InventoryCost.ItemizedFixedCostsExcludingVAT AS ItemizedFixedCostsExcludingVAT,
		|	InventoryCost.ItemizedFixedCostsManag AS ItemizedFixedCostsManag,
		|	InventoryCost.ItemizedFixedCostsCompl AS ItemizedFixedCostsCompl,
		|	InventoryCost.ItemizedVariableCostsIncludingVAT AS ItemizedVariableCostsIncludingVAT,
		|	InventoryCost.ItemizedVariableCostsExcludingVAT AS ItemizedVariableCostsExcludingVAT,
		|	InventoryCost.ItemizedVariableCostsManag AS ItemizedVariableCostsManag, 
		|	InventoryCost.ItemizedVariableCostsCompl AS ItemizedVariableCostsCompl,
		|	InventoryCost.AddExpensesForGoods AS AddExpensesForGoods,
		|	InventoryCost.AdditionalExpensesExcludingVAT AS AdditionalExpensesExcludingVAT,
		|	InventoryCost.AddExpensesMan AS AddExpensesMan,
		|	InventoryCost.AddExpensesLocal AS AddExpensesLocal,
		|	InventoryCost.OffBalanceCost AS OffBalanceCost,
		|	InventoryCost.OffBalanceCostLocal AS OffBalanceCostLocal,
		|	InventoryCost.CostOfPersonalIncomeTax AS CostOfPersonalIncomeTax,
		|	InventoryCost.PermanentDifference AS PermanentDifference,
		|	InventoryCost.CostTD AS CostTD
		|
		|INTO TTCostOfGoods_
		|FROM
		|	AccumulationRegister.InventoryCost AS InventoryCost
		|WHERE
		|	&SelectionConditionAccordingToSelectionTable
		|	AND InventoryCost.RecordType = VALUE(AccumulationRecordType.Receipt)
		|
		|	AND InventoryCost.BusinessOperation IN (VALUE(Enum.BusinessTransactions.ProductsRelease),
		|										VALUE(Enum.BusinessTransactions.ProductsReleaseToWarehouse),
		|										VALUE(Enum.BusinessTransactions.ProductsReleaseToBusinessUnit))
		|
		|	AND InventoryCost.AccountingSection IN (VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease),
		|										VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts),
		|										VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping),
		|										VALUE(Enum.SectionsOfInventoryCostAccounting.VendorManagedInventoryToRegisterWriteOff),
		|										VALUE(Enum.SectionsOfInventoryCostAccounting.VendorManagedInventoryTransferredToPartners),
		|										VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller))
		|	AND &DecryptionOfDocumentRegisteredRecords
		|{WHERE
		|	InventoryCost.Organization.*		AS Organization,
		|	InventoryCost.Lot.*			AS ProductsBatch
		|}
		|
		|INDEX BY
		|	Lot
		|";
	
	QueryText = StrReplace(QueryText,
		"AND &DecryptionOfDocumentRegisteredRecords",
		?(TreeParameters.ReportParameters.DecryptionOfDocumentRegisteredRecords,
			"",
			"AND (InventoryCost.Period BETWEEN &StartDate AND &EndDate OR &EndDate = DATETIME(1,1,1))")); //@Query-part

	QueryText = StrReplace(QueryText, "&SelectionConditionAccordingToSelectionTable", SelectionConditionAccordingToSelectionTable);
	QueriesTexts.Add(QueryText);
	
	#EndRegion
		
	
	#Region TTManufacturedProduct
	
	QueryText = "
		|SELECT
		|	NodeSelectionTable.NodeID AS NodeID,
		|	MAX(InventoryCost.Period)					AS ReleaseDateOfManufacturedProducts,
		|	InventoryCost.Organization						AS Organization,
		|	InventoryCost.Lot								AS ProductsBatch,
		|	InventoryCost.LotVendorAttributes				AS ProductBatchAccountingDimension,
		|	CASE
		|		WHEN TRUE
		|			THEN InventoryCost.ItemsLocationAttributes
		|	END													AS ProductsAccountingDimension,
		|	DimensionKeys.Products								AS ManufacturedProduct,
		|	DimensionKeys.Characteristic							AS ItemVariant,
		|	DimensionKeys.Series									AS ProductionSeries_,
		|	DimensionKeys.Purpose								AS AssignmentOfProducts,
		|	CatDepartments.Ref									AS Department,
		|	CASE
		|		WHEN MAX(ISNULL(NodeSelectionTable.Numerator, 0)) = 0
		|			THEN SUM(
		|					CASE
		|						WHEN TRUE
		|							THEN InventoryCost.Count
		|					END)
		|			ELSE MAX(ISNULL(NodeSelectionTable.Numerator, 0))
		|		END												AS Numerator,
		|	CASE
		|		WHEN MAX(ISNULL(NodeSelectionTable.Denominator, 0)) = 0
		|			THEN SUM(
		|					CASE
		|						WHEN TRUE
		|							THEN InventoryCost.Count
		|					END)
		|			ELSE MAX(ISNULL(NodeSelectionTable.Denominator, 0))
		|		END												AS Denominator,
		|	SUM(
		|		CASE
		|			WHEN TRUE
		|				THEN InventoryCost.Count
		|		END)					AS NumberOfProducts_1,
		|
		// The cost according to the parameter "Data of the cost"
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.Cost
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.CostExcludingVAT
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.CostMan
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.LocalCost
		|		END)												AS Material_,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.LaborCosts
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.LaborCosts
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.LaborCostsMan
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.LaborCostsLocal
		|		END)												AS LaborCosts,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.ItemizedFixedCostsIncludingVAT
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.ItemizedFixedCostsExcludingVAT
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.ItemizedFixedCostsManag
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.ItemizedFixedCostsCompl
		|		END)												AS ItemizedFixed,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.ItemizedVariableCostsIncludingVAT
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.ItemizedVariableCostsExcludingVAT
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.ItemizedVariableCostsManag
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.ItemizedVariableCostsCompl
		|		END)												AS ItemizedVariable,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.AddExpensesForGoods
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.AdditionalExpensesExcludingVAT
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.AddExpensesMan
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.AddExpensesLocal
		|		END)												AS AddExpensesForGoods,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.OffBalanceCost
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.OffBalanceCost
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.OffBalanceCost
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.OffBalanceCostLocal
		|		END)												AS AmountOffBalanceSheetProducts,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.Cost
		|					+ InventoryCost.LaborCosts
		|					+ InventoryCost.ItemizedFixedCostsIncludingVAT
		|					+ InventoryCost.ItemizedVariableCostsIncludingVAT
		|					+ InventoryCost.AddExpensesForGoods
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.CostExcludingVAT
		|					+ InventoryCost.LaborCosts
		|					+ InventoryCost.ItemizedFixedCostsExcludingVAT
		|					+ InventoryCost.ItemizedVariableCostsExcludingVAT
		|					+ InventoryCost.AdditionalExpensesExcludingVAT
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.CostMan
		|					+ InventoryCost.LaborCostsMan
		|					+ InventoryCost.ItemizedFixedCostsManag
		|					+ InventoryCost.ItemizedVariableCostsManag
		|					+ InventoryCost.AddExpensesMan
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.LocalCost
		|					+ InventoryCost.LaborCostsLocal
		|					+ InventoryCost.ItemizedFixedCostsCompl
		|					+ InventoryCost.ItemizedVariableCostsCompl
		|					+ InventoryCost.AddExpensesLocal
		|		END)												AS TotalOutput,
		|	SUM(CASE
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.CostOfPersonalIncomeTax
		|			ELSE 0
		|		END)												AS AIT,
		|
		// Costs with VAT
		|	SUM(InventoryCost.Cost)					AS TangibleIncludingVAT,
		|	SUM(InventoryCost.LaborCosts)				AS LaborCostsIncludingVAT,
		|	SUM(InventoryCost.ItemizedFixedCostsIncludingVAT)	AS ItemizedFixedCostsIncludingVAT,
		|	SUM(InventoryCost.ItemizedVariableCostsIncludingVAT)	AS ItemizedVariableCostsIncludingVAT,
		|	SUM(InventoryCost.AddExpensesForGoods)					AS AdditionalExpensesIncludingVAT,
		|
		// Costs without VAT
		|	SUM(InventoryCost.CostExcludingVAT)				AS TangibleExcludingVAT,
		|	SUM(InventoryCost.ItemizedFixedCostsExcludingVAT)	AS ItemizedFixedCostsExcludingVAT,
		|	SUM(InventoryCost.ItemizedVariableCostsExcludingVAT)	AS ItemizedVariableCostsExcludingVAT,
		|	SUM(InventoryCost.AdditionalExpensesExcludingVAT)			AS AdditionalExpensesExcludingVAT,
		|
		// The Cost of Upr
		|	SUM(InventoryCost.CostMan)				AS MaterialMan,
		|	SUM(InventoryCost.LaborCostsMan)				AS LaborCostsMan,
		|	SUM(InventoryCost.ItemizedFixedCostsManag)	AS ItemizedFixedCostsManag,
		|	SUM(InventoryCost.ItemizedVariableCostsManag)	AS ItemizedVariableCostsManag,
		|	SUM(InventoryCost.AddExpensesMan)				AS AddExpensesMan,
		|	SUM(InventoryCost.OffBalanceCost)		AS CostOffBalanceSheetMan,
		|
		// Regl Costs
		|	SUM(InventoryCost.LocalCost)				AS TangibleCompl,
		|	SUM(InventoryCost.LaborCostsLocal)			AS LaborCostsLocal,
		|	SUM(InventoryCost.ItemizedFixedCostsCompl)	AS ItemizedFixedCostsCompl,
		|	SUM(InventoryCost.ItemizedVariableCostsCompl)	AS ItemizedVariableCostsCompl,
		|	SUM(InventoryCost.AddExpensesLocal)				AS AddExpensesLocal,
		|	SUM(InventoryCost.OffBalanceCostLocal)	AS OffBalanceCostLocal,
		|	
		// Tax accounting
		|	SUM(InventoryCost.LocalCost
		|		+ InventoryCost.AddExpensesLocal
		|		+ InventoryCost.LaborCostsLocal
		|		+ InventoryCost.ItemizedFixedCostsCompl
		|		+ InventoryCost.ItemizedVariableCostsCompl
		|		- InventoryCost.PermanentDifference
		|		- InventoryCost.CostTD)			AS TaxAccounting,
		|	SUM(InventoryCost.PermanentDifference)			AS PermanentDifference,
		|	SUM(InventoryCost.CostTD)			AS CostTD
		|
		|INTO TTManufacturedProduct
		|FROM
		|	TTCostOfGoods_ AS InventoryCost
		|	
		|	
		|	LEFT JOIN Document.SubcontractorReport2_5 AS ProcessorReports2_5
		|		ON ProcessorReports2_5.Ref = InventoryCost.Lot
		|	
		|	
		|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionKeys
		|		ON DimensionKeys.Ref =
		|				CASE
		|					WHEN TRUE
		|						THEN InventoryCost.ItemsLocationAttributes
		|				END
		|	
		|	LEFT JOIN Catalog.BusinessStructure AS CatDepartments
		|		ON CASE
		|			WHEN ProcessorReports2_5.Ref IS NOT NULL
		|				THEN ProcessorReports2_5.Department
		|			WHEN DimensionKeys.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
		|				THEN DimensionKeys.WarehouseArea.Department
		|			ELSE DimensionKeys.StorageLocation
		|		END = CatDepartments.Ref
		|		
		|	INNER JOIN NodeSelectionTable AS NodeSelectionTable
		|		ON (&ConnectionConditions_NodeSelectionTable)
		|		
		|WHERE
		|	NOT &DecryptionOfDocumentRegisteredRecords
		|	AND (InventoryCost.Period BETWEEN &StartDate AND &EndDate OR &EndDate = DATETIME(1,1,1))
		|
		|{WHERE
		|	InventoryCost.Organization.*		AS Organization,
		|	CatDepartments.Ref.*				AS Department,
		|	DimensionKeys.Products.*			AS ManufacturedProduct,
		|	InventoryCost.Lot.*			AS ProductsBatch,
		|	DimensionKeys.Characteristic.*			AS ItemVariant,
		|	DimensionKeys.Series.*					AS ProductionSeries_,
		|	DimensionKeys.Purpose.*				AS AssignmentOfProducts
		|}
		|GROUP BY
		|	NodeSelectionTable.NodeID,
		|	InventoryCost.Organization,
		|	InventoryCost.Lot,
		|	InventoryCost.LotVendorAttributes,
		|	CASE
		|		WHEN TRUE
		|			THEN InventoryCost.ItemsLocationAttributes
		|	END,
		|	DimensionKeys.Products,
		|	DimensionKeys.Characteristic,
		|	DimensionKeys.Series,
		|	DimensionKeys.Purpose,
		|	CatDepartments.Ref
		|
		|UNION ALL
		|
		|SELECT
		|	NodeSelectionTable.NodeID AS NodeID,
		|	MAX(InventoryCost.Period)					AS ReleaseDateOfManufacturedProducts,
		|	TableFilters.Organization								AS Organization,
		|	TableFilters.ProductsBatch							AS ProductsBatch,
		|	TableFilters.ProductBatchAccountingDimension			AS ProductBatchAccountingDimension,
		|	CASE
		|		WHEN TRUE
		|			THEN InventoryCost.ItemsLocationAttributes
		|	END													AS ProductsAccountingDimension,
		|	DimensionKeys.Products								AS ManufacturedProduct,
		|	DimensionKeys.Characteristic							AS ItemVariant,
		|	DimensionKeys.Series									AS ProductionSeries_,
		|	DimensionKeys.Purpose								AS AssignmentOfProducts,
		|	CatDepartments.Ref									AS Department,
		|	MAX(TableFilters.Numerator)						AS Numerator,
		|	SUM(
		|		CASE
		|			WHEN TRUE
		|				THEN InventoryCost.Count
		|		END)												AS Denominator,
		|	MAX(TableFilters.Numerator)						AS NumberOfProducts_1,
		|
		// The cost according to the parameter "Data of the cost"
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.Cost
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.CostExcludingVAT
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.CostMan
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.LocalCost
		|		END)												AS Material_,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.LaborCosts
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.LaborCosts
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.LaborCostsMan
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.LaborCostsLocal
		|		END)												AS LaborCosts,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.ItemizedFixedCostsIncludingVAT
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.ItemizedFixedCostsExcludingVAT
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.ItemizedFixedCostsManag
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.ItemizedFixedCostsCompl
		|		END)												AS ItemizedFixed,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.ItemizedVariableCostsIncludingVAT
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.ItemizedVariableCostsExcludingVAT
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.ItemizedVariableCostsManag
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.ItemizedVariableCostsCompl
		|		END)												AS ItemizedVariable,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.AddExpensesForGoods
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.AdditionalExpensesExcludingVAT
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.AddExpensesMan
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.AddExpensesLocal
		|		END)												AS AddExpensesForGoods,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.OffBalanceCost
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.OffBalanceCost
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.OffBalanceCost
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.OffBalanceCostLocal
		|		END)												AS AmountOffBalanceSheetProducts,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.Cost
		|					+ InventoryCost.LaborCosts
		|					+ InventoryCost.ItemizedFixedCostsIncludingVAT
		|					+ InventoryCost.ItemizedVariableCostsIncludingVAT
		|					+ InventoryCost.AddExpensesForGoods
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.CostExcludingVAT
		|					+ InventoryCost.LaborCosts
		|					+ InventoryCost.ItemizedFixedCostsExcludingVAT
		|					+ InventoryCost.ItemizedVariableCostsExcludingVAT
		|					+ InventoryCost.AdditionalExpensesExcludingVAT
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.CostMan
		|					+ InventoryCost.LaborCostsMan
		|					+ InventoryCost.ItemizedFixedCostsManag
		|					+ InventoryCost.ItemizedVariableCostsManag
		|					+ InventoryCost.AddExpensesMan
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.LocalCost
		|					+ InventoryCost.LaborCostsLocal
		|					+ InventoryCost.ItemizedFixedCostsCompl
		|					+ InventoryCost.ItemizedVariableCostsCompl
		|					+ InventoryCost.AddExpensesLocal
		|		END)												AS TotalOutput,
		|	SUM(CASE
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.CostOfPersonalIncomeTax
		|			ELSE 0
		|		END)												AS AIT,
		|
		// Costs with VAT
		|	SUM(InventoryCost.Cost)					AS TangibleIncludingVAT,
		|	SUM(InventoryCost.LaborCosts)				AS LaborCostsIncludingVAT,
		|	SUM(InventoryCost.ItemizedFixedCostsIncludingVAT)	AS ItemizedFixedCostsIncludingVAT,
		|	SUM(InventoryCost.ItemizedVariableCostsIncludingVAT)	AS ItemizedVariableCostsIncludingVAT,
		|	SUM(InventoryCost.AddExpensesForGoods)					AS AdditionalExpensesIncludingVAT,
		|
		// Costs without VAT
		|	SUM(InventoryCost.CostExcludingVAT)				AS TangibleExcludingVAT,
		|	SUM(InventoryCost.ItemizedFixedCostsExcludingVAT)	AS ItemizedFixedCostsExcludingVAT,
		|	SUM(InventoryCost.ItemizedVariableCostsExcludingVAT)	AS ItemizedVariableCostsExcludingVAT,
		|	SUM(InventoryCost.AdditionalExpensesExcludingVAT)			AS AdditionalExpensesExcludingVAT,
		|
		// The Cost of Upr
		|	SUM(InventoryCost.CostMan)				AS MaterialMan,
		|	SUM(InventoryCost.LaborCostsMan)				AS LaborCostsMan,
		|	SUM(InventoryCost.ItemizedFixedCostsManag)	AS ItemizedFixedCostsManag,
		|	SUM(InventoryCost.ItemizedVariableCostsManag)	AS ItemizedVariableCostsManag,
		|	SUM(InventoryCost.AddExpensesMan)				AS AddExpensesMan,
		|	SUM(InventoryCost.OffBalanceCost)		AS CostOffBalanceSheetMan,
		|
		// Regl Costs
		|	SUM(InventoryCost.LocalCost)				AS TangibleCompl,
		|	SUM(InventoryCost.LaborCostsLocal)			AS LaborCostsLocal,
		|	SUM(InventoryCost.ItemizedFixedCostsCompl)	AS ItemizedFixedCostsCompl,
		|	SUM(InventoryCost.ItemizedVariableCostsCompl)	AS ItemizedVariableCostsCompl,
		|	SUM(InventoryCost.AddExpensesLocal)				AS AddExpensesLocal,
		|	SUM(InventoryCost.OffBalanceCostLocal)	AS OffBalanceCostLocal,
		|	
		// Tax accounting
		|	SUM(InventoryCost.LocalCost
		|		+ InventoryCost.AddExpensesLocal
		|		+ InventoryCost.LaborCostsLocal
		|		+ InventoryCost.ItemizedFixedCostsCompl
		|		+ InventoryCost.ItemizedVariableCostsCompl
		|		- InventoryCost.PermanentDifference
		|		- InventoryCost.CostTD)			AS TaxAccounting,
		|	SUM(InventoryCost.PermanentDifference)			AS PermanentDifference,
		|	SUM(InventoryCost.CostTD)			AS CostTD
		|FROM
		|	TableFilters AS TableFilters
		|	
		|	INNER JOIN TTCostOfGoods_ AS InventoryCost
		|		ON TableFilters.ProductsBatch = InventoryCost.Lot
		|		AND TableFilters.ProductBatchAccountingDimension = InventoryCost.LotVendorAttributes
		|		AND (InventoryCost.Period <= &EndDate OR &EndDate = DATETIME(1,1,1))
		|		
		|	
		|	LEFT JOIN Document.SubcontractorReport2_5 AS ProcessorReports2_5
		|		ON ProcessorReports2_5.Ref = InventoryCost.Lot
		|	
		|	
		|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionKeys
		|		ON DimensionKeys.Ref = 
		|				CASE
		|					WHEN TRUE
		|						THEN InventoryCost.ItemsLocationAttributes
		|				END
		|	
		|	LEFT JOIN Catalog.BusinessStructure AS CatDepartments
		|		ON CASE
		|			WHEN ProcessorReports2_5.Ref IS NOT NULL
		|				THEN ProcessorReports2_5.Department
		|			WHEN DimensionKeys.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
		|				THEN DimensionKeys.WarehouseArea.Department
		|			ELSE DimensionKeys.StorageLocation
		|		END = CatDepartments.Ref
		|		
		|	INNER JOIN NodeSelectionTable AS NodeSelectionTable
		|		ON (&ConnectionConditions_NodeSelectionTable)
		|	
		|WHERE
		|	&DecryptionOfDocumentRegisteredRecords
		|
		|{WHERE
		|	CatDepartments.Ref.*				AS Department,
		|	DimensionKeys.Products.*			AS ManufacturedProduct,
		|	DimensionKeys.Characteristic.*			AS ItemVariant,
		|	DimensionKeys.Series.*					AS ProductionSeries_,
		|	DimensionKeys.Purpose.*				AS AssignmentOfProducts
		|}
		|
		|GROUP BY
		|	NodeSelectionTable.NodeID,
		|	TableFilters.Organization,
		|	TableFilters.ProductsBatch,
		|	TableFilters.ProductBatchAccountingDimension,
		|	CASE
		|		WHEN TRUE
		|			THEN InventoryCost.ItemsLocationAttributes
		|	END,
		|	DimensionKeys.Products,
		|	DimensionKeys.Characteristic,
		|	DimensionKeys.Series,
		|	DimensionKeys.Purpose,
		|	CatDepartments.Ref
		|";
		QueriesTexts.Add(QueryText);
		
		#EndRegion
		
	#Region TotalProductsProduced
		
	QueryText = "
		|SELECT
		|	TTManufacturedProduct.NodeID AS NodeID,
		|	MAX(TTManufacturedProduct.ReleaseDateOfManufacturedProducts) AS ReleaseDateOfManufacturedProducts,
		|	TTManufacturedProduct.Organization						AS Organization,
		|	CASE
		|		WHEN &Cost_Data = 3
		|			THEN TTManufacturedProduct.Organization.LocalAccountingCurrency
		|		ELSE &ManagementAccountingCurrency
		|	END AS Currency,
		|	TTManufacturedProduct.ProductsBatch					AS ProductsBatch,
		|	TTManufacturedProduct.ProductBatchAccountingDimension	AS ProductBatchAccountingDimension,
		|	TTManufacturedProduct.ProductsAccountingDimension			AS ProductsAccountingDimension,
		|	TTManufacturedProduct.ManufacturedProduct						AS ManufacturedProduct,
		|	CatProducts.Description				AS ManufacturedProductPresentation,
		|	TTManufacturedProduct.ItemVariant			AS ItemVariant,
		|	CatCharacteristics.Description				AS ItemVariantPresentation,
		|	TTManufacturedProduct.ProductionSeries_					AS ProductionSeries_,
		|	CatSetOfSeries.Description						AS ProductionSeries_Presentation,
		|	TTManufacturedProduct.AssignmentOfProducts				AS AssignmentOfProducts,
		|	CatAssignments.Description					AS AssignmentOfProductsPresentation,
		|	CatProducts.UnitOfMeasure			AS UnitOfMeasurementProducts,
		|	TTManufacturedProduct.Department					AS Department,
		|	CASE
		|		WHEN PartyAccountingAnalysts.RowCode = 0
		|			THEN FALSE
		|		ELSE TRUE
		|	END										AS ExplosionIsRequired,
		|	CASE
		|		WHEN MAX(TTManufacturedProduct.Numerator) = 0
		|			THEN 1
		|		ELSE MAX(TTManufacturedProduct.Numerator)
		|	END										AS Numerator,
		|	CASE
		|		WHEN MAX(TTManufacturedProduct.Denominator) = 0
		|			THEN 1
		|		ELSE MAX(TTManufacturedProduct.Denominator)
		|	END										AS Denominator,
		|
		// The cost according to the parameter "Data of the cost"
		|	SUM(TTManufacturedProduct.NumberOfProducts_1)		AS NumberOfProducts_1,
		|	SUM(TTManufacturedProduct.Material_)				AS Material_,
		|	SUM(TTManufacturedProduct.LaborCosts)				AS LaborCosts,
		|	SUM(TTManufacturedProduct.ItemizedFixed)	AS ItemizedFixed,
		|	SUM(TTManufacturedProduct.ItemizedVariable)	AS ItemizedVariable,
		|	SUM(TTManufacturedProduct.AddExpensesForGoods)				AS AddExpensesForGoods,
		|	SUM(TTManufacturedProduct.AmountOffBalanceSheetProducts) AS AmountOffBalanceSheetProducts,
		|	SUM(TTManufacturedProduct.TotalOutput)			AS TotalOutput,
		|	SUM(TTManufacturedProduct.AIT)						AS AIT,
		|
		// Costs with VAT
		|	SUM(TTManufacturedProduct.TangibleIncludingVAT)					AS TangibleIncludingVAT,
		|	SUM(TTManufacturedProduct.LaborCostsIncludingVAT)					AS LaborCostsIncludingVAT,
		|	SUM(TTManufacturedProduct.ItemizedFixedCostsIncludingVAT)		AS ItemizedFixedCostsIncludingVAT,
		|	SUM(TTManufacturedProduct.ItemizedVariableCostsIncludingVAT)		AS ItemizedVariableCostsIncludingVAT,
		|	SUM(TTManufacturedProduct.AdditionalExpensesIncludingVAT)					AS AdditionalExpensesIncludingVAT,
		|
		// Costs without VAT
		|	SUM(TTManufacturedProduct.TangibleExcludingVAT)				AS TangibleExcludingVAT,
		|	SUM(TTManufacturedProduct.ItemizedFixedCostsExcludingVAT)		AS ItemizedFixedCostsExcludingVAT,
		|	SUM(TTManufacturedProduct.ItemizedVariableCostsExcludingVAT)		AS ItemizedVariableCostsExcludingVAT,
		|	SUM(TTManufacturedProduct.AdditionalExpensesExcludingVAT)					AS AdditionalExpensesExcludingVAT,
		|
		// The Cost of Upr
		|	SUM(TTManufacturedProduct.MaterialMan)					AS MaterialMan,
		|	SUM(TTManufacturedProduct.LaborCostsMan)					AS LaborCostsMan,
		|	SUM(TTManufacturedProduct.ItemizedFixedCostsManag)			AS ItemizedFixedCostsManag,
		|	SUM(TTManufacturedProduct.ItemizedVariableCostsManag)			AS ItemizedVariableCostsManag,
		|	SUM(TTManufacturedProduct.AddExpensesMan)					AS AddExpensesMan,
		|	SUM(TTManufacturedProduct.CostOffBalanceSheetMan)			AS CostOffBalanceSheetMan,
		|	
		// Regl Costs
		|	SUM(TTManufacturedProduct.TangibleCompl)					AS TangibleCompl,
		|	SUM(TTManufacturedProduct.LaborCostsLocal)					AS LaborCostsLocal,
		|	SUM(TTManufacturedProduct.ItemizedFixedCostsCompl)		AS ItemizedFixedCostsCompl,
		|	SUM(TTManufacturedProduct.ItemizedVariableCostsCompl)		AS ItemizedVariableCostsCompl,
		|	SUM(TTManufacturedProduct.AddExpensesLocal)					AS AddExpensesLocal,
		|	SUM(TTManufacturedProduct.OffBalanceCostLocal)		AS OffBalanceCostLocal,
		|	
		// Tax accounting
		|	SUM(TTManufacturedProduct.TaxAccounting)					AS TaxAccounting,
		|	SUM(TTManufacturedProduct.PermanentDifference)				AS PermanentDifference,
		|	SUM(TTManufacturedProduct.CostTD)					AS CostTD
		|	
		|INTO TotalProductsProduced
		|FROM
		|	TTManufacturedProduct AS TTManufacturedProduct
		|	
		|	LEFT JOIN Catalog.Products AS CatProducts
		|		ON TTManufacturedProduct.ManufacturedProduct = CatProducts.Ref
		|	
		|	LEFT JOIN Catalog.ItemsCharacteristics AS CatCharacteristics
		|		ON TTManufacturedProduct.ItemVariant = CatCharacteristics.Ref
		|	
		|	LEFT JOIN Catalog.ItemsBatches AS CatSetOfSeries
		|		ON TTManufacturedProduct.ProductionSeries_ = CatSetOfSeries.Ref
		|	
		|	LEFT JOIN Catalog.Assignments AS CatAssignments
		|		ON TTManufacturedProduct.AssignmentOfProducts = CatAssignments.Ref
		|	
		|	LEFT JOIN InformationRegister.LotVendorAttributes AS PartyAccountingAnalysts
		|		ON TTManufacturedProduct.ProductBatchAccountingDimension = PartyAccountingAnalysts.DimensionKey
		|	
		|GROUP BY
		|	TTManufacturedProduct.NodeID,
		|	TTManufacturedProduct.Organization,
		|	CASE
		|		WHEN &Cost_Data = 3
		|			THEN TTManufacturedProduct.Organization.LocalAccountingCurrency
		|		ELSE &ManagementAccountingCurrency
		|	END,
		|	TTManufacturedProduct.ProductsBatch,
		|	TTManufacturedProduct.ProductBatchAccountingDimension,
		|	TTManufacturedProduct.ProductsAccountingDimension,
		|	TTManufacturedProduct.ManufacturedProduct,
		|	CatProducts.Description,
		|	TTManufacturedProduct.ItemVariant,
		|	CatCharacteristics.Description,
		|	TTManufacturedProduct.ProductionSeries_,
		|	CatSetOfSeries.Description,
		|	TTManufacturedProduct.AssignmentOfProducts,
		|	CatAssignments.Description,
		|	CatProducts.UnitOfMeasure,
		|	PartyAccountingAnalysts.RowCode,
		|	TTManufacturedProduct.Department
		|";
	QueriesTexts.Add(QueryText);
		
	#EndRegion
		
	#Region IssuedProducts
		
	QueryText = "
		|SELECT
		|	TTManufacturedProduct.NodeID AS NodeID,
		|	NodeSelectionTable.IdOfFirstLevelNode	AS IdOfFirstLevelNode,
		|	NodeSelectionTable.NodeOfFirstLevel_AnalyticsOfManufacturedProductAccounting AS NodeOfFirstLevel_AnalyticsOfManufacturedProductAccounting,
		|	NodeSelectionTable.NodeOfFirstLevel_LotReferenceOfManufacturedProducts AS NodeOfFirstLevel_LotReferenceOfManufacturedProducts,
		|	NodeSelectionTable.NodeOfFirstLevelIs_BatchAccountingAnalysisOfManufacturedProductsLotsVendorAttributes AS NodeOfFirstLevelIs_BatchAccountingAnalysisOfManufacturedProductsLotsVendorAttributes,
		|	ISNULL(NodeSelectionTable.OriginalBatchDate, TTManufacturedProduct.ReleaseDateOfManufacturedProducts) AS OriginalBatchDate,
		|	NodeSelectionTable.DeployAdditionalCosts AS DeployAdditionalCosts,
		|	NodeSelectionTable.ExplosionIsRequired AS SourceNodeNeedsToBeDisconnected,
		|	NodeSelectionTable.ExpenseAccountingAnalytics AS ExpenseAccountingAnalytics,
		|	
		|	TTManufacturedProduct.Organization							AS Organization,
		|	TTManufacturedProduct.Currency								AS Currency,
		|	TTManufacturedProduct.ProductsBatch						AS ProductsBatch,
		|	TTManufacturedProduct.ProductBatchAccountingDimension		AS ProductBatchAccountingDimension,
		|	TTManufacturedProduct.ProductsAccountingDimension				AS ProductsAccountingDimension,
		|	TTManufacturedProduct.ManufacturedProduct							AS ManufacturedProduct,
		|	TTManufacturedProduct.ManufacturedProductPresentation				AS ManufacturedProductPresentation,
		|	TTManufacturedProduct.ItemVariant				AS ItemVariant,
		|	TTManufacturedProduct.ItemVariantPresentation AS ItemVariantPresentation,
		|	TTManufacturedProduct.ProductionSeries_						AS ProductionSeries_,
		|	TTManufacturedProduct.ProductionSeries_Presentation			AS ProductionSeries_Presentation,
		|	TTManufacturedProduct.AssignmentOfProducts					AS AssignmentOfProducts,
		|	TTManufacturedProduct.AssignmentOfProductsPresentation	AS AssignmentOfProductsPresentation,
		|	TTManufacturedProduct.UnitOfMeasurementProducts			AS UnitOfMeasurementProducts,
		|	TTManufacturedProduct.Department						AS Department,
		|	&TypeOfCostsManufacturedProducts								AS ExpenseType,
		|	TTManufacturedProduct.ExplosionIsRequired				AS ExplosionIsRequired,
		|	TTManufacturedProduct.Numerator							AS Numerator,
		|	TTManufacturedProduct.Denominator							AS Denominator,
		|	TTManufacturedProduct.NumberOfProducts_1					AS NumberOfProducts_1,
		|
		// The cost according to the parameter "Data of the cost"
		|	TTManufacturedProduct.Material_
		|		* TTManufacturedProduct.Numerator
		|		/ TTManufacturedProduct.Denominator					AS Material_,
		|	TTManufacturedProduct.LaborCosts
		|		* TTManufacturedProduct.Numerator
		|		/ TTManufacturedProduct.Denominator					AS LaborCosts,
		|	TTManufacturedProduct.ItemizedFixed
		|		* TTManufacturedProduct.Numerator
		|		/ TTManufacturedProduct.Denominator					AS ItemizedFixed,
		|	TTManufacturedProduct.ItemizedVariable
		|		* TTManufacturedProduct.Numerator
		|		/ TTManufacturedProduct.Denominator					AS ItemizedVariable,
		|	TTManufacturedProduct.AddExpensesForGoods
		|		* TTManufacturedProduct.Numerator
		|		/ TTManufacturedProduct.Denominator					AS AddExpensesForGoods,
		|	TTManufacturedProduct.AmountOffBalanceSheetProducts
		|		* TTManufacturedProduct.Numerator
		|		/ TTManufacturedProduct.Denominator					AS AmountOffBalanceSheetProducts,
		|	TTManufacturedProduct.TotalOutput
		|		* TTManufacturedProduct.Numerator
		|		/ TTManufacturedProduct.Denominator					AS TotalOutput,
		|	TTManufacturedProduct.AIT
		|		* TTManufacturedProduct.Numerator
		|		/ TTManufacturedProduct.Denominator					AS AIT,
		|
		// Costs with VAT
		|	TTManufacturedProduct.TangibleIncludingVAT
		|		* TTManufacturedProduct.Numerator
		|		/ TTManufacturedProduct.Denominator					AS TangibleIncludingVAT,
		|	TTManufacturedProduct.LaborCostsIncludingVAT
		|		* TTManufacturedProduct.Numerator
		|		/ TTManufacturedProduct.Denominator					AS LaborCostsIncludingVAT,
		|	TTManufacturedProduct.ItemizedFixedCostsIncludingVAT
		|		* TTManufacturedProduct.Numerator
		|		/ TTManufacturedProduct.Denominator					AS ItemizedFixedCostsIncludingVAT,
		|	TTManufacturedProduct.ItemizedVariableCostsIncludingVAT
		|		* TTManufacturedProduct.Numerator
		|		/ TTManufacturedProduct.Denominator					AS ItemizedVariableCostsIncludingVAT,
		|	TTManufacturedProduct.AdditionalExpensesIncludingVAT
		|		* TTManufacturedProduct.Numerator
		|		/ TTManufacturedProduct.Denominator					AS AdditionalExpensesIncludingVAT,
		|
		// Costs without VAT
		|	TTManufacturedProduct.TangibleExcludingVAT
		|		* TTManufacturedProduct.Numerator
		|		/ TTManufacturedProduct.Denominator					AS TangibleExcludingVAT,
		|	TTManufacturedProduct.ItemizedFixedCostsExcludingVAT
		|		* TTManufacturedProduct.Numerator
		|		/ TTManufacturedProduct.Denominator					AS ItemizedFixedCostsExcludingVAT,
		|	TTManufacturedProduct.ItemizedVariableCostsExcludingVAT
		|		* TTManufacturedProduct.Numerator
		|		/ TTManufacturedProduct.Denominator					AS ItemizedVariableCostsExcludingVAT,
		|	TTManufacturedProduct.AdditionalExpensesExcludingVAT
		|		* TTManufacturedProduct.Numerator
		|		/ TTManufacturedProduct.Denominator					AS AdditionalExpensesExcludingVAT,
		|
		// The Cost of Upr
		|	TTManufacturedProduct.MaterialMan
		|		* TTManufacturedProduct.Numerator
		|		/ TTManufacturedProduct.Denominator					AS MaterialMan,
		|	TTManufacturedProduct.LaborCostsMan
		|		* TTManufacturedProduct.Numerator
		|		/ TTManufacturedProduct.Denominator					AS LaborCostsMan,
		|	TTManufacturedProduct.ItemizedFixedCostsManag
		|		* TTManufacturedProduct.Numerator
		|		/ TTManufacturedProduct.Denominator					AS ItemizedFixedCostsManag,
		|	TTManufacturedProduct.ItemizedVariableCostsManag
		|		* TTManufacturedProduct.Numerator
		|		/ TTManufacturedProduct.Denominator					AS ItemizedVariableCostsManag,
		|	TTManufacturedProduct.AddExpensesMan
		|		* TTManufacturedProduct.Numerator
		|		/ TTManufacturedProduct.Denominator					AS AddExpensesMan,
		|	TTManufacturedProduct.CostOffBalanceSheetMan
		|		* TTManufacturedProduct.Numerator
		|		/ TTManufacturedProduct.Denominator					AS CostOffBalanceSheetMan,
		|		
		// Regl Costs
		|	TTManufacturedProduct.TangibleCompl
		|		* TTManufacturedProduct.Numerator
		|		/ TTManufacturedProduct.Denominator					AS TangibleCompl,
		|	TTManufacturedProduct.LaborCostsLocal
		|		* TTManufacturedProduct.Numerator
		|		/ TTManufacturedProduct.Denominator					AS LaborCostsLocal,
		|	TTManufacturedProduct.ItemizedFixedCostsCompl
		|		* TTManufacturedProduct.Numerator
		|		/ TTManufacturedProduct.Denominator					AS ItemizedFixedCostsCompl,
		|	TTManufacturedProduct.ItemizedVariableCostsCompl
		|		* TTManufacturedProduct.Numerator
		|		/ TTManufacturedProduct.Denominator					AS ItemizedVariableCostsCompl,
		|	TTManufacturedProduct.AddExpensesLocal
		|		* TTManufacturedProduct.Numerator
		|		/ TTManufacturedProduct.Denominator					AS AddExpensesLocal,
		|	TTManufacturedProduct.OffBalanceCostLocal
		|		* TTManufacturedProduct.Numerator
		|		/ TTManufacturedProduct.Denominator					AS OffBalanceCostLocal,
		|	TTManufacturedProduct.TaxAccounting
		|		* TTManufacturedProduct.Numerator
		|		/ TTManufacturedProduct.Denominator					AS TaxAccounting,
		|	TTManufacturedProduct.PermanentDifference
		|		* TTManufacturedProduct.Numerator
		|		/ TTManufacturedProduct.Denominator					AS PermanentDifference,
		|	TTManufacturedProduct.CostTD
		|		* TTManufacturedProduct.Numerator
		|		/ TTManufacturedProduct.Denominator					AS CostTD
		|		
		|INTO IssuedProducts
		|{SELECT
		|	Organization.*,
		|	Currency.*,
		|	ProductsBatch.*,
		|	ProductBatchAccountingDimension.*,
		|	ProductsAccountingDimension.*,
		|	ManufacturedProduct.*,
		|	ManufacturedProductPresentation,
		|	ItemVariant.*,
		|	ItemVariantPresentation,
		|	ProductionSeries_.*,
		|	ProductionSeries_Presentation,
		|	AssignmentOfProducts.*,
		|	AssignmentOfProductsPresentation,
		|	UnitOfMeasurementProducts.*,
		|	Department.*,
		|	ExpenseType,
		|	ExplosionIsRequired,
		|	Numerator,
		|	Denominator,
		|	NumberOfProducts_1,
		|
		// The cost according to the parameter "Data of the cost"
		|	Material_,
		|	LaborCosts,
		|	ItemizedFixed,
		|	ItemizedVariable,
		|	AddExpensesForGoods,
		|	AmountOffBalanceSheetProducts,
		|	TotalOutput,
		|	AIT,
		|
		// Costs with VAT
		|	TangibleIncludingVAT,
		|	LaborCostsIncludingVAT,
		|	ItemizedFixedCostsIncludingVAT,
		|	ItemizedVariableCostsIncludingVAT,
		|	AdditionalExpensesIncludingVAT,
		|
		// Costs without VAT
		|	TangibleExcludingVAT,
		|	ItemizedFixedCostsExcludingVAT,
		|	ItemizedVariableCostsExcludingVAT,
		|	AdditionalExpensesExcludingVAT,
		|
		// The Cost of Upr
		|	MaterialMan,
		|	LaborCostsMan,
		|	ItemizedFixedCostsManag,
		|	ItemizedVariableCostsManag,
		|	AddExpensesMan,
		|	CostOffBalanceSheetMan,
		|	
		// Regl Costs
		|	TangibleCompl,
		|	LaborCostsLocal,
		|	ItemizedFixedCostsCompl,
		|	ItemizedVariableCostsCompl,
		|	AddExpensesLocal,
		|	OffBalanceCostLocal,
		|	
		// Tax accounting
		|	TaxAccounting,
		|	PermanentDifference,
		|	CostTD
		|}
		|FROM
		|	TotalProductsProduced AS TTManufacturedProduct
		|		INNER JOIN NodeSelectionTable AS NodeSelectionTable
		|		ON TTManufacturedProduct.NodeID = NodeSelectionTable.NodeID
		|";
		
	If PlacingIWT Then
		QueryText = QueryText + "
		|INDEX BY
		|	ProductsBatch,
		|	ProductsAccountingDimension,
		|	ProductBatchAccountingDimension,
		|	Organization,
		|	NodeID
		|" //@Query-part
	Else
		QueryText = StrReplace(QueryText, "INTO IssuedProducts", "");
		QueryText = QueryText + "
		|ORDER BY
		|	TTManufacturedProduct.ManufacturedProductPresentation,
		|	TTManufacturedProduct.ItemVariantPresentation,
		|	TTManufacturedProduct.ProductionSeries_Presentation,
		|	TTManufacturedProduct.AssignmentOfProductsPresentation,
		|	TTManufacturedProduct.ProductsBatch
		|"; //@Query-part
		
	EndIf;
	QueriesTexts.Add(QueryText);
		
	#EndRegion
	
	QueryText = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	
	Return QueryText;
	
EndFunction

Function RequestReleasedProducts(PlacingIWT, TreeParameters)
	
	ThereIsSelectionAccordingToNodeSelectionTable = TreeParameters.ReportParameters.NumberOfSelectionNodes > 0;
	 
	If TreeParameters.InteractiveSetup Then
		AdaptDCSRequest(TreeParameters.DCSchema, ThereIsSelectionAccordingToNodeSelectionTable, PlacingIWT, TreeParameters);
		TemplateComposer = New DataCompositionTemplateComposer;
		CompositionTemplate = TemplateComposer.Execute(TreeParameters.DCSchema,
			TreeParameters.DCSettings,,, Type("DataCompositionValueCollectionTemplateGenerator"));
		
		DataSet = CompositionTemplate.DataSets.Find("IssuedProducts");
		QueryOptions = CompositionTemplate.ParameterValues;
		ParameterKey = "Name";
	Else
		DataSet = TreeParameters.DCSchema.DataSets.Find("IssuedProducts");
		DataSet.Query = RequestTemplateForManufacturedProducts(ThereIsSelectionAccordingToNodeSelectionTable, PlacingIWT, TreeParameters);
		TreeParameters.ReportParameters.DecryptionOfDocumentRegisteredRecords = TreeParameters.ReportParameters.Recorders.Count() > 0;
		QueryOptions = TreeParameters.ReportParameters;
		ParameterKey = "Key";
	EndIf;
	
	QueryText = DataSet.Query;

	If ThereIsSelectionAccordingToNodeSelectionTable Then
		ArrayConnectionConditions = New Array();
		
		If Not TreeParameters.ReportParameters.ByAllCompanies Then
			ArrayConnectionConditions.Add("InventoryCost.Organization = NodeSelectionTable.Organization"); //@Query-part
		EndIf;

		If Not TreeParameters.ReportParameters.ByAllBusinessUnits Then
			ArrayConnectionConditions.Add("CatDepartments.Ref = NodeSelectionTable.Department"); //@Query-part
		EndIf;
		
		#Region VariantsOfConnectionConditionsByNodeParameters
		// See comment 204.
		
		ConnectionCondition = "DimensionKeys.Products = NodeSelectionTable.ManufacturedProduct"; //@Query-part
		If TreeParameters.VariantsOfConnectionConditionsByNodeParameters.ManufacturedProduct = 1 Then
			ArrayConnectionConditions.Add(ConnectionCondition);
		ElsIf TreeParameters.VariantsOfConnectionConditionsByNodeParameters.ManufacturedProduct = 2 Then
			ArrayConnectionConditions.Add(
				"(NodeSelectionTable.ForAllProducts OR " + ConnectionCondition + ")"); //@Query-part
		EndIf;
		
		ConnectionCondition = "InventoryCost.Lot = NodeSelectionTable.ProductsBatch"; //@Query-part
		If TreeParameters.VariantsOfConnectionConditionsByNodeParameters.ProductsBatch = 1 Then
			ArrayConnectionConditions.Add(ConnectionCondition);
		ElsIf TreeParameters.VariantsOfConnectionConditionsByNodeParameters.ProductsBatch = 2 Then
			ArrayConnectionConditions.Add(
				"NodeSelectionTable.ForAllParties OR " + ConnectionCondition + ")"); //@Query-part
		EndIf;
		
		ConnectionCondition = "DimensionKeys.Characteristic = NodeSelectionTable.ItemVariant"; //@Query-part
		If TreeParameters.VariantsOfConnectionConditionsByNodeParameters.ItemVariant = 1 Then
			ArrayConnectionConditions.Add(ConnectionCondition); 
		ElsIf TreeParameters.VariantsOfConnectionConditionsByNodeParameters.ItemVariant = 2 Then
			ArrayConnectionConditions.Add(
				"(NodeSelectionTable.AccordingToAllCharacteristics OR " + ConnectionCondition + ")"); //@Query-part
		EndIf;
		
		ConnectionCondition = "DimensionKeys.Series = NodeSelectionTable.ProductionSeries_"; //@Query-part
		If TreeParameters.VariantsOfConnectionConditionsByNodeParameters.ProductionSeries_ = 1 Then
			ArrayConnectionConditions.Add(ConnectionCondition);
		ElsIf TreeParameters.VariantsOfConnectionConditionsByNodeParameters.ProductionSeries_ = 2 Then
			ArrayConnectionConditions.Add(
				"(NodeSelectionTable.ForAllSeries OR " + ConnectionCondition + ")"); //@Query-part
		EndIf;
		
		ConnectionCondition = "DimensionKeys.Purpose = NodeSelectionTable.AssignmentOfProducts"; //@Query-part
		If TreeParameters.VariantsOfConnectionConditionsByNodeParameters.AssignmentOfProducts = 1 Then
			ArrayConnectionConditions.Add(ConnectionCondition);
		ElsIf TreeParameters.VariantsOfConnectionConditionsByNodeParameters.AssignmentOfProducts = 2 Then
			ArrayConnectionConditions.Add(
				"(NodeSelectionTable.ForAllAppointments
				| OR DimensionKeys.Purpose = VALUE(Catalog.Assignments.EmptyRef)
				| OR " + ConnectionCondition + ")"); //@Query-part
		EndIf;
		
		ConnectionCondition = "InventoryCost.LotVendorAttributes = NodeSelectionTable.ProductBatchAccountingDimension"; //@Query-part
		If TreeParameters.VariantsOfConnectionConditionsByNodeParameters.ProductBatchAccountingDimension = 1 Then
			ArrayConnectionConditions.Add(ConnectionCondition);
		ElsIf TreeParameters.VariantsOfConnectionConditionsByNodeParameters.ProductBatchAccountingDimension = 2 Then
			ArrayConnectionConditions.Add(
				"(NodeSelectionTable.AccordingToAllPartyAnalysts OR " + ConnectionCondition + ")"); //@Query-part
		EndIf;

		QueryText = StrReplace(QueryText, "&ConnectionConditions_NodeSelectionTable",
			StrConcat(ArrayConnectionConditions, Chars.LF + " And ")); //@Query-part
			
		#EndRegion
	Else
		QueryText = StrReplace(QueryText, 
			"INNER JOIN NodeSelectionTable AS NodeSelectionTable", 
			"LEFT JOIN NodeSelectionTable AS NodeSelectionTable");
		QueryText = StrReplace(QueryText, "&ConnectionConditions_NodeSelectionTable", "TRUE"); //@Query-part
	
	EndIf;
	
	Query = New Query;
	Query.TempTablesManager = TreeParameters.TempTablesManager;

	Query.Text = QueryText;
	SetCostTreeParameters(Query, QueryOptions, ParameterKey);
	Return Query;
	
EndFunction

Procedure SetCostTreeParameters(Query, QueryOptions, ParameterKey)
	
	For Each CurParameter In QueryOptions Do
		Query.SetParameter(CurParameter[ParameterKey], CurParameter.Value);
	EndDo;
	
	Query.SetParameter("TypesOfTaxationVATIsNotIncludedInCost",
		VATAccountingERP.TypesOfTaxationVATIsNotIncludedInCost());
	Query.SetParameter("TypesOfTaxationVATIsIncludedInCost",
		VATAccountingERP.ActivitiesVATIsIncludedInCost());
	
	PossibleTypesOfCostsOfCostTree = CostStructure.TypesOfCostsOfCostTree();
	For Each TypeOfCosts In PossibleTypesOfCostsOfCostTree Do
		Query.SetParameter(TypeOfCosts.Key, TypeOfCosts.Value);
	EndDo;

EndProcedure

Procedure AdaptDCSRequest(CompositionSchema, ThereIsSelectionAccordingToNodeSelectionTable, PlacingIWT, TreeParameters) Export
	
	DataSet = CompositionSchema.DataSets.Find("IssuedProducts");
	
	If DataSet = Undefined Then
		Raise NStr("vi = 'Đã thay đổi danh sách các tập dữ liệu cho sơ đồ bố trí của cây giá vốn.';
					|ru = 'Изменен перечень наборов данных схемы компоновки дерева себестоимости.';
					|en = 'List of data sets of cost tree composition schema is changed.'; fa = 'List of data sets of cost tree composition schema is changed.';
					|it = 'L''elenco dei set di dati dello schema di raccolta dell''albero del costo.';
					|pl = 'Zmieniono wykaz zbiorów danych schematu układu drzewka kosztów własnych.';
					|tr = 'Maliyet ağacı küme şemasının veri kümeleri listesi değiştirildi.'");
	Else
		If TreeParameters = Undefined Then
			TreeParameters = CostTreeParameters();
		EndIf;
		DataSet.Query = RequestTemplateForManufacturedProducts(ThereIsSelectionAccordingToNodeSelectionTable, PlacingIWT, TreeParameters);
		DataSet.Query = StrReplace(DataSet.Query, "AND &ConditionText", "");
	EndIf;
	
EndProcedure

#EndRegion

#Region StructureOfCostTree

Procedure EmptyCostTree(TreeParameters)
	
	If TreeParameters.ResultTypeValueTree Then
		TreeParameters.Result = New ValueTree;
		InitializeCostTreeFields(TreeParameters.Result, TreeParameters.FieldsStructure);
	ElsIf TreeParameters.ResultTypeTableOfValues Then
		TreeParameters.Result = New ValueTable;
		InitializeCostTreeFields(TreeParameters.Result, TreeParameters.FieldsStructure);
	EndIf;
	
EndProcedure

Procedure InitializeCostTreeFields(Result, FieldsStructure)
	
	For Each CurField In FieldsStructure Do
		If CurField.Value = Undefined Then
			Result.Columns.Add(CurField.Key);
		Else
			Result.Columns.Add(CurField.Key, CurField.Value);
		EndIf;
	EndDo;
	
EndProcedure

Function DescriptionOfTypesFromSameType(TypeName)
	TypesArray = New Array();
	TypesArray.Add(Type(TypeName));
	Return New TypeDescription(TypesArray);
EndFunction

Function StructureOfCostTreeFields()
	
	FieldsStructure = New Structure;
	
	FieldsStructure.Insert("LineKind", DescriptionOfTypesFromSameType("EnumRef.KindsOfCostTreeRows"));
	FieldsStructure.Insert("Id", DescriptionOfTypesFromSameType("UUID"));
		
	TypesArrayString = New Array;
	TypesArrayString.Add(Type("String"));
	StringTypeDetails_36 = New TypeDescription(TypesArrayString, , New StringQualifiers(36));
	FieldsStructure.Insert("IdOfFirstLevelNode", StringTypeDetails_36);
	FieldsStructure.Insert("NodeID", StringTypeDetails_36);
		
	TypesArray = New Array();
	TypesArray.Add(Type("Date"));
	DescriptionOfDateTimeTypes = New TypeDescription(TypesArray, , New DateQualifiers(DateFractions.DateTime));
	FieldsStructure.Insert("OriginalBatchDate", DescriptionOfDateTimeTypes);
	
	DescriptionOfItemAccountingAnalyticsKeysTypes = DescriptionOfTypesFromSameType(
		"CatalogRef.InventoryLocationAttributeKeys");
	FieldsStructure.Insert("ProductsAccountingDimension", DescriptionOfItemAccountingAnalyticsKeysTypes);
	FieldsStructure.Insert("AccountingDimensionFinishedProduct", DescriptionOfItemAccountingAnalyticsKeysTypes);
	
	TypesOfCostAnalytics = New Array;
	TypesOfCostAnalytics.Add(Type("CatalogRef.InventoryLocationAttributeKeys"));
	TypesOfCostAnalytics.Add(Type("CatalogRef.EmployeeWorkKinds"));
	TypesOfCostAnalytics.Add(Type("ChartOfCharacteristicTypesRef.ExpenseItems"));
	TypesOfCostAnalytics = New TypeDescription(TypesOfCostAnalytics);
	FieldsStructure.Insert("CostAccountingDimension", TypesOfCostAnalytics);
	
	TypesOfBatchAccountingAnalytics = DescriptionOfTypesFromSameType("CatalogRef.KeysForLotVendorAttributes");
	FieldsStructure.Insert("LotVendorAttributes",					TypesOfBatchAccountingAnalytics);
	FieldsStructure.Insert("ProductBatchAccountingDimension",		TypesOfBatchAccountingAnalytics);
	FieldsStructure.Insert("BatchAccountingDimensionFinishedProduct",	TypesOfBatchAccountingAnalytics);
	FieldsStructure.Insert("BatchAccountingDimensionCost",			TypesOfBatchAccountingAnalytics);
	
	FieldsStructure.Insert("Organization", DescriptionOfTypesFromSameType("CatalogRef.Companies"));
	FieldsStructure.Insert("Department", DescriptionOfTypesFromSameType("CatalogRef.BusinessStructure"));
	FieldsStructure.Insert("ExpenseType", New TypeDescription(TypesArrayString,, New StringQualifiers(255)));
	
	TypesArray = New Array();
	TypesArray.Add(Type("Boolean"));
	TypesDetailsBoolean = New TypeDescription(TypesArray);
	FieldsStructure.Insert("ExplosionIsRequired", TypesDetailsBoolean);
	FieldsStructure.Insert("ItIsRequiredToUnpackAdditionalExpenseAmount", TypesDetailsBoolean);
	
	FieldsStructure.Insert("UnitOfMeasure", DescriptionOfTypesFromSameType("CatalogRef.PackagesAndUnitsOfMeasure"));
	
	TypesOfCosts = New Array;
	TypesOfCosts.Add(Type("CatalogRef.Products"));
	TypesOfCosts.Add(Type("CatalogRef.EmployeeWorkKinds"));
	TypesOfCosts.Add(Type("ChartOfCharacteristicTypesRef.ExpenseItems"));
	TypesOfCosts.Add(Type("String"));
	TypesOfCosts = New TypeDescription(TypesOfCosts,, New StringQualifiers(255));
	FieldsStructure.Insert("Products", TypesOfCosts);
	
	FieldsStructure.Insert("Characteristic", DescriptionOfTypesFromSameType("CatalogRef.ItemsCharacteristics"));
	FieldsStructure.Insert("Series", DescriptionOfTypesFromSameType("CatalogRef.ItemsBatches"));
	FieldsStructure.Insert("Purpose", DescriptionOfTypesFromSameType("CatalogRef.Assignments"));
	FieldsStructure.Insert("Currency", DescriptionOfTypesFromSameType("CatalogRef.Currencies"));
	FieldsStructure.Insert("ProductCostElement", DescriptionOfTypesFromSameType("CatalogRef.ProductCostElements"));
	
	TypesOfBatches = New TypeDescription(Metadata.DefinedTypes.DocumentLots.Type.Types());
	FieldsStructure.Insert("Lot",					TypesOfBatches);
	FieldsStructure.Insert("ProductsBatch",			TypesOfBatches);
	FieldsStructure.Insert("BatchFinishedProduct",	TypesOfBatches);
	FieldsStructure.Insert("BatchCost",			TypesOfBatches);
	
	TypesArray = New Array();
	TypesArray.Add(Type("Number"));
	TypesDetailsNumber_15_0 = New TypeDescription(TypesArray,,, New NumberQualifiers(15, 0));
	TypesDetailsNumber_19_6 = New TypeDescription(TypesArray,,, New NumberQualifiers(19, 6));
	FieldsStructure.Insert("Level", TypesDetailsNumber_15_0);
	
	FieldsStructure.Insert("Count",			TypesDetailsNumber_19_6);
	FieldsStructure.Insert("Numerator",			TypesDetailsNumber_19_6);
	FieldsStructure.Insert("Denominator",			TypesDetailsNumber_19_6);
	
	// The cost according to the parameter "Data of the cost"
	FieldsStructure.Insert("Sum",					TypesDetailsNumber_19_6);
	FieldsStructure.Insert("OffBalanceSheetAmount",		TypesDetailsNumber_19_6);
	FieldsStructure.Insert("Material_",				TypesDetailsNumber_19_6);
	FieldsStructure.Insert("LaborCosts",				TypesDetailsNumber_19_6);
	FieldsStructure.Insert("ItemizedFixed",	TypesDetailsNumber_19_6);
	FieldsStructure.Insert("ItemizedVariable",	TypesDetailsNumber_19_6);
	FieldsStructure.Insert("AddExpensesForGoods",				TypesDetailsNumber_19_6);
	FieldsStructure.Insert("AIT",						TypesDetailsNumber_19_6);
	
	// Costs with VAT
	FieldsStructure.Insert("TangibleIncludingVAT",				TypesDetailsNumber_19_6);
	FieldsStructure.Insert("LaborCostsIncludingVAT",				TypesDetailsNumber_19_6);
	FieldsStructure.Insert("ItemizedFixedCostsIncludingVAT",	TypesDetailsNumber_19_6);
	FieldsStructure.Insert("ItemizedVariableCostsIncludingVAT", 	TypesDetailsNumber_19_6);
	FieldsStructure.Insert("AdditionalExpensesIncludingVAT",				TypesDetailsNumber_19_6);
	
	// Costs without VAT
	FieldsStructure.Insert("TangibleExcludingVAT",			TypesDetailsNumber_19_6);
	FieldsStructure.Insert("ItemizedFixedCostsExcludingVAT",	TypesDetailsNumber_19_6);
	FieldsStructure.Insert("ItemizedVariableCostsExcludingVAT",	TypesDetailsNumber_19_6);
	FieldsStructure.Insert("AdditionalExpensesExcludingVAT",				TypesDetailsNumber_19_6);
	
	// The Cost of Upr
	FieldsStructure.Insert("MaterialMan",				TypesDetailsNumber_19_6);
	FieldsStructure.Insert("LaborCostsMan",				TypesDetailsNumber_19_6);
	FieldsStructure.Insert("ItemizedFixedCostsManag",		TypesDetailsNumber_19_6);
	FieldsStructure.Insert("ItemizedVariableCostsManag",		TypesDetailsNumber_19_6);
	FieldsStructure.Insert("AddExpensesMan",				TypesDetailsNumber_19_6);
	FieldsStructure.Insert("CostOffBalanceSheetMan",		TypesDetailsNumber_19_6);
	
	// Regl Costs
	FieldsStructure.Insert("TangibleCompl",				TypesDetailsNumber_19_6);
	FieldsStructure.Insert("LaborCostsLocal",				TypesDetailsNumber_19_6);
	FieldsStructure.Insert("ItemizedFixedCostsCompl",	TypesDetailsNumber_19_6);
	FieldsStructure.Insert("ItemizedVariableCostsCompl",	TypesDetailsNumber_19_6);
	FieldsStructure.Insert("AddExpensesLocal",				TypesDetailsNumber_19_6);
	FieldsStructure.Insert("OffBalanceCostLocal",	TypesDetailsNumber_19_6);
	
	// Tax accounting
	FieldsStructure.Insert("TaxAccounting",				TypesDetailsNumber_19_6);
	FieldsStructure.Insert("PermanentDifference",			TypesDetailsNumber_19_6);
	FieldsStructure.Insert("CostTD",				TypesDetailsNumber_19_6);
	
	Return FieldsStructure;
	
EndFunction

Function EmptyNodeSelectionTable(FieldsStructure)
	NodeSelectionTable = New ValueTable();

	TypesDetailsBoolean = DescriptionOfTypesFromSameType("Boolean");
	TypesArray = New Array();
	TypesArray.Add(Type("Date"));
	DescriptionOfDateTimeTypes = New TypeDescription(TypesArray, , New DateQualifiers(DateFractions.DateTime));

	NodeSelectionTable.Columns.Add("IdOfFirstLevelNode", 
		FieldsStructure.IdOfFirstLevelNode);
	
	NodeSelectionTable.Columns.Add("Level", FieldsStructure.Level);
	
	NodeSelectionTable.Columns.Add("NodeOfFirstLevel_AnalyticsOfManufacturedProductAccounting",
		FieldsStructure.ProductsAccountingDimension);
	NodeSelectionTable.Columns.Add("NodeOfFirstLevel_LotReferenceOfManufacturedProducts", FieldsStructure.ProductsBatch);
	NodeSelectionTable.Columns.Add("NodeOfFirstLevelIs_BatchAccountingAnalysisOfManufacturedProductsLotsVendorAttributes",
		FieldsStructure.ProductBatchAccountingDimension);
	
	NodeSelectionTable.Columns.Add("NodeID", FieldsStructure.NodeID);

	NodeSelectionTable.Columns.Add("Organization", FieldsStructure.Organization);
	NodeSelectionTable.Columns.Add("Department", FieldsStructure.Department);
	TypesArray = New Array();
	TypesArray.Add(Type("Number"));
	NodeSelectionTable.Columns.Add("Cost_Data",
		New TypeDescription(TypesArray, , New NumberQualifiers(1, 0, AllowedSign.Nonnegative)));
	NodeSelectionTable.Columns.Add("StartDate", DescriptionOfDateTimeTypes);
	NodeSelectionTable.Columns.Add("EndDate", DescriptionOfDateTimeTypes);
	NodeSelectionTable.Columns.Add("Recorder",
		Metadata.AccumulationRegisters.InventoryCost.StandardAttributes.Recorder.Type);

	NodeSelectionTable.Columns.Add("DeployAdditionalCosts", TypesDetailsBoolean);
	NodeSelectionTable.Columns.Add("ExplosionIsRequired", TypesDetailsBoolean);
	NodeSelectionTable.Columns.Add("ForAllProducts", TypesDetailsBoolean);
	NodeSelectionTable.Columns.Add("ManufacturedProduct", DescriptionOfTypesFromSameType("CatalogRef.Products"));
	NodeSelectionTable.Columns.Add("AccordingToAllCharacteristics", TypesDetailsBoolean);
	NodeSelectionTable.Columns.Add("ItemVariant",
		New TypeDescription("CatalogRef.ItemsCharacteristics"));
	NodeSelectionTable.Columns.Add("ForAllSeries", TypesDetailsBoolean);
	NodeSelectionTable.Columns.Add("ProductionSeries_",
		DescriptionOfTypesFromSameType("CatalogRef.ItemsBatches"));
	NodeSelectionTable.Columns.Add("AssignmentOfProducts",
		DescriptionOfTypesFromSameType("CatalogRef.Assignments"));
	NodeSelectionTable.Columns.Add("ForAllAppointments", TypesDetailsBoolean);
	NodeSelectionTable.Columns.Add("ForAllParties", TypesDetailsBoolean);
	NodeSelectionTable.Columns.Add("ProductsBatch", FieldsStructure.ProductsBatch);
	NodeSelectionTable.Columns.Add("AccordingToAllPartyAnalysts", TypesDetailsBoolean);
	NodeSelectionTable.Columns.Add("ProductBatchAccountingDimension", FieldsStructure.ProductBatchAccountingDimension);
	NodeSelectionTable.Columns.Add("ExpenseAccountingAnalytics",
		DescriptionOfTypesFromSameType("CatalogRef.InventoryLocationAttributeKeys"));
	
	NodeSelectionTable.Columns.Add("BatchCost", FieldsStructure.ProductsBatch);
		
	NodeSelectionTable.Columns.Add("Numerator", FieldsStructure.Numerator);
	NodeSelectionTable.Columns.Add("Denominator", FieldsStructure.Denominator);
	NodeSelectionTable.Columns.Add("ProductsQuantity", FieldsStructure.Count);
	
	NodeSelectionTable.Columns.Add("ManagementAccountingCurrency", New TypeDescription("CatalogRef.Currencies"));
	NodeSelectionTable.Columns.Add("AccountingDimensionFinishedProduct", FieldsStructure.AccountingDimensionFinishedProduct);
	NodeSelectionTable.Columns.Add("ProductCostElement", FieldsStructure.ProductCostElement);
	

	NodeSelectionTable.Columns.Add("OriginalBatchDate", DescriptionOfDateTimeTypes);
	NodeSelectionTable.Columns.Add("DateOfOriginalLotReference_BeginningOfMonth", DescriptionOfDateTimeTypes);
	NodeSelectionTable.Columns.Add("DateOfOriginalLotReference_EndOfMonth", DescriptionOfDateTimeTypes);
	NodeSelectionTable.Columns.Add("IncludePersonalIncomeTaxCost", TypesDetailsBoolean);
	NodeSelectionTable.Columns.Add("ExcludeVATFromCost", TypesDetailsBoolean);
	
	// In order to calculate the difference between the upper-level node and the total for the lower-level nodes,
	// add the sums to the selection lines by level.
	NodeSelectionTable.Columns.Add("Sum", FieldsStructure.Sum);
	NodeSelectionTable.Columns.Add("Material_", FieldsStructure.Material_);
	NodeSelectionTable.Columns.Add("AddExpensesForGoods", FieldsStructure.AddExpensesForGoods);
	NodeSelectionTable.Columns.Add("LaborCosts", FieldsStructure.LaborCosts);
	NodeSelectionTable.Columns.Add("ItemizedVariable", FieldsStructure.ItemizedVariable);
	NodeSelectionTable.Columns.Add("ItemizedFixed", FieldsStructure.ItemizedFixed);
	NodeSelectionTable.Columns.Add("TaxAccounting", FieldsStructure.TaxAccounting);
	NodeSelectionTable.Columns.Add("PermanentDifference", FieldsStructure.PermanentDifference);
	NodeSelectionTable.Columns.Add("CostTD", FieldsStructure.CostTD);
	NodeSelectionTable.Columns.Add("OffBalanceSheetAmount", FieldsStructure.OffBalanceSheetAmount);
	
	NodeSelectionTable.Columns.Add("AmountInclusionExclusionOfVATInCost", FieldsStructure.OffBalanceSheetAmount);
	
	Return NodeSelectionTable;
EndFunction

#EndRegion

#EndRegion
