#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	DataProcessors.CashForecast.InitializeSettingsComposer(LinkerSelection, UUID,
		Parameters.Filter_Settings);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetFilter(Command)
	
	Result = New Structure;
	Result.Insert("Filter_Settings", GetSelectionSettings());
	
	Close(Result);
	
EndProcedure

&AtClient
Procedure CancelInstallation(Command)
	
	Close();

EndProcedure

#EndRegion

#Region Private

&AtServer
Function GetSelectionSettings()
	
	Return LinkerSelection.GetSettings();
	
EndFunction

#EndRegion