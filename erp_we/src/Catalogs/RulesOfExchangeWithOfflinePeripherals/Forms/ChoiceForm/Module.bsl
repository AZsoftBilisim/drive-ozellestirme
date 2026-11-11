
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	CommonClientServer.SetDynamicListFilterItem(List, "PeripheralType", Parameters.PeripheralType, DataCompositionComparisonType.Equal,, ValueIsFilled(Parameters.PeripheralType));

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion
#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

