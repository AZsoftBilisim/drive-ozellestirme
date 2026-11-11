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
	
	// The current state of the set is placed in a temporary table
	// in order to get a change in the new set relative to the current one when writing.
	
	Query = New Query;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.SetParameter("IsNew",    AdditionalProperties.DocumentProperties.IsNew);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.Text =
	"SELECT
	|	Table.InventoryConsumptionOrder AS InventoryConsumptionOrder,
	|	Table.Products                 AS Products,
	|	Table.Characteristic               AS Characteristic,
	|	Table.Series                        AS Series,
	|	Table.Warehouse                        AS Warehouse,
	|	Table.RowCode                    AS RowCode,
	|	CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|			Table.Ordered
	|		ELSE
	|			-Table.Ordered
	|	END                  AS OrderedBeforeWrite,
	|	CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|			Table.ToRegister
	|		ELSE
	|			-Table.ToRegister
	|	END                                AS ToRegisterBeforeWrite
	|INTO RegisteredRecordsOfDomesticConsumptionOrdersBeforeWrite
	|FROM
	|	AccumulationRegister.InventoryConsumptionOrders AS Table
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
	|	ChangesTable.InventoryConsumptionOrder AS InventoryConsumptionOrder,
	|	ChangesTable.Products                AS Products,
	|	ChangesTable.Characteristic              AS Characteristic,
	|	ChangesTable.Series                       AS Series,
	|	ChangesTable.Warehouse                       AS Warehouse,
	|	SUM(ChangesTable.OrderedUpdate)    AS OrderedUpdate,
	|	SUM(ChangesTable.ToRegisterUpdate) AS ToRegisterUpdate
	|INTO RegisteredRecordsOfDomesticConsumptionOrdersUpdate
	|FROM
	|	(SELECT
	|		Table.InventoryConsumptionOrder AS InventoryConsumptionOrder,
	|		Table.Products                 AS Products,
	|		Table.Characteristic               AS Characteristic,
	|		Table.Series                        AS Series,
	|		Table.Warehouse                        AS Warehouse,
	|		Table.OrderedBeforeWrite    AS OrderedUpdate,
	|		Table.ToRegisterBeforeWrite      AS ToRegisterUpdate
	|	FROM
	|		RegisteredRecordsOfDomesticConsumptionOrdersBeforeWrite AS Table
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.InventoryConsumptionOrder AS InventoryConsumptionOrder,
	|		Table.Products                 AS Products,
	|		Table.Characteristic               AS Characteristic,
	|		Table.Series                        AS Series,
	|		Table.Warehouse                        AS Warehouse,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|				-Table.Ordered
	|			ELSE
	|				Table.Ordered
	|		END                  AS OrderedBeforeWrite,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|				-Table.ToRegister
	|			ELSE
	|				Table.ToRegister
	|		END                                AS ToRegisterUpdate
	|	FROM
	|		AccumulationRegister.InventoryConsumptionOrders AS Table
	|	WHERE
	|		Table.Recorder = &Recorder) AS ChangesTable
	|
	|GROUP BY
	|	ChangesTable.InventoryConsumptionOrder,
	|	ChangesTable.Products,
	|	ChangesTable.Characteristic,
	|	ChangesTable.Series,
	|	ChangesTable.Warehouse
	|
	|HAVING
	|	SUM(ChangesTable.ToRegisterUpdate) <> 0
	|	OR SUM(ChangesTable.OrderedUpdate) <> 0
	|;
	|DROP RegisteredRecordsOfDomesticConsumptionOrdersBeforeWrite
	|";
	
	Selection = Query.ExecuteBatch()[0].Select();
	HasChanges = Selection.Next() And Selection.Count > 0;
	DocumentsPosting.RegisterControlTable(AdditionalProperties,
		"RegisteredRecordsOfDomesticConsumptionOrdersUpdate", HasChanges);
	
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
		|	Table.InventoryConsumptionOrder,
		|	Table.Products,
		|	Table.Characteristic,
		|	Table.Series,
		|	Table.Warehouse
		|INTO RegisteredRecordsOrdersForDomesticConsumptionChangeMeasuredGoods
		|FROM
		|	RegisteredRecordsOfDomesticConsumptionOrdersUpdate AS Table
		|WHERE 
		|	Table.Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfUnits)
		|GROUP BY
		|	Table.InventoryConsumptionOrder,
		|	Table.Products,
		|	Table.Characteristic,
		|	Table.Series,
		|	Table.Warehouse
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
		// Main table
		QueryText = QueryText + "
		|SELECT
		|	InventoryConsumptionOrders.RecordType                  AS RecordType,
		|	InventoryConsumptionOrders.InventoryConsumptionOrder AS InventoryConsumptionOrder,
		|	InventoryConsumptionOrders.Products                 AS Products,
		|	InventoryConsumptionOrders.Characteristic               AS Characteristic,
		|	InventoryConsumptionOrders.Warehouse                        AS Warehouse,
		|	InventoryConsumptionOrders.Series                        AS Series,
		|	InventoryConsumptionOrders.ToRegister                  AS ToRegister
		|INTO TTOrdersForDomesticConsumption
		|FROM
		|	AccumulationRegister.InventoryConsumptionOrders AS InventoryConsumptionOrders
		|	INNER JOIN
		|		RegisteredRecordsOfDomesticConsumptionOrdersUpdate AS Changes
		|		ON InventoryConsumptionOrders.InventoryConsumptionOrder = Changes.InventoryConsumptionOrder
		|			AND InventoryConsumptionOrders.Products              = Changes.Products
		|			AND InventoryConsumptionOrders.Characteristic            = Changes.Characteristic
		|			AND InventoryConsumptionOrders.Warehouse                     = Changes.Warehouse
		|			AND InventoryConsumptionOrders.Series                     = Changes.Series
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
		// Tolerance
		QueryText = QueryText + "
		|SELECT
		|	InventoryConsumptionOrders.InventoryConsumptionOrder AS InventoryConsumptionOrder,
		|	InventoryConsumptionOrders.Products                 AS Products,
		|	InventoryConsumptionOrders.Characteristic               AS Characteristic,
		|	InventoryConsumptionOrders.Warehouse                        AS Warehouse,
		|	InventoryConsumptionOrders.Series                        AS Series,
		|	SUM(InventoryConsumptionOrders.ToRegister
		|		* (&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100)) AS AllowableVariance
		|INTO TTToleranceOrdersForDomesticConsumption
		|FROM
		|	TTOrdersForDomesticConsumption AS InventoryConsumptionOrders
		|	INNER JOIN RegisteredRecordsOrdersForDomesticConsumptionChangeMeasuredGoods AS Changes
		|		ON InventoryConsumptionOrders.InventoryConsumptionOrder = Changes.InventoryConsumptionOrder
		|			AND InventoryConsumptionOrders.Products              = Changes.Products
		|			AND InventoryConsumptionOrders.Characteristic            = Changes.Characteristic
		|			AND InventoryConsumptionOrders.Warehouse                     = Changes.Warehouse
		|			AND InventoryConsumptionOrders.Series                     = Changes.Series
		|WHERE
		|	InventoryConsumptionOrders.RecordType = VALUE(AccumulationRecordType.Receipt)
		|GROUP BY
		|	InventoryConsumptionOrders.InventoryConsumptionOrder,
		|	InventoryConsumptionOrders.Products,
		|	InventoryConsumptionOrders.Characteristic,
		|	InventoryConsumptionOrders.Warehouse,
		|	InventoryConsumptionOrders.Series
		|INDEX BY
		|	InventoryConsumptionOrder,
		|	Products,
		|	Characteristic,
		|	Warehouse,
		|	Series
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
		//Balance
		QueryText = QueryText + "
		|SELECT
		|	InventoryConsumptionOrders.InventoryConsumptionOrder AS InventoryConsumptionOrder,
		|	InventoryConsumptionOrders.Products                 AS Products,
		|	InventoryConsumptionOrders.Characteristic               AS Characteristic,
		|	InventoryConsumptionOrders.Warehouse                        AS Warehouse,
		|	InventoryConsumptionOrders.Series                        AS Series,
		|	SUM(CASE WHEN InventoryConsumptionOrders.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
		|			InventoryConsumptionOrders.ToRegister
		|		ELSE
		|			-InventoryConsumptionOrders.ToRegister
		|	END)                                                     AS ToRegisterBalance
		|INTO TTOrdersForDomesticConsumptionBalance
		|FROM
		|	TTOrdersForDomesticConsumption AS InventoryConsumptionOrders
		|GROUP BY
		|	InventoryConsumptionOrders.InventoryConsumptionOrder,
		|	InventoryConsumptionOrders.Products,
		|	InventoryConsumptionOrders.Characteristic,
		|	InventoryConsumptionOrders.Warehouse,
		|	InventoryConsumptionOrders.Series
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
		QueryText = QueryText + "
		|SELECT DISTINCT
		|	OrdersBalance.InventoryConsumptionOrder AS InventoryConsumptionOrder
		|FROM
		|	TTOrdersForDomesticConsumptionBalance AS OrdersBalance
		|	INNER JOIN
		|		TTToleranceOrdersForDomesticConsumption AS AcceptableDeviations
		|		ON
		|			OrdersBalance.InventoryConsumptionOrder = AcceptableDeviations.InventoryConsumptionOrder
		|			AND OrdersBalance.Products               = AcceptableDeviations.Products
		|			AND OrdersBalance.Characteristic             = AcceptableDeviations.Characteristic
		|			AND OrdersBalance.Warehouse                      = AcceptableDeviations.Warehouse
		|			AND OrdersBalance.Series                      = AcceptableDeviations.Series
		|WHERE
		|	OrdersBalance.ToRegisterBalance <= AcceptableDeviations.AllowableVariance
		|	AND OrdersBalance.ToRegisterBalance >= -AcceptableDeviations.AllowableVariance
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
		Query.Text = QueryText;
		
		SampleOrder = Query.Execute().Select();
		
		While SampleOrder.Next() Do
			
			InformationRegisters.OrderQueueToAdjustRowsOfMeasuringGoods.AddOrderToQueue(
				SampleOrder.InventoryConsumptionOrder);
			
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf