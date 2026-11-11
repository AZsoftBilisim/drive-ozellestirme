#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		PrepareDataForRegisteringTasksInNonOperationalQueue();
		Return;
	EndIf;
	
	PrepareDataForRegisteringTasksInNonOperationalQueue();

	If Not AdditionalProperties.Property("DocumentProperties") Then
		InfobaseUpdate.CheckObjectProcessed(ThisObject);
	EndIf;
	
	If AdditionalProperties.Property("DonTSavePending")
		Or (AdditionalProperties.Property("DocumentProperties") 
			And AdditionalProperties.DocumentProperties.WriteMode = DocumentWriteMode.UndoPosting)
		Or Count() = 0 Then
		Return;
	EndIf;
	
	// Save Deferred movements
	RegisterDescription = GenerateCaseDescription();
	#Region QueryText
	QueryText = 
	"SELECT
	|	&AllFields
	|INTO NewRegisteredRecords_
	|FROM
	|	&Set AS T
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&AllFields
	|INTO CurRegisteredRecords
	|FROM
	|	AccumulationRegister.RecordsCashCounterparty AS T
	|WHERE
	|	T.Recorder = &Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&AliasDimensions,
	|	&ResourcesSum
	|INTO Differences1
	|FROM
	|	(SELECT
	|	&AliasDimensions,
	|	&ResourcesMinus
	|	FROM
	|		NewRegisteredRecords_ AS T
	|	WHERE
	|		NOT T.DeferredPosting
	|	
	|	UNION ALL
	|	
	|	SELECT
	|	&AliasDimensions,
	|	&ResourcesPlus
	|	FROM
	|		CurRegisteredRecords AS T
	|	WHERE
	|		NOT T.DeferredPosting
	|	) AS T
	|GROUP BY
	|	&Groups
	|HAVING
	|	&ResourcesSelection
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Differences1.Organization AS Organization1,
	|	&AllFields
	|FROM
	|	CurRegisteredRecords AS T
	|	LEFT JOIN Differences1 AS Differences1
	|	ON TRUE
	|	AND &Join
	|WHERE
	|	T.DeferredPosting
	|	AND Differences1.Organization IS NULL";
	QueryText = StrReplace(QueryText, "&AllFields", RegisterDescription.AllRegisterFields);
	QueryText = StrReplace(QueryText, "&AliasDimensions", RegisterDescription.AliasedGroupings);
	QueryText = StrReplace(QueryText, "&ResourcesSum", RegisterDescription.ResourcesSum);
	QueryText = StrReplace(QueryText, "&ResourcesMinus", RegisterDescription.ResourcesMinus);
	QueryText = StrReplace(QueryText, "&ResourcesPlus", RegisterDescription.Resources);
	QueryText = StrReplace(QueryText, "&Groups", RegisterDescription.Groups);
	QueryText = StrReplace(QueryText, "&ResourcesSelection", RegisterDescription.ResourcesSelection);
	QueryText = StrReplace(QueryText, "&Join", RegisterDescription.Join);
	#EndRegion
	
	Query = New Query(QueryText);
	Query.SetParameter("Set", Unload());
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		FillPropertyValues(Add(), Selection);
	EndDo;
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		CreateNonOperationalQueueJobsWhenWriting();
		Return;
	EndIf;
	
	CreateNonOperationalQueueJobsWhenWriting();
	
EndProcedure

Function GenerateCaseDescription()
	
	LongDesc = New Structure;

	RegisterSet = AccumulationRegisters.RecordsCashCounterparty.CreateRecordSet();
	RegisterTable = RegisterSet.UnloadColumns();
	
	Separator = ","+Chars.LF + Chars.Tab;
	AllRegisterFields = "";
	For Each Column In RegisterTable.Columns Do
		If StrFind(Column.Name, "Delete") > 0 
			Or StrFind(Column.Name, "PointInTime") > 0 Then
			Continue;
		EndIf;
		AllRegisterFields = AllRegisterFields + ?(AllRegisterFields = "", "", Separator) 
			+ "T."+ Column.Name + " AS " + Column.Name;
	EndDo;
	LongDesc.Insert("AllRegisterFields", AllRegisterFields);
	
	RegisterMetadata = Metadata();
	AliasedGroupings = "";
	Groups = "";
	Join = "TRUE";
	For Each Dimension In RegisterMetadata.Dimensions Do
		If StrFind(Dimension.Name, "Delete") > 0 Then
			Continue;
		EndIf;
		AliasedGroupings = AliasedGroupings + ?(AliasedGroupings = "", "", Separator) 
			+ "T."+ Dimension.Name + " AS " + Dimension.Name;
		Groups = Groups + ?(Groups = "", "", Separator) 
			+ "T."+ Dimension.Name;
		If StrFind(Dimension.Name, "ARAPDocument") = 0 Then
			Join = Join + ?(Join = "", "", Chars.LF + Chars.Tab) + "AND T."+ Dimension.Name+ " = Differences1."+ Dimension.Name;
		EndIf;
	EndDo;
	LongDesc.Insert("AliasedGroupings", AliasedGroupings);
	LongDesc.Insert("Groups", Groups);
	LongDesc.Insert("Join", Join);
	
	Resources = "";
	ResourcesSum = "";
	ResourcesSelection = "FALSE";
	For Each Resource In RegisterMetadata.Resources Do
		If StrFind(Resource.Name, "Delete") > 0
			Or StrFind(Resource.Name, "PayAmount") = 0 Then
			Continue;
		EndIf;
		Resources = Resources + ?(Resources = "", "", Separator) 
			+ "T."+ Resource.Name + " AS " + Resource.Name;
		ResourcesSum = ResourcesSum + ?(ResourcesSum = "", "", Separator) 
			+ "SUM(T."+ Resource.Name + ") AS " + Resource.Name;
		ResourcesSelection = ResourcesSelection + ?(ResourcesSelection = "", "", Chars.LF + Chars.Tab) + "OR SUM(T."+ Resource.Name + ") <> 0";
	EndDo;
	LongDesc.Insert("Resources", Resources);
	LongDesc.Insert("ResourcesMinus", StrReplace(Resources, "T.", "-T."));
	LongDesc.Insert("ResourcesSum", ResourcesSum);
	LongDesc.Insert("ResourcesSelection", ResourcesSelection);
	
	Return LongDesc;
	
EndFunction

#EndRegion

#Region Private

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
		|	InitialEntries.LineOfBusinessCash AS LineOfBusinessCash,
		|	InitialEntries.Cash AS Cash,
		|	InitialEntries.CashType AS CashType,
		|	InitialEntries.CashFlowItem AS CashFlowItem,
		|	InitialEntries.PaymentCurrency AS PaymentCurrency,
		|	InitialEntries.ProductCostElement AS ProductCostElement,
		|	InitialEntries.PaymentType275FZ AS PaymentType275FZ,
		|	InitialEntries.CounterpartyLineOfBusiness AS CounterpartyLineOfBusiness,
		|	InitialEntries.Partner AS Partner,
		|	InitialEntries.Counterparty AS Counterparty,
		|	InitialEntries.Contract AS Contract,
		|	InitialEntries.ARAPObject AS ARAPObject,
		|	InitialEntries.ARAPDocument AS ARAPDocument,
		|	InitialEntries.TargetFundItem AS TargetFundItem,
		|	InitialEntries.PayAmount AS PayAmount,
		|	InitialEntries.PaymentAmountLocal AS PaymentAmountLocal,
		|	InitialEntries.PaymentAmountPaymentCurrency AS PaymentAmountPaymentCurrency,
		|	InitialEntries.PostpaymentAmount AS PostpaymentAmount,
		|	InitialEntries.PostpaymentAmountLocal AS PostpaymentAmountLocal,
		|	InitialEntries.PaymentAmountInPaymentCurrency AS PaymentAmountInPaymentCurrency,
		|	InitialEntries.PrepaymentAmountMan AS PrepaymentAmountMan,
		|	InitialEntries.PrepaymentAmountLocal AS PrepaymentAmountLocal,
		|	InitialEntries.PrepaymentAmount AS PrepaymentAmount,
		|	InitialEntries.AmountToBePaidWithinLimit AS AmountToBePaidWithinLimit,
		|	InitialEntries.AmountToBePaidAboveLimit AS AmountToBePaidAboveLimit,
		|	InitialEntries.VATAmount AS VATAmount,
		|	InitialEntries.VATAmountCompl AS VATAmountCompl,
		|	InitialEntries.AmountVATCurrencyPayment AS AmountVATCurrencyPayment,
		|	InitialEntries.ARAPCurrency AS ARAPCurrency,
		|	InitialEntries.PaymentAmountInTheSettlementCurrency AS PaymentAmountInTheSettlementCurrency,
		|	InitialEntries.PostPaymentAmountInARAPCurrency AS PostPaymentAmountInARAPCurrency,
		|	InitialEntries.PrepaymentAmountInARAPCurrency AS PrepaymentAmountInARAPCurrency,
		|	InitialEntries.SourceOfCashFinancialAccountingGroup AS SourceOfCashFinancialAccountingGroup,
		|	InitialEntries.SourceOfARAPFinancialAccountingGroup AS SourceOfARAPFinancialAccountingGroup,
		|	InitialEntries.DeferredPosting AS DeferredPosting,
		|	InitialEntries.VATRate AS VATRate,
		|	InitialEntries.ReversingEntry AS ReversingEntry,
		|	InitialEntries.PaymentRequest AS PaymentRequest
		|INTO VT_TaskQueueInitialEntries
		|FROM
		|	AccumulationRegister.RecordsCashCounterparty AS InitialEntries
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
		|		InitialEntries.LineOfBusinessCash AS LineOfBusinessCash,
		|		InitialEntries.Cash AS Cash,
		|		InitialEntries.CashType AS CashType,
		|		InitialEntries.CashFlowItem AS CashFlowItem,
		|		InitialEntries.PaymentCurrency AS PaymentCurrency,
		|		InitialEntries.ProductCostElement AS ProductCostElement,
		|		InitialEntries.PaymentType275FZ AS PaymentType275FZ,
		|		InitialEntries.CounterpartyLineOfBusiness AS CounterpartyLineOfBusiness,
		|		InitialEntries.Partner AS Partner,
		|		InitialEntries.Counterparty AS Counterparty,
		|		InitialEntries.Contract AS Contract,
		|		InitialEntries.ARAPObject AS ARAPObject,
		|		InitialEntries.ARAPDocument AS ARAPDocument,
		|		InitialEntries.TargetFundItem AS TargetFundItem,
		|		InitialEntries.PayAmount AS PayAmount,
		|		InitialEntries.PaymentAmountLocal AS PaymentAmountLocal,
		|		InitialEntries.PaymentAmountPaymentCurrency AS PaymentAmountPaymentCurrency,
		|		InitialEntries.PostpaymentAmount AS PostpaymentAmount,
		|		InitialEntries.PostpaymentAmountLocal AS PostpaymentAmountLocal,
		|		InitialEntries.PaymentAmountInPaymentCurrency AS PaymentAmountInPaymentCurrency,
		|		InitialEntries.PrepaymentAmountMan AS PrepaymentAmountMan,
		|		InitialEntries.PrepaymentAmountLocal AS PrepaymentAmountLocal,
		|		InitialEntries.PrepaymentAmount AS PrepaymentAmount,
		|		InitialEntries.AmountToBePaidWithinLimit AS AmountToBePaidWithinLimit,
		|		InitialEntries.AmountToBePaidAboveLimit AS AmountToBePaidAboveLimit,
		|		InitialEntries.VATAmount AS VATAmount,
		|		InitialEntries.VATAmountCompl AS VATAmountCompl,
		|		InitialEntries.AmountVATCurrencyPayment AS AmountVATCurrencyPayment,
		|		InitialEntries.ARAPCurrency AS ARAPCurrency,
		|		InitialEntries.PaymentAmountInTheSettlementCurrency AS PaymentAmountInTheSettlementCurrency,
		|		InitialEntries.PostPaymentAmountInARAPCurrency AS PostPaymentAmountInARAPCurrency,
		|		InitialEntries.PrepaymentAmountInARAPCurrency AS PrepaymentAmountInARAPCurrency,
		|		InitialEntries.SourceOfCashFinancialAccountingGroup AS SourceOfCashFinancialAccountingGroup,
		|		InitialEntries.SourceOfARAPFinancialAccountingGroup AS SourceOfARAPFinancialAccountingGroup,
		|		InitialEntries.DeferredPosting AS DeferredPosting,
		|		InitialEntries.VATRate AS VATRate,
		|		InitialEntries.ReversingEntry AS ReversingEntry,
		|		InitialEntries.PaymentRequest AS PaymentRequest
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
		|		Records.LineOfBusinessCash AS LineOfBusinessCash,
		|		Records.Cash AS Cash,
		|		Records.CashType AS CashType,
		|		Records.CashFlowItem AS CashFlowItem,
		|		Records.PaymentCurrency AS PaymentCurrency,
		|		Records.ProductCostElement AS ProductCostElement,
		|		Records.PaymentType275FZ AS PaymentType275FZ,
		|		Records.CounterpartyLineOfBusiness AS CounterpartyLineOfBusiness,
		|		Records.Partner AS Partner,
		|		Records.Counterparty AS Counterparty,
		|		Records.Contract AS Contract,
		|		Records.ARAPObject AS ARAPObject,
		|		Records.ARAPDocument AS ARAPDocument,
		|		Records.TargetFundItem AS TargetFundItem,
		|		-Records.PayAmount AS PayAmount,
		|		-Records.PaymentAmountLocal AS PaymentAmountLocal,
		|		-Records.PaymentAmountPaymentCurrency AS PaymentAmountPaymentCurrency,
		|		-Records.PostpaymentAmount AS PostpaymentAmount,
		|		-Records.PostpaymentAmountLocal AS PostpaymentAmountLocal,
		|		-Records.PaymentAmountInPaymentCurrency AS PaymentAmountInPaymentCurrency,
		|		-Records.PrepaymentAmountMan AS PrepaymentAmountMan,
		|		-Records.PrepaymentAmountLocal AS PrepaymentAmountLocal,
		|		-Records.PrepaymentAmount AS PrepaymentAmount,
		|		-Records.AmountToBePaidWithinLimit AS AmountToBePaidWithinLimit,
		|		-Records.AmountToBePaidAboveLimit AS AmountToBePaidAboveLimit,
		|		-Records.VATAmount AS VATAmount,
		|		-Records.VATAmountCompl AS VATAmountCompl,
		|		-Records.AmountVATCurrencyPayment AS AmountVATCurrencyPayment,
		|		Records.ARAPCurrency AS ARAPCurrency,
		|		-Records.PaymentAmountInTheSettlementCurrency AS PaymentAmountInTheSettlementCurrency,
		|		-Records.PostPaymentAmountInARAPCurrency AS PostPaymentAmountInARAPCurrency,
		|		-Records.PrepaymentAmountInARAPCurrency AS PrepaymentAmountInARAPCurrency,
		|		Records.SourceOfCashFinancialAccountingGroup AS SourceOfCashFinancialAccountingGroup,
		|		Records.SourceOfARAPFinancialAccountingGroup AS SourceOfARAPFinancialAccountingGroup,
		|		Records.DeferredPosting AS DeferredPosting,
		|		Records.VATRate AS VATRate,
		|		Records.ReversingEntry AS ReversingEntry,
		|		Records.PaymentRequest AS PaymentRequest
		|	FROM
		|		AccumulationRegister.RecordsCashCounterparty AS Records
		|	WHERE
		|		Records.Recorder = &Recorder) AS Table
		|GROUP BY
		|	Table.Active,
		|	Table.Period,
		|	Table.Recorder,
		|	Table.BusinessOperation,
		|	Table.Organization,
		|	Table.Department,
		|	Table.LineOfBusinessCash,
		|	Table.Cash,
		|	Table.CashType,
		|	Table.CashFlowItem,
		|	Table.PaymentCurrency,
		|	Table.ProductCostElement,
		|	Table.PaymentType275FZ,
		|	Table.CounterpartyLineOfBusiness,
		|	Table.Partner,
		|	Table.Counterparty,
		|	Table.Contract,
		|	Table.ARAPObject,
		|	Table.ARAPDocument,
		|	Table.TargetFundItem,
		|	Table.ARAPCurrency,
		|	Table.SourceOfCashFinancialAccountingGroup,
		|	Table.SourceOfARAPFinancialAccountingGroup,
		|	Table.DeferredPosting,
		|	Table.VATRate,
		|	Table.ReversingEntry,
		|	Table.PaymentRequest
		|HAVING
		|	SUM(Table.PayAmount) <> 0
		|	OR SUM(Table.PaymentAmountLocal) <> 0
		|	OR SUM(Table.PaymentAmountPaymentCurrency) <> 0
		|	OR SUM(Table.PostpaymentAmount) <> 0
		|	OR SUM(Table.PostpaymentAmountLocal) <> 0
		|	OR SUM(Table.PaymentAmountInPaymentCurrency) <> 0
		|	OR SUM(Table.PrepaymentAmountMan) <> 0
		|	OR SUM(Table.PrepaymentAmountLocal) <> 0
		|	OR SUM(Table.PrepaymentAmount) <> 0
		|	OR SUM(Table.PaymentAmountInTheSettlementCurrency) <> 0
		|	OR SUM(Table.PostPaymentAmountInARAPCurrency) <> 0
		|	OR SUM(Table.PrepaymentAmountInARAPCurrency) <> 0;
		|DROP VT_TaskQueueInitialEntries";

		DataForRegisteringTasks = Query.Execute().Unload();

		BackdateJobQueue.CreateNonOperationalQueueJobsWhenRecordingRecordset(ThisObject, Undefined,
			DataForRegisteringTasks);

	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
