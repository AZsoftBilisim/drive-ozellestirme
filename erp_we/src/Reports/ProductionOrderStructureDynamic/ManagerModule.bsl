
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Generates a tree of products of a given production order.
// The order items and PF of the first level are displayed in the tree.
//
// Parameters:
//	Parameters - Structure - data reading parameters. Contains:
//		* OrderDocument - DocumentRef.ProductionOrder2_2 - order.
//		* StagesShow - Boolean - output/not output stages to the structure.
//  StorageAddress - String - address of the storage where the result will be placed.
//
Procedure BuildOrderTree(Parameters, StorageAddress) Export
	
	PutToTempStorage(
		TreeOrder(Parameters), 
		StorageAddress);
	
EndProcedure

// Generates a tree of products of a given production order.
// The tree is constructed recursively according to the collection of expanded strings.
//
// Parameters:
//	Parameters - Structure - data reading parameters. Contains:
//		* OrderDocument - DocumentRef.ProductionOrder2_2 - order.
//		* StagesShow - Boolean - output/not output stages to the structure.
//		* ExpandedLines - ValueTable - batches deployed in the tree.
//  StorageAddress - String - address of the storage where the result will be placed.
//
Procedure BuildTreeOfExpandedStrings(Parameters, StorageAddress) Export
	
	Result = TreeOrder(Parameters);
	
	ExpandedLines = Parameters.ExpandedLines;
	
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("Products");
	TheStructureOfTheSearch.Insert("Characteristic");
	TheStructureOfTheSearch.Insert("Warehouse");
	TheStructureOfTheSearch.Insert("Purpose");
	TheStructureOfTheSearch.Insert("StageLink");
	
	TreeRows = Result.Rows.FindRows(
		New Structure("FinishTree", True),
		True);
	PartyKeys = New Array;
	
	While TreeRows.UBound() <> -1 Do
		For IndexOf = -TreeRows.UBound() To 0 Do
			
			TreeRow = TreeRows[-IndexOf];
			
			If TreeRow.RowType = StringTypeStructureStage()
					Or TreeRow.RowType = LineTypeStageDocument() Then
				FillPropertyValues(TheStructureOfTheSearch, TreeRow.Parent,
					"Products, Characteristic, Warehouse, Purpose");
				TheStructureOfTheSearch.StageLink = TreeRow.StageLink;
			Else
				FillPropertyValues(TheStructureOfTheSearch, TreeRow);
			EndIf;
			
			If ExpandedLines.FindRows(TheStructureOfTheSearch).UBound() <> -1 Then
				
				PartyKeys.Clear();
				
				For DescendantIndex = -TreeRow.Rows.Count()+1 To 0 Do
					DescendantString = TreeRow.Rows[-DescendantIndex];
					If DescendantString.RowType = RowTypeInternal() Then
						PartyKeys.Add(DescendantString.KeyLot);
						TreeRow.Rows.Delete(-DescendantIndex);
					EndIf;
				EndDo;
				
				FillTreeRecursively(
					TreeRow.Rows,
					TreeOfSemiFinishedProducts(Parameters.OrderDocument, PartyKeys, TreeRow.StageLink, Parameters, Parameters.Purpose).Rows,
					TreeRows);
				
				TreeRow.FinishTree = False;
				
			EndIf;
			TreeRows.Delete(-IndexOf);
			
		EndDo;
	EndDo;
	
	PutToTempStorage(Result, StorageAddress);
	
EndProcedure

// Generates an order tree from a given item item / warehouse (search in the order structure).
//
// Parameters:
//	Parameters - Structure - data reading parameters. Contains:
//		* OrderDocument - DocumentRef.ProductionOrder2_2 - order.
//		* StagesShow - Boolean - output/not output stages to the structure.
//		* Products - CatalogRef.Products - the search value.
//		* Warehouse - CatalogRef.Warehouses - the search value.
//  StorageAddress - String - address of the storage where the result will be placed.
//
Procedure BuildSearchTree(Parameters, StorageAddress) Export
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"Report.ProductionOrderStructureDynamic.SearchInStructure");
	
	DataVolume = BuildSearchTreeInsideTimeMeasurement(Parameters, StorageAddress);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, DataVolume);
	
EndProcedure

Function BuildSearchTreeInsideTimeMeasurement(Parameters, StorageAddress)
	
	If Not ValueIsFilled(Parameters.Products)
		And Not ValueIsFilled(Parameters.Warehouse) Then
		Return 0;
	EndIf;
	
	OrderDocument = Parameters.OrderDocument;
	ProcessType = Parameters.ProcessType;
	StagesShow = Parameters.StagesShow;
	ShowContent = Parameters.ShowContent;
	Purpose = Parameters.Purpose;
	ShowIssues = Parameters.ShowIssues;
	Products = Parameters.Products;
	Warehouse = Parameters.Warehouse;
	StagesOfSelection = Parameters.Stages;
	StagesSelectionOfAnalyst = Parameters.StagesOfAnalytics;
	
	ThisIsDecryptionMode = ValueIsFilled(StagesOfSelection);
	ThisIsRepair = ProcessType = Enums.ProductionProcessTypes.PerformRM;
	ThisIsDisassembly = ProcessType = Enums.ProductionProcessTypes.Disassembly;
	
	ShowIssue = (ThisIsRepair Or ThisIsDisassembly)
		And ShowIssues;
	
	// Selection of the required rows
	QueryTexts = New Array;
	
	QueryTextsOrderedOnTT = ?(ThisIsDecryptionMode,
		QueryTextsLaunchedInTTStages(),
		QueryTextsOrderedOnTT());
	For Each Item In QueryTextsOrderedOnTT Do
		QueryTexts.Add(Item.Value);
	EndDo;
	
	If ThisIsDisassembly Then
		QueryTexts.Add(QueryTextDisassembledFinishedProductsTT());
	Else
		QueryTexts.Add(QueryTextDisassembledFinishedProductsTTSimulation());
	EndIf;
	
	QueryTexts.Add(
		"SELECT
		|	OrderStructure.Products   AS Products,
		|	OrderStructure.Characteristic AS Characteristic,
		|	OrderStructure.Warehouse          AS Warehouse,
		|	OrderStructure.Purpose     AS Purpose,
		|	OrderStructure.KeyLot     AS KeyLot,
		|	OrderStructure.Stage           AS StageLink
		|INTO Table1
		|FROM
		|	InformationRegister.OrderStructure AS OrderStructure
		|WHERE
		|	OrderStructure.ProductionOrder = &OrderDocument
		|	AND OrderStructure.LineKind <> VALUE(Enum.KindsOfProductionOrderStructureLines.ManufacturedProduct)
		|	AND (&Products = VALUE(Catalog.Products.EmptyRef)
		|		OR OrderStructure.Products = &Products)
		|	AND (&Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|		OR OrderStructure.Warehouse = &Warehouse)
		|	AND (&Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|		OR OrderStructure.Purpose = &Purpose)
		|	AND (TRUE IN (&ConditionIsSemiFinishedProduct)
		|		OR &ShowIssue AND OrderStructure.Scheduled <> 0)
		|
		|GROUP BY
		|	OrderStructure.Products,
		|	OrderStructure.Characteristic,
		|	OrderStructure.Warehouse,
		|	OrderStructure.Purpose,
		|	OrderStructure.KeyLot,
		|	OrderStructure.Stage
		|
		|HAVING
		|	SUM(OrderStructure.ToSupply) <> 0
		|	OR SUM(OrderStructure.Done) <> 0
		|	OR SUM(OrderStructure.NotProvide) <> 0
		|	OR (&ShowIssue AND SUM(OrderStructure.Scheduled) > 0)
		|
		|UNION
		|
		|SELECT DISTINCT
		|	Products_1.Products   AS Products,
		|	Products_1.Characteristic AS Characteristic,
		|	Products_1.Recipient     AS Warehouse,
		|	Products_1.Purpose     AS Purpose,
		|	UUID(Products_1.Ref.ProductionLot) AS KeyLot,
		|	Products_1.Ref         AS StageLink
		|FROM
		|	Document.ProductionStage2_2.ManufacturedProducts AS Products_1
		|WHERE
		|	&ShowIssue
		|	AND Products_1.Ref.ReferenceOrder = &OrderDocument
		|	AND Products_1.Ref.Posted
		|	AND (&Products = VALUE(Catalog.Products.EmptyRef)
		|		OR Products_1.Products = &Products)
		|	AND (&Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|		OR Products_1.Recipient = &Warehouse)
		|	AND (&Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|		OR Products_1.Purpose = &Purpose)
		|
		|UNION
		|
		|SELECT DISTINCT
		|	Products_1.Products   AS Products,
		|	Products_1.Characteristic AS Characteristic,
		|	Products_1.Recipient     AS Warehouse,
		|	Products_1.Purpose     AS Purpose,
		|	UUID(Products_1.Ref.ProductionLot) AS KeyLot,
		|	Products_1.Ref         AS StageLink
		|FROM
		|	Document.ProductionStage2_2.SideAndIntermediateRelease AS Products_1
		|WHERE
		|	&ShowIssue
		|	AND Products_1.Ref.ReferenceOrder = &OrderDocument
		|	AND Products_1.Ref.Posted
		|	AND (&Products = VALUE(Catalog.Products.EmptyRef)
		|		OR Products_1.Products = &Products)
		|	AND (&Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|		OR Products_1.Recipient = &Warehouse)
		|	AND (&Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|		OR Products_1.Purpose = &Purpose)
		|
		|INDEX BY
		|	KeyLot
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	Ordered.Products   AS Products,
		|	Ordered.Characteristic AS Characteristic,
		|	Ordered.Warehouse          AS Warehouse,
		|	Ordered.Purpose     AS Purpose
		|FROM
		|	TTOrdered AS Ordered
		|WHERE
		|	(&Products = VALUE(Catalog.Products.EmptyRef) OR Ordered.Products = &Products)
		|	AND (&Warehouse = VALUE(Catalog.Warehouses.EmptyRef) OR Ordered.Warehouse = &Warehouse)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Table.Products   AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse          AS Warehouse,
		|	Table.Purpose     AS Purpose,
		|	Table.KeyLot     AS KeyLot,
		|	Table.StageLink     AS StageLink
		|FROM
		|	Table1 AS Table");
	
	QueryText = StrConcat(QueryTexts, " ; ");
	QueryText = StrReplace(QueryText, "&ConditionIsSemiFinishedProduct", 
		?(ShowContent, "TRUE", QueryTextThisIsASemiFinishedProduct()));
	
	Query = New Query(QueryText);
	Query.TempTablesManager = New TempTablesManager();
	Query.SetParameter("OrderDocument", OrderDocument);
	Query.SetParameter("Products", Products);
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("Purpose", Purpose);
	Query.SetParameter("StagesShow", StagesShow);
	Query.SetParameter("ShowIssue", ShowIssue);
	Query.SetParameter("EmptyLinkKey", New UUID("00000000-0000-0000-0000-000000000000"));
	Query.SetParameter("StatusWorkingSchedule",
		InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule());
	
	If ThisIsDecryptionMode Then
		Query.SetParameter("Stages", StagesOfSelection);
		Query.SetParameter("StageNomenclature", StagesSelectionOfAnalyst.Products);
		Query.SetParameter("StageCharacteristics", StagesSelectionOfAnalyst.Characteristic);
		Query.SetParameter("WarehouseStage", StagesSelectionOfAnalyst.Warehouse);
		Query.SetParameter("StageAppointment", StagesSelectionOfAnalyst.Purpose);
	EndIf;
	
	ResultsArray = Query.ExecuteBatch();
	ManufacturedProduct = ResultsArray[ResultsArray.UBound()-1].Unload();
	Lots = ResultsArray[ResultsArray.UBound()].Unload();
	
	// Traversing the product tree "up" (to products)
	QueryText = 
		"SELECT DISTINCT
		|	OrderStructure.Products        AS Products,
		|	OrderStructure.Characteristic      AS Characteristic,
		|	OrderStructure.Warehouse               AS Warehouse,
		|	OrderStructure.Purpose          AS Purpose,
		|	OrderStructure.ProductionOrder AS ProductionOrder,
		|	OrderStructure.KeyProducts    AS KeyProducts
		|INTO ProductionIssue
		|FROM
		|	InformationRegister.OrderStructure AS OrderStructure
		|WHERE
		|	OrderStructure.KeyLot IN (
		|		SELECT
		|			Table.KeyLot
		|		FROM
		|			SourceTable1 AS Table)
		|	AND OrderStructure.LineKind IN (
		|		VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct),
		|		VALUE(Enum.KindsOfProductionOrderStructureLines.Move))
		|
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose, ProductionOrder, KeyProducts
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	OrderStructure.Products   AS Products,
		|	OrderStructure.Characteristic AS Characteristic,
		|	OrderStructure.Warehouse          AS Warehouse,
		|	OrderStructure.Purpose     AS Purpose,
		|	OrderStructure.KeyLot     AS KeyLot,
		|	OrderStructure.Stage           AS StageLink
		|INTO DestinationTable
		|FROM
		|	InformationRegister.OrderStructure AS OrderStructure
		|WHERE
		|	(OrderStructure.Products, OrderStructure.Characteristic, OrderStructure.Warehouse,
		|		OrderStructure.Purpose, OrderStructure.ProductionOrder, OrderStructure.KeyProducts) IN (
		|		SELECT
		|			ProductionIssue.Products        AS Products,
		|			ProductionIssue.Characteristic      AS Characteristic,
		|			ProductionIssue.Warehouse               AS Warehouse,
		|			ProductionIssue.Purpose          AS Purpose,
		|			ProductionIssue.ProductionOrder AS ProductionOrder,
		|			ProductionIssue.KeyProducts    AS KeyProducts
		|		FROM
		|			ProductionIssue AS ProductionIssue)
		|	AND OrderStructure.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption)
		|
		|INDEX BY
		|	KeyLot
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	Ordered.Products   AS Products,
		|	Ordered.Characteristic AS Characteristic,
		|	Ordered.Warehouse          AS Warehouse,
		|	Ordered.Purpose     AS Purpose
		|FROM
		|	TTOrdered AS Ordered
		|WHERE
		|	Ordered.KeyLot IN (
		|		SELECT
		|			Table.KeyLot
		|		FROM
		|			SourceTable1 AS Table)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Table.Products        AS Products,
		|	Table.Characteristic      AS Characteristic,
		|	Table.Warehouse               AS Warehouse,
		|	Table.Purpose          AS Purpose,
		|	Table.KeyLot          AS KeyLot,
		|	Table.StageLink          AS StageLink
		|FROM
		|	DestinationTable AS Table
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP SourceTable1
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP ProductionIssue";
	
	EvenSample = True;
	While True Do
		
		Query.Text = StrReplace(QueryText, "DestinationTable", ?(EvenSample, "Table2", "Table1"));
		Query.Text = StrReplace(Query.Text, "SourceTable1", ?(EvenSample, "Table1", "Table2"));
		
		ResultsArray = Query.ExecuteBatch();
		SampleProducts = ResultsArray[2].Select();
		While SampleProducts.Next() Do
			FillPropertyValues(ManufacturedProduct.Add(), SampleProducts);
		EndDo;
		
		BatchSelection = ResultsArray[3].Select();
		If BatchSelection.Count() = 0 Then
			Break;
		Else
			While BatchSelection.Next() Do
				FillPropertyValues(Lots.Add(), BatchSelection);
			EndDo;
		EndIf;
		
		EvenSample = Not EvenSample;
		
	EndDo;
	
	ManufacturedProduct.GroupBy("Products, Characteristic, Warehouse, Purpose");
	ManufacturedProduct.Indexes.Add("Products, Characteristic, Warehouse, Purpose");
	
	Lots.GroupBy("Products, Characteristic, Warehouse, Purpose, KeyLot, StageLink");
	Lots.Indexes.Add("KeyLot, StageLink");
	Lots.Indexes.Add("Products, Characteristic, Purpose, KeyLot");
	Lots.Indexes.Add("Products, Characteristic, Warehouse, Purpose, KeyLot");
	
	TheStructureOfTheSearch1 = New Structure("Products, Characteristic, Warehouse, Purpose");
	TheStructureOfTheSearch2 = New Structure("KeyLot, StageLink");
	TheStructureOfTheSearch3 = New Structure("Products, Characteristic, Purpose, KeyLot");
	TheStructureOfTheSearch4 = New Structure("Products, Characteristic, Warehouse, Purpose, KeyLot");
	
	// Formation of the result
	QueueToFillIn = New ValueTable();
	QueueToFillIn.Columns.Add("RowsDestination", New TypeDescription("ValueTreeRowCollection"));
	QueueToFillIn.Columns.Add("StringsSources", New TypeDescription("ValueTreeRowCollection"));
	QueueToRead = New Array;
	PartyKeys = New Array;
	
	Result = New_Tree();
	
	NewLineQueue = QueueToFillIn.Add();
	NewLineQueue.RowsDestination = Result.Rows;
	NewLineQueue.StringsSources = TreeOrder(Parameters).Rows;
	
	While QueueToFillIn.Count() > 0 Or QueueToRead.Count() > 0 Do
		
		QueueIndex = 0;
		While QueueIndex < QueueToFillIn.Count() Do
			
			String = QueueToFillIn[QueueIndex];
			
			For Each SourceRow In String.StringsSources Do
				
				DescendantOfSearch = String.RowsDestination.Parent <> Undefined
					And String.RowsDestination.Parent.SearchString;
				DescendantOfSearchItem = String.RowsDestination.Parent <> Undefined
					And (String.RowsDestination.Parent.SearchString
						And (String.RowsDestination.Parent.RowType = LineTypeProduct()
							Or String.RowsDestination.Parent.RowType = LineTypeDecryptionNomenclature())
						Or String.RowsDestination.Parent.DescendantOfSearchItem);
				
				AddRow = True;
				If SourceRow.RowType = LineTypeLaunchOrder() Then
					AddRow = DescendantOfSearch;
				ElsIf SourceRow.RowType = RowTypeInternal()
					Or DescendantOfSearch
					Or DescendantOfSearchItem Then
					AddRow = True;
				Else
					If SourceRow.RowType = LineTypeProduct()
							Or SourceRow.RowType = LineTypeDecryptionNomenclature() Then
						FillPropertyValues(TheStructureOfTheSearch1, SourceRow);
						FoundRows = ManufacturedProduct.FindRows(TheStructureOfTheSearch1);
					ElsIf SourceRow.RowType = StringTypeStructureStage()
						Or SourceRow.RowType = LineTypeStageDocument() Then
						FillPropertyValues(TheStructureOfTheSearch2, SourceRow);
						FoundRows = Lots.FindRows(TheStructureOfTheSearch2);
					ElsIf SourceRow.MultipleWarehouses Then
						FillPropertyValues(TheStructureOfTheSearch3, SourceRow);
						FoundRows = Lots.FindRows(TheStructureOfTheSearch3);
					Else
						FillPropertyValues(TheStructureOfTheSearch4, SourceRow);
						FoundRows = Lots.FindRows(TheStructureOfTheSearch4);
					EndIf;
					AddRow = FoundRows.UBound() <> -1;
				EndIf;
				If Not AddRow Then
					Continue;
				EndIf;
				
				NewRow = String.RowsDestination.Add();
				FillPropertyValues(NewRow, SourceRow);
				
				NewRow.SearchString = (Not ValueIsFilled(Warehouse) Or Warehouse = NewRow.Warehouse)
					And (Not ValueIsFilled(Products) Or Products = NewRow.Products);
				NewRow.DescendantOfSearchItem = DescendantOfSearchItem;
				
				If NewRow.FinishTree
					And Not NewRow.SearchString
					And Not DescendantOfSearch
					And Not DescendantOfSearchItem Then
					QueueToRead.Add(NewRow);
				EndIf;
				
				If SourceRow.Rows.Count() > 0 Then
					NewLineQueue = QueueToFillIn.Add();
					NewLineQueue.RowsDestination = NewRow.Rows;
					NewLineQueue.StringsSources = SourceRow.Rows;
				EndIf;
				
			EndDo;
			
			QueueIndex = QueueIndex + 1;
			
		EndDo;
		QueueToFillIn.Clear();
		
		For Each String In QueueToRead Do
			
			PartyKeys.Clear();
				
			For DescendantIndex = -String.Rows.Count()+1 To 0 Do
				DescendantString = String.Rows[-DescendantIndex];
				If DescendantString.RowType = RowTypeInternal() Then
					PartyKeys.Add(DescendantString.KeyLot);
					String.Rows.Delete(-DescendantIndex);
				EndIf;
			EndDo;
			
			NewLineQueue = QueueToFillIn.Add();
			NewLineQueue.RowsDestination = String.Rows;
			NewLineQueue.StringsSources = TreeOfSemiFinishedProducts(
				OrderDocument, PartyKeys, String.StageLink, Parameters, Purpose).Rows;
			
			String.FinishTree = False;
			
		EndDo;
		QueueToRead.Clear();
		
	EndDo;
	
	PutToTempStorage(Result, StorageAddress);
	
	RowsCount = 0;
	Queue = New Array;
	For Each String In Result.Rows Do
		Queue.Add(String);
	EndDo;
	IndexOf = 0;
	While IndexOf <= Queue.UBound() Do
		RowsCount = RowsCount + 1;
		For Each String In Queue[IndexOf].Rows Do
			Queue.Add(String);
		EndDo;
		IndexOf = IndexOf + 1;
	EndDo;
	Return RowsCount;
	
EndFunction

// Completes the semi-finished products tree.
// 
// Parameters:
//  OrderDocument - DocumentRef.ProductionOrder2_2 - OrderDocument
//  PartyKeys - Array of UUID - Party Keys
//  Stage - CatalogRef.ProductionStages, DocumentRef.ProductionStage2_2 - Stage
//  Parameters - Structure
//  Purpose - CatalogRef.Assignments
// 
// Returns:
//  ValueTree - The Tree of Semi-Finished Products:
// * Products - CatalogRef.Products - 
// * Characteristic - CatalogRef.ItemsCharacteristics - 
// * Warehouse - CatalogRef.BusinessStructure, CatalogRef.Warehouses - 
// * WarehouseDivision - CatalogRef.BusinessStructure, CatalogRef.Warehouses - 
// * Purpose - CatalogRef.Assignments - 
// * ItemsType - EnumRef.ItemsTypes - 
// * Quality - EnumRef.QualityLevels - 
// * KeyLot - UUID - 
// * KeyProducts - UUID - 
// * LineNumber - Number - 
// * LinePresentation - String - 
// * UnitOfMeasure - CatalogRef.PackagesAndUnitsOfMeasure - 
// * Department - CatalogRef.BusinessStructure - 
// * Begin - Date - 
// * Ending - Date - 
// * DesiredDate - Date - 
// * PictureNumber - Number - 
// * RowType - Number - 
// * Required2 - Number - 
// * Launched - Number - 
// * Done - Number - 
// * Left - Number - 
// * Supplied - Number - 
// * SecuredInterest - Number - 
// * NotProvide - Boolean - 
// * BillOfMaterials - CatalogRef.BillsOfMaterials - 
// * StageLink - CatalogRef.ProductionStages, DocumentRef.ProductionStage2_2 - 
// * ProductionLot - CatalogRef.ProductionLots - 
// * StageNumber - Number - 
// * NextStageNo - Number - 
// * FinishTree - Boolean - 
// * SearchString - Boolean - 
// * IndexOfImageIsStillFreeOrNotNeeded - Number - 
// * IndexOfImageRemainsForOtherPurposes - Number - 
// * IndexOfImageRemainsInAnotherWarehouse - Number - 
// * IndexOfImageLeft - Number - 
// * LaunchOrder - DocumentRef.ProductionOrder2_2 - 
// * ProductionByThirdParty - Boolean - 
// * MultipleWarehouses - Boolean - 
// * MultipleSpecifications - Boolean - 
// * SupplyIsRequired - Boolean - 
// * Canceled - Boolean - 
//
Function TreeOfSemiFinishedProducts(OrderDocument, PartyKeys, Stage, Parameters, Purpose) Export
	
	ProcessType = Parameters.ProcessType;
	StagesShow = Parameters.StagesShow;
	ShowMovements = Parameters.ShowMovements;
	ShowContent = Parameters.ShowContent;
	ShowIssues = Parameters.ShowIssues;
	
	ThisIsRepair = ProcessType = Enums.ProductionProcessTypes.PerformRM;
	ThisIsDisassembly = ProcessType = Enums.ProductionProcessTypes.Disassembly;
	
	ShowIssue = (ThisIsRepair Or ThisIsDisassembly)
		And ShowIssues;
	
	QueryTexts = New ValueList;
	
	If ThisIsDisassembly Then
		QueryTexts.Add(QueryTextDisassembledFinishedProductsTT());
	Else
		QueryTexts.Add(QueryTextDisassembledFinishedProductsTTSimulation());
	EndIf;
	
	FilterCriterion = "OrderStructure.KeyLot IN (&PartyKeys)";
	If ValueIsFilled(Stage) Then
		FilterCriterion = FilterCriterion + " AND OrderStructure.Stage = &Stage";
	EndIf;
	QueryTexts.Add(TextOfRequestNeedsTT(FilterCriterion, ShowContent));
	
	FilterCriterion = 
		"SELECT
		|	Demands.Products        AS Products,
		|	Demands.Characteristic      AS Characteristic,
		|	Demands.ProductionOrder AS ProductionOrder,
		|	Demands.KeyProducts    AS ConnectionKeyTransfer
		|FROM
		|	TTNeed AS Demands";
	QueryTexts.Add(TextOfRequestReplacementKeyProductTT(FilterCriterion, ""));
	
	For Each Item In QueryTextsSupplyTT() Do
		QueryTexts.Add(Item.Value);
	EndDo;
	
	FilterCriterion = 
		"SELECT
		|	OrderStructure.Products        AS Products,
		|	OrderStructure.Characteristic      AS Characteristic,
		|	OrderStructure.ProductionOrder AS ProductionOrder,
		|	OrderStructure.KeyProducts    AS ConnectionKeyTransfer
		|FROM
		|	InformationRegister.OrderStructure AS OrderStructure
		|WHERE
		|	OrderStructure.KeyLot IN(
		|		SELECT
		|			T.KeyLot
		|		FROM
		|			TTSoftware AS T
		|		WHERE
		|			NOT T.IsReserve)
		|	AND OrderStructure.LineKind IN(
		|		VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption))
		|	AND TRUE IN(&ConditionIsSemiFinishedProduct)";
	FilterCriterion = StrReplace(FilterCriterion, "&ConditionIsSemiFinishedProduct", 
		?(ShowContent, "TRUE", QueryTextThisIsASemiFinishedProduct()));
	QueryTexts.Add(TextOfRequestReplacementKeyProductTT(FilterCriterion, "SemiFinishedProducts"));
	
	SelectionOfSecurityParties = 
		"OrderStructure.KeyLot IN
		|		(SELECT
		|			T.KeyLot
		|		FROM
		|			TTSoftware AS T
		|		WHERE
		|			NOT T.IsReserve)";
	
	QueryText = TextOfRequestIsPercentageOfCollateralTT(SelectionOfSecurityParties, ShowContent, "SemiFinishedProducts", "SemiFinishedProducts");
	QueryTexts.Add(QueryText);
	
	If StagesShow Then
		QueryTexts.Add(QueryTextKeysOfLotReferencesOfStagesSupplyOfTT());
		
		QueryText = TextOfRequestIsPercentageOfProvisionOfTTStages(SelectionOfSecurityParties, ShowContent, "SemiFinishedProducts", "SemiFinishedProducts");
		QueryTexts.Add(QueryText);
		
		QueryText = QueryTextStages("TTKeysOfLotReferencesOfStagesSupply", "TTBatchSize", ProcessType);
		QueryTexts.Add(QueryText, "Stages");
		
		QueryText = RequestTextPercentageOfStageProvision("SemiFinishedProducts");
		QueryTexts.Add(QueryText, "PercentageOfCollateralStages");
	EndIf;
	
	If ShowIssue Or ThisIsRepair Then
		FilterCriterion = "OrderStructure.KeyLot IN (&PartyKeys)";
		For Each Item In QueryTextsTTIssue(FilterCriterion, StagesShow, "1") Do
			QueryTexts.Add(Item.Value);
		EndDo;
	Else
		QueryTexts.Add(QueryTextIssueOfTTSimulation("1"));
	EndIf;
	
	If ShowIssue Then
		QueryTexts.Add(QueryTextProductionIssue("1", ValueIsFilled(Stage)), "ProductionIssue");
		
		FilterCriterion = 
			"OrderStructure.KeyLot IN
			|	(SELECT
			|		T.KeyLot AS KeyLot
			|	FROM
			|		TTSoftware AS T)";
		For Each Item In QueryTextsTTIssue(FilterCriterion, StagesShow, "2") Do
			QueryTexts.Add(Item.Value);
		EndDo;
		QueryTexts.Add(QueryTextIssueMinimized("2"), "IssueMinimized");
	EndIf;
	
	QueryTexts.Add(QueryTextDemand(ShowContent, "TTIssue1", ProcessType), "Demands");
	QueryTexts.Add(QueryTextSupply(ProcessType), "Supply");
	AddQueryTextsForInventoryAllocation(QueryTexts);
	QueryTexts.Add(QueryTextBalancesForOtherPurposes(), "BalancesForOtherPurposes");
	QueryTexts.Add(RequestTextNeedCollapsed(ShowContent), "NeedsAreMinimized");
	QueryTexts.Add(QueryTextPercentageOfCollateral("SemiFinishedProducts"), "PercentageOfCollateral");
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager();
	Query.SetParameter("OrderDocument", OrderDocument);
	Query.SetParameter("PartyKeys", PartyKeys);
	Query.SetParameter("Stage", Stage);
	Query.SetParameter("StagesShow", StagesShow);
	Query.SetParameter("ShowMovements", ShowMovements);
	Query.SetParameter("Purpose", Purpose);
	Query.SetParameter("EmptyLinkKey", New UUID("00000000-0000-0000-0000-000000000000"));
	Query.SetParameter("StatusWorkingSchedule",
		InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule());
	
	SetPrivilegedMode(True);
	Tables = TMCommonUse.UploadResultsOfQuery(Query, QueryTexts,, True, False);
	SetPrivilegedMode(False);
	
	Stages = ?(StagesShow, Tables.Stages, Undefined); // ValueTable
	PercentageOfCollateralStages = ?(StagesShow, Tables.PercentageOfCollateralStages, Undefined); // ValueTable
	Demands = Tables.Demands; // ValueTable - Requirements for Level 1 PF
	Supply = Tables.Supply; // ValueTable - Provision Of Level 1 Needs
	BalancesForOtherPurposes = Tables.BalancesForOtherPurposes; // ValueTable
	NeedsAreMinimized = Tables.NeedsAreMinimized; // ValueTable - Requirements for PF level 2
	PercentageOfCollateral = Tables.PercentageOfCollateral; // ValueTable
	ProductionIssue = ?(ShowIssue, Tables.ProductionIssue, Undefined); // ValueTable
	IssueMinimized = ?(ShowIssue, Tables.IssueMinimized, Undefined); // ValueTable
	
	Query.Text = QueryTextReleaseOfCollateralBatches(SelectionOfSecurityParties);
	ReleaseOfCollateralBatches = ReleaseTreeOfSoftwareBatches(Query.Execute());
	
	Supply.Indexes.Add("KeyProducts");
	BalancesForOtherPurposes.Indexes.Add("Products, Characteristic, Warehouse, Purpose");
	PercentageOfCollateral.Indexes.Add("KeyLot");
	
	If StagesShow Then
		NeedsAreMinimized.Indexes.Add("KeyLot, StageLink");
		Stages.Indexes.Add("KeyLot");
		PercentageOfCollateralStages.Indexes.Add("KeyLot, StageLink");
		If ShowIssue Then
			IssueMinimized.Indexes.Add("KeyLot, StageLink");
		EndIf;
	Else
		NeedsAreMinimized.Indexes.Add("KeyLot");
		If ShowIssue Then
			IssueMinimized.Indexes.Add("KeyLot");
		EndIf;
	EndIf;
	
	Result = New_Tree();
	
	// Descendants of the 1st level
	Children = New Array;
	For IndexOf = 0 To Demands.Count() - 1 Do
		NeedString = Demands[IndexOf];
		
		TreeRow = FillInSemiFinishedProductLine(
			Result.Rows, NeedString, Supply, PercentageOfCollateral, ReleaseOfCollateralBatches, BalancesForOtherPurposes, ShowMovements);
		FindNeedsAddStages(TreeRow, NeedsAreMinimized, IssueMinimized, Stages, PercentageOfCollateralStages, StagesShow, Children);
	EndDo;
	
	If ShowIssue Then
		For Each ReleaseString In ProductionIssue Do
			TreeRow = Result.Rows.Add();
			FillInProductionIssueRow(TreeRow, ReleaseString);
		EndDo;
		Result.Rows.Sort("ThisIsASemiFinishedProduct Desc, LinePresentation, ThisIsRelease Desc");
	EndIf;
	
	// Descendants of the 2nd level
	For Each Child In Children Do
		For Each StringPotebnost In Child.Demands Do
			OwnerLines = Child.Owner.Rows; // ValueTreeRowCollection
			TreeRow = OwnerLines.Add();
			TreeRow.RowType = RowTypeInternal();
			TreeRow.KeyLot = StringPotebnost.KeyLot;
			Child.Owner.FinishTree = True;
		EndDo;
		If ShowIssue Then
			For Each ReleaseString In Child.ProductionIssue Do
				OwnerLines = Child.Owner.Rows; // ValueTreeRowCollection
				TreeRow = OwnerLines.Add();
				TreeRow.RowType = RowTypeInternal();
				TreeRow.KeyLot = ReleaseString.KeyLot;
				Child.Owner.FinishTree = True;
			EndDo;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

// Generates a complete order structure from the specified nodes.
//
// Parameters:
//	Parameters - Structure - data reading parameters. Contains:
//		* OrderDocument - DocumentRef.ProductionOrder2_2 - order.
//		* StagesShow - Boolean - output/not output stages to the structure.
//		* Nodes - Map -  the ID of the tree row is passed as the key,
//			as a value - an array of item keys.
//		* PortionSelection - Boolean - if True, a limited number of nodes (1000 pcs) will be read.
//  StorageAddress - String - address of the storage where the result will be placed.
//
Procedure Expand_AllLevels(Parameters, StorageAddress) Export
	
	Nodes = New Map;
	
	TreeRows = New Array;
	RowsCount = 0;
	
	For Each Node In Parameters.Nodes Do
		
		Tree = New_Tree();
		
		FillTreeRecursively(
			Tree.Rows,
			TreeOfSemiFinishedProducts(Parameters.OrderDocument, Node.Value.PartyKeys, Node.Value.Stage, Parameters, Parameters.Purpose).Rows,
			TreeRows);
		
		Nodes.Insert(Node.Key, Tree);
		
		If Parameters.PortionSelection Then
			RowsCount = RowsCount + RowsCount(Tree.Rows);
			If RowsCount >= SamplePortionSize() Then
				Break;
			EndIf;
		EndIf;
		
	EndDo;
	
	PartyKeys = New Array;
	
	While TreeRows.UBound() <> -1 Do
		
		If Parameters.PortionSelection
			And RowsCount >= SamplePortionSize() Then
			Break;
		EndIf;
		
		For IndexOf = -TreeRows.UBound() To 0 Do
			
			TreeRow = TreeRows[-IndexOf];
			
			PartyKeys.Clear();
			
			For DescendantIndex = -TreeRow.Rows.Count()+1 To 0 Do
				DescendantString = TreeRow.Rows[-DescendantIndex];
				If DescendantString.RowType = RowTypeInternal() Then
					PartyKeys.Add(DescendantString.KeyLot);
					TreeRow.Rows.Delete(-DescendantIndex);
				EndIf;
			EndDo;
			
			FillTreeRecursively(
				TreeRow.Rows,
				TreeOfSemiFinishedProducts(Parameters.OrderDocument, PartyKeys, TreeRow.StageLink, Parameters, Parameters.Purpose).Rows,
				TreeRows);
			
			TreeRow.FinishTree = False;
			
			TreeRows.Delete(-IndexOf);
			
			If Parameters.PortionSelection Then
				RowsCount = RowsCount + RowsCount(TreeRow.Rows);
				If RowsCount >= SamplePortionSize() Then
					Break;
				EndIf;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	AllDataIsSelected = Nodes.Count() = Parameters.Nodes.Count()
		And TreeRows.UBound() = -1;
	
	PutToTempStorage(
		New Structure("Nodes, AllDataIsSelected", Nodes, AllDataIsSelected),
		StorageAddress);
	
EndProcedure

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ProductionOrderStructureDynamic);
	TMReportOptionsOverridable.DisableReport(DescriptionOfReport);
	
EndProcedure

#EndRegion

#Region Other

// Adds work to the planning stage of work, as well as (optionally) repaired finished products to the Reverse kit and kit stages.
//
// Parameters:
//  Parameters - Structure:
//   * OrderDocument - DocumentRef.ProductionOrder2_2
//   * Stage - DocumentRef.ProductionStage2_2 - the work planning stage.
//   * KeyLot - UUID - the key of the stage Lot reference.
//   * Works - ValueTable - a table with works and repaired finished products.
//   * StagesOfReverseKittingKitting - Array of DocumentRef.ProductionStage2_2 - Reverse kitting and kitting steps that can be changed during the addition process
//   * ThisIsASemiFinishedProduct - Boolean - if False, the works are added to the Lot reference, providing the need for the order.
//   * OutputParameters - Structure - parameters for the formation of the order tree /tree of semi-finished products.
//   * Purpose - CatalogRef.Assignments - purpose.
//  ResultAddress - String - the address for saving the result of the procedure.
Procedure AddWorksAndRepairedFinishedProductsOnHold(Parameters, ResultAddress) Export
	
	Documents.ProductionStage2_2.AddWorksAndRepairedFinishedProducts(Parameters.Stage, Parameters.Works);
	
	If Parameters.ThisIsASemiFinishedProduct Then
		Tree = New_Tree();
		
		NewRow = Tree.Rows.Add();
		NewRow.RowType = LineTypeStageDocument();
		NewRow.StageLink = Parameters.Stage;
		
		TreeOfSemiFinishedProducts = TreeOfSemiFinishedProducts(
			Parameters.OrderDocument,
			Parameters.KeyLot,
			Parameters.Stage,
			Parameters.OutputParameters,
			Parameters.Purpose);
		FillTreeRecursively(NewRow.Rows, TreeOfSemiFinishedProducts.Rows, New Array);
		
		For Each StageLink In Parameters.StagesOfReverseKittingKitting Do
			
			If Not ValueIsFilled(StageLink) Then
				Continue;
			EndIf;
			
			NewRow = Tree.Rows.Add();
			NewRow.RowType = LineTypeStageDocument();
			NewRow.StageLink = StageLink;
			
			TreeOfSemiFinishedProducts = TreeOfSemiFinishedProducts(
				Parameters.OrderDocument,
				Parameters.KeyLot,
				StageLink,
				Parameters.OutputParameters,
				Parameters.Purpose);
			FillTreeRecursively(NewRow.Rows, TreeOfSemiFinishedProducts.Rows, New Array);
			
		EndDo;
		
	Else
		Tree = TreeOrder(Parameters.OutputParameters);
	EndIf;
	
	PutToTempStorage(Tree, ResultAddress)
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region TreeFormation

Function TreeOrder(Parameters)
	
	OrderDocument = Parameters.OrderDocument;
	ProcessType = Parameters.ProcessType;
	StagesShow = Parameters.StagesShow;
	ShowContent = Parameters.ShowContent;
	ShowMovements = Parameters.ShowMovements;
	ShowIssues = Parameters.ShowIssues;
	Purpose = Parameters.Purpose;
	StagesOfSelection = Parameters.Stages;
	StagesSelectionOfAnalyst = Parameters.StagesOfAnalytics;
	
	ThisIsRepair = ProcessType = Enums.ProductionProcessTypes.PerformRM;
	ThisIsDisassembly = ProcessType = Enums.ProductionProcessTypes.Disassembly;

	ThisIsDecryptionMode = ValueIsFilled(StagesOfSelection);
	ShowIssue = (ThisIsRepair Or ThisIsDisassembly)
		And ShowIssues;
	
	QueryTexts = New ValueList;
	
	TextsOrderedOnTT = ?(ThisIsDecryptionMode,
		QueryTextsLaunchedInTTStages(),
		QueryTextsOrderedOnTT());
	For Each Item In TextsOrderedOnTT Do
		QueryTexts.Add(Item.Value);
	EndDo;
	
	If ThisIsDisassembly Then
		QueryTexts.Add(QueryTextDisassembledFinishedProductsTT());
	Else
		QueryTexts.Add(QueryTextDisassembledFinishedProductsTTSimulation());
	EndIf;
	
	FilterCriterion = 
		"OrderStructure.KeyLot IN
		|	(SELECT
		|		T.KeyLot AS KeyLot
		|	FROM
		|		TTOrdered AS T)";
	If ThisIsDisassembly Then
		FilterCriterion = FilterCriterion + 
			" AND (OrderStructure.Products, OrderStructure.Characteristic) NOT IN
			|	(SELECT
			|		T.Products,
			|		T.Characteristic
			|	FROM
			|		TTDisassembledFinishedProducts AS T)";
	EndIf;
	QueryTexts.Add(TextOfRequestNeedsTT(FilterCriterion, ShowContent));
	
	FilterCriterion = 
		"SELECT
		|	Demands.Products        AS Products,
		|	Demands.Characteristic      AS Characteristic,
		|	Demands.ProductionOrder AS ProductionOrder,
		|	Demands.KeyProducts    AS ConnectionKeyTransfer
		|FROM
		|	TTNeed AS Demands";
	QueryTexts.Add(TextOfRequestReplacementKeyProductTT(FilterCriterion, ""));
	
	For Each Item In QueryTextsSupplyTT() Do
		QueryTexts.Add(Item.Value);
	EndDo;
	
	FilterCriterion = 
		"SELECT
		|	OrderStructure.Products        AS Products,
		|	OrderStructure.Characteristic      AS Characteristic,
		|	OrderStructure.ProductionOrder AS ProductionOrder,
		|	OrderStructure.KeyProducts    AS ConnectionKeyTransfer
		|FROM
		|	InformationRegister.OrderStructure AS OrderStructure
		|WHERE
		|	OrderStructure.KeyLot IN(
		|		SELECT
		|			T.KeyLot
		|		FROM
		|			TTSoftware AS T
		|		WHERE
		|			NOT T.IsReserve)
		|	AND OrderStructure.LineKind IN(
		|		VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption))
		|	AND TRUE IN(&ConditionIsSemiFinishedProduct)";
	FilterCriterion = StrReplace(FilterCriterion, "&ConditionIsSemiFinishedProduct", 
		?(ShowContent, "TRUE", QueryTextThisIsASemiFinishedProduct()));
	QueryTexts.Add(TextOfRequestReplacementKeyProductTT(FilterCriterion, "SemiFinishedProducts"));
	
	SelectionOfBatchesToEnsureOrder = 
		"OrderStructure.KeyLot IN
		|	(SELECT
		|		T.KeyLot AS KeyLot
		|	FROM
		|		TTOrdered AS T)";
	SelectionOfSecurityParties = 
		"OrderStructure.KeyLot IN
		|	(SELECT
		|		T.KeyLot AS KeyLot
		|	FROM
		|		TTSoftware AS T
		|	WHERE
		|		NOT T.IsReserve)";
	
	QueryText = TextOfRequestIsPercentageOfCollateralTT(SelectionOfBatchesToEnsureOrder, ShowContent, "Products_1", "");
	QueryTexts.Add(QueryText);
	
	QueryText = TextOfRequestIsPercentageOfCollateralTT(SelectionOfSecurityParties, ShowContent, "SemiFinishedProducts", "SemiFinishedProducts");
	QueryTexts.Add(QueryText);
	
	QueryTexts.Add(QueryTextKeysOfLotReferencesOfStagesOrderedTT());
	QueryTexts.Add(QueryTextKeysOfLotReferencesOfStagesSupplyOfTT());
	
	If StagesShow Then
		QueryText = TextOfRequestIsPercentageOfProvisionOfTTStages(SelectionOfBatchesToEnsureOrder, ShowContent, "Products_1", "");
		QueryTexts.Add(QueryText);
		
		QueryText = TextOfRequestIsPercentageOfProvisionOfTTStages(SelectionOfSecurityParties, ShowContent, "SemiFinishedProducts", "SemiFinishedProducts");
		QueryTexts.Add(QueryText);
		
		QueryText = QueryTextStages("TTKeysOfLotReferencesOfStagesOrdered", "TTBatchSizeOrder", ProcessType);
		QueryTexts.Add(QueryText, "Stages1");
		
		QueryText = QueryTextStages("TTKeysOfLotReferencesOfStagesSupply", "TTBatchSize", ProcessType);
		QueryTexts.Add(QueryText, "Stages2");
		
		QueryText = RequestTextPercentageOfStageProvision("Products_1");
		QueryTexts.Add(QueryText, "PercentageOfCollateralStages1");
		
		QueryText = RequestTextPercentageOfStageProvision("SemiFinishedProducts");
		QueryTexts.Add(QueryText, "PercentageOfCollateralStages2");
	EndIf;
	
	If ShowIssue Or ThisIsRepair Then
		FilterCriterion = 
			"OrderStructure.KeyLot IN
			|	(SELECT
			|		T.KeyLot AS KeyLot
			|	FROM
			|		TTKeysOfLotReferencesOfStagesOrdered AS T)";
		For Each Item In QueryTextsTTIssue(FilterCriterion, StagesShow, "1") Do
			QueryTexts.Add(Item.Value);
		EndDo;
	Else
		QueryTexts.Add(QueryTextIssueOfTTSimulation("1"));
	EndIf;
	
	If ShowIssue Then
		QueryTexts.Add(QueryTextProductionIssue("1", False), "ProductionIssue1");
		
		FilterCriterion = 
			"OrderStructure.KeyLot IN
			|	(SELECT
			|		T.KeyLot AS KeyLot
			|	FROM
			|		TTKeysOfLotReferencesOfStagesSupply AS T)";
		For Each Item In QueryTextsTTIssue(FilterCriterion, StagesShow, "2") Do
			QueryTexts.Add(Item.Value);
		EndDo;
		QueryTexts.Add(QueryTextIssueMinimized("2"), "ProductionIssue2");
	EndIf;
	
	QueryTexts.Add(QueryTextOrdered(), "Ordered");
	QueryTexts.Add(QueryTextSecuringOrder(ProcessType), "SecuringOrder");
	QueryTexts.Add(QueryTextBalanceOfClosedOrder(), "BalanceOfClosedOrder");
	QueryTexts.Add(QueryTextDemand(ShowContent, "TTIssue1", ProcessType), "Demands1");
	QueryTexts.Add(QueryTextSupply(ProcessType), "Supply");
	AddQueryTextsForInventoryAllocation(QueryTexts);
	QueryTexts.Add(QueryTextBalancesForOtherPurposes(), "BalancesForOtherPurposes");
	QueryTexts.Add(RequestTextNeedCollapsed(ShowContent), "Demands2");
	QueryTexts.Add(QueryTextPercentageOfCollateral("Products_1"), "PercentageOfOrderSecurity");
	QueryTexts.Add(QueryTextPercentageOfCollateral("SemiFinishedProducts"), "PercentageOfCollateral");
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager();
	Query.SetParameter("OrderDocument", OrderDocument);
	Query.SetParameter("StagesShow", StagesShow);
	Query.SetParameter("ShowMovements", ShowMovements);
	Query.SetParameter("Purpose", Purpose);
	Query.SetParameter("EmptyLinkKey", New UUID("00000000-0000-0000-0000-000000000000"));
	Query.SetParameter("TheProductionScheduleIsUsed", 
		ProductionManagementCached.TheProductionScheduleIsUsed());
	Query.SetParameter("StatusWorkingSchedule",
		InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule());
	If ThisIsDecryptionMode Then
		Query.SetParameter("Stages", StagesOfSelection);
		Query.SetParameter("StageNomenclature", StagesSelectionOfAnalyst.Products);
		Query.SetParameter("StageCharacteristics", StagesSelectionOfAnalyst.Characteristic);
		Query.SetParameter("WarehouseStage", StagesSelectionOfAnalyst.Warehouse);
		Query.SetParameter("StageAppointment", StagesSelectionOfAnalyst.Purpose);
	EndIf;
	
	SetPrivilegedMode(True);
	Tables = TMCommonUse.UploadResultsOfQuery(Query, QueryTexts,, True, False);
	SetPrivilegedMode(False);
	
	Stages1 = ?(StagesShow, Tables.Stages1, Undefined); // ValueTable
	Stages2 = ?(StagesShow, Tables.Stages2, Undefined); // ValueTable
	PercentageOfCollateralStages1 = ?(StagesShow, Tables.PercentageOfCollateralStages1, Undefined);
	PercentageOfCollateralStages2 = ?(StagesShow, Tables.PercentageOfCollateralStages2, Undefined);
	Ordered = Tables.Ordered; // ValueTable - Order Needs
	SecuringOrder = Tables.SecuringOrder; // ValueTable - Ensuring the needs of the order
	BalanceOfClosedOrder = Tables.BalanceOfClosedOrder; // ValueTable
	Demands1 = Tables.Demands1; // ValueTable - Requirements for Level 1 PF
	Demands2 = Tables.Demands2; // ValueTable - Requirements for PF level 2
	Supply = Tables.Supply; // ValueTable - Provision Of Level 1 Needs
	BalancesForOtherPurposes = Tables.BalancesForOtherPurposes; // ValueTable
	PercentageOfOrderSecurity = Tables.PercentageOfOrderSecurity; // ValueTable
	PercentageOfCollateral = Tables.PercentageOfCollateral; // ValueTable
	ProductionIssue1 = ?(ShowIssue, Tables.ProductionIssue1, Undefined); // ValueTable
	ProductionIssue2 = ?(ShowIssue, Tables.ProductionIssue2, Undefined); // ValueTable
	
	QueryTexts.Clear();
	QueryTexts.Add(QueryTextReleaseOfCollateralBatches(SelectionOfBatchesToEnsureOrder));
	QueryTexts.Add(QueryTextReleaseOfCollateralBatches(SelectionOfSecurityParties));
	
	Query.Text = StrConcat(QueryTexts.UnloadValues(), ";");
	QueryResults = Query.ExecuteBatch();
	ReleaseOfBatchesOfCollateralOrder = ReleaseTreeOfSoftwareBatches(QueryResults[0]);
	ReleaseOfCollateralBatches = ReleaseTreeOfSoftwareBatches(QueryResults[1]);
	
	SecuringOrder.Indexes.Add("KeyProducts");
	Supply.Indexes.Add("KeyProducts");
	BalancesForOtherPurposes.Indexes.Add("Products, Characteristic, Warehouse, Purpose");
	PercentageOfOrderSecurity.Indexes.Add("KeyLot");
	PercentageOfCollateral.Indexes.Add("KeyLot");
	
	If StagesShow Then
		Demands1.Indexes.Add("KeyLot, StageLink");
		Demands2.Indexes.Add("KeyLot, StageLink");
		Stages1.Indexes.Add("KeyLot");
		Stages2.Indexes.Add("KeyLot");
		If ShowIssue Then
			ProductionIssue1.Indexes.Add("KeyLot, StageLink");
			ProductionIssue2.Indexes.Add("KeyLot, StageLink");
		EndIf;
	Else
		Demands1.Indexes.Add("KeyLot");
		Demands2.Indexes.Add("KeyLot");
		If ShowIssue Then
			ProductionIssue1.Indexes.Add("KeyLot");
			ProductionIssue2.Indexes.Add("KeyLot");
		EndIf;
	EndIf;
	
	Result = New_Tree();
	
	// Order Item
	Children1 = New Array;
	For IndexOf = 0 To Ordered.Count() - 1 Do
		LineOrdered = Ordered[IndexOf];
		
		TreeRow = Result.Rows.Add();
		FillInProductLine(TreeRow, LineOrdered, SecuringOrder, PercentageOfOrderSecurity, ReleaseOfBatchesOfCollateralOrder, ThisIsDecryptionMode);
		FindNeedsAddStages(TreeRow, Demands1, ProductionIssue1, Stages1, PercentageOfCollateralStages1, StagesShow, Children1);
		
		If ThisIsDecryptionMode Then
			TreeRow.RowType = LineTypeDecryptionNomenclature();
		EndIf;
	EndDo;
	
	// Distribution of the Balance of the closed order
	If BalanceOfClosedOrder.Count() > 0 Then
		Result.Rows.Sort("DesiredDate Desc");
		
		BalanceOfClosedOrder.Indexes.Add("Products, Characteristic, Warehouse, Purpose");
		TheStructureOfTheSearch = New Structure("Products, Characteristic, Warehouse, Purpose");
		
		For IndexOf = 0 To Result.Rows.Count() - 1 Do
			OrderLine = Result.Rows[IndexOf];
			FillPropertyValues(TheStructureOfTheSearch, OrderLine);
			FoundRows = BalanceOfClosedOrder.FindRows(TheStructureOfTheSearch);
			If FoundRows.Count() > 0 Then
				StringBalance = FoundRows[0];
				Count = Min(OrderLine.Done, StringBalance.Balance);
				
				OrderLine.Done = OrderLine.Done - Count;
				OrderLine.Left = OrderLine.Required2 - OrderLine.Done;
				
				StringBalance.Balance = StringBalance.Balance - Count;
			EndIf;
		EndDo;
		
		Result.Rows.Sort("LineNumber");
	EndIf;
	
	// Descendants of the 1st level
	Children2 = New Array;
	For Each Child In Children1 Do
		For Each StringPotebnost In Child.Demands Do
			TreeRow = FillInSemiFinishedProductLine(
				Child.Owner.Rows, StringPotebnost, Supply, PercentageOfCollateral, ReleaseOfCollateralBatches, BalancesForOtherPurposes, ShowMovements);
			FindNeedsAddStages(TreeRow, Demands2, ProductionIssue2, Stages2, PercentageOfCollateralStages2, StagesShow, Children2);
		EndDo;
		If ShowIssue Then
			For Each ReleaseString In Child.ProductionIssue Do
				TreeRow = Child.Owner.Rows.Add();
				FillInProductionIssueRow(TreeRow, ReleaseString);
			EndDo;
			Child.Owner.Rows.Sort("ThisIsASemiFinishedProduct Desc, LinePresentation, ThisIsRelease Desc");
		EndIf;
	EndDo;
	
	// Descendants of the 2nd level
	For Each Child In Children2 Do
		For Each StringPotebnost In Child.Demands Do
			TreeRow = Child.Owner.Rows.Add();
			TreeRow.RowType = RowTypeInternal();
			TreeRow.KeyLot = StringPotebnost.KeyLot;
			Child.Owner.FinishTree = True;
		EndDo;
		If ShowIssue Then
			For Each ReleaseString In Child.ProductionIssue Do
				TreeRow = Child.Owner.Rows.Add();
				TreeRow.RowType = RowTypeInternal();
				TreeRow.KeyLot = ReleaseString.KeyLot;
				Child.Owner.FinishTree = True;
			EndDo;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

// Find needs to add stages.
// 
// Parameters:
//  TreeRow - ValueTreeRow
//  Demands - ValueTable
//  ProductionIssue - ValueTable
//  Stages - ValueTable
//  PercentageOfCollateralStages - ValueTable
//  StagesShow - Boolean
//  Result - Array of Structure
//
Procedure FindNeedsAddStages(TreeRow, Demands, ProductionIssue, Stages, PercentageOfCollateralStages, StagesShow, Result)
	
	TheStructureOfTheSearch1 = New Structure("KeyLot");
	TheStructureOfTheSearch2 = New Structure("KeyLot, StageLink");
	
	For Each KeyLot In TreeRow.ProvidingParty Do
		If StagesShow And TreeRow.RowType <> LineTypeMove() Then
			TheStructureOfTheSearch1.KeyLot = KeyLot;
			FoundRows = Stages.FindRows(TheStructureOfTheSearch1);
			For IndexOf = 0 To FoundRows.UBound() Do
				Stage = FoundRows[IndexOf];
				
				If Stage.Products <> Undefined
					And Stage.Products <> TreeRow.Products Then
					Continue;
				EndIf;
				
				FillPropertyValues(TheStructureOfTheSearch2, Stage);
				
				Supply = PercentageOfCollateralStages.FindRows(TheStructureOfTheSearch2);
				CollateralData = ?(Supply.UBound() <> -1, Supply[0], Undefined);
				
				TreeLineStage = TreeRow.Rows.Add();
				FillInStageLine(TreeLineStage, Stage, CollateralData);
				
				ReleaseLines = ?(ProductionIssue = Undefined, Undefined, ProductionIssue.FindRows(TheStructureOfTheSearch2));
				
				Child = New Structure;
				Child.Insert("Owner", TreeLineStage);
				Child.Insert("Demands", Demands.FindRows(TheStructureOfTheSearch2));
				Child.Insert("ProductionIssue", ReleaseLines);
				
				Result.Add(Child);
			EndDo;
		Else
			TheStructureOfTheSearch1.KeyLot = KeyLot;
			ReleaseLines = ?(ProductionIssue = Undefined, Undefined, ProductionIssue.FindRows(TheStructureOfTheSearch1));
			
			Child = New Structure;
			Child.Insert("Owner", TreeRow);
			Child.Insert("Demands", Demands.FindRows(TheStructureOfTheSearch1));
			Child.Insert("ProductionIssue", ReleaseLines);
			
			Result.Add(Child);
		EndIf;
	EndDo;
	
EndProcedure

Procedure FillTreeRecursively(RowsDestination, StringsSources, LinesToCompleteTree)
	
	For Each SourceRow In StringsSources Do
		
		NewRow = RowsDestination.Add();
		FillPropertyValues(NewRow, SourceRow);
		
		If NewRow.FinishTree Then
			LinesToCompleteTree.Add(NewRow);
		EndIf;
		
		If SourceRow.Rows.Count() > 0 Then
			FillTreeRecursively(NewRow.Rows, SourceRow.Rows, LinesToCompleteTree);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure FillInProductLine(TreeRow, FillingValues, Supply, PercentageOfCollateral, ReleaseOfCollateralBatches, ThisIsDecryptionMode)
	
	FillPropertyValues(TreeRow, FillingValues, 
		"Products, Characteristic, Warehouse, Purpose, UnitOfMeasure,
		|Required2, LineNumber, ItemsType, DesiredDate,
		|UnderRepairProduct, UnderRepairVariant");
	
	TreeRow.LinePresentation = ProductsClientServer.ProductPresentation(
		FillingValues.ProductsPresentation,
		FillingValues.CharacteristicPresentation);
	TreeRow.WarehouseDivision = FillingValues.Warehouse;
	
	TreeRow.RowType = LineTypeProduct();
	TreeRow.PictureNumber = PictureNumber(TreeRow);
	
	If ThisIsDecryptionMode Then
		TheStructureOfTheSearch = New Structure("Products, Characteristic, Warehouse, Purpose",
			FillingValues.Products,
			FillingValues.Characteristic,
			FillingValues.Warehouse,
			FillingValues.Purpose);
	Else
		TheStructureOfTheSearch = New Structure("KeyProducts", FillingValues.KeyProducts);
	EndIf;
	
	PartyKeys = New Array;
	ProductListKeys = New Array;
	
	For Each String In Supply.FindRows(TheStructureOfTheSearch) Do
		
		If Not TreeRow.MultipleSpecifications Then
			If TreeRow.BillOfMaterials.IsEmpty() Then
				TreeRow.BillOfMaterials = String.BillOfMaterials;
			ElsIf TreeRow.BillOfMaterials <> String.BillOfMaterials
					And Not String.BillOfMaterials.IsEmpty() Then
				TreeRow.BillOfMaterials = Catalogs.BillsOfMaterials.EmptyRef();
				TreeRow.MultipleSpecifications = True;
			EndIf;
		EndIf;
		
		TreeRow.Launched = TreeRow.Launched + String.Launched;
		TreeRow.Done = TreeRow.Done + String.Done;
		TreeRow.Begin = ?(TreeRow.Begin = '00010101',
			String.Begin,
			?(String.Begin = '00010101', TreeRow.Begin, Min(TreeRow.Begin, String.Begin)));
		TreeRow.Ending = Max(TreeRow.Ending, String.Ending);
		
		If PartyKeys.Find(String.KeyLot) = Undefined Then
			PartyKeys.Add(String.KeyLot);
		EndIf;
		
		If ProductListKeys.Find(String.KeyProducts) = Undefined Then
			ProductListKeys.Add(String.KeyProducts);
		EndIf;
		
	EndDo;
	
	TreeRow.Left = TreeRow.Required2 - TreeRow.Done - TreeRow.Launched;
	
	If PartyKeys.UBound() <> -1 Then
		
		TreeRow.ProvidingParty = New FixedArray(PartyKeys);
		
		TheStructureOfTheSearch = New Structure;
		TheStructureOfTheSearch.Insert("KeyLot");
		TheStructureOfTheSearch.Insert("Products", FillingValues.Products);
		TheStructureOfTheSearch.Insert("Characteristic", FillingValues.Characteristic);
		
		RowsCount = 0;
		For Each KeyLot In PartyKeys Do
			FoundRow = PercentageOfCollateral.Find(KeyLot, "KeyLot");
			If FoundRow <> Undefined Then
				TreeRow.SupplyIsRequired = True;
				
				TreeRow.SecuredInterest = TreeRow.SecuredInterest + FoundRow.SecuredInterest;
				RowsCount = RowsCount + 1;
				
				TheStructureOfTheSearch.KeyLot = KeyLot;
				TreeRows = ReleaseOfCollateralBatches.Rows.FindRows(TheStructureOfTheSearch);
				If TreeRows.Count() > 0 Then
					RowTotals = TreeRows[0];
					If RowTotals.Count * FoundRow.Numerator / FoundRow.Denominator > 0 Then
						Balance = ?(FillingValues.PieceByProductList,
							Round(RowTotals.Count * FoundRow.Numerator / FoundRow.Denominator - 0.5),
							RowTotals.Count * FoundRow.Numerator / FoundRow.Denominator);
						IndexOf = 0;
						While Balance > 0 And IndexOf < RowTotals.Rows.Count() Do
							DetailsRow = RowTotals.Rows[IndexOf];
							
							If ProductListKeys.Find(DetailsRow.KeyProducts) <> Undefined Then
								TreeRow.Supplied = TreeRow.Supplied + Min(Balance, DetailsRow.Count);
							EndIf;
							
							Balance = Balance - Min(Balance, DetailsRow.Count);
							IndexOf = IndexOf + 1;
						EndDo;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
		If RowsCount > 1 Then
			TreeRow.SecuredInterest = TreeRow.SecuredInterest/RowsCount;
		EndIf;
		
	EndIf;
	
EndProcedure

Function FillInSemiFinishedProductLine(Parent, FillingValues, Supply, PercentageOfCollateral, ReleaseOfCollateralBatches, BalancesForOtherPurposes, ShowMovements)
	
	IsNewLine = True;
	TreeRow = Undefined;
	
	If FillingValues.ThisIsMaterial Then
		TheStructureOfTheSearch = New Structure;
		TheStructureOfTheSearch.Insert("Products", FillingValues.Products);
		TheStructureOfTheSearch.Insert("Characteristic", FillingValues.Characteristic);
		TheStructureOfTheSearch.Insert("Warehouse", FillingValues.Warehouse);
		TheStructureOfTheSearch.Insert("Purpose", FillingValues.Purpose);
		TheStructureOfTheSearch.Insert("KeyLot", FillingValues.KeyLot);
		TheStructureOfTheSearch.Insert("DesiredDate", FillingValues.DesiredDate);
		TheStructureOfTheSearch.Insert("NotProvide", FillingValues.NotProvide);
		TheStructureOfTheSearch.Insert("RowType", LineTypeMaterial());
		
		FoundRows = Parent.FindRows(TheStructureOfTheSearch);
		If FoundRows.Count() > 0 Then
			TreeRow = FoundRows[0];
			TreeRow.Required2 = TreeRow.Required2 + FillingValues.Required2;
			IsNewLine = False;
		EndIf;
	EndIf;
	
	If IsNewLine Then
		TreeRow = Parent.Add();
	
		FillPropertyValues(TreeRow, FillingValues, 
			"Products, Characteristic, Warehouse, Purpose, UnitOfMeasure, KeyLot, KeyProducts, Required2, ItemsType, DesiredDate, NotProvide, ItIsIssuedWithinLotReference");
		
		TreeRow.LinePresentation = ProductsClientServer.ProductPresentation(
			FillingValues.ProductsPresentation,
			FillingValues.CharacteristicPresentation);
		TreeRow.WarehouseDivision = FillingValues.Warehouse;
	EndIf;
	
	// Ensuring the need for PF
	SpecificationSoftware = Catalogs.BillsOfMaterials.EmptyRef();
	SpecificationReserve = Catalogs.BillsOfMaterials.EmptyRef();
	MultipleSpecifications = TreeRow.MultipleSpecifications;
	
	ThereIsMove = False;
	ThereIsTypeOfSecurityRelocation = False;
	ThereIsProduction = False;
	
	PartyKeys = New Array;
	LaunchOrderStages = New Map;
	
	TheStructureOfTheSearch = New Structure("KeyProducts", FillingValues.KeyProducts);
	For Each String In Supply.FindRows(TheStructureOfTheSearch) Do
		
		TreeRow.Begin = ?(TreeRow.Begin = '00010101',
			String.Begin,
			?(String.Begin = '00010101', TreeRow.Begin, Min(TreeRow.Begin, String.Begin)));
		TreeRow.Ending = Max(TreeRow.Ending, String.Ending);
		
		If String.ItIsTransfer Then
			If ShowMovements Then
				ThereIsMove = True;
			Else
				TreeRow.MultipleWarehouses = True;
				Continue;
			EndIf;
		EndIf;
		
		If String.SupplyType = Enums.SupplyTypes.Move
			And ShowMovements Then
			ThereIsTypeOfSecurityRelocation = True;
		EndIf;
		
		If String.ThisIsProduction Then
			ThereIsProduction = True;
		EndIf;
		
		TreeRow.Launched = TreeRow.Launched + String.Launched;
		
		If String.IsReserve Then
			
			If Not String.LaunchOrder.IsEmpty() Then
				LineOfLaunchOrderTree = TreeRow.Rows.Find(String.LaunchOrder, "LaunchOrder");
				If LineOfLaunchOrderTree = Undefined Then
					LineOfLaunchOrderTree = TreeRow.Rows.Add();
					LineOfLaunchOrderTree.RowType = LineTypeLaunchOrder();
					LineOfLaunchOrderTree.LaunchOrder = String.LaunchOrder;
					LaunchOrderStages.Insert(String.LaunchOrder, New Array);
				EndIf;
				
				LineOfLaunchOrderTree.LaunchedInLaunchOrders = LineOfLaunchOrderTree.LaunchedInLaunchOrders
					+ String.Allocated;
					
				Presentation = StrTemplate(NStr("vi = '%1 (%2 %3)';
												|ru = '%1 (%2 %3)';
												|en = '%1 (%2 %3)'; fa = '%1 (%2 %3)';
												|it = '%1 (%2 %3)';
												|pl = '%1 (%2 %3)';
												|tr = '%1 (%2 %3)'"),
					Documents.ProductionOrder2_2.OrderPresentation(String.LaunchOrder),
					Format(LineOfLaunchOrderTree.LaunchedInLaunchOrders, "NG=0;"),
					FillingValues.UnitOfMeasure);
				
				If String.DecodingLaunchInStages Then
					LaunchOrderStages[String.LaunchOrder].Add(String.ReceiptOrder);
					LineOfLaunchOrderTree.LaunchOrderStages = New FixedArray(
						LaunchOrderStages[String.LaunchOrder]);
						
					Presentation = Presentation + ", "
						+ Documents.ProductionStage2_2.PresentationStage(String.ReceiptOrder);
					If LineOfLaunchOrderTree.LaunchOrderStages.Count() > 1 Then
						Presentation = Presentation + ", ..."
					EndIf;
				EndIf;
				
				LineOfLaunchOrderTree.LinePresentation = Presentation;
			EndIf;
			
			If ValueIsFilled(String.ReceiptOrder) Then
				TreeRow.Launched = TreeRow.Launched + String.Allocated;
			Else
				TreeRow.Done = TreeRow.Done + String.Allocated;
			EndIf;
			
			If Not MultipleSpecifications Then
				If SpecificationReserve.IsEmpty() Then
					SpecificationReserve = String.BillOfMaterials;
				ElsIf SpecificationReserve <> String.BillOfMaterials
						And Not String.BillOfMaterials.IsEmpty() Then
					SpecificationReserve = Catalogs.BillsOfMaterials.EmptyRef();
					MultipleSpecifications = True;
				EndIf;
			EndIf;
			
		Else
			
			If PartyKeys.Find(String.KeyLot) = Undefined Then
				PartyKeys.Add(String.KeyLot);
			EndIf;
			
			If Not MultipleSpecifications Then
				If SpecificationSoftware.IsEmpty() Then
					SpecificationSoftware = String.BillOfMaterials;
				ElsIf SpecificationSoftware <> String.BillOfMaterials
						And Not String.BillOfMaterials.IsEmpty() Then
					SpecificationSoftware = Catalogs.BillsOfMaterials.EmptyRef();
					MultipleSpecifications = True;
				EndIf;
			EndIf;
			
			If Not ShowMovements
				And TreeRow.Warehouse <> String.Warehouse Then
				TreeRow.Warehouse = String.Warehouse;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If ThereIsProduction Then
		TreeRow.RowType = LineTypeSemiFinished();
	ElsIf ThereIsMove Or ThereIsTypeOfSecurityRelocation Then
		TreeRow.RowType = LineTypeMove();
	Else
		TreeRow.RowType = ?(FillingValues.ThisIsMaterial, LineTypeMaterial(), LineTypeSemiFinished());
	EndIf;
	TreeRow.ThisIsASemiFinishedProduct = TreeRow.RowType = LineTypeSemiFinished();
	
	TreeRow.MultipleSpecifications = MultipleSpecifications;
	If Not MultipleSpecifications Then
		If Not SpecificationSoftware.IsEmpty() Then
			TreeRow.BillOfMaterials = SpecificationSoftware;
		ElsIf Not SpecificationReserve.IsEmpty() Then
			TreeRow.BillOfMaterials = SpecificationReserve;
		Else
			TreeRow.BillOfMaterials = FillingValues.SemiFinishedProductBOM;
		EndIf;
	EndIf;
	
	TreeRow.Left = TreeRow.Required2 - TreeRow.Done - TreeRow.Launched;
	TreeRow.PictureNumber = PictureNumber(TreeRow);
	
	If PartyKeys.UBound() <> -1 Then
		
		TreeRow.ProvidingParty = New FixedArray(PartyKeys);
		
		TheStructureOfTheSearch = New Structure;
		TheStructureOfTheSearch.Insert("KeyLot");
		TheStructureOfTheSearch.Insert("Products", FillingValues.Products);
		TheStructureOfTheSearch.Insert("Characteristic", FillingValues.Characteristic);
		
		RowsCount = 0;
		For Each KeyLot In PartyKeys Do
			FoundRow = PercentageOfCollateral.Find(KeyLot, "KeyLot");
			If FoundRow <> Undefined Then
				TreeRow.SupplyIsRequired = True;
				
				TreeRow.SecuredInterest = TreeRow.SecuredInterest + FoundRow.SecuredInterest;
				RowsCount = RowsCount + 1;
				
				TheStructureOfTheSearch.KeyLot = KeyLot;
				TreeRows = ReleaseOfCollateralBatches.Rows.FindRows(TheStructureOfTheSearch);
				If TreeRows.Count() > 0 Then
					RowTotals = TreeRows[0];
					If RowTotals.Count * FoundRow.Numerator / FoundRow.Denominator > 0 Then
						Balance = ?(FillingValues.PieceByProductList,
							Round(RowTotals.Count * FoundRow.Numerator / FoundRow.Denominator - 0.5),
							RowTotals.Count * FoundRow.Numerator / FoundRow.Denominator);
						IndexOf = 0;
						While Balance > 0 And IndexOf < RowTotals.Rows.Count() Do
							DetailsRow = RowTotals.Rows[IndexOf];
							
							If DetailsRow.KeyProducts = FillingValues.KeyProducts Then
								TreeRow.Supplied = TreeRow.Supplied + Min(Balance, DetailsRow.Count);
								Break;
							EndIf;
							
							Balance = Balance - Min(Balance, DetailsRow.Count);
							IndexOf = IndexOf + 1;
						EndDo;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
		If RowsCount > 1 Then
			TreeRow.SecuredInterest = TreeRow.SecuredInterest/RowsCount;
		EndIf;
		
	EndIf;
	
	// Indication of the presence of residues for other purposes
	If TreeRow.Left > 0
		And IsNewLine Then
		TheStructureOfTheSearch = New Structure;
		TheStructureOfTheSearch.Insert("Products",   FillingValues.Products);
		TheStructureOfTheSearch.Insert("Characteristic", FillingValues.Characteristic);
		TheStructureOfTheSearch.Insert("Warehouse",		   FillingValues.Warehouse);
		TheStructureOfTheSearch.Insert("Purpose",	   FillingValues.Purpose);
		
		RowsArray = BalancesForOtherPurposes.FindRows(TheStructureOfTheSearch);
		If RowsArray.Count() > 0 Then
			FillPropertyValues(TreeRow, RowsArray[0],
				"IndexOfImageIsStillFreeOrNotNeeded, IndexOfImageRemainsForOtherPurposes,
				|IndexOfImageRemainsInAnotherWarehouse, IndexOfImageLeft");
		EndIf;
	EndIf;
	
	Return TreeRow;
	
EndFunction

Procedure FillInProductionIssueRow(TreeRow, FillingValues)
	
	FillPropertyValues(TreeRow, FillingValues, 
		"Products, Characteristic, Warehouse, Purpose, UnitOfMeasure, ItemsType, Quality,
		|KeyLot, ProductionLot, StageLink,
		|Required2, Done, Begin, Ending, Canceled");
	
	TreeRow.LinePresentation = ProductsClientServer.ProductPresentation(
		FillingValues.ProductsPresentation,
		FillingValues.CharacteristicPresentation);
	TreeRow.WarehouseDivision = FillingValues.Warehouse;
	TreeRow.RowType = LineTypeIssue();
	TreeRow.ThisIsRelease = True;
	TreeRow.PictureNumber = PictureNumber(TreeRow);
	TreeRow.Left = TreeRow.Required2 - TreeRow.Done;
	
EndProcedure

Procedure FillInStageLine(TreeRow, FillingValues, CollateralData)
	
	FillPropertyValues(TreeRow, FillingValues,
		"KeyLot,
		|ProductionLot,
		|Department,
		|BillOfMaterials,
		|StageLink,
		|StageNumber,
		|NextStageNo,
		|Begin,
		|Ending,
		|UnitOfMeasure,
		|Required2,
		|Launched,
		|Done,
		|ProductionByThirdParty,
		|WorkPlanning");
	
	TreeRow.LinePresentation = FillingValues.StageName;
	TreeRow.WarehouseDivision = FillingValues.Department;
	TreeRow.RowType = ?(TypeOf(TreeRow.StageLink) = Type("CatalogRef.ProductionStages"),
		StringTypeStructureStage(),
		LineTypeStageDocument());
	TreeRow.PictureNumber = PictureNumber(TreeRow);
	
	If Not TreeRow.ProductionByThirdParty Then
		TreeRow.Left = TreeRow.Required2 - TreeRow.Done - TreeRow.Launched;
	EndIf;
	
	If CollateralData <> Undefined Then
		TreeRow.SupplyIsRequired = True;
		TreeRow.SecuredInterest = CollateralData.SecuredInterest;
		Supplied = (TreeRow.Required2 - TreeRow.Done) * CollateralData.Numerator / CollateralData.Denominator;
		If Supplied > 0 Then
			TreeRow.Supplied = ?(FillingValues.PieceByProductList, Round(Supplied - 0.5), Supplied);
		EndIf;
	EndIf;
	
EndProcedure

Function ReleaseTreeOfSoftwareBatches(QueryResult)
	
	Result = New ValueTree();
	Result.Columns.Add("KeyLot", New TypeDescription("UUID"));
	Result.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	Result.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	Result.Columns.Add("KeyProducts", New TypeDescription("UUID"));
	Result.Columns.Add("Count", New TypeDescription("Number", New NumberQualifiers(15, 3)));
	
	SampleKeyBatch = QueryResult.Select(QueryResultIteration.ByGroups);
	While SampleKeyBatch.Next() Do
		SelectionOfProducts = SampleKeyBatch.Select(QueryResultIteration.ByGroups);
		While SelectionOfProducts.Next() Do
			SampleCharacteristics = SelectionOfProducts.Select(QueryResultIteration.ByGroups);
			While SampleCharacteristics.Next() Do
				RowTotals = Result.Rows.Add();
				FillPropertyValues(RowTotals, SampleCharacteristics);
				
				Selection = SampleCharacteristics.Select();
				While Selection.Next() Do
					DetailsRow = RowTotals.Rows.Add();
					FillPropertyValues(DetailsRow, Selection);
				EndDo;
			EndDo;
		EndDo;
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#Region QueryTexts

Function QueryTextsOrderedOnTT()
	
	QueryTexts = New ValueList;
	
	QueryText = 
		"SELECT
		|	TabularSection.Products     AS Products,
		|	TabularSection.Characteristic   AS Characteristic,
		|	CASE 
		|		WHEN TabularSection.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|				OR TabularSection.ToExpenseAs
		|			THEN TabularSection.Department
		|		ELSE TabularSection.Warehouse
		|	END                           AS Warehouse,
		|	CASE
		|		WHEN TabularSection.Ref.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.WithoutBillsOfMaterials)
		|				AND NOT TabularSection.ToExpenseAs
		|				OR TabularSection.Ref.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Disassembly)
		|			THEN TabularSection.Ref.AssignmentProducts
		|		ELSE TabularSection.Purpose
		|	END                           AS Purpose,
		|	TabularSection.Count       AS Count,
		|	TabularSection.KeyProducts AS KeyProducts,
		|	TabularSection.LineNumber      AS LineNumber,
		|	TabularSection.Ref           AS ProductionOrder,
		|	TabularSection.Ref.Status = VALUE(Enum.ProductionOrderStatuses2_2.Closed) AS Closed,
		|	TabularSection.DemandDate  AS DesiredDate,
		|	TabularSection.Ref.UnderRepairProduct AS UnderRepairProduct,
		|	TabularSection.Ref.UnderRepairVariant AS UnderRepairVariant
		|INTO TTOrderDetails
		|FROM
		|	Document.ProductionOrder2_2.ManufacturedProduct AS TabularSection
		|WHERE
		|	TabularSection.Ref = &OrderDocument
		|	AND NOT TabularSection.Canceled
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose, ProductionOrder, KeyProducts";
	QueryTexts.Add(QueryText, "TTOrderDetails");
	
	QueryText = 
		"SELECT
		|	TabularSection.Products           AS Products,
		|	TabularSection.Characteristic         AS Characteristic,
		|	TabularSection.Warehouse                  AS Warehouse,
		|	TabularSection.Purpose             AS Purpose,
		|	TabularSection.KeyProducts       AS KeyProducts,
		|	TabularSection.ProductionOrder    AS ProductionOrder,
		|	TabularSection.DesiredDate           AS DesiredDate,
		|	TabularSection.UnderRepairProduct AS UnderRepairProduct,
		|	TabularSection.UnderRepairVariant AS UnderRepairVariant,
		|	MIN(TabularSection.LineNumber)   AS LineNumber,
		|	SUM(TabularSection.Count)      AS Required2
		|INTO TTClosedOrderData
		|FROM
		|	TTOrderDetails AS TabularSection
		|WHERE
		|	(&Purpose = VALUE(Catalog.Assignments.EmptyRef) OR TabularSection.Purpose = &Purpose)
		|	AND TabularSection.Closed
		|
		|GROUP BY
		|	TabularSection.Products,
		|	TabularSection.Characteristic,
		|	TabularSection.Warehouse,
		|	TabularSection.Purpose,
		|	TabularSection.KeyProducts,
		|	TabularSection.ProductionOrder,
		|	TabularSection.DesiredDate,
		|	TabularSection.UnderRepairProduct,
		|	TabularSection.UnderRepairVariant
		|
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose, ProductionOrder";
	QueryTexts.Add(QueryText, "TTClosedOrderData");
	
	QueryText = 
		"SELECT
		|	OrderStructure.Products          AS Products,
		|	OrderStructure.Characteristic        AS Characteristic,
		|	OrderStructure.Warehouse                 AS Warehouse,
		|	OrderStructure.Purpose            AS Purpose,
		|	OrderStructure.KeyLot            AS KeyLot,
		|	OrderStructure.KeyProducts      AS KeyProducts,
		|	CASE
		|		WHEN OrderStructure.Stage REFS Document.ProductionStage2_2
		|			THEN CAST(OrderStructure.Stage AS Document.ProductionStage2_2).BillOfMaterials
		|		ELSE OrderStructure.BillOfMaterials
		|	END                                 AS BillOfMaterials,
		|	CASE
		|		WHEN OrderStructure.Stage REFS Document.ProductionStage2_2
		|			THEN CAST(OrderStructure.Stage AS Document.ProductionStage2_2).ProductionLot
		|		ELSE VALUE(Catalog.ProductionLots.EmptyRef)
		|	END                                 AS ProductionLot,
		|	OrderStructure.ProductionOrder   AS ProductionOrder,
		|	TabularSection.DesiredDate           AS DesiredDate,
		|	TabularSection.UnderRepairProduct AS UnderRepairProduct,
		|	TabularSection.UnderRepairVariant AS UnderRepairVariant,
		|	MIN(TabularSection.LineNumber)   AS LineNumber,
		|	SUM(OrderStructure.Ordered) + SUM(OrderStructure.Done) AS Required2,
		|	SUM(OrderStructure.Scheduled) + SUM(OrderStructure.ReverseKittingScheduled) AS Scheduled,
		|	SUM(OrderStructure.AllocatedInFreeProductionLots + OrderStructure.AllocatedInAssignedProductionLots) AS Launched,
		|	SUM(OrderStructure.Done) AS Done
		|INTO TTOrdered
		|FROM
		|	TTOrderDetails AS TabularSection
		|
		|	INNER JOIN InformationRegister.OrderStructure AS OrderStructure
		|	ON TabularSection.Products = OrderStructure.Products
		|		AND TabularSection.Characteristic = OrderStructure.Characteristic
		|		AND TabularSection.Warehouse = OrderStructure.Warehouse
		|		AND TabularSection.Purpose IN (OrderStructure.Purpose, VALUE(Catalog.Assignments.EmptyRef))
		|		AND TabularSection.ProductionOrder = OrderStructure.ProductionOrder
		|		AND TabularSection.KeyProducts = OrderStructure.KeyProducts
		|	
		|WHERE
		|	OrderStructure.LineKind IN(
		|		VALUE(Enum.KindsOfProductionOrderStructureLines.ManufacturedProduct),
		|		VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureOfProducts),
		|		VALUE(Enum.KindsOfProductionOrderStructureLines.Disassembly))
		|	AND (&Purpose = VALUE(Catalog.Assignments.EmptyRef) OR OrderStructure.Purpose = &Purpose)
		|	AND NOT TabularSection.Closed
		|
		|GROUP BY
		|	OrderStructure.Products,
		|	OrderStructure.Characteristic,
		|	OrderStructure.Warehouse,
		|	OrderStructure.Purpose,
		|	OrderStructure.KeyLot,
		|	OrderStructure.KeyProducts,
		|	CASE
		|		WHEN OrderStructure.Stage REFS Document.ProductionStage2_2
		|			THEN CAST(OrderStructure.Stage AS Document.ProductionStage2_2).BillOfMaterials
		|		ELSE OrderStructure.BillOfMaterials
		|	END,
		|	CASE
		|		WHEN OrderStructure.Stage REFS Document.ProductionStage2_2
		|			THEN CAST(OrderStructure.Stage AS Document.ProductionStage2_2).ProductionLot
		|		ELSE VALUE(Catalog.ProductionLots.EmptyRef)
		|	END,
		|	OrderStructure.ProductionOrder,
		|	TabularSection.DesiredDate,
		|	TabularSection.UnderRepairProduct,
		|	TabularSection.UnderRepairVariant
		|
		|HAVING
		|	SUM(OrderStructure.Ordered) > 0
		|		OR SUM(OrderStructure.Scheduled) > 0
		|		OR SUM(OrderStructure.ReverseKittingScheduled) > 0
		|		OR SUM(OrderStructure.AllocatedInFreeProductionLots + OrderStructure.AllocatedInAssignedProductionLots) > 0
		|		OR SUM(OrderStructure.Done) > 0
		|
		|UNION ALL
		|
		|SELECT
		|	TabularSection.Products        AS Products,
		|	TabularSection.Characteristic      AS Characteristic,
		|	TabularSection.Warehouse               AS Warehouse,
		|	TabularSection.Purpose          AS Purpose,
		|	&EmptyLinkKey                   AS KeyLot,
		|	TabularSection.KeyProducts    AS KeyProducts,
		|	VALUE(Catalog.BillsOfMaterials.EmptyRef) AS BillOfMaterials,
		|	VALUE(Catalog.ProductionLots.EmptyRef) AS ProductionLot,
		|	TabularSection.ProductionOrder AS ProductionOrder,
		|	TabularSection.DesiredDate        AS DesiredDate,
		|	TabularSection.UnderRepairProduct AS UnderRepairProduct,
		|	TabularSection.UnderRepairVariant AS UnderRepairVariant,
		|	TabularSection.LineNumber         AS LineNumber,
		|	TabularSection.Required2           AS Required2,
		|	0                                  AS Scheduled,
		|	0                                  AS Launched,
		|	TabularSection.Required2           AS Done
		|FROM
		|	TTClosedOrderData AS TabularSection";
	QueryTexts.Add(QueryText, "TTOrdered");
	
	QueryText = 
		"SELECT
		|	OrderStructure.KeyLot                    AS KeyLot,
		|	OrderStructure.Products                  AS Products,
		|	OrderStructure.Products.UnitOfMeasure AS UnitOfMeasure,
		|	SUM(OrderStructure.Scheduled) + SUM(OrderStructure.ReverseKittingScheduled) AS Scheduled
		|INTO TTBatchSizeOrder
		|FROM
		|	InformationRegister.OrderStructure AS OrderStructure
		|WHERE
		|	&StagesShow
		|	AND (OrderStructure.Products, OrderStructure.Characteristic, OrderStructure.KeyLot) IN 
		|		(SELECT
		|			Ordered.Products,
		|			Ordered.Characteristic,
		|			Ordered.KeyLot
		|		FROM
		|			TTOrdered AS Ordered)
		|
		|GROUP BY
		|	OrderStructure.KeyLot,
		|	OrderStructure.Products,
		|	OrderStructure.Products.UnitOfMeasure
		|
		|HAVING
		|	SUM(OrderStructure.Scheduled) > 0
		|	OR SUM(OrderStructure.ReverseKittingScheduled) > 0
		|
		|INDEX BY
		|	KeyLot";
	QueryTexts.Add(QueryText, "TTBatchSizeOrder");
	
	Return QueryTexts;
	
EndFunction

Function QueryTextKeysOfLotReferencesOfStagesOrderedTT()
	
	Return
		"SELECT DISTINCT
		|	Supply.KeyLot AS KeyLot,
		|	CASE
		|		WHEN Supply.ProductionLot = VALUE(Catalog.ProductionLots.EmptyRef)
		|			THEN Supply.BillOfMaterials
		|		ELSE Supply.ProductionLot
		|	END                  AS Ref
		|INTO TTKeysOfLotReferencesOfStagesOrdered
		|FROM
		|	TTOrdered AS Supply
		|WHERE
		|	Supply.Scheduled > 0
		|	OR Supply.Launched > 0
		|
		|INDEX BY SETS (
		|	(KeyLot),
		|	(Ref)
		|)";
	
EndFunction

Function QueryTextOrdered()
	
	QueryText = 
		"SELECT
		|	Ordered.Products                  AS Products,
		|	Ordered.Products.UnitOfMeasure AS UnitOfMeasure,
		|	Ordered.Products.Presentation    AS ProductsPresentation,
		|	Ordered.Products.ItemsType  AS ItemsType,
		|	ISNULL(Ordered.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces), FALSE) AS PieceByProductList,
		|	Ordered.Characteristic                AS Characteristic,
		|	Ordered.Characteristic.Presentation  AS CharacteristicPresentation,
		|	Ordered.Warehouse                         AS Warehouse,
		|	Ordered.Purpose                    AS Purpose,
		|	Ordered.KeyProducts              AS KeyProducts,
		|	Ordered.DesiredDate                  AS DesiredDate,
		|	Ordered.UnderRepairProduct AS UnderRepairProduct,
		|	Ordered.UnderRepairVariant AS UnderRepairVariant,
		|	MIN(Ordered.LineNumber)          AS LineNumber,
		|	SUM(Ordered.Required2)              AS Required2
		|FROM
		|	TTOrdered AS Ordered
		|
		|GROUP BY
		|	Ordered.Products,
		|	ISNULL(Ordered.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces), FALSE),
		|	Ordered.Characteristic,
		|	Ordered.Warehouse,
		|	Ordered.Purpose,
		|	Ordered.KeyProducts,
		|	Ordered.DesiredDate,
		|	Ordered.UnderRepairProduct,
		|	Ordered.UnderRepairVariant
		|
		|HAVING
		|	SUM(Ordered.Required2) > 0
		|
		|ORDER BY
		|	LineNumber";
	
	Return QueryText;
	
EndFunction

Function QueryTextSecuringOrder(ProcessType)
	
	QueryText = 
		"SELECT
		|	Supply.Products     AS Products,
		|	Supply.Characteristic   AS Characteristic,
		|	Supply.Warehouse            AS Warehouse,
		|	Supply.Purpose       AS Purpose,
		|	Supply.KeyLot       AS KeyLot,
		|	Supply.KeyProducts AS KeyProducts,
		|	Supply.BillOfMaterials     AS BillOfMaterials,
		|	Supply.Launched         AS Launched,
		|	Supply.Done           AS Done,
		|	ISNULL(Schedule.Begin, DATETIME(1,1,1)) AS Begin,
		|	ISNULL(Schedule.Ending, DATETIME(1,1,1)) AS Ending
		|FROM
		|	TTOrdered AS Supply
		|
		|	LEFT JOIN InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
		|	ON Supply.ProductionOrder = Schedule.ProductionOrder
		|		AND Schedule.ScheduleStatus = &StatusWorkingSchedule
		|		AND Supply.KeyLot = Schedule.KeyLot
		|		AND Schedule.Stage = VALUE(Catalog.ProductionStages.EmptyRef)
		|
		|WHERE
		|	Supply.Scheduled > 0
		|	OR Supply.Launched > 0
		|	OR Supply.Done > 0
		|
		|ORDER BY
		|	&Begin,
		|	&Ending";
	
	ProductionManagement.SubstitutionOfActualRegisterOfGraph(QueryText);
	
	SortAscending = SortDataInAscendingOrder(ProcessType);
	QueryText = StrReplace(
		QueryText,
		"&Begin",
		?(SortAscending, "Begin", "Begin DESC"));
	QueryText = StrReplace(
		QueryText,
		"&Ending",
		?(SortAscending, "Ending", "Ending DESC"));
	
	Return QueryText;
	
EndFunction

Function QueryTextBalanceOfClosedOrder()
	
	QueryText = 
		"SELECT
		|	InventoryAndDemandsBalance.Products AS Products,
		|	InventoryAndDemandsBalance.Characteristic AS Characteristic,
		|	InventoryAndDemandsBalance.Warehouse AS Warehouse,
		|	InventoryAndDemandsBalance.Purpose AS Purpose,
		|	InventoryAndDemandsBalance.OrderedBalance AS Balance
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(, (Products, Characteristic, Warehouse, Purpose, OrderDocument) IN
		|		(SELECT
		|			T.Products,
		|			T.Characteristic,
		|			T.Warehouse,
		|			T.Purpose,
		|			T.ProductionOrder AS OrderDocument
		|		FROM
		|			TTClosedOrderData AS T)) AS InventoryAndDemandsBalance";
	
	Return QueryText;
	
EndFunction

Function QueryTextsLaunchedInTTStages()
	
	// Simulation of the needs of the order based on the specified product in the running stage (ordered)
	QueryTexts = New ValueList;
	
	QueryText = 
		"SELECT
		|	NestedQuery.Stage                  AS Stage,
		|	MIN(NestedQuery.DesiredDate) AS DesiredDate
		|INTO TTNeedDateOfLaunchParties
		|FROM
		|	(
		|		SELECT
		|			ProductionIssue.Stage            AS Stage,
		|			MIN(Schedule.Begin) AS DesiredDate
		|		FROM
		|			InformationRegister.OrderStructure AS ProductionIssue
		|			
		|			INNER JOIN InformationRegister.OrderStructure AS Consumption
		|			ON ProductionIssue.Products = Consumption.Products
		|				AND ProductionIssue.Characteristic = Consumption.Characteristic
		|				AND ProductionIssue.Warehouse = Consumption.Warehouse
		|				AND ProductionIssue.Purpose = Consumption.Purpose
		|				AND ProductionIssue.ProductionOrder = Consumption.ProductionOrder
		|				AND ProductionIssue.KeyProducts = Consumption.KeyProducts
		|				AND Consumption.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption)
		|			
		|			INNER JOIN InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
		|			ON Consumption.ProductionOrder = Schedule.ProductionOrder
		|				AND Schedule.ScheduleStatus = &StatusWorkingSchedule
		|				AND Consumption.KeyLot = Schedule.KeyLot
		|				AND Consumption.Stage = Schedule.Stage
		|		WHERE
		|			ProductionIssue.Products = &StageNomenclature
		|			AND ProductionIssue.Characteristic = &StageCharacteristics
		|			AND ProductionIssue.Warehouse = &WarehouseStage
		|			AND ProductionIssue.Purpose = &StageAppointment
		|			AND ProductionIssue.ProductionOrder = &OrderDocument
		|			AND ProductionIssue.Stage IN (&Stages)
		|
		|		GROUP BY
		|			ProductionIssue.Stage
		|		
		|		HAVING
		|			SUM(ProductionIssue.AllocatedInFreeProductionLots + ProductionIssue.AllocatedInAssignedProductionLots) > 0
		|		
		|		UNION ALL
		|		
		|		SELECT
		|			OrderStructure.ReceiptOrder AS Stage,
		|			MIN(Schedule.Begin)             AS DesiredDate
		|		FROM
		|			InformationRegister.OrderStructure AS OrderStructure
		|			
		|			INNER JOIN InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
		|			ON OrderStructure.ProductionOrder = Schedule.ProductionOrder
		|				AND Schedule.ScheduleStatus = &StatusWorkingSchedule
		|				AND OrderStructure.KeyLot = Schedule.KeyLot
		|				AND OrderStructure.Stage = Schedule.Stage
		|		WHERE
		|			OrderStructure.Products = &StageNomenclature
		|			AND OrderStructure.Characteristic = &StageCharacteristics
		|			AND OrderStructure.Warehouse = &WarehouseStage
		|			AND OrderStructure.Purpose = &StageAppointment
		|			AND OrderStructure.ProductionOrder <> &OrderDocument
		|			AND OrderStructure.ReceiptOrder IN (&Stages)
		|		
		|		GROUP BY
		|			OrderStructure.ReceiptOrder
		|		
		|		HAVING
		|			SUM(OrderStructure.AllocatedFromAvailableInventory + OrderStructure.AllocatedFromAvailableInventoryWithAssignment) > 0
		|	) AS NestedQuery
		|
		|GROUP BY
		|	NestedQuery.Stage
		|
		|INDEX BY
		|	Stage";
		
	ProductionManagement.SubstitutionOfActualRegisterOfGraph(QueryText);
	QueryTexts.Add(QueryText, "TTNeedDateOfLaunchParties");
	
	QueryText = 
		"SELECT
		|	OrderStructure.Products          AS Products,
		|	OrderStructure.Characteristic        AS Characteristic,
		|	OrderStructure.Warehouse                 AS Warehouse,
		|	OrderStructure.Purpose            AS Purpose,
		|	OrderStructure.KeyLot            AS KeyLot,
		|	OrderStructure.KeyProducts      AS KeyProducts,
		|	CAST(OrderStructure.Stage AS Document.ProductionStage2_2).BillOfMaterials       AS BillOfMaterials,
		|	CAST(OrderStructure.Stage AS Document.ProductionStage2_2).ProductionLot AS ProductionLot,
		|	OrderStructure.ProductionOrder   AS ProductionOrder,
		|	ISNULL(NeedDates.DesiredDate, DATETIME(1,1,1))                           AS DesiredDate,
		|	VALUE(Catalog.Products.EmptyRef)               AS UnderRepairProduct,
		|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS UnderRepairVariant,
		|	0                                     AS LineNumber,
		|	SUM(OrderStructure.Launched) + SUM(OrderStructure.ReverseKittingStarted)          AS Required2,
		|	0                                     AS Scheduled,
		|	SUM(OrderStructure.Launched) + SUM(OrderStructure.ReverseKittingStarted)          AS Launched,
		|	0                                     AS Done
		|INTO TTOrdered
		|FROM
		|	InformationRegister.OrderStructure AS OrderStructure
		|	
		|	LEFT JOIN TTNeedDateOfLaunchParties AS NeedDates
		|	ON OrderStructure.Stage = NeedDates.Stage
		|WHERE
		|	OrderStructure.Products = &StageNomenclature
		|	AND OrderStructure.Characteristic = &StageCharacteristics
		|	AND OrderStructure.Warehouse = &WarehouseStage
		|	AND OrderStructure.Purpose = &StageAppointment
		|	AND OrderStructure.ProductionOrder = &OrderDocument
		|	AND OrderStructure.Stage IN (&Stages)
		|
		|GROUP BY
		|	OrderStructure.Products,
		|	OrderStructure.Characteristic,
		|	OrderStructure.Warehouse,
		|	OrderStructure.Purpose,
		|	OrderStructure.KeyLot,
		|	OrderStructure.KeyProducts,
		|	CAST(OrderStructure.Stage AS Document.ProductionStage2_2).BillOfMaterials,
		|	CAST(OrderStructure.Stage AS Document.ProductionStage2_2).ProductionLot,
		|	OrderStructure.ProductionOrder,
		|	ISNULL(NeedDates.DesiredDate, DATETIME(1,1,1))
		|
		|HAVING
		|	SUM(OrderStructure.Launched) <> 0
		|	OR SUM(OrderStructure.ReverseKittingStarted) <> 0";
	QueryTexts.Add(QueryText, "TTOrdered");
	
	QueryText = 
		"SELECT
		|	Supply.KeyLot                    AS KeyLot,
		|	Supply.Products                  AS Products,
		|	Supply.Products.UnitOfMeasure AS UnitOfMeasure,
		|	SUM(Supply.Launched)               AS Scheduled
		|INTO TTBatchSizeOrder
		|FROM
		|	TTOrdered AS Supply
		|WHERE
		|	&StagesShow
		|
		|GROUP BY
		|	Supply.KeyLot,
		|	Supply.Products,
		|	Supply.Products.UnitOfMeasure
		|
		|HAVING
		|	SUM(Supply.Launched) > 0
		|
		|INDEX BY
		|	KeyLot";
	QueryTexts.Add(QueryText, "TTBatchSizeOrder");
	
	QueryText = 
		"SELECT
		|	UNDEFINED     AS Products,
		|	UNDEFINED     AS Characteristic,
		|	UNDEFINED     AS Warehouse,
		|	UNDEFINED     AS Purpose,
		|	&EmptyLinkKey AS KeyProducts,
		|	UNDEFINED     AS ProductionOrder,
		|	DATETIME(1,1,1) AS DesiredDate,
		|	0                AS LineNumber,
		|	0                AS Required2
		|INTO TTClosedOrderData";
	QueryTexts.Add(QueryText, "TTClosedOrderData");
	
	Return QueryTexts;
	
EndFunction

Function TextOfRequestNeedsTT(FilterCriterion, ShowContent)
	
	QueryText = 
		"SELECT
		|	OrderStructure.Products        AS Products,
		|	OrderStructure.Characteristic      AS Characteristic,
		|	OrderStructure.Warehouse               AS Warehouse,
		|	OrderStructure.Purpose          AS Purpose,
		|	OrderStructure.ProductionOrder AS ProductionOrder,
		|	OrderStructure.KeyProducts    AS KeyProducts,
		|	OrderStructure.KeyLot          AS KeyLot,
		|	OrderStructure.Stage                AS StageLink,
		|	SUM(OrderStructure.NotProvide) > 0           AS NotProvide,
		|	SUM(OrderStructure.ToSupply)
		|		+ SUM(OrderStructure.Done)
		| 		+ SUM(OrderStructure.NotProvide)
		|		- SUM(OrderStructure.Replaced)               AS Required2,
		|	MAX(ISNULL(Schedule.Begin, DATETIME(1,1,1))) AS DesiredDate,
		|	MAX(OrderStructure.SemiFinishedProductBOM) AS SemiFinishedProductBOM,
		|	MAX(OrderStructure.ConnectionKeyTransfer) AS ConnectionKeyTransfer
		|INTO TTNeed
		|FROM
		|	InformationRegister.OrderStructure AS OrderStructure
		|
		|	LEFT JOIN InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
		|	ON OrderStructure.ProductionOrder = Schedule.ProductionOrder
		|		AND Schedule.ScheduleStatus = &StatusWorkingSchedule
		|		AND OrderStructure.KeyLot = Schedule.KeyLot
		|		AND OrderStructure.Stage = Schedule.Stage
		|WHERE
		|	&FilterCriterion
		|	AND OrderStructure.LineKind IN(
		|		VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption))
		|	AND TRUE IN(&ConditionIsSemiFinishedProduct)
		|	AND (&Purpose = VALUE(Catalog.Assignments.EmptyRef) OR OrderStructure.Purpose = &Purpose)
		|
		|GROUP BY
		|	OrderStructure.Products,
		|	OrderStructure.Characteristic,
		|	OrderStructure.Warehouse,
		|	OrderStructure.Purpose,
		|	OrderStructure.ProductionOrder,
		|	OrderStructure.KeyProducts,
		|	OrderStructure.KeyLot,
		|	OrderStructure.Stage
		|
		|HAVING
		|	SUM(OrderStructure.ToSupply - OrderStructure.Replaced) <> 0
		|	OR SUM(OrderStructure.Done) <> 0
		|	OR SUM(OrderStructure.NotProvide) <> 0
		|
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose, ProductionOrder, KeyProducts";
	
	QueryText = StrReplace(QueryText, "&FilterCriterion", FilterCriterion);
	
	QueryText = StrReplace(QueryText, "&ConditionIsSemiFinishedProduct", 
		?(ShowContent, "TRUE", QueryTextThisIsASemiFinishedProduct()));
	
	ProductionManagement.SubstitutionOfActualRegisterOfGraph(QueryText);
	
	Return QueryText;
	
EndFunction

Function QueryTextDemand(ShowContent, NameOfTTIssue, ProcessType)
	
	QueryText = 
		"SELECT
		|	Demand.Products                                    AS Products,
		|	Demand.Products.UnitOfMeasure                   AS UnitOfMeasure,
		|	Demand.Products.Presentation                      AS ProductsPresentation,
		|	Demand.Products.ItemsType                    AS ItemsType,
		|	ISNULL(Demand.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces), FALSE) AS PieceByProductList,
		|	Demand.Characteristic                                  AS Characteristic,
		|	Demand.Characteristic.Presentation                    AS CharacteristicPresentation,
		|	Demand.Warehouse                                           AS Warehouse,
		|	Demand.Purpose                                      AS Purpose,
		|	Demand.KeyLot                                      AS KeyLot,
		|	Demand.KeyProducts                                AS KeyProducts,
		|	Demand.StageLink                                      AS StageLink,
		|	Demand.NotProvide                                  AS NotProvide,
		|	Demand.Required2                                       AS Required2,
		|	Demand.DesiredDate                                    AS DesiredDate,
		|	Demand.SemiFinishedProductBOM                       AS SemiFinishedProductBOM,
		|	Demand.SemiFinishedProductBOM = VALUE(Catalog.BillsOfMaterials.EmptyRef)
		|		AND &TextNeedIsMaterial                          AS ThisIsMaterial,
		|	TRUE IN (
		|		SELECT TOP 1
		|			TRUE
		|		FROM
		|			TTIssue AS ProductionIssue
		|		WHERE
		|			ProductionIssue.KeyLot = Demand.KeyLot
		|			AND ProductionIssue.Products = Demand.Products
		|			AND ProductionIssue.Characteristic = Demand.Characteristic
		|			AND NOT ProductionIssue.Canceled)                               AS ItIsIssuedWithinLotReference
		|FROM
		|	TTNeed AS Demand
		|
		|ORDER BY
		|	ThisIsMaterial,
		|	Products,
		|	Characteristic,
		|	&DesiredDate,
		|	KeyLot
		|AUTOORDER";
	
	TextNeedIsMaterial = ?(ShowContent,
		StrReplace("NOT TRUE IN (&ThisIsASemiFinishedProduct)", "&ThisIsASemiFinishedProduct", QueryTextThisIsASemiFinishedProduct("Demand")),
		"FALSE");
	QueryText = StrReplace(QueryText, "&TextNeedIsMaterial", TextNeedIsMaterial);
	
	SortAscending = SortDataInAscendingOrder(ProcessType);
	QueryText = StrReplace(
		QueryText,
		"&DesiredDate",
		?(SortAscending, "DesiredDate", "DesiredDate DESC"));
	
	QueryText = StrReplace(QueryText, "TTIssue", NameOfTTIssue);
	
	Return QueryText;
	
EndFunction

Function RequestTextNeedCollapsed(ShowContent)
	
	QueryText = 
		"SELECT
		|	OrderStructure.KeyLot AS KeyLot,
		|	OrderStructure.Stage       AS StageLink
		|FROM
		|	InformationRegister.OrderStructure AS OrderStructure
		|WHERE
		|	OrderStructure.KeyLot IN(
		|		SELECT
		|			T.KeyLot
		|		FROM
		|			TTSoftware AS T)
		|	AND OrderStructure.LineKind IN(
		|		VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption))
		|	AND TRUE IN(&ConditionIsSemiFinishedProduct)
		|	AND (&Purpose = VALUE(Catalog.Assignments.EmptyRef) OR OrderStructure.Purpose = &Purpose)
		|
		|GROUP BY
		|	OrderStructure.KeyLot,
		|	OrderStructure.Stage
		|
		|HAVING
		|	SUM(OrderStructure.ToSupply) <> 0
		|	OR SUM(OrderStructure.Done) <> 0
		|	OR SUM(OrderStructure.NotProvide) <> 0";
	
	QueryText = StrReplace(QueryText, "&ConditionIsSemiFinishedProduct", 
		?(ShowContent, "TRUE", QueryTextThisIsASemiFinishedProduct()));
	
	Return QueryText;
	
EndFunction

Function TextOfRequestIsPercentageOfCollateralTT(FilterCriterion, ShowContent, Postfix, PostfixKeyReplacement)
	
	QueryText = 
		"SELECT
		|	NestedQuery.KeyLot AS KeyLot,
		|	NestedQuery.Allocated AS Numerator,
		|	NestedQuery.Required2 AS Denominator,
		|	NestedQuery.Allocated/NestedQuery.Required2 AS Supplied
		|INTO TTSupplyPercentage
		|FROM
		|	(
		|	SELECT
		|		NestedQuery2.KeyLot          AS KeyLot,
		|		NestedQuery2.Products        AS Products,
		|		NestedQuery2.Characteristic      AS Characteristic,
		|		SUM(NestedQuery2.Required2)    AS Required2,
		|		SUM(NestedQuery2.Allocated) AS Allocated
		|	FROM
		|		(
		|		SELECT
		|			OrderStructure.KeyLot     AS KeyLot,
		|			OrderStructure.Products   AS Products,
		|			OrderStructure.Characteristic AS Characteristic,
		|			OrderStructure.ToSupply
		|				+ OrderStructure.Done   AS Required2,
		|			OrderStructure.AllocatedFromAvailableInventory 
		|				+ OrderStructure.AllocatedFromAvailableInventoryWithAssignment
		|				+ OrderStructure.Done   AS Allocated
		|		FROM
		|			InformationRegister.OrderStructure AS OrderStructure
		|		WHERE
		|			&FilterCriterion
		|			AND OrderStructure.LineKind IN (
		|				VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption),
		|				VALUE(Enum.KindsOfProductionOrderStructureLines.Reserved))
		|			AND (OrderStructure.ReceiptOrder = UNDEFINED
		|				OR NOT &ShowMovements
		|					AND (OrderStructure.ReceiptOrder REFS Document.TransferOrder
		|						OR OrderStructure.ReceiptOrder REFS Document.OrderOfMaterialsForProduction))
		|			AND TRUE IN(&ConditionIsSemiFinishedProduct)
		|
		|		UNION ALL
		|		
		|		SELECT
		|			OrderStructure.KeyLot     AS KeyLot,
		|			OrderStructure.Products   AS Products,
		|			OrderStructure.Characteristic AS Characteristic,
		|			0                              AS Required2,
		|			Reserves.AllocatedFromAvailableInventory 
		|				+ Reserves.AllocatedFromAvailableInventoryWithAssignment AS Allocated
		|		FROM
		|			TTReplacementKeyProduct AS ReplacementKeyProduct
		|		
		|			INNER JOIN InformationRegister.OrderStructure AS Reserves
		|			ON ReplacementKeyProduct.Products = Reserves.Products
		|				AND ReplacementKeyProduct.Characteristic = Reserves.Characteristic
		|				AND ReplacementKeyProduct.Warehouse = Reserves.Warehouse
		|				AND ReplacementKeyProduct.Purpose = Reserves.Purpose
		|				AND ReplacementKeyProduct.ProductionOrder = Reserves.ProductionOrder
		|				AND ReplacementKeyProduct.KeyProducts = Reserves.KeyProducts
		|				AND ReplacementKeyProduct.KeyLot = Reserves.KeyLot
		|				AND Reserves.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Reserved)
		|				AND (Reserves.ReceiptOrder = UNDEFINED
		|					OR Reserves.ReceiptOrder REFS Document.TransferOrder
		|					OR Reserves.ReceiptOrder REFS Document.OrderOfMaterialsForProduction)
		|		
		|			INNER JOIN InformationRegister.OrderStructure AS OrderStructure
		|			ON ReplacementKeyProduct.Products = OrderStructure.Products
		|				AND ReplacementKeyProduct.Characteristic = OrderStructure.Characteristic
		|				AND ReplacementKeyProduct.ProductionOrder = OrderStructure.ProductionOrder
		|				AND ReplacementKeyProduct.KeyProductReplacement = OrderStructure.KeyProducts
		|				AND OrderStructure.LineKind IN(
		|					VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption))
		|				AND NOT OrderStructure.AdditionalRecord
		|		) AS NestedQuery2
		|
		|	GROUP BY
		|		NestedQuery2.KeyLot,
		|		NestedQuery2.Products,
		|		NestedQuery2.Characteristic
		|	
		|	HAVING
		|		SUM(NestedQuery2.Required2) <> 0
		|	) AS NestedQuery";
	
	QueryText = StrReplace(QueryText, "&FilterCriterion", FilterCriterion);
	QueryText = StrReplace(QueryText, "TTReplacementKeyProduct", "TTReplacementKeyProduct" + PostfixKeyReplacement);
	QueryText = StrReplace(QueryText, "TTSupplyPercentage", "TTSupplyPercentage" + Postfix);
	QueryText = StrReplace(QueryText, "&ConditionIsSemiFinishedProduct", 
		?(ShowContent, "TRUE", QueryTextThisIsASemiFinishedProduct()));
	
	Return QueryText;
	
EndFunction

Function QueryTextPercentageOfCollateral(Postfix)
	
	QueryText = 
		"SELECT
		|	NestedQuery.KeyLot AS KeyLot,
		|	MAX(NestedQuery.Numerator) AS Numerator,
		|	MAX(NestedQuery.Denominator) AS Denominator,
		|	AVG(NestedQuery.Supplied)*100 AS SecuredInterest
		|FROM
		|	(
		|	SELECT
		|		PercentageOfCollateral.KeyLot AS KeyLot,
		|		CASE
		|			WHEN PercentageOfCollateral.Supplied IN 
		|				(
		|					SELECT TOP 1
		|						T.Supplied
		|					FROM
		|						TTSupplyPercentage AS T
		|					WHERE
		|						T.KeyLot = PercentageOfCollateral.KeyLot
		|					ORDER BY
		|						T.Supplied
		|				)
		|				THEN PercentageOfCollateral.Numerator
		|		END AS Numerator,
		|		CASE
		|			WHEN PercentageOfCollateral.Supplied IN 
		|				(
		|					SELECT TOP 1
		|						T.Supplied
		|					FROM
		|						TTSupplyPercentage AS T
		|					WHERE
		|						T.KeyLot = PercentageOfCollateral.KeyLot
		|					ORDER BY
		|						T.Supplied
		|				)
		|				THEN PercentageOfCollateral.Denominator
		|		END AS Denominator,
		|		PercentageOfCollateral.Supplied AS Supplied
		|	FROM
		|		TTSupplyPercentage AS PercentageOfCollateral
		|	) AS NestedQuery
		|
		|GROUP BY
		|	NestedQuery.KeyLot";
	
	QueryText = StrReplace(QueryText, "TTSupplyPercentage", "TTSupplyPercentage" + Postfix);
	
	Return QueryText;
	
EndFunction

Function QueryTextReleaseOfCollateralBatches(FilterCriterion)
	
	QueryText = 
		"SELECT
		|	OrderStructure.KeyLot       AS KeyLot,
		|	OrderStructure.Products     AS Products,
		|	OrderStructure.Characteristic   AS Characteristic,
		|	OrderStructure.KeyProducts AS KeyProducts,
		|	SUM(OrderStructure.Scheduled + OrderStructure.ReverseKittingScheduled + OrderStructure.AllocatedInFreeProductionLots + OrderStructure.AllocatedInAssignedProductionLots) AS Count
		|FROM
		|	InformationRegister.OrderStructure AS OrderStructure
		|WHERE
		|	&FilterCriterion
		|
		|GROUP BY
		|	OrderStructure.KeyLot,
		|	OrderStructure.Products,
		|	OrderStructure.Characteristic,
		|	OrderStructure.KeyProducts
		|
		|HAVING
		|	SUM(OrderStructure.Scheduled + OrderStructure.ReverseKittingScheduled + OrderStructure.AllocatedInFreeProductionLots + OrderStructure.AllocatedInAssignedProductionLots) > 0
		|
		|TOTALS
		|	SUM(Count)
		|BY
		|	KeyLot,
		|	Products,
		|	Characteristic";
	
	QueryText = StrReplace(QueryText, "&FilterCriterion", FilterCriterion);
	
	Return QueryText;
	
EndFunction

Function TextOfRequestIsPercentageOfProvisionOfTTStages(FilterCriterion, ShowContent, Postfix, PostfixKeyReplacement)
	
	QueryText = 
		"SELECT
		|	NestedQuery.KeyLot AS KeyLot,
		|	NestedQuery.Stage AS Stage,
		|	NestedQuery.Allocated AS Numerator,
		|	NestedQuery.Required2 AS Denominator,
		|	NestedQuery.Allocated/NestedQuery.Required2 AS Supplied
		|INTO TTIsPercentageOfProvisionOfStages
		|FROM
		|	(
		|	SELECT
		|		NestedQuery2.KeyLot          AS KeyLot,
		|		NestedQuery2.Stage                AS Stage,
		|		NestedQuery2.Products        AS Products,
		|		NestedQuery2.Characteristic      AS Characteristic,
		|		SUM(NestedQuery2.Required2)    AS Required2,
		|		SUM(NestedQuery2.Allocated) AS Allocated
		|	FROM
		|		(
		|		SELECT
		|			OrderStructure.KeyLot     AS KeyLot,
		|			OrderStructure.Stage           AS Stage,
		|			OrderStructure.Products   AS Products,
		|			OrderStructure.Characteristic AS Characteristic,
		|			OrderStructure.ToSupply
		|				+ OrderStructure.Done   AS Required2,
		|			OrderStructure.AllocatedFromAvailableInventory 
		|				+ OrderStructure.AllocatedFromAvailableInventoryWithAssignment
		|				+ OrderStructure.Done   AS Allocated
		|		FROM
		|			InformationRegister.OrderStructure AS OrderStructure
		|		WHERE
		|			&FilterCriterion
		|			AND OrderStructure.LineKind IN (
		|				VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption),
		|				VALUE(Enum.KindsOfProductionOrderStructureLines.Reserved))
		|			AND (OrderStructure.ReceiptOrder = UNDEFINED
		|				OR NOT &ShowMovements
		|					AND (OrderStructure.ReceiptOrder REFS Document.TransferOrder
		|						OR OrderStructure.ReceiptOrder REFS Document.OrderOfMaterialsForProduction))
		|			AND TRUE IN(&ConditionIsSemiFinishedProduct)
		|
		|		UNION ALL
		|		
		|		SELECT
		|			OrderStructure.KeyLot     AS KeyLot,
		|			OrderStructure.Stage           AS Stage,
		|			OrderStructure.Products   AS Products,
		|			OrderStructure.Characteristic AS Characteristic,
		|			0                              AS Required2,
		|			Reserves.AllocatedFromAvailableInventory 
		|				+ Reserves.AllocatedFromAvailableInventoryWithAssignment AS Allocated
		|		FROM
		|			TTReplacementKeyProduct AS ReplacementKeyProduct
		|		
		|			INNER JOIN InformationRegister.OrderStructure AS Reserves
		|			ON ReplacementKeyProduct.Products = Reserves.Products
		|				AND ReplacementKeyProduct.Characteristic = Reserves.Characteristic
		|				AND ReplacementKeyProduct.Warehouse = Reserves.Warehouse
		|				AND ReplacementKeyProduct.Purpose = Reserves.Purpose
		|				AND ReplacementKeyProduct.ProductionOrder = Reserves.ProductionOrder
		|				AND ReplacementKeyProduct.KeyProducts = Reserves.KeyProducts
		|				AND ReplacementKeyProduct.KeyLot = Reserves.KeyLot
		|				AND Reserves.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Reserved)
		|				AND (Reserves.ReceiptOrder = UNDEFINED
		|					OR Reserves.ReceiptOrder REFS Document.TransferOrder
		|					OR Reserves.ReceiptOrder REFS Document.OrderOfMaterialsForProduction)
		|		
		|			INNER JOIN InformationRegister.OrderStructure AS OrderStructure
		|			ON ReplacementKeyProduct.Products = OrderStructure.Products
		|				AND ReplacementKeyProduct.Characteristic = OrderStructure.Characteristic
		|				AND ReplacementKeyProduct.ProductionOrder = OrderStructure.ProductionOrder
		|				AND ReplacementKeyProduct.KeyProductReplacement = OrderStructure.KeyProducts
		|				AND OrderStructure.LineKind IN(
		|					VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption))
		|				AND NOT OrderStructure.AdditionalRecord
		|		) AS NestedQuery2
		|
		|	GROUP BY
		|		NestedQuery2.KeyLot,
		|		NestedQuery2.Stage,
		|		NestedQuery2.Products,
		|		NestedQuery2.Characteristic
		|	
		|	HAVING
		|		SUM(NestedQuery2.Required2) <> 0
		|	) AS NestedQuery";
	
	QueryText = StrReplace(QueryText, "&FilterCriterion", FilterCriterion);
	QueryText = StrReplace(QueryText, "TTReplacementKeyProduct", "TTReplacementKeyProduct" + PostfixKeyReplacement);
	QueryText = StrReplace(QueryText, "TTIsPercentageOfProvisionOfStages", "TTIsPercentageOfProvisionOfStages" + Postfix);
	QueryText = StrReplace(QueryText, "&ConditionIsSemiFinishedProduct", 
		?(ShowContent, "TRUE", QueryTextThisIsASemiFinishedProduct()));
	
	Return QueryText;
	
EndFunction

Function RequestTextPercentageOfStageProvision(Postfix)
	
	QueryText = 
		"SELECT
		|	NestedQuery.KeyLot AS KeyLot,
		|	NestedQuery.Stage AS StageLink,
		|	MAX(NestedQuery.Numerator) AS Numerator,
		|	MAX(NestedQuery.Denominator) AS Denominator,
		|	AVG(NestedQuery.Supplied)*100 AS SecuredInterest
		|FROM
		|	(
		|	SELECT
		|		PercentageOfCollateral.KeyLot AS KeyLot,
		|		PercentageOfCollateral.Stage AS Stage,
		|		CASE
		|			WHEN PercentageOfCollateral.Supplied IN 
		|				(
		|					SELECT TOP 1
		|						T.Supplied
		|					FROM
		|						TTIsPercentageOfProvisionOfStages AS T
		|					WHERE
		|						T.KeyLot = PercentageOfCollateral.KeyLot
		|						AND T.Stage = PercentageOfCollateral.Stage
		|					ORDER BY
		|						T.Supplied
		|				)
		|				THEN PercentageOfCollateral.Numerator
		|		END AS Numerator,
		|		CASE
		|			WHEN PercentageOfCollateral.Supplied IN 
		|				(
		|					SELECT TOP 1
		|						T.Supplied
		|					FROM
		|						TTIsPercentageOfProvisionOfStages AS T
		|					WHERE
		|						T.KeyLot = PercentageOfCollateral.KeyLot
		|						AND T.Stage = PercentageOfCollateral.Stage
		|					ORDER BY
		|						T.Supplied
		|				)
		|				THEN PercentageOfCollateral.Denominator
		|		END AS Denominator,
		|		PercentageOfCollateral.Supplied AS Supplied
		|	FROM
		|		TTIsPercentageOfProvisionOfStages AS PercentageOfCollateral
		|	) AS NestedQuery
		|
		|GROUP BY
		|	NestedQuery.KeyLot,
		|	NestedQuery.Stage";
	
	QueryText = StrReplace(QueryText, "TTIsPercentageOfProvisionOfStages", "TTIsPercentageOfProvisionOfStages" + Postfix);
	
	Return QueryText;
	
EndFunction

Function QueryTextsSupplyTT()
	
	QueryTexts = New ValueList;
	
	QueryText = 
		"SELECT DISTINCT
		|	T.KeyLot AS KeyLot
		|INTO TTPartySoftware
		|FROM
		|	InformationRegister.OrderStructure AS T
		|WHERE
		|	(T.Products, T.Characteristic, T.Warehouse, T.Purpose, T.ProductionOrder, T.KeyProducts) IN(
		|		SELECT
		|			Demand.Products        AS Products,
		|			Demand.Characteristic      AS Characteristic,
		|			Demand.Warehouse               AS Warehouse,
		|			Demand.Purpose          AS Purpose,
		|			Demand.ProductionOrder AS ProductionOrder,
		|			Demand.KeyProducts    AS KeyProducts
		|		FROM
		|			TTNeed AS Demand
		|		
		|		UNION ALL
		|		
		|		SELECT
		|			KeyReplacement.Products        AS Products,
		|			KeyReplacement.Characteristic      AS Characteristic,
		|			KeyReplacement.Warehouse               AS Warehouse,
		|			KeyReplacement.Purpose          AS Purpose,
		|			KeyReplacement.ProductionOrder AS ProductionOrder,
		|			KeyReplacement.KeyProducts    AS KeyProducts
		|		FROM
		|			TTReplacementKeyProduct AS KeyReplacement)
		|	AND T.LineKind IN(
		|		VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct),
		|		VALUE(Enum.KindsOfProductionOrderStructureLines.Move),
		|		VALUE(Enum.KindsOfProductionOrderStructureLines.Reserved),
		|		VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption))";
	QueryTexts.Add(QueryText, "TTPartySoftware");
	
	QueryText = 
		"SELECT
		|	OrderStructure.KeyLot             AS KeyLot,
		|	OrderStructure.KeyProducts       AS KeyProducts,
		|	OrderStructure.Products           AS Products,
		|	OrderStructure.Characteristic         AS Characteristic,
		|	OrderStructure.Warehouse                  AS Warehouse,
		|	OrderStructure.Purpose             AS Purpose,
		|	OrderStructure.ReceiptOrder     AS ReceiptOrder,
		|	OrderStructure.ProductionOrder    AS ProductionOrder,
		|	OrderStructure.LineKind              AS LineKind,
		|	MAX(CASE
		|			WHEN OrderStructure.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption)
		|				THEN VALUE(Catalog.BillsOfMaterials.EmptyRef)
		|			ELSE OrderStructure.BillOfMaterials
		|		END)                             AS BillOfMaterials,
		|	SUM(OrderStructure.Scheduled) + SUM(OrderStructure.ReverseKittingScheduled) AS Scheduled,
		|	SUM(OrderStructure.AllocatedInFreeProductionLots + OrderStructure.AllocatedInAssignedProductionLots) AS Launched,
		|	SUM(OrderStructure.AllocatedFromAvailableInventory + OrderStructure.AllocatedFromAvailableInventoryWithAssignment + OrderStructure.Done) AS Allocated,
		|	SUM(OrderStructure.AllocatedFromAvailableInventoryWithAssignment) AS AllocatedFromAssignedInventory,
		|	SUM(OrderStructure.AllocatedFromAvailableInventory) AS FreeStocksHaveBeenDistributed
		|INTO TTOrderStructureProvision
		|FROM
		|	InformationRegister.OrderStructure AS OrderStructure
		|	
		|WHERE
		|	OrderStructure.KeyLot IN(
		|		SELECT
		|			T.KeyLot
		|		FROM
		|			TTPartySoftware AS T)
		|	AND OrderStructure.LineKind IN(
		|		VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct),
		|		VALUE(Enum.KindsOfProductionOrderStructureLines.Move),
		|		VALUE(Enum.KindsOfProductionOrderStructureLines.Reserved),
		|		VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption))
		|
		|GROUP BY
		|	OrderStructure.KeyLot,
		|	OrderStructure.Products,
		|	OrderStructure.Characteristic,
		|	OrderStructure.Warehouse,
		|	OrderStructure.Purpose,
		|	OrderStructure.ProductionOrder,
		|	OrderStructure.KeyProducts,
		|	OrderStructure.LineKind,
		|	OrderStructure.ReceiptOrder
		|
		|HAVING
		|	SUM(OrderStructure.Scheduled) <> 0
		|		OR SUM(OrderStructure.ReverseKittingScheduled) <> 0
		|		OR SUM(OrderStructure.AllocatedFromAvailableInventory) <> 0
		|		OR SUM(OrderStructure.AllocatedFromAvailableInventoryWithAssignment) <> 0
		|		OR SUM(OrderStructure.AllocatedInFreeProductionLots) <> 0
		|		OR SUM(OrderStructure.AllocatedInAssignedProductionLots) <> 0
		|		OR SUM(OrderStructure.Done) <> 0";
	QueryTexts.Add(QueryText, "TTOrderStructureProvision");
	
	QueryText = 
		"SELECT
		|	OrderStructure.KeyLot           AS KeyLot,
		|	ISNULL(KeyReplacement.KeyProductReplacement, OrderStructure.KeyProducts) AS KeyProducts,
		|	OrderStructure.Products         AS Products,
		|	OrderStructure.Characteristic       AS Characteristic,
		|	OrderStructure.Warehouse                AS Warehouse,
		|	OrderStructure.Purpose           AS Purpose,
		|	
		|	CASE
		|		WHEN OrderStructure.ReceiptOrder REFS Document.ProductionStage2_2
		|			THEN CAST(OrderStructure.ReceiptOrder AS Document.ProductionStage2_2).BillOfMaterials
		|		ELSE OrderStructure.BillOfMaterials
		|	END                                AS BillOfMaterials,
		|
		|	OrderStructure.ReceiptOrder   AS ReceiptOrder,
		|
		|	CASE
		|		WHEN OrderStructure.ReceiptOrder REFS Document.ProductionStage2_2
		|			THEN CAST(OrderStructure.ReceiptOrder AS Document.ProductionStage2_2).ProductionLot
		|		ELSE VALUE(Catalog.ProductionLots.EmptyRef)
		|	END                                AS ProductionLot,
		|	
		|	CASE
		|		WHEN OrderStructure.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Reserved)
		|				AND (
		|					OrderStructure.AllocatedFromAssignedInventory <> 0
		|						AND OrderStructure.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
		|					OR OrderStructure.FreeStocksHaveBeenDistributed <> 0
		|						AND OrderStructure.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|				)
		|			THEN
		|				CASE
		|					WHEN OrderStructure.ReceiptOrder REFS Document.ProductionStage2_2
		|							AND CAST(OrderStructure.ReceiptOrder AS Document.ProductionStage2_2).ReferenceOrder <> &OrderDocument
		|						THEN CAST(OrderStructure.ReceiptOrder AS Document.ProductionStage2_2).ReferenceOrder
		|					WHEN OrderStructure.ReceiptOrder REFS Document.ProductionOrder2_2
		|							AND CAST(OrderStructure.ReceiptOrder AS Document.ProductionOrder2_2) <> &OrderDocument
		|						THEN OrderStructure.ReceiptOrder
		|					ELSE VALUE(Document.ProductionOrder2_2.EmptyRef)
		|				END
		|		ELSE VALUE(Document.ProductionOrder2_2.EmptyRef)
		|	END AS LaunchOrder,
		|
		|	OrderStructure.LineKind = VALUE(
		|		Enum.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct) AS ThisIsProduction,
		|
		|	OrderStructure.LineKind = VALUE(
		|		Enum.KindsOfProductionOrderStructureLines.Move) AS ItIsTransfer,
		|
		|	OrderStructure.LineKind IN(
		|		VALUE(Enum.KindsOfProductionOrderStructureLines.Reserved),
		|		VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption)) AS IsReserve,
		|
		|	ISNULL(CacheOfOrderStructureMasterData.SupplyType,
		|		VALUE(Enum.SupplyTypes.EmptyRef)) AS SupplyType,
		|
		|	SUM(OrderStructure.Scheduled) AS Scheduled,
		|	SUM(OrderStructure.Launched)      AS Launched,
		|	SUM(OrderStructure.Allocated)  AS Allocated,
		|
		|	MIN(
		|		CASE
		|			WHEN OrderStructure.ReceiptOrder REFS Document.ProductionStage2_2
		|				THEN ISNULL(ScheduleOfLotReferencesOfStages.Begin, DATETIME(1,1,1))
		|			WHEN OrderStructure.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Reserved)
		|				THEN DATETIME(1,1,1)
		|			ELSE ISNULL(Schedule.Begin, DATETIME(1,1,1))
		|		END)                           AS Begin,
		|
		|	MAX(
		|		CASE
		|			WHEN OrderStructure.ReceiptOrder REFS Document.ProductionStage2_2
		|				THEN ISNULL(ScheduleOfLotReferencesOfStages.Ending, DATETIME(1,1,1))
		|			WHEN OrderStructure.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Reserved)
		|				THEN DATETIME(1,1,1)
		|			ELSE ISNULL(Schedule.Ending, DATETIME(1,1,1))
		|		END)                           AS Ending
		|INTO TTSoftware
		|FROM
		|	TTOrderStructureProvision AS OrderStructure
		|
		|	LEFT JOIN InformationRegister.ScheduleOfProductionStages2_2 AS ScheduleOfStages
		|	ON OrderStructure.ReceiptOrder REFS Document.ProductionStage2_2
		|		AND ScheduleOfStages.ScheduleStatus = &StatusWorkingSchedule
		|		AND OrderStructure.ReceiptOrder = ScheduleOfStages.Stage
		|
		|	LEFT JOIN InformationRegister.ScheduleOfProductionStages2_2 AS ScheduleOfLotReferencesOfStages
		|	ON ScheduleOfStages.ProductionOrder = ScheduleOfLotReferencesOfStages.ProductionOrder
		|		AND ScheduleOfLotReferencesOfStages.ScheduleStatus = &StatusWorkingSchedule
		|		AND ScheduleOfStages.KeyLot = ScheduleOfLotReferencesOfStages.KeyLot
		|		AND ScheduleOfLotReferencesOfStages.Stage= VALUE(Catalog.ProductionStages.EmptyRef)
		|
		|	LEFT JOIN InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
		|	ON OrderStructure.ProductionOrder = Schedule.ProductionOrder
		|		AND Schedule.ScheduleStatus = &StatusWorkingSchedule
		|		AND OrderStructure.KeyLot = Schedule.KeyLot
		|		AND Schedule.Stage= VALUE(Catalog.ProductionStages.EmptyRef)
		|
		|	LEFT JOIN TTReplacementKeyProduct AS KeyReplacement
		|	ON OrderStructure.Products = KeyReplacement.Products
		|		AND OrderStructure.Characteristic = KeyReplacement.Characteristic
		|		AND OrderStructure.Warehouse = KeyReplacement.Warehouse
		|		AND OrderStructure.Purpose = KeyReplacement.Purpose
		|		AND OrderStructure.ProductionOrder = KeyReplacement.ProductionOrder
		|		AND OrderStructure.KeyProducts = KeyReplacement.KeyProducts
		|
		|	LEFT JOIN InformationRegister.CacheOfOrderStructureMasterData AS CacheOfOrderStructureMasterData
		|	ON OrderStructure.Products = CacheOfOrderStructureMasterData.Products
		|		AND OrderStructure.Characteristic = CacheOfOrderStructureMasterData.Characteristic
		|		AND OrderStructure.Warehouse = CacheOfOrderStructureMasterData.Warehouse
		|		AND OrderStructure.Purpose = CacheOfOrderStructureMasterData.Purpose
		|		AND OrderStructure.ProductionOrder = CacheOfOrderStructureMasterData.ProductionOrder
		|
		|GROUP BY
		|	OrderStructure.KeyLot,
		|	ISNULL(KeyReplacement.KeyProductReplacement, OrderStructure.KeyProducts),
		|	OrderStructure.Products,
		|	OrderStructure.Characteristic,
		|	OrderStructure.Warehouse,
		|	OrderStructure.Purpose,
		|	CASE
		|		WHEN OrderStructure.ReceiptOrder REFS Document.ProductionStage2_2
		|			THEN CAST(OrderStructure.ReceiptOrder AS Document.ProductionStage2_2).BillOfMaterials
		|		ELSE OrderStructure.BillOfMaterials
		|	END,
		|	OrderStructure.ReceiptOrder,
		|	CASE
		|		WHEN OrderStructure.ReceiptOrder REFS Document.ProductionStage2_2
		|			THEN CAST(OrderStructure.ReceiptOrder AS Document.ProductionStage2_2).ProductionLot
		|		ELSE VALUE(Catalog.ProductionLots.EmptyRef)
		|	END,
		|	CASE
		|		WHEN OrderStructure.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Reserved)
		|				AND (
		|					OrderStructure.AllocatedFromAssignedInventory <> 0
		|						AND OrderStructure.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
		|					OR OrderStructure.FreeStocksHaveBeenDistributed <> 0
		|						AND OrderStructure.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|				)
		|			THEN
		|				CASE
		|					WHEN OrderStructure.ReceiptOrder REFS Document.ProductionStage2_2
		|							AND CAST(OrderStructure.ReceiptOrder AS Document.ProductionStage2_2).ReferenceOrder <> &OrderDocument
		|						THEN CAST(OrderStructure.ReceiptOrder AS Document.ProductionStage2_2).ReferenceOrder
		|					WHEN OrderStructure.ReceiptOrder REFS Document.ProductionOrder2_2
		|							AND CAST(OrderStructure.ReceiptOrder AS Document.ProductionOrder2_2) <> &OrderDocument
		|						THEN OrderStructure.ReceiptOrder
		|					ELSE VALUE(Document.ProductionOrder2_2.EmptyRef)
		|				END
		|		ELSE VALUE(Document.ProductionOrder2_2.EmptyRef)
		|	END,
		|	OrderStructure.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct),
		|	OrderStructure.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Move),
		|	OrderStructure.LineKind IN(
		|		VALUE(Enum.KindsOfProductionOrderStructureLines.Reserved),
		|		VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption)),
		|	ISNULL(CacheOfOrderStructureMasterData.SupplyType, VALUE(Enum.SupplyTypes.EmptyRef))
		|
		|INDEX BY
		|	KeyLot";
	ProductionManagement.SubstitutionOfActualRegisterOfGraph(QueryText);
	QueryTexts.Add(QueryText, "TTSoftware");
	
	QueryText = 
		"SELECT
		|	OrderStructure.KeyLot                    AS KeyLot,
		|	OrderStructure.Products                  AS Products,
		|	OrderStructure.Products.UnitOfMeasure AS UnitOfMeasure,
		|	SUM(OrderStructure.Scheduled) + SUM(OrderStructure.ReverseKittingScheduled) AS Scheduled
		|INTO TTBatchSize
		|FROM
		|	InformationRegister.OrderStructure AS OrderStructure
		|WHERE
		|	&StagesShow
		|	AND (OrderStructure.Products, OrderStructure.Characteristic, OrderStructure.KeyLot) IN 
		|		(SELECT
		|			Supply.Products,
		|			Supply.Characteristic,
		|			Supply.KeyLot
		|		FROM
		|			TTSoftware AS Supply)
		|
		|GROUP BY
		|	OrderStructure.KeyLot,
		|	OrderStructure.Products,
		|	OrderStructure.Products.UnitOfMeasure
		|
		|HAVING
		|	SUM(OrderStructure.Scheduled) > 0
		|	OR SUM(OrderStructure.ReverseKittingScheduled) > 0
		|
		|INDEX BY
		|	KeyLot";
	QueryTexts.Add(QueryText, "TTBatchSize");
	
	Return QueryTexts;
	
EndFunction

Function QueryTextKeysOfLotReferencesOfStagesSupplyOfTT()
	
	Return
		"SELECT DISTINCT
		|	Supply.KeyLot AS KeyLot,
		|	CASE
		|		WHEN Supply.ProductionLot = VALUE(Catalog.ProductionLots.EmptyRef)
		|			THEN Supply.BillOfMaterials
		|		ELSE Supply.ProductionLot
		|	END                  AS Ref
		|INTO TTKeysOfLotReferencesOfStagesSupply
		|FROM
		|	TTSoftware AS Supply
		|WHERE
		|	NOT Supply.IsReserve
		|
		|INDEX BY SETS (
		|	(KeyLot),
		|	(Ref)
		|)";
	
EndFunction

Function TextOfRequestReplacementKeyProductTT(FilterCriterion, Postfix)
	
	QueryText =
		"SELECT
		|	OrderStructure.Products                AS Products,
		|	OrderStructure.Characteristic              AS Characteristic,
		|	OrderStructure.Warehouse                       AS Warehouse,
		|	OrderStructure.Purpose                  AS Purpose,
		|	OrderStructure.ProductionOrder         AS ProductionOrder,
		|	OrderStructure.KeyProducts            AS KeyProducts,
		|	OrderStructure.KeyLot                  AS KeyLot,
		|	OrderStructure.ConnectionKeyTransfer        AS KeyProductReplacement
		|INTO TTReplacementKeyProduct
		|FROM
		|	InformationRegister.OrderStructure AS OrderStructure
		|WHERE
		|	NOT &ShowMovements
		|	AND (OrderStructure.Products, OrderStructure.Characteristic, OrderStructure.ProductionOrder, OrderStructure.ConnectionKeyTransfer) IN
		|		(&FilterCriterion)
		|	AND TRUE IN
		|		(SELECT TOP 1
		|			TRUE
		|		FROM
		|			InformationRegister.OrderStructure AS Transfers
		|		WHERE
		|			Transfers.KeyLot = OrderStructure.KeyLot
		|			AND Transfers.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Move))
		|	AND OrderStructure.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption)
		|GROUP BY
		|	OrderStructure.Products,
		|	OrderStructure.Characteristic,
		|	OrderStructure.Warehouse,
		|	OrderStructure.Purpose,
		|	OrderStructure.ProductionOrder,
		|	OrderStructure.KeyLot,
		|	OrderStructure.KeyProducts,
		|	OrderStructure.ConnectionKeyTransfer
		|HAVING
		|	SUM(OrderStructure.ToSupply) <> 0
		|
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose, ProductionOrder, KeyProducts";
	
	QueryText = StrReplace(QueryText, "&FilterCriterion", FilterCriterion);
	QueryText = StrReplace(QueryText, "TTReplacementKeyProduct", "TTReplacementKeyProduct" + Postfix);
	
	Return QueryText;
	
EndFunction

Function QueryTextSupply(ProcessType)
	
	QueryText =
		"SELECT
		|	Supply.KeyLot         AS KeyLot,
		|	Supply.KeyProducts   AS KeyProducts,
		|	Supply.BillOfMaterials       AS BillOfMaterials,
		|	Supply.ReceiptOrder AS ReceiptOrder,
		|	Supply.ProductionLot AS ProductionLot,
		|	Supply.LaunchOrder      AS LaunchOrder,
		|	Supply.LaunchOrder <> VALUE(Document.ProductionOrder2_2.EmptyRef)
		|		AND Supply.ReceiptOrder REFS Document.ProductionStage2_2
		|		AND NOT TRUE IN (
		|			SELECT TOP 1 
		|				TRUE
		|			FROM
		|				Document.ProductionOrder2_2.ManufacturedProduct AS T
		|			WHERE
		|				T.Ref = Supply.LaunchOrder
		|				AND T.Products = Supply.Products
		|				AND T.Characteristic = Supply.Characteristic
		|				AND CASE 
		|					WHEN T.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|							OR T.ToExpenseAs
		|						THEN T.Department
		|					ELSE T.Warehouse
		|				END = Supply.Warehouse
		|				AND CASE
		|					WHEN T.Ref.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.WithoutBillsOfMaterials)
		|							AND NOT T.ToExpenseAs
		|						THEN T.Ref.AssignmentProducts
		|					ELSE T.Purpose
		|				END = Supply.Purpose
		|				AND NOT T.Canceled)   AS DecodingLaunchInStages,
		|	Supply.ThisIsProduction    AS ThisIsProduction,
		|	Supply.ItIsTransfer     AS ItIsTransfer,
		|	Supply.IsReserve          AS IsReserve,
		|	Supply.SupplyType     AS SupplyType,
		|	Supply.Launched           AS Launched,
		|	Supply.Allocated       AS Allocated,
		|	Supply.Begin             AS Begin,
		|	Supply.Ending          AS Ending,
		|	Supply.Warehouse              AS Warehouse,
		|	ISNULL(GraphTotal.Begin, DATETIME(1,1,1))    AS BeginningOfLotReference,
		|	ISNULL(GraphTotal.Ending, DATETIME(1,1,1)) AS EndOfLotReference
		|FROM
		|	TTSoftware AS Supply
		|
		|	LEFT JOIN InformationRegister.ScheduleOfProductionStages2_2 AS GraphTotal
		|	ON GraphTotal.ProductionOrder = &OrderDocument
		|		AND GraphTotal.ScheduleStatus = &StatusWorkingSchedule
		|		AND Supply.KeyLot = GraphTotal.KeyLot
		|		AND GraphTotal.Stage = VALUE(Catalog.ProductionStages.EmptyRef)
		|WHERE
		|	&TextIsNotProductionOfGoodsInNeedOfRAndM
		|
		|ORDER BY
		|	&BeginningOfLotReference,
		|	&EndOfLotReference";
	
	ProductionManagement.SubstitutionOfActualRegisterOfGraph(QueryText);
	
	SubstitutionText = "TRUE";
	If ProcessType = Enums.ProductionProcessTypes.PerformRM Then
		SubstitutionText = 
			"Supply.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
			|OR NOT Supply.ThisIsProduction";
	EndIf;
	QueryText = StrReplace(QueryText, "&TextIsNotProductionOfGoodsInNeedOfRAndM", SubstitutionText);
	
	SortAscending = SortDataInAscendingOrder(ProcessType);
	QueryText = StrReplace(
		QueryText,
		"&BeginningOfLotReference",
		?(SortAscending, "BeginningOfLotReference", "BeginningOfLotReference DESC"));
	QueryText = StrReplace(
		QueryText,
		"&EndOfLotReference",
		?(SortAscending, "EndOfLotReference", "EndOfLotReference DESC"));
	
	Return QueryText;
	
EndFunction

Function QueryTextStages(TableNameKeys, TableNameBatchSize, ProcessType)
	
	QueryText =
		"SELECT
		|	Lots.KeyLot                                           AS KeyLot,
		|	VALUE(Catalog.ProductionLots.EmptyRef)        AS ProductionLot,
		|	Stages.Owner                                              AS BillOfMaterials,
		|	Stages.Ref                                                AS StageLink,
		|	Stages.Description                                          AS StageName,
		|	Stages.Department                                         AS Department,
		|	Stages.StageNumber                                            AS StageNumber,
		|	Stages.NextStageNo                                  AS NextStageNo,
		|	ISNULL(Schedule.Begin, DATETIME(1,1,1))                   AS Begin,
		|	ISNULL(Schedule.Ending, DATETIME(1,1,1))                AS Ending,
		|	ISNULL(BatchesSize.Products, UNDEFINED)           AS Products,
		|	ISNULL(BatchesSize.UnitOfMeasure, UNDEFINED)       AS UnitOfMeasure,
		|	ISNULL(BatchesSize.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces), FALSE) AS PieceByProductList,
		|	ISNULL(BatchesSize.Scheduled, 0)                     AS Required2,
		|	0                                                           AS Launched,
		|	0                                                           AS Done,
		|	Stages.ProductionByThirdParty                                 AS ProductionByThirdParty,
		|	Stages.WorkPlanning                                     AS WorkPlanning,
		|	ISNULL(GraphTotal.Begin, DATETIME(1,1,1))              AS BeginningOfLotReference,
		|	ISNULL(GraphTotal.Ending, DATETIME(1,1,1))           AS EndOfLotReference
		|FROM
		|	&TableNameKeys AS Lots
		|
		|	INNER JOIN Catalog.ProductionStages AS Stages
		|	ON Lots.Ref = Stages.Owner
		|		AND NOT Stages.DeletionMark
		|
		|	LEFT JOIN InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
		|	ON Schedule.ProductionOrder = &OrderDocument
		|		AND Schedule.ScheduleStatus = &StatusWorkingSchedule
		|		AND Lots.KeyLot = Schedule.KeyLot
		|		AND Stages.Ref = Schedule.Stage
		|
		|	LEFT JOIN InformationRegister.ScheduleOfProductionStages2_2 AS GraphTotal
		|	ON GraphTotal.ProductionOrder = &OrderDocument
		|		AND GraphTotal.ScheduleStatus = &StatusWorkingSchedule
		|		AND Lots.KeyLot = GraphTotal.KeyLot
		|		AND GraphTotal.Stage = VALUE(Catalog.ProductionStages.EmptyRef)
		|
		|	LEFT JOIN &TableNameBatchSize AS BatchesSize
		|	ON Lots.KeyLot = BatchesSize.KeyLot
		|
		|UNION ALL
		|
		|SELECT
		|	Lots.KeyLot                                           AS KeyLot,
		|	Stages.ProductionLot                                    AS ProductionLot,
		|	Stages.BillOfMaterials                                          AS BillOfMaterials,
		|	Stages.Ref                                                AS StageLink,
		|	Stages.StageName                                     AS StageName,
		|	Stages.Department                                         AS Department,
		|	Stages.StageNumber                                            AS StageNumber,
		|	Stages.NextStageNo                                  AS NextStageNo,
		|	ISNULL(Schedule.Begin, DATETIME(1,1,1))                   AS Begin,
		|	ISNULL(Schedule.Ending, DATETIME(1,1,1))                AS Ending,
		|	UNDEFINED                                                AS Products,
		|	Stages.ProductionLot.MainProductProducts.UnitOfMeasure AS UnitOfMeasure,
		|	ISNULL(Stages.ProductionLot.MainProductProducts.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces), FALSE) AS PieceByProductList,
		|	Stages.NumberOfPackagesPlan * ISNULL(&PackagingFactorPlan, 1)
		|		- Stages.NumberOfPackagesCanceled * ISNULL(&PackagingFactorCanceled, 1) AS Required2,
		|	CASE
		|		WHEN Stages.Status IN (
		|					VALUE(Enum.StatusesOfProductionStages2_2.ForCompletion),
		|					VALUE(Enum.StatusesOfProductionStages2_2.Initiated))
		|				AND NOT Stages.ProductionByThirdParty
		|			THEN Stages.NumberOfPackagesPlan * ISNULL(&PackagingFactorPlan, 1)
		|					- Stages.NumberOfPackagesCanceled * ISNULL(&PackagingFactorCanceled, 1)
		|					- Stages.NumberOfPackagesReal * ISNULL(&PackagingFactorFact, 1)
		|		ELSE 0
		|	END                                                       AS Launched,
		|	CASE
		|		WHEN Stages.ProductionByThirdParty
		|			THEN 0
		|		ELSE Stages.NumberOfPackagesReal * ISNULL(&PackagingFactorFact, 1)
		|	END                                                       AS Done,
		|	Stages.ProductionByThirdParty                                 AS ProductionByThirdParty,
		|	Stages.WorkPlanning                                     AS WorkPlanning,
		|	ISNULL(GraphTotal.Begin, DATETIME(1,1,1))              AS BeginningOfLotReference,
		|	ISNULL(GraphTotal.Ending, DATETIME(1,1,1))           AS EndOfLotReference
		|FROM
		|	&TableNameKeys AS Lots
		|
		|	INNER JOIN Document.ProductionStage2_2 AS Stages
		|	ON Lots.Ref = Stages.ProductionLot
		|		AND Stages.Posted
		|
		|	LEFT JOIN InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
		|	ON Schedule.ProductionOrder = &OrderDocument
		|		AND Schedule.ScheduleStatus = &StatusWorkingSchedule
		|		AND Lots.KeyLot = Schedule.KeyLot
		|		AND Stages.Ref = Schedule.Stage
		|
		|	LEFT JOIN InformationRegister.ScheduleOfProductionStages2_2 AS GraphTotal
		|	ON GraphTotal.ProductionOrder = &OrderDocument
		|		AND GraphTotal.ScheduleStatus = &StatusWorkingSchedule
		|		AND Lots.KeyLot = GraphTotal.KeyLot
		|		AND GraphTotal.Stage = VALUE(Catalog.ProductionStages.EmptyRef)
		|
		|ORDER BY
		|	&BeginningOfLotReference,
		|	&EndOfLotReference,
		|	KeyLot,
		|	&StageNumber,
		|	&NextStageNo";
	
	ProductionManagement.SubstitutionOfActualRegisterOfGraph(QueryText);
	
	SortAscending = SortDataInAscendingOrder(ProcessType);
	QueryText = StrReplace(
		QueryText,
		"&BeginningOfLotReference",
		?(SortAscending, "BeginningOfLotReference", "BeginningOfLotReference DESC"));
	QueryText = StrReplace(
		QueryText,
		"&EndOfLotReference",
		?(SortAscending, "EndOfLotReference", "EndOfLotReference DESC"));
	QueryText = StrReplace(
		QueryText,
		"&StageNumber",
		?(SortAscending, "StageNumber", "StageNumber DESC"));
	QueryText = StrReplace(
		QueryText,
		"&NextStageNo",
		?(SortAscending, "NextStageNo", "NextStageNo DESC"));
	
	QueryText = StrReplace(
		QueryText,
		"&PackagingFactorPlan",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"Stages.PackagePlan",
			"Stages.ProductionLot.MainProductProducts"));
			
	QueryText = StrReplace(
		QueryText,
		"&PackagingFactorFact",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"Stages.PackageActualData",
			"Stages.ProductionLot.MainProductProducts"));
	
	QueryText = StrReplace(
		QueryText,
		"&PackagingFactorCanceled",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"Stages.PackageCanceled",
			"Stages.ProductionLot.MainProductProducts"));
	
	QueryText = StrReplace(QueryText, "&TableNameKeys", TableNameKeys);
	QueryText = StrReplace(QueryText, "&TableNameBatchSize", TableNameBatchSize);
	
	Return QueryText;
	
EndFunction

Procedure AddQueryTextsForInventoryAllocation(QueryTexts)
	
	QueryText =
		"SELECT
		|	Inventories.Products AS Products,
		|	Inventories.Characteristic AS Characteristic,
		|	Inventories.Warehouse AS Warehouse,
		|	Inventories.Purpose AS Purpose,
		|	Inventories.InStockBalance AS InStockBalance,
		|	Inventories.LockedInStockBalance AS LockedInStockBalance,
		|	Inventories.OrderedBalance AS OrderedBalance,
		|	Inventories.Received_1Balance AS Received_1Balance,
		|	Inventories.LockedReceiptBalance AS LockedReceiptBalance,
		|	Inventories.ReserveAtWarehouseBalance AS ReserveAtWarehouseBalance,
		|	Inventories.ReserveAsReceivedBalance AS ReserveAsReceivedBalance,
		|	Inventories.SnoozeReservationBalance AS SnoozeReservationBalance,
		|	Inventories.ToSupplyBalance AS ToSupplyBalance,
		|	Inventories.NotProvideBalance AS NotProvideBalance
		|INTO InventoryAndDemandsBalance
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		(Products, Characteristic) IN(
		|			SELECT
		|				FilterTable.Products AS Products,
		|				FilterTable.Characteristic AS Characteristic
		|			FROM
		|				TTSoftware AS FilterTable)) AS Inventories
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose";
	QueryTexts.Add(QueryText, "");
		
	QueryText =
		"SELECT
		|	Inventories.Products AS Products,
		|	Inventories.Characteristic AS Characteristic,
		|	Inventories.Warehouse AS Warehouse,
		|	Inventories.Purpose AS Purpose,
		|	Inventories.OrderDocument AS OrderDocument,
		|	Inventories.LockedInStockBalance AS LockedInStockBalance,
		|	Inventories.LockedReceiptBalance AS LockedReceiptBalance,
		|	Inventories.ToUnlockBalance AS ToUnlockBalance,
		|	Inventories.ReserveAtWarehouseFromLockedBalance AS ReserveAtWarehouseFromLockedBalance,
		|	Inventories.ReserveUponReceiptFromLockedBalance AS ReserveUponReceiptFromLockedBalance
		|	
		|INTO InventoryAndNeedsBalanceOfControlledLotsReference
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		(Products, Characteristic) IN(
		|			SELECT
		|				FilterTable.Products AS Products,
		|				FilterTable.Characteristic AS Characteristic
		|			FROM
		|				TTSoftware AS FilterTable)) AS Inventories
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose";
	QueryTexts.Add(QueryText, "");
	
	TablesNames = ProvisionInDocumentsServer.NewTableNamesForInventoryAllocation();
	TablesNames.Balance = "InventoryAndDemandsBalance"; // @query-part-1
	TablesNames.BalanceSheetsOfControlledLotREFERENCES = "InventoryAndNeedsBalanceOfControlledLotsReference"; // @query-part-1
	TablesNames.Result = "CalculationOfInventoryDistribution"; // @query-part-1
	
	Texts = ProvisionInDocumentsServer.InventoryAllocation("", TablesNames, False);
	For Each Text In Texts Do
		QueryTexts.Add(Text, "");
	EndDo;
	
EndProcedure

Function QueryTextBalancesForOtherPurposes()
	
	Return
	"SELECT
	|	Table.Products                                         AS Products,
	|	Table.Characteristic                                       AS Characteristic,
	|	Table.Warehouse                                                AS Warehouse,
	|	Table.Purpose                                           AS Purpose,
	|	MAX(Table.IndexOfImageIsStillFreeOrNotNeeded) AS IndexOfImageIsStillFreeOrNotNeeded,
	|	MAX(Table.IndexOfImageRemainsForOtherPurposes)  AS IndexOfImageRemainsForOtherPurposes,
	|	MAX(Table.IndexOfImageRemainsInAnotherWarehouse)       AS IndexOfImageRemainsInAnotherWarehouse,
	|	MAX(Table.IndexOfImageLeft)                     AS IndexOfImageLeft
	|FROM
	|	(SELECT
	|		Supply.Products   AS Products,
	|		Supply.Characteristic AS Characteristic,
	|		Supply.Warehouse          AS Warehouse,
	|		Supply.Purpose     AS Purpose,
	|		4                          AS IndexOfImageIsStillFreeOrNotNeeded,
	|		0                          AS IndexOfImageRemainsForOtherPurposes,
	|		0                          AS IndexOfImageRemainsInAnotherWarehouse,
	|		4                          AS IndexOfImageLeft
	|	FROM
	|		TTSoftware AS Supply
	|	WHERE
	|		Supply.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
	|		AND TRUE IN (
	|			SELECT TOP 1
	|				TRUE
	|			FROM
	|				CalculationOfInventoryDistribution AS Balance
	|					LEFT JOIN InformationRegister.OrderStructure AS OrderStructure
	|					ON OrderStructure.Products   = Balance.Products
	|					 AND OrderStructure.Characteristic = Balance.Characteristic
	|					 AND OrderStructure.Warehouse          = Balance.Warehouse
	|					 AND OrderStructure.Purpose     = Balance.Purpose
	|					 AND OrderStructure.LineKind      = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption)
	|			WHERE
	|				Balance.Products   = Supply.Products
	|				AND Balance.Characteristic = Supply.Characteristic
	|				AND Balance.Warehouse          = Supply.Warehouse
	|				AND (Balance.Purpose    = VALUE(Catalog.Assignments.EmptyRef)
	|				   OR NOT Balance.Purpose IN (
	|									Supply.Purpose))
	|			GROUP BY
	|				Balance.Purpose
	|			HAVING
	|				MAX(Balance.Available_Surplus + Balance.AvailableWithLock_Surplus) - SUM(ISNULL(OrderStructure.ToSupply, 0)) > 0)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Supply.Products   AS Products,
	|		Supply.Characteristic AS Characteristic,
	|		Supply.Warehouse          AS Warehouse,
	|		Supply.Purpose     AS Purpose,
	|		0                          AS IndexOfImageIsStillFreeOrNotNeeded,
	|		2                          AS IndexOfImageRemainsForOtherPurposes,
	|		0                          AS IndexOfImageRemainsInAnotherWarehouse,
	|		2                          AS IndexOfImageLeft
	|	FROM
	|		TTSoftware AS Supply
	|	WHERE
	|		Supply.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
	|		AND TRUE IN (
	|			SELECT TOP 1
	|				TRUE
	|			FROM
	|				CalculationOfInventoryDistribution AS Balance
	|					LEFT JOIN InformationRegister.OrderStructure AS OrderStructure
	|					ON OrderStructure.Products   = Balance.Products
	|					 AND OrderStructure.Characteristic = Balance.Characteristic
	|					 AND OrderStructure.Warehouse          = Balance.Warehouse
	|					 AND OrderStructure.Purpose     = Balance.Purpose
	|					 AND OrderStructure.LineKind      = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption)
	|			WHERE
	|				Balance.Products   = Supply.Products
	|				AND Balance.Characteristic = Supply.Characteristic
	|				AND Balance.Warehouse          = Supply.Warehouse
	|				AND NOT Balance.Purpose IN (
	|								VALUE(Catalog.Assignments.EmptyRef),
	|								Supply.Purpose)
	|			GROUP BY
	|				Balance.Purpose
	|			HAVING
	|				MAX(Balance.InStock + Balance.AvailableWithLock) > 0
	|				AND MAX(
	|					Balance.ToSupply
	|						+ Balance.Snooze
	|						+ Balance.ToReserveAsNeeded
	|						+ Balance.ToReserve_
	| 						+ Balance.Reserve_FromBlocked
	|						+ Balance.ReserveAsNeeded_FromBlocked)
	|					+ SUM(ISNULL(OrderStructure.ToSupply, 0)) > 0)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Supply.Products   AS Products,
	|		Supply.Characteristic AS Characteristic,
	|		Supply.Warehouse          AS Warehouse,
	|		Supply.Purpose     AS Purpose,
	|		0                          AS IndexOfImageIsStillFreeOrNotNeeded,
	|		0                          AS IndexOfImageRemainsForOtherPurposes,
	|		1                          AS IndexOfImageRemainsInAnotherWarehouse,
	|		1                          AS IndexOfImageLeft
	|	FROM
	|		TTSoftware AS Supply
	|	WHERE
	|		TRUE IN (
	|			SELECT TOP 1
	|				TRUE
	|			FROM
	|				CalculationOfInventoryDistribution AS Balance
	|			WHERE
	|				Balance.Products   = Supply.Products
	|				AND Balance.Characteristic = Supply.Characteristic
	|				AND Balance.Warehouse         <> Supply.Warehouse
	|				AND Balance.Purpose     = VALUE(Catalog.Assignments.EmptyRef)
	|				AND Balance.Available_Postpone
	|					+ Balance.InStock_K
	|					+ Balance.Available_Surplus > 0
	|				AND NOT TRUE IN (
	|						SELECT TOP 1
	|							TRUE
	|						FROM
	|							InformationRegister.OrderStructure AS OrderStructure
	|						WHERE
	|							OrderStructure.KeyLot       = Supply.KeyLot
	|							AND OrderStructure.Products   = Supply.Products
	|							AND OrderStructure.Characteristic = Supply.Characteristic
	|							AND OrderStructure.Warehouse          = Balance.Warehouse
	|							AND OrderStructure.LineKind     <> VALUE(Enum.KindsOfProductionOrderStructureLines.Move)
	|							AND TRUE IN (
	|								SELECT TOP 1
	|									TRUE
	|								FROM
	|									InformationRegister.OrderStructure AS OrderStructure
	|								WHERE
	|									OrderStructure.KeyLot       = Supply.KeyLot
	|									AND OrderStructure.Products   = Supply.Products
	|									AND OrderStructure.Characteristic = Supply.Characteristic
	|									AND OrderStructure.Warehouse          = Supply.Warehouse
	|									AND OrderStructure.LineKind      = VALUE(Enum.KindsOfProductionOrderStructureLines.Move))))
	|		AND NOT TRUE IN (
	|				SELECT TOP 1
	|					TRUE
	|				FROM
	|					InformationRegister.OrderStructure AS OrderStructure
	|				WHERE
	|					OrderStructure.Products       = Supply.Products
	|					AND OrderStructure.Characteristic   = Supply.Characteristic
	|					AND OrderStructure.Warehouse            = Supply.Warehouse
	|					AND OrderStructure.KeyProducts = Supply.KeyProducts
	|					AND OrderStructure.KeyLot      <> Supply.KeyLot
	|					AND TRUE IN (
	|						SELECT TOP 1
	|							TRUE
	|						FROM
	|							InformationRegister.OrderStructure AS OrderStructureMoving
	|						WHERE
	|							OrderStructureMoving.Products      = Supply.Products
	|							AND OrderStructureMoving.Characteristic  = Supply.Characteristic
	|							AND OrderStructureMoving.Warehouse          <> Supply.Warehouse
	|							AND OrderStructureMoving.KeyLot      = OrderStructure.KeyLot
	|							AND OrderStructureMoving.LineKind       = VALUE(Enum.KindsOfProductionOrderStructureLines.Move)))
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Supply.Products   AS Products,
	|		Supply.Characteristic AS Characteristic,
	|		Supply.Warehouse          AS Warehouse,
	|		Supply.Purpose     AS Purpose,
	|		0                          AS IndexOfImageIsStillFreeOrNotNeeded,
	|		0                          AS IndexOfImageRemainsForOtherPurposes,
	|		1                          AS IndexOfImageRemainsInAnotherWarehouse,
	|		1                          AS IndexOfImageLeft
	|	FROM
	|		TTSoftware AS Supply
	|	WHERE
	|		TRUE IN (
	|			SELECT TOP 1
	|				TRUE
	|			FROM
	|				CalculationOfInventoryDistribution AS Balance
	|			WHERE
	|				Balance.Products   = Supply.Products
	|				AND Balance.Characteristic = Supply.Characteristic
	|				AND Balance.Warehouse         <> Supply.Warehouse
	|				AND Balance.Purpose    <> VALUE(Catalog.Assignments.EmptyRef)
	|				AND Balance.InStock + Balance.AvailableWithLock > 0
	|				AND NOT TRUE IN (
	|						SELECT TOP 1
	|							TRUE
	|						FROM
	|							InformationRegister.OrderStructure AS OrderStructure
	|						WHERE
	|							OrderStructure.KeyLot       = Supply.KeyLot
	|							AND OrderStructure.Products   = Supply.Products
	|							AND OrderStructure.Characteristic = Supply.Characteristic
	|							AND OrderStructure.Warehouse          = Balance.Warehouse
	|							AND OrderStructure.LineKind     <> VALUE(Enum.KindsOfProductionOrderStructureLines.Move)
	|							AND TRUE IN (
	|								SELECT TOP 1
	|									TRUE
	|								FROM
	|									InformationRegister.OrderStructure AS OrderStructure
	|								WHERE
	|									OrderStructure.KeyLot       = Supply.KeyLot
	|									AND OrderStructure.Products   = Supply.Products
	|									AND OrderStructure.Characteristic = Supply.Characteristic
	|									AND OrderStructure.Warehouse          = Supply.Warehouse
	|									AND OrderStructure.LineKind      = VALUE(Enum.KindsOfProductionOrderStructureLines.Move))))
	|		AND NOT TRUE IN (
	|				SELECT TOP 1
	|					TRUE
	|				FROM
	|					InformationRegister.OrderStructure AS OrderStructure
	|				WHERE
	|					OrderStructure.Products       = Supply.Products
	|					AND OrderStructure.Characteristic   = Supply.Characteristic
	|					AND OrderStructure.Warehouse            = Supply.Warehouse
	|					AND OrderStructure.KeyProducts = Supply.KeyProducts
	|					AND OrderStructure.KeyLot      <> Supply.KeyLot
	|					AND TRUE IN (
	|						SELECT TOP 1
	|							TRUE
	|						FROM
	|							InformationRegister.OrderStructure AS OrderStructureMoving
	|						WHERE
	|							OrderStructureMoving.Products      = Supply.Products
	|							AND OrderStructureMoving.Characteristic  = Supply.Characteristic
	|							AND OrderStructureMoving.Warehouse          <> Supply.Warehouse
	|							AND OrderStructureMoving.KeyLot      = OrderStructure.KeyLot
	|							AND OrderStructureMoving.LineKind       = VALUE(Enum.KindsOfProductionOrderStructureLines.Move)))) AS Table
	|	
	|GROUP BY
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.Warehouse,
	|	Table.Purpose
	|";
	
EndFunction

Function QueryTextBalancesForOtherAssignmentsInQuantitativeTerms() Export
	
	QueryTexts = New Array();
	QueryText =
		"SELECT
		|	Inventories.Products AS Products,
		|	Inventories.Characteristic AS Characteristic,
		|	Inventories.Warehouse AS Warehouse,
		|	Inventories.Purpose AS Purpose,
		|	Inventories.InStockBalance AS InStockBalance,
		|	Inventories.LockedInStockBalance AS LockedInStockBalance,
		|	Inventories.OrderedBalance AS OrderedBalance,
		|	Inventories.Received_1Balance AS Received_1Balance,
		|	Inventories.LockedReceiptBalance AS LockedReceiptBalance,
		|	Inventories.ReserveAtWarehouseBalance AS ReserveAtWarehouseBalance,
		|	Inventories.ReserveAsReceivedBalance AS ReserveAsReceivedBalance,
		|	Inventories.SnoozeReservationBalance AS SnoozeReservationBalance,
		|	Inventories.ToSupplyBalance AS ToSupplyBalance,
		|	Inventories.NotProvideBalance AS NotProvideBalance
		|INTO InventoryAndDemandsBalance
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		Products = &Products
		|			AND Characteristic = &Characteristic) AS Inventories
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose
		|;
		|
		|//////////////////////////////////////////////////////
		|SELECT
		|	Inventories.Products AS Products,
		|	Inventories.Characteristic AS Characteristic,
		|	Inventories.Warehouse AS Warehouse,
		|	Inventories.Purpose AS Purpose,
		|	Inventories.OrderDocument AS OrderDocument,
		|	Inventories.LockedInStockBalance AS LockedInStockBalance,
		|	Inventories.LockedReceiptBalance AS LockedReceiptBalance,
		|	Inventories.ToUnlockBalance AS ToUnlockBalance,
		|	Inventories.ReserveAtWarehouseFromLockedBalance AS ReserveAtWarehouseFromLockedBalance,
		|	Inventories.ReserveUponReceiptFromLockedBalance AS ReserveUponReceiptFromLockedBalance
		|	
		|INTO InventoryAndNeedsBalanceOfControlledLotsReference
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		Products = &Products
		|			AND Characteristic = &Characteristic) AS Inventories
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose";
	
	TablesNames = ProvisionInDocumentsServer.NewTableNamesForInventoryAllocation();
	TablesNames.Balance = "InventoryAndDemandsBalance"; // @query-part-1
	TablesNames.BalanceSheetsOfControlledLotREFERENCES = "InventoryAndNeedsBalanceOfControlledLotsReference"; // @query-part-1
	TablesNames.Result = "CalculationOfInventoryDistribution"; // @query-part-1
	
	ProvisionInDocumentsServer.InventoryAllocation(QueryText, TablesNames);
	QueryTexts.Add(QueryText);

	QueryText =
	"SELECT ALLOWED
	|	ISNULL(SUM(Table.InCurWarehouse), 0)                AS InCurWarehouse,
	|	ISNULL(SUM(Table.CurWarehouseIsFreeOfSurplus), 0) AS CurWarehouseIsFreeOfSurplus,
	|	ISNULL(SUM(Table.InOtherWarehouses), 0)                AS InOtherWarehouses,
	|	ISNULL(SUM(Table.ThereIsSurplusInOtherWarehouses), 0) AS ThereIsSurplusInOtherWarehouses
	|FROM
	|	(SELECT
	|		Balance.Purpose AS Purpose,
	|		CASE
	|			WHEN Balance.Warehouse = &Warehouse
	|				THEN Balance.InStock + Balance.AvailableWithLock
	|			ELSE 0
	|		END AS InCurWarehouse,
	|		0     AS CurWarehouseIsFreeOfSurplus,
	|		CASE
	|			WHEN Balance.Warehouse <> &Warehouse
	|				THEN Balance.InStock + Balance.AvailableWithLock
	|			ELSE 0
	|		END AS InOtherWarehouses,
	|		0     AS ThereIsSurplusInOtherWarehouses
	|	FROM
	|		CalculationOfInventoryDistribution AS Balance
	|	WHERE
	|		Balance.InStock + Balance.AvailableWithLock > 0
	|
	|	UNION ALL
	|
	|	SELECT
	|		Balance.Purpose AS Purpose,
	|		0     AS InCurWarehouse,
	|		CASE
	|			WHEN Balance.Warehouse = &Warehouse
	|				THEN MAX(Balance.Available_Surplus + Balance.AvailableWithLock_Surplus) - SUM(ISNULL(OrderStructure.AllocatedFromAvailableInventory, 0))
	|			ELSE 0
	|		END AS CurWarehouseIsFreeOfSurplus,
	|		0     AS InOtherWarehouses,
	|		CASE
	|			WHEN Balance.Warehouse <> &Warehouse
	|				THEN MAX(Balance.Available_Surplus + Balance.AvailableWithLock_Surplus) - SUM(ISNULL(OrderStructure.AllocatedFromAvailableInventory, 0))
	|			ELSE 0
	|		END AS ThereIsSurplusInOtherWarehouses
	|	FROM
	|		CalculationOfInventoryDistribution AS Balance
	|			LEFT JOIN InformationRegister.OrderStructure AS OrderStructure
	|			ON Balance.Products   = OrderStructure.Products
	|			 AND Balance.Characteristic = OrderStructure.Characteristic
	|			 AND Balance.Warehouse          = OrderStructure.Warehouse
	|			 AND Balance.Purpose     = OrderStructure.Purpose
	|			 AND OrderStructure.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Reserved)
	|	WHERE
	|		Balance.Products   = &Products
	|		AND Balance.Characteristic = &Characteristic
	|		AND Balance.Warehouse          = &Warehouse
	|		AND Balance.Purpose     = VALUE(Catalog.Assignments.EmptyRef)
	|		AND &Purpose <> VALUE(Catalog.Assignments.EmptyRef)
	|	GROUP BY
	|		Balance.Warehouse, Balance.Purpose
	|	HAVING
	|		MAX(Balance.Available_Surplus + Balance.AvailableWithLock_Surplus) - SUM(ISNULL(OrderStructure.AllocatedFromAvailableInventory, 0)) > 0
	|
	|	UNION ALL
	|
	|	SELECT
	|		Balance.Purpose AS Purpose,
	|		0     AS InCurWarehouse,
	|		CASE
	|			WHEN Balance.Warehouse = &Warehouse
	|				THEN MAX(Balance.Available_Surplus + Balance.AvailableWithLock_Surplus) - SUM(ISNULL(OrderStructure.AllocatedFromAvailableInventoryWithAssignment, 0))
	|			ELSE 0
	|		END AS CurWarehouseIsFreeOfSurplus,
	|		0     AS InOtherWarehouses,
	|		CASE
	|			WHEN Balance.Warehouse <> &Warehouse
	|				THEN MAX(Balance.Available_Surplus + Balance.AvailableWithLock_Surplus) - SUM(ISNULL(OrderStructure.AllocatedFromAvailableInventoryWithAssignment, 0))
	|			ELSE 0
	|		END AS ThereIsSurplusInOtherWarehouses
	|	FROM
	|		CalculationOfInventoryDistribution AS Balance
	|			LEFT JOIN InformationRegister.OrderStructure AS OrderStructure
	|			ON Balance.Products   = OrderStructure.Products
	|			 AND Balance.Characteristic = OrderStructure.Characteristic
	|			 AND Balance.Warehouse          = OrderStructure.Warehouse
	|			 AND Balance.Purpose     = OrderStructure.StructureAssignment
	|			 AND OrderStructure.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Reserved)
	|	WHERE
	|		Balance.Products   = &Products
	|		AND Balance.Characteristic = &Characteristic
	|		AND Balance.Warehouse          = &Warehouse
	|		AND Balance.Purpose    <> VALUE(Catalog.Assignments.EmptyRef)
	|		AND &Purpose           <> VALUE(Catalog.Assignments.EmptyRef)
	|	GROUP BY
	|		Balance.Warehouse, Balance.Purpose
	|	HAVING
	|		MAX(Balance.Available_Surplus + Balance.AvailableWithLock_Surplus) - SUM(ISNULL(OrderStructure.AllocatedFromAvailableInventoryWithAssignment, 0)) > 0
	|
	|) AS Table
	|";
	QueryTexts.Add(QueryText);
	QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	Return QueryText;
	
EndFunction

Function QueryTextThisIsASemiFinishedProduct(NameOfExternalTable = "OrderStructure") Export
	
	Return 
		StrReplace(
		"SELECT TOP 1
		|	TRUE
		|FROM
		|	InformationRegister.CacheOfOrderStructureMasterData AS SupplyMethods
		|WHERE
		|	SupplyMethods.Products = NameOfExternalTable.Products
		|	AND SupplyMethods.Characteristic = NameOfExternalTable.CHARACTERISTIC
		|	AND SupplyMethods.ProductionOrder = NameOfExternalTable.ProductionOrder
		|	AND SupplyMethods.ToPlan
		|	AND SupplyMethods.SupplyType = VALUE(Enum.SupplyTypes.Production)
		|
		|UNION ALL
		|
		|SELECT TOP 1
		|	TRUE
		|FROM
		|	TTDisassembledFinishedProducts AS ProductsBeingDisassembled
		|WHERE
		|	ProductsBeingDisassembled.Products = NameOfExternalTable.Products
		|	AND ProductsBeingDisassembled.Characteristic = NameOfExternalTable.CHARACTERISTIC",
		"NameOfExternalTable",
		NameOfExternalTable);
	
EndFunction

Function QueryTextsTTIssue(FilterCriterion, StagesShow, Postfix)
	
	QueryTexts = New ValueList;
	
	QueryText = 
		"SELECT
		|	OrderStructure.Products         AS Products,
		|	OrderStructure.Characteristic       AS Characteristic,
		|	OrderStructure.Warehouse                AS Warehouse,
		|	OrderStructure.Purpose           AS Purpose,
		|	OrderStructure.KeyProducts     AS KeyProducts,
		|	OrderStructure.KeyLot           AS KeyLot,
		|	OrderStructure.Stage                 AS Stage,
		|	CASE
		|		WHEN OrderStructure.Stage REFS Document.ProductionStage2_2
		|			THEN CAST(OrderStructure.Stage AS Document.ProductionStage2_2).ProductionLot
		|		ELSE VALUE(Catalog.ProductionLots.EmptyRef)
		|	END                                AS ProductionLot,
		|	SUM(OrderStructure.Scheduled) AS Scheduled
		|INTO TTKeysLotReferenceIssue
		|FROM
		|	InformationRegister.OrderStructure AS OrderStructure
		|WHERE
		|	&FilterCriterion
		|	AND (&Purpose = VALUE(Catalog.Assignments.EmptyRef) OR OrderStructure.Purpose = &Purpose)
		|
		|GROUP BY
		|	OrderStructure.Products,
		|	OrderStructure.Characteristic,
		|	OrderStructure.Warehouse,
		|	OrderStructure.Purpose,
		|	OrderStructure.KeyProducts,
		|	OrderStructure.KeyLot,
		|	OrderStructure.Stage,
		|	CASE
		|		WHEN OrderStructure.Stage REFS Document.ProductionStage2_2
		|			THEN CAST(OrderStructure.Stage AS Document.ProductionStage2_2).ProductionLot
		|		ELSE VALUE(Catalog.ProductionLots.EmptyRef)
		|	END
		|
		|HAVING
		|	SUM(OrderStructure.Scheduled) > 0
		|	OR SUM(OrderStructure.AllocatedInFreeProductionLots) > 0
		|	OR SUM(OrderStructure.AllocatedInAssignedProductionLots) > 0
		|	OR SUM(OrderStructure.Done) > 0";
	QueryText = StrReplace(QueryText, "&FilterCriterion", FilterCriterion);
	QueryText = StrReplace(QueryText, "TTKeysLotReferenceIssue", "TTKeysLotReferenceIssue" + Postfix);
	QueryTexts.Add(QueryText, "TTKeysLotReferenceIssue" + Postfix);
	
	QueryText = 
		"SELECT DISTINCT
		|	ProductionIssue.KeyLot         AS KeyLot,
		|	ProductionIssue.ProductionLot AS ProductionLot
		|INTO TTBatchProductionRelease
		|FROM
		|	TTKeysLotReferenceIssue AS ProductionIssue
		|WHERE
		|	ProductionIssue.ProductionLot <> VALUE(Catalog.ProductionLots.EmptyRef)
		|
		|INDEX BY
		|	ProductionLot";
	QueryText = StrReplace(QueryText, "TTKeysLotReferenceIssue", "TTKeysLotReferenceIssue" + Postfix);
	QueryText = StrReplace(QueryText, "TTBatchProductionRelease", "TTBatchProductionRelease" + Postfix);
	QueryTexts.Add(QueryText, "TTBatchProductionRelease" + Postfix);
	
	QueryText = 
		"SELECT
		|	OrderStructure.Products                           AS Products,
		|	OrderStructure.Products.UnitOfMeasure          AS UnitOfMeasure,
		|	OrderStructure.Products.Presentation             AS ProductsPresentation,
		|	OrderStructure.Products.ItemsType           AS ItemsType,
		|	OrderStructure.Products.Quality                  AS Quality,
		|	OrderStructure.Characteristic                         AS Characteristic,
		|	OrderStructure.Characteristic.Presentation           AS CharacteristicPresentation,
		|	OrderStructure.Warehouse                                  AS Warehouse,
		|	OrderStructure.Purpose                             AS Purpose,
		|	FALSE                                                   AS Canceled,
		|	OrderStructure.KeyLot                             AS KeyLot,
		|	VALUE(Catalog.ProductionLots.EmptyRef)   AS ProductionLot,
		|	&TextOfStageCaseField                                  AS StageLink,
		|	MIN(
		|		CASE
		|			WHEN Schedule.Begin IS NOT NULL
		|				THEN Schedule.Begin
		|		END)                                             AS Begin,
		|	MAX(ISNULL(Schedule.Ending, DATETIME(1,1,1))) AS Ending,
		|	SUM(OrderStructure.Scheduled)                   AS Required2,
		|	0                                                      AS Done
		|INTO TTIssue
		|FROM
		|	TTKeysLotReferenceIssue AS OrderStructure
		|
		|	LEFT JOIN InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
		|	ON Schedule.ProductionOrder = &OrderDocument
		|		AND Schedule.ScheduleStatus = &StatusWorkingSchedule
		|		AND OrderStructure.KeyLot = Schedule.KeyLot
		|		AND OrderStructure.Stage = Schedule.Stage
		|WHERE
		|	OrderStructure.Scheduled > 0
		|	AND OrderStructure.Products.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)
		|
		|GROUP BY
		|	OrderStructure.Products,
		|	OrderStructure.Characteristic,
		|	OrderStructure.Warehouse,
		|	OrderStructure.Purpose,
		|	OrderStructure.KeyProducts,
		|	OrderStructure.KeyLot,
		|	&TextOfStageCaseField
		|
		|UNION ALL
		|
		|SELECT
		|	Products_1.Products                  AS Products,
		|	Products_1.Products.UnitOfMeasure AS UnitOfMeasure,
		|	Products_1.Products.Presentation    AS ProductsPresentation,
		|	Products_1.Products.ItemsType  AS ItemsType,
		|	Products_1.Products.Quality         AS Quality,
		|	Products_1.Characteristic                AS Characteristic,
		|	Products_1.Characteristic.Presentation  AS CharacteristicPresentation,
		|	Products_1.Recipient                    AS Warehouse,
		|	Products_1.Purpose                    AS Purpose,
		|	Products_1.Canceled                      AS Canceled,
		|	Lots.KeyLot                     AS KeyLot,
		|	Lots.ProductionLot             AS ProductionLot,
		|	&TextOfStageDocumentField                AS StageLink,
		|	MIN(
		|		CASE
		|			WHEN Schedule.Begin IS NOT NULL
		|					AND (Products_1.ProductionDate = DATETIME(1,1,1)
		|						OR Schedule.Begin <= Products_1.ProductionDate)
		|				THEN Schedule.Begin
		|		END)                            AS Begin,
		|	MAX(
		|		CASE
		|			WHEN Products_1.ProductionDate <> DATETIME(1,1,1)
		|				THEN Products_1.ProductionDate
		|			ELSE ISNULL(Schedule.Ending, DATETIME(1,1,1))
		|		END)                            AS Ending,
		|	SUM(Products_1.Count)             AS Required2,
		|	SUM(
		|		CASE
		|			WHEN Products_1.Manufactured
		|				THEN Products_1.Count
		|			ELSE 0
		|		END)                            AS Done
		|FROM
		|	TTBatchProductionRelease AS Lots
		|
		|	INNER JOIN Document.ProductionStage2_2 AS Stages
		|	ON Lots.ProductionLot = Stages.ProductionLot
		|		AND Stages.Posted
		|
		|	INNER JOIN Document.ProductionStage2_2.ManufacturedProducts AS Products_1
		|	ON Stages.Ref = Products_1.Ref
		|
		|	LEFT JOIN InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
		|	ON Schedule.ProductionOrder = &OrderDocument
		|		AND Schedule.ScheduleStatus = &StatusWorkingSchedule
		|		AND Lots.KeyLot = Schedule.KeyLot
		|		AND Stages.Ref = Schedule.Stage
		|WHERE
		|	(&Purpose = VALUE(Catalog.Assignments.EmptyRef) OR Products_1.Purpose = &Purpose)
		|	AND Products_1.Products.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)
		|
		|GROUP BY
		|	Products_1.Products,
		|	Products_1.Characteristic,
		|	Products_1.Recipient,
		|	Products_1.Purpose,
		|	Products_1.Canceled,
		|	Lots.KeyLot,
		|	Lots.ProductionLot,
		|	&TextOfStageDocumentField
		|
		|UNION ALL
		|
		|SELECT
		|	Products_1.Products                  AS Products,
		|	Products_1.Products.UnitOfMeasure AS UnitOfMeasure,
		|	Products_1.Products.Presentation    AS ProductsPresentation,
		|	Products_1.Products.ItemsType  AS ItemsType,
		|	Products_1.Products.Quality         AS Quality,
		|	Products_1.Characteristic                AS Characteristic,
		|	Products_1.Characteristic.Presentation  AS CharacteristicPresentation,
		|	Products_1.Recipient                    AS Warehouse,
		|	Products_1.Purpose                    AS Purpose,
		|	Products_1.Canceled                      AS Canceled,
		|	Lots.KeyLot                     AS KeyLot,
		|	Lots.ProductionLot             AS ProductionLot,
		|	&TextOfStageDocumentField                AS StageLink,
		|	MIN(
		|		CASE
		|			WHEN Schedule.Begin IS NOT NULL
		|					AND (Products_1.ProductionDate = DATETIME(1,1,1)
		|						OR Schedule.Begin <= Products_1.ProductionDate)
		|				THEN Schedule.Begin
		|		END)                            AS Begin,
		|	MAX(
		|		CASE
		|			WHEN Products_1.ProductionDate <> DATETIME(1,1,1)
		|				THEN Products_1.ProductionDate
		|			ELSE ISNULL(Schedule.Ending, DATETIME(1,1,1))
		|		END)                            AS Ending,
		|	SUM(Products_1.Count)             AS Required2,
		|	SUM(
		|		CASE
		|			WHEN Products_1.Manufactured
		|				THEN Products_1.Count
		|			ELSE 0
		|		END)                            AS Done
		|FROM
		|	TTBatchProductionRelease AS Lots
		|
		|	INNER JOIN Document.ProductionStage2_2 AS Stages
		|	ON Lots.ProductionLot = Stages.ProductionLot
		|		AND Stages.Posted
		|
		|	INNER JOIN Document.ProductionStage2_2.SideAndIntermediateRelease AS Products_1
		|	ON Stages.Ref = Products_1.Ref
		|
		|	LEFT JOIN InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
		|	ON Schedule.ProductionOrder = &OrderDocument
		|		AND Schedule.ScheduleStatus = &StatusWorkingSchedule
		|		AND Lots.KeyLot = Schedule.KeyLot
		|		AND Stages.Ref = Schedule.Stage
		|WHERE
		|	(&Purpose = VALUE(Catalog.Assignments.EmptyRef) OR Products_1.Purpose = &Purpose)
		|	AND Products_1.Products.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)
		|
		|GROUP BY
		|	Products_1.Products,
		|	Products_1.Characteristic,
		|	Products_1.Recipient,
		|	Products_1.Purpose,
		|	Products_1.Canceled,
		|	Lots.KeyLot,
		|	Lots.ProductionLot,
		|	&TextOfStageDocumentField
		|
		|INDEX BY
		|	KeyLot,
		|	Products";
	
	ProductionManagement.SubstitutionOfActualRegisterOfGraph(QueryText);
	
	TextOfStageCaseField = ?(StagesShow, "OrderStructure.Stage", "UNDEFINED");
	QueryText = StrReplace(QueryText, "&TextOfStageCaseField", TextOfStageCaseField);
	
	TextOfStageDocumentField = ?(StagesShow, "Stages.Ref", "UNDEFINED");
	QueryText = StrReplace(QueryText, "&TextOfStageDocumentField", TextOfStageDocumentField);
	
	QueryText = StrReplace(QueryText, "TTKeysLotReferenceIssue", "TTKeysLotReferenceIssue" + Postfix);
	QueryText = StrReplace(QueryText, "TTBatchProductionRelease", "TTBatchProductionRelease" + Postfix);
	QueryText = StrReplace(QueryText, "TTIssue", "TTIssue" + Postfix);
	
	QueryTexts.Add(QueryText, "TTIssue" + Postfix);
	
	Return QueryTexts;
	
EndFunction

Function QueryTextIssueOfTTSimulation(Postfix)
	
	QueryText = 
		"SELECT TOP 0
		|	&EmptyLinkKey                                             AS KeyLot,
		|	VALUE(Catalog.Products.EmptyRef)               AS Products,
		|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
		|	FALSE                                                         AS Canceled
		|INTO TTIssue";
	
	QueryText = StrReplace(QueryText, "TTIssue", "TTIssue" + Postfix);
	
	Return QueryText;
	
EndFunction

Function QueryTextProductionIssue(Postfix, SetSelectionForStage)
	
	QueryText = 
		"SELECT
		|	ProductionIssue.Products                AS Products,
		|	ProductionIssue.UnitOfMeasure            AS UnitOfMeasure,
		|	ProductionIssue.ProductsPresentation   AS ProductsPresentation,
		|	ProductionIssue.ItemsType             AS ItemsType,
		|	ProductionIssue.Quality                    AS Quality,
		|	ProductionIssue.Characteristic              AS Characteristic,
		|	ProductionIssue.CharacteristicPresentation AS CharacteristicPresentation,
		|	ProductionIssue.Warehouse                       AS Warehouse,
		|	ProductionIssue.Purpose                  AS Purpose,
		|	ProductionIssue.Canceled                    AS Canceled,
		|	ProductionIssue.KeyLot                  AS KeyLot,
		|	ProductionIssue.ProductionLot          AS ProductionLot,
		|	ProductionIssue.StageLink                  AS StageLink,
		|	ProductionIssue.Begin                      AS Begin,
		|	ProductionIssue.Ending                   AS Ending,
		|	ProductionIssue.Required2                   AS Required2,
		|	ProductionIssue.Done                      AS Done
		|FROM
		|	TTIssue AS ProductionIssue
		|WHERE
		|	ProductionIssue.StageLink = &Stage
		|
		|ORDER BY
		|	KeyLot,
		|	Products,
		|	Characteristic
		|AUTOORDER";
	
	If Not SetSelectionForStage Then
		QueryText = StrReplace(QueryText, "ProductionIssue.StageLink = &Stage", "TRUE");
	EndIf;
	
	QueryText = StrReplace(QueryText, "TTIssue", "TTIssue" + Postfix);
	
	Return QueryText;
	
EndFunction

Function QueryTextIssueMinimized(Postfix)
	
	QueryText = 
		"SELECT DISTINCT
		|	ProductionIssue.KeyLot   AS KeyLot,
		|	ProductionIssue.StageLink   AS StageLink
		|FROM
		|	TTIssue AS ProductionIssue";
	
	QueryText = StrReplace(QueryText, "TTIssue", "TTIssue" + Postfix);
	
	Return QueryText;
	
EndFunction

Function QueryTextDisassembledFinishedProductsTT()
	
	QueryText = 
		"SELECT DISTINCT
		|	TabularSection.Products   AS Products,
		|	TabularSection.Characteristic AS Characteristic
		|INTO TTDisassembledFinishedProducts
		|FROM
		|	Document.ProductionOrder2_2.ManufacturedProduct AS TabularSection
		|WHERE
		|	TabularSection.Ref = &OrderDocument
		|	AND NOT TabularSection.Canceled
		|	AND TabularSection.Ref.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Disassembly)
		|INDEX BY
		|	Products, Characteristic";
	
	Return QueryText;
	
EndFunction

Function QueryTextDisassembledFinishedProductsTTSimulation()
	
	QueryText = 
		"SELECT TOP 0
		|	VALUE(Catalog.Products.EmptyRef)               AS Products,
		|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic
		|INTO TTDisassembledFinishedProducts";
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region Other

Function New_Tree()
	
	Result = New ValueTree;
	
	Result.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	Result.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	Result.Columns.Add("Warehouse", New TypeDescription("CatalogRef.BusinessStructure, CatalogRef.Warehouses"));
	Result.Columns.Add("WarehouseDivision", New TypeDescription("CatalogRef.BusinessStructure, CatalogRef.Warehouses"));
	Result.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
	
	Result.Columns.Add("ItemsType", New TypeDescription("EnumRef.ItemsTypes"));
	Result.Columns.Add("Quality", New TypeDescription("EnumRef.QualityLevels"));
	
	Result.Columns.Add("UnderRepairProduct", New TypeDescription("CatalogRef.Products"));
	Result.Columns.Add("UnderRepairVariant", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	
	Result.Columns.Add("KeyLot", New TypeDescription("UUID"));
	Result.Columns.Add("KeyProducts", New TypeDescription("UUID"));
	
	Result.Columns.Add("LineNumber", New TypeDescription("Number", New NumberQualifiers));
	
	Result.Columns.Add("LinePresentation", New TypeDescription("String",, New StringQualifiers));
	Result.Columns.Add("UnitOfMeasure", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	
	Result.Columns.Add("Department", New TypeDescription("CatalogRef.BusinessStructure"));
	
	Result.Columns.Add("Begin", New TypeDescription("Date",,, New DateQualifiers));
	Result.Columns.Add("Ending", New TypeDescription("Date",,, New DateQualifiers));
	Result.Columns.Add("DesiredDate", New TypeDescription("Date",,, New DateQualifiers));
	
	Result.Columns.Add("PictureNumber", New TypeDescription("Number", New NumberQualifiers));
	Result.Columns.Add("RowType", New TypeDescription("Number", New NumberQualifiers));
	
	Result.Columns.Add("Required2", New TypeDescription("Number", New NumberQualifiers));
	Result.Columns.Add("Launched", New TypeDescription("Number", New NumberQualifiers));
	Result.Columns.Add("Done", New TypeDescription("Number", New NumberQualifiers));
	Result.Columns.Add("Left", New TypeDescription("Number", New NumberQualifiers));
	Result.Columns.Add("Supplied", New TypeDescription("Number", New NumberQualifiers));
	Result.Columns.Add("SecuredInterest", New TypeDescription("Number", New NumberQualifiers));
	Result.Columns.Add("NotProvide", New TypeDescription("Boolean"));
	
	Result.Columns.Add("BillOfMaterials", New TypeDescription("CatalogRef.BillsOfMaterials"));
	Result.Columns.Add("StageLink", New TypeDescription("CatalogRef.ProductionStages, DocumentRef.ProductionStage2_2"));
	Result.Columns.Add("ProductionLot", New TypeDescription("CatalogRef.ProductionLots"));
	Result.Columns.Add("StageNumber", New TypeDescription("Number", New NumberQualifiers));
	Result.Columns.Add("NextStageNo", New TypeDescription("Number", New NumberQualifiers));
	
	Result.Columns.Add("FinishTree", New TypeDescription("Boolean"));
	Result.Columns.Add("SearchString", New TypeDescription("Boolean"));
	
	Result.Columns.Add("IndexOfImageIsStillFreeOrNotNeeded", Common.TypeDescriptionNumber(1));
	Result.Columns.Add("IndexOfImageRemainsForOtherPurposes", Common.TypeDescriptionNumber(1));
	Result.Columns.Add("IndexOfImageRemainsInAnotherWarehouse", Common.TypeDescriptionNumber(1));
	Result.Columns.Add("IndexOfImageLeft", Common.TypeDescriptionNumber(1));
	
	Result.Columns.Add("LaunchOrder", New TypeDescription("DocumentRef.ProductionOrder2_2"));
	Result.Columns.Add("LaunchOrderStages", New TypeDescription("FixedArray"));
	
	Result.Columns.Add("ProductionByThirdParty", New TypeDescription("Boolean"));
	Result.Columns.Add("MultipleWarehouses", New TypeDescription("Boolean"));
	Result.Columns.Add("MultipleSpecifications", New TypeDescription("Boolean"));
	Result.Columns.Add("SupplyIsRequired", New TypeDescription("Boolean"));
	Result.Columns.Add("Canceled", New TypeDescription("Boolean"));
	
	// Parties providing semi-finished products (Key parties)
	Result.Columns.Add("ProvidingParty", New TypeDescription("FixedArray"));
	
	// Service columns for building a tree
	
	// To calculate the quantity when providing other production orders and their stages
	Result.Columns.Add("LaunchedInLaunchOrders", New TypeDescription("Number", New NumberQualifiers));
	
	// Field for creating a search tree
	Result.Columns.Add("DescendantOfSearchItem", New TypeDescription("Boolean"));
	
	// Fields for additional sorting of lines when displaying the Issue
	Result.Columns.Add("ThisIsASemiFinishedProduct", New TypeDescription("Boolean"));
	Result.Columns.Add("ThisIsRelease", New TypeDescription("Boolean"));
	
	// Fields for calculating the image in special cases
	Result.Columns.Add("WorkPlanning", New TypeDescription("Boolean"));
	Result.Columns.Add("ItIsIssuedWithinLotReference", New TypeDescription("Boolean"));
	
	Return Result;
	
EndFunction

Function LineTypeProduct()
	
	Return 1;
	
EndFunction

Function LineTypeSemiFinished()
	
	Return 2;
	
EndFunction

Function StringTypeStructureStage()
	
	Return 3;
	
EndFunction

Function LineTypeMove()
	
	Return 4;
	
EndFunction

Function LineTypeStageDocument()
	
	Return 5;
	
EndFunction

Function LineTypeLaunchOrder()
	
	Return 6;
	
EndFunction

Function RowTypeInternal()
	
	Return 7;
	
EndFunction

Function LineTypeMaterial()
	
	Return 8;
	
EndFunction

Function LineTypeDecryptionNomenclature()
	
	Return 9;
	
EndFunction

Function LineTypeIssue()
	
	Return 10;
	
EndFunction

Function PictureNumber(String)
	
	If String.RowType = StringTypeStructureStage()
		And Not String.WorkPlanning Then
		Return 0;
	ElsIf String.RowType = LineTypeStageDocument()
		And Not String.WorkPlanning Then
		Return 1;
	ElsIf (String.RowType = LineTypeSemiFinished()
		Or String.RowType = LineTypeMaterial())
		And String.ItemsType = Enums.ItemsTypes.Work_5 Then
		Return 10;
	ElsIf (String.RowType = LineTypeSemiFinished()
		Or String.RowType = LineTypeMaterial())
		And String.ItIsIssuedWithinLotReference Then
		Return 13;
	ElsIf String.RowType = LineTypeSemiFinished() Then
		Return 6;
	ElsIf String.RowType = LineTypeMove() Then
		Return 11;
	ElsIf String.RowType = LineTypeMaterial() Then
		Return 7;
	ElsIf String.RowType = LineTypeIssue() Then
		Return 12;
	ElsIf String.RowType = StringTypeStructureStage() Then
		Return 2;
	ElsIf String.RowType = LineTypeStageDocument() Then
		Return 3;
	Else
		Return 0;
	EndIf;
	
EndFunction

Function SamplePortionSize() Export
	
	Return 1000;
	
EndFunction

Function RowsCount(TreeRows)
	
	Result = 0;
	
	Queue = New Array;
	For Each String In TreeRows Do
		If String.RowType <> RowTypeInternal() Then
			Queue.Add(String);
		EndIf;
	EndDo;
	
	While Queue.UBound() <> -1 Do
		Result = Result + 1;
		For Each DescendantString In Queue[0].Rows Do
			If DescendantString.RowType <> RowTypeInternal() Then
				Queue.Add(DescendantString);
			EndIf;
		EndDo;
		Queue.Delete(0);
	EndDo;
	
	Return Result;
	
EndFunction

Function SortDataInAscendingOrder(ProcessType)
	
	Return ProcessType = Enums.ProductionProcessTypes.PerformRM
		Or ProcessType = Enums.ProductionProcessTypes.Disassembly;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
