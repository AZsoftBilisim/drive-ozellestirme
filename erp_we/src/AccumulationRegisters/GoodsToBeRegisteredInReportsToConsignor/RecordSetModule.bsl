#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		PrepareDataForRegisteringTasksInNonOperationalQueue();
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	PrepareDataForRegisteringTasksInNonOperationalQueue();
	
	If Not DocumentsPosting.MonitorChanges(AdditionalProperties)
		Or ExchangePlans.MasterNode() <> Undefined Then
		Return;
	EndIf;
	
	LockForUpdate = True;
	
	AdditionalProperties.Insert("BatchAccountingIsEnabled",
		CalculationOfCostCached.BatchAccountingIsEnabled(
			BegOfMonth(AdditionalProperties.RecorderDate)));
	
	Query = New Query("
	|SELECT
	|	Goods.Period                     AS Period,
	|	Goods.Recorder                AS Recorder,
	|	Goods.InventoryOwnerAttribute                 AS InventoryOwnerAttribute,
	|	Goods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Goods.Currency                     AS Currency,
	|	Goods.CCDNumber                   AS CCDNumber,
	|
	|	Goods.Count                 AS Count,
	|	Goods.RevenueAmount               AS RevenueAmount,
	|	Goods.QuantityConsumed          AS QuantityConsumed,
	|
	|	Goods.Count                 AS QuantityToRegister,
	|	Goods.RevenueAmount               AS RevenueAmountToRegister,
	|	Goods.QuantityConsumed          AS QuantityConsumedForIncoiceRegistration,
	|
	|	Goods.BusinessOperation      AS BusinessOperation,
	|	Goods.CommissionAmount        AS CommissionAmount,
	|	Goods.DocumentSalesOfGoodsAndServices         AS DocumentSalesOfGoodsAndServices,
	|	Goods.TaxInvoiceDate           AS TaxInvoiceDate,
	|	Goods.Customer                 AS Customer,
	|	Goods.CorInventoryOwnerAttribute              AS CorInventoryOwnerAttribute,
	|	Goods.Products               AS Products,
	|	Goods.Characteristic             AS Characteristic,
	|	Goods.TaxInvoiceNumber          AS TaxInvoiceNumber
	|INTO GoodsForRegistrationBeforeWrite
	|FROM
	|	AccumulationRegister.GoodsToBeRegisteredInReportsToConsignor AS Goods
	|WHERE
	|	Goods.Recorder = &Recorder
	|	AND &BatchAccountingIsEnabled
	|");
	
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.SetParameter("BatchAccountingIsEnabled", AdditionalProperties.BatchAccountingIsEnabled);
	
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.Execute();
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		CreateNonOperationalQueueJobsWhenWriting();
		Return;
	EndIf;
	
	CreateNonOperationalQueueJobsWhenWriting();
	
	If Not DocumentsPosting.MonitorChanges(AdditionalProperties)
		Or ExchangePlans.MasterNode() <> Undefined Then
		Return;
	EndIf;
	
	Query = New Query("SELECT
	|	Table.Period AS Period,
	|	Table.Recorder AS Recorder,
	|	Table.Organization AS Organization,
	|	Table.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	Table.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Table.Currency AS Currency,
	|	Table.CCDNumber AS CCDNumber,
	|	Table.BusinessOperation AS BusinessOperation,
	|	Table.CommissionAmount AS CommissionAmount,
	|	Table.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|	Table.TaxInvoiceDate AS TaxInvoiceDate,
	|	Table.Customer AS Customer,
	|	Table.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.TaxInvoiceNumber AS TaxInvoiceNumber,
	|	SUM(Table.Count) AS CountUpdate,
	|	SUM(Table.RevenueAmount) AS RevenueAmountUpdate,
	|	SUM(Table.QuantityConsumed) AS QuantityConsumedUpdate
	|INTO ChangesTableGoodsToBeRegisteredInReportsToConsignor
	|FROM
	|	(SELECT
	|		Goods.Period AS Period,
	|		Goods.Recorder AS Recorder,
	|		InventoryKinds.Organization AS Organization,
	|		Goods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|		Goods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		Goods.Currency AS Currency,
	|		Goods.CCDNumber AS CCDNumber,
	|		Goods.Count AS Count,
	|		Goods.RevenueAmount AS RevenueAmount,
	|		Goods.QuantityConsumed AS QuantityConsumed,
	|		Goods.BusinessOperation AS BusinessOperation,
	|		Goods.CommissionAmount AS CommissionAmount,
	|		Goods.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|		Goods.TaxInvoiceDate AS TaxInvoiceDate,
	|		Goods.Customer AS Customer,
	|		Goods.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|		Goods.Products AS Products,
	|		Goods.Characteristic AS Characteristic,
	|		Goods.TaxInvoiceNumber AS TaxInvoiceNumber
	|	FROM
	|		GoodsForRegistrationBeforeWrite AS Goods
	|			INNER JOIN Catalog.InventoryKinds AS InventoryKinds
	|			ON Goods.InventoryOwnerAttribute = InventoryKinds.Ref
	|	WHERE
	|		&BatchAccountingIsEnabled
	|
	|	UNION ALL
	|
	|	SELECT
	|		Goods.Period AS Period,
	|		Goods.Recorder AS Recorder,
	|		InventoryKinds.Organization AS Organization,
	|		Goods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|		Goods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		Goods.Currency AS Currency,
	|		Goods.CCDNumber AS CCDNumber,
	|		-Goods.Count AS Count,
	|		-Goods.RevenueAmount AS RevenueAmount,
	|		-Goods.QuantityConsumed AS QuantityConsumed,
	|		Goods.BusinessOperation AS BusinessOperation,
	|		Goods.CommissionAmount AS CommissionAmount,
	|		Goods.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|		Goods.TaxInvoiceDate AS TaxInvoiceDate,
	|		Goods.Customer AS Customer,
	|		Goods.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|		Goods.Products AS Products,
	|		Goods.Characteristic AS Characteristic,
	|		Goods.TaxInvoiceNumber AS TaxInvoiceNumber
	|	FROM
	|		AccumulationRegister.GoodsToBeRegisteredInReportsToConsignor AS Goods
	|			INNER JOIN Catalog.InventoryKinds AS InventoryKinds
	|			ON Goods.InventoryOwnerAttribute = InventoryKinds.Ref
	|	WHERE
	|		Goods.Recorder = &Recorder
	|		AND &BatchAccountingIsEnabled) AS Table
	|GROUP BY
	|	Table.Period,
	|	Table.Recorder,
	|	Table.Organization,
	|	Table.InventoryOwnerAttribute,
	|	Table.ItemsLocationAttributes,
	|	Table.Currency,
	|	Table.CCDNumber,
	|	Table.BusinessOperation,
	|	Table.CommissionAmount,
	|	Table.DocumentSalesOfGoodsAndServices,
	|	Table.TaxInvoiceDate,
	|	Table.Customer,
	|	Table.CorInventoryOwnerAttribute,
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.TaxInvoiceNumber
	|HAVING
	|	SUM(Table.Count) <> 0
	|	OR SUM(Table.RevenueAmount) <> 0
	|	OR SUM(Table.QuantityConsumed) <> 0
	|");
	
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.SetParameter("BatchAccountingIsEnabled", AdditionalProperties.BatchAccountingIsEnabled);
	
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	
	Query.Execute();
	
EndProcedure

#EndRegion

#Region Private

#Region BackdateJobQueue

Procedure PrepareDataForRegisteringTasksInNonOperationalQueue()
	
	If Not BackdateJobQueue.CreationOfNonOperationalQueueTasksIsAvailable(ThisObject) Then
		Return;
	EndIf;
	
	If GetFunctionalOption("NewOnlineARAPAccounting") 
		And GetFunctionalOption("UseBalanceSheetStatement") Then
		
		Query = New Query;
		Query.TempTablesManager = New TempTablesManager;
		Query.Text = "
		|SELECT
		|	InitialEntries.Recorder AS Recorder,
		|	InitialEntries.Period AS Period,
		|	InitialEntries.Active AS Active,
		|	InitialEntries.RecordType AS RecordType,
		|	InitialEntries.Organization AS Organization,
		|	InitialEntries.Currency AS Currency,
		|	InitialEntries.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	InitialEntries.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	InitialEntries.ReversingEntry AS ReversingEntry,
		|	InitialEntries.RevenueAmount AS RevenueAmount,
		|	InitialEntries.RevenueAmountMan AS RevenueAmountMan
		|INTO VT_TaskQueueInitialEntries
		|FROM
		|	AccumulationRegister.GoodsToBeRegisteredInReportsToConsignor AS InitialEntries
		|WHERE
		|	InitialEntries.Recorder = &Recorder";
		Query.SetParameter("Recorder", Filter.Recorder.Value);
		Query.Execute();
		
		AdditionalProperties.Insert("TemporaryTableManagerJobQueue", Query.TempTablesManager);
		
	EndIf;
	
EndProcedure

Procedure CreateNonOperationalQueueJobsWhenWriting()
	
	If Not BackdateJobQueue.CreationOfNonOperationalQueueTasksIsAvailable(ThisObject) Then
		Return;
	EndIf;
	
	If GetFunctionalOption("NewOnlineARAPAccounting") 
		And GetFunctionalOption("UseBalanceSheetStatement") Then
		
		Query = New Query;
		Query.TempTablesManager = AdditionalProperties.TemporaryTableManagerJobQueue;
		Query.SetParameter("Recorder", Filter.Recorder.Value);
		Query.Text = "
		|SELECT DISTINCT
		|	Table.Recorder AS Document,
		|	Table.Period AS TaskPeriod,
		|	Table.Organization AS Organization,
		|	VALUE(Catalog.BackdateJobKinds.RecordBalanceSheetStatementRegisterRecords) AS JobKind
		|FROM
		|	(SELECT
		|		InitialEntries.Recorder AS Recorder,
		|		InitialEntries.Period AS Period,
		|		InitialEntries.Active AS Active,
		|		InitialEntries.RecordType AS RecordType,
		|		InitialEntries.Organization AS Organization,
		|		InitialEntries.Currency AS Currency,
		|		InitialEntries.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|		InitialEntries.ItemsLocationAttributes AS ItemsLocationAttributes,
		|		InitialEntries.ReversingEntry AS ReversingEntry,
		|		InitialEntries.RevenueAmount AS RevenueAmount,
		|		InitialEntries.RevenueAmountMan AS RevenueAmountMan
		|	FROM
		|		VT_TaskQueueInitialEntries AS InitialEntries
		|
		|	UNION ALL
		|
		|	SELECT
		|		Records.Recorder AS Recorder,
		|		Records.Period AS Period,
		|		Records.Active AS Active,
		|		Records.RecordType AS RecordType,
		|		Records.Organization AS Organization,
		|		Records.Currency AS Currency,
		|		Records.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|		Records.ItemsLocationAttributes AS ItemsLocationAttributes,
		|		Records.ReversingEntry AS ReversingEntry,
		|		-Records.RevenueAmount AS RevenueAmount,
		|		-Records.RevenueAmountMan AS RevenueAmountMan
		|	FROM
		|		AccumulationRegister.GoodsToBeRegisteredInReportsToConsignor AS Records
		|	WHERE
		|		Records.Recorder = &Recorder) AS Table
		|GROUP BY
		|	Table.Recorder,
		|	Table.Period,
		|	Table.Active,
		|	Table.RecordType,
		|	Table.Organization,
		|	Table.Currency,
		|	Table.InventoryOwnerAttribute,
		|	Table.ItemsLocationAttributes,
		|	Table.ReversingEntry
		|HAVING
		|	SUM(Table.RevenueAmount) <> 0 OR SUM(Table.RevenueAmountMan) <> 0
		|;
		|DROP VT_TaskQueueInitialEntries";

		DataForRegisteringTasks = Query.Execute().Unload();

		BackdateJobQueue.CreateNonOperationalQueueJobsWhenRecordingRecordset(ThisObject, Undefined,
			DataForRegisteringTasks);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf