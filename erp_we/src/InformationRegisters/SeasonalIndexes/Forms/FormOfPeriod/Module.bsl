
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("CustomSettingsAddress") Then
		CustomSettingsAddress = Parameters.CustomSettingsAddress;
	EndIf;
	
	NumberOfYears = 2;
	EndDate = BegOfDay(CurrentSessionDate())-1;
	StartDate = EndDate - 86400 * 365 * NumberOfYears;
	
	DataCompositionSchema = InformationRegisters.SeasonalIndexes.GetTemplate("CalculationBySaleStatistics");
	
	AddressOfDataCompositionSchema = PutToTempStorage(DataCompositionSchema, UUID);
	
	SettingsSource = New DataCompositionAvailableSettingsSource(AddressOfDataCompositionSchema); 
	SettingsComposer.Initialize(SettingsSource);
	SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
	
	UserSettings = Undefined;
	If IsTempStorageURL(CustomSettingsAddress) Then
		UserSettings = GetFromTempStorage(CustomSettingsAddress);
	EndIf; 
	
	If UserSettings <> Undefined Then
		
		SettingsComposer.LoadUserSettings(UserSettings);
		SettingsComposer.Refresh();
		
	EndIf;
	
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure NumberOfYearsOnChange(Item)
	
	StartDate = EndDate - 86400 * 365 * NumberOfYears;
	
EndProcedure

&AtClient
Procedure EndDateOnChange(Item)
	
	StartDate = EndDate - 86400 * 365 * NumberOfYears;
	
EndProcedure

&AtClient
Procedure CalculationOptionOnChange(Item)
	
	DataCompositionClientServer.SetParameter(SettingsComposer, "CalculationOption", CalculationOption);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Calculate(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	CustomSettingsAddress = PutToTempStorage(SettingsComposer.UserSettings, 
		CustomSettingsAddress);
	
	Settings = New Structure;
	Settings.Insert("NumberOfYears",                 NumberOfYears);
	Settings.Insert("StartDate",                    StartDate);
	Settings.Insert("EndDate",                 EndDate);
	Settings.Insert("CalculationOption",                CalculationOption);
	
	Close(Settings);
	
EndProcedure

&AtClient
Procedure OpenFilter(Command)
	
	FormParameters = New Structure("SettingsComposer", SettingsComposer);
	OpenForm("InformationRegister.SeasonalIndexes.Form.FilterForm", FormParameters, ThisForm, UUID);
	
EndProcedure

#EndRegion
