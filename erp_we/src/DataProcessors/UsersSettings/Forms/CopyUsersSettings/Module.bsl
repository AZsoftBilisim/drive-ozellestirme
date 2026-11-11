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
	CopySettingsToRadioButtons = "SelectedUsers1";
	SettingsToCopyRadioButton = "CopyAllSettings";
	FormOpeningMode = Parameters.FormOpeningMode;
	
	SettingsRecipientsUsers = New Structure;
	If Parameters.User <> Undefined Then
		UsersArray = New Array;
		UsersArray.Add(Parameters.User);
		SettingsRecipientsUsers.Insert("UsersArray", UsersArray);
		Items.SelectUsers.Title = String(Parameters.User);
		UsersCount = 1;
		PassedUserType = TypeOf(Parameters.User);
		Items.CopyToGroup.Enabled = False;
	Else
		UserRef = Users.CurrentUser();
	EndIf;
	
	If UserRef = Undefined Then
		Items.SettingsToCopyGroup.Enabled = False;
	EndIf;
	
	ClearSettingsSelectionHistory = True;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If Upper(EventName) = Upper("UserSelection") Then
		If Source <> FormName Then
			Return;
		EndIf;
		
		SettingsRecipientsUsers = New Structure("UsersArray", Parameter.UsersDestination);
		
		UsersCount = Parameter.UsersDestination.Count();
		If UsersCount = 1 Then
			Items.SelectUsers.Title = String(Parameter.UsersDestination[0]);
		ElsIf UsersCount > 1 Then
			NumberAndSubject = Format(UsersCount, "NFD=0") + " "
				+ UsersInternalClientServer.IntegerSubject(UsersCount,
					"", NStr("vi = 'người sử dụng,người sử dụng,người sử dụng,,,,,,0';
							|ru = 'пользователь,пользователя,пользователей,,,,,,0';
							|en = 'user, users,,,0'; fa = 'user, users,,,0';
							|it = 'utente,dell''utente,degli utenti,,,,,,0';
							|pl = 'użytkownik,użytkownika,użytkowników,,,,,,0';
							|tr = 'kullanıcı, kullanıcılar, kullanıcılar,,,,,,0'"));
			Items.SelectUsers.Title = NumberAndSubject;
		EndIf;
		Items.SelectUsers.ToolTip = "";
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UserStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	SelectedUsersType = Undefined;
	
	If UsersCount <> 0 Then
		UsersToHide = New ValueList;
		UsersToHide.LoadValues(SettingsRecipientsUsers.UsersArray);
	EndIf;
	
	FilterParameters = New Structure(
		"ChoiceMode, UsersToHide",
		True, UsersToHide);
	
	If PassedUserType = Undefined Then
		
		If UseExternalUsers Then
			UsersTypeSelection = New ValueList;
			UsersTypeSelection.Add("ExternalUsers", NStr("vi = 'Người dùng ngoài';
														|ru = 'Внешние пользователи';
														|en = 'External users'; fa = 'کاربران خارجی';
														|it = 'Utenti esterni';
														|pl = 'Użytkownicy zewnętrzni';
														|tr = 'Harici kullanıcılar'"));
			UsersTypeSelection.Add("Users", NStr("vi = 'Người sử dụng';
												|ru = 'Пользователи';
												|en = 'Users'; fa = 'کاربران';
												|it = 'Utenti';
												|pl = 'Users';
												|tr = 'Kullanıcılar'"));
			
			Notification = New CallbackDescription("UserStartChoiceCompletion", ThisObject, FilterParameters);
			UsersTypeSelection.ShowChooseItem(Notification);
			Return;
		Else
			SelectedUsersType = "Users";
		EndIf;
		
	EndIf;
	
	OpenUserSelectionForm(SelectedUsersType, FilterParameters);
	
EndProcedure

&AtClient
Procedure UserStartChoiceCompletion(SelectedOption, FilterParameters) Export
	
	If SelectedOption = Undefined Then
		Return;
	EndIf;
	SelectedUsersType = SelectedOption.Value;
	
	OpenUserSelectionForm(SelectedUsersType, FilterParameters);
	
EndProcedure

&AtClient
Procedure OpenUserSelectionForm(SelectedUsersType, FilterParameters)
	
	If SelectedUsersType = "Users"
		Or PassedUserType = Type("CatalogRef.Users") Then
		OpenForm("Catalog.Users.ListForm", FilterParameters, Items.UserRef);
	ElsIf SelectedUsersType = "ExternalUsers"
		Or PassedUserType = Type("CatalogRef.ExternalUsers") Then
		OpenForm("Catalog.ExternalUsers.ListForm", FilterParameters, Items.UserRef);
	EndIf;
	UserRefOld = UserRef;
	
EndProcedure

&AtClient
Procedure UserRefOnChange(Item)
	
	If UserRef <> Undefined
		And IBUserName(UserRef) = Undefined Then
		ShowMessageBox(,NStr("vi = 'Người dùng đã chọn không có cài đặt nào để sao chép
				|, vui lòng chọn một người dùng khác.';
				|ru = 'У выбранного пользователя нет настроек, которые можно было бы
				|скопировать, выберите другого пользователя.';
				|en = 'The selected user does not have any settings to copy.
				|Please select another user.'; fa = 'The selected user does not have any settings to copy.
				|Please select another user.';
				|it = 'L''utente selezionato non possiede le impostazioni che potrebbero
				|essere copiate, selezionare un altro utente.';
				|pl = 'Wybrany użytkownik nie ma żadnych ustawień, które można 
				|skopiować, wybierz innego użytkownika.';
				|tr = 'Seçilen kullanıcı, 
				|başka bir kullanıcı seçmek için bir ayara sahip değildir.'"));
		UserRef = UserRefOld;
		Return;
	EndIf;
	
	If UserRef <> Undefined
		And SettingsRecipientsUsers.Property("UsersArray") Then
		
		If SettingsRecipientsUsers.UsersArray.Find(UserRef) <> Undefined Then
			ShowMessageBox(,NStr("vi = 'Bạn không thể sao chép cài đặt người dùng cho chính mình,
					|hãy chọn người dùng khác.';
					|ru = 'Нельзя копировать настройки пользователя самому себе,
					|выберите другого пользователя.';
					|en = 'Cannot copy user settings to the source user.
					|Please select a different user.'; fa = 'Cannot copy user settings to the source user.
					|Please select a different user.';
					|it = 'Non è possibile copiare le impostazioni utente su se stessi,
					|selezionare un altro utente.';
					|pl = 'Nie możesz skopiować ustawień użytkownika do siebie, 
					|wybierz innego użytkownika.';
					|tr = 'Kullanıcı ayarları bu kullanıcıya kopyalanamaz.
					|Lütfen, başka bir kullanıcı seçin.'"));
				UserRef = UserRefOld;
				Return;
		EndIf;
		
	EndIf;
	
	Items.SettingsToCopyGroup.Enabled = UserRef <> Undefined;
	
	SelectedSettings = Undefined;
	SettingsCount = 0;
	Items.SelectSettings.Title = NStr("vi = 'Chọn';
										|ru = 'Выбрать';
										|en = 'Select'; fa = 'انتخاب';
										|it = 'Selezionare';
										|pl = 'Select';
										|tr = 'Seç'");
	
EndProcedure

&AtServer
Function IBUserName(UserRef)
	
	Return DataProcessors.UsersSettings.IBUserName(UserRef);
	
EndFunction

&AtClient
Procedure SelectSettings(Item)
	
	FormParameters = New Structure("User, SettingsOperation, ClearSettingsSelectionHistory",
		UserRef, "Copy", ClearSettingsSelectionHistory);
	OpenForm("DataProcessor.UsersSettings.Form.SettingsChoice", FormParameters, ThisObject,,,,
		New CallbackDescription("SelectSettingsAfterChoice", ThisObject));
	
EndProcedure

&AtClient
Procedure SelectUsers(Item)
	
	SelectedUsers = Undefined;
	SettingsRecipientsUsers.Property("UsersArray", SelectedUsers);
	If SelectedUsers = Undefined Then
		SelectedUsers = New Array;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("User",          UserRef);
	FormParameters.Insert("ActionType",           "Copy");
	FormParameters.Insert("SelectedUsers", SelectedUsers);
	FormParameters.Insert("Source", FormName);
	
	OpenForm("DataProcessor.UsersSettings.Form.SelectUsers", FormParameters);
	
EndProcedure

&AtClient
Procedure CopySettingsToRadioButtonsOnChange(Item)
	
	If CopySettingsToRadioButtons = "SelectedUsers1" Then
		Items.SelectUsers.Enabled = True;
	Else
		Items.SelectUsers.Enabled = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure SettingsToCopyRadioButtonOnChange(Item)
	
	If SettingsToCopyRadioButton = "CopySelectedSettings1" Then
		Items.SelectSettings.Enabled = True;
	Else
		Items.SelectSettings.Enabled = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Copy(Command)
	
	ClearMessages();
	
	If UserRef = Undefined Then
		CommonClient.MessageToUser(
			NStr("vi = 'Hãy chọn người sử dụng mà cần sao chép tùy chỉnh của họ';
				|ru = 'Выберите пользователя, чьи настройки необходимо скопировать.';
				|en = 'Select the source user.'; fa = 'Select the source user.';
				|it = 'Selezionare l''utente con le impostazioni da copiare.';
				|pl = 'Wybierz użytkownika, którego ustawienia chcesz skopiować.';
				|tr = 'Ayarları kopyalanması gereken bir kullanıcı seçin.'"), , "UserRef");
		Return;
	EndIf;
	
	If UsersCount = 0 And CopySettingsToRadioButtons <> "ToAllUsers" Then
		CommonClient.MessageToUser(
			NStr("vi = 'Hãy chọn một hoặc nhiều người sử dụng cần sao chép tùy chỉnh.';
				|ru = 'Выберите одного или несколько пользователей, которым необходимо скопировать настройки.';
				|en = 'Select one or several destination users.'; fa = 'Select one or several destination users.';
				|it = 'Selezionare uno o più utenti che necessitano di copiare le impostazioni.';
				|pl = 'Wybierz jednego lub więcej użytkowników, aby skopiować ustawienia.';
				|tr = 'Ayarları kopyalanması gereken bir veya daha fazla kullanıcı seçin.'"), , "Receiver");
		Return;
	EndIf;
	
	If SettingsToCopyRadioButton = "CopySelectedSettings1" And SettingsCount = 0 Then
		CommonClient.MessageToUser(
			NStr("vi = 'Hãy chọn tùy chỉnh cần sao chép.';
				|ru = 'Выберите настройки, которые необходимо скопировать.';
				|en = 'Select the settings to copy.'; fa = 'Select the settings to copy.';
				|it = 'Selezionare le impostazioni da copiare.';
				|pl = 'Wybierz ustawienia, które chcesz skopiować.';
				|tr = 'Kopyalanacak ayarları seçin.'"), , "SettingsToCopyRadioButton");
		Return;
	EndIf;
	
	// When copying appearance settings or all settings to other users,
	// check if the app supports them. And if it does, inform the user in a user message.
	OpenFormsToCopy = OpenFormsToCopy();
	CheckActiveUsers();
	If CheckResult = "HasActiveUsersRecipients"
		Or (ValueIsFilled(OpenFormsToCopy) And CheckResult = "CurrentUserRecipient") Then
		
		If SettingsToCopyRadioButton = "CopyAllSettings" 
			Or (SettingsToCopyRadioButton = "CopySelectedSettings1"
			And SelectedSettings.Interface.Count() <> 0) Then
			
			ClosingNotification1 = New CallbackDescription("CopyContinued", ThisObject);
			
			FormParameters = New Structure;
			FormParameters.Insert("Action", Command.Name);
			FormParameters.Insert("OpenFormsToCopy", OpenFormsToCopy);
			FormParameters.Insert("HasActiveUsersRecipients", CheckResult = "HasActiveUsersRecipients");
			OpenForm("DataProcessor.UsersSettings.Form.CopySettingsWarning", FormParameters, , , , , ClosingNotification1);
			Return;
			
		EndIf;
		
	EndIf;
	CopySettings(Command.Name);
	
EndProcedure

&AtClient
Function OpenFormsToCopy()
	
	If SelectedSettings = Undefined Then
		Return "";
	EndIf;
	
	Settings = SelectedSettings.Interface;
	
	OpenFormsRow          = "";
	AllSettingsToCopyRow = "";
	For Each FormSettings In Settings Do
		For Each FormSettingsItem In FormSettings Do
			AllSettingsToCopyRow = AllSettingsToCopyRow + Chars.LF + FormSettingsItem.Value;
		EndDo;
	EndDo;
	
	OpenWindows = GetWindows();
	For Each OpenWindow In OpenWindows Do
		If OpenWindow.HomePage Or OpenWindow.IsMain Then
			Continue;
		EndIf;
		Content    = OpenWindow.Content;
		DefaultForm = Content.Get(0);
		
		OpenFormName = DefaultForm.FormName;
		If StrFind(OpenFormName, "DataProcessor.UsersSettings") > 0
			Or StrFind(OpenFormName, ".SSLAdministrationPanel.") > 0 Then
			Continue;
		EndIf;
		
		If StrFind(AllSettingsToCopyRow, OpenFormName) > 0 Then
			OpenFormsRow = ?(ValueIsFilled(OpenFormsRow),
				OpenFormsRow + Chars.LF + "- " + OpenWindow.Caption,
				NStr("vi = 'Cửa sổ mở';
					|ru = 'Открытые окна';
					|en = 'The open windows'; fa = 'The open windows';
					|it = 'Finestre aperte';
					|pl = 'Otwieranie okna';
					|tr = 'Açık pencereler'") + ":" + Chars.LF + "- " + OpenWindow.Caption)
		EndIf;
		
	EndDo;
	
	Return OpenFormsRow;
	
EndFunction

#EndRegion

#Region Private

&AtClient
Procedure CopyContinued(Result, AdditionalParameters) Export
	
	If TypeOf(Result) = Type("Structure")
		And Result.Property("Action")
		And Result.Action = "CopyAndClose" Then
		CopySettings(Result.Action);
	EndIf;
	
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
Procedure CopySettings(CommandName)
	
	If CopySettingsToRadioButtons = "SelectedUsers1" Then
		
		SettingsCopiedToNote = UsersInternalClient.UsersNote(
			UsersCount, SettingsRecipientsUsers.UsersArray[0]);
	Else
		SettingsCopiedToNote = NStr("vi = 'cho tất cả người sử dụng';
									|ru = 'всем пользователям';
									|en = 'all users'; fa = 'all users';
									|it = 'per tutti gli utenti';
									|pl = 'do wszystkich użytkowników';
									|tr = 'tüm kullanıcılara'");
	EndIf;
	
	NotificationText1    = NStr("vi = 'Sao chép tùy chỉnh';
								|ru = 'Копирование настроек';
								|en = 'Copy settings'; fa = 'کپی تنظیمات';
								|it = 'Copia delle impostazioni';
								|pl = 'Kopiowanie ustawień';
								|tr = 'Ayarları kopyala'");
	NotificationPicture = PictureLib.DialogInformation;
	
	If SettingsToCopyRadioButton = "CopySelectedSettings1" Then
		Report = Undefined;
		CopySelectedSettings(Report);
		
		If Report <> Undefined Then
			QueryText = NStr("vi = 'Không phải tất cả phương án báo cáo và tùy chỉnh đều được sao chép.';
							|ru = 'Не все варианты отчетов и настройки были скопированы.';
							|en = 'Some report options and settings are not copied.'; fa = 'Some report options and settings are not copied.';
							|it = 'Non tutte le versioni dei report e le impostazioni sono state copiate.';
							|pl = 'Nie wszystkie opcje raportów i ustawienia zostały skopiowane.';
							|tr = 'Bazı rapor seçenekleri ve ayarları kopyalanmadı.'");
			QuestionButtons = New ValueList;
			QuestionButtons.Add("OK", NStr("vi = 'Đồng ý';
											|ru = 'ОК';
											|en = 'OK'; fa = 'تأیید';
											|it = 'OK';
											|pl = 'OK';
											|tr = 'Tamam'"));
			QuestionButtons.Add("ShowReport", NStr("vi = 'Hiển thị báo cáo';
													|ru = 'Показать отчет';
													|en = 'View report'; fa = 'View report';
													|it = 'Visualizzare il report';
													|pl = 'Pokaż raport';
													|tr = 'Rapor göster'"));
			
			Notification = New CallbackDescription("CopySettingsShowQueryBox", ThisObject, Report);
			ShowQueryBox(Notification, QueryText, QuestionButtons,, QuestionButtons[0].Value);
			Return;
		EndIf;
			
		If Report = Undefined Then
			NotificationComment = UsersInternalClient.GenerateNoteOnCopy(
				SettingPresentation, SettingsCount, SettingsCopiedToNote);
			
			ShowUserNotification(NotificationText1, , NotificationComment, NotificationPicture);
		EndIf;
	Else
		SettingsCopied = CopyingAllSettings();
		If Not SettingsCopied Then
			
			ShowMessageBox(, StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Tùy chỉnh không được sao chép vì người sử dụng ""%1"" đã không lưu bất kỳ tùy chỉnh nào.';
					|ru = 'Настройки не были скопированы, так как у пользователя ""%1"" не было сохранено ни одной настройки.';
					|en = 'The settings were not copied because user ""%1"" does not have any saved settings.'; fa = 'The settings were not copied because user ""%1"" does not have any saved settings.';
					|it = 'Le impostazioni non sono state copiate, poiché l''utente ""%1"" non ha salvato alcuna impostazione.';
					|pl = 'Ustawienia nie zostały skopiowane, ponieważ użytkownik ""%1"" nie zapisał żadnych ustawień.';
					|tr = '""%1"" kullanıcısının kayıtlı ayarları olmadığından ayarlar kopyalanmadı.'"),
				String(UserRef)));
			Return;
		EndIf;
		
		NotificationComment = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã sao chép tất cả tùy chỉnh %1';
				|ru = 'Скопированы все настройки %1';
				|en = 'All settings are copied to %1'; fa = 'All settings are copied to %1';
				|it = 'Tutte le impostazioni sono copiate %1';
				|pl = 'Skopiowane wszystkie ustawienia %1';
				|tr = 'Tüm ayarlar kopyalandı %1'"), SettingsCopiedToNote);
		
		ShowUserNotification(NotificationText1, , NotificationComment, NotificationPicture);
	EndIf;
	
	// If this is copying settings from another user, notifying the UsersSettings form
	If FormOpeningMode = "CopyFrom" Then
		Notify("SettingsCopied1", True);
	EndIf;
	
	If CommandName = "CopyAndClose" Then
		Close();
	EndIf;
	
	Return;
	
EndProcedure

&AtClient
Procedure CopySettingsShowQueryBox(Response, Report) Export
	
	If Response = "OK" Then
		Return;
	Else
		Report.ShowGroups = True;
		Report.ShowGrid = False;
		Report.ShowHeaders = False;
		Report.Show();
		Return;
	EndIf;
	
EndProcedure

&AtServer
Procedure CopySelectedSettings(Report)
	
	User = DataProcessors.UsersSettings.IBUserName(UserRef);
	
	If CopySettingsToRadioButtons = "SelectedUsers1" Then
		Destinations = SettingsRecipientsUsers.UsersArray;
	ElsIf CopySettingsToRadioButtons = "ToAllUsers" Then
		Destinations = New Array;
		UsersTable = New ValueTable;
		UsersTable.Columns.Add("User");
		UsersTable.Columns.Add("Department");
		UsersTable.Columns.Add("Individual");
		DataProcessors.UsersSettings.UsersToCopy(UserRef, UsersTable,
			TypeOf(UserRef) = Type("CatalogRef.ExternalUsers"));
		
		For Each TableRow In UsersTable Do
			Destinations.Add(TableRow.User);
		EndDo;
		
	EndIf;
	
	NotCopiedReportSettings = New ValueTable;
	NotCopiedReportSettings.Columns.Add("User");
	NotCopiedReportSettings.Columns.Add("ReportsList", New TypeDescription("ValueList"));
	
	If SelectedSettings.ReportsSettings.Count() > 0 Then
		
		DataProcessors.UsersSettings.CopyReportAndPersonalSettings(ReportsUserSettingsStorage,
			User, Destinations, SelectedSettings.ReportsSettings, NotCopiedReportSettings);
		
		DataProcessors.UsersSettings.CopyReportOptions(
			SelectedSettings.SelectedReportsOptions, SelectedSettings.ReportOptionTable, User, Destinations);
	EndIf;
		
	If SelectedSettings.Interface.Count() > 0 Then
		DataProcessors.UsersSettings.CopyInterfaceSettings(User, Destinations, SelectedSettings.Interface);
	EndIf;
	
	If SelectedSettings.OtherSettings.Count() > 0 Then
		DataProcessors.UsersSettings.CopyInterfaceSettings(User, Destinations, SelectedSettings.OtherSettings);
	EndIf;
	
	If SelectedSettings.PersonalSettings.Count() > 0 Then
		DataProcessors.UsersSettings.CopyReportAndPersonalSettings(CommonSettingsStorage,
			User, Destinations, SelectedSettings.PersonalSettings);
	EndIf;
	
	For Each OtherUserSettingsItem In SelectedSettings.OtherUserSettings Do
		For Each CatalogUser In Destinations Do
			UserInfo = New Structure;
			UserInfo.Insert("UserRef", CatalogUser);
			UserInfo.Insert("InfoBaseUserName", 
				DataProcessors.UsersSettings.IBUserName(CatalogUser));
			UsersInternal.OnSaveOtherUserSettings(
				UserInfo, OtherUserSettingsItem);
		EndDo;
	EndDo;
	
	If NotCopiedReportSettings.Count() <> 0 Then
		Report = DataProcessors.UsersSettings.CreateReportOnCopyingSettings(
			NotCopiedReportSettings);
	EndIf;
	
EndProcedure

&AtServer
Function CopyingAllSettings()
	
	If CopySettingsToRadioButtons = "SelectedUsers1" Then
		Destinations = SettingsRecipientsUsers.UsersArray;
	Else
		Destinations = New Array;
		UsersTable = New ValueTable;
		UsersTable.Columns.Add("User");
		UsersTable.Columns.Add("Department");
		UsersTable.Columns.Add("Individual");
		UsersTable = DataProcessors.UsersSettings.UsersToCopy(UserRef, UsersTable, 
			TypeOf(UserRef) = Type("CatalogRef.ExternalUsers"));
		
		For Each TableRow In UsersTable Do
			Destinations.Add(TableRow.User);
		EndDo;
		
	EndIf;
	
	SettingsToCopy = New Array;
	SettingsToCopy.Add("ReportsSettings");
	SettingsToCopy.Add("InterfaceSettings2");
	SettingsToCopy.Add("PersonalSettings");
	SettingsToCopy.Add("Favorites");
	SettingsToCopy.Add("PrintSettings");
	SettingsToCopy.Add("OtherUserSettings");
	
	SettingsCopied = DataProcessors.UsersSettings.
		CopyUsersSettings(UserRef, Destinations, SettingsToCopy);
		
	Return SettingsCopied;
	
EndFunction

&AtServer
Procedure CheckActiveUsers()
	
	CurrentUser = Users.CurrentUser();
	If SettingsRecipientsUsers.Property("UsersArray") Then
		UsersArray = SettingsRecipientsUsers.UsersArray;
	EndIf;
	
	If CopySettingsToRadioButtons = "ToAllUsers" Then
		
		UsersArray = New Array;
		UsersTable = New ValueTable;
		UsersTable.Columns.Add("User");
		UsersTable.Columns.Add("Department");
		UsersTable.Columns.Add("Individual");
		UsersTable = DataProcessors.UsersSettings.UsersToCopy(UserRef, UsersTable, 
			TypeOf(UserRef) = Type("CatalogRef.ExternalUsers"));
		
		For Each TableRow In UsersTable Do
			UsersArray.Add(TableRow.User);
		EndDo;
		
	EndIf;
	
	If UsersArray.Count() = 1 
		And UsersArray[0] = CurrentUser Then
		
		CheckResult = "CurrentUserRecipient";
		Return;
		
	EndIf;
		
	HasActiveUsersRecipients = False;
	Sessions = GetInfoBaseSessions();
	For Each Recipient In UsersArray Do
		If Recipient = CurrentUser Then
			CheckResult = "CurrentUserAmongRecipients";
			Return;
		EndIf;
		For Each Session In Sessions Do
			If Recipient.IBUserID = Session.User.UUID Then
				HasActiveUsersRecipients = True;
			EndIf;
		EndDo;
	EndDo;
	
	CheckResult = ?(HasActiveUsersRecipients, "HasActiveUsersRecipients", "");
	
EndProcedure

#EndRegion
