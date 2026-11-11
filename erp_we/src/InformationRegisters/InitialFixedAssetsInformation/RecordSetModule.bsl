#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	PrepareDataForGeneratingTasksBeforeRecording();
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	PrepareDataForGeneratingTasksWhenRecording();
	
EndProcedure

#EndRegion

#Region Private

Procedure PrepareDataForGeneratingTasksBeforeRecording()
	
	If Not DocumentsPosting.MonitorChanges(AdditionalProperties) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	TableBeforeWrite.Period AS Period,
	|	TableBeforeWrite.Organization AS Organization,
	|	TableBeforeWrite.FixedAsset AS FixedAsset,
	|	TableBeforeWrite.AccountingProcedureAC AS AccountingProcedureAC,
	|	TableBeforeWrite.AccountingProcedureTA AS AccountingProcedureTA,
	|	TableBeforeWrite.AccountingProcedureMA AS AccountingProcedureMA,
	|	TableBeforeWrite.DepreciationMethodAccounting AS DepreciationMethodAccounting,
	|	TableBeforeWrite.DepreciationMethodTaxAccounting AS DepreciationMethodTaxAccounting,
	|	TableBeforeWrite.CostBefore2002 AS CostBefore2002,
	|	TableBeforeWrite.DepreciationBefore2002 AS DepreciationBefore2002,
	|	TableBeforeWrite.DepreciationBefore2009 AS DepreciationBefore2009,
	|	TableBeforeWrite.ActualUsefulLifeBefore2009 AS ActualUsefulLifeBefore2009,
	|	TableBeforeWrite.InitialCostTA AS InitialCostTA,
	|	TableBeforeWrite.CommissioningDateAC AS CommissioningDateAC,
	|	TableBeforeWrite.CommissioningDateTA AS CommissioningDateTA,
	|	TableBeforeWrite.CommissioningDateMA AS CommissioningDateMA
	|INTO InitialFixedAssetsInformationBeforeWrite
	|FROM
	|	InformationRegister.InitialFixedAssetsInformation AS TableBeforeWrite
	|WHERE
	|	TableBeforeWrite.Recorder = &Recorder
	|	AND TableBeforeWrite.CorrectionDate = DATETIME(1,1,1)";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	
	Query.Execute();
	
EndProcedure

Procedure PrepareDataForGeneratingTasksWhenRecording()
	
	If Not DocumentsPosting.MonitorChanges(AdditionalProperties) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Recorder               AS Document,
	|	Table.Period             AS Period,
	|	Table.Organization        AS Organization,
	|	Table.FixedAsset   AS FixedAsset,
	|	MAX(Table.RecordInLocalAccounting) AS RecordInLocalAccounting,
	|	MAX(Table.RecordInManAccounting)  AS RecordInManAccounting
	|INTO InitialFixedAssetsInformationUpdate
	|FROM
	|	(SELECT
	|		TableBeforeWrite.Period            AS Period,
	|		TableBeforeWrite.Organization       AS Organization,
	|		TableBeforeWrite.FixedAsset  AS FixedAsset,
	|
	|		TableWhenWriting.Period IS NULL
	|			OR TableWhenWriting.AccountingProcedureAC <> TableBeforeWrite.AccountingProcedureAC 
	|			OR TableWhenWriting.AccountingProcedureTA <> TableBeforeWrite.AccountingProcedureTA
	|			OR TableWhenWriting.DepreciationMethodAccounting <> TableBeforeWrite.DepreciationMethodAccounting
	|			OR TableWhenWriting.CostBefore2002 <> TableBeforeWrite.CostBefore2002
	|			OR TableWhenWriting.DepreciationBefore2002 <> TableBeforeWrite.DepreciationBefore2002
	|			OR TableWhenWriting.DepreciationBefore2009 <> TableBeforeWrite.DepreciationBefore2009
	|			OR TableWhenWriting.ActualUsefulLifeBefore2009 <> TableBeforeWrite.ActualUsefulLifeBefore2009
	|			OR TableWhenWriting.InitialCostTA <> TableBeforeWrite.InitialCostTA AS RecordInLocalAccounting,
	|
	|		TableWhenWriting.Period IS NULL
	|			OR TableWhenWriting.AccountingProcedureMA <> TableBeforeWrite.AccountingProcedureMA
	|			OR BEGINOFPERIOD(TableWhenWriting.CommissioningDateMA, DAY) <> BEGINOFPERIOD(TableBeforeWrite.CommissioningDateMA, DAY) AS RecordInManAccounting
	|	FROM
	|		InitialFixedAssetsInformationBeforeWrite AS TableBeforeWrite
	|			LEFT JOIN InformationRegister.InitialFixedAssetsInformation AS TableWhenWriting
	|			ON TableWhenWriting.FixedAsset = TableBeforeWrite.FixedAsset
	|				AND TableWhenWriting.Organization = TableBeforeWrite.Organization
	|				AND BEGINOFPERIOD(TableWhenWriting.Period, DAY) = BEGINOFPERIOD(TableBeforeWrite.Period, DAY)
	|				AND TableWhenWriting.Recorder = &Recorder
	|				AND TableWhenWriting.CorrectionDate = DATETIME(1,1,1)
	|		WHERE
	|			(TableWhenWriting.Period IS NULL
	|				OR TableWhenWriting.AccountingProcedureAC <> TableBeforeWrite.AccountingProcedureAC
	|				OR TableWhenWriting.AccountingProcedureTA <> TableBeforeWrite.AccountingProcedureTA
	|				OR TableWhenWriting.AccountingProcedureMA <> TableBeforeWrite.AccountingProcedureMA
	|				OR TableWhenWriting.DepreciationMethodAccounting <> TableBeforeWrite.DepreciationMethodAccounting
	|				OR TableWhenWriting.DepreciationMethodTaxAccounting <> TableBeforeWrite.DepreciationMethodTaxAccounting
	|				OR TableWhenWriting.CostBefore2002 <> TableBeforeWrite.CostBefore2002
	|				OR TableWhenWriting.DepreciationBefore2002 <> TableBeforeWrite.DepreciationBefore2002
	|				OR TableWhenWriting.DepreciationBefore2009 <> TableBeforeWrite.DepreciationBefore2009
	|				OR TableWhenWriting.ActualUsefulLifeBefore2009 <> TableBeforeWrite.ActualUsefulLifeBefore2009
	|				OR TableWhenWriting.InitialCostTA <> TableBeforeWrite.InitialCostTA
	|				OR BEGINOFPERIOD(TableWhenWriting.CommissioningDateAC, DAY) <> BEGINOFPERIOD(TableBeforeWrite.CommissioningDateAC, DAY)
	|				OR BEGINOFPERIOD(TableWhenWriting.CommissioningDateTA, MONTH) <> BEGINOFPERIOD(TableBeforeWrite.CommissioningDateTA, MONTH)
	|				OR BEGINOFPERIOD(TableWhenWriting.CommissioningDateMA, DAY) <> BEGINOFPERIOD(TableBeforeWrite.CommissioningDateMA, DAY))
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TableWhenWriting.Period,
	|		TableWhenWriting.Organization,
	|		TableWhenWriting.FixedAsset,
	|
	|		TableBeforeWrite.Period IS NULL
	|			OR TableWhenWriting.AccountingProcedureAC <> TableBeforeWrite.AccountingProcedureAC 
	|			OR TableWhenWriting.AccountingProcedureTA <> TableBeforeWrite.AccountingProcedureTA
	|			OR TableWhenWriting.DepreciationMethodAccounting <> TableBeforeWrite.DepreciationMethodAccounting
	|			OR TableWhenWriting.CostBefore2002 <> TableBeforeWrite.CostBefore2002
	|			OR TableWhenWriting.DepreciationBefore2002 <> TableBeforeWrite.DepreciationBefore2002
	|			OR TableWhenWriting.DepreciationBefore2009 <> TableBeforeWrite.DepreciationBefore2009
	|			OR TableWhenWriting.ActualUsefulLifeBefore2009 <> TableBeforeWrite.ActualUsefulLifeBefore2009
	|			OR TableWhenWriting.InitialCostTA <> TableBeforeWrite.InitialCostTA AS RecordInLocalAccounting,
	|
	|		TableWhenWriting.Period IS NULL
	|			OR TableWhenWriting.AccountingProcedureMA <> TableBeforeWrite.AccountingProcedureMA
	|			OR BEGINOFPERIOD(TableWhenWriting.CommissioningDateMA, DAY) <> BEGINOFPERIOD(TableBeforeWrite.CommissioningDateMA, DAY) AS RecordInManAccounting
	|	FROM
	|		InformationRegister.InitialFixedAssetsInformation AS TableWhenWriting
	|			LEFT JOIN InitialFixedAssetsInformationBeforeWrite AS TableBeforeWrite
	|			ON TableWhenWriting.FixedAsset = TableBeforeWrite.FixedAsset
	|				AND TableWhenWriting.Organization = TableBeforeWrite.Organization
	|				AND BEGINOFPERIOD(TableWhenWriting.Period, DAY) = BEGINOFPERIOD(TableBeforeWrite.Period, DAY)
	|		WHERE
	|			(TableBeforeWrite.Period IS NULL
	|				OR TableWhenWriting.AccountingProcedureAC <> TableBeforeWrite.AccountingProcedureAC
	|				OR TableWhenWriting.AccountingProcedureTA <> TableBeforeWrite.AccountingProcedureTA
	|				OR TableWhenWriting.AccountingProcedureMA <> TableBeforeWrite.AccountingProcedureMA
	|				OR TableWhenWriting.DepreciationMethodAccounting <> TableBeforeWrite.DepreciationMethodAccounting
	|				OR TableWhenWriting.DepreciationMethodTaxAccounting <> TableBeforeWrite.DepreciationMethodTaxAccounting
	|				OR TableWhenWriting.CostBefore2002 <> TableBeforeWrite.CostBefore2002
	|				OR TableWhenWriting.DepreciationBefore2002 <> TableBeforeWrite.DepreciationBefore2002
	|				OR TableWhenWriting.DepreciationBefore2009 <> TableBeforeWrite.DepreciationBefore2009
	|				OR TableWhenWriting.ActualUsefulLifeBefore2009 <> TableBeforeWrite.ActualUsefulLifeBefore2009
	|				OR TableWhenWriting.InitialCostTA <> TableBeforeWrite.InitialCostTA
	|				OR BEGINOFPERIOD(TableWhenWriting.CommissioningDateAC, DAY) <> BEGINOFPERIOD(TableBeforeWrite.CommissioningDateAC, DAY)
	|				OR BEGINOFPERIOD(TableWhenWriting.CommissioningDateTA, DAY) <> BEGINOFPERIOD(TableBeforeWrite.CommissioningDateTA, DAY)
	|				OR BEGINOFPERIOD(TableWhenWriting.CommissioningDateMA, DAY) <> BEGINOFPERIOD(TableBeforeWrite.CommissioningDateMA, DAY))
	|			AND TableWhenWriting.Recorder = &Recorder
	|			AND TableWhenWriting.CorrectionDate = DATETIME(1,1,1)
	|
	|	) AS Table
	|
	|GROUP BY
	|	Table.Period,
	|	Table.Organization,
	|	Table.FixedAsset";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	
	Query.Text = Query.Text + Common.QueryBatchSeparator() + "DROP InitialFixedAssetsInformationBeforeWrite";
	
	Selection = Query.ExecuteBatch()[0].Select();
	DocumentsPosting.RegisterControlTable(AdditionalProperties,
		"InitialFixedAssetsInformationUpdate", Selection.Next() And Selection.Count > 0);
	
EndProcedure
 
#EndRegion

#EndIf
