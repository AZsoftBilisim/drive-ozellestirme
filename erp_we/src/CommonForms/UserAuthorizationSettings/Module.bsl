///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Variables

&AtServer
Var CurrentSettingsByItems, CurrentItemsBySettings;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ShowExternalUsersSettings = Parameters.ShowExternalUsersSettings;
	UseExternalUsers = ExternalUsers.UseExternalUsers();
	
	RecommendedSettingsValues = New Structure;
	RecommendedSettingsValues.Insert("PasswordMustMeetComplexityRequirements", Null);
	RecommendedSettingsValues.Insert("MinPasswordLength", 8);
	RecommendedSettingsValues.Insert("ShouldBeExcludedFromBannedPasswordList", Null);
	RecommendedSettingsValues.Insert("ActionUponLoginIfRequirementNotMet", "SuggestPasswordChange");
	RecommendedSettingsValues.Insert("MaxPasswordLifetime", 30);
	RecommendedSettingsValues.Insert("MinPasswordLifetime", 1);
	RecommendedSettingsValues.Insert("DenyReusingRecentPasswords", 10);
	RecommendedSettingsValues.Insert("WarnAboutPasswordExpiration", 5);
	RecommendedSettingsValues.Insert("InactivityPeriodBeforeDenyingAuthorization", 45);
	
	RecommendedCommonSettingsValues = New Structure;
	RecommendedCommonSettingsValues.Insert("AreSeparateSettingsForExternalUsers", Null);
	RecommendedCommonSettingsValues.Insert("NotificationLeadTimeBeforeAccessExpire", 7);
	RecommendedCommonSettingsValues.Insert("PasswordSaveOptionUponLogin", "AllowedAndDisabled");
	RecommendedCommonSettingsValues.Insert("PasswordRemembranceDuration",
		SuggestedValue(600, True, "PasswordSaveOptionUponLogin", True));
	RecommendedCommonSettingsValues.Insert("InactivityTimeoutBeforeTerminateSession", 960);
	RecommendedCommonSettingsValues.Insert("NotificationLeadTimeBeforeTerminateInactiveSession", 5);
	RecommendedCommonSettingsValues.Insert("PasswordAttemptsCountBeforeLockout", 3);
	RecommendedCommonSettingsValues.Insert("PasswordLockoutDuration",
		SuggestedValue(5, True, "PasswordAttemptsCountBeforeLockout", True));
	RecommendedCommonSettingsValues.Insert("ShowInList", Null);
	RecommendedCommonSettingsValues.Insert("ShouldUseStandardBannedPasswordList", Null);
	RecommendedCommonSettingsValues.Insert("ShouldUseAdditionalBannedPasswordList", Null);
	RecommendedCommonSettingsValues.Insert("ShouldUseBannedPasswordService", Null);
	RecommendedCommonSettingsValues.Insert("BannedPasswordServiceAddress", Null);
	RecommendedCommonSettingsValues.Insert("BannedPasswordServiceMaxTimeout", Null);
	RecommendedCommonSettingsValues.Insert("ShouldSkipValidationIfBannedPasswordServiceOffline", Null);
	
	LogonSettings = UsersInternal.LogonSettings();
	If Common.DataSeparationEnabled() Then
		Items.GroupWarnAboutPasswordExpiration.Visible = False;
		Items.GroupWarnAboutPasswordExpiration2.Visible = False;
	EndIf;
	
	FillMapOfSettingAndItemNames();
	
	FillSettingsInForm(LogonSettings.Overall, RecommendedCommonSettingsValues);
	FillSettingsInForm(LogonSettings.Users, RecommendedSettingsValues);
	FillSettingsInForm(LogonSettings.ExternalUsers, RecommendedSettingsValues, True);
	
	If UseExternalUsers Then
		UpdateExternalUsersSettingsAvailability(ThisObject);
		If ShowExternalUsersSettings Then
			Items.Pages.CurrentPage = Items.ForExternalUsers;
		EndIf;
	Else
		Items.AreSeparateSettingsForExternalUsers.Visible = False;
		AreSeparateSettingsForExternalUsers = False;
		UpdateExternalUsersSettingsAvailability(ThisObject);
	EndIf;
	
	If Common.DataSeparationEnabled() Then
		Items.WarningConfigurationInService.Visible = True;
		Items.FormWriteAndClose.Enabled = False;
		Items.Pages.ReadOnly = True;
		Items.NoteShowInListDataSeparationEnabled.Visible = True;
		Items.ShowInList.Enabled = False;
		Items.ShowBannedPasswordList.Enabled = False;
		Items.ClearBannedPasswordList.Enabled = False;
		Items.ImportBannedPasswordList.Enabled = False;
		
	ElsIf UseExternalUsers Then
		Items.NoteShowInListExternalUsers.Visible = True;
		Items.ShowInList.Enabled = False;
	EndIf;
	
	If Common.FileInfobase() Then
		Items.GroupPasswordAttemptsCountBeforeLockout.Visible = False;
		Items.GroupPasswordLockoutDuration.Visible = False;
	EndIf;
	
	If Not UsersInternal.IsSettings8_3_26Available() Then
		Items.ShouldBeExcludedFromBannedPasswordList.Visible = False;
		Items.ActionUponLoginIfRequirementNotMetEnable.Visible = False;
		Items.GroupActionUponLoginIfRequirementNotMet.Visible = False;
		Items.ShouldBeExcludedFromBannedPasswordList2.Visible = False;
		Items.ActionUponLoginIfRequirementNotMet2Enable.Visible = False;
		Items.GroupActionUponLoginIfRequirementNotMet2.Visible = False;
		Items.GroupInactivityTimeoutBeforeTerminateSession.Visible = False;
		Items.GroupNotificationLeadTimeBeforeTerminateInactiveSession.Visible = False;
		Items.GroupPasswordSaveOptionUponLogin.Visible = False;
		Items.GroupPasswordRemembranceDuration.Visible = False;
		Items.BannedPasswords.Visible = False;
	EndIf;
	
	Items.ImportBannedPasswordListExtendedTooltip.Title =
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đặt danh sách mật khẩu từ tệp văn bản (%1 với bảng kê chi tiết [với %2]). Mỗi mật khẩu phải được chỉ định trên một dòng.
			           |Thay vì mật khẩu, bạn có thể chỉ định các giá trị mật khẩu được lưu trữ (băm (hash) mật khẩu bằng thuật toán %3 ở định dạng %4).';
			           |ru = 'Установить список паролей из текстового файла (%1 со спецификацией [c %2]). Каждый пароль должен быть указан на одной строке.
			           |Вместо паролей можно указать сохраняемые значения паролей (хеши паролей по алгоритму %3 в формате %4).';
			           |en = 'Import a banned password list from a text file encoded with %1 with specification (with %2). Each password should be specified on a separate line.
			           |You can specify either a password or its %3 hash in the %4 format.'; fa = 'Import a banned password list from a text file encoded with %1 with specification (with %2). Each password should be specified on a separate line.
			           |You can specify either a password or its %3 hash in the %4 format.';
			           |it = 'Установить список паролей из текстового файла (%1 со спецификацией [c %2]). Каждый пароль должен быть указан на одной строке.
			           |Вместо паролей можно указать сохраняемые значения паролей (хеши паролей по алгоритму %3 в формате %4).';
			           |pl = 'Import a banned password list from a text file encoded with %1 with specification (with %2). Each password should be specified on a separate line.
			           |You can specify either a password or its %3 hash in the %4 format.';
			           |tr = 'Bir metin dosyasından (%1,spesifikasyonunun  [, %2 ile] ) şifrelerin bir listesini ayarlayın. Her şifre bir satırda belirtilmelidir.
			           |Şifreler yerine, kaydedilen şifre değerlerini belirtebilirsiniz (%4 formatında %3 algoritmasını kullanan şifre karmaları)'"),
			"UTF-8", "BOM", "sha1", "base64");
	
	UpdateAvailabilityOfBannedPasswordServiceSettings(ThisObject);
	RecountPasswordsInAdditionalBannedList();
	
	StandardSubsystemsServer.ResetWindowLocationAndSize(ThisObject);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If ShouldUseBannedPasswordService
	   And Not ValueIsFilled(BannedPasswordServiceAddress) Then
		
		Common.MessageToUser(
			NStr("vi = 'Chưa điền địa chỉ dịch vụ';
				|ru = 'Адрес сервиса не заполнен';
				|en = 'Service address required'; fa = 'Service address required';
				|it = 'Адрес сервиса не заполнен';
				|pl = 'Service address required';
				|tr = 'Adres hizmeti doldurulmadı'"),, "BannedPasswordServiceAddress",, Cancel);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AreSeparateSettingsForExternalUsersOnChange(Item)
	
	UpdateExternalUsersSettingsAvailability(ThisObject, True);
	
EndProcedure

&AtClient
Procedure PasswordMustMeetComplexityRequirementsOnChange(Item)
	
	If MinPasswordLength < 7 Then
		MinPasswordLength = 7;
	EndIf;
	If MinPasswordLength2 < 7 Then
		MinPasswordLength2 = 7;
	EndIf;
	
EndProcedure

&AtClient
Procedure MinPasswordLengthOnChange(Item)
	
	If MinPasswordLength < 7
	  And PasswordMustMeetComplexityRequirements Then
		
		MinPasswordLength = 7;
	EndIf;
	
	If MinPasswordLength2 < 7
	  And PasswordMustMeetComplexityRequirements2 Then
		
		MinPasswordLength2 = 7;
	EndIf;
	
EndProcedure

&AtClient
Procedure SettingEnableOnChange(Item)
	
	Names = SettingsByItems.Get(Item.Name);
	
	If ThisObject[Item.Name] = False Then
		SuggestedValue = SuggestedValue(RecommendedSettingsValues[Names.SettingName]);
		ThisObject[Names.SettingNameOnForm] = SuggestedValue.Value;
	EndIf;
	
	Items[Names.TagName].Enabled = ThisObject[Item.Name];
	
EndProcedure

&AtClient
Procedure CommonSettingEnableOnChange(Item, EnableSynchronously = True)
	
	Names = SettingsByItems.Get(Item.Name);
	
	If ThisObject[Item.Name] = False Then
		SuggestedValue = SuggestedValue(RecommendedCommonSettingsValues[Names.SettingName]);
		ThisObject[Names.SettingNameOnForm] = SuggestedValue.Value;
	EndIf;
	
	Items[Names.TagName].Enabled = ThisObject[Item.Name];
	
	If Not EnableSynchronously Then
		Return;
	EndIf;
	
	EnableSynchronously(Item,
		Items.ShouldTerminateSessionAfterInactivityTimeout.Name,
		Items.ShouldNotifyUserBeforeTerminateInactiveSession.Name);
	
	EnableSynchronously(Item,
		Items.PasswordAttemptsCountBeforeLockoutEnable.Name,
		Items.PasswordLockoutDurationEnable.Name);
	
	EnableSynchronously(Item,
		Items.CanSavePasswordUponLogin.Name,
		Items.ShouldTemporarilyRememberPassword.Name);
	
EndProcedure

&AtClient
Procedure SettingValueOnChange(Item, Value = 1)
	
	If ThisObject[Item.Name] < Value Then
		ThisObject[Item.Name] = Value;
	EndIf;
	
EndProcedure

&AtClient
Procedure InactivityTimeoutBeforeTerminateSessionOnChange(Item)
	
	SettingValueOnChange(Item, 2);
	
	If NotificationLeadTimeBeforeTerminateInactiveSession > InactivityTimeoutBeforeTerminateSession - 1 Then
		NotificationLeadTimeBeforeTerminateInactiveSession = InactivityTimeoutBeforeTerminateSession - 1;
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationLeadTimeBeforeTerminateInactiveSessionOnChange(Item)
	
	SettingValueOnChange(Item);
	
	If InactivityTimeoutBeforeTerminateSession < NotificationLeadTimeBeforeTerminateInactiveSession + 1 Then
		InactivityTimeoutBeforeTerminateSession = NotificationLeadTimeBeforeTerminateInactiveSession + 1;
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowInListClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure ShowInListChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If ShowInList = ValueSelected
	 Or ValueSelected = "EnabledForNewUsers"
	 Or ValueSelected = "DisabledForNewUsers" Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	Notification = New CallbackDescription("ShowInListChoiceProcessingCompletion",
		ThisObject, ValueSelected);
	
	If ValueSelected = "HiddenAndEnabledForAllUsers" Then
		QueryText =
			NStr("vi = 'Khi đăng nhập vào ứng dụng, danh sách chọn người sử dụng sẽ đầy đủ
			           |(sẽ bật sử dụng và ẩn mục tin ""Hiển thị trong danh sách chọn"" trong tất cả các thẻ của tất cả
			           | người sử dụng)';
			           |ru = 'При входе в приложение список выбора пользователей станет полным
			           |(реквизит ""Показывать в списке выбора"" в карточках всех
			           | пользователей будет включен и скрыт).';
			           |en = 'The startup dialog will display the list of all users.
			           |The ""Show in choice list"" checkbox will be selected and hidden in all user cards.
			           |'; fa = 'The startup dialog will display the list of all users.
			           |The ""Show in choice list"" checkbox will be selected and hidden in all user cards.
			           |';
			           |it = 'При входе в приложение список выбора пользователей станет полным
			           |(реквизит ""Показывать в списке выбора"" в карточках всех
			           | пользователей будет включен и скрыт).';
			           |pl = 'The startup dialog will display the list of all users.
			           |The ""Show in choice list"" checkbox will be selected and hidden in all user cards.
			           |';
			           |tr = 'Uygulamaya giriş yapıldığında, kullanıcı seçim listesi doldurulur
			           |(Tüm
			           | kullanıcıların kartlarındaki “Seçim listesinde göster” özelliği etkinleştirilecek ve gizlenecektir).'");
	Else
		QueryText =
			NStr("vi = 'Khi đăng nhập vào ứng dụng, danh sách chọn người sử dụng sẽ đầy đủ
			           |(sẽ xóa và ẩn mục tin ""Hiển thị trong danh sách chọn"" trong tất cả các thẻ của tất cả
			           | người sử dụng)';
			           |ru = 'При входе в приложение список выбора пользователей станет пустым
			           |(реквизит ""Показывать в списке выбора"" в карточках всех
			           | пользователей будет очищен и скрыт).';
			           |en = 'The user list in the startup dialog will be cleared.
			           |The ""Show in choice list"" checkbox will be cleared and hidden in all user cards.
			           |'; fa = 'The user list in the startup dialog will be cleared.
			           |The ""Show in choice list"" checkbox will be cleared and hidden in all user cards.
			           |';
			           |it = 'При входе в приложение список выбора пользователей станет пустым
			           |(реквизит ""Показывать в списке выбора"" в карточках всех
			           | пользователей будет очищен и скрыт).';
			           |pl = 'The user list in the startup dialog will be cleared.
			           |The ""Show in choice list"" checkbox will be cleared and hidden in all user cards.
			           |';
			           |tr = 'Uygulamaya giriş yapıldığında, kullanıcı seçim listesi doldurulur
			           |(Tüm
			           | kullanıcıların kartlarındaki “Seçim listesinde göster” özelliği etkinleştirilecek ve gizlenecektir).'");
	EndIf;
	
	ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure ShouldUseBannedPasswordServiceOnChange(Item)
	
	UpdateAvailabilityOfBannedPasswordServiceSettings(ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteAndClose(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	WriteAtServer();
	Notify("Write_ConstantsSet", New Structure, "UserAuthorizationSettings");
	Close();
	
EndProcedure

&AtClient
Procedure ShowBannedPasswordList(Command)
	
	If ValueIsFilled(NewPasswordListAddressInTempStorage) Then
		Text = ImportedBannedPasswordList(NewPasswordListAddressInTempStorage);
		If IsNewListContainsPasswords Then
			DocumentTitle = NStr("vi = 'Mật khẩu bị cấm (được tải xuống để cài đặt)';
								|ru = 'Запрещенные пароли (загружены для установки)';
								|en = 'Banned passwords (imported)'; fa = 'Banned passwords (imported)';
								|it = 'Запрещенные пароли (загружены для установки)';
								|pl = 'Banned passwords (imported)';
								|tr = 'Yasak parolalar (kurulmak için yüklenmiştir)'");
		Else
			DocumentTitle = NStr("vi = 'Băm (hash) các mật khẩu bị cấm (được tải xuống để cài đặt)';
								|ru = 'Хеши запрещенных паролей (загружены для установки)';
								|en = 'Banned password hashes (imported)'; fa = 'Banned password hashes (imported)';
								|it = 'Хеши запрещенных паролей (загружены для установки)';
								|pl = 'Banned password hashes (imported)';
								|tr = 'Yasaklanmış şifrelerin karmaları (kurulum için yüklenmiştir)'");
		EndIf;
	Else
		Text = CurrentBannedPasswordHashList();
		DocumentTitle = NStr("vi = 'Băm (hash) các mật khẩu bị cấm';
							|ru = 'Хеши запрещенных паролей';
							|en = 'Banned password hashes'; fa = 'Banned password hashes';
							|it = 'Хеши запрещенных паролей';
							|pl = 'Banned password hashes';
							|tr = 'Yasaklanmış şifrelerin karmaları'");
	EndIf;
	
	TextDocument = New TextDocument;
	TextDocument.SetText(Text);
	TextDocument.Show(DocumentTitle);
	
EndProcedure

&AtClient
Procedure ClearBannedPasswordList(Command)
	
	RecountPasswordsInAdditionalBannedList(True);
	
EndProcedure

&AtClient
Procedure ImportBannedPasswordList(Command)
	
	ImportParameters = FileSystemClient.FileImportParameters();
	ImportParameters.FormIdentifier = UUID;
	ImportParameters.Dialog.Filter = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Văn bản thuần (%1 với bảng kê chi tiết [với %2])';
			|ru = 'Текстовый документ (%1 со спецификацией [c %2])';
			|en = 'Text file: %1 with specification (with %2)'; fa = 'Text file: %1 with specification (with %2)';
			|it = 'Текстовый документ (%1 со спецификацией [c %2])';
			|pl = 'Text file: %1 with specification (with %2)';
			|tr = 'Metin belgesi (%1 spesifikasyonla [%2 ile])'"), "UTF-8", "BOM") + "|*.txt";
	
	Notification = New CallbackDescription("AfterFileImported", ThisObject);
	FileSystemClient.ImportFile_(Notification, ImportParameters);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillMapOfSettingAndItemNames()
	
	CurrentSettingsByItems = New Map;
	CurrentItemsBySettings = New Map;
	
	AddNames(Items.PasswordMustMeetComplexityRequirements2.Name,
		Items.PasswordMustMeetComplexityRequirements2.Name,
		"PasswordMustMeetComplexityRequirements",
		"PasswordMustMeetComplexityRequirements2");
	
	AddNames(Items.MinPasswordLengthEnable.Name,
		Items.MinPasswordLength.Name,
		"MinPasswordLength");
	
	AddNames(Items.MinPasswordLength2Enable.Name,
		Items.MinPasswordLength2.Name,
		"MinPasswordLength",
		"MinPasswordLength2");
	
	AddNames(Items.ActionUponLoginIfRequirementNotMetEnable.Name,
		Items.ActionUponLoginIfRequirementNotMet.Name,
		"ActionUponLoginIfRequirementNotMet");
	
	AddNames(Items.ActionUponLoginIfRequirementNotMet2Enable.Name,
		Items.ActionUponLoginIfRequirementNotMet2.Name,
		"ActionUponLoginIfRequirementNotMet",
		"ActionUponLoginIfRequirementNotMet2");
	
	AddNames(Items.MaxPasswordLifetimeEnable.Name,
		Items.MaxPasswordLifetime.Name,
		"MaxPasswordLifetime");
	
	AddNames(Items.MaxPasswordLifetime2Enable.Name,
		Items.MaxPasswordLifetime2.Name,
		"MaxPasswordLifetime",
		"MaxPasswordLifetime2");
	
	AddNames(Items.MinPasswordLifetimeEnable.Name,
		Items.MinPasswordLifetime.Name,
		"MinPasswordLifetime");
	
	AddNames(Items.MinPasswordLifetime2Enable.Name,
		Items.MinPasswordLifetime2.Name,
		"MinPasswordLifetime",
		"MinPasswordLifetime2");
	
	AddNames(Items.DenyReusingRecentPasswordsEnable.Name,
		Items.DenyReusingRecentPasswords.Name,
		"DenyReusingRecentPasswords");
	
	AddNames(Items.DenyReusingRecentPasswords2Enable.Name,
		Items.DenyReusingRecentPasswords2.Name,
		"DenyReusingRecentPasswords",
		"DenyReusingRecentPasswords2");
	
	AddNames(Items.WarnAboutPasswordExpirationEnable.Name,
		Items.WarnAboutPasswordExpiration.Name,
		"WarnAboutPasswordExpiration");
	
	AddNames(Items.WarnAboutPasswordExpiration2Enable.Name,
		Items.WarnAboutPasswordExpiration2.Name,
		"WarnAboutPasswordExpiration",
		"WarnAboutPasswordExpiration2");
	
	AddNames(Items.InactivityPeriodBeforeDenyingAuthorizationEnable.Name,
		Items.InactivityPeriodBeforeDenyingAuthorization.Name,
		"InactivityPeriodBeforeDenyingAuthorization");
	
	AddNames(Items.InactivityPeriodBeforeDenyingAuthorization2Enable.Name,
		Items.InactivityPeriodBeforeDenyingAuthorization2.Name,
		"InactivityPeriodBeforeDenyingAuthorization",
		"InactivityPeriodBeforeDenyingAuthorization2");
	
	AddNames(Items.ShouldNotifyUserBeforeAccessExpire.Name,
		Items.NotificationLeadTimeBeforeAccessExpire.Name,
		"NotificationLeadTimeBeforeAccessExpire");
	
	AddNames(Items.ShouldTerminateSessionAfterInactivityTimeout.Name,
		Items.InactivityTimeoutBeforeTerminateSession.Name,
		"InactivityTimeoutBeforeTerminateSession");
	
	AddNames(Items.ShouldNotifyUserBeforeTerminateInactiveSession.Name,
		Items.NotificationLeadTimeBeforeTerminateInactiveSession.Name,
		"NotificationLeadTimeBeforeTerminateInactiveSession");
	
	AddNames(Items.PasswordAttemptsCountBeforeLockoutEnable.Name,
		Items.PasswordAttemptsCountBeforeLockout.Name,
		"PasswordAttemptsCountBeforeLockout");
	
	AddNames(Items.PasswordLockoutDurationEnable.Name,
		Items.PasswordLockoutDuration.Name,
		"PasswordLockoutDuration");
	
	AddNames(Items.CanSavePasswordUponLogin.Name,
		Items.PasswordSaveOptionUponLogin.Name,
		"PasswordSaveOptionUponLogin");
	
	AddNames(Items.ShouldTemporarilyRememberPassword.Name,
		Items.PasswordRemembranceDuration.Name,
		"PasswordRemembranceDuration");
	
	SettingsByItems = New FixedMap(CurrentSettingsByItems);
	ItemsBySettings = New FixedMap(CurrentItemsBySettings);
	
EndProcedure

&AtServer
Procedure AddNames(ItemNameInclude, TagName, SettingName, SettingNameOnForm = Undefined)
	
	Properties = New Structure;
	Properties.Insert("TagName", TagName);
	Properties.Insert("SettingName", SettingName);
	Properties.Insert("SettingNameOnForm", SettingNameOnForm);
	
	If SettingNameOnForm = Undefined Then
		Properties.SettingNameOnForm = SettingName;
	EndIf;
	
	CurrentSettingsByItems.Insert(ItemNameInclude, New FixedStructure(Properties));
	
	NamesKey = ?(SettingNameOnForm = Undefined, SettingName, SettingName + "2");
	Properties.Delete("SettingName");
	Properties.Insert("ItemNameInclude", ItemNameInclude);
	
	CurrentItemsBySettings.Insert(NamesKey, New FixedStructure(Properties));
	
EndProcedure

&AtClientAtServerNoContext
Function SuggestedValue(Value, Enable = True, Dependence = "", IsEmptyForbidden = False)
	
	If TypeOf(Value) = Type("Structure") Then
		Return Value;
	EndIf;
	
	Result = New Structure;
	Result.Insert("Value", Value);
	Result.Insert("Enable", Enable);
	Result.Insert("Dependence", Dependence);
	Result.Insert("IsEmptyForbidden", IsEmptyForbidden);
	
	Return Result;
	
EndFunction

&AtClient
Procedure EnableSynchronously(Item, Name1, Name2)
	
	If Item.Name = Name1 Then
		ThisObject[Name2] = ThisObject[Name1];
		CommonSettingEnableOnChange(Items[Name2], False);
		
	ElsIf Item.Name = Name2 Then
		ThisObject[Name1] = ThisObject[Name2];
		CommonSettingEnableOnChange(Items[Name1], False);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateExternalUsersSettingsAvailability(Form, OnChange = False)
	
	If Form.AreSeparateSettingsForExternalUsers Then
		Form.Items.ForUsers.Title = NStr("vi = 'Đối với người sử dụng';
										|ru = 'Для пользователей';
										|en = 'For users'; fa = 'برای کاربران';
										|it = 'Per gli utenti';
										|pl = 'Dla użytkowników';
										|tr = 'Kullanıcılar için'");
		Form.Items.ForExternalUsers.Visible = True;
		If OnChange Then
			Form.Items.Pages.CurrentPage =
				Form.Items.ForExternalUsers;
		EndIf;
	Else
		Form.Items.ForUsers.Title = NStr("vi = 'Chính';
										|ru = 'Основные';
										|en = 'Main'; fa = 'اصلی';
										|it = 'Основные';
										|pl = 'Main';
										|tr = 'Ana'");
		Form.Items.ForExternalUsers.Visible = False;
		Form.Items.Pages.CurrentPage =
			Form.Items.ForUsers;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateAvailabilityOfBannedPasswordServiceSettings(Form)
	
	Form.Items.BannedPasswordServiceAddress.Enabled =
		Form.ShouldUseBannedPasswordService;
	
	Form.Items.BannedPasswordServiceAddress.AutoMarkIncomplete =
		?(Form.ShouldUseBannedPasswordService, True, Undefined);
	
	Form.Items.BannedPasswordServiceMaxTimeout.Enabled =
		Form.ShouldUseBannedPasswordService;
	
	Form.Items.ShouldSkipValidationIfBannedPasswordServiceOffline.Enabled =
		Form.ShouldUseBannedPasswordService;
	
EndProcedure

&AtServer
Procedure RecountPasswordsInAdditionalBannedList(Val Clear = False, Val Count = -1)
	
	If UsersInternal.IsSettings8_3_26Available() Then
		If Clear Then
			Count = 0;
			NewPasswordListAddressInTempStorage =
				PutToTempStorage(New Array, UUID);
		ElsIf Count = -1 Then
			SetPrivilegedMode(True);
			ManagerOfList = AdditionalAuthenticationSettings.PasswordCompromiseCheckList;
			Count = ManagerOfList.GetPasswordsStoredValuesCount();
			SetPrivilegedMode(False);
		EndIf;
	Else
		Count = 0;
	EndIf;
	
	If ValueIsFilled(Count) Then
		IsListAvailable = Not Common.DataSeparationEnabled();
		TitleText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Danh sách bổ sung (%1)';
				|ru = 'Дополнительный список (%1)';
				|en = 'Additional list (%1)'; fa = 'Additional list (%1)';
				|it = 'Дополнительный список (%1)';
				|pl = 'Additional list (%1)';
				|tr = 'Ek liste (%1)'"), String(Count));
	Else
		IsListAvailable = False;
		TitleText = NStr("vi = 'Danh sách bổ sung';
						|ru = 'Дополнительный список';
						|en = 'Additional list'; fa = 'فهرست تکمیلی';
						|it = 'Дополнительный список';
						|pl = 'Additional list';
						|tr = 'Ek liste'");
	EndIf;
	
	Items.ShowBannedPasswordList.Enabled = IsListAvailable;
	Items.ClearBannedPasswordList.Enabled = IsListAvailable;
	Items.ShouldUseAdditionalBannedPasswordList.Title = TitleText;
	
EndProcedure

&AtServer
Procedure FillSettingsInForm(Settings, RecommendedSettingsValues, ForExternalUsers = False)
	
	For Each KeyAndValue In RecommendedSettingsValues Do
		NamesKey = KeyAndValue.Key + ?(ForExternalUsers, "2", "");
		Names = ItemsBySettings.Get(NamesKey);
		If Names = Undefined Then
			Names = New Structure("SettingNameOnForm, TagName",
				KeyAndValue.Key, KeyAndValue.Key);
		EndIf;
		If KeyAndValue.Value = Null Then
			ThisObject[Names.SettingNameOnForm] = Settings[KeyAndValue.Key];
			Continue;
		EndIf;
		SuggestedValue = SuggestedValue(KeyAndValue.Value,, KeyAndValue.Key);
		If ValueIsFilled(Settings[KeyAndValue.Key]) Then
			ThisObject[Names.SettingNameOnForm] = Settings[KeyAndValue.Key];
			If SuggestedValue.Enable Then
				ThisObject[Names.ItemNameInclude] = True;
			EndIf;
		Else
			ThisObject[Names.SettingNameOnForm] = SuggestedValue.Value;
		EndIf;
		If Not ValueIsFilled(Settings[SuggestedValue.Dependence]) Then
			Items[Names.TagName].Enabled = False;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure WriteAtServer()
	
	BeginTransaction();
	Try
		SetNewAdditionalBannedPasswordList();
		Overall = Users.CommonAuthorizationSettingsNewDetails();
		If IsShowInListPropertyBulkChangeConfirmed
		   And Overall.ShowInList <> ShowInList
		   And (    ShowInList = "HiddenAndEnabledForAllUsers"
		      Or ShowInList = "HiddenAndDisabledForAllUsers") Then
			UsersInternal.SetShowInListAttributeForAllInfobaseUsers(
				ShowInList = "HiddenAndEnabledForAllUsers");
		EndIf;
		FillSettingsFromForm(Overall, RecommendedCommonSettingsValues);
		Users.SetCommonAuthorizationSettings(Overall);
		
		UsersSettings = Users.NewDescriptionOfLoginSettings();
		FillSettingsFromForm(UsersSettings, RecommendedSettingsValues);
		Users.SetLoginSettings(UsersSettings);
		
		ExternalUsersSettings = Users.NewDescriptionOfLoginSettings();
		FillSettingsFromForm(ExternalUsersSettings, RecommendedSettingsValues, True);
		Users.SetLoginSettings(ExternalUsersSettings, True);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	NewPasswordListAddressInTempStorage = "";
	
	RefreshReusableValues();
	
EndProcedure

&AtServer
Procedure SetNewAdditionalBannedPasswordList()
	
	If Not ValueIsFilled(NewPasswordListAddressInTempStorage)
	 Or Not UsersInternal.IsSettings8_3_26Available() Then
		Return;
	EndIf;
	
	Rows = GetFromTempStorage(NewPasswordListAddressInTempStorage);
	ManagerOfList = AdditionalAuthenticationSettings.PasswordCompromiseCheckList;
	
	If IsNewListContainsPasswords Then
		ManagerOfList.SetListFromPasswords(Rows);
	Else
		ManagerOfList.SetListFromPasswordsStoredValues(Rows);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillSettingsFromForm(Settings, RecommendedSettingsValues, ForExternalUsers = False)
	
	For Each KeyAndValue In RecommendedSettingsValues Do
		NamesKey = KeyAndValue.Key + ?(ForExternalUsers, "2", "");
		Names = ItemsBySettings.Get(NamesKey);
		If Names = Undefined Then
			Names = New Structure("SettingNameOnForm, TagName",
				KeyAndValue.Key, KeyAndValue.Key);
		EndIf;
		If KeyAndValue.Value = Null Then
			Settings[KeyAndValue.Key] = ThisObject[Names.SettingNameOnForm];
			Continue;
		EndIf;
		SuggestedValue = SuggestedValue(KeyAndValue.Value);
		
		If SuggestedValue.Enable And ThisObject[Names.ItemNameInclude] Then
			Settings[KeyAndValue.Key] = ThisObject[Names.SettingNameOnForm];
		ElsIf SuggestedValue.IsEmptyForbidden Then
			Settings[KeyAndValue.Key] = SuggestedValue.Value;
		ElsIf TypeOf(KeyAndValue.Value) = Type("Number") Then
			Settings[KeyAndValue.Key] = 0;
		ElsIf TypeOf(KeyAndValue.Value) = Type("String") Then
			Settings[KeyAndValue.Key] = "";
		ElsIf TypeOf(KeyAndValue.Value) = Type("Boolean") Then
			Settings[KeyAndValue.Key] = False;
		Else
			Settings[KeyAndValue.Key] = Undefined;
		EndIf;
	EndDo;
	
EndProcedure

&AtServerNoContext
Function CurrentBannedPasswordHashList()
	
	If Not UsersInternal.IsSettings8_3_26Available() Then
		Return "";
	EndIf;
	
	ManagerOfList = AdditionalAuthenticationSettings.PasswordCompromiseCheckList;
	Rows = ManagerOfList.GetPasswordsStoredValuesList();
	
	If TypeOf(Rows) = Type("Array") Then
		Return StrConcat(Rows, Chars.LF);
	EndIf;
	
	Return "";
	
EndFunction

&AtServerNoContext
Function ImportedBannedPasswordList(Address)
	
	Rows = GetFromTempStorage(Address);
	
	Return StrConcat(Rows, Chars.LF);
	
EndFunction

&AtClient
Procedure ShowInListChoiceProcessingCompletion(Response, ValueSelected) Export
	
	If Response = DialogReturnCode.Yes Then
		ShowInList = ValueSelected;
		IsShowInListPropertyBulkChangeConfirmed = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterFileImported(FileThatWasPut, Context) Export
	
	If FileThatWasPut = Undefined Then
		Return;
	EndIf;
	
	Result = ListPreparationPreliminaryResult(FileThatWasPut.Location);
	If TypeOf(Result) <> Type("Array") Then
		ShowMessageBox(, Result);
		Return;
	EndIf;
	
	Buttons = New ValueList;
	Buttons.Add("Passwords", NStr("vi = 'Mật khẩu này';
									|ru = 'Это пароли';
									|en = 'Passwords'; fa = 'Passwords';
									|it = 'Это пароли';
									|pl = 'Passwords';
									|tr = 'Bu parolalar'"));
	Buttons.Add("PasswordsHash", NStr("vi = 'Đây là băm (hash) mật khẩu';
										|ru = 'Это хеши паролей';
										|en = 'Password hashes'; fa = 'Password hashes';
										|it = 'Это хеши паролей';
										|pl = 'Password hashes';
										|tr = 'Bunlar parolalar karmalarıdır'"));
	Buttons.Add("Cancel", NStr("vi = 'Hủy bỏ';
								|ru = 'Отмена';
								|en = 'Cancel'; fa = 'انصراف';
								|it = 'Отмена';
								|pl = 'Cancel';
								|tr = 'İptal'"));
	
	QueryText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Các dòng trong tệp đã chọn:
		           |
		           |%1
		           |
		           |Đây là mật khẩu
		           |hay băm (hash) mật khẩu không (sử dụng thuật toán %2 ở định dạng %3)?';
		           |ru = 'Строки в выбранном файле:
		           |
		           |%1
		           |
		           |Это пароли
		           |или хеши паролей (по алгоритму %2 в формате %3)?';
		           |en = 'Does this file contain passwords or password hashes?
		           |
		           |%1
		           |
		           |(Hash format must be %3 hashed with %2.)'; fa = 'Does this file contain passwords or password hashes?
		           |
		           |%1
		           |
		           |(Hash format must be %3 hashed with %2.)';
		           |it = 'Строки в выбранном файле:
		           |
		           |%1
		           |
		           |Это пароли
		           |или хеши паролей (по алгоритму %2 в формате %3)?';
		           |pl = 'Does this file contain passwords or password hashes?
		           |
		           |%1
		           |
		           |(Hash format must be %3 hashed with %2.)';
		           |tr = 'Seçilen dosyadaki satırlar:
		           |
		           |%1
		           |
		           |Bu şifreler
		           |veya şifre karmaları mı (%3 formatında %2 algoritmasını kullanıyor)?'"),
		StrConcat(Result, Chars.LF), "sha1", "base64");
	
	Notification = New CallbackDescription("AfterFileFormatSelected", ThisObject, FileThatWasPut.Location);
	
	ShowQueryBox(Notification, QueryText, Buttons);
	
EndProcedure

&AtClient
Procedure AfterFileFormatSelected(Response, PutFileAddress) Export
	
	If Response <> "Passwords" And Response <> "PasswordsHash" Then
		Return;
	EndIf;
	
	Text = ListPreparationResult(PutFileAddress, Response);
	ShowMessageBox(, Text);
	
EndProcedure

&AtServerNoContext
Function ListPreparationPreliminaryResult(Val Address)
	
	BinaryData = GetFromTempStorage(Address);
	If TypeOf(BinaryData) <> Type("BinaryData") Then
		Return NStr("vi = 'Không thể nhận dữ liệu tệp';
					|ru = 'Не удалось получить данные файла';
					|en = 'Couldn''t receive the file data'; fa = 'Couldn''t receive the file data';
					|it = 'Не удалось получить данные файла';
					|pl = 'Couldn''t receive the file data';
					|tr = 'Dosya verileri alınamadı.'");
	EndIf;
	
	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Trong phần đầu của tệp, chưa tìm thấy bảng kê chi tiết %1 (%2)';
			|ru = 'В начале файла не найдена спецификация %1 (%2)';
			|en = 'Couldn''t find specification at the beginning of the file:  %1 (with %2)'; fa = 'Couldn''t find specification at the beginning of the file:  %1 (with %2)';
			|it = 'В начале файла не найдена спецификация %1 (%2)';
			|pl = 'Couldn''t find specification at the beginning of the file:  %1 (with %2)';
			|tr = '%1 (%2) spesifikasyonu dosyanın başında bulunamadı'"), "UTF-8", "BOM");
	
	If BinaryData.Size() < 3 Then
		Return ErrorText;
	EndIf;
	
	DataReader = New DataReader(BinaryData);
	BinaryDataBuffer = DataReader.ReadIntoBinaryDataBuffer(3);
	
	If BinaryDataBuffer[0] <> NumberFromHexString("0xEF")
	 Or BinaryDataBuffer[1] <> NumberFromHexString("0xBB")
	 Or BinaryDataBuffer[2] <> NumberFromHexString("0xBF") Then
		
		Return ErrorText;
	EndIf;
	
	Text = GetStringFromBinaryData(BinaryData, TextEncoding.UTF8);
	Rows = StrSplit(Text, Chars.LF + Chars.CR, False);
	AllRows = New Array;
	FirstStrings = New Array;
	
	For Each String In Rows Do
		If Not ValueIsFilled(String) Then
			Continue;
		EndIf;
		String = TrimAll(String);
		AllRows.Add(String);
		If FirstStrings.Count() < 5 Then
			FirstStrings.Add(String);
		EndIf;
	EndDo;
	
	If Not ValueIsFilled(AllRows) Then
		Return NStr("vi = 'Tệp trống';
					|ru = 'Пустой файл';
					|en = 'Empty file'; fa = 'Empty file';
					|it = 'Пустой файл';
					|pl = 'Empty file';
					|tr = 'Boş dosya'");
	EndIf;
	
	If AllRows.Count() > 5 Then
		FirstStrings.Add("...");
	EndIf;
	
	PutToTempStorage(AllRows, Address);
	
	Return FirstStrings;
	
EndFunction

&AtServer
Function ListPreparationResult(Val Address, Val Format)
	
	Rows = GetFromTempStorage(Address);
	
	If Format = "PasswordsHash" Then
		LineNumber = 0;
		For Each String In Rows Do
			LineNumber = LineNumber + 1;
			If Not ValueIsFilled(String) Then
				Continue;
			EndIf;
			Try
				Hash = Base64Value(String);
			Except
				ErrorInfo = ErrorInfo();
				Return StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Nội dung ""%1"" trong dòng %2 không theo định dạng %3 theo nguyên nhân:
					|%4';
					|ru = 'Текст ""%1"" в строке %2 не в формате %3 по причине:
					|%4';
					|en = 'Line %2 (""%1"") format is not %3 due to:
					|%4'; fa = 'Line %2 (""%1"") format is not %3 due to:
					|%4';
					|it = 'Текст ""%1"" в строке %2 не в формате %3 по причине:
					|%4';
					|pl = 'Line %2 (""%1"") format is not %3 due to:
					|%4';
					|tr = '%2 satırındaki ""%1"" metni şu nedenle %3 biçiminde değil:
					|%4'"),
					String,
					Format(LineNumber, "NG="),
					"base64",
					ErrorProcessing.DetailErrorDescription(ErrorInfo));
			EndTry;
			If Hash.Size() = 0 Then
				Return StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Nội dung ""%1"" trong dòng %2 không theo định dạng %3.';
						|ru = 'Текст ""%1"" в строке %2 не в формате %3.';
						|en = 'Line %2 (""%1"") format is not %3.'; fa = 'Line %2 (""%1"") format is not %3.';
						|it = 'Текст ""%1"" в строке %2 не в формате %3.';
						|pl = 'Line %2 (""%1"") format is not %3.';
						|tr = '%2 satırındaki ""%1"" metni %3 biçiminde değil'"),
					String,
					Format(LineNumber, "NG="),
					"base64");
			EndIf;
			If Hash.Size() <> 20 Then
				Return StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Nội dung ""%1"" trong dòng %2 có dữ liệu nhị phân có độ dài %3, không dưới 20 byte';
						|ru = 'Текст ""%1"" в строке %2 содержит двоичные данные длиной %3, а не 20 байт';
						|en = 'Line %2 (""%1"") contains binary data with a length other  than 20 bites: %3'; fa = 'Line %2 (""%1"") contains binary data with a length other  than 20 bites: %3';
						|it = 'Текст ""%1"" в строке %2 содержит двоичные данные длиной %3, а не 20 байт';
						|pl = 'Line %2 (""%1"") contains binary data with a length other  than 20 bites: %3';
						|tr = '%2 satırındaki ""%1"" metni, 20 bayt değil, %3 uzunluğunda ikili veri içeriyor'"),
					String,
					Format(LineNumber, "NG="),
					Format(Hash.Size(), "NG="));
			EndIf;
		EndDo;
	EndIf;
	
	NewPasswordListAddressInTempStorage =
		PutToTempStorage(Rows, UUID);
	IsNewListContainsPasswords = Format <> "PasswordsHash";
	
	RecountPasswordsInAdditionalBannedList(False, Rows.Count());
	
	If Format = "PasswordsHash" Then
		Return NStr("vi = 'Đã kết nhập băm (hash) mật khẩu';
					|ru = 'Хеши паролей загружены';
					|en = 'Password hashes imported'; fa = 'Password hashes imported';
					|it = 'Хеши паролей загружены';
					|pl = 'Password hashes imported';
					|tr = 'Parolaların karmaları yüklendi'");
	EndIf;
	
	Return NStr("vi = 'Đã kết nhập mật khẩu';
				|ru = 'Пароли загружены';
				|en = 'Passwords imported'; fa = 'Passwords imported';
				|it = 'Пароли загружены';
				|pl = 'Passwords imported';
				|tr = 'Parolalar yüklendi'");
	
EndFunction

#EndRegion
