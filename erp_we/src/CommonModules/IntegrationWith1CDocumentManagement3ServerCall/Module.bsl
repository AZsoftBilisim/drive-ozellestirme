////////////////////////////////////////////////////////////////////////////////
// Subsystem "Integration with 1C:Document management"
// Integration module1documentwork3the server call: server, server call
////////////////////////////////////////////////////////////////////////////////

#Region Internal

#Region AsynchronousOperations

// starts asynchronous task changes, and also, if necessary, receives from 1C:Workflow updated
// data in a single batch request.
//
// Parameters:
//   OperationType - See IntegrationWith1CDocumentManagementCoreClientServer.TypeOfOperationOnTask
//   DataByTask - See IntegrationWith1CDocumentManagement3ClientServer.DataByTask
//   FormUniqueID - UUID - ID of the calling form.
//   DataUpdateRequired - Boolean - You need to execute a request to update the data.
//   ThisIsFormOfTaskList - Boolean - The operation is performed from the task list form.
//   TaskListFormParameters - See IntegrationWith1CDocumentManagement3ClientServer.TaskListFormParameters
//
// Returns:
//   See TimeConsumingOperations.ExecuteInBackground
//
Function LongTermOperationOnTask(Val OperationType, Val DataByTask, Val FormUniqueID,
		Val DataUpdateRequired = True, Val ThisIsFormOfTaskList = False,
		Val TaskListFormParameters = Undefined) Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	PackageQueries = New Array;
	
	If OperationType.PerformTaskAction Then
		PackageQueries.Add(IntegrationWith1CDocumentManagement3.PerformRequestTaskAction(Proxy, DataByTask));
		
	ElsIf OperationType.TakeToWork Then
		PackageQueries.Add(IntegrationWith1CDocumentManagement3.TakeTaskToWorkRequest(Proxy, DataByTask));
		
	ElsIf OperationType.CancelTakingToWork Then
		PackageQueries.Add(IntegrationWith1CDocumentManagement3.CancelTakingTaskToWorkRequest(Proxy, DataByTask));
		
	ElsIf OperationType.SetFlag Then
		PackageQueries.Add(IntegrationWith1CDocumentManagement3.SetRequestTaskFlag(Proxy, DataByTask));
		
	EndIf;
	
	If DataUpdateRequired Then
		If ThisIsFormOfTaskList Then
			IntegrationWith1CDocumentManagement3.AddTaskSelectionFilters(
				Proxy,
				TaskListFormParameters.DisplayFilters,
				TaskListFormParameters.QuickSearch);
			PackageQueries.Add(
				IntegrationWith1CDocumentManagement3.ListOfIssuesRequest(
					Proxy,
					TaskListFormParameters.CurrentPage,
					TaskListFormParameters.DynamicListPageSize,
					TaskListFormParameters.SortingField,
					TaskListFormParameters.FieldSortingDirection,
					TaskListFormParameters.DisplayFilters,
					TaskListFormParameters.DisplayingTaskCard));
		Else
			PackageQueries.Add(
				IntegrationWith1CDocumentManagementCore.GetRequestObjects(
					Proxy,
					CommonClientServer.ValueInArray(DataByTask.TaskAction),
					"htmlView"));
		EndIf;
	EndIf;
	
	Return IntegrationWith1CDocumentManagementCore.ExecuteBatchRequestAsynchronously(
		Proxy,
		PackageQueries,
		FormUniqueID);
	
EndFunction

// starts asynchronous task changes, and also, if necessary, receives from 1C:Workflow updated
// data in a single batch request.
//
// Parameters:
//   OperationType - See IntegrationWith1CDocumentManagementCoreClientServer.TypeOfOperationOnTask
//   DataProcessorData - See IntegrationWith1CDocumentManagement3ClientServer.DataProcessorData
//   ExternalObject - AnyRef - a link to the associated IP object.
//   FormUniqueID - UUID - ID of the calling form.
//   DataUpdateRequired - Boolean - You need to execute a request to update the data.
//   ObjectIsBeingUpdated - Boolean - an implicitly returned value, True if the object is being updated.
//   ControlOverSendingFiles - See IntegrationWith1CDocumentManagementCore.ControlOverSendingFiles
//
// Returns:
//   See TimeConsumingOperations.ExecuteInBackground
//
Function LongOfOperationWithProcessing(Val OperationType, Val DataProcessorData, Val ExternalObject,
		Val FormUniqueID, Val DataUpdateRequired = True, ObjectIsBeingUpdated = False,
		ControlOverSendingFiles = Undefined) Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	PackageQueries = New Array;
	
	If OperationType.ToBegin Then
		If ValueIsFilled(ExternalObject) Then
			RequestToUpdateObject = IntegrationWith1CDocumentManagement3Exchange.RequestToUpdateObject(
				Proxy,
				ExternalObject,
				ControlOverSendingFiles);
			ControlOverSendingFiles = Common.ValueTableToArray(ControlOverSendingFiles);
			If RequestToUpdateObject = Undefined Then
				ObjectIsBeingUpdated = False;
			Else
				ObjectIsBeingUpdated = True;
				PackageQueries.Add(RequestToUpdateObject);
			EndIf;
		EndIf;
		PackageQueries.Add(IntegrationWith1CDocumentManagement3.StartProcessingRequest(Proxy, DataProcessorData));
		
	ElsIf OperationType.Abort Then
		PackageQueries.Add(IntegrationWith1CDocumentManagement3.AbortRequestProcessing(Proxy, DataProcessorData));
		
	ElsIf OperationType.Stop Then
		PackageQueries.Add(IntegrationWith1CDocumentManagement3.StopProcessingRequest(Proxy, DataProcessorData));
		
	ElsIf OperationType.Continue Then
		PackageQueries.Add(IntegrationWith1CDocumentManagement3.ContinueProcessingRequest(Proxy, DataProcessorData));
		
	ElsIf OperationType.Fill Then
		PackageQueries.Add(IntegrationWith1CDocumentManagement3.FillInProcessingRequest(Proxy, DataProcessorData));
		
	ElsIf OperationType.Restart Then
		PackageQueries.Add(IntegrationWith1CDocumentManagement3.RestartRequestProcessing(Proxy, DataProcessorData));
		
	EndIf;
	
	If DataUpdateRequired Then
		PackageQueries.Add(
			IntegrationWith1CDocumentManagement3.CurProcessingOfRequestObject(
				Proxy,
				DataProcessorData.SubjectOfID,
				DataProcessorData.SubjectOfType));
	EndIf;
	
	Return IntegrationWith1CDocumentManagementCore.ExecuteBatchRequestAsynchronously(
		Proxy,
		PackageQueries,
		FormUniqueID);
	
EndFunction

// Gets an HTML preview of an object from the Workflow in the background task.
//
// Parameters:
//   FormUniqueID - UUID - ID of the calling form.
//   ID - String - the unique identifier of the object in the Document Flow.
//   Type - String - the name of the type XDTO.
//   IgnoreMaxSize - Boolean - allows you to ignore the Workflow setting
//     "File size limit for preview".
//   ObjectForGettingPersonalData - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//   ReturnBinaryData - Boolean - instead of an HTML preview string, you need to get binary file data for
//     visualization using platform tools, for example, through a PDF document.
//
// Returns:
//   See TimeConsumingOperations.ExecuteInBackground
//
Function GetHTMLPreviewOfObjectAsynchronously(FormUniqueID, ID, Type, IgnoreMaxSize = False,
		ObjectForGettingPersonalData = Undefined, ReturnBinaryData = False) Export
	
	TimeConsumingOperationParameters = IntegrationWith1CDocumentManagementCore.TimeConsumingOperationParameters();
	TimeConsumingOperationParameters.Insert("ID", ID);
	TimeConsumingOperationParameters.Insert("Type", Type);
	TimeConsumingOperationParameters.Insert("IgnoreMaxSize", IgnoreMaxSize);
	TimeConsumingOperationParameters.Insert("ObjectForGettingPersonalData", ObjectForGettingPersonalData);
	TimeConsumingOperationParameters.Insert("ReturnBinaryData", ReturnBinaryData);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(FormUniqueID);
	ExecutionParameters.WaitCompletion = 0; // Start immediately.
	ExecutionParameters.BackgroundJobDescription =
		NStr("vi = 'Nhận xem trước HTML đối tượng từ 1C:Document Management';
			|ru = 'Получение HTML предпросмотра объекта из 1С:Документооборот';
			|en = 'Get object preview HTML from 1C:Document Management'; fa = 'Get object preview HTML from 1C:Document Management';
			|it = 'Получение HTML предпросмотра объекта из 1С:Документооборот';
			|pl = 'Get object preview HTML from 1C:Document Management';
			|tr = '1C:Document Management''ten nesnenin HTML önizlemesini alma'");
	
	Return TimeConsumingOperations.ExecuteInBackground(
		"IntegrationWith1CDocumentManagement3.GetHTMLPreviewOfObjectInBackground",
		TimeConsumingOperationParameters,
		ExecutionParameters);
	
EndFunction

// Checks the participants of the action in the background task.
//
// Parameters:
//   ActionXDTOString - String - string Presentation of an XDTO object of the type inheriting DMAction.
//   FormUniqueID - UUID - ID of the calling form.
//
// Returns:
//   See TimeConsumingOperations.ExecuteInBackground
//
Function CheckParticipantsAsynchronously(ActionXDTOString, FormUniqueID) Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		"DMCheckValidityOfActionParticipantsRequest");
	Query.action = IntegrationWith1CDocumentManagementCore.StringInXDTOObject(Proxy, ActionXDTOString);
	
	Return IntegrationWith1CDocumentManagementCore.ExecuteRequestAsynchronously(
		Proxy,
		Query,
		FormUniqueID,
		NStr("vi = 'Kiểm tra người tham gia thao tác';
			|ru = 'Проверка участников действия';
			|en = 'Check action participants'; fa = 'Check action participants';
			|it = 'Проверка участников действия';
			|pl = 'Check action participants';
			|tr = 'Eylem katılımcılarının kontrolü'"));
	
EndFunction

#EndRegion

#Region GeneralProceduresAndFunctions

// Change the deadline (exact date or relative deadline) for the Presentation.
//
// Parameters:
//   Date - Date - due date (exact date).
//   Days - Number - relative time, days.
//   Hours1 - Number - relative time, hours.
//   Minutes1 - Number - relative time, minutes.
//   OptionForSettingDeadline - String - option to set the deadline.
//   Presentation - String - Presentation of the term by a string.
//   TermChangeParameters - See IntegrationWith1CDocumentManagement3ClientServer.ParametersForChangingDeadlineForSubmission
//
// Returns:
//   Boolean
//
Function ChangeDeadlineForExecutionByPresentation(Date, Days, Hours1, Minutes1, OptionForSettingDeadline, Presentation,
		TermChangeParameters) Export
	
	Result = True;
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		"DMGetDueDateByDueDatePresentationRequest");
	
	Query.oldDueDate = Date;
	Query.oldDueDateDays = Days;
	Query.oldDueDateHours = Hours1;
	Query.oldDueDateMinutes = Minutes1;
	Query.dueDatePresentation = Presentation;
	If ValueIsFilled(OptionForSettingDeadline) Then
		Query.oldDueDateSpecificationVariant = OptionForSettingDeadline;
	EndIf;
	
	If ValueIsFilled(TermChangeParameters.PerformerID)
			And ValueIsFilled(TermChangeParameters.PerformerType) Then
		Performer = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
			TermChangeParameters.PerformerID,
			TermChangeParameters.PerformerType,
			TermChangeParameters.Performer);
		DataMainObjectOfAddressingExecutor =
			IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
				TermChangeParameters.MainAddressingObjectPerformerID,
				TermChangeParameters.MainAddressingObjectPerformerType,
				TermChangeParameters.MainAddressingObjectPerformer);
		DataIsAdditionalAddressingObjectPerformer =
			IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
				TermChangeParameters.AdditionalAddressingObjectExecutorID,
				TermChangeParameters.AdditionalAddressingObjectExecutorType,
				TermChangeParameters.AdditionalAddressingObjectExecutor);
		Query.participant = IntegrationWith1CDocumentManagement3.MemberOfXDTOTasks(
			Proxy,
			Performer,
			DataMainObjectOfAddressingExecutor,
			DataIsAdditionalAddressingObjectPerformer);
	EndIf;
	
	Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	
	If IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, Response, "DMError") Then
		Result = False;
		TermChangeParameters.TextOfWarningMessage = TrimAll(Response.description);
		// Let's write the full text of the error in the LR.
		IntegrationWith1CDocumentManagementCore.RecordXDTOError(Response);
	Else
		Result = Response.result;
		TermChangeParameters.TextOfWarningMessage = Response.warningMessageText;
		Date = Response.dueDate;
		Days = Response.dueDateDays;
		Hours1 = Response.dueDateHours;
		Minutes1 = Response.dueDateMinutes;
		OptionForSettingDeadline = Response.dueDateSpecificationVariant;
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the navigation link that opens the linked 1C database:Document flow.
//
// Parameters:
//   WithoutAuthorization - Boolean - You should add authorization parameters to the navigation link.
//
// Returns:
//   String
//
Function NavigationLinkOfDatabaseDM(WithoutAuthorization = False) Export
	
	DataOfSUBAsset = InformationRegisters.DataOf1CDocumentManagementNodes.DataOfSUBAsset(
		SessionParameters.IntegrationWith1CDocumentManagementNode);
	If ValueIsFilled(DataOfSUBAsset.ExternalURLHostAddress) Then
		
		If DataOfSUBAsset.LocationTypeOfExternalURLHostAddress =
				Enums.InfobaseLocationType.OnThisComputer Then
			HostAddress = StrTemplate("e1c://filev/%1", DataOfSUBAsset.ExternalURLHostAddress);
			
		ElsIf DataOfSUBAsset.LocationTypeOfExternalURLHostAddress =
				Enums.InfobaseLocationType.OnLANComputer Then
			HostAddress = StrTemplate("e1c://file/%1", DataOfSUBAsset.ExternalURLHostAddress);
			
		ElsIf DataOfSUBAsset.LocationTypeOfExternalURLHostAddress =
				Enums.InfobaseLocationType.At1CEnterpriseServer Then
			HostAddress = StrTemplate("e1c://server/%1", DataOfSUBAsset.ExternalURLHostAddress);
			
		Else
			HostAddress = DataOfSUBAsset.ExternalURLHostAddress;
			
		EndIf;
		
	Else
		HostAddress = IntegrationWith1CDocumentManagementCore.AddressOf1CDocumentManagementWebService();
	EndIf;
	
	If WithoutAuthorization = False
			And SessionParameters.IntegrationWith1CDocumentManagementPasswordIsKnown
			And Not SessionParameters.IntegrationWith1CDocumentManagementOSAuthenticationIsUsed
			And Not SessionParameters.IntegrationWith1CDocumentManagementJWTTokenAuthenticationIsUsed Then
		Address = StrTemplate("%1?N=%2&P=%3",
			HostAddress,
			SessionParameters.IntegrationWith1CDocumentManagementUsername,
			SessionParameters.IntegrationWith1CDocumentManagementPassword);
	Else
		Address = HostAddress;
	EndIf;
	
	Return Address;
	
EndFunction

// Starts in 1C:Document processing of the object.
//
// Parameters:
//   ObjectBefore - Structure- the object BEFORE you want to start processing:
//     * ID - String
//     * type - String
//     * name - String
//     * ExternalObject - AnyRef - a link to the associated IP object.
//   ObjectNeedsToBeUpdatedTO - Boolean - True if the object needs to be updated TO before starting processing.
//   ErrorText - String - implicitly returned value, error message text.
//
// Returns:
//   Boolean - True if the processing was started successfully.
//
Function StartProcessing(ObjectBefore, ObjectNeedsToBeUpdatedTO, ErrorText) Export
	
	Success = True;
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	DataProcessorData = IntegrationWith1CDocumentManagement3ClientServer.DataProcessorData(ObjectBefore.ID, ObjectBefore.type);
	ExternalObject = Undefined;
	ObjectBefore.Property("ExternalObject", ExternalObject);
	ObjectNeedsToBeUpdatedTO = (ObjectNeedsToBeUpdatedTO And ValueIsFilled(ExternalObject));
	
	PackageQueries = New Array;
	
	If ObjectNeedsToBeUpdatedTO Then
		ControlOverSendingFiles = Undefined; // See IntegrationWith1CDocumentManagementCore.ControlOverSendingFiles
		RequestToUpdateObject = IntegrationWith1CDocumentManagement3Exchange.RequestToUpdateObject(
			Proxy,
			ExternalObject,
			ControlOverSendingFiles);
		If RequestToUpdateObject = Undefined Then
			ObjectNeedsToBeUpdatedTO = False;
		Else
			PackageQueries.Add(RequestToUpdateObject);
		EndIf;
	EndIf;
	
	PackageQueries.Add(
		IntegrationWith1CDocumentManagement3.StartProcessingRequest(Proxy, DataProcessorData, ExternalObject));
	
	ResponseToPackageRequests = IntegrationWith1CDocumentManagementCore.ExecuteBatchRequest(
		Proxy,
		PackageQueries);
	
	If ObjectNeedsToBeUpdatedTO Then
		AnswerIsToUpdateObject = ResponseToPackageRequests.responses[0];
		ResponseStartProcessing = ResponseToPackageRequests.responses[1];
		
		If IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, AnswerIsToUpdateObject, "DMError") Then
			IntegrationWith1CDocumentManagementCore.RecordXDTOError(AnswerIsToUpdateObject);
		Else
			// The object BEFORE was successfully updated.
			For Each String In ControlOverSendingFiles Do
				InformationRegisters.ControlOverSendingFilesTo1CDocumentManagement.SaveHashSumOfFileVersion(
					String.Source,
					String.FileName,
					String.SpreadsheetDocument)
			EndDo;
		EndIf;
	Else
		ResponseStartProcessing = ResponseToPackageRequests.responses[0];
	EndIf;
	
	If IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, ResponseStartProcessing, "DMError") Then
		Success = False;
		ErrorText = TrimAll(ResponseStartProcessing.description);
		// Let's write the full text of the error in the LR.
		IntegrationWith1CDocumentManagementCore.RecordXDTOError(ResponseStartProcessing);
	EndIf;
	
	Return Success;
	
EndFunction

// Retrieves from the Document Flow the rules for uploading data to the DO that are suitable for the specified type of IC object.
//
// Parameters:
//   ObjectTypeIS - String - the full name of the IP object type.
//   RulesForLoadingXDTO - XDTOList - a list of loading rules that, for optimization purposes, could have been
//      obtained earlier in a batch request to 1C:Document flow.
//
// Returns:
//   Array of Structure:
//     * VDOLoadingRule - String
//     * VDOLoadingRuleID - String
//     * ObjectTypeDM - String
//     * DocumentKindDM - String
//     * DocumentKindDMID - String
//
Function SuitableRulesForLoadingVDO(ObjectTypeIS, Val RulesForLoadingXDTO = Undefined) Export
	
	Result = New Array;
	
	If Not ValueIsFilled(ObjectTypeIS) Then
		Return Result;
	EndIf;
	
	If RulesForLoadingXDTO = Undefined Then
		Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
		
		Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMGetDataLoadingRulesRequest");
		Query.externalObjectType = ObjectTypeIS;
		
		Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
		IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Response);
		
		RulesForLoadingXDTO = Response.dataLoadingRules;
	EndIf;
	
	For Each XDTOUploadRule In RulesForLoadingXDTO Do
		Rule = New Structure;
		
		Rule.Insert("VDOLoadingRule", XDTOUploadRule.objectName);
		Rule.Insert("VDOLoadingRuleID", XDTOUploadRule.objectID.id);
		Rule.Insert("URL", XDTOUploadRule.objectID.navigationRef);
		
		Rule.Insert("ObjectTypeDM", XDTOUploadRule.objectType);
		
		If IntegrationWith1CDocumentManagementCore.PropertySet(
				XDTOUploadRule, "documentType") Then
			Rule.Insert("DocumentKindDM", XDTOUploadRule.documentType.name);
			Rule.Insert("DocumentKindDMID", XDTOUploadRule.documentType.objectID.ID);
		EndIf;
		
		Result.Add(Rule);
	EndDo;
	
	Return Result;
	
EndFunction

// Selects the appropriate integration rules for the transferred IP objects.
//
// Parameters:
//   ListOfIPObjects - Array of DefinedType.IntegrationWith1CWorkflowAllLinksOverridable - a list
//     of IP objects for which you need to select the appropriate integration rules.
//   PriorityOnly - Boolean - The rules will be sorted by priority, and only the
//     rules with the highest priority will be selected. The more key Attributes of the rule match the values of the Attributes
//     of the IP object, the higher the priority of the rule for this particular IP object.
//   CollapseByRuleTO - Boolean - collapse the final list of suitable integration rules
//     using the link to the rule for uploading data to the DO specified in them.
//
// Returns:
//   Map of KeyAndValue:
//     * Key - DefinedType.IntegrationWith1CWorkflowAllLinksOverridable - the IP object.
//     * Value - Array of CatalogRef.RulesForIntegrationWith1CDocumentManagement3 - a list of suitable rules.
//
Function SuitableIntegrationRules(ListOfIPObjects, PriorityOnly = False, CollapseByRuleTO = False) Export
	
	Result = New Map;
	
	If ListOfIPObjects.Count() = 0 Then
		Return Result;
	EndIf;
	
	// Let's form an array of the types of transferred IP objects without repetition.
	ArrayOfICObjectTypes = New Array;
	For Each ObjectIS In ListOfIPObjects Do
		ObjectTypeIS = ObjectIS.Metadata().FullName();
		If ArrayOfICObjectTypes.Find(ObjectTypeIS) = Undefined Then
			ArrayOfICObjectTypes.Add(ObjectTypeIS);
		EndIf;
	EndDo;
	
	// Let's find the integration rules corresponding to the specified types.
	// Let's select the names and values of the key Attributes specified in them.
	RequestAllRules = New Query(
		"SELECT
		|	RulesForIntegrationWith1CDocumentManagement3.ObjectTypeIS AS ObjectTypeIS,
		|	RulesForIntegrationWith1CDocumentManagement3.Ref AS Rule,
		|	RulesForIntegrationWith1CDocumentManagement3.DMDataLoadingRule AS DMDataLoadingRule,
		|	RulesForIntegrationWith1CDocumentManagement3.UseApplicabilityConditionWhenExporting AS UseApplicabilityConditionWhenExporting,
		|	RulesForIntegrationWith1CDocumentManagement3.ApplicabilityConditionOnExport AS ApplicabilityConditionOnExport,
		|	RulesForIntegrationWith1CDocumentManagement3KeyAttributesIS.Name AS AttributeName,
		|	RulesForIntegrationWith1CDocumentManagement3KeyAttributesIS.IsAdditionalAttributeIS AS IsAdditionalAttributeIS,
		|	RulesForIntegrationWith1CDocumentManagement3KeyAttributesIS.AttributeValue AS Value
		|INTO AllRules
		|FROM
		|	Catalog.RulesForIntegrationWith1CDocumentManagement3 AS RulesForIntegrationWith1CDocumentManagement3
		|		LEFT JOIN Catalog.RulesForIntegrationWith1CDocumentManagement3.KeyAttributesIS AS RulesForIntegrationWith1CDocumentManagement3KeyAttributesIS
		|		ON (RulesForIntegrationWith1CDocumentManagement3KeyAttributesIS.Ref = RulesForIntegrationWith1CDocumentManagement3.Ref)
		|WHERE
		|	NOT RulesForIntegrationWith1CDocumentManagement3.DeletionMark
		|	AND RulesForIntegrationWith1CDocumentManagement3.ObjectTypeIS IN(&ArrayOfICObjectTypes)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AllRules.ObjectTypeIS AS ObjectTypeIS,
		|	AllRules.Rule AS Rule,
		|	AllRules.DMDataLoadingRule AS DMDataLoadingRule,
		|	AllRules.UseApplicabilityConditionWhenExporting AS UseApplicabilityConditionWhenExporting,
		|	AllRules.ApplicabilityConditionOnExport AS ApplicabilityConditionOnExport,
		|	AllRules.AttributeName AS AttributeName,
		|	AllRules.IsAdditionalAttributeIS AS IsAdditionalAttributeIS,
		|	AllRules.Value AS Value
		|FROM
		|	AllRules AS AllRules
		|TOTALS
		|	MAX(DMDataLoadingRule)
		|BY
		|	ObjectTypeIS,
		|	Rule
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	AllRules.ObjectTypeIS AS ObjectTypeIS,
		|	CASE
		|		WHEN AllRules.IsAdditionalAttributeIS
		|			THEN """"
		|		ELSE AllRules.AttributeName
		|	END AS AttributeName,
		|	AllRules.IsAdditionalAttributeIS AS IsAdditionalAttributeIS
		|FROM
		|	AllRules AS AllRules
		|WHERE
		|	NOT AllRules.AttributeName IS NULL
		|TOTALS BY
		|	ObjectTypeIS");
	RequestAllRules.SetParameter("ArrayOfICObjectTypes", ArrayOfICObjectTypes);
	
	ArrayOfResultsAllRules = RequestAllRules.ExecuteBatch();
	TablesQuantity = ArrayOfResultsAllRules.Count();
	
	SelectionRulesGroupingByType = ArrayOfResultsAllRules[TablesQuantity - 2].Select(
		QueryResultIteration.ByGroups);
	
	SampleAttributesForAnalysis = ArrayOfResultsAllRules[TablesQuantity - 1].Select(
		QueryResultIteration.ByGroups);
	
	// We will dynamically generate and execute a query that will select from the database a list of IP objects
	// for which integration rules are to be selected, as well as the values of their Attributes,
	// which we will analyze when searching for a suitable rule.
	RequestObjectData = New Query;
	RequestObjectData.SetParameter("ListOfIPObjects", ListOfIPObjects);
	ArrayOfGeneralQueryText = New Array;
	
	For Each ObjectTypeIS In ArrayOfICObjectTypes Do
		RequestTextForType = StrReplace(
			"SELECT
			|	""&ObjectTypeIS"" AS ObjectTypeIS,
			|	&SelectingFields,
			|	ObjectIS.Ref AS Ref
			|FROM
			|	&ObjectTypeIS AS ObjectIS
			|WHERE
			|	ObjectIS.Ref IN(&ListOfIPObjects)",
			"&ObjectTypeIS",
			ObjectTypeIS);
		
		SelectingFields = "";
		SampleAttributesForAnalysis.Reset();
		If SampleAttributesForAnalysis.FindNext(ObjectTypeIS, "ObjectTypeIS") Then
			ArraySelectionOfFields = New Array;
			SelectionDetailRecords = SampleAttributesForAnalysis.Select();
			While SelectionDetailRecords.Next() Do
				If Not SelectionDetailRecords.IsAdditionalAttributeIS Then
					ArraySelectionOfFields.Add(StrTemplate("ObjectIS.%1 AS %1", SelectionDetailRecords.AttributeName));
				EndIf;
			EndDo;
			
			If ArraySelectionOfFields.Count() > 0 Then
				SelectingFields = StrConcat(ArraySelectionOfFields, ", ") + ", ";
			EndIf;
		EndIf;
		
		ArrayOfGeneralQueryText.Add(StrReplace(RequestTextForType, "&SelectingFields,", SelectingFields));
	EndDo;
	
	RequestObjectData.Text = StrConcat(ArrayOfGeneralQueryText, " ; ");
	ArrayOfResultsObjectData = RequestObjectData.ExecuteBatch();
	
	// For each of the IC objects, we will sort through all the rules that match them by type, and add to the
	// function result those of the rules that match the key Attributes for a particular object.
	IndexOf = 0;
	For Each ObjectTypeIS In ArrayOfICObjectTypes Do
		SelectionRulesGroupingByType.Reset();
		If SelectionRulesGroupingByType.FindNext(ObjectTypeIS, "ObjectTypeIS") Then
			ThereAreRules = True;
			RuleSelection_ = SelectionRulesGroupingByType.Select(QueryResultIteration.ByGroups);
		Else
			ThereAreRules = False;
		EndIf;
		
		ObjectDataTable = ArrayOfResultsObjectData[IndexOf].Unload();
		For Each IPObjectData In ObjectDataTable Do
			SuitableRules = New ValueTable;
			SuitableRules.Columns.Add("Rule",
				New TypeDescription("CatalogRef.RulesForIntegrationWith1CDocumentManagement3"));
			SuitableRules.Columns.Add("Priority",
				New TypeDescription("Number"));
			SuitableRules.Columns.Add("DMDataLoadingRule",
				New TypeDescription("String"));
			
			If ThereAreRules Then
				RuleSelection_.Reset();
				While RuleSelection_.Next() Do
					TheseRules = RuleSelection_.Select();
					Priority = 0;
					
					If RuleFitsObject(TheseRules, IPObjectData, Priority) Then
						AppropriateRulesLine = SuitableRules.Add();
						AppropriateRulesLine.Rule = RuleSelection_.Rule;
						AppropriateRulesLine.Priority = Priority;
						AppropriateRulesLine.DMDataLoadingRule = RuleSelection_.DMDataLoadingRule;
					EndIf;
				EndDo;
			EndIf;
			
			// We will return only the rules with the highest priority.
			RulesWithHighestPriority = New Array;
			If SuitableRules.Count() > 0 Then
				
				LinksToRulesDM = New Array;
				SuitableRules.Sort("Priority DESC");
				MaxPriority = SuitableRules[0].Priority;
				
				For Each String In SuitableRules Do
					
					If CollapseByRuleTO
							And LinksToRulesDM.Find(String.DMDataLoadingRule) <> Undefined Then
						Continue;
					EndIf;
					
					If (String.Priority = MaxPriority) Or Not PriorityOnly Then
						RulesWithHighestPriority.Add(String.Rule);
						LinksToRulesDM.Add(String.DMDataLoadingRule);
					Else
						Break;
					EndIf;
					
				EndDo;
				
			EndIf;
			
			Result.Insert(IPObjectData.Ref, RulesWithHighestPriority);
		EndDo;
		IndexOf = IndexOf + 1;
	EndDo;
	
	Return Result;
	
EndFunction

// Selects the appropriate integration rules for the transferred IP object.
//
// Parameters:
//   ObjectIS - DefinedType.IntegrationWith1CWorkflowAllLinksOverridable - the IP object
//     for which it is required to select the appropriate integration rules.
//   PriorityOnly - Boolean - The rules will be sorted by priority, and only the
//     rules with the highest priority will be selected. The more key Attributes of the rule match the values of the Attributes
//     of the IP object, the higher the priority of the rule for this particular IP object.
//   AdditionalInformation_3 - Boolean - if true, instead of an array of rules, an array of structures containing, in addition
//     to a reference to the rule itself, the values of its key Attributes will be returned.
//
// Returns:
//   Array of CatalogRef.RulesForIntegrationWith1CDocumentManagement3 - a list of suitable rules.
//   See IntegrationWith1CDocumentManagementCoreClientServer.TheseIntegrationRules
//
Function SuitableObjectIntegrationRules(ObjectIS, PriorityOnly = False, AdditionalInformation_3 = False) Export
	
	ListOfIPObjects = New Array;
	ListOfIPObjects.Add(ObjectIS);
	SuitableIntegrationRules = SuitableIntegrationRules(ListOfIPObjects, PriorityOnly);
	SuitableObjectIntegrationRules = SuitableIntegrationRules[ObjectIS];
	If SuitableObjectIntegrationRules = Undefined Then
		SuitableObjectIntegrationRules = New Array;
	EndIf;
	
	If Not AdditionalInformation_3 Then
		Return SuitableObjectIntegrationRules;
	EndIf;
	
	Result = New Array;
	
	Query = New Query(
		"SELECT
		|	Rules.Ref AS Ref,
		|	Rules.ObjectTypeIS AS ObjectTypeIS,
		|	Rules.ObjectTypeDM AS ObjectTypeDM,
		|	Rules.ObjectPresentationIS AS ObjectPresentationIS,
		|	Rules.ObjectPresentationDM AS ObjectPresentationDM,
		|	Rules.DocumentKindDM AS DocumentKindDM,
		|	Rules.DocumentKindDMID AS DocumentKindDMID
		|FROM
		|	Catalog.RulesForIntegrationWith1CDocumentManagement3 AS Rules
		|WHERE
		|	Rules.Ref IN(&SuitableObjectIntegrationRules)");
	Query.SetParameter("SuitableObjectIntegrationRules", SuitableObjectIntegrationRules);
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		Rule = IntegrationWith1CDocumentManagementCoreClientServer.TheseIntegrationRules();
		Rule.Ref = Selection.Ref;
		Rule.ObjectTypeIS = Selection.ObjectTypeIS;
		Rule.ObjectTypeDM = Selection.ObjectTypeDM;
		Rule.ObjectPresentationIS = Selection.ObjectPresentationIS;
		Rule.ObjectPresentationDM = Selection.ObjectPresentationDM;
		Rule.PresentationOfTheDocumentType = Selection.DocumentKindDM;
		Rule.IDOfDocumentType = Selection.DocumentKindDMID;
		Rule.TypeOfDocumentType = ?(ValueIsFilled(Selection.DocumentKindDMID), "DMDocumentType", "");
		
		Result.Add(Rule);
	EndDo;
	
	Return Result;
	
EndFunction

// Selects the appropriate integration rules for the transferred type of IP objects.
//
// Parameters:
//   ObjectTypeIS - String - type of IP objects.
//
// Returns:
//   Array of See IntegrationWith1CDocumentManagementCoreClientServer.TheseIntegrationRules
//
Function SuitableIntegrationRulesForTypeOfIPObject(ObjectTypeIS) Export
	
	Result = New Array;
	
	AllIntegrationRules = IntegrationWith1CDocumentManagement3Cached.AllIntegrationRules();
	
	FoundRules = AllIntegrationRules.FindRows(New Structure("ObjectTypeIS", ObjectTypeIS));
	For Each TheseRules In FoundRules Do
		Rule = IntegrationWith1CDocumentManagementCoreClientServer.TheseIntegrationRules();
		Rule.Ref = TheseRules.Ref;
		Rule.ObjectTypeIS = TheseRules.ObjectTypeIS;
		Rule.ObjectTypeDM = TheseRules.ObjectTypeDM;
		Rule.ObjectPresentationIS = TheseRules.ObjectPresentationIS;
		Rule.ObjectPresentationDM = TheseRules.ObjectPresentationDM;
		Rule.PresentationOfTheDocumentType = TheseRules.DocumentKindDM;
		Rule.IDOfDocumentType = TheseRules.DocumentKindDMID;
		Rule.TypeOfDocumentType = ?(ValueIsFilled(TheseRules.DocumentKindDMID), "DMDocumentType", "");
		
		Result.Add(Rule);
	EndDo;
	
	Return Result;
	
EndFunction

// Returns a reference from the cache to the object BEFORE.
//
// Returns:
//   String - reference to the object BEFORE.
//
Function GetLinkToObjectBefore() Export
	
	Return SessionParameters.IntegrationWith1CDocumentManagementDMObject;
	
EndFunction

// Returns the data required to upload the IP object to the DO: a list of tabular parts of the IP object that are required
// to fill in the DO object; a list of expressions in the built-in language that need to be executed on the IP side for
// subsequent transfer of results to the DO side; a list of printed forms that need to be generated on the IP side;
// a list of links to the DO object being created, which are automatically generated based on the data of the IP object; a list of new
// objects that were created in the DO in accordance with the settings for automatic creation of links; a list
// of mandatory links that need to be selected interactively.
//
// Parameters:
//   ObjectIS - Arbitrary - the IP object, on the basis of which the object is created BEFORE.
//   Rule - CatalogRef.RulesForIntegrationWith1CDocumentManagement3 - rule for filling in an item BEFORE.
//
// Returns:
//   Structure:
//     * PreliminaryDataInRepository - String - the address in the temporary storage containing
//         the structure See IntegrationWith1CDocumentManagement3.PreliminaryDataForUnloadingVDO
//     * NewObjectsBefore - Array of See IntegrationWith1CDocumentManagement3ClientServer.NewObjectBefore
//     * RequiredLinks - Array of See IntegrationWith1CDocumentManagementCoreClientServer.SettingUpConnectionOfObjectsTO
//
Function PreliminaryDataForUnloadingVDO(ObjectIS, Rule) Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	ListOfIPObjects = CommonClientServer.ValueInArray(ObjectIS);
	
	SuitableIntegrationRules = New Map;
	SuitableIntegrationRules.Insert(ObjectIS, CommonClientServer.ValueInArray(Rule));
	
	NewObjectsBefore = New Array;
	
	PreliminaryData = IntegrationWith1CDocumentManagement3.PreliminaryDataForUnloadingVDO(
		Proxy,
		ListOfIPObjects,
		SuitableIntegrationRules,,,
		NewObjectsBefore);
	PreliminaryDataInRepository = PutToTempStorage(
		PreliminaryData,
		New UUID);
	
	Result = New Structure;
	Result.Insert("PreliminaryDataInRepository", PreliminaryDataInRepository);
	Result.Insert("NewObjectsBefore", NewObjectsBefore);
	Result.Insert("RequiredLinks", New Array);
	If PreliminaryData.ComplianceOfMandatoryLinksWithIPObjects[ObjectIS] <> Undefined Then
		Result.RequiredLinks = PreliminaryData.ComplianceOfMandatoryLinksWithIPObjects[ObjectIS];
	EndIf;
	
	Return Result;
	
EndFunction

// Places a reference to the object in the cache BEFORE.
//
// Parameters:
//   ObjectBefore - String - reference to the object BEFORE.
//
Procedure SetObjectReferenceTO(ObjectBefore) Export
	
	SessionParameters.IntegrationWith1CDocumentManagementDMObject = ObjectBefore;
	
EndProcedure

// Checks whether the transmitted document type describes UP to 3.
//
// Parameters:
//   XDTOObjectType - String - object type.
//
// Returns:
//   Boolean
//
Function IsDocumentBefore3(XDTOObjectType) Export
	
	Return IntegrationWith1CDocumentManagement3.IsDocumentBefore3(XDTOObjectType);
	
EndFunction

// Checks whether the passed type describes a known review object.
//
// Parameters:
//   XDTOObjectType - String - object type.
//
// Returns:
//   Boolean
//
Function ThisIsWellKnownObjectOfReview(Val XDTOObjectType) Export
	
	Return IntegrationWith1CDocumentManagement3.ThisIsWellKnownObjectOfReview(XDTOObjectType);
	
EndFunction

#EndRegion

#Region Files

// Changes file roles.
//
// Parameters:
//   Files - Array of See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//   SelectedRoleID - String - ID of the new file role.
//
Procedure ReplaceRoleOfFiles(Files, SelectedRoleID) Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy,"DMChangeFilesRoleRequest");
	
	Query.newRole = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMFileRole");
	Query.newRole.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		SelectedRoleID,
		"DMFileRole");
	Query.newRole.name = "";
	
	FilesForChangingRoles = Query.files; // XDTOList
	For Each File In Files Do
		XDTOFile = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMFile");
		XDTOFile.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
			Proxy,
			File.ID,
			File.Type);
		XDTOFile.name = "";
		FilesForChangingRoles.Add(XDTOFile);
	EndDo;
	
	Result = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Result);
	
EndProcedure

// Copies the attached object files stored on the IP side to the linked object on the DO side.
//
// Parameters:
//   AttachedVISFiles - ValueList of AnyRef - list of attached files in the IP.
//   OwnerID - String - ID of the file owner in the Document Flow.
//   OwnerType - String - the XDTO type of the file owner in the Document Flow.
//   OwnerIS - AnyRef - the reference to the object is the owner of the file in the IP.
//   FileRoleID - String - the role of the file.
//
// Returns:
//   Array of See IntegrationWith1CDocumentManagementCoreClientServer.FileData.
//
Function TransferFilesAndSvTO(AttachedVISFiles, OwnerID, OwnerType, OwnerIS,
		FileRoleID = Undefined) Export
	
	If Common.SubsystemExists("StandardSubsystems.FilesOperations") Then
		ModuleFilesOperations = Common.CommonModule("FilesOperations");
	Else
		Raise NStr("vi = 'Không có phân hệ chuẩn ""Làm việc với tệp""';
					|ru = 'Отсутствует стандартная подсистема ""Работа с файлами""';
					|en = 'The standard ""File management"" subsystem is missing'; fa = 'The standard ""File management"" subsystem is missing';
					|it = 'Отсутствует стандартная подсистема ""Работа с файлами""';
					|pl = 'The standard ""File management"" subsystem is missing';
					|tr = '""Dosyalar ile çalışma"" standart alt sistemi eksik'");
	EndIf;
	
	Common.CommonSettingsStorageSave(
		OwnerIS.Metadata().FullName(),
		"AskQuestionAboutTransferringFilesToDM",
		True);
	RefreshReusableValues();
	
	CreatedFiles = New Array;
	
	NmbrOfFiles = AttachedVISFiles.Count() - 1;
	For IndexOf = 0 To NmbrOfFiles Do
		
		FileNumber = NmbrOfFiles - IndexOf;
		VISFile = AttachedVISFiles[FileNumber].Value;
		FileData = ModuleFilesOperations.FileData(VISFile);
		
		CurrentFile = IntegrationWith1CDocumentManagementCoreClientServer.FileData(
			FileData.Description,
			Undefined,
			"DMFile",
			FileData.Extension,
			FileRoleID);
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
		CreationParameters.TempFileStorageAddress = FileData.RefToBinaryFileData;
		CreationParameters.Owner = OwnerIS;
		
		CreationParameters.ExternalObject.ID = String(VISFile.UUID());
		CreationParameters.ExternalObject.type = VISFile.Metadata().FullName();
		CreationParameters.ExternalObject.name = FileData.Description;
		
		CurrentFile.ID = IntegrationWith1CDocumentManagementCoreServerCall.CreateFileInWorkflow(
			CreationParameters,
			OwnerID,
			OwnerType);
		
		CreatedFiles.Add(CurrentFile);
		
		AttachedVISFiles.Delete(FileNumber);
		
	EndDo;
	
	Return CreatedFiles;
	
EndFunction

// Receives binary data from the EDI document file and places it in temporary storage.
//
// Parameters:
//   ID - String - ID of the EDI document.
//   Type - String - the type of EDI document.
//   FormUniqueID - UUID - ID of the calling form.
//   Extension - String - implicitly returned value, file extension.
//   Description - String - implicitly returned value, file name.
//
// Returns:
//   String - the address in the temporary storage with the binary data of the file.
//
Function GetDocumentFileAndPutItInRepository(ID, Type, FormUniqueID,
		Extension = "", Description = "") Export
	
	If Not IntegrationWith1CDocumentManagement3.FunctionalityOfGettingMainFileOfEDIDocumentIsAvailable() Then
		Raise
			NStr("vi = 'Tính năng nhận tệp văn bản chính của HTQLVBĐT không được hỗ trợ trong phiên bản 1C:Document Management.
				|Cần có phiên bản 1C:Document Management từ 3.0.18 trở lên.';
				|ru = 'Функционал получения основного файла документа ЭДО не поддерживается в данной версии 1С:Документооборота.
				|Требуется 1С:Документооборот версии 3.0.18 или выше.';
				|en = 'Functionality of receiving the main EDI document file is not supported in this version of 1C:Document Management.
				|Version 3.0.18 or later is required.'; fa = 'Functionality of receiving the main EDI document file is not supported in this version of 1C:Document Management.
				|Version 3.0.18 or later is required.';
				|it = 'Functionality of receiving the main EDI document file is not supported in this version of 1C:Document Management.
				|Version 3.0.18 or later is required.';
				|pl = 'Functionality of receiving the main EDI document file is not supported in this version of 1C:Document Management.
				|Version 3.0.18 or later is required.';
				|tr = 'EDI belgesinin temel dosyasını alma işlevi,  1C:Document Management''ın bu sürümünde desteklenmemektedir.
				|1C:Document Management 3.0.18 veya üstü sürüm gerekmektedir.'");
	EndIf;
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	DocumentEDI = IntegrationWith1CDocumentManagementCore.GetObject(Proxy, Type, ID);
	If Not IntegrationWith1CDocumentManagementCore.PropertySet(DocumentEDI, "mainFile")
			Or TypeOf(DocumentEDI.mainFile.binaryData) <> Type("BinaryData") Then
		Raise NStr("vi = 'Không tìm thấy tệp văn bản chính của QLVBĐT.';
					|ru = 'Основной файл документа ЭДО не найден.';
					|en = 'The main EDI document file is not found.'; fa = 'The main EDI document file is not found.';
					|it = 'The main EDI document file is not found.';
					|pl = 'The main EDI document file is not found.';
					|tr = 'EDI belgesinin temel dosyası bulunamadı.'");
	EndIf;
	
	Address = PutToTempStorage(DocumentEDI.mainFile.binaryData, FormUniqueID);
	Description = DocumentEDI.mainFile.name;
	Extension = DocumentEDI.mainFile.extension;
	
	Return Address;
	
EndFunction

#EndRegion

#Region Tasks

// Updates additional task data that is in temporary storage.
//
// Parameters:
//   AdditionalDataAddress - String - the address of the additional task data in the temporary storage.
//   NewVersionOfTheData - String - new version of the task data.
//   NewResultOfActionIsText - String - new result of the task action.
//
Procedure UpdateTaskData(AdditionalDataAddress, NewVersionOfTheData, NewResultOfActionIsText) Export
	
	AdditionalInformationOnIssue = Undefined;
	If IsTempStorageURL(AdditionalDataAddress) Then
		AdditionalInformationOnIssue = GetFromTempStorage(AdditionalDataAddress); // See IntegrationWith1CDocumentManagement3.AdditionalInformationOnIssue
	EndIf;
	
	If AdditionalInformationOnIssue <> Undefined Then
		AdditionalInformationOnIssue.Scope.ResultOfActionInText = NewResultOfActionIsText;
		AdditionalInformationOnIssue.Scope.DataVersionOfTaskAction = NewVersionOfTheData;
	EndIf;
	
EndProcedure

// Saves the result of the task.
//
// Parameters:
//   ResultOfActionInText - String - comment on the issue.
//   TaskActionID - String - the ID of the task.
//   DataVersionOfTaskAction - String - The current version of the task data.
//   AdditionalDataAddress - String - the address of the additional task data in the temporary storage.
//
// Returns:
//   String - new version of the data.
//   Undefined - if the functionality is not supported in the current version BEFORE.
//
Function SaveActionResult(ResultOfActionInText, TaskActionID, DataVersionOfTaskAction,
		AdditionalDataAddress) Export
	
	If Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("3.0.20.21") Then
		Return Undefined;
	EndIf;
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		"DMSaveTaskActionResultRequest");
	Query.taskAction = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		"DMTaskAction");
	Query.taskAction.name = "";
	Query.taskAction.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		TaskActionID,
		"DMTaskAction");
	Query.actionResultString = ResultOfActionInText;
	Query.dataVersion = DataVersionOfTaskAction;
	
	Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Response);
	
	UpdateTaskData(AdditionalDataAddress, Response.newDataVersion, ResultOfActionInText);
	
	Return Response.newDataVersion;
	
EndFunction

#EndRegion

#Region Actions

// Processes the result of checking the participants of the action.
//
// Parameters:
//   ResultOfCheckIsString - String -  string Presentation of the XDTO object
//     type DMCheckValidityOfActionParticipantsResponse.
//
// Returns:
//   Structure:
//     * Success - Boolean
//     * WarningText - String
//
Function ResultOfCheckingParticipantsOfAction(Val ResultOfCheckIsString) Export
	
	CheckResult = New Structure("Success, WarningText", True, "");
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	ResponseToRequest = IntegrationWith1CDocumentManagementCore.StringInXDTOObject(
		Proxy,
		ResultOfCheckIsString);
	
	If IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, ResponseToRequest, "DMError") Then
		CheckResult.Success = False;
		CheckResult.WarningText = TrimAll(ResponseToRequest.description);
	EndIf;
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(ResponseToRequest, "result")
			And ValueIsFilled(ResponseToRequest.result) Then
		CheckResult.Success = False;
		CheckResult.WarningText = TrimAll(ResponseToRequest.result);
	EndIf;
	
	Return CheckResult;
	
EndFunction

#EndRegion

#Region Links

// Adds a link of the specified type between two 1C objects:Document management.
//
// Parameters:
//   InitialObject - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM.
//   LinkedObject - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM.
//   LinkType - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM.
//   Comment - String - comments on object relationships.
//
Procedure AddObjectRelationshipsBefore(Val InitialObject, Val LinkedObject, Val LinkType,
		Val Comment = Undefined) Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Link = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMRelation");
	
	Link.object = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMRelatedObject");
	Link.object.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		InitialObject.ID,
		InitialObject.Type);
	Link.object.name = InitialObject.Presentation;
	
	Link.relatedObject = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMRelatedObject");
	Link.relatedObject.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		LinkedObject.ID,
		LinkedObject.Type);
	Link.relatedObject.name = LinkedObject.Presentation;
	
	Link.relationType = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMRelationType");
	Link.relationType.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		LinkType.ID,
		LinkType.Type);
	Link.relationType.name = LinkType.Presentation;
	
	If ValueIsFilled(Comment)
			And IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("3.0.18.19") Then
		Link.comment = Comment;
	EndIf;
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMAddRelationRequest");
	Query.relation = Link;
	
	Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Response);
	
EndProcedure

// Deletes a relationship of the specified type between two 1C objects:Document management.
//
// Parameters:
//   InitialObject - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM.
//   LinkedObject - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM.
//   LinkType - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM.
//
Procedure DeleteObjectLinksBEFORE(Val InitialObject, Val LinkedObject, Val LinkType) Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Link = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMRelation");
	
	Link.object = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMRelatedObject");
	Link.object.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		InitialObject.ID,
		InitialObject.Type);
	Link.object.name = InitialObject.Presentation;
	
	Link.relatedObject = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMRelatedObject");
	Link.relatedObject.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		LinkedObject.ID,
		LinkedObject.Type);
	Link.relatedObject.name = LinkedObject.Presentation;
	
	Link.relationType = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMRelationType");
	Link.relationType.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		LinkType.ID,
		LinkType.Type);
	Link.relationType.name = LinkType.Presentation;
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMRemoveRelationRequest");
	Query.relation = Link;
	
	Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Response);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Function RuleFitsObject(TheseRules, IPObjectData, Priority)
	
	RuleFits = True;
	
	While TheseRules.Next() Do
		If TheseRules.UseApplicabilityConditionWhenExporting Then
			
			RuleFits = IntegrationWith1CDocumentManagement3.ResultOfExpressionInEmbeddedLanguage(
				TheseRules.ApplicabilityConditionOnExport,
				IPObjectData.Ref.GetObject());
			Break;
			
		Else
			
			If Not ValueIsFilled(TheseRules.AttributeName) Then
				// The key Attributes are not set, we believe that the rule is appropriate
				Break;
				
			ElsIf TheseRules.IsAdditionalAttributeIS Then
				Property = IntegrationWith1CDocumentManagementCore.AdditionalAttributeByName(TheseRules.AttributeName);
				PropertyValue = PropertyManager.PropertyValue(IPObjectData.Ref, Property);
				If PropertyValue = Undefined Then
					// The additional property is not set in the object. But in the rules, the key Attribute can be set as empty.
					RuleFits = (TheseRules.Value = False) Or Not ValueIsFilled(TheseRules.Value);
					If Not RuleFits Then
						Break;
					EndIf;
					
				ElsIf PropertyValue <> TheseRules.Value Then
					RuleFits = False;
					Break;
					
				EndIf;
				
			ElsIf IPObjectData[TheseRules.AttributeName] <> TheseRules.Value Then
				RuleFits = False;
				Break;
				
			EndIf;
			
			Priority = Priority + 1;
			
		EndIf;
	EndDo;
	
	Return RuleFits;
	
EndFunction

#EndRegion