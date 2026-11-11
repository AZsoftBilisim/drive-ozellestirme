#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load
		Or Not DocumentsPosting.MonitorChanges(AdditionalProperties)
		Or CostCalculationAppliedAlgorithms.RegisteredRecordsAreRecordedByCalculatingBatchesAndCosts(ThisObject) Then
		Return;
	EndIf;
	
	CostCalculationAppliedAlgorithms.SaveRegisteredRecordsGeneratedByCalculationOfBatchesAndCosts(ThisObject, Replacing);
	
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
	
	If DataExchange.Load
		Or Not DocumentsPosting.MonitorChanges(AdditionalProperties)
		Or CostCalculationAppliedAlgorithms.RegisteredRecordsAreRecordedByCalculatingBatchesAndCosts(ThisObject) Then
		Return;
	EndIf;
	
	ArrayOfRequestTexts = New Array;
	ArrayOfRequestTexts.Add(AdditionalProperties.SampleTextOfChangeTable);
	
	Query = New Query;
	Query.Text = StrConcat(ArrayOfRequestTexts, Common.QueryBatchSeparator());
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	
	Query.ExecuteBatch();
	
EndProcedure

#EndRegion

#EndIf
