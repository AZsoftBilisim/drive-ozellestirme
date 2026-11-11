#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	AmountTotal = 0; InterestTotal = 0; FeeTotal = 0;
	For Each SetRow In ThisObject Do
		
		AmountTotal = AmountTotal + SetRow.Sum;
		SetRow.AmountTotal = AmountTotal;
		
		InterestTotal = InterestTotal + SetRow.Interests;
		SetRow.InterestTotal = InterestTotal;
		
		FeeTotal = FeeTotal + SetRow.Fee;
		SetRow.FeeTotal = FeeTotal;
	EndDo;
	
	CreateTableOfPaymentObjects();
	
	PrepareDataForGeneratingTasksBeforeRecording();
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	InformationRegisters.ScheduleOfPayments.CalculatePaymentScheduleForFinancialInstruments(
		AdditionalProperties.TableOfPaymentObjects.UnloadColumn("PaymentObject"));
	
	PrepareDataForGeneratingTasksWhenRecording();
	
	SetPrivilegedMode(False);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure") Then
		For Each SetRow In ThisObject Do
			FillPropertyValues(SetRow, FillingData);
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Generates a table of orders that were previously in the movements and that will now be recorded.
//
Procedure CreateTableOfPaymentObjects()
	
	Contract = Common.ObjectAttributeValue(Filter.ScheduleOption.Value, "Owner");
	
	TableOfPaymentObjects = New ValueTable;
	TableOfPaymentObjects.Columns.Add("PaymentObject");
	TableOfPaymentObjects.Columns.Add("ScheduleOption");
	NewRow = TableOfPaymentObjects.Add();
	NewRow.PaymentObject = Contract;
	NewRow.ScheduleOption = Filter.ScheduleOption.Value;
	
	AdditionalProperties.Insert("TableOfPaymentObjects", TableOfPaymentObjects);
	
EndProcedure

Procedure PrepareDataForGeneratingTasksBeforeRecording()
	
	If Not AdditionalProperties.Property("TempTablesManager") Then
		AdditionalProperties.Insert("TempTablesManager", New TempTablesManager());
	EndIf;
	
	// The current state of the set is placed in a temporary table
	// in order to get a change in the new set relative to the current one when writing.
	
	QueryText = "
	|SELECT
	|	ScheduleOfPaymentForLoansAndDeposits.Period AS Period,
	|	ScheduleOfPaymentForLoansAndDeposits.ScheduleOption AS ScheduleOption,
	|	ScheduleOfPaymentForLoansAndDeposits.Sum AS Sum,
	|	ScheduleOfPaymentForLoansAndDeposits.Interests AS Interests,
	|	ScheduleOfPaymentForLoansAndDeposits.Fee AS Fee
	|INTO ScheduleOfPaymentForLoansAndDepositsBeforeWrite
	|FROM
	|	InformationRegister.ScheduleOfPaymentForLoansAndDeposits AS ScheduleOfPaymentForLoansAndDeposits
	|WHERE
	|	&ConditionPeriod
	|	AND &ConditionVariantOfGraph
	|";
	
	If Filter.Period.Use Then
		ConditionPeriod = "ScheduleOfPaymentForLoansAndDeposits.Period = &Period";
	Else
		ConditionPeriod = "TRUE";
	EndIf;
	
	If Filter.ScheduleOption.Use Then
		ConditionVariantOfGraph = "ScheduleOfPaymentForLoansAndDeposits.ScheduleOption = &ScheduleOption";
	Else
		ConditionVariantOfGraph = "TRUE";
	EndIf;
	
	QueryText = StrReplace(QueryText, "&ConditionPeriod", ConditionPeriod);
	QueryText = StrReplace(QueryText, "&ConditionVariantOfGraph", ConditionVariantOfGraph);
	
	Query = New Query(QueryText);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	
	If Filter.Period.Use Then
		Query.SetParameter("Period", Filter.Period.Value);
	EndIf;
	
	If Filter.ScheduleOption.Use Then
		Query.SetParameter("ScheduleOption", Filter.ScheduleOption.Value);
	EndIf;
	
	Query.Execute();
	
EndProcedure

Procedure PrepareDataForGeneratingTasksWhenRecording()
	
	// The change of the new set relative to the current one is calculated taking into account the accumulated changes
	// and is placed in a temporary table for subsequent recording in the task registers.
	
	QueryText = "
	|SELECT
	|	Table.Period AS Period,
	|	Table.ScheduleOption AS ScheduleOption
	|INTO ChangesTableScheduleOfPaymentForLoansAndDeposits
	|FROM
	|	(SELECT
	|		ScheduleOfPaymentForLoansAndDeposits.Period AS Period,
	|		ScheduleOfPaymentForLoansAndDeposits.ScheduleOption AS ScheduleOption,
	|		ScheduleOfPaymentForLoansAndDeposits.Sum AS Sum,
	|		ScheduleOfPaymentForLoansAndDeposits.Interests AS Interests,
	|		ScheduleOfPaymentForLoansAndDeposits.Fee AS Fee
	|	FROM
	|		ScheduleOfPaymentForLoansAndDepositsBeforeWrite AS ScheduleOfPaymentForLoansAndDeposits
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ScheduleOfPaymentForLoansAndDeposits.Period AS Period,
	|		ScheduleOfPaymentForLoansAndDeposits.ScheduleOption AS ScheduleOption,
	|		-ScheduleOfPaymentForLoansAndDeposits.Sum AS Sum,
	|		-ScheduleOfPaymentForLoansAndDeposits.Interests AS Interests,
	|		-ScheduleOfPaymentForLoansAndDeposits.Fee AS Fee
	|	FROM
	|		InformationRegister.ScheduleOfPaymentForLoansAndDeposits AS ScheduleOfPaymentForLoansAndDeposits
	|	WHERE
	|		&ConditionPeriod
	|		AND &ConditionVariantOfGraph
	|	) AS Table
	|GROUP BY
	|	Table.Period,
	|	Table.ScheduleOption
	|HAVING
	|	SUM(Table.Sum) <> 0
	|	OR SUM(Table.Interests) <> 0
	|	OR SUM(Table.Fee) <> 0
	|
	|;
	|
	|DROP ScheduleOfPaymentForLoansAndDepositsBeforeWrite
	|";
	
	If Filter.Period.Use Then
		ConditionPeriod = "ScheduleOfPaymentForLoansAndDeposits.Period = &Period";
	Else
		ConditionPeriod = "TRUE";
	EndIf;
	
	If Filter.ScheduleOption.Use Then
		ConditionVariantOfGraph = "ScheduleOfPaymentForLoansAndDeposits.ScheduleOption = &ScheduleOption";
	Else
		ConditionVariantOfGraph = "TRUE";
	EndIf;
	
	QueryText = StrReplace(QueryText, "&ConditionPeriod", ConditionPeriod);
	QueryText = StrReplace(QueryText, "&ConditionVariantOfGraph", ConditionVariantOfGraph);
	
	Query = New Query(QueryText);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	
	If Filter.Period.Use Then
		Query.SetParameter("Period", Filter.Period.Value);
	EndIf;
	
	If Filter.ScheduleOption.Use Then
		Query.SetParameter("ScheduleOption", Filter.ScheduleOption.Value);
	EndIf;
	
	Query.ExecuteBatch();
	
	MonthEndTransactionsServer.ReflectTasksByEndOfMonth(
		DocumentsPosting.DocumentEmulation(Undefined, '00010101'),
		AdditionalProperties.TempTablesManager);
	
EndProcedure

#EndRegion

#EndIf