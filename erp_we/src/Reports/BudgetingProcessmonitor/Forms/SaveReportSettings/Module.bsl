
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	If Parameters.Property("ObjectKey") Then
		ObjectKey = Parameters.ObjectKey;
	EndIf;
	If Parameters.Property("Settings") Then
		Settings = Parameters.Settings;
	EndIf;
	If Parameters.Property("CurrentSettingKey") Then
		CurrentSettingKey = Parameters.CurrentSettingKey;
	EndIf;	
	
	IBUser = IBUserName(Users.CurrentUser());
	
	ReFillSettingsList();
		
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SettingsKey = GenerateFreeDescription(CurrentSettingKey, SettingsList);
	Items.NextStepInfo.CurrentPage = Items.New;

EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure SettingsListOnActivateRow(Item)

	CurrentData = Items.SettingsList.CurrentData;
	If Not CurrentData = Undefined Then
		SettingsKey = CurrentData.Value;
		Items.NextStepInfo.CurrentPage = Items.OverwriteOption;
	EndIf;
	
EndProcedure

&AtClient
Procedure SettingsKeyOnChange(Item)
	
	If SettingsList.FindByValue(SettingsKey) = Undefined Then
		Items.NextStepInfo.CurrentPage = Items.New;
	Else
		Items.NextStepInfo.CurrentPage = Items.OverwriteOption;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SaveSetting(Command)
	
	Cancel = False;
	
	If Not ValueIsFilled(SettingsKey) Then
		CommonClientServer.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Tên"".';
				|ru = 'Поле ""Наименование"" не заполнено';
				|en = '""Description"" is not filled in'; fa = '""Description"" is not filled in';
				|it = 'Il campo ""Denominazione"" non è compilato';
				|pl = 'Pole ""Nazwa"" nie jest wypełnione';
				|tr = '""Tanım"" alanı doldurulmadı'"),
			,
			"ThisForm.SettingsKey");
		Cancel = True;
	EndIf;

	If Cancel Then
		Return;
	EndIf;
	
	SaveSettingOnServer(ObjectKey, SettingsKey, Settings);
	Close(SettingsKey);
	
EndProcedure

&AtClient
Procedure SettingsListDelete(Command)
	
	CurrentData = Items.SettingsList.CurrentData;
	Setting = CurrentData.Value;
	ListOfDeleteSettingsOnServer(ObjectKey, Setting);
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Function IBUserName(User)
	If Not ValueIsFilled(User) Then
		Return Undefined;
	EndIf;
	
	SetPrivilegedMode(True);
	
	FoundInformationSecurityUser = InfoBaseUsers.FindByUUID(
		Common.ObjectAttributeValue(User, "IBUserID"));
	If FoundInformationSecurityUser = Undefined Then
		Return Undefined;
	EndIf;
	
	Return FoundInformationSecurityUser.Name;
EndFunction

&AtServerNoContext
Procedure SaveSettingOnServer(ObjectKey, SettingsKey, Settings)
	
	Common.SystemSettingsStorageSave(ObjectKey, SettingsKey, Settings); 
	
EndProcedure

&AtServer
Procedure ListOfDeleteSettingsOnServer(ObjectKey, Setting)
	
	Common.SystemSettingsStorageDelete(ObjectKey, Setting, IBUser);	
	ReFillSettingsList();
	
EndProcedure

&AtServer
Procedure ReFillSettingsList()
	
	SettingsList = SystemSettingsStorage.GetList(ObjectKey);
	CurrentValue = SettingsList.FindByValue(CurrentSettingKey);
	If Not CurrentValue = Undefined Then
		IndexOf = SettingsList.IndexOf(CurrentValue);
		Items.SettingsList.CurrentRow = IndexOf;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function GenerateFreeDescription(SettingsKey, SettingsList)
	
	If SettingsList.Count() = 0 Then
		FreeDescription = NStr("vi = 'Chính';
								|ru = 'Основной';
								|en = 'Main'; fa = 'اصلی';
								|it = 'Principale';
								|pl = 'Podstawowej';
								|tr = 'Ana'");
		Return FreeDescription;
	EndIf;
	
	ConfigurationNameTemplate = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = '%1 - bản sao';
			|ru = '%1 - копия';
			|en = '%1 - copy'; fa = '%1 - copy';
			|it = '%1 - copia';
			|pl = '%1 - kopia';
			|tr = '%1 - kopya'"),
		SettingsKey);
	
	FreeDescription = ConfigurationNameTemplate;
	ValueFound = SettingsList.FindByValue(FreeDescription);
	If ValueFound = Undefined Then
		Return FreeDescription;
	EndIf;
	
	OptionNumber = 1;
	While True Do
		OptionNumber = OptionNumber + 1;
		FreeDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 (%2)';
				|ru = '%1 (%2)';
				|en = '%1 (%2)'; fa = '%1 (%2)';
				|it = '%1 (%2)';
				|pl = '%1 (%2)';
				|tr = '%1 (%2)'"),
			ConfigurationNameTemplate,
			Format(OptionNumber, ""));
		ValueFound = SettingsList.FindByValue(FreeDescription);
		If ValueFound = Undefined Then
			Return FreeDescription;
		EndIf;
	EndDo;
	
EndFunction

#EndRegion