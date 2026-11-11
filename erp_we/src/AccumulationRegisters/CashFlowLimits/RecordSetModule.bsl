#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Or Not DocumentsPosting.CalculateChanges_(AdditionalProperties) Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.Text = "
	|SELECT DISTINCT
	|	Table.CashFlowItem,
	|	Table.Organization,
	|	Table.Department
	|INTO CashFlowLimitsChange
	|FROM
	|	AccumulationRegister.CashFlowLimits AS Table
	|WHERE
	|	Table.Recorder = &Recorder
	|";
	
	Selection = Query.Execute().Select();
	DocumentsPosting.RegisterControlTable(AdditionalProperties,
		"CashFlowLimitsChange", Selection.Next() And Selection.Count > 0);
	
EndProcedure

#EndRegion

#EndIf
