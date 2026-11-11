
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	TaxContributionKindsLocalization.ChoiceFormOnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectFromFullList(Command)
	ChooseFromFullListOnServer();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ChooseFromFullListOnServer()
	
	CommonClientServer.SetFormItemProperty(
		Items,
		"FormSelectFromFullList",
		"Visible",
		False);
		
	DisableSettingsItems(List.SettingsComposer.Settings.Filter.Items);
	DisableSettingsItems(List.SettingsComposer.FixedSettings.Filter.Items);
	DisableSettingsItems(List.SettingsComposer.UserSettings.Items);
	
EndProcedure

&AtServer
Procedure DisableSettingsItems(ItemsCollection)
	
	For Each SettingsItem In ItemsCollection Do
		
		If TypeOf(SettingsItem) = Type("DataCompositionFilterItem")
			Or TypeOf(SettingsItem) = Type("DataCompositionFilterItemGroup") Then
			
			SettingsItem.Use = False;
		ElsIf TypeOf(SettingsItem) = Type("DataCompositionFilterItemCollection") Then
			DisableSettingsItems(SettingsItem.Items)
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion