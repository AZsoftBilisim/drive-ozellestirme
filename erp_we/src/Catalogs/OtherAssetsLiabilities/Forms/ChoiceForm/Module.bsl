
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	If Parameters.Property("Filter") And Parameters.Filter.Property("Owner") Then
		Owner = Parameters.Filter.Owner;
		Parameters.Filter.Delete("Owner");
		CommonClientServer.SetDynamicListFilterItem(
			List,
			"Owner",
			Owner,
			DataCompositionComparisonType.Equal,
			, // Presentation
			True); // Use
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

