///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region InfobaseLockAndConnectionTerminations

// Sets the infobase connection lock.
// If this function is called from a session with separator values set,
// it sets the data area session lock.
//
// Parameters:
//  MessageText           - String - text to be used in the error message
//                                      displayed when someone attempts to connect
//                                      to a locked infobase.
// 
//  KeyCode            - String - string to be added to "/uc" command line parameter
//                                       or to "uc" connection string parameter
//                                      in order to establish connection to the infobase
//                                      regardless of the lock.
//                                      Cannot be used for data area session locks.
//  WaitingForTheStartOfBlocking - Number -  delay time of the lock start in minutes.
//  LockDuration   - Number -  lock duration in minutes.
//
// Returns:
//   Boolean   - True if the lock is set successfully.
//              False if the lock cannot be set due to insufficient rights.
//
Function SetConnectionLock(Val MessageText = "", Val KeyCode = "KeyCode", // ACC:142 - Intended for backward compatibility.
	Val WaitingForTheStartOfBlocking = 0, Val LockDuration = 0) Export
	
	If Common.DataSeparationEnabled() And Common.SeparatedDataUsageAvailable() Then
		
		If Not Users.IsFullUser() Then
			Return False;
		EndIf;
		
		Block = NewConnectionLockParameters();
		Block.Use = True;
		Block.Begin = CurrentSessionDate() + WaitingForTheStartOfBlocking * 60;
		Block.Message = GenerateLockMessage(MessageText, KeyCode);
		Block.Exclusive = Users.IsFullUser(, True);
		
		If LockDuration > 0 Then 
			Block.End = Block.Begin + LockDuration * 60;
		EndIf;
		
		SetDataAreaSessionLock(Block);
		
		Return True;
	Else
		If Not Users.IsFullUser(, True) Then
			Return False;
		EndIf;
		
		Block = New SessionsLock;
		Block.Use = True;
		Block.Begin = CurrentSessionDate() + WaitingForTheStartOfBlocking * 60;
		Block.KeyCode = KeyCode;
		Block.Parameter = ServerNotifications.SessionKey();
		Block.Message = GenerateLockMessage(MessageText, KeyCode);
		
		If LockDuration > 0 Then 
			Block.End = Block.Begin + LockDuration * 60;
		EndIf;
		
		SetSessionsLock(Block);
	
		SetPrivilegedMode(True);
		SendServerNotificationAboutLockSet();
		SetPrivilegedMode(False);
		
		Return True;
	EndIf;
	
EndFunction

// Determines whether connection lock is set for a batch 
// update of the infobase configuration.
//
// Returns:
//    Boolean - True if the lock is set, otherwise False.
//
Function ConnectionsLocked() Export
	
	LockParameters = CurrentConnectionLockParameters();
	Return LockParameters.ConnectionsLocked;
	
EndFunction

// Gets the infobase connection lock parameters to be used at client side.
//
// Parameters:
//    GetSessionCount - Boolean - if True, then the SessionCount field
//                                         is filled in the returned structure.
//
// Returns:
//   Structure:
//     * Use       - Boolean - True if the lock is set, otherwise False. 
//     * Begin            - Date   - lock start date. 
//     * End             - Date   - lock end date. 
//     * Message         - String - message to user. 
//     * SessionTerminationTimeout - Number - interval in seconds.
//     * SessionCount - Number  - 0 if the GetSessionCount parameter value is False.
//     * CurrentSessionDate - Date   - a current session date.
//
Function SessionLockParameters(Val GetSessionCount = False) Export
	
	LockParameters = CurrentConnectionLockParameters();
	Return AdvancedSessionLockParameters(GetSessionCount, LockParameters);
	
EndFunction

// Removes the infobase lock.
//
// Returns:
//   Boolean   - True if the operation is successful.
//              False if the operation cannot be performed due to insufficient rights.
//
Function AllowUserAuthorization() Export
	
	If Common.DataSeparationEnabled() And Common.SeparatedDataUsageAvailable() Then
		
		If Not Users.IsFullUser() Then
			Return False;
		EndIf;
		
		LockParameters = GetDataAreaSessionLock();
		If LockParameters.Use Then
			LockParameters.Use = False;
			SetDataAreaSessionLock(LockParameters);
		EndIf;
		Return True;
		
	EndIf;
	
	If Not Users.IsFullUser(, True) Then
		Return False;
	EndIf;
	
	LockParameters = GetSessionsLock();
	If LockParameters.Use Then
		LockParameters.Use = False;
		
		SetSessionsLock(LockParameters);
		
		SetPrivilegedMode(True);
		SendServerNotificationAboutLockSet();
		SetPrivilegedMode(False);
	EndIf;
	
	Return True;
	
EndFunction

// Returns information about the current connections to the infobase.
// If necessary, writes a message to the event log.
//
// Parameters:
//    GetConnectionString - Boolean - add the connection string to the return value.
//    MessagesForEventLog - ValueList - if the parameter is not blank, the events from the list will be written
//                                                      to the event log.
//    ClusterPort - Number - a non-standard port of a server cluster.
//
// Returns:
//    Structure:
//        * HasActiveConnections - Boolean - indicates whether there are active connections.
//        * HasCOMConnections - Boolean - indicates whether there are COM connections.
//        * HasDesignerConnection - Boolean - indicates whether there is a Designer connection.
//        * HasActiveUsers - Boolean - indicates whether there are active users.
//        * InfoBaseConnectionString - String - an infobase connection string. The property is present
//                                                            only if the GetConnectionString parameter
//                                                            value is True.
//
Function ConnectionsInformation(GetConnectionString = False,
	MessagesForEventLog = Undefined, ClusterPort = 0) Export
	
	SetPrivilegedMode(True);
	
	Result = New Structure();
	Result.Insert("HasActiveConnections", False);
	Result.Insert("HasCOMConnections", False);
	Result.Insert("HasDesignerConnection", False);
	Result.Insert("HasActiveUsers", False);
	
	If InfoBaseUsers.GetUsers().Count() > 0 Then
		Result.HasActiveUsers = True;
	EndIf;
	
	If GetConnectionString Then
		Result.Insert("InfoBaseConnectionString", InfoBaseConnectionString());
	EndIf;
		
	EventLog.WriteEventsToEventLog(MessagesForEventLog);
	
	SessionsArray = GetInfoBaseSessions();
	If SessionsArray.Count() = 1 Then
		Return Result;
	EndIf;
	
	Result.HasActiveConnections = True;
	
	For Each Session In SessionsArray Do
		If Upper(Session.ApplicationName) = Upper("COMConnection") Then // COM connection.
			Result.HasCOMConnections = True;
		ElsIf Upper(Session.ApplicationName) = Upper("Designer") Then // Designer.
			Result.HasDesignerConnection = True;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#Region DataAreaSessionsLock

// Gets an empty structure with data area session lock parameters.
// 
// Returns:
//   Structure:
//     * Begin         - Date   - time the lock became active.
//     * End          - Date   - time the lock ended.
//     * Message      - String - messages for users attempting to access the locked data area.
//     * Use    - Boolean - shows if the lock is set.
//     * Exclusive   - Boolean - the lock cannot be modified by the application administrator.
//
Function NewConnectionLockParameters() Export
	
	Result = New Structure;
	Result.Insert("End", Date(1,1,1));
	Result.Insert("Begin", Date(1,1,1));
	Result.Insert("Message", "");
	Result.Insert("Use", False);
	Result.Insert("Exclusive", False);
	
	Return Result;
	
EndFunction

// Sets the data area session lock.
// 
// Parameters:
//   Parameters         - See NewConnectionLockParameters
//   LocalTime - Boolean - lock beginning time and lock end time are specified in the local session time.
//                                If the parameter is False, they are specified in universal time.
//   DataArea - Number - number of the data area to be locked.
//     When calling this procedure from a session with separator values set, only a value
//       equal to the session separator value (or unspecified) can be passed.
//     When calling this procedure from a session with separator values not set, the parameter value must be specified.
//
Procedure SetDataAreaSessionLock(Val Parameters, Val LocalTime = True, Val DataArea = -1) Export
	
	If Not Users.IsFullUser() Then
		Raise(NStr("vi = 'Không đủ quyền để thực hiện giao dịch.';
					|ru = 'Недостаточно прав для выполнения операции.';
					|en = 'Insufficient rights to perform the operation.'; fa = 'Insufficient rights to perform the operation.';
					|it = 'Diritti insufficienti per eseguire l''operazione.';
					|pl = 'Niewystarczające uprawnienia do wykonania operacji.';
					|tr = 'İşlem için gerekli yetkiler yok.'"), ErrorCategory.AccessViolation);
	EndIf;
	
	// For backward compatibility purposes.
	ConnectionsLockParameters = NewConnectionLockParameters();
	FillPropertyValues(ConnectionsLockParameters, Parameters); 
	Parameters = ConnectionsLockParameters;
	 
	If Parameters.Exclusive And Not Users.IsFullUser(, True) Then
		Raise(NStr("vi = 'Không đủ quyền để thực hiện thao tác';
					|ru = 'Недостаточно прав для выполнения операции';
					|en = 'Not enough rights to perform the operation.'; fa = 'Not enough rights to perform the operation.';
					|it = 'Diritti insufficienti per eseguire l''operazione';
					|pl = 'Niewystarczające uprawnienia do wykonania operacji';
					|tr = 'İşlem için gerekli yetkiler yok'"), ErrorCategory.AccessViolation);
	EndIf;
	
	If Common.SeparatedDataUsageAvailable() Then
		
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		SessionSeparatorValue = ModuleSaaSOperations.SessionSeparatorValue();
		
		If DataArea = -1 Then
			DataArea = SessionSeparatorValue;
		ElsIf DataArea <> SessionSeparatorValue Then
			Raise NStr("vi = 'Từ phiên làm việc có các giá trị sử dụng đường chia tách, không thể thiết lập phong tỏa phiên làm việc của vùng dữ liệu khác với vùng được sử dụng trong phiên làm việc.';
						|ru = 'Из сеанса с используемыми значениями разделителей нельзя установить блокировку сеансов области данных, отличной от используемой в сеансе.';
						|en = 'Cannot set a session lock for a data area that is different from the session data area because the session uses separator values.'; fa = 'Cannot set a session lock for a data area that is different from the session data area because the session uses separator values.';
						|it = 'Da una sessione con valori delimitatore utilizzati, non è possibile impostare un blocco delle sessioni dell''area dati diversa da quella utilizzata nella sessione.';
						|pl = 'Z sesji z używanymi wartościami separatorów nie można ustawić blokadę sesji obszaru danych, odmiennej od używanej w sesji.';
						|tr = 'Kullanılan ayırıcı değerleri olan bir oturumdan, oturumda kullanılandan farklı bir veri alanı için bir oturum kilidi ayarlayamazsınız.'");
		EndIf;
		
	ElsIf DataArea = -1 Then
		Raise NStr("vi = 'Không thể thiết lập phong tỏa phiên làm việc của vùng dữ liệu - không chỉ ra vùng làm việc.';
					|ru = 'Невозможно установить блокировку сеансов области данных - не указана область данных.';
					|en = 'Cannot lock data area sessions because the data area is not specified.'; fa = 'Cannot lock data area sessions because the data area is not specified.';
					|it = 'Impossibile impostare il blocco delle sessioni dell''area dati: l''area dati non è specificata.';
					|pl = 'Nie można ustawić blokadę sesji obszarze danych - nie określono obszar danych.';
					|tr = 'Veri alanı belirlenmediğinden dolayı, veri alanı oturumları kilitlenemedi.'");
	EndIf;
	
	SetPrivilegedMode(True);
	BeginTransaction();
	Try
		
		DataLock = New DataLock;
		LockItem = DataLock.Add("InformationRegister.DataAreaSessionLocks");
		LockItem.SetValue("DataAreaAuxiliaryData", DataArea);
		DataLock.Lock();
		
		LockSet1 = InformationRegisters.DataAreaSessionLocks.CreateRecordSet();
		LockSet1.Filter.DataAreaAuxiliaryData.Set(DataArea);
		LockSet1.Read();
		LockSet1.Clear();
		If Parameters.Use Then 
			Block = LockSet1.Add();
			Block.DataAreaAuxiliaryData = DataArea;
			Block.LockStart = ?(LocalTime And ValueIsFilled(Parameters.Begin), 
				ToUniversalTime(Parameters.Begin), Parameters.Begin);
			Block.LockEnd = ?(LocalTime And ValueIsFilled(Parameters.End), 
				ToUniversalTime(Parameters.End), Parameters.End);
			Block.LockMessage = Parameters.Message;
			Block.Exclusive = Parameters.Exclusive;
		EndIf;
		LockSet1.Write();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	SendServerNotificationAboutLockSet();
	
EndProcedure

// Gets information on the data area session lock.
// 
// Parameters:
//   LocalTime - Boolean - lock beginning time and lock end time are returned 
//                                in the local session time zone. If the parameter is False, 
//                                they are specified in universal time.
//
// Returns:
//   See NewConnectionLockParameters.
//
Function GetDataAreaSessionLock(Val LocalTime = True) Export
	
	Result = NewConnectionLockParameters();
	If Not Common.DataSeparationEnabled() Or Not Common.SeparatedDataUsageAvailable() Then
		Return Result;
	EndIf;
	
	If Not Users.IsFullUser() Then
		Raise(NStr("vi = 'Không đủ quyền để thực hiện thao tác';
					|ru = 'Недостаточно прав для выполнения операции';
					|en = 'Not enough rights to perform the operation.'; fa = 'Not enough rights to perform the operation.';
					|it = 'Diritti insufficienti per eseguire l''operazione';
					|pl = 'Niewystarczające uprawnienia do wykonania operacji';
					|tr = 'İşlem için gerekli yetkiler yok'"), ErrorCategory.AccessViolation);
	EndIf;
	
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	
	SetPrivilegedMode(True);
	LockSet1 = InformationRegisters.DataAreaSessionLocks.CreateRecordSet();
	LockSet1.Filter.DataAreaAuxiliaryData.Set(
		ModuleSaaSOperations.SessionSeparatorValue());
	LockSet1.Read();
	If LockSet1.Count() = 0 Then
		Return Result;
	EndIf;
	Block = LockSet1[0];
	Result.Begin = ?(LocalTime And ValueIsFilled(Block.LockStart), 
		ToLocalTime(Block.LockStart), Block.LockStart);
	Result.End = ?(LocalTime And ValueIsFilled(Block.LockEnd), 
		ToLocalTime(Block.LockEnd), Block.LockEnd);
	Result.Message = Block.LockMessage;
	Result.Exclusive = Block.Exclusive;
	Result.Use = True;
	If ValueIsFilled(Block.LockEnd) And CurrentSessionDate() > Block.LockEnd Then
		Result.Use = False;
	EndIf;
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

Function IsSubsystemUsed() Export
	
	// See also: IBConnectionsClient.IsSubsystemUsed
	Return Not Common.DataSeparationEnabled();
	
EndFunction

// Returns a text string containing the active infobase connection list.
// The connection names are separated by line breaks.
//
// Parameters:
//  Message - String - string to pass.
//
// Returns:
//   String - connection names.
//
Function ActiveSessionsMessage() Export
	
	Message = NStr("vi = 'Không thể ngắt phiên làm việc:';
					|ru = 'Не удалось отключить сеансы:';
					|en = 'Cannot close sessions:'; fa = 'Cannot close sessions:';
					|it = 'Non è stato possibile disabilitare le sessioni:';
					|pl = 'Nie udało się wyłączyć sesje:';
					|tr = 'Oturumlar devre dışı bırakılamaz:'");
	CurrentSessionNumber = InfoBaseSessionNumber();
	For Each Session In GetInfoBaseSessions() Do
		If Session.SessionNumber <> CurrentSessionNumber Then
			Message = Message + Chars.LF + "• " + Session;
		EndIf;
	EndDo;
	
	Return Message;
	
EndFunction

// Gets the number of active infobase sessions.
//
// Parameters:
//   IncludeConsole - Boolean - if False, the server cluster console sessions are excluded.
//                               The server cluster console sessions do not prevent execution 
//                               of administrative operations (enabling the exclusive mode, and so on).
//
// Returns:
//   Number - number of active infobase sessions.
//
Function InfobaseSessionsCount(IncludeConsole = True, IncludeBackgroundJobs = True) Export
	
	IBSessions = GetInfoBaseSessions();
	If IncludeConsole And IncludeBackgroundJobs Then
		Return IBSessions.Count();
	EndIf;
	
	Result = 0;
	
	For Each IBSession In IBSessions Do
		
		If Not IncludeConsole And IBSession.ApplicationName = "SrvrConsole"
			Or Not IncludeBackgroundJobs And IBSession.ApplicationName = "BackgroundJob" Then
			Continue;
		EndIf;
		
		Result = Result + 1;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Determines the number of infobase sessions and checks if there are sessions
// that cannot be forcibly disabled. Generates error message
// text.
//
Function BlockingSessionsInformation(MessageText = "") Export
	
	BlockingSessionsInformation = New Structure;
	
	CurrentSessionNumber = InfoBaseSessionNumber();
	InfobaseSessions = GetInfoBaseSessions();
	
	HasBlockingSessions = False;
	If Common.FileInfobase() Then
		ActiveSessionNames = "";
		For Each Session In InfobaseSessions Do
			If Session.SessionNumber <> CurrentSessionNumber
				And Session.ApplicationName <> "1CV8"
				And Session.ApplicationName <> "1CV8C"
				And Session.ApplicationName <> "WebClient" Then
				ActiveSessionNames = ActiveSessionNames + Chars.LF + "• " + Session;
				HasBlockingSessions = True;
			EndIf;
		EndDo;
	EndIf;
	
	BlockingSessionsInformation.Insert("HasBlockingSessions", HasBlockingSessions);
	BlockingSessionsInformation.Insert("SessionCount", InfobaseSessions.Count());
	
	If HasBlockingSessions Then
		Message = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đang có các phiên làm việc hiện tại với ứng dụng
			|mà không thể buộc kết thúc:
			|%1
			|%2';
			|ru = 'Имеются активные сеансы работы с приложением,
			|которые не могут быть завершены принудительно:
			|%1
			|%2';
			|en = 'There are active sessions
			|that cannot be closed:
			|%1
			|%2'; fa = 'There are active sessions
			|that cannot be closed:
			|%1
			|%2';
			|it = 'Имеются активные сеансы работы с приложением,
			|которые не могут быть завершены принудительно:
			|%1
			|%2';
			|pl = 'There are active sessions
			|that cannot be closed:
			|%1
			|%2';
			|tr = 'Uygulamada kapatılmaya zorlanamayacak aktif oturumlar var:
			|
			|%1
			|%2'"),
			ActiveSessionNames, MessageText);
		BlockingSessionsInformation.Insert("MessageText", Message);
		
	EndIf;
	
	Return BlockingSessionsInformation;
	
EndFunction

#Region ConfigurationSubsystemsEventHandlers

// See SaaSOperationsOverridable.OnFillIIBParametersTable.
Procedure OnFillIIBParametersTable(Val ParametersTable) Export
	
	If Not IsSubsystemUsed() Then
		Return;
	EndIf;
	
	If Common.SubsystemExists("CloudTechnology.Core") Then
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		ModuleSaaSOperations.AddConstantToInformationSecurityParameterTable(ParametersTable, "LockMessageOnConfigurationUpdate");
	EndIf;
	
EndProcedure

// See CommonOverridable.OnAddClientParametersOnStart.
Procedure OnAddClientParametersOnStart(Parameters) Export
	
	If Not IsSubsystemUsed() Then
		Return;
	EndIf;
	
	LockParameters = CurrentConnectionLockParameters();
	Parameters.Insert("SessionLockParameters", New FixedStructure(AdvancedSessionLockParameters(False, LockParameters)));
	
	If Not LockParameters.ConnectionsLocked
		Or Not Common.DataSeparationEnabled()
		Or Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	// The following code is intended for locked data areas only.
	If InfobaseUpdate.InfobaseUpdateInProgress() 
		And Users.IsFullUser() Then
		// The app administrator can sign in even if the data area is locked due to an incomplete update.
		// By doing that, the administrator initiates the area update.
		Return; 
	EndIf;
	
	CurrentMode = LockParameters.CurrentDataAreaMode;
	
	If ValueIsFilled(CurrentMode.End) Then
		If ValueIsFilled(CurrentMode.Message) Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Người quản trị ứng dụng đã chặn người sử dụng làm việc trong kỳ từ %1 đến %2 vì lý do:
					|%3.';
					|ru = 'Администратором приложения установлена блокировка работы пользователей на период с %1 по %2 по причине:
					|%3.';
					|en = 'The application administrator locked the application for the period from %1 to %2. Reason:
					|%3.'; fa = 'The application administrator locked the application for the period from %1 to %2. Reason:
					|%3.';
					|it = 'Dall''amministratore dell''applicazione è stato installato il blocco del lavoro degli utenti per un periodo dal%1 al%2 a causa di:
					|%3.';
					|pl = 'Administrator aplikacji ustawił blokowanie pracy użytkowników na okres od %1 do %2 z powodu:
					|%3.';
					|tr = '%1 - %2 arası yönetici tarafından kullanıcıların çalışması şu sebeple kilitlenmiştir:
					|%3'"), CurrentMode.Begin, CurrentMode.End, CurrentMode.Message);
		Else
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Người quản trị ứng dụng đã chặn người sử dụng làm việc trong kỳ từ %1 đến %2 để thực hiện các công việc thường kỳ.';
					|ru = 'Администратором приложения установлена блокировка работы пользователей на период с %1 по %2 для проведения регламентных работ.';
					|en = 'The application administrator locked the application for the period from %1 to %2 for scheduled maintenance.'; fa = 'The application administrator locked the application for the period from %1 to %2 for scheduled maintenance.';
					|it = 'Dall''amministratore dell''applicazione è stato installato il blocco del lavoro degli utenti per un periodo dal%1 al%2 per l''esecuzione dei lavori di routine.';
					|pl = 'Administrator aplikacji ustawił blokowanie pracy użytkowników na okres od %1 do %2 w celu przeprowadzenia robót reglamentowanych.';
					|tr = '%1 - %2 arası yönetici tarafından kullanıcıların çalışması planlı işlerin yürütülmesi için kilitlenmiştir.'"), 
				CurrentMode.Begin, CurrentMode.End);
		EndIf;		
	Else
		If ValueIsFilled(CurrentMode.Message) Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Người quản trị ứng dụng đã chặn người sử dụng làm việc trong kỳ từ %1 vì lý do:
					|%2.';
					|ru = 'Администратором приложения установлена блокировка работы пользователей на период с %1 по причине:
					|%2.';
					|en = 'The application administrator locked the application at %1. Reason:
					|%2.'; fa = 'The application administrator locked the application at %1. Reason:
					|%2.';
					|it = 'Dall''amministratore dell''applicazione è stato installato il blocco del lavoro degli utenti per un periodo dal%1  a causa di:
					| %2,';
					|pl = 'Administrator aplikacji ustawił blokowanie pracy użytkowników na okres %1 z powodu:
					|%2.';
					|tr = '%1''dan itibaren yönetici tarafından kullanıcıların çalışması şu sebeple kilitlenmiştir:
					|%2.'"), CurrentMode.Begin, CurrentMode.Message);
		Else
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Người quản trị ứng dụng đã chặn người sử dụng làm việc trong kỳ từ %1 để thực hiện các công việc thường kỳ.';
					|ru = 'Администратором приложения установлена блокировка работы пользователей на период с %1 для проведения регламентных работ.';
					|en = 'The application administrator locked the application at %1 due for scheduled maintenance.'; fa = 'The application administrator locked the application at %1 due for scheduled maintenance.';
					|it = 'Dall''amministratore dell''applicazione è stato installato il blocco del lavoro degli utenti per un periodo dal%1 per l''esecuzione dei lavori di routine.';
					|pl = 'Administrator aplikacji ustawił blokowanie pracy użytkowników na okres od %1 w celu przeprowadzenia robót reglamentowanych.';
					|tr = '%1''dan itibaren yönetici tarafından kullanıcıların çalışması planlı işlerin yürütülmesi için kilitlenmiştir.'"), 
				CurrentMode.Begin);
		EndIf;		
	EndIf;
	Parameters.Insert("DataAreaSessionsLocked", MessageText + Chars.LF + Chars.LF + NStr("vi = 'Ứng dụng tạm thời không khả dụng.';
																						|ru = 'Приложение временно недоступно.';
																						|en = 'The application is temporarily unavailable.'; fa = 'The application is temporarily unavailable.';
																						|it = 'L''applicazione temporaneamente non è disponibile.';
																						|pl = 'Aplikacja jest czasowo niedostępna';
																						|tr = 'Uygulama geçici olarak kullanılamıyor.'"));
	LogonMessageText = "";
	If Users.IsFullUser() Then
		LogonMessageText = MessageText + Chars.LF + Chars.LF + NStr("vi = 'Đăng nhập vào ứng dụng bị chặn?';
																	|ru = 'Войти в заблокированное приложение?';
																	|en = 'Do you want to sign in to the locked application?'; fa = 'Do you want to sign in to the locked application?';
																	|it = 'Entrare nella posizione bloccata?';
																	|pl = 'Wejść do zablokowanej aplikacji?';
																	|tr = 'Kilitli uygulamaya girilsin mi?'");
	EndIf;
	Parameters.Insert("PromptToAuthorize", LogonMessageText);
	If (Users.IsFullUser() And Not CurrentMode.Exclusive) 
		Or Users.IsFullUser(, True) Then
		
		Parameters.Insert("CanUnlock", True);
	Else
		Parameters.Insert("CanUnlock", False);
	EndIf;
	
EndProcedure

// See CommonOverridable.OnAddClientParameters.
Procedure OnAddClientParameters(Parameters) Export
	
	If Not IsSubsystemUsed() Then
		Return;
	EndIf;
	
	Parameters.Insert("SessionLockParameters", New FixedStructure(SessionLockParameters()));
	
EndProcedure

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	Types.Add(Metadata.InformationRegisters.DataAreaSessionLocks);
	
EndProcedure

// Parameters:
//   ToDoList - See ToDoListServer.ToDoList.
//
Procedure OnFillToDoList(ToDoList) Export
	
	If Not IsSubsystemUsed() Then
		Return;
	EndIf;
	
	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	If Not AccessRight("DataAdministration", Metadata)
		Or ModuleToDoListServer.UserTaskDisabled("SessionsLock") Then
		Return;
	EndIf;
	
	// The procedure can be called only if the "To-do list" subsystem is integrated.
	// Therefore, don't check if the subsystem is integrated.
	Sections = ModuleToDoListServer.SectionsForObject(Metadata.DataProcessors.ApplicationLock.FullName());
	
	LockParameters = SessionLockParameters(False);
	CurrentSessionDate = CurrentSessionDate();
	
	If LockParameters.Use Then
		If CurrentSessionDate < LockParameters.Begin Then
			If LockParameters.End <> Date(1, 1, 1) Then
				Message = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đã lập kế hoạch từ %1 đến %2';
																						|ru = 'Запланирована с %1 по %2';
																						|en = 'Scheduled from %1 to %2'; fa = 'Scheduled from %1 to %2';
																						|it = 'Pianificata da %1 a %2';
																						|pl = 'Zaplanowane od %1 do %2';
																						|tr = '%1 ile %2 arası için planlandı'"),
					Format(LockParameters.Begin, "DLF=DT"), Format(LockParameters.End, "DLF=DT"));
			Else
				Message = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đã lập kế hoạch từ %1';
																						|ru = 'Запланирована с %1';
																						|en = 'Scheduled from %1'; fa = 'Scheduled from %1';
																						|it = 'Pianificata da %1';
																						|pl = 'Zaplanowane od %1';
																						|tr = '%1 itibaren planlandı'"), Format(LockParameters.Begin, "DLF=DT"));
			EndIf;
			Importance = False;
		ElsIf LockParameters.End <> Date(1, 1, 1) And CurrentSessionDate > LockParameters.End And LockParameters.Begin <> Date(1, 1, 1) Then
			Importance = False;
			Message = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Không có hiệu lực (hết hạn %1)';
																					|ru = 'Не действует (истек срок %1)';
																					|en = 'Inactive (expired on %1)'; fa = 'Inactive (expired on %1)';
																					|it = 'Non valido (scaduto %1)';
																					|pl = 'Nieważny (wygasł termin %1)';
																					|tr = 'Geçerli değil (süresi doldu%1)'"), Format(LockParameters.End, "DLF=DT"));
		Else
			If LockParameters.End <> Date(1, 1, 1) Then
				Message = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'từ %1 đến %2';
																						|ru = 'с %1 по %2';
																						|en = 'from %1 to %2'; fa = 'from %1 to %2';
																						|it = 'da %1 fino a %2';
																						|pl = 'od %1 do %2';
																						|tr = '%1 itibaren %2 kadar'"),
					Format(LockParameters.Begin, "DLF=DT"), Format(LockParameters.End, "DLF=DT"));
			Else
				Message = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'từ %1';
																						|ru = 'с %1';
																						|en = 'from %1'; fa = 'from %1';
																						|it = 'da %1';
																						|pl = 'od %1';
																						|tr = 'itibaren %1'"), 
					Format(LockParameters.Begin, "DLF=DT"));
			EndIf;
			Importance = True;
		EndIf;
	Else
		Message = NStr("vi = 'Không có hiệu lực';
						|ru = 'Не действует';
						|en = 'Inactive'; fa = 'غیرفعال';
						|it = 'Non valido';
						|pl = 'Nie obowiązuje';
						|tr = 'Geçerli değil'");
		Importance = False;
	EndIf;

	
	For Each Section In Sections Do
		
		CaseFileID = "SessionsLock" + StrReplace(Section.FullName(), ".", "");
		
		ToDoItem = ToDoList.Add();
		ToDoItem.Id  = CaseFileID;
		ToDoItem.HasToDoItems       = LockParameters.Use;
		ToDoItem.Presentation  = NStr("vi = 'Chặn người sử dụng làm việc';
										|ru = 'Блокировка работы пользователей';
										|en = 'Deny user access'; fa = 'ممنوعیت دسترسی کاربران';
										|it = 'Il blocco di lavoro degli utenti';
										|pl = 'Blokada pracy użytkownika';
										|tr = 'Kullanıcı çalışmasını kilitleme'");
		ToDoItem.Form          = "DataProcessor.ApplicationLock.Form";
		ToDoItem.Important         = Importance;
		ToDoItem.Owner       = Section;
		
		ToDoItem = ToDoList.Add();
		ToDoItem.Id  = "SessionLockDetails";
		ToDoItem.HasToDoItems       = LockParameters.Use;
		ToDoItem.Presentation  = Message;
		ToDoItem.Owner       = CaseFileID; 
		
	EndDo;
	
EndProcedure

// See CommonOverridable.OnAddServerNotifications
Procedure OnAddServerNotifications(Notifications) Export
	
	If Not IsSubsystemUsed() Then
		Return;
	EndIf;
	
	Notification = ServerNotifications.NewServerNotification(
		"StandardSubsystems.UsersSessions.SessionsLock");
	Notification.NotificationSendModuleName  = "IBConnections";
	Notification.NotificationReceiptModuleName = "IBConnectionsClient";
	Notification.VerificationPeriod = 300;
	
	Notifications.Insert(Notification.Name, Notification);
	
EndProcedure

// See StandardSubsystemsServer.OnSendServerNotification
Procedure OnSendServerNotification(NameOfAlert, ParametersVariants) Export
	
	SendServerNotificationAboutLockSet(True);
	
EndProcedure

// See CommonOverridable.OnReceiptRecurringClientDataOnServer
Procedure OnReceiptRecurringClientDataOnServer(Parameters, Results) Export
	
	If Not IsSubsystemUsed() Then
		Return;
	EndIf;
	
	ParameterName = "StandardSubsystems.UsersSessions.SessionsLock";
	SessionLockParameters = SessionsLockSettingsWhenSet();
	
	If SessionLockParameters <> Undefined
	   And SessionLockParameters.Use Then
		
		Results.Insert(ParameterName, SessionLockParameters);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Procedure SendServerNotificationAboutLockSet(OnSendServerNotification = False) Export
	
	Try
		SessionLockParameters = SessionsLockSettingsWhenSet();
		If SessionLockParameters = Undefined Then
			SessionLockParameters = New Structure("Use", False);
		EndIf;
		
		If SessionLockParameters.Use
		 Or Not OnSendServerNotification Then
			
			ServerNotifications.SendServerNotification(
				"StandardSubsystems.UsersSessions.SessionsLock",
				SessionLockParameters, Undefined, Not OnSendServerNotification);
		EndIf;
	Except
		If OnSendServerNotification Then
			Raise;
		EndIf;
		WriteLogEvent(EventLogEvent(),
			EventLogLevel.Error,,,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

#Region Other

// Returns session lock message text.
//
// Parameters:
//  Message - String - message for the lock.
//  KeyCode - String - infobase access key code.
//
// Returns:
//   String - lock message.
//
Function GenerateLockMessage(Val Message, Val KeyCode) Export
	
	AdministrationParameters = StandardSubsystemsServer.AdministrationParameters();
	FileModeFlag = False;
	IBPath = IBConnectionsClientServer.InfobasePath(FileModeFlag, AdministrationParameters.ClusterPort);
	InfobasePathString = ?(FileModeFlag = True, "/F", "/S") + IBPath;
	MessageText = "";
	If Not IsBlankString(Message) Then
		MessageText = Message + Chars.LF + Chars.LF;
	EndIf;
	
	ParameterName = "AllowUserAuthorization";
	If Common.DataSeparationEnabled() And Common.SeparatedDataUsageAvailable() Then
		MessageText = MessageText + NStr("vi = '%1
			|Để cho phép người sử dụng làm việc, có thể mở ứng dụng với tham số %2. Ví dụ:
			|http://<địa chỉ web của máy chủ>/?C=%2';
			|ru = '%1
			|Для разрешения работы пользователей можно открыть приложение с параметром %2. Например:
			|https://<веб-адрес сервера>/?C=%2';
			|en = '%1
			|To allow user access, you can open the application with the parameter %2. For example:
			|https://<server web address>/?C=%2'; fa = '%1
			|To allow user access, you can open the application with the parameter %2. For example:
			|https://<server web address>/?C=%2';
			|it = '%1
			|To allow user access, you can open the application with the parameter %2. For example:
			|https://<server web address>/?C=%2';
			|pl = '%1
			|To allow user access, you can open the application with the parameter %2. For example:
			|https://<server web address>/?C=%2';
			|tr = '%1
			|Kullanıcıların işlem yapmasına izin verebilmek için uygulamayı %2 parametresi ile açabilirsiniz. Örnek:
			|https://<веб-адрес сервера>/?C=%2'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, 
			IBConnectionsClientServer.TextForAdministrator(), ParameterName);
	Else
		MessageText = MessageText + NStr("ru = '%1
			|Для того чтобы разрешить работу пользователей, воспользуйтесь консолью кластера серверов или запустите ""1С:Предприятие"" с параметрами:
			|ENTERPRISE %2 /C %3 /UC %4';
			|vi = '%1
			|To allow user access, use the server cluster console or run 1C:Enterprise with the following parameters:
			|ENTERPRISE %2 /C %3 /UC %4';
			|en = '%1
			|To allow user access, use the server cluster console or run 1C:Enterprise with the following parameters:
			|ENTERPRISE %2 /C %3 /UC %4'; fa = '%1
			|To allow user access, use the server cluster console or run 1C:Enterprise with the following parameters:
			|ENTERPRISE %2 /C %3 /UC %4';
			|it = '%1
			|To allow user access, use the server cluster console or run 1C:Enterprise with the following parameters:
			|ENTERPRISE %2 /C %3 /UC %4';
			|pl = '%1
			|To allow user access, use the server cluster console or run 1C:Enterprise with the following parameters:
			|ENTERPRISE %2 /C %3 /UC %4';
			|tr = '%1
			|Kullanıcıların çalışmasına izin vermek için sunucu kümesi konsolunu kullanın veya ""1C:Enterprise"" uygulamasını şu parametrelerle başlatın:
			|ENTERPRISE %2 /C %3 /UC %4'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, IBConnectionsClientServer.TextForAdministrator(),
			InfobasePathString, ParameterName, "KeyCode");
	EndIf;
	
	Return MessageText;
	
EndFunction

// Returns the flag specifying whether a connection lock is set for a specific date.
//
// Parameters:
//  CurrentMode - SessionsLock - sessions lock.
//  CurrentDate - Date - date to check.
//
// Returns:
//  Boolean - True if set.
//
Function ConnectionsLockedForDate(CurrentMode, CurrentDate)
	
	Return (CurrentMode.Use And CurrentMode.Begin <= CurrentDate 
		And (Not ValueIsFilled(CurrentMode.End) Or CurrentDate <= CurrentMode.End));
	
EndFunction

// See the description in the SessionLockParameters function.
//
// Parameters:
//    GetSessionCount - Boolean
//    LockParameters - See CurrentConnectionLockParameters
//
Function AdvancedSessionLockParameters(Val GetSessionCount, LockParameters)
	
	If LockParameters.IBConnectionLockSetForDate Then
		CurrentMode = LockParameters.CurrentIBMode;
	ElsIf LockParameters.DataAreaConnectionLockSetForDate Then
		CurrentMode = LockParameters.CurrentDataAreaMode;
	ElsIf LockParameters.CurrentIBMode.Use Then
		CurrentMode = LockParameters.CurrentIBMode;
	Else
		CurrentMode = LockParameters.CurrentDataAreaMode;
	EndIf;
	
	SetPrivilegedMode(True);
	
	Result = New Structure;
	Result.Insert("Use", CurrentMode.Use);
	Result.Insert("Begin", CurrentMode.Begin);
	Result.Insert("End", CurrentMode.End);
	Result.Insert("Message", CurrentMode.Message);
	Result.Insert("SessionTerminationTimeout", 15 * 60);
	Result.Insert("SessionCount", ?(GetSessionCount, InfobaseSessionsCount(), 0));
	Result.Insert("CurrentSessionDate", LockParameters.CurrentDate);
	Result.Insert("RestartOnCompletion", True);
	
	IBConnectionsOverridable.OnDetermineSessionLockParameters(Result);
	
	Return Result;
	
EndFunction

// Parameters:
//   ShouldReturnUndefinedIfUnspecified - Boolean
// 
// Returns:
//   Structure:
//   * IBConnectionLockSetForDate - Boolean
//   * CurrentDataAreaMode - See NewConnectionLockParameters
//   * CurrentIBMode - SessionsLock
//   * CurrentDate - Date
//
Function CurrentConnectionLockParameters()
	
	CurrentDate = CurrentDate(); // ACC:143 - CurrentSessionDate is not used since there's a lock in the server time zone.
	
	SetPrivilegedMode(True);
	CurrentIBMode = GetSessionsLock();
	CurrentDataAreaMode = GetDataAreaSessionLock();
	SetPrivilegedMode(False);
	
	IBLockedForDate = ConnectionsLockedForDate(CurrentIBMode, CurrentDate);
	AreaLockedAtDate = ConnectionsLockedForDate(CurrentDataAreaMode, CurrentDate);
	ConnectionsLocked = IBLockedForDate Or AreaLockedAtDate;
	
	Parameters = New Structure;
	Parameters.Insert("CurrentDate", CurrentDate);
	Parameters.Insert("CurrentIBMode", CurrentIBMode);
	Parameters.Insert("CurrentDataAreaMode", CurrentDataAreaMode);
	Parameters.Insert("IBConnectionLockSetForDate", IBLockedForDate);
	Parameters.Insert("DataAreaConnectionLockSetForDate", AreaLockedAtDate);
	Parameters.Insert("ConnectionsLocked", ConnectionsLocked);
	
	Return Parameters;
	
EndFunction

// Returns:
//   See SessionLockParameters
//
Function SessionsLockSettingsWhenSet()
	
	LockParameters = CurrentConnectionLockParameters();
	
	Result = AdvancedSessionLockParameters(False, LockParameters);
	If Not Result.Use Then
		Return Undefined;
	EndIf;
	
	If LockParameters.IBConnectionLockSetForDate Then
		Result.Insert("Parameter", LockParameters.CurrentIBMode.Parameter);
	EndIf;
	
	Return Result;
	
EndFunction

// Returns a string constant for generating event log messages.
//
// Returns:
//   String - an event description for the event log.
//
Function EventLogEvent() Export
	
	Return NStr("vi = 'Kết thúc công việc người sử dụng';
				|ru = 'Завершение работы пользователей';
				|en = 'User sessions'; fa = 'جلسات کاربر';
				|it = 'Arresto del lavoro degli utenti';
				|pl = 'Zakończenie pracy użytkowników';
				|tr = 'Kullanıcı oturumlarının tamamlanması'", Common.DefaultLanguageCode());
	
EndFunction

#EndRegion

#EndRegion