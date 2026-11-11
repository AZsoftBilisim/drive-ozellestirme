#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If DocumentsPosting.CalculateChanges_(AdditionalProperties) Then
		
		LockForUpdate = True;
		
		Query = New Query;
		Query.SetParameter("Recorder", Filter.Recorder.Value);
		Query.SetParameter("IsNew",    AdditionalProperties.DocumentProperties.IsNew);
		Query.TempTablesManager = AdditionalProperties.TempTablesManager;
		Query.Text =
		"SELECT
		|	Table.PaymentRequest AS PaymentRequest,
		|	Table.BankAccountCashAccount                 AS BankAccountCashAccount,
		|	Table.Recipient                          AS Recipient,
		|	Table.Organization                         AS Organization,
		|	CASE
		|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN Table.Sum
		|		ELSE -Table.Sum
		|	END                                       AS SumBeforeWrite
		|INTO CashFlowsPayableBeforeRecording
		|FROM
		|	AccumulationRegister.CashToBePaid AS Table
		|WHERE
		|	Table.Recorder = &Recorder
		|	AND NOT &IsNew
		|";
		
		Query.Execute();
	EndIf;
	
	CreateTableOfPaymentObjects();
	InformationRegisters.ScheduleOfPayments.SetDataLocksForGraphCalculation(
		AdditionalProperties.TableOfPaymentObjects, "AccumulationRegister.CashToBePaid", "PaymentRequest");
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)

	If DataExchange.Load Then
		Return;
	EndIf;

	If DocumentsPosting.CalculateChanges_(AdditionalProperties) Then
		
		// The change of the new set relative to the current one is calculated, taking into account the accumulated changes
		// , and is placed in the temporary table "Movement of monetary means and payment Change".
		Query = New Query;
		Query.TempTablesManager = AdditionalProperties.TempTablesManager;
		Query.SetParameter("Recorder", Filter.Recorder.Value);
		Query.Text =
		"SELECT
		|	ChangesTable.PaymentRequest AS PaymentRequest,
		|	ChangesTable.BankAccountCashAccount                 AS BankAccountCashAccount,
		|	ChangesTable.Recipient                          AS Recipient,
		|	ChangesTable.Organization                         AS Organization,
		|	SUM(ChangesTable.SumUpdate)               AS SumUpdate
		|
		|INTO CashFlowsPayableChange
		|FROM
		|	(SELECT
		|		Table.PaymentRequest AS PaymentRequest,
		|		Table.BankAccountCashAccount                 AS BankAccountCashAccount,
		|		Table.Recipient                          AS Recipient,
		|		Table.Organization                         AS Organization,
		|		Table.SumBeforeWrite                   AS SumUpdate
		|	FROM
		|		CashFlowsPayableBeforeRecording AS Table
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Table.PaymentRequest AS PaymentRequest,
		|		Table.BankAccountCashAccount                 AS BankAccountCashAccount,
		|		Table.Recipient                          AS Recipient,
		|		Table.Organization                         AS Organization,
		|		CASE
		|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -Table.Sum
		|			ELSE Table.Sum
		|		END                                       AS SumUpdate
		|	FROM
		|		AccumulationRegister.CashToBePaid AS Table
		|	WHERE
		|		Table.Recorder = &Recorder) AS ChangesTable
		|
		|GROUP BY
		|	ChangesTable.PaymentRequest,
		|	ChangesTable.BankAccountCashAccount,
		|	ChangesTable.Recipient,
		|	ChangesTable.Organization
		|
		|HAVING
		|	SUM(ChangesTable.SumUpdate) <> 0
		|;
		|DROP CashFlowsPayableBeforeRecording
		|";
		
		Result = Query.ExecuteBatch();
		
		Selection = Result[0].Select();
		DocumentsPosting.RegisterControlTable(AdditionalProperties,
			"CashFlowsPayableChange", Selection.Next() And Selection.Count > 0);
		
	EndIf;
	
	InformationRegisters.ScheduleOfPayments.CalculatePaymentScheduleForCashToBePaid(
		AdditionalProperties.TableOfPaymentObjects.UnloadColumn("PaymentObject"));
	
EndProcedure

#EndRegion

#Region Private

// Generates a table of requests that were previously in the movements and that will now be recorded.
//
Procedure CreateTableOfPaymentObjects()

	Query = New Query;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.Text = "
	|SELECT DISTINCT
	|	Table.PaymentRequest AS PaymentObject
	|FROM
	|	AccumulationRegister.CashToBePaid AS Table
	|WHERE
	|	Table.Recorder = &Recorder
	|";
	
	TableOfPaymentObjects = Query.Execute().Unload();
	
	TableOfNewPaymentObjects = Unload(, "PaymentRequest");
	TableOfNewPaymentObjects.GroupBy("PaymentRequest");
	For Each Record In TableOfNewPaymentObjects Do
		If TableOfPaymentObjects.Find(Record.PaymentRequest, "PaymentObject") = Undefined Then
			TableOfPaymentObjects.Add().PaymentObject = Record.PaymentRequest;
		EndIf;
	EndDo;
	
	AdditionalProperties.Insert("TableOfPaymentObjects", TableOfPaymentObjects);
	
EndProcedure

#EndRegion

#EndIf