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
	
	DocumentMechanisms.Add("AddressWarehouse");
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
	
	If TypeOf(Document) = Type("DocumentObject.GoodsTransferNote") Then
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
		
		QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers);
	EndIf;
	
	TakeGoodsToWarehouse(Query, QueryTexts, Registers);
	ShipGoodsFromWarehouse_(Query, QueryTexts, Registers);
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Documents.GoodsPickingPlacement.AddGenerateCommand(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	DataProcessors.ReferenceAddressWarehousingOfProducts.AddGenerateCommand(GenerationCommands);
	
EndProcedure

// Adds a command to create a document "order to move goods".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTable, Undefined - generated commands for output to the submenu.
//
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.GoodsTransferNote) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.GoodsTransferNote.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.GoodsTransferNote);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseWarerooms";
	
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
	AttributesNames = "Warehouse,ReceivingWareroom,SenderWareroom,Status,DateOfShipment";
	
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
	
	SeriesSpecificationParameters.FullObjectName = "Document.GoodsTransferNote";
	
	WarehouseSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Warehouse, False);
	
	SeriesSpecificationParameters.UseItemsBatch  = WarehouseSeriesParameters.UseItemsBatch;
	SeriesSpecificationParameters.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;
	
	SeriesSpecificationParameters.NameTSGoods  = "ShippedGoods";
	SeriesSpecificationParameters.TSSeriesName   = "ShippedGoods";
	
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.TransferBetweenWarerooms);
	
	SenderUseAddressStorage = WarehousesServer.UseBinLocationWarehousing(Object.Warehouse, Object.SenderWareroom, Object.DateOfShipment);
	ReceiverUseAddressableStorage = WarehousesServer.UseBinLocationWarehousing(Object.Warehouse, Object.ReceivingWareroom, Object.DateOfShipment);
	
	SeriesSpecificationParameters.UseBinLocationWarehousing = SenderUseAddressStorage
	   Or ReceiverUseAddressableStorage;
	
	If Object.Status = Enums.TransferNoteStatuses.ForPicking Then
		
		SeriesSpecificationParameters.ShipmentPlanning = True;
		SeriesSpecificationParameters.SelectionPlanning = True;
		SeriesSpecificationParameters.PickingCheck = False;
		SeriesSpecificationParameters.FactOfSelection = False;
		
	ElsIf Object.Status = Enums.TransferNoteStatuses.ForChecking Then	
		
		SeriesSpecificationParameters.ShipmentPlanning = False;
		SeriesSpecificationParameters.SelectionPlanning = False;
		SeriesSpecificationParameters.PickingCheck = True;
		SeriesSpecificationParameters.FactOfSelection = False;
			
	ElsIf Object.Status = Enums.TransferNoteStatuses.ToShip
		Or Object.Status = Enums.TransferNoteStatuses.Accepted Then
		
		SeriesSpecificationParameters.ShipmentPlanning = False;
		SeriesSpecificationParameters.SelectionPlanning = False;
		SeriesSpecificationParameters.PickingCheck = False;
		SeriesSpecificationParameters.FactOfSelection = True;
		
	EndIf;
	
	SeriesSpecificationParameters.LinkFields.Add("ControlledLotReference");
	SeriesSpecificationParameters.LinkFields.Add("Purpose");
	SeriesSpecificationParameters.LinkFields.Add("Action");
	
	SeriesSpecificationParameters.LinkFields.Add("Package");
	SeriesSpecificationParameters.FieldNameQuantity = "NumberOfPackages";
	
	SeriesSpecificationParameters.RegisterSeries = ProductsClientServer.ItIsNecessaryToRegisterSeries(SeriesSpecificationParameters);
	SeriesSpecificationParameters.SpecialCheckingOfSeriesIndicationStatuses = True;
	
	SeriesSpecificationParameters.ItSWarrant = True;
	SeriesSpecificationParameters.FieldNameRoom = "SenderWareroom";
	SeriesSpecificationParameters.FieldNameControlledLotReference = ".ControlledLotReference";
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
    Var QueryText;
    
    If SeriesSpecificationParameters.LinkFields.Find("Package") <> Undefined Then
        QueryText = 
        "SELECT
        |	Goods.Action,
        |	Goods.Products,
        |	Goods.Series,
        |	Goods.NumberOfPackages AS Count,
        |	Goods.BatchesIndicationStatus,
        |	Goods.LineNumber
        |INTO Goods
        |FROM
        |	&Goods AS Goods";
    Else
        QueryText = 
        "SELECT
        |	Goods.Action,
		|	Goods.Products,
		|	Goods.Series,
		|	Goods.Count,
		|	Goods.BatchesIndicationStatus,
		|	Goods.LineNumber
        |INTO Goods
        |FROM
        |	&Goods AS Goods";
    EndIf; 
    
    QueryText = 	QueryText + "
    |;
    |
    |////////////////////////////////////////////////////////////////////////////////
    |";
    
    QueryText = 	QueryText +
    "SELECT
    |	Goods.LineNumber AS LineNumber,
    |	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
    |	CASE
    |		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL 
    |			THEN 0
    |		ELSE CASE
    |				WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment
    |					THEN CASE
    |							WHEN Goods.Count > 0
    |									AND Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
    |								THEN CASE
    |										WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
    |											THEN 14
    |										ELSE 10
    |									END
    |							ELSE CASE
    |									WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
    |										THEN 13
    |									ELSE 9
    |								END
    |						END
    |				WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningPicking
    |					THEN CASE
    |							WHEN BatchAccountingPolicies.BatchAccountingPolicy.BatchesAccountingByFEFO
    |								THEN CASE
    |										WHEN Goods.Count > 0
    |												AND Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
    |											THEN 6
    |										ELSE 5
    |									END
    |							ELSE CASE
    |									WHEN Goods.Count > 0
    |											AND Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
    |										THEN 8
    |									ELSE 7
    |								END
    |						END
 	|		WHEN (BatchAccountingPolicies.BatchAccountingPolicy.SpecifyByPickingResult
	|				OR BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnReceiving)
	|				AND BatchAccountingPolicies.BatchAccountingPolicy.SpecifyUponTransferBetweenWarerooms
    |					THEN CASE
    |							WHEN BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries
    |								THEN CASE
    |										WHEN Goods.Count > 0
    |												AND Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
    |											THEN 4
    |										WHEN Goods.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.Pick)
    |												AND (NOT &UseBinLocationWarehousing
    |													OR &UseBinLocationWarehousing)
    |														AND &SelectionPlanning
    |											THEN 0
    |										ELSE 3
    |									END
    |							ELSE CASE
    |									WHEN Goods.Count > 0
    |											AND Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
    |											AND Goods.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.Ship)
    |										THEN 2
    |									WHEN Goods.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.Ship)
    |										THEN 1
    |									ELSE 0
    |								END
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
    |		ON (BatchAccountingPolicies.Warehouse = &Warehouse)
    |			AND Goods.Products.ProductKind = BatchAccountingPolicies.Ref
    |;
    |
    |////////////////////////////////////////////////////////////////////////////////
    |SELECT
    |	StatusTable.LineNumber AS LineNumber,
    |	StatusTable.BatchesIndicationStatus AS BatchesIndicationStatus
    |FROM
    |	StatusTable AS StatusTable
    |WHERE
    |	StatusTable.BatchesIndicationStatus <> StatusTable.OldStatusOfSpecifyingSeries
    |
    |ORDER BY
    |	LineNumber";
    Return QueryText;
	
EndFunction

// Returns the request body for the get the available appointments
//	Parameters:
//		RequestFormationParameters - Structure - the parameters for the generation of text queries
//	Returns:
//		String - query text.
//
Function RequestTextForAvailableAssignments(RequestFormationParameters) Export
	
	Return Catalogs.Assignments.RequestTextOfUnsecuredAppointmentsSecured(RequestFormationParameters);
	
EndFunction

// Returns the request text to check whether the series is filled in
//	Parameters:
//		SeriesSpecificationParameters - Structure - the structure of fields is specified in the function Nomenclaturales.Parametrizatsii
//	Returns:
//		String - query text.
//
Function TextOfRequestToCheckSeriesFilling(SeriesSpecificationParameters) Export
	
	If SeriesSpecificationParameters.UseBinLocationWarehousing Then
		QueryText = 
		"SELECT
		|	TableOfSeries.LineNumber AS LineNumber,
		|	TableOfSeries.Products AS Products,
		|	TableOfSeries.Characteristic AS Characteristic,
		|	TableOfSeries.Series AS Series,
		|	""Series"" AS FieldNameSeries,
		|	CASE
		|		WHEN TableOfSeries.Action <> VALUE(Enum.ActionsWithGoodsIssueNoteRows.Pick)
		|			THEN TableOfSeries.Package
		|		ELSE VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|	END AS Package,
		|	CASE
		|		WHEN TableOfSeries.Action <> VALUE(Enum.ActionsWithGoodsIssueNoteRows.Pick)
		|			THEN TableOfSeries.NumberOfPackages
		|		ELSE TableOfSeries.Count
		|	END AS NumberOfPackages
		|INTO SeriesTableForQuery
		|FROM
		|	&TableOfSeries_QueryNumber AS TableOfSeries
		|WHERE
		|	TableOfSeries.BatchesIndicationStatus > 0
		|	AND NOT TableOfSeries.BatchesIndicationStatus IN (&SeriesStatusesYouCanSpecifySeries)";
	Else
		QueryText = 
		"SELECT
		|	TableOfSeries.LineNumber AS LineNumber,
		|	TableOfSeries.Products AS Products,
		|	TableOfSeries.Characteristic AS Characteristic,
		|	TableOfSeries.Series AS Series,
		|	""Series"" AS FieldNameSeries,
		|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
		|	TableOfSeries.Count AS NumberOfPackages
		|INTO SeriesTableForQuery
		|FROM
		|	&TableOfSeries_QueryNumber AS TableOfSeries
		|WHERE
		|	TableOfSeries.BatchesIndicationStatus > 0
		|	AND NOT TableOfSeries.BatchesIndicationStatus IN (&SeriesStatusesYouCanSpecifySeries)";
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

#Region Print

// Returns the rules for printing the printed form of the Task for selecting (placing) products.
//
// Returns:
//	Array - the elements of which is the structure (See DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand)
//          .
//
Function RulesForPrintingTasksForSelectionPlacement() Export
	
	PrintRules = New Array;
	
	JobPrintingRules = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.RulesForPrintingTasksForSelectionPlacement();
	JobPrintingRules.ReceiptOperation	= True;
	JobPrintingRules.ThisIsAnInvoice			= False;
	JobPrintingRules.FieldNameRoom		= "ReceivingWareroom";
	JobPrintingRules.NameTSGoods			= "ShippedGoods";
	
	PrintRules.Add(JobPrintingRules);
	
	JobPrintingRules = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.RulesForPrintingTasksForSelectionPlacement();
	JobPrintingRules.ThisIsAnInvoice		= False;
	JobPrintingRules.FieldNameRoom	= "SenderWareroom";
	JobPrintingRules.NameTSGoods		= "ShippedGoods";
	
	PrintRules.Add(JobPrintingRules);
	
	Return PrintRules;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

Procedure FillInActionInLines(Object) Export
	
	If Object.Status = Enums.TransferNoteStatuses.ToShip
		Or Object.Status = Enums.TransferNoteStatuses.Accepted Then
		FoundRows = Object.ShippedGoods.FindRows(New Structure("Action",
		 														Enums.ActionsWithGoodsIssueNoteRows.Pick)); // An array of a documentable part of a string.Ordernaposition of goods.Shipped Goods
		
		For Each ArrRow In FoundRows Do
			ArrRow.Action = Enums.ActionsWithGoodsIssueNoteRows.Ship;
		EndDo;
		
	EndIf;
		
EndProcedure

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.SetParameter("Ref", DocumentRef);
	Query.Text = 
	"SELECT
	|	HeaderData_.DateOfShipment			AS Period,
	|	HeaderData_.Warehouse					AS Warehouse,
	|	HeaderData_.SenderWareroom	AS SenderWareroom,
	|	HeaderData_.ReceivingWareroom		AS ReceivingWareroom,
	|	HeaderData_.Status					AS Status
	|FROM
	|	Document.GoodsTransferNote AS HeaderData_
	|WHERE
	|	HeaderData_.Ref = &Ref";
	
	Attributes = Query.Execute().Select();
	Attributes.Next();

	Query.SetParameter("Status",					Attributes.Status);
	Query.SetParameter("Period",					Attributes.Period);
	Query.SetParameter("Warehouse",					Attributes.Warehouse);
	Query.SetParameter("SenderWareroom",	Attributes.SenderWareroom);
	Query.SetParameter("ReceivingWareroom",	Attributes.ReceivingWareroom);
	
EndProcedure

Function QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsBatchMovement";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableProducts", QueryTexts) Then
		QueryTextTTTableProducts(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	SeriesTable.Products             AS Products,
	|	SeriesTable.Characteristic           AS Characteristic,
	|	SeriesTable.Purpose               AS Purpose,
	|	SeriesTable.Series                    AS Series,
	|	SeriesTable.Count               AS Count,
	|	&Warehouse                                AS Sender,
	|	&SenderWareroom                 AS WareroomOfSender,
	|	&Warehouse                                AS Recipient,
	|	&ReceivingWareroom                  AS WareroomOfRecipient,
	|	VALUE(Enum.WarehouseTransactions.TransferBetweenWarerooms) AS WarehouseOperation,
	|	&Ref                               AS Document,
	|	&Period                               AS Period,
	|	TRUE                                AS ThisIsWarehouseRecord
	|FROM
	|	TTTableProducts AS SeriesTable
	|WHERE
	|	SeriesTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|	AND (SeriesTable.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.Pick)
	|	OR SeriesTable.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.Ship))
	|
	|UNION ALL
	|
	|SELECT
	|	SeriesTable.Products,
	|	SeriesTable.Characteristic,
	|	SeriesTable.Purpose,
	|	SeriesTable.Series,
	|	SeriesTable.Count,
	|	&Warehouse,
	|	&SenderWareroom,
	|	&Warehouse,
	|	&ReceivingWareroom,
	|	VALUE(Enum.WarehouseTransactions.TransferBetweenWarerooms),
	|	&Ref,
	|	&Period,
	|	TRUE
	|FROM
	|	TTTableProducts AS SeriesTable
	|WHERE
	|	SeriesTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|	AND &Status = VALUE(Enum.TransferNoteStatuses.Accepted)
	|	AND SeriesTable.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure TakeGoodsToWarehouse(Query, QueryTexts, Registers)
	
	QueryTextDocument_ = 
	"SELECT
	|	GoodsTable.Ref              AS Ref,
	|	HeaderData_.DateOfShipment          AS Date,
	|	HeaderData_.Warehouse                 AS Warehouse,
	|	HeaderData_.ReceivingArea           AS Cell,
	|	HeaderData_.ReceivingWareroom   AS Premise,
	|	UNDEFINED                      AS Sender,
	|	UNDEFINED                      AS ReferenceOrder,
	|	UNDEFINED                      AS BusinessOperation,
	|	GoodsTable.Products        AS Products,
	|	GoodsTable.Characteristic      AS Characteristic,
	|	GoodsTable.Purpose          AS Purpose,
	|	GoodsTable.ControlledLotReference <> VALUE(Catalog.ControlledLots.EmptyRef) AS ToControlQuality,
	// The movement of the party that has not reached it is not important, since this is an acceptance without attraction = False.
	|	FALSE                              AS RecordOfAPreviouslyReceivedLot,
	|	GoodsTable.ControlledLotReference AS ControlledLotReference,
	|	GoodsTable.Package            AS Package,
	|	FALSE                              AS ThisIsAPackingList,
	|	GoodsTable.Series               AS Series,
	|	GoodsTable.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	GoodsTable.Count          AS Count,
	|	GoodsTable.NumberOfPackages  AS NumberOfPackages,
	|	FALSE                              AS Accepts,
	|	TRUE                            AS Accepted,
	|	FALSE                              AS ThisIsReturnOfRejectedGoods,
	|	TRUE                            AS ThisIsAcceptanceWithoutOrder
	|FROM
	|	Document.GoodsTransferNote.ShippedGoods AS GoodsTable
	|		LEFT JOIN Document.GoodsTransferNote AS HeaderData_
	|		ON GoodsTable.Ref = HeaderData_.Ref
	|WHERE
	|	GoodsTable.Ref IN(&Ref)
	|	AND HeaderData_.Status = VALUE(Enum.TransferNoteStatuses.Accepted)
	|	AND (GoodsTable.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.Pick)
	|		OR GoodsTable.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.Ship))";
	
	WarehousesServer.TakeGoodsToWarehouse(Query, QueryTexts, Registers, QueryTextDocument_, "GoodsTable");
	
EndProcedure

Procedure ShipGoodsFromWarehouse_(Query, QueryTexts, Registers)
	
	TextOfDocumentDataRequest = 
	"SELECT
	|	DocumentGoods.Ref				AS Ref,
	|	HeaderData_.DateOfShipment			AS Period,
	|	UNDEFINED						AS OrderDocument,
	|	&DefaultTransportTask		AS TransportationJob,
	|	UNDEFINED						AS Recipient,
	|	HeaderData_.Warehouse					AS Warehouse,
	|	HeaderData_.SenderWareroom	AS Premise,
	|	HeaderData_.ShippingZone			AS Cell,
	|	DocumentGoods.Products		AS Products,
	|	DocumentGoods.Characteristic		AS Characteristic,
	|	DocumentGoods.Purpose			AS Purpose,
	|	DocumentGoods.ControlledLotReference AS ControlledLotReference,
	|	DocumentGoods.Package			AS Package,
	|	DocumentGoods.Series				AS Series,
	|	DocumentGoods.BatchesIndicationStatus	AS BatchesIndicationStatus,
	|	DocumentGoods.Count			AS Count,
	|	DocumentGoods.NumberOfPackages	AS NumberOfPackages,
	|	DocumentGoods.Action			AS Action,
	|	FALSE								AS ForAssembly,
	|	CASE
	|		WHEN HeaderData_.Status IN(VALUE(Enum.TransferNoteStatuses.ForPicking),
	|									VALUE(Enum.TransferNoteStatuses.ForChecking))
	|			THEN TRUE
	|		ELSE FALSE
	|	END								AS AssemblyInProgress,
	|	CASE
	|		WHEN HeaderData_.Status = VALUE(Enum.TransferNoteStatuses.ToShip)
	|			THEN TRUE
	|		ELSE FALSE
	|	END								AS Assembled,
	|	CASE
	|		WHEN HeaderData_.Status = VALUE(Enum.TransferNoteStatuses.Accepted)
	|			THEN TRUE
	|		ELSE FALSE
	|	END								AS ToShip
	|FROM
	|	Document.GoodsTransferNote.ShippedGoods AS DocumentGoods
	|		LEFT JOIN Document.GoodsTransferNote AS HeaderData_
	|		ON DocumentGoods.Ref = HeaderData_.Ref
	|
	|WHERE
	|	DocumentGoods.Ref IN(&Ref)
	|	AND HeaderData_.Status <> VALUE(Enum.TransferNoteStatuses.EmptyRef)
	|	AND DocumentGoods.Count <> 0";
	
	TextOfDocumentDataRequest = StrReplace(TextOfDocumentDataRequest,
												"&DefaultTransportTask",
												"VALUE(Document.TransportationJob.EmptyRef)");
	
	WarehousesServer.ShipGoodsFromWarehouse_(Query, QueryTexts, Registers, TextOfDocumentDataRequest);
	
EndProcedure

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	If AccessRight("Update", Metadata.Documents.GoodsTransferNote) Then
		// Order to move goods
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "GoodsTransferNote";
		PrintCommand.Presentation = NStr("vi = 'Phiếu chuyển kho';
										|ru = 'Ордер на перемещение товаров';
										|en = 'Internal stock transfer'; fa = 'انتقال داخلی موجودی';
										|it = 'Ordine di trasferimento merci';
										|pl = 'Zlecenie na przemieszczenie towarów';
										|tr = 'Dahili stok transferi'");
		PrintCommand.CheckPostingBeforePrint = True;
	EndIf;
	
	// Assignment for the placement of goods
	PrintCommand = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand(PrintCommands, "PlacementJob");
	PrintCommand.AdditionalParameters.Insert("PrintingFromDocumentData");
	
	// Task for the selection of goods
	PrintCommand = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand(PrintCommands, "SelectionTask");
	PrintCommand.AdditionalParameters.Insert("PrintingFromDocumentData");
	
EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "GoodsTransferNote") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"GoodsTransferNote",
			NStr("vi = 'Điều chuyển giữa các nhà kho';
				|ru = 'Перемещение между помещениями';
				|en = 'Intra-warehouse transfer'; fa = 'انتقال درون‌انباری';
				|it = 'Trasferimento tra locali';
				|pl = 'Przemieszczenie między pomieszczeniami';
				|tr = 'Alanlar arasında transfer'"),
			PrintingMovementOfGoodsBetweenPremises(ObjectsArray, PrintObjects));
	EndIf;
EndProcedure

Function PrintingMovementOfGoodsBetweenPremises(ObjectsArray, PrintObjects)
	
	SetPrivilegedMode(True);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_GoodsIssueNote_GoodsIssueNote";
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputCodes = ValueIsFilled(NameOfCodeColumn);
	
	DocumentAttributes = New Structure("Number, Date, Prefix");
	DocumentSynonym = NStr("vi = 'Phiếu chuyển kho';
							|ru = 'Ордер на перемещение товаров';
							|en = 'Internal stock transfer'; fa = 'انتقال داخلی موجودی';
							|it = 'Ordine di trasferimento merci';
							|pl = 'Zlecenie na przemieszczenie towarów';
							|tr = 'Dahili stok transferi'", Common.DefaultLanguageCode());
	
	UseItemPackages = GetFunctionalOption("UseItemPackages");
	
	RequestByHeader = New Query;
	RequestByHeader.Text = 
	"SELECT
	|	GoodsTransferNote.Ref,
	|	PRESENTATION(GoodsTransferNote.Warehouse) AS WarehousePresentation_,
	|	PRESENTATION(GoodsTransferNote.SenderWareroom) AS PresentationOfSenderSPremises,
	|	PRESENTATION(GoodsTransferNote.ReceivingWareroom) AS PresentationOfRecipientSPremises,
	|	PRESENTATION(GoodsTransferNote.ShippingZone) AS ShipmentAreaPresentation,
	|	PRESENTATION(GoodsTransferNote.ReceivingArea) AS PresentationOfAcceptanceArea,
	|	GoodsTransferNote.Date,
	|	GoodsTransferNote.DateOfShipment,
	|	GoodsTransferNote.Number,
	|	GoodsTransferNote.EmployeeResponsible.Individual AS EmployeeResponsible,
	|	GoodsTransferNote.Warehouse AS Warehouse,
	|	GoodsTransferNote.SenderWareroom AS SenderWareroom,
	|	GoodsTransferNote.ReceivingWareroom AS ReceivingWareroom,
	|	GoodsTransferNote.Warehouse.UseItemsBatch AS UseItemsBatch
	|FROM
	|	Document.GoodsTransferNote AS GoodsTransferNote
	|WHERE
	|	GoodsTransferNote.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	GoodsTransferNote.Ref
	|TOTALS BY
	|	UseItemsBatch";
	
	RequestByHeader.SetParameter("ObjectsArray", ObjectsArray);
	
	ObjectsTree = RequestByHeader.Execute().Unload(QueryResultIteration.ByGroups);
	
	For Each UsingSeries In ObjectsTree.Rows Do
						
		RequestForProducts = New Query;
		RequestForProducts.SetParameter("ObjectsArray", UsingSeries.Rows.UnloadColumn("Ref"));
		
		If UsingSeries.UseItemsBatch Then
			QueryTextByGoods = 
			"SELECT
			|	OrderToMoveGoodsShippedGoods.Ref AS Ref,
			|	OrderToMoveGoodsShippedGoods.Products AS Products,
			|	OrderToMoveGoodsShippedGoods.Characteristic AS Characteristic,
			|	OrderToMoveGoodsShippedGoods.Series AS Series,
			|	OrderToMoveGoodsShippedGoods.NumberOfPackages AS NumberOfPackages,
			|	OrderToMoveGoodsShippedGoods.Count AS Count,
			|	CASE
			|		WHEN OrderToMoveGoodsShippedGoods.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip)
			|			THEN TRUE
			|		ELSE FALSE
			|	END AS DoNotShip,
			|	OrderToMoveGoodsShippedGoods.Package AS Package
			|INTO TableOfGoods
			|FROM
			|	Document.GoodsTransferNote.ShippedGoods AS OrderToMoveGoodsShippedGoods
			|WHERE
			|	OrderToMoveGoodsShippedGoods.Ref IN(&ObjectsArray)
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	TableOfGoods.Ref AS Ref,
			|	TableOfGoods.Products AS Products,
			|	TableOfGoods.Characteristic AS Characteristic,
			|	CASE
			|		WHEN TableOfGoods.Products.ProductKind.BatchUsageSettings = VALUE(Enum.ItemsBatchUsageSettings.InventoryItem)
			|			THEN NULL
			|		ELSE TableOfGoods.Series
			|	END AS Series,
			|	SUM(TableOfGoods.NumberOfPackages) AS NumberOfPackages,
			|	SUM(TableOfGoods.Count) AS Count,
			|	TableOfGoods.DoNotShip AS DoNotShip,
			|	TableOfGoods.Package AS Package
			|INTO SummaryTableOfProducts
			|FROM
			|	TableOfGoods AS TableOfGoods
			|
			|GROUP BY
			|	TableOfGoods.Ref,
			|	TableOfGoods.Products,
			|	TableOfGoods.Characteristic,
			|	CASE
			|		WHEN TableOfGoods.Products.ProductKind.BatchUsageSettings = VALUE(Enum.ItemsBatchUsageSettings.InventoryItem)
			|			THEN NULL
			|		ELSE TableOfGoods.Series
			|	END,
			|	TableOfGoods.DoNotShip,
			|	TableOfGoods.Package
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	TableOfGoods.Ref AS Ref,
			|	&OutputCodes,
			|	TableOfGoods.Products AS Products,
			|	TableOfGoods.Characteristic AS Characteristic,
			|	TableOfGoods.Products.DescriptionFull AS ProductPresentation,
			|	TableOfGoods.Characteristic.DescriptionFull AS CharacteristicPresentation,
			|	TableOfGoods.Series.Description AS BatchPresentation,
			|	TableOfGoods.NumberOfPackages,
			|	TableOfGoods.Count,
			|	TableOfGoods.DoNotShip AS DoNotShip,
			|	PRESENTATION(TableOfGoods.Products.UnitOfMeasure) AS PresentationOfBasicUnitOfMeasure,
			|	CASE
			|		WHEN TableOfGoods.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
			|			THEN PRESENTATION(TableOfGoods.Package)
			|		ELSE PRESENTATION(TableOfGoods.Products.UnitOfMeasure)
			|	END AS PresentationOfPackingUnit,
			|	TableOfGoods.Products.ProductKind.BatchUsageSettings AS BatchUsageSettings
			|FROM
			|	SummaryTableOfProducts AS TableOfGoods
			|
			|ORDER BY
			|	Ref,
			|	TableOfGoods.DoNotShip,
			|	Products,
			|	Characteristic
			|TOTALS BY
			|	Ref,
			|	DoNotShip,
			|	Products,
			|	Characteristic
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT DISTINCT
			|	TableOfGoods.Ref AS Ref,
			|	TableOfGoods.Products AS Products,
			|	TableOfGoods.Characteristic AS Characteristic,
			|	TableOfGoods.Series.Description AS BatchPresentation,
			|	TableOfGoods.DoNotShip AS DoNotShip
			|FROM
			|	TableOfGoods AS TableOfGoods
			|WHERE
			|	TableOfGoods.Products.ProductKind.BatchUsageSettings = VALUE(Enum.ItemsBatchUsageSettings.InventoryItem)
			|	AND NOT TableOfGoods.Series IS NULL 
			|
			|ORDER BY
			|	Ref,
			|	DoNotShip,
			|	Products,
			|	Characteristic,
			|	BatchPresentation";
			
			If OutputCodes Then
				QueryTextByGoods = StrReplace(QueryTextByGoods, "&OutputCodes", "TableOfGoods.Products." + NameOfCodeColumn + " AS AdditionalColumn");
			Else
				QueryTextByGoods = StrReplace(QueryTextByGoods, "&OutputCodes,", "");
			EndIf;

			RequestForProducts.Text 	 = QueryTextByGoods;
			QueryResult		 = RequestForProducts.ExecuteBatch(); 
			SelectionByTableParts = QueryResult[2].Select(QueryResultIteration.ByGroups);
			SelectionBySeries 		 = QueryResult[3].Select();
					
		Else
			
			QueryTextByGoods = 
			"SELECT
			|	OrderToMoveGoodsShippedGoods.Ref AS Ref,
			|	OrderToMoveGoodsShippedGoods.Products.DescriptionFull AS ProductPresentation,
			|	&OutputCodes,
			|	OrderToMoveGoodsShippedGoods.Characteristic.DescriptionFull AS CharacteristicPresentation,
			|	"""" AS BatchPresentation,
			|	OrderToMoveGoodsShippedGoods.NumberOfPackages,
			|	OrderToMoveGoodsShippedGoods.Count,
			|	CASE
			|		WHEN OrderToMoveGoodsShippedGoods.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip)
			|			THEN TRUE
			|		ELSE FALSE
			|	END AS DoNotShip,
			|	PRESENTATION(OrderToMoveGoodsShippedGoods.Products.UnitOfMeasure) AS PresentationOfBasicUnitOfMeasure,
			|	CASE
			|		WHEN OrderToMoveGoodsShippedGoods.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
			|			THEN PRESENTATION(OrderToMoveGoodsShippedGoods.Package)
			|		ELSE PRESENTATION(OrderToMoveGoodsShippedGoods.Products.UnitOfMeasure)
			|	END AS PresentationOfPackingUnit,
			|	OrderToMoveGoodsShippedGoods.Products.ProductKind.BatchUsageSettings AS BatchUsageSettings
			|FROM
			|	Document.GoodsTransferNote.ShippedGoods AS OrderToMoveGoodsShippedGoods
			|WHERE
			|	OrderToMoveGoodsShippedGoods.Ref IN(&ObjectsArray)
			|
			|ORDER BY
			|	Ref,
			|	Products,
			|	Characteristic
			|TOTALS BY
			|	Ref,
			|	DoNotShip,
			|	Products,
			|	Characteristic";
			
			If OutputCodes Then
				QueryTextByGoods = StrReplace(QueryTextByGoods, "&OutputCodes", "OrderToMoveGoodsShippedGoods.Products." + NameOfCodeColumn + " AS AdditionalColumn");
			Else
				QueryTextByGoods = StrReplace(QueryTextByGoods, "&OutputCodes,", "");
			EndIf;

			RequestForProducts.Text = QueryTextByGoods;
			SelectionByTableParts = RequestForProducts.Execute().Select(QueryResultIteration.ByGroups);
			
		EndIf;
	  
		FirstDocument = True;
	
		For Each SelectionByDocuments In UsingSeries.Rows Do
			
			If Not SelectionByTableParts.FindNext(New Structure("Ref",SelectionByDocuments.Ref)) Then
				Continue;
			EndIf;
			
			AddressStorageSenderIsUsed = WarehousesServer.UseBinLocationWarehousing(
				SelectionByDocuments.Warehouse,SelectionByDocuments.SenderWareroom,SelectionByDocuments.DateOfShipment);
			AddressStorageReceiverIsUsed  = WarehousesServer.UseBinLocationWarehousing(
				SelectionByDocuments.Warehouse,SelectionByDocuments.ReceivingWareroom,SelectionByDocuments.DateOfShipment);
			
			DisplayingPackages = UseItemPackages Or AddressStorageSenderIsUsed Or AddressStorageReceiverIsUsed;
			
			// We get the layout in a loop, because the width of the columns depends on the warehouse and the room in the document.
			Template = PrintManagement.PrintFormTemplate("Document.GoodsTransferNote.PF_MXL_GoodsTransferNote");
			
			HeaderArea_ 		= Template.GetArea("Title");
			SectionHeader 			= Template.GetArea("Header");
			
			TableHeaderAreaStart 	= Template.GetArea("TableHeader|BeginningOfTheLine");
			AreaTableRowStart 	= Template.GetArea("TableRow|BeginningOfTheLine");
			AreaBasementTableTop 	= Template.GetArea("TableFooter|BeginningOfTheLine");
			
			AreaTableHeaderCodeColumn 	= Template.GetArea("TableHeader|ColumnOfCodes");
			AreaTableRowCodeColumn 	= Template.GetArea("TableRow|ColumnOfCodes");
			AreaBasementTableColumnCodes 	= Template.GetArea("TableFooter|ColumnOfCodes");
			
			AreaTableHeaderCodeColumn.Parameters.NameOfCodeColumn = PresentationOfCodesColumn; 
			
			AreaTableHeaderPackingColumn 		= Template.GetArea("TableHeader|ColumnOfPackages");
			AreaTableRowPackingColumn 	= Template.GetArea("TableRow|ColumnOfPackages");
			AreaBasementTablePackingColumn		= Template.GetArea("TableFooter|ColumnOfPackages");

			SignatureArea = Template.GetArea("Signatures");
			
			AreaHeaderDoNotShip = Template.GetArea("DonTShipHeader");
			
			ProductColumnArea_ = Template.Area("ProductColumn_");
			
			If Not OutputCodes Then
				ProductColumnArea_.ColumnWidth = ProductColumnArea_.ColumnWidth + Template.Area("ColumnOfCodes").ColumnWidth;
			EndIf;
			
			If Not DisplayingPackages Then
				ProductColumnArea_.ColumnWidth = ProductColumnArea_.ColumnWidth + Template.Area("ColumnOfPackagesQuantity").ColumnWidth
				+ Template.Area("ColumnOfPackagesPresentation").ColumnWidth; 		
			EndIf;
			
			AreaTableHeaderProductColumn 	= Template.GetArea("TableHeader|ProductColumn_");
			AreaTableRowProductColumn 	= Template.GetArea("TableRow|ProductColumn_");
			AreaBasementTableGoodsColumn 	= Template.GetArea("TableFooter|ProductColumn_");
			
			TableHeaderAreaEnd 	= Template.GetArea("TableHeader|EndOfRow");
			AreaTableRowEnd 	= Template.GetArea("TableRow|EndOfRow");
			AreaBasementTableEnd 	= Template.GetArea("TableFooter|EndOfRow");
			
			SamplingByTSLines = SelectionByTableParts.Select(QueryResultIteration.ByGroups);
			
			If Not FirstDocument Then
				SpreadsheetDocument.PutHorizontalPageBreak();
			EndIf;
			
			// Output the header of the tabular document
			FirstDocument = False;
			RowNumberStart = SpreadsheetDocument.TableHeight + 1;
				
			If AddressStorageSenderIsUsed Then
				
				ShippingZoneText = NStr("vi = 'Khu vực giao hàng:';
										|ru = 'Зона отгрузки:';
										|en = 'Outbound area:'; fa = 'ناحیه خروجی:';
										|it = 'Area di spedizione:';
										|pl = 'Strefa wysyłki:';
										|tr = 'Yükleme alanı:'", Common.DefaultLanguageCode());
				ShippingZonePresentation = SelectionByDocuments.ShipmentAreaPresentation;
				
			Else
				
				ShippingZoneText = "";
				ShippingZonePresentation = "";
				
			EndIf;
			
			If AddressStorageReceiverIsUsed Then
				
				TextOfAcceptanceZone = NStr("vi = 'Khu vực tiếp nhận:';
											|ru = 'Зона приемки:';
											|en = 'Inbound area:'; fa = 'ناحیه ورودی:';
											|it = 'Area di accettazione:';
											|pl = 'Stefa przyjęcia:';
											|tr = 'Boşaltma alanı:'", Common.DefaultLanguageCode());
				ReceivingAreaPresentation = SelectionByDocuments.PresentationOfAcceptanceArea;
				
			Else
				
				TextOfAcceptanceZone = "";
				ReceivingAreaPresentation = "";
				
			EndIf;
			
			FillPropertyValues(DocumentAttributes,SelectionByDocuments);
			
			HeaderArea_.Parameters.TitleText = TMCommonUseClientServer.GenerateDocumentTitle(DocumentAttributes, DocumentSynonym);
			
			BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, HeaderArea_, SelectionByDocuments.Ref);
			SpreadsheetDocument.Put(HeaderArea_);
			
			SectionHeader.Parameters.Fill(SelectionByDocuments);	
			SectionHeader.Parameters.TextOfAcceptanceZone 			= TextOfAcceptanceZone;
			SectionHeader.Parameters.PresentationOfAcceptanceArea 	= ReceivingAreaPresentation;
			SectionHeader.Parameters.ShippingZoneText 			= ShippingZoneText;
			SectionHeader.Parameters.ShipmentAreaPresentation 	= ShippingZonePresentation;
			
			SpreadsheetDocument.Put(SectionHeader);
			
			// Output the header of the nomenclature table
			ParametersStructure = StructureOfOutputParametersOfProductTableRow();
			ParametersStructure.SpreadsheetDocument 		= SpreadsheetDocument;
			ParametersStructure.OutputCodes 			= OutputCodes;
			ParametersStructure.DisplayingPackages 		= DisplayingPackages;
			ParametersStructure.AreaBegin 			= TableHeaderAreaStart;
			ParametersStructure.AreaColumnCodes 	= AreaTableHeaderCodeColumn;
			ParametersStructure.ProductColumnArea_ 	= AreaTableHeaderProductColumn;
			ParametersStructure.PackagingColumnArea 	= AreaTableHeaderPackingColumn;
			ParametersStructure.AreaEnd 			= TableHeaderAreaEnd;
			
			DisplayRowInProductTable(ParametersStructure);

			TotalItems_1 = 0;
			
			// Let's create a tabular document for an unloaded item
			DoNotShipTabularDocument = New SpreadsheetDocument;
			TotalItemsDoNotShip = 0;
			
			SelectionBasedOnDonTShipParameter = SelectionByTableParts.Select(QueryResultIteration.ByGroups);
			
			While SelectionBasedOnDonTShipParameter.Next() Do
				
				SamplingByTSLinks = SelectionBasedOnDonTShipParameter.Select(QueryResultIteration.ByGroups);
				
				While SamplingByTSLinks.Next() Do
					
					SamplingByTSProduct = SamplingByTSLinks.Select(QueryResultIteration.ByGroups);
					
					While SamplingByTSProduct.Next() Do
						
						SamplingByTSLines = SamplingByTSProduct.Select(QueryResultIteration.ByGroups);
						
						FirstRow = True;
						StringOfPackages = "";
						StringQuantityOfPackages = "";
						UnitString = "";
						CountRow = "";
						
						While SamplingByTSLines.Next() Do
							
							If SamplingByTSLines.BatchUsageSettings = Enums.ItemsBatchUsageSettings.InventoryItem Then
								
								If FirstRow Then
									
									// Let's determine in which tabular document we output the nomenclature
									If SamplingByTSLines.DoNotShip = 0 Then
										TabularDocumentForStringOutput = SpreadsheetDocument;
										TotalItems_1 				 = TotalItems_1 + 1;
										LineNumber 					 = TotalItems_1;
									Else
										TabularDocumentForStringOutput = DoNotShipTabularDocument;
										TotalItemsDoNotShip 	 = TotalItemsDoNotShip + 1;
										LineNumber 					 = TotalItemsDoNotShip;
									EndIf;
									
									AreaTableRowStart.Parameters.Fill(SamplingByTSLines);
									AreaTableRowStart.Parameters.LineNumber = LineNumber;
									
									If OutputCodes Then
										AreaTableRowCodeColumn.Parameters.SKU = SamplingByTSLines.AdditionalColumn;
									EndIf;
									
									TheStructureOfTheSearch = New Structure;
									TheStructureOfTheSearch.Insert("Ref", SamplingByTSLines.Ref);
									TheStructureOfTheSearch.Insert("Products", SamplingByTSLines.Products);
									TheStructureOfTheSearch.Insert("Characteristic", SamplingByTSLines.Characteristic);
									TheStructureOfTheSearch.Insert("DoNotShip", SamplingByTSLines.DoNotShip);
									
									SeriesString = "";
									While SelectionBySeries.FindNext(TheStructureOfTheSearch) Do
										SeriesString = SeriesString + SelectionBySeries.BatchPresentation + ", ";
									EndDo;
									
									If StrLen(SeriesString) <> 0 Then
										SeriesString = Left(SeriesString, StrLen(SeriesString) - 2);
									EndIf;
									
									AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
									AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
									
									AreaTableRowProductColumn.Parameters.OwnGoods = ProductsClientServer.PresentationOfProductsForPrinting(
										SamplingByTSLines.ProductPresentation,
										SamplingByTSLines.CharacteristicPresentation,
										, // Package
										SeriesString,
										AdditionalParametersProductPresentation);
									
									FirstRow = False;
									
									ProductWithSeriesInstance = True;
									
								EndIf;
								
								If DisplayingPackages Then
									StringOfPackages = StringOfPackages + SamplingByTSLines.PresentationOfPackingUnit + Chars.LF;
									StringQuantityOfPackages = StringQuantityOfPackages + SamplingByTSLines.NumberOfPackages + Chars.LF;
								EndIf;
								
								UnitString = UnitString + SamplingByTSLines.PresentationOfBasicUnitOfMeasure + Chars.LF;
								CountRow = CountRow + SamplingByTSLines.Count + Chars.LF;
								
							Else
								
								// Let's determine in which tabular document we output the nomenclature
								If SamplingByTSLines.DoNotShip = 0 Then
									TabularDocumentForStringOutput = SpreadsheetDocument;
									TotalItems_1 				 = TotalItems_1 + 1;
									LineNumber 					 = TotalItems_1;
								Else
									TabularDocumentForStringOutput = DoNotShipTabularDocument;
									TotalItemsDoNotShip 	 = TotalItemsDoNotShip + 1;
									LineNumber 					 = TotalItemsDoNotShip;
								EndIf;
								
								AreaTableRowStart.Parameters.Fill(SamplingByTSLines);
								AreaTableRowStart.Parameters.LineNumber = LineNumber;
								
								If OutputCodes Then
									AreaTableRowCodeColumn.Parameters.SKU = SamplingByTSLines.AdditionalColumn;
								EndIf;
								
								AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
								AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
								
								AreaTableRowProductColumn.Parameters.OwnGoods = ProductsClientServer.PresentationOfProductsForPrinting(
									SamplingByTSLines.ProductPresentation,
									SamplingByTSLines.CharacteristicPresentation,
									, // Package
									SamplingByTSLines.BatchPresentation,
									AdditionalParametersProductPresentation);
								
								If DisplayingPackages Then
									AreaTableRowPackingColumn.Parameters.Fill(SamplingByTSLines);
								EndIf;
								
								AreaTableRowEnd.Parameters.Fill(SamplingByTSLines);
																
								ParametersStructure = StructureOfOutputParametersOfProductTableRow();
								ParametersStructure.SpreadsheetDocument 		= TabularDocumentForStringOutput;
								ParametersStructure.OutputCodes 			= OutputCodes;
								ParametersStructure.DisplayingPackages 		= DisplayingPackages;
								ParametersStructure.AreaBegin 			= AreaTableRowStart;
								ParametersStructure.AreaColumnCodes 	= AreaTableRowCodeColumn;
								ParametersStructure.ProductColumnArea_ 	= AreaTableRowProductColumn;
								ParametersStructure.PackagingColumnArea 	= AreaTableRowPackingColumn;
								ParametersStructure.AreaEnd 			= AreaTableRowEnd;
								
								DisplayRowInProductTable(ParametersStructure);
									
								ProductWithSeriesInstance = False;	
									
							EndIf;
						EndDo;
						
						If ProductWithSeriesInstance Then
							
							If DisplayingPackages Then
								AreaTableRowPackingColumn.Parameters.NumberOfPackages = StringQuantityOfPackages;
								AreaTableRowPackingColumn.Parameters.PresentationOfPackingUnit = StringOfPackages;
							EndIf;
							
							AreaTableRowEnd.Parameters.Count = CountRow;
							AreaTableRowEnd.Parameters.PresentationOfBasicUnitOfMeasure = UnitString;
							
							ParametersStructure = StructureOfOutputParametersOfProductTableRow();
							ParametersStructure.SpreadsheetDocument 		= TabularDocumentForStringOutput;
							ParametersStructure.OutputCodes 			= OutputCodes;
							ParametersStructure.DisplayingPackages 		= DisplayingPackages;
							ParametersStructure.AreaBegin 			= AreaTableRowStart;
							ParametersStructure.AreaColumnCodes 	= AreaTableRowCodeColumn;
							ParametersStructure.ProductColumnArea_ 	= AreaTableRowProductColumn;
							ParametersStructure.PackagingColumnArea 	= AreaTableRowPackingColumn;
							ParametersStructure.AreaEnd 			= AreaTableRowEnd;
							
							DisplayRowInProductTable(ParametersStructure);
														
						EndIf;
						
					EndDo;
					
				EndDo;
				
			EndDo;
						
			// Output the table's basement and captions			
			ParametersStructure = StructureOfOutputParametersOfProductTableRow();
			ParametersStructure.SpreadsheetDocument 		= SpreadsheetDocument;
			ParametersStructure.OutputCodes 			= OutputCodes;
			ParametersStructure.DisplayingPackages 		= DisplayingPackages;
			ParametersStructure.AreaBegin 			= AreaBasementTableTop;
			ParametersStructure.AreaColumnCodes 	= AreaBasementTableColumnCodes;
			ParametersStructure.ProductColumnArea_ 	= AreaBasementTableGoodsColumn;
			ParametersStructure.PackagingColumnArea 	= AreaBasementTablePackingColumn;
			ParametersStructure.AreaEnd 			= AreaBasementTableEnd;
			
			DisplayRowInProductTable(ParametersStructure);
						
			SignatureArea.Parameters.EmployeeResponsiblePresentation = PersonsTM.IndividualShortName(SelectionByDocuments.EmployeeResponsible, SelectionByDocuments.Date);
			
			SpreadsheetDocument.Put(SignatureArea);
			
			// Let's supplement the main tabular document with a table of non-downloadable nomenclature
			If TotalItemsDoNotShip > 0 Then
				
				// Let's output the title and header of the table of the non-loaded nomenclature
				TitleText = NStr("vi = 'Trong khu vực giao hàng cần đặt các mặt hàng sau';
								|ru = 'В зоне отгрузки необходимо оставить следующие позиции товаров';
								|en = 'The following goods items should be left in the outbound area'; fa = 'The following goods items should be left in the outbound area';
								|it = 'Nella area di spedizione, è necessario lasciare i seguenti articoli di merce';
								|pl = 'W strefie wysyłki należy zostawić następujące pozycje towarów';
								|tr = 'Aşağıdaki ürün pozisyonları yükleme alanında bırakılmalıdır'",
					Common.DefaultLanguageCode());
				AreaHeaderDoNotShip.Parameters.TitleText = TitleText;
				SpreadsheetDocument.Put(AreaHeaderDoNotShip);
				
				ParametersStructure = StructureOfOutputParametersOfProductTableRow();
				ParametersStructure.SpreadsheetDocument 		= SpreadsheetDocument;
				ParametersStructure.OutputCodes 			= OutputCodes;
				ParametersStructure.DisplayingPackages 		= DisplayingPackages;
				ParametersStructure.AreaBegin 			= TableHeaderAreaStart;
				ParametersStructure.AreaColumnCodes 	= AreaTableHeaderCodeColumn;
				ParametersStructure.ProductColumnArea_ 	= AreaTableHeaderProductColumn;
				ParametersStructure.PackagingColumnArea 	= AreaTableHeaderPackingColumn;
				ParametersStructure.AreaEnd 			= TableHeaderAreaEnd;
				
				DisplayRowInProductTable(ParametersStructure);
								
				// Let's attach the table of non-downloadable nomenclature to the main tabular document
				SpreadsheetDocument.Put(DoNotShipTabularDocument);
				
				// Let's output the basement of the table of non-loaded nomenclature
				ParametersStructure = StructureOfOutputParametersOfProductTableRow();
				ParametersStructure.SpreadsheetDocument 		= SpreadsheetDocument;
				ParametersStructure.OutputCodes 			= OutputCodes;
				ParametersStructure.DisplayingPackages 		= DisplayingPackages;
				ParametersStructure.AreaBegin 			= AreaBasementTableTop;
				ParametersStructure.AreaColumnCodes 	= AreaBasementTableColumnCodes;
				ParametersStructure.ProductColumnArea_ 	= AreaBasementTableGoodsColumn;
				ParametersStructure.PackagingColumnArea 	= AreaBasementTablePackingColumn;
				ParametersStructure.AreaEnd 			= AreaBasementTableEnd;
				
				DisplayRowInProductTable(ParametersStructure);
								
			EndIf;
			
			PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, SelectionByDocuments.Ref);
			
		EndDo;
		
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
	Return SpreadsheetDocument;	
	
EndFunction

Procedure DisplayRowInProductTable(ParametersStructure)
	
	SpreadsheetDocument 		= ParametersStructure.SpreadsheetDocument;
	OutputCodes 			= ParametersStructure.OutputCodes;
	DisplayingPackages 		= ParametersStructure.DisplayingPackages;
	AreaBegin 			= ParametersStructure.AreaBegin;
	AreaColumnCodes 	= ParametersStructure.AreaColumnCodes;
	ProductColumnArea_ 	= ParametersStructure.ProductColumnArea_;
	PackagingColumnArea 	= ParametersStructure.PackagingColumnArea;
	AreaEnd 			= ParametersStructure.AreaEnd;	
	
	SpreadsheetDocument.Put(AreaBegin);
	
	If OutputCodes Then
		SpreadsheetDocument.Join(AreaColumnCodes);
	EndIf;
	
	SpreadsheetDocument.Join(ProductColumnArea_);
	
	If DisplayingPackages Then
		SpreadsheetDocument.Join(PackagingColumnArea);
	EndIf;
	
	SpreadsheetDocument.Join(AreaEnd);
	
EndProcedure

Function StructureOfOutputParametersOfProductTableRow()
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("SpreadsheetDocument");
	ParametersStructure.Insert("OutputCodes");
	ParametersStructure.Insert("DisplayingPackages");
	ParametersStructure.Insert("AreaBegin");
	ParametersStructure.Insert("AreaColumnCodes");
	ParametersStructure.Insert("ProductColumnArea_");
	ParametersStructure.Insert("PackagingColumnArea");
	ParametersStructure.Insert("AreaEnd");
	
	Return ParametersStructure;
	
EndFunction

// Returns the document data structure used for printing the printed form of the product selection (placement) Task.
//
// Parameters:
//	PrintParameters	- Structure	- additional print options.
//	ObjectsArray	- Array	- links to objects that need to be printed.
//	
// Returns:
//	Structure - a structure with the following keys:
//		*ErrorResults			- Undefined		- errors in document data that make it impossible
//															to print the document.
//		*ResultOnOrders	- Undefined		- information about orders for document shipment.
//		*HeaderResults			- QueryResult	- data of the document header used for printing the Task
//															for selecting (placing) products.
//		*ResultForTabularPart	- QueryResult	- data of the product part of the document used for printing
//															Tasks for selecting (placing) products.
//		*ResultForPackages		- Undefined		- data about product packages in the table part of the document
//															used for printing the Task for selecting (placing) products.
//		*ResultBySeries			- QueryResult	- data about product series in the table part of the document
//															used for printing the Task for selecting (placing) products.
//
Function GetDataForPrintedFormForProductPlacement(PrintParameters, ObjectsArray) Export
	
	PackingList_ = Not PrintParameters.Property("NoExtraCharge");
	
	QueryText = RequestTextProductsTasksSelectionProductPlacement(PackingList_)
					+ Common.QueryBatchSeparator() +
	"SELECT
	|	GoodsTable.Ref					AS Ref,
	|	GoodsTable.Warehouse						AS Warehouse,
	|	GoodsTable.Premise					AS Premise,
	|	MIN(GoodsTable.LineNumber)		AS LineNumber,
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
	|	TaskItems_ AS GoodsTable
	|
	|GROUP BY
	|	GoodsTable.Ref,
	|	GoodsTable.Warehouse,
	|	GoodsTable.Premise,
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
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TaskData_.Ref								AS Ref,
	|	PRESENTATION(TaskData_.Ref)					AS RefPresentation,
	|	TaskData_.Number									AS Number,
	|	&HeaderDate_											AS Date,
	|	TaskData_.Warehouse									AS Warehouse,
	|	PRESENTATION(TaskData_.Warehouse)					AS WarehousePresentation,
	|	PRESENTATION(TaskData_.ReceivingWareroom)	AS PremisePresentation,
	|	FALSE												AS ThisIsAnInvoice,
	|	CASE
	|		WHEN TaskData_.Warehouse.UseWarerooms
	|				AND &HeaderDate_ >= TaskData_.Warehouse.StartDateOfWareroomUse
	|			THEN CASE
	|					WHEN TaskData_.ReceivingWareroom.UseBinLocationWarehousing
	|							AND &HeaderDate_ >= TaskData_.ReceivingWareroom.StartDateOfUsingWarehouseBinSystem
	|						THEN TRUE
	|					ELSE FALSE
	|				END
	|		ELSE CASE
	|				WHEN TaskData_.Warehouse.UseBinLocationWarehousing
	|						AND &HeaderDate_ >= TaskData_.Warehouse.StartDateOfUsingWarehouseBinSystem
	|					THEN TRUE
	|				ELSE FALSE
	|			END
	|	END												AS BinLocationWarehousingIsUsed,
	|	CASE
	|		WHEN TaskData_.Warehouse.UseWarerooms
	|				AND &HeaderDate_ >= TaskData_.Warehouse.StartDateOfWareroomUse
	|			THEN CASE
	|					WHEN TaskData_.ReceivingWareroom.UseBinLocationWarehousingForInformation
	|							AND (NOT TaskData_.ReceivingWareroom.UseBinLocationWarehousing
	|								OR &HeaderDate_ < TaskData_.ReceivingWareroom.StartDateOfUsingWarehouseBinSystem)
	|						THEN TRUE
	|					ELSE FALSE
	|				END
	|		ELSE CASE
	|				WHEN TaskData_.Warehouse.UseBinLocationWarehousingForInformation
	|						AND (NOT TaskData_.Warehouse.UseBinLocationWarehousing
	|							OR &HeaderDate_ < TaskData_.Warehouse.StartDateOfUsingWarehouseBinSystem)
	|					THEN TRUE
	|				ELSE FALSE
	|			END
	|	END												AS ReferenceStorageIsUsed,
	|	CASE
	|		WHEN TaskData_.Warehouse.UseWarerooms
	|				AND &HeaderDate_ >= TaskData_.Warehouse.StartDateOfWareroomUse
	|			THEN TaskData_.ReceivingWareroom.WarehouseZoneUsage
	|		ELSE TaskData_.Warehouse.WarehouseZoneUsage
	|	END												AS WarehouseZoneUsage,
	|	FALSE												AS AdvancedWarehousingIsUsed
	|FROM
	|	Document.GoodsTransferNote AS TaskData_
	|
	|WHERE
	|	TaskData_.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Ref,
	|	Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
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
	|	TableOfGoods.LineNumber							AS LineNumber,
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
	|						AND &DateTS >= TableOfGoods.Warehouse.StartDateOfWareroomUse
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
	|						AND &DateTS >= TableOfGoods.Warehouse.StartDateOfWareroomUse
	|					THEN TableOfGoods.Premise = OtherCells.Premise
	|				ELSE OtherCells.Premise = VALUE(Catalog.Warerooms.EmptyRef)
	|			END
	|
	|ORDER BY
	|	Ref,
	|	Warehouse,
	|	WarehouseZone,
	|	LineNumber,
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
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.Ref				AS Ref,
	|	TableOfGoods.Warehouse				AS Warehouse,
	|	ISNULL(MainStorageBins.Cell.WarehouseZone, &DefaultWorkArea)	AS WarehouseZone,
	|	TableOfGoods.LineNumber			AS LineNumber,
	|	TableOfGoods.Products			AS Products,
	|	TableOfGoods.Characteristic		AS Characteristic,
	|	TableOfGoods.Series.Description	AS BatchPresentation
	|FROM
	|	TaskItems_ AS TableOfGoods
	|		LEFT JOIN InformationRegister.PlaceProductsInStorageBins AS MainStorageBins
	|		ON TableOfGoods.Products = MainStorageBins.Products
	|			AND MainStorageBins.MainStorageBin
	|			AND TableOfGoods.Warehouse = MainStorageBins.Warehouse
	|			AND CASE
	|				WHEN TableOfGoods.Warehouse.UseWarerooms
	|						AND &DateTS >= TableOfGoods.Warehouse.StartDateOfWareroomUse
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
	|	LineNumber,
	|	Products,
	|	Characteristic";
	
	SettingPlacement	= PrintParameters.JobType = "PlacementJob";
	DateField_			= ?(SettingPlacement, "Date", "DateOfShipment");
	RoomField		= ?(SettingPlacement, "ReceivingWareroom", "SenderWareroom");
	
	QueryText = StrReplace(QueryText, "&HeaderDate_",			"TaskData_." + DateField_);
	QueryText = StrReplace(QueryText, "&DateTS",				"TableOfGoods.Ref." + DateField_);
	QueryText = StrReplace(QueryText, "ReceivingWareroom",	RoomField);
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
	Query.SetParameter("ObjectsArray", ObjectsArray);
	
	SetPrivilegedMode(True);
	Result = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	MaxIndex = Result.UBound();
	
	TaskData_ = New Structure;
	TaskData_.Insert("ErrorResults",		Undefined);
	TaskData_.Insert("ResultOnOrders",	Undefined);
	TaskData_.Insert("HeaderResults",			Result[MaxIndex - 2]);
	TaskData_.Insert("ResultForTabularPart",	Result[MaxIndex - 1]);
	TaskData_.Insert("ResultForPackages",		Undefined);
	TaskData_.Insert("ResultBySeries",			Result[MaxIndex]);
	
	Return TaskData_;
	
EndFunction

Function RequestTextProductsTasksSelectionProductPlacement(PackingList_)
	
	If PackingList_ Then
		
		QueryText =
		"SELECT
		|	DocumentData.Ref						AS Ref,
		|	DocumentData.Warehouse						AS Warehouse,
		|	DocumentData.ReceivingWareroom			AS Premise,
		|	MIN(DocumentGoods.LineNumber)		AS LineNumber,
		|	DocumentGoods.Products				AS Products,
		|	DocumentGoods.Characteristic				AS Characteristic,
		|	DocumentGoods.Series						AS Series,
		|	DocumentGoods.Package					AS Package,
		|	SUM(DocumentGoods.Count)			AS Count,
		|	SUM(DocumentGoods.NumberOfPackages)	AS NumberOfPackages
		|INTO TaskItems_
		|FROM
		|	Document.GoodsTransferNote.ShippedGoods AS DocumentGoods
		|		LEFT JOIN Document.GoodsTransferNote AS DocumentData
		|		ON DocumentGoods.Ref = DocumentData.Ref
		|
		|WHERE
		|	DocumentGoods.Ref IN(&ObjectsArray)
		|	AND DocumentGoods.Action <> VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip)
		|
		|GROUP BY
		|	DocumentData.Ref,
		|	DocumentData.Warehouse,
		|	DocumentData.ReceivingWareroom,
		|	DocumentGoods.Products,
		|	DocumentGoods.Characteristic,
		|	DocumentGoods.Series,
		|	DocumentGoods.Package";
		
	Else
		
		QueryText =
		"SELECT
		|	DocumentData.Ref						AS Ref,
		|	DocumentData.Warehouse						AS Warehouse,
		|	DocumentData.ReceivingWareroom			AS Premise,
		|	MIN(DocumentGoods.LineNumber)		AS LineNumber,
		|	DocumentGoods.Products				AS Products,
		|	DocumentGoods.Characteristic				AS Characteristic,
		|	DocumentGoods.Series						AS Series,
		|	&DefaultPackaging						AS Package,
		|	SUM(DocumentGoods.Count)			AS Count,
		|	SUM(DocumentGoods.NumberOfPackages)	AS NumberOfPackages
		|INTO TaskItems_
		|FROM
		|	Document.GoodsTransferNote.ShippedGoods AS DocumentGoods
		|		LEFT JOIN Document.GoodsTransferNote AS DocumentData
		|		ON DocumentGoods.Ref = DocumentData.Ref
		|
		|WHERE
		|	DocumentGoods.Ref IN(&ObjectsArray)
		|	AND DocumentGoods.Action <> VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip)
		|	AND ISNULL(DocumentGoods.Package.PackageType, UNDEFINED) <> VALUE(Enum.TypesOfItemsPackages.CargoItem)
		|
		|GROUP BY
		|	DocumentData.Ref,
		|	DocumentData.Warehouse,
		|	DocumentData.ReceivingWareroom,
		|	DocumentGoods.Products,
		|	DocumentGoods.Characteristic,
		|	DocumentGoods.Series,
		|	&DefaultPackaging
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Ref					AS Ref,
		|	DocumentData.Warehouse					AS Warehouse,
		|	DocumentData.ReceivingWareroom		AS Premise,
		|	MIN(DocumentGoods.LineNumber)	AS LineNumber,
		|	GoodsWithoutPackaging_.Products			AS Products,
		|	GoodsWithoutPackaging_.Characteristic		AS Characteristic,
		|	GoodsWithoutPackaging_.Series					AS Series,
		|	&DefaultPackaging					AS Package,
		|	SUM(DocumentGoods.Count)		AS Count,
		|	SUM(DocumentGoods.Count)		AS NumberOfPackages
		|FROM
		|	(SELECT
		|		DocumentGoods.Ref				AS Ref,
		|		DocumentGoods.Products		AS Products,
		|		DocumentGoods.Characteristic		AS Characteristic,
		|		DocumentGoods.Purpose			AS Purpose,
		|		DocumentGoods.Series				AS Series,
		|		MAX(DocumentGoods.Package)	AS Package
		|	FROM
		|		Document.GoodsTransferNote.ShippedGoods AS DocumentGoods
		|	
		|	WHERE
		|		DocumentGoods.Ref IN(&ObjectsArray)
		|		AND DocumentGoods.Action <> VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip)
		|		AND ISNULL(DocumentGoods.Package.PackageType, UNDEFINED) = VALUE(Enum.TypesOfItemsPackages.CargoItem)
		|	
		|	GROUP BY
		|		DocumentGoods.Ref,
		|		DocumentGoods.Products,
		|		DocumentGoods.Characteristic,
		|		DocumentGoods.Purpose,
		|		DocumentGoods.Series
		|	
		|	) AS GoodsWithoutPackaging_
		|		INNER JOIN Document.GoodsTransferNote.ShippedGoods AS DocumentGoods
		|		ON GoodsWithoutPackaging_.Ref = DocumentGoods.Ref
		|			AND GoodsWithoutPackaging_.Products = DocumentGoods.Products
		|			AND GoodsWithoutPackaging_.Characteristic = DocumentGoods.Characteristic
		|			AND GoodsWithoutPackaging_.Purpose = DocumentGoods.Purpose
		|			AND GoodsWithoutPackaging_.Series = DocumentGoods.Series
		|			AND GoodsWithoutPackaging_.Package = DocumentGoods.Package
		|		
		|		LEFT JOIN Document.GoodsTransferNote AS DocumentData
		|		ON GoodsWithoutPackaging_.Ref = DocumentData.Ref
		|
		|GROUP BY
		|	DocumentData.Ref,
		|	DocumentData.Warehouse,
		|	DocumentData.ReceivingWareroom,
		|	GoodsWithoutPackaging_.Products,
		|	GoodsWithoutPackaging_.Characteristic,
		|	GoodsWithoutPackaging_.Series,
		|	&DefaultPackaging";
		
		QueryText = StrReplace(QueryText,
									"&DefaultPackaging",
									"VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)");
		
	EndIf;
	
	Return QueryText;
	
EndFunction

Function QueryTextTTTableProducts(Query, QueryTexts)
	
	RegisterName = "TTTableProducts";
		
	QueryText = 
	"SELECT
	|	ShippedGoods.Products,
	|	ShippedGoods.Characteristic,
	|	ShippedGoods.Purpose,
	|	ShippedGoods.Series,
	|	ShippedGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	ShippedGoods.Action,
	|	ShippedGoods.Count
	|INTO TTTableProducts
	|FROM
	|	Document.GoodsTransferNote.ShippedGoods AS ShippedGoods
	|WHERE
	|	ShippedGoods.Ref = &Ref
	|	AND ISNULL(ShippedGoods.Package.PackageType, UNDEFINED) <> VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.Purpose,
	|	Table.Series,
	|	Table.BatchesIndicationStatus,
	|	Table.Action,
	|	SUM(ShippedGoodsQuantity.Count)
	|FROM
	|	(SELECT
	|		ShippedGoodsPackage.Ref AS Ref,
	|		ShippedGoodsPackage.Products AS Products,
	|		ShippedGoodsPackage.Characteristic AS Characteristic,
	|		ShippedGoodsPackage.Purpose AS Purpose,
	|		ShippedGoodsPackage.Series AS Series,
	|		MAX(ShippedGoodsPackage.Package) AS Package,
	|		ShippedGoodsPackage.Action AS Action,
	|		ShippedGoodsPackage.BatchesIndicationStatus AS BatchesIndicationStatus
	|	FROM
	|		Document.GoodsTransferNote.ShippedGoods AS ShippedGoodsPackage
	|	WHERE
	|		ShippedGoodsPackage.Ref = &Ref
	|		AND ISNULL(ShippedGoodsPackage.Package.PackageType, UNDEFINED) = VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|	
	|	GROUP BY
	|		ShippedGoodsPackage.Ref,
	|		ShippedGoodsPackage.Products,
	|		ShippedGoodsPackage.Characteristic,
	|		ShippedGoodsPackage.Purpose,
	|		ShippedGoodsPackage.Action,
	|		ShippedGoodsPackage.Series,
	|		ShippedGoodsPackage.BatchesIndicationStatus) AS Table
	|		INNER JOIN Document.GoodsTransferNote.ShippedGoods AS ShippedGoodsQuantity
	|		ON Table.Ref = ShippedGoodsQuantity.Ref
	|			AND Table.Products = ShippedGoodsQuantity.Products
	|			AND Table.Characteristic = ShippedGoodsQuantity.Characteristic
	|			AND Table.Series = ShippedGoodsQuantity.Series
	|			AND Table.Purpose = ShippedGoodsQuantity.Purpose
	|			AND Table.Package = ShippedGoodsQuantity.Package
	|			AND Table.Action = ShippedGoodsQuantity.Action
	|
	|GROUP BY
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.Purpose,
	|	Table.Series,
	|	Table.Action,
	|	Table.BatchesIndicationStatus";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
