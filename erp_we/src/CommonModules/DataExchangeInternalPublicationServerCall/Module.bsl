#Region Internal

Function SettingFlagShouldMutePromptToMigrateToWebService(SettingObject1, Value = Undefined) Export
	
	If TypeOf(SettingObject1) = Type("String") Then
		Var_Key = "ShouldMutePromptToMigrateToWebService" + SettingObject1;
	Else
		Var_Key = "ShouldMutePromptToMigrateToWebService" + SettingObject1.UUID();
	EndIf;
	
	If Value = Undefined Then
		// Read
		Return Common.CommonSettingsStorageLoad("ApplicationSettings", Var_Key, False,, UserName());
	EndIf;
	
	SettingsDescription = NStr("vi = 'Không đề xuất chuyển sang web-service';
								|ru = 'Не предлагать перейти на веб-сервис';
								|en = 'Do not offer to switch to a web service'; fa = 'Do not offer to switch to a web service';
								|it = 'Non chiedere di passare al servizio web';
								|pl = 'Nie proponuj przechodzić do serwisu webowego';
								|tr = 'Web servise geçmeyi önerme'");
	
	// Write
	Common.CommonSettingsStorageSave("ApplicationSettings", Var_Key, Value, SettingsDescription, UserName());
	
EndFunction

#EndRegion