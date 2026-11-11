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
Var RefreshInterface;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not Users.CommonAuthorizationSettingsUsed() Then
		Items.UsersAuthorizationSettingsGroup.Visible = False;
		Items.GroupExternalUsers.Group
			= ChildFormItemsGroup.AlwaysHorizontal;
	EndIf;
	
	If Common.DataSeparationEnabled()
	 Or StandardSubsystemsServer.IsBaseConfigurationVersion()
	 Or Common.IsStandaloneWorkplace()
	 Or Not UsersInternal.ExternalUsersEmbedded() Then
	
		Items.GroupExternalUsers.Visible = False;
		Items.SectionDetails.Title =
			NStr("vi = 'Quản trị người dùng, tùy chỉnh nhóm truy cập, quản lý tùy chỉnh tự tạo.';
				|ru = 'Администрирование пользователей, настройка групп доступа, управление пользовательскими настройками.';
				|en = 'Manage users, configure access groups, grant access to external users, and manage user settings.'; fa = 'مدیریت کاربران، پیکربندی گروه‌های دسترسی، اعطای دسترسی به کاربران خارجی و مدیریت تنظیمات کاربر.';
				|it = 'Gestione degli utenti, impostazione dei gruppi di accesso, gestione delle impostazioni dell''utente.';
				|pl = 'Administracja użytkowników, konfigurowanie grup dostępu, zarządzanie ustawieniami użytkowników.';
				|tr = 'Kullanıcı yönetimi, erişim gruplarını yapılandırma, kullanıcı ayarlarını yönetme.'");
	EndIf;
	
	If StandardSubsystemsServer.IsBaseConfigurationVersion()
	 Or Common.IsSubordinateDIBNode() Then
		
		Items.UseUserGroups.Enabled = False;
		Items.UseExternalUsers.Enabled = False;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagementInternal = Common.CommonModule("AccessManagementInternal");
		SimplifiedInterface = ModuleAccessManagementInternal.SimplifiedAccessRightsSetupInterface();
		Items.OpenAccessGroups.Visible            = Not SimplifiedInterface;
		Items.UseUserGroups.Visible = Not SimplifiedInterface;
		
		IsRecordLevelRestrictionDisabled = ModuleAccessManagementInternal.IsRecordLevelRestrictionDisabled();
		IsStandardOptionDisabled          = ModuleAccessManagementInternal.IsStandardOptionDisabled();
		Items.LimitAccessAtRecordLevel.Visible =
			Not IsRecordLevelRestrictionDisabled;
		Items.LimitAccessAtRecordLevelUniversally.Visible =
			Not IsRecordLevelRestrictionDisabled
			And Not IsStandardOptionDisabled
			And ModuleAccessManagementInternal.ScriptVariantRussian()
			And Users.IsFullUser();
		Items.AccessUpdateOnRecordsLevel.Visible =
			Not IsRecordLevelRestrictionDisabled
			And ModuleAccessManagementInternal.LimitAccessAtRecordLevelUniversally(True);
		If Common.IsSubordinateDIBNode() Then
			Items.LimitAccessAtRecordLevel.Enabled = False;
			Items.LimitAccessAtRecordLevelUniversally.Enabled = False;
		EndIf;
		UpdateVisibilityOfStandardOptionObsoleteWarning(ThisObject);
		If IsRecordLevelRestrictionDisabled Then
			For Each SubordinateItem In Items.AccessGroupsGroup.ChildItems Do
				If SubordinateItem <> Items.AccessGroupsProfilesAndRecordLevelRestrictionGroup Then
					SubordinateItem.Visible = False;
				EndIf;
			EndDo;
			For Each SubordinateItem In Items.AccessGroupsProfilesAndRecordLevelRestrictionGroup.ChildItems Do
				If SubordinateItem <> Items.AccessGroupsAndRecordLevelRestrictionGroup
				   And SubordinateItem <> Items.AccessGroupsProfilesGroup Then
					SubordinateItem.Visible = False;
				EndIf;
			EndDo;
		EndIf;
		IsAccessRightsChangeLoggingSupported =
			ModuleAccessManagementInternal.IsAccessRightsChangeLoggingSupported();
	Else
		Items.AccessGroupsGroup.Visible = False;
		IsAccessRightsChangeLoggingSupported = False;
	EndIf;
	
	If Not IsAccessRightsChangeLoggingSupported
	   And Items.Find("ShouldRegisterChangesInAccessRights") <> Undefined Then
		
		Items.ShouldRegisterChangesInAccessRights.Title =
			NStr("vi = 'Ghi nhận thay đổi người tham gia của nhóm người sử dụng';
				|ru = 'Регистрировать изменения участников групп пользователей';
				|en = 'Log changes in user group membership'; fa = 'Log changes in user group membership';
				|it = 'Регистрировать изменения участников групп пользователей';
				|pl = 'Log changes in user group membership';
				|tr = 'Kullanıcı grubu üyelerindeki değişiklikleri  kaydetme'");
		Items.ShouldRegisterChangesInAccessRights.ExtendedTooltip.Title =
			NStr("vi = 'Ghi lại các sự kiện bổ sung vào nhật ký sự kiện khi thay đổi người tham gia của nhóm người dùng thay đổi.';
				|ru = 'Запись дополнительных событий в журнал регистрации при изменении участников групп пользователей.';
				|en = 'Logging events of changes in user group membership.'; fa = 'Logging events of changes in user group membership.';
				|it = 'Запись дополнительных событий в журнал регистрации при изменении участников групп пользователей.';
				|pl = 'Logging events of changes in user group membership.';
				|tr = 'Kullanıcı gruplarının üyeleri değiştiğinde ek olayları günlüğe kaydedin.'");
	EndIf;
	
	If Not Common.SubsystemExists("StandardSubsystems.PeriodClosingDates") Then
		Items.PeriodClosingDatesGroup.Visible = False;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.PersonalDataProtection") Then
		Items.GroupPersonalDataAccessEventRegistrationSettings.Visible =
		 Users.IsFullUser(, True);
	Else
		Items.PersonalDataProtectionGroup.Visible = False;
	EndIf;
	
	If Not Common.SubsystemExists("StandardSubsystems.ReportsOptions")
	 Or Metadata.Subsystems.Find("Administration") = Undefined Then
		Items.UserMonitoring.Visible = False;
	EndIf;
	
	If Not Common.SubsystemExists("StandardSubsystems.UserMonitoring") Then
		Items.GroupDataAccessAudit.Visible = False;
		If Items.Find("ShouldRegisterChangesInAccessRights") <> Undefined Then
			Items.ShouldRegisterChangesInAccessRights.Visible = False;
		EndIf;
		Items.GroupUserMonitoringLeftColumnVerticalIndent.Visible = True;
		
	ElsIf Common.DataSeparationEnabled()
	      Or Not Users.IsFullUser(, True) Then
		
		Items.GroupDataAccessManagementSettings.Visible = False;
	Else
		ModuleUserMonitoring = Common.CommonModule("UserMonitoring");
		ShouldRegisterDataAccess = ModuleUserMonitoring.ShouldRegisterDataAccess();
	EndIf;
	
	If Common.DataSeparationEnabled() Then
		Items.PasswordsRecovery.Visible = False;
	EndIf;
	
	// Update items states.
	SetAvailability();
	
	ApplicationSettingsOverridable.UsersAndRightsSettingsOnCreateAtServer(ThisObject);
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	If Exit Then
		Return;
	EndIf;
	RefreshApplicationInterface();
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName <> "Write_ConstantsSet" Then
		Return;
	EndIf;
	
	If Source = "UseSurvey" 
		And CommonClient.SubsystemExists("StandardSubsystems.Surveys") Then
		
		Read();
		SetAvailability();
		
	ElsIf Source = "UseHidePersonalDataOfSubjects" Then
		Read();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UseUserGroupsOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure ShouldRegisterChangesInAccessRightsOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseExternalUsersOnChange(Item)
	
	If ConstantsSet.UseExternalUsers Then
		
		QueryText =
			NStr("vi = 'Cho phép người dùng bên ngoài truy cập? 
			           |
			           |Khi đăng nhập vào ứng dụng, danh sách lựa chọn của người dùng sẽ trở nên trống
			           |(thuộc tính ""Hiển thị trong danh sách lựa chọn"" trong thẻ của tất cả
			           |người dùng sẽ bị xóa và ẩn).';
			           |ru = 'Разрешить доступ внешним пользователям?
			           |
			           |При входе в приложение список выбора пользователей станет пустым
			           |(реквизит ""Показывать в списке выбора"" в карточках всех
			           | пользователей будет очищен и скрыт).';
			           |en = 'Do you want to allow external user access?
			           |
			           |This will clear the user list in the startup dialog.
			           |The ""Show in choice list"" checkbox will be cleared and hidden in all user cards).
			           |'; fa = 'Do you want to allow external user access?
			           |
			           |This will clear the user list in the startup dialog.
			           |The ""Show in choice list"" checkbox will be cleared and hidden in all user cards).
			           |';
			           |it = 'Разрешить доступ внешним пользователям?
			           |
			           |При входе в приложение список выбора пользователей станет пустым
			           |(реквизит ""Показывать в списке выбора"" в карточках всех
			           | пользователей будет очищен и скрыт).';
			           |pl = 'Do you want to allow external user access?
			           |
			           |This will clear the user list in the startup dialog.
			           |The ""Show in choice list"" checkbox will be cleared and hidden in all user cards).
			           |';
			           |tr = 'Harici kullanıcılara erişime izin verilsin mi?
			           |
			           |Uygulamaya girdiğinizde kullanıcı seçim listesi boşalacaktır
			           |(Tüm
			           | kullanıcıların kartlarındaki “Seçim listesinde göster” özelliği temizlenecek ve gizlenecektir).'");
		
		ShowQueryBox(
			New CallbackDescription(
				"UseExternalUsersOnChangeCompletion",
				ThisObject,
				Item),
			QueryText,
			QuestionDialogMode.YesNo);
	Else
		QueryText =
			NStr("vi = 'Cấm người dùng bên ngoài truy cập?
			           |
			           |Mục tin ""Được phép đăng nhập vào ứng dụng"" sẽ
			           |bị xóa trong thẻ của tất cả người dùng bên ngoài.';
			           |ru = 'Запретить доступ внешним пользователям?
			           |
			           |Реквизит ""Вход в приложение разрешен"" будет
			           |очищен в карточках всех внешних пользователей.';
			           |en = 'Do you want to deny external user access?
			           |
			           |The ""Login allowed"" checkbox will be cleared in all external user cards.
			           |'; fa = 'Do you want to deny external user access?
			           |
			           |The ""Login allowed"" checkbox will be cleared in all external user cards.
			           |';
			           |it = 'Запретить доступ внешним пользователям?
			           |
			           |Реквизит ""Вход в приложение разрешен"" будет
			           |очищен в карточках всех внешних пользователей.';
			           |pl = 'Do you want to deny external user access?
			           |
			           |The ""Login allowed"" checkbox will be cleared in all external user cards.
			           |';
			           |tr = 'Harici kullanıcıların erişimi reddedilsin mi?
			           |
			           |Tüm harici kullanıcıların kartlarında
			           |""Uygulamada oturum açmaya izin veriliyor"" özelliği temizlenecek.'");
		
		ShowQueryBox(
			New CallbackDescription(
				"UseExternalUsersOnChangeCompletion",
				ThisObject,
				Item),
			QueryText,
			QuestionDialogMode.YesNo);
	EndIf;
	
EndProcedure

&AtClient
Procedure LimitAccessAtRecordLevelUniversallyOnChange(Item)
	
	If ConstantsSet.LimitAccessAtRecordLevelUniversally Then
		QueryText =
			NStr("vi = 'Bật tùy chọn hiệu suất hạn chế truy cập?
			           |
			           | Việc bật sử dụng này sẽ mất một chút thời gian để điền lại cài đặt quyền trong ứng dụng,
			           |xem tiến trình thực hiện theo tham chiếu ""Cập nhật truy cập ở mức độ bản ghi"".';
			           |ru = 'Включить производительный вариант ограничения доступа?
			           |
			           |Включение займет некоторое время для перезаполнения настроек прав в приложении,
			           |см. ход выполнения по ссылке ""Обновление доступа на уровне записей"".';
			           |en = 'Do you want to enable the high-performance access restriction mode?
			           |
			           |The update of the right settings will take some time.
			           |To monitor the progress, click ""RLS access update progress"".'; fa = 'Do you want to enable the high-performance access restriction mode?
			           |
			           |The update of the right settings will take some time.
			           |To monitor the progress, click ""RLS access update progress"".';
			           |it = 'Включить производительный вариант ограничения доступа?
			           |
			           |Включение займет некоторое время для перезаполнения настроек прав в приложении,
			           |см. ход выполнения по ссылке ""Обновление доступа на уровне записей"".';
			           |pl = 'Do you want to enable the high-performance access restriction mode?
			           |
			           |The update of the right settings will take some time.
			           |To monitor the progress, click ""RLS access update progress"".';
			           |tr = 'Üretimsel erişim kısıtlaması seçeneği kapatılsın mı?
			           |
			           |Bu seçeneği açtığınızda uygulamadaki izin ayarlarının tekrar doldurulması biraz zaman alacaktır,
			           | ""Kayıt düzeyinde erişim güncellemesi"" bağlantısından ilerleyişine bakın.'");
	Else
		QueryText =
			NStr("vi = 'Quay lại phiên bản tiêu chuẩn cũ của hạn chế quyền truy cập?
			           |
			           |Việc bật sử dụng này sẽ mất một chút thời gian để điền lại cài đặt quyền trong ứng dụng,
			           |xem tiến trình thực hiện nhiệm vụ thường kỳ ""Điền dữ liệu để hạn chế truy cập"" trong nhật ký sự kiện.';
			           |ru = 'Вернуться к устаревшему стандартному варианту ограничения доступа?
			           |
			           |Включение займет некоторое время для перезаполнения настроек прав в приложении,
			           |см. ход выполнения регламентного задания ""Заполнение данных для ограничения доступа"" в журнале регистрации.';
			           |en = 'Are you sure you want to enable the standard access restriction mode, which is obsolete?
			           |
			           |The update of the right settings will take some time.
			           |To monitor the progress, click ""RLS access update progress"".'; fa = 'Are you sure you want to enable the standard access restriction mode, which is obsolete?
			           |
			           |The update of the right settings will take some time.
			           |To monitor the progress, click ""RLS access update progress"".';
			           |it = 'Are you sure you want to enable the standard access restriction mode, which is obsolete?
			           |
			           |The update of the right settings will take some time.
			           |To monitor the progress, click ""RLS access update progress"".';
			           |pl = 'Are you sure you want to enable the standard access restriction mode, which is obsolete?
			           |
			           |The update of the right settings will take some time.
			           |To monitor the progress, click ""RLS access update progress"".';
			           |tr = 'Eski standart seçenek olan erişim kısıtlamasına geri dönülsün mü?
			           |
			           |Bu seçeneği açtığınızda uygulamadaki izin ayarlarının tekrar doldurulması biraz zaman alacaktır,
			           | zamanlanmış görevdeki ""Erişim kısıtlaması için veri doldurma"" zamanlanmış görevinin ilerleyişine bakın.'");
	EndIf;
	
	If ValueIsFilled(QueryText) Then
		ShowQueryBox(
			New CallbackDescription(
				"LimitAccessAtRecordLevelUniversallyOnChangeCompletion",
				ThisObject, Item),
			QueryText, QuestionDialogMode.YesNo);
	Else
		LimitAccessAtRecordLevelUniversallyOnChangeCompletion(DialogReturnCode.Yes, Item);
	EndIf;
	
EndProcedure

&AtClient
Procedure LimitAccessAtRecordLevelOnChange(Item)
	
	If ConstantsSet.LimitAccessAtRecordLevelUniversally Then
		QueryText =
			NStr("vi = 'Cài đặt nhóm quyền truy cập sẽ có hiệu lực sau một thời gian,
			           |xem tiến trình thực hiện theo tham chiếu ""Cập nhật truy cập ở mức độ bản ghi"".
			           |
			           |Việc cập nhật cài đặt quyền truy cập có thể tạm thời làm chậm hiệu suất của ứng dụng 
			           |và mất từ vài giây đến vài giờ (tùy thuộc vào khối lượng dữ liệu).';
			           |ru = 'Настройки групп доступа вступят в силу через некоторое время,
			           |см. ход выполнения по ссылке ""Обновление доступа на уровне записей"".
			           |
			           |Заполнение настроек прав доступа может временно замедлить работу приложения 
			           |и занять от нескольких секунд до часов (в зависимости от объема данных).';
			           |en = 'Access group settings will take effect in a while.
			           |To monitor the progress, click ""RLS access update progress"".
			           |
			           |This might slow down the app and take
			           |from seconds to a few hours, depending on the data volume.'; fa = 'Access group settings will take effect in a while.
			           |To monitor the progress, click ""RLS access update progress"".
			           |
			           |This might slow down the app and take
			           |from seconds to a few hours, depending on the data volume.';
			           |it = 'Настройки групп доступа вступят в силу через некоторое время,
			           |см. ход выполнения по ссылке ""Обновление доступа на уровне записей"".
			           |
			           |Заполнение настроек прав доступа может временно замедлить работу приложения 
			           |и занять от нескольких секунд до часов (в зависимости от объема данных).';
			           |pl = 'Access group settings will take effect in a while.
			           |To monitor the progress, click ""RLS access update progress"".
			           |
			           |This might slow down the app and take
			           |from seconds to a few hours, depending on the data volume.';
			           |tr = 'Erişim grupları ayarları kademeli olarak yürürlüğe girecektir 
			           |(""Kayıt düzeyinde erişim güncellemesi"" bağlantısı altındaki sürece bakın).
			           |
			           | Erişimin güncellenmesi programı yavaşlatabilir
			           | ve birkaç saniyeden birkaç saate kadar sürebilir (veri miktarına bağlı olarak).'");
		If ConstantsSet.LimitAccessAtRecordLevel Then
			QueryText = NStr("vi = 'Bật hạn chế truy cập ở mức độ bản ghi?';
							|ru = 'Включить ограничение доступа на уровне записей?';
							|en = 'Do you want to enable record-level access restrictions?'; fa = 'Do you want to enable record-level access restrictions?';
							|it = 'Attivare la limitazione di accesso al livello di registrazioni?';
							|pl = 'Włączyć ograniczenie dostępu na poziomie wpisów?';
							|tr = 'Kayıt düzeyinde erişim kısıtlaması etkinleştirilsin mi?'")
				+ Chars.LF + Chars.LF + QueryText;
		Else
			QueryText = NStr("vi = 'Tắt hạn chế truy cập mức kỷ lục?';
							|ru = 'Выключить ограничение доступа на уровне записей?';
							|en = 'Do you want to disable record-level access restrictions?'; fa = 'Do you want to disable record-level access restrictions?';
							|it = 'Disabilitare la limitazione di accesso al livello di registrazione';
							|pl = 'Wyłączyć ograniczenie dostępu na poziomie wpisów?';
							|tr = 'Kayıt düzeyinde erişim kısıtlaması kapatılsın mı?'")
				+ Chars.LF + Chars.LF + QueryText;
		EndIf;
		
	ElsIf ConstantsSet.LimitAccessAtRecordLevel Then
		QueryText =
			NStr("vi = 'Bật hạn chế truy cập ở mức độ bản ghi?
			           |
			           |Việc điền cài đặt quyền truy cập có thể tạm thời làm chậm hiệu suất của ứng dụng 
			           |và mất từ vài giây đến vài giờ (tùy thuộc vào khối lượng dữ liệu).
			           |Xem tiến trình thực hiện nhiệm vụ thường kỳ ""Điền dữ liệu để hạn chế truy cập"" trong nhật ký sự kiện.';
			           |ru = 'Включить ограничение доступа на уровне записей?
			           |
			           |Заполнение настроек прав доступа может временно замедлить работу приложения 
			           |и занять от нескольких секунд до часов (в зависимости от объема данных).
			           |См. ход выполнения регламентного задания ""Заполнение данных для ограничения доступа"" в журнале регистрации.';
			           |en = 'Do you want to enable RLS restriction?
			           |
			           |This might slow down the app and take
			           |from seconds to a few hours, depending on the data volume.
			           |To monitor the progress, see ""Populate data for access restriction"" in the event log.'; fa = 'Do you want to enable RLS restriction?
			           |
			           |This might slow down the app and take
			           |from seconds to a few hours, depending on the data volume.
			           |To monitor the progress, see ""Populate data for access restriction"" in the event log.';
			           |it = 'Включить ограничение доступа на уровне записей?
			           |
			           |Заполнение настроек прав доступа может временно замедлить работу приложения 
			           |и занять от нескольких секунд до часов (в зависимости от объема данных).
			           |См. ход выполнения регламентного задания ""Заполнение данных для ограничения доступа"" в журнале регистрации.';
			           |pl = 'Do you want to enable RLS restriction?
			           |
			           |This might slow down the app and take
			           |from seconds to a few hours, depending on the data volume.
			           |To monitor the progress, see ""Populate data for access restriction"" in the event log.';
			           |tr = 'Üretimsel erişim kısıtlaması seçeneği etkinleştirilsin mi?
			           |
			           |Yetki ayarlarının doldurulması uygulamayı geçici olarak yavaşlatabilir ve birkaç saniye ile saate kadar zaman alabilir (veri miktarına göre),
			           | kayıt günlüğündeki ""Erişim kısıtlaması için veri doldurma"" zamanlanmış  görevinin ilerleyişine bakın
			           |.'");
	Else
		QueryText = "";
	EndIf;
	
	If ValueIsFilled(QueryText) Then
		ShowQueryBox(
			New CallbackDescription(
				"LimitAccessAtRecordLevelOnChangeCompletion",
				ThisObject, Item),
			QueryText, QuestionDialogMode.YesNo);
	Else
		LimitAccessAtRecordLevelOnChangeCompletion(DialogReturnCode.Yes, Item);
	EndIf;
	
EndProcedure

&AtClient
Procedure ShouldRegisterDataAccessOnChange(Item)
	RegisterDataAccessOnChangeAtServer(ShouldRegisterDataAccess);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CatalogExternalUsers(Command)
	OpenForm("Catalog.ExternalUsers.ListForm", , ThisObject);
EndProcedure

&AtClient
Procedure UserMonitoring(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.ReportsOptions") Then
		ModuleReportsOptionsClient = CommonClient.CommonModule("ReportsOptionsClient");
		ModuleReportsOptionsClient.ShowReportBar("Administration", Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure AccessUpdateOnRecordsLevel(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagementInternalClient = CommonClient.CommonModule("AccessManagementInternalClient");
		ModuleAccessManagementInternalClient.OpenAccessUpdateOnRecordsLevelForm(True, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure ConfigurePeriodClosingDates(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.PeriodClosingDates") Then
		ModulePeriodClosingDatesInternalClient = CommonClient.CommonModule("PeriodClosingDatesInternalClient");
		ModulePeriodClosingDatesInternalClient.OpenPeriodEndClosingDates(ThisObject);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure UpdateVisibilityOfStandardOptionObsoleteWarning(Form)
	
	Items = Form.Items;
	Items.StandardOptionObsolete.Visible =
		Items.LimitAccessAtRecordLevelUniversally.Visible
		And Items.LimitAccessAtRecordLevelUniversally.Enabled
		And Not Items.AccessUpdateOnRecordsLevel.Visible;
	
EndProcedure

&AtClient
Procedure Attachable_OnChangeAttribute(Item, ShouldRefreshInterface = True)
	
	ConstantsNames = OnChangeAttributeServer(Item.Name);
	RefreshReusableValues();
	
	If ShouldRefreshInterface Then
		RefreshInterface = True;
		AttachIdleHandler("RefreshApplicationInterface", 2, True);
	EndIf;
	
	For Each ConstantName In ConstantsNames Do
		If ConstantName <> "" Then
			Notify("Write_ConstantsSet", New Structure, ConstantName);
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure Attachable_PDDestructionSettingsOnChange(Item)
	
	If CommonClient.SubsystemExists("StandardSubsystems.PersonalDataProtection") Then
		ModulePersonalDataProtectionClient = CommonClient.CommonModule("PersonalDataProtectionClient");
		ModulePersonalDataProtectionClient.SettingsForDestructionOfPersonalDataWhenChanging(ThisObject);
	EndIf;

	RefreshInterface = True;
	AttachIdleHandler("RefreshApplicationInterface", 2, True);

EndProcedure

&AtClient
Procedure RefreshApplicationInterface()
	
	If RefreshInterface = True Then
		RefreshInterface = False;
		CommonClient.RefreshApplicationInterface();
	EndIf;
	
EndProcedure

&AtClient
Procedure LimitAccessAtRecordLevelUniversallyOnChangeCompletion(Response, Item) Export
	
	If Response = DialogReturnCode.No Then
		ConstantsSet.LimitAccessAtRecordLevelUniversally
			= Not ConstantsSet.LimitAccessAtRecordLevelUniversally;
		Return;
	EndIf;
	
	Attachable_OnChangeAttribute(Item);
	
	Items.AccessUpdateOnRecordsLevel.Visible =
		ConstantsSet.LimitAccessAtRecordLevelUniversally;
	
	UpdateVisibilityOfStandardOptionObsoleteWarning(ThisObject);
	
EndProcedure

&AtClient
Procedure LimitAccessAtRecordLevelOnChangeCompletion(Response, Item) Export
	
	If Response = DialogReturnCode.No Then
		ConstantsSet.LimitAccessAtRecordLevel = Not ConstantsSet.LimitAccessAtRecordLevel;
		Return;
	EndIf;
	
	Attachable_OnChangeAttribute(Item);
	
	If Not ConstantsSet.LimitAccessAtRecordLevel Then
		
	EndIf;
	
EndProcedure

&AtClient
Procedure UseExternalUsersOnChangeCompletion(Response, Item) Export
	
	If Response = DialogReturnCode.No Then
		ConstantsSet.UseExternalUsers = Not ConstantsSet.UseExternalUsers;
	Else
		Attachable_OnChangeAttribute(Item);
	EndIf;
	
EndProcedure

&AtServer
Function OnChangeAttributeServer(TagName)
	
	ConstantsNames = New Array;
	DataPathAttribute = Items[TagName].DataPath;
	
	BeginTransaction();
	Try
		
		ConstantName = SaveAttributeValue(DataPathAttribute);
		ConstantsNames.Add(ConstantName);
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	SetAvailability(DataPathAttribute);
	RefreshReusableValues();
	Return ConstantsNames;
	
EndFunction

&AtServerNoContext
Procedure RegisterDataAccessOnChangeAtServer(Val ShouldRegisterDataAccess)
	
	If Not Common.SubsystemExists("StandardSubsystems.UserMonitoring") Then
		Return;
	EndIf;
	
	ModuleUserMonitoring = Common.CommonModule("UserMonitoring");
	ModuleUserMonitoring.SetDataAccessRegistration(ShouldRegisterDataAccess);
	
EndProcedure

&AtServer
Function SaveAttributeValue(DataPathAttribute)
	
	NameParts = StrSplit(DataPathAttribute, ".");
	If NameParts.Count() <> 2 Then
		Return "";
	EndIf;
	
	ConstantName = NameParts[1];
	ConstantManager = Constants[ConstantName];
	ConstantValue = ConstantsSet[ConstantName];
	CurrentValue  = ConstantManager.Get();
	If CurrentValue <> ConstantValue Then
		Try
			ConstantManager.Set(ConstantValue);
		Except
			ConstantsSet[ConstantName] = CurrentValue;
			Raise;
		EndTry;
	EndIf;
	If DataPathAttribute = "ConstantsSet.UseExternalUsers" 
		Or DataPathAttribute = "ConstantsSet.LimitAccessAtRecordLevel" Then
		
		If Not ConstantsSet.UsePartnerAccessGroups 
			  And ConstantsSet.UseExternalUsers 
			  And ConstantsSet.LimitAccessAtRecordLevel Then
			
			Constants.UsePartnerAccessGroups.Set(True);
		EndIf;
		
		ThisForm.Read();
		SetAvailability("ConstantsSet.UsePartnerAccessGroups");
		
	EndIf;
	Return ConstantName;
	
EndFunction

&AtServer
Procedure SetAvailability(DataPathAttribute = "")
	
	If DataPathAttribute = "ConstantsSet.UseExternalUsers"
	 Or DataPathAttribute = "" Then
		
		Items.OpenExternalUsers.Enabled = ConstantsSet.UseExternalUsers;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.PeriodClosingDates")
		And (DataPathAttribute = "ConstantsSet.UsePeriodClosingDates"
		Or DataPathAttribute = "") Then
		
		Items.ConfigurePeriodClosingDates.Enabled = ConstantsSet.UsePeriodClosingDates;
	EndIf;
	If DataPathAttribute = "ConstantsSet.UsePartnerAccessGroups" Or DataPathAttribute = "" Then
		Items.OpenPartnerAccessGroups.Enabled = ConstantsSet.UsePartnerAccessGroups;
		Items.UsePartnerAccessGroupsGroup.Enabled = ConstantsSet.LimitAccessAtRecordLevel;
		Items.GroupUsePartnerAccessGroupsLeft.Enabled = Not ConstantsSet.UseExternalUsers;
		Items.CommentUsePartnerAccessGroupsGroup.Visible = ConstantsSet.LimitAccessAtRecordLevel And ConstantsSet.UseExternalUsers;
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.LimitAccessAtRecordLevel" Or DataPathAttribute = "" Then
		
		Items.UsePartnerAccessGroups.Enabled    = ConstantsSet.LimitAccessAtRecordLevel;
		SetAvailability("ConstantsSet.UsePartnerAccessGroups");
		Items.LimitAccessOnLevelOfIndividualRecords.Enabled = ConstantsSet.LimitAccessAtRecordLevel;
		Items.UseAccessGroupsOfItemKindsAndBudgetBalanceItems.Enabled = ConstantsSet.LimitAccessAtRecordLevel;
		SetAvailability("ConstantsSet.LimitAccessOnLevelOfIndividualRecords");
		SetAvailability("ConstantsSet.UseAccessGroupsOfItemKindsAndBudgetBalanceItems");
	EndIf;
	If DataPathAttribute = "ConstantsSet.LimitAccessOnLevelOfIndividualRecords" Or DataPathAttribute = "" Then
		Items.OpenIndividualAccessGroups.Enabled = ConstantsSet.LimitAccessOnLevelOfIndividualRecords;
	EndIf;
	If DataPathAttribute = "ConstantsSet.LimitAccessAtRecordLevel" Or DataPathAttribute = "" Then
		
		Items.UseItemAccessGroups.Enabled = ConstantsSet.LimitAccessAtRecordLevel;
		
		SetAvailability("ConstantsSet.UseItemAccessGroups");
		
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.UseItemAccessGroups" Or DataPathAttribute = "" Then
		Items.OpenProductAccessGroups.Enabled = ConstantsSet.UseItemAccessGroups;
	EndIf;
	If DataPathAttribute = "ConstantsSet.UseAccessGroupsOfItemKindsAndBudgetBalanceItems" Or DataPathAttribute = "" Then
		Items.OpenAccessGroupsOfBudgetProfiles.Enabled = ConstantsSet.UseAccessGroupsOfItemKindsAndBudgetBalanceItems;
		Items.OpenAccessGroupsOfBudgetItemsAndIndicators.Enabled = ConstantsSet.UseAccessGroupsOfItemKindsAndBudgetBalanceItems;
	EndIf;
EndProcedure

&AtClient
Procedure OpenPartnerAccessGroups(Command)
	OpenForm("Catalog.PartnerAccessGroups.ListForm", , ThisForm);
EndProcedure

&AtClient
Procedure OpenIndividualAccessGroups(Command)
	OpenForm("Catalog.AccessGroupsOfPersons.ListForm", , ThisForm);
EndProcedure

&AtClient
Procedure LimitAccessOnLevelOfIndividualRecordsOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UsePartnerAccessGroupsOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure OpenProductAccessGroups(Command)
	OpenForm("Catalog.ItemAccessGroups.ListForm", , ThisForm);
EndProcedure

&AtClient
Procedure UseItemAccessGroupsOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure OpenAccessGroupsOfBudgetItemsAndIndicators(Command)
	OpenForm("Catalog.AccessGroupsOfBudgetFlowItemsAndIndicators.ListForm", , ThisForm);
	Return;
	
EndProcedure

&AtClient
Procedure OpenAccessGroupsOfBudgetProfiles(Command)
	OpenForm("Catalog.BudgetProfileAccessGroups.ListForm", , ThisForm);
	Return;
	
EndProcedure

&AtClient
Procedure UseAccessGroupsOfItemKindsAndBudgetBalanceItemsOnChange(Item)
	Attachable_OnChangeAttribute(Item);
	Return;
	
EndProcedure

#EndRegion