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
	
	Return "http://www.1c.ru/SaaS/Exchange/Control";
	
EndFunction

// Message interface version supported by the handler.
//
// Returns:
//   String - a message interface version.
//
Function Version() Export
	
	Return "2.1.2.1";
	
EndFunction

// Base type for version messages.
//
// Returns:
//   XDTOObjectType - a base type of message body.
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
	
	Dictionary = DataExchangeMessagesControlInterface;
	MessageType = Message.Body.Type();
	
	If MessageType = Dictionary.ExchangeSetupStep1CompletedMessage(Package()) Then
		
		ExchangeSetupStep1Completed(Message, Sender);
		
	ElsIf MessageType = Dictionary.ExchangeSetupStep2CompletedMessage(Package()) Then
		
		ExchangeSetupStep2Completed(Message, Sender);
		
	ElsIf MessageType = Dictionary.ExchangeSetupErrorStep1Message(Package()) Then
		
		ExchangeSetupErrorStep1(Message, Sender);
		
	ElsIf MessageType = Dictionary.ExchangeSetupErrorStep2Message(Package()) Then
		
		ExchangeSetupErrorStep2(Message, Sender);
		
	ElsIf MessageType = Dictionary.ExchangeMessageImportCompletedMessage(Package()) Then
		
		ExchangeMessageImportCompleted(Message, Sender);
		
	ElsIf MessageType = Dictionary.ExchangeMessageImportErrorMessage(Package()) Then
		
		ExchangeMessageImportError(Message, Sender);
		
	ElsIf MessageType = Dictionary.CorrespondentDataGettingCompletedMessage(Package()) Then
		
		CorrespondentDataGettingCompleted(Message, Sender);
		
	ElsIf MessageType = Dictionary.GettingCommonDataOfCorrespondentNodeCompletedMessage(Package()) Then
		
		GettingCommonDataOfCorrespondentNodeCompleted(Message, Sender);
		
	ElsIf MessageType = Dictionary.CorrespondentDataGettingErrorMessage(Package()) Then
		
		CorrespondentDataGettingError(Message, Sender);
		
	ElsIf MessageType = Dictionary.CorrespondentNodeCommonDataGettingErrorMessage(Package()) Then
		
		CorrespondentNodeCommonDataGettingError(Message, Sender);
		
	ElsIf MessageType = Dictionary.GettingCorrespondentAccountingParametersCompletedMessage(Package()) Then
		
		GettingCorrespondentAccountingParametersCompleted(Message, Sender);
		
	ElsIf MessageType = Dictionary.CorrespondentAccountingParametersGettingErrorMessage(Package()) Then
		
		CorrespondentAccountingParametersGettingError(Message, Sender);
		
	Else
		
		MessageProcessed = False;
		Return;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Exchange setup.

Procedure ExchangeSetupStep1Completed(Message, Sender)
	
	DataExchangeSaaS.CommitSuccessfulSession(Message, SynchronizationSetupStep1Presentation());
	
EndProcedure

Procedure ExchangeSetupStep2Completed(Message, Sender)
	
	DataExchangeSaaS.CommitSuccessfulSession(Message, SynchronizationSetupStep2Presentation());
	
EndProcedure

Procedure ExchangeSetupErrorStep1(Message, Sender)
	
	DataExchangeSaaS.CommitUnsuccessfulSession(Message, SynchronizationSetupStep1Presentation());
	
EndProcedure

Procedure ExchangeSetupErrorStep2(Message, Sender)
	
	DataExchangeSaaS.CommitUnsuccessfulSession(Message, SynchronizationSetupStep2Presentation());
	
EndProcedure

Procedure ExchangeMessageImportCompleted(Message, Sender)
	
	DataExchangeSaaS.CommitSuccessfulSession(Message, ExchangeMessageImportPresentation());
	
EndProcedure

Procedure ExchangeMessageImportError(Message, Sender)
	
	DataExchangeSaaS.CommitSuccessfulSession(Message, ExchangeMessageImportPresentation());
	
EndProcedure

// Get peer infobase data.

Procedure CorrespondentDataGettingCompleted(Message, Sender)
	
	DataExchangeSaaS.SaveSessionData(Message, CorrespondentDataGettingPresentation());
	
EndProcedure

Procedure GettingCommonDataOfCorrespondentNodeCompleted(Message, Sender)
	
	DataExchangeSaaS.SaveSessionData(Message, GettingCommonDataOfCorrespondentNodePresentation());
	
EndProcedure

Procedure CorrespondentDataGettingError(Message, Sender)
	
	DataExchangeSaaS.CommitUnsuccessfulSession(Message, CorrespondentDataGettingPresentation());
	
EndProcedure

Procedure CorrespondentNodeCommonDataGettingError(Message, Sender)
	
	DataExchangeSaaS.CommitUnsuccessfulSession(Message, GettingCommonDataOfCorrespondentNodePresentation());
	
EndProcedure

// Retrieves correspondent accounting parameters.

Procedure GettingCorrespondentAccountingParametersCompleted(Message, Sender)
	
	DataExchangeSaaS.SaveSessionData(Message, GettingCorrespondentAccountingParametersPresentation());
	
EndProcedure

Procedure CorrespondentAccountingParametersGettingError(Message, Sender)
	
	DataExchangeSaaS.CommitUnsuccessfulSession(Message, GettingCorrespondentAccountingParametersPresentation());
	
EndProcedure

// Auxiliary functions.

Function SynchronizationSetupStep1Presentation()
	
	Return NStr("vi = 'Tùy chỉnh đồng bộ, bước 1.';
				|ru = 'Настройка синхронизации, шаг 1.';
				|en = 'Synchronization setup, step 1.'; fa = 'Synchronization setup, step 1.';
				|it = 'Impostazione della sincronizzazione, passo 1.';
				|pl = 'Synchronizacja konfiguracji, krok 1.';
				|tr = 'Senkronizasyon ayarı, adım 1.'");
	
EndFunction

Function SynchronizationSetupStep2Presentation()
	
	Return NStr("vi = 'Tùy chỉnh đồng bộ, bước 2.';
				|ru = 'Настройка синхронизации, шаг 2.';
				|en = 'Synchronization setup, step 2.'; fa = 'Synchronization setup, step 2.';
				|it = 'Impostazione della sincronizzazione, passo 2.';
				|pl = 'Synchronizacja konfiguracji, krok 2.';
				|tr = 'Senkronizasyon ayarı, adım 2.'");
	
EndFunction

Function ExchangeMessageImportPresentation()
	
	Return NStr("vi = 'Kết nhập thông điệp trao đổi.';
				|ru = 'Загрузка сообщения обмена.';
				|en = 'Importing an exchange message.'; fa = 'Importing an exchange message.';
				|it = 'Download del messaggio di scambio.';
				|pl = 'Pobieranie wiadomości wymiany.';
				|tr = 'Değişim mesajını yükle.'");
	
EndFunction

Function CorrespondentDataGettingPresentation()
	
	Return NStr("vi = 'Nhận dữ liệu của cơ sở trao đổi dữ liệu.';
				|ru = 'Получение данных корреспондента.';
				|en = 'Receiving data from the peer infobase.'; fa = 'Receiving data from the peer infobase.';
				|it = 'Acquisizione dei dati del corrispondente.';
				|pl = 'Pobieranie danych korespondenta.';
				|tr = 'Muhabir verilerini al.'");
	
EndFunction

Function GettingCommonDataOfCorrespondentNodePresentation()
	
	Return NStr("vi = 'Nhận dữ liệu chung của các nút thuộc cơ sở trao đổi dữ liệu.';
				|ru = 'Получение общих данных узлов корреспондента.';
				|en = 'Receiving common data from peer infobase nodes.'; fa = 'Receiving common data from peer infobase nodes.';
				|it = 'Acquisizione dei dati generali dei nodi del corrispondente.';
				|pl = 'Pobieranie ogólnych danych węzłów korespondenta.';
				|tr = 'Muhabir düğümlerinin paylaşılan verilerini al.'");
	
EndFunction

Function GettingCorrespondentAccountingParametersPresentation()
	
	Return NStr("vi = 'Nhận tham số kế toán của cơ sở trao đổi dữ liệu.';
				|ru = 'Получение параметров учета корреспондента.';
				|en = 'Receiving accounting settings from the peer infobase.'; fa = 'Receiving accounting settings from the peer infobase.';
				|it = 'Acquisizione dei parametri di registrazione del corrispondente.';
				|pl = 'Pobieranie parametrów ewidencji korespondenta.';
				|tr = 'Muhabir muhasebesinin parametrelerini al.'");
	
EndFunction

#EndRegion
