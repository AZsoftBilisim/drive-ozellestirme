#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not DocumentsPosting.MonitorChanges(AdditionalProperties)
		Or ExchangePlans.MasterNode() <> Undefined Then
		Return;
	EndIf;
	
	// The current state of the balances is placed in a temporary table
	// in order to get a change in the current register balances when writing.
	
	QueryTextsForGettingChangeTable = 
		MonthEndTransactionsServer.QueryTextsForCaseChangeTable(Metadata(), Filter);
	
	Query = New Query;
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.Text = QueryTextsForGettingChangeTable.InitialDataSampleText;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	
	Query.Execute();
	
	AdditionalProperties.Insert("SampleTextOfChangeTable", QueryTextsForGettingChangeTable.SampleTextOfChangeTable);
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
		
	// Verification of fraud.Loading is not required, because this object in the RIB must create tasks when writing.
	If Not DocumentsPosting.MonitorChanges(AdditionalProperties)
		Or ExchangePlans.MasterNode() <> Undefined Then
		Return;
	EndIf;
	
	ArrayOfRequestTexts = New Array;
	ArrayOfRequestTexts.Add(AdditionalProperties.SampleTextOfChangeTable);
	
	TextOfTaskForGeneratingVATRegisteredRecords =
	"SELECT DISTINCT
	|	BEGINOFPERIOD(ChangesTable.Period, MONTH) AS Month,
	|	ChangesTable.Organization AS Organization,
	|	ChangesTable.DocumentPayments AS TaxInvoice
	|INTO TTName
	|FROM
	|	ChangesTableVATPrepaymentsFromCustomer AS ChangesTable
	|";
	TTName = Metadata().Name + "_JobsForGeneratingVATRecords";
	TextOfTaskForGeneratingVATRegisteredRecords = StrReplace(TextOfTaskForGeneratingVATRegisteredRecords, "TTName", TTName);
	
	ArrayOfRequestTexts.Add(TextOfTaskForGeneratingVATRegisteredRecords);
	
	Query = New Query;
	Query.Text = StrConcat(ArrayOfRequestTexts, Common.QueryBatchSeparator());
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	
	Result = Query.ExecuteBatch();
	Selection = Result[Result.Count() - 1].Select();
	
	DocumentsPosting.RegisterControlTable(
		AdditionalProperties,
		TTName,
		Selection.Next() And Selection.Count > 0);
	
EndProcedure

#EndRegion

#EndIf