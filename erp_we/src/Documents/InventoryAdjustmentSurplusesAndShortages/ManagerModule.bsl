#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("SerialAccounting");
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
//  Structure - a collection of elements - tables of values - data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.InventoryAdjustmentSurplusesAndShortages") Then
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
		
		QueryTextTableGoodsForRegistrationOfSurplusesAndShortages(Query, QueryTexts, Registers);
		QueryTextTableProductStock(Query, QueryTexts, Registers);
		RequestTextTableItemsToBeProcessedForSurplusesAndShortages(Query, QueryTexts, Registers);
		QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers);
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	
	AttributesNames = "Warehouse,Premise,Date";
	Return AttributesNames;
	
EndFunction

// Returns parameters for specifying series for the products specified in the document.
//
// Parameters:
//	Object - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
// Returns:
// 	See ProductsClientServer.SeriesSpecificationParameters.
//
Function SeriesSpecificationParameters(Object) Export
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	SeriesSpecificationParameters.FullObjectName = "Document.InventoryAdjustmentSurplusesAndShortages";
	
	WarehouseSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Warehouse, False);
	
	SeriesSpecificationParameters.UseItemsBatch  = WarehouseSeriesParameters.UseItemsBatch;
	SeriesSpecificationParameters.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;
	
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.SurplusesRecord);
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.ShortageRecord);
	SeriesSpecificationParameters.UseBinLocationWarehousing = True;
	SeriesSpecificationParameters.LinkFields.Add("Package");
	SeriesSpecificationParameters.FieldNameQuantity = "NumberOfPackages";	
	
	SeriesSpecificationParameters.ThisIsAnInvoice = True;
	SeriesSpecificationParameters.TSSeriesName = "Goods";
	SeriesSpecificationParameters.FieldNameRoom = "Premise";
	SeriesSpecificationParameters.Date = Object.Date;
	SeriesSpecificationParameters.SeriesOnlyForCostPrice = False;
	
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
	|	Goods.Characteristic AS Characteristic,
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
	|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind,
	|	Goods.Characteristic AS Characteristic,
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
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
	|			THEN CASE
	|					WHEN Goods.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 13
	|					ELSE 14
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment
	|			THEN CASE
	|					WHEN Goods.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 9
	|					ELSE 10
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningPicking
	|			THEN CASE
	|					WHEN BatchAccountingPolicies.BatchAccountingPolicy.BatchesAccountingByFEFO
	|						THEN CASE
	|								WHEN Goods.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|									THEN 5
	|								ELSE 6
	|							END
	|					ELSE CASE
	|							WHEN Goods.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|								THEN 7
	|							ELSE 8
	|						END
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyByPickingResult
	|				AND BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries
	|			THEN CASE
	|					WHEN Goods.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 3
	|					ELSE 4
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
	
	Return QueryText;
	
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
EndProcedure

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
EndProcedure

// Initializes parameters that serve the selection of assignments in document forms.
//
//  Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.RecordsInWarehouseRegisters = "TRUE";
	
	// Needs for goods in stock.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.Goods.Purpose");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	
	DescriptionOfColumns.DataPaths.Products     = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse            = "Object.Warehouse";
	
	Return FormTemplate;
	
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

#EndRegion

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure
// End StandardSubsystems.ObjectsVersioning

#EndRegion

#Region Private

#Region Posting

// Used in information security update mechanisms
//
// Parameters:
//  RegisterName	 - String	 - register name.
//
// Returns:
//  Map -
//
Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	InventoryAdjustmentSurplusesAndShortages.Date AS Period,
	|	InventoryAdjustmentSurplusesAndShortages.Warehouse AS Warehouse,
	|	InventoryAdjustmentSurplusesAndShortages.Premise AS Premise
	|FROM
	|	Document.InventoryAdjustmentSurplusesAndShortages AS InventoryAdjustmentSurplusesAndShortages
	|WHERE
	|	InventoryAdjustmentSurplusesAndShortages.Ref = &Ref";
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	Query.SetParameter("Period",      Attributes.Period);
	Query.SetParameter("Warehouse", Attributes.Warehouse);
	Query.SetParameter("Premise", Attributes.Premise);
	
EndProcedure

Function QueryTextTableGoodsForRegistrationOfSurplusesAndShortages(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsForRegistrationOfSurplusesAndShortages";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTProducts_1", QueryTexts) Then
		QueryTextTTProducts_1(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period AS Period,
	|	&Warehouse AS Warehouse,
	|	&Premise AS Premise,
	|	TTProducts_1.Products AS Products,
	|	TTProducts_1.Characteristic AS Characteristic,
	|	TTProducts_1.Purpose AS Purpose,
	|	CASE
	|		WHEN TTProducts_1.BatchesIndicationStatus = 14
	|			THEN TTProducts_1.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	TTProducts_1.Count AS ToCertificateRegistration
	|FROM
	|	TTProducts_1 AS TTProducts_1
	|WHERE
	|	TTProducts_1.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordSurplus)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense),
	|	&Period,
	|	&Warehouse,
	|	&Premise,
	|	TTProducts_1.Products,
	|	TTProducts_1.Characteristic,
	|	TTProducts_1.Purpose,
	|	CASE
	|		WHEN TTProducts_1.BatchesIndicationStatus = 14
	|			THEN TTProducts_1.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	TTProducts_1.Count
	|FROM
	|	TTProducts_1 AS TTProducts_1
	|WHERE
	|	TTProducts_1.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordShortage)";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsBatchMovement";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTProducts_1", QueryTexts) Then
		QueryTextTTProducts_1(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	SeriesTable.Products AS Products,
	|	SeriesTable.Characteristic AS Characteristic,
	|	SeriesTable.Purpose AS Purpose,
	|	SeriesTable.Series AS Series,
	|	SeriesTable.Count AS Count,
	|	&Ref AS Document,
	|	&Period AS Period,
	|	&Ref AS Recorder,
	|	&Warehouse AS Sender,
	|	&Premise AS WareroomOfSender,
	|	UNDEFINED AS Recipient,
	|	UNDEFINED AS WareroomOfRecipient,
	|	VALUE(Enum.WarehouseTransactions.SurplusesRecord) AS WarehouseOperation,
	|	FALSE AS ThisIsWarehouseRecord
	|FROM
	|	TTProducts_1 AS SeriesTable
	|WHERE
	|	SeriesTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|	AND SeriesTable.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordSurplus)
	|
	|UNION ALL
	|
	|SELECT
	|	SeriesTable.Products,
	|	SeriesTable.Characteristic,
	|	SeriesTable.Purpose,
	|	SeriesTable.Series,
	|	-SeriesTable.Count,
	|	&Ref,
	|	&Period,
	|	&Ref,
	|	UNDEFINED,
	|	UNDEFINED,
	|	&Warehouse,
	|	&Premise,
	|	VALUE(Enum.WarehouseTransactions.ShortageRecord),
	|	FALSE
	|FROM
	|	TTProducts_1 AS SeriesTable
	|WHERE
	|	SeriesTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|	AND SeriesTable.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordShortage)";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableProductStock(Query, QueryTexts, Registers)
	
	RegisterName = "ProductStock";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTProducts_1", QueryTexts) Then
		QueryTextTTProducts_1(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	TTProducts_1.Products AS Products,
	|	TTProducts_1.Characteristic AS Characteristic,
	|	TTProducts_1.Purpose AS Purpose,
	|	CASE
	|		WHEN TTProducts_1.BatchesIndicationStatus IN (4, 6, 8, 10, 14)
	|			THEN TTProducts_1.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	TTProducts_1.Count AS InStock,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Period AS Period,
	|	&Warehouse AS Warehouse,
	|	&Premise AS Premise
	|FROM
	|	TTProducts_1 AS TTProducts_1
	|WHERE
	|	TTProducts_1.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordShortage)
	|
	|UNION ALL
	|
	|SELECT
	|	TTProducts_1.Products,
	|	TTProducts_1.Characteristic,
	|	TTProducts_1.Purpose,
	|	CASE
	|		WHEN TTProducts_1.BatchesIndicationStatus IN (4, 6, 8, 10, 14)
	|			THEN TTProducts_1.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END,
	|	TTProducts_1.Count,
	|	VALUE(AccumulationRecordType.Receipt),
	|	&Period,
	|	&Warehouse,
	|	&Premise
	|FROM
	|	TTProducts_1 AS TTProducts_1
	|WHERE
	|	TTProducts_1.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordSurplus)";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function RequestTextTableItemsToBeProcessedForSurplusesAndShortages(Query, QueryTexts, Registers)
	
	RegisterName = "CargoItemsForRecordingSurplusesAndShortages";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 	
	"SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Period AS Period,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	&Warehouse AS Warehouse,
	|	&Premise AS Premise,
	|	GoodsTable.Purpose AS Purpose,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.NumberOfPackages AS Count,
	|	GoodsTable.Package AS CargoItem
	|FROM
	|	Document.InventoryAdjustmentSurplusesAndShortages.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordSurplus)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt),
	|	&Period,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	&Warehouse,
	|	&Premise,
	|	GoodsTable.Purpose,
	|	GoodsTable.Series,
	|	GoodsTable.NumberOfPackages,
	|	GoodsTable.Package
	|FROM
	|	Document.InventoryAdjustmentSurplusesAndShortages.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordShortage)";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTTProducts_1(Query, QueryTexts)
	
	RegisterName = "TTProducts_1";
			
	QueryText = 
	"SELECT
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.Purpose,
	|	Table.Series,
	|	Table.BatchesIndicationStatus,
	|	SUM(GoodsTable.Count) AS Count,
	|	GoodsTable.OperationKind
	|INTO TTProducts_1
	|FROM
	|	(SELECT
	|		GoodsTable.Ref AS Ref,
	|		GoodsTable.Products AS Products,
	|		GoodsTable.Characteristic AS Characteristic,
	|		GoodsTable.Purpose AS Purpose,
	|		GoodsTable.Series AS Series,
	|		MAX(GoodsTable.Package) AS Package,
	|		GoodsTable.BatchesIndicationStatus AS BatchesIndicationStatus,
	|		GoodsTable.OperationKind AS OperationKind
	|	FROM
	|		Document.InventoryAdjustmentSurplusesAndShortages.Goods AS GoodsTable
	|	WHERE
	|		GoodsTable.Ref = &Ref
	|	
	|	GROUP BY
	|		GoodsTable.Ref,
	|		GoodsTable.Products,
	|		GoodsTable.Characteristic,
	|		GoodsTable.Purpose,
	|		GoodsTable.Series,
	|		GoodsTable.BatchesIndicationStatus,
	|		GoodsTable.OperationKind) AS Table
	|		INNER JOIN Document.InventoryAdjustmentSurplusesAndShortages.Goods AS GoodsTable
	|		ON Table.Ref = GoodsTable.Ref
	|			AND Table.Products = GoodsTable.Products
	|			AND Table.Characteristic = GoodsTable.Characteristic
	|			AND Table.Series = GoodsTable.Series
	|			AND Table.Purpose = GoodsTable.Purpose
	|			AND Table.Package = GoodsTable.Package
	|			AND Table.OperationKind = GoodsTable.OperationKind
	|
	|GROUP BY
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.Purpose,
	|	Table.Series,
	|	Table.BatchesIndicationStatus,
	|	GoodsTable.OperationKind";
		
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure ReflectStockDistribution(Query, QueryTexts, Registers)
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref               AS Ref,
		|	TabPart.Ref.Date          AS Period,
		|	TabPart.Products         AS Products,
		|	TabPart.Characteristic       AS Characteristic,
		|	TabPart.Ref.Warehouse         AS Warehouse,
		|	TabPart.Purpose           AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	TabPart.Count           AS Count,
		|	UNDEFINED                  AS PlannedConsumptionOfDistributedStock,
		|	FALSE                          AS ControlOfFreeResidue
		|FROM
		|	Document.InventoryAdjustmentSurplusesAndShortages.Goods AS TabPart
		|WHERE
		|	TabPart.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordShortage)
		|		AND ISNULL(TabPart.Package.PackageType, UNDEFINED) <> VALUE(Enum.TypesOfItemsPackages.CargoItem)";
	
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, False);
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Ref.Warehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking,
		|	DATETIME(1, 1, 1) AS QualityConfirmationDate,
		|	TabPart.Count AS Count,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule
		|FROM
		|	Document.InventoryAdjustmentSurplusesAndShortages.Goods AS TabPart
		|WHERE
		|	TabPart.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordSurplus)
		|	AND ISNULL(TabPart.Package.PackageType,
		|		UNDEFINED) <> VALUE(Enum.TypesOfItemsPackages.CargoItem)";
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, False);
	
	TextProductLocations =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Purpose AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	TabPart.Series AS Series,
		|	TabPart.OperationKind AS OperationKind,
		|	MAX(TabPart.Package) AS Package
		|INTO ProductLocations
		|FROM
		|	Document.InventoryAdjustmentSurplusesAndShortages.Goods AS TabPart
		|WHERE
		|	TabPart.Ref IN(&Ref)
		|		AND TabPart.Package.PackageType = VALUE(Enum.TypesOfItemsPackages.CargoItem)
		|GROUP BY
		|	TabPart.Ref,
		|	TabPart.Products,
		|	TabPart.Characteristic,
		|	TabPart.Purpose,
		|	TabPart.Series,
		|	TabPart.OperationKind
		|INDEX BY
		|	Ref, Products, Characteristic, Purpose, Series, OperationKind, Package";
		
	TemporaryTableTemplateTexts = New Structure();
	TemporaryTableTemplateTexts.Insert("ProductLocations", TextProductLocations);
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Ref.Warehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	TabPart.Count AS Count,
		|	UNDEFINED AS PlannedConsumptionOfDistributedStock,
		|	FALSE AS ControlOfFreeResidue
		|FROM
		|	Document.InventoryAdjustmentSurplusesAndShortages.Goods AS TabPart
		|		INNER JOIN ProductLocations AS ProductLocations
		|		ON TabPart.Ref = ProductLocations.Ref
		|		AND TabPart.Products = ProductLocations.Products
		|		AND TabPart.Characteristic = ProductLocations.Characteristic
		|		AND TabPart.Purpose = ProductLocations.Purpose
		|		AND TabPart.Series = ProductLocations.Series
		|		AND TabPart.Package = ProductLocations.Package
		|		AND TabPart.OperationKind = ProductLocations.OperationKind
		|WHERE
		|	TabPart.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordShortage)
		|	AND TabPart.Package.PackageType = VALUE(Enum.TypesOfItemsPackages.CargoItem)";
		
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, False,
		TemporaryTableTemplateTexts);
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Ref.Warehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking,
		|	DATETIME(1, 1, 1) AS QualityConfirmationDate,
		|	TabPart.Count AS Count,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule
		|FROM
		|	Document.InventoryAdjustmentSurplusesAndShortages.Goods AS TabPart
		|		INNER JOIN ProductLocations AS ProductLocations
		|		ON TabPart.Ref = ProductLocations.Ref
		|		AND TabPart.Products = ProductLocations.Products
		|		AND TabPart.Characteristic = ProductLocations.Characteristic
		|		AND TabPart.Purpose = ProductLocations.Purpose
		|		AND TabPart.Series = ProductLocations.Series
		|		AND TabPart.Package = ProductLocations.Package
		|		AND TabPart.OperationKind = ProductLocations.OperationKind
		|WHERE
		|	TabPart.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordSurplus)
		|	AND TabPart.Package.PackageType = VALUE(Enum.TypesOfItemsPackages.CargoItem)";
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, False,
		TemporaryTableTemplateTexts);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
