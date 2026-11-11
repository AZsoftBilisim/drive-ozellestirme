
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If IsTempStorageURL(Parameters.SettingsAddress) Then
		LayoutSettingsVariable = GetFromTempStorage(Parameters.SettingsAddress);
		DeleteFromTempStorage(Parameters.SettingsAddress);
	Else
		LayoutSettingsVariable = Parameters.SettingsAddress;
	EndIf;
	
	If IsTempStorageURL(Parameters.NameAddressOfTheLayout) Then
		URLSchemes = Parameters.NameAddressOfTheLayout;
	Else
		DataCompositionSchema = TMCommonUse.TemplateByName(Parameters.NameAddressOfTheLayout);
		URLSchemes = PutToTempStorage(DataCompositionSchema, New UUID());
	EndIf;
	
	SettingsSource = New DataCompositionAvailableSettingsSource(URLSchemes);
	CompositionSettings.Initialize(SettingsSource);
	CompositionSettings.LoadSettings(LayoutSettingsVariable);
	CompositionSettings.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers
#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OKButton(Command)
	
	Close(PlaceProductSelectionSettingsToTemporaryStorage());
	
EndProcedure

&AtClient
Procedure CancelButton(Command)
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function PlaceProductSelectionSettingsToTemporaryStorage()
	LayoutSettingsVariable = CompositionSettings.GetSettings();
	Return PutToTempStorage(LayoutSettingsVariable);
EndFunction

#EndRegion





