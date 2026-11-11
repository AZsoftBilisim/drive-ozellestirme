#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	SettingsMode = Object.SettingsMode;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	NodeFormName = "";
	
	If SettingsMode = "WebShowcase" Then
		NodeFormName= "WebShowcaseForm";
	Else
		NodeFormName = "SynchronizationForm";
	EndIf;
	
	ParametersOfFormToOpen = New Structure();
	ParametersOfFormToOpen.Insert("FillingValues", New Structure());
	ParametersOfFormToOpen.FillingValues.Insert("Object", Object.Ref);
	ParametersOfFormToOpen.Insert("Key", Object.Ref);
	
	OpenForm("ExchangePlan.DataSynchronizationViaUniversalFormat.Form." + NodeFormName, ParametersOfFormToOpen, FormOwner, Object.Ref,,, CallbackDescriptionOnClose, FormWindowOpeningMode.Independent);
	Cancel = True;
	
EndProcedure

#EndRegion
