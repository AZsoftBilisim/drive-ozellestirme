#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

#EndRegion

#Region Public

// Code of procedures and functions

#EndRegion

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	TempTablesManager = New TempTablesManager;
	
	Query = New Query;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	Table.Products          AS Products,
	|	Table.Characteristic        AS Characteristic,
	|	Table.Warehouse                 AS Warehouse,
	|	Table.Purpose            AS Purpose,
	|	Table.ProductionOrder   AS ProductionOrder,
	|	Table.KeyProducts      AS KeyProducts,
	|	Table.Stage                  AS Stage,
	|	Table.DateOfReceipt       AS DateOfReceipt,
	|	Table.ReceiptOrder    AS ReceiptOrder,
	|	Table.BillOfMaterials          AS BillOfMaterials,
	|	Table.DemandDate       AS DemandDate,
	|	Table.Lot                AS Lot,
	|	Table.Department         AS Department,
	|	Table.DurationBeforeProductionIssue AS DurationBeforeProductionIssue,
	|	Table.ToProduce         AS ToProduce,
	|	Table.ReverseKittingStarted      AS ReverseKittingStarted,
	|	Table.ReverseKittingCompleted        AS ReverseKittingCompleted,
	|	Table.Launched              AS Launched,
	|	Table.Done                AS Done
	|INTO RegisteredRecordsOfProductionOrdersBeforeRecording
	|FROM
	|	InformationRegister.ProductionOrders AS Table
	|WHERE
	|	Table.Recorder = &Recorder
	|;";
	Query.Execute();

	SetOrderBlocking(TempTablesManager);
	
	AdditionalProperties.Insert("TemporaryTablesForCalculatingStateOfProductsOfOrder", TempTablesManager);
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.TempTablesManager = AdditionalProperties.TemporaryTablesForCalculatingStateOfProductsOfOrder;
	Query.Text =
	"SELECT
	|	ChangesTable.Products         AS Products,
	|	ChangesTable.Characteristic       AS Characteristic,
	|	ChangesTable.Warehouse                AS Warehouse,
	|	ChangesTable.Purpose           AS Purpose,
	|	ChangesTable.ProductionOrder  AS ProductionOrder,
	|	SUM(ChangesTable.ToProduce) AS ToProduce,
	|	SUM(ChangesTable.ToProduceUpdate) AS ToProduceUpdate
	|INTO RegisteredRecordsProductionOrdersChanges
	|FROM
	|	(SELECT
	|		Table.Products          AS Products,
	|		Table.Characteristic        AS Characteristic,
	|		Table.Warehouse                 AS Warehouse,
	|		Table.Purpose            AS Purpose,
	|		Table.ProductionOrder   AS ProductionOrder,
	|		Table.KeyProducts      AS KeyProducts,
	|		Table.Stage                  AS Stage,
	|		Table.DateOfReceipt       AS DateOfReceipt,
	|		Table.ReceiptOrder    AS ReceiptOrder,
	|		Table.BillOfMaterials          AS BillOfMaterials,
	|		Table.DemandDate       AS DemandDate,
	|		Table.Lot                AS Lot,
	|		Table.Department         AS Department,
	|		Table.DurationBeforeProductionIssue AS DurationBeforeProductionIssue,
	|		0                             AS ToProduce,
	|		-Table.ToProduce        AS ToProduceUpdate,
	|		-Table.ReverseKittingStarted     AS ReverseKittingStartedUpdate,
	|		-Table.ReverseKittingCompleted       AS ReverseKittingCompletedUpdate,
	|		-Table.Launched             AS LaunchedUpdate,
	|		-Table.Done               AS DoneUpdate
	|	FROM
	|		RegisteredRecordsOfProductionOrdersBeforeRecording AS Table
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Products          AS Products,
	|		Table.Characteristic        AS Characteristic,
	|		Table.Warehouse                 AS Warehouse,
	|		Table.Purpose            AS Purpose,
	|		Table.ProductionOrder   AS ProductionOrder,
	|		Table.KeyProducts      AS KeyProducts,
	|		Table.Stage                  AS Stage,
	|		Table.DateOfReceipt       AS DateOfReceipt,
	|		Table.ReceiptOrder    AS ReceiptOrder,
	|		Table.BillOfMaterials          AS BillOfMaterials,
	|		Table.DemandDate       AS DemandDate,
	|		Table.Lot                AS Lot,
	|		Table.Department         AS Department,
	|		Table.DurationBeforeProductionIssue AS DurationBeforeProductionIssue,
	|		Table.ToProduce         AS ToProduce,
	|		Table.ToProduce         AS ToProduceUpdate,
	|		Table.ReverseKittingStarted      AS ReverseKittingStartedUpdate,
	|		Table.ReverseKittingCompleted        AS ReverseKittingCompletedUpdate,
	|		Table.Launched              AS LaunchedUpdate,
	|		Table.Done                AS DoneUpdate
	|	FROM
	|		InformationRegister.ProductionOrders AS Table
	|	WHERE
	|		Table.Recorder = &Recorder) AS ChangesTable
	|
	|GROUP BY
	|	ChangesTable.Products,
	|	ChangesTable.Characteristic,
	|	ChangesTable.Warehouse,
	|	ChangesTable.Purpose,
	|	ChangesTable.ProductionOrder,
	|	ChangesTable.KeyProducts,
	|	ChangesTable.Stage,
	|	ChangesTable.DateOfReceipt,
	|	ChangesTable.ReceiptOrder,
	|	ChangesTable.BillOfMaterials,
	|	ChangesTable.DemandDate,
	|	ChangesTable.Lot,
	|	ChangesTable.Department,
	|	ChangesTable.DurationBeforeProductionIssue
	|
	|HAVING
	|	SUM(ChangesTable.ToProduceUpdate) <> 0
	|		OR SUM(ChangesTable.ReverseKittingStartedUpdate) <> 0
	|		OR SUM(ChangesTable.ReverseKittingCompletedUpdate) <> 0
	|		OR SUM(ChangesTable.LaunchedUpdate) <> 0
	|		OR SUM(ChangesTable.DoneUpdate) <> 0
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Warehouse,
	|	Purpose,
	|	ProductionOrder
	|;
	|DROP RegisteredRecordsOfProductionOrdersBeforeRecording
	|";
	
	QueryResultsArray = Query.ExecuteBatch();
	
	Selection = QueryResultsArray[0].Select();
	
	If Selection.Next() And Selection.Count > 0 Then
		InformationRegisters.ProductionOrders.CalculateStatus(AdditionalProperties.TemporaryTablesForCalculatingStateOfProductsOfOrder,
			"RegisteredRecordsProductionOrdersChanges"); 
	EndIf;

EndProcedure

#EndRegion

#Region Internal

// Code of procedures and functions

#EndRegion

#Region Private

Procedure SetOrderBlocking(TempTablesManager)
	
	Orders = Unload(, "ProductionOrder");
	Orders.GroupBy("ProductionOrder");
	
	Query = New Query();
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("Orders", Orders);
	Query.Text = 
	"SELECT
	|	Orders.ProductionOrder AS ProductionOrder
	|INTO Orders
	|FROM
	|	&Orders AS Orders
	|;
	|SELECT
	|	Table.ProductionOrder AS ProductionOrder
	|FROM
	|	Orders AS Table
	|
	|UNION
	|
	|SELECT
	|	Table.ProductionOrder
	|FROM
	|	RegisteredRecordsOfProductionOrdersBeforeRecording AS Table
	|;
	|";
	QueryResult = Query.Execute();
	
	DataLock = New DataLock();
	LockItem = DataLock.Add("InformationRegister.ProductionOrders");
	LockItem.DataSource = QueryResult;
	LockItem.UseFromDataSource("ProductionOrder", "ProductionOrder");
	DataLock.Lock();
	
EndProcedure

#EndRegion

#Region Initialize

#EndRegion

#EndIf
