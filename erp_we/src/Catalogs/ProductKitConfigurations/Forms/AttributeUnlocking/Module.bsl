#Region Variables

&AtClient
Var IdleHandlerParameters;

&AtClient
Var TimeConsumingOperationForm;

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

#EndRegion
