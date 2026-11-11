#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	RentalServiceTotal = 0;
	SecurityPaymentAmountTotal = 0;
	BuyoutValueTotal = 0;
	BuyoutValuePrepaymentTotal = 0;
	
	RegisterTable = Unload();
	RegisterTable.Sort("Date");
	
	If RegisterTable.Count() > 0 
		And CommonClientServer.HasAttributeOrObjectProperty(Filter,"Recorder")
		And TypeOf(Filter.Recorder.Value) = Type("DocumentRef.OBEntryOfLeaseSettlements") Then
		StartDateOfSummation = RegisterTable[0].ChangeDate;
	Else
		StartDateOfSummation = Date(1,1,1);
	EndIf;
	
	For Each SetRow In RegisterTable Do
		If SetRow.Date > StartDateOfSummation Then
			RentalServiceTotal = RentalServiceTotal + SetRow.RentalService;
			SetRow.RentalServiceTotal = RentalServiceTotal;
			
			SecurityPaymentAmountTotal = SecurityPaymentAmountTotal + SetRow.DepositPayment;
			SetRow.SecurityPaymentAmountTotal = SecurityPaymentAmountTotal;
			
			BuyoutValueTotal = BuyoutValueTotal + SetRow.BuyoutValue;
			SetRow.BuyoutValueTotal = BuyoutValueTotal;
		
			BuyoutValuePrepaymentTotal = BuyoutValuePrepaymentTotal + SetRow.BuyoutValuePrepayment;
			SetRow.BuyoutValuePrepaymentTotal = BuyoutValuePrepaymentTotal;
		EndIf;
	EndDo;
	
	Load(RegisterTable);
	
	RegisterTable.Columns.Contract.Name = "PaymentObject";
	RegisterTable.GroupBy("PaymentObject,EffectiveContractTerms");
	
	AdditionalProperties.Insert("TableOfPaymentObjects", RegisterTable);
	
	PrepareDataForGeneratingTasksBeforeRecording();
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	InformationRegisters.ScheduleOfPayments.CalculatePaymentScheduleForFinancialInstruments(
		AdditionalProperties.TableOfPaymentObjects.UnloadColumn("PaymentObject"),
		AdditionalProperties.TableOfPaymentObjects.UnloadColumn("EffectiveContractTerms"));
	SetPrivilegedMode(False);
	
	PrepareDataForGeneratingTasksWhenRecording();
	
EndProcedure

#EndRegion

#Region Private

Procedure PrepareDataForGeneratingTasksBeforeRecording()
	
	If Not DocumentsPosting.MonitorChanges(AdditionalProperties) Then
		Return;
	EndIf;
	
	// The current state of the set is placed in a temporary table
	// in order to get a change in the new set relative to the current one when writing.
	
	QueryText = "
	|SELECT
	|	LeaseServicesPaymentSchedule.Recorder AS Recorder,
	|	LeaseServicesPaymentSchedule.EffectiveContractTerms AS EffectiveContractTerms,
	|	LeaseServicesPaymentSchedule.Contract AS Contract,
	|	LeaseServicesPaymentSchedule.Date AS Date,
	|	LeaseServicesPaymentSchedule.RentalService AS RentalService,
	|	LeaseServicesPaymentSchedule.RentalServiceVAT AS RentalServiceVAT,
	|	LeaseServicesPaymentSchedule.DepositPayment AS DepositPayment,
	|	LeaseServicesPaymentSchedule.SecurityPaymentVATAmount AS SecurityPaymentVATAmount,
	|	LeaseServicesPaymentSchedule.BuyoutValue AS BuyoutValue,
	|	LeaseServicesPaymentSchedule.BuyoutValueVAT AS BuyoutValueVAT,
	|	LeaseServicesPaymentSchedule.BuyoutValuePrepayment AS BuyoutValuePrepayment
	|INTO LeaseServicesPaymentScheduleBeforeWrite
	|FROM
	|	InformationRegister.LeaseServicesPaymentSchedule AS LeaseServicesPaymentSchedule
	|WHERE
	|	LeaseServicesPaymentSchedule.Recorder = &Recorder
	|	AND CASE
	|		WHEN VALUETYPE(LeaseServicesPaymentSchedule.Recorder) <> TYPE(Document.LeaseTermAdjustment)
	|			THEN TRUE
	|		ELSE LeaseServicesPaymentSchedule.Date >= BEGINOFPERIOD(CAST(LeaseServicesPaymentSchedule.Recorder AS Document.LeaseTermAdjustment).Date, DAY)
	|	END
	|	AND NOT &IsNew
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.SetParameter("IsNew", AdditionalProperties.DocumentProperties.IsNew);
	Query.Execute();
	
EndProcedure

Procedure PrepareDataForGeneratingTasksWhenRecording()
	
	If Not DocumentsPosting.MonitorChanges(AdditionalProperties) Then
		Return;
	EndIf;
	
	// The change of the new set relative to the current one is calculated taking into account the accumulated changes
	// and is placed in a temporary table for subsequent recording in the task registers.
	
	QueryText = "
	|SELECT
	|	Table.Recorder AS Recorder,
	|	Table.EffectiveContractTerms AS EffectiveContractTerms,
	|	Table.Contract AS Contract,
	|	Table.Date AS Date
	|INTO ChangesTableLeaseServicesPaymentSchedule
	|FROM
	|	(SELECT
	|		LeaseServicesPaymentSchedule.Recorder AS Recorder,
	|		LeaseServicesPaymentSchedule.EffectiveContractTerms AS EffectiveContractTerms,
	|		LeaseServicesPaymentSchedule.Contract AS Contract,
	|		LeaseServicesPaymentSchedule.Date AS Date,
	|		LeaseServicesPaymentSchedule.RentalService AS RentalService,
	|		LeaseServicesPaymentSchedule.RentalServiceVAT AS RentalServiceVAT,
	|		LeaseServicesPaymentSchedule.DepositPayment AS DepositPayment,
	|		LeaseServicesPaymentSchedule.SecurityPaymentVATAmount AS SecurityPaymentVATAmount,
	|		LeaseServicesPaymentSchedule.BuyoutValue AS BuyoutValue,
	|		LeaseServicesPaymentSchedule.BuyoutValueVAT AS BuyoutValueVAT,
	|		LeaseServicesPaymentSchedule.BuyoutValuePrepayment AS BuyoutValuePrepayment
	|	FROM
	|		LeaseServicesPaymentScheduleBeforeWrite AS LeaseServicesPaymentSchedule
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		LeaseServicesPaymentSchedule.Recorder AS Recorder,
	|		LeaseServicesPaymentSchedule.EffectiveContractTerms AS EffectiveContractTerms,
	|		LeaseServicesPaymentSchedule.Contract AS Contract,
	|		LeaseServicesPaymentSchedule.Date AS Date,
	|		-LeaseServicesPaymentSchedule.RentalService AS RentalService,
	|		-LeaseServicesPaymentSchedule.RentalServiceVAT AS RentalServiceVAT,
	|		-LeaseServicesPaymentSchedule.DepositPayment AS DepositPayment,
	|		-LeaseServicesPaymentSchedule.SecurityPaymentVATAmount AS SecurityPaymentVATAmount,
	|		-LeaseServicesPaymentSchedule.BuyoutValue AS BuyoutValue,
	|		-LeaseServicesPaymentSchedule.BuyoutValueVAT AS BuyoutValueVAT,
	|		-LeaseServicesPaymentSchedule.BuyoutValuePrepayment AS BuyoutValuePrepayment
	|	FROM
	|		InformationRegister.LeaseServicesPaymentSchedule AS LeaseServicesPaymentSchedule
	|	WHERE
	|		LeaseServicesPaymentSchedule.Recorder = &Recorder
	|		AND CASE
	|			WHEN VALUETYPE(LeaseServicesPaymentSchedule.Recorder) <> TYPE(Document.LeaseTermAdjustment)
	|				THEN TRUE
	|			ELSE LeaseServicesPaymentSchedule.Date >= BEGINOFPERIOD(CAST(LeaseServicesPaymentSchedule.Recorder AS Document.LeaseTermAdjustment).Date, DAY)
	|		END
	|	) AS Table
	|GROUP BY
	|	Table.Recorder,
	|	Table.EffectiveContractTerms,
	|	Table.Contract,
	|	Table.Date
	|HAVING
	|	SUM(Table.RentalService) <> 0
	|	OR SUM(Table.RentalServiceVAT) <> 0
	|	OR SUM(Table.DepositPayment) <> 0
	|	OR SUM(Table.SecurityPaymentVATAmount) <> 0
	|	OR SUM(Table.BuyoutValue) <> 0
	|	OR SUM(Table.BuyoutValueVAT) <> 0
	|	OR SUM(Table.BuyoutValuePrepayment) <> 0
	|
	|;
	|
	|DROP LeaseServicesPaymentScheduleBeforeWrite
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.ExecuteBatch();
	
EndProcedure

#EndRegion

#EndIf
