///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Variables

&AtClient
Var NotificationProcessingParameters;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	CurrentUserRef = Users.CurrentUser();
	
	If Not Users.IsFullUser() Then
		ConfigureFormForLimitedUser();
	EndIf;
	
	If NoViewRight Then
		Items.ReportOrWarning.CurrentPage = Items.InsufficientRights;
		Return;
	EndIf;
	
	CurrentInfobaseUser = DataProcessors.UsersSettings.IBUserName(
		CurrentUserRef);
	
	If Parameters.User <> Undefined Then
		
		IBUserID = Common.ObjectAttributeValue(Parameters.User,
			"IBUserID");
		
		SetPrivilegedMode(True);
		IBUser = InfoBaseUsers.FindByUUID(
			IBUserID);
		SetPrivilegedMode(False);
		
		If IBUser = Undefined Then
			Items.ReportOrWarning.CurrentPage = Items.DisplayWarning;
			Return;
		EndIf;
		
		UserRef = Parameters.User;
		Items.UserRef.Visible = False;
		Title = NStr("vi = 'Tùy chỉnh người sử dụng';
					|ru = 'Настройки пользователя';
					|en = 'User settings'; fa = 'تنظیمات کاربر';
					|it = 'Impostazioni dell''utente';
					|pl = 'Ustawienia użytkownika';
					|tr = 'Kullanıcı ayarları'");
	Else
		UserRef = Users.CurrentUser();
	EndIf;
	
	InfoBaseUser = DataProcessors.UsersSettings.IBUserName(UserRef);
	
	UseExternalUsers = GetFunctionalOption("UseExternalUsers");
	
	PersonalSettingsFormName = Common.CommonCoreParameters().PersonalSettingsFormName;
	
	SelectedSettingsPage = Items.SettingsKinds.CurrentPage.Name;
	
EndProcedure

&AtServer
Procedure ConfigureFormForLimitedUser()
	
	Items.Copy.Visible = False;
	Items.CopyToOtherUsers.Visible = False;
	Items.CopyFrom.Visible = False;
	Items.ClearSelectedSettingsGroup.Visible = False;
	Items.InterfaceContextMenuCopy.Visible = False;
	Items.ReportSettingsTreeContextMenuCopy.Visible = False;
	Items.OtherSettingsContextMenuCopy.Visible = False;
	
	NoViewRight = (CurrentUserRef <> Parameters.User);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If Upper(EventName) = Upper("UserSelection") And Source <> FormName Then
		Return;
	EndIf;
	
	NotificationProcessingParameters = New Structure("EventName, Parameter", EventName, Parameter);
	AttachIdleHandler("Attachable_ExecuteNotifyProcessing", 0.1, True);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If NoViewRight
	 Or Items.ReportOrWarning.CurrentPage = Items.DisplayWarning Then
		Return;
	EndIf;
	
	AttachIdleHandler("UpdateSettingsList", 0.1, True);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OnCurrentPageChange(Item, CurrentPage)
	
	SelectedSettingsPage = CurrentPage.Name;
	
EndProcedure

&AtClient
Procedure UserRefStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	FilterParameters = New Structure("ChoiceMode", True);
	
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
		
		UsersTypeSelection.ShowChooseItem(New CallbackDescription(
			"UserRefStartChoiceCompletion", ThisObject, FilterParameters));
	Else
		OpenForm("Catalog.Users.ListForm",
			FilterParameters, Items.UserRef);
	EndIf;
	
EndProcedure

&AtClient
Procedure UserRefStartChoiceCompletion(SelectedOption, FilterParameters) Export
	
	If SelectedOption = Undefined Then
		Return;
	EndIf;
	
	If SelectedOption.Value = "Users" Then
		OpenForm("Catalog.Users.ListForm",
			FilterParameters, Items.UserRef);
		
	ElsIf SelectedOption.Value = "ExternalUsers" Then
		OpenForm("Catalog.ExternalUsers.ListForm",
			FilterParameters, Items.UserRef);
	EndIf;
	
EndProcedure

&AtClient
Procedure ReportAndInterfaceSettingsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	If Not Copy Then
		Cancel = True;
		Return;
	EndIf;
	
	CopySettings();
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure SettingsBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
	QueryText = NStr("vi = 'Xóa tùy chỉnh đã chọn?';
					|ru = 'Очистить выбранные настройки?';
					|en = 'Do you want to clear the selected settings?'; fa = 'Do you want to clear the selected settings?';
					|it = 'Cancellare le impostazioni selezionate?';
					|pl = 'Wyczyścić wybrane ustawienia?';
					|tr = 'Seçilen ayarlar temizlensin mi?'");
	Notification = New CallbackDescription("SettingsBeforeDeleteRowCompletion", ThisObject, Item);
	
	ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo,, DialogReturnCode.Yes);
	
EndProcedure

&AtClient
Procedure SettingsTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	UsersInternalClient.OpenReportOrForm(CurrentItem,
		InfoBaseUser, CurrentInfobaseUser, PersonalSettingsFormName);
	
EndProcedure

&AtClient
Procedure UserRefOnChange(Item)
	
	Items.CommandBar.Enabled = Not IsBlankString(Item.SelectedText);
	
	If SettingsGettingResult() = "NoIBUser" Then
		UserRef = CurrentUserRef;
		
		ShowMessageBox(, StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Người dùng đã chọn ""%1"" không có người dùng infobase
			           |được chỉ định, không thể xem cài đặt của người dùng đó.
			           |Bạn có thể khắc phục sự cố trong thẻ của người dùng này.';
			           |ru = 'У выбранного пользователя ""%1"" не указан
			           |пользователь информационной базы, просмотреть его настройки невозможно.
			           |Устранить проблему можно в карточке данного пользователя.';
			           |en = 'Cannot view the settings of the selected user ""%1""
			           |because it is not mapped to an infobase user.
			           |You can correct this in the user card.'; fa = 'Cannot view the settings of the selected user ""%1""
			           |because it is not mapped to an infobase user.
			           |You can correct this in the user card.';
			           |it = 'Per l''utente selezionato ""%1"" non è indicato
			           |l''utente del database informatico, è impossibile visualizzarne le sue impostazioni.
			           | È possibile risolvere il problema nella scheda di questo utente.';
			           |pl = 'Wybrany użytkownik ""%1"" nie posiada
			           | bazy danych o użytkownikach, niemożliwe jest przejrzenie jej ustawień. 
			           |Możesz rozwiązać problem na karcie użytkownika.';
			           |tr = 'Seçilen ""%1"" kullanıcısı Infobase kullanıcısı tarafından listelenmiyor, 
			           |ayarlarını görüntüleyemiyor. 
			           |Sorunu bu kullanıcının kartında çözebilirsiniz.'"),
			UserRef));
		Return;
	EndIf;
	
	UpdateSettingsList();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Refresh(Command)
	
	UpdateSettingsList();
	
EndProcedure

&AtClient
Procedure CopyToOtherUsers(Command)
	
	CopySettings();
	
EndProcedure

&AtClient
Procedure CopyAllSettings(Command)
	
	SettingsToCopy.Clear();
	
	SettingsToCopy.Add("ReportsSettings",      NStr("vi = 'Tùy chỉnh báo cáo';
													|ru = 'Настройки отчетов';
													|en = 'Report settings'; fa = 'تنظیمات گزارش';
													|it = 'Impostazioni dei report';
													|pl = 'Ustawienia raportów';
													|tr = 'Rapor ayarları'"));
	SettingsToCopy.Add("InterfaceSettings2", NStr("vi = 'Tùy chỉnh hình dạng ngoài';
													|ru = 'Настройки внешнего вида';
													|en = 'Appearance settings'; fa = 'Appearance settings';
													|it = 'Impostazioni del tipo esterno';
													|pl = 'Ustawienia wyglądu';
													|tr = 'Dış görünüm ayarları'"));
	SettingsToCopy.Add("FormData",            NStr("vi = 'Dữ liệu của biểu mẫu';
													|ru = 'Данные форм';
													|en = 'Form data'; fa = 'Form data';
													|it = 'Dati dei modelli';
													|pl = 'Dane form';
													|tr = 'Veriler formu'"));
	SettingsToCopy.Add("PersonalSettings", NStr("vi = 'Tùy chỉnh cá nhân';
												|ru = 'Персональные настройки';
												|en = 'Personal settings'; fa = 'تنظیمات شخصی';
												|it = 'Impostazioni personali';
												|pl = 'Ustawienia osobiste';
												|tr = 'Kişisel ayarlar'"));
	SettingsToCopy.Add("Favorites",             NStr("vi = 'Ưa thích';
													|ru = 'Избранное';
													|en = 'Favorites'; fa = 'Favorites';
													|it = 'Preferiti';
													|pl = 'Favorites';
													|tr = 'Sık kullanılanlar'"));
	SettingsToCopy.Add("PrintSettings",       NStr("vi = 'Tùy chỉnh in';
													|ru = 'Настройки печати';
													|en = 'Print settings'; fa = 'تنظیمات چاپ';
													|it = 'Impostazioni stampa';
													|pl = 'Ustawienia druku';
													|tr = 'Yazdırma ayarları'"));
	SettingsToCopy.Add("OtherUserSettings",
		NStr("vi = 'Tùy chỉnh báo cáo và bộ xử lý bổ sung';
			|ru = 'Настройки дополнительных отчетов и обработок';
			|en = 'Additional report and data processor settings'; fa = 'Additional report and data processor settings';
			|it = 'Impostazioni dei report aggiuntivi ed elaborazioni';
			|pl = 'Ustawienia dodatkowych raportów i traktowania';
			|tr = 'Ek rapor ve veri işlemcisi ayarları'"));
	
	FormParameters = New Structure;
	FormParameters.Insert("User", UserRef);
	FormParameters.Insert("ActionType",  "CopyAll");
	
	SelectUsers(FormParameters);
	
EndProcedure

&AtClient
Procedure CopyReportSettings(Command)
	
	SettingsToCopy.Clear();
	
	SettingsToCopy.Add("ReportsSettings", NStr("vi = 'Tùy chỉnh báo cáo';
												|ru = 'Настройки отчетов';
												|en = 'Report settings'; fa = 'تنظیمات گزارش';
												|it = 'Impostazioni dei report';
												|pl = 'Ustawienia raportów';
												|tr = 'Rapor ayarları'"));
	
	FormParameters = New Structure;
	FormParameters.Insert("User", UserRef);
	FormParameters.Insert("ActionType",  "CopyAll");
	SelectUsers(FormParameters);
	
EndProcedure

&AtClient
Procedure CopyInterfaceSettings(Command)
	
	SettingsToCopy.Clear();
	
	SettingsToCopy.Add("InterfaceSettings2", NStr("vi = 'Tùy chỉnh hình dạng ngoài';
													|ru = 'Настройки внешнего вида';
													|en = 'Appearance settings'; fa = 'Appearance settings';
													|it = 'Impostazioni del tipo esterno';
													|pl = 'Ustawienia wyglądu';
													|tr = 'Dış görünüm ayarları'"));
	
	FormParameters = New Structure;
	FormParameters.Insert("User", UserRef);
	FormParameters.Insert("ActionType",  "CopyAll");
	SelectUsers(FormParameters);
	
EndProcedure

&AtClient
Procedure CopyReportAndInterfaceSettings(Command)
	
	SettingsToCopy.Clear();
	SettingsToCopy.Add("ReportsSettings",      NStr("vi = 'Tùy chỉnh báo cáo';
													|ru = 'Настройки отчетов';
													|en = 'Report settings'; fa = 'تنظیمات گزارش';
													|it = 'Impostazioni dei report';
													|pl = 'Ustawienia raportów';
													|tr = 'Rapor ayarları'"));
	SettingsToCopy.Add("InterfaceSettings2", NStr("vi = 'Tùy chỉnh hình dạng ngoài';
													|ru = 'Настройки внешнего вида';
													|en = 'Appearance settings'; fa = 'Appearance settings';
													|it = 'Impostazioni del tipo esterno';
													|pl = 'Ustawienia wyglądu';
													|tr = 'Dış görünüm ayarları'"));
	
	FormParameters = New Structure;
	FormParameters.Insert("User", UserRef);
	FormParameters.Insert("ActionType",  "CopyAll");
	SelectUsers(FormParameters);
	
EndProcedure

&AtClient
Procedure Clear(Command)
	
	SettingsTree = SelectedSettingsPageFormTable();
	
	If SettingsTree.SelectedRows.Count() = 0 Then
		
		ShowMessageBox(,NStr("vi = 'Hãy chọn tùy chỉnh cần xóa.';
							|ru = 'Выберите настройки, которые требуется удалить.';
							|en = 'Select the settings that you want to delete.'; fa = 'Select the settings that you want to delete.';
							|it = 'Selezionare le impostazioni da eliminare.';
							|pl = 'Wybierz ustawienia, które należy usunąć.';
							|tr = 'Silmek istediğiniz ayarları seçin.'"));
		Return;
		
	EndIf;
	
	Notification = New CallbackDescription("ClearCompletion", ThisObject, SettingsTree);
	QueryText = NStr("vi = 'Xóa tùy chỉnh đã chọn?';
					|ru = 'Очистить выделенные настройки?';
					|en = 'Do you want to clear the selected settings?'; fa = 'Do you want to clear the selected settings?';
					|it = 'Cancellare le impostazioni selezionate?';
					|pl = 'Oczyść wybrane ustawienia?';
					|tr = 'Seçilen ayarlar temizlensin mi?'");
	
	ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo,, DialogReturnCode.Yes);
	
EndProcedure

&AtClient
Procedure ClearSettingsForSelectedUsers(Command)
	
	SettingsTree = SelectedSettingsPageFormTable();
	SelectedRows = SettingsTree.SelectedRows;
	If SelectedRows.Count() = 0 Then
		
		ShowMessageBox(, NStr("vi = 'Hãy chọn tùy chỉnh cần xóa.';
								|ru = 'Выберите настройки, которые требуется удалить.';
								|en = 'Select the settings that you want to delete.'; fa = 'Select the settings that you want to delete.';
								|it = 'Selezionare le impostazioni da eliminare.';
								|pl = 'Wybierz ustawienia, które należy usunąć.';
								|tr = 'Silmek istediğiniz ayarları seçin.'"));
		Return;
		
	EndIf;
	
	QueryText =
		NStr("vi = 'Xóa cài đặt đã chọn?
		           |Một cửa sổ sẽ mở ra để chọn những người dùng cần xóa cài đặt.';
		           |ru = 'Очистить выделенные настройки?
		           |Откроется окно выбора пользователей, которым необходимо очистить настройки.';
		           |en = 'Do you want to clear the selected settings?
		           |This will open the list where you can select the users whose settings will be cleared.'; fa = 'Do you want to clear the selected settings?
		           |This will open the list where you can select the users whose settings will be cleared.';
		           |it = 'Cancellare le impostazioni selezionate?
		           |Si aprirà una finestra per selezionare gli utenti che hanno bisogno di cancellare le impostazioni.';
		           |pl = 'Wyczyść wybrane ustawienia?
		           |Otworzy się okno wyboru użytkowników, ustawienia których należy usunąć.';
		           |tr = 'Seçilen ayarları temizle? 
		           |Ayarları temizlenecek olan kullanıcı seçim penceresi açılacaktır.'");
	
	Notification = New CallbackDescription("ClearSettingsForSelectedUsersCompletion", ThisObject);
	
	ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo,, DialogReturnCode.Yes);
	
EndProcedure

&AtClient
Procedure ClearAllSettings(Command)
	
	QueryText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Xóa tất cả tùy chỉnh của người sử dụng ""%1""?';
			|ru = 'Очистить все настройки у пользователя ""%1""?';
			|en = 'Do you want to clear all settings for user ""%1""?'; fa = 'Do you want to clear all settings for user ""%1""?';
			|it = 'Cancellare tutte le impostazioni dell''utente ""%1""?';
			|pl = 'Wyczyść wszystkie ustawienia użytkownika ""%1""?';
			|tr = '""%1"" kullanıcısının tüm ayarları temizlensin mi?'"), String(UserRef));
	
	QuestionButtons = New ValueList;
	QuestionButtons.Add("Clear", NStr("vi = 'Xóa';
										|ru = 'Очистить';
										|en = 'Clear'; fa = 'پاک کردن';
										|it = 'Cancellare';
										|pl = 'Clear';
										|tr = 'Temizle'"));
	QuestionButtons.Add("Cancel",   NStr("vi = 'Hủy bỏ';
										|ru = 'Отмена';
										|en = 'Cancel'; fa = 'انصراف';
										|it = 'Annulla';
										|pl = 'Cancel';
										|tr = 'İptal'"));
	
	Notification = New CallbackDescription("ClearAllSettingsCompletion", ThisObject);
	
	ShowQueryBox(Notification, QueryText, QuestionButtons,, QuestionButtons[1].Value);
	
EndProcedure

&AtClient
Procedure ClearObsoleteSettings(Command)
	
	QueryText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Xóa các tùy chỉnh cũ của người sử dụng ""%1""?';
			|ru = 'Очистить устаревшие настройки у пользователя ""%1""?';
			|en = 'Clear obsolete settings for the ""%1"" users?'; fa = 'Clear obsolete settings for the ""%1"" users?';
			|it = 'Cancellare le impostazioni obsolete dell''utente ""%1""?';
			|pl = 'Wyczyść przestarzałe ustawienia użytkownika ""%1""?';
			|tr = '""%1"" kullanıcısı için eski ayarlar silinsin mi?'"), String(UserRef));
	
	QuestionButtons = New ValueList;
	QuestionButtons.Add("Clear", NStr("vi = 'Xóa bỏ';
										|ru = 'Очистить';
										|en = 'Clear the settings.'; fa = 'Clear the settings.';
										|it = 'Cancellare';
										|pl = 'Clear the settings.';
										|tr = 'Temizle'"));
	QuestionButtons.Add("Cancel",   NStr("vi = 'Hủy bỏ';
										|ru = 'Отмена';
										|en = 'Cancel'; fa = 'انصراف';
										|it = 'Annulla';
										|pl = 'Cancel';
										|tr = 'İptal'"));
	
	Notification = New CallbackDescription("ClearObsoleteSettingsCompletion", ThisObject);
	
	ShowQueryBox(Notification, QueryText, QuestionButtons,, QuestionButtons[1].Value);
	
EndProcedure

&AtClient
Procedure ClearReportAndInterfaceSettings(Command)
	
	QueryText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Xóa tất cả tùy chỉnh báo cáo và hình dạng ngoài của người sử dụng ""%1""?';
			|ru = 'Очистить все настройки отчетов и внешнего вида у пользователя ""%1""?';
			|en = 'Do you want to clear all appearance and report settings for user ""%1""?'; fa = 'Do you want to clear all appearance and report settings for user ""%1""?';
			|it = 'Cancellare tutte le impostazioni dei report e del tipo esterno dell''utente ""%1""?';
			|pl = 'Wyczyść wszystkie ustawienia raportu i konta użytkownika ""%1""?';
			|tr = '""%1"" kullanıcısının tüm arayüz ve rapor ayarları temizlensin mi?'"),
		String(UserRef));
	
	QuestionButtons = New ValueList;
	QuestionButtons.Add("Clear", NStr("vi = 'Xóa';
										|ru = 'Очистить';
										|en = 'Clear'; fa = 'پاک کردن';
										|it = 'Cancellare';
										|pl = 'Clear';
										|tr = 'Temizle'"));
	QuestionButtons.Add("Cancel",   NStr("vi = 'Hủy bỏ';
										|ru = 'Отмена';
										|en = 'Cancel'; fa = 'انصراف';
										|it = 'Annulla';
										|pl = 'Cancel';
										|tr = 'İptal'"));
	
	Notification = New CallbackDescription("ClearReportAndInterfaceSettingsCompletion", ThisObject);
	
	ShowQueryBox(Notification, QueryText, QuestionButtons,, QuestionButtons[1].Value);
	
EndProcedure

&AtClient
Procedure OpenSettingsItem(Command)
	
	UsersInternalClient.OpenReportOrForm(CurrentItem,
		InfoBaseUser, CurrentInfobaseUser, PersonalSettingsFormName);
	
EndProcedure

&AtClient
Procedure ClearSettingsForAllUsers(Command)
	
	QueryText =
		NStr("vi = 'Tất cả cài đặt của tất cả người dùng bây giờ sẽ bị xóa.
		           |Tiếp tục?';
		           |ru = 'Сейчас будут очищены все настройки всех пользователей.
		           |Продолжить?';
		           |en = 'All settings of all users will be cleared.
		           |Do you want to continue?'; fa = 'All settings of all users will be cleared.
		           |Do you want to continue?';
		           |it = 'Tutte le impostazioni per tutti gli utenti verranno ora cancellate.
		           |Continuare?';
		           |pl = 'Teraz wszystkie ustawienia wszystkich użytkowników zostaną wyczyszczone.
		           |Kontynuuj?';
		           |tr = 'Tüm kullanıcıların tüm ayarları silinecek.
		           |Devam edilsin mi?'");
	
	QuestionButtons = New ValueList;
	QuestionButtons.Add("ClearAll", NStr("vi = 'Xóa tất cả';
										|ru = 'Очистить все';
										|en = 'Clear all'; fa = 'پاک کردن همه';
										|it = 'Cancellare tutto';
										|pl = 'Oczyść wszystkie';
										|tr = 'Tümünü temizle'"));
	QuestionButtons.Add("Cancel",      NStr("vi = 'Hủy bỏ';
											|ru = 'Отмена';
											|en = 'Cancel'; fa = 'انصراف';
											|it = 'Annulla';
											|pl = 'Cancel';
											|tr = 'İptal'"));
	
	Notification = New CallbackDescription("ClearSettingsForAllUsersCompletion", ThisObject);
	ShowQueryBox(Notification, QueryText, QuestionButtons,, QuestionButtons[1].Value);
	
EndProcedure

&AtClient
Procedure ClearObsoleteSettingsOfAllUsers(Command)
	
	QueryText =
		NStr("vi = 'Bây giờ sẽ xóa các tùy chỉnh cũ của tất cả người sử dụng.
		           |Tiếp tục?';
		           |ru = 'Сейчас будут очищены устаревшие настройки всех пользователей.
		           |Продолжить?';
		           |en = 'Obsolete settings for all users will be cleared.
		           |Continue?'; fa = 'Obsolete settings for all users will be cleared.
		           |Continue?';
		           |it = 'Adesso saranno eliminate le impostazioni obsolete di tutti gli utenti.
		           |Continuare?';
		           |pl = 'Teraz przestarzałe ustawienia wszystkich użytkowników zostaną wyczyszczone.
		           |Kontynuować?';
		           |tr = 'Tüm kullanıcıların eski ayarları şimdi silinecek.
		           | Devam edilsin mi?'");
	
	QuestionButtons = New ValueList;
	QuestionButtons.Add("ClearAll", NStr("vi = 'Xóa tất cả';
										|ru = 'Очистить все';
										|en = 'Clear all'; fa = 'پاک کردن همه';
										|it = 'Cancellare tutto';
										|pl = 'Oczyść wszystkie';
										|tr = 'Tümünü temizle'"));
	QuestionButtons.Add("Cancel",      NStr("vi = 'Hủy bỏ';
											|ru = 'Отмена';
											|en = 'Cancel'; fa = 'انصراف';
											|it = 'Annulla';
											|pl = 'Cancel';
											|tr = 'İptal'"));
	
	Notification = New CallbackDescription("ClearObsoleteSettingsOfAllUsersCompletion", ThisObject);
	ShowQueryBox(Notification, QueryText, QuestionButtons,, QuestionButtons[1].Value);
	
EndProcedure

&AtClient
Procedure CopyFrom(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("User",       UserRef);
	FormParameters.Insert("FormOpeningMode", "CopyFrom");
	
	OpenForm("DataProcessor.UsersSettings.Form.CopyUsersSettings", FormParameters);
	
EndProcedure

#EndRegion

#Region Private

#Region ProceduresAndFunctionsToOutputSettingsLists

&AtClient
Procedure UpdateSettingsList()
	
	Items.QuickSearch.Enabled = False;
	Items.CommandBar.Enabled = False;
	Items.TimeConsumingOperationPages.CurrentPage = Items.TimeConsumingOperationPage;
	
	Result = UpdatingSettingsList();
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	
	CallbackOnCompletion = New CallbackDescription("UpdateSettingsListCompletion", ThisObject);
	
	TimeConsumingOperationsClient.WaitCompletion(Result, CallbackOnCompletion, IdleParameters);
	
EndProcedure

&AtServer
Function UpdatingSettingsList()
	
	If ValueIsFilled(JobID) Then
		TimeConsumingOperations.CancelJobExecution(JobID);
	EndIf;
	
	TimeConsumingOperationParameters = TimeConsumingOperationParameters();
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.WaitCompletion = 0; // Run immediately.
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Cập nhật tùy chỉnh người sử dụng';
														|ru = 'Обновление настроек пользователей';
														|en = 'Update user settings'; fa = 'Update user settings';
														|it = 'Aggiornamento delle impostazioni utenti';
														|pl = 'Aktualizacja ustawień użytkowników';
														|tr = 'Kullanıcı ayarlarının güncellenmesi'");
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground("UsersInternal.FillSettingsLists",
		TimeConsumingOperationParameters, ExecutionParameters);
	
	If TimeConsumingOperation.Status = "Running" Then
		JobID = TimeConsumingOperation.JobID; 
	EndIf;
	
	Return TimeConsumingOperation;
	
EndFunction

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure UpdateSettingsListCompletion(Result, AdditionalParameters) Export
	
	Items.TimeConsumingOperationPages.CurrentPage = Items.SettingsPage;
	Items.QuickSearch.Enabled = True;
	Items.CommandBar.Enabled = True;
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		FillSettings(Result.ResultAddress);
		AttachIdleHandler("Attachable_ExpandValueTree", 0.1, True);
		
	ElsIf Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(
			Result.ErrorInfo);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillSettings(Val ResultAddress)
	
	Result = GetFromTempStorage(ResultAddress);
	
	ValueToFormAttribute(Result.ReportSettingsTree, "ReportsSettings");
	ValueToFormAttribute(Result.UserReportOptions, "UserReportOptionTable");
	ValueToFormAttribute(Result.InterfaceSettings2, "Interface");
	ValueToFormAttribute(Result.OtherSettingsTree, "OtherSettings");
	
	CalculateSettingsCount();
	
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsToEvaluateSettingsCount

&AtServer
Procedure CalculateSettingsCount()
	
	SettingsList = ReportsSettings.GetItems();
	SettingsCount = SettingsInTreeCount(SettingsList);
	
	If SettingsCount <> 0 Then
		Items.ReportSettingsPage.Title =
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Tùy chỉnh báo cáo (%1)';
					|ru = 'Настройки отчетов (%1)';
					|en = 'Report settings (%1)'; fa = 'Report settings (%1)';
					|it = 'Impostazioni dei report (%1)';
					|pl = 'Ustawienia raportów (%1)';
					|tr = 'Rapor ayarları (%1)'"), SettingsCount);
	Else
		Items.ReportSettingsPage.Title = NStr("vi = 'Tùy chỉnh báo cáo';
												|ru = 'Настройки отчетов';
												|en = 'Report settings'; fa = 'تنظیمات گزارش';
												|it = 'Impostazioni dei report';
												|pl = 'Ustawienia raportów';
												|tr = 'Rapor ayarları'");
	EndIf;
	
	SettingsList = Interface.GetItems();
	SettingsCount = SettingsInTreeCount(SettingsList);
	
	If SettingsCount <> 0 Then
		Items.InterfacePage.Title =
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Hình dạng ngoài (%1)';
					|ru = 'Внешний вид (%1)';
					|en = 'Appearance (%1)'; fa = 'Appearance (%1)';
					|it = 'Tipo esterno (%1)';
					|pl = 'Widok zewnętrzny (%1)';
					|tr = 'Dış görünüş (%1)'"), SettingsCount);
	Else
		Items.InterfacePage.Title = NStr("vi = 'Hình dạng ngoài';
										|ru = 'Внешний вид';
										|en = 'Appearance'; fa = 'ظاهر';
										|it = 'Tipo esterno';
										|pl = 'Wygląd';
										|tr = 'Dış görünüş'");
	EndIf;
	
	SettingsList = OtherSettings.GetItems();
	SettingsCount = SettingsInTreeCount(SettingsList);
	
	If SettingsCount <> 0 Then
		Items.OtherSettingsPage.Title =
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Tùy chỉnh khác (%1)';
					|ru = 'Прочие настройки (%1)';
					|en = 'Other settings (%1)'; fa = 'Other settings (%1)';
					|it = 'Altre impostazioni (%1)';
					|pl = 'Pozostałe ustawienia (%1)';
					|tr = 'Diğer ayarlar (%1)'"), SettingsCount);
	Else
		Items.OtherSettingsPage.Title = NStr("vi = 'Tùy chỉnh khác';
											|ru = 'Прочие настройки';
											|en = 'Other settings'; fa = 'سایر تنظیمات';
											|it = 'Altre impostazioni';
											|pl = 'Inne ustawienia';
											|tr = 'Diğer ayarlar'");
	EndIf;
	
EndProcedure

&AtServer
Function SettingsInTreeCount(SettingsList)
	
	SettingsCount = 0;
	For Each Setting In SettingsList Do
		
		SubordinateSettingsCount = Setting.GetItems().Count();
		If SubordinateSettingsCount = 0 Then
			SettingsCount = SettingsCount + 1;
		Else
			SettingsCount = SettingsCount + SubordinateSettingsCount;
		EndIf;
		
	EndDo;
	
	Return SettingsCount;
EndFunction

#EndRegion

#Region ProceduresAndFunctionsToCopyDeleteAndClearSettings

&AtServer
Procedure CopyAtServer(UsersDestination, ReportPersonalizationCount, Report)
	
	Result = SelectedSettings1();
	SelectedReportOptionsTable = New ValueTable;
	SelectedReportOptionsTable.Columns.Add("Presentation");
	SelectedReportOptionsTable.Columns.Add("StandardProcessing");
	
	If SelectedSettingsPage = "ReportSettingsPage" Then
		
		For Each Setting In Result.SettingsArray Do
			
			For Each Item In Setting Do
				
				If Item.Check Then
					ReportPersonalizationCount = ReportPersonalizationCount + 1;
					ReportKey = StringFunctionsClientServer.SubstituteParametersToString(Item.Value, "/");
					
					FilterParameter = New Structure("ObjectKey", ReportKey[0]);
					RowsArray = UserReportOptionTable.FindRows(FilterParameter);
					
					If RowsArray.Count() <> 0 Then
						TableRow = SelectedReportOptionsTable.Add();
						TableRow.Presentation = RowsArray[0].Presentation;
						TableRow.StandardProcessing = True;
					EndIf;
					
				EndIf;
				
			EndDo;
			
		EndDo;
		
		NotCopiedReportSettings = New ValueTable;
		NotCopiedReportSettings.Columns.Add("User");
		NotCopiedReportSettings.Columns.Add("ReportsList", New TypeDescription("ValueList"));
		
		DataProcessors.UsersSettings.CopyReportAndPersonalSettings(
			ReportsUserSettingsStorage,
			InfoBaseUser,
			UsersDestination,
			Result.SettingsArray,
			NotCopiedReportSettings);
		
		// Copy report options.
		DataProcessors.UsersSettings.CopyReportOptions(Result.ReportOptionArray,
			UserReportOptionTable, InfoBaseUser, UsersDestination);
			
		If NotCopiedReportSettings.Count() <> 0
		 Or UserReportOptionTable.Count() <> 0 Then
			
			Report = DataProcessors.UsersSettings.CreateReportOnCopyingSettings(
				NotCopiedReportSettings, SelectedReportOptionsTable);
		EndIf;
		
	ElsIf SelectedSettingsPage = "InterfacePage" Then
		DataProcessors.UsersSettings.CopyInterfaceSettings(InfoBaseUser,
			UsersDestination, Result.SettingsArray);
	Else
		
		If Result.PersonalSettingsArray.Count() <> 0 Then
			DataProcessors.UsersSettings.CopyReportAndPersonalSettings(
				CommonSettingsStorage,
				InfoBaseUser,
				UsersDestination,
				Result.PersonalSettingsArray);
		EndIf;
			
		If Result.UserSettingsArray.Count() <> 0 Then
			
			For Each OtherUserSettings In Result.UserSettingsArray Do
				For Each DestinationUser In UsersDestination Do
					
					UserInfo = New Structure;
					UserInfo.Insert("UserRef", DestinationUser);
					UserInfo.Insert("InfoBaseUserName",
						DataProcessors.UsersSettings.IBUserName(DestinationUser));
					
					UsersInternal.OnSaveOtherUserSettings(
						UserInfo, OtherUserSettings);
				EndDo;
			EndDo;
		EndIf;
		
		DataProcessors.UsersSettings.CopyInterfaceSettings(
			InfoBaseUser, UsersDestination, Result.SettingsArray);
	EndIf;
	
EndProcedure

&AtServer
Procedure CopyAllSettingsAtServer(User, UsersDestination, SettingsArray, Report)
	
	NotCopiedReportSettings = New ValueTable;
	NotCopiedReportSettings.Columns.Add("User");
	NotCopiedReportSettings.Columns.Add("ReportsList", New TypeDescription("ValueList"));
	
	DataProcessors.UsersSettings.CopyUsersSettings(
		UserRef, UsersDestination, SettingsArray, NotCopiedReportSettings);
		
	If NotCopiedReportSettings.Count() <> 0
	 Or UserReportOptionTable.Count() <> 0 Then
		
		Report = DataProcessors.UsersSettings.CreateReportOnCopyingSettings(
			NotCopiedReportSettings, UserReportOptionTable);
	EndIf;
	
EndProcedure

&AtServer
Procedure ClearAtServer(Users = Undefined, SelectedUsers1 = False)
	
	Result = SelectedSettings1();
	StorageDescription = SettingsStorageForSelectedPage();
	
	If SelectedUsers1 Then
		
		DataProcessors.UsersSettings.DeleteSettingsForSelectedUsers(Users,
			Result.SettingsArray, StorageDescription);
		
		If Result.PersonalSettingsArray.Count() <> 0 Then
			DataProcessors.UsersSettings.DeleteSettingsForSelectedUsers(Users,
				Result.PersonalSettingsArray, "CommonSettingsStorage");
		EndIf;
		
		Return;
	EndIf;
	
	// Clear settings.
	UserInfo = New Structure;
	UserInfo.Insert("InfoBaseUserName", InfoBaseUser);
	UserInfo.Insert("UserRef", UserRef);
	
	DataProcessors.UsersSettings.DeleteSelectedSettings(UserInfo,
		Result.SettingsArray, StorageDescription);
	
	If Result.PersonalSettingsArray.Count() <> 0 Then
		DataProcessors.UsersSettings.DeleteSelectedSettings(UserInfo,
			Result.PersonalSettingsArray, "CommonSettingsStorage");
	EndIf;
	
	If Result.UserSettingsArray.Count() <> 0 Then
		
		For Each OtherUserSettings In Result.UserSettingsArray Do
			UsersInternal.OnDeleteOtherUserSettings(
				UserInfo, OtherUserSettings);
		EndDo;
	EndIf;
	
	// Clear report options.
	If SelectedSettingsPage = "ReportSettingsPage" Then
		
		DataProcessors.UsersSettings.DeleteReportOptions(Result.ReportOptionArray,
			UserReportOptionTable, InfoBaseUser);
	EndIf;
	
EndProcedure

&AtServer
Procedure ClearAllSettingsAtServer(SettingsToClear, ClearAll = False)
	
	UsersArray = New Array;
	UsersArray.Add(UserRef);
	
	DataProcessors.UsersSettings.DeleteUserSettings(SettingsToClear,
		UsersArray, UserReportOptionTable, ClearAll);
	
EndProcedure

&AtServer
Procedure ClearOutdatedSettingsOnTheServer()
	
	UsersArray = New Array;
	UsersArray.Add(UserRef);
	
	DataProcessors.UsersSettings.DeleteOutdatedUserSettings(UsersArray);
	
EndProcedure

&AtServer
Procedure ClearAllUserSettingsAtServer()
	
	SettingsToClear = New Array;
	SettingsToClear.Add("ReportsSettings");
	SettingsToClear.Add("InterfaceSettings2");
	SettingsToClear.Add("PersonalSettings");
	SettingsToClear.Add("FormData");
	SettingsToClear.Add("Favorites");
	SettingsToClear.Add("PrintSettings");
	
	UsersArray = New Array;
	UsersTable = New ValueTable;
	UsersTable.Columns.Add("User");
	UsersTable.Columns.Add("Department");
	UsersTable.Columns.Add("Individual");
	
	UsersTable = DataProcessors.UsersSettings.UsersToCopy("",
		UsersTable, False, True);
	
	For Each TableRow In UsersTable Do
		UsersArray.Add(TableRow.User);
	EndDo;
	
	DataProcessors.UsersSettings.DeleteUserSettings(SettingsToClear, UsersArray,, True);
	
EndProcedure

&AtServer
Procedure ClearOutdatedSettingsOfAllUsersOnTheServer()
	
	DataProcessors.UsersSettings.DeleteOutdatedUserSettings(Undefined);
	
EndProcedure

&AtClient
Procedure DeleteSettingsFromValueTree(SelectedRows)
	
	For Each SelectedRow In SelectedRows Do
		
		If SelectedSettingsPage = "ReportSettingsPage" Then
			DeleteSettingsRow(ReportsSettings, SelectedRow);
			
		ElsIf SelectedSettingsPage = "InterfacePage" Then
			DeleteSettingsRow(Interface, SelectedRow);
		Else
			DeleteSettingsRow(OtherSettings, SelectedRow);
		EndIf;
		
	EndDo;
	
	CalculateSettingsCount();
EndProcedure

&AtClient
Procedure ClearCompletion(Response, SettingsTree) Export
	
	If Response = DialogReturnCode.No Then
		Return;
	EndIf;
	
	SelectedRows = SettingsTree.SelectedRows;
	SettingsCount = CopiedOrDeletedSettingsCount(SettingsTree);
	
	ClearAtServer();
	CommonClient.RefreshApplicationInterface();
	
	If SettingsCount = 1 Then
		
		SettingName1 = SettingsTree.CurrentData.Setting;
		If StrLen(SettingName1) > 24 Then
			SettingName1 = Left(SettingName1, 24) + "...";
		EndIf;
		
	EndIf;
	
	DeleteSettingsFromValueTree(SelectedRows);
	
	NotifyDeletion(SettingsCount, SettingName1);
	
EndProcedure

#EndRegion

#Region AuxiliaryProceduresAndFunctions

&AtClient
Procedure Attachable_ExecuteNotifyProcessing()
	
	EventName = NotificationProcessingParameters.EventName;
	Parameter   = NotificationProcessingParameters.Parameter;
	
	If Upper(EventName) = Upper("SettingsCopied1") Then
		UpdateSettingsList();
		CommonClient.RefreshApplicationInterface();
		Return;
	EndIf;
	
	If Upper(EventName) <> Upper("UserSelection") Then
		Return;
	EndIf;
	
	UsersDestination = Parameter.UsersDestination;
	UsersCount = UsersDestination.Count();
	
	SettingsCopiedToNote = UsersInternalClient.UsersNote(
		UsersCount, UsersDestination[0]);
	
	NotificationText1     = NStr("vi = 'Sao chép tùy chỉnh';
								|ru = 'Копирование настроек';
								|en = 'Copy settings'; fa = 'کپی تنظیمات';
								|it = 'Copia delle impostazioni';
								|pl = 'Kopiowanie ustawień';
								|tr = 'Ayarları kopyala'");
	NotificationPicture  = PictureLib.DialogInformation;
	
	If Parameter.CopyAll Then
		
		SettingsArray = New Array;
		SettingsNames = "";
		For Each Setting In SettingsToCopy Do 
			
			SettingsNames = SettingsNames + Lower(Setting.Presentation) + ", ";
			SettingsArray.Add(Setting.Value);
			
		EndDo;
		
		SettingsNames = Left(SettingsNames, StrLen(SettingsNames)-2);
		
		If SettingsArray.Count() = 7 Then
			NotificationComment = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã sao chép tất cả tùy chỉnh %1';
					|ru = 'Скопированы все настройки %1';
					|en = 'All settings are copied to %1.'; fa = 'All settings are copied to %1.';
					|it = 'Tutte le impostazioni sono copiate %1';
					|pl = 'Skopiowane wszystkie ustawienia %1';
					|tr = 'Tüm ayarlar kopyalandı %1'"), SettingsCopiedToNote);
		Else
			NotificationComment = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = '%1 đã sao chép %2';
					|ru = '%1 скопированы %2';
					|en = '%1 copied to %2'; fa = '%1 copied to %2';
					|it = '%1 copiate %2';
					|pl = '%1 skopiowane %2';
					|tr = '%1 kopyalandı %2'"), SettingsNames, SettingsCopiedToNote);
		EndIf;
		
		Report = Undefined;
		CopyAllSettingsAtServer(InfoBaseUser,
			UsersDestination, SettingsArray, Report);
		
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
			
			Notification = New CallbackDescription("NotificationProcessingShowQueryBox", ThisObject, Report);
			ShowQueryBox(Notification, QueryText, QuestionButtons,, QuestionButtons[0].Value);
			
			Return;
		EndIf;
		
		ShowUserNotification(NotificationText1, , NotificationComment, NotificationPicture);
		Return;
	EndIf;
	
	If Parameter.SettingsClearing Then
		
		SettingsTree = SelectedSettingsPageFormTable();
		SettingsCount = CopiedOrDeletedSettingsCount(SettingsTree);
		
		ClearAtServer(UsersDestination, True);
		
		If SettingsCount = 1 Then
			
			SettingName1 = SettingsTree.CurrentData.Setting;
			If StrLen(SettingName1) > 24 Then
				SettingName1 = Left(SettingName1, 24) + "...";
			EndIf;
			
		EndIf;
		
		UsersCount = Parameter.UsersDestination.Count();
		NotifyDeletion(SettingsCount, SettingName1, UsersCount);
		Return;
	EndIf;
	
	SettingsTree = SelectedSettingsPageFormTable();
	SettingsCount = CopiedOrDeletedSettingsCount(SettingsTree);
	
	ReportPersonalizationCount = 0;
	Report = Undefined;
	CopyAtServer(UsersDestination, ReportPersonalizationCount, Report);
	
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
		
		Notification = New CallbackDescription("NotificationProcessingShowQueryBox", ThisObject, Report);
		ShowQueryBox(Notification, QueryText, QuestionButtons,, QuestionButtons[0].Value);
		Return;
	Else
		
		If SettingsCount = 1 Then
			SettingPresentation = SettingsTree.CurrentData.Setting;
		EndIf;
		
		NotificationComment = UsersInternalClient.GenerateNoteOnCopy(
			SettingPresentation, SettingsCount, SettingsCopiedToNote);
		
		ShowUserNotification(NotificationText1, , NotificationComment, NotificationPicture);
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectUsers(ChoiceParameters)
	
	ChoiceParameters.Insert("Source", FormName);
	OpenForm("DataProcessor.UsersSettings.Form.SelectUsers", ChoiceParameters);
	
EndProcedure

&AtClient
Procedure ClearSettingsForSelectedUsersCompletion(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.No Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("User", UserRef);
	FormParameters.Insert("ActionType",  "Clearing");
	SelectUsers(FormParameters);
	
EndProcedure

&AtClient
Procedure ClearSettingsForAllUsersCompletion(Response, AdditionalParameters) Export
	
	If Response = "Cancel" Then
		Return;
	EndIf;
	
	ClearAllUserSettingsAtServer();
	CommonClient.RefreshApplicationInterface();
	
	ShowUserNotification(NStr("vi = 'Xóa tùy chỉnh';
								|ru = 'Очистка настроек';
								|en = 'Clear settings'; fa = 'پاک کردن تنظیمات';
								|it = 'Cancellazione delle impostazioni';
								|pl = 'Oczyszczenie ustawień';
								|tr = 'Temizleme ayarları'"), ,
		NStr("vi = 'Đã xóa tất cả tùy chỉnh của tất cả người sử dụng';
			|ru = 'Очищены все настройки всех пользователя';
			|en = 'All settings of all users are cleared.'; fa = 'All settings of all users are cleared.';
			|it = 'Tutte le impostazioni degli utenti sono cancellate';
			|pl = 'Wyczyszczone wszystkie ustawienia każdego użytkownika';
			|tr = 'Tüm kullanıcıların tüm ayarları silindi.'"), PictureLib.DialogInformation);
	
EndProcedure

&AtClient
Procedure ClearObsoleteSettingsOfAllUsersCompletion(Response, AdditionalParameters) Export
	
	If Response = "Cancel" Then
		Return;
	EndIf;
	
	ClearOutdatedSettingsOfAllUsersOnTheServer();
	CommonClient.RefreshApplicationInterface();
	
	ShowUserNotification(NStr("vi = 'Xóa tùy chỉnh';
								|ru = 'Очистка настроек';
								|en = 'Clear settings'; fa = 'پاک کردن تنظیمات';
								|it = 'Cancellazione delle impostazioni';
								|pl = 'Oczyszczenie ustawień';
								|tr = 'Temizleme ayarları'"), ,
		NStr("vi = 'Đã xóa các tùy chỉnh cũ của tất cả người sử dụng';
			|ru = 'Очищены устаревшие настройки всех пользователя';
			|en = 'Obsolete settings are cleared for all users'; fa = 'Obsolete settings are cleared for all users';
			|it = 'Sono state eliminate le impostazioni obsolete di tutti gli utenti';
			|pl = 'Wyczyszczono przestarzałe ustawienia wszystkich użytkowników';
			|tr = 'Tüm kullanıcılar için eski ayarlar temizlendi'"), PictureLib.DialogInformation);
	
EndProcedure

&AtClient
Procedure ClearAllSettingsCompletion(Response, AdditionalParameters) Export
	
	If Response = "Cancel" Then
		Return;
	EndIf;
	
	SettingsToClear = New Array;
	SettingsToClear.Add("ReportsSettings");
	SettingsToClear.Add("InterfaceSettings2");
	SettingsToClear.Add("FormData");
	SettingsToClear.Add("PersonalSettings");
	SettingsToClear.Add("Favorites");
	SettingsToClear.Add("PrintSettings");
	SettingsToClear.Add("OtherUserSettings");
	
	ClearAllSettingsAtServer(SettingsToClear, True);
	CommonClient.RefreshApplicationInterface();
	UpdateSettingsList();
	
	ExplanationText = NStr("vi = 'Đã xóa tất cả tùy chỉnh của người sử dụng ""%1""';
							|ru = 'Очищены все настройки пользователя ""%1""';
							|en = 'All settings of user ""%1"" are cleared.'; fa = 'All settings of user ""%1"" are cleared.';
							|it = 'Sono cancellate tutte le impostazioni dell''utente ""%1""';
							|pl = 'Wyczyszczone wszystkie ustawienia użytkownika ""%1""';
							|tr = '""%1"" kullanıcıya ait tüm ayarlar temizlendi'");
	ExplanationText = StringFunctionsClientServer.SubstituteParametersToString(ExplanationText, UserRef);
	ShowUserNotification(NStr("vi = 'Xóa tùy chỉnh';
								|ru = 'Очистка настроек';
								|en = 'Clear settings'; fa = 'پاک کردن تنظیمات';
								|it = 'Cancellazione delle impostazioni';
								|pl = 'Oczyszczenie ustawień';
								|tr = 'Temizleme ayarları'"), , ExplanationText, PictureLib.DialogInformation);
	
EndProcedure

&AtClient
Procedure ClearObsoleteSettingsCompletion(Response, AdditionalParameters) Export
	
	If Response = "Cancel" Then
		Return;
	EndIf;
	
	ClearOutdatedSettingsOnTheServer();
	CommonClient.RefreshApplicationInterface();
	UpdateSettingsList();
	
	ExplanationText = NStr("vi = 'Đã xóa các tùy chỉnh cũ của người sử dụng ""%1""';
							|ru = 'Очищены устаревшие настройки пользователя ""%1""';
							|en = 'Obsolete settings are cleared for the ""%1"" user'; fa = 'Obsolete settings are cleared for the ""%1"" user';
							|it = 'Sono state eliminate le impostazioni obsolete dell''utente ""%1""';
							|pl = 'Wyczyszczono przestarzałe ustawienia użytkownika ""%1""';
							|tr = 'Eski kullanıcı ayarları temizlendi ""%1""'");
	ExplanationText = StringFunctionsClientServer.SubstituteParametersToString(ExplanationText, UserRef);
	ShowUserNotification(NStr("vi = 'Xóa tùy chỉnh';
								|ru = 'Очистка настроек';
								|en = 'Clear settings'; fa = 'پاک کردن تنظیمات';
								|it = 'Cancellazione delle impostazioni';
								|pl = 'Oczyszczenie ustawień';
								|tr = 'Temizleme ayarları'"), , ExplanationText, PictureLib.DialogInformation);
	
EndProcedure

&AtClient
Procedure ClearReportAndInterfaceSettingsCompletion(Response, AdditionalParameters) Export
	
	If Response = "Cancel" Then
		Return;
	EndIf;
	
	SettingsToClear = New Array;
	SettingsToClear.Add("ReportsSettings");
	SettingsToClear.Add("InterfaceSettings2");
	SettingsToClear.Add("FormData");
	
	ClearAllSettingsAtServer(SettingsToClear);
	CommonClient.RefreshApplicationInterface();
	
	ExplanationText = NStr("vi = 'Đã xóa tất cả tùy chỉnh báo cáo và hình dạng ngoài của người sử dụng ""%1""';
							|ru = 'Очищены все настройки отчетов и внешнего вида у пользователя ""%1""';
							|en = 'All appearance and report settings for user ""%1"" are cleared.'; fa = 'All appearance and report settings for user ""%1"" are cleared.';
							|it = 'Tutte le impostazioni dei report e del tipo esterno dell''utente ""%1"" sono cancellate';
							|pl = 'Wyczyszczone wszystkie ustawienia raportów i wyglądu u użytkownika ""%1""';
							|tr = 'Tüm rapor ayarları ve kullanıcı ""%1"" görünümleri temizlendi'");
	ExplanationText = StringFunctionsClientServer.SubstituteParametersToString(ExplanationText, String(UserRef));
	ShowUserNotification(NStr("vi = 'Xóa tùy chỉnh';
								|ru = 'Очистка настроек';
								|en = 'Clear settings'; fa = 'پاک کردن تنظیمات';
								|it = 'Cancellazione delle impostazioni';
								|pl = 'Oczyszczenie ustawień';
								|tr = 'Temizleme ayarları'"), , ExplanationText, PictureLib.DialogInformation);
	
EndProcedure

&AtClient
Procedure SettingsBeforeDeleteRowCompletion(Response, Item) Export
	
	If Response = DialogReturnCode.No Then
		Return;
	EndIf;
	
	ClearAtServer();
	CommonClient.RefreshApplicationInterface();
	
	SelectedRows = Item.SelectedRows;
	SettingsCount = CopiedOrDeletedSettingsCount(Item);
	
	If SettingsCount = 1 Then
		
		SettingsTree = SelectedSettingsPageFormTable();
		SettingName1 = SettingsTree.CurrentData.Setting;
		
		If StrLen(SettingName1) > 24 Then
			SettingName1 = Left(SettingName1, 24) + "...";
		EndIf;
		
	EndIf;
	
	DeleteSettingsFromValueTree(SelectedRows);
	
	NotifyDeletion(SettingsCount, SettingName1);
	
EndProcedure

&AtClient
Procedure NotificationProcessingShowQueryBox(Response, Report) Export
	
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

&AtClient
Procedure Attachable_ExpandValueTree()
	
	For Each Item In ReportsSettings.GetItems() Do
		Items.ReportSettingsTree.Expand(Item.GetID(), True);
	EndDo;
	
	For Each Item In Interface.GetItems() Do
		Items.Interface.Expand(Item.GetID(), True);
	EndDo;
	
EndProcedure

&AtClient
Function SelectedSettingsPageFormTable()
	
	If SelectedSettingsPage = "ReportSettingsPage" Then
		Return Items.ReportSettingsTree;
	ElsIf SelectedSettingsPage = "InterfacePage" Then
		Return Items.Interface;
	Else
		Return Items.OtherSettings;
	EndIf;
	
EndFunction

&AtClient
Function CopiedOrDeletedSettingsCount(SettingsTree)
	
	SelectedRows = SettingsTree.SelectedRows;
	// Moving the array of selected rows to a value list in order to sort the selected rows.
	SelectedRowsList = New ValueList;
	For Each Item In SelectedRows Do
		SelectedRowsList.Add(Item);
	EndDo;
	
	SelectedRowsList.SortByValue();
	If SelectedSettingsPage = "ReportSettingsPage" Then
		CurrentValueTree = ReportsSettings;
	ElsIf SelectedSettingsPage = "InterfacePage" Then
		CurrentValueTree = Interface;
	Else
		CurrentValueTree = OtherSettings;
	EndIf;
	
	SettingsCount = 0;
	For Each SelectedRow In SelectedRowsList Do
		TreeItem = CurrentValueTree.FindByID(SelectedRow.Value);
		SubordinateItemsCount = TreeItem.GetItems().Count();
		ItemParent = TreeItem.GetParent();
		
		If SubordinateItemsCount <> 0 Then
			SettingsCount = SettingsCount + SubordinateItemsCount;
			TopLevelItem = TreeItem;
		ElsIf SubordinateItemsCount = 0
			And ItemParent = Undefined Then
			SettingsCount = SettingsCount + 1;
		Else
			
			If ItemParent <> TopLevelItem Then
				SettingsCount = SettingsCount + 1;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return SettingsCount;
EndFunction

&AtClient
Procedure DeleteSettingsRow(SettingsTree, SelectedRow)
	
	SettingsItem = SettingsTree.FindByID(SelectedRow);
	If SettingsItem = Undefined Then
		Return;
	EndIf;
	
	SettingsItemParent = SettingsItem.GetParent();
	If SettingsItemParent <> Undefined Then
		
		SubordinateRowsCount = SettingsItemParent.GetItems().Count();
		If SubordinateRowsCount = 1 Then
			
			If SettingsItemParent.Type <> "PersonalOption" Then
				SettingsTree.GetItems().Delete(SettingsItemParent);
			EndIf;
			
		Else
			SettingsItemParent.GetItems().Delete(SettingsItem);
		EndIf;
		
	Else
		SettingsTree.GetItems().Delete(SettingsItem);
	EndIf;
	
EndProcedure

&AtClient
Procedure NotifyDeletion(SettingsCount, SettingName1 = Undefined, UsersCount = Undefined)
	
	SubjectInWords = Format(SettingsCount, "NFD=0") + " "
		+ UsersInternalClientServer.IntegerSubject(SettingsCount,
			"", NStr("vi = 'tùy chỉnh,tùy chỉnh,tùy chỉnh,,,,,,0';
					|ru = 'настройка,настройки,настроек,,,,,,0';
					|en = 'setting,settings,,,0'; fa = 'setting,settings,,,0';
					|it = 'impostazione,impostazioni,delle impostazioni,,,,,,0';
					|pl = 'ustawienie,ustawienia,ustawień,,,,,,0';
					|tr = 'ayar, ayarlar, ayarlar,,,,,,0'"));
	
	If SettingsCount = 1
	   And UsersCount = Undefined Then
		
		ExplanationText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '""%1"" đã xóa bởi người dùng ""%2""';
				|ru = '""%1"" очищена пользователю ""%2""';
				|en = '""%1"" cleared for user ""%2.""'; fa = '""%1"" cleared for user ""%2.""';
				|it = '""%1"" cancellata per l''utente ""%2""';
				|pl = '""%1"" oczyszczona użytkownikowi ""%2""';
				|tr = '""%1"" %2 için temizlendi'"), SettingName1, String(UserRef));
		
	ElsIf UsersCount = Undefined Then
		ExplanationText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã xóa %1 cho người sử dụng ""%2""';
				|ru = 'Очищено %1 пользователю ""%2""';
				|en = '%1 cleared for user ""%2.""'; fa = '%1 cleared for user ""%2.""';
				|it = 'Cancellato %1 per l''utente ""%2""';
				|pl = 'Oczyszczone %1 użytkownikowi ""%2""';
				|tr = '""%1"" kullanıcı için silindi %2'"), SubjectInWords, String(UserRef));
	EndIf;
	
	ClearSettingsForNote = UsersInternalClient.UsersNote(
		UsersCount, String(UserRef));
	
	If UsersCount <> Undefined Then
		
		If SettingsCount = 1 Then
			ExplanationText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = '""%1"" đã xóa %2';
					|ru = '""%1"" очищена %2';
					|en = '""%1"" cleared for %2'; fa = '""%1"" cleared for %2';
					|it = '""%1"" cancellata %2';
					|pl = '""%1"" wyczyszczona %2';
					|tr = '""%1"" temizlendi %2'"), SettingName1, ClearSettingsForNote);
		Else
			ExplanationText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã xóa %1 %2';
					|ru = 'Очищено %1 %2';
					|en = '%1 cleared for %2'; fa = '%1 cleared for %2';
					|it = 'Cancellate %1 %2';
					|pl = 'Wyczyszczone %1 %2';
					|tr = 'Temizlendi %1 %2'"), SubjectInWords, ClearSettingsForNote);
		EndIf;
		
	EndIf;
	
	ShowUserNotification(NStr("vi = 'Xóa tùy chỉnh';
								|ru = 'Очистка настроек';
								|en = 'Clear settings'; fa = 'پاک کردن تنظیمات';
								|it = 'Cancellazione delle impostazioni';
								|pl = 'Oczyszczenie ustawień';
								|tr = 'Temizleme ayarları'"),
		, ExplanationText, PictureLib.DialogInformation);
	
EndProcedure

&AtClient
Procedure CopySettings()
	
	SettingsTree = SelectedSettingsPageFormTable();
	If SettingsTree.SelectedRows.Count() = 0 Then
		ShowMessageBox(,
			NStr("vi = 'Hãy chọn tùy chỉnh cần sao chép.';
				|ru = 'Выберите настройки, которые требуется скопировать.';
				|en = 'Select the settings to copy.'; fa = 'Select the settings to copy.';
				|it = 'Selezionare le impostazioni da copiare.';
				|pl = 'Wybierz ustawienia, które należy skopiować.';
				|tr = 'Kopyalamak istediğiniz ayarları seçin.'"));
		Return;
	ElsIf SettingsTree.SelectedRows.Count() = 1 Then
		
		If SettingsTree.CurrentData.Type = "PersonalOption" Then
			ShowMessageBox(,
				NStr("vi = 'Không thể sao chép phiên bản cá nhân của báo cáo.
			               |Để cung cấp phiên bản cá nhân của báo cáo cho những người dùng khác, bạn phải
			               |lưu lại nó với dấu ""Chỉ dành cho tác giả"".';
			               |ru = 'Невозможно скопировать личный вариант отчета.
			               |Для того чтобы личный вариант отчета стал доступен другим пользователям, необходимо
			               |его пересохранить со снятой пометкой ""Только для автора"".';
			               |en = 'Cannot copy a personal report option.
			               |To make the personal report option available to other users,
			               |save it with ""Available to author only"" check box cleared.'; fa = 'Cannot copy a personal report option.
			               |To make the personal report option available to other users,
			               |save it with ""Available to author only"" check box cleared.';
			               |it = 'Non è possibile copiare la versione personale del report.
			               |Per poter rendere disponibile la versione personale del report ad altri utenti, è necessario
			               |salvarlo nuovamente con il contrassegno ""Solo per l''autore"" rimosso.';
			               |pl = 'Kopiowanie wersji osobistej raportu jest niemożliwe.
			               |Aby udostępnić osobistą wersję raportu innym użytkownikom, należy
			               |zapisać ją z usuniętym znakiem ""Tylko dla autora"".';
			               |tr = '
			               |Kişisel rapor seçeneklerinin kopyalanması mümkün değildir. 
			               |Kişisel rapor seçeneğini diğer kullanıcılara sunmak istiyorsanız, ""Yalnızca sahibi için"" işaretini kaldırmanız gerekir.'"));
			Return;
		ElsIf SettingsTree.CurrentData.Type = "SettingsItemPersonal" Then
			ShowMessageBox(,
				NStr("vi = 'Không thể sao chép cài đặt báo cáo tùy chỉnh.
			               |Không thể sao chép cài đặt báo cáo tùy chỉnh.';
			               |ru = 'Невозможно скопировать настройку личного варианта отчета.
			               |Копирование настроек личных вариантов отчетов не предусмотрено.';
			               |en = 'Cannot copy the setting of a personal report option.
			               |Copying settings of personal report options is not supported.'; fa = 'Cannot copy the setting of a personal report option.
			               |Copying settings of personal report options is not supported.';
			               |it = 'Non è possibile copiare l''impostazione della versione personale del report.
			               |La copia delle impostazioni per le versioni personali del report non è prevista.';
			               |pl = 'Nie można skopiować ustawień osobistych wersji raportu. 
			               |Nie ma opcji kopiowania ustawień osobistych wersji raportów osobistych.';
			               |tr = 'Kişisel rapor seçeneğinin ayarını kopyalamak imkansız. 
			               |Tek tek rapor seçenek ayarlarının kopyalanması sağlanmamıştır.'"));
			Return;
		EndIf;
		
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("User", UserRef);
	FormParameters.Insert("ActionType",  "");
	SelectUsers(FormParameters);
	
EndProcedure

&AtServer
Function SettingsGettingResult()
	
	If Not ValueIsFilled(UserRef) Then
		UserRef = Catalogs.Users.EmptyRef();
		InfoBaseUser = Undefined;
	Else
		InfoBaseUser = DataProcessors.UsersSettings.IBUserName(
			UserRef);
	EndIf;
	
	If InfoBaseUser = Undefined Then
		Return "NoIBUser";
	EndIf;
	
	Return "Success";
	
EndFunction

&AtServer
Function SettingsTreeForSelectedPage()
	
	If SelectedSettingsPage = "ReportSettingsPage" Then
		Return ReportsSettings;
	ElsIf SelectedSettingsPage = "InterfacePage" Then
		Return Interface;
	Else
		Return OtherSettings;
	EndIf;
	
EndFunction

&AtServer
Function SettingsStorageForSelectedPage()
	
	If SelectedSettingsPage = "ReportSettingsPage" Then
		Return "ReportsUserSettingsStorage";
	ElsIf SelectedSettingsPage = "InterfacePage"
		Or SelectedSettingsPage = "OtherSettingsPage" Then
		Return "SystemSettingsStorage";
	EndIf;
	
EndFunction

&AtServer
Function SelectedSettingsItems()
	
	If SelectedSettingsPage = "ReportSettingsPage" Then
		Return Items.ReportSettingsTree.SelectedRows;
	ElsIf SelectedSettingsPage = "InterfacePage" Then
		Return Items.Interface.SelectedRows;
	Else
		Return Items.OtherSettings.SelectedRows;
	EndIf;
	
EndFunction

&AtServer
Function SelectedSettings1()
	
	SettingsTree = SettingsTreeForSelectedPage();
	SettingsArray = New Array;
	PersonalSettingsArray = New Array;
	ReportOptionArray = New Array;
	UserSettingsArray = New Array;
	CurrentReportOption = Undefined;
	
	SelectedItems = SelectedSettingsItems();
	
	For Each SelectedItem In SelectedItems Do
		SelectedSetting = SettingsTree.FindByID(SelectedItem);
		
		// Filling the array of personal settings.
		If SelectedSetting.Type = "PersonalSettings" Then
			PersonalSettingsArray.Add(SelectedSetting.Keys);
			Continue;
		EndIf;
		
		// Filling the array of other user settings.
		If SelectedSetting.Type = "OtherUserSettingsItem1" Then
			OtherUserSettings = New Structure;
			OtherUserSettings.Insert("SettingID", SelectedSetting.RowType);
			OtherUserSettings.Insert("SettingValue",      SelectedSetting.Keys);
			UserSettingsArray.Add(OtherUserSettings);
			Continue;
		EndIf;
		
		// Marking personal settings in the list of keys.
		If SelectedSetting.Type = "PersonalOption" Then
			
			For Each Item In SelectedSetting.Keys Do
				Item.Check = True;
			EndDo;
			CurrentReportOption = SelectedSetting.Keys.Copy();
			// Filling the array of user-defined report options.
			ReportOptionArray.Add(SelectedSetting.Keys);
			
		ElsIf SelectedSetting.Type = "StandardOptionPersonal" Then
			ReportOptionArray.Add(SelectedSetting.Keys);
		EndIf;
		
		If SelectedSetting.Type = "SettingsItemPersonal" Then
			
			If CurrentReportOption <> Undefined
			   And CurrentReportOption.FindByValue(SelectedSetting.Keys[0].Value) <> Undefined Then
				
				Continue;
			Else
				SelectedSetting.Keys[0].Check = True;
				SettingsArray.Add(SelectedSetting.Keys);
				Continue;
			EndIf;
			
		EndIf;
		
		SettingsArray.Add(SelectedSetting.Keys);
		
	EndDo;
	
	Result = New Structure;
	Result.Insert("SettingsArray", SettingsArray);
	Result.Insert("PersonalSettingsArray", PersonalSettingsArray);
	Result.Insert("ReportOptionArray", ReportOptionArray);
	Result.Insert("UserSettingsArray", UserSettingsArray);
	
	Return Result;
EndFunction

&AtServer
Function TimeConsumingOperationParameters()
	
	TimeConsumingOperationParameters = New Structure;
	TimeConsumingOperationParameters.Insert("FormName");
	TimeConsumingOperationParameters.Insert("SettingsOperation");
	TimeConsumingOperationParameters.Insert("InfoBaseUser");
	TimeConsumingOperationParameters.Insert("UserRef");
	
	FillPropertyValues(TimeConsumingOperationParameters, ThisObject);
	
	TimeConsumingOperationParameters.Insert("ReportSettingsTree",
		FormAttributeToValue("ReportsSettings"));
	
	TimeConsumingOperationParameters.Insert("InterfaceSettings2",
		FormAttributeToValue("Interface"));
	
	TimeConsumingOperationParameters.Insert("OtherSettingsTree",
		FormAttributeToValue("OtherSettings"));
	
	TimeConsumingOperationParameters.Insert("UserReportOptions",
		FormAttributeToValue("UserReportOptionTable"));
	
	Return TimeConsumingOperationParameters;
	
EndFunction

#EndRegion

#EndRegion