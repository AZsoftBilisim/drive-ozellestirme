///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Initialization parameters.
// 
// Parameters:
//  TransportID - String - Transport ID
// 
// Returns:
//  Structure - Initialization Parameters:
//   * Peer - ExchangePlanRef, Undefined - A reference to the exchange plan node
//   * ExchangePlanName - String 
//   * CorrespondentExchangePlanName - String
//   * TransportID - String
//   * TransportSettings - Structure - Composition repeats the attributes of the transport data processor
//   * AuthenticationData - Structure - Its composition repeats the attributes of the transport data processor. 
//   Includes only authentication details. For example, "Password" and "UserName".
//
Function InitializationParameters(TransportID = "") Export
	
	Parameters = New Structure;
	Parameters.Insert("Peer", Undefined);
	Parameters.Insert("ExchangePlanName", "");
	Parameters.Insert("CorrespondentExchangePlanName", "");
	Parameters.Insert("TransportID", TransportID);
	Parameters.Insert("TransportSettings", New Structure);
	Parameters.Insert("AuthenticationData", New Structure);
	
	Return Parameters;
	
EndFunction

// Initialize transport data processor.
// 
// Parameters:
//  InitializationParameters - Structure - Initialization Parameters:
//   * Peer - ExchangePlanRef - References to exchange plan node. If specified, 
//   the transport details (that is, data processor attributes) will be filled.
//   * ExchangePlanName - String 
//   * CorrespondentExchangePlanName - String
//   * TransportID - String - Available transport ID.
//   Available IDs See AvailableTransportTypes
//   * TransportSettings - Structure - Composition repeats the attributes of the transport data processor,
//   * AuthenticationData - Structure - Its composition repeats the attributes of the transport data processor. 
//   Includes only authentication details. For example, "Password" and "UserName".
//  CreateTemporaryDirectory - Boolean - If True, create a temporary directory
// 
// Returns:
//   DataProcessorObject.ExchangeMessageTransportCOM,
//   DataProcessorObject.ExchangeMessageTransportEMAIL,
//   DataProcessorObject.ExchangeMessagesTransportESB1C,
//   DataProcessorObject.ExchangeMessagesTransportFILE,
//   DataProcessorObject.ExchangeMessagesTransportFTP,
//   DataProcessorObject.ExchangeMessagesTransportGoogleDrive,
//   DataProcessorObject.ExchangeMessagesTransportHTTP,
//   DataProcessorObject.ExchangeMessagesTransportSM,
//   DataProcessorObject.ExchangeMessagesTransportWS,
//   DataProcessorObject.ExchangeMessagesTransportPassiveMode,
//   DataProcessorObject.ExchangeMessagesTransportYandexDisk - Handler for the given transport with the filled parameters.
//    During initialization, "TempDirectory" is created and a temp name for the "ExchangeMessage" file and 
//     filename templates ("NameTemplatesForReceivingMessage") are set
//  
Function Initialize(InitializationParameters, CreateTemporaryDirectory = True) Export
	
	Parameters = InitializationParameters();
	FillPropertyValues(Parameters, InitializationParameters);
	
	If ValueIsFilled(Parameters.TransportID) Then
		TransportID = Parameters.TransportID;
	ElsIf ValueIsFilled(Parameters.Peer) Then
		TransportID = DefaultTransport(Parameters.Peer);
	EndIf;
	
	Manager = TransportManagerById(TransportID);
	Transport = Manager.Create();
	
	If ValueIsFilled(Parameters.Peer) Then
		Transport.Peer = Parameters.Peer;
	ElsIf ValueIsFilled(Parameters.ExchangePlanName) Then
		Transport.Peer = ExchangePlans[Parameters.ExchangePlanName].EmptyRef();
	EndIf;
		
	If ValueIsFilled(Parameters.ExchangePlanName) Then
		Transport.ExchangePlanName = Parameters.ExchangePlanName;
	ElsIf ValueIsFilled(Parameters.Peer) Then
		Transport.ExchangePlanName = Parameters.Peer.Metadata().Name;
	EndIf;
	
	If ValueIsFilled(Parameters.CorrespondentExchangePlanName) Then
		Transport.CorrespondentExchangePlanName = Parameters.CorrespondentExchangePlanName;
	ElsIf ValueIsFilled(Parameters.Peer) Then
		Transport.CorrespondentExchangePlanName = DataExchangeCached.GetNameOfCorrespondentExchangePlan(Parameters.Peer);
	EndIf;
	
	If Not ValueIsFilled(Transport.CorrespondentExchangePlanName) Then
		Transport.CorrespondentExchangePlanName = Transport.ExchangePlanName;
	EndIf;
	
	If ValueIsFilled(Parameters.TransportSettings) Then
		TransportSettings = Parameters.TransportSettings;
	ElsIf ValueIsFilled(Parameters.Peer) Then;
		TransportSettings = TransportSettings(Parameters.Peer, TransportID);
	Else
		TransportSettings = New Structure;
	EndIf;
	
	FillPropertyValues(Transport, TransportSettings);
	FillInSettingsFromSecureStorage(Transport);
	
	If ValueIsFilled(Parameters.AuthenticationData) Then
		FillPropertyValues(Transport, Parameters.AuthenticationData);
	EndIf;
	
	If ValueIsFilled(Parameters.Peer) Then 
		FillInDefaultMessageNames(Transport);
	EndIf;
	
	If CreateTemporaryDirectory Then
		Transport.TempDirectory = TempExchangeMessagesDirectory(Transport);
	
		TempFileName = String(New UUID) + ".xml";
	
		Transport.ExchangeMessage = 
			CommonClientServer.GetFullFileName(Transport.TempDirectory, TempFileName);
	EndIf;
	
	Return Transport;
	
EndFunction

// Drop the transport processing, delete the temporary exchange directory 
// 
// Parameters:
//  Transport - DataProcessorObject.ExchangeMessageTransportCOM,
//            - DataProcessorObject.ExchangeMessageTransportEMAIL,
//            - DataProcessorObject.ExchangeMessageTransportESB1C,
//            - DataProcessorObject.ExchangeMessageTransportFILE,
//            - DataProcessorObject.ExchangeMessageTransportFTP,
//            - DataProcessorObject.ExchangeMessageTransportGoogleDrive,
//            - DataProcessorObject.ExchangeMessageTransportHTTP,
//            - DataProcessorObject.ExchangeMessageTransportSM,
//            - DataProcessorObject.ExchangeMessageTransportWS,
//            - DataProcessorObject.ExchangeMessageTransportPassiveMode,
//            - DataProcessorObject.ExchangeMessageTransportYandexDisk - Exchange message transport hander.
//
// Returns:
//  Boolean - "True" if succeeded, "False" if errors occurred.
//
Function Deinitialization(Transport) Export

	Try
		
		If Not IsBlankString(Transport.TempDirectory) Then
			DeleteFiles(Transport.TempDirectory);
		EndIf;
		
		If Not Transport.DirectoryID = Undefined Then
			DataExchangeServer.GetFileFromStorage(Transport.DirectoryID);
		EndIf;
		
		Transport = Undefined;
		
	Except
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

// Transport settings.
// 
// Parameters:
//  Peer - ExchangePlanRef - Peer infobase
//  TransportID - String - Transport ID
// 
// Returns:
//  Structure - Transport settings (transport handling attributes)
//
Function TransportSettings(Peer, TransportID) Export 
	
	Result = New Structure;
	
	Settings = Catalogs.ExchangeMessageTransportSettings.TransportSettings(
		Peer, TransportID);
		
	Manager = TransportManagerById(TransportID);
	Attributes = Manager.Create().Metadata().Attributes;
	
	For Each Attribute In Attributes Do
		Result.Insert(Attribute.Name, Attribute.Type.AdjustValue());
	EndDo;
		
	FillPropertyValues(Result, Settings);
	
	Return Result;
	
EndFunction

// Default transport settings.
// 
// Parameters:
//  Peer - ExchangePlanRef
//  TransportID - String - Returns the ID of the default transport
// 
// Returns:
//  Structure - Default transport settings (transport handling attributes)
//
Function DefaultTransportSettings(Peer, TransportID = "") Export
	
	Result = New Structure;
	
	Settings = Catalogs.ExchangeMessageTransportSettings.DefaultTransportSettings(
		Peer, TransportID);
		
	If Not ValueIsFilled(TransportID) Then
		Return Result;
	EndIf;
		
	Manager = TransportManagerById(TransportID);
	Attributes = Manager.Create().Metadata().Attributes;
	
	For Each Attribute In Attributes Do
		Result.Insert(Attribute.Name, Attribute.Type.AdjustValue());
	EndDo;
		
	FillPropertyValues(Result, Settings);
	
	Return Result;

EndFunction

// Transport parameters (transport handler).
// 
// Parameters:
//  TransportID - String - Transport ID
// 
// Returns:
//   Undefined,
//   Structure - See ExchangeMessagesTransport.StructureOfTransportParameters
//
Function TransportParameters(Val TransportID) Export
	
	If Not ValueIsFilled(TransportID) Then
		Return Undefined;
	EndIf;
	
	If TypeOf(TransportID) <> Type("String") Then
		TransportID = DefaultTransport(TransportID);
	EndIf;
	
	Return TransportManagerById(TransportID).TransportParameters();
	
EndFunction

// Transport settings (transport handler).
// 
// Parameters:
//  TransportID - String - Transport ID
//  ParameterName - String - Transport parameter name. List of parameters See StructureOfTransportParameters
// 
// Returns:
//  Arbitrary
//
Function TransportParameter(Val TransportID, ParameterName) Export
	
	If Not ValueIsFilled(TransportID) Then
		Return Undefined;
	EndIf;
	
	If TypeOf(TransportID) <> Type("String") Then
		TransportID = DefaultTransport(TransportID);
	EndIf;
	
	Parameters = TransportParameters(TransportID);
	Return Parameters[ParameterName];
	
EndFunction

// A structure with transport parameters.
// 
// Returns:
//  Structure - A structure with transport parameters:
//   * Alias - String - Brief transport presentation
//   * TransportID - String
//   * LongDesc - String - Transport detailed description.
//   * NameOfConfigurationForm - String - The name of the form for the set up transport
//   * NameOfFirstSetupForm - String - The name of the form used for the initial synchronization.
//   * NameOfAuthenticationForm - String - The name of the form used to input authentication data
//   * AttributesForSecureStorage - Array of String - A list of attributes that
//   are put to the safe storage when saving the transport settings
//   * StartDataExchangeFromCorrespondent - Boolean - Flag indicating that the synchronization can be run in the peer infobase
//   * UseProgress - Boolean - Flag indicating whether the progress bar is displayed during a data exchange.
//   If "True", use it for offline exchanges. If "False", use it for online exchanges.
//   * SaveConnectionParametersToFile - Boolean -
//   * ApplicationOperationMode - Number - Only affects the icon in the list of the "DataSyncSettings" form.
//   Valid values are 0 and 1. "0"  - An exchange over ordinary channels (FILE, FTP, etc.). "1" - Application in a service.
//   * Picture - Picture - The transport icon displayed in choice lists
//   * DirectConnection - Boolean - If "True", there's a direct connection with the infobase (COM, WS, or HTTP)
//   * PassiveMode - Boolean - If "True", this is a stub transport.
//   Stub transports don't support data initialization.
//   It is intended to be used with WS and HTTP
//   * SettingUpSubAssetInCorrespondent - Boolean - 
//   "True" if the transport should be fine-tuned in the peer infobase during a synchronization.
//   Otherwise, "False"
//
Function StructureOfTransportParameters() Export
	
	Parameters = New Structure;
	
	Parameters.Insert("Alias", "");
	Parameters.Insert("TransportID", "");
	Parameters.Insert("LongDesc", "");
	Parameters.Insert("NameOfConfigurationForm", "FormSettings");
	Parameters.Insert("NameOfFirstSetupForm", "FormSettings");
	Parameters.Insert("NameOfAuthenticationForm", "AuthenticationForm");
	Parameters.Insert("AttributesForSecureStorage", New Array);
	Parameters.Insert("StartDataExchangeFromCorrespondent", True);
	Parameters.Insert("UseProgress", True);
	Parameters.Insert("SaveConnectionParametersToFile", True);
	Parameters.Insert("ApplicationOperationMode", 0); 
	Parameters.Insert("Picture", PictureLib.TransportDataTransfer);
	
	// For online exchange
	Parameters.Insert("DirectConnection", False);
	Parameters.Insert("PassiveMode", False);
	
	Parameters.Insert("SettingUpSubAssetInCorrespondent", False);
	
	Return Parameters;
	
EndFunction

// Structure for validating received transport parameters.
// 
// Returns:
//  Structure - Structure for validating received transport parameters.:
//   * ConnectionIsSet - Boolean - Connection verified.
//   * ConnectionAllowed - Boolean - Has permission to use the specified type of transport.
//   * InterfaceVersions - Undefined, 
//                        String - Used for versioned transport types, for example, WEB or HTTP.
//   * ErrorMessage - String - Connection error text.
//   * CorrespondentParametersReceived - Boolean - Received a response with the peer infobase parameters.
//   * CorrespondentParameters - Undefined,
//                               String - XML string with the peer infobase parameters.
//   * CorrespondentExchangePlanName - String - Name of the exchange plan in the peer infobase.
//   * ThisNodeExistsInPeerInfobase - Boolean - Indicates whether the peer infobase has a setting with the current infobase. 
//   * ThisInfobaseHasPeerInfobaseNode - Boolean - Indicates whether the infobase has a setting with the peer infobase.
//   * NodeToDelete - Undefined,
//                       ExchangePlanRef - Exchange node to delete.
//
Function StructureOfResultOfObtainingParametersOfCorrespondent() Export
	
	Result = New Structure;
	Result.Insert("ConnectionIsSet", False);
	Result.Insert("ConnectionAllowed", False);
	Result.Insert("InterfaceVersions", Undefined);
	Result.Insert("ErrorMessage", "");
	
	Result.Insert("CorrespondentParametersReceived", False);
	Result.Insert("CorrespondentParameters", Undefined);
	Result.Insert("CorrespondentExchangePlanName", "");

	// Synchronization settings duplication check (sync is already set up)
	Result.Insert("ThisNodeExistsInPeerInfobase", False);
	Result.Insert("ThisInfobaseHasPeerInfobaseNode", False);
	Result.Insert("NodeToDelete", Undefined);
	
	Return Result;
	
EndFunction

// Default transport.
// 
// Parameters:
//  Peer - ExchangePlanRef - Peer infobase
// 
// Returns:
//  String - Transport ID
//  
Function DefaultTransport(Peer) Export
	
	Return Catalogs.ExchangeMessageTransportSettings.DefaultTransport(Peer);
		
EndFunction

// Delete all settings for the transport.
// 
// Parameters:
//  Peer - ExchangePlanRef - Exchange plan node being deleted
//
Procedure DeleteAllTransportSettings(Peer) Export
	
	Catalogs.ExchangeMessageTransportSettings.DeleteAllSettings(Peer);

EndProcedure

#Region ManagersOfTypicalTransportTreatments

// Returns a transport handler by ID.
// 
// Parameters:
//  TransportID - String - Transport ID
// 
// Returns:
//  Arbitrary - Transport handling manager
Function TransportManagerById(TransportID) Export
	
	Managers = TransportManagersById();
	
	Return Managers.Get(TransportID); 
	
EndFunction

// Returns the handler manager for the FILE transport.
// 
// Returns:
//  DataProcessorManager.ExchangeMessageTransportFILE
//
Function TransportManagerFILE() Export
	
	Return DataProcessors.ExchangeMessageTransportFILE;
	
EndFunction

// Returns the handler manager for the COM transport.
// 
// Returns:
//  DataProcessorManager.ExchangeMessageTransportCOM
//
Function TransportManagerCOM() Export
	
	Return DataProcessors.ExchangeMessageTransportCOM;
	
EndFunction

// Returns the handler manager for the EMAIL transport.
// 
// Returns:
//  DataProcessorManager.ExchangeMessageTransportEMAIL
//
Function TransportManagerEMAIL() Export
	
	Return DataProcessors.ExchangeMessageTransportEMAIL;
	
EndFunction

// Returns the handler manager for the FTP transport.
// 
// Returns:
//  DataProcessorManager.ExchangeMessageTransportFTP
//
Function TransportManagerFTP() Export
	
	Return DataProcessors.ExchangeMessageTransportFTP;
	
EndFunction

// Returns the handler manager for the HTTP transport.
// 
// Returns:
//  DataProcessorManager.ExchangeMessageTransportHTTP
//
Function TransportManagerHTTP() Export
	
	Return DataProcessors.ExchangeMessageTransportHTTP;
	
EndFunction

// Returns the handler manager for the WS transport.
// 
// Returns:
//  DataProcessorManager.ExchangeMessageTransportWS
//
Function TransportManagerWS() Export
	
	Return DataProcessors.ExchangeMessageTransportWS;
	
EndFunction

// Returns the handler manager for the SM transport.
// 
// Returns:
//  DataProcessorManager.ExchangeMessageTransportSM
//
Function TransportManagerSM() Export
	
	Return DataProcessors.ExchangeMessageTransportSM;
	
EndFunction

// Returns the handler manager for the PassiveMode transport.
// 
// Returns:
//  DataProcessorManager.ExchangeMessageTransportPassiveMode
//
Function TransportManagerPassiveMode() Export
	
	Return DataProcessors.ExchangeMessageTransportPassiveMode;
	
EndFunction

// Returns the handler manager for the ESB1C transport.
// 
// Returns:
//  DataProcessorManager.ExchangeMessageTransportESB1C
//
Function TransportManagerESB1C() Export
	
	Return DataProcessors.ExchangeMessageTransportESB1C;
	
EndFunction

// Returns the handler manager for the GoogleDrive transport.
// 
// Returns:
//  DataProcessorManager.ExchangeMessageTransportGoogleDrive
//
Function TransportManagerGoogleDrive() Export
	
	Return DataProcessors.ExchangeMessageTransportGoogleDrive;
	
EndFunction

// Returns the handler manager for the YandexDisk transport.
// 
// Returns:
//  DataProcessorManager.ExchangeMessageTransportYandexDisk
//
Function YandexDiskTransportManager() Export
	
	Return DataProcessors.ExchangeMessageTransportYandexDisk;
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

Function AvailableTransportTypes(Peer, Val SettingsMode = "") Export
	
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(Peer);
	
	If Not Peer.IsEmpty() Then
		SettingsMode = DataExchangeServer.SavedExchangePlanNodeSettingOption(Peer);
	EndIf;
	
	SettingOptionDetails = DataExchangeCached.SettingOptionDetails(ExchangePlanName,  
		SettingsMode, "", "");
		
	Result = SettingOptionDetails.UsedExchangeMessagesTransports;
	
	If Result.Count() = 0 Then
		Result = AllTypesOfTransport();
	EndIf;
	
	// Intended for backward compatibility
	For IndexOf = 0 To Result.UBound() Do
		
		Transport = Result[IndexOf];
		
		If Transport = Enums.ExchangeMessagesTransportTypes.COM Then
			Result[IndexOf] = DataProcessors.ExchangeMessageTransportCOM;
		ElsIf Transport = Enums.ExchangeMessagesTransportTypes.EMAIL Then
			Result[IndexOf] = DataProcessors.ExchangeMessageTransportEMAIL;
		ElsIf Transport = Enums.ExchangeMessagesTransportTypes.FILE Then
			Result[IndexOf] = DataProcessors.ExchangeMessageTransportFILE;
		ElsIf Transport = Enums.ExchangeMessagesTransportTypes.FTP Then
			Result[IndexOf] = DataProcessors.ExchangeMessageTransportFTP;
		ElsIf Transport = Enums.ExchangeMessagesTransportTypes.WS Then
			Result[IndexOf] = DataProcessors.ExchangeMessageTransportWS;
		ElsIf Transport = Enums.ExchangeMessagesTransportTypes.WSPassiveMode Then
			Result[IndexOf] = DataProcessors.ExchangeMessageTransportPassiveMode;	
		EndIf;
		
	EndDo;
		
	// Data exchange over COM connections is not supported by:
	//  - Configurations with the basic license
	//  - Distributed infobases
	//  - Exchange without conversion rules
	//  - 1C:Enterprise servers that run on Linux
	//
	If StandardSubsystemsServer.IsBaseConfigurationVersion()
		Or DataExchangeCached.IsDistributedInfobaseExchangePlan(ExchangePlanName)
		Or DataExchangeCached.IsStandardDataExchangeNode(ExchangePlanName)
		Or Common.IsLinuxServer() Then
		
		CommonClientServer.DeleteValueFromArray(Result, DataProcessors.ExchangeMessageTransportCOM);
	
	EndIf;

	// Data exchange over 1C:Bus is not supported by:
	//  - Configurations with the basic license
	//  - Distributed infobases
	//  - Exchange without conversion rules
// 
	//
	If StandardSubsystemsServer.IsBaseConfigurationVersion()
		Or DataExchangeCached.IsDistributedInfobaseExchangePlan(ExchangePlanName)
		Or DataExchangeCached.IsStandardDataExchangeNode(ExchangePlanName) Then
		
		CommonClientServer.DeleteValueFromArray(Result, DataProcessors.ExchangeMessageTransportESB1C);
	
	EndIf;
			
	// Data exchange over WS connections is not supported by:
	//  - Distributed infobases that are not a standalone workstation
	//
	If DataExchangeCached.IsDistributedInfobaseExchangePlan(ExchangePlanName)
		And Not DataExchangeCached.IsStandaloneWorkstationNode(Peer) Then
		
		CommonClientServer.DeleteValueFromArray(Result, DataProcessors.ExchangeMessageTransportWS);
		CommonClientServer.DeleteValueFromArray(Result, DataProcessors.ExchangeMessageTransportHTTP);
		CommonClientServer.DeleteValueFromArray(Result, DataProcessors.ExchangeMessageTransportPassiveMode);
		CommonClientServer.DeleteValueFromArray(Result, DataProcessors.ExchangeMessageTransportESB1C);
		
	EndIf;
		
	// Data exchange over email is not supported when:
	//  - "Email management" subsystem is unavailable
	//  - The configuration cannot receive email messages
	If Common.SubsystemExists("StandardSubsystems.EmailOperations") Then
		ModuleEmailOperationsInternal = Common.CommonModule("EmailOperationsInternal");
		If Not ModuleEmailOperationsInternal.CanReceiveEmails() Then
			CommonClientServer.DeleteValueFromArray(Result,
				DataProcessors.ExchangeMessageTransportEMAIL);
		EndIf;
	Else
		CommonClientServer.DeleteValueFromArray(Result,
			DataProcessors.ExchangeMessageTransportEMAIL);
	EndIf;
		
	If Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable() Then
		
		CommonClientServer.DeleteValueFromArray(Result, DataProcessors.ExchangeMessageTransportYandexDisk);
		CommonClientServer.DeleteValueFromArray(Result, DataProcessors.ExchangeMessageTransportGoogleDrive);
		CommonClientServer.DeleteValueFromArray(Result, DataProcessors.ExchangeMessageTransportCOM);
		CommonClientServer.DeleteValueFromArray(Result, DataProcessors.ExchangeMessageTransportEMAIL);
		CommonClientServer.DeleteValueFromArray(Result, DataProcessors.ExchangeMessageTransportFILE);
		CommonClientServer.DeleteValueFromArray(Result, DataProcessors.ExchangeMessageTransportFTP);	
		CommonClientServer.DeleteValueFromArray(Result, DataProcessors.ExchangeMessageTransportESB1C);
		
	Else
		
		CommonClientServer.DeleteValueFromArray(Result, DataProcessors.ExchangeMessageTransportSM);
		
	EndIf;
	
	ExchangeMessagesTransportOverridable.WhenDeterminingAvailableTransportTypes(
		Result, Peer, SettingsMode);
	
	Return Result;
	
EndFunction

Function ConnectionSettingsInXML(ConnectionSettings) Export
	
	Manager = TransportManagerById(ConnectionSettings.TransportID);
	Return Manager.ConnectionSettingsInXML(ConnectionSettings);
	
EndFunction

Function ConnectionSettingsINJSON(ConnectionSettings) Export
	
	JSONConnectionSettings = ConnectionSettingsINJSONGeneral(ConnectionSettings);
	
	If ValueIsFilled(ConnectionSettings.TransportID) Then
		
		Manager = TransportManagerById(ConnectionSettings.TransportID);
		TransportSettings = Manager.TransportSettingsINJSON(ConnectionSettings.TransportSettings);
		
	Else
		
		TransportSettings = New Structure;
		
	EndIf;
	
	JSONConnectionSettings.Insert("TransportSettings", TransportSettings);
	
	Return ValueToJSON(JSONConnectionSettings);
	
EndFunction

Function ConnectionSettingsFromXML(XMLText, TransportID = "") Export
	
	If Not ValueIsFilled(TransportID) Then
		
		XMLReader = New XMLReader;
		XMLReader.SetString(XMLText);
		Factory = XDTOFactory.ReadXML(XMLReader);
		
		If Factory.Properties().Get("MainExchangeParameters") <> Undefined Then
			TransportID = Factory.MainExchangeParameters.ExchangeMessagesTransportKind;
		EndIf;
		
	EndIf;
	
	Manager = TransportManagerById(TransportID);
	ConnectionSettings = Manager.ConnectionSettingsFromXML(XMLText);
	
	Return ConnectionSettings;
	
EndFunction

Function ConnectionSettingsFromJSON(JSONText, TransportID = "") Export

	ConnectionSettingsFromFile = JSONValue(JSONText, False);
	
	ConnectionSettings = New Structure;
	TransportID = "";
	
	If ConnectionSettingsFromFile.Property("MainExchangeParameters") Then
		
		MainParameters = ConnectionSettingsFromFile.MainExchangeParameters;
		
		ConnectionSettings.Insert("FormatVersion", MainParameters.FormatVersion);
		ConnectionSettings.Insert("SourceInfobasePrefix", MainParameters.DestinationInfobasePrefix);
		ConnectionSettings.Insert("DestinationInfobasePrefix", MainParameters.SourceInfobasePrefix);
		ConnectionSettings.Insert("NodeCode", MainParameters.CorrespondentNodeCode);
		ConnectionSettings.Insert("CorrespondentNodeCode", MainParameters.NodeCode);
		
		ConnectionSettings.Insert("PredefinedNodeCode", MainParameters.CorrespondentNodeCode);
		ConnectionSettings.Insert("SecondInfobaseNewNodeCode", MainParameters.NodeCode);
		
		ConnectionSettings.Insert("ExchangePlanName", MainParameters.CorrespondentExchangePlanName);
		ConnectionSettings.Insert("CorrespondentExchangePlanName", MainParameters.ExchangePlanName);
		
		ConnectionSettings.Insert("SecondInfobaseDescription", MainParameters.ThisInfobaseDescription);
		ConnectionSettings.Insert("ThisInfobaseDescription", MainParameters.SecondInfobaseDescription);
		ConnectionSettings.Insert("TransportID", MainParameters.TransportID);
		ConnectionSettings.Insert("ExchangeSetupOption", MainParameters.ExchangeSetupOption);
		ConnectionSettings.Insert("SentNo", MainParameters.SentNo);
		ConnectionSettings.Insert("ReceivedNo", MainParameters.ReceivedNo);
		
		TransportID = MainParameters.TransportID;
		
	EndIf;
	
	If ValueIsFilled(TransportID)
		And ConnectionSettingsFromFile.Property("TransportSettings") Then
				
		Manager = TransportManagerById(TransportID);
		TransportSettings = Manager.TransportSettingsFromJSON(ConnectionSettingsFromFile.TransportSettings);
		
	Else
		
		TransportSettings = New Structure;
		
	EndIf;
	
	ConnectionSettings.Insert("TransportSettings", TransportSettings);
	
	// XDTOExchangeParameters
	If ConnectionSettingsFromFile.Property("XDTOExchangeParameters") Then
		XDTOExchangeParameters = ConnectionSettingsFromFile.XDTOExchangeParameters; 
		ConnectionSettings.Insert("ExchangeFormat", XDTOExchangeParameters.ExchangeFormat);
	EndIf;
	
	If ConnectionSettingsFromFile.Property("SupportedObjectsInFormat") Then
		
		FormatObjects = TableFromArray_SupportedObjectsInFormat(
			ConnectionSettingsFromFile.SupportedObjectsInFormat,
			MainParameters.ExchangeFormatVersions);
		
		Storage = New ValueStorage(FormatObjects);
		ConnectionSettings.Insert("SupportedObjectsInFormat", Storage);
		
	EndIf;
	
	Return ConnectionSettings;

EndFunction

Function NameOfFolderWhereSettingsAreSaved(ConnectionSettings) Export

	Manager = TransportManagerById(ConnectionSettings.TransportID);
	Return Manager.NameOfFolderWhereSettingsAreSaved(ConnectionSettings);
	
EndFunction

Procedure CheckAndFillInXMLConnectionSettings(
	ConnectionSettings, ConnectionSettingsFromFile, IsOnlineConnection = False, ErrorMessage = "") Export
	
	CorrectSettingsFile = False;
	ExchangePlanNameInSettings = "";
	
	If ConnectionSettingsFromFile.Property("ExchangePlanName", ExchangePlanNameInSettings)
		And ConnectionSettingsFromFile.ExchangePlanName = ConnectionSettings.ExchangePlanName Then
		
		CorrectSettingsFile = True;
		
	ElsIf DataExchangeCached.IsXDTOExchangePlan(ConnectionSettings.ExchangePlanName) Then 
		
		// Do not verify the exchange plan name for the default exchange plan
		CorrectSettingsFile = True;
		
	EndIf;
	
	If Not CorrectSettingsFile Then
		
		Template = NStr("vi = 'Tệp không chứa tùy chỉnh kết nối cho trao đổi dữ liệu đã chọn.
			|Đã chọn trao đổi ""%1"".
			|Trong tệp đã chỉ ra tùy chỉnh cho trao đổi ""%2"".';
			|ru = 'Файл не содержит настроек подключения для выбранного обмена данными.
			|Выбран обмен ""%1"".
			|В файле указаны настройки для обмена ""%2"".';
			|en = 'The file does not contain connection settings for the selected data exchange.
			|Exchange ""%1"" is selected,
			|while the file contains settings for exchange ""%2"".'; fa = 'The file does not contain connection settings for the selected data exchange.
			|Exchange ""%1"" is selected,
			|while the file contains settings for exchange ""%2"".';
			|it = 'Il file non contiene le configurazioni di connessione per lo scambio dei dati selezionato.
			|È selezionato scambio ""%1"".
			|Le impostazioni di scambio"" %2""sono specificate nel file.';
			|pl = 'Plik nie zawiera ustawień połączenia dla wybranej wymiany danych.
			|Wybrana wymiana ""%1"".
			|W pliku są określone ustawienia do wymiany ""%2"".';
			|tr = 'Dosya seçilen veri paylaşımı için bağlantı ayarlarını içermez. 
			| ""%1"" veri alışverişi seçildi. 
			|Dosyada, ""%2"" paylaşımı için ayarlar belirtilmiştir.'");
		
		ErrorMessage = StrTemplate(Template, ConnectionSettings.ExchangePlanName, ExchangePlanNameInSettings);
		
		Return;
		
	EndIf;
	
	If Not ValueIsFilled(ConnectionSettings.CorrespondentExchangePlanName) Then
		ConnectionSettings.CorrespondentExchangePlanName = ConnectionSettingsFromFile.ExchangePlanName;
	EndIf;
	
	FillPropertyValues(ConnectionSettings, ConnectionSettingsFromFile, , "ExchangePlanName, SourceInfobasePrefix");
	
	NumberSentFromConnectionSettings = Undefined;
	
	If CommonClientServer.HasAttributeOrObjectProperty(ConnectionSettings, "SentNo") Then
		NumberSentFromConnectionSettings = ConnectionSettings.SentNo;
	EndIf;
	
	NumberReceivedFromConnectionSettings = Undefined;
	
	If CommonClientServer.HasAttributeOrObjectProperty(ConnectionSettings, "ReceivedNo") Then
		NumberReceivedFromConnectionSettings = ConnectionSettings.ReceivedNo;
	EndIf;
	
	If StrLen(ConnectionSettings.SecondInfobaseNewNodeCode) = 36
		And StrLen(ConnectionSettings.PredefinedNodeCode) = 36
		And ValueIsFilled(NumberSentFromConnectionSettings)
		And ValueIsFilled(NumberReceivedFromConnectionSettings) Then
		
		If ExchangePlans[ConnectionSettings.ExchangePlanName].ThisNode().Code <> ConnectionSettings.PredefinedNodeCode
			And DataExchangeCached.ExchangePlanNodes(ConnectionSettings.ExchangePlanName).Count() > 0 Then
			ConnectionSettings.RestoreExchangeSettings = "RestoreWithWarning";
		Else
			ConnectionSettings.RestoreExchangeSettings = "Restoring";
		EndIf;
		
	EndIf;
	
	If Not IsOnlineConnection
		Or Not ValueIsFilled(ConnectionSettings.UsePrefixesForExchangeSettings) Then
		
		EmptyRefOfExchangePlan = ExchangePlans[ConnectionSettings.ExchangePlanName].EmptyRef();
		
		ConnectionSettings.UsePrefixesForExchangeSettings = 
			Not DataExchangeCached.IsXDTOExchangePlan(ConnectionSettings.ExchangePlanName)
				Or Not DataExchangeXDTOServer.VersionWithDataExchangeIDSupported(EmptyRefOfExchangePlan);
		
	EndIf;
	
	If Not IsOnlineConnection Then
		SecondInfobaseNewNodeCode = Undefined;
		ConnectionSettingsFromFile.Property("SecondInfobaseNewNodeCode", SecondInfobaseNewNodeCode);
		
		ConnectionSettings.UsePrefixesForCorrespondentExchangeSettings =
			ConnectionSettings.UsePrefixesForCorrespondentExchangeSettings
				Or (ConnectionSettings.WizardRunOption = "ContinueDataExchangeSetup"
					And DataExchangeCached.IsXDTOExchangePlan(ConnectionSettings.ExchangePlanName)
					And ValueIsFilled(SecondInfobaseNewNodeCode)
					And StrLen(SecondInfobaseNewNodeCode) <> 36);
	EndIf;
			
	If Not ConnectionSettings.UsePrefixesForExchangeSettings
		And Not ConnectionSettings.UsePrefixesForCorrespondentExchangeSettings Then
		
		ConnectionSettingsFromFile.Property("PredefinedNodeCode", ConnectionSettings.SourceInfobaseID);
		ConnectionSettingsFromFile.Property("SecondInfobaseNewNodeCode",  ConnectionSettings.DestinationInfobaseID);
		
	Else
		
		ConnectionSettingsFromFile.Property("SourceInfobasePrefix", ConnectionSettings.SourceInfobasePrefix);
		ConnectionSettingsFromFile.Property("SecondInfobaseNewNodeCode",            ConnectionSettings.DestinationInfobasePrefix);
		
	EndIf;
	
	If ConnectionSettings.WizardRunOption = "ContinueDataExchangeSetup"
		And (ConnectionSettings.UsePrefixesForExchangeSettings
			Or ConnectionSettings.UsePrefixesForCorrespondentExchangeSettings) Then
		
		IBPrefix = GetFunctionalOption("InfobasePrefix");
		If Not IsBlankString(IBPrefix)
			And IBPrefix <> ConnectionSettings.SourceInfobasePrefix Then
			
			Template = NStr("vi = 'Tiền tố chương trình đã chỉ ra khi tùy chỉnh (""%1""), không tương ứng với tiền tố trong chương trình này (""%2"").
				|Để tiếp tục, cần bắt đầu tùy chỉnh mới từ chương trình khác và chỉ ra tiền tố chính xác (""%2"").';
				|ru = 'Префикс программы, указанный при настройке (""%1""), не соответствует префиксу в этой программе (""%2"").
				|Для продолжения начните настройку заново из другой программы, и укажите корректный префикс (""%2"").';
				|en = 'The application prefix specified during setup (""%1"") does not match the prefix in this application (""%2"").
				|To continue, start the setup from another application and specify the correct prefix (""%2"").'; fa = 'The application prefix specified during setup (""%1"") does not match the prefix in this application (""%2"").
				|To continue, start the setup from another application and specify the correct prefix (""%2"").';
				|it = 'Il prefisso del programma indicato nell''impostazione (""%1"") non corrisponde al prefisso in questo programma (""%2"").
				|Per continuare, avviare l''impostazione nuovamente da un altro programma e indicare il prefisso corretto (""%2"").';
				|pl = 'Prefiks programu, wskazany przy ustawieniu (""%1""), nie jest zgodny z prefiksem w tym programie (""%2"").
				|Aby kontynuować zacznij ustawienie od nowa z innego programu, i podaj poprawny prefiks (""%2"").';
				|tr = 'Yapılandırılma esnasında belirtilen program öneki (""%1""), bu programdaki ( ""%2"" ) önek ile eşleşmiyor. 
				|Devam etmek için başka bir programdan yeniden yapılandırmaya başlayın ve doğru önek (""%2"" ) belirtin.'");
			
			ErrorMessage = StrTemplate(Template, ConnectionSettings.SourceInfobasePrefix, IBPrefix);
			
			Return;
			
		EndIf;
		
	EndIf;
	
	// Supporting the exchange settings file of the 1.0 version format.
	If ConnectionSettings.ExchangeDataSettingsFileFormatVersion = "1.0" Then
		
		ConnectionSettings.ThisInfobaseDescription    = NStr("vi = 'Cơ sở thông tin này';
															|ru = 'Эта информационная база';
															|en = 'This infobase'; fa = 'This infobase';
															|it = 'Questo database';
															|pl = 'Ta baza informacyjna';
															|tr = 'Bu infobase'");
		ConnectionSettingsFromFile.Property("DataExchangeExecutionSettingsDescription", ConnectionSettings.SecondInfobaseDescription);
		ConnectionSettingsFromFile.Property("NewNodeCode", ConnectionSettings.SecondInfobaseNewNodeCode);
		
	EndIf;
	
	//
	AttributesForSecureStorage = TransportParameter(
		ConnectionSettings.TransportID, "AttributesForSecureStorage");
		
	TransportSettings = ConnectionSettings.TransportSettings;
		
	SetPrivilegedMode(True);
	
	For Each Attribute In AttributesForSecureStorage Do
		
		Value = TransportSettings[Attribute];
		
		If ValueIsFilled(Value) Then
			
			Value_ID = String(New UUID);
			Common.WriteDataToSecureStorage(Value_ID, Value);
			TransportSettings[Attribute] = Value_ID;
			
		EndIf;
	
	EndDo;
	
	ConnectionSettings.WizardRunOption = "ContinueDataExchangeSetup";
	
	SetPrivilegedMode(False);

EndProcedure

Function ConfiguredTransportTypes(Peer) Export
	
	Return Catalogs.ExchangeMessageTransportSettings.ConfiguredTransportTypes(Peer);
	
EndFunction

Function TableOfTransportParameters(Peer = Undefined, SettingsMode = "") Export
	
	Table = New ValueTable;
	Table.Columns.Add("Transport");
	Table.Columns.Add("FullNameOfTransportProcessing");
	
	For Each KeyAndValue In StructureOfTransportParameters() Do
		Table.Columns.Add(KeyAndValue.Key);
	EndDo;
	
	If Peer = Undefined Then
		TypesOfTransport = AllTypesOfTransport();
	Else
		TypesOfTransport = AvailableTransportTypes(Peer, SettingsMode);
	EndIf;
	
	For Each Transport In TypesOfTransport Do
		
		Parameters = Transport.TransportParameters();
		
		If Table.Find(Parameters.TransportID, "TransportID") <> Undefined Then
			Continue;
		EndIf;
		
		NewRow = Table.Add();
		NewRow.Transport = Transport;
		NewRow.FullNameOfTransportProcessing = Transport.Create().Metadata().FullName();
		FillPropertyValues(NewRow, Parameters);
		
		If Not ValueIsFilled(NewRow.Alias) Then
			NewRow.Alias = NewRow.TransportID;
		EndIf;
		
	EndDo;
	
	Return Table;
	
EndFunction

Procedure SaveTransportSettings(Peer, TransportID, TransportSettings, DefaultSetting = Undefined) Export
	
	RecordStructure = New Structure();
	RecordStructure.Insert("Peer", Peer);
	RecordStructure.Insert("TransportID", TransportID);
	RecordStructure.Insert("Settings", TransportSettings);
	
	If DefaultSetting <> Undefined Then
		RecordStructure.Insert("DefaultSetting", DefaultSetting);
	EndIf;
	
	Catalogs.ExchangeMessageTransportSettings.UpdateSettings2(RecordStructure);
	
EndProcedure

Function DataSynchronizationPassword(Val InfobaseNode) Export
	
	SetPrivilegedMode(True);
	
	DataSynchronizationPasswords = SessionParameters.DataSynchronizationPasswords.Get();
	
	Return DataSynchronizationPasswords.Get(InfobaseNode);

EndFunction

Function DataSynchronizationPasswordSpecified(Val InfobaseNode) Export
	
	Return DataSynchronizationPassword(InfobaseNode) <> Undefined;
	
EndFunction

Procedure SetDataSynchronizationPassword(Val InfobaseNode, Val AuthenticationData) Export
	
	SetPrivilegedMode(True);
	
	DataSynchronizationPasswords = SessionParameters.DataSynchronizationPasswords.Get();
	DataSynchronizationPasswords.Insert(InfobaseNode, AuthenticationData);
	SessionParameters.DataSynchronizationPasswords = New ValueStorage(DataSynchronizationPasswords);
	
EndProcedure

Function FullNameOfConfigurationForm(TransportID) Export

	Manager = TransportManagerById(TransportID);
	DataProcessorName = Manager.Create().Metadata().FullName();
	NameOfConfigurationForm = TransportParameter(TransportID, "NameOfConfigurationForm");
	
	Return DataProcessorName + ".Form." + NameOfConfigurationForm;
		
EndFunction

Function FullNameOfFirstSetupForm(TransportID) Export

	Manager = TransportManagerById(TransportID);
	DataProcessorName = Manager.Create().Metadata().FullName();
	NameOfFirstSetupForm = TransportParameter(TransportID, "NameOfFirstSetupForm");
	
	Return DataProcessorName + ".Form." + NameOfFirstSetupForm;
		
EndFunction

#Region OperationsWithFTPConnectionObject

// It determines whether the FTP server has the directory.
//
// Parameters:
//  Path - String - directory path.
//  DirectoryName - String - a directory name.
//  FTPConnection - FTPConnection - FTPConnection used to connect to the FTP server.
// 
// Returns:
//  Boolean - if True, the directory exists. Otherwise, False.
//
Function FTPDirectoryExist(Val Path, Val DirectoryName, Val FTPConnection) Export
	
	For Each FTPFile In FTPConnection.FindFiles(Path) Do
		
		If FTPFile.IsDirectory() And FTPFile.Name = DirectoryName Then
			
			Return True;
			
		EndIf;
		
	EndDo;
	
	Return False;
EndFunction

Function FTPConnection(Val Settings) Export
	
	Return New FTPConnection(
		Settings.Server,
		Settings.Port,
		Settings.UserName,
		Settings.UserPassword,
		ProxyServerSettings(Settings.SecureConnection),
		Settings.PassiveConnection,
		Settings.Timeout,
		Settings.SecureConnection);
	
EndFunction

Function FTPConnectionSetup(Val Timeout = 180) Export
	
	Result = New Structure;
	Result.Insert("Server", "");
	Result.Insert("Port", 21);
	Result.Insert("UserName", "");
	Result.Insert("UserPassword", "");
	Result.Insert("PassiveConnection", False);
	Result.Insert("Timeout", Timeout);
	Result.Insert("SecureConnection", Undefined);
	
	Return Result;
EndFunction

// Returns server name and FTP server path. This data is gotten from FTP server connection string.
//
// Parameters:
//  StringForConnection - String - an FTP resource connection string.
// 
// Returns:
//  Structure - FTP server connection settings. Structure fields are::
//              Server - String - The server name.
//              Path - String - The server path.
//
//  Example 1:
// Result = FTPServerNameAndPath("ftp://server");
// Result.Server = "server";
// Result.Path = "/";
//
//  Example 2:
// Result = FTPServerNameAndPath("ftp://server/saas/obmen");
// Result.Server = "server";
// Result.Path = "/saas/obmen/";
//
Function FTPServerNameAndPath(Val StringForConnection) Export
	
	Result = New Structure("Server, Path");
	StringForConnection = TrimAll(StringForConnection);
	
	If (Upper(Left(StringForConnection, 6)) <> "FTP://"
		And Upper(Left(StringForConnection, 7)) <> "FTPS://")
		Or StrFind(StringForConnection, "@") <> 0 Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Xâu ký tự kết nối đến nguồn FTP không phù hợp với định dạng: ""%1""';
				|ru = 'Строка подключения к FTP-ресурсу не соответствует формату: ""%1""';
				|en = 'The FTP connection string has invalid format: ""%1""'; fa = 'The FTP connection string has invalid format: ""%1""';
				|it = 'La riga di connessione alla risorsa FTP non corrisponde al formato: ""%1""';
				|pl = 'Wiersz podłączenia do FTP-zasobu nie odpowiada formatowi: ""%1""';
				|tr = 'FTP bağlantı dizesi şu biçimle eşleşmiyor: ""%1""'"), StringForConnection);
	EndIf;
	
	ConnectionParameters = StrSplit(StringForConnection, "/");
	
	If ConnectionParameters.Count() < 3 Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trong xâu ký tự kết nối đến nguồn FTP chưa chỉ ra tên server: ""%1""';
				|ru = 'В строке подключения к FTP-ресурсу не указано имя сервера: ""%1""';
				|en = 'The server name is missing from the FTP connection string: ""%1""'; fa = 'The server name is missing from the FTP connection string: ""%1""';
				|it = 'Nella riga di connessione alla risorsa FTP non è indicato il nome del server: ""%1""';
				|pl = 'W wierszu podłączenia do FTP-zasobu nie jest wskazana nazwa serwera: ""%1""';
				|tr = 'FTP kaynak bağlantı dizesinde sunucu adı belirtilmemiş: ""%1""'"), StringForConnection);
	EndIf;
	
	Result.Server = ConnectionParameters[2];
	
	ConnectionParameters.Delete(0);
	ConnectionParameters.Delete(0);
	ConnectionParameters.Delete(0);
	
	ConnectionParameters.Insert(0, "@");
	
	If Not IsBlankString(ConnectionParameters.Get(ConnectionParameters.UBound())) Then
		
		ConnectionParameters.Add("@");
		
	EndIf;
	
	Result.Path = StrConcat(ConnectionParameters, "/");
	Result.Path = StrReplace(Result.Path, "@", "");
	
	Return Result;
EndFunction

#EndRegion

#Region COM

// Main function that is used to perform the data exchange over the external connection.
//
// Parameters: 
//  SettingsStructure - structure of COM exchange transport settings.
//
// Returns:
//  Structure:
//    * Join                  - COMObject
//                                  - Undefined - if the connection is established, returns a COM object reference.
//                                    Otherwise, returns Undefined;
//    * BriefErrorDetails       - String - brief error description;
//    * DetailedErrorDetails     - String - detailed error description;
//    * AddInAttachmentError - Boolean - a COM connection error flag.
//
Function EstablishExternalConnectionWithInfobase(SettingsStructure) Export
	
	Result = Common.EstablishExternalConnectionWithInfobase(SettingsStructure);
	
	ExternalConnection = Result.Join;
	If ExternalConnection = Undefined Then
		// Connection establish error.
		Return Result;
	EndIf;
	
	// COM connection cannot connect configurations with mismatching 1C:Enterprise language versions.
	
	VariantOfBuiltInCorrespondentLanguage = "";
	EmbeddedLanguageOptionsAreDifferent = False;
	If Metadata.ScriptVariant = Metadata.ObjectProperties.ScriptVariant.Russian
		And ExternalConnection.Metadata.ScriptVariant <> ExternalConnection.Metadata.ObjectProperties.ScriptVariant.Russian Then
		VariantOfBuiltInCorrespondentLanguage = NStr("vi = 'Tiếng Anh';
													|ru = 'Английский';
													|en = 'English'; fa = 'انگلیسی';
													|it = 'Английский';
													|pl = 'English';
													|tr = 'İngilizce'");
		EmbeddedLanguageOptionsAreDifferent = True;
	EndIf;
	
	If Metadata.ScriptVariant = Metadata.ObjectProperties.ScriptVariant.English
		And ExternalConnection.Metadata.ScriptVariant <> ExternalConnection.Metadata.ObjectProperties.ScriptVariant.English Then
		VariantOfBuiltInCorrespondentLanguage = NStr("vi = 'Tiếng Nga';
													|ru = 'Русский';
													|en = 'Russian'; fa = 'روسی';
													|it = 'Русский';
													|pl = 'Russian';
													|tr = 'Rusça'");
		EmbeddedLanguageOptionsAreDifferent = True;
	EndIf;
	
	If EmbeddedLanguageOptionsAreDifferent Then
		
		DetailedErrorDetails = NStr("vi = 'Trong chương trình được kết nối có phương án ngôn ngữ hệ thống khác (%1). Không thể kết nối.';
									|ru = 'В подключаемой программе отличается вариант встроенного языка (%1). Подключение невозможно.';
									|en = 'The application to connect has a different 1C:Enterprise language option (%1). Connection is unavailable.'; fa = 'The application to connect has a different 1C:Enterprise language option (%1). Connection is unavailable.';
									|it = 'Nel programma collegabile differisce la variante di linguaggio integrato (%1). Impossibile collegarsi.';
									|pl = 'W podłączanym programie różni się wariant języka wbudowanego (%1). Podłączenie jest niemożliwe.';
									|tr = 'Bağlanan programda 1C:Enterprise dilinin seçeneği farklı (%1). Bağlantı kurulamaz.'");
		DetailedErrorDetails = StrTemplate(DetailedErrorDetails, VariantOfBuiltInCorrespondentLanguage); 
		
		Result.DetailedErrorDetails = DetailedErrorDetails;
		Result.BriefErrorDetails   = DetailedErrorDetails;
		Result.Join = Undefined;
		
		Return Result;
		
	EndIf;
		
	// Checking whether it is possible to operate with an external infobase.
	
	Try
		NoFullAccess = Not ExternalConnection.DataExchangeExternalConnection.RoleAvailableFullAccess();
	Except
		NoFullAccess = True;
	EndTry;
	
	If NoFullAccess Then
		Result.DetailedErrorDetails = NStr("vi = 'Cần ấn định vai trò ""Quản trị hệ thống"" và ""Toàn quyền"" cho người sử dụng đã chỉ ra để kết nối với chương trình khác';
											|ru = 'Пользователю, указанному для подключения к другой программе, должны быть назначены роли ""Администратор системы"" и ""Полные права""';
											|en = 'The user on whose behalf connection to the peer application is established must be assigned the ""System administrator"" and ""Full access"" roles.'; fa = 'The user on whose behalf connection to the peer application is established must be assigned the ""System administrator"" and ""Full access"" roles.';
											|it = 'All''utente specificato per la connessione ad un altro programma devono essere assegnati i ruoli ""Amministratore di sistema"" e ""Diritti completi""';
											|pl = 'Użytkownikowi, wskazanemu do podłączenia do innego programu, powinny być określone role ""Administrator systemu"" i ""Pełne uprawnienia""';
											|tr = 'Başka bir uygulamaya bağlantı için belirtilen kullanıcı ""Sistem yöneticisi"" ve ""Tam haklar"" rollerine atanmış olmalıdır.'");
		Result.BriefErrorDetails   = Result.DetailedErrorDetails;
		Result.Join = Undefined;
	Else
		Try 
			InvalidState = ExternalConnection.InfobaseUpdate.InfobaseUpdateRequired();
		Except
			InvalidState = False
		EndTry;
		
		If InvalidState Then
			Result.DetailedErrorDetails = NStr("vi = 'Chương trình khác có trạng thái đang cập nhật.';
												|ru = 'Другая программа находится в состоянии обновления.';
												|en = 'Peer application is updating.'; fa = 'Peer application is updating.';
												|it = 'Un altro programma si trova in fase di aggiornamento.';
												|pl = 'Peer application is updating.';
												|tr = 'Başka bir uygulama güncelleniyor.'");
			Result.BriefErrorDetails   = Result.DetailedErrorDetails;
			Result.Join = Undefined;
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Initializes the data exchange subsystem to execute the exchange process.
// Parameters:
//
// Returns:
//  Structure - a structure with all necessary data and objects to execute exchange.
//
Function ExchangeSettingsForExternalConnection(InfobaseNode, ActionOnExchange, TransactionItemsCount) Export
	
	// Function return value.
	ExchangeSettingsStructure = DataExchangeServer.BaseExchangeSettingsStructure();
	
	ExchangeSettingsStructure.InfobaseNode = InfobaseNode;
	ExchangeSettingsStructure.ActionOnExchange      = ActionOnExchange;
	ExchangeSettingsStructure.IsDIBExchange           = DataExchangeCached.IsDistributedInfobaseNode(InfobaseNode);
	
	PropertyStructure = Common.ObjectAttributesValues(ExchangeSettingsStructure.InfobaseNode, "Code, Description");
	
	ExchangeSettingsStructure.InfobaseNodeCode1 = DataExchangeServer.CorrespondentNodeIDForExchange(
		ExchangeSettingsStructure.InfobaseNode);
		
	ExchangeSettingsStructure.InfobaseNodeDescription = PropertyStructure.Description;
	
	If TransactionItemsCount = Undefined Then
		TransactionItemsCount = DataExchangeServer.ItemsCountInTransactionOfActionToExecute(ActionOnExchange);
	EndIf;
	
	ExchangeSettingsStructure.TransactionItemsCount = TransactionItemsCount;
	
	// CALCULATED VALUES
	ExchangeSettingsStructure.DoDataImport = (ExchangeSettingsStructure.ActionOnExchange = Enums.ActionsOnExchange.DataImport);
	ExchangeSettingsStructure.DoDataExport = (ExchangeSettingsStructure.ActionOnExchange = Enums.ActionsOnExchange.DataExport);
	
	ExchangeSettingsStructure.ExchangePlanName = DataExchangeCached.GetExchangePlanName(ExchangeSettingsStructure.InfobaseNode);
	ExchangeSettingsStructure.CorrespondentExchangePlanName =
		DataExchangeCached.GetNameOfCorrespondentExchangePlan(ExchangeSettingsStructure.InfobaseNode);
	
	ExchangeSettingsStructure.CurrentExchangePlanNode = DataExchangeCached.GetThisExchangePlanNode(ExchangeSettingsStructure.ExchangePlanName);
	ExchangeSettingsStructure.CurrentExchangePlanNodeCode1 = DataExchangeServer.NodeIDForExchange(ExchangeSettingsStructure.InfobaseNode);
	
	// Getting the message key for the event log.
	ExchangeSettingsStructure.EventLogMessageKey = DataExchangeServer.EventLogMessageKey(
		ExchangeSettingsStructure.InfobaseNode, ExchangeSettingsStructure.ActionOnExchange);
		
	ExchangeSettingsStructure.TransportID = "COM";
	
	DataExchangeServer.SetDebugModeSettingsForStructure(ExchangeSettingsStructure);
	
	// Validate settings structure values for the data exchange. Log errors.
	DataExchangeServer.CheckExchangeStructure(ExchangeSettingsStructure);
	
	// Canceling if settings contain errors.
	If ExchangeSettingsStructure.Cancel Then
		Return ExchangeSettingsStructure;
	EndIf;
	
	// Initializing the exchange data processor.
	DataExchangeServer.InitDataExchangeDataProcessorByConversionRules(ExchangeSettingsStructure);
	
	Return ExchangeSettingsStructure;

EndFunction

// Returns an array of version numbers supported by correspondent API for the DataExchange subsystem.
// 
// Parameters:
//   ExternalConnection - COMObject - COM connection that is used for working with the peer infobase.
//
// Returns:
//   Array of String - Version numbers that are supported by the peer's API.
//
Function InterfaceVersionsThroughExternalConnection(ExternalConnection) Export
	
	Return Common.GetInterfaceVersionsViaExternalConnection(ExternalConnection, "DataExchange");
	
EndFunction

#EndRegion

// Verifies the transport processor connection by the specified settings.
Procedure CheckExchangeMessageTransportDataProcessorAttachment(Cancel,
	SettingsStructure, TransportKind, ErrorMessage = "", NewPasswords = Undefined) Export
	
	SetPrivilegedMode(True);
	
	Peer = Undefined;
	ThereIsCorrespondent = SettingsStructure.Property("Peer", Peer)
		Or SettingsStructure.Property("CorrespondentEndpoint", Peer);
		
	ParametersString1 = "COMUserPassword, FTPConnectionPassword, WSPassword, ArchivePasswordExchangeMessages,
		|FTPConnectionDataAreasPassword, ArchivePasswordDataAreaExchangeMessages";
	
	If ThereIsCorrespondent And NewPasswords = Undefined Then
		Passwords = Common.ReadDataFromSecureStorage(Peer, ParametersString1, True);
	EndIf;
	
	If TransportKind = Enums.ExchangeMessagesTransportTypes.FILE Then
		
		Transport = DataProcessors.ExchangeMessageTransportFILE.Create();
		Transport.DataExchangeDirectory = SettingsStructure.FILEDataExchangeDirectory;
		
	ElsIf TransportKind = Enums.ExchangeMessagesTransportTypes.FTP Then 
		
		Transport = DataProcessors.ExchangeMessageTransportFTP.Create();
		Transport.PassiveConnection = SettingsStructure.FTPConnectionPassiveConnection;
		Transport.User = SettingsStructure.FTPConnectionUser;
		Transport.Port = SettingsStructure.FTPConnectionPort;
		Transport.Path = SettingsStructure.FTPConnectionPath;
		
		If SettingsStructure.Property("FTPConnectionPassword") Then
			Transport.Password = SettingsStructure.FTPConnectionPassword;
		ElsIf NewPasswords = Undefined Then
			Transport.Password = Passwords.FTPConnectionPassword;
		Else
			Transport.Password = NewPasswords.FTPConnectionPassword;
		EndIf;
		
	EndIf;
	
	If Not Transport.ConnectionIsSet() Then
		
		Cancel = True;
		
		ErrorMessage = Transport.ErrorMessage
			+ Chars.LF + NStr("vi = 'Thông tin về lỗi kỹ thuật xem trong nhật ký sự kiện.';
								|ru = 'Техническую информацию об ошибке см. в журнале регистрации.';
								|en = 'See the event log for details.'; fa = 'See the event log for details.';
								|it = 'Per i dettagli tecnici sull''errore consultare il registro di log.';
								|pl = 'See the event log for details.';
								|tr = 'Olay günlüğündeki hata hakkındaki teknik bilgilere bakın.'");
				
	EndIf;
	
EndProcedure

Function ValueToJSON(Value) Export
	
	JSONWriter = New JSONWriter;
	JSONWriter.SetString();
	WriteJSON(JSONWriter, Value);
	
	Return JSONWriter.Close();
	
EndFunction

Function JSONValue(String, ReadToMap = True, PropertiesWithDateValuesNames = Undefined) Export
	
	JSONReader = New JSONReader;
	JSONReader.SetString(String);
	
	Return ReadJSON(JSONReader, ReadToMap, PropertiesWithDateValuesNames);

EndFunction

// Check that all required transport configuration fields are filled.
//
// Parameters:
//  Setting - QueryResult, Structure - Values of transport settings attributes.
//  SettingID - String - Transport ID.
//
// Returns:
//   Boolean - True if all required attributes are filled.
//
Function RequiredAttributesOfTransportSettingsHaveBeenFilledIn(Val Setting, Val SettingID) Export
	
	SettingUpTransport = SettingUpTransportInStructure(Setting);

	TransportManager = TransportManagerById(SettingID);
	
	SettingFilledIn = RequiredAttributesOfSettingsAreFilledIn(SettingUpTransport, TransportManager);
	
	ExchangeMessagesTransportOverridable.WhenCheckingFillingInRequiredAttributesOfTransportSettings(SettingUpTransport, TransportManager, SettingFilledIn);
	
	Return SettingFilledIn;
	
EndFunction

#EndRegion

#Region Private

Function AllTypesOfTransport()
	
	TypesOfTransport = New Array;
	
	TypesOfTransport.Add(DataProcessors.ExchangeMessageTransportSM);
	TypesOfTransport.Add(DataProcessors.ExchangeMessageTransportCOM);
	TypesOfTransport.Add(DataProcessors.ExchangeMessageTransportFILE);
	TypesOfTransport.Add(DataProcessors.ExchangeMessageTransportFTP);
	TypesOfTransport.Add(DataProcessors.ExchangeMessageTransportEMAIL);
	TypesOfTransport.Add(DataProcessors.ExchangeMessageTransportYandexDisk);
	TypesOfTransport.Add(DataProcessors.ExchangeMessageTransportGoogleDrive);
	TypesOfTransport.Add(DataProcessors.ExchangeMessageTransportWS);
	TypesOfTransport.Add(DataProcessors.ExchangeMessageTransportHTTP);
	TypesOfTransport.Add(DataProcessors.ExchangeMessageTransportPassiveMode);
	TypesOfTransport.Add(DataProcessors.ExchangeMessageTransportESB1C);
	
	ExchangeMessagesTransportOverridable.WhenDeterminingTransportTypes(TypesOfTransport);
		
	Return TypesOfTransport;
	
EndFunction

Function TransportManagersById()
	
	Managers = New Map;
	
	For Each Transport In AllTypesOfTransport() Do
		
		Parameters = Transport.TransportParameters();
		
		If Managers.Get(Parameters.TransportID) <> Undefined Then
			Continue;
		EndIf;
		
		Managers.Insert(Parameters.TransportID, Transport);
		
	EndDo;
	
	Return Managers;
	
EndFunction

Function PrefixForIdentifierAttribute()
	
	Return "Id_";
	
EndFunction

Procedure OnCreateAtServer(Form, Cancel, StandardProcessing) Export
	
	Form.Enabled = Users.IsFullUser();
	
	FormParameters = Form.Parameters;
	Object = Form.Object;
	
	If FormParameters.Property("TransportSettings")
		And TypeOf(FormParameters.TransportSettings) = Type("Structure") Then
		
		TransportSettings = FormParameters.TransportSettings;
		FillPropertyValues(Object, TransportSettings);
		
	Else
		
		TransportSettings = New Structure;
		
	EndIf;
		
	NameOfTransportProcessing = Form.FormAttributeToValue("Object").Metadata().Name;
	TransportParameters = DataProcessors[NameOfTransportProcessing].TransportParameters();

	If ValueIsFilled(TransportParameters.Alias) Then
		Form.AutoTitle = False;
		Form.Title = TransportParameters.Alias;
	EndIf;
	
	Prefix = PrefixForIdentifierAttribute();
	AttributesToBeAdded = New Array;
	
	For Each Attribute In TransportParameters.AttributesForSecureStorage Do
		
		NewAttribute = New FormAttribute(Prefix + Attribute,
			New TypeDescription("String", , , New StringQualifiers(36)));
		AttributesToBeAdded.Add(NewAttribute);
		
	EndDo;
	
	Form.ChangeAttributes(AttributesToBeAdded);
	
	For Each Attribute In TransportParameters.AttributesForSecureStorage Do
		
		If TransportSettings.Property(Attribute) Then
			Form[Prefix + Attribute] = TransportSettings[Attribute];
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure FillInSettingsFromSecureStorageForForm(Form, Object) Export
	
	FormObject = Form.Object;
	NameOfTransportProcessing = Object.Metadata().Name;
	TransportParameters = DataProcessors[NameOfTransportProcessing].TransportParameters();
	
	Prefix = PrefixForIdentifierAttribute();
	
	SetPrivilegedMode(True);
	
	For Each Attribute In TransportParameters.AttributesForSecureStorage Do
		
		If FormObject[Attribute] = Form[Prefix + Attribute]
			And ValueIsFilled(Form[Prefix + Attribute]) Then
			Object[Attribute] = Common.ReadDataFromSecureStorage(Form[Prefix + Attribute]);
		EndIf;
	
	EndDo;
	
	SetPrivilegedMode(False);
	
EndProcedure

Procedure FillInSettingsFromSecureStorage(Object) Export
	
	NameOfTransportProcessing = Object.Metadata().Name;
	TransportParameters = DataProcessors[NameOfTransportProcessing].TransportParameters();
	
	SetPrivilegedMode(True);
	
	For Each Attribute In TransportParameters.AttributesForSecureStorage Do
		
		If ValueIsFilled(Object[Attribute]) Then
			Object[Attribute] = Common.ReadDataFromSecureStorage(Object[Attribute]);
		EndIf;
	
	EndDo;
	
	SetPrivilegedMode(False);
	
EndProcedure

Function ResultOfClosingTransportForm(Form) Export
	
	Result = New Structure;
	
	Object = Form.Object;
	
	MetadataDataProcessors = Form.FormAttributeToValue("Object").Metadata();
	NameOfTransportProcessing = MetadataDataProcessors.Name;
	TransportParameters = DataProcessors[NameOfTransportProcessing].TransportParameters();
	
	Prefix = PrefixForIdentifierAttribute();
	
	SetPrivilegedMode(True);
	
	For Each Attribute In TransportParameters.AttributesForSecureStorage Do
		
		Value = Object[Attribute];
		Value_ID = Form[Prefix + Attribute];
		
		If Not Value = Value_ID Then
			
			If ValueIsFilled(Value) Then
				// Save or update the password.
				If Not ValueIsFilled(Value_ID) Then
					Value_ID = String(New UUID);
				EndIf;
				
				Common.WriteDataToSecureStorage(Value_ID, Value);
				Object[Attribute] = Value_ID;
				
			ElsIf ValueIsFilled(Value_ID) Then
				
				// Remove the password from the secured storage.
				Common.DeleteDataFromSecureStorage(Value_ID);
				
			EndIf;
			
		EndIf;
	
	EndDo;
	
	SetPrivilegedMode(False);
	
	For Each Attribute In MetadataDataProcessors.Attributes Do
		Result.Insert(Attribute.Name, Object[Attribute.Name]);
	EndDo;
	
	Return Result;
		
EndFunction

Procedure ErrorInformationInMessages(Transport, ErrorInfo, SupplementErrorMessage = False) Export

	BriefErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo);
	DetailErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo);
	
	If SupplementErrorMessage Then
		
		Transport.ErrorMessage = Transport.ErrorMessage + Chars.LF + BriefErrorDescription;
		Transport.ErrorMessageEventLog = Transport.ErrorMessageEventLog + Chars.LF + DetailErrorDescription;
		
	Else
		
		Transport.ErrorMessage = BriefErrorDescription;
		Transport.ErrorMessageEventLog = DetailErrorDescription;
	
	EndIf;
	
EndProcedure

Procedure WriteMessageToRegistrationLog(Transport, ActionOnExchange = Undefined, ErrorMessage = "", IsError = True) Export
	
	If ValueIsFilled(ErrorMessage) Then
		ErrorMessageEventLog = ErrorMessage;
	ElsIf ValueIsFilled(Transport.ErrorMessageEventLog) Then
		ErrorMessageEventLog = Transport.ErrorMessageEventLog;
	ElsIf ValueIsFilled(Transport.ErrorMessage) Then
		ErrorMessageEventLog = Transport.ErrorMessage;
	Else
		ErrorMessageEventLog = NStr("vi = 'Lỗi nội bộ';
									|ru = 'Внутренняя ошибка';
									|en = 'Internal error'; fa = 'Internal error';
									|it = 'Errore interno';
									|pl = 'Błąd wewnętrzny';
									|tr = 'Dahili hata'");
	EndIf;
	
	TransportName = NStr("vi = 'Bộ xử lý: %1';
						|ru = 'Обработка: %1';
						|en = 'Data processor: %1'; fa = 'Data processor: %1';
						|it = 'Elaborazione: %1';
						|pl = 'Przetwarzanie: %1';
						|tr = 'Veri işlemcisi: %1'");
	TransportName = StrTemplate(TransportName, Transport.Metadata().Name);
	
	ErrorMessageEventLog = TransportName + Chars.LF + ErrorMessageEventLog;
	
	If TypeOf(ActionOnExchange) = Type("String") Then
		ActionOnExchange = Enums.ActionsOnExchange[ActionOnExchange];
	EndIf;
		
	Peer = Transport.Peer;
	
	If Not ValueIsFilled(ActionOnExchange) Or Not ValueIsFilled(Peer) Then
		EventLogMessageKey = NStr("vi = 'Truyền thông điệp trao đổi';
									|ru = 'Транспорт сообщений обмена';
									|en = 'Exchange message transport'; fa = 'انتقال پیام تبادل';
									|it = 'Trasporto dei messaggi di scambio';
									|pl = 'Exchange message transport';
									|tr = 'Değişim ileti aktarımı'");
	Else
		EventLogMessageKey = DataExchangeServer.EventLogMessageKey(
			Transport.Peer, ActionOnExchange);
	EndIf;
		
	Level = ?(IsError, EventLogLevel.Error, EventLogLevel.Information);
	
	If ValueIsFilled(Peer) Then
		
		WriteLogEvent(EventLogMessageKey, 
			Level,
			Peer.Metadata(),
			Peer,
			ErrorMessageEventLog);
			
	Else
		WriteLogEvent(EventLogMessageKey, Level,,, ErrorMessageEventLog);
	EndIf;
	
EndProcedure

Function AuthenticationRequired(AuthenticationParameters, FormName = "") Export
	
	If Not ValueIsFilled(AuthenticationParameters.TransportID) Then
		Return False;
	EndIf;
	
	DirectConnection = TransportParameter(AuthenticationParameters.TransportID, "DirectConnection");
	
	If Not DirectConnection Then
		Return False;
	EndIf;
	
	DataSynchronizationPasswordSpecified = DataSynchronizationPasswordSpecified(AuthenticationParameters.Peer);
	
	If DataSynchronizationPasswordSpecified Then
		Return False;
	EndIf;
	
	Transport = Initialize(AuthenticationParameters, False);
	
	DataProcessorName = Transport.Metadata().FullName();
	NameOfAuthenticationForm = TransportParameter(AuthenticationParameters.TransportID, "NameOfAuthenticationForm");
	FormName = DataProcessorName + ".Form." + NameOfAuthenticationForm;
	
	Return Transport.AuthenticationRequired();
	
EndFunction

Function TempExchangeMessagesDirectory(Transport)
	
	TempDirectoryName = "";
	
	DirectoryID = Transport.DirectoryID;
	
	// Creating the temporary exchange message directory.
	Try
		
		TempDirectoryName = DataExchangeServer.CreateTempExchangeMessagesDirectory(DirectoryID);
		
	Except
		
		Transport.ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteMessageToRegistrationLog(Transport);
		
		Return TempDirectoryName;
		
	EndTry;
	
	Return TempDirectoryName;
	
EndFunction

Procedure FillInDefaultMessageNames(Transport)
	
	// Templates for receiving
	Templates = New Array;
	Peer = Transport.Peer;
	
	ThisNode = DataExchangeCached.GetThisExchangePlanNode(Transport.ExchangePlanName);
	Transliteration = Transport.Metadata().Attributes.Find("Transliteration") <> Undefined
		And Transport.Transliteration;
	
	FirstTemplate = MessageFileNameTemplate(ThisNode, Peer, False, Transliteration);
	FirstTemplate = StrReplace(FirstTemplate, "Message", "Message*") + ".*";
	
	Templates.Add(FirstTemplate);
	
	SecondTemplate = MessageFileNameTemplate(ThisNode, Peer, False, Transliteration, True);
	SecondTemplate = StrReplace(SecondTemplate, "Message", "Message*") + ".*";
	
	If FirstTemplate <> SecondTemplate Then
		Templates.Add(SecondTemplate);
	EndIf;
	
	Transport.NameTemplatesForReceivingMessage = Templates;
	
	// Name of the message being sent
	Transport.NameOfMessageToSend = MessageFileNameTemplate(ThisNode, Peer, True, Transliteration) + ".xml";
	
EndProcedure

Function MessageFileNameTemplate(CurrentExchangePlanNode, InfobaseNode, IsOutgoingMessage, 
	Transliteration = False, UseVirtualNodeCodeOnGet = False)
	
	If IsOutgoingMessage Then
		SenderCode = DataExchangeServer.NodeIDForExchange(InfobaseNode);
		RecipientCode  = DataExchangeServer.CorrespondentNodeIDForExchange(InfobaseNode);
	Else
		SenderCode = DataExchangeServer.CorrespondentNodeIDForExchange(InfobaseNode);
		RecipientCode  = DataExchangeServer.NodeIDForExchange(InfobaseNode);
	EndIf;
	
	If IsOutgoingMessage Or UseVirtualNodeCodeOnGet Then
		// This is an exchange with a peer infobase that is unaware of the predefined node's new code.
		// Instead, use the code from the register when generating the exchange message filename.
		PredefinedNodeAlias = DataExchangeServer.PredefinedNodeAlias(InfobaseNode);
		If ValueIsFilled(PredefinedNodeAlias) Then
			If IsOutgoingMessage Then
				SenderCode = PredefinedNodeAlias;
			Else
				RecipientCode = PredefinedNodeAlias;
			EndIf;
		EndIf;
	EndIf;
	
	MessageFileName = ExchangeMessageFileName(SenderCode, RecipientCode, IsOutgoingMessage);
	
	// Considering the transliteration setting for the exchange plan node.
	If Transliteration Then
		MessageFileName = StringFunctions.LatinString(MessageFileName);
	EndIf;
	
	Return MessageFileName;
	
EndFunction

// Returns the name of exchange message file by sender node and recipient node data.
//
Function ExchangeMessageFileName(SenderNodeCode, RecipientNodeCode, IsOutgoingMessage)
	
	NameTemplate = "[Prefix]_[SenderNode]_[RecipientNode]";
	If StrLen(SenderNodeCode) = 36 And IsOutgoingMessage Then
		SourceIBPrefix = Constants.DistributedInfobaseNodePrefix.Get();
		If ValueIsFilled(SourceIBPrefix) Then
			NameTemplate = "[Prefix]_[SourceIBPrefix]_[SenderNode]_[RecipientNode]";
		EndIf;
	EndIf;
	NameTemplate = StrReplace(NameTemplate, "[Prefix]",         "Message");
	NameTemplate = StrReplace(NameTemplate, "[SourceIBPrefix]",SourceIBPrefix);
	NameTemplate = StrReplace(NameTemplate, "[SenderNode]", SenderNodeCode);
	NameTemplate = StrReplace(NameTemplate, "[RecipientNode]",  RecipientNodeCode);
	
	Return NameTemplate;
EndFunction

Function PackExchangeMessageIntoZipFile(Transport, Password) Export
	
	Result = True;
		
	FileName = CommonClientServer.GetFullFileName(
		Transport.TempDirectory, Transport.NameOfMessageToSend);
		
	// Getting the temporary archive file name.
	File = New File(FileName);
	FileNameWithoutExtension = File.BaseName;
		
	ArchiveTempFileName = CommonClientServer.GetFullFileName(
		Transport.TempDirectory, FileNameWithoutExtension + ".zip");
		
	If FileName <> Transport.ExchangeMessage Then
		MoveFile(Transport.ExchangeMessage, FileName);
		Transport.ExchangeMessage = FileName;
	EndIf;
	
	Try
		
		Archiver = New ZipFileWriter(ArchiveTempFileName, Password, NStr("vi = 'Tệp thông điệp trao đổi';
																		|ru = 'Файл сообщения обмена';
																		|en = 'Exchange message file'; fa = 'Exchange message file';
																		|it = 'File del messaggio di scambio';
																		|pl = 'Plik wiadomości wymiany';
																		|tr = 'Değişim mesajı dosyası'"));
		Archiver.Add(Transport.ExchangeMessage);
		Archiver.Write();
		
		Transport.ExchangeMessage = ArchiveTempFileName;
		
	Except
		
		Result = False;
		
		ErrorMessage = NStr("vi = 'Lỗi khi nén tệp thông điệp trao đổi.
                                  |%1';
                                  |ru = 'Ошибка при сжатии файла сообщения обмена.
                                  |%1';
                                  |en = 'Error packing the exchange message file.
                                  |%1'; fa = 'Error packing the exchange message file.
                                  |%1';
                                  |it = 'Ошибка при сжатии файла сообщения обмена.
                                  |%1';
                                  |pl = 'Error packing the exchange message file.
                                  |%1';
                                  |tr = 'Veri alışverişi mesajı dosyası sıkıştırılırken bir hata oluştu.
                                  |%1'");
		ErrorMessage = StrTemplate(ErrorMessage, ErrorProcessing.BriefErrorDescription(ErrorInfo())); 
		
		WriteMessageToRegistrationLog(Transport, Enums.ActionsOnExchange.DataExport);
		
	EndTry;
	
	Archiver = Undefined;
	
	Return Result;
	
EndFunction

Function UnzipExchangeMessageFromZipFile(Transport, ArchiveFileName, Password) Export

	Result = True;
	
	Archive = New ZipFileReader(ArchiveFileName, Password);
	FileInArchive = Archive[0];
		
	Try
		
		Archive.Extract(FileInArchive, Transport.TempDirectory);
		
		Transport.ExchangeMessage = 
			CommonClientServer.GetFullFileName(Transport.TempDirectory, FileInArchive.Name);
		
	Except
		
		Result = False;
		
		ErrorMessage = NStr("vi = 'Lỗi khi giải nén tệp thông điệp.
                                  |%1';
                                  |ru = 'Ошибка при распаковке сжатого файла сообщения.
                                  |%1';
                                  |en = 'Error extracting message file.
                                  |%1'; fa = 'Error extracting message file.
                                  |%1';
                                  |it = 'Ошибка при распаковке сжатого файла сообщения.
                                  |%1';
                                  |pl = 'Error extracting message file.
                                  |%1';
                                  |tr = 'Sıkıştırılmış mesaj dosyası açılırken bir hata oluştu.
                                  |%1'");
		ErrorMessage = StrTemplate(ErrorMessage, ErrorProcessing.BriefErrorDescription(ErrorInfo())); 
		
		Transport.ErrorMessage = ErrorMessage;
		
		WriteMessageToRegistrationLog(Transport, Enums.ActionsOnExchange.DataImport);
		
	EndTry;
	
	Return Result
	
EndFunction

Function ConnectionSettingsInXML_1_2(ConnectionSettings) Export
	
	TransportID = ConnectionSettings.TransportID;
	
	NodeAttributes = Common.ObjectAttributesValues(
		ConnectionSettings.InfobaseNode, "Code,ReceivedNo,SentNo");
	
	XMLWriter = New XMLWriter;
	XMLWriter.SetString("UTF-8");
	XMLWriter.WriteXMLDeclaration();
	
	XMLWriter.WriteStartElement("ПараметрыНастройки"); // @Non-NLS
	XMLWriter.WriteAttribute("ВерсияФормата", VersionOfXMLDataExchangeSettingsFormat()); // @Non-NLS 
	
	XMLWriter.WriteNamespaceMapping("xsd", "http://www.w3.org/2001/XMLSchema");
	XMLWriter.WriteNamespaceMapping("xsi", "http://www.w3.org/2001/XMLSchema-instance");
	XMLWriter.WriteNamespaceMapping("v8",  "http://v8.1c.ru/data");
	
	// Connection parameters
	XMLWriter.WriteStartElement("ОсновныеПараметрыОбмена"); // @Non-NLS

	ExchangePlanName = DataExchangeFormatTranslationCached.BroadcastName(ConnectionSettings.ExchangePlanName, "ru");

	AddXMLRecord(XMLWriter, ExchangePlanName, "ИмяПланаОбмена"); // @Non-NLS
	AddXMLRecord(XMLWriter, ConnectionSettings.ThisInfobaseDescription,   "НаименованиеВторойБазы"); // @Non-NLS
	AddXMLRecord(XMLWriter, ConnectionSettings.SecondInfobaseDescription, "НаименованиеЭтойБазы"); // @Non-NLS
	AddXMLRecord(XMLWriter, ConnectionSettings.NodeCode, "КодНовогоУзлаВторойБазы"); // @Non-NLS
	AddXMLRecord(XMLWriter, ConnectionSettings.DestinationInfobasePrefix, "ПрефиксИнформационнойБазыИсточника"); // @Non-NLS
	
	// Exchange message transport settings
	XMLWriter.WriteStartElement("ВидТранспортаСообщенийОбмена"); // @Non-NLS
	XMLWriter.WriteAttribute("xmlns", "");
	XMLWriter.WriteAttribute("xsi:type", "EnumRef.ВидыТранспортаСообщенийОбмена"); // @Non-NLS-2
	XMLWriter.WriteText(?(TransportID = "WS", "", TransportID));
	XMLWriter.WriteEndElement();
	
	TransportSettings = ConnectionSettings.TransportSettings;
		
	If TransportID = "FILE" Then
		
		ArchivePasswordExchangeMessages = Common.ReadDataFromSecureStorage(TransportSettings.ArchivePasswordExchangeMessages);
	
		AddXMLRecord(XMLWriter, ArchivePasswordExchangeMessages, "ПарольАрхиваСообщенияОбмена"); // @Non-NLS
		AddXMLRecord(XMLWriter, TransportSettings.Transliteration, "ТранслитерацияИмениФайловСообщенийОбмена"); // @Non-NLS
		AddXMLRecord(XMLWriter, TransportSettings.DataExchangeDirectory, "FILEКаталогОбменаИнформацией"); // @Non-NLS
		AddXMLRecord(XMLWriter, TransportSettings.CompressOutgoingMessageFile, "FILEСжиматьФайлИсходящегоСообщения"); // @Non-NLS
		
	ElsIf TransportID = "COM" Then
		
		AddXMLRecord(XMLWriter, "", "ПарольАрхиваСообщенияОбмена"); // @Non-NLS-2
		AddXMLRecord(XMLWriter, False, "ТранслитерацияИмениФайловСообщенийОбмена"); // @Non-NLS
		
		IBConnectionParameters = CommonClientServer.GetConnectionParametersFromInfobaseConnectionString(
		InfoBaseConnectionString());
		
		InfobaseOperatingMode             = IBConnectionParameters.InfobaseOperatingMode;
		NameOfInfobaseOn1CEnterpriseServer = IBConnectionParameters.NameOfInfobaseOn1CEnterpriseServer;
		NameOf1CEnterpriseServer                     = IBConnectionParameters.NameOf1CEnterpriseServer;
		InfobaseDirectory                   = IBConnectionParameters.InfobaseDirectory;

		IBUser   = InfoBaseUsers.CurrentUser();
		OSAuthentication = IBUser.OSAuthentication;
		UserName  = IBUser.Name;

		AddXMLRecord(XMLWriter, InfobaseOperatingMode, "COMВариантРаботыИнформационнойБазы"); // @Non-NLS
		AddXMLRecord(XMLWriter, NameOfInfobaseOn1CEnterpriseServer, "COMИмяИнформационнойБазыНаСервере1СПредприятия"); // @Non-NLS
		AddXMLRecord(XMLWriter, NameOf1CEnterpriseServer, "COMИмяСервера1СПредприятия"); // @Non-NLS
		AddXMLRecord(XMLWriter, InfobaseDirectory, "COMКаталогИнформационнойБазы"); // @Non-NLS
		AddXMLRecord(XMLWriter, OSAuthentication, "COMАутентификацияОперационнойСистемы"); // @Non-NLS
		AddXMLRecord(XMLWriter, UserName, "COMИмяПользователя"); // @Non-NLS
		
	ElsIf TransportID = "FTP" Then
		
		ArchivePasswordExchangeMessages = Common.ReadDataFromSecureStorage(TransportSettings.ArchivePasswordExchangeMessages);
		Password = Common.ReadDataFromSecureStorage(TransportSettings.Password);
		
		AddXMLRecord(XMLWriter, ArchivePasswordExchangeMessages, "ПарольАрхиваСообщенияОбмена"); // @Non-NLS	//	
		AddXMLRecord(XMLWriter, TransportSettings.Transliteration, "ТранслитерацияИмениФайловСообщенийОбмена"); // @Non-NLS
		AddXMLRecord(XMLWriter, TransportSettings.CompressOutgoingMessageFile, "FTPСжиматьФайлИсходящегоСообщения"); // @Non-NLS
		AddXMLRecord(XMLWriter, TransportSettings.MaxMessageSize, "FTPСоединениеМаксимальныйДопустимыйРазмерСообщения"); // @Non-NLS
		AddXMLRecord(XMLWriter, Password, "FTPСоединениеПароль"); // @Non-NLS
		AddXMLRecord(XMLWriter, TransportSettings.PassiveConnection, "FTPСоединениеПассивноеСоединение"); // @Non-NLS
		AddXMLRecord(XMLWriter, TransportSettings.User, "FTPСоединениеПользователь"); // @Non-NLS
		AddXMLRecord(XMLWriter, TransportSettings.Port, "FTPСоединениеПорт"); // @Non-NLS
		AddXMLRecord(XMLWriter, TransportSettings.Path, "FTPСоединениеПуть"); // @Non-NLS
		
	ElsIf TransportID = "WS" Then
			
		// No action required
		
	ElsIf TransportID = "EMAIL" Then 
		
		ArchivePasswordExchangeMessages = Common.ReadDataFromSecureStorage(TransportSettings.ArchivePasswordExchangeMessages);
	
		AddXMLRecord(XMLWriter, ArchivePasswordExchangeMessages, "ПарольАрхиваСообщенияОбмена"); // @Non-NLS
		AddXMLRecord(XMLWriter, TransportSettings.Transliteration, "ТранслитерацияИмениФайловСообщенийОбмена"); // @Non-NLS
		AddXMLRecord(XMLWriter, TransportSettings.MaxMessageSize, "EMAILМаксимальныйДопустимыйРазмерСообщения"); // @Non-NLS
		AddXMLRecord(XMLWriter, TransportSettings.CompressOutgoingMessageFile,        "EMAILСжиматьФайлИсходящегоСообщения"); // @Non-NLS
		
		// Account
		XMLWriter.WriteStartElement("EMAILУчетнаяЗапись"); // @Non-NLS
		XMLWriter.WriteAttribute("xmlns", "");
		XMLWriter.WriteAttribute("xsi:type", "CatalogRef.УчетныеЗаписиЭлектроннойПочты"); // @Non-NLS-2
		XMLWriter.WriteText(String(TransportSettings.Account.UUID()));
		XMLWriter.WriteEndElement();
		
	EndIf;
	
	AddXMLRecord(XMLWriter, TransportID = "EMAIL", "ИспользоватьПараметрыТранспортаEMAIL"); // @Non-NLS-2
	AddXMLRecord(XMLWriter, TransportID = "FILE", "ИспользоватьПараметрыТранспортаFILE"); // @Non-NLS-2
	AddXMLRecord(XMLWriter, TransportID = "FTP", "ИспользоватьПараметрыТранспортаFTP"); // @Non-NLS-2
	
	// Supporting the exchange settings file of the 1.0 version format.
	AddXMLRecord(XMLWriter, ConnectionSettings.ThisInfobaseDescription, "НаименованиеНастройкиВыполненияОбмена"); // @Non-NLS
	
	AddXMLRecord(XMLWriter, ConnectionSettings.NodeCode, "КодНовогоУзла"); // @Non-NLS
	AddXMLRecord(XMLWriter, NodeAttributes.Code, "КодПредопределенногоУзла"); // @Non-NLS
	AddXMLRecord(XMLWriter, NodeAttributes.SentNo, "НомерОтправленного"); // @Non-NLS
	AddXMLRecord(XMLWriter, NodeAttributes.ReceivedNo, "НомерПринятого"); // @Non-NLS
	
	XMLWriter.WriteEndElement(); // MainExchangeParameters
	
	If TransportID = "EMAIL" Then
		
		// EmailAccount
		Account = Undefined;
		If ValueIsFilled(TransportSettings.Account) Then
			Account = TransportSettings.Account.GetObject();
		EndIf;
		
		XMLWriter.WriteStartElement("УчетнаяЗаписьЭлектроннойПочты"); // @Non-NLS
		WriteXML(XMLWriter, Account);
		XMLWriter.WriteEndElement(); 
		// EmailAccount
		
	EndIf;
	
	If DataExchangeCached.IsXDTOExchangePlan(ConnectionSettings.ExchangePlanName) Then
		WriteXDTOExchangeParameters(XMLWriter, ConnectionSettings.ExchangePlanName);
	EndIf;
	
	XMLWriter.WriteEndElement(); // SetupParameters
	
	Return XMLWriter.Close();

EndFunction

Function ConnectionSettingsFromXML_1_2(XMLText, TransportID) Export
	
	Settings = New Structure;

	XMLReader = New XMLReader;
	XMLReader.SetString(XMLText);

	Factory = XDTOFactory.ReadXML(XMLReader);
		
	If Factory.Properties().Get("ОсновныеПараметрыОбмена") <> Undefined Then // @Non-NLS
		
		MainParameters = New Structure;
		MainParametersOfXDTO = Factory["ОсновныеПараметрыОбмена"]; // @Non-NLS
		For Each Property In MainParametersOfXDTO.Properties() Do
			MainParameters.Insert(Property.Name, MainParametersOfXDTO[Property.Name]); 
		EndDo;
		
		Settings.Insert("ExchangePlanName", MainParameters["ИмяПланаОбмена"]); // @Non-NLS-2
		Settings.Insert("SecondInfobaseDescription", MainParameters["НаименованиеВторойБазы"]); // @Non-NLS-2
		Settings.Insert("ThisInfobaseDescription", MainParameters["НаименованиеЭтойБазы"]); // @Non-NLS-2
		Settings.Insert("SecondInfobaseNewNodeCode", MainParameters["КодНовогоУзлаВторойБазы"]); // @Non-NLS-2
		Settings.Insert("SourceInfobasePrefix", MainParameters["ПрефиксИнформационнойБазыИсточника"]); // @Non-NLS-2
		
		Settings.Insert("DataExchangeExecutionSettingsDescription", MainParameters["НаименованиеНастройкиВыполненияОбмена"]); // @Non-NLS-2
		Settings.Insert("NewNodeCode", MainParameters["КодНовогоУзла"]); // @Non-NLS-2
		Settings.Insert("PredefinedNodeCode", MainParameters["КодПредопределенногоУзла"]); // @Non-NLS-2
		Settings.Insert("TransportID", TransportID);
			
		CopyStructureValue(MainParameters, "НомерОтправленного", Settings, "SentNo"); // @Non-NLS-1
		CopyStructureValue(MainParameters, "НомерПринятого", Settings, "ReceivedNo"); // @Non-NLS-1
	
		TransportSettings = New Structure;
		
		If TransportID = "FILE" Then
		
			TransportSettings.Insert("DataExchangeDirectory", MainParameters["FILEКаталогОбменаИнформацией"]); // @Non-NLS-2
			TransportSettings.Insert("CompressOutgoingMessageFile", MainParameters["FILEСжиматьФайлИсходящегоСообщения"]); // @Non-NLS-2
			TransportSettings.Insert("ArchivePasswordExchangeMessages", MainParameters["ПарольАрхиваСообщенияОбмена"]); // @Non-NLS-2
			TransportSettings.Insert("Transliteration", False);
		
		ElsIf TransportID = "FTP" Then
			
			TransportSettings.Insert("MaxMessageSize", MainParameters["FTPСоединениеМаксимальныйДопустимыйРазмерСообщения"]); // @Non-NLS-2
			TransportSettings.Insert("Password", MainParameters["FTPConnectionPassword"]);
			TransportSettings.Insert("ArchivePasswordExchangeMessages", MainParameters["ПарольАрхиваСообщенияОбмена"]); // @Non-NLS-2
			TransportSettings.Insert("PassiveConnection", MainParameters["FTPСоединениеПассивноеСоединение"]); // @Non-NLS-2
			TransportSettings.Insert("User", MainParameters["FTPСоединениеПользователь"]); // @Non-NLS-2
			TransportSettings.Insert("Port", MainParameters["FTPСоединениеПорт"]); // @Non-NLS-2
			TransportSettings.Insert("Path", MainParameters["FTPСоединениеПуть"]); // @Non-NLS-2
			TransportSettings.Insert("CompressOutgoingMessageFile", MainParameters["FTPСжиматьФайлИсходящегоСообщения"]); // @Non-NLS-2
			TransportSettings.Insert("Transliteration", False);
		
		ElsIf TransportID = "EMAIL" Then
			
			TransportSettings.Insert("MaxMessageSize", MainParameters["EMAILМаксимальныйДопустимыйРазмерСообщения"]); // @Non-NLS-2
			TransportSettings.Insert("CompressOutgoingMessageFile", MainParameters["EMAILСжиматьФайлИсходящегоСообщения"]); // @Non-NLS-2
			TransportSettings.Insert("ArchivePasswordExchangeMessages", MainParameters["ПарольАрхиваСообщенияОбмена"]); // @Non-NLS-2
			
		ElsIf TransportID = "COM" Then
			
			TransportSettings.Insert("InfobaseOperatingMode", MainParameters["COMВариантРаботыИнформационнойБазы"]); // @Non-NLS-2
			TransportSettings.Insert("NameOfInfobaseOn1CEnterpriseServer", MainParameters["COMИмяИнформационнойБазыНаСервере1СПредприятия"]); // @Non-NLS-2
			TransportSettings.Insert("NameOf1CEnterpriseServer", MainParameters["COMИмяСервера1СПредприятия"]); // @Non-NLS-2
			TransportSettings.Insert("InfobaseDirectory", MainParameters["COMКаталогИнформационнойБазы"]); // @Non-NLS-2
			TransportSettings.Insert("OperatingSystemAuthentication", MainParameters["COMАутентификацияОперационнойСистемы"]); // @Non-NLS-2
			TransportSettings.Insert("UserName", MainParameters["COMИмяПользователя"]); // @Non-NLS-2
			TransportSettings.Insert("UserPassword");
			TransportSettings.Insert("ContinueSettings", True);
		
		ElsIf TransportID = "WS" Then
			
			Settings.Insert("TransportID", "PassiveMode");
				
		EndIf;
		
	EndIf;
	
	If Factory.Properties().Get("XDTOExchangeParameters") <> Undefined Then
		
		ExchangeParameters = New Structure;
		XDTOExchangeParameters = Factory["XDTOExchangeParameters"];
		For Each Property In XDTOExchangeParameters.Properties() Do
			ExchangeParameters.Insert(Property.Name, XDTOExchangeParameters[Property.Name]); 
		EndDo;
		
		Settings.Insert("ExchangeFormat", XDTOExchangeParameters["ФорматОбмена"]); // @Non-NLS-2
		
	EndIf;
	
	If Factory.Properties().Get("УчетнаяЗаписьЭлектроннойПочты") <> Undefined Then // @Non-NLS
		
		StandardAttributes = New Structure;
		StandardAttributes.Insert("Description","Description");
		StandardAttributes.Insert("PredefinedDataName","PredefinedDataName");
		
		StructureOfAccount = New Structure;
		
		PropertyName = Factory["УчетнаяЗаписьЭлектроннойПочты"].Properties()[0].Name; // @Non-NLS
		XDTOAccount = Factory["УчетнаяЗаписьЭлектроннойПочты"][PropertyName]; // @Non-NLS
		
		Dictionary = DictionaryForAccount("en");
		
		For Each Property In XDTOAccount.Properties() Do
			
			Var_Key = Property.Name;
			
			If StandardAttributes.Property(Var_Key) Then
				Var_Key = StandardAttributes[Var_Key];
			EndIf;
			
			If Metadata.ScriptVariant = Metadata.ObjectProperties.ScriptVariant.English Then
				If Dictionary.Get(Var_Key) <> Undefined Then
					Var_Key = Dictionary.Get(Var_Key);
				Else
					Continue;
				EndIf;
			EndIf;
			
			StructureOfAccount.Insert(Var_Key, XDTOAccount[Property.Name]);
			
		EndDo;
		
		CatalogName = "EmailAccounts";
		Manager = Common.ObjectManagerByFullName("Catalog." + CatalogName);
		EmailAccount = Manager.CreateItem();
		EmailAccount.Description = StructureOfAccount.Description;
		If StructureOfAccount.Property("PredefinedDataName") Then
			EmailAccount.PredefinedDataName = StructureOfAccount.PredefinedDataName;
		EndIf;
		
		For Each Attribute In Metadata.Catalogs[CatalogName].Attributes Do
			
			If Not StructureOfAccount.Property(Attribute.Name) Then
				Continue;
			EndIf;
			
			EmailAccount[Attribute.Name] = StructureOfAccount[Attribute.Name];
			
		EndDo;

		If Common.SubsystemExists("StandardSubsystems.EmailOperations") Then
			
			ModuleEmailOperationsInternal = Common.CommonModule("EmailOperationsInternal");
			
			ThisInfobaseAccount = ModuleEmailOperationsInternal.ThisInfobaseAccountByCorrespondentAccountData(
				EmailAccount);
				
			TransportSettings.Insert("Account", ThisInfobaseAccount.Ref);
			
		EndIf;
		
	EndIf;
	
	Settings.Insert("TransportSettings", TransportSettings);
		
	Return Settings;
	
EndFunction

Function DictionaryForAccount(DirectionOfTranslation = "en")
	
	Dictionary = New Map;
	
	Dictionary.Insert("Email", "Email");
	Dictionary.Insert("Timeout", "Timeout");
	Dictionary.Insert("UserName", "UserName");
	Dictionary.Insert("UseForSending", "UseForSending");
	Dictionary.Insert("UseForReceiving", "UseForReceiving");
	Dictionary.Insert("UseSecureConnectionForIncomingMail", "UseSecureConnectionForIncomingMail");
	Dictionary.Insert("UseSecureConnectionForOutgoingMail", "UseSecureConnectionForOutgoingMail");
	Dictionary.Insert("KeepMessageCopiesAtServer", "KeepMessageCopiesAtServer");
	Dictionary.Insert("KeepMailAtServerPeriod", "KeepMailAtServerPeriod");
	Dictionary.Insert("User", "User");
	Dictionary.Insert("SMTPUser", "SMTPUser");
	Dictionary.Insert("IncomingMailServerPort", "IncomingMailServerPort");
	Dictionary.Insert("OutgoingMailServerPort", "OutgoingMailServerPort");
	Dictionary.Insert("ProtocolForIncomingMail", "ProtocolForIncomingMail");
	Dictionary.Insert("IncomingMailServer", "IncomingMailServer");
	Dictionary.Insert("OutgoingMailServer", "OutgoingMailServer");
	Dictionary.Insert("SignInBeforeSendingRequired", "SignInBeforeSendingRequired");
	Dictionary.Insert("SendBCCToThisAddress", "SendBCCToThisAddress");
	Dictionary.Insert("AccountOwner", "AccountOwner");
	Dictionary.Insert("AuthorizationRequiredOnSendEmails", "AuthorizationRequiredOnSendEmails");
	Dictionary.Insert("EmailServiceAuthorization", "EmailServiceAuthorization");
	Dictionary.Insert("EmailServiceName", "EmailServiceName");
	
	If DirectionOfTranslation = "en" Then
		
		Return Dictionary;
		
	ElsIf DirectionOfTranslation = "ru" Then
		
		NewDictionary = New Map;
		For Each KeyAndValue In Dictionary Do
			NewDictionary.Insert(KeyAndValue.Value, KeyAndValue.Key);
		EndDo;
		
		Return NewDictionary;
		
	EndIf;
	
EndFunction

Function ConnectionSettingsINJSONGeneral(ConnectionSettings)

	Result = New Structure;
	
	// Main exchange parameters
	MainParameters = New Structure;
	
	NodeAttributes = Common.ObjectAttributesValues(
		ConnectionSettings.InfobaseNode, "Code,ReceivedNo,SentNo");
		
	ExchangePlanName = DataExchangeFormatTranslationCached.BroadcastName(ConnectionSettings.ExchangePlanName, "en");
	CorrespondentExchangePlanName = DataExchangeFormatTranslationCached.BroadcastName(
		ConnectionSettings.CorrespondentExchangePlanName, "en");
	
	MainParameters.Insert("FormatVersion", VersionOfJSONDataExchangeSettingsFormat());
	MainParameters.Insert("SourceInfobasePrefix", ConnectionSettings.SourceInfobasePrefix);
	MainParameters.Insert("DestinationInfobasePrefix", ConnectionSettings.DestinationInfobasePrefix);
	MainParameters.Insert("NodeCode", ConnectionSettings.NodeCode);
	MainParameters.Insert("CorrespondentNodeCode", ConnectionSettings.CorrespondentNodeCode);
	MainParameters.Insert("ExchangePlanName", ExchangePlanName);
	MainParameters.Insert("CorrespondentExchangePlanName", CorrespondentExchangePlanName);
	MainParameters.Insert("ThisInfobaseDescription", ConnectionSettings.ThisInfobaseDescription);
	MainParameters.Insert("SecondInfobaseDescription", ConnectionSettings.SecondInfobaseDescription);
	MainParameters.Insert("ExchangeSetupOption", ConnectionSettings.ExchangeSetupOption);
	MainParameters.Insert("TransportID", ConnectionSettings.TransportID);
	MainParameters.Insert("SentNo", NodeAttributes.SentNo);
	MainParameters.Insert("ReceivedNo", NodeAttributes.ReceivedNo);
		
	Result.Insert("MainExchangeParameters", MainParameters);
	
	// XDTOExchangeParameters
	If DataExchangeCached.IsXDTOExchangePlan(ConnectionSettings.ExchangePlanName) Then
		
		ExchangeFormatVersions = DataExchangeServer.ExchangePlanSettingValue(ConnectionSettings.ExchangePlanName, "ExchangeFormatVersions");
		ExchangeFormatVersions = Common.UnloadColumn(ExchangeFormatVersions, "Key", True);
		
		MainParameters.Insert("ExchangeFormatVersions", ExchangeFormatVersions);
		
		XDTOExchangeParameters = New Structure;
		XDTOExchangeParameters.Insert("ExchangeFormat", ConnectionSettings.ExchangeFormat);
		
		Result.Insert("XDTOExchangeParameters", XDTOExchangeParameters);

		If ConnectionSettings.SupportedObjectsInFormat <> Undefined Then 
			
			Array = ArrayFromTable_SupportedObjectsInFormat(
				ConnectionSettings.SupportedObjectsInFormat.Get(), 
				ExchangeFormatVersions);
			
			Result.Insert("SupportedObjectsInFormat", Array);
			
		EndIf;
		
	EndIf;
	
	Return Result; 
	
EndFunction

Function ArrayFromTable_SupportedObjectsInFormat(Table, ExchangeFormatVersions) Export
	
	ObjectsTable = Table.Copy(,"Object");
	ObjectsTable.GroupBy("Object");
	
	Result = New Array;
		
	For Each String In ObjectsTable Do
		
		StringStructure = New Structure;
		StringStructure.Insert("Object", String.Object);
		StringStructure.Insert("Receive", New Array);
		StringStructure.Insert("Send", New Array);
		
		Filter = New Structure("Object", String.Object);
		SearchResult = Table.FindRows(Filter);
		
		For Each Ellie In SearchResult Do
			
			If Ellie.Receive Then
				StringStructure.Send.Add(Ellie.Version);
			EndIf;
			
			If Ellie.Send Then
				StringStructure.Receive.Add(Ellie.Version);
			EndIf;
			
		EndDo;
		
		If StringStructure.Send.Count() = ExchangeFormatVersions.Count() Then
			StringStructure.Send =  "*";
		EndIf;
		
		If StringStructure.Receive.Count() = ExchangeFormatVersions.Count() Then
			StringStructure.Receive =  "*";
		EndIf;
		
		Result.Add(StringStructure);
		
	EndDo;
	
	Return Result;
	
EndFunction

Function TableFromArray_SupportedObjectsInFormat(Array, ExchangeFormatVersions) Export

	Result = New ValueTable;
	Result.Columns.Add("Version");
	Result.Columns.Add("Object");
	Result.Columns.Add("Send");
	Result.Columns.Add("Receive");
	
	For Each Ellie In Array Do
		
		Object = Ellie["Object"];
		
		SendingVersion = Ellie["Send"];
		If SendingVersion = "*" Then
			SendingVersion = ExchangeFormatVersions;
		EndIf;
		
		For Each Version In SendingVersion Do
			
			NewRow = Result.Add();
			NewRow.Version = Version;
			NewRow.Object = Object;
			NewRow.Send = True;
			NewRow.Receive = False;
			
		EndDo;
		
		GettingVersion = Ellie["Receive"];
		If GettingVersion = "*" Then
			GettingVersion = ExchangeFormatVersions;
		EndIf;
		
		For Each Version In GettingVersion Do
			
			Filter = New Structure("Object, Version", Object, Version);
			SearchResult = Result.FindRows(Filter);
			
			If SearchResult.Count() = 0 Then
				
				NewRow = Result.Add();
				NewRow.Version = Version;
				NewRow.Object = Object;
				NewRow.Send = False;
				NewRow.Receive = True;
				
			Else
				
				SearchResult[0].Receive = True;
				
			EndIf;
			
		EndDo;
		
	EndDo;

	Return Result;
	
EndFunction

Procedure AddXMLRecord(XMLWriter, Value, FullName) Export
	
	WriteXML(XMLWriter, Value, FullName, XMLTypeAssignment.Explicit);
	
EndProcedure

Procedure CopyStructureValue(Source, KeySource, Receiver, KeyDestination = Undefined) Export
	
	If KeyDestination = Undefined Then
		KeyDestination = KeySource;
	EndIf;
	
	If Source.Property(KeySource) Then
		Value = Source[KeySource];
	Else
		Value = Undefined;
	EndIf;
	
	Receiver.Insert(KeyDestination, Value);
	
EndProcedure

Function VersionOfXMLDataExchangeSettingsFormat() Export
	
	Return "1.2";
	
EndFunction

Function VersionOfJSONDataExchangeSettingsFormat()
	
	Return "2.0";
	
EndFunction

Procedure WriteXDTOExchangeParameters(XMLWriter, ExchangePlanName) Export
	
	XMLWriter.WriteStartElement("ПараметрыОбменаXDTO"); // @Non-NLS
	
	ExchangeFormat = DataExchangeServer.ExchangePlanSettingValue(ExchangePlanName, "ExchangeFormat");
	
	WriteXML(XMLWriter, ExchangeFormat, "ФорматОбмена", XMLTypeAssignment.Explicit); // @Non-NLS
	
	XMLWriter.WriteEndElement(); // XDTOExchangeParameters
	
EndProcedure

#Region OnConnectToCorrespondent

Procedure OnConnectToCorrespondent(Cancel, ExchangePlanName, Val CorrespondentVersion, ErrorMessage = "") Export
	
	If Not ValueIsFilled(CorrespondentVersion) Then
		CorrespondentVersion = "0.0.0.0";
	EndIf;
	
	Try
	
		If Not DataExchangeServer.HasExchangePlanManagerAlgorithm("OnConnectToCorrespondent", ExchangePlanName) Then
			Return;
		ElsIf IsBlankString(CorrespondentVersion) Then
			CorrespondentVersion = "0.0.0.0";
		EndIf;
		
		ExchangePlans[ExchangePlanName].OnConnectToCorrespondent(CorrespondentVersion);
	
	Except
		
		DetailErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		MessageTemplate = NStr("vi = 'Khi thực hiện hàm sự kiện ПриПодключенииККорреспонденту đã xảy ra lỗi:%1%2';
								|ru = 'При выполнении обработчика ПриПодключенииККорреспонденту произошла ошибка:%1%2';
								|en = 'Event handler error: OnConnectToCorrespondent. Details: %1%2'; fa = 'Event handler error: OnConnectToCorrespondent. Details: %1%2';
								|it = 'Durante l''esecuzione di gestore ПриПодключенииККорреспонденту si è verificato un errore:%1%2';
								|pl = 'Podczas wykonywania obsługi PodczasPołączeniaDoKorespondenta wystąpił błąd:%1%2';
								|tr = 'ПриПодключенииККорреспонденту işleyicisini yürütürken hata oluştu:%1%2'");
		ErrorMessage = StrTemplate(MessageTemplate, Chars.LF, DetailErrorDescription);
		
		WriteLogEvent(DataExchangeServer.DataExchangeCreationEventLogEvent(),
			EventLogLevel.Error, , , ErrorMessage);
		
		Cancel = True;
		
	EndTry;
	
EndProcedure

Procedure CheckForDuplicateSyncs(ExchangePlanName, CorrespondentParameters, Result) Export
	
	ManagerExchangePlan = ExchangePlans[ExchangePlanName];
	ThisNode = ManagerExchangePlan.ThisNode();
	If DataExchangeServer.IsXDTOExchangePlan(ThisNode)
		And DataExchangeXDTOServer.VersionWithDataExchangeIDSupported(ThisNode) Then
		
		NodeRef1 = ManagerExchangePlan.FindByCode(CorrespondentParameters.ThisNodeCode);
		
		If Not NodeRef1.IsEmpty() Then
			Result.ThisInfobaseHasPeerInfobaseNode = True;
			Result.NodeToDelete = NodeRef1;
		EndIf;
		
		Result.ThisNodeExistsInPeerInfobase = CorrespondentParameters.NodeExists;
		
	EndIf;
	
EndProcedure

// Gets proxy server settings.
//
Function ProxyServerSettings(SecureConnection)
	
	Proxy = Undefined;
	If Common.SubsystemExists("StandardSubsystems.GetFilesFromInternet") Then
		ModuleNetworkDownload = Common.CommonModule("GetFilesFromInternet");
		Protocol = ?(SecureConnection = Undefined, "ftp", "ftps");
		Proxy = ModuleNetworkDownload.GetProxy(Protocol);
	EndIf;
	
	Return Proxy;
	
EndFunction

#EndRegion

Function VerifyAuthentication(Peer, TransportID, TransportSettings, AuthenticationData) Export
	
	Parameters = InitializationParameters();

	If TypeOf(Peer) = Type("String") Then
		Parameters.ExchangePlanName = Peer;
	Else
		Parameters.Peer = Peer;
	EndIf;
	
	Parameters.TransportID = TransportID;
	Parameters.TransportSettings = TransportSettings;
	Parameters.AuthenticationData = AuthenticationData;
	
	Transport = Initialize(Parameters);
		
	If Transport.ConnectionIsSet() Then
		
		Return True;
		
	Else
		
		Raise Transport.ErrorMessage;
		
	EndIf;
	
EndFunction

// Validates required transport settings attributes.
//
// Parameters:
//  Setting - Structure - Values of transport settings attributes.
//  TransportManager - Arbitrary - Transport manager. See ExchangeMessagesTransport.TransportManagerById().
//
// Returns:
//   Boolean - True if all required attributes are filled.
//
Function RequiredAttributesOfSettingsAreFilledIn(Setting, TransportManager)
	
	If Not Setting.Count() Then
		Return False;
	EndIf;
	
	SettingFilledIn = True;
	
	If TransportManager = TransportManagerCOM() Then
		SettingFilledIn = RequiredAttributesForCOMTransportSettingsHaveBeenFilledIn(Setting);
	Else
		RequiredDetails_ = RequiredAttributesOfTransports();
		
		RequiredTransportAttributes = RequiredDetails_.Get(TransportManager);
		
		If RequiredTransportAttributes <> Undefined Then
			For Each SettingsDetails In RequiredTransportAttributes Do
				If Setting.Property(SettingsDetails) Then
					If Not ValueIsFilled(Setting[SettingsDetails]) Then
						SettingFilledIn = False;
						Break;
					EndIf;
				EndIf;
			EndDo;	
		EndIf;
	EndIf;
	
	Return SettingFilledIn;
	
EndFunction

// Validates required COM transport settings attributes.
//
// Parameters:
//  Setting - Structure - Values of transport settings attributes.
//
// Returns:
//   Boolean - True if all required attributes are filled.
//
Function RequiredAttributesForCOMTransportSettingsHaveBeenFilledIn(Setting)
	
	SettingFilledIn = False;
	
	If Setting.InfobaseOperatingMode Then
		If ValueIsFilled(Setting.NameOf1CEnterpriseServer) And ValueIsFilled(Setting.NameOfInfobaseOn1CEnterpriseServer) Then
			SettingFilledIn = True;
		EndIf;
	Else
		SettingFilledIn = ValueIsFilled(Setting.InfobaseDirectory);
	EndIf;
	
	Return SettingFilledIn;
	
EndFunction

// Returns a map with the required attributes
//
// Returns:
//  Map - 
//   * The key is arbitrary - for the transport manager, see the transportcommunication function of the exchange.Managertransport to identifiers;
//   * Value - Array - contains the names of the required Attributes;
//
Function RequiredAttributesOfTransports()
	
	RequiredAttributesForFilling = New Map;
	
	SettingsDetails_1 = New Array;
	SettingsDetails_1.Add("Account");
	RequiredAttributesForFilling.Insert(TransportManagerEMAIL(), SettingsDetails_1);
	
	SettingsDetails_1 = New Array;
	SettingsDetails_1.Add("SendingChannel");
	SettingsDetails_1.Add("ReceiptChannel");
	SettingsDetails_1.Add("RecipientCode");
	SettingsDetails_1.Add("IntegrationService");
	RequiredAttributesForFilling.Insert(TransportManagerESB1C(), SettingsDetails_1);
	
	SettingsDetails_1 = New Array;
	SettingsDetails_1.Add("DataExchangeDirectory");
	RequiredAttributesForFilling.Insert(TransportManagerFILE(), SettingsDetails_1);

	SettingsDetails_1 = New Array;
	SettingsDetails_1.Add("Path"); 
	SettingsDetails_1.Add("User");
	RequiredAttributesForFilling.Insert(TransportManagerFTP(), SettingsDetails_1); 
	
	SettingsDetails_1 = New Array;
	SettingsDetails_1.Add("ClientID");
	SettingsDetails_1.Add("ClientSecret");
	SettingsDetails_1.Add("AccessToken");
	SettingsDetails_1.Add("RefreshToken");
	RequiredAttributesForFilling.Insert(YandexDiskTransportManager(), SettingsDetails_1);
	
	SettingsDetails_1 = New Array;
	SettingsDetails_1.Add("ClientID");
	SettingsDetails_1.Add("ClientSecret");
	SettingsDetails_1.Add("AccessToken");
	SettingsDetails_1.Add("RefreshToken");
	RequiredAttributesForFilling.Insert(TransportManagerGoogleDrive(), SettingsDetails_1);
	
	SettingsDetails_1 = New Array;
	SettingsDetails_1.Add("WebServiceAddress");
	RequiredAttributesForFilling.Insert(TransportManagerWS(), SettingsDetails_1);
	
	SettingsDetails_1 = New Array;
	SettingsDetails_1.Add("WebServiceAddress");
	RequiredAttributesForFilling.Insert(TransportManagerHTTP(), SettingsDetails_1);

	SettingsDetails_1 = New Array;
	SettingsDetails_1.Add("PeerInfobaseName");
	SettingsDetails_1.Add("CorrespondentEndpoint");
	RequiredAttributesForFilling.Insert(TransportManagerSM(), SettingsDetails_1);
	
	SettingsDetails_1 = New Array;
	RequiredAttributesForFilling.Insert(TransportManagerPassiveMode(), SettingsDetails_1);
	
	Return RequiredAttributesForFilling;
	
EndFunction

// Converts a setting into a structure.
// 
// Parameters:
//  Setting - QueryResult, Structure - Values of transport settings attributes. 
//
// Returns:
//  Structure - Values of settings attribute.
//
Function SettingUpTransportInStructure(Setting)
	
	If TypeOf(Setting) = Type("QueryResult") Then
		Result = New Structure;
		
		Selection = Setting.Select();
		
		While Selection.Next() Do
			Result.Insert(Selection.Setting, Selection.Value);
		EndDo;
	Else
		Result = Setting;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion
