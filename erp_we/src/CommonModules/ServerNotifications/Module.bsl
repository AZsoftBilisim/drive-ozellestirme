///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Intended for the CommonOverridable.OnAddServerNotifications procedure.
//
// Parameters:
//  Name - String - Notification name matching the structure property name.
//
// Returns:
//  Structure:
//   * Name - String - Notification name.
//
//   * NotificationSendModuleName - String - Name of the server module containing the export procedure
//                    OnSendServerNotification. For example, "IBConnections".
//                    For a use case, see the StandardSubsystemsServer common module.
//                    An optional parameter. If not passed, the procedure will not be called.
//                    For example, to notify about functional option changes immediately after its constant is reassigned
//                    (instead of tracking changes in the scheduled job).
//                    
//                    
//
//   * NotificationReceiptModuleName - String - Name of the client common module containing the export procedure
//                    OnReceiptServerNotification. For example, "IBConnectionsClient".
//                    For a use case, see the StandardSubsystemsClient common module.
//
//   * Parameters - Arbitrary - Any serializable value to pass as a parameter to the OnSendServerNotification procedure.
//                    Try to make the size of serialized values as small as possible.
//                    For example, the details of session extensions and metadata it order to calculate
//                    the added and removed extensions and patches in a scheduled job upon calling
//                    OnSendServerNotification and sending a notification containing the diff of the given sessions.
//                    
//                    
//
//   * VerificationPeriod - Number - Timeout (in seconds) before calling OnSendServerNotification
//                         in order to check the status of the server and notification (if required).
//                         The start value is 20 minutes.
//                         If the passed timeout is less than 60 seconds, it will be increased to "60".
//                         Note: The actual minimal interval in SaaS might be greater and vary (5 to 10 minutes).
//                         
//                         
//
//
Function NewServerNotification(Name) Export
	
	Result = New Structure;
	Result.Insert("Name", Name);
	Result.Insert("NotificationSendModuleName", "");
	Result.Insert("NotificationReceiptModuleName", "");
	Result.Insert("Parameters", Undefined);
	Result.Insert("VerificationPeriod", 20*60);
	
	Return Result;
	
EndFunction

// Queues a server notification to be delivered to the client.
// It will be delivered by the Collaboration System or within a server call.
// 
//
// Parameters:
//  NameOfAlert - String - See NewServerNotification.Name.
//  
//  Result - Arbitrary - Any serializable value to send to the client within the notification.
//             Try to make the size of serialized values as small as possible.
//             The recommended size is less than 1 KB.
//
//  Recipients - Undefined - All users (all sessions).
//               If an empty map is passed, then return.
//           - Map of KeyAndValue:
//              * Key - UUID - infobase user ID.
//              * Value - Array of See ServerNotifications.SessionKey
//                         - Array of String - if the array contains "*", then it's for all the user sessions.
//
//  SendImmediately - Boolean - If True, tries to send a message immediately via the
//               Collaboration System, and it fails, adds it to the queue.
//               The handlers of the OnSendServerNotification event don't support immediate sending.
//               Note: A failed request to the Collaboration System takes about (3–5 sec)*2,
//               a successful one takes about (50 msec)*2. This is particularly important when developing transactions.
//
Procedure SendServerNotification(NameOfAlert, Result, Recipients, SendImmediately = False) Export
	
	SendServerNotificationWithGroupID(NameOfAlert, Result, Recipients, SendImmediately);
	
EndProcedure

// Logs an error caught in the handlers of the
// OnReceiptRecurringClientDataOnServer event.
//
// Parameters:
//  ErrorInfo - ErrorInfo
//
// Example:
//	StartMoment = CurrentUniversalDateInMilliseconds();
//	Try
//		If Common.SubsystemExists("StandardSubsystems.MonitoringCenter") Then
//			ModuleMonitoringCenterInternal = Common.CommonModule("MonitoringCenterInternal");
//			ModuleMonitoringCenterInternal.OnReceiptRecurringClientDataOnServer(Parameters, Results);
//		EndIf;
//	Except
//		ServerNotifications.HandleError(ErrorInfo());
//	EndTry;
//	ServerNotifications.AddIndicator(Results, StartMoment,
//		"MonitoringCenterInternal.OnReceiptRecurringClientDataOnServer");
//
Procedure HandleError(ErrorInfo) Export
	
	WriteLogEvent(
		NStr("vi = 'Thông báo từ máy chủ.Lỗi nhận hoặc xử lý thông báo';
			|ru = 'Серверные оповещения.Ошибка получения или обработки оповещений';
			|en = 'Server notifications.Error getting or processing notifications'; fa = 'Server notifications.Error getting or processing notifications';
			|it = 'Серверные оповещения.Ошибка получения или обработки оповещений';
			|pl = 'Server notifications.Error getting or processing notifications';
			|tr = 'Sunucu uyarısı.Alma işleminde veya uyarının işlenmesinde hata.'",
			Common.DefaultLanguageCode()),
		EventLogLevel.Error,,,
		ErrorProcessing.DetailErrorDescription(ErrorInfo));
	
EndProcedure

// Adds a performance indicator to the handlers of the event
// OnReceiptRecurringClientDataOnServer.
//
// Parameters:
//  Results - See CommonOverridable.OnReceiptRecurringClientDataOnServer.Results
//  StartMoment - Number - CurrentUniversalDateInMilliseconds before the procedure will be called.
//  ProcedureName - String - Full name of the called procedure
//
// Example:
//	StartMoment = CurrentUniversalDateInMilliseconds();
//	Try
//		If Common.SubsystemExists("StandardSubsystems.MonitoringCenter") Then
//			ModuleMonitoringCenterInternal = Common.CommonModule("MonitoringCenterInternal");
//			ModuleMonitoringCenterInternal.OnReceiptRecurringClientDataOnServer(Parameters, Results);
//		EndIf;
//	Except
//		ServerNotifications.HandleError(ErrorInfo());
//	EndTry;
//	ServerNotifications.AddIndicator(Results, StartMoment,
//		"MonitoringCenterInternal.OnReceiptRecurringClientDataOnServer");
//
Procedure AddIndicator(Results, StartMoment, ProcedureName) Export
	
	Indicators = Results.Get(NestedIndicatorsParameterName());
	AddMainIndicator(Indicators, StartMoment, ProcedureName);
	
EndProcedure

#Region InterfaceImplementation

// Returns the session's UUID obtained from
// the session properties SessionStart and SessionNumber.
//
// Parameters:
//  Session - InfoBaseSession
//        - Undefined - Use the current session.
//
// Returns:
//  String - String of the following format: "<SessionStart> <SessionNumber>".
//    For example, "2022.03.07 05:01:09 8342".
//
Function SessionKey(Session = Undefined) Export
	
	If Session = Undefined Then
		Session = GetCurrentInfoBaseSession();
	EndIf;
	
	// ACC:1367-off - No.763.1.1. Arbitrary formats are acceptable
	// as they are intended for internal use only and hidden from the user.
	Return Format(Session.SessionStarted, "DF='yyyy.MM.dd HH:mm:ss'") + " "
		+ Format(Session.SessionNumber, "NZ=0; NG=");
	// ACC:1367-on
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

// See CommonOverridable.OnAddClientParametersOnStart.
Procedure OnAddClientParametersOnStart(Parameters) Export
	
	Parameters.Insert("ServerNotifications", ServerNotificationsParametersThisSession());
	
EndProcedure

// See JobsQueueOverridable.OnDefineHandlerAliases
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export
	
	NamesAndAliasesMap.Insert(
		Metadata.ScheduledJobs.SendServerNotificationsToClients.MethodName);
	
EndProcedure

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	Types.Add(Metadata.Constants.ServerNotificationsSendStatus);
	Types.Add(Metadata.InformationRegisters.PeriodicServerNotifications);
	Types.Add(Metadata.InformationRegisters.SentServerNotifications);
	
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Main procedures and functions.

// Returns:
//  Structure:
//    * GroupID  - UUID - Notification group ID (for writing to the register).
//                           - Undefined - No need to provide.
//    * NotificationTypeInGroup - UUID - ID of the notification type in the notification group.
//                           - Undefined - No need to provide.
//    * DeliveryDeferral     - Number  - If "0", write to the Collaboration System with the scheduled job (unless it must be sent immediately).
//                                      Otherwise, the timeout in seconds before writing the message to the Collaboration System.
//                                      If the passed timeout exceeds 5 seconds, it will be reduced to "5".
//    * Replace             - Boolean - Flag indicating whether the last undelivered notification of the given type in the group must be
//                                      replaced with a new one considering the specified delay (excluding the elapsed time).
//                                      If the delay is more than 0, ShouldSendImmediately is ignored.
//
//    * LogEventOnDeliveryDeferral     - String - Event name that will be logged upon the delayed delivery.
//                                                Applicable if "Replace" is set to True.
//    * LogCommentOnDeliveryDeferral - String - Event comment for the Event Log.
//    
//    * ShouldWriteUnconditionally - Boolean - If set to "True", the method writers the notification to the register
//                                    even in cases where client notifications are available
//                                    (for example, to get messages from the notifications).
//
Function AdditionalSendingParameters() Export
	
	Result = New Structure;
	Result.Insert("GroupID");
	Result.Insert("NotificationTypeInGroup");
	Result.Insert("Replace", False);
	Result.Insert("DeliveryDeferral", 0);
	Result.Insert("LogEventOnDeliveryDeferral", "");
	Result.Insert("LogCommentOnDeliveryDeferral", "");
	Result.Insert("ShouldWriteUnconditionally", False);
	
	Return Result;
	
EndFunction

// Parameters:
//  NameOfAlert  - See SendServerNotification.NameOfAlert
//  Result      - See SendServerNotification.Result
//  Recipients       - See SendServerNotification.Recipients
//  SendImmediately - See SendServerNotification.SendImmediately
//
//  AdditionalParameters - See AdditionalSendingParameters
//
Procedure SendServerNotificationWithGroupID(NameOfAlert, Result, Recipients,
			SendImmediately, AdditionalSendingParameters = Undefined) Export
	
	If Recipients <> Undefined And Not ValueIsFilled(Recipients) Then
		Return;
	EndIf;
	
	NotificationContent = NotificationNewContent();
	NotificationContent.NameOfAlert = NameOfAlert;
	NotificationContent.Result     = Result;
	NotificationContent.Recipients      = Recipients;
	
	If TimeConsumingOperations.ShouldSkipNotification(NotificationContent) Then
		Return;
	EndIf;
	
	If SendImmediately
	   And ServerNotificationsInternalCached.IsSessionSendServerNotificationsToClients() Then
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trong thủ tục %1 không thể chỉ ra giá trị %2 đối với tham số %3
			           |khi gọi ra từ thủ tục %4.';
			           |ru = 'В процедуре %1 недопустимо указывать значение %2 для параметра %3
			           |при вызове из процедур %4.';
			           |en = 'In procedure %1, you cannot specify value %2 for parameter %3
			           |when calling from procedures %4.'; fa = 'In procedure %1, you cannot specify value %2 for parameter %3
			           |when calling from procedures %4.';
			           |it = 'Non è consentito indicare il valore %2 per il parametro %3
			           | nella procedura %1 per la chiamata dalle procedure %4.';
			           |pl = 'W procedurze %1 nie można podawać wartości %2 dla parametru %3
			           |podczas wywołania z procedur %4.';
			           |tr = '%1 prosedüründe %3 parametresi için %4 prosedürlerinden çağırırken
			           |%2 değerinin belirtilmesi yasaktır.'"),
			"ServerNotifications.SendServerNotification",
			"True",
			"SendImmediately",
			"OnSendServerNotification");
		Raise ErrorText;
	EndIf;
	
	NotificationID = Lower(New UUID);
	AddedOn = CurrentSessionDate();
	DateAddedMilliseconds = Milliseconds(AddedOn);
	AdditionalParameters = ?(AdditionalSendingParameters = Undefined,
		AdditionalSendingParameters(), AdditionalSendingParameters);
	
	DeliveryDeferral = AdditionalParameters.DeliveryDeferral;
	
	If AdditionalParameters.Replace Then
		DeleteLastUndeliveredNotification(AdditionalParameters.GroupID,
			AdditionalParameters.NotificationTypeInGroup, DeliveryDeferral,
			AddedOn, DateAddedMilliseconds);
	EndIf;
	
	If Not ValueIsFilled(Recipients)
	 Or Recipients.Count() > 27 Then
		AddresseesIDs = "";
	Else
		List = New Array;
		For Each KeyAndValue In Recipients Do
			List.Add(Lower(KeyAndValue.Key));
		EndDo;
		AddresseesIDs = StrConcat(List, Chars.LF);
	EndIf;
	
	RecordSet = ServiceRecordSet(InformationRegisters.SentServerNotifications);
	RecordSet.Filter.NotificationID.Set(NotificationID);
	NewRecord = RecordSet.Add();
	NewRecord.NotificationID = NotificationID;
	NewRecord.AddedOn = AddedOn;
	NewRecord.DateAddedMilliseconds = DateAddedMilliseconds;
	NewRecord.Recipients = AddresseesIDs;
	NewRecord.NotificationContent = New ValueStorage(NotificationContent, New Deflation(9));
	NewRecord.GroupID = Lower(AdditionalParameters.GroupID);
	NewRecord.NotificationTypeInGroup = Lower(AdditionalParameters.NotificationTypeInGroup);
	
	If Not Common.SeparatedDataUsageAvailable() Then
		RecordSet.Filter.DataAreaAuxiliaryData.Set(0);
		NewRecord.DataAreaAuxiliaryData = 0;
	EndIf;
	
	AreClientNotificationsAvailable = ServerNotificationsInternalCached.AreClientNotificationsAvailable();
	RunDeferredDelivery = False;
	
	If ValueIsFilled(DeliveryDeferral) Then
		RunDeferredDelivery = True;
		
		If DeliveryDeferral > 5 Then
			NewRecord.DeferralOfWritingToCollaborationSystem = 5;
		Else
			NewRecord.DeferralOfWritingToCollaborationSystem = DeliveryDeferral;
		EndIf;
		
	ElsIf SendImmediately
	        And (AreClientNotificationsAvailable
	           Or IsCurrentUserRegisteredInInteractionSystem()) Then
		
		If SendMessageImmediately(NotificationID, AddedOn, NotificationContent) Then
			NewRecord.CollaborationSystemRecordDate = CurrentSessionDate();
			NewRecord.DateWrittenToCollaborationSystemMilliseconds = Milliseconds();
		EndIf;
		
	ElsIf SendImmediately Then
		NewRecord.DeferralOfWritingToCollaborationSystem = 0.1;
	EndIf;
	
	If ValueIsFilled(NewRecord.DeferralOfWritingToCollaborationSystem)
	   And Not AreClientNotificationsAvailable
	   And Not CollaborationSystemConnected() Then
		
		NewRecord.DeferralOfWritingToCollaborationSystem = 0;
		RunDeferredDelivery = False;
	EndIf;
	
	If Not AdditionalParameters.Replace
	   And AreClientNotificationsAvailable
	   And Not AdditionalParameters.ShouldWriteUnconditionally
	   And ValueIsFilled(NewRecord.CollaborationSystemRecordDate) Then
		
		Return;
	EndIf;
	
	RecordSet.Write();
	
	If RunDeferredDelivery Then
		Launched = False;
		StartDeliverDeferredServerNotifications(Launched);
		If Launched And ValueIsFilled(AdditionalParameters.LogEventOnDeliveryDeferral) Then
			Try
				Raise NStr("vi = 'Ngăn xếp lần gọi:';
							|ru = 'Стек вызовов:';
							|en = 'Call stack:'; fa = 'Call stack:';
							|it = 'Стек вызовов:';
							|pl = 'Call stack:';
							|tr = 'Çağrı yığını:'");
			Except
				CallsStack = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			EndTry;
			Comment = AdditionalParameters.LogCommentOnDeliveryDeferral;
			Comment = Comment + ?(ValueIsFilled(Comment), Chars.LF, "") + CallsStack;
			WriteLogEvent(AdditionalParameters.LogEventOnDeliveryDeferral,
				EventLogLevel.Information,,, Comment);
		EndIf;
	EndIf;
	
EndProcedure

// Intended for the SendServerNotificationWithGroupID procedure.
Procedure DeleteLastUndeliveredNotification(GroupID, NotificationTypeInGroup,
			DeliveryDeferral, AddedOn, DateAddedMilliseconds)
	
	Query = New Query;
	Query.SetParameter("GroupID",  Lower(GroupID));
	Query.SetParameter("NotificationTypeInGroup", Lower(NotificationTypeInGroup));
	Query.Text =
	"SELECT TOP 1
	|	SentServerNotifications.NotificationID AS NotificationID,
	|	SentServerNotifications.AddedOn AS AddedOn,
	|	SentServerNotifications.DateAddedMilliseconds AS DateAddedMilliseconds,
	|	SentServerNotifications.DeferralOfWritingToCollaborationSystem AS DeferralOfWritingToCollaborationSystem,
	|	SentServerNotifications.CollaborationSystemRecordDate AS CollaborationSystemRecordDate,
	|	SentServerNotifications.DateWrittenToCollaborationSystemMilliseconds AS DateWrittenToCollaborationSystemMilliseconds
	|FROM
	|	InformationRegister.SentServerNotifications AS SentServerNotifications
	|WHERE
	|	SentServerNotifications.GroupID = &GroupID
	|	AND SentServerNotifications.NotificationTypeInGroup = &NotificationTypeInGroup
	|
	|ORDER BY
	|	SentServerNotifications.AddedOn DESC,
	|	SentServerNotifications.DateAddedMilliseconds DESC";
	
	Selection = Query.Execute().Select();
	If Not Selection.Next() Then
		DeliveryDeferral = 0;
		Return;
	EndIf;
	
	If ValueIsFilled(Selection.CollaborationSystemRecordDate) Then
		TimePassed = AddedOn - Selection.CollaborationSystemRecordDate
			+ (DateAddedMilliseconds - Selection.DateWrittenToCollaborationSystemMilliseconds) / 1000;
	Else
		TimePassed = AddedOn - Selection.AddedOn
			+ (DateAddedMilliseconds - Selection.DateAddedMilliseconds) / 1000;
		If DeliveryDeferral > Selection.DeferralOfWritingToCollaborationSystem Then
			DeliveryDeferral = Selection.DeferralOfWritingToCollaborationSystem;
		EndIf;
	EndIf;
	TimePassed = Round(TimePassed, 1, RoundMode.Round15as20);
	DeliveryDeferral = DeliveryDeferral - TimePassed;
	
	If DeliveryDeferral < 0 Then
		DeliveryDeferral = 0;
	EndIf;
	
	If ValueIsFilled(Selection.CollaborationSystemRecordDate) Then
		Return;
	EndIf;
	
	RecordSet = ServiceRecordSet(InformationRegisters.SentServerNotifications);
	RecordSet.Filter.NotificationID.Set(Selection.NotificationID);
	RecordSet.Write();
	
EndProcedure

// Intended for the SendServerNotificationWithGroupID procedure.
Function SendMessageImmediately(NotificationID, AddedOn, NotificationContent)
	
	Data = MessageNewData();
	Data.NameOfAlert           = NotificationContent.NameOfAlert;
	Data.Result               = NotificationContent.Result;
	Data.Recipients                = NotificationContent.Recipients;
	Data.NotificationID = NotificationID;
	Data.AddedOn          = AddedOn;
	Data.WasSentFromQueue     = False;
	
	If ServerNotificationsInternalCached.AreClientNotificationsAvailable() Then
		Return SendNotification(Data);
	EndIf;
	
	If ValueIsFilled(Data.Recipients) And Data.Recipients.Count() = 1 Then
		For Each KeyAndValue In Data.Recipients Do
			Break;
		EndDo;
		ConversationID = PersonalChatID(KeyAndValue.Key);
	Else
		ConversationID = GlobalChatID();
	EndIf;
	
	Return SendMessage(Data, ConversationID);
	
EndFunction

Function Milliseconds(AddedOn = Undefined)
	
	DateInMilliseconds = CurrentUniversalDateInMilliseconds();
	
	Result = DateInMilliseconds - Int(DateInMilliseconds/1000)*1000;
	
	If AddedOn = Undefined Then
		Return Result;
	EndIf;
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	Properties = New Structure(SessionParameters.TimeConsumingOperations);
	
	If AddedOn < Properties.AddedOn
	   And Properties.AddedOn - AddedOn < 5 Then
		
		AddedOn = Properties.AddedOn;
		Result = Properties.DateAddedMilliseconds;
	EndIf;
	
	If AddedOn = Properties.AddedOn
	   And Result <= Properties.DateAddedMilliseconds Then
		
		Result = Properties.DateAddedMilliseconds + 1;
		If Result > 999 Then
			Result = 0;
			AddedOn = AddedOn + 1;
		EndIf;
	EndIf;
	
	Properties.AddedOn = AddedOn;
	Properties.DateAddedMilliseconds = Result;
	
	SessionParameters.TimeConsumingOperations = New FixedStructure(Properties);
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
	Return Result;
	
EndFunction

// Parameters:
//  GroupID  - UUID - ID of the notification type.
//                           Used to search for records in the register.
//
//  NotificationTypeInGroup - UUID - ID of the notification type in the notification group.
//                           Used to search for records in the register.
//
//  LastAlert  - See NewServerNotificationToClient
//
// Returns:
//  Array of See NewServerNotificationToClient
//
Function ServerNotificationForClient(GroupID, NotificationTypeInGroup,
			LastAlert = Undefined) Export
	
	If LastAlert = Undefined Then
		LastAlert = NewServerNotificationToClient();
	EndIf;
	
	Query = New Query;
	Query.SetParameter("GroupID",        Lower(GroupID));
	Query.SetParameter("NotificationTypeInGroup",       Lower(NotificationTypeInGroup));
	Query.SetParameter("AddedOn",             LastAlert.AddedOn);
	Query.SetParameter("DateAddedMilliseconds", LastAlert.DateAddedMilliseconds);
	Query.SetParameter("NotificationID",    LastAlert.NotificationID);
	Query.Text =
	"SELECT
	|	SentServerNotifications.NotificationID AS NotificationID,
	|	SentServerNotifications.NotificationContent AS NotificationContent,
	|	SentServerNotifications.AddedOn AS AddedOn,
	|	SentServerNotifications.DateAddedMilliseconds AS DateAddedMilliseconds
	|FROM
	|	InformationRegister.SentServerNotifications AS SentServerNotifications
	|WHERE
	|	SentServerNotifications.GroupID = &GroupID
	|	AND SentServerNotifications.NotificationTypeInGroup = &NotificationTypeInGroup
	|	AND SentServerNotifications.NotificationID <> &NotificationID
	|	AND (SentServerNotifications.AddedOn > &AddedOn
	|			OR SentServerNotifications.AddedOn = &AddedOn
	|				AND SentServerNotifications.DateAddedMilliseconds > &DateAddedMilliseconds)
	|
	|ORDER BY
	|	SentServerNotifications.AddedOn,
	|	SentServerNotifications.DateAddedMilliseconds";
	
	Selection = Query.Execute().Select();
	Result = New Array;
	
	While Selection.Next() Do
		Notification = NewServerNotificationToClient();
		FillPropertyValues(Notification, Selection);
		Notification.Content = NotificationNewContent(Selection.NotificationContent);
		Result.Add(Notification);
	EndDo;
	
	Return Result;
	
EndFunction

// Returns:
//  Structure:
//   * NotificationID - String
//   * Content - See NotificationNewContent
//   * AddedOn - Date
//   * DateAddedMilliseconds - Number
//
Function NewServerNotificationToClient()
	
	Result = New Structure;
	Result.Insert("NotificationID", "");
	Result.Insert("Content", Undefined);
	Result.Insert("AddedOn", '00010101');
	Result.Insert("DateAddedMilliseconds", 0);
	
	Return Result;
	
EndFunction

// Parameters:
//   Storage - Undefined
//             - ValueStorage
//
// Returns:
//  Structure:
//   * NameOfAlert - See SendServerNotification.NameOfAlert
//   * Result     - See SendServerNotification.Result
//   * Recipients      - See SendServerNotification.Recipients
//
Function NotificationNewContent(Storage = Undefined)
	
	Content = New Structure;
	Content.Insert("NameOfAlert", "");
	Content.Insert("Result");
	Content.Insert("Recipients", New Map);
	
	If TypeOf(Storage) <> Type("ValueStorage") Then
		Return Content;
	EndIf;
	
	CurrentContent = Storage.Get();
	If TypeOf(CurrentContent) = Type("Structure") Then
		FillPropertyValues(Content, CurrentContent);
	EndIf;
	
	Return Content;
	
EndFunction

// Scheduled job handler.
Procedure SendServerNotificationsToClients() Export
	
	Common.OnStartExecuteScheduledJob(
		Metadata.ScheduledJobs.SendServerNotificationsToClients);
	
	SetPrivilegedMode(True);
	
	If Not Common.SeparatedDataUsageAvailable() Then
		SetUsageOfJobSendServerNotificationsToClients(False);
		Return;
	EndIf;
	
	If IsAllSessionSleeping() Then
		SendServerNotification(NameOfNotificationAllSessionsSleepingJobDisabled(), Undefined, Undefined);
		SetUsageOfJobSendServerNotificationsToClients(False);
		Return;
	EndIf;
	
	SendStatus = SendStatusOnBackgroundJobStart();
	If SendStatus <> Undefined Then
		MaxIntervalByUser = New Map;
		PrepareServerNotifications(SendStatus, MaxIntervalByUser);
		SendPreparedServerNotifications(SendStatus, MaxIntervalByUser);
		UpdateJobSendServerNotificationsToClientsIfNoNotifications(
			SendStatus.MinCheckInterval);
	EndIf;
	
	SetPrivilegedMode(False);
	
EndProcedure

// Common server call handler.
//
// Parameters:
//  Parameters - See ServerNotificationsClient.CommonServerCallNewParameters
//
// Returns:
//  Structure:
//   * ServerNotifications - Array of Structure:
//      ** NameOfAlert - See SendServerNotification.NameOfAlert
//      ** Result     - See SendServerNotification.Result
//   * LastNotificationDate - Date
//   * MinCheckInterval - Number
//   * AdditionalResults - Map - Contains the parameters inserted in the procedure
//       CommonOverridable.OnReceiptRecurringClientDataOnServer.
//   * CollaborationSystemConnected - Boolean
//   * ShouldRegisterIndicators - Boolean
//
Function SessionUndeliveredServerNotifications(Val Parameters) Export
	
	CommonStartTime = CurrentUniversalDateInMilliseconds();
	ShouldRegisterIndicators = CommonClientServer.StructureProperty(Parameters,
		"ShouldRegisterIndicators", False);
	Indicators = ?(ShouldRegisterIndicators, New Array, Undefined);
	
	If Parameters.Property("MessagesForEventLog") Then
		StartMoment = CurrentUniversalDateInMilliseconds();
		EventLog.WriteEventsToEventLog(Parameters.MessagesForEventLog);
		AddMainIndicator(Indicators, StartMoment,
			"EventLog.WriteEventsToEventLog");
	EndIf;
	
	AdditionalResults = New Map;
	If Indicators <> Undefined Then
		AdditionalResults.Insert(NestedIndicatorsParameterName(), New Array);
	EndIf;
	AdditionalParameters = CommonClientServer.StructureProperty(Parameters,
		"AdditionalParameters", New Map);
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	Try
		TimeConsumingOperations.OnReceiptRecurringClientDataOnServer(
			AdditionalParameters, AdditionalResults);
	Except
		HandleError(ErrorInfo());
	EndTry;
	AddMainIndicator(Indicators, StartMoment,
		"TimeConsumingOperations.OnReceiptRecurringClientDataOnServer");
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	SetPrivilegedMode(True);
	ServiceAdministratorSession = ServiceAdministratorSession();
	SetPrivilegedMode(False);
	AddMainIndicator(Indicators, StartMoment,
		"ServerNotifications.ServiceAdministratorSession");
	
	Result = New Structure;
	ShouldSendDataRecurrently = Parameters.Property("ShouldSendDataRecurrently");
	IsRecurringDataSendEnabled = ShouldSendDataRecurrently
		And Parameters.ShouldSendDataRecurrently;
	
	If ShouldSendDataRecurrently Then
		If IsRecurringDataSendEnabled Then
			StartMoment = CurrentUniversalDateInMilliseconds();
			Try
				SSLSubsystemsIntegration.OnReceiptRecurringClientDataOnServer(
					AdditionalParameters, AdditionalResults);
			Except
				HandleError(ErrorInfo());
			EndTry;
			AddMainIndicator(Indicators, StartMoment,
				"SSLSubsystemsIntegration.OnReceiptRecurringClientDataOnServer",
				AdditionalResults);
			
			StartMoment = CurrentUniversalDateInMilliseconds();
			Try
				CommonOverridable.OnReceiptRecurringClientDataOnServer(
					AdditionalParameters, AdditionalResults);
			Except
				HandleError(ErrorInfo());
			EndTry;
			AddMainIndicator(Indicators, StartMoment,
				"CommonOverridable.OnReceiptRecurringClientDataOnServer",
				AdditionalResults);
		EndIf;
		
		If Not ServiceAdministratorSession Then
			StartMoment = CurrentUniversalDateInMilliseconds();
			Try
				If Common.SubsystemExists("StandardSubsystems.UsersSessions") Then
					ModuleIBConnections = Common.CommonModule("IBConnections");
					ModuleIBConnections.OnReceiptRecurringClientDataOnServer(
						AdditionalParameters, AdditionalResults);
				EndIf;
			Except
				HandleError(ErrorInfo());
			EndTry;
			AddMainIndicator(Indicators, StartMoment,
				"IBConnections.OnReceiptRecurringClientDataOnServer");
			
			ChatsParametersKeyName = "StandardSubsystems.Core.ServerNotifications.ChatsIDs";
			PopulateChatsIDs = AdditionalParameters.Get(ChatsParametersKeyName) <> Undefined;
			
			If PopulateChatsIDs Then
				StartMoment = CurrentUniversalDateInMilliseconds();
				CollaborationSystemConnected = CollaborationSystemConnected();
				Result.Insert("CollaborationSystemConnected", CollaborationSystemConnected);
				AddMainIndicator(Indicators, StartMoment,
					"ServerNotifications.CollaborationSystemConnected");
			EndIf;
			
			If PopulateChatsIDs
			   And CollaborationSystemConnected Then
				
				StartMoment = CurrentUniversalDateInMilliseconds();
				Try
					AdditionalResults.Insert(ChatsParametersKeyName, ChatsIDs());
				Except
					HandleError(ErrorInfo());
				EndTry;
				AddMainIndicator(Indicators, StartMoment,
					"ServerNotifications.ChatsIDs");
			EndIf;
		Else
			ParameterName = "StandardSubsystems.Core.ServerNotifications.RemovingOutdatedAlerts";
			If AdditionalParameters.Get(ParameterName) <> Undefined Then
				StartMoment = CurrentUniversalDateInMilliseconds();
				Try
					DeleteOutdatedNotifications();
				Except
					HandleError(ErrorInfo());
				EndTry;
				AddMainIndicator(Indicators, StartMoment,
					"ServerNotifications.DeleteOutdatedNotifications");
			EndIf;
		EndIf;
	EndIf;
	
	SetPrivilegedMode(True);
	
	NewSendDateOfLastNotification = Parameters.LastNotificationDate;
	If Not ServiceAdministratorSession Then
		StartMoment = CurrentUniversalDateInMilliseconds();
		SendStatus = ServerNotificationsSendStatus();
		AddMainIndicator(Indicators, StartMoment,
			"ServerNotifications.ServerNotificationsSendStatus");
		
		If NewSendDateOfLastNotification < SendStatus.LastCheckDate Then
			NewSendDateOfLastNotification = SendStatus.LastCheckDate;
		EndIf;
		If ValueIsFilled(SendStatus.MinCheckInterval) Then
			Result.Insert("MinCheckInterval", SendStatus.MinCheckInterval);
		EndIf;
	EndIf;
	
	IBUserID = InfoBaseUsers.CurrentUser().UUID;
	ThisSessionKey = SessionKey();
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	Selection = NewServerNotifications(Parameters.LastNotificationDate);
	AddMainIndicator(Indicators, StartMoment,
		"ServerNotifications.NewServerNotifications");
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	NameOfNotificationAllSessionsSleepingJobDisabled = NameOfNotificationAllSessionsSleepingJobDisabled();
	NewServerNotifications = New Array;
	CurrentSessionDate = CurrentSessionDate();
	While Selection.Next() Do
		Storage = Selection.NotificationContent;
		Content = NotificationNewContent(Storage);
		DateNotificationWasAdded = Selection.AddedOn;
		If DateNotificationWasAdded > CurrentSessionDate Then
			DateNotificationWasAdded = NewSendDateOfLastNotification;
		EndIf;
		If ValueIsFilled(Content.NameOfAlert) Then
			If Content.NameOfAlert = NameOfNotificationAllSessionsSleepingJobDisabled Then
				If Not ServiceAdministratorSession Then
					Try
						SetUsageOfJobSendServerNotificationsToClients(True);
						DeleteServerNotification(Selection.NotificationID);
					Except
						HandleError(ErrorInfo());
					EndTry;
				EndIf;
				Continue;
			EndIf;
			If TypeOf(Content.Recipients) = Type("Map") Then
				SessionsKeys = Content.Recipients.Get(IBUserID);
				If TypeOf(SessionsKeys) <> Type("Array")
				 Or SessionsKeys.Find(ThisSessionKey) = Undefined
				   And SessionsKeys.Find("*") = Undefined Then
					Continue;
				EndIf;
			EndIf;
			Data = MessageNewData();
			Data.NameOfAlert           = Content.NameOfAlert;
			Data.Result               = Content.Result;
			Data.NotificationID = Selection.NotificationID;
			Data.AddedOn          = DateNotificationWasAdded;
			If Not TimeConsumingOperations.ShouldSkipNotification(Data) Then
				NewServerNotifications.Add(Data);
			EndIf;
		EndIf;
		NewSendDateOfLastNotification = DateNotificationWasAdded;
	EndDo;
	If ValueIsFilled(NewServerNotifications) Then
		Result.Insert("ServerNotifications", NewServerNotifications);
	EndIf;
	AddMainIndicator(Indicators, StartMoment,
		"ServerNotifications.NewServerNotifications.Selection.Next");
	
	If ValueIsFilled(NewSendDateOfLastNotification) Then
		Result.Insert("LastNotificationDate", NewSendDateOfLastNotification);
	EndIf;
	
	If ValueIsFilled(AdditionalResults) Then
		Result.Insert("AdditionalResults", AdditionalResults);
	EndIf;
	
	SetPrivilegedMode(False);
	
	AddMainIndicator(Indicators, CommonStartTime,
		"ServerNotifications.SessionUndeliveredServerNotifications",
		AdditionalResults, True);
	
	If ShouldRegisterIndicators Then
		Result.Insert("Indicators", Indicators);
	EndIf;
	
	Return Result;
	
EndFunction

Procedure AddMainIndicator(Indicators, StartMoment, ProcedureName,
			AdditionalResults = Undefined, Shared = False)
	
	If Indicators = Undefined Then
		Return;
	EndIf;
	
	Duration = CurrentUniversalDateInMilliseconds() - StartMoment;
	If Not Shared And Not ValueIsFilled(Duration) Then
		Return;
	EndIf;
	
	Text = Format(Duration / 1000, "ND=6; NFD=3; NZ=000,000; NLZ=") + " " + ProcedureName;
	
	If Shared Then
		Indicators.Insert(0, "    " + Text);
		AdditionalResults.Delete(NestedIndicatorsParameterName());
	Else
		Indicators.Add("      " + Text);
	EndIf;
	
	If AdditionalResults = Undefined Then
		Return;
	EndIf;
	
	NestedIndicators = AdditionalResults.Get(NestedIndicatorsParameterName());
	If TypeOf(NestedIndicators) <> Type("Array") Then
		Return;
	EndIf;
	
	For Each NestedIndicator In NestedIndicators Do
		Indicators.Add("  " + NestedIndicator);
	EndDo;
	NestedIndicators.Clear();
	
EndProcedure

Function NestedIndicatorsParameterName()
	Return "StandardSubsystems.Core.ServerNotifications.Indicators";
EndFunction

Function RegisterServerNotificationsIndicators()
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	Return Constants.RegisterServerNotificationsIndicators.Get();
	
EndFunction

Procedure RegisterServerNotificationIndicatorsOnConstantChange(DoRegister) Export
	
	SendServerNotification(
		"StandardSubsystems.Core.ServerNotifications.ShouldRegisterIndicators",
		DoRegister, Undefined, True);
	
EndProcedure

Procedure PrepareServerNotifications(SendStatus, MaxIntervalByUser = Undefined)
	
	DeleteOutdatedNotifications();
	
	SendStatus.LastCheckDate = CurrentSessionDate();
	SendStatus.MinCheckInterval = 60*20;
	
	ActiveSessionsByKeys = New Map;
	Sessions = GetInfoBaseSessions();
	For Each Session In Sessions Do
		ActiveSessionsByKeys.Insert(SessionKey(Session), Session);
	EndDo;
	
	RecurringNotifications = PeriodicServerNotifications(MaxIntervalByUser,
		ActiveSessionsByKeys);
	
	For Each KeyAndValue In RecurringNotifications Do
		NameOfAlert = KeyAndValue.Key;
		Notification    = KeyAndValue.Value;
		If SendStatus.MinCheckInterval > Notification.VerificationPeriod Then
			SendStatus.MinCheckInterval = Notification.VerificationPeriod;
		EndIf;
		CheckDate = SendStatus.CheckDatesByNotificationNames.Get(NameOfAlert);
		CurrentSessionDate = CurrentSessionDate();
		If TypeOf(CheckDate) = Type("Date")
		   And CurrentSessionDate >= CheckDate
		   And CurrentSessionDate < CheckDate + Notification.VerificationPeriod Then
			Continue;
		EndIf;
		SendStatus.CheckDatesByNotificationNames.Insert(NameOfAlert, CurrentSessionDate);
		If Metadata.CommonModules.Find(Notification.NotificationSendModuleName) = Undefined Then
			Continue;
		EndIf;
		SendingModule = Common.CommonModule(Notification.NotificationSendModuleName);
		If SendingModule = UsersInternal Then
			ProcedureParameters = New Structure;
			ProcedureParameters.Insert("ParametersVariants", KeyAndValue.Value.ParametersVariants);
			ProcedureParameters.Insert("ActiveSessionsByKeys", ActiveSessionsByKeys);
		Else
			ProcedureParameters = KeyAndValue.Value.ParametersVariants;
		EndIf;
		Try
			SendingModule.OnSendServerNotification(NameOfAlert, ProcedureParameters);
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
				Notification.NotificationSendModuleName + ".OnSendServerNotification",
				ErrorProcessing.DetailErrorDescription(ErrorInfo));
			WriteLogEvent(
				NStr("vi = 'Thông báo từ máy chủ.Lỗi nhiệm vụ nền';
					|ru = 'Серверные оповещения.Ошибка работы фонового задания';
					|en = 'Server notifications.Background job error'; fa = 'Server notifications.Background job error';
					|it = 'Avvisi server. Errore di funzionamento del compito in background';
					|pl = 'Powiadomienia serwerowe.Błąd pracy zadania w tle';
					|tr = 'Sunucu bildirimleri.Arka plan işi hatası'",
					Common.DefaultLanguageCode()),
				EventLogLevel.Error,,, ErrorText);
		EndTry;
	EndDo;
	
	ReviseMinCheckInterval(SendStatus.MinCheckInterval);
	
	ShouldRegisterIndicators = RegisterServerNotificationsIndicators();
	If SendStatus.ShouldRegisterIndicators <> ShouldRegisterIndicators Then
		SendServerNotification(
			"StandardSubsystems.Core.ServerNotifications.ShouldRegisterIndicators",
			ShouldRegisterIndicators, Undefined);
		SendStatus.ShouldRegisterIndicators = ShouldRegisterIndicators;
	EndIf;
	
	CollaborationSystemConnected = CollaborationSystemConnected();
	If SendStatus.CollaborationSystemConnected <> CollaborationSystemConnected Then
		SendServerNotification(
			"StandardSubsystems.Core.ServerNotifications.CollaborationSystemConnected",
			CollaborationSystemConnected, Undefined);
		SendStatus.CollaborationSystemConnected = CollaborationSystemConnected;
	EndIf;
	
	UpdateSendStatus(SendStatus,
		"LastCheckDate, CheckDatesByNotificationNames, MinCheckInterval,
		|CollaborationSystemConnected, ShouldRegisterIndicators");
	
EndProcedure

// Returns:
//   See CommonOverridable.OnAddServerNotifications.Notifications
//
Function AddedSessionNotifications()
	
	Notifications = New Map;
	TimeConsumingOperations.OnAddServerNotifications(Notifications);
	
	If Not ServiceAdministratorSession() Then
		SSLSubsystemsIntegration.OnAddServerNotifications(Notifications);
		CommonOverridable.OnAddServerNotifications(Notifications);
	EndIf;
	
	Return Notifications;
	
EndFunction

// Parameters:
//  RecurringNotifications - See CommonOverridable.OnAddServerNotifications.Notifications
//
// Returns:
//  Map of KeyAndValue:
//   ** Value -
//   ** Value - See ServerNotificationToSave
//
Function RepeatedNotificationToSave(RecurringNotifications)
	
	Result = New Map;
	For Each KeyAndValue In RecurringNotifications Do
		Result.Insert(KeyAndValue.Key,
			ServerNotificationToSave(KeyAndValue.Value));
	EndDo;
	
	Return Result;
	
EndFunction

// Parameters:
//  Notification - See NewServerNotification
//
// Returns:
//  Structure:
//   * NotificationSendModuleName - String - See NewServerNotification.NotificationSendModuleName.
//   * Parameters         - Arbitrary - See NewServerNotification.Parameters.
//                           If the property value is "Undefined", it does not exist.
//
//   * VerificationPeriod    - Number - See NewServerNotification.VerificationPeriod.
//                           If "20*60" is passed, the property does not exist.
//
Function ServerNotificationToSave(Notification)
	
	Result = New Structure;
	Result.Insert("NotificationSendModuleName", Notification.NotificationSendModuleName);
	
	If Notification.Parameters <> Undefined Then
		Result.Insert("Parameters", Notification.Parameters);
	EndIf;
	
	If Notification.VerificationPeriod <> 20*60 Then
		Result.Insert("VerificationPeriod", Notification.VerificationPeriod);
	EndIf;
	
	Return Result;
	
EndFunction

Procedure SendPreparedServerNotifications(SendStatus, MaxIntervalByUser)
	
	AreClientNotificationsAvailable = ServerNotificationsInternalCached.AreClientNotificationsAvailable();
	SendingAvailable = AreClientNotificationsAvailable;
	
	If Not AreClientNotificationsAvailable
	   And IsCurrentUserRegisteredInInteractionSystem() Then
		
		GlobalChatID = GlobalChatID();
		If GlobalChatID <> Undefined Then
			CleanUpObsoleteMessages(SendStatus);
			SendingAvailable = True;
		EndIf;
	EndIf;
	
	LastNotificationDate = SendStatus.LastCheckDate;
	IdsOfRecentAlerts = New Array;
	
	Selection = NewServerNotifications(?(ValueIsFilled(SendStatus.FailedNotificationDate),
		SendStatus.FailedNotificationDate, SendStatus.LastNotificationDate), False);
	
	Context = New Structure;
	Context.Insert("GlobalChatID", GlobalChatID);
	Context.Insert("PersonalChatsIDs", New Map);
	Context.Insert("FailedNotificationDate", '00010101');
	Context.Insert("FailedNotificationsDatesByUsers", New Map);
	Context.Insert("SuccessfullNotificationsDatesByUsers", New Map);
	
	CurrentSessionDate = CurrentSessionDate();
	AdjustableServerAlerts = New Array;
	
	While Selection.Next() Do
		Storage = Selection.NotificationContent;
		Content = NotificationNewContent(Storage);
		DateNotificationWasAdded = Selection.AddedOn;
		If DateNotificationWasAdded > CurrentSessionDate Then
			If DateNotificationWasAdded > CurrentSessionDate + 60 Then
				AdjustableServerAlerts.Add(Selection.NotificationID);
			EndIf;
			DateNotificationWasAdded = LastNotificationDate;
		EndIf;
		If SendingAvailable
		   And ValueIsFilled(Content.NameOfAlert)
		   And Selection.Send Then
			
			Data = MessageNewData();
			Data.NameOfAlert           = Content.NameOfAlert;
			Data.Result               = Content.Result;
			Data.NotificationID = Selection.NotificationID;
			Data.AddedOn          = DateNotificationWasAdded;
			
			If TypeOf(Content.Recipients) <> Type("Map") Then
				If Not MessageAlreadyDelivered(SendStatus, Selection, "AllUsers") Then
					Data.Recipients = Undefined;
					Data.Errors = Context.FailedNotificationsDatesByUsers;
					MessageSent = ?(AreClientNotificationsAvailable, SendNotification(Data),
						SendMessage(Data, GlobalChatID));
					If MessageSent Then
						Context.SuccessfullNotificationsDatesByUsers.Insert("AllUsers", CurrentSessionDate());
					Else
						If Context.FailedNotificationsDatesByUsers.Get("AllUsers") = Undefined Then
							Context.FailedNotificationsDatesByUsers.Insert("AllUsers", Data.AddedOn);
						EndIf;
						If Not ValueIsFilled(Context.FailedNotificationDate) Then
							Context.FailedNotificationDate = Data.AddedOn;
						EndIf;
					EndIf;
				EndIf;
			Else
				Recipients = New Map;
				For Each AddresseeDetails In Content.Recipients Do
					If Not MessageAlreadyDelivered(SendStatus, Selection, AddresseeDetails.Key) Then
						Recipients.Insert(AddresseeDetails.Key, AddresseeDetails.Value);
					EndIf;
				EndDo;
				SendTargetedMessage(Data, Recipients, Context);
			EndIf;
		EndIf;
		If LastNotificationDate <> DateNotificationWasAdded Then
			IdsOfRecentAlerts = New Array;
		EndIf;
		LastNotificationDate = DateNotificationWasAdded;
		If Not ValueIsFilled(Context.FailedNotificationDate) Then
			IdsOfRecentAlerts.Add(Selection.NotificationID);
		EndIf;
	EndDo;
	
	If SendingAvailable Then
		NotifyAboutActivity(SendStatus, MaxIntervalByUser, Context);
	EndIf;
	
	If ValueIsFilled(Context.FailedNotificationDate)
	   And Context.FailedNotificationDate < LastNotificationDate - MaxDeliveryRetryIterval() Then
		
		Context.FailedNotificationDate = LastNotificationDate - MaxDeliveryRetryIterval();
	EndIf;
	
	SendStatus.FailedNotificationDate   = Context.FailedNotificationDate;
	SendStatus.LastNotificationDate = LastNotificationDate;
	SendStatus.IdsOfRecentAlerts = IdsOfRecentAlerts;
	SendStatus.FailedNotificationsDatesByUsers = Context.FailedNotificationsDatesByUsers;
	
	UpdateSendStatus(SendStatus,
		"FailedNotificationDate,
		|LastNotificationDate,
		|IdsOfRecentAlerts,
		|LastMessageClearDate,
		|FailedNotificationsDatesByUsers,
		|SuccessfullNotificationsDatesByUsers");
	
	If ValueIsFilled(AdjustableServerAlerts) Then
		FixDateWhenNotificationsWereAdded(AdjustableServerAlerts, LastNotificationDate);
	EndIf;
	
EndProcedure

Procedure SendTargetedMessage(Data, Recipients, Context)
	
	If Recipients.Count() = 0 Then
		Return;
	EndIf;
	
	AreClientNotificationsAvailable = ServerNotificationsInternalCached.AreClientNotificationsAvailable();
	
	If AreClientNotificationsAvailable Or Recipients.Count() > 20 Then
		Data.Recipients = Recipients;
		IdentifyFailedNotificationsDates(Data, Context.FailedNotificationsDatesByUsers);
		MessageSent = ?(AreClientNotificationsAvailable, SendNotification(Data),
			SendMessage(Data, Context.GlobalChatID));
		
		If MessageSent Then
			For Each AddresseeDetails In Recipients Do
				Context.SuccessfullNotificationsDatesByUsers.Insert(AddresseeDetails.Key, CurrentSessionDate());
			EndDo;
		Else
			For Each AddresseeDetails In Recipients Do
				If Context.FailedNotificationsDatesByUsers.Get(AddresseeDetails.Key) = Undefined Then
					Context.FailedNotificationsDatesByUsers.Insert(AddresseeDetails.Key, Data.AddedOn);
				EndIf;
			EndDo;
			If Not ValueIsFilled(Context.FailedNotificationDate) Then
				Context.FailedNotificationDate = Data.AddedOn;
			EndIf;
		EndIf;
	Else
		For Each AddresseeDetails In Recipients Do
			IBUserID = AddresseeDetails.Key;
			Data.Recipients = New Map;
			Data.Recipients.Insert(IBUserID, AddresseeDetails.Value);
			IdentifyFailedNotificationsDates(Data, Context.FailedNotificationsDatesByUsers);
			ConversationID = Context.PersonalChatsIDs.Get(IBUserID);
			If ConversationID = Undefined Then
				ConversationID = PersonalChatID(IBUserID);
			EndIf;
			If SendMessage(Data, ConversationID) Then
				Context.SuccessfullNotificationsDatesByUsers.Insert(IBUserID, CurrentSessionDate());
			Else
				If Context.FailedNotificationsDatesByUsers.Get(IBUserID) = Undefined Then
					Context.FailedNotificationsDatesByUsers.Insert(IBUserID, Data.AddedOn);
				EndIf;
				If Not ValueIsFilled(Context.FailedNotificationDate) Then
					Context.FailedNotificationDate = Data.AddedOn;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

Procedure NotifyAboutActivity(SendStatus, MaxIntervalByUser, Context)
	
	PingAddressees = New Map;
	NextCheckDate = SendStatus.LastCheckDate
		+ SendStatus.MinCheckInterval + 3;
	
	For Each PeriodDetails In MaxIntervalByUser Do
		If Context.FailedNotificationsDatesByUsers.Get("AllUsers") <> Undefined
		 Or Context.FailedNotificationsDatesByUsers.Get(PeriodDetails.Key) <> Undefined Then
			Continue;
		EndIf;
		DateSent = Context.SuccessfullNotificationsDatesByUsers.Get(PeriodDetails.Key);
		CommonSendDate = Context.SuccessfullNotificationsDatesByUsers.Get("AllUsers");
		If DateSent = Undefined Or CommonSendDate <> Undefined And DateSent < CommonSendDate Then
			DateSent = CommonSendDate;
		EndIf;
		If DateSent = Undefined Then
			DateSent = SendStatus.SuccessfullNotificationsDatesByUsers.Get(PeriodDetails.Key);
			CommonSendDate = SendStatus.SuccessfullNotificationsDatesByUsers.Get("AllUsers");
			If DateSent = Undefined Or CommonSendDate <> Undefined And DateSent < CommonSendDate Then
				DateSent = CommonSendDate;
			EndIf;
		EndIf;
		If DateSent = Undefined
		 Or DateSent + PeriodDetails.Value > NextCheckDate Then
			PingAddressees.Insert(PeriodDetails.Key, New Array);
		EndIf;
	EndDo;
	
	If ValueIsFilled(PingAddressees) Then
		Data = MessageNewData();
		Data.NameOfAlert = "NoServerNotifications";
		SendTargetedMessage(Data, PingAddressees, Context);
	EndIf;
	
EndProcedure

Procedure FixDateWhenNotificationsWereAdded(NotificationIds, LastNotificationDate)
	
	DateAddedMilliseconds = 999;
	IndexOf = NotificationIds.Count();
	While IndexOf > 0 Do
		IndexOf = IndexOf - 1;
		NotificationID = NotificationIds[IndexOf];
		
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.SentServerNotifications");
		LockItem.SetValue("NotificationID", NotificationID);
	
		RecordSet = ServiceRecordSet(InformationRegisters.SentServerNotifications);
		RecordSet.Filter.NotificationID.Set(NotificationID);
		
		BeginTransaction();
		Try
			Block.Lock();
			RecordSet.Read();
			If RecordSet.Count() = 1 Then
				RecordSet[0].AddedOn = LastNotificationDate;
				RecordSet[0].DateAddedMilliseconds = DateAddedMilliseconds;
				RecordSet.Write();
			EndIf;
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
		DateAddedMilliseconds = DateAddedMilliseconds - 1;
	EndDo;
	
EndProcedure

// Returns:
//  Structure:
//   * NameOfAlert           - See SendServerNotification.NameOfAlert
//   * Result               - See SendServerNotification.Result
//   * Recipients                - See SendServerNotification.Recipients
//   * NotificationID - String - UUID string.
//   * AddedOn          - Date - Date the notification was added.
//   * Errors - Map of KeyAndValue:
//       ** Key - UUID - infobase user ID.
//       ** Value - Date - Date of the first message failed to send.
//   * WasSentFromQueue - Boolean - If True, the message was sent in its due order
//       (according to the time it was queued). Therefore, you should update the last notification date.
//
Function MessageNewData() Export
	
	Data = New Structure;
	Data.Insert("NameOfAlert", "");
	Data.Insert("Result");
	Data.Insert("Recipients", New Map);
	Data.Insert("NotificationID", "");
	Data.Insert("AddedOn", '00010101');
	Data.Insert("Errors", New Map);
	Data.Insert("WasSentFromQueue", True);
	
	Return Data;
	
EndFunction

Function MessageAlreadyDelivered(SendStatus, Selection, IBUserID)
	
	If ValueIsFilled(Selection.CollaborationSystemRecordDate) Then
		Return True;
	EndIf;
	
	FailedNotificationDate =
		SendStatus.FailedNotificationsDatesByUsers.Get(IBUserID);
	
	If FailedNotificationDate = Undefined Then
		FailedNotificationDate = SendStatus.LastNotificationDate;
	EndIf;
	
	Return Selection.AddedOn < FailedNotificationDate
		Or SendStatus.IdsOfRecentAlerts.Find(Selection.NotificationID) <> Undefined;
	
EndFunction

Procedure IdentifyFailedNotificationsDates(Data, FailedNotificationsDatesByUsers,
			IBUserID = Undefined)
	
	Data.Errors = New Map;
	
	If IBUserID = Undefined Then
		For Each KeyAndValue In FailedNotificationsDatesByUsers Do
			If Data.Recipients.Get(KeyAndValue.Key) <> Undefined Then
				Data.Errors.Insert(KeyAndValue.Key, KeyAndValue.Value);
			EndIf;
		EndDo;
	Else
		FailedNotificationDate = FailedNotificationsDatesByUsers.Get(IBUserID);
		If FailedNotificationDate <> Undefined Then
			Data.Errors.Insert(IBUserID, FailedNotificationDate);
		EndIf;
	EndIf;
	
	FailedNotificationDate = FailedNotificationsDatesByUsers.Get("AllUsers");
	If FailedNotificationDate <> Undefined Then
		Data.Errors.Insert("AllUsers", FailedNotificationDate);
	EndIf;
	
EndProcedure

Function MaxDeliveryRetryIterval()
	
	Return 120;
	
EndFunction

Function NewServerNotifications(LastNotificationDate, OnlyForCurrentUser = True)
	
	Query = New Query;
	Query.SetParameter("LastNotificationDate", LastNotificationDate);
	
	Query.Text =
	"SELECT
	|	SentServerNotifications.NotificationID AS NotificationID,
	|	SentServerNotifications.NotificationContent AS NotificationContent,
	|	SentServerNotifications.AddedOn AS AddedOn,
	|	SentServerNotifications.CollaborationSystemRecordDate AS CollaborationSystemRecordDate,
	|	&Send AS Send
	|FROM
	|	InformationRegister.SentServerNotifications AS SentServerNotifications
	|WHERE
	|	SentServerNotifications.AddedOn >= &LastNotificationDate
	|	AND &Filter
	|
	|ORDER BY
	|	SentServerNotifications.AddedOn,
	|	SentServerNotifications.DateAddedMilliseconds";
	
	SendField = "TRUE";
	FilterCriterion = ?(Common.SeparatedDataUsageAvailable(), "TRUE",
			"SentServerNotifications.DataAreaAuxiliaryData = 0");
	
	If OnlyForCurrentUser Then
		FilterCriterion = FilterCriterion + "
		|AND (SentServerNotifications.Recipients = """"
		|		OR SentServerNotifications.Recipients LIKE &AddresseeSearchTemplate)";
		Query.SetParameter("AddresseeSearchTemplate",
			"%" + Lower(InfoBaseUsers.CurrentUser().UUID) + "%");
	EndIf;
	
	If ServerNotificationsInternalCached.AreClientNotificationsAvailable() Then
		If OnlyForCurrentUser Then
			FilterCriterion = FilterCriterion + "
			|	AND NOT SentServerNotifications.NotificationTypeInGroup IN (&TimeConsumingOperationNotificationKinds)";
		Else
			SendField = "NOT SentServerNotifications.NotificationTypeInGroup IN (&TimeConsumingOperationNotificationKinds)";
		EndIf;
		Query.SetParameter("TimeConsumingOperationNotificationKinds",
			TimeConsumingOperations.TimeConsumingOperationNotificationKinds());
	EndIf;
	
	Query.Text = StrReplace(Query.Text, "&Send", SendField);
	Query.Text = StrReplace(Query.Text, "&Filter", FilterCriterion);
	
	Return Query.Execute().Select();
	
EndFunction

// Returns:
//  Structure:
//   * Parameters - Arbitrary - See NewServerNotification.Parameters.
//   * Recipients - Map of KeyAndValue:
//      ** Key - UUID - infobase user ID.
//      ** Value - Array of See ServerNotifications.SessionKey
//
Function ServerNotificationNewParametersVariant()
	
	ParametersVariant = New Structure;
	ParametersVariant.Insert("Parameters");
	ParametersVariant.Insert("Recipients", New Map);
	
	Return ParametersVariant;
	
EndFunction

Function IsAllSessionSleeping()
	Return False;
EndFunction

// Returns:
//  Map of KeyAndValue:
//   * Key - String - See NewServerNotification.Name
//   * Value - Structure:
//      ** NotificationSendModuleName - String - See NewServerNotification.NotificationSendModuleName
//      ** VerificationPeriod - Number - See NewServerNotification.VerificationPeriod
//      ** ParametersVariants - See StandardSubsystemsServer.OnSendServerNotification.ParametersVariants
//
Function PeriodicServerNotifications(MaxIntervalByUser, ActiveSessionsByKeys)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	PeriodicServerNotifications.SessionKey AS SessionKey,
	|	PeriodicServerNotifications.IBUserID AS IBUserID,
	|	PeriodicServerNotifications.Notifications AS Notifications
	|FROM
	|	InformationRegister.PeriodicServerNotifications AS PeriodicServerNotifications";
	
	Notifications = New Map;
	NotificationParametersVariantsByValueKeys = New Map;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		If ActiveSessionsByKeys.Get(Selection.SessionKey) = Undefined Then
			RecordSet = ServiceRecordSet(InformationRegisters.PeriodicServerNotifications);
			RecordSet.Filter.SessionKey.Set(Selection.SessionKey);
			RecordSet.Write();
			Continue;
		EndIf;
		SessionNotifications = RecurringServerNotificationsAboutSession(Selection.Notifications);
		If Not ValueIsFilled(SessionNotifications) Then
			Continue;
		EndIf;
		For Each KeyAndValue In SessionNotifications Do
			NameOfAlert = KeyAndValue.Key;
			If TypeOf(KeyAndValue.Value) <> Type("Structure") Then
				Continue;
			EndIf;
			Notification = Notifications.Get(NameOfAlert);
			If Notification = Undefined Then
				Notification = New Structure;
				Notification.Insert("NotificationSendModuleName", "");
				Notification.Insert("VerificationPeriod", 20*60);
				FillPropertyValues(Notification, KeyAndValue.Value);
				Notification.Insert("ParametersVariants", New Array);
				Notifications.Insert(NameOfAlert, Notification);
			EndIf;
			NotificationParameters = Undefined;
			KeyAndValue.Value.Property("Parameters", NotificationParameters);
			ParametersVariantsByValueKeys = NotificationParametersVariantsByValueKeys.Get(NameOfAlert);
			If ParametersVariantsByValueKeys = Undefined Then
				ParametersVariantsByValueKeys = New Map;
				NotificationParametersVariantsByValueKeys.Insert(NameOfAlert, ParametersVariantsByValueKeys);
			EndIf;
			ParametersValueKey = ValueToStringInternal(NotificationParameters);
			ParametersVariant = ParametersVariantsByValueKeys.Get(ParametersValueKey);
			If ParametersVariant = Undefined Then
				ParametersVariant = ServerNotificationNewParametersVariant();
				ParametersVariantsByValueKeys.Insert(ParametersValueKey, ParametersVariant);
				ParametersVariant.Parameters = NotificationParameters;
				Notification.ParametersVariants.Add(ParametersVariant);
			EndIf;
			SessionsKeys = ParametersVariant.Recipients.Get(Selection.IBUserID);
			If SessionsKeys = Undefined Then
				SessionsKeys = New Array;
				ParametersVariant.Recipients.Insert(Selection.IBUserID, SessionsKeys);
			EndIf;
			If SessionsKeys.Find(Selection.SessionKey) = Undefined Then
				SessionsKeys.Add(Selection.SessionKey);
			EndIf;
			If MaxIntervalByUser <> Undefined Then
				CurrentPeriod = MaxIntervalByUser.Get(Selection.IBUserID);
				If CurrentPeriod = Undefined
				 Or CurrentPeriod > Notification.VerificationPeriod Then
					MaxIntervalByUser.Insert(Selection.IBUserID,
						Notification.VerificationPeriod);
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	
	Return Notifications;
	
EndFunction

Procedure UpdateJobSendServerNotificationsToClientsIfNoNotifications(MinCheckInterval)
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	TRUE AS TrueValue
	|FROM
	|	InformationRegister.PeriodicServerNotifications AS PeriodicServerNotifications";
	
	IsJobDisabled = False;
	If Query.Execute().IsEmpty() Then
		Block = New DataLock;
		Block.Add("InformationRegister.PeriodicServerNotifications");
		
		BeginTransaction();
		Try
			Block.Lock();
			If Query.Execute().IsEmpty() Then
				ConfigureJobSendServerNotificationsToClients(False);
				IsJobDisabled = True;
			EndIf;
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndIf;
	
	If Not IsJobDisabled Then
		ConfigureJobSendServerNotificationsToClients(True, MinCheckInterval);
	EndIf;
	
EndProcedure

// Parameters:
//  NotificationsStorage - ValueStorage
//
// Returns:
//  Map of KeyAndValue:
//   * Key     - String - See ServerNotifications.NewServerNotification.Name
//   * Value - See ServerNotifications.NewServerNotification
//
Function RecurringServerNotificationsAboutSession(NotificationsStorage)
	
	If TypeOf(NotificationsStorage) <> Type("ValueStorage") Then
		Return New Map;
	EndIf;
	
	Notifications = NotificationsStorage.Get();
	If TypeOf(Notifications) <> Type("Map") Then
		Return New Map;
	EndIf;
	
	Return Notifications;
	
EndFunction

// Returns:
//  Structure:
//   * LastCheckDate - Date
//   * MinCheckInterval - Number
//   * CheckDatesByNotificationNames - Map of KeyAndValue:
//       ** Key     - String - See NewServerNotification.Name
//       ** Value - Date
//   * LastNotificationDate - Date - Date of the last notification sent.
//   * IdsOfRecentAlerts - Array of String - ids of the last
//       alerts with the same date of the last alert.
//   * FailedNotificationDate   - Date - Date of the failed notification.
//   * FailedNotificationsDatesByUsers - Map of KeyAndValue:
//       ** Key     - UUID - infobase user ID.
//       ** Value - Date - Date of the failed notification.
//   * SuccessfullNotificationsDatesByUsers - Map of KeyAndValue:
//       ** Key     - UUID - infobase user ID.
//       ** Value - Date
//   * BackgroundJobIdentifier - UUID
//   * LastMessageClearDate - Date
//   * CollaborationSystemConnected - Boolean
//   * ShouldRegisterIndicators - Boolean
//
Function ServerNotificationsSendStatus()
	
	State = New Structure;
	State.Insert("LastCheckDate", '00010101');
	State.Insert("MinCheckInterval", 0);
	State.Insert("CheckDatesByNotificationNames", New Map);
	State.Insert("LastNotificationDate", '00010101');
	State.Insert("IdsOfRecentAlerts", New Array);
	State.Insert("FailedNotificationDate", '00010101');
	State.Insert("FailedNotificationsDatesByUsers", New Map);
	State.Insert("SuccessfullNotificationsDatesByUsers", New Map);
	State.Insert("BackgroundJobIdentifier",
		CommonClientServer.BlankUUID());
	State.Insert("LastMessageClearDate", '00010101');
	State.Insert("CollaborationSystemConnected", False);
	State.Insert("ShouldRegisterIndicators", False);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ServerNotificationsSendStatus.Value AS Value
	|FROM
	|	Constant.ServerNotificationsSendStatus AS ServerNotificationsSendStatus";
	Selection = Query.Execute().Select();
	Value = ?(Selection.Next(), Selection.Value, Undefined);
	
	If TypeOf(Value) = Type("ValueStorage") Then
		CurrentStatus = Value.Get();
		If TypeOf(CurrentStatus) = Type("Structure") Then
			For Each KeyAndValue In CurrentStatus Do
				If State.Property(KeyAndValue.Key)
				   And TypeOf(State[KeyAndValue.Key]) = TypeOf(KeyAndValue.Value) Then
					State[KeyAndValue.Key] = KeyAndValue.Value;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	CurrentSessionDate = CurrentSessionDate();
	If State.LastCheckDate > CurrentSessionDate Then
		State.LastCheckDate = CurrentSessionDate;
	EndIf;
	If State.LastNotificationDate > CurrentSessionDate Then
		State.LastNotificationDate = CurrentSessionDate;
	EndIf;
	If State.FailedNotificationDate > CurrentSessionDate Then
		State.FailedNotificationDate = CurrentSessionDate;
	EndIf;
	
	Return State;
	
EndFunction

Procedure UpdateSendStatus(NewSendStatus, PropertiesNames)
	
	Block = New DataLock;
	Block.Add("Constant.ServerNotificationsSendStatus");
	BeginTransaction();
	Try
		Block.Lock();
		SendStatus = ServerNotificationsSendStatus();
		If StrFind(PropertiesNames, "SuccessfullNotificationsDatesByUsers") > 0 Then
			NewDates = NewSendStatus.SuccessfullNotificationsDatesByUsers;
			For Each KeyAndValue In SendStatus.SuccessfullNotificationsDatesByUsers Do
				NewDate = NewDates.Get(KeyAndValue.Key);
				If NewDate <> Undefined And NewDate < KeyAndValue.Value Then
					NewDates.Insert(KeyAndValue.Key, NewDate);
				EndIf;
			EndDo;
		EndIf;
		Write = False;
		For Each KeyAndValue In New Structure(PropertiesNames) Do
			PropertyName = KeyAndValue.Key;
			If SendStatus[PropertyName] = NewSendStatus[PropertyName] Then
				Continue;
			EndIf;
			SendStatus[PropertyName] = NewSendStatus[PropertyName];
			Write = True;
		EndDo;
		If Write Then
			ValueManager = ServiceValueManager(Constants.ServerNotificationsSendStatus);
			ValueManager.Value = New ValueStorage(SendStatus, New Deflation(9));
			ValueManager.Write();
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		ErrorInfo = ErrorInfo();
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể thiết lập hằng %1 do nguyên nhân:
			           |%2';
			           |ru = 'Не удалось установить константу %1 по причине:
			           |%2';
			           |en = 'Cannot set constant %1 due to:
			           |%2'; fa = 'Cannot set constant %1 due to:
			           |%2';
			           |it = 'Non è stato possibile impostare la costante %1 a causa di: 
			           |%2';
			           |pl = 'Nie udało się ustawić stałej %1 z powodu:
			           |%2';
			           |tr = '%1 sabiti ayarlanamadı çünkü:
			           |%2'"),
			"ServerNotificationsSendStatus",
			ErrorProcessing.DetailErrorDescription(ErrorInfo));
		WriteLogEvent(
			NStr("vi = 'Thông báo từ máy chủ.Lỗi nhiệm vụ nền';
				|ru = 'Серверные оповещения.Ошибка работы фонового задания';
				|en = 'Server notifications.Background job error'; fa = 'Server notifications.Background job error';
				|it = 'Avvisi server. Errore di funzionamento del compito in background';
				|pl = 'Powiadomienia serwerowe.Błąd pracy zadania w tle';
				|tr = 'Sunucu bildirimleri.Arka plan işi hatası'",
				Common.DefaultLanguageCode()),
			EventLogLevel.Error,,, ErrorText);
	EndTry;
	
EndProcedure

// Returns:
//   See ServerNotificationsSendStatus
//
Function SendStatusOnBackgroundJobStart()
	
	CurrentSession = GetCurrentInfoBaseSession();
	If CurrentSession.ApplicationName <> "BackgroundJob" Then
		Return ServerNotificationsSendStatus();
	EndIf;
	
	CurrentBackgroundJob = CurrentSession.GetBackgroundJob();
	If CurrentBackgroundJob = Undefined Then
		Return ServerNotificationsSendStatus();
	EndIf;
	
	SendStatus = Undefined;
	
	Block = New DataLock;
	Block.Add("Constant.ServerNotificationsSendStatus");
	BeginTransaction();
	Try
		Block.Lock();
		SendStatus = ServerNotificationsSendStatus();
		If SendServerNotificationsToClientsRunning(SendStatus) Then
			SendStatus = Undefined;
		Else
			SendStatus.BackgroundJobIdentifier = CurrentBackgroundJob.UUID;
			ValueManager = ServiceValueManager(Constants.ServerNotificationsSendStatus);
			ValueManager.Value = New ValueStorage(SendStatus, New Deflation(9));
			ValueManager.Write();
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		ErrorInfo = ErrorInfo();
		SendStatus = Undefined;
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể thiết lập hằng %1 do nguyên nhân:
			           |%2';
			           |ru = 'Не удалось установить константу %1 по причине:
			           |%2';
			           |en = 'Cannot set constant %1 due to:
			           |%2'; fa = 'Cannot set constant %1 due to:
			           |%2';
			           |it = 'Non è stato possibile impostare la costante %1 a causa di: 
			           |%2';
			           |pl = 'Nie udało się ustawić stałej %1 z powodu:
			           |%2';
			           |tr = '%1 sabiti ayarlanamadı çünkü:
			           |%2'"),
			"ServerNotificationsSendStatus",
			ErrorProcessing.DetailErrorDescription(ErrorInfo));
		WriteLogEvent(
			NStr("vi = 'Thông báo từ máy chủ.Lỗi khởi động nhiệm vụ nền';
				|ru = 'Серверные оповещения.Ошибка запуска фонового задания';
				|en = 'Server notifications.Background job startup error'; fa = 'Server notifications.Background job startup error';
				|it = 'Avvisi server. Errore di avvio del compito in background';
				|pl = 'Powiadomienia serwerowe.Błąd uruchomienia zadania w tle';
				|tr = 'Sunucu bildirimleri.Arka plan işini başlatma hatası'",
				Common.DefaultLanguageCode()),
			EventLogLevel.Error,,, ErrorText);
	EndTry;
	
	Return SendStatus;
	
EndFunction

Function SendServerNotificationsToClientsRunning(SendStatus)
	
	ActiveBackgroundJob = BackgroundJobs.FindByUUID(
		SendStatus.BackgroundJobIdentifier);
	
	Return ActiveBackgroundJob <> Undefined
	      And ActiveBackgroundJob.State = BackgroundJobState.Active;
	
EndFunction

Procedure DeleteOutdatedNotifications()
	
	Query = New Query;
	Query.SetParameter("TheBoundaryOfObsolescence", CurrentSessionDate() - 60*60);
	Query.Text =
	"SELECT
	|	SentServerNotifications.NotificationID AS NotificationID
	|FROM
	|	InformationRegister.SentServerNotifications AS SentServerNotifications
	|WHERE
	|	SentServerNotifications.AddedOn < &TheBoundaryOfObsolescence
	|	AND &Filter
	|
	|ORDER BY
	|	SentServerNotifications.AddedOn,
	|	SentServerNotifications.DateAddedMilliseconds";
	
	SeparatedDataUsageAvailable = Common.SeparatedDataUsageAvailable();
	
	Query.Text = StrReplace(Query.Text, "&Filter",
		?(SeparatedDataUsageAvailable, "TRUE",
			"SentServerNotifications.DataAreaAuxiliaryData = 0"));
	
	RecordSetIsEmpty = ServiceRecordSet(InformationRegisters.SentServerNotifications);
	If Not SeparatedDataUsageAvailable Then
		RecordSetIsEmpty.Filter.DataAreaAuxiliaryData.Set(0);
	EndIf;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		RecordSetIsEmpty.Filter.NotificationID.Set(Selection.NotificationID);
		RecordSetIsEmpty.Write();
	EndDo;
	
EndProcedure

// Intended for the SendServerNotificationWithGroupID procedure.
Procedure StartDeliverDeferredServerNotifications(Launched = False)
	
	If Not ServerNotificationsInternalCached.AreClientNotificationsAvailable()
	   And Not IsCurrentUserRegisteredInInteractionSystem()
	 Or Common.FileInfobase() // Starting the delivery is pointless as the job will be waiting for a long-running operation job.
	 Or ExclusiveMode() // Starting the delivery is prohibited as all changes within the session will be blocked.
	 Or InfobaseUpdate.InfobaseUpdateRequired()
	 Or IsDeferredServerAlertsDeliveryRunning() Then
		Return;
	EndIf;
	
	CurrentSession = GetCurrentInfoBaseSession();
	JobDescription =
		NStr("vi = 'Tự khởi động';
			|ru = 'Автозапуск';
			|en = 'Autostart'; fa = 'Autostart';
			|it = 'Автозапуск';
			|pl = 'Autostart';
			|tr = 'Otomatik başlatma'", Common.DefaultLanguageCode()) + ": "
		+ NStr("vi = 'Truyền thông báo từ máy chủ có gia hạn';
				|ru = 'Доставка серверных оповещений с отсрочкой';
				|en = 'Delayed server notification delivery'; fa = 'Delayed server notification delivery';
				|it = 'Доставка серверных оповещений с отсрочкой';
				|pl = 'Delayed server notification delivery';
				|tr = 'Sunucu bildirimlerinin gecikmeli teslimatı'", Common.DefaultLanguageCode()) + " ("
		+ StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'từ phiên %1 ngày %2';
				|ru = 'из сеанса %1 от %2';
				|en = 'from the %1 session started on %2'; fa = 'from the %1 session started on %2';
				|it = 'dalla sessione %1 del %2';
				|pl = 'z sesji %1 z dn. %2';
				|tr = '%2 tarihli %1 oturumdan'", Common.DefaultLanguageCode()),
			Format(CurrentSession.SessionNumber, "NG="),
			Format(CurrentSession.SessionStarted, "DLF=DT")) + ")";
	
	// The procedure name must be as specified in the NameOfJobMethodServerNotificationsDeferredDelivery function.
	BackgroundJobs.Execute("ServerNotifications.ServerNotificationsDeferredDelivery",,, JobDescription);
	
	Launched = True;
	
EndProcedure

// Start background handler.
Procedure ServerNotificationsDeferredDelivery() Export
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	CurrentSession = GetCurrentInfoBaseSession();
	If CurrentSession.ApplicationName <> "BackgroundJob" Then
		Return;
	EndIf;
	
	CurrentBackgroundJob = CurrentSession.GetBackgroundJob();
	If CurrentBackgroundJob = Undefined Then
		Return;
	EndIf;
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	If IsDeferredServerAlertsDeliveryRunning(CurrentBackgroundJob)
	 Or Not ServerNotificationsInternalCached.AreClientNotificationsAvailable()
	   And Not IsCurrentUserRegisteredInInteractionSystem() Then
		Return;
	EndIf;
	
	While True Do
		WaitStart = CurrentSessionDate();
		While True Do
			Selection = UnsentDeferredNotifications();
			If Selection.Count() > 0
			 Or CurrentSessionDate() - WaitStart > 20 Then
				Break;
			EndIf;
			CurrentBackgroundJob.WaitForExecutionCompletion(1);
		EndDo;
		If Selection.Count() = 0 Then
			Break;
		EndIf;
		StartOfDelivery = CurrentSessionDate();
		While Selection.Next() Do
			DeliverNotification(Selection);
			If CurrentSessionDate() - StartOfDelivery > 5 Then
				Break;
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

// Intended for the ServerNotificationsDeferredDelivery procedure.
Procedure DeliverNotification(Selection)
	
	AdditionDeferredDate = Selection.AddedOn + Selection.DeferralOfWritingToCollaborationSystem;
	If CurrentSessionDate() <= AdditionDeferredDate Then
		Return;
	EndIf;
	
	NotificationContent = NotificationNewContent(Selection.NotificationContent);
	If ValueIsFilled(NotificationContent.NameOfAlert) Then
		Sent = SendMessageImmediately(Selection.NotificationID,
			Selection.AddedOn, NotificationContent);
	Else
		Sent = False;
	EndIf;
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.SentServerNotifications");
	LockItem.SetValue("NotificationID", Selection.NotificationID);
	
	BeginTransaction();
	Try
		Block.Lock();
		RecordSet = InformationRegisters.SentServerNotifications.CreateRecordSet();
		RecordSet.Filter.NotificationID.Set(Selection.NotificationID);
		RecordSet.Read();
		If RecordSet.Count() = 1
		   And (Not ValueIsFilled(RecordSet[0].CollaborationSystemRecordDate)
		      Or RecordSet[0].DeferralOfWritingToCollaborationSystem <> 0 ) Then
			
			If Sent Then
				RecordSet[0].CollaborationSystemRecordDate = CurrentSessionDate();
				RecordSet[0].DateWrittenToCollaborationSystemMilliseconds = Milliseconds();
			Else
				RecordSet[0].DeferralOfWritingToCollaborationSystem = 0;
			EndIf;
			RecordSet.Write();
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Intended for the procedures StartDeliverDeferredServerNotifications and ServerNotificationsDeferredDelivery.
Function IsDeferredServerAlertsDeliveryRunning(CurrentBackgroundJob = Undefined)
	
	Filter = New Structure;
	Filter.Insert("State", BackgroundJobState.Active);
	Filter.Insert("MethodName", NameOfJobMethodServerNotificationsDeferredDelivery());
	
	FoundJobs = BackgroundJobs.GetBackgroundJobs(Filter);
	
	If FoundJobs.Count() = 0 Then
		Return False;
	EndIf;
	If CurrentBackgroundJob = Undefined Then
		Return True;
	EndIf;
	
	IDOfCurrent = CurrentBackgroundJob.UUID;
	
	For Each FoundJob In FoundJobs Do
		If FoundJob.UUID = IDOfCurrent Then
			Continue;
		EndIf;
		Return True;
	EndDo;
	
	Return False;
	
EndFunction

// Intended for the StartDeliverDeferredServerNotifications procedure
// and the IsDeferredServerAlertsDeliveryRunning function.
//
Function NameOfJobMethodServerNotificationsDeferredDelivery()
	
	Return "ServerNotifications.ServerNotificationsDeferredDelivery";
	
EndFunction

// Intended for the ServerNotificationsDeferredDelivery procedure.
Function UnsentDeferredNotifications()
	
	SendStatus = ServerNotificationsSendStatus();
	LastNotificationDate = ?(ValueIsFilled(SendStatus.FailedNotificationDate),
		SendStatus.FailedNotificationDate, SendStatus.LastNotificationDate);
	
	Query = New Query;
	Query.SetParameter("LastNotificationDate", LastNotificationDate);
	Query.SetParameter("DateEmpty", '00010101');
	Query.Text =
	"SELECT
	|	SentServerNotifications.NotificationID AS NotificationID,
	|	SentServerNotifications.NotificationContent AS NotificationContent,
	|	SentServerNotifications.AddedOn AS AddedOn,
	|	SentServerNotifications.DeferralOfWritingToCollaborationSystem AS DeferralOfWritingToCollaborationSystem
	|FROM
	|	InformationRegister.SentServerNotifications AS SentServerNotifications
	|WHERE
	|	SentServerNotifications.AddedOn >= &LastNotificationDate
	|	AND SentServerNotifications.CollaborationSystemRecordDate = &DateEmpty
	|	AND SentServerNotifications.DeferralOfWritingToCollaborationSystem > 0
	|
	|ORDER BY
	|	SentServerNotifications.AddedOn,
	|	SentServerNotifications.DateAddedMilliseconds";
	
	Return Query.Execute().Select();
	
EndFunction

// Returns:
//  Structure:
//   * SessionKey - See SessionKey
//   * IBUserID - UUID - ID of the current user.
//   * LastNotificationDate - Date
//   * Notifications - See CommonOverridable.OnAddServerNotifications.Notifications
//   * MinimumPeriod - Number - Time interval in seconds.
//   * CollaborationSystemConnected - Boolean
//   * PersonalChatID - Undefined - Chat is unavailable.
//                                    - CollaborationSystemConversationID - ID of the chat
//                                        "ServerNotifications <Infobase user ID>".
//   * GlobalChatID - Undefined - Chat is unavailable.
//                                   - CollaborationSystemConversationID - ID of the chat
//                                        "ServerNotifications".
//   * ServiceAdministratorSession - Boolean
//
Function ServerNotificationsParametersThisSession() Export
	
	Notifications = AddedSessionNotifications();
	
	Parameters = New Structure;
	Parameters.Insert("SessionKey", SessionKey());
	Parameters.Insert("IBUserID",
		InfoBaseUsers.CurrentUser().UUID);
	Parameters.Insert("LastNotificationDate", CurrSessionStartInCurrSessionDateTimeZone());
	Parameters.Insert("Notifications", Notifications);
	Parameters.Insert("MinimumPeriod", 20*60);
	Parameters.Insert("CollaborationSystemConnected", False);
	Parameters.Insert("PersonalChatID", Undefined);
	Parameters.Insert("GlobalChatID", Undefined);
	Parameters.Insert("ServiceAdministratorSession", ServiceAdministratorSession());
	Parameters.Insert("ShouldRegisterIndicators", RegisterServerNotificationsIndicators());
	Parameters.Insert("RepeatedDateExportMinInterval",
		RepeatedDateExportMinInterval());
	
	RecurringNotifications = New Map;
	For Each KeyAndValue In Notifications Do
		Notification = KeyAndValue.Value;
		If Not ValueIsFilled(Notification.Name)
		 Or KeyAndValue.Key <> Notification.Name Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Trong thủ tục ""%1""
				           |chưa điền hoặc điền sai tên thông báo
				           |%2 = ""%3""
				           |%4 = ""%5"".';
				           |ru = 'В процедуре ""%1""
				           |не заполнено или некорректно заполнено имя оповещения
				           |%2 = ""%3""
				           |%4 = ""%5"".';
				           |en = 'In procedure ""%1"",
				           |the notification name is either unspecified or filled in incorrectly
				           |%2 = ""%3""
				           |%4 = ""%5"".'; fa = 'In procedure ""%1"",
				           |the notification name is either unspecified or filled in incorrectly
				           |%2 = ""%3""
				           |%4 = ""%5"".';
				           |it = 'Nella procedura ""%1""
				           | non è stato compilato p è stato compilato scorrettamente il nome dell''avviso
				           |%2 = ""%3""
				           |%4 = ""%5"".';
				           |pl = 'W procedurze ""%1""
				           |nie wypełniono lub niepoprawnie wypełniono nazwę powiadomienia
				           |%2 = ""%3""
				           |%4 = ""%5"".';
				           |tr = '""%1"" prosedüründe
				           |bildirim adı doldurulmadı veya yanlış dolduruldu
				           |%2 = ""%3""
				           |%4 = ""%5"".'"),
					"CommonOverridable.OnAddServerNotifications",
					"Key", KeyAndValue.Key, "Notification.Name", Notification.Name);
			Raise ErrorText;
		EndIf;
		If Not ValueIsFilled(Notification.NotificationReceiptModuleName) Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Trong thủ tục ""%1""
				           |thông báo ""%2""
				           |chưa điền thuộc tính ""%3"".';
				           |ru = 'В процедуре ""%1""
				           |у оповещения ""%2""
				           |не заполнено свойство ""%3"".';
				           |en = 'In procedure ""%1"",
				           |property ""%3"" of notification ""%2""
				           |is not filled in.'; fa = 'In procedure ""%1"",
				           |property ""%3"" of notification ""%2""
				           |is not filled in.';
				           |it = 'Nella procedura ""%1""
				           | la proprietà ""%3"" dell''avviso ""%2""
				           | non è compilata.';
				           |pl = 'W procedurze ""%1""
				           |dla powiadomienia ""%2""
				           |nie wypełniono właściwości ""%3"".';
				           |tr = '""%1"" prosedüründe
				           |""%2"" bildiriminde
				           |""%3"" özelliği doldurulmadı.'"),
					"CommonOverridable.OnAddServerNotifications",
					Notification.Name, "NotificationReceiptModuleName");
			Raise ErrorText;
		EndIf;
		If Metadata.CommonModules.Find(Notification.NotificationReceiptModuleName) = Undefined Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Trong thủ tục ""%1""
				           |thông báo ""%2""
				           |trong thuộc tính ""%3"" đã chỉ ra mô-đun chung không tồn tại
				           |""%4"".';
				           |ru = 'В процедуре ""%1""
				           |у оповещения ""%2""
				           |в свойстве ""%3"" указан несуществующий общий модуль
				           |""%4"".';
				           |en = 'In procedure ""%1"",
				           |property ""%3"" of notification ""%2""
				           |has non-existent common module
				           |""%4"".'; fa = 'In procedure ""%1"",
				           |property ""%3"" of notification ""%2""
				           |has non-existent common module
				           |""%4"".';
				           |it = 'Nella procedura ""%1""
				           | nella proprietà ""%3"" dell''avviso ""%2""
				           | è indicato un modulo comune non esistente
				           |""%4"".';
				           |pl = 'W procedurze ""%1""
				           |dla powiadomienia ""%2""
				           |we właściwości ""%3"" jest podany nieistniejący wspólny moduł
				           |""%4"".';
				           |tr = '""%1"" prosedüründe
				           |""%2"" bildiriminde
				           |""%3""özelliğinde var olmayan bir
				           |""%4"" modülü belirtildi.'"),
					"CommonOverridable.OnAddServerNotifications",
					Notification.Name, "NotificationReceiptModuleName", Notification.NotificationReceiptModuleName);
			Raise ErrorText;
		EndIf;
		If Not ValueIsFilled(Notification.NotificationSendModuleName) Then
			Continue;
		EndIf;
		If Metadata.CommonModules.Find(Notification.NotificationSendModuleName) = Undefined Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Trong thủ tục ""%1""
				           |thông báo ""%2""
				           |trong thuộc tính ""%3"" đã chỉ ra mô-đun chung không tồn tại
				           |""%4"".';
				           |ru = 'В процедуре ""%1""
				           |у оповещения ""%2""
				           |в свойстве ""%3"" указан несуществующий общий модуль
				           |""%4"".';
				           |en = 'In procedure ""%1"",
				           |property ""%3"" of notification ""%2""
				           |has non-existent common module
				           |""%4"".'; fa = 'In procedure ""%1"",
				           |property ""%3"" of notification ""%2""
				           |has non-existent common module
				           |""%4"".';
				           |it = 'Nella procedura ""%1""
				           | nella proprietà ""%3"" dell''avviso ""%2""
				           | è indicato un modulo comune non esistente
				           |""%4"".';
				           |pl = 'W procedurze ""%1""
				           |dla powiadomienia ""%2""
				           |we właściwości ""%3"" jest podany nieistniejący wspólny moduł
				           |""%4"".';
				           |tr = '""%1"" prosedüründe
				           |""%2"" bildiriminde
				           |""%3""özelliğinde var olmayan bir
				           |""%4"" modülü belirtildi.'"),
					"CommonOverridable.OnAddServerNotifications",
					Notification.Name, "NotificationSendModuleName", Notification.NotificationSendModuleName);
			Raise ErrorText;
		EndIf;
		If Parameters.ServiceAdministratorSession Then
			Continue;
		EndIf;
		RecurringNotifications.Insert(KeyAndValue.Key, Notification);
		If Parameters.MinimumPeriod > Notification.VerificationPeriod Then
			Parameters.MinimumPeriod = Notification.VerificationPeriod;
		EndIf;
	EndDo;
	
	If Parameters.ServiceAdministratorSession Then
		Return Parameters;
	EndIf;
	
	ReviseMinCheckInterval(Parameters.MinimumPeriod);
	
	If ValueIsFilled(RecurringNotifications) Then
		SetPrivilegedMode(True);
		RecordSet = ServiceRecordSet(InformationRegisters.PeriodicServerNotifications);
		RecordSet.Filter.SessionKey.Set(Parameters.SessionKey);
		NewRecord = RecordSet.Add();
		NewRecord.SessionKey = Parameters.SessionKey;
		NewRecord.IBUserID =
			InfoBaseUsers.CurrentUser().UUID;
		NewRecord.Notifications = New ValueStorage(RepeatedNotificationToSave(RecurringNotifications), New Deflation(9));
		NewRecord.AddedOn = CurrentSessionDate();
		RecordSet.Write();
		ConfigureJobSendServerNotificationsToClients(True, Parameters.MinimumPeriod, True);
		SetPrivilegedMode(False);
	EndIf;
	
	For Each KeyAndValue In Notifications Do
		KeyAndValue.Value.Parameters = Undefined;
	EndDo;
	
	Parameters.CollaborationSystemConnected = CollaborationSystemConnected();
	FillPropertyValues(Parameters, ChatsIDs());
	
	Return Parameters;
	
EndFunction

Function CurrSessionStartInCurrSessionDateTimeZone()
	
	// ACC:143-off - No.643.2.1. "CurrentDate" is required instead of "CurrentSessionDate"
	// as the current date is used in the "SessionStart" property of the "InfoBaseSession" object.
	TimeShift = CurrentSessionDate() - CurrentDate();
	// ACC:143-on
	
	Return GetCurrentInfoBaseSession().SessionStarted + TimeShift;
	
EndFunction

// Returns:
//  Structure:
//   * PersonalChatID - Undefined - Chat is unavailable.
//                                    - CollaborationSystemConversationID - ID of the chat
//                                        "ServerNotifications <Infobase user ID>".
//   * GlobalChatID - Undefined - Chat is unavailable.
//                                   - CollaborationSystemConversationID - ID of the chat
//                                        "ServerNotifications".
// 
Function ChatsIDs()
	
	Result = New Structure;
	Result.Insert("PersonalChatID");
	Result.Insert("GlobalChatID");
	
	UserIDCollaborationSystem = Undefined;
	If Not IsCurrentUserRegisteredInInteractionSystem(UserIDCollaborationSystem) Then
		Return Result;
	EndIf;
	
	GlobalChatID = GlobalChatID();
	If GlobalChatID = Undefined Then
		Return Result;
	EndIf;
	
	PersonalChatID = PersonalChatID(, UserIDCollaborationSystem);
	If PersonalChatID = Undefined Then
		Return Result;
	EndIf;
	
	Result.GlobalChatID  = GlobalChatID;
	Result.PersonalChatID = PersonalChatID;
	
	Return Result;
	
EndFunction

Procedure ReviseMinCheckInterval(MinCheckInterval)
	
	LowerBound = ?(Common.DataSeparationEnabled(), 5*60, 60);
	
	If MinCheckInterval < LowerBound Then
		MinCheckInterval = LowerBound;
	EndIf;
	
	MinInterval = RepeatedDateExportMinInterval() * 60;
	
	If MinCheckInterval < MinInterval Then
		MinCheckInterval = MinInterval;
	EndIf;
	
EndProcedure

// When Collaboration System is not used, and the number of sessions exceeds 2,000,
// 1-minute interval for server calls will cause a high server load (33 calls per second).
// If the ratio is less than 1 core per 10 sessions, the load might lead to a critical performance degradation.
// To reduce the load, set the interval to 2–5 minutes.
// Note that will reduce the UI responsiveness when user actions affect the server side.
// 
// 
//
// Returns:
//  Number - The minimal time (in minutes) the intermittent data transfer must run
//          for the common server call and checks run by the scheduled job.
//          This parameter overrides (upward) the predefined value.
//
Function RepeatedDateExportMinInterval()
	Return 1;
EndFunction

Procedure ConfigureJobSendServerNotificationsToClients(Enable, RepeatPeriod = 0, OnStart = False)
	
	Try
		ConfigureJobSendServerNotificationsToClientsNoAttempt(Enable, RepeatPeriod, OnStart);
	Except
		ErrorInfo = ErrorInfo();
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể tùy chỉnh nhiệm vụ thường kỳ
			           |""%1"" do nguyên nhân:
			           |%2';
			           |ru = 'Не удалось настроить регламентное задание
			           |""%1"" по причине:
			           |%2';
			           |en = 'Cannot set up scheduled job
			           |""%1"" due to:
			           |%2'; fa = 'Cannot set up scheduled job
			           |""%1"" due to:
			           |%2';
			           |it = 'Non è stato possibile impostare il compito di background
			           |""%1"" a causa di:
			           |%2';
			           |pl = 'Nie udało się ustawić zadania reglamentowanego
			           |""%1"" z powodu:
			           |%2';
			           |tr = '""%1"" programlı işi ayarlanamadı
			           |çünkü:
			           |%2'"),
			Metadata.ScheduledJobs.SendServerNotificationsToClients.Name,
			ErrorProcessing.DetailErrorDescription(ErrorInfo));
		WriteLogEvent(
			NStr("vi = 'Thông báo từ máy chủ.Lỗi tùy chỉnh nhiệm vụ thường kỳ';
				|ru = 'Серверные оповещения.Ошибка настройки регламентного задания';
				|en = 'Server notifications.Scheduled job setup error'; fa = 'Server notifications.Scheduled job setup error';
				|it = 'Avvisi server. Errore di impostazione del compito di background';
				|pl = 'Powiadomienia serwerowe.Błąd ustawienia zadania reglamentowanego';
				|tr = 'Sunucu bildirimler.Zamanlanmış görevi ayarlarken bir hata oluştu'",
				Common.DefaultLanguageCode()),
			EventLogLevel.Error,,, ErrorText);
	EndTry;
	
EndProcedure

Procedure ConfigureJobSendServerNotificationsToClientsNoAttempt(Enable, RepeatPeriod, OnStart)
	
	UserName = "";
	If ValueIsFilled(UserName())
	 Or Not OnStart
	   And InfoBaseUsers.GetUsers().Count() <> 0 Then
		Try
			IBUser = InfobaseDummyUser();
		Except
			ErrorInfo = ErrorInfo();
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể tạo người sử dụng dịch vụ ""%1"" do nguyên nhân:
				           |%2';
				           |ru = 'Не удалось создать служебного пользователя ""%1"" по причине:
				           |%2';
				           |en = 'Cannot create utility user ""%1"" due to:
				           |%2'; fa = 'Cannot create utility user ""%1"" due to:
				           |%2';
				           |it = 'Non è stato possibile creare l''utente di servizio ""%1"" a causa di:
				           |%2';
				           |pl = 'Nie udało się utworzyć użytkownika serwisowego ""%1"" z powodu:
				           |%2';
				           |tr = '""%1"" dahili kullanıcısı oluşturulamadı çünkü:
				           |%2'"),
				InternalUsername(),
				ErrorProcessing.DetailErrorDescription(ErrorInfo));
			Raise ErrorText;
		EndTry;
		If IBUser <> Undefined Then
			UserName = IBUser.Name;
		EndIf;
	EndIf;
	
	MinRetryInterval = 60;
	MaxRetryInterval = 20*60;
	ReviseMinCheckInterval(MinRetryInterval);
	
	If ValueIsFilled(RepeatPeriod) Then
		If RepeatPeriod < MinRetryInterval Then
			RepeatPeriod = MinRetryInterval;
		ElsIf RepeatPeriod > MaxRetryInterval Then
			RepeatPeriod = MaxRetryInterval;
		Else
			WholePartCount = Int(RepeatPeriod / 15);
			Balance = RepeatPeriod - WholePartCount * 15;
			If Balance <> 0 Then
				RepeatPeriod = WholePartCount * 15;
			EndIf;
		EndIf;
	Else
		RepeatPeriod = MaxRetryInterval;
	EndIf;
	
	Schedule = New JobSchedule;
	Schedule.DaysRepeatPeriod = 1;
	Schedule.RepeatPeriodInDay = RepeatPeriod;
	
	JobMetadata = Metadata.ScheduledJobs.SendServerNotificationsToClients;
	JobParameters = New Structure("Key, RestartIntervalOnFailure,
	|RestartCountOnFailure");
	FillPropertyValues(JobParameters, JobMetadata);
	JobParameters.Insert("Use", Enable);
	JobParameters.Insert("UserName", UserName);
	JobParameters.Insert("Schedule", Schedule);
	
	If Common.DataSeparationEnabled() Then
		Filter = New Structure("MethodName", JobMetadata.MethodName);
	Else
		Filter = New Structure("Metadata", JobMetadata);
	EndIf;
	FoundJobs = ScheduledJobsServer.FindJobs(Filter);
	
	If FoundJobs.Count() > 1 Then
		For Each FoundJob In FoundJobs Do
			If FoundJob = FoundJobs[0] Then
				Continue;
			EndIf;
			ScheduledJobsServer.DeleteJob(FoundJob);
		EndDo;
	EndIf;
	
	If FoundJobs.Count() = 0 Then
		BeginTransaction();
		Try
			ScheduledJobsServer.BlockARoutineTask(JobMetadata);
			FoundJobs = ScheduledJobsServer.FindJobs(Filter);
			If FoundJobs.Count() = 0 Then
				JobParameters.Insert("Metadata", JobMetadata);
				ScheduledJobsServer.AddJob(JobParameters);
				UpdateSendStatus(New Structure("MinCheckInterval", RepeatPeriod),
					"MinCheckInterval");
			EndIf;
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry
	EndIf;
	
	If FoundJobs.Count() = 0 Then
		Return;
	EndIf;
	
	Job = FoundJobs[0];
	If AreJobParametersMatch(Job, JobParameters, OnStart) Then
		Return;
	EndIf;
	
	BeginTransaction();
	Try
		ScheduledJobsServer.BlockARoutineTask(Job.UUID);
		FoundJobs = ScheduledJobsServer.FindJobs(Filter);
		If FoundJobs.Count() = 0
		 Or FoundJobs[0].UUID <> Job.UUID Then
			ConfigureJobSendServerNotificationsToClientsNoAttempt(Enable, RepeatPeriod, OnStart);
		ElsIf Not AreJobParametersMatch(FoundJobs[0], JobParameters, OnStart) Then
			If OnStart And RepeatPeriod >= FoundJobs[0].Schedule.RepeatPeriodInDay Then
				JobParameters.Delete("Schedule");
			EndIf;
			ScheduledJobsServer.ChangeJob(FoundJobs[0].UUID, JobParameters);
			If JobParameters.Property("Schedule") Then
				UpdateSendStatus(New Structure("MinCheckInterval", RepeatPeriod),
					"MinCheckInterval");
			EndIf;
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry
	
EndProcedure

Function NameOfNotificationAllSessionsSleepingJobDisabled()
	Return "StandardSubsystems.Core.ServerNotifications.AllSessionsSleepingJobDisabled";
EndFunction

Procedure DeleteServerNotification(NotificationID)
	
	RecordSet = ServiceRecordSet(InformationRegisters.SentServerNotifications);
	RecordSet.Filter.NotificationID.Set(NotificationID);
	RecordSet.Write();
	
EndProcedure

Procedure SetUsageOfJobSendServerNotificationsToClients(Use)
	
	Try
		SetUsageOfJobSendServerNotificationsToClientsNoAttempt(Use);
	Except
		ErrorInfo = ErrorInfo();
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể thay đổi sử dụng nhiệm vụ thường kỳ
			           |""%1"" theo nguyên nhân:
			           |%2';
			           |ru = 'Не удалось изменить использование регламентного задания
			           |""%1"" по причине:
			           |%2';
			           |en = 'Cannot change the usage of
			           |the ""%1"" scheduled job due to:
			           |%2'; fa = 'Cannot change the usage of
			           |the ""%1"" scheduled job due to:
			           |%2';
			           |it = 'Не удалось изменить использование регламентного задания
			           |""%1"" по причине:
			           |%2';
			           |pl = 'Cannot change the usage of
			           |the ""%1"" scheduled job due to:
			           |%2';
			           |tr = '""%1"" zamanlanmış görevi kullanımı şu sebeple değiştirilemedi
			           |:
			           |%2'"),
			Metadata.ScheduledJobs.SendServerNotificationsToClients.Name,
			ErrorProcessing.DetailErrorDescription(ErrorInfo));
		WriteLogEvent(
			NStr("vi = 'Thông báo từ máy chủ.Lỗi tùy chỉnh nhiệm vụ thường kỳ';
				|ru = 'Серверные оповещения.Ошибка настройки регламентного задания';
				|en = 'Server notifications.Scheduled job setup error'; fa = 'Server notifications.Scheduled job setup error';
				|it = 'Avvisi server. Errore di impostazione del compito di background';
				|pl = 'Powiadomienia serwerowe.Błąd ustawienia zadania reglamentowanego';
				|tr = 'Sunucu bildirimler.Zamanlanmış görevi ayarlarken bir hata oluştu'",
				Common.DefaultLanguageCode()),
			EventLogLevel.Error,,, ErrorText);
	EndTry;
	
EndProcedure

Procedure SetUsageOfJobSendServerNotificationsToClientsNoAttempt(Val Use)
	
	JobMetadata = Metadata.ScheduledJobs.SendServerNotificationsToClients;
	If Common.DataSeparationEnabled() Then
		Filter = New Structure("MethodName", JobMetadata.MethodName);
	Else
		Filter = New Structure("Metadata", JobMetadata);
	EndIf;
	If Not Common.SeparatedDataUsageAvailable() Then
		Use = False;
		FilterShared = New Structure("Metadata, Use", JobMetadata, True);
		// ACC:453-off - No.760.3. It is acceptable to obtain an invalid job to disable it.
		Jobs = ScheduledJobs.GetScheduledJobs(FilterShared);
		// ACC:453-on
		For Each Job In Jobs Do
			ScheduledJobsServer.SetScheduledJobUsage(Job, False);
		EndDo;
		Filter.Insert("DataArea", 0);
	EndIf;
	Filter.Insert("Use", Not Use);
	
	Jobs = ScheduledJobsServer.FindJobs(Filter);
	
	For Each Job In Jobs Do
		ScheduledJobsServer.ChangeJob(Job.UUID,
			New Structure("Use", Use));
	EndDo;
	
EndProcedure

Function AreJobParametersMatch(Job, JobParameters, OnStart)
	
	For Each KeyAndValue In JobParameters Do
		If Job[KeyAndValue.Key] = KeyAndValue.Value Then
			Continue;
		EndIf;
		If KeyAndValue.Key = "Schedule" Then
			If OnStart Then
				If JobParameters.Schedule.RepeatPeriodInDay
				   < Job.Schedule.RepeatPeriodInDay Then
					Return False;
				EndIf;
				NewSchedule = New JobSchedule;
				FillPropertyValues(NewSchedule, JobParameters.Schedule);
				NewSchedule.RepeatPeriodInDay =
					Job.Schedule.RepeatPeriodInDay;
			Else
				NewSchedule = JobParameters.Schedule;
			EndIf;
			If String(Job[KeyAndValue.Key]) = String(NewSchedule) Then
				Continue;
			EndIf;
		EndIf;
		Return False;
	EndDo;
	
	Return True;
	
EndFunction

Function EventLogInteractionSystemErrorSeverity(ErrorInfo)
	
	LogLevel = EventLogLevel.Error;
	If Not Common.SubsystemExists("StandardSubsystems.Conversations") Then
		Return LogLevel;
	EndIf;
	
	ModuleConversations = Common.CommonModule("Conversations");
	If ModuleConversations.IsInteractionSystemConnectError(ErrorInfo) Then
		LogLevel = EventLogLevel.Warning;
	EndIf;
	
	Return LogLevel;
	
EndFunction

// Parameters:
//  IsInternal - Boolean - If True and the name of the current user is empty,
//     create a utility user and assign it to the scheduled job.
//
// Returns:
//  Boolean
//
Function IsCurrentUserRegisteredInInteractionSystem(UserIDCollaborationSystem = Undefined)
	
	If Not CollaborationSystemConnected() Then
		Return False;
	EndIf;
	
	IBUser = InfoBaseUsers.CurrentUser();
	If Not ValueIsFilled(IBUser.Name)
	 Or Not Common.SubsystemExists("StandardSubsystems.Conversations")
	 Or IsInteractionSystemTemporarilyUnavailable() Then
		Return False;
	EndIf;
	
	ModuleConversations = Common.CommonModule("Conversations");
	AuthorizedUser = Users.AuthorizedUser();
	Try
		UserIDCollaborationSystem = ModuleConversations.CollaborationSystemUser(
			AuthorizedUser, True);
	Except
		ErrorInfo = ErrorInfo();
		If IsInteractionSystemTemporarilyUnavailable(True) Then
			Return False;
		EndIf;
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể ghi nhận người sử dụng hiện tại
			           |""%1 (%2)""
			           |trong hệ thống tương tác do nguyên nhân:
			           |%3';
			           |ru = 'Не удалось зарегистрировать текущего пользователя
			           |""%1 (%2)""
			           |в системе взаимодействия по причине:
			           |%3';
			           |en = 'Cannot register current user
			           |""%1 (%2)""
			           |in the collaboration system due to:
			           |%3'; fa = 'Cannot register current user
			           |""%1 (%2)""
			           |in the collaboration system due to:
			           |%3';
			           |it = 'Non è stato possibile registrare l''utente corrente 
			           |""%1 (%2)""
			           | nel sistema di interazione a causa di:
			           |%3';
			           |pl = 'Nie udało się zarejestrować bieżącego użytkownika
			           |""%1 (%2)""
			           |w systemie interakcji z powodu:
			           |%3';
			           |tr = 'Geçerli kullanıcı 
			           |""%1 (%2)""
			           |Ortak Çalışma Sisteminde kaydedilemedi çünkü:
			           |%3'"),
			IBUser.Name,
			Lower(IBUser.UUID),
			ErrorProcessing.DetailErrorDescription(ErrorInfo));
		WriteLogEvent(
			NStr("vi = 'Thông báo từ máy chủ.Lỗi ghi nhận người sử dụng trong hệ thống tương tác';
				|ru = 'Серверные оповещения.Ошибка регистрации пользователя в системе взаимодействия';
				|en = 'Server notifications.An error occurred when registering the user in the collaboration system'; fa = 'Server notifications.An error occurred when registering the user in the collaboration system';
				|it = 'Avvisi server. Errore di registrazione dell''utente nel sistema di interazione';
				|pl = 'Powiadomienia serwerowe.Błąd rejestracji użytkownika w systemie interakcji ';
				|tr = 'Sunucu bildirimleri.Ortak Çalışma Sisteminde kullanıcı kaydı hatası'",
				Common.DefaultLanguageCode()),
			EventLogInteractionSystemErrorSeverity(ErrorInfo),,,
			ErrorText);
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

Function IsInteractionSystemTemporarilyUnavailable(CheckAvailability = False)
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	ParameterName = "StandardSubsystems.Core.InteractionSystemFailedAccessDate";
	PreviousValue2 = StandardSubsystemsServer.ExtensionParameter(ParameterName, True);
	PreviousValue2 = ?(TypeOf(PreviousValue2) = Type("Date"), PreviousValue2, '00010101');
	
	If ValueIsFilled(PreviousValue2)
	   And PreviousValue2 + 60*5 > CurrentSessionDate()
	   And PreviousValue2 - 60 < CurrentSessionDate() Then
		Return True;
	EndIf;
	
	If Not CheckAvailability Then
		Return False;
	EndIf;
	
	NewValue = '00010101';
	Try
		CollaborationSystem.GetExternalSystemTypes();
	Except
		NewValue = CurrentSessionDate();
		ErrorInfo = ErrorInfo();
	EndTry;
	
	If Not ValueIsFilled(NewValue) Then
		Return False;
	EndIf;
	
	CurrentValue = StandardSubsystemsServer.ExtensionParameter(ParameterName, True);
	CurrentValue = ?(TypeOf(CurrentValue) = Type("Date"), CurrentValue, '00010101');
	If PreviousValue2 <> CurrentValue Then
		Return True;
	EndIf;
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.ExtensionVersionParameters");
	LockItem.SetValue("ExtensionsVersion", Catalogs.ExtensionsVersions.EmptyRef());
	LockItem.SetValue("ParameterName", ParameterName);
	
	BeginTransaction();
	Try
		Block.Lock();
		CurrentValue = StandardSubsystemsServer.ExtensionParameter(ParameterName, True);
		CurrentValue = ?(TypeOf(CurrentValue) = Type("Date"), CurrentValue, '00010101');
		If PreviousValue2 = CurrentValue Then
			StandardSubsystemsServer.SetExtensionParameter(ParameterName, NewValue, True);
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	If PreviousValue2 = CurrentValue Then
		WriteLogEvent(
			NStr("vi = 'Thông báo từ máy chủ.Hệ thống tương tác không khả dụng';
				|ru = 'Серверные оповещения.Система взаимодействия недоступна';
				|en = 'Server notifications.Collaboration system is unavailable'; fa = 'Server notifications.Collaboration system is unavailable';
				|it = 'Avvisi server. Il sistema di interazione non è disponibile';
				|pl = 'Powiadomienia serwerowe.System interakcji jest niedostępny';
				|tr = 'Sunucu bildirimleri.Ortak çalışma sistemi kullanılamıyor'",
				Common.DefaultLanguageCode()),
			EventLogLevel.Warning,,,
			ErrorProcessing.BriefErrorDescription(ErrorInfo));
	EndIf;
	
	Return True;
	
EndFunction

Function InfobaseDummyUser()
	
	Properties = Users.NewIBUserDetails(, True);
	Properties.Name = InternalUsername();
	RefToNew = Catalogs.Users.GetRef(
		New UUID("ea3b6bcf-d6d8-11ee-886a-b06ebfbf08c7"));
	
	Return Users.InfobaseDummyUser(Properties, RefToNew);
	
EndFunction

Function InternalUsername()
	
	Return "SendServerNotifications";
	
EndFunction

Function ServiceAdministratorSession()
	
	If Not Common.DataSeparationEnabled() Then
		Return False;
	EndIf;
	
	If Common.SubsystemExists("CloudTechnology.Core") Then
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		Return ModuleSaaSOperations.SessionWithoutSeparators();
	EndIf;
	
	Return False;
	
EndFunction

Function UseCollaborationSystemInFileInfobase()
	
	Return False;
	
EndFunction

Function CollaborationSystemConnected(RefreshCache = False, DeliverWithoutCS = Undefined) Export
	
	If ServerNotificationsInternalCached.AreClientNotificationsAvailable() Then
		Return False;
	EndIf;
	
	LastCheck = ServerNotificationsInternalCached.LastCheckOfInteractionSystemConnection();
	
	If LastCheck.Date + 300 > CurrentSessionDate() And Not RefreshCache Then
		Return LastCheck.Connected;
	EndIf;
	
	LastCheck.Date = CurrentSessionDate();
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	If ServiceAdministratorSession()
	 Or Not UseCollaborationSystemInFileInfobase()
	   And Common.FileInfobase() Then
		
		LastCheck.Connected = False;
	
	ElsIf Common.SubsystemExists("StandardSubsystems.Conversations") Then
		ModuleConversations = Common.CommonModule("Conversations");
		LastCheck.Connected = ModuleConversations.CollaborationSystemConnected();
	Else
		LastCheck.Connected = False;
	EndIf;
	
	If LastCheck.Connected Then
		If DeliverWithoutCS = Undefined Then
			DeliverWithoutCS = Constants.DeliverServerNotificationsWithoutCollaborationSystem.Get();
		EndIf;
		If DeliverWithoutCS Then
			LastCheck.Connected = False;
		EndIf;
	EndIf;
	
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
	Return LastCheck.Connected;
	
EndFunction

Procedure OnChangeConstantDeliverServerNotificationsWithoutCollaborationSystem(DeliverWithoutCS) Export
	
	If Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	CollaborationSystemConnected = CollaborationSystemConnected(True);
	
	If Not CollaborationSystemConnected And DeliverWithoutCS Then
		CollaborationSystemConnected(True, False);
	EndIf;
	
	SendServerNotification(
		"StandardSubsystems.Core.ServerNotifications.CollaborationSystemConnected",
		CollaborationSystemConnected, Undefined, True);
	
	If Not CollaborationSystemConnected And DeliverWithoutCS Then
		CollaborationSystemConnected(True);
	EndIf;
	
EndProcedure

Function PersonalChatID(IBUserID = Undefined,
			UserIDCollaborationSystem = Undefined)
	
	SetPrivilegedMode(True);
	If IBUserID = Undefined Then
		UUID = InfoBaseUsers.CurrentUser().UUID;
	Else
		UUID = IBUserID;
	EndIf;
	PersonalChatKey = "ServerNotifications" + "_" + Lower(UUID);
	
	Try
		ShouldUpdateChatMembers = UserIDCollaborationSystem <> Undefined;
		AttemptNumber = 1;
		CreatedOn = False;
		While True Do
			Conversation = CollaborationSystem.GetConversation(PersonalChatKey);
			If Conversation <> Undefined Then
				Break;
			EndIf;
			If UserIDCollaborationSystem = Undefined Then
				If IBUserID = Undefined Then
					UserIDCollaborationSystem = CollaborationSystem.CurrentUserID();
				Else
					Try
						UserIDCollaborationSystem = CollaborationSystem.GetUserID(UUID);
					Except
						UserIDCollaborationSystem = CollaborationSystem.CurrentUserID();
					EndTry;
				EndIf;
			EndIf;
			NewConversation = CollaborationSystem.CreateConversation();
			NewConversation.Displayed = False;
			NewConversation.Key = PersonalChatKey;
			NewConversation.Members.Add(UserIDCollaborationSystem);
			Try
				NewConversation.Write();
				Conversation = NewConversation;
				CreatedOn = True;
				Break;
			Except
				AttemptNumber = AttemptNumber + 1;
				If AttemptNumber > 10 Then
					Raise;
				EndIf;
			EndTry;
		EndDo;
		If Not CreatedOn
		   And (Conversation.Displayed
		      Or ShouldUpdateChatMembers
		        And (Conversation.Members.Count() <> 1
		           Or Not Conversation.Members.Contains(UserIDCollaborationSystem))) Then
			Conversation.Displayed = False;
			If ShouldUpdateChatMembers Then
				Conversation.Members.Clear();
				Conversation.Members.Add(UserIDCollaborationSystem);
			EndIf;
			Conversation.Write();
		EndIf;
	Except
		ErrorInfo = ErrorInfo();
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể tạo thảo luận riêng đối với người sử dụng ""%1 (%2)"" do nguyên nhân:
			           |%3';
			           |ru = 'Не удалось создать личное обсуждение для пользователя ""%1 (%2)"" по причине:
			           |%3';
			           |en = 'Cannot create a personal conversation for user ""%1 (%2)"" due to:
			           |%3'; fa = 'Cannot create a personal conversation for user ""%1 (%2)"" due to:
			           |%3';
			           |it = 'Non è stato possibile creare una discussione privata per l''utente ""%1 (%2)"" a causa di:
			           |%3';
			           |pl = 'Nie udało się utworzyć dyskusji osobistej dla użytkownika ""%1 (%2)"" z powodu:
			           |%3';
			           |tr = '""%1 (%2)"" kullanıcısı için özel sohbet oluşturulamadı çünkü:
			           |%3'"),
			InfoBaseUsers.CurrentUser().Name,
			Lower(IBUserID),
			ErrorProcessing.DetailErrorDescription(ErrorInfo));
		WriteLogEvent(
			NStr("vi = 'Thông báo từ máy chủ.Lỗi tạo thảo luận riêng';
				|ru = 'Серверные оповещения.Ошибка создания личного обсуждения';
				|en = 'Server notifications.An error occurred when creating a personal conversation'; fa = 'Server notifications.An error occurred when creating a personal conversation';
				|it = 'Avvisi server. Errore di creazione di una discussione privata';
				|pl = 'Powiadomienia serwerowe.Błąd utworzenia dyskusji osobistej';
				|tr = 'Sunucu bildirimleri.Özel sohbet oluşturma hatası'",
				Common.DefaultLanguageCode()),
			EventLogInteractionSystemErrorSeverity(ErrorInfo),,, ErrorText);
		Return Undefined;
	EndTry;
	SetPrivilegedMode(False);
	
	Return Conversation.ID;
	
EndFunction

Function GlobalChatID()
	
	GlobalChatKey = "ServerNotifications";
	
	SetPrivilegedMode(True);
	Try
		Conversation = CollaborationSystem.GetConversation(GlobalChatKey);
		CreatedOn = False;
		If Conversation = Undefined Then
			Conversation = CollaborationSystem.CreateConversation();
			Conversation.Displayed = False;
			Conversation.Key = GlobalChatKey;
			Conversation.Members.Add(CollaborationSystem.StandardUsers.AllApplicationUsers);
			Try
				Conversation.Write();
				CreatedOn = True;
			Except
				CreatedOn = False;
			EndTry;
			If Not CreatedOn Then
				ExistingChat = CollaborationSystem.GetConversation(GlobalChatKey);
				If ExistingChat <> Undefined Then
					Conversation = ExistingChat;
				Else
					Conversation.Write();
					CreatedOn = True;
				EndIf;
			EndIf;
		EndIf;
		If Not CreatedOn And Conversation.Displayed Then
			Conversation.Displayed = False;
			Conversation.Write();
		EndIf;
	Except
		ErrorInfo = ErrorInfo();
		WriteLogEvent(
			NStr("vi = 'Thông báo từ máy chủ.Lỗi tạo thảo luận riêng';
				|ru = 'Серверные оповещения.Ошибка создания общего обсуждения';
				|en = 'Server notifications.An error occurred when creating a common conversation'; fa = 'Server notifications.An error occurred when creating a common conversation';
				|it = 'Avvisi server. Errore di creazione di una discussione comune';
				|pl = 'Powiadomienia serwerowe.Błąd utworzenia dyskusji ogólnej';
				|tr = 'Sunucu bildirimleri.Ortak sohbet oluşturma hatası'",
				Common.DefaultLanguageCode()),
			EventLogInteractionSystemErrorSeverity(ErrorInfo),,,
			ErrorProcessing.DetailErrorDescription(ErrorInfo));
		Return Undefined;
	EndTry;
	SetPrivilegedMode(False);
	
	Return Conversation.ID;
	
EndFunction

// Delivers a message containing arbitrary data from the client to the server.
//
// Throws an exception if the delivery failed.
//
// Parameters: 
//   Data - See MessageNewData
//   ConversationID - CollaborationSystemConversationID
//
// Returns:
//  Boolean - True if the message is successfully written to the Collaboration System.
//
Function SendMessage(Data, ConversationID)
	
	ProcedureName = TimeConsumingOperations.FullNameOfLongRunningOperationAppliedProcedure();
	Text = Data.NameOfAlert + "
		|" + ?(ValueIsFilled(Data.NotificationID), Data.NotificationID, "-") + "
		|" + ?(ValueIsFilled(ProcedureName), ProcedureName, "-");
	
	Try
		NewMessage = CollaborationSystem.CreateMessage(ConversationID);
		NewMessage.Data = Data;
		NewMessage.Date   = CurrentSessionDate();
		NewMessage.Text  = New FormattedString(Text);
		NewMessage.Write();
	Except
		ErrorInfo = ErrorInfo();
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể gửi thông báo đến thảo luận %1 do nguyên nhân:
			           |%2';
			           |ru = 'Не удалось отправить сообщение в обсуждение %1 по причине:
			           |%2';
			           |en = 'Cannot send the message to conversation %1 due to:
			           |%2'; fa = 'Cannot send the message to conversation %1 due to:
			           |%2';
			           |it = 'Non è stato possibile inviare il messaggio nella discussione %1 a causa di:
			           |%2';
			           |pl = 'Nie udało się wysłać wiadomości do dyskusji %1 z powodu:
			           |%2';
			           |tr = '%1 sohbetine mesaj gönderilemedi çünkü:
			           |%2'"),
			Lower(ConversationID),
			ErrorProcessing.DetailErrorDescription(ErrorInfo));
		WriteLogEvent(
			NStr("vi = 'Thông báo từ máy chủ.Lỗi gửi thông báo';
				|ru = 'Серверные оповещения.Ошибка отправки сообщения';
				|en = 'Server notifications.Send message error'; fa = 'Server notifications.Send message error';
				|it = 'Avvisi server. Errore di invio messaggio';
				|pl = 'Powiadomienia serwerowe.Błąd wysyłki wiadomości';
				|tr = 'Sunucu bildirimleri.Mesaj gönderme hatası'",
				Common.DefaultLanguageCode()),
			EventLogInteractionSystemErrorSeverity(ErrorInfo),,, ErrorText);
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

// Delivers a message containing arbitrary data from the client to the server.
//
// Throws an exception if the delivery failed.
//
// Parameters: 
//  Data - See MessageNewData
//
// Returns:
//  Boolean - If "True", the message is accepted for delivery.
//
Function SendNotification(Data)
	
	If ValueIsFilled(Data.Recipients) Then
		SessionsNumbers = New Array;
		NumberDetails = New TypeDescription("Number");
		For Each KeyAndValue In Data.Recipients Do
			If TypeOf(KeyAndValue.Value) <> Type("Array") Then
				SessionsNumbers = Undefined;
				Break;
			EndIf;
			For Each SessionKey In KeyAndValue.Value Do
				SessionKeyParts = StrSplit(SessionKey, " ", False);
				SessionNumberAsString = ?(SessionKeyParts.Count() > 1,
					SessionKeyParts.Get(SessionKeyParts.UBound()), "0");
				SessionNumber = NumberDetails.AdjustValue(SessionNumberAsString);
				If ValueIsFilled(SessionNumber) Then
					SessionsNumbers.Add(SessionNumber);
				Else
					SessionsNumbers = Undefined;
					Break;
				EndIf;
			EndDo;
			If SessionsNumbers = Undefined Then
				Break;
			EndIf;
		EndDo;
	Else
		SessionsNumbers = Undefined;
	EndIf;
	
	Notification_Key = ServerNotificationsInternalClientServer.ServerNotificationsNotificationsKey();
	SendClientNotifications(Notification_Key, Data, SessionsNumbers);
	
	Return True;
	
EndFunction

// Allows to attach an extension that logs outgoing notifications.
Procedure SendClientNotifications(Notification_Key, Data, SessionsNumbers)
	ClientNotificationManager().SendNotification(Notification_Key, Data, SessionsNumbers);
EndProcedure

Procedure CleanUpObsoleteMessages(SendStatus)
	
	NewDate = BegOfHour(CurrentSessionDate());
	Period = 60*60;
	If SendStatus.LastMessageClearDate + Period > NewDate Then
		If SendStatus.LastMessageClearDate > NewDate Then
			SendStatus.LastMessageClearDate = NewDate;
		EndIf;
		Return;
	EndIf;
	
	Boundary = NewDate - Period;
	
	Try
		ChatsFilter = New CollaborationSystemConversationsFilter;
		ChatsFilter.Group = True;
		ChatsFilter.Displayed = False;
		FoundDiscussions = CollaborationSystem.GetConversations(ChatsFilter);
		For Each Conversation In FoundDiscussions Do
			If Not StrStartsWith(Conversation.Key, "ServerNotifications") Then
				Continue;
			EndIf;
			FilterMessages_ = New CollaborationSystemMessagesFilter;
			FilterMessages_.Conversation = Conversation.ID;
			FilterMessages_.SortDirection = SortDirection.Asc;
			Messages = CollaborationSystem.GetMessages(FilterMessages_);
			For Each Message In Messages Do
				If Message.Date < Boundary Then
					CollaborationSystem.DeleteMessage(Message.ID);
				EndIf;
			EndDo;
		EndDo;
		SendStatus.LastMessageClearDate = NewDate;
	Except
		ErrorInfo = ErrorInfo();
		WriteLogEvent(
			NStr("vi = 'Thông báo từ máy chủ.Lỗi xóa thông báo cũ';
				|ru = 'Серверные оповещения.Ошибка очистки устаревших сообщений';
				|en = 'Server notifications.An error occurred when clearing obsolete messages'; fa = 'Server notifications.An error occurred when clearing obsolete messages';
				|it = 'Avvisi server. Errore di cancellazione vecchi messaggi';
				|pl = 'Powiadomienia serwerowe.Błąd czyszczenia przestarzałych wiadomości';
				|tr = 'Sunucu bildirimleri.Eski mesajları temizleme hatası'",
				Common.DefaultLanguageCode()),
			EventLogInteractionSystemErrorSeverity(ErrorInfo),,,
			ErrorProcessing.DetailErrorDescription(ErrorInfo));
	EndTry;
	
EndProcedure

Function ServiceRecordSet(RegisterManager)
	
	RecordSet = RegisterManager.CreateRecordSet();
	RecordSet.AdditionalProperties.Insert("DontControlObjectsToDelete");
	RecordSet.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
	RecordSet.DataExchange.Recipients.AutoFill = False;
	RecordSet.DataExchange.Load = True;
	
	Return RecordSet;
	
EndFunction

Function ServiceValueManager(ManagerOfConstant)
	
	ValueManager = ManagerOfConstant.CreateValueManager();
	ValueManager.AdditionalProperties.Insert("DontControlObjectsToDelete");
	ValueManager.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
	ValueManager.DataExchange.Recipients.AutoFill = False;
	ValueManager.DataExchange.Load = True;
	
	Return ValueManager;
	
EndFunction

// Client notifications

Function ClientNotificationManager()
	
	SetSafeMode(True);
	
	// ACC:488-off - Support of new 1C:Enterprise opportunities (the executable code is safe)
	Return Eval("ClientNotifications")
	// ACC:488-on
	
EndFunction

#EndRegion
