#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	TMCommonUse.CollapseRecordSet(ThisObject, True);
	
	If DataExchange.Load Or Not DocumentsPosting.CalculateChanges_(AdditionalProperties) Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	VerificationRequired = True;
	
	For Each Record In ThisObject Do
		If (Record.RecordType = AccumulationRecordType.Expense And Record.InStock <> 0)
		 Or (Record.RecordType = AccumulationRecordType.Receipt And Record.ToShip <> 0)Then
			VerificationRequired = Common.ObjectAttributeValue(Record.Warehouse,"RealTimeStockControl");
			Break;
		EndIf;
	EndDo;
	
	If Not VerificationRequired Then
		AdditionalProperties.CalculateChanges_ = False;
		Return;
	EndIf;
	
	LockForUpdate = True;
	
	// The current state of the set is placed in the temporary table "
	// Movement of goods by Record" in order to get a change in the new set relative to the current one when recording.
	Query = New Query;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.SetParameter("IsNew",    AdditionalProperties.DocumentProperties.IsNew);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.Text =
	"SELECT
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Purpose AS Purpose,
	|	Table.ControlledLotReference AS ControlledLotReference,
	|	Table.Series AS Series,
	|	Table.Warehouse AS Warehouse,
	|	Table.Premise AS Premise,
	|	CASE
	|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN Table.InStock
	|		ELSE -Table.InStock
	|	END AS InStockBeforeWrite,
	|	CASE
	|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN Table.ToShip
	|		ELSE -Table.ToShip
	|	END AS ToShipBeforeWrite
	|INTO MovementOfGoodsInWarehousesBeforeRecording
	|FROM
	|	AccumulationRegister.ProductStock AS Table
	|WHERE
	|	Table.Recorder = &Recorder
	|	AND (NOT &IsNew)
	|	AND Table.ToControlBalance";
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
	|	ChangesTable.Products AS Products,
	|	ChangesTable.Characteristic AS Characteristic,
	|	ChangesTable.Purpose AS Purpose,
	|	ChangesTable.ControlledLotReference AS ControlledLotReference,
	|	ChangesTable.Series AS Series,
	|	ChangesTable.Warehouse AS Warehouse,
	|	ChangesTable.Premise AS Premise,
	|	SUM(ChangesTable.InStockUpdate) AS InStockUpdate,
	|	SUM(ChangesTable.ToShipUpdate) AS ToShipUpdate
	|INTO MovementOfGoodsInWarehousesChange
	|FROM
	|	(SELECT
	|		Table.Products AS Products,
	|		Table.Characteristic AS Characteristic,
	|		Table.Purpose AS Purpose,
	|		Table.ControlledLotReference AS ControlledLotReference,
	|		Table.Series AS Series,
	|		Table.Warehouse AS Warehouse,
	|		Table.Premise AS Premise,
	|		Table.InStockBeforeWrite AS InStockUpdate,
	|		Table.ToShipBeforeWrite AS ToShipUpdate
	|	FROM
	|		MovementOfGoodsInWarehousesBeforeRecording AS Table
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Products,
	|		Table.Characteristic,
	|		Table.Purpose,
	|		Table.ControlledLotReference,
	|		Table.Series,
	|		Table.Warehouse,
	|		Table.Premise,
	|		CASE
	|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -Table.InStock
	|			ELSE Table.InStock
	|		END,
	|		CASE
	|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -Table.ToShip
	|			ELSE Table.ToShip
	|		END
	|	FROM
	|		AccumulationRegister.ProductStock AS Table
	|	WHERE
	|		Table.Recorder = &Recorder
	|		AND Table.ToControlBalance) AS ChangesTable
	|
	|GROUP BY
	|	ChangesTable.Products,
	|	ChangesTable.Warehouse,
	|	ChangesTable.Characteristic,
	|	ChangesTable.Purpose,
	|	ChangesTable.ControlledLotReference,
	|	ChangesTable.Series,
	|	ChangesTable.Premise
	|
	|HAVING
	|	(SUM(ChangesTable.InStockUpdate) > 0
	|		OR SUM(ChangesTable.ToShipUpdate) < 0)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ChangesTable.Products AS Products,
	|	ChangesTable.Characteristic AS Characteristic,
	|	ChangesTable.Purpose AS Purpose,
	|	ChangesTable.ControlledLotReference AS ControlledLotReference,
	|	ChangesTable.Series AS Series,
	|	ChangesTable.Warehouse AS Warehouse,
	|	ChangesTable.Premise AS Premise,
	|	SUM(ChangesTable.InStockUpdate) AS InStockUpdate
	|INTO RegisteredRecordedProductStockChangesSummary
	|FROM
	|	(SELECT
	|		Table.Products AS Products,
	|		Table.Characteristic AS Characteristic,
	|		Table.Purpose AS Purpose,
	|		Table.ControlledLotReference AS ControlledLotReference,
	|		Table.Series AS Series,
	|		Table.Warehouse AS Warehouse,
	|		Table.Premise AS Premise,
	|		Table.InStockBeforeWrite AS InStockUpdate
	|	FROM
	|		MovementOfGoodsInWarehousesBeforeRecording AS Table
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Products,
	|		Table.Characteristic,
	|		Table.Purpose,
	|		Table.ControlledLotReference,
	|		Table.Series,
	|		Table.Warehouse,
	|		Table.Premise,
	|		CASE
	|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -Table.InStock
	|			ELSE Table.InStock
	|		END
	|	FROM
	|		AccumulationRegister.ProductStock AS Table
	|	WHERE
	|		Table.Recorder = &Recorder
	|		AND Table.ToControlBalance) AS ChangesTable
	|
	|GROUP BY
	|	ChangesTable.Products,
	|	ChangesTable.Warehouse,
	|	ChangesTable.Characteristic,
	|	ChangesTable.Purpose,
	|	ChangesTable.ControlledLotReference,
	|	ChangesTable.Series,
	|	ChangesTable.Premise
	|
	|HAVING
	|	SUM(ChangesTable.InStockUpdate) <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP MovementOfGoodsInWarehousesBeforeRecording";
	
	QueryResult = Query.ExecuteBatch();
	
	Selection = QueryResult[0].Select();
	DocumentsPosting.RegisterControlTable(AdditionalProperties,
		"MovementOfGoodsInWarehousesChange", Selection.Next() And Selection.Count > 0);
	
	Selection = QueryResult[1].Select();
	DocumentsPosting.RegisterControlTable(AdditionalProperties,
		"RegisteredRecordedProductStockChangesSummary", Selection.Next() And Selection.Count > 0);
	
EndProcedure

#EndRegion

#EndIf