///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All rights reserved. This program and accompanying materials are provided 
// in accordance with the terms of the Attribution 4.0 International (CC BY 4.0) license
// The license text is available at the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
			
	If Not Users.IsFullUser() Then
		ErrorText =  NStr("vi = 'Không đủ quyền để kết thúc phiên làm việc';
							|ru = 'Недостаточно прав для завершения сеанса';
							|en = 'Insufficient rights to end the session'; fa = 'Insufficient rights to end the session';
							|it = 'Diritti insufficiente per terminare la sessione';
							|pl = 'Niewystarczające uprawnienia do zakończenia sesji';
							|tr = 'Oturumu kapatmak için yetkiler yetersiz'");
		GoToWizardStep(5);
		Return;
	EndIf;
				
	TerminateWithoutWarning = Constants.CloseSessionsWithoutWarningByDefaultSaaS.Get();
		
	GoToWizardStep(1);
		
EndProcedure

#EndRegion

#Region Private

//@skip-warning - Unused method is a feature of the implementation.
&AtClient
Function CheckPasswordEntry()
	
	If IsBlankString(Password) Then	
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa chỉ ra mật khẩu để truy cập đến dịch vụ';
				|ru = 'Не указан пароль для доступа к сервису';
				|en = 'Password to access the service is not specified'; fa = 'Password to access the service is not specified';
				|it = 'La password di accesso al servizio non è indicata';
				|pl = 'Nie wskazano hasła dostępu do serwisu';
				|tr = 'Servise erişim parolası belirtilmedi'"), ,
			"Password");	
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

//@skip-warning - Unused method is a feature of the implementation.
&AtClient
Function StartSendingAlerts()
			
	If TerminateWithoutWarning 
		Or Not SendAlertsToServer(Parameters.SessionsNumbers, MessageToUsers) Then
		GoToWizardStep(3);
		GoToNextStep();
		Return False;	
	EndIf;

	AttachIdleHandler("AfterPerformingSendingAlertsToUsers", 60, True);

	Return True;
				
EndFunction

&AtClient
Procedure AfterPerformingSendingAlertsToUsers() Export
	GoToNextStep();
EndProcedure

&AtServerNoContext
Function SendAlertsToServer(Val SessionsNumbers, Val MessageToUsers)
	
	SetPrivilegedMode(True);
	
	NotificationToTheUser = New Structure();
	NotificationToTheUser.Insert(
		"NotificationKind",
		"SessionTerminationWarning");
	
	UserDescription = Common.ObjectAttributeValue(
		Users.CurrentUser(),
		"Description");
	NotificationToTheUser.Insert("UserDescription", UserDescription);	 
	
	If ValueIsFilled(MessageToUsers) Then
		NotificationToTheUser.Insert("Message", MessageToUsers);	 
	EndIf;
	
	InteractiveApplicationNames = CommonCTL.InteractiveApplicationNames();
		
	SessionNumbersUserNames = New Map();
	For Each Session In GetInfoBaseSessions() Do
		
		If InteractiveApplicationNames.Find(Session.ApplicationName) = Undefined Then
			Continue;
		EndIf;
				
		SessionUser = Session.User;
		If SessionUser = Undefined Then
			Continue;	
		EndIf;
		
		UserName = SessionUser.Name;
		If Not ValueIsFilled(UserName) Then
			Continue;
		EndIf;
		
		SessionNumbersUserNames.Insert(Session.SessionNumber, UserName);
	
	EndDo;
	
	DataArea = SaaSOperations.SessionSeparatorValue();	
	DeliveredAlerts = New Array;	
		
	For Each SessionNumber In SessionsNumbers Do
		
		UserName = SessionNumbersUserNames.Get(SessionNumber);
		If Not ValueIsFilled(UserName) Then
			Continue
		EndIf;
		
		DeliveredNotification = New Structure();
		DeliveredNotification.Insert("DataArea", DataArea);
		DeliveredNotification.Insert("UserName", UserName);	
		DeliveredNotification.Insert("SessionNumber", SessionNumber);	
		DeliveredNotification.Insert("UserNotification", NotificationToTheUser);
		
		DeliveredAlerts.Add(DeliveredNotification);
				
	EndDo;
	
	If Not ValueIsFilled(DeliveredAlerts) Then
		Return False;
	EndIf;
		
	UsersNotificationCTL.DeliverAlerts(DeliveredAlerts);
	
	Return True;
	
EndFunction

//@skip-warning - Unused method is a feature of the implementation.
&AtClient
Function StartTerminatingSessions()
							
	TimeConsumingOperation = RunSessionTerminationOnServer(
		Parameters.SessionsNumbers,
		Password,
		MessageToUsers);
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	
	NotificationOnCompletion = New CallbackDescription("AfterCompletingSessions", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, NotificationOnCompletion, IdleParameters);

	Return True;
	
EndFunction

&AtServerNoContext
Function RunSessionTerminationOnServer(Val SessionsNumbers, Val Password, Val MessageFromUser)
	
	PartsOfMessageTextToUsers = New Array();
	
	UserDescription = Common.ObjectAttributeValue(
		Users.CurrentUser(),
		"Description");
	PartsOfMessageTextToUsers.Add(StrTemplate(NStr("vi = 'Đã kết thúc phiên làm việc
		|Người sử dụng đã kết thúc phiên làm việc: %1';
		|ru = 'Сеанс завершен
		|Пользователь завершивший сеанс: %1';
		|en = 'Session is closed
		|User that closed the session: %1'; fa = 'Session is closed
		|User that closed the session: %1';
		|it = 'Sessione conclusa
		|Utente che ha terminato la sessione: %1';
		|pl = 'Sesja została zakończona
		|Użytkownik, który zakończył sesję: %1';
		|tr = 'Oturum kapatıldı
		|Oturumu kapatan kullanıcı: %1'"),
		UserDescription));
		 
	If ValueIsFilled(MessageFromUser) Then
		PartsOfMessageTextToUsers.Add(StrTemplate(NStr("vi = 'Thông báo từ người sử dụng: %1';
														|ru = 'Сообщение от пользователя: %1';
														|en = 'Message from a user: %1'; fa = 'Message from a user: %1';
														|it = 'Messaggio dall''utente: %1';
														|pl = 'Wiadomość od użytkownika: %1';
														|tr = 'Kullanıcı mesajı: %1'"), MessageFromUser));
	EndIf;	
	MessageToUsers = StrConcat(PartsOfMessageTextToUsers, Chars.LF); 
		
	ExecutionParameters = TimeConsumingOperations.ProcedureExecutionParameters();
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Kết thúc phiên làm việc';
														|ru = 'Завершение сеансов';
														|en = 'Close sessions'; fa = 'Close sessions';
														|it = 'Chiudere le sessioni';
														|pl = 'Zakończenie sesji';
														|tr = 'Oturumları kapat'");

	Return TimeConsumingOperations.ExecuteProcedure(
		ExecutionParameters,
		"RemoteAdministrationCTLInternal.EndDataAreaSessions",
		SessionsNumbers,
		Password,
		MessageToUsers);
		
EndFunction

&AtClient
Procedure AfterCompletingSessions(Result, AdditionalParameters) Export
		
	If Result <> Undefined And Result.Status = "Completed2" Then
		
		Close(DialogReturnCode.OK);
	
	Else
		
		If Result = Undefined Then
			ErrorPresentation = NStr("vi = 'Nhiệm vụ đã bị hủy';
									|ru = 'Задание отменено';
									|en = 'Job is canceled'; fa = 'Job is canceled';
									|it = 'Task annullato';
									|pl = 'Zadanie anulowano';
									|tr = 'Görev iptal edildi'");
		Else
			ErrorPresentation = Result.DetailErrorDescription;
		EndIf;
		
		WriteError(
			NStr("vi = 'Lỗi kết thúc phiên làm việc';
				|ru = 'Ошибка завершения сеанса';
				|en = 'An error occurred when closing the session'; fa = 'An error occurred when closing the session';
				|it = 'Errore di chiusura della sessione';
				|pl = 'Błąd zakończenia sesji';
				|tr = 'Oturumu kapatma hatası'", CommonClient.DefaultLanguageCode()),
			ErrorPresentation);
		
		ErrorText = NStr("vi = 'Khi thử kết thúc phiên làm việc, đã xảy ra lỗi.
		|Hãy kiểm tra tính chính xác khi nhập mật khẩu để truy cập đến dịch vụ, hãy thử lại sau hoặc liên hệ với bộ phận hỗ trợ dịch vụ';
		|ru = 'При попытке завершить сеансы произошла ошибка.
		|Проверьте правильность ввода пароля для доступа к сервису, попробуйте позже или обратитесь в службу поддержки сервиса';
		|en = 'An error occurred when closing the sessions.
		|Check whether the password to access the service is correct, try again later, or contact the technical support of the service'; fa = 'An error occurred when closing the sessions.
		|Check whether the password to access the service is correct, try again later, or contact the technical support of the service';
		|it = 'Al tentativo di terminare la sessione si è verificato un errore.
		|Verificare la correttezza della password inserita per l''accesso al servizio, riprovare più tardi o rivolgersi al servizio di supporto';
		|pl = 'Podczas próby zakończenia sesji wystąpił błąd.
		|Sprawdź poprawność wprowadzenia hasła dla dostępu do usługi, spróbuj później lub zwróć się do pomocy technicznej usługi';
		|tr = 'Oturumları kapatmaya çalışırken bir hata oluştu.
		|Servise erişim parolanızın doğru olduğundan emin olun, daha sonra tekrar deneyin veya müşteri hizmetleriyle iletişime geçin'");
		
		GoToWizardStep(5);
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure WriteError(EventName, ErrorText)
	// @skip-check module-nstr-camelcase - verification error
	FullNameOfEvent = NStr("vi = 'ЗавершениеСеансовВМоделиСервиса';
							|ru = 'ЗавершениеСеансовВМоделиСервиса';
							|en = 'SessionsTerminationSaaS'; fa = 'SessionsTerminationSaaS';
							|it = 'ЗавершениеСеансовВМоделиСервиса';
							|pl = 'ЗавершениеСеансовВМоделиСервиса';
							|tr = 'ЗавершениеСеансовВМоделиСервиса'", Common.DefaultLanguageCode()) + "." + EventName;
	WriteLogEvent(FullNameOfEvent, EventLogLevel.Error,,, ErrorText);
EndProcedure

&AtClient
Procedure Next(Command)
	
	GoToNextStep();
	
EndProcedure

&AtClient
Function ExecuteTransitionHandlerBetweenSteps()
	
	Result = True;
	
	If ValueIsFilled(TransitionFromCurrentStepHandler) Then
		
		Result = Eval(TransitionFromCurrentStepHandler + "()");
				
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Procedure GoToWizardStep(Val Step)
	
	Scenario = WizardScript();
	
	StepDescription = Scenario.Find(Step, "StepNumber");
	Items.GroupPages.CurrentPage = Items[StepDescription.Page];
	Items.CommandsPagesGroup.CurrentPage = Items[StepDescription.CommandsPage];
	
	TransitionFromCurrentStepHandler = StepDescription.Handler;
	CurrentStep = Step;
	
EndProcedure

&AtServer
Function WizardScript()
	
	Result = New ValueTable();
	
	Result.Columns.Add("StepNumber", New TypeDescription("Number"));
	Result.Columns.Add("Page", New TypeDescription("String"));
	Result.Columns.Add("CommandsPage", New TypeDescription("String"));
	Result.Columns.Add("Handler", New TypeDescription("String"));
	
	// Entering a password
	NewRow = Result.Add();
	NewRow.StepNumber = 1;
	NewRow.Page = Items.PasswordInputPage.Name;
	NewRow.CommandsPage = Items.DataEntryCommandPage.Name;
	NewRow.Handler = "CheckPasswordEntry";
		
	// User alerts
	NewRow = Result.Add();
	NewRow.StepNumber = 2;
	NewRow.Page = Items.UserAlertsPage.Name;
	NewRow.CommandsPage = Items.DataEntryCommandPage.Name;
	NewRow.Handler = "StartSendingAlerts";
	
	// Waiting for user notification
	NewRow = Result.Add();
	NewRow.StepNumber = 3;
	NewRow.Page = Items.WaitingForUserNotificationsPage.Name;
	NewRow.CommandsPage = Items.WaitCommandPage.Name;
	NewRow.Handler = "StartTerminatingSessions";
		
	// Waiting for completion
	NewRow = Result.Add();
	NewRow.StepNumber = 4;
	NewRow.Page = Items.WaitingForSessionsToEndPage.Name;
	NewRow.CommandsPage = Items.WaitCommandPage.Name;
	
	// Viewing an error
	NewRow = Result.Add();
	NewRow.StepNumber = 5;
	NewRow.Page = Items.ErrorPage.Name;
	NewRow.CommandsPage = Items.ErrorCommandPage.Name;
	
	Return Result;
	
EndFunction

&AtClient
Procedure GoToNextStep()
	
	CurStepBeforeHandlerExecution = CurrentStep;
	
	If Not ExecuteTransitionHandlerBetweenSteps() Then
		Return;
	EndIf;
	
	If CurrentStep <> CurStepBeforeHandlerExecution Then
		Return;
	EndIf;
	
	GoToWizardStep(CurrentStep + 1);

EndProcedure

#EndRegion


