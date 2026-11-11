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
	
	Try
		Result = SendExchangeMessage(MessageForDataMapping);
	Except
		Result = False;
	EndTry;
	
	Return Result;
	
EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.GetData
Function GetData() Export

	Try
		Result = GetExchangeMessage();
	Except
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo());
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataImport");
		
		Result = False;
		
	EndTry;
	
	Return Result;
	
EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.BeforeExportData
Function BeforeExportData(MessageForDataMapping = False) Export
	
	Return CheckingExternalConnectionBeforeExchange(Enums.ActionsOnExchange.DataExport, MessageForDataMapping);
	
EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.CorrespondentParameters
Function CorrespondentParameters(ConnectionSettings) Export
	
	Result = ExchangeMessagesTransport.StructureOfResultOfObtainingParametersOfCorrespondent();
	Result.Insert("CorrespondentExchangePlanName", ExchangePlanName);
	
	ExternalConnection = EstablishExternalConnectionWithInfobase();
	If ExternalConnection = Undefined Then
		Result.ErrorMessage = ErrorMessage;
		Result.ConnectionIsSet = False;
		Return Result;
	EndIf;
	
	Result.ConnectionIsSet = True;
	Result.InterfaceVersions = ExchangeMessagesTransport.InterfaceVersionsThroughExternalConnection(ExternalConnection);
	
	If Result.InterfaceVersions.Find("3.0.1.1") <> Undefined
		Or Result.InterfaceVersions.Find("3.0.2.1") <> Undefined
		Or Result.InterfaceVersions.Find("3.0.2.2") <> Undefined Then 
		
		ErrorMessage = "";
		
		SourceInfobaseID = DataExchangeServer.PredefinedExchangePlanNodeCode(ExchangePlanName);
		
		If Result.InterfaceVersions.Find("3.0.2.2") <> Undefined Then
			
			AdditionalParameters = New Structure;
			If DataExchangeCached.IsXDTOExchangePlan(ExchangePlanName) Then
				AdditionalParameters.Insert("IsXDTOExchangePlan", True);
				AdditionalParameters.Insert("SettingID", ConnectionSettings.SettingID);
			EndIf;
			
			InfoBaseAdmParams = ExternalConnection.DataExchangeExternalConnection.GetInfobaseParameters_3_0_2_2(
				CorrespondentExchangePlanName,
				SourceInfobaseID,
				ErrorMessage,
				AdditionalParameters);
		Else
			
			InfoBaseAdmParams = ExternalConnection.DataExchangeExternalConnection.GetInfobaseParameters_2_0_1_6(
				CorrespondentExchangePlanName,
				SourceInfobaseID,
				ErrorMessage);
			
		EndIf;
		
		CorrespondentParameters = Common.ValueFromXMLString(InfoBaseAdmParams);
		
		If Not CorrespondentParameters.ExchangePlanExists Then
				
			MessageTemplate = 
				NStr("vi = 'Trong cơ sở trao đổi dữ liệu không tìm thấy sơ đồ trao đổi ""%1"".
					|Hãy chắc chắn rằng,
					| - đã chọn đúng dạng ứng dụng để tùy chỉnh trao đổi;
					| - đã chỉ ra đúng vị trí chương trình đang kết nối.';
					|ru = 'В корреспонденте не найден план обмена ""%1"".
					|Убедитесь, что
					| - выбран правильный вид приложения для настройки обмена;
					| - корректно указано расположение программы, к которой выполняется подключение.';
					|en = 'Exchange plan ""%1"" is not found in the peer application.
					|Ensure that the following data is correct:
					|- The application type selected in the exchange settings.
					|- The application location specified in the connection settings.'; fa = 'Exchange plan ""%1"" is not found in the peer application.
					|Ensure that the following data is correct:
					|- The application type selected in the exchange settings.
					|- The application location specified in the connection settings.';
					|it = 'Il piano di scambio ""%1"" non è stato trovato nel corrispondente.
					|Assicurarsi che
					| - è stato selezionato il tipo corretto di applicazione per la configurazione di scambio;
					| - la posizione del programma di connessione è specificata correttamente.';
					|pl = 'W korespondencie nie znaleziono planu wymiany ""%1"".
					|Przekonaj się, że
					| - wybrano właściwy rodzaj aplikacji dla ustawienia wymiany;
					| - prawidłowo określono lokalizację programu, do którego wykonywane jest połączenie.';
					|tr = 'Muhabirde ""%1"" alışveriş planı bulunamadı. 
					| - 
					|Veri alışverişini yapılandırmak için uygulamanın türü doğru seçildiğinden; 
					|- bağlantının yapıldığı programın konumunun doğru belirtildiğinden emin olun.'");
			
			ErrorMessage = StrTemplate(MessageTemplate, ExchangePlanName);
			
			Result.ErrorMessage = ErrorMessage;
			
			ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject);
			
			Return Result;
			
		EndIf;
		
		Result.CorrespondentParametersReceived = True;
		Result.CorrespondentParameters = CorrespondentParameters;
		Result.CorrespondentExchangePlanName = CorrespondentParameters.ExchangePlanName;
		
	Else
		
		ErrorMessage = 
			NStr("vi = 'Cơ sở thông tin trao đổi không hỗ trợ phiên bản 3.0.1.1 của giao diện ""TraoĐổiDữLiệu"".
			|Để tùy chỉnh kết nối, hãy cập nhật cấu hình cơ sở thông tin trao đổi hoặc bắt đầu tùy chỉnh từ đó.';
			|ru = 'Корреспондент не поддерживает версию 3.0.1.x интерфейса ""ОбменДанными"".
			|Для настройки подключения обновите конфигурацию корреспондента, или начните настройку из него.';
			|en = 'The peer infobase does not support version 3.0.1.x of the DataExchange interface.
			|To set up the connection, update the peer infobase configuration or start setting up from it.'; fa = 'The peer infobase does not support version 3.0.1.x of the DataExchange interface.
			|To set up the connection, update the peer infobase configuration or start setting up from it.';
			|it = 'Корреспондент не поддерживает версию 3.0.1.x интерфейса ""ОбменДанными"".
			|Для настройки подключения обновите конфигурацию корреспондента, или начните настройку из него.';
			|pl = 'The peer infobase does not support version 3.0.1.x of the DataExchange interface.
			|To set up the connection, update the peer infobase configuration or start setting up from it.';
			|tr = 'Muhabir ""ОбменДанными"" arayüzü 3.0.1.1 sürümünü desteklemiyor.
			|Bağlantı kurmak için muhabir konfigürasyonunu güncelleyin veya buradan yapılandırmaya başlayın.'");
		
		Result.ConnectionAllowed = False;
		Result.ErrorMessage = ErrorMessage;
		
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject);
		
		Return Result;
		
	EndIf;
	
	Cancel = False;
	ErrorMessage = "";
	
	ExchangeMessagesTransport.OnConnectToCorrespondent(
		Cancel, ExchangePlanName, CorrespondentParameters.ConfigurationVersion, ErrorMessage);
	
	If Cancel Then
		
		Result.ConnectionAllowed = False;
		Result.ErrorMessage = ErrorMessage;
		
		Return Result;
		
	EndIf;
	
	ExchangeMessagesTransport.CheckForDuplicateSyncs(ExchangePlanName, CorrespondentParameters, Result);
	
	Result.ConnectionAllowed = True;
	
	Return Result;
	
EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.SaveSettingsInCorrespondent
Function SaveSettingsInCorrespondent(ConnectionSettings) Export
	
	ExternalConnection = EstablishExternalConnectionWithInfobase();
	If ExternalConnection = Undefined Then
		Return False;
	EndIf;
		
	CorrespondentConnectionSettings = ExternalConnection.DataProcessors.DataExchangeCreationWizard.Create();
	
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
		
	Try
		
		XMLConnectionSettingsString = DataProcessors.ExchangeMessageTransportCOM.ConnectionSettingsInXML(ConnectionSettings);
		
		ExternalConnection.DataProcessors.DataExchangeCreationWizard.FillConnectionSettingsFromXMLString(
			CorrespondentConnectionSettings, XMLConnectionSettingsString);
		
	Except
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo());
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject);
		
		Return False;
		
	EndTry;
	
	If DataExchangeCached.IsXDTOExchangePlan(ExchangePlanName) Then
		
		CorrespondentConnectionSettings.ExchangeFormatVersion = ConnectionSettings.ExchangeFormatVersion;
		
		TableObjects = DataExchangeXDTOServer.SupportedObjectsInFormat(
			ConnectionSettings.ExchangePlanName, "SendReceive", ConnectionSettings.InfobaseNode);
		
		StorageString = XDTOSerializer.XMLString(
			New ValueStorage(TableObjects, New Deflation(9)));
		
		CorrespondentConnectionSettings.SupportedObjectsInFormat = 
			ExternalConnection.XDTOSerializer.XMLValue(
				ExternalConnection.NewObject("TypeDescription", "ValueStorage").Types().Get(0), StorageString);
		
	EndIf;
		
	Try
		
		ExternalConnection.DataExchangeServer.CheckDataExchangeUsage(True);
		ExternalConnection.DataProcessors.DataExchangeCreationWizard.ConfigureDataExchange(
			CorrespondentConnectionSettings);
		
	Except
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo());
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject);
		
		Return False;
		
	EndTry;
	
	Return True;
	
EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.AuthenticationRequired
Function AuthenticationRequired() Export
	
	Return ContinueSettings;
	
EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.DeleteSynchronizationSettingInCorrespondent
Function DeleteSynchronizationSettingInCorrespondent() Export
		
	ExternalConnection = EstablishExternalConnectionWithInfobase();
	If ExternalConnection = Undefined Then
		Return False;
	EndIf;
	
	NodeID = DataExchangeServer.NodeIDForExchange(Peer);
	CorrespondentNode = ExternalConnection.DataExchangeServer.ExchangePlanNodeByCode(CorrespondentExchangePlanName, NodeID);
	
	If CorrespondentNode = Undefined Then
		
		MessageTemplate = NStr("vi = 'Trong chương trình-cơ sở trao đổi dữ liệu không tìm thấy nút trao đổi ""%1"" có mã ""%2"".';
								|ru = 'В программе-корреспонденте не найден узел плана обмена ""%1"" по коду ""%2"".';
								|en = 'Exchange plan node ""%1"" is not found in the peer application by code ""%2"".'; fa = 'Exchange plan node ""%1"" is not found in the peer application by code ""%2"".';
								|it = 'Nessun nodo del piano di scambio ""%1"" per codice ""%2"" è stato trovato nel programma corrispondente.';
								|pl = 'W programie-korespondencie nie znaleziono wezła planu wymiany ""%1"" według kodu ""%2""-';
								|tr = 'Muhabir programında ""%1"" kodu ile ""%2"" değişim planı düğümü bulunamadı.'");
		ErrorMessage = StrTemplate(MessageTemplate, CorrespondentExchangePlanName, NodeID);
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject);
		
		Return False;
		
	EndIf;
	
	Try
		
		ExternalConnection.DataExchangeServer.DeleteSynchronizationSetting(CorrespondentNode);
		
	Except
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo());
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject);
		
		Return False;
		
	EndTry;
	
	Return True;
	
EndFunction

#EndRegion

#Region Private

Function ConnectionIsSet() Export
	
	ExternalConnection = EstablishExternalConnectionWithInfobase();
	
	If ExternalConnection = Undefined Then
		Return False;
	Else
		Return True;
	EndIf;

EndFunction

Function SendExchangeMessage(MessageForDataMapping)
	 
	StructureOfExchangeSettingsOfSun = Undefined;
	ExchangeWithSSL20 = False;
		
	ExternalConnection = ExternalConnectionForSendingReceivingMessage(
		Enums.ActionsOnExchange.DataExport,
		StructureOfExchangeSettingsOfSun,
		ExchangeWithSSL20,
		MessageForDataMapping);
	
	If ExternalConnection = Undefined Then
		Return False;
	EndIf;
	
	If DataExchangeCached.IsXDTOExchangePlan(ExchangePlanName) Then
		DataProcessorForDataImport = ExternalConnection.DataProcessors.ConvertXTDOObjects.Create();
	Else
		DataProcessorForDataImport = ExternalConnection.DataProcessors.InfobaseObjectConversion.Create();
	EndIf;
	
	DataProcessorForDataImport.ExchangeMode = "Load";
	DataProcessorForDataImport.ExchangeNodeDataImport = StructureOfExchangeSettingsOfSun.InfobaseNode;
	
	DataExchangeServer.SetCommonParametersForDataExchangeProcessing(DataProcessorForDataImport, StructureOfExchangeSettingsOfSun, ExchangeWithSSL20);
	
	HasMapSupport            = True;
	DataSynchronizationSetupCompleted = True;
	InterfaceVersions = ExchangeMessagesTransport.InterfaceVersionsThroughExternalConnection(ExternalConnection);
	
	If InterfaceVersions.Find("3.0.1.1") <> Undefined
		Or InterfaceVersions.Find("3.0.2.1") <> Undefined 
		Or InterfaceVersions.Find("3.0.2.2") <> Undefined Then
			
		ErrorMessage = "";
		NodeCode = DataExchangeServer.PredefinedExchangePlanNodeCode(ExchangePlanName);
		
		CorrespondentExchangePlanName = DataExchangeCached.GetNameOfCorrespondentExchangePlan(Peer);
		
		If InterfaceVersions.Find("3.0.2.2") <> Undefined Then
			
			AdditionalParameters = New Structure;
			If DataExchangeCached.IsXDTOExchangePlan(ExchangePlanName) Then
				AdditionalParameters.Insert("IsXDTOExchangePlan", True);
			EndIf;
			
			InfoBaseAdmParams =  ExternalConnection.DataExchangeExternalConnection.GetInfobaseParameters_3_0_2_2(
				CorrespondentExchangePlanName, NodeCode, ErrorMessage, AdditionalParameters);
		Else
			
			InfoBaseAdmParams =  ExternalConnection.DataExchangeExternalConnection.GetInfobaseParameters_2_0_1_6(
				CorrespondentExchangePlanName, NodeCode, ErrorMessage);
				
		EndIf;
			
		CorrespondentParameters = Common.ValueFromXMLString(InfoBaseAdmParams);
		
		If CorrespondentParameters.Property("DataMappingSupported") Then
			HasMapSupport = CorrespondentParameters.DataMappingSupported;
		EndIf;
		
		If CorrespondentParameters.Property("DataSynchronizationSetupCompleted") Then
			DataSynchronizationSetupCompleted = CorrespondentParameters.DataSynchronizationSetupCompleted;
		EndIf;
		
	EndIf;
	
	If MessageForDataMapping
		And (HasMapSupport Or Not DataSynchronizationSetupCompleted) Then
		DataProcessorForDataImport.DataImportMode = "ImportMessageForDataMapping";
	EndIf;
	
	DataProcessorForDataImport.ObjectCountPerTransaction = 
		ItemsCountInTransactionOfActionToExecute(Enums.ActionsOnExchange.DataExport); 
	DataProcessorForDataImport.UseTransactions = (DataProcessorForDataImport.ObjectCountPerTransaction <> 1);
		
	If MessageForDataMapping Then
		
		TextReader = New TextReader(ExchangeMessage);
		XMLExportData = TextReader.Read();
		TextReader.Close();
	
		DataProcessorForDataImport.PutMessageForDataMapping(XMLExportData);
		
	Else
		
		DataProcessorForDataImport.ExchangeFileName = ExchangeMessage;
		DataProcessorForDataImport.RunDataImport();
		
	EndIf;
	
	StructureOfExchangeSettingsOfSun.ExchangeExecutionResultString = DataProcessorForDataImport.ExchangeExecutionResultString();
	DataProcessorForDataImport = Undefined;
	
	ExternalConnection.DataExchangeExternalConnection.WriteExchangeFinish(StructureOfExchangeSettingsOfSun);
	ExternalConnection = Undefined;
	
	Return True;
	
EndFunction

Function GetExchangeMessage()
	
	StructureOfExchangeSettingsOfSun = Undefined;
	ExchangeWithSSL20 = False;
	
	ExternalConnection = ExternalConnectionForSendingReceivingMessage(
		Enums.ActionsOnExchange.DataImport,
		StructureOfExchangeSettingsOfSun,
		ExchangeWithSSL20);
		
	If ExternalConnection = Undefined Then
		Return False;
	EndIf;
		
	If Not DataExchangeCached.IsXDTOExchangePlan(ExchangePlanName) Then
		
		// Getting exchange rules from the second infobase.
		ObjectsConversionRules = ExternalConnection.DataExchangeExternalConnection.GetObjectConversionRules(StructureOfExchangeSettingsOfSun.ExchangePlanName);
		
	EndIf;
		
	// Getting the initialized data processor for exporting data.
	If DataExchangeCached.IsXDTOExchangePlan(ExchangePlanName) Then
		ProcessingOfAircraftDataExchange = ExternalConnection.DataProcessors.ConvertXTDOObjects.Create();
		ProcessingOfAircraftDataExchange.ExchangeMode = "Upload0";
	Else
		ProcessingOfAircraftDataExchange = ExternalConnection.DataProcessors.InfobaseObjectConversion.Create();
		ProcessingOfAircraftDataExchange.SavedSettings = ObjectsConversionRules;
		ProcessingOfAircraftDataExchange.DataImportExecutedInExternalConnection = False;
		ProcessingOfAircraftDataExchange.ExchangeMode = "Upload0";
		
		Try
			ProcessingOfAircraftDataExchange.RestoreRulesFromInternalFormat();
		Except
			
			ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo());
			ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataImport");
				
			Return False;
				
		EndTry;
		
		// Specify exchange nodes.
		ProcessingOfAircraftDataExchange.BackgroundExchangeNode = Undefined;
		ProcessingOfAircraftDataExchange.DontExportObjectsByRefs = True;
		ProcessingOfAircraftDataExchange.ExchangeRulesFileName = "1";
		ProcessingOfAircraftDataExchange.ExternalConnection = Undefined;
		
	EndIf;
	
	ProcessingOfAircraftDataExchange.NodeForExchange = StructureOfExchangeSettingsOfSun.InfobaseNode;
	If ProcessingOfAircraftDataExchange.Metadata().Attributes.Find("SetExchangePlanNodeLock") <> Undefined Then
		ProcessingOfAircraftDataExchange.SetExchangePlanNodeLock = True;
	EndIf;
	
	DataExchangeServer.SetCommonParametersForDataExchangeProcessing(ProcessingOfAircraftDataExchange, StructureOfExchangeSettingsOfSun, ExchangeWithSSL20);
			
	ProcessingOfAircraftDataExchange.ExchangeFileName = ExchangeMessage;
	ProcessingOfAircraftDataExchange.RunDataExport();
	StructureOfExchangeSettingsOfSun.ExchangeExecutionResultString = ProcessingOfAircraftDataExchange.ExchangeExecutionResultString();
	
	ExternalConnection.DataExchangeExternalConnection.WriteExchangeFinish(StructureOfExchangeSettingsOfSun);
	ExternalConnection = Undefined;
	
	Return True;
	
EndFunction

Function ExternalConnectionForSendingReceivingMessage(ActionOnExchange, StructureOfExchangeSettingsOfSun, ExchangeWithSSL20, MessageForDataMapping = False)
	
	ExternalConnection = EstablishExternalConnectionWithInfobase(ActionOnExchange);
	
	If ExternalConnection = Undefined Then
		Return False;
	EndIf;
	
	TransactionItemsCount = ItemsCountInTransactionOfActionToExecute(ActionOnExchange);
	
	// DATA EXCHANGE INITIALIZATION
	ExchangeSettingsStructure = ExchangeMessagesTransport.ExchangeSettingsForExternalConnection(
		Peer,
		ActionOnExchange,
		TransactionItemsCount);
	
	// Getting remote infobase version.
	SSLVersionByExternalConnection = ExternalConnection.StandardSubsystemsServer.LibraryVersion();
	ExchangeWithSSL20 = CommonClientServer.CompareVersions("2.1.1.10", SSLVersionByExternalConnection) > 0;
	
	Structure = New Structure("ExchangePlanName, CorrespondentExchangePlanName, 
		|CurrentExchangePlanNodeCode1, TransactionItemsCount");
	
	FillPropertyValues(Structure, ExchangeSettingsStructure);
	
	// Reversing enumeration values.
	ActionOnStringExchange = ?(ActionOnExchange = Enums.ActionsOnExchange.DataExport,
								Common.EnumerationValueName(Enums.ActionsOnExchange.DataImport),
								Common.EnumerationValueName(Enums.ActionsOnExchange.DataExport));
								
	Structure.Insert("ActionOnStringExchange", ActionOnStringExchange);
	Structure.Insert("DebugMode", False);
	Structure.Insert("ExchangeProtocolFileName", "");
	
	CorrespondentStructure = Common.CopyRecursive(Structure, False);
	CorrespondentStructure.ExchangePlanName = Structure.CorrespondentExchangePlanName;
	CorrespondentStructure.CorrespondentExchangePlanName = Structure.ExchangePlanName;
	
	Try
		// ExchangeSettingsStructureExternalConnection
		StructureOfExchangeSettingsOfSun = ExternalConnection.DataExchangeExternalConnection.ExchangeSettingsStructure(CorrespondentStructure);
	Except
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo());
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, ActionOnExchange);
		Return Undefined;
	EndTry;
	
	StructureOfExchangeSettingsOfSun.Insert("StartDate", ExternalConnection.CurrentSessionDate());
	
	Return ExternalConnection; 
	
EndFunction

Function EstablishExternalConnectionWithInfobase(ActionOnExchange = Undefined)
	
	AttemptNumber = 1;
	
	ParametersStructure = CommonClientServer.ParametersStructureForExternalConnection();
	FillPropertyValues(ParametersStructure, ThisObject);
	
	ExternalConnection = Undefined;
	
	While AttemptNumber <= 2 Do
		
		Connection = ExchangeMessagesTransportCached.EstablishExternalConnectionWithInfobase(ParametersStructure);
		ExternalConnection = Connection.Join;
		
		If ExternalConnection <> Undefined Then
			Return ExternalConnection;
		EndIf;
		
		If ExternalConnection = Undefined
			And Not Common.FileInfobase() Then
			
			ErrorMessage = Connection.BriefErrorDetails;
			ErrorMessageEventLog = Connection.DetailedErrorDetails;
			ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, ActionOnExchange);
			
			Break;
		
		EndIf;
		
		If AttemptNumber = 1 Then
			
			If Not RegisterCOMConnector() Then
				Break;
			EndIf;
			
		ElsIf AttemptNumber = 2 Then
			
			ErrorMessage = Connection.BriefErrorDetails;
			ErrorMessageEventLog = Connection.DetailedErrorDetails;
			ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, ActionOnExchange);
			
		EndIf;
		
		AttemptNumber = AttemptNumber + 1;
		
	EndDo;
	
	Return ExternalConnection; 
	
EndFunction

Function RegisterCOMConnector(ActionOnExchange = Undefined)
	
	ApplicationStartupParameters = FileSystem.ApplicationStartupParameters();
	ApplicationStartupParameters.WaitForCompletion = True;
	ApplicationStartupParameters.GetOutputStream = True;
	
	CommandText = StrTemplate("regsvr32.exe /n /i:user /s ""%1comcntr.dll""", BinDir());
	
	RunResult = FileSystem.StartApplication(CommandText, ApplicationStartupParameters);
		
	Template = 
		NStr("vi = 'Đã thực hiện ghi nhận lại cấu phần ""comcntr"" trên máy tính %1.
			|Lệnh: %2
			|Mã trả lại %3, thông báo:
			|%4';
			|ru = 'Выполнена перерегистрация компоненты ""comcntr"" на компьютере %1.
			|Команда: %2
			|Код возврата %3, сообщение:
			|%4';
			|en = 'The comcntr component is reregistered on computer %1.
			|Command: %2
			|Return code:%3, message:
			|%4'; fa = 'The comcntr component is reregistered on computer %1.
			|Command: %2
			|Return code:%3, message:
			|%4';
			|it = 'Выполнена перерегистрация компоненты ""comcntr"" на компьютере %1.
			|Команда: %2
			|Код возврата %3, сообщение:
			|%4';
			|pl = 'The comcntr component is reregistered on computer %1.
			|Command: %2
			|Return code:%3, message:
			|%4';
			|tr = '%1  bilgisayarındaki ""comcntr"" bileşeni yeniden kaydedildi.
			|Komut: %2
			|İade kodu %3, mesaj:
			|%4'");
	
	Comment = StrTemplate(Template, ComputerName(), CommandText, RunResult.ReturnCode, RunResult.OutputStream);
	
	IsError = RunResult.ReturnCode <> 0;
	
	ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, ActionOnExchange, Comment, IsError);
	
	Return RunResult.ReturnCode = 0;

EndFunction

Function CheckingExternalConnectionBeforeExchange(ActionOnExchange, MessageForDataMapping = False)
	
	ExternalConnection = EstablishExternalConnectionWithInfobase(ActionOnExchange);
	If ExternalConnection = Undefined Then
		Return False;
	EndIf;
	
	TransactionItemsCount = DataExchangeServer.ItemsCountInTransactionOfActionToExecute(ActionOnExchange);
	
	// DATA EXCHANGE INITIALIZATION
	ExchangeSettingsStructure = ExchangeMessagesTransport.ExchangeSettingsForExternalConnection(
		Peer,
		ActionOnExchange,
		TransactionItemsCount);
	
	// Getting remote infobase version.
	SSLVersionByExternalConnection = ExternalConnection.StandardSubsystemsServer.LibraryVersion();
	ExchangeWithSSL20 = CommonClientServer.CompareVersions("2.1.1.10", SSLVersionByExternalConnection) > 0;
	
	Structure = New Structure("ExchangePlanName, CorrespondentExchangePlanName, 
		|CurrentExchangePlanNodeCode1, TransactionItemsCount");
	
	FillPropertyValues(Structure, ExchangeSettingsStructure);
	
	// Reversing enumeration values.
	ActionOnStringExchange = ?(ActionOnExchange = Enums.ActionsOnExchange.DataExport,
								Common.EnumerationValueName(Enums.ActionsOnExchange.DataImport),
								Common.EnumerationValueName(Enums.ActionsOnExchange.DataExport));
								
	Structure.Insert("ActionOnStringExchange", ActionOnStringExchange);
	Structure.Insert("DebugMode", False);
	Structure.Insert("ExchangeProtocolFileName", "");
	
	If DataExchangeCached.IsXDTOExchangePlan(ExchangePlanName) Then
		// Checking a predefined node alias.
		PredefinedNodeAlias = DataExchangeServer.PredefinedNodeAlias(Peer);
		ExchangePlanManager = ExternalConnection.ExchangePlans[Structure.CorrespondentExchangePlanName];
		CheckNodeExistenceInCorrespondent = True;
		If ValueIsFilled(PredefinedNodeAlias) Then
			// Check if the node code in the peer infobase was changed.
			// If this is the case, the alias is not required.
			If ExchangePlanManager.FindByCode(PredefinedNodeAlias) <> ExchangePlanManager.EmptyRef() Then
				Structure.CurrentExchangePlanNodeCode1 = PredefinedNodeAlias;
				CheckNodeExistenceInCorrespondent = False;
			EndIf;
		EndIf;
		If CheckNodeExistenceInCorrespondent Then
			ExchangePlanRef = ExchangePlanManager.FindByCode(Structure.CurrentExchangePlanNodeCode1);
			If Not ValueIsFilled(ExchangePlanRef.Code) Then
				// If necessary, start migration to data synchronization via universal format.
				MessageText = NStr("vi = 'Cần chuyển sang đồng bộ dữ liệu thông qua định dạng đa năng trong cơ sở trao đổi tin.';
									|ru = 'Необходим переход на синхронизацию данных через универсальный формат в базе-корреспонденте.';
									|en = 'Switch the peer infobase to Interim Format Data Exchange.'; fa = 'Switch the peer infobase to Interim Format Data Exchange.';
									|it = 'È necessario un passaggio alla sincronizzazione dei dati tramite il formato universale nel database-corrispondente.';
									|pl = 'Switch the peer infobase to Interim Format Data Exchange.';
									|tr = 'Muhabir veritabanında genel bir format üzerinden veri senkronizasyonu için bir geçiş gereklidir.'");
				ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, ActionOnExchange, MessageText, False);

				ParametersStructure = New Structure();
				ParametersStructure.Insert("Code", Structure.CurrentExchangePlanNodeCode1);
				ParametersStructure.Insert("SettingsMode", 
					Common.ObjectAttributeValue(Peer, "SettingsMode"));
				ParametersStructure.Insert("Error", False);
				ParametersStructure.Insert("ErrorMessage", "");
				
				HasErrors = False;
				ErrorMessage = "";
				TransferResult = ExchangePlanManager.SwitchingToSynchronizationViaUniversalFormatExternalConnection(ParametersStructure);
				
				If ParametersStructure.Error Then
					
					HasErrors = True;
					
					MessageText = NStr("vi = 'Lỗi khi chuyển sang đồng bộ dữ liệu thông qua định dạng đa năng: %1. Đã hủy trao đổi.';
										|ru = 'Ошибка при переходе на синхронизацию данных через универсальный формат: %1. Обмен отменен.';
										|en = 'Error switching to Interim Format Data Exchange: %1. The exchange is canceled.'; fa = 'Error switching to Interim Format Data Exchange: %1. The exchange is canceled.';
										|it = 'Errore durante il passaggio alla sincronizzazione dei dati tramite il formato universale: %1. Lo scambio è stato annullato.';
										|pl = 'Error switching to Interim Format Data Exchange: %1. The exchange is canceled.';
										|tr = 'Genel biçim üzerinden veri senkronizasyonu geçiş yaparken bir hata oluştu:%1 . Veri alışverişi iptal edildi.'",
						Common.DefaultLanguageCode());
						
					ErrorMessage = StrTemplate(MessageText, ParametersStructure.ErrorMessage);
					
				ElsIf TransferResult = Undefined Then
					
					HasErrors = True;
					ErrorMessage = NStr("vi = 'Chưa chuyển sang đồng bộ dữ liệu thông qua định dạng đa năng';
										|ru = 'Переход на синхронизацию данных через универсальный формат не выполнен';
										|en = 'Switching to Interim Format Data Exchange failed'; fa = 'Switching to Interim Format Data Exchange failed';
										|it = 'La transizione alla sincronizzazione dei dati attraverso il formato universale non è stata completata';
										|pl = 'Przejście do synchronizacji danych za pomocą formatu uniwersalnego nie jest wykonane';
										|tr = 'Genel biçim üzerinden veri eşitlemeye geçiş başarısız oldu'");
					
				EndIf;
				
				If HasErrors Then
					ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, ActionOnExchange);
					Return False;
				Else
					MessageText = NStr("vi = 'Đã chuyển thành công sang đồng bộ dữ liệu thông qua định dạng đa năng.';
										|ru = 'Переход на синхронизацию данных через универсальный формат завершен успешно.';
										|en = 'Switching Interim Format Data Exchange completed.'; fa = 'Switching Interim Format Data Exchange completed.';
										|it = 'La transizione alla sincronizzazione dei dati attraverso il formato universale è stata completata con successo.';
										|pl = 'Przejście do synchronizacji danych za pomocą formatu uniwersalnego jest zakończone pomyślnie.';
										|tr = 'Genel biçim üzerinden veri eşitlemeye geçiş başarılı oldu.'");
					ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, ActionOnExchange, MessageText, False);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
		
	CorrespondentStructure = Common.CopyRecursive(Structure, False);
	CorrespondentStructure.ExchangePlanName = Structure.CorrespondentExchangePlanName;
	CorrespondentStructure.CorrespondentExchangePlanName = Structure.ExchangePlanName;
	
	Try
		// ExchangeSettingsStructureExternalConnection
		StructureOfExchangeSettingsOfSun = ExternalConnection.DataExchangeExternalConnection.ExchangeSettingsStructure(CorrespondentStructure);
	Except
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo());
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, ActionOnExchange);
		Return False;
	EndTry;
	
	If StructureOfExchangeSettingsOfSun.Property("DataSynchronizationSetupCompleted") Then
		If Not MessageForDataMapping
			And StructureOfExchangeSettingsOfSun.DataSynchronizationSetupCompleted = False Then
			
			MessageText = NStr("vi = 'Để tiếp tục, hãy chuyển sang chương trình ""%1"" và hoàn tất tùy chỉnh đồng bộ trong đó.
				|Đã hủy thực hiện trao đổi dữ liệu.';
				|ru = 'Для продолжения перейдите в программу ""%1"" и завершите в ней настройку синхронизации.
				|Выполнение обмена данными отменено.';
				|en = 'To continue, set up synchronization in ""%1"".
				|The data exchange is canceled.'; fa = 'To continue, set up synchronization in ""%1"".
				|The data exchange is canceled.';
				|it = 'Per continuare, passare al programma ""%1"" e completare l''impostazione di sincronizzazione.
				|Esecuzione scambio dati annullata.';
				|pl = 'Aby kontynuować przejdź do programu ""%1"" i zakończ w nim ustawienie synchronizacji.
				|Wykonanie wymiany danych zostało anulowane.';
				|tr = 'Devam etmek için ""%1"" programına geçin ve senkronizasyon ayarlarını tamamlayın.
				|Veri alışverişi iptal edildi.'");
			
			ErrorMessage = StrTemplate(MessageText, StructureOfExchangeSettingsOfSun.InfobaseNodeDescription);
			
			ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, ActionOnExchange);
			
			Return False;
			
		EndIf;
	EndIf;
	
	If StructureOfExchangeSettingsOfSun.Property("MessageReceivedForDataMapping") Then
		If Not MessageForDataMapping
			And StructureOfExchangeSettingsOfSun.MessageReceivedForDataMapping = True Then
			
			MessageText = NStr("vi = 'Để tiếp tục, hãy chuyển sang chương trình ""%1"" và thực hiện kết nhập thông điệp để so sánh dữ liệu.
				|Đã hủy thực hiện trao đổi dữ liệu.';
				|ru = 'Для продолжения перейдите в программу ""%1"" и выполните загрузку сообщения для сопоставления данных.
				|Выполнение обмена данными отменено.';
				|en = 'To continue, open %1 and import the data mapping message.
				|The data exchange is canceled.'; fa = 'To continue, open %1 and import the data mapping message.
				|The data exchange is canceled.';
				|it = 'Per continuare, passare al programma ""%1"" e scaricare il messaggio per il confronto dati.
				|Esecuzione scambio dati annullata.';
				|pl = 'Aby kontynuować przejdź do programu ""%1"" i wykonaj import wiadomości do porównania danych.
				|Wykonanie wymiany danych zostało anulowane.';
				|tr = 'Devam etmek için ""%1"" programına geçin ve veri eşleşmesi için mesajı indirin.
				|Veri alışverişi iptal edildi.'");
			
			ErrorMessage = StrTemplate(MessageText, StructureOfExchangeSettingsOfSun.InfobaseNodeDescription);
			ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, ActionOnExchange);
			
			Return False;
			
		EndIf;
	EndIf;
	
	If ActionOnExchange = Enums.ActionsOnExchange.DataImport
		And Not DataExchangeCached.IsXDTOExchangePlan(ExchangePlanName) Then
		
		// Getting exchange rules from the second infobase.
		ObjectsConversionRules = ExternalConnection.DataExchangeExternalConnection.GetObjectConversionRules(StructureOfExchangeSettingsOfSun.ExchangePlanName);
		
		If ObjectsConversionRules = Undefined Then
			
			// Exchange rules must be specified.
			
			MessageText = NStr("vi = 'Chưa đặt quy tắc chuyển đổi trong cơ sở thông tin thứ hai đối với sơ đồ trao đổi %1. Đã hủy trao đổi.';
								|ru = 'Не заданы правила конвертации во второй информационной базе для плана обмена %1. Обмен отменен.';
								|en = 'Conversion rules are not specified for exchange plan %1 in the second infobase. The exchange is canceled.'; fa = 'Conversion rules are not specified for exchange plan %1 in the second infobase. The exchange is canceled.';
								|it = 'Non sono state indicate le regole per la conversione nel secondo database per il piano di scambio %1. Scambio annullato.';
								|pl = 'Conversion rules are not specified for exchange plan %1 in the second infobase. The exchange is canceled.';
								|tr = '%1 değişim planının dönüşüm kuralları ikinci Infobase''de belirtilmedi. Değişim iptal edildi.'",
				Common.DefaultLanguageCode());
				
			ErrorMessage = StrTemplate(MessageText, StructureOfExchangeSettingsOfSun.ExchangePlanName);
			ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataImport");
			
			Return False;
			
		EndIf;
	EndIf;
		
	ExternalConnection.DataExchangeExternalConnection.WriteLogEventDataExchangeStart(StructureOfExchangeSettingsOfSun);
	ExternalConnection = Undefined;
	
	Return True;
	
EndFunction

Function ItemsCountInTransactionOfActionToExecute(Action)
	
	If Action = Enums.ActionsOnExchange.DataExport Then
		ItemCount = DataExchangeServer.DataExportTransactionItemsCount();
	Else
		ItemCount = DataExchangeServer.DataImportTransactionItemCount();
	EndIf;
	
	Return ItemCount;
	
EndFunction

#EndRegion

#Region Initialize

TempDirectory = Undefined;
MessagesOfExchange = Undefined;

#EndRegion

#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf