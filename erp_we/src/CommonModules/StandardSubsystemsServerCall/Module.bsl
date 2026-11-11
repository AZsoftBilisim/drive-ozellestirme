///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Sets the parameter that cancels the desktop form creating.
// The procedure is used if there is a need
// to interact with the user during the startup.
//
// Used from the StandardSubsystemsClient module procedure of the same name.
// The direct call on server has the meaning for reducing server call numbers
// if during preparing client parameters with Cached module it is already
// known that interactive processing is required.
//
// If the client parameter getting procedure directly calls this procedure,
// the state on the client is updated automatically, otherwise
// use the StandardSubsystemsClient module procedure of the same name
// to update it.
//
// Parameters:
//  Hide - Boolean - pass True to set the state
//           or False to clear it. You
//           can call the RefreshInterface method once the procedure is executed to recreate
//           the interface.
//
Procedure HideDesktopOnStart(Hide = True) Export
	
	If CurrentRunMode() = Undefined Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	// Saving or restoring the home page form content.
	ObjectKey         = "Common/HomePageSettings";
	StorageObjectKey = "Common/HomePageSettingsBeforeClear";
	SavedSettings = SystemSettingsStorage.Load(StorageObjectKey, "");
	
	If TypeOf(Hide) <> Type("Boolean") Then
		Hide = TypeOf(SavedSettings) = Type("ValueStorage");
	EndIf;
	
	If Hide Then
		If TypeOf(SavedSettings) <> Type("ValueStorage") Then
			CurrentSettings = SystemSettingsStorage.Load(ObjectKey);
			SavingSettings = New ValueStorage(CurrentSettings, New Deflation(9));
			SystemSettingsStorage.Save(StorageObjectKey, "", SavingSettings);
		EndIf;
		StandardSubsystemsServer.SetBlankFormOnHomePage();
	Else
		If TypeOf(SavedSettings) = Type("ValueStorage") Then
			SavedSettings = SavedSettings.Get();
			If SavedSettings = Undefined Then
				SystemSettingsStorage.Delete(ObjectKey, Undefined,
					InfoBaseUsers.CurrentUser().Name);
			Else
				SystemSettingsStorage.Save(ObjectKey, "", SavedSettings);
			EndIf;
			SystemSettingsStorage.Delete(StorageObjectKey, Undefined,
				InfoBaseUsers.CurrentUser().Name);
		EndIf;
	EndIf;
	
	CurrentParameters = New Map(SessionParameters.ClientParametersAtServer);
	
	If Hide Then
		CurrentParameters.Insert("HideDesktopOnStart", True);
		
	ElsIf CurrentParameters.Get("HideDesktopOnStart") <> Undefined Then
		CurrentParameters.Delete("HideDesktopOnStart");
	EndIf;
	
	SessionParameters.ClientParametersAtServer = New FixedMap(CurrentParameters);
	
EndProcedure

// See CommonInternalClientServer.CalculationCellsIndicators.
Function CalculationCellsIndicators(Val SpreadsheetDocument, SelectedAreas, UUID = Undefined) Export 
	
	If UUID = Undefined Then 
		Return CommonInternalClientServer.CalculationCellsIndicators(SpreadsheetDocument, SelectedAreas);
	EndIf;
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Tính toán các chỉ tiêu trong ô';
														|ru = 'Расчет показателей ячеек';
														|en = 'Cell indicator calculation'; fa = 'Cell indicator calculation';
														|it = 'Calcolo degli indicatori delle celle';
														|pl = 'Obliczenie wskaźników komórek';
														|tr = 'Hücre göstergelerini hesapla'");
	
	Return TimeConsumingOperations.ExecuteFunction(
		ExecutionParameters, 
		"CommonInternalClientServer.CalculationCellsIndicators",
		SpreadsheetDocument,
		SelectedAreas);
	
EndFunction

// See InformationRegisters.UsersInfo.ProcessAnswerOnDisconnectingOpenIDConnect
Procedure ProcessAnswerOnDisconnectingOpenIDConnect(Disconnect) Export
	
	// ACC:277-off - The "StandardSubsystemsServerCall" is used to
	// avoid creating "UsersServerCall" for one procedure.
	InformationRegisters.UsersInfo.ProcessAnswerOnDisconnectingOpenIDConnect(Disconnect);
	// ACC:277-on
	
EndProcedure

// See UsersInternal.AreCurrentUserRolesReduced
Function AreCurrentUserRolesReduced() Export
	Return UsersInternal.AreCurrentUserRolesReduced();
EndFunction

#EndRegion

#Region Private

// Returns the structure of parameters required for the operation of client-side code configuration,
// that is in the BeforeStart, OnStart event handlers.
//
// To be called only from StandardSubsystemsClientCached.ClientParametersOnStart.
//
Function ClientParametersOnStart(Parameters) Export
	
	CommonStartTime = CurrentUniversalDateInMilliseconds();
	Indicators = ?(StandardSubsystemsClientServer.ShouldRegisterPerformanceIndicators(),
		New Array, Undefined);
	
	NewParameters = New Structure;
	AddTimeAdjustments(NewParameters, Parameters);
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	HandleClientParametersAtServer(Parameters);
	StandardSubsystemsServer.AddMainIndicator(Indicators, StartMoment,
		"StandardSubsystemsServerCall.HandleClientParametersAtServer");
	
	StoreTempParameters(Parameters);
	CommonClientServer.SupplementStructure(Parameters, NewParameters);
	
	If Parameters.RetrievedClientParameters <> Undefined Then
		If Not Parameters.Property("SkipClearingDesktopHiding") Then
			// Update the desktop's hide state if the previous startup crashed
			// before running a restoration with the built-in mechanisms.
			StartMoment = CurrentUniversalDateInMilliseconds();
			HideDesktopOnStart(Undefined);
			StandardSubsystemsServer.AddMainIndicator(Indicators, StartMoment,
				"StandardSubsystemsServerCall.HideDesktopOnStart");
		EndIf;
	EndIf;
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	IsAllAdded = StandardSubsystemsServer.AddClientParametersOnStart(Parameters);
	StandardSubsystemsServer.AddMainIndicator(Indicators, StartMoment,
		"StandardSubsystemsServer.AddClientParametersOnStart", Parameters);
	
	If Not IsAllAdded Then
		Result = FixedClientParametersWithoutTemporaryParameters(Parameters, Indicators);
		StandardSubsystemsServer.AddMainIndicator(Indicators, CommonStartTime,
			"StandardSubsystemsServerCall.ClientParametersOnStart",, True);
		Return Result;
	EndIf;
	
	If Parameters.SeparatedDataUsageAvailable Then
		StartMoment = CurrentUniversalDateInMilliseconds();
		UsersInternal.OnAddClientParametersOnStart(Parameters, Undefined, False);
		StandardSubsystemsServer.AddMainIndicator(Indicators, StartMoment,
			"UsersInternal.OnAddClientParametersOnStart(,,False)");
	EndIf;
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	SSLSubsystemsIntegration.OnAddClientParametersOnStart(Parameters);
	StandardSubsystemsServer.AddMainIndicator(Indicators, StartMoment,
		"SSLSubsystemsIntegration.OnAddClientParametersOnStart", Parameters);
	
	If Parameters.SeparatedDataUsageAvailable Then
		AppliedParameters = New Structure;
		StartMoment = CurrentUniversalDateInMilliseconds();
		CommonOverridable.OnAddClientParametersOnStart(AppliedParameters);
		StandardSubsystemsServer.AddMainIndicator(Indicators, StartMoment,
			"CommonOverridable.OnAddClientParametersOnStart", AppliedParameters);
		For Each Parameter In AppliedParameters Do
			Parameters.Insert(Parameter.Key, Parameter.Value);
		EndDo;
	EndIf;
	
	Result = FixedClientParametersWithoutTemporaryParameters(Parameters, Indicators);
	StandardSubsystemsServer.AddMainIndicator(Indicators, CommonStartTime,
		"StandardSubsystemsServerCall.ClientParametersOnStart",, True);
	
	Return Result;
	
EndFunction

// Returns the structure of parameters required for the operation of client-side code configuration. 
// To be called only from StandardSubsystemsClientCached.ClientRunParameters.
//
Function ClientRunParameters(ClientProperties) Export
	
	CommonStartTime = CurrentUniversalDateInMilliseconds();
	Indicators = ?(StandardSubsystemsClientServer.ShouldRegisterPerformanceIndicators(),
		New Array, Undefined);
	
	Parameters = New Structure;
	AddTimeAdjustments(Parameters, ClientProperties);
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	HandleClientParametersAtServer(ClientProperties);
	StandardSubsystemsServer.AddMainIndicator(Indicators, StartMoment,
		"StandardSubsystemsServerCall.HandleClientParametersAtServer");
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	SSLSubsystemsIntegration.OnAddClientParameters(Parameters);
	StandardSubsystemsServer.AddMainIndicator(Indicators, StartMoment,
		"SSLSubsystemsIntegration.OnAddClientParameters", Parameters);
	
	AppliedParameters = New Structure;
	StartMoment = CurrentUniversalDateInMilliseconds();
	CommonOverridable.OnAddClientParameters(AppliedParameters);
	StandardSubsystemsServer.AddMainIndicator(Indicators, StartMoment,
		"CommonOverridable.OnAddClientParameters", Parameters);
	For Each Parameter In AppliedParameters Do
		Parameters.Insert(Parameter.Key, Parameter.Value);
	EndDo;
	
	Result = New Structure(Common.FixedData(Parameters));
	Result.Insert("PerformanceIndicators_", Indicators);
	StandardSubsystemsServer.AddMainIndicator(Indicators, CommonStartTime,
		"StandardSubsystemsServerCall.ClientRunParameters",, True);
	
	Return New FixedStructure(Result);
	
EndFunction

// Parameters:
//  OnStart - Boolean
//  Indicators - String
//  CallsStack - String
//
Procedure WritePerformanceIndicators(Val OnStart, Val Indicators, Val CallsStack) Export
	
	EventName = ?(OnStart,
		NStr("vi = 'Tham số hoạt động của client khi khởi động. Các chỉ số hiệu suất';
			|ru = 'Параметры работы клиента при запуске.Показатели производительности';
			|en = 'Client parameters on startup.Performance indicators'; fa = 'Client parameters on startup.Performance indicators';
			|it = 'Client parameters on startup.Performance indicators';
			|pl = 'Client parameters on startup.Performance indicators';
			|tr = 'Başlatma esnasında istemci performans parametreleri. Performans göstergeleri'",
			Common.DefaultLanguageCode()),
		NStr("vi = 'Tham số hoạt động của client. Các chỉ số hiệu suất';
			|ru = 'Параметры работы клиента.Показатели производительности';
			|en = 'Client parameters.Performance indicators'; fa = 'Client parameters.Performance indicators';
			|it = 'Client parameters.Performance indicators';
			|pl = 'Client parameters.Performance indicators';
			|tr = 'İstemci performans parametreleri. Performans göstergeleri'",
			Common.DefaultLanguageCode()));
	
	Comment = Indicators + Chars.LF + Chars.LF + CallsStack;
	
	WriteLogEvent(EventName,
		EventLogLevel.Information,,, Comment);
	
	If Common.SubsystemExists("CloudTechnology") Then
		EventNameStack = ?(OnStart,
			NStr("vi = 'Tham số hoạt động của client khi khởi động. Ngăn xếp lần gọi';
				|ru = 'Параметры работы клиента при запуске.Стек вызова';
				|en = 'Client parameters on startup.Call stack'; fa = 'Client parameters on startup.Call stack';
				|it = 'Client parameters on startup.Call stack';
				|pl = 'Client parameters on startup.Call stack';
				|tr = 'Başlatma esnasında istemci işlemi için parametreler. Çağrı yığını'",
				Common.DefaultLanguageCode()),
			NStr("vi = 'Tham số hoạt động của client.Ngăn xếp lần gọi';
				|ru = 'Параметры работы клиента.Стек вызова';
				|en = 'Client parameters.Call stack'; fa = 'Client parameters.Call stack';
				|it = 'Client parameters.Call stack';
				|pl = 'Client parameters.Call stack';
				|tr = 'İstemci işlemi için parametreler. Çağrı yığını'",
				Common.DefaultLanguageCode()));
		
		ModuleCommonCTL = Common.CommonModule("CommonCTL");
		ModuleCommonCTL.TechnologyLogEntry(EventName, Indicators);
		ModuleCommonCTL.TechnologyLogEntry(EventNameStack, CallsStack);
	EndIf;
	
EndProcedure

// See SaaSOperations.SignInToDataArea.
Procedure SignInToDataArea(Val DataArea) Export
	
	If Common.SubsystemExists("CloudTechnology.Core") Then
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		ModuleSaaSOperations.SignInToDataArea(DataArea);
	EndIf;
	
EndProcedure

// Checks the right to disable the system logic and
// hides the desktop on the server if there is the right,
// otherwise an exception is thrown.
// 
Procedure CheckDisableStartupLogicRight(ClientProperties) Export
	
	HandleClientParametersAtServer(ClientProperties);
	HideDesktopOnStart(True);
	
	LoginDataArea = Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable();
	
	If Not LoginDataArea And Not AccessRight("Administration", Metadata)
		Or LoginDataArea And Not AccessRight("DataAdministration", Metadata) Then
		
		ErrorText = NStr("vi = 'Không đủ quyền để thực hiện giao dịch.';
						|ru = 'Недостаточно прав для выполнения операции.';
						|en = 'Insufficient rights to perform the operation.'; fa = 'Insufficient rights to perform the operation.';
						|it = 'Diritti insufficienti per eseguire l''operazione.';
						|pl = 'Niewystarczające uprawnienia do wykonania operacji.';
						|tr = 'İşlem için gerekli yetkiler yok.'");
	Else
		ErrorText = UsersInternal.ErrorCheckingTheRightsOfTheCurrentUserWhenLoggingIn();
	EndIf;
	
	If ValueIsFilled(ErrorText) Then
		ClientProperties.Insert("ErrorThereIsNoRightToDisableTheSystemStartupLogic", ErrorText);
	EndIf;
	
EndProcedure

// For internal use only.
Procedure WriteErrorToEventLogOnStartOrExit(Shutdown, Val Event, Val ErrorText) Export
	
	If Event = "Run" Then
		EventName = NStr("vi = 'Khởi động ứng dụng';
						|ru = 'Запуск приложения';
						|en = 'Startup'; fa = 'Startup';
						|it = 'Запуск приложения';
						|pl = 'Startup';
						|tr = 'Uygulamanın başlatılması'", Common.DefaultLanguageCode());
		If Shutdown Then
			ErrorDescriptionBeginning = NStr("vi = 'Không thể khởi động ứng dụng do nguyên nhân:';
											|ru = 'Запуск приложения невозможен по причине:';
											|en = 'Startup failed due to:'; fa = 'Startup failed due to:';
											|it = 'Запуск приложения невозможен по причине:';
											|pl = 'Startup failed due to:';
											|tr = 'Program şu sebeple başlatılamıyor:'");
		Else
			ErrorDescriptionBeginning = NStr("vi = 'Đã xảy ra tình huống ngoại lệ khi khởi động ứng dụng:';
											|ru = 'Возникла исключительная ситуация при запуске приложения:';
											|en = 'Exception occurred during startup:'; fa = 'Exception occurred during startup:';
											|it = 'Возникла исключительная ситуация при запуске приложения:';
											|pl = 'Exception occurred during startup:';
											|tr = 'Uygulama başlatılırken olağandışı bir durum oluştu:'");
		EndIf;
	Else
		EventName = NStr("vi = 'Kết thúc ứng dụng';
						|ru = 'Завершение приложения';
						|en = 'Exit'; fa = 'خروج';
						|it = 'Завершение приложения';
						|pl = 'Exit';
						|tr = 'Uygulamanın sonlandırılması'", Common.DefaultLanguageCode());
		ErrorDescriptionBeginning = NStr("vi = 'Đã xảy ra tình huống ngoại lệ khi kết thúc ứng dụng:';
										|ru = 'Возникла исключительная ситуация при завершении приложения:';
										|en = 'Exception occurred while exiting the app:'; fa = 'Exception occurred while exiting the app:';
										|it = 'Возникла исключительная ситуация при завершении приложения:';
										|pl = 'Exception occurred while exiting the app:';
										|tr = 'Uygulama sonlandırırken olağandışı bir durum oluştu:'");
	EndIf;
	
	ErrorDescription = ErrorDescriptionBeginning + Chars.LF + Chars.LF + ErrorText;
	EventLog.AddMessageForEventLog(EventName, EventLogLevel.Error,,, ErrorDescription);

EndProcedure

// Returns full metadata object name by its type.
Function FullMetadataObjectName(Type) Export
	MetadataObject = Metadata.FindByType(Type);
	If MetadataObject = Undefined Then
		Return Undefined;
	EndIf;
	Return MetadataObject.FullName();
EndFunction

// Returns a metadata object name by type.
//
// Parameters:
//  Source - Type - object.
//
// Returns:
//   String
//
Function MetadataObjectName(Type) Export
	MetadataObject = Metadata.FindByType(Type);
	If MetadataObject = Undefined Then
		Return Undefined;
	EndIf;
	Return MetadataObject.Name;
EndFunction

// See StandardSubsystemsServer.LibraryVersion.
Function LibraryVersion() Export
	
	Return StandardSubsystemsServer.LibraryVersion();
	
EndFunction

// Returns:
//  Array of String
//
Function NamesOfClientModules() Export
	
	Names = New Array;
	For Each MetadataObject In Metadata.CommonModules Do
		If MetadataObject.ClientManagedApplication
		   And Not MetadataObject.Global Then
			Names.Add(MetadataObject.Name);
		EndIf;
	EndDo;
	
	Return Names;
	
EndFunction

#Region PredefinedDataManagement

// See StandardSubsystemsCached.RefsByPredefinedItemsNames
Function RefsByPredefinedItemsNames(FullMetadataObjectName) Export
	
	Return StandardSubsystemsCached.RefsByPredefinedItemsNames(FullMetadataObjectName);
	
EndFunction

#EndRegion

#Region ForMetadataObjectIDsCatalog

// See Catalogs.MetadataObjectIDs.IDPresentation
Function MetadataObjectIDPresentation(Ref) Export
	
	Return Catalogs.MetadataObjectIDs.IDPresentation(Ref);
	
EndFunction

#EndRegion

#Region AuxiliaryProceduresAndFunctions

Procedure AddTimeAdjustments(Parameters, ClientProperties)
	
	SessionDate = CurrentSessionDate();
	UniversalSessionDate = ToUniversalTime(SessionDate, SessionTimeZone());
	
	Parameters.Insert("SessionTimeOffset", SessionDate - ClientProperties.CurrentDateOnClient);
	Parameters.Insert("UniversalTimeCorrection", UniversalSessionDate - SessionDate);
	Parameters.Insert("StandardTimeOffset", StandardTimeOffset(SessionTimeZone()));
	Parameters.Insert("ClientDateOffset", CurrentUniversalDateInMilliseconds()
		- ClientProperties.CurrentUniversalDateInMillisecondsOnClient);
	
EndProcedure

Procedure StoreTempParameters(Parameters)
	
	Parameters.Insert("TempParameterNames", New Array);
	
	For Each KeyAndValue In Parameters Do
		TempParameterNames = Parameters.TempParameterNames; // Array
		TempParameterNames.Add(KeyAndValue.Key);
	EndDo;
	
EndProcedure

Procedure HandleClientParametersAtServer(Val Parameters)
	
	PrivilegedModeSetOnStart = PrivilegedMode();
	SetPrivilegedMode(True);
	
	If SessionParameters.ClientParametersAtServer.Get("TheFirstServerCallIsMade") <> True Then
		// First server call from client after start.
		ClientParameters = New Map(SessionParameters.ClientParametersAtServer);
		ClientParameters.Insert("TheFirstServerCallIsMade", True);
		ClientParameters.Insert("LaunchParameter", Parameters.LaunchParameter);
		ClientParameters.Insert("InfoBaseConnectionString", Parameters.InfoBaseConnectionString);
		ClientParameters.Insert("PrivilegedModeSetOnStart", PrivilegedModeSetOnStart);
		ClientParameters.Insert("IsWebClient", Parameters.IsWebClient);
		ClientParameters.Insert("IsMobileClient", Parameters.IsMobileClient);
		ClientParameters.Insert("IsLinuxClient", Parameters.IsLinuxClient);
		ClientParameters.Insert("IsMacOSClient", Parameters.IsMacOSClient);
		ClientParameters.Insert("IsWindowsClient", Parameters.IsWindowsClient);
		ClientParameters.Insert("ClientUsed", Parameters.ClientUsed);
		ClientParameters.Insert("RAM", Parameters.RAM);
		ClientParameters.Insert("BinDir", Parameters.BinDir);
		ClientParameters.Insert("ClientID", Parameters.ClientID);
		ClientParameters.Insert("MainDisplayResolotion", Parameters.MainDisplayResolotion);
		ClientParameters.Insert("SystemInfo", Parameters.SystemInfo);
		
		SessionParameters.ClientParametersAtServer = New FixedMap(ClientParameters);
		
		If StrFind(Lower(Parameters.LaunchParameter), Lower("StartInfobaseUpdate")) > 0 Then
			InfobaseUpdateInternal.SetInfobaseUpdateStartup(True);
		EndIf;
		
		If Not Common.DataSeparationEnabled() Then
			If ExchangePlans.MasterNode() <> Undefined
				Or ValueIsFilled(Constants.MasterNode.Get()) Then
				// Prevent an unwanted update of predefined data in a child node during:
				// - A startup with the master node temporarily disabled.
				// - A data restructuring when restoring the node.
				If GetInfoBasePredefinedData()
					<> PredefinedDataUpdate.DontAutoUpdate Then
					SetInfoBasePredefinedDataUpdate(
					PredefinedDataUpdate.DontAutoUpdate);
				EndIf;
				If ExchangePlans.MasterNode() <> Undefined
					And Not ValueIsFilled(Constants.MasterNode.Get()) Then
					// Saving the master node for recovery purpose.
					StandardSubsystemsServer.SaveMasterNode();
				EndIf;
			EndIf;
		EndIf;
		
		If StrFind(Parameters.LaunchParameter, "DisableSystemStartupLogic") = 0 Then
			InformationRegisters.ExtensionVersionParameters.OnFirstServerCall();
		EndIf;
	EndIf;

EndProcedure

Function FixedClientParametersWithoutTemporaryParameters(Parameters, Indicators)
	
	ClientParameters = Parameters;
	Parameters = New Structure;
	
	For Each TemporaryParameterName In ClientParameters.TempParameterNames Do
		Parameters.Insert(TemporaryParameterName, ClientParameters[TemporaryParameterName]);
		ClientParameters.Delete(TemporaryParameterName);
	EndDo;
	Parameters.Delete("TempParameterNames");
	
	Parameters.HideDesktopOnStart =
		StandardSubsystemsServer.ClientParametersAtServer(False).Get(
			"HideDesktopOnStart") <> Undefined;
	
	Result = New Structure(Common.FixedData(ClientParameters));
	Result.Insert("PerformanceIndicators_", Indicators);
	Return New FixedStructure(Result);
	
EndFunction

Function TheComponentOfTheLatestVersion(Id, Location, AddIn) Export
	
	Return StandardSubsystemsServer.TheComponentOfTheLatestVersion(Id, Location, AddIn);
	
EndFunction

Function AppRestartTimeForApplyPatches() Export
	
	Return Common.CommonSettingsStorageLoad(
		"UserCommonSettings", 
		"AppRestartTimeForApplyPatches",,,
		UserName());
	
EndFunction

#EndRegion

#EndRegion