////////////////////////////////////////////////////////////////////////////////
// Subsystem "Integration with 1C:Document management"
// Module integration1sdocumentworkingbazovaya functionality of the server call: server, server call
////////////////////////////////////////////////////////////////////////////////

#Region Internal

#Region AsynchronousOperations

// Records changes to the object in the Workflow in the background job.
//
// Parameters:
//   FormUniqueID - UUID - ID of the calling form.
//   RowObject - String - string Presentation of the XDTO object with stored data.
//
// Returns:
//   See TimeConsumingOperations.ExecuteInBackground
//
Function WriteObjectAsynchronously(FormUniqueID, RowObject) Export
	
	TimeConsumingOperationParameters = TimeConsumingOperationParameters();
	TimeConsumingOperationParameters.Insert("RowObject", RowObject);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(FormUniqueID);
	ExecutionParameters.WaitCompletion = 0; // Start immediately.
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Bản ghi đối tượng trong 1C:Document Management';
														|ru = 'Запись объекта в 1С:Документообороте';
														|en = 'Save the object in 1C:Document Management'; fa = 'Save the object in 1C:Document Management';
														|it = 'Запись объекта в 1С:Документообороте';
														|pl = 'Save the object in 1C:Document Management';
														|tr = '1C:Document Management''ta nesne kaydı'");
	
	Return TimeConsumingOperations.ExecuteInBackground(
		"IntegrationWith1CDocumentManagementCore.RecordObjectInBackground",
		TimeConsumingOperationParameters,
		ExecutionParameters);
	
EndFunction

// Determines whether the client application Form needs to be processed according to the service version BEFORE, or whether an exception should be raised.
//
// Parameters:
//   ErrorInfo - String
//                      - ErrorInfo - information about an error received during a long of operation.
//   MinVersionBefore - String - the minimum version of the service required for the Form to work correctly.
//
// Returns:
//   Boolean - True if the form needs to be processed. Otherwise, an exception will be thrown.
//
Function NeedToProcessForm(Val ErrorInfo, MinVersionBefore = "") Export
	
	ServiceVersion = IntegrationWith1CDocumentManagementCore.ServiceVersion();
	
	If Not IntegrationWith1CDocumentManagementCoreClientServer.ServiceIsAvailable(ServiceVersion) Then
		Return True;
		
	ElsIf MinVersionBefore <> ""
			And IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable(MinVersionBefore) Then
		Return True;
		
	Else
		If TypeOf(ErrorInfo) = Type("String") Then
			ErrorPresentation = ErrorInfo;
		ElsIf TypeOf(ErrorInfo) = Type("ErrorInfo") Then
			ErrorPresentation = ErrorProcessing.DetailErrorDescription(ErrorInfo);
		Else
			ErrorPresentation = String(ErrorInfo);
		EndIf;
		Raise ErrorPresentation;
		
	EndIf;
	
EndFunction

// returns the structure of parameters for accessing the 1C service:Workflow in the background task.
//
// Parameters:
//   UseCache - Boolean - when checking the possibility of authorization without a password, you do not need to use a cache.
//   AddressOfDocumentManagementWebService - String - the address of the web service BEFORE, or
//                                   - Undefined - indicates the need to use a previously saved address.
//
// Returns:
//   See IntegrationWith1CDocumentManagementCore.TimeConsumingOperationParameters
//
Function TimeConsumingOperationParameters(UseCache = True, AddressOfDocumentManagementWebService = Undefined) Export
	
	Return IntegrationWith1CDocumentManagementCore.TimeConsumingOperationParameters(
		UseCache,
		AddressOfDocumentManagementWebService);
	
EndFunction

// The function is executed once and starts the background task of connecting to the DO.
// if the background task was started earlier and hasn't been completed yet, it will return the Cur task
// without starting a new one.
//
// Parameters:
//   UserName - String - user name BEFORE.
//   Password - String - the user's password is UP TO.
//   FormUniqueID - UUID - ID of the calling form.
//   UseCache - Boolean - when checking the possibility of authorization without a password, you do not need to use a cache.
//   AddressOfDocumentManagementWebService - String - the address of the web service BEFORE, or
//                                   - Undefined - indicates the need to use a previously saved address.
//
// Returns:
//   Undefined - in case the connection was not performed.
//   See TimeConsumingOperations.ExecuteInBackground- in case the connection has started.
//
Function ConnectAndGetServiceVersionAsynchronously(UserName, Password,
		FormUniqueID = Undefined, UseCache = True,
		AddressOfDocumentManagementWebService = Undefined) Export
	
	If Not IntegrationWith1CDocumentManagementCore.UserIsAllowedToUseIntegration() Then
		Return Undefined;
	EndIf;
	
	Settings = UseIntegration();
	If Not Settings.UseIntegrationBefore2 And Not Settings.UseIntegrationBefore3
			And IntegrationWith1CDocumentManagementCore.AddressOf1CDocumentManagementWebService() = "" Then
		// Integration is not used at all. There is nothing to check.
		Return Undefined;
	EndIf;
	
	ConnectionOperation = SessionParameters.IntegrationWith1CDocumentManagementConnectingOperation.Get(); // See TimeConsumingOperations.ExecuteInBackground
	
	If ConnectionOperation = Undefined Then
		TaskIsRunning = False;
	Else
		Try
			TaskIsRunning = Not TimeConsumingOperations.JobCompleted(ConnectionOperation.JobID);
		Except
			TaskIsRunning = False;
		EndTry;
	EndIf;
	
	If Not TaskIsRunning Then
		ConnectionOperation = OperationOfConnectingAndGettingVersionOfService(
			UseCache,
			UserName,
			Password,
			FormUniqueID,
			AddressOfDocumentManagementWebService);
		SessionParameters.IntegrationWith1CDocumentManagementConnectingOperation = New ValueStorage(ConnectionOperation);
	EndIf;
	
	Return ConnectionOperation;
	
EndFunction

// Retrieves an object from the Workflow in the background task.
//
// Parameters:
//   FormUniqueID - UUID - ID of the calling form.
//   Type - String - the name of the type XDTO.
//   ID - String - the unique identifier of the object in the Document Flow.
//   Columns - Array of String - optional, the composition of the columns to be filled in.
//           - String - if the list of columns is separated by commas.
//   IntegrationRule - CatalogRef.RulesForIntegrationWith1CDocumentManagement3 - integration rule for
//     filling in the IP object.
//   ExternalIPObject - AnyRef - passed to fill in the externalObject property.
//
// Returns:
//   See TimeConsumingOperations.ExecuteInBackground
//
Function GetObjectAsynchronously(FormUniqueID, Type, ID, Columns = Undefined,
		IntegrationRule = Undefined, ExternalIPObject = Undefined) Export
	
	TimeConsumingOperationParameters = TimeConsumingOperationParameters();
	TimeConsumingOperationParameters.Insert("Type", Type);
	TimeConsumingOperationParameters.Insert("ID", ID);
	TimeConsumingOperationParameters.Insert("Columns", Columns);
	TimeConsumingOperationParameters.Insert("IntegrationRule", IntegrationRule);
	TimeConsumingOperationParameters.Insert("ExternalIPObject", ExternalIPObject);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(FormUniqueID);
	ExecutionParameters.WaitCompletion = 0; // Start immediately.
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Nhận dữ liệu từ 1C:Document Management';
														|ru = 'Получение данных из 1С:Документооборота';
														|en = 'Get data from 1C:Document Management'; fa = 'Get data from 1C:Document Management';
														|it = 'Получение данных из 1С:Документооборота';
														|pl = 'Get data from 1C:Document Management';
														|tr = '1C:Document Management üzerinden verilerin alınması'");
	
	Return TimeConsumingOperations.ExecuteInBackground(
		"IntegrationWith1CDocumentManagementCore.GetObjectInBackground",
		TimeConsumingOperationParameters,
		ExecutionParameters);
	
EndFunction

#EndRegion

#Region GeneralProceduresAndFunctions

// Gets the version of the service UP to.
//
// Returns:
//   String - service version.
//
Function ServiceVersion() Export
	
	Return IntegrationWith1CDocumentManagementCore.ServiceVersion();
	
EndFunction

// returns the lifetime of the access token to the 1C web service:Document flow in seconds.
//
// Returns:
//   Number
//
Function LifetimeOfAccessToken() Export
	
	Return 12*60*60; // The lifetime is 12 hours.
	
EndFunction

// Returns the data structure for filling in the IC object based on the object UP to.
//
// Parameters:
//   UIDRules - UUID - unique ID of the rule being used.
//   ObjectTypeDM - String - the name of the XDTO object type.
//   ObjectIDDM - String - ID of the document flow object.
//
// Returns:
//   See IntegrationWith1CDocumentManagementCore.DataForFillingInIntegratedObject
//
Function DataForFillingInIntegratedObject(UIDRules, ObjectTypeDM, ObjectIDDM) Export
	
	Return IntegrationWith1CDocumentManagementCore.DataForFillingInIntegratedObject(
		UIDRules,
		ObjectTypeDM,
		ObjectIDDM);
	
EndFunction

// Adds the connection of the IP object to the object BEFORE.
//
// Parameters:
//   ID - String - ID of the document flow object.
//   Type - String - XDTO is the type of Document flow object.
//   IntegratedObject - AnyRef - the IP object.
//   WhetherFilesAreAttached - Boolean - True if there are attached files in the DO.
//   AddVDOConnection - Boolean - True if you want to add a link on the BEFORE side.
//   RegisterForExchange - Boolean - True if it is required to register an IP object for exchange with DO.
//
Procedure AddLink(ID, Type, IntegratedObject, WhetherFilesAreAttached = Undefined,
		AddVDOConnection = True, RegisterForExchange = False) Export
	
	BeginTransaction();
	
	Try
		
		VDOConnectionIsCreatedAutomatically =
			IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("3.0.9.18");
		If AddVDOConnection Or Not VDOConnectionIsCreatedAutomatically Then
			Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
			
			Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMAddObjectLinkRequest");
			
			Query.ownerObject = IntegrationWith1CDocumentManagementCore.CreateExternalObject(
				Proxy,
				IntegratedObject);
			
			Query.linkedObject = IntegrationWith1CDocumentManagementCore.CreateObjectID(Proxy, ID, Type);
			
			Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
			IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Response);
		EndIf;
		
		InformationRegisters.ObjectsIntegratedWith1CDocumentManagement.AddLink(
			ID,
			Type,
			IntegratedObject,
			WhetherFilesAreAttached);
		
		If RegisterForExchange Then
			DocumentFlowNode = IntegrationWith1CDocumentManagementCoreCached.DocumentFlowNode();
			ExchangePlans.RecordChanges(DocumentFlowNode, IntegratedObject);
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		WriteLogEvent(
			IntegrationWith1CDocumentManagementCore.EventLogEventName(
				NStr("vi = 'Không thể thêm liên kết';
					|ru = 'Не удалось добавить связь';
					|en = 'Cannot add link'; fa = 'Cannot add link';
					|it = 'Non è stato possibile aggiungere il collegamento';
					|pl = 'Nie udało się dodać połączenia';
					|tr = 'Bağlantı eklenemedi'", Common.DefaultLanguageCode())),
			EventLogLevel.Error,,,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
		Raise ErrorProcessing.BriefErrorDescription(ErrorInfo());
		
	EndTry;
	
EndProcedure

// Gets the availability of the functionality of the version of the Document Management web service.
//
// Parameters:
//   ServiceVersion - String - a version of the Document Management web service containing the required functionality.
//
// Returns:
//   Boolean - True if the web Document Management service of the specified version is available.
//
Function FunctionalityOfServiceVersionIsAvailable(ServiceVersion = "") Export
	
	Return IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable(ServiceVersion);
	
EndFunction

// Records the error in the GR.
//
// Parameters:
//   ErrorText - String - error text.
//
Procedure WriteError(ErrorText) Export
	
	IntegrationWith1CDocumentManagementCore.WriteError(ErrorText);
	
EndProcedure

// Records the warning in the LR.
//
// Parameters:
//   WarningText - String - warning text.
//
Procedure WriteWarning(WarningText) Export
	
	IntegrationWith1CDocumentManagementCore.WriteWarning(WarningText);
	
EndProcedure

// Returns the name of the IP metadata object by its type.
//
// Parameters:
//   ObjectType - Type - the type of IP object.
//
// Returns:
//   String - object name.
//
Function NameOfMetadataObjectByType(ObjectType) Export
	
	Return Metadata.FindByType(ObjectType).FullName();
	
EndFunction

// Finds Attributes in the client application form that contain a link to an object that is integrated with 1C:Document management.
//
// Parameters:
//   Form - ClientApplicationForm - the form in which the Attribute is searched.
//         - See IntegrationWith1CDocumentManagementCoreClientServer.FormOfIntegratedObject
//   FormAttributes - Array of FormAttribute - list of all Attributes of the form.
//                  - Undefined - if the function call comes from the client, and it is impossible to get a list of Attributes.
//   TypeOfIntegratedObject - Type - the type of link you want to find on the form.
//                            - Undefined - if the type of the integrated object is not known in advance.
//
// Returns:
//   String - the name of the Attribute that contains a link to the integrated with 1C:Document management object.
//
Function NameOfAttributeOfObjectIntegratedWith1CDocumentManagement(Val Form, FormAttributes = Undefined,
		TypeOfIntegratedObject = Undefined) Export
	
	If FormAttributes = Undefined And TypeOf(Form) = Type("ClientApplicationForm") Then
		FormAttributes = Form.GetAttributes();
	EndIf;
	
	AttributeName = "";
	
	IntegrationWith1CDocumentManagementCoreServerCallOverridable.WhenDeterminingAttributeNameOfObjectIntegratedWith1CDocumentManagement(
		Form,
		FormAttributes,
		TypeOfIntegratedObject,
		AttributeName);
	If AttributeName <> "" Then
		Return AttributeName;
	EndIf;
	
	AllRefsType = Metadata.DefinedTypes.IntegrationWith1CWorkflowAllLinksOverridable.Type;
	
	MainObjectType = Undefined;
	TypeOfMainObjectIsAttachableToIntegration = False;
	NameOfMainObjectType = IntegrationWith1CDocumentManagementCoreClientServer.TypeNameFromFullName(
		Form.FormName,
		True,
		False);
	If NameOfMainObjectType <> "" Then
		MainObjectType = Type(NameOfMainObjectType);
		TypeOfMainObjectIsAttachableToIntegration = AllRefsType.ContainsType(MainObjectType);
	EndIf;
	
	AttributesThatStoreItem = New ValueTable;
	AttributesThatStoreItem.Columns.Add("AttributeName", New TypeDescription("String"));
	AttributesThatStoreItem.Columns.Add("Priority", New TypeDescription("Number"));
	
	If (TypeOf(Form.Parameters) = Type("FormDataStructure") Or TypeOf(Form.Parameters) = Type("Structure"))
			And Form.Parameters.Property("Key") Then
		KeyType = TypeOf(Form.Parameters.Key);
		If Common.IsReference(KeyType) Then
			
			KeyTypeIsAttachableToIntegration = AllRefsType.ContainsType(KeyType);
			
			NewRow = AttributesThatStoreItem.Add();
			NewRow.AttributeName = "Parameters.Key";
			
			If TypeOfIntegratedObject <> Undefined And KeyType = TypeOfIntegratedObject Then
				NewRow.Priority = 0;
				
			ElsIf MainObjectType <> Undefined
					And TypeOfMainObjectIsAttachableToIntegration
					And KeyType = MainObjectType Then
				NewRow.Priority = 3;
				
			ElsIf Not TypeOfMainObjectIsAttachableToIntegration And KeyTypeIsAttachableToIntegration Then
				NewRow.Priority = 6;
				
			ElsIf MainObjectType <> Undefined And KeyType = MainObjectType Then
				NewRow.Priority = 9;
				
			Else
				NewRow.Priority = 12;
				
			EndIf;
			
		EndIf;
	EndIf;
	
	If TypeOf(FormAttributes) = Type("Array") Then
		For Each Attribute In FormAttributes Do
			If (TypeOf(Form[Attribute.Name]) = Type("FormDataStructure") Or TypeOf(Form[Attribute.Name]) = Type("Structure"))
					And Form[Attribute.Name].Property("Ref") = True Then
				
				ObjectIS = Form[Attribute.Name]; // DocumentObject
				NewRow = AttributesThatStoreItem.Add();
				NewRow.AttributeName = StrTemplate("%1.Ref", Attribute.Name);
				
				RefType = TypeOf(ObjectIS.Ref);
				LinkTypeIsAttachableToIntegration = AllRefsType.ContainsType(RefType);
				
				If TypeOfIntegratedObject <> Undefined And RefType = TypeOfIntegratedObject Then
					If Attribute.Name = "Object" Then
						NewRow.Priority = 1;
					Else
						NewRow.Priority = 2;
					EndIf;
					
				ElsIf MainObjectType <> Undefined
						And TypeOfMainObjectIsAttachableToIntegration
						And RefType = MainObjectType Then
					If Attribute.Name = "Object" Then
						NewRow.Priority = 4;
					Else
						NewRow.Priority = 5;
					EndIf;
					
				ElsIf Not TypeOfMainObjectIsAttachableToIntegration And LinkTypeIsAttachableToIntegration Then
					If Attribute.Name = "Object" Then
						NewRow.Priority = 7;
					Else
						NewRow.Priority = 8;
					EndIf;
					
				ElsIf MainObjectType <> Undefined And RefType = MainObjectType Then
					If Attribute.Name = "Object" Then
						NewRow.Priority = 10;
					Else
						NewRow.Priority = 11;
					EndIf;
					
				Else
					If Attribute.Name = "Object" Then
						NewRow.Priority = 13;
					Else
						NewRow.Priority = 14;
					EndIf;
					
				EndIf;
				
			EndIf;
		EndDo;
	EndIf;
	
	AttributesThatStoreItem.Sort("Priority");
	
	If AttributesThatStoreItem.Count() > 0 Then
		PriorityLines = AttributesThatStoreItem.FindRows(
			New Structure("Priority",
			AttributesThatStoreItem[0].Priority));
		If PriorityLines.Count() = 1 Then
			AttributeName = PriorityLines[0].AttributeName;
		EndIf;
	EndIf;
	
	Return AttributeName;
	
EndFunction

// Returns the name of the XDTO type by the type of the Integrated System object.
//
// Parameters:
//   TypeIS - String
//         - Type - the full name of the IP object type or the IP object type.
//
// Returns:
//   String - the name of the type XDTO.
//
Function TypeNameXDTO(TypeIS) Export
	
	ComplianceTable = IntegrationWith1CDocumentManagementCoreCached.MapTypes();
	
	If TypeOf(TypeIS) = Type("String") Then
		String = ComplianceTable.Find(TypeIS, "TypeNameIS");
	ElsIf TypeOf(TypeIS) = Type("Type") Then
		String = ComplianceTable.Find(TypeIS, "ObjectTypeIS");
	Else
		Return "";
	EndIf;
	
	If String = Undefined Then
		Return "";
	Else
		Return String["TypeNameXDTO"];
	EndIf;
	
EndFunction

// Returns the full name of the Integrated System object type by the type name XDTO.
//
// Parameters:
//   TypeNameXDTO - String - the name of the type XDTO.
//
// Returns:
//   String - the full name of the IP object type.
//
Function TypeNameIS(TypeNameXDTO) Export
	
	ComplianceTable = IntegrationWith1CDocumentManagementCoreCached.MapTypes();
	String = ComplianceTable.Find(TypeNameXDTO, "TypeNameXDTO");
	If String = Undefined Then
		Return "";
	Else
		Return String["TypeNameIS"];
	EndIf;
	
EndFunction

// Returns information about whether integration with 1C is enabled:Document management.
//
// Returns:
//   Structure:
//     * UseIntegrationBefore2 - Boolean
//     * UseIntegrationBefore3 - Boolean
//
Function UseIntegration() Export
	
	Result = New Structure("UseIntegrationBefore2, UseIntegrationBefore3", False, False);
	
	If IntegrationWith1CDocumentManagementCore.ThereIsSubsystemUPTo2() Then
		ModuleIntegrationWith1CDocumentManagement = Common.CommonModule("IntegrationWith1CDocumentManagement");
		Result.UseIntegrationBefore2 = ModuleIntegrationWith1CDocumentManagement.UseIntegration();
	EndIf;
	If IntegrationWith1CDocumentManagementCore.ThereIsSubsystemUPTo3() Then
		ModuleIntegrationWith1CDocumentManagement3 = Common.CommonModule("IntegrationWith1CDocumentManagement3");
		Result.UseIntegrationBefore3 = ModuleIntegrationWith1CDocumentManagement3.UseIntegration();
	EndIf;
	
	Return Result;
	
EndFunction

// Checks whether integration is configured for the specified object of the integrated system.
//
// Parameters:
//   ObjectIS - DefinedType.IntegrationWith1CWorkflowAllLinksOverridable - the IC object being checked.
//   IntegrationRule - CatalogRef.RulesForIntegrationWith1CDocumentManagement
//                     - CatalogRef.RulesForIntegrationWith1CDocumentManagement3 - an implicitly returned value,
//     an integration rule suitable for an IC object.
//   CreateAutomatically - Boolean - create integration rules automatically if the procedure being overridden
//     Joining the Integration rule or integration rule is automatically written for this IP object.
//
// Returns:
//   Boolean
//
Function IntegrationConfiguredForObject(ObjectIS, IntegrationRule = Undefined,
		CreateAutomatically = True) Export
	
	Result = False;
	
	LinkedObjectBefore = InformationRegisters.ObjectsIntegratedWith1CDocumentManagement.ObjectDataUpToExternalObject(
		ObjectIS);
	If LinkedObjectBefore <> Undefined Then
		Result = True;
	Else
		Rules = FindCreateAppropriateRules(ObjectIS,, CreateAutomatically);
		If Rules.Count() > 0 Then
			Result = True;
			IntegrationRule = Rules[0];
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

// Returns an array of suitable integration rules, or creates new ones if they are missing, and if the IP object
// supports automatic creation of rules.
//
// Parameters:
//   ObjectIS - DefinedType.IntegrationWith1CWorkflowAllLinksOverridable - the IP object.
//   ObjectTypeIS - String - the type of IP object.
//   CreateAutomatically - Boolean - create integration rules automatically if the procedure being overridden
//     Joining the Integration rule or integration rule is automatically written for this IP object.
//
// Returns:
//   Array of Structure:
//     * Ref - CatalogRef.RulesForIntegrationWith1CDocumentManagement - the rule.
//     * ObjectPresentationDM - String - representation of the object BEFORE.
//     * ObjectPresentationIS - String - representation of the IP object.
//     * ObjectTypeDM - String - the object type is UP TO.
//     * ObjectTypeIS - String - the type of IP object.
//     * IDOfDocumentType - String - id of the document type BEFORE.
//     * TypeOfDocumentType - String - the type of document type BEFORE.
//
Function FindCreateAppropriateRules(ObjectIS = Undefined, ObjectTypeIS = Undefined,
		CreateAutomatically = True) Export
	
	Rules = New Array;
	
	If ObjectTypeIS = Undefined And Common.IsReference(TypeOf(ObjectIS)) Then
		ObjectTypeIS = ObjectIS.Metadata().FullName();
	EndIf;
	
	Settings = UseIntegration();
	
	If Settings.UseIntegrationBefore2 Then
		
		ModuleIntegrationWith1CDocumentManagementServerCall = Common.CommonModule(
			"IntegrationWith1CDocumentManagementServerCall");
		Rules = ModuleIntegrationWith1CDocumentManagementServerCall.SuitableRules(ObjectIS,,ObjectTypeIS);
		If Rules.Count() = 0 And CreateAutomatically Then
			// It is possible that the module being redefined contains automatic creation of rules for this type of IP object.
			CreatedRules = ModuleIntegrationWith1CDocumentManagementServerCall.CreateIntegrationRulesAutomatically(
				?(ValueIsFilled(ObjectTypeIS), ObjectTypeIS, ObjectIS));
			If CreatedRules.Count() = 1 Then
				Rules.Add(CreatedRules[0]);
			ElsIf CreatedRules.Count() > 1 Then
				Rules = ModuleIntegrationWith1CDocumentManagementServerCall.SuitableRules(ObjectIS,,ObjectTypeIS);
			EndIf;
		EndIf;
		
	ElsIf Settings.UseIntegrationBefore3 Then
		
		ModuleIntegrationWith1CWorkflow3ServerCall = Common.CommonModule(
			"IntegrationWith1CDocumentManagement3ServerCall");
		If ValueIsFilled(ObjectIS) Then
			Rules = ModuleIntegrationWith1CWorkflow3ServerCall.SuitableObjectIntegrationRules(
				ObjectIS,,
				True);
		ElsIf ValueIsFilled(ObjectTypeIS) Then
			Rules = ModuleIntegrationWith1CWorkflow3ServerCall.SuitableIntegrationRulesForTypeOfIPObject(
				ObjectTypeIS);
		EndIf;
		
	EndIf;
	
	Return Rules;
	
EndFunction

// Checks whether the user's password is known BEFORE. Returns True if the user's password is already known.
//
// Returns:
//   Boolean
//
Function PasswordKnown() Export
	
	Return IntegrationWith1CDocumentManagementCore.UserIsAllowedToUseIntegration()
		And SessionParameters.IntegrationWith1CDocumentManagementPasswordIsKnown;
	
EndFunction

// Returns the settings of the Workflow database.
//
// Returns:
//   See IntegrationWith1CDocumentManagementCoreCached.GetSettings
//
Function GetSettings() Export
	
	Return IntegrationWith1CDocumentManagementCoreCached.GetSettings();
	
EndFunction

// Marks an object for deletion or removes a mark.
//
// Parameters:
//   Objects - Array of Structure:
//     * ID - String
//     * Type - String
//
Procedure MarkForDeletionUncheckItems(Objects) Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	IntegrationWith1CDocumentManagementCore.MarkForDeletionUncheckItems(Proxy, Objects);
	
EndProcedure

// Checks the connection to the web service BEFORE and returns the result of the check.
//
// Parameters:
//   AuthorizationSettings - See IntegrationWith1CDocumentManagementCoreClientServer.AuthorizationSettingsIn1CDocumentManagement
//   ServiceAddress - String - the address of the web service BEFORE, or
//                - Undefined - indicates the need to use a previously saved address.
//   ErrorMessageText - String - implicitly returned value, error message text.
//   UserOfExchangeTask - Boolean - The call is made to configure the user of the exchange job.
//     the Cur user's session settings will not be changed.
//
// Returns:
//   Boolean - True if the connection was successful, and False otherwise.
//
Function TestConnection(AuthorizationSettings, Val ServiceAddress = Undefined,
		ErrorMessageText = "", UserOfExchangeTask = False) Export
	
	Proxy = IntegrationWith1CDocumentManagementCore.GetProxy(
		False,
		AuthorizationSettings,
		ServiceAddress,
		ErrorMessageText,
		UserOfExchangeTask);
	
	Return (Proxy <> Undefined);
	
EndFunction

// Gets the username BEFORE and password from the IS (in the web client - only the username). All parameters are
// implicitly returned values.
//
// Parameters:
//   AuthorizationSettings - See IntegrationWith1CDocumentManagementCoreClientServer.AuthorizationSettingsIn1CDocumentManagement
//   ComputerName - String - the name of the computer that stores part of the password, or:
//                 - Undefined - a sign that the password does not need to be restored.
//   PartOfVIBPassword - String - the part of the password stored in the IB.
//   PasswordPartTemporaryFile - String - the path to the temporary file with the other part of the password.
//
Procedure ReadAuthorizationSettings(AuthorizationSettings, Val ComputerName = Undefined, PartOfVIBPassword = "",
		PasswordPartTemporaryFile = "") Export
	
	AuthorizationSettings.UserName = Undefined;
	AuthorizationSettings.PasswordIsSaved = False;
	AuthorizationSettings.OSAuthenticationIsUsed = False;
	AuthorizationSettings.JWTAuthenticationIsUsed = False;
	
	If Not IntegrationWith1CDocumentManagementCore.UserIsAllowedToUseIntegration() Then
		Return;
	EndIf;
	
	// Let's choose a username and password recovery data, or at least a username. Priority is
	// given to data saved from the current computer to ensure recovery of a separately stored password.
	Query = New Query(
		"SELECT ALLOWED TOP 1
		|	AuthorizationSettingsIn1CDocumentManagement.UserName AS UserName,
		|	AuthorizationSettingsIn1CDocumentManagement.PasswordPartInInfobase AS PasswordPartInInfobase,
		|	AuthorizationSettingsIn1CDocumentManagement.PasswordPartTemporaryFile AS PasswordPartTemporaryFile,
		|	AuthorizationSettingsIn1CDocumentManagement.OSAuthenticationIsUsed AS OSAuthenticationIsUsed,
		|	AuthorizationSettingsIn1CDocumentManagement.JWTAuthenticationIsUsed AS JWTAuthenticationIsUsed,
		|	CASE
		|		WHEN AuthorizationSettingsIn1CDocumentManagement.ComputerNameHash = &ComputerNameHash
		|			THEN 0
		|		ELSE 1
		|	END AS Priority
		|FROM
		|	InformationRegister.AuthorizationSettingsIn1CDocumentManagement AS AuthorizationSettingsIn1CDocumentManagement
		|WHERE
		|	AuthorizationSettingsIn1CDocumentManagement.User = &User
		|
		|ORDER BY
		|	Priority");
	If ComputerName = Undefined Then // Web client.
		Query.SetParameter("ComputerNameHash", 0);
	Else // We will restore the data for the password if the computer is the same, or at least the name.
		Query.SetParameter("ComputerNameHash", CRC32HashSum(ComputerName));
	EndIf;
	Query.SetParameter("User", Users.CurrentUser());
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		AuthorizationSettings.UserName = Selection.UserName;
		AuthorizationSettings.PasswordIsSaved = ValueIsFilled(Selection.PasswordPartTemporaryFile);
		PartOfVIBPassword = Selection.PasswordPartInInfobase;
		PasswordPartTemporaryFile = Selection.PasswordPartTemporaryFile;
		AuthorizationSettings.OSAuthenticationIsUsed = Selection.OSAuthenticationIsUsed;
		AuthorizationSettings.JWTAuthenticationIsUsed = Selection.JWTAuthenticationIsUsed;
	EndIf;
	
EndProcedure

// Reads authorization settings UP to from session parameters.
//
// Parameters:
//   OSAuthenticationIsUsed - Boolean - True if operating system authentication is used.
//   JWTAuthenticationIsUsed - Boolean - True if authentication via JWT tokens is used.
//
Procedure ReadAuthorizationSettingsFromSessionParameters(OSAuthenticationIsUsed,
		JWTAuthenticationIsUsed) Export
	
	OSAuthenticationIsUsed = SessionParameters.IntegrationWith1CDocumentManagementOSAuthenticationIsUsed;
	JWTAuthenticationIsUsed = SessionParameters.IntegrationWith1CDocumentManagementJWTTokenAuthenticationIsUsed;
	
EndProcedure

// Retrieves authorization settings in UP TO from the old repository (from the repository of general settings).
//
// Parameters:
//   UserName - String - user name BEFORE.
//   Password - String - password.
//   PasswordIsSaved - Boolean - True if the password is saved.
//
Procedure ReadAuthorizationSettingsFromGeneralSettingsStore(UserName, Password, PasswordIsSaved) Export
	
	UserName = Common.CommonSettingsStorageLoad(
		"IntegrationWith1CDocumentManagement", "User", "");
	Password = Common.CommonSettingsStorageLoad(
		"IntegrationWith1CDocumentManagement", "Password", "");
	PasswordIsSaved = Common.CommonSettingsStorageLoad(
		"IntegrationWith1CDocumentManagement", "SavePassword", False);
	
EndProcedure

// Resets all saved connection parameters to BEFORE.
//
Procedure ResetInternetConnectionCache() Export
	
	SessionParameters.IntegrationWith1CDocumentManagementWSDefinitions = New ValueStorage(Undefined);
	SessionParameters.IntegrationWith1CDocumentManagementConnectingOperation = New ValueStorage(Undefined);
	SessionParameters.IntegrationWith1CDocumentManagementServiceVersion = "";
	SessionParameters.IntegrationWith1CDocumentManagementPasswordIsKnown = False;
	SessionParameters.IntegrationWith1CDocumentManagementUsername = "";
	SessionParameters.IntegrationWith1CDocumentManagementPassword = "";
	SessionParameters.IntegrationWith1CDocumentManagementJWTTokenAuthenticationIsUsed = False;
	SessionParameters.IntegrationWith1CDocumentManagementOSAuthenticationIsUsed = False;
	SessionParameters.IntegrationWith1CDocumentManagementProxyServerLocation = "";
	
	IntegrationWith1CDocumentManagementCore.UpdateReusedParameters();
	
EndProcedure

// Returns the abbreviated name of the integrated configuration for output in headers and decorations.
//
// Returns:
//   See IntegrationWith1CDocumentManagementCore.AbbreviatedNameOfConfiguration
//
Function AbbreviatedNameOfConfiguration() Export
	
	Return IntegrationWith1CDocumentManagementCore.AbbreviatedNameOfConfiguration();
	
EndFunction

// Saves the username BEFORE and, if necessary, the password.
//
// Parameters:
//   AuthorizationSettings - See IntegrationWith1CDocumentManagementCoreClientServer.AuthorizationSettingsIn1CDocumentManagement
//   ComputerName - String - the name of the computer where part of the password is stored, or:
//                 - Undefined - indicates that the password does not need to be saved.
//   PartOfVIBPassword - String - the password in whole or in part, stored in the IB.
//   PasswordPartTemporaryFile - String - the path to the temporary file with the other part of the password.
//
Procedure SaveAuthorizationSettings(Val AuthorizationSettings, Val ComputerName = Undefined,
		Val PartOfVIBPassword = "", Val PasswordPartTemporaryFile = "") Export
	
	If ComputerName = Undefined Then // Web client.
		PasswordIsSaved = False;
		ComputerNameHash = 0;
	Else
		PasswordIsSaved = True;
		ComputerNameHash = CRC32HashSum(ComputerName);
	EndIf;
	
	RecordSet = InformationRegisters.AuthorizationSettingsIn1CDocumentManagement.CreateRecordSet();
	RecordSet.Filter.User.Set(Users.CurrentUser());
	RecordSet.Filter.PasswordIsSaved.Set(PasswordIsSaved);
	RecordSet.Filter.ComputerNameHash.Set(ComputerNameHash);
	
	Record = RecordSet.Add();
	Record.User = Users.CurrentUser();
	Record.PasswordIsSaved = PasswordIsSaved;
	Record.ComputerNameHash = ComputerNameHash;
	
	Record.UserName = AuthorizationSettings.UserName;
	Record.PasswordPartInInfobase = PartOfVIBPassword; // Doesn't make sense for a web client.
	Record.PasswordPartTemporaryFile = PasswordPartTemporaryFile; // Doesn't make sense for a web client.
	Record.OSAuthenticationIsUsed = AuthorizationSettings.OSAuthenticationIsUsed;
	Record.JWTAuthenticationIsUsed = AuthorizationSettings.JWTAuthenticationIsUsed;
	
	RecordSet.Write();
	
EndProcedure

// Saves the username UP to for sharing and its password.
//
// Parameters:
//   UserName - String - the name of the user BEFORE to perform the data exchange.
//   Password - String - the password of this user.
//
Procedure SaveAuthorizationSettingsForExchange(Val UserName, Val Password) Export
	
	SetPrivilegedMode(True);
	Constants.IntegrationWith1CDocumentManagementUsernameForExchange.Set(UserName);
	Constants.IntegrationWith1CDocumentManagementPasswordForExchange.Set(Password);
	
EndProcedure

// Saves the indication of using OS authentication for the current user without changing the authorization settings
// 1C:Enterprises.
//
// Parameters:
//   ComputerName - String, Undefined - the name of the computer where part of the password is stored. Undefined indicates
//     working with a web client.
//   OSAuthenticationIsUsed - Boolean - True if operating system authentication is used.
//
Procedure SaveFAAuthenticationUsageSettings(ComputerName, OSAuthenticationIsUsed) Export
	
	If ComputerName = Undefined Then // Web client.
		PasswordIsSaved = False;
		ComputerNameHash = 0;
	Else
		PasswordIsSaved = True;
		ComputerNameHash = CRC32HashSum(ComputerName);
	EndIf;
	
	Record = InformationRegisters.AuthorizationSettingsIn1CDocumentManagement.CreateRecordManager();
	Record.User = Users.CurrentUser();
	Record.PasswordIsSaved = PasswordIsSaved;
	Record.ComputerNameHash = ComputerNameHash;
	
	Record.Read();
	
	Record.User = Users.CurrentUser();
	Record.PasswordIsSaved = PasswordIsSaved;
	Record.ComputerNameHash = ComputerNameHash;
	
	Record.OSAuthenticationIsUsed = OSAuthenticationIsUsed;
	
	Record.Write();
	
EndProcedure

// saves the sign of using jwt authentication for the Cur user without changing the authorization settings
// 1C:Enterprises.
//
// Parameters:
//   ComputerName - String, Undefined - the name of the computer where part of the password is stored. Undefined indicates
//     working with a web client.
//   JWTAuthenticationIsUsed - Boolean - True if authentication via JWT tokens is used.
//
Procedure SaveSettingsForUsingJWTAuthentication(ComputerName, JWTAuthenticationIsUsed) Export
	
	If ComputerName = Undefined Then // Web client.
		PasswordIsSaved = False;
		ComputerNameHash = 0;
	Else
		PasswordIsSaved = True;
		ComputerNameHash = CRC32HashSum(ComputerName);
	EndIf;
	
	Record = InformationRegisters.AuthorizationSettingsIn1CDocumentManagement.CreateRecordManager();
	Record.User = Users.CurrentUser();
	Record.PasswordIsSaved = PasswordIsSaved;
	Record.ComputerNameHash = ComputerNameHash;
	
	Record.Read();
	
	Record.User = Users.CurrentUser();
	Record.PasswordIsSaved = PasswordIsSaved;
	Record.ComputerNameHash = ComputerNameHash;
	
	Record.JWTAuthenticationIsUsed = JWTAuthenticationIsUsed;
	
	Record.Write();
	
EndProcedure

// Returns the type of the Integrated System object by the type name XDTO.
//
// Parameters:
//   TypeNameXDTO - String - the name of the type XDTO.
//
// Returns:
//   Type, Undefined - the type of IP object.
//
Function TypeIS(TypeNameXDTO) Export
	
	ComplianceTable = IntegrationWith1CDocumentManagementCoreCached.MapTypes();
	String = ComplianceTable.Find(TypeNameXDTO, "TypeNameXDTO");
	If String = Undefined Then
		Return Undefined;
	Else
		Return String["ObjectTypeIS"];
	EndIf;
	
EndFunction

// Deletes the authorization settings in the UP from the old repository (from the repository of general settings).
//
Procedure DeleteAuthorizationSettingsFromGeneralSettingsStore() Export
	
	SetPrivilegedMode(True);
	IBUser = InfoBaseUsers.CurrentUser();
	Common.CommonSettingsStorageDelete(
		"IntegrationWith1CDocumentManagement", "User", IBUser.Name);
	Common.CommonSettingsStorageDelete(
		"IntegrationWith1CDocumentManagement", "Password", IBUser.Name);
	Common.CommonSettingsStorageDelete(
		"IntegrationWith1CDocumentManagement", "SavePassword", IBUser.Name);
	
EndProcedure

// Deletes the object's relationship with the Workflow object.
//
// Parameters:
//   ID - String - ID of the document flow object.
//   Type - String - the XDTO type of the Workflow object.
//   IntegratedObject - DefinedType.IntegrationWith1CWorkflowAllLinksOverridable - a reference to the
//     system object.
//
Procedure DeleteLink(ID, Type, IntegratedObject) Export
	
	BeginTransaction();
	
	Try
		
		InformationRegisters.ObjectsIntegratedWith1CDocumentManagement.DeleteLink(ID, Type, IntegratedObject);
		
		Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
		
		Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMRemoveObjectLinkRequest");
		
		Query.ownerObject = IntegrationWith1CDocumentManagementCore.CreateExternalObject(
			Proxy,
			IntegratedObject);
		
		Query.linkedObject = IntegrationWith1CDocumentManagementCore.CreateObjectID(Proxy, ID, Type);
		
		Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
		IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Response);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		WriteLogEvent(
			IntegrationWith1CDocumentManagementCore.EventLogEventName(
				NStr("vi = 'Không thể xóa liên kết';
					|ru = 'Не удалось удалить связь';
					|en = 'Cannot remove link'; fa = 'Cannot remove link';
					|it = 'Non è stato possibile eliminare il collegamento';
					|pl = 'Nie udało się usunąć powiązania';
					|tr = 'Bağlantı silinemedi'", Common.DefaultLanguageCode())),
			EventLogLevel.Error,,,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
		Raise ErrorProcessing.BriefErrorDescription(ErrorInfo());
		
	EndTry;
	
EndProcedure

// Sets the service version to the session parameters.
//
// Parameters:
//   ServiceVersion - String, Undefined - the installed version of the service. Undefined indicates the need
//     to get the version of the service before installation.
//   ErrorText - String - an implicit return value, the text of the error message
//     received when determining the service version.
//
Procedure SetServiceVersionInSessionSettings(Val ServiceVersion = Undefined, ErrorText = "") Export
	
	If ServiceVersion = Undefined Then // We'll get it.
		IntegrationWith1CDocumentManagementCore.InstallServiceVersion(, ErrorText);
	Else
		SessionParameters.IntegrationWith1CDocumentManagementServiceVersion = ServiceVersion;
	EndIf;
	
	If SessionParameters.IntegrationWith1CDocumentManagementServiceVersion = "0.0.0.0" Then
		SessionParameters.IntegrationWith1CDocumentManagementPasswordIsKnown = False;
	EndIf;
	
EndProcedure

// Sets the authorization settings UP to in session parameters.
//
// Parameters:
//   UserName - String - user name BEFORE.
//   Password - String - the user's password is UP TO.
//   OSAuthenticationIsUsed - Boolean - True if operating system authentication is used.
//   JWTAuthenticationIsUsed - Boolean - True if authentication via JWT tokens is used.
//   WSDefinitions - ValueStorage - contains binary WSDL data describing the service BEFORE.
//   ProxyLocation - String - location of the 1C proxy service:Document management.
//
Procedure SetAuthorizationSettingsInSessionSettings(Val UserName, Val Password,
		Val OSAuthenticationIsUsed, Val JWTAuthenticationIsUsed,
		WSDefinitions = Undefined, ProxyLocation = Undefined) Export
	
	SessionParameters.IntegrationWith1CDocumentManagementPasswordIsKnown = True;
	SessionParameters.IntegrationWith1CDocumentManagementUsername = String(UserName);
	If Password = Undefined Then
		SessionParameters.IntegrationWith1CDocumentManagementPassword = "";
	Else
		SessionParameters.IntegrationWith1CDocumentManagementPassword = String(Password);
	EndIf;
	SessionParameters.IntegrationWith1CDocumentManagementOSAuthenticationIsUsed = OSAuthenticationIsUsed;
	SessionParameters.IntegrationWith1CDocumentManagementJWTTokenAuthenticationIsUsed = JWTAuthenticationIsUsed;
	
	If ValueIsFilled(ProxyLocation) Then
		SessionParameters.IntegrationWith1CDocumentManagementProxyServerLocation = ProxyLocation;
	Else
		SessionParameters.IntegrationWith1CDocumentManagementProxyServerLocation = "";
	EndIf;
	
	If WSDefinitions <> Undefined Then
		SessionParameters.IntegrationWith1CDocumentManagementWSDefinitions = WSDefinitions;
	EndIf;
	
	IntegrationWith1CDocumentManagementCore.UpdateReusedParameters(); // the Cur user may have been changed to.
	
EndProcedure

// Returns predefined expression templates in the embedded language.
//
// Returns:
//   Map of KeyAndValue:
//     * Key - String - the name of the template.
//     * Value - String - expression in the built-in language.
//
Function ExpressionTemplatesInEmbeddedLanguage() Export
	
	ExpressionTemplates = New Map;
	IntegrationWith1CDocumentManagementCoreServerCallOverridable.WhenDefiningExpressionTemplatesInEmbeddedLanguage(
		ExpressionTemplates);
	
	Return ExpressionTemplates;
	
EndFunction

// Returns True if the current user is the one under whom the exchange routine task is performed.
//
// Returns:
//   Boolean
//
Function ThisIsExchangeJobUser() Export
	
	SetPrivilegedMode(True);
	IBUser = InfoBaseUsers.CurrentUser();
	Try
		Jobs = ScheduledJobsServer.FindJobs(New Structure("Metadata",
			Metadata.ScheduledJobs.ExchangeDataWith1CDocumentManagement));
		If Jobs.Count() > 0 Then
			Return (Jobs[0].UserName = IBUser.Name);
		Else
			Return False;
		EndIf;
	Except
		Return False;
	EndTry;
	
EndFunction

#EndRegion

#Region RequestsToThe1CDocumentManagement

// Prepares data for selection from the list when processing the Auto-selection event for input fields.
//
// Parameters:
//   ValueTypes - String - XDTO class names separated by ';'.
//                - ValueList of String - list of XDTO types.
//                - Array of String - list of XDTO types.
//   ChoiceData - ValueList of Structure - list to fill in:
//     * ID - String
//     * type - String
//     * name - String
//     * presentation - String
//     * isNotAvailableAccordingCommunicationRules - Boolean
//   Text - String - A string of text entered in the input field.
//   StandardProcessing - Boolean - indicates whether standard event processing is being performed.
//   Filter - Structure - optional, additional selection.
//
Procedure DataForAutoMatching(ValueTypes, ChoiceData, Text, StandardProcessing, Filter = Undefined) Export
	
	ChoiceData = New ValueList;
	
	StandardProcessing = False;
	
	If StrLen(Text) < 2 Then
		Return;
	EndIf;
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	If TypeOf(ValueTypes) = Type("String") Then
		TypesArray = New Array;
		If StrFind(ValueTypes, ";") > 0 Then
			
			For Each TypeName In StrSplit(ValueTypes, ";") Do
				TypesArray.Add(TrimAll(TypeName));
			EndDo;
			
		ElsIf StrFind(ValueTypes, ",") > 0 Then
			
			For Each TypeName In StrSplit(ValueTypes, ",") Do
				TypesArray.Add(TrimAll(TypeName));
			EndDo;
			
		Else
			
			TypesArray.Add(TrimAll(ValueTypes));
			
		EndIf;
		
	ElsIf TypeOf(ValueTypes) = Type("ValueList") Then
		TypesArray = ValueTypes.UnloadValues();
		
	ElsIf TypeOf(ValueTypes) = Type("Array") Then
		TypesArray = ValueTypes;
		
	Else
		Raise StrTemplate(
			NStr("vi = 'Không thể chọn dữ liệu đối với kiểu: %1';
				|ru = 'Невозможно подобрать данные для типа: %1';
				|en = 'Cannot select data for the type: %1'; fa = 'Cannot select data for the type: %1';
				|it = 'Impossibile selezionare dati per il tipo: %1';
				|pl = 'Nie można wybrać danych dla tego typu: %1';
				|tr = 'Bu tür için veri alınamıyor: %1'"), String(ValueTypes));
		
	EndIf;
	
	For Each XDTOType In TypesArray Do
		
		If Not ValueIsFilled(XDTOType) Then
			Continue;
		EndIf;
		
		ListOfConditions = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListQuery");
		FilterConditions = ListOfConditions.conditions; // XDTOList
		
		AddSetOfSelectionCriteriaColumns(ListOfConditions.columnSet, XDTOType);
		
		Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
		Condition.property = "name";
		Condition.value = Text;
		
		FilterConditions.Add(Condition);
		
		SelectionOfCurrentEmployeesHasBeenEstablished = False;
		
		// We will impose an additional selection.
		If Filter <> Undefined Then
			For Each FIlterRow In Filter Do
				If FIlterRow.Key = "ContextOfCommunicationRules" Then
					// We supplement the selection conditions with the context of the communication rules.
					ModuleIntegrationWith1CDocumentManagement3 = Common.CommonModule("IntegrationWith1CDocumentManagement3");
					ModuleIntegrationWith1CDocumentManagement3.ToSupplementSelectionWithContextOfCommunicationRules(
						Proxy,
						FIlterRow.Value,
						FilterConditions);
				Else
					Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
					Condition.property = FIlterRow.Key;
					If TypeOf(FIlterRow.Value) = Type("Structure") Then
						Condition.value = IntegrationWith1CDocumentManagementCore.CreateObjectID(
							Proxy,
							FIlterRow.Value.ID,
							FIlterRow.Value.type);
					Else
						Condition.value = FIlterRow.Value;
					EndIf;
					FilterConditions.Add(Condition);
					If Lower(Condition.property) = "isactual" Then
						SelectionOfCurrentEmployeesHasBeenEstablished = True;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
		
		If XDTOType = "DMEmployee" And Not SelectionOfCurrentEmployeesHasBeenEstablished Then
			Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy,"DMObjectListCondition");
			Condition.property = "isActual";
			Condition.value = True;
			FilterConditions.Add(Condition);
		EndIf;
		
		// Let's limit the size of the list.
		If ListOfConditions.Properties().Get("limit") <> Undefined Then
			ListOfConditions.limit = IntegrationWith1CDocumentManagementCore.MaximumNumberOfSelectedObjects(
				XDTOType);
		EndIf;
		
		Result = IntegrationWith1CDocumentManagementCore.FindListOfObjects(
			Proxy,
			XDTOType,
			ListOfConditions);
		
		For Each Item In Result.items Do
			
			Name = Item.object.name + ?(Item.object.objectID.type = "DMBusinessProcessExecutorRole", " (role)", "");
			
			DataElement = New Structure;
			DataElement.Insert("ID", Item.object.objectID.ID);
			DataElement.Insert("type", Item.object.objectID.type);
			DataElement.Insert("presentation", Item.object.objectID.presentation);
			DataElement.Insert("name", Name);
			If IntegrationWith1CDocumentManagementCore.PropertySet(
					Item.object, "isNotAvailableAccordingCommunicationRules") Then
				DataElement.Insert("isNotAvailableAccordingCommunicationRules",
					Item.object.isNotAvailableAccordingCommunicationRules);
			Else
				DataElement.Insert("isNotAvailableAccordingCommunicationRules", False);
			EndIf;
			
			// Other properties that depend on the type (see Add to the list of selection conditions);
			For Each Column In ListOfConditions.columnSet Do
				Value = Item.object[Column];
				If TypeOf(Value) = Type("XDTODataObject") Then
					If IntegrationWith1CDocumentManagementCore.PropertySet(Value, "objectID") Then
						DataElement.Insert(Column, Value.name);
						DataElement.Insert(StrTemplate("%1ID", Column), Value.objectID.ID);
						DataElement.Insert(StrTemplate("%1Type", Column), Value.objectID.type);
					EndIf;
					Continue;
				EndIf;
				DataElement.Insert(Column, Value);
			EndDo;
			
			ItemPresentation = New FormattedString(
				Name,,
				?(DataElement.isNotAvailableAccordingCommunicationRules,
					StyleColors.UnavailableData,
					Undefined));
			
			ChoiceData.Add(DataElement, ItemPresentation);
			
		EndDo;
		
	EndDo;
	
EndProcedure

// gets the 1C object:The document flow associated with the configuration object-the consumer.
//
// Parameters:
//   ReferenceToExternalObject - AnyRef - a reference to the consumer configuration object.
//   GetFromTO - Boolean - you need to get a link to the linked object on the Workflow side.
//   GetPersonalIncomeTax - Boolean - You need to get the State-based accessibility settings on the Workflow side.
//
// Returns:
//   See IntegrationWith1CDocumentManagementCore.ObjectDataUpToExternalObject
//
Function ObjectDataUpToExternalObject(ReferenceToExternalObject, GetFromTO = False, GetPersonalIncomeTax = False) Export
	
	Return IntegrationWith1CDocumentManagementCore.ObjectDataUpToExternalObject(
		ReferenceToExternalObject,
		GetFromTO,
		GetPersonalIncomeTax);
	
EndFunction

// Returns a list of values filled with the values of elements of the specified type, taking into account selections.
//
// Parameters:
//   TypeOfSelectionObject - String - the name of the XDTO class.
//   Filter - Structure - with an enumeration of properties and their values.
//
// Returns:
//   ValueList of Structure:
//     * AttributePresentation - String
//     * AttributeID - String
//     * AttributeType - String
//
Function ValuesForSelection(TypeOfSelectionObject, Filter = Undefined) Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	ListOfConditions = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListQuery");
	FilterConditions = ListOfConditions.conditions; // XDTOList
	
	If TypeOf(Filter) = Type("Structure") Then
		For Each FIlterRow In Filter Do
			Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
			Condition.property = FIlterRow.Key;
			
			If TypeOf(FIlterRow.Value) = Type("Structure") Then
				Condition.value = IntegrationWith1CDocumentManagementCore.CreateObjectID(
					Proxy,
					FIlterRow.Value.ID,
					FIlterRow.Value.type);
			Else
				Condition.value = FIlterRow.Value;
			EndIf;
			
			FilterConditions.Add(Condition);
		EndDo;
	EndIf;
	
	AddSetOfSelectionCriteriaColumns(ListOfConditions.columnSet, TypeOfSelectionObject);
	
	Result = IntegrationWith1CDocumentManagementCore.FindListOfObjects(
		Proxy,
		TypeOfSelectionObject,
		ListOfConditions);
	
	ChoiceList = New ValueList;
	
	For Each Item In Result.items Do
		
		// Standard properties.
		ChoiceStructure = New Structure;
		ChoiceStructure.Insert("AttributePresentation", Item.object.name);
		ChoiceStructure.Insert("AttributeID", Item.object.objectID.ID);
		ChoiceStructure.Insert("AttributeType", Item.object.objectID.type);
		
		// Other properties that depend on the type (see Add to the list of selection conditions);
		For Each Column In ListOfConditions.columnSet Do
			ChoiceStructure.Insert(Column, Item.object[Column]);
		EndDo;
		
		ChoiceList.Add(ChoiceStructure, Item.object.name);
		
	EndDo;
	
	Return ChoiceList;
	
EndFunction

// Searches for an object in UP by its type and by the exact coincidence of the name.
//
// Parameters:
//   ObjectType - String - the type of object to search for.
//   Name - String - the name of the object.
//
// Returns:
//   XDTODataObject, Undefined - XDTO Object of type DMObject. If the object is not found, it is returned Indefinitely.
//
Function FindVDOObjectByName(ObjectType, Name) Export
	
	FoundObject = Undefined;
	
	Settings = UseIntegration();
	
	If Settings.UseIntegrationBefore2 Then
		DataProcessorName = "IntegrationWith1CDocumentManagement";
	ElsIf Settings.UseIntegrationBefore3 Then
		DataProcessorName = "IntegrationWith1CDocumentManagement3";
	Else
		Return FoundObject;
	EndIf;
	
	// Let's define the search structure
	FilterName = New Structure;
	FilterName.Insert("Value", Name);
	FilterName.Insert("ComparisonOperator", "=");
	FilterName.Insert("Presentation", "Description");
	FilterName.Insert("ConditionPresentation", StrTemplate("= ""%1""", Name));
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("name", FilterName);
	
	// Let's perform a search
	AddressInTempStorage = "";
	NumberOfResults = 0;
	LimitNumberOfResults = 0;
	DataProcessors[DataProcessorName].PerformSearchByBankingDetails(
		ObjectType,
		FilterStructure1,
		AddressInTempStorage,
		NumberOfResults,
		LimitNumberOfResults);
	
	If NumberOfResults > 0 Then
		// Get the object
		SearchResults = GetFromTempStorage(AddressInTempStorage);
		Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
		FoundObject = IntegrationWith1CDocumentManagementCore.GetObject(
			Proxy,
			ObjectType,
			SearchResults.FoundObjects[0].ID);
	EndIf;
	
	Return FoundObject;
	
EndFunction

// Creates a new Document flow object according to the IP object and the specified rule.
//
// Parameters:
//   ObjectIS - AnyRef - the IP object, the data source of the filling.
//   Rule - CatalogRef.RulesForIntegrationWith1CDocumentManagement - filling rule.
//   LinksToCreation - Array of See IntegrationWith1CDocumentManagementCoreClientServer.ConnectionToCreation
//   PreliminaryDataInRepository - String - the address in the temporary storage containing
//     the structure See IntegrationWith1CDocumentManagement3.PreliminaryDataForUnloadingVDO
//
// Returns:
//   Structure:
//     * name - String
//     * ID - String
//     * type - String
//   The string is an error message.
//
Function CreateMapItemUsingRule(ObjectIS, Rule, LinksToCreation = Undefined,
		PreliminaryDataInRepository = Undefined) Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Settings = UseIntegration();
	If Settings.UseIntegrationBefore2 Then
		ModuleIntegrationWith1CDocumentManagement = Common.CommonModule("IntegrationWith1CDocumentManagement");
		ObjectDMOrMessage = ModuleIntegrationWith1CDocumentManagement.CreateMapItemUsingRule(
			Proxy,
			ObjectIS,
			Rule);
	ElsIf Settings.UseIntegrationBefore3 Then
		ModuleIntegrationWith1CDocumentManagement3 = Common.CommonModule("IntegrationWith1CDocumentManagement3");
		ObjectDMOrMessage = ModuleIntegrationWith1CDocumentManagement3.CreateMapItemUsingRule(
			Proxy,
			ObjectIS,
			Rule,
			LinksToCreation,
			PreliminaryDataInRepository);
	Else
		Return NStr("vi = 'Không sử dụng tích hợp với 1C:Document Management';
					|ru = 'Интеграция с 1С:Документооборот не используется';
					|en = 'Integration with 1C:Document Management is not used'; fa = 'Integration with 1C:Document Management is not used';
					|it = 'Nessuna integrazione con 1C:Document Management utilizzata';
					|pl = 'Integracja z 1C:Document Mangement nie jest używana';
					|tr = '1C:Document Management ile entegrasyon kullanılamıyor'");
	EndIf;
	
	If TypeOf(ObjectDMOrMessage) = Type("String") Then
		// We will return an error message.
		Return ObjectDMOrMessage;
	EndIf;
	
	Result = New Structure;
	Result.Insert("name", ObjectDMOrMessage.name);
	Result.Insert("ID", ObjectDMOrMessage.objectID.ID);
	Result.Insert("type", ObjectDMOrMessage.objectID.type);
	
	IntegrationWith1CDocumentManagementCoreClientServer.AddPersonalData(Result);
	IntegrationWith1CDocumentManagementCore.FillInPPEOfXDTOObject(Result, ObjectDMOrMessage);
	
	Return Result;
	
EndFunction

#EndRegion

#Region ProcessesAndTasks_

// Called when the state of the agreement changes to BEFORE. Changes the state on the IC side.
//
// Parameters:
//   Id - String - id of the linked object BEFORE.
//   Type - String - the type of the linked object BEFORE.
//   State - EnumRef.ApprovalStatesIn1CDocumentManagement - new state, or
//             - Undefined - when the agreement is interrupted.
//   CallingFromObjectForm - Boolean - True if the state change is caused by the user from the object form.
//   SubjectOfApproval - AnyRef - the agreed object, or
//                       - Undefined - a sign of the need to find the IP object by the object BEFORE.
//   Set - String - a representation of the user who has set the new state.
//   InstallationDate - Date - The date when the new state was set.
//
Procedure WhenApprovalStateChanges(Val Id, Val Type, Val State, Val CallingFromObjectForm,
		Val SubjectOfApproval = Undefined, Val Set = Undefined, Val InstallationDate = Undefined) Export
	
	RecordSet = InformationRegisters.ApprovalStatesIn1CDocumentManagement.CreateRecordSet();
	RecordSet.Filter.ObjectIDDM.Set(Id);
	
	If State <> Undefined Then // Undefined - deletion.
		Record = RecordSet.Add();
		Record.ObjectIDDM = Id;
		Record.State = State;
		If Set = Undefined Then
			Record.Set = String(Users.CurrentUser());
		Else
			Record.Set = Set;
		EndIf;
		If InstallationDate = Undefined Then
			Record.InstallationDate = CurrentSessionDate();
		Else
			Record.InstallationDate = InstallationDate;
		EndIf;
	EndIf;
	
	RecordSet.Write();
	
	// The reference to the subject in the IP may be unknown if the call is from the task form BEFORE. Let's define it.
	If SubjectOfApproval = Undefined Then
		Query = New Query(
			"SELECT ALLOWED TOP 1
			|	ObjectsIntegratedWith1CDocumentManagement.Object AS SubjectOfApproval
			|FROM
			|	InformationRegister.ObjectsIntegratedWith1CDocumentManagement AS ObjectsIntegratedWith1CDocumentManagement
			|WHERE
			|	ObjectsIntegratedWith1CDocumentManagement.ObjectTypeDM = &Type
			|	AND ObjectsIntegratedWith1CDocumentManagement.ObjectIDDM = &Id");
		Query.SetParameter("Type", Type);
		Query.SetParameter("Id", Id);
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			SubjectOfApproval = Selection.SubjectOfApproval;
		EndIf;
	EndIf;
	
	// On the IP side, you should not perform actions when coordinating unrelated objects BEFORE.
	If SubjectOfApproval <> Undefined Then
		IntegrationWith1CDocumentManagementCoreOverridable.WhenApprovalStateChanges(
			SubjectOfApproval,
			State,
			CallingFromObjectForm,
			Set,
			InstallationDate);
	EndIf;
	
EndProcedure

#EndRegion

#Region Files

// Returns a list of file versions by its ID.
//
// Parameters:
//   FileID - String - the unique ID of the workflow file.
//   IncludeMarkedForDeletion - Boolean - True if you need to get files without taking into account the tag.
//
// Returns:
//   XDTOList - a list of XDTO objects of type DMObjectListItem.
//
Function FileVersions(FileID, IncludeMarkedForDeletion = False) Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
	Condition.property = "owner";
	Condition.value = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		FileID,
		"DMFile");
	
	ListOfConditions = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListQuery");
	FilterConditions = ListOfConditions.conditions; // XDTOList
	FieldsReceived = ListOfConditions.columnSet; // XDTOList
	
	FilterConditions.Add(Condition);
	
	FieldsReceived.Add("size");
	FieldsReceived.Add("creationDate");
	FieldsReceived.Add("modificationDate");
	FieldsReceived.Add("author");
	FieldsReceived.Add("extension");
	
	If IncludeMarkedForDeletion Then
		
		Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
		Condition.property = "ignoreDeletionMark";
		Condition.value = True;
		FilterConditions.Add(Condition);
		
		FieldsReceived.Add("deletionMark");
		
	EndIf;
	
	If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.4.9.1") Then
		FieldsReceived.Add("modificationDateUniversal");
		FieldsReceived.Add("comment");
	EndIf;
	
	If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("3.0.9.18") Then
		FieldsReceived.Add("number");
	EndIf;
	
	Result = IntegrationWith1CDocumentManagementCore.FindListOfObjects(
		Proxy,
		"DMFileVersion",
		ListOfConditions);
	
	Return Result.items;
	
EndFunction

// Retrieves the binary data of the file.
//
// Parameters:
//   ID - String - id of the file to get the data from.
//   UseVisualizationOfItemInstanceStamp - Boolean - it is required to get the binary data of the file with the visualization of the item instance stamp.
//
// Returns:
//   BinaryData - binary file data from the Workflow.
//
Function FileBinaryData(ID, UseVisualizationOfItemInstanceStamp = True) Export
	
	Files = CommonClientServer.ValueInArray(ID);
	BinaryFilesData = BinaryFilesData(Files, UseVisualizationOfItemInstanceStamp);
	
	Return BinaryFilesData[ID];
	
EndFunction

// Retrieves binary file data.
//
// Parameters:
//   Files - Array of String - array of file IDs to get data from.
//   UseVisualizationOfItemInstanceStamp - Boolean - it is required to get the binary data of the file with the visualization of the item instance stamp.
//
// Returns:
//   Map of KeyAndValue:
//     * Key - String - file identifier.
//     * Value - BinaryData - binary file data from the Workflow.
//
Function BinaryFilesData(Files, UseVisualizationOfItemInstanceStamp = True) Export
	
	BinaryFilesData = New Map;
	
	For Each XDTOFile In FilesData(Files, UseVisualizationOfItemInstanceStamp) Do
		BinaryFilesData.Insert(XDTOFile.objectID.ID, XDTOFile.binaryData);
	EndDo;
	
	Return BinaryFilesData;
	
EndFunction

// Returns True if there are stored files to the external object.
//
// Parameters:
//   ExternalObject - DefinedType.IntegrationWith1CWorkflowAllLinksOverridable - the object is the owner.
//
// Returns:
//   Boolean - True if there are stored files.
//
Function ThereAreStoredVISFiles(ExternalObject) Export
	
	ThereAreStoredFiles = False;
	
	IntegrationWith1CDocumentManagementCore.WhenDeterminingPresenceOfAttachedFiles(
		ExternalObject,
		ThereAreStoredFiles);
	
	Return ThereAreStoredFiles;
	
EndFunction

// Enters information about the object's signature into the Document management database.
//
// Parameters:
//   Description - String - the name of the object BEFORE.
//   ID - String - the ID of the object BEFORE.
//   Type - String - type of the XDTO object.
//   Encrypted - Boolean - the owner of the signature is encrypted.
//   SignaturesArray - Array of See IntegrationWith1CDocumentManagementCoreClientServer.SignatureData
//
Procedure EnterInformationAboutItemSignatures(Description, ID, Type, Encrypted, SignaturesArray) Export
	
	ObjectsSignatures = New Map;
	IntegrationWith1CDocumentManagementCoreClientServer.AddObjectCaptions(
		ObjectsSignatures,
		Description,
		ID,
		Type,
		Encrypted,
		SignaturesArray);
	EnterInformationAboutObjectSignatures(ObjectsSignatures);
	
EndProcedure

// Enters information about object signatures into the Document Management database.
//
// Parameters:
//   ObjectsSignatures - Map of KeyAndValue:
//     * Key - String - ID of the DO object that owns the signature.
//     * Value - See IntegrationWith1CDocumentManagementCoreClientServer.SignatureOwnerSDetails
//
Procedure EnterInformationAboutObjectSignatures(ObjectsSignatures) Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	ArrayOfXDTOObjects = New Array;
	For Each MapItem In ObjectsSignatures Do
		SignatureOwnerSDetails = MapItem.Value;
		XDTODataObject = IntegrationWith1CDocumentManagementCore.CreateXDTOObjectToSaveSignatures(
			Proxy,
			SignatureOwnerSDetails);
		ArrayOfXDTOObjects.Add(XDTODataObject);
	EndDo;
	
	If ArrayOfXDTOObjects.Count() > 0 Then
		IntegrationWith1CDocumentManagementCore.WriteObjects(Proxy, ArrayOfXDTOObjects);
	EndIf;
	
EndProcedure

// Fills in the fields of the specified file with the data of its owner on the DO side.
//
// Parameters:
//   ID - String - ID of the file BEFORE.
//
Procedure FillFileFieldsWithOwnerData(ID) Export
	
	If Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.0.15.1") Then
		MessageText = NStr("vi = 'Để điền tệp, cần có phiên bản 1C:Document Management không thấp hơn 2.0.15.1';
							|ru = 'Для заполнения файлов нужен 1С:Документооборот версии не ниже 2.0.15.1';
							|en = 'To fill in files, 1C:Document Management version should be not earlier than 2.0.15.1'; fa = 'To fill in files, 1C:Document Management version should be not earlier than 2.0.15.1';
							|it = 'Per la compilazione dei file è necessaria una versione di 1C:Document Management non precedente alla 2.0.15.1';
							|pl = 'Do wypełnienia plików jest potrzebny 1C:Document Management wersji nie niżej niż 2.0.15.1';
							|tr = 'Dosyaları doldurmak için 2.0.15.1''den düşük olmayan 1C:Document Management sürümü gerekmektedir'");
		Raise MessageText;
	EndIf;
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy,"DMAutoFillRequest");
	
	File = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMFile");
	File.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(Proxy, ID, "DMFile");
	File.name = "";
	
	Query.file = File;
	
	Result = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Result);
	
EndProcedure

// Populates the list of files by copying attached files or Files from an external object.
//
// Parameters:
//   ExternalObject - AnyRef - reference to the consumer object.
//   ID - String - ID of the document flow object.
//   Type - String - the XDTO type of the Workflow object.
//   Presentation - String - representation of the document flow object.
//   FormUniqueID - UUID - ID of the calling form.
//
Procedure FillFilesByCopying(ExternalObject, ID, Type, Presentation, FormUniqueID) Export
	
	FilesArray = GetStoredFiles(ExternalObject);
	
	For Each FileData In FilesArray Do
		
		// Let's put the File in a temporary storage.
		If FileData.Property("FileBinaryData") Then
			If TypeOf(FileData.FileBinaryData) = Type("String")
					And IsTempStorageURL(FileData.FileBinaryData) Then
				TempFileStorageAddress = FileData.FileBinaryData;
			Else // Binary data.
				TempFileStorageAddress =
					PutToTempStorage(FileData.FileBinaryData, FormUniqueID);
			EndIf;
		ElsIf FileData.Property("RefToBinaryFileData")
				And IsTempStorageURL(FileData.RefToBinaryFileData) Then
			TempFileStorageAddress = FileData.RefToBinaryFileData;
		Else
			Raise NStr("vi = 'Không thể xác định địa chỉ kho chứa tạm thời của tệp đính kèm';
						|ru = 'Не удалось определить адрес временного хранилища присоединенного файла';
						|en = 'Cannot determine a temporary storage address of the attachment '; fa = 'Cannot determine a temporary storage address of the attachment ';
						|it = 'Non è stato possibile definire l''indirizzo dell''archivio temporaneo del file allegato';
						|pl = 'Nie udało się określić adres tymczasowego repozytorium załączanego pliku';
						|tr = 'Ekli dosyanın geçici depolama adresi belirlenemedi'");
		EndIf;
		
		CurrentFile = IntegrationWith1CDocumentManagementCoreClientServer.FileData(
			FileData.Description,
			Undefined,
			"DMFile",
			FileData.Extension);
		CurrentFile.Size = FileData.Size;
		CurrentFile.ModificationDate = ToLocalTime(FileData.UniversalModificationDate);
		CurrentFile.UniversalModificationDate = FileData.UniversalModificationDate;
		If FileData.TextExtractionStatus = "Extracted" Then
			TextStorage = Common.ObjectAttributeValue(FileData.Ref, "TextStorage");
			If TypeOf(TextStorage) = Type("ValueStorage") Then
				CurrentFile.Text = TextStorage.Get();
			EndIf;
		EndIf;
		
		CreationParameters = IntegrationWith1CDocumentManagementCoreClientServer.NewFileCreationOptions(
			CurrentFile);
		CreationParameters.TempFileStorageAddress = TempFileStorageAddress;
		CreationParameters.Owner = ExternalObject;
		
		CreateFileInWorkflow(
			CreationParameters,
			ID,
			Type,
			Presentation);
		
	EndDo;
	
EndProcedure

// Captures a file in UP TO.
//
// Parameters:
//   Id - String - id of the file in UP to.
//   DateOfCapture - Date
//
Procedure CaptureFile(Val Id, Val DateOfCapture) Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMLockFileRequest");
	Query.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(Proxy, Id, "DMFile");
	Query.lockDate = DateOfCapture;
	Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Response);
	
EndProcedure

// Checks whether attached files are used BEFORE. Designed to determine the FO on the client.
//
// Returns:
//   Boolean
//
Function UseAttachedFiles1CDocumentManagement() Export
	
	Return IntegrationWith1CDocumentManagementCore.UseAttachedFiles1CDocumentManagement();
	
EndFunction

// Checks whether the attached files should be used BEFORE for the specified object. Returns
// True, if integration is configured, but the IP object does not have its own attached files.
//
// Parameters:
//   ObjectIS - DefinedType.IntegrationWith1CWorkflowAllLinksOverridable - the IC object being checked.
//   IntegrationRule - CatalogRef.RulesForIntegrationWith1CDocumentManagement
//                     - CatalogRef.RulesForIntegrationWith1CDocumentManagement3 - an implicitly returned value,
//     an integration rule suitable for an IC object.
//
// Returns:
//   Boolean - True if the attached files should be used BEFORE.
//
Function Use1CDocumentManagementAttachedFilesForTheObject(ObjectIS, IntegrationRule = Undefined) Export
	
	If Not UseAttachedFiles1CDocumentManagement() Then
		Return False;
	EndIf;
	
	IntegrationConfiguredForObject = IntegrationConfiguredForObject(ObjectIS, IntegrationRule, False);
	
	Settings = UseIntegration();
	
	If Settings.UseIntegrationBefore2 Then
		
		If Not IntegrationConfiguredForObject Then
			Return False;
		EndIf;
		
		Return Not ThereAreStoredVISFiles(ObjectIS);
		
	ElsIf Settings.UseIntegrationBefore3 Then
		
		Return IntegrationConfiguredForObject;
		
	EndIf;
	
EndFunction

// Returns the maximum allowed file size from the corresponding constant.
//
// Returns:
//   Number
//
Function MaximumFileSize_() Export
	
	SetPrivilegedMode(True);
	MaximumTransferFileSize = Constants.MaximumFileSizeForTransferIn1CDocumentManagement.Get();
	
	If MaximumTransferFileSize = Undefined Or MaximumTransferFileSize = 0 Then
		MaximumTransferFileSize = 10485760; // = 10 MB
		Constants.MaximumFileSizeForTransferIn1CDocumentManagement.Set(MaximumTransferFileSize);
	EndIf;
	
	Return MaximumTransferFileSize;
	
EndFunction

// Fills in the list of files in the document card.
//
// Parameters:
//   FilesTree - FormDataTree - the list to be filled in:
//     * Description - String
//     * PictureIndex - Number
//     * Size - Number
//     * CreationDate - Date
//     * SignedWithDS - Boolean
//     * Author - String
//     * ModificationDate - Date
//     * IsBeingEdited - Boolean
//     * EditedByCurUser - Boolean
//     * LongDesc - String
//     * Extension - String
//     * Encrypted - Boolean
//     * IsOriginal - Boolean
//     * DeletionMark - Boolean
//     * TemplateID - String
//     * BeingEditedBy - String
//     * SignedEncryptedPictureNumber - Number
//     * ID - String
//     * Type - String
//     * FileRoleID - String
//     * RoleIsMandatory - Boolean
//   AvailableRoles - ValueList of String - The list that needs to be filled in contains
//     role IDs and Presentations.
//   XDTOFiles - XDTOList - A list of XDTO objects of the DMFile type.
//   UseFileRoles - Boolean - indicates whether file roles are used.
//   RolesOfXDTOFiles - XDTOList - a list of XDTO objects of the DMFileRole type.
//   ElementToUpdateHeader - FormGroup - a form element whose header needs to be supplemented
//     with the number of files.
//
Procedure UpdateFileTree(FilesTree, AvailableRoles, XDTOFiles, UseFileRoles = False,
		RolesOfXDTOFiles = Undefined, ElementToUpdateHeader = Undefined) Export
	
	AvailableRoles.Clear();
	
	CurCurrentUserAndEmployees =
		IntegrationWith1CDocumentManagementCoreCached.Current1CDocumentManagementUser();
	
	// Determine whether to display an empty file role.
	If UseFileRoles Then
		
		ThereAreFilesWithoutRole = False;
		For Each XDTOFile In XDTOFiles Do
			
			If Not IntegrationWith1CDocumentManagementCore.PropertySet(XDTOFile, "role") Then
				ThereAreFilesWithoutRole = True;
				Break;
			EndIf;
			
			FileRoleFound = False;
			For Each RoleOfXDTOFile In RolesOfXDTOFiles Do
				If RoleOfXDTOFile.objectID.id = XDTOFile.role.objectID.id Then
					FileRoleFound = True;
					Break;
				EndIf;
			EndDo;
			If Not FileRoleFound Then
				ThereAreFilesWithoutRole = True;
				Break;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	// At the first level of the tree, we will display the roles of the files.
	If UseFileRoles Then
		
		For Each RoleOfXDTOFile In RolesOfXDTOFiles Do
			NewRow = FilesTree.GetItems().Add();
			NewRow.PictureIndex = 2;
			NewRow.SignedEncryptedPictureNumber = -1;
			NewRow.Description = RoleOfXDTOFile.name;
			NewRow.ID = RoleOfXDTOFile.objectID.id;
			NewRow.Type = RoleOfXDTOFile.objectID.type;
			NewRow.RoleIsMandatory = RoleOfXDTOFile.required;
			
			AvailableRoles.Add(RoleOfXDTOFile.objectID.id, RoleOfXDTOFile.name);
		EndDo;
		
		If ThereAreFilesWithoutRole Then
			LineIsEmptyRole = FilesTree.GetItems().Add();
			LineIsEmptyRole.PictureIndex = 2;
			LineIsEmptyRole.SignedEncryptedPictureNumber = -1;
			LineIsEmptyRole.Description = "<>";
			LineIsEmptyRole.ID = "";
			LineIsEmptyRole.Type = "DMFileRole";
			LineIsEmptyRole.RoleIsMandatory = False;
		EndIf;
		
	EndIf;
	
	// At the second level of the tree we will display the files.
	For Each XDTOFile In XDTOFiles Do
		
		RootItem = FilesTree.GetItems();
		
		If UseFileRoles Then
			
			If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOFile, "role") Then
				
				FileRoleFound = False;
				
				For Each FileRoleString In FilesTree.GetItems() Do
					If FileRoleString.ID = XDTOFile.role.objectID.id Then
						RootItem = FileRoleString.GetItems();
						FileRoleFound = True;
						Break;
					EndIf;
				EndDo;
				
				If Not FileRoleFound Then
					RootItem = LineIsEmptyRole.GetItems();
				EndIf;
				
			Else
				
				RootItem = LineIsEmptyRole.GetItems();
				
			EndIf;
			
		EndIf;
		
		FillInFileListLine(RootItem.Add(), XDTOFile, CurCurrentUserAndEmployees);
		
	EndDo;
	
	// Add the number of files to the role headers.
	If UseFileRoles Then
		
		For Each FileRoleString In FilesTree.GetItems() Do
			NumberOfFilesInRole = FileRoleString.GetItems().Count();
			If NumberOfFilesInRole > 0 Then
				FileRoleString.Description = StrTemplate("%1 (%2)", FileRoleString.Description, NumberOfFilesInRole);
			EndIf;
		EndDo;
		
	EndIf;
	
	// Print the total number of files in the form header.
	If ElementToUpdateHeader <> Undefined Then
		
		FilesQuantity = XDTOFiles.Count();
		If FilesQuantity = 0 Then
			HeaderFiles = NStr("vi = 'Tệp';
								|ru = 'Файлы';
								|en = 'Files'; fa = 'فایل‌ها';
								|it = 'Файлы';
								|pl = 'Files';
								|tr = 'Dosyalar'");
		Else
			HeaderFiles = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Tệp (%1)';
					|ru = 'Файлы (%1)';
					|en = 'Files (%1)'; fa = 'Files (%1)';
					|it = 'File (%1)';
					|pl = 'Pliki (%1)';
					|tr = 'Dosyalar (%1)'"),
				FilesQuantity);
		EndIf;
		ElementToUpdateHeader.Title = HeaderFiles;
		
	EndIf;
	
EndProcedure

// Fills in the list of files in the document card.
//
// Parameters:
//   XDTOFiles - XDTOList - A list of XDTO objects of the DMFile type.
//   Files - FormDataCollection:
//     * ID - String
//     * Author - String
//     * TempFileStorageAddress - String
//     * UniversalModificationDate - Date
//     * CreationDate - Date
//     * Encrypted - Boolean
//     * PictureIndex - Number
//     * Description - String
//     * SignedEncryptedPictureNumber - Number
//     * LongDesc - String
//     * SignedWithDS - Boolean
//     * DeletionMark - Boolean
//     * Size - Number
//     * Extension - String
//     * IsBeingEdited - Boolean
//     * EditedByCurUser - Boolean
//     * Type - String
//     * TemplateID - String
//     * IsOriginal - Boolean
//   ElementToUpdateHeader - FormGroup - a form element whose header needs to be supplemented
//     with the number of files.
//
Procedure UpdateFileList(XDTOFiles, Files, ElementToUpdateHeader = Undefined) Export
	
	Files.Clear();
	
	CurCurrentUserAndEmployees =
		IntegrationWith1CDocumentManagementCoreCached.Current1CDocumentManagementUser();
	
	// Files.
	For Each XDTOFile In XDTOFiles Do
		FillInFileListLine(Files.Add(), XDTOFile, CurCurrentUserAndEmployees);
	EndDo;
	
	If ElementToUpdateHeader <> Undefined Then
		FilesQuantity = Files.Count();
		If FilesQuantity = 0 Then
			HeaderFiles = NStr("vi = 'Tệp';
								|ru = 'Файлы';
								|en = 'Files'; fa = 'فایل‌ها';
								|it = 'Файлы';
								|pl = 'Files';
								|tr = 'Dosyalar'");
		Else
			HeaderFiles = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Tệp (%1)';
					|ru = 'Файлы (%1)';
					|en = 'Files (%1)'; fa = 'Files (%1)';
					|it = 'File (%1)';
					|pl = 'Pliki (%1)';
					|tr = 'Dosyalar (%1)'"),
				FilesQuantity);
		EndIf;
		ElementToUpdateHeader.Title = HeaderFiles;
	EndIf;
	
EndProcedure

// Updates the file TO binary data previously placed in temporary storage.
//
// Parameters:
//   Parameters - Structure - file creation parameters, contains properties:
//     * CurrentFile - See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//     * FormUniqueID - UUID - ID of the calling form.
//     * EditingInformation - See IntegrationWith1CDocumentManagementCoreServerCall.GetInformationAboutEditingFile.
//     * TempFileStorageAddress - String - the address of the temporary storage containing binary data.
//     * UnlockFile - Boolean - True if the file should be released.
//     * UpdateEditInformation - Boolean - indicates whether the editing information should be updated.
//
// Returns:
//    Boolean - True if the file was placed successfully.
//
Function UpdateFileWithBinaryTemporaryStorageData(Val Parameters) Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	File = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMFile");
	File.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		Parameters.CurrentFile.ID,
		Parameters.CurrentFile.Type);
	File.name = ""; // the name does not change
	
	BinaryData = GetFromTempStorage(Parameters.TempFileStorageAddress);
	File.binaryData = BinaryData;
	If Not IsBlankString(Parameters.CurrentFile.Text) Then
		File.text = Parameters.CurrentFile.Text;
	EndIf;
	
	// In a web client without an extension, the size and date may be unknown on the client. We'll get it.
	If Not ValueIsFilled(Parameters.CurrentFile.Size) Then
		Parameters.CurrentFile.Size = BinaryData.Size();
	EndIf;
	SessionDate = CurrentSessionDate();
	If Not ValueIsFilled(Parameters.CurrentFile.ModificationDate) Then
		Parameters.CurrentFile.ModificationDate = SessionDate;
	EndIf;
	If Not ValueIsFilled(Parameters.CurrentFile.UniversalModificationDate) Then
		Parameters.CurrentFile.UniversalModificationDate = ToUniversalTime(SessionDate);
	EndIf;
	
	File.extension = Parameters.CurrentFile.Extension;
	File.size = Parameters.CurrentFile.Size;
	File.modificationDate = Parameters.CurrentFile.ModificationDate;
	File.modificationDateUniversal = Parameters.CurrentFile.UniversalModificationDate;
	If Parameters.Property("EditingInformation")
			And Parameters.EditingInformation.Property("VersionComment")
			And IntegrationWith1CDocumentManagementCore.PropertyExists(File, "comment") Then
		File.comment = Parameters.EditingInformation.VersionComment;
	EndIf;
	
	RecordingResult = IntegrationWith1CDocumentManagementCore.WriteObject(Proxy, File);
	
	If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.4.9.1") Then
		
		If Parameters.UnlockFile Then
			UnlockFile(Parameters.CurrentFile.ID);
		EndIf;
		
		If Parameters.UpdateEditInformation Then
			If Parameters.Property("EditingInformation") Then
				EditingInformation = Parameters.EditingInformation;
				
				If IntegrationWith1CDocumentManagementCore.ValidateType(
						Proxy, RecordingResult.objects[0], "DMObjectChangeResponseStructure") Then
					UpdatedFile = RecordingResult.objects[0].object;
				Else
					UpdatedFile = RecordingResult.objects[0];
				EndIf;
				
				EditingInformation.VersionID = UpdatedFile.activeVersion.objectID.ID;
			Else
				EditingInformation = GetInformationAboutEditingFile(
					Parameters.CurrentFile.ID,
					Parameters.CurrentFile.Type);
			EndIf;
			If EditingInformation.Saved_ Then
				EditingInformation.ForReading = Parameters.UnlockFile;
			Else
				EditingInformation.Saved_ = True;
				EditingInformation.Insert("ForReading", True);
				EditingInformation.Insert("InOwnerWorkingDirectory", False);
				EditingInformation.Insert("SaveDate", Parameters.CurrentFile.ModificationDate);
				EditingInformation.Insert("FullPath", Parameters.CurrentFile.FileName);
			EndIf;
			EditingInformation.Insert("Size", Parameters.CurrentFile.Size);
			EditingInformation.Insert("UniversalModificationDate", Parameters.CurrentFile.UniversalModificationDate);
			SaveFileEditingInformation(EditingInformation);
		EndIf;
		
	EndIf;
	
	Return True;
	
EndFunction

// Returns the structure of the file description from the Document Flow with binary data, if the
// address of the temporary storage for them is passed.
//
// Parameters:
//   ID - String - file identifier.
//   Form - ClientApplicationForm - if set, we put additional details on the form.
//   TempFileStorageAddress - String - the address for receiving binary data.
//
// Returns:
//   Structure - file description in BEFORE:
//     * Description - String
//     * Extension - String
//     * LongDesc - String
//     * Size - Number
//     * SignedWithDS - Boolean
//     * Encrypted - Boolean
//     * SignedEncryptedPictureNumber - Number
//     * Author - String
//     * ID - String
//     * CreationDate - Date
//     * IsBeingEdited - Boolean
//     * AddAttributes - XDTOList
//     * UniversalModificationDate - Date
//     * ModificationDate - Date
//     * AuthorOfModification - String
//     * IsOriginal - Boolean
//     * IsOriginalVisibility - Boolean
//     * IsOriginalViewOnly - Boolean
//     * Template - String
//     * TemplateID - String
//     * FileRole - String
//     * FileRoleID - String
//     * Code - String
//     * Project - String
//     * PresentationHTML - String
//     * PreviewCut - Boolean
//                          - Undefined
//     * ApplicationTasks - String
//     * StoreVersions - Boolean
//                     - Undefined
//     * CurrentVersionID - String
//                       - Undefined
//     * CurCurrentVersionNumber - String
//                          - Undefined
//     * CurrentVersionAuthor - String
//                          - Undefined
//     * CurVersionDateOfCreation - Date
//                                 - Undefined
//     * CurVersionDateOfChange - Date
//                                  - Undefined
//     * CurrentVersionSize - Number
//                           - Undefined
//     * ItemInstanceStatus - Number
//                - Undefined
//     * ItemInstanceStatusHint - String
//                         - Undefined
//     * InteractionStatus - Number
//                            - Undefined
//     * InteractionStatusHint - String
//                                     - Undefined
//     * Owner - String
//     * OwnerID - String
//     * OwnerType - String
//     * FileOwner - See InformationRegisters.ObjectsIntegratedWith1CDocumentManagement.ReferenceToIPObjectAccordingToDocumentManagementData
//     * BeingEditedBy - String
//     * BeingEditedByID - String
//     * BeingEditedByType - String
//     * LockedDate - Date
//     * Signatures - Array of See IntegrationWith1CDocumentManagementCoreClientServer.StructureOfSignature
//
Function FileDetails(ID, Form = Undefined, TempFileStorageAddress = "") Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	FieldsReceived = New Array;
	
	FieldsReceived.Add("objectID");
	FieldsReceived.Add("signed");
	FieldsReceived.Add("name");
	FieldsReceived.Add("size");
	FieldsReceived.Add("creationDate");
	FieldsReceived.Add("modificationDate");
	FieldsReceived.Add("modificationDateUniversal");
	FieldsReceived.Add("author");
	FieldsReceived.Add("extension");
	FieldsReceived.Add("description");
	FieldsReceived.Add("editing");
	FieldsReceived.Add("encrypted");
	FieldsReceived.Add("scannedOriginal");
	FieldsReceived.Add("template");
	FieldsReceived.Add("additionalProperties");
	// Getting binary data.
	If IsTempStorageURL(TempFileStorageAddress) Then
		FieldsReceived.Add("binaryData");
	EndIf;
	// Getting the owner of the file.
	If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.3.1.3") Then
		FieldsReceived.Add("owner");
	EndIf;
	// Getting information about editing.
	If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.4.9.1") Then
		FieldsReceived.Add("editingUser");
		FieldsReceived.Add("lockDate");
		FieldsReceived.Add("activeVersion");
	EndIf;
	
	If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("3.0.9.18") Then
		FieldsReceived.Add("htmlView");
		FieldsReceived.Add("htmlViewTruncated");
		FieldsReceived.Add("modificatedBy");
		FieldsReceived.Add("role");
		FieldsReceived.Add("signatureStatus");
		FieldsReceived.Add("signatureStatusDescription");
		FieldsReceived.Add("interactionStatus");
		FieldsReceived.Add("interactionStatusDescription");
		FieldsReceived.Add("tasksDescription");
		FieldsReceived.Add("storeVersions");
		FieldsReceived.Add("code");
		FieldsReceived.Add("project");
		FieldsReceived.Add("scannedOriginalEnabled");
		FieldsReceived.Add("scannedOriginalReadOnly");
	EndIf;
	
	If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("3.0.9.18") Then
		FieldsReceived.Add("signatures");
	Else
		FieldsReceived.Add("signatures.author");
		FieldsReceived.Add("signatures.date");
		FieldsReceived.Add("signatures.comment");
		FieldsReceived.Add("signatures.signature");
		FieldsReceived.Add("signatures.thumbprint");
		FieldsReceived.Add("signatures.lineNumber");
		FieldsReceived.Add("signatures.signer");
		FieldsReceived.Add("signatures.certificate");
		FieldsReceived.Add("signatures.signatureFileName");
	EndIf;
	
	FileInfo1 = FileInfo1(Proxy, ID, FieldsReceived);
	
	FileDetails = New Structure;
	
	FileDetails.Insert("Description", FileInfo1.name);
	FileDetails.Insert("Extension", FileInfo1.extension);
	FileDetails.Insert("LongDesc", FileInfo1.description);
	FileDetails.Insert("Size", FileInfo1.size);
	
	FileDetails.Insert("SignedWithDS", FileInfo1.signed);
	FileDetails.Insert("Encrypted", FileInfo1.encrypted);
	FileDetails.Insert("SignedEncryptedPictureNumber", SignedEncryptedPictureNumber(FileInfo1));
	
	FileDetails.Insert("ID", FileInfo1.objectID.ID);
	FileDetails.Insert("CreationDate", FileInfo1.creationDate);
	FileDetails.Insert("IsBeingEdited", FileInfo1.editing);
	FileDetails.Insert("AddAttributes", FileInfo1.additionalProperties);
	If IntegrationWith1CDocumentManagementCore.PropertySet(FileInfo1, "author") Then
		FileDetails.Insert("Author", FileInfo1.author.name);
	Else
		FileDetails.Insert("Author", "");
	EndIf;
	
	FileDetails.Insert("UniversalModificationDate", FileInfo1.modificationDateUniversal);
	FileDetails.Insert("ModificationDate", FileInfo1.modificationDate);
	If IntegrationWith1CDocumentManagementCore.PropertySet(FileInfo1, "modificatedBy") Then
		FileDetails.Insert("AuthorOfModification", FileInfo1.modificatedBy.name);
	Else
		FileDetails.Insert("AuthorOfModification", "");
	EndIf;
	
	FileDetails.Insert("IsOriginal", FileInfo1.scannedOriginal);
	If IntegrationWith1CDocumentManagementCore.PropertySet(FileInfo1, "scannedOriginalEnabled") Then
		FileDetails.Insert("IsOriginalVisibility", FileInfo1.scannedOriginalEnabled);
	Else
		FileDetails.Insert("IsOriginalVisibility", False);
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(FileInfo1, "scannedOriginalReadOnly") Then
		FileDetails.Insert("IsOriginalViewOnly", FileInfo1.scannedOriginalReadOnly);
	Else
		FileDetails.Insert("IsOriginalViewOnly", True);
	EndIf;
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(FileInfo1, "template") Then
		FileDetails.Insert("Template", FileInfo1.template.name);
		FileDetails.Insert("TemplateID", FileInfo1.template.objectID.ID);
	Else
		FileDetails.Insert("Template", "");
		FileDetails.Insert("TemplateID", "");
	EndIf;
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(FileInfo1, "role") Then
		FileDetails.Insert("FileRole", FileInfo1.role.name);
		FileDetails.Insert("FileRoleID", FileInfo1.role.objectID.ID);
	Else
		FileDetails.Insert("FileRole", "");
		FileDetails.Insert("FileRoleID", "");
	EndIf;
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(FileInfo1, "code") Then
		FileDetails.Insert("Code", FileInfo1.code);
	Else
		FileDetails.Insert("Code", "");
	EndIf;
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(FileInfo1, "project") Then
		FileDetails.Insert("Project", FileInfo1.project.name);
	Else
		FileDetails.Insert("Project", "");
	EndIf;
	
	// File preview.
	If IntegrationWith1CDocumentManagementCore.PropertySet(FileInfo1, "htmlView") Then
		FileDetails.Insert("PresentationHTML", FileInfo1.htmlView);
		FileDetails.Insert("PreviewCut", FileInfo1.htmlViewTruncated);
	Else
		FileDetails.Insert("PresentationHTML", "");
		FileDetails.Insert("PreviewCut", Undefined);
	EndIf;
	
	// Title of the application task command.
	If IntegrationWith1CDocumentManagementCore.PropertySet(FileInfo1, "tasksDescription") Then
		FileDetails.Insert("ApplicationTasks", FileInfo1.tasksDescription);
	Else
		FileDetails.Insert("ApplicationTasks", "");
	EndIf;
	
	// store versions.
	If IntegrationWith1CDocumentManagementCore.PropertySet(FileInfo1, "storeVersions") Then
		FileDetails.Insert("StoreVersions", FileInfo1.storeVersions);
	Else
		FileDetails.Insert("StoreVersions", Undefined);
	EndIf;
	
	// the Cur version.
	If IntegrationWith1CDocumentManagementCore.PropertySet(FileInfo1, "activeVersion") Then
		CurVersionOfXdto = FileInfo1.activeVersion;
		FileDetails.Insert("CurrentVersionID", CurVersionOfXdto.objectID.ID);
		If IntegrationWith1CDocumentManagementCore.PropertySet(CurVersionOfXdto, "number") Then
			FileDetails.Insert("CurCurrentVersionNumber", CurVersionOfXdto.number);
		Else
			FileDetails.Insert("CurCurrentVersionNumber", Undefined);
		EndIf;
		If IntegrationWith1CDocumentManagementCore.PropertySet(CurVersionOfXdto, "author") Then
			FileDetails.Insert("CurrentVersionAuthor", CurVersionOfXdto.author.name);
		Else
			FileDetails.Insert("CurrentVersionAuthor", Undefined);
		EndIf;
		If IntegrationWith1CDocumentManagementCore.PropertySet(CurVersionOfXdto, "creationDate") Then
			FileDetails.Insert("CurVersionDateOfCreation", CurVersionOfXdto.creationDate);
		Else
			FileDetails.Insert("CurVersionDateOfCreation", Undefined);
		EndIf;
		If IntegrationWith1CDocumentManagementCore.PropertySet(CurVersionOfXdto, "modificationDate") Then
			FileDetails.Insert("CurVersionDateOfChange", CurVersionOfXdto.modificationDate);
		Else
			FileDetails.Insert("CurVersionDateOfChange", Undefined);
		EndIf;
		If IntegrationWith1CDocumentManagementCore.PropertySet(CurVersionOfXdto, "size") Then
			FileDetails.Insert("CurrentVersionSize", CurVersionOfXdto.size);
		Else
			FileDetails.Insert("CurrentVersionSize", Undefined);
		EndIf;
	Else
		FileDetails.Insert("CurrentVersionID", Undefined);
		FileDetails.Insert("CurCurrentVersionNumber", Undefined);
		FileDetails.Insert("CurrentVersionAuthor", Undefined);
		FileDetails.Insert("CurVersionDateOfCreation", Undefined);
		FileDetails.Insert("CurVersionDateOfChange", Undefined);
		FileDetails.Insert("CurrentVersionSize", Undefined);
	EndIf;
	
	// the Status of the item instance file.
	If IntegrationWith1CDocumentManagementCore.PropertySet(FileInfo1, "signatureStatus") Then
		FileDetails.Insert("ItemInstanceStatus", FileInfo1.signatureStatus);
		FileDetails.Insert("ItemInstanceStatusHint", FileInfo1.signatureStatusDescription);
	Else
		FileDetails.Insert("ItemInstanceStatus", Undefined);
		FileDetails.Insert("ItemInstanceStatusHint", Undefined);
	EndIf;
	
	// the Status of the file interaction.
	If IntegrationWith1CDocumentManagementCore.PropertySet(FileInfo1, "interactionStatus") Then
		FileDetails.Insert("InteractionStatus", FileInfo1.interactionStatus);
		FileDetails.Insert("InteractionStatusHint", FileInfo1.interactionStatusDescription);
	Else
		FileDetails.Insert("InteractionStatus", Undefined);
		FileDetails.Insert("InteractionStatusHint", Undefined);
	EndIf;
	
	// Saving binary data.
	If IsTempStorageURL(TempFileStorageAddress) Then
		PutToTempStorage(FileInfo1.binaryData, TempFileStorageAddress);
	EndIf;
	
	// Getting the owner of the file.
	If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.3.1.3") Then
		FileDetails.Insert("Owner", FileInfo1.owner.name);
		FileDetails.Insert("OwnerID", FileInfo1.owner.objectID.ID);
		FileDetails.Insert("OwnerType", FileInfo1.owner.objectID.type);
		FileOwner = InformationRegisters.ObjectsIntegratedWith1CDocumentManagement.ReferenceToIPObjectAccordingToDocumentManagementData(
			FileInfo1.owner.objectID.ID,
			FileInfo1.owner.objectID.type);
		FileDetails.Insert("FileOwner", FileOwner);
	EndIf;
	
	// Getting information about editing.
	If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.4.9.1") Then
		If IntegrationWith1CDocumentManagementCore.PropertySet(FileInfo1, "editingUser") Then
			FileDetails.Insert("BeingEditedBy", FileInfo1.editingUser.name);
			FileDetails.Insert("BeingEditedByID", FileInfo1.editingUser.objectID.ID);
			FileDetails.Insert("BeingEditedByType", FileInfo1.editingUser.objectID.type);
		Else
			FileDetails.Insert("BeingEditedBy", "");
			FileDetails.Insert("BeingEditedByID", "");
			FileDetails.Insert("BeingEditedByType", "");
		EndIf;
		FileDetails.Insert("LockedDate", FileInfo1.lockDate);
	EndIf;
	
	Signatures = New Array;
	
	For Each XDTOSignature In FileInfo1.signatures Do
		Signatures.Add(IntegrationWith1CDocumentManagementCore.SignatureDataFromXDTO(XDTOSignature));
	EndDo;
	
	FileDetails.Insert("Signatures", Signatures);
	
	If Form <> Undefined Then
		DataProcessors.IntegrationWith1CDocumentManagementCore.PlaceAdditionalDetailsOnForm(
			Form,
			FileInfo1);
		DataProcessors.IntegrationWith1CDocumentManagementCore.SetNavigationLink(
			Form,
			FileInfo1);
	EndIf;
	
	Return FileDetails;
	
EndFunction

// Frees the file in UP TO.
//
// Parameters:
//   Id - String - id of the file in UP to.
//
Procedure UnlockFile(Val Id) Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMUnlockFileRequest");
	Query.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(Proxy, Id, "DMFile");
	Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Response);
	
EndProcedure

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
//   See IntegrationWith1CDocumentManagementCore.ParametersForTransferringFilesToDM
//
Function ParametersForTransferringFilesToDM(LinkData, AttachedVISFiles = Undefined,
		FileCatalogType = "Undefined", OwnerTypePresentation = "object_") Export
	
	Return IntegrationWith1CDocumentManagementCore.ParametersForTransferringFilesToDM(
		LinkData,
		AttachedVISFiles,
		FileCatalogType,
		OwnerTypePresentation);
	
EndFunction

// Retrieves the binary data of the file version and places it in temporary storage.
//
// Parameters:
//   ID - String - id of the file version.
//   UseVisualizationOfItemInstanceStamp - Boolean - it is required to get the binary data of the file with the visualization of the item instance stamp.
//   FormUniqueID - UUID - ID of the calling form.
//   DataCurrentFile - See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//
// Returns:
//   String - the address in the temporary storage with binary data of the file version.
//
Function GetVersionOfFileAndPutItInRepository(ID, UseVisualizationOfItemInstanceStamp, FormUniqueID,
		DataCurrentFile = Undefined) Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	FieldsReceived = New Array;
	FieldsReceived.Add("objectID");
	FieldsReceived.Add("name");
	FieldsReceived.Add("binaryData");
	FieldsReceived.Add("extension");
	FieldsReceived.Add("size");
	FieldsReceived.Add("modificationDateUniversal");
	FieldsReceived.Add("encrypted");
	If Not UseVisualizationOfItemInstanceStamp Then
		FieldsReceived.Add("withoutStampVisualization");
	EndIf;
	VersionData = IntegrationWith1CDocumentManagementCore.GetObject(
		Proxy,
		"DMFileVersion",
		ID,
		FieldsReceived);
	If DataCurrentFile <> Undefined Then
		DataCurrentFile.Size = VersionData.size;
		DataCurrentFile.UniversalModificationDate = VersionData.modificationDateUniversal;
		DataCurrentFile.Encrypted = VersionData.encrypted;
	EndIf;
	Address = PutToTempStorage(VersionData.binaryData, FormUniqueID);
	
	Return Address;
	
EndFunction

// Creates a new PDF document, fills it with data from the preview file.
//
// Parameters:
//   AddressInPreviewFileStorage - String - the address of the preview file in the temporary storage on the server.
//
// Returns:
//   PDFDocument
//   Undefined - if there is no file data in the temporary storage.
//
Function GetPDFDocument(AddressInPreviewFileStorage) Export
	
	FileData = GetFromTempStorage(AddressInPreviewFileStorage);
	If TypeOf(FileData) <> Type("BinaryData") Then
		Return Undefined;
	EndIf;
	
	MemoryStream = New MemoryStream;
	
	DataWriter = New DataWriter(MemoryStream);
	DataWriter.Write(FileData);
	DataWriter.Close();
	
	MemoryStream.Seek(0, PositionInStream.Begin);
	
	PDFDocument = New PDFDocument;
	PDFDocument.Read(MemoryStream);
	
	Return PDFDocument;
	
EndFunction

// Gets from TO information about editing the active version of the file or the specified version.
//
// Parameters:
//   Id - String - id of the file or version.
//   Type - String - DMFile or DMFileVersion.
//
// Returns:
//   Structure:
//     * VersionID - String - id of the saved file version (the same if the version is specified explicitly).
//     * Saved_ - Boolean - True if the file is saved on disk.
//     * SaveDate - Date - the date the file was saved to disk, if it is saved.
//     * FullPath - String - the full path to the file on disk, if it is saved.
//     * RecommendedFolder - String - the recommended folder for saving the file if it is not saved.
//     * ForReading - Boolean - True if the file is saved read-only.
//     * InOwnerWorkingDirectory - Boolean - True if the file is saved in the working directory of the owner folder.
//     * UniversalModificationDate - Date - date and time of modification of the saved version of the file.
//     * Size - Number - the size of the saved version of the file.
//     * LocalFileCacheMaxSize - Number - the maximum size of the directory.
//     * VersionComment - String - comment on the file version. Applicable to UP TO 3.0.11 or higher.
//
Function GetInformationAboutEditingFile(Id, Type) Export
	
	EditingInformation = EditingInformation(Id, Type);
	
	InformationRecords = New Structure;
	InformationRecords.Insert("VersionID", EditingInformation.objectID.ID);
	InformationRecords.Insert("Saved_", EditingInformation.info.saved);
	If InformationRecords.Saved_ Then
		InformationRecords.Insert("SaveDate", EditingInformation.info.saveDate);
		InformationRecords.Insert("FullPath", EditingInformation.info.fullPath);
		InformationRecords.Insert("ForReading", EditingInformation.info.readOnly);
		InformationRecords.Insert("UniversalModificationDate", EditingInformation.info.modificationDateUniversal);
		InformationRecords.Insert("Size", EditingInformation.info.size);
	EndIf;
	InformationRecords.Insert("RecommendedFolder", EditingInformation.info.folder);
	InformationRecords.Insert("LocalFileCacheMaxSize", 0);
	InformationRecords.Insert("InOwnerWorkingDirectory", EditingInformation.info.inOwnersFolder);
	
	If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.1.14.2") Then
		InformationRecords.LocalFileCacheMaxSize = EditingInformation.info.maxFolderSize;
	EndIf;
	
	If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("3.0.11.25") Then
		InformationRecords.Insert("VersionComment", "");
	EndIf;
	
	Return InformationRecords;
	
EndFunction

// Retrieves the binary data of the file and places it in temporary storage. When specifying the date
// of the loan, the file is borrowed to the current user. To reduce the number of calls, the size and date are implicitly returned.
//
// Parameters:
//   ID - String - file id
//   UseVisualizationOfItemInstanceStamp - Boolean - it is required to get the binary data of the file with the visualization of the item instance stamp.
//   FormUniqueID - UUID - ID of the calling form.
//   LockedDate - Date - the date the file was borrowed by the current user. If not specified, the loan is not made.
//   DataCurrentFile - See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//
// Returns:
//   String - the address in the temporary storage with binary data of the active version of the file.
//
Function GetFileAndPutItInStorage(ID, UseVisualizationOfItemInstanceStamp, FormUniqueID,
		LockedDate = Undefined, DataCurrentFile = Undefined) Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	If LockedDate = Undefined Then
		FieldsReceived = New Array;
		FieldsReceived.Add("objectID");
		FieldsReceived.Add("name");
		FieldsReceived.Add("binaryData");
		FieldsReceived.Add("extension");
		FieldsReceived.Add("size");
		FieldsReceived.Add("modificationDateUniversal");
		FieldsReceived.Add("encrypted");
		If Not UseVisualizationOfItemInstanceStamp Then
			FieldsReceived.Add("withoutStampVisualization");
		EndIf;
		FileData = IntegrationWith1CDocumentManagementCore.GetObject(
			Proxy,
			"DMFile",
			ID,
			FieldsReceived);
	Else // Receiving with capture.
		If Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.4.9.1") Then
			Raise NStr("vi = 'Phiên bản 1C:Document Management đang sử dụng không hỗ trợ mượn tệp';
						|ru = 'Заем файлов не поддерживается используемой версией 1С:Документооборота';
						|en = 'Files loan is not supported by the used version of 1C:Document Management'; fa = 'Files loan is not supported by the used version of 1C:Document Management';
						|it = 'Prestito dei file non supportato in questa versione utilizzabile di 1C:Document Management';
						|pl = 'Zajmowanie plików nie jest obsługiwane w używanej wersji 1C:Document Management';
						|tr = 'Dosya kredisi, 1C:Document Management''ın mevcut sürümü tarafından desteklenmemektedir'");
		EndIf;
		Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMLockFileRequest");
		FieldsReceived = Query.columnSet; // XDTOList
		
		Query.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(Proxy, ID, "DMFile");
		Query.lockDate = LockedDate;
		FieldsReceived.Add("binaryData");
		FieldsReceived.Add("size");
		FieldsReceived.Add("modificationDateUniversal");
		FieldsReceived.Add("encrypted");
		If Not UseVisualizationOfItemInstanceStamp Then
			FieldsReceived.Add("withoutStampVisualization");
		EndIf;
		Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
		IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Response);
		FileData = Response.object;
	EndIf;
	
	If DataCurrentFile <> Undefined Then
		DataCurrentFile.Size = FileData.size;
		DataCurrentFile.UniversalModificationDate = FileData.modificationDateUniversal;
		DataCurrentFile.Encrypted = FileData.encrypted;
	EndIf;
	Address = PutToTempStorage(FileData.binaryData, FormUniqueID);
	
	Return Address;
	
EndFunction

// Returns stored files to an external object.
//
// Parameters:
//   ExternalObject - Arbitrary - the object is the owner.
//
// Returns:
//   Array of See FilesOperations.FileData
//
Function GetStoredFiles(ExternalObject) Export
	
	StoredFiles = New Array;
	
	IntegrationWith1CDocumentManagementCore.OnReceiveAttachedFiles(
		ExternalObject,
		StoredFiles);
	
	Return StoredFiles;
	
EndFunction

// Makes the specified file version active.
//
// Parameters:
//   FileID - String - id of the owner file.
//   VersionID - String - id of the version to make active.
//   MessageText - String - an implicitly returned parameter, the text of the problem message.
//
// Returns:
//   Boolean - True if the operation was completed successfully.
//
Function MakeVersionActive(FileID, VersionID, MessageText = "") Export
	
	If Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.4.6.1") Then
		MessageText = NStr("vi = 'Để làm việc với các phiên bản, cần có phiên bản 1C:Document Management không thấp hơn 1.4.6.1';
							|ru = 'Для работы с версиями нужен 1С:Документооборот версии не ниже 1.4.6.1';
							|en = 'To operate with versions, 1C:Document Management not earlier than 1.4.6.1 is required'; fa = 'To operate with versions, 1C:Document Management not earlier than 1.4.6.1 is required';
							|it = 'Per il lavoro con le versioni è necessario una versione di 1C:Document Management non precedente alla 1.4.6.1';
							|pl = 'Do pracy z wersjami jest potrzebny 1C:Document Management nie niżej niż 1.4.6.1';
							|tr = 'Sürümlerle çalışmak için 1.4.6.1''den düşük olmayan 1C:Document Management sürümüne ihtiyacınız var'");
		Return False;
	EndIf;
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	File = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMFile");
	File.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		FileID,
		"DMFile");
	File.name = "";
	Version = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMFileVersion");
	Version.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		VersionID,
		"DMFileVersion");
	Version.name = "";
	File.activeVersion = Version;
	
	Try
		IntegrationWith1CDocumentManagementCore.WriteObject(Proxy, File);
		Return True;
	Except
		MessageText = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		Return False;
	EndTry;
	
EndFunction

// Creates a file in the Workflow.
//
// Parameters:
//   CreationParameters - Structure - IntegrationWith1CDocumentManagementCoreClientServer.NewFileCreationOptions
//   OwnerID - String - ID of the file owner in the Document Flow.
//   OwnerType - String - the type of the file owner in the Document Flow.
//   OwnerPresentation - String - representation of the file owner in the Document Flow.
//   TryingToUpdate - Boolean - True, if a file of the same name is found, you need to update it, and
//     False if it is necessary to create a new file unconditionally.
//
// Returns:
//   String - id of the created file.
//
Function CreateFileInWorkflow(CreationParameters, OwnerID, OwnerType, OwnerPresentation = "",
		TryingToUpdate = False) Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	XDTOFile = IntegrationWith1CDocumentManagementCore.XDTOFileFromCreationParameters(
		Proxy,
		CreationParameters);
	
	Query = IntegrationWith1CDocumentManagementCore.CreateRequestFile(
		Proxy,
		XDTOFile,
		OwnerID,
		OwnerType,
		OwnerPresentation);
	
	If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.4.9.1") Then
		Query.tryToUpdate = TryingToUpdate;
	EndIf;
	
	Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Response);
	
	WhetherFilesAreAttached = True;
	
	ObjectIS = InformationRegisters.ObjectsIntegratedWith1CDocumentManagement.ReferenceToIPObjectAccordingToDocumentManagementData(
		OwnerID,
		OwnerType);
	If ObjectIS <> Undefined Then
		IntegrationWith1CDocumentManagementCore.OnAdd1CDocumentManagementAttachedFiles(
			OwnerID,
			OwnerType,
			ObjectIS,
			WhetherFilesAreAttached);
	ElsIf ValueIsFilled(CreationParameters.Owner) Then
		// If the IP object that owns the file is known, but the connection in the database is not established, we will add a new connection.
		// The method of soldering the connected document flow filesin this case, it will be called implicitly when adding a link.
		// If there is no connection in the database, and the owner object is not known in the IP, nothing needs to be done.
		AddLink(
			OwnerID,
			OwnerType,
			CreationParameters.Owner,
			WhetherFilesAreAttached);
	EndIf;
	
	Return Response.file.objectID.ID;
	
EndFunction

// Saves to the file version editing information.
//
// Parameters:
//   InformationRecords - Structure:
//     * VersionID - String - id of the file version.
//     * Saved_ - Boolean - True if the file is saved on disk.
//     * SaveDate - Boolean - the date the file was saved on disk.
//     * FullPath - String - the full path to the file on the disk.
//     * ForReading - Boolean - True if the file is saved read-only.
//     * InOwnerWorkingDirectory - Boolean - True if the file is saved in the working directory of the owner folder.
//     * Size - Number - the size of the saved version of the file.
//
Procedure SaveFileEditingInformation(InformationRecords) Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy,"DMUpdateFileEditingInfoRequest");
	
	Query.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		InformationRecords.VersionID,
		"DMFileVersion");
	
	If Query.Properties().Get("clientIdentifier") <> Undefined Then
		SysInfo = New SystemInfo;
		Query.clientIdentifier = String(SysInfo.ClientID);
	EndIf;
	
	Query.info = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy,"DMFileEditingInfo");
	
	Query.info.saved = InformationRecords.Saved_;
	If InformationRecords.Saved_ Then
		Query.info.saveDate = InformationRecords.SaveDate;
		Query.info.fullPath = InformationRecords.FullPath;
		Query.info.readOnly = InformationRecords.ForReading;
		Query.info.modificationDateUniversal = InformationRecords.UniversalModificationDate;
		Query.info.size = InformationRecords.Size;
		Query.info.inOwnersFolder = InformationRecords.InOwnerWorkingDirectory;
	EndIf;
	
	Result = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Result);
	
EndProcedure

// checks whether the file is being edited by the Cur user.
//
// Parameters:
//   WhoEditsID - String - ID of the person editing the file.
//   WhoEditsType - String - the object type of the person editing the file.
//   CurCurrentUserAndEmployees - Array of XDTODataObject - the Cur user and his employees.
//
// Returns:
//   Boolean
//
Function FileIsBeingEditedByCurUser(WhoEditsID, WhoEditsType,
		CurCurrentUserAndEmployees) Export
	
	For Each Item In CurCurrentUserAndEmployees Do
		If WhoEditsID = Item.objectID.ID And WhoEditsType = Item.objectID.type Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

// Returns a list of XDTO files by Workflow object.
//
// Parameters:
//   OwnerID - String - the unique identifier of the document flow object.
//   OwnerName - String - representation of the document flow object.
//   OwnerType - String - the XDTO type of the Workflow object.
//   IncludeMarkedForDeletion - Boolean - True if you need to get files without taking into account the tag.
//
// Returns:
//   XDTODataObject - A list of XDTO objects of the DMFile type.
//
Function FilesByOwner(OwnerID, OwnerName, OwnerType,
		IncludeMarkedForDeletion = False) Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMGetFileListByOwnerRequest");
	FieldsReceived = Query.columnSet; // XDTOList
	Owners = Query.owners; // XDTOList
	
	OwnerObject =  IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObject");
	OwnerObject.name = OwnerName;
	OwnerObject.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		String(OwnerID),
		OwnerType);
	
	Owners.Add(OwnerObject);
	
	FieldsReceived.Add("objectID");
	FieldsReceived.Add("signed");
	FieldsReceived.Add("name");
	FieldsReceived.Add("size");
	FieldsReceived.Add("creationDate");
	FieldsReceived.Add("modificationDateUniversal");
	FieldsReceived.Add("author");
	FieldsReceived.Add("extension");
	FieldsReceived.Add("description");
	FieldsReceived.Add("encrypted");
	FieldsReceived.Add("editing");
	
	If IncludeMarkedForDeletion Then
		Query.ignoreDeletionMark = True;
		FieldsReceived.Add("deletionMark");
	EndIf;
	
	// Capture and edit files.
	If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.4.8.1") Then
		FieldsReceived.Add("editingUser");
	EndIf;
	
	Files = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Files);
	
	Return Files;
	
EndFunction

// Reads and returns a tabular document from temporary storage.
//
// Parameters:
//   AddressOfTabularDocumentInRepository - String - the address of the tabular document in the temporary storage.
//
// Returns:
//   SpreadsheetDocument
//
Function ReadingTabularDocument(AddressOfTabularDocumentInRepository) Export
	
	TabularDocumentData = GetFromTempStorage(AddressOfTabularDocumentInRepository);
	TempFileName = GetTempFileName("mxl");
	TabularDocumentData.Write(TempFileName);
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.Read(TempFileName);
	DeleteFiles(TempFileName);
	
	Return SpreadsheetDocument;
	
EndFunction

#EndRegion

#Region DigitalSignatures

// Returns the value of the constant "Use electronic digital signatures".
//
// Returns:
//   Boolean - if True, electronic signatures are used.
//
Function UseElectronicDigitalSignatures() Export
	
	If Common.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		ModuleDigitalSignature = Common.CommonModule("DigitalSignature");
		Return ModuleDigitalSignature.UseDigitalSignature();
	Else
		Return False;
	EndIf;
	
EndFunction

// Retrieves the objects to be signed by the item instance, fills in the array for signatures.
//
// Parameters:
//   ObjectName_1 - String - name of the document Flow document.
//   ObjectID - String - ID of the workflow document.
//   ObjectType - String - the type of the XDTO object in the Document Flow.
//   ArrayOfCaptionObjects - Array of Structure:
//     * BinaryData - BinaryData
//     * CaptionReferenceObject - String
//     * ObjectType - String
//   Files - Array of String - array of file IDs in the Document Flow.
//   AddressOfObjectSBinaryData - See IntegrationWith1CDocumentManagementCoreClientServer.AddressOfObjectSBinaryData
//
Procedure GetObjectsForCaption(ObjectName_1, ObjectID, ObjectType, ArrayOfCaptionObjects, Files,
		AddressOfObjectSBinaryData) Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	ListOfObjects = New Array;
	If StrFind(ObjectType, "Document") > 0 Then
		ListOfObjects.Add(New Structure("ID, Type", ObjectID, ObjectType));
	EndIf;
	For Each File In Files Do
		ListOfObjects.Add(New Structure("ID, Type", File, "DMFile"));
	EndDo;
	
	Columns = New Array;
	Columns.Add("objectID");
	Columns.Add("name");
	Columns.Add("keyPropertiesValue");
	Columns.Add("binaryData");
	Columns.Add("encrypted");
	Columns.Add("withoutStampVisualization");
	
	DataOfXDTOObjects = IntegrationWith1CDocumentManagementCore.GetObjects(
		Proxy,
		ListOfObjects,
		Columns);
	
	For Each XDTODataObject In DataOfXDTOObjects Do
		CaptionObject = CaptionObject();
		CaptionObject.CaptionReferenceObject = XDTODataObject.objectID.ID;
		CaptionObject.ObjectType = XDTODataObject.objectID.type;
		CaptionObject.ObjectName_1 = XDTODataObject.name;
		If CaptionObject.ObjectType = "DMFile" Then
			CaptionObject.Encrypted = XDTODataObject.encrypted;
			CaptionObject.BinaryData = XDTODataObject.binaryData;
			AddressOfObjectSBinaryData.AddressesOfBinaryDataFiles[XDTODataObject.objectID.ID] =
				PutToTempStorage(
					XDTODataObject.binaryData,
					AddressOfObjectSBinaryData.FormUniqueID);
		Else
			CaptionObject.Encrypted = False;
			CaptionObject.BinaryData = XDTODataObject.keyPropertiesValue;
			AddressOfObjectSBinaryData.AddressOfDocumentImpression = PutToTempStorage(
				XDTODataObject.keyPropertiesValue,
				AddressOfObjectSBinaryData.FormUniqueID);
		EndIf;
		ArrayOfCaptionObjects.Add(CaptionObject);
	EndDo;
	
EndProcedure

// Saves file signatures in temporary storage.
//
// Parameters:
//   ID - String - file identifier.
//
// Returns:
//   String - the address of the array of signatures in the temporary storage.
//
Function PlaceFileSignaturesInStorage(ID) Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	FieldsReceived = New Array;
	FieldsReceived.Add("signatures");
	FieldsReceived.Add("signatures.author");
	FieldsReceived.Add("signatures.date");
	FieldsReceived.Add("signatures.comment");
	FieldsReceived.Add("signatures.signature");
	FieldsReceived.Add("signatures.thumbprint");
	FieldsReceived.Add("signatures.lineNumber");
	FieldsReceived.Add("signatures.signer");
	FieldsReceived.Add("signatures.certificate");
	FieldsReceived.Add("signatures.signatureFileName");
	FileInfo1 = IntegrationWith1CDocumentManagementCore.GetObject(
		Proxy,
		"DMFile",
		ID,
		FieldsReceived);
	
	Signatures = New Array;
	
	For Each XDTOSignature In FileInfo1.signatures Do
		Signatures.Add(IntegrationWith1CDocumentManagementCore.SignatureDataFromXDTO(XDTOSignature));
	EndDo;
	
	Return PutToTempStorage(Signatures, New UUID);
	
EndFunction

// Checks signatures from the array of selected lines. If the array of selected rows is not passed, it checks all
// signatures from the signature table.
//
// Parameters:
//   SignatureTable - See IntegrationWith1CDocumentManagementCoreClientServer.SignatureTable
//   SelectedSignatures - See IntegrationWith1CDocumentManagementCoreClient.SelectedSignatures
//   AddressOfObjectSBinaryData - See IntegrationWith1CDocumentManagementCoreClientServer.AddressOfObjectSBinaryData
//   Application - Undefined - returns the cryptography manager of the first program for which it was possible to create it.
//             - CatalogRef.DigitalSignatureAndEncryptionApplications - programs for which you need to create and
//     return a cryptography manager.
//             - Structure - See DigitalSignature.NewApplicationDetails.
//             - BinaryData - signature or certificate data in DER encoding to define the program.
//             - String - the address of the binary data described above in the temporary storage.
//
Procedure VerifySignatures(SignatureTable, SelectedSignatures = Undefined, AddressOfObjectSBinaryData = Undefined,
		Application = Undefined) Export
	
	CryptoManager = GetCryptographyManager("CheckSignature", Application);
	IntegrationWith1CDocumentManagementCore.VerifySignatures(
		CryptoManager,
		SignatureTable,
		SelectedSignatures,
		AddressOfObjectSBinaryData);
	
EndProcedure

// Checks whether the integrated system can create electronic
// signatures for 1C objects:Document management. Designed to determine the setting value on the client.
//
// Returns:
//   Boolean
//
Function CreateDigitalSignaturesFor1CDocumentManagementObjectsUsingIntegratedSystem() Export
	
	Return IntegrationWith1CDocumentManagementCore.CreateDigitalSignaturesFor1CDocumentManagementObjectsUsingIntegratedSystem();
	
EndFunction

// Deletes the signatures of the document and its files.
//
// Parameters:
//   SignaturesToDelete - See IntegrationWith1CDocumentManagementCoreClient.SelectedSignatures
//   SignatureTable - See IntegrationWith1CDocumentManagementCoreClientServer.SignatureTable
//
// Returns:
//   Map of KeyAndValue - an implicit return value. Returns files that
//         need to be notified that their signatures have been deleted:
//     * Key - String - file identifier.
//     * Value - String - file name.
//
Function DeleteSignatures(SignaturesToDelete, SignatureTable) Export
	
	ObjectsSignatures = New Map;
	FilesForNotification = New Map;
	
	// forming an array of signature data.
	For Each RowData In SignatureTable Do
		
		// by the object's GUID + line number, we delete from the array all those that need to be deleted.
		SignatureRemoved = False;
		For Each DeletedSignatureString In SignaturesToDelete Do
			If DeletedSignatureString.ObjectID = RowData.ObjectID
					And DeletedSignatureString.LineNumber = RowData.LineNumber Then
				SignatureRemoved = True;
				IntegrationWith1CDocumentManagementCoreClientServer.AddObjectCaptions(
					ObjectsSignatures,
					RowData.Object_Name,
					RowData.ObjectID,
					RowData.ObjectType,
					RowData.Encrypted);
				If RowData.ObjectType = "DMFile"
						And FilesForNotification[RowData.ObjectID] = Undefined Then
					FilesForNotification[RowData.ObjectID] = RowData.Object_Name;
				EndIf;
				Break;
			EndIf;
		EndDo;
		
		If SignatureRemoved Then
			Continue;
		EndIf;
		
		If ValueIsFilled(RowData.CertificateAddress) Then
			CertificateBinaryData = GetFromTempStorage(RowData.CertificateAddress);
		Else
			CertificateBinaryData = Undefined;
		EndIf;
		SignatureData = IntegrationWith1CDocumentManagementCore.SignatureData(
			GetFromTempStorage(RowData.SignatureAddress),
			CertificateBinaryData,
			RowData);
		IntegrationWith1CDocumentManagementCoreClientServer.AddObjectCaptions(
			ObjectsSignatures,
			RowData.Object_Name,
			RowData.ObjectID,
			RowData.ObjectType,
			RowData.Encrypted,
			CommonClientServer.ValueInArray(SignatureData));
		
	EndDo;
	
	EnterInformationAboutObjectSignatures(ObjectsSignatures);
	
	Return FilesForNotification;
	
EndFunction

#EndRegion

#Region Documents

// creates files of printed forms of objects by the name of the 1C document form command:Document management and
// attaches them to documents.
//
// Parameters:
//   ObjectIS - AnyRef - a reference to the object of the current database.
//   ObjectBefore - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//   CommandName - String - the name of the button command in the format "Manager_%_Command_%".
//   AdditionalParameters - String - (optional) custom parameters to pass to the print Manager.
//   FileFormat - EnumRef.TypesOfSavedPrintedFormFileOfObjects - the type of file being saved.
//   FileRoleID - String - ID of the role of the file to save the printed form to.
//   CommandPresentation - String - synonym for the print Command.
//
// Returns:
//   Array of See IntegrationWith1CDocumentManagementCoreClientServer.NewFileCreationOptions
//
Function AttachPrintedFormOfObjectToDocument(ObjectIS, ObjectBefore, CommandName, AdditionalParameters,
		FileFormat, FileRoleID, CommandPresentation = "") Export
	
	Result = New Array;
	
	PrintFormsCollection = New ValueTable;
	IntegrationWith1CDocumentManagementCore.FillInCollectionOfPrintedForms(
		ObjectIS,
		CommandName,
		AdditionalParameters,
		PrintFormsCollection);
	
	TempFileName = GetTempFileName();
	FileFormatName = Common.EnumerationValueName(FileFormat);
	
	For Each PrintForm In PrintFormsCollection Do
		If PrintForm.SpreadsheetDocument <> Undefined
				And PrintForm.SpreadsheetDocument.PageCount() > 0 Then
			
			PrintForm.SpreadsheetDocument.Write(TempFileName, SpreadsheetDocumentFileType[FileFormatName]);
			
			Description = IntegrationWith1CDocumentManagementCore.NameOfPrintForm(
				ObjectIS,
				CommandPresentation,
				PrintForm.TemplateSynonym,
				PrintForm.TemplateName);
			
			Extension = IntegrationWith1CDocumentManagementCore.ExpansionOfSavedPrintedForm(
				FileFormat);
			
			CurrentFile = IntegrationWith1CDocumentManagementCoreClientServer.FileData(
				Description,
				Undefined,
				"DMFile",
				Extension,
				FileRoleID);
			
			File = New File(TempFileName);
			CurrentFile.Size = File.Size();
			CurrentFile.ModificationDate = File.GetModificationTime();
			CurrentFile.UniversalModificationDate = File.GetModificationUniversalTime();
			File = Undefined;
			
			CreationParameters = IntegrationWith1CDocumentManagementCoreClientServer.NewFileCreationOptions(
				CurrentFile);
			CreationParameters.TempFileStorageAddress = PutToTempStorage(
				New BinaryData(TempFileName));
			CreationParameters.Owner = ObjectIS;
			
			CreationParameters.CurrentFile.ID = CreateFileInWorkflow(
				CreationParameters,
				ObjectBefore.ID,
				ObjectBefore.Type,
				ObjectBefore.Presentation,
				True);
			
			Result.Add(CreationParameters);
			
		EndIf;
	EndDo;
	
	DeleteFiles(TempFileName);
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

// Returns an XDTO list containing file data.
//
// Parameters:
//   Files - Array of String - array of file IDs in the Document Flow.
//   UseVisualizationOfItemInstanceStamp - Boolean - it is required to get the binary data of the file with the visualization of the item instance stamp.
//
// Returns:
//   XDTOList - A list of XDTO objects of the DMFile type.
//
Function FilesData(Files, UseVisualizationOfItemInstanceStamp = True)
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	ListOfObjects = New Array;
	For Each File In Files Do
		ListOfObjects.Add(New Structure("ID, Type", File, "DMFile"));
	EndDo;
	
	Columns = New Array;
	Columns.Add("objectID");
	Columns.Add("name");
	Columns.Add("binaryData");
	Columns.Add("encrypted");
	If Not UseVisualizationOfItemInstanceStamp Then
		Columns.Add("withoutStampVisualization");
	EndIf;
	
	Return IntegrationWith1CDocumentManagementCore.GetObjects(Proxy, ListOfObjects, Columns);
	
EndFunction

// Complements the set of columns of DMObjectListQuery.query selection criteria with columns for individual types of objects.
//
// Parameters:
//   SetOfColumns - XDTOList
//   XDTOType - String
//
Procedure AddSetOfSelectionCriteriaColumns(SetOfColumns, XDTOType)
	
	If XDTOType = "DMOrganization" Then
		// VAT and DDS articles.
		If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.1.8.1.CORP") Then
			SetOfColumns.Add("VATpayer");
		EndIf;
		
	ElsIf XDTOType = "DMCorrespondent" Then
		SetOfColumns.Add("legalPrivatePerson");
		
	ElsIf XDTOType = "DMProduct" Then
		SetOfColumns.Add("VATRate");
		SetOfColumns.Add("VATRateUniversal");
		SetOfColumns.Add("measurementUnit");
		SetOfColumns.Add("price");
		
	EndIf;
	
EndProcedure

Procedure FillInFileListLine(FileListString, XDTOFile, CurCurrentUserAndEmployees)
	
	// General information about the file.
	FileListString.Description = XDTOFile.name;
	FileListString.ID = XDTOFile.objectID.ID;
	If FileListString.Property("Type") Then
		FileListString.Type = XDTOFile.objectID.type;
	EndIf;
	FileListString.Extension = XDTOFile.extension;
	DeletionMark = False;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOFile, "deletionMark") Then
		DeletionMark = XDTOFile.deletionMark;
	EndIf;
	FileListString.PictureIndex =
		IntegrationWith1CDocumentManagementCore.IndexOfFileIcon(
			FileListString.Extension,
			DeletionMark);
	
	// File template.
	// Let's skip the prototypes of the files that will be filled in according to the templates when recording.
	If XDTOFile.Properties().Get("template") <> Undefined And XDTOFile.template <> Undefined Then
		FileListString.TemplateID = XDTOFile.template.objectID.ID;
		If Not ValueIsFilled(XDTOFile.objectID.ID) Then
			Return;
		EndIf;
	EndIf;
	
	// Date of creation/modification.
	FileListString.CreationDate = XDTOFile.creationDate;
	If FileListString.Property("ModificationDate") And ValueIsFilled(XDTOFile.modificationDateUniversal) Then
		FileListString.ModificationDate = ToLocalTime(XDTOFile.modificationDateUniversal, SessionTimeZone());
	EndIf;
	If FileListString.Property("UniversalModificationDate") Then
		FileListString.UniversalModificationDate = XDTOFile.modificationDateUniversal;
	EndIf;
	
	// The author of the file/changes.
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOFile, "author") Then
		FileListString.Author = XDTOFile.author.name;
	EndIf;
	If FileListString.Property("WasEditedBy")
			And IntegrationWith1CDocumentManagementCore.PropertySet(XDTOFile, "activeVersion")
			And IntegrationWith1CDocumentManagementCore.PropertySet(XDTOFile.activeVersion, "author") Then
		FileListString.WasEditedBy = XDTOFile.activeVersion.author.name;
	EndIf;
	
	// Other information about the file.
	FileListString.LongDesc = XDTOFile.description;
	FileListString.Size = Format(
		IntegrationWith1CDocumentManagementCoreClientServer.SizeInKb(XDTOFile.size),
		"ND=10; NZ=0");
	FileListString.SignedWithDS = XDTOFile.signed;
	If FileListString.Property("Encrypted") Then
		FileListString.Encrypted = XDTOFile.encrypted;
	EndIf;
	If FileListString.Property("SignedEncryptedPictureNumber") Then
		FileListString.SignedEncryptedPictureNumber = SignedEncryptedPictureNumber(XDTOFile, True);
	EndIf;
	If FileListString.Property("FileRoleID")
			And IntegrationWith1CDocumentManagementCore.PropertySet(XDTOFile, "role") Then
		FileListString.FileRoleID = XDTOFile.role.objectID.id;
	EndIf;
	
	FileListString.IsBeingEdited = XDTOFile.editing;
	FileListString.Encrypted = XDTOFile.encrypted;
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOFile, "editingUser") Then
		FileListString.EditedByCurUser = FileIsBeingEditedByCurUser(
			XDTOFile.editingUser.objectID.ID,
			XDTOFile.editingUser.objectID.type,
			CurCurrentUserAndEmployees);
		If FileListString.Property("BeingEditedBy") Then
			FileListString.BeingEditedBy = XDTOFile.editingUser.name;
		EndIf;
	Else
		FileListString.EditedByCurUser = False;
	EndIf;
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOFile, "scannedOriginal") Then
		FileListString.IsOriginal = XDTOFile.scannedOriginal;
	EndIf;
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOFile, "deletionMark") Then
		FileListString.DeletionMark = XDTOFile.deletionMark;
	EndIf;
	
	If FileListString.Property("PresentationHTML")
			And IntegrationWith1CDocumentManagementCore.PropertySet(XDTOFile, "htmlView") Then
		FileListString.PresentationHTML = XDTOFile.htmlView;
		FileListString.PreviewCut = XDTOFile.htmlViewTruncated;
	EndIf;
	
EndProcedure

// Returns the image number.
//
// Parameters:
//   XDTOFile - XDTODataObject - An XDTO object of the DMFile type.
//   FillingInLine - Boolean
//
// Returns:
//   Number
//
Function SignedEncryptedPictureNumber(XDTOFile, FillingInLine = False)
	
	SignedEncryptedPictureNumber = -1;
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOFile, "signatureStatus") Then
		
		SignedEncryptedPictureNumber = XDTOFile.signatureStatus;
		
	Else
		
		If XDTOFile.signed = True And XDTOFile.encrypted = True Then
			SignedEncryptedPictureNumber = 3;
		ElsIf XDTOFile.encrypted = True Then
			SignedEncryptedPictureNumber = 1;
		ElsIf XDTOFile.signed = True Then
			SignedEncryptedPictureNumber = 2;
		EndIf;
		
	EndIf;
	
	If FillingInLine And SignedEncryptedPictureNumber = 0 Then
		SignedEncryptedPictureNumber = -1;
	EndIf;
	
	Return SignedEncryptedPictureNumber;
	
EndFunction

Function CaptionObject()
	
	Result = New Structure;
	Result.Insert("BinaryData", Undefined);
	Result.Insert("CaptionReferenceObject", Undefined);
	Result.Insert("ObjectType", "");
	Result.Insert("ObjectName_1", "");
	Result.Insert("Encrypted", False);
	
	Return Result;
	
EndFunction

// Performs in the background of operation connecting to BEFORE and getting the version of the service BEFORE.
//
// Parameters:
//   UseCache - Boolean - when checking the possibility of authorization without a password, you do not need to use a cache.
//   UserName - String - user name BEFORE.
//   Password - String - the user's password is UP TO.
//   FormUniqueID - UUID - ID of the calling form.
//   AddressOfDocumentManagementWebService - String - the address of the web service BEFORE, or
//                                   - Undefined - indicates the need to use a previously saved address.
//
// Returns:
//   See TimeConsumingOperations.ExecuteInBackground
//
Function OperationOfConnectingAndGettingVersionOfService(UseCache, UserName, Password,
		FormUniqueID = Undefined, AddressOfDocumentManagementWebService = Undefined)
	
	TimeConsumingOperationParameters = TimeConsumingOperationParameters(UseCache, AddressOfDocumentManagementWebService);
	TimeConsumingOperationParameters.IntegrationWith1CDocumentManagementUsername = UserName;
	TimeConsumingOperationParameters.IntegrationWith1CDocumentManagementPassword = Password;
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(FormUniqueID);
	ExecutionParameters.WaitCompletion = 0; // Start immediately.
	ExecutionParameters.RunInBackground = True;
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Kết nối đến 1C:Document Management';
														|ru = 'Подключение к 1С:Документооборот';
														|en = 'Connect to 1C:Document Management'; fa = 'Connect to 1C:Document Management';
														|it = 'Подключение к 1С:Документооборот';
														|pl = 'Connect to 1C:Document Management';
														|tr = '1C:Document Management''e bağlantı'");
	
	Return TimeConsumingOperations.ExecuteInBackground(
		"IntegrationWith1CDocumentManagementCore.ConnectAndGetServiceVersionInBackground",
		TimeConsumingOperationParameters,
		ExecutionParameters);
	
EndFunction

// Gets the cryptography manager.
//
// Parameters:
//   Operation - String - if not empty, it must contain one of the lines that define
//     the operation to insert in the error description: Signing, Verifying Signatures, Encrypting,
//     Decrypting, Verifying Certificates, Receiving Certificates.
//   Application - Undefined - returns the cryptography manager of the first program for which it was possible to create it.
//             - CatalogRef.DigitalSignatureAndEncryptionApplications - programs for which you need to create and
//     return a cryptography manager.
//             - Structure - See DigitalSignature.NewApplicationDetails.
//             - BinaryData - signature or certificate data in DER encoding to define the program.
//             - String - the address of the binary data described above in the temporary storage.
//
// Returns:
//   CryptoManager, Undefined - cryptography manager or Undefined if an error occurred.
//
Function GetCryptographyManager(Operation = "", Application = Undefined)
	
	If Common.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		ModuleDigitalSignature = Common.CommonModule("DigitalSignature");
		Return ModuleDigitalSignature.CryptoManager(Operation,,, Application);
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// Retrieves information about a file from the Workflow.
//
// Parameters:
//   Id - String - id of the file or version.
//   Type - String - DMFile or DMFileVersion.
//
// Returns:
//   XDTODataObject:
//     * name - String
//     * objectID - XDTODataObject:
//       ** ID - String
//       ** type - String
//     * info - XDTODataObject:
//       ** saved - Boolean
//       ** saveDate - Date
//       ** fullPath - String
//       ** readOnly - Boolean
//       ** modificationDateUniversal - Date
//       ** size - Number
//       ** folder - String
//       ** inOwnersFolder - Boolean
//       ** maxFolderSize - Number
//
Function EditingInformation(Id, Type)
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy,"DMGetFileEditingInfoRequest");
	Query.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(Proxy, Id, Type);
	
	If Query.Properties().Get("clientIdentifier") <> Undefined Then
		SysInfo = New SystemInfo;
		Query.clientIdentifier = String(SysInfo.ClientID);
	EndIf;
	
	Result = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Result);
	
	Return Result;
	
EndFunction

// Retrieves information about a file from the Workflow.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   ID - String - id of the file in UP to.
//   FieldsReceived - Array of String - file Attributes that you want to get from BEFORE.
//
// Returns:
//   XDTODataObject:
//     * name - String
//     * objectID - XDTODataObject:
//       ** ID - String
//       ** type - String
//     * description - String
//     * size - Number
//     * scannedOriginal - Boolean
//     * signed - Boolean
//     * additionalProperties - XDTOList
//     * modificationDateUniversal - Date
//     * modificationDate - Date
//     * extension - String
//     * encrypted - Boolean
//     * creationDate - Date
//     * lockDate - Date
//     * editing - Boolean
//     * author - XDTODataObject:
//       ** name - String
//       ** objectID - XDTODataObject:
//         *** ID - String
//         *** type - String
//     * owner - XDTODataObject:
//       ** name - String
//       ** objectID - XDTODataObject:
//         *** ID - String
//         *** type - String
//
Function FileInfo1(Proxy, ID, FieldsReceived)
	
	Return IntegrationWith1CDocumentManagementCore.GetObject(
		Proxy,
		"DMFile",
		ID,
		FieldsReceived);
	
EndFunction

// Returns the hash sum of the data according to the CRC32 algorithm.
//
// Parameters:
//   Data - String, BinaryData - data for calculation.
//
// Returns:
//   Number - the hash amount calculated using the CRC32 algorithm.
//
Function CRC32HashSum(Data)
	
	DataHashing = New DataHashing(HashFunction.CRC32);
	DataHashing.Append(Data);
	
	Return DataHashing.HashSum;
	
EndFunction

#EndRegion