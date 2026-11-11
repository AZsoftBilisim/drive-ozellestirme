
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	InitializeTheForm();
	InitializeSettingsComposer();
	SetDefaultSelections();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure DefaultSettings(Command)
	DefaultSettingsAtServer();
EndProcedure

&AtClient
Procedure CompleteEditing(Command)
	Close(GetSettings());
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure InitializeTheForm()
	
	ParametersAddress = Parameters.ParametersAddress;

	If Parameters.Property("FormCaption") Then
		AutoTitle = False;
		Title = Parameters.FormCaption;
	EndIf;
	
	If Parameters.Property("TitleFinishEditing") Then
		Items.FormCompleteEditing.Title = Parameters.TitleFinishEditing;
	EndIf;
	
	If Parameters.Property("Filter") Then
		For Each KeyAndValue In Parameters.Filter Do
			RowData = FilterDefault.Add();
			RowData.FieldName = KeyAndValue.Key;
			If TypeOf(KeyAndValue.Value) = Type("Structure") Then
				RowData.Value = KeyAndValue.Value.Value;
				RowData.ComparisonType = KeyAndValue.Value.ComparisonType;
			Else
				RowData.Value = KeyAndValue.Value;
				RowData.ComparisonType = DataCompositionComparisonType.Equal;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Procedure InitializeSettingsComposer()
	
	SetupParameters = GetFromTempStorage(ParametersAddress);
	
	DataCompositionSchema = SetupParameters.DataCompositionSchema;
	
	DCSAddress = PutToTempStorage(DataCompositionSchema, UUID);
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(DCSAddress));
	
	If SetupParameters.Property("Settings")
		And ValueIsFilled(SetupParameters.Settings) Then
		SettingsComposer.LoadSettings(SetupParameters.Settings);
	Else	
		SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
	EndIf;
	
	SettingsComposer.Refresh();

EndProcedure

&AtServer
Procedure DefaultSettingsAtServer()
	
	SetupParameters = GetFromTempStorage(ParametersAddress);
	DataCompositionSchema = SetupParameters.DataCompositionSchema;
	SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
	
	SetDefaultSelections();
	
EndProcedure

&AtServer
Procedure SetDefaultSelections()
	
	For Each RowData In FilterDefault Do
		
		FilterElement = DataCompositionClientServer.AddFilter(
			SettingsComposer, 
			RowData.FieldName, 
			RowData.Value,
			RowData.ComparisonType,,);
		
		RowData.Id = FilterElement.UserSettingID;
		
	EndDo;
	
EndProcedure

&AtServer
Function GetSettings()
	Return SettingsComposer.GetSettings();
EndFunction

#EndRegion
