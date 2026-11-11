
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InitializeSettingsComposer(Parameters.AddressesOfDataCompositionSchema, Parameters.CustomSettingsAddress);
	
	AddressesOfDataCompositionSchema = Parameters.AddressesOfDataCompositionSchema;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CompleteEditing(Command)
	
	CustomSettingsAddress = PutToTempStorage(SettingsComposer.UserSettings);
	
	Close(CustomSettingsAddress);
	
EndProcedure

&AtClient
Procedure CustomizeStandardSettings(Command)
	
	SettingsComposer = Undefined;
	
	InitializeSettingsComposer(AddressesOfDataCompositionSchema);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer 
Procedure InitializeSettingsComposer(AddressesOfDataCompositionSchema, CustomSettingsAddress = Undefined)
	
	DCSAnalysisOptions = GetFromTempStorage(AddressesOfDataCompositionSchema.DataCompositionSchema);
	
	DCSAddress = PutToTempStorage(DCSAnalysisOptions, New UUID());
	AvailableSettingsSource = New DataCompositionAvailableSettingsSource(DCSAddress);
		
	SettingsComposer.Initialize(AvailableSettingsSource);
	
	If Not AddressesOfDataCompositionSchema.DataCompositionSettings = Undefined Then
		DataCompositionSettings = GetFromTempStorage(AddressesOfDataCompositionSchema.DataCompositionSettings);
		
		SettingsComposer.LoadSettings(DataCompositionSettings);
		
	Else
		SettingsComposer.LoadSettings(DCSAnalysisOptions.DefaultSettings);
		
	EndIf;
	
	If Not CustomSettingsAddress = Undefined Then
		DataCompositionUserSettings = GetFromTempStorage(CustomSettingsAddress);
	
		If Not DataCompositionUserSettings = Undefined Then
			SettingsComposer.LoadUserSettings(DataCompositionUserSettings);
		EndIf;
		
	Else 
		SettingsComposer.Refresh();
		
	EndIf;
	
EndProcedure

#EndRegion
