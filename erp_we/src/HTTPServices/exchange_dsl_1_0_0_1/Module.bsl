///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Private

Function InterfaceVersion()
	
	Return 1;
	
EndFunction

Function GetVersion_GET(Query)
	
	Response = New HTTPServiceResponse(200);
	Response.SetBodyFromString(InterfaceVersion());
	Return Response;

EndFunction

Function GetIBParameters_GET(Query)
	
	Response = New HTTPServiceResponse(200);
	
	ExchangePlanName = Query.QueryOptions.Get("ExchangePlanName");
	NodeCode = Query.QueryOptions.Get("NodeCode");
	IsXDTOExchangePlan = Query.QueryOptions.Get("IsXDTOExchangePlan");
	
	AdditionalParameters = New Structure;
	If ValueIsFilled(IsXDTOExchangePlan) Then
		AdditionalParameters.Insert("IsXDTOExchangePlan", True);
	EndIf;
	
	ErrorMessage = "";
	
	Try
	
		Parameters = DataExchangeServer.InfoBaseAdmParams_20(ExchangePlanName, NodeCode, ErrorMessage, AdditionalParameters);
	
	Except
		
		ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			
		WriteLogEvent(DataExchangeServer.DataExchangeCreationEventLogEvent(),
			EventLogLevel.Error, , , ErrorMessage);
		
		Return ErrorResponse(ErrorMessage);
		
	EndTry;
	
	BodyAsString = ExchangeMessagesTransport.ValueToJSON(Parameters);
	
	Response.SetBodyFromString(BodyAsString);
	Response.Headers.Insert("Content-Type","text/html; charset=utf-8");
	
	Return Response;
	
EndFunction

Function CreateExchangeNodePOST(Query)
	
	Response = New HTTPServiceResponse(200);
	
	SetPrivilegedMode(True);
	
	DataExchangeServer.CheckDataExchangeUsage(True);
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	
	Try
		
		BodyAsString = Query.GetBodyAsString(TextEncoding.UTF8);
		ConnectionSettingsFromRequest = ExchangeMessagesTransport.ConnectionSettingsFromJSON(BodyAsString);
		ConnectionSettingsFromRequest.Insert("TransportID", "PassiveMode");
		ConnectionSettingsFromRequest.Insert("TransportSettings", New Structure);
		
		ConnectionSettings = ExchangeMessagesTransportClientServer.StructureOfConnectionSettings();
		ConnectionSettings.ExchangePlanName = ConnectionSettingsFromRequest.ExchangePlanName;
	
		ExchangeMessagesTransport.CheckAndFillInXMLConnectionSettings(ConnectionSettings, ConnectionSettingsFromRequest);
		
		ModuleSetupWizard.ConfigureDataExchange(ConnectionSettings);
		
	Except
		
		ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			
		WriteLogEvent(DataExchangeServer.DataExchangeCreationEventLogEvent(),
			EventLogLevel.Error, , , ErrorMessage);
		
		Return ErrorResponse(ErrorMessage);
		
	EndTry;
	
	Return Response;
	
EndFunction

Function PutFileForMapping_POST(Query)
	
	Response = New HTTPServiceResponse(200);
	
	ExchangePlanName = Query.QueryOptions.Get("ExchangePlanName");
	NodeCode = Query.QueryOptions.Get("NodeCode");
	FileID = Query.QueryOptions.Get("FileID");
	
	Try
		
		ExchangeWebServiceOperationData.PutMessageForDataMapping(
			ExchangePlanName, NodeCode, FileID);
		
	Except
		
		Return ErrorResponse(ErrorInfo());
		
	EndTry;
		
	Return Response;
	
EndFunction

Function PutFileChunk_POST(Query)
	
	Response = New HTTPServiceResponse(200);
	
	SessionID = New UUID(Query.QueryOptions.Get("SessionID"));
	PartNumber = Number(Query.QueryOptions.Get("PartNumber"));
	
	PartData = Query.GetBodyAsBinaryData();
	
	Try
		
		ExchangeWebServiceOperationData.PutFileChunk(SessionID, PartNumber, PartData);
		
	Except
		
		Return ErrorResponse(ErrorInfo());
		
	EndTry;
	
	Return Response;
	
EndFunction

Function AssembleFileFromParts_POST(Query)
	
	Response = New HTTPServiceResponse(200);
	
	SessionID = New UUID(Query.QueryOptions.Get("SessionID"));
	PartCount = Number(Query.QueryOptions.Get("PartCount"));
	FileID = Undefined;
	
	Try
		ExchangeWebServiceOperationData.AssembleFileFromParts(SessionID, PartCount, FileID);
	Except
		Return ErrorResponse(ErrorInfo());
	EndTry;
	
	Body = New Structure("FileID", String(FileID));
	BodyAsString = ExchangeMessagesTransport.ValueToJSON(Body);
	Response.SetBodyFromString(BodyAsString);
		
	Return Response;
	
EndFunction

Function RunDataImport_POST(Query)
	
	Response = New HTTPServiceResponse(200);
	
	ExchangePlanName = Query.QueryOptions.Get("ExchangePlanName");
	NodeCode = Query.QueryOptions.Get("NodeCode");
	FileID = Query.QueryOptions.Get("FileID");
	TimeConsumingOperationAllowed = Query.QueryOptions.Get("TimeConsumingOperationAllowed");

	TimeConsumingOperation = Undefined;
	OperationID = Undefined;
	
	Try 
		ExchangeWebServiceOperationData.RunDataImport(ExchangePlanName, NodeCode, FileID, 
			TimeConsumingOperation, OperationID, TimeConsumingOperationAllowed);
	Except
		Return ErrorResponse(ErrorInfo());
	EndTry;
	
	Body = New Structure;
	Body.Insert("TimeConsumingOperation", TimeConsumingOperation);
	Body.Insert("OperationID", OperationID);
	
	BodyAsString = ExchangeMessagesTransport.ValueToJSON(Body);
	Response.SetBodyFromString(BodyAsString);
	
	Return Response;

EndFunction

Function GetStateOfTimeConsumingOperations_GET(Query)
	
	Response = New HTTPServiceResponse(200);
	
	OperationID = Query.QueryOptions.Get("OperationID");
	ErrorMessageString = Undefined;
	
	State = ExchangeWebServiceOperationData.GetTimeConsumingOperationState(OperationID, ErrorMessageString);
	
	If ValueIsFilled(ErrorMessageString) Then
		Return ErrorResponse(ErrorMessageString);
	EndIf;
	
	Body = New Structure;
	Body.Insert("ActionState", State);
	Body.Insert("Message", ErrorMessageString);
	
	BodyAsString = ExchangeMessagesTransport.ValueToJSON(Body);
	
	Response.SetBodyFromString(BodyAsString);

	Return Response;

EndFunction

Function RunDataExport_POST(Query)
	
	Response = New HTTPServiceResponse(200);
	
	ExchangePlanName = Query.QueryOptions.Get("ExchangePlanName");
	NodeCode = Query.QueryOptions.Get("NodeCode");
	TimeConsumingOperationAllowed = Query.QueryOptions.Get("TimeConsumingOperationAllowed");
	
	FileID = Undefined;
	TimeConsumingOperation = Undefined;
	OperationID = Undefined;
	
	Try
		ExchangeWebServiceOperationData.RunDataExport(ExchangePlanName, NodeCode, 
			FileID, TimeConsumingOperation, OperationID, TimeConsumingOperationAllowed);
	Except
		Return ErrorResponse(ErrorInfo());
	EndTry;
	
	Body = New Structure;
	Body.Insert("TimeConsumingOperation", TimeConsumingOperation);
	Body.Insert("OperationID", OperationID);
	Body.Insert("FileID", FileID);

	BodyAsString = ExchangeMessagesTransport.ValueToJSON(Body);
	
	Response.SetBodyFromString(BodyAsString);
	
	Return Response;

EndFunction

Function PrepareFileForReceiving_POST(Query)
	
	Response = New HTTPServiceResponse(200);
	
	FileID = Query.QueryOptions.Get("FileID");
	PartSize = Number(Query.QueryOptions.Get("BlockSize"));
	
	SessionID = Undefined;
	PartCount = Undefined;
	
	Try
		ExchangeWebServiceOperationData.PrepareFileForReceipt(FileID, PartSize, SessionID, PartCount);
	Except
		Return ErrorResponse(ErrorInfo());
	EndTry;
		
	Body = New Structure;
	Body.Insert("SessionID", String(SessionID));
	Body.Insert("PartCount", PartCount);
	
	BodyAsString = ExchangeMessagesTransport.ValueToJSON(Body);
	Response.SetBodyFromString(BodyAsString);
	
	Return Response;
	
EndFunction

Function GetPartOfFile_GET(Query)
	
	Response = New HTTPServiceResponse(200);
	
	SessionID = New UUID(Query.QueryOptions.Get("SessionID"));
	PartNumber = Number(Query.QueryOptions.Get("PartNumber"));
	PartData = Undefined;
	
	Try
		ExchangeWebServiceOperationData.GetFileChunk(SessionID, PartNumber, PartData);
	Except
		Return ErrorResponse(ErrorInfo());
	EndTry;
		
	Response.SetBodyFromBinaryData(PartData);
	
	Return Response;

EndFunction

Function DeleteFiles_DELETE(Query)
	
	Response = New HTTPServiceResponse(200);
	
	SessionID = New UUID(Query.QueryOptions.Get("SessionID"));

	Try
		ExchangeWebServiceOperationData.DeleteExchangeMessage(SessionID);
	Except
		Return ErrorResponse(ErrorInfo());
	EndTry;
		
	Return Response;

EndFunction

Function DeleteExchangeNode_DELETE(Query)
	
	Response = New HTTPServiceResponse(200);
	
	ExchangePlanName = Query.QueryOptions.Get("ExchangePlanName");
	NodeCode = Query.QueryOptions.Get("NodeCode");
	
	Try
		ExchangeWebServiceOperationData.DeleteDataExchangeNode(ExchangePlanName, NodeCode);
	Except
		Return ErrorResponse(ErrorInfo());
	EndTry;
	
	Return Response;

EndFunction

Function ErrorResponse(ErrorInfo = "")
	
	If TypeOf(ErrorInfo) = Type("ErrorInfo") Then
		ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
	EndIf;
	
	Body = New Structure("Message", ErrorMessage);
	BodyAsString = ExchangeMessagesTransport.ValueToJSON(Body);
			
	Response = New HTTPServiceResponse(400);
	Response.SetBodyFromString(BodyAsString);
	
	EventLogMessageKey = NStr("vi = 'Truyền thông điệp trao đổi';
								|ru = 'Транспорт сообщений обмена';
								|en = 'Exchange message transport'; fa = 'انتقال پیام تبادل';
								|it = 'Транспорт сообщений обмена';
								|pl = 'Exchange message transport';
								|tr = 'Değişim ileti aktarımı'", Common.DefaultLanguageCode());
	WriteLogEvent(
		EventLogMessageKey, 
		EventLogLevel.Error,,,
		ErrorMessage);
	Return Response;
	
EndFunction

#EndRegion
