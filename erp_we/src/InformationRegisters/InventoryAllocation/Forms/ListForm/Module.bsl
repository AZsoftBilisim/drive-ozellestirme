#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ReadOnly = Not Common.DebugMode();
	
EndProcedure

#EndRegion