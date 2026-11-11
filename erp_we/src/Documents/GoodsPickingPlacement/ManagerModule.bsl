
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#If Not MobileStandaloneServer Then

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("AddressWarehouse");
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  See DocumentsPosting.InitializeDocumentDataForPosting
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.GoodsPickingPlacement") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query			= New Query;
	QueryTexts	= New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		FillInInitializationParameters(Query, DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
	EndIf;
	
	PickUpProducts(Query, QueryTexts, Registers);
	PlaceProducts(Query, QueryTexts, Registers);
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Documents.GoodsPickingPlacement.AddGenerateCommand(GenerationCommands);
	
	Documents.SetStorageBinLocks.AddGenerateCommand(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
EndProcedure

// Adds the command for creating the document"product Selection (placement)".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTable, Undefined - generated commands for output to the submenu.
//
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.GoodsPickingPlacement) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.GoodsPickingPlacement.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.GoodsPickingPlacement);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseBinLocationWarehousing";
	

		Return CreateBasedOnCommand;
	EndIf;

	Return Undefined;
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
EndProcedure

// Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	AttributesNames = "Warehouse,OperationKind,Status,Date";
	
	Return AttributesNames;
EndFunction

#EndIf

// Returns parameters for specifying series for the products specified in the document.
//
// Parameters:
//  Object	 - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
// Returns:
//  Structure:
//  *Filter - See ProductsClientServer.SeriesSpecificationParameters
//  *Location - See ProductsClientServer.SeriesSpecificationParameters
//
Function SeriesSpecificationParameters(Object) Export
	
	#If Not MobileStandaloneServer Then
		Filter = ProductsClientServer.SeriesSpecificationParameters();
		
		WarehouseSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Warehouse, False);
	#Else
		Filter = MobileWarehouseKeeperWorkspace.ItemClientServerSerialSpecificationParameters();
		
		WarehouseSeriesParameters = MobileWarehouseKeeperWorkspace.UseOfSeriesInStock(Object.Warehouse, False);
	#EndIf
	
	Filter.FullObjectName = "Document.GoodsPickingPlacement";
	Filter.NameTSGoods = "GoodsFilter";
	Filter.TSSeriesName  = "GoodsFilter";
	
	Filter.UseItemsBatch  = WarehouseSeriesParameters.UseItemsBatch;
	Filter.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;
	Filter.UseBinLocationWarehousing = True;
	Filter.FieldNameQuantity = "NumberOfPackages";	
	Filter.LinkFields.Add("Package");
	Filter.LinkFields.Add("Cell");
	Filter.LinkFields.Add("Purpose");
	
	Filter.ItSWarrant = True;
	Filter.FieldNameRoom = "Premise";
	
	If Object.OperationKind = Enums.OperationKindsOfGoodsPlacementPicking.Location Then
		Filter.ShipmentPlanning = True;
		Filter.FactOfSelection = True;
	Else
		Filter.ShipmentPlanning = Object.Status = Enums.StatusesOfGoodsPickingPlacement.InProgress
												  Or Object.Status = Enums.StatusesOfGoodsPickingPlacement.Prepared2;
			
		Filter.FactOfSelection = Object.Status = Enums.StatusesOfGoodsPickingPlacement.CompletedWithoutErrors
											Or Object.Status = Enums.StatusesOfGoodsPickingPlacement.DoneWithErrors;
	EndIf;

	If Object.Status = Enums.StatusesOfGoodsPickingPlacement.DoneWithErrors Then
		Filter.FieldNameQuantity = "NumberOfPackagesPicked";
	Else
		Filter.FieldNameQuantity = "NumberOfPackages";
	EndIf;
	
	Filter.Date = Object.Date;
	Filter.WarehouseTransactions.Add(Enums.WarehouseTransactions.PickingFromStorageBins);
	
	#If Not MobileStandaloneServer Then
		Location = ProductsClientServer.SeriesSpecificationParameters();
		
		WarehouseSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Warehouse, False);
	#Else
		Location = MobileWarehouseKeeperWorkspace.ItemClientServerSerialSpecificationParameters();
		
		WarehouseSeriesParameters = MobileWarehouseKeeperWorkspace.UseOfSeriesInStock(Object.Warehouse, False);
	#EndIf
	
	Location.FullObjectName = "Document.GoodsPickingPlacement";
	Location.NameTSGoods = "GoodsPlacement";
	Location.TSSeriesName  = "GoodsPlacement";
	
	Location.UseItemsBatch  = WarehouseSeriesParameters.UseItemsBatch;
	Location.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;
	Location.UseBinLocationWarehousing = True;
	Location.FieldNameQuantity = "NumberOfPackages";	
	Location.LinkFields.Add("Package");
	Location.LinkFields.Add("Cell");
	Location.LinkFields.Add("Purpose");
	
	Location.ItSWarrant = True;
	Location.FieldNameRoom = "Premise";
	
	If Object.OperationKind = Enums.OperationKindsOfGoodsPlacementPicking.Location Then
		Location.ShipmentPlanning = True;
		Location.FactOfSelection = True;
	Else
		Location.ShipmentPlanning = Object.Status = Enums.StatusesOfGoodsPickingPlacement.InProgress
												  Or Object.Status = Enums.StatusesOfGoodsPickingPlacement.Prepared2;
			
		Location.FactOfSelection = Object.Status = Enums.StatusesOfGoodsPickingPlacement.CompletedWithoutErrors
											Or Object.Status = Enums.StatusesOfGoodsPickingPlacement.DoneWithErrors;
	EndIf;
	
	If Object.Status = Enums.StatusesOfGoodsPickingPlacement.DoneWithErrors Then
		Location.FieldNameQuantity = "NumberOfPackagesPlaced";
	Else
		Location.FieldNameQuantity = "NumberOfPackages";
	EndIf;
	
	Location.Date = Object.Date;
	Location.WarehouseTransactions.Add(Enums.WarehouseTransactions.PlacementIntoBins);
	
	SeriesSpecificationParameters = New Structure;
	SeriesSpecificationParameters.Insert("Filter", Filter);
	SeriesSpecificationParameters.Insert("Location", Location);
	
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
	|	Goods.Products,
	|	Goods.Series,
	|	Goods.BatchesIndicationStatus,
	|	Goods.LineNumber
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL 
	|			THEN 0
	|		ELSE CASE
	|				WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment
	|					THEN CASE
	|							WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
	|								THEN CASE
	|										WHEN Goods.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|											THEN 13
	|										ELSE 14
	|									END
	|							ELSE CASE
	|									WHEN Goods.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|										THEN 9
	|									ELSE 10
	|								END
	|						END
	|				WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningPicking
	|					THEN CASE
	|							WHEN Goods.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|								THEN 7
	|							ELSE 8
	|						END
	|				WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyByPickingResult
	|						AND BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries
	|						AND &FactOfSelection
	|					THEN CASE
	|							WHEN Goods.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|								THEN 3
	|							ELSE 4
	|						END
	|				ELSE 0
	|			END
	|	END AS BatchesIndicationStatus
	|INTO StatusTable
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|			INNER JOIN Catalog.Warehouses AS Warehouses
	|			ON BatchAccountingPolicies.Warehouse = Warehouses.Ref
	|		ON (CAST(Goods.Products AS Catalog.Products).ProductKind = BatchAccountingPolicies.Ref)
	|			AND (BatchAccountingPolicies.Warehouse = &Warehouse)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	StatusTable.LineNumber AS LineNumber,
	|	StatusTable.BatchesIndicationStatus AS BatchesIndicationStatus
	|FROM
	|	StatusTable AS StatusTable
	|WHERE
	|	StatusTable.OldStatusOfSpecifyingSeries <> StatusTable.BatchesIndicationStatus
	|
	|ORDER BY
	|	LineNumber";
	
	Return QueryText;

EndFunction

#If Not MobileStandaloneServer Then

// Returns a table of States and dates of cell recalculations after the selection/placement of products with an error.
//
// Parameters:
//  DocumentRef	 - DocumentRef.GoodsPickingPlacement	 - link to the document " Selection and placement of products"
//  Status			 - EnumRef.StatusesOfGoodsPickingPlacement	 - the status of the document "Selection placement of products".
//
// Returns:
//  ValueTable - a table of values with states and dates of cell recalculations.
//
Function TableOfCellRecalculationStates(DocumentRef, Status) Export
	
	TableOfCellRecalculationStates = New ValueTable;
	OperationKind = Common.ObjectAttributeValue(DocumentRef, "OperationKind");
	
	If Status = Enums.StatusesOfGoodsPickingPlacement.DoneWithErrors Then
		
		If OperationKind = Enums.OperationKindsOfGoodsPlacementPicking.Move Then
			
			QueryText = 
			"SELECT
			|	COUNT(DISTINCT SelectionCells.Cell) AS NumberOfBins
			|INTO SelectionCellsForMarking
			|FROM
			|	Document.GoodsPickingPlacement.GoodsFilter AS SelectionCells
			|WHERE
			|	SelectionCells.Ref = &DocumentRef
			|	AND SelectionCells.Count <> SelectionCells.CountPicked
			|
			|HAVING
			|	COUNT(DISTINCT SelectionCells.Cell) > 0
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT DISTINCT
			|	CellsWithErrors.Cell                                            AS Cell,
			|	CellsWithErrors.DocumentDate                                     AS DocumentDate,
			|	VALUE(Enum.BinRecountStates.RecountIsRequired) AS State
			|FROM
			|	(SELECT DISTINCT
			|		SelectingGoodItems.Cell      AS Cell,
			|		SelectingGoodItems.Ref.Date AS DocumentDate
			|	FROM
			|		Document.GoodsPickingPlacement.GoodsFilter AS SelectingGoodItems
			|			LEFT JOIN SelectionCellsForMarking AS SelectionCellsForMarking
			|			ON TRUE
			|	WHERE
			|		SelectingGoodItems.Ref = &DocumentRef
			|		AND ISNULL(SelectionCellsForMarking.NumberOfBins, 0) > 0
			|		AND SelectingGoodItems.Count <> SelectingGoodItems.CountPicked
			|	
			|	UNION ALL
			|	
			|	SELECT DISTINCT
			|		ProductsPlaced.Cell      AS Cell,
			|		ProductsPlaced.Ref.Date AS DocumentDate
			|	FROM
			|		Document.GoodsPickingPlacement.GoodsPlacement AS ProductsPlaced
			|			LEFT JOIN SelectionCellsForMarking AS SelectionCellsForMarking
			|			ON TRUE
			|	WHERE
			|		ProductsPlaced.Ref = &DocumentRef
			|		AND ISNULL(SelectionCellsForMarking.NumberOfBins, 0) = 0
			|		AND ProductsPlaced.Count <> ProductsPlaced.CountPlaced) AS CellsWithErrors";
			
		Else
			
			QueryText = 
			"SELECT DISTINCT
			|	CellsWithErrors.Cell,
			|	CellsWithErrors.DocumentDate AS DocumentDate,
			|	VALUE(Enum.BinRecountStates.RecountIsRequired) AS State
			|FROM
			|	(SELECT
			|		SelectionProductPlacementProductsSelection.Cell AS Cell,
			|		SelectionProductPlacementProductsSelection.Ref.Date AS DocumentDate
			|	FROM
			|		Document.GoodsPickingPlacement.GoodsFilter AS SelectionProductPlacementProductsSelection
			|	WHERE
			|		SelectionProductPlacementProductsSelection.Ref = &DocumentRef
			|		AND SelectionProductPlacementProductsSelection.Count <> SelectionProductPlacementProductsSelection.CountPicked
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		SelectionProductPlacementProductsPlacement.Cell,
			|		SelectionProductPlacementProductsPlacement.Ref.Date
			|	FROM
			|		Document.GoodsPickingPlacement.GoodsPlacement AS SelectionProductPlacementProductsPlacement
			|	WHERE
			|		SelectionProductPlacementProductsPlacement.Ref = &DocumentRef
			|		AND SelectionProductPlacementProductsPlacement.Count <> SelectionProductPlacementProductsPlacement.CountPlaced) AS CellsWithErrors";
			
		EndIf;
		
		Query = New Query;
		Query.Text = QueryText;
		
		Query.SetParameter("DocumentRef", DocumentRef);
		TableOfCellRecalculationStates = Query.Execute().Unload();
		
	EndIf;
	
	Return TableOfCellRecalculationStates;
	
EndFunction

// Returns the request body for the get the available appointments
//	Parameters:
//		RequestFormationParameters - Structure - the parameters for the generation of text queries
//	Returns:
//		String - query text.
//
Function RequestTextForAvailableAssignments(RequestFormationParameters) Export
	
	If RequestFormationParameters.OperationKind = Enums.OperationKindsOfGoodsPlacementPicking.Location Then
		
		QueryText = Catalogs.Assignments.RequestTextForAvailableAssignmentsBasedOnBalancesInCell(RequestFormationParameters);
		
	ElsIf RequestFormationParameters.OperationKind = Enums.OperationKindsOfGoodsPlacementPicking.Move Then
		
		If RequestFormationParameters.ChoiceMode = "ResiduesInCell" Then
			QueryText = Catalogs.Assignments.RequestTextForAvailableAssignmentsBasedOnBalancesInCell(RequestFormationParameters);
		Else
			QueryText =
			"SELECT
			|	RegisterDataGoodsInWarehouses.Products AS Products,
			|	RegisterDataGoodsInWarehouses.Characteristic AS Characteristic,
			|	Assignments.Ref AS Purpose,
			|	SUM(RegisterDataGoodsInWarehouses.Demand) AS Demand,
			|	SUM(RegisterDataGoodsInWarehouses.Demand) - MAX(ISNULL(DocumentData.Count, 0)) AS Balance,
			|	SUM(0) AS Supplied,
			|	Assignments.RecordsInWarehouseRegisters AS RecordsInWarehouseRegisters
			|FROM
			|	(SELECT
			|		ProductStockBalance.Products AS Products,
			|		ProductStockBalance.Characteristic AS Characteristic,
			|		ProductStockBalance.Purpose AS Purpose,
			|		ProductStockBalance.InStockBalance AS Demand
			|	FROM
			|		AccumulationRegister.ProductStock.Balance(
			|				,
			|				Characteristic = &Characteristic
			|					AND Products = &Products
			|					AND Purpose <> VALUE(Catalog.Assignments.EmptyRef)
			|					AND Warehouse = &Warehouse) AS ProductStockBalance) AS RegisterDataGoodsInWarehouses
			|		LEFT JOIN GoodsOfDocumentAreGrouped AS DocumentData
			|		ON RegisterDataGoodsInWarehouses.Products = DocumentData.Products
			|			AND RegisterDataGoodsInWarehouses.Characteristic = DocumentData.Characteristic
			|			AND RegisterDataGoodsInWarehouses.Purpose = DocumentData.Purpose
			|		INNER JOIN Catalog.Assignments AS Assignments
			|		ON RegisterDataGoodsInWarehouses.Purpose = Assignments.Ref
			|WHERE
			|	RegisterDataGoodsInWarehouses.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
			|	AND RegisterDataGoodsInWarehouses.Purpose.RecordsInWarehouseRegisters
			|
			|GROUP BY
			|	RegisterDataGoodsInWarehouses.Products,
			|	RegisterDataGoodsInWarehouses.Characteristic,
			|	Assignments.Ref";

			If RequestFormationParameters.TakeIntoAccountAlreadySelected Then
				// The request is not for dynamic lists
				QueryText =
				"SELECT
				|	DocumentGoods.Products,
				|	DocumentGoods.Characteristic,
				|	DocumentGoods.Purpose,
				|	DocumentGoods.Count
				|INTO TableOfDocumentProducts
				|FROM
				|	&DocumentGoods AS DocumentGoods
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	TableOfDocumentProducts.Products AS Products,
				|	TableOfDocumentProducts.Characteristic AS Characteristic,
				|	TableOfDocumentProducts.Purpose AS Purpose,
				|	SUM(TableOfDocumentProducts.Count) AS Count
				|INTO GoodsOfDocumentAreGrouped
				|FROM
				|	TableOfDocumentProducts AS TableOfDocumentProducts
				|WHERE
				|	TableOfDocumentProducts.Products = &Products AND TableOfDocumentProducts.Characteristic = &Characteristic
				|
				|GROUP BY
				|	TableOfDocumentProducts.Products,
				|	TableOfDocumentProducts.Characteristic,
				|	TableOfDocumentProducts.Purpose
				|;" + QueryText;
			Else
				QueryText = StrReplace(QueryText, "GoodsOfDocumentAreGrouped", "(" +
				"SELECT
				|	TRUE AS Products,
				|	TRUE AS Characteristic,
				|	TRUE AS Purpose,
				|	0 AS Count" + ")");
			EndIf;
			
		EndIf;
		
	Else
		
		QueryText =
		"SELECT ALLOWED
		|	RegisterDataReadyForSelection.Products AS Products,
		|	RegisterDataReadyForSelection.Characteristic AS Characteristic,
		|	SUM(RegisterDataReadyForSelection.Demand) AS Demand,
		|	SUM(RegisterDataReadyForSelection.Demand) - MAX(ISNULL(DocumentData.Count, 0)) AS Balance,
		|	SUM(0) AS Supplied,
		|	Assignments.Ref AS Purpose,
		|	Assignments.RecordsInWarehouseRegisters AS RecordsInWarehouseRegisters
		|FROM
		|	(SELECT
		|		GoodsForPickingBalance.Products AS Products,
		|		GoodsForPickingBalance.Characteristic AS Characteristic,
		|		GoodsForPickingBalance.Purpose AS Purpose,
		|		GoodsForPickingBalance.ForPickingBalance - GoodsForPickingBalance.BeingPickedBalance - GoodsForPickingBalance.PickedBalance AS Demand
		|	FROM
		|		AccumulationRegister.GoodsForPicking.Balance(
		|				,
		|				Characteristic = &Characteristic
		|					AND Products = &Products
		|					AND Purpose <> VALUE(Catalog.Assignments.EmptyRef)
		|					AND ReferenceOrder = &ReferenceOrder
		|					OR ReferenceOrder.TransportationJob = &ReferenceOrder) AS GoodsForPickingBalance
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		GoodsForPicking.Products,
		|		GoodsForPicking.Characteristic,
		|		GoodsForPicking.Purpose,
		|		CASE
		|			WHEN GoodsForPicking.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN GoodsForPicking.BeingPicked + GoodsForPicking.Picked
		|			ELSE 0
		|		END
		|	FROM
		|		AccumulationRegister.GoodsForPicking AS GoodsForPicking
		|	WHERE
		|		GoodsForPicking.Products = &Products
		|		AND GoodsForPicking.Characteristic = &Characteristic
		|		AND GoodsForPicking.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
		|		AND (ReferenceOrder = &ReferenceOrder
		|					OR ReferenceOrder.TransportationJob = &ReferenceOrder)
		|		AND GoodsForPicking.Recorder = &Recorder
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		&Products,
		|		&Characteristic,
		|		&Purpose,
		|		0) AS RegisterDataReadyForSelection
		|		LEFT JOIN GoodsOfDocumentAreGrouped AS DocumentData
		|		ON RegisterDataReadyForSelection.Products = DocumentData.Products
		|			AND RegisterDataReadyForSelection.Characteristic = DocumentData.Characteristic
		|			AND RegisterDataReadyForSelection.Purpose = DocumentData.Purpose
		|		INNER JOIN Catalog.Assignments AS Assignments
		|		ON RegisterDataReadyForSelection.Purpose = Assignments.Ref
		|WHERE
		|	RegisterDataReadyForSelection.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
		|	AND RegisterDataReadyForSelection.Purpose.RecordsInWarehouseRegisters
		|
		|GROUP BY
		|	RegisterDataReadyForSelection.Products,
		|	RegisterDataReadyForSelection.Characteristic,
		|	Assignments.Ref";
		
		If RequestFormationParameters.TakeIntoAccountAlreadySelected Then
			// The request is not for dynamic lists
			QueryText =
			"SELECT
			|	DocumentGoods.Products,
			|	DocumentGoods.Characteristic,
			|	DocumentGoods.Purpose,
			|	DocumentGoods.Count
			|INTO TableOfDocumentProducts
			|FROM
			|	&DocumentGoods AS DocumentGoods
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	TableOfDocumentProducts.Products AS Products,
			|	TableOfDocumentProducts.Characteristic AS Characteristic,
			|	TableOfDocumentProducts.Purpose AS Purpose,
			|	SUM(TableOfDocumentProducts.Count) AS Count
			|INTO GoodsOfDocumentAreGrouped
			|FROM
			|	TableOfDocumentProducts AS TableOfDocumentProducts
			|WHERE
			|	TableOfDocumentProducts.Products = &Products AND TableOfDocumentProducts.Characteristic = &Characteristic
			|
			|GROUP BY
			|	TableOfDocumentProducts.Products,
			|	TableOfDocumentProducts.Characteristic,
			|	TableOfDocumentProducts.Purpose
			|;" + QueryText;
		Else
			QueryText = StrReplace(QueryText, "GoodsOfDocumentAreGrouped", "(" +
				"SELECT
				|	TRUE AS Products,
				|	TRUE AS Characteristic,
				|	TRUE AS Purpose,
				|	0 AS Count" + ")");
		EndIf;
	EndIf;
			
	Return QueryText;
	
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Warehouse)";

EndProcedure

// End StandardSubsystems.AccessManagement

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure
// End StandardSubsystems.ObjectsVersioning

#EndIf

#EndRegion

#Region Private

#If Not MobileStandaloneServer Then

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.SetParameter("Ref", DocumentRef);
	Query.Text = 
	"SELECT
	|	CASE
	|		WHEN GoodsPickingPlacement.ExecutionStartDate <> DATETIME(1, 1, 1)
	|				AND GoodsPickingPlacement.Status = VALUE(Enum.StatusesOfGoodsPickingPlacement.InProgress)
	|			THEN GoodsPickingPlacement.ExecutionStartDate
	|		WHEN GoodsPickingPlacement.ExecutionEndDate <> DATETIME(1, 1, 1)
	|				AND GoodsPickingPlacement.Status IN(VALUE(Enum.StatusesOfGoodsPickingPlacement.CompletedWithoutErrors),
	|													VALUE(Enum.StatusesOfGoodsPickingPlacement.DoneWithErrors))
	|			THEN GoodsPickingPlacement.ExecutionEndDate
	|		ELSE GoodsPickingPlacement.Date
	|	END AS Period,
	|	GoodsPickingPlacement.OperationKind AS OperationKind,
	|	GoodsPickingPlacement.Status AS Status,
	|	GoodsPickingPlacement.ReferenceOrder AS ReferenceOrder,
	|	GoodsPickingPlacement.ReceivingArea AS ReceivingArea,
	|	GoodsPickingPlacement.Warehouse AS Warehouse,
	|	GoodsPickingPlacement.Premise AS Premise
	|FROM
	|	Document.GoodsPickingPlacement AS GoodsPickingPlacement
	|WHERE
	|	GoodsPickingPlacement.Ref = &Ref";
	
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	Query.SetParameter("Status",			Attributes.Status);
	Query.SetParameter("Warehouse",			Attributes.Warehouse);
	Query.SetParameter("Premise",		Attributes.Premise);
	Query.SetParameter("Period",			Attributes.Period);
	Query.SetParameter("OperationKind",	Attributes.OperationKind);
	Query.SetParameter("ReceivingArea",	Attributes.ReceivingArea);
	Query.SetParameter("ReferenceOrder",	Attributes.ReferenceOrder);
	Query.SetParameter("OrderingForSeries",
								?(ValueIsFilled(Attributes.ReferenceOrder), Attributes.ReferenceOrder, DocumentRef));
	
EndProcedure

Procedure PickUpProducts(Query, QueryTexts, Registers)
	
	// For Selection and Relocation operations
	
	QueryTextDocument_ =
	// In the work - we fix the beginning of the selection process, reserve the goods in the cells
	"SELECT
	|	GoodsTable.Ref              AS Ref,
	|	CASE
	|		WHEN GoodsTable.Ref.ExecutionStartDate <> DATETIME(1, 1, 1)
	|				AND GoodsTable.Ref.Status = VALUE(Enum.StatusesOfGoodsPickingPlacement.InProgress)
	|			THEN GoodsTable.Ref.ExecutionStartDate
	|		ELSE GoodsTable.Ref.Date
	|	END                             AS Date,
	|	GoodsTable.Ref.ReferenceOrder AS ReferenceOrder,
	|	GoodsTable.Cell              AS Cell,
	|	GoodsTable.Products        AS Products,
	|	GoodsTable.Characteristic      AS Characteristic,
	|	GoodsTable.Purpose          AS Purpose,
	|	GoodsTable.Series               AS Series,
	|	GoodsTable.Package            AS Package,
	|	GoodsTable.Count          AS Count,
	|	GoodsTable.NumberOfPackages  AS NumberOfPackages,
	|	GoodsTable.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	GoodsTable.Ref.OperationKind = VALUE(Enum.OperationKindsOfGoodsPlacementPicking.Filter) AS IsFilter,
	|	FALSE                              AS Picked,
	|	TRUE                            AS ThisIsReflectionOfCells
	|FROM
	|	Document.GoodsPickingPlacement.GoodsFilter AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN(&Ref)
	|	AND GoodsTable.Ref.Status IN(VALUE(Enum.StatusesOfGoodsPickingPlacement.InProgress),
	|									VALUE(Enum.StatusesOfGoodsPickingPlacement.Prepared2))
	|
	|UNION ALL
	|
	// Completed - we record the completion of the selection
	|SELECT
	|	GoodsTable.Ref              AS Ref,
	|	CASE
	|		WHEN GoodsTable.Ref.ExecutionEndDate = DATETIME(1, 1, 1)
	|			THEN GoodsTable.Ref.Date
	|		ELSE GoodsTable.Ref.ExecutionEndDate
	|	END                             AS Date,
	|	GoodsTable.Ref.ReferenceOrder AS ReferenceOrder,
	|	UNDEFINED                      AS Cell,
	|	GoodsTable.Products        AS Products,
	|	GoodsTable.Characteristic      AS Characteristic,
	|	GoodsTable.Purpose          AS Purpose,
	|	GoodsTable.Series               AS Series,
	|	GoodsTable.Package            AS Package,
	|	GoodsTable.CountPicked  AS Count,
	|	GoodsTable.NumberOfPackagesPicked AS NumberOfPackages,
	|	GoodsTable.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	GoodsTable.Ref.OperationKind = VALUE(Enum.OperationKindsOfGoodsPlacementPicking.Filter) AS IsFilter,
	|	TRUE                            AS Picked,
	|	FALSE                              AS ThisIsReflectionOfCells
	|FROM
	|	Document.GoodsPickingPlacement.GoodsFilter AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN(&Ref)
	|	AND GoodsTable.NumberOfPackagesPicked > 0
	|	AND GoodsTable.Ref.Status IN(VALUE(Enum.StatusesOfGoodsPickingPlacement.CompletedWithoutErrors),
	|									VALUE(Enum.StatusesOfGoodsPickingPlacement.DoneWithErrors))
	|
	|UNION ALL
	|
	// Completed - we fix the write-off of the product from the cells
	|SELECT
	|	GoodsTable.Ref              AS Ref,
	|	CASE
	|		WHEN GoodsTable.Ref.ExecutionEndDate = DATETIME(1, 1, 1)
	|			THEN GoodsTable.Ref.Date
	|		ELSE GoodsTable.Ref.ExecutionEndDate
	|	END                             AS Date,
	|	UNDEFINED                      AS ReferenceOrder,
	|	GoodsTable.Cell              AS Cell,
	|	GoodsTable.Products        AS Products,
	|	GoodsTable.Characteristic      AS Characteristic,
	|	GoodsTable.Purpose          AS Purpose,
	|	GoodsTable.Series               AS Series,
	|	GoodsTable.Package            AS Package,
	|	-GoodsTable.CountPicked  AS Count,
	|	-GoodsTable.NumberOfPackagesPicked AS NumberOfPackages,
	|	GoodsTable.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	FALSE                              AS IsFilter,
	|	TRUE                            AS Picked,
	|	TRUE                            AS ThisIsReflectionOfCells
	|FROM
	|	Document.GoodsPickingPlacement.GoodsFilter AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN(&Ref)
	|	AND GoodsTable.NumberOfPackagesPicked > 0
	|	AND GoodsTable.Ref.Status IN(VALUE(Enum.StatusesOfGoodsPickingPlacement.CompletedWithoutErrors),
	|									VALUE(Enum.StatusesOfGoodsPickingPlacement.DoneWithErrors))
	|";
	
	WarehousesServer.PickUpProducts(Query, QueryTexts, Registers, QueryTextDocument_);
	
EndProcedure

Procedure PlaceProducts(Query, QueryTexts, Registers)
	
	QueryTextDocument_ =
	// Completed - we record the receipt of goods in the cells
	"SELECT
	|	GoodsTable.Ref              AS Ref,
	|	CASE
	|		WHEN GoodsTable.Ref.ExecutionEndDate = DATETIME(1, 1, 1)
	|			THEN GoodsTable.Ref.Date
	|		ELSE GoodsTable.Ref.ExecutionEndDate
	|	END                             AS Date,
	|	GoodsTable.Ref.Warehouse        AS Warehouse,
	|	GoodsTable.Cell              AS Cell,
	|	GoodsTable.Products        AS Products,
	|	GoodsTable.Characteristic      AS Characteristic,
	|	GoodsTable.Purpose          AS Purpose,
	|	GoodsTable.Series               AS Series,
	|	GoodsTable.Package            AS Package,
	|	GoodsTable.CountPlaced         AS Count,
	|	GoodsTable.NumberOfPackagesPlaced AS NumberOfPackages,
	|	GoodsTable.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	FALSE                              AS Reserved,
	|	FALSE                              AS TakePlaces,
	|	TRUE                            AS Placed
	|FROM
	|	Document.GoodsPickingPlacement.GoodsPlacement AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN(&Ref)
	|	AND GoodsTable.Ref.Status IN(VALUE(Enum.StatusesOfGoodsPickingPlacement.CompletedWithoutErrors),
	|									VALUE(Enum.StatusesOfGoodsPickingPlacement.DoneWithErrors))
	|	AND GoodsTable.NumberOfPackagesPlaced > 0
	|
	|UNION ALL
	|
	// In the work - IF the type of operation is "Placement" - we reserve the goods in the cell of the acceptance zone
	|SELECT
	|	GoodsTable.Ref              AS Ref,
	|	CASE
	|		WHEN GoodsTable.Ref.ExecutionStartDate <> DATETIME(1, 1, 1)
	|				AND GoodsTable.Ref.Status = VALUE(Enum.StatusesOfGoodsPickingPlacement.InProgress)
	|			THEN GoodsTable.Ref.ExecutionStartDate
	|		ELSE GoodsTable.Ref.Date
	|	END                             AS Date,
	|	GoodsTable.Ref.Warehouse        AS Warehouse,
	|	GoodsTable.Ref.ReceivingArea  AS Cell,
	|	GoodsTable.Products        AS Products,
	|	GoodsTable.Characteristic      AS Characteristic,
	|	GoodsTable.Purpose          AS Purpose,
	|	GoodsTable.Series               AS Series,
	|	GoodsTable.Package            AS Package,
	|	GoodsTable.Count          AS Count,
	|	GoodsTable.NumberOfPackages  AS NumberOfPackages,
	|	GoodsTable.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TRUE                            AS Reserved,
	|	FALSE                              AS TakePlaces,
	|	FALSE                              AS Placed
	|FROM
	|	Document.GoodsPickingPlacement.GoodsPlacement AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN(&Ref)
	|	AND GoodsTable.Ref.Status IN(VALUE(Enum.StatusesOfGoodsPickingPlacement.Prepared2),
	|									VALUE(Enum.StatusesOfGoodsPickingPlacement.InProgress))
	|	AND GoodsTable.NumberOfPackages > 0
	|	AND GoodsTable.Ref.OperationKind = VALUE(Enum.OperationKindsOfGoodsPlacementPicking.Location)
	|
	|UNION ALL
	|
	// Completed - IF the type of operation is "Placement" - we record the shipment of goods from the cell of the acceptance zone
	|SELECT
	|	GoodsTable.Ref              AS Ref,
	|	CASE
	|		WHEN GoodsTable.Ref.ExecutionEndDate = DATETIME(1, 1, 1)
	|			THEN GoodsTable.Ref.Date
	|		ELSE GoodsTable.Ref.ExecutionEndDate
	|	END                             AS Date,
	|	GoodsTable.Ref.Warehouse        AS Warehouse,
	|	GoodsTable.Ref.ReceivingArea  AS Cell,
	|	GoodsTable.Products        AS Products,
	|	GoodsTable.Characteristic      AS Characteristic,
	|	GoodsTable.Purpose          AS Purpose,
	|	GoodsTable.Series               AS Series,
	|	GoodsTable.Package            AS Package,
	|	-GoodsTable.CountPlaced         AS Count,
	|	-GoodsTable.NumberOfPackagesPlaced AS NumberOfPackages,
	|	GoodsTable.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	FALSE                              AS Reserved,
	|	FALSE                              AS TakePlaces,
	|	TRUE                            AS Placed
	|FROM
	|	Document.GoodsPickingPlacement.GoodsPlacement AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN(&Ref)
	|	AND GoodsTable.Ref.Status IN(VALUE(Enum.StatusesOfGoodsPickingPlacement.CompletedWithoutErrors),
	|									VALUE(Enum.StatusesOfGoodsPickingPlacement.DoneWithErrors))
	|	AND GoodsTable.NumberOfPackagesPlaced > 0
	|	AND GoodsTable.Ref.OperationKind = VALUE(Enum.OperationKindsOfGoodsPlacementPicking.Location)
	|
	|UNION ALL
	|
	// In the work - we fix it for placement in cells
	|SELECT
	|	GoodsTable.Ref              AS Ref,
	|	CASE
	|		WHEN GoodsTable.Ref.ExecutionStartDate <> DATETIME(1, 1, 1)
	|				AND GoodsTable.Ref.Status = VALUE(Enum.StatusesOfGoodsPickingPlacement.InProgress)
	|			THEN GoodsTable.Ref.ExecutionStartDate
	|		ELSE GoodsTable.Ref.Date
	|	END                             AS Date,
	|	GoodsTable.Ref.Warehouse        AS Warehouse,
	|	GoodsTable.Cell              AS Cell,
	|	GoodsTable.Products        AS Products,
	|	GoodsTable.Characteristic      AS Characteristic,
	|	GoodsTable.Purpose          AS Purpose,
	|	GoodsTable.Series               AS Series,
	|	GoodsTable.Package            AS Package,
	|	GoodsTable.Count          AS Count,
	|	GoodsTable.NumberOfPackages  AS NumberOfPackages,
	|	GoodsTable.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	FALSE                              AS Reserved,
	|	TRUE                            AS TakePlaces,
	|	FALSE                              AS Placed
	|FROM
	|	Document.GoodsPickingPlacement.GoodsPlacement AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN(&Ref)
	|	AND GoodsTable.Ref.Status IN(VALUE(Enum.StatusesOfGoodsPickingPlacement.Prepared2),
	|									VALUE(Enum.StatusesOfGoodsPickingPlacement.InProgress))
	|	AND GoodsTable.NumberOfPackages > 0
	|";
	
	WarehousesServer.PlaceProducts(Query, QueryTexts, Registers, QueryTextDocument_);
	
EndProcedure

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	// Assignment to a warehouse worker
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "WarehouseJob";
	PrintCommand.Presentation = NStr("vi = 'Nhiệm vụ dành cho nhân viên kho';
									|ru = 'Задание складскому работнику';
									|en = 'Put-away task'; fa = 'وظیفه جای‌گذاری';
									|it = 'Task al dipendente di magazzino';
									|pl = 'Zadanie dla pracownika magazynowego';
									|tr = 'Ambar çalışanına görev'");
	PrintCommand.CheckPostingBeforePrint = True;
	
	// Labels
	PrintCommand = PrintCommands.Add();
	PrintCommand.Handler = "PrintManagementTMClient.PrintPriceTagsAndLabels";
	PrintCommand.PrintManager = "Document.GoodsPickingPlacement";
	PrintCommand.Id = "Labels";
	PrintCommand.Presentation = NStr("vi = 'Nhãn tem';
									|ru = 'Этикетки';
									|en = 'Labels'; fa = 'برچسب‌ها';
									|it = 'Etichette';
									|pl = 'Labels';
									|tr = 'Etiketler'");
	PrintCommand.CheckPostingBeforePrint = True;


EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "WarehouseJob") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"WarehouseJob",
			NStr("vi = 'Nhiệm vụ kho bãi';
				|ru = 'Складское задание';
				|en = 'Warehouse task'; fa = 'Warehouse task';
				|it = 'Task di magazzino';
				|pl = 'Zadanie magazynowe';
				|tr = 'Ambar görevi'"),
			PrintJob(ObjectsArray, PrintObjects));
	EndIf;
EndProcedure

Function PrintJob(ObjectsArray, PrintObjects)
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputCodes = ValueIsFilled(NameOfCodeColumn);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PrintPARAMETERS_SelectionOfProductPlacement_TaskForSelectionOfProductPlacement";
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	GoodsPickingPlacement.Ref AS Ref,
	|	GoodsPickingPlacement.Date AS Date,
	|	GoodsPickingPlacement.Number AS Number,
	|	GoodsPickingPlacement.OperationKind AS OperationKind,
	|	PRESENTATION(GoodsPickingPlacement.ShippingZone) AS ShippingZonePresentation,
	|	PRESENTATION(GoodsPickingPlacement.ReceivingArea) AS ReceivingAreaPresentation,
	|	PRESENTATION(GoodsPickingPlacement.WarehouseZone) AS WarehouseZonePresentation,
	|	PRESENTATION(GoodsPickingPlacement.Warehouse) AS WarehousePresentation,
	|	PRESENTATION(GoodsPickingPlacement.Premise) AS PremisePresentation,
	|	GoodsPickingPlacement.Performer.Individual AS Performer,
	|	GoodsPickingPlacement.ReferenceOrder AS ReferenceOrder,
	|	PRESENTATION(GoodsPickingPlacement.ReferenceOrder) AS ReferenceOrderPresentation,
	|	GoodsPickingPlacement.ReferenceOrder.Date AS Order_Date,
	|	GoodsPickingPlacement.ReferenceOrder.Number AS OrderNumber__,
	|	ISNULL(GoodsPickingPlacement.ReferenceOrder.ShipmentUnderTransportationJob, FALSE) AS ShipmentUnderTransportationJob,
	|	GoodsPickingPlacement.ReferenceOrder.DeliveryProcedure AS DeliveryProcedure,
	|	PRESENTATION(GoodsPickingPlacement.ReferenceOrder.TransportationJob) AS TransportationJobPresentation,
	|	GoodsPickingPlacement.ReferenceOrder.TransportationJob.Number AS TransportationTaskNumber,
	|	GoodsPickingPlacement.ReferenceOrder.TransportationJob.Date AS TransportationTaskDate
	|FROM
	|	Document.GoodsPickingPlacement AS GoodsPickingPlacement
	|WHERE
	|	GoodsPickingPlacement.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SelectionProductPlacementProductsSelection.LineNumber AS LineNumber,
	|	0 AS Label,
	|	SelectionProductPlacementProductsSelection.NumberOfPackages AS CountPlan,
	|	SelectionProductPlacementProductsSelection.NumberOfPackagesPicked AS CountReal,
	|	SelectionProductPlacementProductsSelection.Products.DescriptionFull AS ProductsPresentation,
	|	SelectionProductPlacementProductsSelection.Characteristic.DescriptionFull AS CharacteristicPresentation,
	|	SelectionProductPlacementProductsSelection.Series.Description AS SeriesPresentation,
	|	PRESENTATION(SelectionProductPlacementProductsSelection.Cell) AS CellPresentation,
	|	PRESENTATION(SelectionProductPlacementProductsSelection.Package) AS PackagePresentation,
	|	SelectionProductPlacementProductsSelection.Products.Code AS Code,
	|	SelectionProductPlacementProductsSelection.Products.SKU AS SKU,
	|	SelectionProductPlacementProductsSelection.Ref AS Ref
	|FROM
	|	Document.GoodsPickingPlacement.GoodsFilter AS SelectionProductPlacementProductsSelection
	|WHERE
	|	SelectionProductPlacementProductsSelection.Ref IN(&ObjectsArray)
	|
	|UNION ALL
	|
	|SELECT
	|	SelectionProductPlacementProductsPlacement.LineNumber,
	|	1,
	|	SelectionProductPlacementProductsPlacement.NumberOfPackages,
	|	SelectionProductPlacementProductsPlacement.NumberOfPackagesPlaced,
	|	SelectionProductPlacementProductsPlacement.Products.DescriptionFull,
	|	SelectionProductPlacementProductsPlacement.Characteristic.DescriptionFull,
	|	PRESENTATION(SelectionProductPlacementProductsPlacement.Series),
	|	PRESENTATION(SelectionProductPlacementProductsPlacement.Cell),
	|	PRESENTATION(SelectionProductPlacementProductsPlacement.Package),
	|	SelectionProductPlacementProductsPlacement.Products.Code,
	|	SelectionProductPlacementProductsPlacement.Products.SKU,
	|	SelectionProductPlacementProductsPlacement.Ref
	|FROM
	|	Document.GoodsPickingPlacement.GoodsPlacement AS SelectionProductPlacementProductsPlacement
	|WHERE
	|	SelectionProductPlacementProductsPlacement.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Ref,
	|	Label,
	|	LineNumber
	|TOTALS BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	GoodsPickingPlacement.Ref AS Ref,
	|	PRESENTATION(GoodsIssueNoteGoodsByReferences.ReferenceOrder) AS BasisPresentation,
	|	GoodsIssueNoteGoodsByReferences.ReferenceOrder.Number AS BaseDocumentNumber,
	|	GoodsIssueNoteGoodsByReferences.ReferenceOrder.Date AS ReferenceDocumentDateForPrintForms,
	|	MIN(GoodsIssueNoteGoodsByReferences.LineNumber) AS LineNumber
	|FROM
	|	Document.GoodsIssueNote.GoodsByReferences AS GoodsIssueNoteGoodsByReferences
	|		INNER JOIN Document.GoodsPickingPlacement AS GoodsPickingPlacement
	|		ON GoodsIssueNoteGoodsByReferences.Ref = GoodsPickingPlacement.ReferenceOrder
	|WHERE
	|	GoodsPickingPlacement.Ref IN(&ObjectsArray)
	|
	|GROUP BY
	|	GoodsPickingPlacement.Ref,
	|	GoodsIssueNoteGoodsByReferences.ReferenceOrder.Number,
	|	GoodsIssueNoteGoodsByReferences.ReferenceOrder.Date,
	|	PRESENTATION(GoodsIssueNoteGoodsByReferences.ReferenceOrder)
	|
	|ORDER BY
	|	Ref,
	|	LineNumber";
	Query.SetParameter("ObjectsArray", ObjectsArray);
	
	// You need to print the invoice number and date, but you may not have access to the invoices
	SetPrivilegedMode(True);
	
	Results = Query.ExecuteBatch();
	
	SetPrivilegedMode(False);
	
	SelectionByDocuments      = Results[0].Select();
	SelectionByTableParts = Results[1].Select(QueryResultIteration.ByGroups);
	SamplingByOrders   = Results[2].Select();
	
	DocumentAttributes = New Structure("Number, Date, Prefix, Presentation");
	
	Template = PrintManagement.PrintFormTemplate("Document.GoodsPickingPlacement.PF_MXL_WarehouseTask");
	
	HeaderArea_ 		  = Template.GetArea("Title");
	StorageArea_   = Template.GetArea("WarehouseExecutor");
	ScopeOfApplication_2	 	  = Template.GetArea("Basis");
	ScopeOfApplication_8 	  = Template.GetArea("ReferenceOrder");
	TransportTaskArea = Template.GetArea("TransportationJob");
	SubtitleArea 	  = Template.GetArea("Subtitle");
	
	TableHeaderAreaStart 	= Template.GetArea("TableHeader|BeginningOfTheLine");
	AreaTableRowStart 	= Template.GetArea("TableRow|BeginningOfTheLine");
	AreaBasementTableTop 	= Template.GetArea("TableFooter|BeginningOfTheLine");
	
	AreaTableHeaderCodeColumn 	= Template.GetArea("TableHeader|ColumnOfCodes");
	AreaTableRowCodeColumn 	= Template.GetArea("TableRow|ColumnOfCodes");
	AreaBasementTableColumnCodes 	= Template.GetArea("TableFooter|ColumnOfCodes");
	
	AreaTableHeaderCodeColumn.Parameters.NameOfCodeColumn = PresentationOfCodesColumn; 
	
	If Not OutputCodes Then
		ProductColumnArea_ = Template.Area("ProductColumn_");
		
		ProductColumnArea_.ColumnWidth = ProductColumnArea_.ColumnWidth  + Template.Area("ColumnOfCodes").ColumnWidth;
	EndIf;	
	
	AreaTableHeaderProductColumn 	= Template.GetArea("TableHeader|ProductColumn_");
	AreaTableRowProductColumn 	= Template.GetArea("TableRow|ProductColumn_");
	AreaBasementTableGoodsColumn 	= Template.GetArea("TableFooter|ProductColumn_");
	
	TableHeaderAreaEnd 	= Template.GetArea("TableHeader|EndOfRow");
	AreaTableRowEnd 	= Template.GetArea("TableRow|EndOfRow");
	AreaBasementTableEnd 	= Template.GetArea("TableFooter|EndOfRow");
	
	FirstDocument = True;
	
	While SelectionByDocuments.Next() Do
		
		If Not SelectionByTableParts.FindNext(New Structure("Ref",SelectionByDocuments.Ref)) Then
			Continue;
		EndIf;
			
		SamplingByTSLines = SelectionByTableParts.Select(QueryResultIteration.ByGroups);
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument = False;
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		DerivingBase = False;
		
		If SelectionByDocuments.OperationKind = Enums.OperationKindsOfGoodsPlacementPicking.Filter Then
			
			TitleText		 = NStr("vi = 'NHIỆM VỤ LẤY HÀNG HÓA RA';
									|ru = 'Задание на отбор товара';
									|en = 'Picking job'; fa = 'کار برداشت';
									|it = 'Task per selezione di merce';
									|pl = 'Zadanie doboru towaru';
									|tr = 'Ürün filtre görevi'", Common.DefaultLanguageCode());
			ZoneText			 = NStr("vi = 'Khu vực giao hàng:';
										|ru = 'Зона отгрузки:';
										|en = 'Outbound area:'; fa = 'ناحیه خروجی:';
										|it = 'Area di spedizione:';
										|pl = 'Strefa wysyłki:';
										|tr = 'Yükleme alanı:'", Common.DefaultLanguageCode());
			ZonePresentation	 = SelectionByDocuments.ShippingZonePresentation;
			WarehouseZone		 = SelectionByDocuments.WarehouseZonePresentation;
			OutputOrder_ = True;
			DerivingBase    = TypeOf(SelectionByDocuments.ReferenceOrder) = Type("DocumentRef.GoodsIssueNote");
			DisplaySubtitle = False;
			
		ElsIf SelectionByDocuments.OperationKind = Enums.OperationKindsOfGoodsPlacementPicking.Location Then
			
			TitleText = NStr("vi = 'NHIỆM VỤ XẾP VÀO HÀNG HÓA';
							|ru = 'Задание на размещение товара';
							|en = 'Put-away task'; fa = 'وظیفه جای‌گذاری';
							|it = 'Task per collocamento prodotti';
							|pl = 'Zadanie na rozmieszczenie towaru';
							|tr = 'Ürün yerleştirme görevi'", Common.DefaultLanguageCode());
			ZoneText = NStr("vi = 'Khu vực tiếp nhận:';
							|ru = 'Зона приемки:';
							|en = 'Inbound area:'; fa = 'ناحیه ورودی:';
							|it = 'Area di accettazione:';
							|pl = 'Stefa przyjęcia:';
							|tr = 'Boşaltma alanı:'", Common.DefaultLanguageCode());
			ZonePresentation = SelectionByDocuments.ReceivingAreaPresentation;
			WarehouseZone		= SelectionByDocuments.WarehouseZonePresentation;
			OutputOrder_ = False;
			DisplaySubtitle = False;
			
		ElsIf SelectionByDocuments.OperationKind = Enums.OperationKindsOfGoodsPlacementPicking.Move Then
			
			TitleText = NStr("vi = 'NHIỆM VỤ ĐIỀU CHUYỂN HÀNG HÓA';
							|ru = 'Задание на перемещение товара';
							|en = 'Intra-warehouse transfer task'; fa = 'وظیفه انتقال درون‌انباری';
							|it = 'Task per trasferimento merce';
							|pl = 'Zadanie na przemieszczenie towaru';
							|tr = 'Mal transferi görevi'", Common.DefaultLanguageCode());
			ZoneText = "";
			ZonePresentation = "";
			WarehouseZone	= "";
			OutputOrder_ = False;
			DisplaySubtitle = True;
						
		EndIf;
		
		FillPropertyValues(DocumentAttributes, SelectionByDocuments);
		
		HeaderArea_.Parameters.TitleText = TMCommonUseClientServer.GenerateDocumentTitle(DocumentAttributes, TitleText);
		
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, HeaderArea_, SelectionByDocuments.Ref);
		SpreadsheetDocument.Put(HeaderArea_);
		
		StorageArea_.Parameters.PerformerPresentation	= PersonsTM.IndividualShortName(SelectionByDocuments.Performer, SelectionByDocuments.Date);
		StorageArea_.Parameters.WarehousePresentation		= WarehousesServer.GetWarehousePresentation(SelectionByDocuments.WarehousePresentation,SelectionByDocuments.PremisePresentation);
		StorageArea_.Parameters.ZoneText 				= ZoneText;
		StorageArea_.Parameters.ZonePresentation 		= ZonePresentation;
		
		If ValueIsFilled(WarehouseZone) Then
			StorageArea_.Parameters.TextOfWorkingSection = NStr("vi = 'Khu vực làm việc:';
																|ru = 'Рабочий участок:';
																|en = 'Warehouse area:'; fa = 'Warehouse area:';
																|it = 'Area di lavoro:';
																|pl = 'Obszar roboczy:';
																|tr = 'Çalışma alanı:'", Common.DefaultLanguageCode());
			StorageArea_.Parameters.WarehouseZonePresentation = WarehouseZone;			
		Else
			StorageArea_.Parameters.TextOfWorkingSection = "";
			StorageArea_.Parameters.WarehouseZonePresentation = "";			
		EndIf;
		
		SpreadsheetDocument.Put(StorageArea_);
		
		If DerivingBase Then
			
			Counter = 0;
			PresentationOfGrounds = "";
			FirstOrder = True;
			DocumentAttributes = New Structure("Date, Number, Prefix, Presentation");
			
			While SamplingByOrders.FindNext(New Structure("Ref", SelectionByDocuments.Ref)) Do
				
				DocumentAttributes.Date          = SamplingByOrders.ReferenceDocumentDateForPrintForms;
				DocumentAttributes.Number         = SamplingByOrders.BaseDocumentNumber;
				DocumentAttributes.Prefix       = "";
				DocumentAttributes.Presentation = SamplingByOrders.BasisPresentation;
				
 				BaseDocumentPresentation = TMCommonUseClientServer.GenerateDocumentTitle(DocumentAttributes);
				
				If Not FirstOrder Then
					PresentationOfGrounds = PresentationOfGrounds + ", ";		
				EndIf;
				
				FirstOrder = False;
				
				PresentationOfGrounds = PresentationOfGrounds + BaseDocumentPresentation;
				
				Counter = Counter + 1;
				
			EndDo;
			
			GroundsHeader = "";
			If Counter > 1 Then 
				GroundsHeader = NStr("vi = 'Cơ sở:';
									|ru = 'Основания:';
									|en = 'Base documents:'; fa = 'Base documents:';
									|it = 'Causali:';
									|pl = 'Podstawy:';
									|tr = 'Temel belgeler:'", Common.DefaultLanguageCode());
			Else
				GroundsHeader = NStr("vi = 'Cơ sở:';
									|ru = 'Основание:';
									|en = 'Base document:'; fa = 'سند مبنا:';
									|it = 'Causale:';
									|pl = 'Podstawa:';
									|tr = 'Temel belge:'", Common.DefaultLanguageCode());
			EndIf;
			
			ScopeOfApplication_2.Parameters.Basis1Presentation = PresentationOfGrounds;
			ScopeOfApplication_2.Parameters.GroundsHeader = GroundsHeader;
			
			SpreadsheetDocument.Put(ScopeOfApplication_2);
			
		EndIf;
		
		If OutputOrder_ Then
			DocumentAttributes.Date          = SelectionByDocuments.Order_Date;
			DocumentAttributes.Number         = SelectionByDocuments.OrderNumber__;
			DocumentAttributes.Prefix       = "";
			DocumentAttributes.Presentation = SelectionByDocuments.ReferenceOrderPresentation;
			
			ScopeOfApplication_8.Parameters.ReferenceOrderPresentation	= TMCommonUseClientServer.GenerateDocumentTitle(DocumentAttributes);
			SpreadsheetDocument.Put(ScopeOfApplication_8);
		EndIf;
		
		If SelectionByDocuments.ShipmentUnderTransportationJob Then
			DocumentAttributes.Date          = SelectionByDocuments.TransportationTaskDate;
			DocumentAttributes.Number         = SelectionByDocuments.TransportationTaskNumber;
			DocumentAttributes.Prefix       = "";
			DocumentAttributes.Presentation = SelectionByDocuments.TransportationJobPresentation;
			                                    
			TransportTaskArea.Parameters.TransportationJobPresentation	= TMCommonUseClientServer.GenerateDocumentTitle(DocumentAttributes);
			TransportTaskArea.Parameters.DeliveryProcedure = SelectionByDocuments.DeliveryProcedure;
			SpreadsheetDocument.Put(TransportTaskArea);
		EndIf;
		
		Label = Undefined;
		
		While SamplingByTSLines.Next() Do
			
			If Label <> SamplingByTSLines.Label Then
				If DisplaySubtitle Then
					
					If SamplingByTSLines.Label = 0 Then
						HeadlineText = NStr("vi = 'Hàng hóa cần lấy ra';
											|ru = 'Товары к отбору';
											|en = 'Pick list'; fa = 'فهرست برداشت';
											|it = 'Merci da selezionare';
											|pl = 'Wiersze pozycji do doboru';
											|tr = 'Filtrelenecek ürünler'", Common.DefaultLanguageCode());
					Else
						HeadlineText = NStr("vi = 'Hàng hóa cần xếp vào';
											|ru = 'Товары к размещению';
											|en = 'Put-away list'; fa = 'فهرست جای‌گذاری';
											|it = 'Merci da collocare';
											|pl = 'Wiersze pozycji do rozmieszczenia';
											|tr = 'Yerleştirilecek ürünler'", Common.DefaultLanguageCode());
					EndIf;
					
					If Label <> Undefined Then
						SpreadsheetDocument.Put(AreaBasementTableTop);
						If OutputCodes Then
							SpreadsheetDocument.Join(AreaBasementTableColumnCodes);
						EndIf;
						SpreadsheetDocument.Join(AreaBasementTableGoodsColumn);
						SpreadsheetDocument.Join(AreaBasementTableEnd);
					EndIf;
				
					SubtitleArea.Parameters.HeadlineText = HeadlineText;
					SpreadsheetDocument.Put(SubtitleArea);
				EndIf;
				
				SpreadsheetDocument.Put(TableHeaderAreaStart);
				If OutputCodes Then
					SpreadsheetDocument.Join(AreaTableHeaderCodeColumn);
				EndIf;
				SpreadsheetDocument.Join(AreaTableHeaderProductColumn);
				SpreadsheetDocument.Join(TableHeaderAreaEnd);
			EndIf;
			
			AreaTableRowStart.Parameters.Fill(SamplingByTSLines);
			SpreadsheetDocument.Put(AreaTableRowStart);
			
			If OutputCodes Then
				AreaTableRowCodeColumn.Parameters.SKU = SamplingByTSLines[NameOfCodeColumn];
				SpreadsheetDocument.Join(AreaTableRowCodeColumn);
			EndIf;
				
			AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
			AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
	
			AreaTableRowProductColumn.Parameters.OwnGoods = ProductsClientServer.PresentationOfProductsForPrinting(
				SamplingByTSLines.ProductsPresentation,
				SamplingByTSLines.CharacteristicPresentation,
				, // Package
				SamplingByTSLines.SeriesPresentation,
				AdditionalParametersProductPresentation);
			
			SpreadsheetDocument.Join(AreaTableRowProductColumn);
			
			AreaTableRowEnd.Parameters.Fill(SamplingByTSLines);
			SpreadsheetDocument.Join(AreaTableRowEnd);	
			
			Label = SamplingByTSLines.Label;
			
		EndDo;
		
		SpreadsheetDocument.Put(AreaBasementTableTop);
		If OutputCodes Then
			SpreadsheetDocument.Join(AreaBasementTableColumnCodes);
		EndIf;
		SpreadsheetDocument.Join(AreaBasementTableGoodsColumn);
		SpreadsheetDocument.Join(AreaBasementTableEnd);
		
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, SelectionByDocuments.Ref);
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;
	
	Return SpreadsheetDocument;	
EndFunction

// A function to Get the data to print labels
//
// Parameters:
//  DocumentsArray - Array of DocumentRef.GoodsPickingPlacement
//
// Returns:
//  String - The address of the temporary storage where the print data is placed.
//
Function LabelPrintingData(DocumentsArray) Export
	
	SetPrivilegedMode(True);
	
	PricingDate = TMCommonUse.GetMaximumDateOfDocuments(DocumentsArray);
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	SelectionProductPlacementProductsSelection.Ref AS Ref,
	|	SelectionProductPlacementProductsSelection.Products AS Products,
	|	SelectionProductPlacementProductsSelection.Characteristic AS Characteristic,
	|	SelectionProductPlacementProductsSelection.Package AS Package,
	|	SelectionProductPlacementProductsSelection.Series AS Series,
	|	SUM(SelectionProductPlacementProductsSelection.NumberOfPackages) AS NumberOfPackages,
	|	MIN(SelectionProductPlacementProductsSelection.LineNumber) AS Order,
	|	SelectionProductPlacementProductsSelection.Ref.OperationKind AS OperationKind
	|INTO GoodsFilter
	|FROM
	|	Document.GoodsPickingPlacement.GoodsFilter AS SelectionProductPlacementProductsSelection
	|WHERE
	|	SelectionProductPlacementProductsSelection.Ref IN(&DocumentsArray)
	|
	|GROUP BY 
	|	SelectionProductPlacementProductsSelection.Package,
	|	SelectionProductPlacementProductsSelection.Ref,
	|	SelectionProductPlacementProductsSelection.Products,
	|	SelectionProductPlacementProductsSelection.Characteristic,
	|	SelectionProductPlacementProductsSelection.Series,
	|	SelectionProductPlacementProductsSelection.Ref.OperationKind
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SelectionProductPlacementProductsPlacement.Ref,
	|	SelectionProductPlacementProductsPlacement.Products,
	|	SelectionProductPlacementProductsPlacement.Characteristic,
	|	SelectionProductPlacementProductsPlacement.Package,
	|	SelectionProductPlacementProductsPlacement.Series,
	|	SUM(SelectionProductPlacementProductsPlacement.NumberOfPackages) AS NumberOfPackages,
	|	MIN(SelectionProductPlacementProductsPlacement.LineNumber) AS Order,
	|	SelectionProductPlacementProductsPlacement.Ref.OperationKind
	|INTO GoodsPlacement
	|FROM
	|	Document.GoodsPickingPlacement.GoodsPlacement AS SelectionProductPlacementProductsPlacement
	|WHERE
	|	SelectionProductPlacementProductsPlacement.Ref IN(&DocumentsArray)
	|
	|GROUP BY
	|	SelectionProductPlacementProductsPlacement.Package,
	|	SelectionProductPlacementProductsPlacement.Ref,
	|	SelectionProductPlacementProductsPlacement.Products,
	|	SelectionProductPlacementProductsPlacement.Characteristic,
	|	SelectionProductPlacementProductsPlacement.Series,
	|	SelectionProductPlacementProductsPlacement.Ref.OperationKind
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsFilter.Ref,
	|	GoodsFilter.Products,
	|	GoodsFilter.Characteristic,
	|	GoodsFilter.Series,
	|	GoodsFilter.Package
	|INTO MovedWithoutRepackaging
	|FROM
	|	GoodsFilter AS GoodsFilter
	|		INNER JOIN GoodsPlacement AS GoodsPlacement
	|		ON GoodsFilter.Ref = GoodsPlacement.Ref
	|			AND GoodsFilter.Products = GoodsPlacement.Products
	|			AND GoodsFilter.Characteristic = GoodsPlacement.Characteristic
	|			AND GoodsFilter.Package = GoodsPlacement.Package
	|			AND GoodsFilter.Series = GoodsPlacement.Series
	|
	|GROUP BY
	|	GoodsFilter.Ref,
	|	GoodsFilter.Products,
	|	GoodsFilter.Characteristic,
	|	GoodsFilter.Series,
	|	GoodsFilter.Package
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsFilter.Products AS Products,
	|	GoodsFilter.Characteristic AS Characteristic,
	|	GoodsFilter.Order AS Order,
	|	GoodsFilter.Package,
	|	GoodsFilter.Series,
	|	GoodsFilter.NumberOfPackages AS NumberOfPackages,
	|	GoodsFilter.NumberOfPackages AS Count,
	|	NULL AS Field1
	|FROM
	|	GoodsFilter AS GoodsFilter
	|WHERE
	|	GoodsFilter.OperationKind = VALUE(Enum.OperationKindsOfGoodsPlacementPicking.Filter)
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsPlacement.Products,
	|	GoodsPlacement.Characteristic,
	|	GoodsPlacement.Order,
	|	GoodsPlacement.Package,
	|	GoodsPlacement.Series,
	|	GoodsPlacement.NumberOfPackages,
	|	GoodsPlacement.NumberOfPackages,
	|	MovedWithoutRepackaging.Ref
	|FROM
	|	GoodsPlacement AS GoodsPlacement
	|		LEFT JOIN MovedWithoutRepackaging AS MovedWithoutRepackaging
	|		ON GoodsPlacement.Ref = MovedWithoutRepackaging.Ref
	|			AND GoodsPlacement.Products = MovedWithoutRepackaging.Products
	|			AND GoodsPlacement.Package = MovedWithoutRepackaging.Package
	|			AND GoodsPlacement.Characteristic = MovedWithoutRepackaging.Characteristic
	|WHERE
	|	CASE ISNULL(MovedWithoutRepackaging.Ref, 2)
	|			WHEN 2
	|				THEN 2
	|			ELSE 0
	|		END + CASE GoodsPlacement.OperationKind
	|			WHEN VALUE(Enum.OperationKindsOfGoodsPlacementPicking.Location)
	|				THEN 2
	|			ELSE 0
	|		END > 1
	|
	|ORDER BY
	|	Order";
	
	Query.SetParameter("DocumentsArray", DocumentsArray);
	
	Result = Query.Execute();
	
	// Preparation of the action structure for processing the printing of price tags and labels
	StructureOfActions = New Structure;
	StructureOfActions.Insert("ShowQuantityColumnInDocument", True);
	StructureOfActions.Insert("SetPrintModeFromDocument");
	StructureOfActions.Insert("SetMode", "PrintLabels");
	StructureOfActions.Insert("FillInTheNumberOfLabelsForTheDocument");
	StructureOfActions.Insert("FillInTheGoodsTable");
	
	// Preparation of data for filling in the tabular part of the processing of printing price tags and labels.
	ResultingStructure = New Structure;
	ResultingStructure.Insert("Goods", Result.Unload());
	ResultingStructure.Insert("StructureOfActions", StructureOfActions);
	ResultingStructure.Insert("Date",              PricingDate);
	
	Return PutToTempStorage(ResultingStructure);
	
EndFunction

#EndRegion

#EndIf

#EndRegion

#EndIf
