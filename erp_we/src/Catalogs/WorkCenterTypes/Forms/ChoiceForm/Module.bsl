#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	CommonClientServer.SetDynamicListFilterItem(List,
		"UseAvailabilityAccordingToSchedule",
		True,
		DataCompositionComparisonType.Equal,,
		LimitedAvailability);
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure LimitedAvailabilityOnChange(Item)
	CommonClientServer.SetDynamicListFilterItem(List,
		"UseAvailabilityAccordingToSchedule",
		True,
		DataCompositionComparisonType.Equal,,
		LimitedAvailability);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

