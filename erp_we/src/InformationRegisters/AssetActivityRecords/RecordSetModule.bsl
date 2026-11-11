#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load 
		Or Not DocumentsPosting.MonitorChanges(AdditionalProperties)
		Or Not NonCurrentAssets.VNAManagementIsUsed() Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	TableBeforeWrite.Period,
	|	TableBeforeWrite.Asset,
	|	TableBeforeWrite.RunningTimeValue,
	|	TableBeforeWrite.Value,
	|	TableBeforeWrite.AverageDailyValue
	|INTO AssetActivityRecordsBeforeWrite
	|FROM
	|	InformationRegister.AssetActivityRecords AS TableBeforeWrite
	|WHERE
	|	TableBeforeWrite.Recorder = &Recorder
	|	AND TableBeforeWrite.Active
	|	AND TableBeforeWrite.Asset REFS Catalog.Assets";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	
	Query.Execute();
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load 
		Or Not DocumentsPosting.MonitorChanges(AdditionalProperties)
		Or Not NonCurrentAssets.VNAManagementIsUsed() Then
		Return;
	EndIf;
	
	ListOfTtToDelete = New Array;
	ListOfTtToDelete.Add("AssetActivityRecordsBeforeWrite");
	ListOfTtToDelete.Add("OperatingConditionsChangeWithoutOrganization");
	
	ListOfRequests = New Array;
	
	QueryText = 
	"SELECT
	|	MIN(Table.Period)  AS Period,
	|	Table.FixedAsset AS FixedAsset
	|INTO OperatingConditionsChangeWithoutOrganization
	|FROM
	|	(SELECT
	|		TableBeforeWrite.Period              AS Period,
	|		TableBeforeWrite.Asset  AS FixedAsset
	|	FROM
	|		AssetActivityRecordsBeforeWrite AS TableBeforeWrite
	|			LEFT JOIN InformationRegister.AssetActivityRecords AS TableWhenWriting
	|			ON TableWhenWriting.Asset = TableBeforeWrite.Asset
	|				AND TableWhenWriting.RunningTimeValue = TableBeforeWrite.RunningTimeValue
	|				AND TableWhenWriting.Recorder = &Recorder
	|		WHERE
	|			(BEGINOFPERIOD(TableWhenWriting.Period, DAY) <> BEGINOFPERIOD(TableBeforeWrite.Period, DAY)
	|				OR TableWhenWriting.Value <> TableBeforeWrite.Value
	|				OR TableWhenWriting.AverageDailyValue <> TableBeforeWrite.AverageDailyValue
	|				OR TableWhenWriting.Period IS NULL)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TableWhenWriting.Period,
	|		TableWhenWriting.Asset
	|	FROM
	|		InformationRegister.AssetActivityRecords AS TableWhenWriting
	|			LEFT JOIN AssetActivityRecordsBeforeWrite AS TableBeforeWrite
	|			ON TableWhenWriting.Asset = TableBeforeWrite.Asset
	|				AND TableWhenWriting.RunningTimeValue = TableBeforeWrite.RunningTimeValue
	|		WHERE
	|			(BEGINOFPERIOD(TableWhenWriting.Period, DAY) <> BEGINOFPERIOD(TableBeforeWrite.Period, DAY)
	|				OR TableWhenWriting.Value <> TableBeforeWrite.Value
	|				OR TableWhenWriting.AverageDailyValue <> TableBeforeWrite.AverageDailyValue
	|				OR TableBeforeWrite.Period IS NULL)
	|			AND TableWhenWriting.Recorder = &Recorder
	|
	|	) AS Table
	|
	|GROUP BY
	|	Table.FixedAsset
	|	
	|INDEX BY
	|	FixedAsset";
	
	ListOfRequests.Add(QueryText);
	
	QueryText = NonCurrentAssetsLocalization.QueryTextTableAssetActivityRecordsUpdate(ListOfTtToDelete);
	
	If QueryText = Undefined Then
		
		QueryText =
		"SELECT
		|	MAX(FixedAssetDepreciationParametersManagementAccounting.Period) AS Period_Last,
		|	TableUpdate.Period AS Period,
		|	TableUpdate.FixedAsset AS FixedAsset
		|INTO ByRunningTimeUU_Last
		|FROM
		|	OperatingConditionsChangeWithoutOrganization AS TableUpdate
		|		INNER JOIN InformationRegister.FixedAssetDepreciationParametersManagementAccounting AS FixedAssetDepreciationParametersManagementAccounting
		|		ON (FixedAssetDepreciationParametersManagementAccounting.FixedAsset = TableUpdate.FixedAsset)
		|			AND (FixedAssetDepreciationParametersManagementAccounting.Period <= TableUpdate.Period)
		|			AND (FixedAssetDepreciationParametersManagementAccounting.CorrectionDate = DATETIME(1,1,1))
		|
		|GROUP BY
		|	TableUpdate.FixedAsset,
		|	TableUpdate.Period
		|
		|INDEX BY
		|	Period,
		|	FixedAsset
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ByRunningTimeUU_Last.Period AS Period,
		|	ByRunningTimeUU_Last.FixedAsset AS FixedAsset,
		|	FixedAssetDepreciationParametersManagementAccounting.Organization AS Organization,
		|	TRUE AS RecordInLocalAccounting,
		|	TRUE AS RecordInManAccounting,
		|	&Recorder AS Document
		|INTO AssetActivityRecordsUpdate
		|FROM
		|	ByRunningTimeUU_Last AS ByRunningTimeUU_Last
		|		INNER JOIN InformationRegister.FixedAssetDepreciationParametersManagementAccounting AS FixedAssetDepreciationParametersManagementAccounting
		|		ON (FixedAssetDepreciationParametersManagementAccounting.FixedAsset = ByRunningTimeUU_Last.FixedAsset)
		|			AND (FixedAssetDepreciationParametersManagementAccounting.Period = ByRunningTimeUU_Last.Period_Last)
		|			AND (FixedAssetDepreciationParametersManagementAccounting.CorrectionDate = DATETIME(1,1,1))
		|WHERE
		|	FixedAssetDepreciationParametersManagementAccounting.DepreciationMethod IN (
		|				VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction), 
		|				VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ByUniformDepreciationRatesPer1000KmOfMileage))";
		
		ListOfTtToDelete.Add("ByRunningTimeUU_Last");
		
	EndIf; 
	ListOfRequests.Add(QueryText);

	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	
	Query = New Query(QueryText);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	
	Selection = Query.Execute().Select();
	DocumentsPosting.RegisterControlTable(AdditionalProperties,
		"AssetActivityRecordsUpdate", Selection.Next() And Selection.Count > 0);
	
	TMCommonUse.DestroyTemporaryTables(AdditionalProperties.TempTablesManager, ListOfTtToDelete);
		
EndProcedure

#EndRegion

#EndIf
