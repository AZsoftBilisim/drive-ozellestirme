///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

Function TransportSettings(Val Peer) Export
	
	If Not Common.SubsystemExists("CloudTechnology") Then
		Raise NStr("vi = 'Chưa xác định bộ quản lý tùy chỉnh truyền thông điệp trao đổi.';
					|ru = 'Не определен менеджер настроек транспорта обмена сообщениями.';
					|en = 'The manager of exchange message transport settings is not defined.'; fa = 'The manager of exchange message transport settings is not defined.';
					|it = 'Manager delle impostazioni di trasporto di scambio messaggi non definito.';
					|pl = 'Nie określono menadżera ustawień transportu wymiany wiadomości.';
					|tr = 'Mesaj değişimi aracının ayarlar yöneticisi belirlenmedi.'");
	EndIf;
	
	MessagesExchangeTransportSettingsRegisterName = "MessageExchangeTransportSettings";
	
	QueryText =
		"SELECT
		|	"""" AS FILEDataExchangeDirectory,
		|	"""" AS FTPConnectionPath,
		|	DataAreaTransportSettings.DataExchangeDirectory AS RelativeInformationExchangeDirectory,
		|	DataAreasTransportSettings.FILEDataExchangeDirectory AS FILECommonInformationExchangeDirectory,
		|	DataAreasTransportSettings.FILECompressOutgoingMessageFile,
		|	DataAreasTransportSettings.FTPConnectionPath AS FTPCommonInformationExchangeDirectory,
		|	DataAreasTransportSettings.FTPCompressOutgoingMessageFile,
		|	DataAreasTransportSettings.FTPConnectionMaxMessageSize,
		|	DataAreasTransportSettings.FTPConnectionPassiveConnection,
		|	DataAreasTransportSettings.FTPConnectionUser,
		|	DataAreasTransportSettings.FTPConnectionPort,
		|	DataAreasTransportSettings.DefaultExchangeMessagesTransportKind,
		|	DataAreasTransportSettings.CorrespondentEndpoint,
		|	TransportSettings.WebServiceAddress AS WSWebServiceURL,
		|	TransportSettings.UserName AS WSUserName,
		|	"""" AS WSPeerDataArea,
		|	"""" AS WSCorrespondentEndpoint
		|FROM
		|	InformationRegister.DataAreaExchangeTransportSettings AS DataAreaTransportSettings
		|		LEFT JOIN InformationRegister.DataAreasExchangeTransportSettings AS DataAreasTransportSettings
		|		ON (DataAreasTransportSettings.CorrespondentEndpoint = DataAreaTransportSettings.CorrespondentEndpoint)
		|		LEFT JOIN #TransportSettingsTable AS TransportSettings
		|		ON (TransportSettings.Endpoint = DataAreaTransportSettings.CorrespondentEndpoint)
		|WHERE
		|	DataAreaTransportSettings.Peer = &Peer";
	
	QueryText = StrReplace(QueryText, "#TransportSettingsTable", "InformationRegister." + MessagesExchangeTransportSettingsRegisterName);
	
	Query = New Query(QueryText);
	Query.SetParameter("Peer", Peer);
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	
	If QueryResult.IsEmpty() Then
		Return Undefined;
	EndIf;
	
	Result = DataExchangeInternal.QueryResultToStructure(QueryResult);
	
	SetPrivilegedMode(True);
	Passwords = Common.ReadDataFromSecureStorage(Result.CorrespondentEndpoint,
		"FTPConnectionDataAreasPassword,WSPassword, ArchivePasswordDataAreaExchangeMessages", True);
	SetPrivilegedMode(False);
	
	Result.Insert("WSPassword", Passwords.WSPassword);
	Result.Insert("FTPConnectionPassword", Passwords.FTPConnectionDataAreasPassword);
	Result.Insert("ArchivePasswordExchangeMessages", Passwords.ArchivePasswordDataAreaExchangeMessages);
	
	Result.FILEDataExchangeDirectory = CommonClientServer.GetFullFileName(
		Result.FILECommonInformationExchangeDirectory,
		Result.RelativeInformationExchangeDirectory);
	
	Result.FTPConnectionPath = CommonClientServer.GetFullFileName(
		Result.FTPCommonInformationExchangeDirectory,
		Result.RelativeInformationExchangeDirectory);
	
	Result.Insert("UseTempDirectoryToSendAndReceiveMessages", True);
	
	If Result.DefaultExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.FTP Then
		FTPParameters = ExchangeMessagesTransport.FTPServerNameAndPath(Result.FTPConnectionPath);
		Result.Insert("FTPServer", FTPParameters.Server);
		Result.Insert("FTPPath",   FTPParameters.Path);
	Else
		Result.Insert("FTPServer", "");
		Result.Insert("FTPPath",   "");
	EndIf;
	
	DataExchangeInternal.AddTransactionItemsCountToTransportSettings(Result);
	
	Return Result;
EndFunction

Function TransportSettingsWS(Val Peer) Export
	
	If Not Common.SubsystemExists("CloudTechnology") Then
		Raise NStr("vi = 'Chưa xác định bộ quản lý tùy chỉnh truyền thông điệp trao đổi.';
					|ru = 'Не определен менеджер настроек транспорта обмена сообщениями.';
					|en = 'The manager of exchange message transport settings is not defined.'; fa = 'The manager of exchange message transport settings is not defined.';
					|it = 'Manager delle impostazioni di trasporto di scambio messaggi non definito.';
					|pl = 'Nie określono menadżera ustawień transportu wymiany wiadomości.';
					|tr = 'Mesaj değişimi aracının ayarlar yöneticisi belirlenmedi.'");
	EndIf;
	
	MessagesExchangeTransportSettingsRegisterName = "MessageExchangeTransportSettings";
	
	Query = New Query(
	"SELECT
	|	DataAreaTransportSettings.CorrespondentEndpoint AS CorrespondentEndpoint
	|FROM
	|	InformationRegister.DataAreaExchangeTransportSettings AS DataAreaTransportSettings
	|WHERE
	|	DataAreaTransportSettings.Peer = &Peer");
	Query.SetParameter("Peer", Peer);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	Endpoint = Selection.CorrespondentEndpoint;
	
	TransportSettingManager = Common.ObjectManagerByFullName("InformationRegister."
		+ MessagesExchangeTransportSettingsRegisterName);
	SettingsStructure = TransportSettingManager.TransportSettingsWS(Endpoint);
	
	If Not ValueIsFilled(SettingsStructure.WSWebServiceURL) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Chưa đặt tùy chỉnh kết nối Web-service đối với cơ sở trao đổi tin ""%1"".';
				|ru = 'Не заданы настройки подключения веб-сервиса для корреспондента ""%1"".';
				|en = 'Peer infobase ""%1"" connection is not set up.'; fa = 'Peer infobase ""%1"" connection is not set up.';
				|it = 'Impostazioni di connessione del servizio web per il corrispondente ""%1"" non sono impostate.';
				|pl = 'Nie zadano ustawień podłączeni serwisu internetowego dla korespondenta ""%1"".';
				|tr = '""%1"" muhabiri için web servisi bağlantı ayarları belirlenmedi.'"),
			String(Peer));
	EndIf;
	
	Return SettingsStructure;
	
EndFunction

// Updates a register record by the passed structure values
//
Procedure UpdateRecord(RecordStructure) Export
	
	DataExchangeInternal.UpdateInformationRegisterRecord(RecordStructure, "DataAreaExchangeTransportSettings");
	
EndProcedure

#EndRegion

#EndIf
