
#Region Public

#Region ActualDataQueryRules

// Returns the names of metrics and corresponding fields from the source schema
// 
// Parameters:
//	DataCompositionSchema - DataCompositionSchema - the data source schema, which contains a data set of the "Union" type named " United Fact"
//	Rule - CatalogRef.ActualDataQueryRulesByBudgetBalanceItems, CatalogRef.ActualDataQueryRulesByBudgetFlowItems - rule for getting actual data.
//
// Returns:
//	Structure - compared fact indicators and data source fields:
//		* Key     - String - name of the actual data metric
//		* Value - String - the name of the field in the data source schema.
// 
Function SourcesAndRules(DataCompositionSchema, Rule) Export
	
	SourcesOfSum = New Structure;
	
	DataSet = DataCompositionSchema.DataSets.Find("CombinedFact");
	If DataSet = Undefined Then
		If DataCompositionSchema.DataSets.Count() > 0 Then
			DataSet = DataCompositionSchema.DataSets[0];
		Else 
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không có một dữ liệu nào được đặt trong ACS của quy tắc ""%1"".';
					|ru = 'В СКД правила ""%1"" нет ни одного набора данных.';
					|en = 'There are no data sets in the ""%1"" rule DCS.'; fa = 'There are no data sets in the ""%1"" rule DCS.';
					|it = 'Non esiste un singolo ""%1"" set di dati nel Sistema di composizione dei dati layout.';
					|pl = 'W SKD reguły ""%1"" brak żadnego kompletu danych.';
					|tr = 'Veri Oluşturma Sistemi''nde ""%1"" kuralı tek bir veri kümesi değil.'"), 
				Rule);
			Raise MessageText;
		EndIf;
	EndIf;
		
	If Common.IsReference(TypeOf(Rule)) Then
		RuleDetails = Common.ObjectAttributesValues(Rule, 
			"NameOfTheDataSourceTemplate, 
			|DataSourceSection, 
			|TransactionAmountSource, 
			|SourceOfForeignExchange, 
			|DataSource, 
			|RuleType, 
			|TotalType");
	Else
		RuleDetails = Rule;
	EndIf;
	
	DataSetName = RuleDetails.NameOfTheDataSourceTemplate; // The data set name corresponds to the operation case
	
	If RuleDetails.DataSourceSection = Enums.SectionsOfBudgetingDataSources.OperationalAccounting Then
		If GetFunctionalOption("SetUpRulesForObtainingActualDataByAssetAndLiabilityItems") Then
			RuleOnItemOfAssetsLiabilities = ThisIsItemOfAssetsLiabilities(RuleDetails.DataSource);
		Else
			RuleOnItemOfAssetsLiabilities = False;
		EndIf;
		If RuleOnItemOfAssetsLiabilities Then
			RegisterIndicators = DataSourcesCached.IndicatorsOfSumOfItemOfAssetsLiabilities(RuleDetails.DataSource);
		Else
			RegisterIndicators = FinancialAccountingServerCached.Indicators(DataSetName);
		EndIf;
		SumSourceResources = RegisterIndicators.Get(RuleDetails.TransactionAmountSource).Resources;
		If SumSourceResources = Undefined Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đối với nguồn của số tiền %1 của giao dịch kinh doanh %2 không tìm thấy tài nguyên phù hợp trong nguồn dữ liệu.';
					|ru = 'Для источника суммы %1 хозяйственной операции %2 не найдены соответствующие ресурсы в источнике данных.';
					|en = 'Corresponding resources are not found in the data source for the source of amount %1 of business transaction %2.'; fa = 'Corresponding resources are not found in the data source for the source of amount %1 of business transaction %2.';
					|it = 'Per la fonte della somma %1 della transazione commerciale %2 non sono state trovate le risorse corrispondenti nella sorgente dei dati.';
					|pl = 'Dla źródła wartości %1 operacji gospodarczej %2 nie znaleziono odpowiednich zasobów w źródle danych.';
					|tr = '%1 tutar kaynağı için %2 ticari işlemindeki veri kaynaklarında ilgili kaynaklar bulunamadı.'"), 
				RuleDetails.TransactionAmountSource, 
				RuleDetails.DataSource);
			Raise MessageText;
		EndIf;
		
		For Each Resource In SumSourceResources Do
			If RuleOnItemOfAssetsLiabilities Then
				AmountField = BudgetingServer.AccountingResourceField(Resource["Name"], RuleDetails.TotalType);
			Else
				AmountField = Resource["Name"];
			EndIf;
			If DataSet.Fields.Find(AmountField) = Undefined Then
				// The resource is not selected in the source
				Continue;
			EndIf;
			If Resource["SourceOfCurrency"] = "CurrencyOfMan" Then
				SourcesOfSum.Insert("Man", AmountField);
			ElsIf Resource["SourceOfCurrency"] = "ComplCurrency" Then
				SourcesOfSum.Insert("Compl", AmountField);
			Else
				SourcesOfSum.Insert("Currency", AmountField);
			EndIf;
		EndDo;
		
	ElsIf RuleDetails.DataSourceSection = Enums.SectionsOfBudgetingDataSources.LocalAccounting Then
		SourcesOfSum.Insert("Compl", BudgetingServer.AccountingResourceField("Sum", RuleDetails.TotalType));
		SourcesOfSum.Insert("Man", BudgetingServer.AccountingResourceField("AmountOfUU", RuleDetails.TotalType));
		If RuleDetails.SourceOfForeignExchange Then
			SourcesOfSum.Insert("Currency", BudgetingServer.AccountingResourceField("AmountInCurrency", RuleDetails.TotalType));
		EndIf;
	ElsIf RuleDetails.DataSourceSection = Enums.SectionsOfBudgetingDataSources.FinancialAccounting Then
		SourcesOfSum.Insert("International_", BudgetingServer.AccountingResourceField("Sum", RuleDetails.TotalType));
		If RuleDetails.SourceOfForeignExchange Then
			SourcesOfSum.Insert("Currency", BudgetingServer.AccountingResourceField("AmountInCurrency", RuleDetails.TotalType));
		EndIf;
		
	ElsIf RuleDetails.DataSourceSection = Enums.SectionsOfBudgetingDataSources.CustomQuery Then
		BudgetingServer.FillInSourcesOfAmountAccordingToScheme(SourcesOfSum, DataSet.Items[DataSetName]);
	EndIf;
	
	Return SourcesOfSum;
	
EndFunction

// Convolves columns of the same type in the table of values into a single column with data transfer.
// For example, it allows multiple Analytic1 columns..6 collapse into one column of Analytics.
// Names of collapsible columns must consist of two (three) parts-ColumnName + (prefix Identifier)+ID.
// 
// Parameters:
//	DataTable         - ValueTable - the table whose columns will be collapsed
//		After the convolution, the table will contain the following columns:
//			Columns not specified in the measurement columns
//			Columns specified in the measurement columns, but folded from several into one
//			Columns specified in the columnaggregates with summed data.
//	MeasurementColumns_      - String, Array - comma-separated column names that will collapse the table based on their unique values. 
//		After the convolution, the columns will be deleted.
//	IDs        - Array - string identifiers by which columns will be collapsed and which are contained in the column names. 
//		For example, a unique identifier or a column sequence number.
//	IDPrefix - String - prefix to be used as part of the identifier
//	ColumnsAggregates       - String, Array - change of columns separated by commas, the values of which will be summed during convolution.
//	FuzzyMatchingOfIdentifiers - Boolean - Flag for fuzzy matching of identifiers
//
Procedure CollapseByIDColumns(DataTable, MeasurementColumns_, IDs, IDPrefix = "", ColumnsAggregates = Undefined, FuzzyMatchingOfIdentifiers = False) Export
	
	#Region Initialize
	
	SourceColumns_ = DataTable.Columns;
	NontransformableMeasurements = New Array;
	
	DCSConvolution = DataCompositionServer.EmptyCircuit();
	TotalFields = DCSConvolution.TotalFields;
	
	#EndRegion 
	
	#Region CheckingParameterTypes
	
	If TypeOf(MeasurementColumns_) = Type("String") Then
		// Remove the spaces and form a list of names
		DimensionColumnNames = StrSplit(StrReplace(MeasurementColumns_, " ", ""), ",");
	ElsIf TypeOf(MeasurementColumns_) = Type("Array") Then
		DimensionColumnNames = MeasurementColumns_;
	Else
		Raise NStr("vi = 'Không hợp lệ loại tham số 2';
					|ru = 'Некорректный тип параметра 2';
					|en = 'Incorrect type of parameter 2'; fa = 'Incorrect type of parameter 2';
					|it = 'Tipo del parametro 2 non valido';
					|pl = 'Niepoprawny typ parametru 2';
					|tr = 'Yanlış parametre türü 2'") ;
	EndIf;
	
	If TypeOf(ColumnsAggregates) = Type("String") Then
		// Remove the spaces and form a list of names
		AggregateColumnNames = StrSplit(StrReplace(ColumnsAggregates, " ", ""), ",");
	ElsIf TypeOf(ColumnsAggregates) = Type("Array") Then
		AggregateColumnNames = ColumnsAggregates;
	ElsIf TypeOf(ColumnsAggregates) = Type("Undefined") Then
		AggregateColumnNames = New Array;
	Else
		Raise NStr("vi = 'Không hợp lệ loại tham số 4';
					|ru = 'Некорректный тип параметра 4';
					|en = 'Incorrect type of parameter 4'; fa = 'Incorrect type of parameter 4';
					|it = 'Tipo del parametro 4 non valido';
					|pl = 'Niepoprawny typ parametru 4';
					|tr = 'Yanlış parametre türü 4'") ;
	EndIf;
	
	If Not TypeOf(IDs) = Type("Array") Then
		Raise NStr("vi = 'Không hợp lệ loại tham số 5';
					|ru = 'Некорректный тип параметра 5';
					|en = 'Incorrect type of parameter 5'; fa = 'Incorrect type of parameter 5';
					|it = 'Tipo del parametro 5 non valido';
					|pl = 'Niepoprawny typ parametru 5';
					|tr = 'Yanlış parametre türü 5'") ;
	EndIf;
	
	#EndRegion

	LBDataTable = DataCompositionServer.AddEmptyDataSet(DCSConvolution, 
		Type("DataCompositionSchemaDataSetObject"), "DataTable");

	#Region AddingSourceFieldsToDataset
	
	For Each SourceColumn In SourceColumns_ Do
		ColumnName = SourceColumn.Name;
		FinancialReportingServer.NewSetField(LBDataTable, ColumnName, ColumnName, , SourceColumn.ValueType);
		
		NontransformableMeasurements.Add(ColumnName);
	EndDo;
	
	#EndRegion 

	#Region AddingNewDimensionFields
		
	ElementsOfFieldConvolutionExpression = New Array;
	
	For Each NameOfMeasurementColumn In DimensionColumnNames Do
		
		ElementsOfFieldConvolutionExpression.Add("CASE"); //@Query-part
		
		For Each UUID In IDs Do 
			
			SourceFieldName = NameOfMeasurementColumn + IDPrefix + UUID;
			
			If FuzzyMatchingOfIdentifiers And SourceColumns_.Find(SourceFieldName) = Undefined Then // More identifiers can be passed than there are columns
				Continue;
			EndIf;
			
			ElementsOfFieldConvolutionExpression.Add("WHEN " + "ValueIsFilled(" + SourceFieldName + ")" + Chars.LF
			+ "THEN " + SourceFieldName);
			
			FieldIndex = NontransformableMeasurements.Find(SourceFieldName);
			If Not FieldIndex = Undefined Then
				NontransformableMeasurements.Delete(FieldIndex);
			EndIf;
		EndDo;
		
		ElementsOfFieldConvolutionExpression.Add("END");
		
		FieldConvolutionExpression = StrConcat(ElementsOfFieldConvolutionExpression, Chars.LF);
		FinancialReportingServer.NewCalculatedField(DCSConvolution, NameOfMeasurementColumn, FieldConvolutionExpression, , True);
		
		ElementsOfFieldConvolutionExpression.Clear();
		
	EndDo;
	
	#EndRegion 
	
	#Region AddingNewAggregateFields
	
	For Each AggregateColumnName In AggregateColumnNames Do
		
		AggregateExpression = "ISNULL(" 
		+ "CASE WHEN ValueIsFilled(" + AggregateColumnName + ") THEN " + AggregateColumnName + " ELSE 0 END" + ", 0)";
		
		FinancialReportingServer.NewCalculatedField(DCSConvolution, AggregateColumnName, AggregateExpression, , True);
		
		If TotalFields.Find(AggregateColumnName) = Undefined Then
			FinancialReportingServer.NewResource(DCSConvolution, AggregateColumnName, "Sum");
		EndIf;
		
		FieldIndex = NontransformableMeasurements.Find(AggregateColumnName);
		If Not FieldIndex = Undefined Then
			NontransformableMeasurements.Delete(FieldIndex);
		EndIf;
		
	EndDo;
	
	#EndRegion 
	
	#Region CreatingSettings
	
	// Create and initialize the linker
	ConvolutionSettings = BudgetingServer.InitializedDefaultSettings(DCSConvolution);
	
	DataCompositionClientServer.DisableOutputOfTotals(ConvolutionSettings);
	
	RootElementOfStructure = ConvolutionSettings.Structure;
	
	DataGroup2 = FinancialReportingServer.NewGrouping(RootElementOfStructure);
	
	For Each ColumnName In NontransformableMeasurements Do 
		
		FinancialReportingServer.NewDimensionField(DataGroup2, ColumnName);
		
	EndDo;
	
	For Each ColumnName In DimensionColumnNames Do
		
		FinancialReportingServer.NewDimensionField(DataGroup2, ColumnName);
		
	EndDo;
	
	For Each ColumnName In AggregateColumnNames Do
		
		FinancialReportingServer.NewSelectionField(ConvolutionSettings, ColumnName);
	
	EndDo;
	
	#EndRegion 
	
	#Region GettingCollapsedTable
	
	// Initialize the layout layout, which will be stored in the cache and executed
	DataAcquisitionTemplate = FinancialReportingServer.PrepareLayoutTemplateForUploadingDCS(DCSConvolution, ConvolutionSettings);
	
	// Execute a processor output to a collection of values
	ExternalDataSets = New Structure("DataTable", DataTable);
	DataTable = FinancialReportingServer.UploadDCSResultsFromTemplate(DataAcquisitionTemplate, ExternalDataSets);
	
	#EndRegion 
	
EndProcedure

// Returns the schema for the rule for getting actual data
// 
// Parameters:
//	RuleDescription_ - CatalogRef.ActualDataQueryRulesByBudgetBalanceItems, 
//	                - CatalogRef.ActualDataQueryRulesByBudgetFlowItems,
//	                - QueryResultSelection, ValueTableRow, Structure - The rule for obtaining a fact based on budget indicators.
//	ClearedCollectionsOfSettings - Map - names of collections that are guaranteed to be cleared. If the value is filled in, a copy of the SKD will be received.
//	                           - Undefined - The default value. The settings are not cleared.
//	DataReceiptMode - EnumRef.BudgetingDataReceiptMode - 
//	                                  All - in this case, the word ALLOWED is removed from data layout schema queries. A copy of the SKD will be returned.
//	                                  Allowed-in this case, the scheme is executed as is.
//	                       If the value is filled in, a copy of the SKD will be received.
//	                     - Undefined - The default value. The text of the request does not change.
//	GettingCopyForChanges  - Boolean - False by default. If True, a copy of the SKD will be returned.
//	CorrespondencesTable - ValueTable - table of actual data based on correspondence of balance registers.
// 
// Returns:
//	DataCompositionSchema - The schema of the data collection is a scheme for obtaining the actual data corresponding to the source.
//
Function DataLayoutRules(RuleDescription_, ClearedCollectionsOfSettings = Undefined, DataReceiptMode = Undefined, GettingCopyForChanges = False, CorrespondencesTable = Undefined) Export
	
	// We get the scheme of the rule
	TypeOfRuleDescription = TypeOf(RuleDescription_);
	
	If Common.IsReference(TypeOfRuleDescription) Then
		If TypeOfRuleDescription = Type("CatalogRef.ActualDataQueryRulesByBudgetFlowItems") Then
			RuleDetails = Common.ObjectAttributesValues(RuleDescription_,
				"Ref, DataSourceSection, DataSource, CorDataSource, HashOfDataCompositionSchema, TransactionAmountSource, TotalType, RuleType");
		Else
			RuleDetails = Common.ObjectAttributesValues(RuleDescription_,
				"Ref, DataSourceSection, DataSource, HashOfDataCompositionSchema, TransactionAmountSource");
		EndIf;
		RuleDetails.Insert("DataSourceObjectType", TypeOf(RuleDetails.Ref));
	ElsIf TypeOfRuleDescription = Type("ValueTableRow") Or TypeOfRuleDescription = Type("Structure") Then
		RuleDetails = RuleDescription_;
	ElsIf TypeOfRuleDescription = Type("FormDataStructure") 
		Or Not Common.IsReference(TypeOfRuleDescription) Then // Rule Object
		RuleDetails = New Structure(
			"Ref, DataSourceSection, DataSource, CorDataSource, HashOfDataCompositionSchema, TransactionAmountSource, TotalType, RuleType");
		FillPropertyValues(RuleDetails, RuleDescription_);
		RuleDetails.Insert("DataSourceObjectType", TypeOf(RuleDetails.Ref));
	EndIf;
	
	If RuleDetails.DataSourceSection = Enums.SectionsOfBudgetingDataSources.CustomQuery Then
		ArbitraryDataInSource = True;
	Else
		ArbitraryDataInSource = False;
	EndIf;
	
	SupportedObjectTypes = DataSourcesCached.SupportedCatalogDataSources();
	
	SourceCatalogName = SupportedObjectTypes[RuleDetails.DataSourceObjectType];
	
	If SourceCatalogName = Undefined Then
		Raise NStr("vi = 'Loại không hợp lệ của nguồn dữ liệu danh mục.';
					|ru = 'Недопустимый тип справочника-источника получения данных.';
					|en = 'Invalid type of the catalog-data source.'; fa = 'Invalid type of the catalog-data source.';
					|it = 'Tipo di origine dati non valido.';
					|pl = 'Niedopuszczalny typ katalogu-źródła pobierania danych.';
					|tr = 'Veri alım katalog kaynağının kabul edilemeyecek türü.'");
	EndIf;
	
	If RuleDetails.DataSourceSection = Enums.SectionsOfBudgetingDataSources.OperationalAccounting Then
		If CommonClientServer.HasAttributeOrObjectProperty(RuleDetails, "CorrespondencesTable") Then
			CorrespondencesTable = RuleDetails.CorrespondencesTable;
		EndIf;
		If SourceCatalogName = "ActualDataQueryRulesByBudgetFlowItems"
			And (Not CommonClientServer.HasAttributeOrObjectProperty(RuleDetails, "TypeOfAccountingDataReceipt")
			Or Not CommonClientServer.HasAttributeOrObjectProperty(RuleDetails, "TypeOfAccountingDataExpense")) Then
			If ThisIsSettingUpBusinessOfOperation(RuleDetails.DataSource) Then
				AccountingDataTypes = Common.ObjectAttributesValues(RuleDetails.DataSource,
					"Receipt, Expense");
				RuleDetails.Insert("TypeOfAccountingDataReceipt", AccountingDataTypes.Receipt);
				RuleDetails.Insert("TypeOfAccountingDataExpense", AccountingDataTypes.Expense);
			Else
				DataSources = New Array();
				If ValueIsFilled(RuleDetails.DataSource) Then
					DataSources.Add(RuleDetails.DataSource);
				EndIf;
				If ValueIsFilled(RuleDetails.CorDataSource) Then
					DataSources.Add(RuleDetails.CorDataSource);
				EndIf;
				If DataSources.Count() > 0 Then
					AccountingDataTypes = Common.ObjectsAttributeValue(DataSources, "TypeOfAccountingData");
				EndIf;
				If RuleDetails.TotalType = Enums.TypesOfTotals.TurnoverCr Then
					TypeOfAccountingDataExpense = ?(
						ValueIsFilled(RuleDetails.DataSource),
						AccountingDataTypes[RuleDetails.DataSource],
						Enums.AccountingDataTypes.EmptyRef());
					TypeOfAccountingDataReceipt = ?(
						ValueIsFilled(RuleDetails.CorDataSource),
						AccountingDataTypes[RuleDetails.CorDataSource],
						Enums.AccountingDataTypes.EmptyRef());
				Else
					TypeOfAccountingDataReceipt = ?(
						ValueIsFilled(RuleDetails.DataSource),
						AccountingDataTypes[RuleDetails.DataSource],
						Enums.AccountingDataTypes.EmptyRef());
					TypeOfAccountingDataExpense = ?(
						ValueIsFilled(RuleDetails.CorDataSource),
						AccountingDataTypes[RuleDetails.CorDataSource],
						Enums.AccountingDataTypes.EmptyRef());
				EndIf;
				RuleDetails.Insert("TypeOfAccountingDataReceipt", TypeOfAccountingDataReceipt);
				RuleDetails.Insert("TypeOfAccountingDataExpense", TypeOfAccountingDataExpense);
			EndIf;
		EndIf;
	EndIf;
	
	If CorrespondencesTable <> Undefined Then
		If ValueIsFilled(RuleDescription_.DataSource) Then
			DataLayoutRules = DataCompositionSchemaAccordingToCorrespondenceTableOfRegisters(
				CorrespondencesTable);
		Else
			DataLayoutRules = Undefined;
		EndIf;
		
	ElsIf Not ArbitraryDataInSource Then
		UsedSKD_BudgetExecution = False;
		
		If SourceCatalogName = "ActualDataQueryRulesByBudgetFlowItems" Then
			If RuleDetails.DataSourceSection = Enums.SectionsOfBudgetingDataSources.OperationalAccounting
				And RuleDetails.RuleType = Enums.ActualBudgetingDataQueryRuleType.BudgetFulfillment Then
				UsedSKD_BudgetExecution = DataSourcesCached.UsedSKD_BudgetExecution(
					RuleDetails.TransactionAmountSource, RuleDetails.TypeOfAccountingDataExpense);
			EndIf;
		EndIf;
		
		If UsedSKD_BudgetExecution Then
			DataLayoutRules = DataSourcesCached.DCS_BudgetFulfillment(
				RuleDetails.TypeOfAccountingDataExpense, RuleDetails.TypeOfAccountingDataReceipt);
		ElsIf Catalogs[SourceCatalogName].RuleOnItemOfAssetsLiabilities(RuleDetails) Then
			If Not ValueIsFilled(RuleDescription_.DataSource) Then
				DataLayoutRules = Undefined;
			ElsIf SourceCatalogName = "ActualDataQueryRulesByBudgetBalanceItems" Then
				If ChartsOfCharacteristicTypes.AssetLiabilityItems.ThisIsCustomArticle(RuleDetails.DataSource) Then
					DataLayoutRules = DataSourcesCached.DataLayoutRules(SourceCatalogName,
						RuleDetails.DataSourceSection, RuleDetails.DataSource);
				Else
					DataLayoutRules = DataCompositionSchemaOfFactIndicatorForItemAssetsLiabilities(RuleDetails);
				EndIf;
			ElsIf Not ValueIsFilled(RuleDetails.CorDataSource) Then
				DataLayoutRules = DataCompositionSchemaOfFactOfArticleAccordingToArticleOfAssetsLiabilities(RuleDetails);
			Else
				DataLayoutRules = DataCompositionSchemaOfFactOfArticleByCorrespondenceOfArticlesOfAssetsLiabilities(RuleDetails);
			EndIf;
		Else
			DataLayoutRules = DataSourcesCached.DataLayoutRules(SourceCatalogName,
				RuleDetails.DataSourceSection, RuleDetails.DataSource);
		EndIf;
		
	Else // Arbitrary schema in the data source 
		DataLayoutRules =
			DataSourcesCached.ArbitraryDataLayoutSchemeRules(
				SourceCatalogName, 
				RuleDetails.DataSourceSection,
				RuleDetails.HashOfDataCompositionSchema);
		
	EndIf;
	
	// If the schema changes and there is no goal to write the modified schema to the cached module, then we get a copy.
	ReturnCopyOfSchema = GettingCopyForChanges
		Or Not ClearedCollectionsOfSettings = Undefined
		Or DataReceiptMode = Enums.BudgetingDataReceiptMode.All;
	
	If ReturnCopyOfSchema
		And DataLayoutRules <> Undefined Then
		DataLayoutRules = DataCompositionServer.CopyDataLayoutDiagram(DataLayoutRules);
	EndIf;
	
	If DataLayoutRules = Undefined Then
		If RuleDetails.DataSourceSection = Enums.SectionsOfBudgetingDataSources.OperationalAccounting
			And ValueIsFilled(RuleDetails.DataSource) Then
			
			DefaultSchemaNames = DataSourcesCached.DefaultSchemaNamesForDataSources();
			DefaultSchemaName = DefaultSchemaNames[SourceCatalogName];
			
			ErrorMessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không có sơ đồ thu thập dữ liệu được xác định cho quy tắc ""%1"" và nguồn ""%2"".';
					|ru = 'Для правила ""%1"" и источника ""%2"" не определена схема получения данных.';
					|en = 'Data receipt scheme is not determined for the ""%1"" rule and the ""%2"" source.'; fa = 'Data receipt scheme is not determined for the ""%1"" rule and the ""%2"" source.';
					|it = 'Per la regola ""%1""e l''origine ""%2"" non è definito uno schema di recupero dati.';
					|pl = 'Dla reguły ""%1"" i źródła ""%2"" nie jest określony schemat pobierania danych.';
					|tr = '""%1"" kuralı ve ""%2"" kaynağı için Veri Oluşturma Sistemi belirtilmemiş.'"), 
				?(TypeOfRuleDescription = Type("ValueTableRow"), RuleDetails.Rule, RuleDetails.Ref),
				RuleDescription_.DataSource);
					
			If Not ValueIsFilled(DefaultSchemaName) Then
				
				Raise ErrorMessageText;
				
			EndIf;
			
			DataLayoutRules = Catalogs[SourceCatalogName].GetTemplate(DefaultSchemaName);
			
			If DataLayoutRules = Undefined Then
				
				Raise ErrorMessageText;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If Not DataLayoutRules = Undefined Then
	
		// Clearing collections of settings that are overridden by the consumer
		If ClearedCollectionsOfSettings <> Undefined Then
			For Each CollectionToCleanUp In ClearedCollectionsOfSettings Do
				SchemaCollectionBeingCleanedUp = DataLayoutRules[CollectionToCleanUp.Key];
				
				If CollectionToCleanUp.Key = "Parameters" Then
					For Each CollectionItem In SchemaCollectionBeingCleanedUp Do
						CollectionItem.Value = Undefined;
					EndDo;
				Else
					SchemaCollectionBeingCleanedUp.Clear();
				EndIf;
			EndDo;
		EndIf;
			
		If DataReceiptMode = Enums.BudgetingDataReceiptMode.All Then
			For Each Set In DataLayoutRules.DataSets Do
				If TypeOf(Set) = Type("DataCompositionSchemaDataSetQuery")
					And ValueIsFilled(Set.Query) Then
					Set.Query = RequestSchemes.SetSelectionOfAllowedRecordsInEntireRequest(Set.Query, False);
				EndIf;
			EndDo;
		EndIf;
		
	EndIf;
	
	Return DataLayoutRules;
	
EndFunction

// Returns parameters for getting the default fact
//
// Parameters:
//   DefaultValues             - Structure, Undefined - override the initial values of the parameters.
//   ExpressionIdentificationParameters - Structure, Undefined - the composition of the expressions used.
//
// Returns:
//  Structure - Parameters for getting facts by item and budget indicator:
//    * InternationalCurrency                 - CatalogRef.Currencies - The cached value of the functional currency of international accounting (See FinancialAccountingOfGeneralPurpose.AccountingCurrencies) 
//    * ReportCurrency                     - CatalogRef.Currencies - Data Currency
//    * ComplCurrency                       - CatalogRef.Currencies - The Cached value Of The Local Accounting Currency.
//    * CurrencyOfMan                        - CatalogRef.Currencies - The Cached value Of The Man. Accounting Currency.
//    * DimensionKinds                     - Array of ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions - contains the values
//    of the analyst, in the context of which it is necessary to get the fact. ** - array values.
//    * DataAcquisitionRules        - Boolean - add a column with the applied rule to the data table
//    * ReturnBudgetIndicatorItem- Boolean - add a column with an article/indicator (data source) to the data table
//    * ReturnManAndLocalAmounts          - Boolean - Return the amounts from The Man and Local Registers.
//    * AdditionalData             - Structure - additional data that will join the actual data:
//      ** Kind                   - EnumRef.KindOfAdditionalDataSourceInformation - describes how to supplement the actual data
//      ** DataTable         - ValueTable - additional data table containing a column with the name of the identifier field
//    * AdditionalSelection              - DataCompositionSettings - additional global selection, which
//                                                                     is superimposed on the source data.
//    * AdditionalFiltersForAnalytics- Structure - global selection fields for analytics 1..6, on the basis of which the settings are generated:
//      ** Key     - String - the name of the field on which you want to apply additional selection
//      ** Value - Arbitrary - the value of the add. selection
//    * AdditionalFiltersForMeasurements- Structure - fields of global selection for measurements, on the basis of which settings are generated:
//      ** Key     - String - the name of the field on which you want to apply additional selection
//      ** Value - Arbitrary - the value of the add. selection
//    * TableIndexes                    - Map - the names of the tables of the fact receipt parameter values and the arrays of indexes included in them:
//      ** Key - String - name of the table in the fact getting parameters
//      ** Value - Array of String - array of rows describing the applied indexes
//    * OriginalAnalystFillExpressions - Map - the initial expressions of the filling of the analyst in the language of formulas:
//      **Key - String - The original expression of the analytics filling.
//      **Value - CatalogRef.BudgetFlowItems, CatalogRef.BudgetBalanceItems - Budget item or indicator
//      		(to point to a specific object in case of an error).
//    * NumberedAnalyticsUsed- Structure - the numbered analysts involved. Takes values from "Analytica1" to "Analytic6"
//    * MaximumNumberOfAnalytics       - Number - the number of analysts involved. Takes values from 1 to 6
//    * BalancesOnlyAtBeginningOfPeriod     - Boolean - Get the fact only at the beginning of the period (for Balances),
//                                                  otherwise the data is received at the end of each of the subperiods.
//    * Period                           - StandardPeriod - Sample Period
//    * Periodicity                    - EnumRef.Periodicity, Undefined - The frequency of detailing
//        data for the period. Undefined - no details.
//    * Indicators                       - Structure - indicators that are automatically selected based on the settings of the source data set:
//      ** Count - Boolean, Undefined - the presence of the property in the structure means that you should add getting the quantity to the selection
//      ** Sum      - Boolean, Undefined - the presence of the property in the structure means that you should add getting the amount to the selection
//    * AddStoredFactForItemsThatAffectBudgetPerformance - Boolean - Supplement the fact for articles that affect the indicators with a stored fact.
//                                                                                The default is False. False - if the entire stored fact is obtained separately (using cached DCS).
//                                                                                In budget reports (and budget copies), the stored fact is obtained separately (using cached DCS)
//                                                                                . The stored fact is not used in limits (because rules with the budget execution type do not support the stored fact).
//    * ByCurrency                        - Boolean - Expand by currency (summary indicators).
//    * ByUnitsOfMeasurement              - Boolean - Expand by units of measurement (quantitative indicators).
//    * ByCompanies                   - Boolean - Expand by organization.
//    * ByBusinessUnits                 - Boolean - Expand by division.
//    * ByRegistrar                   - Boolean - Expand the fact by the registrar (for revolutions).
//    * DataReceiptMode             - EnumRef.BudgetingDataReceiptMode - defines the mode of using RLS when receiving data
//    * AnalystTable                  - ValueTable - the rules used by measurement, analytics and mapping analytics (the kind and expression to obtain). By default, an empty table:
//      ** Rule                          - CatalogRef.ActualDataQueryRulesByBudgetFlowItems - link to the rule
//      ** ByCompanies                   - Boolean - receive data on the corresponding measurement
//      ** ByBusinessUnits                 - Boolean - receive data on the corresponding measurement
//      ** DimensionKind                     - ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions - Dimension kind
//      ** DimensionPopulationExpression     - String - expression for getting data from the fields of the source schema
//    * PeriodsTable                  - ValueTable - continuous periods for which you want to get data:
//      ** RuleOfFact  - CatalogRef.ActualDataQueryRulesByBudgetFlowItems - link to the rule
//      ** BeginOfPeriod - Date - start date of the period
//      ** EndOfPeriod  - Date - Period end date
//    * TableOfArticleRules              - ValueTable - rules for getting facts and columns with Attributes. By
//        default, the table is empty. See Catalogs.Rules for receiving the actual cost of the budgets.Templates.Fact receipt rules.
//
Function TemplateForGettingFactParameters(DefaultValues = Undefined, ExpressionIdentificationParameters = Undefined) Export
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	Parameters = New Structure;
	
	Parameters.Insert("Period",                            New StandardPeriod);
	Parameters.Insert("Periodicity",                     Undefined); // Without detailing by period
	Parameters.Insert("ActualDataLimit",                 Date(1, 1, 1));
	Parameters.Insert("UpdateDate",                  Date(1, 1, 1));
	Parameters.Insert("BalancesOnlyAtBeginningOfPeriod",      False);
	Parameters.Insert("ReturnManAndLocalAmounts",           False);
	
	Parameters.Insert("DataAcquisitionRules",         False);
	Parameters.Insert("ReturnBudgetIndicatorItem", False);
	Parameters.Insert("Scenario",                          Catalogs.BudgetingScenarios.EmptyRef());
	
	// Data indicators
	Parameters.Insert("Indicators", New Structure("Count, Sum"));
	Parameters.Insert("AddStoredFactForItemsThatAffectBudgetPerformance", False);
	
	// Data sections
	Parameters.Insert("ByCurrency",                         False);
	Parameters.Insert("ByUnitsOfMeasurement",               False);
	Parameters.Insert("ByCompanies",                    False);
	Parameters.Insert("ByBusinessUnits",                  False);
	Parameters.Insert("ByRegistrar",                    False);
	
	Parameters.Insert("DimensionKinds",                      New Array);
	Parameters.Insert("MaximumNumberOfAnalytics",        0);
	Parameters.Insert("NumberedAnalyticsUsed", New Structure);
	Parameters.Insert("OriginalAnalystFillExpressions", New Map);
	
	Parameters.Insert("AdditionalSelection");
	Parameters.Insert("AdditionalFiltersForAnalytics", New Structure);
	Parameters.Insert("AdditionalFiltersForMeasurements", New Structure);
	Parameters.AdditionalFiltersForMeasurements.Insert("Organization");
	Parameters.AdditionalFiltersForMeasurements.Insert("Department");
	Parameters.AdditionalFiltersForMeasurements.Insert("Scenario");
	Parameters.AdditionalFiltersForMeasurements.Insert("StorageCurrency");
	
	// Data Access restrictions
	Parameters.Insert("AccessRestrictions", New Structure);
	Parameters.AccessRestrictions.Insert("ThereIsPrivilegedMode", False);
	Parameters.AccessRestrictions.Insert("ThereIsNoPrivilegedMode", False);
	Parameters.AccessRestrictions.Insert("DataReceiptMode", Enums.BudgetingDataReceiptMode.EmptyRef());
	
	// Currencies
	SetPrivilegedMode(True);
	DetailsOfChartOfAccounts = Common.ObjectAttributesValues(
		Catalogs.FinancialAccountingChartsOfAccounts.International,
		"PresentationCurrency, AccountingInFunctionalCurrency");
	If DetailsOfChartOfAccounts.AccountingInFunctionalCurrency = Enums.AccountingKindsInFunctionalCurrency.InCurrencyOfLocal Then
		FunctionalCurrency__ = Constants.LocalAccountingCurrency.Get();
	Else
		FunctionalCurrency__ = SettingsValueCached.ManagementAccountingCurrency();
	EndIf;
	SetPrivilegedMode(False);
	Parameters.Insert("InternationalCurrency", FunctionalCurrency__);
	Parameters.Insert("ReportCurrency", Catalogs.Currencies.EmptyRef());
	Parameters.Insert("FunctionalCurrency", Enums.AccountingKindsInFunctionalCurrency.InManagementAccountingCurrency_);
	
	// Parameters of batch data acquisition using data acquisition rules
	DescriptionOfFactRuleType = DataSourcesCached.DescriptionOfRuleType();
	
	BooleanTypeDetails                = New TypeDescription("Boolean");
	StringTypeDetails                = Common.StringTypeDetails(0);
	TypesDetailsDate                 = Common.DateTypeDetails(DateFractions.Date);
	IDTypeDescription                    = Common.TypeDescriptionNumber(4,, AllowedSign.Nonnegative);
	
	Parameters.Insert("TableOfArticleRules", New ValueTable);
	
	Parameters.Insert("DataAreas", New Structure);
	
	TableOfDataAreas = New ValueTable;
	TableOfDataAreas.Columns.Add("DataSourceID",    StringTypeDetails);
	TableOfDataAreas.Columns.Add("SourcePrivilegedMode", BooleanTypeDetails);
	TableOfDataAreas.Columns.Add("Period",                          TypesDetailsDate);
	TableOfDataAreas.Columns.Add("BeginOfPeriod",                   TypesDetailsDate);
	TableOfDataAreas.Columns.Add("EndOfPeriod",                    TypesDetailsDate);
	TableOfDataAreas.Columns.Add("ExpressionPeriod",                 StringTypeDetails);
	TableOfDataAreas.Columns.Add("ExpressionPeriodBoundary",          StringTypeDetails);
	TableOfDataAreas.Columns.Add("ExpressionStartOfPeriod",          StringTypeDetails);
	TableOfDataAreas.Columns.Add("ExpressionEndOfPeriod",           StringTypeDetails);
	TableOfDataAreas.Columns.Add("ID_ExpressionPeriod",              IDTypeDescription);
	TableOfDataAreas.Columns.Add("ID_ExpressionStartOfPeriod",       IDTypeDescription);
	TableOfDataAreas.Columns.Add("ID_ExpressionEndOfPeriod",        IDTypeDescription);
	TableOfDataAreas.Columns.Add("GettingBalancesForPeriodBoundary", BooleanTypeDetails);
	
	Parameters.DataAreas.Insert("DataTable", TableOfDataAreas);
	Parameters.DataAreas.Insert("ConvolutionColumns", 
		"DataSourceID, 
		|SourcePrivilegedMode,
		|Period, BeginOfPeriod, EndOfPeriod,
		|ID_ExpressionStartOfPeriod, ID_ExpressionEndOfPeriod, ID_ExpressionPeriod,
		|GettingBalancesForPeriodBoundary");
	
	Parameters.Insert("ExpressionConditions", New Structure); 
	If Not ExpressionIdentificationParameters = Undefined Then
		For Each PartOfExpression In ExpressionIdentificationParameters.PartsOfExpressions Do 
			Parameters.ExpressionConditions.Insert(PartOfExpression.Key);
		EndDo;
	Else
		Parameters.ExpressionConditions.Insert("ExpressionStartOfPeriod");
		Parameters.ExpressionConditions.Insert("ExpressionEndOfPeriod");
		Parameters.ExpressionConditions.Insert("ExpressionPeriod");
		Parameters.ExpressionConditions.Insert("ExpressionPeriodBoundary");
		
		For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
			Parameters.ExpressionConditions.Insert("DimensionPopulationExpression" + DimensionNumber);
		EndDo;
		Parameters.ExpressionConditions.Insert("ExpressionForFillingInAnalyticsCurrency");
		Parameters.ExpressionConditions.Insert("ExpressionFillingAnalyticsStorageCurrency");
		Parameters.ExpressionConditions.Insert("ExpressionForFillingCoursePeriod");
		Parameters.ExpressionConditions.Insert("AnalyticsFillExpressionUnitOfMeasurement");
		
		// Conditions for the values of articles and indicators
		Parameters.ExpressionConditions.Insert("IndicatorExpressionCountOpeningBalance");
		Parameters.ExpressionConditions.Insert("IndicatorExpressionAmountCurrencyOpeningBalance");
		Parameters.ExpressionConditions.Insert("IndicatorExpressionAmountCurrencyManOpeningBalance");
		Parameters.ExpressionConditions.Insert("IndicatorExpressionAmountCurrencyComplOpeningBalance");
		
		Parameters.ExpressionConditions.Insert("IndicatorExpressionCountReceipt");
		Parameters.ExpressionConditions.Insert("IndicatorExpressionAmountCurrencyReceipt");
		Parameters.ExpressionConditions.Insert("IndicatorExpressionAmountCurrencyManReceipt");
		Parameters.ExpressionConditions.Insert("IndicatorExpressionAmountCurrencyComplReceipt");
		
		Parameters.ExpressionConditions.Insert("IndicatorExpressionCountExpense");
		Parameters.ExpressionConditions.Insert("IndicatorExpressionAmountCurrencyExpense");
		Parameters.ExpressionConditions.Insert("IndicatorExpressionAmountCurrencyManExpense");
		Parameters.ExpressionConditions.Insert("IndicatorExpressionAmountCurrencyComplExpense");
	EndIf;
	
	Parameters.ExpressionConditions.Insert("QuantityConversionExpression");
	
	AnalystTable = New ValueTable;
	AnalystTable.Columns.Add("Rule",          DescriptionOfFactRuleType);
	AnalystTable.Columns.Add("ByCompanies",   BooleanTypeDetails);
	AnalystTable.Columns.Add("ByBusinessUnits", BooleanTypeDetails);
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		AnalystTable.Columns.Add("DimensionKind" + DimensionNumber);
		AnalystTable.Columns.Add("DimensionPopulationExpression" + DimensionNumber);
	EndDo;
	
	Parameters.Insert("AnalystTable", AnalystTable);
	
	PeriodsTable = Planning.PeriodTableTemplate();
	PeriodsTable.Columns["StartDate"].Name = "BeginOfPeriod";
	PeriodsTable.Columns["EndDate"].Name = "EndOfPeriod";
	PeriodsTable.Columns.Add("RuleOfFact", New TypeDescription("CatalogRef.ActualDataQueryRulesByBudgetFlowItems"));
	
	Parameters.Insert("PeriodsTable", PeriodsTable);
	
	Parameters.Insert("AdditionalData", New Structure);
	Parameters.AdditionalData.Insert("IdFieldName",    "");
	Parameters.AdditionalData.Insert("Kind",                      Enums.KindOfAdditionalDataSourceInformation.EmptyRef());
	Parameters.AdditionalData.Insert("NumberingOfIdentifiers", False);
	Parameters.AdditionalData.Insert("DataTable",            New ValueTable);
	
	// Hierarchical data sources
	ComparisonTable_ = New ValueTable;
	ComparisonTable_.Columns.Add("DataSource");
	ComparisonTable_.Columns.Add("OriginalDataSource");
	
	Parameters.Insert("HierarchyOfDataSources", New Structure);
	Parameters.HierarchyOfDataSources.Insert("ComparisonTable_", ComparisonTable_);
	Parameters.HierarchyOfDataSources.Insert("MatchingForSelections", New Map);
	
	TableOfComparisonsOfCorAccounts = New ValueTable;
	TableOfComparisonsOfCorAccounts.Columns.Add("BalancedAccount");
	TableOfComparisonsOfCorAccounts.Columns.Add("CorAccountSource");
	Parameters.HierarchyOfDataSources.Insert("TableOfComparisonsOfCorAccounts", TableOfComparisonsOfCorAccounts);
	
	Parameters.Insert("TableIndexes", New Map); // The key is the name of the table, the value is an array of index rows
	
	If DefaultValues <> Undefined Then
		FillPropertyValues(Parameters, DefaultValues);
	EndIf;
	
	Return Parameters;
	
EndFunction

// Returns the stored configuration from the specified directory
//
// Parameters:
//  SourceCatalogName  - String - for example, " rules for getting Factapoindicatorsbudgetsreferences"
//  SettingsHash - String - hash-sum of configured data layout selections
//  Owner - CatalogRef.BudgetFlowItems,
//  			Reference link.Indicators of budgets
//  			Undefined - the owner of the rule (indicates the need to add Links to additional properties).
//
// Returns:
//  DataCompositionSettingsComposer 
//
Function GetStoredCatalogSettings(SourceCatalogName, SettingsHash, Owner = Undefined) Export
	
	StoredSettings = Undefined;
	
	Query = New Query;
	Query.Text = "SELECT TOP 1
	|	DataSourceRules.Ref AS Ref,
	|	DataSourceRules.SettingsComposer AS SettingsComposer
	|FROM
	|	&QueryTextTableCatalog_ AS DataSourceRules
	|WHERE
	|	DataSourceRules.SettingsHash = &SettingsHash";
	If ValueIsFilled(Owner) Then
		Query.Text = Query.Text + StringFunctionsClientServer.SubstituteParametersToString("
		|	AND DataSourceRules.%1 = &Owner", ?(SourceCatalogName = "ActualDataQueryRulesByBudgetFlowItems",
			"BudgetFlowItem", "BudgetBalanceItem"));
		Query.SetParameter("Owner", Owner);
	EndIf;
	Query.Text = StrReplace(Query.Text, "&QueryTextTableCatalog_", "Catalog." + SourceCatalogName);
	Query.SetParameter("SettingsHash", SettingsHash);
	
	Result = Query.Execute();
	
	If Not Result.IsEmpty() Then
		Selection = Result.Select();
		Selection.Next();
		
		SettingsComposer = Selection.SettingsComposer; // ValueStorage
		StoredSettings = SettingsComposer.Get();
		If Not StoredSettings = Undefined And ValueIsFilled(Owner) Then
			StoredSettings.AdditionalProperties.Insert("Ref", Selection.Ref);
		EndIf;
	EndIf;

	Return StoredSettings;

EndFunction

// Returns the stored layout from the specified reference list
//
// Parameters:
//  SourceCatalogName  - String - for example, " rules for getting Factapoindicatorsbudgetsreferences"
//  HashOfDataCompositionSchema - String - hash-sum of an arbitrary data layout scheme
//  Owner - CatalogRef.BudgetFlowItems,
//  			Reference link.Indicators of budgets
//  			Undefined - the owner of the rule (indicates the need to add Links to additional properties).
//
// Returns:
//  SpreadsheetDocument, TextDocument - an object that can be a layout. 
//
Function GettingStoredCatalogTemplate(SourceCatalogName, HashOfDataCompositionSchema, Owner = Undefined) Export
	
	StoredTemplate = Undefined;
	
	Query = New Query;
	Query.Text = "SELECT TOP 1
	|	DataSourceRules.Ref AS Ref,
	|	DataSourceRules.DataSourceScheme AS DataSourceScheme
	|FROM
	|	&QueryTextTableCatalog_ AS DataSourceRules
	|WHERE
	|	DataSourceRules.HashOfDataCompositionSchema = &HashSchemes";
	If ValueIsFilled(Owner) Then
		Query.Text = Query.Text + StringFunctionsClientServer.SubstituteParametersToString("
		|	AND DataSourceRules.%1 = &Owner", ?(SourceCatalogName = "ActualDataQueryRulesByBudgetFlowItems",
			"BudgetFlowItem", "BudgetBalanceItem"));
		Query.SetParameter("Owner", Owner);
	EndIf;
	
	Query.Text = StrReplace(Query.Text, "&QueryTextTableCatalog_", "Catalog." + SourceCatalogName);
	Query.SetParameter("HashSchemes", HashOfDataCompositionSchema);
	
	Result = Query.Execute();
	
	If Not Result.IsEmpty() Then
		Selection = Result.Select();
		Selection.Next();
		
		DataSourceScheme = Selection.DataSourceScheme; // ValueStorage
		StoredTemplate = DataSourceScheme.Get();
		If Not StoredTemplate = Undefined And ValueIsFilled(Owner) Then
			StoredTemplate.DefaultSettings.AdditionalProperties.Insert("Ref", Selection.Ref);
		EndIf;
	EndIf;

	Return StoredTemplate;

EndFunction

// Returns an array of document types by data source
//
// Parameters:
//  DataSource - CatalogRef.BusinessTransactionsSettings
//
// Returns:
//  Array of CatalogRef.MetadataObjectIDs
//
Function ArrayOfTypesOfDocumentsByDataSource(DataSource) Export
	
	AccountingDataTypes = Common.ObjectAttributesValues(DataSource, "Receipt, Expense");
	
	DocumentsKindsArrayReceipt = Common.CopyRecursive(
		DataSourcesCached.ArrayOfTypesOfDocumentsByTypeOfAccountingData(AccountingDataTypes.Receipt));
	DocumentsKindsArrayExpense = Common.CopyRecursive(
		DataSourcesCached.ArrayOfTypesOfDocumentsByTypeOfAccountingData(AccountingDataTypes.Expense));
	If Not ValueIsFilled(AccountingDataTypes.Receipt) Then
		Return DocumentsKindsArrayExpense;
	ElsIf Not ValueIsFilled(AccountingDataTypes.Expense) Then
		Return DocumentsKindsArrayReceipt;
	EndIf;
	
	MismatchedTypesOfDocuments = CommonClientServer.ArraysDifference(DocumentsKindsArrayReceipt,
		DocumentsKindsArrayExpense);
	
	Counter = 0;
	While Counter < DocumentsKindsArrayReceipt.Count() Do
		If MismatchedTypesOfDocuments.Find(DocumentsKindsArrayReceipt[Counter]) <> Undefined Then
			DocumentsKindsArrayReceipt.Delete(Counter);
		Else
			Counter = Counter + 1;
		EndIf;
	EndDo;
	
	If AccountingDataTypes.Receipt = Enums.AccountingDataTypes.OtherAssetsLiabilities
		Or AccountingDataTypes.Expense = Enums.AccountingDataTypes.OtherAssetsLiabilities Then
		DocumentsKindsArrayReceipt.Add(Common.MetadataObjectID(
			Metadata.Documents.MovementOfOtherAssetsAndLiabilities));
	EndIf;
	
	Return DocumentsKindsArrayReceipt;
	
EndFunction

// Returns data for generating the Query Text to the source of actual data on the rule settings
//
// Parameters:
//  RuleDescription_ - Structure - parameters of the actual data receipt rule:
//   *DimensionPopulationExpression1_6 - String
//   *FillInAnalyticsWithSpecifiedValue1_6 - Boolean
//   *DimensionValue1_6 - Arbitrary
//   *BudgetFlowItem - CatalogRef.BudgetFlowItems - Budget item rules
//  SourceDCSSettings - DataCompositionSettings - default settings of the Actual data source DCS
//
// Returns:
//  Structure - request data structure:
//   *QueryTextFragments - Structure - Query Text Fragments:
//    **TextOfDimensionsFields - String - a fragment of the query text with a selection of budget item analytics fields
//    **ConditionText - String - a fragment of the request text with a condition for selecting the rule
//    **TextOfConnections - String - a fragment of the query text with left connections to the characteristic tables
//   *QueryOptions - Structure - request parameters according to the rule settings:
//    **GUIDParameter - Arbitrary - value of the request parameter
//
Function DataForRequestToSourceOfFactAccordingToRule(RuleDescription_, SourceDCSSettings) Export
	
	QueryTextFragments = New Structure("TextOfDimensionsFields, ConditionText, TextOfConnections", "", "", "");
	DataForRequest = New Structure("QueryTextFragments, QueryOptions", QueryTextFragments, New Structure);
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	
	TemplateDescriptionOfAnalyticsTypes = "DimensionKind%1, DimensionKind%1.ValueType";
	AttributesOfDescriptionOfTypesOfAnalytics = New Array;
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		AttributesOfDescriptionOfTypesOfAnalytics.Add(StringFunctionsClientServer.SubstituteParametersToString(
			TemplateDescriptionOfAnalyticsTypes, DimensionNumber));
	EndDo;
	
	DescriptionsOfAnalyticsTypes = Common.ObjectAttributesValues(RuleDescription_.BudgetFlowItem, StrConcat(
		AttributesOfDescriptionOfTypesOfAnalytics, ","));
	
	TreeOfAttributesOfSourceFields = ProcessingOfFormulas.GetEmptyOperandTree();
	
	// The analyst's fill-in expressions
	TemplateForExpressingAnalyticsValues = "CASE
		|	WHEN NOT VALUETYPE(%1) IN (%2)
		|		THEN %3
		|	ELSE %1
		|END"; // @query-part
	
	AnalyticsFillInExpressions = New Array;
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		DimensionKind = DescriptionsOfAnalyticsTypes["DimensionKind"+DimensionNumber];
		If Not ValueIsFilled(DimensionKind) Then
			Expression = BudgetingServer.ExpressingEmptyValue();
		ElsIf Not RuleDescription_["FillInAnalyticsWithSpecifiedValue" + DimensionNumber] Then
			Expression = RuleDescription_["DimensionPopulationExpression" + DimensionNumber];
			If IsBlankString(Expression) Then
				Expression = BudgetingServer.ExpressingEmptyValue();
			Else
				Expression = ExpressionOfFieldToPutInQueryText(Expression, DataForRequest,
					SourceDCSSettings.SelectionAvailableFields, TreeOfAttributesOfSourceFields);
				DescriptionOfTypeOfAnalyticsType = DescriptionsOfAnalyticsTypes["DimensionKind" + DimensionNumber + "ValueType"];
				If BudgetingServer.ThisIsAnalyticsDimension(DescriptionOfTypeOfAnalyticsType, DimensionKind) Then
					Expression = StringFunctionsClientServer.SubstituteParametersToString(
						TemplateForExpressingAnalyticsValues, Expression,
						FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(
						BudgetingCached.TypesOfAnalyticsType(DimensionKind)),
						BudgetingServer.ExpressingEmptyValue());
				EndIf;
			EndIf;
		Else
			DimensionValue = RuleDescription_["DimensionValue"+DimensionNumber];
			Expression = FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(DimensionValue);
			If StrStartsWith(Expression, "Parameter") Then
				FindAndAddRequestParameter(Expression, DimensionValue, DataForRequest.QueryOptions);
				Expression = "&"+Expression;
			EndIf;
		EndIf;
		AnalyticsFillInExpressions.Add(Expression + " AS Dimension" + DimensionNumber); // @query-part
	EndDo;
	
	TextOfDimensionsFields = StrConcat(AnalyticsFillInExpressions, "," + Chars.LF + Chars.Tab);
	QueryTextFragments.TextOfDimensionsFields = TextOfDimensionsFields;
	
	// Filter
	If CommonClientServer.HasAttributeOrObjectProperty(RuleDescription_, "SettingsComposer") Then
	
		Filter = RuleDescription_.SettingsComposer.Get().Filter;
		
		ConditionText = ConvertDataLayoutSelectionToQueryConditionText(Filter, DataForRequest,
			SourceDCSSettings.FilterAvailableFields, TreeOfAttributesOfSourceFields);
		QueryTextFragments.ConditionText = ?(IsBlankString(ConditionText), "TRUE", ConditionText);
		
	EndIf;
	
	Return DataForRequest;
	
EndFunction

// Returns data for generating the query text for the Balance (turnover) of the budget indicator (item)
//
// Parameters:
//  RuleDescription_ - Structure - parameters of the rule for calculating Balance (turnover) budgets:
//   *DimensionFillingSettings - ValueTable - settings for filling in the receiver's metric (article) analytics
//   *BudgetFlowItem - CatalogRef.BudgetFlowItems - Budget item rules
//  SourceDCSSettings - DataCompositionSettings - default settings of the Actual data source DCS
//  ExpressionOffsetPeriod - String - the text of the expression for determining the number of offset periods
//
// Returns:
//  Structure - request data structure:
//   *QueryTextFragments - Structure - Query Text Fragments:
//    **TextOfDimensionsFields - String - a fragment of the query text with a selection of budget item analytics fields
//    **ConditionText - String - a fragment of the request text with a condition for selecting the rule
//    **TextOfConnections - String - a fragment of the query text with left connections to the characteristic tables
//   *QueryOptions - Structure - request parameters according to the rule settings:
//    **GUIDParameter - Arbitrary - value of the request parameter
//
Function DataForRequestToSourceByDataCalculationSettings(RuleDescription_, SourceDCSSettings,
	ExpressionOffsetPeriod) Export
	
	QueryTextFragments = New Structure("TextOfDimensionsFields, ConditionText, TextOfConnections", "", "", "");
	If Not IsBlankString(ExpressionOffsetPeriod) Then
		QueryTextFragments.Insert("ExpressionOffsetPeriod", "");
	EndIf;
	DataForRequest = New Structure("QueryTextFragments, QueryOptions", QueryTextFragments, New Structure);
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	
	TemplateDescriptionOfAnalyticsTypes = "DimensionKind%1, DimensionKind%1.ValueType";
	AttributesOfDescriptionOfTypesOfAnalytics = New Array;
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		AttributesOfDescriptionOfTypesOfAnalytics.Add(StringFunctionsClientServer.SubstituteParametersToString(
			TemplateDescriptionOfAnalyticsTypes, DimensionNumber));
	EndDo;
	
	DescriptionsOfAnalyticsTypes = Common.ObjectAttributesValues(RuleDescription_.Receiver, StrConcat(
		AttributesOfDescriptionOfTypesOfAnalytics, ","));
	
	TreeOfAttributesOfSourceFields = ProcessingOfFormulas.GetEmptyOperandTree();
	
	// The expression of filling in the analyst
	TemplateForExpressingAnalyticsValues = "CASE
		|	WHEN NOT VALUETYPE(%1) IN (%2)
		|		THEN %3
		|	ELSE %1
		|END"; // @query-part
	
	// Expressions of matching analyst values
	TemplateForExpressingCorrespondenceOfAnalystValues = "CASE AliasOfSourceTable.Dimension%1
		|	%2
		|	ELSE %3
		|END"; // @query-part
	TemplateForExpressionOfMatchingElement = "WHEN %1 THEN %2"; // @query-part
	
	AnalyticsFillInExpressions = New Array;
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		DimensionKind = DescriptionsOfAnalyticsTypes["DimensionKind"+DimensionNumber];
		If Not ValueIsFilled(DimensionKind) Then
			Expression = BudgetingServer.ExpressingEmptyValue();
		Else
			AnalyticsViewLine = RuleDescription_.DimensionFillingSettings.Find(DimensionKind, "DimensionKind");
			If AnalyticsViewLine = Undefined Then
				ErrorText = NStr(
					"vi = 'Trong tùy chỉnh điền đối tượng phân tích của quy tắc %1 chưa tìm thấy dạng đối tượng phân tích %2. Cần chọn lại đích trong quy tắc.';
					|ru = 'В настройках заполнения аналитик правила %1 не найден вид аналитики %2. Необходимо перевыбрать приемник в правиле.';
					|en = 'The %2 dimension kind is not found in the dimension population settings of the %1 rule. Reselect the destination in the rule.'; fa = 'The %2 dimension kind is not found in the dimension population settings of the %1 rule. Reselect the destination in the rule.';
					|it = 'The %2 dimension kind is not found in the dimension population settings of the %1 rule. Reselect the destination in the rule.';
					|pl = 'The %2 dimension kind is not found in the dimension population settings of the %1 rule. Reselect the destination in the rule.';
					|tr = '%1 kural doldurma ayarlarında %2 analiz türü bulunamadı. Kuralda hedefin yeniden seçilmesi gerekmektedir.'");
				Raise StringFunctionsClientServer.SubstituteParametersToString(ErrorText,
					RuleDescription_.Description, DimensionKind);
			EndIf;
			If AnalyticsViewLine.FillingMethod
				= Enums.MethodsOfFillingBudgetFlowItemDimensions.FromDataSource Then
				Expression = AnalyticsViewLine.DimensionPopulationExpression;
				If IsBlankString(Expression) Then
					Expression = BudgetingServer.ExpressingEmptyValue();
				Else
					Expression = ExpressionOfFieldToPutInQueryText(Expression, DataForRequest,
					SourceDCSSettings.SelectionAvailableFields, TreeOfAttributesOfSourceFields);
					DescriptionOfTypeOfAnalyticsType = DescriptionsOfAnalyticsTypes["DimensionKind" + DimensionNumber + "ValueType"];
					If BudgetingServer.ThisIsAnalyticsDimension(DescriptionOfTypeOfAnalyticsType, DimensionKind) Then
						Expression = StringFunctionsClientServer.SubstituteParametersToString(
						TemplateForExpressingAnalyticsValues, Expression,
						FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(
						BudgetingCached.TypesOfAnalyticsType(DimensionKind)),
						BudgetingServer.ExpressingEmptyValue());
					EndIf;
				EndIf;
			ElsIf AnalyticsViewLine.FillingMethod
				= Enums.MethodsOfFillingBudgetFlowItemDimensions.BySetValue Then
				ArrayOfMatchingExpressions = New Array;
				LinesOfMatchingAnalystValues = RuleDescription_.MatchingAnalystValues.FindRows(
					New Structure("DimensionKind", AnalyticsViewLine.DimensionKind));
				For Each MapRow In LinesOfMatchingAnalystValues Do
					StringSourceAnalyticsValue = FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(
						MapRow.SourceDimensionValue);
					If StrStartsWith(StringSourceAnalyticsValue, "Parameter") Then
						FindAndAddRequestParameter(StringSourceAnalyticsValue,
							MapRow.SourceDimensionValue, DataForRequest.QueryOptions);
						StringSourceAnalyticsValue = "&" + StringSourceAnalyticsValue;
					EndIf;
					ReceiverAnalyticsValueString = FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(
						MapRow.DimensionValue);
					If StrStartsWith(ReceiverAnalyticsValueString, "Parameter") Then
						FindAndAddRequestParameter(ReceiverAnalyticsValueString,
							MapRow.DimensionValue, DataForRequest.QueryOptions);
						ReceiverAnalyticsValueString = "&" + ReceiverAnalyticsValueString;
					EndIf;
					ArrayOfMatchingExpressions.Add(StringFunctionsClientServer.SubstituteParametersToString(
						TemplateForExpressionOfMatchingElement, StringSourceAnalyticsValue,
						ReceiverAnalyticsValueString));
				EndDo;
				If ArrayOfMatchingExpressions.Count() = 0 Then
					ArrayOfMatchingExpressions.Add(StringFunctionsClientServer.SubstituteParametersToString(
						TemplateForExpressionOfMatchingElement, BudgetingServer.ExpressingEmptyValue(),
						BudgetingServer.ExpressingEmptyValue()));
				EndIf;
				If ValueIsFilled(RuleDescription_.Source) Then
					SourceDimensionNumber = BudgetingCached.NumberOfTypeOfAnalyticsItemIndicatorBudgets(
						RuleDescription_.Source, AnalyticsViewLine.KindOfSourceDimension);
					Expression = StringFunctionsClientServer.SubstituteParametersToString(
						TemplateForExpressingCorrespondenceOfAnalystValues, SourceDimensionNumber, StrConcat(
						ArrayOfMatchingExpressions, Chars.LF + Chars.Tab),
						BudgetingServer.ExpressingEmptyValue());
				Else
					AvailableTypesOfAnalytics = BudgetingCached.AvailableTypesOfAnalyticsForPlanningSourceType(
						RuleDescription_.SourceType);
					TypeOfAnalyticsType = BudgetingCached.TypesOfAnalyticsType(
						AnalyticsViewLine.KindOfSourceDimension)[0];
					NameOfAnalyticsField = StrReplace(AvailableTypesOfAnalytics.Get(TypeOfAnalyticsType), "TableName.", "");
					Expression = StringFunctionsClientServer.SubstituteParametersToString(StrReplace(
						TemplateForExpressingCorrespondenceOfAnalystValues, "Dimension%1", NameOfAnalyticsField), , StrConcat(
						ArrayOfMatchingExpressions, Chars.LF + Chars.Tab),
						BudgetingServer.ExpressingEmptyValue());
				EndIf;
			Else
				DimensionValue = AnalyticsViewLine.DimensionValue;
				Expression = FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(DimensionValue);
				If StrStartsWith(Expression, "Parameter") Then
					FindAndAddRequestParameter(Expression, DimensionValue, DataForRequest.QueryOptions);
					Expression = "&"+Expression;
				EndIf;
			EndIf;
		EndIf;
		AnalyticsFillInExpressions.Add(Expression + " AS Dimension" + DimensionNumber); // @query-part
	EndDo;
	
	TextOfDimensionsFields = StrConcat(AnalyticsFillInExpressions, "," + Chars.LF + Chars.Tab);
	QueryTextFragments.TextOfDimensionsFields = TextOfDimensionsFields;
	
	// Filter
	Filter = SourceDCSSettings.Filter;

	ConditionText = ConvertDataLayoutSelectionToQueryConditionText(Filter, DataForRequest,
		SourceDCSSettings.FilterAvailableFields, TreeOfAttributesOfSourceFields);
	QueryTextFragments.ConditionText = ?(IsBlankString(ConditionText), "TRUE", ConditionText);
	
	// Period offset expression
	If Not IsBlankString(ExpressionOffsetPeriod) Then
		QueryTextFragments.ExpressionOffsetPeriod = ExpressionOfFieldToPutInQueryText(
			ExpressionOffsetPeriod, DataForRequest, SourceDCSSettings.SelectionAvailableFields,
			TreeOfAttributesOfSourceFields);
	EndIf;
	
	Return DataForRequest;
	
EndFunction

// Returns a query based on the layout scheme of the rule data with an arbitrary query.
//
// Parameters:
//  DataCompositionSchema - DataCompositionSchema - Data Layout Rules
//  TempTableName - String - the name of the temporary table to place the query data in
//
// Returns:
//  Undefined,
//  Query
//
Function QueryAccordingToSchemaOfRuleDataSource(DataCompositionSchema, TempTableName) Export
	
	DataCompositionServer.AddParameter(DataCompositionSchema, "Document",
		New TypeDescription("DocumentRef.PaymentRequest, DocumentRef.ApplicationForBusinessTrip"));
	Settings = DataCompositionSchema.DefaultSettings;
	FinancialReportingServer.NewFilter(Settings.Filter, "Recorder",
		New DataCompositionField("DataParameters.Document"));
	
	CompositionTemplate = DataCompositionServer.GetLayoutTemplate(DataCompositionSchema, Settings);
	If CompositionTemplate.DataSets.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	Query = DataCompositionServer.GETRequestFromLayoutTemplate(CompositionTemplate, CompositionTemplate.DataSets[0].Name);
	ParametersToDelete = New Array;
	For Each QueryParameter In Query.Parameters Do
		If QueryParameter.Key = "Document" Then
			// The "Document" parameter is empty, but it is filled in when conducting a controlled document
			Continue;
		EndIf;
		StringParameterValue = FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(
			QueryParameter.Value);
		If StrStartsWith(StringParameterValue, "Parameter") Then
			Continue;
		Else
			Query.Text = StrReplace(Query.Text, "&" + QueryParameter.Key, StringParameterValue);
			ParametersToDelete.Add(QueryParameter.Key);
		EndIf;
	EndDo;
	For Each QueryParameter In ParametersToDelete Do
		Query.Parameters.Delete(QueryParameter);
	EndDo;
	
	QueryText = 
		"SELECT
		|	*
		|INTO TempTableName
		|FROM
		|	&DataSourceRules";
	QueryText = StrReplace(QueryText, "&DataSourceRules", "(" + Query.Text + ") AS NestedQuery");
	QueryText = StrReplace(QueryText, "TempTableName", TempTableName);
	Query.Text = QueryText;
	
	Return Query;
	
EndFunction

#EndRegion 

#Region IndexesOfValueTables

// Returns a string representation of indices
// 
// Parameters:
//	ValueTable - ValueTable - the table whose indexes you want to get.
//
// Returns:
//	Array of String - string representations of table indexes.
// 
Function IndexesTableIntoArray(ValueTable) Export
	TableIndexes_ = New Array;
	
	For Each TableIndex In ValueTable.Indexes Do
		TableIndexes_.Add(String(TableIndex));
	EndDo;
	
	Return TableIndexes_;
	
EndFunction

// Returns string representations of indexes for multiple tables
// 
// Parameters:
//	ValueTables - Map of KeyAndValue, Structure - tables whose indexes you want to get:
//		* Key     - String - table name
//		* Value - ValueTable - the table whose indexes you want to get.
//
// Returns:
//	Map of KeyAndValue - Table Indexes:
//		* Key     - String - table name
//		* Value - Array of String - string representations of table indexes.
// 
Function TableNamesAndIndexes(ValueTables) Export
	TableNamesAndIndexes = New Map;
	
	For Each ValueTablesElement In ValueTables Do 
		TableNamesAndIndexes.Insert(ValueTablesElement.Key, IndexesTableIntoArray(ValueTablesElement.Value));
	EndDo;
	
	Return TableNamesAndIndexes;
EndFunction

// Sets or clears indexes of the value table
// 
// Parameters:
//	ValueTable - ValueTable - table whose indexes you want to set
//	TableIndexes_ - Array, Undefined - the string representation of the indexes on the table.
//		If passed Undefined, the table indexes will be cleared.
//
Procedure SetIndexesFromArray(ValueTable, TableIndexes_ = Undefined) Export
	
	If TableIndexes_ = Undefined Then
		ValueTable.Indexes.Clear();
	Else
		
		For Each TableIndex In TableIndexes_ Do
			ValueTable.Indexes.Add(TableIndex);
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion 

#EndRegion

#Region Internal

// Returns whether the transmitted data source belongs to the items of the management balance sheet.
//
// Parameters:
//  DataSource - Structure,FormDataStructure,
//  					The Type plancharacteristicobject.Articles of activespassives,
//  					View characteristicslink.Articles of passive assets.
//
// Returns:
//  Boolean
//
Function ThisIsItemOfManagementBalanceSheet(DataSource) Export
	
	DataSourceType = TypeOf(DataSource);
	
	If DataSourceType = Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems") Then
		SourceAttributeValues = Common.ObjectAttributesValues(
			DataSource, "NameOfBudgetDataSource,Predefined");
	ElsIf DataSourceType = Type("ChartOfCharacteristicTypesObject.AssetLiabilityItems") Then
		SourceAttributeValues = DataSource;
	ElsIf (DataSourceType = Type("Structure") Or DataSourceType = Type("FormDataStructure"))
		And DataSource.Property("NameOfBudgetDataSource") And DataSource.Property("Predefined") Then
		SourceAttributeValues = DataSource;
	ElsIf DataSourceType = Type("String") And Not IsBlankString(DataSource) Then
		Query = New Query("
		|SELECT TOP 1
		|	AssetLiabilityItems.NameOfBudgetDataSource AS NameOfBudgetDataSource,
		|	AssetLiabilityItems.Predefined AS Predefined
		|FROM
		|	ChartOfCharacteristicTypes.AssetLiabilityItems AS AssetLiabilityItems
		|WHERE
		|	NOT AssetLiabilityItems.DeletionMark
		|	AND NOT AssetLiabilityItems.IsFolder
		|	AND AssetLiabilityItems.NameOfBudgetDataSource = &DataSource
		|");
		Query.SetParameter("DataSource", DataSource);
		Result = Query.Execute();
		If Not Result.IsEmpty() Then
			SourceAttributeValues = Result.Unload()[0];
		Else
			Return False;
		EndIf;
	Else
		Return False;
	EndIf;
	
	If Not SourceAttributeValues.Predefined Then
		Return Not GetFunctionalOption("SetUpRulesForObtainingActualDataByAssetAndLiabilityItems");
	Else
		Return ValueIsFilled(SourceAttributeValues.NameOfBudgetDataSource);
	EndIf;
	
EndFunction

// Returns the affiliation of the transmitted data source to the asset and liability
// items describing the data of the operational accounting balance registers.
//
// Parameters:
//  DataSource - Structure,FormDataStructure,
//  					The Type plancharacteristicobject.Articles of activespassives,
//  					View characteristicslink.Articles of passive assets.
//
// Returns:
//  Boolean
//
Function ThisIsItemOfAssetsLiabilities(DataSource) Export
	
	DataSourceType = TypeOf(DataSource);
	
	If DataSourceType = Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems") Then
		SourceAttributeValues = Common.ObjectAttributesValues(
			DataSource, "DataSource,Predefined");
	ElsIf DataSourceType = Type("ChartOfCharacteristicTypesObject.AssetLiabilityItems") Then
		SourceAttributeValues = DataSource;
	ElsIf (DataSourceType = Type("Structure") Or DataSourceType = Type("FormDataStructure"))
		And DataSource.Property("DataSource") And DataSource.Property("Predefined") Then
		SourceAttributeValues = DataSource;
	ElsIf DataSourceType = Type("String") And Not IsBlankString(DataSource) Then
		FullSourceName = "ChartOfCharacteristicTypes.AssetLiabilityItems." + DataSource;
		DataSourceLink = Common.PredefinedItem(FullSourceName);
		If DataSourceLink = Undefined Then
			Return False;
		Else
			Return ThisIsItemOfAssetsLiabilities(DataSourceLink);
		EndIf;
	Else
		Return False;
	EndIf;
	
	If Not SourceAttributeValues.Predefined Then
		Return GetFunctionalOption("SetUpRulesForObtainingActualDataByAssetAndLiabilityItems");
	Else
		Return ValueIsFilled(SourceAttributeValues.DataSource);
	EndIf;
	
EndFunction

// Returns whether the transmitted data source belongs to the business operations Catalog.
//
// Parameters:
//  DataSource - CatalogRef.BusinessTransactionsSettings,
//  					A reference object.Settings of economic operations.
//
// Returns:
//  Boolean
//
Function ThisIsSettingUpBusinessOfOperation(DataSource) Export
	
	DataSourceType = TypeOf(DataSource);
	
	If DataSourceType = Type("CatalogRef.BusinessTransactionsSettings")
	 Or DataSourceType = Type("CatalogObject.BusinessTransactionsSettings") Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Returns the folder name of the fields in the data source rules for getting facts about budget items.
//
// Returns:
//  String
//
Function NameOfDataSourceFieldsFolder() Export
	
	Return "DataSourceGroup";
	
EndFunction

// Returns the folder name of the fields cor. data source rules for obtaining facts by budget items.
//
// Returns:
//  String
//
Function NameOfFolderOfFieldsOfCorDataSource() Export
	
	Return "CorGroupDataSource";
	
EndFunction

// Returns the prefix of the field names of the cor. data source rules for obtaining facts by budget items.
//
// Returns:
//  String
//
Function PrefixOfFieldNamesCorOfDataSource() Export
	
	Return "Balanced";
	
EndFunction

#EndRegion 

#Region Private

// Returns an empty balance register correspondence table for calculating the data layout scheme
//
// Parameters:
//  DataSource - CatalogRef.BusinessTransactionsSettings,
//                   Structure
//  CorrespondenceAnalytics - Undefined,
//                             Structure
//
// Returns:
//  ValueTable
//
Function TableOfCorrespondenceRegisters(DataSource, CorrespondenceAnalytics = Undefined) Export
	
	CorrespondencesTable = New ValueTable;
	
	// Shared columns
	CorrespondencesTable.Columns.Add("Period", New TypeDescription("Date", , , New DateQualifiers(DateFractions.DateTime)));
	CorrespondencesTable.Columns.Add("Recorder");
	CorrespondencesTable.Columns.Add("Organization", New TypeDescription("CatalogRef.Companies"));
	CorrespondencesTable.Columns.Add("Currency", New TypeDescription("CatalogRef.Currencies"));
	CorrespondencesTable.Columns.Add("FinRecordID", New TypeDescription("String", , New StringQualifiers(36)));
	
	// Dimension
	If TypeOf(DataSource) = Type("CatalogRef.BusinessTransactionsSettings") Then
		AccountingDataTypes = Common.ObjectAttributesValues(DataSource, "Receipt, Expense");
	Else
		AccountingDataTypes = DataSource;
	EndIf;
	TypesOfAccountingDataMatch = (AccountingDataTypes.Receipt = AccountingDataTypes.Expense);
	
	If CorrespondenceAnalytics <> Undefined Then
		DimensionExpense = CorrespondenceAnalytics.DimensionCr;
		DimensionReceipt = CorrespondenceAnalytics.DimensionDr;
		CorDimension = CorrespondenceAnalytics.CorDimension;
	Else
		DimensionExpense = New Array;
		DimensionReceipt = New Array;
		CorDimension = New Map;
	EndIf;
	AddColumnsByAccountingDataType(CorrespondencesTable, AccountingDataTypes.Expense, TypesOfAccountingDataMatch, Undefined, DimensionExpense);
	If TypesOfAccountingDataMatch Then
		DimensionReceipt = Common.CopyRecursive(DimensionExpense);
		AddColumnsByAccountingDataType(CorrespondencesTable, AccountingDataTypes.Expense, TypesOfAccountingDataMatch, CorDimension, DimensionReceipt);
		If CorrespondenceAnalytics <> Undefined Then
			CorrespondenceAnalytics.DimensionDr = CommonClientServer.ArraysDifference(DimensionReceipt, DimensionExpense);
		EndIf;
	ElsIf Not ValueIsFilled(AccountingDataTypes.Expense) Then
		AddColumnsByAccountingDataType(CorrespondencesTable, AccountingDataTypes.Receipt, True, CorDimension, DimensionReceipt);
	Else
		AddColumnsByAccountingDataType(CorrespondencesTable, AccountingDataTypes.Receipt, TypesOfAccountingDataMatch, Undefined, DimensionReceipt);
		If DimensionExpense.Find("Department") <> Undefined Then
			If AccountingDataTypes.Receipt = Enums.AccountingDataTypes.Counterparties
				Or AccountingDataTypes.Receipt = Enums.AccountingDataTypes.Cash
				And AccountingDataTypes.Expense <> Enums.AccountingDataTypes.Counterparties
				Or AccountingDataTypes.Receipt = Enums.AccountingDataTypes.Products
				And AccountingDataTypes.Expense <> Enums.AccountingDataTypes.Counterparties
				And AccountingDataTypes.Expense <> Enums.AccountingDataTypes.Cash Then
				DimensionExpense.Delete(DimensionExpense.Find("Department"));
				DimensionReceipt.Add("Department");
			EndIf;
		EndIf;
	EndIf;
	
	Return CorrespondencesTable;
	
EndFunction

Procedure AddColumnsByAccountingDataType(CorrespondencesTable, TypeOfAccountingData, TypesOfAccountingDataMatch, CorDimension, ArrayAnalytics)
	
	StructureOfAnalytics = DataSourcesCached.AnalyticsStructureByTypeOfAccountingData(TypeOfAccountingData);
	
	ConsiderTypeOfAccountingData = Not TypesOfAccountingDataMatch And ValueIsFilled(TypeOfAccountingData);
	
	For Each DimDetails In StructureOfAnalytics Do
		FieldName = DimDetails.Key;
		FieldTitle = DimDetails.Value.Title;
		
		If (FieldName = "LineOfBusiness" Or FieldName = "Department") And ConsiderTypeOfAccountingData Then
			FieldParameters = DataSourcesCached.FieldNameByAccountingDataType(FieldName, FieldTitle, TypeOfAccountingData);
			FieldName = FieldParameters.FieldName;
			FieldTitle = FieldParameters.FieldTitle;
		EndIf;
		If CorrespondencesTable.Columns.Find(FieldName) = Undefined Then
			CorrespondencesTable.Columns.Add(FieldName, DimDetails.Value.Type, FieldTitle);
			ArrayAnalytics.Add(FieldName);
		ElsIf CorDimension <> Undefined Then
			CorrespondencesTable.Columns.Add(DimDetails.Value.NameBalanced, DimDetails.Value.Type,
				DimDetails.Value.TitleBalanced);
			ArrayAnalytics.Add(DimDetails.Value.NameBalanced);
			CorDimension.Insert(DimDetails.Value.NameBalanced, FieldName);
		EndIf;
	EndDo;
	
	If CorDimension <> Undefined And TypeOfAccountingData = Enums.AccountingDataTypes.Cash Then
		CorrespondencesTable.Columns.Add("CorrespondingCurency", CorrespondencesTable.Columns.Currency.ValueType, NStr("vi = 'Đối ứng tiền tệ';
																														|ru = 'Кор. валюта';
																														|en = 'Cor. currency'; fa = 'ارز مقابل';
																														|it = 'Valuta corrispondente';
																														|pl = 'Kor. waluta';
																														|tr = 'Muhabir para birimi'"));
	EndIf;
	
EndProcedure

// Returns the data layout scheme according to the correspondence table of balance registers
//
// Parameters:
//  CorrespondencesTable - ValueTable
//
// Returns:
//  DataCompositionSchema
//
Function DataCompositionSchemaAccordingToCorrespondenceTableOfRegisters(CorrespondencesTable) Export
	
	DCS = DataCompositionServer.EmptyCircuit();
	
	DataSetName = "CorrespondencesTable";
	DataSet = DataCompositionServer.AddEmptyDataSet(DCS, Type("DataCompositionSchemaDataSetObject"), DataSetName, , DataSetName);
	
	For Each Column In CorrespondencesTable.Columns Do
		FinancialReportingServer.NewSetField(DataSet, Column.Name, , Column.Title, Column.ValueType);
	EndDo;
	
	Return DCS;
	
EndFunction

// Adds additional sum resources as a result of adding up some of the original resources
//
// Parameters:
//  SummaryResources - Array of ValueTableColumn
//  TabIndex - Number
//
// Returns:
//  Map of KeyAndValue - comparison of a composite sum resource with the original ones:
//   * Key - String - name of the column of the composite sum resource
//   * Value - Array of String - column names of the original sum resources.
//
Function CompositeSumResources(SummaryResources, TabIndex) Export
	
	CompositeResources = New Map;
	
	If TabIndex = 1 Then
		
		// amount of VAT
		If SummaryResources.Find("AmountExcludingVATMan") <> Undefined
			And SummaryResources.Find("VATAmountMan") = Undefined Then
			CompositeResources.Insert("VATAmountMan");
		EndIf;
		If SummaryResources.Find("AmountExcludingVATCompl") <> Undefined
			And SummaryResources.Find("VATAmountCompl") = Undefined Then
			CompositeResources.Insert("VATAmountCompl");
		EndIf;
		If SummaryResources.Find("VATExclusiveAmountVal") <> Undefined
			And SummaryResources.Find("VATAmountShaft") = Undefined Then
			CompositeResources.Insert("VATAmountShaft");
		EndIf;
		
		// Cost including VAT
		If SummaryResources.Find("CostExcludingVATMan") <> Undefined
			And SummaryResources.Find("VATAmountOfCostOfMan") <> Undefined Then
			CompositeResources.Insert("CostWithVATMan", StrSplit("CostExcludingVATMan,VATAmountOfCostOfMan", ","));
		ElsIf SummaryResources.Find("CostMan") <> Undefined Then
			CompositeResources.Insert("CostWithVATMan", StrSplit("CostMan", ","));
		EndIf;
		If SummaryResources.Find("AmountOfAdditionalExpensesAmountExcludingVATMan") <> Undefined
			And SummaryResources.Find("VATAmountOfAdditionalExpenseAmountOfMan") <> Undefined Then
			CompositeResources.Insert("AmountOfAdditionalExpensesAmountWithVATMan", StrSplit("AmountOfAdditionalExpensesAmountExcludingVATMan,VATAmountOfAdditionalExpenseAmountOfMan", ","));
		ElsIf SummaryResources.Find("AmountOfAdditionalExpenseAmountOfMan") <> Undefined Then
			CompositeResources.Insert("AmountOfAdditionalExpensesAmountWithVATMan", StrSplit("AmountOfAdditionalExpenseAmountOfMan", ","));
		EndIf;
		
		// Payment amount
		If SummaryResources.Find("ManSPrepaymentAmount") <> Undefined
			And SummaryResources.Find("AmountOfManSPostPayment") <> Undefined Then
			CompositeResources.Insert("ManPaymentAmount", StrSplit("ManSPrepaymentAmount,AmountOfManSPostPayment", ","));
		EndIf;
		If SummaryResources.Find("PrepaymentAmountLocal") <> Undefined
			And SummaryResources.Find("PostpaymentAmountLocal") <> Undefined Then
			CompositeResources.Insert("PaymentAmountLocal", StrSplit("PrepaymentAmountLocal,PostpaymentAmountLocal", ","));
		EndIf;
		If SummaryResources.Find("PrepaymentAmountVal") <> Undefined
			And SummaryResources.Find("AmountOfPostPaymentShaft") <> Undefined Then
			CompositeResources.Insert("PaymentAmountShaft", StrSplit("PrepaymentAmountVal,AmountOfPostPaymentShaft", ","));
		EndIf;
		
	ElsIf TabIndex = 2 Then
		
		// VAT inclusive
		If SummaryResources.Find("AmountExcludingVATMan") <> Undefined
			And SummaryResources.Find("VATAmountMan") <> Undefined Then
			CompositeResources.Insert("SumMan", StrSplit("AmountExcludingVATMan,VATAmountMan", ","));
			If SummaryResources.Find("AmountOfExpensesForSaleOfMan") <> Undefined Then
				CompositeResources.Insert("SumMan", StrSplit("AmountExcludingVATMan,VATAmountMan,AmountOfExpensesForSaleOfMan", ","));
			EndIf;
		EndIf;
		If SummaryResources.Find("AmountExcludingVATCompl") <> Undefined
			And SummaryResources.Find("VATAmountCompl") <> Undefined Then
			CompositeResources.Insert("SumCompl", StrSplit("AmountExcludingVATCompl,VATAmountCompl", ","));
			If SummaryResources.Find("AmountOfExpensesForSaleOfLocal") <> Undefined Then
				CompositeResources.Insert("SumCompl", StrSplit("AmountExcludingVATCompl,VATAmountCompl,AmountOfExpensesForSaleOfLocal", ","));
			EndIf;
		EndIf;
		If SummaryResources.Find("VATExclusiveAmountVal") <> Undefined
			And SummaryResources.Find("VATAmountShaft") <> Undefined Then
			CompositeResources.Insert("SumCurr", StrSplit("VATExclusiveAmountVal,VATAmountShaft", ","));
			If SummaryResources.Find("AmountOfExpensesForSaleOfShaft") <> Undefined Then
				CompositeResources.Insert("SumCurr", StrSplit("VATExclusiveAmountVal,VATAmountShaft,AmountOfExpensesForSaleOfShaft", ","));
			EndIf;
		EndIf;
		
		// Cost_
		If SummaryResources.Find("LocalCost") <> Undefined
			And SummaryResources.Find("AmountOfAdditionalExpensesAmountOfLocal") <> Undefined Then
			CompositeResources.Insert("CostLocal", StrSplit("LocalCost,AmountOfAdditionalExpensesAmountOfLocal", ","));
			If SummaryResources.Find("AmountOfExpensesForSaleOfLocal") <> Undefined Then
				CompositeResources.Insert("CostLocal", StrSplit("LocalCost,AmountOfAdditionalExpensesAmountOfLocal,AmountOfExpensesForSaleOfLocal", ","));
			EndIf;
		EndIf;
		If SummaryResources.Find("CostExcludingVATMan") <> Undefined
			And SummaryResources.Find("AmountOfAdditionalExpensesAmountExcludingVATMan") <> Undefined Then
			CompositeResources.Insert("CostWithoutVATMan", StrSplit("CostExcludingVATMan,AmountOfAdditionalExpensesAmountExcludingVATMan", ","));
			If SummaryResources.Find("AmountOfExpensesForSaleOfMan") <> Undefined Then
				CompositeResources.Insert("CostWithoutVATMan", StrSplit("CostExcludingVATMan,AmountOfAdditionalExpensesAmountExcludingVATMan,AmountOfExpensesForSaleOfMan", ","));
			EndIf;
		EndIf;
		
		// Cost including VAT
		If SummaryResources.Find("CostWithVATMan") <> Undefined
			And SummaryResources.Find("AmountOfAdditionalExpensesAmountWithVATMan") <> Undefined Then
			CompositeResources.Insert("Cost_WithVATMan", StrSplit("CostWithVATMan,AmountOfAdditionalExpensesAmountWithVATMan", ","));
			If SummaryResources.Find("AmountOfExpensesForSaleOfMan") <> Undefined Then
				CompositeResources.Insert("Cost_WithVATMan", StrSplit("CostWithVATMan,AmountOfAdditionalExpensesAmountWithVATMan,AmountOfExpensesForSaleOfMan", ","));
			EndIf;
		EndIf;
		
	ElsIf TabIndex = 3 Then
		
		// VAT exclusive
		If SummaryResources.Find("ManPaymentAmount") <> Undefined
			And SummaryResources.Find("VATAmountMan") <> Undefined
			And SummaryResources.Find("AmountExcludingVATMan") = Undefined Then
			CompositeResources.Insert("AmountExcludingVATMan", StrSplit("ManPaymentAmount,-VATAmountMan", ","));
		EndIf;
		If SummaryResources.Find("PaymentAmountLocal") <> Undefined
			And SummaryResources.Find("VATAmountCompl") <> Undefined
			And SummaryResources.Find("AmountExcludingVATCompl") = Undefined Then
			CompositeResources.Insert("AmountExcludingVATCompl", StrSplit("PaymentAmountLocal,-VATAmountCompl", ","));
		EndIf;
		If SummaryResources.Find("PaymentAmountShaft") <> Undefined
			And SummaryResources.Find("VATAmountShaft") <> Undefined
			And SummaryResources.Find("VATExclusiveAmountVal") = Undefined Then
			CompositeResources.Insert("VATExclusiveAmountVal", StrSplit("PaymentAmountShaft,-VATAmountShaft", ","));
		EndIf;
		
	EndIf;
	
	Return CompositeResources;
	
EndFunction

Function ExpressionOfFieldToPutInQueryText(OriginalExpression, DataForRequest, AvailableFields, AttributeTree)
	
	PartsOfExpression = ProcessingOfFormulasClientServer.OperandParts(OriginalExpression);
	ConnectionsTexts = New Array;
	
	TemplateForExpressionOfCharacteristics = "CAST (%1.%2 AS %3)"; // @query-part
	
	TemplateForElementExpressingCompositeCharacteristic = "WHEN VALUETYPE(%1.%2) = TYPE(%3)
		|	THEN CAST (%1.%2 AS %3)"; // @query-part
	
	TemplateForCompositeFeatureExpressionElement = "WHEN VALUETYPE(%1) = TYPE(%2)
		|	THEN %3"; // @query-part
	
	ConnectionTemplateWithTableOfCharacteristics = "LEFT JOIN %1 AS %2
		|	ON %3 = %2.%4
		|	AND (%2.%5 = %6)"; // @query-part
	
	ItemsTypes = ProcessingOfFormulas.TypesOfOperandTreeElements();
	
	If PartsOfExpression.Count() > 1 Then
		CurrentTreeRow = AttributeTree;
		QueryExpression = "AliasOfSourceTable";
		Presentation = "";
		AliasPrefixOfCharacteristicsTable = "";
		While PartsOfExpression.Count() > 0 Do
			Presentation = ?(IsBlankString(Presentation), "", Presentation + ".") + PartsOfExpression[0];
			PartOfTheView = StringFunctionsClientServer.ReplaceCharsWithOther("[]", PartsOfExpression[0], "");
			TreeRow = CurrentTreeRow.Rows.Find(PartOfTheView, "Id", False);
			If TreeRow = Undefined Then
				TreeRow = CurrentTreeRow.Rows.Find(PartOfTheView, "Presentation", False);
			EndIf;
			If TreeRow = Undefined Then
				TreeRow = CurrentTreeRow.Rows.Add();
				TreeRow.Id = PartOfTheView;
				TreeRow.Presentation = PartOfTheView;
				TreeRow.TreeItemType = ItemsTypes.Attribute;
				Field = AvailableFields.FindField(New DataCompositionField(Presentation));
				If Field <> Undefined Then
					TreeRow.ValueType = Field.ValueType;
				EndIf;
				TreeRow.OperandSelectionAllowed = True;
				TreeRow.IncludedInID = True;
			EndIf;
			If TreeRow.TreeItemType = ItemsTypes.Attribute Then
				QueryExpression = QueryExpression + "." + TreeRow.Id;
				AliasPrefixOfCharacteristicsTable = ?(IsBlankString(AliasPrefixOfCharacteristicsTable), "",
					AliasPrefixOfCharacteristicsTable + "_") + TreeRow.Id;
			ElsIf TreeRow.TreeItemType = ItemsTypes.AdditionalAttribute
				Or TreeRow.TreeItemType = ItemsTypes.AdditionalInfoItem
				Or TreeRow.TreeItemType = ItemsTypes.TypeOfContactInformation_Address
				Or TreeRow.TreeItemType = ItemsTypes.TypeOfContactInformation_Phone
				Or TreeRow.TreeItemType = ItemsTypes.TypeOfContactInformation_Skype
				Or TreeRow.TreeItemType = ItemsTypes.TypeOfContactInformation_EmailAddress
				Or TreeRow.TreeItemType = ItemsTypes.TypeOfContactInformation_WebPage
				Or TreeRow.TreeItemType = ItemsTypes.TypeOfContactInformation_Fax
				Or TreeRow.TreeItemType = ItemsTypes.TypeOfContactInformation_Other
				Or TreeRow.TreeItemType = ItemsTypes.TypeOfContactInformation_MultipleTypesOfContactInformation Then
				Id = StringFunctionsClientServer.ReplaceCharsWithOther("{}",
					TreeRow.Id, "");
				If TreeRow.TreeItemType = ItemsTypes.AdditionalAttribute
					Or TreeRow.TreeItemType = ItemsTypes.AdditionalInfoItem Then
					Id = StrReplace(Id, "DR_.", "");
				Else
					Id = StrReplace(Id, "KI.", "");
				EndIf;
				CharacteristicParameters = CharacteristicParametersForQueryText(
					TreeRow.Parent.ValueType, TreeRow.TreeItemType, Id);
				If CharacteristicParameters.Count() = 0 Then
					Raise(StringFunctionsClientServer.SubstituteParametersToString(
						NStr(
						"vi = 'Không thể xác định đối tượng chủ của thuộc tính bổ sung với ID %1 theo trường có biểu thức %2.';
						|ru = 'Не удалось определить владельца дополнительного свойства с идентификатором %1 по полю с выражением %2.';
						|en = 'Cannot identify the owner of the additional property with ID %1 by the field with the %2 expression.'; fa = 'Cannot identify the owner of the additional property with ID %1 by the field with the %2 expression.';
						|it = 'Не удалось определить владельца дополнительного свойства с идентификатором %1 по полю с выражением %2.';
						|pl = 'Cannot identify the owner of the additional property with ID %1 by the field with the %2 expression.';
						|tr = '%1 kimlikli ek mülkün sahibi, %2 ifadesinin bulunduğu alandan belirlenemedi.'"),
						TreeRow.Id, OriginalExpression),
						ErrorCategory.StoredDataError);
				EndIf;
				ElementsOfCompositeDataPath = New Array;
				For Each Parameters In CharacteristicParameters Do
					AliasOfCharacteristicsTable = AliasPrefixOfCharacteristicsTable + "_"
						+ Parameters.AliasOfSourceTable;
					StringCharacteristic = FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(
						Parameters.Property);
					If StrStartsWith(StringCharacteristic, "Parameter") Then
						FindAndAddRequestParameter(StringCharacteristic, Parameters.Property,
							DataForRequest.QueryOptions);
						StringCharacteristic = "&" + StringCharacteristic;
					EndIf;
					JoinText = StringFunctionsClientServer.SubstituteParametersToString(
						ConnectionTemplateWithTableOfCharacteristics, Parameters.PathToSourceTable,
						AliasOfCharacteristicsTable, QueryExpression, Parameters.ObjectField,
						Parameters.PropertyField, StringCharacteristic);
					If StrFind(DataForRequest.QueryTextFragments.TextOfConnections, JoinText) = 0 Then
						ConnectionsTexts.Add(JoinText);
					EndIf;
					TypesOfCharacteristicValues = TreeRow.ValueType.Types();
					If TypesOfCharacteristicValues.Count() = 1 Then
						NameOfValueType = FinancialAccountingByBalanceSheetRegisterData.FullTypeName(
							TypesOfCharacteristicValues[0]);
						ExpressionOfCharacteristic = StringFunctionsClientServer.SubstituteParametersToString(
							TemplateForExpressionOfCharacteristics, AliasOfCharacteristicsTable,
							Parameters.PropertyValueField, NameOfValueType);
					Else
						DataPathElements = New Array;
						For Each ValueType In TypesOfCharacteristicValues Do
							NameOfValueType = FinancialAccountingByBalanceSheetRegisterData.FullTypeName(
								ValueType);
							DataPathElements.Add(
								StringFunctionsClientServer.SubstituteParametersToString(
								TemplateForElementExpressingCompositeCharacteristic, AliasOfCharacteristicsTable,
								Parameters.PropertyValueField, NameOfValueType));
						EndDo;
						ExpressionOfCharacteristic = "(CASE"
							+ Chars.LF + StrConcat(DataPathElements, Chars.LF) + Chars.LF
							+ "WHEN "
							+ AliasOfCharacteristicsTable + "." + Parameters.PropertyValueField
							+ " = UNDEFINED THEN UNDEFINED"
							+ Chars.LF
							+ "END)"; // @query-part-1 @query-part-2 @query-part-3 @query-part-4 @query-part-5
					EndIf;
					If CharacteristicParameters.Count() = 1 Then
						ElementsOfCompositeDataPath.Add(ExpressionOfCharacteristic);
					Else
						ElementsOfCompositeDataPath.Add(
							StringFunctionsClientServer.SubstituteParametersToString(
							TemplateForCompositeFeatureExpressionElement, QueryExpression, Parameters.ObjectName,
							ExpressionOfCharacteristic));
					EndIf;
				EndDo;
				AliasPrefixOfCharacteristicsTable = AliasPrefixOfCharacteristicsTable + "_" + Id;
				If ElementsOfCompositeDataPath.Count() = 1 Then
					QueryExpression = ElementsOfCompositeDataPath[0];
				Else
					QueryExpression = "(CASE" // @query-part
						+ Chars.LF + StrConcat(ElementsOfCompositeDataPath, Chars.LF) + Chars.LF
						+ "END)"; //@ query-part
				EndIf;
			EndIf;
			PartsOfExpression.Delete(0);
			If PartsOfExpression.Count() > 0 Then
				ProcessingOfFormulas.ExpandOperandString(TreeRow);
			EndIf;
			CurrentTreeRow = TreeRow;
		EndDo;
		If ConnectionsTexts.Count() > 0 Then
			DataForRequest.QueryTextFragments.TextOfConnections = ?(IsBlankString(
				DataForRequest.QueryTextFragments.TextOfConnections), Chars.Tab,
				DataForRequest.QueryTextFragments.TextOfConnections + Chars.LF + Chars.Tab) + StrConcat(
				ConnectionsTexts, Chars.LF + Chars.Tab);
		EndIf;
	Else
		QueryExpression = "AliasOfSourceTable." + OriginalExpression;
	EndIf;
	
	Return QueryExpression;

EndFunction

Function ConvertDataLayoutSelectionToQueryConditionText(Filter, DataForRequest, AvailableFields, AttributeTree,
	GroupTypeOfSelectionElements = Undefined)
	
	ConditionText = "";
	
	For Each Item In Filter.Items Do
	
		If Not Item.Use Then
			Continue;
		EndIf;
		
		If IsBlankString(ConditionText) Then
			ConditionConnector = "";
		ElsIf GroupTypeOfSelectionElements = DataCompositionFilterItemsGroupType.OrGroup Then
			ConditionConnector = Chars.LF + "OR " // @query-part
		Else
			ConditionConnector = Chars.LF + "AND "; // @query-part
		EndIf;
		
		If TypeOf(Item) = Type("DataCompositionFilterItemGroup") Then
		
			TextOfSelectionCriteria = ConvertDataLayoutSelectionToQueryConditionText(Item, DataForRequest,
				AvailableFields, AttributeTree, Item.GroupType);
			If Not IsBlankString(TextOfSelectionCriteria) Then
				ConditionText = ConditionText + ConditionConnector + ?(GroupTypeOfSelectionElements
					= DataCompositionFilterItemsGroupType.NotGroup, "NOT (", "(") + TextOfSelectionCriteria + ")";// @query-part
			EndIf;
		
		Else
		
			If Not ValueIsFilled(Item.LeftValue) Then
				Continue;
			ElsIf AvailableFields.FindField(Item.LeftValue) = Undefined Then
				Continue;
			EndIf;
			
			QueryExpression = ExpressionOfFieldToPutInQueryText(TrimAll(Item.LeftValue),
				DataForRequest, AvailableFields, AttributeTree);
			
			If TypeOf(Item.RightValue) = Type("ValueList") Then
				ParameterValue = Item.RightValue.UnloadValues();
			Else
				ParameterValue = Item.RightValue;
			EndIf;
			StringParameterValue = FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(ParameterValue);
			If StrStartsWith(StringParameterValue, "Parameter") Then
				StringParameterValue = "&" + StringParameterValue;
			EndIf;
			
			SelectionCriteria = "";
			If Item.ComparisonType = DataCompositionComparisonType.Equal Then
				SelectionCriteria = QueryExpression + " = " + StringParameterValue;
			ElsIf Item.ComparisonType = DataCompositionComparisonType.NotEqual Then
				SelectionCriteria = QueryExpression + " <> " + StringParameterValue;
			ElsIf Item.ComparisonType = DataCompositionComparisonType.Greater Then
				SelectionCriteria = QueryExpression + " > " + StringParameterValue;
			ElsIf Item.ComparisonType = DataCompositionComparisonType.GreaterOrEqual Then
				SelectionCriteria = QueryExpression + " >= " + StringParameterValue;
			ElsIf Item.ComparisonType = DataCompositionComparisonType.Less Then
				SelectionCriteria = QueryExpression + " < " + StringParameterValue;
			ElsIf Item.ComparisonType = DataCompositionComparisonType.Greater Then
				SelectionCriteria = QueryExpression + " <= " + StringParameterValue;
			ElsIf Item.ComparisonType = DataCompositionComparisonType.InList Then
				SelectionCriteria = QueryExpression + " IN (" + StringParameterValue + ")"; // @query-part
			ElsIf Item.ComparisonType = DataCompositionComparisonType.NotInList Then
				SelectionCriteria = "NOT " + QueryExpression + " IN (" + StringParameterValue + ")"; // @query-part
			ElsIf Item.ComparisonType = DataCompositionComparisonType.InHierarchy
				Or Item.ComparisonType = DataCompositionComparisonType.InListByHierarchy Then
				SelectionCriteria = QueryExpression + " IN HIERARCHY (" + StringParameterValue + ")"; // @query-part
			ElsIf Item.ComparisonType = DataCompositionComparisonType.NotInHierarchy
				Or Item.ComparisonType = DataCompositionComparisonType.NotInListByHierarchy Then
				SelectionCriteria = "NOT " + QueryExpression + " IN HIERARCHY (" + StringParameterValue + ")"; // @query-part
			ElsIf Item.ComparisonType = DataCompositionComparisonType.Contains Then
				StringParameterValue = Common.GenerateSearchQueryString(StringParameterValue);
				SelectionCriteria = QueryExpression + " LIKE ""%""+" + StringParameterValue + "+""%"" ESCAPE ""~"""; // @query-part
			ElsIf Item.ComparisonType = DataCompositionComparisonType.NotContains Then
				StringParameterValue = Common.GenerateSearchQueryString(StringParameterValue);
				SelectionCriteria = "NOT " + QueryExpression + " LIKE ""%""+" + StringParameterValue
					+ "+""%"" ESCAPE ""~"""; // @query-part
			ElsIf Item.ComparisonType = DataCompositionComparisonType.BeginsWith Then
				StringParameterValue = Common.GenerateSearchQueryString(StringParameterValue);
				SelectionCriteria = QueryExpression + " LIKE " + StringParameterValue + "+""%"" ESCAPE ""~"""; // @query-part
			ElsIf Item.ComparisonType = DataCompositionComparisonType.NotBeginsWith Then
				StringParameterValue = Common.GenerateSearchQueryString(StringParameterValue);
				SelectionCriteria = "NOT " + QueryExpression + " LIKE " + StringParameterValue
					+ "+""%"" ESCAPE ""~"""; // @query-part
			ElsIf Item.ComparisonType = DataCompositionComparisonType.Filled
				Or Item.ComparisonType = DataCompositionComparisonType.NotFilled Then
				ArrayOfEmptyValues_ = ArrayOfEmptyValuesByTypeDescription(AvailableFields.FindField(
					Item.LeftValue).ValueType);
				StringParameterValue = FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(
					ArrayOfEmptyValues_);
				If Item.ComparisonType = DataCompositionComparisonType.Filled Then
					SelectionCriteria = "(NOT " + QueryExpression + " IN (" + StringParameterValue + ") AND NOT "
						+ QueryExpression + " IS NULL)"; // @query-part
				Else
					SelectionCriteria = "(" + QueryExpression + " IN (" + StringParameterValue + ") OR "
						+ QueryExpression + " IS NULL)"; // @query-part
				EndIf;
			EndIf;
			If StrStartsWith(StringParameterValue, "&Parameter") Then
				ParameterName = StrReplace(StringParameterValue, "&", "");
				FindAndAddRequestParameter(ParameterName, ParameterValue,
					DataForRequest.QueryOptions);
				If "&"+ParameterName <> StringParameterValue Then
					SelectionCriteria = StrReplace(SelectionCriteria, StringParameterValue, "&"+ParameterName);
				EndIf;
			EndIf;
			
			ConditionText = ConditionText + ConditionConnector + SelectionCriteria;
		
		EndIf;
	
	EndDo;
	
	Return ConditionText;
	
EndFunction

Function ArrayOfEmptyValuesByTypeDescription(TypeDescription)

	ArrayOfEmptyValues_ = New Array;
	
	For Each ValueType In TypeDescription.Types() Do
		If Common.IsReference(ValueType) Then
			MetadataByType = Metadata.FindByType(ValueType);
			If MetadataByType <> Undefined  Then
				ObjectManager = Common.ObjectManagerByFullName(MetadataByType.FullName());
				ArrayOfEmptyValues_.Add(ObjectManager.EmptyRef());
			EndIf;
		ElsIf ValueType = Type("String") Then
			ArrayOfEmptyValues_.Add("");
		ElsIf ValueType = Type("Number") Then
			ArrayOfEmptyValues_.Add(0);
		ElsIf ValueType = Type("Date") Then
			ArrayOfEmptyValues_.Add('00010101');
		ElsIf ValueType = Type("Boolean") Then
			ArrayOfEmptyValues_.Add(False);
		ElsIf ValueType = Type("UUID") Then
			ArrayOfEmptyValues_.Add(CommonClientServer.BlankUUID());
		EndIf;
	EndDo;
	
	If ArrayOfEmptyValues_.Count() > 1 Then
		ArrayOfEmptyValues_.Add(Undefined);
	EndIf;

	Return ArrayOfEmptyValues_;

EndFunction

Function CharacteristicParametersForQueryText(TypeDescription, ElementType, Id)
	
	CharacteristicParameters = New Array;
	
	ParametersByString = "Property,ObjectName,AliasOfSourceTable,PathToSourceTable,ObjectField,PropertyField,PropertyValueField";
	
	ItemsTypes = ProcessingOfFormulas.TypesOfOperandTreeElements();
	
	TypesOfValuesOfOwnerOfAdditionalProperty = TypeDescription.Types();
	UseObjectNameForAlias = (TypesOfValuesOfOwnerOfAdditionalProperty.Count() > 1);
	
	For Each ValueType In TypesOfValuesOfOwnerOfAdditionalProperty Do
		If Not Common.IsReference(ValueType) Then
			Continue;
		EndIf;
		MetadataByType = Metadata.FindByType(ValueType);
		If MetadataByType = Undefined Then
			Continue;
		EndIf;
		MetadataObjectName = MetadataByType.Name;
		FullMetadataObjectName = MetadataByType.FullName();
		EmptyValue = Common.ObjectManagerByFullName(FullMetadataObjectName).EmptyRef();
		
		ParametersStructure = New Structure(ParametersByString);
		
		If ElementType = ItemsTypes.AdditionalAttribute Then
			If Not PropertyManager.UseAddlAttributes(EmptyValue) Then
				Continue;
			Else
				AdditionalProperty = ChartsOfCharacteristicTypes.AdditionalAttributesAndInfo.FindByAttribute(
					"IDForFormulas", Id);
				If AdditionalProperty.IsEmpty() Then
					Raise(StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Không thể xác định mục tin bổ sung theo ID %1.';
							|ru = 'Не удалось определить дополнительный реквизит по идентификатору %1.';
							|en = 'Cannot identify the additional attribute by ID %1.'; fa = 'Cannot identify the additional attribute by ID %1.';
							|it = 'Не удалось определить дополнительный реквизит по идентификатору %1.';
							|pl = 'Cannot identify the additional attribute by ID %1.';
							|tr = '%1Tanımlayıcıya göre ek özellik belirlenemiyor'"),
						Id), ErrorCategory.StoredDataError);
				ElsIf Not PropertyManager.CheckObjectProperty(EmptyValue, AdditionalProperty) Then
					Continue;
				EndIf;
			EndIf;
			ParametersStructure.Property = AdditionalProperty;
			ParametersStructure.ObjectName = FullMetadataObjectName;
			ParametersStructure.AliasOfSourceTable = ?(UseObjectNameForAlias,
				MetadataObjectName, "") + Id;
			ParametersStructure.PathToSourceTable = FullMetadataObjectName + ".AdditionalAttributes";
			ParametersStructure.ObjectField = "Ref";
			ParametersStructure.PropertyField = "Property";
			ParametersStructure.PropertyValueField = "Value";
		ElsIf ElementType = ItemsTypes.AdditionalInfoItem Then
			If Not PropertyManager.UseAddlInfo(EmptyValue) Then
				Continue;
			Else
				AdditionalProperty = ChartsOfCharacteristicTypes.AdditionalAttributesAndInfo.FindByAttribute(
					"IDForFormulas", Id);
				If AdditionalProperty.IsEmpty() Then
					Raise(StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Không thể xác định thông tin bổ sung theo ID %1.';
							|ru = 'Не удалось определить дополнительное сведение по идентификатору %1.';
							|en = 'Cannot identify the additional information record by ID %1.'; fa = 'Cannot identify the additional information record by ID %1.';
							|it = 'Не удалось определить дополнительное сведение по идентификатору %1.';
							|pl = 'Cannot identify the additional information record by ID %1.';
							|tr = '%1Tanımlayıcıya göre ek özellik belirlenemiyor.'"),
						Id), ErrorCategory.StoredDataError);
				ElsIf Not PropertyManager.CheckObjectProperty(EmptyValue, AdditionalProperty) Then
					Continue;
				EndIf;
			EndIf;
			ParametersStructure.Property = AdditionalProperty;
			ParametersStructure.ObjectName = FullMetadataObjectName;
			ParametersStructure.AliasOfSourceTable = ?(UseObjectNameForAlias,
				MetadataObjectName, "") + Id;
			ParametersStructure.PathToSourceTable = "InformationRegister.AdditionalInfo";
			ParametersStructure.ObjectField = "Object";
			ParametersStructure.PropertyField = "Property";
			ParametersStructure.PropertyValueField = "Value";
		Else
			If Not ContactsManager.ContainsContactInformation(EmptyValue) Then
				Continue;
			Else
				If ValueType = Type("CatalogRef.ContactPersonsForPartners") Then
					ContactInformationGroup1 = Common.PredefinedItem(
						"Catalog.ContactInformationKinds.CatalogContactPersonsForPartners");
				ElsIf ValueType = Type("CatalogRef.Counterparties") Then
					ContactInformationGroup1 = Common.PredefinedItem(
						"Catalog.ContactInformationKinds.CatalogCounterparties");
				ElsIf ValueType = Type("CatalogRef.Companies") Then
					ContactInformationGroup1 = Common.PredefinedItem(
						"Catalog.ContactInformationKinds.CatalogCompanies");
				ElsIf ValueType = Type("CatalogRef.Partners") Then
					ContactInformationGroup1 = Common.PredefinedItem(
						"Catalog.ContactInformationKinds.CatalogPartners");
				ElsIf ValueType = Type("CatalogRef.Users") Then
					ContactInformationGroup1 = Common.PredefinedItem(
						"Catalog.ContactInformationKinds.CatalogUsers");
				ElsIf ValueType = Type("CatalogRef.Warehouses") Then
					ContactInformationGroup1 = Common.PredefinedItem(
						"Catalog.ContactInformationKinds.CatalogWarehouses");
				ElsIf ValueType = Type("CatalogRef.Persons") Then
					ContactInformationGroup1 = Common.PredefinedItem(
						"Catalog.ContactInformationKinds.CatalogPersons");
				Else
					Raise(StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Không thể xác định nhóm thông tin liên hệ đối với kiểu %1.';
							|ru = 'Не удалось определить группу контактной информации для типа %1.';
							|en = 'Cannot identify the contact information group for the %1 type.'; fa = 'Cannot identify the contact information group for the %1 type.';
							|it = 'Не удалось определить группу контактной информации для типа %1.';
							|pl = 'Cannot identify the contact information group for the %1 type.';
							|tr = '%1 türü için iletişim bilgileri grubu belirlenemedi.'"), String(
						ValueType)), ErrorCategory.StoredDataError);
				EndIf;
				AdditionalProperty = Catalogs.ContactInformationKinds.FindByAttribute(
					"IDForFormulas", Id, ContactInformationGroup1);
				If AdditionalProperty.IsEmpty() Then
					Raise(StringFunctionsClientServer.SubstituteParametersToString(
						NStr(
						"vi = 'Không thể xác định dạng thông tin liên hệ theo ID %1 đối với kiểu %2.';
						|ru = 'Не удалось определить вид контактной информации по идентификатору %1 для типа %2.';
						|en = 'Cannot identify the contact information kind by ID %1 for the %2 type.'; fa = 'Cannot identify the contact information kind by ID %1 for the %2 type.';
						|it = 'Не удалось определить вид контактной информации по идентификатору %1 для типа %2.';
						|pl = 'Cannot identify the contact information kind by ID %1 for the %2 type.';
						|tr = '%2 türü için %1 tanımlayıcısına göre iletişim bilgilerinin türü belirlenemedi.'"),
						Id, String(ValueType)), ErrorCategory.StoredDataError);
				EndIf;
			EndIf;
			ParametersStructure.Property = AdditionalProperty;
			ParametersStructure.ObjectName = FullMetadataObjectName;
			ParametersStructure.AliasOfSourceTable = ?(UseObjectNameForAlias,
				MetadataObjectName, "") + Id;
			ParametersStructure.PathToSourceTable = FullMetadataObjectName + ".ContactInformation";
			ParametersStructure.ObjectField = "Ref";
			ParametersStructure.PropertyField = "KindForList";
			ParametersStructure.PropertyValueField = "Presentation";
		EndIf;
		CharacteristicParameters.Add(ParametersStructure);
		
	EndDo;
	
	Return CharacteristicParameters;
	
EndFunction

Procedure FindAndAddRequestParameter(ParameterName, ParameterValue, QueryOptions)
	
	If TypeOf(ParameterValue) = Type("Array") Then
		QueryOptions.Insert(ParameterName, ParameterValue);
	Else
		ParameterValueFound = False;
		For Each Parameter In QueryOptions Do
			If ParameterValue = Parameter.Value Then
				ParameterValueFound = True;
				Break;
			EndIf;
		EndDo;
		If ParameterValueFound Then
			ParameterName = Parameter.Key;
		Else
			QueryOptions.Insert(ParameterName, ParameterValue);
		EndIf;
	EndIf;
	
EndProcedure

#Region FormationOfDataCompositionSchemaRulesForObtainingFactsByItemsOfAssetsLiabilities

Function DataCompositionSchemaOfFactOfArticleByCorrespondenceOfArticlesOfAssetsLiabilities(RuleDetails)
	
	If TypeOf(RuleDetails.DataSource) <> Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems") Then
		Raise NStr("vi = 'Loại nguồn nhận dữ liệu không hợp lệ.';
					|ru = 'Недопустимый тип источника получения данных.';
					|en = 'Invalid type of data receipt source.'; fa = 'Invalid type of data receipt source.';
					|it = 'Tipo di origine dati non valido.';
					|pl = 'Niedopuszczalny typ źródła pobierania danych.';
					|tr = 'Veri alım kaynağının kabul edilemeyecek türü'");
	EndIf;
	
	If TypeOf(RuleDetails.CorDataSource) <> Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems") Then
		Raise NStr("vi = 'Loại nguồn đối ứng nhận dữ liệu không hợp lệ.';
					|ru = 'Недопустимый тип корреспондирующего источника получения данных.';
					|en = 'Invalid type of corresponding data source.'; fa = 'Invalid type of corresponding data source.';
					|it = 'Invalid type of corresponding data source.';
					|pl = 'Invalid type of corresponding data source.';
					|tr = 'Veri alımı için geçersiz ilgili kaynak türü'");
	EndIf;
	
	DataSourceDescription = ChartsOfCharacteristicTypes.AssetLiabilityItems.DescriptionOfFinancialAccountingObject(RuleDetails.DataSource);
	DescriptionOfCorDataSource = ChartsOfCharacteristicTypes.AssetLiabilityItems.DescriptionOfFinancialAccountingObject(RuleDetails.CorDataSource);
	
	If DataSourceDescription = Undefined Or IsBlankString(DataSourceDescription.DataSource) Then
		Raise NStr("vi = 'Nguồn nhận dữ liệu không hợp lệ.';
					|ru = 'Недопустимый источник получения данных.';
					|en = 'Invalid data source.'; fa = 'Invalid data source.';
					|it = 'Invalid data source.';
					|pl = 'Invalid data source.';
					|tr = 'Veri alımı için geçersiz kaynak.'");
	EndIf;
	
	If DescriptionOfCorDataSource = Undefined Then
		Raise NStr("vi = 'Nguồn đối ứng nhận dữ liệu không hợp lệ.';
					|ru = 'Недопустимый корреспондирующий источник получения данных.';
					|en = 'Invalid corresponding data source.'; fa = 'Invalid corresponding data source.';
					|it = 'Invalid corresponding data source.';
					|pl = 'Invalid corresponding data source.';
					|tr = 'Veri alımı için geçersiz ilgili kaynak'");
	EndIf;
	
	If ValueIsFilled(RuleDetails.TransactionAmountSource)
		And DataSourceDescription.Indicators[RuleDetails.TransactionAmountSource] = Undefined Then
		Raise NStr("vi = 'Nguồn nhận dữ liệu không hợp lệ.';
					|ru = 'Недопустимый источник получения суммы.';
					|en = 'Invalid amount source.'; fa = 'Invalid amount source.';
					|it = 'Invalid amount source.';
					|pl = 'Invalid amount source.';
					|tr = 'Tutar alımı için geçersiz kaynak.'");
	EndIf;
	
	If IsBlankString(DescriptionOfCorDataSource.DataSource) Then
		DataCompositionSchema = DataCompositionSchemaOfFactOfArticleAccordingToArticleOfAssetsLiabilities(RuleDetails);
		
		CorReflectionParametersInAccounting = FinancialAccountingByBalanceSheetRegisterData.ParametersForReflectingRegisteredRecordsInFinancialAccounting();
		CorReflectionParametersInAccounting.PathToDataDivision =
			FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(Catalogs.BusinessStructure.EmptyRef());
		CorReflectionParametersInAccounting.PathToDataLineOfBusiness =
			FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(Catalogs.LinesOfBusiness.EmptyRef());
		CorReflectionParametersInAccounting.DataPathCurrency =
			FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(Catalogs.Currencies.EmptyRef());
		
		CoreFieldsOfDataSet = New Structure();
		DescriptionOfRequestFieldsCorSource = DescriptionOfDataSourceRequestFieldsArticlesAssetsLiabilities();
		AddFieldsOfSetWithFieldsOfStandardMeasurements(DescriptionOfRequestFieldsCorSource, CoreFieldsOfDataSet, DescriptionOfCorDataSource, CorReflectionParametersInAccounting);
		
		NameOfSourceFieldsFolder = NameOfDataSourceFieldsFolder();
		NameOfSourceFieldFolderCor = NameOfFolderOfFieldsOfCorDataSource();
		
		DataSet = DataCompositionSchema.DataSets[0];
		FinancialReportingServer.NewSetGroup(DataSet, NameOfSourceFieldFolderCor, DescriptionOfCorDataSource.Presentation);
		
		For Each KeyAndValue In CoreFieldsOfDataSet Do
			FieldName = KeyAndValue.Key;
			FieldDetails = KeyAndValue.Value; // See FinancialAccountingByBalanceSheetRegisterData.DescriptionOfDataSourceField
			
			If DescriptionOfRequestFieldsCorSource.BalancedFields.Find(FieldName) <> Undefined
			 Or DataSet.Fields.Find(NameOfSourceFieldsFolder + "." + FieldName) = Undefined Then
				Continue;
			EndIf;
			
			PostfixOfFieldHeaders = " " + NStr("vi = '(đối ứng)';
												|ru = '(кор.)';
												|en = '(cor.)'; fa = '(cor.)';
												|it = '(cor.)';
												|pl = '(cor.)';
												|tr = '(ilgili)'");
			FieldTitle = FieldDetails.Title + PostfixOfFieldHeaders;
			DataPath = NameOfSourceFieldFolderCor + "." + FieldName;
			FieldType = FieldDetails.Type;
			FinancialReportingServer.NewSetField(DataSet, FieldName, DataPath, FieldTitle, FieldType);
		EndDo;
		
		Return DataCompositionSchema;
	EndIf;
	
	DataSourceManager = AccumulationRegisters[DataSourceDescription.DataSource]; // AccumulationRegisterManager -
	DataSourceMetadata = DataSourceManager.CreateRecordSet().Metadata();
	AccountingReflectionParameters = DataSourceManager.ParametersForReflectingRegisteredRecordsInFinancialAccounting(DataSourceMetadata);
	
	CorDataSourceManager = AccumulationRegisters[DescriptionOfCorDataSource.DataSource]; // AccumulationRegisterManager -
	MetadataOfCorDataSource = CorDataSourceManager.CreateRecordSet().Metadata();
	CorReflectionParametersInAccounting = CorDataSourceManager.ParametersForReflectingRegisteredRecordsInFinancialAccounting(MetadataOfCorDataSource);
	
	TemporaryTableQueryText = "
	|SELECT
	|	DataSourceAlias.Period AS Period,
	|	&AnalyticsFields AS AnalyticsFieldAliases,
	|	&ResourceFields AS ResourceFieldAliases
	|INTO TempTableOfDataSource
	|FROM
	|	&TableOfDataSource AS DataSourceAlias
	|WHERE
	|	DataSourceAlias.Active
	|	AND DataSourceAlias.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND &SourcePrivilegedMode = &PrivilegedMode
	|{WHERE
	|	(""DataSourceID"") AS DataSourceID,
	|	&FilterFields.* AS AliasesOfSelectionFields
	|}
	|INDEX BY
	|	AnalyticsFieldAliases
	|";
	
	FieldsOfSourceTempTable = New Structure();
	DescriptionOfSourceRequestFields = DescriptionOfDataSourceRequestFieldsArticlesAssetsLiabilities();
	DescriptionOfSourceRequestFields.TempTable = True;
	DescriptionOfSourceRequestFields.Factor = RuleDetails.TransactionAmountSource;
	
	AddFieldsOfSetWithFieldsOfStandardMeasurements(DescriptionOfSourceRequestFields, FieldsOfSourceTempTable, DataSourceDescription, AccountingReflectionParameters);
	AddSetFieldsWithBalancedDataSourceFields(DescriptionOfSourceRequestFields, FieldsOfSourceTempTable, DataSourceDescription, AccountingReflectionParameters);
	AddDataSourceAnalyticsFieldsToSetFields(DescriptionOfSourceRequestFields, FieldsOfSourceTempTable, AccountingReflectionParameters, True);
	AddDataSourceResourcesToSetFields(DescriptionOfSourceRequestFields, FieldsOfSourceTempTable, DataSourceDescription, AccountingReflectionParameters);
	
	FieldsOfTemporaryCorSourceTable = New Structure();
	DescriptionOfRequestFieldsCorSource = DescriptionOfDataSourceRequestFieldsArticlesAssetsLiabilities();
	DescriptionOfRequestFieldsCorSource.Correspondence = True;
	DescriptionOfRequestFieldsCorSource.TempTable = True;
	
	AddFieldsOfSetWithFieldsOfStandardMeasurements(DescriptionOfRequestFieldsCorSource, FieldsOfTemporaryCorSourceTable, DescriptionOfCorDataSource, CorReflectionParametersInAccounting);
	AddSetFieldsWithBalancedDataSourceFields(DescriptionOfRequestFieldsCorSource, FieldsOfTemporaryCorSourceTable, DescriptionOfCorDataSource, CorReflectionParametersInAccounting);
	AddDataSourceAnalyticsFieldsToSetFields(DescriptionOfRequestFieldsCorSource, FieldsOfTemporaryCorSourceTable, CorReflectionParametersInAccounting, True);
	AddDataSourceResourcesToSetFields(DescriptionOfRequestFieldsCorSource, FieldsOfTemporaryCorSourceTable, DescriptionOfCorDataSource, CorReflectionParametersInAccounting);
	
	TableOfDataSource = "AccumulationRegister." + DataSourceDescription.DataSource; //@query-part
	DataSourceCorTable = "AccumulationRegister." + DescriptionOfCorDataSource.DataSource; //@query-part
	
	QueriesTexts = New Array();
	Separator = "," + Chars.LF +Chars.Tab;
	
	QueryTextOfTemporarySourceTable = StrReplace(
		TemporaryTableQueryText,
		"&TableOfDataSource",
		TableOfDataSource);
	QueryTextOfTemporarySourceTable = StrReplace(
		QueryTextOfTemporarySourceTable,
		"&AnalyticsFields AS AnalyticsFieldAliases",
		StrConcat(DescriptionOfSourceRequestFields.AnalyticsFields, Separator));
	QueryTextOfTemporarySourceTable = StrReplace(
		QueryTextOfTemporarySourceTable,
		"&ResourceFields AS ResourceFieldAliases",
		StrConcat(DescriptionOfSourceRequestFields.ResourceFields, Separator));
	QueryTextOfTemporarySourceTable = StrReplace(
		QueryTextOfTemporarySourceTable,
		"&FilterFields.* AS AliasesOfSelectionFields",
		StrConcat(DescriptionOfSourceRequestFields.FilterFields, Separator));
	QueryTextOfTemporarySourceTable = StrReplace(
		QueryTextOfTemporarySourceTable,
		"AnalyticsFieldAliases",
		StrConcat(DescriptionOfSourceRequestFields.BalancedFields, Separator));
	QueryTextOfTemporarySourceTable = StrReplace(
		QueryTextOfTemporarySourceTable,
		"DataSourceAlias",
		DescriptionOfSourceRequestFields.DataSourceAlias);
	
	QueriesTexts.Add(QueryTextOfTemporarySourceTable);
	
	QueryTextOfTempTableCorSource = StrReplace(
		TemporaryTableQueryText,
		"&TableOfDataSource",
		DataSourceCorTable);
	QueryTextOfTempTableCorSource = StrReplace(
		QueryTextOfTempTableCorSource,
		"TempTableOfDataSource",
		"TempTableOfCorOfDataSource");
	QueryTextOfTempTableCorSource = StrReplace(
		QueryTextOfTempTableCorSource,
		"&AnalyticsFields AS AnalyticsFieldAliases",
		StrConcat(DescriptionOfRequestFieldsCorSource.AnalyticsFields, Separator));
	QueryTextOfTempTableCorSource = StrReplace(
		QueryTextOfTempTableCorSource,
		"&ResourceFields AS ResourceFieldAliases",
		StrConcat(DescriptionOfRequestFieldsCorSource.ResourceFields, Separator));
	QueryTextOfTempTableCorSource = StrReplace(
		QueryTextOfTempTableCorSource,
		"&FilterFields.* AS AliasesOfSelectionFields",
		StrConcat(DescriptionOfRequestFieldsCorSource.FilterFields, Separator));
	QueryTextOfTempTableCorSource = StrReplace(
		QueryTextOfTempTableCorSource,
		"AnalyticsFieldAliases",
		StrConcat(DescriptionOfRequestFieldsCorSource.BalancedFields, Separator));
	QueryTextOfTempTableCorSource = StrReplace(
		QueryTextOfTempTableCorSource,
		"DataSourceAlias",
		DescriptionOfRequestFieldsCorSource.DataSourceAlias);
	
	QueriesTexts.Add(QueryTextOfTempTableCorSource);
	
	QueryTextOfCorrespondenceOfSources = "
	|SELECT ALLOWED
	|	&AssetAndLiabilityItem AS DataSource,
	|	&CorArticleOfAssetsLiabilities AS CorDataSource,
	|	&PeriodsFields AS AliasesOfPeriodFields,
	|	&AnalyticsFields AS AnalyticsFieldAliases,
	|	&ResourceFields AS ResourceFieldAliases
	|{SELECT
	|	DataSource,
	|	CorDataSource,
	|	AliasesOfPeriodFields.*,
	|	AnalyticsFieldAliases.*,
	|	ResourceFieldAliases.*
	|}
	|FROM
	|	TempTableOfDataSource AS TableOfDataSource
	|	INNER JOIN TempTableOfCorOfDataSource AS TableCorDataSource
	|	ON TableOfDataSource.Period = TableCorDataSource.Period
	|	 AND TableOfDataSource.Recorder = TableCorDataSource.Recorder
	|	 AND TableOfDataSource.Organization = TableCorDataSource.Organization
	|	 AND TableOfDataSource.FinRecordID = TableCorDataSource.FinRecordID
	|	 AND CASE
	|		WHEN TableOfDataSource.BusinessTransactionSetting <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|			AND TableCorDataSource.BusinessTransactionSetting <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|			THEN TableOfDataSource.BusinessTransactionSetting = TableCorDataSource.BusinessTransactionSetting
	|		ELSE TRUE
	|	 END
	|	 AND TableOfDataSource.ReversingEntry = TableCorDataSource.ReversingEntry
	|WHERE
	|	&SourcePrivilegedMode = &PrivilegedMode
	|{WHERE
	|	(""DataSourceID"") AS DataSourceID,
	|	(&AssetAndLiabilityItem) AS DataSource,
	|	(&CorArticleOfAssetsLiabilities) AS CorDataSource,
	|	&PeriodsFields AS AliasesOfPeriodFields
	|}
	|GROUP BY
	|	&PeriodGroupingFields,
	|	&AnalyticsGroupingFields
	|";
	
	RequestFieldsDescription = DescriptionOfDataSourceRequestFieldsArticlesAssetsLiabilities();
	RequestFieldsDescription.DataSourceAlias = "TableOfDataSource";
	DatasetFields = FieldsOfDataCompositionSchemaSetForAssetLiabilityItem(True);
	
	For Each FieldName In DescriptionOfSourceRequestFields.ResourceFieldAliases Do
		DataPath = FinancialAccountingByBalanceSheetRegisterData.DataPathWithSourceAlias(
			FieldName, RequestFieldsDescription.DataSourceAlias);
		DataSourceField = "SUM(" + DataPath + ")"; //@query-part
		RequestFieldsDescription.ResourceFields.Add(DataSourceField + " AS " + FieldName); //@query-part
		RequestFieldsDescription.ResourceFieldAliases.Add(FieldName);
		DatasetFields.Insert(FieldName, Common.CopyRecursive(FieldsOfSourceTempTable[FieldName]));
		FieldsOfSourceTempTable.Delete(FieldName);
	EndDo;
	
	For Each KeyAndValue In FieldsOfSourceTempTable Do
		FieldName = KeyAndValue.Key;
		FieldDetails = KeyAndValue.Value; // See FinancialAccountingByBalanceSheetRegisterData.DescriptionOfDataSourceField
		FieldDetails.DataPath = FieldName;
	EndDo;
	
	AddDataSourceFieldsToSetFields(RequestFieldsDescription, DatasetFields, FieldsOfSourceTempTable);
	AddPeriodFieldsToSetFields(RequestFieldsDescription, DatasetFields, DataSourceDescription, AccountingReflectionParameters);
	
	For Each FieldName In DescriptionOfRequestFieldsCorSource.ResourceFieldAliases Do
		FieldsOfTemporaryCorSourceTable.Delete(FieldName);
	EndDo;
	
	For Each BalancesField In RequestFieldsDescription.BalancedFields Do
		If FieldsOfTemporaryCorSourceTable.Property(BalancesField) Then
			FieldsOfTemporaryCorSourceTable.Delete(BalancesField);
		EndIf;
	EndDo;
	
	For Each KeyAndValue In FieldsOfTemporaryCorSourceTable Do
		FieldName = KeyAndValue.Key;
		FieldDetails = KeyAndValue.Value; // See FinancialAccountingByBalanceSheetRegisterData.DescriptionOfDataSourceField
		FieldDetails.DataPath = FieldName;
	EndDo;
	
	RequestFieldsDescription.DataSourceAlias = "TableCorDataSource";
	AddDataSourceFieldsToSetFields(RequestFieldsDescription, DatasetFields, FieldsOfTemporaryCorSourceTable);
	
	DataSourceSelectionString = FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(RuleDetails.DataSource);
	SelectingSourceUsingParameter = StrStartsWith(DataSourceSelectionString, "Parameter");
	
	DataSourceCorSelectionString = FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(RuleDetails.CorDataSource);
	SelectingSourceCodeUsingParameter = StrStartsWith(DataSourceCorSelectionString, "Parameter");
	
	QueryTextOfCorrespondenceOfSources = StrReplace(
		QueryTextOfCorrespondenceOfSources,
		"&PeriodsFields AS AliasesOfPeriodFields",
		StrConcat(RequestFieldsDescription.PeriodsFields, Separator));
	QueryTextOfCorrespondenceOfSources = StrReplace(
		QueryTextOfCorrespondenceOfSources,
		"&AnalyticsFields AS AnalyticsFieldAliases",
		StrConcat(RequestFieldsDescription.AnalyticsFields, Separator));
	QueryTextOfCorrespondenceOfSources = StrReplace(
		QueryTextOfCorrespondenceOfSources,
		"&ResourceFields AS ResourceFieldAliases",
		StrConcat(RequestFieldsDescription.ResourceFields, Separator));
	QueryTextOfCorrespondenceOfSources = StrReplace(
		QueryTextOfCorrespondenceOfSources,
		"AliasesOfPeriodFields.*",
		StrConcat(RequestFieldsDescription.AliasesOfPeriodFields, Separator));
	QueryTextOfCorrespondenceOfSources = StrReplace(
		QueryTextOfCorrespondenceOfSources,
		"AnalyticsFieldAliases.*",
		StrConcat(RequestFieldsDescription.AnalyticsFieldAliases, Separator));
	QueryTextOfCorrespondenceOfSources = StrReplace(
		QueryTextOfCorrespondenceOfSources,
		"ResourceFieldAliases.*",
		StrConcat(RequestFieldsDescription.ResourceFieldAliases, Separator));
	QueryTextOfCorrespondenceOfSources = StrReplace(
		QueryTextOfCorrespondenceOfSources,
		"&PeriodGroupingFields",
		StrConcat(RequestFieldsDescription.PeriodGroupingFields, Separator));
	QueryTextOfCorrespondenceOfSources = StrReplace(
		QueryTextOfCorrespondenceOfSources,
		"&AnalyticsGroupingFields",
		StrConcat(RequestFieldsDescription.AnalyticsGroupingFields, Separator));
	QueryTextOfCorrespondenceOfSources = StrReplace(
		QueryTextOfCorrespondenceOfSources,
		"&AssetAndLiabilityItem",
		?(SelectingSourceUsingParameter, "&", "") + DataSourceSelectionString);
	QueryTextOfCorrespondenceOfSources = StrReplace(
		QueryTextOfCorrespondenceOfSources,
		"&CorArticleOfAssetsLiabilities",
		?(SelectingSourceCodeUsingParameter, "&", "") + DataSourceCorSelectionString);
	
	QueriesTexts.Add(QueryTextOfCorrespondenceOfSources);
	
	DataCompositionSchema = DataCompositionServer.EmptyCircuit();
	DataSetName = "DataSource";
	DataSet = DataCompositionServer.AddEmptyDataSet(DataCompositionSchema,, DataSetName);
	DataSet.AutoFillAvailableFields = False;
	DataSet.Query = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	
	NameOfSourceFieldsFolder = NameOfDataSourceFieldsFolder();
	NameOfSourceFieldFolderCor = NameOfFolderOfFieldsOfCorDataSource();
	
	FinancialReportingServer.NewSetGroup(DataSet, NameOfSourceFieldsFolder, DataSourceDescription.Presentation);
	FinancialReportingServer.NewSetGroup(DataSet, NameOfSourceFieldFolderCor, DescriptionOfCorDataSource.Presentation);
	
	SourceFieldsOutsideFolder = DataSourceFieldsOutsideFieldsFolder(RequestFieldsDescription, True);
	
	For Each KeyAndValue In DatasetFields Do
		FieldName = KeyAndValue.Key;
		FieldDetails = KeyAndValue.Value; // See FinancialAccountingByBalanceSheetRegisterData.DescriptionOfDataSourceField
		FieldTitle = FieldDetails.Title;
		FieldType = FieldDetails.Type;
		
		If SourceFieldsOutsideFolder.Find(FieldName) <> Undefined Then
			DataPath = FieldName;
		ElsIf FieldsOfTemporaryCorSourceTable.Property(FieldName) Then
			DataPath = NameOfSourceFieldFolderCor + "." + FieldName;
		Else
			DataPath = NameOfSourceFieldsFolder + "." + FieldName;
		EndIf;
		
		SetField = FinancialReportingServer.NewSetField(DataSet, FieldName, DataPath, FieldTitle, FieldType);
		
		If FieldName = "DataSourceID" Then
			SetField.UseRestriction.Condition = False;
		EndIf;
	EndDo;
	
	DataCompositionServer.AddParameter(DataCompositionSchema, "BeginOfPeriod",,, False);
	DataCompositionServer.AddParameter(DataCompositionSchema, "EndOfPeriod",,, False);
	DataCompositionServer.AddParameter(DataCompositionSchema, "PrivilegedMode",,, False);
	DataCompositionServer.AddParameter(DataCompositionSchema, "SourcePrivilegedMode",,, False);
	
	If SelectingSourceUsingParameter Then
		DataCompositionServer.AddParameter(DataCompositionSchema, DataSourceSelectionString,
			New TypeDescription("ChartOfCharacteristicTypesRef.AssetLiabilityItems"), RuleDetails.DataSource, False);
	EndIf;
	
	If SelectingSourceCodeUsingParameter Then
		DataCompositionServer.AddParameter(DataCompositionSchema, DataSourceCorSelectionString,
			New TypeDescription("ChartOfCharacteristicTypesRef.AssetLiabilityItems"), RuleDetails.CorDataSource, False);
	EndIf;
	
	For Each DataCompositionSchemaParameter In DataCompositionSchema.Parameters Do
		DataCompositionSchemaParameter.IncludeInAvailableFields = False;
		DataCompositionSchemaParameter.UseRestriction = True;
	EndDo;
	
	If DataSourceDescription.Filterdata_.Items.Count() > 0 Then
		DataCompositionClientServer.CopyElements(
			DataCompositionSchema.DefaultSettings.Filter,
			DataSourceDescription.Filterdata_);
	EndIf;
	
	If DescriptionOfCorDataSource.Filterdata_.Items.Count() > 0 Then
		FinancialAccountingByBalanceSheetRegisterData.CopyDataCompositionFilter(
			DataCompositionSchema.DefaultSettings.Filter,
			DescriptionOfCorDataSource.Filterdata_,
			PrefixOfFieldNamesCorOfDataSource());
	EndIf;
	
	Return DataCompositionSchema;
	
EndFunction

Function DataCompositionSchemaOfFactOfArticleAccordingToArticleOfAssetsLiabilities(RuleDetails)
	
	If TypeOf(RuleDetails.DataSource) <> Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems") Then
		Raise NStr("vi = 'Loại nguồn nhận dữ liệu không hợp lệ.';
					|ru = 'Недопустимый тип источника получения данных.';
					|en = 'Invalid type of data receipt source.'; fa = 'Invalid type of data receipt source.';
					|it = 'Tipo di origine dati non valido.';
					|pl = 'Niedopuszczalny typ źródła pobierania danych.';
					|tr = 'Veri alım kaynağının kabul edilemeyecek türü'");
	EndIf;
	
	DataSourceDescription = ChartsOfCharacteristicTypes.AssetLiabilityItems.DescriptionOfFinancialAccountingObject(RuleDetails.DataSource);
	
	If DataSourceDescription = Undefined Or IsBlankString(DataSourceDescription.DataSource) Then
		Raise NStr("vi = 'Nguồn nhận dữ liệu không hợp lệ.';
					|ru = 'Недопустимый источник получения данных.';
					|en = 'Invalid data source.'; fa = 'Invalid data source.';
					|it = 'Invalid data source.';
					|pl = 'Invalid data source.';
					|tr = 'Veri alımı için geçersiz kaynak.'");
	EndIf;
	
	If ValueIsFilled(RuleDetails.TransactionAmountSource)
		And DataSourceDescription.Indicators[RuleDetails.TransactionAmountSource] = Undefined Then
		Raise NStr("vi = 'Nguồn nhận số tiền không hợp lệ.';
					|ru = 'Недопустимый источник получения суммы.';
					|en = 'Invalid amount source.'; fa = 'Invalid amount source.';
					|it = 'Invalid amount source.';
					|pl = 'Invalid amount source.';
					|tr = 'Tutar alımı için geçersiz kaynak.'");
	EndIf;
	
	DataSourceManager = AccumulationRegisters[DataSourceDescription.DataSource]; // AccumulationRegisterManager -
	DataSourceMetadata = DataSourceManager.CreateRecordSet().Metadata();
	AccountingReflectionParameters = DataSourceManager.ParametersForReflectingRegisteredRecordsInFinancialAccounting(DataSourceMetadata);
	
	QueryText = "
	|SELECT ALLOWED
	|	&AssetAndLiabilityItem AS DataSource,
	|	&PeriodsFields AS AliasesOfPeriodFields,
	|	&AnalyticsFields AS AnalyticsFieldAliases,
	|	&ResourceFields AS ResourceFieldAliases
	|{SELECT
	|	DataSource,
	|	AliasesOfPeriodFields.*,
	|	AnalyticsFieldAliases.*,
	|	ResourceFieldAliases.*
	|}
	|FROM
	|	&TableOfDataSource AS DataSourceAlias
	|WHERE
	|	DataSourceAlias.Active
	|	AND DataSourceAlias.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND &SourcePrivilegedMode = &PrivilegedMode
	|{WHERE
	|	(""DataSourceID"") AS DataSourceID,
	|	(&AssetAndLiabilityItem) AS DataSource,
	|	&PeriodsFields AS AliasesOfPeriodFields,
	|	&FilterFields.* AS AliasesOfSelectionFields
	|}
	|GROUP BY
	|	&PeriodGroupingFields,
	|	&AnalyticsGroupingFields
	|";
	
	DatasetFields = FieldsOfDataCompositionSchemaSetForAssetLiabilityItem();
	RequestFieldsDescription = DescriptionOfDataSourceRequestFieldsArticlesAssetsLiabilities();
	RequestFieldsDescription.Factor = RuleDetails.TransactionAmountSource;
	
	AddFieldsOfSetWithFieldsOfStandardMeasurements(RequestFieldsDescription, DatasetFields, DataSourceDescription, AccountingReflectionParameters);
	AddPeriodFieldsToSetFields(RequestFieldsDescription, DatasetFields, DataSourceDescription, AccountingReflectionParameters);
	AddDataSourceAnalyticsFieldsToSetFields(RequestFieldsDescription, DatasetFields, AccountingReflectionParameters, True);
	AddDataSourceResourcesToSetFields(RequestFieldsDescription, DatasetFields, DataSourceDescription, AccountingReflectionParameters);
	
	TableOfDataSource = "AccumulationRegister." + DataSourceDescription.DataSource; //@query-part
	
	DataSourceSelectionString = FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(RuleDetails.DataSource);
	SelectingSourceUsingParameter = StrStartsWith(DataSourceSelectionString, "Parameter");
	
	Separator = "," + Chars.LF +Chars.Tab;
	
	QueryText = StrReplace(QueryText,
		"&TableOfDataSource",
		TableOfDataSource);
	QueryText = StrReplace(QueryText,
		"&PeriodsFields AS AliasesOfPeriodFields",
		StrConcat(RequestFieldsDescription.PeriodsFields, Separator));
	QueryText = StrReplace(QueryText,
		"&AnalyticsFields AS AnalyticsFieldAliases",
		StrConcat(RequestFieldsDescription.AnalyticsFields, Separator));
	QueryText = StrReplace(QueryText,
		"&ResourceFields AS ResourceFieldAliases",
		StrConcat(RequestFieldsDescription.ResourceFields, Separator));
	QueryText = StrReplace(QueryText,
		"&FilterFields.* AS AliasesOfSelectionFields",
		StrConcat(RequestFieldsDescription.FilterFields, Separator));
	QueryText = StrReplace(QueryText,
		"AliasesOfPeriodFields.*",
		StrConcat(RequestFieldsDescription.AliasesOfPeriodFields, Separator));
	QueryText = StrReplace(QueryText,
		"AnalyticsFieldAliases.*",
		StrConcat(RequestFieldsDescription.AnalyticsFieldAliases, Separator));
	QueryText = StrReplace(QueryText,
		"ResourceFieldAliases.*",
		StrConcat(RequestFieldsDescription.ResourceFieldAliases, Separator));
	QueryText = StrReplace(QueryText,
		"&PeriodGroupingFields",
		StrConcat(RequestFieldsDescription.PeriodGroupingFields, Separator));
	QueryText = StrReplace(QueryText,
		"&AnalyticsGroupingFields",
		StrConcat(RequestFieldsDescription.AnalyticsGroupingFields, Separator));
	QueryText = StrReplace(QueryText,
		"DataSourceAlias",
		RequestFieldsDescription.DataSourceAlias);
	QueryText = StrReplace(QueryText,
		"&AssetAndLiabilityItem",
		?(SelectingSourceUsingParameter, "&", "") + DataSourceSelectionString);
	
	DataCompositionSchema = DataCompositionServer.EmptyCircuit();
	DataSetName = "DataSource";
	DataSet = DataCompositionServer.AddEmptyDataSet(DataCompositionSchema,, DataSetName);
	DataSet.AutoFillAvailableFields = False;
	DataSet.Query = QueryText;
	
	NameOfSourceFieldsFolder = NameOfDataSourceFieldsFolder();
	FinancialReportingServer.NewSetGroup(DataSet, NameOfSourceFieldsFolder, DataSourceDescription.Presentation);
	SourceFieldsOutsideFolder = DataSourceFieldsOutsideFieldsFolder(RequestFieldsDescription);
	
	For Each KeyAndValue In DatasetFields Do
		FieldName = KeyAndValue.Key;
		FieldDetails = KeyAndValue.Value; // See FinancialAccountingByBalanceSheetRegisterData.DescriptionOfDataSourceField
		FieldTitle = FieldDetails.Title;
		FieldType = FieldDetails.Type;
		
		If SourceFieldsOutsideFolder.Find(FieldName) <> Undefined Then
			DataPath = FieldName;
		Else
			DataPath = NameOfSourceFieldsFolder + "." + FieldName;
		EndIf;
		
		SetField = FinancialReportingServer.NewSetField(DataSet, FieldName, DataPath, FieldTitle, FieldType);
		
		If FieldName = "DataSourceID" Then
			SetField.UseRestriction.Condition = False;
		EndIf;
	EndDo;
	
	DataCompositionServer.AddParameter(DataCompositionSchema, "BeginOfPeriod",,, False);
	DataCompositionServer.AddParameter(DataCompositionSchema, "EndOfPeriod",,, False);
	DataCompositionServer.AddParameter(DataCompositionSchema, "PrivilegedMode",,, False);
	DataCompositionServer.AddParameter(DataCompositionSchema, "SourcePrivilegedMode",,, False);
	
	If SelectingSourceUsingParameter Then
		DataCompositionServer.AddParameter(DataCompositionSchema, DataSourceSelectionString,
			New TypeDescription("ChartOfCharacteristicTypesRef.AssetLiabilityItems"), RuleDetails.DataSource, False);
	EndIf;
	
	For Each DataCompositionSchemaParameter In DataCompositionSchema.Parameters Do
		DataCompositionSchemaParameter.IncludeInAvailableFields = False;
		DataCompositionSchemaParameter.UseRestriction = True;
	EndDo;
	
	If DataSourceDescription.Filterdata_.Items.Count() > 0 Then
		DataCompositionClientServer.CopyElements(
			DataCompositionSchema.DefaultSettings.Filter,
			DataSourceDescription.Filterdata_);
	EndIf;
	
	Return DataCompositionSchema;
	
EndFunction

Function DataCompositionSchemaOfFactIndicatorForItemAssetsLiabilities(RuleDetails)
	
	If TypeOf(RuleDetails.DataSource) <> Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems") Then
		Raise NStr("vi = 'Loại nguồn nhận dữ liệu không hợp lệ.';
					|ru = 'Недопустимый тип источника получения данных.';
					|en = 'Invalid type of data receipt source.'; fa = 'Invalid type of data receipt source.';
					|it = 'Tipo di origine dati non valido.';
					|pl = 'Niedopuszczalny typ źródła pobierania danych.';
					|tr = 'Veri alım kaynağının kabul edilemeyecek türü'");
	EndIf;
	
	DataSourceDescription = ChartsOfCharacteristicTypes.AssetLiabilityItems.DescriptionOfFinancialAccountingObject(RuleDetails.DataSource);
	
	If DataSourceDescription = Undefined Or IsBlankString(DataSourceDescription.DataSource) Then
		Raise NStr("vi = 'Nguồn nhận dữ liệu không hợp lệ.';
					|ru = 'Недопустимый источник получения данных.';
					|en = 'Invalid data source.'; fa = 'Invalid data source.';
					|it = 'Invalid data source.';
					|pl = 'Invalid data source.';
					|tr = 'Veri alımı için geçersiz kaynak.'");
	EndIf;
	
	If ValueIsFilled(RuleDetails.TransactionAmountSource)
		And DataSourceDescription.Indicators[RuleDetails.TransactionAmountSource] = Undefined Then
		Raise NStr("vi = 'Nguồn nhận số tiền không hợp lệ.';
					|ru = 'Недопустимый источник получения суммы.';
					|en = 'Invalid amount source.'; fa = 'Invalid amount source.';
					|it = 'Invalid amount source.';
					|pl = 'Invalid amount source.';
					|tr = 'Tutar alımı için geçersiz kaynak.'");
	EndIf;
	
	DataSourceManager = AccumulationRegisters[DataSourceDescription.DataSource]; // AccumulationRegisterManager -
	DataSourceMetadata = DataSourceManager.CreateRecordSet().Metadata();
	AccountingReflectionParameters = DataSourceManager.ParametersForReflectingRegisteredRecordsInFinancialAccounting(DataSourceMetadata);
	AccumulationRegisterType = Metadata.ObjectProperties.AccumulationRegisterType;
	
	QueryText = "
	|SELECT ALLOWED
	|	&AssetAndLiabilityItem AS DataSource,
	|	&AnalyticsFields AS AnalyticsFieldAliases,
	|	&ResourceFields AS ResourceFieldAliases
	|{SELECT
	|	DataSource,
	|	AnalyticsFieldAliases.*,
	|	ResourceFieldAliases.*
	|}
	|FROM
	|	&TableOfDataSource AS DataSourceAlias
	|{WHERE
	|	&FilterFields.* AS AliasesOfSelectionFields
	|}
	|";
	
	DescriptionOfResources = DescriptionOfResourcesItemsOfAssetsLiabilities();
	DatasetFields = FieldsOfDataCompositionSchemaSetForAssetLiabilityItem();
	RequestFieldsDescription = DescriptionOfDataSourceRequestFieldsArticlesAssetsLiabilities();
	
	AddFieldsOfSetWithFieldsOfStandardMeasurements(RequestFieldsDescription, DatasetFields, DataSourceDescription, AccountingReflectionParameters);
	AddDataSourceAnalyticsFieldsToSetFields(RequestFieldsDescription, DatasetFields, AccountingReflectionParameters);
	
	If DataSourceMetadata.RegisterType = AccumulationRegisterType.Turnovers Then
		TableOfDataSource = 
			"AccumulationRegister.%1.Turnovers(,
			|	&PeriodLimit,
			|	Period,
			|	&SourcePrivilegedMode = &PrivilegedMode
			|	{(""DataSourceID"") AS DataSourceID,
			|	(&AssetAndLiabilityItem) AS DataSource,
			|	&TableFields.* AS AliasesOfTableFields
			|	})"; //@query-part
		
		CoefficientTotal = "CASE
			|		WHEN &DebitCondition THEN 1
			|		WHEN &ConditionCredit THEN -1
			|		ELSE 0
			|	END"; //@query-part
		
		DebitCondition = DataSourceDescription.DebitCondition;
		ConditionCredit = DataSourceDescription.ConditionCredit;
		
		If IsBlankString(DebitCondition) Then
			DebitCondition = AccountingReflectionParameters.DebitCondition;
		EndIf;
		
		If IsBlankString(ConditionCredit) Then
			ConditionCredit = AccountingReflectionParameters.ConditionCredit;
		EndIf;
		
		If IsBlankString(DebitCondition) Or IsBlankString(ConditionCredit) Then
			Raise NStr("vi = 'Chưa chỉ định quy tắc ghi nhận các khoản phát sinh vào bên Nợ và bên Có.';
						|ru = 'Не указаны правила отнесения оборотов к дебету и кредиту.';
						|en = 'The rules for allocating turnover to debit and credit are not specified.'; fa = 'The rules for allocating turnover to debit and credit are not specified.';
						|it = 'The rules for allocating turnover to debit and credit are not specified.';
						|pl = 'The rules for allocating turnover to debit and credit are not specified.';
						|tr = 'Ciroların borç ve alacağa tahsis edilme kuralları belirtilmemiş.'");
		EndIf;
		
		CoefficientTotal = StrReplace(CoefficientTotal, "&DebitCondition", DebitCondition);
		CoefficientTotal = StrReplace(CoefficientTotal, "&ConditionCredit", ConditionCredit);
		TypeOfResourceTotal = "Turnover"; //@query-part
	Else
		TableOfDataSource = 
			"AccumulationRegister.%1.Balance(
			|	&PeriodLimit,
			|	&SourcePrivilegedMode = &PrivilegedMode
			|	{(""DataSourceID"") AS DataSourceID,
			|	(&AssetAndLiabilityItem) AS DataSource,
			|	&TableFields.* AS AliasesOfTableFields
			|	})"; //@query-part
		
		InversionOfRegisteredRecords = ChartsOfCharacteristicTypes.AssetLiabilityItems.InversionOfArticleSRegisteredRecordsByIndicator(
			DataSourceDescription, RuleDetails.TransactionAmountSource);
		
		If Not InversionOfRegisteredRecords Then
			InversionOfRegisteredRecords = AccountingReflectionParameters.InversionOfRegisteredRecords;
		EndIf;
		
		CoefficientTotal = ?(InversionOfRegisteredRecords, "-1", "1"); //@query-part
		TypeOfResourceTotal = "Balance"; //@query-part
	EndIf;
	
	For Each KeyAndValue In DescriptionOfResources Do
		FieldName = KeyAndValue.Key;
		FieldDetails = KeyAndValue.Value; // See FinancialAccountingByBalanceSheetRegisterData.DescriptionOfDataSourceField
		
		If ValueIsFilled(RuleDetails.TransactionAmountSource) Then
			ResourceComposition = DataSourceDescription.Indicators[RuleDetails.TransactionAmountSource][FieldDetails.DataPath];
		Else
			ResourceComposition = DataSourceDescription[FieldDetails.DataPath];
		EndIf;
		
		If ResourceComposition.Count() = 0 Then
			Continue;
		EndIf;
		
		DataSourceFields = New Array();
		
		For Each ResourceField In ResourceComposition Do
			DataPath = FinancialAccountingByBalanceSheetRegisterData.DataPathWithSourceAlias(
				ResourceField.ResourceName, RequestFieldsDescription.DataSourceAlias);
			ZoomRatio = ResourceField.ZoomRatio;
			If ZoomRatio <> 0 Then
				DataSourceFields.Add(?(ZoomRatio < 0, "-", "") + DataPath + TypeOfResourceTotal); //@query-part
			EndIf;
		EndDo;
		
		If DataSourceFields.Count() = 0 Then
			Continue;
		EndIf;
		
		DataSourceField = CoefficientTotal + " * (" + StrConcat(DataSourceFields, " + ") + ")"; //@query-part
		RequestFieldsDescription.ResourceFields.Add(DataSourceField + " AS " + FieldName); //@query-part
		RequestFieldsDescription.ResourceFieldAliases.Add(FieldName);
		DatasetFields.Insert(FieldName, FieldDetails);
	EndDo;
	
	DataSourceSelectionString = FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(RuleDetails.DataSource);
	SelectingSourceUsingParameter = StrStartsWith(DataSourceSelectionString, "Parameter");
	
	Separator = "," + Chars.LF +Chars.Tab;
	
	QueryText = StrReplace(QueryText,
		"&TableOfDataSource",
		StrTemplate(TableOfDataSource, DataSourceDescription.DataSource));
	QueryText = StrReplace(QueryText,
		"&AnalyticsFields AS AnalyticsFieldAliases",
		StrConcat(RequestFieldsDescription.AnalyticsFields, Separator));
	QueryText = StrReplace(QueryText,
		"&ResourceFields AS ResourceFieldAliases",
		StrConcat(RequestFieldsDescription.ResourceFields, Separator));
	QueryText = StrReplace(QueryText,
		"&TableFields.* AS AliasesOfTableFields",
		StrConcat(RequestFieldsDescription.TableFields, Separator));
	QueryText = StrReplace(QueryText,
		"&FilterFields.* AS AliasesOfSelectionFields",
		StrConcat(RequestFieldsDescription.FilterFields, Separator));
	QueryText = StrReplace(QueryText,
		"AnalyticsFieldAliases.*",
		StrConcat(RequestFieldsDescription.AnalyticsFieldAliases, Separator));
	QueryText = StrReplace(QueryText,
		"ResourceFieldAliases.*",
		StrConcat(RequestFieldsDescription.ResourceFieldAliases, Separator));
	QueryText = StrReplace(QueryText,
		"DataSourceAlias",
		RequestFieldsDescription.DataSourceAlias);
	QueryText = StrReplace(QueryText,
		"&AssetAndLiabilityItem",
		?(SelectingSourceUsingParameter, "&", "") + DataSourceSelectionString);
	
	DataCompositionSchema = DataCompositionServer.EmptyCircuit();
	DataSetName = "DataSource";
	DataSet = DataCompositionServer.AddEmptyDataSet(DataCompositionSchema,, DataSetName);
	DataSet.AutoFillAvailableFields = False;
	DataSet.Query = QueryText;
	
	For Each KeyAndValue In DatasetFields Do
		FieldName = KeyAndValue.Key;
		FieldDetails = KeyAndValue.Value; // See FinancialAccountingByBalanceSheetRegisterData.DescriptionOfDataSourceField
		DataPath = FieldName;
		FieldTitle = FieldDetails.Title;
		FieldType = FieldDetails.Type;
		
		SetField = FinancialReportingServer.NewSetField(DataSet, FieldName, DataPath, FieldTitle, FieldType);
		
		If FieldName = "DataSourceID" Then
			SetField.UseRestriction.Condition = False;
		EndIf;
	EndDo;
	
	DataCompositionServer.AddParameter(DataCompositionSchema, "PeriodLimit",,, False);
	DataCompositionServer.AddParameter(DataCompositionSchema, "PrivilegedMode",,, False);
	DataCompositionServer.AddParameter(DataCompositionSchema, "SourcePrivilegedMode",,, False);
	
	If SelectingSourceUsingParameter Then
		DataCompositionServer.AddParameter(DataCompositionSchema, DataSourceSelectionString,
			New TypeDescription("ChartOfCharacteristicTypesRef.AssetLiabilityItems"), RuleDetails.DataSource, False);
	EndIf;
	
	For Each DataCompositionSchemaParameter In DataCompositionSchema.Parameters Do
		DataCompositionSchemaParameter.IncludeInAvailableFields = False;
		DataCompositionSchemaParameter.UseRestriction = True;
	EndDo;
	
	If DataSourceDescription.Filterdata_.Items.Count() > 0 Then
		DataCompositionClientServer.CopyElements(
			DataCompositionSchema.DefaultSettings.Filter,
			DataSourceDescription.Filterdata_);
	EndIf;
	
	Return DataCompositionSchema;
	
EndFunction

Function DescriptionOfDataSourceRequestFieldsArticlesAssetsLiabilities()
	
	RequestFieldsDescription = New Structure();
	
	RequestFieldsDescription.Insert("PeriodsFields", New Array());
	RequestFieldsDescription.Insert("AnalyticsFields", New Array());
	RequestFieldsDescription.Insert("ResourceFields", New Array());
	RequestFieldsDescription.Insert("TableFields", New Array());
	RequestFieldsDescription.Insert("FilterFields", New Array());
	RequestFieldsDescription.Insert("AliasesOfPeriodFields", New Array());
	RequestFieldsDescription.Insert("AnalyticsFieldAliases", New Array());
	RequestFieldsDescription.Insert("ResourceFieldAliases", New Array());
	RequestFieldsDescription.Insert("PeriodGroupingFields", New Array());
	RequestFieldsDescription.Insert("AnalyticsGroupingFields", New Array());
	RequestFieldsDescription.Insert("BalancedFields", FinancialAccountingByBalanceSheetRegisterData.BalancedFieldsOfDataSources());
	RequestFieldsDescription.Insert("Correspondence", False);
	RequestFieldsDescription.Insert("TempTable", False);
	RequestFieldsDescription.Insert("Factor", Enums.IndicatorsOfAnalyticalRegisters.EmptyRef());
	RequestFieldsDescription.Insert("DataSourceAlias", FinancialAccountingByBalanceSheetRegisterData.DefaultDataSourceAlias());
	
	Return RequestFieldsDescription;
	
EndFunction

Function DescriptionOfResourcesItemsOfAssetsLiabilities()
	
	DescriptionOfResources = New Structure();
	AssetLiabilityItemManager = ChartsOfCharacteristicTypes.AssetLiabilityItems;
	
	DescriptionOfResources.Insert("SumMan",
		FinancialAccountingByBalanceSheetRegisterData.DescriptionOfDataSourceField(
			AssetLiabilityItemManager.ManagementAccountingResourcesGroup(),
			NStr("vi = 'Số tiền (quản trị)';
				|ru = 'Сумма (упр.)';
				|en = 'Amount, mgmt'; fa = 'مبلغ، مدیریت';
				|it = 'Importo (gest.)';
				|pl = 'Wartość (zarz.)';
				|tr = 'Tutar (yönetim)'"),
			CurrencyRateOperations.MoneyFieldTypeDescription()));
			
	DescriptionOfResources.Insert("SumCompl",
		FinancialAccountingByBalanceSheetRegisterData.DescriptionOfDataSourceField(
			AssetLiabilityItemManager.RegulatedAccountingResourcesGroup(),
			NStr("vi = 'Số tiền (quy định)';
				|ru = 'Сумма (регл.)';
				|en = 'Amount (local)'; fa = 'مبلغ (محلی)';
				|it = 'Importo (reg.)';
				|pl = 'Wartość (regl.)';
				|tr = 'Tutar (yerel)'"),
			CurrencyRateOperations.MoneyFieldTypeDescription()));
			
	DescriptionOfResources.Insert("AmountInCurrency",
		FinancialAccountingByBalanceSheetRegisterData.DescriptionOfDataSourceField(
			AssetLiabilityItemManager.CurrencyAccountingResourcesGroup(),
			NStr("vi = 'Số tiền theo tiền tệ';
				|ru = 'Сумма в валюте';
				|en = 'Amount in currency'; fa = 'مبلغ به ارز';
				|it = 'Importo in valuta';
				|pl = 'Suma w walucie';
				|tr = 'Para birimi cinsinden tutar'"),
			CurrencyRateOperations.MoneyFieldTypeDescription()));
			
	DescriptionOfResources.Insert("Count",
		FinancialAccountingByBalanceSheetRegisterData.DescriptionOfDataSourceField(
			AssetLiabilityItemManager.QuantitativeAccountingResourcesGroup(),
			NStr("vi = 'Số lượng';
				|ru = 'Количество';
				|en = 'Quantity'; fa = 'مقدار';
				|it = 'Quantity';
				|pl = 'Quantity';
				|tr = 'Miktar'"),
			Common.TypeDescriptionNumber(15, 3)));
	
	Return DescriptionOfResources;
	
EndFunction

Function FieldsOfDataCompositionSchemaSetForAssetLiabilityItem(Correspondence = False)
	
	DatasetFields = New Structure();
	
	DatasetFields.Insert("DataSource",
		FinancialAccountingByBalanceSheetRegisterData.DescriptionOfDataSourceField(
			"DataSource",
			NStr("vi = 'Nguồn dữ liệu';
				|ru = 'Источник данных';
				|en = 'Data source'; fa = 'منبع داده';
				|it = 'Origine dei dati';
				|pl = 'Źródło danych';
				|tr = 'Veri kaynağı'"),
			New TypeDescription("ChartOfCharacteristicTypesRef.AssetLiabilityItems")));
	
	If Correspondence Then
		DatasetFields.Insert("CorDataSource",
			FinancialAccountingByBalanceSheetRegisterData.DescriptionOfDataSourceField(
				"CorDataSource",
				NStr("vi = 'Nguồn dữ liệu (đối ứng)';
					|ru = 'Источник данных (кор.)';
					|en = 'Data source (cor.)'; fa = 'Data source (cor.)';
					|it = 'Data source (cor.)';
					|pl = 'Data source (cor.)';
					|tr = 'Veri kaynağı (ilgili)'"),
				New TypeDescription("ChartOfCharacteristicTypesRef.AssetLiabilityItems")));
	EndIf;
	
	DatasetFields.Insert("DataSourceID",
		FinancialAccountingByBalanceSheetRegisterData.DescriptionOfDataSourceField(
			"DataSourceID",
			NStr("vi = 'Mã số định danh nguồn dữ liệu';
				|ru = 'Идентификатор источника данных';
				|en = 'Data source ID'; fa = 'شناسه منبع داده';
				|it = 'Identificativo della sorgente di dati';
				|pl = 'Identyfikator źródła danych';
				|tr = 'Veri kaynağının tanımlayıcısı'"),
			Metadata.DefinedTypes.DataSourceID.Type));
	
	Return DatasetFields;
	
EndFunction

Procedure AddPeriodFieldsToSetFields(RequestFieldsDescription, DatasetFields, DataSourceDescription, AccountingReflectionParameters)
	
	DescriptionOfPeriods = New Structure();
	
	DescriptionOfPeriods.Insert("SecondPeriod",
		FinancialAccountingByBalanceSheetRegisterData.DescriptionOfDataSourceField(
			"", //@query-part
			NStr("vi = 'Kỳ, giây';
				|ru = 'Период, секунда';
				|en = 'Period, second'; fa = 'دوره، ثانیه';
				|it = 'Periodo, secondo';
				|pl = 'Okres, sekunda';
				|tr = 'Dönem, saniye'"),
			Common.DateTypeDetails(DateFractions.DateTime)));
	
	DescriptionOfPeriods.Insert("DayPeriod",
		FinancialAccountingByBalanceSheetRegisterData.DescriptionOfDataSourceField(
			"DAY", //@query-part
			NStr("vi = 'Kỳ, ngày';
				|ru = 'Период, день';
				|en = 'Period, day'; fa = 'دوره، روز';
				|it = 'Periodo, giorno';
				|pl = 'Okres, dzień';
				|tr = 'Dönem, gün'"),
			Common.DateTypeDetails(DateFractions.DateTime)));
	
	DescriptionOfPeriods.Insert("WeekPeriod",
		FinancialAccountingByBalanceSheetRegisterData.DescriptionOfDataSourceField(
			"WEEK", //@query-part
			NStr("vi = 'Kỳ, tuần';
				|ru = 'Период, неделя';
				|en = 'Period, week'; fa = 'دوره، هفته';
				|it = 'Periodo, settimana';
				|pl = 'Okres, tydzień';
				|tr = 'Dönem, hafta'"),
			Common.DateTypeDetails(DateFractions.DateTime)));
	
	DescriptionOfPeriods.Insert("TenDaysPeriod",
		FinancialAccountingByBalanceSheetRegisterData.DescriptionOfDataSourceField(
			"TENDAYS", //@query-part
			NStr("vi = 'Kỳ, 10 ngày';
				|ru = 'Период, декада';
				|en = 'Period, ten-day period'; fa = 'دوره، دهه';
				|it = 'Periodo, decade';
				|pl = 'Okres, dekada';
				|tr = 'Dönem, 10 günlük süre'"),
			Common.DateTypeDetails(DateFractions.DateTime)));
	
	DescriptionOfPeriods.Insert("MonthPeriod",
		FinancialAccountingByBalanceSheetRegisterData.DescriptionOfDataSourceField(
			"MONTH", //@query-part
			NStr("vi = 'Kỳ, tháng';
				|ru = 'Период, месяц';
				|en = 'Period, month'; fa = 'دوره، ماه';
				|it = 'Periodo, mese';
				|pl = 'Okres, miesiąc';
				|tr = 'Dönem, ay'"),
			Common.DateTypeDetails(DateFractions.DateTime)));
	
	DescriptionOfPeriods.Insert("QuarterPeriod",
		FinancialAccountingByBalanceSheetRegisterData.DescriptionOfDataSourceField(
			"QUARTER", //@query-part
			NStr("vi = 'Kỳ, quý';
				|ru = 'Период, квартал';
				|en = 'Period, quarter'; fa = 'دوره، فصل';
				|it = 'Periodo, trimestre';
				|pl = 'Okres, kwartał';
				|tr = 'Dönem, çeyrek'"),
			Common.DateTypeDetails(DateFractions.DateTime)));
	
	DescriptionOfPeriods.Insert("HalfYearPeriod",
		FinancialAccountingByBalanceSheetRegisterData.DescriptionOfDataSourceField(
			"HALFYEAR", //@query-part
			NStr("vi = 'Kỳ, nửa năm';
				|ru = 'Период, полугодие';
				|en = 'Period, half-year'; fa = 'دوره، نیم‌سال';
				|it = 'Periodo, semestre';
				|pl = 'Okres, półrocze';
				|tr = 'Dönem, yarıyıl'"),
			Common.DateTypeDetails(DateFractions.DateTime)));
	
	DescriptionOfPeriods.Insert("YearPeriod",
		FinancialAccountingByBalanceSheetRegisterData.DescriptionOfDataSourceField(
			"YEAR", //@query-part
			NStr("vi = 'Kỳ, năm';
				|ru = 'Период, год';
				|en = 'Period, year'; fa = 'دوره، سال';
				|it = 'Periodo, anno';
				|pl = 'Okres, rok';
				|tr = 'Dönem, yıl'"),
			Common.DateTypeDetails(DateFractions.DateTime)));
	
	If DatasetFields.Property("Currency") Then
		DescriptionOfPeriods.Insert("RatePeriod",
			FinancialAccountingByBalanceSheetRegisterData.DescriptionOfDataSourceField(
				"DAY", //@query-part
				NStr("vi = 'Thời gian khóa học';
					|ru = 'Период курса';
					|en = 'Rate period'; fa = 'دوره نرخ';
					|it = 'Periodo del tasso di cambio';
					|pl = 'Okres kursu';
					|tr = 'Kur dönemi'"),
				Common.DateTypeDetails(DateFractions.DateTime)));
	EndIf;
	
	For Each KeyAndValue In DescriptionOfPeriods Do
		FieldName = KeyAndValue.Key;
		FieldDetails = KeyAndValue.Value; // See FinancialAccountingByBalanceSheetRegisterData.DescriptionOfDataSourceField
		DataPath = "Period"; //@query-part
		PeriodType = FieldDetails.DataPath;
		
		DataSourceField = FinancialAccountingByBalanceSheetRegisterData.DataPathWithSourceAlias(
			DataPath, RequestFieldsDescription.DataSourceAlias);
			
		If Not IsBlankString(PeriodType) Then
			DataSourceField = "BEGINOFPERIOD(" + DataSourceField + ", " + PeriodType + ")"; //@query-part
		EndIf;
		
		RequestFieldsDescription.PeriodsFields.Add(DataSourceField + " AS " + FieldName); //@query-part
		RequestFieldsDescription.AliasesOfPeriodFields.Add(FieldName); //@query-part
		RequestFieldsDescription.PeriodGroupingFields.Add(DataSourceField); //@query-part
		
		DatasetFields.Insert(FieldName, FieldDetails);
	EndDo;
	
EndProcedure

Procedure AddFieldsOfSetWithFieldsOfStandardMeasurements(RequestFieldsDescription, DatasetFields, DataSourceDescription, AccountingReflectionParameters)
	
	DimensionsDetails = New Structure();
	
	DimensionsDetails.Insert("Organization",
		FinancialAccountingByBalanceSheetRegisterData.DescriptionOfDataSourceField(
			AccountingReflectionParameters.DataPathOrganization,
			NStr("vi = 'Doanh nghiệp';
				|ru = 'Организация';
				|en = 'Company'; fa = 'Company';
				|it = 'Azienda';
				|pl = 'Organizacja';
				|tr = 'İş yeri'"),
			New TypeDescription("CatalogRef.Companies")));
	
	DimensionsDetails.Insert("Department",
		FinancialAccountingByBalanceSheetRegisterData.DescriptionOfDataSourceField(
			AccountingReflectionParameters.PathToDataDivision,
			NStr("vi = 'Bộ phận';
				|ru = 'Подразделение';
				|en = 'Department'; fa = 'دپارتمان';
				|it = 'Reparto';
				|pl = 'Dział';
				|tr = 'Departman'"),
			New TypeDescription("CatalogRef.BusinessStructure")));
	
	DimensionsDetails.Insert("LineOfBusiness",
		FinancialAccountingByBalanceSheetRegisterData.DescriptionOfDataSourceField(
			?(IsBlankString(DataSourceDescription.PathToDataLineOfBusiness),
				AccountingReflectionParameters.PathToDataLineOfBusiness,
				DataSourceDescription.PathToDataLineOfBusiness),
			NStr("vi = 'Lĩnh vực hoạt động';
				|ru = 'Направление деятельности';
				|en = 'Line of business'; fa = 'خط کسب‌وکار';
				|it = 'Settore di attività';
				|pl = 'Rodzaj działalności';
				|tr = 'İş kolu'"),
			New TypeDescription("CatalogRef.LinesOfBusiness")));
	
	DimensionsDetails.Insert("Currency",
		FinancialAccountingByBalanceSheetRegisterData.DescriptionOfDataSourceField(
			AccountingReflectionParameters.DataPathCurrency,
			NStr("vi = 'Tiền tệ';
				|ru = 'Валюта';
				|en = 'Currency'; fa = 'ارز';
				|it = 'Currency';
				|pl = 'Currency';
				|tr = 'Para birimi'"),
			New TypeDescription("CatalogRef.Currencies")));
	
	AddDataSourceFieldsToSetFields(RequestFieldsDescription, DatasetFields, DimensionsDetails);
	
EndProcedure

Procedure AddSetFieldsWithBalancedDataSourceFields(RequestFieldsDescription, DatasetFields, DataSourceDescription, AccountingReflectionParameters)
	
	DescriptionOfBalanceFields = New Structure();
	
	DescriptionOfBalanceFields.Insert("FinRecordID",
		FinancialAccountingByBalanceSheetRegisterData.DescriptionOfDataSourceField(
			?(IsBlankString(DataSourceDescription.DataPathRecordFinID),
				AccountingReflectionParameters.DataPathRecordFinID,
				DataSourceDescription.DataPathRecordFinID),
			NStr("vi = 'Mã số định danh hồ sơ';
				|ru = 'Идентификатор фин. записи';
				|en = 'Fin. record ID'; fa = 'شناسه رکورد مالی';
				|it = 'Identificativo della registrazione finanziaria';
				|pl = 'Identyfikator wpisu finansowego';
				|tr = 'Finansal kayıt kimliği'"),
			Common.StringTypeDetails(36)));
	
	DescriptionOfBalanceFields.Insert("BusinessTransactionSetting",
		FinancialAccountingByBalanceSheetRegisterData.DescriptionOfDataSourceField(
			?(IsBlankString(DataSourceDescription.DataPathSettingUpHouseholdOperations),
				AccountingReflectionParameters.DataPathSettingUpHouseholdOperations,
				DataSourceDescription.DataPathSettingUpHouseholdOperations),
			NStr("vi = 'Thiết lập giao dịch kinh doanh';
				|ru = 'Настройка хозяйственной операции';
				|en = 'Business transactions setting'; fa = 'تنظیم عملیات تجاری';
				|it = 'Impostazione delle operazioni gestionali';
				|pl = 'Ustawienie operacji gospodarczej';
				|tr = 'Ticari işlem ayarı'"),
			New TypeDescription("CatalogRef.BusinessTransactionsSettings")));
	
	DescriptionOfBalanceFields.Insert("ReversingEntry",
		FinancialAccountingByBalanceSheetRegisterData.DescriptionOfDataSourceField(
			?(IsBlankString(AccountingReflectionParameters.DataPathIsStorno),
				"FALSE",
				AccountingReflectionParameters.DataPathIsStorno),
			NStr("vi = 'Đảo ngược';
				|ru = 'Сторно';
				|en = 'Storno'; fa = 'استورنو';
				|it = 'Storno';
				|pl = 'Storno';
				|tr = 'İptal'"),
			New TypeDescription("Boolean")));
	
	AddDataSourceFieldsToSetFields(RequestFieldsDescription, DatasetFields, DescriptionOfBalanceFields);
	
EndProcedure

Procedure AddDataSourceAnalyticsFieldsToSetFields(RequestFieldsDescription, DatasetFields, AccountingReflectionParameters, UseAttributes = False)
	
	AddDataSourceFieldsToSetFields(RequestFieldsDescription, DatasetFields, AccountingReflectionParameters.DimensionsDetails);
	
	If UseAttributes Then
		AddDataSourceFieldsToSetFields(RequestFieldsDescription, DatasetFields, AccountingReflectionParameters.AttributesDetails1);
	EndIf;
	
EndProcedure

Procedure AddDataSourceFieldsToSetFields(RequestFieldsDescription, DatasetFields, DescriptionOfDataSourceFields)
	
	DescriptionOfPrimitiveTypes = FinancialAccountingByBalanceSheetRegisterData.DescriptionOfPrimitiveTypes();
	
	For Each KeyAndValue In DescriptionOfDataSourceFields Do
		If RequestFieldsDescription.Correspondence
			And RequestFieldsDescription.BalancedFields.Find(KeyAndValue.Key) = Undefined Then
			FieldsNamesPrefix = PrefixOfFieldNamesCorOfDataSource();
			PostfixOfFieldHeaders = " " + NStr("vi = '(đối ứng)';
												|ru = '(кор.)';
												|en = '(cor.)'; fa = '(cor.)';
												|it = '(cor.)';
												|pl = '(cor.)';
												|tr = '(ilgili)'");
		Else
			FieldsNamesPrefix = "";
			PostfixOfFieldHeaders = "";
		EndIf;
		
		FieldName = FieldsNamesPrefix + KeyAndValue.Key;
		FieldDetails = KeyAndValue.Value; // See FinancialAccountingByBalanceSheetRegisterData.DescriptionOfDataSourceField
		FieldDetails.Title = FieldDetails.Title + PostfixOfFieldHeaders;
		
		If DatasetFields.Property(FieldName) Then
			Continue;
		ElsIf IsBlankString(FieldDetails.DataPath) Then
			Continue;
		Else
			DataPathAlreadyExists = False;
			For Each DataSetField In DatasetFields Do
				If DataSetField.Value.DataPath = FieldDetails.DataPath Then
					DataPathAlreadyExists = True;
					Break;
				EndIf;
			EndDo;
			If DataPathAlreadyExists Then
				Continue;
			EndIf;
		EndIf;
		
		TypePrimitive = DescriptionOfPrimitiveTypes.ContainsType(FieldDetails.Type.Types()[0]);
		TableField = FinancialAccountingByBalanceSheetRegisterData.DataPathWithoutSourceAlias(
			FieldDetails.DataPath, RequestFieldsDescription.DataSourceAlias);
		DataSourceField = FinancialAccountingByBalanceSheetRegisterData.DataPathWithSourceAlias(
			FieldDetails.DataPath, RequestFieldsDescription.DataSourceAlias);
		
		RequestFieldsDescription.AnalyticsFields.Add(DataSourceField + " AS " + FieldName); //@query-part
		RequestFieldsDescription.TableFields.Add("(" + TableField + ?(TypePrimitive, ")", ").*") + " AS " + FieldName); //@query-part
		RequestFieldsDescription.FilterFields.Add("(" + DataSourceField + ?(TypePrimitive, ")", ").*") + " AS " + FieldName); //@query-part
		RequestFieldsDescription.AnalyticsFieldAliases.Add(FieldName + ?(TypePrimitive, "", ".*")); //@query-part
		RequestFieldsDescription.AnalyticsGroupingFields.Add(DataSourceField); //@query-part
		
		DatasetFields.Insert(FieldName, FieldDetails);
	EndDo;
	
EndProcedure

Procedure AddDataSourceResourcesToSetFields(RequestFieldsDescription, DatasetFields, DataSourceDescription, AccountingReflectionParameters)
	
	DataSourceManager = AccumulationRegisters[DataSourceDescription.DataSource]; // AccumulationRegisterManager -
	DataSourceMetadata = DataSourceManager.CreateRecordSet().Metadata();
	AccumulationRegisterType = Metadata.ObjectProperties.AccumulationRegisterType;
	
	DebitCondition = DataSourceDescription.DebitCondition;
	ConditionCredit = DataSourceDescription.ConditionCredit;
	
	If RequestFieldsDescription.Correspondence Then
		FieldsNamesPrefix = PrefixOfFieldNamesCorOfDataSource();
		PostfixOfFieldHeaders = " " + NStr("vi = '(đối ứng)';
											|ru = '(кор.)';
											|en = '(cor.)'; fa = '(cor.)';
											|it = '(cor.)';
											|pl = '(cor.)';
											|tr = '(ilgili)'");
	Else
		FieldsNamesPrefix = "";
		PostfixOfFieldHeaders = "";
	EndIf;
	
	If DataSourceMetadata.RegisterType = AccumulationRegisterType.Turnovers Then
		If IsBlankString(DebitCondition) Then
			DebitCondition = AccountingReflectionParameters.DebitCondition;
		EndIf;
		
		If IsBlankString(ConditionCredit) Then
			ConditionCredit = AccountingReflectionParameters.ConditionCredit;
		EndIf;
		
		If IsBlankString(DebitCondition) Or IsBlankString(ConditionCredit) Then
			Raise NStr("vi = 'Chưa chỉ định quy tắc ghi nhận các khoản phát sinh vào bên Nợ và bên Có.';
						|ru = 'Не указаны правила отнесения оборотов к дебету и кредиту.';
						|en = 'The rules for allocating turnover to debit and credit are not specified.'; fa = 'The rules for allocating turnover to debit and credit are not specified.';
						|it = 'The rules for allocating turnover to debit and credit are not specified.';
						|pl = 'The rules for allocating turnover to debit and credit are not specified.';
						|tr = 'Ciroların borç ve alacağa tahsis edilme kuralları belirtilmemiş.'");
		EndIf;
	Else
		InversionOfRegisteredRecords = ChartsOfCharacteristicTypes.AssetLiabilityItems.InversionOfArticleSRegisteredRecordsByIndicator(
			DataSourceDescription, RequestFieldsDescription.Factor);
		
		If Not InversionOfRegisteredRecords Then
			InversionOfRegisteredRecords = AccountingReflectionParameters.InversionOfRegisteredRecords;
		EndIf;
		
		If IsBlankString(DebitCondition) Then
			If InversionOfRegisteredRecords Then
				DebitCondition = "DataSourceAlias.RecordType = VALUE(AccumulationRecordType.Expense)"; //@query-part;
			Else
				DebitCondition = "DataSourceAlias.RecordType = VALUE(AccumulationRecordType.Receipt)"; //@query-part;
			EndIf;
		EndIf;
		
		If IsBlankString(ConditionCredit) Then
			If InversionOfRegisteredRecords Then
				ConditionCredit = "DataSourceAlias.RecordType = VALUE(AccumulationRecordType.Receipt)"; //@query-part;
			Else
				ConditionCredit = "DataSourceAlias.RecordType = VALUE(AccumulationRecordType.Expense)"; //@query-part;
			EndIf;
		EndIf;
	EndIf;
	
	SpeedRatios = New Structure();
	SpeedRatios.Insert("TurnoverDr", StrReplace(
		"CASE
		|		WHEN &DebitCondition THEN 1
		|		ELSE 0
		|	END",
		"&DebitCondition",
		DebitCondition)); //@query-part;
	SpeedRatios.Insert("TurnoverCr", StrReplace(
		"CASE
		|		WHEN &ConditionCredit THEN 1
		|		ELSE 0
		|	END",
		"&ConditionCredit",
		 ConditionCredit)); //@query-part;
	SpeedRatios.Insert("Turnover", StrReplace(
		StrReplace(
		"CASE
		|		WHEN &DebitCondition THEN 1
		|		WHEN &ConditionCredit THEN -1
		|		ELSE 0
		|	END",
		"&DebitCondition",
		DebitCondition),
		"&ConditionCredit",
		 ConditionCredit)); //@query-part;
	
	DescriptionOfResources = DescriptionOfResourcesItemsOfAssetsLiabilities();
	For Each KeyAndValue In DescriptionOfResources Do
		FieldName = KeyAndValue.Key;
		FieldDetails = KeyAndValue.Value; // See FinancialAccountingByBalanceSheetRegisterData.DescriptionOfDataSourceField
		
		If ValueIsFilled(RequestFieldsDescription.Factor) Then
			ResourceComposition = DataSourceDescription.Indicators[RequestFieldsDescription.Factor][FieldDetails.DataPath];
		Else
			ResourceComposition = DataSourceDescription[FieldDetails.DataPath];
		EndIf;
		
		If ResourceComposition.Count() = 0 Then
			Continue;
		EndIf;
		
		DataSourceFields = New Array();
		
		For Each ResourceField In ResourceComposition Do
			DataPath = FinancialAccountingByBalanceSheetRegisterData.DataPathWithSourceAlias(
				ResourceField.ResourceName, RequestFieldsDescription.DataSourceAlias);
			ZoomRatio = ResourceField.ZoomRatio;
			If ZoomRatio <> 0 Then
				DataSourceFields.Add(?(ZoomRatio < 0, "-", "") + DataPath); //@query-part
			EndIf;
		EndDo;
		
		If DataSourceFields.Count() = 0 Then
			Continue;
		EndIf;
		
		For Each RatioTurnover In SpeedRatios Do
			TypeOfTurnover = RatioTurnover.Key;
			ZoomRatio = RatioTurnover.Value;
			TurnoverName = FieldsNamesPrefix + FieldName + TypeOfTurnover;
			
			If TypeOfTurnover = "TurnoverDr" Then
				TurnoverPresentation = NStr("vi = 'phát sinh Nợ';
											|ru = 'оборот Дт';
											|en = 'Dr turnover'; fa = 'گردش بدهکار';
											|it = 'Fatturato a debito';
											|pl = 'Obrót Wn';
											|tr = 'Borç ciro'");
			ElsIf TypeOfTurnover = "TurnoverCr" Then
				TurnoverPresentation = NStr("vi = 'phát sinh Có';
											|ru = 'оборот Кт';
											|en = 'Cr turnover'; fa = 'گردش بستانکار';
											|it = 'Fatturato a credito';
											|pl = 'obrót Ma';
											|tr = 'Alacak ciro'");
			Else
				TurnoverPresentation = NStr("vi = 'phát sinh';
											|ru = 'оборот';
											|en = 'turnover'; fa = 'turnover';
											|it = 'fatturato';
											|pl = 'turnover';
											|tr = 'Ciro'");
			EndIf;
			
			TurnoverPresentation = TurnoverPresentation + PostfixOfFieldHeaders;
			
			If RequestFieldsDescription.TempTable Then
				DataSourceField = ZoomRatio + " * (" + StrConcat(DataSourceFields, " + ") + ")"; //@query-part
			Else
				DataSourceField = "SUM(" + ZoomRatio + " * (" + StrConcat(DataSourceFields, " + ") + "))"; //@query-part
			EndIf;
			
			RequestFieldsDescription.ResourceFields.Add(DataSourceField + " AS " + TurnoverName); //@query-part
			RequestFieldsDescription.ResourceFieldAliases.Add(TurnoverName);
			
			DatasetFields.Insert(TurnoverName,
				FinancialAccountingByBalanceSheetRegisterData.DescriptionOfDataSourceField(
					TurnoverName,
					FieldDetails.Title + ", " + TurnoverPresentation,
					FieldDetails.Type));
		EndDo;
	EndDo;
	
EndProcedure

Function DataSourceFieldsOutsideFieldsFolder(RequestFieldsDescription, Correspondence = False)
	
	SourceFieldsOutsideFolder = New Array();
	
	For Each KeyAndValue In FieldsOfDataCompositionSchemaSetForAssetLiabilityItem(Correspondence) Do
		SourceFieldsOutsideFolder.Add(KeyAndValue.Key);
	EndDo;
	
	CommonClientServer.SupplementArray(SourceFieldsOutsideFolder, RequestFieldsDescription.BalancedFields);
	CommonClientServer.SupplementArray(SourceFieldsOutsideFolder, RequestFieldsDescription.AliasesOfPeriodFields);
	CommonClientServer.SupplementArray(SourceFieldsOutsideFolder, RequestFieldsDescription.ResourceFieldAliases);
	
	Return SourceFieldsOutsideFolder;
	
EndFunction

#EndRegion

#EndRegion