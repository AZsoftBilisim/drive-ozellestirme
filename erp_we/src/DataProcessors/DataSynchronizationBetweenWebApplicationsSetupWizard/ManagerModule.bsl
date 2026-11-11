///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Parameters:
//   XDTOSetup - Boolean - True if the exchange via the XDTO is configured.
// 
// Returns:
//   Structure - Connection settings for configuring the exchange:
//     * ExchangePlanName - String - an exchange plan name.
//     * CorrespondentExchangePlanName - String - a peer exchange plan name.
//     * SettingID - String - the setting option name as it is specified in the exchange plan manager module.
//     * ExchangeFormat - String - an exchange format name.
//     * Description - String - the description of this application.
//     * PeerInfobaseName - String - the peer infobase application description.
//     * Prefix - String - the prefix of this application.
//     * CorrespondentPrefix - String - peer infobase application prefix.
//     * SourceInfobaseID - String - the ID of this application.
//     * DestinationInfobaseID - String - the peer infobase application ID.
//     * CorrespondentEndpoint - DefinedType.MessagesQueueEndpoint - message exchange point.
//     * Peer - ExchangePlanRef - an exchange plan node.
//     * CorrespondentDataArea - Number - peer infobase data area number.
//     * XDTOCorrespondentSettings - Structure - details of the exchange format settings of the XDTO correspondent:
//       ** SupportedVersions - Array of String - (optional) the set of supported versions of the exchange format.
//       ** SupportedObjects - ValueStorage - a table of supported format objects.
// 
Function ConnectionSettingsDetails(XDTOSetup) Export
	
	ConnectionSettings = New Structure;
	ConnectionSettings.Insert("ExchangePlanName",               "");
	ConnectionSettings.Insert("CorrespondentExchangePlanName", "");
	
	ConnectionSettings.Insert("SettingID", "");
	
	ConnectionSettings.Insert("ExchangeFormat", "");
	
	ConnectionSettings.Insert("Description",               "");
	ConnectionSettings.Insert("PeerInfobaseName", "");
	
	ConnectionSettings.Insert("Prefix",               "");
	ConnectionSettings.Insert("CorrespondentPrefix", "");
	
	ConnectionSettings.Insert("SourceInfobaseID", "");
	ConnectionSettings.Insert("DestinationInfobaseID", "");
	
	ConnectionSettings.Insert("CorrespondentEndpoint");

	ConnectionSettings.Insert("Peer");
	ConnectionSettings.Insert("CorrespondentDataArea", 0);
	
	If XDTOSetup Then
		XDTOCorrespondentSettings = New Structure;
		XDTOCorrespondentSettings.Insert("SupportedVersions", New Array);
		XDTOCorrespondentSettings.Insert("SupportedObjects");
		
		ConnectionSettings.Insert("XDTOCorrespondentSettings", XDTOCorrespondentSettings);
	EndIf;
	
	Return ConnectionSettings;
	
EndFunction

#Region ApplicationsList

// Parameters:
//   Settings - Structure - operation execution setting details.
//   HandlerParameters - Structure - secondary parameters:
//     * AdditionalParameters - Structure - arbitrary additional parameters.
//   ContinueWait - Boolean - True if a long-running operation is running.
//
Procedure OnStartGetApplicationList(Settings, HandlerParameters, ContinueWait = True) Export
	
	If Not Common.SubsystemExists("CloudTechnology") Then
		Return;
	EndIf;
		
	ModuleMessagesSaaS = Common.CommonModule("MessagesSaaS");
	
	HandlerParameters = TimeConsumingOperationHandlerParameters();
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	Try
		// Sending a message to SaaS.
		Message = ModuleMessagesSaaS.NewMessage(
			MessagesDataExchangeAdministrationManagementInterface.GetDataSynchronizationSettingsMessage());
			
		// ExchangeFormat - Mustn't filter as the whole table is needed, including the nodes with setup synchronization.
		AdditionalProperties = New Structure("Mode");
		FillPropertyValues(AdditionalProperties, Settings);
		
		Message.AdditionalInfo = XDTOSerializer.WriteXDTO(AdditionalProperties);
			
		HandlerParameters.OperationID = DataExchangeSaaS.SendMessage(Message);
			
		CommitTransaction();
	Except
		RollbackTransaction();
		
		ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(DataExchangeSaaS.EventLogEventDataSynchronizationMonitor(),
			EventLogLevel.Error, , , ErrorMessage);
			
		HandlerParameters.Cancel = True;
		HandlerParameters.ErrorMessage = ErrorMessage;
		HandlerParameters.OperationID = Undefined;
		
		ContinueWait = False;
	EndTry;
	
	If Not HandlerParameters.Cancel Then
		ModuleMessagesSaaS.DeliverQuickMessages();
		
		For Each SettingItem In Settings Do
			HandlerParameters.AdditionalParameters.Insert(SettingItem.Key, SettingItem.Value);
		EndDo;
		
		ContinueWait = True;
	EndIf;
	
EndProcedure

// Parameters:
//   HandlerParameters - Structure - secondary parameters:
//     * AdditionalParameters - Structure - arbitrary additional parameters.
//   ContinueWait - Boolean - True if a long-running operation is not completed yet.
//
Procedure OnWaitForGetApplicationList(HandlerParameters, ContinueWait = True) Export
	
	If HandlerParameters.AdditionalParameters.Property("WaitForSessionGetCorrespondentParameters") Then
		
		ContinueWait = False;
		
		AreasToDetermineNodeCodes = HandlerParameters.AdditionalParameters.AreasToDetermineNodeCodes.Get();
		
		For Each Area In AreasToDetermineNodeCodes Do
			
			For Each NodesCodesString In Area.NodesCodes Do
				
				If NodesCodesString.ContinueWait Then
					OnWaitSystemMessagesExchangeSession(NodesCodesString.HandlerParameters, NodesCodesString.ContinueWait);
				EndIf;
				
				If Not NodesCodesString.ContinueWait
					And Not ValueIsFilled(NodesCodesString.PredefinedNodeCode)
					And Not NodesCodesString.HandlerParameters.Cancel Then
					
					CorrespondentParameters = InformationRegisters.SystemMessageExchangeSessions.GetSessionData(
						NodesCodesString.HandlerParameters.OperationID).Get();
						
					If CorrespondentParameters.Property("InfoBaseAdmParams") Then
						If CorrespondentParameters.InfoBaseAdmParams.NodeExists Then
							NodesCodesString.PredefinedNodeCode = CorrespondentParameters.InfoBaseAdmParams.ThisNodeCode;
						EndIf;
					EndIf;
					
				EndIf;
				
				ContinueWait = ContinueWait Or NodesCodesString.ContinueWait;
				
			EndDo;
			
		EndDo;
		
		HandlerParameters.AdditionalParameters.AreasToDetermineNodeCodes =
			New ValueStorage(AreasToDetermineNodeCodes, New Deflation(9));
		
	Else
		OnWaitSystemMessagesExchangeSession(HandlerParameters, ContinueWait);
		
		If Not ContinueWait
			And Not HandlerParameters.Cancel Then
			
			SynchronizationSettingsFromServiceManager = Undefined;
			
			SetPrivilegedMode(True);
			Try
				SynchronizationSettingsFromServiceManager = InformationRegisters.SystemMessageExchangeSessions.GetSessionData(
					HandlerParameters.OperationID).Get();
			Except
				Information = ErrorInfo();
				
				HandlerParameters.Cancel = True;
				HandlerParameters.ErrorMessage = ErrorProcessing.BriefErrorDescription(Information);
				HandlerParameters.OperationID = Undefined;
				
				WriteLogEvent(DataExchangeSaaS.EventLogEventDataSynchronizationMonitor(),
					EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(Information));
					
				Return;
			EndTry;
			
			DeleteUnnecessarySynchronizationSettingsRows(SynchronizationSettingsFromServiceManager, HandlerParameters.AdditionalParameters);
			
			HasPredefinedNodeCode = SynchronizationSettingsFromServiceManager.Columns.Find("PredefinedNodeCode") <> Undefined;
			If Not HasPredefinedNodeCode Then
				SynchronizationSettingsFromServiceManager.Columns.Add("PredefinedNodeCode", New TypeDescription("String"));
			EndIf;
			
			XDTOSynchronizationSettingsStrings = SynchronizationSettingsFromServiceManager.FindRows(
				New Structure("IsXDTOExchangePlan, SynchronizationConfigured", True, True));
				
			AreasToDetermineNodeCodes = New ValueTable;
			AreasToDetermineNodeCodes.Columns.Add("DataArea", New TypeDescription("Number"));
			AreasToDetermineNodeCodes.Columns.Add("ExchangePlan",    New TypeDescription("String"));
			AreasToDetermineNodeCodes.Columns.Add("NodesCodes");
				
			For Each XDTOSynchronizationSettingsString In XDTOSynchronizationSettingsStrings Do
				
				If ValueIsFilled(XDTOSynchronizationSettingsString.PredefinedNodeCode) Then
					Continue;
				EndIf;
				
				NodesCodes = New ValueTable;
				NodesCodes.Columns.Add("ThisNodeCode",             New TypeDescription("String"));
				NodesCodes.Columns.Add("PredefinedNodeCode", New TypeDescription("String"));
				NodesCodes.Columns.Add("HandlerParameters");
				NodesCodes.Columns.Add("ContinueWait",       New TypeDescription("Boolean"));
				
				Query = New Query(
				"SELECT
				|	T.Ref AS ExchangeNode
				|FROM
				|	#ExchangePlanTable AS T
				|WHERE
				|	NOT T.ThisNode");
				
				Query.Text = StrReplace(Query.Text,
					"#ExchangePlanTable", "ExchangePlan." + XDTOSynchronizationSettingsString.ExchangePlan);
				
				Selection = Query.Execute().Select();
				While Selection.Next() Do
					ThisNodeCode = DataExchangeServer.NodeIDForExchange(Selection.ExchangeNode);
					
					CorrespondentDataArea = InformationRegisters.XDTODataExchangeSettings.CorrespondentSettingValue(Selection.ExchangeNode,
						"CorrespondentDataArea");
					
					If XDTOSynchronizationSettingsString.DataArea = CorrespondentDataArea Then
						NodesCodesString = NodesCodes.Add();
						NodesCodesString.ThisNodeCode = ThisNodeCode;
						NodesCodesString.PredefinedNodeCode = DataExchangeServer.CorrespondentNodeIDForExchange(Selection.ExchangeNode);
						NodesCodesString.ContinueWait = False; 
						Break;
					EndIf;
				EndDo;
				
				Selection.Reset();
				
				While Selection.Next() Do
					ThisNodeCode = DataExchangeServer.NodeIDForExchange(Selection.ExchangeNode);
					
					If Not NodesCodes.Find(ThisNodeCode, "ThisNodeCode") = Undefined Then
						Continue;
					EndIf;
					
					NodesCodesString = NodesCodes.Add();
					NodesCodesString.ThisNodeCode = ThisNodeCode;
					NodesCodesString.ContinueWait = True;
					
				EndDo;
				
				Area = AreasToDetermineNodeCodes.Add();
				FillPropertyValues(Area, XDTOSynchronizationSettingsString, "DataArea, ExchangePlan");
				Area.NodesCodes = NodesCodes;
				
			EndDo;
				
			HandlerParameters.AdditionalParameters.Insert("SynchronizationSettingsFromServiceManager",
				New ValueStorage(SynchronizationSettingsFromServiceManager, New Deflation(9)));
			HandlerParameters.AdditionalParameters.Insert("AreasToDetermineNodeCodes",
					New ValueStorage(AreasToDetermineNodeCodes, New Deflation(9)));
				
			If AreasToDetermineNodeCodes.Count() > 0 Then
				
				OnStartGetCodesOfDataAreasNodes(HandlerParameters);
				
				If Not HandlerParameters.Cancel Then
					HandlerParameters.AdditionalParameters.Insert("WaitForSessionGetCorrespondentParameters");
					ContinueWait = True;
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Parameters:
//   HandlerParameters - Structure - secondary parameters:
//     * AdditionalParameters - Structure - arbitrary additional parameters.
//   CompletionStatus - Structure - operation execution result details.
//
Procedure OnCompleteGettingApplicationsList(HandlerParameters, CompletionStatus) Export
	
	InitializeCompletionStatusOfTimeConsumingOperation(CompletionStatus);
	
	If HandlerParameters.Cancel Then
		FillPropertyValues(CompletionStatus, HandlerParameters, "Cancel, ErrorMessage");
	Else
		
		Try
			CompletionStatus.Result = DataSynchronizationApplicationsTable(HandlerParameters.AdditionalParameters);
		Except
			Information = ErrorInfo();
			
			CompletionStatus.Cancel = True;
			CompletionStatus.ErrorMessage = ErrorProcessing.BriefErrorDescription(Information);
			
			WriteLogEvent(DataExchangeSaaS.EventLogEventDataSynchronizationMonitor(),
				EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(Information));
		EndTry;
		
	EndIf;
	
	HandlerParameters = Undefined;
	
EndProcedure

#EndRegion

#Region SaveConnectionSettings

// Parameters:
//   ConnectionSettings - Structure - operation execution setting details.
//   HandlerParameters - Structure - secondary parameters:
//     * AdditionalParameters - Structure - arbitrary additional parameters.
//   ContinueWait - Boolean - True if a long-running operation is running.
//
Procedure OnStartSaveConnectionSettings(ConnectionSettings, HandlerParameters, ContinueWait = True) Export
	
	BackgroundJobKey = DataExchangeServer.BackgroundJobKey(ConnectionSettings.ExchangePlanName,
		NStr("vi = 'Tùy chỉnh kết nối đến cơ sở trao đổi dữ liệu';
			|ru = 'Настройка подключения к корреспонденту';
			|en = 'Peer infobase connection setup'; fa = 'Peer infobase connection setup';
			|it = 'Configurazione della connessione al corrispondente';
			|pl = 'Konfiguracja podłączenia do korespondenta';
			|tr = 'Muhabir ile bağlantı ayarları'"));

	If DataExchangeServer.HasActiveBackgroundJobs(BackgroundJobKey) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đang thực hiện tùy chỉnh kết nối đến cơ sở trao đổi dữ liệu đối với ""%1"".';
				|ru = 'Настройка подключения к корреспонденту для ""%1"" уже выполняется.';
				|en = 'Connection to ""%1"" is being set up.'; fa = 'Connection to ""%1"" is being set up.';
				|it = 'Configurazione della connessione al corrispondente per ""%1"" in corso.';
				|pl = 'Konfiguracja podłączenia do korespondenta dla ""%1"" jest już w toku.';
				|tr = '""%1"" için muhabir ile bağlantı ayarları zaten yapılıyor.'"), ConnectionSettings.ExchangePlanName);
	EndIf;
		
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("ConnectionSettings", ConnectionSettings);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID);
	ExecutionParameters.BackgroundJobDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Tùy chỉnh kết nối đến cơ sở trao đổi dữ liệu: %1.';
			|ru = 'Настройка подключения к корреспонденту: %1.';
			|en = 'Peer infobase ""%1"" connection setup'; fa = 'Peer infobase ""%1"" connection setup';
			|it = 'Configurazione della connessione al corrispondente: %1.';
			|pl = 'Konfiguracja podłączenia do korespondenta: %1.';
			|tr = 'Muhabir ile bağlantı ayarları: %1.'"), ConnectionSettings.ExchangePlanName);
	ExecutionParameters.BackgroundJobKey = BackgroundJobKey;
	ExecutionParameters.RunNotInBackground1    = False;
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.DataSynchronizationBetweenWebApplicationsSetupWizard.ConfigureExchangeStep1_3_0_1_1",
		ProcedureParameters,
		ExecutionParameters);
		
	OnStartTimeConsumingOperation(BackgroundJob, HandlerParameters, ContinueWait);
	
	If Not ContinueWait
		And Not HandlerParameters.Cancel Then
		HandlerParameters.AdditionalParameters.Insert("BackgroundJobCompleted");
		ContinueWait = True;
	EndIf;
	
	HandlerParameters.AdditionalParameters.Insert("ConnectionSettings", ConnectionSettings);
	
EndProcedure

// Parameters:
//   HandlerParameters - Structure - secondary parameters:
//     * AdditionalParameters - Structure - arbitrary additional parameters.
//   ContinueWait - Boolean - True if a long-running operation is not completed yet.
//
Procedure OnWaitForSaveConnectionSettings(HandlerParameters, ContinueWait = True) Export
	
	If HandlerParameters.AdditionalParameters.Property("WaitForMessageExchangeSessionInSystem1") Then
		
		OnWaitSystemMessagesExchangeSession(
			HandlerParameters.AdditionalParameters.SessionHandlerParameters, ContinueWait);
			
		If Not ContinueWait
			And Not HandlerParameters.AdditionalParameters.SessionHandlerParameters.Cancel Then
			HandlerParameters.AdditionalParameters.Insert("WaitForMessageExchangeSessionInSystem2");
			HandlerParameters.AdditionalParameters.Delete("WaitForMessageExchangeSessionInSystem1");
			
			OnStartSaveExchangeSettingInServiceManager(HandlerParameters.AdditionalParameters.ConnectionSettings,
				HandlerParameters.AdditionalParameters.SessionHandlerParameters, ContinueWait);
		EndIf;
			
	ElsIf HandlerParameters.AdditionalParameters.Property("WaitForMessageExchangeSessionInSystem2") Then
			
		OnWaitSystemMessagesExchangeSession(
			HandlerParameters.AdditionalParameters.SessionHandlerParameters, ContinueWait);
			
	Else
		
		JobCompleted = False;
		
		If HandlerParameters.AdditionalParameters.Property("BackgroundJobCompleted") Then
			JobCompleted = True;
		Else
			OnWaitTimeConsumingOperation(HandlerParameters, ContinueWait);
			
			JobCompleted = Not ContinueWait And Not HandlerParameters.Cancel;
		EndIf;
		
		If JobCompleted Then
			
			Result = GetFromTempStorage(HandlerParameters.ResultAddress);
			
			SessionHandlerParameters = Result.SessionHandlerParameters;
			HandlerParameters.AdditionalParameters.Insert("Peer", Result.Peer);
			
			If SessionHandlerParameters.Cancel Then
				ContinueWait = False;
				HandlerParameters.Cancel = True;
				HandlerParameters.ErrorMessage = SessionHandlerParameters.ErrorMessage;
			Else
				ContinueWait = True;
				HandlerParameters.AdditionalParameters.Insert("WaitForMessageExchangeSessionInSystem1");
				HandlerParameters.AdditionalParameters.Insert("SessionHandlerParameters", SessionHandlerParameters);
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Parameters:
//   HandlerParameters - Structure - secondary parameters:
//     * AdditionalParameters - Structure - arbitrary additional parameters.
//   CompletionStatus - Structure - operation execution result details.
//
Procedure OnCompleteConnectionSettingsSaving(HandlerParameters, CompletionStatus) Export
	
	InitializeCompletionStatusOfTimeConsumingOperation(CompletionStatus);
	
	If HandlerParameters.Cancel Then
		FillPropertyValues(CompletionStatus, HandlerParameters, "Cancel, ErrorMessage");
	Else
		SessionHandlerParameters = HandlerParameters.AdditionalParameters.SessionHandlerParameters;
		
		Result = New Structure;
		Result.Insert("ConnectionSettingsSaved", True);
		Result.Insert("ExchangeNode",                    Undefined);
		Result.Insert("ErrorMessage",             "");
		
		If SessionHandlerParameters.Cancel Then
			// Deleting an exchange node in the current infobase.
			If ValueIsFilled(HandlerParameters.AdditionalParameters.Peer) Then
				DataExchangeServer.DeleteSynchronizationSetting(HandlerParameters.AdditionalParameters.Peer);
			EndIf;
			
			Result.ConnectionSettingsSaved = False;
			Result.ErrorMessage             = SessionHandlerParameters.ErrorMessage;
		Else
			Result.Insert("ExchangeNode", HandlerParameters.AdditionalParameters.Peer);
		EndIf;
		
		CompletionStatus.Result = Result;
		
	EndIf;
	
	HandlerParameters = Undefined;
	
EndProcedure

#EndRegion

#Region GetCommonDataOfCorrespondentNodes

// Parameters:
//   ConnectionSettings - Structure - operation execution setting details.
//   HandlerParameters - Structure - secondary parameters:
//     * AdditionalParameters - Structure - arbitrary additional parameters.
//   ContinueWait - Boolean - True if a long-running operation is running.
//
Procedure OnStartGetCommonDataFromCorrespondentNodes(ConnectionSettings, HandlerParameters, ContinueWait = True) Export
	
	If Not Common.SubsystemExists("CloudTechnology") Then
		Return;
	EndIf;
		
	ModuleMessagesSaaS = Common.CommonModule("MessagesSaaS");
	
	HandlerParameters = TimeConsumingOperationHandlerParameters();
	HandlerParameters.AdditionalParameters.Insert("ConnectionSettings", ConnectionSettings);
	
	ExchangePlanName              = ConnectionSettings.ExchangePlanName;
	CorrespondentDataArea = ConnectionSettings.CorrespondentDataArea;
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	Try
		// Send a message to a peer infobase.
		Message = ModuleMessagesSaaS.NewMessage(
			DataExchangeMessagesManagementInterface.GetCommonDataOfCorrespondentNodeMessage());
		Message.Body.CorrespondentZone = CorrespondentDataArea;
		
		Message.Body.ExchangePlan = ExchangePlanName;
		
		AdditionalProperties = New Structure;
		AdditionalProperties.Insert("Interface", "3.0.1.1");
		
		Message.AdditionalInfo = XDTOSerializer.WriteXDTO(AdditionalProperties);
		
		HandlerParameters.OperationID = DataExchangeSaaS.SendMessage(Message);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		
		ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(DataExchangeSaaS.EventLogEventDataSynchronizationSetup(),
			EventLogLevel.Error, , , ErrorMessage);
			
		HandlerParameters.Cancel = True;
		HandlerParameters.ErrorMessage = ErrorMessage;
		HandlerParameters.OperationID = Undefined;
		
		ContinueWait = False;
		Return;
	EndTry;
	
	ModuleMessagesSaaS.DeliverQuickMessages();
	
EndProcedure

// For internal use.
//
Procedure OnWaitForGetCommonDataFromCorrespondentNodes(HandlerParameters, ContinueWait = True) Export
	
	OnWaitSystemMessagesExchangeSession(HandlerParameters, ContinueWait);
	
EndProcedure

// Parameters:
//   HandlerParameters - Structure - secondary parameters:
//     * AdditionalParameters - Structure - arbitrary additional parameters.
//   CompletionStatus - Structure - operation execution result details.
//
Procedure OnCompleteGetCommonDataFromCorrespondentNodes(HandlerParameters, CompletionStatus) Export
	
	InitializeCompletionStatusOfTimeConsumingOperation(CompletionStatus);
	
	ConnectionSettings = HandlerParameters.AdditionalParameters.ConnectionSettings;
	
	If HandlerParameters.Cancel Then
		FillPropertyValues(CompletionStatus, HandlerParameters, "Cancel, ErrorMessage");
	Else
		Result = New Structure;
		Result.Insert("CorrespondentParametersReceived", True);
		Result.Insert("CorrespondentParameters");
		Result.Insert("ErrorMessage", "");
		
		SetPrivilegedMode(True);
		
		Try
			// Peer infobase parameters.
			CorrespondentData = InformationRegisters.SystemMessageExchangeSessions.GetSessionData(
				HandlerParameters.OperationID).Get();
				
			If Not CorrespondentData.Property("InfoBaseAdmParams", Result.CorrespondentParameters) Then
				Result.ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không hỗ trợ phiên bản 3.0.1.1 của giao diện ""ОбменДанными"".
					|Để tùy chỉnh kết nối, hãy cập nhật chương trình ""%1"" hoặc bắt đầu tùy chỉnh từ đó.';
					|ru = 'Не поддерживается версия 3.0.1.1 интерфейса ""ОбменДанными"".
					|Для настройки подключения обновите программу ""%1"", или начните настройку из нее.';
					|en = 'DataExchange interface 3.0.1.1 is not supported.
					|To set up the connection, update %1 or start the setup from it.'; fa = 'DataExchange interface 3.0.1.1 is not supported.
					|To set up the connection, update %1 or start the setup from it.';
					|it = 'Non è supportata la versione 3.0.1.1 dell''interfaccia ""ОбменДанными"".
					|Per l''impostazione di connessione, aggiornare il programma ""%1"" o avviare da esso l''impostazione.';
					|pl = 'Nie jest obsługiwana wersja 3.0.1.1 interfejsu ""ОбменДанными"".
					|W celu ustawienia połączenia zaktualizuj program ""%1"", lub rozpocznij ustawienie z niego.';
					|tr = '""ОбменДанными"" arayüzü 3.0.1.1 sürümü desteklenmiyor.
					|Bağlantıyı ayarlamak için ""%1"" programını güncelleyin veya programdan yapılandırmaya başlayın.'"),
					ConnectionSettings.PeerInfobaseName);
				Result.CorrespondentParametersReceived = False;
			EndIf;
			
			CompletionStatus.Result = Result;
			
		Except
			CompletionStatus.Cancel = True;
			CompletionStatus.ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			
			WriteLogEvent(DataExchangeSaaS.EventLogEventDataSynchronizationSetup(),
				EventLogLevel.Error, , , CompletionStatus.ErrorMessage);
			
			Return;
		EndTry;
	EndIf;
	
	HandlerParameters = Undefined;
	
EndProcedure

#EndRegion

#Region DeleteDataSynchronizationSetting

// For internal use.
//
Procedure OnStartDeleteSynchronizationSettings(DeletionSettings, HandlerParameters, ContinueWait) Export
	
	If Not Common.SubsystemExists("CloudTechnology") Then
		Return;
	EndIf;
		
	ModuleMessagesSaaS = Common.CommonModule("MessagesSaaS");
	
	HandlerParameters = TimeConsumingOperationHandlerParameters();
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	Try
		// Sending a message to the service manager.
		Message = ModuleMessagesSaaS.NewMessage(
			MessagesDataExchangeAdministrationManagementInterface.DisableSynchronizationMessage());
			
		Message.Body.CorrespondentZone = DeletionSettings.CorrespondentDataArea;
		Message.Body.ExchangePlan      = DeletionSettings.ExchangePlanName;
		
		HandlerParameters.OperationID = DataExchangeSaaS.SendMessage(Message);
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Tắt đồng bộ dữ liệu ""%1"" với ứng dụng ""%2"".';
				|ru = 'Отключение синхронизации данных ""%1"" с приложением ""%2"".';
				|en = 'Disable ""%1"" data synchronization with application ""%2"".'; fa = 'Disable ""%1"" data synchronization with application ""%2"".';
				|it = 'Disattivazione della sincronizzazione di dati ""%1"" con applicazione ""%2"".';
				|pl = 'Wyłączenie synchronizacji danych ""%1"" z aplikacją ""%2"".';
				|tr = '""%1"" verilerinin ""%2"" uygulamasıyla senkronizasyonu devre dışı bırakılıyor.'"),
			DeletionSettings.ExchangePlanName, XMLString(DeletionSettings.CorrespondentDataArea));
		
		WriteLogEvent(DataExchangeSaaS.EventLogEventDataSynchronizationSetup(),
			EventLogLevel.Information, , , MessageText);
		
		CommitTransaction();
	Except
		
		RollbackTransaction();
		
		ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(DataExchangeSaaS.EventLogEventDataSynchronizationSetup(),
			EventLogLevel.Error, , , ErrorMessage);
		
		HandlerParameters.Cancel = True;
		HandlerParameters.ErrorMessage = ErrorMessage;
		HandlerParameters.OperationID = Undefined;
		
		ContinueWait = False;
		Return;
	EndTry;
	
	ModuleMessagesSaaS.DeliverQuickMessages();
	ContinueWait = True;
	
EndProcedure

// For internal use.
//
Procedure OnWaitForDeleteSynchronizationSettings(HandlerParameters, ContinueWait) Export
	
	OnWaitSystemMessagesExchangeSession(HandlerParameters, ContinueWait);
	
EndProcedure

// For internal use.
//
Procedure OnCompleteSynchronizationSettingsDeletion(HandlerParameters, CompletionStatus) Export
	
	InitializeCompletionStatusOfTimeConsumingOperation(CompletionStatus);
	
	If HandlerParameters.Cancel Then
		FillPropertyValues(CompletionStatus, HandlerParameters, "Cancel, ErrorMessage");
	Else
		
		Result = New Structure;
		Result.Insert("SettingDeleted",                 True);
		Result.Insert("SettingDeletedInCorrespondent",  True);
		Result.Insert("ErrorMessage",                "");
		Result.Insert("ErrorMessageInCorrespondent", "");
		
		CompletionStatus.Result = Result;
		
	EndIf;
	
	HandlerParameters = Undefined;
	
EndProcedure

#EndRegion

#Region TransportChange

// For internal use.
//
Procedure OnStartDisconnectingFromSM(Settings, HandlerParameters, ContinueWait) Export
	
	If Not Common.SubsystemExists("CloudTechnology") Then
		Return;
	EndIf;
		
	ModuleMessagesSaaS = Common.CommonModule("MessagesSaaS");
	
	HandlerParameters = TimeConsumingOperationHandlerParameters();
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	Try
		// Sending a message to the service manager.
		Message = ModuleMessagesSaaS.NewMessage(
			MessagesDataExchangeAdministrationManagementInterface.MessageDisableSyncOverSM());
			
		Message.Body.CorrespondentZone = Settings.CorrespondentDataArea;
		Message.Body.ExchangePlan      = Settings.ExchangePlanName;
				
		HandlerParameters.OperationID = DataExchangeSaaS.SendMessage(Message);
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Tắt sử dụng đồng bộ dữ liệu qua bộ quản lý dịch vụ (chuyển sang web-service) ""%1"" với ứng dụng ""%2"".';
				|ru = 'Отключение синхронизации данных через менеджер сервиса (переход на веб-сервис) ""%1"" с приложением ""%2"".';
				|en = 'Disable data synchronization using service manager (switch to a web service) ""%1"" with application ""%2"".'; fa = 'Disable data synchronization using service manager (switch to a web service) ""%1"" with application ""%2"".';
				|it = 'Annullamento sincronizzazione dati tramite il manager del servizio (pasaggio al servizio web) ""%1"" con l''applicazione ""%2"".';
				|pl = 'Wyłączenie synchronizacji danych przez menedżer danych serwisu (przejście do serwisu webowego) ""%1"" z aplikacją ""%2"".';
				|tr = '""%1"" servis yöneticisi aracılığıyla (web servisine geçiş) ""%2"" uygulamasıyla veri senkronizasyonunu devre dışı bırak.'"),
			Settings.ExchangePlanName, XMLString(Settings.CorrespondentDataArea));
		
		WriteLogEvent(DataExchangeSaaS.EventLogEventDataSynchronizationSetup(),
			EventLogLevel.Information, , , MessageText);
		
		CommitTransaction();
	Except
		
		RollbackTransaction();
		
		ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(DataExchangeSaaS.EventLogEventDataSynchronizationSetup(),
			EventLogLevel.Error, , , ErrorMessage);
		
		HandlerParameters.Cancel = True;
		HandlerParameters.ErrorMessage = ErrorMessage;
		HandlerParameters.OperationID = Undefined;
		
		ContinueWait = False;
		Return;
	EndTry;
	
	ModuleMessagesSaaS.DeliverQuickMessages();
	ContinueWait = True;
	
EndProcedure

// For internal use.
//
Procedure OnWaitDisconnectingFromSM(HandlerParameters, ContinueWait) Export
	
	OnWaitSystemMessagesExchangeSession(HandlerParameters, ContinueWait);
	
EndProcedure

// For internal use.
//
Procedure OnCompleteDisconnectingFromSM(HandlerParameters, CompletionStatus) Export 
	
	InitializeCompletionStatusOfTimeConsumingOperation(CompletionStatus);
	
	If HandlerParameters.Cancel Then
		FillPropertyValues(CompletionStatus, HandlerParameters, "Cancel, ErrorMessage");
	Else
		
		Result = New Structure;
		Result.Insert("IsTransportChanged",                 True);
		Result.Insert("IsTransportChangedInPeer",  True);
		Result.Insert("ErrorMessage",                "");
		Result.Insert("ErrorMessageInCorrespondent", "");
		
		CompletionStatus.Result = Result;
		
	EndIf;
	
	HandlerParameters = Undefined;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region MessagesExchangeSessions

Procedure OnWaitSystemMessagesExchangeSession(HandlerParameters, ContinueWait)
	
	SessionStatus = "";
	Try
		SessionStatus = SessionStatus(HandlerParameters.OperationID);
	Except
		ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(DataExchangeSaaS.EventLogEventDataSynchronizationMonitor(),
			EventLogLevel.Error, , , ErrorMessage);
			
		HandlerParameters.Cancel = True;
		HandlerParameters.ErrorMessage = ErrorMessage;
		HandlerParameters.OperationID = Undefined;
		
		ContinueWait  = False;
		Return;
	EndTry;
	
	If SessionStatus = "Success" Then
		
		ContinueWait = False;
		
	ElsIf SessionStatus = "Error" Then
		
		HandlerParameters.Cancel = True;
		HandlerParameters.ErrorMessage = SessionErrorDetails(HandlerParameters.OperationID);
		HandlerParameters.OperationID = Undefined;
		ContinueWait  = False;
		
	Else
		
		ContinueWait = True;
		
	EndIf;
	
EndProcedure

Function SessionStatus(Val Session)
	
	SetPrivilegedMode(True);
	
	Return InformationRegisters.SystemMessageExchangeSessions.SessionStatus(Session);
	
EndFunction

Function SessionErrorDetails(Val Session)
	
	SetPrivilegedMode(True);
	
	Return InformationRegisters.SystemMessageExchangeSessions.SessionErrorDetails(Session);
	
EndFunction 

#EndRegion

#Region TimeConsumingOperations1

// For internal use.
//
Procedure OnStartTimeConsumingOperation(BackgroundJob, HandlerParameters, ContinueWait = True)
	
	HandlerParameters = TimeConsumingOperationHandlerParameters(BackgroundJob);
	
	If BackgroundJob.Status = "Running" Then
		HandlerParameters.ResultAddress       = BackgroundJob.ResultAddress;
		HandlerParameters.OperationID = BackgroundJob.JobID;
		HandlerParameters.TimeConsumingOperation    = True;
		
		ContinueWait = True;
		Return;
	ElsIf BackgroundJob.Status = "Completed2" Then
		HandlerParameters.ResultAddress    = BackgroundJob.ResultAddress;
		HandlerParameters.TimeConsumingOperation = False;
		
		ContinueWait = False;
		Return;
	Else
		HandlerParameters.ErrorMessage = BackgroundJob.BriefErrorDescription;
		If ValueIsFilled(BackgroundJob.DetailErrorDescription) Then
			HandlerParameters.ErrorMessage = BackgroundJob.DetailErrorDescription;
		EndIf;
		
		HandlerParameters.Cancel = True;
		HandlerParameters.TimeConsumingOperation = False;
		
		ContinueWait = False;
		Return;
	EndIf;
	
EndProcedure

// For internal use.
//
Procedure OnWaitTimeConsumingOperation(HandlerParameters, ContinueWait = True)
	
	If HandlerParameters.Cancel
		Or Not HandlerParameters.TimeConsumingOperation Then
		ContinueWait = False;
		Return;
	EndIf;
	
	JobCompleted = False;
	Try
		JobCompleted = TimeConsumingOperations.JobCompleted(HandlerParameters.OperationID);
	Except
		HandlerParameters.Cancel             = True;
		HandlerParameters.ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(DataExchangeServer.DataExchangeCreationEventLogEvent(),
			EventLogLevel.Error, , , HandlerParameters.ErrorMessage);
	EndTry;
		
	If HandlerParameters.Cancel Then
		ContinueWait = False;
		Return;
	EndIf;
	
	ContinueWait = Not JobCompleted;
	
EndProcedure

Function TimeConsumingOperationHandlerParameters(BackgroundJob = Undefined)
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("BackgroundJob",          BackgroundJob);
	HandlerParameters.Insert("Cancel",                   False);
	HandlerParameters.Insert("ErrorMessage",       "");
	HandlerParameters.Insert("TimeConsumingOperation",      False);
	HandlerParameters.Insert("OperationID",   Undefined);
	HandlerParameters.Insert("ResultAddress",         Undefined);
	HandlerParameters.Insert("AdditionalParameters", New Structure);
	
	Return HandlerParameters;
	
EndFunction

Procedure InitializeCompletionStatusOfTimeConsumingOperation(CompletionStatus)
	
	CompletionStatus = New Structure;
	CompletionStatus.Insert("Cancel",             False);
	CompletionStatus.Insert("ErrorMessage", "");
	CompletionStatus.Insert("Result",         Undefined);

EndProcedure

#EndRegion

// Parameters:
//   HandlerParameters - Structure - secondary parameters:
//     * AdditionalParameters - Structure - arbitrary additional parameters.
//
Procedure OnStartGetCodesOfDataAreasNodes(HandlerParameters)
	
	If Not Common.SubsystemExists("CloudTechnology") Then
		Return;
	EndIf;
		
	ModuleMessagesSaaS = Common.CommonModule("MessagesSaaS");
	
	AreasToDetermineNodeCodes = HandlerParameters.AdditionalParameters.AreasToDetermineNodeCodes.Get();
	
	SetPrivilegedMode(True);
	
	For Each Area In AreasToDetermineNodeCodes Do
		
		For Each NodesCodesString In Area.NodesCodes Do
			
			If Not NodesCodesString.ContinueWait Then
				Continue;
			EndIf;
			
			NodesCodesString.HandlerParameters = TimeConsumingOperationHandlerParameters();
		
			BeginTransaction();
			Try
				Message = ModuleMessagesSaaS.NewMessage(
					DataExchangeMessagesManagementInterface.GetCorrespondentAccountingParametersMessage());
					
				Message.Body.ExchangePlan      = Area.ExchangePlan;
				Message.Body.CorrespondentCode = NodesCodesString.ThisNodeCode;
				
				Message.Body.CorrespondentZone = Area.DataArea;
				
				AdditionalProperties = New Structure;
				AdditionalProperties.Insert("Interface", "3.0.1.1");
				
				Message.AdditionalInfo = XDTOSerializer.WriteXDTO(AdditionalProperties);
			
				NodesCodesString.HandlerParameters.OperationID = DataExchangeSaaS.SendMessage(Message);
					
				CommitTransaction();
			Except
				RollbackTransaction();
				
				ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
				
				WriteLogEvent(DataExchangeSaaS.EventLogEventDataSynchronizationMonitor(),
					EventLogLevel.Error, , , ErrorMessage);
					
				HandlerParameters.Cancel = True;
				HandlerParameters.ErrorMessage = ErrorMessage;
				HandlerParameters.OperationID = Undefined;
				
				Break;
			EndTry;
			
		EndDo;
		
		If HandlerParameters.Cancel Then
			Break;
		EndIf;
		
	EndDo;
	
	If Not HandlerParameters.Cancel Then
		ModuleMessagesSaaS.DeliverQuickMessages();
	EndIf;
	
	HandlerParameters.AdditionalParameters.AreasToDetermineNodeCodes =
		New ValueStorage(AreasToDetermineNodeCodes, New Deflation(9));
	
EndProcedure

Procedure OnStartSaveExchangeSettingInServiceManager(ConnectionSettings, HandlerParameters, ContinueWait)
	
	If Not Common.SubsystemExists("CloudTechnology") Then
		Return;
	EndIf;
		
	ModuleMessagesSaaS = Common.CommonModule("MessagesSaaS");
	
	HandlerParameters = TimeConsumingOperationHandlerParameters();
	
	ExchangePlanName              = ConnectionSettings.ExchangePlanName;
	CorrespondentDataArea = ConnectionSettings.CorrespondentDataArea;
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	Try
		// Sending a message to the service manager, enabling synchronization.
		Message = ModuleMessagesSaaS.NewMessage(
			MessagesDataExchangeAdministrationManagementInterface.EnableSynchronizationMessage());
			
		Message.Body.CorrespondentZone = CorrespondentDataArea;
		Message.Body.ExchangePlan = ExchangePlanName;
		
		HandlerParameters.OperationID = DataExchangeSaaS.SendMessage(Message);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		
		Information = ErrorInfo();
		
		WriteLogEvent(DataExchangeSaaS.EventLogEventDataSynchronizationSetup(),
			EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(Information));
			
		HandlerParameters.Cancel = True;
		HandlerParameters.ErrorMessage = ErrorProcessing.BriefErrorDescription(Information);
		HandlerParameters.OperationID = Undefined;
		
		ContinueWait = False;
		Return;
	EndTry;
	
	ModuleMessagesSaaS.DeliverQuickMessages();
	ContinueWait = True;
	
EndProcedure

Function DataSynchronizationApplicationsTable(Parameters)
	
	SynchronizationSettingsFromServiceManager = Parameters.SynchronizationSettingsFromServiceManager.Get();
	AreasToDetermineNodeCodes          = Parameters.AreasToDetermineNodeCodes.Get();
	
	HasExchangeAdministrationManage_3_0_1_1 = DataExchangeInternalPublication.HasInServiceExchangeAdministrationManage_3_0_1_1();
		
	ApplicationsTable = New ValueTable;
	ApplicationsTable.Columns.Add("ApplicationDescription", New TypeDescription("String"));
	ApplicationsTable.Columns.Add("Prefix",                New TypeDescription("String"));
	ApplicationsTable.Columns.Add("CorrespondentPrefix",  New TypeDescription("String"));
	ApplicationsTable.Columns.Add("CorrespondentVersion",   New TypeDescription("String"));
	ApplicationsTable.Columns.Add("CorrespondentRole",     New TypeDescription("String"));
	ApplicationsTable.Columns.Add("ExchangePlanName",         New TypeDescription("String"));
	ApplicationsTable.Columns.Add("ExchangeFormat",           New TypeDescription("String"));
	ApplicationsTable.Columns.Add("DataArea",          New TypeDescription("Number"));
	
	ApplicationsTable.Columns.Add("Endpoint", New TypeDescription("ExchangePlanRef.MessagesExchange"));
	ApplicationsTable.Columns.Add("CorrespondentEndpoint", New TypeDescription("ExchangePlanRef.MessagesExchange"));
	
	ApplicationsTable.Columns.Add("Peer");
	
	ApplicationsTable.Columns.Add("SyncSetupUnavailable", New TypeDescription("Boolean"));
	ApplicationsTable.Columns.Add("ErrorMessage",                New TypeDescription("String"));
	
	ApplicationsTable.Columns.Add("HasExchangeAdministrationManage_3_0_1_1",	New TypeDescription("Boolean"));
	
	If SynchronizationSettingsFromServiceManager.Count() = 0 Then
		Return ApplicationsTable;
	EndIf;
	
	ListOfProperties = "ApplicationDescription,
					|Prefix,
					|CorrespondentPrefix,
					|CorrespondentVersion,
					|CorrespondentRole,
					|ExchangeFormat,
					|DataArea";
	
	If HasExchangeAdministrationManage_3_0_1_1 Then
		ListOfProperties = ListOfProperties + ",HasExchangeAdministrationManage_3_0_1_1";
	EndIf;
	
	SetPrivilegedMode(True);
	
	For Each SettingFromServiceManager In SynchronizationSettingsFromServiceManager Do
		
		ApplicationRow = ApplicationsTable.Add();
		FillPropertyValues(ApplicationRow, SettingFromServiceManager, ListOfProperties);
		ApplicationRow.ExchangePlanName = SettingFromServiceManager.ExchangePlan;
		ApplicationRow.CorrespondentEndpoint = ExchangePlans["MessagesExchange"].FindByCode(
			SettingFromServiceManager.CorrespondentEndpoint);
			
		If HasExchangeAdministrationManage_3_0_1_1 Then
			ApplicationRow.Endpoint = ExchangePlans["MessagesExchange"].FindByCode(
				SettingFromServiceManager.Endpoint);	
		EndIf;
			
		If ApplicationRow.CorrespondentEndpoint.IsEmpty() Then
			ApplicationRow.SyncSetupUnavailable = True;
			ApplicationRow.ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đối với ứng dụng ""%1"" không tìm thấy điểm cuối có tên định danh ""%2"".';
					|ru = 'Для приложения ""%1"" не найдена конечная точка с идентификатором ""%2"".';
					|en = 'An endpoint with ID ""%2"" is not found for application ""%1"".'; fa = 'An endpoint with ID ""%2"" is not found for application ""%1"".';
					|it = 'Per l''applicazione ""%1"" non è stato trovato endpoint con identificativo ""%2"".';
					|pl = 'Dla aplikacji ""%1"" nie znaleziono punktu końcowego z identyfikatorem ""%2"".';
					|tr = '""%1"" uygulaması için ""%2"" kimlikli uç nokta bulunamadı.'"),
				SettingFromServiceManager.ApplicationDescription,
				SettingFromServiceManager.CorrespondentEndpoint);
		ElsIf SettingFromServiceManager.SynchronizationSetupInServiceManager Then
			ApplicationRow.SyncSetupUnavailable = True;
			ApplicationRow.ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Điểm cuối ""%1"" tạm thời không khả dụng.
				|Hãy thử lại sau.';
				|ru = 'Конечная точка ""%1"" временно недоступна.
				|Повторите попытку позднее.';
				|en = 'Endpoint ""%1"" is temporarily unavailable.
				|Try again later.'; fa = 'Endpoint ""%1"" is temporarily unavailable.
				|Try again later.';
				|it = 'Endpoint ""%1"" temporaneamente non disponibile. 
				|Riprova più tardi.';
				|pl = 'Punkt końcowy ""%1"" jest czasowo niedostępny.
				|Proszę powtórzyć próbę później.';
				|tr = '""%1"" uç noktası geçici olarak kullanılamıyor.
				|Sonra tekrar deneyin.'"),
				ApplicationRow.CorrespondentEndpoint);
		Else
			Try
				TransportSettings = InformationRegisters.DataAreasExchangeTransportSettings.TransportSettings(
					ApplicationRow.CorrespondentEndpoint);
			Except
				Information = ErrorInfo();
				
				WriteLogEvent(DataExchangeSaaS.EventLogEventDataSynchronizationSetup(),
					EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(Information));
				
				ApplicationRow.SyncSetupUnavailable = True;
				ApplicationRow.ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không thể nhận tùy chỉnh kết nối đối với ứng dụng ""%1"" do nguyên nhân:
					|%2
					|Hãy thử lại sau.';
					|ru = 'Не удалось получить настройки подключения для приложения ""%1"" по причине:
					|%2
					|Повторите попытку позднее.';
					|en = 'Cannot get connection settings for application ""%1"" due to:
					|%2
					|'; fa = 'Cannot get connection settings for application ""%1"" due to:
					|%2
					|';
					|it = 'Non è stato possibile ottenere le impostazioni di attivazione per l''applicazione ""%1"" a causa di:
					|%2
					| Riprova più tardi.';
					|pl = 'Nie udało się pobrać ustawień połączenia dla aplikacji ""%1"" z powodu:
					|%2
					|Proszę powtórzyć próbę później.';
					|tr = '""%1"" uygulaması için bağlantı ayarları alınamadı çünkü:
					|%2
					|Sonra tekrar deneyin.'"),
					SettingFromServiceManager.ApplicationDescription,
					ErrorProcessing.BriefErrorDescription(Information));
			EndTry;
		EndIf;
			
		If Not ValueIsFilled(SettingFromServiceManager.PredefinedNodeCode)
			And SettingFromServiceManager.IsXDTOExchangePlan
			And SettingFromServiceManager.SynchronizationConfigured Then
			
			Filter = New Structure("DataArea, ExchangePlan");
			FillPropertyValues(Filter, SettingFromServiceManager);
			
			Areas = AreasToDetermineNodeCodes.FindRows(Filter);
			If Areas.Count() > 0 Then
				Area = Areas[0];
				
				For Each NodesCodesString In Area.NodesCodes Do
					If Not ValueIsFilled(NodesCodesString.PredefinedNodeCode) Then
						Continue;
					EndIf;
					
					SettingFromServiceManager.PredefinedNodeCode = NodesCodesString.PredefinedNodeCode;
					Break;
				EndDo;
			EndIf;
		EndIf;
			
		If ValueIsFilled(SettingFromServiceManager.PredefinedNodeCode) Then
			ApplicationRow.Peer = DataExchangeServer.ExchangePlanNodeByCode(ApplicationRow.ExchangePlanName,
				SettingFromServiceManager.PredefinedNodeCode);
		EndIf;
			
		If Not ValueIsFilled(ApplicationRow.Peer) Then
			NodeCodeSaaS = DataExchangeSaaS.ExchangePlanNodeCodeInService(ApplicationRow.DataArea);	
			ApplicationRow.Peer = DataExchangeServer.ExchangePlanNodeByCode(ApplicationRow.ExchangePlanName, NodeCodeSaaS);
		Else
			
			CorrespondentDataArea = InformationRegisters.XDTODataExchangeSettings.CorrespondentSettingValue(ApplicationRow.Peer,
				"CorrespondentDataArea");
			
			If CorrespondentDataArea = Undefined Then
				InformationRegisters.XDTODataExchangeSettings.UpdateCorrespondentSettings(ApplicationRow.Peer,
					"CorrespondentDataArea", SettingFromServiceManager.DataArea);
			EndIf;
			
			If HasExchangeAdministrationManage_3_0_1_1 Then
				InformationRegisters.XDTODataExchangeSettings.UpdateCorrespondentSettings(ApplicationRow.Peer,
					"HasExchangeAdministrationManage_3_0_1_1", ApplicationRow.HasExchangeAdministrationManage_3_0_1_1);	
			EndIf;			
			
		EndIf;
		
		If Parameters.Mode = "NotConfiguredExchanges"
			And ValueIsFilled(ApplicationRow.Peer) Then
			ApplicationsTable.Delete(ApplicationRow);
		ElsIf Parameters.Mode = "ConfiguredExchanges"
			And Not ValueIsFilled(ApplicationRow.Peer) Then
			ApplicationsTable.Delete(ApplicationRow);
		EndIf;
				
	EndDo;
	
	Return ApplicationsTable;
	
EndFunction

Procedure DeleteUnnecessarySynchronizationSettingsRows(SynchronizationSettingsFromServiceManager, AdditionalParameters)
	
	SynchronizationSettingsFromServiceManager.Columns.Add("IsXDTOExchangePlan", New TypeDescription("Boolean"));
	SynchronizationSettingsFromServiceManager.Columns.Add("DeleteSettingItem",  New TypeDescription("Boolean"));
	
	SynchronizationSettingsFromServiceManager.Columns.Add("ExchangePlanNameToMigrateToNewExchange",
		New TypeDescription("String"));
	
	If SynchronizationSettingsFromServiceManager.Columns.Find("CorrespondentRole") = Undefined Then	
		SynchronizationSettingsFromServiceManager.Columns.Add("CorrespondentRole", New TypeDescription("String"));
	EndIf;
	
	HasCorrespondentVersion = SynchronizationSettingsFromServiceManager.Columns.Find("CorrespondentVersion") <> Undefined;
	
	For Each SettingFromServiceManager In SynchronizationSettingsFromServiceManager Do
		
		If Metadata.ExchangePlans.Find(SettingFromServiceManager.ExchangePlan) = Undefined Then
			SettingFromServiceManager.DeleteSettingItem = True;
			Continue;
		EndIf;
		
		ExchangePlanSettings = DataExchangeServer.ExchangePlanSettingValue(SettingFromServiceManager.ExchangePlan,
			"ExchangePlanNameToMigrateToNewExchange, IsXDTOExchangePlan");
		FillPropertyValues(SettingFromServiceManager, ExchangePlanSettings);
		
		If Not ValueIsFilled(SettingFromServiceManager.SynchronizationConfigured) Then
			SettingFromServiceManager.SynchronizationConfigured = False;
		EndIf;
		
	EndDo;
	
	If AdditionalParameters.Mode = "NotConfiguredExchanges" Then
		
		ConfiguredExchanges = SynchronizationSettingsFromServiceManager.Copy(New Structure("SynchronizationConfigured", True));
		
		// Areas with configured synchronization over internal publications
		Query = New Query;
		Query.Text = 
			"SELECT
			|	SettingsTable.Value AS Value
			|FROM
			|	Catalog.ExchangeMessageTransportSettings.Settings AS SettingsTable
			|WHERE
			|	SettingsTable.Setting = ""CorrespondentDataArea""";
		
		DataAreaInternalPublication = Query.Execute().Unload().UnloadColumn("Value");
		
		For Each SettingFromServiceManager In SynchronizationSettingsFromServiceManager Do
			
			If SettingFromServiceManager.DeleteSettingItem Then
				Continue;
			EndIf;
			
			If Not SettingFromServiceManager.SynchronizationConfigured
				And ConfiguredExchanges.FindRows(New Structure("DataArea", SettingFromServiceManager.DataArea)).Count() > 0 Then
				SettingFromServiceManager.DeleteSettingItem = True;
				Continue;
			EndIf;
			
			SettingVariants = DataExchangeServer.CorrespondentExchangeSettingsOptions(
				SettingFromServiceManager.ExchangePlan,
				?(HasCorrespondentVersion, SettingFromServiceManager.CorrespondentVersion, ""),
				SettingFromServiceManager.CorrespondentRole);
				
			If SettingVariants.Find(AdditionalParameters.SettingID) = Undefined Then
				SettingFromServiceManager.DeleteSettingItem = True;
				Continue;
			EndIf;
			
			If DataAreaInternalPublication.Find(SettingFromServiceManager.DataArea) <> Undefined Then
				SettingFromServiceManager.DeleteSettingItem = True;
				Continue;
			EndIf;
			
			// Excluding a possibility of creating a new data synchronization using an obsolete exchange plan.
			SettingFromServiceManager.DeleteSettingItem = Not SettingFromServiceManager.SynchronizationConfigured
				And ValueIsFilled(SettingFromServiceManager.ExchangePlanNameToMigrateToNewExchange);
			
		EndDo;
				
	EndIf;
	
	For Each SettingFromServiceManager In SynchronizationSettingsFromServiceManager.FindRows(New Structure("DeleteSettingItem", False)) Do
		
		If AdditionalParameters.Mode = "NotConfiguredExchanges" Then
			If SettingFromServiceManager.ExchangePlan <> AdditionalParameters.ExchangePlanName Then
				SettingFromServiceManager.DeleteSettingItem = True;
				Continue;
			EndIf;
		EndIf;
		
		If AdditionalParameters.Mode = "NotConfiguredExchanges"
			And SettingFromServiceManager.SynchronizationConfigured Then
			SettingFromServiceManager.DeleteSettingItem = True;
		ElsIf AdditionalParameters.Mode = "ConfiguredExchanges"
			And Not SettingFromServiceManager.SynchronizationConfigured Then
			SettingFromServiceManager.DeleteSettingItem = True;
		EndIf;
		
	EndDo;
	
	If SynchronizationSettingsFromServiceManager.Find(True, "DeleteSettingItem") <> Undefined Then
		SynchronizationSettingsFromServiceManager = SynchronizationSettingsFromServiceManager.Copy(
			New Structure("DeleteSettingItem", False));
	EndIf;

EndProcedure

#EndRegion

#EndIf
