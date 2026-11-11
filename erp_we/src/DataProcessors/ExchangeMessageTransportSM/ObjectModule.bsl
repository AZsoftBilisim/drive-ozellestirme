///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var ExchangeMessage Export; // For import, it is the name of the file stored in "TempDirectory". For export, the name of the file to be sent out
Var TempDirectory Export; // A temporary exchange directory.
Var DirectoryID Export;
Var Peer Export;
Var ExchangePlanName Export;
Var CorrespondentExchangePlanName Export;
Var ErrorMessage Export;
Var ErrorMessageEventLog Export;

Var NameTemplatesForReceivingMessage Export;
Var NameOfMessageToSend Export; 

#EndRegion

#Region Public

// See DataProcessorObject.ExchangeMessageTransportFILE.SendData
Function SendData(MessageForDataMapping = False) Export
	
	Result = True;
		
	Try
		
		If InternalPublication Then
			
			Result = InternalPublication_SendMessage(MessageForDataMapping);
			
		Else
			
			Result = ServiceManager_SendMessage(MessageForDataMapping);
			
		EndIf;
		
	Except
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo());
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataExport");
		
		Result = False;
		
	EndTry;
	
	Return Result;

EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.GetData
Function GetData() Export
	
	Try
		
		If InternalPublication Then 
			
			Result = InternalPublication_ReceiveMessage();
			
		Else
			
			Result = ServiceManager_GetMessage();
			
		EndIf;
		
	Except
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo());
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataImport");
		
		Result = False;
		
	EndTry;
	
	Return Result;
	
EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.CorrespondentParameters
Function CorrespondentParameters(ConnectionSettings) Export
	
	If InternalPublication Then
		Result = InternalPublication_CorrespondentParameters();
	Else
		Result = ServiceManager_CorrespondentParameters();
	EndIf;
	
	Return Result;
		
EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.BeforeExportData
Function BeforeExportData(MessageForDataMapping = False) Export
	
	Return True;
	
EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.SaveSettingsInCorrespondent
Function SaveSettingsInCorrespondent(ConnectionSettings) Export

	If InternalPublication Then
		Result = InternalPublication_SaveSettingsInCorrespondent(ConnectionSettings);	
	Else
		Result = ServiceManager_SaveSettingsInCorrespondent(ConnectionSettings);	
	EndIf;
	
	Return Result;
	
EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.AuthenticationRequired
Function AuthenticationRequired() Export
	
	Return False;
	
EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.DeleteSynchronizationSettingInCorrespondent
Function DeleteSynchronizationSettingInCorrespondent() Export
	
	If InternalPublication Then
		
		Return InternalPublication_DeleteSynchronizationSettingInCorrespondent();
		
	Else
		
		Return True;
		
	EndIf;
	
EndFunction

#EndRegion

#Region Private

Function InternalPublication_CorrespondentParameters()
	
	Result = ExchangeMessagesTransport.StructureOfResultOfObtainingParametersOfCorrespondent();
	Result.Insert("CorrespondentExchangePlanName", ExchangePlanName);
	
	ModuleMessagesExchangeTransportSettings = Common.CommonModule("InformationRegisters.MessageExchangeTransportSettings");
	ConnectionParameters = ModuleMessagesExchangeTransportSettings.TransportSettingsWS(CorrespondentEndpoint);
	
	Try
		
		CorrespondentVersions = DataExchangeCached.CorrespondentVersions(ConnectionParameters);
		
	Except
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo());
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject);
		
		Result.ConnectionIsSet = False;
		Result.ErrorMessage = ErrorMessage;
				
		Return Result;
		
	EndTry;
		
	InterfaceVersion = DataExchangeWebService.MaximumGeneralVersionOfExchangeInterface(CorrespondentVersions);
	
	If Not StrFind("3.0.2.1, 3.0.2.2", InterfaceVersion)  Then
			
		ErrorMessage = NStr("vi = 'Cơ sở trao đổi tin không hỗ trợ phiên bản giao diện 3.0.2.x ""TraoĐổiDữLiệu"".
								|Để thiết lập kết nối, hãy cập nhật cấu hình của cơ sở trao đổi tin.';
								|ru = 'Корреспондент не поддерживает версию интерфейса 3.0.2.x ""ОбменДанными"".
								|Для настройки подключения обновите конфигурацию корреспондента.';
								|en = 'The peer infobase does not support version 3.0.2.x of the DataExchange interface.
								|To set up the connection, update the peer infobase configuration.'; fa = 'The peer infobase does not support version 3.0.2.x of the DataExchange interface.
								|To set up the connection, update the peer infobase configuration.';
								|it = 'Корреспондент не поддерживает версию интерфейса 3.0.2.x ""ОбменДанными"".
								|Для настройки подключения обновите конфигурацию корреспондента.';
								|pl = 'The peer infobase does not support version 3.0.2.x of the DataExchange interface.
								|To set up the connection, update the peer infobase configuration.';
								|tr = 'Muhabir ""ОбменДанными"" arayüzü 3.0.1.1 sürümünü desteklemiyor.
								|Bağlantı kurmak için muhabir konfigürasyonunu güncelleyin.'");
		
		Result.ConnectionAllowed = False;
		Result.ErrorMessage = ErrorMessage;
			
		Return Result;
		
	EndIf;
		
	Proxy = InternalPublication_Proxy();
	
	If Proxy = Undefined Then
		
		Result.ConnectionIsSet = False;
		Result.ErrorMessage = ErrorMessage;
		
		Return Result;
		
	EndIf;

	AdditionalParameters = New Structure;
	If DataExchangeCached.IsXDTOExchangePlan(ExchangePlanName) Then
		AdditionalParameters.Insert("IsXDTOExchangePlan", True);
	EndIf;
	
	ThisNodeCode = ExchangePlans[ExchangePlanName].ThisNode().Code;
	
	IBParameters = DataExchangeWebService.GetParametersOfInfobase(
		Proxy, ExchangePlanName, ThisNodeCode, ErrorMessage, CorrespondentDataArea, AdditionalParameters);
	
	CorrespondentParameters = XDTOSerializer.ReadXDTO(IBParameters);
	
	If Not CorrespondentParameters.ExchangePlanExists Then
		
		Text = NStr("vi = 'Trong cơ sở trao đổi tin không tìm thấy sơ đồ trao đổi ""%1"".
			|Hãy chắc chắn rằng,
			| - đã chọn đúng dạng ứng dụng để tùy chỉnh trao đổi;
			| - đã chỉ ra đúng địa chỉ ứng dụng trên Internet.';
			|ru = 'В корреспонденте не найден план обмена ""%1"".
			|Убедитесь, что
			| - выбран правильный вид приложения для настройки обмена;
			| - указан правильный адрес приложения в Интернете.';
			|en = 'Exchange plan ""%1"" is not found in the peer application.
			|Ensure that the following data is correct:
			|- The application type selected in the exchange settings.
			|- The web application address.'; fa = 'Exchange plan ""%1"" is not found in the peer application.
			|Ensure that the following data is correct:
			|- The application type selected in the exchange settings.
			|- The web application address.';
			|it = 'Il piano di scambio %1"""" non è stato trovato nel corrispondente.
			| Assicurarsi che
			| - è stato selezionato il tipo corretto di applicazione per impostare lo scambio;
			| - è indicato l''indirizzo corretto dell''applicazione in Internet.';
			|pl = 'W korespondencie nie znaleziono planu wymiany ""%1"".
			|Przekonaj się, że
			| - wybrano właściwy rodzaj aplikacji dla ustawienia wymiany;
			| - podano poprawny adres aplikacji w Internecie.';
			|tr = 'Muhabirde ""%1"" alışveriş planı bulunamadı. 
			| - 
			|Veri alışverişini yapılandırmak için uygulamanın türü doğru seçildiğinden; 
			|- bağlantının yapıldığı programın İnternet''teki konumunun doğru belirtildiğinden emin olun.'");
		
		ErrorMessage = StrTemplate(Text, ExchangePlanName);
		
		Result.ConnectionIsSet = False;
		Result.ErrorMessage = ErrorMessage;
		
		Return Result;
		
	EndIf;
	
	Result.CorrespondentParametersReceived = True;
	Result.CorrespondentParameters = CorrespondentParameters;
	Result.CorrespondentExchangePlanName = CorrespondentParameters.ExchangePlanName;
	Result.ConnectionIsSet = True;
	
	Cancel = False;
	ErrorMessage = "";
	
	ExchangeMessagesTransport.OnConnectToCorrespondent(Cancel, ExchangePlanName, InterfaceVersion, ErrorMessage);
		
	If Cancel Then
		
		Result.ConnectionAllowed = False;
		Result.ErrorMessage = ErrorMessage;
		
		Return Result;
		
	EndIf;
	
	ExchangeMessagesTransport.CheckForDuplicateSyncs(ExchangePlanName, CorrespondentParameters, Result);
	
	Result.ConnectionAllowed = True;
	
	Return Result;
	
EndFunction

Function InternalPublication_SaveSettingsInCorrespondent(ConnectionSettings)

	Proxy = InternalPublication_Proxy();
	
	If Proxy = Undefined Then
		
		Return False;
		
	EndIf;
		
	CorrespondentConnectionSettings = New Structure;
	For Each SettingItem In ConnectionSettings Do
		CorrespondentConnectionSettings.Insert(SettingItem.Key);
	EndDo;
	
	CorrespondentConnectionSettings.WizardRunOption   = "ContinueDataExchangeSetup";
	CorrespondentConnectionSettings.ExchangeSetupOption = ConnectionSettings.ExchangeSetupOption;
	
	CorrespondentConnectionSettings.ExchangePlanName               = ConnectionSettings.CorrespondentExchangePlanName;
	CorrespondentConnectionSettings.CorrespondentExchangePlanName = ConnectionSettings.ExchangePlanName;
	CorrespondentConnectionSettings.ExchangeFormat                 = ConnectionSettings.ExchangeFormat;
	
	CorrespondentConnectionSettings.UsePrefixesForExchangeSettings =
		ConnectionSettings.UsePrefixesForCorrespondentExchangeSettings;
	
	CorrespondentConnectionSettings.UsePrefixesForCorrespondentExchangeSettings =
		ConnectionSettings.UsePrefixesForExchangeSettings;
	
	CorrespondentConnectionSettings.SourceInfobasePrefix = ConnectionSettings.DestinationInfobasePrefix;
	CorrespondentConnectionSettings.DestinationInfobasePrefix = ConnectionSettings.SourceInfobasePrefix;
	
	If DataExchangeCached.IsXDTOExchangePlan(ConnectionSettings.ExchangePlanName) Then
		CorrespondentConnectionSettings.ExchangeFormatVersion = ConnectionSettings.ExchangeFormatVersion;
		
		TableObjects = DataExchangeXDTOServer.SupportedObjectsInFormat(
			ConnectionSettings.ExchangePlanName, "SendReceive", ConnectionSettings.InfobaseNode);
		
		CorrespondentConnectionSettings.SupportedObjectsInFormat = New ValueStorage(TableObjects, New Deflation(9));
	EndIf;
		
	CorrespondentConnectionSettings.WSCorrespondentEndpoint = Common.ObjectAttributeValue(Endpoint, "Code");
	CorrespondentConnectionSettings.WSPeerDataArea = SessionParameters.DataAreaValue;
	ConnectionSettings.WSCorrespondentEndpoint = Common.ObjectAttributeValue(Endpoint, "Code");
	ConnectionSettings.WSPeerDataArea = SessionParameters.DataAreaValue;
			
	XMLConnectionSettingsString = DataProcessors.ExchangeMessageTransportSM.ConnectionSettingsInXML(ConnectionSettings);
	
	ConnectionParameters = New Structure;
	ConnectionParameters.Insert("ConnectionSettings", CorrespondentConnectionSettings);
	ConnectionParameters.Insert("XMLParametersString",  XMLConnectionSettingsString);
	
	Try
		DataExchangeWebService.CreateExchangeNode(Proxy, ConnectionParameters, CorrespondentDataArea);
	Except
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo());
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject);
		
		Return False;
		
	EndTry;
			
	Return True;
	
EndFunction

Function InternalPublication_SendMessage(MessageForDataMapping)

	Proxy = InternalPublication_Proxy();
	
	If Proxy = Undefined Then
		
		Return False;
		
	EndIf;
	
	ExchangeSettingsStructure = DataExchangeServer.ExchangeSettingsForInfobaseNode(
		Peer, Enums.ActionsOnExchange.DataExport, "SM");
		
	Cancel = False;
	SetupStatus = DataExchangeWebService.SetupStatus(
		Proxy, ExchangeSettingsStructure, CorrespondentDataArea, Cancel, ErrorMessage);
	
	If Cancel Then
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataExport");
		Return False;
	EndIf;
	
	UIDFileID = DataExchangeWebService.PutFileInStorageInService(
		Proxy, ExchangeMessage, 1024,, CorrespondentDataArea);
	
	FileIDAsString = String(UIDFileID);
	
	If MessageForDataMapping
		And (SetupStatus.DataMappingSupported
		Or Not SetupStatus.DataSynchronizationSetupCompleted) Then
		
		DataExchangeWebService.PutMessageForDataMapping(
			Proxy, ExchangeSettingsStructure, FileIDAsString, CorrespondentDataArea);
		
	EndIf;
	
	Return True;
	
EndFunction

Function InternalPublication_ReceiveMessage()
	
	Proxy = InternalPublication_Proxy();
	If Proxy = Undefined Then
		
		Return False;
		
	EndIf;
	
	ExchangeSettingsStructure = DataExchangeServer.ExchangeSettingsForInfobaseNode(
		Peer, Enums.ActionsAtCancelInternalPublication.DataImport, "SM");
		
	Cancel = False;
	SetupStatus = DataExchangeWebService.SetupStatus(
		Proxy, ExchangeSettingsStructure, CorrespondentDataArea, Cancel, ErrorMessage);
	
	If Cancel Then
		
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataImport");
		Return False;
		
	EndIf;
	
	ExchangeParameters = DataExchangeServer.ExchangeParameters();
	DataExchangeWebService.RunDataExport(Proxy, ExchangeSettingsStructure, ExchangeParameters, CorrespondentDataArea);
	
	If ExchangeParameters.TimeConsumingOperation Then
		
		DataExchangeWebService.WaitingForTheOperationToComplete(
			ExchangeSettingsStructure, ExchangeParameters, Proxy, Enums.ActionsOnExchange.DataImport);
		
	EndIf;
	
	UIDOfTheMessageFile = New UUID(ExchangeParameters.FileID);
	ExchangeMessage = DataExchangeWebService.GetFileFromStorageInService(
		Proxy, UIDOfTheMessageFile, Peer, 1024, CorrespondentDataArea);
	
	Return True;
	
EndFunction

Function InternalPublication_DeleteSynchronizationSettingInCorrespondent()

	Proxy = InternalPublication_Proxy();
	
	If Proxy = Undefined Then
		Return False;
	EndIf;
	
	ExchangeSettingsStructure = DataExchangeServer.ExchangeSettingsForInfobaseNode(Peer, "NodeDeletion");

	ExchangeSettingsStructure.EventLogMessageKey = DataExchangeServer.DataExchangeDeletionEventLogEvent();
	ExchangeSettingsStructure.ActionOnExchange = Undefined;
	
	Try
		DataExchangeWebService.DeleteExchangeNode(Proxy, ExchangeSettingsStructure, CorrespondentDataArea);
	Except
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo());
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject);
		
		Return False;
		
	EndTry;
	
	Return True;

EndFunction

Function ServiceManager_CorrespondentParameters()
	
	Result = ExchangeMessagesTransport.StructureOfResultOfObtainingParametersOfCorrespondent();
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataSynchronizationBetweenWebApplicationsSetupWizard();
	
	If ModuleSetupWizard = Undefined Then
		ContinueWait = False;
		Return Result;
	EndIf;
	
	ConnectionSettings = New Structure;
	ConnectionSettings.Insert("ExchangePlanName",              ExchangePlanName);
	ConnectionSettings.Insert("PeerInfobaseName",  PeerInfobaseName);
	ConnectionSettings.Insert("CorrespondentDataArea", CorrespondentDataArea);
	
	ContinueWait = True;
	
	HandlerParameters = Undefined;
	ModuleSetupWizard.OnStartGetCommonDataFromCorrespondentNodes(
		ConnectionSettings, HandlerParameters, ContinueWait);
		
	// Waiting
	IdleHandlerParameters = Undefined; 
	InitIdleHandlerParameters(IdleHandlerParameters);
	
	While ContinueWait Do
		
		DataExchangeServer.Pause(IdleHandlerParameters.CurrentInterval);
		UpdateIdleHandlerParameters(IdleHandlerParameters);
		
		ModuleSetupWizard.OnWaitForGetCommonDataFromCorrespondentNodes(HandlerParameters, ContinueWait);	
	
	EndDo;
	
	CompletionStatus = Undefined;
	ModuleSetupWizard.OnCompleteGetCommonDataFromCorrespondentNodes(
		HandlerParameters, CompletionStatus);
		
	HandlerParameters = Undefined;
		
	If CompletionStatus.Cancel Then
		
		ErrorMessage = CompletionStatus.Result.ErrorMessage;
			
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject);
			
		Result.ConnectionIsSet = False;
		Result.ErrorMessage = ErrorMessage;
		
	Else
		
		ConnectionCheckCompleted = CompletionStatus.Result.CorrespondentParametersReceived;
				
		If ConnectionCheckCompleted Then
			Result.ConnectionIsSet = True;
			Result.CorrespondentParameters = CompletionStatus.Result.CorrespondentParameters;
		EndIf;
				
	EndIf;
	
	Result.ConnectionAllowed = True;
	
	Return Result;
	
EndFunction

Function ServiceManager_SaveSettingsInCorrespondent(ConnectionSettings)
	
	SetPrivilegedMode(True);
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataSynchronizationBetweenWebApplicationsSetupWizard();
	
	XDTOSetup = DataExchangeCached.IsXDTOExchangePlan(ExchangePlanName);
	
	MSConnectionSettings = ModuleSetupWizard.ConnectionSettingsDetails(XDTOSetup);
		
	MSConnectionSettings.ExchangePlanName = ConnectionSettings.CorrespondentExchangePlanName;
	MSConnectionSettings.CorrespondentExchangePlanName = ConnectionSettings.ExchangePlanName;
	MSConnectionSettings.SettingID = ConnectionSettings.SettingID;
	MSConnectionSettings.ExchangeFormat = ConnectionSettings.ExchangeFormat;
	MSConnectionSettings.Description = ConnectionSettings.ThisInfobaseDescription;
	MSConnectionSettings.PeerInfobaseName = ConnectionSettings.SecondInfobaseDescription;
	MSConnectionSettings.Prefix = ConnectionSettings.SourceInfobasePrefix;
	MSConnectionSettings.CorrespondentPrefix = ConnectionSettings.DestinationInfobasePrefix;
	MSConnectionSettings.SourceInfobaseID = ConnectionSettings.SourceInfobaseID;
	MSConnectionSettings.DestinationInfobaseID = ConnectionSettings.DestinationInfobaseID;
	MSConnectionSettings.CorrespondentEndpoint = CorrespondentEndpoint;
	MSConnectionSettings.CorrespondentDataArea = CorrespondentDataArea;
	
	If XDTOSetup Then
		XDTOCorrespondentSettings = MSConnectionSettings.XDTOCorrespondentSettings;
		XDTOCorrespondentSettings.SupportedVersions.Add(ConnectionSettings.ExchangeFormatVersion);
		XDTOCorrespondentSettings.SupportedObjects = ConnectionSettings.SupportedPeerInfobaseFormatObjects;
	EndIf;
	
	// Shared node data.
	
	InformationRegisters.CommonInfobasesNodesSettings.UpdatePrefixes(
		Peer,
		MSConnectionSettings.Prefix,
		MSConnectionSettings.CorrespondentPrefix);
		
	ActualCorrespondentCode = Common.ObjectAttributeValue(Peer, "Code");
		
	ThisNodeCode = MSConnectionSettings.SourceInfobaseID;
	
	// Operations with transport settings.
	Parameters = New Structure;
	Parameters.Insert("Peer", Peer);
	Parameters.Insert("ThisNodeCode", ThisNodeCode);
	Parameters.Insert("CorrespondentCode", MSConnectionSettings.DestinationInfobaseID);
	Parameters.Insert("CorrespondentEndpoint", CorrespondentEndpoint);
	Parameters.Insert("IsCorrespondent", False);
	Parameters.Insert("SSL200CompatibilityMode", False);
	Parameters.Insert("ThisNodeAlias", "");
	
	ModuleDataExchangeSaaS = Common.CommonModule("DataExchangeSaaS");
	ModuleDataExchangeSaaS.UpdateDataAreaTransportSettings(Parameters);
				
	MessageExchangePlanName = "MessagesExchange";
	ModuleMessagesSaaS = Common.CommonModule("MessagesSaaS");
	MessageExchangePlanManager = Common.ObjectManagerByFullName("ExchangePlan."
		+ MessageExchangePlanName);
		
	SessionHandlerParameters = TimeConsumingOperationHandlerParameters();
	
	ModuleDataExchangeSaaS = Common.CommonModule("DataExchangeSaaS");
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	Try
		
		ModuleDataExchangeMessagesManagementInterface = Common.CommonModule("DataExchangeMessagesManagementInterface");
		
		// Send a message to a peer infobase.
		Message = ModuleMessagesSaaS.NewMessage(
			ModuleDataExchangeMessagesManagementInterface.SetUpExchangeStep1Message());
			
		Message.Body.CorrespondentZone = MSConnectionSettings.CorrespondentDataArea;
		
		Message.Body.ExchangePlan      = MSConnectionSettings.ExchangePlanName;
		Message.Body.CorrespondentCode = MSConnectionSettings.SourceInfobaseID;
		Message.Body.CorrespondentName = MSConnectionSettings.Description;
		
		Message.Body.Code     = MSConnectionSettings.DestinationInfobaseID;
		Message.Body.EndPoint = Common.ObjectAttributeValue(MessageExchangePlanManager.ThisNode(), "Code");
		
		If DataExchangeCached.IsXDTOExchangePlan(MSConnectionSettings.ExchangePlanName) Then
			FormatVersions = Common.UnloadColumn(
				DataExchangeServer.ExchangePlanSettingValue(ExchangePlanName, "ExchangeFormatVersions"), "Key", True);
				
			FormatObjects = DataExchangeXDTOServer.SupportedObjectsInFormat(
				ExchangePlanName, "SendReceive", Peer);
			
			XDTOCorrespondentSettings = New Structure;
			XDTOCorrespondentSettings.Insert("SupportedVersions", FormatVersions);
			XDTOCorrespondentSettings.Insert("SupportedObjects",
				New ValueStorage(FormatObjects, New Deflation(9)));
				
			Message.Body.XDTOSettings = XDTOSerializer.WriteXDTO(XDTOCorrespondentSettings);
		EndIf;
		
		AdditionalProperties = New Structure;
		AdditionalProperties.Insert("Interface", "3.0.1.1");
		AdditionalProperties.Insert("Prefix", MSConnectionSettings.CorrespondentPrefix);
		AdditionalProperties.Insert("CorrespondentPrefix", MSConnectionSettings.Prefix);
		AdditionalProperties.Insert("SettingID", MSConnectionSettings.SettingID);
		
		Message.AdditionalInfo = XDTOSerializer.WriteXDTO(AdditionalProperties);
		
		SessionHandlerParameters.OperationID = ModuleDataExchangeSaaS.SendMessage(Message);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		
		Information = ErrorInfo();
		
		SessionHandlerParameters.Cancel = True;
		SessionHandlerParameters.ErrorMessage = ErrorProcessing.BriefErrorDescription(Information);
		
		ErrorMessage = ErrorProcessing.DetailErrorDescription(Information);
		
		WriteLogEvent(ModuleDataExchangeSaaS.EventLogEventDataSynchronizationSetup(),
			EventLogLevel.Error, , , ErrorMessage);
			
		Return False;
			
	EndTry;
		
	If Not SessionHandlerParameters.Cancel Then
		ModuleMessagesSaaS.DeliverQuickMessages();
		
		SessionHandlerParameters.TimeConsumingOperation = True;
		SessionHandlerParameters.AdditionalParameters.Insert(
			"Peer", Peer);
	EndIf;
	
	HandlerParameters = TimeConsumingOperationHandlerParameters();
	HandlerParameters.AdditionalParameters.Insert("Peer", Peer);
	HandlerParameters.AdditionalParameters.Insert("WaitForMessageExchangeSessionInSystem1");
	HandlerParameters.AdditionalParameters.Insert("SessionHandlerParameters", SessionHandlerParameters);
	HandlerParameters.AdditionalParameters.Insert("ConnectionSettings", MSConnectionSettings);
	
	ContinueWait = True;
	
	IdleHandlerParameters = Undefined; 
	InitIdleHandlerParameters(IdleHandlerParameters);
	
	While ContinueWait Do
		
		DataExchangeServer.Pause(IdleHandlerParameters.CurrentInterval);
		UpdateIdleHandlerParameters(IdleHandlerParameters);
		
		ModuleSetupWizard.OnWaitForSaveConnectionSettings(
			HandlerParameters, ContinueWait);
	
	EndDo;
		
	Return True;
	
EndFunction

Function ServiceManager_SendMessage(MessageForDataMapping)

	DataAreaExchangeTransportConfigurationModule = Common.CommonModule("InformationRegisters.DataAreaExchangeTransportSettings");
	DataAreaTransportSettings = DataAreaExchangeTransportConfigurationModule.TransportSettings(Peer);
		
	If DataAreaTransportSettings.DefaultExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.FILE Then
		
		Transport = DataProcessors.ExchangeMessageTransportFILE.Create();
		Transport.DataExchangeDirectory = DataAreaTransportSettings.FILEDataExchangeDirectory;
		Transport.CompressOutgoingMessageFile = DataAreaTransportSettings.FILECompressOutgoingMessageFile;
		Transport.ArchivePasswordExchangeMessages = DataAreaTransportSettings.ArchivePasswordExchangeMessages;
		
	ElsIf DataAreaTransportSettings.DefaultExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.FTP Then 
		
		Transport = DataProcessors.ExchangeMessageTransportFTP.Create();
		Transport.CompressOutgoingMessageFile = DataAreaTransportSettings.FTPCompressOutgoingMessageFile;
		Transport.MaxMessageSize = DataAreaTransportSettings.FTPConnectionMaxMessageSize;
		Transport.PassiveConnection = DataAreaTransportSettings.FTPConnectionPassiveConnection;
		Transport.User = DataAreaTransportSettings.FTPConnectionUser;
		Transport.Port = DataAreaTransportSettings.FTPConnectionPort;
		Transport.Path = DataAreaTransportSettings.FTPConnectionPath;
		Transport.ArchivePasswordExchangeMessages = DataAreaTransportSettings.ArchivePasswordExchangeMessages;
		Transport.Password = DataAreaTransportSettings.FTPConnectionPassword;
		
	EndIf;
	
	Transport.Peer = Peer;
	Transport.NameOfMessageToSend = NameOfMessageToSend;
	Transport.TempDirectory = TempDirectory;
	Transport.ExchangeMessage = ExchangeMessage;
	
	SendingResult = Transport.SendData(MessageForDataMapping);
	
	If Not SendingResult Then	
		Return False;
	EndIf;
	
	If MessageForDataMapping Then
		
		ExportSettings1 = New Structure;
		ExportSettings1.Insert("Peer", Peer);
		ExportSettings1.Insert("CorrespondentDataArea", CorrespondentDataArea);
		
		HandlerParameters = Undefined;
		ContinueWait = True;
		
		IdleHandlerParameters = Undefined; 
		InitIdleHandlerParameters(IdleHandlerParameters);
				
		ModuleInteractiveExchangeWizard = DataExchangeServer.ModuleInteractiveDataExchangeWizardSaaS();
		
		ModuleInteractiveExchangeWizard.OnStartPuttingDataToMap(
			ExportSettings1, HandlerParameters, ContinueWait);	
		
		While ContinueWait Do
			
			DataExchangeServer.Pause(IdleHandlerParameters.CurrentInterval);
			UpdateIdleHandlerParameters(IdleHandlerParameters);
			
			ModuleInteractiveExchangeWizard.OnWaitSystemMessagesExchangeSession(
				HandlerParameters, ContinueWait);				
		
		EndDo;
		
	EndIf;
	
	Return True;
	
EndFunction

Function ServiceManager_GetMessage()
	
	DataAreaExchangeTransportConfigurationModule = Common.CommonModule("InformationRegisters.DataAreaExchangeTransportSettings");
	DataAreaTransportSettings = DataAreaExchangeTransportConfigurationModule.TransportSettings(Peer);
	
	If DataAreaTransportSettings.DefaultExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.FILE Then
		
		Transport = DataProcessors.ExchangeMessageTransportFILE.Create();
		Transport.DataExchangeDirectory = DataAreaTransportSettings.FILEDataExchangeDirectory;
		Transport.CompressOutgoingMessageFile = DataAreaTransportSettings.FILECompressOutgoingMessageFile;
		Transport.ArchivePasswordExchangeMessages = DataAreaTransportSettings.ArchivePasswordExchangeMessages;
		
	ElsIf DataAreaTransportSettings.DefaultExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.FTP Then 
		
		Transport = DataProcessors.ExchangeMessageTransportFTP.Create();
		Transport.CompressOutgoingMessageFile = DataAreaTransportSettings.FTPCompressOutgoingMessageFile;
		Transport.MaxMessageSize = DataAreaTransportSettings.FTPConnectionMaxMessageSize;
		Transport.PassiveConnection = DataAreaTransportSettings.FTPConnectionPassiveConnection;
		Transport.User = DataAreaTransportSettings.FTPConnectionUser;
		Transport.Port = DataAreaTransportSettings.FTPConnectionPort;
		Transport.Path = DataAreaTransportSettings.FTPConnectionPath;
		Transport.ArchivePasswordExchangeMessages = DataAreaTransportSettings.ArchivePasswordExchangeMessages;
		Transport.Password = DataAreaTransportSettings.FTPConnectionPassword;
		
	EndIf;
	
	Transport.Peer = Peer;
	Transport.ExchangeMessage = ExchangeMessage;
	Transport.TempDirectory = TempDirectory;
	Transport.NameTemplatesForReceivingMessage = NameTemplatesForReceivingMessage;
	
	Result = Transport.GetData();
	ExchangeMessage = Transport.ExchangeMessage;
	
	Return Result;
	
EndFunction

Procedure UpdateIdleHandlerParameters(IdleHandlerParameters) Export
	
	IdleHandlerParameters.CurrentInterval = Min(IdleHandlerParameters.MaxInterval,
		Round(IdleHandlerParameters.CurrentInterval * IdleHandlerParameters.IntervalIncreaseCoefficient, 1));
		
EndProcedure

Procedure InitIdleHandlerParameters(IdleHandlerParameters) Export
	
	IdleHandlerParameters = New Structure;
	IdleHandlerParameters.Insert("MinInterval", 1);
	IdleHandlerParameters.Insert("MaxInterval", 15);
	IdleHandlerParameters.Insert("CurrentInterval", 1);
	IdleHandlerParameters.Insert("IntervalIncreaseCoefficient", 1.4);
	
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

Function ConnectionIsSet() Export
	
	Return True;
	
EndFunction

Function InternalPublication_Proxy()
	
	ModuleMessagesExchangeTransportSettings = Common.CommonModule("InformationRegisters.MessageExchangeTransportSettings");
	TransportSettingsWS = ModuleMessagesExchangeTransportSettings.TransportSettingsWS(CorrespondentEndpoint);

	ConnectionParameters = New Structure;
	ConnectionParameters.Insert("WebServiceAddress", TransportSettingsWS.WSWebServiceURL);
	ConnectionParameters.Insert("UserName", TransportSettingsWS.WSUserName);
	ConnectionParameters.Insert("Password", TransportSettingsWS.WSPassword);
	
	Proxy = DataExchangeWebService.WSProxy(ConnectionParameters, ErrorMessage);
	
	If Proxy = Undefined Then
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject);
	EndIf;
		
	Return Proxy;
	
EndFunction	

#EndRegion

#Region Initialize

TempDirectory = Undefined;
ExchangeMessage = Undefined;

#EndRegion

#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf