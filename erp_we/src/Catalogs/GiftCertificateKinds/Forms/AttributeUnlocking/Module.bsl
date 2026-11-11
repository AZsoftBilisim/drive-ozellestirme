#Region Variables

&AtClient
Var IdleHandlerParameters;

&AtClient
Var TimeConsumingOperationForm;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion


#Region FormCommandsEventHandlers

&AtClient
Procedure EnableEdit(Command)

	Close(True);

EndProcedure

&AtClient
Procedure CheckObjectUsage(Command)
	
	ChangeLockOfTMObjectAttributesClient.CheckObjectUsage(ThisForm, IdleHandlerParameters);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion
