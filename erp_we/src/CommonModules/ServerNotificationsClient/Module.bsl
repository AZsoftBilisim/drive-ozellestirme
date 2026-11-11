///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Completion check of the intermittent wait for the handlers of
// the BeforeRecurringClientDataSendToServer event.
//
// Parameters:
//  CounterName   - String - For example, "StandardSubsystems.MonitoringCenter".
//  Timeout - Number - Timeout before the counter triggers (in seconds).
//  FirstTime     - Boolean - If set to True, returns True after initialization.
//  SessionDate    - Date - The return value (in cases when a custom counter is required).
//
// Returns:
//  Boolean - True if the last count ended, and a new one started.
//
// Example:
//	CounterName = "StandardSubsystems.MonitoringCenter";
//	If Not ServerNotificationsClient.TimeoutExpired(CounterName) Then
//		Return;
//	EndIf;
//
Function TimeoutExpired(CounterName, Timeout = 1200, FirstTime = False, SessionDate = '00010101') Export
	
	DataReceiptStatus = DataReceiptStatus();
	SessionDate = DataReceiptStatus.CurrentSessionDateToCheckWaitingCounter;
	If Not ValueIsFilled(CounterName) Then
		Return False;
	EndIf;
	WaitCounters = DataReceiptStatus.WaitCounters;
	
	LastDate = WaitCounters.Get(CounterName);
	If LastDate = Undefined Then
		WaitCounters.Insert(CounterName, SessionDate);
		Return FirstTime;
	EndIf;
	
	If LastDate + Timeout > SessionDate Then
		Return False;
	EndIf;
	
	WaitCounters.Insert(CounterName, SessionDate);
	Return True;
	
EndFunction

// Logs an error caught in the handlers of the events
// BeforeRecurringClientDataSendToServer and
// AfterRecurringReceiptOfClientDataOnServer.
//
// Parameters:
//  ErrorInfo - ErrorInfo
//
// Example:
//	StartMoment = CurrentUniversalDateInMilliseconds();
//	Try
//		If CommonClient.SubsystemExists("StandardSubsystems.MonitoringCenter") Then
//			ModuleMonitoringCenterClientInternal = CommonClient.CommonModule("MonitoringCenterClientInternal");
//			ModuleMonitoringCenterClientInternal.BeforeRecurringClientDataSendToServer(Parameters);
//		EndIf;
//	Except
//		ServerNotificationsClient.HandleError(ErrorInfo());
//	EndTry;
//	ServerNotificationsClient.AddIndicator(StartMoment,
//		"MonitoringCenterClientInternal.BeforeRecurringClientDataSendToServer");
//
Procedure HandleError(ErrorInfo) Export
	
	EventLogClient.AddMessageForEventLog(
		NStr("vi = 'Thông báo từ máy chủ.Lỗi nhận hoặc xử lý thông báo';
			|ru = 'Серверные оповещения.Ошибка получения или обработки оповещений';
			|en = 'Server notifications.Error getting or processing notifications'; fa = 'Server notifications.Error getting or processing notifications';
			|it = 'Серверные оповещения.Ошибка получения или обработки оповещений';
			|pl = 'Server notifications.Error getting or processing notifications';
			|tr = 'Sunucu uyarısı.Alma işleminde veya uyarının işlenmesinde hata.'",
			CommonClient.DefaultLanguageCode()),
		"Error",
		ErrorProcessing.DetailErrorDescription(ErrorInfo));
	
EndProcedure

// Adds a performance indicator to the handlers of the event
// BeforeRecurringClientDataSendToServer and
// AfterRecurringReceiptOfClientDataOnServer.
//
// Parameters:
//  StartMoment - Number - CurrentUniversalDateInMilliseconds before the procedure will be called.
//  ProcedureName - String - Full name of the called procedure
//
// Example:
//	StartMoment = CurrentUniversalDateInMilliseconds();
//	Try
//		If CommonClient.SubsystemExists("StandardSubsystems.MonitoringCenter") Then
//			ModuleMonitoringCenterClientInternal = CommonClient.CommonModule("MonitoringCenterClientInternal");
//			ModuleMonitoringCenterClientInternal.BeforeRecurringClientDataSendToServer(Parameters);
//		EndIf;
//	Except
//		ServerNotificationsClient.HandleError(ErrorInfo());
//	EndTry;
//	ServerNotificationsClient.AddIndicator(StartMoment,
//		"MonitoringCenterClientInternal.BeforeRecurringClientDataSendToServer");
//
Procedure AddIndicator(StartMoment, ProcedureName) Export
	
	Indicators = ApplicationParameters.Get(NestedIndicatorsParameterName());
	AddMainIndicator(Indicators, StartMoment, ProcedureName, , True);
	
EndProcedure

#Region InterfaceImplementation

// Returns the session's UUID obtained from
// the session properties SessionStart and SessionNumber.
//
// Returns:
//   See ServerNotifications.SessionKey
//
Function SessionKey() Export
	
	Return DataReceiptStatus().SessionKey;
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

// Parameters:
//  Interval - Number
//  ShouldReceiveImmediately - Boolean - If set to "True", the next check will make a server call
//                     that returns the notification stack.
//
Procedure AttachServerNotificationReceiptCheckHandler(Interval = 1, ShouldReceiveImmediately = False) Export
	
	If Interval < 1 Then
		Interval = 1;
	ElsIf Interval > 60 Then
		Interval = 60;
	EndIf;
	
	If ShouldReceiveImmediately Then
		DataReceiptStatus().ShouldReceiveImmediately = True;
	EndIf;
	
	AttachIdleHandler("ServerNotificationsReceiptCheckHandler", Interval);
	
EndProcedure

#Region ConfigurationSubsystemsEventHandlers

// See CommonClientOverridable.BeforeStart.
Procedure BeforeStart(Parameters) Export
	
	ClientParameters = StandardSubsystemsClient.ClientParametersOnStart();
	
	If Not ClientParameters.Property("ServerNotifications") Then
		Return;
	EndIf;
	
	ServerNotificationsParameters = ClientParameters.ServerNotifications; // See ServerNotifications.ServerNotificationsParametersThisSession
	DataReceiptStatus = DataReceiptStatus();
	FillPropertyValues(DataReceiptStatus, ServerNotificationsParameters);
	Parameters.RetrievedClientParameters.Insert("ServerNotifications");
	Parameters.CountOfReceivedClientParameters = Parameters.CountOfReceivedClientParameters + 1;
	
	SessionDate = CommonClient.SessionDate();
	DataReceiptStatus.StatusUpdateDate = SessionDate;
	DataReceiptStatus.LastReceivedMessageDate = SessionDate;
	DataReceiptStatus.DateOfLastServerCall = SessionDate;
	DataReceiptStatus.WaitingCountersDateAlignmentSecondsNumber = Second(SessionDate);
	DataReceiptStatus.CurrentSessionDateToCheckWaitingCounter = SessionDate;
	
	DataReceiptStatus.IsCheckAllowed = True;
	AttachServerNotificationReceiptCheckHandler();
	AttachNewMessageHandler(DataReceiptStatus());
	
EndProcedure

// See CommonClientOverridable.AfterStart.
Procedure AfterStart() Export
	
	DataReceiptStatus = DataReceiptStatus();
	DataReceiptStatus.IsRecurringDataSendEnabled = True;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Procedure CheckAndReceiveServerNotifications() Export
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	DataReceiptStatus = DataReceiptStatus();
	Indicators = ?(DataReceiptStatus.ShouldRegisterIndicators, New Array, Undefined);
	If Indicators <> Undefined Then
		If ApplicationParameters = Undefined Then
			ApplicationParameters = New Map;
		EndIf;
		ApplicationParameters.Insert(NestedIndicatorsParameterName(), New Array);
	EndIf;
	
	Try
		CheckGetServerNotificationsWithIndicators(DataReceiptStatus, Indicators);
	Except
		AreServerCallsAllowed = True;
		Try
			StandardSubsystemsServerCall.MetadataObjectName(Type("Undefined"));
		Except
			AreServerCallsAllowed = False;
		EndTry;
		If Not AreServerCallsAllowed Then
			AttachServerNotificationReceiptCheckHandler(15);
			Return;
		EndIf;
		Raise;
	EndTry;
	
	AddMainIndicator(Indicators, StartMoment,
		"ServerNotificationsClient.CheckAndReceiveServerNotifications", True);
	
EndProcedure

Procedure CheckGetServerNotificationsWithIndicators(DataReceiptStatus, Indicators);
	
	If Not DataReceiptStatus.IsCheckAllowed Then
		Return;
	EndIf;
	
	AdditionalParameters = New Map;
	CurrentSessionDate = CommonClient.SessionDate();
	DataReceiptStatus.CurrentSessionDateToCheckWaitingCounter = BegOfMinute(CurrentSessionDate)
		+ DataReceiptStatus.WaitingCountersDateAlignmentSecondsNumber
		- ?(Second(CurrentSessionDate) < DataReceiptStatus.WaitingCountersDateAlignmentSecondsNumber, 60, 0);
	
	Interval = 60;
	AreChatsActive = DataReceiptStatus.AreClientNotificationsAvailable
		Or DataReceiptStatus.CollaborationSystemConnected
		  And DataReceiptStatus.IsNewPersonalMessageHandlerAttached
		  And DataReceiptStatus.LastReceivedMessageDate + 60 > CurrentSessionDate;
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	Try
		TimeConsumingOperationsClient.BeforeRecurringClientDataSendToServer(AdditionalParameters,
			AreChatsActive, Interval);
	Except
		HandleError(ErrorInfo());
	EndTry;
	AddMainIndicator(Indicators, StartMoment,
		"TimeConsumingOperationsClient.BeforeRecurringClientDataSendToServer");
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	AreNotificationsReceived = AreNotificationsReceived(DataReceiptStatus);
	AddMainIndicator(Indicators, StartMoment, "ServerNotificationsClient.AreNotificationsReceived");
	
	ChatsParametersKeyName = "StandardSubsystems.Core.ServerNotifications.ChatsIDs";
	ShouldSendDataRecurrently = TimeoutExpired(
		"StandardSubsystems.Core.ServerNotifications.ShouldSendDataRecurrently",
		DataReceiptStatus.RepeatedDateExportMinInterval * 60);
	
	If ShouldSendDataRecurrently Then
		If DataReceiptStatus.IsRecurringDataSendEnabled Then
			StartMoment = CurrentUniversalDateInMilliseconds();
			Try
				SSLSubsystemsIntegrationClient.BeforeRecurringClientDataSendToServer(
					AdditionalParameters);
			Except
				HandleError(ErrorInfo());
			EndTry;
			AddMainIndicator(Indicators, StartMoment,
				"SSLSubsystemsIntegrationClient.BeforeRecurringClientDataSendToServer");
			
			StartMoment = CurrentUniversalDateInMilliseconds();
			Try
				CommonClientOverridable.BeforeRecurringClientDataSendToServer(
					AdditionalParameters);
			Except
				HandleError(ErrorInfo());
			EndTry;
			AddMainIndicator(Indicators, StartMoment,
				"CommonClientOverridable.BeforeRecurringClientDataSendToServer");
		EndIf;
		
		StartMoment = CurrentUniversalDateInMilliseconds();
		Try
			If CommonClient.SubsystemExists("StandardSubsystems.UsersSessions") Then
				ModuleIBConnectionsClient = CommonClient.CommonModule("IBConnectionsClient");
				ModuleIBConnectionsClient.BeforeRecurringClientDataSendToServer(AdditionalParameters,
					AreNotificationsReceived);
			EndIf;
		Except
			HandleError(ErrorInfo());
		EndTry;
		AddMainIndicator(Indicators, StartMoment,
			"IBConnectionsClient.BeforeRecurringClientDataSendToServer");
		
		If DataReceiptStatus.ServiceAdministratorSession Then
			ParameterName = "StandardSubsystems.Core.ServerNotifications.RemovingOutdatedAlerts";
			If TimeoutExpired(ParameterName) Then
				AdditionalParameters.Insert(ParameterName, True);
			EndIf;
		EndIf;
		
		If DataReceiptStatus.PersonalChatID = Undefined
		   And DataReceiptStatus.CollaborationSystemConnected
		   And TimeoutExpired(ChatsParametersKeyName, 300, True) Then
			
			AdditionalParameters.Insert(ChatsParametersKeyName, True);
		EndIf;
	EndIf;
	
	If DataReceiptStatus.DateOfLastServerCall + 60 < CurrentSessionDate Then
		MessagesForEventLog = ApplicationParameters["StandardSubsystems.MessagesForEventLog"];
	EndIf;
	
	If AreNotificationsReceived
	   And Not DataReceiptStatus.ShouldReceiveImmediately
	   And Not ValueIsFilled(AdditionalParameters)
	   And Not ValueIsFilled(MessagesForEventLog) Then
		
		AttachServerNotificationReceiptCheckHandler(Interval);
		Return;
	EndIf;
	
	CommonCallParameters = CommonServerCallNewParameters();
	CommonCallParameters.LastNotificationDate = DataReceiptStatus.LastNotificationDate;
	If ValueIsFilled(AdditionalParameters) Then
		CommonCallParameters.Insert("AdditionalParameters", AdditionalParameters);
	EndIf;
	If ShouldSendDataRecurrently Then
		CommonCallParameters.Insert("ShouldSendDataRecurrently",
			DataReceiptStatus.IsRecurringDataSendEnabled);
	EndIf;
	MessagesNew = ApplicationParameters["StandardSubsystems.MessagesForEventLog"];
	If ValueIsFilled(MessagesNew) Then
		CommonCallParameters.Insert("MessagesForEventLog", MessagesNew);
	EndIf;
	If Indicators <> Undefined Then
		CommonCallParameters.Insert("ShouldRegisterIndicators", True);
	EndIf;
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	CommonCallResult = ServerNotificationsInternalServerCall.SessionUndeliveredServerNotifications(
		CommonCallParameters);
	AddMainIndicator(Indicators, StartMoment,
		"ServerNotificationsInternalServerCall.SessionUndeliveredServerNotifications");
	
	If TypeOf(CommonCallResult) <> Type("Structure") Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Hàm ""%1""
			           |đã trả về giá trị không hợp lệ ""%2"" có kiểu ""%3"" thay vì kiểu ""%4"":
			           |- hoặc hàm đã bị thay đổi bởi một tiện ích mở rộng;
			           |- hoặc sau lần cập nhật cấu hình tiếp theo, bộ nhớ đệm metadata của nền tảng 1C:Enterprise trên client hoặc server đã được cập nhật không đúng cách (trong trường hợp này cần xóa bộ nhớ đệm);
			           |- hoặc khi gọi trên server đã xảy ra một lỗi bất thường và nền tảng 1C:Enterprise đã xử lý không đúng, dẫn đến việc thay vì gọi ra ngoại lệ thì trả về giá trị Không xác định (để ghi nhận lỗi cần có khả năng tái hiện ổn định).';
			           |ru = 'Функция ""%1""
			           |вернула некорректное значение ""%2"" типа ""%3"" вместо типа ""%4"":
			           |- либо функция была изменена расширением;
			           |- либо после очередного обновления конфигурации некорректно обновились кэши метаданных платформы 1С:Предприятия на клиенте или на сервере (тогда их нужно почистить);
			           |- либо при серверном вызове возникла необычная ошибка, которая была некорректно обработана платформой 1С:Предприятия и вместо вызова исключения возвращено значение Неопределено (для регистрации нужна возможность устойчивого воспроизведения).';
			           |en = 'The function %1()
			           |returned an invalid value ""%2"" of type %3 instead of the expected type %4. Possible reasons:
			           |- The function was modified by an extension.
			           |- The 1C:Enterprise metadata cache on the client or server was not refreshed correctly after a configuration update. Try clearing the cache.
			           |- An unexpected server-side error occurred and was handled incorrectly by 1C:Enterprise, returning Undefined instead of raising an exception. To report a bug, ensure that the issue can be reproduced and include the steps required to trigger it.'; fa = 'The function %1()
			           |returned an invalid value ""%2"" of type %3 instead of the expected type %4. Possible reasons:
			           |- The function was modified by an extension.
			           |- The 1C:Enterprise metadata cache on the client or server was not refreshed correctly after a configuration update. Try clearing the cache.
			           |- An unexpected server-side error occurred and was handled incorrectly by 1C:Enterprise, returning Undefined instead of raising an exception. To report a bug, ensure that the issue can be reproduced and include the steps required to trigger it.';
			           |it = 'The function %1()
			           |returned an invalid value ""%2"" of type %3 instead of the expected type %4. Possible reasons:
			           |- The function was modified by an extension.
			           |- The 1C:Enterprise metadata cache on the client or server was not refreshed correctly after a configuration update. Try clearing the cache.
			           |- An unexpected server-side error occurred and was handled incorrectly by 1C:Enterprise, returning Undefined instead of raising an exception. To report a bug, ensure that the issue can be reproduced and include the steps required to trigger it.';
			           |pl = 'The function %1()
			           |returned an invalid value ""%2"" of type %3 instead of the expected type %4. Possible reasons:
			           |- The function was modified by an extension.
			           |- The 1C:Enterprise metadata cache on the client or server was not refreshed correctly after a configuration update. Try clearing the cache.
			           |- An unexpected server-side error occurred and was handled incorrectly by 1C:Enterprise, returning Undefined instead of raising an exception. To report a bug, ensure that the issue can be reproduced and include the steps required to trigger it.';
			           |tr = '""%1""
			           |fonksiyonu ""%3"" tipinde ""%2"" değerini ""%4"" tipine döndürdü:
			           | - Ya da fonksiyon uzantı tarafından değiştirildi;
			           |- Ya da bir sonraki konfigürasyon güncellemesinden sonra, istemci veya sunucudaki 1C:Enterprise platform meta veri önbellekleri yanlış bir şekilde güncellendi (bu durumda temizlenmeleri gerekir);
			           |- Ya da 1C:Enterprise platformu tarafından yanlış işlenen sunucu çağrısı sırasında alışılmadık bir hata oluştu ve bir istisna oluşturmak yerine, Tanımsız değere döndürüldü (kayıt için sürdürülebilir üretim olanağı gereklidir).'"),
			"ServerNotificationsInternalServerCall.SessionUndeliveredServerNotifications",
			String(CommonCallResult),
			String(TypeOf(CommonCallResult)),
			String(Type("Structure")));
		Try
			Raise ErrorText;
		Except
			ErrorInfo = ErrorInfo();
			ServerNotificationsInternalServerCall.RegisterUndeliveredServerNotificationsRetrievalError(
				ErrorProcessing.DetailErrorDescription(ErrorInfo));
		EndTry;
		AttachServerNotificationReceiptCheckHandler(15);
		Return;
	EndIf;
	
	If MessagesNew <> Undefined Then
		MessagesNew.Clear();
	EndIf;
	
	If CommonCallResult.Property("Indicators") Then
		CommonClientServer.SupplementArray(Indicators, CommonCallResult.Indicators);
	EndIf;
	
	If CommonCallResult.Property("ServerNotifications") Then
		StartMoment = CurrentUniversalDateInMilliseconds();
		For Each ServerNotification In CommonCallResult.ServerNotifications Do
			ProcessServerNotificationOnClient(DataReceiptStatus, ServerNotification);
		EndDo;
		AddMainIndicator(Indicators, StartMoment,
			"ServerNotificationsClient.ProcessServerNotificationOnClient");
	EndIf;
	DataReceiptStatus.ShouldReceiveImmediately = False;
	
	AdditionalResults = CommonClientServer.StructureProperty(CommonCallResult,
		"AdditionalResults", New Map);
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	Try
		TimeConsumingOperationsClient.AfterRecurringReceiptOfClientDataOnServer(
			AdditionalResults, AreChatsActive, Interval);
	Except
		HandleError(ErrorInfo());
	EndTry;
	AddMainIndicator(Indicators, StartMoment,
		"TimeConsumingOperationsClient.AfterRecurringReceiptOfClientDataOnServer");
	
	If ShouldSendDataRecurrently Then
		If DataReceiptStatus.IsRecurringDataSendEnabled Then
			StartMoment = CurrentUniversalDateInMilliseconds();
			Try
				SSLSubsystemsIntegrationClient.AfterRecurringReceiptOfClientDataOnServer(
					AdditionalResults);
			Except
				HandleError(ErrorInfo());
			EndTry;
			AddMainIndicator(Indicators, StartMoment,
				"SSLSubsystemsIntegrationClient.AfterRecurringReceiptOfClientDataOnServer");
			
			StartMoment = CurrentUniversalDateInMilliseconds();
			Try
				CommonClientOverridable.AfterRecurringReceiptOfClientDataOnServer(
					AdditionalResults);
			Except
				HandleError(ErrorInfo());
			EndTry;
			AddMainIndicator(Indicators, StartMoment,
				"CommonClientOverridable.AfterRecurringReceiptOfClientDataOnServer");
		EndIf;
		
		StartMoment = CurrentUniversalDateInMilliseconds();
		Try
			If CommonClient.SubsystemExists("StandardSubsystems.UsersSessions") Then
				ModuleIBConnectionsClient = CommonClient.CommonModule("IBConnectionsClient");
				ModuleIBConnectionsClient.AfterRecurringReceiptOfClientDataOnServer(
					AdditionalResults);
			EndIf;
		Except
			HandleError(ErrorInfo());
		EndTry;
		AddMainIndicator(Indicators, StartMoment,
			"IBConnectionsClient.AfterRecurringReceiptOfClientDataOnServer");
		
		ChatsIDs = AdditionalResults.Get(ChatsParametersKeyName);
		If ChatsIDs <> Undefined Then
			FillPropertyValues(DataReceiptStatus, ChatsIDs);
			StartMoment = CurrentUniversalDateInMilliseconds();
			AttachNewMessageHandler(DataReceiptStatus);
			AddMainIndicator(Indicators, StartMoment,
				"ServerNotificationsClient.AttachNewMessageHandler");
		EndIf;
		
		If CommonCallResult.Property("CollaborationSystemConnected") Then
			DataReceiptStatus.CollaborationSystemConnected = CommonCallResult.CollaborationSystemConnected;
		EndIf;
	EndIf;
	
	CurrentSessionDate = CommonClient.SessionDate();
	If CommonCallResult.Property("LastNotificationDate")
	   And CommonCallResult.LastNotificationDate <= CurrentSessionDate + 2 Then
		DataReceiptStatus.LastNotificationDate = CommonCallResult.LastNotificationDate;
	EndIf;
	If CommonCallResult.Property("MinCheckInterval") Then
		DataReceiptStatus.MinimumPeriod = CommonCallResult.MinCheckInterval;
	EndIf;
	DataReceiptStatus.StatusUpdateDate = CurrentSessionDate;
	DataReceiptStatus.DateOfLastServerCall = CurrentSessionDate;
	
	If Interval > DataReceiptStatus.MinimumPeriod Then
		Interval = DataReceiptStatus.MinimumPeriod;
	EndIf;
	
	AttachServerNotificationReceiptCheckHandler(Interval);
	
EndProcedure

Procedure AddMainIndicator(Indicators, StartMoment, ProcedureName,
			Shared = False, Nested = False, Duration = 0)
	
	If Indicators = Undefined Then
		Return;
	EndIf;
	
	Duration = CurrentUniversalDateInMilliseconds() - StartMoment;
	If Not Shared And Not ValueIsFilled(Duration) Then
		Return;
	EndIf;
	
	Text = Format(Duration / 1000, "ND=6; NFD=3; NZ=000,000; NLZ=") + " " + ProcedureName;
	
	If Shared Then
		Indicators.Insert(0, Text);
		WriteIndicators(Indicators, Duration);
		Return;
	Else
		Indicators.Add("  " + Text);
	EndIf;
	
	If Nested Then
		Return;
	EndIf;
	
	NestedIndicators = ApplicationParameters.Get(NestedIndicatorsParameterName());
	For Each NestedIndicator In NestedIndicators Do
		Indicators.Add("  " + NestedIndicator);
	EndDo;
	NestedIndicators.Clear();
	
EndProcedure

Function NestedIndicatorsParameterName()
	Return "StandardSubsystems.Core.ServerNotifications.Indicators";
EndFunction

Procedure WriteIndicators(Indicators, TotalDuration)
	
	Comment = StrConcat(Indicators, Chars.LF);
	ServerCallMethodName = "ServerNotificationsInternalServerCall.SessionUndeliveredServerNotifications";
	
	If TotalDuration < 50
	   And StrFind(Comment, ServerCallMethodName) = 0 Then
		Return;
	EndIf;
	
	ServerNotificationsInternalServerCall.WritePerformanceIndicators(Comment);
	
EndProcedure

Procedure ProcessServerNotificationOnClient(DataReceiptStatus, ServerNotification)
	
	If IsNotificationReceived(DataReceiptStatus, ServerNotification) Then
		Return;
	EndIf;
	
	NameOfAlert = ServerNotification.NameOfAlert;
	Result     = ServerNotification.Result;
	
	If NameOfAlert = "StandardSubsystems.Core.ServerNotifications.ShouldRegisterIndicators" Then
		DataReceiptStatus.ShouldRegisterIndicators = (Result = True);
		Return;
	ElsIf NameOfAlert = "StandardSubsystems.Core.ServerNotifications.CollaborationSystemConnected" Then
		DataReceiptStatus.CollaborationSystemConnected = (Result = True);
		Return;
	EndIf;
	
	Notification = DataReceiptStatus.Notifications.Get(NameOfAlert);
	If Notification = Undefined Then
		Return;
	EndIf;
	
	DataProcessorModule = CommonClient.CommonModule(Notification.NotificationReceiptModuleName);
	Try
		DataProcessorModule.OnReceiptServerNotification(NameOfAlert, Result);
	Except
		ErrorInfo = ErrorInfo();
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Chưa thực hiện thủ tục ""%1"" do nguyên nhân:
			           |%2';
			           |ru = 'Процедура ""%1"" не выполнена по причине:
			           |%2';
			           |en = 'Cannot execute the ""%1"" procedure due to:
			           |%2'; fa = 'Cannot execute the ""%1"" procedure due to:
			           |%2';
			           |it = 'Процедура ""%1"" не выполнена по причине:
			           |%2';
			           |pl = 'Cannot execute the ""%1"" procedure due to:
			           |%2';
			           |tr = '""%1"" prosedürü şu sebeple tamamlanmadı:
			           |%2'"),
			Notification.NotificationReceiptModuleName + ".OnReceiptServerNotification",
			ErrorProcessing.DetailErrorDescription(ErrorInfo));
		EventLogClient.AddMessageForEventLog(
			NStr("vi = 'Thông báo từ máy chủ.Lỗi xử lý thông báo đã nhận';
				|ru = 'Серверные оповещения.Ошибка обработки полученного оповещения';
				|en = 'Server notifications.An error occurred when processing the received message'; fa = 'Server notifications.An error occurred when processing the received message';
				|it = 'Avvisi server. Errore di elaborazione del messaggio ricevuto';
				|pl = 'Powiadomienia serwerowe.Błąd przetwarzania otrzymanego powiadomienia';
				|tr = 'Sunucu bildirimleri.Alınan bildirimi işleme hatası'",
				CommonClient.DefaultLanguageCode()),
			"Error",
			ErrorText);
	EndTry;
	
EndProcedure

Function AreNotificationsReceived(DataReceiptStatus)
	
	AttachNewMessageHandler(DataReceiptStatus);
	
	Boundary = DataReceiptStatus.StatusUpdateDate + DataReceiptStatus.MinimumPeriod;
	
	Inventory = Boundary - CommonClient.SessionDate();
	
	If Inventory > 0 Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

// See NewReceiptStatus
Function DataReceiptStatus() Export
	
	AppParameterName = "StandardSubsystems.Core.ServerNotifications";
	DataReceiptStatus = ApplicationParameters.Get(AppParameterName);
	If DataReceiptStatus = Undefined Then
		DataReceiptStatus = NewReceiptStatus();
		ApplicationParameters.Insert(AppParameterName, DataReceiptStatus);
	EndIf;
	
	DataReceiptStatus.AreClientNotificationsAvailable =
		StandardSubsystemsClientCached.AreClientNotificationsAvailable();
	
	Return DataReceiptStatus;
	
EndFunction

// Returns:
//  Structure:
//   * LastNotificationDate - Date
//   * AdditionalParameters - Map
//   * MessagesForEventLog - Undefined, ValueList
//   * ShouldSendDataRecurrently - Boolean
//   * ShouldRegisterIndicators - Boolean
//
Function CommonServerCallNewParameters() Export
	
	Result = New Structure;
	Result.Insert("LastNotificationDate",  '00010101');
	
	Return Result;
	
EndFunction

// Returns:
//  Structure:
//   * IsCheckAllowed - Boolean - Is set to True in the BeforeStart procedure.
//   * ShouldRegisterIndicators - Boolean
//   * ServiceAdministratorSession - Boolean
//   * IsRecurringDataSendEnabled - Boolean - Is set to True in the AfterStart procedure.
//   * RepeatedDateExportMinInterval - See ServerNotifications.
//   * SessionKey - See ServerNotifications.SessionKey
//   * IBUserID - UUID
//   * StatusUpdateDate - Date
//   * LastReceivedMessageDate - Date
//   * MinimumPeriod - Number - Time interval in seconds.
//   * LastNotificationDate - Date
//   * Notifications - See CommonOverridable.OnAddServerNotifications.Notifications
//   * ReceivedNotifications - Array of String - UUID strings of the received messages.
//   * AreClientNotificationsAvailable - Boolean
//   * CollaborationSystemConnected - Boolean
//   * PersonalChatID - Undefined - Chat is unavailable.
//                                    - CollaborationSystemConversationID - ID of the chat
//        "ServerNotifications <Infobase user ID>".
//
//   * GlobalChatID - Undefined - Chat is unavailable.
//                                   - CollaborationSystemConversationID - ID of the chat
//        "ServerNotifications".
//   * IsNewPersonalMessageHandlerAttached - Boolean
//   * IsNewGlobalMessageHandlerAttached - Boolean
//   * DateOfLastServerCall - Date
//   * CurrentSessionDateToCheckWaitingCounter - Date
//   * WaitingCountersDateAlignmentSecondsNumber - Number
//   * WaitCounters - Map of KeyAndValue:
//      ** Key - String - Counter name
//      ** Value - Date - Last time the counter triggered.
//   * ShouldReceiveImmediately - Boolean - If set to "True", the server call is made unconditionally.
//
Function NewReceiptStatus()
	
	State = New Structure;
	State.Insert("IsCheckAllowed", False);
	State.Insert("ShouldRegisterIndicators", False);
	State.Insert("ServiceAdministratorSession", False);
	State.Insert("IsRecurringDataSendEnabled", False);
	State.Insert("RepeatedDateExportMinInterval", 1);
	State.Insert("SessionKey", "");
	State.Insert("IBUserID",
		CommonClientServer.BlankUUID());
	State.Insert("StatusUpdateDate", '00010101');
	State.Insert("LastReceivedMessageDate", '00010101');
	State.Insert("MinimumPeriod", 60);
	State.Insert("LastNotificationDate", '00010101');
	State.Insert("Notifications", New Map);
	State.Insert("ReceivedNotifications", New Array);
	State.Insert("AreClientNotificationsAvailable", False);
	State.Insert("CollaborationSystemConnected", False);
	State.Insert("PersonalChatID", Undefined);
	State.Insert("GlobalChatID", Undefined);
	State.Insert("IsNewPersonalMessageHandlerAttached", False);
	State.Insert("IsNewGlobalMessageHandlerAttached", False);
	State.Insert("DateOfLastServerCall", '00010101');
	State.Insert("CurrentSessionDateToCheckWaitingCounter", '00010101');
	State.Insert("WaitingCountersDateAlignmentSecondsNumber", 0);
	State.Insert("WaitCounters", New Map);
	State.Insert("ShouldReceiveImmediately", False);
	
	Return State;
	
EndFunction

Procedure AttachNewMessageHandler(DataReceiptStatus)
	
	Context = New Structure("DataReceiptStatus", DataReceiptStatus);
	
	If DataReceiptStatus.AreClientNotificationsAvailable Then
		ClientNotificationManager().AttachHandler(
			ServerNotificationsInternalClientServer.ServerNotificationsNotificationsKey(),
			New CallbackDescription("OnGetNewClientNotification", ThisObject, Context,
				"OnErrorGettingNewClientNotification", ThisObject));
		Return;
	EndIf;
	
	If DataReceiptStatus.PersonalChatID <> Undefined
	   And Not DataReceiptStatus.IsNewPersonalMessageHandlerAttached Then
		
		Try
			CollaborationSystem.BeginAttachNewMessagesHandler(
				New CallbackDescription("AfterAttachingNewPersonalMessageHandler", ThisObject, Context,
					"AfterNewPersonalMessageHandlerAttachError", ThisObject),
				DataReceiptStatus.PersonalChatID,
				New CallbackDescription("OnReceiptNewInteractionSystemPersonalMessage", ThisObject, Context,
					"OnInteractionSystemNewPersonalMessageReceiptError", ThisObject),
				Undefined);
		Except
			AfterNewPersonalMessageHandlerAttachError(ErrorInfo(), False, Context);
		EndTry;
	EndIf;
	
	If DataReceiptStatus.GlobalChatID <> Undefined
	   And Not DataReceiptStatus.IsNewGlobalMessageHandlerAttached Then
		
		Try
			CollaborationSystem.BeginAttachNewMessagesHandler(
				New CallbackDescription("AfterAttachingNewGroupMessageHandler", ThisObject, Context,
					"AfterNewGlobalMessageHandlerAttachError", ThisObject),
				DataReceiptStatus.GlobalChatID,
				New CallbackDescription("OnReceiptNewInteractionSystemGlobalMessage", ThisObject, Context,
					"OnInteractionSystemNewGlobalMessageReceiptError", ThisObject),
				Undefined);
		Except
			AfterNewGlobalMessageHandlerAttachError(ErrorInfo(), False, Context);
		EndTry;
	EndIf;
	
EndProcedure

Procedure AfterAttachingNewPersonalMessageHandler(Context) Export
	
	Context.DataReceiptStatus.IsNewPersonalMessageHandlerAttached = True;
	
EndProcedure

Procedure AfterNewPersonalMessageHandlerAttachError(ErrorInfo, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	EventLogClient.AddMessageForEventLog(
		NStr("vi = 'Thông báo từ máy chủ.Lỗi kết nối hàm sự kiện thông báo cá nhân mới';
			|ru = 'Серверные оповещения.Ошибка подключения обработчика новых личных сообщений';
			|en = 'Server notifications.An error occurred when connecting the handler of new personal messages'; fa = 'Server notifications.An error occurred when connecting the handler of new personal messages';
			|it = 'Avvisi server. Errore di collegamento gestore di nuovi messaggi personali';
			|pl = 'Powiadomienia serwerowe.Błąd podłączenia procedury przetwarzania nowych wiadomości osobistych';
			|tr = 'Sunucu bildirimleri.Yeni özel mesaj işleyici bağlantı hatası'",
			CommonClient.DefaultLanguageCode()),
		"Error",
		ErrorProcessing.DetailErrorDescription(ErrorInfo));
	
EndProcedure

Procedure OnReceiptNewInteractionSystemPersonalMessage(Message, Context) Export
	
	OnReceiptNewInteractionSystemMessage(Message, Context);
	
EndProcedure

Procedure OnInteractionSystemNewPersonalMessageReceiptError(ErrorInfo, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	EventLogClient.AddMessageForEventLog(
		NStr("vi = 'Thông báo từ máy chủ.Lỗi nhận thông báo cá nhân mới';
			|ru = 'Серверные оповещения.Ошибка получения нового личного сообщения';
			|en = 'Server notifications.An error occurred when receiving a new personal message'; fa = 'Server notifications.An error occurred when receiving a new personal message';
			|it = 'Avvisi server. Errore di ricezione del nuovo messaggio personale';
			|pl = 'Powiadomienia serwerowe.Błąd otrzymania nowej wiadomości osobistej';
			|tr = 'Sunucu bildirimleri.Yeni özel mesaj alma hatası'",
			CommonClient.DefaultLanguageCode()),
		"Error",
		ErrorProcessing.DetailErrorDescription(ErrorInfo));
	
EndProcedure

Procedure AfterAttachingNewGroupMessageHandler(Context) Export
	
	Context.DataReceiptStatus.IsNewGlobalMessageHandlerAttached = True;
	
EndProcedure

Procedure AfterNewGlobalMessageHandlerAttachError(ErrorInfo, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	EventLogClient.AddMessageForEventLog(
		NStr("vi = 'Thông báo từ máy chủ.Lỗi kết nối hàm sự kiện thông báo chung mới';
			|ru = 'Серверные оповещения.Ошибка подключения обработчика новых общих сообщений';
			|en = 'Server notifications.An error occurred when connecting the handler of new common messages'; fa = 'Server notifications.An error occurred when connecting the handler of new common messages';
			|it = 'Avvisi server. Errore di collegamento gestore di nuovi messaggi comuni';
			|pl = 'Powiadomienia serwerowe.Błąd podłączenia procedury przetwarzania nowych wiadomości ogólnych';
			|tr = 'Sunucu bildirimleri.Yeni paylaşımlı mesaj işleyici bağlantı hatası'",
			CommonClient.DefaultLanguageCode()),
		"Error",
		ErrorProcessing.DetailErrorDescription(ErrorInfo));
	
EndProcedure

Procedure OnReceiptNewInteractionSystemGlobalMessage(Message, Context) Export
	
	OnReceiptNewInteractionSystemMessage(Message, Context);
	
EndProcedure

Procedure OnInteractionSystemNewGlobalMessageReceiptError(ErrorInfo, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	EventLogClient.AddMessageForEventLog(
		NStr("vi = 'Thông báo từ máy chủ.Lỗi nhận thông báo chung mới';
			|ru = 'Серверные оповещения.Ошибка получения нового общего сообщения';
			|en = 'Server notifications.An error occurred when receiving a new common message'; fa = 'Server notifications.An error occurred when receiving a new common message';
			|it = 'Avvisi server. Errore di ricezione del nuovo messaggio comune';
			|pl = 'Powiadomienia serwerowe.Błąd otrzymania nowej wiadomości ogólnego';
			|tr = 'Sunucu bildirimleri.Yeni paylaşımlı mesaj alma hatası'",
			CommonClient.DefaultLanguageCode()),
		"Error",
		ErrorProcessing.DetailErrorDescription(ErrorInfo));
	
EndProcedure

// Parameters:
//  Message - CollaborationSystemMessage
//  Context  - Structure:
//    * DataReceiptStatus - See NewReceiptStatus
//
Procedure OnReceiptNewInteractionSystemMessage(Message, Context)
	
	DataReceiptStatus = Context.DataReceiptStatus;
	
	If Not DataReceiptStatus.IsCheckAllowed
	 Or ApplicationParameters = Undefined Then
		Return;
	EndIf;
	
	DataReceiptStatus.LastReceivedMessageDate = CommonClient.SessionDate();
	
	Try
		Data = Message.Data; // See ServerNotifications.MessageNewData
	Except
		ErrorInfo = ErrorInfo();
		LongDesc = New Structure;
		LongDesc.Insert("Date", Message.Date);
		LongDesc.Insert("Id", String(Message.ID));
		LongDesc.Insert("Conversation", String(Message.Conversation));
		LongDesc.Insert("Text", TrimAll(Message.Text));
		LongDesc.Insert("DetailErrorDescription",
			ErrorProcessing.DetailErrorDescription(ErrorInfo));
		ServerNotificationsInternalServerCall.LogErrorGettingDataFromMessage(LongDesc);
		Return;
	EndTry;
	
	OnReceiptServerNotification(Data, DataReceiptStatus);
	
EndProcedure

Procedure OnReceiptServerNotification(Data, DataReceiptStatus)
	
	If TypeOf(Data) <> Type("Structure")
	 Or Not Data.Property("NameOfAlert") Then
		Return;
	EndIf;
	
	If Data.NameOfAlert <> "NoServerNotifications" Then
		If Data.Recipients <> Undefined Then
			SessionsKeys = Data.Recipients.Get(DataReceiptStatus.IBUserID);
			If TypeOf(SessionsKeys) <> Type("Array")
			 Or SessionsKeys.Find(DataReceiptStatus.SessionKey) = Undefined
			   And SessionsKeys.Find("*") = Undefined Then
				Return;
			EndIf;
		EndIf;
		ProcessServerNotificationOnClient(DataReceiptStatus, Data);
		If Not Data.WasSentFromQueue Then
			Return;
		EndIf;
	EndIf;
	
	ThisIsDateAlertWasAdded = False;
	LastNotificationDate = Data.Errors.Get(DataReceiptStatus.IBUserID);
	If LastNotificationDate = Undefined Then
		LastNotificationDate = Data.Errors.Get("AllUsers");
		If LastNotificationDate = Undefined Then
			LastNotificationDate = Data.AddedOn;
			ThisIsDateAlertWasAdded = True;
		EndIf;
	EndIf;
	
	CurrentSessionDate = CommonClient.SessionDate();
	If LastNotificationDate <= CurrentSessionDate + 2 Then
		If DataReceiptStatus.LastNotificationDate < LastNotificationDate Then
			DataReceiptStatus.LastNotificationDate = LastNotificationDate;
		EndIf;
		If ThisIsDateAlertWasAdded Then
			DataReceiptStatus.StatusUpdateDate = CurrentSessionDate;
		EndIf;
	EndIf;
	
EndProcedure

Function IsNotificationReceived(DataReceiptStatus, ServerNotification)
	
	If ServerNotification.AddedOn < DataReceiptStatus.LastNotificationDate - 5
	   And (ServerNotification.WasSentFromQueue
	      Or Not DataReceiptStatus.AreClientNotificationsAvailable) Then
		Return True;
	EndIf;
	
	ReceivedNotifications = DataReceiptStatus.ReceivedNotifications;
	
	If ReceivedNotifications.Find(ServerNotification.NotificationID) <> Undefined Then
		Return True;
	EndIf;
	
	ReceivedNotifications.Add(ServerNotification.NotificationID);
	If ReceivedNotifications.Count() > 1000 Then
		ReceivedNotifications.Delete(0);
	EndIf;
	
	Return False;
	
EndFunction

// Client notifications

Procedure OnGetNewClientNotification(Data, Context) Export
	
	DataReceiptStatus = Context.DataReceiptStatus;
	
	If Not DataReceiptStatus.IsCheckAllowed
	 Or ApplicationParameters = Undefined Then
		Return;
	EndIf;
	
	DataReceiptStatus.LastReceivedMessageDate = CommonClient.SessionDate();
	
	OnReceiptServerNotification(Data, DataReceiptStatus);
	
EndProcedure

Procedure OnErrorGettingNewClientNotification(ErrorInfo, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	EventLogClient.AddMessageForEventLog(
		NStr("vi = 'Thông báo từ máy chủ.Lỗi nhận thông báo chung mới';
			|ru = 'Серверные оповещения.Ошибка получения нового уведомления клиента';
			|en = 'Server notifications.Error obtaining new client notification'; fa = 'Server notifications.Error obtaining new client notification';
			|it = 'Серверные оповещения.Ошибка получения нового уведомления клиента';
			|pl = 'Server notifications.Error obtaining new client notification';
			|tr = 'Sunucu bildirimleri. Yeni istemci bildirimi alınırken hata oluştu'",
			CommonClient.DefaultLanguageCode()),
		"Error",
		ErrorProcessing.DetailErrorDescription(ErrorInfo));
	
EndProcedure

Function ClientNotificationManager()
	
	// ACC:488-off - Support of new 1C:Enterprise opportunities (the executable code is safe)
	Return Eval("ClientNotifications")
	// ACC:488-on
	
EndFunction

#EndRegion