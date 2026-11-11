
#Region FormCommandsEventHandlers

&AtClient
Procedure GoToInterface82AndRestart(Command)
	Close(DialogReturnCode.OK);
EndProcedure

&AtClient
Procedure ExitApplication(Command)
	Close(DialogReturnCode.Cancel);
EndProcedure

#EndRegion

