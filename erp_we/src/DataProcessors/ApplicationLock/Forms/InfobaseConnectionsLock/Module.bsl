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
Var AdministrationParameters, CurrentLockValue;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Common.SubsystemExists("CloudTechnology.Core") Then
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		SessionWithoutSeparators = ModuleSaaSOperations.SessionWithoutSeparators();
	Else
		SessionWithoutSeparators = True;
	EndIf;
	
	IsFileInfobase = Common.FileInfobase();
	IsSystemAdministrator = Users.IsFullUser(, True);
	
	If IsFileInfobase Or Not IsSystemAdministrator Then
		Items.DisableScheduledJobsGroup.Visible = False;
	EndIf;
	
	If Common.DataSeparationEnabled() Or Not IsSystemAdministrator Then
		Items.UnlockCode.Visible = False;
	EndIf;
	
	SetInitialUserAuthorizationRestrictionStatus();
	RefreshSettingsPage();
	
	If Not IBConnections.IsSubsystemUsed() Then
		Enabled = False;
	EndIf;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ClientConnectedOverWebServer = CommonClient.ClientConnectedOverWebServer();
	If IBConnectionsClient.SessionTerminationInProgress() Then
		Items.GroupMode.CurrentPage = Items.LockStatePage;
		RefreshStatePage(ThisObject);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	BlockingSessionsInformation = IBConnections.BlockingSessionsInformation(NStr("vi = 'Chưa đặt phong tỏa.';
																				|ru = 'Блокировка не установлена.';
																				|en = 'The lock is not set.'; fa = 'The lock is not set.';
																				|it = 'Il blocco non è inserito.';
																				|pl = 'Blokada nie jest ustawiona.';
																				|tr = 'Kilit ayarlanmadı.'"));
	
	If BlockingSessionsInformation.HasBlockingSessions Then
		Raise BlockingSessionsInformation.MessageText;
	EndIf;
	
	SessionCount = BlockingSessionsInformation.SessionCount;
	
	// Checking if a lock can be set.
	If Object.LockEffectiveFrom > Object.LockEffectiveTo 
		And ValueIsFilled(Object.LockEffectiveTo) Then
		Common.MessageToUser(
			NStr("vi = 'Ngày kết thúc phong tỏa không thể nhỏ hơn ngày bắt đầu phong tỏa. Chưa thiết lập phong tỏa';
				|ru = 'Дата окончания блокировки не может быть меньше даты начала блокировки. Блокировка не установлена.';
				|en = 'Cannot set a lock. The end date cannot be earlier than the start date.'; fa = 'Cannot set a lock. The end date cannot be earlier than the start date.';
				|it = 'La data del termine di blocco non può essere inferiore alla data dell''inizio di blocco. Il blocco non è inserito.';
				|pl = 'Data zakończenia blokady nie może być mniejsza niż data rozpoczęcia blokady. Blokada nie jest ustawiona.';
				|tr = 'Kilit bitiş tarihi, kilit başlangıç tarihinden önce olamaz. Kilit ayarlanmamış.'"),,
			"Object.LockEffectiveTo",,Cancel);
		Return;
	EndIf;
	
	If Not ValueIsFilled(Object.LockEffectiveFrom) Then
		Common.MessageToUser(
			NStr("vi = 'Chưa chỉ ra ngày bắt đầu phong tỏa.';
				|ru = 'Не указана дата начала блокировки.';
				|en = 'Please select the start date.'; fa = 'Please select the start date.';
				|it = 'La data dell''inizio di blocco non è indicata.';
				|pl = 'Nie podano daty rozpoczęcia.';
				|tr = 'Kilit başlangıç tarihi belirtilmemiş.'"),, "Object.LockEffectiveFrom",,Cancel);
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "UsersSessions" Then
		SessionCount = Parameter.SessionCount;
		UpdateLockState(ThisObject);
		If Parameter.Status = "Done" Then
			Close();
		ElsIf Parameter.Status = "Error" Then
			ShowMessageBox(,NStr("vi = 'Không thể tắt tất cả người dùng đang hoạt động.
				|Xem Nhật ký để biết chi tiết.';
				|ru = 'Не удалось завершить работу всех активных пользователей.
				|Подробности см. в Журнале регистрации.';
				|en = 'Cannot close all active user sessions.
				|See the event log for details.'; fa = 'Cannot close all active user sessions.
				|See the event log for details.';
				|it = 'Non è stato possibile terminare il lavoro di tutti gli utenti attivi.
				|Per i dettagli vedere il registro.';
				|pl = 'Nie udało się zamknąć wszystkich aktywnych użytkowników.
				|Szczegółowe informacje zawiera dziennik.';
				|tr = 'Tüm aktif kullanıcıların oturumları sonlandırılamıyor.
				|Ayrıntılar için bkz. Olay günlüğü.'"), 30);
			Close();
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ActiveUsers(Command)
	
	OpenForm("DataProcessor.ActiveUsers.Form",, ThisObject);
	
EndProcedure

&AtClient
Procedure Apply(Command)
	
	ClearMessages();
	
	Object.DisableUserAuthorisation = Not InitialUserAuthorizationRestrictionStatusValue;
	If Object.DisableUserAuthorisation Then
		
		SessionCount = 1;
		Try
			If Not CheckLockPreconditions() Then
				Return;
			EndIf;
		Except
			CommonClient.MessageToUser(ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			Return;
		EndTry;
		
		CurrentSessionDate = CommonClient.SessionDate();
		
		QuestionTitle = NStr("vi = 'Phong tỏa công việc của người dùng';
							|ru = 'Блокировка работы пользователей';
							|en = 'Deny user access'; fa = 'ممنوعیت دسترسی کاربران';
							|it = 'Il blocco di lavoro degli utenti';
							|pl = 'Blokada pracy użytkownika';
							|tr = 'Kullanıcı çalışmasını kilitleme'");
		If SessionCount > 1 And Object.LockEffectiveFrom < CurrentSessionDate + 10 * 60 Then
			QueryText = NStr("vi = 'Thời gian bắt đầu của hành động chặn quá gần, do đó người dùng có thể không có thời gian để lưu tất cả dữ liệu của họ và kết thúc làm việc.
				|Nên đặt thời gian bắt đầu thành 10 phút so với thời gian hiện tại.';
				|ru = 'Указано слишком близкое время начала действия блокировки, к которому пользователи могут не успеть сохранить все свои данные и завершить работу.
				|Рекомендуется установить время начала на 10 минут относительно текущего времени.';
				|en = 'The period before applying the lock is too short. Users might not have enough time to save their data.
				|It is recommended that you give them at least 10 minutes.'; fa = 'The period before applying the lock is too short. Users might not have enough time to save their data.
				|It is recommended that you give them at least 10 minutes.';
				|it = 'Указано слишком близкое время начала действия блокировки, к которому пользователи могут не успеть сохранить все свои данные и завершить работу.
				|Рекомендуется установить время начала на 10 минут относительно текущего времени.';
				|pl = 'The period before applying the lock is too short. Users might not have enough time to save their data.
				|It is recommended that you give them at least 10 minutes.';
				|tr = 'Engellemenin çok erken başlama zamanı ayarlanmışsa, kullanıcılar tüm verilerini kaydetme ve oturumlarını sonlandırma için yeterli zamana sahip olmayabilir. 
				|Başlangıç saatinden 10 dakika sonra başlangıç zamanının ayarlanması önerilir.'");
			Buttons = New ValueList;
			Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Phong tỏa sau 10 phút';
													|ru = 'Заблокировать через 10 минут';
													|en = 'Lock in 10 minutes'; fa = 'Lock in 10 minutes';
													|it = 'Заблокировать через 10 минут';
													|pl = 'Lock in 10 minutes';
													|tr = '10 dakika içinde kilitleme'"));
			Buttons.Add(DialogReturnCode.No, NStr("vi = 'Phong tỏa ngay lập tức';
													|ru = 'Заблокировать сейчас';
													|en = 'Lock now'; fa = 'Lock now';
													|it = 'Bloccare subito';
													|pl = 'Zablokuj teraz';
													|tr = 'Şimdi kilitle'"));
			Buttons.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
														|ru = 'Отмена';
														|en = 'Cancel'; fa = 'انصراف';
														|it = 'Annulla';
														|pl = 'Cancel';
														|tr = 'İptal'"));
			Notification = New CallbackDescription("ApplyCompletion", ThisObject, "LockTimeTooSoon");
			ShowQueryBox(Notification, QueryText, Buttons,,, QuestionTitle);
		ElsIf Object.LockEffectiveFrom > CurrentSessionDate + 60 * 60 Then
			QueryText = NStr("vi = 'Thời gian để khóa bắt đầu quá lâu (hơn một giờ).
				|Lên lịch khóa cho thời gian đã chỉ định?';
				|ru = 'Указано слишком большое время начала действия блокировки (более, чем через час).
				|Запланировать блокировку на указанное время?';
				|en = 'The user lock is deferred for more than one hour.
				|Do you want to schedule the user lock for the specified time?'; fa = 'The user lock is deferred for more than one hour.
				|Do you want to schedule the user lock for the specified time?';
				|it = 'L''orario indicato come inizio del blocco risulta troppo avanti (più di un''ora).
				|Programmare il blocco per l''orario indicato?';
				|pl = 'Czas rozpoczęcia akcji blokującej jest zbyt długi (ponad godzinę później).
				|Czy blokowanie jest zaplanowane na określony czas?';
				|tr = 'Engellemenin statü süresi çok geç (bir saatten fazla). 
				|Belirtilen süre için kilitlemeyi programlamak ister misiniz?'");
			Buttons = New ValueList;
			Buttons.Add(DialogReturnCode.No, NStr("vi = 'Dự định';
													|ru = 'Запланировать';
													|en = 'Schedule'; fa = 'برنامه زمان‌بندی';
													|it = 'Programmare';
													|pl = 'Schedule';
													|tr = 'Planla'"));
			Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Phong tỏa ngay lập tức';
													|ru = 'Заблокировать сейчас';
													|en = 'Lock now'; fa = 'Lock now';
													|it = 'Bloccare subito';
													|pl = 'Zablokuj teraz';
													|tr = 'Şimdi kilitle'"));
			Buttons.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
														|ru = 'Отмена';
														|en = 'Cancel'; fa = 'انصراف';
														|it = 'Annulla';
														|pl = 'Cancel';
														|tr = 'İptal'"));
			Notification = New CallbackDescription("ApplyCompletion", ThisObject, "LockTimeTooLate");
			ShowQueryBox(Notification, QueryText, Buttons,,, QuestionTitle);
		Else
			If Object.LockEffectiveFrom - CurrentSessionDate > 15*60 Then
				QueryText = NStr("vi = 'Việc tắt tất cả người dùng đang hoạt động sẽ được thực hiện trong khoảng thời gian từ%1 đến %2.
					|Tiếp tục?';
					|ru = 'Завершение работы всех активных пользователей будет произведено в период с %1 по %2.
					|Продолжить?';
					|en = 'All active user sessions will be closed from %1 to %2.
					|Do you want to continue?'; fa = 'All active user sessions will be closed from %1 to %2.
					|Do you want to continue?';
					|it = 'Il termine di lavoro di tutti gli utenti attivi verrà effettuato nel periodo dal %1 al %2.
					|Continuare?';
					|pl = 'Zamknięcie pracy wszystkich aktywnych użytkowników zostanie wykonane od %1 do %2.
					|Kontynuować?';
					|tr = 'Tüm aktif kullanıcıların oturumları %1''den %2 kadar olan süre içinde sonlandırılacak. 
					|Devam edilsin mi?'");
			Else
				QueryText = NStr("vi = 'Phiên của tất cả người dùng đang hoạt động sẽ bị chấm dứt đến %2.
					|Tiếp tục?';
					|ru = 'Сеансы всех активных пользователей будут завершены к %2.
					|Продолжить?';
					|en = 'All active user sessions will be closed by %2.
					|Do you want to continue?'; fa = 'All active user sessions will be closed by %2.
					|Do you want to continue?';
					|it = 'Le sessioni di tutti gli utenti attivi verranno terminate entro %2.
					|Continuare?';
					|pl = 'Sesje wszystkich aktywnych użytkowników zostaną zakończone przez %2.
					|Kontynuuj?';
					|tr = 'Tüm aktif kullanıcıların oturumu %2. 
					|Devam edilsin mi?'");
			EndIf;
			Notification = New CallbackDescription("ApplyCompletion", ThisObject, "Confirmation");
			QueryText = StringFunctionsClientServer.SubstituteParametersToString(QueryText, Object.LockEffectiveFrom - 900, Object.LockEffectiveFrom);
			ShowQueryBox(Notification, QueryText, QuestionDialogMode.OKCancel,,, QuestionTitle);
		EndIf;
		
	Else
		
		Notification = New CallbackDescription("ApplyCompletion", ThisObject, "Confirmation");
		RunCallback(Notification, DialogReturnCode.OK);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ApplyCompletion(Response, Variant) Export
	
	CurrentSessionDate = CommonClient.SessionDate();
	
	If Variant = "LockTimeTooSoon" Or Variant = "LockTimeTooLate" Then
		If Response = DialogReturnCode.Yes Then
			Object.LockEffectiveFrom = CurrentSessionDate + 10 * 60;
		ElsIf Response <> DialogReturnCode.No Then
			Return;
		EndIf;
	ElsIf Variant = "Confirmation" Then
		If Response <> DialogReturnCode.OK Then
			Return;
		EndIf;
	EndIf;
	
	If CorrectAdministrationParametersEntered And IsSystemAdministrator And Not IsFileInfobase
		And CurrentLockValue <> Object.DisableScheduledJobs Then
		
		Try
			SetScheduledJobLockAtServer(AdministrationParameters);
		Except
			EventLogClient.AddMessageForEventLog(IBConnectionsClient.EventLogEvent(), "Error",
				ErrorProcessing.DetailErrorDescription(ErrorInfo()),, True);
			Items.ErrorGroup.Visible = True;
			Items.ErrorText.Title = ErrorProcessing.BriefErrorDescription(ErrorInfo());
			Return;
		EndTry;
		
	EndIf;
	
	If Not IsFileInfobase And Not CorrectAdministrationParametersEntered And SessionWithoutSeparators Then
		
		CallbackDescription = New CallbackDescription("AfterGetAdministrationParametersOnLock", ThisObject);
		FormCaption = NStr("vi = 'Quản lý phong tỏa các phiên làm việc';
							|ru = 'Управление блокировкой сеансов';
							|en = 'User sessions'; fa = 'جلسات کاربر';
							|it = 'Gestione blocco sessioni';
							|pl = 'Kontrola blokady sesji';
							|tr = 'Oturum kilidi yönetimi'");
		NoteLabel = NStr("vi = 'Để quản lý phong tỏa phiên làm việc,
			|hãy nhập tham số quản trị cụm máy chủ và cơ sở thông tin';
			|ru = 'Для управления блокировкой сеансов введите
			|параметры администрирования кластера серверов и информационной базы';
			|en = 'To manage user sessions, enter
			|the infobase and server cluster administration parameters'; fa = 'To manage user sessions, enter
			|the infobase and server cluster administration parameters';
			|it = 'Per la gestione del blocco delle sessioni, inserire
			|i parametri di amministrazione del cluster di server e infobase';
			|pl = 'Aby zarządzać blokowaniem sesji, wprowadź
			|parametry administrowania klastera serwerów i bazy informacyjnej';
			|tr = 'Oturum engellemeyi yönetmek için sunucu kümesi parametrelerini ve infobase yönetim ayarlarını girin
			|'");
		IBConnectionsClient.ShowAdministrationParameters(CallbackDescription, True,
			True, AdministrationParameters, FormCaption, NoteLabel);
		
	Else
		
		AfterGetAdministrationParametersOnLock(True, Undefined);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Stop(Command)
	
	If Not IsFileInfobase And Not CorrectAdministrationParametersEntered And SessionWithoutSeparators Then
		
		CallbackDescription = New CallbackDescription("AfterGetAdministrationParametersOnUnlock", ThisObject);
		FormCaption = NStr("vi = 'Quản lý phong tỏa các phiên làm việc';
							|ru = 'Управление блокировкой сеансов';
							|en = 'User sessions'; fa = 'جلسات کاربر';
							|it = 'Gestione blocco sessioni';
							|pl = 'Kontrola blokady sesji';
							|tr = 'Oturum kilidi yönetimi'");
		NoteLabel = NStr("vi = 'Để quản lý phong tỏa phiên làm việc,
			|hãy nhập tham số quản trị cụm máy chủ và cơ sở thông tin';
			|ru = 'Для управления блокировкой сеансов введите
			|параметры администрирования кластера серверов и информационной базы';
			|en = 'To manage user sessions, enter
			|the infobase and server cluster administration parameters'; fa = 'To manage user sessions, enter
			|the infobase and server cluster administration parameters';
			|it = 'Per la gestione del blocco delle sessioni, inserire
			|i parametri di amministrazione del cluster di server e infobase';
			|pl = 'Aby zarządzać blokowaniem sesji, wprowadź
			|parametry administrowania klastera serwerów i bazy informacyjnej';
			|tr = 'Oturum engellemeyi yönetmek için sunucu kümesi parametrelerini ve infobase yönetim ayarlarını girin
			|'");
		IBConnectionsClient.ShowAdministrationParameters(CallbackDescription, True,
			True, AdministrationParameters, FormCaption, NoteLabel);
		
	Else
		
		AfterGetAdministrationParametersOnUnlock(True, Undefined);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AdministrationParameters(Command)
	
	CallbackDescription = New CallbackDescription("AfterGetAdministrationParameters", ThisObject);
	FormCaption = NStr("vi = 'Quản lý phong tỏa nhiệm vụ thường kỳ';
						|ru = 'Управление блокировкой регламентных заданий';
						|en = 'Scheduled job locks'; fa = 'Scheduled job locks';
						|it = 'Gestione blocco dei task di routine';
						|pl = 'Zarządzanie rutynowymi blokadami zadań';
						|tr = 'Zamanlanmış iş kilidi yönetimi'");
	NoteLabel = NStr("vi = 'Để quản lý phong tỏa nhiệm vụ thường kỳ,
		|hãy nhập tham số quản trị cụm máy chủ và cơ sở thông tin';
		|ru = 'Для управления блокировкой регламентных заданий введите
		|параметры администрирования кластера серверов и информационной базы';
		|en = 'To manage scheduled job locks, enter
		|the infobase and server cluster administration parameters'; fa = 'To manage scheduled job locks, enter
		|the infobase and server cluster administration parameters';
		|it = 'Per la gestione del blocco dei compiti di routine, inserire
		|i parametri di amministrazione del cluster di server e infobase';
		|pl = 'Dla zarządzania blokowaniem zadań reglamentowanych wprowadź
		|parametry administrowania klastera serwerów i bazy informacyjnej';
		|tr = 'Zamanlanmış görevlerin kilitlenmesini yönetmek için sunucu kümesi parametrelerini ve infobase yönetim ayarlarını girin
		|'");
	IBConnectionsClient.ShowAdministrationParameters(CallbackDescription, True,
		True, AdministrationParameters, FormCaption, NoteLabel);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.InitialUserAuthorizationRestrictionStatus.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsersAuthorizationRestrictionStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = NStr("vi = 'Cấm';
								|ru = 'Запрещено';
								|en = 'Denied'; fa = 'رد شده';
								|it = 'Non consentito';
								|pl = 'Denied';
								|tr = 'Yasak'");

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ErrorNoteText);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.InitialUserAuthorizationRestrictionStatus.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsersAuthorizationRestrictionStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = NStr("vi = 'Dự tính';
								|ru = 'Запланировано';
								|en = 'Scheduled'; fa = 'برنامه‌ریزی‌شده';
								|it = 'Pianificato';
								|pl = 'Scheduled';
								|tr = 'Planlanan'");

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ErrorNoteText);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.InitialUserAuthorizationRestrictionStatus.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsersAuthorizationRestrictionStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = NStr("vi = 'Đã hết hạn';
								|ru = 'Истекло';
								|en = 'Expired'; fa = 'منقضی‌شده';
								|it = 'Scaduto';
								|pl = 'Expired';
								|tr = 'Süresi doldu'");

	Item.Appearance.SetParameterValue("TextColor", StyleColors.LockedAttributeColor);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.InitialUserAuthorizationRestrictionStatus.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsersAuthorizationRestrictionStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = NStr("vi = 'Được phép';
								|ru = 'Разрешено';
								|en = 'Allowed'; fa = 'مجاز';
								|it = 'Consentito';
								|pl = 'Allowed';
								|tr = 'İzin verilen'");

	Item.Appearance.SetParameterValue("TextColor", StyleColors.FormTextColor);

EndProcedure

&AtServer
Function CheckLockPreconditions()
	
	Return CheckFilling();

EndFunction

&AtServer
Function LockUnlock()
	
	Try
		FormAttributeToValue("Object").PerformInstallation();
		Items.ErrorGroup.Visible = False;
	Except
		WriteLogEvent(IBConnections.EventLogEvent(),
			EventLogLevel.Error,,, 
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		If IsSystemAdministrator Then
			Items.ErrorGroup.Visible = True;
			Items.ErrorText.Title = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		EndIf;
		Return False;
	EndTry;
	
	SetInitialUserAuthorizationRestrictionStatus();
	SessionCount = IBConnections.InfobaseSessionsCount();
	Return True;
	
EndFunction

&AtServer
Function CancelLock()
	
	Try
		FormAttributeToValue("Object").CancelLock();
	Except
		WriteLogEvent(IBConnections.EventLogEvent(),
			EventLogLevel.Error,,, 
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		If IsSystemAdministrator Then
			Items.ErrorGroup.Visible = True;
			Items.ErrorText.Title = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		EndIf;
		Return False;
	EndTry;
	
	SetInitialUserAuthorizationRestrictionStatus();
	Items.GroupMode.CurrentPage = Items.SettingsPage;
	RefreshSettingsPage();
	Return True;
	
EndFunction

&AtServer
Procedure RefreshSettingsPage()
	
	Items.DisableScheduledJobsGroup.Enabled = True;
	Items.ApplyCommand.Visible = True;
	Items.ApplyCommand.DefaultButton = True;
	Items.StopCommand.Visible = False;
	Items.ApplyCommand.Title = ?(Object.DisableUserAuthorisation,
		NStr("vi = 'Bỏ phong tỏa';
			|ru = 'Снять блокировку';
			|en = 'Remove lock'; fa = 'Remove lock';
			|it = 'Rimuovere il blocco';
			|pl = 'Odblokuj';
			|tr = 'Blokeyi kaldır'"), NStr("vi = 'Thiết lập phong tỏa';
										|ru = 'Установить блокировку';
										|en = 'Set lock'; fa = 'Set lock';
										|it = 'Inserire il blocco';
										|pl = 'Ustaw blokadę';
										|tr = 'Kilidi ayarla'"));
	Items.DisableScheduledJobs.Title = ?(Object.DisableScheduledJobs,
		NStr("vi = 'Vẫn để phong tỏa công việc của nhiệm vụ thường kỳ';
			|ru = 'Оставить блокировку работы регламентных заданий';
			|en = 'Keep scheduled job locks'; fa = 'Keep scheduled job locks';
			|it = 'Lasciare il blocco di funzionamento dei task di routine';
			|pl = 'Zostaw blokadę na rutynowe zadania związane z blokowaniem';
			|tr = 'Zamanlanmış işlerin kilitleme işlemlerini sürdürün'"), NStr("vi = 'Cấm nhiệm vụ thường kỳ';
														|ru = 'Также запретить работу регламентных заданий';
														|en = 'Lock scheduled jobs'; fa = 'قفل کارهای زمان‌بندی‌شده';
														|it = 'Proibire anche il funzionamento dei task di routine';
														|pl = 'Zakazuj także wykonywania rutynowych zadań';
														|tr = 'Ayrıca planlanan işleri de devre dışı bırak'"));
	
EndProcedure

&AtClientAtServerNoContext
Procedure RefreshStatePage(Form)
	
	Form.Items.DisableScheduledJobsGroup.Enabled = False;
	Form.Items.StopCommand.Visible = True;
	Form.Items.ApplyCommand.Visible = False;
	Form.Items.CloseCommand.DefaultButton = True;
	UpdateLockState(Form);
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateLockState(Form)
	
	If Form.SessionCount = 0 Then
		
		StateText = NStr("vi = 'Việc chặn đang chờ xử lý... 
			|Công việc của người dùng trong ứng dụng sẽ bị cấm vào thời gian đã chỉ định';
			|ru = 'Ожидается установка блокировки...
			|Работа пользователей в приложении будет запрещена в указанное время';
			|en = 'Lock pending…
			|Users will be unable to use the app while the lock is set.'; fa = 'Lock pending…
			|Users will be unable to use the app while the lock is set.';
			|it = 'Ожидается установка блокировки...
			|Работа пользователей в приложении будет запрещена в указанное время';
			|pl = 'Lock pending…
			|Users will be unable to use the app while the lock is set.';
			|tr = 'Kilitleme bekleniyor...
			|Uygulamadaki kullanıcıların çalışması belirtilen zamanda yasaklanacak'");
		
	Else
		
		StateText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Vui lòng chờ trong giây lát...
			|Công việc của người sử dụng đang kết thúc. Còn lại %1 phiên làm việc đang hoạt động';
			|ru = 'Пожалуйста, подождите...
			|Работа пользователей завершается. Осталось активных сеансов: %1';
			|en = 'Please wait…
			|Closing user sessions. Active sessions remaining: %1.'; fa = 'Please wait…
			|Closing user sessions. Active sessions remaining: %1.';
			|it = 'Attendere per favore...
			|Il lavoro degli utenti sta per terminare. Rimangono sessioni attive: %1';
			|pl = 'Proszę czekać...
			|Użytkownicy się wyłączają. Pozostały aktywne sesje: %1';
			|tr = 'Lütfen bekleyin...
			|Kullanıcı oturumları kapatılıyor. Kalan aktif oturumlar: %1'"),
			Form.SessionCount);
			
	EndIf;
	
	Form.Items.State.Title = StateText;
	
EndProcedure

&AtServer
Procedure GetLockParameters()
	DataProcessor = FormAttributeToValue("Object");
	Try
		DataProcessor.GetLockParameters();
		Items.ErrorGroup.Visible = False;
	Except
		WriteLogEvent(IBConnections.EventLogEvent(),
			EventLogLevel.Error,,, 
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		If IsSystemAdministrator Then
			Items.ErrorGroup.Visible = True;
			Items.ErrorText.Title = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		EndIf;
	EndTry;
	
	ValueToFormAttribute(DataProcessor, "Object");
	
EndProcedure

&AtServer
Procedure SetInitialUserAuthorizationRestrictionStatus()
	
	GetLockParameters();
	
	InitialUserAuthorizationRestrictionStatusValue = Object.DisableUserAuthorisation;
	If Object.DisableUserAuthorisation Then
		If CurrentSessionDate() < Object.LockEffectiveFrom Then
			InitialUserAuthorizationRestrictionStatus = NStr("vi = 'Công việc của người sử dụng trong ứng dụng sẽ bị cấm vào thời gian đã chỉ ra';
															|ru = 'Работа пользователей в приложении будет запрещена в указанное время';
															|en = 'Users will be denied access to the application at the specified time'; fa = 'Users will be denied access to the application at the specified time';
															|it = 'Работа пользователей в приложении будет запрещена в указанное время';
															|pl = 'Users will be denied access to the application at the specified time';
															|tr = 'Uygulamada kullanıcı işlemi belirtilen zamanda yasaklanacaktır'");
			UsersAuthorizationRestrictionStatus = "Scheduled";
		ElsIf CurrentSessionDate() > Object.LockEffectiveTo And Object.LockEffectiveTo <> '00010101' Then
			InitialUserAuthorizationRestrictionStatus = NStr("vi = 'Cho phép người sử dụng làm việc với ứng dụng (đã hết hạn cấm)';
															|ru = 'Работа пользователей в приложении разрешена (истек срок запрета)';
															|en = 'Users are allowed to log in to the application (the lock has expired)'; fa = 'Users are allowed to log in to the application (the lock has expired)';
															|it = 'Работа пользователей в приложении разрешена (истек срок запрета)';
															|pl = 'Users are allowed to log in to the application (the lock has expired)';
															|tr = 'Uygulamada kullanıcı işlemine izin verilir (yasak süresi sona ermiştir)'");
			UsersAuthorizationRestrictionStatus = "Expired";
		Else
			InitialUserAuthorizationRestrictionStatus = NStr("vi = 'Cấm người sử dụng làm việc với ứng dụng';
															|ru = 'Работа пользователей в приложении запрещена';
															|en = 'Users are denied access to the application'; fa = 'Users are denied access to the application';
															|it = 'Работа пользователей в приложении запрещена';
															|pl = 'Users are denied access to the application';
															|tr = 'Uygulamada kullanıcı işlemi yasaktır'");
			UsersAuthorizationRestrictionStatus = "Prohibited";
		EndIf;
	Else
		InitialUserAuthorizationRestrictionStatus = NStr("vi = 'Cho phép người sử dụng làm việc trong ứng dụng';
														|ru = 'Работа пользователей в приложении разрешена';
														|en = 'Users can access the application'; fa = 'Users can access the application';
														|it = 'Работа пользователей в приложении разрешена';
														|pl = 'Users can access the application';
														|tr = 'Uygulamada kullanıcı işlemine izin verilir'");
		UsersAuthorizationRestrictionStatus = "Allowed1";
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterGetAdministrationParameters(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		
		AdministrationParameters = Result;
		CorrectAdministrationParametersEntered = True;
		
		Try
			Object.DisableScheduledJobs = InfobaseScheduledJobLockAtServer(AdministrationParameters);
			CurrentLockValue = Object.DisableScheduledJobs;
		Except;
			CorrectAdministrationParametersEntered = False;
			Raise;
		EndTry;
		
		Items.DisableScheduledJobsGroup.CurrentPage = Items.ScheduledJobManagementGroup;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterGetAdministrationParametersOnLock(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	ElsIf TypeOf(Result) = Type("Structure") Then
		AdministrationParameters = Result;
		CorrectAdministrationParametersEntered = True;
		EnableScheduledJobLockManagement();
		IBConnectionsClient.SaveAdministrationParameters(AdministrationParameters);
	ElsIf TypeOf(Result) = Type("Boolean") And CorrectAdministrationParametersEntered Then
		IBConnectionsClient.SaveAdministrationParameters(AdministrationParameters);
	EndIf;
	
	If Not LockUnlock() Then
		Return;
	EndIf;
	
	IBConnectionsClient.SetTheUserShutdownMode(Object.DisableUserAuthorisation);
	
	If Object.DisableUserAuthorisation Then
		Items.GroupMode.CurrentPage = Items.LockStatePage;
		RefreshStatePage(ThisObject);
	Else
		Items.GroupMode.CurrentPage = Items.SettingsPage;
		RefreshSettingsPage();
	EndIf;
	
	ShowUserNotification(NStr("vi = 'Phong tỏa công việc của người dùng';
								|ru = 'Блокировка работы пользователей';
								|en = 'User access'; fa = 'User access';
								|it = 'Il blocco di lavoro degli utenti';
								|pl = 'Blokada pracy użytkownika';
								|tr = 'Kullanıcı çalışmasını kilitleme'"),
		New CallbackDescription("OpeningHandlerOfAppWorkBlockForm", IBConnectionsClient),
		?(Object.DisableUserAuthorisation, NStr("vi = 'Đã thiết lập phong tỏa.';
												|ru = 'Блокировка установлена.';
												|en = 'User access is denied.'; fa = 'User access is denied.';
												|it = 'Il blocco è inserito.';
												|pl = 'Blokada jest ustawiona.';
												|tr = 'Kilit ayarlandı.'"), NStr("vi = 'Đã gỡ bỏ phong tỏa.';
																						|ru = 'Блокировка снята.';
																						|en = 'User access is allowed.'; fa = 'User access is allowed.';
																						|it = 'Il blocco è rimosso.';
																						|pl = 'Blokada jest wyłączona.';
																						|tr = 'Kilidi kaldırıldı.'")),
		PictureLib.DialogInformation);
	
EndProcedure

&AtClient
Procedure AfterGetAdministrationParametersOnUnlock(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	ElsIf TypeOf(Result) = Type("Structure") Then
		AdministrationParameters = Result;
		CorrectAdministrationParametersEntered = True;
		EnableScheduledJobLockManagement();
		IBConnectionsClient.SaveAdministrationParameters(AdministrationParameters);
	ElsIf TypeOf(Result) = Type("Boolean") And CorrectAdministrationParametersEntered Then
		IBConnectionsClient.SaveAdministrationParameters(AdministrationParameters);
	EndIf;
	
	If Not CancelLock() Then
		Return;
	EndIf;
	
	IBConnectionsClient.SetTheUserShutdownMode(False);
	ShowMessageBox(,NStr("vi = 'Đã hủy bỏ kết thúc công việc của những người sử dụng đang làm việc.';
						|ru = 'Завершение работы активных пользователей отменено.';
						|en = 'Closing active user sessions is canceled.'; fa = 'Closing active user sessions is canceled.';
						|it = 'Il termine di lavoro degli utenti attivi è annullato.';
						|pl = 'Zamknij pracę aktywnych użytkowników anulowanych.';
						|tr = 'Aktif kullanıcıların uygulamadan çıkarılması iptal edildi.'"));
	
EndProcedure

&AtClient
Procedure EnableScheduledJobLockManagement()
	
	Object.DisableScheduledJobs = InfobaseScheduledJobLockAtServer(AdministrationParameters);
	CurrentLockValue = Object.DisableScheduledJobs;
	Items.DisableScheduledJobsGroup.CurrentPage = Items.ScheduledJobManagementGroup;
	
EndProcedure

&AtServer
Procedure SetScheduledJobLockAtServer(AdministrationParameters)
	
	ClusterAdministration.SetInfobaseScheduledJobLock(
		AdministrationParameters, Undefined, Object.DisableScheduledJobs);
	
EndProcedure

&AtServer
Function InfobaseScheduledJobLockAtServer(AdministrationParameters)
	
	Return ClusterAdministration.InfobaseScheduledJobLock(AdministrationParameters);
	
EndFunction

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
