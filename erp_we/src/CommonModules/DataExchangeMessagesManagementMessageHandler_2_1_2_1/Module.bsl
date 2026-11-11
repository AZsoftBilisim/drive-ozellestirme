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
	
	Return "http://www.1c.ru/SaaS/Exchange/Manage";
	
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
	
	Dictionary = DataExchangeMessagesManagementInterface;
	MessageType = Message.Body.Type();
	
	If MessageType = Dictionary.SetUpExchangeStep1Message(Package()) Then
		
		ConfigureExchangeStep1(Message, Sender);
		
	ElsIf MessageType = Dictionary.SetUpExchangeStep2Message(Package()) Then
		
		ConfigureExchangeStep2(Message, Sender);
		
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

Procedure ConfigureExchangeStep1(Message, Sender)
	
	If Not Common.SubsystemExists("CloudTechnology") Then
		Return;
	EndIf;
		
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	ModuleMessagesSaaS = Common.CommonModule("MessagesSaaS");
	
	If Message.IsSet("AdditionalInfo") Then
		AdditionalProperties = XDTOSerializer.ReadXDTO(Message.AdditionalInfo);
		If AdditionalProperties.Property("Interface")
			And AdditionalProperties.Interface = "3.0.1.1" Then
			DataExchangeMessagesManagementMessageHandler_3_0_1_1.ConfigureExchangeStep1(Message, Sender);
			Return;
		EndIf;
	EndIf;
	
	Body = Message.Body;
	
	Peer = Undefined;
	
	BeginTransaction();
	Try
		
		ThisNodeCode       = Common.ObjectAttributeValue(ExchangePlans[Body.ExchangePlan].ThisNode(), "Code");
		ThisNodeAlias = "";
		
		If Not IsBlankString(ThisNodeCode)
			And ThisNodeCode <> Body.Code Then
			
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
		If Message.IsSet("AdditionalInfo") Then
			Prefix = XDTOSerializer.ReadXDTO(Message.AdditionalInfo).Prefix;
		EndIf;
		
		NodeFiltersSetting = XDTOSerializer.ReadXDTO(Body.FilterSettings);
		
		// {Handler: OnGetSenderData} Start
		If DataExchangeServer.HasExchangePlanManagerAlgorithm("OnGetSenderData", Body.ExchangePlan) Then
			ExchangePlans[Body.ExchangePlan].OnGetSenderData(NodeFiltersSetting, False);
		EndIf;
		// {Handler: OnGetSenderData} End
		
		// Create the exchange setting.
		ConnectionSettings = New Structure;
		ConnectionSettings.Insert("ExchangePlanName",              Body.ExchangePlan);
		ConnectionSettings.Insert("CorrespondentCode",           Body.CorrespondentCode);
		ConnectionSettings.Insert("PeerInfobaseName",  Body.CorrespondentName);
		ConnectionSettings.Insert("CorrespondentEndpoint", CorrespondentEndpoint);
		ConnectionSettings.Insert("Settings",                   NodeFiltersSetting);
		ConnectionSettings.Insert("Prefix",                     Prefix);
		ConnectionSettings.Insert("Peer"); // Output parameter.
		
		DataExchangeSaaS.CreateExchangeSetting(
			ConnectionSettings,
			True,
			,
			ThisNodeAlias);
			
		Peer = ConnectionSettings.Peer;
		
		// Registering catalogs to export
		DataExchangeServer.RegisterOnlyCatalogsForInitialExport(Peer);
		
		// Start data export.
		Cancel = False;
		DataExchangeSaaS.RunDataExport(Cancel, Peer);
		If Cancel Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã xảy ra lỗi trong quá trình kết xuất danh mục đối với cơ sở trao đổi dữ liệu %1.';
					|ru = 'Возникли ошибки в процессе выгрузки справочников для корреспондента %1.';
					|en = 'Error exporting catalogs to peer infobase %1.'; fa = 'Error exporting catalogs to peer infobase %1.';
					|it = 'Si sono verificati degli errori durante l''upoal delle directory per il corrispondente %1.';
					|pl = 'Wystąpiły błędy w trakcie ładowania poradników dla korespondenta %1.';
					|tr = '%1 muhabiri için kataloglar dışa aktarılırken hatalar oluştu.'"),
				String(Peer));
		EndIf;
		
		// Sending a response message that notifies about successful setup
		ResponseMessage = ModuleMessagesSaaS.NewMessage(
			DataExchangeMessagesControlInterface.ExchangeSetupStep1CompletedMessage());
		ResponseMessage.Body.Zone = ModuleSaaSOperations.SessionSeparatorValue();
		ResponseMessage.Body.CorrespondentZone = Body.CorrespondentZone;
		ResponseMessage.Body.SessionId = Body.SessionId;
		
		ModuleMessagesSaaS.SendMessage(ResponseMessage, Sender, True);
		CommitTransaction();
	Except
		RollbackTransaction();
		
		DataExchangeSaaS.DeleteExchangePlanNode(Peer);
		
		ErrorPresentation = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(DataExchangeSaaS.EventLogEventDataSynchronizationSetup(),
			EventLogLevel.Error,,, ErrorPresentation);
		
		// Sending a response error message
		BeginTransaction();
		ResponseMessage = ModuleMessagesSaaS.NewMessage(
			DataExchangeMessagesControlInterface.ExchangeSetupErrorStep1Message());
		ResponseMessage.Body.Zone = ModuleSaaSOperations.SessionSeparatorValue();
		ResponseMessage.Body.CorrespondentZone = Body.CorrespondentZone;
		ResponseMessage.Body.SessionId = Body.SessionId;
		
		ResponseMessage.Body.ErrorDescription = ErrorPresentation;
		
		ModuleMessagesSaaS.SendMessage(ResponseMessage, Sender, True);
		CommitTransaction();
	EndTry;
	
	ModuleMessagesSaaS.DeliverQuickMessages();
	
EndProcedure

Procedure ConfigureExchangeStep2(Message, Sender)
	
	If Not Common.SubsystemExists("CloudTechnology") Then
		Return;
	EndIf;
		
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	ModuleMessagesSaaS = Common.CommonModule("MessagesSaaS");
	
	Body = Message.Body;
	
	BeginTransaction();
	Try
		
		Peer = ExchangeCorrespondent(Body.ExchangePlan, Body.CorrespondentCode);
		
		// Update the exchange setting.
		DataExchangeSaaS.UpdateExchangeSetting(Peer,
			DataExchangeServer.GetFilterSettingsValues(XDTOSerializer.ReadXDTO(Body.AdditionalSettings)));
		
		// Registering all infobase data for exporting, except for catalogs
		DataExchangeServer.RegisterAllDataExceptCatalogsForInitialExport(Peer);
		
		// Sending a response message that notifies about successful setup
		ResponseMessage = ModuleMessagesSaaS.NewMessage(
			DataExchangeMessagesControlInterface.ExchangeSetupStep2CompletedMessage());
		ResponseMessage.Body.Zone = ModuleSaaSOperations.SessionSeparatorValue();
		ResponseMessage.Body.CorrespondentZone = Body.CorrespondentZone;
		ResponseMessage.Body.SessionId = Body.SessionId;
		
		ModuleMessagesSaaS.SendMessage(ResponseMessage, Sender, True);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		
		ErrorPresentation = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(DataExchangeSaaS.EventLogEventDataSynchronizationSetup(),
			EventLogLevel.Error,,, ErrorPresentation);
		
		// Sending a response error message
		ResponseMessage = ModuleMessagesSaaS.NewMessage(
			DataExchangeMessagesControlInterface.ExchangeSetupErrorStep2Message());
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

Procedure ImportExchangeMessage(Message, Sender)
	
	If Not Common.SubsystemExists("CloudTechnology") Then
		Return;
	EndIf;
		
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	ModuleMessagesSaaS = Common.CommonModule("MessagesSaaS");
	
	If Message.IsSet("AdditionalInfo") Then
		AdditionalProperties = XDTOSerializer.ReadXDTO(Message.AdditionalInfo);
		If AdditionalProperties.Property("Interface")
			And AdditionalProperties.Interface = "3.0.1.1" Then
			DataExchangeMessagesManagementMessageHandler_3_0_1_1.ImportExchangeMessage(Message, Sender);
			Return;
		EndIf;
	EndIf;
	
	Body = Message.Body;
	
	ResponseMessage = Undefined;
	Try
		
		Peer = ExchangeCorrespondent(Body.ExchangePlan, Body.CorrespondentCode);
		
		// Import an exchange message.
		Cancel = False;
		DataExchangeSaaS.RunDataImport(Cancel, Peer);
		If Cancel Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã xảy ra lỗi trong quá trình kết nhập danh mục từ cơ sở trao đổi dữ liệu %1.';
					|ru = 'Возникли ошибки в процессе загрузки справочников от корреспондента %1.';
					|en = 'Error importing catalogs from peer infobase %1.'; fa = 'Error importing catalogs from peer infobase %1.';
					|it = 'Si sono verificati degli errori durante il download delle directory per il corrispondente %1.';
					|pl = 'Wystąpiły błędy podczas pobierania poradników od korespondenta %1.';
					|tr = '%1 muhabirinden kataloglar içe aktarılırken hatalar oluştu.'"),
				String(Peer));
		EndIf;
		
		// Sending a response message that notifies about successful setup
		ResponseMessage = ModuleMessagesSaaS.NewMessage(
			DataExchangeMessagesControlInterface.ExchangeMessageImportCompletedMessage());
		ResponseMessage.Body.Zone = ModuleSaaSOperations.SessionSeparatorValue();
		ResponseMessage.Body.CorrespondentZone = Body.CorrespondentZone;
		ResponseMessage.Body.SessionId = Body.SessionId;
		
	Except
		
		ErrorPresentation = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(DataExchangeSaaS.EventLogEventDataSynchronizationSetup(),
			EventLogLevel.Error,,, ErrorPresentation);
		
		// Sending a response error message
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

Procedure GetCommonDataOfCorrespondentNodes1(Message, Sender)
	
	If Not Common.SubsystemExists("CloudTechnology") Then
		Return;
	EndIf;
		
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	ModuleMessagesSaaS = Common.CommonModule("MessagesSaaS");
	
	If Message.IsSet("AdditionalInfo") Then
		AdditionalProperties = XDTOSerializer.ReadXDTO(Message.AdditionalInfo);
		If AdditionalProperties.Property("Interface")
			And AdditionalProperties.Interface = "3.0.1.1" Then
			DataExchangeMessagesManagementMessageHandler_3_0_1_1.GetCommonDataOfCorrespondentNodes1(Message, Sender);
			Return;
		EndIf;
	EndIf;
	
	Body = Message.Body;
	
	BeginTransaction();
	Try
		
		CorrespondentData = DataExchangeServer.DataForThisInfobaseNodeTabularSections(Body.ExchangePlan);
		
		// Sending a response message that notifies about successful setup
		ResponseMessage = ModuleMessagesSaaS.NewMessage(
			DataExchangeMessagesControlInterface.GettingCommonDataOfCorrespondentNodeCompletedMessage());
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

Procedure GetCorrespondentAccountingParameters(Message, Sender)
	
	If Not Common.SubsystemExists("CloudTechnology") Then
		Return;
	EndIf;
		
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	ModuleMessagesSaaS = Common.CommonModule("MessagesSaaS");
	
	If Message.IsSet("AdditionalInfo") Then
		AdditionalProperties = XDTOSerializer.ReadXDTO(Message.AdditionalInfo);
		If AdditionalProperties.Property("Interface")
			And AdditionalProperties.Interface = "3.0.1.1" Then
			DataExchangeMessagesManagementMessageHandler_3_0_1_1.GetCorrespondentAccountingParameters(Message, Sender);
			Return;
		EndIf;
	EndIf;
	
	
	Body = Message.Body;
	
	BeginTransaction();
	Try
		
		Peer = ExchangeCorrespondent(Body.ExchangePlan, Body.CorrespondentCode);
		
		Cancel = False;
		ErrorPresentation = "";
		
		CorrespondentData = New Structure;
		
		If DataExchangeServer.HasExchangePlanManagerAlgorithm("AccountingSettingsCheckHandler", Body.ExchangePlan) Then
			ExchangePlans[Body.ExchangePlan].AccountingSettingsCheckHandler(Cancel, Peer, ErrorPresentation);
		EndIf;
		
		CorrespondentData.Insert("AccountingParametersSpecified", Not Cancel);
		CorrespondentData.Insert("ErrorPresentation",  ErrorPresentation);
		
		// Sending a response message that notifies about successful setup
		ResponseMessage = ModuleMessagesSaaS.NewMessage(
			DataExchangeMessagesControlInterface.GettingCorrespondentAccountingParametersCompletedMessage());
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
			DataExchangeMessagesControlInterface.CorrespondentAccountingParametersGettingErrorMessage());
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

Function ExchangeCorrespondent(Val ExchangePlanName, Val Code)
	
	Result = ExchangePlans[ExchangePlanName].FindByCode(Code);
	
	If Not ValueIsFilled(Result) Then
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không tìm thấy nút sơ đồ trao đổi; tên sơ đồ trao đổi %1; mã nút %2.';
				|ru = 'Не найден узел плана обмена; имя плана обмена %1; код узла %2.';
				|en = 'Node not found. Exchange plan: %1. Node ID: %2.'; fa = 'Node not found. Exchange plan: %1. Node ID: %2.';
				|it = 'Il nodo del piano di scambio non trovato; il nome del piano di scambio %1; codice del nodo %2.';
				|pl = 'Nie znaleziono węzła planu wymiany; nazwa planu wymiany %1; kod węzła %2.';
				|tr = 'Değişim planı düğümü bulunamadı; değişim planı adı %1; düğüm kodu %2.'"), ExchangePlanName, Code);
		Raise MessageString;
	EndIf;
	
	Return Result;
EndFunction

#EndRegion
