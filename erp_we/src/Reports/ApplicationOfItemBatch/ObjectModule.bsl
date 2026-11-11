#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - Structure - see the return value of the Clientserver report.Get a setup report for silence().
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
				ParameterItem.UserSettingPresentation = NStr("vi = 'Thành phần chi tiết';
															|ru = 'Комплектующая';
															|en = 'Component'; fa = 'Component';
															|it = 'Kit';
															|pl = 'Component';
															|tr = 'Bileşen'");
				Break;
			EndIf;
		EndDo;
		For Each ParameterItem In NewDCSettings.DataParameters.Items Do
			If ParameterItem.Parameter = SearchValue Then
				ParameterItem.UserSettingPresentation = NStr("vi = 'Thành phần chi tiết';
															|ru = 'Комплектующая';
															|en = 'Component'; fa = 'Component';
															|it = 'Kit';
															|pl = 'Component';
															|tr = 'Bileşen'");
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	NewDCSettings = FormSettingsComposer.Settings;

EndProcedure

#EndRegion

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	UseProduction = GetFunctionalOption("UseProduction");
	
	MainCircuitSettings = SettingsComposer.GetSettings();
	
	FilterProducts = DataCompositionClientServer.GetParameter(MainCircuitSettings, "Products").Value;
	FilterSeries = DataCompositionClientServer.GetParameter(MainCircuitSettings, "Series").Value;
	
	If Not ValueIsFilled(FilterProducts) Then
		If GetFunctionalOption("UseProduction") Then
			MessageText = NStr("vi = 'Chưa điền trường ""Bán thành phẩm hoặc nguyên vật liệu"".';
								|ru = 'Поле ""Полуфабрикат или материал"" не заполнено.';
								|en = '""Semi-finished product or material"" is not filled in.'; fa = '""Semi-finished product or material"" is not filled in.';
								|it = 'Il campo ""semilavorato o materiale non è compilato.';
								|pl = 'Pole ""Półprodukt lub materiał"" nie jest wypełnione.';
								|tr = '""Yarım Mamul Ürün ve Malzeme"" alanı doldurulmadı.'");
		Else
			MessageText = NStr("vi = 'Chưa điền trường ""Bảng kê chi tiết"".';
								|ru = 'Поле ""Комплектующая"" не заполнено.';
								|en = '""Component"" is not filled in.'; fa = '""Component"" is not filled in.';
								|it = 'Campo ""Kit"" non compilato.';
								|pl = 'Nie wypełniono pola ""Komponent"".';
								|tr = '""Bileşen"" alanı doldurulmadı.'");
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
		
	ReportSettings = SettingsComposer.GetSettings();
	
	// Data preparation
	ReportParameters = New Structure;
	ReportParameters.Insert("Products", DataCompositionClientServer.GetParameter(ReportSettings, "Products").Value);
	ReportParameters.Insert("Characteristic", DataCompositionClientServer.GetParameter(ReportSettings, "Characteristic").Value);
	ReportParameters.Insert("Series", DataCompositionClientServer.GetParameter(ReportSettings, "Series").Value);
	
	TreeSeriesStructure = ApplicationOfItemBatch(ReportParameters);
	
	For Each TreeRow In TreeSeriesStructure.Rows Do
		
		TreeRow.ParentID = "";
		TreeRow.ItemID = New UUID;
		ToFillInServiceFields(TreeRow.Rows, TreeRow.ItemID);
	
	EndDo;
	
	ExternalSets = New Structure;
	ExternalSets.Insert("SeriesApplication", TreeSeriesStructure);
	
	// Report design
	UseProduction = GetFunctionalOption("UseProduction");
	AreaParameters_ = New Structure;
	If UseProduction Then
		AreaParameters_.Insert("TextProducts_", NStr("vi = 'Thành phẩm hoặc bán thành phẩm';
													|ru = 'Продукция или полуфабрикат';
													|en = 'Products or semi-finished product'; fa = 'محصولات یا محصول نیمه‌ساخته';
													|it = 'Prodotto o semilavorato';
													|pl = 'Wiersze pozycji lub półprodukt';
													|tr = 'İmal edilen ürünler veya yarı mamul ürün'", Common.DefaultLanguageCode()));
		AreaParameters_.Insert("TextProduced", NStr("vi = 'Đã thực hiện';
													|ru = 'Произведено';
													|en = 'Produced'; fa = 'تولیدشده';
													|it = 'Prodotto';
													|pl = 'Produced';
													|tr = 'Üretildi'", Common.DefaultLanguageCode()));
	Else
		AreaParameters_.Insert("TextProducts_", NStr("vi = 'Bộ sản phẩm';
													|ru = 'Комплект';
													|en = 'Kit'; fa = 'کیت';
													|it = 'Kit';
													|pl = 'Kit';
													|tr = 'Küme'", Common.DefaultLanguageCode()));
		AreaParameters_.Insert("TextProduced", NStr("vi = 'Đã tập hợp';
													|ru = 'Собрано';
													|en = 'Assembled'; fa = 'مونتاژشده';
													|it = 'Composto';
													|pl = 'Assembled';
													|tr = 'Toplandı'", Common.DefaultLanguageCode()));
	EndIf;
	
	DatasetFields = DataCompositionSchema.DataSets.SeriesApplication.Fields; // DataCompositionSchemaDataSetFields
	ProductsField = DatasetFields.Find("Products");
	FieldIsProduced = DatasetFields.Find("Manufactured");
	
	If ProductsField <> Undefined Then
		ProductsField.Title = AreaParameters_.TextProducts_;
	EndIf;
	
	If FieldIsProduced <> Undefined Then
		FieldIsProduced.Title = AreaParameters_.TextProduced;
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

Function ApplicationOfItemBatch(Parameters)
	
	ApplicationOfSeriesProductTree = New ValueTree;
	ApplicationOfSeriesProductTree.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	ApplicationOfSeriesProductTree.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	ApplicationOfSeriesProductTree.Columns.Add("Series", New TypeDescription("CatalogRef.ItemsBatches"));
	ApplicationOfSeriesProductTree.Columns.Add("Manufactured", New TypeDescription("Number"));
	ApplicationOfSeriesProductTree.Columns.Add("UnitOfMeasure", New TypeDescription("String"));
	ApplicationOfSeriesProductTree.Columns.Add("ProductsPresentation", New TypeDescription("String"));
	ApplicationOfSeriesProductTree.Columns.Add("SeriesPresentation", New TypeDescription("String"));
	
	TypesArray = New Array;
	TypesArray.Add(New TypeDescription("UUID"));
	TypesArray.Add(New TypeDescription("String"));
	
	ApplicationOfSeriesProductTree.Columns.Add("ItemID", New TypeDescription(TypesArray));
	ApplicationOfSeriesProductTree.Columns.Add("ParentID", New TypeDescription(TypesArray));
	
	ApplicationOfCollectionSeries = ApplicationOfSeriesProductTree.Rows;
	
	ItemList = New ValueTable; // See ProductionServer.ServiceStructureOfValueTable
	ItemList.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	ItemList.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	ItemList.Columns.Add("Series", New TypeDescription("CatalogRef.ItemsBatches"));
	ItemList.Columns.Add("Rows");
	
	NewRow = ItemList.Add();
	FillPropertyValues(NewRow, Parameters);
	NewRow.Rows = ApplicationOfCollectionSeries;
	
	FilterByItemVariant = ValueIsFilled(Parameters.Characteristic);
	
	SetPrivilegedMode(True);
	
	While ItemList.Count() <> 0 Do
		
		NewListOfProducts = ItemList.CopyColumns();
		
		ProducedSeries = ProducedSeries(ItemList, FilterByItemVariant);
		
		If Not FilterByItemVariant Then
			
			FilterByItemVariant = True;
			
			ItemList.Clear();
			
			Columns = "ListProducts_, ListCharacteristics, ListSeries";
			ProducedSeriesCopy = ProducedSeries.Copy(, Columns);
			ProducedSeriesCopy.GroupBy(Columns);
			
			For Each String In ProducedSeriesCopy Do
				
				NewRow = ItemList.Add();
				NewRow.Products = String.ListProducts_;
				NewRow.Characteristic = String.ListCharacteristics;
				NewRow.Series = String.ListSeries;
				NewRow.Rows = ApplicationOfCollectionSeries;
				
			EndDo;
			
		EndIf;
		
		For Each StringProducts_ In ItemList Do
			
			TheStructureOfTheSearch = New Structure;
			TheStructureOfTheSearch.Insert("ListProducts_", StringProducts_.Products);
			TheStructureOfTheSearch.Insert("ListCharacteristics", StringProducts_.Characteristic);
			TheStructureOfTheSearch.Insert("ListSeries", StringProducts_.Series);
			
	  		StringsList = ProducedSeries.FindRows(TheStructureOfTheSearch);
			For Each StringProductSeries In StringsList Do
				
				NewSeries_ = StringProducts_.Rows.Add();
				FillPropertyValues(NewSeries_, StringProductSeries);
				NewSeries_.ProductsPresentation = ProductsClientServer.ProductPresentation(
					StringProductSeries.ProductsPresentation,
					StringProductSeries.CharacteristicPresentation);
				
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
			
		EndDo;
		
		ItemList = NewListOfProducts.Copy();
		
	EndDo; 
	
	Return ApplicationOfSeriesProductTree;

EndFunction

Function ProducedSeries(ItemList, FilterByItemVariant)
	
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
	
	
	#Region ConsumptionOfSeriesInProduction22
	
	// Production without an order
	QueryTexts.Add(
	"SELECT ALLOWED
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.ProductionLot AS ProductionLot
	|INTO ConsumptionOfSeriesInProductionWithoutOrder
	|FROM
	|	(
	// Production without an order
	|	SELECT
	|		GoodsTable.Products   AS Products,
	|		GoodsTable.Characteristic AS Characteristic,
	|		GoodsTable.Series          AS Series,
	|		CatProductionLots.Ref AS ProductionLot
	|	FROM
	|		Document.BackflushProduction.MaterialsAndWorks AS GoodsTable
	|		
	|		INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Document = GoodsTable.Ref
	|		AND CatProductionLots.Code = GoodsTable.CostGroupNumber
	|		AND NOT CatProductionLots.DeletionMark
	|	
	|	WHERE
	|		GoodsTable.Ref.Posted
	|		AND NOT GoodsTable.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|		AND &SelectionAccordingToListOfItemsTable
	|	
	|	UNION ALL
	|	
	// Distribution of materials for production without an order.
	|	SELECT
	|		GoodsTable.Products        AS Products,
	|		GoodsTable.Characteristic      AS Characteristic,
	|		GoodsTable.Series               AS Series,
	|		BatchTable.ProductionLot  AS ProductionLot
	|	FROM
	|		Document.ProductionCostAllocation AS GoodsTable
	|		
	|		INNER JOIN Document.ProductionCostAllocation.ProductionLots AS BatchTable
	|		ON BatchTable.Ref = GoodsTable.Ref
	|	WHERE
	|		GoodsTable.Ref.Posted
	|		AND NOT GoodsTable.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|		AND VALUETYPE(BatchTable.ProductionLot.Document) = TYPE(Document.BackflushProduction)
	|		AND &SelectionAccordingToListOfItemsTable
	|	
	|	UNION ALL
	|	
	// Distribution of materials for production without an order, the series are indicated in a separate tabular part.
	// Due to the lack of compliance of the series with the production batches, all series participate in all production batches.
	|	SELECT
	|		GoodsTable.Products        AS Products,
	|		GoodsTable.Characteristic      AS Characteristic,
	|		GoodsTable.Series               AS Series,
	|		BatchTable.ProductionLot  AS ProductionLot
	|	FROM
	|		Document.ProductionCostAllocation.SetOfSeries AS GoodsTable
	|		
	|		INNER JOIN Document.ProductionCostAllocation.ProductionLots AS BatchTable
	|		ON BatchTable.Ref = GoodsTable.Ref
	|	WHERE
	|		GoodsTable.Ref.Posted
	|		AND NOT GoodsTable.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|		AND VALUETYPE(BatchTable.ProductionLot.Document) = TYPE(Document.BackflushProduction)
	|		AND &SelectionAccordingToListOfItemsTable
	|	) AS GoodsTable
	|
	|GROUP BY
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Series,
	|	GoodsTable.ProductionLot
	|
	|INDEX BY
	|	ProductionLot
	|");
	
	// Production on the side
	QueryTexts.Add(
	"SELECT ALLOWED
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.ProductionLot AS ProductionLot
	|INTO ConsumptionOfBatchesDuringProductionOnSide
	|FROM
	|	(
	// Subcontracting service notification received
	|	SELECT
	|		GoodsTable.Products   AS Products,
	|		GoodsTable.Characteristic AS Characteristic,
	|		GoodsTable.Series          AS Series,
	|		CatProductionLots.Ref AS ProductionLot
	|	FROM
	|		Document.SubcontractorReport2_5.MaterialsAndWorks AS GoodsTable
	|		
	|		INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Document = GoodsTable.Ref
	|		AND CatProductionLots.Code = GoodsTable.CostGroupNumber
	|		AND NOT CatProductionLots.DeletionMark
	|	
	|	WHERE
	|		GoodsTable.Ref.Posted
	|		AND NOT GoodsTable.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|		AND &SelectionAccordingToListOfItemsTable
	|	
	|	UNION ALL
	|	
	// The Subcontracted services notification received by stages
	|	SELECT
	|		GoodsTable.Products     AS Products,
	|		GoodsTable.Characteristic   AS Characteristic,
	|		GoodsTable.Series            AS Series,
	|		Data_Stage.ProductionLot AS ProductionLot
	|	FROM
	|		Document.SubcontractorReport2_5.MaterialsAndWorks AS GoodsTable
	|		
	|		INNER JOIN Document.ProductionStage2_2 AS Data_Stage
	|		ON GoodsTable.ProductionStage = Data_Stage.Ref
	|	
	|	WHERE
	|		GoodsTable.Ref.Posted
	|		AND NOT GoodsTable.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|		AND &SelectionAccordingToListOfItemsTable
	|	
	|	UNION ALL
	|	
	// Distribution of materials for production on the side.
	|	SELECT
	|		GoodsTable.Products        AS Products,
	|		GoodsTable.Characteristic      AS Characteristic,
	|		GoodsTable.Series               AS Series,
	|		BatchTable.ProductionLot  AS ProductionLot
	|	FROM
	|		Document.ProductionCostAllocation AS GoodsTable
	|		
	|		INNER JOIN Document.ProductionCostAllocation.ProductionLots AS BatchTable
	|		ON BatchTable.Ref = GoodsTable.Ref
	|	WHERE
	|		GoodsTable.Ref.Posted
	|		AND NOT GoodsTable.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|		AND VALUETYPE(BatchTable.ProductionLot.Document) = TYPE(Document.SubcontractorReport2_5)
	|		AND &SelectionAccordingToListOfItemsTable
	|	
	|	UNION ALL
	|	
	// The distribution of materials for production on the side, the series are indicated in a separate tabular part.
	// Due to the lack of compliance of the series with the production batches, all series participate in all production batches.
	|	SELECT
	|		GoodsTable.Products        AS Products,
	|		GoodsTable.Characteristic      AS Characteristic,
	|		GoodsTable.Series               AS Series,
	|		BatchTable.ProductionLot  AS ProductionLot
	|	FROM
	|		Document.ProductionCostAllocation.SetOfSeries AS GoodsTable
	|		
	|		INNER JOIN Document.ProductionCostAllocation.ProductionLots AS BatchTable
	|		ON BatchTable.Ref = GoodsTable.Ref
	|	WHERE
	|		GoodsTable.Ref.Posted
	|		AND NOT GoodsTable.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|		AND VALUETYPE(BatchTable.ProductionLot.Document) = TYPE(Document.SubcontractorReport2_5)
	|		AND &SelectionAccordingToListOfItemsTable
	|	) AS GoodsTable
	|
	|GROUP BY
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Series,
	|	GoodsTable.ProductionLot
	|
	|INDEX BY
	|	ProductionLot
	|");
	
	// Production by order
	QueryTexts.Add(
	"SELECT ALLOWED DISTINCT
	|	SeriesMovement.Products AS Products,
	|	SeriesMovement.Characteristic AS Characteristic,
	|	SeriesMovement.Series AS Series,
	|	ISNULL(CatProductionLots.Ref, CAST(SeriesMovement.Document AS Document.ProductionStage2_2).ProductionLot) AS ProductionLot
	|INTO ConsumptionOfSeriesInStagesOfProduction
	|FROM
	|	AccumulationRegister.GoodsBatchMovement.Turnovers(
	|			,
	|			,
	|			,
	|			&SelectionAccordingToListOfProducts
	|				AND (WarehouseOperation = VALUE(Enum.WarehouseTransactions.ConsumptionDuringProduction)
	|						AND VALUETYPE(Document) = TYPE(Document.ProductionStage2_2)
	|					OR Document IN
	|						(SELECT
	|							AllocationOfCosts.Ref AS Ref
	|						FROM
	|							Document.ProductionCostAllocation AS AllocationOfCosts
	|						WHERE
	|							TRUE IN
	|								(SELECT
	|									TRUE
	|								FROM
	|									Document.ProductionCostAllocation.ProductionLots AS ProductionLots
	|										LEFT JOIN Catalog.ProductionLots AS CatProductionLots
	|										ON
	|											ProductionLots.ProductionLot = CatProductionLots.Ref
	|								WHERE
	|									ProductionLots.Ref = AllocationOfCosts.Ref
	|									AND VALUETYPE(CatProductionLots.Document) = TYPE(Document.ProductionOrder2_2)
	|									AND CatProductionLots.Document <> VALUE(Document.ProductionOrder2_2.EmptyRef))))) AS SeriesMovement
	|
	|		LEFT JOIN Document.ProductionCostAllocation.ProductionLots AS ProductionLots
	|		ON SeriesMovement.Document = ProductionLots.Ref
	|
	|		LEFT JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON (ProductionLots.ProductionLot = CatProductionLots.Ref)
	|			AND (VALUETYPE(CatProductionLots.Document) = TYPE(Document.ProductionOrder2_2))
	|			AND (CatProductionLots.Document <> VALUE(Document.ProductionOrder2_2.EmptyRef))
	|
	|INDEX BY
	|	ProductionLot
	|");
	#EndRegion
	
	#Region ArrivalOfSeriesInProduction22
	
	// Production without an order
	QueryTexts.Add(
	"SELECT ALLOWED DISTINCT
	|	GoodsTable.Products       AS Products,
	|	GoodsTable.Characteristic     AS Characteristic,
	|	GoodsTable.Series              AS Series,
	|	SUM(GoodsTable.Count)  AS Count,
	|	GoodsTable.ProductionLot AS ProductionLot
	|INTO ReceiptOfSeriesInProductionWithoutOrder
	|FROM
	|	(
	// production of products in the pantry
	|	SELECT
	|		GoodsTable.Products   AS Products,
	|		GoodsTable.Characteristic AS Characteristic,
	|		GoodsTable.Series          AS Series,
	|		GoodsTable.Count     AS Count,
	|		CatProductionLots.Ref AS ProductionLot
	|	FROM
	|		Document.BackflushProduction.ManufacturedProducts AS GoodsTable
	|	
	|		INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Document = GoodsTable.Ref
	|		AND CatProductionLots.Code = GoodsTable.CostGroupNumber
	|		AND NOT CatProductionLots.DeletionMark
	|	
	|	WHERE
	|		GoodsTable.Ref.Posted
	|		AND VALUETYPE(GoodsTable.Recipient) = TYPE(Catalog.Warehouses)
	|		AND NOT GoodsTable.Recipient = VALUE(Catalog.Warehouses.EmptyRef)
	|		AND NOT GoodsTable.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|		AND CatProductionLots.Ref IN(
	|			SELECT
	|				ExpenseLotReference.ProductionLot
	|			FROM
	|				ConsumptionOfSeriesInProductionWithoutOrder AS ExpenseLotReference)
	|	
	|	UNION ALL
	|	
	// production of products in the pantry
	|	SELECT
	|		GoodsTable.Products   AS Products,
	|		GoodsTable.Characteristic AS Characteristic,
	|		GoodsTable.Series          AS Series,
	|		GoodsTable.Count     AS Count,
	|		CatProductionLots.Ref AS ProductionLot
	|	FROM
	|		Document.BackflushProduction.BatchFinishedProducts AS GoodsTable
	|	
	|		INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Document = GoodsTable.Ref
	|		AND CatProductionLots.Code = GoodsTable.CostGroupNumber
	|		AND NOT CatProductionLots.DeletionMark
	|	
	|	WHERE
	|		GoodsTable.Ref.Posted
	|		AND VALUETYPE(GoodsTable.Recipient) = TYPE(Catalog.Warehouses)
	|		AND NOT GoodsTable.Recipient = VALUE(Catalog.Warehouses.EmptyRef)
	|		AND CatProductionLots.Ref IN(
	|			SELECT
	|				ExpenseLotReference.ProductionLot
	|			FROM
	|				ConsumptionOfSeriesInProductionWithoutOrder AS ExpenseLotReference)
	|	
	|	UNION ALL
	|	
	// production of returnable waste to the pantry
	|	SELECT
	|		GoodsTable.Products   AS Products,
	|		GoodsTable.Characteristic AS Characteristic,
	|		GoodsTable.Series          AS Series,
	|		GoodsTable.Count     AS Count,
	|		CatProductionLots.Ref AS ProductionLot
	|	FROM
	|		Document.BackflushProduction.SideAndIntermediateRelease AS GoodsTable
	|	
	|		INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Document = GoodsTable.Ref
	|		AND CatProductionLots.Code = GoodsTable.CostGroupNumber
	|		AND NOT CatProductionLots.DeletionMark
	|	
	|	WHERE
	|		GoodsTable.Ref.Posted
	|		AND VALUETYPE(GoodsTable.Recipient) = TYPE(Catalog.Warehouses)
	|		AND NOT GoodsTable.Recipient = VALUE(Catalog.Warehouses.EmptyRef)
	|		AND NOT GoodsTable.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|		AND CatProductionLots.Ref IN(
	|			SELECT
	|				ExpenseLotReference.ProductionLot
	|			FROM
	|				ConsumptionOfSeriesInProductionWithoutOrder AS ExpenseLotReference)
	|	
	|	UNION ALL
	|	
	// production of returnable waste to the pantry
	|	SELECT
	|		GoodsTable.Products   AS Products,
	|		GoodsTable.Characteristic AS Characteristic,
	|		GoodsTable.Series          AS Series,
	|		GoodsTable.Count     AS Count,
	|		CatProductionLots.Ref AS ProductionLot
	|	FROM
	|		Document.BackflushProduction.BatchSideAndIntermediateRelease AS GoodsTable
	|	
	|		INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Document = GoodsTable.Ref
	|		AND CatProductionLots.Code = GoodsTable.CostGroupNumber
	|		AND NOT CatProductionLots.DeletionMark
	|	
	|	WHERE
	|		GoodsTable.Ref.Posted
	|		AND VALUETYPE(GoodsTable.Recipient) = TYPE(Catalog.Warehouses)
	|		AND NOT GoodsTable.Recipient = VALUE(Catalog.Warehouses.EmptyRef)
	|		AND CatProductionLots.Ref IN(
	|			SELECT
	|				ExpenseLotReference.ProductionLot
	|			FROM
	|				ConsumptionOfSeriesInProductionWithoutOrder AS ExpenseLotReference)
	|	) AS GoodsTable
	|
	|GROUP BY
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Series,
	|	GoodsTable.ProductionLot
	|
	|INDEX BY
	|	ProductionLot
	|");
	
	// Production by order
	QueryTexts.Add(
	"SELECT
	|	ProductionStage2_2.Ref AS Ref,
	|	ProductionStage2_2.ProductionLot
	|INTO ProductionStages
	|FROM
	|	Document.ProductionStage2_2 AS ProductionStage2_2
	|WHERE
	|	ProductionStage2_2.Posted
	|	AND ProductionStage2_2.ProductionLot IN
	|			(SELECT
	|				SeriesConsumption.ProductionLot
	|			FROM
	|				ConsumptionOfSeriesInStagesOfProduction AS SeriesConsumption)
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductionStages.ProductionLot AS ProductionLot,
	|	ReleaseTable.Ref AS Ref,
	|	ReleaseTable.Products AS Products,
	|	ReleaseTable.Characteristic AS Characteristic,
	|	ReleaseTable.Purpose AS Purpose,
	|	ReleaseTable.Recipient AS Recipient,
	|	ReleaseTable.Manufactured AS Manufactured,
	|	ReleaseTable.ProductionDate AS ProductionDate,
	|	ReleaseTable.Department AS Department,
	|	ReleaseTable.Series AS Series,
	|	SUM(ReleaseTable.Count) AS Count
	|INTO StagesOutputProducts
	|FROM
	|	ProductionStages AS ProductionStages
	|		INNER JOIN Document.ProductionStage2_2.ManufacturedProducts AS ReleaseTable
	|		ON ProductionStages.Ref = ReleaseTable.Ref
	|WHERE
	|	ReleaseTable.Manufactured
	|	AND NOT ReleaseTable.Canceled
	|
	|GROUP BY
	|	ReleaseTable.Ref,
	|	ReleaseTable.Manufactured,
	|	ReleaseTable.Series,
	|	ReleaseTable.Recipient,
	|	ReleaseTable.Characteristic,
	|	ReleaseTable.Purpose,
	|	ReleaseTable.ProductionDate,
	|	ProductionStages.ProductionLot,
	|	ReleaseTable.Products,
	|	ReleaseTable.Department
	|
	|INDEX BY
	|	Ref,
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Recipient,
	|	Manufactured,
	|	ProductionDate,
	|	Department
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductionStages.ProductionLot AS ProductionLot,
	|	ReleaseTable.Ref AS Ref,
	|	ReleaseTable.Products AS Products,
	|	ReleaseTable.Characteristic AS Characteristic,
	|	ReleaseTable.Purpose AS Purpose,
	|	ReleaseTable.Recipient AS Recipient,
	|	ReleaseTable.Manufactured AS Manufactured,
	|	ReleaseTable.ProductionDate AS ProductionDate,
	|	ReleaseTable.Department AS Department,
	|	ReleaseTable.ProductOwner AS ProductOwner,
	|	ReleaseTable.Series AS Series,
	|	SUM(ReleaseTable.Count) AS Count
	|INTO StagesByProducts
	|FROM
	|	ProductionStages AS ProductionStages
	|		INNER JOIN Document.ProductionStage2_2.SideAndIntermediateRelease AS ReleaseTable
	|		ON ProductionStages.Ref = ReleaseTable.Ref
	|WHERE
	|	ReleaseTable.Manufactured = TRUE
	|	AND ReleaseTable.StageConsumer = VALUE(Document.ProductionStage2_2.EmptyRef)
	|	AND NOT ReleaseTable.Canceled
	|
	|GROUP BY
	|	ProductionStages.ProductionLot,
	|	ReleaseTable.Recipient,
	|	ReleaseTable.Series,
	|	ReleaseTable.Purpose,
	|	ReleaseTable.Manufactured,
	|	ReleaseTable.Ref,
	|	ReleaseTable.Products,
	|	ReleaseTable.Characteristic,
	|	ReleaseTable.ProductionDate,
	|	ReleaseTable.Department,
	|	ReleaseTable.ProductOwner
	|
	|INDEX BY
	|	Ref,
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Recipient,
	|	Manufactured,
	|	ProductionDate,
	|	Department,
	|	ProductOwner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReleaseTable.ProductionLot AS ProductionLot,
	|	ReleaseTable.Products AS Products,
	|	ReleaseTable.Characteristic AS Characteristic,
	|	ISNULL(SeriesTable.Series, ReleaseTable.Series) AS Series,
	|	ISNULL(SeriesTable.Count, ReleaseTable.Count) AS Count
	|INTO ArrivalOfSeriesInProductionStages
	|FROM
	|	StagesOutputProducts AS ReleaseTable
	|		LEFT JOIN Document.ProductionStage2_2.BatchFinishedProducts AS SeriesTable
	|		ON ReleaseTable.Ref = SeriesTable.Ref
	|			AND ReleaseTable.Products = SeriesTable.Products
	|			AND ReleaseTable.Characteristic = SeriesTable.Characteristic
	|			AND ReleaseTable.Purpose = SeriesTable.Purpose
	|			AND ReleaseTable.Recipient = SeriesTable.Recipient
	|			AND ReleaseTable.Manufactured = SeriesTable.Manufactured
	|			AND ReleaseTable.ProductionDate = SeriesTable.ProductionDate
	|			AND ReleaseTable.Department = SeriesTable.Department
	|
	|UNION ALL
	|
	|SELECT
	|	ReleaseTable.ProductionLot,
	|	ReleaseTable.Products,
	|	ReleaseTable.Characteristic,
	|	ISNULL(SeriesTable.Series, ReleaseTable.Series),
	|	ISNULL(SeriesTable.Count, ReleaseTable.Count)
	|FROM
	|	StagesByProducts AS ReleaseTable
	|		LEFT JOIN Document.ProductionStage2_2.BatchSideAndIntermediateRelease AS SeriesTable
	|		ON ReleaseTable.Ref = SeriesTable.Ref
	|			AND ReleaseTable.Products = SeriesTable.Products
	|			AND ReleaseTable.Characteristic = SeriesTable.Characteristic
	|			AND ReleaseTable.Purpose = SeriesTable.Purpose
	|			AND ReleaseTable.Recipient = SeriesTable.Recipient
	|			AND ReleaseTable.Manufactured = SeriesTable.Manufactured
	|			AND ReleaseTable.ProductionDate = SeriesTable.ProductionDate
	|			AND ReleaseTable.Department = SeriesTable.Department
	|			AND ReleaseTable.ProductOwner = SeriesTable.ProductOwner
	|
	|INDEX BY
	|	ProductionLot");
	#EndRegion
	
	#Region ReceiptOfSeriesDuringProductionOnSide
	
	QueryTexts.Add(
	"SELECT ALLOWED
	|	GoodsTable.Products       AS Products,
	|	GoodsTable.Characteristic     AS Characteristic,
	|	GoodsTable.Series              AS Series,
	|	SUM(GoodsTable.Count)  AS Count,
	|	GoodsTable.ProductionLot AS ProductionLot
	|INTO ReceiptOfSeriesDuringProductionOnSide
	|FROM
	|	(SELECT
	|		GoodsTable.Products   AS Products,
	|		GoodsTable.Characteristic AS Characteristic,
	|		GoodsTable.Series          AS Series,
	|		GoodsTable.Count     AS Count,
	|		CatProductionLots.Ref AS ProductionLot
	|	FROM
	|		Document.SubcontractorReport2_5.ManufacturedProducts AS GoodsTable
	|		
	|		INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Document = GoodsTable.Ref
	|		AND CatProductionLots.Code = GoodsTable.CostGroupNumber
	|		AND NOT CatProductionLots.DeletionMark
	|	
	|	WHERE
	|		GoodsTable.Ref.Posted
	|		AND GoodsTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|		AND CatProductionLots.Ref IN(
	|			SELECT
	|				ExpenseLotReference.ProductionLot
	|			FROM
	|				ConsumptionOfBatchesDuringProductionOnSide AS ExpenseLotReference)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsTable.Products   AS Products,
	|		GoodsTable.Characteristic AS Characteristic,
	|		GoodsTable.Series          AS Series,
	|		GoodsTable.Count     AS Count,
	|		CatProductionLots.Ref AS ProductionLot
	|	FROM
	|		Document.SubcontractorReport2_5.SideAndIntermediateRelease AS GoodsTable
	|	
	|		INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Document = GoodsTable.Ref
	|		AND CatProductionLots.Code = GoodsTable.CostGroupNumber
	|		AND NOT CatProductionLots.DeletionMark
	|	
	|	WHERE
	|		GoodsTable.Ref.Posted
	|		AND GoodsTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|		AND CatProductionLots.Ref IN(
	|			SELECT
	|				ExpenseLotReference.ProductionLot
	|			FROM
	|				ConsumptionOfBatchesDuringProductionOnSide AS ExpenseLotReference)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsTable.Products     AS Products,
	|		GoodsTable.Characteristic   AS Characteristic,
	|		GoodsTable.Series            AS Series,
	|		GoodsTable.Count       AS Count,
	|		Data_Stage.ProductionLot AS ProductionLot
	|	FROM
	|		Document.SubcontractorReport2_5.ManufacturedProducts AS GoodsTable
	|	
	|		INNER JOIN Document.ProductionStage2_2 AS Data_Stage
	|		ON GoodsTable.ProductionStage = Data_Stage.Ref
	|	
	|	WHERE
	|		GoodsTable.Ref.Posted
	|		AND GoodsTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|		AND Data_Stage.ProductionLot IN(
	|			SELECT
	|				ExpenseLotReference.ProductionLot
	|			FROM
	|				ConsumptionOfBatchesDuringProductionOnSide AS ExpenseLotReference)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsTable.Products     AS Products,
	|		GoodsTable.Characteristic   AS Characteristic,
	|		GoodsTable.Series            AS Series,
	|		GoodsTable.Count       AS Count,
	|		Data_Stage.ProductionLot AS ProductionLot
	|	FROM
	|		Document.SubcontractorReport2_5.SideAndIntermediateRelease AS GoodsTable
	|	
	|		INNER JOIN Document.ProductionStage2_2 AS Data_Stage
	|		ON GoodsTable.ProductionStage = Data_Stage.Ref
	|	
	|	WHERE
	|		GoodsTable.Ref.Posted
	|		AND GoodsTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|		AND Data_Stage.ProductionLot IN(
	|			SELECT
	|				ExpenseLotReference.ProductionLot
	|			FROM
	|				ConsumptionOfBatchesDuringProductionOnSide AS ExpenseLotReference)
	|	) AS GoodsTable
	|
	|GROUP BY
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Series,
	|	GoodsTable.ProductionLot
	|
	|INDEX BY
	|	ProductionLot
	|");
	
	#EndRegion
	#Region ConsumptionOfSeriesDuringAssembly
	
	QueryTexts.Add(
	"SELECT ALLOWED
	|	SeriesMovement.Products AS Products,
	|	SeriesMovement.Characteristic AS Characteristic,
	|	SeriesMovement.Series AS Series,
	|	CAST(SeriesMovement.Document AS Document.AssemblyFromComponents) AS Document,
	|	SeriesMovement.CountTurnover AS Count
	|INTO ConsumptionOfSeriesDuringAssembly
	|FROM
	|	AccumulationRegister.GoodsBatchMovement.Turnovers(
	|			,
	|			,
	|			,
	|			&SelectionAccordingToListOfProducts
	|				AND WarehouseOperation IN (VALUE(Enum.WarehouseTransactions.ShipComponentsForAssembly),
	|										VALUE(Enum.WarehouseTransactions.ShipSetsForDisassembly))) AS SeriesMovement
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Series,
	|	Document");
	
	#EndRegion
	
	#Region ArrivalOfSeries
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
	|	SUM(NestedQuery.Manufactured) AS Manufactured
	|FROM
	|(
	|	SELECT
	|		ConsumptionOfSeriesDuringAssembly.Products AS ListProducts_,
	|		ConsumptionOfSeriesDuringAssembly.Characteristic AS ListCharacteristics,
	|		ConsumptionOfSeriesDuringAssembly.Series AS ListSeries,
	|		ReceiptOfSeriesDuringAssembly.Products AS Products,
	|		ReceiptOfSeriesDuringAssembly.Characteristic AS Characteristic,
	|		ReceiptOfSeriesDuringAssembly.Series AS Series,
	|		ReceiptOfSeriesDuringAssembly.CountTurnover AS Manufactured
	|	FROM 	
	|		AccumulationRegister.GoodsBatchMovement.Turnovers(
	|			,
	|			,
	|			,
	|			Document IN
	|					(SELECT
	|						ConsumptionOfSeriesDuringAssembly.Document
	|					FROM
	|						ConsumptionOfSeriesDuringAssembly AS ConsumptionOfSeriesDuringAssembly)
	|				AND WarehouseOperation IN (VALUE(Enum.WarehouseTransactions.ReceivingOfAssembledSets),
	|										VALUE(Enum.WarehouseTransactions.ReceivingOfComponentsAfterDisassembly))) AS ReceiptOfSeriesDuringAssembly
	|		LEFT JOIN ConsumptionOfSeriesDuringAssembly AS ConsumptionOfSeriesDuringAssembly
	|		ON ConsumptionOfSeriesDuringAssembly.Document = ReceiptOfSeriesDuringAssembly.Document

	|
	|	UNION ALL
	|
	// Production without an order
	|	SELECT
	|		ConsumptionOfSeriesInProductionWithoutOrder.Products   AS ListProducts_,
	|		ConsumptionOfSeriesInProductionWithoutOrder.Characteristic AS ListCharacteristics,
	|		ConsumptionOfSeriesInProductionWithoutOrder.Series          AS ListSeries,
	|		ReceiptOfSeries.Products                      AS Products,
	|		ReceiptOfSeries.Characteristic                    AS Characteristic,
	|		ReceiptOfSeries.Series                             AS Series,
	|		ReceiptOfSeries.Count                        AS Manufactured
	|	FROM
	|		ReceiptOfSeriesInProductionWithoutOrder AS ReceiptOfSeries
	|		LEFT JOIN ConsumptionOfSeriesInProductionWithoutOrder AS ConsumptionOfSeriesInProductionWithoutOrder
	|		ON ConsumptionOfSeriesInProductionWithoutOrder.ProductionLot = ReceiptOfSeries.ProductionLot
	|
	|	UNION ALL
	|
	// Production on the side
	|	SELECT
	|		ConsumptionOfBatchesDuringProductionOnSide.Products   AS ListProducts_,
	|		ConsumptionOfBatchesDuringProductionOnSide.Characteristic AS ListCharacteristics,
	|		ConsumptionOfBatchesDuringProductionOnSide.Series          AS ListSeries,
	|		ReceiptOfSeries.Products                      AS Products,
	|		ReceiptOfSeries.Characteristic                    AS Characteristic,
	|		ReceiptOfSeries.Series                             AS Series,
	|		ReceiptOfSeries.Count                        AS Manufactured
	|	FROM 
	|		ReceiptOfSeriesDuringProductionOnSide AS ReceiptOfSeries
	|		LEFT JOIN ConsumptionOfBatchesDuringProductionOnSide AS ConsumptionOfBatchesDuringProductionOnSide
	|		ON ConsumptionOfBatchesDuringProductionOnSide.ProductionLot = ReceiptOfSeries.ProductionLot
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		SeriesConsumption.Products AS ListProducts_,
	|		SeriesConsumption.Characteristic AS ListCharacteristics,
	|		SeriesConsumption.Series AS ListSeries,
	|		ArrivalOfSeries.Products AS Products,
	|		ArrivalOfSeries.Characteristic AS Characteristic,
	|		ArrivalOfSeries.Series AS Series,
	|		ArrivalOfSeries.Count AS Manufactured
	|	FROM 
	|		ArrivalOfSeriesInProductionStages AS ArrivalOfSeries
	|			LEFT JOIN ConsumptionOfSeriesInStagesOfProduction AS SeriesConsumption
	|			ON ArrivalOfSeries.ProductionLot = SeriesConsumption.ProductionLot
	|
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
	|
	|/////////////////////////////////////////////////////////////
	|";
	
	QueryText = StrConcat(QueryTexts, Separator);
	
	If FilterByItemVariant Then
		
		SelectionAccordingToListOfProducts = 
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
		|						ItemList)";
		
	Else
		
		SelectionAccordingToListOfProducts = 
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
		|						ItemList)";
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "&SelectionAccordingToListOfItemsTable", SelectionAccordingToListOfItemsTable);
	QueryText = StrReplace(QueryText, "&SelectionAccordingToListOfProducts", SelectionAccordingToListOfProducts);
	
	Query = New Query(QueryText);
	
	Query.TempTablesManager = New TempTablesManager;
	
	Query.SetParameter("ItemList", ItemList);
	
	Result = Query.Execute().Unload();
	
	Result.Indexes.Add("ListProducts_,ListSeries");
	
	Return Result;
	
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
