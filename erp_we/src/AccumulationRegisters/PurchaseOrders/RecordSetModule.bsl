#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If Not DocumentsPosting.CalculateChanges_(AdditionalProperties) Then
		Return;
	EndIf;
	
	LockForUpdate = True;
	
	// The current state of the set is placed in the temporary table "
	// Movement of goods by loading by recording" in order to get a change in the new set relative to the current one when recording.

	Query = New Query;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.SetParameter("IsNew",    AdditionalProperties.DocumentProperties.IsNew);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.Text =
	"SELECT
	|	Table.PurchaseOrder AS PurchaseOrder,
	|	Table.Products    AS Products,
	|	Table.Characteristic  AS Characteristic,
	|	Table.RowCode       AS RowCode,
	|	Table.Warehouse           AS Warehouse,
	|	CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|			Table.Ordered
	|		ELSE
	|			-Table.Ordered
	|	END                  AS OrderedBeforeWrite,
	|	CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|			Table.ToRegister
	|		ELSE
	|			-Table.ToRegister
	|	END                   AS ToRegisterBeforeWrite,
	|	CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|			Table.ToReceive
	|		ELSE
	|			-Table.ToReceive
	|	END                   AS ToReceiveBeforeWrite
	|INTO SendOrdersToSuppliersBeforeRecording
	|FROM
	|	AccumulationRegister.PurchaseOrders AS Table
	|WHERE
	|	Table.Recorder = &Recorder
	|	AND NOT &IsNew
	|";
	Query.Execute();

EndProcedure

Procedure OnWrite(Cancel, Replacing)

	If DataExchange.Load Or Not DocumentsPosting.CalculateChanges_(AdditionalProperties) Then
		Return;
	EndIf;

	// The change of the new set relative to the current one is calculated taking into account the accumulated changes
	// and placed in a temporary table.
	Query = New Query;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.Text =
	"SELECT
	|	ChangesTable.PurchaseOrder              AS PurchaseOrder,
	|	ChangesTable.Products                 AS Products,
	|	ChangesTable.Characteristic               AS Characteristic,
	|	ChangesTable.RowCode                    AS RowCode,
	|	ChangesTable.Warehouse                        AS Warehouse,
	|	SUM(ChangesTable.OrderedUpdate)     AS OrderedUpdate,
	|	SUM(ChangesTable.ToRegisterUpdate)  AS ToRegisterUpdate,
	|	SUM(ChangesTable.ToReceiveUpdate) AS ToReceiveUpdate
	|INTO MovementOfOrdersToSuppliersChange
	|FROM
	|	(SELECT
	|		Table.PurchaseOrder          AS PurchaseOrder,
	|		Table.Products             AS Products,
	|		Table.Characteristic           AS Characteristic,
	|		Table.RowCode                AS RowCode,
	|		Table.Warehouse                    AS Warehouse,
	|		Table.OrderedBeforeWrite     AS OrderedUpdate,
	|		Table.ToRegisterBeforeWrite  AS ToRegisterUpdate,
	|		Table.ToReceiveBeforeWrite AS ToReceiveUpdate
	|	FROM
	|		SendOrdersToSuppliersBeforeRecording AS Table
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.PurchaseOrder        AS PurchaseOrder,
	|		Table.Products           AS Products,
	|		Table.Characteristic         AS Characteristic,
	|		Table.RowCode              AS RowCode,
	|		Table.Warehouse                  AS Warehouse,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|				-Table.Ordered
	|			ELSE
	|				Table.Ordered
	|		END                  AS OrderedBeforeWrite,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|				-Table.ToRegister
	|			ELSE
	|				Table.ToRegister
	|		END                          AS ToRegisterUpdate,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|				-Table.ToReceive
	|			ELSE
	|				Table.ToReceive
	|		END                          AS ToReceiveUpdate
	|	FROM
	|		AccumulationRegister.PurchaseOrders AS Table
	|	WHERE
	|		Table.Recorder = &Recorder) AS ChangesTable
	|
	|GROUP BY
	|	ChangesTable.PurchaseOrder,
	|	ChangesTable.Products,
	|	ChangesTable.Characteristic,
	|	ChangesTable.RowCode,
	|	ChangesTable.Warehouse
	|
	|HAVING
	|	SUM(ChangesTable.ToRegisterUpdate) <> 0
	|	OR SUM(ChangesTable.OrderedUpdate) <> 0
	|	OR SUM(ChangesTable.ToReceiveUpdate) <> 0
	|;
	|DROP SendOrdersToSuppliersBeforeRecording
	|";
	
	QueryResultsArray = Query.ExecuteBatch();
	QueryResult = QueryResultsArray[0]; // QueryResult
	Selection = QueryResult.Select();
	HasChanges = Selection.Next() And Selection.Count > 0;
	DocumentsPosting.RegisterControlTable(AdditionalProperties,
		"MovementOfOrdersToSuppliersChange", HasChanges);
	
	If HasChanges
		And GetFunctionalOption("UseAllowableDeviationOfMeasuringGoodsShipmentReceiving") Then
	
		Query = New Query;
		Query.SetParameter("AllowableDeviationOfMeasuringGoodsShipmentAndReceiving",
			Constants.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving.Get());
		Query.SetParameter("DimensionalTypesOfUnits",
			Catalogs.PackagesAndUnitsOfMeasure.DimensionalTypesOfUnits());
		Query.TempTablesManager = AdditionalProperties.TempTablesManager;
		
		QueryText = "
		|SELECT
		|	Table.PurchaseOrder,
		|	Table.Products,
		|	Table.Characteristic,
		|	Table.Warehouse
		|INTO RegisteredRecordsOrdersToSuppliersChangeMeasuredGoods
		|FROM
		|	MovementOfOrdersToSuppliersChange AS Table
		|WHERE 
		|	Table.Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfUnits)
		|GROUP BY
		|	Table.PurchaseOrder,
		|	Table.Products,
		|	Table.Characteristic,
		|	Table.Warehouse
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
		// Main table
		QueryText = QueryText + "
		|SELECT
		|	PurchaseOrders.RecordType     AS RecordType,
		|	PurchaseOrders.PurchaseOrder AS PurchaseOrder,
		|	PurchaseOrders.Products    AS Products,
		|	PurchaseOrders.Characteristic  AS Characteristic,
		|	PurchaseOrders.Warehouse           AS Warehouse,
		|	PurchaseOrders.ToRegister     AS ToRegister,
		|	PurchaseOrders.ToReceive    AS ToReceive
		|INTO TTOrdersToSuppliers
		|FROM
		|	AccumulationRegister.PurchaseOrders AS PurchaseOrders
		|	INNER JOIN
		|		MovementOfOrdersToSuppliersChange AS Changes
		|		ON PurchaseOrders.PurchaseOrder   = Changes.PurchaseOrder
		|			AND PurchaseOrders.Products   = Changes.Products
		|			AND PurchaseOrders.Characteristic = Changes.Characteristic
		|			AND PurchaseOrders.Warehouse          = Changes.Warehouse
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
		// Tolerance
		QueryText = QueryText + "
		|SELECT
		|	PurchaseOrders.PurchaseOrder AS PurchaseOrder,
		|	PurchaseOrders.Products    AS Products,
		|	PurchaseOrders.Characteristic  AS Characteristic,
		|	PurchaseOrders.Warehouse           AS Warehouse,
		|	SUM(PurchaseOrders.ToRegister
		|		* (&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100)) AS AllowableVariance,
		|	SUM(PurchaseOrders.ToReceive
		|		* (&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100)) AS ToleranceForAdmission
		|INTO TTAcceptableDeviationsOrdersToSuppliers
		|FROM
		|	TTOrdersToSuppliers AS PurchaseOrders
		|	INNER JOIN
		|		RegisteredRecordsOrdersToSuppliersChangeMeasuredGoods AS Changes
		|		ON PurchaseOrders.PurchaseOrder   = Changes.PurchaseOrder
		|			AND PurchaseOrders.Products   = Changes.Products
		|			AND PurchaseOrders.Characteristic = Changes.Characteristic
		|			AND PurchaseOrders.Warehouse          = Changes.Warehouse
		|WHERE
		|	PurchaseOrders.RecordType = VALUE(AccumulationRecordType.Receipt)
		|GROUP BY
		|	PurchaseOrders.PurchaseOrder,
		|	PurchaseOrders.Products,
		|	PurchaseOrders.Characteristic,
		|	PurchaseOrders.Warehouse
		|INDEX BY
		|	PurchaseOrder,
		|	Products,
		|	Characteristic,
		|	Warehouse
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
		//Balance
		QueryText = QueryText + "
		|SELECT
		|	PurchaseOrders.PurchaseOrder    AS PurchaseOrder,
		|	PurchaseOrders.Products       AS Products,
		|	PurchaseOrders.Characteristic     AS Characteristic,
		|	PurchaseOrders.Warehouse              AS Warehouse,
		|	SUM(CASE WHEN PurchaseOrders.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
		|			PurchaseOrders.ToRegister
		|		ELSE
		|			-PurchaseOrders.ToRegister
		|	END)                               AS ToRegisterBalance,
		|	SUM(CASE WHEN PurchaseOrders.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
		|			PurchaseOrders.ToReceive
		|		ELSE
		|			-PurchaseOrders.ToReceive
		|	END)                               AS ToReceiveBalance
		|INTO TTOrdersToSuppliersBalance
		|FROM
		|	TTOrdersToSuppliers AS PurchaseOrders
		|GROUP BY
		|	PurchaseOrders.PurchaseOrder,
		|	PurchaseOrders.Products,
		|	PurchaseOrders.Characteristic,
		|	PurchaseOrders.Warehouse
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
		QueryText = QueryText + "
		|SELECT DISTINCT
		|	OrdersBalance.PurchaseOrder AS PurchaseOrder
		|FROM
		|	TTOrdersToSuppliersBalance AS OrdersBalance
		|	INNER JOIN
		|		TTAcceptableDeviationsOrdersToSuppliers AS AcceptableDeviations
		|		ON
		|			OrdersBalance.PurchaseOrder  = AcceptableDeviations.PurchaseOrder
		|			AND OrdersBalance.Products   = AcceptableDeviations.Products
		|			AND OrdersBalance.Characteristic = AcceptableDeviations.Characteristic
		|			AND OrdersBalance.Warehouse          = AcceptableDeviations.Warehouse
		|WHERE
		|	OrdersBalance.ToRegisterBalance <= AcceptableDeviations.AllowableVariance
		|	AND OrdersBalance.ToRegisterBalance >= -AcceptableDeviations.AllowableVariance
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	OrdersBalance.PurchaseOrder AS PurchaseOrder
		|FROM
		|	TTOrdersToSuppliersBalance AS OrdersBalance
		|	INNER JOIN
		|		TTAcceptableDeviationsOrdersToSuppliers AS AcceptableDeviations
		|		ON
		|			OrdersBalance.PurchaseOrder  = AcceptableDeviations.PurchaseOrder
		|			AND OrdersBalance.Products   = AcceptableDeviations.Products
		|			AND OrdersBalance.Characteristic = AcceptableDeviations.Characteristic
		|			AND OrdersBalance.Warehouse          = AcceptableDeviations.Warehouse
		|WHERE
		|	OrdersBalance.ToReceiveBalance <= AcceptableDeviations.ToleranceForAdmission
		|	AND OrdersBalance.ToReceiveBalance >= -AcceptableDeviations.ToleranceForAdmission
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
		Query.Text = QueryText;
		
		SampleOrder = Query.Execute().Select();
		
		While SampleOrder.Next() Do
			
			InformationRegisters.OrderQueueToAdjustRowsOfMeasuringGoods.AddOrderToQueue(
				SampleOrder.PurchaseOrder);
			
		EndDo;
	
	EndIf;
	
EndProcedure

#EndRegion

#EndIf