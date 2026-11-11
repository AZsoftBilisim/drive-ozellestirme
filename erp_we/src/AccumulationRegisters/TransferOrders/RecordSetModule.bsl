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
	|	Table.TransferOrder AS TransferOrder,
	|	Table.Products       AS Products,
	|	Table.Characteristic     AS Characteristic,
	|	Table.Series              AS Series,
	|	Table.RowCode          AS RowCode,
	|	CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|			Table.Ordered
	|		ELSE
	|			-Table.Ordered
	|	END                  AS OrderedBeforeWrite,
	|	CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|			Table.ToRegister
	|		ELSE
	|			-Table.ToRegister
	|	END                      AS ToRegisterBeforeWrite
	|INTO RegisteredRecordsMoveOrdersBeforeRecording
	|FROM
	|	AccumulationRegister.TransferOrders AS Table
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
	|	ChangesTable.TransferOrder          AS TransferOrder,
	|	ChangesTable.Products                AS Products,
	|	ChangesTable.Characteristic              AS Characteristic,
	|	ChangesTable.Series                       AS Series,
	|	SUM(ChangesTable.OrderedUpdate)    AS OrderedUpdate,
	|	SUM(ChangesTable.ToRegisterUpdate) AS ToRegisterUpdate
	|INTO RegisteredRecordsOrdersToMoveChange
	|FROM
	|	(SELECT
	|		Table.TransferOrder  AS TransferOrder,
	|		Table.Products        AS Products,
	|		Table.Characteristic      AS Characteristic,
	|		Table.Series               AS Series,
	|		Table.OrderedBeforeWrite    AS OrderedUpdate,
	|		Table.ToRegisterBeforeWrite AS ToRegisterUpdate
	|	FROM
	|		RegisteredRecordsMoveOrdersBeforeRecording AS Table
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.TransferOrder AS TransferOrder,
	|		Table.Products       AS Products,
	|		Table.Characteristic     AS Characteristic,
	|		Table.Series               AS Series,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|				-Table.Ordered
	|			ELSE
	|				Table.Ordered
	|		END                  AS OrderedBeforeWrite,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|				-Table.ToRegister
	|			ELSE
	|				Table.ToRegister
	|		END                      AS ToRegisterUpdate
	|	FROM
	|		AccumulationRegister.TransferOrders AS Table
	|	WHERE
	|		Table.Recorder = &Recorder) AS ChangesTable
	|
	|GROUP BY
	|	ChangesTable.TransferOrder,
	|	ChangesTable.Products,
	|	ChangesTable.Characteristic,
	|	ChangesTable.Series
	|
	|HAVING
	|	SUM(ChangesTable.ToRegisterUpdate) <> 0
	|	OR SUM(ChangesTable.OrderedUpdate) <> 0
	|;
	|DROP RegisteredRecordsMoveOrdersBeforeRecording
	|";
	
	Selection = Query.ExecuteBatch()[0].Select();
	HasChanges = Selection.Next() And Selection.Count > 0;
	DocumentsPosting.RegisterControlTable(AdditionalProperties,
		"RegisteredRecordsOrdersToMoveChange", HasChanges);
	
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
		|	Table.TransferOrder,
		|	Table.Products,
		|	Table.Characteristic,
		|	Table.Series
		|INTO RegisteredRecordsOrdersToMoveChangeDimensionalGoods
		|FROM
		|	RegisteredRecordsOrdersToMoveChange AS Table
		|WHERE 
		|	Table.Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfUnits)
		|GROUP BY
		|	Table.TransferOrder,
		|	Table.Products,
		|	Table.Characteristic,
		|	Table.Series
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
		// Main table
		QueryText = QueryText + "
		|SELECT
		|	TransferOrders.RecordType        AS RecordType,
		|	TransferOrders.TransferOrder AS TransferOrder,
		|	TransferOrders.Products       AS Products,
		|	TransferOrders.Characteristic     AS Characteristic,
		|	TransferOrders.Series              AS Series,
		|	TransferOrders.ToRegister        AS ToRegister
		|INTO TTMoveOrders
		|FROM
		|	AccumulationRegister.TransferOrders AS TransferOrders
		|	INNER JOIN
		|		RegisteredRecordsOrdersToMoveChange AS Changes
		|		ON TransferOrders.TransferOrder = Changes.TransferOrder
		|			AND TransferOrders.Products    = Changes.Products
		|			AND TransferOrders.Characteristic  = Changes.Characteristic
		|			AND TransferOrders.Series           = Changes.Series
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
		// Tolerance
		QueryText = QueryText + "
		|SELECT
		|	TransferOrders.TransferOrder AS TransferOrder,
		|	TransferOrders.Products       AS Products,
		|	TransferOrders.Characteristic     AS Characteristic,
		|	TransferOrders.Series              AS Series,
		|	SUM(TransferOrders.ToRegister
		|		* (&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100)) AS AllowableVariance
		|INTO TTToleranceMoveOrders
		|FROM
		|	TTMoveOrders AS TransferOrders
		|	INNER JOIN
		|		RegisteredRecordsOrdersToMoveChangeDimensionalGoods AS Changes
		|		ON TransferOrders.TransferOrder = Changes.TransferOrder
		|			AND TransferOrders.Products    = Changes.Products
		|			AND TransferOrders.Characteristic  = Changes.Characteristic
		|			AND TransferOrders.Series           = Changes.Series
		|WHERE
		|	TransferOrders.RecordType = VALUE(AccumulationRecordType.Receipt)
		|GROUP BY
		|	TransferOrders.TransferOrder,
		|	TransferOrders.Products,
		|	TransferOrders.Characteristic,
		|	TransferOrders.Series
		|INDEX BY
		|	TransferOrder,
		|	Products,
		|	Characteristic,
		|	Series
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
		//Balance
		QueryText = QueryText + "
		|SELECT
		|	TransferOrders.TransferOrder AS TransferOrder,
		|	TransferOrders.Products       AS Products,
		|	TransferOrders.Characteristic     AS Characteristic,
		|	TransferOrders.Series              AS Series,
		|	SUM(CASE WHEN TransferOrders.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
		|			TransferOrders.ToRegister
		|		ELSE
		|			-TransferOrders.ToRegister
		|	END)                                 AS ToRegisterBalance
		|INTO TTMoveOrdersBalance
		|FROM
		|	TTMoveOrders AS TransferOrders
		|GROUP BY
		|	TransferOrders.TransferOrder,
		|	TransferOrders.Products,
		|	TransferOrders.Characteristic,
		|	TransferOrders.Series
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
		QueryText = QueryText + "
		|SELECT DISTINCT
		|	OrdersBalance.TransferOrder AS TransferOrder
		|FROM
		|	TTMoveOrdersBalance AS OrdersBalance
		|	INNER JOIN
		|		TTToleranceMoveOrders AS AcceptableDeviations
		|		ON
		|			OrdersBalance.TransferOrder = AcceptableDeviations.TransferOrder
		|			AND OrdersBalance.Products     = AcceptableDeviations.Products
		|			AND OrdersBalance.Characteristic   = AcceptableDeviations.Characteristic
		|			AND OrdersBalance.Series            = AcceptableDeviations.Series
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
				SampleOrder.TransferOrder);
			
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf