
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("Filter") Then
		
		If Parameters.Filter.Property("NoRefund") Then
			CommonClientServer.SetDynamicListFilterItem(List, "State",
				"Returned__", DataCompositionComparisonType.NotEqual, "NoRefund", True,
				DataCompositionSettingsItemViewMode.Inaccessible);
		EndIf;
		
		If Parameters.Filter.Property("AlreadySelectedTickets") Then
			CommonClientServer.SetDynamicListFilterItem(List, "Ref",
				Parameters.Filter.AlreadySelectedTickets, DataCompositionComparisonType.NotInList, "AlreadySelectedTickets", True,
				DataCompositionSettingsItemViewMode.Inaccessible);
		EndIf;
		
		If Parameters.Filter.Property("ExpenseReportDate") Then
			CommonClientServer.SetDynamicListFilterItem(List, "ArrivalDate",
				Parameters.Filter.ExpenseReportDate, DataCompositionComparisonType.LessOrEqual, "ExpenseReportDate", True,
				DataCompositionSettingsItemViewMode.Inaccessible);
		EndIf;
		
	EndIf;
	
EndProcedure
