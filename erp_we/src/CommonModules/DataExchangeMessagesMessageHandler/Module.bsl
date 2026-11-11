///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Generates a list of handlers of messages that are processed by the current subsystem.
// 
// Parameters:
//  Handlers - ValueTable - See the field list in MessagesExchange.NewTableOfMessageHandlers.
// 
Procedure GetMessagesChannelsHandlers(Handlers) Export
	
	AddMessageChannelHandler("DataExchange\ApplicationSoftware\ExchangeCreation",                 DataExchangeMessagesMessageHandler, Handlers);
	AddMessageChannelHandler("DataExchange\ApplicationSoftware\DeleteExchange",                 DataExchangeMessagesMessageHandler, Handlers);
	AddMessageChannelHandler("DataExchange\ApplicationSoftware\SetDataAreaPrefix", DataExchangeMessagesMessageHandler, Handlers);
	
EndProcedure

// Processes a message body from the channel according to the algorithm of the current message channel.
//
// Parameters:
//  MessagesChannel - String - an ID of a message channel used to receive the message.
//  Body  - Arbitrary - a Body of the message received from the channel to be processed.
//  Sender    - ExchangePlanRef.MessagesExchange - an endpoint that is the sender of the message.
//
Procedure ProcessMessage(MessagesChannel, Body, Sender) Export
	
	Try
		
		SetDataArea(Body.DataArea);
		
		If MessagesChannel = "DataExchange\ApplicationSoftware\ExchangeCreation" Then
			
			CreateDataExchangeInInfobase(
									Sender,
									Body.Settings,
									Body.NodeFiltersSetting,
									Body.DefaultNodeValues,
									Body.ThisNodeCode,
									Body.NewNodeCode);
			
		ElsIf MessagesChannel = "DataExchange\ApplicationSoftware\DeleteExchange" Then
			
			DeleteDataExchangeFromInfobase(Sender, Body.ExchangePlanName, Body.NodeCode, Body.DataArea);
			
		ElsIf MessagesChannel = "DataExchange\ApplicationSoftware\SetDataAreaPrefix" Then
			
			SetDataAreaPrefix(Body.Prefix);
			
		EndIf;
		
	Except
		CancelDataAreaSetup();
		Raise;
	EndTry;
	
	CancelDataAreaSetup();
	
EndProcedure

#EndRegion

#Region Private

// Required for compatibility in the scenario where the SSL version in the correspondent infobase is earlier than 2.1.2.
//
Procedure CreateDataExchangeInInfobase(Sender, Settings, NodeFiltersSetting, DefaultNodeValues, ThisNodeCode, NewNodeCode)
	
	// Creating a message exchange directory (if necessary)
	Directory = New File(Settings.FILEDataExchangeDirectory);
	
	If Not Directory.Exists() Then
		
		Try
			CreateDirectory(Directory.FullName);
		Except
			
			// Sending an error message in the managing application
			SendMessageExchangeCreationError(Number(ThisNodeCode), Number(NewNodeCode),
				ErrorProcessing.DetailErrorDescription(ErrorInfo()), Sender);
			
			WriteLogEvent(DataExchangeServer.DataExchangeEventLogEvent(),
				EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			Return;
		EndTry;
	EndIf;
	
	BeginTransaction();
	Try
		
		CorrespondentDataArea = Number(NewNodeCode);
		ExchangePlanName              = Settings.ExchangePlanName;
		CorrespondentCode           = DataExchangeSaaS.ExchangePlanNodeCodeInService(CorrespondentDataArea);
		PeerInfobaseName  = Settings.SecondInfobaseDescription;
		NodeFiltersSetting      = New Structure;
		
		CorrespondentEndpoint = DataExchangeSaaS.EndpointsExchangePlanManager().FindByCode(
			Settings.CorrespondentEndpoint);
		
		If CorrespondentEndpoint.IsEmpty() Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không tìm thấy điểm cuối của cơ sở trao đổi dữ liệu với mã ""%1"".';
					|ru = 'Не найдена конечная точка корреспондента с кодом ""%1"".';
					|en = 'Endpoint with ID %1 not found in peer infobase.'; fa = 'Endpoint with ID %1 not found in peer infobase.';
					|it = 'L''endpoint del corrispondente con il codice ""%1"" non è stato trovato.';
					|pl = 'Nie znaleziono punktu końcowego korespondenta z kodem ""%1"".';
					|tr = '""%1"" kodlu muhabir uç noktası bulunamadı.'"),
				Settings.CorrespondentEndpoint);
		EndIf;
		
		// Creating exchange settings in the current infobase
		ConnectionSettings = New Structure;
		ConnectionSettings.Insert("ExchangePlanName",              ExchangePlanName);
		ConnectionSettings.Insert("CorrespondentCode",           CorrespondentCode);
		ConnectionSettings.Insert("PeerInfobaseName",  PeerInfobaseName);
		ConnectionSettings.Insert("CorrespondentEndpoint", CorrespondentEndpoint);
		ConnectionSettings.Insert("Settings",                   NodeFiltersSetting);
		ConnectionSettings.Insert("Prefix",                     "");
		ConnectionSettings.Insert("Peer"); // Output parameter.
		
		DataExchangeSaaS.CreateExchangeSetting(
			ConnectionSettings,
			,
			True);
			
		Peer = ConnectionSettings.Peer;
		
		// Saving exchange message transfer settings for the current data area
		RecordStructure = New Structure;
		RecordStructure.Insert("Peer", Peer);
		RecordStructure.Insert("CorrespondentEndpoint", CorrespondentEndpoint);
		RecordStructure.Insert("DataExchangeDirectory", Settings.FILERelativeInformationExchangeDirectory);
		
		InformationRegisters.DataAreaExchangeTransportSettings.UpdateRecord(RecordStructure);
		
		// Registering all infobase data for exporting
		DataExchangeServer.RegisterDataForInitialExport(Peer);
		
		// Sending an operation completion message in a managing application
		SendMessageOperationSuccessful(Number(ThisNodeCode), Number(NewNodeCode), Sender);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		
		// Sending an error message in the managing application
		SendMessageExchangeCreationError(Number(ThisNodeCode), Number(NewNodeCode),
			ErrorProcessing.DetailErrorDescription(ErrorInfo()), Sender);
		
		WriteLogEvent(DataExchangeServer.DataExchangeEventLogEvent(),
			EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Return;
	EndTry;
	
EndProcedure

// Required for compatibility in the scenario where the SSL version in the correspondent infobase is earlier than 2.1.2.
//
Procedure DeleteDataExchangeFromInfobase(Sender, ExchangePlanName, NodeCode, DataArea)
	
	// Sending an operation completion message in a managing application
	SendMessageOperationSuccessful(DataArea, Number(NodeCode), Sender);
	
EndProcedure

Procedure SetDataAreaPrefix(Val Prefix)
	
	If Common.SubsystemExists("CloudTechnology") Then
	
		SetPrivilegedMode(True);
		
		ManagerOfConstant = Constants["DataAreaPrefix"];
		
		If IsBlankString(ManagerOfConstant.Get()) Then
			
			ManagerOfConstant.Set(Format(Prefix, "ND=2; NLZ=; NG=0"));
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure SetDataArea(Val DataArea)
	
	If Not Common.SubsystemExists("CloudTechnology") Then
		Return;
	EndIf;
		
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	
	SetPrivilegedMode(True);
	
	ModuleSaaSOperations.SetSessionSeparation(True, DataArea);
	
EndProcedure

Procedure CancelDataAreaSetup()
	
	If Not Common.SubsystemExists("CloudTechnology") Then
		Return;
	EndIf;
		
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	
	SetPrivilegedMode(True);
	
	ModuleSaaSOperations.SetSessionSeparation(False);
	
EndProcedure

Procedure SendMessageOperationSuccessful(Code1, Code2, Endpoint)
	
	If Not Common.SubsystemExists("CloudTechnology") Then
		Return;
	EndIf;
		
	ModuleMessagesExchange = Common.CommonModule("MessagesExchange");
	
	BeginTransaction();
	Try
		
		Body = New Structure("Code1, Code2", Code1, Code2);
		
		ModuleMessagesExchange.SendMessage("DataExchange\ApplicationSoftware\Response\ActionSuccessful", Body, Endpoint);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		WriteLogEvent(EventLogEventMessagesSending(),
			EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise;
	EndTry;
	
EndProcedure

Procedure SendMessageExchangeCreationError(Code1, Code2, ErrorString, Endpoint)
	
	If Not Common.SubsystemExists("CloudTechnology") Then
		Return;
	EndIf;
		
	ModuleMessagesExchange = Common.CommonModule("MessagesExchange");
	
	BeginTransaction();
	Try
		
		Body = New Structure("Code1, Code2, ErrorString", Code1, Code2, ErrorString);
		
		ModuleMessagesExchange.SendMessage("DataExchange\ApplicationSoftware\Response\ExchangeCreationError", Body, Endpoint);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		WriteLogEvent(EventLogEventMessagesSending(),
			EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise;
	EndTry;
	
EndProcedure

Procedure AddMessageChannelHandler(Canal, ChannelHandler, Handlers)
	
	Handler = Handlers.Add();
	Handler.Canal = Canal;
	Handler.Handler = ChannelHandler;
	
EndProcedure

Function EventLogEventMessagesSending()
	
	Return NStr("vi = 'Gửi thông điệp';
				|ru = 'Отправка сообщений';
				|en = 'Send messages'; fa = 'Send messages';
				|it = 'Invio dei messaggi';
				|pl = 'Wysyłanie wiadomości';
				|tr = 'Mesajları gönder'", Common.DefaultLanguageCode());
	
EndFunction

#EndRegion
