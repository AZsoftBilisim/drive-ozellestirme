
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	AllowEditingTheUseOfARoutineTask = True;
	AllowEditingOfTheSKDSettings                      = True;
	AllowEditingOfTheSchedule                        = True;
	AllowEditingFormationMethod                = True;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EnableEdit(Command)
	
	Result = New Array;
	If AllowEditingTheUseOfARoutineTask Then
		Result.Add("ScheduledJobUsed");
	EndIf;
	
	If AllowEditingOfTheSKDSettings Then
		Result.Add("PresentationOfTheSKDTemplate");
	EndIf;
	
	If AllowEditingOfTheSchedule Then
		Result.Add("Schedule");
	EndIf;
	
	If AllowEditingFormationMethod Then
		Result.Add("GenerationMethod");
	EndIf;
	
	Close(Result);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion
