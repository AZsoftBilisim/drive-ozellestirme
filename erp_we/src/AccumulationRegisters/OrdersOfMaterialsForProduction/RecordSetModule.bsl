#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
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
	|	Table.ReferenceOrder                 AS ReferenceOrder,
	|	Table.Products                 AS Products,
	|	Table.Characteristic               AS Characteristic,
	|	Table.Series                        AS Series,
	|	Table.Warehouse                        AS Warehouse,
	|	Table.Department                AS Department,
	|	Table.Purpose                   AS Purpose,
	|	Table.AssignmentSender        AS AssignmentSender,
	|	Table.RowCode                    AS RowCode,
	|	CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|			Table.ToRegister
	|		ELSE
	|			-Table.ToRegister
	|	END                                AS ToRegisterBeforeWrite
	|INTO RegisteredRecordsOrdersMaterialsIntoProductionBeforeRecording
	|FROM
	|	AccumulationRegister.OrdersOfMaterialsForProduction AS Table
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
	|	ChangesTable.ReferenceOrder                AS ReferenceOrder,
	|	ChangesTable.Products                AS Products,
	|	ChangesTable.Characteristic              AS Characteristic,
	|	ChangesTable.Series                       AS Series,
	|	ChangesTable.RowCode                   AS RowCode,
	|	ChangesTable.Warehouse                       AS Warehouse,
	|	ChangesTable.Department               AS Department,
	|	ChangesTable.Purpose                  AS Purpose,
	|	ChangesTable.AssignmentSender       AS AssignmentSender,
	|	SUM(ChangesTable.ToRegisterUpdate) AS ToRegisterUpdate
	|INTO RegisteredRecordsOrdersOfMaterialsIntoProductionChange
	|FROM
	|	(SELECT
	|		Table.ReferenceOrder                 AS ReferenceOrder,
	|		Table.Products                 AS Products,
	|		Table.Characteristic               AS Characteristic,
	|		Table.Series                        AS Series,
	|		Table.Warehouse                        AS Warehouse,
	|		Table.Department                AS Department,
	|		Table.Purpose                   AS Purpose,
	|		Table.AssignmentSender        AS AssignmentSender,
	|		Table.RowCode                    AS RowCode,
	|		Table.ToRegisterBeforeWrite      AS ToRegisterUpdate
	|	FROM
	|		RegisteredRecordsOrdersMaterialsIntoProductionBeforeRecording AS Table
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.ReferenceOrder                 AS ReferenceOrder,
	|		Table.Products                 AS Products,
	|		Table.Characteristic               AS Characteristic,
	|		Table.Series                        AS Series,
	|		Table.Warehouse                        AS Warehouse,
	|		Table.Department                AS Department,
	|		Table.Purpose                   AS Purpose,
	|		Table.AssignmentSender        AS AssignmentSender,
	|		Table.RowCode                    AS RowCode,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|				-Table.ToRegister
	|			ELSE
	|				Table.ToRegister
	|		END                                AS ToRegisterUpdate
	|	FROM
	|		AccumulationRegister.OrdersOfMaterialsForProduction AS Table
	|	WHERE
	|		Table.Recorder = &Recorder) AS ChangesTable
	|
	|GROUP BY
	|	ChangesTable.ReferenceOrder,
	|	ChangesTable.Products,
	|	ChangesTable.Characteristic,
	|	ChangesTable.Series,
	|	ChangesTable.Warehouse,
	|	ChangesTable.Department,
	|	ChangesTable.Purpose,
	|	ChangesTable.AssignmentSender,
	|	ChangesTable.RowCode
	|
	|HAVING
	|	SUM(ChangesTable.ToRegisterUpdate) > 0
	|;
	|DROP RegisteredRecordsOrdersMaterialsIntoProductionBeforeRecording
	|";
	
	Selection = Query.ExecuteBatch()[0].Select();
	HasChanges = Selection.Next() And Selection.Count > 0;
	DocumentsPosting.RegisterControlTable(AdditionalProperties,
		"RegisteredRecordsOrdersOfMaterialsIntoProductionChange", HasChanges);
	
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
		|	Table.ReferenceOrder,
		|	Table.Products,
		|	Table.Characteristic,
		|	Table.Series,
		|	Table.Purpose,
		|	Table.AssignmentSender,
		|	Table.Department,
		|	Table.RowCode,
		|	Table.Warehouse
		|INTO RegisteredRecordsOrdersOfMaterialsIntoProductionChangeDimensionalGoods
		|FROM
		|	RegisteredRecordsOrdersOfMaterialsIntoProductionChange AS Table
		|WHERE 
		|	Table.Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfUnits)
		|GROUP BY
		|	Table.ReferenceOrder,
		|	Table.Products,
		|	Table.Characteristic,
		|	Table.Series,
		|	Table.Purpose,
		|	Table.AssignmentSender,
		|	Table.Department,
		|	Table.RowCode,
		|	Table.Warehouse
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		// Main table
		|SELECT
		|	Table.RecordType    AS RecordType,
		|	Table.ReferenceOrder   AS ReferenceOrder,
		|	Table.Products   AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse          AS Warehouse,
		|	Table.Series          AS Series,
		|	Table.Purpose     AS Purpose,
		|	Table.AssignmentSender AS AssignmentSender,
		|	Table.Department  AS Department,
		|	Table.RowCode      AS RowCode,
		|	Table.ToRegister    AS ToRegister
		|INTO TTMaterialOrdersInProduction
		|FROM
		|	RegisteredRecordsOrdersOfMaterialsIntoProductionChangeDimensionalGoods AS Changes
		|	LEFT JOIN
		|		AccumulationRegister.OrdersOfMaterialsForProduction AS Table
		|		ON Table.ReferenceOrder      = Changes.ReferenceOrder
		|			AND Table.Products   = Changes.Products
		|			AND Table.Characteristic = Changes.Characteristic
		|			AND Table.Warehouse          = Changes.Warehouse
		|			AND Table.Series          = Changes.Series
		|			AND Table.Purpose     = Changes.Purpose
		|			AND Table.AssignmentSender = Changes.AssignmentSender
		|			AND Table.Department  = Changes.Department
		|			AND Table.RowCode      = Changes.RowCode
		|WHERE
		|	NOT Changes.ReferenceOrder IS NULL
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|DROP RegisteredRecordsOrdersOfMaterialsIntoProductionChangeDimensionalGoods
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		// Tolerance
		|SELECT
		|	Table.ReferenceOrder   AS ReferenceOrder,
		|	Table.Products   AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse          AS Warehouse,
		|	Table.Series          AS Series,
		|	Table.Purpose     AS Purpose,
		|	Table.AssignmentSender AS AssignmentSender,
		|	Table.Department  AS Department,
		|	Table.RowCode      AS RowCode,
		|	SUM(Table.ToRegister
		|		* (&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100)) AS AllowableVariance
		|INTO TTPermissibleDeviationsOrdersOfMaterialsInProduction
		|FROM
		|	TTMaterialOrdersInProduction AS Table
		|WHERE
		|	Table.RecordType = VALUE(AccumulationRecordType.Receipt)
		|GROUP BY
		|	Table.ReferenceOrder,
		|	Table.Products,
		|	Table.Characteristic,
		|	Table.Warehouse,
		|	Table.Series,
		|	Table.Purpose,
		|	Table.AssignmentSender,
		|	Table.Department,
		|	Table.RowCode
		|INDEX BY
		|	ReferenceOrder,
		|	Products,
		|	Characteristic,
		|	Warehouse,
		|	Series,
		|	Purpose,
		|	AssignmentSender,
		|	Department,
		|	RowCode
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		//Balance
		|SELECT
		|	Table.ReferenceOrder       AS ReferenceOrder,
		|	Table.Products       AS Products,
		|	Table.Characteristic     AS Characteristic,
		|	Table.Warehouse              AS Warehouse,
		|	Table.Series              AS Series,
		|	Table.Purpose         AS Purpose,
		|	Table.AssignmentSender AS AssignmentSender,
		|	Table.Department  AS Department,
		|	Table.RowCode          AS RowCode,
		|	SUM(CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
		|			Table.ToRegister
		|		ELSE
		|			-Table.ToRegister
		|	END)                     AS ToRegisterBalance
		|INTO TTMaterialOrdersInProductionBalance
		|FROM
		|	TTMaterialOrdersInProduction AS Table
		|GROUP BY
		|	Table.ReferenceOrder,
		|	Table.Products,
		|	Table.Characteristic,
		|	Table.Warehouse,
		|	Table.Series,
		|	Table.Purpose,
		|	Table.AssignmentSender,
		|	Table.Department,
		|	Table.RowCode
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT DISTINCT
		|	Table.ReferenceOrder AS ReferenceOrder
		|FROM
		|	TTMaterialOrdersInProductionBalance AS Table
		|	INNER JOIN
		|		TTPermissibleDeviationsOrdersOfMaterialsInProduction AS AcceptableDeviations
		|		ON
		|			Table.ReferenceOrder     = AcceptableDeviations.ReferenceOrder
		|			AND Table.RowCode      = AcceptableDeviations.RowCode
		|			AND Table.Products   = AcceptableDeviations.Products
		|			AND Table.Characteristic = AcceptableDeviations.Characteristic
		|			AND Table.Warehouse          = AcceptableDeviations.Warehouse
		|			AND Table.Series          = AcceptableDeviations.Series
		|			AND Table.Purpose     = AcceptableDeviations.Purpose
		|			AND Table.AssignmentSender = AcceptableDeviations.AssignmentSender
		|			AND Table.Department  = AcceptableDeviations.Department
		|WHERE
		|	Table.ToRegisterBalance <= AcceptableDeviations.AllowableVariance
		|	AND Table.ToRegisterBalance >= -AcceptableDeviations.AllowableVariance";
		
		Query.Text = QueryText;
		
		SampleOrder = Query.Execute().Select();
		
		While SampleOrder.Next() Do
			
			InformationRegisters.OrderQueueToAdjustRowsOfMeasuringGoods.AddOrderToQueue(SampleOrder.ReferenceOrder);
			
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
