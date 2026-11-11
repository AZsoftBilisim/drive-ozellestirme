//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load
	 Or Not DocumentsPosting.CalculateChanges_(AdditionalProperties) Then
		Return;
	EndIf;
	
	LockForUpdate = True;
	
	// The current State of the set is placed in the temporary table "
	// Movements of the stat of the trobonuses of the pre-recording components" in order to get a change in the new set relative to the current one when recording
	QueryText = 
	"SELECT
	|	Table.Organization AS Organization,
	|	Table.Counterparty AS Counterparty,
	|	Table.Partner AS Partner,
	|	Table.BeginOfPeriod AS BeginOfPeriod,
	|	Table.PeriodEnding AS PeriodEnding,
	|	Table.TermDocument AS TermDocument,
	|	Table.Currency AS Currency,
	|	SUM(CASE
	|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN Table.AmountBonus
	|		ELSE -Table.AmountBonus
	|	END) AS AmountBonusBeforeWrite,
	|	SUM(CASE
	|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN Table.ToCertify
	|		ELSE -Table.ToCertify
	|	END) AS ToCertifyBeforeWrite,
	|	SUM(CASE
	|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN Table.ToSign
	|		ELSE -Table.ToSign
	|	END) AS ToSignBeforeWrite,
	|	SUM(CASE
	|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN -Table.ToWriteOff
	|		ELSE Table.ToWriteOff
	|	END) AS ToWriteOffBeforeWrite
	|INTO RegisteredRecordsBalancesRetroCustomerBonusesBeforeWrite
	|FROM
	|	AccumulationRegister.CustomerRebates AS Table
	|WHERE
	|	Table.Recorder = &Recorder
	|	AND NOT &IsNew
	|	AND NOT &DataExchange
	|	AND &CalculateChanges_
	|	AND &PostWithoutRebateBalanceCheck = FALSE
	|GROUP BY
	|	Table.Organization,
	|	Table.Counterparty,
	|	Table.Partner,
	|	Table.BeginOfPeriod,
	|	Table.PeriodEnding,
	|	Table.TermDocument,
	|	Table.Currency";
	
	Query = New Query(QueryText);
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.SetParameter("IsNew", AdditionalProperties.DocumentProperties.IsNew);
	Query.SetParameter("DataExchange", DataExchange.Load);
	Query.SetParameter(
		"CalculateChanges_",
		DocumentsPosting.CalculateChanges_(AdditionalProperties));
	Query.SetParameter(
		"PostWithoutRebateBalanceCheck",
		SessionParameters.PostWithoutRebateBalanceCheck);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	
	Query.Execute();
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load
	 Or Not DocumentsPosting.CalculateChanges_(AdditionalProperties) Then
		Return;
	EndIf;
	
	// The change of the new set relative to the current one is calculated taking into account the accumulated changes
	// and placed in a temporary table.
	//@skip-check bsl-ql-hub - The movementstatingstatecretrobonusyclientsrecording is created in the event before recording
	QueryText =
	"SELECT
	|	ChangesTable.Organization AS Organization,
	|	ChangesTable.Counterparty AS Counterparty,
	|	ChangesTable.Partner AS Partner,
	|	ChangesTable.BeginOfPeriod AS BeginOfPeriod,
	|	ChangesTable.PeriodEnding AS PeriodEnding,
	|	ChangesTable.TermDocument AS TermDocument,
	|	ChangesTable.Currency AS Currency,
	|	SUM(ChangesTable.AmountBonusUpdate) AS AmountBonusUpdate,
	|	SUM(ChangesTable.ToCertifyUpdate) AS ToCertifyUpdate,
	|	SUM(ChangesTable.ToSignUpdate) AS ToSignUpdate,
	|	SUM(ChangesTable.ToWriteOffUpdate) AS ToWriteOffUpdate
	|INTO RetroCustomerBonusesAreRegisteredRecordedUpdate
	|FROM
	|	(SELECT
	|		Table.Organization AS Organization,
	|		Table.Counterparty AS Counterparty,
	|		Table.Partner AS Partner,
	|		Table.BeginOfPeriod AS BeginOfPeriod,
	|		Table.PeriodEnding AS PeriodEnding,
	|		Table.TermDocument AS TermDocument,
	|		Table.Currency AS Currency,
	|		Table.AmountBonusBeforeWrite AS AmountBonusUpdate,
	|		Table.ToCertifyBeforeWrite AS ToCertifyUpdate,
	|		Table.ToSignBeforeWrite AS ToSignUpdate,
	|		Table.ToWriteOffBeforeWrite AS ToWriteOffUpdate
	|	FROM
	|		RegisteredRecordsBalancesRetroCustomerBonusesBeforeWrite AS Table
	|
	|	UNION ALL
	|
	|	SELECT
	|		Table.Organization AS Organization,
	|		Table.Counterparty AS Counterparty,
	|		Table.Partner AS Partner,
	|		Table.BeginOfPeriod AS BeginOfPeriod,
	|		Table.PeriodEnding AS PeriodEnding,
	|		Table.TermDocument AS TermDocument,
	|		Table.Currency AS Currency,
	|		CASE
	|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -Table.AmountBonus
	|			ELSE Table.AmountBonus
	|		END,
	|		CASE
	|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -Table.ToCertify
	|			ELSE Table.ToCertify
	|		END,
	|		CASE
	|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -Table.ToSign
	|			ELSE Table.ToSign
	|		END,
	|		CASE
	|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -Table.ToWriteOff
	|			ELSE Table.ToWriteOff
	|		END
	|	FROM
	|		AccumulationRegister.CustomerRebates AS Table
	|	WHERE
	|		Table.Recorder = &Recorder) AS ChangesTable
	|WHERE
	|	NOT &DataExchange
	|	AND &CalculateChanges_
	|	AND &PostWithoutRebatesBalanceCheck = FALSE
	|GROUP BY
	|	ChangesTable.Organization,
	|	ChangesTable.Counterparty,
	|	ChangesTable.Partner,
	|	ChangesTable.BeginOfPeriod,
	|	ChangesTable.PeriodEnding,
	|	ChangesTable.TermDocument,
	|	ChangesTable.Currency
	|HAVING
	|	(SUM(ChangesTable.AmountBonusUpdate) <> 0
	|	OR SUM(ChangesTable.ToCertifyUpdate) <> 0
	|	OR SUM(ChangesTable.ToSignUpdate) <> 0
	|	OR SUM(ChangesTable.ToWriteOffUpdate) <> 0)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP RegisteredRecordsBalancesRetroCustomerBonusesBeforeWrite";
	
	Query = New Query(QueryText);
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.SetParameter("DataExchange", DataExchange.Load);
	Query.SetParameter(
		"CalculateChanges_",
		DocumentsPosting.CalculateChanges_(AdditionalProperties));
	Query.SetParameter(
		"PostWithoutRebatesBalanceCheck",
		SessionParameters.PostWithoutRebateBalanceCheck);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	
	Result = Query.ExecuteBatch();
	Selection = Result[0].Select();
	HasChanges = (Selection.Next() And Selection.Count > 0);
	DocumentsPosting.RegisterControlTable(
		AdditionalProperties,
		"RetroCustomerBonusesAreRegisteredRecordedUpdate",
		HasChanges);
	
EndProcedure
	
#EndRegion

#EndIf	