#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If DocumentsPosting.CalculateChanges_(AdditionalProperties) Then
		
		LockForUpdate = True;
		
		// The current state of the set is placed in the temporary table "
		// Movement of goods by loading by recording" in order to get a change in the new set relative to the current one when recording.
		
		Query = New Query;
		Query.SetParameter("Recorder", Filter.Recorder.Value);
		Query.SetParameter("IsNew", AdditionalProperties.DocumentProperties.IsNew);
		Query.TempTablesManager = AdditionalProperties.TempTablesManager;
		Query.Text =
		"SELECT
		|	Table.ReferenceOrder AS ReferenceOrder,
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Series AS Series,
		|	Table.RowCode AS RowCode,
		|	Table.Warehouse AS Warehouse,
		|	Table.Factor AS Factor,
		|	Table.Count AS CountBeforeWrite,
		|	Table.Sum AS SumBeforeWrite,
		|	Table.VATAmount AS VATAmountBeforeWrite,
		|	Table.VATAmountMan AS VATAmountManBeforeWrite,
		|	Table.VATAmountCompl AS VATAmountComplBeforeWrite
		|INTO RegisteredRecordsOfShipmentOrdersBeforeRecording
		|FROM
		|	AccumulationRegister.ShipmentAndReturnReferences AS Table
		|WHERE
		|	Table.Recorder = &Recorder
		|	AND NOT &IsNew
		|";
		
		Query.Execute();
		
	EndIf;

	If Count() = 0 Then
		
		Query = New Query;
		Query.SetParameter("Recorder", Filter.Recorder.Value);
		Query.Text =
		"SELECT DISTINCT
		|	ShipmentAndReturnReferences.ReferenceOrder AS ReferenceOrder
		|FROM
		|	AccumulationRegister.ShipmentAndReturnReferences AS ShipmentAndReturnReferences
		|WHERE
		|	ShipmentAndReturnReferences.Recorder = &Recorder";
		
		OrdersForCalculatingState = Query.Execute().Unload().UnloadColumn("ReferenceOrder");
		AdditionalProperties.Insert("OrdersForCalculatingState", OrdersForCalculatingState);
		
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	Recorder = Filter.Recorder.Value;
	
	If DocumentsPosting.CalculateChanges_(AdditionalProperties) Then
		
		// The change of the new set relative to the current one is calculated taking into account the accumulated changes
		// and placed in a temporary table.
		Query = New Query;
		Query.SetParameter("Recorder", Recorder);
		Query.TempTablesManager = AdditionalProperties.TempTablesManager;
		Query.Text =
		"SELECT
		|	ChangesTable.ReferenceOrder AS ReferenceOrder,
		|	ChangesTable.Products AS Products,
		|	ChangesTable.Characteristic AS Characteristic,
		|	ChangesTable.Series AS Series,
		|	ChangesTable.RowCode AS RowCode,
		|	ChangesTable.Warehouse AS Warehouse,
		|	ChangesTable.Factor AS Factor,
		|	SUM(ChangesTable.CountUpdate) AS CountUpdate,
		|	SUM(ChangesTable.SumUpdate) AS SumUpdate,
		|	SUM(ChangesTable.VATAmountUpdate) AS VATAmountUpdate,
		|	SUM(ChangesTable.VATAmountManUpdate) AS VATAmountManUpdate,
		|	SUM(ChangesTable.VATAmountComplUpdate) AS VATAmountComplUpdate
		|INTO RegisteredRecordsOfShipmentOrderUpdate
		|FROM
		|	(SELECT
		|		Table.ReferenceOrder AS ReferenceOrder,
		|		Table.Products AS Products,
		|		Table.Characteristic AS Characteristic,
		|		Table.Series AS Series,
		|		Table.RowCode AS RowCode,
		|		Table.Warehouse AS Warehouse,
		|		Table.Factor AS Factor,
		|		Table.CountBeforeWrite AS CountUpdate,
		|		Table.SumBeforeWrite AS SumUpdate,
		|		Table.VATAmountBeforeWrite AS VATAmountUpdate,
		|		Table.VATAmountManBeforeWrite AS VATAmountManUpdate,
		|		Table.VATAmountComplBeforeWrite AS VATAmountComplUpdate
		|	FROM
		|		RegisteredRecordsOfShipmentOrdersBeforeRecording AS Table
		|
		|	UNION ALL
		|
		|	SELECT
		|		Table.ReferenceOrder,
		|		Table.Products,
		|		Table.Characteristic,
		|		Table.Series,
		|		Table.RowCode,
		|		Table.Warehouse,
		|		Table.Factor,
		|		-Table.Count,
		|		-Table.Sum,
		|		-Table.VATAmount,
		|		-Table.VATAmountMan,
		|		-Table.VATAmountCompl
		|	FROM
		|		AccumulationRegister.ShipmentAndReturnReferences AS Table
		|	WHERE
		|		Table.Recorder = &Recorder) AS ChangesTable
		|GROUP BY
		|	ChangesTable.ReferenceOrder,
		|	ChangesTable.Products,
		|	ChangesTable.Characteristic,
		|	ChangesTable.Series,
		|	ChangesTable.RowCode,
		|	ChangesTable.Warehouse,
		|	ChangesTable.Factor
		|HAVING
		|	SUM(ChangesTable.CountUpdate) <> 0
		|	OR SUM(ChangesTable.SumUpdate) <> 0
		|	OR SUM(ChangesTable.VATAmountUpdate) <> 0
		|	OR SUM(ChangesTable.VATAmountManUpdate) <> 0
		|	OR SUM(ChangesTable.VATAmountComplUpdate) <> 0";
		
		QueryResultsArray = Query.ExecuteBatch();
		QueryResult = QueryResultsArray[0]; // QueryResult
		Selection = QueryResult.Select();
		
		HasChanges = Selection.Next() And Selection.Count > 0;
		DocumentsPosting.RegisterControlTable(AdditionalProperties,
			"RegisteredRecordsOfShipmentOrderUpdate",
			HasChanges);
		
		If HasChanges
			And GetFunctionalOption("UseAllowableDeviationOfMeasuringGoodsShipmentReceiving") Then
			
			Query = New Query;
			Query.TempTablesManager = AdditionalProperties.TempTablesManager;
			Query.SetParameter("AllowableDeviationOfMeasuringGoodsShipmentAndReceiving",
				Constants.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving.Get());
			Query.SetParameter("DimensionalTypesOfUnits",
				Catalogs.PackagesAndUnitsOfMeasure.DimensionalTypesOfUnits());
			
			QueryText =
			"SELECT
			|	TableOfRevolutions.ReferenceOrder AS ReferenceOrder,
			|	TableOfRevolutions.RowCode AS RowCode,
			|	MAX(TableOfRevolutions.Warehouse) AS Warehouse,
			|	MAX(TableOfRevolutions.Series) AS Series
			|INTO TableSeriesWarehouses
			|FROM
			|	AccumulationRegister.ShipmentAndReturnReferences.Turnovers(,,, (ReferenceOrder, Products, Characteristic) IN
			|		(SELECT
			|			Table.ReferenceOrder,
			|			Table.Products,
			|			Table.Characteristic
			|		FROM
			|			RegisteredRecordsOfShipmentOrderUpdate AS Table)
			|	AND RowCode <> 0
			|	AND Factor IN (VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Ordered),
			|		VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip),
			|		VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped))) AS TableOfRevolutions
			|GROUP BY
			|	TableOfRevolutions.ReferenceOrder,
			|	TableOfRevolutions.RowCode
			|
			|INDEX BY
			|	ReferenceOrder,
			|	RowCode
			|;
			|
			|SELECT
			|	Table.ReferenceOrder AS ReferenceOrder,
			|	Table.Products AS Products,
			|	Table.Characteristic AS Characteristic,
			|	Table.RowCode AS RowCode,
			|	CASE
			|		WHEN Table.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
			|			THEN ISNULL(TableSeriesWarehouses.Series, VALUE(Catalog.ItemsBatches.EmptyRef))
			|		ELSE Table.Series
			|	END AS Series,
			|	CASE
			|		WHEN Table.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
			|			THEN ISNULL(TableSeriesWarehouses.Warehouse, VALUE(Catalog.Warehouses.EmptyRef))
			|		ELSE Table.Warehouse
			|	END AS Warehouse,
			|	Table.Factor AS Factor
			|INTO RegisteredRecordsOrdersForShipmentChangeMeasuredGoods
			|FROM
			|	RegisteredRecordsOfShipmentOrderUpdate AS Table
			|		INNER JOIN Catalog.Products AS ProductsTable
			|		ON Table.Products = ProductsTable.Ref
			|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS TableOfUnitsOfMeasurement
			|		ON ProductsTable.UnitOfMeasure = TableOfUnitsOfMeasurement.Ref
			|		AND TableOfUnitsOfMeasurement.MeasuredValueType IN (&DimensionalTypesOfUnits)
			|		LEFT JOIN TableSeriesWarehouses AS TableSeriesWarehouses
			|		ON Table.ReferenceOrder = TableSeriesWarehouses.ReferenceOrder
			|		AND Table.RowCode = TableSeriesWarehouses.RowCode
			|		AND Table.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)";
			
			// Main table
			QueryText = QueryText
				+ Common.QueryBatchSeparator()
				+ "SELECT
				|	ShipmentAndReturnReferences.ReferenceOrder AS ReferenceOrder,
				|	ShipmentAndReturnReferences.Products AS Products,
				|	ShipmentAndReturnReferences.Characteristic AS Characteristic,
				|	ShipmentAndReturnReferences.RowCode AS RowCode,
				|	CASE
				|		WHEN ShipmentAndReturnReferences.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
				|			THEN ISNULL(TableSeriesWarehouses.Warehouse, VALUE(Catalog.Warehouses.EmptyRef))
				|		ELSE ShipmentAndReturnReferences.Warehouse
				|	END AS Warehouse,
				|	CASE
				|		WHEN ShipmentAndReturnReferences.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
				|			THEN ISNULL(TableSeriesWarehouses.Series, VALUE(Catalog.ItemsBatches.EmptyRef))
				|		ELSE ShipmentAndReturnReferences.Series
				|	END AS Series,
				|	ShipmentAndReturnReferences.Factor AS Factor,
				|	ShipmentAndReturnReferences.Count AS Count
				|INTO TTOrdersForShipment
				|FROM
				|	AccumulationRegister.ShipmentAndReturnReferences AS ShipmentAndReturnReferences
				|		LEFT JOIN TableSeriesWarehouses AS TableSeriesWarehouses
				|		ON ShipmentAndReturnReferences.ReferenceOrder = TableSeriesWarehouses.ReferenceOrder
				|		AND ShipmentAndReturnReferences.RowCode = TableSeriesWarehouses.RowCode
				|		AND ShipmentAndReturnReferences.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
				|WHERE
				|	(ShipmentAndReturnReferences.ReferenceOrder, ShipmentAndReturnReferences.Products,
				|		ShipmentAndReturnReferences.Characteristic) IN
				|		(SELECT
				|			Table.ReferenceOrder,
				|			Table.Products,
				|			Table.Characteristic
				|		FROM
				|			RegisteredRecordsOfShipmentOrderUpdate AS Table)
				|	AND ShipmentAndReturnReferences.Factor IN
				|	(VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegister),
				|		VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Issued_1),
				|		VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip),
				|		VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped),
				|		VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegisterForReturns),
				|		VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.RegisteredOnReturns),
				|		VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ForReceiving),
				|		VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Accepted),
				|		VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.AcceptedOnReturns))
				|	AND VALUETYPE(ShipmentAndReturnReferences.Recorder) <>
				|		TYPE(Document.WriteOffOfShippedGoods)";
			
			// Tolerance
			QueryText = QueryText
				+ Common.QueryBatchSeparator()
				+ "SELECT
				|	ShipmentAndReturnReferences.ReferenceOrder AS ReferenceOrder,
				|	ShipmentAndReturnReferences.Products AS Products,
				|	ShipmentAndReturnReferences.Characteristic AS Characteristic,
				|	ShipmentAndReturnReferences.Warehouse AS Warehouse,
				|	ShipmentAndReturnReferences.Series AS Series,
				|	SUM(CASE
				|		WHEN
				|			ShipmentAndReturnReferences.Factor =
				|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegister)
				|			THEN ShipmentAndReturnReferences.Count
				|		ELSE 0
				|	END) * &AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100 AS AcceptableDeviationToDesign,
				|	SUM(CASE
				|		WHEN
				|			ShipmentAndReturnReferences.Factor =
				|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip)
				|			THEN ShipmentAndReturnReferences.Count
				|		ELSE 0
				|	END) * &AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100 AS AcceptableDeviationToBeShipped,
				|	SUM(CASE
				|		WHEN
				|			ShipmentAndReturnReferences.Factor =
				|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegisterForReturns)
				|			THEN ShipmentAndReturnReferences.Count
				|		ELSE 0
				|	END) * &AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100 AS AcceptableDeviationToReturn,
				|	SUM(CASE
				|		WHEN
				|			ShipmentAndReturnReferences.Factor =
				|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ForReceiving)
				|			THEN ShipmentAndReturnReferences.Count
				|		ELSE 0
				|	END) * &AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100 AS AcceptableDeviationToAcceptance
				|INTO TTPermissibleDeviationsOfShipmentOrder
				|FROM
				|	TTOrdersForShipment AS ShipmentAndReturnReferences
				|WHERE
				|	(ShipmentAndReturnReferences.ReferenceOrder, ShipmentAndReturnReferences.Products,
				|		ShipmentAndReturnReferences.Characteristic) IN
				|		(SELECT
				|			ChangesTable.ReferenceOrder,
				|			ChangesTable.Products,
				|			ChangesTable.Characteristic
				|		FROM
				|			RegisteredRecordsOrdersForShipmentChangeMeasuredGoods AS ChangesTable)
				|	AND ShipmentAndReturnReferences.Factor IN
				|	(VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegister),
				|		VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip),
				|		VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegisterForReturns),
				|		VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ForReceiving))
				|GROUP BY
				|	ShipmentAndReturnReferences.ReferenceOrder,
				|	ShipmentAndReturnReferences.Products,
				|	ShipmentAndReturnReferences.Characteristic,
				|	ShipmentAndReturnReferences.Warehouse,
				|	ShipmentAndReturnReferences.Series
				|
				|INDEX BY
				|	ReferenceOrder,
				|	Products,
				|	Characteristic,
				|	Warehouse,
				|	Series";
			
			//Balance
			QueryText = QueryText
				+ Common.QueryBatchSeparator()
				+ "SELECT
				|	ShipmentAndReturnReferences.ReferenceOrder AS ReferenceOrder,
				|	ShipmentAndReturnReferences.Products AS Products,
				|	ShipmentAndReturnReferences.Characteristic AS Characteristic,
				|	ShipmentAndReturnReferences.Warehouse AS Warehouse,
				|	ShipmentAndReturnReferences.Series AS Series,
				|	SUM(CASE
				|		WHEN
				|			ShipmentAndReturnReferences.Factor =
				|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegister)
				|			THEN ShipmentAndReturnReferences.Count
				|		WHEN
				|			ShipmentAndReturnReferences.Factor =
				|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Issued_1)
				|			THEN -ShipmentAndReturnReferences.Count
				|		ELSE 0
				|	END) AS ToRegisterBalance,
				|	SUM(CASE
				|		WHEN
				|			ShipmentAndReturnReferences.Factor =
				|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip)
				|			THEN ShipmentAndReturnReferences.Count
				|		WHEN
				|			ShipmentAndReturnReferences.Factor =
				|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped)
				|			THEN -ShipmentAndReturnReferences.Count
				|		ELSE 0
				|	END) AS ToShipBalance,
				|	SUM(CASE
				|		WHEN
				|			ShipmentAndReturnReferences.Factor =
				|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegisterForReturns)
				|			THEN ShipmentAndReturnReferences.Count
				|		WHEN
				|			ShipmentAndReturnReferences.Factor =
				|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.RegisteredOnReturns)
				|			THEN -ShipmentAndReturnReferences.Count
				|		ELSE 0
				|	END) AS ForReturnBalance,
				|	SUM(CASE
				|		WHEN
				|			ShipmentAndReturnReferences.Factor =
				|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ForReceiving)
				|			THEN ShipmentAndReturnReferences.Count
				|		WHEN
				|			ShipmentAndReturnReferences.Factor =
				|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Accepted)
				|			THEN -ShipmentAndReturnReferences.Count
				|		WHEN
				|			ShipmentAndReturnReferences.Factor =
				|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.AcceptedOnReturns)
				|			THEN -ShipmentAndReturnReferences.Count
				|		ELSE 0
				|	END) AS ForReceivingBalance
				|INTO TTOrdersForShipmentBalance
				|FROM
				|	TTOrdersForShipment AS ShipmentAndReturnReferences
				|GROUP BY
				|	ShipmentAndReturnReferences.ReferenceOrder,
				|	ShipmentAndReturnReferences.Products,
				|	ShipmentAndReturnReferences.Characteristic,
				|	ShipmentAndReturnReferences.Warehouse,
				|	ShipmentAndReturnReferences.Series";
			
			QueryText = QueryText
				+ Common.QueryBatchSeparator()
				+ "SELECT DISTINCT
				|	BalancesOnOrders.ReferenceOrder AS ReferenceOrder
				|FROM
				|	TTOrdersForShipmentBalance AS BalancesOnOrders
				|		INNER JOIN TTPermissibleDeviationsOfShipmentOrder AS AcceptableDeviations
				|		ON BalancesOnOrders.ReferenceOrder = AcceptableDeviations.ReferenceOrder
				|		AND BalancesOnOrders.Products = AcceptableDeviations.Products
				|		AND BalancesOnOrders.Characteristic = AcceptableDeviations.Characteristic
				|		AND BalancesOnOrders.Warehouse = AcceptableDeviations.Warehouse
				|		AND BalancesOnOrders.Series = AcceptableDeviations.Series
				|WHERE
				|	BalancesOnOrders.ToRegisterBalance <= AcceptableDeviations.AcceptableDeviationToDesign
				|	AND BalancesOnOrders.ToRegisterBalance >= -AcceptableDeviations.AcceptableDeviationToDesign
				|	AND BalancesOnOrders.ToRegisterBalance <> 0
				|	OR BalancesOnOrders.ToShipBalance <= AcceptableDeviations.AcceptableDeviationToBeShipped
				|	AND BalancesOnOrders.ToShipBalance >= -AcceptableDeviations.AcceptableDeviationToBeShipped
				|	AND BalancesOnOrders.ToShipBalance <> 0
				|	OR BalancesOnOrders.ForReturnBalance <= AcceptableDeviations.AcceptableDeviationToReturn
				|	AND BalancesOnOrders.ForReturnBalance >= -AcceptableDeviations.AcceptableDeviationToReturn
				|	AND BalancesOnOrders.ForReturnBalance <> 0
				|	OR BalancesOnOrders.ForReceivingBalance <= AcceptableDeviations.AcceptableDeviationToAcceptance
				|	AND BalancesOnOrders.ForReceivingBalance >= -AcceptableDeviations.AcceptableDeviationToAcceptance
				|	AND BalancesOnOrders.ForReceivingBalance <> 0";
			
			Query.Text = QueryText;
			
			SampleData = Query.Execute().Select();
			While SampleData.Next() Do
				InformationRegisters.OrderQueueToAdjustRowsOfMeasuringGoods.AddOrderToQueue(SampleData.ReferenceOrder);
			EndDo;
			
		EndIf;
		
	EndIf;
	
	References = New Array;
	TypesOfOrders = New Array;
	
	If Count() Then
		
		For Each Record In ThisObject Do
			
			If References.Find(Record.ReferenceOrder) = Undefined Then
				References.Add(Record.ReferenceOrder);
			EndIf;
			
		EndDo;
		
	Else
		
		If AdditionalProperties.Property("OrdersForCalculatingState") Then
			References = AdditionalProperties.OrdersForCalculatingState;
		EndIf;
		
	EndIf;
	
	If References.Count() = 0 Then
		Return;
	EndIf;
	
	For Each ReferenceOrder In References Do
		
		If TypesOfOrders.Find(TypeOf(ReferenceOrder)) = Undefined Then
			TypesOfOrders.Add(TypeOf(ReferenceOrder));
		EndIf;
		
	EndDo;
	
	MinimumDateOfOrders = MinimumDateOfOrders(References);
	If Not ValueIsFilled(MinimumDateOfOrders) Then
		
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.ShipmentAndReturnReferencesToFulfill");
		LockItem.DataSource = Unload();
		LockItem.UseFromDataSource("ReferenceOrder", "ReferenceOrder");
		LockItem.Mode = DataLockMode.Exclusive;
		
		Try
			
			Block.Lock();
			
			For Each ReferenceOrder In References Do
				
				SetOfOrdersForShipmentToBeExecuted = InformationRegisters.ShipmentAndReturnReferencesToFulfill.CreateRecordSet();
				SetOfOrdersForShipmentToBeExecuted.Filter.ReferenceOrder.Set(ReferenceOrder);
				SetOfOrdersForShipmentToBeExecuted.Write();
				
			EndDo;
			
		Except
			Raise(ErrorDescription());
		EndTry;
		
	Else
		
		Query = New Query;
		Query.SetParameter("References", References);
		Query.SetParameter("BeginOfPeriod", MinimumDateOfOrders);
		Query.SetParameter("Recorder", Recorder);
		Query.Text =
		"SELECT
		|	ShipmentReferences.ReferenceOrder AS ReferenceOrder,
		|	ShipmentReferences.Products AS Products,
		|	ShipmentReferences.Characteristic AS Characteristic,
		|	ShipmentReferences.RowCode AS RowCode,
		|	ShipmentReferences.Warehouse AS Warehouse,
		|	ShipmentReferences.Series AS Series,
		|	SUM(ShipmentReferences.Ordered) AS Ordered,
		|	SUM(ShipmentReferences.RequestedForReturn) AS RequestedForReturn,
		|	SUM(ShipmentReferences.ToRegister) AS ToRegister,
		|	SUM(ShipmentReferences.Issued_1) AS Issued_1,
		|	SUM(ShipmentReferences.IssuedAmount) AS IssuedAmount,
		|	SUM(ShipmentReferences.ToRegisterForReturns) AS ToRegisterForReturns,
		|	SUM(ShipmentReferences.RegisteredOnReturns) AS RegisteredOnReturns,
		|	SUM(ShipmentReferences.ToShip) AS ToShip,
		|	SUM(ShipmentReferences.Shipped) AS Shipped,
		|	SUM(ShipmentReferences.ForReceiving) AS ForReceiving,
		|	SUM(ShipmentReferences.Accepted) AS Accepted,
		|	SUM(ShipmentReferences.AcceptedOnReturns) AS AcceptedOnReturns,
		|	SUM(ShipmentReferences.TaxInvoicesRegistered) AS TaxInvoicesRegistered,
		|	SUM(ShipmentReferences.IssuedInvoicesAmount) AS IssuedInvoicesAmount
		|INTO ShipmentOrdersExpandedTurnover
		|FROM
		|	(SELECT
		|		ShippingOrdersTurnover.ReferenceOrder AS ReferenceOrder,
		|		ShippingOrdersTurnover.Products AS Products,
		|		ShippingOrdersTurnover.Characteristic AS Characteristic,
		|		ShippingOrdersTurnover.RowCode AS RowCode,
		|		ShippingOrdersTurnover.Warehouse AS Warehouse,
		|		ShippingOrdersTurnover.Series AS Series,
		|		ShippingOrdersTurnover.OrderedQuantityTurnover AS Ordered,
		|		ShippingOrdersTurnover.QuantityRequestedForReturnTurnover AS RequestedForReturn,
		|		ShippingOrdersTurnover.ForRegistrationQuantityTurnover AS ToRegister,
		|		ShippingOrdersTurnover.IssuedQuantityTurnover AS Issued_1,
		|		ShippingOrdersTurnover.IssuedVATAmountLocalTurnover AS IssuedAmount,
		|		ShippingOrdersTurnover.ForRegistrationOnReturnsQuantityTurnover AS ToRegisterForReturns,
		|		ShippingOrdersTurnover.IssuedByReturnsQuantityTurnover AS RegisteredOnReturns,
		|		ShippingOrdersTurnover.QuantityToBeShippedTurnover AS ToShip,
		|		ShippingOrdersTurnover.ShippedQuantityTurnover AS Shipped,
		|		ShippingOrdersTurnover.QuantityReadyForAcceptanceTurnover AS ForReceiving,
		|		ShippingOrdersTurnover.QuantityAccepted_Turnover AS Accepted,
		|		ShippingOrdersTurnover.AcceptedOnReturnsQuantityTurnover AS AcceptedOnReturns,
		|		ShippingOrdersTurnover.IssuedInvoicesQuantityTurnover AS TaxInvoicesRegistered,
		|		ShippingOrdersTurnover.IssuedInvoicesVATAmountLocalTurnover AS IssuedInvoicesAmount
		|	FROM
		|		#ShipmentOrdersTurnoverExpanded AS ShippingOrdersTurnover
		|
		|	UNION ALL
		|
		|	SELECT
		|		OrdersForShipmentOfRegisteredRecords.ReferenceOrder AS ReferenceOrder,
		|		OrdersForShipmentOfRegisteredRecords.Products AS Products,
		|		OrdersForShipmentOfRegisteredRecords.Characteristic AS Characteristic,
		|		OrdersForShipmentOfRegisteredRecords.RowCode AS RowCode,
		|		OrdersForShipmentOfRegisteredRecords.Warehouse AS Warehouse,
		|		OrdersForShipmentOfRegisteredRecords.Series AS Series,
		|		OrdersForShipmentOfRegisteredRecords.Count AS Ordered,
		|		0,
		|		0,
		|		0,
		|		0,
		|		0,
		|		0,
		|		0,
		|		0,
		|		0,
		|		0,
		|		0,
		|		0,
		|		0
		|	FROM
		|		AccumulationRegister.ShipmentAndReturnReferences AS OrdersForShipmentOfRegisteredRecords
		|	WHERE
		|		OrdersForShipmentOfRegisteredRecords.ReferenceOrder IN (&References)
		|		AND
		|			OrdersForShipmentOfRegisteredRecords.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegister)
		|		AND OrdersForShipmentOfRegisteredRecords.Count < 0
		|		AND VALUETYPE(OrdersForShipmentOfRegisteredRecords.Recorder) IN (TYPE(Document.WriteOffOfShippedGoods),
		|			TYPE(Document.GoodsReceiptFromCustomer))) AS ShipmentReferences
		|GROUP BY
		|	ShipmentReferences.ReferenceOrder,
		|	ShipmentReferences.Products,
		|	ShipmentReferences.Characteristic,
		|	ShipmentReferences.RowCode,
		|	ShipmentReferences.Warehouse,
		|	ShipmentReferences.Series
		|
		|INDEX BY
		|	ReferenceOrder,
		|	RowCode
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TableOfRevolutions.ReferenceOrder AS ReferenceOrder,
		|	TableOfRevolutions.RowCode AS RowCode,
		|	MAX(TableOfRevolutions.Warehouse) AS Warehouse,
		|	MAX(TableOfRevolutions.Series) AS Series
		|INTO TableSeriesWarehouses
		|FROM
		|	AccumulationRegister.ShipmentAndReturnReferences.Turnovers(,,, ReferenceOrder IN (&References)
		|		AND RowCode <> 0
		|		AND Factor IN
		|			(VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Ordered),
		|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip),
		|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped))) AS TableOfRevolutions
		|GROUP BY
		|	TableOfRevolutions.ReferenceOrder,
		|	TableOfRevolutions.RowCode
		|
		|INDEX BY
		|	ReferenceOrder,
		|	RowCode
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TableOfRevolutions.ReferenceOrder AS ReferenceOrder,
		|	TableOfRevolutions.Products AS Products,
		|	TableOfRevolutions.Characteristic AS Characteristic,
		|	CASE
		|		WHEN TableOfRevolutions.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|			THEN ISNULL(TableSeriesWarehouses.Warehouse, VALUE(Catalog.Warehouses.EmptyRef))
		|		ELSE TableOfRevolutions.Warehouse
		|	END AS Warehouse,
		|	CASE
		|		WHEN TableOfRevolutions.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
		|			THEN ISNULL(TableSeriesWarehouses.Series, VALUE(Catalog.ItemsBatches.EmptyRef))
		|		ELSE TableOfRevolutions.Series
		|	END AS Series,
		|	SUM(TableOfRevolutions.Ordered) AS Ordered,
		|	SUM(TableOfRevolutions.RequestedForReturn) AS RequestedForReturn,
		|	SUM(TableOfRevolutions.ToRegister) AS ToRegister,
		|	SUM(TableOfRevolutions.Issued_1) AS Issued_1,
		|	SUM(TableOfRevolutions.IssuedAmount) AS IssuedAmount,
		|	SUM(TableOfRevolutions.ToRegisterForReturns) AS ToRegisterForReturns,
		|	SUM(TableOfRevolutions.RegisteredOnReturns) AS RegisteredOnReturns,
		|	SUM(TableOfRevolutions.ToShip) AS ToShip,
		|	SUM(TableOfRevolutions.Shipped) AS Shipped,
		|	SUM(TableOfRevolutions.ForReceiving) AS ForReceiving,
		|	SUM(TableOfRevolutions.Accepted) AS Accepted,
		|	SUM(TableOfRevolutions.AcceptedOnReturns) AS AcceptedOnReturns,
		|	SUM(TableOfRevolutions.TaxInvoicesRegistered) AS TaxInvoicesRegistered,
		|	SUM(TableOfRevolutions.IssuedInvoicesAmount) AS IssuedInvoicesAmount
		|INTO TTOrdersForShipmentTurnover
		|FROM
		|	ShipmentOrdersExpandedTurnover AS TableOfRevolutions
		|		LEFT JOIN TableSeriesWarehouses AS TableSeriesWarehouses
		|		ON TableOfRevolutions.ReferenceOrder = TableSeriesWarehouses.ReferenceOrder
		|		AND TableOfRevolutions.RowCode = TableSeriesWarehouses.RowCode
		|GROUP BY
		|	TableOfRevolutions.ReferenceOrder,
		|	TableOfRevolutions.Products,
		|	TableOfRevolutions.Characteristic,
		|	TableOfRevolutions.RowCode,
		|	CASE
		|		WHEN TableOfRevolutions.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|			THEN ISNULL(TableSeriesWarehouses.Warehouse, VALUE(Catalog.Warehouses.EmptyRef))
		|		ELSE TableOfRevolutions.Warehouse
		|	END,
		|	CASE
		|		WHEN TableOfRevolutions.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
		|			THEN ISNULL(TableSeriesWarehouses.Series, VALUE(Catalog.ItemsBatches.EmptyRef))
		|		ELSE TableOfRevolutions.Series
		|	END
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ShippingOrdersTurnover.ReferenceOrder AS ReferenceOrder,
		|	ShippingOrdersTurnover.Products AS Products,
		|	ShippingOrdersTurnover.Characteristic AS Characteristic,
		|	ShippingOrdersTurnover.Warehouse AS Warehouse,
		|	ShippingOrdersTurnover.Series AS Series,
		|	CASE
		|		WHEN ShippingOrdersTurnover.Ordered <= ShippingOrdersTurnover.Issued_1
		|			THEN 1
		|		WHEN ShippingOrdersTurnover.Issued_1 = 0
		|		AND ShippingOrdersTurnover.Ordered > 0
		|			THEN 2
		|		ELSE 3
		|	END AS DocumentStateOrdered,
		|	CASE
		|		WHEN ShippingOrdersTurnover.ToRegister <= ShippingOrdersTurnover.Issued_1
		|			THEN 1
		|		WHEN ShippingOrdersTurnover.Issued_1 = 0
		|		AND ShippingOrdersTurnover.ToRegister > 0
		|			THEN 2
		|		ELSE 3
		|	END AS DocumentStateToRegister,
		|	CASE
		|		WHEN ShippingOrdersTurnover.ToShip <= ShippingOrdersTurnover.Shipped
		|			THEN 1
		|		WHEN ShippingOrdersTurnover.Shipped = 0
		|		AND ShippingOrdersTurnover.ToShip > 0
		|			THEN 2
		|		ELSE 3
		|	END AS StateOfGoodsToShip,
		|	CASE
		|		WHEN ShippingOrdersTurnover.RequestedForReturn <= ShippingOrdersTurnover.RegisteredOnReturns
		|			THEN 1
		|		WHEN ShippingOrdersTurnover.RegisteredOnReturns = 0
		|		AND ShippingOrdersTurnover.RequestedForReturn > 0
		|			THEN 2
		|		ELSE 3
		|	END AS StateOfGoodsDeclaredForReturn,
		|	CASE
		|		WHEN ShippingOrdersTurnover.ToRegisterForReturns <= ShippingOrdersTurnover.RegisteredOnReturns
		|			THEN 1
		|		WHEN ShippingOrdersTurnover.RegisteredOnReturns = 0
		|		AND ShippingOrdersTurnover.ToRegisterForReturns > 0
		|			THEN 2
		|		ELSE 3
		|	END AS StateOfGoodsRegisteredBasedOnReturns,
		|	CASE
		|		WHEN ShippingOrdersTurnover.ForReceiving <= ShippingOrdersTurnover.Accepted +
		|			ShippingOrdersTurnover.AcceptedOnReturns
		|			THEN 1
		|		WHEN ShippingOrdersTurnover.Accepted + ShippingOrdersTurnover.AcceptedOnReturns = 0
		|		AND ShippingOrdersTurnover.ForReceiving > 0
		|			THEN 2
		|		ELSE 3
		|	END AS StateOfGoodsToReceive,
		|	CASE
		|		WHEN VALUETYPE(ShippingOrdersTurnover.ReferenceOrder) NOT IN (TYPE(Document.SalesOrder),
		|			TYPE(Document.GoodsShipmentToCustomer), TYPE(Document.SourceDocument),
		|			TYPE(Document.RequestForReturnOfGoodsFromCustomer), TYPE(Document.SaleAdjustment))
		|			THEN 1
		|		WHEN ShippingOrdersTurnover.ToShip -
		|			ShippingOrdersTurnover.Shipped = ShippingOrdersTurnover.ToRegister -
		|			ShippingOrdersTurnover.Issued_1
		|			THEN 1
		|		WHEN ShippingOrdersTurnover.ToRegister - ShippingOrdersTurnover.Issued_1 > 0
		|		AND ShippingOrdersTurnover.ToRegister -
		|			ShippingOrdersTurnover.Issued_1 = ShippingOrdersTurnover.ToShip
		|			THEN 2
		|		ELSE 3
		|	END AS StateOfGoodsToTransferOfTitleToGoods,
		|	CASE
		|		WHEN VALUETYPE(ShippingOrdersTurnover.ReferenceOrder) NOT IN (TYPE(Document.SalesOrder),
		|			TYPE(Document.GoodsShipmentToCustomer), TYPE(Document.SourceDocument),
		|			TYPE(Document.RequestForReturnOfGoodsFromCustomer), TYPE(Document.SaleAdjustment))
		|			THEN 1
		|		WHEN CASE
		|			WHEN ShippingOrdersTurnover.TaxInvoicesRegistered = ShippingOrdersTurnover.Issued_1
		|			OR ShippingOrdersTurnover.TaxInvoicesRegistered = 0
		|				THEN 1
		|			WHEN ShippingOrdersTurnover.Issued_1 = 0
		|			AND ShippingOrdersTurnover.TaxInvoicesRegistered > 0
		|				THEN 2
		|			ELSE 3
		|		END = 1
		|			THEN CASE
		|				WHEN ShippingOrdersTurnover.IssuedInvoicesAmount = ShippingOrdersTurnover.IssuedAmount
		|				OR ShippingOrdersTurnover.IssuedInvoicesAmount = 0
		|					THEN 1
		|				WHEN ShippingOrdersTurnover.IssuedAmount = 0
		|				AND ShippingOrdersTurnover.IssuedInvoicesAmount > 0
		|					THEN 2
		|				ELSE 3
		|			END
		|		ELSE CASE
		|			WHEN ShippingOrdersTurnover.TaxInvoicesRegistered = ShippingOrdersTurnover.Issued_1
		|			OR ShippingOrdersTurnover.TaxInvoicesRegistered = 0
		|				THEN 1
		|			WHEN ShippingOrdersTurnover.Issued_1 = 0
		|			AND ShippingOrdersTurnover.TaxInvoicesRegistered > 0
		|				THEN 2
		|			ELSE 3
		|		END
		|	END AS StateOfGoodsToRegisterTaxInvoices
		|INTO OrderStateTT
		|FROM
		|	TTOrdersForShipmentTurnover AS ShippingOrdersTurnover
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	StatesOfOrders.ReferenceOrder AS ReferenceOrder,
		|	StatesOfOrders.Warehouse AS Warehouse,
		|	&Organization AS Organization,
		|	&Number AS Number,
		|	&Date AS Date,
		|	&DocumentAmount AS DocumentAmount,
		|	&Currency AS Currency,
		|	CASE
		|		WHEN StatesOfOrders.ReferenceOrder REFS Document.SourceDocument
		|			THEN &Recorders_BusinessTransactions
		|		ELSE &BusinessOperation
		|	END AS BusinessOperation,
		|	&Partner AS Partner,
		|	&Counterparty AS Counterparty,
		|	CASE
		|		WHEN StatesOfOrders.ReferenceOrder REFS Document.SourceDocument
		|			THEN &Recorders_Manager
		|		ELSE &Manager
		|	END AS Manager,
		|	CASE
		|		WHEN MAX(StatesOfOrders.DocumentStateOrdered) = 1
		|			THEN VALUE(Enum.StateOfRegisteringDocumentsByReference.Decorated)
		|		WHEN MAX(StatesOfOrders.DocumentStateOrdered) = 2
		|			THEN VALUE(Enum.StateOfRegisteringDocumentsByReference.PendingCreation)
		|		ELSE VALUE(Enum.StateOfRegisteringDocumentsByReference.PartiallyRegistered)
		|	END AS DocumentStateOrdered,
		|	CASE
		|		WHEN MAX(StatesOfOrders.DocumentStateToRegister) = 1
		|			THEN VALUE(Enum.StateOfRegisteringDocumentsByReference.Decorated)
		|		WHEN MAX(StatesOfOrders.DocumentStateToRegister) = 2
		|			THEN VALUE(Enum.StateOfRegisteringDocumentsByReference.PendingCreation)
		|		ELSE VALUE(Enum.StateOfRegisteringDocumentsByReference.PartiallyRegistered)
		|	END AS DocumentStateToRegister,
		|	CASE
		|		WHEN MAX(StatesOfOrders.StateOfGoodsToShip) = 1
		|			THEN VALUE(Enum.StateOfRegisteringDocumentsByReference.Decorated)
		|		WHEN MAX(StatesOfOrders.StateOfGoodsToShip) = 2
		|			THEN VALUE(Enum.StateOfRegisteringDocumentsByReference.PendingCreation)
		|		ELSE VALUE(Enum.StateOfRegisteringDocumentsByReference.PartiallyRegistered)
		|	END AS StateOfGoodsToShip,
		|	CASE
		|		WHEN MAX(StatesOfOrders.StateOfGoodsDeclaredForReturn) = 1
		|			THEN VALUE(Enum.StateOfRegisteringDocumentsByReference.Decorated)
		|		WHEN MAX(StatesOfOrders.StateOfGoodsDeclaredForReturn) = 2
		|			THEN VALUE(Enum.StateOfRegisteringDocumentsByReference.PendingCreation)
		|		ELSE VALUE(Enum.StateOfRegisteringDocumentsByReference.PartiallyRegistered)
		|	END AS StateOfGoodsDeclaredForReturn,
		|	CASE
		|		WHEN MAX(StatesOfOrders.StateOfGoodsRegisteredBasedOnReturns) = 1
		|			THEN VALUE(Enum.StateOfRegisteringDocumentsByReference.Decorated)
		|		WHEN MAX(StatesOfOrders.StateOfGoodsRegisteredBasedOnReturns) = 2
		|			THEN VALUE(Enum.StateOfRegisteringDocumentsByReference.PendingCreation)
		|		ELSE VALUE(Enum.StateOfRegisteringDocumentsByReference.PartiallyRegistered)
		|	END AS StateOfGoodsRegisteredBasedOnReturns,
		|	CASE
		|		WHEN MAX(StatesOfOrders.StateOfGoodsToReceive) = 1
		|			THEN VALUE(Enum.StateOfRegisteringDocumentsByReference.Decorated)
		|		WHEN MAX(StatesOfOrders.StateOfGoodsToReceive) = 2
		|			THEN VALUE(Enum.StateOfRegisteringDocumentsByReference.PendingCreation)
		|		ELSE VALUE(Enum.StateOfRegisteringDocumentsByReference.PartiallyRegistered)
		|	END AS StateOfGoodsToReceive,
		|	CASE
		|		WHEN MAX(StatesOfOrders.StateOfGoodsToTransferOfTitleToGoods) = 1
		|			THEN VALUE(Enum.StateOfRegisteringDocumentsByReference.Decorated)
		|		WHEN MAX(StatesOfOrders.StateOfGoodsToTransferOfTitleToGoods) = 2
		|			THEN VALUE(Enum.StateOfRegisteringDocumentsByReference.PendingCreation)
		|		ELSE VALUE(Enum.StateOfRegisteringDocumentsByReference.PartiallyRegistered)
		|	END AS StateOfGoodsToTransferOfTitleToGoods,
		|	CASE
		|		WHEN MAX(StatesOfOrders.StateOfGoodsToRegisterTaxInvoices) = 1
		|			THEN VALUE(Enum.StateOfRegisteringDocumentsByReference.Decorated)
		|		WHEN MAX(StatesOfOrders.StateOfGoodsToRegisterTaxInvoices) = 2
		|			THEN VALUE(Enum.StateOfRegisteringDocumentsByReference.PendingCreation)
		|		ELSE VALUE(Enum.StateOfRegisteringDocumentsByReference.PartiallyRegistered)
		|	END AS StateOfGoodsToRegisterTaxInvoices
		|FROM
		|	OrderStateTT AS StatesOfOrders
		|GROUP BY
		|	StatesOfOrders.ReferenceOrder,
		|	StatesOfOrders.Warehouse,
		|	CASE
		|		WHEN StatesOfOrders.ReferenceOrder REFS Document.SourceDocument
		|			THEN &Recorders_BusinessTransactions
		|		ELSE &BusinessOperation
		|	END,
		|	CASE
		|		WHEN StatesOfOrders.ReferenceOrder REFS Document.SourceDocument
		|			THEN &Recorders_Manager
		|		ELSE &Manager
		|	END
		|HAVING
		|	MAX(StatesOfOrders.DocumentStateOrdered) > 1
		|	OR MAX(StatesOfOrders.DocumentStateToRegister) > 1
		|	OR MAX(StatesOfOrders.StateOfGoodsToShip) > 1
		|	OR MAX(StatesOfOrders.StateOfGoodsDeclaredForReturn) > 1
		|	OR MAX(StatesOfOrders.StateOfGoodsRegisteredBasedOnReturns) > 1
		|	OR MAX(StatesOfOrders.StateOfGoodsToReceive) > 1
		|	OR MAX(StatesOfOrders.StateOfGoodsToTransferOfTitleToGoods) > 1
		|	OR MAX(StatesOfOrders.StateOfGoodsToRegisterTaxInvoices) > 1
		|TOTALS
		|BY
		|	ReferenceOrder";
		
		TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
		TableFormationParameters.ConditionText =
			"ReferenceOrder IN (&References)
			|	AND VALUETYPE(ReferenceOrder) <> TYPE(Document.RegisterAdjustment)";
		TableFormationParameters.BeginOfPeriod = "&BeginOfPeriod";
		TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, RowCode, Warehouse, Series";
		TableFormationParameters.Indicators = "Ordered, RequestedForReturn, ToRegister, Issued_1,
			|ToRegisterForReturns, RegisteredOnReturns, ToShip,
			|Shipped, ForReceiving, Accepted, AcceptedOnReturns,
			|TaxInvoicesRegistered";
		TableFormationParameters.Resources = "Count, VATAmountCompl";
		
		ShipmentOrdersTurnoverExpanded =
			AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
				TableFormationParameters);
		
		Query.Text = StrReplace(Query.Text,
			"#ShipmentOrdersTurnoverExpanded",
			ShipmentOrdersTurnoverExpanded);
		
		Query.Text = StrReplace(Query.Text,
			"&Organization",
			QueryTextValueOfAttributeFromCompositeType(
				"StatesOfOrders.ReferenceOrder",
				"Organization",
				TypesOfOrders));
		
		Query.Text = StrReplace(Query.Text,
			"&Number",
			QueryTextValueOfAttributeFromCompositeType(
				"StatesOfOrders.ReferenceOrder",
				"Number",
				TypesOfOrders));
		
		Query.Text = StrReplace(Query.Text,
			"&Date",
			QueryTextValueOfAttributeFromCompositeType(
				"StatesOfOrders.ReferenceOrder",
				"Date",
				TypesOfOrders));
		
		Query.Text = StrReplace(Query.Text,
			"&DocumentAmount",
			QueryTextValueOfAttributeFromCompositeType(
				"StatesOfOrders.ReferenceOrder",
				"DocumentAmount",
				TypesOfOrders));
		
		Query.Text = StrReplace(Query.Text,
			"&Currency",
			QueryTextValueOfAttributeFromCompositeType(
				"StatesOfOrders.ReferenceOrder",
				"Currency",
				TypesOfOrders));
		
		Query.Text = StrReplace(Query.Text,
			"&Partner",
			QueryTextValueOfAttributeFromCompositeType(
				"StatesOfOrders.ReferenceOrder",
				"Partner",
				TypesOfOrders));
		
		Query.Text = StrReplace(Query.Text,
			"&Counterparty",
			QueryTextValueOfAttributeFromCompositeType(
				"StatesOfOrders.ReferenceOrder",
				"Counterparty",
				TypesOfOrders));
		
		Query.Text = StrReplace(Query.Text,
			"&Manager",
			QueryTextValueOfAttributeFromCompositeType(
				"StatesOfOrders.ReferenceOrder",
				"Manager",
				TypesOfOrders));
		
		Query.Text = StrReplace(Query.Text,
			"&BusinessOperation",
			QueryTextValueOfAttributeFromCompositeType(
				"StatesOfOrders.ReferenceOrder",
				"BusinessOperation",
				TypesOfOrders));
		
		If CommonClientServer.HasAttributeOrObjectProperty(Recorder, "Manager") Then
			Recorders_Manager = Common.ObjectAttributeValue(Recorder, "Manager");
		ElsIf CommonClientServer.HasAttributeOrObjectProperty(Recorder, "EmployeeResponsible") Then
			Recorders_Manager = Common.ObjectAttributeValue(Recorder, "EmployeeResponsible");
		Else
			Recorders_Manager = Undefined;
		EndIf;
		
		If CommonClientServer.HasAttributeOrObjectProperty(Recorder, "BusinessOperation") Then
			Recorders_BusinessTransactions =
				Common.ObjectAttributeValue(Recorder, "BusinessOperation");
		Else
			Recorders_BusinessTransactions = Undefined;
		EndIf;
		
		Query.SetParameter("Recorders_Manager", Recorders_Manager);
		Query.SetParameter("Recorders_BusinessTransactions", Recorders_BusinessTransactions);
		
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.ShipmentAndReturnReferencesToFulfill");
		LockItem.DataSource = Unload();
		LockItem.UseFromDataSource("ReferenceOrder", "ReferenceOrder");
		LockItem.Mode = DataLockMode.Exclusive;
		
		Try
			
			Block.Lock();
			
			SampleData = Query.Execute().Select(QueryResultIteration.ByGroups);
			
			For Each ReferenceOrder In References Do
				
				SetOfOrdersForShipmentToBeExecuted = InformationRegisters.ShipmentAndReturnReferencesToFulfill.CreateRecordSet();
				SetOfOrdersForShipmentToBeExecuted.Filter.ReferenceOrder.Set(ReferenceOrder);
				
				If SampleData.FindNext(ReferenceOrder, "ReferenceOrder") Then
					
					SelectionDetailRecords = SampleData.Select();
					While SelectionDetailRecords.Next() Do
						
						Record = SetOfOrdersForShipmentToBeExecuted.Add();
						FillPropertyValues(Record, SelectionDetailRecords);
						
					EndDo;
					
				EndIf;
				
				SetOfOrdersForShipmentToBeExecuted.Write();
				
				SampleData.Reset();
				
			EndDo;
			
		Except
			Raise(ErrorDescription());
		EndTry;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// The Query Text is the Attribute value of the composite type.
// 
// Parameters:
//  TableName - String - table name
//  AttributeName - String - The name of the props
//  AttributeTypes - Array of Type - Array of Attribute types
// 
// Returns:
//  String - Query Text The Value Of The Attribute From The Composite Type
Function QueryTextValueOfAttributeFromCompositeType(TableName, AttributeName, AttributeTypes) Export
	
	Result = "";
	
	QueryTextTemplate2 =
	"	WHEN VALUETYPE(&LinkField) = TYPE(&RefType)
	|		THEN CAST(&LinkField AS &RefType).%AttributeName
	|"; // @query-part
	
	StandardAttributes = New Array;
	StandardAttributes.Add("Number");
	StandardAttributes.Add("Date");
	
	For Each Type In AttributeTypes Do
		
		AttributeMetadata = Metadata.FindByType(Type);
		
		If Common.HasObjectAttribute(AttributeName, AttributeMetadata)
			Or StandardAttributes.Find(AttributeName) <> Undefined Then
			
			FullName = StrTemplate("Document.%1", AttributeMetadata.Name);
			PartOfRequest = StrReplace(QueryTextTemplate2, "%AttributeName", AttributeName);
			PartOfRequest = StrReplace(PartOfRequest, "&LinkField", TableName);
			PartOfRequest = StrReplace(PartOfRequest, "&RefType", FullName);
			Result = Result + PartOfRequest;
			
		EndIf;
		
	EndDo;
	
	If ValueIsFilled(Result) Then
	
		Result = StrTemplate(
			"CASE
			|	%1
			|END", // @query-part
			TrimAll(Result));

	Else
		
		Result = "UNDEFINED"

	EndIf;
	
	Return Result;
	
EndFunction

Function MinimumDateOfOrders(References)
	
	Query = New Query;
	Query.SetParameter("References", References);
	Query.Text =
	"SELECT TOP 1
	|	BEGINOFPERIOD(ShipmentReferences.Period, DAY) AS Date
	|FROM
	|	AccumulationRegister.ShipmentAndReturnReferences AS ShipmentReferences
	|WHERE
	|	ShipmentReferences.ReferenceOrder IN (&References)
	|
	|ORDER BY
	|	ShipmentReferences.Period";
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Result = Selection.Date;
	Else
		Result = Date(1, 1, 1);
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf