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
	
	Return "http://www.1c.ru/SaaS/Exchange/Manage/3.0.1.1";
	
EndFunction

// Message interface version supported by the handler.
//
// Returns:
//   String - a message interface version.
//
Function Version() Export
	
	Return "3.0.1.1";
	
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
	
	Dictionary = DataExchangeMessagesManagementInterface;
	MessageType = Message.Body.Type();
	
	If MessageType = Dictionary.SetUpExchangeStep1Message(Package()) Then
		
		ConfigureExchangeStep1(Message, Sender);
		
	ElsIf MessageType = Dictionary.ImportExchangeMessageMessage(Package()) Then
		
		ImportExchangeMessage(Message, Sender);
		
	ElsIf MessageType = Dictionary.GetCorrespondentDataMessage(Package()) Then
		
		GetCorrespondentData(Message, Sender);
		
	ElsIf MessageType = Dictionary.GetCommonDataOfCorrespondentNodeMessage(Package()) Then
		
		GetCommonDataOfCorrespondentNodes1(Message, Sender);
		
	ElsIf MessageType = Dictionary.GetCorrespondentAccountingParametersMessage(Package()) Then
		
		GetCorrespondentAccountingParameters(Message, Sender);
		
	Else
		
		MessageProcessed = False;
		Return;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure ConfigureExchangeStep1(Message, Sender) Export
	
	If Not Common.SubsystemExists("CloudTechnology") Then
		Return;
	EndIf;
		
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	ModuleMessagesSaaS = Common.CommonModule("MessagesSaaS");
	
	Body = Message.Body;
	
	ThisNodeCode = Common.ObjectAttributeValue(ExchangePlans[Body.ExchangePlan].ThisNode(), "Code");
	ThisNodeAlias = "";
	
	If Not IsBlankString(ThisNodeCode) And ThisNodeCode <> Body.Code Then
		ThisNodeAlias = DataExchangeSaaS.ExchangePlanNodeCodeInService(ModuleSaaSOperations.SessionSeparatorValue());
	
		If ThisNodeAlias <> Body.Code Then
			MessageString = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Mã mong muốn của nút định trước trong ứng dụng này là ""%1""
				|không tương ứng với mã thực tế ""%2"" hoặc ẩn danh ""%3"". Sơ đồ trao đổi: %4.';
				|ru = 'Ожидаемый код предопределенного узла в этом приложении ""%1""
				|не соответствует фактическому ""%2"" или псевдониму ""%3"". План обмена: %4.';
				|en = 'Expected code of the predefined node in the %1
				| application does not match the actual one %2or alias %3. Exchange plan: %4.'; fa = 'Expected code of the predefined node in the %1
				| application does not match the actual one %2or alias %3. Exchange plan: %4.';
				|it = 'Il codice previsto del nodo predefinito in questa applicazione ""%1""
				| non corrisponde a quello effettivo ""%2"" o allo pseudonimo ""%3"". Il piano di scambio: %4.';
				|pl = 'Oczekiwany kod predefiniowanego węzła w tej aplikacji ""%1""
				|nie pokrywa się z faktycznym ""%2"" lub pseudonimem ""%3"". Plan wymiany: %4.';
				|tr = 'Bu uygulamadaki önceden tanımlanmış düğümün beklenen kodu ""%1""
				|gerçek ""%2"" kodu ile veya ""%3"" takma adı ile eşleşmiyor. Değişim planı: %4'"),
				Body.Code, ThisNodeCode, ThisNodeAlias, Body.ExchangePlan);
			Raise MessageString;
		EndIf;
	EndIf;
	
	CorrespondentEndpoint = DataExchangeSaaS.EndpointsExchangePlanManager().FindByCode(Body.EndPoint);
	
	If CorrespondentEndpoint.IsEmpty() Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không tìm thấy điểm cuối của cơ sở trao đổi dữ liệu với mã ""%1"".';
				|ru = 'Не найдена конечная точка корреспондента с кодом ""%1"".';
				|en = 'Endpoint with ID %1 not found.'; fa = 'Endpoint with ID %1 not found.';
				|it = 'L''endpoint del corrispondente con il codice ""%1"" non è stato trovato.';
				|pl = 'Nie znaleziono punktu końcowego korespondenta z kodem ""%1"".';
				|tr = '""%1"" kodlu muhabir uç noktası bulunamadı.'"),
			Body.EndPoint);
	EndIf;
	
	Prefix = "";
	CorrespondentPrefix = "";
	SettingID = "";
	
	If Message.IsSet("AdditionalInfo") Then
		AdditionalProperties = XDTOSerializer.ReadXDTO(Message.AdditionalInfo);
		If AdditionalProperties.Property("Prefix") Then
			Prefix = AdditionalProperties.Prefix;
		EndIf;
		If AdditionalProperties.Property("CorrespondentPrefix") Then
			CorrespondentPrefix = AdditionalProperties.CorrespondentPrefix;
		EndIf;
		If AdditionalProperties.Property("SettingID") Then
			SettingID = AdditionalProperties.SettingID;
		EndIf;
	EndIf;
	
	XDTOCorrespondentSettings = New Structure;
	
	Filter_Settings = XDTOSerializer.ReadXDTO(Body.FilterSettings);
	If Filter_Settings.Property("XDTOCorrespondentSettings") Then
		XDTOCorrespondentSettings = Filter_Settings.XDTOCorrespondentSettings;
	EndIf;
	
	// Create an exchange setting.
	ConnectionSettings = New Structure;
	ConnectionSettings.Insert("ExchangePlanName", Body.ExchangePlan);
	ConnectionSettings.Insert("SettingID", SettingID);
	
	ConnectionSettings.Insert("Description", ""); // Not required.
	ConnectionSettings.Insert("PeerInfobaseName", Body.CorrespondentName);
	
	ConnectionSettings.Insert("Prefix",               Prefix);
	ConnectionSettings.Insert("CorrespondentPrefix", CorrespondentPrefix);
	
	ConnectionSettings.Insert("SourceInfobaseID", ThisNodeCode);
	ConnectionSettings.Insert("DestinationInfobaseID", Body.CorrespondentCode);
	
	ConnectionSettings.Insert("CorrespondentEndpoint", CorrespondentEndpoint);
	
	ConnectionSettings.Insert("XDTOCorrespondentSettings", XDTOCorrespondentSettings);

	ConnectionSettings.Insert("Peer"); // Output parameter.
	
	ConnectionSettings.Insert("CorrespondentDataArea", Body.CorrespondentZone);
	
	BeginTransaction();
	Try
		DataExchangeSaaS.CreateExchangeSetting_3_0_1_1(ConnectionSettings,
			True, , ThisNodeAlias);
			
		// Sending a response message that notifies about the successful operation.
		ResponseMessage = ModuleMessagesSaaS.NewMessage(
			DataExchangeMessagesControlInterface.ExchangeSetupStep1CompletedMessage());
			
		ResponseMessage.Body.Zone = ModuleSaaSOperations.SessionSeparatorValue();
		ResponseMessage.Body.SessionId = Body.SessionId;
		
		ResponseMessage.Body.CorrespondentZone = Body.CorrespondentZone;
		
		ModuleMessagesSaaS.SendMessage(ResponseMessage, Sender, True);
		CommitTransaction();
	Except
		RollbackTransaction();
		
		ErrorPresentation = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(DataExchangeSaaS.EventLogEventDataSynchronizationSetup(),
			EventLogLevel.Error, , , ErrorPresentation);
		
		DataExchangeSaaS.DeleteExchangePlanNode(ConnectionSettings.Peer);
		
		// Sending a response error message.
		BeginTransaction();
		ResponseMessage = ModuleMessagesSaaS.NewMessage(
			DataExchangeMessagesControlInterface.ExchangeSetupErrorStep1Message());
			
		ResponseMessage.Body.Zone = ModuleSaaSOperations.SessionSeparatorValue();
		ResponseMessage.Body.SessionId = Body.SessionId;		
		
		ResponseMessage.Body.CorrespondentZone = Body.CorrespondentZone;
		ResponseMessage.Body.ErrorDescription = ErrorPresentation;
		
		ModuleMessagesSaaS.SendMessage(ResponseMessage, Sender, True);
		CommitTransaction();
	EndTry;
	
	ModuleMessagesSaaS.DeliverQuickMessages();
	
EndProcedure

Procedure ImportExchangeMessage(Message, Sender) Export
	
	If Not Common.SubsystemExists("CloudTechnology") Then
		Return;
	EndIf;
		
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	ModuleMessagesSaaS = Common.CommonModule("MessagesSaaS");
	
	MessageForDataMapping = False;
	
	If Message.IsSet("AdditionalInfo") Then
		AdditionalProperties = XDTOSerializer.ReadXDTO(Message.AdditionalInfo);
		If AdditionalProperties.Property("MessageForDataMapping") Then
			MessageForDataMapping = AdditionalProperties.MessageForDataMapping;
		EndIf;
	EndIf;
	
	Body = Message.Body;
	
	If Body.Properties().Get("MessageForDataMatching") <> Undefined 
		And Body.IsSet("MessageForDataMatching") Then
		MessageForDataMapping = Body.MessageForDataMatching; 
	EndIf;
	
	ResponseMessage = Undefined;
	Try
		Peer = ExchangeCorrespondent(Body.ExchangePlan, Body.CorrespondentCode);
		
		// Import an exchange message.
		Cancel = False;
		DataExchangeSaaS.RunDataImport(Cancel, Peer, MessageForDataMapping);
		If Cancel Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Trong quá trình kết nhập dữ liệu từ chương trình ""%1"" đã xảy ra lỗi.';
					|ru = 'В процессе загрузки данных из программы  ""%1"" возникли ошибки.';
					|en = 'Errors occurred during data import from ""%1"" application.'; fa = 'Errors occurred during data import from ""%1"" application.';
					|it = 'Si sono verificati degli errori durante il download dei dati dal programma ""%1"".';
					|pl = 'W trakcie pobierania danych z programu ""%1"" wystąpiły błędy.';
					|tr = '""%1"" programından veriler içe aktarılırken hatalar oluştu.'"),
				String(Peer));
		EndIf;
		
		// Sending a response message that notifies about the successful operation.
		ResponseMessage = ModuleMessagesSaaS.NewMessage(
			DataExchangeMessagesControlInterface.ExchangeMessageImportCompletedMessage());
		ResponseMessage.Body.Zone = ModuleSaaSOperations.SessionSeparatorValue();
		ResponseMessage.Body.CorrespondentZone = Body.CorrespondentZone;
		ResponseMessage.Body.SessionId = Body.SessionId;
	Except
		ErrorPresentation = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(DataExchangeSaaS.EventLogEventDataSynchronizationSetup(),
			EventLogLevel.Error, , , ErrorPresentation);
		
		// Sending a response error message.
		ResponseMessage = ModuleMessagesSaaS.NewMessage(
			DataExchangeMessagesControlInterface.ExchangeMessageImportErrorMessage());
		ResponseMessage.Body.Zone = ModuleSaaSOperations.SessionSeparatorValue();
		ResponseMessage.Body.CorrespondentZone = Body.CorrespondentZone;
		ResponseMessage.Body.SessionId = Body.SessionId;
		
		ResponseMessage.Body.ErrorDescription = ErrorPresentation;
		
	EndTry;
	
	If Not ResponseMessage = Undefined Then
		BeginTransaction();
		Try
			ModuleMessagesSaaS.SendMessage(ResponseMessage, Sender, True);
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
		ModuleMessagesSaaS.DeliverQuickMessages();
	EndIf;
	
EndProcedure

Procedure GetCorrespondentData(Message, Sender)
	
	If Not Common.SubsystemExists("CloudTechnology") Then
		Return;
	EndIf;
		
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	ModuleMessagesSaaS = Common.CommonModule("MessagesSaaS");
	
	Body = Message.Body;
	
	BeginTransaction();
	Try
		
		CorrespondentData = DataExchangeServer.CorrespondentTablesData(
			XDTOSerializer.ReadXDTO(Body.Tables), Body.ExchangePlan);
		
		// Sending a response message that notifies about successful setup
		ResponseMessage = ModuleMessagesSaaS.NewMessage(
			DataExchangeMessagesControlInterface.CorrespondentDataGettingCompletedMessage());
		ResponseMessage.Body.Zone = ModuleSaaSOperations.SessionSeparatorValue();
		ResponseMessage.Body.CorrespondentZone = Body.CorrespondentZone;
		ResponseMessage.Body.SessionId = Body.SessionId;
		
		ResponseMessage.Body.Data = New ValueStorage(CorrespondentData);
		ModuleMessagesSaaS.SendMessage(ResponseMessage, Sender, True);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		
		ErrorPresentation = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(DataExchangeSaaS.EventLogEventDataSynchronizationSetup(),
			EventLogLevel.Error,,, ErrorPresentation);
		
		// Sending a response error message
		ResponseMessage = ModuleMessagesSaaS.NewMessage(
			DataExchangeMessagesControlInterface.CorrespondentDataGettingErrorMessage());
		ResponseMessage.Body.Zone = ModuleSaaSOperations.SessionSeparatorValue();
		ResponseMessage.Body.CorrespondentZone = Body.CorrespondentZone;
		ResponseMessage.Body.SessionId = Body.SessionId;
		
		ResponseMessage.Body.ErrorDescription = ErrorPresentation;
		
		BeginTransaction();
		ModuleMessagesSaaS.SendMessage(ResponseMessage, Sender, True);
		CommitTransaction();
	EndTry;
	
	ModuleMessagesSaaS.DeliverQuickMessages();
	
EndProcedure

Procedure GetCommonDataOfCorrespondentNodes1(Message, Sender) Export
	
	If Not Common.SubsystemExists("CloudTechnology") Then
		Return;
	EndIf;
		
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	ModuleMessagesSaaS = Common.CommonModule("MessagesSaaS");
	
	Body = Message.Body;
	
	BeginTransaction();
	Try
		// Sending a response message that notifies about the successful operation.
		ResponseMessage = ModuleMessagesSaaS.NewMessage(
			DataExchangeMessagesControlInterface.GettingCommonDataOfCorrespondentNodeCompletedMessage());
			
		ResponseMessage.Body.Zone = ModuleSaaSOperations.SessionSeparatorValue();
		ResponseMessage.Body.CorrespondentZone = Body.CorrespondentZone;
		ResponseMessage.Body.SessionId = Body.SessionId;
		
		ErrorPresentation = "";
		IBParameters = DataExchangeServer.InfoBaseAdmParams(Body.ExchangePlan, "", ErrorPresentation);
		
		Result = New Structure;
		Result.Insert("CommonNodeData",            New Structure());
		Result.Insert("InfoBaseAdmParams", IBParameters);
		
		ResponseMessage.Body.Data = New ValueStorage(Result);
		
		ModuleMessagesSaaS.SendMessage(ResponseMessage, Sender, True);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		
		ErrorPresentation = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(DataExchangeSaaS.EventLogEventDataSynchronizationSetup(),
			EventLogLevel.Error,,, ErrorPresentation);
		
		// Sending a response error message
		ResponseMessage = ModuleMessagesSaaS.NewMessage(
			DataExchangeMessagesControlInterface.CorrespondentNodeCommonDataGettingErrorMessage());
		ResponseMessage.Body.Zone = ModuleSaaSOperations.SessionSeparatorValue();
		ResponseMessage.Body.CorrespondentZone = Body.CorrespondentZone;
		ResponseMessage.Body.SessionId = Body.SessionId;
		
		ResponseMessage.Body.ErrorDescription = ErrorPresentation;
		
		BeginTransaction();
		ModuleMessagesSaaS.SendMessage(ResponseMessage, Sender, True);
		CommitTransaction();
	EndTry;
	
	ModuleMessagesSaaS.DeliverQuickMessages();
	
EndProcedure

Procedure GetCorrespondentAccountingParameters(Message, Sender) Export
	
	If Not Common.SubsystemExists("CloudTechnology") Then
		Return;
	EndIf;
		
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	ModuleMessagesSaaS = Common.CommonModule("MessagesSaaS");
	
	Body = Message.Body;
	
	BeginTransaction();
	Try
		Cancel = False;
		ErrorPresentation = "";
		
		CorrespondentData = New Structure;
		
		IBParameters = DataExchangeServer.InfoBaseAdmParams(Body.ExchangePlan, Body.CorrespondentCode, ErrorPresentation);
		Cancel = Not IBParameters.AccountingParametersSettingsAreSpecified;
		
		CorrespondentData.Insert("InfoBaseAdmParams", IBParameters);
		
		CorrespondentData.Insert("AccountingParametersSpecified", Not Cancel);
		CorrespondentData.Insert("ErrorPresentation",  ErrorPresentation);
		
		// Sending a response message that notifies about successful setup
		ResponseMessage = ModuleMessagesSaaS.NewMessage(
			DataExchangeMessagesControlInterface.GettingCorrespondentAccountingParametersCompletedMessage());
			
		ResponseMessage.Body.Zone = ModuleSaaSOperations.SessionSeparatorValue();
		ResponseMessage.Body.SessionId = Body.SessionId;
		
		ResponseMessage.Body.CorrespondentZone = Body.CorrespondentZone;
		ResponseMessage.Body.Data = New ValueStorage(CorrespondentData);
		
		ModuleMessagesSaaS.SendMessage(ResponseMessage, Sender, True);
		
		CommitTransaction();
		
	Except
		RollbackTransaction();
		
		ErrorPresentation = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(DataExchangeSaaS.EventLogEventDataSynchronizationSetup(),
			EventLogLevel.Error,,, ErrorPresentation);
		
		// Sending a response error message
		ResponseMessage = ModuleMessagesSaaS.NewMessage(
			DataExchangeMessagesControlInterface.CorrespondentAccountingParametersGettingErrorMessage());
			
		ResponseMessage.Body.Zone = ModuleSaaSOperations.SessionSeparatorValue();
		ResponseMessage.Body.SessionId = Body.SessionId;
		
		ResponseMessage.Body.CorrespondentZone = Body.CorrespondentZone;
		ResponseMessage.Body.ErrorDescription = ErrorPresentation;
		
		BeginTransaction();
		ModuleMessagesSaaS.SendMessage(ResponseMessage, Sender, True);
		CommitTransaction();
	EndTry;
	
	ModuleMessagesSaaS.DeliverQuickMessages();
	
EndProcedure

Function ExchangeCorrespondent(Val ExchangePlanName, Val Code)
	
	Result = ExchangePlans[ExchangePlanName].FindByCode(Code);
	
	If Not ValueIsFilled(Result) Then
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không tìm thấy nút sơ đồ trao đổi; tên sơ đồ trao đổi %1; mã nút %2.';
				|ru = 'Не найден узел плана обмена; имя плана обмена %1; код узла %2.';
				|en = 'Node not found. Exchange plan: %1. Node ID: %2.'; fa = 'Node not found. Exchange plan: %1. Node ID: %2.';
				|it = 'Il nodo del piano di scambio non trovato; il nome del piano di scambio %1; codice del nodo %2.';
				|pl = 'Nie znaleziono węzła planu wymiany; nazwa planu wymiany %1; kod węzła %2.';
				|tr = 'Değişim planı düğümü bulunamadı; değişim planı adı %1; düğüm kodu %2.'"),
			ExchangePlanName, Code);
		Raise MessageString;
	EndIf;
	
	Return Result;
EndFunction

#EndRegion
