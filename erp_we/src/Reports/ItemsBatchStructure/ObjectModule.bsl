#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - See ReportsClientServer.GetDefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	
	Settings.Events.BeforeLoadVariantAtServer = True;
	
EndProcedure

// Called in the report form handler of the same name after executing the form code.
//
// Parameters:
//   Form - ClientApplicationForm - report form or report settings.
//   NewDCSettings - DataCompositionSettings - settings to upload to the settings Builder.
//
Procedure BeforeLoadVariantAtServer(Form, NewDCSettings) Export
	
	FormSettingsComposer = Form.Report.SettingsComposer; // DataCompositionSettingsComposer - 
	
	If Not GetFunctionalOption("UseProduction") Then
		SearchValue = New DataCompositionParameter("Products");
		For Each ParameterItem In FormSettingsComposer.Settings.DataParameters.Items Do
			If ParameterItem.Parameter = SearchValue Then
				ParameterItem.UserSettingPresentation = NStr("vi = 'Bộ sản phẩm';
															|ru = 'Комплект';
															|en = 'Kit'; fa = 'کیت';
															|it = 'Kit';
															|pl = 'Kit';
															|tr = 'Küme'");
				Break;
			EndIf;
		EndDo;
		For Each ParameterItem In NewDCSettings.DataParameters.Items Do
			If ParameterItem.Parameter = SearchValue Then
				ParameterItem.UserSettingPresentation = NStr("vi = 'Bộ sản phẩm';
															|ru = 'Комплект';
															|en = 'Kit'; fa = 'کیت';
															|it = 'Kit';
															|pl = 'Kit';
															|tr = 'Küme'");
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	NewDCSettings = FormSettingsComposer.Settings;

EndProcedure

#EndRegion

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	MainCircuitSettings = SettingsComposer.GetSettings();
	
	FilterProducts = DataCompositionClientServer.GetParameter(MainCircuitSettings, "Products").Value;
	FilterSeries = DataCompositionClientServer.GetParameter(MainCircuitSettings, "Series").Value;
	
	If Not ValueIsFilled(FilterProducts) Then
		If GetFunctionalOption("UseProduction") Then
			MessageText = NStr("vi = 'Chưa điền trường ""Thành phẩm hoặc bán thành phẩm"".';
								|ru = 'Поле ""Продукция или полуфабрикат"" не заполнено.';
								|en = '""Product or semi-finished product"" is not filled in.'; fa = '""Product or semi-finished product"" is not filled in.';
								|it = 'Il campo ""Prodotto o semilavorato"" non è compilato.';
								|pl = 'Pole ""Wiersze pozycji lub półprodukt"" nie jest wypełnione.';
								|tr = '""İmal Edilen Ürünler veya Yarı Mamul Ürün"" alanı doldurulmadı.'");
		Else
			MessageText = NStr("vi = 'Chưa điền trường ""Bộ sản phẩm"".';
								|ru = 'Поле ""Комплект"" не заполнено.';
								|en = '""Kit"" is not filled in.'; fa = '""Kit"" is not filled in.';
								|it = 'Il campo ""Kit"" non è completato.';
								|pl = 'Pole ""Komplet"" nie jest wypełnione.';
								|tr = '""Küme"" alanı doldurulmadı.'");
		EndIf; 
		CommonClientServer.MessageToUser(MessageText,,,, Cancel); 
	EndIf;
	If Not ValueIsFilled(FilterSeries) Then
		MessageText = NStr("vi = 'Chưa điền trường ""Sê-ri"".';
							|ru = 'Поле ""Серия"" не заполнено.';
							|en = '""Batch"" is not filled in.'; fa = '""Batch"" is not filled in.';
							|it = 'Il campo ""Serie"" non è compilato.';
							|pl = 'Pole ""Seria"" nie jest wypełnione.';
							|tr = '""Parti"" alanı doldurulmadı.'");
		CommonClientServer.MessageToUser(MessageText,,,, Cancel); 
	EndIf;
	
EndProcedure

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	UseProduction = GetFunctionalOption("UseProduction");
	ReportSettings = SettingsComposer.GetSettings();
	
	// Data preparation
	ReportParameters = New Structure;
	ReportParameters.Insert("Products", DataCompositionClientServer.GetParameter(ReportSettings, "Products").Value);
	ReportParameters.Insert("Characteristic", DataCompositionClientServer.GetParameter(ReportSettings, "Characteristic").Value);
	ReportParameters.Insert("Series", DataCompositionClientServer.GetParameter(ReportSettings, "Series").Value);
	
	RowLimitExceeded = False;
	TreeSeriesStructure = ItemsBatchStructure(ReportParameters, RowLimitExceeded);
	
	For Each TreeRow In TreeSeriesStructure.Rows Do
		
		TreeRow.ParentID = "";
		TreeRow.ItemID = New UUID;
		ToFillInServiceFields(TreeRow.Rows, TreeRow.ItemID);
	
	EndDo;
	
	ExternalSets = New Structure;
	ExternalSets.Insert("SeriesStructure", TreeSeriesStructure);
	
	// Report design
	AreaParameters_ = New Structure;
	If UseProduction Then
		AreaParameters_.Insert("TextMaterial", NStr("vi = 'Bán thành phẩm hoặc nguyên vật liệu';
													|ru = 'Полуфабрикат или материал';
													|en = 'Semi-finished product or material'; fa = 'محصول نیمه‌ساخته یا ماده';
													|it = 'Semilavorato o materiali';
													|pl = 'Półprodukt lub materiał';
													|tr = 'Yarı mamul ürün veya malzeme'", Common.DefaultLanguageCode()));
		AreaParameters_.Insert("TextConsumed", NStr("vi = 'Đã dùng';
													|ru = 'Израсходовано';
													|en = 'Spent'; fa = 'مصرف‌شده';
													|it = 'Speso';
													|pl = 'Spent';
													|tr = 'Sarf edildi'", Common.DefaultLanguageCode()));
	Else
		AreaParameters_.Insert("TextMaterial", NStr("vi = 'Thành phần chi tiết';
													|ru = 'Комплектующая';
													|en = 'Component'; fa = 'Component';
													|it = 'Kit';
													|pl = 'Component';
													|tr = 'Bileşen'", Common.DefaultLanguageCode()));
		AreaParameters_.Insert("TextConsumed", NStr("vi = 'Đã dùng';
													|ru = 'Израсходовано';
													|en = 'Spent'; fa = 'مصرف‌شده';
													|it = 'Speso';
													|pl = 'Spent';
													|tr = 'Sarf edildi'", Common.DefaultLanguageCode()));
	EndIf;
	
	DatasetFields = DataCompositionSchema.DataSets.SeriesStructure.Fields; // DataCompositionSchemaDataSetFields
	ProductsField = DatasetFields.Find("Products");
	FieldIsUsedUp = DatasetFields.Find("Spent");
	
	If ProductsField <> Undefined Then
		ProductsField.Title = AreaParameters_.TextMaterial;
	EndIf;
	
	If FieldIsUsedUp <> Undefined Then
		FieldIsUsedUp.Title = AreaParameters_.TextConsumed;
	EndIf;
	
	// Report generation
	DetailsData = New DataCompositionDetailsData;

	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);

	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, ExternalSets, DetailsData, True);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
EndProcedure

#EndRegion

#Region Private

Function ItemsBatchStructure(Parameters, RowLimitExceeded)
	
	ProductSeriesStructureTree = New ValueTree;
	ProductSeriesStructureTree.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	ProductSeriesStructureTree.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	ProductSeriesStructureTree.Columns.Add("Series", New TypeDescription("CatalogRef.ItemsBatches"));
	ProductSeriesStructureTree.Columns.Add("Spent", New TypeDescription("Number"));
	ProductSeriesStructureTree.Columns.Add("UnitOfMeasure", New TypeDescription("String"));
	ProductSeriesStructureTree.Columns.Add("ProductsPresentation", New TypeDescription("String"));
	ProductSeriesStructureTree.Columns.Add("SeriesPresentation", New TypeDescription("String"));
	
	TypesArray = New Array;
	TypesArray.Add(New TypeDescription("UUID"));
	TypesArray.Add(New TypeDescription("String"));
	
	ProductSeriesStructureTree.Columns.Add("ItemID", New TypeDescription(TypesArray));
	ProductSeriesStructureTree.Columns.Add("ParentID", New TypeDescription(TypesArray));
	
	SeriesStructureCollection = ProductSeriesStructureTree.Rows;
	
	ItemList = New ValueTable; // See ProductionServer.ServiceStructureOfValueTable
	ItemList.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	ItemList.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	ItemList.Columns.Add("Series", New TypeDescription("CatalogRef.ItemsBatches"));
	ItemList.Columns.Add("Rows");
	
	NewRow = ItemList.Add();
	FillPropertyValues(NewRow, Parameters);
	NewRow.Rows = SeriesStructureCollection;
	
	FilterByItemVariant = ValueIsFilled(Parameters.Characteristic);
	
	SetPrivilegedMode(True);
	
	TheStructureOfTheSearch = New Structure("ListProducts_, ListCharacteristics, ListSeries");
	RowsCount = 0;
	RowLimit = RowLimit();
	
	While ItemList.Count() <> 0 Do
		
		NewListOfProducts = ItemList.CopyColumns();
		
		UsedSeries = UsedSeries(ItemList, FilterByItemVariant);
		UsedSeries.Indexes.Add("ListProducts_, ListCharacteristics, ListSeries");
		
		If Not FilterByItemVariant Then
			
			FilterByItemVariant = True;
			
			ItemList.Clear();
			
			Columns = "ListProducts_, ListCharacteristics, ListSeries";
			UsedSeriesCopy = UsedSeries.Copy(, Columns);
			UsedSeriesCopy.GroupBy(Columns);
			
			For Each String In UsedSeriesCopy Do
				
				NewRow = ItemList.Add();
				NewRow.Products = String.ListProducts_;
				NewRow.Characteristic = String.ListCharacteristics;
				NewRow.Series = String.ListSeries;
				NewRow.Rows = SeriesStructureCollection;
				
			EndDo;
			
		EndIf;
		
		For Each StringProducts_ In ItemList Do
			
			TheStructureOfTheSearch.ListProducts_ = StringProducts_.Products;
			TheStructureOfTheSearch.ListCharacteristics = StringProducts_.Characteristic;
			TheStructureOfTheSearch.ListSeries = StringProducts_.Series;
			
			For Each StringSeriesOfMaterial In UsedSeries.FindRows(TheStructureOfTheSearch) Do
				
				RowsCount = RowsCount + 1;
				If RowsCount > RowLimit Then
					RowLimitExceeded = True;
					Break;
				EndIf;
				
				NewSeries_ = StringProducts_.Rows.Add();
				FillPropertyValues(NewSeries_, StringSeriesOfMaterial);
				NewSeries_.ProductsPresentation = ProductsClientServer.ProductPresentation(
					StringSeriesOfMaterial.ProductsPresentation,
					StringSeriesOfMaterial.CharacteristicPresentation);
					
				If ValueIsFilled(NewSeries_.Series) Then
					
					// Loop control
					HasLoop = False;
					
					Parent = NewSeries_.Parent;
					While Parent <> Undefined Do
						If Parent.Products = NewSeries_.Products
								And Parent.Characteristic = NewSeries_.Characteristic
								And Parent.Series = NewSeries_.Series Then
							HasLoop = True;
							Break;
						EndIf;
						Parent = Parent.Parent;
					EndDo;
					
					If Not HasLoop Then
						NewNomenclature = NewListOfProducts.Add();
						FillPropertyValues(NewNomenclature, NewSeries_);
						NewNomenclature.Rows = NewSeries_.Rows;
					EndIf;
					
				EndIf;
				
			EndDo; 
			If RowsCount > RowLimit Then
				Break;
			EndIf;
		EndDo;
		
		If RowsCount > RowLimit Then
			Break;
		EndIf;
		
		ItemList = NewListOfProducts.Copy();
		
	EndDo; 
	
	Return ProductSeriesStructureTree;
	
EndFunction

Function UsedSeries(ItemList, FilterByItemVariant)

	QueryTexts = New Array;
	
	#Region ItemList
	
	QueryTexts.Add(
	"SELECT
	|	CAST(ItemList.Products AS Catalog.Products) AS Products,
	|	CAST(ItemList.Characteristic AS Catalog.ItemsCharacteristics) AS Characteristic,
	|	CAST(ItemList.Series AS Catalog.ItemsBatches) AS Series
	|INTO ItemList
	|FROM
	|	&ItemList AS ItemList
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Series");
	
	#EndRegion
	


	#Region ReceiptOfSeriesInProduction22
	
	QueryTexts.Add(
	// production of products in the pantry
	"SELECT ALLOWED DISTINCT
	|	GoodsTable.Products   AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Series          AS Series,
	|	CatProductionLots.Ref AS ProductionLot
	|INTO ReceiptOfSeriesInProductionWithoutOrder
	|FROM
	|	Document.BackflushProduction.ManufacturedProducts AS GoodsTable
	|	
	|	INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|	ON CatProductionLots.Document = GoodsTable.Ref
	|	AND CatProductionLots.Code = GoodsTable.CostGroupNumber
	|	AND NOT CatProductionLots.DeletionMark
	|
	|WHERE
	|	GoodsTable.Ref.Posted
	|	AND VALUETYPE(GoodsTable.Recipient) = TYPE(Catalog.Warehouses)
	|	AND NOT GoodsTable.Recipient = VALUE(Catalog.Warehouses.EmptyRef)
	|	AND NOT GoodsTable.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|	AND &SelectionAccordingToListOfItemsTable
	|
	|UNION ALL
	|
	// production of products in the pantry
	|SELECT
	|	GoodsTable.Products   AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Series          AS Series,
	|	CatProductionLots.Ref AS ProductionLot
	|FROM
	|	Document.BackflushProduction.BatchFinishedProducts AS GoodsTable
	|	
	|	INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|	ON CatProductionLots.Document = GoodsTable.Ref
	|	AND CatProductionLots.Code = GoodsTable.CostGroupNumber
	|	AND NOT CatProductionLots.DeletionMark
	|
	|WHERE
	|	GoodsTable.Ref.Posted
	|	AND VALUETYPE(GoodsTable.Recipient) = TYPE(Catalog.Warehouses)
	|	AND NOT GoodsTable.Recipient = VALUE(Catalog.Warehouses.EmptyRef)
	|	AND &SelectionAccordingToListOfItemsTable
	|
	|UNION ALL
	|
	// production of returnable waste to the pantry
	|SELECT
	|	GoodsTable.Products   AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Series          AS Series,
	|	CatProductionLots.Ref AS ProductionLot
	|FROM
	|	Document.BackflushProduction.SideAndIntermediateRelease AS GoodsTable
	|	
	|	INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|	ON CatProductionLots.Document = GoodsTable.Ref
	|	AND CatProductionLots.Code = GoodsTable.CostGroupNumber
	|	AND NOT CatProductionLots.DeletionMark
	|
	|WHERE
	|	GoodsTable.Ref.Posted
	|	AND VALUETYPE(GoodsTable.Recipient) = TYPE(Catalog.Warehouses)
	|	AND NOT GoodsTable.Recipient = VALUE(Catalog.Warehouses.EmptyRef)
	|	AND NOT GoodsTable.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|	AND &SelectionAccordingToListOfItemsTable
	|
	|UNION ALL
	|
	// production of returnable waste to the pantry
	|SELECT
	|	GoodsTable.Products   AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Series          AS Series,
	|	CatProductionLots.Ref AS ProductionLot
	|FROM
	|	Document.BackflushProduction.BatchSideAndIntermediateRelease AS GoodsTable
	|	
	|	INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|	ON CatProductionLots.Document = GoodsTable.Ref
	|	AND CatProductionLots.Code = GoodsTable.CostGroupNumber
	|	AND NOT CatProductionLots.DeletionMark
	|
	|WHERE
	|	GoodsTable.Ref.Posted
	|	AND VALUETYPE(GoodsTable.Recipient) = TYPE(Catalog.Warehouses)
	|	AND NOT GoodsTable.Recipient = VALUE(Catalog.Warehouses.EmptyRef)
	|	AND &SelectionAccordingToListOfItemsTable
	|
	|INDEX BY
	|	ProductionLot
	|");
	QueryTexts.Add(
	"SELECT ALLOWED DISTINCT
	|	SeriesMovement.Products AS Products,
	|	SeriesMovement.Characteristic AS Characteristic,
	|	SeriesMovement.Series AS Series,
	|	CAST(SeriesMovement.Document AS Document.ProductionStage2_2).ProductionLot AS ProductionLot
	|INTO ReceiptOfSeriesInStagesOfProduction
	|FROM
	|	AccumulationRegister.GoodsBatchMovement.Turnovers(
	|			,
	|			,
	|			,
	|			&SelectionAccordingToListOfProducts
	|				AND WarehouseOperation = VALUE(Enum.WarehouseTransactions.ManufactureOfProducts)
	|				AND Document REFS Document.ProductionStage2_2) AS SeriesMovement
	|
	|INDEX BY
	|	ProductionLot");
	#EndRegion
	
	#Region ReceiptOfSeriesDuringProductionOnSide
	
	QueryTexts.Add(
	"SELECT ALLOWED DISTINCT
	|	GoodsTable.Products   AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Series          AS Series,
	|	CatProductionLots.Ref AS ProductionLot
	|INTO ReceiptOfSeriesDuringProductionOnSide
	|FROM
	|	Document.SubcontractorReport2_5.ManufacturedProducts AS GoodsTable
	|	
	|	INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|	ON CatProductionLots.Document = GoodsTable.Ref
	|	AND CatProductionLots.Code = GoodsTable.CostGroupNumber
	|	AND NOT CatProductionLots.DeletionMark
	|
	|WHERE
	|	GoodsTable.Ref.Posted
	|	AND GoodsTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|	AND &SelectionAccordingToListOfItemsTable
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.Products   AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Series          AS Series,
	|	CatProductionLots.Ref AS ProductionLot
	|FROM
	|	Document.SubcontractorReport2_5.SideAndIntermediateRelease AS GoodsTable
	|	
	|	INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|	ON CatProductionLots.Document = GoodsTable.Ref
	|	AND CatProductionLots.Code = GoodsTable.CostGroupNumber
	|	AND NOT CatProductionLots.DeletionMark
	|
	|WHERE
	|	GoodsTable.Ref.Posted
	|	AND GoodsTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|	AND &SelectionAccordingToListOfItemsTable
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.Products     AS Products,
	|	GoodsTable.Characteristic   AS Characteristic,
	|	GoodsTable.Series            AS Series,
	|	Data_Stage.ProductionLot AS ProductionLot
	|FROM
	|	Document.SubcontractorReport2_5.ManufacturedProducts AS GoodsTable
	|	
	|	INNER JOIN Document.ProductionStage2_2 AS Data_Stage
	|	ON GoodsTable.ProductionStage = Data_Stage.Ref
	|
	|WHERE
	|	GoodsTable.Ref.Posted
	|	AND GoodsTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|	AND &SelectionAccordingToListOfItemsTable
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.Products     AS Products,
	|	GoodsTable.Characteristic   AS Characteristic,
	|	GoodsTable.Series            AS Series,
	|	Data_Stage.ProductionLot AS ProductionLot
	|FROM
	|	Document.SubcontractorReport2_5.SideAndIntermediateRelease AS GoodsTable
	|	
	|	INNER JOIN Document.ProductionStage2_2 AS Data_Stage
	|	ON GoodsTable.ProductionStage = Data_Stage.Ref
	|
	|WHERE
	|	GoodsTable.Ref.Posted
	|	AND GoodsTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|	AND &SelectionAccordingToListOfItemsTable
	|
	|INDEX BY
	|	ProductionLot
	|");
	
	#EndRegion
	#Region DocumentsOfReceiptOfSeriesInProduction22
	
	QueryTexts.Add(
	"SELECT
	|	ProductionStage2_2.Ref AS Ref
	|INTO ProductionStages
	|FROM
	|	Document.ProductionStage2_2 AS ProductionStage2_2
	|WHERE
	|	ProductionStage2_2.ProductionLot IN
	|			(SELECT
	|				ReceiptOfSeries.ProductionLot
	|			FROM
	|				ReceiptOfSeriesInStagesOfProduction AS ReceiptOfSeries)
	|	AND ProductionStage2_2.Posted
	|
	|INDEX BY
	|	Ref
	|;
	|SELECT DISTINCT
	|	Table.ProductionLot AS ProductionLot,
	|	Table.Products         AS Products,
	|	Table.Characteristic       AS Characteristic
	|INTO StageRelease
	|FROM
	|	(SELECT
	|		ManufacturedProducts.Ref.ProductionLot AS ProductionLot,
	|		ManufacturedProducts.Products              AS Products,
	|		ManufacturedProducts.Characteristic            AS Characteristic
	|	FROM
	|		Document.ProductionStage2_2.ManufacturedProducts AS ManufacturedProducts
	|	WHERE
	|		ManufacturedProducts.Ref IN
	|				(SELECT
	|					ProductionStages.Ref
	|				FROM
	|					ProductionStages)
	|		AND ManufacturedProducts.Ref.ProductionLot = ManufacturedProducts.StageConsumer.ProductionLot
	|		AND NOT ManufacturedProducts.Canceled
	|
	|	UNION ALL
	|
	|	SELECT
	|		SideAndIntermediateRelease.Ref.ProductionLot AS ProductionLot,
	|		SideAndIntermediateRelease.Products              AS Products,
	|		SideAndIntermediateRelease.Characteristic            AS Characteristic
	|	FROM
	|		Document.ProductionStage2_2.SideAndIntermediateRelease AS SideAndIntermediateRelease
	|	WHERE
	|		SideAndIntermediateRelease.Ref IN
	|				(SELECT
	|					ProductionStages.Ref
	|				FROM
	|					ProductionStages)
	|		AND SideAndIntermediateRelease.Ref.ProductionLot = SideAndIntermediateRelease.StageConsumer.ProductionLot
	|		AND NOT SideAndIntermediateRelease.Canceled
	|	
	|) AS Table
	|
	|INDEX BY
	|	ProductionLot,
	|	Products,
	|	Characteristic
	|");
	
	#EndRegion
	#Region ReceiptOfSeriesDuringAssembly_
	
	QueryTexts.Add(
	"SELECT ALLOWED
	|	SeriesMovement.Products AS Products,
	|	SeriesMovement.Characteristic AS Characteristic,
	|	SeriesMovement.Series AS Series,
	|	CAST(SeriesMovement.Document AS Document.AssemblyFromComponents) AS Document,
	|	SeriesMovement.CountTurnover AS Count
	|INTO ReceiptOfAssemblySeries
	|FROM
	|	AccumulationRegister.GoodsBatchMovement.Turnovers(
	|			,
	|			,
	|			,
	|			&SelectionAccordingToListOfProducts
	|				AND WarehouseOperation IN (VALUE(Enum.WarehouseTransactions.ReceivingOfAssembledSets),
	|										VALUE(Enum.WarehouseTransactions.ReceivingOfComponentsAfterDisassembly))) AS SeriesMovement
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Series,
	|	Document");
	
	#EndRegion
	
	#Region SeriesConsumption
	
	QueryTexts.Add(
	"SELECT ALLOWED
	|	NestedQuery.ListProducts_ AS ListProducts_,
	|	NestedQuery.ListCharacteristics AS ListCharacteristics, 
	|	NestedQuery.ListSeries AS ListSeries,
	|	NestedQuery.Products AS Products,
	|	NestedQuery.Products.Presentation AS ProductsPresentation,
	|	NestedQuery.Products.UnitOfMeasure AS UnitOfMeasure,
	|	NestedQuery.Characteristic AS Characteristic,
	|	NestedQuery.Characteristic.Presentation AS CharacteristicPresentation,
	|	NestedQuery.Series AS Series,
	|	NestedQuery.Series.Presentation AS SeriesPresentation,
	|	SUM(NestedQuery.Spent) AS Spent
	|FROM
	|(
	|	SELECT
	|		ReceiptOfAssemblySeries.Products AS ListProducts_,
	|		ReceiptOfAssemblySeries.Characteristic AS ListCharacteristics,
	|		ReceiptOfAssemblySeries.Series AS ListSeries,
	|		UsedSeries.Products AS Products,
	|		UsedSeries.Characteristic AS Characteristic,
	|		UsedSeries.Series AS Series,
	|		UsedSeries.CountTurnover AS Spent
	|	FROM
	|			AccumulationRegister.GoodsBatchMovement.Turnovers(
	|				,
	|				,
	|				,
	|				Document IN
	|						(SELECT
	|							ReceiptOfAssemblySeries.Document
	|						FROM
	|							ReceiptOfAssemblySeries)
	|					AND WarehouseOperation IN (VALUE(Enum.WarehouseTransactions.ShipComponentsForAssembly),
	|											VALUE(Enum.WarehouseTransactions.ShipSetsForDisassembly))) AS UsedSeries
	|			LEFT JOIN ReceiptOfAssemblySeries AS ReceiptOfAssemblySeries
	|			ON (ReceiptOfAssemblySeries.Document = UsedSeries.Document)
	|	
	|	UNION ALL
	|
	// Production by order
	|	SELECT
	|		ReceiptOfSeries.Products AS ListProducts_,
	|		ReceiptOfSeries.Characteristic AS ListCharacteristics,
	|		ReceiptOfSeries.Series AS ListSeries,
	|		UsedSeries.Products AS Products,
	|		UsedSeries.Characteristic AS Characteristic,
	|		UsedSeries.Series AS Series,
	|		UsedSeries.CountTurnover AS Spent
	|	FROM
	|		AccumulationRegister.GoodsBatchMovement.Turnovers(
	|				,
	|				,
	|				,
	|				Document IN
	|						(SELECT
	|							ProductionStages.Ref
	|						FROM
	|							ProductionStages AS ProductionStages)
	|					AND WarehouseOperation = VALUE(Enum.WarehouseTransactions.ConsumptionDuringProduction)) AS UsedSeries
	|
	|			LEFT JOIN Document.ProductionStage2_2 AS ProductionStage2_2
	|			ON UsedSeries.Document = ProductionStage2_2.Ref
	|
	|			LEFT JOIN ReceiptOfSeriesInStagesOfProduction AS ReceiptOfSeries
	|			ON ProductionStage2_2.ProductionLot = ReceiptOfSeries.ProductionLot
	|
	|			LEFT JOIN StageRelease AS StageRelease
	|			ON UsedSeries.Products = StageRelease.Products
	|				AND UsedSeries.Characteristic = StageRelease.Characteristic
	|				AND ProductionStage2_2.ProductionLot = StageRelease.ProductionLot
	|
	|	WHERE
	|		StageRelease.Products IS NULL
	|	
	|	UNION ALL
	|
	// Distribution of materials for production by order
	|	SELECT
	|		ReceiptOfSeries.Products AS ListProducts_,
	|		ReceiptOfSeries.Characteristic AS ListCharacteristics,
	|		ReceiptOfSeries.Series AS ListSeries,
	|		UsedSeries.Products AS Products,
	|		UsedSeries.Characteristic AS Characteristic,
	|		UsedSeries.Series AS Series,
	|		UsedSeries.CountTurnover AS Spent
	|	FROM
	|		AccumulationRegister.GoodsBatchMovement.Turnovers(
	|				,
	|				,
	|				,
	|				Document IN
	|					(SELECT
	|						AllocationOfCosts.Ref AS Ref
	|					FROM
	|						ReceiptOfSeriesInStagesOfProduction AS ReceiptOfSeries
	|							INNER JOIN Document.ProductionCostAllocation.ProductionLots AS AllocationOfCosts
	|							ON
	|								ReceiptOfSeries.ProductionLot = AllocationOfCosts.ProductionLot)) AS UsedSeries
	|
	|			LEFT JOIN Document.ProductionCostAllocation.ProductionLots AS AllocationOfCosts
	|			ON UsedSeries.Document = AllocationOfCosts.Ref
	|
	|			LEFT JOIN ReceiptOfSeriesInStagesOfProduction AS ReceiptOfSeries
	|			ON (AllocationOfCosts.ProductionLot = ReceiptOfSeries.ProductionLot)
	|
	|	UNION ALL
	|
	// Production without an order
	|	SELECT
	|		ReceiptOfSeries.Products   AS ListProducts_,
	|		ReceiptOfSeries.Characteristic AS ListCharacteristics,
	|		ReceiptOfSeries.Series          AS ListSeries,
	|		GoodsTable.Products      AS Products,
	|		GoodsTable.Characteristic    AS Characteristic,
	|		GoodsTable.Series             AS Series,
	|		GoodsTable.Count        AS Spent
	|	FROM
	|		Document.BackflushProduction.MaterialsAndWorks AS GoodsTable
	|		
	|		INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Document = GoodsTable.Ref
	|		AND CatProductionLots.Code = GoodsTable.CostGroupNumber
	|		AND NOT CatProductionLots.DeletionMark
	|		
	|		INNER JOIN ReceiptOfSeriesInProductionWithoutOrder AS ReceiptOfSeries
	|		ON ReceiptOfSeries.ProductionLot = CatProductionLots.Ref
	|		
	|	WHERE
	|		VALUETYPE(GoodsTable.Warehouse) = TYPE(Catalog.Warehouses)
	|		AND NOT GoodsTable.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|		AND NOT GoodsTable.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|	
	|	UNION ALL
	|
	// Distribution of materials for production without an order.
	|	SELECT
	|		ReceiptOfSeries.Products             AS ListProducts_,
	|		ReceiptOfSeries.Characteristic           AS ListCharacteristics,
	|		ReceiptOfSeries.Series                    AS ListSeries,
	|		UsedSeries.Ref.Products   AS Products,
	|		UsedSeries.Ref.Characteristic AS Characteristic,
	|		UsedSeries.Ref.Series          AS Series,
	|		UsedSeries.Count            AS Spent
	|	FROM
	|		Document.ProductionCostAllocation.ProductionLots AS UsedSeries
	|		
	|		INNER JOIN ReceiptOfSeriesInProductionWithoutOrder AS ReceiptOfSeries
	|		ON ReceiptOfSeries.ProductionLot = UsedSeries.ProductionLot
	|		
	|	WHERE
	|		NOT UsedSeries.Ref.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|	
	|	UNION ALL
	|	
	// Distribution of materials for production without an order, the series are indicated in a separate tabular part.
	// Due to the lack of compliance of the series with the production batches, all series participate in all production batches.
	|	SELECT
	|		ReceiptOfSeries.Products      AS ListProducts_,
	|		ReceiptOfSeries.Characteristic    AS ListCharacteristics,
	|		ReceiptOfSeries.Series             AS ListSeries,
	|		UsedSeries.Products   AS Products,
	|		UsedSeries.Characteristic AS Characteristic,
	|		UsedSeries.Series          AS Series,
	|		UsedSeries.Count     AS Spent
	|	FROM
	|		Document.ProductionCostAllocation.SetOfSeries AS UsedSeries
	|		
	|		INNER JOIN Document.ProductionCostAllocation.ProductionLots AS DistributionParties
	|		ON DistributionParties.Ref = UsedSeries.Ref
	|		
	|		INNER JOIN ReceiptOfSeriesInProductionWithoutOrder AS ReceiptOfSeries
	|		ON ReceiptOfSeries.ProductionLot = DistributionParties.ProductionLot
	|		
	|	WHERE
	|		NOT UsedSeries.Ref.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|	
	|	UNION ALL
	|	
	// Production on the side
	|	SELECT
	|		ReceiptOfSeries.Products   AS ListProducts_,
	|		ReceiptOfSeries.Characteristic AS ListCharacteristics,
	|		ReceiptOfSeries.Series          AS ListSeries,
	|		GoodsTable.Products      AS Products,
	|		GoodsTable.Characteristic    AS Characteristic,
	|		GoodsTable.Series             AS Series,
	|		GoodsTable.Count        AS Spent
	|	FROM
	|		Document.SubcontractorReport2_5.MaterialsAndWorks AS GoodsTable
	|		
	|		INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Document = GoodsTable.Ref
	|		AND CatProductionLots.Code = GoodsTable.CostGroupNumber
	|		AND NOT CatProductionLots.DeletionMark
	|		
	|		INNER JOIN ReceiptOfSeriesDuringProductionOnSide AS ReceiptOfSeries
	|		ON ReceiptOfSeries.ProductionLot = CatProductionLots.Ref
	|
	|	WHERE
	|		GoodsTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|	
	|	UNION ALL
	|	
	// Production on the side by stages
	|	SELECT
	|		ReceiptOfSeries.Products   AS ListProducts_,
	|		ReceiptOfSeries.Characteristic AS ListCharacteristics,
	|		ReceiptOfSeries.Series          AS ListSeries,
	|		GoodsTable.Products      AS Products,
	|		GoodsTable.Characteristic    AS Characteristic,
	|		GoodsTable.Series             AS Series,
	|		GoodsTable.Count        AS Spent
	|	FROM
	|		Document.SubcontractorReport2_5.MaterialsAndWorks AS GoodsTable
	|		
	|		INNER JOIN Document.ProductionStage2_2 AS Data_Stage
	|		ON GoodsTable.ProductionStage = Data_Stage.Ref
	|		
	|		INNER JOIN ReceiptOfSeriesDuringProductionOnSide AS ReceiptOfSeries
	|		ON ReceiptOfSeries.ProductionLot = Data_Stage.ProductionLot
	|
	|	WHERE
	|		GoodsTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|
	|	UNION ALL
	|
	// Distribution of materials for production on the side
	|	SELECT
	|		ReceiptOfSeries.Products             AS ListProducts_,
	|		ReceiptOfSeries.Characteristic           AS ListCharacteristics,
	|		ReceiptOfSeries.Series                    AS ListSeries,
	|		UsedSeries.Ref.Products   AS Products,
	|		UsedSeries.Ref.Characteristic AS Characteristic,
	|		UsedSeries.Ref.Series          AS Series,
	|		UsedSeries.Count            AS Spent
	|	FROM
	|		Document.ProductionCostAllocation.ProductionLots AS UsedSeries
	|		
	|		INNER JOIN ReceiptOfSeriesDuringProductionOnSide AS ReceiptOfSeries
	|		ON ReceiptOfSeries.ProductionLot = UsedSeries.ProductionLot
	|		
	|	WHERE
	|		NOT UsedSeries.Ref.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|	
	|	UNION ALL
	|	
	// The distribution of materials for production on the side, the series are indicated in a separate tabular part.
	// Due to the lack of compliance of the series with the production batches, all series participate in all production batches.
	|	SELECT
	|		ReceiptOfSeries.Products      AS ListProducts_,
	|		ReceiptOfSeries.Characteristic    AS ListCharacteristics,
	|		ReceiptOfSeries.Series             AS ListSeries,
	|		UsedSeries.Products   AS Products,
	|		UsedSeries.Characteristic AS Characteristic,
	|		UsedSeries.Series          AS Series,
	|		UsedSeries.Count     AS Spent
	|	FROM
	|		Document.ProductionCostAllocation.SetOfSeries AS UsedSeries
	|		
	|		INNER JOIN Document.ProductionCostAllocation.ProductionLots AS DistributionParties
	|		ON DistributionParties.Ref = UsedSeries.Ref
	|		
	|		INNER JOIN ReceiptOfSeriesDuringProductionOnSide AS ReceiptOfSeries
	|		ON ReceiptOfSeries.ProductionLot = DistributionParties.ProductionLot
	|		
	|	WHERE
	|		NOT UsedSeries.Ref.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|) AS NestedQuery
	|WHERE
	|	NOT(NestedQuery.ListProducts_ = NestedQuery.Products
	|		AND NestedQuery.ListCharacteristics = NestedQuery.Characteristic
	|		AND NestedQuery.ListSeries = NestedQuery.Series)
	|
	|GROUP BY
	|	NestedQuery.ListProducts_,
	|	NestedQuery.ListCharacteristics,
	|	NestedQuery.ListSeries,
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	NestedQuery.Series
	|
	|ORDER BY
	|	ProductsPresentation,
	|	CharacteristicPresentation,
	|	SeriesPresentation");
	
	#EndRegion
	
	Separator = 
	"
	|;
	|/////////////////////////////////////////////////////////////
	|";
	QueryText = StrConcat(QueryTexts, Separator);
	
	If FilterByItemVariant Then
		
		SelectionAccordingToListOfNonclatura = 
		"(Products, Characteristic, Series) IN
		|					(SELECT
		|						ItemList.Products,
		|						ItemList.Characteristic,
		|						ItemList.Series
		|					FROM
		|						ItemList)";
		
		SelectionAccordingToListOfItemsTable = 
		"(GoodsTable.Products, GoodsTable.Characteristic, GoodsTable.Series) IN
		|					(SELECT
		|						ItemList.Products,
		|						ItemList.Characteristic,
		|						ItemList.Series
		|					FROM
		|						ItemList AS ItemList)";
		
	Else
		
		SelectionAccordingToListOfNonclatura = 
		"(Products, Series) IN
		|					(SELECT
		|						ItemList.Products,
		|						ItemList.Series
		|					FROM
		|						ItemList)";
		
		SelectionAccordingToListOfItemsTable = 
		"(GoodsTable.Products, GoodsTable.Series) IN
		|					(SELECT
		|						ItemList.Products,
		|						ItemList.Series
		|					FROM
		|						ItemList AS ItemList)";
		
	EndIf;
	
	QueryText = StrReplace(
		QueryText,
		"&SelectionAccordingToListOfItemsTable",
		SelectionAccordingToListOfItemsTable);
	
	QueryText = StrReplace(
		QueryText,
		"&SelectionAccordingToListOfProducts",
		SelectionAccordingToListOfNonclatura);
	
	Query = New Query(QueryText);
	Query.SetParameter("ItemList", ItemList);
	
	Return Query.Execute().Unload();
	
EndFunction

Function RowLimit()
	Return 100000;
EndFunction

Procedure ToFillInServiceFields(TreeRows, Id)

	For Each TreeRow In TreeRows Do
		
		TreeRow.ItemID = New UUID;
		TreeRow.ParentID = Id;
		ToFillInServiceFields(TreeRow.Rows, TreeRow.ItemID);
	
	EndDo;

EndProcedure

#EndRegion

#EndIf
