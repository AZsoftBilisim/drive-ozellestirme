#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SearchString = Parameters.SearchString;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure FindExecute(Command)
	
	Close(SearchString);
	
EndProcedure

#EndRegion