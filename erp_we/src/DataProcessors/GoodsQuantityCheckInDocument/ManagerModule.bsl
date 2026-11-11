#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	AttributesNames = "Warehouse,Premise,WarehouseDocument,WarehouseOperation,DateOfShipment";
	
	Return AttributesNames;
EndFunction

// Returns parameters for specifying series for the products specified in the document.
//
// Parameters:
//  Object	 - Structure - the structure of the values of the details object required to populate the parameters specify the series.
// 
// Returns:
//  See ProductsClientServer.SeriesSpecificationParameters.
//
Function SeriesSpecificationParameters(Object) Export
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	SeriesSpecificationParameters.FullObjectName = "DataProcessor.GoodsQuantityCheckInDocument";
	SeriesSpecificationParameters.TSSeriesName = "Goods";
	
	WarehouseSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Warehouse, False);
	
	SeriesSpecificationParameters.UseItemsBatch  = WarehouseSeriesParameters.UseItemsBatch;
	SeriesSpecificationParameters.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;
	
	SeriesSpecificationParameters.WarehouseTransactions.Add(Object.WarehouseOperation);
	
	SeriesSpecificationParameters.UseBinLocationWarehousing = WarehousesServer.UseBinLocationWarehousing(Object.Warehouse, Object.Premise, Object.DateOfShipment);
	
	SeriesSpecificationParameters.LinkFields.Add("Package");
	SeriesSpecificationParameters.FieldNameQuantity = "NumberOfPackages";
	
	SeriesSpecificationParameters.FieldNameRoom = "Premise";
	
	SeriesSpecificationParameters.LinkFields.Add("DoNotShip");
	SeriesSpecificationParameters.LinkFields.Add("PackingList");
	SeriesSpecificationParameters.LinkFields.Add("Purpose");
	
	SeriesSpecificationParameters.ShipmentPlanning = False;
	SeriesSpecificationParameters.SelectionPlanning = False;
	SeriesSpecificationParameters.PickingCheck = False;
	SeriesSpecificationParameters.FactOfSelection = True;
	
	SeriesSpecificationParameters.ItSWarrant = True;
	SeriesSpecificationParameters.BlockFormData = False;
	SeriesSpecificationParameters.Date = Object.DateOfShipment;
	
	Return SeriesSpecificationParameters;
EndFunction

// Returns the request text for calculating the statuses for specifying series
//	Parameters:
//		SeriesSpecificationParameters - Structure - the structure of fields is specified in the function Nomenclaturales.Parametrizatsii
//	Returns:
//		String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	QueryText = 
	"SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.Products AS Products,
	|	Goods.DoNotShip AS DoNotShip,
	|	Goods.Series AS Series,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.Products AS Products,
	|	Goods.DoNotShip AS DoNotShip,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind,
	|	Goods.Series AS Series,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus
	|INTO ProductsToRequest
	|FROM
	|	Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL 
	|			THEN 0
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN CASE
	|								WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
	|									THEN 14
	|								ELSE 10
	|							END
	|					ELSE CASE
	|							WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
	|								THEN 13
	|							ELSE 9
	|						END
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningPicking
	|			THEN CASE
	|					WHEN BatchAccountingPolicies.BatchAccountingPolicy.BatchesAccountingByFEFO
	|						THEN CASE
	|								WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|									THEN 6
	|								ELSE 5
	|							END
	|					ELSE CASE
	|							WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|								THEN 8
	|							ELSE 7
	|						END
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyByPickingResult
	|					AND (BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnShipmentToCustomer
	|							AND &ShipmentToCustomer
	|						OR BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnRetailShipment
	|							AND &RetailShipment
	|						OR BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenShippingComponentsForAssembly
	|							AND &ShipComponentsForAssembly
	|						OR BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenShippingKitsForDisassembly
	|							AND &ShipSetsForDisassembly
	|						OR BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnShipmentForInternalNeeds
	|							AND &ShipmentForInternalNeeds
	|						OR BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnShipmentByReturnToVendor
	|							AND &ShipmentUnderReturnToVendor
	|						OR BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnShipmentByTransfer
	|							AND &ShipmentByTransfer)
	|				OR (BatchAccountingPolicies.BatchAccountingPolicy.SpecifyByPickingResult
	|					OR BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnReceiving)
	|					AND BatchAccountingPolicies.BatchAccountingPolicy.SpecifyUponTransferBetweenWarerooms
	|					AND &TransferBetweenWarerooms
	|			THEN CASE
	|					WHEN BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries
	|						THEN CASE
	|								WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|									THEN 4
	|								ELSE 3
	|							END
	|					ELSE CASE
	|							WHEN Goods.DoNotShip = 1
	|								THEN 0
	|							WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|								THEN 2
	|							ELSE 1
	|						END
	|				END
	|		ELSE 0
	|	END AS BatchesIndicationStatus
	|INTO Statuses
	|FROM
	|	ProductsToRequest AS Goods
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|			INNER JOIN Catalog.Warehouses AS Warehouses
	|			ON (&Warehouse = Warehouses.Ref)
	|		ON (BatchAccountingPolicies.Warehouse = &Warehouse)
	|			AND Goods.ProductKind = BatchAccountingPolicies.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Statuses.LineNumber AS LineNumber,
	|	Statuses.BatchesIndicationStatus AS BatchesIndicationStatus
	|FROM
	|	Statuses AS Statuses
	|WHERE
	|	Statuses.BatchesIndicationStatus <> Statuses.OldStatusOfSpecifyingSeries
	|
	|ORDER BY
	|	Statuses.LineNumber";
	
	If SeriesSpecificationParameters.LinkFields.Find("Package") = Undefined Then
		
		QueryText = StrReplace(QueryText, "Goods.Package AS Package",
			"VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package");
			
	EndIf;
	
	Return QueryText;

	
EndFunction

// Returns the request body for the get the available appointments
//	Parameters:
//		RequestFormationParameters - Structure - the parameters for the generation of text queries
//	Returns:
//		String - query text.
//
Function RequestTextForAvailableAssignments(RequestFormationParameters) Export
	
	Return Catalogs.Assignments.RequestTextForAllAppointments(RequestFormationParameters);
	
EndFunction

#EndRegion

#Region Private

Function ConditionForSelectingRows(Object) Export
	
	If TypeOf(Object.WarehouseDocument) = Type("DocumentRef.GoodsTransferNote") Then
		
		If Object.CorrectionMode Then
			ConditionForSelectingRows = "TRUE";
		Else
			ConditionForSelectingRows = "GoodsTable.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.Pick)";
		EndIf;
		
	Else
		
		If Object.CorrectionMode Then
			ConditionForSelectingRows = 
			"NOT GoodsTable.ThisIsAPackingList
			|AND GoodsTable.PackingListParent = VALUE(Document.PackingList.EmptyRef)";
		Else
			ConditionForSelectingRows = "GoodsTable.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.Pick)";
		EndIf;
		
	EndIf;
	
	Return ConditionForSelectingRows;
	
EndFunction

#Region Print

// Returns the document data structure used for printing the print form of the product selection Task.
//
// Parameters:
//	PrintParameters	- Structure									- additional print options.
//	ShipmentOrder_	- DocumentRef.GoodsTransferNote,
//						Document link.Consumables - link to the document to be printed.
//	
// Returns:
//	Structure - a structure with the following keys:
//		*ErrorResults			- Undefined			- errors in document data that make it impossible
//																to print the document.
//		*ResultOnOrders	- QueryResult		- information about orders for document shipment.
//									- Undefined - 
//		*HeaderResults			- QueryResult		- the data of the header of the document used for the print Job
//																in the selection of goods.
//		*ResultForTabularPart	- QueryResult		- data of the product part of the document used for printing
//																Job in the selection of goods.
//		*ResultForPackages		- Undefined			- data about product packages in the tabular part of the document
//																used for printing the product selection Task.
//		*ResultBySeries			- QueryResult		- data about product series in the table part of the document
//																that is used for printing the product selection Task.
//
Function GetDataForPrintedFormTaskOnDoborGoods(PrintParameters, ShipmentOrder_) Export
	
	QueryText =
	"SELECT
	|	CAST(DoborTable.Products AS Catalog.Products)					AS Products,
	|	CAST(DoborTable.Characteristic AS Catalog.ItemsCharacteristics)	AS Characteristic,
	|	CAST(DoborTable.Series AS Catalog.ItemsBatches)						AS Series,
	|	CAST(DoborTable.Package AS Catalog.PackagesAndUnitsOfMeasure)			AS Package,
	|	DoborTable.QuantityShortage														AS Count,
	|	DoborTable.NumberOfPackagesShortage												AS NumberOfPackages
	|INTO DoborTable
	|FROM
	|	&TableOfGoods AS DoborTable
	|
	|WHERE
	|	DoborTable.QuantityShortage > 0
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	TaskData_.Ref					AS Ref,
	|	TaskData_.Warehouse						AS Warehouse,
	|	TaskData_.SenderWareroom		AS Premise,
	|	GoodsTable.Products				AS Products,
	|	GoodsTable.Characteristic			AS Characteristic,
	|	CASE
	|		WHEN GoodsTable.Products.ProductKind.BatchUsageSettings = &BatchUsageSettings
	|			THEN VALUE(Catalog.ItemsBatches.EmptyRef)
	|		ELSE GoodsTable.Series
	|	END									AS Series,
	|	CASE
	|		WHEN GoodsTable.Products.ProductKind.BatchUsageSettings = &BatchUsageSettings
	|				OR GoodsTable.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN GoodsTable.Products.UnitOfMeasure
	|		ELSE GoodsTable.Package
	|	END									AS Package,
	|	SUM(GoodsTable.Count)			AS Count,
	|	SUM(CASE
	|		WHEN GoodsTable.Products.ProductKind.BatchUsageSettings = &BatchUsageSettings
	|			THEN GoodsTable.Count
	|		ELSE GoodsTable.NumberOfPackages
	|	END)									AS NumberOfPackages
	|INTO TableOfGoodsSummarized
	|FROM
	|	DoborTable AS GoodsTable
	|		LEFT JOIN Document.GoodsTransferNote AS TaskData_
	|		ON TRUE
	|
	|WHERE
	|	TaskData_.Ref = &ShipmentOrder_
	|
	|GROUP BY
	|	TaskData_.Ref,
	|	TaskData_.Warehouse,
	|	TaskData_.SenderWareroom,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	CASE
	|		WHEN GoodsTable.Products.ProductKind.BatchUsageSettings = &BatchUsageSettings
	|			THEN VALUE(Catalog.ItemsBatches.EmptyRef)
	|		ELSE GoodsTable.Series
	|	END,
	|	CASE
	|		WHEN GoodsTable.Products.ProductKind.BatchUsageSettings = &BatchUsageSettings
	|				OR GoodsTable.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN GoodsTable.Products.UnitOfMeasure
	|		ELSE GoodsTable.Package
	|	END
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	DocumentDescription.Ref						AS Ref,
	|	PRESENTATION(DocumentDescription.ReferenceOrder)	AS BasisPresentation,
	|	DocumentDescription.ReferenceOrder.Number			AS BaseDocumentNumber,
	|	DocumentDescription.ReferenceOrder.Date				AS ReferenceDocumentDateForPrintForms,
	|	MIN(DocumentDescription.LineNumber)			AS LineNumber
	|FROM
	|	Document.GoodsIssueNote.GoodsByReferences AS DocumentDescription
	|
	|WHERE
	|	DocumentDescription.Ref = &ShipmentOrder_
	|
	|GROUP BY
	|	DocumentDescription.Ref,
	|	PRESENTATION(DocumentDescription.ReferenceOrder),
	|	DocumentDescription.ReferenceOrder.Number,
	|	DocumentDescription.ReferenceOrder.Date
	|
	|ORDER BY
	|	Ref,
	|	LineNumber
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3
	|SELECT
	|	TaskData_.Ref								AS Ref,
	|	PRESENTATION(TaskData_.Ref)					AS RefPresentation,
	|	TaskData_.DateOfShipment							AS Date,
	|	TaskData_.Number									AS Number,
	|	TaskData_.Warehouse									AS Warehouse,
	|	PRESENTATION(TaskData_.Warehouse)					AS WarehousePresentation,
	|	PRESENTATION(TaskData_.SenderWareroom)	AS PremisePresentation,
	|	FALSE												AS ThisIsAnInvoice,
	|	CASE
	|		WHEN TaskData_.Warehouse.UseWarerooms
	|				AND TaskData_.DateOfShipment >= TaskData_.Warehouse.StartDateOfWareroomUse
	|			THEN CASE
	|					WHEN TaskData_.SenderWareroom.UseBinLocationWarehousing
	|							AND TaskData_.DateOfShipment >= TaskData_.SenderWareroom.StartDateOfUsingWarehouseBinSystem
	|						THEN TRUE
	|					ELSE FALSE
	|				END
	|		ELSE CASE
	|				WHEN TaskData_.Warehouse.UseBinLocationWarehousing
	|						AND TaskData_.DateOfShipment >= TaskData_.Warehouse.StartDateOfUsingWarehouseBinSystem
	|					THEN TRUE
	|				ELSE FALSE
	|			END
	|	END												AS BinLocationWarehousingIsUsed,
	|	CASE
	|		WHEN TaskData_.Warehouse.UseWarerooms
	|				AND TaskData_.DateOfShipment >= TaskData_.Warehouse.StartDateOfWareroomUse
	|			THEN CASE
	|					WHEN TaskData_.SenderWareroom.UseBinLocationWarehousingForInformation
	|							AND (NOT TaskData_.SenderWareroom.UseBinLocationWarehousing
	|								OR TaskData_.DateOfShipment < TaskData_.SenderWareroom.StartDateOfUsingWarehouseBinSystem)
	|						THEN TRUE
	|					ELSE FALSE
	|				END
	|		ELSE CASE
	|				WHEN TaskData_.Warehouse.UseBinLocationWarehousingForInformation
	|						AND (NOT TaskData_.Warehouse.UseBinLocationWarehousing
	|							OR TaskData_.DateOfShipment < TaskData_.Warehouse.StartDateOfUsingWarehouseBinSystem)
	|					THEN TRUE
	|				ELSE FALSE
	|			END
	|	END												AS ReferenceStorageIsUsed,
	|	CASE
	|		WHEN TaskData_.Warehouse.UseWarerooms
	|			AND TaskData_.DateOfShipment >= TaskData_.Warehouse.StartDateOfWareroomUse
	|			THEN TaskData_.SenderWareroom.WarehouseZoneUsage
	|		ELSE TaskData_.Warehouse.WarehouseZoneUsage
	|	END												AS WarehouseZoneUsage,
	|	FALSE												AS AdvancedWarehousingIsUsed,
	|	&Add_Fields
	|FROM
	|	Document.GoodsTransferNote AS TaskData_
	|
	|WHERE
	|	TaskData_.Ref = &ShipmentOrder_
	|
	|ORDER BY
	|	Ref,
	|	Warehouse
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 4
	|SELECT
	|	TableOfGoods.Ref								AS Ref,
	|	TableOfGoods.Warehouse								AS Warehouse,
	|	ISNULL(MainStorageBins.Cell.WarehouseZone, &DefaultWorkArea)	AS WarehouseZone,
	|	PRESENTATION(MainStorageBins.Cell.WarehouseZone)	AS PresentationOfWorkArea,
	|	ISNULL(MainStorageBins.Cell.TabIndex, 0)	AS TabIndex,
	|	ISNULL(MainStorageBins.Cell, &DefaultCell)	AS MainStorageBin,
	|	ISNULL(MainStorageBins.Cell.Code, """")			AS MainStorageBinPresentation,
	|	ISNULL(OtherCells.Cell.TabIndex, 0)	AS TraversalOrderAdditionalCell,
	|	ISNULL(OtherCells.Cell.Code, """")			AS CellPresentation,
	|	TableOfGoods.Products.Code						AS Code,
	|	TableOfGoods.Products.SKU					AS SKU,
	|	TableOfGoods.Products							AS Products,
	|	TableOfGoods.Products.DescriptionFull		AS ProductPresentation,
	|	TableOfGoods.Characteristic						AS Characteristic,
	|	TableOfGoods.Characteristic.DescriptionFull	AS CharacteristicPresentation,
	|	Goods.ProductKind.BatchUsageSettings	AS BatchUsageSettings,
	|	TableOfGoods.Series								AS Series,
	|	TableOfGoods.Series.Description					AS BatchPresentation,
	|	TableOfGoods.Package								AS Package,
	|	PRESENTATION(TableOfGoods.Package)				AS PresentationOfPackingUnit,
	|	PRESENTATION(Goods.UnitOfMeasure)				AS PresentationOfBasicUnitOfMeasure,
	|	TableOfGoods.Count							AS Count,
	|	TableOfGoods.NumberOfPackages					AS NumberOfPackages
	|FROM
	|	TableOfGoodsSummarized AS TableOfGoods
	|		LEFT JOIN Catalog.Products AS Goods
	|		ON TableOfGoods.Products = Goods.Ref
	|		
	|		LEFT JOIN InformationRegister.PlaceProductsInStorageBins AS MainStorageBins
	|		ON TableOfGoods.Products = MainStorageBins.Products
	|			AND MainStorageBins.MainStorageBin
	|			AND TableOfGoods.Warehouse = MainStorageBins.Warehouse
	|			AND CASE
	|				WHEN TableOfGoods.Warehouse.UseWarerooms
	|						AND TableOfGoods.Ref.DateOfShipment >= TableOfGoods.Warehouse.StartDateOfWareroomUse
	|					THEN TableOfGoods.Premise = MainStorageBins.Premise
	|				ELSE MainStorageBins.Premise = VALUE(Catalog.Warerooms.EmptyRef)
	|			END
	|		
	|		LEFT JOIN InformationRegister.PlaceProductsInStorageBins AS OtherCells
	|		ON TableOfGoods.Products = OtherCells.Products
	|			AND NOT OtherCells.MainStorageBin
	|			AND TableOfGoods.Warehouse = OtherCells.Warehouse
	|			AND CASE
	|				WHEN TableOfGoods.Warehouse.UseWarerooms
	|						AND TableOfGoods.Ref.DateOfShipment >= TableOfGoods.Warehouse.StartDateOfWareroomUse
	|					THEN TableOfGoods.Premise = OtherCells.Premise
	|				ELSE OtherCells.Premise = VALUE(Catalog.Warerooms.EmptyRef)
	|			END
	|
	|ORDER BY
	|	Ref,
	|	Warehouse,
	|	WarehouseZone,
	|	Products,
	|	Characteristic,
	|	Series
	|
	|TOTALS BY
	|	Ref,
	|	Warehouse,
	|	WarehouseZone
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 5
	|SELECT
	|	TableOfGoods.Ref				AS Ref,
	|	TableOfGoods.Warehouse				AS Warehouse,
	|	ISNULL(MainStorageBins.Cell.WarehouseZone, &DefaultWorkArea)	AS WarehouseZone,
	|	TableOfGoods.Products			AS Products,
	|	TableOfGoods.Characteristic		AS Characteristic,
	|	TableOfGoods.Series.Description	AS BatchPresentation
	|FROM
	|	TableOfGoodsSummarized AS TableOfGoods
	|		LEFT JOIN InformationRegister.PlaceProductsInStorageBins AS MainStorageBins
	|		ON TableOfGoods.Products = MainStorageBins.Products
	|			AND MainStorageBins.MainStorageBin
	|			AND TableOfGoods.Warehouse = MainStorageBins.Warehouse
	|			AND CASE
	|				WHEN TableOfGoods.Warehouse.UseWarerooms
	|						AND TableOfGoods.Ref.DateOfShipment >= TableOfGoods.Warehouse.StartDateOfWareroomUse
	|					THEN TableOfGoods.Premise = MainStorageBins.Premise
	|				ELSE MainStorageBins.Premise = VALUE(Catalog.Warerooms.EmptyRef)
	|			END
	|
	|WHERE
	|	TableOfGoods.Products.ProductKind.BatchUsageSettings = &BatchUsageSettings
	|	AND TableOfGoods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|
	|ORDER BY
	|	Ref,
	|	Warehouse,
	|	WarehouseZone,
	|	Products,
	|	Characteristic";
	
	If TypeOf(ShipmentOrder_) = Type("DocumentRef.GoodsIssueNote") Then
		TextOfAdditionalFields_ =
		"	PRESENTATION(TaskData_.TransportationJob.Ref)	AS TransportationJobPresentation,
		|	TaskData_.TransportationJob.Date					AS TransportationTaskDate,
		|	TaskData_.TransportationJob.Number					AS TransportationTaskNumber,
		|	TaskData_.DeliveryProcedure							AS DeliveryProcedure,
		|	TaskData_.ShipmentUnderTransportationJob				AS ShipmentUnderTransportationJob";
		
		QueryText = StrReplace(QueryText, "SenderWareroom",		"Premise");
		QueryText = StrReplace(QueryText, "&Add_Fields",					TextOfAdditionalFields_);
		QueryText = StrReplace(QueryText, "GoodsTransferNote",	"GoodsIssueNote");
	Else
		QueryText = StrReplace(QueryText, "&Add_Fields", "TRUE");
	EndIf;
	
	QueryText = StrReplace(QueryText,
								"&BatchUsageSettings",
								"VALUE(Enum.ItemsBatchUsageSettings.InventoryItem)");
	QueryText = StrReplace(QueryText,
								"&DefaultWorkArea",
								"VALUE(Catalog.WarehouseZones.EmptyRef)");
	QueryText = StrReplace(QueryText,
								"&DefaultCell",
								"VALUE(Catalog.StorageBins.EmptyRef)");
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("ShipmentOrder_",	ShipmentOrder_);
	Query.SetParameter("TableOfGoods",		PrintParameters.TableOfGoods.Unload());
	
	SetPrivilegedMode(True);
	Result = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	MaxIndex			= Result.UBound();
	ResultOnOrders	= ?(TypeOf(ShipmentOrder_) = Type("DocumentRef.GoodsIssueNote"),
									Result[MaxIndex - 3],
									Undefined);
	
	TaskData_ = New Structure;
	TaskData_.Insert("ErrorResults",		Undefined);
	TaskData_.Insert("ResultOnOrders",	ResultOnOrders);
	TaskData_.Insert("HeaderResults",			Result[MaxIndex - 2]);
	TaskData_.Insert("ResultForTabularPart",	Result[MaxIndex - 1]);
	TaskData_.Insert("ResultForPackages",		Undefined);
	TaskData_.Insert("ResultBySeries",			Result[MaxIndex]);
	
	Return TaskData_;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
