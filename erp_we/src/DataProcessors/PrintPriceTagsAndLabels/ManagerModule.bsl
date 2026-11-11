#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// This function prepares the data structure required for printing price tags and labels.
// 
// Parameters:
//  SettingsStructure - Structure - Structure of settings:
// * RawData - Undefined -
// * RequiredFields - Array of String-
// * PatternMatchingAndPatternStructure - Map -
// * DataParameters - Structure -
// * SettingsComposer - Undefined -
// * NameOfDataLayoutSchemaTemplate - Undefined -
// * UsePriceManagementSystem25 - Undefined -
//  Mode - String - Mode
// 
// Returns:
//  Structure -- data required for printing labels and price tags.
Function PrepareDataStructure(SettingsStructure, Mode) Export
	
	If SettingsStructure.RawData <> Undefined Then
		RawData = SettingsStructure.RawData.Copy();
	Else
		RawData = Undefined;
	EndIf;
	
	UsePriceManagementSystem25 = SettingsStructure.UsePriceManagementSystem25;
	If UsePriceManagementSystem25 = Undefined Then
		
		PricingDate = Undefined;
		If SettingsStructure.DataParameters.Property("Date")
			And ValueIsFilled(SettingsStructure.DataParameters.Date) Then
				
			PricingDate = SettingsStructure.DataParameters.Date;
			
		ElsIf SettingsStructure.DataParameters.Property("DateAdditionally") 
			And ValueIsFilled(SettingsStructure.DataParameters.DateAdditionally) Then
				
			PricingDate = SettingsStructure.DataParameters.DateAdditionally;
			
		EndIf;
		
		UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25(PricingDate);
		
	EndIf;
	
	ResultStructure1 = New Structure;
	ResultStructure1.Insert("Table",                             Undefined);
	ResultStructure1.Insert("MatchingDCSFieldsToTableColumns", New Map);
	
	// scheme of the layout.
	If Mode = "Assets" Then
		DataCompositionSchema = DataProcessors.LabelPrintingOfAssets.GetTemplate(SettingsStructure.NameOfDataLayoutSchemaTemplate);
	ElsIf Mode = "InventoryInOperation" Then
		DataCompositionSchema = DataProcessors.PrintLabelsOfInventoryInOperation.GetTemplate(SettingsStructure.NameOfDataLayoutSchemaTemplate);
	ElsIf Mode = "Nodes" Then
		DataCompositionSchema = DataProcessors.LabelPrintingOfSubAssets.GetTemplate(SettingsStructure.NameOfDataLayoutSchemaTemplate);
	Else
		DataCompositionSchema = DataProcessors.PrintPriceTagsAndLabels.GetTemplate(SettingsStructure.NameOfDataLayoutSchemaTemplate);
	EndIf; 
	
	DataSet25 = DataCompositionSchema.DataSets.Find("DataSet2_5");
	If DataSet25 <> Undefined Then
		If UsePriceManagementSystem25 Then
			DataCompositionSchema.DataSets.DataSet.Query = DataSet25.Query;
		EndIf;
		DataCompositionSchema.DataSets.Delete(DataSet25);
	EndIf;
	
	DatabaseQueryDataSet = TypeOf(DataCompositionSchema.DataSets.DataSet) = Type("DataCompositionSchemaDataSetQuery");
	
	If DatabaseQueryDataSet Then
		QueryText = DataCompositionSchema.DataSets.DataSet.Query;
		
		QueryText = StrReplace(QueryText,
				"&QueryTextPackagingFactor1",
				Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
				"ProductPackages",
				"RawData.Products"));
		
		QueryText = StrReplace(QueryText,
				"&QueryTextPackagingFactor2",
				Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
				"SinglePackages.Package",
				"SinglePackages.Products"));
		
		QueryText = StrReplace(QueryText,
				"&QueryTextPackagingFactor3",
				Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
				"RawData.Package",
				"RawData.Products"));
		
		QueryText = StrReplace(QueryText,
				"&QueryTextPackagingFactor4",
				Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
				"SinglePackagesOfProducts.Package",
				"SinglePackagesOfProducts.Products"));
		
		If RawData <> Undefined Then
			ReplacementText = ?(GetFunctionalOption("UseItemsBatch"),
							"RawData.Series",
							"VALUE(Catalog.ItemsBatches.EmptyRef)");
			
			QueryText = StrReplace(QueryText, "&DataBySeriesOverridable", ReplacementText);
		EndIf;
		
		PrintPriceTagsAndLabelsLocalization.WhenPreparingSetDataStructure(Mode, DataCompositionSchema, QueryText);
		
		DataCompositionSchema.DataSets.DataSet.Query = QueryText;
	EndIf;
	
	// It is possible to change the data layout scheme.
	ExpressionAcquisitionData = ProcessingOfFormulas.DataForObtainingFormulaExpressionsViaDCS(DataCompositionSchema,
		SettingsStructure.RequiredFields, True);
	
	Fields_For_Selection = New Array;
	FieldNumber = 0;
	
	// Stores assigned names to calculated fields. To get data in the SKD (contains sets of objects).
	ColumnNamesForDCS = New Map;
	// Stores the original expressions specified in the print layout. To get data in a request (contains sets of requests).
	OriginalQueryExpressions = New Map;
	For Each ExpressionConversion In ExpressionAcquisitionData.ConvertedExpressions Do
		OriginalExpression = ExpressionConversion.Key;
		ConversionResult = ExpressionConversion.Value;
		If ValueIsFilled(ConversionResult) Then
			If StrFind(ConversionResult, ".") > 0 Then
				FieldNumber = FieldNumber + 1;
				FieldName = "FieldToEval" + Format(FieldNumber, "NZ=0; NG=0;");
			
				FinancialReportingServer.NewCalculatedField(DataCompositionSchema,
					FieldName,
					ConversionResult);
				Fields_For_Selection.Add(FieldName);
				
				If Not DatabaseQueryDataSet Then
					ColumnNamesForDCS.Insert(OriginalExpression, ReplaceSpecialCharacters(FieldName));
				EndIf;
			Else
				// The original layout field.
				Fields_For_Selection.Add(ConversionResult);
				
				If Not DatabaseQueryDataSet Then
					ColumnNamesForDCS.Insert(OriginalExpression, ReplaceSpecialCharacters(ConversionResult));
				EndIf;
			EndIf;
			If DatabaseQueryDataSet Then
				OriginalQueryExpressions.Insert(ConversionResult, OriginalExpression);
			EndIf;
		EndIf;
	EndDo;
	
	// Preparing the data layout layout builder.
	Composer = New DataCompositionSettingsComposer;
	Composer.Initialize(New DataCompositionAvailableSettingsSource(DataCompositionSchema));
	Composer.LoadSettings(DataCompositionSchema.DefaultSettings);
	Composer.Settings.Filter.Items.Clear();
	
	// Selection of the settings linker.
	If SettingsStructure.SettingsComposer <> Undefined Then
		DataCompositionClientServer.CopyElements(Composer.Settings.Filter, SettingsStructure.SettingsComposer.Settings.Filter);
	EndIf;
	
	For Each FieldName In Fields_For_Selection Do
		SelectedField = Composer.Settings.Selection.Items.Add(Type("DataCompositionSelectedField"));
		SelectedField.Field = New DataCompositionField(FieldName);
	EndDo;
	
	If Mode = "Goods" Then
		// Filling in parameters.
		For Each DataParameter In SettingsStructure.DataParameters Do
			If DataParameter.Key = "Warehouse" Then // If the warehouse is not full, we do not use the parameter
				SetValueOfDCSParameter(Composer, DataParameter.Key, DataParameter.Value, False);
			Else
				SetValueOfDCSParameter(Composer, DataParameter.Key, DataParameter.Value);
			EndIf;
		EndDo;
		SetValueOfDCSParameter(Composer, "CurrentTime",        CurrentSessionDate());
		SetValueOfDCSParameter(Composer, "CurrentUser", Users.CurrentUser());
		
		SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(Composer);
	EndIf;
	
	// Layout layout of the data layout.
	TemplateComposer = New DataCompositionTemplateComposer;
	DataCompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, Composer.GetSettings(),,,Type("DataCompositionValueCollectionTemplateGenerator"));
	
	If DatabaseQueryDataSet Then
		
		For Each DataSet In DataCompositionTemplate.DataSets Do
			For Each Field In DataSet.Fields Do
				
				ConversionResult = Catalogs.LabelAndPriceTagTemplates.NameOfFieldInTemplate(Field.DataPath);
				OriginalExpression = OriginalQueryExpressions.Get(ConversionResult);
				If OriginalExpression = Undefined Then
					OriginalExpression = ConversionResult;
				EndIf;
				ResultStructure1.MatchingDCSFieldsToTableColumns.Insert(
					OriginalExpression,
					ReplaceSpecialCharacters(Field.Name));
					
			EndDo;
		EndDo;
		
	Else
		
		For Each ExpressionConversion In ExpressionAcquisitionData.ConvertedExpressions Do
			OriginalExpression = ExpressionConversion.Key;
			ColumnNameInDCSMode = ColumnNamesForDCS.Get(OriginalExpression);
			ResultStructure1.MatchingDCSFieldsToTableColumns.Insert(
				Catalogs.LabelAndPriceTagTemplates.NameOfFieldInTemplate(OriginalExpression),
				ColumnNameInDCSMode);
		EndDo;
		
	EndIf;
	
	If DatabaseQueryDataSet Then
		
		Query = New Query(DataCompositionTemplate.DataSets.DataSet.Query);
		
		// Filling in parameters from the selection fields of the processing form settings linker.
		For Each Parameter In DataCompositionTemplate.ParameterValues Do
			Query.Parameters.Insert(Parameter.Name, Parameter.Value);
		EndDo;
		
	EndIf;
	
	If Mode = "Goods" Then
		// Substitution of a request for calculating prices...
		If GetFunctionalOption("UseItemPackages") Then
			
			TextToReplace = "ItemPricesCrossSectionOfTheLatest.Price";
			ReplacementText = " CAST(
			|          ItemPricesCrossSectionOfTheLatest.Price
			|          / 
			|          ISNULL(&QueryTextPackagingFactor1, 1) 
			|          * 
			|          ISNULL(&QueryTextPackagingFactor2, 1) AS NUMBER(31,2)) ";
			
			ReplacementText = StrReplace(ReplacementText, "&QueryTextPackagingFactor1",
				Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
					"ItemPricesCrossSectionOfTheLatest.Package",
					"ItemPricesCrossSectionOfTheLatest.Products"));
			ReplacementText = StrReplace(ReplacementText, "&QueryTextPackagingFactor2",
				Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
					"SourceDataLastRequest.Package",
					"SourceDataLastRequest.Products"));
			Query.Text = StrReplace(Query.Text, TextToReplace, ReplacementText);
			
			TextToReplace = "PricesOfProductRangeCutInAddition.Price";
			ReplacementText = " CAST(
			|          PricesOfProductRangeCutInAddition.Price
			|          / 
			|          ISNULL(&QueryTextPackagingFactor1, 1) 
			|          * 
			|          ISNULL(&QueryTextPackagingFactor2, 1) AS NUMBER(31,2)) ";
			ReplacementText = StrReplace(ReplacementText, "&QueryTextPackagingFactor1",
				Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
					"PricesOfProductRangeCutInAddition.Package",
					"PricesOfProductRangeCutInAddition.Products"));
			ReplacementText = StrReplace(ReplacementText, "&QueryTextPackagingFactor2",
				Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
					"SourceDataLastRequest.Package",
					"SourceDataLastRequest.Products"));
			Query.Text = StrReplace(Query.Text, TextToReplace, ReplacementText);
			
			TextToReplace = "ProductStockBalance.InStockBalance";
			ReplacementText = " CAST(
			|          ProductStockBalance.InStockBalance
			|          / 
			|          ISNULL(&QueryTextPackagingFactor, 1) AS NUMBER(31,2)) ";
			ReplacementText = StrReplace(ReplacementText, "&QueryTextPackagingFactor",
				Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
					"SourceDataLastRequest.Package",
					"SourceDataLastRequest.Products"));
			Query.Text = StrReplace(Query.Text, TextToReplace, ReplacementText);
			
		EndIf;
		
		// Substitution of the request when printing labels...
		If RawData <> Undefined Then
			
			Query.Text = StrReplace(Query.Text, "RawDataOverridable", "&Table");
			
			TMCommonUse.NumberValueTable(RawData, "Order");
			Query.Parameters.Insert("Table", RawData);
			
			Query.Text = StrReplace(Query.Text, """NumberOfPriceTags""", "RawData.NumberOfPriceTags");
			Query.Text = StrReplace(Query.Text, """NumberOfLabels""", "RawData.NumberOfLabels");
			
			Query.Text = StrReplace(Query.Text, "COUNT(RawData.NumberOfPriceTags)",
			                                         "SUM(RawData.NumberOfPriceTagsToPrint)");
			Query.Text = StrReplace(Query.Text, "COUNT(RawData.NumberOfLabels)",
			                                         "SUM(RawData.NumberOfLabels)");	
			
			Query.Text = StrReplace(Query.Text, """PriceTagTemplate""", "RawData.PriceTagTemplate");
			Query.Text = StrReplace(Query.Text, """LabelsTemplate""", "RawData.LabelsTemplate");
			
			Query.Text = StrReplace(Query.Text, """Barcode""", "RawData.Barcode");
			Query.Text = StrReplace(Query.Text, """Price""", "RawData.Price");
			Query.Text = StrReplace(Query.Text, """PriceAdditionally""", "RawData.PriceAdditionally");
			
			Query.Text = StrReplace(Query.Text, """LastPriceChangeDate""", "RawData.LastPriceChangeDate");
			Query.Text = StrReplace(Query.Text, """LastPriceChangeDateAdditionally""", "RawData.LastPriceChangeDateAdditionally");
			
		Else
			
			TemporaryTableText =
			"	(SELECT
			|		VALUE(Catalog.Products.EmptyRef) AS Products,
			|		VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
			|		VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
			|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
			|		0 AS Order,
			|		0 AS Count)";
			
			Query.Text = StrReplace(Query.Text, "RawDataOverridable", TemporaryTableText);
			
		EndIf;
		
	ElsIf Mode = "StorageBins" Then
		
		If RawData <> Undefined Then
			
			Query.Text = StrReplace(Query.Text, "RawDataOverridable", "&Table");
			
			TMCommonUse.NumberValueTable(RawData, "Order");
			Query.Parameters.Insert("Table", RawData);
			
		Else
			
			TemporaryTableText =
			"	(SELECT
			|		VALUE(Catalog.StorageBins.EmptyRef) AS Cell,
			|		"""" AS Barcode,
			|		0 AS Order)";
			
			Query.Text = StrReplace(Query.Text, "RawDataOverridable", TemporaryTableText);
			
		EndIf;
		
	ElsIf Mode = "ItemsBatches" Then
		
		If RawData <> Undefined Then
			
			Query.Text = StrReplace(Query.Text, "RawDataOverridable", "&Table");
			
			TMCommonUse.NumberValueTable(RawData, "Order");
			Query.Parameters.Insert("Table", RawData);
			
		Else
			
			TemporaryTableText =
			"	(SELECT
			|		VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
			|		"""" AS Barcode,
			|		0 AS Order)";
			
			Query.Text = StrReplace(Query.Text, "RawDataOverridable", TemporaryTableText);
			
		EndIf;
		
	ElsIf Mode = "Delivery" Then
		
		If RawData <> Undefined Then
		
			ExternalDataSets = New Structure;
			ExternalDataSets.Insert("InitialInvoiceData", RawData);
			
			Result = New ValueTable;
			CompositionProcessor = New DataCompositionProcessor;
			CompositionProcessor.Initialize(DataCompositionTemplate, ExternalDataSets);
			
			OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
			OutputProcessor.SetObject(Result);	
			Result = OutputProcessor.Output(CompositionProcessor);
			
			ResultStructure1.Table = Result;
			
		EndIf;
		
	ElsIf Mode = "PackingLists" Then
		
		If RawData <> Undefined Then
			
			Query.Text = StrReplace(Query.Text, "RawDataOverridable", "&Table");
			
			TMCommonUse.NumberValueTable(RawData, "Order");
			Query.Parameters.Insert("Table", RawData);
			
		Else
			
			TemporaryTableText =
			"	(SELECT
			|		VALUE(Document.PackingList.EmptyRef) AS Ref,
			|		"""" AS Barcode,
			|		0 AS Order)";
			
			Query.Text = StrReplace(Query.Text, "RawDataOverridable", TemporaryTableText);
			
		EndIf;
	
	ElsIf Mode = "InventoryInOperation" Then
		
		If RawData <> Undefined Then
			
			TemporaryTableText =
			"	(SELECT
			|		VALUE(Catalog.LotsOfInventoryInOperation.EmptyRef) AS Products,
			|		VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
			|		VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
			|		VALUE(Catalog.LotsOfInventoryInOperation.EmptyRef) AS Lot,
			|		"""" AS AssetID,
			|		0 AS Order)";
			
			Query.Text = StrReplace(Query.Text, TemporaryTableText, "&Table");
			
			TMCommonUse.NumberValueTable(RawData, "Order");
			Query.Parameters.Insert("Table", RawData);
			
		EndIf;
	ElsIf Mode = "Assets" Then
		
		If RawData <> Undefined Then
			
			Query.Text = StrReplace(Query.Text, "RawDataOverridable", "&Table");
			
			TMCommonUse.NumberValueTable(RawData, "Order");
			Query.Parameters.Insert("Table", RawData);
			
		Else
			
			TemporaryTableText =
			"	(SELECT
			|		VALUE(Catalog.Assets.EmptyRef) AS Asset,
			|		"""" AS Barcode,
			|		0 AS Order)";
			
			Query.Text = StrReplace(Query.Text, "RawDataOverridable", TemporaryTableText);
			
		EndIf;
	ElsIf Mode = "Nodes" Then
		
		If RawData <> Undefined Then
			
			Query.Text = StrReplace(Query.Text, "RawDataOverridable", "&Table");
			
			TMCommonUse.NumberValueTable(RawData, "Order");
			Query.Parameters.Insert("Table", RawData);
			
		Else
			
			TemporaryTableText =
			"	(SELECT
			|		VALUE(Catalog.SubAssets.EmptyRef) AS Node,
			|		"""" AS Barcode,
			|		0 AS Order)";
			
			Query.Text = StrReplace(Query.Text, "RawDataOverridable", TemporaryTableText);
			
		EndIf;
	EndIf;
	
	PrintPriceTagsAndLabelsLocalization.WhenPreparingDataStructureForPrinting(SettingsStructure, Mode, Query, RawData);
	
	If DatabaseQueryDataSet Then
		ResultStructure1.Table = Query.Execute().Unload();
	EndIf;
	
	Return ResultStructure1;
	
EndFunction

#EndRegion

#Region Private

#Region Print

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	SetPrivilegedMode(True);

	PrintPriceTagsAndLabelsLocalization.OnPrint(PrintFormsCollection, PrintParameters, PrintObjects);
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "PriceTagProducts") 
		Or PrintManagement.TemplatePrintRequired(PrintFormsCollection, "LabelProducts_") Then
		
		FormPrintedFormsOfLabelsAndPriceTagsOfGoods(PrintParameters, PrintObjects, PrintFormsCollection);
		
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "LabelStorageCells") Then
		
		SpreadsheetDocument = ToFormPrintedFormOfLabelOfWarehouseCell(PrintParameters, PrintObjects);
		SpreadsheetDocument.PrintParametersKey = "PRINT_OPTIONS_LabelStorageCells";
		
		TemplateSynonym = NStr("vi = 'Nhãn tem của ô hàng';
								|ru = 'Этикетки складских ячеек';
								|en = 'Storage bin labels'; fa = 'Storage bin labels';
								|it = 'Etichette delle celle di magazzino';
								|pl = 'Etykiety komórek magazynowych';
								|tr = 'Depo etiketleri'");
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"LabelStorageCells",
			TemplateSynonym,
			SpreadsheetDocument);
		
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ItemsBatchLabel") Then
		
		SpreadsheetDocument = ToFormPrintedFormOfLabelOfSeriesOfProducts(PrintParameters, PrintObjects);
		SpreadsheetDocument.PrintParametersKey = "PRINT_OPTIONS_ItemsBatchLabel";
		
		TemplateSynonym = NStr("vi = 'Nhãn tem sê-ri mặt hàng';
								|ru = 'Этикетки серий номенклатуры';
								|en = 'Labels of item batch'; fa = 'Labels of item batch';
								|it = 'Etichette delle serie di articolo';
								|pl = 'Etykiety serii nomenklatury';
								|tr = 'Öğe parti etiketleri'");
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"ItemsBatchLabel",
			TemplateSynonym,
			SpreadsheetDocument);
		
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ShippingLabel") Then
		
		If PrintParameters.Property("AddressInStorage") Then
			SpreadsheetDocument = FormPrintedFormOfShippingLabel(PrintParameters, PrintObjects, PrintFormsCollection);
		Else
			
			ShippingLabelPrintingOptions = ShippingLabelPrintingData(ObjectsArray);
			SpreadsheetDocument = FormPrintedFormOfShippingLabel(
				ShippingLabelPrintingOptions,
				ObjectsArray,
				PrintFormsCollection);
			
		EndIf;
		
		SpreadsheetDocument.PrintParametersKey = "PRINT_OPTIONS_ShippingLabel";
		
		TemplateSynonym = NStr("vi = 'Nhãn tem giao hàng';
								|ru = 'Этикетки доставки';
								|en = 'Delivery labels'; fa = 'Delivery labels';
								|it = 'Etichette di consegna';
								|pl = 'Etykiety dostawy';
								|tr = 'Teslimat etiketleri'");
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"ShippingLabel",
			TemplateSynonym,
			SpreadsheetDocument);
			
	EndIf;

	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "LabelPackingSheets") Then
		
		SpreadsheetDocument = FormPrintedFormLabelsPackingSheets(PrintParameters, PrintObjects);
		SpreadsheetDocument.PrintParametersKey = "PRINT_OPTIONS_LabelPackingSheets";
		
		TemplateSynonym = NStr("vi = 'Nhãn tem phiếu đóng gói';
								|ru = 'Этикетки упаковочных листов';
								|en = 'Packing list labels'; fa = 'Packing list labels';
								|it = 'Etichette delle liste di imballaggio';
								|pl = 'Etykiety list pakowych';
								|tr = 'Ürün listesi etiketleri'");
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"LabelPackingSheets",
			TemplateSynonym,
			SpreadsheetDocument);
			
	EndIf;
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "LabelTMTSVOperation") Then
		
		SpreadsheetDocument = DataProcessors.PrintLabelsOfInventoryInOperation.ToFormPrintedFormOfTMTSVLabel(
								PrintParameters, ObjectsArray);
		SpreadsheetDocument.PrintParametersKey = "PRINT_OPTIONS_LabelTMTSVOperation";
		
		TemplateSynonym = NStr("vi = 'Nhãn tem vật tư đang sử dụng';
								|ru = 'Этикетки ТМЦ в эксплуатации';
								|en = 'Labels of inventory in operation'; fa = 'Labels of inventory in operation';
								|it = 'Этикетки ТМЦ в эксплуатации';
								|pl = 'Etykiety zapasów w eksploatacji';
								|tr = 'Kullanımdaki stok etiketleri'");
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"LabelTMTSVOperation",
			TemplateSynonym,
			SpreadsheetDocument);
			
	EndIf;

	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "LabelOfObjectsOfOperation") Then
		
		SpreadsheetDocument = DataProcessors.LabelPrintingOfAssets.ToFormPrintedFormOfLabelOfObjectsOfOperation(
								PrintParameters, ObjectsArray);
		SpreadsheetDocument.PrintParametersKey = "PRINT_OPTIONS_LabelOfObjectsOfOperation";
		
		TemplateSynonym = NStr("vi = 'Nhãn tem đối tượng đang vận hành';
								|ru = 'Этикетки объектов эксплуатации';
								|en = 'Assets labels'; fa = 'Assets labels';
								|it = 'Etichette delle infrastrutture';
								|pl = 'Etykiety obiektów eksploatacji';
								|tr = 'Varlık işletme etiketleri'");
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"LabelOfObjectsOfOperation",
			TemplateSynonym,
			SpreadsheetDocument);
			
	EndIf;
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "LabelOfUnitOfObjectOfOperation") Then
		
		SpreadsheetDocument = DataProcessors.LabelPrintingOfSubAssets.ToFormPrintedFormOfLabelOfNodesOfObjectsOfOperation(
								PrintParameters, ObjectsArray);
		SpreadsheetDocument.PrintParametersKey = "PRINT_OPTIONS_LabelOfUnitOfObjectOfOperation";
		
		TemplateSynonym = NStr("vi = 'Nhãn của nút đối tượng đang vận hành';
								|ru = 'Этикетки узлов объектов эксплуатации';
								|en = 'Sub-asset labels'; fa = 'Sub-asset labels';
								|it = 'Etichette dei nodi degli oggetti d''uso operativo';
								|pl = 'Etykiety węzłów obiektów eksploatacji';
								|tr = 'Varlık işletme tertibatı etiketleri'");
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"LabelOfUnitOfObjectOfOperation",
			TemplateSynonym,
			SpreadsheetDocument);
			
	EndIf;
	If TypeOf(PrintParameters) = Type("Structure")
		 And PrintParameters.Property("StructureOfTypes") Then
		PrintFormGeneration.FillInSendingParameters(OutputParameters.SendOptions, PrintParameters.StructureOfTypes, PrintFormsCollection);
	EndIf;	
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
EndProcedure

Procedure FormPrintedFormsOfLabelsAndPriceTagsOfGoods(PrintData, PrintObjects, CollectionOfBSPPrintingPlates)
	
	RawData = GetFromTempStorage(PrintData.Goods);
	
	NeedToPrintLabels = False;
	If PrintManagement.TemplatePrintRequired(CollectionOfBSPPrintingPlates, "LabelProducts_") Then
		NeedToPrintLabels = True;
		CollectionOfBSPPrintingPlates.Delete(CollectionOfBSPPrintingPlates.Find(Upper("LabelProducts_"), "UpperCaseName"));
	EndIf;
	
	NeedToPrintPriceTags = False;
	If PrintManagement.TemplatePrintRequired(CollectionOfBSPPrintingPlates, "PriceTagProducts") Then
		NeedToPrintPriceTags = True;
		CollectionOfBSPPrintingPlates.Delete(CollectionOfBSPPrintingPlates.Find(Upper("PriceTagProducts"), "UpperCaseName"));
	EndIf;
	
	SettingsStructure = SettingsStructure();
	SettingsStructure.RequiredFields.Add("NumberOfPriceTagsToPrint");
	SettingsStructure.RequiredFields.Add("NumberOfLabelsToPrint");
	SettingsStructure.RequiredFields.Add("PriceTagTemplateForPrinting");
	SettingsStructure.RequiredFields.Add("LabelTemplateForPrinting");
	SettingsStructure.RequiredFields.Add("Products");
	If GetFunctionalOption("UseItemVariants") Then
		SettingsStructure.RequiredFields.Add("Characteristic");
	EndIf;
	If GetFunctionalOption("UseItemPackages") Then
		SettingsStructure.RequiredFields.Add("Package");
	EndIf;
	
	SettingsStructure.NameOfDataLayoutSchemaTemplate = "TemplateFieldsPrintGoods";
	
	// We collect the fields used from the templates.
	PatternMatching = New Map;
	For Each TSRow In RawData Do
		If ValueIsFilled(TSRow.LabelsTemplate) And TSRow.NumberOfLabels > 0 And NeedToPrintLabels Then
			PatternMatching.Insert(TSRow.LabelsTemplate);
		EndIf;
		If ValueIsFilled(TSRow.PriceTagTemplate) And TSRow.NumberOfPriceTags > 0 And NeedToPrintPriceTags Then
			PatternMatching.Insert(TSRow.PriceTagTemplate);
		EndIf;
	EndDo;
	If PrintData.Property("StructureOfTemplateTemplate") And ValueIsFilled(PrintData.StructureOfTemplateTemplate) Then
		PatternMatching.Insert(Catalogs.LabelAndPriceTagTemplates.EmptyRef());
	EndIf;
	
	// We fill in the collection of required fields and form a template match.
	For Each KeyAndValue In PatternMatching Do
		
		LabelAndPriceTagTemplate = KeyAndValue.Key;
		
		If ValueIsFilled(LabelAndPriceTagTemplate) Then
			TemplateKey = KeyAndValue.Key.Template; // ValueStorage
			TemplateStructure = TemplateKey.Get();
		Else
			TemplateStructure = PrintData.StructureOfTemplateTemplate;
		EndIf;
		
		// The structure of templates.
		SettingsStructure.PatternMatchingAndPatternStructure.Insert(LabelAndPriceTagTemplate, TemplateStructure);
		
		// We add the fields present in the printed form of the price tag to the array of mandatory fields.
		For Each Item In TemplateStructure.TemplateParameters Do
			SettingsStructure.RequiredFields.Add(Item.Key);
		EndDo;
		
	EndDo;
	
	SettingsStructure.DataParameters.Insert("Organization", PrintData.Organization);
	
	SettingsStructure.DataParameters.Insert("ExchangeRule",                 PrintData.ExchangeRule);
	SettingsStructure.DataParameters.Insert("MaximumCodeOfGoodsSoldByWeight", PrintData.MaximumCodeOfGoodsSoldByWeight);
	SettingsStructure.DataParameters.Insert("RuleOfExportToScales",          PrintData.RuleOfExportToScales);
	
	SettingsStructure.DataParameters.Insert("PriceKind",       PrintData.PriceKind);
	SettingsStructure.DataParameters.Insert("Date",          PrintData.Date);
	
	SettingsStructure.DataParameters.Insert("PriceKindAdditional", PrintData.PriceKindAdditional);
	SettingsStructure.DataParameters.Insert("DateAdditionally",    PrintData.DateAdditionally);
	
	SettingsStructure.RawData = RawData;

#Region PreparingTemplateDataStructure
	
	ResultStructure1 = PrepareDataStructure(SettingsStructure, "Goods");

#EndRegion

#Region CreatingTabularDocument
	
	Etalon = DataProcessors.PrintPriceTagsAndLabels.GetTemplate("Etalon");
	DrawingSquare = Etalon.Drawings.Square100Pixels; // SpreadsheetDocumentDrawing
	NumberOfMillimetersPerPixel = DrawingSquare.Height / 100;
	
	// Preparation of a collection of printed forms.
	PrintFormsCollection = New ValueTable;
	PrintFormsCollection.Columns.Add("TemplateName");
	PrintFormsCollection.Columns.Add("TemplateSynonym");
	PrintFormsCollection.Columns.Add("SpreadsheetDocument");
	PrintFormsCollection.Columns.Add("ColumnNameQuantity");
	PrintFormsCollection.Columns.Add("ColumnNameTemplate");
	PrintFormsCollection.Columns.Add("Template");
	
	For Each KeyAndValue In SettingsStructure.PatternMatchingAndPatternStructure Do
		
		If ((ValueIsFilled(KeyAndValue.Key)
				And KeyAndValue.Key.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.GoodsLabel)
				Or Not ValueIsFilled(KeyAndValue.Key))
			And NeedToPrintLabels Then
			
			PrintForm = PrintFormsCollection.Add();
			PrintForm.TemplateName            = "Label_: "+KeyAndValue.Key;
			PrintForm.TemplateSynonym        = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Nhãn tem: %1';
																											|ru = 'Этикетка: %1';
																											|en = 'Label: %1'; fa = 'Label: %1';
																											|it = 'Etichetta: %1';
																											|pl = 'Etykieta: %1';
																											|tr = 'Etiket: %1'"), KeyAndValue.Key);
			PrintForm.ColumnNameQuantity = "NumberOfLabelsToPrint";
			PrintForm.ColumnNameTemplate     = "LabelTemplateForPrinting";
			PrintForm.Template = KeyAndValue.Key;
			
		EndIf;
		
		If ((ValueIsFilled(KeyAndValue.Key)
				And KeyAndValue.Key.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.GoodsPriceTag)
				Or Not ValueIsFilled(KeyAndValue.Key))
			And NeedToPrintPriceTags Then
			
			PrintForm = PrintFormsCollection.Add();
			PrintForm.TemplateName            = "PriceTag: " + KeyAndValue.Key;
			PrintForm.TemplateSynonym        = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Nhãn giá: %1';
																											|ru = 'Ценник: %1';
																											|en = 'Price tag: %1'; fa = 'Price tag: %1';
																											|it = 'Cartellino del prezzo: %1';
																											|pl = 'Cennik: %1';
																											|tr = 'Fiyat etiketi: %1'"), KeyAndValue.Key);
			PrintForm.ColumnNameQuantity = "NumberOfPriceTagsToPrint";
			PrintForm.ColumnNameTemplate     = "PriceTagTemplateForPrinting";
			PrintForm.Template = KeyAndValue.Key;
			
		EndIf;
		
	EndDo;
	
	For Each PrintForm In PrintFormsCollection Do
		
		ColumnNumber = 0;
		RowNumber = 0;
		
		For Each LineProducts_ In ResultStructure1.Table Do
			
			If LineProducts_[PrintForm.ColumnNameQuantity] > 0 And LineProducts_[PrintForm.ColumnNameTemplate] = PrintForm.Template Then
				
				TemplateStructure = SettingsStructure.PatternMatchingAndPatternStructure.Get(LineProducts_[PrintForm.ColumnNameTemplate]);	// Structure - See Catalogs.LabelAndPriceTagTemplates.PrepareStructureOfTemplateTemplate
				
				If PrintForm.SpreadsheetDocument = Undefined Then
					PrintForm.SpreadsheetDocument = New SpreadsheetDocument;
				EndIf;
				
				Area = TemplateStructure.LabelTemplate.GetArea(TemplateStructure.AreaNameSeals);
				
				// Applying tabular document settings.
				FillPropertyValues(PrintForm.SpreadsheetDocument, TemplateStructure.LabelTemplate, , "PrintArea");
				
				For Each TemplateParameter In TemplateStructure.TemplateParameters Do
					If TMCommonUseClientServer.HasObjectAttribute(Area.Parameters, TemplateParameter.Value) Then
						ColumnDescription = ResultStructure1.MatchingDCSFieldsToTableColumns.Get(Catalogs.LabelAndPriceTagTemplates.NameOfFieldInTemplate(TemplateParameter.Key));
						If ColumnDescription <> Undefined Then
							Area.Parameters[TemplateParameter.Value] = LineProducts_[ColumnDescription];
						EndIf;
					EndIf;
				EndDo;
				
				For Each Drawing In Area.Drawings Do
					
					If StrFind(Drawing.Name, Catalogs.LabelAndPriceTagTemplates.NameOfBarcodeParameter()) = 1 Then
						
						BarcodeValue = LineProducts_[ResultStructure1.MatchingDCSFieldsToTableColumns.Get(Catalogs.LabelAndPriceTagTemplates.NameOfBarcodeParameter())];
						If ValueIsFilled(BarcodeValue) Then
							
							InputDataType = 0;
							BarcodeValueForComponent = BarcodeValue;
							PrintPriceTagsAndLabelsLocalization.WhenDeterminingBarcodeValueForComponent(
								BarcodeValueForComponent, TemplateStructure.CodeType, InputDataType);
							
							If TemplateStructure.Property("DetailLevel") Then
								DetailLevel = TemplateStructure.DetailLevel;
							Else
								DetailLevel = 1;
							EndIf;
							
							BarcodeParameters = BarcodeGeneration.BarcodeGenerationParameters();
							BarcodeParameters.Insert("Width",           Round(Drawing.Width / NumberOfMillimetersPerPixel) * DetailLevel);
							BarcodeParameters.Insert("Height",           Round(Drawing.Height / NumberOfMillimetersPerPixel) * DetailLevel);
							BarcodeParameters.Insert("Barcode",         TrimAll(BarcodeValueForComponent));
							BarcodeParameters.Insert("InputDataType", InputDataType);
							BarcodeParameters.Insert("CodeType",          TemplateStructure.CodeType);
							BarcodeParameters.Insert("TextVisible",  TemplateStructure.TextVisible);
							BarcodeParameters.Insert("FontSize",     TemplateStructure.FontSize * DetailLevel);
							
							If TemplateStructure.Property("GS1DatabarRowCount") Then
								BarcodeParameters.Insert("GS1DatabarRowCount", TemplateStructure.GS1DatabarRowCount);
							EndIf;
							If TemplateStructure.Property("FontType") Then
								BarcodeParameters.Insert("FontType", TemplateStructure.MonochromeFont);
							EndIf;
							If TemplateStructure.Property("CanvasRotation") Then
								BarcodeParameters.Insert("CanvasRotation", TemplateStructure.CanvasRotation);
							EndIf;
							If TemplateStructure.Property("MonochromeFont") Then
								BarcodeParameters.Insert("MonochromeFont", TemplateStructure.MonochromeFont);
							EndIf;
							If TemplateStructure.Property("Zoomable") Then
								BarcodeParameters.Insert("Zoomable", TemplateStructure.Zoomable);
							EndIf;
							If TemplateStructure.Property("MaintainAspectRatio") Then
								BarcodeParameters.Insert("MaintainAspectRatio", TemplateStructure.MaintainAspectRatio);
							EndIf;
							If TemplateStructure.Property("VerticalAlignment") Then
								BarcodeParameters.Insert("VerticalAlignment", TemplateStructure.VerticalAlignment);
							EndIf;
							
							Drawing.Picture = BarcodeGeneration.TheImageOfTheBarcode(BarcodeParameters).Picture;
							
						EndIf;
						
					EndIf;
					
					If StrFind(Drawing.Name, "CurrencySign") = 1 Then
						CurrencyCodeValue = LineProducts_[ResultStructure1.MatchingDCSFieldsToTableColumns.Get(Catalogs.LabelAndPriceTagTemplates.NameOfCurrencyCodeParameter())];
						Try
							Drawing.Picture = New Picture(Catalogs.LabelAndPriceTagTemplates.GetTemplate("CurrencySign" + CurrencyCodeValue), True);
						Except
							Drawing.Picture = New Picture;
						EndTry;
					EndIf;
					
				EndDo;
				
				For Indus = 1 To LineProducts_[PrintForm.ColumnNameQuantity] Do // Cycle by number of instances
					
					ColumnNumber = ColumnNumber + 1;
					
					If ColumnNumber = 1 Then
						
						RowNumber = RowNumber + 1;
						
						PrintForm.SpreadsheetDocument.Put(Area);
						
					Else
						
						PrintForm.SpreadsheetDocument.Join(Area);
						
					EndIf;
					
					If ColumnNumber = TemplateStructure.HorizontalQuantity And RowNumber = TemplateStructure.VerticalQuantity Then
						
						RowNumber    = 0;
						ColumnNumber = 0;
						
						PrintForm.SpreadsheetDocument.PutHorizontalPageBreak();
						
					ElsIf ColumnNumber = TemplateStructure.HorizontalQuantity Then
						
						ColumnNumber = 0;
						
					EndIf;
					
				EndDo; // Cycle by number of instances
				
			EndIf;
			
		EndDo; // Cycle through the rows of the product table
		
	EndDo;
	
#EndRegion
	
	For Each PrintForm In PrintFormsCollection Do
		If PrintForm.SpreadsheetDocument <> Undefined Then
			NewRow = CollectionOfBSPPrintingPlates.Add();
			
			NewRow.TemplateName = PrintForm.TemplateName;
			NewRow.UpperCaseName   = Upper(PrintForm.TemplateName);
			NewRow.Copies2 = 1;
			
			NewRow.SpreadsheetDocument = PrintForm.SpreadsheetDocument;
			NewRow.SpreadsheetDocument.PrintParametersKey = "PRINT_OPTIONS_" + PrintForm.Template.UUID();
			NewRow.TemplateSynonym = PrintForm.TemplateSynonym;
		EndIf;
	EndDo;
	
EndProcedure

Function ToFormPrintedFormOfLabelOfWarehouseCell(PrintData, PrintObjects)
	
	SettingsStructure = SettingsStructure();
	SettingsStructure.RequiredFields.Add("Cell");
	
	SettingsStructure.NameOfDataLayoutSchemaTemplate = "TemplateFieldsStorageBins";
	
	LabelsTemplate        = PrintData.LabelsTemplate;
	Copies = PrintData.Copies;
	
	SettingsStructure.RawData = GetFromTempStorage(PrintData.StorageBins);
	
	If Not PrintData.Property("StructureOfTemplateTemplate") Or Not ValueIsFilled(PrintData.StructureOfTemplateTemplate) Then
		LabelTemplateTemplate = LabelsTemplate.Template; // ValueStorage	
		TemplateStructure = LabelTemplateTemplate.Get();		// Structure - See Catalogs.LabelAndPriceTagTemplates.PrepareStructureOfTemplateTemplate
	Else
		TemplateStructure = PrintData.StructureOfTemplateTemplate;	// Structure - See Catalogs.LabelAndPriceTagTemplates.PrepareStructureOfTemplateTemplate
	EndIf;
	
	For Each Item In TemplateStructure.TemplateParameters Do
		SettingsStructure.RequiredFields.Add(Item.Key);
	EndDo;
	
	ResultStructure1 = PrepareDataStructure(SettingsStructure, "StorageBins");
	
	Etalon = DataProcessors.PrintPriceTagsAndLabels.GetTemplate("Etalon");
	DrawingSquare = Etalon.Drawings.Square100Pixels; // SpreadsheetDocumentDrawing
	NumberOfMillimetersPerPixel = DrawingSquare.Height / 100;
	
	SpreadsheetDocument = New SpreadsheetDocument;
	
	ColumnNumber = 0;
	RowNumber = 0;
	
	Area = TemplateStructure.LabelTemplate.GetArea(TemplateStructure.AreaNameSeals);
	
	For Each TableRow In ResultStructure1.Table Do
		
		FillPropertyValues(SpreadsheetDocument, TemplateStructure.LabelTemplate, , "PrintArea");
		
		For Each TemplateParameter In TemplateStructure.TemplateParameters Do
			If TMCommonUseClientServer.HasObjectAttribute(Area.Parameters, TemplateParameter.Value) Then
				ColumnDescription = ResultStructure1.MatchingDCSFieldsToTableColumns.Get(Catalogs.LabelAndPriceTagTemplates.NameOfFieldInTemplate(TemplateParameter.Key));
				If ColumnDescription <> Undefined Then
					Area.Parameters[TemplateParameter.Value] = TableRow[ColumnDescription];
				EndIf;
			EndIf;
		EndDo;
		
		For Each Drawing In Area.Drawings Do
			If StrFind(Drawing.Name, Catalogs.LabelAndPriceTagTemplates.NameOfBarcodeParameter()) = 1 Then
				
				BarcodeValue = TableRow[ResultStructure1.MatchingDCSFieldsToTableColumns.Get(Catalogs.LabelAndPriceTagTemplates.NameOfBarcodeParameter())];
				If ValueIsFilled(BarcodeValue) Then
					
					InputDataType = 0;
					BarcodeValueForComponent = BarcodeValue;
					PrintPriceTagsAndLabelsLocalization.WhenDeterminingBarcodeValueForComponent(
						BarcodeValueForComponent, TemplateStructure.CodeType, InputDataType);
					
					If TemplateStructure.Property("DetailLevel") Then
						DetailLevel = TemplateStructure.DetailLevel;
					Else
						DetailLevel = 1;
					EndIf;
					
					BarcodeParameters = BarcodeGeneration.BarcodeGenerationParameters();
					BarcodeParameters.Insert("Width",           Round(Drawing.Width / NumberOfMillimetersPerPixel));
					BarcodeParameters.Insert("Height",           Round(Drawing.Height / NumberOfMillimetersPerPixel));
					BarcodeParameters.Insert("Barcode",         TrimAll(BarcodeValueForComponent));
					BarcodeParameters.Insert("InputDataType", InputDataType);
					BarcodeParameters.Insert("CodeType",          TemplateStructure.CodeType);
					BarcodeParameters.Insert("TextVisible",  TemplateStructure.TextVisible);
					BarcodeParameters.Insert("FontSize",     TemplateStructure.FontSize * DetailLevel);
					
					If TemplateStructure.Property("GS1DatabarRowCount") Then
						BarcodeParameters.Insert("GS1DatabarRowCount", TemplateStructure.GS1DatabarRowCount);
					EndIf;
					If TemplateStructure.Property("FontType") Then
						BarcodeParameters.Insert("FontType", TemplateStructure.MonochromeFont);
					EndIf;
					If TemplateStructure.Property("CanvasRotation") Then
						BarcodeParameters.Insert("CanvasRotation", TemplateStructure.CanvasRotation);
					EndIf;
					If TemplateStructure.Property("MonochromeFont") Then
						BarcodeParameters.Insert("MonochromeFont", TemplateStructure.MonochromeFont);
					EndIf;
					If TemplateStructure.Property("Zoomable") Then
						BarcodeParameters.Insert("Zoomable", TemplateStructure.Zoomable);
					EndIf;
					If TemplateStructure.Property("MaintainAspectRatio") Then
						BarcodeParameters.Insert("MaintainAspectRatio", TemplateStructure.MaintainAspectRatio);
					EndIf;
					If TemplateStructure.Property("VerticalAlignment") Then
						BarcodeParameters.Insert("VerticalAlignment", TemplateStructure.VerticalAlignment);
					EndIf;
					
					Drawing.Picture = BarcodeGeneration.TheImageOfTheBarcode(BarcodeParameters).Picture;
					
				EndIf;
				
			EndIf;
		EndDo;
		
		For Indus = 1 To Copies Do // Cycle by number of instances
			
			ColumnNumber = ColumnNumber + 1;
			
			If ColumnNumber = 1 Then
				
				RowNumber = RowNumber + 1;
				
				SpreadsheetDocument.Put(Area);
				
			Else
				
				SpreadsheetDocument.Join(Area);
				
			EndIf;
			
			If ColumnNumber = TemplateStructure.HorizontalQuantity
				And RowNumber = TemplateStructure.VerticalQuantity Then
				
				RowNumber    = 0;
				ColumnNumber = 0;
				
				SpreadsheetDocument.PutHorizontalPageBreak();
				
			ElsIf ColumnNumber = TemplateStructure.HorizontalQuantity Then
				
				ColumnNumber = 0;
				
			EndIf;
			
		EndDo; // Cycle by number of instances
		
	EndDo; // Cycle through the rows of the table
	
	Return SpreadsheetDocument;
	
EndFunction

Function FormPrintedFormOfShippingLabel(PrintData, PrintObjects, CollectionOfBSPPrintingPlates)
	
	SettingsStructure = SettingsStructure();
	SettingsStructure.RequiredFields.Add("ReferenceOrder");
	SettingsStructure.RequiredFields.Add("LabelsTemplate");
	
	SettingsStructure.NameOfDataLayoutSchemaTemplate = "TemplateFieldsDelivery";
	
	// We collect the fields used from the templates.
	DeliveryTable = GetFromTempStorage(PrintData.AddressInStorage);
	PutToTempStorage(Undefined, PrintData.AddressInStorage); 

	PatternMatching = New Map;
	For Each TSRow In DeliveryTable Do
		If ValueIsFilled(TSRow.LabelsTemplate) Then
			PatternMatching.Insert(TSRow.LabelsTemplate);
		EndIf;
	EndDo;
	If PrintData.Property("StructureOfTemplateTemplate") And ValueIsFilled(PrintData.StructureOfTemplateTemplate) Then
		PatternMatching.Insert(Catalogs.LabelAndPriceTagTemplates.EmptyRef());
	EndIf;
	
	// We fill in the collection of required fields and form a template match.
	For Each KeyAndValue In PatternMatching Do
		
		LabelAndPriceTagTemplate = KeyAndValue.Key;
		
		If ValueIsFilled(LabelAndPriceTagTemplate) Then
			TemplateOfLabelsAndPriceTagsTemplate = LabelAndPriceTagTemplate.Template; // ValueStorage
			TemplateStructure = TemplateOfLabelsAndPriceTagsTemplate.Get();
		Else
			TemplateStructure = PrintData.StructureOfTemplateTemplate;
		EndIf;
		
		// The structure of templates.
		SettingsStructure.PatternMatchingAndPatternStructure.Insert(KeyAndValue.Key, TemplateStructure);
		
		// We add the fields present in the printed form of the price tag to the array of mandatory fields.
		For Each Item In TemplateStructure.TemplateParameters Do
			SettingsStructure.RequiredFields.Add(Item.Key);	
		EndDo;
		
	EndDo;
	
	SettingsStructure.RawData = DeliveryTable;

#Region PreparingTemplateDataStructure
	
	ResultStructure1 = PrepareDataStructure(SettingsStructure, "Delivery");
	
	// Preparation of a collection of printed forms.
	PrintFormsCollection = New ValueTable;
	PrintFormsCollection.Columns.Add("TemplateName");
	PrintFormsCollection.Columns.Add("TemplateSynonym");
	PrintFormsCollection.Columns.Add("SpreadsheetDocument");
	PrintFormsCollection.Columns.Add("ColumnNameTemplate");
	PrintFormsCollection.Columns.Add("Template");
	
	For Each KeyAndValue In SettingsStructure.PatternMatchingAndPatternStructure Do
	
		PrintForm = PrintFormsCollection.Add();
		PrintForm.TemplateName            = "Label_: "+KeyAndValue.Key;
		PrintForm.TemplateSynonym        =  StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Nhãn tem: %1';
																											|ru = 'Этикетка: %1';
																											|en = 'Label: %1'; fa = 'Label: %1';
																											|it = 'Etichetta: %1';
																											|pl = 'Etykieta: %1';
																											|tr = 'Etiket: %1'"), KeyAndValue.Key);
		PrintForm.ColumnNameTemplate     = "LabelsTemplate";
		PrintForm.Template = KeyAndValue.Key;
		
	EndDo;
	
#EndRegion
	
	SpreadsheetDocument = New SpreadsheetDocument;
	VerticalQuantity =0;
	
	For Each PrintForm In PrintFormsCollection Do
		
		RowNumber    = 0;
		ColumnNumber = 0;
		VerticalQuantity = VerticalQuantity + 1/TemplateStructure.VerticalQuantity; 
		If VerticalQuantity > 1  Then
			VerticalQuantity =0;
			
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
				
		For Each LineProducts_ In ResultStructure1.Table Do
			
			If LineProducts_[PrintForm.ColumnNameTemplate] = PrintForm.Template Then
				
				TemplateStructure = SettingsStructure.PatternMatchingAndPatternStructure.Get(LineProducts_[PrintForm.ColumnNameTemplate]);
				
				Area = TemplateStructure.LabelTemplate.GetArea(TemplateStructure.AreaNameSeals); // SpreadsheetDocument
				
				// Applying tabular document settings.
				FillPropertyValues(SpreadsheetDocument, TemplateStructure.LabelTemplate, , "PrintArea");
				
				For Each TemplateParameter In TemplateStructure.TemplateParameters Do
					If TMCommonUseClientServer.HasObjectAttribute(Area.Parameters, TemplateParameter.Value) Then
						ColumnDescription = ResultStructure1.MatchingDCSFieldsToTableColumns.Get(Catalogs.LabelAndPriceTagTemplates.NameOfFieldInTemplate(TemplateParameter.Key));
						If ColumnDescription <> Undefined Then
							Area.Parameters[TemplateParameter.Value] = LineProducts_[ColumnDescription];
						EndIf;
					EndIf;
				EndDo;
				
				ColumnNumber = ColumnNumber + 1;
				
				If ColumnNumber = 1 Then
					
					RowNumber = RowNumber + 1;
					
					SpreadsheetDocument.Put(Area);
					
				Else
					
					SpreadsheetDocument.Join(Area);
					
				EndIf;
				
				If RowNumber = TemplateStructure.VerticalQuantity And ColumnNumber = TemplateStructure.HorizontalQuantity Then
					
					RowNumber    = 0;
					ColumnNumber = 0;
					VerticalQuantity =0;
					
					SpreadsheetDocument.PutHorizontalPageBreak();
					
				ElsIf ColumnNumber = TemplateStructure.HorizontalQuantity Then
					
					ColumnNumber = 0;
					VerticalQuantity = VerticalQuantity + 1/TemplateStructure.VerticalQuantity;
					
				EndIf;
				
			EndIf;
			
		EndDo; // Cycle through the rows of the product table
		
	EndDo;
	
	StructureOfTypes = TMCommonUse.MatchingArraysByObjectType(DeliveryTable.UnloadColumn("ReferenceOrder"));
	PrintData.Insert( "StructureOfTypes", StructureOfTypes );
	
	Return SpreadsheetDocument;
	
EndFunction

Function ToFormPrintedFormOfLabelOfSeriesOfProducts(PrintData, PrintObjects)
	
	SettingsStructure = SettingsStructure();
	SettingsStructure.RequiredFields.Add("Series");
	
	SettingsStructure.NameOfDataLayoutSchemaTemplate = "TemplateFieldsItemBatch";
	
	LabelsTemplate        = PrintData.LabelsTemplate;
	Copies = PrintData.Copies;
	
	SettingsStructure.RawData = GetFromTempStorage(PrintData.AddressInStorage);
	
	If Not PrintData.Property("StructureOfTemplateTemplate") Or Not ValueIsFilled(PrintData.StructureOfTemplateTemplate) Then
		LabelTemplateTemplate = Common.ObjectAttributeValue(LabelsTemplate, "Template"); // ValueStorage
		TemplateStructure = LabelTemplateTemplate.Get();		// Structure - See Catalogs.LabelAndPriceTagTemplates.PrepareStructureOfTemplateTemplate
	Else
		TemplateStructure = PrintData.StructureOfTemplateTemplate;	// Structure - See Catalogs.LabelAndPriceTagTemplates.PrepareStructureOfTemplateTemplate
	EndIf;
	
	For Each Item In TemplateStructure.TemplateParameters Do
		SettingsStructure.RequiredFields.Add(Item.Key);
	EndDo;
	
	ResultStructure1 = PrepareDataStructure(SettingsStructure, "ItemsBatches");
	
	Etalon = DataProcessors.PrintPriceTagsAndLabels.GetTemplate("Etalon");
	DrawingSquare = Etalon.Drawings.Square100Pixels; // SpreadsheetDocumentDrawing
	NumberOfMillimetersPerPixel = DrawingSquare.Height / 100;
	
	SpreadsheetDocument = New SpreadsheetDocument;
	
	ColumnNumber = 0;
	RowNumber = 0;
	
	Area = TemplateStructure.LabelTemplate.GetArea(TemplateStructure.AreaNameSeals);
	
	For Each TableRow In ResultStructure1.Table Do
		
		FillPropertyValues(SpreadsheetDocument, TemplateStructure.LabelTemplate, , "PrintArea");
		
		For Each TemplateParameter In TemplateStructure.TemplateParameters Do
			If TMCommonUseClientServer.HasObjectAttribute(Area.Parameters, TemplateParameter.Value) Then
				ColumnDescription = ResultStructure1.MatchingDCSFieldsToTableColumns.Get(Catalogs.LabelAndPriceTagTemplates.NameOfFieldInTemplate(TemplateParameter.Key));
				If ColumnDescription <> Undefined Then
					Area.Parameters[TemplateParameter.Value] = TableRow[ColumnDescription];
				EndIf;
			EndIf;
		EndDo;
		
		For Each Drawing In Area.Drawings Do
			If StrFind(Drawing.Name, Catalogs.LabelAndPriceTagTemplates.NameOfBarcodeParameter()) = 1 Then
				
				BarcodeValue = TableRow[ResultStructure1.MatchingDCSFieldsToTableColumns.Get(Catalogs.LabelAndPriceTagTemplates.NameOfBarcodeParameter())];
				If ValueIsFilled(BarcodeValue) Then
					
					InputDataType = 0;
					BarcodeValueForComponent = BarcodeValue;
					PrintPriceTagsAndLabelsLocalization.WhenDeterminingBarcodeValueForComponent(
						BarcodeValueForComponent, TemplateStructure.CodeType, InputDataType);
					
					If TemplateStructure.Property("DetailLevel") Then
						DetailLevel = TemplateStructure.DetailLevel;
					Else
						DetailLevel = 1;
					EndIf;
					
					BarcodeParameters = BarcodeGeneration.BarcodeGenerationParameters();
					BarcodeParameters.Insert("Width",           Round(Drawing.Width / NumberOfMillimetersPerPixel));
					BarcodeParameters.Insert("Height",           Round(Drawing.Height / NumberOfMillimetersPerPixel));
					BarcodeParameters.Insert("Barcode",         TrimAll(BarcodeValueForComponent));
					BarcodeParameters.Insert("InputDataType", InputDataType);
					BarcodeParameters.Insert("CodeType",          TemplateStructure.CodeType);
					BarcodeParameters.Insert("TextVisible",  TemplateStructure.TextVisible);
					BarcodeParameters.Insert("FontSize",     TemplateStructure.FontSize * DetailLevel);
					
					If TemplateStructure.Property("GS1DatabarRowCount") Then
						BarcodeParameters.Insert("GS1DatabarRowCount", TemplateStructure.GS1DatabarRowCount);
					EndIf;
					If TemplateStructure.Property("FontType") Then
						BarcodeParameters.Insert("FontType", TemplateStructure.MonochromeFont);
					EndIf;
					If TemplateStructure.Property("CanvasRotation") Then
						BarcodeParameters.Insert("CanvasRotation", TemplateStructure.CanvasRotation);
					EndIf;
					If TemplateStructure.Property("MonochromeFont") Then
						BarcodeParameters.Insert("MonochromeFont", TemplateStructure.MonochromeFont);
					EndIf;
					If TemplateStructure.Property("Zoomable") Then
						BarcodeParameters.Insert("Zoomable", TemplateStructure.Zoomable);
					EndIf;
					If TemplateStructure.Property("MaintainAspectRatio") Then
						BarcodeParameters.Insert("MaintainAspectRatio", TemplateStructure.MaintainAspectRatio);
					EndIf;
					If TemplateStructure.Property("VerticalAlignment") Then
						BarcodeParameters.Insert("VerticalAlignment", TemplateStructure.VerticalAlignment);
					EndIf;
					
					Drawing.Picture = BarcodeGeneration.TheImageOfTheBarcode(BarcodeParameters).Picture;
					
				EndIf;
				
			EndIf;
		EndDo;
		
		For Indus = 1 To Copies Do // Cycle by number of instances
			
			ColumnNumber = ColumnNumber + 1;
			
			If ColumnNumber = 1 Then
				
				RowNumber = RowNumber + 1;
				
				SpreadsheetDocument.Put(Area);
				
			Else
				
				SpreadsheetDocument.Join(Area);
				
			EndIf;
			
			If ColumnNumber = TemplateStructure.HorizontalQuantity
				And RowNumber = TemplateStructure.VerticalQuantity Then
				
				RowNumber    = 0;
				ColumnNumber = 0;
				
				SpreadsheetDocument.PutHorizontalPageBreak();
				
			ElsIf ColumnNumber = TemplateStructure.HorizontalQuantity Then
				
				ColumnNumber = 0;
				
			EndIf;
			
		EndDo; // Cycle by number of instances
		
	EndDo; // Cycle through the rows of the table
	
	Return SpreadsheetDocument;
	
EndFunction

Function FormPrintedFormLabelsPackingSheets(PrintData, PrintObjects)
	
	SettingsStructure = SettingsStructure();
	SettingsStructure.RequiredFields.Add("PackingList");
	
	SettingsStructure.NameOfDataLayoutSchemaTemplate = "TemplateFieldsPackingLists";
	
	If Not PrintData.Property("LabelsTemplate") Then
		LabelsTemplate = Constants.PackingListLabelTemplate.Get();
		If Not ValueIsFilled(LabelsTemplate) Then
			ExceptionText = NStr("vi = 'Không thể in nhãn tem vì trong tùy chỉnh chương trình chưa chọn khuôn mẫu nhãn tem theo mặc định. Hãy liên hệ với người quản trị.';
								|ru = 'Печать этикетки не возможна, т.к. в настройках программы не выбран шаблон этикетки по умолчанию. Обратитесь к администратору.';
								|en = 'Cannot print a label as the default label is not selected in the application settings. Please contact the administrator.'; fa = 'Cannot print a label as the default label is not selected in the application settings. Please contact the administrator.';
								|it = 'La stampa dell''etichetta non è possibile perché Il modello di etichetta di default non è selezionato nelle impostazioni del programma. Contattare amministratore.';
								|pl = 'Wydruk etykiety nie jest możliwy, ponieważ w ustawieniach programu nie został wybrany szablon domyślnej etykiety. Skontaktuj się z administratorem.';
								|tr = 'Yazılım ayarlarında varsayılan etiket numunesi seçilmediği için etiket yazdırılamıyor. Yöneticinize başvurun.'");
			
			Raise ExceptionText;
			
		EndIf;
	Else
	    LabelsTemplate = PrintData.LabelsTemplate;
	EndIf;
	
	If Not PrintData.Property("Copies") Then
		Copies = 1;
	Else
	    Copies = PrintData.Copies;
	EndIf;
	
	SettingsStructure.RawData = GetFromTempStorage(PrintData.AddressInStorage);
	PutToTempStorage(Undefined, PrintData.AddressInStorage); 
	
	If Not PrintData.Property("StructureOfTemplateTemplate") Or Not ValueIsFilled(PrintData.StructureOfTemplateTemplate) Then
		TemplateStructure = Common.ObjectAttributeValue(LabelsTemplate, "Template").Get();	// Structure - See Catalogs.LabelAndPriceTagTemplates.PrepareStructureOfTemplateTemplate
	Else
		TemplateStructure = PrintData.StructureOfTemplateTemplate;	// Structure - See Catalogs.LabelAndPriceTagTemplates.PrepareStructureOfTemplateTemplate
	EndIf;
	
	For Each Item In TemplateStructure.TemplateParameters Do
		SettingsStructure.RequiredFields.Add(Item.Key);
	EndDo;
	
	ResultStructure1 = PrepareDataStructure(SettingsStructure, "PackingLists");
	
	Etalon = DataProcessors.PrintPriceTagsAndLabels.GetTemplate("Etalon");
	DrawingSquare = Etalon.Drawings.Square100Pixels; // SpreadsheetDocumentDrawing
	NumberOfMillimetersPerPixel = DrawingSquare.Height / 100;
	
	SpreadsheetDocument = New SpreadsheetDocument;
	
	ColumnNumber = 0;
	RowNumber = 0;
	
	Area = TemplateStructure.LabelTemplate.GetArea(TemplateStructure.AreaNameSeals);
	
	For Each TableRow In ResultStructure1.Table Do
			
		FillPropertyValues(SpreadsheetDocument, TemplateStructure.LabelTemplate, , "PrintArea");
		
		For Each TemplateParameter In TemplateStructure.TemplateParameters Do
			If TMCommonUseClientServer.HasObjectAttribute(Area.Parameters, TemplateParameter.Value) Then
				ColumnDescription = ResultStructure1.MatchingDCSFieldsToTableColumns.Get(Catalogs.LabelAndPriceTagTemplates.NameOfFieldInTemplate(TemplateParameter.Key));
				If ColumnDescription <> Undefined Then
					Area.Parameters[TemplateParameter.Value] = TableRow[ColumnDescription];
				EndIf;
			EndIf;
		EndDo;
		
		For Each Drawing In Area.Drawings Do
			If StrFind(Drawing.Name, Catalogs.LabelAndPriceTagTemplates.NameOfBarcodeParameter()) = 1 Then
				
				BarcodeValue = TableRow[ResultStructure1.MatchingDCSFieldsToTableColumns.Get(Catalogs.LabelAndPriceTagTemplates.NameOfBarcodeParameter())];
				If ValueIsFilled(BarcodeValue) Then
					
					InputDataType = 0;
					BarcodeValueForComponent = BarcodeValue;
					PrintPriceTagsAndLabelsLocalization.WhenDeterminingBarcodeValueForComponent(
						BarcodeValueForComponent, TemplateStructure.CodeType, InputDataType);
					
					If TemplateStructure.Property("DetailLevel") Then
						DetailLevel = TemplateStructure.DetailLevel;
					Else
						DetailLevel = 1;
					EndIf;
					
					BarcodeParameters = BarcodeGeneration.BarcodeGenerationParameters();
					BarcodeParameters.Insert("Width",           Round(Drawing.Width / NumberOfMillimetersPerPixel));
					BarcodeParameters.Insert("Height",           Round(Drawing.Height / NumberOfMillimetersPerPixel));
					BarcodeParameters.Insert("Barcode",         TrimAll(BarcodeValueForComponent));
					BarcodeParameters.Insert("InputDataType", InputDataType);
					BarcodeParameters.Insert("CodeType",          TemplateStructure.CodeType);
					BarcodeParameters.Insert("TextVisible",  TemplateStructure.TextVisible);
					BarcodeParameters.Insert("FontSize",     TemplateStructure.FontSize * DetailLevel);
					
					If TemplateStructure.Property("GS1DatabarRowCount") Then
						BarcodeParameters.Insert("GS1DatabarRowCount", TemplateStructure.GS1DatabarRowCount);
					EndIf;
					If TemplateStructure.Property("FontType") Then
						BarcodeParameters.Insert("FontType", TemplateStructure.MonochromeFont);
					EndIf;
					If TemplateStructure.Property("CanvasRotation") Then
						BarcodeParameters.Insert("CanvasRotation", TemplateStructure.CanvasRotation);
					EndIf;
					If TemplateStructure.Property("MonochromeFont") Then
						BarcodeParameters.Insert("MonochromeFont", TemplateStructure.MonochromeFont);
					EndIf;
					If TemplateStructure.Property("Zoomable") Then
						BarcodeParameters.Insert("Zoomable", TemplateStructure.Zoomable);
					EndIf;
					If TemplateStructure.Property("MaintainAspectRatio") Then
						BarcodeParameters.Insert("MaintainAspectRatio", TemplateStructure.MaintainAspectRatio);
					EndIf;
					If TemplateStructure.Property("VerticalAlignment") Then
						BarcodeParameters.Insert("VerticalAlignment", TemplateStructure.VerticalAlignment);
					EndIf;
					
					Drawing.Picture = BarcodeGeneration.TheImageOfTheBarcode(BarcodeParameters).Picture;
					
				EndIf;
				
			EndIf;
		EndDo;
		
		For Indus = 1 To Copies Do // Cycle by number of instances
			
			ColumnNumber = ColumnNumber + 1;
			
			If ColumnNumber = 1 Then
				
				RowNumber = RowNumber + 1;
				
				SpreadsheetDocument.Put(Area);
				
			Else
				
				SpreadsheetDocument.Join(Area);
				
			EndIf;
			
			If ColumnNumber = TemplateStructure.HorizontalQuantity
				And RowNumber = TemplateStructure.VerticalQuantity Then
				
				RowNumber    = 0;
				ColumnNumber = 0;
				
				SpreadsheetDocument.PutHorizontalPageBreak();
				
			ElsIf ColumnNumber = TemplateStructure.HorizontalQuantity Then
				
				ColumnNumber = 0;
				
			EndIf;
			
		EndDo; // Cycle by number of instances
		
	EndDo; // Cycle through the rows of the table
	
	Return SpreadsheetDocument;
	
EndFunction

#EndRegion

#Region Other

Function SetValueOfDCSParameter(SettingsComposer, ParameterName, ParameterValue, UseNotFilled = True)
	
	ParameterIsSet = False;
	
	DataCompositionParameter = New DataCompositionParameter(ParameterName);
	DataCompositionParameterValue = SettingsComposer.Settings.DataParameters.FindParameterValue(DataCompositionParameter);
	If DataCompositionParameterValue <> Undefined Then
		
		DataCompositionParameterValue.Value = ParameterValue;
		DataCompositionParameterValue.Use = ?(UseNotFilled, True, ValueIsFilled(DataCompositionParameterValue.Value));
		
		ParameterIsSet = True;
		
	EndIf;
	
	Return ParameterIsSet;
	
EndFunction

// the structure of the settings.
// 
// Returns:
//  Structure - Structure of settings:
// * RawData - Undefined -
// * RequiredFields - Array of String -
// * PatternMatchingAndPatternStructure - Map -
// * DataParameters - Structure -
// * SettingsComposer - Undefined -
// * NameOfDataLayoutSchemaTemplate - Undefined -
// * UsePriceManagementSystem25 - Undefined -
Function SettingsStructure() Export
	
	SettingsStructure = New Structure;
	SettingsStructure.Insert("RawData",                         Undefined);
	SettingsStructure.Insert("RequiredFields",                       New Array);
	SettingsStructure.Insert("PatternMatchingAndPatternStructure", New Map);
	SettingsStructure.Insert("DataParameters"    ,                    New Structure);
	SettingsStructure.Insert("SettingsComposer",                    Undefined);
	SettingsStructure.Insert("NameOfDataLayoutSchemaTemplate",         Undefined);
	SettingsStructure.Insert("UsePriceManagementSystem25",          Undefined);
	
	Return SettingsStructure;
	
EndFunction

Function ShippingLabelPrintingData(ObjectsArray) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	
	ArrayOfRequestTexts = New Array;
	CurrentObject = ObjectsArray[0];
	
	If TypeOf(CurrentObject) = Type("DocumentRef.TransportationJob") Then
		
		TextOfRequestToCreateTTTaskOrder =
		"SELECT
		|	TransportationTask.Ref AS TransportationJob,
		|	CASE
		|		WHEN TransportationTask.Ref.JobIsPerformedBy = VALUE(Enum.TypesOfTransportationJobAssignees.Carrier)
		|			THEN TransportationTask.Ref.Carrier
		|		ELSE TransportationTask.ReferenceOrder.CarrierPartner
		|	END AS Carrier,
		|	TransportationTask.ReferenceOrder AS ReferenceOrder,
		|	TransportationTask.Weight AS Weight,
		|	TransportationTask.VolumeM3 AS VolumeM3,
		|	CASE
		|		WHEN TransportationTask.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
		|				AND TransportationTask.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= TransportationTask.Ref.PlanTripStartTime
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS AdvancedWarehouse,
		|	TransportationTask.Warehouse AS Warehouse,
		|	CASE
		|		WHEN TransportationTask.Ref.JobIsPerformedBy = VALUE(Enum.TypesOfTransportationJobAssignees.Carrier)
		|			AND ISNULL(TransportationTask.Ref.Carrier.LabelsTemplate, VALUE(Catalog.LabelAndPriceTagTemplates.EmptyRef)) <> VALUE(Catalog.LabelAndPriceTagTemplates.EmptyRef)
		|			THEN TransportationTask.Ref.Carrier.LabelsTemplate
		|		WHEN TransportationTask.RecipientSender REFS Catalog.Partners
		|			AND ISNULL(CAST(TransportationTask.RecipientSender AS Catalog.Partners).LabelsTemplate, VALUE(Catalog.LabelAndPriceTagTemplates.EmptyRef)) <> VALUE(Catalog.LabelAndPriceTagTemplates.EmptyRef)
		|			THEN CAST(TransportationTask.RecipientSender AS Catalog.Partners).LabelsTemplate
		|		ELSE &ShippingLabelTemplate
		|	END AS LabelsTemplate,
		|	SUM(ISNULL(GoodsIssueNote.TotalNumberOfPackageItems, 0)) AS TotalNumberOfPackageItems
		|INTO InstructionsForTask
		|FROM
		|	Document.TransportationJob.References AS TransportationTask
		|		LEFT JOIN Document.GoodsIssueNote AS GoodsIssueNote
		|		ON TransportationTask.Ref = GoodsIssueNote.TransportationJob
		|WHERE
		|	TransportationTask.Ref IN(&CommandParameter)
		|	AND NOT TransportationTask.ReferenceOrder REFS Document.InstructionForShippingAgent
		|
		|GROUP BY
		|	TransportationTask.ReferenceOrder,
		|	TransportationTask.Ref,
		|	CASE
		|		WHEN TransportationTask.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
		|				AND TransportationTask.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= TransportationTask.Ref.PlanTripStartTime
		|			THEN TRUE
		|		ELSE FALSE
		|	END,
		|	CASE
		|		WHEN TransportationTask.Ref.JobIsPerformedBy = VALUE(Enum.TypesOfTransportationJobAssignees.Carrier)
		|			AND ISNULL(TransportationTask.Ref.Carrier.LabelsTemplate, VALUE(Catalog.LabelAndPriceTagTemplates.EmptyRef)) <> VALUE(Catalog.LabelAndPriceTagTemplates.EmptyRef)
		|			THEN TransportationTask.Ref.Carrier.LabelsTemplate
		|		WHEN TransportationTask.RecipientSender REFS Catalog.Partners
		|			AND ISNULL(CAST(TransportationTask.RecipientSender AS Catalog.Partners).LabelsTemplate, VALUE(Catalog.LabelAndPriceTagTemplates.EmptyRef)) <> VALUE(Catalog.LabelAndPriceTagTemplates.EmptyRef)
		|			THEN CAST(TransportationTask.RecipientSender AS Catalog.Partners).LabelsTemplate
		|		ELSE &ShippingLabelTemplate
		|	END,
		|	CASE
		|		WHEN TransportationTask.Ref.JobIsPerformedBy = VALUE(Enum.TypesOfTransportationJobAssignees.Carrier)
		|			THEN TransportationTask.Ref.Carrier
		|		ELSE TransportationTask.ReferenceOrder.CarrierPartner
		|	END,
		|	TransportationTask.Warehouse,
		|	TransportationTask.VolumeM3,
		|	TransportationTask.Weight";
		
		QueryTextByReference =
		"SELECT
		|	InstructionsForTask.ReferenceOrder AS ReferenceOrder,
		|	InstructionsForTask.Carrier AS Carrier,
		|	InstructionsForTask.Weight AS InvoiceWeight,
		|	InstructionsForTask.VolumeM3 AS InvoiceVolume,
		|	InstructionsForTask.LabelsTemplate AS LabelsTemplate,
		|	COUNT(DISTINCT DocumentOrderGoods.LineNumber) AS NumberOfRows
		|,&QueryTextTSName
		|FROM
		|	InstructionsForTask AS InstructionsForTask
		|		INNER JOIN TextNameTSGoods AS DocumentOrderGoods
		|		ON (&TextOfItchHeaderConnectionCondition)
		|			AND (&TextOfConnectionToWarehouseOrder)
		|WHERE
		|	NOT InstructionsForTask.AdvancedWarehouse
		|
		|GROUP BY
		|	InstructionsForTask.ReferenceOrder,
		|	InstructionsForTask.Carrier,
		|	InstructionsForTask.Weight,
		|	InstructionsForTask.VolumeM3,
		|	InstructionsForTask.LabelsTemplate,
		|	InstructionsForTask.TotalNumberOfPackageItems";
		
		ArrayOfTextsForOrders = New Array;
		
		TypesOfOrders = Metadata.DefinedTypes.DeliveryReferenceOrder.Type.Types();
		ThisIsFirstOneType = True;
		
		For Each TypeOfOrder_ In TypesOfOrders Do
			
			MetadataOfOrders = Metadata.FindByType(TypeOfOrder_);
						
			If Not Common.IsDocument(MetadataOfOrders)
				Or MetadataOfOrders = Metadata.Documents.InstructionForShippingAgent Then
				Continue;
			Else
				
				QueryText = DataForPrintingDeliveryLabelsToAdaptToOrder(MetadataOfOrders, QueryTextByReference);
				QueryText = StrReplace(QueryText, "&TextOfItchHeaderConnectionCondition", "InstructionsForTask.ReferenceOrder = DocumentOrderGoods.Ref");
				If ThisIsFirstOneType Then
					QueryText = StrReplace(QueryText, ",&QueryTextTSName", "INTO TTOrdersAndTemplates");
					ThisIsFirstOneType = False;
				Else
					QueryText = StrReplace(QueryText, ",&QueryTextTSName", "");
				EndIf;
				
				ArrayOfTextsForOrders.Add(QueryText);
				
			EndIf;
			If MetadataOfOrders = Metadata.Documents.SubcontractOrder2_5
			 Or False Then
				
				QueryText = StrReplace(QueryTextByReference, "TextNameTSGoods", "Document.ProductionStage2_2.SupplyWithMaterialsAndWorks");
				QueryText = StrReplace(QueryText, ",&QueryTextTSName", "");
				QueryText = StrReplace(QueryText, "&TextOfItchHeaderConnectionCondition",
					"(DocumentOrderGoods.Ref.SubcontractOrder = InstructionsForTask.ReferenceOrder AND NOT DocumentOrderGoods.Canceled)");
				QueryText = DataForPrintingDeliveryLabelsToAdaptToOrder(MetadataOfOrders, QueryText);
				
				ArrayOfTextsForOrders.Add(QueryText);
			EndIf;
		EndDo;
		
		If GetFunctionalOption("UseWarehouseManagementSystem") Then
			QueryText =
			"SELECT
			|	InstructionsForTask.ReferenceOrder AS ReferenceOrder,
			|	InstructionsForTask.Carrier AS Carrier,
			|	InstructionsForTask.Weight AS InvoiceWeight,
			|	InstructionsForTask.VolumeM3 AS InvoiceVolume,
			|	InstructionsForTask.LabelsTemplate AS LabelsTemplate,
			|	InstructionsForTask.TotalNumberOfPackageItems AS NumberOfRows
			|FROM
			|	InstructionsForTask AS InstructionsForTask
			|WHERE
			|	InstructionsForTask.AdvancedWarehouse
			|
			|GROUP BY
			|	InstructionsForTask.ReferenceOrder,
			|	InstructionsForTask.Carrier,
			|	InstructionsForTask.Weight,
			|	InstructionsForTask.VolumeM3,
			|	InstructionsForTask.LabelsTemplate,
			|	InstructionsForTask.TotalNumberOfPackageItems";
			
			ArrayOfTextsForOrders.Add(QueryText);
		EndIf;
		
		QueryTextTTOrdersAndTemplates = StrConcat(ArrayOfTextsForOrders, TMCommonUse.QuerySeparatorInJoin());
		
		TaskSelectionTextWithoutInstructions =
		"SELECT
		|	NestedQuery.Ref AS Ref
		|FROM
		|	(SELECT DISTINCT
		|		TransportationTask.Ref AS Ref
		|	FROM
		|		Document.TransportationJob.References AS TransportationTask
		|			LEFT JOIN InstructionsForTask AS InstructionsForTask
		|			ON TransportationTask.Ref = InstructionsForTask.TransportationJob
		|	WHERE
		|		TransportationTask.Ref IN(&CommandParameter)
		|		AND InstructionsForTask.TransportationJob IS NULL
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		TransportationJobs.Ref
		|	FROM
		|		Document.TransportationJob AS TransportationJobs
		|			LEFT JOIN Document.TransportationJob.References AS TransportationTask
		|			ON TransportationJobs.Ref = TransportationTask.Ref
		|	WHERE
		|		TransportationJobs.Ref IN(&CommandParameter)
		|		AND TransportationTask.Ref IS NULL) AS NestedQuery
		|WHERE
		|	NOT NestedQuery.Ref IS NULL";
		
		ArrayOfRequestTexts.Add(TextOfRequestToCreateTTTaskOrder);
		ArrayOfRequestTexts.Add(QueryTextTTOrdersAndTemplates);
		ArrayOfRequestTexts.Add(TaskSelectionTextWithoutInstructions);
		
	Else
		
		QueryTextByReference =
		"SELECT
		|	DocumentReferenceOrder.Ref AS ReferenceOrder,
		|	DocumentReferenceOrder.CarrierPartner AS Carrier,
		|	SUM(CASE
		|			WHEN DocumentOrderGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|					OR &QueryTextPackageWeight = 0
		|				THEN &QueryTextItemWeight * DocumentOrderGoods.Count
		|			ELSE &QueryTextPackageWeight * DocumentOrderGoods.NumberOfPackages
		|		END) AS InvoiceWeight,
		|	SUM(CASE
		|			WHEN DocumentOrderGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|					OR &QueryTextPackageVolume = 0
		|				THEN &QueryTextTheVolumeOfTheItem * DocumentOrderGoods.Count
		|			ELSE &QueryTextPackageVolume * DocumentOrderGoods.NumberOfPackages
		|		END) AS InvoiceVolume,
		|	COUNT(DISTINCT DocumentOrderGoods.LineNumber) AS NumberOfRows,
		|	CASE
		|		WHEN (DocumentReferenceOrder.DeliveryMethod = VALUE(Enum.TransportMethods.SelfPickup)
		|				OR DocumentReferenceOrder.DeliveryMethod = VALUE(Enum.TransportMethods.ToCustomer))
		|				AND ISNULL(&RequestTextTemplateFromPartnerCard, VALUE(Catalog.LabelAndPriceTagTemplates.EmptyRef)) <> VALUE(Catalog.LabelAndPriceTagTemplates.EmptyRef)
		|			THEN &RequestTextTemplateFromPartnerCard
		|		WHEN ISNULL(DocumentReferenceOrder.CarrierPartner.LabelsTemplate, VALUE(Catalog.LabelAndPriceTagTemplates.EmptyRef)) <> VALUE(Catalog.LabelAndPriceTagTemplates.EmptyRef)
		|			THEN DocumentReferenceOrder.CarrierPartner.LabelsTemplate
		|		ELSE &ShippingLabelTemplate
		|	END AS LabelsTemplate
		|,&QueryTextTSName
		|FROM
		|	TextNameDocumentHeader AS DocumentReferenceOrder
		|		INNER JOIN TextNameTSGoods AS DocumentOrderGoods
		|		ON &TextOfItchHeaderConnectionCondition
		|WHERE
		|	DocumentReferenceOrder.Ref IN(&CommandParameter)
		|
		|GROUP BY
		|	DocumentReferenceOrder.Ref,
		|	DocumentReferenceOrder.CarrierPartner,
		|	CASE
		|		WHEN (DocumentReferenceOrder.DeliveryMethod = VALUE(Enum.TransportMethods.SelfPickup)
		|				OR DocumentReferenceOrder.DeliveryMethod = VALUE(Enum.TransportMethods.ToCustomer))
		|				AND ISNULL(&RequestTextTemplateFromPartnerCard, VALUE(Catalog.LabelAndPriceTagTemplates.EmptyRef)) <> VALUE(Catalog.LabelAndPriceTagTemplates.EmptyRef)
		|			THEN &RequestTextTemplateFromPartnerCard
		|		WHEN ISNULL(DocumentReferenceOrder.CarrierPartner.LabelsTemplate, VALUE(Catalog.LabelAndPriceTagTemplates.EmptyRef)) <> VALUE(Catalog.LabelAndPriceTagTemplates.EmptyRef)
		|			THEN DocumentReferenceOrder.CarrierPartner.LabelsTemplate
		|		ELSE &ShippingLabelTemplate
		|	END";
		
		StructureOfTypes = TMCommonUse.MatchingArraysByObjectType(ObjectsArray);

		ArrayOfTextsForOrders = New Array;
		ThisIsFirstOneType = True;
		
		For Each KeyValue In StructureOfTypes Do
			
			MetadataOfOrders = Metadata.FindByFullName(KeyValue.Key);
			
			QueryText = DataForPrintingDeliveryLabelsToAdaptToOrder(MetadataOfOrders, QueryTextByReference);
			QueryText = StrReplace(QueryText, "&TextOfItchHeaderConnectionCondition", "(DocumentOrderGoods.Ref = DocumentReferenceOrder.Ref)");
			
			If ThisIsFirstOneType Then
				QueryText = StrReplace(QueryText, ",&QueryTextTSName", "INTO TTOrdersAndTemplates");
				ThisIsFirstOneType = False;
			Else
				QueryText = StrReplace(QueryText, ",&QueryTextTSName", "");
			EndIf;
			
			ArrayOfTextsForOrders.Add(QueryText);
			If MetadataOfOrders = Metadata.Documents.SubcontractOrder2_5
			 Or False Then
				
				QueryText = StrReplace(QueryTextByReference, "TextNameTSGoods", "Document.ProductionStage2_2.SupplyWithMaterialsAndWorks");
				QueryText = StrReplace(QueryText, ",&QueryTextTSName", "");
				QueryText = StrReplace(QueryText, "&TextOfItchHeaderConnectionCondition",
					"(DocumentOrderGoods.Ref.SubcontractOrder = DocumentReferenceOrder.Ref AND NOT DocumentOrderGoods.Canceled)");
				
				QueryText = DataForPrintingDeliveryLabelsToAdaptToOrder(MetadataOfOrders, QueryText);
				
				ArrayOfTextsForOrders.Add(QueryText);
			EndIf;
		EndDo;
		
		QueryTextTTOrdersAndTemplates = StrConcat(ArrayOfTextsForOrders, TMCommonUse.QuerySeparatorInJoin());
		
		ArrayOfRequestTexts.Add(QueryTextTTOrdersAndTemplates);
		
	EndIf;
	
	TextOfDataSelectionRequests =
	"SELECT
	|	TTOrdersAndTemplates.ReferenceOrder AS ReferenceOrder,
	|	TTOrdersAndTemplates.InvoiceWeight AS InvoiceWeight,
	|	TTOrdersAndTemplates.InvoiceVolume AS InvoiceVolume,
	|	TTOrdersAndTemplates.NumberOfRows AS NumberOfRows,
	|	TTOrdersAndTemplates.LabelsTemplate AS LabelsTemplate,
	|	&UnitOfMeasureForWeight AS UnitOfMeasureForWeight,
	|	&UnitOfMeasureForVolume AS UnitOfMeasureForVolume
	|FROM
	|	TTOrdersAndTemplates AS TTOrdersAndTemplates
	|WHERE
	|	TTOrdersAndTemplates.LabelsTemplate <> VALUE(Catalog.LabelAndPriceTagTemplates.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTOrdersAndTemplates.ReferenceOrder AS Ref,
	|	TTOrdersAndTemplates.Carrier AS Carrier
	|FROM
	|	TTOrdersAndTemplates AS TTOrdersAndTemplates
	|WHERE
	|	TTOrdersAndTemplates.LabelsTemplate = VALUE(Catalog.LabelAndPriceTagTemplates.EmptyRef)";
		
	ArrayOfRequestTexts.Add(TextOfDataSelectionRequests);
	QueryText = StrConcat(ArrayOfRequestTexts, Common.QueryBatchSeparator());
	
	Query.Text = QueryText;
	Query.SetParameter("ShippingLabelTemplate", Constants.LabelTemplateForDelivery.Get());
	Query.SetParameter("UnitOfMeasureForWeight", Constants.UnitOfMeasureForWeight.Get());
	Query.SetParameter("UnitOfMeasureForVolume", Constants.UnitOfMeasureForVolume.Get());
	
	Query.SetParameter("CommandParameter", ObjectsArray);
	QueryResult = Query.ExecuteBatch();
	
	DeliveryTable			= QueryResult[QueryResult.UBound() - 1].Unload();
	ErrorsTable			= QueryResult[QueryResult.UBound()].Unload();
	
	If TypeOf(CurrentObject)	= Type("DocumentRef.TransportationJob")  Then
		TasksWithoutOrders	= QueryResult[QueryResult.UBound() - 2].Unload();
		DeliveryToOurWarehouse		= Common.ObjectAttributeValue(CurrentObject, "Operation") = PredefinedValue("Enum.DeliveryKinds.ToWarehouse");
	Else
		TasksWithoutOrders	= Undefined;
		DeliveryToOurWarehouse		= False;
	EndIf;
	
	ReturnStructure = New Structure;
	ReturnStructure.Insert("ArrayOfLinksWithErrors",ErrorsTable.UnloadColumn("Ref"));
	ReturnStructure.Insert("DeliveryToOurWarehouse",DeliveryToOurWarehouse);
	
	ErrorsTable.GroupBy("Carrier");
	ReturnStructure.Insert("ArrayOfCarriersWithoutLabelTemplates",ErrorsTable.UnloadColumn("Carrier"));
	
	ThereAreLabelsToPrint = DeliveryTable.Count() > 0;
	ReturnStructure.Insert("ThereAreLabelsToPrint",ThereAreLabelsToPrint);
	
	If ThereAreLabelsToPrint Then
		ReturnStructure.Insert("AddressInStorage",PutToTempStorage(DeliveryTable, New UUID));
	EndIf;
	
	If TasksWithoutOrders <> Undefined
		And TasksWithoutOrders.Count() > 0 Then
		
		ReturnStructure.Insert("ArrayOfTasksWithoutOrders", TasksWithoutOrders.UnloadColumn("Ref"));
		
	EndIf;
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
	Return ReturnStructure;
	
EndFunction

Function DataForPrintingDeliveryLabelsToAdaptToOrder(MetadataOfOrders, QueryTextByReference)
	
	NamesOfTSGoods = New Map;
	NamesOfTSGoods.Insert(Metadata.Documents.RequestForReturnOfGoodsFromCustomer,"SubstituteGoods");
	NamesOfTSGoods.Insert(Metadata.Documents.MaterialProviderOrder2_5,"ManufacturedProduct");
	NamesOfTSGoods.Insert(Metadata.Documents.SubcontractOrder2_5, "SupplyWithMaterialsAndWorks");
	If MetadataOfOrders.TabularSections.Find("Goods") <> Undefined Then
		NameTSGoods = "Goods";
	Else
		NameTSGoods = NamesOfTSGoods.Get(MetadataOfOrders);
		
		If NameTSGoods = Undefined Then
			ExceptionText = NStr("vi = 'Đối với loại %TypeOfOrder_% của đơn hàng giao hàng, truy vấn cho việc lựa chọn dữ liệu phân bổ không được xác định.';
								|ru = 'Для типа %TypeOfOrder_% распоряжения на доставку не определен запрос выборки данных доставки.';
								|en = 'Request for delivery data selection is not defined for delivery reference type %TypeOfOrder_%.'; fa = 'Request for delivery data selection is not defined for delivery reference type %TypeOfOrder_%.';
								|it = 'Per il tipo %TypeOfOrder_% della disposizione di consegna la richiesta di recupero dei dati di consegna non è definita.';
								|pl = 'Dla rodzaju %TypeOfOrder_% zamówienia na dostawę nie jest zdefiniowany zapotrzebowanie wyboru danych dostawy.';
								|tr = 'Teslimat emrinin %TypeOfOrder_% türünün tanımlanmış bir teslimat verisi örnekleme talebi yoktur.'");
			ExceptionText = StrReplace(ExceptionText, "%TypeOfOrder_%", MetadataOfOrders.FullName());
			Raise ExceptionText;
		EndIf;
		
	EndIf;
	
	QueryText = StrReplace(QueryTextByReference, "TextNameTSGoods", MetadataOfOrders.FullName() + "." + NameTSGoods);
	
	If MetadataOfOrders.TabularSections[NameTSGoods].Attributes.Find("Warehouse") <> Undefined Then
		QueryText = StrReplace(QueryText, "&TextOfConnectionToWarehouseOrder",
		"InstructionsForTask.Warehouse = DocumentOrderGoods.Warehouse");
	Else
		QueryText = StrReplace(QueryText, "&TextOfConnectionToWarehouseOrder",
		"TRUE");
	EndIf;
	
	QueryText = StrReplace(QueryText, "TextNameDocumentHeader", MetadataOfOrders.FullName());
	
	If MetadataOfOrders.Attributes.Find("Partner") <> Undefined Then
		QueryText = StrReplace(QueryText, "&RequestTextTemplateFromPartnerCard",
		"DocumentReferenceOrder.Partner.LabelsTemplate");
	Else
		QueryText = StrReplace(QueryText, "&RequestTextTemplateFromPartnerCard",
		"NULL");
	EndIf;
	
	QueryText = StrReplace(
		QueryText, 
		"&QueryTextItemWeight", 
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight("DocumentOrderGoods.Products.UnitOfMeasure", "DocumentOrderGoods.Products"));

	QueryText = StrReplace(
		QueryText, 
		"&QueryTextTheVolumeOfTheItem", 
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume("DocumentOrderGoods.Products.UnitOfMeasure", "DocumentOrderGoods.Products"));

	QueryText = StrReplace(
		QueryText, 
		"&QueryTextPackageWeight", 
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight("DocumentOrderGoods.Package", "DocumentOrderGoods.Products"));

	QueryText = StrReplace(
		QueryText, 
		"&QueryTextPackageVolume", 
					Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume("DocumentOrderGoods.Package", "DocumentOrderGoods.Products"));
	
	Return QueryText;

EndFunction

Function LabelPrintingDataPackingSheets(PrintObjects) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	
	If TypeOf(PrintObjects[0]) = Type("DocumentRef.GoodsIssueNote") Then
		Query.Text =
		"SELECT
		|	SpendingOrderForGoodsShippedGoods.PackingList AS Ref,
		|	SpendingOrderForGoodsShippedGoods.PackingList.Code AS Barcode
		|FROM
		|	Document.GoodsIssueNote.ShippedGoods AS SpendingOrderForGoodsShippedGoods
		|WHERE
		|	SpendingOrderForGoodsShippedGoods.ThisIsAPackingList
		|	AND SpendingOrderForGoodsShippedGoods.Ref IN(&PrintObjects)";
	ElsIf TypeOf(PrintObjects[0]) = Type("DocumentRef.PackingList") Then
		Query.Text =
		"SELECT
		|	PackingList.Ref,
		|	PackingList.Code AS Barcode
		|FROM
		|	Document.PackingList AS PackingList
		|WHERE
		|	PackingList.Ref IN(&PrintObjects)";
	Else 
		Return New Structure ("ThereIsLabelTemplate",False);
	EndIf; 
	
	Query.SetParameter("PrintObjects",PrintObjects);
	PackingListTable = Query.Execute().Unload();
	ThereAreLabelsToPrint = PackingListTable.Count() > 0;
	LabelsTemplate = Constants.PackingListLabelTemplate.Get();
	ThereIsLabelTemplate = ValueIsFilled(LabelsTemplate);
		
	ReturnStructure = New Structure;
	ReturnStructure.Insert("ThereIsLabelTemplate",    ThereIsLabelTemplate);
	ReturnStructure.Insert("LabelsTemplate",        LabelsTemplate);
	ReturnStructure.Insert("ThereAreLabelsToPrint", ThereAreLabelsToPrint);
	If ThereAreLabelsToPrint Then
		ReturnStructure.Insert("AddressInStorage",   PutToTempStorage(PackingListTable, New UUID));
	EndIf;
	
	Return ReturnStructure;
	
EndFunction

Function ReplaceSpecialCharacters(Val IncomingString)
	
	Var Result;
	
	Result = StrReplace(IncomingString, ".", "");
	Result = StrReplace(Result, " ", "");
	Result = StrReplace(Result, "[", "_");
	Result = StrReplace(Result, "]", "_");
	Result = StrReplace(Result, "(", "_");
	Result = StrReplace(Result, ")", "_");
	Result = StrReplace(Result, "*", "_");
	Result = StrReplace(Result, "-", "_");
	Result = StrReplace(Result, "+", "_");
	Result = StrReplace(Result, "/", "_");
	Result = StrReplace(Result, "@", "_");
	Result = StrReplace(Result, "#", "_");
	Result = StrReplace(Result, "$", "_");
	Result = StrReplace(Result, "%", "_");
	Result = StrReplace(Result, "^", "_");
	Result = StrReplace(Result, "&", "_");
	Result = StrReplace(Result, "*", "_");
	Result = StrReplace(Result, ">", "_");
	Result = StrReplace(Result, "<", "_");
	Result = StrReplace(Result, "?", "_");
	Result = StrReplace(Result, ",", "_");
	
	Return Result;

EndFunction

#EndRegion

#EndRegion

#EndIf
