#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
	
		Return;
	
	EndIf;
	
	CustomSettingsAddress = Parameters.CustomSettingsAddress;
	
	// Getting a data layout diagram
	Attributes = Common.ObjectAttributesValues(Parameters.Source, 
		"DCSTemplateName, DataCompositionSchema, StorageOfDataCompositionSettings");
	If ValueIsFilled(Attributes.DCSTemplateName) Then
		DataCompositionSchema = Catalogs.PlanningDataSources.LayoutSchemeByTemplateName(Attributes.DCSTemplateName);
		If DataCompositionSchema = Undefined Then
			DataCompositionSchema = Attributes.DataCompositionSchema.Get();
		EndIf; 
	Else
		DataCompositionSchema = Attributes.DataCompositionSchema.Get();
	EndIf;
	
	// Initializing the Settings Linker
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(PutToTempStorage(DataCompositionSchema, UUID)));
	
	Try
		DataCompositionSettings = Attributes.StorageOfDataCompositionSettings.Get();
	Except
		Common.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trong nguồn điền dữ liệu ""%1"" có lỗi trong tùy chỉnh. Đã đặt tùy chỉnh mặc định.';
				|ru = 'В источнике заполнения данных ""%1"" имеются ошибки в настройках. Установлены настройки по умолчанию.';
				|en = 'There are errors in the settings in the ""%1"" data filling source. The default settings are set.'; fa = 'There are errors in the settings in the ""%1"" data filling source. The default settings are set.';
				|it = 'Nell''origine di compilazione dati ""%1"" sono presenti errori di impostazione. Sono selezionate le impostazioni predefinite.';
				|pl = 'Źródło wypełnienia danych ""%1"" zawiera błędy w ustawieniach. Ustawione są ustawienia domyślne.';
				|tr = 'Kaynakta ""%1"" verisinin doldurulması esnasında ayarlarda hatalar meydana geldi. Ayarlar varsayılana göre ayarlandı.'"), Parameters.Source));
		ThisForm.Modified = True;
	EndTry;

	If DataCompositionSettings <> Undefined Then
		SettingsComposer.LoadSettings(DataCompositionSettings);
	Else
		SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
	EndIf;
	SettingsComposer.Refresh();
	
	// Getting User settings
	UserSettings = GetFromTempStorage(CustomSettingsAddress);
	
	// Loading user Settings
	If UserSettings <> Undefined Then
		
		SettingsComposer.LoadUserSettings(UserSettings);
		
	EndIf;
	
	If Parameters.Property("FilterPlan_") Then
		Catalogs.PlanningDataSources.SetSelectionsBasedOnPlanAttributes(SettingsComposer, Parameters.FilterPlan_);
	EndIf;
	
	ChangeResultTo = Parameters.ChangeResultTo;
	ParameterChangeToSeasonalFactor = DataCompositionClientServer.GetParameter(SettingsComposer,
		"ChangeToTheSeasonalIndex");
	
	ProductsField = New DataCompositionField("Products");
	ThereIsFieldProducts = False;
	GroupingFields = PlanningClientServer.GetDimensionFields(SettingsComposer);
	For Each Field In GroupingFields Do
	
		If Field.Use And Field.Field = ProductsField Then
		
			ThereIsFieldProducts = True;
			Break;
		
		EndIf; 
	
	EndDo;
	If Not ThereIsFieldProducts Then
	
		SelectionFields = PlanningClientServer.GetSelectionFields(SettingsComposer);
		For Each Field In SelectionFields Do
			
			If Field.Use And Field.Field = ProductsField Then
				
				ThereIsFieldProducts = True;
				Break;
				
			EndIf; 
			
		EndDo;
	
	EndIf; 
	
	UseSeasonalIndexes = ThereIsFieldProducts
		And ParameterChangeToSeasonalFactor <> Undefined 
		And GetFunctionalOption("UseSeasonalIndexes");
	
	Items.GroupSeasonalCoefficients.Visible = UseSeasonalIndexes;
	If Not UseSeasonalIndexes
		And ParameterChangeToSeasonalFactor <> Undefined Then
		
		DeleteParameter = DataCompositionClientServer.GetParameter(SettingsComposer.Settings,
			"ChangeToTheSeasonalIndex");
		DeleteParameter.UserSettingID = "";
		ParameterChangeToSeasonalFactor = Undefined;
	
	EndIf; 
	
	If UseSeasonalIndexes And Not AccessRight("View", Metadata.InformationRegisters.SeasonalIndexes) Then
		Items.OpenAndSetUpSeasonalIndexes.Visible = False;
	EndIf; 
	
	If Not ThereIsFieldProducts And ParameterChangeToSeasonalFactor <> Undefined Then
	
		ParameterChangeToSeasonalFactor.Use = False;
	
	EndIf; 
	
	If ParameterChangeToSeasonalFactor <> Undefined Then
	
		ChangeToTheSeasonalIndex = (ParameterChangeToSeasonalFactor.Use
			And ParameterChangeToSeasonalFactor.Value = True);
	
	EndIf; 
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSettingsComposerUserSettings

&AtClient
Procedure SettingsComposerUserSettingsOnChange(Item)
	
	Parameter = DataCompositionClientServer.GetParameter(SettingsComposer, "ChangeToTheSeasonalIndex");
	
	If Parameter.UserSettingID = String(Item.CurrentRow) Then
		ChangeToTheSeasonalIndex = Item.CurrentData.Value;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CompleteEditing(Command)
	
	PutToTempStorage(SettingsComposer.UserSettings, CustomSettingsAddress);
	
	SettingsComposer.LoadSettings(ApplyCustomSettings(SettingsComposer));
	
	SettingsComposer.Settings.Structure.UserSettingID = "";
	
	PopulationFields = PlanningClientServer.GetTextOfSelectedLayoutFields(SettingsComposer);
	
	Close(New Structure("ChangeResultTo, PopulationFields", ChangeResultTo, PopulationFields));
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

&AtClient
Procedure OpenAndSetUpSeasonalIndexesClick(Item)
	
	OpenForm("InformationRegister.SeasonalIndexes.Form.SeasonalIndexes"); 
	
EndProcedure

&AtClient
Procedure ChangeTheSeasonalCoefficientOnChange(Item)
	
	ParameterChangeToSeasonalFactor = DataCompositionClientServer.GetParameter(SettingsComposer,
		"ChangeToTheSeasonalIndex");
		
	If ParameterChangeToSeasonalFactor <> Undefined Then
	
		ParameterChangeToSeasonalFactor.Use = True;
		ParameterChangeToSeasonalFactor.Value = ChangeToTheSeasonalIndex;
	
	EndIf; 
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#Region Private

&AtServerNoContext
Function ApplyCustomSettings(SettingsComposer)
	Return SettingsComposer.GetSettings();
EndFunction

#EndRegion

#EndRegion
