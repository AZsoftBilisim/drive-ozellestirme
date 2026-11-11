#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not DocumentsPosting.MonitorChanges(AdditionalProperties) Then
		Return;
	EndIf;
	
	LockForUpdate = True;
	
	// The current state of the set is placed in a temporary table
	// in order to get a change in the new set relative to the current one when writing.
	
	Query = New Query;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.SetParameter("IsNew",AdditionalProperties.DocumentProperties.IsNew);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.Text =
	"SELECT
	|	Table.Period AS Period,
	|	Table.RecordType AS RecordType,
	|	Table.Organization AS Organization,
	|	Table.Department AS Department,
	|	Table.Individual AS Individual,
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Series AS Series,
	|	Table.Lot AS Lot,
	|	Table.LineOfBusiness AS LineOfBusiness,
	|	Table.AssetID AS AssetID,
	|	Table.CCDNumber AS CCDNumber,
	|	Table.QuantityByGBRN AS QuantityByGBRNBeforeWrite,
	|	Table.Count AS CountBeforeWrite
	|
	|INTO RegisteredRecordsOfInventoryInOperationBeforeRecording
	|
	|FROM
	|	AccumulationRegister.InventoryInOperation AS Table
	|WHERE
	|	Table.Recorder = &Recorder
	|	AND NOT &IsNew";
	Query.Execute();
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Or Not DocumentsPosting.MonitorChanges(AdditionalProperties) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	Table.Period AS Period,
	|	Table.Organization AS Organization,
	|	Table.Department AS Department,
	|	Table.Individual AS Individual,
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Series AS Series,
	|	Table.Lot AS Lot,
	|	Table.LineOfBusiness AS LineOfBusiness,
	|	Table.AssetID AS AssetID,
	|	Table.CCDNumber AS CCDNumber,
	|	SUM(Table.QuantityByGBRNUpdate) AS QuantityByGBRNUpdate,
	|	SUM(Table.CountUpdate) AS CountUpdate
	|INTO MovementOfTMTSVOperationChange
	|FROM
	|	(SELECT
	|		BEGINOFPERIOD(Table.Period, DAY) AS Period,
	|		Table.Organization AS Organization,
	|		Table.Department AS Department,
	|		Table.Individual AS Individual,
	|		Table.Products AS Products,
	|		Table.Characteristic AS Characteristic,
	|		Table.Series AS Series,
	|		Table.Lot AS Lot,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		Table.AssetID AS AssetID,
	|		CASE
	|			WHEN &UseTraceableImportedGoodsAccounting
	|				THEN Table.CCDNumber
	|			ELSE VALUE(Catalog.CCDNumbers.EmptyRef)
	|		END AS CCDNumber,
	|		CASE
	|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN Table.QuantityByGBRNBeforeWrite
	|			ELSE -Table.QuantityByGBRNBeforeWrite
	|		END AS QuantityByGBRNUpdate,
	|		CASE
	|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN Table.CountBeforeWrite
	|			ELSE -Table.CountBeforeWrite
	|		END AS CountUpdate
	|	FROM
	|		RegisteredRecordsOfInventoryInOperationBeforeRecording AS Table
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		BEGINOFPERIOD(Table.Period, DAY),
	|		Table.Organization,
	|		Table.Department,
	|		Table.Individual,
	|		Table.Products AS Products,
	|		Table.Characteristic AS Characteristic,
	|		Table.Series AS Series,
	|		Table.Lot AS Lot,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		Table.AssetID AS AssetID,
	|		CASE
	|			WHEN &UseTraceableImportedGoodsAccounting
	|				THEN Table.CCDNumber
	|			ELSE VALUE(Catalog.CCDNumbers.EmptyRef)
	|		END,
	|		CASE
	|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -Table.QuantityByGBRN
	|			ELSE Table.QuantityByGBRN
	|		END,
	|		CASE
	|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -Table.Count
	|			ELSE Table.Count
	|		END
	|	FROM
	|		AccumulationRegister.InventoryInOperation AS Table
	|	WHERE
	|		Table.Recorder = &Recorder
	|
	|	) AS Table
	|
	|GROUP BY
	|	Table.Period,
	|	Table.Organization,
	|	Table.Department,
	|	Table.Individual,
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.Series,
	|	Table.Lot,
	|	Table.LineOfBusiness,
	|	Table.AssetID,
	|	Table.CCDNumber
	|
	|HAVING
	|	(SUM(Table.CountUpdate) <> 0
	|		OR SUM(Table.QuantityByGBRNUpdate) <> 0)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP RegisteredRecordsOfInventoryInOperationBeforeRecording";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.SetParameter("UseTraceableImportedGoodsAccounting",
		GetFunctionalOption("UseTraceableImportedGoodsAccounting"));

	Result = Query.ExecuteBatch();
	
	Selection = Result[0].Select();
	DocumentsPosting.RegisterControlTable(AdditionalProperties,
		"MovementOfTMTSVOperationChange", Selection.Next() And Selection.Count > 0);
		
	InventoryInOperationLocalization.WhenRecordingTMTSVRegisterOfOperation(
		Filter.Recorder.Value, AdditionalProperties.TempTablesManager);
	
EndProcedure

#EndRegion

#EndIf