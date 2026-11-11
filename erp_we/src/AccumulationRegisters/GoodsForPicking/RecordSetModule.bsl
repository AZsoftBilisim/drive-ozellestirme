#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	TMCommonUse.CollapseRecordSet(ThisObject, True);
	
	If DataExchange.Load Or Not DocumentsPosting.CalculateChanges_(AdditionalProperties) Then
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
	|	Table.Series AS Series,
	|	Table.ReferenceOrder AS ReferenceOrder,
	|	CASE
	|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN Table.Picked
	|		ELSE -Table.Picked
	|	END AS PickedBeforeWrite,
	|	CASE
	|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN Table.BeingPicked
	|		ELSE -Table.BeingPicked
	|	END AS BeingPickedBeforeWrite,
	|	CASE
	|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN Table.ForPicking
	|		ELSE -Table.ForPicking
	|	END AS ForPickingBeforeWrite
	|INTO PrepareGoodsForSelectionBeforeRecording
	|FROM
	|	AccumulationRegister.GoodsForPicking AS Table
	|WHERE
	|	Table.Recorder = &Recorder
	|	AND NOT &IsNew
	|	AND Table.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)";
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
	|	ChangesTable.Series AS Series,
	|	ChangesTable.ReferenceOrder AS ReferenceOrder,
	|	SUM(ChangesTable.ForPickingUpdate) AS ForPickingUpdate,
	|	SUM(ChangesTable.BeingPickedUpdate) AS BeingPickedUpdate,
	|	SUM(ChangesTable.PickedUpdate) AS PickedUpdate
	|INTO MovementOfGoodsToSelectionChange
	|FROM
	|	(SELECT
	|		Table.Products AS Products,
	|		Table.Characteristic AS Characteristic,
	|		Table.Purpose AS Purpose,
	|		Table.Series AS Series,
	|		Table.ReferenceOrder AS ReferenceOrder,
	|		Table.ForPickingBeforeWrite AS ForPickingUpdate,
	|		Table.BeingPickedBeforeWrite AS BeingPickedUpdate,
	|		Table.PickedBeforeWrite AS PickedUpdate
	|	FROM
	|		PrepareGoodsForSelectionBeforeRecording AS Table
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Products,
	|		Table.Characteristic,
	|		Table.Purpose,
	|		Table.Series,
	|		Table.ReferenceOrder,
	|		CASE
	|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -Table.ForPicking
	|			ELSE Table.ForPicking
	|		END,
	|		CASE
	|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -Table.BeingPicked
	|			ELSE Table.BeingPicked
	|		END,
	|		CASE
	|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -Table.Picked
	|			ELSE Table.Picked
	|		END
	|	FROM
	|		AccumulationRegister.GoodsForPicking AS Table
	|	WHERE
	|		Table.Recorder = &Recorder 
	|		AND Table.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)) AS ChangesTable
	|
	|GROUP BY
	|	ChangesTable.Products,
	|	ChangesTable.ReferenceOrder,
	|	ChangesTable.Characteristic,
	|	ChangesTable.Purpose,
	|	ChangesTable.Series
	|
	|HAVING
	// According to KOTBOR, a decrease in arrival and an increase in consumption will lead to an incorrect state of the register.
	|	(SUM(ChangesTable.ForPickingUpdate) > 0
	// If the software is selected, an increase in the arrival and a decrease in the expense will lead to an incorrect state of the register.
	|		OR SUM(ChangesTable.BeingPickedUpdate)< 0 
	// by Selected, any change will lead to an incorrect state of the register
	|		OR SUM(ChangesTable.PickedUpdate) <> 0) 
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP PrepareGoodsForSelectionBeforeRecording";
	
	QueryResult = Query.ExecuteBatch()[0]; // QueryResult
	Selection = QueryResult.Select();
	DocumentsPosting.RegisterControlTable(AdditionalProperties,
		"MovementOfGoodsToSelectionChange", Selection.Next() And Selection.Count > 0);
	
EndProcedure

#EndRegion

#EndIf