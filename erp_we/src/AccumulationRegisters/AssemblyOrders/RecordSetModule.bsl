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
	|	Table.ByAssemblyDisassemblyOrder  AS ByAssemblyDisassemblyOrder,
	|	Table.Products   AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Series          AS Series,
	|	Table.RowCode      AS RowCode,
	|	Table.AssemblyType      AS AssemblyType,
	|	CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|			Table.Ordered
	|		ELSE
	|			-Table.Ordered
	|	END                  AS OrderedBeforeWrite,
	|	CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|			Table.ToRegister
	|		ELSE
	|			-Table.ToRegister
	|	END                  AS ToRegisterBeforeWrite
	|INTO CreateBuildOrdersBeforeRecording
	|FROM
	|	AccumulationRegister.AssemblyOrders AS Table
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
	|	ChangesTable.ByAssemblyDisassemblyOrder               AS ByAssemblyDisassemblyOrder,
	|	ChangesTable.Products                AS Products,
	|	ChangesTable.Characteristic              AS Characteristic,
	|	ChangesTable.Series                       AS Series,
	|	ChangesTable.AssemblyType                   AS AssemblyType,
	|	SUM(ChangesTable.OrderedUpdate)    AS OrderedUpdate,
	|	SUM(ChangesTable.ToRegisterUpdate) AS ToRegisterUpdate
	|INTO RegisteredRecordsBuildOrdersChange
	|FROM
	|	(SELECT
	|		Table.ByAssemblyDisassemblyOrder       AS ByAssemblyDisassemblyOrder,
	|		Table.Products        AS Products,
	|		Table.Characteristic      AS Characteristic,
	|		Table.Series               AS Series,
	|		Table.AssemblyType           AS AssemblyType,
	|		Table.OrderedBeforeWrite    AS OrderedUpdate,
	|		Table.ToRegisterBeforeWrite AS ToRegisterUpdate
	|	FROM
	|		CreateBuildOrdersBeforeRecording AS Table
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.ByAssemblyDisassemblyOrder      AS ByAssemblyDisassemblyOrder,
	|		Table.Products       AS Products,
	|		Table.Characteristic     AS Characteristic,
	|		Table.Series              AS Series,
	|		Table.AssemblyType          AS AssemblyType,
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
	|		AccumulationRegister.AssemblyOrders AS Table
	|	WHERE
	|		Table.Recorder = &Recorder) AS ChangesTable
	|
	|GROUP BY
	|	ChangesTable.ByAssemblyDisassemblyOrder,
	|	ChangesTable.Products,
	|	ChangesTable.Characteristic,
	|	ChangesTable.Series,
	|	ChangesTable.AssemblyType
	|
	|HAVING
	|	SUM(ChangesTable.ToRegisterUpdate) <> 0
	|	OR SUM(ChangesTable.OrderedUpdate) <> 0
	|INDEX BY
	|	ChangesTable.ByAssemblyDisassemblyOrder,
	|	ChangesTable.Products,
	|	ChangesTable.Characteristic,
	|	ChangesTable.Series,
	|	ChangesTable.AssemblyType
	|;
	|DROP CreateBuildOrdersBeforeRecording
	|";
	
	Selection = Query.ExecuteBatch()[0].Select();
	HasChanges = Selection.Next() And Selection.Count > 0;
	DocumentsPosting.RegisterControlTable(AdditionalProperties,
		"RegisteredRecordsBuildOrdersChange", HasChanges);
	
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
		|	Table.ByAssemblyDisassemblyOrder,
		|	Table.Products,
		|	Table.Characteristic,
		|	Table.Series,
		|	Table.AssemblyType
		|INTO RegisteredRecordsAssemblyOrdersChangeDimensionalGoods
		|FROM
		|	RegisteredRecordsBuildOrdersChange AS Table
		|WHERE 
		|	Table.Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfUnits)
		|GROUP BY
		|	Table.ByAssemblyDisassemblyOrder,
		|	Table.Products,
		|	Table.Characteristic,
		|	Table.Series,
		|	Table.AssemblyType
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
		// Main table
		QueryText = QueryText + "
		|SELECT
		|	AssemblyOrders.RecordType    AS RecordType,
		|	AssemblyOrders.ByAssemblyDisassemblyOrder  AS ByAssemblyDisassemblyOrder,
		|	AssemblyOrders.Products   AS Products,
		|	AssemblyOrders.Characteristic AS Characteristic,
		|	AssemblyOrders.Series          AS Series,
		|	AssemblyOrders.AssemblyType      AS AssemblyType,
		|	AssemblyOrders.ToRegister    AS ToRegister
		|INTO TTAssemblyOrders
		|FROM
		|	AccumulationRegister.AssemblyOrders AS AssemblyOrders
		|	INNER JOIN
		|		RegisteredRecordsBuildOrdersChange AS Changes
		|		ON AssemblyOrders.ByAssemblyDisassemblyOrder     = Changes.ByAssemblyDisassemblyOrder
		|			AND AssemblyOrders.Products   = Changes.Products
		|			AND AssemblyOrders.Characteristic = Changes.Characteristic
		|			AND AssemblyOrders.Series          = Changes.Series
		|			AND AssemblyOrders.AssemblyType      = Changes.AssemblyType
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
		// Tolerance
		QueryText = QueryText + "
		|SELECT
		|	AssemblyOrders.ByAssemblyDisassemblyOrder  AS ByAssemblyDisassemblyOrder,
		|	AssemblyOrders.Products   AS Products,
		|	AssemblyOrders.Characteristic AS Characteristic,
		|	AssemblyOrders.Series          AS Series,
		|	AssemblyOrders.AssemblyType      AS AssemblyType,
		|	SUM(AssemblyOrders.ToRegister
		|		* (&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100)) AS AllowableVariance
		|INTO TTAcceptableDeviationsAssemblyOrders
		|FROM
		|	TTAssemblyOrders AS AssemblyOrders
		|	INNER JOIN
		|		RegisteredRecordsAssemblyOrdersChangeDimensionalGoods AS Changes
		|		ON AssemblyOrders.ByAssemblyDisassemblyOrder     = Changes.ByAssemblyDisassemblyOrder
		|			AND AssemblyOrders.Products   = Changes.Products
		|			AND AssemblyOrders.Characteristic = Changes.Characteristic
		|			AND AssemblyOrders.Series          = Changes.Series
		|			AND AssemblyOrders.AssemblyType      = Changes.AssemblyType
		|WHERE
		|	AssemblyOrders.RecordType = VALUE(AccumulationRecordType.Receipt)
		|GROUP BY
		|	AssemblyOrders.ByAssemblyDisassemblyOrder,
		|	AssemblyOrders.Products,
		|	AssemblyOrders.Characteristic,
		|	AssemblyOrders.Series,
		|	AssemblyOrders.AssemblyType
		|INDEX BY
		|	ByAssemblyDisassemblyOrder,
		|	Products,
		|	Characteristic,
		|	Series,
		|	AssemblyType
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
		//Balance
		QueryText = QueryText + "
		|SELECT
		|	AssemblyOrders.ByAssemblyDisassemblyOrder      AS ByAssemblyDisassemblyOrder,
		|	AssemblyOrders.Products       AS Products,
		|	AssemblyOrders.Characteristic     AS Characteristic,
		|	AssemblyOrders.Series              AS Series,
		|	AssemblyOrders.AssemblyType          AS AssemblyType,
		|	SUM(CASE WHEN AssemblyOrders.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
		|			AssemblyOrders.ToRegister
		|		ELSE
		|			-AssemblyOrders.ToRegister
		|	END)                            AS ToRegisterBalance
		|INTO TTAssemblyOrdersBalance
		|FROM
		|	TTAssemblyOrders AS AssemblyOrders
		|GROUP BY
		|	AssemblyOrders.ByAssemblyDisassemblyOrder,
		|	AssemblyOrders.Products,
		|	AssemblyOrders.Characteristic,
		|	AssemblyOrders.Series,
		|	AssemblyOrders.AssemblyType
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
		QueryText = QueryText + "
		|SELECT DISTINCT
		|	OrdersBalance.ByAssemblyDisassemblyOrder AS ByAssemblyDisassemblyOrder
		|FROM
		|	TTAssemblyOrdersBalance AS OrdersBalance
		|	INNER JOIN
		|		TTAcceptableDeviationsAssemblyOrders AS AcceptableDeviations
		|		ON
		|			OrdersBalance.ByAssemblyDisassemblyOrder    = AcceptableDeviations.ByAssemblyDisassemblyOrder
		|			AND OrdersBalance.Products   = AcceptableDeviations.Products
		|			AND OrdersBalance.Characteristic = AcceptableDeviations.Characteristic
		|			AND OrdersBalance.Series          = AcceptableDeviations.Series
		|			AND OrdersBalance.AssemblyType      = AcceptableDeviations.AssemblyType
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
				SampleOrder.ByAssemblyDisassemblyOrder);
			
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf