
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	ReadOnly = Not Users.IsFullUser();
EndProcedure
