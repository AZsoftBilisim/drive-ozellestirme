#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	// Verification of fraud.Loading is not required, because this object in the RIB must create tasks when writing.
	
	DataSynchronizationViaAUniversalFormatDeletingRegisteredRecords = 
		AdditionalProperties.Property("DataSynchronizationViaAUniversalFormatDeletingRegisteredRecords")
		And AdditionalProperties.DataSynchronizationViaAUniversalFormatDeletingRegisteredRecords;
	
	If DataSynchronizationViaAUniversalFormatDeletingRegisteredRecords Then
		DocumentProperties = New Structure();
		DocumentProperties.Insert("IsNew", False);
		DocumentProperties.Insert("WriteMode", DocumentWriteMode.UndoPosting);
		
		RecorderDate = Common.ObjectAttributeValue(Filter.Recorder.Value, "Date");
		
		AdditionalProperties.Insert("DocumentProperties",       DocumentProperties);
		AdditionalProperties.Insert("RecorderDate",        RecorderDate);
		AdditionalProperties.Insert("CalculateChanges_",   True);
		AdditionalProperties.Insert("TempTablesManager", New TempTablesManager);
		AdditionalProperties.Insert("ControlTables",         New Structure);
	EndIf;
	
	If Not DocumentsPosting.MonitorChanges(AdditionalProperties)
		And Not DataSynchronizationViaAUniversalFormatDeletingRegisteredRecords Then
		Return;
	EndIf;
	
	LockForUpdate = True;
	
	// The current state of the set is placed in a temporary table
	// in order to get a change in the new set relative to the current one when writing.
	#Region QueryText
	QueryText = "
	|SELECT
	|	Table.Recorder                  AS Recorder,
	|	Table.ARAPObject               AS ARAPObject,
	|	Table.Currency                       AS Currency,
	|	CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Expense) THEN
	|			CASE WHEN Table.Sum < 0 THEN
	|					0
	|				ELSE -Table.Sum
	|			END
	|		ELSE Table.Sum
	|	END                                AS SumBeforeWrite
	|
	|INTO VendorsARAPAccountingBeforeWrite
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting AS Table
	|WHERE
	|	Table.Recorder = &Recorder
	|	AND NOT &IsNew
	|	AND Table.ARAPObject.Object <> UNDEFINED
	|	AND NOT &DataExchange
	|;
	|/////////////////////////////////////////////////
	|SELECT
	|	Calculations.Period                         AS Period,
	|	Calculations.Recorder                    AS Recorder,
	|	Calculations.RecordType                    AS RecordType,
	|	Calculations.AccountingDimensionByPartners      AS AccountingDimensionByPartners,
	|	Calculations.ARAPObject                 AS ARAPObject,
	|	Calculations.Currency                         AS Currency,
	|	Calculations.BusinessOperation          AS BusinessOperation,
	|	Calculations.Sum                          AS Sum,
	|	Calculations.BeingPaid                   AS BeingPaid,
	|	Calculations.SumCompl                      AS SumCompl,
	|	Calculations.SumMan                       AS SumMan,
	|	Calculations.AmountDue                        AS AmountDue,
	|	Calculations.ToReceive                   AS ToReceive,
	|	Calculations.CashFlowItem  AS CashFlowItem,
	|	Calculations.OperationProcedure                AS OperationProcedure,
	|	Calculations.SettlementProcedureByPaymentDate     AS SettlementProcedureByPaymentDate,
	|	Calculations.ARAPDocument              AS ARAPDocument,
	|	Calculations.DestinationAccountingDimensionByPartners AS DestinationAccountingDimensionByPartners,
	|	Calculations.CalculationObjectReceiver AS CalculationObjectReceiver,
	|	Calculations.CurrencyReceiver AS CurrencyReceiver,
	|	Calculations.ByDataOfSourceARAPObject AS ByDataOfSourceARAPObject,
	|	Calculations.DocumentCurrency                AS DocumentCurrency,
	|	Calculations.PaymentOption                  AS PaymentOption,
	|	Calculations.PaymentDate                    AS PaymentDate,
	|	Calculations.RecorderDate               AS RecorderDate,
	|	Calculations.PurchaseByOrder                AS PurchaseByOrder,
	|	Calculations.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	Calculations.PaymentRequest AS PaymentRequest,
	|	Calculations.FinRecordID         AS FinRecordID,
	|	Calculations.LinkedDocument              AS LinkedDocument,
	|	Calculations.ReversingEntry                         AS ReversingEntry
	|INTO SettlementsWithSuppliersInitialRegisteredRecords
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting AS Calculations
	|WHERE
	|	Calculations.Recorder = &Recorder
	|";
	#EndRegion
	
	Query = New Query(QueryText);
	Query.SetParameter("Recorder",  Filter.Recorder.Value);
	Query.SetParameter("IsNew",     AdditionalProperties.DocumentProperties.IsNew);
	Query.SetParameter("DataExchange", DataExchange.Load);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.Execute();
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	TableOfPaymentObjects = CreateTableOfPaymentObjects();
	InformationRegisters.ScheduleOfPayments.SetDataLocksForGraphCalculation(
		TableOfPaymentObjects, "AccumulationRegister.VendorsARAPAccounting", "ARAPObject", "ARAPObject");
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	// Verification of fraud.Loading is not required, because this object in the RIB must create tasks when writing.
	
	DataSynchronizationViaAUniversalFormatDeletingRegisteredRecords = 
		AdditionalProperties.Property("DataSynchronizationViaAUniversalFormatDeletingRegisteredRecords")
		And AdditionalProperties.DataSynchronizationViaAUniversalFormatDeletingRegisteredRecords;
	
	If Not DocumentsPosting.MonitorChanges(AdditionalProperties)
		And Not DataSynchronizationViaAUniversalFormatDeletingRegisteredRecords Then
		Return;
	EndIf;
	
	NewOnlineARAPAccounting = GetFunctionalOption("NewOnlineARAPAccounting");
	
	#Region OperationalConductOfMutualSettlements
	
	PerformDistributionOfMutualSettlementsInTransaction = Undefined;
	
	// Let's check that the data record is called from the document holding mechanism.
	If AdditionalProperties.Property("PropertiesOfRegisteredRecordsOfMechanisms")
		And AdditionalProperties.PropertiesOfRegisteredRecordsOfMechanisms.Property("ARAPAccounting") Then
		
		If AdditionalProperties.PropertiesOfRegisteredRecordsOfMechanisms.ARAPAccounting.Property("PerformDistributionOfMutualSettlementsInTransaction") Then
			PerformDistributionOfMutualSettlementsInTransaction = AdditionalProperties.PropertiesOfRegisteredRecordsOfMechanisms.ARAPAccounting.PerformDistributionOfMutualSettlementsInTransaction;
		EndIf;
		
	Else
		// Data loading or recording of Registered Records is not called from the document holding mechanism.
		PerformDistributionOfMutualSettlementsInTransaction = False;
	EndIf;
	
	If PerformDistributionOfMutualSettlementsInTransaction = Undefined Then
		
		If (Not NewOnlineARAPAccounting Or Common.FileInfobase()
			Or Common.DebugMode()) Then

			PerformDistributionOfMutualSettlementsInTransaction = True;

		Else
			
			SettingOfBackgroundDistributionOfMutualSettlementsIsEnabled = Constants.AllocateARAPInBackgroundJob.Get();
			
			If SettingOfBackgroundDistributionOfMutualSettlementsIsEnabled Then
				PerformDistributionOfMutualSettlementsInTransaction = False;
			Else
				If AdditionalProperties.DocumentProperties.Property("Date") Then
					DocumentDate = AdditionalProperties.DocumentProperties.Date;
				ElsIf AdditionalProperties.Property("RecorderDate") Then
					DocumentDate = AdditionalProperties.RecorderDate;
				Else
					DocumentDate = Common.ObjectAttributeValue(Filter.Recorder.Value, "Date");
				EndIf;
			EndIf;

		EndIf;
	
	EndIf;
	
	#EndRegion
	
	Query = New Query;
	#Region QueryText
	ArrayOfRequestTexts = New Array;
	TemporaryTablesToBeDestroyed = New Array;
	
	QueryText =
	"SELECT DISTINCT
	|	BEGINOFPERIOD(Table.Period, MONTH)   AS Month,
	|	Table.Period                         AS Period,
	|	Table.OperationProcedure                AS OperationProcedure,
	|	Table.SettlementProcedureByPaymentDate     AS SettlementProcedureByPaymentDate,
	|	Table.AccountingDimensionByPartners      AS AccountingDimensionByPartners,
	|	Table.ARAPObject                 AS ARAPObject,
	|	Table.Currency                         AS Currency,
	|	&Recorder                           AS Document,
	|	SUM(Table.Sum)                   AS Sum,
	|	SUM(Table.AmountDue)                 AS AmountDue,
	|	SUM(Table.ToReceive)            AS ToReceive,
	|	SUM(Table.SumCompl)               AS SumCompl,
	|	SUM(Table.SumMan)                AS SumMan,
	|	SUM(Table.BeingPaid)            AS BeingPaid,
	|	Keys.Organization                      AS Organization,
	|	Table.DestinationAccountingDimensionByPartners AS DestinationAccountingDimensionByPartners,
	|	Table.CalculationObjectReceiver         AS CalculationObjectReceiver,
	|	Table.CurrencyReceiver                 AS CurrencyReceiver,
	|	Table.ByDataOfSourceARAPObject AS ByDataOfSourceARAPObject,
	|	CASE WHEN Table.ReversingEntry
	|			THEN Table.LinkedDocument
	|		ELSE Table.OrderDocument
	|	END                                  AS OrderDocument,
	|	Table.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	Table.PaymentRequest AS PaymentRequest,
	|	Table.ARAPDocument              AS ARAPDocument,
	|	Table.PaymentDate                    AS PaymentDate,
	|	Table.RecorderDate               AS RecorderDate,
	|	Table.FinRecordID         AS FinRecordID,
	|	Table.ReversingEntry                         AS ReversingEntry,
	|	&CreateTasksByEndOfNextMonth  AS CreateTasksByEndOfNextMonth,
	|	&CalculateChanges_                      AS RaiseException1
	|INTO VendorsARAPAccountingChanges
	|FROM
	|	(SELECT
	|		Calculations.Period                         AS Period,
	|		Calculations.AccountingDimensionByPartners      AS AccountingDimensionByPartners,
	|		Calculations.ARAPObject                 AS ARAPObject,
	|		Calculations.Currency                         AS Currency,
	|		Calculations.Sum                          AS Sum,
	|		Calculations.BeingPaid                   AS BeingPaid,
	|		Calculations.BusinessOperation          AS BusinessOperation,
	|		Calculations.SumCompl                      AS SumCompl,
	|		Calculations.SumMan                       AS SumMan,
	|		Calculations.AmountDue                        AS AmountDue,
	|		Calculations.ToReceive                   AS ToReceive,
	|		Calculations.CashFlowItem  AS CashFlowItem,
	|		Calculations.OperationProcedure                AS OperationProcedure,
	|		Calculations.SettlementProcedureByPaymentDate     AS SettlementProcedureByPaymentDate,
	|		Calculations.ARAPDocument              AS ARAPDocument,
	|		Calculations.DestinationAccountingDimensionByPartners AS DestinationAccountingDimensionByPartners,
	|		Calculations.CalculationObjectReceiver         AS CalculationObjectReceiver,
	|		Calculations.CurrencyReceiver         AS CurrencyReceiver,
	|		Calculations.ByDataOfSourceARAPObject AS ByDataOfSourceARAPObject,
	|		Calculations.DocumentCurrency                AS DocumentCurrency,
	|		Calculations.PaymentOption                  AS PaymentOption,
	|		Calculations.PaymentDate                    AS PaymentDate,
	|		Calculations.RecorderDate               AS RecorderDate,
	|		Calculations.PurchaseByOrder                AS OrderDocument,
	|		Calculations.BusinessTransactionSetting AS BusinessTransactionSetting,
	|		Calculations.PaymentRequest AS PaymentRequest,
	|		Calculations.FinRecordID         AS FinRecordID,
	|		Calculations.LinkedDocument              AS LinkedDocument,
	|		Calculations.ReversingEntry                         AS ReversingEntry,
	|		CASE WHEN VALUETYPE(Calculations.Recorder) = TYPE(Document.ARAPSettlement)
	|				AND Calculations.RecordType = VALUE(AccumulationRecordType.Receipt) AND Calculations.Sum > 0
	|			THEN 0
	|			WHEN VALUETYPE(Calculations.Recorder) = TYPE(Document.ARAPSettlement)
	|				AND Calculations.RecordType = VALUE(AccumulationRecordType.Receipt) AND Calculations.Sum < 0
	|			THEN -1
	|			ELSE 1
	|		END AS NettingMovementIndex
	|	FROM
	|		SettlementsWithSuppliersInitialRegisteredRecords AS Calculations
	|		
	|	UNION ALL
	|		
	|	SELECT
	|		Calculations.Period                         AS Period,
	|		Calculations.AccountingDimensionByPartners      AS AccountingDimensionByPartners,
	|		Calculations.ARAPObject                 AS ARAPObject,
	|		Calculations.Currency                         AS Currency,
	|		-Calculations.Sum                         AS Sum,
	|		-Calculations.BeingPaid                  AS BeingPaid,
	|		Calculations.BusinessOperation          AS BusinessOperation,
	|		-Calculations.SumCompl                     AS SumCompl,
	|		-Calculations.SumMan                      AS SumMan,
	|		-Calculations.AmountDue                       AS AmountDue,
	|		-Calculations.ToReceive                  AS ToReceive,
	|		Calculations.CashFlowItem  AS CashFlowItem,
	|		Calculations.OperationProcedure                AS OperationProcedure,
	|		Calculations.SettlementProcedureByPaymentDate     AS SettlementProcedureByPaymentDate,
	|		Calculations.ARAPDocument              AS ARAPDocument,
	|		Calculations.DestinationAccountingDimensionByPartners AS DestinationAccountingDimensionByPartners,
	|		Calculations.CalculationObjectReceiver         AS CalculationObjectReceiver,
	|		Calculations.CurrencyReceiver         AS CurrencyReceiver,
	|		Calculations.ByDataOfSourceARAPObject AS ByDataOfSourceARAPObject,
	|		Calculations.DocumentCurrency                AS DocumentCurrency,
	|		Calculations.PaymentOption                  AS PaymentOption,
	|		Calculations.PaymentDate                    AS PaymentDate,
	|		Calculations.RecorderDate               AS RecorderDate,
	|		Calculations.PurchaseByOrder                AS OrderDocument,
	|		Calculations.BusinessTransactionSetting AS BusinessTransactionSetting,
	|		Calculations.PaymentRequest AS PaymentRequest,
	|		Calculations.FinRecordID         AS FinRecordID,
	|		Calculations.LinkedDocument              AS LinkedDocument,
	|		Calculations.ReversingEntry                         AS ReversingEntry,
	|		CASE WHEN VALUETYPE(Calculations.Recorder) = TYPE(Document.ARAPSettlement)
	|				AND Calculations.RecordType = VALUE(AccumulationRecordType.Receipt) AND Calculations.Sum > 0
	|			THEN 0
	|			WHEN VALUETYPE(Calculations.Recorder) = TYPE(Document.ARAPSettlement)
	|				AND Calculations.RecordType = VALUE(AccumulationRecordType.Receipt) AND Calculations.Sum < 0
	|			THEN -1
	|			ELSE 1
	|		END AS NettingMovementIndex
	|	FROM AccumulationRegister.VendorsARAPAccounting AS Calculations
	|	WHERE Calculations.Recorder = &Recorder
	|) AS Table
	|
	|	LEFT JOIN Catalog.DimensionKeysOfAccountingByPartners AS Keys
	|	ON Keys.Ref = Table.AccountingDimensionByPartners
	|GROUP BY
	|	Table.Period,
	|	Table.AccountingDimensionByPartners,
	|	Table.ARAPObject,
	|	Table.Currency,
	|	Table.BusinessOperation,
	|	Table.CashFlowItem,
	|	Table.ARAPDocument,
	|	Table.DestinationAccountingDimensionByPartners,
	|	Table.CalculationObjectReceiver,
	|	Table.CurrencyReceiver,
	|	Table.ByDataOfSourceARAPObject,
	|	Table.DocumentCurrency,
	|	Table.PaymentOption,
	|	Table.PaymentDate,
	|	Table.RecorderDate,
	|	Table.NettingMovementIndex,
	|	Keys.Organization,
	|	Table.OperationProcedure,
	|	Table.SettlementProcedureByPaymentDate,
	|	CASE WHEN Table.ReversingEntry
	|			THEN Table.LinkedDocument
	|		ELSE Table.OrderDocument
	|	END,
	|	Table.BusinessTransactionSetting,
	|	Table.PaymentRequest,
	|	Table.FinRecordID,
	|	Table.ReversingEntry
	|HAVING
	|	SUM(Table.Sum) <> 0
	|	OR SUM(Table.SumCompl) <> 0
	|	OR SUM(Table.SumMan) <> 0
	|	OR SUM(Table.AmountDue) <> 0
	|	OR SUM(Table.BeingPaid) <> 0
	|	OR SUM(Table.ToReceive) <> 0";
	ArrayOfRequestTexts.Add(QueryText);
	
	QueryText ="
	|SELECT DISTINCT
	|	ChangesTable.Document                  AS Recorder,
	|	ChangesTable.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	ChangesTable.ARAPObject            AS ARAPObject,
	|	ChangesTable.Period                    AS Period,
	|	ChangesTable.Sum                     AS Sum
	|	
	|INTO VendorsARAPAccountingChangesEnteringBalances
	|FROM
	|	VendorsARAPAccountingChanges AS ChangesTable
	|WHERE
	|	ChangesTable.Sum < 0
	|";
	ArrayOfRequestTexts.Add(QueryText);
	
	QueryText = "
	|SELECT DISTINCT
	|	Table.AccountingDimensionByPartners,
	|	Table.ARAPObject,
	|	Table.Currency AS Currency,
	|	Table.PaymentRequest
	|INTO MovementSettlementsWithSuppliersChangePaid
	|FROM
	|	VendorsARAPAccountingChanges AS Table
	|WHERE
	|	Table.BeingPaid <> 0
	|";
	ArrayOfRequestTexts.Add(QueryText);
	
	QueryText = "
	|SELECT
	|	ChangesTable.Month AS Month,
	|	ChangesTable.Period AS Period,
	|	ChangesTable.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	ChangesTable.ARAPObject AS ARAPObject,
	|	ChangesTable.Currency AS Currency,
	|	ChangesTable.Document AS Document,
	|	ChangesTable.Organization AS Organization,
	|	ChangesTable.OrderDocument AS OrderDocument,
	|	ChangesTable.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	ChangesTable.ARAPDocument AS ARAPDocument,
	|	ChangesTable.PaymentDate AS PaymentDate,
	|	ChangesTable.RecorderDate AS RecorderDate,
	|	ChangesTable.FinRecordID AS FinRecordID,
	|	ChangesTable.ReversingEntry AS ReversingEntry,
	|	ChangesTable.CreateTasksByEndOfNextMonth AS CreateTasksByEndOfNextMonth,
	|	SUM(ChangesTable.Sum) AS Sum,
	|	SUM(ChangesTable.SumCompl) AS SumCompl,
	|	SUM(ChangesTable.SumMan) AS SumMan
	|INTO ChangesTableVendorsARAPAccounting
	|FROM
	|	VendorsARAPAccountingChanges AS ChangesTable
	|GROUP BY
	|	ChangesTable.Month,
	|	ChangesTable.Period,
	|	ChangesTable.AccountingDimensionByPartners,
	|	ChangesTable.ARAPObject,
	|	ChangesTable.Currency,
	|	ChangesTable.Document,
	|	ChangesTable.Organization,
	|	ChangesTable.OrderDocument,
	|	ChangesTable.BusinessTransactionSetting,
	|	ChangesTable.ARAPDocument,
	|	ChangesTable.PaymentDate,
	|	ChangesTable.RecorderDate,
	|	ChangesTable.FinRecordID,
	|	ChangesTable.ReversingEntry,
	|	ChangesTable.CreateTasksByEndOfNextMonth
	|HAVING
	|	SUM(ChangesTable.Sum) <> 0
	|	OR SUM(ChangesTable.SumCompl) <> 0
	|	OR SUM(ChangesTable.SumMan) <> 0";
	ArrayOfRequestTexts.Add(QueryText);
	
	QueryText = "
	|SELECT DISTINCT
	|	VendorsARAPAccountingChanges.Period AS TaskPeriod,
	|	CatalogAccountingDimensionByPartners.Organization AS Organization,
	|	VendorsARAPAccountingChanges.Document AS Document,
	|	VALUE(Catalog.BackdateJobKinds.RecordBalanceSheetStatementRegisterRecords) AS JobKind
	|INTO QueueDataForAdditionalDocumentsManBalance
	|FROM
	|VendorsARAPAccountingChanges AS VendorsARAPAccountingChanges
	|		INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS CatalogAccountingDimensionByPartners
	|			ON VendorsARAPAccountingChanges.AccountingDimensionByPartners = CatalogAccountingDimensionByPartners.Ref
	|WHERE 
	|	VendorsARAPAccountingChanges.SumMan <> 0
	|		AND &UseBalanceSheetStatement
	|		AND &IsMasterNode1
	|		AND &NewCalculations
	|";
	
	ArrayOfRequestTexts.Add(QueryText);
	TemporaryTablesToBeDestroyed.Add("QueueDataForAdditionalDocumentsManBalance");
	
	#Region QueryTextOperationalDistributionOfSettlements
	
	If PerformDistributionOfMutualSettlementsInTransaction = Undefined 
		And Not SettingOfBackgroundDistributionOfMutualSettlementsIsEnabled Then
		
		QueryText = "
		|SELECT
		|	MIN(DocumentRegisterRecords.ThisIsOrder)
		|	OR MAX(DocumentRegisterRecords.ThisIsIncreaseInDebt) AS ItIsNecessaryToLookAtDebts,
		|	MIN(DocumentRegisterRecords.ThisIsOrder)
		|	OR MAX(DocumentRegisterRecords.ThisIsReductionInDebt) AS NeedToWatchPayments
		|INTO TermsOfInspections
		|FROM
		|	(SELECT
		|		Calculations.Sum = 0 AS ThisIsOrder,
		|
		|		(Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
		|			AND Calculations.Sum > 0)
		|		OR 
		|		(Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			AND Calculations.Sum < 0) AS ThisIsIncreaseInDebt,
		|
		|		(Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			AND Calculations.Sum > 0)
		|		OR 
		|		(Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
		|			AND Calculations.Sum < 0) AS ThisIsReductionInDebt
		|	FROM
		|		AccumulationRegister.VendorsARAPAccounting AS Calculations
		|	WHERE
		|		Calculations.Recorder = &Recorder
		|
		|	UNION ALL
		|
		|	SELECT
		|		TRUE AS ThisIsOrder,
		|		FALSE AS ThisIsIncreaseInDebt,
		|		FALSE AS ThisIsReductionInDebt) AS DocumentRegisterRecords";
		
		ArrayOfRequestTexts.Add(QueryText);
		
		QueryText = "
		|SELECT
		|	SUM(TableBalance.NumberOfPrepayments) >= &NumberOfBalanceEntries AS LotOfPrepayments,
		|	SUM(TableBalance.NumberOfDebts) >= &NumberOfBalanceEntries AS LotOfDebt
		|INTO NumberOfRecordsBalances
		|FROM
		|	(SELECT
		|		CalculationsByTermsBalance.ARAPDocument AS ARAPDocument,
		|		CalculationsByTermsBalance.PlannedRepaymentDate AS PlannedRepaymentDate,
		|		CalculationsByTermsBalance.OccurrenceDate AS OccurrenceDate,
		|		CASE
		|			WHEN CalculationsByTermsBalance.PrepaymentBalance <> 0
		|				THEN 1
		|			ELSE 0
		|		END AS NumberOfPrepayments,
		|		CASE
		|			WHEN CalculationsByTermsBalance.DebtBalance <> 0
		|				THEN 1
		|			ELSE 0
		|		END AS NumberOfDebts
		|	FROM
		|		AccumulationRegister.VendorsARAPAccountingByDueDates.Balance(&RemainderPeriod_, (AccountingDimensionByPartners, ARAPObject, Currency) IN
		|			(SELECT
		|				Calculations.AccountingDimensionByPartners,
		|				Calculations.ARAPObject,
		|				Calculations.Currency
		|			FROM
		|				VendorsARAPAccountingChanges AS Calculations)
		|		AND TRUE IN
		|			(SELECT
		|				TermsOfInspections.NeedToWatchPayments
		|			FROM
		|				TermsOfInspections AS TermsOfInspections)) AS CalculationsByTermsBalance) AS TableBalance";
		
		ArrayOfRequestTexts.Add(QueryText);
		
		QueryText = "
		|SELECT
		|	COUNT(DISTINCT CASE
		|		WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
		|		AND Calculations.Sum > 0
		|		OR Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
		|		AND Calculations.Sum < 0
		|			THEN Calculations.Recorder
		|		ELSE UNDEFINED
		|	END) >= &NumberOfDocumentsAhead AS LotOfDebt,
		|
		|	COUNT(DISTINCT CASE
		|		WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
		|		AND Calculations.Sum > 0
		|		OR Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
		|		AND Calculations.Sum < 0
		|			THEN Calculations.Recorder
		|		ELSE UNDEFINED
		|	END) >= &NumberOfDocumentsAhead AS LotsOfPayments
		|
		|INTO DocumentsAhead
		|FROM
		|	VendorsARAPAccountingChanges AS ChangesTable
		|		INNER JOIN AccumulationRegister.VendorsARAPAccounting AS Calculations
		|		ON ChangesTable.AccountingDimensionByPartners = Calculations.AccountingDimensionByPartners
		|		AND ChangesTable.ARAPObject = Calculations.ARAPObject
		|		AND ChangesTable.Currency = Calculations.Currency
		|		AND (Calculations.Period >= BEGINOFPERIOD(ChangesTable.Period, DAY))
		|		AND (Calculations.Active)
		|WHERE
		|	NOT Calculations.Sum = 0";
		
		ArrayOfRequestTexts.Add(QueryText);
		
		QueryText = "
		|SELECT
		|	MAX(DistributionConditions.BackgroundDistributionOfSettlements) AS BackgroundDistributionOfSettlements
		|INTO MutualSettlementAllocationMode
		|FROM
		|	(SELECT
		|		CASE
		|			WHEN TermsOfInspections.NeedToWatchPayments
		|			AND (ISNULL(DocumentsAhead.LotOfDebt, FALSE)
		|			OR ISNULL(NumberOfRecordsBalances.LotOfDebt, FALSE)
		|			OR ISNULL(DocumentsAhead.LotsOfPayments, FALSE)
		|			AND NOT ISNULL(NumberOfRecordsBalances.LotOfDebt, FALSE))
		|				THEN TRUE
		|			WHEN TermsOfInspections.ItIsNecessaryToLookAtDebts
		|			AND ISNULL(DocumentsAhead.LotOfDebt, FALSE)
		|				THEN TRUE
		|			ELSE FALSE
		|		END AS BackgroundDistributionOfSettlements
		|	FROM
		|		TermsOfInspections AS TermsOfInspections
		|			LEFT JOIN NumberOfRecordsBalances AS NumberOfRecordsBalances
		|			ON TRUE
		|			LEFT JOIN DocumentsAhead AS DocumentsAhead
		|			ON TRUE
		|
		|	UNION ALL
		|
		|	SELECT TOP 1
		|		TRUE
		|	FROM
		|		VendorsARAPAccountingChanges AS ChangesTable
		|			INNER JOIN InformationRegister.JobsForARAPAllocating AS Jobs
		|			ON ChangesTable.AccountingDimensionByPartners = Jobs.AccountingDimensionByPartners
		|			AND ChangesTable.ARAPObject = Jobs.ARAPObject
		|			AND ChangesTable.Currency = Jobs.Currency) AS DistributionConditions";
		
		ArrayOfRequestTexts.Add(QueryText);
		
		ArrayOfRequestTexts.Add("DROP TermsOfInspections");
		ArrayOfRequestTexts.Add("DROP NumberOfRecordsBalances");
		ArrayOfRequestTexts.Add("DROP DocumentsAhead");
		
		TemporaryTablesToBeDestroyed.Add("MutualSettlementAllocationMode");
		
	EndIf;
	
	#EndRegion
	
	#Region QueryTextOfTaskDistributionOfSettlements
	
	If PerformDistributionOfMutualSettlementsInTransaction = Undefined
		Or Not PerformDistributionOfMutualSettlementsInTransaction Then
		
		QueryText = AccumulationRegisters.VendorsARAPAccounting.QueryTextDataForRegistrationOfTasksForDistributionOfSettlements();
		ArrayOfRequestTexts.Add(QueryText);
		
		ArrayOfRequestTexts.Add("DROP MinimumChangePeriodsSuppliers");
		
		TemporaryTablesToBeDestroyed.Add("TasksForDistributionOfMutualSettlementsSuppliers");
		
	EndIf;
	
	#EndRegion
	
	#EndRegion
	
	ArrayOfRequestTexts.Add("DROP VendorsARAPAccountingBeforeWrite");
	ArrayOfRequestTexts.Add("DROP SettlementsWithSuppliersInitialRegisteredRecords");
	
	Query.Text = StrConcat(ArrayOfRequestTexts, Common.QueryBatchSeparator());
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.SetParameter("NewCalculations", NewOnlineARAPAccounting);
	Query.SetParameter("CalculateChanges_",    DocumentsPosting.CalculateChanges_(AdditionalProperties)
		And TypeOf(Filter.Recorder.Value) <> Type("DocumentRef.OBEntry")
		And TypeOf(Filter.Recorder.Value) <> Type("DocumentRef.OBEntryARAP"));
	Query.SetParameter("CreateTasksByEndOfNextMonth", TypeOf(Filter.Recorder.Value) = Type("DocumentRef.OBEntryARAP"));
	ThisIsPlanDocument = OnlineARAPAccountingServer.ListOfPlanRegistrarTypes().FindByValue(TypeOf(Filter.Recorder.Value)) <> Undefined;
	Query.SetParameter("DoNotCheckBanDateAndDoNotCreateChildTasks", ThisIsPlanDocument);
	Query.SetParameter("UseBalanceSheetStatement", GetFunctionalOption("UseBalanceSheetStatement"));
	Query.SetParameter("IsMasterNode1", ExchangePlans.MasterNode() = Undefined);
	
	If PerformDistributionOfMutualSettlementsInTransaction = Undefined
		And Not SettingOfBackgroundDistributionOfMutualSettlementsIsEnabled Then
		
		ReplacementText = "
		|TRUE IN
		|		(SELECT TOP 1
		|			DistributionMode.BackgroundDistributionOfSettlements
		|		FROM
		|			MutualSettlementAllocationMode AS DistributionMode)";
		Query.Text = StrReplace(Query.Text, "&CreateTasksForDistributionOfMutualSettlements", ReplacementText);
		Query.SetParameter("RemainderPeriod_", DocumentDate);
		
		ConditionsForDistributionOfSettlementsInTransaction = OnlineARAPAccountingServer.ConditionsForDistributionOfSettlementsInDocumentTransaction();
		Query.SetParameter("NumberOfBalanceEntries",
			ConditionsForDistributionOfSettlementsInTransaction.NumberOfBalanceEntries);
		Query.SetParameter("NumberOfDocumentsAhead",
			ConditionsForDistributionOfSettlementsInTransaction.NumberOfDocumentsAhead);
		
	Else
		Query.SetParameter("CreateTasksForDistributionOfMutualSettlements", Not PerformDistributionOfMutualSettlementsInTransaction);
	EndIf;
	
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	
	Result = Query.ExecuteBatch();
	
	Selection = Result[0].Select();
	DocumentsPosting.RegisterControlTable(AdditionalProperties,
		"VendorsARAPAccountingChanges", Selection.Next() And Selection.Count > 0);
	Selection = Result[1].Select();
	DocumentsPosting.RegisterControlTable(AdditionalProperties,
		"VendorsARAPAccountingChangesEnteringBalances", Selection.Next() And Selection.Count > 0);
	Selection = Result[2].Select();
	DocumentsPosting.RegisterControlTable(AdditionalProperties,
		"MovementSettlementsWithSuppliersChangePaid", Selection.Next() And Selection.Count > 0);
	
	// Control table for generating tasks by the end of the month
	Selection = Result[3].Select();
	DocumentsPosting.RegisterControlTable(AdditionalProperties,
		"ChangesTableVendorsARAPAccounting", Selection.Next() And Selection.Count > 0);
	
	If PerformDistributionOfMutualSettlementsInTransaction = Undefined Then

		TableOfConditions = Query.TempTablesManager.Tables["MutualSettlementAllocationMode"].GetData().Unload();
		
		PerformDistributionOfMutualSettlementsInTransaction = Not TableOfConditions[0].BackgroundDistributionOfSettlements;
		
	EndIf;
	
	If AdditionalProperties.Property("PropertiesOfRegisteredRecordsOfMechanisms")
		And AdditionalProperties.PropertiesOfRegisteredRecordsOfMechanisms.Property("ARAPAccounting") Then
		
		AdditionalProperties.PropertiesOfRegisteredRecordsOfMechanisms.ARAPAccounting.Insert(
			"PerformDistributionOfMutualSettlementsInTransaction", PerformDistributionOfMutualSettlementsInTransaction);
			
	EndIf;
	
	AdditionalProperties.Insert("NotCreateTasksForDistributionOfMutualSettlements",
		PerformDistributionOfMutualSettlementsInTransaction);
	
	If DataExchange.Load Then
		
		If NewOnlineARAPAccounting Then
			
			InformationRegisters.JobsForARAPAllocating.CreateTasksWhenExchangingData(ThisObject,
				Query.TempTablesManager);
			
			If ExchangePlans.MasterNode() = Undefined 
				And AdditionalProperties.Property("RIBExchangeCreateNonOperationalQueueJobs") Then
				
				KindsOfTasks = New Array;
				KindsOfTasks.Add(Catalogs.BackdateJobKinds.RecordBalanceSheetStatementRegisterRecords);
				InformationRegisters.JobsOfBackdateAdditionalDocumentPosting.CreateTasksWhenExchangingData(ThisObject,
					KindsOfTasks, Query.TempTablesManager);
					
			EndIf;
			
		ElsIf Constants.MigrationToOnlineARAPAccountingHasStarted.Get() Then
			
			// Tasks for the distribution of calculations are generated here for the distribution of calculations when uploading data to the RIB
			ChangesTable = OnlineARAPAccountingServer.TableOfChangesForRecalculation(
				Query.TempTablesManager);
			OnlineARAPAccountingServer.RegisterChangesToDeferredAllocation(Filter.Recorder.Value, ChangesTable);
			
		EndIf;
		
	Else
		
		If NewOnlineARAPAccounting Then

			BackdateJobQueue.CreateNonOperationalQueueJobsWhenRecordingRecordset(ThisObject,
				Query.TempTablesManager);

		EndIf;
		
	EndIf;
	
	TMCommonUse.DestroyTemporaryTables(Query.TempTablesManager, TemporaryTablesToBeDestroyed);
	
EndProcedure

#EndRegion

#Region Private

// Generates a table of orders that were previously in the movements and that will now be recorded.
//
Function CreateTableOfPaymentObjects()

	Query = New Query;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.SetParameter("TableOfNewCalculationObjects", Unload(, "ARAPObject"));
	
	Query.Text = "
	|SELECT DISTINCT
	|	CAST(Table.ARAPObject AS Catalog.ARAPObjects) AS ARAPObject
	|INTO ARAPObjects
	|FROM &TableOfNewCalculationObjects AS Table
	|;
	|SELECT
	|	ISNULL(Table.ARAPObject.Object, &Recorder) AS PaymentObject,
	|	Table.ARAPObject AS ARAPObject
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting AS Table
	|WHERE
	|	Table.Recorder = &Recorder
	|	AND Table.ARAPObject <> VALUE(Catalog.ARAPObjects.EmptyRef)
	|
	|UNION
	|
	|SELECT
	|	ARAPObjects.ARAPObject.Object AS PaymentObject,
	|	ARAPObjects.ARAPObject AS ARAPObject
	|FROM ARAPObjects
	|WHERE 
	|	ARAPObjects.ARAPObject.Object <> UNDEFINED
	|";
	
	Return Query.Execute().Unload();
	
EndFunction

Procedure UploadWithProcessing(CalculationTable) Export
	
	ARAPAccountingPosting.AddFillInOrderOfOperation(CalculationTable, TypeOf(Filter.Recorder.Value));
	Load(CalculationTable);
	
EndProcedure

#EndRegion

#EndIf
