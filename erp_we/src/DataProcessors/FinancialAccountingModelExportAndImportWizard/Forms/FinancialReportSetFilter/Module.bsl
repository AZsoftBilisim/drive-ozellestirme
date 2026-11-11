#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	TableOfSetsOfFinancialReports.Load(GetFromTempStorage(Parameters.AddressInTempStorage));
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Done(Command)
	Close(AddressInTemporaryStorageOfChartsOfAccounts());
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
	
	For Each String In TableOfSetsOfFinancialReports Do
		String.Check = Check;
	EndDo;
	
EndProcedure

&AtServer
Function AddressInTemporaryStorageOfChartsOfAccounts()
	Return PutToTempStorage(TableOfSetsOfFinancialReports.Unload(), UUID)
EndFunction

#EndRegion
