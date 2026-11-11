#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		PrepareDataForRegisteringTasksInNonOperationalQueue();
		Return;
	EndIf;

	If Not AdditionalProperties.Property("DocumentProperties") Then
		InfobaseUpdate.CheckObjectProcessed(ThisObject);
	EndIf;
	
	PrepareDataForRegisteringTasksInNonOperationalQueue();

EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		CreateNonOperationalQueueJobsWhenWriting();
		Return;
	EndIf;
	
	CreateNonOperationalQueueJobsWhenWriting();
	
EndProcedure

#EndRegion

#Region BackdateJobQueue

Procedure PrepareDataForRegisteringTasksInNonOperationalQueue()
	
	If AdditionalProperties.Property("DonTRegisterNonOperationalQueueTasks") Then
		Return;
	EndIf;
	
	If Not BackdateJobQueue.CreationOfNonOperationalQueueTasksIsAvailable(ThisObject) Then
		Return;
	EndIf;
	
	If GetFunctionalOption("NewOnlineARAPAccounting") Then
		
		Query = New Query;
		Query.TempTablesManager = New TempTablesManager;
		Query.Text = "
		|SELECT
		|	InitialEntries.Active AS Active,
		|	InitialEntries.Period AS Period,
		|	InitialEntries.Recorder AS Recorder,
		|	InitialEntries.BusinessOperation AS BusinessOperation,
		|	InitialEntries.Organization AS Organization,
		|	InitialEntries.Department AS Department,
		|	InitialEntries.LineOfBusiness AS LineOfBusiness,
		|	InitialEntries.Partner AS Partner,
		|	InitialEntries.Counterparty AS Counterparty,
		|	InitialEntries.Contract AS Contract,
		|	InitialEntries.ARAPObject AS ARAPObject,
		|	InitialEntries.CorLineOfBusiness AS CorLineOfBusiness,
		|	InitialEntries.CorPartner AS CorPartner,
		|	InitialEntries.CorCounterparty AS CorCounterparty,
		|	InitialEntries.CorContract AS CorContract,
		|	InitialEntries.CorARAPObject AS CorARAPObject,
		|	InitialEntries.AmountType AS AmountType,
		|	InitialEntries.CorAmountType AS CorAmountType,
		|	InitialEntries.Sum AS Sum,
		|	InitialEntries.AmountExcludingVAT AS AmountExcludingVAT,
		|	InitialEntries.SumCompl AS SumCompl,
		|	InitialEntries.LocalAmountExcludingVAT AS LocalAmountExcludingVAT,
		|	InitialEntries.Currency AS Currency,
		|	InitialEntries.AmountInCurrency AS AmountInCurrency,
		|	InitialEntries.AmountExcludingVATInCurrency AS AmountExcludingVATInCurrency,
		|	InitialEntries.ARAPCurrency AS ARAPCurrency,
		|	InitialEntries.AmountInARAPCurrency AS AmountInARAPCurrency,
		|	InitialEntries.AmountExcludingVATInARAPCurrency AS AmountExcludingVATInARAPCurrency,
		|	InitialEntries.CorCurrencyOfARAPAccounting AS CorCurrencyOfARAPAccounting,
		|	InitialEntries.AdjAmountInARAPCurrency AS AdjAmountInARAPCurrency,
		|	InitialEntries.AdjAmountExcludingVATInARAPCurrency AS AdjAmountExcludingVATInARAPCurrency,
		|	InitialEntries.SourceOfARAPFinancialAccountingGroup AS SourceOfARAPFinancialAccountingGroup,
		|	InitialEntries.CorSourceOfARAPFinancialAccountingGroup AS CorSourceOfARAPFinancialAccountingGroup,
		|	InitialEntries.ReversingEntry AS ReversingEntry
		|INTO VT_TaskQueueInitialEntries
		|FROM
		|	AccumulationRegister.RecordsCounterpartyCounterparty AS InitialEntries
		|WHERE
		|	InitialEntries.Recorder = &Recorder";
		Query.SetParameter("Recorder", Filter.Recorder.Value);
		Query.Execute();
		
		AdditionalProperties.Insert("TemporaryTableManagerJobQueue", Query.TempTablesManager);
		
	EndIf;
	
EndProcedure

Procedure CreateNonOperationalQueueJobsWhenWriting()
	
	If AdditionalProperties.Property("DonTRegisterNonOperationalQueueTasks") Then
		Return;
	EndIf;
	
	If Not BackdateJobQueue.CreationOfNonOperationalQueueTasksIsAvailable(ThisObject) Then
		Return;
	EndIf;
	
	If GetFunctionalOption("NewOnlineARAPAccounting") Then
		
		Query = New Query;
		Query.TempTablesManager = AdditionalProperties.TemporaryTableManagerJobQueue;
		Query.SetParameter("Recorder", Filter.Recorder.Value);
		Query.Text = "
		|SELECT DISTINCT
		|	Table.Recorder AS Recorder,
		|	Table.Period AS Period,
		|	Table.Organization AS Organization
		|FROM
		|	(SELECT
		|		InitialEntries.Active AS Active,
		|		InitialEntries.Period AS Period,
		|		InitialEntries.Recorder AS Recorder,
		|		InitialEntries.BusinessOperation AS BusinessOperation,
		|		InitialEntries.Organization AS Organization,
		|		InitialEntries.Department AS Department,
		|		InitialEntries.LineOfBusiness AS LineOfBusiness,
		|		InitialEntries.Partner AS Partner,
		|		InitialEntries.Counterparty AS Counterparty,
		|		InitialEntries.Contract AS Contract,
		|		InitialEntries.ARAPObject AS ARAPObject,
		|		InitialEntries.CorLineOfBusiness AS CorLineOfBusiness,
		|		InitialEntries.CorPartner AS CorPartner,
		|		InitialEntries.CorCounterparty AS CorCounterparty,
		|		InitialEntries.CorContract AS CorContract,
		|		InitialEntries.CorARAPObject AS CorARAPObject,
		|		InitialEntries.AmountType AS AmountType,
		|		InitialEntries.CorAmountType AS CorAmountType,
		|		InitialEntries.Sum AS Sum,
		|		InitialEntries.AmountExcludingVAT AS AmountExcludingVAT,
		|		InitialEntries.SumCompl AS SumCompl,
		|		InitialEntries.LocalAmountExcludingVAT AS LocalAmountExcludingVAT,
		|		InitialEntries.Currency AS Currency,
		|		InitialEntries.AmountInCurrency AS AmountInCurrency,
		|		InitialEntries.AmountExcludingVATInCurrency AS AmountExcludingVATInCurrency,
		|		InitialEntries.ARAPCurrency AS ARAPCurrency,
		|		InitialEntries.AmountInARAPCurrency AS AmountInARAPCurrency,
		|		InitialEntries.AmountExcludingVATInARAPCurrency AS AmountExcludingVATInARAPCurrency,
		|		InitialEntries.CorCurrencyOfARAPAccounting AS CorCurrencyOfARAPAccounting,
		|		InitialEntries.AdjAmountInARAPCurrency AS AdjAmountInARAPCurrency,
		|		InitialEntries.AdjAmountExcludingVATInARAPCurrency AS AdjAmountExcludingVATInARAPCurrency,
		|		InitialEntries.SourceOfARAPFinancialAccountingGroup AS SourceOfARAPFinancialAccountingGroup,
		|		InitialEntries.CorSourceOfARAPFinancialAccountingGroup AS CorSourceOfARAPFinancialAccountingGroup,
		|		InitialEntries.ReversingEntry AS ReversingEntry
		|	FROM
		|		VT_TaskQueueInitialEntries AS InitialEntries
		|
		|	UNION ALL
		|
		|	SELECT
		|		Records.Active AS Active,
		|		Records.Period AS Period,
		|		Records.Recorder AS Recorder,
		|		Records.BusinessOperation AS BusinessOperation,
		|		Records.Organization AS Organization,
		|		Records.Department AS Department,
		|		Records.LineOfBusiness AS LineOfBusiness,
		|		Records.Partner AS Partner,
		|		Records.Counterparty AS Counterparty,
		|		Records.Contract AS Contract,
		|		Records.ARAPObject AS ARAPObject,
		|		Records.CorLineOfBusiness AS CorLineOfBusiness,
		|		Records.CorPartner AS CorPartner,
		|		Records.CorCounterparty AS CorCounterparty,
		|		Records.CorContract AS CorContract,
		|		Records.CorARAPObject AS CorARAPObject,
		|		Records.AmountType AS AmountType,
		|		Records.CorAmountType AS CorAmountType,
		|		-Records.Sum AS Sum,
		|		-Records.AmountExcludingVAT AS AmountExcludingVAT,
		|		-Records.SumCompl AS SumCompl,
		|		-Records.LocalAmountExcludingVAT AS LocalAmountExcludingVAT,
		|		Records.Currency AS Currency,
		|		Records.AmountInCurrency AS AmountInCurrency,
		|		Records.AmountExcludingVATInCurrency AS AmountExcludingVATInCurrency,
		|		Records.ARAPCurrency AS ARAPCurrency,
		|		Records.AmountInARAPCurrency AS AmountInARAPCurrency,
		|		Records.AmountExcludingVATInARAPCurrency AS AmountExcludingVATInARAPCurrency,
		|		Records.CorCurrencyOfARAPAccounting AS CorCurrencyOfARAPAccounting,
		|		Records.AdjAmountInARAPCurrency AS AdjAmountInARAPCurrency,
		|		Records.AdjAmountExcludingVATInARAPCurrency AS AdjAmountExcludingVATInARAPCurrency,
		|		Records.SourceOfARAPFinancialAccountingGroup AS SourceOfARAPFinancialAccountingGroup,
		|		Records.CorSourceOfARAPFinancialAccountingGroup AS CorSourceOfARAPFinancialAccountingGroup,
		|		Records.ReversingEntry AS ReversingEntry
		|	FROM
		|		AccumulationRegister.RecordsCounterpartyCounterparty AS Records
		|	WHERE
		|		Records.Recorder = &Recorder) AS Table
		|GROUP BY
		|	Table.Active,
		|	Table.Period,
		|	Table.Recorder,
		|	Table.BusinessOperation,
		|	Table.Organization,
		|	Table.Department,
		|	Table.LineOfBusiness,
		|	Table.Partner,
		|	Table.Counterparty,
		|	Table.Contract,
		|	Table.ARAPObject,
		|	Table.CorLineOfBusiness,
		|	Table.CorPartner,
		|	Table.CorCounterparty,
		|	Table.CorContract,
		|	Table.CorARAPObject,
		|	Table.AmountType,
		|	Table.CorAmountType,
		|	Table.Currency,
		|	Table.AmountInCurrency,
		|	Table.AmountExcludingVATInCurrency,
		|	Table.ARAPCurrency,
		|	Table.AmountInARAPCurrency,
		|	Table.AmountExcludingVATInARAPCurrency,
		|	Table.CorCurrencyOfARAPAccounting,
		|	Table.AdjAmountInARAPCurrency,
		|	Table.AdjAmountExcludingVATInARAPCurrency,
		|	Table.SourceOfARAPFinancialAccountingGroup,
		|	Table.CorSourceOfARAPFinancialAccountingGroup,
		|	Table.ReversingEntry
		|HAVING
		|	SUM(Table.Sum) <> 0 OR SUM(Table.AmountExcludingVAT) <> 0 
		|	OR SUM(Table.SumCompl) <> 0 OR SUM(Table.LocalAmountExcludingVAT) <> 0
		|;
		|DROP VT_TaskQueueInitialEntries";

		DataForRegisteringTasks = Query.Execute().Unload();

		BackdateJobQueue.CreateNonOperationalQueueJobsWhenRecordingRecordset(ThisObject, Undefined,
			DataForRegisteringTasks);

	EndIf;
	
EndProcedure

#EndRegion

#EndIf
