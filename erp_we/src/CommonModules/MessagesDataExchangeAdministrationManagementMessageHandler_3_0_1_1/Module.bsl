///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Namespace of message interface version.
//
// Returns:
//   String - a namespace.
//
Function Package() Export
	
	Return "http://www.1c.ru/SaaS/ExchangeAdministration/Manage/" + Version();
	
EndFunction

// Message interface version supported by the handler.
//
// Returns:
//   String - Version of message interface.
//
Function Version() Export
	
	Return "3.0.1.1";
	
EndFunction

// Base type for version messages.
//
// Returns:
//   XDTOObjectType - Basic type of message body.
//
Function BaseType() Export
	
	If Not Common.SubsystemExists("CloudTechnology") Then
		Raise NStr("vi = 'Không có bộ quản lý dịch vụ.';
					|ru = 'Отсутствует менеджер сервиса.';
					|en = 'There is no Service manager.'; fa = 'There is no Service manager.';
					|it = 'manager del servizio assente.';
					|pl = 'Brak menadżera serwisu.';
					|tr = 'Servis Yöneticisi eksik.'");
	EndIf;
	
	ModuleMessagesSaaS = Common.CommonModule("MessagesSaaS");
	
	Return ModuleMessagesSaaS.TypeBody();
	
EndFunction

// Processing incoming SaaS messages
//
// Parameters:
//   Message   - XDTODataObject - an incoming message.
//   Sender - ExchangePlanRef.MessagesExchange - exchange plan node that matches the message sender.
//   MessageProcessed - Boolean - indicates whether the message is successfully processed. The parameter value must be
//                         set to True if the message was successfully read in this handler.
//
Procedure ProcessSaaSMessage(Val Message, Val Sender, MessageProcessed) Export
	
	MessageProcessed = True;
	
	Dictionary = MessagesDataExchangeAdministrationManagementInterface;
	MessageType = Message.Body.Type();
	
	If MessageType = Dictionary.ConnectCorrespondentMessage(Package()) Then
		ConnectCorrespondent(Message, Sender);
	ElsIf MessageType = Dictionary.SetTransportSettingsMessage(Package()) Then
		SetTransportSettings(Message, Sender);
	ElsIf MessageType = Dictionary.DeleteSynchronizationSettingMessage(Package()) Then
		DeleteSynchronizationSetting(Message, Sender);
	ElsIf MessageType = Dictionary.ExecuteDataSynchronizationMessage(Package()) Then
		RunSync(Message, Sender);
	Else
		MessageProcessed = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure ConnectCorrespondent(Message, Sender)
	
	If Not Common.SubsystemExists("CloudTechnology") Then
		Return;
	EndIf;
	
	MessageExchangePlanName     = "MessagesExchange";
	ModuleMessagesExchange        = Common.CommonModule("MessagesExchange");
	ModuleMessagesSaaS = Common.CommonModule("MessagesSaaS");
	MessageExchangePlanManager = Common.ObjectManagerByFullName("ExchangePlan."
		+ MessageExchangePlanName);
	
	ThisMessageExchangeNode = MessageExchangePlanManager.ThisNode();
	
	Body = Message.Body;
	
	// Checking the endpoint.
	IsEndpoint = DataExchangeSaaS.EndpointsExchangePlanManager().FindByCode(Body.SenderId);
	
	If IsEndpoint.IsEmpty()
		Or IsEndpoint <> ThisMessageExchangeNode Then
		
		// Sending an error message to the service manager.
		ErrorPresentation = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Điểm cuối không như dự kiến. Mã điểm cuối dự kiến là %1. Mã điểm cuối hiện tại là %2.';
				|ru = 'Конечная точка не соответствует ожидаемой. Код ожидаемой конечной точки %1. Код текущей конечной точки %2.';
				|en = 'Endpoint does not match the expected one. Expected endpoint code %1. Current endpoint code %2. '; fa = 'Endpoint does not match the expected one. Expected endpoint code %1. Current endpoint code %2. ';
				|it = 'L''endpoint non corrisponde a quello previsto. Codice dell''endpoint previsto %1. Codice dell''endpoint corrente %2.';
				|pl = 'Punkt końcowy nie pokrywa się z oczekiwanym. Kod oczekiwanego punktu końcowego %1. Kod bieżącego punktu końcowego %2.';
				|tr = 'Uç nokta beklenen ile eşleşmiyor. Beklenen uç nokta kodu %1. Geçerli uç nokta kodu %2.'"),
			Body.SenderId,
			Common.ObjectAttributeValue(ThisMessageExchangeNode, "Code"));
			
		SendAResponseMessageAboutAConnectionError(Message, Sender, ErrorPresentation);	
		Return;
		
	EndIf;
	
	// Checking whether correspondent is connected.
	Peer = DataExchangeSaaS.EndpointsExchangePlanManager().FindByCode(Body.RecipientId);
	
	If Peer.IsEmpty() Then // Connecting a correspondent endpoint.
		
		Cancel = False;
		ConnectedCorrespondent = Undefined;
		
		SenderConnectionSettings = DataExchangeServer.WSParameterStructure();
		SenderConnectionSettings.WSWebServiceURL = Body.RecipientURL;
		SenderConnectionSettings.WSUserName = Body.RecipientUser;
		SenderConnectionSettings.WSPassword = Body.RecipientPassword;
		
		RecipientConnectionSettings = DataExchangeServer.WSParameterStructure();
		RecipientConnectionSettings.WSWebServiceURL = Body.SenderURL;
		RecipientConnectionSettings.WSUserName = Body.SenderUser;
		RecipientConnectionSettings.WSPassword = Body.SenderPassword;
		
		ModuleMessagesExchange.ConnectEndpoint(
									Cancel,
									SenderConnectionSettings,
									RecipientConnectionSettings,
									ConnectedCorrespondent,
									Body.RecipientName,
									Body.SenderName);
		
		If Cancel Then // Sending an error message to the service manager.
			
			ErrorPresentation = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Lỗi kết nối điểm cuối của cơ sở trao đổi dữ liệu. Mã điểm cuối của cơ sở trao đổi dữ liệu %1.';
					|ru = 'Ошибка подключения конечной точки корреспондента обмена. Код конечной точки корреспондента обмена %1.';
					|en = 'Peer infobase endpoint connection error. Endpoint ID: %1.'; fa = 'Peer infobase endpoint connection error. Endpoint ID: %1.';
					|it = 'Errore durante la connessione dell''endpoint del corrispondente di scambio. Codice dell''endpoint del corrispondente di scambio %1.';
					|pl = 'Błąd połączenia punktu końcowego korespondenta wymiany. Kod punktu końcowego korespondenta wymiany %1.';
					|tr = 'Değişim muhabirinin uç noktasını bağlarken bir hata oluştu. Değişim muhabirinin uç noktasının kodu %1.'"),
				Body.RecipientId);
				
			SendAResponseMessageAboutAConnectionError(Message, Sender, ErrorPresentation);	
			Return;
			
		EndIf;
		
		ConnectedCorrespondentCode = Common.ObjectAttributeValue(ConnectedCorrespondent, "Code");
		
		If ConnectedCorrespondentCode <> Body.RecipientId Then
			
			// A wrong exchange peer is connected.
			// Send an error message to the Service Manager.
			ErrorPresentation = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Lỗi khi kết nối điểm cuối cơ sở trao đổi dữ liệu.
				|Tùy chỉnh kết nối Web-service không như dự kiến.
				|Mã điểm cuối của cơ sở trao đổi dữ liệu dự kiến là %1.
				|Mã điểm cuối của cơ sở trao đổi dữ liệu đã kết nối là %2.';
				|ru = 'Ошибка при подключении конечной точки корреспондента обмена.
				|Настройки подключения веб-сервиса не соответствуют ожидаемым.
				|Код ожидаемой конечной точки корреспондента обмена %1.
				|Код подключенной конечной точки корреспондента обмена %2.';
				|en = 'Peer infobase endpoint connection error.
				|Unexpected endpoint ID.
				|Expected ID: %1.
				|Actual ID: %2.'; fa = 'Peer infobase endpoint connection error.
				|Unexpected endpoint ID.
				|Expected ID: %1.
				|Actual ID: %2.';
				|it = 'Errore durante la connessione dell''endpoint del corrispondente di scambio.
				|Le impostazioni di connessione del servizio web non corrispondono a quelle previste.
				|Codice dell''endpoint del corrispondente di scambio previsto%1.
				|Codice dell''endpoint del corrispondente di scambio connesso %2.';
				|pl = 'Błąd połączenia punktu końcowego korespondenta wymiany.
				|Ustawienia połączenia z usługą sieciową nie są zgodne z oczekiwaniami.
				|Kod oczekiwanego punktu końcowego korespondenta wymiany%1.
				|Kod połączonego punktu końcowego korespondenta wymiany %2.';
				|tr = 'Değişim muhabirinin uç noktasını bağlarken bir hata oluştu.
				|Web servisinin bağlantı ayarları beklenenler ile eşleşmiyor.
				|Değişim muhabirinin beklenen uç nokta kodu %1.
				|Değişim muhabirinin bağlı uç nokta kodu %2.'"),
				Body.RecipientId,
				ConnectedCorrespondentCode);
			
			SendAResponseMessageAboutAConnectionError(Message, Sender, ErrorPresentation);	
			Return;
			
		EndIf;
		
		BeginTransaction();
		Try
		    Block = New DataLock;
		    LockItem = Block.Add(Common.TableNameByRef(ConnectedCorrespondent));
		    LockItem.SetValue("Ref", ConnectedCorrespondent);
		    Block.Lock();
		    
			LockDataForEdit(ConnectedCorrespondent);
			CorrespondentObject = ConnectedCorrespondent.GetObject(); // ExchangePlanObject.MessagesExchange
			
			CorrespondentObject.Locked = True;

		    CorrespondentObject.Write();

		    CommitTransaction();
		Except
		    RollbackTransaction();
		    Raise;
		EndTry;
		
	Else // Updating the correspondent and the endpoint connection settings.
		
		Cancel = False;
		
		SenderConnectionSettings = DataExchangeServer.WSParameterStructure();
		SenderConnectionSettings.WSWebServiceURL = Body.RecipientURL;
		SenderConnectionSettings.WSUserName = Body.RecipientUser;
		SenderConnectionSettings.WSPassword = Body.RecipientPassword;
		
		RecipientConnectionSettings = DataExchangeServer.WSParameterStructure();
		RecipientConnectionSettings.WSWebServiceURL = Body.SenderURL;
		RecipientConnectionSettings.WSUserName = Body.SenderUser;
		RecipientConnectionSettings.WSPassword = Body.SenderPassword;
		
		ModuleMessagesExchange.UpdateEndpointConnectionSettings(
									Cancel,
									Peer,
									SenderConnectionSettings,
									RecipientConnectionSettings);
		
		If Cancel Then // Sending an error message to the service manager.
			
			ErrorPresentation = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Lỗi cập nhật tham số kết nối điểm cuối này và điểm cuối của cơ sở trao đổi dữ liệu.
				|Mã của điểm cuối này %1
				|Mã điểm cuối của cơ sở trao đổi dữ liệu %2';
				|ru = 'Ошибка обновления параметров подключения этой конечной точки и конечной точки корреспондента обмена.
				|Код этой конечной токи %1
				|Код конечной точки корреспондента обмена %2';
				|en = 'Endpoint connection failed.
				|This infobase endpoint ID: %1.
				|The peer infobase endpoint ID: %2.'; fa = 'Endpoint connection failed.
				|This infobase endpoint ID: %1.
				|The peer infobase endpoint ID: %2.';
				|it = 'Errore durante l''aggiornamento dei parametri di connessione di questo endpoint e dell''endpoint del corrispondente di scambio.
				|Codice di questo endpoint%1
				|Codice dell''endpoint del corrispondente di scambio %2';
				|pl = 'Błąd aktualizacji ustawień połączenia tego punktu końcowego i punktu końcowego korespondenta wymiany.
				|Kod tego punktu końcowego %1
				|Kod punktu końcowego korespondenta wymiany %2';
				|tr = 'Bu uç noktanın ve değişim muhabirinin uç noktasının bağlantı ayarları güncellenirken bir hata oluştu.
				|Bu uç noktanın kodu %1
				|Değişim muhabirinin uç noktasının kodu %2'"),
				Common.ObjectAttributeValue(ThisMessageExchangeNode, "Code"),
				Body.RecipientId);
				
			SendAResponseMessageAboutAConnectionError(Message, Sender, ErrorPresentation);	
			Return;
			
		EndIf;
		
		CorrespondentObject = Peer.GetObject();
		CorrespondentObject.Locked = True;
		CorrespondentObject.Write();
		
	EndIf;
	
	// Sending a message to the service manager about successful operation completion.
	BeginTransaction();
	Try
		ResponseMessage = ModuleMessagesSaaS.NewMessage(
			MessagesDataExchangeAdministrationControlInterface.CorrespondentConnectionCompletedMessage());
		ResponseMessage.Body.RecipientId = Body.RecipientId;
		ResponseMessage.Body.SenderId    = Body.SenderId;
		ModuleMessagesSaaS.SendMessage(ResponseMessage, Sender);
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

Procedure SetTransportSettings(Message, Sender)
	
	Body = Message.Body;
	
	Peer = DataExchangeSaaS.EndpointsExchangePlanManager().FindByCode(Body.RecipientId);
	
	If Peer.IsEmpty() Then
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không tìm thấy điểm cuối của cơ sở trao đổi dữ liệu với mã ""%1"".';
				|ru = 'Не найдена конечная точка корреспондента с кодом ""%1"".';
				|en = 'Endpoint with ID %1 is not found.'; fa = 'Endpoint with ID %1 is not found.';
				|it = 'L''endpoint del corrispondente con il codice ""%1"" non è stato trovato.';
				|pl = 'Nie znaleziono punktu końcowego korespondenta z kodem ""%1"".';
				|tr = '""%1"" kodlu muhabir uç noktası bulunamadı.'"),
			Body.RecipientId);
		Raise MessageString;
	EndIf;
	
	DataExchangeServer.SetDataImportTransactionItemsCount(Body.ImportTransactionQuantity);
	
	RecordStructure = New Structure;
	RecordStructure.Insert("CorrespondentEndpoint", Peer);
	
	RecordStructure.Insert("FILEDataExchangeDirectory",       Body.FILE_ExchangeFolder);
	RecordStructure.Insert("FILECompressOutgoingMessageFile", Body.FILE_CompressExchangeMessage);
	
	RecordStructure.Insert("FTPCompressOutgoingMessageFile",                  Body.FTP_CompressExchangeMessage);
	RecordStructure.Insert("FTPConnectionMaxMessageSize", Body.FTP_MaxExchangeMessageSize);
	RecordStructure.Insert("FTPConnectionPassiveConnection",                   Body.FTP_PassiveMode);
	RecordStructure.Insert("FTPConnectionUser",                          Body.FTP_User);
	RecordStructure.Insert("FTPConnectionPort",                                  Body.FTP_Port);
	RecordStructure.Insert("FTPConnectionPath",                                  Body.FTP_ExchangeFolder);
	
	RecordStructure.Insert("DefaultExchangeMessagesTransportKind",      Enums.ExchangeMessagesTransportTypes[Body.ExchangeTransport]);
	
	
	SetPrivilegedMode(True);
	Common.WriteDataToSecureStorage(Peer, Body.FTP_Password, "FTPConnectionDataAreasPassword");
	Common.WriteDataToSecureStorage(Peer, Body.ExchangeMessagePassword, "ArchivePasswordDataAreaExchangeMessages");
	SetPrivilegedMode(False);
	
	InformationRegisters.DataAreasExchangeTransportSettings.UpdateRecord(RecordStructure);
	
EndProcedure

Procedure DeleteSynchronizationSetting(Message, Sender)
	
	Body = Message.Body;
	DataExchangeSaaS.DeleteSynchronizationSetting(Body.ExchangePlan, Format(Body.CorrespondentZone, "ND=7; NLZ=; NG=0"));
	
EndProcedure

Procedure RunSync(Message, Sender)
	
	DataExchangeScenario = XDTOSerializer.ReadXDTO(Message.Body.Scenario);
	
	DataExchangeSaaS.ExecuteDataExchange(DataExchangeScenario);
	
EndProcedure

Function EventLogEventCorrespondentConnection()
	
	Return NStr("vi = 'Trao đổi dữ liệu.Kết nối cơ sở trao đổi dữ liệu';
				|ru = 'Обмен данными.Подключение корреспондента обмена';
				|en = 'Data exchange.Peer infobase connection'; fa = 'Data exchange.Peer infobase connection';
				|it = 'Scambio di dati. Connessione del corrispondente di scambio';
				|pl = 'Wymiana danych. Połączenie korespondenta wymiany';
				|tr = 'Veri değişimi.Değişim muhabiri bağlantısı'", Common.DefaultLanguageCode());
	
EndFunction

Procedure SendAResponseMessageAboutAConnectionError(Message, Sender, ErrorPresentation)
	
	AttemptNumber = Undefined;
	If Message.IsSet("AdditionalInfo") Then
		AdditionalProperties = XDTOSerializer.ReadXDTO(Message.AdditionalInfo);
		AdditionalProperties.Property("AttemptNumber", AttemptNumber);
	EndIf;
	
	WriteLogEvent(EventLogEventCorrespondentConnection(),
		EventLogLevel.Error,,, ErrorPresentation);
	
	ModuleMessagesSaaS = Common.CommonModule("MessagesSaaS");
	
	ResponseMessage = ModuleMessagesSaaS.NewMessage(
		MessagesDataExchangeAdministrationControlInterface.CorrespondentConnectionErrorMessage());
		
	AdditionalProperties = New Structure;
	AdditionalProperties.Insert("AttemptNumber", AttemptNumber);
	ResponseMessage.AdditionalInfo = XDTOSerializer.WriteXDTO(AdditionalProperties);
	ResponseMessage.Body.RecipientId      = Message.Body.RecipientId;
	ResponseMessage.Body.SenderId         = Message.Body.SenderId;
	ResponseMessage.Body.ErrorDescription = ErrorPresentation;
	
	BeginTransaction();
	Try
		ModuleMessagesSaaS.SendMessage(ResponseMessage, Sender);
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

#EndRegion
