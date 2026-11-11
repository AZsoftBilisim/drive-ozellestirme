///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

#Region SessionAndJobLock

// See ClusterAdministration.InfobaseSessionAndJobLock
Function InfobaseSessionAndJobLock(Val ClusterAdministrationParameters, Val IBAdministrationParameters) Export
	
	ServerAgent = ServerAgent(ClusterAdministrationParameters);
	ServerCluster = ServerCluster(ServerAgent, ClusterAdministrationParameters);
	ClusterBase = ClusterBase(ServerCluster, IBAdministrationParameters);
	Result = SessionAndScheduleJobLockProperties(ClusterBase);
	Return Result;
	
EndFunction

// See ClusterAdministration.SetInfobaseSessionAndJobLock
Procedure SetInfobaseSessionAndJobLock(Val ClusterAdministrationParameters, Val IBAdministrationParameters, Val SessionAndJobLockProperties) Export
		
	LockToSet = Common.CopyRecursive(SessionAndJobLockProperties, False);
	DateEmpty = Date(1, 1, 1);
	SetDefault(LockToSet.DateFrom1, DateEmpty);
	SetDefault(LockToSet.DateTo, DateEmpty);

	ServerAgent = ServerAgent(ClusterAdministrationParameters);	
	ServerCluster = ServerCluster(ServerAgent, ClusterAdministrationParameters);		
	ClusterBase = ClusterBase(ServerCluster, IBAdministrationParameters);

	SetProperty(ClusterBase.SessionsLockEnabled, LockToSet, "SessionsLock");
	SetProperty(ClusterBase.LockBeginTime, LockToSet, "DateFrom1");
	SetProperty(ClusterBase.LockEndTime, LockToSet, "DateTo");
	SetProperty(ClusterBase.LockMessage, LockToSet, "Message");
	SetProperty(ClusterBase.SessionStartPermissionCode, LockToSet, "KeyCode");
	SetProperty(ClusterBase.LockParameter, LockToSet, "LockParameter");
	SetProperty(ClusterBase.LockScheduledJobs, LockToSet, "LockScheduledJobs");	
	
	ClusterBase.Write();
EndProcedure

// See ClusterAdministration.CheckAdministrationParameters
Procedure CheckAdministrationParameters(Val ClusterAdministrationParameters, Val IBAdministrationParameters = Undefined,
	CheckInfobaseAdministrationParameters = True,
	CheckClusterAdministrationParameters = True) Export
	
	If CheckClusterAdministrationParameters Or CheckInfobaseAdministrationParameters Then
		ServerAgent = ServerAgent(ClusterAdministrationParameters);	
		ServerCluster = ServerCluster(ServerAgent, ClusterAdministrationParameters);		
	EndIf;
	If CheckInfobaseAdministrationParameters Then
		ClusterBase(ServerCluster, IBAdministrationParameters);
	EndIf;	
EndProcedure

#EndRegion

#Region LockScheduledJobs

// See ClusterAdministration.InfobaseScheduledJobLock
Function InfobaseScheduledJobLock(Val ClusterAdministrationParameters, Val IBAdministrationParameters) Export	
	ServerAgent = ServerAgent(ClusterAdministrationParameters);	
	ServerCluster = ServerCluster(ServerAgent, ClusterAdministrationParameters);		
	ClusterBase = ClusterBase(ServerCluster, IBAdministrationParameters);
	Return ClusterBase.LockScheduledJobs;
EndFunction

// See ClusterAdministration.SetInfobaseScheduledJobLock
Procedure SetInfobaseScheduledJobLock(Val ClusterAdministrationParameters, Val IBAdministrationParameters, Val LockScheduledJobs) Export
	ServerAgent = ServerAgent(ClusterAdministrationParameters);	
	ServerCluster = ServerCluster(ServerAgent, ClusterAdministrationParameters);
	ClusterBase = ClusterBase(ServerCluster, IBAdministrationParameters);
	If ClusterBase.LockScheduledJobs <> LockScheduledJobs Then
		ClusterBase.LockScheduledJobs = LockScheduledJobs;
		ClusterBase.Write();
	EndIf;
EndProcedure

#EndRegion

#Region InfobaseSessions

// See ClusterAdministration.InfobaseSessions
Function InfobaseSessions(Val ClusterAdministrationParameters, Val IBAdministrationParameters, Val Filter = Undefined) Export
	
	ServerAgent = ServerAgent(ClusterAdministrationParameters);	
	ServerCluster = ServerCluster(ServerAgent, ClusterAdministrationParameters);
	ClusterBase = ClusterBase(ServerCluster, IBAdministrationParameters);
	
	ClientApplicationsIDs = ClusterAdministration.ClientApplicationsIDs();		
	ClusterAdministration.AddFilterCondition(Filter, "ClientApplicationID", ComparisonType.InList, ClientApplicationsIDs);
	
	Result = SessionsList(ServerAgent, ServerCluster, ClusterBase, Filter);
	Return Result;

EndFunction

// See ClusterAdministration.DeleteInfobaseSessions
Procedure DeleteInfobaseSessions(Val ClusterAdministrationParameters, Val IBAdministrationParameters, Val Filter = Undefined) Export
	
	ServerAgent = ServerAgent(ClusterAdministrationParameters);	
	ServerCluster = ServerCluster(ServerAgent, ClusterAdministrationParameters);
	ClusterBase = ClusterBase(ServerCluster, IBAdministrationParameters);
	
	MessageToUsers = NStr("ru = 'Сеанс завершен администратором';
							|vi = 'The session is closed by the administrator';
							|en = 'The session is closed by the administrator'; fa = 'The session is closed by the administrator';
							|it = 'The session is closed by the administrator';
							|pl = 'The session is closed by the administrator';
							|tr = 'Oturum yönetici tarafından sonlandırıldı'");
	
	AttemptsNumber = 4;
	AreAllSessionsCompleted = False;
	CompletionMarks = New Map();
	HadErrors = False;
	For CurrentAttempt = 1 To AttemptsNumber Do
		SessionsList = SessionsList(ServerAgent, ServerCluster, ClusterBase, Filter, True);
		If Not ValueIsFilled(SessionsList) Then
			AreAllSessionsCompleted = True;
			Break;
		EndIf;
		For Each Session In SessionsList Do
			Try
				SessionObject = Session.SessionObject; // AdministrationSession
				SessionNumber = SessionObject.SessionNumber;
				HasCompletionMark = CompletionMarks.Get(SessionObject.SessionID) = True;
				If Not HasCompletionMark Then
					SessionObject.TerminateSession(MessageToUsers);
					CompletionMarks.Insert(SessionObject.SessionID, True);
				EndIf;
			Except
				ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
				Comment = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Ошибка завершения сеанса %1: %2';
																						|vi = 'An error occurred when closing session %1: %2';
																						|en = 'An error occurred when closing session %1: %2'; fa = 'An error occurred when closing session %1: %2';
																						|it = 'An error occurred when closing session %1: %2';
																						|pl = 'An error occurred when closing session %1: %2';
																						|tr = 'Oturum sonlandırma hatası %1: %2'"),
					SessionNumber, ErrorDescription);
				WriteErrorToEventLog(Comment);
				HadErrors = True;
				Continue;
			EndTry;
		EndDo;
		
		IsIntermediateAttempt = CurrentAttempt > 1 And CurrentAttempt < AttemptsNumber;
		If IsIntermediateAttempt Then
			Pause(CurrentAttempt);
		EndIf;
	EndDo;	
	
	If Not AreAllSessionsCompleted Then
		If HadErrors Then
			ExceptionText = NStr("ru = 'Не удалось завершить сеансы. См. журнал регистрации.';
								|vi = 'Cannot close the sessions. See the event log.';
								|en = 'Cannot close the sessions. See the event log.'; fa = 'Cannot close the sessions. See the event log.';
								|it = 'Cannot close the sessions. See the event log.';
								|pl = 'Cannot close the sessions. See the event log.';
								|tr = 'Oturumlar sonlandırılamadı. Olay günlüğüne bakın.'");
		Else
			ExceptionText = NStr("ru = 'Не удалось завершить сеансы.';
								|vi = 'Cannot close the sessions.';
								|en = 'Cannot close the sessions.'; fa = 'Cannot close the sessions.';
								|it = 'Cannot close the sessions.';
								|pl = 'Cannot close the sessions.';
								|tr = 'Oturumlar sonlandırılamadı.'");
		EndIf;
		Raise ExceptionText;
	EndIf;
	
EndProcedure

#EndRegion

#Region InfobaseConnections

// See ClusterAdministration.InfobaseConnections
Function InfobaseConnections(Val ClusterAdministrationParameters, Val IBAdministrationParameters, Val Filter = Undefined) Export
	ServerAgent = ServerAgent(ClusterAdministrationParameters);	
	ServerCluster = ServerCluster(ServerAgent, ClusterAdministrationParameters);
	ClusterBase = ClusterBase(ServerCluster, IBAdministrationParameters);
	Result = ListOfConnections(ServerAgent, ServerCluster, ClusterBase, Filter);
	Return Result;
EndFunction

// See ClusterAdministration.TerminateInfobaseConnections
Procedure TerminateInfobaseConnections(Val ClusterAdministrationParameters, Val IBAdministrationParameters, Val Filter = Undefined) Export
	
	ServerAgent = ServerAgent(ClusterAdministrationParameters);	
	ServerCluster = ServerCluster(ServerAgent, ClusterAdministrationParameters);
	ClusterBase = ClusterBase(ServerCluster, IBAdministrationParameters);
	
	ClientApplicationsIDs = ClusterAdministration.ClientApplicationsIDs();
	ClusterAdministration.AddFilterCondition(Filter, "ApplicationName", ComparisonType.InList, ClientApplicationsIDs);
		
	AttemptsNumber = 4;
	AllConnectionsTerminated = False;
	DisableMarks = New Map();
	HadErrors = False;
	For CurrentAttempt = 1 To AttemptsNumber Do
		ListOfConnections = ListOfConnections(ServerAgent, ServerCluster, ClusterBase, Filter, False); // Array of AdministrationConnection 
		If Not ValueIsFilled(ListOfConnections) Then
			AllConnectionsTerminated = True;
			Break;
		EndIf;

		For Each Join In ListOfConnections Do
			Try
				ConnectionNumber = Join.ConnectionNumber;
				HasDisableMark = DisableMarks.Get(Join.ConnectionID) = True;
				If Not HasDisableMark Then
					Join.Disconnect();
					DisableMarks.Insert(Join.ConnectionID, True);
				EndIf;
			Except
				ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
				Comment = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Ошибка отключения соединения %1: %2';
																						|vi = 'Error in disconnection %1: %2';
																						|en = 'Error in disconnection %1: %2'; fa = 'Error in disconnection %1: %2';
																						|it = 'Error in disconnection %1: %2';
																						|pl = 'Error in disconnection %1: %2';
																						|tr = 'Bağlantı kesme hatası %1: %2'"),
					ConnectionNumber, ErrorDescription);
				WriteErrorToEventLog(Comment);
				HadErrors = True;
				Continue;
			EndTry;
		EndDo;
		
		IsIntermediateAttempt = CurrentAttempt > 1 And CurrentAttempt < AttemptsNumber;
		If IsIntermediateAttempt Then
			Pause(CurrentAttempt);
		EndIf;
	EndDo;
	
	If Not AllConnectionsTerminated Then
		If HadErrors Then
			ExceptionText = NStr("ru = 'Не удалось разорвать соединения. См. журнал регистрации.';
								|vi = 'Cannot close the connections. See the event log.';
								|en = 'Cannot close the connections. See the event log.'; fa = 'Cannot close the connections. See the event log.';
								|it = 'Cannot close the connections. See the event log.';
								|pl = 'Cannot close the connections. See the event log.';
								|tr = 'Bağlantılar kesilemedi. Olay günlüğüne bakın.'");
		Else
			ExceptionText = NStr("ru = 'Не удалось разорвать соединения.';
								|vi = 'Cannot close connections.';
								|en = 'Cannot close connections.'; fa = 'Cannot close connections.';
								|it = 'Non è stato possibile interrompere le connessioni.';
								|pl = 'Nie udało się przerwać połączenie.';
								|tr = 'Bağlantılar kapatılamıyor.'");
		EndIf;
		Raise ExceptionText;
	EndIf;
	
EndProcedure

#EndRegion

#Region SecurityProfiles

// See ClusterAdministration.InfobaseSecurityProfile
Function InfobaseSecurityProfile(Val ClusterAdministrationParameters, Val IBAdministrationParameters) Export
	ServerAgent = ServerAgent(ClusterAdministrationParameters);	
	ServerCluster = ServerCluster(ServerAgent, ClusterAdministrationParameters);
	ClusterBase = ClusterBase(ServerCluster, IBAdministrationParameters);
	Return ClusterBase.SecurityProfile;
EndFunction

// See ClusterAdministration.InfobaseSafeModeSecurityProfile
Function InfobaseSafeModeSecurityProfile(Val ClusterAdministrationParameters, Val IBAdministrationParameters) Export
	ServerAgent = ServerAgent(ClusterAdministrationParameters);	
	ServerCluster = ServerCluster(ServerAgent, ClusterAdministrationParameters);
	ClusterBase = ClusterBase(ServerCluster, IBAdministrationParameters);
	Return ClusterBase.SafeModeSecurityProfile;
EndFunction

// See ClusterAdministration.SetInfobaseSecurityProfile
Procedure SetInfobaseSecurityProfile(Val ClusterAdministrationParameters, Val IBAdministrationParameters, Val ProfileName = "") Export
	ServerAgent = ServerAgent(ClusterAdministrationParameters);	
	ServerCluster = ServerCluster(ServerAgent, ClusterAdministrationParameters);
	ClusterBase = ClusterBase(ServerCluster, IBAdministrationParameters);
	ClusterBase.SecurityProfile = ProfileName;
	ClusterBase.Write();
EndProcedure

// See ClusterAdministration.SetInfobaseSafeModeSecurityProfile
Procedure SetInfobaseSafeModeSecurityProfile(Val ClusterAdministrationParameters, Val IBAdministrationParameters, Val ProfileName = "") Export
	ServerAgent = ServerAgent(ClusterAdministrationParameters);	
	ServerCluster = ServerCluster(ServerAgent, ClusterAdministrationParameters);
	ClusterBase = ClusterBase(ServerCluster, IBAdministrationParameters);
	ClusterBase.SafeModeSecurityProfile = ProfileName;
	ClusterBase.Write();
EndProcedure

// See ClusterAdministration.SecurityProfileExists
Function SecurityProfileExists(Val ClusterAdministrationParameters, Val ProfileName) Export
	SecurityProfileObject = SecurityProfileObject(ClusterAdministrationParameters, ProfileName);
	Result = SecurityProfileObject <> Undefined;
	Return Result;
EndFunction

// See ClusterAdministration.SecurityProfile
Function SecurityProfile(Val ClusterAdministrationParameters, Val ProfileName) Export
	Result = ClusterAdministration.SecurityProfileProperties();
	SecurityProfileObject = SecurityProfileObject(ClusterAdministrationParameters, ProfileName);
	FillPropertyValues(Result, SecurityProfileObject);
	Result.FullAccessToPrivilegedMode = SecurityProfileObject.FullPrivilegedMode;
	Result.FullAccessToCryptoFunctions = SecurityProfileObject.CryptoAvailable;
	
	Result.FullAccessToAllModulesExtension = Not ValueIsFilled(Result.ModulesAvailableForExtension)
		And Not ValueIsFilled(Result.ModulesNotAvailableForExtension);
	Result.FullAccessToAccessRightsExtension = SecurityProfileObject.AllowAccessRightsExtension;
	Result.FullOperatingSystemApplicationAccess = SecurityProfileObject.ExternalApplicationsFullAccess;
	
	Result.VirtualDirectories = VirtualDirectoriesProperties(SecurityProfileObject);
	Result.COMClasses = COMClassesProperties(SecurityProfileObject);
	Result.AddIns = AddInsProperties(SecurityProfileObject);
	Result.ExternalModules = ExternalModulesProperties(SecurityProfileObject);
	Result.OSApplications = OSApplicationsProperties(SecurityProfileObject);
	Result.InternetResources = InternetResourcesProperties(SecurityProfileObject);
	Return Result;	
EndFunction

// See ClusterAdministration.CreateSecurityProfile
Procedure CreateSecurityProfile(Val ClusterAdministrationParameters, Val SecurityProfileProperties) Export
	If SecurityProfileExists(ClusterAdministrationParameters, SecurityProfileProperties.Name) Then
		ClusterPresentation = StrTemplate("%1:%2", 
			ClusterAdministrationParameters.AdministrationServerAddress,
			Format(ClusterAdministrationParameters.ClusterPort, "NG=;"));
		ExceptionPattern = NStr("ru = 'В кластере серверов %1 уже зарегистрирован профиль безопасности %2';
								|vi = 'Security profile %2 is already registered in server cluster %1.';
								|en = 'Security profile %2 is already registered in server cluster %1.'; fa = 'Security profile %2 is already registered in server cluster %1.';
								|it = 'Nel cluster di server %1 è già registrato il profilo di sicurezza %2';
								|pl = 'W klasterze serwerów %1 już jest zarejestrowany profil bezpieczeństwa %2';
								|tr = '%1 sunucu kümesinde %2 güvenlik profili zaten kaydedildi'");
		ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(ExceptionPattern, ClusterPresentation, SecurityProfileProperties.Name);
		Raise ExceptionText;
	EndIf;
	
	ServerAgent = ServerAgent(ClusterAdministrationParameters);	
	ServerCluster = ServerCluster(ServerAgent, ClusterAdministrationParameters);
	ObjectOfProfile = ServerCluster.CreateSecurityProfile();
		
	ImportSecurityProfileProperties(ObjectOfProfile, SecurityProfileProperties);	
EndProcedure

// See ClusterAdministration.SetSecurityProfileProperties
Procedure SetSecurityProfileProperties(Val ClusterAdministrationParameters, Val SecurityProfileProperties)  Export
	ObjectOfProfile = SecurityProfileObject(ClusterAdministrationParameters, SecurityProfileProperties.Name);
	ImportSecurityProfileProperties(ObjectOfProfile, SecurityProfileProperties);
EndProcedure

// See ClusterAdministration.DeleteSecurityProfile
Procedure DeleteSecurityProfile(Val ClusterAdministrationParameters, Val ProfileName) Export
	ObjectOfProfile = SecurityProfileObject(ClusterAdministrationParameters, ProfileName);
	If ObjectOfProfile <> Undefined Then
		ObjectOfProfile.Delete();
	EndIf;
EndProcedure

#EndRegion

#Region Infobases

// See ClusterAdministration.InfoBaseID
Function InfoBaseID(Val ClusterID, Val ClusterAdministrationParameters, Val InfobaseAdministrationParameters) Export
	ServerAgent = ServerAgent(ClusterAdministrationParameters);	
	ServerCluster = ServerCluster(ServerAgent, ClusterAdministrationParameters);
	ClusterBase = ClusterBase(ServerCluster, InfobaseAdministrationParameters);
	Return ClusterBase.InfoBaseID;
EndFunction

// See ClusterAdministration.InfobasesProperties
Function InfobasesProperties(Val ClusterID, Val ClusterAdministrationParameters, Val Filter = Undefined) Export
	Command = "infobase summary list " + ClusterParameters(ClusterAdministrationParameters, ClusterID);
	BaseDetailsPropertyTypes = BaseDetailsPropertyTypes();
	Properties = RunCommand(Command, ClusterAdministrationParameters, , Filter, BaseDetailsPropertyTypes);
	
	Return Properties;
EndFunction

#EndRegion

#Region Cluster

// See ClusterAdministration.ClusterID
Function ClusterID(Val ClusterAdministrationParameters) Export
	ServerAgent = ServerAgent(ClusterAdministrationParameters);	
	ServerCluster = ServerCluster(ServerAgent, ClusterAdministrationParameters);
	Return ServerCluster.ClusterID;
EndFunction

// See ClusterAdministration.ClusterProperties
Function ClusterProperties(Val ClusterAdministrationParameters, Val Filter = Undefined) Export
	If ValueIsFilled(ClusterAdministrationParameters.AdministrationServerAddress) Then
		Server = TrimAll(ClusterAdministrationParameters.AdministrationServerAddress);
		If ValueIsFilled(ClusterAdministrationParameters.AdministrationServerPort) Then
			Server = Server + ":" + AdjustValue(ClusterAdministrationParameters.AdministrationServerPort);
		EndIf;
	Else
		Server = "";
	EndIf;
	ClusterPropertyTypes = ClusterPropertyTypes();
	Result = RunCommand("cluster list " + Server, ClusterAdministrationParameters, , Filter, ClusterPropertyTypes);
	Return Result;
EndFunction

#EndRegion

#Region WorkingProcessesServers

// See ClusterAdministration.WorkingProcessesProperties
Function WorkingProcessesProperties(Val ClusterID, Val ClusterAdministrationParameters, Val Filter = Undefined) Export
	ClusterParameters = ClusterParameters(ClusterAdministrationParameters, ClusterID);
	Result = RunCommand("process list " + ClusterParameters, ClusterAdministrationParameters, , Filter);
	Return Result;
EndFunction

// See ClusterAdministration.WorkingServerProperties
Function WorkingServerProperties(Val ClusterID, Val ClusterAdministrationParameters, Val Filter = Undefined) Export
	ClusterParameters = ClusterParameters(ClusterAdministrationParameters, ClusterID);
	WorkingServerPropertyTypes = WorkingServerPropertyTypes();
	Result = RunCommand("server list " + ClusterParameters, ClusterAdministrationParameters, , Filter, WorkingServerPropertyTypes);
	Return Result;
EndFunction

#EndRegion

// See ClusterAdministration.SessionsProperties
Function SessionsProperties(Val ClusterID, Val ClusterAdministrationParameters, Val InfoBaseID, Val Filter = Undefined, Val UseDictionary = True) Export
	
	Command = "session list --infobase=%1 " + ClusterParameters(ClusterAdministrationParameters, ClusterID);	
	SubstituteParametersToCommand(Command, InfoBaseID);	
	
	If UseDictionary Then
		Dictionary = SessionPropertiesDictionary();
	Else
		Dictionary = Undefined;
		Filter = FilterToRacNotation(Filter, SessionPropertiesDictionary());
	EndIf;
	
	Result = RunCommand(Command, ClusterAdministrationParameters, Dictionary, Filter, SessionPropertyTypes());
	
	Return Result;                                       
	
EndFunction

// See ClusterAdministration.ConnectionsProperties
Function ConnectionsProperties(Val ClusterID, Val ClusterAdministrationParameters, Val InfoBaseID, Val InfobaseAdministrationParameters, Val Filter = Undefined, Val UseDictionary = False) Export
	
	ClusterParameters = ClusterParameters(ClusterAdministrationParameters, ClusterID);
	
	If UseDictionary Then
		Dictionary = ConnectionPropertiesDictionary();
	Else
		Dictionary = Undefined;
		Filter = FilterToRacNotation(Filter, ConnectionPropertiesDictionary());
	EndIf;
	
	Result = New Array();
	WorkingProcesses = WorkingProcessesProperties(ClusterID, ClusterAdministrationParameters);
	
	For Each IWorkingProcessInfo In WorkingProcesses Do
		
		Command = "connection list --process=%1 --infobase=%2 --infobase-user=%3 --infobase-pwd=%4 " + ClusterParameters;
		SubstituteParametersToCommand(Command,
			IWorkingProcessInfo.Get("process"),
			InfoBaseID,
			InfobaseAdministrationParameters.InfobaseAdministratorName,
			InfobaseAdministrationParameters.InfobaseAdministratorPassword);
			
		WorkingProcessConnections = RunCommand(Command, ClusterAdministrationParameters, Dictionary, Filter, ConnectionPropertyTypes());
		For Each Join In WorkingProcessConnections Do
			If UseDictionary Then
				If Join.DataBaseConnectionMode = "none" Then
					Join.Insert("DataBaseConnectionMode", 0);
				ElsIf Join.DataBaseConnectionMode = "shared" Then
					Join.Insert("DataBaseConnectionMode", 1);
				Else // exclusive
					Join.Insert("DataBaseConnectionMode", 2);
				EndIf;
				Join.Insert("InfobaseConnectionMode", ?(Join.InfobaseConnectionMode = "shared", 0, 1));
				Join.Insert("ControlIsOnServer", ?(Join.ControlIsOnServer = "client", 0, 1));
			Else
				Join.Insert("process", IWorkingProcessInfo.Get("process"));
			EndIf;
			Result.Add(Join);
		EndDo;
		
	EndDo;
	
	Return Result;
	
EndFunction

// See ClusterAdministration.PathToAdministrationServerClient
Function PathToAdministrationServerClient() Export	
	StartDirectory = CommonClientServer.AddLastPathSeparator(BinDir());
	Result = StartDirectory + "rac";
	
	If Common.IsWindowsServer() Then
		Result = Result + ".exe";
	EndIf;
	
	Return Result;
EndFunction

#EndRegion

#Region Private

#Region Service

Procedure SetDefault(Receiver, ValueToBeSet)
	If Not ValueIsFilled(Receiver) Then
		Receiver = ValueToBeSet;
	EndIf;
EndProcedure

Procedure SetProperty(Receiver, Source, SourceKey)
	Var PropertyValue;
	If Not Source.Property(SourceKey, PropertyValue) Then
		Return;
	EndIf;	
	If Receiver <> PropertyValue Then
		Receiver = PropertyValue;
	EndIf;
EndProcedure

Procedure Pause(SecondsCount)
	InfobaseUpdateInternal.Pause(SecondsCount);
EndProcedure

Procedure WriteErrorToEventLog(Comment)
	EventNameLR = NStr("ru = 'Администрирование кластера';
						|vi = 'Cluster administration';
						|en = 'Cluster administration'; fa = 'مدیریت کلاستر';
						|it = 'Amministrazione del cluster';
						|pl = 'Zarządzanie klastrem';
						|tr = 'Küme yönetimi'", Common.DefaultLanguageCode());
	WriteLogEvent(EventNameLR, EventLogLevel.Error, , , Comment);
EndProcedure

#EndRegion

#Region CreateSecurityProfile

Procedure ImportSecurityProfileProperties(ObjectOfProfile, SecurityProfileProperties)
	If Not ValueIsFilled(ObjectOfProfile.Name) Then
		ObjectOfProfile.Name = SecurityProfileProperties.Name;
	EndIf;
	FillPropertyValues(ObjectOfProfile, SecurityProfileProperties, , "Name");
	ObjectOfProfile.CryptoAvailable = SecurityProfileProperties.FullAccessToCryptoFunctions;
	ObjectOfProfile.ExternalApplicationsFullAccess = SecurityProfileProperties.FullOperatingSystemApplicationAccess;
	ObjectOfProfile.FullPrivilegedMode = SecurityProfileProperties.FullAccessToPrivilegedMode;
	ObjectOfProfile.AllowAccessRightsExtension = SecurityProfileProperties.FullAccessToAccessRightsExtension;
	ObjectOfProfile.Write();
	
	ImportVirtualDirectoriesProperties(ObjectOfProfile, SecurityProfileProperties);
	ImportCOMClassesProperties(ObjectOfProfile, SecurityProfileProperties);
	ImportAddInsProperties(ObjectOfProfile, SecurityProfileProperties);
	ImportExternalModulesProperties(ObjectOfProfile, SecurityProfileProperties);
	ImportOSApplicationsProperties(ObjectOfProfile, SecurityProfileProperties);
	ImportInternetResourcesProperties(ObjectOfProfile, SecurityProfileProperties);
EndProcedure

Procedure ClearAccessControlListItems(ListItems)
	For Each Item In ListItems Do
		Item.Delete();
	EndDo;
EndProcedure

Procedure ImportVirtualDirectoriesProperties(ObjectOfProfile, SecurityProfileProperties)
	CurrentValues = ObjectOfProfile.GetAllowedVirtualDirectories();
	ClearAccessControlListItems(CurrentValues);

	For Each Source In SecurityProfileProperties.VirtualDirectories Do
		Receiver = ObjectOfProfile.CreateAllowedVirtualDirectory();
		FillPropertyValues(Receiver, Source);
		Receiver.WritingAllowed = Source.DataWriter;
		Receiver.ReadingAllowed = Source.DataReader;
		Receiver.Path = Source.PhysicalURL;
		Receiver.Alias = Source.LogicalURL;
		Receiver.Write();
	EndDo;	
EndProcedure

Procedure ImportCOMClassesProperties(ObjectOfProfile, SecurityProfileProperties)
	CurrentValues = ObjectOfProfile.GetAllowedCOMClass();
	ClearAccessControlListItems(CurrentValues);

	For Each Source In SecurityProfileProperties.COMClasses Do
		Receiver = ObjectOfProfile.CreateAllowedCOMClass();
		FillPropertyValues(Receiver, Source);
		Receiver.ObjectUUID = Source.CLSID;
		Receiver.ComputerName = Source.Computer;
		Receiver.FileName = Source.FileMoniker;
		Receiver.Write();
	EndDo;	
EndProcedure

Procedure ImportAddInsProperties(ObjectOfProfile, SecurityProfileProperties)
	CurrentValues = ObjectOfProfile.GetAllowedAddIns();
	ClearAccessControlListItems(CurrentValues);

	For Each Source In SecurityProfileProperties.AddIns Do
		Receiver = ObjectOfProfile.CreateAllowedAddIn();
		FillPropertyValues(Receiver, Source);
		Receiver.Write();
	EndDo;	
EndProcedure

Procedure ImportExternalModulesProperties(ObjectOfProfile, SecurityProfileProperties)
	CurrentValues = ObjectOfProfile.GetAllowedExternalModules();
	ClearAccessControlListItems(CurrentValues);		

	For Each Source In SecurityProfileProperties.ExternalModules Do
		Receiver = ObjectOfProfile.CreateAllowedExternalModule();
		FillPropertyValues(Receiver, Source);
		Receiver.Write();
	EndDo;	
EndProcedure

Procedure ImportOSApplicationsProperties(ObjectOfProfile, SecurityProfileProperties)
	CurrentValues = ObjectOfProfile.GetAllowedExternalApplications();
	ClearAccessControlListItems(CurrentValues);		

	For Each Source In SecurityProfileProperties.OSApplications Do
		Receiver = ObjectOfProfile.CreateAllowedExternalApplication();
		FillPropertyValues(Receiver, Source);
		Receiver.CommandString = Source.CommandLinePattern;
		Receiver.Write();
	EndDo;
EndProcedure

Procedure ImportInternetResourcesProperties(ObjectOfProfile, SecurityProfileProperties)
	CurrentValues = ObjectOfProfile.GetAllowedInternetResources();
	ClearAccessControlListItems(CurrentValues);		

	For Each Source In SecurityProfileProperties.InternetResources Do
		Receiver = ObjectOfProfile.CreateAllowedInternetResource();
		FillPropertyValues(Receiver, Source);
		Receiver.Write();
	EndDo;
EndProcedure

#EndRegion

#Region DetailsOfObjects

Function SessionAndScheduleJobLockProperties(ClusterBase)
	Result = ClusterAdministration.SessionAndScheduleJobLockProperties();
	Result.SessionsLock = ClusterBase.SessionsLockEnabled;
	Result.DateFrom1 = ClusterBase.LockBeginTime;
	Result.DateTo = ClusterBase.LockEndTime;
	Result.Message = ClusterBase.LockMessage;
	Result.KeyCode = ClusterBase.SessionStartPermissionCode;
	Result.LockParameter = ClusterBase.LockParameter;
	Result.LockScheduledJobs = ClusterBase.LockScheduledJobs;
	Return Result;
EndFunction

Function WorkProcessDescription(IWorkingProcessInfo, ServerCluster)
	
	Result = ClusterAdministration.WorkingProcessProperties();
	FillPropertyValues(Result, IWorkingProcessInfo);

	Result.ServerReaction = Round(IWorkingProcessInfo.AverageCallDuration, 3);
	Result.SpentByDBMS = Round(IWorkingProcessInfo.AverageDBMSCallsDuration, 3);
	Result.SpentByTheLockManager = Round(IWorkingProcessInfo.AverageServiceCallDuration, 3);
	Result.SpentByTheServer = Round(IWorkingProcessInfo.AverageWorkProcessCallProcessingDuration, 3);
	Result.ClientStreams = Round(IWorkingProcessInfo.AverageThreadCount, 3);
	Result.ExceedingTheCriticalValue = IWorkingProcessInfo.MemoryUsageExcessTime;
	Result.OccupiedMemory = IWorkingProcessInfo.MemoryUsage / 1024;
	Result.Id = IWorkingProcessInfo.ProcessID;
	Result.Started2 = ?(IWorkingProcessInfo.Running, 1, 0);
	Result.StartedAt = IWorkingProcessInfo.StartTime;
	Result.Connections = ServerCluster.GetConnections().Count();
	
	If IWorkingProcessInfo.WorkProcessStatus = AdministrationWorkProcessStatus.NotUsed Then
		Result.Use = 0;
	ElsIf IWorkingProcessInfo.WorkProcessStatus = AdministrationWorkProcessStatus.Used Then
		Result.Use = 1;
	ElsIf IWorkingProcessInfo.WorkProcessStatus = AdministrationWorkProcessStatus.Reserve Then
		Result.Use = 2;		
	EndIf;
	
	If ValueIsFilled(IWorkingProcessInfo.Licenses) Then
		Result.ILicenseInfo = LicenseDescription(IWorkingProcessInfo.Licenses[0]);
	EndIf;
	
	Return Result;
	
EndFunction

Function IConnectionShort(Join)
	Result = ClusterAdministration.ConnectionDetailsProperties();
	FillPropertyValues(Result, Join);
	Result.ConnectionEstablishingTime = Join.ConnectionTime;
	Result.ClientComputerName = Join.ComputerName;
	Result.Number = Join.ConnectionNumber;
	Result.Block = Join.ManagedLockSessionNumber;
	Return Result;
EndFunction

Function SessionDetails(Session)
	Result = ClusterAdministration.SessionProperties();	
	Result.Number = Session.SessionNumber;
	Result.UserName = Session.UserName;
	Result.ClientComputerName = Session.ComputerName;
	Result.ClientApplicationID = Session.ApplicationName;
	Result.LanguageID = Session.LanguageCode;
	Result.SessionCreationTime = Session.BeginTime;
	Result.LatestSessionActivityTime = Session.LastActivityTime;
	Result.Block = Session.ManagedLockSessionNumber;
	Result.DBMSLock = Session.DBMSLockSessionNumber;
	
	Result.Passed = Session.ClientSentReceivedDataSize;
	Result.PassedIn5Minutes = Session.ClientSentReceivedDataSizeLast5Min;
	Result.ServerCalls = Session.CallCountTotal;
	Result.ServerCallsIn5Minutes = Session.CallCountLast5Min;
	Result.ServerCallDurations = Session.CallDurationTotal;
	Result.CurrentServerCallDuration = Session.CallDurationCurrent;
	Result.ServerCallDurationsIn5Minutes = Session.CallDurationLast5Min;
	Result.ExchangedWithDBMS = Session.DBMSSentAndReceivedDataSizeTotal;
	Result.ExchangedWithDBMSIn5Minutes = Session.DBMSSentAndReceivedDataSizeLast5Min;
	Result.DBMSCallDuration = Session.DBMSCallDurationTotal;
	Result.CurrentDBMSCallDuration = Session.DBMSCallDurationCurrent;
	Result.DBMSCallDurationsIn5Minutes = Session.DBMSCallDurationLast5Min;
	Result.DBMSConnection = Session.DBMSConnection;

	Result.Sleep = Session.HibernateSession;
	Result.TerminateIn = Session.HibernateSessionTerminateTime;
	Result.SleepIn = Session.PassiveSessionHibernateTime;
	Result.ReadFromDisk = Session.ReadDiskDataSizeTotal;
	Result.ReadFromDiskInCurrentCall = Session.ReadDiskDataSizeCurrent;
	Result.ReadFromDiskIn5Minutes = Session.ReadDiskDataSizeLast5Min;
	Result.OccupiedMemory = Session.MemoryUsageTotal;
	Result.OccupiedMemoryInCurrentCall = Session.MemoryUsageCurrent;
	Result.OccupiedMemoryIn5Minutes = Session.MemoryUsageLast5Min;
	Result.WrittenOnDisk = Session.WriteDiskDataSizeTotal;
	Result.WrittenOnDiskInCurrentCall = Session.WriteDiskDataSizeCurrent;
	Result.WrittenOnDiskIn5Minutes = Session.WriteDiskDataSizeLast5Min;
	
	Result.DBMSConnectionTime = 0;
	Result.DBMSConnectionSeizeTime = "";
	
	Return Result;
EndFunction

Function LicenseDescription(ILicenseInfo)	
	Result = ClusterAdministration.LicenseProperties();
	FillPropertyValues(Result, ILicenseInfo);
	Result.IssuedByServer = ILicenseInfo.RetrievedByServer;
	Result.LisenceType = ILicenseInfo.SoftwareLicense;
	Result.MaxUsersForSet = ILicenseInfo.MaxSoftwareLicenseUsers;
	Result.MaxUsersInKey = ILicenseInfo.MaxUsers;
	Result.LicenseIsReceivedViaAladdinLicenseManager = ILicenseInfo.NetworkKey;
	Result.ProcessAddress = ILicenseInfo.ServerAddress;
	Result.ProcessPort = ILicenseInfo.ServerPort;
	Result.FullPresentation = ILicenseInfo.DetailedPresentation;
	Result.LisenceType = ?(ILicenseInfo.SoftwareLicense, 0, 1);
	Return Result;
EndFunction

Function VirtualDirectoriesProperties(SecurityProfileObject)
	Result = New Array();
	ListOfSources = SecurityProfileObject.GetAllowedVirtualDirectories();
	For Each Source In ListOfSources Do
		Properties = ClusterAdministration.VirtualDirectoryProperties();
		FillPropertyValues(Properties, Source);
		Properties.DataWriter = Source.WritingAllowed;
		Properties.DataReader = Source.ReadingAllowed;
		Properties.PhysicalURL = Source.Path;
		Properties.LogicalURL = Source.Alias;
		
		Result.Add(Properties);
	EndDo;	
	Return Result;
EndFunction

Function COMClassesProperties(SecurityProfileObject)
	Result = New Array();
	ListOfSources = SecurityProfileObject.GetAllowedCOMClass();
	For Each Source In ListOfSources Do
		Properties = ClusterAdministration.COMClassProperties();
		FillPropertyValues(Properties, Source);
		Properties.CLSID = Source.ObjectUUID;
		Properties.Computer = Source.ComputerName;
		Properties.FileMoniker = Source.FileName;
		
		Result.Add(Properties);
	EndDo;	
	Return Result;
EndFunction

Function AddInsProperties(SecurityProfileObject)
	Result = New Array();
	ListOfSources = SecurityProfileObject.GetAllowedAddIns();
	For Each Source In ListOfSources Do
		Properties = ClusterAdministration.AddInProperties();
		FillPropertyValues(Properties, Source);
		
		Result.Add(Properties);
	EndDo;	
	Return Result;	
EndFunction

Function ExternalModulesProperties(SecurityProfileObject)
	Result = New Array();
	ListOfSources = SecurityProfileObject.GetAllowedExternalModules();
	For Each Source In ListOfSources Do
		Properties = ClusterAdministration.ExternalModuleProperties();
		FillPropertyValues(Properties, Source);
		
		Result.Add(Properties);
	EndDo;	
	Return Result;		
EndFunction

Function OSApplicationsProperties(SecurityProfileObject)
	Result = New Array();
	ListOfSources = SecurityProfileObject.GetAllowedExternalApplications();
	For Each Source In ListOfSources Do
		Properties = ClusterAdministration.OSApplicationProperties();
		FillPropertyValues(Properties, Source);
		Properties.CommandLinePattern = Source.CommandString;
		
		Result.Add(Properties);
	EndDo;	
	Return Result;		
EndFunction

Function InternetResourcesProperties(SecurityProfileObject)
	Result = New Array();
	ListOfSources = SecurityProfileObject.GetAllowedInternetResources();
	For Each Source In ListOfSources Do
		Properties = ClusterAdministration.InternetResourceProperties();
		FillPropertyValues(Properties, Source);
		
		Result.Add(Properties);
	EndDo;	
	Return Result;		
EndFunction

#EndRegion

#Region AdministrationObjects

Function ServerAgent(ClusterAdministrationParameters)
	
	AdministrationServerAddress = ClusterAdministrationParameters.AdministrationServerAddress;
	AdministrationServerPort = ClusterAdministrationParameters.AdministrationServerPort;
	Result = New ServerAdministration(AdministrationServerAddress, AdministrationServerPort);

	Return Result;

EndFunction

Function ServerCluster(ServerAgent, ClusterAdministrationParameters)
	Result = Undefined;
	
	ClusterPort = ClusterAdministrationParameters.ClusterPort;

	Clusters = ServerAgent.GetClusters();
	For Each Cluster In Clusters Do
		If Cluster.Port = ClusterPort Then
			Result = Cluster;
			Break;
		EndIf;
	EndDo;
	
	If Result = Undefined Then
		ExceptionPattern = NStr("ru = 'На сервере администрирования %1 не найден кластер на порту %2';
								|vi = 'The cluster on port %2 is not found on the %1 administration server.';
								|en = 'The cluster on port %2 is not found on the %1 administration server.'; fa = 'The cluster on port %2 is not found on the %1 administration server.';
								|it = 'The cluster on port %2 is not found on the %1 administration server.';
								|pl = 'The cluster on port %2 is not found on the %1 administration server.';
								|tr = '%1 yönetim sunucusunda %2 portunda küme bulunamadı'");
		ClusterPortFormat = Format(ClusterPort, "NG=;");
		ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(ExceptionPattern, ClusterAdministrationParameters.AdministrationServerAddress, ClusterPortFormat);
		Raise ExceptionText;
	Else
		ClusterAdministratorName = ClusterAdministrationParameters.ClusterAdministratorName;
		ClusterAdministratorPassword = ClusterAdministrationParameters.ClusterAdministratorPassword;
		
		Result.Authenticate(ClusterAdministratorName, ClusterAdministratorPassword);
	EndIf;
	
	Return Result;
EndFunction

Function ClusterBase(ServerCluster, IBAdministrationParameters)
	Result = Undefined;
		
	Infobases = ServerCluster.GetInfoBases();
	For Each InfoBase In Infobases Do
		If InfoBase.Name = IBAdministrationParameters.NameInCluster Then
			Result = InfoBase;
			Break;
		EndIf;
	EndDo;
	
	If Result = Undefined Then
		ExceptionPattern = NStr("ru = 'В кластере серверов %1:%2 не найдена информационная база ""%3""';
								|vi = 'Infobase ""%3"" is not found on server cluster %1:%2';
								|en = 'Infobase ""%3"" is not found on server cluster %1:%2'; fa = 'Infobase ""%3"" is not found on server cluster %1:%2';
								|it = 'Infobase ""%3"" is not found on server cluster %1:%2';
								|pl = 'Infobase ""%3"" is not found on server cluster %1:%2';
								|tr = '%1:%2 sunucu kümesinde ""%3"" infobase bulunamadı'");
		ClusterPortFormat = Format(ServerCluster.Port, "NG=;");
		ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(ExceptionPattern, ServerCluster.ComputerName,
			ClusterPortFormat, IBAdministrationParameters.NameInCluster);
		Raise ExceptionText;
	Else
		InfobaseAdministratorName = IBAdministrationParameters.InfobaseAdministratorName;	
		InfobaseAdministratorPassword = IBAdministrationParameters.InfobaseAdministratorPassword;
		Result.Authenticate(InfobaseAdministratorName, InfobaseAdministratorPassword);
	EndIf;	
	
	Return Result;
EndFunction

Function PropertiesOfLockDescriptionSessions(ServerCluster, ClusterBase)
	Result = New Map();
	Locks = ServerCluster.GetLocks();
	For Each Block In Locks Do			
		If ValueIsFilled(Block.SessionID) Then
			ClusterAdministration.SessionDataFromLock(Result,
				Block.Description,
				Block.SessionID,
				ClusterBase.Name);
		EndIf;
	EndDo;

	Return Result;
EndFunction

Function SessionsList(ServerAgent, ServerCluster, ClusterBase, Val Filter = Undefined, AddSessionObjects = False)
	Result = New Array;

	PropertiesOfLockDescriptionSessions = PropertiesOfLockDescriptionSessions(ServerCluster, ClusterBase);

	BaseSessions = ClusterBase.GetSessions();
	BaseConnections = ClusterBase.GetConnections();
	ClusterWorkingProcesses = ServerCluster.GetWorkProcesses();
	For Each Session In BaseSessions Do
		SessionDetails = SessionDetails(Session);
		If ValueIsFilled(Session.Licenses) Then
			SessionLicense = Session.Licenses[0]; // AdministrationLicense
			SessionDetails.ILicenseInfo = LicenseDescription(SessionLicense);
		EndIf;
		
		SessionFromLockProperties = PropertiesOfLockDescriptionSessions[Session.SessionID];		
		If ValueIsFilled(SessionFromLockProperties) Then
			SessionDetails.Separator = SessionFromLockProperties.Separator;
			SessionDetails.DBLockMode = SessionFromLockProperties.DBLockMode;
		EndIf;

		SessionConnection = SessionConnection(Session, BaseConnections);
		If SessionConnection <> Undefined Then
			SessionDetails.IConnectionShort = IConnectionShort(SessionConnection);
			SessionWorkingProcess = SessionWorkingProcess(SessionConnection, ClusterWorkingProcesses);	
			If SessionWorkingProcess <> Undefined Then
				WorkProcessDescription = WorkProcessDescription(SessionWorkingProcess, ServerCluster);
				
				SessionDetails.IWorkingProcessInfo = WorkProcessDescription;
				SessionDetails.IConnectionShort.IWorkingProcessInfo = WorkProcessDescription;
			EndIf;
		EndIf;

		If ClusterAdministration.CheckFilterConditions(SessionDetails, Filter) Then
			If AddSessionObjects Then
				SessionDetails.Insert("SessionObject", Session);
			EndIf;
			Result.Add(SessionDetails);
		EndIf;
	EndDo;
	Return Result;
EndFunction

Function SessionConnection(Session, BaseConnections)
	Var Result;
	For Each Join In BaseConnections Do
		If Join.ConnectionID = Session.ConnectionID Then
			Result = Join;
			Break;
		EndIf;
	EndDo;	
	Return Result;
EndFunction

Function SessionWorkingProcess(SessionConnection, ClusterWorkingProcesses)
	Var Result;
	For Each IWorkingProcessInfo In ClusterWorkingProcesses Do
		If SessionConnection.ProcessID = IWorkingProcessInfo.WorkProcessID Then
			Result = IWorkingProcessInfo;					
			Break;
		EndIf;	
	EndDo;
	Return Result;
EndFunction

Function ListOfConnections(ServerAgent, ServerCluster, ClusterBase, Val Filter = Undefined, DetailsList1 = False)
	Result = New Array();
	For Each Join In ClusterBase.GetConnections() Do
		IConnectionShort = IConnectionShort(Join);
		If Not ValueIsFilled(IConnectionShort.Number) Then
			Continue;
		EndIf;

		If ClusterAdministration.CheckFilterConditions(IConnectionShort, Filter) Then
			If DetailsList1 Then
				Result.Add(IConnectionShort);
			Else
				Result.Add(Join);
			EndIf;
		EndIf;
	EndDo;
	Return Result;
EndFunction

Function SecurityProfileObject(ClusterAdministrationParameters, ProfileName)
	Result = Undefined;
	ServerAgent = ServerAgent(ClusterAdministrationParameters);	
	ServerCluster = ServerCluster(ServerAgent, ClusterAdministrationParameters);
	SecurityProfiles = ServerCluster.GetSecurityProfiles();
	For Each SecurityProfile In SecurityProfiles Do
		If SecurityProfile.Name = ProfileName Then
			Result = SecurityProfile;
			Break;
		EndIf;
	EndDo;	
	Return Result;
EndFunction

#EndRegion

#Region PropertiesFromConsole

Function ClusterPropertyTypes()
	
	Types = New Map;
	
	Types.Insert("cluster", Type("String"));
	Types.Insert("host", Type("String"));
	Types.Insert("port", Type("Number"));
	Types.Insert("name", Type("String"));
	Types.Insert("expiration-timeout", Type("Number"));
	Types.Insert("lifetime-limit", Type("Number"));
	Types.Insert("max-memory-size", Type("Number"));
	Types.Insert("max-memory-time-limit", Type("Number"));
	Types.Insert("security-level", Type("Number"));
	Types.Insert("session-fault-tolerance-level", Type("Number"));
	Types.Insert("load-balancing-mode", Type("String"));
	Types.Insert("errors-count-threshold", Type("Number"));
	Types.Insert("kill-problem-processes", Type("Number"));	
	
	Return New FixedMap(Types);

EndFunction

Function WorkingServerPropertyTypes()
	Types = New Map;
	
	Types.Insert("server", Type("String"));
	Types.Insert("agent-host", Type("String"));
	Types.Insert("agent-port", Type("Number"));
	Types.Insert("port-range", Type("String"));
	Types.Insert("name", Type("String"));
	Types.Insert("using", Type("String"));
	Types.Insert("dedicate-managers", Type("String"));
	Types.Insert("infobases-limit", Type("Number"));
	Types.Insert("memory-limit", Type("Number"));
	Types.Insert("connections-limit", Type("Number"));
	Types.Insert("safe-working-processes-memory-limit", Type("Number"));
	Types.Insert("safe-call-memory-limit", Type("Number"));
	Types.Insert("cluster-port", Type("Number"));

	Return New FixedMap(Types);
EndFunction

Function SessionPropertyTypes()
	
	Types = New Map;
	
	Types.Insert("session", Type("String"));
	Types.Insert("session-id", Type("Number"));
	Types.Insert("infobase", Type("String"));
	Types.Insert("connection", Type("String"));
	Types.Insert("process", Type("String"));
	Types.Insert("user-name", Type("String"));
	Types.Insert("host", Type("String"));
	Types.Insert("app-id", Type("String"));
	Types.Insert("locale", Type("String"));
	Types.Insert("started-at", Type("Date"));
	Types.Insert("last-active-at", Type("Date"));
	Types.Insert("hibernate", Type("Boolean"));
	Types.Insert("passive-session-hibernate-time", Type("Number"));
	Types.Insert("hibernate-session-terminate-time", Type("Number"));
	Types.Insert("blocked-by-dbms", Type("Number"));
	Types.Insert("blocked-by-ls", Type("Number"));
	Types.Insert("bytes-all", Type("Number"));
	Types.Insert("bytes-last-5min", Type("Number"));
	Types.Insert("calls-all", Type("Number"));
	Types.Insert("calls-last-5min", Type("Number"));
	Types.Insert("dbms-bytes-all", Type("Number"));
	Types.Insert("dbms-bytes-last-5min", Type("Number"));
	Types.Insert("db-proc-info", Type("String"));
	Types.Insert("db-proc-took", Type("Number"));
	Types.Insert("db-proc-took-at", Type("Date"));
	Types.Insert("duration-all", Type("Number"));
	Types.Insert("duration-all-dbms", Type("Number"));
	Types.Insert("duration-current", Type("Number"));
	Types.Insert("duration-current-dbms", Type("Number"));
	Types.Insert("duration-last-5min", Type("Number"));
	Types.Insert("duration-last-5min-dbms", Type("Number"));
	Types.Insert("memory-current", Type("Number"));
	Types.Insert("memory-last-5min", Type("Number"));
	Types.Insert("memory-total", Type("Number"));
	Types.Insert("read-current", Type("Number"));
	Types.Insert("read-last-5min", Type("Number"));
	Types.Insert("read-total", Type("Number"));
	Types.Insert("write-current", Type("Number"));
	Types.Insert("write-last-5min", Type("Number"));
	Types.Insert("write-total", Type("Number"));
	
	Return New FixedMap(Types);
	
EndFunction

Function ConnectionPropertyTypes()
	
	Types = New Map;
	
	Types.Insert("connection", Type("String"));
	Types.Insert("conn-id", Type("Number"));
	Types.Insert("user-name", Type("String"));
	Types.Insert("host", Type("String"));
	Types.Insert("app-id", Type("String"));
	Types.Insert("connected-at", Type("Date"));
	Types.Insert("thread-mode", Type("String"));
	Types.Insert("ib-conn-mode", Type("String"));
	Types.Insert("db-conn-mode", Type("String"));
	Types.Insert("blocked-by-dbms", Type("Number"));
	Types.Insert("bytes-all", Type("Number"));
	Types.Insert("bytes-last-5min", Type("Number"));
	Types.Insert("calls-all", Type("Number"));
	Types.Insert("calls-last-5min", Type("Number"));
	Types.Insert("dbms-bytes-all", Type("Number"));
	Types.Insert("dbms-bytes-last-5min", Type("Number"));
	Types.Insert("db-proc-info", Type("String"));
	Types.Insert("db-proc-took", Type("Number"));
	Types.Insert("db-proc-took-at", Type("Date"));
	Types.Insert("duration-all", Type("Number"));
	Types.Insert("duration-all-dbms", Type("Number"));
	Types.Insert("duration-current", Type("Number"));
	Types.Insert("duration-current-dbms", Type("Number"));
	Types.Insert("duration-last-5min", Type("Number"));
	Types.Insert("duration-last-5min-dbms", Type("Number"));
	Types.Insert("memory-current", Type("Number"));
	Types.Insert("memory-last-5min", Type("Number"));
	Types.Insert("memory-total", Type("Number"));
	Types.Insert("read-current", Type("Number"));
	Types.Insert("read-last-5min", Type("Number"));
	Types.Insert("read-total", Type("Number"));
	Types.Insert("write-current", Type("Number"));
	Types.Insert("write-last-5min", Type("Number"));
	Types.Insert("write-total", Type("Number"));
	
	Return New FixedMap(Types);
	
EndFunction

Function BaseDetailsPropertyTypes()
	
	Types = New Map;
	
	Types.Insert("infobase", Type("String"));
	Types.Insert("name", Type("String"));
	Types.Insert("descr", Type("String"));

	Return New FixedMap(Types);
	
EndFunction

Function SessionPropertiesDictionary()
	
	ILicenseInfo = New Structure;
	ILicenseInfo.Insert("Key", "license");
	ILicenseInfo.Insert("Dictionary", LicensePropertiesDictionary());
	
	IConnectionShort = New Structure;
	IConnectionShort.Insert("Key", "connection");
	IConnectionShort.Insert("Dictionary", ConnectionDetailsPropertiesDictionary());
	
	IWorkingProcessInfo = New Structure;
	IWorkingProcessInfo.Insert("Key", "process");
	IWorkingProcessInfo.Insert("Dictionary", WorkingProcessPropertiesDictionary());
	
	Result = ClusterAdministration.SessionProperties();
	
	Result.Number = "session-id";
	Result.UserName = "user-name";
	Result.ClientComputerName = "host";
	Result.ClientApplicationID = "app-id";
	Result.LanguageID = "locale";
	Result.SessionCreationTime = "started-at";
	Result.LatestSessionActivityTime = "last-active-at";
	Result.DBMSLock = "blocked-by-dbms";
	Result.Block = "blocked-by-ls";
	Result.Passed = "bytes-all";
	Result.PassedIn5Minutes = "bytes-last-5min";
	Result.ServerCalls = "calls-all";
	Result.ServerCallsIn5Minutes = "calls-last-5min";
	Result.ServerCallDurations = "duration-all";
	Result.CurrentServerCallDuration = "duration-current";
	Result.ServerCallDurationsIn5Minutes = "duration-last-5min";
	Result.ExchangedWithDBMS = "dbms-bytes-all";
	Result.ExchangedWithDBMSIn5Minutes = "dbms-bytes-last-5min";
	Result.DBMSCallDuration = "duration-all-dbms";
	Result.CurrentDBMSCallDuration = "duration-current-dbms";
	Result.DBMSCallDurationsIn5Minutes = "duration-last-5min-dbms";
	Result.DBMSConnection = "db-proc-info";
	Result.DBMSConnectionTime = "db-proc-took";
	Result.DBMSConnectionSeizeTime = "db-proc-took-at";
	Result.Sleep = "hibernate";
	Result.TerminateIn = "hibernate-session-terminate-time";
	Result.SleepIn = "passive-session-hibernate-time";
	Result.ReadFromDisk = "read-total";
	Result.ReadFromDiskInCurrentCall = "read-current";
	Result.ReadFromDiskIn5Minutes = "read-last-5min";
	Result.OccupiedMemory = "memory-total";
	Result.OccupiedMemoryInCurrentCall = "memory-current";
	Result.OccupiedMemoryIn5Minutes = "memory-last-5min";
	Result.WrittenOnDisk = "write-total";
	Result.WrittenOnDiskInCurrentCall = "write-current";
	Result.WrittenOnDiskIn5Minutes = "write-last-5min";
	Result.ILicenseInfo = New FixedStructure(ILicenseInfo);
	Result.IConnectionShort = New FixedStructure(IConnectionShort);
	Result.IWorkingProcessInfo = New FixedStructure(IWorkingProcessInfo);
	
	Return New FixedStructure(Result);
	
EndFunction

Function ConnectionDetailsPropertiesDictionary()
	
	IWorkingProcessInfo = New Structure;
	IWorkingProcessInfo.Insert("Key", "process");
	IWorkingProcessInfo.Insert("Dictionary", WorkingProcessPropertiesDictionary());
	
	Result = ClusterAdministration.ConnectionDetailsProperties();
	
	Result.ApplicationName = "application";
	Result.Block = "blocked-by-ls";
	Result.ConnectionEstablishingTime = "connected-at";
	Result.Number = "conn-id";
	Result.ClientComputerName = "host";
	Result.SessionNumber = "session-number";
	Result.IWorkingProcessInfo = New FixedStructure(IWorkingProcessInfo);
	
	Return New FixedStructure(Result);
	
EndFunction

Function LicensePropertiesDictionary()
	
	Result = ClusterAdministration.LicenseProperties();
	
	Result.FileName = "full-name";
	Result.FullPresentation = "full-presentation";
	Result.BriefPresentation = "short-presentation";
	Result.IssuedByServer = "issued-by-server";
	Result.LisenceType = "license-type";
	Result.MaxUsersForSet = "max-users-all";
	Result.MaxUsersInKey = "max-users-cur";
	Result.LicenseIsReceivedViaAladdinLicenseManager = "net";
	Result.ProcessAddress = "rmngr-address";
	Result.ProcessID = "rmngr-pid";
	Result.ProcessPort = "rmngr-port";
	Result.KeySeries = "series";
	
	Return New FixedStructure(Result);
	
EndFunction

Function WorkingProcessPropertiesDictionary()
	
	ILicenseInfo = New Structure;
	ILicenseInfo.Insert("Key", "license");
	ILicenseInfo.Insert("Dictionary", LicensePropertiesDictionary());
	
	Result = ClusterAdministration.WorkingProcessProperties();
	
	Result.AvailablePerformance = "available-perfomance";
	Result.SpentByTheClient = "avg-back-call-time";
	Result.ServerReaction = "avg-call-time";
	Result.SpentByDBMS = "avg-db-call-time";
	Result.SpentByTheLockManager = "avg-lock-call-time";
	Result.SpentByTheServer = "avg-server-call-time";
	Result.ClientStreams = "avg-threads";
	Result.Capacity = "capacity";
	Result.Connections = "connections";
	Result.ComputerName = "host";
	Result.Enabled = "is-enable";
	Result.Port = "port";
	Result.ExceedingTheCriticalValue = "memory-excess-time";
	Result.OccupiedMemory = "memory-size";
	Result.Id = "pid";
	Result.Started2 = "running";
	Result.CallsCountByWhichTheStatisticsIsCalculated = "selection-size";
	Result.StartedAt = "started-at";
	Result.Use = "use";
	Result.ILicenseInfo = New FixedStructure(ILicenseInfo);
	
	Return New FixedStructure(Result);
	
EndFunction

Function ConnectionPropertiesDictionary()
	
	Result = ClusterAdministration.ConnectionProperties();
	
	Result.Number = "conn-id";
	Result.UserName = "user-name";
	Result.ClientComputerName = "host";
	Result.ClientApplicationID = "app-id";
	Result.ConnectionEstablishingTime = "connected-at";
	Result.InfobaseConnectionMode = "ib-conn-mode";
	Result.DataBaseConnectionMode = "db-conn-mode";
	Result.DBMSLock = "blocked-by-dbms";
	Result.Passed = "bytes-all";
	Result.PassedIn5Minutes = "bytes-last-5min";
	Result.ServerCalls = "calls-all";
	Result.ServerCallsIn5Minutes = "calls-last-5min";
	Result.ExchangedWithDBMS = "dbms-bytes-all";
	Result.ExchangedWithDBMSIn5Minutes = "dbms-bytes-last-5min";
	Result.DBMSConnection = "db-proc-info";
	Result.DBMSTime = "db-proc-took";
	Result.DBMSConnectionSeizeTime = "db-proc-took-at";
	Result.ServerCallDurations = "duration-all";
	Result.DBMSCallDuration = "duration-all-dbms";
	Result.CurrentServerCallDuration = "duration-current";
	Result.CurrentDBMSCallDuration = "duration-current-dbms";
	Result.ServerCallDurationsIn5Minutes = "duration-last-5min";
	Result.DBMSCallDurationsIn5Minutes = "duration-last-5min-dbms";
	Result.ReadFromDisk = "read-total";
	Result.ReadFromDiskInCurrentCall = "read-current";
	Result.ReadFromDiskIn5Minutes = "read-last-5min";
	Result.OccupiedMemory = "memory-total";
	Result.OccupiedMemoryInCurrentCall = "memory-current";
	Result.OccupiedMemoryIn5Minutes = "memory-last-5min";
	Result.WrittenOnDisk = "write-total";
	Result.WrittenOnDiskInCurrentCall = "write-current";
	Result.WrittenOnDiskIn5Minutes = "write-last-5min";
	Result.ControlIsOnServer = "thread-mode";
	
	Return New FixedStructure(Result);
	
EndFunction

Function AdjustValue(Val Value)
	
	If TypeOf(Value) = Type("Date") Then
		
		Return XMLString(Value);
		
	ElsIf TypeOf(Value) = Type("Boolean") Then
		
		Return Format(Value, "BF=no; BT=yes");
		
	ElsIf TypeOf(Value) = Type("Number") Then
		
		Return Format(Value, "NDS=,; NZ=0; NG=0; NN=1");
		
	ElsIf TypeOf(Value) = Type("String") Then
		
		// The documentation stipulates:
		// Arbitrary strings are enclosed in double quotation marks, and double quotation marks within such strings should be duplicated.
		Digits = "0123456789";
		LatinCharacters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
		CyrillicCharacters = "ABVGDEZHZIYKLMNOPRSTUFKHTSCHSHSHYEYUYaabvgdezhziyklmnoprstufkhtschshyeyu"; // ACC:1036 - Orthography check is not required.
		AllowedChars = Digits + LatinCharacters + CyrillicCharacters + "-";
		If StringContainsAllowedCharsOnly(Value, AllowedChars) Then
			Return Value;
		Else
			Return """" + StrReplace(Value, """", """""") + """";
		EndIf;
		
	EndIf;
	
	Return String(Value);
	
EndFunction

Function ClusterParameters(ClusterAdministrationParameters, ClusterID = Undefined)
	
	If ClusterID = Undefined Then
		ClusterID = ClusterID(ClusterAdministrationParameters);
	EndIf;
	
	ClusterParameters = "--cluster=" + ClusterID;
	If ValueIsFilled(ClusterAdministrationParameters.ClusterAdministratorName) Then
		ClusterParameters = ClusterParameters + " --cluster-user=""" + ClusterAdministrationParameters.ClusterAdministratorName + """";
		If ValueIsFilled(ClusterAdministrationParameters.ClusterAdministratorPassword) Then
			ClusterParameters = ClusterParameters + " --cluster-pwd=""" + ClusterAdministrationParameters.ClusterAdministratorPassword + """";
		EndIf;
	EndIf;
	
	If ValueIsFilled(ClusterAdministrationParameters.AdministrationServerAddress) Then
		Server = TrimAll(ClusterAdministrationParameters.AdministrationServerAddress);
		If ValueIsFilled(ClusterAdministrationParameters.AdministrationServerPort) Then
			Server = Server + ":" + AdjustValue(ClusterAdministrationParameters.AdministrationServerPort);
		EndIf;
		ClusterParameters = ClusterParameters + " " + Server;
	EndIf;
	
	Return ClusterParameters;
	
EndFunction

Procedure SubstituteParametersToCommand(Command, Val Parameter1, 
	Val Parameter2 = Undefined, 
	Val Parameter3 = Undefined, 
	Val Parameter4 = Undefined)
	
	Command = StringFunctionsClientServer.SubstituteParametersToString(Command, 
		AdjustValue(Parameter1),
		AdjustValue(Parameter2),
		AdjustValue(Parameter3),
		AdjustValue(Parameter4));
	
EndProcedure

Function FilterToRacNotation(Val Filter, Val Dictionary)
	
	If Filter = Undefined Then
		Return Undefined;
	EndIf;
	
	If Dictionary = Undefined Then
		Return Filter;
	EndIf;
	
	Result = New Array();
	
	For Each Condition In Filter Do
		
		If TypeOf(Condition) = Type("KeyAndValue") Then
			
			Result.Add(New Structure("Property, ComparisonType, Value", Dictionary[Condition.Key], ComparisonType.Equal, Condition.Value));
			
		ElsIf TypeOf(Condition) = Type("Structure") Then
			
			Result.Add(New Structure("Property, ComparisonType, Value", Dictionary[Condition.Property], Condition.ComparisonType, Condition.Value));
			
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#Region LaunchConsoleCommands

Function RunCommand(Command, ClusterAdministrationParameters, Dictionary = Undefined, Filter = Undefined, PropertyTypes = Undefined)
	
	If SafeMode() <> False Then
		Raise NStr("vi = 'Không thể quản trị cụm máy chủ ở chế độ an toàn';
					|ru = 'Администрирование кластера невозможно в безопасном режиме';
					|en = 'Safe mode does not support cluster administration.'; fa = 'Safe mode does not support cluster administration.';
					|it = 'L''amministrazione del cluster è impossibile in modalità sicura';
					|pl = 'Administrowanie klastrami nie jest możliwe w trybie awaryjnym';
					|tr = 'Kümenin yönetilmesi güvenli modda kullanılamaz'");
	EndIf;
	
	If Common.DataSeparationEnabled() Then
		Raise NStr("vi = 'Trong mô hình dịch vụ, không cho phép cơ sở thông tin ứng dụng thực hiện các chức năng quản trị cụm máy chủ';
					|ru = 'В модели сервиса недопустимо выполнение прикладной информационной базой функций администрирования кластера';
					|en = 'SaaS mode does not support cluster administration.'; fa = 'SaaS mode does not support cluster administration.';
					|it = 'Nel modello del servizio non è permessa l''esecuzione della base informativa applicata delle funzioni di amministrazioni del cluster';
					|pl = 'W modelu usługi baza danych aplikacji funkcji administrowania klastrem jest niedozwolona.';
					|tr = 'Hizmet modelinde, uygulama infobase''nin küme yönetimi işlevlerini gerçekleştirmesine izin verilmez.'");
	EndIf;
	
	// Substituting path to the rac utility and the ras server address to the command line.
	Client = PathToAdministrationServerClient();
	ClientFile = New File(Client);
	If Not ClientFile.Exists() Then
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể thực hiện thao tác quản trị cụm máy chủ vì lý do: tệp %1 không tồn tại
			           |
			           |Để quản trị cụm máy chủ thông qua máy chủ quản trị (ras), hãy cài đặt Client máy chủ quản trị (rac) trên
			           |máy tính này.
			           |Để cài đặt nó:
			           |- Đối với máy tính chạy hệ điều hành Windows, cần cài đặt lại nền tảng bằng cách cài đặt cấu phần ""Máy chủ 1C:Enterprise""; 
			           |- Đối với máy tính chạy Linux, hãy cài đặt gói 1c-enterprise83-server*.';
			           |ru = 'Невозможно выполнить операцию администрирования кластера серверов по причине: не существует файл %1
			           |
			           |Для администрирования кластера через сервер администрирования (ras) установите на данном
			           |компьютере клиент сервера администрирования (rac).
			           |Для его установки:
			           |- Для компьютеров с ОС Windows переустановите платформу, установив компонент ""Сервер 1С:Предприятия"";
			           |- Для компьютеров с ОС Linux установите пакет 1c-enterprise83-server*.';
			           |en = 'Cannot perform the operation of server cluster administration as the %1 file does not exist.
			           |
			           |To administer the cluster via the administration server (ras), install the server administration client (rac) on this
			           |computer.
			           |To install it:
			           |- For Windows, reinstall 1C:Enterprise platform with ""1C:Enterprise server"" component selected.
			           |- For Linux, install the 1c-enterprise83-server* package.'; fa = 'Cannot perform the operation of server cluster administration as the %1 file does not exist.
			           |
			           |To administer the cluster via the administration server (ras), install the server administration client (rac) on this
			           |computer.
			           |To install it:
			           |- For Windows, reinstall 1C:Enterprise platform with ""1C:Enterprise server"" component selected.
			           |- For Linux, install the 1c-enterprise83-server* package.';
			           |it = 'Impossibile eseguire l''operazione di amministrazione del cluster di server a causa di: non esiste il file %1
			           |
			           |Per l''amministrazione del cluster tramite server di amministrazione (ras), installare su questo computer
			           |il client del server di amministrazione (rac).
			           |Per l''installazione:
			           |- Per computer con Sistema Operativo Windows, reinstallare la piattaforma installando la componente ""Server 1C:Enterprise"";
			           |- Per computer con Sistema Operativo Linux, installare il pacchetto 1c-enterprise83-server*.';
			           |pl = 'Niemożliwe jest wykonanie operacji administrowania klastera serwerów z powodu: plik %1 nie istnieje. 
			           |
			           |Dla administrowania klastera przez serwer administrowania (ras) zainstaluj na tym 
			           |komputerze klient serwera administrowania (rac). 
			           |Aby go zainstalować: 
			           |- Dla komputerów z OS Windows ponownie zainstaluj platformę, instalując komponent ""Serwer 1C:Enterprise""; 
			           |- Dla komputerów z OS Linux zainstaluj pakiet 1c-enterprise83-server*.';
			           |tr = 'Sunucu küme yönetiminin operasyonunu çalıştırılamıyor: %1 dosya bulunamadı.
			           |
			           |Kümeyi yönetici sunucusu (ras) aracılığıyla yönetmek için, bu bilgisayara
			           | bir yönetim sunucusu (ras) istemcisi yükleyin.
			           |Yüklemek için:
			           |- Windows işletim sistemine sahip bilgisayarlar için, 1C:Enterprise sunucu yönetimi bileşenini kurarak platformu yeniden yükleyin"";
			           |- Linux OS''li bilgisayarlar için 1c-enterprise83-server * paketini yükleyin.'"),
			ClientFile.FullName);
		
	EndIf;
	
	CommandLine = """" + Client + """ " + Command;
	
	ApplicationStartupParameters = FileSystem.ApplicationStartupParameters();
	ApplicationStartupParameters.CurrentDirectory = PlatformExecutableFilesDirectory();
	ApplicationStartupParameters.WaitForCompletion = True;
	ApplicationStartupParameters.GetOutputStream = True;
	ApplicationStartupParameters.GetErrorStream = True;
	
	Result = FileSystem.StartApplication(ConvertACommandLineToAnArray(CommandLine),
		ApplicationStartupParameters);
	
	OutputStream = Result.OutputStream;
	ErrorStream = Result.ErrorStream;
	
	If ValueIsFilled(ErrorStream) Then
		Raise ErrorStream;
	EndIf;
	
	If IsBlankString(OutputStream) Then
		Return New Array;
	EndIf;
	
	Result = OutputParser(OutputStream, Dictionary, Filter, PropertyTypes);
	Return Result;
	
EndFunction

Function StringContainsAllowedCharsOnly(String, AllowedChars)
	
	AllAllowedChars = New Map;
	For Position = 1 To StrLen(AllowedChars) Do
		AllAllowedChars[Mid(AllowedChars, Position, 1)] = True;
	EndDo;
	
	For Position = 1 To StrLen(String) Do
		If AllAllowedChars[Mid(String, Position, 1)] = Undefined Then
			Return False;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction

Function PlatformExecutableFilesDirectory()
	
	Result = BinDir();
	SeparatorChar = GetPathSeparator();
	
	If Right(Result, 1) <> SeparatorChar Then
		Result = Result + SeparatorChar;
	EndIf;
	
	Return Result;
	
EndFunction

Function ConvertACommandLineToAnArray(Val CommandLine)
	
	Result = New Array;
	
	TheQuotationMarksAreOpen = False;
	StringLength = StrLen(CommandLine);
	PreviousChar = "";
	NewItem = "";
	
	For IndexOf = 1 To StringLength Do
		
		Char = Mid(CommandLine, IndexOf, 1);
		If Char = """" Then
			TheQuotationMarksAreOpen = Not TheQuotationMarksAreOpen;
		EndIf;
		
		If Not Char = """" Then
			NewItem = NewItem + Char;
		EndIf;
		
		If PreviousChar = """" And Char = """"
			 And TheQuotationMarksAreOpen Then
			NewItem = NewItem + PreviousChar;
		EndIf;
		
		If (Char = " " And Not TheQuotationMarksAreOpen) Or IndexOf = StringLength Then
			If Not IsBlankString(NewItem) Then
				Result.Add(TrimAll(NewItem));
			EndIf;
			
			NewItem = "";
			Continue;
		EndIf;
		
		PreviousChar = Char;
		
	EndDo;
		
	Return Result;
	
EndFunction

Function CastOutputItem(OutputItem, ElementType)
	
	If ElementType = Type("String") Then
		
		Return OutputItem;
		
	ElsIf ElementType = Type("Number") Then
		
		If IsBlankString(OutputItem) Then
			Return 0;
		EndIf;
		
		Try
			Return Number(OutputItem);
		Except
			Raise NStr("vi = 'Sai định dạng.';
						|ru = 'Неправильный формат.';
						|en = 'Invalid format.'; fa = 'Invalid format.';
						|it = 'Formato incorretto.';
						|pl = 'Niepoprawny format.';
						|tr = 'Geçersiz format.'");
		EndTry;
		
	ElsIf ElementType = Type("Date") Then
		
		If IsBlankString(OutputItem) Then
			Return Date(1, 1, 1);
		EndIf;
		
		Try
			Return XMLValue(Type("Date"), OutputItem);
		Except
			Raise NStr("vi = 'Sai định dạng.';
						|ru = 'Неправильный формат.';
						|en = 'Invalid format.'; fa = 'Invalid format.';
						|it = 'Formato incorretto.';
						|pl = 'Niepoprawny format.';
						|tr = 'Geçersiz format.'");
		EndTry;
		
	ElsIf ElementType = Type("Boolean") Then
		
		If OutputItem = "on" Or OutputItem = "yes" Then
			Return True;
		ElsIf OutputItem = "off" Or OutputItem = "no" Then
			Return False;
		Else
			Raise NStr("vi = 'Sai định dạng.';
						|ru = 'Неправильный формат.';
						|en = 'Invalid format.'; fa = 'Invalid format.';
						|it = 'Formato incorretto.';
						|pl = 'Niepoprawny format.';
						|tr = 'Geçersiz format.'");
		EndIf;
		
	ElsIf ElementType = Undefined Then
		
		// Skip identifying the data type in the string as 
		// an empty string may be an empty date, and 
		// the string can contain only numbers (for example, a process PID).
		
		If IsBlankString(OutputItem) Then
			Return Undefined;
		EndIf;
		
		Return OutputItem;
		
	Else
		
		Raise NStr("vi = 'Sai kiểu phần tử.';
					|ru = 'Неверный тип элемента.';
					|en = 'Invalid item type.'; fa = 'Invalid item type.';
					|it = 'Tipo dell''elemento incorretto.';
					|pl = 'Nieprawidłowy typ elementu.';
					|tr = 'Geçersiz bileşen türü.'");
		
	EndIf;
	
	Return OutputItem;
	
EndFunction

Function OutputParser(Val OutputStream, Val Dictionary, Val Filter = Undefined, PropertyTypes = Undefined)
	
	Result = New Array;
	ResultItem = New Map;
	
	Position = 1;
	OutputEnd = StrLen(OutputStream);
	
	While Position <= OutputEnd Do
		
		PropertyName = ReadUpToSeparator(OutputStream, Position, ":");
		PropertyRow = ReadUpToSeparator(OutputStream, Position, Chars.LF);
		PropertyType1 = ?(PropertyTypes = Undefined, Undefined, PropertyTypes.Get(PropertyName));
		PropertyValue = CastOutputItem(PropertyRow, PropertyType1);
		ResultItem.Insert(PropertyName, PropertyValue);
		
		If Mid(OutputStream, Position, 1) = Chars.LF Then
			Position = Position + 1;
			OutputItemParser(ResultItem, Result, Dictionary, Filter);
			ResultItem = New Map;
		EndIf;
		
	EndDo;
	
	If ResultItem.Count() > 0 Then
		OutputItemParser(ResultItem, Result, Dictionary, Filter);
	EndIf;
	
	Return Result;
	
EndFunction

Function ReadUpToSeparator(Stream, Position, Separator)
	
	CurrentChar = Mid(Stream, Position, 1);
	
	// Offset the position up to a meaningful character.
	While IsBlankString(CurrentChar) And Not CurrentChar = Separator And Position < StrLen(Stream) Do
		Position = Position + 1;
		CurrentChar = Mid(Stream, Position, 1);
	EndDo;
	
	If CurrentChar = Separator Then
		Position = Position + 1;
		Return "";
	EndIf;
	
	QuotationMark = """";
	If CurrentChar = QuotationMark Then
		Position = Position + 1;
		StartPosition = Position;
		// Find the next single quotation mark.
		While Position <= StrLen(Stream) Do
			FoundQuotationMark = StrFind(Stream, QuotationMark, SearchDirection.FromBegin, Position); 
			If FoundQuotationMark = 0 Then
				Raise NStr("vi = 'Sai định dạng.';
							|ru = 'Неправильный формат.';
							|en = 'Invalid format.'; fa = 'Invalid format.';
							|it = 'Formato incorretto.';
							|pl = 'Niepoprawny format.';
							|tr = 'Geçersiz format.'");
			ElsIf Mid(Stream, FoundQuotationMark + 1, 1) = QuotationMark Then
				Position = FoundQuotationMark + 2;
			Else
				Position = FoundQuotationMark + 1;
				// A quotation mark might be followed by a separator.
				If Mid(Stream, Position, 1) = Separator Then
					Position = Position + 1;
				EndIf;
				Break;
			EndIf;
		EndDo;
		If Position > StrLen(Stream) Then
			Raise NStr("vi = 'Sai định dạng.';
						|ru = 'Неправильный формат.';
						|en = 'Invalid format.'; fa = 'Invalid format.';
						|it = 'Formato incorretto.';
						|pl = 'Niepoprawny format.';
						|tr = 'Geçersiz format.'");
		EndIf;
		Value = TrimAll(Mid(Stream, StartPosition, FoundQuotationMark - StartPosition));
		Value = StrReplace(Value, QuotationMark + QuotationMark, QuotationMark);
		Return Value;
	Else
		// A simple case: Read till the next separator.
		SeparatorPosition = StrFind(Stream, Separator, SearchDirection.FromBegin, Position);
		Value = TrimAll(Mid(Stream, Position, SeparatorPosition - Position));
		Position = SeparatorPosition + 1;
		Return Value;
	EndIf;
	
EndFunction

Procedure OutputItemParser(ResultItem, Result, Dictionary, Filter)
	
	If Dictionary <> Undefined Then
		Object = ParseOutputItem(ResultItem, Dictionary);
	Else
		Object = ResultItem;
	EndIf;
	
	If Filter <> Undefined And Not ClusterAdministration.CheckFilterConditions(Object, Filter) Then
		Return;
	EndIf;
	
	Result.Add(Object);
	
EndProcedure

Function ParseOutputItem(Val OutputItem, Val Dictionary)
	
	Result = New Structure();
	
	For Each DictionaryFragment In Dictionary Do
		If TypeOf(DictionaryFragment.Value) = Type("FixedStructure") Then
			SubordinateObject = OutputItem[DictionaryFragment.Value.Key];
			If SubordinateObject = Undefined Then
				Result.Insert(DictionaryFragment.Key, Undefined);
			Else
				Property = ParseOutputItem(OutputItem[DictionaryFragment.Value.Key], DictionaryFragment.Value.Dictionary);
				Result.Insert(DictionaryFragment.Key, Property);
			EndIf;
		Else
			Result.Insert(DictionaryFragment.Key, OutputItem[DictionaryFragment.Value]);
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

