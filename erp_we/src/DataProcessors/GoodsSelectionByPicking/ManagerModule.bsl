#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// This function prepares the data structure required for printing price tags and labels.
//
// Parameters:
//  SettingsStructure - Structure - data, configuration structure.
//
// Returns:
//  Structure - data required for printing labels and price tags.
//
Function PrepareDataStructure(SettingsStructure) Export
	
	ResultStructure1 = New Structure;
	ResultStructure1.Insert("TableOfGoods",                             Undefined);
	ResultStructure1.Insert("CorrespondenceOfDCSFieldsToColumnsOfProductTable", New Map);

#Region PreparingDataLayoutSchemeAndDCSSettingsComposer
	
	// scheme of the layout.
	DataCompositionSchema = DataProcessors.GoodsSelectionByPicking.GetTemplate(SettingsStructure.NameOfDataLayoutSchemaTemplate);

	

	If SettingsStructure.Property("ExternalDataSourceSelectionIsUsed") Then
		
		ExternalDataSets = Undefined;
		
		If SettingsStructure.Property("TableOfGoods") Then
			ColumnsOfGoodsTable = SettingsStructure.TableOfGoods.Columns;
			ColumnsArray1 = New Array();

			If Not ColumnsOfGoodsTable.Find("PriceKind") = Undefined Then
				ColumnsArray1.Add("PriceKind");
			EndIf;
		
			If Not ColumnsOfGoodsTable.Find("Price") = Undefined Then
				ColumnsArray1.Add("Price");
			EndIf;

			ConfigureDatasets(DataCompositionSchema, ColumnsOfGoodsTable);

			AddColumnNames = StrConcat(ColumnsArray1, ", ");
			If ValueIsFilled(AddColumnNames) Then
				AddColumnNames = ", " + AddColumnNames;
			EndIf;
			
			ExternalDataSets = New Structure;
			TableForSource = SettingsStructure.TableOfGoods.Copy(, "Products, Characteristic, Series, Package" + AddColumnNames);// ValueTable
			TableForSource.GroupBy("Products, Characteristic, Series, Package" + AddColumnNames);
			
			ByBatch = False;
			ByPackage = False;
			
			If ColumnsOfGoodsTable.Find("Series") <> Undefined Then
				ByBatch = True;
				TableForSource.Columns.Add("SeriesForCommunication", New TypeDescription("CatalogRef.ItemsBatches"));
			EndIf;

			If ColumnsOfGoodsTable.Find("Package") <> Undefined Then
				ByPackage = True;
				TableForSource.Columns.Add("PackagingForCommunication", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
			EndIf;
			
			TableForSelection = TableForSource.Copy(, "Products");
			TableForSelection.GroupBy("Products");
			SelectionList_ = TableForSelection.UnloadColumn("Products");
			
			If ByBatch Or ByPackage Then
				PricingSettingsTable = GetPricingSettingsTable(SelectionList_);
				For Each Setting In PricingSettingsTable Do
					FoundRows = TableForSource.FindRows(New Structure("Products", Setting.Products));
					
					For Each FoundRow In FoundRows Do
						If ByBatch And Setting.ByBatch Then
							FoundRow.SeriesForCommunication = FoundRow.Series;
						EndIf;
						If ByPackage And Setting.ByPackage Then
							FoundRow.PackagingForCommunication = FoundRow.Package;
						EndIf;
					EndDo;
				EndDo;
			EndIf;
			
			ExternalDataSets.Insert("ProductsTable", TableForSource);
			
		EndIf;
	EndIf;

	// Preparing the data layout layout builder.
	Composer = New DataCompositionSettingsComposer;
	Composer.Initialize(New DataCompositionAvailableSettingsSource(DataCompositionSchema));
	Composer.LoadSettings(DataCompositionSchema.DefaultSettings);
	Composer.Settings.Filter.Items.Clear();
	Composer.Refresh(DataCompositionSettingsRefreshMethod.Full);
	
	// Selection and sorting of the settings linker.
	If SettingsStructure.SettingsComposer <> Undefined Then
		
		DataCompositionClientServer.CopyElements(
			Composer.Settings.Filter,
			SettingsStructure.SettingsComposer.Settings.Filter);
			
		DataCompositionClientServer.CopyElements(
			Composer.Settings.Order,
			SettingsStructure.SettingsComposer.Settings.Order);
			
	EndIf;

	

	UseProductRange = GetFunctionalOption("UseProductRange");
	If UseProductRange Then
		DataCompositionClientServer.SetParameter(Composer.Settings, "ProductRangeAsOfDate", CurrentSessionDate());
	EndIf;
	
	If SettingsStructure.Property("PricesAsOfDate") Then
		DataCompositionClientServer.SetParameter(Composer.Settings, "PricesAsOfDate", SettingsStructure.PricesAsOfDate);
	EndIf;
	
	If SettingsStructure.Property("DateOfReceiptOfBalances") Then
		
		DataCompositionClientServer.SetParameter(
			Composer.Settings,
			"DateOfReceiptOfBalances",
			New Boundary(SettingsStructure.DateOfReceiptOfBalances, BoundaryType.Including));
		
	EndIf;
	
	If SettingsStructure.Property("Vendor") Then
		DataCompositionClientServer.SetParameter(Composer.Settings, "Vendor", SettingsStructure.Vendor);
	EndIf;
	
	If SettingsStructure.Property("SelectionByTheOptionOfCalculatingThePricesOfSets") Then
		CommonClientServer.AddCompositionItem(
			Composer.Settings.Filter,
			"SetPricingOption",
			DataCompositionComparisonType.InList,
			SettingsStructure.SelectionByTheOptionOfCalculatingThePricesOfSets,
			Undefined,
			True,
			DataCompositionSettingsItemViewMode.QuickAccess);
	EndIf;
	
	If SettingsStructure.KeepRecordsOfQualityCertificates Then
		DataCompositionClientServer.SetParameter(Composer.Settings, "KeepRecordsOfQualityCertificates", True);
	EndIf;
	
	If SettingsStructure.Property("ExternalDataSourceSelectionIsUsed") Then
		
		If SettingsStructure.Property("TableOfGoods") Then
			
			CommonClientServer.AddCompositionItem(
				Composer.Settings.Filter,
				"Products",
				DataCompositionComparisonType.InList,
				SelectionList_,
				Undefined,
				True);
				
		EndIf;
	EndIf;
	
	// Selected fields of the settings builder.
	For Each RequiredField In SettingsStructure.RequiredFields Do
		DCSField = DataCompositionServer.FindDCSFieldByFullName(Composer.Settings.Selection.SelectionAvailableFields.Items, RequiredField);
		If DCSField <> Undefined Then
			SelectedField = Composer.Settings.Selection.Items.Add(Type("DataCompositionSelectedField"));
			SelectedField.Field = DCSField.Field;
		EndIf;
	EndDo;
	
	SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(Composer);

	// Layout layout of the data layout.
	TemplateComposer = New DataCompositionTemplateComposer;
	DataCompositionTemplate = TemplateComposer.Execute(
		DataCompositionSchema,
		Composer.GetSettings(),,,
		Type("DataCompositionValueCollectionTemplateGenerator"));

#EndRegion

#Region PreparingAuxiliaryDataForMatchingTemplateAndDCSFields
	
	For Each Field In DataCompositionTemplate.DataSets.DataSet.Fields Do
		ResultStructure1.CorrespondenceOfDCSFieldsToColumnsOfProductTable.Insert(
			Catalogs.LabelAndPriceTagTemplates.NameOfFieldInTemplate(Field.DataPath), Field.Name);
	EndDo;

#EndRegion

#Region PreparationOfGoodsTable
	
	TableOfGoods = New ValueTable;
	
	DataCompositionProcessor = New DataCompositionProcessor;
	If ExternalDataSets = Undefined Then
		DataCompositionProcessor.Initialize(DataCompositionTemplate);
	Else
		DataCompositionProcessor.Initialize(DataCompositionTemplate, ExternalDataSets);
	EndIf;
	
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	OutputProcessor.SetObject(TableOfGoods);
	OutputProcessor.Output(DataCompositionProcessor);
	
	ResultStructure1.TableOfGoods = TableOfGoods;
	
	Return ResultStructure1;
	
#EndRegion

EndFunction

Procedure ConfigureDatasets(DataCompositionSchema, ColumnsOfGoodsTable)

	UseItemVariants = GetFunctionalOption("UseItemVariants");
	UseItemsBatch          = GetFunctionalOption("UseItemsBatch");
	UseItemPackages       = GetFunctionalOption("UseItemPackages");

	WorkingDataset = DataCompositionSchema.DataSets[0];

	DataSetProducts                = DataCompositionSchema.DataSets.Add(Type("DataCompositionSchemaDataSetObject"));
	DataSetProducts.Name            = "ProductsTable";
	DataSetProducts.ObjectName     = "ProductsTable";
	DataSetProducts.DataSource = WorkingDataset.DataSource;
	
	DataCompositionSchema.DataSetLinks.Clear();
	
	AddDCSDataSetField(DataSetProducts, "Products", "CatalogRef.Products");
	AddRelationshipOfDCSDataSets(DataCompositionSchema, DataSetProducts, WorkingDataset, "Products");
	
	If UseItemVariants And ColumnsOfGoodsTable.Find("Characteristic") <> Undefined Then
		AddDCSDataSetField(DataSetProducts, "Characteristic", "CatalogRef.ItemsCharacteristics");
		AddRelationshipOfDCSDataSets(DataCompositionSchema, DataSetProducts, WorkingDataset, "Characteristic");
	EndIf;
		
	If UseItemsBatch And ColumnsOfGoodsTable.Find("Series") <> Undefined Then
		AddDCSDataSetField(DataSetProducts, "Series", "CatalogRef.ItemsBatches");
		AddDCSDataSetField(DataSetProducts, "SeriesForCommunication", "CatalogRef.ItemsBatches");
		AddRelationshipOfDCSDataSets(DataCompositionSchema, 
										DataSetProducts, WorkingDataset, "SeriesForCommunication", "Series");
	EndIf;
	
	If UseItemPackages And ColumnsOfGoodsTable.Find("Package") <> Undefined Then
		AddDCSDataSetField(DataSetProducts, "Package", "CatalogRef.PackagesAndUnitsOfMeasure");
		AddDCSDataSetField(DataSetProducts, "PackagingForCommunication", "CatalogRef.PackagesAndUnitsOfMeasure");
		AddRelationshipOfDCSDataSets(DataCompositionSchema, 
										DataSetProducts, WorkingDataset, "PackagingForCommunication", "Package");
	EndIf;

	If ColumnsOfGoodsTable.Find("PriceKind") <> Undefined Then
		AddDCSDataSetField(DataSetProducts, "PriceKind", "CatalogRef.TypesOfPrices");
	EndIf;

	If ColumnsOfGoodsTable.Find("Price") <> Undefined Then
		AddDCSDataSetField(DataSetProducts, "Price", "Number");
	EndIf;

EndProcedure


// Parameters:
// 	DCS - DataCompositionSchema - Changeable data layout scheme
// 	DataSetProducts - DataCompositionSchemaDataSetObject - Dataset
// 	WorkingDataset - DataCompositionSchemaDataSetObject - Dataset
// 	Field - String - Field for a source expression and a sink expression
// 	WorkingSetField - String - Field for a source expression and a sink expression
// 
Procedure AddRelationshipOfDCSDataSets(DCS, 
										DataSetProducts, 
										WorkingDataset, 
										Field, 
										WorkingSetField = Undefined) Export
	
	Link                     = DCS.DataSetLinks.Add();
	Link.SourceDataSet = DataSetProducts.Name;
	Link.DestinationDataSet = WorkingDataset.Name;
	Link.SourceExpression   = Field;
	Link.DestinationExpression   = ?(WorkingSetField = Undefined, Field, WorkingSetField);
	
EndProcedure

// Parameters:
// 	DataSet - DataCompositionSchemaDataSetObject - Dataset
// 	FieldName - String - field name
// 	ValueType - String - Value type
// 
Procedure AddDCSDataSetField(DataSet, FieldName, ValueType) Export
	
	DataSetField             = DataSet.Fields.Add(Type("DataCompositionSchemaDataSetField"));
	DataSetField.Field        = FieldName;
	DataSetField.DataPath = FieldName;
	DataSetField.ValueType = New TypeDescription(ValueType);
	
EndProcedure
#EndRegion

#Region Private

// Get the pricing settings table.
// 
// Parameters:
//  ItemList - Array of CatalogRef.Products
// 
// Returns:
//  ValueTable - Get the pricing settings table
Function GetPricingSettingsTable(ItemList) Export
	
	Query = New Query;
	Query.Text = "SELECT
	|	Products.Ref AS Products,
	|	ItemKinds.Ref AS ProductKind,
	|	CASE
	|		WHEN
	|			ItemKinds.SettingsOfPriceKeyByItemVariant = VALUE(Enum.FilterOptionForPriceKey.DontUse)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ByItemVariant,
	|	CASE
	|		WHEN ItemKinds.SettingsOfPriceKeyByBatch = VALUE(Enum.FilterOptionForPriceKey.DontUse)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ByBatch,
	|	CASE
	|		WHEN ItemKinds.SettingsOfPriceKeyByPackage = VALUE(Enum.FilterOptionForPriceKey.DontUse)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ByPackage
	|FROM
	|	Catalog.Products AS Products
	|		LEFT JOIN Catalog.ItemKinds AS ItemKinds
	|		ON Products.ProductKind = ItemKinds.Ref
	|WHERE
	|	Products.Ref IN (&ItemList)";
	
	Query.SetParameter("ItemList", ItemList);
	
	Result = Query.Execute().Unload();
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf