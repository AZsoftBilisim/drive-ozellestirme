
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	If Parameters.AddressOfDataCompositionSettings <> "" Then
		SettingsComposer.Initialize(
			New DataCompositionAvailableSettingsSource(Parameters.AddressOfDataCompositionSchema));
		
		UserSettings = GetFromTempStorage(Parameters.AddressOfDataCompositionSettings); // DataCompositionUserSettings - 
		
		Items.Filter_Settings.Visible				= False;
		Items.OrderSettings.Visible				= False;
		Items.ConditionalAppearanceSettings.Visible	= False;
		Items.SettingUpAGrouping.Visible			= False;
		
		For Each SettingItem In UserSettings.Items Do
			If TypeOf(SettingItem) = Type("DataCompositionFilter") Then
				SettingsComposer.Settings.Filter.UserSettingID =
					SettingItem.UserSettingID;
				Items.Filter_Settings.Visible				= True;
			ElsIf TypeOf(SettingItem) = Type("DataCompositionOrder") Then
				SettingsComposer.Settings.Order.UserSettingID =
					SettingItem.UserSettingID;
				Items.OrderSettings.Visible				= True;
			ElsIf TypeOf(SettingItem) = Type("DataCompositionConditionalAppearance") Then
				SettingsComposer.Settings.ConditionalAppearance.UserSettingID =
					SettingItem.UserSettingID;
				Items.ConditionalAppearanceSettings.Visible	= True;
			ElsIf TypeOf(SettingItem) = Type("DataCompositionSettingStructure") Then
				SettingsComposer.Settings.Structure.UserSettingID =
					SettingItem.UserSettingID;
				Items.SettingUpAGrouping.Visible			= True;
			EndIf;
			If Items.Structure.CurrentRow = Undefined Then
				Items.Structure.CurrentRow =
					SettingsComposer.UserSettings.GetIDByObject(SettingItem);
			EndIf;
		EndDo;
		
		SettingsComposer.LoadUserSettings(
			GetFromTempStorage(Parameters.AddressOfDataCompositionSettings));
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SettingsTypes1OnCurrentPageChange(Item, CurrentPage)
	If CurrentPage = Items.Filter_Settings Then
		RequiredType_ = Type("DataCompositionFilter");
	ElsIf CurrentPage = Items.OrderSettings Then
		RequiredType_ = Type("DataCompositionOrder");
	ElsIf CurrentPage = Items.ConditionalAppearanceSettings Then
		RequiredType_ = Type("DataCompositionConditionalAppearance");
	ElsIf CurrentPage = Items.SettingUpAGrouping Then
		RequiredType_ = Type("DataCompositionSettingStructure");
	EndIf;
	
	For Each SettingItem In SettingsComposer.UserSettings.Items Do
		If TypeOf(SettingItem) = RequiredType_ Then
			Items.Structure.CurrentRow =
				SettingsComposer.UserSettings.GetIDByObject(SettingItem);
		EndIf;
	EndDo;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Cancel(Command)
	Close();
EndProcedure

&AtClient
Procedure CompleteEditing(Command)
	//Close(Get the Builder's settings(the linker of the settings, the owner of the form.Unique identifier));
	Close(PutToTempStorage(SettingsComposer.UserSettings,
		FormOwner.UUID));
EndProcedure

#EndRegion