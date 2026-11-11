#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	If Not AdditionalProperties.Property("DocumentProperties") Then
		InfobaseUpdate.CheckObjectProcessed(ThisObject);
	EndIf;

	If Not DocumentsPosting.MonitorChanges(AdditionalProperties) Then
		Return;
	EndIf;
	
	LockForUpdate = True;
		
	// The current state of the set is placed in a temporary table
	// in order to get a change in the new set relative to the current one when writing.
	
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
	
	If DataExchange.Load Or Not DocumentsPosting.MonitorChanges(AdditionalProperties) Then
		Return;
	EndIf;
	
	RegisterName = "RecordsIncomeExpensesOtherAssetsLiabilities";
	Query = New Query;
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	
	If Not ExchangePlans.MasterNode() = Undefined Then // In RIB, this register is processed only in the main node.
		
		// Destroying the table of initial register entries:
		Query.Text = "DROP InitialEntries" + RegisterName;
		Query.Execute();
		Return;
		
	EndIf;
	
	// The change of the new set relative to the current one is calculated taking into account the accumulated changes
	// and is placed in a temporary table for subsequent recording in the task registers.
	Query.Text = AdditionalProperties.SampleTextOfChangeTable;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.Execute();
	
EndProcedure
#EndRegion

#EndIf
