#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Or Not DocumentsPosting.CalculateChanges_(AdditionalProperties) Then
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
	|	BEGINOFPERIOD(Table.Period, MONTH) AS Month,
	|	Table.Organization             AS Organization,
	|	Table.ProductionLot      AS ProductionLot,
	|	Table.ReferenceOrder            AS ReferenceOrder,
	|	Table.WorkKind                AS WorkKind,
	|	Table.Performer             AS Performer,
	|	Table.Department           AS Department,
	|	Table.ReferenceRowCode   AS ReferenceRowCode,
	// It is only necessary to control the reduction of the Balance - for this, the indicator is taken modulo.
	|	CASE
	|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			AND Table.Count > 0
	|			THEN Table.Count
	|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			AND Table.Count < 0
	|			THEN -Table.Count
	|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Expense)
	|			AND Table.Count > 0
	|			THEN -Table.Count
	|		ELSE Table.Count
	|	END                           AS CountBeforeWrite
	|INTO AdditionalLaborCostsForRegistrationBeforeRecording
	|FROM
	|	AccumulationRegister.LaborCostsToRegister AS Table
	|WHERE
	|	Table.Recorder = &Recorder
	|	AND NOT &IsNew
	// Correction and storno can form negative Balances according to the original orders.
	|	AND NOT Table.ReversingEntry
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
	|	ChangesTable.Month                         AS Month,
	|	ChangesTable.Organization                   AS Organization,
	|	ChangesTable.ProductionLot            AS ProductionLot,
	|	ChangesTable.ReferenceOrder                  AS ReferenceOrder,
	|	ChangesTable.WorkKind                      AS WorkKind,
	|	ChangesTable.Performer                   AS Performer,
	|	ChangesTable.Department                 AS Department,
	|	ChangesTable.ReferenceRowCode         AS ReferenceRowCode,
	|	SUM(ChangesTable.CountUpdate)    AS CountUpdate
	|INTO AdditionalLaborCostsForRegistration
	|FROM
	|	(SELECT
	|		Table.Month                   AS Month,
	|		Table.Organization             AS Organization,
	|		Table.ProductionLot      AS ProductionLot,
	|		Table.ReferenceOrder            AS ReferenceOrder,
	|		Table.WorkKind                AS WorkKind,
	|		Table.Performer             AS Performer,
	|		Table.Department           AS Department,
	|		Table.ReferenceRowCode   AS ReferenceRowCode,
	|		Table.CountBeforeWrite  AS CountUpdate
	|	FROM
	|		AdditionalLaborCostsForRegistrationBeforeRecording AS Table
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		BEGINOFPERIOD(Table.Period, MONTH) AS Month,
	|		Table.Organization             AS Organization,
	|		Table.ProductionLot      AS ProductionLot,
	|		Table.ReferenceOrder            AS ReferenceOrder,
	|		Table.WorkKind                AS WorkKind,
	|		Table.Performer             AS Performer,
	|		Table.Department           AS Department,
	|		Table.ReferenceRowCode   AS ReferenceRowCode,
	// It is only necessary to control the reduction of the Balance - for this, the indicator is taken modulo.
	|		CASE
	|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				AND Table.Count > 0
	|				THEN -Table.Count
	|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				AND Table.Count < 0
	|				THEN Table.Count
	|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Expense)
	|				AND Table.Count > 0
	|				THEN Table.Count
	|			ELSE -Table.Count
	|		END                           AS CountUpdate
	|	FROM
	|		AccumulationRegister.LaborCostsToRegister AS Table
	|	WHERE
	|		Table.Recorder = &Recorder
	// Correction and storno can form negative Balances according to the original orders.
	|		AND NOT Table.ReversingEntry) AS ChangesTable
	|
	|GROUP BY
	|	ChangesTable.Month,
	|	ChangesTable.Organization,
	|	ChangesTable.ProductionLot,
	|	ChangesTable.ReferenceOrder,
	|	ChangesTable.WorkKind,
	|	ChangesTable.Performer,
	|	ChangesTable.Department,
	|	ChangesTable.ReferenceRowCode
	|
	|HAVING
	|	SUM(ChangesTable.CountUpdate) > 0
	|
	|INDEX BY
	|	Month,
	|	Organization,
	|	ProductionLot,
	|	ReferenceOrder,
	|	WorkKind,
	|	Performer,
	|	Department,
	|	ReferenceRowCode
	|;
	|DROP AdditionalLaborCostsForRegistrationBeforeRecording
	|";
	
	Selection = Query.ExecuteBatch()[0].Select();
	DocumentsPosting.RegisterControlTable(AdditionalProperties,
		"AdditionalLaborCostsForRegistration", Selection.Next() And Selection.Count > 0);
	
EndProcedure

#EndRegion

#EndIf