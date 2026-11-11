#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ReadOnly = Not Users.IsFullUser();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MinimizeRegisteredRecords(Command)
	
	MinimizeTrafficOnServer();
	
EndProcedure

&AtServer
Procedure MinimizeTrafficOnServer()
	
	OrderStructureInternal.RegisterConvolution();
	
	Items.List.Refresh();
	
EndProcedure

#EndRegion
