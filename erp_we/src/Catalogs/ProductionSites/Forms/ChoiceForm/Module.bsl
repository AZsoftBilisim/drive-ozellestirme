
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	If Parameters.Property("FilterDepartment") Then 
		
		For Each KeyAndValue In Parameters.FilterDepartment Do
			
			CommonClientServer.SetDynamicListFilterItem(
				List, 
				"Owner." + KeyAndValue.Key, 
				KeyAndValue.Value, 
				DataCompositionComparisonType.Equal,
				, 
				True);
			
		EndDo;
		
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion
