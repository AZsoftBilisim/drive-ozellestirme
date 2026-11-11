#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Parameters.Property("Performer", Performer);
	Parameters.Property("CurrentUser", CurrentUser);
	
	Items.TaskExecutorTeam.Title =
		String(Performer);
	
	Items.CommandCurUser.Title = StrTemplate(
		NStr("vi = 'Tôi, %1';
			|ru = 'Я, %1';
			|en = 'Me, %1'; fa = 'Me, %1';
			|it = 'Il sottoscritto, %1';
			|pl = 'Ja, %1';
			|tr = 'Ben, %1'"),
		String(CurrentUser));
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure TaskExecutorTeam(Command)
	
	Close("taskPerformer");
	
EndProcedure

&AtClient
Procedure CommandCurUser(Command)
	
	Close("currentUser");
	
EndProcedure

#EndRegion