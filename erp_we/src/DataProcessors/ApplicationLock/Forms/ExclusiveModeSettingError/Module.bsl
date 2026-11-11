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
	
	Title = ?(ValueIsFilled(Parameters.Title), Parameters.Title, Title);
	Items.ErrorMessageText.Title = ?(ValueIsFilled(Parameters.ErrorMessageText),
		Parameters.ErrorMessageText, Items.ErrorMessageText.Title);
	
	CheckExclusiveModeAtServer();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If ExclusiveModeAvailable Then
		Cancel = True;
		RunCallback(CallbackDescriptionOnClose, False);
		Return;
	EndIf;
	
	If Parameters.ShouldCloseAllSessionsButCurrent Then
		IBConnectionsClient.SetTerminateAllSessionsExceptCurrentFlag(True);
	EndIf;
	AttachIdleHandler("CheckExclusiveMode", 30);
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	If Parameters.ShouldCloseAllSessionsButCurrent Then
		IBConnectionsClient.SetTerminateAllSessionsExceptCurrentFlag(False);
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ActiveUsersClick(Item)
	
	CheckExclusiveModeAtServer();
	CallbackDescription = New CallbackDescription("OpenActiveUserListCompletion", ThisObject);
	OpenForm("DataProcessor.ActiveUsers.Form.ActiveUsers", , , , , ,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ActiveUsers2Click(Item)
	
	CheckExclusiveModeAtServer();
	CallbackDescription = New CallbackDescription("OpenActiveUserListCompletion", ThisObject);
	OpenForm("DataProcessor.ActiveUsers.Form.ActiveUsers" , , , , , ,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EndSessionsAndRepeat(Command)
	
	Items.GroupPages.CurrentPage = Items.Waiting;
	Items.FormRetryApplicationStart.Visible = False;
	Items.TerminateSessionsAndRestartApplicationForm.Visible = False;
	
	// Setting the infobase lock parameters.
	CheckExclusiveMode();
	LockFileInfobase();
	IBConnectionsClient.SetTheUserShutdownMode(True);
	AttachIdleHandler("WaitForUserSessionTermination", 60);
	
EndProcedure

&AtClient
Procedure AbortApplicationStart(Command)
	
	CancelFileInfobaseLock();
	
	Close(True);
	
EndProcedure

&AtClient
Procedure RetryApplicationStart(Command)
	
	Close(False);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure OpenActiveUserListCompletion(Result, AdditionalParameters) Export
	CheckExclusiveMode();
EndProcedure

&AtClient
Procedure CheckExclusiveMode()
	
	CheckExclusiveModeAtServer();
	If ExclusiveModeAvailable Then
		Close(False);
		Return;
	EndIf;
		
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateActiveSessionCount(Form)
	
	If Form.ActiveSessionCount > 0 Then
		HyperlinkText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Người sử dụng đang làm việc (%1)';
																						|ru = 'Активные пользователи (%1)';
																						|en = 'Active users (%1)'; fa = 'کاربران فعال (%1)';
																						|it = 'Gli utenti attivi (%1)';
																						|pl = 'Aktywni użytkownicy (%1)';
																						|tr = 'Aktif kullanıcılar (%1)'"), 
			Form.ActiveSessionCount);
	Else
		HyperlinkText = NStr("vi = 'Người sử dụng đang làm việc';
							|ru = 'Активные пользователи';
							|en = 'Active users'; fa = 'کاربران فعال';
							|it = 'Utenti attivi';
							|pl = 'Aktywni użytkownicy';
							|tr = 'Aktif kullanıcılar'");
	EndIf;	
	
	Form.Items.ActiveUsers.Title = HyperlinkText;
	Form.Items.ActiveUsersWait.Title = HyperlinkText;
	Form.Items.ActiveUsers.ExtendedTooltip.Title = Form.ExclusiveModeSettingError;
	Form.Items.ActiveUsersWait.ExtendedTooltip.Title = Form.ExclusiveModeSettingError;
	
	If Form.ActiveSessionCount = 0 And IsBlankString(Form.ExclusiveModeSettingError) Then
		Form.Items.ErrorMessageText.Title = NStr("vi = 'Những người dùng khác đã hoàn thành công việc của họ:';
												|ru = 'Другие пользователи уже завершили свою работу:';
												|en = 'Other users have already signed out:'; fa = 'Other users have already signed out:';
												|it = 'Altri utenti hanno già terminato il loro lavoro:';
												|pl = 'Inni użytkownicy już skończyli swoją pracę:';
												|tr = 'Diğer kullanıcılar işlerini artık tamamladılar:'");
		Form.Items.FixErrorText.Title = NStr("vi = 'Để tiếp tục, nhấp Thử lại.';
											|ru = 'Для продолжения нажмите Повторить.';
											|en = 'To continue, click Retry.'; fa = 'To continue, click Retry.';
											|it = 'Per continuare premere Ripeti.';
											|pl = 'W celu kontynuacji naciśnij Powtórz.';
											|tr = 'Devam etmek için Tekrarla butonuna tıklayın.'");
	Else	
		If ValueIsFilled(Form.Parameters.ErrorTextExitFailed) Then
			ErrorMessageText = Form.Parameters.ErrorTextExitFailed;
		Else	
			ErrorMessageText = NStr("vi = 'Không thể thực hiện cập nhật phiên bản ứng dụng, bởi vì không thể kết thúc công việc của người sử dụng:';
									|ru = 'Невозможно выполнить обновление версии приложения, т.к. не удалось завершить работу пользователей:';
									|en = 'Cannot update the app because the following users are still signed in:'; fa = 'Cannot update the app because the following users are still signed in:';
									|it = 'Невозможно выполнить обновление версии приложения, т.к. не удалось завершить работу пользователей:';
									|pl = 'Cannot update the app because the following users are still signed in:';
									|tr = 'Şu kullanıcı oturumları hala etkin olduğundan uygulama sürümü güncellenemiyor:'");
		EndIf;
		Form.Items.ErrorMessageText.Title = ErrorMessageText;
		Form.Items.FixErrorText.Title = NStr("vi = 'Để tiếp tục, cần kết thúc công việc của người sử dụng.';
											|ru = 'Для продолжения необходимо завершить их работу.';
											|en = 'To continue, close their sessions.'; fa = 'برای ادامه، جلسات آن‌ها را ببندید.';
											|it = 'Per continuare, è necessario completare il loro lavoro.';
											|pl = 'Aby kontynuować należy zakończyć ich pracę.';
											|tr = 'Devam etmek için kapatın.'");
	EndIf;	
	
EndProcedure

&AtServer
Procedure CheckExclusiveModeAtServer()
	
	InfobaseSessions = GetInfoBaseSessions();
	CurrentUserSessionNumber = InfoBaseSessionNumber();
	ActiveSessionCount = 0;
	For Each IBSession In InfobaseSessions Do
		If IBSession.ApplicationName = "Designer" And Not Parameters.ShouldCloseDesignerSession
			Or IBSession.SessionNumber = CurrentUserSessionNumber Then
			Continue;
		EndIf;
		ActiveSessionCount = ActiveSessionCount + 1;
	EndDo;
	
	ExclusiveModeAvailable = False;
	ExclusiveModeSettingError = "";
	If ActiveSessionCount = 0 Then
		Try
			SetExclusiveMode(True);
		Except
			ExclusiveModeSettingError = NStr("vi = 'Thông tin kỹ thuật:';
											|ru = 'Техническая информация:';
											|en = 'Details:'; fa = 'جزئیات:';
											|it = 'Informazione tecnica:';
											|pl = 'Informacje techniczne:';
											|tr = 'Teknik bilgi:'") + " " 
				+ ErrorProcessing.BriefErrorDescription(ErrorInfo());
		EndTry;
		If ExclusiveMode() Then
			SetExclusiveMode(False);
		EndIf;
		ExclusiveModeAvailable = True;
	EndIf;	
	UpdateActiveSessionCount(ThisObject);
	
EndProcedure

&AtClient
Procedure WaitForUserSessionTermination()
	
	UserSessionsTerminationDuration = UserSessionsTerminationDuration + 1;
	If UserSessionsTerminationDuration < 8 Then
		Return;
	EndIf;
	
	CancelFileInfobaseLock();
	Items.GroupPages.CurrentPage = Items.Information;
	UpdateActiveSessionCount(ThisObject);
	Items.FormRetryApplicationStart.Visible = True;
	Items.TerminateSessionsAndRestartApplicationForm.Visible = True;
	DetachIdleHandler("WaitForUserSessionTermination");
	UserSessionsTerminationDuration = 0;
	
EndProcedure

&AtServer
Procedure LockFileInfobase()
	
	Object.DisableUserAuthorisation = True;
	
	Object.LockEffectiveFrom = CurrentSessionDate() + 2*60;
	BlockingPeriod = ?(ValueIsFilled(Parameters.BlockingPeriod), Parameters.BlockingPeriod, 5*60);
	Object.LockEffectiveTo = Object.LockEffectiveFrom + BlockingPeriod;
	Object.MessageForUsers = ?(ValueIsFilled(Parameters.LoginMessage), Parameters.LoginMessage, NStr("vi = 'Tạm thời, không cho phép làm việc với ứng dụng để cập nhật lên phiên bản mới.';
																									|ru = 'Работа с приложением временно недоступна для обновления на новую версию.';
																									|en = 'The app is unavailable while updating'; fa = 'The app is unavailable while updating';
																									|it = 'Работа с приложением временно недоступна для обновления на новую версию.';
																									|pl = 'The app is unavailable while updating';
																									|tr = 'Uygulama, yeni bir sürüme güncelleme için geçici olarak kullanılamıyor.'"));
	
	Try
		FormAttributeToValue("Object").PerformInstallation();
	Except
		WriteLogEvent(IBConnections.EventLogEvent(),
			EventLogLevel.Error,,, 
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Common.MessageToUser(ErrorProcessing.BriefErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

&AtServer
Procedure CancelFileInfobaseLock()
	
	FormAttributeToValue("Object").CancelLock();
	
EndProcedure

#EndRegion
