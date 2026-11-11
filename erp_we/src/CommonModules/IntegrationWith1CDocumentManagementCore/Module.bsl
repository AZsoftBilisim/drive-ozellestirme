////////////////////////////////////////////////////////////////////////////////
// Subsystem "Integration with 1C:Document management"
// Module integration1sdocumentworkingbazofunctionality: server, external connection
////////////////////////////////////////////////////////////////////////////////

#Region Public

#Region AsynchronousOperations

// executes a request to the 1C service:Workflow in the background task.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   Query - XDTODataObject - the request being executed.
//   FormUniqueID - UUID - ID of the calling form.
//   BackgroundJobDescription - String - a representation of a long-running operation that will be displayed in the interface.
//
// Returns:
//   See TimeConsumingOperations.ExecuteInBackground
//
Function ExecuteRequestAsynchronously(Proxy, Query, FormUniqueID, BackgroundJobDescription = "") Export
	
	TimeConsumingOperationParameters = TimeConsumingOperationParameters();
	TimeConsumingOperationParameters.Insert(
		"Query_String",
		XDTOObjectInString(Proxy, Query));
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(FormUniqueID);
	ExecutionParameters.WaitCompletion = 0; // Start immediately.
	If ValueIsFilled(BackgroundJobDescription) Then
		ExecutionParameters.BackgroundJobDescription = BackgroundJobDescription;
	EndIf;
	
	Return TimeConsumingOperations.ExecuteInBackground(
		"IntegrationWith1CDocumentManagementCore.MakeRequestInBackground",
		TimeConsumingOperationParameters,
		ExecutionParameters);
	
EndFunction

// executes a request to the 1C service:Workflow from a background task.
//
// Parameters:
//   Parameters - Structure:
//     * IntegrationWith1CDocumentManagementWSDefinitions - ValueStorage
//     * IntegrationWith1CDocumentManagementServiceVersion - String
//     * IntegrationWith1CDocumentManagementUsername - String
//     * IntegrationWith1CDocumentManagementJWTTokenAuthenticationIsUsed - Boolean
//     * IntegrationWith1CDocumentManagementOSAuthenticationIsUsed - Boolean
//     * IntegrationWith1CDocumentManagementProxyServerLocation - String
//     * IntegrationWith1CDocumentManagementPassword - String
//     * IntegrationWith1CDocumentManagementPasswordIsKnown - Boolean
//     * Query_String - String
//   StorageAddress - String - the address of the repository where the request result will be placed.
//
Procedure MakeRequestInBackground(Parameters, StorageAddress) Export
	
	Proxy = GetProxyInBackground(Parameters);
	
	Try
		Response = ExecuteQuery(Proxy, StringInXDTOObject(Proxy, Parameters.Query_String));
	Except
		PutToTempStorage(ServiceVersion(), StorageAddress);
		Raise;
	EndTry;
	
	PutToTempStorage(XDTOObjectInString(Proxy, Response), StorageAddress);
	
EndProcedure

// executes a batch request to the 1C service:Workflow in the background task.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   Queries - Array of XDTODataObject - package requests.
//   FormUniqueID - UUID - ID of the calling form.
//   BackgroundJobDescription - String - a representation of a long-running operation that will be displayed in the interface.
//   CheckSubordinates - Boolean - specifies whether to check the results of queries included in the package.
//
// Returns:
//   See TimeConsumingOperations.ExecuteInBackground
//
Function ExecuteBatchRequestAsynchronously(Proxy, Queries, FormUniqueID, BackgroundJobDescription = "",
		CheckSubordinates = False) Export
	
	TimeConsumingOperationParameters = TimeConsumingOperationParameters();
	StringRequests = New Array;
	For Each Query In Queries Do
		StringRequests.Add(XDTOObjectInString(Proxy, Query));
	EndDo;
	TimeConsumingOperationParameters.Insert("StringRequests", StringRequests);
	TimeConsumingOperationParameters.Insert("CheckSubordinates", CheckSubordinates);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(FormUniqueID);
	ExecutionParameters.WaitCompletion = 0; // Start immediately.
	If ValueIsFilled(BackgroundJobDescription) Then
		ExecutionParameters.BackgroundJobDescription = BackgroundJobDescription;
	EndIf;
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(
		"IntegrationWith1CDocumentManagementCore.ExecuteBatchRequestInBackground",
		TimeConsumingOperationParameters,
		ExecutionParameters);
	
	Return TimeConsumingOperation;
	
EndFunction

// executes a request to the 1C service:Workflow from a background task.
//
// Parameters:
//   Parameters - Structure:
//     * IntegrationWith1CDocumentManagementWSDefinitions - ValueStorage
//     * IntegrationWith1CDocumentManagementServiceVersion - String
//     * IntegrationWith1CDocumentManagementUsername - String
//     * IntegrationWith1CDocumentManagementJWTTokenAuthenticationIsUsed - Boolean
//     * IntegrationWith1CDocumentManagementOSAuthenticationIsUsed - Boolean
//     * IntegrationWith1CDocumentManagementProxyServerLocation - String
//     * IntegrationWith1CDocumentManagementPassword - String
//     * IntegrationWith1CDocumentManagementPasswordIsKnown - Boolean
//     * StringRequests - Array of String
//     * CheckSubordinates - Boolean
//   StorageAddress - String - the address of the repository where the request result will be placed.
//
Procedure ExecuteBatchRequestInBackground(Parameters, StorageAddress) Export
	
	Proxy = GetProxyInBackground(Parameters);
	
	Queries = New Array;
	For Each Query_String In Parameters.StringRequests Do
		Queries.Add(StringInXDTOObject(Proxy, Query_String));
	EndDo;
	
	Try
		Response = ExecuteBatchRequest(Proxy, Queries, Parameters.CheckSubordinates);
	Except
		PutToTempStorage(ServiceVersion(), StorageAddress);
		Raise;
	EndTry;
	
	PutToTempStorage(XDTOObjectInString(Proxy, Response), StorageAddress);
	
EndProcedure

// Records changes to the object in the Workflow in the background job.
//
// Parameters:
//   Parameters - Structure:
//     * IntegrationWith1CDocumentManagementWSDefinitions - ValueStorage
//     * IntegrationWith1CDocumentManagementServiceVersion - String
//     * IntegrationWith1CDocumentManagementUsername - String
//     * IntegrationWith1CDocumentManagementJWTTokenAuthenticationIsUsed - Boolean
//     * IntegrationWith1CDocumentManagementOSAuthenticationIsUsed - Boolean
//     * IntegrationWith1CDocumentManagementProxyServerLocation - String
//     * IntegrationWith1CDocumentManagementPassword - String
//     * IntegrationWith1CDocumentManagementPasswordIsKnown - Boolean
//     * RowObject - String - string Presentation of the XDTO object with stored data.
//   StorageAddress - String - the address of the repository where the request result will be placed.
//
Procedure RecordObjectInBackground(Parameters, StorageAddress) Export
	
	Proxy = GetProxyInBackground(Parameters);
	
	Try
		RecordingResult = WriteObject(
			Proxy,
			StringInXDTOObject(Proxy, Parameters.RowObject));
	Except
		PutToTempStorage(ServiceVersion(), StorageAddress);
		Raise;
	EndTry;
	
	PutToTempStorage(XDTOObjectInString(Proxy, RecordingResult), StorageAddress);
	
EndProcedure

// Converts an XDTO object from a namespace "http://www.1c.ru/dm " in line.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   XDTODataObject - XDTODataObject, XDTOList - the XDTO xml object whose representation you want to get.
//
// Returns:
//   String
//
Function XDTOObjectInString(Proxy, XDTODataObject) Export
	
	Result = New Array;
	
	If TypeOf(XDTODataObject) = Type("XDTOList") Then
		ListOfObjects = XDTODataObject;
	Else
		ListOfObjects = CommonClientServer.ValueInArray(XDTODataObject);
	EndIf;
	
	DMFactory = DMFactory(Proxy);
	XMLWriter = New XMLWriter;
	For Each Object In ListOfObjects Do
		XMLWriter.SetString();
		DMFactory.WriteXML(XMLWriter, Object);
		Result.Add(XMLWriter.Close());
	EndDo;
	XMLWriter = Undefined;
	
	Return StrConcat(Result, SeparatorForListItems());
	
EndFunction

// returns the structure of parameters for accessing the 1C service:Workflow in the background task.
//
// Parameters:
//   UseCache - Boolean - when checking the possibility of authorization without a password, you do not need to use a cache.
//   AddressOfDocumentManagementWebService - String - the address of the web service BEFORE, or
//                                   - Undefined - indicates the need to use a previously saved address.
//
// Returns:
//   Structure:
//     * AddressOfDocumentManagementWebService - Undefined
//     * IntegrationWith1CDocumentManagementWSDefinitions - ValueStorage
//     * IntegrationWith1CDocumentManagementServiceVersion - String
//     * IntegrationWith1CDocumentManagementUsername - String
//     * IntegrationWith1CDocumentManagementJWTTokenAuthenticationIsUsed - Boolean
//     * IntegrationWith1CDocumentManagementOSAuthenticationIsUsed - Boolean
//     * IntegrationWith1CDocumentManagementProxyServerLocation - String
//     * IntegrationWith1CDocumentManagementPassword - String
//     * IntegrationWith1CDocumentManagementPasswordIsKnown - Boolean
//     * IntegrationWith1CDocumentManagementNode - String
//
Function TimeConsumingOperationParameters(UseCache = True, AddressOfDocumentManagementWebService = Undefined) Export
	
	OperationParametersList = New Structure;
	
	OperationParametersList.Insert("AddressOfDocumentManagementWebService", AddressOfDocumentManagementWebService);
	
	OperationParametersList.Insert("IntegrationWith1CDocumentManagementWSDefinitions", New ValueStorage(Undefined));
	OperationParametersList.Insert("IntegrationWith1CDocumentManagementServiceVersion", "");
	OperationParametersList.Insert("IntegrationWith1CDocumentManagementUsername", "");
	OperationParametersList.Insert("IntegrationWith1CDocumentManagementJWTTokenAuthenticationIsUsed", False);
	OperationParametersList.Insert("IntegrationWith1CDocumentManagementOSAuthenticationIsUsed", False);
	OperationParametersList.Insert("IntegrationWith1CDocumentManagementProxyServerLocation", "");
	OperationParametersList.Insert("IntegrationWith1CDocumentManagementPassword", "");
	OperationParametersList.Insert("IntegrationWith1CDocumentManagementPasswordIsKnown", False);
	OperationParametersList.Insert("IntegrationWith1CDocumentManagementNode", "");
	
	If UseCache Then
		OperationParametersList.IntegrationWith1CDocumentManagementWSDefinitions = SessionParameters.IntegrationWith1CDocumentManagementWSDefinitions;
		OperationParametersList.IntegrationWith1CDocumentManagementServiceVersion = SessionParameters.IntegrationWith1CDocumentManagementServiceVersion;
		OperationParametersList.IntegrationWith1CDocumentManagementUsername = SessionParameters.IntegrationWith1CDocumentManagementUsername;
		OperationParametersList.IntegrationWith1CDocumentManagementJWTTokenAuthenticationIsUsed = SessionParameters.IntegrationWith1CDocumentManagementJWTTokenAuthenticationIsUsed;
		OperationParametersList.IntegrationWith1CDocumentManagementOSAuthenticationIsUsed = SessionParameters.IntegrationWith1CDocumentManagementOSAuthenticationIsUsed;
		OperationParametersList.IntegrationWith1CDocumentManagementProxyServerLocation = SessionParameters.IntegrationWith1CDocumentManagementProxyServerLocation;
		OperationParametersList.IntegrationWith1CDocumentManagementPassword = SessionParameters.IntegrationWith1CDocumentManagementPassword;
		OperationParametersList.IntegrationWith1CDocumentManagementPasswordIsKnown = SessionParameters.IntegrationWith1CDocumentManagementPasswordIsKnown;
		OperationParametersList.IntegrationWith1CDocumentManagementNode = SessionParameters.IntegrationWith1CDocumentManagementNode;
	EndIf;
	
	Return OperationParametersList;
	
EndFunction

// connects to the 1C service:Workflow from the background task, and makes a request for the service version.
//
// Parameters:
//   Parameters - See IntegrationWith1CDocumentManagementCore.TimeConsumingOperationParameters
//   StorageAddress - String - the address of the repository where the request result will be placed.
//
Procedure ConnectAndGetServiceVersionInBackground(Parameters, StorageAddress = "") Export
	
	ParametersOfLongTermOperationInSessionParameters(Parameters);
	
	If Not IntegrationWith1CDocumentManagementCoreCached.IsBackgroundJob() Then
		IntegrationWith1CDocumentManagementCoreServerCall.ResetInternetConnectionCache();
	EndIf;
	
	InstallServiceVersion(True,, Parameters.AddressOfDocumentManagementWebService);
	PutToTempStorage(TimeConsumingOperationParameters(), StorageAddress);
	
EndProcedure

// Retrieves an object from the Workflow in the background task.
//
// Parameters:
//   Parameters - Structure:
//     * IntegrationWith1CDocumentManagementWSDefinitions - ValueStorage
//     * IntegrationWith1CDocumentManagementServiceVersion - String
//     * IntegrationWith1CDocumentManagementUsername - String
//     * IntegrationWith1CDocumentManagementJWTTokenAuthenticationIsUsed - Boolean
//     * IntegrationWith1CDocumentManagementOSAuthenticationIsUsed - Boolean
//     * IntegrationWith1CDocumentManagementProxyServerLocation - String
//     * IntegrationWith1CDocumentManagementPassword - String
//     * IntegrationWith1CDocumentManagementPasswordIsKnown - Boolean
//     * Type - String
//     * ID - String
//     * Columns - Array of String - optional, the composition of the columns to be filled in.
//               - String - if the list of columns is separated by commas.
//     * IntegrationRule - CatalogRef.RulesForIntegrationWith1CDocumentManagement3 - integration rule for
//         filling in the IP object.
//     * ExternalIPObject - AnyRef - passed to fill in the externalObject property.
//   StorageAddress - String - the address of the repository where the request result will be placed.
//
Procedure GetObjectInBackground(Parameters, StorageAddress) Export
	
	Proxy = GetProxyInBackground(Parameters);
	
	Try
		XDTODataObject = GetObject(
			Proxy,
			Parameters.Type,
			Parameters.ID,
			Parameters.Columns,
			Parameters.IntegrationRule,
			Parameters.ExternalIPObject);
	Except
		PutToTempStorage(ServiceVersion(), StorageAddress);
		Raise;
	EndTry;
	
	PutToTempStorage(XDTOObjectInString(Proxy, XDTODataObject), StorageAddress);
	
EndProcedure

// Creates a proxy for the Workflow web service in the background job, with the settings passed directly.
//
// Parameters:
//   Parameters - Structure:
//     * IntegrationWith1CDocumentManagementWSDefinitions - ValueStorage
//     * IntegrationWith1CDocumentManagementServiceVersion - String
//     * IntegrationWith1CDocumentManagementUsername - String
//     * IntegrationWith1CDocumentManagementJWTTokenAuthenticationIsUsed - Boolean
//     * IntegrationWith1CDocumentManagementOSAuthenticationIsUsed - Boolean
//     * IntegrationWith1CDocumentManagementProxyServerLocation - String
//     * IntegrationWith1CDocumentManagementPassword - String
//     * IntegrationWith1CDocumentManagementPasswordIsKnown - Boolean
//
// Returns:
//   WSProxy - proxy of the Document management web service.
//   Undefined - in case the proxy of the web service could not be obtained.
//
Function GetProxyInBackground(Parameters) Export
	
	ParametersOfLongTermOperationInSessionParameters(Parameters);
	
	Return GetProxyFromSessionParameters();
	
EndFunction

// Converts a string to an XDTO object from a namespace "http://www.1c.ru/dm ".
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   String - String - xml representation of the XDTO object.
//
// Returns:
//   XDTODataObject
//   Array of ObjectXDTO
//
Function StringInXDTOObject(Proxy, String) Export
	
	Result = New Array;
	
	ListOfObjects = StringFunctionsClientServer.SplitStringIntoSubstringsArray(String, SeparatorForListItems());
	
	DMFactory = DMFactory(Proxy);
	XMLReader = New XMLReader;
	For Each Object In ListOfObjects Do
		XMLReader.SetString(Object);
		XMLReader.Read();
		XDTOType = DMFactory.Type(URIOfNamespaceOfWorkflowWebService(), XMLReader.Name);
		Result.Add(DMFactory.ReadXML(XMLReader, XDTOType));
	EndDo;
	XMLReader = Undefined;
	
	If Result.Count() = 1 Then
		Return Result[0];
	Else
		Return Result;
	EndIf;
	
EndFunction

#EndRegion

#Region InterfaceImplementation

#Region StandardSubsystems_BasicFunctionality

// See CommonOverridable.OnAddSessionParameterSettingHandlers
Procedure OnAddSessionParameterSettingHandlers(Handlers) Export
	
	Handlers.Insert("IntegrationWith1CDocumentManagementWSDefinitions",
		"IntegrationWith1CDocumentManagementCore.SetSessionParameters");
	
	Handlers.Insert("IntegrationWith1CDocumentManagementServiceVersion",
		"IntegrationWith1CDocumentManagementCore.SetSessionParameters");
	
	Handlers.Insert("IntegrationWith1CDocumentManagementUsername",
		"IntegrationWith1CDocumentManagementCore.SetSessionParameters");
	
	Handlers.Insert("IntegrationWith1CDocumentManagementJWTTokenAuthenticationIsUsed",
		"IntegrationWith1CDocumentManagementCore.SetSessionParameters");
	
	Handlers.Insert("IntegrationWith1CDocumentManagementOSAuthenticationIsUsed",
		"IntegrationWith1CDocumentManagementCore.SetSessionParameters");
	
	Handlers.Insert("IntegrationWith1CDocumentManagementProxyServerLocation",
		"IntegrationWith1CDocumentManagementCore.SetSessionParameters");
	
	Handlers.Insert("IntegrationWith1CDocumentManagementSettings",
		"IntegrationWith1CDocumentManagementCore.SetSessionParameters");
	
	Handlers.Insert("IntegrationWith1CDocumentManagementConnectingOperation",
		"IntegrationWith1CDocumentManagementCore.SetSessionParameters");
	
	Handlers.Insert("IntegrationWith1CDocumentManagementPassword",
		"IntegrationWith1CDocumentManagementCore.SetSessionParameters");
	
	Handlers.Insert("IntegrationWith1CDocumentManagementPasswordIsKnown",
		"IntegrationWith1CDocumentManagementCore.SetSessionParameters");
	
	Handlers.Insert("Integration1CDocumentManagementXMLSchema",
		"IntegrationWith1CDocumentManagementCore.SetSessionParameters");
	
	Handlers.Insert("IntegrationWith1CDocumentManagementCurrentUser",
		"IntegrationWith1CDocumentManagementCore.SetSessionParameters");
	
	Handlers.Insert("IntegrationWith1CDocumentManagementNode",
		"IntegrationWith1CDocumentManagementCore.SetSessionParameters");
	
EndProcedure

// See StandardSubsystemsServer.OnDefineMethodsAllowedForCallAsArbitraryCode
Procedure OnDefineMethodsAllowedForCallAsArbitraryCode(Methods) Export
	
	Methods.Insert("MakeRequestInBackground", True);
	Methods.Insert("ExecuteDataExchange", True);
	Methods.Insert("ExecuteBatchRequestInBackground", True);
	Methods.Insert("RecordObjectInBackground", True);
	Methods.Insert("ConnectAndGetServiceVersionInBackground", True);
	Methods.Insert("GetObjectInBackground", True);
	
	Methods.Insert("SetSessionParameters");
	
EndProcedure

#EndRegion

#Region StandardSubsystems_Print

// See PrintManagementOverridable.BeforeAddPrintCommands
Procedure BeforeAddPrintCommands(FormName, PrintCommands, StandardProcessing) Export
	
	If Not UserIsAllowedToUseIntegration() Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreOverridable.BeforeAddPrintCommands(
		FormName,
		PrintCommands,
		StandardProcessing);
	
	Settings = IntegrationWith1CDocumentManagementCoreServerCall.UseIntegration();
	If PrintCommands.Count() > 0
			And (Settings.UseIntegrationBefore2 Or Settings.UseIntegrationBefore3) Then
		TimeConsumingOperationParameters = TimeConsumingOperationParameters();
		For Each PrintCommand In PrintCommands Do
			PrintCommand.AdditionalParameters.Insert(
				"IntegrationWith1CWorkflow_ParametersOfOperation",
				TimeConsumingOperationParameters);
			PrintCommand.AdditionalParameters.Insert(
				"AddExternalPrintFormsToSet",
				PrintCommand.AddExternalPrintFormsToSet);
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

#Region StandardSubsystems_PlugInCommands

// See GenerateFromOverridable.BeforeAddGenerationCommands
Procedure BeforeAddGenerationCommands(GenerationCommands, Parameters, StandardProcessing) Export
	
	For Each SourceType In Parameters.SourcesTypes Do
		If Not Metadata.DefinedTypes.IntegrationWith1CWorkflowAllLinksOverridable.Type.ContainsType(
				SourceType) Then
			Return;
		EndIf;
	EndDo;
	
	Order = 99;
	
	If ThereIsSubsystemUPTo2() Then
		AddGenerationCommand(
			GenerationCommands,
			Metadata.CommonCommands["IntegrationWith1CDocumentManagementCreateLetter"],
			"IntegrationWith1CDocumentManagementClient.ProcessingOutgoingMessageCommand",
			Parameters.KindInCase,
			"UseEmail1CDocumentManagement",
			Order,
			False);
		
		AddGenerationCommand(
			GenerationCommands,
			Metadata.CommonCommands["IntegrationWith1CDocumentManagementCreateBusinessProcess"],
			"IntegrationWith1CDocumentManagementClient.ProcessingCommandsCreateBusinessProcess",
			Parameters.KindInCase,
			"UseProcessesAndTasks1CDocumentManagement",
			Order,
			False);
	EndIf;
	
	If ThereIsSubsystemUPTo3() Then
		AddGenerationCommand(
			GenerationCommands,
			Metadata.CommonCommands["IntegrationWith1CDocumentManagementStartProcessing"],
			"IntegrationWith1CDocumentManagement3Client.ProcessingStartProcessingCommand",
			Parameters.KindInCase,
			"UseProcessingOf1CDocumentManagementObjects",
			Order,
			True);
	EndIf;
	
EndProcedure

#EndRegion

#Region StandardSubsystems_RoutineTasks

// See ScheduledJobsOverridable.OnDefineScheduledJobSettings
Procedure OnDefineScheduledJobSettings(Settings) Export
	
	FOList = New Array;
	If ThereIsSubsystemUPTo2() Then
		FOList.Add("UseIntegrationWith1CDocumentManagement");
	EndIf;
	If ThereIsSubsystemUPTo3() Then
		FOList.Add("UseIntegrationWith1CDocumentManagement3");
	EndIf;
	
	For Each FOName In FOList Do
		Setting = Settings.Add();
		Setting.ScheduledJob = Metadata.ScheduledJobs.ExchangeDataWith1CDocumentManagement;
		Setting.FunctionalOption = Metadata.FunctionalOptions[FOName];
		Setting.DependenceByT = False;
		Setting.EnableOnEnableFunctionalOption = False;
		Setting.AvailableInSubordinateDIBNode = False;
		Setting.AvailableAtStandaloneWorkstation = False;
		Setting.AvailableSaaS = True;
		Setting.UseExternalResources = True;
	EndDo;
	
EndProcedure

#EndRegion

#Region ServiceTechnology_TaskQueue

// See JobsQueueOverridable.OnDefineHandlerAliases
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export
	
	NamesAndAliasesMap.Insert(Metadata.ScheduledJobs.ExchangeDataWith1CDocumentManagement.MethodName);
	
EndProcedure

// See JobsQueueOverridable.OnGetTemplateList
Procedure OnGetTemplateList(JobTemplates) Export
	
	JobTemplates.Add(Metadata.ScheduledJobs.ExchangeDataWith1CDocumentManagement.Name);
	
EndProcedure

#EndRegion

#EndRegion

#Region DataExchange

// Performs data exchange with 1C:Document management according to the rules of integration.
//
Procedure ExecuteDataExchange() Export
	
	Common.OnStartExecuteScheduledJob(
		Metadata.ScheduledJobs.ExchangeDataWith1CDocumentManagement);
	
	Settings = IntegrationWith1CDocumentManagementCoreServerCall.UseIntegration();
	
	If Not Settings.UseIntegrationBefore2 And Not Settings.UseIntegrationBefore3 Then
		DocumentFlowNode = IntegrationWith1CDocumentManagementCoreCached.DocumentFlowNode();
		ExchangePlans.DeleteChangeRecords(DocumentFlowNode);
		Return;
	EndIf;
	
	// Let's read the authorization settings and set them in the session parameters. Constants may not be available.
	SetPrivilegedMode(True);
	UserName = Constants.IntegrationWith1CDocumentManagementUsernameForExchange.Get();
	Password = Constants.IntegrationWith1CDocumentManagementPasswordForExchange.Get();
	If Not ValueIsFilled(UserName) Then // let's read the settings from the user storage.
		
		PasswordIsSaved = False;
		IntegrationWith1CDocumentManagementCoreServerCall.ReadAuthorizationSettingsFromGeneralSettingsStore(
			UserName,
			Password,
			PasswordIsSaved);
		
		If Not ValueIsFilled(UserName) Then
			
			WriteLogEvent(
				EventLogEventName(),
				EventLogLevel.Error,,,
				NStr("vi = 'Đối với người sử dụng nhiệm vụ trao đổi thường kỳ, chưa chỉ ra tên người sử dụng 1C:Document Management';
					|ru = 'Для пользователя регламентного задания обмена не указано имя пользователя 1С:Документооборота';
					|en = '1C:Document Management username is not specified for the user of scheduled exchange job'; fa = '1C:Document Management username is not specified for the user of scheduled exchange job';
					|it = 'Per l''utente del compito di routine di cambio non è indicato il nome dell''utente di 1C:Document Management';
					|pl = 'Dla użytkownika zadania reglamentowanego wymiany nie podano nazwy użytkownika 1C:Document Management';
					|tr = 'Zamanlanmış görev değişim görevinin kullanıcısı için kullanıcı adı 1C:Document Management belirtilmedi'",
					Common.DefaultLanguageCode()));
			
			Return;
			
		EndIf;
		
		If PasswordIsSaved <> True Then
			
			WriteLogEvent(
				EventLogEventName(),
				EventLogLevel.Error,,,
				NStr("vi = 'Đối với người sử dụng nhiệm vụ trao đổi thường kỳ, chưa lưu lại mật khẩu 1C:Document Management';
					|ru = 'Для пользователя регламентного задания обмена не сохранен пароль 1С:Документооборота';
					|en = '1C:Document Management password is not saved for the user of scheduled exchange job'; fa = '1C:Document Management password is not saved for the user of scheduled exchange job';
					|it = 'Per l''utente del compito di routine di scambio non è salvata la password di 1C:Document Management';
					|pl = 'Dla użytkownika zadania reglamentowanego wymiany nie zapisano hasła 1C:Document Management';
					|tr = 'Zamanlanmış görev değişim görevinin kullanıcısı için 1C:Document Management şifresi kaydedilmedi'",
					Common.DefaultLanguageCode()));
			
			Return;
			
		EndIf;
		
		// Let's move the settings to constants.
		IntegrationWith1CDocumentManagementCoreServerCall.SaveAuthorizationSettingsForExchange(
			UserName,
			Password);
		IntegrationWith1CDocumentManagementCoreServerCall.DeleteAuthorizationSettingsFromGeneralSettingsStore();
		
	EndIf;
	SetPrivilegedMode(False);
	
	IntegrationWith1CDocumentManagementCoreServerCall.SetAuthorizationSettingsInSessionSettings(
		UserName,
		Password,
		False,
		False);
	IntegrationWith1CDocumentManagementCoreServerCall.SetServiceVersionInSessionSettings();
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	If Proxy = Undefined Then
		// The service is not available.
		Return;
	EndIf;
	
	If Settings.UseIntegrationBefore2 Then
		
		// Let's check the synchronization support.
		If Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.3.2.3.CORP") Then
			If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("") Then
				// The service is available, but the version is younger than the required one.
				DocumentFlowNode = IntegrationWith1CDocumentManagementCoreCached.DocumentFlowNode();
				ExchangePlans.DeleteChangeRecords(DocumentFlowNode);
			EndIf;
			Return;
		EndIf;
		
		ModuleIntegrationWith1CDocumentManagementExchange = Common.CommonModule("IntegrationWith1CDocumentManagementExchange");
		
	ElsIf Settings.UseIntegrationBefore3 Then
		
		ModuleIntegrationOfS1CDocumentFlow3Exchange = Common.CommonModule("IntegrationWith1CDocumentManagement3Exchange");
		
	EndIf;
	
	EventName = NStr("vi = 'Gửi dữ liệu';
					|ru = 'Отправка данных';
					|en = 'Export'; fa = 'خروج اطلاعات';
					|it = 'Invio dei dati';
					|pl = 'Wysłanie danych';
					|tr = 'Veri gönderimi'");
	PrepareDataForSending(
		Proxy,
		Settings,
		EventName,
		ModuleIntegrationWith1CDocumentManagementExchange,
		ModuleIntegrationOfS1CDocumentFlow3Exchange);
	SendData(Proxy, Settings, EventName);
	ClearOutdatedData();
	
	If Settings.UseIntegrationBefore2 Then
		ModuleIntegrationWith1CDocumentManagementExchange.GetData();
	EndIf;
	
	UpdatePrintedForms(Proxy, Settings);
	
EndProcedure

// Adds an error to the registration Log about the inability to select the Attribute value based on the data to be filled in.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   PropertyValue - XDTODataObject - data that came from BEFORE.
//                    - XDTOList - data that came from BEFORE.
//                    - String - data that came from BEFORE.
//                    - Number - data that came from BEFORE.
//                    - Date - data that came from BEFORE.
//                    - Boolean - data that came from BEFORE.
//                    - BinaryData - data that came from BEFORE.
//                    - Undefined - There is no data on the DO side, the IP object Attributes need to be cleared.
//   ObjectAttributeTypeIS - Type - the type of the IP object's details to be filled in.
//   ObjectToFillInIS - Arbitrary - the IS object to be filled in.
//   AttributeNameObjectIS - String - name of the IP object Attribute to be filled in.
//   PropertyName - String - The name of the XDTO property of the object from TO that is being filled in from.
//   ObjectTypeXDTO - String - the name of the XDTO type of the object from BEFORE whose property value is being filled in.
//
Procedure FixErrorInSelectingAttributeValue(Proxy, PropertyValue, ObjectAttributeTypeIS,
		ObjectToFillInIS, AttributeNameObjectIS = "", PropertyName = "", ObjectTypeXDTO = "") Export
	
	If TypeOf(PropertyValue) = Type("XDTODataObject") Or TypeOf(PropertyValue) = Type("XDTOList") Then
		ValuePresentation = XDTOObjectInString(Proxy, PropertyValue);
	Else
		ValuePresentation = String(PropertyValue);
	EndIf;
	
	ErrorText = New Array;
	If ValueIsFilled(AttributeNameObjectIS)
			And Metadata.FindByType(TypeOf(ObjectToFillInIS)) <> Undefined Then
		If ValueIsFilled(PropertyName) And ValueIsFilled(ObjectTypeXDTO) Then
			ErrorText.Add(StrTemplate(
				NStr("vi = 'Lỗi khi điền mục tin %1 đối tượng hệ thống thông tin kiểu %2 từ mục tin %3 đối tượng DM kiểu %4.';
					|ru = 'Ошибка при заполнении реквизита %1 объекта ИС типа %2 из реквизита %3 объекта ДО типа %4.';
					|en = 'An error occurred when filling the %1 attribute of the IS object of the %2 type from the %3 attribute of the 1C:Document Management object of the %4 type.'; fa = 'An error occurred when filling the %1 attribute of the IS object of the %2 type from the %3 attribute of the 1C:Document Management object of the %4 type.';
					|it = 'Ошибка при заполнении реквизита %1 объекта ИС типа %2 из реквизита %3 объекта ДО типа %4.';
					|pl = 'An error occurred when filling the %1 attribute of the IS object of the %2 type from the %3 attribute of the 1C:Document Management object of the %4 type.';
					|tr = 'DO nesne türündeki %4 öznitelik %3 ile ES nesne türü %2 öznitelik %1 doldurulurken hata oluştu.'"),
				AttributeNameObjectIS,
				Metadata.FindByType(TypeOf(ObjectToFillInIS)).FullName(),
				PropertyName,
				ObjectTypeXDTO));
		Else
			ErrorText.Add(StrTemplate(
				NStr("vi = 'Lỗi khi điền mục tin %1 đối tượng hệ thống thông tin kiểu %2.';
					|ru = 'Ошибка при заполнении реквизита %1 объекта ИС типа %2.';
					|en = 'An error occurred when filling the %1 attribute of the IS object of the %2 type.'; fa = 'An error occurred when filling the %1 attribute of the IS object of the %2 type.';
					|it = 'Ошибка при заполнении реквизита %1 объекта ИС типа %2.';
					|pl = 'An error occurred when filling the %1 attribute of the IS object of the %2 type.';
					|tr = 'ES nesne türü %2 özniteliği %1 doldurulurken hata oluştu.'"),
				AttributeNameObjectIS,
				Metadata.FindByType(TypeOf(ObjectToFillInIS)).FullName()));
		EndIf;
	EndIf;
	ErrorText.Add(NStr("vi = 'Không thể chọn giá trị mục tin theo dữ liệu để điền.';
						|ru = 'Нет возможности подобрать значение реквизита по данным для заполнения.';
						|en = 'Cannot select an attribute value by the data for filling.'; fa = 'Cannot select an attribute value by the data for filling.';
						|it = 'Нет возможности подобрать значение реквизита по данным для заполнения.';
						|pl = 'Cannot select an attribute value by the data for filling.';
						|tr = 'Gereksinimin değeri doldurulacak veriler ile eşleştirilemez.'"));
	ErrorText.Add(StrTemplate(
		NStr("vi = 'Kiểu mục tin: %1.';
			|ru = 'Тип реквизита: %1.';
			|en = 'Attribute type: %1.'; fa = 'Attribute type: %1.';
			|it = 'Тип реквизита: %1.';
			|pl = 'Attribute type: %1.';
			|tr = 'Öznitelik türü: %1.'"), Common.TypePresentationString(ObjectAttributeTypeIS)));
	ErrorText.Add(StrTemplate(
		NStr("vi = 'Kiểu dữ liệu để điền: %1.';
			|ru = 'Тип данных для заполнения: %1.';
			|en = 'Data type for filling: %1.'; fa = 'Data type for filling: %1.';
			|it = 'Тип данных для заполнения: %1.';
			|pl = 'Data type for filling: %1.';
			|tr = 'Doldurulacak verilerin türü: %1.'"), TypeOf(PropertyValue)));
	ErrorText.Add(NStr("vi = 'Dữ liệu để điền:';
						|ru = 'Данные для заполнения:';
						|en = 'Data for filling:'; fa = 'Data for filling:';
						|it = 'Данные для заполнения:';
						|pl = 'Data for filling:';
						|tr = 'Doldurulacak veriler:'"));
	ErrorText.Add(ValuePresentation);
	
	WriteWarning(
		StrConcat(ErrorText, Chars.LF),
		NStr("vi = 'Nhận dữ liệu';
			|ru = 'Получение данных';
			|en = 'Receiving data'; fa = 'در حال دریافت داده';
			|it = 'Получение данных';
			|pl = 'Pobieranie danych';
			|tr = 'Veri alımı'"),
		ObjectToFillInIS);
	
EndProcedure

// Constructor of the structure describing the value for filling in the Attributes of the IP object.
//
// Parameters:
//   XDTODataObject - XDTODataObject - It is transmitted if the IP Attribute needs to be selected for the XDTO object.
//
// Returns:
//   Structure:
//     * PropertyValue - XDTODataObject - data that came from BEFORE.
//                        - XDTOList - data that came from BEFORE.
//                        - String - data that came from BEFORE.
//                        - Number - data that came from BEFORE.
//                        - Date - data that came from BEFORE.
//                        - Boolean - data that came from BEFORE.
//                        - BinaryData - data that came from BEFORE.
//                        - Undefined - There is no data on the DO side, the IP object Attributes need to be cleared.
//     * ObjectTypeXDTO - String - the name of the XDTO type of the object from BEFORE whose property value is being filled in.
//     * PropertyName - String - The name of the XDTO property of the object from TO that is being filled in from.
//     * NameToSearch - String - a string for searching in the IP for an Catalog item or listing by name.
//     * PresentationForSearching - String - a string for searching for a Catalog item or listing by synonym in the IP.
//     * Owner - AnyRef - the owner of the directory item to find or create in the IP.
//                - Undefined - if the owner is absent.
//     * ObjectIDDM - String - The ID of the object BEFORE to search by
//         the register of the object integrated with the document flow or to create a link.
//     * ObjectTypeDM - String - the name of the object type BEFORE to search for
//         the case of the object integrated with the document flow or to create a link.
//     * ExternalObject - XDTODataObject - an XDTO object of the ExternalObject type. Can pass a direct link to the IP object.
//                      - Undefined - if there is no information about the external object.
//
Function ValueForFillingInAttributesOfIPObject(XDTODataObject = Undefined) Export
	
	ValueToFillIn = New Structure;
	ValueToFillIn.Insert("PropertyValue", XDTODataObject);
	ValueToFillIn.Insert("ObjectTypeXDTO", "");
	ValueToFillIn.Insert("PropertyName", "");
	ValueToFillIn.Insert("NameToSearch", "");
	ValueToFillIn.Insert("PresentationForSearching", "");
	ValueToFillIn.Insert("Owner", Undefined);
	
	ValueToFillIn.Insert("ObjectIDDM", "");
	ValueToFillIn.Insert("ObjectTypeDM", "");
	ValueToFillIn.Insert("ExternalObject", Undefined);
	
	If PropertySet(XDTODataObject, "name") Then
		ValueToFillIn.NameToSearch = XDTODataObject.name;
	EndIf;
	If PropertySet(XDTODataObject, "objectID") Then
		ValueToFillIn.ObjectIDDM = XDTODataObject.objectID.ID;
		ValueToFillIn.ObjectTypeDM = XDTODataObject.objectID.type;
		ValueToFillIn.PresentationForSearching = XDTODataObject.objectID.presentation;
	EndIf;
	If PropertySet(XDTODataObject, "externalObject") Then
		ValueToFillIn.ExternalObject = XDTODataObject.externalObject;
	EndIf;
	
	Return ValueToFillIn;
	
EndFunction

// Returns the value of the Attribute of the IP object by the value to fill in.
//
// Parameters:
//   ObjectAttributeTypeIS - Type - the type of the IP object's details to be filled in.
//   ValueToFillIn - See IntegrationWith1CDocumentManagementCore.ValueForFillingInAttributesOfIPObject
//   Context - See IntegrationWith1CDocumentManagementCore.ContextForFillingInAttributesOfIPObject
//   Create_IfNotFound - Boolean - automatically create a new item in the ip Catalog
//     if it was not possible to select an existing item by the value of the object's Attribute before.
//
// Returns:
//   Arbitrary
//
Function ValueOfAttributeOfIPObjectByValueToFillIn(ObjectAttributeTypeIS, ValueToFillIn,
		Context = Undefined, Create_IfNotFound = True) Export
	
	Result = Undefined;
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	If Context = Undefined Then
		Context = ContextForFillingInAttributesOfIPObject();
	EndIf;
	
	WhenDeterminingValueOfAttributeOfIPObjectByValueToFillIn(
		Proxy,
		Result,
		ObjectAttributeTypeIS,
		ValueToFillIn,
		Context);
	
	If Result <> Undefined Then
		Return Result;
	EndIf;
	
	If ValueToFillIn.PropertyValue = Undefined Then
		// If an empty value is received from BEFORE, the IP Attribute needs to be cleared.
		Return Result;
	EndIf;
	
	If Common.IsReference(ObjectAttributeTypeIS) Then
		// For reference objects, the desired value can be passed from TO in the ExternalObject property
		// or set in the register of the object integrated with the document flow.
		If ValueToFillIn.ExternalObject <> Undefined Then
			Result = LinkFromUUID(
				ValueToFillIn.ExternalObject.type,
				ValueToFillIn.ExternalObject.ID);
		EndIf;
		If Result = Undefined And Not IsBlankString(ValueToFillIn.ObjectIDDM) Then
			Result =
				InformationRegisters.ObjectsIntegratedWith1CDocumentManagement.ReferenceToIPObjectAccordingToDocumentManagementData(
					ValueToFillIn.ObjectIDDM,
					ValueToFillIn.ObjectTypeDM,
					ObjectAttributeTypeIS);
		EndIf;
		
		If Result <> Undefined Then
			Return Result;
		EndIf;
		
		// Metadata and the manager of the IP Attribute object will be needed to further search for a suitable value.
		AttributeMetadataIS = Metadata.FindByType(ObjectAttributeTypeIS);
		ManagerOfIPAttributeObject = Common.ObjectManagerByFullName(AttributeMetadataIS.FullName());
	EndIf;
	
	// The algorithm for selecting the value of the IP Attribute directly depends on its type.
	If AttributeMetadataIS <> Undefined And Common.IsCatalog(AttributeMetadataIS) Then
		
		// 1. We match the ID of the object to the ID.
		// 2. We are looking for a view to search.
		// 3. We are looking for the Search name.
		// 4. If we didn't find anything, and there is an identifier of the object, we create an element, if not, we clear the Attribute.
		// 5. The very meaning of the property is not analyzed. We will show it in the text of the error, in case of a bad selection.
		
		RefByUUID = Undefined;
		Result = ElementOfIPCatalogByObjectIdentifierXDTO(
			ValueToFillIn,
			AttributeMetadataIS,
			ManagerOfIPAttributeObject,
			RefByUUID);
		
		// You cannot search by name and other Attributes if
		// the owner has not been identified for the Catalog with the owners.
		If Result = Undefined
				And (AttributeMetadataIS.Owners.Count() = 0
					Or ValueIsFilled(ValueToFillIn.Owner)) Then
			
			If Not IsBlankString(ValueToFillIn.PresentationForSearching) Then
				Result = FindByDescription(
					ManagerOfIPAttributeObject,
					ValueToFillIn.PresentationForSearching,
					True,,
					ValueToFillIn.Owner); // The result changes from Undefined to an empty link if the search fails.
			EndIf;
			
			If Not ValueIsFilled(Result) And Not IsBlankString(ValueToFillIn.NameToSearch) Then
				Result = FindByDescription(
					ManagerOfIPAttributeObject,
					ValueToFillIn.NameToSearch,
					True,,
					ValueToFillIn.Owner);
			EndIf;
			
			If Not ValueIsFilled(Result) Then
				If Create_IfNotFound And RefByUUID <> Undefined Then
					// create a new item in the Catalog.
					If Not AccessRight("Insert", AttributeMetadataIS) Then
						Raise StrTemplate(
							NStr("vi = 'Không đủ quyền để tạo mới phần tử (%1).
								|Hãy liên hệ với người quản trị.';
								|ru = 'Недостаточно прав для создания новых элементов (%1).
								|Обратитесь к администратору.';
								|en = 'Insufficient rights to create new items (%1).
								|Contact the administrator.'; fa = 'Insufficient rights to create new items (%1).
								|Contact the administrator.';
								|it = 'Недостаточно прав для создания новых элементов (%1).
								|Обратитесь к администратору.';
								|pl = 'Niewystarczająco praw do utworzenia nowych elementów (%1).
								|Zwróć się do administratora.';
								|tr = 'Yeni öğeler (%1) oluşturmak için yetersiz yetki. 
								|Yöneticiniz ile iletişime geçin.'"),
							AttributeMetadataIS.Presentation());
					EndIf;
					Result = NewObjectIsFromXDTOObject(
						AttributeMetadataIS,
						ValueToFillIn.PropertyValue,
						Context.ObjectToFillInIS,
						RefByUUID,
						ValueToFillIn.Owner);
				Else
					Result = Undefined;
				EndIf;
			EndIf;
			
		EndIf;
		
	ElsIf AttributeMetadataIS <> Undefined And Common.IsEnum(AttributeMetadataIS) Then
		
		// 1. We are looking by Search name.
		// 2. We are looking for a view to search.
		// 3. We are looking for the ID of the object ID (it can pass the name of the enumeration value TO).
		// 4. If nothing is found, the result will be empty, the IP Attribute will be cleared, we will generate an error in the LR.
		// 5. The very meaning of the property is not analyzed. We will show it in the text of the error, in case of a bad selection.
		If Not IsBlankString(ValueToFillIn.NameToSearch) Then
			Result = ValueOfEnumerationByNameOrSynonym(
				ManagerOfIPAttributeObject,
				AttributeMetadataIS.EnumValues,
				ValueToFillIn.NameToSearch);
		EndIf;
		If Result = Undefined And Not IsBlankString(ValueToFillIn.PresentationForSearching) Then
			Result = ValueOfEnumerationByNameOrSynonym(
				ManagerOfIPAttributeObject,
				AttributeMetadataIS.EnumValues,
				ValueToFillIn.PresentationForSearching);
		EndIf;
		If Result = Undefined And Not IsBlankString(ValueToFillIn.ObjectIDDM) Then
			Result = ValueOfEnumerationByNameOrSynonym(
				ManagerOfIPAttributeObject,
				AttributeMetadataIS.EnumValues,
				ValueToFillIn.ObjectIDDM);
		EndIf;
		
	ElsIf ObjectAttributeTypeIS = Type("String") Then
		
		// 1. If the Search view is filled in, assign it.
		// 2. If the Search name is filled in, assign it.
		// 3. Otherwise, we look at the values of the property.
		// 4. If it is an object or a list of XDTO - use the OBJECTXDTO method in the string.
		// 5. Otherwise, we bring the property values to the line.
		If Not IsBlankString(ValueToFillIn.PresentationForSearching) Then
			Result = ValueToFillIn.PresentationForSearching;
		ElsIf Not IsBlankString(ValueToFillIn.NameToSearch) Then
			Result = ValueToFillIn.NameToSearch;
		ElsIf TypeOf(ValueToFillIn.PropertyValue) = Type("XDTODataObject")
				Or TypeOf(ValueToFillIn.PropertyValue) = Type("XDTOList") Then
			Result = XDTOObjectInString(Proxy, ValueToFillIn.PropertyValue);
		Else
			Result = String(ValueToFillIn.PropertyValue);
		EndIf;
		
	ElsIf ObjectAttributeTypeIS = Type("Number") Then
		
		// The Attributes of the number type IP can be filled in by converting the property value to a number.
		Try
			Result = Number(ValueToFillIn.PropertyValue);
		Except
			Result = Undefined;
		EndTry;
		
	ElsIf ObjectAttributeTypeIS = Type("Date") Then
		
		// The date-type IP Attributes can be filled in by bringing the property value to the date.
		Try
			Result = Date(ValueToFillIn.PropertyValue);
		Except
			Result = Undefined;
		EndTry;
		
	ElsIf ObjectAttributeTypeIS = Type("Boolean") Then
		
		// The Attributes of a Boolean-type IC can be filled in by converting the property value to a Boolean.
		Try
			Result = Boolean(ValueToFillIn.PropertyValue);
		Except
			Result = Undefined;
		EndTry;
		
	Else
		
		// Other types of IP Attributes can only be filled in with the specified IP value or from an expression on the IP side.
		// There is no way to find the desired IP value based on the value from BEFORE.
		Result = Undefined;
		
	EndIf;
	
	If Result = Undefined Then
		FixErrorInSelectingAttributeValue(
			Proxy,
			ValueToFillIn.PropertyValue,
			ObjectAttributeTypeIS,
			Context.ObjectToFillInIS,
			Context.AttributeNameObjectIS,
			ValueToFillIn.PropertyName,
			ValueToFillIn.ObjectTypeXDTO);
	EndIf;
	
	Return Result;
	
EndFunction

// Constructor of the structure describing the context for filling in the Attributes of the IP object.
//
// Returns:
//   Structure:
//     * ObjectToFillInIS - Arbitrary - the IS object to be filled in.
//                           - Undefined - if there is no object to fill in.
//     * AttributeNameObjectIS - String - name of the IP object Attribute to be filled in.
//     * IsAdditionalAttributeIS - Boolean - true if the Attribute of the IP object to be filled in is an additional one. a property.
//     * AdditionalAttributeIS - ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo - the property is the owner.
//     * ChoiceParameters - Map of KeyAndValue - The selection parameters:
//       ** Key - String - the name of the parameter of the type "Selection.The owner."
//       ** Value - Arbitrary - the value of the parameter (selection).
//
Function ContextForFillingInAttributesOfIPObject() Export
	
	Context = New Structure;
	Context.Insert("ObjectToFillInIS", Undefined);
	Context.Insert("AttributeNameObjectIS", "");
	Context.Insert("IsAdditionalAttributeIS", False);
	Context.Insert("AdditionalAttributeIS",
		ChartsOfCharacteristicTypes.AdditionalAttributesAndInfo.EmptyRef());
	Context.Insert("ChoiceParameters", New Map);
	
	Return Context;
	
EndFunction

// Creates a new IP object from the XDTO object.
//
// Parameters:
//   ObjectMetadataIS - MetadataObject - metadata of the IP object.
//   XDTODataObject - XDTODataObject - the object BEFORE, the source of the fill data.
//   ObjectToFillInIS - Arbitrary - the IP object, during the filling of which the creation is called
//     ObjectIS by reference. Provides the context needed to populate the ObjectIS.
//   RefByUUID - AnyRef - a new link created by the XDTO object ID.
//   Owner - AnyRef - the owner of the Catalog item to be created in the IP.
//            - Undefined - if the owner is absent.
//
// Returns:
//   AnyRef - a reference to the created object.
//
Function NewObjectIsFromXDTOObject(ObjectMetadataIS, XDTODataObject, ObjectToFillInIS = Undefined,
		RefByUUID = Undefined, Owner = Undefined) Export
	
	Manager = Common.ObjectManagerByFullName(ObjectMetadataIS.FullName());
	NewObject = Manager.CreateItem(); // DefinedType.IntegrationWith1CDocumentManagementCatalogsObjectsOverridable
	NewObject.Description = XDTODataObject.name;
	If ValueIsFilled(RefByUUID) Then
		NewObject.SetNewObjectRef(RefByUUID);
	ElsIf StringFunctionsClientServer.IsUUID(XDTODataObject.objectID.id) Then
		RefByUUID = Manager.GetRef(New UUID(XDTODataObject.objectID.id));
		NewObject.SetNewObjectRef(RefByUUID);
	EndIf;
	If ValueIsFilled(Owner) Then
		NewObject.Owner = Owner;
	EndIf;
	
	WhenCreatingLink(NewObject, XDTODataObject, ObjectToFillInIS);
	
	NewObject.Write();
	
	If PropertySet(XDTODataObject, "objectID")
			And XDTODataObject.objectID.ID <> ""
			And XDTODataObject.objectID.type <> ""
			And Not ObjectDoesNotSupportExchange(XDTODataObject.objectID.type) Then
		WhetherFilesAreAttached = False; // An additional request to the DO is not required.
		If PropertySet(XDTODataObject, "files") Then
			WhetherFilesAreAttached = (XDTODataObject.files.Count() > 0);
		EndIf;
		InformationRegisters.ObjectsIntegratedWith1CDocumentManagement.AddLink(
			XDTODataObject.objectID.ID,
			XDTODataObject.objectID.type,
			NewObject.Ref,
			WhetherFilesAreAttached);
	EndIf;
	
	Return NewObject.Ref;
	
EndFunction

// Checks whether the object supports the data exchange mechanism before.
//
// Parameters:
//   ObjectTypeDM - String - the object type is UP TO.
//
// Returns:
//   Boolean
//
Function ObjectDoesNotSupportExchange(ObjectTypeDM) Export
	
	ObjectsWithExchangeSupport = New Array;
	
	ObjectsWithExchangeSupport.Add("DMCorrespondent");
	
	Settings = IntegrationWith1CDocumentManagementCoreServerCall.UseIntegration();
	If Settings.UseIntegrationBefore2 Then
		ObjectsWithExchangeSupport.Add("DMInternalDocument");
		ObjectsWithExchangeSupport.Add("DMIncomingDocument");
		ObjectsWithExchangeSupport.Add("DMOutgoingDocument");
	ElsIf Settings.UseIntegrationBefore3 Then
		ObjectsWithExchangeSupport.Add("DMDocument");
		ObjectsWithExchangeSupport.Add("DMMeeting");
	EndIf;
	
	Return ObjectsWithExchangeSupport.Find(ObjectTypeDM) <> Undefined;
	
EndFunction

// It is called before recording objects of the integrated system through the exchange mechanism with 1C:Document flow.
// Allows you to perform additional checks before recording, change additional properties and refuse recording.
//
// Parameters:
//   ObjectIS - DocumentObject
//            - CatalogObject - the IS object being modified.
//   Cancel - Boolean - indicates that the recording was rejected.
//   Var_DocumentWriteMode - DocumentWriteMode - allows you to change the recording mode.
//   Var_DocumentPostingMode - DocumentPostingMode - allows you to change the mode of the document.
//
Procedure BeforeRecordingICObject(ObjectIS, Cancel,
		Var_DocumentWriteMode = Undefined, Var_DocumentPostingMode = Undefined) Export
	
	ObjectVersionInfo = New Structure;
	ObjectVersionInfo.Insert("VersionAuthor", Undefined);
	ObjectVersionInfo.Insert("ObjectVersionType", "ChangedByUser");
	ObjectVersionInfo.Insert("Comment", NStr("vi = 'Nhận dữ liệu từ 1C:Document Management';
											|ru = 'Получение данных из 1С:Документооборота';
											|en = 'Get data from 1C:Document Management'; fa = 'Get data from 1C:Document Management';
											|it = 'Получение данных из 1С:Документооборота';
											|pl = 'Get data from 1C:Document Management';
											|tr = '1C:Document Management üzerinden verilerin alınması'"));
	ObjectVersionInfo.Insert("SynchronizationWarning", "");
	
	ObjectIS.AdditionalProperties.Insert("ObjectVersionInfo", ObjectVersionInfo);
	
	IntegrationWith1CDocumentManagementCoreOverridable.BeforeRecordingICObject(
		ObjectIS,
		Cancel,
		Var_DocumentWriteMode,
		Var_DocumentPostingMode);
	
	If Not Cancel
			And ObjectIS.AdditionalProperties.Property("ObjectVersionInfo")
			And Common.SubsystemExists("StandardSubsystems.ObjectsVersioning") Then
		ModuleObjectsVersioning = Common.CommonModule("ObjectsVersioning");
		ModuleObjectsVersioning.CreateObjectVersionByDataExchange(
			ObjectIS,
			ObjectIS.AdditionalProperties.ObjectVersionInfo,
			Common.RefExists(ObjectIS.Ref),
			IntegrationWith1CDocumentManagementCoreCached.DocumentFlowNode());
	EndIf;
	
EndProcedure

#EndRegion

#Region GeneralProceduresAndFunctions

// Gets the publication address of the Workflow web service.
//
// Parameters:
//   AddressOfServiceCenter - Boolean - It is required to obtain the address of the central sub-asset.
//
// Returns:
//   String - service address.
//
Function AddressOf1CDocumentManagementWebService(AddressOfServiceCenter = False) Export
	
	WebServiceAddress = Constants.AddressOf1CDocumentManagementWebService.Get();
	
	If AddressOfServiceCenter = False Then
		Settings = IntegrationWith1CDocumentManagementCoreServerCall.UseIntegration();
		If Settings.UseIntegrationBefore3 Then
			RegisterName = "DataOf1CDocumentManagementNodes";
			RegisterDataOf1CDocumentManagementNodes = InformationRegisters[RegisterName];
			DataOfSUBAsset = RegisterDataOf1CDocumentManagementNodes.DataOfSUBAsset(SessionParameters.IntegrationWith1CDocumentManagementNode);
			If ValueIsFilled(DataOfSUBAsset.WebServiceAddress) Then
				WebServiceAddress = DataOfSUBAsset.WebServiceAddress;
			EndIf;
		EndIf;
	EndIf;
	
	ProcessAddressOf1CDocumentManagementWebService(WebServiceAddress);
	
	Return WebServiceAddress;
	
EndFunction

// Gets the service version from the session parameters.
//
// Returns:
//   String - service version.
//
Function ServiceVersion() Export
	
	Return SessionParameters.IntegrationWith1CDocumentManagementServiceVersion;
	
EndFunction

// Performs an arbitrary algorithm in the built-in 1C language:Enterprises by pre-setting
// safe code execution mode and safe data separation mode for all separators
// present in the configuration.
//
// Parameters:
//   Algorithm - String - algorithm in the built - in language " 1C:Companies".
//   Parameters - Arbitrary - the context that is required to execute the algorithm.
//
Procedure ExecuteInSafeMode(Algorithm, Parameters) Export
	
	CheckAlgorithmForForbiddenExpressions(Algorithm);
	
	// BSLLS:PairingBrokenTransaction-off
	// Design solution. The Start /Cancel transaction methods are used to prevent
	// unauthorized actions with the database from an expression in the embedded language.
	
	BeginTransaction();
	
	Try
		Common.ExecuteInSafeMode(Algorithm, Parameters);
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	If TransactionActive() Then
		RollbackTransaction();
	EndIf;
	
	// BSLLS:PairingBrokenTransaction-on
	
EndProcedure

// Executes a request to the service, turning error messages into a form understandable to the user.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   Query - XDTODataObject - the request being executed.
//
// Returns:
//   XDTODataObject - the result of executing the request.
//
Function ExecuteQuery(Proxy, Query) Export
	
	Try
		
		Response = Proxy.execute(Query);
		Return Response;
		
	Except
		
		Info = ErrorInfo();
		WriteLogEvent(
			EventLogEventName(),
			EventLogLevel.Error,,,
			ErrorProcessing.DetailErrorDescription(Info));
		
		BriefErrorDescription = ErrorProcessing.BriefErrorDescription(Info);
		// For known types of errors, we will change the text of the message.
		If Find(BriefErrorDescription, NStr("vi = 'Chưa thực hiện đăng nhập người sử dụng';
											|ru = 'Аутентификация пользователя не выполнена';
											|en = 'User authentication failed'; fa = 'User authentication failed';
											|it = 'L''autenticazione dell''utente non è stata eseguita';
											|pl = 'Nie wykonano uwierzytelniania użytkownika';
											|tr = 'Kullanıcı doğrulama gerçekleştirilemedi'")) <> 0 Then
			
			SessionParameters.IntegrationWith1CDocumentManagementServiceVersion = "0.0.0.0";
			BriefErrorDescription = NStr("vi = 'Sai tên người sử dụng hoặc mật khẩu. Hãy kiểm tra tên
				|và mật khẩu trong tùy chỉnh đăng nhập vào 1C:Document Management.';
				|ru = 'Неверное имя пользователя или пароль. Проверьте имя
				|и пароль в настройках авторизации в 1С:Документообороте.';
				|en = 'Incorrect username or password. Check the name
				|and the password in authorization settings in 1C:Document Management.'; fa = 'Incorrect username or password. Check the name
				|and the password in authorization settings in 1C:Document Management.';
				|it = 'Nome o password utente errati. Verificare il nome
				|e la password nelle impostazioni di autorizzazione in 1C:Document Management.';
				|pl = 'Nieprawidłowa nazwa użytkownika lub hasło. Sprawdź nazwę
				|i hasło w ustawieniach uwierzytelniania w 1C:Document Management.';
				|tr = 'Girdiğiniz kullanıcı adı
				|veya şifre hatalı. 1C:Document Management''teki yetkilendirme ayarlarında adı ve şifreyi kontrol et.'");
			
		// For unknown types of errors, we will turn HTML into plain text.
		ElsIf Find(BriefErrorDescription, "<html>") <> 0 Then
			
			HTMLDocument = New FormattedDocument;
			HTMLDocument.SetHTML(BriefErrorDescription, New Structure);
			BriefErrorDescription = HTMLDocument.GetText();
			
		Else
			
			// An exception may have arisen due to the fact that the service is not physically available.
			// To check, you need to request the service version.
			IntegrationWith1CDocumentManagementCoreServerCall.SetServiceVersionInSessionSettings();
			If ServiceVersion() = "0.0.0.0" Then
				BriefErrorDescription = NStr("vi = 'Không đủ quyền truy cập đến 1C:Document Management.';
											|ru = 'Нет доступа к 1С:Документообороту.';
											|en = 'No access to 1C:Document Management.'; fa = 'دسترسی به 1C:Document Management وجود ندارد.';
											|it = 'Non vi è accesso a 1C:Document Management.';
											|pl = 'Brak dostępu do 1C:Document Management.';
											|tr = '1C:Document Management''e erişilmiyor.'");
			EndIf;
			
		EndIf;
		
		Raise BriefErrorDescription;
		
	EndTry;
	
EndFunction

// Executes a package of requests to the Document management service.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   Queries - Array of XDTODataObject - package requests.
//   CheckSubordinates - Boolean - specifies whether to check the results of queries included in the package.
//
// Returns:
//   XDTODataObject - an XDTO object of the DMBatchResponse type.
//
Function ExecuteBatchRequest(Proxy, Queries, CheckSubordinates = False) Export
	
	Package = CreateObject(Proxy, "DMBatchRequest");
	PackageQueries = Package.requests; // XDTOList
	
	For Each Query In Queries Do
		PackageQueries.Add(Query);
	EndDo;
	
	ResponseToPackageRequests = ExecuteQuery(Proxy, Package);
	CheckWebServiceRefund(Proxy, ResponseToPackageRequests);
	
	If CheckSubordinates Then
		For Each Response In ResponseToPackageRequests.responses Do
			CheckWebServiceRefund(Proxy, Response);
		EndDo;
	EndIf;
	
	Return ResponseToPackageRequests;
	
EndFunction

// Removes extra characters from the expression in the embedded language.
//
// Parameters:
//   ComputedExpression - String - The original expression.
//
// Returns:
//   String
//
Function ExpressionWithoutExtraCharacters(ComputedExpression) Export
	
	ExpressionWithoutExtraCharacters = Lower(ComputedExpression);
	ExpressionWithoutExtraCharacters = StrReplace(ExpressionWithoutExtraCharacters, Chars.CR, "");
	ExpressionWithoutExtraCharacters = StrReplace(ExpressionWithoutExtraCharacters, Chars.VTab, "");
	ExpressionWithoutExtraCharacters = StrReplace(ExpressionWithoutExtraCharacters, Chars.NBSp, "");
	ExpressionWithoutExtraCharacters = StrReplace(ExpressionWithoutExtraCharacters, Chars.LF, "");
	ExpressionWithoutExtraCharacters = StrReplace(ExpressionWithoutExtraCharacters, Chars.FF, "");
	ExpressionWithoutExtraCharacters = StrReplace(ExpressionWithoutExtraCharacters, Chars.Tab, "");
	ExpressionWithoutExtraCharacters = StrReplace(ExpressionWithoutExtraCharacters, " ", "");
	
	Return ExpressionWithoutExtraCharacters;
	
EndFunction

// Returns the data structure for filling in the IC object based on the object UP to.
//
// Parameters:
//   UIDRules - UUID - unique ID of the rule being used.
//   ObjectTypeDM - String - the name of the XDTO object type.
//   ObjectIDDM - String - ID of the document flow object.
//
// Returns:
//   Structure:
//     * FormName - String - the name of the object form of this configuration.
//     * Object1CDocumentManagement - Structure:
//         ** ID - String - object identifier.
//         ** Type - String - object type.
//     * TypeOfObjectToCreate - String - the type of IP object being created.
//     * AttributesValues - Structure - the key is the name of the Attribute, the value is the value of the Attribute:
//       ** IsAdditionalAttributeIS - Boolean
//       ** ThisIsTable - Boolean
//       ** Table - String
//       ** AdditionalAttributes - Array of Structure:
//         *** Property - ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo
//         *** Value - Characteristic.AdditionalAttributesAndInfo
//     * AdditionalAttributes - Array of Structure - Values of additional banking details:
//       ** Property - ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo
//       ** Value - Characteristic.AdditionalAttributesAndInfo
//     * WhetherFilesAreAttached - Boolean
//                                   - Undefined - indicates whether there are attached files.
//     * IntegrationRule - CatalogRef.RulesForIntegrationWith1CDocumentManagement
//                         - CatalogRef.RulesForIntegrationWith1CDocumentManagement3
//
Function DataForFillingInIntegratedObject(UIDRules, ObjectTypeDM, ObjectIDDM) Export
	
	Settings = IntegrationWith1CDocumentManagementCoreServerCall.UseIntegration();
	If Settings.UseIntegrationBefore2 Then
		ModuleRulesOfIntegrationWith1CDocumentManagement =
			Common.CommonModule("Catalogs.RulesForIntegrationWith1CDocumentManagement");
		Rule = ModuleRulesOfIntegrationWith1CDocumentManagement.GetRef(UIDRules);
	ElsIf Settings.UseIntegrationBefore3 Then
		ModuleRulesOfIntegrationWith1CDocumentManagement3 =
			Common.CommonModule("Catalogs.RulesForIntegrationWith1CDocumentManagement3");
		Rule = ModuleRulesOfIntegrationWith1CDocumentManagement3.GetRef(UIDRules);
	Else
		Raise NStr("vi = 'Chưa tùy chỉnh tích hợp với 1C:Document Management';
					|ru = 'Не настроена интеграция с 1С:Документооборот';
					|en = 'Integration with 1C:Document Management is not configured'; fa = 'Integration with 1C:Document Management is not configured';
					|it = 'Не настроена интеграция с 1С:Документооборот';
					|pl = 'Integration with 1C:Document Management is not configured';
					|tr = '1C:Document Management ile entegrasyon ayarlanmamış'");
	EndIf;
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	XDTODataObject = GetObject(Proxy, ObjectTypeDM, ObjectIDDM,, Rule);
	
	ObjectTypeIS = Common.ObjectAttributeValue(Rule, "ObjectTypeIS");
	FormName = ObjectTypeIS + ".ObjectForm";
	Object = NewIPObject(ObjectTypeIS);
	
	If Settings.UseIntegrationBefore2 Then
		ModuleRulesOfIntegrationWith1CDocumentManagement =
			Common.CommonModule("Catalogs.RulesForIntegrationWith1CDocumentManagement");
		ModuleRulesOfIntegrationWith1CDocumentManagement.FillInObjectByXDTOObject(
			Proxy,
			Object,
			XDTODataObject,
			Rule);
	ElsIf Settings.UseIntegrationBefore3 Then
		ModuleRulesOfIntegrationWith1CDocumentManagement3 =
			Common.CommonModule("Catalogs.RulesForIntegrationWith1CDocumentManagement3");
		ModuleRulesOfIntegrationWith1CDocumentManagement3.FillInICObjectByXDTOObject(
			Proxy,
			Object,
			XDTODataObject,
			Rule);
	EndIf;
	
	ObjectAttributes = ObjectAttributesIS(ObjectTypeIS);
	
	// Let's transfer the object data to the structure.
	AttributesValues = New Structure;
	HeaderAttributes = ObjectAttributes.FindRows(
		New Structure("IsAdditionalAttributeIS, ThisIsTable, Table", False, False, ""));
	For Each HeaderAttributes In HeaderAttributes Do
		AttributesValues.Insert(HeaderAttributes.Name, Object[HeaderAttributes.Name]);
	EndDo;
	TabularSections = ObjectAttributes.FindRows(
		New Structure("IsAdditionalAttributeIS, ThisIsTable", False, True));
	For Each TabularSection In TabularSections Do
		AttributesValues.Insert(TabularSection.Name, New Array);
		CurrentTabularSection = AttributesValues[TabularSection.Name]; // Array
		TabularSectionAttributes = ObjectAttributes.FindRows(
			New Structure("IsAdditionalAttributeIS, Table", False, TabularSection.Name));
		
		For Each String In Object[TabularSection.Name] Do
			StringStructure = New Structure;
			For Each TabularSectionAttribute In TabularSectionAttributes Do
				StringStructure.Insert(TabularSectionAttribute.Name, String[TabularSectionAttribute.Name]);
			EndDo;
			CurrentTabularSection.Add(StringStructure);
		EndDo;
		
	EndDo;
	
	AdditionalAttributes = New Array;
	
	If Object.Ref.Metadata().TabularSections.Find("AdditionalAttributes") <> Undefined Then
		For Each String In Object.AdditionalAttributes Do
			AdditionalAttribute5 = New Structure;
			AdditionalAttribute5.Insert("Property",String.Property);
			AdditionalAttribute5.Insert("Value", String.Value);
			AdditionalAttributes.Add(AdditionalAttribute5);
		EndDo;
	EndIf;
	
	AttributesValues.Insert("AdditionalAttributes", AdditionalAttributes);
	
	Object1CDocumentManagement = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
		ObjectIDDM,
		ObjectTypeDM);
	
	FillingData = New Structure;
	FillingData.Insert("FormName", FormName);
	FillingData.Insert("Object1CDocumentManagement", Object1CDocumentManagement);
	FillingData.Insert("TypeOfObjectToCreate", ObjectTypeIS);
	FillingData.Insert("AttributesValues", AttributesValues);
	FillingData.Insert("AdditionalAttributes", AdditionalAttributes);
	FillingData.Insert("IntegrationRule", Rule);
	
	If PropertySet(XDTODataObject, "files") Then
		FillingData.Insert("WhetherFilesAreAttached", XDTODataObject.files.Count() <> 0);
	Else
		FillingData.Insert("WhetherFilesAreAttached", Undefined);
	EndIf;
	
	Return FillingData;
	
EndFunction

// Adds a string of invertible constants to the constant dependency table.
//
// Parameters:
//   TableOfConstants - See IntegrationWith1CDocumentManagementCore.DependenciesOfConstants
//   NameOfParentConstant - String - the name of the parent constant as it is set in the configurator.
//   NameOfSubordinateConstant - String - the name of the subordinate constant as it is set in the configurator.
//
Procedure AddStringOfInvertibleConstants(TableOfConstants, NameOfParentConstant,
		NameOfSubordinateConstant = "") Export
	
	If NameOfSubordinateConstant = "" Then
		NameOfSubordinateConstant = "Not" + NameOfParentConstant;
	EndIf;
	
	AddRowToConstantDependencyTable(
		TableOfConstants,
		NameOfParentConstant,
		False,
		NameOfSubordinateConstant,
		True);
	AddRowToConstantDependencyTable(
		TableOfConstants,
		NameOfParentConstant,
		True,
		NameOfSubordinateConstant,
		False);
	
EndProcedure

// Adds a row to the type matching table.
//
// Parameters:
//   Table - ValueTable - type matching table.
//   TypeNameXDTO - String - type name XDTO
//   ObjectTypeIS - Type - the type of IP object.
//
Procedure AddTypeMatchingString(Table, TypeNameXDTO, ObjectTypeIS) Export
	
	NewRow = Table.Add();
	NewRow.TypeNameXDTO = TypeNameXDTO;
	NewRow.ObjectTypeIS = ObjectTypeIS;
	
EndProcedure

// Adds a row to the constant dependency table.
//
// Parameters:
//   TableOfConstants - See IntegrationWith1CDocumentManagementCore.DependenciesOfConstants
//   NameOfParentConstant - String - the name of the parent constant as it is set in the configurator
//   ValueOfParentConstant - Arbitrary - the value of the parent constant
//   NameOfSubordinateConstant - String - the name of the subordinate constant as it is set in the configurator
//   ValueOfSubordinateConstant - Arbitrary - the value of the subordinate constant
//
Procedure AddRowToConstantDependencyTable(TableOfConstants, NameOfParentConstant,
		ValueOfParentConstant, NameOfSubordinateConstant, ValueOfSubordinateConstant) Export
	
	NewRow = TableOfConstants.Add();
	NewRow.NameOfParentConstant = NameOfParentConstant;
	NewRow.ValueOfParentConstant = ValueOfParentConstant;
	NewRow.NameOfSubordinateConstant = NameOfSubordinateConstant;
	NewRow.ValueOfSubordinateConstant = ValueOfSubordinateConstant;
	
EndProcedure

// returns a link to an additional Attribute with a unique name.
//
// Parameters:
//   NameOfAdditionalProps - String - See IntegrationWith1CDocumentManagementCore.NameOfAdditionalProps
//
// Returns:
//   ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo
//
Function AdditionalAttributeByName(NameOfAdditionalProps) Export
	
	IDOfAdditionalBankingDetails = StrReplace(NameOfAdditionalProps, "AdditionalAttribute5_", "");
	IDOfAdditionalBankingDetails = StrTemplate("%1-%2-%3-%4-%5",
		Left(IDOfAdditionalBankingDetails, 8),
		Mid(IDOfAdditionalBankingDetails, 9, 4),
		Mid(IDOfAdditionalBankingDetails, 13, 4),
		Mid(IDOfAdditionalBankingDetails, 17, 4),
		Mid(IDOfAdditionalBankingDetails, 21, 12));
	
	Return ChartsOfCharacteristicTypes.AdditionalAttributesAndInfo.GetRef(
		New UUID(IDOfAdditionalBankingDetails));
	
EndFunction

// Gets the availability of the functionality of the version of the Document Management web service.
//
// Parameters:
//   ServiceVersion - String - a version of the Document Management web service containing the required functionality.
//   Optimistic - Boolean - a sign of the need to return True if the version of the service is still unknown.
//
// Returns:
//   Boolean - True if the web Document Management service of the specified version is available.
//
Function FunctionalityOfServiceVersionIsAvailable(ServiceVersion = "", Optimistic = False) Export
	
	If Optimistic And Not SessionParameters.IntegrationWith1CDocumentManagementPasswordIsKnown Then
		Return True;
	EndIf;
	
	If UserIsAllowedToUseIntegration() Then
		CurrentVersion = ServiceVersion();
	Else
		CurrentVersion = "0.0.0.0";
	EndIf;
	
	If CurrentVersion = "0.0.0.0" Then // Connection error.
		Return False;
	ElsIf IsBlankString(CurrentVersion) Then // In the process of receiving.
		If Optimistic Then
			Return True; // We don't know yet, but most likely it is available.
		Else
			Return False; // We don't know yet, but it's probably not available.
		EndIf;
	ElsIf IsBlankString(ServiceVersion) Then // We need at least some.
		Return True;
	EndIf;
	
	CurVersionDescription = StrSplit(CurrentVersion, ".");
	If CurVersionDescription.Count() <> 5 Then
		// The old versions do not inform the editors, and for these versions it is important.
		// Optimistically assume a Corp.
		If CurrentVersion = "1.2.7.3" Or CurrentVersion = "1.2.8.1" Then
			CurVersionDescription.Add("CORP");
		Else
			CurVersionDescription.Add("PROF");
		EndIf;
	EndIf;
	
	Return VersionNoLess(CurVersionDescription, ServiceVersion);
	
EndFunction

// Determines whether BID modules designed for integration with 1C are built into the configuration:Document management of edition 2.
//
// Returns:
//   Boolean
//
Function ThereIsSubsystemUPTo2() Export
	
	Return Common.SubsystemExists(
		"IntegrationWith1CDocumentManagementSubsystem.IntegrationWith1CDocumentManagementEdition2Subsystem");
	
EndFunction

// Determines whether BID modules designed for integration with 1C are built into the configuration:Document management of edition 3.
//
// Returns:
//   Boolean
//
Function ThereIsSubsystemUPTo3() Export
	
	Return Common.SubsystemExists(
		"IntegrationWith1CDocumentManagementSubsystem.IntegrationWith1CDocumentManagementEdition3Subsystem");
	
EndFunction

// Checks the value for an object type containing a unique identifier.
//
// Parameters:
//   Value - Arbitrary - the value to check.
//
// Returns:
//   Boolean - Indicates whether the object has a unique identifier.
//
Function ThereIsUniqueIdentifier(Value) Export
	
	If Value = Undefined Then
		Return False;
	EndIf;
	
	Type = TypeOf(Value);
	
	Return Catalogs.AllRefsType().ContainsType(Type)
		Or Documents.AllRefsType().ContainsType(Type)
		Or ChartsOfCharacteristicTypes.AllRefsType().ContainsType(Type)
		Or BusinessProcesses.AllRefsType().ContainsType(Type)
		Or Tasks.AllRefsType().ContainsType(Type);
	
EndFunction

// Returns a table describing the dependency of constants in the configuration.
// Each row in the table means:
// for a parent constant with the value X, only the value Y for the subordinate constant is allowed.
//
// Returns:
//   ValueTable:
//     * NameOfParentConstant - String
//     * NameOfSubordinateConstant - String
//     * ValueOfParentConstant - Arbitrary
//     * ValueOfSubordinateConstant - Arbitrary
//
Function DependenciesOfConstants() Export
	
	Settings = IntegrationWith1CDocumentManagementCoreServerCall.UseIntegration();
	
	Result = New ValueTable;
	
	Result.Columns.Add("NameOfParentConstant", New TypeDescription("String"));
	Result.Columns.Add("NameOfSubordinateConstant",  New TypeDescription("String"));
	Result.Columns.Add("ValueOfParentConstant");
	Result.Columns.Add("ValueOfSubordinateConstant");
	
	Result.Indexes.Add("NameOfParentConstant");
	Result.Indexes.Add("NameOfSubordinateConstant");
	
	If ThereIsSubsystemUPTo2() And ThereIsSubsystemUPTo3() Then
		AddRowToConstantDependencyTable(
			Result,
			"UseIntegrationWith1CDocumentManagement3",
			True,
			"UseIntegrationWith1CDocumentManagement",
			False);
		AddRowToConstantDependencyTable(
			Result,
			"UseIntegrationWith1CDocumentManagement",
			True,
			"UseIntegrationWith1CDocumentManagement3",
			False);
	EndIf;
	
	If ThereIsSubsystemUPTo2() Then
		AddRowToConstantDependencyTable(
			Result,
			"UseIntegrationWith1CDocumentManagement",
			False,
			"UseDailyReports1CDocumentManagement",
			False);
		AddRowToConstantDependencyTable(
			Result,
			"UseIntegrationWith1CDocumentManagement",
			False,
			"UseEmail1CDocumentManagement",
			False);
		AddRowToConstantDependencyTable(
			Result,
			"UseIntegrationWith1CDocumentManagement",
			False,
			"UseFileStorage1CDocumentManagement",
			False);
		AddRowToConstantDependencyTable(
			Result,
			"UseIntegrationWith1CDocumentManagement",
			False,
			"UseProcessesAndTasks1CDocumentManagement",
			False);
		AddRowToConstantDependencyTable(
			Result,
			"UseIntegrationWith1CDocumentManagement",
			False,
			"UseRelatedDocuments1CDocumentManagement",
			False);
		AddRowToConstantDependencyTable(
			Result,
			"UseIntegrationWith1CDocumentManagement",
			False,
			"UseAttachedFiles1CDocumentManagement",
			False);
		
		// Approval via 1C:Document flow
		AddRowToConstantDependencyTable(
			Result,
			"UseIntegrationWith1CDocumentManagement",
			False,
			"UseApprovalThrough1CDocumentManagement",
			False);
		If Settings.UseIntegrationBefore2 Then
			AddRowToConstantDependencyTable(
				Result,
				"UseProcessesAndTasks1CDocumentManagement",
				False,
				"UseApprovalThrough1CDocumentManagement",
				False);
			AddRowToConstantDependencyTable(
				Result,
				"UseApprovalThrough1CDocumentManagement",
				True,
				"UseProcessesAndTasks1CDocumentManagement",
				True);
		EndIf;
	EndIf;
	
	If ThereIsSubsystemUPTo3() Then
		AddRowToConstantDependencyTable(
			Result,
			"UseIntegrationWith1CDocumentManagement3",
			False,
			"UseProcessingOf1CDocumentManagementObjects",
			False);
		AddRowToConstantDependencyTable(
			Result,
			"UseIntegrationWith1CDocumentManagement3",
			False,
			"UseAttachedFiles1CDocumentManagement",
			False);
		AddRowToConstantDependencyTable(
			Result,
			"UseIntegrationWith1CDocumentManagement3",
			False,
			"CreateDigitalSignaturesFor1CDocumentManagementObjectsUsingIntegratedSystem",
			False);
		
		// Approval via 1C:Document flow
		AddRowToConstantDependencyTable(
			Result,
			"UseIntegrationWith1CDocumentManagement3",
			False,
			"UseApprovalThrough1CDocumentManagement",
			False);
		If Settings.UseIntegrationBefore3 Then
			AddRowToConstantDependencyTable(
				Result,
				"UseProcessingOf1CDocumentManagementObjects",
				False,
				"UseApprovalThrough1CDocumentManagement",
				False);
			AddRowToConstantDependencyTable(
				Result,
				"UseApprovalThrough1CDocumentManagement",
				True,
				"UseProcessingOf1CDocumentManagementObjects",
				True);
		EndIf;
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreOverridable.WhenRetrievingConstantDependencyTable(Result);
	
	Return Result;
	
EndFunction

// Records changes to an object in the Workflow.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   Object - XDTODataObject - XDTO object with stored data.
//
// Returns:
//   XDTODataObject - An XDTO object of the DMUpdateResponse type.
//
Function WriteObject(Proxy, Object) Export
	
	Return WriteObjects(Proxy, CommonClientServer.ValueInArray(Object));
	
EndFunction

// Records changes to objects in the Workflow.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   Objects - Array of XDTODataObject - an array of XDTO objects with stored data.
//
// Returns:
//   XDTODataObject - An XDTO object of the DMUpdateResponse type.
//
Function WriteObjects(Proxy, Objects) Export
	
	Query = RecordRequestObjects(Proxy, Objects);
	RecordingResult = ExecuteQuery(Proxy, Query);
	CheckWebServiceRefund(Proxy, RecordingResult);
	
	For Each ResultOfXDTO In RecordingResult.objects Do
		If ValidateType(Proxy, ResultOfXDTO, "DMObjectChangeResponseStructure") And ResultOfXDTO.success = False Then
			CheckWebServiceRefund(Proxy, ResultOfXDTO.error);
		EndIf;
	EndDo;
	
	Return RecordingResult;
	
EndFunction

// Returns a request to record changes to objects in the Workflow.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   Objects - Array of XDTODataObject - an array of XDTO objects with stored data.
//
// Returns:
//   XDTODataObject - An XDTO object of the DMUpdateRequest type.
//
Function RecordRequestObjects(Proxy, Objects) Export
	
	Query = CreateObject(Proxy, "DMUpdateRequest");
	ListOfObjects = Query.objects; // XDTOList
	
	For Each Object In Objects Do
		ListOfObjects.Add(Object);
	EndDo;
	
	Return Query;
	
EndFunction

// Records the error in the GR.
//
// Parameters:
//   ErrorText - String - error text.
//   SecondLevelEvent - String - the name of the event that is added through a dot to the default event name.
//   Data - Arbitrary - data that the event is associated with.
//
Procedure WriteError(ErrorText, SecondLevelEvent = "", Val Data = Undefined) Export
	
	If Data <> Undefined Then
		DataType = TypeOf(Data);
		If Not Common.IsReference(DataType) Then
			MetadataObject = Metadata.FindByType(DataType);
			If MetadataObject <> Undefined And Common.IsRefTypeObject(MetadataObject) Then
				Data = Data.Ref;
			EndIf;
		EndIf;
	EndIf;
	
	WriteLogEvent(
		EventLogEventName(SecondLevelEvent),
		EventLogLevel.Error,,
		Data,
		ErrorText);
	
EndProcedure

// Writes an error from an XDTO object of type DMError to the GR.
//
// Parameters:
//   XDTOError - XDTODataObject - XDTO object of type DMError;
//
Procedure RecordXDTOError(XDTOError) Export
	
	ErrorText = TrimAll(XDTOError.description);
	SecondLevelEvent = TrimAll(XDTOError.subject);
	SecondLevelEvent = StrReplace(SecondLevelEvent, ".", "_");
	
	// Let's write the full text of the error in the LR.
	WriteError(ErrorText, SecondLevelEvent);
	
EndProcedure

// Records the warning in the LR.
//
// Parameters:
//   WarningText - String - warning text.
//   SecondLevelEvent - String - the name of the event that is added through a dot to the default event name.
//   Data - Arbitrary - data that the event is associated with.
//
Procedure WriteWarning(WarningText, SecondLevelEvent = "", Data = Undefined) Export
	
	WriteLogEvent(
		EventLogEventName(SecondLevelEvent),
		EventLogLevel.Warning,,
		Data,
		WarningText);
	
EndProcedure

// Fills in the properties of the receiver object by the source object.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   Receiver - XDTODataObject - the object to fill in.
//   Source - XDTODataObject - the source of the fill data.
//
Procedure FillInXDTOPropertyValues(Proxy, Receiver, Source) Export
	
	For Each Property In Source.Properties() Do
		
		DestinationProperty = Receiver.Properties().Get(Property.Name);
		If DestinationProperty <> Undefined
				And (PropertySet(Source, Property.Name)
					Or DestinationProperty.LowerBound <> 0) Then
			
			If TypeOf(Source[Property.Name]) = Type("XDTODataObject") Then
				Object_Property = CreateObject(Proxy, Property.Type.Name);
				FillInXDTOPropertyValues(Proxy, Object_Property, Source[Property.Name]);
				Receiver[Property.Name] = Object_Property;
				
			ElsIf TypeOf(Source[Property.Name]) = Type("XDTOList") Then
				ReceiverList = Receiver[Property.Name]; // XDTOList
				For Each Item In Source[Property.Name] Do
					NewItem = CreateObject(Proxy,Property.Type.Name);
					FillInXDTOPropertyValues(Proxy, NewItem, Item);
					ReceiverList.Add(NewItem);
				EndDo;
				
			Else
				Receiver[Property.Name] = Source[Property.Name];
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Fills in the XDTO object (receiver) using the Attributes (source).
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   Source - ClientApplicationForm, Structure - contains the details or properties
//     by which the XDTO object is filled in.
//   AttributeName - String - the name of the source object props.
//   Receiver - XDTODataObject - contains a property to be filled in.
//   XDTOObjectType - String - the type of the XDTO property to be filled in.
//   AlwaysFillIn - Boolean - indicates that it is filled in, even if the object details are not filled in.
//
Procedure PopulateXDTOObjectFromObjectProps(Proxy, Source, AttributeName, Receiver,
		Val XDTOObjectType = "", AlwaysFillIn = False) Export
	
	If ValueIsFilled(Source[AttributeName])
			Or ValueIsFilled(Source[AttributeName + "ID"])
			Or AlwaysFillIn Then
		If XDTOObjectType = "" Then
			XDTOObjectType = Source[AttributeName + "Type"];
		EndIf;
		Receiver = CreateObject(Proxy, XDTOObjectType);
		Receiver.name = Source[AttributeName];
		Receiver.objectID = CreateObjectID(Proxy, Source[AttributeName + "ID"], Source[AttributeName + "Type"]);
	EndIf;
	
EndProcedure

// Fills in the object Attributes (receiver) for the XDTO object (source).
//
// Parameters:
//   Receiver - Arbitrary - an object containing the requisites or properties
//     that must be filled in by the property of the XDTO object.
//   Source - XDTODataObject, XDTOProperty - the XDTO object or its property, by which the object props will be filled in.
//   AttributeName - String - the name of the object props.
//   FillInPresentation - Boolean - a sign of the need to fill in the presentation details
//     by the ObjectId.presentation property.
//
Procedure FillInObjectDetails(Receiver, Source, AttributeName, FillInPresentation = False) Export
	
	If Source <> Undefined Then
		
		Receiver[AttributeName] = Source.name;
		Receiver[AttributeName + "ID"] = Source.objectID.ID;
		Receiver[AttributeName + "Type"] = Source.objectID.type;
		
		// Older versions of the service do not fill in the view.
		If FillInPresentation Then
			If PropertySet(Source.objectID, "presentation") Then
				Receiver[AttributeName + "Presentation"] = Source.objectID.presentation;
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

// Fills the XDTO object with electronic signatures.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   XDTODataObject - XDTODataObject - an XDTO object with the signatures property where signatures will be added.
//   SignaturesArray - Array of See IntegrationWith1CDocumentManagementCoreClientServer.SignatureData
//
Procedure FillInSignaturesOfXDTOObject(Proxy, XDTODataObject, SignaturesArray) Export
	
	SignaturesList = XDTODataObject.signatures; // XDTOList
	SignaturesList.Clear();
	For Each SignatureData In SignaturesArray Do
		XDTOSignature = CreateObject(Proxy, "DMSignature");
		FillOutXDTOSignature(Proxy, XDTOSignature, SignatureData);
		SignaturesList.Add(XDTOSignature);
	EndDo;
	
EndProcedure

// Fills in the specified form details by the property of the XDTO object.
//
// Parameters:
//   Form - ClientApplicationForm - the form whose details are being filled in.
//   FormAttributeName - String - name of the information to fill in.
//   XDTODataObject - XDTODataObject - the source of the fill data.
//   PropertyNameXDTO - String - name of the data source property.
//
Procedure FillInFormDetailsFromXDTO(Form, FormAttributeName, XDTODataObject, PropertyNameXDTO) Export
	
	If PropertySet(XDTODataObject, PropertyNameXDTO) Then
		XDTOPropertyValue = XDTODataObject[PropertyNameXDTO];
		If TypeOf(XDTOPropertyValue) = Type("XDTODataObject") Then
			Form[FormAttributeName + "Type"] = XDTOPropertyValue.objectID.type;
			Form[FormAttributeName + "ID"] = XDTOPropertyValue.objectID.ID;
			Form[FormAttributeName] = XDTOPropertyValue.name;
		Else
			Form[FormAttributeName] = XDTOPropertyValue;
		EndIf;
	EndIf;
	
EndProcedure

// Fills in the Attributes of the XDTO object for the IP object.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   XDTODataObject - XDTODataObject - the object to fill in.
//   ObjectIS - AnyRef - the source of the filling.
//
Procedure FillInDetailsFromConsumer(Proxy, XDTODataObject, ObjectIS) Export
	
	If ValidateType(Proxy, XDTODataObject, "DMCurrency")
			And TypeOf(ObjectIS) = IntegrationWith1CDocumentManagementCoreCached.CurrencyKind() Then
		Attributes = Common.ObjectAttributesValues(ObjectIS, "Code, DescriptionFull");
		XDTODataObject.code = Attributes.Code;
		XDTODataObject.fullName = Attributes.DescriptionFull;
		
	ElsIf ValidateType(Proxy, XDTODataObject, "DMBank")
			And TypeOf(ObjectIS) = IntegrationWith1CDocumentManagementCoreCached.BankClassifierType() Then
		Code = Common.ObjectAttributeValue(ObjectIS, "Code");
		XDTODataObject.BIC = Code;
		
	ElsIf ValidateType(Proxy, XDTODataObject, "DMCountry")
			And TypeOf(ObjectIS) = IntegrationWith1CDocumentManagementCoreCached.TypeOfCountryInWorld() Then
		Attributes = Common.ObjectAttributesValues(
			ObjectIS,
			"Code, CodeAlpha2, CodeAlpha3, EEUMember, InternationalDescription, DescriptionFull");
		XDTODataObject.code = Attributes.Code;
		XDTODataObject.codeAlpha2 = Attributes.CodeAlpha2;
		XDTODataObject.codeAlpha3 = Attributes.CodeAlpha3;
		XDTODataObject.EAEUMember = Attributes.EEUMember;
		XDTODataObject.longDescription = Attributes.DescriptionFull;
		XDTODataObject.internationalDescription = Attributes.InternationalDescription;
		
	ElsIf ValidateType(Proxy, XDTODataObject, "DMUser")
			And TypeOf(ObjectIS) = IntegrationWith1CDocumentManagementCoreCached.TypeUsers() Then
		Attributes = Common.ObjectAttributesValues(ObjectIS, "Individual, Department");
		If ValueIsFilled(Attributes.Individual) Then
			XDTODataObject.privatePerson = CreateObject(Proxy, "DMPrivatePerson", Attributes.Individual);
		EndIf;
		If ValueIsFilled(Attributes.Department) Then
			XDTODataObject.subdivision = CreateObject(Proxy, "DMSubdivision", Attributes.Department);
		EndIf;
		
	ElsIf ValidateType(Proxy, XDTODataObject, "DMEmployee")
			And TypeOf(ObjectIS) = IntegrationWith1CDocumentManagementCoreCached.TypeUsers() Then
		XDTODataObject.user = CreateObject(Proxy, "DMUser", ObjectIS);
		Attributes = Common.ObjectAttributesValues(ObjectIS, "Individual, Department");
		If ValueIsFilled(Attributes.Individual) Then
			XDTODataObject.privatePerson = CreateObject(Proxy, "DMPrivatePerson", Attributes.Individual);
			XDTODataObject.name = XDTODataObject.privatePerson.name;
		EndIf;
		If ValueIsFilled(Attributes.Department) Then
			XDTODataObject.subdivision = CreateObject(Proxy, "DMSubdivision", Attributes.Department);
		EndIf;
		
	ElsIf (ValidateType(Proxy, XDTODataObject, "DMParty") Or ValidateType(Proxy, XDTODataObject, "DMPartyRowContact"))
			And TypeOf(ObjectIS) = IntegrationWith1CDocumentManagementCoreCached.TypeUsers() Then
		Settings = IntegrationWith1CDocumentManagementCoreServerCall.UseIntegration();
		If Settings.UseIntegrationBefore2 Then
			XDTODataObject.user = CreateObject(Proxy, "DMUser", ObjectIS);
		ElsIf Settings.UseIntegrationBefore3 Then
			XDTODataObject.employee = CreateObject(Proxy, "DMEmployee", ObjectIS);
		EndIf;
		
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreOverridable.FillInDetailsFromConsumer(
		Proxy,
		XDTODataObject,
		ObjectIS);
	
EndProcedure

// returns the unique name of the additional Attribute for later use in integration rules.
//
// Parameters:
//   AdditionalAttribute5 - ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo - additional banking details.
//
// Returns:
//   String - the name of the additional Attribute.
//
Function NameOfAdditionalProps(AdditionalAttribute5) Export
	
	Return StrTemplate("AdditionalAttribute5_%1",
		StrReplace(String(AdditionalAttribute5.UUID()), "-", ""));
	
EndFunction

// Returns the localized name of the log event for integration with UP to.
//
// Parameters:
//   SecondLevelEvent - String - the name of the event that is added through a dot to the default event name.
//
// Returns:
//   String - Integration with 1C:Document
//        management or Integration with 1C:Document management.<Eventname of the second level>.
//
Function EventLogEventName(SecondLevelEvent = "") Export
	
	If SecondLevelEvent = "" Then
		Return NStr("vi = 'Tích hợp với 1C:Document Management';
					|ru = 'Интеграция с 1С:Документооборотом';
					|en = 'Integration with 1C:Document Management'; fa = 'یکپارچگی با 1C:Document Management';
					|it = 'Integrazione con 1C:Document Management';
					|pl = 'Integracja z 1C:Document Management';
					|tr = '1C:Document Management ile entegrasyon'",
			Common.DefaultLanguageCode());
	Else
		Return StrTemplate("%1.%2",
			NStr("vi = 'Tích hợp với 1C:Document Management';
				|ru = 'Интеграция с 1С:Документооборотом';
				|en = 'Integration with 1C:Document Management'; fa = 'یکپارچگی با 1C:Document Management';
				|it = 'Integrazione con 1C:Document Management';
				|pl = 'Integracja z 1C:Document Management';
				|tr = '1C:Document Management ile entegrasyon'",
				Common.DefaultLanguageCode()),
			SecondLevelEvent);
	EndIf;
	
EndFunction

// Returns the index of the image of the directory element.
//
// Returns:
//   Number - index of the image.
//
Function IndexOfImageOfCatalogElement() Export
	
	PictureIndex = 3;
	
	IntegrationWith1CDocumentManagementCoreOverridable.WhenDeterminingIndexOfImageOfCatalogItem(PictureIndex);
	
	Return PictureIndex;
	
EndFunction

// Assigns a base identifier to the new document, if possible.
//
// Parameters:
//   Source - DocumentObject - a recordable document.
//   Cancel - Boolean - indicates that you need to cancel the recording.
//   WriteMode - DocumentWriteMode - the recording mode of the document.
//   PostingMode - DocumentPostingMode - the mode of the document.
//
Procedure IntegrationWith1CDocumentManagementBeforeWriteDocument(Source, Cancel, WriteMode, PostingMode) Export
	
	If Source.DataExchange.Load = True Then
		Return;
	EndIf;
	
	SetNewReferenceBeforeWritingObject(Source);
	
EndProcedure

// Assigns the base identifier to the new directory element, if possible.
//
// Parameters:
//   Source - CatalogObject - a recordable Catalog.
//   Cancel - Boolean - indicates that you need to cancel the recording.
//
Procedure IntegrationWith1CDocumentManagementBeforeWriteCatalog(Source, Cancel) Export
	
	If Source.DataExchange.Load = True Then
		Return;
	EndIf;
	
	SetNewReferenceBeforeWritingObject(Source);
	
EndProcedure

// Checks whether attached files are used BEFORE.
//
// Returns:
//   Boolean
//
Function UseAttachedFiles1CDocumentManagement() Export
	
	Return GetFunctionalOption("UseAttachedFiles1CDocumentManagement");
	
EndFunction

// It works identically to the platform's method of finding a name, but takes into account the mark for deletion.
// Searches for an Catalog item by its name.
// If there are several items with the specified name, then only one of them will be found.
//
// Parameters:
//   Manager - CatalogManager - manager of the Catalog where you want to find the item.
//   Description - String - a string containing the name you are looking for.
//   ExactMap - Boolean - defines the full match search mode.
//     The search will be successful if the search string: if the parameter value is False, it will
//     match the left side of the name; if the parameter value is True, it will
//     completely match the name (except for the "tail" spaces in the name).
//   Parent - CatalogRef - the parent to search within.
//     If not specified, the search will be conducted in the entire Catalog.
//   Owner - CatalogRef - the owner to search within.
//     If not specified, the search will be conducted in the entire Catalog.
//   IncludeMarkedForDeletion - Boolean - True if you need to find an item without taking into account the tag.
//
// Returns:
//   CatalogRef - link to the Catalog item found.
//     If there is no element with the required name, an empty link will be returned.
//   Undefined - if no name is set for the Catalog (length = 0), it will be returned Undefined.
//
Function FindByDescription(Manager, Description, ExactMap = False, Parent = Undefined,
		Owner = Undefined, IncludeMarkedForDeletion = False) Export
	
	ManagerName = StrReplace(String(Manager), "Manager", "");
	If Left(ManagerName, 10) <> "Catalog" Then
		Return Manager.EmptyRef();
	EndIf;
	MetadataObject = Metadata.FindByFullName(ManagerName);
	If MetadataObject.DescriptionLength = 0 Then
		Return Undefined;
	EndIf;
	
	Query = New Query(
		"SELECT TOP 1
		|	Objects.Ref AS Ref
		|FROM
		|	&Manager AS Objects
		|WHERE
		|	&Description
		|	AND &Parent
		|	AND &Owner
		|	AND &DeletionMark");
	Query.Text = StrReplace(Query.Text, "&Manager", ManagerName);
	If ExactMap Then
		Query.Text = StrReplace(Query.Text, "&Description", "Objects.Description = &Description");
		Query.SetParameter("Description", Description);
	Else
		Query.Text = StrReplace(Query.Text, "&Description", "Objects.Description LIKE &Description");
		Query.SetParameter("Description", TrimR(Description) + "%");
	EndIf;
	If ValueIsFilled(Parent) And MetadataObject.Hierarchical Then
		Query.Text = StrReplace(Query.Text, "&Parent", "Objects.Parent = &ParentReference");
		Query.SetParameter("ParentReference", Parent);
	Else
		Query.Text = StrReplace(Query.Text, "&Parent", "TRUE");
	EndIf;
	If ValueIsFilled(Owner) And (MetadataObject.Owners.Count() > 0) Then
		Query.Text = StrReplace(Query.Text, "&Owner", "Objects.Owner = &OwnerLink");
		Query.SetParameter("OwnerLink", Owner);
	Else
		Query.Text = StrReplace(Query.Text, "&Owner", "TRUE");
	EndIf;
	If IncludeMarkedForDeletion Then
		Query.Text = StrReplace(Query.Text, "&DeletionMark", "TRUE");
	Else
		Query.Text = StrReplace(Query.Text, "&DeletionMark", "NOT Objects.DeletionMark");
	EndIf;
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		Return Selection.Ref;
	Else
		Return Manager.EmptyRef();
	EndIf;
	
EndFunction

// Gets the values available for selection by the DMGetObjectListRequest request.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   TypeOfObjectOfChoiceXDTO - String - name of the object type whose values you want to get.
//   ObjectSelectionCriteria - XDTODataObject - an XDTO object of the DMObjectListQuery type.
//
// Returns:
//   XDTODataObject - an XDTO object of the DMGetObjectListResponse type.
//
Function FindListOfObjects(Proxy, TypeOfObjectOfChoiceXDTO, ObjectSelectionCriteria = Undefined) Export
	
	Query = FindListOfObjectsRequest(Proxy, TypeOfObjectOfChoiceXDTO, ObjectSelectionCriteria);
	Response = ExecuteQuery(Proxy, Query);
	CheckWebServiceRefund(Proxy, Response);
	
	Return Response;
	
EndFunction

// Returns a DMGetObjectListRequest request to get the values available for selection.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   TypeOfObjectOfChoiceXDTO - String - name of the object type whose values you want to get.
//   ObjectSelectionCriteria - XDTODataObject - XDTO object of type DMObjectListQuery:
//     * columnConformity - XDTOList
//
// Returns:
//   XDTODataObject - an XDTO object of the DMGetObjectListRequest type.
//
Function FindListOfObjectsRequest(Proxy, TypeOfObjectOfChoiceXDTO, ObjectSelectionCriteria = Undefined) Export
	
	Query = CreateObject(Proxy, "DMGetObjectListRequest");
	Query.type = TypeOfObjectOfChoiceXDTO;
	
	Settings = IntegrationWith1CDocumentManagementCoreServerCall.UseIntegration();
	
	If Settings.UseIntegrationBefore3 Then
		ModuleIntegrationWith1CDocumentManagement3 = Common.CommonModule("IntegrationWith1CDocumentManagement3");
		If ModuleIntegrationWith1CDocumentManagement3.IsDocumentBefore3(TypeOfObjectOfChoiceXDTO)
				Or TypeOfObjectOfChoiceXDTO = "DMCorrespondent"
				Or TypeOfObjectOfChoiceXDTO = "DMMeeting" Then
			ModuleRulesOfIntegrationWith1CDocumentManagement3 =
				Common.CommonModule("Catalogs.RulesForIntegrationWith1CDocumentManagement3");
			ObjectAttributesBefore = ModuleRulesOfIntegrationWith1CDocumentManagement3.ObjectAttributesBefore(
				TypeOfObjectOfChoiceXDTO,
				Undefined,
				True);
			If ObjectSelectionCriteria = Undefined Then
				ObjectSelectionCriteria = CreateObject(Proxy, "DMObjectListQuery");
			EndIf;
			For Each ObjectAttributeBefore In ObjectAttributesBefore Do
				If ObjectAttributeBefore.NameOfAttributeOfVDO = "" Then
					Continue;
				EndIf;
				Map = CreateObject(Proxy, "DMObjectListColumnConformity");
				Map.xdtoPropertyName = ObjectAttributeBefore.Name;
				Map.dmPropertyName = ObjectAttributeBefore.NameOfAttributeOfVDO;
				ObjectSelectionCriteria.columnConformity.Add(Map);
			EndDo;
		EndIf;
	EndIf;
	
	If ObjectSelectionCriteria <> Undefined Then
		Query.query = ObjectSelectionCriteria;
	EndIf;
	
	Return Query;
	
EndFunction

// Retrieves the outgoing message's XDTO object, filled in by default.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   SubjectOf - Structure - description of the item (ID, type).
//
// Returns:
//   XDTODataObject - a new outgoing email.
//
Function NewOutgoingEmail(Proxy, SubjectOf = Undefined) Export
	
	Query = CreateObject(Proxy, "DMGetNewEMailRequest");
	
	Query.type = "DMOutgoingEMail";
	If SubjectOf <> Undefined Then
		Query.targetID = CreateObjectID(Proxy, SubjectOf.ID, SubjectOf.type);
	EndIf;
	
	Response = ExecuteQuery(Proxy, Query);
	CheckWebServiceRefund(Proxy, Response);
	
	If ValidateType(Proxy, Response, "DMGetNewEMailResponse") Then
		Return Response.object;
	Else
		Raise NStr("vi = 'Phiên bản 1C:Document Management này không hỗ trợ tạo e-mail đi';
					|ru = 'Эта версия 1С:Документооборота не поддерживает создание исходящих писем';
					|en = 'This version of 1C:Document Management does not support creation of outgoing emails'; fa = 'This version of 1C:Document Management does not support creation of outgoing emails';
					|it = 'Questa versione di 1C:Document Management non supporta la creazione di posta in uscita';
					|pl = 'Ta wersja 1C:Document Management nie obsługuje utworzenia wiadomości wychodzących';
					|tr = '1C:Document Management''in bu sürümü, giden mektupların oluşturulmasını desteklemiyor'");
	EndIf;
	
EndFunction

// Retrieves the object filled in by default from the Workflow.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   Type - String - the name of the XDTO object type.
//   SubjectOf - Structure - Used to get business processes:
//     * ID - String - the unique identifier of the object in the Workflow.
//     * type - String - the name of the type XDTO.
//   Columns - Array of String - optional, the composition of the columns to be filled in.
//           - String - if the list of columns is separated by commas.
//   DocumentKindDMID - String - ID of the document type, if you want to get a new document of this type.
//
// Returns:
//   XDTODataObject - an XDTO object of the dmgetnewobjectreresponse type.
//
Function NewObjectBefore(Proxy, Type, SubjectOf = Undefined, Columns = Undefined, DocumentKindDMID = "") Export
	
	If SubjectOf <> Undefined Then
		
		Settings = IntegrationWith1CDocumentManagementCoreServerCall.UseIntegration();
		If Type = "DMOutgoingEMail" Then
			Return NewOutgoingEmail(Proxy, SubjectOf);
			
		ElsIf Settings.UseIntegrationBefore2 Then
			ModuleIntegrationWith1CDocumentManagement = Common.CommonModule("IntegrationWith1CDocumentManagement");
			Return ModuleIntegrationWith1CDocumentManagement.NewObjectBefore(Proxy, Type, SubjectOf);
			
		Else
			Return Undefined;
			
		EndIf;
		
	Else
		
		Query = GetNewObjectRequest(Proxy, Type, Columns, DocumentKindDMID);
		Response = ExecuteQuery(Proxy, Query);
		CheckWebServiceRefund(Proxy, Response);
		
		If ValidateType(Proxy, Response, "DMGetNewObjectResponse") Then
			Return Response.object;
		EndIf;
		
		Return Response;
		
	EndIf;
	
EndFunction

// Returns a new object of the specified type.
//
// Parameters:
//   FullName - String - full name of the metadata object. Example: "Directory.Companies".
//
// Returns:
//   DocumentObject
//   Reference Object
//   Type Characterization planobject
//   A kind of settlement planobject
//   Business ProcessObject
//   Taskobject
//
Function NewIPObject(FullName) Export
	
	ObjectManagerIS = Common.ObjectManagerByFullName(FullName);
	ObjectMetadataIS = Metadata.FindByFullName(FullName);
	If Common.IsCatalog(ObjectMetadataIS)
			Or Common.IsChartOfCharacteristicTypes(ObjectMetadataIS) Then
		ObjectIS = ObjectManagerIS.CreateItem();
		
	ElsIf Common.IsDocument(ObjectMetadataIS) Then
		ObjectIS = ObjectManagerIS.CreateDocument();
		
	ElsIf Common.IsChartOfCalculationTypes(ObjectMetadataIS) Then
		ObjectIS = ObjectManagerIS.CreateCalculationType();
		
	ElsIf Common.IsBusinessProcess(ObjectMetadataIS) Then
		ObjectIS = ObjectManagerIS.CreateBusinessProcess();
		
	ElsIf Common.IsTask(ObjectMetadataIS) Then
		ObjectIS = ObjectManagerIS.CreateTask();
		
	Else
		Raise
			StrTemplate(NStr("vi = '1C:Document Management không hỗ trợ tích hợp với các đối tượng kiểu: %1';
							|ru = '1С:Документооборот не поддерживает интеграцию с объектами типа: %1';
							|en = '1C:Document Management does not support integration with objects of the %1 type'; fa = '1C:Document Management does not support integration with objects of the %1 type';
							|it = '1С:Документооборот не поддерживает интеграцию с объектами типа: %1';
							|pl = '1C:Document Management does not support integration with objects of the %1 type';
							|tr = '1C:Document Management şu türdeki nesnelerle entegrasyonu desteklememektedir: %1'"), FullName);
		
	EndIf;
	
	Try
		ObjectIS.Fill(Undefined);
	Except
		WriteError(ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return ObjectIS;
	
EndFunction

// Clears all stored function values with reuse of return values and session parameters.
//
Procedure UpdateReusedParameters() Export
	
	SessionParameters.IntegrationWith1CDocumentManagementSettings = "";
	SessionParameters.IntegrationWith1CDocumentManagementCurrentUser = "";
	RefreshReusableValues();
	
EndProcedure

// The handler of the subscription to the event of the completion processing for documents.
//
// Parameters:
//   Source - DefinedType.IntegrationWith1CDocumentManagementDocumentsObjectsOverridable
//   FillingData - Arbitrary - The value that is used as the basis for filling in.
//   StandardProcessing - Boolean - indicates whether standard event processing is being performed.
//
Procedure ProcessingFillingDocuments(Source, FillingData, StandardProcessing) Export
	
	FillingOfISObject(Source, FillingData, StandardProcessing);
	
EndProcedure

// A handler for subscribing to a fill-in event for directories.
//
// Parameters:
//   Source - DefinedType.IntegrationWith1CDocumentManagementCatalogsObjectsOverridable
//   FillingData - Arbitrary - The value that is used as the basis for filling in.
//   FillingText - String
//                   - Undefined
//   StandardProcessing - Boolean - indicates whether standard event processing is being performed.
//
Procedure ProcessingCatalogContent(Source, FillingData, FillingText, StandardProcessing) Export
	
	FillingOfISObject(Source, FillingData, StandardProcessing);
	
EndProcedure

// Determines whether the BID supports the metadata object of the integrated system.
//
// Parameters:
//   MetadataObject - MetadataObject - the object to determine whether it belongs to the specified type.
//
// Returns:
//   Boolean
//
Function MetadataObjectIsSupported(MetadataObject) Export
	
	Return Common.IsCatalog(MetadataObject)
		Or Common.IsDocument(MetadataObject)
		Or Common.IsChartOfCharacteristicTypes(MetadataObject)
		Or Common.IsChartOfCalculationTypes(MetadataObject)
		Or Common.IsBusinessProcess(MetadataObject)
		Or Common.IsTask(MetadataObject);
	
EndFunction

// Returns a description of the 1C web service:Document management.
//
// Returns:
//   String
//
Function WebServiceDescription() Export
	
	Settings = IntegrationWith1CDocumentManagementCoreServerCall.UseIntegration();
	
	If Settings.UseIntegrationBefore2 Then
		ModuleIntegrationWith1CDocumentManagement = Common.CommonModule("IntegrationWith1CDocumentManagement");
		Return ModuleIntegrationWith1CDocumentManagement.WebServiceDescription();
		
	ElsIf Settings.UseIntegrationBefore3 Then
		ModuleIntegrationWith1CDocumentManagement3 = Common.CommonModule("IntegrationWith1CDocumentManagement3");
		Return ModuleIntegrationWith1CDocumentManagement3.WebServiceDescription();
		
	EndIf;
	
	Return "";
	
EndFunction

// Puts the identifier of the base object in additional properties. Called before writing the object.
//
// Parameters:
//   Form - ClientApplicationForm - the shape of the object being recorded.
//   Object - DocumentObject, CatalogObject - the object being recorded.
//   WriteParameters - Structure - structure containing the record parameters.
//
Procedure BeforeWriteAtServer(Form, Object, WriteParameters) Export
	
	ObjectBefore = IntegrationWith1CDocumentManagementCoreClientServer.ObjectDMFromFormData(Form);
	If ValueIsFilled(ObjectBefore.ID) Then
		Object.AdditionalProperties.Insert("ObjectIDDM", ObjectBefore.ID);
	EndIf;
	
EndProcedure

// Determines the possibility of using OS authentication by the 1C platform:Enterprises.
// Returns True for versions 8.3.7 and older under MS Windows, and False in other cases.
//
// Returns:
//   Boolean
//
Function FAAuthenticationIsSupported() Export
	
	If Not ServerRunsUnderWindows()
			Or Constants.UseOSAuthenticationIn1CDocumentManagementWebService.Get() = False Then
		Return False;
	EndIf;
	
	SystemInfo = New SystemInfo;
	
	Return (CommonClientServer.CompareVersions(SystemInfo.AppVersion, "8.3.7.1") >= 0);
	
EndFunction

// Returns the appropriate consumer type for the XDTO object.
//
// Parameters:
//   CandidateTypes - Array of Type - array of types to select the appropriate one from.
//   XDTOPropertyValue - XDTODataObject - the value of the property of the XDTO object, according to the type of which
//     you need to select the appropriate type.
//   CurrentValueType - Type - if the Attribute of the IP object has a composite type, and some
//     specific value has already been set in it, the type of the Cur value will take precedence when choosing the appropriate type.
//
// Returns:
//   Type - one of the elements of the array is the type of the data that is suitable for the object type XDTO.
//
Function SuitableType(CandidateTypes, XDTOPropertyValue = Undefined, CurrentValueType = Undefined) Export
	
	If CandidateTypes.Count() = 0 Then
		
		SuitableType = Undefined;
		
	ElsIf CandidateTypes.Count() = 1 Then
		
		SuitableType = CandidateTypes[0];
		
	Else
		
		XDTOPropertyValueType = TypeOf(XDTOPropertyValue);
		ICTypeByValueOfXDTOProperty = Undefined;
		If XDTOPropertyValueType = Type("XDTODataObject") Then
			If PropertyExists(XDTOPropertyValue, "objectID") Then
				XDTOObjectType = XDTOPropertyValue.objectID.type;
			Else
				XDTOObjectType = XDTOPropertyValue.Type().Name;
			EndIf;
			ICTypeByValueOfXDTOProperty = IntegrationWith1CDocumentManagementCoreServerCall.TypeIS(
				XDTOObjectType);
		EndIf;
		
		If CandidateTypes.Find(ICTypeByValueOfXDTOProperty) <> Undefined Then
			SuitableType = ICTypeByValueOfXDTOProperty;
		ElsIf CandidateTypes.Find(CurrentValueType) <> Undefined Then
			SuitableType = CurrentValueType;
		ElsIf CandidateTypes.Find(XDTOPropertyValueType) <> Undefined Then
			SuitableType = XDTOPropertyValueType;
		Else
			SuitableType = CandidateTypes[0];
		EndIf;
		
	EndIf;
	
	Return SuitableType;
	
EndFunction

// Returns the UUID by reference to the IP object.
//
// Parameters:
//   Ref - AnyRef - reference to the IP object.
//
// Returns:
//   String - a string Presentation of the UUID or the name of the enumeration value.
//
Function GetIDFromLink(Ref) Export
	
	If Ref.IsEmpty() Or Not Common.RefExists(Ref) Then
		Return "";
	EndIf;
	
	Type = TypeOf(Ref);
	If Enums.AllRefsType().ContainsType(Type) Then
		Return Common.EnumerationValueName(Ref);
	Else
		Return String(Ref.UUID());
	EndIf;
	
EndFunction

// Returns the type name by reference to the IC object.
//
// Parameters:
//   Ref - AnyRef - reference to the IP object.
//
// Returns:
//   String
//
Function GetLinkTypeName(Ref) Export
	
	RefType = TypeOf(Ref);
	If Common.IsReference(RefType) Then
		// Let's specify the type of external object from the metadata.
		TypeName = Ref.Metadata().FullName();
	Else
		TypeName = String(RefType);
	EndIf;
	
	Return TypeName;
	
EndFunction

// Returns the settings of the Workflow database.
//
// Returns:
//   FixedStructure:
//     * NeedToExtractText - Boolean
//     * UseElectronicDigitalSignatures - Boolean
//     * UseDateAndTimeInTaskDeadlines - Boolean
//     * UseTaskRedirection - Boolean
//     * AddWorkToDailyReportWhenCompletingTask - Boolean
//     * ActualTaskExecutor - String - an XDTO object of type DMActualTasksPerformer.
//     * KeepRecordsOfScannedCopiesOfOriginalDocuments - Boolean
//     * ShowLockedFilesOnExit - Boolean
//     * UseAutoCompleteFiles - Boolean
//     * ChangeJobsBackdated - Boolean
//     * ShowPDFUsing1C - Boolean
//     * TitleOfMessageInPreviewArea - String
//     * ListOfExtensionsOfScannedCopiesOfOriginals - String
//     * TasksAreAvailableToMe - Boolean
//     * ListOfTaskExecutors - Array of See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//
Function GetSettings() Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	If SessionParameters.IntegrationWith1CDocumentManagementSettings = "" Then
		
		Query = GetRequestSettings(Proxy);
		
		XDTOSettings = ExecuteQuery(Proxy, Query);
		CheckWebServiceRefund(Proxy, XDTOSettings);
		
	Else
		
		XDTOSettings = StringInXDTOObject(Proxy, SessionParameters.IntegrationWith1CDocumentManagementSettings);
		
	EndIf;
	
	Settings = New Structure;
	
	If PropertySet(XDTOSettings, "needExtractText") Then
		Settings.Insert("NeedToExtractText", XDTOSettings.needExtractText);
	Else
		Settings.Insert("NeedToExtractText", False);
	EndIf;
	
	If PropertySet(XDTOSettings, "useDigitalSignatures") Then
		Settings.Insert("UseElectronicDigitalSignatures", XDTOSettings.useDigitalSignatures);
	Else
		Settings.Insert("UseElectronicDigitalSignatures", False);
	EndIf;
	
	If PropertySet(XDTOSettings, "useBothDateAndTimeInTasksDueDates") Then
		Settings.Insert("UseDateAndTimeInTaskDeadlines", XDTOSettings.useBothDateAndTimeInTasksDueDates);
	Else
		Settings.Insert("UseDateAndTimeInTaskDeadlines", False);
	EndIf;
	
	If PropertySet(XDTOSettings, "useTasksForwarding") Then
		Settings.Insert("UseTaskRedirection", XDTOSettings.useTasksForwarding);
	Else
		Settings.Insert("UseTaskRedirection", True);
	EndIf;
	
	If PropertySet(XDTOSettings, "addActualWorkUponTaskExecution") Then
		Settings.Insert("AddWorkToDailyReportWhenCompletingTask",
			XDTOSettings.addActualWorkUponTaskExecution);
	Else
		Settings.Insert("AddWorkToDailyReportWhenCompletingTask", False);
	EndIf;
	
	ActualTaskExecutor = "taskPerformer";
	If PropertySet(XDTOSettings, "actualTasksPerformer") Then
		ActualTaskExecutor = XDTOSettings.actualTasksPerformer;
	EndIf;
	Settings.Insert("ActualTaskExecutor", ActualTaskExecutor);
	
	If PropertySet(XDTOSettings, "accountForScannedOriginals") Then
		Settings.Insert("KeepRecordsOfScannedCopiesOfOriginalDocuments", XDTOSettings.accountForScannedOriginals);
	Else
		Settings.Insert("KeepRecordsOfScannedCopiesOfOriginalDocuments", False);
	EndIf;
	
	If PropertySet(XDTOSettings, "showLockedFilesOnExit") Then
		Settings.Insert("ShowLockedFilesOnExit", XDTOSettings.showLockedFilesOnExit);
	Else
		Settings.Insert("ShowLockedFilesOnExit", False);
	EndIf;
	
	If PropertySet(XDTOSettings, "useAutoFill") Then
		Settings.Insert("UseAutoCompleteFiles", XDTOSettings.useAutoFill);
	Else
		Settings.Insert("UseAutoCompleteFiles", False);
	EndIf;
	
	If PropertySet(XDTOSettings, "allowToChangeEndDate") Then
		Settings.Insert("ChangeJobsBackdated", XDTOSettings.allowToChangeEndDate);
	Else
		Settings.Insert("ChangeJobsBackdated", True);
	EndIf;
	
	If PropertySet(XDTOSettings, "showPdfBy1C") Then
		Settings.Insert("ShowPDFUsing1C", XDTOSettings.showPdfBy1C);
	Else
		Settings.Insert("ShowPDFUsing1C", False);
	EndIf;
	
	If PropertySet(XDTOSettings, "htmlViewMessageHead") Then
		Settings.Insert("TitleOfMessageInPreviewArea", XDTOSettings.htmlViewMessageHead);
	Else
		Settings.Insert("TitleOfMessageInPreviewArea",
			"<head>
			|<style type=""text/css"">
			|.block
			|{
			|	width: 45%;
			|	padding: 5% 20% 25% 25%;
			|	font-size: 150%;
			|	text-align: center;
			|	position:absolute;
			|}
			|a:link {
			|	color: #006699; text-decoration: none;}
			|a:visited {
			|	color: #006699; text-decoration: none;}
			|a:hover {
			|	color: #006699; text-decoration: underline;}
			|</style>
			|</head>");
	EndIf;
	
	If PropertySet(XDTOSettings, "scannedOriginalExtensionsList") Then
		Settings.Insert("ListOfExtensionsOfScannedCopiesOfOriginals", XDTOSettings.scannedOriginalExtensionsList);
	Else
		Settings.Insert("ListOfExtensionsOfScannedCopiesOfOriginals", "");
	EndIf;
	
	If PropertySet(XDTOSettings, "tasksAvailable") Then
		Settings.Insert("TasksAreAvailableToMe", XDTOSettings.tasksAvailable);
	Else
		Settings.Insert("TasksAreAvailableToMe", True);
	EndIf;
	
	ListOfTaskExecutors = New Array;
	If PropertySet(XDTOSettings, "taskPerformers") Then
		For Each XDTODataObject In XDTOSettings.taskPerformers Do
			TaskExecutor = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
				XDTODataObject.objectID.id,
				XDTODataObject.objectID.type,
				XDTODataObject.name);
			ListOfTaskExecutors.Add(TaskExecutor);
		EndDo;
	EndIf;
	Settings.Insert("ListOfTaskExecutors", ListOfTaskExecutors);
	
	Return New FixedStructure(Settings);
	
EndFunction

// Returns a request to get the Workflow database settings.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//
// Returns:
//   XDTODataObject - an XDTO object of the DMGetSettingsRequest type.
//
Function GetRequestSettings(Proxy) Export
	
	Return CreateObject(Proxy, "DMGetSettingsRequest");
	
EndFunction

// Returns a request to get the default object from the Workflow.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   Type - String - the name of the XDTO object type.
//   Columns - Array of String - optional, the composition of the columns to be filled in.
//           - String - if the list of columns is separated by commas.
//   DocumentKindDMID - String - ID of the document type, if you want to get a new document of this type.
//
// Returns:
//   XDTODataObject - an XDTO object of the DMGetNewObjectRequest type.
//
Function GetNewObjectRequest(Proxy, Type, Columns = Undefined, DocumentKindDMID = "") Export
	
	Query = CreateObject(Proxy, "DMGetNewObjectRequest");
	FieldsReceived = Query.columnSet; // XDTOList
	
	Query.type = Type;
	
	If Columns <> Undefined Then
		If TypeOf(Columns) = Type("String") Then
			Columns = StrSplit(Columns, ",");
		EndIf;
		
		For Each Column In Columns Do
			FieldsReceived.Add(Column);
		EndDo;
	EndIf;
	
	If ValueIsFilled(DocumentKindDMID) Then
		Query.documentType = CreateObjectID(Proxy, DocumentKindDMID, "DMDocumentType");
	EndIf;
	
	Return Query;
	
EndFunction

// Retrieves an object from the Workflow.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   Type - String - the name of the type XDTO.
//   ID - String - the unique identifier of the object in the Document Flow.
//   Columns - Array of String - optional, the composition of the columns to be filled in.
//           - String - if the list of columns is separated by commas.
//   IntegrationRule - CatalogRef.RulesForIntegrationWith1CDocumentManagement3 - integration rule for
//     filling in the IP object.
//   ExternalIPObject - AnyRef - passed to fill in the externalObject property.
//
// Returns:
//   XDTODataObject - an XDTO object of the specified type.
//
Function GetObject(Proxy, Type, ID, Columns = Undefined, IntegrationRule = Undefined,
		ExternalIPObject = Undefined) Export
	
	Object = New Structure("ID, Type, ExternalIPObject", ID, Type, ExternalIPObject);
	
	Response = GetObjects(
		Proxy,
		CommonClientServer.ValueInArray(Object),
		Columns,
		IntegrationRule);
	
	If Response.Count() > 0 Then
		Return Response[0];
	Else
		Raise StrTemplate(NStr("vi = 'Không thể nhận đối tượng DM: %1 (%2)';
								|ru = 'Не удалось получить объект ДО: %1 (%2)';
								|en = 'Cannot get the DI object: %1 (%2)'; fa = 'Cannot get the DI object: %1 (%2)';
								|it = 'Не удалось получить объект ДО: %1 (%2)';
								|pl = 'Cannot get the DI object: %1 (%2)';
								|tr = 'İş Akışı nesnesi alınamadı: %1 (%2)'"), ID, Type);
	EndIf;
	
EndFunction

// Retrieves objects from the workflow.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   Objects - Array of Structure:
//     * ID - String
//     * Type - String
//     * ExternalIPObject - AnyRef - passed to fill in the externalObject property.
//   Columns - Array of String - optional, the composition of the columns to be filled in.
//           - String - if the list of columns is separated by commas.
//   IntegrationRule - CatalogRef.RulesForIntegrationWith1CDocumentManagement3 - integration rule for
//     filling in the IP object.
//
// Returns:
//   XDTOList - list of XDTO objects of the specified type.
//
Function GetObjects(Proxy, Objects, Columns = Undefined, IntegrationRule = Undefined) Export
	
	Query = GetRequestObjects(Proxy, Objects, Columns, IntegrationRule);
	Response = ExecuteQuery(Proxy, Query);
	CheckWebServiceRefund(Proxy, Response);
	
	Return Response.objects;
	
EndFunction

// Returns a request to get objects from the Workflow.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   Objects - Array of Structure:
//     * ID - String
//     * Type - String
//     * ExternalIPObject - AnyRef - passed to fill in the externalObject property.
//   Columns - Array of String - optional, the composition of the columns to be filled in.
//           - String - if the list of columns is separated by commas.
//   IntegrationRule - CatalogRef.RulesForIntegrationWith1CDocumentManagement3 - integration rule for
//     filling in the IP object.
//
// Returns:
//   XDTODataObject - an XDTO object of the DMRetrieveRequest type.
//
Function GetRequestObjects(Proxy, Objects, Columns = Undefined, IntegrationRule = Undefined) Export
	
	Query = CreateObject(Proxy, "DMRetrieveRequest");
	ListOfObjects = Query.objectIDs; // XDTOList
	FieldsReceived = Query.columnSet; // XDTOList
	TransferOfLinksIsSupported = False;
	If PropertyExists(Query, "links") Then
		TransferOfLinksIsSupported = True;
		XDTOConnections = Query.links; // XDTOList
	EndIf;
	
	ExpressionsToExecuteOnSideDM = New Array;
	ListOfExpressions = Undefined;
	If IntegrationRule <> Undefined And PropertyExists(Query, "objectsExpressionRows") Then
		Settings = IntegrationWith1CDocumentManagementCoreServerCall.UseIntegration();
		If Settings.UseIntegrationBefore3 Then
			ModuleIntegrationWith1CDocumentManagement3 = Common.CommonModule("IntegrationWith1CDocumentManagement3");
			ModuleRulesOfIntegrationWith1CDocumentManagement3 =
				Common.CommonModule("Catalogs.RulesForIntegrationWith1CDocumentManagement3");
			RulesForAnalysis = CommonClientServer.ValueInArray(IntegrationRule);
			ExpressionsToExecuteOnSideDM =
				ModuleRulesOfIntegrationWith1CDocumentManagement3.ExpressionsToExecuteOnSideDM(RulesForAnalysis);
			ListOfExpressions = Query.objectsExpressionRows; // XDTOList
		EndIf;
	EndIf;
	
	For Each Object In Objects Do
		
		ExternalIPObject = Undefined;
		Object.Property("ExternalIPObject", ExternalIPObject);
		If TransferOfLinksIsSupported And ValueIsFilled(ExternalIPObject) Then
			XDTOConnections.Add(
				CreateDMLink(
					Proxy,
					Object.ID,
					Object.Type,
					ExternalIPObject));
		EndIf;
		
		objectID = CreateObjectID(Proxy, Object.ID, Object.Type);
		ListOfObjects.Add(objectID);
		
		If ListOfExpressions <> Undefined Then
			
			ComplianceWithXDTORules = CreateObject(Proxy, "DMObjectExpressionRow");
			ComplianceWithXDTORules.object = CreateObjectID(Proxy, Object.ID, Object.Type);
			
			For Each ExpressionToExecuteOnDMSide In ExpressionsToExecuteOnSideDM Do
				ExpressionOfXDTORule = CreateObject(Proxy, "DMExpressionRow");
				ModuleIntegrationWith1CDocumentManagement3.PrepareCalculatedExpressionToBeTransferredToDMSide(
					ExpressionOfXDTORule,
					ExpressionToExecuteOnDMSide);
				ComplianceWithXDTORules.expressionRows.Add(ExpressionOfXDTORule);
			EndDo;
			
			If ComplianceWithXDTORules.expressionRows.Count() > 0 Then
				ListOfExpressions.Add(ComplianceWithXDTORules);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If Columns <> Undefined Then
		If TypeOf(Columns) = Type("String") Then
			Columns = StrSplit(Columns, ",");
		EndIf;
		
		For Each Column In Columns Do
			FieldsReceived.Add(TrimAll(Column));
		EndDo;
	EndIf;
	
	Return Query;
	
EndFunction

// Creates a proxy for a Workflow web service with authorization settings from session parameters or, if this
// is not possible, for example, when creating a proxy in a background task, with settings passed directly.
//
// Parameters:
//   RaiseException1 - Boolean - True if an exception should be raised if it is impossible to get it.
//   AuthorizationSettings - See IntegrationWith1CDocumentManagementCoreClientServer.AuthorizationSettingsIn1CDocumentManagement
//   AddressOfDocumentManagementWebService - String - the address of the web service BEFORE, or
//                                   - Undefined - indicates the need to use a previously saved address.
//   ErrorMessageText - String - implicitly returned value, error message text.
//   UserOfExchangeTask - Boolean - The call is made to configure the user of the exchange job.
//     the Cur user's session settings will not be changed.
//
// Returns:
//   WSProxy - proxy of the Document management web service.
//   Undefined - in case the proxy of the web service could not be obtained.
//
Function GetProxy(RaiseException1 = True, AuthorizationSettings = Undefined,
		AddressOfDocumentManagementWebService = Undefined, ErrorMessageText = "",
		UserOfExchangeTask = False) Export
	
	If ValueIsFilled(SessionParameters.Integration1CDocumentManagementXMLSchema) Then
		// Workflow is waiting for a response from the DMILService web service. Connecting to a web service
		// Document management is not possible at this moment.
		Return Undefined;
	EndIf;
	
	If AuthorizationSettings = Undefined Then
		AuthorizationSettings =
			IntegrationWith1CDocumentManagementCoreClientServer.AuthorizationSettingsIn1CDocumentManagement();
	EndIf;
	
	If AuthorizationSettings.Use_Cache And SessionParameters.IntegrationWith1CDocumentManagementPasswordIsKnown
			And ((AuthorizationSettings.UserName = Undefined)
				Or (AuthorizationSettings.UserName = SessionParameters.IntegrationWith1CDocumentManagementUsername))
			And ((AuthorizationSettings.Password = Undefined)
				Or (AuthorizationSettings.Password = SessionParameters.IntegrationWith1CDocumentManagementPassword)) Then
		Try
			Proxy = GetProxyFromSessionParameters();
			If Proxy <> Undefined Then
				AuthorizationSettings.OSAuthenticationIsUsed =
					SessionParameters.IntegrationWith1CDocumentManagementOSAuthenticationIsUsed;
				AuthorizationSettings.JWTAuthenticationIsUsed =
					SessionParameters.IntegrationWith1CDocumentManagementJWTTokenAuthenticationIsUsed;
				Return Proxy;
			EndIf;
		Except
			Proxy = Undefined;
		EndTry;
	EndIf;
	
	If AddressOfDocumentManagementWebService = Undefined Then
		AddressOfDocumentManagementWebService = AddressOf1CDocumentManagementWebService();
	Else
		ProcessAddressOf1CDocumentManagementWebService(AddressOfDocumentManagementWebService);
	EndIf;
	
	If Not ValueIsFilled(AddressOfDocumentManagementWebService) Then
		ErrorMessageText = NStr("vi = 'Chưa chỉ ra địa chỉ Web-service 1C:Document Management.';
								|ru = 'Не указан адрес веб-сервиса 1С:Документооборота.';
								|en = 'Address of 1C:Document Management web service is not specified.'; fa = 'Address of 1C:Document Management web service is not specified.';
								|it = 'Indirizzo del servizio web di 1C:Document Management non indicato.';
								|pl = 'Nie podano adresu usługi webowej 1C:Document Management.';
								|tr = '1C:Document Management web hizmetinin adresi belirtilmedi.'");
		WriteWarning(ErrorMessageText);
		If RaiseException1 Then
			Raise ErrorMessageText;
		Else
			Return Undefined;
		EndIf;
	EndIf;
	
	ServiceData_ = DocumentManagementWebServiceData(AddressOfDocumentManagementWebService, UserOfExchangeTask);
	
	AuthorizationSettings.OSAuthenticationIsUsed = False;
	AuthorizationSettings.JWTAuthenticationIsUsed = False;
	
	If AuthorizationSettings.UserName = Undefined Then
		AuthorizationSettings.UserName = SessionParameters.IntegrationWith1CDocumentManagementUsername;
	EndIf;
	
	If AuthorizationSettings.Password = Undefined Then
		AuthorizationSettings.Password = SessionParameters.IntegrationWith1CDocumentManagementPassword;
	EndIf;
	
	ProxyLocation = Undefined;
	ErrorMessageText = "";
	
	UseNameOfWebService = True;
	DefiningWebServiceBEFORE = DefiningWebServiceBEFORE(
		AddressOfDocumentManagementWebService,
		ServiceData_,
		UseNameOfWebService,
		AuthorizationSettings,
		ProxyLocation,
		ErrorMessageText);
	If DefiningWebServiceBEFORE = Undefined Then
		UseNameOfWebService = False;
		DefiningWebServiceBEFORE = DefiningWebServiceBEFORE(
			AddressOfDocumentManagementWebService,
			ServiceData_,
			UseNameOfWebService,
			AuthorizationSettings,
			ProxyLocation,
			ErrorMessageText);
	EndIf;
	
	If DefiningWebServiceBEFORE = Undefined Then
		
		If Not ValueIsFilled(AuthorizationSettings.UserName)
				And Not AuthorizationSettings.OSAuthenticationIsUsed
				And Not AuthorizationSettings.JWTAuthenticationIsUsed Then
			AddTextOfErrorMessage(
				ErrorMessageText,
				NStr("vi = 'Chưa chỉ ra tên người sử dụng 1C:Document Management.';
					|ru = 'Не указано имя пользователя 1С:Документооборота.';
					|en = '1C:Document Management username is not specified.'; fa = '1C:Document Management username is not specified.';
					|it = 'Не указано имя пользователя 1С:Документооборота.';
					|pl = 'Nie podano nazwy użytkownika 1C:Document Management.';
					|tr = '1C:Document Management kullanıcı adı belirtilmedi.'"));
		EndIf;
		
		If AuthorizationSettings.Password = Undefined
				And Not SessionParameters.IntegrationWith1CDocumentManagementPasswordIsKnown
				And Not AuthorizationSettings.OSAuthenticationIsUsed
				And Not AuthorizationSettings.JWTAuthenticationIsUsed Then
			AddTextOfErrorMessage(
				ErrorMessageText,
				NStr("vi = 'Chưa chỉ ra mật khẩu để đăng nhập vào 1C:Document Management.';
					|ru = 'Не указан пароль для авторизации в 1С:Документооборот.';
					|en = 'Password for authorization in 1C:Document Management is not specified.'; fa = 'Password for authorization in 1C:Document Management is not specified.';
					|it = 'Не указан пароль для авторизации в 1С:Документооборот.';
					|pl = 'Password for authorization in 1C:Document Management is not specified.';
					|tr = '1C:Document Management''te yetkilendirme şifresi belirtilmedi.'"));
		EndIf;
		
		SessionParameters.IntegrationWith1CDocumentManagementPasswordIsKnown = False;
		SessionParameters.IntegrationWith1CDocumentManagementServiceVersion = "0.0.0.0";
		
		WriteWarning(ErrorMessageText);
		If RaiseException1 Then
			Raise NStr("vi = 'Lỗi kết nối đến 1C:Document Management.
				|
				|Có thể là chưa đăng nhập, đã chỉ ra sai địa chỉ Web-service
				|hoặc cơ sở 1C:Document Management chưa được đăng tải trên Web-server.
				|
				|Chi tiết xem trong nhật ký sự kiện. Hãy liên hệ với người quản trị hệ thống.';
				|ru = 'Ошибка подключения к 1С:Документообороту.
				|
				|Возможно, не прошла авторизация, указан неверный адрес веб-сервиса
				|или база 1С:Документооборота не опубликована на веб-сервере.
				|
				|Подробности в журнале регистрации. Обратитесь к администратору системы.';
				|en = '1C:Document Management connection error.
				|
				|Authorization might fail, the web service address is incorrect 
				|or the 1C:Document Management base is not published on the web server.
				|
				|See the event log. Contact your system administrator.'; fa = '1C:Document Management connection error.
				|
				|Authorization might fail, the web service address is incorrect 
				|or the 1C:Document Management base is not published on the web server.
				|
				|See the event log. Contact your system administrator.';
				|it = 'Ошибка подключения к 1С:Документообороту.
				|
				|Возможно, не прошла авторизация, указан неверный адрес веб-сервиса
				|или база 1С:Документооборота не опубликована на веб-сервере.
				|
				|Подробности в журнале регистрации. Обратитесь к администратору системы.';
				|pl = '1C:Document Management connection error.
				|
				|Authorization might fail, the web service address is incorrect 
				|or the 1C:Document Management base is not published on the web server.
				|
				|See the event log. Contact your system administrator.';
				|tr = '1C:Document Management''te bağlanırken hata.
				|
				|Belki yetkilendirme başarısız oldu, yanlış web hizmeti adresi
				|belirtildi veya 1C:Document Management veritabanı web sunucusunda yayınlanmadı.
				|
				|Ayrıntılar kayıt günlüğünde. Sistem yöneticisine başvur.'");
		Else
			Return Undefined;
		EndIf;
		
	EndIf;
	
	Try
		
		Proxy = New WSProxy(
			DefiningWebServiceBEFORE,
			ServiceData_.URIOfNamespaceOfWorkflowWebService,
			ServiceData_.NameOfDocumentManagementWebService,
			ServiceData_.NameOfDocumentManagementWebService + "Soap",
			ServiceData_.InternetProxy,
			ServiceData_.Timeout,
			ServiceData_.SecureConnection,
			ProxyLocation,
			AuthorizationSettings.OSAuthenticationIsUsed);
		If ServiceVersion() = "0.0.0.0" Then
			// The service was not available before, but now access to it has appeared. We will define and install its version.
			ErrorText = "";
			IntegrationWith1CDocumentManagementCoreServerCall.SetServiceVersionInSessionSettings(,
				ErrorText);
			If ErrorText <> "" Then
				If RaiseException1 Then
					Raise ErrorText;
				Else
					AddTextOfErrorMessage(
						ErrorMessageText,
						ErrorText);
					Return Undefined;
				EndIf;
			EndIf;
		EndIf;
		
	Except
		
		SessionParameters.IntegrationWith1CDocumentManagementPasswordIsKnown = False;
		SessionParameters.IntegrationWith1CDocumentManagementServiceVersion = "0.0.0.0";
		
		ErrorMessageText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteWarning(ErrorMessageText);
		If RaiseException1 Then
			Raise NStr("vi = 'Lỗi kết nối đến 1C:Document Management.
				|
				|Có thể là chưa đăng nhập, đã chỉ ra sai địa chỉ Web-service
				|hoặc cơ sở 1C:Document Management chưa được đăng tải trên Web-server.
				|
				|Chi tiết xem trong nhật ký sự kiện. Hãy liên hệ với người quản trị hệ thống.';
				|ru = 'Ошибка подключения к 1С:Документообороту.
				|
				|Возможно, не прошла авторизация, указан неверный адрес веб-сервиса
				|или база 1С:Документооборота не опубликована на веб-сервере.
				|
				|Подробности в журнале регистрации. Обратитесь к администратору системы.';
				|en = '1C:Document Management connection error.
				|
				|Authorization might fail, the web service address is incorrect 
				|or the 1C:Document Management base is not published on the web server.
				|
				|See the event log. Contact your system administrator.'; fa = '1C:Document Management connection error.
				|
				|Authorization might fail, the web service address is incorrect 
				|or the 1C:Document Management base is not published on the web server.
				|
				|See the event log. Contact your system administrator.';
				|it = 'Ошибка подключения к 1С:Документообороту.
				|
				|Возможно, не прошла авторизация, указан неверный адрес веб-сервиса
				|или база 1С:Документооборота не опубликована на веб-сервере.
				|
				|Подробности в журнале регистрации. Обратитесь к администратору системы.';
				|pl = '1C:Document Management connection error.
				|
				|Authorization might fail, the web service address is incorrect 
				|or the 1C:Document Management base is not published on the web server.
				|
				|See the event log. Contact your system administrator.';
				|tr = '1C:Document Management''te bağlanırken hata.
				|
				|Belki yetkilendirme başarısız oldu, yanlış web hizmeti adresi
				|belirtildi veya 1C:Document Management veritabanı web sunucusunda yayınlanmadı.
				|
				|Ayrıntılar kayıt günlüğünde. Sistem yöneticisine başvur.'");
		Else
			Return Undefined;
		EndIf;
		
	EndTry;
	
	If Not AuthorizationSettings.OSAuthenticationIsUsed
			And Not AuthorizationSettings.JWTAuthenticationIsUsed Then
		Proxy.User = AuthorizationSettings.UserName;
		Proxy.Password = AuthorizationSettings.Password;
	EndIf;
	
	Return Proxy;
	
EndFunction

// Determines the availability of integration for the current user. It can be redefined
// if you refuse to use the supplied role using Integration and Document management.
//
// Returns:
//   Boolean - True if the use of integration is allowed.
//
Function UserIsAllowedToUseIntegration() Export
	
	Allowed1 = False;
	
	If ThereIsSubsystemUPTo2() Then
		Allowed1 = AccessRight("Use", Metadata.DataProcessors["IntegrationWith1CDocumentManagement"]);
	ElsIf ThereIsSubsystemUPTo3() Then
		Allowed1 = AccessRight("Use", Metadata.DataProcessors["IntegrationWith1CDocumentManagement3"]);
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreOverridable.WhenDeterminingUserPermissionToUseIntegration(Allowed1);
	
	Return Allowed1;
	
EndFunction

// Marks an object for deletion or removes a mark.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   ID - String - ID of the object being marked for deletion in the Document Flow.
//   Type - String - the name of the XDTO type of the object being marked for deletion.
//
// Returns:
//   XDTODataObject - An XDTO object of the DMDeleteResponse type.
//
Function MarkForDeletionMarkItem(Proxy, ID, Type) Export
	
	Object = New Structure("ID, Type", ID, Type);
	
	Response = MarkForDeletionUncheckItems(
		Proxy,
		CommonClientServer.ValueInArray(Object));
	
	Return Response;
	
EndFunction

// Marks objects for deletion or removes the mark.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   Objects - Array of Structure:
//     * ID - String
//     * Type - String
//
// Returns:
//   XDTODataObject - An XDTO object of the DMDeleteResponse type.
//
Function MarkForDeletionUncheckItems(Proxy, Objects) Export
	
	Query = MarkForDeletionUncheckRequestObjects(Proxy, Objects);
	Response = ExecuteQuery(Proxy, Query);
	CheckWebServiceRefund(Proxy, Response);
	
	Return Response;
	
EndFunction

// Returns a request to mark objects for deletion or to remove the mark.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   Objects - Array of Structure:
//     * ID - String
//     * Type - String
//
// Returns:
//   XDTODataObject - An XDTO object of the DMDeleteRequest type.
//
Function MarkForDeletionUncheckRequestObjects(Proxy, Objects) Export
	
	Query = CreateObject(Proxy, "DMDeleteRequest");
	ListOfObjects = Query.objectIDs; // XDTOList
	
	For Each Object In Objects Do
		objectID = CreateObjectID(Proxy, Object.ID, Object.Type);
		ListOfObjects.Add(objectID);
	EndDo;
	
	Return Query;
	
EndFunction

// Constructor of the structure describing the rule for filling in the Attributes of the object BEFORE.
//
// Parameters:
//   Name - String - the name of the Attribute of the XDTO object.
//   Presentation - String - Presentation of the object's Attributes BEFORE.
//   ShouldUpdate - Boolean - is it required to update the Attribute of the IP object from the Attribute of the object TO.
//
// Returns:
//   Structure:
//     * Name - String - the name of the Attribute of the XDTO object.
//     * Presentation - String - Presentation of the object's Attributes BEFORE.
//     * ShouldUpdate - Boolean - is it required to update the Attribute of the IP object from the Attribute of the object TO.
//     * IsAdditionalAttributeDM - Boolean - This is an additional Attribute of the object BEFORE.
//
Function RuleForFillingInFromObjectAttributesTO(Name, Presentation = "", ShouldUpdate = True) Export
	
	FillingRule = New Structure;
	FillingRule.Insert("Name", Name);
	FillingRule.Insert("Presentation", Presentation);
	FillingRule.Insert("ShouldUpdate", ShouldUpdate);
	FillingRule.Insert("IsAdditionalAttributeDM", False);
	
	Return FillingRule;
	
EndFunction

// Returns the maximum number of objects selected by the service when receiving lists.
//
// Parameters:
//   Type - String - object type XDTO
//
// Returns:
//   Number - maximum number of elements to be selected at a time
//
Function MaximumNumberOfSelectedObjects(Type) Export
	
	MaximumQuantity = 20;
	
	IntegrationWith1CDocumentManagementCoreOverridable.WhenDeterminingMaximumNumberOfSelectedObjects(
		Type, MaximumQuantity);
	
	Return MaximumQuantity;
	
EndFunction

// Returns the maximum number of attempts to send an exchange message.
//
// Returns:
//   Number
//
Function MaximumNumberOfAttemptsToSendExchangeMessage() Export
	
	Return 4;
	
EndFunction

// Requests a reference to a predefined Workflow object by the specified name and type.
//
// Parameters:
//   ObjectType - String - The name of the XDTO class whose predefined object you want to get.
//   PredefinedItemName1 - String - name of the predefined element.
//
// Returns:
//   XDTODataObject - An XDTO object of type DMObject.
//
Function PredefinedValueBefore(ObjectType, PredefinedItemName1) Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Query = CreateObject(Proxy, "DMGetPredefinedObjectRequest");
	Query.type = ObjectType;
	Query.predefinedObjectName = PredefinedItemName1;
	
	Result = ExecuteQuery(Proxy, Query);
	CheckWebServiceRefund(Proxy, Result);
	
	Return Result.result;
	
EndFunction

// Returns a Presentation of the Document Flow object type XDTO by type name.
// By default, it returns a singular Presentation.
//
// Parameters:
//   XDTOType - String - the name of the XDTO object type.
//   PluralForm - Boolean - It is required to return the Presentation in the plural.
//   ForFormOfSelection - Boolean - it is required to return a Presentation for the selection Form starting with "Selection ...".
//
// Returns:
//   String - representation of the type of the Document Flow object XDTO by type name.
//
Function ObjectTypePresentationXDTO(XDTOType, PluralForm = False, ForFormOfSelection = False) Export
	
	Settings = IntegrationWith1CDocumentManagementCoreServerCall.UseIntegration();
	
	If Settings.UseIntegrationBefore2 Then
		ModuleIntegrationWith1CDocumentManagementClientServer = Common.CommonModule(
			"IntegrationWith1CDocumentManagementClientServer");
		Return ModuleIntegrationWith1CDocumentManagementClientServer.ObjectTypePresentationXDTO(
			XDTOType,
			PluralForm,
			ForFormOfSelection);
		
	ElsIf Settings.UseIntegrationBefore3 Then
		ModuleIntegrationWith1CDocumentManagement3ClientServer = Common.CommonModule(
			"IntegrationWith1CDocumentManagement3ClientServer");
		Return ModuleIntegrationWith1CDocumentManagement3ClientServer.ObjectTypePresentationXDTO(
			XDTOType,
			PluralForm,
			ForFormOfSelection);
		
	EndIf;
	
EndFunction

// Called when writing the constants of the subsystem Integration with 1C:Document management.
//
// Parameters:
//   Source - ConstantValueManager - a recordable constant.
//   Cancel - Boolean - the flag for refusing to perform the recording.
//
Procedure WhileSavingConstant(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreOverridable.WhileSavingConstant(Source, Cancel);
	
	ConstantName = Source.ThisObject.Metadata().Name;
	ConstantValue = Source.Value;
	
	ConstantType = TypeOf(ConstantValue);
	PrimitiveTypes = New TypeDescription("Number,String,Date,Boolean,Undefined");
	
	SetPrivilegedMode(True);
	
	// Synchronize "simple" dependent constants
	If PrimitiveTypes.ContainsType(ConstantType) Or Common.RefTypeValue(ConstantValue) Then
		
		SubordinateConstants = GetValidValuesOfSubordinateConstants(ConstantName, ConstantValue);
		
		If ValueIsFilled(SubordinateConstants) Then
			
			For Each KeyAndValue In SubordinateConstants Do
				If Constants[KeyAndValue.Key].Get() <> KeyAndValue.Value Then
					Constants[KeyAndValue.Key].Set(KeyAndValue.Value);
				EndIf;
			EndDo;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Adds Workflow commands to the object form when created on the server.
//
// Parameters:
//   Form - ClientApplicationForm - the form from which the procedure is called.
//   CommandLocation - FormGroup - the default location is the command panel of the form.
//   NotificationParameters - Structure - parameters where the command source can be set.
//   Ref - AnyRef - a reference to the IP object, which is the main object of the Form.
//
Procedure OnCreateAtServer(Form, CommandLocation = Undefined, NotificationParameters = Undefined,
		Ref = Undefined) Export
	
	If Not UserIsAllowedToUseIntegration() Then
		Return;
	EndIf;
	
	FormAttributes = Form.GetAttributes();
	
	// Add the missing Attributes of the form.
	AttributesToBeAdded = New Array;
	If FormAttributeByName(FormAttributes, "UseIntegrationBefore2") = Undefined Then
		AttributesToBeAdded.Add(New FormAttribute(
			"UseIntegrationBefore2",
			New TypeDescription("Boolean"),,
			NStr("vi = 'Sử dụng tích hợp với 1C:Document Management';
				|ru = 'Использовать интеграцию с 1С:Документооборотом';
				|en = 'Use integration with 1C:Document Management'; fa = 'استفاده از یکپارچه‌سازی با 1C:Document Management';
				|it = 'Utilizzare integrazione con 1C:Document Management';
				|pl = 'Używaj integracji z 1C:Document Management';
				|tr = '1C:Document Management ile entegrasyonu kullan'")));
	EndIf;
	If FormAttributeByName(FormAttributes, "UseIntegrationBefore3") = Undefined Then
		AttributesToBeAdded.Add(New FormAttribute(
			"UseIntegrationBefore3",
			New TypeDescription("Boolean"),,
			NStr("vi = 'Sử dụng tích hợp với 1C:Document Management phiên bản 3';
				|ru = 'Использовать интеграцию с 1С:Документооборотом редакции 3';
				|en = 'Use integration with 1C:Document Management (revision 3)'; fa = 'استفاده از یکپارچه‌سازی با 1C:Document Management (ویرایش 3)';
				|it = 'Utilizzare integrazione con 1C:Document Management versione 3';
				|pl = 'Używaj integracji z 1C:Document Management edycji 3';
				|tr = '1C:Document Management revizyon 3 ile entegrasyon kullan'")));
	EndIf;
	If FormAttributeByName(FormAttributes, "UseAttachedFiles1CDocumentManagement") = Undefined Then
		AttributesToBeAdded.Add(New FormAttribute(
			"UseAttachedFiles1CDocumentManagement",
			New TypeDescription("Boolean"),,
			NStr("vi = 'Sử dụng tệp đính kèm của 1C:Document Management';
				|ru = 'Использовать присоединенные файлы 1С:Документооборота';
				|en = 'Use attached files of 1C:Document Management'; fa = 'استفاده از فایل‌های پیوست 1C:Document Management';
				|it = 'Utilizzare file allegati di 1C:Document Management';
				|pl = 'Używaj załączonych plików 1C:Document Management';
				|tr = '1C:Document Management ekli dosyalarını kullan'")));
	EndIf;
	If FormAttributeByName(FormAttributes, "NameOfAttributeOfObjectIntegratedWith1CDocumentManagement") = Undefined Then
		AttributesToBeAdded.Add(New FormAttribute(
			"NameOfAttributeOfObjectIntegratedWith1CDocumentManagement",
			New TypeDescription("String"),,
			NStr("vi = 'Tên mục tin có chứa tham chiếu đến đối tượng được tích hợp với 1C:Document Management';
				|ru = 'Имя реквизита, содержащего ссылку на интегрируемый с 1С:Документооборотом объект';
				|en = 'Name of the attribute which contains a link to the object to integrate with 1C:Document Management'; fa = 'Name of the attribute which contains a link to the object to integrate with 1C:Document Management';
				|it = 'Имя реквизита, содержащего ссылку на интегрируемый с 1С:Документооборотом объект';
				|pl = 'Name of the attribute which contains a link to the object to integrate with 1C:Document Management';
				|tr = '1C:Document Management akışı ile entegre edilen nesneye referans içeren özniteliğin adı'")));
	EndIf;
	If Form.Parameters.Property("IntegrationWith1CDocumentManagement_ObjectTypeDM")
			And Form.Parameters.Property("IntegrationWith1CDocumentManagement_ObjectIdentifierDM") Then
		AttributesToBeAdded.Add(New FormAttribute(
			"IntegrationWith1CDocumentManagement_ObjectTypeDM",
			New TypeDescription("String"),,
			NStr("vi = 'Kiểu đối tượng 1C:Document Management';
				|ru = 'Тип объекта 1С:Документооборота';
				|en = '1C:Document Management object type'; fa = 'نوع شیء 1C:Document Management';
				|it = 'Тип объекта 1С:Документооборота';
				|pl = 'Typ obiektu 1C:Document Management';
				|tr = '1C:Document Management nesne türü'")));
		AttributesToBeAdded.Add(New FormAttribute(
			"IntegrationWith1CDocumentManagement_ObjectIdentifierDM",
			New TypeDescription("String"),,
			NStr("vi = 'Định danh đối tượng 1C:Document Management';
				|ru = 'Идентификатор объекта 1С:Документооборота';
				|en = '1C:Document Management object ID'; fa = 'شناسه شیء 1C:Document Management';
				|it = 'Идентификатор объекта 1С:Документооборота';
				|pl = 'Identyfikator obiektu 1C:Document Management';
				|tr = '1C:Document Management nesnesi kimliği'")));
	EndIf;
	Form.ChangeAttributes(AttributesToBeAdded);
	
	// Let's save the type and identifier of the base object.
	If Form.Parameters.Property("IntegrationWith1CDocumentManagement_ObjectTypeDM")
			And Form.Parameters.Property("IntegrationWith1CDocumentManagement_ObjectIdentifierDM") Then
		Form["IntegrationWith1CDocumentManagement_ObjectTypeDM"] =
			Form.Parameters.IntegrationWith1CDocumentManagement_ObjectTypeDM;
		Form["IntegrationWith1CDocumentManagement_ObjectIdentifierDM"] =
			Form.Parameters.IntegrationWith1CDocumentManagement_ObjectIdentifierDM;
	EndIf;
	
	// Save the ID of the linked object TO.
	If Form.Parameters.Property("Basis")
			And TypeOf(Form.Parameters.Basis) = Type("Structure")
			And Form.Parameters.Basis.Property("Object1CDocumentManagement") Then
		FormCommand = Form.Commands.Add("ObjectIDDM");
		FormCommand.Action = Form.Parameters.Basis.Object1CDocumentManagement.ID;
	EndIf;
	
	If CommandLocation = Undefined And Form.Items.Find("List") <> Undefined
			And (StrFind(Form.FormName, "ListForm") <> 0 Or StrFind(Form.FormName, "ChoiceForm") <> 0) Then
		For Each FormItem In Form.Items.List.CommandBar.ChildItems Do
			If TypeOf(FormItem) = Type("FormGroup") Then
				For Each GroupItem In FormItem.ChildItems Do
					If TypeOf(GroupItem) = Type("FormGroup")
							And (GroupItem.Title = NStr("vi = 'Tạo trên cơ sở';
														|ru = 'Создать на основании';
														|en = 'Create'; fa = 'ایجاد';
														|it = 'Создать на основании';
														|pl = 'Utwórz na podstawie';
														|tr = 'Yeni belgeye aktar'")
								Or GroupItem.Title = NStr("vi = 'Sổ tay';
															|ru = 'Органайзер';
															|en = 'Organizer'; fa = 'سازمان‌دهنده';
															|it = 'Органайзер';
															|pl = 'Organizer';
															|tr = 'Düzenleyici'")
								Or GroupItem.Title = NStr("vi = 'In';
															|ru = 'Печать';
															|en = 'Print'; fa = 'چاپ';
															|it = 'Печать';
															|pl = 'Print';
															|tr = 'Yazdır'")) Then
						CommandLocation = FormItem;
						Break;
					EndIf;
				EndDo;
			EndIf;
			If CommandLocation <> Undefined Then
				Break;
			EndIf;
		EndDo;
		If CommandLocation = Undefined
				And Form.Items.List.CommandBarLocation <> FormItemCommandBarLabelLocation.None
				And Form.Items.List.CommandBar.ChildItems.Count() > 0 Then
			CommandLocation = Form.Items.List.CommandBar;
		EndIf;
	EndIf;
	If CommandLocation = Undefined And Form.CommandBarLocation = FormCommandBarLabelLocation.None Then
		For Each FormItem In Form.Items Do
			If TypeOf(FormItem) = Type("FormGroup")
					And FormItem.Type = FormGroupType.CommandBar
					And FormItem.Visible
					And FormItem.Enabled
					And Not FormItem.ReadOnly Then
				CommandLocation = FormItem;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	TypeOfIntegratedObject = Undefined;
	If Form.Parameters.Property("Basis")
			And TypeOf(Form.Parameters.Basis) = Type("Structure")
			And Form.Parameters.Basis.Property("TypeOfObjectToCreate") Then
		NameOfTypeOfObjectBeingCreated = IntegrationWith1CDocumentManagementCoreClientServer.TypeNameFromFullName(
			Form.Parameters.Basis.TypeOfObjectToCreate);
		TypeOfIntegratedObject = Type(NameOfTypeOfObjectBeingCreated);
	EndIf;
	
	Form.NameOfAttributeOfObjectIntegratedWith1CDocumentManagement =
		IntegrationWith1CDocumentManagementCoreServerCall.NameOfAttributeOfObjectIntegratedWith1CDocumentManagement(
			Form,
			FormAttributes,
			TypeOfIntegratedObject);
	
	If Ref = Undefined Then
		Ref = ReferenceToIntegratedObjectFromForm(Form, FormAttributes, TypeOfIntegratedObject);
	EndIf;
	
	Settings = IntegrationWith1CDocumentManagementCoreServerCall.UseIntegration();
	If Settings.UseIntegrationBefore2 Then
		Form.UseIntegrationBefore2 = True;
		ModuleIntegrationWith1CDocumentManagement = Common.CommonModule("IntegrationWith1CDocumentManagement");
		ModuleIntegrationWith1CDocumentManagement.OnCreateAtServer(
			Form,
			CommandLocation,
			NotificationParameters,
			Ref);
	ElsIf Settings.UseIntegrationBefore3 Then
		Form.UseIntegrationBefore3 = True;
		ModuleIntegrationWith1CDocumentManagement3 = Common.CommonModule("IntegrationWith1CDocumentManagement3");
		ModuleIntegrationWith1CDocumentManagement3.OnCreateAtServer(
			Form,
			CommandLocation,
			NotificationParameters);
	Else
		Return;
	EndIf;
	
	Form.UseAttachedFiles1CDocumentManagement = UseAttachedFiles1CDocumentManagement();
	
	Try
		If UseAttachedFiles1CDocumentManagement()
				And NeedToOutputTheAttachedFilesCommandDM(Form) Then
			AddCommandFiles(Form, CommandLocation);
		EndIf;
	Except
		ErrorMessageText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteLogEvent(
			EventLogEventName(),
			EventLogLevel.Error,,,
			ErrorMessageText);
		Common.MessageToUser(ErrorMessageText);
	EndTry;
	
EndProcedure

// Called when creating integration forms that are placed on the desktop.
// Allows you to refuse to create them when working in an undivided session or when performing an information security update.
//
// Parameters:
//   Cancel - Boolean - refusal to create.
//
Procedure WhenCreatingFormsHostedOnDesktopOnServer(Cancel) Export
	
	// Let's check the need to display the form on the desktop.
	If Common.DataSeparationEnabled() And Not Common.SeparatedDataUsageAvailable() Then
		Cancel = True;
		Return;
	EndIf;
	
	ClientParameters = StandardSubsystemsServer.ClientParametersAtServer();
	If ClientParameters.Get("HideDesktopOnStart") <> Undefined Then
		Cancel = True;
		Return;
	EndIf;
	
EndProcedure

// Returns True if the client application is a web client, otherwise False.
//
// Returns:
//   Boolean
//
Function ApplicationIsWebClient() Export
	
	SystemInfo = New SystemInfo;
	
	Return ValueIsFilled(SystemInfo.UserAgentInformation);
	
EndFunction

// Checks an arbitrary algorithm in the built-in 1C language:Enterprise, which is set by the user in
// the enterprise mode, for the presence of dangerous structures in it that allow unlimited access to the database.
//
// Parameters:
//   AlgorithmForVerification - String - algorithm in the built-in language "1C:Enterprises", which is required to be checked.
//
Procedure CheckAlgorithmForForbiddenExpressions(Val AlgorithmForVerification) Export
	
	AlgorithmForVerification = ExpressionWithoutExtraCharacters(AlgorithmForVerification);
	
	ForbiddenLines = New Array;
	Exceptions = New Array;
	ErrorList = New Array;
	SuitableExceptions = New Array;
	
	ForbiddenLines.Add("Выполнить"); //@NON-NLS-1
	ForbiddenLines.Add("Execute"); //@NON-NLS-1
	
	// The exception is the Execute() method of the Request object.
	Exceptions.Add(".Execute()");
	Exceptions.Add(".ExecuteBatch()");
	
	CheckAlgorithm(AlgorithmForVerification, ForbiddenLines, Exceptions, ErrorList, SuitableExceptions);
	
	ForbiddenLines.Clear();
	Exceptions.Clear();
	
	ForbiddenLines.Add("Записать"); //@NON-NLS-1
	ForbiddenLines.Add("Write"); //@NON-NLS-1
	
	ForbiddenLines.Add("Base64Значение"); //@NON-NLS-1
	ForbiddenLines.Add("Base64Value"); //@NON-NLS-1
	
	ForbiddenLines.Add("ХранилищеЗначения"); //@NON-NLS-1
	ForbiddenLines.Add("ValueStorage"); //@NON-NLS-1
	
	ForbiddenLines.Add("ДвоичныеДанные"); //@NON-NLS-1
	ForbiddenLines.Add("BinaryData"); //@NON-NLS-1
	
	ForbiddenLines.Add("БезопасныйРежим"); //@NON-NLS-1
	ForbiddenLines.Add("SafeMode"); //@NON-NLS-1
	
	ForbiddenLines.Add("Транзакция"); //@NON-NLS-1
	ForbiddenLines.Add("Транзакцию"); //@NON-NLS-1
	ForbiddenLines.Add("Transaction"); //@NON-NLS-1
	
	CheckAlgorithm(AlgorithmForVerification, ForbiddenLines, Exceptions, ErrorList, SuitableExceptions);
	
	If ErrorList.Count() > 0 Then
		If SuitableExceptions.Count() = 0 Then
			ErrorText = StrTemplate(
				NStr("vi = 'Trong biểu thức đã cấm sử dụng cấu trúc:
					|%1';
					|ru = 'В выражении запрещено использовать конструкции:
					|%1';
					|en = 'Cannot use the following constructions in the expression:
					|%1'; fa = 'Cannot use the following constructions in the expression:
					|%1';
					|it = 'В выражении запрещено использовать конструкции:
					|%1';
					|pl = 'Cannot use the following constructions in the expression:
					|%1';
					|tr = 'Buradaki ifade, şu yapıların kullanımını yasaklar: 
					|%1'"),
				StrConcat(ErrorList, Chars.LF));
		Else
			ErrorText = StrTemplate(
				NStr("vi = 'Trong biểu thức đã cấm sử dụng cấu trúc:
					|%1
					|
					|Danh sách loại trừ:
					|%2';
					|ru = 'В выражении запрещено использовать конструкции:
					|%1
					|
					|Список исключений:
					|%2';
					|en = 'Cannot use the following constructions in the expression:
					|%1
					|
					|List of exceptions:
					|%2'; fa = 'Cannot use the following constructions in the expression:
					|%1
					|
					|List of exceptions:
					|%2';
					|it = 'В выражении запрещено использовать конструкции:
					|%1
					|
					|Список исключений:
					|%2';
					|pl = 'Cannot use the following constructions in the expression:
					|%1
					|
					|List of exceptions:
					|%2';
					|tr = 'Bu ifadede şu yapılara izin verilmemektedir: 
					|%1
					|
					| İstisnalar listesi: 
					|%2'"),
				StrConcat(ErrorList, Chars.LF),
				StrConcat(SuitableExceptions, Chars.LF));
		EndIf;
		Raise ErrorText;
	EndIf;
	
EndProcedure

// Checks the return of the WEB service. If an object of type DMError returns, it throws an exception.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   Response - XDTODataObject - the verified result of the service call.
//
Procedure CheckWebServiceRefund(Proxy, Response) Export
	
	If ValidateType(Proxy, Response, "DMError") Then
		// Let's write the full text of the error in the LR.
		RecordXDTOError(Response);
		Raise StrTemplate(
				"%1:
				|%2",
			Response.subject,
			TrimAll(Response.description));
	EndIf;
	
EndProcedure

// Checks the type of the XDTO object.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   XDTODataObject - XDTODataObject - the object being checked.
//   Type - String - name of the type to check.
//
// Returns:
//   Boolean - True if the object is an object of the specified type and False otherwise.
//
Function ValidateType(Proxy, XDTODataObject, Type) Export
	
	If TypeOf(XDTODataObject) = Type("XDTODataObject") Then
		XDTOObjectType = XDTODataObject.Type();
	Else
		Return False;
	EndIf;
	
	DMFactory = DMFactory(Proxy, False);
	If DMFactory = Undefined Then
		// Connecting to 1C:The workflow has not been established.
		Return (Lower(TrimAll(XDTOObjectType.Name)) = Lower(TrimAll(Type)));
		
	Else
		Return XDTOTypesAreSame(XDTOObjectType, DMFactory.Type(URIOfNamespaceOfWorkflowWebService(), Type));
		
	EndIf;
	
EndFunction

// Searches for and returns the Attributes of the form by name.
//
// Parameters:
//   FormAttributes - Array of FormAttribute - list of all Attributes of the form.
//   AttributeName - String - the name of the Attribute you are looking for.
//
// Returns:
//   FormAttribute - in case the Attribute was found.
//   Undefined - if there is no Attribute on the form.
//
Function FormAttributeByName(FormAttributes, AttributeName) Export
	
	For Each Attribute In FormAttributes Do
		If Attribute.Name = AttributeName Then
			Return Attribute;
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

// Returns the details of the consumer object of the specified type.
//
// Parameters:
//   ObjectTypeIS - String - the full name of the object's metadata.
//   ForExpression - Boolean - returns a list of Attributes for composing an expression in the embedded language.
//
// Returns:
//   ValueTable:
//     * Name - String
//     * Presentation - String
//     * Type - TypeDescription
//     * ThisIsTable - Boolean
//     * Table - String
//     * TableForSorting - String
//     * IsAdditionalAttributeIS - Boolean
//     * AdditionalAttributeIS - ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo
//     * ChoiceParameterLinks - Array of Structure:
//         ** Name - String
//         ** DataPath - String
//     * Order - Number
//
Function ObjectAttributesIS(ObjectTypeIS, ForExpression = False) Export
	
	Attributes = New ValueTable;
	Attributes.Columns.Add("Name", New TypeDescription("String"));
	Attributes.Columns.Add("Presentation", New TypeDescription("String"));
	Attributes.Columns.Add("ToolTip", New TypeDescription("String"));
	Attributes.Columns.Add("Type", New TypeDescription("TypeDescription"));
	Attributes.Columns.Add("ThisIsTable", New TypeDescription("Boolean"));
	Attributes.Columns.Add("Table", New TypeDescription("String"));
	Attributes.Columns.Add("TableForSorting", New TypeDescription("String"));
	Attributes.Columns.Add("IsAdditionalAttributeIS", New TypeDescription("Boolean"));
	Attributes.Columns.Add("AdditionalAttributeIS",
		New TypeDescription("ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo"));
	Attributes.Columns.Add("ChoiceParameterLinks", New TypeDescription("Array"));
	Attributes.Columns.Add("Order", New TypeDescription("Number"));
	
	Attributes.Indexes.Add("Name");
	Attributes.Indexes.Add("Table, Name");
	
	ObjectMetadata = Metadata.FindByFullName(ObjectTypeIS); // MetadataObjectDocument
	If ObjectMetadata = Undefined Then
		Return Attributes;
	EndIf;
	
	For Each AttributeMetadata In ObjectMetadata.StandardAttributes Do
		
		If AttributeMetadata.Name = "Code"
				Or AttributeMetadata.Name = "Description"
				Or AttributeMetadata.Name = "Owner"
				Or AttributeMetadata.Name = "Number"
				Or AttributeMetadata.Name = "Date"
				Or AttributeMetadata.Name = "DeletionMark" Then
			
			Attribute = Attributes.Add();
			Attribute.Name = AttributeMetadata.Name;
			Attribute.Type = AttributeMetadata.Type;
			Attribute.ToolTip = TrimAll(AttributeMetadata.ToolTip);
			
			If AttributeMetadata.Name = "DeletionMark" Then
				Attribute.Presentation = NStr("vi = 'Đánh dấu xóa';
												|ru = 'Пометка удаления';
												|en = 'Deletion mark'; fa = 'علامت حذف';
												|it = 'Пометка удаления';
												|pl = 'Zaznaczenie usunięcia';
												|tr = 'Silme işareti'");
			Else
				Attribute.Presentation = ?(ValueIsFilled(AttributeMetadata.Synonym),
					AttributeMetadata.Synonym,
					AttributeMetadata.Name);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	For Each AttributeMetadata In ObjectMetadata.Attributes Do
		
		If StrStartsWith(AttributeMetadata.Name, "Delete")
				Or StrFind(AttributeMetadata.Synonym, NStr("vi = '(Xóa bỏ)';
															|ru = '(Удалить)';
															|en = '(Delete)'; fa = '(Delete)';
															|it = '(Удалить)';
															|pl = '(Delete)';
															|tr = '(Sil)'")) > 0 Then
			Continue;
		EndIf;
		
		Attribute = Attributes.Add();
		Attribute.Name = AttributeMetadata.Name;
		Attribute.Type = AttributeMetadata.Type;
		Attribute.Presentation = ?(ValueIsFilled(AttributeMetadata.Synonym),
			AttributeMetadata.Synonym,
			AttributeMetadata.Name);
		Attribute.ToolTip = TrimAll(AttributeMetadata.Tooltip);
		For Each RelationshipOfSelectionParameters In AttributeMetadata.ChoiceParameterLinks Do
			CommunicationStructure = New Structure("Name, DataPath",
				RelationshipOfSelectionParameters.Name,
				RelationshipOfSelectionParameters.DataPath);
			Attribute.ChoiceParameterLinks.Add(CommunicationStructure);
		EndDo;
		
	EndDo;
	
	UsingAttributeToUse = Metadata.ObjectProperties.CommonAttributeUse.Use;
	UsingAutoAttributes = Metadata.ObjectProperties.CommonAttributeUse.Auto;
	AutoUseOfAttributeToUse = Metadata.ObjectProperties.CommonAttributeAutoUse.Use;
	DoNotUseDataSeparationAttributes = Metadata.ObjectProperties.CommonAttributeDataSeparation.DontUse;
	
	AllGeneralDetails = New Array; // Array of MetadataObjectCommonAttribute
	For Each CommonAttribute In Metadata.CommonAttributes Do
		If CommonAttribute.DataSeparation = DoNotUseDataSeparationAttributes Then
			AllGeneralDetails.Add(CommonAttribute);
		EndIf;
	EndDo;
	
	For Each AttributeMetadata In AllGeneralDetails Do
		
		CompositionItem = AttributeMetadata.Content.Find(ObjectMetadata);
		If CompositionItem = Undefined Then
			// There is no common Attribute in the document.
			Continue;
		EndIf;
		
		If CompositionItem.Use = UsingAttributeToUse
				Or (CompositionItem.Use = UsingAutoAttributes
					And AttributeMetadata.AutoUse = AutoUseOfAttributeToUse) Then
			
			Attribute = Attributes.Add();
			Attribute.Name = AttributeMetadata.Name;
			Attribute.Type = AttributeMetadata.Type;
			Attribute.Presentation = ?(ValueIsFilled(AttributeMetadata.Synonym),
				AttributeMetadata.Synonym,
				AttributeMetadata.Name);
			Attribute.ToolTip = TrimAll(AttributeMetadata.Tooltip);
			For Each RelationshipOfSelectionParameters In AttributeMetadata.ChoiceParameterLinks Do
				CommunicationStructure = New Structure("Name, DataPath",
					RelationshipOfSelectionParameters.Name,
					RelationshipOfSelectionParameters.DataPath);
				Attribute.ChoiceParameterLinks.Add(CommunicationStructure);
			EndDo;
			
		EndIf;
		
	EndDo;
	
	For Each MetadataTables In ObjectMetadata.TabularSections Do
		
		If Not ForExpression
				And (MetadataTables.Name = "AdditionalAttributes"
					Or MetadataTables.Name = "ContactInformation") Then
			Continue;
		EndIf;
		
		If StrStartsWith(MetadataTables.Name, "Delete")
				Or StrFind(MetadataTables.Synonym, NStr("vi = '(Xóa bỏ)';
														|ru = '(Удалить)';
														|en = '(Delete)'; fa = '(Delete)';
														|it = '(Удалить)';
														|pl = '(Delete)';
														|tr = '(Sil)'")) > 0 Then
			Continue;
		EndIf;
		
		Table = Attributes.Add();
		Table.Name = MetadataTables.Name;
		Table.TableForSorting = MetadataTables.Name;
		Table.ThisIsTable = True;
		Table.Presentation = ?(ValueIsFilled(MetadataTables.Synonym),
			MetadataTables.Synonym,
			MetadataTables.Name);
		Table.ToolTip = TrimAll(MetadataTables.Tooltip);
		
		For Each AttributeMetadata In MetadataTables.Attributes Do
			
			If StrStartsWith(AttributeMetadata.Name, "Delete")
					Or StrFind(AttributeMetadata.Synonym, NStr("vi = '(Xóa bỏ)';
																|ru = '(Удалить)';
																|en = '(Delete)'; fa = '(Delete)';
																|it = '(Удалить)';
																|pl = '(Delete)';
																|tr = '(Sil)'")) > 0 Then
				Continue;
			EndIf;
			
			Attribute = Attributes.Add();
			Attribute.Name = AttributeMetadata.Name;
			Attribute.Type = AttributeMetadata.Type;
			Attribute.Presentation = ?(ValueIsFilled(AttributeMetadata.Synonym),
				AttributeMetadata.Synonym,
				AttributeMetadata.Name);
			Attribute.ToolTip = TrimAll(AttributeMetadata.Tooltip);
			For Each RelationshipOfSelectionParameters In AttributeMetadata.ChoiceParameterLinks Do
				CommunicationStructure = New Structure("Name, DataPath",
					RelationshipOfSelectionParameters.Name,
					RelationshipOfSelectionParameters.DataPath);
				Attribute.ChoiceParameterLinks.Add(CommunicationStructure);
			EndDo;
			
			Attribute.Table = Table.Name;
			Attribute.TableForSorting = Table.Name;
			
		EndDo;
		
	EndDo;
	
	If Metadata.FunctionalOptions.Find("UseAdditionalAttributesAndInfo") <> Undefined
			And GetFunctionalOption("UseAdditionalAttributesAndInfo") Then
		
		TypeName = IntegrationWith1CDocumentManagementCoreClientServer.TypeNameFromFullName(ObjectTypeIS);
		PropertiesOwner = New(Type(TypeName));
		
		If PropertyManager.UseAddlAttributes(PropertiesOwner) Then
			
			SetOfAdditionalBankingDetails = PropertyManager.ObjectProperties(PropertiesOwner, True, False);
			PropertiesOfAdditionalBankingDetails = Common.ObjectsAttributesValues(
				SetOfAdditionalBankingDetails,
				"Description, ValueType, ToolTip");
			
			For Each AdditionalAttribute5 In SetOfAdditionalBankingDetails Do
				PropertiesOfAdditionalProps = PropertiesOfAdditionalBankingDetails[AdditionalAttribute5];
				If Not ValueIsFilled(AdditionalAttribute5) Or Not ValueIsFilled(PropertiesOfAdditionalProps) Then
					Continue;
				EndIf;
				
				Attribute = Attributes.Add();
				Attribute.Name = NameOfAdditionalProps(AdditionalAttribute5);
				Attribute.Presentation = StrTemplate(NStr("vi = 'Mục tin bổ sung: %1';
															|ru = 'Доп. реквизит: %1';
															|en = 'Additional attribute: %1'; fa = 'Additional attribute: %1';
															|it = 'Additional attribute: %1';
															|pl = 'Additional attribute: %1';
															|tr = 'Ek öznitelik: %1'"),
					PropertiesOfAdditionalProps.Description);
				Attribute.ToolTip = TrimAll(PropertiesOfAdditionalProps.ToolTip);
				Attribute.Type = PropertiesOfAdditionalProps.ValueType;
				Attribute.IsAdditionalAttributeIS = True;
				Attribute.AdditionalAttributeIS = AdditionalAttribute5;
			EndDo;
			
		EndIf;
		
	EndIf;
	
	Attributes.Sort("TableForSorting, ThisIsTable DESC, Presentation");
	
	If Not ForExpression Then
		// Let's define the order taking into account the dependencies on the selection parameters.
		For RowIndex = 0 To Attributes.Count() - 1 Do
			Attributes[RowIndex].Order = RowIndex;
		EndDo;
		Repeat_ = True;
		While Repeat_ Do
			Repeat_ = False;
			For Each Attribute In Attributes Do
				DataPath = PathToPropsData(Attribute);
				MaximumOrder = 0;
				For Each RelationshipOfSelectionParameters In Attribute.ChoiceParameterLinks Do
					Dependencies = Attributes.FindRows(PropsSearchStructure(RelationshipOfSelectionParameters.DataPath));
					For Each Dependence In Dependencies Do
						HasLoop = False;
						For Each DependenceRelationOfSelectionParameters In Dependence.ChoiceParameterLinks Do
							If DependenceRelationOfSelectionParameters.DataPath = DataPath Then
								HasLoop = True;
								Break;
							EndIf;
						EndDo;
						If Not HasLoop Then
							MaximumOrder = Max(MaximumOrder, Dependence.Order);
						EndIf;
					EndDo;
				EndDo;
				If MaximumOrder >= Attribute.Order Then
					Attribute.Order = MaximumOrder + 1;
					Repeat_ = True;
				EndIf;
			EndDo;
		EndDo;
		Attributes.Sort("TableForSorting, Order");
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreOverridable.WhenReceivingAttributesOfIPObject(
		ObjectTypeIS,
		Attributes);
	
	Return Attributes;
	
EndFunction

// Determines whether the property exists in the XDTO object.
//
// Parameters:
//   XDTODataObject - XDTODataObject - the source object whose property needs to be checked.
//   PropertyName - String - property name.
//   RaiseException1 - Boolean - raise an exception if there is no property with the specified name.
//
// Returns:
//   Boolean - the property exists.
//
Function PropertyExists(XDTODataObject, PropertyName, RaiseException1 = False) Export
	
	If TypeOf(XDTODataObject) <> Type("XDTODataObject") Then
		Return False;
	EndIf;
	
	PropertyExists = (XDTODataObject.Type().Properties.Get(PropertyName) <> Undefined);
	
	If RaiseException1 And Not PropertyExists Then
		ExceptionText = StrTemplate(NStr("vi = 'Trong đối tượng XDTO kiểu ""%1"" không có thuộc tính với tên gọi ""%2"".';
										|ru = 'В объекте XDTO типа ""%1"" не существует свойства с именем ""%2"".';
										|en = 'In the XDTO object of the %1 type, a property with the %2 name does not exist.'; fa = 'In the XDTO object of the %1 type, a property with the %2 name does not exist.';
										|it = 'В объекте XDTO типа ""%1"" не существует свойства с именем ""%2"".';
										|pl = 'In the XDTO object of the %1 type, a property with the %2 name does not exist.';
										|tr = '""%1"" tipindeki XDTO nesnesinde ""%2"" isimli bir özellik bulunmamaktadır.'"),
			XDTODataObject.Type().Name,
			PropertyName);
		Raise ExceptionText;
	EndIf;
	
	Return PropertyExists;
	
EndFunction

// Determines whether the property has been set in the XDTO object.
//
// Parameters:
//   XDTODataObject - XDTODataObject - the source object whose property needs to be checked.
//   PropertyName - String - property name.
//
// Returns:
//   Boolean - the property is set.
//
Function PropertySet(XDTODataObject, PropertyName) Export
	
	Return (PropertyExists(XDTODataObject, PropertyName) And XDTODataObject.IsSet(PropertyName));
	
EndFunction

// Returns True if the server is running under Windows, and False otherwise.
//
// Returns:
//   Boolean
//
Function ServerRunsUnderWindows() Export
	
	SysInfo = New SystemInfo;
	
	Return (SysInfo.PlatformType = PlatformType.Windows_x86)
		Or (SysInfo.PlatformType = PlatformType.Windows_x86_64);
	
EndFunction

// Returns an indication of the status "Agreed" according to the workflow data.
//
// Parameters:
//   ObjectReference - AnyRef - reference to the IP object.
//
// Returns:
//   Boolean - the status of the agreement in UP to.
//
Function ApprovedIn1CDocumentManagement(ObjectReference) Export
	
	StateHasBeenReceived = False;
	Approved = False;
	
	Try
		
		If SessionParameters.IntegrationWith1CDocumentManagementPasswordIsKnown Then
			
			Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
			
			If Proxy <> Undefined Then
				
				Query = CreateObject(Proxy, "DMGetDocumentListRequest");
				FieldsReceived = Query.columnSet; // XDTOList
				FieldsReceived.Add("statusApproval");
				
				Owners = Query.externalObjects; // XDTOList
				Owners.Add(CreateExternalObject(Proxy, ObjectReference));
				
				Result = ExecuteQuery(Proxy, Query);
				
				If ValidateType(Proxy, Result, "DMError") = False And Result.documents.Count() > 0 Then
					
					StateHasBeenReceived = True;
					
					ObjectBefore = Result.documents[0];
					If PropertySet(ObjectBefore, "statusApproval") Then
						If TypeOf(ObjectBefore.statusApproval) = Type("String")
								And ObjectBefore.statusApproval = "Approved" Then
							Approved = True;
							
						ElsIf TypeOf(ObjectBefore.statusApproval) = Type("XDTODataObject")
								And PropertySet(ObjectBefore.statusApproval, "name")
								And ObjectBefore.statusApproval.name = "Согласован" Then //@NON-NLS-3
							Approved = True;
							
						EndIf;
					EndIf;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	Except
		// if there is no connection, we will return the false Status.
		Approved = False;
	EndTry;
	
	If Not StateHasBeenReceived Then
		// perhaps the State of the agreement is saved in the register.
		Query = New Query(
			"SELECT
			|	ApprovalStatesIn1CDocumentManagement.State AS State
			|FROM
			|	InformationRegister.ObjectsIntegratedWith1CDocumentManagement AS ObjectsIntegratedWith1CDocumentManagement
			|		INNER JOIN InformationRegister.ApprovalStatesIn1CDocumentManagement AS ApprovalStatesIn1CDocumentManagement
			|		ON ObjectsIntegratedWith1CDocumentManagement.ObjectIDDM = ApprovalStatesIn1CDocumentManagement.ObjectIDDM
			|WHERE
			|	ObjectsIntegratedWith1CDocumentManagement.Object = &ObjectReference");
		Query.SetParameter("ObjectReference", ObjectReference);
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			Approved = (Selection.State = Enums.ApprovalStatesIn1CDocumentManagement.Approved);
		EndIf;
	EndIf;
	
	Return Approved;
	
EndFunction

// Creates a DMLink object.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   ObjectIDDM - String - the ID of the object BEFORE.
//   ObjectTypeDM - String - type of the XDTO object.
//   ObjectIS - AnyRef - reference to the IP object.
//
// Returns:
//   XDTODataObject - An XDTO object of the DMLink type.
//
Function CreateDMLink(Proxy, ObjectIDDM, ObjectTypeDM, ObjectIS) Export
	
	AbbreviatedNameOfConfiguration = AbbreviatedNameOfConfiguration();
	
	XDTOConnection = CreateObject(Proxy, "DMLink");
	
	If Not ValueIsFilled(ObjectIDDM) Then
		Raise StrTemplate(
			NStr("vi = 'Đã phát hiện một liên kết sai giữa các đối tượng của 1C:Document management và %1.
				|Chưa chỉ ra tên định danh duy nhất của đối tượng 1C:Document management mà được liên kết với đối tượng ""%2"".
				|Hãy thực hiện lệnh ""Đồng bộ hóa liên kết"" trong các tùy chỉnh tích hợp với 1C:Document management.';
				|ru = 'Обнаружена некорректная связь между объектами 1С:Документооборота и %1.
				|Не указан уникальный идентификатор объекта 1С:Документооборота, связанного с объектом ""%2"".
				|Выполните команду ""Синхронизировать связи"" в настройках интеграции с 1С: Документооборотом.';
				|en = 'An incorrect link between the objects of 1C:Document Management and %1 is found.
				|The ID of the 1C:Document Management object mapped to the ""%2"" object is not specified.
				|Click ""Synchronize links"" in the 1C:Document Management integration settings.'; fa = 'An incorrect link between the objects of 1C:Document Management and %1 is found.
				|The ID of the 1C:Document Management object mapped to the ""%2"" object is not specified.
				|Click ""Synchronize links"" in the 1C:Document Management integration settings.';
				|it = 'Обнаружена некорректная связь между объектами 1С:Документооборота и %1.
				|Не указан уникальный идентификатор объекта 1С:Документооборота, связанного с объектом ""%2"".
				|Выполните команду ""Синхронизировать связи"" в настройках интеграции с 1С: Документооборотом.';
				|pl = 'An incorrect link between the objects of 1C:Document Management and %1 is found.
				|The ID of the 1C:Document Management object mapped to the ""%2"" object is not specified.
				|Click ""Synchronize links"" in the 1C:Document Management integration settings.';
				|tr = '1C:Document Management nesneleri ile %1 arasında hatalı bir bağlantı tespit edildi.
				|""%2"" nesnesiyle bağlantılı 1C:Document Management nesnesinin benzersiz kimliği belirtilmedi.
				|1C: Document Management ile entegrasyon ayarlarında ""Bağlantıları senkronize et"" komutunu çalıştırın.'"),
			AbbreviatedNameOfConfiguration,
			String(ObjectIS));
	ElsIf Not ValueIsFilled(ObjectTypeDM) Then
		Raise StrTemplate(
			NStr("vi = 'Đã phát hiện một liên kết sai giữa các đối tượng của 1C:Document management và %1.
				|Chưa chỉ ra tên định danh duy nhất của đối tượng 1C:Document management mà được liên kết với đối tượng ""%2"".
				|Hãy thực hiện lệnh ""Đồng bộ hóa liên kết"" trong các tùy chỉnh tích hợp với 1C:Document management.';
				|ru = 'Обнаружена некорректная связь между объектами 1С:Документооборота и %1.
				|Не указан тип объекта 1С:Документооборота, связанного с объектом ""%2"".
				|Выполните команду ""Синхронизировать связи"" в настройках интеграции с 1С: Документооборотом.';
				|en = 'An incorrect link between the objects of 1C:Document Management and %1 is found.
				|The type of the 1C:Document Management object mapped to the ""%2"" object is not specified.
				|Click ""Synchronize links"" in the 1C:Document Management integration settings.'; fa = 'An incorrect link between the objects of 1C:Document Management and %1 is found.
				|The type of the 1C:Document Management object mapped to the ""%2"" object is not specified.
				|Click ""Synchronize links"" in the 1C:Document Management integration settings.';
				|it = 'Обнаружена некорректная связь между объектами 1С:Документооборота и %1.
				|Не указан тип объекта 1С:Документооборота, связанного с объектом ""%2"".
				|Выполните команду ""Синхронизировать связи"" в настройках интеграции с 1С: Документооборотом.';
				|pl = 'An incorrect link between the objects of 1C:Document Management and %1 is found.
				|The type of the 1C:Document Management object mapped to the ""%2"" object is not specified.
				|Click ""Synchronize links"" in the 1C:Document Management integration settings.';
				|tr = '1C:Document Management nesneleri ile %1 arasında hatalı bir bağlantı tespit edildi.
				|""%2"" nesnesiyle bağlantılı 1C:Document Management nesnesinin türü belirtilmedi.
				|1C: Document Management ile entegrasyon ayarlarında ""Bağlantıları senkronize et"" komutunu çalıştırın.'"),
			AbbreviatedNameOfConfiguration,
			String(ObjectIS));
	Else
		XDTOConnection.linkedObject = CreateObjectID(Proxy, ObjectIDDM, ObjectTypeDM);
	EndIf;
	
	If ValueIsFilled(ObjectIS) Then
		XDTOConnection.ownerObject = CreateExternalObjectID(Proxy, ObjectIS);
	Else
		Raise StrTemplate(
			NStr("vi = 'Đã phát hiện một liên kết sai giữa các đối tượng của 1C:Document management và %1.
				|Đối tượng 1C:Document management %2 (%3) được tham chiếu đến đối tượng không tồn tại %1.
				|Hãy thực hiện lệnh ""Đồng bộ hóa liên kết"" trong các tùy chỉnh tích hợp với 1C:Document management.';
				|ru = 'Обнаружена некорректная связь между объектами 1С:Документооборота и %1.
				|Объект 1С:Документооборота %2 (%3) ссылается на не существующий объект %1.
				|Выполните команду ""Синхронизировать связи"" в настройках интеграции с 1С: Документооборотом.';
				|en = 'An incorrect link between the objects of 1C:Document Management and %1 is found.
				|The %2 (%3) 1C:Document Management object refers to the non-existent %1 object.
				|Click ""Synchronize links"" in the 1C:Document Management integration settings.'; fa = 'An incorrect link between the objects of 1C:Document Management and %1 is found.
				|The %2 (%3) 1C:Document Management object refers to the non-existent %1 object.
				|Click ""Synchronize links"" in the 1C:Document Management integration settings.';
				|it = 'Обнаружена некорректная связь между объектами 1С:Документооборота и %1.
				|Объект 1С:Документооборота %2 (%3) ссылается на не существующий объект %1.
				|Выполните команду ""Синхронизировать связи"" в настройках интеграции с 1С: Документооборотом.';
				|pl = 'An incorrect link between the objects of 1C:Document Management and %1 is found.
				|The %2 (%3) 1C:Document Management object refers to the non-existent %1 object.
				|Click ""Synchronize links"" in the 1C:Document Management integration settings.';
				|tr = '1C:Document Management ve %1 nesneleri arasında hatalı bir bağlantı tespit edildi.
				|%2 (%3) 1C:Document Management nesnesi mevcut olmayan %1 nesnesine bağlantı içermektedir.
				|1C: Document Management ile entegrasyon ayarlarında ""Bağlantıları senkronize et"" komutunu çalıştırın.'"),
			AbbreviatedNameOfConfiguration,
			ObjectIDDM,
			ObjectTypeDM);
	EndIf;
	
	Return XDTOConnection;
	
EndFunction

// Creates an ExternalObject.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   ExternalIPObject - AnyRef - reference to an external IP object.
//   ID - String - ID of the external IP object.
//   Type - String - the type of external IP object.
//   Description - String - name of the external IP object.
//
// Returns:
//   XDTODataObject - an XDTO object of the ExternalObject type.
//
Function CreateExternalObject(Proxy, ExternalIPObject = Undefined, ID = "", Type = "", Description = "") Export
	
	ExternalObject = CreateObject(Proxy, "ExternalObject");
	ExternalObject.ID = ID;
	ExternalObject.type = Type;
	ExternalObject.name = Description;
	
	If Common.IsReference(TypeOf(ExternalIPObject)) Then
		ExternalIPObjectMetadata = ExternalIPObject.Metadata();
		URL = "";
		Presentation = String(ExternalIPObject);
		// Default values.
		ExternalObject.name = String(ExternalIPObject);
		ExternalObject.type = GetLinkTypeName(ExternalIPObject);
		If Common.IsReference(TypeOf(ExternalIPObject)) Then
			If Not Enums.AllRefsType().ContainsType(TypeOf(ExternalIPObject)) Then
				URL = GetURL(ExternalIPObject);
			EndIf;
			If Not ExternalIPObject.IsEmpty() Then
				// Specify the name of the external object.
				If HasDescription(ExternalIPObject) Then
					ExternalObject.name = Common.ObjectAttributeValue(ExternalIPObject, "Description");
				EndIf;
				// Specifying the ID of the external object.
				ExternalObject.ID = GetIDFromLink(ExternalIPObject);
			Else
				Presentation = ExternalIPObjectMetadata.Synonym;
			EndIf;
		EndIf;
		If PropertyExists(ExternalObject, "navigationRef") Then
			ExternalObject.navigationRef = URL;
		EndIf;
		If PropertyExists(ExternalObject, "presentation") Then
			ExternalObject.presentation = Presentation;
		EndIf;
		If PropertyExists(ExternalObject, "barcodeData")
				And (Common.IsDocument(ExternalIPObjectMetadata)
					Or Common.IsCatalog(ExternalIPObjectMetadata)) Then
			ExternalObject.barcodeData = "";
			IntegrationWith1CDocumentManagementCoreOverridable.WhenDeterminingBarcodeOfDocument(
				ExternalIPObject,
				ExternalObject.barcodeData);
		EndIf;
	EndIf;
	
	Return ExternalObject;
	
EndFunction

// Creates an ExternalObjectID object.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   ExternalIPObject - AnyRef - reference to an external IP object.
//   ID - String - ID of the external IP object.
//   Type - String - the type of external IP object.
//
// Returns:
//   XDTODataObject - an XDTO object of the ExternalObjectID type.
//
Function CreateExternalObjectID(Proxy, ExternalIPObject = Undefined, ID = "", Type = "") Export
	
	ExternalObjectID = CreateObject(Proxy, "ExternalObjectID");
	ExternalObjectID.ID = ID;
	ExternalObjectID.type = Type;
	
	If Common.IsReference(TypeOf(ExternalIPObject)) Then
		ExternalIPObjectMetadata = ExternalIPObject.Metadata();
		URL = "";
		Presentation = String(ExternalIPObject);
		// Default values.
		ExternalObjectID.type = GetLinkTypeName(ExternalIPObject);
		If Common.IsReference(TypeOf(ExternalIPObject)) Then
			If Not Enums.AllRefsType().ContainsType(TypeOf(ExternalIPObject)) Then
				URL = GetURL(ExternalIPObject);
			EndIf;
			If Not ExternalIPObject.IsEmpty() Then
				// Specifying the ID of the external object.
				ExternalObjectID.ID = GetIDFromLink(ExternalIPObject);
			Else
				Presentation = ExternalIPObjectMetadata.Synonym;
			EndIf;
		EndIf;
		If PropertyExists(ExternalObjectID, "navigationRef") Then
			ExternalObjectID.navigationRef = URL;
		EndIf;
		If PropertyExists(ExternalObjectID, "presentation") Then
			ExternalObjectID.presentation = Presentation;
		EndIf;
		If PropertyExists(ExternalObjectID, "barcodeData")
				And (Common.IsDocument(ExternalIPObjectMetadata)
					Or Common.IsCatalog(ExternalIPObjectMetadata)) Then
			ExternalObjectID.barcodeData = "";
			IntegrationWith1CDocumentManagementCoreOverridable.WhenDeterminingBarcodeOfDocument(
				ExternalIPObject,
				ExternalObjectID.barcodeData);
		EndIf;
	EndIf;
	
	Return ExternalObjectID;
	
EndFunction

// Creates a DMObjectID object.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   ID - String - id of the XDTO object.
//   Type - String - type of the XDTO object.
//
// Returns:
//   XDTODataObject - an XDTO object of the DMObjectID type.
//
Function CreateObjectID(Proxy, ID = "", Type = "") Export
	
	objectID = CreateObject(Proxy, "DMObjectID");
	objectID.ID = ID;
	objectID.type = Type;
	
	Return objectID;
	
EndFunction

// Creates an XDTO object from the data structure of the referenced object BEFORE.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   ReferenceObjectDataDM - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//
// Returns:
//   XDTODataObject - an XDTO object inherited from the DMObject type.
//
Function CreateFromReferenceObjectDataUPTO(Proxy, ReferenceObjectDataDM) Export
	
	XDTODataObject = CreateObject(Proxy, ReferenceObjectDataDM.Type);
	XDTODataObject.name = ReferenceObjectDataDM.Description;
	XDTODataObject.ObjectID = CreateObjectID(Proxy, ReferenceObjectDataDM.ID, ReferenceObjectDataDM.Type);
	
	Return XDTODataObject;
	
EndFunction

// Creates a new object in the Workflow.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   Object - XDTODataObject - description of the object being created.
//
// Returns:
//   XDTODataObject - An XDTO object of the DMCreateResponse or DMError type.
//
Function CreateNewObject(Proxy, Object) Export
	
	Query = CreateObject(Proxy, "DMCreateRequest");
	Query.object = Object;
	
	Response = ExecuteQuery(Proxy, Query);
	CheckWebServiceRefund(Proxy, Response);
	
	Return Response;
	
EndFunction

// Creates an XDTO object of the specified type from the namespace of the Workflow web service.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   ObjectType - String - type of the XDTO object.
//   ExternalIPObject - AnyRef - passed to fill in the name and externalObject properties.
//   FillInFromExternalObject - Boolean - It is required to fill in the XDTO object from an external IC object.
//
// Returns:
//   XDTODataObject - an XDTO object of the specified type.
//
Function CreateObject(Proxy, ObjectType, ExternalIPObject = Undefined, FillInFromExternalObject = True) Export
	
	DMFactory = DMFactory(Proxy);
	XDTOObjectType = DMFactory.Type(URIOfNamespaceOfWorkflowWebService(), ObjectType);
	
	If XDTOObjectType = Undefined Then
		Raise StrTemplate(
			NStr("vi = 'Web-service 1C:Document Management phiên bản %2 không hỗ trợ kiểu đối tượng ""%1""';
				|ru = 'Тип объекта ""%1"" не поддерживается веб-сервисом 1С:Документооборот версии %2';
				|en = 'The ""%1"" object type is not supported by 1C:Document Management web service of version %2'; fa = 'The ""%1"" object type is not supported by 1C:Document Management web service of version %2';
				|it = 'Tipo di oggetto ""%1"" non è supportato dal servizio web 1C:Document Management versione %2';
				|pl = 'Тип объекта ""%1"" не поддерживается веб-сервисом 1С:Документооборот версии %2 ';
				|tr = '""%1"" nesne türü, web hizmeti 1C:Document Management sürümü %2tarafından desteklenmiyor '"),
			ObjectType,
			ServiceVersion());
	EndIf;
	
	If Lower(XDTOObjectType.BaseType.Name) = "string" Then
		NewObject = "";
	Else
		NewObject = DMFactory.Create(XDTOObjectType);
	EndIf;
	
	If PropertyExists(NewObject, "dataBaseID") Then
		NewObject.dataBaseID = IntegrationWith1CDocumentManagementCoreCached.DatabaseId_();
	EndIf;
	
	If PropertyExists(NewObject, "dmilVersionNumber") Then
		NewObject.dmilVersionNumber = IntegrationWith1CDocumentManagementCoreCached.DMILVersion();
	EndIf;
	
	If PropertyExists(NewObject, "objectID") Then
		NewObject.objectID = CreateObjectID(Proxy);
	EndIf;
	
	If ExternalIPObject <> Undefined Then
		
		If TypeOf(XDTOObjectType) = Type("XDTOObjectType") Then
			For Each PropertyOfXDTOObject In XDTOObjectType.Properties Do
				If Lower(PropertyOfXDTOObject.Name) = "externalobject" Then
					If PropertyOfXDTOObject.Type.Name = "ExternalObject" Then
						NewObject.externalObject = CreateExternalObject(Proxy, ExternalIPObject);
					ElsIf PropertyOfXDTOObject.Type.Name = "ExternalObjectID" Then
						NewObject.externalObject = CreateExternalObjectID(Proxy, ExternalIPObject);
					EndIf;
					Break;
				EndIf;
			EndDo;
		EndIf;
		
		If PropertyExists(NewObject, "name") Then
			ObjectDescription = String(ExternalIPObject);
			If HasDescription(ExternalIPObject) Then
				ObjectDescription = Common.ObjectAttributeValue(ExternalIPObject, "Description");
			EndIf;
			NewObject.name = ObjectDescription;
		EndIf;
		
		If FillInFromExternalObject Then
			FillInDetailsFromConsumer(Proxy, NewObject, ExternalIPObject);
		EndIf;
		
	EndIf;
	
	Return NewObject;
	
EndFunction

// Creates an XDTO object for transferring an array of signatures to the Workflow.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   SignatureOwnerSDetails - See IntegrationWith1CDocumentManagementCoreClientServer.SignatureOwnerSDetails
//
// Returns:
//   XDTODataObject - An XDTO object with the signatures property filled in.
//
Function CreateXDTOObjectToSaveSignatures(Proxy, SignatureOwnerSDetails) Export
	
	XDTODataObject = CreateObject(Proxy, SignatureOwnerSDetails.Type);
	XDTODataObject.objectID = CreateObjectID(Proxy, SignatureOwnerSDetails.ID, SignatureOwnerSDetails.Type);
	XDTODataObject.name = SignatureOwnerSDetails.Description;
	
	If PropertyExists(XDTODataObject, "updateSignatures") Then
		XDTODataObject.updateSignatures = True;
	EndIf;
	
	FillInSignaturesOfXDTOObject(Proxy, XDTODataObject, SignatureOwnerSDetails.SignaturesArray);
	
	Return XDTODataObject;
	
EndFunction

// Returns the abbreviated name of the integrated configuration for output in headers and decorations.
//
// Returns:
//   String - abbreviated name of the configuration.
//
Function AbbreviatedNameOfConfiguration() Export
	
	NameAbbreviated = NStr("vi = 'Hệ thống thông tin';
							|ru = 'ИС';
							|en = 'IS'; fa = 'IS';
							|it = 'IS';
							|pl = 'IS';
							|tr = 'Entegre sistem'");
	
	IntegrationWith1CDocumentManagementCoreOverridable.WhenDefiningAbbreviatedConfigurationName(
		NameAbbreviated);
	
	Return NameAbbreviated;
	
EndFunction

// Gets a reference to an object by the name of the configuration object and ID.
//
// Parameters:
//   Type - String - the type of the configuration object.
//   UUID - String - id of the configuration object.
//
// Returns:
//   AnyRef - object reference.
//
Function LinkFromUUID(Type, UUID) Export
	
	ReferenceToConsumer_ = Undefined;
	
	If StrStartsWith(Type, "Catalog.") Then
		ReferenceToConsumer_ = Catalogs[StrReplace(Type,
			"Catalog.", "")].GetRef(New UUID(UUID));
		
	ElsIf StrStartsWith(Type, "Document.")Then
		ReferenceToConsumer_ = Documents[StrReplace(Type,
			"Document.", "")].GetRef(New UUID(UUID));
		
	ElsIf StrStartsWith(Type, "ChartOfAccounts.") Then
		ReferenceToConsumer_ = ChartsOfAccounts[StrReplace(Type,
			"ChartOfAccounts.", "")].GetRef(New UUID(UUID));
		
	ElsIf StrStartsWith(Type, "ChartOfCalculationTypes.") Then
		ReferenceToConsumer_ = ChartsOfCalculationTypes[StrReplace(Type,
			"ChartOfCalculationTypes.", "")].GetRef(New UUID(UUID));
		
	ElsIf StrStartsWith(Type, "ChartOfCharacteristicTypes.") Then
		ReferenceToConsumer_ = ChartsOfCharacteristicTypes[StrReplace(Type,
			"ChartOfCharacteristicTypes.", "")].GetRef(New UUID(UUID));
		
	ElsIf StrStartsWith(Type, "BusinessProcess.") Then
		ReferenceToConsumer_ = BusinessProcesses[StrReplace(Type,
			"BusinessProcess.", "")].GetRef(New UUID(UUID));
		
	ElsIf StrStartsWith(Type, "Task.") Then
		ReferenceToConsumer_ = Tasks[StrReplace(Type,
			"Task.", "")].GetRef(New UUID(UUID));
		
	ElsIf StrStartsWith(Type, "Enum.") And ValueIsFilled(UUID) Then
		ReferenceToConsumer_ = Enums[StrReplace(Type,
			"Enum.", "")][UUID];
		
	EndIf;
	
	Return ReferenceToConsumer_;
	
EndFunction

// Retrieves a link from the client application form to an object that integrates with the software.
//
// Parameters:
//   Form - ClientApplicationForm - the form in which the link is searched.
//   FormAttributes - Array of FormAttribute - list of all Attributes of the form.
//   TypeOfIntegratedObject - Type - the type of link you want to find on the form.
//
// Returns:
//   AnyRef - reference to the object being integrated.
//
Function ReferenceToIntegratedObjectFromForm(Form, FormAttributes = Undefined,
		TypeOfIntegratedObject = Undefined) Export
	
	FormAttributeValues = IntegrationWith1CDocumentManagementCoreClientServer.FormOfIntegratedObject();
	FillPropertyValues(FormAttributeValues, Form);
	
	// If the method was called in the event of the Attachment form in the server
	// integrations1documentofunctionbase functionality.If you join the server, then the name of the Attribute containing
	// the object reference will be in the Attribute of the form requesite_name of the objectintegrated by Document Management.
	If Not ValueIsFilled(FormAttributeValues.NameOfAttributeOfObjectIntegratedWith1CDocumentManagement) Then
		// If the Attribute name is unknown, we will try to determine it. It can be specified in an overridden module.
		FormAttributeValues.NameOfAttributeOfObjectIntegratedWith1CDocumentManagement =
			IntegrationWith1CDocumentManagementCoreServerCall.NameOfAttributeOfObjectIntegratedWith1CDocumentManagement(
				Form,
				FormAttributes,
				TypeOfIntegratedObject);
	EndIf;
	
	Return IntegrationWith1CDocumentManagementCoreClientServer.ReferenceToIntegratedObjectFromForm(
		Form,
		FormAttributeValues.NameOfAttributeOfObjectIntegratedWith1CDocumentManagement,
		TypeOfIntegratedObject);
	
EndFunction

// Returns references to objects of this configuration based on information about them in the object BEFORE.
//
// Parameters:
//   XDTODataObject - XDTODataObject - descendant of DMObject, the object BEFORE.
//              - Structure - contains the ID and type of the external object:
//     * ID - String - id of the external object according to 1C:Document management;
//     * type - String - type of external object according to 1C:Document management.
//
// Returns:
//   Array of AnyRef - an array of links to related objects of this configuration.
//
Function LinksToExternalObjects(XDTODataObject) Export
	
	Result = New Array;
	
	If TypeOf(XDTODataObject) = Type("Structure") Then
		ExternalObjects = New Array;
		ExternalObjects.Add(XDTODataObject);
		
	ElsIf PropertySet(XDTODataObject, "externalObjects") Then
		ExternalObjects = XDTODataObject.externalObjects;
		
	ElsIf PropertySet(XDTODataObject, "externalObject") Then
		ExternalObjects = New Array;
		ExternalObjects.Add(XDTODataObject.externalObject);
		
	Else
		Return Result;
	EndIf;
	
	SetPrivilegedMode(True);
	
	For Each ExternalObject In ExternalObjects Do
	
		Try
			Ref = LinkFromUUID(ExternalObject.type, ExternalObject.ID);
		Except
			// The object type was not found in the current configuration.
			Continue;
		EndTry;
		
		If Ref <> Undefined And Common.RefExists(Ref) Then
			Result.Add(Ref);
			
			If PropertySet(XDTODataObject, "objectID")
					And XDTODataObject.objectID.ID <> ""
					And XDTODataObject.objectID.type <> ""
					And Not ObjectDoesNotSupportExchange(XDTODataObject.objectID.type) Then
				WhetherFilesAreAttached = False; // An additional request to the DO is not required.
				If PropertySet(XDTODataObject, "files") Then
					WhetherFilesAreAttached = (XDTODataObject.files.Count() > 0);
				EndIf;
				InformationRegisters.ObjectsIntegratedWith1CDocumentManagement.AddLink(
					XDTODataObject.objectID.ID,
					XDTODataObject.objectID.type,
					Ref,
					WhetherFilesAreAttached);
			EndIf;
		EndIf;
		
	EndDo;
	
	SetPrivilegedMode(False);
	
	Return Result;
	
EndFunction

// Returns the timeout of the Workflow web service proxy, possibly overridden in the settings.
//
// Returns:
//   Number - timeout in seconds.
//
Function ServiceTimeout() Export
	
	If IntegrationWith1CDocumentManagementCoreServerCall.ThisIsExchangeJobUser() Then
		Timeout = 60;
	Else
		Timeout = 20;
	EndIf;
	IntegrationWith1CDocumentManagementCoreOverridable.WhenDeterminingServiceTimeout(Timeout);
	
	Return Timeout;
	
EndFunction

// Gets the current 1C user:Document management.
//
// Returns:
//   Array of XDTODataObject - An XDTO object of type DMUser, DMEmployee, or Undefined.
//
Function Current1CDocumentManagementUser() Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	If SessionParameters.IntegrationWith1CDocumentManagementCurrentUser = "" Then
		
		Query = CurCurrentWorkflowUserRequest(Proxy);
		Response = ExecuteQuery(Proxy, Query);
		
	Else
		
		Response = StringInXDTOObject(Proxy, SessionParameters.IntegrationWith1CDocumentManagementCurrentUser);
		
	EndIf;
	
	If ValidateType(Proxy, Response, "DMError") Then
		Return Undefined;
	Else
		Result = New Array;
		Result.Add(Response.user);
		
		Settings = IntegrationWith1CDocumentManagementCoreServerCall.UseIntegration();
		If Settings.UseIntegrationBefore3 Then
			UserEmployees = Response.employees; // XDTOList
			For Each Employee In UserEmployees Do
				Result.Add(Employee);
			EndDo;
		EndIf;
		
		Return Result;
	EndIf;
	
EndFunction

// returns a request to get the Cur of the 1C user:Document management.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//
// Returns:
//   XDTODataObject - an XDTO object of the DMGetCurrentUserRequest type.
//
Function CurCurrentWorkflowUserRequest(Proxy) Export
	
	Return CreateObject(Proxy, "DMGetCurrentUserRequest");
	
EndFunction

// Checks whether the types of the XDTO object match.
//
// Parameters:
//   Type1 - XDTOObjectType - the first type.
//   Type2 - XDTOObjectType - the second type.
//
// Returns:
//   Boolean
//
Function XDTOTypesAreSame(Type1, Type2) Export
	
	If TypeOf(Type1) <> Type("XDTOObjectType") Or TypeOf(Type2) <> Type("XDTOObjectType") Then
		Return False;
	EndIf;
	
	Return (Type1.NamespaceURI = Type2.NamespaceURI)
		And (Type1.Name = Type2.Name)
		And (NameOfBaseTypeXDTO(Type1) = NameOfBaseTypeXDTO(Type2));
	
EndFunction

// BID commands can appear on the form of an IC object in the "Creation based on" section in various ways:
//   1. Automatically: the platform will display the general command if
//      the visibility of the command is not disabled in the command interface of a specific form.
//   2. Programmatically: through the BSP mechanism, the creation of the foundation is undetectable.Before adding the Creation command,
//      if a specific IC object was connected to the BSP mechanism in the method
//      The creation of the base is undetectable.When defining the objectscommand of creation.
// Thus, we do not know in advance which of the ways the command was output.
// If both methods have worked, the command will be duplicated on the form.
// This procedure allows you to hide an extra command.
//
// Parameters:
//   Form - ClientApplicationForm - the form from which the procedure is called.
//   CommandName - String - the name of the command whose duplicates you want to hide.
//
Procedure RemoveDuplicatesOfIntegrationCommands(Form, CommandName) Export
	
	ListOfCommands = New ValueTable;
	ListOfCommands.Columns.Add("Command");
	ListOfCommands.Columns.Add("Priority");
	
	For Each FormItem In Form.Items Do
		If TypeOf(FormItem) = Type("FormButton")
				And FormItem.Visible
				And StrEndsWith(FormItem.Name, CommandName)
				And StrFind(FormItem.Name, "ContextMenu") = 0 Then
			NewRow = ListOfCommands.Add();
			NewRow.Command = FormItem;
			NewRow.Priority = ?(StrStartsWith(FormItem.Name, "FormOfGeneralCommand"), 1, 0);
		EndIf;
	EndDo;
	
	ListOfCommands.Sort("Priority");
	
	If ListOfCommands.Count() > 1 Then
		For IndexOf = 1 To ListOfCommands.Count() - 1 Do
			ListOfCommands[IndexOf].Command.Visible = False;
		EndDo;
	EndIf;
	
EndProcedure

// Sets the service version in the session parameters.
//
// Parameters:
//   FromBackgroundTask - Boolean - the procedure is started from a background job.
//   ErrorText - String - an implicit return value, the text of the error message
//     received when determining the service version.
//   AddressOfDocumentManagementWebService - String - the address of the web service BEFORE, or
//                                   - Undefined - indicates the need to use a previously saved address.
//
Procedure InstallServiceVersion(FromBackgroundTask = False, ErrorText = "",
		AddressOfDocumentManagementWebService = Undefined) Export
	
	PreviousValue2 = ServiceVersion();
	SessionParameters.IntegrationWith1CDocumentManagementServiceVersion = GetVersionByCallingService(
		FromBackgroundTask,
		ErrorText,
		AddressOfDocumentManagementWebService);
	
	If PreviousValue2 <> "" And PreviousValue2 <> "0.0.0.0" And PreviousValue2 <> ServiceVersion() Then
		UpdateReusedParameters();
	EndIf;
	
EndProcedure

// Sets the parameters of the session with the subsystem "Integration with 1C:Document management".
//
// Parameters:
//   ParameterName - String
//   SpecifiedParameters - Array of String
//
Procedure SetSessionParameters(ParameterName, SpecifiedParameters) Export
	
	If ParameterName = "IntegrationWith1CDocumentManagementWSDefinitions" Then
		SessionParameters.IntegrationWith1CDocumentManagementWSDefinitions = New ValueStorage(Undefined);
		If SpecifiedParameters <> Undefined Then
			SpecifiedParameters.Add("IntegrationWith1CDocumentManagementWSDefinitions");
		EndIf;
	EndIf;
	
	If ParameterName = "IntegrationWith1CDocumentManagementServiceVersion" Then
		SessionParameters.IntegrationWith1CDocumentManagementServiceVersion = "";
		If InfobaseUpdate.InfobaseUpdateRequired()
				Or InfobaseUpdate.InfobaseUpdateInProgress() Then
			SessionParameters.IntegrationWith1CDocumentManagementServiceVersion = "0.0.0.0";
		EndIf;
		If SpecifiedParameters <> Undefined Then
			SpecifiedParameters.Add("IntegrationWith1CDocumentManagementServiceVersion");
		EndIf;
		
	EndIf;
	
	If ParameterName = "IntegrationWith1CDocumentManagementUsername" Then
		SessionParameters.IntegrationWith1CDocumentManagementUsername = "";
		If SpecifiedParameters <> Undefined Then
			SpecifiedParameters.Add("IntegrationWith1CDocumentManagementUsername");
		EndIf;
	EndIf;
	
	If ParameterName = "IntegrationWith1CDocumentManagementJWTTokenAuthenticationIsUsed" Then
		SessionParameters.IntegrationWith1CDocumentManagementJWTTokenAuthenticationIsUsed = False;
		If SpecifiedParameters <> Undefined Then
			SpecifiedParameters.Add("IntegrationWith1CDocumentManagementJWTTokenAuthenticationIsUsed");
		EndIf;
	EndIf;
	
	If ParameterName = "IntegrationWith1CDocumentManagementOSAuthenticationIsUsed" Then
		SessionParameters.IntegrationWith1CDocumentManagementOSAuthenticationIsUsed = False;
		If SpecifiedParameters <> Undefined Then
			SpecifiedParameters.Add("IntegrationWith1CDocumentManagementOSAuthenticationIsUsed");
		EndIf;
	EndIf;
	
	If ParameterName = "IntegrationWith1CDocumentManagementProxyServerLocation" Then
		SessionParameters.IntegrationWith1CDocumentManagementProxyServerLocation = "";
		If SpecifiedParameters <> Undefined Then
			SpecifiedParameters.Add("IntegrationWith1CDocumentManagementProxyServerLocation");
		EndIf;
	EndIf;
	
	If ParameterName = "IntegrationWith1CDocumentManagementSettings" Then
		SessionParameters.IntegrationWith1CDocumentManagementSettings = "";
		If SpecifiedParameters <> Undefined Then
			SpecifiedParameters.Add("IntegrationWith1CDocumentManagementSettings");
		EndIf;
	EndIf;
	
	If ParameterName = "IntegrationWith1CDocumentManagementConnectingOperation" Then
		SessionParameters.IntegrationWith1CDocumentManagementConnectingOperation = New ValueStorage(Undefined);
		If SpecifiedParameters <> Undefined Then
			SpecifiedParameters.Add("IntegrationWith1CDocumentManagementConnectingOperation");
		EndIf;
	EndIf;
	
	If ParameterName = "IntegrationWith1CDocumentManagementPassword" Then
		SessionParameters.IntegrationWith1CDocumentManagementPassword = "";
		If SpecifiedParameters <> Undefined Then
			SpecifiedParameters.Add("IntegrationWith1CDocumentManagementPassword");
		EndIf;
	EndIf;
	
	If ParameterName = "IntegrationWith1CDocumentManagementPasswordIsKnown" Then
		SessionParameters.IntegrationWith1CDocumentManagementPasswordIsKnown = False;
		If SpecifiedParameters <> Undefined Then
			SpecifiedParameters.Add("IntegrationWith1CDocumentManagementPasswordIsKnown");
		EndIf;
	EndIf;
	
	If ParameterName = "Integration1CDocumentManagementXMLSchema" Then
		SessionParameters.Integration1CDocumentManagementXMLSchema = "";
		If SpecifiedParameters <> Undefined Then
			SpecifiedParameters.Add("Integration1CDocumentManagementXMLSchema");
		EndIf;
	EndIf;
	
	If ParameterName = "IntegrationWith1CDocumentManagementCurrentUser" Then
		SessionParameters.IntegrationWith1CDocumentManagementCurrentUser = "";
		If SpecifiedParameters <> Undefined Then
			SpecifiedParameters.Add("IntegrationWith1CDocumentManagementCurrentUser");
		EndIf;
	EndIf;
	
	If ParameterName = "IntegrationWith1CDocumentManagementNode" Then
		SessionParameters.IntegrationWith1CDocumentManagementNode = "";
		Settings = IntegrationWith1CDocumentManagementCoreServerCall.UseIntegration();
		If Settings.UseIntegrationBefore3 Then
			ModuleIntegrationWith1CDocumentManagement3 = Common.CommonModule("IntegrationWith1CDocumentManagement3");
			SessionParameters.IntegrationWith1CDocumentManagementNode =
				ModuleIntegrationWith1CDocumentManagement3.CurrentUserSSUBAsset();
		EndIf;
		If SpecifiedParameters <> Undefined Then
			SpecifiedParameters.Add("IntegrationWith1CDocumentManagementNode");
		EndIf;
	EndIf;
	
EndProcedure

// Sets session parameters by an array of names.
//
// Parameters:
//   ParameterNames - Array of String - an array of strings with the names of the session parameters to install.
//
Procedure SetSessionParametersByArrayOfNames(ParameterNames) Export
	
	If TypeOf(ParameterNames) <> Type("Array") Then
		Return;
	EndIf;
	
	For Each ParameterName In ParameterNames Do
		SetSessionParameters(ParameterName, Undefined);
	EndDo;
	
EndProcedure

// Adds a barcode for the IP object to the linked document in UP to.
//
// Parameters:
//   ObjectIS - AnyRef - the IP object, the data source of the filling.
//   ID - String - ID of the document flow object.
//   Type - String - XDTO-type of document management object
//
Procedure SetBarcode(ObjectIS, ID, Type) Export
	
	If Find(Type, "Document") = 0 Then
		Return;
	EndIf;
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	BarcodeObjectIS = "";
	IntegrationWith1CDocumentManagementCoreOverridable.WhenDeterminingBarcodeOfDocument(
		ObjectIS,
		BarcodeObjectIS);
	If ValueIsFilled(BarcodeObjectIS)
			And IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.4.3.1.CORP") Then
		
		Query = CreateObject(Proxy, "DMRetrieveBarcodesRequest");
		
		Query.objectID = CreateObjectID(Proxy, ID, Type);
		
		Result = ExecuteQuery(Proxy, Query);
		CheckWebServiceRefund(Proxy, Result);
		
		Query = CreateObject(Proxy, "DMUpdateBarcodesRequest");
		
		Query.objectBarcodes = Result.objectBarcodes;
		BarcodeList = Query.objectBarcodes.barcodes; // XDTOList
		
		Barcode = CreateObject(Proxy, "DMBarcode");
		Barcode.internal = False;
		Barcode.barcodeData = BarcodeObjectIS;
		BarcodeList.Add(Barcode);
		
		Result = ExecuteQuery(Proxy, Query);
		CheckWebServiceRefund(Proxy, Result);
		
	EndIf;
	
EndProcedure

// Returns the XDTO factory that the Workflow service works with.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   RaiseException1 - Boolean - raise an exception if the Document Management service is unavailable.
//
// Returns:
//   XDTOFactory
//
Function DMFactory(Proxy = Undefined, RaiseException1 = True) Export
	
	If SessionParameters.Integration1CDocumentManagementXMLSchema <> "" Then
		
		Return IntegrationWith1CDocumentManagementCoreCached.DMFactory(
			SessionParameters.Integration1CDocumentManagementXMLSchema);
		
	ElsIf Proxy <> Undefined Then
		
		Return Proxy.XDTOFactory;
		
	ElsIf RaiseException1 Then
		
		Raise NStr("vi = 'Chưa tùy chỉnh tích hợp với 1C:Document Management hoặc dịch vụ
			|1C:Document Management không khả dụng. Hãy liên hệ với người quản trị.';
			|ru = 'Интеграция с 1С:Документооборотом не настроена, или сервис
			|1С:Документооборота недоступен. Обратитесь к администратору.';
			|en = 'Integration with 1C:Document Management is not configured, or
			|1C:Document Management service is not available. Contact your administrator.'; fa = 'Integration with 1C:Document Management is not configured, or
			|1C:Document Management service is not available. Contact your administrator.';
			|it = 'Интеграция с 1С:Документооборотом не настроена, или сервис
			|1С:Документооборота недоступен. Обратитесь к администратору.';
			|pl = 'Integracja z 1C:Document Management nie jest ustawiona, lub usługa 
			|1C:Document Management jest niedostępny. Zwróć się do administratora.';
			|tr = '1C:Document Management ile entegrasyon yapılandırılmamış veya
			|1C:Document Management hizmeti kullanılamıyor. Yönetici ile iletişime geç.'");
		
	EndIf;
	
EndFunction

// Checks whether the value is an object, i.e. inherited from the DMObject type.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   Value - Arbitrary - the value to check.
//
// Returns:
//   Boolean - True if the value is a descendant of the DMObject type, otherwise False.
//
Function ThisIsObjectValue(Proxy, Value) Export
	
	If TypeOf(Value) <> Type("XDTODataObject") Then
		Return False;
	EndIf;
	
	DMFactory = DMFactory(Proxy);
	ObjectType = DMFactory.Type(URIOfNamespaceOfWorkflowWebService(), "DMObject");
	Return ObjectType.IsDescendant(Value.Type());
	
EndFunction

// Checks whether the property is an object, i.e. inherited from the DMObject type.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   XDTODataObject - XDTODataObject - an object containing the property to be checked
//   PropertyNameXDTO - String - name of the property being checked
//
// Returns:
//   Boolean - True if the property is a descendant of the DMObject type, otherwise False
//
Function ThisIsObjectProperty(Proxy, XDTODataObject, PropertyNameXDTO) Export
	
	PropertyExists(XDTODataObject, PropertyNameXDTO, True);
	
	PropertyType1 = XDTODataObject.Type().Properties.Get(PropertyNameXDTO).Type;
	DMFactory = DMFactory(Proxy);
	TypeParent = DMFactory.Type(URIOfNamespaceOfWorkflowWebService(), "DMObject");
	
	Return TypeOf(PropertyType1) = Type("XDTOObjectType") And TypeParent.IsDescendant(PropertyType1);
	
EndFunction

#EndRegion

#Region RequestsToThe1CDocumentManagement

// gets the 1C object:The document flow associated with the configuration object-the consumer.
//
// Parameters:
//   ReferenceToExternalObject - AnyRef - a reference to the consumer configuration object.
//   GetFromTO - Boolean - you need to get a link to the linked object on the Workflow side.
//   GetPersonalIncomeTax - Boolean - You need to get the State-based accessibility settings on the Workflow side.
//
// Returns:
//   Undefined, Structure - object data:
//     * name - String - name of the Workflow object.
//     * ID - String - the unique identifier of the object in the Document Flow.
//     * type - String - the name of the XDTO type corresponding to the object BEFORE.
//     * ExternalObject - AnyRef - a link to the associated IP object.
//
Function ObjectDataUpToExternalObject(ReferenceToExternalObject, GetFromTO = False, GetPersonalIncomeTax = False) Export
	
	If Not ValueIsFilled(ReferenceToExternalObject) Then
		Return Undefined;
	EndIf;
	
	Settings = IntegrationWith1CDocumentManagementCoreServerCall.UseIntegration();
	
	If Settings.UseIntegrationBefore2 Or GetFromTO Then
		
		Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
		Query = CreateObject(Proxy, "DMGetDocumentListRequest");
		ListOfExternalObjects = Query.externalObjects; // XDTOList
		ListOfExternalObjects.Add(
			CreateExternalObject(Proxy, ReferenceToExternalObject));
		
		FieldsReceived = Query.columnSet; // XDTOList
		FieldsReceived.Add("name");
		FieldsReceived.Add("documentType");
		FieldsReceived.Add("enabledProperties");
		
		Result = ExecuteQuery(Proxy, Query);
		CheckWebServiceRefund(Proxy, Result);
		
		If Result.documents.Count() > 0 Then
			
			Object = Result.documents[0];
			
			ReturnData = New Structure;
			ReturnData.Insert("ExternalObject", ReferenceToExternalObject);
			ReturnData.Insert("ID", Object.objectID.ID);
			ReturnData.Insert("type", Object.objectID.type);
			ReturnData.Insert("name", Object.name);
			
			IntegrationWith1CDocumentManagementCoreClientServer.AddPersonalData(ReturnData);
			FillInPPEOfXDTOObject(ReturnData, Object);
			
			If StrFind(ReturnData.type, "Document") > 0 Then
				
				If Object.documentType = Undefined Then
					Raise StrTemplate(NStr("vi = 'Không thể nhận dữ liệu 1C:Document Management: %1.
						|Hãy liên hệ với người quản trị.';
						|ru = 'Невозможно получить данные 1С:Документооборота: %1.
						|Обратитесь к администратору.';
						|en = 'Cannot receive 1C:Document Management data: %1.
						|Contact the administrator.'; fa = 'Cannot receive 1C:Document Management data: %1.
						|Contact the administrator.';
						|it = 'Невозможно получить данные 1С:Документооборота: %1.
						|Обратитесь к администратору.';
						|pl = 'Nie można otrzymać danych 1C:Document Management: %1.
						|Zwróć się do administratora.';
						|tr = '1C:Document Management verileri alınamıyor: %1.
						|Yönetici ile iletişime geç.'"),
						Object.name);
				EndIf;
				
				DocumentKind = New Structure("ID, type, name",
					Object.documentType.objectID.ID,
					Object.documentType.objectID.type,
					Object.documentType.name);
				
				ReturnData.Insert("documentType", DocumentKind);
				
			EndIf;
			
			Return ReturnData;
			
		EndIf;
		
	ElsIf Settings.UseIntegrationBefore3 Then
		
		ReturnData = InformationRegisters.ObjectsIntegratedWith1CDocumentManagement.ObjectDataUpToExternalObject(
			ReferenceToExternalObject);
		
		If ReturnData <> Undefined Then
			
			Document = Undefined;
			
			ModuleIntegrationWith1CDocumentManagement3 = Common.CommonModule("IntegrationWith1CDocumentManagement3");
			If GetPersonalIncomeTax And ModuleIntegrationWith1CDocumentManagement3.IsDocumentBefore3(ReturnData.type) Then
				Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
				Document = GetObject(
					Proxy,
					ReturnData.type,
					ReturnData.ID,
					"enabledProperties");
			EndIf;
			
			IntegrationWith1CDocumentManagementCoreClientServer.AddPersonalData(ReturnData);
			FillInPPEOfXDTOObject(ReturnData, Document);
			
		EndIf;
		
		Return ReturnData;
		
	EndIf;
	
EndFunction

#EndRegion

#Region ASBS

// Fills in the State-based accessibility settings from the XDTO object in the data structure.
//
// Parameters:
//   StructureOfData - Structure, ClientApplicationForm - an arbitrary structure that needs
//     to be supplemented with NDPS values.
//   XDTODataObject - XDTODataObject - An XDTO object containing the enabledProperties property.
//
Procedure FillInPPEOfXDTOObject(StructureOfData, XDTODataObject = Undefined) Export
	
	If PropertySet(XDTODataObject, "enabledProperties") And XDTODataObject.enabledProperties.Count() <> 0 Then
		
		IntegrationWith1CDocumentManagementCoreClientServer.SetValuesOfAllNDPSFields(
			StructureOfData,
			False);
		
		ASBSFields = IntegrationWith1CDocumentManagementCoreClientServer.ASBSFields();
		For Each AvailableField In XDTODataObject.enabledProperties Do
			FieldName = ASBSFields[Lower(AvailableField)];
			If FieldName = Undefined Then
				Continue;
			EndIf;
			If IntegrationWith1CDocumentManagementCoreClientServer.ThereIsProperty(
					StructureOfData, FieldName) Then
				StructureOfData[FieldName] = True;
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure

// Fills in the State-based accessibility settings in the data structure from the specified properties of the XDTO object.
//
// Parameters:
//   StructureOfData - Structure, ClientApplicationForm - an arbitrary structure that needs
//     to be supplemented with the NDPS value.
//   XDTODataObject - XDTODataObject - the source object whose property you want to transfer to the NPS.
//   PropertiesNames - String - comma-separated property names.
//
Procedure FillInNDPPpeOfXDTOProperties(StructureOfData, XDTODataObject, PropertiesNames) Export
	
	For Each PropertyName In StrSplit(PropertiesNames, ",", False) Do
		If PropertySet(XDTODataObject, PropertyName) Then
			ASBSFields = IntegrationWith1CDocumentManagementCoreClientServer.ASBSFields();
			StructureOfData[ASBSFields[PropertyName]] = XDTODataObject[PropertyName];
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region Files

// Returns data stored on the DO side of files.
//
// Parameters:
//   Source - AnyRef - a reference to the original IP object.
//   FormUniqueID - UUID - ID of the calling form.
//   ExtensionsList - String - a comma-separated list of file extensions to get from BEFORE.
//
// Returns:
//   Array of See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//
Function IPObjectFileData(Source, FormUniqueID, Val ExtensionsList = Undefined) Export
	
	FilesData = New Array;
	
	Settings = IntegrationWith1CDocumentManagementCoreServerCall.UseIntegration();
	
	If Not Settings.UseIntegrationBefore2 And Not Settings.UseIntegrationBefore3 Then
		Return FilesData;
	EndIf;
	
	UseEDIToStoreObjectFiles =
		IntegrationWith1CDocumentManagementCoreServerCall.Use1CDocumentManagementAttachedFilesForTheObject(
			Source);
	If Not UseEDIToStoreObjectFiles Then
		Return FilesData;
	EndIf;
	
	LinkedObjectBefore =
		IntegrationWith1CDocumentManagementCoreServerCall.ObjectDataUpToExternalObject(Source);
	If LinkedObjectBefore = Undefined Then
		Return FilesData;
	EndIf;
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	XDTODataObject = GetObject(Proxy, LinkedObjectBefore.type, LinkedObjectBefore.ID, "files");
	
	ValidExtensions = New Array;
	If TypeOf(ExtensionsList) = Type("String") Then
		ExtensionsList = StrReplace(ExtensionsList, " ", "");
		ExtensionsList = Lower(ExtensionsList);
		ValidExtensions = StrSplit(ExtensionsList, ",", False);
	EndIf;
	NoFilter = (ValidExtensions.Count() = 0);
	
	NecessaryFiles = New Array;
	For Each XDTOFile In XDTODataObject.files Do
		If NoFilter Or ValidExtensions.Find(Lower(XDTOFile.extension)) <> Undefined Then
			NecessaryFiles.Add(New Structure("ID, Type", XDTOFile.objectID.ID, XDTOFile.objectID.type));
		EndIf;
	EndDo;
	If NecessaryFiles.Count() = 0 Then
		Return FilesData;
	EndIf;
	
	NecessaryXDTOFiles = GetObjects(Proxy, NecessaryFiles, "name,extension,size,binaryData");
	
	For Each XDTOFile In NecessaryXDTOFiles Do
		FileData = IntegrationWith1CDocumentManagementCoreClientServer.FileData(
			XDTOFile.name,
			XDTOFile.objectID.ID,
			XDTOFile.objectID.type,
			XDTOFile.extension);
		FileData.Size = XDTOFile.size;
		FileData.RefToBinaryFileData = PutToTempStorage(
			XDTOFile.binaryData,
			FormUniqueID);
		
		FilesData.Add(FileData);
	EndDo;
	
	Return FilesData;
	
EndFunction

// Adds a print Command to the object's print form table.
//
// Parameters:
//   PrintForms - ValueTable:
//     * PrintManager - String - the name of the object whose manager module contains
//                                 the Print procedure that generates tabular documents for this command.
//     * CommandName - String
//     * CommandPresentation - String
//     * AdditionalParameters - String - (optional) custom parameters to pass to the print Manager.
//   PrintCommand - See PrintManagement.FormPrintCommands
//
Procedure AddPrintCommand(PrintForms, PrintCommand) Export
	
	String = PrintForms.Add();
	String.PrintManager = PrintCommand.PrintManager;
	String.CommandName = PrintCommand.Id;
	String.CommandPresentation = PrintCommand.Presentation;
	String.AdditionalParameters = PrintCommand.AdditionalParametersInLine;
	
EndProcedure

// Fills in the collection of printed forms of an object by the name of the print manager and the print manager's command.
//
// Parameters:
//   ExternalObject - AnyRef - external object.
//   CommandName - String - command name.
//   AdditionalParameters - String - (optional) custom parameters to pass to the print Manager.
//   PrintFormsCollection - ValueTable - an implicitly returned value.
//
Procedure FillInCollectionOfPrintedForms(ExternalObject, CommandName, AdditionalParameters,
		PrintFormsCollection) Export
	
	StandardProcessing = True;
	
	IntegrationWith1CDocumentManagementCoreOverridable.WhenFillingOutCollectionOfPrintedForms(
		ExternalObject,
		CommandName,
		AdditionalParameters,
		PrintFormsCollection,
		StandardProcessing);
	
	If StandardProcessing = False Then
		Return;
	EndIf;
	
	ModulePrintManager = Undefined;
	ModuleAdditionalReportsAndDataProcessors = Undefined;
	
	If Common.SubsystemExists("StandardSubsystems.Print") Then
		ModulePrintManager = Common.CommonModule("PrintManagement");
	EndIf;
	If Common.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors") Then
		ModuleAdditionalReportsAndDataProcessors = Common.CommonModule("AdditionalReportsAndDataProcessors");
	EndIf;
	
	If ModulePrintManager = Undefined Or ModuleAdditionalReportsAndDataProcessors = Undefined Then
		PrintFormsCollection = New ValueTable;
		Return;
	EndIf;
	
	If StrFind(CommandName, "PrintCommand") = 1 Then
		CommandNumberAsString = Mid(CommandName, StrLen("PrintCommand") + 1);
		If CommandNumberAsString = "0" Then
			CommandNumber = 0;
		Else
			TypeDescription = New TypeDescription("Number");
			CommandNumber = TypeDescription.AdjustValue(CommandNumberAsString);
			CommandNumber = ?(CommandNumber = 0, -1, CommandNumber);
		EndIf;
	Else
		CommandNumber = -1;
	EndIf;
	
	ObjectManager = ExternalObject.Metadata().FullName();
	
	PrintCommands = FormPrintCommands(ObjectManager + ".Form.ListForm");
	NumberOfPrintCommands = PrintCommands.Count();
	If NumberOfPrintCommands = 0 Then
		PrintFormsCollection = New ValueTable;
		Return;
	EndIf;
	
	If CommandNumber = -1 Or CommandNumber >= NumberOfPrintCommands Then
		Filter = New Structure("Id", CommandName);
		If ValueIsFilled(AdditionalParameters) Then
			Filter.Insert("AdditionalParametersInLine", AdditionalParameters);
		EndIf;
		PrintCommandLines = PrintCommands.FindRows(Filter);
		If PrintCommandLines.Count() > 0 Then
			PrintCommand = PrintCommandLines[0];
		EndIf;
	Else
		PrintCommand = PrintCommands[CommandNumber];
	EndIf;
	CommandDetails = Common.ValueTableRowToStructure(PrintCommand);
	
	PrintObjectsList = New ValueList;
	PrintObjectsList.Add(ExternalObject);
	
	PrintObjects = New Array;
	PrintObjects.Add(ExternalObject);
	
	CommandDetails.Insert("PrintObjects", PrintObjects);
	
	PrintParameters = CommandDetails.AdditionalParameters; // Structure
	OutputParameters = Undefined;
	
	Try
		
		If PrintParameters.Property("Ref") And ValueIsFilled(PrintParameters.Ref) Then
				PrintParameters.Insert("CommandID", CommandDetails.Id);
				PrintParameters.Insert("RelatedObjects", PrintObjects);
				
				ModuleAdditionalReportsAndDataProcessors.PrintByExternalSource(
					PrintParameters.Ref,
					PrintParameters,
					PrintFormsCollection,
					PrintObjectsList,
					OutputParameters);
		Else
			PrintForms = ModulePrintManager.GeneratePrintForms(
				CommandDetails.PrintManager,
				CommandDetails.Id,
				PrintObjects,
				PrintParameters);
			PrintFormsCollection = PrintForms.PrintFormsCollection;
		EndIf;
		
	Except
		
		PrintFormsCollection = New ValueTable;
		MessageText = StrTemplate(
			NStr("vi = 'Không thể tạo mẫu in ""%1"" theo lý do:
				|%2 ';
				|ru = 'Не удалось сформировать печатную форму ""%1"" по причине:
				|%2';
				|en = 'Cannot generate the %1 print form due to:
				|%2'; fa = 'Cannot generate the %1 print form due to:
				|%2';
				|it = 'Не удалось сформировать печатную форму ""%1"" по причине:
				|%2';
				|pl = 'Cannot generate the %1 print form due to:
				|%2';
				|tr = 'Şu nedenden dolayı ""%1"" yazdırma formu oluşturulamadı:
				|%2'"),
			CommandDetails.Presentation,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		WriteLogEvent(
			EventLogEventName(),
			EventLogLevel.Error,,,
			MessageText);
		
	EndTry;
	
EndProcedure

// Fills in the list of attached IP object files that have not been transferred to the linked document BEFORE.
//
// Parameters:
//   NonTransferredToDMAttachedFilesToIS - ValueList of AnyRef - an implicit return value. List
//     of files that have not been transferred.
//   AllAttachedVISFiles - Array of AnyRef - a list of all attached object files
//     stored in the IC.
//                             - AnyRef - a link to the owner of the files in the IP.
//   ListOfFilesBefore - XDTOList - a list of XDTO objects of the DMFile type.
//
Procedure FillInNonTransferredToDMAttachedFilesToIS(NonTransferredToDMAttachedFilesToIS,
		Val AllAttachedVISFiles, ListOfFilesBefore) Export
	
	If NonTransferredToDMAttachedFilesToIS = Undefined Then
		NonTransferredToDMAttachedFilesToIS = New ValueList;
	Else
		NonTransferredToDMAttachedFilesToIS.Clear();
	EndIf;
	
	If TypeOf(AllAttachedVISFiles) <> Type("Array") Then
		// A link to the owner was passed in the All-Connected Files parameter.
		AllAttachedVISFiles = AttachedVISFiles(AllAttachedVISFiles);
	EndIf;
	
	NumberOfIPFiles = AllAttachedVISFiles.UBound();
	For IndexOf = 0 To NumberOfIPFiles Do
		FileNumber = NumberOfIPFiles - IndexOf;
		AttachedVISFile = AllAttachedVISFiles[FileNumber];
		IdOfIPFile = String(AttachedVISFile.UUID());
		FileIsVDO = False;
		For Each XDTOFile In ListOfFilesBefore Do
			If XDTOFile.objectID.id = IdOfIPFile Then
				FileIsVDO = True;
				Break;
			EndIf;
		EndDo;
		If FileIsVDO Then
			AllAttachedVISFiles.Delete(FileNumber);
		EndIf;
	EndDo;
	For Each AttachedVISFile In AllAttachedVISFiles Do
		NonTransferredToDMAttachedFilesToIS.Add(AttachedVISFile);
	EndDo;
	
EndProcedure

// Retrieves a table of object form print managers.
//
// Parameters:
//   ObjectManager - String - the full name of the metadata of the object manager.
//   PrintForms - ValueTable:
//     * PrintManager - String - the name of the object whose manager module contains
//                                 the Print procedure that generates tabular documents for this command.
//     * CommandName - String
//     * CommandPresentation - String
//     * AdditionalParameters - String - (optional) custom parameters to pass to the print Manager.
//
Procedure FillInTableOfObjectPrintManagers(ObjectManager, PrintForms) Export
	
	StandardProcessing = True;
	
	IntegrationWith1CDocumentManagementCoreOverridable.WhenFillingInObjectPrintManagerTable(
		ObjectManager,
		PrintForms,
		StandardProcessing);
	
	If StandardProcessing = False Then
		Return;
	EndIf;
	
	PrintCommands = FormPrintCommands(ObjectManager + ".Form.ListForm");
	For Each PrintCommand In PrintCommands Do
		AddPrintCommand(PrintForms, PrintCommand);
	EndDo;
	
EndProcedure

// Generates the file name of the printed Form of the IC object for placement in the DO.
//
// Parameters:
//   Source - AnyRef - a reference to the original IP object.
//   CommandPresentation - String - synonym for the print Command.
//   TemplateSynonym - String - synonym for the printed Form Template.
//   TemplateName - String - name of the print form layout.
//
// Returns:
//   String
//
Function NameOfPrintForm(Source, CommandPresentation, TemplateSynonym, TemplateName) Export
	
	If ValueIsFilled(CommandPresentation) Then
		PrintFormPresentation = CommandPresentation;
	ElsIf ValueIsFilled(TemplateSynonym) Then
		PrintFormPresentation = TemplateSynonym;
	Else
		PrintFormPresentation = TemplateName;
	EndIf;
	
	Source_Metadata = Source.Metadata();
	If Common.IsDocument(Source_Metadata) And Source_Metadata.NumberLength > 0 Then
		DateNumber = Common.ObjectAttributesValues(Source, "Date, Number");
		FileName = StrTemplate(NStr("vi = '%1 Số%2 ngày %3';
									|ru = '%1 №%2 от %3';
									|en = '%1 No%2 dated %3'; fa = '%1 No%2 dated %3';
									|it = '%1 №%2 del %3';
									|pl = '%1 nr %2 z dnia %3.';
									|tr = '%1 sayılı %2 tarihli %3'"),
			PrintFormPresentation,
			String(DateNumber.Number),
			Format(DateNumber.Date, "DF=dd.MM.yyyy")); // Design solution. The local date format (DLF) is not
				// used, because the integration matches the files of printed
				// Forms by name, which must be fixed.
	Else
		FileName = StrTemplate(NStr("vi = '%1 %2';
									|ru = '%1 %2';
									|en = '%1 %2'; fa = '%1 %2';
									|it = '%1 %2';
									|pl = '%1 %2';
									|tr = '%1 %2'"),
			PrintFormPresentation,
			String(Source));
	EndIf;
	
	Return CommonClientServer.ReplaceProhibitedCharsInFileName(FileName, " ");
	
EndFunction

// Gets the index of the file icon - the index in the image of the collection of pictogram files.
//
// Parameters:
//   Extension - String - file extension.
//   DeletionMark - Boolean - the file is marked for deletion.
//
// Returns:
//   Number
//
Function IndexOfFileIcon(Extension, DeletionMark = False) Export
	
	PictureIndex = IntegrationWith1CDocumentManagementCoreClientServer.IndexOfFileIcon(Extension);
	
	If DeletionMark Then
		PictureIndex = PictureIndex + 1;
	EndIf;
	
	Return PictureIndex;
	
EndFunction

// Returns the number of attached files to the associated 1C object:Document flow.
//
// Parameters:
//   ID - String - ID of the document flow object.
//   Type - String - XDTO is the type of Document flow object.
//   IncludingRemoteOnes - Boolean - whether to take into account files marked for deletion.
//
// Returns:
//   Number - the number of attached files.
//
Function NumberOfAssociatedObjectFiles(ID, Type, IncludingRemoteOnes = True) Export
	
	If ID = "" Or Type = "" Then
		Return Undefined;
	EndIf;
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	FieldsReceived = New Array;
	FieldsReceived.Add("files");
	If StrFind(Type, "Document") > 0 Then
		FieldsReceived.Add("enabledProperties");
	EndIf;
	If IncludingRemoteOnes Then
		FieldsReceived.Add("ignoreDeletionMark");
	EndIf;
	
	XDTODataObject = GetObject(
		Proxy,
		Type,
		ID,
		FieldsReceived);
	
	If PropertySet(XDTODataObject, "files") Then
		Return XDTODataObject.files.Count();
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// Returns form print commands.
//
// Parameters:
//   FormName - String - the name of the object form.
//
// Returns:
//   See PrintManagement.CreatePrintCommandsCollection
//
Function FormPrintCommands(Val FormName) Export
	
	If Not Common.SubsystemExists("StandardSubsystems.Print") Then
		Return New ValueTable;
	EndIf;
	
	ModulePrintManager = Common.CommonModule("PrintManagement");
	CollectionOfPrintCommands = ModulePrintManager.CreatePrintCommandsCollection();
	
	MetadataObjectForm = Metadata.FindByFullName(FormName);
	MetadataObject = Undefined;
	
	If MetadataObjectForm = Undefined Then
		NameParts = StrSplit(FormName, ".", False);
		If NameParts.Count() > 1 Then
			MetadataObject = Metadata.FindByFullName(StrTemplate("%1.%2", NameParts[0], NameParts[1]));
			If MetadataObject <> Undefined Then
				MetadataObjectForm = MetadataObject.DefaultListForm;
				If MetadataObjectForm <> Undefined Then
					FormName = MetadataObjectForm.FullName();
				EndIf;
			EndIf;
		EndIf;
	ElsIf Not Metadata.CommonForms.Contains(MetadataObjectForm) Then
		MetadataObject = MetadataObjectForm.Parent();
	EndIf;
	
	If MetadataObjectForm <> Undefined
			And MetadataObject <> Undefined
			And ModulePrintManager.PrintCommandsSources().Find(MetadataObject) <> Undefined Then
		CollectionOfPrintCommands = ModulePrintManager.FormPrintCommands(FormName);
		CollectionOfPrintCommands.Columns.Add("AdditionalParametersInLine");
		BeforeAddPrintCommands(FormName, CollectionOfPrintCommands, True);
		For Each PrintCommand In CollectionOfPrintCommands Do
			PrintCommand.AdditionalParametersInLine = PrintOptionsToLine(
				PrintCommand.AdditionalParameters);
		EndDo;
		CollapseFormPrintingCommands(CollectionOfPrintCommands);
	EndIf;
	
	Return CollectionOfPrintCommands;
	
EndFunction

// The constructor of the table that caches values for subsequent entry into the register
// of information about the control of sending files1 Document flow.
//
// Returns:
//  ValueTable:
//     * Source - AnyRef - a reference to the original IP object.
//     * FileName - String - the name of the printed form.
//     * SpreadsheetDocument - SpreadsheetDocument - the formed printed form.
//
Function ControlOverSendingFiles() Export
	
	ControlOverSendingFiles = New ValueTable;
	ControlOverSendingFiles.Columns.Add("Source",
		New TypeDescription(Metadata.DefinedTypes.IntegrationWith1CWorkflowAllLinksOverridable.Type));
	ControlOverSendingFiles.Columns.Add("FileName", New TypeDescription("String"));
	ControlOverSendingFiles.Columns.Add("SpreadsheetDocument", New TypeDescription("SpreadsheetDocument"));
	
	Return ControlOverSendingFiles;
	
EndFunction

// Returns a table of values with information about the object's print managers.
//
// Parameters:
//   ObjectManager - String - the full name of the metadata of the object manager.
//
// Returns:
//   ValueTable:
//     * CommandName - String - name of the print manager team.
//     * PrintManager - String - the name of the object whose manager module contains
//         the Print procedure that generates tabular documents for this command.
//     * CommandPresentation - String - representation of the print command for display on forms.
//     * AdditionalParameters - String - (optional) custom parameters to pass to the print Manager.
//
Function PrintManagers(ObjectManager) Export
	
	PrintForms = New ValueTable;
	PrintForms.Columns.Add("CommandName");
	PrintForms.Columns.Add("PrintManager");
	PrintForms.Columns.Add("CommandPresentation");
	PrintForms.Columns.Add("AdditionalParameters");
	
	FillInTableOfObjectPrintManagers(ObjectManager, PrintForms);
	
	Return PrintForms;
	
EndFunction

// Forms the parameter structure necessary to show the user the question of transferring files from the IP to the DO, and for
// further file transfer.
//
// Parameters:
//   LinkData - Structure:
//     * ID - String - ID of the document flow object.
//     * Type - String - the XDTO type of the Workflow object.
//     * Object - AnyRef - a reference to the integrated system object that owns the files.
//   AttachedVISFiles - ValueList of AnyRef - list of files in the IP that have not been transferred to the BEFORE.
//                          - Undefined - if you want to define a list of files.
//   FileCatalogType - String - the full name of the metadata of the file owner in the IP.
//   OwnerTypePresentation - String - Presentation of the file owner type in the IC.
//
// Returns:
//   Structure:
//     * NeedToAskQuestionAboutTransferringFilesToDM - Boolean - True if you need to ask a question to the user. False if
//         file transfer to BEFORE is not required.
//     * StateAllowsFileAddition - Boolean - indicates whether the user can add files to the object BEFORE,
//         in accordance with the State accessibility settings.
//     * StateAllowsAddingScannedCopy - Boolean - indicates whether the user can add scanned copies to the
//         object BEFORE, in accordance with the State availability settings.
//     * AttachedVISFiles - ValueList of AnyRef - list of files in the IP that have not been transferred to the BEFORE.
//                              - Undefined - if file transfer is not required.
//     * OwnerID - String - ID of the file owner in the Document Flow.
//     * OwnerType - String - the XDTO type of the file owner in the Document Flow.
//     * OwnerIS - AnyRef - the reference to the object is the owner of the file in the IP.
//     * FileCatalogType - String - the full name of the metadata of the file owner in the IP.
//     * OwnerTypePresentation - String - Presentation of the file owner type in the IC.
//     * AbbreviatedNameOfConfiguration - See IntegrationWith1CDocumentManagementCore.AbbreviatedNameOfConfiguration
//
Function ParametersForTransferringFilesToDM(LinkData, AttachedVISFiles = Undefined,
		FileCatalogType = "Undefined", OwnerTypePresentation = "object_") Export
	
	FileTransferOptions = New Structure;
	FileTransferOptions.Insert("NeedToAskQuestionAboutTransferringFilesToDM", False);
	FileTransferOptions.Insert("StateAllowsFileAddition", True);
	FileTransferOptions.Insert("StateAllowsAddingScannedCopy", True);
	FileTransferOptions.Insert("AttachedVISFiles", AttachedVISFiles);
	FileTransferOptions.Insert("OwnerID", LinkData.ID);
	FileTransferOptions.Insert("OwnerType", LinkData.Type);
	FileTransferOptions.Insert("OwnerIS", LinkData.Object);
	FileTransferOptions.Insert("FileCatalogType", FileCatalogType);
	FileTransferOptions.Insert("OwnerTypePresentation", OwnerTypePresentation);
	FileTransferOptions.Insert("AbbreviatedNameOfConfiguration", AbbreviatedNameOfConfiguration());
	
	Settings = IntegrationWith1CDocumentManagementCoreServerCall.UseIntegration();
	If Not Settings.UseIntegrationBefore3 Then
		// The file transfer functionality is implemented only in integration with UP to 3.
		Return FileTransferOptions;
	EndIf;
	
	If ValueIsFilled(LinkData.Object)
			And (FileCatalogType = "Undefined" Or OwnerTypePresentation = "object_") Then
		Owner_Metadata = LinkData.Object.Metadata();
		FileTransferOptions.FileCatalogType = Owner_Metadata.FullName();
		ObjectTypeArray = StrSplit(FileTransferOptions.FileCatalogType, ".");
		If ObjectTypeArray[0] = "Catalog" Then
			FileTransferOptions.OwnerTypePresentation = "catalog_";
		ElsIf ObjectTypeArray[0] = "Document" Then
			FileTransferOptions.OwnerTypePresentation = "document_";
		EndIf;
	EndIf;
	
	SettingAskQuestionAboutTransferringFilesToDM =
		IntegrationWith1CDocumentManagementCoreCached.SettingAskQuestionAboutTransferringFilesToDM(
			FileTransferOptions.FileCatalogType);
	If SettingAskQuestionAboutTransferringFilesToDM = False Then
		// Personal user settings.
		Return FileTransferOptions;
	EndIf;
	
	If Not IntegrationWith1CDocumentManagementCoreServerCall.Use1CDocumentManagementAttachedFilesForTheObject(
			LinkData.Object) Then
		// The functionality of storing files in the DO is not used.
		Return FileTransferOptions;
	EndIf;
	
	AllAttachedVISFiles = AttachedVISFiles(LinkData.Object);
	If AllAttachedVISFiles.Count() = 0 Then
		// There are no files to transfer to BEFORE.
		Return FileTransferOptions;
	EndIf;
	
	If FileTransferOptions.AttachedVISFiles = Undefined Then
		ListOfFilesBefore = New Array;
		If ValueIsFilled(LinkData.ID) Then
			Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
			XDTODataObject = GetObject(
				Proxy,
				LinkData.Type,
				LinkData.ID,
				"files,enabledProperties");
			FillInPPEOfXDTOObject(FileTransferOptions, XDTODataObject);
			If PropertySet(XDTODataObject, "files") Then
				ListOfFilesBefore = XDTODataObject.files;
			EndIf;
		EndIf;
		FillInNonTransferredToDMAttachedFilesToIS(
			FileTransferOptions.AttachedVISFiles,
			AllAttachedVISFiles,
			ListOfFilesBefore);
	EndIf;
	
	FileTransferOptions.NeedToAskQuestionAboutTransferringFilesToDM =
		(FileTransferOptions.AttachedVISFiles.Count() > 0);
	
	Return FileTransferOptions;
	
EndFunction

// Converts the structure of additional parameters of the printed Form into a string.
//
// Parameters:
//   PrintParameters - Structure - additional parameters of the printed Form.
//
// Returns:
//   String
//
Function PrintOptionsToLine(PrintParameters) Export
	
	StructureForProcessing = Common.CopyRecursive(PrintParameters);
	
	If StructureForProcessing.Property("IntegrationWith1CWorkflow_ParametersOfOperation") Then
		StructureForProcessing.Delete("IntegrationWith1CWorkflow_ParametersOfOperation");
	EndIf;
	
	Try
		AdditionalParametersInLine = Common.ValueToJSON(StructureForProcessing);
	Except
		AdditionalParametersInLine = "";
	EndTry;
	
	Return AdditionalParametersInLine;
	
EndFunction

// Generates parameters for creating object files UP to from printed forms of the IC object.
//
// Parameters:
//   Source - AnyRef - a reference to the original IP object.
//   AttachedPrintedForms - See IntegrationWith1CDocumentManagementCore.AttachedPrintedForms
//   TypeOfSavedPrintedFormFile - EnumRef.TypesOfSavedPrintedFormFileOfObjects - the type of file
//     in which the printed form is saved.
//   ControlOverSendingFiles - See IntegrationWith1CDocumentManagementCore.ControlOverSendingFiles
//   UpdateOnly - Boolean - True if only updating existing forms is performed.
//   FormUniqueID - UUID - ID of the calling form.
//
// Returns:
//   Array of See IntegrationWith1CDocumentManagementCoreClientServer.NewFileCreationOptions
//
Function PrintedFormsToCreate(Source, AttachedPrintedForms, TypeOfSavedPrintedFormFile,
		ControlOverSendingFiles = Undefined, UpdateOnly = False, FormUniqueID = Undefined) Export
	
	Result = New Array;
	
	SourceMetadata = Source.Metadata();
	
	FormPrintCommands = FormPrintCommands(StrTemplate("%1.Form.ListForm", SourceMetadata.FullName()));
	
	LinesToDelete = New Array;
	For Each String In AttachedPrintedForms Do
		Filter = New Structure("Id, PrintManager",
			String.CommandName,
			String.PrintManager);
		If ValueIsFilled(String.AdditionalParameters) Then
			Filter.Insert("AdditionalParametersInLine", String.AdditionalParameters);
		EndIf;
		PrintCommandLines = FormPrintCommands.FindRows(Filter);
		If PrintCommandLines.Count() > 0 Then
			CommandIndex = FormPrintCommands.IndexOf(PrintCommandLines[0]);
			String.CommandName = StrTemplate("PrintCommand%1", Format(CommandIndex, "NZ=0; NG=0"));
			String.CommandPresentation = PrintCommandLines[0].Presentation;
		Else
			// There is no such printed form in the IP object.
			LinesToDelete.Add(String);
			Continue;
		EndIf;
		If UpdateOnly And (Not String.ShouldUpdate) Then
			LinesToDelete.Add(String);
		EndIf;
	EndDo;
	
	For Each String In LinesToDelete Do
		AttachedPrintedForms.Delete(String);
	EndDo;
	
	PrintForms = AttachedPrintedForms.Copy();
	AttachedPrintedForms.GroupBy("PrintManager");
	PrintManagers = AttachedPrintedForms.UnloadColumn("PrintManager");
	
	FileFormat_ = Common.EnumerationValueName(TypeOfSavedPrintedFormFile);
	Extension = ExpansionOfSavedPrintedForm(TypeOfSavedPrintedFormFile);
	
	For Each PrintManager In PrintManagers Do
		
		ManagerTemplates = PrintForms.FindRows(New Structure("PrintManager", PrintManager));
		
		For Each ManagerSTeam In ManagerTemplates Do
			
			TableOfPrintedForms = New ValueTable;
			
			FillInCollectionOfPrintedForms(
				Source,
				ManagerSTeam.CommandName,
				ManagerSTeam.AdditionalParameters,
				TableOfPrintedForms);
			
			For Each PrintForm In TableOfPrintedForms Do
				If PrintForm.SpreadsheetDocument = Undefined
						Or PrintForm.SpreadsheetDocument.PageCount() = 0 Then
					Continue;
				EndIf;
				
				TempFileName = GetTempFileName();
				
				FileName = NameOfPrintForm(
					Source,
					ManagerSTeam.CommandPresentation,
					PrintForm.TemplateSynonym,
					PrintForm.TemplateName);
				
				If UpdateOnly
						And InformationRegisters.ControlOverSendingFilesTo1CDocumentManagement.FileHasAlreadyBeenSent(
							Source, FileName, PrintForm.SpreadsheetDocument) Then
					Continue;
				ElsIf ControlOverSendingFiles <> Undefined Then
					NewRow = ControlOverSendingFiles.Add();
					NewRow.Source = Source;
					NewRow.FileName = FileName;
					NewRow.SpreadsheetDocument = PrintForm.SpreadsheetDocument;
				Else
					InformationRegisters.ControlOverSendingFilesTo1CDocumentManagement.SaveHashSumOfFileVersion(
						Source,
						FileName,
						PrintForm.SpreadsheetDocument);
				EndIf;
				
				PrintForm.SpreadsheetDocument.Write(
					TempFileName,
					SpreadsheetDocumentFileType[FileFormat_]);
				File = New File(TempFileName);
				
				CurrentFile = IntegrationWith1CDocumentManagementCoreClientServer.FileData(
					FileName,
					Undefined,
					"DMFile",
					Extension,
					ManagerSTeam.FileRoleID);
				CurrentFile.Size = File.Size();
				CurrentFile.ModificationDate = File.GetModificationTime();
				CurrentFile.UniversalModificationDate = File.GetModificationUniversalTime();
				
				FileCreationParameters =
					IntegrationWith1CDocumentManagementCoreClientServer.NewFileCreationOptions(CurrentFile);
				FileCreationParameters.TempFileStorageAddress = PutToTempStorage(
					New BinaryData(TempFileName),
					FormUniqueID);
				FileCreationParameters.Owner = Source;
				
				Result.Add(FileCreationParameters);
				
				File = Undefined;
				DeleteFiles(TempFileName);
				
			EndDo;
			
		EndDo;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Called when determining the presence of files stored in the integrated configuration.
//
// Parameters:
//   FilesOwner - Arbitrary - the object is the owner.
//   HasFiles - Boolean, Undefined - an implicitly returned value, a sign of the presence of attached files.
//
Procedure WhenDeterminingPresenceOfAttachedFiles(FilesOwner, HasFiles) Export
	
	StandardProcessing = True;
	
	IntegrationWith1CDocumentManagementCoreOverridable.WhenDeterminingPresenceOfAttachedFiles(
		FilesOwner, HasFiles, StandardProcessing);
	
	If StandardProcessing = False Then
		Return;
	EndIf;
	
	HasFiles = (AttachedVISFiles(FilesOwner).Count() > 0);
	
EndProcedure

// Returns a list of attached files stored in the IP.
//
// Parameters:
//   FilesOwner - Arbitrary - the object is the owner.
//
// Returns:
//   Array of AnyRef - list of links to attached files.
//
Function AttachedVISFiles(FilesOwner) Export
	
	Result = New Array;
	
	If Not Common.SubsystemExists("StandardSubsystems.FilesOperations") Then
		Return Result;
	EndIf;
	
	FilesStorageCatalogName = "";
	ModuleFilesOperations = Common.CommonModule("FilesOperations");
	Try
		ModuleFilesOperations.NewRefToFile(FilesOwner, FilesStorageCatalogName);
	Except
		FilesStorageCatalogName = "";
	EndTry;
	If Not ValueIsFilled(FilesStorageCatalogName) Then
		Return Result;
	EndIf;
	
	Query = New Query(
		"SELECT
		|	Files.Ref AS Ref
		|FROM
		|	&FilesStorageCatalogName AS Files
		|WHERE
		|	Files.FileOwner = &FilesOwner
		|	AND NOT Files.DeletionMark");
	Query.Text = StrReplace(
		Query.Text,
		"&FilesStorageCatalogName",
		StrTemplate("Catalog.%1", FilesStorageCatalogName));
	Query.SetParameter("FilesOwner", FilesOwner);
	
	If Metadata.Catalogs[FilesStorageCatalogName].Hierarchical Then
		Query.Text = Query.Text + " AND NOT Files.IsFolder";
	EndIf;
	
	SetPrivilegedMode(True);
	Result = Query.Execute().Unload().UnloadColumn("Ref");
	
	Return Result;
	
EndFunction

// Constructor of the table of values describing the attached printed forms.
//
// Returns:
//  ValueTable:
//     * CommandName - String - name of the print manager team.
//     * CommandPresentation - String - representation of the print command for display on forms.
//     * PrintManager - String - the name of the print manager as specified in the configurator.
//     * ShouldUpdate - Boolean - update the value.
//     * FileRoleID - String - ID of the role of the print form file on the DO side.
//     * AdditionalParameters - String - (optional) custom parameters to pass to the print Manager.
//
Function AttachedPrintedForms() Export
	
	AttachedPrintedForms = New ValueTable;
	AttachedPrintedForms.Columns.Add("CommandName", New TypeDescription("String"));
	AttachedPrintedForms.Columns.Add("CommandPresentation", New TypeDescription("String"));
	AttachedPrintedForms.Columns.Add("PrintManager", New TypeDescription("String"));
	AttachedPrintedForms.Columns.Add("ShouldUpdate", New TypeDescription("Boolean"));
	AttachedPrintedForms.Columns.Add("FileRoleID", New TypeDescription("String"));
	AttachedPrintedForms.Columns.Add("AdditionalParameters", New TypeDescription("String"));
	
	Return AttachedPrintedForms;
	
EndFunction

// Called when receiving attached files.
//
// Parameters:
//   FilesOwner - Arbitrary - the object is the owner.
//   FilesData - Array of See FilesOperations.FileData
//
Procedure OnReceiveAttachedFiles(FilesOwner, FilesData) Export
	
	StandardProcessing = True;
	
	IntegrationWith1CDocumentManagementCoreOverridable.OnReceiveAttachedFiles(
		FilesOwner, FilesData, StandardProcessing);
	
	If StandardProcessing = False Then
		Return;
	EndIf;
	
	If Not Common.SubsystemExists("StandardSubsystems.FilesOperations") Then
		Return;
	EndIf;
	
	Files = New Array;
	ModuleFilesOperations = Common.CommonModule("FilesOperations");
	ModuleFilesOperations.FillFilesAttachedToObject(FilesOwner, Files);
	
	For Each File In Files Do
		FileData = ModuleFilesOperations.FileData(File, Undefined, True, False);
		FilesData.Add(FileData);
	EndDo;
	
EndProcedure

// Sets the indication of the presence of attached files UP to for the IC object. It is called when adding
// a link to a DO object that has files, when adding a file from the IC interface, and when updating in the background.
//
// Parameters:
//   ID - String - ID of the document flow object.
//   Type - String - XDTO is the type of Document flow object.
//   ObjectIS - DefinedType.AttachedFilesOwner - the IP object.
//   WhetherFilesAreAttached - Boolean - True if there are attached files in the DO.
//
Procedure OnAdd1CDocumentManagementAttachedFiles(ID, Type, ObjectIS,
		WhetherFilesAreAttached = Undefined) Export
	
	StandardProcessing = True;
	
	IntegrationWith1CDocumentManagementCoreOverridable.OnAdd1CDocumentManagementAttachedFiles(
		ID, Type, ObjectIS, StandardProcessing);
	
	If StandardProcessing = False Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(ObjectIS) Then
		Return;
	EndIf;
	
	If Not Common.SubsystemExists("StandardSubsystems.FilesOperations")
			Or Not UseAttachedFiles1CDocumentManagement() Then
		Return;
	EndIf;
	
	AttachedFilesOwner = Metadata.DefinedTypes.Find("AttachedFilesOwner");
	If AttachedFilesOwner = Undefined
			Or Not AttachedFilesOwner.Type.ContainsType(TypeOf(ObjectIS)) Then
		Return;
	EndIf;
	
	If WhetherFilesAreAttached = Undefined Then
		
		Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
		If Not ObjectDoesNotSupportFiles(Proxy, Type) Then
			// A DO object cannot have attached files.
			Return;
		EndIf;
		
		// The presence of attached files in the DO is not known in advance. Get the number of files in BEFORE the request.
		FilesCountBefore = NumberOfAssociatedObjectFiles(ID, Type);
		If FilesCountBefore = Undefined Or FilesCountBefore = 0 Then
			Return;
		EndIf;
		
	ElsIf WhetherFilesAreAttached = False Then
		
		// The presence of attached files in the DO is known in advance. There are no files.
		Return;
		
	EndIf;
	
	SetPrivilegedMode(True);
	
	FileAvailabilityModule = Common.CommonModule("InformationRegisters.FilesExist");
	RecordManager = FileAvailabilityModule.CreateRecordManager();
	RecordManager.ObjectWithFiles = ObjectIS;
	RecordManager.Read();
	
	If Not ValueIsFilled(RecordManager.ObjectWithFiles) Then
		RecordManager.ObjectWithFiles = ObjectIS;
	EndIf;
	
	If Not RecordManager.HasFiles Then
		RecordManager.HasFiles = True;
	EndIf;
	
	If IsBlankString(RecordManager.ObjectID) Then
		RecordManager.ObjectID = "0000000000";
	EndIf;
	
	If RecordManager.Modified() Then
		RecordManager.Write();
	EndIf;
	
EndProcedure

// Removes the indication of the presence of attached files for the IC object, if they are not in the IC itself. Called when
// the link to the object is removed BEFORE and during background updates.
//
// Parameters:
//   ID - String - ID of the document flow object.
//   Type - String - XDTO is the type of Document flow object.
//   ObjectIS - DefinedType.AttachedFilesOwner - the IP object.
//
Procedure OnRemove1CDocumentManagementAttachedFiles(ID, Type, ObjectIS) Export
	
	StandardProcessing = True;
	
	IntegrationWith1CDocumentManagementCoreOverridable.OnRemove1CDocumentManagementAttachedFiles(
		ID, Type, ObjectIS, StandardProcessing);
	
	If StandardProcessing = False Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(ObjectIS) Then
		Return;
	EndIf;
	
	If Not Common.SubsystemExists("StandardSubsystems.FilesOperations")
			Or Not UseAttachedFiles1CDocumentManagement() Then
		Return;
	EndIf;
	
	AttachedFilesOwner = Metadata.DefinedTypes.Find("AttachedFilesOwner");
	If Not AttachedFilesOwner.Type.ContainsType(TypeOf(ObjectIS)) Then
		Return;
	EndIf;
	
	FilesArray = New Array;
	ModuleFilesOperations = Common.CommonModule("FilesOperations");
	ModuleFilesOperations.FillFilesAttachedToObject(ObjectIS, FilesArray);
	
	If FilesArray.Count() <> 0 Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	// Delete the entry.
	FileAvailabilityModule = Common.CommonModule("InformationRegisters.FilesExist");
	RecordManager = FileAvailabilityModule.CreateRecordManager();
	RecordManager.ObjectWithFiles = ObjectIS;
	RecordManager.Read();
	If RecordManager.Selected() Then
		RecordManager.HasFiles = False;
		RecordManager.Write();
	EndIf;
	
EndProcedure

// Returns the extension by the file type of the printed form being saved.
//
// Parameters:
//   FileType - EnumRef.TypesOfSavedPrintedFormFileOfObjects - the type of file being saved.
//
// Returns:
//   String - file extension.
//
Function ExpansionOfSavedPrintedForm(FileType) Export
	
	If FileType = PredefinedValue("Enum.TypesOfSavedPrintedFormFileOfObjects.PDF_A_1") Then
		Return "pdf";
		
	ElsIf ValueIsFilled(FileType) And Common.RefExists(FileType) Then
		Return Lower(Common.EnumerationValueName(FileType));
		
	Else
		Return "";
		
	EndIf
	
EndFunction

// Returns a request to create a file in the Workflow.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   XDTOFile - XDTODataObject - An XDTO object of the DMFile type.
//   OwnerID - String - ID of the file owner in the Document Flow.
//   OwnerType - String - the type of the file owner in the Document Flow.
//   OwnerPresentation - String - representation of the file owner in the Document Flow.
//
// Returns:
//   XDTODataObject - an XDTO object of the DMAddFileRequest type.
//
Function CreateRequestFile(Proxy, XDTOFile, OwnerID, OwnerType, OwnerPresentation = "") Export
	
	Query = CreateObject(Proxy, "DMAddFileRequest");
	
	OwnerObject = CreateObject(Proxy, "DMObject");
	OwnerObject.objectID = CreateObjectID(Proxy, OwnerID, OwnerType);
	OwnerObject.name = OwnerPresentation;
	
	Query.owner = OwnerObject;
	
	Query.file = XDTOFile;
	
	Return Query;
	
EndFunction

// Returns the default file type of the printable form being saved.
//
// Returns:
//   EnumRef.TypesOfSavedPrintedFormFileOfObjects - the default type.
//
Function DefaultFileTypeOfSavedPrintedForm() Export
	
	Return Enums.TypesOfSavedPrintedFormFileOfObjects.PDF_A_1;
	
EndFunction

// Creates and fills in an XDTO object of the DMFile type based on data from the creation parameters.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   CreationParameters - Structure - IntegrationWith1CDocumentManagementCoreClientServer.NewFileCreationOptions
//
// Returns:
//   XDTODataObject - An XDTO object of the DMFile type.
//
Function XDTOFileFromCreationParameters(Proxy, CreationParameters) Export
	
	XDTOFile = CreateObject(Proxy, "DMFile");
	XDTOFile.objectID = CreateObjectID(Proxy, "", "DMFile");
	
	If ValueIsFilled(CreationParameters.ExternalObject.ID) Then
		XDTOFile.externalObject = CreateExternalObject(
			Proxy,,
			CreationParameters.ExternalObject.ID,
			CreationParameters.ExternalObject.type,
			CreationParameters.ExternalObject.name);
	EndIf;
	
	XDTOFile.name = CreationParameters.CurrentFile.Description;
	XDTOFile.description = CreationParameters.CurrentFile.LongDesc;
	XDTOFile.extension = CreationParameters.CurrentFile.Extension;
	
	If ValueIsFilled(CreationParameters.TempFileStorageAddress) Then
		
		XDTOFile.modificationDate = CreationParameters.CurrentFile.ModificationDate;
		XDTOFile.modificationDateUniversal = CreationParameters.CurrentFile.UniversalModificationDate;
		XDTOFile.size = CreationParameters.CurrentFile.Size;
		XDTOFile.scannedOriginal = CreationParameters.IsScannedCopy;
		
		XDTOFile.binaryData = GetFromTempStorage(CreationParameters.TempFileStorageAddress);
		IntegrationWith1CDocumentManagementCoreClientServer.FileSizeExceedsMaximumAllowed(
			IntegrationWith1CDocumentManagementCoreServerCall.MaximumFileSize_(),
			XDTOFile.binaryData.Size(),
			CreationParameters.CurrentFile.Description);
		
	ElsIf ValueIsFilled(CreationParameters.TemplateID) Then
		
		TemplateFile_ = CreateObject(Proxy, "DMFile");
		TemplateFile_.objectID = CreateObjectID(Proxy, CreationParameters.TemplateID, "DMFile");
		TemplateFile_.name = CreationParameters.CurrentFile.Description;
		
		XDTOFile.template = TemplateFile_;
		
	EndIf;
	
	If Not IsBlankString(CreationParameters.CurrentFile.Text) Then
		XDTOFile.text = CreationParameters.CurrentFile.Text;
	EndIf;
	
	If ValueIsFilled(CreationParameters.CurrentFile.FileRoleID) And PropertyExists(XDTOFile, "role") Then
		XDTOFile.role = CreateObject(Proxy, "DMFileRole");
		XDTOFile.role.name = "";
		XDTOFile.role.objectID = CreateObjectID(Proxy, CreationParameters.CurrentFile.FileRoleID, "DMFileRole");
	EndIf;
	
	Return XDTOFile;
	
EndFunction

#EndRegion

#Region ProcessesAndTasks_

// Fills in the XDTO object describing the full role.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   FullXDTORole - XDTODataObject - an XDTO object of the DMCompleteRole type.
//   Role - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//   MainAddressingObject - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//   AdditionalAddressingObject - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//
Procedure FillInFullRole(Proxy, FullXDTORole, Role, MainAddressingObject = Undefined,
		AdditionalAddressingObject = Undefined) Export
	
	FullXDTORole.role = CreateObject(Proxy, "DMBusinessProcessExecutorRole");
	FullXDTORole.role.name = Role.Description;
	FullXDTORole.role.objectID = CreateObjectID(Proxy, Role.ID, Role.Type);
	
	If ValueIsFilled(MainAddressingObject) Then
		FullXDTORole.mainAddressingObject = CreateObject(Proxy, "DMMainAddressingObject");
		FullXDTORole.mainAddressingObject.name = MainAddressingObject.Description;
		FullXDTORole.mainAddressingObject.objectID =
			CreateObjectID(Proxy, MainAddressingObject.ID, MainAddressingObject.Type);
	EndIf;
	
	If ValueIsFilled(AdditionalAddressingObject) Then
		FullXDTORole.secondaryAddressingObject = CreateObject(Proxy, "DMSecondaryAddressingObject");
		FullXDTORole.secondaryAddressingObject.name = AdditionalAddressingObject.Description;
		FullXDTORole.secondaryAddressingObject.objectID =
			CreateObjectID(Proxy, AdditionalAddressingObject.ID, AdditionalAddressingObject.Type);
	EndIf;
	
EndProcedure

// Generates an XDTO object describing the task participant.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   Performer - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//   MainAddressingObject - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//   AdditionalAddressingObject - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//
// Returns:
//   XDTODataObject - An XDTO object of the DMTaskParticipant type.
//
Function TaskParticipant(Proxy, Performer, MainAddressingObject = Undefined,
		AdditionalAddressingObject = Undefined) Export
	
	Settings = IntegrationWith1CDocumentManagementCoreServerCall.UseIntegration();
	
	If Settings.UseIntegrationBefore2 Then
		ModuleIntegrationWith1CDocumentManagement = Common.CommonModule("IntegrationWith1CDocumentManagement");
		TaskParticipant = ModuleIntegrationWith1CDocumentManagement.TaskParticipant(
			Proxy,
			Performer,
			MainAddressingObject,
			AdditionalAddressingObject);
	ElsIf Settings.UseIntegrationBefore3 Then
		ModuleIntegrationWith1CDocumentManagement3 = Common.CommonModule("IntegrationWith1CDocumentManagement3");
		TaskParticipant = ModuleIntegrationWith1CDocumentManagement3.MemberOfXDTOTasks(
			Proxy,
			Performer,
			MainAddressingObject,
			AdditionalAddressingObject);
	EndIf;
	
	Return TaskParticipant;
	
EndFunction

#EndRegion

#Region AuthorizationViaJWTTokens

// returns the uri of the 1C web service namespace:Document flow.
//
// Returns:
//   String
//
Function URIOfNamespaceOfWorkflowWebService() Export
	
	Return "http://www.1c.ru/dm";
	
EndFunction

// returns the name of the 1C web service:Document flow.
//
// Returns:
//   String
//
Function NameOfDocumentManagementWebService() Export
	
	Return "DMService";
	
EndFunction

// Returns the user mapping key that will be passed to the access token.
// the key depends on the Cur settings, it can be the username of the ib user or the FA user.
//
// Returns:
//   String
//
Function AccessTokenUserMappingKey() Export
	
	UserMatchingKey = "";
	
	CurrentIBUser = InfoBaseUsers.CurrentUser();
	Var_Key = Constants.KeyToMapUsers1CDocumentManagement.Get();
	If Var_Key = Enums.KeysToMapUsers1CDocumentManagement.IBUserName Then
		UserMatchingKey = CurrentIBUser.Name;
	ElsIf Var_Key = Enums.KeysToMapUsers1CDocumentManagement.OSUser Then
		UserMatchingKey = StrReplace(CurrentIBUser.OSUser, "\\", "");
	ElsIf Var_Key = Enums.KeysToMapUsers1CDocumentManagement.Email Then
		UserMatchingKey = CurrentIBUser.Email;
	EndIf;
	
	Return UserMatchingKey;
	
EndFunction

// Returns the parameter structure required to generate the access token.
//
// Returns:
//   Structure:
//     * Issuer - String
//     * CreationTime - Number
//     * LifeTime - Number
//     * Id - UUID
//     * Recipients - Array of String
//     * UserMatchingKey - String
//
Function AccessTokenParameters() Export
	
	// The time on the server BEFORE and after may vary. if the time of token creation received on the ip server
	// is longer than the Cur time on the pre-authorization server will not take place. To exclude small
	// time deviations, set the offset to 1 minute.
	TimeOffset = 60;
	
	Parameters = New Structure;
	Parameters.Insert("Issuer", IssuerOfAccessToken());
	Parameters.Insert("CreationTime", Number(CurrentUniversalDate() - Date(1970, 1, 1, 0, 0, 0) - TimeOffset));
	Parameters.Insert("LifeTime",
		IntegrationWith1CDocumentManagementCoreServerCall.LifetimeOfAccessToken() + TimeOffset);
	Parameters.Insert("Id", New UUID);
	Parameters.Insert("Recipients", RecipientsOfAccessToken());
	Parameters.Insert("UserMatchingKey", AccessTokenUserMappingKey());
	
	Return Parameters;
	
EndFunction

// Returns an array of recipients required to generate an access token.
//
// Returns:
//   Array of String
//
Function RecipientsOfAccessToken() Export
	
	ArrayOfRecipients_ = New Array;
	ArrayOfRecipients_.Add("dmil");
	
	Return ArrayOfRecipients_;
	
EndFunction

// returns the alias of the 1C web service:Document flow.
//
// Returns:
//   String
//
Function AliasOfDocumentManagementWebService() Export
	
	Return "dm.1cws";
	
EndFunction

// Generates a text Presentation of the JWT token for authentication in the Document Management web service.
//
// Returns:
//   String
//
Function TextOfAccessToken() Export
	
	TextOfAccessToken = "";
	IntegrationWith1CDocumentManagementCoreOverridable.WhenReceivingAccessToken(TextOfAccessToken);
	
	If TextOfAccessToken = "" And AccessTokenUserMappingKey() <> "" Then
		AccessToken = New AccessToken;
		FillPropertyValues(AccessToken, AccessTokenParameters());
		TokenSigningKey = Constants.AccessTokenSignatureKey1CDocumentManagement.Get();
		AccessToken.Sign(AccessTokenSignAlgorithm.HS256, TokenSigningKey);
		TextOfAccessToken = String(AccessToken);
	EndIf;
	
	Return TextOfAccessToken;
	
EndFunction

// Returns the issuer required to generate the access token.
//
// Returns:
//   String
//
Function IssuerOfAccessToken() Export
	
	Return "ssl";
	
EndFunction

#EndRegion

#Region DigitalSignatures

// Converts the signature table on the form into an array of structured signature data.
//
// Parameters:
//   SignatureTable - See IntegrationWith1CDocumentManagementCoreClientServer.StructureOfSignatureTreeString
//
// Returns:
//   Array of See IntegrationWith1CDocumentManagementCoreClientServer.SignatureData
//
Function DataOfSignatures(SignatureTable) Export
	
	ArrayOfSignatureData = New Array; // signatures left after deletion
	
	// forming an array of signature data.
	For Each RowData In SignatureTable Do
		
		CertificateBinaryData = Undefined;
		If ValueIsFilled(RowData.CertificateAddress) Then
			CertificateBinaryData = GetFromTempStorage(RowData.CertificateAddress);
		EndIf;
		SignatureData = SignatureData(
			GetFromTempStorage(RowData.SignatureAddress),
			CertificateBinaryData,
			RowData);
		ArrayOfSignatureData.Add(SignatureData);
		
	EndDo;
	
	Return ArrayOfSignatureData;
	
EndFunction

// Returns the data from which the XDTO DMSignature object will be generated for transmission to the DO.
//
// Parameters:
//   Signature - BinaryData - binary signature data.
//   CertificateBinaryData - BinaryData - binary data of the certificate.
//   SignatureProperties - Structure - There may be either a signature property structure that the BSP returns when
//     adding a new signature, or a signature table row if it is already an existing signature on the side BEFORE.
//
// Returns:
//   See IntegrationWith1CDocumentManagementCoreClientServer.SignatureData
//
Function SignatureData(Signature, CertificateBinaryData, SignatureProperties) Export
	
	SignatureData = IntegrationWith1CDocumentManagementCoreClientServer.SignatureData(
		Signature,
		CertificateBinaryData,
		SignatureProperties);
	SignatureData.Certificate = New ValueStorage(CertificateBinaryData);
	
	Return SignatureData;
	
EndFunction

// Fills in the signature data structure for the XDTO object.
//
// Parameters:
//   XDTOSignature - XDTODataObject - the XDTO object of the signature, type DMSignature.
//
// Returns:
//   See IntegrationWith1CDocumentManagementCoreClientServer.StructureOfSignature
//
Function SignatureDataFromXDTO(XDTOSignature) Export
	
	SignatureData = IntegrationWith1CDocumentManagementCoreClientServer.StructureOfSignature();
	
	SignatureData.Signature = XDTOSignature.signature;
	SignatureData.CertificateBinaryData = XDTOSignature.certificate;
	SignatureData.Certificate = New ValueStorage(XDTOSignature.certificate);
	
	SignatureData.CertificateOwner = XDTOSignature.author;
	SignatureData.SignatureDate = XDTOSignature.date;
	SignatureData.Comment = XDTOSignature.comment;
	SignatureData.Thumbprint = XDTOSignature.thumbprint;
	SignatureData.SignatureFileName = XDTOSignature.signatureFileName;
	SignatureData.SignatureSetBy = XDTOSignature.signer.name;
	SignatureData.SignatureSetByID = XDTOSignature.signer.objectID.ID;
	
	If PropertySet(XDTOSignature, "signatureType") Then
		SignatureData.SignatureType = XDTOSignature.signatureType;
	EndIf;
	
	Return SignatureData;
	
EndFunction

// Fills in the XDTO signature object according to the signature structure.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   XDTOSignature - XDTODataObject - an XDTO object of type DMSignature.
//   SignatureData - See IntegrationWith1CDocumentManagementCoreClientServer.SignatureData
//
Procedure FillOutXDTOSignature(Proxy, XDTOSignature, SignatureData) Export
	
	XDTOSignature.signature = SignatureData.Signature;
	XDTOSignature.certificate = SignatureData.CertificateBinaryData;
	
	XDTOSignature.author = SignatureData.CertificateOwner;
	XDTOSignature.comment = SignatureData.Comment;
	XDTOSignature.date = ?(ValueIsFilled(SignatureData.SignatureDate),
		SignatureData.SignatureDate,
		CurrentSessionDate());
	XDTOSignature.signatureFileName = SignatureData.SignatureFileName;
	XDTOSignature.thumbprint = SignatureData.Thumbprint;
	
	If SignatureData.Property("SignatureSetBy") Then
		XDTOSignature.signer = CreateObject(Proxy, "DMUser");
		XDTOSignature.signer.name = SignatureData.SignatureSetBy;
		XDTOSignature.signer.objectID = CreateObjectID(Proxy, SignatureData.SignatureSetByID, "DMUser");
	EndIf;
	
	If PropertyExists(XDTOSignature, "signatureType") And ValueIsFilled(SignatureData.SignatureType) Then
		XDTOSignature.signatureType = SignatureData.SignatureType;
	EndIf;
	
EndProcedure

// Fills in the list of 1C object signatures:Workflow and its subordinate files.
//
// Parameters:
//   ObjectDocumentManagement - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//   ObjectSignatures - XDTOList - the list of signatures of the document flow document.
//   ObjectFiles - XDTOList - a list of workflow document files.
//   SignatureTree - FormDataTree - See IntegrationWith1CDocumentManagementCoreClientServer.StructureOfSignatureTreeString
//   NumberOfItemInstances - Number - the number of ECS to display in the page header.
//   FormUniqueID - UUID - ID of the calling form.
//
Procedure FillSignatureList(ObjectDocumentManagement, ObjectSignatures, ObjectFiles, SignatureTree, NumberOfItemInstances,
		FormUniqueID) Export
	
	ObjectsSignatures = New Map;
	
	// Add the signatures of the document itself.
	SignaturesArray = New Array;
	For Each XDTOSignature In ObjectSignatures Do
		SignaturesArray.Add(SignatureDataFromXDTO(XDTOSignature));
	EndDo;
	IntegrationWith1CDocumentManagementCoreClientServer.AddObjectCaptions(
		ObjectsSignatures,
		ObjectDocumentManagement.Description,
		ObjectDocumentManagement.ID,
		ObjectDocumentManagement.Type,
		False,
		SignaturesArray);
	
	// Add the signatures of the document files.
	For Each File In ObjectFiles Do
		SignaturesArray = New Array;
		For Each XDTOSignature In File.signatures Do
			SignaturesArray.Add(SignatureDataFromXDTO(XDTOSignature));
		EndDo;
		IntegrationWith1CDocumentManagementCoreClientServer.AddObjectCaptions(
			ObjectsSignatures,
			File.name,
			File.objectID.ID,
			File.objectID.type,
			File.encrypted,
			SignaturesArray);
	EndDo;
	
	NumberOfItemInstances = 0;
	LineNumber = 0;
	
	SignatureTree.GetItems().Clear();
	TreeItems = SignatureTree.GetItems(); // FormDataTreeItemCollection
	
	// We will display the signatures of the document on the form.
	For Each MapItem In ObjectsSignatures Do
		
		SignatureOwnerSDetails = MapItem.Value; // See IntegrationWith1CDocumentManagementCoreClientServer.SignatureOwnerSDetails
		
		If SignatureOwnerSDetails.Type <> "DMFile" And SignatureOwnerSDetails.SignaturesArray.Count() <> 0 Then
			NewSignatureOwnerLine = TreeItems.Add();
			
			NewSignatureOwnerLine.CertificateOwner = CertificateOwner(SignatureOwnerSDetails);
			If NewSignatureOwnerLine.Property("WhoReceivedCertificateAndStatus") Then
				NewSignatureOwnerLine.WhoReceivedCertificateAndStatus = NewSignatureOwnerLine.CertificateOwner;
			EndIf;
			NewSignatureOwnerLine.Object = ObjectDocumentManagement.Description;
			NewSignatureOwnerLine.Object_Name = ObjectDocumentManagement.Description;
			NewSignatureOwnerLine.ObjectID = ObjectDocumentManagement.ID;
			NewSignatureOwnerLine.ObjectType = ObjectDocumentManagement.Type;
			
			NewLineOfOwnerOfSignatureElements = NewSignatureOwnerLine.GetItems();
			
			For Each Signature In SignatureOwnerSDetails.SignaturesArray Do
				FillInSignatureTreeLine(
					NewLineOfOwnerOfSignatureElements.Add(),
					LineNumber,
					Signature,
					SignatureOwnerSDetails,
					FormUniqueID);
				LineNumber = LineNumber + 1;
				NumberOfItemInstances = NumberOfItemInstances + 1;
			EndDo;
		EndIf;
		
	EndDo;
	
	// We will display the signatures of the document files on the form.
	For Each MapItem In ObjectsSignatures Do
		
		SignatureOwnerSDetails = MapItem.Value; // See IntegrationWith1CDocumentManagementCoreClientServer.SignatureOwnerSDetails
		
		If SignatureOwnerSDetails.Type = "DMFile" And SignatureOwnerSDetails.SignaturesArray.Count() <> 0 Then
			NewSignatureOwnerLine = TreeItems.Add();
			
			NewSignatureOwnerLine.CertificateOwner = CertificateOwner(SignatureOwnerSDetails);
			If NewSignatureOwnerLine.Property("WhoReceivedCertificateAndStatus") Then
				NewSignatureOwnerLine.WhoReceivedCertificateAndStatus = NewSignatureOwnerLine.CertificateOwner;
			EndIf;
			
			NewSignatureOwnerLine.Object = SignatureOwnerSDetails.Description;
			NewSignatureOwnerLine.Object_Name = SignatureOwnerSDetails.Description;
			NewSignatureOwnerLine.ObjectID = SignatureOwnerSDetails.ID;
			NewSignatureOwnerLine.ObjectType = SignatureOwnerSDetails.Type;
			
			NewLineOfOwnerOfSignatureElements = NewSignatureOwnerLine.GetItems();
			
			For Each Signature In SignatureOwnerSDetails.SignaturesArray Do
				FillInSignatureTreeLine(
					NewLineOfOwnerOfSignatureElements.Add(),
					LineNumber,
					Signature,
					SignatureOwnerSDetails,
					FormUniqueID);
				LineNumber = LineNumber + 1;
				NumberOfItemInstances = NumberOfItemInstances + 1;
			EndDo;
		EndIf;
		
	EndDo;
	
EndProcedure

// Fills in the tree line on the item instance tab in the document.
//
// Parameters:
//   NewRow - FormDataTreeItem - See IntegrationWith1CDocumentManagementCoreClientServer.StructureOfSignatureTreeString
//   LineNumber - Number - the signature number in the branch of the owner object.
//   Signature - See IntegrationWith1CDocumentManagementCoreClientServer.StructureOfSignature
//   SignatureOwnerSDetails - See IntegrationWith1CDocumentManagementCoreClientServer.SignatureOwnerSDetails
//   FormUniqueID - UUID - ID of the calling form.
//
Procedure FillInSignatureTreeLine(NewRow, LineNumber, Signature, SignatureOwnerSDetails,
		FormUniqueID) Export
	
	FillPropertyValues(NewRow, Signature);
	
	NewRow.History = False;
	NewRow.SignatureCorrect = False;
	NewRow.Status = NStr("ru = 'Не проверена';
						|vi = 'Not verified';
						|en = 'Not verified'; fa = 'Not verified';
						|it = 'Не проверена';
						|pl = 'Not verified';
						|tr = 'Kontrol edilmedi'");
	
	NewRow.LineNumber = LineNumber;
	
	NewRow.WhoReceivedCertificateAndStatus = NewRow.CertificateOwner + Chars.LF + NewRow.Status;
	//@skip-check module-nstr-camelcase
	FormatString = NStr("ru = 'ДФ=""дд.ММ.гггг ЧЧ:мм""';
						|vi = 'DF=""MM/dd/yyyy HH:mm""';
						|en = 'DF=""MM/dd/yyyy HH:mm""'; fa = 'DF=""MM/dd/yyyy HH:mm""';
						|it = 'ДФ=""дд.ММ.гггг ЧЧ:мм""';
						|pl = 'DF=""MM/dd/yyyy HH:mm""';
						|tr = 'DF=""dd.MM.yyyy HH:mm""'");
	NewRow.SignatureDateAndComment = Format(NewRow.SignatureDate, FormatString)
		+ Chars.LF + NewRow.Comment;
	
	NewRow.Encrypted = SignatureOwnerSDetails.Encrypted;
	NewRow.Object = SignatureOwnerSDetails.Description;
	NewRow.Object_Name = SignatureOwnerSDetails.Description;
	NewRow.ObjectID = SignatureOwnerSDetails.ID;
	NewRow.ObjectType = SignatureOwnerSDetails.Type;
	
	NewRow.SignatureAddress = PutToTempStorage(
		Signature.Signature,
		FormUniqueID);
	
	CertificateBinaryData = Signature.CertificateBinaryData;
	If CertificateBinaryData <> Undefined Then
		NewRow.CertificateAddress = PutToTempStorage(
			CertificateBinaryData,
			FormUniqueID);
	EndIf;
	
EndProcedure

// Updates the signature tree based on the data of the XDTO collections.
//
// Parameters:
//   XDTOFiles - XDTOList - Workflow document files.
//   Signatures - FormDataTree - signatures in the form.
//   FormUniqueID - UUID - ID of the calling form.
//
Procedure UpdateListOfFileSignatures(XDTOFiles, Signatures, FormUniqueID) Export
	
	ObjectsSignatures = New Map;
	
	// Add the signatures of the document files.
	For Each File In XDTOFiles Do
		SignaturesArray = New Array;
		For Each XDTOSignature In File.signatures Do
			SignaturesArray.Add(SignatureDataFromXDTO(XDTOSignature));
		EndDo;
		IntegrationWith1CDocumentManagementCoreClientServer.AddObjectCaptions(
			ObjectsSignatures,
			File.name,
			File.objectID.ID,
			File.objectID.type,
			File.encrypted,
			SignaturesArray);
	EndDo;
	
	TreeItems = Signatures.GetItems();
	TreeItems.Clear();
	
	For Each MapItem In ObjectsSignatures Do
		
		SignatureOwnerSDetails = MapItem.Value; // See IntegrationWith1CDocumentManagementCoreClientServer.SignatureOwnerSDetails
		
		If SignatureOwnerSDetails.Type = "DMFile" And SignatureOwnerSDetails.SignaturesArray.Count() <> 0 Then
			NewSignatureOwnerLine = TreeItems.Add();
			
			NewSignatureOwnerLine.CertificateOwner = CertificateOwner(SignatureOwnerSDetails);
			If NewSignatureOwnerLine.Property("WhoReceivedCertificateAndStatus") Then
				NewSignatureOwnerLine.WhoReceivedCertificateAndStatus = NewSignatureOwnerLine.CertificateOwner;
			EndIf;
			
			NewLineOfOwnerOfSignatureElements = NewSignatureOwnerLine.GetItems();
			LineNumber = 0;
			For Each Signature In SignatureOwnerSDetails.SignaturesArray Do
				FillInSignatureTreeLine(
					NewLineOfOwnerOfSignatureElements.Add(),
					LineNumber,
					Signature,
					SignatureOwnerSDetails,
					FormUniqueID);
				LineNumber = LineNumber + 1;
			EndDo;
		EndIf;
		
	EndDo;
	
EndProcedure

// Signs the document with an electronic signature.
//
// Parameters:
//   AddedObjectSignatures - Map of KeyAndValue:
//     * Key - String - ID of the DO object that owns the signature.
//     * Value - See IntegrationWith1CDocumentManagementCoreClientServer.SignatureOwnerSDetails
//   SignatureTree - See IntegrationWith1CDocumentManagementCoreClientServer.StructureOfSignatureTreeString
//
Procedure SignDocument(AddedObjectSignatures, SignatureTree) Export
	
	SignatureTable = IntegrationWith1CDocumentManagementCoreClientServer.SignatureTable(SignatureTree);
	
	// Adding the added signatures.
	For Each RowData In SignatureTable Do
		
		If ValueIsFilled(RowData.CertificateAddress) Then
			CertificateBinaryData = GetFromTempStorage(RowData.CertificateAddress);
		Else
			CertificateBinaryData = Undefined;
		EndIf;
		SignatureData = SignatureData(
			GetFromTempStorage(RowData.SignatureAddress),
			CertificateBinaryData,
			RowData);
		IntegrationWith1CDocumentManagementCoreClientServer.AddObjectCaptions(
			AddedObjectSignatures,
			RowData.Object_Name,
			RowData.ObjectID,
			RowData.ObjectType,
			RowData.Encrypted,
			CommonClientServer.ValueInArray(SignatureData));
		
	EndDo;
	
	IntegrationWith1CDocumentManagementCoreServerCall.EnterInformationAboutObjectSignatures(
		AddedObjectSignatures);
	
EndProcedure

// Checks signatures from the array of selected lines. If the array of selected rows is not passed, it checks all
// signatures from the signature table.
//
// Parameters:
//   CryptoManager - CryptoManager - Cryptography Manager object.
//   SignatureTable - See IntegrationWith1CDocumentManagementCoreClientServer.SignatureTable
//   SelectedSignatures - See IntegrationWith1CDocumentManagementCoreClient.SelectedSignatures
//   AddressOfObjectSBinaryData - See IntegrationWith1CDocumentManagementCoreClientServer.AddressOfObjectSBinaryData
//
Procedure VerifySignatures(CryptoManager, SignatureTable, SelectedSignatures = Undefined,
		AddressOfObjectSBinaryData = Undefined) Export
	
	MatchingObjectIDAndBinaryData = New Map;
	
	For Each RowData In SignatureTable Do
		If IntegrationWith1CDocumentManagementCoreClientServer.SignatureHighlighted(
				SelectedSignatures, RowData) Then
			VerifySingleSignature(
				RowData,
				CryptoManager,
				MatchingObjectIDAndBinaryData,
				AddressOfObjectSBinaryData);
		EndIf;
	EndDo;
	
EndProcedure

// Checks whether the integrated system can create electronic
// signatures for 1C objects:Document management.
//
// Returns:
//   Boolean
//
Function CreateDigitalSignaturesFor1CDocumentManagementObjectsUsingIntegratedSystem() Export
	
	Result = True;
	StandardProcessing = True;
	
	IntegrationWith1CDocumentManagementCoreOverridable.WhenCheckingAbilityToCreateDigitalSignaturesFor1CDocumentManagementObjectsUsingIntegratedSystem(
		Result,
		StandardProcessing);
	
	If StandardProcessing Then
		Settings = IntegrationWith1CDocumentManagementCoreServerCall.UseIntegration();
		If Settings.UseIntegrationBefore3 Then
			Result = Constants.CreateDigitalSignaturesFor1CDocumentManagementObjectsUsingIntegratedSystem.Get();
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Users

// The constructor of the structure describing the additional data of the user BEFORE associated with the user IP.
//
// Returns:
//   Structure:
//     * IBUser - String - name of the IB user.
//     * OSUser - String - the FA user's name.
//     * Email - String - email address.
//     * Node - String - ID of the BEFORE sub-asset from which this link was created.
//     * ThisIsSlaveSUBAsset - Boolean - indicates that the connection belongs to a subordinate sub-asset BEFORE.
//
Function AdditionalDataOfCommunicationOfUsersDOiIS() Export
	
	AdditionalData = New Structure;
	AdditionalData.Insert("IBUser", "");
	AdditionalData.Insert("OSUser", "");
	AdditionalData.Insert("Email", "");
	AdditionalData.Insert("Node", "");
	AdditionalData.Insert("ThisIsSlaveSUBAsset", False);
	
	Return AdditionalData;
	
EndFunction

// Gets the ID of the DO sub-asset where the IP user is guaranteed to be able to log in.
// The data is taken from the register of the object integrated with the document flow, from the user's connection to the user of the IC.
//
// Parameters:
//   IPUser - DefinedType.User - the user of the integrated system.
//
// Returns:
//   String - The ID of the sub-asset BEFORE.
//
Function SubAssetForAuthorizationOfVDO(IPUser) Export
	
	SubAssetForAuthorizationOfVDO = "";
	UserBefore = InformationRegisters.ObjectsIntegratedWith1CDocumentManagement.ObjectDataUpToExternalObject(
		IPUser);
	If ValueIsFilled(UserBefore) And TypeOf(UserBefore.AdditionalData) = Type("Structure") Then
		AdditionalDataOfCommunicationOfUsersDOiIS = UserBefore.AdditionalData; // See IntegrationWith1CDocumentManagementCore.AdditionalDataOfCommunicationOfUsersDOiIS
		If AdditionalDataOfCommunicationOfUsersDOiIS.Property("Node") Then
			SubAssetForAuthorizationOfVDO = AdditionalDataOfCommunicationOfUsersDOiIS.Node;
		EndIf;
	EndIf;
	
	Return SubAssetForAuthorizationOfVDO;
	
EndFunction

// Retrieves the name of the information security user specified by the user BEFORE associated with the IP user.
// The data is taken from the register of the object integrated with the document flow, from the user's connection to the user of the IC.
//
// Parameters:
//   IPUser - DefinedType.User - the user of the integrated system.
//
// Returns:
//   String - name of the IB user.
//
Function IBUserNameForVDOAuthorization(IPUser) Export
	
	IBUserNameForVDOAuthorization = "";
	UserBefore = InformationRegisters.ObjectsIntegratedWith1CDocumentManagement.ObjectDataUpToExternalObject(
		IPUser);
	If ValueIsFilled(UserBefore) And TypeOf(UserBefore.AdditionalData) = Type("Structure") Then
		AdditionalDataOfCommunicationOfUsersDOiIS = UserBefore.AdditionalData; // See IntegrationWith1CDocumentManagementCore.AdditionalDataOfCommunicationOfUsersDOiIS
		If AdditionalDataOfCommunicationOfUsersDOiIS.Property("IBUser") Then
			IBUserNameForVDOAuthorization = AdditionalDataOfCommunicationOfUsersDOiIS.IBUser;
		EndIf;
	EndIf;
	
	Return IBUserNameForVDOAuthorization;
	
EndFunction

#EndRegion

#Region ObsoleteProceduresAndFunctions

// Deprecated. Should be used
// integrations1documentofunctionbase functionality.The value of the Session objectpointment for filling in.
// Returns the value of the Attribute of the IP object by the value of the Attribute of the object BEFORE.
//
// Parameters:
//   XDTODataObject - XDTODataObject - the source object to match.
//   ObjectAttributeTypeIS - Type - the type of the IP object's details to be filled in.
//   AttributeNameObjectIS - String - name of the IP object Attribute to be filled in.
//   TypeOfIPObjectToFillIn - Type - the type of the IP object to be filled in.
//   ObjectToFillInIS - Arbitrary - the IS object to be filled in.
//   IsAdditionalAttributeIS - Boolean - true if the Attribute of the IP object to be filled in is an additional one. a property.
//   AdditionalAttributeIS - ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo - the property is the owner.
//   ChoiceParameters - Map of KeyAndValue - The selection parameters:
//     * Key - String - the name of the parameter of the type "Selection.The owner."
//     * Value - Arbitrary - the value of the parameter (selection).
//   Create_IfNotFound - Boolean - automatically create a new item in the ip Catalog
//     if it was not possible to select an existing item by the value of the object's Attribute before.
//
// Returns:
//   AnyRef - a reference to the found or created object.
//
Function ValueOfAttributeByXDTOObject(XDTODataObject, ObjectAttributeTypeIS, AttributeNameObjectIS = Undefined,
		TypeOfIPObjectToFillIn = Undefined, ObjectToFillInIS = Undefined, IsAdditionalAttributeIS = False,
		AdditionalAttributeIS = Undefined, ChoiceParameters = Undefined, Create_IfNotFound = True) Export
	
	// Create a value to fill in.
	ValueToFillIn = ValueForFillingInAttributesOfIPObject(XDTODataObject);
	
	If IsAdditionalAttributeIS
		And (ObjectAttributeTypeIS = Type("CatalogRef.ObjectsPropertiesValues")
			Or ObjectAttributeTypeIS = Type("CatalogRef.ObjectPropertyValueHierarchy")) Then
		ValueToFillIn.Owner = AdditionalAttributeIS;
	ElsIf ChoiceParameters <> Undefined Then
		ValueToFillIn.Owner = ChoiceParameters["Filter.Owner"];
	Else
		ValueToFillIn.Owner = Undefined;
	EndIf;
	
	// Let's create a context.
	Context = ContextForFillingInAttributesOfIPObject();
	Context.ObjectToFillInIS = ObjectToFillInIS;
	Context.AttributeNameObjectIS = AttributeNameObjectIS;
	Context.IsAdditionalAttributeIS = IsAdditionalAttributeIS;
	Context.AdditionalAttributeIS = AdditionalAttributeIS;
	Context.ChoiceParameters = ChoiceParameters;
	
	Return ValueOfAttributeOfIPObjectByValueToFillIn(
		ObjectAttributeTypeIS,
		ValueToFillIn,
		Context,
		Create_IfNotFound);
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region DataExchange

Function RequestToSendVDOExchangeMessage(Proxy, Settings)
	
	If Settings.UseIntegrationBefore2 Then
		QueryName1 = "DMPutChangesRequest";
	ElsIf Settings.UseIntegrationBefore3 Then
		QueryName1 = "DMUpdateFromIncomingDataRequest";
	EndIf;
	
	Return CreateObject(Proxy, QueryName1);
	
EndFunction

// Makes a copy of the file control table with the specified selection by source.
//
// Parameters:
//   SourceTable - See IntegrationWith1CDocumentManagementCore.ControlOverSendingFiles
//   ArrayOfSources - Array of AnyRef - the rows will be returned whose "Source" Attributes are
//     included in this array.
//
// Returns:
//   See IntegrationWith1CDocumentManagementCore.ControlOverSendingFiles
//
Function CopyOfFileSendingControlTable(SourceTable, ArrayOfSources)
	
	TableCopy = SourceTable.Copy();
	
	RowsCount = TableCopy.Count();
	For LineNumber = 1 To RowsCount Do
		IndexOf = RowsCount - LineNumber;
		String = TableCopy[IndexOf];
		If (ArrayOfSources.Find(String.Source) = Undefined) Then
			TableCopy.Delete(IndexOf);
		EndIf;
	EndDo;
	
	Return TableCopy;
	
EndFunction

// Updates the printed forms of the object BEFORE after the change of the IP object.
//
Procedure UpdatePrintedForms(Proxy, Settings)
	
	If Settings.UseIntegrationBefore2 Then
		
		ModuleIntegrationWith1CDocumentManagement = Common.CommonModule("IntegrationWith1CDocumentManagement");
		
	ElsIf Settings.UseIntegrationBefore3 Then
		
		ModuleIntegrationWith1CDocumentManagement3 = Common.CommonModule("IntegrationWith1CDocumentManagement3");
		If Not ModuleIntegrationWith1CDocumentManagement3.FileFunctionalityIsAvailable() Then
			Return;
		EndIf;
		
	EndIf;
	
	RequestObjects = New Query(
		"SELECT
		|	PreparationForUpdatingPrintedForms.Object AS Object,
		|	PreparationForUpdatingPrintedForms.Rule AS Rule,
		|	ObjectsIntegratedWith1CDocumentManagement.ObjectTypeDM AS ObjectTypeDM,
		|	ObjectsIntegratedWith1CDocumentManagement.ObjectIDDM AS ObjectIDDM
		|FROM
		|	InformationRegister.PreparationForUpdatingPrintedForms AS PreparationForUpdatingPrintedForms
		|		INNER JOIN InformationRegister.ObjectsIntegratedWith1CDocumentManagement AS ObjectsIntegratedWith1CDocumentManagement
		|		ON PreparationForUpdatingPrintedForms.Object = ObjectsIntegratedWith1CDocumentManagement.Object
		|WHERE
		|	PreparationForUpdatingPrintedForms.Rule REFS Catalog.RulesForIntegrationWith1CDocumentManagement");
	If Settings.UseIntegrationBefore3 Then
		RequestObjects.Text = StrReplace(
			RequestObjects.Text,
			"PreparationForUpdatingPrintedForms.Rule REFS Catalog.RulesForIntegrationWith1CDocumentManagement",
			"PreparationForUpdatingPrintedForms.Rule REFS Catalog.RulesForIntegrationWith1CDocumentManagement3");
	EndIf;
	PreparationForUpdatingPrintedForms = RequestObjects.Execute().Unload();
	
	If PreparationForUpdatingPrintedForms.Count() = 0 Then
		Return;
	EndIf;
	
	Query = CreateObject(Proxy, "DMUpdateFilesRequest");
	TotalMessageSize = 0;
	MessageSizeLimit =
		IntegrationWith1CDocumentManagementCoreServerCall.MaximumFileSize_();
	
	If Settings.UseIntegrationBefore2 Then
		
		RequestRuleData = New Query;
		QueryText =
			"SELECT DISTINCT
			|	PreparationForUpdatingPrintedForms.Rule AS Rule
			|INTO TTRules
			|FROM
			|	InformationRegister.PreparationForUpdatingPrintedForms AS PreparationForUpdatingPrintedForms
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	TTRules.Rule AS Rule,
			|	RulesForIntegrationWith1CDocumentManagement.TypeOfSavedPrintedFormFile AS TypeOfSavedPrintedFormFile,
			|	RulesForIntegrationWith1CDocumentManagement.AttachedPrintedForms.(
			|		Ref AS Ref,
			|		LineNumber AS LineNumber,
			|		CommandName AS CommandName,
			|		PrintManager AS PrintManager,
			|		AdditionalParameters AS AdditionalParameters,
			|		ShouldUpdate AS ShouldUpdate,
			|		CommandPresentation AS CommandPresentation
			|	) AS AttachedPrintedForms
			|FROM
			|	TTRules AS TTRules
			|		INNER JOIN Catalog.RulesForIntegrationWith1CDocumentManagement AS RulesForIntegrationWith1CDocumentManagement
			|		ON TTRules.Rule = RulesForIntegrationWith1CDocumentManagement.Ref";
		RequestRuleData.Text = QueryText;
		Selection = RequestRuleData.Execute().Select();
		
		ComplianceOfPrintedFormsWithRules = New Map;
		TypesOfPrintedFormFiles = New Map;
		
		While Selection.Next() Do
			ComplianceOfPrintedFormsWithRules.Insert(Selection.Rule, Selection.AttachedPrintedForms.Unload());
			TypesOfPrintedFormFiles.Insert(Selection.Rule, Selection.TypeOfSavedPrintedFormFile);
		EndDo;
		
	ElsIf Settings.UseIntegrationBefore3 Then
		
		ListOfIPObjects = PreparationForUpdatingPrintedForms.UnloadColumn("Object");
		SuitableIntegrationRules = New Map;
		For Each String In PreparationForUpdatingPrintedForms Do
			SuitableIntegrationRules.Insert(
				String.Object,
				CommonClientServer.ValueInArray(String.Rule));
		EndDo;
		
		PreliminaryData = ModuleIntegrationWith1CDocumentManagement3.PreliminaryDataForUnloadingVDO(
			Proxy,
			ListOfIPObjects,
			SuitableIntegrationRules,
			False,
			False);
		ComplianceOfPrintedFormsWithIPObjects = PreliminaryData.ComplianceOfPrintedFormsWithIPObjects;
		TypesOfPrintedFormFiles = PreliminaryData.TypesOfPrintedFormFiles;
		
	EndIf;
	
	ControlOverSendingFiles = ControlOverSendingFiles();
	
	For Each String In PreparationForUpdatingPrintedForms Do
		
		RecordManager = InformationRegisters.PreparationForUpdatingPrintedForms.CreateRecordManager();
		RecordManager.Object = String.Object;
		RecordManager.Delete();
		
		If Settings.UseIntegrationBefore2 Then
			
			AttachedPrintedForms = ModuleIntegrationWith1CDocumentManagement.AttachedPrintedForms(
				ComplianceOfPrintedFormsWithRules[String.Rule]);
			TypeOfSavedPrintedFormFile = TypesOfPrintedFormFiles[String.Rule];
			
		ElsIf Settings.UseIntegrationBefore3 Then
			
			AttachedPrintedForms = ModuleIntegrationWith1CDocumentManagement3.AttachedPrintedForms(
				ComplianceOfPrintedFormsWithIPObjects[String.Object]);
			TypeOfSavedPrintedFormFile =
				Enums.TypesOfSavedPrintedFormFileOfObjects[TypesOfPrintedFormFiles[String.Object]];
			
		EndIf;
		
		PrintedFormsToCreate = PrintedFormsToCreate(
			String.Object,
			AttachedPrintedForms,
			TypeOfSavedPrintedFormFile,
			ControlOverSendingFiles,
			True);
		
		If PrintedFormsToCreate.Count() = 0
				Or Not ObjectDoesNotSupportFiles(Proxy, String.ObjectTypeDM) Then
			Continue;
		EndIf;
		
		XDTODataObject = CreateObject(Proxy, String.ObjectTypeDM);
		ListOfFiles = XDTODataObject.files; // XDTOList
		
		XDTODataObject.name = String(String.Object);
		XDTODataObject.objectID = CreateObjectID(Proxy, String.ObjectIDDM, String.ObjectTypeDM);
		
		For Each CreationParameters In PrintedFormsToCreate Do
			XDTOFile = XDTOFileFromCreationParameters(Proxy, CreationParameters);
			ListOfFiles.Add(XDTOFile);
			TotalMessageSize = TotalMessageSize + CreationParameters.CurrentFile.Size;
		EndDo;
		
		Query.objects.Add(XDTODataObject);
		
		If TotalMessageSize > MessageSizeLimit And Query.objects.Count() > 0 Then
			Result = ExecuteQuery(Proxy, Query);
			CheckWebServiceRefund(Proxy, Result);
			Query = CreateObject(Proxy, "DMUpdateFilesRequest");
			TotalMessageSize = 0;
		EndIf;
		
	EndDo;
	
	If Query.objects.Count() = 0 Then
		Return;
	EndIf;
	
	Result = ExecuteQuery(Proxy, Query);
	CheckWebServiceRefund(Proxy, Result);
	
	For Each String In ControlOverSendingFiles Do
		InformationRegisters.ControlOverSendingFilesTo1CDocumentManagement.SaveHashSumOfFileVersion(
			String.Source,
			String.FileName,
			String.SpreadsheetDocument)
	EndDo;
	
EndProcedure

// Reads data from the queue for submission, and sends it to the Workflow.
//
Procedure SendData(Proxy, Settings, EventName)
	
	Try
		
		DatabaseRequest = New Query(
			"SELECT
			|	QueueOfMessagesIn1CDocumentManagement.PointInTime AS PointInTime,
			|	QueueOfMessagesIn1CDocumentManagement.Data AS Data,
			|	QueueOfMessagesIn1CDocumentManagement.Id AS Id
			|FROM
			|	InformationRegister.QueueOfMessagesIn1CDocumentManagement AS QueueOfMessagesIn1CDocumentManagement
			|WHERE
			|	QueueOfMessagesIn1CDocumentManagement.NumberOfSendingAttempts < &MaximumNumberOfAttemptsToSendExchangeMessage
			|
			|ORDER BY
			|	PointInTime");
		DatabaseRequest.SetParameter("MaximumNumberOfAttemptsToSendExchangeMessage",
			MaximumNumberOfAttemptsToSendExchangeMessage());
		Result = DatabaseRequest.Execute();
		
		If Result.IsEmpty() Then
			Return;
		EndIf;
		
		Selection = Result.Select();
		
	Except
		WriteError(ErrorProcessing.DetailErrorDescription(ErrorInfo()), EventName);
	EndTry;
	
	URIOfNamespaceOfWorkflowWebService = URIOfNamespaceOfWorkflowWebService();
	
	While Selection.Next() Do
		
		MessageID = Selection.Id;
		
		Try
			
			Query = RequestToSendVDOExchangeMessage(Proxy, Settings);
			ListOfObjects = Query.objects; // XDTOList
			
			BinaryData = Selection.Data.Get(); // BinaryData
			
			ExchangeMessageFileName = GetTempFileName("xml");
			BinaryData.Write(ExchangeMessageFileName);
			
			XMLReader = New XMLReader;
			XMLReader.OpenFile(ExchangeMessageFileName);
			XMLReader.Read();
			XMLReader.Read();
			
			While XMLReader.NodeType = XMLNodeType.StartElement Do
				// Sequential reading of one object after another is performed
				XDTOType = Proxy.XDTOFactory.Type(URIOfNamespaceOfWorkflowWebService, XMLReader.Name);
				XDTODataObject = Proxy.XDTOFactory.ReadXML(XMLReader, XDTOType);
				ListOfObjects.Add(XDTODataObject);
			EndDo;
			
			XMLReader = Undefined;
			DeleteFiles(ExchangeMessageFileName);
			
			Response = ExecuteQuery(Proxy, Query);
			
			If CheckResultOfSending(Proxy, Query, Response, Settings, Selection) Then
				InformationRegisters.HistoryOfSendingMessagesTo1CDocumentManagement.MoveMessageToHistory(
					Selection.PointInTime,
					MessageID);
			EndIf;
			
		Except
			
			ErrorMessageText = ErrorProcessing.BriefErrorDescription(ErrorInfo());
			
			WriteError(ErrorMessageText, EventName, String(MessageID));
			
			RecordManager = InformationRegisters.QueueOfMessagesIn1CDocumentManagement.CreateRecordManager();
			RecordManager.PointInTime = Selection.PointInTime;
			RecordManager.Id = MessageID;
			RecordManager.Read();
			RecordManager.NumberOfSendingAttempts = RecordManager.NumberOfSendingAttempts + 1;
			RecordManager.ErrorMessageText = ErrorMessageText;
			RecordManager.Write();
			
		EndTry;
		
	EndDo;
	
EndProcedure

Procedure ClearOutdatedData()
	
	TermOfStorageOfMessagesTo1CDocumentManagement = Constants.TermOfStorageOfMessagesTo1CDocumentManagement.Get();
	If TermOfStorageOfMessagesTo1CDocumentManagement = 0 Then
		// We won't set a deadline. Apply the default value.
		TermOfStorageOfMessagesTo1CDocumentManagement = 30;	// OfDays
		Constants.TermOfStorageOfMessagesTo1CDocumentManagement.Set(TermOfStorageOfMessagesTo1CDocumentManagement);
	EndIf;
	
	Deadline = CurrentSessionDate() - TermOfStorageOfMessagesTo1CDocumentManagement * 24 * 60 * 60;
	
	Query = New Query(
		"SELECT
		|	QueueOfMessagesIn1CDocumentManagement.PointInTime AS PointInTime,
		|	QueueOfMessagesIn1CDocumentManagement.Id AS Id
		|FROM
		|	InformationRegister.QueueOfMessagesIn1CDocumentManagement AS QueueOfMessagesIn1CDocumentManagement
		|WHERE
		|	QueueOfMessagesIn1CDocumentManagement.CreationDate <= &Deadline
		|	AND QueueOfMessagesIn1CDocumentManagement.NumberOfSendingAttempts >= &MaximumNumberOfAttemptsToSendExchangeMessage
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	HistoryOfSendingMessagesTo1CDocumentManagement.PointInTime AS PointInTime,
		|	HistoryOfSendingMessagesTo1CDocumentManagement.Id AS Id
		|FROM
		|	InformationRegister.HistoryOfSendingMessagesTo1CDocumentManagement AS HistoryOfSendingMessagesTo1CDocumentManagement
		|WHERE
		|	HistoryOfSendingMessagesTo1CDocumentManagement.DateSent <= &Deadline");
	Query.SetParameter("Deadline", Deadline);
	Query.SetParameter("MaximumNumberOfAttemptsToSendExchangeMessage",
		MaximumNumberOfAttemptsToSendExchangeMessage());
	
	ResultsArray = Query.ExecuteBatch();
	
	DeleteMessages(ResultsArray[0].Unload(), InformationRegisters.QueueOfMessagesIn1CDocumentManagement);
	DeleteMessages(ResultsArray[1].Unload(), InformationRegisters.HistoryOfSendingMessagesTo1CDocumentManagement);
	
EndProcedure

// Prepares exchange messages in the Workflow and writes them to the queue for sending.
//
Procedure PrepareDataForSending(Proxy, Settings, EventName,
		ModuleIntegrationWith1CDocumentManagementExchange, ModuleIntegrationOfS1CDocumentFlow3Exchange)
	
	DocumentFlowNode = IntegrationWith1CDocumentManagementCoreCached.DocumentFlowNode();
	
	// Sampling of all changes for this integrated system
	ObjectsToDeleteFromChangeRegistration = New Array;
	IntegratedObjects_ = New Array;
	If Settings.UseIntegrationBefore2 Then
		IntegratedObjects_ = ModuleIntegrationWith1CDocumentManagementExchange.RegisteredData(
			Proxy,
			DocumentFlowNode,
			ObjectsToDeleteFromChangeRegistration,
			EventName);
	ElsIf Settings.UseIntegrationBefore3 Then
		IntegratedObjects_ = ModuleIntegrationOfS1CDocumentFlow3Exchange.RegisteredData(
			Proxy,
			DocumentFlowNode,
			ObjectsToDeleteFromChangeRegistration,
			EventName);
	EndIf;
	
	MaximumNumberOfObjectsInMessage = 10;
	IntegrationWith1CDocumentManagementCoreOverridable.WhenDeterminingMaximumNumberOfObjectsInExchangeMessage(
		MaximumNumberOfObjectsInMessage);
	
	PortionOfObjects = New Array;
	ObjectsPerServing = 0;
	ControlOverSendingFiles = ControlOverSendingFiles();
	
	For Each IntegratedObject In IntegratedObjects_ Do
		If ObjectsPerServing >= MaximumNumberOfObjectsInMessage Then
			GenerateMessage(
				Proxy,
				PortionOfObjects,
				ControlOverSendingFiles);
			PortionOfObjects = New Array;
			ObjectsPerServing = 0;
			ControlOverSendingFiles = ControlOverSendingFiles();
		EndIf;
		
		Try
			If Settings.UseIntegrationBefore2 Then
				XDTODataObject = ModuleIntegrationWith1CDocumentManagementExchange.GetXDTOOfChangesFromObject(
					Proxy,
					IntegratedObject,
					ControlOverSendingFiles);
			ElsIf Settings.UseIntegrationBefore3 Then
				XDTODataObject = ModuleIntegrationOfS1CDocumentFlow3Exchange.GetXDTOOfChangesFromObject(
					Proxy,
					IntegratedObject,
					ControlOverSendingFiles);
			EndIf;
			
			PortionOfObjects.Add(XDTODataObject);
			ObjectsPerServing = ObjectsPerServing + 1;
			
		Except
			ObjectIndex = ObjectsToDeleteFromChangeRegistration.Find(IntegratedObject.Object);
			If ObjectIndex <> Undefined Then
				ObjectsToDeleteFromChangeRegistration.Delete(ObjectIndex);
			EndIf;
			
			WriteLogEvent(
				EventLogEventName(
					NStr("ru = 'Формирование сообщения обмена';
						|vi = 'Generate exchange message';
						|en = 'Generate exchange message'; fa = 'Generate exchange message';
						|it = 'Generazione del messaggio di scambio';
						|pl = 'Wygenerowanie wiadomości wymiany';
						|tr = 'Değişim mesajı oluşturma'", Common.DefaultLanguageCode())),
				EventLogLevel.Error,
				Metadata.ExchangePlans.IntegrationWith1CDocumentManagementSubsystemOverridable,
				IntegratedObject.Object,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
	EndDo;
	
	GenerateMessage(
		Proxy,
		PortionOfObjects,
		ControlOverSendingFiles);
	
	For Each ObjectToDelete In ObjectsToDeleteFromChangeRegistration Do
		ExchangePlans.DeleteChangeRecords(DocumentFlowNode, ObjectToDelete);
	EndDo;
	
EndProcedure

Function CheckResultOfSending(Proxy, Query, Response, Settings, MessageAttributes)
	
	If ValidateType(Proxy, Response, "DMError") Then
		Raise StrTemplate("%1
				|
				|%2",
			Response.subject,
			Response.description);
	EndIf;
	
	If Settings.UseIntegrationBefore2 Then
		Return True;
	EndIf;
	
	ErrorMessageText = "";
	
	ConfigurationName = AbbreviatedNameOfConfiguration();
	
	ErrorsArray = New Array;
	PortionOfRequestObjectsWithError = New Array;
	NotSentIPObjects = New Array;
	PortionOfRequestObjectsWithoutErrors = New Array;
	SentIPObjects = New Array;
	
	For Each XDTODataObject In Response.objects Do
		ObjectIS = Undefined;
		For Each XDTORequestObject In Query.objects Do
			If XDTORequestObject.updatingObject.id = XDTODataObject.key.id
					And XDTORequestObject.updatingObject.type = XDTODataObject.key.type Then
				ObjectIS = LinkFromUUID(XDTORequestObject.externalObject.type, XDTORequestObject.externalObject.ID);
				Break;
			EndIf;
		EndDo;
		
		If XDTODataObject.success Then
			PortionOfRequestObjectsWithoutErrors.Add(XDTORequestObject);
			SentIPObjects.Add(ObjectIS);
			Continue;
		Else
			PortionOfRequestObjectsWithError.Add(XDTORequestObject);
			NotSentIPObjects.Add(ObjectIS);
		EndIf;
		
		ArrayOfObjectErrors = New Array;
		ArrayOfObjectErrors.Add(
			StrTemplate(NStr("vi = 'Lỗi trong 1C:Document Management khi nhận thông điệp trao đổi từ %1:';
							|ru = 'Ошибка на стороне 1С:Документооборот при получении сообщения обмена из %1:';
							|en = 'An error occurred on 1C:Document Management side when receiving the exchange message from %1:'; fa = 'An error occurred on 1C:Document Management side when receiving the exchange message from %1:';
							|it = 'Errore sul lato 1C:Document Management durante la ricezione del messaggio di scambio da %1:';
							|pl = 'Błąd po stronie 1C:Document Management podczas otrzymania wiadomości wymiany z %1:';
							|tr = '1C:Document Management tarafında değişim mesajı alırken hata %1:'"),
				ConfigurationName));
		ArrayOfObjectErrors.Add(XDTODataObject.error.subject);
		ArrayOfObjectErrors.Add(XDTODataObject.error.description);
		
		If ObjectIS <> Undefined Then
			ArrayOfObjectErrors.Add(
				StrTemplate(NStr("vi = 'Tham chiếu đến đối tượng %1 có các thay đổi được gửi đến 1C:Document Management: %2';
								|ru = 'Ссылка на объект %1, изменения которого отправляются в 1С:Документооборот: %2';
								|en = 'The link to the %1 object whose changes are sent to 1C:Document Management: %2'; fa = 'The link to the %1 object whose changes are sent to 1C:Document Management: %2';
								|it = 'Riferimento all''oggetto %1, le cui modifiche vengono inviate a 1C:Document Management: %2';
								|pl = 'Odnośnik do obiektu %1, którego zmiany są wysyłane do 1C:Document Management: %2';
								|tr = 'Değişiklikleri 1C:Document Management''e gönderilen %1 nesneye bağlantı: %2'"),
					ConfigurationName,
					GetURL(ObjectIS)));
		EndIf;
		
		ErrorsArray.Add(StrConcat(ArrayOfObjectErrors, Chars.LF));
	EndDo;
	
	If ErrorsArray.Count() = 0 Then
		Return True;
	EndIf;
	
	ErrorMessageText = StrConcat(
		ErrorsArray,
		"
		|
		|-----
		|
		|");
	
	If PortionOfRequestObjectsWithoutErrors.Count() = 0 Then
		Raise ErrorMessageText;
	EndIf;
	
	BeginTransaction();
	
	Try
		
		DataLock = New DataLock;
		
		LockItem = DataLock.Add("InformationRegister.QueueOfMessagesIn1CDocumentManagement");
		LockItem.SetValue("PointInTime", MessageAttributes.PointInTime);
		LockItem.SetValue("Id", MessageAttributes.Id);
		LockItem.Mode = DataLockMode.Exclusive;
		
		DataLock.Lock();
		
		ErrorMessageAttributes = InformationRegisters.QueueOfMessagesIn1CDocumentManagement.MessageAttributes();
		ErrorMessageAttributes.PointInTime = MessageAttributes.PointInTime;
		ErrorMessageAttributes.Id = MessageAttributes.Id;
		ErrorMessageAttributes.ErrorMessageText = ErrorMessageText;
		
		QueueRecordManager = InformationRegisters.QueueOfMessagesIn1CDocumentManagement.CreateRecordManager();
		QueueRecordManager.PointInTime = MessageAttributes.PointInTime;
		QueueRecordManager.Id = MessageAttributes.Id;
		QueueRecordManager.Read();
		If QueueRecordManager.Selected() Then
			ErrorMessageAttributes.NumberOfSendingAttempts = QueueRecordManager.NumberOfSendingAttempts + 1;
			ControlOverSendingFiles = QueueRecordManager.ControlOverSendingFiles.Get();
			ControlOfSendingFilesWithoutErrors = CopyOfFileSendingControlTable(
				ControlOverSendingFiles,
				SentIPObjects);
			ControlOfSendingFilesWithError = CopyOfFileSendingControlTable(
				ControlOverSendingFiles,
				NotSentIPObjects);
			QueueRecordManager.Delete();
		Else
			ControlOfSendingFilesWithoutErrors = ControlOverSendingFiles();
			ControlOfSendingFilesWithError = ControlOverSendingFiles();
		EndIf;
		
		GenerateMessage(
			Proxy,
			PortionOfRequestObjectsWithError,
			ControlOfSendingFilesWithError,
			ErrorMessageAttributes);
		
		NoErrorMessageAttributes = InformationRegisters.QueueOfMessagesIn1CDocumentManagement.MessageAttributes();
		
		GenerateMessage(
			Proxy,
			PortionOfRequestObjectsWithoutErrors,
			ControlOfSendingFilesWithoutErrors,
			NoErrorMessageAttributes);
		
		InformationRegisters.HistoryOfSendingMessagesTo1CDocumentManagement.MoveMessageToHistory(
			NoErrorMessageAttributes.PointInTime,
			NoErrorMessageAttributes.Id);
		
		CommitTransaction();
		
		Return False;
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndFunction

// called when filling in the Attributes of the ip object by the value of the Attributes of the object before.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   Result - Arbitrary - the filled-in value of the IP object's props.
//   ObjectAttributeTypeIS - Type - the type of the IP object's details to be filled in.
//   ValueToFillIn - See IntegrationWith1CDocumentManagementCore.ValueForFillingInAttributesOfIPObject
//   Context - See IntegrationWith1CDocumentManagementCore.ContextForFillingInAttributesOfIPObject
//
Procedure WhenDeterminingValueOfAttributeOfIPObjectByValueToFillIn(Proxy, Result, ObjectAttributeTypeIS,
		ValueToFillIn, Context)
	
	XDTODataObject = ValueToFillIn;
	
	If Result = Undefined And ThisIsObjectValue(Proxy, ValueToFillIn.PropertyValue) Then
		
		XDTODataObject = ValueToFillIn.PropertyValue;
		
		If ObjectAttributeTypeIS = IntegrationWith1CDocumentManagementCoreCached.TypeUsers()
				And (ValidateType(Proxy, XDTODataObject, "DMEmployee")
					Or ValidateType(Proxy, XDTODataObject, "DMUser")) Then
			
			If Not IsBlankString(ValueToFillIn.ObjectIDDM) Then
				Result =
					InformationRegisters.ObjectsIntegratedWith1CDocumentManagement.ReferenceToIPObjectAccordingToDocumentManagementData(
						ValueToFillIn.ObjectIDDM,
						ValueToFillIn.ObjectTypeDM);
			EndIf;
			
			If Not ValueIsFilled(Result) And PropertySet(XDTODataObject, "infoBaseUser") Then
				SetPrivilegedMode(True);
				
				If PropertySet(XDTODataObject.infoBaseUser, "objectID")
						And StringFunctionsClientServer.IsUUID(XDTODataObject.infoBaseUser.objectID.ID) Then
					Result = Users.FindByID(
						New UUID(XDTODataObject.infoBaseUser.objectID.ID));
				EndIf;
				
				If Not ValueIsFilled(Result) Then
					SuitableInformationSecurityUser = Undefined;
					If ValueIsFilled(XDTODataObject.infoBaseUser.name) Then
						SuitableInformationSecurityUser = InfoBaseUsers.FindByName(XDTODataObject.infoBaseUser.name);
					EndIf;
					If SuitableInformationSecurityUser = Undefined
							And (ValueIsFilled(XDTODataObject.infoBaseUser.OSUserName)
								Or ValueIsFilled(XDTODataObject.infoBaseUser.email)) Then
						For Each IBUser In InfoBaseUsers.GetUsers() Do
							If (ValueIsFilled(XDTODataObject.infoBaseUser.email)
										And TrimAll(Lower(IBUser.Email)) = TrimAll(Lower(XDTODataObject.infoBaseUser.email)))
									Or (ValueIsFilled(XDTODataObject.infoBaseUser.OSUserName)
										And TrimAll(Lower(IBUser.OSUser)) = TrimAll(Lower(XDTODataObject.infoBaseUser.OSUserName))) Then
								SuitableInformationSecurityUser = IBUser;
								Break;
							EndIf;
						EndDo;
					EndIf;
					If SuitableInformationSecurityUser <> Undefined Then
						Result = Users.FindByID(SuitableInformationSecurityUser.UUID);
					EndIf;
				EndIf;
				
				SetPrivilegedMode(False);
			EndIf;
			
			If Not ValueIsFilled(Result) Then
				
				NameOfEmployee = "";
				UserDescription = "";
				Individual_Name = "";
				EmployeeUser = Undefined;
				Individual = Undefined;
				
				If ValidateType(Proxy, XDTODataObject, "DMEmployee") Then
					NameOfEmployee = XDTODataObject.name;
					If PropertySet(XDTODataObject, "user") Then
						UserDescription = XDTODataObject.user.name;
						EmployeeUser = ValueOfAttributeOfIPObjectByValueToFillIn(
							IntegrationWith1CDocumentManagementCoreCached.TypeUsers(),
							ValueForFillingInAttributesOfIPObject(XDTODataObject.user),
							Context,
							False);
					EndIf;
				ElsIf ValidateType(Proxy, XDTODataObject, "DMUser") Then
					UserDescription = XDTODataObject.name;
				EndIf;
				
				If PropertySet(XDTODataObject, "privatePerson") Then
					Individual_Name = XDTODataObject.privatePerson.name;
					Individual = ValueOfAttributeOfIPObjectByValueToFillIn(
						Metadata.Catalogs.Users.Attributes.Individual.Type.Types()[0],
						ValueForFillingInAttributesOfIPObject(XDTODataObject.privatePerson),
						Context,
						False);
				EndIf;
				
				Query = New Query(
					"SELECT ALLOWED
					|	Users.Ref AS Ref,
					|	0 AS Priority
					|FROM
					|	Catalog.Users AS Users
					|WHERE
					|	Users.Ref = &EmployeeUser
					|
					|UNION ALL
					|
					|SELECT
					|	Users.Ref,
					|	1
					|FROM
					|	Catalog.Users AS Users
					|WHERE
					|	&PersonHasBeenTransferred = TRUE
					|	AND Users.Individual = &Individual
					|	AND NOT Users.DeletionMark
					|
					|UNION ALL
					|
					|SELECT
					|	Users.Ref,
					|	2
					|FROM
					|	Catalog.Users AS Users
					|WHERE
					|	Users.Description = &UserDescription
					|	AND NOT Users.DeletionMark
					|
					|UNION ALL
					|
					|SELECT
					|	Users.Ref,
					|	3
					|FROM
					|	Catalog.Users AS Users
					|WHERE
					|	Users.Description = &Individual_Name
					|	AND NOT Users.DeletionMark
					|
					|UNION ALL
					|
					|SELECT
					|	Users.Ref,
					|	4
					|FROM
					|	Catalog.Users AS Users
					|WHERE
					|	Users.Description = &NameOfEmployee
					|	AND NOT Users.DeletionMark
					|
					|ORDER BY
					|	Priority");
				Query.SetParameter("EmployeeUser", EmployeeUser);
				Query.SetParameter("Individual", Individual);
				Query.SetParameter("PersonHasBeenTransferred", ValueIsFilled(Individual));
				Query.SetParameter("UserDescription", UserDescription);
				Query.SetParameter("Individual_Name", Individual_Name);
				Query.SetParameter("NameOfEmployee", NameOfEmployee);
				
				Selection = Query.Execute().Select();
				If Selection.Next() Then
					Result = Selection.Ref;
				EndIf;
				
			EndIf;
			
		ElsIf ObjectAttributeTypeIS = IntegrationWith1CDocumentManagementCoreCached.TypeUsers()
				And (XDTODataObject.objectID.type = "DMParty"
					Or XDTODataObject.objectID.type = "DMPartyRowContact"
					Or ValidateType(Proxy, XDTODataObject, "DMParty")
					Or ValidateType(Proxy, XDTODataObject, "DMPartyRowContact")) Then
			
			UserXDTO = Undefined;
			Settings = IntegrationWith1CDocumentManagementCoreServerCall.UseIntegration();
			If Settings.UseIntegrationBefore2
					And PropertySet(XDTODataObject, "user") Then
				UserXDTO = XDTODataObject.user;
			ElsIf Settings.UseIntegrationBefore3
					And PropertySet(XDTODataObject, "employee") Then
				UserXDTO = XDTODataObject.employee;
			EndIf;
			
			If UserXDTO <> Undefined Then
				Result = ValueOfAttributeOfIPObjectByValueToFillIn(
					IntegrationWith1CDocumentManagementCoreCached.TypeUsers(),
					ValueForFillingInAttributesOfIPObject(UserXDTO),
					Context,
					False);
			EndIf;
			
		ElsIf ObjectAttributeTypeIS = IntegrationWith1CDocumentManagementCoreCached.CurrencyKind()
				And ValidateType(Proxy, XDTODataObject, "DMCurrency") Then
			
			Description = XDTODataObject.name;
			Code = "";
			DescriptionFull = "";
			
			If PropertySet(XDTODataObject, "code") Then
				Code = XDTODataObject.code;
			EndIf;
			If PropertySet(XDTODataObject, "fullName") Then
				DescriptionFull = XDTODataObject.fullName;
			EndIf;
			
			Query = New Query(
				"SELECT ALLOWED
				|	Currencies.Ref AS Ref,
				|	0 AS Priority
				|FROM
				|	Catalog.Currencies AS Currencies
				|WHERE
				|	&Code <> """"
				|	AND Currencies.Code = &Code
				|	AND NOT Currencies.DeletionMark
				|
				|UNION ALL
				|
				|SELECT
				|	Currencies.Ref,
				|	1
				|FROM
				|	Catalog.Currencies AS Currencies
				|WHERE
				|	Currencies.Description = &Description
				|	AND NOT Currencies.DeletionMark
				|
				|UNION ALL
				|
				|SELECT
				|	Currencies.Ref,
				|	2
				|FROM
				|	Catalog.Currencies AS Currencies
				|WHERE
				|	Currencies.DescriptionFull = &DescriptionFull
				|	AND NOT Currencies.DeletionMark
				|
				|ORDER BY
				|	Priority");
			Query.SetParameter("Code", Code);
			Query.SetParameter("Description", Description);
			Query.SetParameter("DescriptionFull", DescriptionFull);
			
			Selection = Query.Execute().Select();
			If Selection.Next() Then
				Result = Selection.Ref;
			EndIf;
			
		ElsIf ObjectAttributeTypeIS = IntegrationWith1CDocumentManagementCoreCached.BankClassifierType()
				And ValidateType(Proxy, XDTODataObject, "DMBank") Then
			
			Description = XDTODataObject.name;
			Code = "";
			
			If PropertySet(XDTODataObject, "BIC") Then
				Code = XDTODataObject.BIC;
			EndIf;
			
			Query = New Query(
				"SELECT ALLOWED
				|	BankClassifier.Ref AS Ref,
				|	0 AS Priority
				|FROM
				|	Catalog.BankClassifier AS BankClassifier
				|WHERE
				|	&Code <> """"
				|	AND BankClassifier.Code = &Code
				|	AND NOT BankClassifier.DeletionMark
				|
				|UNION ALL
				|
				|SELECT
				|	BankClassifier.Ref,
				|	1
				|FROM
				|	Catalog.BankClassifier AS BankClassifier
				|WHERE
				|	BankClassifier.Description = &Description
				|	AND NOT BankClassifier.DeletionMark
				|
				|ORDER BY
				|	Priority");
			Query.SetParameter("Code", Code);
			Query.SetParameter("Description", Description);
			
			Selection = Query.Execute().Select();
			If Selection.Next() Then
				Result = Selection.Ref;
			EndIf;
			
		ElsIf ObjectAttributeTypeIS = IntegrationWith1CDocumentManagementCoreCached.TypeOfCountryInWorld()
				And ValidateType(Proxy, XDTODataObject, "DMCountry") Then
			
			Description = XDTODataObject.name;
			Code = "";
			
			If PropertySet(XDTODataObject, "code") Then
				Code = XDTODataObject.code;
			EndIf;
			
			Query = New Query(
				"SELECT ALLOWED
				|	WorldCountries.Ref AS Ref,
				|	0 AS Priority
				|FROM
				|	Catalog.WorldCountries AS WorldCountries
				|WHERE
				|	&Code <> """"
				|	AND WorldCountries.Code = &Code
				|	AND NOT WorldCountries.DeletionMark
				|
				|UNION ALL
				|
				|SELECT
				|	WorldCountries.Ref,
				|	1
				|FROM
				|	Catalog.WorldCountries AS WorldCountries
				|WHERE
				|	WorldCountries.Description = &Description
				|	AND NOT WorldCountries.DeletionMark
				|
				|ORDER BY
				|	Priority");
			Query.SetParameter("Code", Code);
			Query.SetParameter("Description", Description);
			
			Selection = Query.Execute().Select();
			If Selection.Next() Then
				Result = Selection.Ref;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreOverridable.WhenDeterminingValueOfPropsOnXDTOObject(
		Result,
		XDTODataObject,
		ObjectAttributeTypeIS,
		Context.AttributeNameObjectIS,
		TypeOf(Context.ObjectToFillInIS),
		Context.ObjectToFillInIS,
		Context.IsAdditionalAttributeIS,
		Context.AdditionalAttributeIS,
		Context.ChoiceParameters);
	
EndProcedure

// called when creating an ip object by reference in the Attributes of the before object.
//
// Parameters:
//   ObjectIS - Arbitrary - an IC object created but not yet recorded.
//   XDTODataObject - XDTODataObject - the original object whose match was not found in the current IB.
//   ObjectToFillInIS - Arbitrary - the IP object, during the filling of which the creation is called
//     ObjectIS by reference. Provides the context needed to populate the ObjectIS.
//
Procedure WhenCreatingLink(ObjectIS, XDTODataObject, ObjectToFillInIS = Undefined)
	
	If TypeOf(ObjectIS) = IntegrationWith1CDocumentManagementCoreCached.CurrencyKind(True)
			And XDTODataObject.objectID.type = "DMCurrency" Then
		
		If PropertySet(XDTODataObject, "code") Then
			ObjectIS.Code = XDTODataObject.code;
		EndIf;
		
		If PropertySet(XDTODataObject, "fullName") And ValueIsFilled(XDTODataObject.fullName) Then
			ObjectIS.DescriptionFull = XDTODataObject.fullName;
		Else
			ObjectIS.DescriptionFull = XDTODataObject.name;
		EndIf;
		
	ElsIf TypeOf(ObjectIS) = IntegrationWith1CDocumentManagementCoreCached.BankClassifierType(True)
			And XDTODataObject.objectID.type = "DMBank" Then
		
		If PropertySet(XDTODataObject, "BIC") Then
			ObjectIS.Code = XDTODataObject.BIC;
		EndIf;
		
	ElsIf TypeOf(ObjectIS) = IntegrationWith1CDocumentManagementCoreCached.TypeOfCountryInWorld(True)
			And XDTODataObject.objectID.type = "DMCountry" Then
		
		If PropertySet(XDTODataObject, "code") Then
			ObjectIS.Code = XDTODataObject.code;
		EndIf;
		If PropertySet(XDTODataObject, "codeAlpha2") Then
			ObjectIS.CodeAlpha2 = XDTODataObject.codeAlpha2;
		EndIf;
		If PropertySet(XDTODataObject, "codeAlpha3") Then
			ObjectIS.CodeAlpha3 = XDTODataObject.codeAlpha3;
		EndIf;
		If PropertySet(XDTODataObject, "EAEUMember") Then
			ObjectIS.EEUMember = XDTODataObject.EAEUMember;
		EndIf;
		If PropertySet(XDTODataObject, "longDescription") And ValueIsFilled(XDTODataObject.longDescription) Then
			ObjectIS.DescriptionFull = XDTODataObject.longDescription;
		Else
			ObjectIS.DescriptionFull = XDTODataObject.name;
		EndIf;
		If PropertySet(XDTODataObject, "internationalDescription") Then
			ObjectIS.InternationalDescription = XDTODataObject.internationalDescription;
		EndIf;
		
	ElsIf TypeOf(ObjectIS) = IntegrationWith1CDocumentManagementCoreCached.TypeUsers(True)
			And (XDTODataObject.objectID.type = "DMUser"
				Or XDTODataObject.objectID.type = "DMEmployee"
				Or XDTODataObject.objectID.type = "DMParty"
				Or XDTODataObject.objectID.type = "DMPartyRowContact") Then
		
		UserXDTO = Undefined;
		XDTOEmployee = Undefined;
		
		If XDTODataObject.objectID.type = "DMUser" Then
			UserXDTO = XDTODataObject;
		EndIf;
		
		If XDTODataObject.objectID.type = "DMEmployee" Then
			XDTOEmployee = XDTODataObject;
		EndIf;
		
		If (XDTODataObject.objectID.type = "DMParty"
				Or XDTODataObject.Type().Name = "DMParty"
				Or XDTODataObject.objectID.type = "DMPartyRowContact"
				Or XDTODataObject.Type().Name = "DMPartyRowContact") Then
			Settings = IntegrationWith1CDocumentManagementCoreServerCall.UseIntegration();
			If Settings.UseIntegrationBefore2 And PropertySet(XDTODataObject, "user") Then
				UserXDTO = XDTODataObject.user;
			ElsIf Settings.UseIntegrationBefore3 And PropertySet(XDTODataObject, "employee") Then
				XDTOEmployee = XDTODataObject.employee;
			EndIf;
		EndIf;
		
		If XDTOEmployee <> Undefined And PropertySet(XDTOEmployee, "user") Then
			UserXDTO = XDTOEmployee.user;
		EndIf;
		
		If UserXDTO <> Undefined Then
			If PropertySet(UserXDTO, "privatePerson") Then
				ObjectIS.Individual = ValueOfAttributeOfIPObjectByValueToFillIn(
					Metadata.Catalogs.Users.Attributes.Individual.Type.Types()[0],
					ValueForFillingInAttributesOfIPObject(UserXDTO.privatePerson),,
					False);
			EndIf;
			If PropertySet(UserXDTO, "subdivision") Then
				ObjectIS.Department = ValueOfAttributeOfIPObjectByValueToFillIn(
					Metadata.Catalogs.Users.Attributes.Department.Type.Types()[0],
					ValueForFillingInAttributesOfIPObject(UserXDTO.subdivision),,
					False);
			EndIf;
		EndIf;
		
		If XDTOEmployee <> Undefined Then
			If Not ValueIsFilled(ObjectIS.Individual)
					And PropertySet(XDTOEmployee, "privatePerson") Then
				ObjectIS.Individual = ValueOfAttributeOfIPObjectByValueToFillIn(
					Metadata.Catalogs.Users.Attributes.Individual.Type.Types()[0],
					ValueForFillingInAttributesOfIPObject(XDTOEmployee.privatePerson),,
					False);
			EndIf;
			If Not ValueIsFilled(ObjectIS.Department)
					And PropertySet(XDTOEmployee, "subdivision") Then
				ObjectIS.Department = ValueOfAttributeOfIPObjectByValueToFillIn(
					Metadata.Catalogs.Users.Attributes.Department.Type.Types()[0],
					ValueForFillingInAttributesOfIPObject(XDTOEmployee.subdivision),,
					False);
			EndIf;
		EndIf;
		
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreOverridable.WhenCreatingLink(
		ObjectIS,
		XDTODataObject,
		ObjectToFillInIS);
	
EndProcedure

Procedure GenerateMessage(Proxy, PortionOfObjects, ControlOverSendingFiles, MessageAttributes = Undefined)
	
	If PortionOfObjects.Count() = 0 Then
		Return;
	EndIf;
	
	TempFileName = GetTempFileName("xml");
	XMLWriter = New XMLWriter;
	XMLWriter.OpenFile(TempFileName, "UTF-8");
	XMLWriter.WriteXMLDeclaration();
	XMLWriter.WriteStartElement("Message");
	
	ObjectsInMessage = 0;
	For Each XDTODataObject In PortionOfObjects Do
		If XDTODataObject = Undefined Then
			Continue;
		EndIf;
		Proxy.XDTOFactory.WriteXML(XMLWriter, XDTODataObject);
		ObjectsInMessage = ObjectsInMessage + 1;
	EndDo;
	
	XMLWriter.WriteEndElement();	// Message
	XMLWriter.Close();
	
	If ObjectsInMessage > 0 Then
		InformationRegisters.QueueOfMessagesIn1CDocumentManagement.AddAMessage(
			New BinaryData(TempFileName),
			ControlOverSendingFiles,
			MessageAttributes);
	EndIf;
	
	DeleteFiles(TempFileName);
	
EndProcedure

Procedure DeleteMessages(MessageTable, Register_Manager)
	
	For Each String In MessageTable Do
		RecordManager = Register_Manager.CreateRecordManager();
		RecordManager.PointInTime = String.PointInTime;
		RecordManager.Id = String.Id;
		RecordManager.Delete();
	EndDo;
	
EndProcedure

#EndRegion

// Determines whether the service version is more recent or the same as the required version.
//
// Parameters:
//   DescriptionOfServiceVersion - Array of String - an array of 4-5 elements that makes up the full version number.
//   RequiredVersion - String - a string with the required version number.
//
// Returns:
//   Boolean - True if the version description is at least the required version.
//
Function VersionNoLess(DescriptionOfServiceVersion, RequiredVersion)
	
	DescriptionOfRequiredVersion = StrSplit(RequiredVersion, ".");
	If DescriptionOfRequiredVersion.Count() <> 5 Then
		DescriptionOfRequiredVersion.Add("PROF");
	EndIf;
	
	EditorialPriority = New Map;
	EditorialPriority.Insert("PROF", 0);
	EditorialPriority.Insert("CORP", 1);
	EditorialPriority.Insert("HOLD", 2);
	EditorialPriority.Insert("HOLD_CENTER", 2);
	
	PriorityOfServiceVersionRevision = EditorialPriority[DescriptionOfServiceVersion[4]];
	PriorityOfRevisionOfRequiredVersion = EditorialPriority[DescriptionOfRequiredVersion[4]];
	
	If PriorityOfServiceVersionRevision < PriorityOfRevisionOfRequiredVersion Then
		Return False;
	EndIf;
	
	TypeDetails = New TypeDescription("Number");
	DescriptionOfServiceVersion0 = TypeDetails.AdjustValue(DescriptionOfServiceVersion[0]);
	DescriptionOfRequiredVersion0 = TypeDetails.AdjustValue(DescriptionOfRequiredVersion[0]);
	DescriptionOfServiceVersion1 = TypeDetails.AdjustValue(DescriptionOfServiceVersion[1]);
	DescriptionOfRequiredVersion1 = TypeDetails.AdjustValue(DescriptionOfRequiredVersion[1]);
	DescriptionOfServiceVersion2 = TypeDetails.AdjustValue(DescriptionOfServiceVersion[2]);
	DescriptionOfRequiredVersion2 = TypeDetails.AdjustValue(DescriptionOfRequiredVersion[2]);
	DescriptionOfServiceVersion3 = TypeDetails.AdjustValue(DescriptionOfServiceVersion[3]);
	DescriptionOfRequiredVersion3 = TypeDetails.AdjustValue(DescriptionOfRequiredVersion[3]);
	
	NumberAtLeast = False;
	If DescriptionOfServiceVersion0 > DescriptionOfRequiredVersion0 Then
		NumberAtLeast = True;
	ElsIf DescriptionOfServiceVersion0 = DescriptionOfRequiredVersion0 Then
		
		If DescriptionOfServiceVersion1 > DescriptionOfRequiredVersion1 Then
			NumberAtLeast = True;
		ElsIf DescriptionOfServiceVersion1 = DescriptionOfRequiredVersion1 Then
			
			If DescriptionOfServiceVersion2 > DescriptionOfRequiredVersion2 Then
				NumberAtLeast = True;
			ElsIf DescriptionOfServiceVersion2 = DescriptionOfRequiredVersion2 Then
				
				If DescriptionOfServiceVersion3 >= DescriptionOfRequiredVersion3 Then
					NumberAtLeast = True;
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return NumberAtLeast;
	
EndFunction

Function DocumentManagementWebServiceData(AddressOfDocumentManagementWebService, UserOfExchangeTask = False)
	
	WebServiceData = New Structure();
	
	WebServiceData.Insert("SecureConnection", Undefined);
	
	// If necessary, we will create a secure connection. We use certificates from the repository
	// Windows, if it makes sense for the current platform.
	ThisIsSSLConnection = StrStartsWith(AddressOfDocumentManagementWebService, "https");
	If ThisIsSSLConnection Then
		If ServerRunsUnderWindows() Then
			WebServiceData.SecureConnection = CommonClientServer.NewSecureConnection(
				New WindowsClientCertificate(),
				New WindowsCertificationAuthorityCertificates());
		Else
			WebServiceData.SecureConnection = CommonClientServer.NewSecureConnection();
		EndIf;
	EndIf;
	
	WebServiceData.Insert("InternetProxy", Undefined);
	
	IntegrationWith1CDocumentManagementCoreOverridable.WhenReceivingWSProxy(
		WebServiceData.InternetProxy);
	
	WebServiceData.Insert("Timeout", ServiceTimeout());
	WebServiceData.Insert("NameOfDocumentManagementWebService", NameOfDocumentManagementWebService());
	WebServiceData.Insert("AliasOfDocumentManagementWebService", AliasOfDocumentManagementWebService());
	WebServiceData.Insert(
		"URIOfNamespaceOfWorkflowWebService",
		URIOfNamespaceOfWorkflowWebService());
	
	WebServiceData.Insert("UserOfExchangeTask", UserOfExchangeTask);
	
	Return WebServiceData;
	
EndFunction

Procedure AddGenerationCommand(CommandsTable, Command, Handler, KindInCase, FunctionalOptions, Order,
		MultipleChoice)
	
	CreationBasedOnCommand = CommandsTable.Add();
	CreationBasedOnCommand.Handler = Handler;
	CreationBasedOnCommand.Id = Command.Name;
	CreationBasedOnCommand.Presentation = Command.Synonym;
	CreationBasedOnCommand.WriteMode = ?(KindInCase = "DOCUMENT", "Write", "Write");
	CreationBasedOnCommand.FunctionalOptions = FunctionalOptions;
	CreationBasedOnCommand.Order = Order;
	CreationBasedOnCommand.MultipleChoice = MultipleChoice;
	
	Order = Order - 1;
	
EndProcedure

Procedure AddCommandFiles(Form, Val CommandLocation)
	
	If CommandLocation = Undefined Then
		CommandLocation = Form.CommandBar;
	EndIf;
	
	CommandName = "IntegrationWith1CDocumentManagement_Files";
	
	If Form.Commands.Find(CommandName) = Undefined Then
		FormCommand = Form.Commands.Add(CommandName);
		FormCommand.Action = "Attachable_ExecuteIntegrationCommand";
		SSLVersion = StandardSubsystemsServer.LibraryVersion();
		If CommonClientServer.CompareVersions(SSLVersion, "3.1.9.64") < 0
				And Common.SubsystemExists("StandardSubsystems.FilesOperations") Then
			// The Command "Files" from the BSP can be output to the Form at the same time as the Command "Files" from the BID.
			// Change the name of the Command to avoid duplication.
			FormCommand.Title = NStr("vi = 'Các tệp DM';
									|ru = 'Файлы ДО';
									|en = 'DI files'; fa = 'DI files';
									|it = 'File DM';
									|pl = 'Pliki Document Management';
									|tr = 'İş Akışı dosyaları'");
		Else
			FormCommand.Title = NStr("vi = 'Tệp';
									|ru = 'Файлы';
									|en = 'Files'; fa = 'فایل‌ها';
									|it = 'Файлы';
									|pl = 'Files';
									|tr = 'Dosyalar'");
		EndIf;
		FormCommand.ToolTip = NStr("vi = 'Các tệp được lưu trong 1C:Document Management';
									|ru = 'Файлы, хранящиеся в 1С:Документооборот';
									|en = 'Files stored in 1C:Document Management'; fa = 'Files stored in 1C:Document Management';
									|it = 'File salvati in 1C:Document Management';
									|pl = 'Pliki, przechowywane w 1C:Document Management';
									|tr = '1C:Document Management''e depolanan dosyalar'");
		FormCommand.ModifiesStoredData = False;
		FormCommand.Representation = ButtonRepresentation.Text;
	EndIf;
	
	OriginalElementName = "IntegrationWith1CDocumentManagement_Files";
	
	TagName = OriginalElementName;
	While Form.Items.Find(TagName) <> Undefined Do
		TagName = Form.Items.Find(TagName).Name;
		Iterator_SSLy = StrReplace(TagName, OriginalElementName, "");
		Iterator_SSLy = Number(?(IsBlankString(Iterator_SSLy),"0",Iterator_SSLy));
		Iterator_SSLy = Iterator_SSLy + ?(Iterator_SSLy = 0, 2, 1);
		TagName = OriginalElementName + Format(Iterator_SSLy,"NG=0");
	EndDo;
	
	NewItem = Form.Items.Add(TagName, Type("FormButton"), CommandLocation);
	NewItem.Type = FormButtonType.Hyperlink;
	NewItem.CommandName = CommandName;
	
EndProcedure

Procedure AddTextOfErrorMessage(ErrorMessageText, Val Supplement)
	
	Supplement = StrReplace(Supplement, "{",
		"
		|{");
	Supplement = StrReplace(Supplement, "}",
		"}
		|");
	Supplement = StrReplace(Supplement, "\r\n", Chars.LF);
	Supplement = StrReplace(Supplement, "\n", Chars.LF);
	Supplement = StrReplace(Supplement, "&nbsp", Chars.NBSp);
	Supplement = TrimAll(Supplement);
	
	ErrorTextSeparator =
		"
		|
		|---------
		|
		|";
	If IsBlankString(ErrorMessageText) Then
		ErrorMessageText = Supplement;
	Else
		ErrorMessageText = ErrorMessageText + ErrorTextSeparator + Supplement;
	EndIf;
	
EndProcedure

// Checks The Presence Of The "Name" Attribute.
//
// Parameters:
//   ObjectIS - AnyRef - reference to the IP object.
//
// Returns:
//   Boolean
//
Function HasDescription(ObjectIS)
	
	If Not Common.IsReference(TypeOf(ObjectIS)) Then
		Return False;
	EndIf;
	
	HasDescription = False;
	
	MetadataObject = ObjectIS.Metadata();
	If Common.IsCatalog(MetadataObject) Then
		For Each Attribute In MetadataObject.StandardAttributes Do
			If Attribute.Name = "Description" Then
				HasDescription = True;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	Return HasDescription;
	
EndFunction

Function ValueOfEnumerationByNameOrSynonym(EnumManager, EnumValues, Val NameOrSynonymOfValue)
	
	EnumerationValue = Undefined;
	
	NameOrSynonymOfValue = TrimAll(NameOrSynonymOfValue);
	If NameOrSynonymOfValue <> "" Then
		If EnumValues.Find(NameOrSynonymOfValue) = Undefined Then
			For Each MetadataEnumValue In EnumValues Do
				If Upper(TrimAll(MetadataEnumValue.Synonym)) = Upper(NameOrSynonymOfValue) Then
					EnumerationValue = EnumManager[MetadataEnumValue.Name];
					Break;
				EndIf;
			EndDo;
		Else
			EnumerationValue = EnumManager[NameOrSynonymOfValue];
		EndIf;
	EndIf;
	
	Return EnumerationValue;
	
EndFunction

// Returns the name of the base type of the XDTO object.
//
// Parameters:
//   XDTOObjectType - XDTOObjectType - the type whose base type name you want to get.
//
// Returns:
//   String
//
Function NameOfBaseTypeXDTO(XDTOObjectType)
	
	BaseTypeXDTO = "";
	If TypeOf(XDTOObjectType) = Type("XDTOObjectType") And XDTOObjectType.BaseType <> Undefined Then
		BaseTypeXDTO = XDTOObjectType.BaseType.Name;
	EndIf;
	
	Return BaseTypeXDTO;
	
EndFunction

Function CertificateOwner(SignatureOwnerSDetails)
	
	Return StrTemplate("%1 ""%2""",
		ObjectTypePresentationXDTO(SignatureOwnerSDetails.Type),
		SignatureOwnerSDetails.Description);
	
EndFunction

// Checks whether it is necessary to output the command of attached files from the integration library with 1C:Document management.
//
// Parameters:
//   Form - ClientApplicationForm - the form being checked.
//
// Returns:
//   Boolean - The result of the check.
//
Function NeedToOutputTheAttachedFilesCommandDM(Form)
	
	Result = False;
	BSPFilesCommandIsDisplayed = False;
	
	Try
		
		FormNameArray = StrSplit(Form.FormName, ".");
		
		SSLVersion = StandardSubsystemsServer.LibraryVersion();
		If CommonClientServer.CompareVersions(SSLVersion, "3.1.9.64") >= 0
				And Common.SubsystemExists("StandardSubsystems.FilesOperations") Then
			
			ModuleFilesOperations = Common.CommonModule("FilesOperations");
			TypeName = IntegrationWith1CDocumentManagementCoreClientServer.TypeNameFromFullName(Form.FormName);
			CanAttachFilesToObject = ModuleFilesOperations.CanAttachFilesToObject(Type(TypeName));
			
			FormName = FormNameArray[FormNameArray.UBound()];
			
			If CanAttachFilesToObject
					And StrFind(FormName, "ListForm") = 0
					And StrFind(FormName, "ChoiceForm") = 0 Then
				// The "Files" Command from the BSP should be displayed on the Form. The Command from BID is not needed.
				BSPFilesCommandIsDisplayed = True;
			EndIf;
			
		EndIf;
		
		If Not BSPFilesCommandIsDisplayed Then
			// There is no command "Files" from the BSP on the Form. Let's check the need to output the "Files" command from the BID.
			ObjectName = StrTemplate("%1.%2", FormNameArray[0], FormNameArray[1]);
			Rules = IntegrationWith1CDocumentManagementCoreServerCall.FindCreateAppropriateRules(
				Undefined,
				ObjectName,
				False);
			Result = (Rules.Count() <> 0);
		EndIf;
		
	Except
		Result = False;
	EndTry;
	
	IntegrationWith1CDocumentManagementCoreOverridable.OnDetermineTheNeedToOutputTheAttachedFilesCommandDM(
		Form,
		Result);
	
	Return Result;
	
EndFunction

Procedure ProcessAddressOf1CDocumentManagementWebService(WebServiceAddress)
	
	// The address must end with "/".
	If ValueIsFilled(WebServiceAddress)
			And Right(WebServiceAddress, 1) <> "/"
			And Right(WebServiceAddress, 1) <> "\" Then
		WebServiceAddress = WebServiceAddress + "/";
	EndIf;
	
	// Remove the regional settings (for example, "/ru_EN/") from the address.
	If Right(WebServiceAddress, 4) = "/ru/" Or Right(WebServiceAddress, 4) = "/en/" Then
		WebServiceAddress = Left(WebServiceAddress, StrLen(WebServiceAddress) - 3);
	EndIf;
	RegionalSettings = Right(WebServiceAddress, 7);
	If Left(RegionalSettings, 1) = "/" And Right(RegionalSettings, 1) = "/" Then
		RegionalSettings = StrReplace(RegionalSettings, "/", "");
		ArrayToCheck = StrSplit(RegionalSettings, "_");
		If ArrayToCheck.Count() = 2
				And StrLen(ArrayToCheck[0]) = 2
				And Lower(ArrayToCheck[0]) = ArrayToCheck[0]
				And StrLen(ArrayToCheck[1]) = 2
				And Upper(ArrayToCheck[1]) = ArrayToCheck[1] Then
			WebServiceAddress = Left(WebServiceAddress, StrLen(WebServiceAddress) - 6);
		EndIf;
	EndIf;
	
EndProcedure

// Handler for filling in the IC object according to the data BEFORE.
//
// Parameters:
//   Source - DefinedType.IntegrationWith1CDocumentManagementDocumentsObjectsOverridable
//   FillingData - Arbitrary - The value that is used as the basis for filling in.
//   StandardProcessing - Boolean - indicates whether standard event processing is being performed.
//
Procedure FillingOfISObject(Source, FillingData, StandardProcessing)
	
	If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("Object1CDocumentManagement") Then
		Return;
	EndIf;
	
	// Fill in the details of the header.
	FillPropertyValues(Source, FillingData.AttributesValues);
	
	// Fill in the tabular parts.
	TablePartsMetadata = Source.Metadata().TabularSections;
	For Each AttributeValue In FillingData.AttributesValues Do
		If TypeOf(AttributeValue.Value) <> Type("Array")
				Or AttributeValue.Value.Count() = 0
				Or TablePartsMetadata.Find(AttributeValue.Key) = Undefined Then
			Continue;
		EndIf;
		TabPartIS = Source[AttributeValue.Key];
		TabPartIS.Clear();
		For Each String In AttributeValue.Value Do
			FillPropertyValues(TabPartIS.Add(), String);
		EndDo;
	EndDo;
	
EndProcedure

// checks whether the object supports 1C:Workflow storage of attached files.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   Type - String - XDTO is the type of Document flow object.
//
// Returns:
//   Boolean
//
Function ObjectDoesNotSupportFiles(Proxy, Type)
	
	XDTODataObject = CreateObject(Proxy, Type);
	
	Return PropertyExists(XDTODataObject, "files");
	
EndFunction

Function DefiningWebServiceBEFORE(AddressOfDocumentManagementWebService, ServiceData_, UseNameOfWebService,
		AuthorizationSettings, ProxyLocation, ErrorMessageText)
	
	DefiningWebServiceBEFORE = CheckingConnectionByLoginPassword(
		AddressOfDocumentManagementWebService,
		ServiceData_,
		UseNameOfWebService,
		AuthorizationSettings.UserName,
		AuthorizationSettings.Password,
		ErrorMessageText);
	
	If DefiningWebServiceBEFORE = Undefined And Not ValueIsFilled(AuthorizationSettings.UserName) Then
		
		DefiningWebServiceBEFORE = CheckingConnectionViaJWT(
			AddressOfDocumentManagementWebService,
			ServiceData_,
			UseNameOfWebService,
			ProxyLocation,
			AuthorizationSettings.JWTAuthenticationIsUsed,
			ErrorMessageText);
		
	EndIf;
	
	If DefiningWebServiceBEFORE = Undefined And Not ValueIsFilled(AuthorizationSettings.UserName) Then
		
		DefiningWebServiceBEFORE = CheckingConnectionViaFA(
			AddressOfDocumentManagementWebService,
			ServiceData_,
			UseNameOfWebService,
			AuthorizationSettings.OSAuthenticationIsUsed,
			ErrorMessageText);
		
	EndIf;
	
	Return DefiningWebServiceBEFORE;
	
EndFunction

// Transfers the parameters of a long-running operation to the session parameters of a background job.
//
// Parameters:
//   TimeConsumingOperationParameters - See IntegrationWith1CDocumentManagementCore.TimeConsumingOperationParameters
//
Procedure ParametersOfLongTermOperationInSessionParameters(TimeConsumingOperationParameters)
	
	SessionParameters.IntegrationWith1CDocumentManagementWSDefinitions = TimeConsumingOperationParameters.IntegrationWith1CDocumentManagementWSDefinitions;
	SessionParameters.IntegrationWith1CDocumentManagementServiceVersion = TimeConsumingOperationParameters.IntegrationWith1CDocumentManagementServiceVersion;
	SessionParameters.IntegrationWith1CDocumentManagementUsername = TimeConsumingOperationParameters.IntegrationWith1CDocumentManagementUsername;
	SessionParameters.IntegrationWith1CDocumentManagementJWTTokenAuthenticationIsUsed = TimeConsumingOperationParameters.IntegrationWith1CDocumentManagementJWTTokenAuthenticationIsUsed;
	SessionParameters.IntegrationWith1CDocumentManagementOSAuthenticationIsUsed = TimeConsumingOperationParameters.IntegrationWith1CDocumentManagementOSAuthenticationIsUsed;
	SessionParameters.IntegrationWith1CDocumentManagementProxyServerLocation = TimeConsumingOperationParameters.IntegrationWith1CDocumentManagementProxyServerLocation;
	If TimeConsumingOperationParameters.IntegrationWith1CDocumentManagementPassword = Undefined Then
		SessionParameters.IntegrationWith1CDocumentManagementPassword = "";
	Else
		SessionParameters.IntegrationWith1CDocumentManagementPassword = TimeConsumingOperationParameters.IntegrationWith1CDocumentManagementPassword;
	EndIf;
	SessionParameters.IntegrationWith1CDocumentManagementPasswordIsKnown = TimeConsumingOperationParameters.IntegrationWith1CDocumentManagementPasswordIsKnown;
	SessionParameters.IntegrationWith1CDocumentManagementNode = TimeConsumingOperationParameters.IntegrationWith1CDocumentManagementNode;
	
EndProcedure

Function GetAndUpdateWSDefinitionCache(ServiceData_, WSDLLocation, UserName, Password,
		OSAuthenticationIsUsed = False, JWTAuthenticationIsUsed = False, ProxyLocation = Undefined)
	
	WSDLFileName = GetTempFileName("xml");
	ErrorMessageText = "";
	DefiningWebServiceBEFORE = Undefined;
	
	Try
		
		URIStructure = CommonClientServer.URIStructure(WSDLLocation);
		
		If Common.SubsystemExists("StandardSubsystems.GetFilesFromInternet") Then
			
			ModuleNetworkDownload = Common.CommonModule("GetFilesFromInternet");
			ModuleNetworkDownloadClientServer = Common.CommonModule(
				"GetFilesFromInternetClientServer");
			
			ReceivingParameters = ModuleNetworkDownloadClientServer.FileGettingParameters();
			ReceivingParameters.PathForSaving = WSDLFileName;
			ReceivingParameters.User = UserName;
			ReceivingParameters.Password = Password;
			ReceivingParameters.Port = URIStructure.Port;
			ReceivingParameters.Timeout = ServiceData_.Timeout;
			ReceivingParameters.SecureConnection = ServiceData_.SecureConnection;
			ReceivingParameters.UseOSAuthentication = OSAuthenticationIsUsed;
			
			DownloadResult = ModuleNetworkDownload.DownloadFileAtServer(
				WSDLLocation,
				ReceivingParameters,
				False);
			
		Else
			
			DownloadResult = DownloadFileAtServer(
				WSDLFileName,
				URIStructure,
				ServiceData_,
				UserName,
				Password,
				OSAuthenticationIsUsed);
			
		EndIf;
		
		If DownloadResult.Status Then
			SecureConnection = CommonClientServer.NewSecureConnection();
			DefiningWebServiceBEFORE = New WSDefinitions(WSDLFileName,,,, ServiceData_.Timeout, SecureConnection);
			If Not ServiceData_.UserOfExchangeTask Then
				WSDLData = New BinaryData(WSDLFileName);
				IntegrationWith1CDocumentManagementCoreServerCall.SetAuthorizationSettingsInSessionSettings(
					UserName,
					Password,
					OSAuthenticationIsUsed,
					JWTAuthenticationIsUsed,
					New ValueStorage(WSDLData),
					ProxyLocation);
			EndIf;
		Else
			MessageFromDownloadResult = DownloadResult.ErrorMessage;
			BeginningOfResponseBodyFromServer = StrFind(DownloadResult.ErrorMessage, "{""#exception""");
			If BeginningOfResponseBodyFromServer > 0 Then
				Try
					JSONString = StrReplace(Mid(DownloadResult.ErrorMessage, BeginningOfResponseBodyFromServer), "#", "x");
					JSONReader = New JSONReader;
					JSONReader.SetString(JSONString);
					MessageStructure = ReadJSON(JSONReader);
					JSONReader.Close();
					LongDesc = New Array;
					LongDesc.Add(MessageStructure.exception.descr);
					If MessageStructure.exception.Property("inner") Then
						LongDesc.Add(MessageStructure.exception.inner.descr);
					EndIf;
					MessageFromDownloadResult = StrConcat(LongDesc, Chars.LF);
				Except
					MessageFromDownloadResult = DownloadResult.ErrorMessage;
				EndTry;
			EndIf;
			ErrorMessageText = TrimAll(StrTemplate(
				NStr("vi = 'Không thể nhận WSDL tệp mô tả web-service 1C:Document management.
					|Địa chỉ WSDL tệp: %1.
					|Mã phản hồi của máy chủ: %2.
					|Thông báo về lỗi:
					|%3';
					|ru = 'Не удалось получить WSDL файл описания web-сервиса 1С:Документооборота.
					|Адрес WSDL файла: %1.
					|Код ответа сервера: %2.
					|Сообщение об ошибке:
					|%3';
					|en = 'Cannot get a WSDL file with the description of 1C:Document Management web service.
					|WSDL file address: %1.
					|Server response code: %2.
					|Error message:
					|%3'; fa = 'Cannot get a WSDL file with the description of 1C:Document Management web service.
					|WSDL file address: %1.
					|Server response code: %2.
					|Error message:
					|%3';
					|it = 'Не удалось получить WSDL файл описания web-сервиса 1С:Документооборота.
					|Адрес WSDL файла: %1.
					|Код ответа сервера: %2.
					|Сообщение об ошибке:
					|%3';
					|pl = 'Cannot get a WSDL file with the description of 1C:Document Management web service.
					|WSDL file address: %1.
					|Server response code: %2.
					|Error message:
					|%3';
					|tr = '1C:Document Management web hizmeti ayrıntılarının WSDL dosyası alınamadı.
					|WSDL dosya adresi: %1.
					|Sunucu yanıt kodu: %2.
					|Hata mesajı:
					|%3'"),
				WSDLLocation,
				DownloadResult.StatusCode,
				MessageFromDownloadResult));
		EndIf;
		
	Except
		
		ErrorMessageText = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		
	EndTry;
	
	Try
		
		WSDLFile = New File(WSDLFileName);
		If WSDLFile.Exists() Then
			DeleteFiles(WSDLFileName);
		EndIf;
		
	Except
		
		ErrorMessageText = ErrorMessageText
			+ ?(ErrorMessageText = "", "", Chars.LF)
			+ ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
	EndTry;
	
	If ErrorMessageText <> "" Then
		
		If DefiningWebServiceBEFORE = Undefined Then
			Raise ErrorMessageText;
		Else
			WriteLogEvent(
				EventLogEventName(),
				EventLogLevel.Error,,,
				ErrorMessageText);
		EndIf;
		
	EndIf;
	
	Return DefiningWebServiceBEFORE;
	
EndFunction

// Gets the version of the service by contacting it directly.
//
// Parameters:
//   FromBackgroundTask - Boolean - the function is started from a background job.
//   ErrorText - String - an implicit return value, the text of the error message
//     received when determining the service version.
//   AddressOfDocumentManagementWebService - String - the address of the web service BEFORE, or
//                                   - Undefined - indicates the need to use a previously saved address.
//
Function GetVersionByCallingService(FromBackgroundTask = False, ErrorText = "",
		AddressOfDocumentManagementWebService = Undefined)
	
	Try
		// When starting from a non-background job, we will try to get a proxy in the mode with the call of exceptions
		// to fill in the reused value.
		Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy(
			Not FromBackgroundTask, // Do not raise an exception for a background job.
			AddressOfDocumentManagementWebService);
	Except
		Proxy = GetProxy(False);
	EndTry;
	
	If Proxy = Undefined Then
		
		WriteWarning(NStr("vi = 'Dịch vụ không khả dụng';
							|ru = 'Сервис недоступен';
							|en = 'Service is not available'; fa = 'Service is not available';
							|it = 'Servizio non disponibile';
							|pl = 'Usługa jest niedostępna';
							|tr = 'Hizmet erişilmiyor'", Common.DefaultLanguageCode()));
		Return "0.0.0.0";
		
	Else
		
		Try
			
			Query = CreateObject(Proxy, "DMGetVersionRequest");
			Response = Proxy.execute(Query); // We don't use the Execute Request method. It requests the service version itself.
			If ValidateType(Proxy, Response, "DMError") Then
				ErrorText = Response.description;
				WriteLogEvent(
					EventLogEventName(),
					EventLogLevel.Error,,,
					ErrorText);
				Return "0.0.0.0";
			Else
				MessageText = StrTemplate(
					NStr("vi = 'Đã kết nối dịch vụ phiên bản %1';
						|ru = 'Подключен сервис версии %1';
						|en = 'Service of version %1 enabled'; fa = 'Service of version %1 enabled';
						|it = 'Servizio della versione %1 collegato';
						|pl = 'Jest podłączona usługa wersji %1';
						|tr = '%1sürüm hizmeti etkin'", Common.DefaultLanguageCode()),
					Response.versionNumber);
				WriteLogEvent(
					EventLogEventName(),
					EventLogLevel.Information,,,
					MessageText);
				Return Response.versionNumber;
			EndIf;
			
		Except
			
			WriteWarning(NStr("vi = 'Dịch vụ không khả dụng';
								|ru = 'Сервис недоступен';
								|en = 'Service is not available'; fa = 'Service is not available';
								|it = 'Servizio non disponibile';
								|pl = 'Usługa jest niedostępna';
								|tr = 'Hizmet erişilmiyor'", Common.DefaultLanguageCode()));
			Return "0.0.0.0";
			
		EndTry;
		
	EndIf;
	
EndFunction

// Returns a structure that describes the "subordinate" constants for the specified "parent" constant.
//
// Parameters:
//   NameOfParentConstant - String - the name of the constant as it is set in the configurator.
//   ValueOfParentConstant - Arbitrary - the value of the constant.
//
// Returns:
//   Structure - where the Key is the name of the subordinate constant, and the value corresponds to the value of the parent constant.
//
Function GetValidValuesOfSubordinateConstants(NameOfParentConstant, ValueOfParentConstant)
	
	Result = New Structure;
	TableOfConstants = DependenciesOfConstants();
	
	SubordinateConstants = TableOfConstants.FindRows(
		New Structure(
			"NameOfParentConstant, ValueOfParentConstant",
			NameOfParentConstant, ValueOfParentConstant));
	
	For Each TableRow In SubordinateConstants Do
		Result.Insert(TableRow.NameOfSubordinateConstant, TableRow.ValueOfSubordinateConstant);
	EndDo;
	
	Return Result;
	
EndFunction

Function GetProxyFromSessionParameters(RaiseException1 = True)
	
	WSDLFileName = GetTempFileName("xml");
	
	Try
		
		BinaryWSDLData = SessionParameters.IntegrationWith1CDocumentManagementWSDefinitions.Get(); // BinaryData
		BinaryWSDLData.Write(WSDLFileName);
		SecureConnection = CommonClientServer.NewSecureConnection();
		DefiningWebServiceBEFORE = New WSDefinitions(WSDLFileName,,,, ServiceTimeout(), SecureConnection);
		
		AddressOfDocumentManagementWebService = AddressOf1CDocumentManagementWebService();
		ServiceData_ = DocumentManagementWebServiceData(AddressOfDocumentManagementWebService);
		
		Proxy = New WSProxy(
			DefiningWebServiceBEFORE,
			ServiceData_.URIOfNamespaceOfWorkflowWebService,
			ServiceData_.NameOfDocumentManagementWebService,
			ServiceData_.NameOfDocumentManagementWebService + "Soap",
			ServiceData_.InternetProxy,
			ServiceData_.Timeout,
			ServiceData_.SecureConnection,
			SessionParameters.IntegrationWith1CDocumentManagementProxyServerLocation,
			SessionParameters.IntegrationWith1CDocumentManagementOSAuthenticationIsUsed);
		If Not SessionParameters.IntegrationWith1CDocumentManagementOSAuthenticationIsUsed
				And Not SessionParameters.IntegrationWith1CDocumentManagementJWTTokenAuthenticationIsUsed Then
			Proxy.User = SessionParameters.IntegrationWith1CDocumentManagementUsername;
			Proxy.Password = SessionParameters.IntegrationWith1CDocumentManagementPassword;
		EndIf;
		
	Except
		SessionParameters.IntegrationWith1CDocumentManagementPasswordIsKnown = False;
		Proxy = GetProxy(RaiseException1);
	EndTry;
	
	WSDLFile = New File(WSDLFileName);
	If WSDLFile.Exists() Then
		DeleteFiles(WSDLFileName);
	EndIf;
	
	Return Proxy;
	
EndFunction

Procedure CheckAlgorithm(Algorithm, ForbiddenLines, Exceptions, ErrorList, SuitableExceptions)
	
	For Each ForbiddenString In ForbiddenLines Do
		
		Position = StrFind(Algorithm, Lower(ForbiddenString));
		While Position <> 0 Do
			
			// Let's check for possible exceptions.
			IsException = False;
			For Each LineException In Exceptions Do
				LineException = Lower(LineException);
				ExceptionLength = StrLen(LineException);
				If Mid(Algorithm, Position - 1, ExceptionLength) = LineException
						Or Mid(Algorithm, Position, ExceptionLength) = LineException Then
					IsException = True;
					Break;
				EndIf;
			EndDo;
			
			If Not IsException And ErrorList.Find(StrTemplate("""%1""", ForbiddenString)) = Undefined Then
				ErrorList.Add(StrTemplate("""%1""", ForbiddenString));
				For Each LineException In Exceptions Do
					If SuitableExceptions.Find(StrTemplate("""%1""", LineException)) = Undefined Then
						SuitableExceptions.Add(StrTemplate("""%1""", LineException));
					EndIf;
				EndDo;
			EndIf;
			
			Position = StrFind(Algorithm, Lower(ForbiddenString), SearchDirection.FromBegin, Position + 1);
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Verifies one digital signature.
//
// Parameters:
//   RowData - FormDataTreeItem - See IntegrationWith1CDocumentManagementCoreClientServer.StructureOfSignatureTreeString
//   CryptoManager - CryptoManager - Cryptography Manager object.
//   MatchingObjectIDAndBinaryData - Map of KeyAndValue:
//     * Key - String - object identifier.
//     * Value - BinaryData - binary object data.
//   AddressOfObjectSBinaryData - See IntegrationWith1CDocumentManagementCoreClientServer.AddressOfObjectSBinaryData
//
Procedure VerifySingleSignature(RowData, CryptoManager, MatchingObjectIDAndBinaryData,
		AddressOfObjectSBinaryData)
	
	DSVerificationParameters = IntegrationWith1CDocumentManagementCoreClientServer.DSVerificationParameters(
		RowData,
		MatchingObjectIDAndBinaryData,
		AddressOfObjectSBinaryData);
	If DSVerificationParameters.Signature = Undefined Then
		Return;
	EndIf;
	
	ErrorDescription = "";
	If Common.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		ModuleDigitalSignature = Common.CommonModule("DigitalSignature");
		Try
			History = Not ModuleDigitalSignature.VerifySignature(
				CryptoManager,
				DSVerificationParameters.BinaryObjectData,
				DSVerificationParameters.Signature,
				ErrorDescription);
		Except
			History = True;
			ErrorDescription = NStr("vi = 'chưa chỉ ra bộ quản lý mã hóa';
									|ru = 'не указан менеджер криптографии';
									|en = 'crypto manager is not specified'; fa = 'crypto manager is not specified';
									|it = 'не указан менеджер криптографии';
									|pl = 'crypto manager is not specified';
									|tr = 'kripto yöneticisi belirtilmemiş'");
		EndTry;
	Else
		History = True;
		ErrorDescription = NStr("vi = 'không có phân hệ chuẩn ""Chữ ký điện tử""';
								|ru = 'отсутствует стандартная подсистема ""Электронная подпись""';
								|en = 'the standard ""Digital signature"" subsystem is missing'; fa = 'the standard ""Digital signature"" subsystem is missing';
								|it = 'отсутствует стандартная подсистема ""Электронная подпись""';
								|pl = 'the standard ""Digital signature"" subsystem is missing';
								|tr = 'Standart bir ""Elektronik İmza"" alt sistemi eksiktir'");
	EndIf;
	
	RowData.SignatureValidationDate = CurrentSessionDate();
	RowData.History = History;
	RowData.SignatureCorrect = Not History;
	RowData.Status = IntegrationWith1CDocumentManagementCoreClientServer.ItemInstanceStatus(History, ErrorDescription);
	RowData.WhoReceivedCertificateAndStatus = RowData.CertificateOwner + Chars.LF + RowData.Status;
	
EndProcedure

Function CheckingConnectionByLoginPassword(AddressOfDocumentManagementWebService, ServiceData_, UseNameOfWebService,
		UserName, Password, ErrorMessageText)
	
	DefiningWebServiceBEFORE = Undefined;
	
	If ValueIsFilled(UserName) Then
		Try
			WSDLLocation = StrTemplate("%1ws/%2?wsdl",
				AddressOfDocumentManagementWebService,
				?(UseNameOfWebService,
					ServiceData_.NameOfDocumentManagementWebService,
					ServiceData_.AliasOfDocumentManagementWebService));
			DefiningWebServiceBEFORE = GetAndUpdateWSDefinitionCache(
				ServiceData_,
				WSDLLocation,
				UserName,
				Password);
		Except
			DefiningWebServiceBEFORE = Undefined;
			AddTextOfErrorMessage(
				ErrorMessageText,
				ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		EndTry;
	EndIf;
	
	Return DefiningWebServiceBEFORE;
	
EndFunction

Function CheckingConnectionViaJWT(AddressOfDocumentManagementWebService, ServiceData_, UseNameOfWebService,
		ProxyLocation, JWTAuthenticationIsUsed, ErrorMessageText)
	
	DefiningWebServiceBEFORE = Undefined;
	
	TextOfAccessToken = TextOfAccessToken();
	
	If TextOfAccessToken <> "" Then
		Try
			ProxyLocation = StrTemplate("%1ws/%2?AccessToken=%3",
				AddressOfDocumentManagementWebService,
				?(UseNameOfWebService,
					ServiceData_.NameOfDocumentManagementWebService,
					ServiceData_.AliasOfDocumentManagementWebService),
				TextOfAccessToken);
			DefiningWebServiceBEFORE = GetAndUpdateWSDefinitionCache(
				ServiceData_,
				ProxyLocation + "&wsdl",
				"",
				"",
				False,
				True,
				ProxyLocation);
			JWTAuthenticationIsUsed = True;
		Except
			DefiningWebServiceBEFORE = Undefined;
			ProxyLocation = Undefined;
			AddTextOfErrorMessage(
				ErrorMessageText,
				ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		EndTry;
	EndIf;
	
	Return DefiningWebServiceBEFORE;
	
EndFunction

Function CheckingConnectionViaFA(AddressOfDocumentManagementWebService, ServiceData_, UseNameOfWebService,
		OSAuthenticationIsUsed, ErrorMessageText)
	
	DefiningWebServiceBEFORE = Undefined;
	
	If FAAuthenticationIsSupported() Then
		Try
			WSDLLocation = StrTemplate("%1ws/%2?wsdl",
				AddressOfDocumentManagementWebService,
				?(UseNameOfWebService,
					ServiceData_.NameOfDocumentManagementWebService,
					ServiceData_.AliasOfDocumentManagementWebService));
			DefiningWebServiceBEFORE = GetAndUpdateWSDefinitionCache(
				ServiceData_,
				WSDLLocation,
				"",
				"",
				True);
			OSAuthenticationIsUsed = True;
		Except
			DefiningWebServiceBEFORE = Undefined;
			AddTextOfErrorMessage(
				ErrorMessageText,
				ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		EndTry;
	EndIf;
	
	Return DefiningWebServiceBEFORE;
	
EndFunction

Function PathToPropsData(Attribute)
	
	If Attribute.Table <> "" Then
		Return Attribute.Table + "." + Attribute.Name;
	Else
		Return Attribute.Name;
	EndIf;
	
EndFunction

Function SeparatorForListItems()
	
	Return "<NextItemInList>";
	
EndFunction

Procedure CollapseFormPrintingCommands(FormPrintCommands)
	
	CommandsCount = FormPrintCommands.Count();
	If CommandsCount < 2 Then
		Return;
	EndIf;
	
	For Number = 1 To CommandsCount Do
		CommandBeingChecked = FormPrintCommands[CommandsCount - Number];
		For CurrentNumber = 0 To FormPrintCommands.Count() - 1 Do
			PrintCommand = FormPrintCommands[CurrentNumber];
			If FormPrintCommands.IndexOf(CommandBeingChecked) <> FormPrintCommands.IndexOf(PrintCommand)
					And CommandBeingChecked.Id = PrintCommand.Id
					And CommandBeingChecked.PrintManager = PrintCommand.PrintManager
					And CommandBeingChecked.AdditionalParametersInLine = PrintCommand.AdditionalParametersInLine Then
				FormPrintCommands.Delete(CommandBeingChecked);
				Break;
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

Function DownloadFileAtServer(WSDLFileName, URIStructure, ServiceData_, UserName, Password,
		OSAuthenticationIsUsed)
	
	DownloadResult = New Structure("Status, StatusCode, ErrorMessage", True, 200, "");
	
	Join = New HTTPConnection(
		URIStructure.Host,
		URIStructure.Port,
		UserName,
		Password,
		ServiceData_.InternetProxy,
		ServiceData_.Timeout,
		ServiceData_.SecureConnection,
		OSAuthenticationIsUsed);
	
	HTTPRequest = New HTTPRequest(URIStructure.PathAtServer);
	HTTPRequest.Headers.Insert("Accept-Charset", "utf-8");
	HTTPResponse = Join.Get(HTTPRequest, WSDLFileName);
	DownloadResult.StatusCode = HTTPResponse.StatusCode;
	
	If DownloadResult.StatusCode <> 200 Then
		DownloadResult.Status = False;
		DownloadResult.ErrorMessage = HTTPResponse.GetBodyAsString();
	EndIf;
	
	Return DownloadResult;
	
EndFunction

Function PropsSearchStructure(DataPath)
	
	SplitRow = StrSplit(DataPath, ".");
	If SplitRow.Count() = 1 Then
		TheStructureOfTheSearch = New Structure("Table, Name", "", SplitRow[0]);
	Else
		TheStructureOfTheSearch = New Structure("Table, Name", SplitRow[0], SplitRow[1]);
	EndIf;
	
	Return TheStructureOfTheSearch;
	
EndFunction

// Sets the reference of the new object according to the identifier in the additional properties.
//
// Parameters:
//   Object - DocumentObject
//          - CatalogObject - the object being recorded.
//
Procedure SetNewReferenceBeforeWritingObject(Object)
	
	If Not Object.AdditionalProperties.Property("ObjectIDDM")
			Or Not Object.Ref.IsEmpty()
			Or ValueIsFilled(Object.GetNewObjectRef()) Then
		Return;
	EndIf;
	
	ObjectIDDM = Object.AdditionalProperties.ObjectIDDM;
	
	UUID = New UUID(ObjectIDDM);
	FullName = Object.Metadata().FullName();
	Manager = Common.ObjectManagerByFullName(FullName);
	RefByUUID = Manager.GetRef(UUID);
	
	QueryText = StrReplace(
		"SELECT TOP 1
		|	FullName.Ref AS Ref
		|FROM
		|	&FullName AS FullName
		|WHERE
		|	FullName.Ref = &RefByUUID",
		"&FullName",
		FullName);
	Query = New Query(QueryText);
	Query.SetParameter("RefByUUID", RefByUUID);
	SetPrivilegedMode(True);
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Object.SetNewObjectRef(RefByUUID);
	EndIf;
	
EndProcedure

Function ElementOfIPCatalogByObjectIdentifierXDTO(ValueToFillIn, ObjectMetadata, ObjectManager,
		RefByUUID)
	
	Result = Undefined;
	
	If Not StringFunctionsClientServer.IsUUID(ValueToFillIn.ObjectIDDM)
			Or IsBlankString(ValueToFillIn.ObjectTypeDM) Then
		Return Result;
	EndIf;
	
	// It is possible that the matches were created by data synchronization and the Catalog item identifiers match.
	CatalogView = ObjectMetadata.Name;
	RefByUUID = ObjectManager.GetRef(
		New UUID(ValueToFillIn.ObjectIDDM));
	
	// An RLS exception is possible.
	Query = New Query(
		"SELECT TOP 1
		|	CatalogObject_.Ref AS Ref
		|FROM
		|	&Catalog AS CatalogObject_
		|WHERE
		|	CatalogObject_.Ref = &RefByUUID");
	Query.Text = StrReplace(
		Query.Text,
		"&Catalog",
		StrTemplate("Catalog.%1", CatalogView));
	Query.SetParameter("RefByUUID", RefByUUID);
	
	Error = Undefined;
	Try
		Selection = Query.Execute().Select();
	Except
		Error = ErrorInfo();
		ErrorPresentation = ErrorProcessing.DetailErrorDescription(Error);
		WriteLogEvent(
			EventLogEventName(),
			EventLogLevel.Error,,
			RefByUUID,
			ErrorPresentation);
	EndTry;
	
	If Error <> Undefined Then
		
		SetPrivilegedMode(True);
		Selection = Query.Execute().Select();
		
		If Selection.Next() Then
			Result = String(Selection.Ref);
			MessageText = StrTemplate(
				NStr("vi = 'Không đủ quyền để truy cập đến đối tượng này (%1).
					|Hãy liên hệ với người quản trị.';
					|ru = 'Недостаточно прав для доступа к этому объекту (%1).
					|Обратитесь к администратору.';
					|en = 'Insufficient rights to access this object (%1).
					|Contact your administrator.'; fa = 'Insufficient rights to access this object (%1).
					|Contact your administrator.';
					|it = 'Недостаточно прав для доступа к этому объекту (%1).
					|Обратитесь к администратору.';
					|pl = 'Niewystarczająco praw dla dostępu do tego obiektu (%1).
					|Zwróć się do administratora.';
					|tr = 'Bu nesneye (%1) erişim için yetersiz yetki.
					|Yönetici ile iletişime geçin.'"),
				Result);
			Raise MessageText; // Detailed information is in the registration log.
		EndIf;
		
	EndIf;
	
	If Selection.Next() Then
		// The object has been found.
		Result = Selection.Ref;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion
