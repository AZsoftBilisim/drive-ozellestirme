
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Documents.ARAPReconciliation2_4.InitializeSettingsComposer(LinkerSelection, UUID, Parameters.Filter_Settings);
	
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