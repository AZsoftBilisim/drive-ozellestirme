#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	TMCommonUse.CollapseRecordSet(ThisObject, True);
	
	If DataExchange.Load Or Not DocumentsPosting.CalculateChanges_(AdditionalProperties) Then
		Return;
	EndIf;
	
	VerificationRequired = True;
	
	For Each Record In ThisObject Do
		
		If (Record.RecordType = AccumulationRecordType.Expense
				And Record.InStock <> 0)
			Or (Record.RecordType = AccumulationRecordType.Receipt
				And Record.ForPicking <> 0) Then
			
			VerificationRequired = Common.ObjectAttributeValue(Record.Cell,
				"Owner.RealTimeStockControl");
			Break;
			
		EndIf;
		
	EndDo;
	
	If Not VerificationRequired Then
		AdditionalProperties.CalculateChanges_ = False;
		Return;
	EndIf;
	
	LockForUpdate = True;
	
	ArrayOfCellTypes = New Array;
	ArrayOfCellTypes.Add(Enums.TypesOfStorageCells.Location);
	CommonClientServer.SupplementArray(ArrayOfCellTypes, WarehousesClientServer.CellTypesAcceptance());
	CommonClientServer.SupplementArray(ArrayOfCellTypes, WarehousesClientServer.CellTypesShipment());
	
	// The current state of the set is placed in the temporary table "
	// Movement of goods by Record" in order to get a change in the new set relative to the current one when recording.
	Query = New Query;
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.SetParameter("IsNew", AdditionalProperties.DocumentProperties.IsNew);
	Query.SetParameter("ArrayOfCellTypes", ArrayOfCellTypes);
	Query.Text =
	"SELECT
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Purpose AS Purpose,
	|	Table.Series AS Series,
	|	Table.Package AS Package,
	|	Table.Cell AS Cell,
	|	CASE
	|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN Table.InStock
	|		ELSE -Table.InStock
	|	END AS InStockBeforeWrite,
	|	CASE
	|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN Table.ForPicking
	|		ELSE -Table.ForPicking
	|	END AS ForPickingBeforeWrite,
	|	CASE
	|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN Table.ForPlacement
	|		ELSE -Table.ForPlacement
	|	END AS ForPlacementBeforeWrite
	|INTO AllItemsInCellsBeforeRecording
	|FROM
	|	AccumulationRegister.GoodsInStorageBins AS Table
	|WHERE
	|	Table.Recorder = &Recorder
	|	AND (NOT &IsNew)
	|	AND Table.Cell.StorageBinType IN (&ArrayOfCellTypes)";
	Query.Execute();
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load
		Or Not DocumentsPosting.CalculateChanges_(AdditionalProperties) Then
		Return;
	EndIf;
	
	ArrayOfCellTypes = New Array;
	ArrayOfCellTypes.Add(Enums.TypesOfStorageCells.Location);
	CommonClientServer.SupplementArray(ArrayOfCellTypes, WarehousesClientServer.CellTypesAcceptance());
	CommonClientServer.SupplementArray(ArrayOfCellTypes, WarehousesClientServer.CellTypesShipment());
	
	// The change of the new set relative to the current one is calculated taking into account the accumulated changes
	// and placed in a temporary table.
	Query = New Query;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.SetParameter("ArrayOfCellTypes", ArrayOfCellTypes);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.Text =
	"SELECT
	|	ChangesTable.Products AS Products,
	|	ChangesTable.Characteristic AS Characteristic,
	|	ChangesTable.Purpose AS Purpose,
	|	ChangesTable.Series AS Series,
	|	ChangesTable.Package AS Package,
	|	ChangesTable.Cell AS Cell,
	|	SUM(ChangesTable.InStockUpdate) AS InStockUpdate,
	|	SUM(ChangesTable.ForPickingUpdate) AS ForPickingUpdate,
	|	SUM(ChangesTable.ForPlacementUpdate) AS ForPlacementUpdate
	|INTO MovementOfGoodsInCellsChange
	|FROM
	|	(SELECT
	|		Table.Products AS Products,
	|		Table.Characteristic AS Characteristic,
	|		Table.Purpose AS Purpose,
	|		Table.Series AS Series,
	|		Table.Package AS Package,
	|		Table.Cell AS Cell,
	|		Table.InStockBeforeWrite AS InStockUpdate,
	|		Table.ForPickingBeforeWrite AS ForPickingUpdate,
	|		Table.ForPlacementBeforeWrite AS ForPlacementUpdate
	|	FROM
	|		AllItemsInCellsBeforeRecording AS Table
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Products,
	|		Table.Characteristic,
	|		Table.Purpose,
	|		Table.Series,
	|		Table.Package,
	|		Table.Cell,
	|		CASE
	|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -Table.InStock
	|			ELSE Table.InStock
	|		END,
	|		CASE
	|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -Table.ForPicking
	|			ELSE Table.ForPicking
	|		END,
	|		CASE
	|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -Table.ForPlacement
	|			ELSE Table.ForPlacement
	|		END
	|	FROM
	|		AccumulationRegister.GoodsInStorageBins AS Table
	|	WHERE
	|		Table.Recorder = &Recorder
	|	 	AND Table.Cell.StorageBinType IN (&ArrayOfCellTypes)) AS ChangesTable
	|
	|GROUP BY
	|	ChangesTable.Products,
	|	ChangesTable.Package,
	|	ChangesTable.Characteristic,
	|	ChangesTable.Purpose,
	|	ChangesTable.Series,
	|	ChangesTable.Cell
	|
	|HAVING
	// By cash, a decrease in the arrival and an increase in the expense will lead to an incorrect state of the register.
	|	(SUM(ChangesTable.InStockUpdate) > 0
	// According to KOTBOR, an increase in arrival and a decrease in consumption will lead to an incorrect state of the register.
	|		OR SUM(ChangesTable.ForPickingUpdate) < 0
	// According to the placement, it is required to verify that only isolated goods are placed in the area of separate storage for
	// one purpose.
	|		OR SUM(ChangesTable.ForPlacementUpdate) < 0)
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP AllItemsInCellsBeforeRecording";
	
	QueryResult = Query.ExecuteBatch()[0]; // QueryResult
	Selection = QueryResult.Select();
	DocumentsPosting.RegisterControlTable(AdditionalProperties,
		"MovementOfGoodsInCellsChange", Selection.Next() And Selection.Count > 0);
	
EndProcedure

#EndRegion

#EndIf