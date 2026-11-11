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
	
	Query = New Query;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.SetParameter("IsNew",    AdditionalProperties.DocumentProperties.IsNew);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.Text =
	"SELECT
	|	CargoItemsForRecordingSurplusesAndShortages.Warehouse AS Warehouse,
	|	CargoItemsForRecordingSurplusesAndShortages.Premise AS Premise,
	|	CargoItemsForRecordingSurplusesAndShortages.Products AS Products,
	|	CargoItemsForRecordingSurplusesAndShortages.Characteristic AS Characteristic,
	|	CargoItemsForRecordingSurplusesAndShortages.Purpose AS Purpose,
	|	CargoItemsForRecordingSurplusesAndShortages.Series AS Series,
	|	CargoItemsForRecordingSurplusesAndShortages.CargoItem AS CargoItem,
	|	CASE
	|		WHEN CargoItemsForRecordingSurplusesAndShortages.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN CargoItemsForRecordingSurplusesAndShortages.Count
	|		ELSE -CargoItemsForRecordingSurplusesAndShortages.Count
	|	END AS Count
	|INTO RegisteredRecordsOfCommodityPlacesToReflectSurplusShortagesBeforeRecording
	|FROM
	|	AccumulationRegister.CargoItemsForRecordingSurplusesAndShortages AS CargoItemsForRecordingSurplusesAndShortages
	|WHERE
	|	NOT &IsNew
	|	AND CargoItemsForRecordingSurplusesAndShortages.Recorder = &Recorder";	
	
	Query.Execute();
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Or Not DocumentsPosting.MonitorChanges(AdditionalProperties) Then
		Return;
	EndIf;
	
	QueryTexts = New ValueList;
	
	QueryText =
	"SELECT DISTINCT
	|	NestedQuery.Warehouse,
	|	NestedQuery.Premise,
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	NestedQuery.Purpose,
	|	NestedQuery.Series
	|INTO TTTableOfChanges
	|FROM
	|	(SELECT
	|		ChangesTable.Warehouse AS Warehouse,
	|		ChangesTable.Premise AS Premise,
	|		ChangesTable.Products AS Products,
	|		ChangesTable.Characteristic AS Characteristic,
	|		ChangesTable.Purpose AS Purpose,
	|		ChangesTable.Series AS Series,
	|		ChangesTable.CargoItem AS CargoItem,
	|		SUM(ChangesTable.Count) AS Count
	|	FROM
	|		(SELECT
	|			BeforeWrite.Warehouse AS Warehouse,
	|			BeforeWrite.Premise AS Premise,
	|			BeforeWrite.Products AS Products,
	|			BeforeWrite.Characteristic AS Characteristic,
	|			BeforeWrite.Purpose AS Purpose,
	|			BeforeWrite.Series AS Series,
	|			BeforeWrite.CargoItem AS CargoItem,
	|			BeforeWrite.Count AS Count
	|		FROM
	|			RegisteredRecordsOfCommodityPlacesToReflectSurplusShortagesBeforeRecording AS BeforeWrite
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			CargoItemsForRecordingSurplusesAndShortages.Warehouse,
	|			CargoItemsForRecordingSurplusesAndShortages.Premise,
	|			CargoItemsForRecordingSurplusesAndShortages.Products,
	|			CargoItemsForRecordingSurplusesAndShortages.Characteristic,
	|			CargoItemsForRecordingSurplusesAndShortages.Purpose,
	|			CargoItemsForRecordingSurplusesAndShortages.Series,
	|			CargoItemsForRecordingSurplusesAndShortages.CargoItem,
	|			CASE
	|				WHEN CargoItemsForRecordingSurplusesAndShortages.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN -CargoItemsForRecordingSurplusesAndShortages.Count
	|				ELSE CargoItemsForRecordingSurplusesAndShortages.Count
	|			END
	|		FROM
	|			AccumulationRegister.CargoItemsForRecordingSurplusesAndShortages AS CargoItemsForRecordingSurplusesAndShortages
	|		WHERE
	|			CargoItemsForRecordingSurplusesAndShortages.Recorder = &Recorder) AS ChangesTable
	|	
	|	GROUP BY
	|		ChangesTable.Characteristic,
	|		ChangesTable.Premise,
	|		ChangesTable.Series,
	|		ChangesTable.Products,
	|		ChangesTable.Warehouse,
	|		ChangesTable.Purpose,
	|		ChangesTable.CargoItem
	|	
	|	HAVING
	|		SUM(ChangesTable.Count) <> 0) AS NestedQuery";
	
	QueryTexts.Add(QueryText, "TTTableOfChanges");
	
	QueryText =
	"SELECT
	|	ProductLocationsBalance.Warehouse,
	|	ProductLocationsBalance.Premise,
	|	ProductLocationsBalance.Products,
	|	ProductLocationsBalance.Characteristic,
	|	ProductLocationsBalance.Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	ProductLocationsBalance.Series,
	|	ProductLocationsBalance.CargoItem,
	|	ProductLocationsBalance.CountBalance
	|INTO TTGoodsPlacesBalances
	|FROM
	|	AccumulationRegister.CargoItemsForRecordingSurplusesAndShortages.Balance(
	|			,
	|			(Warehouse, Premise, Products, Characteristic, Purpose, Series) IN
	|				(SELECT
	|					ChangesTable.Warehouse AS Warehouse,
	|					ChangesTable.Premise AS Premise,
	|					ChangesTable.Products AS Products,
	|					ChangesTable.Characteristic AS Characteristic,
	|					ChangesTable.Purpose AS Purpose,
	|					ChangesTable.Series AS Series
	|				FROM
	|					TTTableOfChanges AS ChangesTable)) AS ProductLocationsBalance";
	
	QueryTexts.Add(QueryText, "TTGoodsPlacesBalances");
	
	WarehousesServer.QueryTextTTSetsOnCommodityRequirementsForReflectionOfSurplusShortages(QueryTexts);
	
	QueryText =
	"SELECT DISTINCT
	|	TTSetsOnCommodityRequirementsForReflectionOfSurplusShortages.Warehouse,
	|	TTSetsOnCommodityRequirementsForReflectionOfSurplusShortages.Premise
	|FROM
	|	TTSetsOnCommodityRequirementsForReflectionOfSurplusShortages AS TTSetsOnCommodityRequirementsForReflectionOfSurplusShortages";
	
	QueryTexts.Add(QueryText, "WarehousesPremisesForRegistrationOfSurplusShortages");
	
	QueryText = "
	|DROP RegisteredRecordsOfCommodityPlacesToReflectSurplusShortagesBeforeRecording";
	
	QueryTexts.Add(QueryText);
	
	Query = New Query;
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	
	WarehousesPremisesForRegistrationOfSurplusShortages = TMCommonUse.UploadResultsOfQuery(Query, QueryTexts,, True,True).WarehousesPremisesForRegistrationOfSurplusShortages;
	
	For Each WarehouseWareroom In WarehousesPremisesForRegistrationOfSurplusShortages Do
		
		WarehousesServer.AddToFormationQueueCorrectionOfSurplusShortagesByProductLocations(WarehouseWareroom.Warehouse, 
																								WarehouseWareroom.Premise, 
																								Filter.Recorder.Value);
		
	EndDo;
	
EndProcedure

#EndRegion

#EndIf