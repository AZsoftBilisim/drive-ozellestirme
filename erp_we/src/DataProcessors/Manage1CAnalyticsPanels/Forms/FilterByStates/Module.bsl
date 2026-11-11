#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	StatusTable.Load(GetFromTempStorage(Parameters.AddressInTempStorage));
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Done(Command)
	Close(AddressInTempStorage());
EndProcedure

&AtClient
Procedure SelectAllCommand(Command)
	MarkTableElements(True);
EndProcedure

&AtClient
Procedure ClearAllIetmsCommand(Command)
	MarkTableElements(False);
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure MarkTableElements(Check) 
	For Each String In StatusTable Do
		String.Check = Check;
	EndDo;
EndProcedure

&AtServer
Function AddressInTempStorage()
	Return PutToTempStorage(StatusTable.Unload(), UUID)
EndFunction

#EndRegion
