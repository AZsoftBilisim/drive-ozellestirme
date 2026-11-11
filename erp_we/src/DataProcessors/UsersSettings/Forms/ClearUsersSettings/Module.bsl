///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	UseExternalUsers = GetFunctionalOption("UseExternalUsers");
	SelectedUsers.Add(Users.CurrentUser());
	UpdateUsersSelectionRef(ThisObject);
	
	UsersToClearSettingsRadioButtons = "SelectedUsers1";
	SettingsToClearRadioButton   = "ClearAll";
	ClearSettingsSelectionHistory     = True;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If Upper(EventName) = Upper("UserSelection") Then
		If Source <> FormName Then
			Return;
		EndIf;
		
		SelectedUsers.LoadValues(Parameter.UsersDestination);
		UpdateUsersSelectionRef(ThisObject);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UsersToClearSettingsRadioButtonsOnChange(Item)
	
	If UsersToClearSettingsRadioButtons = "SelectedUsers1"
		And UsersCount = 0 Then
		Items.SettingsToClearGroup.Enabled = False;
	Else
		Items.SettingsToClearGroup.Enabled = True;
		SettingsToClearRadioButtonOnChange(Items.SettingsToClearRadioButton);
	EndIf;
	
EndProcedure

&AtClient
Procedure SettingsToClearRadioButtonOnChange(Item)
	
	If SettingsToClearRadioButton = "SelectedSettings2" Then
		If UsersToClearSettingsRadioButtons <> "SelectedUsers1"
		 Or UsersCount <> 1 Then
			SettingsToClearRadioButton = "ClearAll";
			Items.SelectSettings.Enabled = False;
			ShowMessageBox(,NStr("vi = 'Xóa tùy chỉnh riêng chỉ sử dụng được khi chọn một người sử dụng.';
								|ru = 'Очистка отдельных настроек доступна только при выборе одного пользователя.';
								|en = 'To clear individual settings, select one user.'; fa = 'To clear individual settings, select one user.';
								|it = 'La cancellazione delle singole impostazioni è disponibile solo quando viene selezionato un singolo utente.';
								|pl = 'Czyszczenie poszczególnych ustawień jest dostępne tylko po wybraniu jednego użytkownika.';
								|tr = 'Ayrı ayarların temizlenmesi sadece bir kullanıcı seçildiğinde kullanılabilir.'"));
		Else
			Items.SelectSettings.Enabled = True;
		EndIf;
	Else
		Items.SelectSettings.Enabled = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectUsersClick(Item)
	
	If UseExternalUsers Then
		UsersTypeSelection = New ValueList;
		UsersTypeSelection.Add("ExternalUsers", NStr("vi = 'Người dùng ngoài';
													|ru = 'Внешние пользователи';
													|en = 'External users'; fa = 'کاربران خارجی';
													|it = 'Utenti esterni';
													|pl = 'Użytkownicy zewnętrzni';
													|tr = 'Harici kullanıcılar'"));
		UsersTypeSelection.Add("Users",        NStr("vi = 'Người sử dụng';
													|ru = 'Пользователи';
													|en = 'Users'; fa = 'کاربران';
													|it = 'Utenti';
													|pl = 'Users';
													|tr = 'Kullanıcılar'"));
		
		Notification = New CallbackDescription("SelectUsersClickSelectItem", ThisObject);
		UsersTypeSelection.ShowChooseItem(Notification);
		Return;
	EndIf;
	
	OpenUserSelectionForm(PredefinedValue("Catalog.Users.EmptyRef"));
	
EndProcedure

&AtClient
Procedure SelectSettings(Item)
	
	If UsersCount = 1 Then
		UserRef = SelectedUsers[0].Value;
		FormParameters = New Structure("User, SettingsOperation, ClearSettingsSelectionHistory",
			UserRef, "Clearing", ClearSettingsSelectionHistory);
		OpenForm("DataProcessor.UsersSettings.Form.SettingsChoice", FormParameters, ThisObject,,,,
			New CallbackDescription("SelectSettingsAfterChoice", ThisObject));
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Clear(Command)
	
	ClearMessages();
	SettingsClearing();
	
EndProcedure

&AtClient
Procedure ClearAndClose(Command)
	
	ClearMessages();
	SettingsCleared = SettingsClearing();
	If SettingsCleared Then
		CommonClient.RefreshApplicationInterface();
		Close();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure UpdateUsersSelectionRef(Form)
	Form.UsersCount = Form.SelectedUsers.Count();
	If Form.UsersCount = 0 Then
		Form.Items.SelectSettings.Title = NStr("vi = 'Chọn';
												|ru = 'Выбрать';
												|en = 'Select'; fa = 'انتخاب';
												|it = 'Выбрать';
												|pl = 'Select';
												|tr = 'Seç'");
		Form.SelectedSettings = Undefined;
		Form.SettingsCount = Undefined;
	ElsIf Form.UsersCount = 1 Then
		Form.Items.SelectUsers.Title = String(Form.SelectedUsers[0].Value);
		Form.Items.SettingsToClearGroup.Enabled = True;
	Else
		NumberAndSubject = Format(Form.UsersCount, "NFD=0") + " "
			+ UsersInternalClientServer.IntegerSubject(Form.UsersCount,
				"", NStr("vi = 'người sử dụng,người sử dụng,người sử dụng,,,,,,0';
						|ru = 'пользователь,пользователя,пользователей,,,,,,0';
						|en = 'user, users,,,0'; fa = 'user, users,,,0';
						|it = 'пользователь,пользователя,пользователей,,,,,,0';
						|pl = 'user, users,,,0';
						|tr = 'kullanıcı, kullanıcılar, kullanıcılar,,,,,,0'"));
		Form.Items.SelectUsers.Title = NumberAndSubject;
		Form.SettingsToClearRadioButton = "ClearAll";
	EndIf;
EndProcedure
	
&AtClient
Procedure SelectUsersClickSelectItem(SelectedOption, AdditionalParameters) Export
	
	If SelectedOption = Undefined Then
		Return;
	EndIf;
	
	If SelectedOption.Value = "Users" Then
		User = PredefinedValue("Catalog.Users.EmptyRef");
		
	ElsIf SelectedOption.Value = "ExternalUsers" Then
		User = PredefinedValue("Catalog.ExternalUsers.EmptyRef");
	EndIf;
	
	OpenUserSelectionForm(User);
	
EndProcedure

&AtClient
Procedure OpenUserSelectionForm(User)
	
	FormParameters = New Structure;
	FormParameters.Insert("User",          User);
	FormParameters.Insert("ActionType",           "Clearing");
	FormParameters.Insert("SelectedUsers", SelectedUsers.UnloadValues());
	FormParameters.Insert("Source", FormName);
	
	OpenForm("DataProcessor.UsersSettings.Form.SelectUsers", FormParameters);
	
EndProcedure

&AtClient
Procedure SelectSettingsAfterChoice(Parameter, Context) Export
	
	If TypeOf(Parameter) <> Type("Structure") Then
		Return;
	EndIf;
	
	SelectedSettings = New Structure;
	SelectedSettings.Insert("Interface",       Parameter.Interface);
	SelectedSettings.Insert("ReportsSettings", Parameter.ReportsSettings);
	SelectedSettings.Insert("OtherSettings",  Parameter.OtherSettings);
	
	SelectedSettings.Insert("ReportOptionTable",  Parameter.ReportOptionTable);
	SelectedSettings.Insert("SelectedReportsOptions", Parameter.SelectedReportsOptions);
	
	SelectedSettings.Insert("PersonalSettings",           Parameter.PersonalSettings);
	SelectedSettings.Insert("OtherUserSettings", Parameter.OtherUserSettings);
	
	SettingsCount = Parameter.SettingsCount;
	
	If SettingsCount = 0 Then
		TitleText = NStr("vi = 'Chọn';
						|ru = 'Выбрать';
						|en = 'Select'; fa = 'انتخاب';
						|it = 'Selezionare';
						|pl = 'Wybierz';
						|tr = 'Seç'");
	ElsIf SettingsCount = 1 Then
		SettingPresentation = Parameter.SettingsPresentations[0];
		TitleText = SettingPresentation;
	Else
		TitleText = Format(SettingsCount, "NFD=0") + " "
			+ UsersInternalClientServer.IntegerSubject(SettingsCount,
				"", NStr("vi = 'tùy chỉnh,tùy chỉnh,tùy chỉnh,,,,,,0';
						|ru = 'настройка,настройки,настроек,,,,,,0';
						|en = 'setting,settings,,,0'; fa = 'setting,settings,,,0';
						|it = 'impostazione,impostazioni,delle impostazioni,,,,,,0';
						|pl = 'ustawienie,ustawienia,ustawień,,,,,,0';
						|tr = 'ayar, ayarlar, ayarlar,,,,,,0'"));
	EndIf;
	
	Items.SelectSettings.Title = TitleText;
	Items.SelectSettings.ToolTip = "";
	
EndProcedure

&AtClient
Function SettingsClearing()
	
	If UsersToClearSettingsRadioButtons = "SelectedUsers1"
		And UsersCount = 0 Then
		CommonClient.MessageToUser(
			NStr("vi = 'Chọn người dùng hoặc những người dùng
				|muốn xóa cài đặt.';
				|ru = 'Выберите пользователя или пользователей,
				|которым необходимо очистить настройки.';
				|en = 'Select the users whose
				|settings you want to clear.'; fa = 'Select the users whose
				|settings you want to clear.';
				|it = 'Selezionare l''utente o utenti,
				|per i quali è necessario cancellare le impostazioni.';
				|pl = 'Wybierz użytkownika lub użytkowników,
				|ustawienia których należy usunąć.';
				|tr = 'Ayarları temizlemek için 
				|gerekli olan kullanıcıyı veya kullanıcıları seçin.'"), , "Source");
		Return False;
	EndIf;
	
	If UsersToClearSettingsRadioButtons = "SelectedUsers1" Then
			
		If UsersCount = 1 Then
			SettingsClearedForNote = NStr("vi = 'người sử dụng ""%1""';
											|ru = 'пользователя ""%1""';
											|en = 'user ""%1""'; fa = 'user ""%1""';
											|it = 'dell''utente ""%1""';
											|pl = 'użytkownika ""%1""';
											|tr = 'kullanıcı ""%1""'");
			SettingsClearedForNote = StringFunctionsClientServer.SubstituteParametersToString(
				SettingsClearedForNote, SelectedUsers[0].Value);
		Else
			SettingsClearedForNote = NStr("vi = '%1 cho người dùng';
											|ru = '%1 пользователям';
											|en = '%1 users'; fa = '%1 users';
											|it = '%1 per gli utenti';
											|pl = '%1 użytkownikom';
											|tr = '%1 kullanıcılar'");
			SettingsClearedForNote = StringFunctionsClientServer.SubstituteParametersToString(SettingsClearedForNote, UsersCount);
		EndIf;
		
	Else
		SettingsClearedForNote = NStr("vi = 'cho tất cả người sử dụng';
										|ru = 'всем пользователям';
										|en = 'all users'; fa = 'all users';
										|it = 'per tutti gli utenti';
										|pl = 'do wszystkich użytkowników';
										|tr = 'tüm kullanıcılara'");
	EndIf;
	
	If SettingsToClearRadioButton = "SelectedSettings2"
		And SettingsCount = 0 Then
		CommonClient.MessageToUser(
			NStr("vi = 'Hãy chọn tùy chỉnh cần xóa';
				|ru = 'Выберите настройки, которые необходимо очистить.';
				|en = 'Select the settings that you want to clear.'; fa = 'Select the settings that you want to clear.';
				|it = 'Selezionare le impostazioni da cancellare.';
				|pl = 'Wybierz ustawienia, które chcesz wyczyścić.';
				|tr = 'Temizlenecek ayarları seçin.'"), , "SettingsToClearRadioButton");
		Return False;
	EndIf;
	
	If SettingsToClearRadioButton = "SelectedSettings2" Then
		ClearSelectedSettings();
		
		If SettingsCount = 1 Then
			
			If StrLen(SettingPresentation) > 24 Then
				SettingPresentation = Left(SettingPresentation, 24) + "...";
			EndIf;
			
			ExplanationText = NStr("vi = '""%1"" đã xóa bởi %2';
									|ru = '""%1"" очищена у %2';
									|en = '""%1"" cleared for %2'; fa = '""%1"" cleared for %2';
									|it = '""%1"" cancellata da %2';
									|pl = '""%1"" wyczyszczona u %2';
									|tr = '""%1"" %2 için temizlendi'");
			ExplanationText = StringFunctionsClientServer.SubstituteParametersToString(ExplanationText, SettingPresentation, SettingsClearedForNote);
			
		Else
			SubjectInWords = Format(SettingsCount, "NFD=0") + " "
				+ UsersInternalClientServer.IntegerSubject(SettingsCount,
					"", NStr("vi = 'tùy chỉnh,tùy chỉnh,tùy chỉnh,,,,,,0';
							|ru = 'настройка,настройки,настроек,,,,,,0';
							|en = 'setting,settings,,,0'; fa = 'setting,settings,,,0';
							|it = 'impostazione,impostazioni,delle impostazioni,,,,,,0';
							|pl = 'ustawienie,ustawienia,ustawień,,,,,,0';
							|tr = 'ayar, ayarlar, ayarlar,,,,,,0'"));
			
			ExplanationText = NStr("vi = 'Xóa %1 của %2';
									|ru = 'Очищено %1 у %2';
									|en = '%1 cleared for %2'; fa = '%1 cleared for %2';
									|it = 'Cancellate %1 per %2';
									|pl = 'Usunięto %1 w %2';
									|tr = '%1, %2 için temizlendi'");
			ExplanationText = StringFunctionsClientServer.SubstituteParametersToString(ExplanationText, SubjectInWords, SettingsClearedForNote);
		EndIf;
		
		ShowUserNotification(NStr("vi = 'Xóa tùy chỉnh';
									|ru = 'Очистка настроек';
									|en = 'Clear settings'; fa = 'پاک کردن تنظیمات';
									|it = 'Cancellazione delle impostazioni';
									|pl = 'Oczyszczenie ustawień';
									|tr = 'Temizleme ayarları'"), , ExplanationText, PictureLib.DialogInformation);
		
	ElsIf SettingsToClearRadioButton = "ClearAll" Then
		ClearAllSettings();
		
		ExplanationText = NStr("vi = 'Xóa tất cả tùy chỉnh %1';
								|ru = 'Очищены все настройки %1';
								|en = 'All settings are cleared for %1'; fa = 'All settings are cleared for %1';
								|it = 'Cancellate tutte le impostazioni %1';
								|pl = 'Usunięto wszystkie ustawienia %1';
								|tr = 'Tüm ayarlar %1 temizlendi'");
		ExplanationText = StringFunctionsClientServer.SubstituteParametersToString(ExplanationText, SettingsClearedForNote);
		ShowUserNotification(NStr("vi = 'Xóa tùy chỉnh';
									|ru = 'Очистка настроек';
									|en = 'Clear settings'; fa = 'پاک کردن تنظیمات';
									|it = 'Cancellazione delle impostazioni';
									|pl = 'Oczyszczenie ustawień';
									|tr = 'Temizleme ayarları'"), , ExplanationText, PictureLib.DialogInformation);
		
	ElsIf SettingsToClearRadioButton = "ObsoleteSettings" Then
		ClearObsoleteSettings();
		
		ExplanationText = NStr("vi = 'Đã xóa các tùy chỉnh cũ %1';
								|ru = 'Очищены устаревшие настройки %1';
								|en = 'Obsolete settings %1 are cleared'; fa = 'Obsolete settings %1 are cleared';
								|it = 'Sono state inserite le impostazioni obsolete %1';
								|pl = 'Wyczyszczono przestarzałe ustawienia %1';
								|tr = 'Eski ayarlar temizlendi%1'");
		ExplanationText = StringFunctionsClientServer.SubstituteParametersToString(ExplanationText, SettingsClearedForNote);
		ShowUserNotification(NStr("vi = 'Xóa tùy chỉnh';
									|ru = 'Очистка настроек';
									|en = 'Clear settings'; fa = 'پاک کردن تنظیمات';
									|it = 'Cancellazione delle impostazioni';
									|pl = 'Oczyszczenie ustawień';
									|tr = 'Temizleme ayarları'"), , ExplanationText, PictureLib.DialogInformation);
	EndIf;
	
	SettingsCount = 0;
	Items.SelectSettings.Title = NStr("vi = 'Chọn';
										|ru = 'Выбрать';
										|en = 'Select'; fa = 'انتخاب';
										|it = 'Selezionare';
										|pl = 'Select';
										|tr = 'Seç'");
	Return True;
	
EndFunction

&AtServer
Procedure ClearSelectedSettings()
	
	Source = SelectedUsers[0].Value;
	User = DataProcessors.UsersSettings.IBUserName(Source);
	UserInfo = New Structure;
	UserInfo.Insert("UserRef", Source);
	UserInfo.Insert("InfoBaseUserName", User);
	
	If SelectedSettings.ReportsSettings.Count() > 0 Then
		DataProcessors.UsersSettings.DeleteSelectedSettings(
			UserInfo, SelectedSettings.ReportsSettings, "ReportsUserSettingsStorage");
		
		DataProcessors.UsersSettings.DeleteReportOptions(
			SelectedSettings.SelectedReportsOptions, SelectedSettings.ReportOptionTable, User);
	EndIf;
	
	If SelectedSettings.Interface.Count() > 0 Then
		DataProcessors.UsersSettings.DeleteSelectedSettings(
			UserInfo, SelectedSettings.Interface, "SystemSettingsStorage");
	EndIf;
	
	If SelectedSettings.OtherSettings.Count() > 0 Then
		DataProcessors.UsersSettings.DeleteSelectedSettings(
			UserInfo, SelectedSettings.OtherSettings, "SystemSettingsStorage");
	EndIf;
	
	If SelectedSettings.PersonalSettings.Count() > 0 Then
		DataProcessors.UsersSettings.DeleteSelectedSettings(
			UserInfo, SelectedSettings.PersonalSettings, "CommonSettingsStorage");
	EndIf;
	
	For Each OtherUserSettings In SelectedSettings.OtherUserSettings Do
		UsersInternal.OnDeleteOtherUserSettings(
			UserInfo, OtherUserSettings);
	EndDo;
	
EndProcedure

&AtServer
Procedure ClearAllSettings()
	
	SettingsArray = New Array;
	SettingsArray.Add("ReportsSettings");
	SettingsArray.Add("InterfaceSettings2");
	SettingsArray.Add("PersonalSettings");
	SettingsArray.Add("FormData");
	SettingsArray.Add("Favorites");
	SettingsArray.Add("PrintSettings");
	SettingsArray.Add("OtherUserSettings");
	
	If UsersToClearSettingsRadioButtons = "SelectedUsers1" Then
		Sources = SelectedUsers.UnloadValues();
	Else
		Sources = New Array;
		UsersTable = New ValueTable;
		UsersTable.Columns.Add("User");
		UsersTable.Columns.Add("Department");
		UsersTable.Columns.Add("Individual");

		UsersTable = DataProcessors.UsersSettings.UsersToCopy("", UsersTable, False, True);
		For Each TableRow In UsersTable Do
			Sources.Add(TableRow.User);
		EndDo;
		
	EndIf;
	
	DataProcessors.UsersSettings.DeleteUserSettings(SettingsArray, Sources,, True);
	
EndProcedure

&AtServer
Procedure ClearObsoleteSettings()
	
	Sources = ?(UsersToClearSettingsRadioButtons = "SelectedUsers1", 
		SelectedUsers.UnloadValues(), Undefined);
	DataProcessors.UsersSettings.DeleteOutdatedUserSettings(Sources);
	
EndProcedure

#EndRegion
