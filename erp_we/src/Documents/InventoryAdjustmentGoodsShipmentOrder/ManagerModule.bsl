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
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("SerialAccounting");
	
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
	
	If TypeOf(Document) = Type("DocumentObject.InventoryAdjustmentGoodsShipmentOrder") Then
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
		QueryTextTableCargoItemsForRecordingSurplusesAndShortages(Query, QueryTexts, Registers);
		QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers);
		QueryTextTableProductStock(Query, QueryTexts, Registers);
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
	PickUpProducts(Query, QueryTexts, Registers);
	
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
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
EndProcedure

// Adds a command to create a document "adjustment for a product order".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTable, Undefined - generated commands for output to the submenu.
//
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.InventoryAdjustmentGoodsShipmentOrder) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.InventoryAdjustmentGoodsShipmentOrder.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.InventoryAdjustmentGoodsShipmentOrder);
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

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

EndProcedure

#EndIf

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
//  Object	 - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
// Returns:
//  See ProductsClientServer.SeriesSpecificationParameters.
//
Function SeriesSpecificationParameters(Object) Export
	
	#If Not MobileStandaloneServer Then
		SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
		
		WarehouseSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Warehouse, False);
	#Else
		SeriesSpecificationParameters = MobileWarehouseKeeperWorkspace.ItemClientServerSerialSpecificationParameters();
		
		WarehouseSeriesParameters = MobileWarehouseKeeperWorkspace.UseOfSeriesInStock(Object.Warehouse, False);
	#EndIf
	
	SeriesSpecificationParameters.FullObjectName = "Document.InventoryAdjustmentGoodsShipmentOrder";
	
	SeriesSpecificationParameters.UseItemsBatch  = WarehouseSeriesParameters.UseItemsBatch;
	SeriesSpecificationParameters.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;
	
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.ShipmentControl);
	SeriesSpecificationParameters.UseBinLocationWarehousing = True;
	SeriesSpecificationParameters.LinkFields.Add("Package");
	SeriesSpecificationParameters.FieldNameQuantity = "NumberOfPackages";	
	
	SeriesSpecificationParameters.ItSWarrant = True;
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

#If Not MobileStandaloneServer Then

#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text = 
	"SELECT
	|	HeaderData_.Date AS Period,
	|	HeaderData_.Warehouse AS Warehouse,
	|	HeaderData_.WarehouseDocument AS WarehouseDocument,
	|	HeaderData_.RecipientNote AS RecipientNote,
	|	HeaderData_.Premise AS Premise,
	|	HeaderData_.ShippingZone AS ShippingZone
	|FROM
	|	Document.InventoryAdjustmentGoodsShipmentOrder AS HeaderData_
	|WHERE
	|	HeaderData_.Ref = &Ref";
	
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	Query.SetParameter("Period",                       Attributes.Period);
	Query.SetParameter("Warehouse",                        Attributes.Warehouse);
	Query.SetParameter("WarehouseDocument",                        Attributes.WarehouseDocument);
	Query.SetParameter("RecipientNote",              Attributes.RecipientNote);
	Query.SetParameter("Premise",                    Attributes.Premise);
	Query.SetParameter("ShippingZone",                 Attributes.ShippingZone);
	
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
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Period AS Period,
	|	&Warehouse AS Warehouse,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	CASE
	|		WHEN ISNULL(GoodsTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN GoodsTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END AS Purpose,
	|	CASE
	|		WHEN GoodsTable.ThisIsSeriesAtCostPrice
	|			THEN GoodsTable.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	GoodsTable.Count AS ToCertificateRegistration
	|FROM
	|	TTProducts_1 AS GoodsTable
	|WHERE
	|	GoodsTable.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordShortage)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt),
	|	&Period,
	|	&Warehouse,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	CASE
	|		WHEN ISNULL(GoodsTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN GoodsTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END,
	|	CASE
	|		WHEN GoodsTable.ThisIsSeriesAtCostPrice
	|			THEN GoodsTable.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END,
	|	GoodsTable.Count
	|FROM
	|	TTProducts_1 AS GoodsTable
	|WHERE
	|	GoodsTable.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordSurplus)";
	
	QueryTexts.Add(QueryText, RegisterName);

	Return QueryText;
	
EndFunction

Function QueryTextTableCargoItemsForRecordingSurplusesAndShortages(Query, QueryTexts, Registers)
	
	RegisterName = "CargoItemsForRecordingSurplusesAndShortages";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTGoodsPlacesBalances", QueryTexts) Then
		QueryTextTTProductLocationsBalance(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTCommodityPlacesToReflectSurplusShortages", QueryTexts) Then
		WarehousesServer.QueryTextTTCargoItemsForRecordingSurplusesAndShortages(QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period AS Period,
	|	&Warehouse AS Warehouse,
	|	&Premise AS Premise,
	|	NestedQuery.Products AS Products,
	|	NestedQuery.Characteristic AS Characteristic,
	|	NestedQuery.Purpose AS Purpose,
	|	NestedQuery.Series AS Series,
	|	NestedQuery.Package AS CargoItem,
	|	SUM(NestedQuery.Count) AS Count
	|FROM
	|	(SELECT
	|		DiscrepanciesInProductLocations.Products AS Products,
	|		DiscrepanciesInProductLocations.Characteristic AS Characteristic,
	|		DiscrepanciesInProductLocations.Purpose AS Purpose,
	|		DiscrepanciesInProductLocations.Series AS Series,
	|		DiscrepanciesInProductLocations.CargoItem AS Package,
	|		DiscrepanciesInProductLocations.CountBalance AS Count
	|	FROM
	|		TTGoodsPlacesBalances AS DiscrepanciesInProductLocations
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TTCommodityPlacesToReflectSurplusShortages.Products,
	|		TTCommodityPlacesToReflectSurplusShortages.Characteristic,
	|		TTCommodityPlacesToReflectSurplusShortages.Purpose,
	|		TTCommodityPlacesToReflectSurplusShortages.Series,
	|		TTCommodityPlacesToReflectSurplusShortages.Package,
	|		CASE
	|			WHEN TTCommodityPlacesToReflectSurplusShortages.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordSurplus)
	|				THEN -TTCommodityPlacesToReflectSurplusShortages.NumberOfPackages
	|			ELSE TTCommodityPlacesToReflectSurplusShortages.NumberOfPackages
	|		END
	|	FROM
	|		TTCommodityPlacesToReflectSurplusShortages AS TTCommodityPlacesToReflectSurplusShortages) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	NestedQuery.Purpose,
	|	NestedQuery.Series,
	|	NestedQuery.Package
	|
	|HAVING
	|	SUM(NestedQuery.Count) <> 0";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure PickUpProducts(Query, QueryTexts, Registers)
	
	QueryTextDocument_ =
	// We fix the shortage of selection
	"SELECT
	|	GoodsTable.Ref              AS Ref,
	|	GoodsTable.Ref.Date         AS Date,
	|	GoodsTable.Ref.WarehouseDocument        AS ReferenceOrder,
	|	UNDEFINED                      AS Cell,
	|	GoodsTable.Products        AS Products,
	|	GoodsTable.Characteristic      AS Characteristic,
	|	GoodsTable.Purpose          AS Purpose,
	|	GoodsTable.Series               AS Series,
	|	GoodsTable.Package            AS Package,
	|	-GoodsTable.Count         AS Count,
	|	-GoodsTable.NumberOfPackages AS NumberOfPackages,
	|	GoodsTable.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TRUE                            AS Picked,
	|	TRUE                            AS IsFilter,
	|	FALSE                              AS ThisIsReflectionOfCells
	|FROM
	|	Document.InventoryAdjustmentGoodsShipmentOrder.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN(&Ref)
	|	AND GoodsTable.OperationKind IN (
	|		VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordShortage),
	|		VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.MoveToOtherNote),
	|		VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.LeaveInShippingArea)
	|	)
	|
	|UNION ALL
	|
	// We fix the surplus by selection
	|SELECT
	|	GoodsTable.Ref              AS Ref,
	|	GoodsTable.Ref.Date         AS Date,
	|	CASE
	|		WHEN GoodsTable.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordSurplus)
	|			THEN GoodsTable.Ref.WarehouseDocument
	|		ELSE GoodsTable.Ref.RecipientNote
	|	END                             AS ReferenceOrder,
	|	UNDEFINED                      AS Cell,
	|	GoodsTable.Products        AS Products,
	|	GoodsTable.Characteristic      AS Characteristic,
	|	GoodsTable.Purpose          AS Purpose,
	|	GoodsTable.Series               AS Series,
	|	GoodsTable.Package            AS Package,
	|	GoodsTable.Count          AS Count,
	|	GoodsTable.NumberOfPackages  AS NumberOfPackages,
	|	GoodsTable.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TRUE                            AS Picked,
	|	TRUE                            AS IsFilter,
	|	FALSE                              AS ThisIsReflectionOfCells
	|FROM
	|	Document.InventoryAdjustmentGoodsShipmentOrder.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN(&Ref)
	|	AND GoodsTable.OperationKind IN (
	|		VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordSurplus),
	|		VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.MoveToOtherNote)
	|	)
	|
	|UNION ALL
	|
	// We fix the excess in the cells
	|SELECT
	|	GoodsTable.Ref              AS Ref,
	|	GoodsTable.Ref.Date         AS Date,
	|	UNDEFINED                      AS ReferenceOrder,
	|	GoodsTable.Ref.ShippingZone AS Cell,
	|	GoodsTable.Products        AS Products,
	|	GoodsTable.Characteristic      AS Characteristic,
	|	GoodsTable.Purpose          AS Purpose,
	|	GoodsTable.Series               AS Series,
	|	GoodsTable.Package            AS Package,
	|	GoodsTable.Count          AS Count,
	|	GoodsTable.NumberOfPackages  AS NumberOfPackages,
	|	GoodsTable.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TRUE                            AS Picked,
	|	FALSE                              AS IsFilter,
	|	TRUE                            AS ThisIsReflectionOfCells
	|FROM
	|	Document.InventoryAdjustmentGoodsShipmentOrder.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN(&Ref)
	|	AND GoodsTable.OperationKind IN (
	|		VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordSurplusAndLeaveInShippingArea),
	|		VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.LeaveInShippingArea)
	|	)
	|";
	
	WarehousesServer.PickUpProducts(Query, QueryTexts, Registers, QueryTextDocument_);
	
EndProcedure

Function QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers)
	RegisterName = "GoodsBatchMovement";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	QueryText =
	"SELECT
	|	SeriesTable.Products AS Products,
	|	SeriesTable.Characteristic AS Characteristic,
	|	CASE
	|		WHEN ISNULL(SeriesTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN SeriesTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END AS Purpose,
	|	SeriesTable.Series AS Series,
	|	SeriesTable.Count AS Count,
	|	&Warehouse AS Sender,
	|	&Premise AS WareroomOfSender,
	|	&Warehouse AS Recipient,
	|	&Premise AS WareroomOfRecipient,
	|	VALUE(Enum.WarehouseTransactions.ShipmentControl) AS WarehouseOperation,
	|	&WarehouseDocument  AS Document,
	|	&Period AS Period,
	|	TRUE AS ThisIsWarehouseRecord
	|FROM
	|	Document.InventoryAdjustmentGoodsShipmentOrder.Goods AS SeriesTable
	|
	|WHERE
	|	SeriesTable.Ref = &Ref
	|	AND SeriesTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)";	
	
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
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period AS Period,
	|	&Warehouse AS Warehouse,
	|	&Premise AS Premise,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	CASE
	|		WHEN ISNULL(GoodsTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN GoodsTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.Count AS InStock
	|FROM
	|	TTProducts_1 AS GoodsTable
	|WHERE
	|	GoodsTable.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordSurplus)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense),
	|	&Period,
	|	&Warehouse,
	|	&Premise,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	CASE
	|		WHEN ISNULL(GoodsTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN GoodsTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	GoodsTable.Series,
	|	GoodsTable.Count
	|FROM
	|	TTProducts_1 AS GoodsTable
	|WHERE
	|	GoodsTable.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordShortage)";	
	
	QueryTexts.Add(QueryText, RegisterName);

	Return QueryText;
	
EndFunction

Function QueryTextTTProductLocationsBalance(Query, QueryTexts)
	
	RegisterName = "TTGoodsPlacesBalances";
	QueryText = 
	"SELECT
	|	&Warehouse AS Warehouse,
	|	&Premise AS Premise,
	|	InventoryAdjustmentGoodsShipmentOrderGoods.Products AS Products,
	|	InventoryAdjustmentGoodsShipmentOrderGoods.Characteristic AS Characteristic,
	|	InventoryAdjustmentGoodsShipmentOrderGoods.Purpose AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	CASE
	|		WHEN InventoryAdjustmentGoodsShipmentOrderGoods.BatchesIndicationStatus IN (4, 6, 8, 10, 14)
	|			THEN InventoryAdjustmentGoodsShipmentOrderGoods.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	InventoryAdjustmentGoodsShipmentOrderGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	InventoryAdjustmentGoodsShipmentOrderGoods.Package AS CargoItem,
	|	SUM(CASE
	|			WHEN InventoryAdjustmentGoodsShipmentOrderGoods.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordSurplus)
	|					OR InventoryAdjustmentGoodsShipmentOrderGoods.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordSurplusAndLeaveInShippingArea)
	|				THEN InventoryAdjustmentGoodsShipmentOrderGoods.NumberOfPackages
	|			WHEN InventoryAdjustmentGoodsShipmentOrderGoods.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordShortage)
	|				THEN -InventoryAdjustmentGoodsShipmentOrderGoods.NumberOfPackages
	|			ELSE 0
	|		END) AS CountBalance
	|INTO TTGoodsPlacesBalances
	|FROM
	|	Document.InventoryAdjustmentGoodsShipmentOrder.Goods AS InventoryAdjustmentGoodsShipmentOrderGoods
	|WHERE
	|	InventoryAdjustmentGoodsShipmentOrderGoods.Ref = &Ref
	|	AND InventoryAdjustmentGoodsShipmentOrderGoods.OperationKind IN (VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordSurplus), VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordShortage), VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordSurplusAndLeaveInShippingArea))
	|	AND ISNULL(InventoryAdjustmentGoodsShipmentOrderGoods.Package.PackageType, UNDEFINED) = VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|
	|GROUP BY
	|	InventoryAdjustmentGoodsShipmentOrderGoods.Package,
	|	InventoryAdjustmentGoodsShipmentOrderGoods.Products,
	|	InventoryAdjustmentGoodsShipmentOrderGoods.Characteristic,
	|	InventoryAdjustmentGoodsShipmentOrderGoods.Purpose,
	|	CASE
	|		WHEN InventoryAdjustmentGoodsShipmentOrderGoods.BatchesIndicationStatus IN (4, 6, 8, 10, 14)
	|			THEN InventoryAdjustmentGoodsShipmentOrderGoods.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END,
	|	InventoryAdjustmentGoodsShipmentOrderGoods.BatchesIndicationStatus
	|
	|HAVING
	|	SUM(CASE
	|			WHEN InventoryAdjustmentGoodsShipmentOrderGoods.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordSurplus)
	|				THEN InventoryAdjustmentGoodsShipmentOrderGoods.NumberOfPackages
	|			WHEN InventoryAdjustmentGoodsShipmentOrderGoods.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordShortage)
	|				THEN -InventoryAdjustmentGoodsShipmentOrderGoods.NumberOfPackages
	|			ELSE 0
	|		END) <> 0";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTTProducts_1(Query, QueryTexts)
	
	If Not DocumentsPosting.ThereIsQueryTable("TTGoodsPlacesBalances", QueryTexts) Then
		QueryTextTTProductLocationsBalance(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTSetsOnCommodityRequirementsForReflectionOfSurplusShortages", QueryTexts) Then
		WarehousesServer.QueryTextTTSetsOnCommodityRequirementsForReflectionOfSurplusShortages(QueryTexts);
	EndIf;
	
	RegisterName = "TTProducts_1";
			
	QueryText = 
	"SELECT DISTINCT
	|	TTSetsOnCommodityRequirementsForReflectionOfSurplusShortages.Products AS Products,
	|	TTSetsOnCommodityRequirementsForReflectionOfSurplusShortages.Characteristic AS Characteristic,
	|	TTSetsOnCommodityRequirementsForReflectionOfSurplusShortages.Purpose AS Purpose,
	|	TTSetsOnCommodityRequirementsForReflectionOfSurplusShortages.Series AS Series,
	|	InventoryAdjustmentGoodsShipmentOrderGoods.BatchesIndicationStatus = 14 AS ThisIsSeriesAtCostPrice,
	|	TTSetsOnCommodityRequirementsForReflectionOfSurplusShortages.OperationKind AS OperationKind,
	|	TTSetsOnCommodityRequirementsForReflectionOfSurplusShortages.KitCount AS Count
	|INTO TTProducts_1
	|FROM
	|	TTSetsOnCommodityRequirementsForReflectionOfSurplusShortages AS TTSetsOnCommodityRequirementsForReflectionOfSurplusShortages
	|		INNER JOIN Document.InventoryAdjustmentGoodsShipmentOrder.Goods AS InventoryAdjustmentGoodsShipmentOrderGoods
	|		ON TTSetsOnCommodityRequirementsForReflectionOfSurplusShortages.Products = InventoryAdjustmentGoodsShipmentOrderGoods.Products
	|WHERE
	|	InventoryAdjustmentGoodsShipmentOrderGoods.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	InventoryAdjustmentGoodsShipmentOrderGoods.Products,
	|	InventoryAdjustmentGoodsShipmentOrderGoods.Characteristic,
	|	InventoryAdjustmentGoodsShipmentOrderGoods.Purpose,
	|	CASE
	|		WHEN InventoryAdjustmentGoodsShipmentOrderGoods.BatchesIndicationStatus IN (4, 6, 8, 10, 14)
	|			THEN InventoryAdjustmentGoodsShipmentOrderGoods.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END,
	|	InventoryAdjustmentGoodsShipmentOrderGoods.BatchesIndicationStatus = 14,
	|	CASE
	|		WHEN InventoryAdjustmentGoodsShipmentOrderGoods.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordSurplusAndLeaveInShippingArea)
	|			THEN VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordSurplus)
	|		ELSE InventoryAdjustmentGoodsShipmentOrderGoods.OperationKind
	|	END,
	|	SUM(InventoryAdjustmentGoodsShipmentOrderGoods.Count)
	|FROM
	|	Document.InventoryAdjustmentGoodsShipmentOrder.Goods AS InventoryAdjustmentGoodsShipmentOrderGoods
	|WHERE
	|	InventoryAdjustmentGoodsShipmentOrderGoods.Ref = &Ref
	|	AND InventoryAdjustmentGoodsShipmentOrderGoods.OperationKind IN (VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordSurplus), VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordShortage), VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordSurplusAndLeaveInShippingArea))
	|	AND ISNULL(InventoryAdjustmentGoodsShipmentOrderGoods.Package.PackageType, UNDEFINED) <> VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|
	|GROUP BY
	|	InventoryAdjustmentGoodsShipmentOrderGoods.Characteristic,
	|	InventoryAdjustmentGoodsShipmentOrderGoods.Products,
	|	InventoryAdjustmentGoodsShipmentOrderGoods.OperationKind,
	|	CASE
	|		WHEN InventoryAdjustmentGoodsShipmentOrderGoods.BatchesIndicationStatus IN (4, 6, 8, 10, 14)
	|			THEN InventoryAdjustmentGoodsShipmentOrderGoods.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END,
	|	InventoryAdjustmentGoodsShipmentOrderGoods.BatchesIndicationStatus = 14,
	|	InventoryAdjustmentGoodsShipmentOrderGoods.Purpose
	|
	|HAVING
	|	SUM(InventoryAdjustmentGoodsShipmentOrderGoods.Count) > 0";
		
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

// Returns a table of States and dates of cell recalculations after checking the shipment of goods
//	Returns:
//		ValueTable - a table of values with states and dates of cell recalculations.
//
Function TableOfCellRecalculationStates(DocumentRef, Status) Export
	
	TableOfCellRecalculationStates = New ValueTable;
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	SelectionProductPlacementProductsSelection.Products,
	|	SelectionProductPlacementProductsSelection.Characteristic,
	|	SelectionProductPlacementProductsSelection.Series,
	|	SelectionProductPlacementProductsSelection.Package,
	|	SelectionProductPlacementProductsSelection.Cell
	|INTO GoodsFilter
	|FROM
	|	Document.InventoryAdjustmentGoodsShipmentOrder AS InventoryAdjustmentGoodsShipmentOrder
	|		INNER JOIN Document.GoodsPickingPlacement.GoodsFilter AS SelectionProductPlacementProductsSelection
	|		ON InventoryAdjustmentGoodsShipmentOrder.WarehouseDocument = SelectionProductPlacementProductsSelection.Ref.ReferenceOrder
	|WHERE
	|	InventoryAdjustmentGoodsShipmentOrder.Ref = &DocumentRef
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InventoryAdjustmentGoodsShipmentOrderGoods.Products,
	|	InventoryAdjustmentGoodsShipmentOrderGoods.Characteristic,
	|	InventoryAdjustmentGoodsShipmentOrderGoods.Series,
	|	InventoryAdjustmentGoodsShipmentOrderGoods.Package
	|INTO GoodsShortage
	|FROM
	|	Document.InventoryAdjustmentGoodsShipmentOrder.Goods AS InventoryAdjustmentGoodsShipmentOrderGoods
	|WHERE
	|	InventoryAdjustmentGoodsShipmentOrderGoods.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordShortage)
	|	AND InventoryAdjustmentGoodsShipmentOrderGoods.Ref = &DocumentRef
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InventoryAdjustmentGoodsShipmentOrderGoods.Products,
	|	InventoryAdjustmentGoodsShipmentOrderGoods.Characteristic,
	|	InventoryAdjustmentGoodsShipmentOrderGoods.Series,
	|	InventoryAdjustmentGoodsShipmentOrderGoods.Package
	|INTO GoodsSurplus_
	|FROM
	|	Document.InventoryAdjustmentGoodsShipmentOrder.Goods AS InventoryAdjustmentGoodsShipmentOrderGoods
	|WHERE
	|	InventoryAdjustmentGoodsShipmentOrderGoods.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordSurplus)
	|	AND InventoryAdjustmentGoodsShipmentOrderGoods.Ref = &DocumentRef
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	InternalQuery.Cell,
	|	VALUE(Enum.BinRecountStates.RecountIsRequired) AS State,
	|	CAST(&DocumentRef AS Document.InventoryAdjustmentGoodsShipmentOrder).Date AS DocumentDate
	|FROM
	|	(SELECT
	|		GoodsFilter.Cell AS Cell
	|	FROM
	|		GoodsFilter AS GoodsFilter
	|			INNER JOIN GoodsShortage AS GoodsShortage
	|			ON GoodsFilter.Products = GoodsShortage.Products
	|				AND GoodsFilter.Characteristic = GoodsShortage.Characteristic
	|				AND GoodsFilter.Series = GoodsShortage.Series
	|				AND GoodsFilter.Package = GoodsShortage.Package
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsInStorageBinsBalance.Cell
	|	FROM
	|		AccumulationRegister.GoodsInStorageBins.Balance(
	|				,
	|				(Products, Characteristic, Series, Package) IN
	|					(SELECT
	|						GoodsSurplus_.Products,
	|						GoodsSurplus_.Characteristic,
	|						GoodsSurplus_.Series,
	|						GoodsSurplus_.Package
	|					FROM
	|						GoodsSurplus_ AS GoodsSurplus_)) AS GoodsInStorageBinsBalance
	|	WHERE
	|		GoodsInStorageBinsBalance.InStockBalance > 0) AS InternalQuery";
	
	Query.SetParameter("DocumentRef", DocumentRef);
	TableOfCellRecalculationStates = Query.Execute().Unload();
	
	Return TableOfCellRecalculationStates;
	
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
		|	Document.InventoryAdjustmentGoodsShipmentOrder.Goods AS TabPart
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
		|	TabPart.Count AS Count,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule
		|FROM
		|	Document.InventoryAdjustmentGoodsShipmentOrder.Goods AS TabPart
		|WHERE
		|	TabPart.OperationKind IN (VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordSurplus),
		|		VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordSurplusAndLeaveInShippingArea))
		|	AND ISNULL(TabPart.Package.PackageType,
		|		UNDEFINED) <> VALUE(Enum.TypesOfItemsPackages.CargoItem)";
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, False);
	
	TextProductLocationsInDocument =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	MAX(TabPart.Ref.Date) AS Date,
		|	MAX(TabPart.Ref.Warehouse) AS Warehouse,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Purpose AS Purpose,
		|	TabPart.Package AS CargoItem,
		|	CASE
		|		WHEN TabPart.BatchesIndicationStatus IN (4, 6, 8, 10, 14)
		|			THEN TabPart.Series
		|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
		|	END AS Series,
		|	SUM(CASE
		|			WHEN TabPart.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordSurplus)
		|					OR TabPart.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordSurplusAndLeaveInShippingArea)
		|				THEN TabPart.NumberOfPackages
		|			WHEN TabPart.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordShortage)
		|				THEN -TabPart.NumberOfPackages
		|			ELSE 0
		|		END) AS CountBalance
		|INTO ProductLocationsInDocument
		|FROM
		|	Document.InventoryAdjustmentGoodsShipmentOrder.Goods AS TabPart
		|WHERE
		|	TabPart.Ref IN(&Ref)
		|		AND TabPart.OperationKind IN (
		|			VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordSurplus),
		|			VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordShortage),
		|			VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordSurplusAndLeaveInShippingArea))
		|		AND TabPart.Package.PackageType = VALUE(Enum.TypesOfItemsPackages.CargoItem)
		|GROUP BY
		|	TabPart.Ref,
		|	TabPart.Package,
		|	TabPart.Products,
		|	TabPart.Characteristic,
		|	TabPart.Purpose,
		|	CASE
		|		WHEN TabPart.BatchesIndicationStatus IN (4, 6, 8, 10, 14)
		|			THEN TabPart.Series
		|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
		|	END
		|HAVING
		|	SUM(CASE
		|			WHEN TabPart.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordSurplus)
		|					OR TabPart.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordSurplusAndLeaveInShippingArea)
		|				THEN TabPart.NumberOfPackages
		|			WHEN TabPart.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordShortage)
		|				THEN -TabPart.NumberOfPackages
		|			ELSE 0
		|		END) <> 0
		|INDEX BY
		|	Ref, Products, CargoItem";
		
	TextProductLocationsInProductRange =
		"SELECT DISTINCT
		|	ProductLocationsBalance.Date AS Date,
		|	ProductLocationsBalance.Ref AS Ref,
		|	ProductLocationsBalance.Products AS Products,
		|	ProductLocationsBalance.Characteristic AS Characteristic,
		|	ProductLocationsBalance.Purpose AS Purpose,
		|	ProductLocationsBalance.Series AS Series,
		|	PackagesAndUnitsOfMeasure.Ref AS CargoItem,
		|	PackagesAndUnitsOfMeasure.NumberOfPackages AS NumberOfSeats
		|INTO ItemsInProductRange
		|FROM
		|	Catalog.PackagesAndUnitsOfMeasure AS PackagesAndUnitsOfMeasure
		|		INNER JOIN ProductLocationsInDocument AS ProductLocationsBalance
		|		ON (PackagesAndUnitsOfMeasure.Owner = CASE
		|				WHEN ProductLocationsBalance.Products.PackagingGroup = VALUE(Catalog.PackagingGroups.SpecialForItem)
		|					THEN ProductLocationsBalance.Products.Ref
		|				ELSE ProductLocationsBalance.Products.PackagingGroup
		|			END)
		|WHERE
		|	PackagesAndUnitsOfMeasure.PackageType = VALUE(Enum.TypesOfItemsPackages.CargoItem)
		|INDEX BY
		|	Ref, Products, CargoItem";
	
	TextWholeSets =
		"SELECT
		|	ItemsInProductRange.Ref AS Ref,
		|	ItemsInProductRange.Products AS Products,
		|	ItemsInProductRange.Characteristic AS Characteristic,
		|	ItemsInProductRange.Purpose AS Purpose,
		|	ItemsInProductRange.Series AS Series,
		|	MAX(TabPart.Date) AS Date,
		|	MAX(TabPart.Warehouse) AS Warehouse,
		|	MIN(CASE
		|			WHEN (CAST(ISNULL(TabPart.CountBalance, 0) / ItemsInProductRange.NumberOfSeats AS NUMBER(12, 0)))
		|					- ISNULL(TabPart.CountBalance, 0) / ItemsInProductRange.NumberOfSeats <= 0
		|				THEN CAST(ISNULL(TabPart.CountBalance, 0) / ItemsInProductRange.NumberOfSeats AS NUMBER(12, 0))
		|			ELSE (CAST(ISNULL(TabPart.CountBalance, 0) / ItemsInProductRange.NumberOfSeats AS NUMBER(12, 0))) - 1
		|		END) AS KitCount
		|INTO WholeSets
		|FROM
		|	ItemsInProductRange AS ItemsInProductRange
		|		
		|		LEFT JOIN ProductLocationsInDocument AS TabPart
		|		ON TabPart.Ref = ItemsInProductRange.Ref
		|			AND TabPart.Products = ItemsInProductRange.Products
		|			AND TabPart.Characteristic = ItemsInProductRange.Characteristic
		|			AND TabPart.Purpose = ItemsInProductRange.Purpose
		|			AND TabPart.Series = ItemsInProductRange.Series
		|			AND TabPart.CargoItem = ItemsInProductRange.CargoItem
		|			AND TabPart.CountBalance > 0
		|		
		|GROUP BY
		|	ItemsInProductRange.Ref,
		|	ItemsInProductRange.Products,
		|	ItemsInProductRange.Characteristic,
		|	ItemsInProductRange.Purpose,
		|	ItemsInProductRange.Series
		|HAVING
		|	MIN(CASE
		|			WHEN (CAST(ISNULL(TabPart.CountBalance, 0) / ItemsInProductRange.NumberOfSeats AS NUMBER(12, 0)))
		|					- ISNULL(TabPart.CountBalance, 0) / ItemsInProductRange.NumberOfSeats <= 0
		|				THEN CAST(ISNULL(TabPart.CountBalance, 0) / ItemsInProductRange.NumberOfSeats AS NUMBER(12, 0))
		|			ELSE (CAST(ISNULL(TabPart.CountBalance, 0) / ItemsInProductRange.NumberOfSeats AS NUMBER(12, 0))) - 1
		|		END) > 0
		|
		|UNION ALL
		|
		|SELECT
		|	ItemsInProductRange.Ref AS Ref,
		|	ItemsInProductRange.Products AS Products,
		|	ItemsInProductRange.Characteristic AS Characteristic,
		|	ItemsInProductRange.Purpose AS Purpose,
		|	ItemsInProductRange.Series AS Series,
		|	MAX(TabPart.Date) AS Date,
		|	MAX(TabPart.Warehouse) AS Warehouse,
		|	MIN(CASE
		|			WHEN (CAST(ISNULL(TabPart.CountBalance, 0) / ItemsInProductRange.NumberOfSeats AS NUMBER(12, 0)))
		|					- ISNULL(TabPart.CountBalance, 0) / ItemsInProductRange.NumberOfSeats > 0
		|				THEN CAST(ISNULL(TabPart.CountBalance, 0) / ItemsInProductRange.NumberOfSeats AS NUMBER(12, 0))- 1
		|			ELSE (CAST(ISNULL(TabPart.CountBalance, 0) / ItemsInProductRange.NumberOfSeats AS NUMBER(12, 0))) 
		|		END) AS KitCount
		|FROM
		|	ItemsInProductRange AS ItemsInProductRange
		|		
		|		LEFT JOIN ProductLocationsInDocument AS TabPart
		|		ON TabPart.Ref = ItemsInProductRange.Ref
		|			AND TabPart.Products = ItemsInProductRange.Products
		|			AND TabPart.Characteristic = ItemsInProductRange.Characteristic
		|			AND TabPart.Purpose = ItemsInProductRange.Purpose
		|			AND TabPart.Series = ItemsInProductRange.Series
		|			AND TabPart.CargoItem = ItemsInProductRange.CargoItem
		|			AND TabPart.CountBalance < 0
		|		
		|GROUP BY
		|	ItemsInProductRange.Ref,
		|	ItemsInProductRange.Products,
		|	ItemsInProductRange.Characteristic,
		|	ItemsInProductRange.Purpose,
		|	ItemsInProductRange.Series
		|HAVING
		|	MIN(CASE
		|			WHEN (CAST(ISNULL(TabPart.CountBalance, 0) / ItemsInProductRange.NumberOfSeats AS NUMBER(12, 0)))
		|					- ISNULL(TabPart.CountBalance, 0) / ItemsInProductRange.NumberOfSeats > 0
		|				THEN CAST(ISNULL(TabPart.CountBalance, 0) / ItemsInProductRange.NumberOfSeats AS NUMBER(12, 0))- 1
		|			ELSE (CAST(ISNULL(TabPart.CountBalance, 0) / ItemsInProductRange.NumberOfSeats AS NUMBER(12, 0))) 
		|		END) < 0";
	
	TemporaryTableTemplateTexts = New Structure();
	TemporaryTableTemplateTexts.Insert("ProductLocationsInDocument", TextProductLocationsInDocument);
	TemporaryTableTemplateTexts.Insert("ItemsInProductRange", TextProductLocationsInProductRange);
	TemporaryTableTemplateTexts.Insert("WholeSets", TextWholeSets);
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Warehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	-TabPart.KitCount AS Count,
		|	UNDEFINED AS PlannedConsumptionOfDistributedStock,
		|	FALSE AS ControlOfFreeResidue
		|FROM
		|	WholeSets AS TabPart
		|WHERE
		|	TabPart.KitCount < 0
		|	AND VALUETYPE(TabPart.Ref) = TYPE(Document.InventoryAdjustmentGoodsShipmentOrder)"; // it is necessary that it is not doubled in the IB update.
	
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, False,
		TemporaryTableTemplateTexts);
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Warehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking,
		|	DATETIME(1, 1, 1) AS QualityConfirmationDate,
		|	TabPart.KitCount AS Count,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule
		|FROM
		|	WholeSets AS TabPart
		|WHERE
		|	TabPart.KitCount > 0
		|	AND VALUETYPE(TabPart.Ref) = TYPE(Document.InventoryAdjustmentGoodsShipmentOrder)"; // it is necessary that it is not doubled in the IB update.
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, False,
		TemporaryTableTemplateTexts);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
#EndIf
