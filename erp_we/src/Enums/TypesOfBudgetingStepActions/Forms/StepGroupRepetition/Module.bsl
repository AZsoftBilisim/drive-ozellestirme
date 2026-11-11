
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Address = Parameters.Address;
	BudgetingModel = Parameters.BudgetingModel;
	
	ActionSettings = GetFromTempStorage(Address);
	Enums.TypesOfBudgetingStepActions.RestoreActionSettings(ActionSettings, ThisObject);
	
	OptionsParameters = New Structure("BudgetingModel", BudgetingModel);
	SetFormFunctionalOptionParameters(OptionsParameters);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ShouldSaveSettings(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	Close(SaveSettingsAtServer());
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function SaveSettingsAtServer()
	
	Settings = Enums.TypesOfBudgetingStepActions.ActionSettings(ThisObject);
	Return PutToTempStorage(Settings, Address);
	
EndFunction

#EndRegion
