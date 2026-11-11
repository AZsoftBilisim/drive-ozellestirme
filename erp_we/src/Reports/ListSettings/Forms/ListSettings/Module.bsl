#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	SchemaURL = Parameters.SchemaURL;
	If ValueIsFilled(Parameters.Title) Then
		Title = Parameters.Title;
	EndIf;
	
	If ValueIsFilled(Parameters.TitleOfFinishEditingButton) Then
		Items.FormCompleteEditing.Title = Parameters.TitleOfFinishEditingButton;
	EndIf;
	
	Report.SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(SchemaURL));
	
	Report.SettingsComposer.LoadSettings(Parameters.ListSettings.GetSettings());
	Report.SettingsComposer.LoadUserSettings(Parameters.ListSettings.UserSettings);
	Report.SettingsComposer.Refresh();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure FinishEditingCommand(Command)
	
	Close(Report.SettingsComposer);
	
EndProcedure

#EndRegion
