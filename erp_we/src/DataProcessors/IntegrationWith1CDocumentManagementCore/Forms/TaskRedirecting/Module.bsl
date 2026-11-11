#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("Task") Then
		Task = Parameters.Task;
		TaskID = Parameters.TaskID;
		TaskType = Parameters.TaskType;
	EndIf;
	
	If Parameters.Property("UseIntegrationBefore3") Then
		UseIntegrationBefore2 = False;
		UseIntegrationBefore3 = True;
	Else
		UseIntegrationBefore2 = True;
		UseIntegrationBefore3 = False;
	EndIf;
	
	UseCommunicationRules =
		IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("3.0.15.41");
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure WhomStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	FormOpenParameters = Undefined;
	Notification = New CallbackDescription("WhomStartChoiceCompletion", ThisObject);
	If UseIntegrationBefore3 Then
		ChoiceFormName = "DataProcessor.IntegrationWith1CDocumentManagement3.Form.AddressBook";
		ModuleIntegrationWith1CDocumentManagement3Client =
			CommonClient.CommonModule("IntegrationWith1CDocumentManagement3Client");
		FormOpenParameters = New Structure(
			"ContextOfCommunicationRules",
			ModuleIntegrationWith1CDocumentManagement3Client.ContextOfCommunicationRules(ThisObject, Item.Name));
	Else
		ChoiceFormName = "DataProcessor.IntegrationWith1CDocumentManagement.Form.SelectBusinessProcessPerformer";
	EndIf;
	
	OpenForm(
		ChoiceFormName,
		FormOpenParameters,
		ThisObject,,,,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure WhomStartChoiceCompletion(Result, NotificationParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Result.Property("Performer", Performer);
	Result.Property("PerformerID", PerformerID);
	Result.Property("PerformerType", PerformerType);
	
	Result.Property("MainAddressingObject", MainAddressingObject);
	Result.Property("MainAddressingObjectID", MainAddressingObjectID);
	Result.Property("MainAddressingObjectType", MainAddressingObjectType);
	
	Result.Property("AdditionalAddressingObject", AdditionalAddressingObject);
	Result.Property("AdditionalAddressingObjectID", AdditionalAddressingObjectID);
	Result.Property("AdditionalAddressingObjectType", AdditionalAddressingObjectType);
	
	Whom = IntegrationWith1CDocumentManagementCoreClientServer.PresentationOfTaskParticipant(
		Performer,
		MainAddressingObject,
		AdditionalAddressingObject);
	
EndProcedure

&AtClient
Procedure WhomAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		Filter = Undefined;
		If UseCommunicationRules Then
			ModuleIntegrationWith1CDocumentManagement3Client =
				CommonClient.CommonModule("IntegrationWith1CDocumentManagement3Client");
			Filter = New Structure(
				"ContextOfCommunicationRules",
				ModuleIntegrationWith1CDocumentManagement3Client.ContextOfCommunicationRules(ThisObject, Item.Name));
		EndIf;
		
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			?(UseIntegrationBefore3, "DMEmployee", "DMUser"),
			ChoiceData,
			Text,
			StandardProcessing,
			Filter);
	EndIf;
	
EndProcedure

&AtClient
Procedure WhomTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	ClearPerformers();
	If ValueIsFilled(Text) Then
		Filter = Undefined;
		If UseCommunicationRules Then
			ModuleIntegrationWith1CDocumentManagement3Client =
				CommonClient.CommonModule("IntegrationWith1CDocumentManagement3Client");
			Filter = New Structure(
				"ContextOfCommunicationRules",
				ModuleIntegrationWith1CDocumentManagement3Client.ContextOfCommunicationRules(ThisObject, Item.Name));
		EndIf;
		
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			?(UseIntegrationBefore3, "DMEmployee", "DMUser"),
			ChoiceData,
			Text,
			StandardProcessing,
			Filter);
		
		If ChoiceData.Count() = 1 And Not ChoiceData[0].Value.isNotAvailableAccordingCommunicationRules Then
			ClearPerformers();
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"Performer",
				ChoiceData[0].Value,
				StandardProcessing,
				ThisObject,,,
				False);
			Whom = IntegrationWith1CDocumentManagementCoreClientServer.PresentationOfTaskParticipant(
				Performer,
				MainAddressingObject,
				AdditionalAddressingObject);
			StandardProcessing = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure WhomChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	ClearPerformers();
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"Performer",
		ValueSelected,
		StandardProcessing,
		ThisObject,,,
		False);
	Whom = IntegrationWith1CDocumentManagementCoreClientServer.PresentationOfTaskParticipant(
		Performer,
		MainAddressingObject,
		AdditionalAddressingObject);
	
EndProcedure

&AtClient
Procedure WhomClearing(Item, StandardProcessing)
	
	ClearPerformers();
	Whom = IntegrationWith1CDocumentManagementCoreClientServer.PresentationOfTaskParticipant(
		Performer,
		MainAddressingObject,
		AdditionalAddressingObject);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Forward(Command)
	
	If Not ValueIsFilled(Performer) Then
		ClearMessages();
		CommonClient.MessageToUser(NStr("vi = 'Chưa chỉ ra người thực hiện nhiệm vụ.';
										|ru = 'Не указан исполнитель задачи.';
										|en = 'The task assignee is not specified.'; fa = 'The task assignee is not specified.';
										|it = 'Esecutore dell''obiettivo non indicato.';
										|pl = 'Wykonawca zadania nie jest określony.';
										|tr = 'Göreve atanan belirtilmedi.'"),, "Whom");
		Return;
	EndIf;
	
	Result = RedirectTask();
	If Result.Success Then
		OperationType = IntegrationWith1CDocumentManagementCoreClientServer.TypeOfOperationOnTask();
		OperationType.Forward = True;
		NotificationParameters = New Structure("ID, Type, OperationType", TaskID, TaskType, OperationType);
		Notify("Workflow_ActionOnTask", NotificationParameters);
		If IsOpen() Then
			Close(True);
		EndIf;
	Else
		ShowMessageBox(, Result.ErrorText);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ClearPerformers()
	
	Performer = "";
	PerformerID = "";
	PerformerType = "";
	
	MainAddressingObject = "";
	MainAddressingObjectID = "";
	MainAddressingObjectType = "";
	
	AdditionalAddressingObject = "";
	AdditionalAddressingObjectID = "";
	AdditionalAddressingObjectType = "";
	
EndProcedure

&AtServer
Function RedirectTask()
	
	Result = New Structure("Success, ErrorText", True, "");
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMRedirectTasksRequest");
	TaskList = Query.tasks; // XDTOList
	
	Query.Comment = Comment;
	
	XDTOTask = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		?(UseIntegrationBefore3, "DMTaskAction", "DMObject"));
	XDTOTask.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		TaskID,
		TaskType);
	XDTOTask.name = Task;
	TaskList.Add(XDTOTask);
	
	DataExecutor = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
		PerformerID,
		PerformerType,
		Performer);
	DataIsMainObject = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
		MainAddressingObjectID,
		MainAddressingObjectType,
		MainAddressingObject);
	DataIsAdditionalObject = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
		AdditionalAddressingObjectID,
		AdditionalAddressingObjectType,
		AdditionalAddressingObject);
	
	Query.performer = IntegrationWith1CDocumentManagementCore.TaskParticipant(
		Proxy,
		DataExecutor,
		DataIsMainObject,
		DataIsAdditionalObject);
	
	Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	
	If IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, Response, "DMError") Then
		Result.Success = False;
		ErrorTextArray = StrSplit(Response.description, "{");
		Result.ErrorText = TrimAll(ErrorTextArray[0]);
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion