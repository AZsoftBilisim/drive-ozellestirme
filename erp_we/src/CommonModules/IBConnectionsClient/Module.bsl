///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Opens the form for entering infobase and/or cluster administration parameters.
//
// Parameters:
//  OnCloseNotifyDescription - CallbackDescription - a handler that will be called once the administration
//	                                                   parameters are entered.
//  PromptForIBAdministrationParameters - Boolean - indicates whether the infobase administration parameters
//	                                                   must be entered.
//  PromptForClusterAdministrationParameters - Boolean - indicates whether the cluster administration parameters
//	                                                         must be entered.
//  AdministrationParameters - See StandardSubsystemsServer.AdministrationParameters.
//  Title - String - a form title that explains the purpose of requesting the administration parameters.
//  NoteLabel - String - a description of the action in whose context the administration parameters are requested.
//
Procedure ShowAdministrationParameters(OnCloseNotifyDescription, PromptForIBAdministrationParameters,
	PromptForClusterAdministrationParameters, AdministrationParameters = Undefined,
	Title = "", NoteLabel = "") Export
	
	FormParameters = New Structure;
	FormParameters.Insert("PromptForIBAdministrationParameters", PromptForIBAdministrationParameters);
	FormParameters.Insert("PromptForClusterAdministrationParameters", PromptForClusterAdministrationParameters);
	FormParameters.Insert("AdministrationParameters", AdministrationParameters);
	FormParameters.Insert("Title", Title);
	FormParameters.Insert("NoteLabel", NoteLabel);
	
	OpenForm("CommonForm.ApplicationAdministrationParameters", FormParameters,,,,,OnCloseNotifyDescription);
	
EndProcedure

// Sets and disables the session termination mode.
// On exit and before lock, all active users will be notified about the session termination
// and prompted
// to save their data.
// The current session closes last.
//
// Parameters:
//  ExitApplication - Boolean
//
Procedure SetTheUserShutdownMode(Val ExitApplication) Export
	
	SetUserTerminationInProgressFlag(ExitApplication);
	SetUserExitControl(Not ExitApplication);
	
	If ExitApplication Then
		CurrentMode = IBConnectionsServerCall.SessionLockParameters(True);
		EndUserSessions(CurrentMode);
	EndIf;
	
EndProcedure

// Indicates whether it is necessary to close the session with enabled
// application lock.
//
// Parameters:
//   Value - Boolean - True if closing the current session is not required.
//
Procedure SetTerminateAllSessionsExceptCurrentFlag(Value) Export
	
	ClientParameters().TerminateAllSessionsExceptCurrent = Value;
	
EndProcedure

#EndRegion

#Region Internal

// Sets the SessionTerminationInProgress variable to Value.
//
// Parameters:
//   Value - Boolean - a value being set.
//
Procedure SetUserTerminationInProgressFlag(Value) Export
	
	ClientParameters().SessionTerminationInProgress = Value;
	
EndProcedure

#Region ConfigurationSubsystemsEventHandlers

// The procedure is called when a user works interactively with a data area.
//
// Parameters:
//  StartupParameters - Array - an array of strings separated with semicolons ";" in the start parameter
//                     passed to the configuration using the /C command line key.
//  Cancel            - Boolean - a return value. If True,
//                     the OnStart event processing is canceled.
//
Procedure LaunchParametersOnProcess(StartupParameters, Cancel) Export
	
	If Not IsSubsystemUsed() Then
		Return;
	EndIf;
	
	Cancel = Cancel Or ProcessStartParameters(StartupParameters);
	
EndProcedure

// See CommonClientOverridable.BeforeStart.
Procedure BeforeStart(Parameters) Export
	
	ClientParameters = StandardSubsystemsClient.ClientParametersOnStart();
	
	If Not ClientParameters.Property("DataAreaSessionsLocked") Then
		Return;
	EndIf;
	
	Parameters.InteractiveHandler = New CallbackDescription(
		"BeforeStartInteractiveHandler", ThisObject);
	
EndProcedure

// See CommonClientOverridable.AfterStart.
Procedure AfterStart() Export
	
	If Not IsSubsystemUsed()
	 Or Not CommonClient.SeparatedDataUsageAvailable()
	 Or GetClientConnectionSpeed() <> ClientConnectionSpeed.Normal Then
		Return;
	EndIf;
	
	LockMode = StandardSubsystemsClient.ClientParametersOnStart().SessionLockParameters;
	CurrentTime = LockMode.CurrentSessionDate;
	If LockMode.Use 
		 And (Not ValueIsFilled(LockMode.Begin) Or CurrentTime >= LockMode.Begin) 
		 And (Not ValueIsFilled(LockMode.End) Or CurrentTime <= LockMode.End) Then
		// If a user logged in to the infobase despite the lock, they used the "/UC" startup option.
		// It is assumed that such a user session should not be closed.
		Return;
	EndIf;
	
	If StrFind(Upper(LaunchParameter), Upper("EndUserSessions")) > 0 Then
		Return;
	EndIf;
	
	SetUserExitControl(True);
	
	If LockMode.Use Then
		ClientParameters().DateOfLastLockMessage = CommonClient.SessionDate();
		SessionTerminationModeManagement(LockMode);
	EndIf;
	
EndProcedure

// Parameters:
//  Cancel - See CommonClientOverridable.BeforeExit.Cancel
//  Warnings - See CommonClientOverridable.BeforeExit.Warnings
//
Procedure BeforeExit(Cancel, Warnings) Export
	
	If SessionTerminationInProgress() Then
		WarningParameters = StandardSubsystemsClient.WarningOnExit();
		WarningParameters.HyperlinkText = NStr("vi = 'Chặn người sử dụng làm việc';
												|ru = 'Блокировка работы пользователей';
												|en = 'User access'; fa = 'User access';
												|it = 'Il blocco di lavoro degli utenti';
												|pl = 'Blokada pracy użytkownika';
												|tr = 'Kullanıcı çalışmasını kilitleme'");
		WarningParameters.WarningText = NStr("vi = 'Người sử dụng đã thoát khỏi phiên làm việc hiện tại';
											|ru = 'Из текущего сеанса выполняется завершение работы пользователей';
											|en = 'User sessions are being closed from the current session.'; fa = 'User sessions are being closed from the current session.';
											|it = 'Dalla sessione corrente si effettua la terminazione del lavoro degli utenti';
											|pl = 'W bieżącej sesji trwa kończenie pracy użytkowników';
											|tr = 'Geçerli oturumdan kullanıcı kapatma işlemi yapılır'");
		WarningParameters.OutputSingleWarning = True;
		
		Form = "DataProcessor.ApplicationLock.Form.InfobaseConnectionsLock";
		
		ActionOnClickHyperlink = WarningParameters.ActionOnClickHyperlink;
		ActionOnClickHyperlink.Form = Form;
		ActionOnClickHyperlink.ApplicationWarningForm = Form;
		
		Warnings.Add(WarningParameters);
	EndIf;
	
EndProcedure

// The procedure is called during an unsuccessful attempt to set exclusive mode in a file infobase.
//
// Parameters:
//  Notification - CallbackDescription - describes the object which must be passed control after closing this form.
//
Procedure OnOpenExclusiveModeSetErrorForm(Notification = Undefined, FormParameters = Undefined) Export
	
	OpenForm("DataProcessor.ApplicationLock.Form.ExclusiveModeSettingError", FormParameters,
		, , , , Notification);
	
EndProcedure

// Returns:
//  Structure:
//   * Title - String
//   * ErrorMessageText - String - Text of an error that occurs on form opening.
//   * ErrorTextExitFailed - String - Text of an error that occurs when trying to terminate user sessions.
//   * ShouldCloseDesignerSession - Boolean - If "True", the Designer session will be considered during the exclusive mode availability check.
//   * ShouldCloseAllSessionsButCurrent - Boolean
//   * LoginMessage - String
//   * BlockingPeriod - Number - Lock time in seconds.
//
Function ExclusiveModeSetErrorFormOpenParameters() Export
	
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("Title", "");
	FormOpenParameters.Insert("ErrorMessageText", "");
	FormOpenParameters.Insert("ErrorTextExitFailed", "");
	FormOpenParameters.Insert("ShouldCloseDesignerSession", False);
	FormOpenParameters.Insert("ShouldCloseAllSessionsButCurrent", False);
	FormOpenParameters.Insert("LoginMessage", "");
	FormOpenParameters.Insert("BlockingPeriod", 300);
	
	Return FormOpenParameters;
	
EndFunction

// Opens the user activity lock form.
//
Procedure OnOpenUserActivityLockForm(Notification = Undefined, FormParameters = Undefined) Export
	
	OpenForm("DataProcessor.ApplicationLock.Form.InfobaseConnectionsLock", FormParameters,
		, , , , Notification);
	
EndProcedure

// Replaces the default notification with a custom form containing the active user list.
//
// Parameters:
//  FormName - String - a return value.
//
Procedure OnDefineActiveUserForm(FormName) Export
	
	FormName = "DataProcessor.ActiveUsers.Form.ActiveUsers";
	
EndProcedure

// See StandardSubsystemsClient.OnReceiptServerNotification
Procedure OnReceiptServerNotification(NameOfAlert, Result) Export
	
	If Not IsSubsystemUsed() Then
		Return;
	EndIf;
	
	CurrentSessionDate = '00010101';
	ServerNotificationsClient.TimeoutExpired("",,, CurrentSessionDate);
	
	ClientParameters = ClientParameters();
	ClientParameters.LockCheckLastDate = CurrentSessionDate;
	
	If Result.Use Then
		ClientParameters.DateOfLastLockMessage = CurrentSessionDate;
	Else
		ClientParameters.DateOfLastLockMessage = '00010101';
		ClearUserNotifications();
		Return;
	EndIf;
	
	If SessionTerminationInProgress() Then
		If Not IsProcedureEndUserSessionsRunning() Then
			CurrentMode = IBConnectionsServerCall.SessionLockParameters(True);
			EndUserSessions(CurrentMode);
		EndIf;
		
	ElsIf IsUserExitControlEnabled() Then
		SessionTerminationModeManagement(Result);
	EndIf;
	
EndProcedure

// Parameters:
//  Parameters - See CommonOverridable.
//  AreNotificationsReceived - Boolean - Indicates that all notifications are received for the given period of time
//                                (via either the Collaboration System or the common server call).
//
Procedure BeforeRecurringClientDataSendToServer(Parameters, AreNotificationsReceived) Export
	
	If Not IsSubsystemUsed() Then
		Return;
	EndIf;
	
	CurrentSessionDate = '00010101';
	ServerNotificationsClient.TimeoutExpired("",,, CurrentSessionDate);
	
	ClientParameters = ClientParameters();
	
	If Not ValueIsFilled(ClientParameters.LockCheckLastDate)
	   And Not ValueIsFilled(ClientParameters.DateOfLastLockMessage) Then
		ClientParameters.LockCheckLastDate = CurrentSessionDate;
		Return;
	EndIf;
	
	If SessionTerminationInProgress() Then
		Interval = 60;
	ElsIf IsUserExitControlEnabled() Then
		If ClientParameters.DateOfLastLockMessage + 300 > CurrentSessionDate Then
			Interval = 60;
		ElsIf AreNotificationsReceived Then
			Return;
		Else
			Interval = 300;
		EndIf;
	Else
		Return;
	EndIf;
	
	If ClientParameters.LockCheckLastDate + Interval > CurrentSessionDate Then
		Return;
	EndIf;
	ClientParameters.LockCheckLastDate = CurrentSessionDate;
	
	ParameterName = "StandardSubsystems.UsersSessions.SessionsLock";
	Parameters.Insert(ParameterName, True);
	
EndProcedure

// See CommonClientOverridable.AfterRecurringReceiptOfClientDataOnServer
Procedure AfterRecurringReceiptOfClientDataOnServer(Results) Export
	
	ParameterName = "StandardSubsystems.UsersSessions.SessionsLock";
	Result = Results.Get(ParameterName);
	If Result = Undefined Then
		Return;
	EndIf;
	
	OnReceiptServerNotification(ParameterName, Result);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Function IsSubsystemUsed()
	
	// See also: IBConnections.IsSubsystemUsed
	Return Not CommonClient.DataSeparationEnabled();
	
EndFunction

// Returns:
//  Structure:
//   * TerminateAllSessionsExceptCurrent - Boolean
//   * SessionTerminationInProgress - Boolean
//   * ShouldControlUserExit - Boolean
//   * AdministrationParameters - See StandardSubsystemsServer.AdministrationParameters
//   * IsProcedureEndUserSessionsRunning - Boolean
//   * LockCheckLastDate - Date
//   * DateOfLastLockMessage - Date
//
Function ClientParameters()
	
	ParameterName = "StandardSubsystems.UserSessionTerminationParameters";
	ClientParameters = ApplicationParameters[ParameterName];
	If ClientParameters <> Undefined Then
		Return ClientParameters;
	EndIf;
	
	ClientParameters = New Structure;
	ClientParameters.Insert("TerminateAllSessionsExceptCurrent", False);
	ClientParameters.Insert("SessionTerminationInProgress", False);
	ClientParameters.Insert("ShouldControlUserExit", False);
	ClientParameters.Insert("AdministrationParameters", Undefined);
	ClientParameters.Insert("IsProcedureEndUserSessionsRunning", False);
	ClientParameters.Insert("LockCheckLastDate",    '00010101');
	ClientParameters.Insert("DateOfLastLockMessage", '00010101');
	
	ApplicationParameters.Insert(ParameterName, ClientParameters);
	Return ClientParameters;
	
EndFunction

Procedure SetUserExitControl(Value = True)
	
	ClientParameters().ShouldControlUserExit = Value;
	
EndProcedure

Function IsUserExitControlEnabled()
	
	Return ClientParameters().ShouldControlUserExit;
	
EndFunction

Procedure SetIsProcedureEndUserSessionsRunning(Value = True)
	
	ClientParameters().IsProcedureEndUserSessionsRunning = Value;
	
EndProcedure

Function IsProcedureEndUserSessionsRunning()
	
	Return ClientParameters().IsProcedureEndUserSessionsRunning;
	
EndFunction

// Terminate active sessions if infobase connection lock is set. 
// 
//
Procedure SessionTerminationModeManagement(CurrentMode)

	LockSet = CurrentMode.Use;
	
	If Not LockSet
	 Or CurrentMode.Property("Parameter")
	   And CurrentMode.Parameter = ServerNotificationsClient.SessionKey() Then
		Return;
	EndIf;
	
	CurrentMoment            = CurrentMode.CurrentSessionDate;
	LockEndTime = CurrentMode.End;
	
	If LockEndTime <> '00010101' And CurrentMoment > LockEndTime Then
		Return;
	EndIf;
	
	DataSeparationEnabled = CommonClient.DataSeparationEnabled();
	
	LockBeginTime  = CurrentMode.Begin;
	WaitTimeout = CurrentMode.SessionTerminationTimeout;
	
	StopTimeoutSaaS = 60; // One minute before the lock is set.
	StopTimeout               = 0;  // At the time when the lock is set.
	ExitWithConfirmationTimeout         = 60 + ?(DataSeparationEnabled, StopTimeoutSaaS, StopTimeout);
	WaitTimeout           = ?(WaitTimeout - 60 > ExitWithConfirmationTimeout,
		WaitTimeout, ExitWithConfirmationTimeout + 60);
	
	LockBeginTimeDate  = Format(LockBeginTime, "DLF=DD");
	LockBeginTimeTime = Format(LockBeginTime, "DLF=T");
	
	MessageText = IBConnectionsClientServer.ExtractLockMessage(CurrentMode.Message);
	Template = NStr("vi = 'Nên kết thúc công việc hiện tại và lưu lại tất cả dữ liệu của mình. Ứng dụng sẽ kết thúc %1 trong %2. 
		|%3';
		|ru = 'Рекомендуется завершить текущую работу и сохранить все свои данные. Работа приложения будет завершена %1 в %2. 
		|%3';
		|en = 'Please save your data. The app will be temporarily unavailable starting %1, %2.
		|%3'; fa = 'Please save your data. The app will be temporarily unavailable starting %1, %2.
		|%3';
		|it = 'Рекомендуется завершить текущую работу и сохранить все свои данные. Работа приложения будет завершена %1 в %2. 
		|%3';
		|pl = 'Please save your data. The app will be temporarily unavailable starting %1, %2.
		|%3';
		|tr = 'Mevcut oturumu sonlandırmanız ve tüm verileri kaydetmeniz tavsiye edilir. Uygulama %1 içinde kapatılacak%2.
		|%3'");
	MessageText = StringFunctionsClientServer.SubstituteParametersToString(Template, LockBeginTimeDate, LockBeginTimeTime, MessageText);
	
	If Not DataSeparationEnabled
		And (Not ValueIsFilled(LockBeginTime) Or LockBeginTime - CurrentMoment < StopTimeout) Then
		
		StandardSubsystemsClient.SkipExitConfirmation();
		Exit(False, CurrentMode.RestartOnCompletion);
		
	ElsIf DataSeparationEnabled
		And (Not ValueIsFilled(LockBeginTime) Or LockBeginTime - CurrentMoment < StopTimeoutSaaS) Then
		
		StandardSubsystemsClient.SkipExitConfirmation();
		Exit(False, False);
		
	ElsIf LockBeginTime - CurrentMoment <= ExitWithConfirmationTimeout Then
		
		AskOnTermination(MessageText, LockBeginTime);
		
	ElsIf LockBeginTime - CurrentMoment <= WaitTimeout Then
		
		ShowWarningOnExit(MessageText, LockBeginTime);
		
	EndIf;
	
EndProcedure

// Terminate active sessions when timeout.
// Then terminate the current session.
//
Procedure EndUserSessions(CurrentMode)

	LockBeginTime = CurrentMode.Begin;
	CurrentMoment = CurrentMode.CurrentSessionDate;
	SessionCount = CurrentMode.SessionCount;
	
	ClickNotification = New CallbackDescription("OpeningHandlerOfAppWorkBlockForm", ThisObject);
	
	If CurrentMoment < LockBeginTime Then
		Notify("UsersSessions",
			New Structure("Status, SessionCount", "RefreshEnabled", SessionCount));
		MessageText = NStr("vi = 'Dự tính phong tỏa công việc của người sử dụng trong %1.';
							|ru = 'Блокировка работы пользователей запланирована на %1.';
							|en = 'The application will be temporarily unavailable since %1.'; fa = 'The application will be temporarily unavailable since %1.';
							|it = 'Il blocco del lavoro degli utenti è pianificato per %1.';
							|pl = 'Blokadę pracy użytkowników zaplanowano na %1.';
							|tr = 'Kullanıcı oturumunun kilitlenmesi %1 planlandı.'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, LockBeginTime);
		ShowUserNotification(NStr("vi = 'Kết thúc công việc của người sử dụng';
									|ru = 'Завершение работы пользователей';
									|en = 'Closing user sessions'; fa = 'Closing user sessions';
									|it = 'Arresto del lavoro degli utenti';
									|pl = 'Zakończenie pracy użytkowników';
									|tr = 'Kullanıcı oturumlarının tamamlanması'"), 
			ClickNotification, MessageText, PictureLib.DialogInformation);
		Return;
	EndIf;
	
	If SessionCount <= 1 Then
		// All user sessions, except for the current one, are closed.
		// Last of all, offer to close the session started with the "EndUserSessions" parameter.
		// The closure order is driven by the need to update the configuration from a file.
		SetUserTerminationInProgressFlag(False);
		Notify("UsersSessions",
			New Structure("Status, SessionCount", "Done", SessionCount));
		TerminateThisSession();
		Return;
	EndIf; 
	
	LockSet = CurrentMode.Use;
	If Not LockSet Then
		Return;
	EndIf;
	
	// For file infobases, some connections might not be force-closed.
	If CommonClient.FileInfobase() Then
		Notify("UsersSessions",
			New Structure("Status, SessionCount", "RefreshEnabled", SessionCount));
		Return;
	EndIf;
	
	// After the lock is started, all user sessions must be closed.
	// If failed to do so, try to force-close them.
	
	Try
		AdministrationParameters = SavedAdministrationParameters();
		If CommonClient.ClientConnectedOverWebServer() Then
			IBConnectionsServerCall.DeleteAllSessionsExceptCurrent(AdministrationParameters);
		Else 
			IBConnectionsClientServer.DeleteAllSessionsExceptCurrent(AdministrationParameters);
		EndIf;
		SaveAdministrationParameters(Undefined);
	Except
		SetUserTerminationInProgressFlag(False);
		EventLogClient.AddMessageForEventLog(EventLogEvent(),
			"Error", ErrorProcessing.DetailErrorDescription(ErrorInfo()),, True);
		Notify("UsersSessions",
			New Structure("Status,SessionCount", "Error", SessionCount));
		ShowUserNotification(NStr("vi = 'Kết thúc công việc của người sử dụng';
									|ru = 'Завершение работы пользователей';
									|en = 'Closing user sessions'; fa = 'Closing user sessions';
									|it = 'Arresto del lavoro degli utenti';
									|pl = 'Zakończenie pracy użytkowników';
									|tr = 'Kullanıcı oturumlarının tamamlanması'"),
			ClickNotification,
			NStr("vi = 'Không thể kết thúc phiên làm việc. Chi tiết xem trong Nhật ký sự kiện.';
				|ru = 'Завершение сеансов не выполнено. Подробности см. в Журнале регистрации.';
				|en = 'Cannot close sessions. For more information, see the event log.'; fa = 'Cannot close sessions. For more information, see the event log.';
				|it = 'L''arresto delle sessioni non è stato completato. Per i dettagli vedere il registro di log.';
				|pl = 'Zakończenie sesji nie powiodło się. Szczegóły patrz Dzienniku rejestracji.';
				|tr = 'Oturumların sonlandırılması yapılmadı. Daha fazla bilgi için olay günlüğüne bakın.'"),
			PictureLib.DialogExclamation);	
		Return;
	EndTry;
	
	SetUserTerminationInProgressFlag(False);
	Notify("UsersSessions",
		New Structure("Status,SessionCount", "Done", SessionCount));
	TerminateThisSession();
	ShowUserNotification(NStr("vi = 'Kết thúc công việc của người sử dụng';
								|ru = 'Завершение работы пользователей';
								|en = 'Closing user sessions'; fa = 'Closing user sessions';
								|it = 'Arresto del lavoro degli utenti';
								|pl = 'Zakończenie pracy użytkowników';
								|tr = 'Kullanıcı oturumlarının tamamlanması'"),
		ClickNotification,
		NStr("vi = 'Đã kết thúc thành công phiên làm việc';
			|ru = 'Завершение сеансов выполнено успешно';
			|en = 'All user sessions are closed.'; fa = 'All user sessions are closed.';
			|it = 'Arresto delle sessioni completato con successo';
			|pl = 'Zakończenia sesji przebiegły pomyślnie';
			|tr = 'Oturumlar başarıyla kapatıldı'"),
		PictureLib.DialogInformation);
	
EndProcedure

// Terminates the last remaining session of the administrator who initiated user session termination.
//
Procedure TerminateThisSession(OutputQuestion1 = True)
	
	SetUserTerminationInProgressFlag(False);
	
	If TerminateAllSessionsExceptCurrent() Then
		Return;
	EndIf;
	
	If Not OutputQuestion1 Then 
		Exit(False);
		Return;
	EndIf;
	
	SetIsProcedureEndUserSessionsRunning(True);
	
	Notification = New CallbackDescription("TerminateThisSessionCompletion", ThisObject);
	MessageText = NStr("vi = 'Cấm người sử dụng làm việc với ứng dụng. Kết thúc phiên làm việc này?';
						|ru = 'Работа пользователей с приложением запрещена. Завершить работу этого сеанса?';
						|en = 'User access is restricted. Exit the app?'; fa = 'User access is restricted. Exit the app?';
						|it = 'Работа пользователей с приложением запрещена. Завершить работу этого сеанса?';
						|pl = 'User access is restricted. Exit the app?';
						|tr = 'Uygulamada kullanıcı işlemi yasaktır. Bu oturumu kapatmak istiyor musunuz?'");
	Title = NStr("vi = 'Kết thúc phiên làm việc hiện tại';
				|ru = 'Завершение работы текущего сеанса';
				|en = 'Close current session'; fa = 'Close current session';
				|it = 'Arresto del lavoro della sessione corrente';
				|pl = 'Zamknięcie bieżącej sesji';
				|tr = 'Mevcut oturumu sonlandır'");
	ShowQueryBox(Notification, MessageText, QuestionDialogMode.YesNo, 60, DialogReturnCode.Yes, Title, DialogReturnCode.Yes);
	
EndProcedure

Procedure OpeningHandlerOfAppWorkBlockForm(Context) Export
	
	FullFormName = "DataProcessor.ApplicationLock.Form.InfobaseConnectionsLock";
	
	Windows = GetWindows();
	For Each Window In Windows Do
		For Each Form In Window.Content Do
			If Form.FormName = FullFormName And Form.IsOpen() Then
				Form.Activate();
				Return;
			EndIf;
		EndDo;
	EndDo;
	
	OpenForm(FullFormName);
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////
// Core subsystem event handlers.

Function SessionTerminationInProgress() Export
	
	Return ClientParameters().SessionTerminationInProgress;
	
EndFunction

Function TerminateAllSessionsExceptCurrent()
	
	Return ClientParameters().TerminateAllSessionsExceptCurrent;
	
EndFunction

Function SavedAdministrationParameters()
	
	Return ClientParameters().AdministrationParameters;
	
EndFunction

Procedure SaveAdministrationParameters(Value) Export
	
	ClientParameters().AdministrationParameters = Value;
	
EndProcedure

Procedure FillInClusterAdministrationParameters(StartupParameters)
	
	AdministrationParameters = IBConnectionsServerCall.AdministrationParameters();
	ParametersCount = StartupParameters.Count();
	
	If ParametersCount > 1 Then
		AdministrationParameters.ClusterAdministratorName = StartupParameters[1];
	EndIf;
	
	If ParametersCount > 2 Then
		AdministrationParameters.ClusterAdministratorPassword = StartupParameters[2];
	EndIf;
	
	SaveAdministrationParameters(AdministrationParameters);
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////
// Notification handlers.

// Prompts users to unlock and log in, or close the application.
Procedure BeforeStartInteractiveHandler(Parameters, Context) Export
	
	ClientParameters = StandardSubsystemsClient.ClientParametersOnStart();
	
	QueryText   = ClientParameters.PromptToAuthorize;
	MessageText = ClientParameters.DataAreaSessionsLocked;
	
	If Not IsBlankString(QueryText) Then
		Buttons = New ValueList();
		Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Đăng nhập';
												|ru = 'Войти';
												|en = 'Sign in'; fa = 'Sign in';
												|it = 'Accedere';
												|pl = 'Sign in';
												|tr = 'Giriş'"));
		If ClientParameters.CanUnlock Then
			Buttons.Add(DialogReturnCode.No, NStr("vi = 'Bỏ chặn và đăng nhập';
													|ru = 'Снять блокировку и войти';
													|en = 'Remove lock and sign in'; fa = 'Remove lock and sign in';
													|it = 'Togliere il blocco e accedere';
													|pl = 'Zdjąć blokadę i zalogować się';
													|tr = 'Kilidini aç ve oturumu aç'"));
		EndIf;
		Buttons.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
													|ru = 'Отмена';
													|en = 'Cancel'; fa = 'انصراف';
													|it = 'Annulla';
													|pl = 'Cancel';
													|tr = 'İptal'"));
		
		ResponseHandler = New CallbackDescription(
			"AfterAnswerToPromptToAuthorizeOrUnlock", ThisObject, Parameters);
		
		ShowQueryBox(ResponseHandler, QueryText, Buttons, 15,
			DialogReturnCode.Cancel,, DialogReturnCode.Cancel);
		Return;
	Else
		Parameters.Cancel = True;
		ShowMessageBox(
			StandardSubsystemsClient.NotificationWithoutResult(Parameters.ContinuationHandler),
			MessageText, 15);
	EndIf;
	
EndProcedure

// Continues from the above procedure.
Procedure AfterAnswerToPromptToAuthorizeOrUnlock(Response, Parameters) Export
	
	If Response = DialogReturnCode.Yes Then // Logging on to the locked application.
		
	ElsIf Response = DialogReturnCode.No Then // Removing the application lock and logging on.
		IBConnectionsServerCall.SetDataAreaSessionLock(
			New Structure("Use", False));
	Else
		Parameters.Cancel = True;
	EndIf;
	
	RunCallback(Parameters.ContinuationHandler);
	
EndProcedure

Procedure ShowWarningOnExit(MessageText, LockBeginTime)
	
	InformParameters = InformParameters(LockBeginTime);
	If Not InformParameters.IsNotificationDisplayed Then
		ShowUserNotification(NStr("vi = 'Sẽ kết thúc công việc của ứng dụng';
									|ru = 'Работа приложения будет завершена';
									|en = 'App will be closed'; fa = 'App will be closed';
									|it = 'Работа приложения будет завершена';
									|pl = 'App will be closed';
									|tr = 'Uygulama sonlandırılacak'"),, MessageText,, 
			UserNotificationStatus.Important, "UserSessionsEndControl");
		InformParameters.IsNotificationDisplayed = True;
	EndIf;
	
	If InformParameters.IsWarningShown Then
		Return;
	EndIf;
	
	ShowMessageBox(, MessageText, 30);
	
	InformParameters.IsWarningShown = True;
	
EndProcedure

// Returns:
//  Structure:
//   * IsNotificationDisplayed - Boolean
//   * IsWarningShown - Boolean
//   * IsQuestionShown - Boolean
//
Function InformParameters(LockBeginTime)
	
	ParameterName = "StandardSubsystems.WarningShownBeforeExit";
	Properties = ApplicationParameters[ParameterName];
	If Properties = Undefined Or Properties.LockBeginTime <> LockBeginTime Then
		Properties = New Structure;
		Properties.Insert("IsNotificationDisplayed", False);
		Properties.Insert("IsWarningShown", False);
		Properties.Insert("IsQuestionShown", False);
		Properties.Insert("LockBeginTime", LockBeginTime);
		ApplicationParameters.Insert(ParameterName, Properties);
	EndIf;
	
	Return Properties;
	
EndFunction

Procedure ClearUserNotifications()
	
	ParameterName = "StandardSubsystems.WarningShownBeforeExit";
	InformParameters = ApplicationParameters[ParameterName];
	If InformParameters = Undefined
	 Or Not InformParameters.IsNotificationDisplayed Then
		Return;
	EndIf;
	InformParameters.IsNotificationDisplayed = False;
	
	ShowUserNotification(NStr("vi = 'Đã hủy kết thúc công việc';
								|ru = 'Завершение работы отменено';
								|en = 'Closing the application is canceled'; fa = 'Closing the application is canceled';
								|it = 'Завершение работы отменено';
								|pl = 'Closing the application is canceled';
								|tr = 'İşin tamamlanması iptal edildi'"),, ,,
		UserNotificationStatus.Important, "UserSessionsEndControl");
	
EndProcedure

Procedure AskOnTermination(MessageText, LockBeginTime)
	
	InformParameters = InformParameters(LockBeginTime);
	If Not InformParameters.IsNotificationDisplayed Then
		ShowUserNotification(NStr("vi = 'Sẽ kết thúc công việc của ứng dụng';
									|ru = 'Работа приложения будет завершена';
									|en = 'App will be closed'; fa = 'App will be closed';
									|it = 'Работа приложения будет завершена';
									|pl = 'App will be closed';
									|tr = 'Uygulama sonlandırılacak'"),, MessageText,,
			UserNotificationStatus.Important, "UserSessionsEndControl");
		InformParameters.IsNotificationDisplayed = True;
	EndIf;
	
	If InformParameters.IsQuestionShown Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = '%1
		|Kết thúc công việc?';
		|ru = '%1
		|Завершить работу?';
		|en = '%1
		|Do you want to exit?'; fa = '%1
		|Do you want to exit?';
		|it = '%1
		|Terminare il lavoro?';
		|pl = '%1
		|Zakończyć pracę?';
		|tr = '%1
		|Uygulama kapatılsın mı?'");
	QueryText = StringFunctionsClientServer.SubstituteParametersToString(QueryText, MessageText);
	CallbackDescription = New CallbackDescription("AskOnTerminationCompletion", ThisObject);
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo, 30, DialogReturnCode.Yes);
	
	InformParameters.IsQuestionShown = True;
	
EndProcedure

Procedure AskOnTerminationCompletion(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.Yes Then
		StandardSubsystemsClient.SkipExitConfirmation();
		Exit(True, False);
	EndIf;
	
EndProcedure

Procedure TerminateThisSessionCompletion(Response, Parameters) Export
	
	If Response <> DialogReturnCode.No Then
		StandardSubsystemsClient.SkipExitConfirmation();
		Exit(False);
	EndIf;
	
	SetIsProcedureEndUserSessionsRunning(False);
	
EndProcedure	

// Processes start parameters related to allowing or terminating infobase connections.
//
// Parameters:
//  LaunchParameterValue - String - main launch parameter.
//  StartupParameters          - Array of String - Semicolon-delimited additional startup parameters.
//
// Returns:
//   Boolean   - True if system start must be canceled.
//
Function ProcessStartParameters(Val StartupParameters)

	// Process startup parameters for DisableUserAuthorisation and AllowUserAuthorization.
	ParameterNameAllowUsers = "AllowUserAuthorization";
	ParameterNameShutdownUsers = "EndUserSessions";
	If TheKeyIsContainedInTheStartupParameters(StartupParameters, ParameterNameAllowUsers) Then
		
		If Not CommonClient.SeparatedDataUsageAvailable() Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chưa xử lý tham số khởi động %1. Chưa thực hiện đăng nhập vào vùng dữ liệu.';
					|ru = 'Параметр запуска %1 не отработан. Не выполнен вход в область данных.';
					|en = 'The %1 parameter ignored because you did not enter the data area.'; fa = 'The %1 parameter ignored because you did not enter the data area.';
					|it = 'The %1 parameter ignored because you did not enter the data area.';
					|pl = 'The %1 parameter ignored because you did not enter the data area.';
					|tr = '%1 başlatma parametresi işlenemedi. Veri alanına girilmedi.'"),
				ParameterNameAllowUsers);
			EventLogClient.AddMessageForEventLog(EventLogEvent(),
				"Warning", MessageText,, True);
			Return True;
		EndIf;
		
		If Not IBConnectionsServerCall.AllowUserAuthorization() Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chưa xử lý tham số khởi động %1. Không đủ quyền quản trị cơ sở thông tin.';
					|ru = 'Параметр запуска %1 не отработан. Нет прав на администрирование информационной базы.';
					|en = 'The %1 parameter is ignored because you do not have administrative rights.'; fa = 'The %1 parameter is ignored because you do not have administrative rights.';
					|it = 'Il parametro di avvio %1 non è perfezionato. Non ci sono permessi per amministrare il database.';
					|pl = 'Opcja uruchamiania %1 nie został opracowany. Brak praw, na zarządzanie bazą informacyjną.';
					|tr = '%1Başlatma parametresi işlenmedi. Infobase''in yönetimi için yetki yok.'"),
				ParameterNameAllowUsers);
			EventLogClient.AddMessageForEventLog(EventLogEvent(),
				"Warning", MessageText,, True);
			Return True;
		EndIf;
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã khởi động với tham số %1. Ứng dụng sẽ kết thúc công việc.';
				|ru = 'Выполнен запуск с параметром %1. Работа приложения будет завершена.';
				|en = 'The application is started with parameter %1. The application will be closed.'; fa = 'The application is started with parameter %1. The application will be closed.';
				|it = 'Выполнен запуск с параметром %1. Работа приложения будет завершена.';
				|pl = 'The application is started with parameter %1. The application will be closed.';
				|tr = '%1 parametre ile başlatıldı. Programın çalışması sonlandırılacaktır.'"),
				ParameterNameAllowUsers);
		EventLogClient.AddMessageForEventLog(EventLogEvent(),,
			MessageText,, True);
		Exit(False);
		Return True;
		
	// The parameter can contain two additional semicolon-delimited ( ; ) parts: 
	// The credentials of the admin on whose behalf the cluster is connected in the client/server mode.
	// See the comments to the "EndUserSessions" procedure.
	ElsIf TheKeyIsContainedInTheStartupParameters(StartupParameters, ParameterNameShutdownUsers) Then
		
		If Not CommonClient.SeparatedDataUsageAvailable() Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chưa xử lý tham số khởi động %1. Chưa thực hiện đăng nhập vào vùng dữ liệu.';
					|ru = 'Параметр запуска %1 не отработан. Не выполнен вход в область данных.';
					|en = 'The %1 parameter ignored because you did not enter the data area.'; fa = 'The %1 parameter ignored because you did not enter the data area.';
					|it = 'The %1 parameter ignored because you did not enter the data area.';
					|pl = 'The %1 parameter ignored because you did not enter the data area.';
					|tr = '%1 başlatma parametresi işlenemedi. Veri alanına girilmedi.'"),
				ParameterNameShutdownUsers);
			EventLogClient.AddMessageForEventLog(EventLogEvent(),
				"Warning", MessageText,, True);
			Return True;
		EndIf;

		AdditionalParameters = AdditionalParametersForUserShutdown();
		LockSet = IBConnectionsServerCall.SetConnectionLock(
			AdditionalParameters.MessageText,
			AdditionalParameters.KeyCode,
			AdditionalParameters.WaitingForTheStartOfBlockingMin,
			AdditionalParameters.BlockingDurationMin);
		
		If Not LockSet Then 
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chưa xử lý tham số khởi động %1. Không đủ quyền quản trị cơ sở thông tin.';
					|ru = 'Параметр запуска %1 не отработан. Нет прав на администрирование информационной базы.';
					|en = 'The %1 parameter is ignored because you do not have administrative rights.'; fa = 'The %1 parameter is ignored because you do not have administrative rights.';
					|it = 'Il parametro di avvio %1 non è perfezionato. Non ci sono permessi per amministrare il database.';
					|pl = 'Opcja uruchamiania %1 nie został opracowany. Brak praw, na zarządzanie bazą informacyjną.';
					|tr = '%1Başlatma parametresi işlenmedi. Infobase''in yönetimi için yetki yok.'"),
				ParameterNameShutdownUsers);
			EventLogClient.AddMessageForEventLog(EventLogEvent(),
				"Warning", MessageText,, True);
			Return True;
		EndIf;
		
		LaunchParametersRefined = LaunchParametersRefined(StartupParameters, AdditionalParameters);
		FillInClusterAdministrationParameters(LaunchParametersRefined);
		
		SetUserTerminationInProgressFlag(True);
		CurrentMode = IBConnectionsServerCall.SessionLockParameters(True);
		EndUserSessions(CurrentMode);
		Return False; 
		
	EndIf;
	Return False;
	
EndFunction

// Returns a string constant for generating event log messages.
//
// Returns:
//   String
//
Function EventLogEvent() Export
	
	Return NStr("vi = 'Kết thúc công việc người sử dụng';
				|ru = 'Завершение работы пользователей';
				|en = 'User sessions'; fa = 'جلسات کاربر';
				|it = 'Arresto del lavoro degli utenti';
				|pl = 'Zakończenie pracy użytkowników';
				|tr = 'Kullanıcı oturumlarının tamamlanması'", CommonClient.DefaultLanguageCode());
	
EndFunction

#Region AdditionalParametersForUserShutdown

// Extracts the session lock parameters from the startup parameter.
//
// Returns:
//   Structure:
//     * ClusterAdministratorName    - String - a name of 1C server cluster administrator.
//     * ClusterAdministratorPassword - String - a password of 1C server cluster administrator.
//     * MessageText               - String - text to be used in the error message
//                                               displayed when someone attempts to connect
//                                               to a locked infobase.
//     * KeyCode                - String - string to be added to "/uc" command line parameter
//                                                or to "uc" connection string parameter
//                                               in order to establish connection to the infobase
//                                               regardless of the lock.
//                                               Cannot be used for data area session locks.
//     * WaitingForTheStartOfBlockingMin  - Number -  delay time of the lock start in minutes.
//     * BlockingDurationMin    - Number -  lock duration in minutes.
//
Function AdditionalParametersForUserShutdown() 
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ClusterAdministratorName", "");
	AdditionalParameters.Insert("ClusterAdministratorPassword", "");
	AdditionalParameters.Insert("MessageText", "");
	AdditionalParameters.Insert("KeyCode", "KeyCode");
	AdditionalParameters.Insert("WaitingForTheStartOfBlockingMin", 0);
	AdditionalParameters.Insert("BlockingDurationMin", 0);
	
	AdditionalParametersExtracted = AdditionalUserShutdownParametersExtracted();
	
	For Each Parameter In AdditionalParameters Do 
		
		ParameterValue = Undefined;
		
		If AdditionalParametersExtracted.Property(Parameter.Key, ParameterValue)
			And ValueIsFilled(ParameterValue) Then 
			
			AdditionalParameters[Parameter.Key] = ParameterValue;
		EndIf;
		
	EndDo;
	
	Return AdditionalParameters;
	
EndFunction

Function AdditionalUserShutdownParametersExtracted()
	
	AdditionalParameters = New Structure;
	
	UserShutdownParameter = UserShutdownParameter();
	
	If Not ValueIsFilled(UserShutdownParameter) Then 
		Return AdditionalParameters;
	EndIf;
	
	InitialNumber = StrFind(UserShutdownParameter, "EndUserSessions")
		+ StrLen("EndUserSessions");
	
	AdditionalParametersByTheString = TrimAll(Mid(UserShutdownParameter, InitialNumber));
	CompositionOfAdditionalParameters = StrSplit(AdditionalParametersByTheString, ",");
	PreviousParameter = Undefined;
	
	For Each Parameter In CompositionOfAdditionalParameters Do 
		
		ParameterDetails = StrSplit(Parameter, "=");
		
		If ParameterDetails.Count() <> 2 Then 
			
			If PreviousParameter <> Undefined
				And ValueIsFilled(ParameterDetails[0]) Then 
				
				ParameterValue = AdditionalParameters[PreviousParameter] + "," + ParameterDetails[0];
				AdditionalParameters.Insert(PreviousParameter, ParameterValue);
				
			EndIf;
			
			Continue;
			
		EndIf;
		
		AdditionalParameters.Insert(TrimAll(ParameterDetails[0]), TrimAll(ParameterDetails[1]));
		PreviousParameter = TrimAll(ParameterDetails[0]);
		
	EndDo;
	
	Return AdditionalUserShutdownParametersNormalized(AdditionalParameters);
	
EndFunction

Function UserShutdownParameter()
	
	CompositionOfLaunchParameters = StrSplit(LaunchParameter, ";", False);
	
	For Each Parameter In CompositionOfLaunchParameters Do 
		
		If StrStartsWith(TrimAll(Parameter), "EndUserSessions") Then 
			Return Parameter;
		EndIf;
		
	EndDo;
	
	Return "";
	
EndFunction

Function AdditionalUserShutdownParametersNormalized(AdditionalParameters)
	
	AdditionalParametersAreNormalized = New Structure;
	
	AdditionalParameterKeys = KeysForAdditionalUserShutdownParameters();
	
	For Each AdditionalParameter In AdditionalParameters Do 
		
		For Each AdditionalParameterKey In AdditionalParameterKeys Do 
			
			If StrStartsWith(AdditionalParameter.Key, AdditionalParameterKey.Key) Then 
				
				AdditionalParametersAreNormalized.Insert(
					AdditionalParameterKey.Value, AdditionalParameter.Value);
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	FormatAdditionalUserShutdownParameters(AdditionalParametersAreNormalized);
	
	Return AdditionalParametersAreNormalized;
	
EndFunction

Function KeysForAdditionalUserShutdownParameters()
	
	AdditionalParameterKeys = New Map;
	AdditionalParameterKeys.Insert("Name", "ClusterAdministratorName");
	AdditionalParameterKeys.Insert("Password", "ClusterAdministratorPassword");
	AdditionalParameterKeys.Insert("Message", "MessageText");
	AdditionalParameterKeys.Insert("Code", "KeyCode");
	AdditionalParameterKeys.Insert("Waiting", "WaitingForTheStartOfBlockingMin");
	AdditionalParameterKeys.Insert("Duration", "BlockingDurationMin");
	
	Return AdditionalParameterKeys;
	
EndFunction

Procedure FormatAdditionalUserShutdownParameters(AdditionalParameters)
	
	ParametersToBeFormatted = New Array;
	ParametersToBeFormatted.Add("WaitingForTheStartOfBlockingMin");
	ParametersToBeFormatted.Add("BlockingDurationMin");
	
	NumberDetails = New TypeDescription("Number");
	
	For Each Parameter In ParametersToBeFormatted Do 
		
		ParameterValue = Undefined;
		
		If Not AdditionalParameters.Property(Parameter, ParameterValue) Then 
			Continue;
		EndIf;
		
		AvailableCharacters = New Array;
		
		CharsCount = StrLen(ParameterValue);
		
		For CharacterNumber = 1 To CharsCount Do 
			
			Char = Mid(ParameterValue, CharacterNumber, 1);
			
			If StrFind("0123456789", Char) > 0 Then 
				AvailableCharacters.Add(Char);
			EndIf;
			
		EndDo;
		
		TheValueOfTheParameterIsNormalized = StrConcat(AvailableCharacters);
		
		If ValueIsFilled(TheValueOfTheParameterIsNormalized) Then 
			AdditionalParameters[Parameter] = NumberDetails.AdjustValue(TheValueOfTheParameterIsNormalized);
		Else
			AdditionalParameters[Parameter] = 0;
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

Function TheKeyIsContainedInTheStartupParameters(StartupParameters, Var_Key)
	
	For Each Parameter In StartupParameters Do 
		
		If StrStartsWith(TrimAll(Parameter), Var_Key) Then 
			Return True;
		EndIf;
		
	EndDo;
	
	Return False;
	
EndFunction

Function LaunchParametersRefined(StartupParameters, AdditionalParameters)
	
	ClusterAdministratorName = CommonClientServer.StructureProperty(
		AdditionalParameters, "ClusterAdministratorName");
	
	If Not ValueIsFilled(ClusterAdministratorName) Then 
		Return StartupParameters;
	EndIf;
	
	LaunchParametersRefined = New Array;
	LaunchParametersRefined.Add(StartupParameters[0]);
	LaunchParametersRefined.Add(ClusterAdministratorName);
	
	ClusterAdministratorPassword = CommonClientServer.StructureProperty(
		AdditionalParameters, "ClusterAdministratorPassword");
	
	If ValueIsFilled(ClusterAdministratorPassword) Then 
		LaunchParametersRefined.Add(ClusterAdministratorPassword);
	EndIf;
	
	Return LaunchParametersRefined;
	
EndFunction

#EndRegion