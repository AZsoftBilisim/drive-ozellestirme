#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	RentalServiceTotal = 0;
	
	RegisterTable = Unload();
	RegisterTable.Sort("Date");
	
	For Each SetRow In RegisterTable Do
		
		RentalServiceTotal = RentalServiceTotal + SetRow.RentalService;
		SetRow.RentalServiceTotal = RentalServiceTotal;
		
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
	|	LeaseServicesPaymentSchedule.RentalServiceVAT AS RentalServiceVAT
	|INTO ScheduleOfPaymentsForIncomeRentalServicesBeforeWrite
	|FROM
	|	InformationRegister.ScheduleOfPaymentsForIncomeRentalServices AS LeaseServicesPaymentSchedule
	|WHERE
	|	LeaseServicesPaymentSchedule.Recorder = &Recorder
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
	
	QueryText = "SELECT
	|	Table.Recorder AS Recorder,
	|	Table.EffectiveContractTerms AS EffectiveContractTerms,
	|	Table.Contract AS Contract,
	|	Table.Date AS Date
	|INTO ChangesTableScheduleOfPaymentsForIncomeRentalServices
	|FROM
	|	(SELECT
	|		LeaseServicesPaymentSchedule.Recorder AS Recorder,
	|		LeaseServicesPaymentSchedule.EffectiveContractTerms AS EffectiveContractTerms,
	|		LeaseServicesPaymentSchedule.Contract AS Contract,
	|		LeaseServicesPaymentSchedule.Date AS Date,
	|		LeaseServicesPaymentSchedule.RentalService AS RentalService,
	|		LeaseServicesPaymentSchedule.RentalServiceVAT AS RentalServiceVAT
	|	FROM
	|		ScheduleOfPaymentsForIncomeRentalServicesBeforeWrite AS LeaseServicesPaymentSchedule
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		LeaseServicesPaymentSchedule.Recorder,
	|		LeaseServicesPaymentSchedule.EffectiveContractTerms,
	|		LeaseServicesPaymentSchedule.Contract,
	|		LeaseServicesPaymentSchedule.Date,
	|		-LeaseServicesPaymentSchedule.RentalService,
	|		-LeaseServicesPaymentSchedule.RentalServiceVAT
	|	FROM
	|		InformationRegister.ScheduleOfPaymentsForIncomeRentalServices AS LeaseServicesPaymentSchedule
	|	WHERE
	|		LeaseServicesPaymentSchedule.Recorder = &Recorder) AS Table
	|
	|GROUP BY
	|	Table.Recorder,
	|	Table.EffectiveContractTerms,
	|	Table.Contract,
	|	Table.Date
	|
	|HAVING
	|	(SUM(Table.RentalService) <> 0
	|		OR SUM(Table.RentalServiceVAT) <> 0)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP ScheduleOfPaymentsForIncomeRentalServicesBeforeWrite";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.ExecuteBatch();
	
EndProcedure

#EndRegion

#EndIf