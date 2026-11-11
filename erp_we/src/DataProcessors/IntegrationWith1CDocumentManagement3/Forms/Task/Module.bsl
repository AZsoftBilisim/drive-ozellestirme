#Region Variables

&AtClient
Var ApplicationTreeRowKey;

&AtClient
Var SavingCommentIsDone;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ThisIsThinWindowsClient = Not IntegrationWith1CDocumentManagementCore.ApplicationIsWebClient()
		And Common.IsWindowsClient();
	PagesOfCreationCommandsBasedOn = PutToTempStorage(New Map, UUID);
	
	AbbreviatedNameOfConfiguration =
		IntegrationWith1CDocumentManagementCore.AbbreviatedNameOfConfiguration();
	
	ID = Parameters.ID;
	Type = Parameters.type;
	SavedComment = Parameters.SavedComment;
	StateOfApplicationTree = Parameters.StateOfApplicationTree;
	StateOfApplicationTree = Parameters.StateOfApplicationTree;
	MainSubjectID = Parameters.MainSubjectID;
	MainSubjectType = Parameters.MainSubjectType;
	
	If ValueIsFilled(Parameters.DataByTask) Then
		
		HTMLTaskDescription = Parameters.DataByTask.PresentationHTML;
		TaskAction = Parameters.DataByTask.TaskAction; // See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
		Title = TaskAction.Description;
		DataProcessors.IntegrationWith1CDocumentManagementCore.SetNavigationLink(
			ThisObject,
			TaskAction.URL);
		
		AdditionalData = GetFromTempStorage(Parameters.DataByTask.AdditionalDataAddress);
		If AdditionalData <> Undefined Then
			AdditionalDataAddress = Parameters.DataByTask.AdditionalDataAddress;
			DisplayAdditionalData(AdditionalData);
		EndIf;
		
		IsInitialized = True;
		
	Else
		
		Title = NStr("vi = 'Kết nhập nhiệm vụ từ 1C:Document Management';
					|ru = 'Загрузка задачи из 1С:Документооборот';
					|en = 'Import a task from 1C:Document Management'; fa = 'Import a task from 1C:Document Management';
					|it = 'Загрузка задачи из 1С:Документооборот';
					|pl = 'Import a task from 1C:Document Management';
					|tr = '1C:Document Management''ten görev indirme'");
		
	EndIf;
	
	If Not IsBlankString(Parameters.SuitableObjects) And IsTempStorageURL(Parameters.SuitableObjects) Then
		SuitableObjects = GetFromTempStorage(Parameters.SuitableObjects);
		DisplayCreationCommandsBasedOn(SuitableObjects);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	TestConnection();
	
	// Expand the application tree.
	TreeType = IntegrationWith1CDocumentManagement3Client.TreeType();
	TreeType.ThisIsApplicationTree = True;
	IntegrationWith1CDocumentManagement3Client.ExpandTheTree(
		TreeType,
		ApplicationTree.GetItems(),
		Items.ApplicationTree,
		StateOfApplicationTree);
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If ShowPDFUsing1C Then
		ThisObject["PDFDocumentAttributes"] = Undefined;
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If Not IsOpen() Then
		Return;
	EndIf;
	
	If EventName = "IntegrationWith1CDocumentManagement_SuccessfulConnection" Then
		If Source <> ThisObject Then
			WhenConnecting();
		EndIf;
		
	ElsIf EventName = "ChangedResultOfTextAction" Then
		If Source = ThisObject
				Or TypeOf(Parameter) <> Type("Structure")
				Or Not Parameter.Property("Text")
				Or Not Parameter.Property("ID")
				Or Not Parameter.Property("Type")
				Or Not Parameter.Property("DataVersionOfTaskAction") Then
			Return;
		EndIf;
		If Parameter.ID = ID And Parameter.Type = Type Then
			SavedComment = Parameter.Text;
			ResultOfActionInText = Parameter.Text;
			DataVersionOfTaskAction = Parameter.DataVersionOfTaskAction;
			IntegrationWith1CDocumentManagement3ServerCall.UpdateTaskData(
				AdditionalDataAddress,
				Parameter.DataVersionOfTaskAction,
				Parameter.Text);
		EndIf;
		
	ElsIf EventName = "Workflow_ActionOnTask" Then
		If TypeOf(Parameter) = Type("Structure")
				And Parameter.Property("OperationType")
				And Parameter.Property("ID")
				And Parameter.Property("Type")
				And Parameter.ID = ID
				And Parameter.Type = Type Then
			If Parameter.OperationType.PerformTaskAction Or Parameter.OperationType.Forward Then
				If IsOpen() Then
					Close(Parameter.OperationType);
				EndIf;
			Else
				If Source = ThisObject Then
					Return;
				EndIf;
				UpdateForm(False, False, True);
			EndIf;
		EndIf;
		
	ElsIf EventName = "HTMLObjectPreviewReceived" Then
		If Not IntegrationWith1CDocumentManagementCoreClientServer.TheseAreNotificationParametersHTMLObjectPreviewReceived(
				Parameter) Then
			Return;
		EndIf;
		ProcessHTMLPreviewReceiptEvent(Parameter, Source);
		
	ElsIf EventName = "Recording_1CDocumentManagementFile" Then
		If TypeOf(Parameter) <> Type("Structure")
				Or Not Parameter.Property("FileOperation")
				Or Not Parameter.Property("FileID")
				Or Not Parameter.Property("FileOwner")
				Or Not Parameter.Property("FileName")
				Or Not Parameter.Property("FormUniqueID")
				Or Not Parameter.FileOperation.InformFileListForm Then
			Return;
		EndIf;
		NeedUpdate = False;
		AppUpdateOptions = AppUpdateOptions("DMFile");
		AppUpdateOptions.ReadingAttributes = New Structure("IsBeingEdited", Undefined);
		UpdateComplete = UpdateAppByID(Parameter.FileID, AppUpdateOptions);
		If UpdateComplete Then
			// The modified file is in the application tree.
			NeedUpdate = True;
			If Parameter.FileOperation.EditingFile Then
				If AppUpdateOptions.ReadingAttributes.IsBeingEdited = Undefined Then
					NeedUpdate = False;
				Else
					NeedUpdate = Not AppUpdateOptions.ReadingAttributes.IsBeingEdited;
				EndIf;
			EndIf;
		Else
			// Perhaps the owner of the file is in the application tree, but the file itself is not.
			// For example, when a new file was added.
			NeedUpdate = UpdateAppByID(Parameter.FileOwner, AppUpdateOptions());
		EndIf;
		If NeedUpdate Then
			TreeType = IntegrationWith1CDocumentManagement3Client.TreeType();
			TreeType.ThisIsApplicationTree = True;
			StateOfApplicationTree = IntegrationWith1CDocumentManagement3Client.CurCurrentStateOfTree(
				TreeType,
				ApplicationTree.GetItems(),
				Items.ApplicationTree);
			If Parameter.FileOperation.CreatingFile Then
				NewFileLine = New Structure(
					"ApplicationPresentation, ApplicationID, ApplicationType, RowType, FileRoleID");
				NewFileLine.ApplicationPresentation = Parameter.FileName;
				NewFileLine.ApplicationID = Parameter.FileID;
				NewFileLine.ApplicationType = "DMFile";
				StateOfApplicationTree.KeyOfCurRowOfTree =
					IntegrationWith1CDocumentManagement3Client.TreeRowKey(TreeType, NewFileLine);
			EndIf;
			If Parameter.FormUniqueID = Undefined Then
				OutputIdleWindow = (Source = ThisObject);
			Else
				OutputIdleWindow = (UUID = Parameter.FormUniqueID);
			EndIf;
			UpdateForm(OutputIdleWindow, False, True);
		EndIf;
		
	ElsIf EventName = "DocumentManagement_AddingALink" Then
		If TypeOf(Parameter) <> Type("Structure")
				Or Not Parameter.Property("ID")
				Or Not Parameter.Property("Type")
				Or Not Parameter.Property("Object") Then
			Return;
		EndIf;
		AppUpdateOptions = AppUpdateOptions(Parameter.Type);
		AppUpdateOptions.AttributesForUpdate = New Structure("Ref, ApplicationPresentation",
			Parameter.Object,
			StrTemplate(NStr("vi = '%1, đối tượng %2';
							|ru = '%1, объект %2';
							|en = '%1, object %2'; fa = '%1, object %2';
							|it = '%1, объект %2';
							|pl = '%1, object %2';
							|tr = '%1, nesne %2'"), String(Parameter.Object), AbbreviatedNameOfConfiguration));
		UpdateAppByID(Parameter.ID, AppUpdateOptions, True);
		DisplayCreationCommandsBasedOn(New Array);
		
	ElsIf EventName = "DocumentManagement_DeletingALink" Then
		If TypeOf(Parameter) <> Type("Structure")
				Or Not Parameter.Property("ID")
				Or Not Parameter.Property("Type")
				Or Not UpdateAppByID(Parameter.ID, AppUpdateOptions(Parameter.Type), True) Then
			Return;
		EndIf;
		UpdateForm(False, False, True);
		
	ElsIf EventName = "Workflow_ActionWithProcessing" Then
		If TypeOf(Parameter) = Type("Structure")
				And Parameter.Property("DataProcessorData")
				And Parameter.DataProcessorData.SubjectOfID = MainSubjectID
				And Parameter.DataProcessorData.SubjectOfType = MainSubjectType Then
			If Parameter.Property("OperationType")
					And (Parameter.OperationType.Stop Or Parameter.OperationType.Abort) Then
				If IsOpen() Then
					Close();
				EndIf;
			Else
				UpdateForm(False, False, True);
			EndIf;
		EndIf;
		
	ElsIf EventName = "IntegrationWith1CWorkflow3_RuleWritten" Then
		UpdateForm(False, False, True);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AuthorizationSettingsDecorationClick(Item)
	
	Notification = New CallbackDescription("AuthorizationSettingsDecorationClickCompletion", ThisObject);
	NameOfParameterForm = "DataProcessor.IntegrationWith1CDocumentManagementCore.Form.AuthorizationIn1CDocumentManagement";
	
	OpenForm(NameOfParameterForm,, ThisObject,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AuthorizationSettingsDecorationClickCompletion(Result, Var_Parameters) Export
	
	If Result = True Then
		WhenConnecting();
	EndIf;
	
EndProcedure

&AtClient
Procedure HTMLDetailsOnClick(Item, EventData, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not ValueIsFilled(EventData.Href) Then
		Return;
	EndIf;
	
	If StrFind(EventData.Href, "OpenForEdit") Then
		
		IntegrationWith1CDocumentManagement3Client.ApplicationsTasksFilesEdit(
			ApplicationTreeCurrentData(),
			UUID);
		
	ElsIf StrFind(EventData.Href, "OpenForView") Or StrFind(EventData.Href, "OpenEDI") Then
		
		IntegrationWith1CDocumentManagement3Client.OpenTasksToViewApp(
			ApplicationTreeCurrentData(),
			UUID);
		
	ElsIf StrFind(EventData.Href, "CreatePreview") Then
		
		UpdatePreview1(True, True);
		
	ElsIf StrFind(EventData.Href, "v8doc:status") Then
		
		IntegrationWith1CDocumentManagement3Client.OpenWorkflowFormFromApplicationTree(
			"ProcessingPage",
			ApplicationTree,
			ApplicationTreeCurrentData(),
			UUID);
		
	ElsIf StrFind(EventData.Href, "ShowLinks") Then
		
		LineIsMainSubject = IntegrationWith1CDocumentManagement3Client.MainSubjectInApplicationTree(
			ApplicationTreeCurrentData(),
			ApplicationTree);
		If LineIsMainSubject <> Undefined Then
			ObjectBefore = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
				LineIsMainSubject.ApplicationID,
				LineIsMainSubject.ApplicationType,
				LineIsMainSubject.Application,,
				LineIsMainSubject.URL);
			IntegrationWith1CDocumentManagement3Client.ShowObjectConnections(ObjectBefore);
		EndIf;
		
	ElsIf IntegrationWith1CDocumentManagementCoreClient.IsURL(EventData.Href) Then
		
		IntegrationWith1CDocumentManagementCoreClient.OpenURL(EventData.Href);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ResultOfActionInTextTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	// We will save the text of the comment when the focus leaves.
	If IsBlankString(Text) And SavedComment = Undefined Then
		Return;
	EndIf;
	
	If SavedComment = Text Then
		// The comment hasn't changed.
		Return;
	EndIf;
	
	SavedComment = Text;
	ResultOfActionInText = Text;
	SavingCommentIsDone = False;
	
	AttachIdleHandler("SaveActionResult", 0.2, True);
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("ID", ID);
	NotificationParameters.Insert("Type", Type);
	NotificationParameters.Insert("Text", Text);
	NotificationParameters.Insert("DataVersionOfTaskAction", DataVersionOfTaskAction);
	Notify("ChangedResultOfTextAction", NotificationParameters, ThisObject);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersApplicationTree

&AtClient
Procedure ApplicationTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	IntegrationWith1CDocumentManagement3Client.OpenTasksToViewApp(
		ApplicationTreeCurrentData(),
		UUID);
	
EndProcedure

&AtClient
Procedure ApplicationTreeOnActivateRow(Item)
	
	If Item.CurrentRow = Undefined Then
		Return;
	EndIf;
	
	NewKey = StrTemplate("%1_%2", ID, Item.CurrentRow);
	If NewKey = ApplicationTreeRowKey Then
		Return;
	EndIf;
	ApplicationTreeRowKey = NewKey;
	
	IntegrationWith1CDocumentManagement3Client.SetAvailabilityOfCommandsOfTaskApplications(
		Item.CurrentRow,
		ThisObject,
		ThisIsThinWindowsClient);
	
	PresentationHTML = IntegrationWith1CDocumentManagementCoreClientServer.DownloadMessage();
	Items.ViewPages.CurrentPage = Items.HTMLGroupPage;
	Items.GroupPreviewCut.Visible = False;
	AttachIdleHandler("UpdatePreviewWhenLineIsActivated", 0.2, True);
	
EndProcedure

&AtClient
Procedure ApplicationTreeBeforeRowChange(Item, Cancel)
	
	IntegrationWith1CDocumentManagement3Client.ApplicationTreeTasksBeforeStartOfChange(
		ApplicationTreeCurrentData(),
		Cancel);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure PDFDocumentEnlarge(Command)
	
	Items["DocumentPDFField"].Scale = Items["DocumentPDFField"].Scale + 10;
	
EndProcedure

&AtClient
Procedure PDFDocumentReduce(Command)
	
	If Items["DocumentPDFField"].Scale <= 10 Then
		Return;
	EndIf;
	
	Items["DocumentPDFField"].Scale = Items["DocumentPDFField"].Scale - 10;
	
EndProcedure

&AtClient
Procedure PDFDocumentLeftTurn(Command)
	
	Items["DocumentPDFField"].Orientation = Items["DocumentPDFField"].Orientation - 90;
	
EndProcedure

&AtClient
Procedure PDFDocumentTurnRight(Command)
	
	Items["DocumentPDFField"].Orientation = Items["DocumentPDFField"].Orientation + 90;
	
EndProcedure

&AtClient
Procedure PerformTaskActionOption1(Command)
	
	OperationType = IntegrationWith1CDocumentManagementCoreClientServer.TypeOfOperationOnTask();
	OperationType.PerformTaskAction = True;
	TaskActionParameters = TaskActionParameters();
	TaskActionParameters.OperationParametersList = New Structure("ResultOfOptionNumber", "ResultOfOption1");
	TaskActionParameters.DataUpdateRequired = False;
	ActionOnTask(OperationType, TaskActionParameters);
	
EndProcedure

&AtClient
Procedure PerformTaskActionOption2(Command)
	
	OperationType = IntegrationWith1CDocumentManagementCoreClientServer.TypeOfOperationOnTask();
	OperationType.PerformTaskAction = True;
	TaskActionParameters = TaskActionParameters();
	TaskActionParameters.OperationParametersList = New Structure("ResultOfOptionNumber", "ResultOfOption2");
	TaskActionParameters.DataUpdateRequired = False;
	ActionOnTask(OperationType, TaskActionParameters);
	
EndProcedure

&AtClient
Procedure PerformTaskActionOption3(Command)
	
	OperationType = IntegrationWith1CDocumentManagementCoreClientServer.TypeOfOperationOnTask();
	OperationType.PerformTaskAction = True;
	TaskActionParameters = TaskActionParameters();
	TaskActionParameters.OperationParametersList = New Structure("ResultOfOptionNumber", "ResultOfOption3");
	TaskActionParameters.DataUpdateRequired = False;
	ActionOnTask(OperationType, TaskActionParameters);
	
EndProcedure

&AtClient
Procedure PerformTemplateTaskAction1(Command)
	
	OperationType = IntegrationWith1CDocumentManagementCoreClientServer.TypeOfOperationOnTask();
	OperationType.PerformTemplateTaskAction = True;
	TaskActionParameters = TaskActionParameters();
	TaskActionParameters.OperationParametersList = New Structure("ResultOfOptionNumber", "ResultOfOption1");
	ActionOnTask(OperationType, TaskActionParameters);
	
EndProcedure

&AtClient
Procedure PerformTemplateTaskAction2(Command)
	
	OperationType = IntegrationWith1CDocumentManagementCoreClientServer.TypeOfOperationOnTask();
	OperationType.PerformTemplateTaskAction = True;
	TaskActionParameters = TaskActionParameters();
	TaskActionParameters.OperationParametersList = New Structure("ResultOfOptionNumber", "ResultOfOption2");
	ActionOnTask(OperationType, TaskActionParameters);
	
EndProcedure

&AtClient
Procedure PerformTemplateTaskAction3(Command)
	
	OperationType = IntegrationWith1CDocumentManagementCoreClientServer.TypeOfOperationOnTask();
	OperationType.PerformTemplateTaskAction = True;
	TaskActionParameters = TaskActionParameters();
	TaskActionParameters.OperationParametersList = New Structure("ResultOfOptionNumber", "ResultOfOption1");
	ActionOnTask(OperationType, TaskActionParameters);
	
EndProcedure

&AtClient
Procedure SelectTemplateForTask(Command)
	
	OperationType = IntegrationWith1CDocumentManagementCoreClientServer.TypeOfOperationOnTask();
	OperationType.SelectTemplateForTask = True;
	ActionOnTask(OperationType);
	
EndProcedure

&AtClient
Procedure PerformConnectedTaskAction1(Command)
	
	OperationType = IntegrationWith1CDocumentManagementCoreClientServer.TypeOfOperationOnTask();
	OperationType.PerformConnectedTaskAction = True;
	ActionOnTask(OperationType);
	
EndProcedure

&AtClient
Procedure CancelExecution(Command)
	
	OperationType = IntegrationWith1CDocumentManagementCoreClientServer.TypeOfOperationOnTask();
	OperationType.CancelExecution = True;
	ActionOnTask(OperationType);
	
EndProcedure

&AtClient
Procedure UpdatePreviewCommand(Command)
	
	UpdatePreview1(True);
	
EndProcedure

&AtClient
Procedure OpenApp(Command)
	
	IntegrationWith1CDocumentManagement3Client.OpenTasksToViewApp(
		ApplicationTreeCurrentData(),
		UUID);
	
EndProcedure

&AtClient
Procedure OpenCard(Command)
	
	IntegrationWith1CDocumentManagement3Client.OpenTaskApplicationCard(ApplicationTreeCurrentData());
	
EndProcedure

&AtClient
Procedure FilesInsertImageFromBuffer(Command)
	
	IntegrationWith1CDocumentManagement3Client.ApplicationsTasksFilesInsertPictureFromBuffer(
		ApplicationTreeCurrentData(),
		UUID);
	
EndProcedure

&AtClient
Procedure FilesAdd(Command)
	
	IntegrationWith1CDocumentManagement3Client.ApplicationsTasksFilesAdd(
		ApplicationTreeCurrentData(),
		UUID);
	
EndProcedure

&AtClient
Procedure EditFiles(Command)
	
	IntegrationWith1CDocumentManagement3Client.ApplicationsTasksFilesEdit(
		ApplicationTreeCurrentData(),
		UUID);
	
EndProcedure

&AtClient
Procedure FilesFinishEditing(Command)
	
	IntegrationWith1CDocumentManagement3Client.ApplicationsTasksFilesFinishEditing(
		ApplicationTreeCurrentData(),
		UUID);
	
EndProcedure

&AtClient
Procedure ReleaseFiles(Command)
	
	IntegrationWith1CDocumentManagement3Client.ApplicationsTasksFilesToRelease(
		ApplicationTreeCurrentData(),
		UUID);
	
EndProcedure

&AtClient
Procedure UpdateFilesFromFileOnDisk(Command)
	
	IntegrationWith1CDocumentManagement3Client.ApplicationsTasksFilesToUpdateFromFileOnDisk(
		ApplicationTreeCurrentData(),
		UUID);
	
EndProcedure

&AtClient
Procedure FilesDelete(Command)
	
	IntegrationWith1CDocumentManagement3Client.ApplicationsTasksFilesToDelete(
		ApplicationTreeCurrentData(),
		UUID);
	
EndProcedure

&AtClient
Procedure SaveFilesAs(Command)
	
	IntegrationWith1CDocumentManagement3Client.ApplicationsTasksFilesSaveAs(
		ApplicationTreeCurrentData(),
		ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_CreateLinkedObject(Command)
	
	IntegrationWith1CDocumentManagement3Client.Attachable_CreateLinkedObject(
		Command,
		MainSubjectID,
		MainSubjectType,
		UUID);
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	UpdateForm(True, False, True);
	
EndProcedure

&AtClient
Procedure TakeToWork(Command)
	
	OperationType = IntegrationWith1CDocumentManagementCoreClientServer.TypeOfOperationOnTask();
	OperationType.TakeToWork = True;
	ActionOnTask(OperationType);
	
EndProcedure

&AtClient
Procedure CancelTakingToWork(Command)
	
	OperationType = IntegrationWith1CDocumentManagementCoreClientServer.TypeOfOperationOnTask();
	OperationType.CancelTakingToWork = True;
	ActionOnTask(OperationType);
	
EndProcedure

&AtClient
Procedure SetYellowFlag(Command)
	
	OperationType = IntegrationWith1CDocumentManagementCoreClientServer.TypeOfOperationOnTask();
	OperationType.SetFlag = True;
	TaskActionParameters = TaskActionParameters();
	TaskActionParameters.OperationParametersList = New Structure("Flag", "Yellow");
	ActionOnTask(OperationType, TaskActionParameters);
	
EndProcedure

&AtClient
Procedure SetGreenFlag(Command)
	
	OperationType = IntegrationWith1CDocumentManagementCoreClientServer.TypeOfOperationOnTask();
	OperationType.SetFlag = True;
	TaskActionParameters = TaskActionParameters();
	TaskActionParameters.OperationParametersList = New Structure("Flag", "Green");
	ActionOnTask(OperationType, TaskActionParameters);
	
EndProcedure

&AtClient
Procedure SetRedFlag(Command)
	
	OperationType = IntegrationWith1CDocumentManagementCoreClientServer.TypeOfOperationOnTask();
	OperationType.SetFlag = True;
	TaskActionParameters = TaskActionParameters();
	TaskActionParameters.OperationParametersList = New Structure("Flag", "Red");
	ActionOnTask(OperationType, TaskActionParameters);
	
EndProcedure

&AtClient
Procedure SetPurpleFlag(Command)
	
	OperationType = IntegrationWith1CDocumentManagementCoreClientServer.TypeOfOperationOnTask();
	OperationType.SetFlag = True;
	TaskActionParameters = TaskActionParameters();
	TaskActionParameters.OperationParametersList = New Structure("Flag", "Purple");
	ActionOnTask(OperationType, TaskActionParameters);
	
EndProcedure

&AtClient
Procedure SetOrangeFlag(Command)
	
	OperationType = IntegrationWith1CDocumentManagementCoreClientServer.TypeOfOperationOnTask();
	OperationType.SetFlag = True;
	TaskActionParameters = TaskActionParameters();
	TaskActionParameters.OperationParametersList = New Structure("Flag", "Orange");
	ActionOnTask(OperationType, TaskActionParameters);
	
EndProcedure

&AtClient
Procedure SetBlueFlag(Command)
	
	OperationType = IntegrationWith1CDocumentManagementCoreClientServer.TypeOfOperationOnTask();
	OperationType.SetFlag = True;
	TaskActionParameters = TaskActionParameters();
	TaskActionParameters.OperationParametersList = New Structure("Flag", "Blue");
	ActionOnTask(OperationType, TaskActionParameters);
	
EndProcedure

&AtClient
Procedure ClearFlag(Command)
	
	OperationType = IntegrationWith1CDocumentManagementCoreClientServer.TypeOfOperationOnTask();
	OperationType.SetFlag = True;
	TaskActionParameters = TaskActionParameters();
	TaskActionParameters.OperationParametersList = New Structure("Flag", "");
	ActionOnTask(OperationType, TaskActionParameters);
	
EndProcedure

&AtClient
Procedure Forward(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("Task", Title);
	FormParameters.Insert("TaskID", ID);
	FormParameters.Insert("TaskType", Type);
	FormParameters.Insert("UseIntegrationBefore3", True);
	OpenForm(
		"DataProcessor.IntegrationWith1CDocumentManagementCore.Form.TaskRedirecting",
		FormParameters);
	
EndProcedure

&AtClient
Procedure AddParticipants(Command)
	
	FormParameters = New Structure("MainSubjectID, MainSubjectType", MainSubjectID, MainSubjectType);
	IntegrationWith1CDocumentManagementCoreClient.OpenObject(
		ProcessingActionType,
		ProcessingActionID,
		ThisObject,
		FormParameters);
	
EndProcedure

#EndRegion

#Region Private

#Region Client

&AtClient
Function ApplicationTreeCurrentData()
	
	ApplicationTreeCurrentData = Items.ApplicationTree.CurrentData;
	If ApplicationTreeCurrentData = Undefined Then
		ApplicationTreeItems = ApplicationTree.GetItems();
		If ApplicationTreeItems.Count() > 0 Then
			ApplicationTreeCurrentData = ApplicationTreeItems[0];
		EndIf;
	EndIf;
	
	Return ApplicationTreeCurrentData;
	
EndFunction

&AtClient
Function NeedToUpdatePreview(ApplicationTreeLine, UpdateData1, ReturnBinaryData, ThereIsPreviewFile)
	
	If ApplicationTreeLine.RowType = "task" Then
		Return UpdateData1;
	ElsIf ApplicationTreeLine.ApplicationType = "DMFile"
			Or IntegrationWith1CDocumentManagement3ClientCached.ThisIsWellKnownObjectOfReview(ApplicationTreeLine.ApplicationType) Then
		Return UpdateData1
			Or (ReturnBinaryData And Not ThereIsPreviewFile)
			Or (Not ValueIsFilled(ApplicationTreeLine.PresentationHTML) And Not ThereIsPreviewFile);
	EndIf;
	
	Return False;
	
EndFunction

&AtClient
Procedure UpdatePreview1(UpdateData1 = False, IgnoreMaxSize = False)
	
	PresentationHTML = IntegrationWith1CDocumentManagementCoreClientServer.DownloadMessage();
	Items.ViewPages.CurrentPage = Items.HTMLGroupPage;
	Items.GroupPreviewCut.Visible = False;
	
	CurrentData = ApplicationTreeCurrentData();
	If CurrentData = Undefined Then
		PresentationHTML = IntegrationWith1CDocumentManagementCoreClientServer.MessageAboutAbsenceOfPreview(
			TitleOfMessageInPreviewArea);
		Return;
	EndIf;
	If CurrentData.WaitingForPreview Then
		Return;
	EndIf;
	
	// The receipt of the document's NDPS is combined with the receipt of a preview for optimization.
	// We will get the NDPS in one batch request together with the preview, for one service call BEFORE.
	// In advance, when receiving the task list, it is impossible to get the NDPS of all items, because this
	// will significantly slow down the updating of the list.
	ObjectForGettingPersonalData = Undefined;
	DocumentLine = IntegrationWith1CDocumentManagement3ClientServer.DocumentLineInApplicationTree(CurrentData);
	If DocumentLine <> Undefined Then
		ObjectForGettingPersonalData =
			IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
				DocumentLine.ApplicationID,
				DocumentLine.ApplicationType);
	EndIf;
	
	ReturnBinaryData = ShowPDFUsing1C
		And (Lower(CurrentData.Extension) = "pdf")
		And Not CurrentData.Encrypted;
	ThereIsPreviewFile = IsTempStorageURL(CurrentData.AddressInPreviewFileStorage)
		And Not CurrentData.Encrypted;
	
	If NeedToUpdatePreview(CurrentData, UpdateData1, ReturnBinaryData, ThereIsPreviewFile) Then
		
		CurrentData.WaitingForPreview = True;
		TimeConsumingOperation = IntegrationWith1CDocumentManagement3ServerCall.GetHTMLPreviewOfObjectAsynchronously(
			UUID,
			CurrentData.ApplicationID,
			CurrentData.ApplicationType,
			IgnoreMaxSize,
			ObjectForGettingPersonalData,
			ReturnBinaryData);
		
		CallbackOnCompletion = New CallbackDescription(
			"UpdatePreview1Completion",
			ThisObject,
			CurrentData);
		
		IntegrationWith1CDocumentManagementCoreClient.ExecuteRequestAsynchronously(
			ThisObject,
			TimeConsumingOperation,
			CallbackOnCompletion,
			False,,
			False);
		
		Return;
		
	EndIf;
	
	If Not CurrentData.EditedByCurUser And CurrentData.PreviewCut Then
		Items.GroupPreviewCut.Visible = True;
	EndIf;
	
	If ValueIsFilled(CurrentData.PresentationHTML) Then
		PresentationHTML = CurrentData.PresentationHTML;
	ElsIf ThereIsPreviewFile Then
		If CurrentData.EditedByCurUser Then
			PresentationHTML = IntegrationWith1CDocumentManagementCoreClientServer.MessageAboutEditing(
				TitleOfMessageInPreviewArea);
		Else
			PDFDocument = IntegrationWith1CDocumentManagementCoreServerCall.GetPDFDocument(
				CurrentData.AddressInPreviewFileStorage);
			If PDFDocument = Undefined Then
				PresentationHTML = IntegrationWith1CDocumentManagementCoreClientServer.MessageAboutAbsenceOfPreview(
					TitleOfMessageInPreviewArea);
			Else
				ThisObject["PDFDocumentAttributes"] = PDFDocument;
				Items.ViewPages.CurrentPage = Items.PageGroupPDF;
				Items["DocumentPDFField"].CurrentPageNumber = 1;
			EndIf;
		EndIf;
	ElsIf CurrentData.RowType = "task" Then
		PresentationHTML = HTMLTaskDescription;
	Else
		PresentationHTML = IntegrationWith1CDocumentManagementCoreClientServer.MessageAboutAbsenceOfPreview(
			TitleOfMessageInPreviewArea);
	EndIf;
	
EndProcedure

// Called after getting a preview of the object BEFORE.
//
// Parameters:
//   Result - See TimeConsumingOperations.ActionCompleted
//   NotificationParameters - See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//
&AtClient
Procedure UpdatePreview1Completion(Result, NotificationParameters) Export
	
	HTMLObjectPreview =
		IntegrationWith1CDocumentManagementCoreClientServer.NotificationParametersReceivedHTMLObjectPreview();
	
	If Result <> Undefined And Result.Status = "Error" Then
		HTMLMessage =
			IntegrationWith1CDocumentManagementCoreClientServer.PreviewMessage(
				Result.BriefErrorDescription,
				TitleOfMessageInPreviewArea);
		HTMLObjectPreview.ID = NotificationParameters.ApplicationID;
		HTMLObjectPreview.Type = NotificationParameters.ApplicationType;
		HTMLObjectPreview.Extension = NotificationParameters.Extension;
		HTMLObjectPreview.PresentationHTML = HTMLMessage;
		Notify("HTMLObjectPreviewReceived", HTMLObjectPreview, ThisObject);
	EndIf;
	
	ProcessAForm = False;
	If IntegrationWith1CDocumentManagementCoreClient.ActionCompleted(Result, ProcessAForm) Then
		IntegrationWith1CDocumentManagementCoreClientServer.AddPersonalData(HTMLObjectPreview);
		FillPropertyValues(HTMLObjectPreview, Result.ResultLongOperation);
		HTMLObjectPreview.ID = NotificationParameters.ApplicationID;
		HTMLObjectPreview.Type = NotificationParameters.ApplicationType;
		HTMLObjectPreview.Extension = NotificationParameters.Extension;
		If IsBlankString(HTMLObjectPreview.PresentationHTML) Then
			HTMLObjectPreview.PresentationHTML =
				IntegrationWith1CDocumentManagementCoreClientServer.MessageAboutAbsenceOfPreview(
					TitleOfMessageInPreviewArea);
		EndIf;
		Notify("HTMLObjectPreviewReceived", HTMLObjectPreview, ThisObject);
	ElsIf ProcessAForm Then
		ProcessFormAccordingToServiceVersion();
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdatePreviewWhenLineIsActivated()
	
	UpdatePreview1();
	
	// Save the Cur State of the application tree.
	TreeType = IntegrationWith1CDocumentManagement3Client.TreeType();
	TreeType.ThisIsApplicationTree = True;
	StateOfApplicationTree = IntegrationWith1CDocumentManagement3Client.CurCurrentStateOfTree(
		TreeType,
		ApplicationTree.GetItems(),
		Items.ApplicationTree);
	
EndProcedure

&AtClient
Function UpdateAppByID(Val ApplicationID, AppUpdateOptions, OnlyBasicSubjects = False)
	
	UpdateComplete = False;
	
	FoundRows = AllApplicationsInValueTree(
		ApplicationTree.GetItems(),
		ApplicationID,
		AppUpdateOptions.ApplicationType,
		OnlyBasicSubjects);
	
	For Each FoundRow In FoundRows Do
		
		If AppUpdateOptions.AttributesForUpdate <> Undefined Then
			DocumentLine = IntegrationWith1CDocumentManagement3ClientServer.DocumentLineInApplicationTree(FoundRow);
			If DocumentLine <> Undefined Then
				IntegrationWith1CDocumentManagementCoreClientServer.FillInNDPOfPpeStructure(
					DocumentLine,
					AppUpdateOptions.ASBS);
			EndIf;
			
			FillPropertyValues(FoundRow, AppUpdateOptions.AttributesForUpdate);
			
			UpdateTreeInRepository(ApplicationID, AppUpdateOptions);
		EndIf;
		
		If AppUpdateOptions.ReadingAttributes <> Undefined Then
			FillPropertyValues(AppUpdateOptions.ReadingAttributes, FoundRow);
		EndIf;
		
		UpdateComplete = True;
		
	EndDo;
	
	Return UpdateComplete;
	
EndFunction

// Handler for the "GETTHTML Object view" event.
//
// Parameters:
//   Parameter - See IntegrationWith1CDocumentManagementCoreClientServer.NotificationParametersReceivedHTMLObjectPreview
//   Source - Arbitrary - event source.
//
&AtClient
Procedure ProcessHTMLPreviewReceiptEvent(Parameter, Source)
	
	ParametersOfUpdate = AppUpdateOptions(Parameter.Type);
	ParametersOfUpdate.AttributesForUpdate =
		New Structure("WaitingForPreview, PresentationHTML, PreviewCut", False, "", False);
	If TypeOf(Parameter.BinaryData) = Type("BinaryData") And Lower(Parameter.Extension) = "pdf" Then
		AddressInPreviewFileStorage = PutToTempStorage(
			Parameter.BinaryData,
			UUID);
		ParametersOfUpdate.AttributesForUpdate.Insert(
			"AddressInPreviewFileStorage", AddressInPreviewFileStorage);
	Else
		ParametersOfUpdate.AttributesForUpdate.PresentationHTML = Parameter.PresentationHTML;
		ParametersOfUpdate.AttributesForUpdate.PreviewCut = Parameter.PreviewCut;
	EndIf;
	IntegrationWith1CDocumentManagementCoreClientServer.FillInNDPOfPpeStructure(
		ParametersOfUpdate.ASBS,
		Parameter);
	UpdateComplete = UpdateAppByID(Parameter.ID, ParametersOfUpdate);
	If UpdateComplete Then
		UpdatePreview1();
		IntegrationWith1CDocumentManagement3Client.SetAvailabilityOfCommandsOfTaskApplications(
			Items.ApplicationTree.CurrentRow,
			ThisObject,
			ThisIsThinWindowsClient);
	EndIf;
	
EndProcedure

&AtClient
Procedure SaveActionResult()
	
	If Items.ResultOfActionInText.ReadOnly Or SavingCommentIsDone = True Then
		Return;
	EndIf;
	
	NewVersionOfTheData = IntegrationWith1CDocumentManagement3ServerCall.SaveActionResult(
		ResultOfActionInText,
		ID,
		DataVersionOfTaskAction,
		AdditionalDataAddress);
	If ValueIsFilled(NewVersionOfTheData) And DataVersionOfTaskAction <> NewVersionOfTheData Then
		DataVersionOfTaskAction = NewVersionOfTheData;
		NotificationParameters = New Structure;
		NotificationParameters.Insert("ID", ID);
		NotificationParameters.Insert("Type", Type);
		NotificationParameters.Insert("Text", ResultOfActionInText);
		NotificationParameters.Insert("DataVersionOfTaskAction", DataVersionOfTaskAction);
		Notify("ChangedResultOfTextAction", NotificationParameters, ThisObject);
	EndIf;
	
	SavingCommentIsDone = True;
	
EndProcedure

#EndRegion

#Region ClientServer

&AtClientAtServerNoContext
Function AllApplicationsInValueTree(Rows, ApplicationID, ApplicationType, OnlyBasicSubjects = False)
	
	Result = New Array;
	
	For Each String In Rows Do
		
		If OnlyBasicSubjects And String.RowType <> "application" Then
			Continue;
		EndIf;
		
		If String.ApplicationID = ApplicationID And String.ApplicationType = ApplicationType Then
			Result.Add(String);
		ElsIf String.ApplicationID = ApplicationID And ApplicationType = Undefined Then
			Result.Add(String);
		EndIf;
		
		If TypeOf(String) = Type("FormDataTreeItem") Then
			SubordinateRows = String.GetItems();
		Else
			SubordinateRows = String.Rows;
		EndIf;
		SubordinateApplications = AllApplicationsInValueTree(
			SubordinateRows,
			ApplicationID,
			ApplicationType,
			OnlyBasicSubjects);
		For Each FoundRow In SubordinateApplications Do
			Result.Add(FoundRow);
		EndDo;
		
	EndDo;
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function TaskActionParameters()
	
	TaskActionParameters = New Structure;
	TaskActionParameters.Insert("OperationParametersList", Undefined);
	TaskActionParameters.Insert("DataUpdateRequired", True);
	TaskActionParameters.Insert("RequiredInteractiveAction",
		IntegrationWith1CDocumentManagement3ClientServer.RequiredInteractiveAction());
	
	Return TaskActionParameters;
	
EndFunction

#EndRegion

#Region Server

&AtServer
Procedure UpdateTreeInRepository(ApplicationID, AppUpdateOptions)
	
	If IsBlankString(AdditionalDataAddress)
			Or AppUpdateOptions.AttributesForUpdate = Undefined Then
		Return;
	EndIf;
	
	AdditionalInformationOnIssue = GetFromTempStorage(AdditionalDataAddress);
	If AdditionalInformationOnIssue <> Undefined Then
		FoundRows = AllApplicationsInValueTree(
			AdditionalInformationOnIssue.ApplicationTree.Rows,
			ApplicationID,
			AppUpdateOptions.ApplicationType);
		
		For Each FoundRow In FoundRows Do
			
			DocumentLine = IntegrationWith1CDocumentManagement3ClientServer.DocumentLineInApplicationTree(FoundRow);
			If DocumentLine <> Undefined Then
				IntegrationWith1CDocumentManagementCoreClientServer.FillInNDPOfPpeStructure(
					DocumentLine,
					AppUpdateOptions.ASBS);
			EndIf;
			
			FillPropertyValues(FoundRow, AppUpdateOptions.AttributesForUpdate);
			
		EndDo;
		
		PutToTempStorage(AdditionalInformationOnIssue, AdditionalDataAddress);
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateWidthOfFormElements()
	
	GroupCommandPanelWidth = 17;
	ShiftTakeToWork = 14;
	ShiftRedirect = 4;
	
	If Not Items.TakeToWork.Visible Then
		GroupCommandPanelWidth = GroupCommandPanelWidth - ShiftTakeToWork;
	EndIf;
	If Not Items.Forward.Visible Then
		GroupCommandPanelWidth = GroupCommandPanelWidth - ShiftRedirect;
	EndIf;
	Items.GroupCommandBar.Width = GroupCommandPanelWidth;
	
EndProcedure

&AtServer
Procedure ProcessResponseOfWebServiceToReceiptOfTask(XDTOTask)
	
	DataProcessors.IntegrationWith1CDocumentManagementCore.SetNavigationLink(ThisObject, XDTOTask);
	
	Title = XDTOTask.title;
	HTMLTaskDescription = XDTOTask.htmlView;
	
	If Not ValueIsFilled(MainSubjectID) And Not ValueIsFilled(MainSubjectType) Then
		MainSubject = IntegrationWith1CDocumentManagement3.MainSubjectOfTask(XDTOTask);
		MainSubjectID = MainSubject.ID;
		MainSubjectType = MainSubject.Type;
	EndIf;
	
	AdditionalInformationOnIssue = IntegrationWith1CDocumentManagement3.AdditionalInformationOnIssue(XDTOTask);
	If Not IsBlankString(AdditionalDataAddress) Then
		PutToTempStorage(AdditionalInformationOnIssue, AdditionalDataAddress);
	EndIf;
	
	DisplayAdditionalData(AdditionalInformationOnIssue);
	
	ThereIsAlreadyConnection = False;
	If AdditionalInformationOnIssue <> Undefined Then
		For Each ApplicationTreeLine In AdditionalInformationOnIssue.ApplicationTree.Rows Do
			If ValueIsFilled(ApplicationTreeLine.Ref) Then
				ThereIsAlreadyConnection = True;
				Break;
			EndIf;
		EndDo;
	EndIf;
	If Not ThereIsAlreadyConnection Then
		// To build a list of creation commands based on an array of integration rules suitable for the task,
		// we also fill in the data ID and type of the main subject of the task.
		SuitableObjects = IntegrationWith1CDocumentManagement3.SuitableObjectsToCreateBasedOnTask(
			XDTOTask,
			AdditionalInformationOnIssue.ApplicationTree.Rows,
			MainSubjectID,
			MainSubjectType);
		DisplayCreationCommandsBasedOn(SuitableObjects);
	EndIf;
	
EndProcedure

&AtServer
Procedure DisplayAdditionalData(AdditionalInformationOnIssue)
	
	If AdditionalInformationOnIssue = Undefined Then
		Items.ThereAreOneTaskPagesAndSeveralPagesThatAreMissing.CurrentPage = Items.ErrorPage;
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagement3.UpdateTaskScope(
		ThisObject,
		AdditionalInformationOnIssue.Scope,
		SavedComment,
		False);
	
	UpdateWidthOfFormElements();
	
	ValueToFormAttribute(AdditionalInformationOnIssue.ApplicationTree, "ApplicationTree");
	
EndProcedure

&AtServer
Procedure DisplayCreationCommandsBasedOn(SuitableObjects)
	
	KeyOfCreationCommandsPageBasedOn = "";
	If SuitableObjects.Count() > 0 Then
		// Each unique combination of rules corresponds to its own group of creation commands based on.
		// For optimization, if the appropriate rules match when redrawing the form, we will not create
		// a new group of commands on the form, but will use the previously created group.
		// The matching of the name of the page to a certain combination of suitable rules is stored in temporary
		// storage at the address of the pagecommandation.
		MatchingPages = GetFromTempStorage(PagesOfCreationCommandsBasedOn);
		PageMatchingKey = ValueToStringInternal(SuitableObjects);
		KeyOfCreationCommandsPageBasedOn = MatchingPages[PageMatchingKey];
		If Not ValueIsFilled(KeyOfCreationCommandsPageBasedOn) Then
			KeyOfCreationCommandsPageBasedOn =
				IntegrationWith1CDocumentManagement3.NewPageOfCommandsToCreateBasedOnTask(
					ThisObject,
					SuitableObjects);
			MatchingPages[PageMatchingKey] = KeyOfCreationCommandsPageBasedOn;
			PutToTempStorage(MatchingPages, PagesOfCreationCommandsBasedOn);
		EndIf;
	EndIf;
	
	NewPage = Items["GroupTeamPage" + KeyOfCreationCommandsPageBasedOn];
	If Items.TeamPageGroup.CurrentPage <> NewPage Then
		Items.TeamPageGroup.CurrentPage = NewPage;
		Items.TeamPageGroup.Visible =
			(NewPage.ChildItems[0].ChildItems[0].ChildItems.Count() > 0);
	EndIf;
	
EndProcedure

&AtServer
Function AppUpdateOptions(Val ApplicationType = Undefined)
	
	ParametersOfUpdate = New Structure;
	ParametersOfUpdate.Insert("ApplicationType", ApplicationType);
	ParametersOfUpdate.Insert("AttributesForUpdate", Undefined);
	ParametersOfUpdate.Insert("ReadingAttributes", Undefined);
	
	ASBS = New Structure;
	IntegrationWith1CDocumentManagementCoreClientServer.AddPersonalData(ASBS);
	ParametersOfUpdate.Insert("ASBS", ASBS);
	
	Return ParametersOfUpdate;
	
EndFunction

#EndRegion

#Region Connection

// Checks the connection to the DO by displaying the authorization window, if necessary, and changing the form according to the result.
//
&AtClient
Procedure TestConnection()
	
	CallbackDescription = New CallbackDescription("TestConnectionCompletion", ThisObject);
	IntegrationWith1CDocumentManagementCoreClient.TestConnection(
		CallbackDescription,
		ThisObject,,
		False,
		True);
	
EndProcedure

&AtClient
Procedure TestConnectionCompletion(Result, Var_Parameters) Export
	
	If Result = True Then
		WhenConnecting();
	Else // Couldn't connect to BEFORE.
		ProcessFormAccordingToServiceVersion();
	EndIf;
	
EndProcedure

&AtClient
Procedure WhenConnecting()
	
	If ProcessFormAccordingToServiceVersion() Then
		UpdateForm();
	EndIf;
	
EndProcedure

&AtServer
Function ProcessFormAccordingToServiceVersion()
	
	ServiceVersion = IntegrationWith1CDocumentManagementCore.ServiceVersion();
	
	If Not IntegrationWith1CDocumentManagementCoreClientServer.ServiceIsAvailable(ServiceVersion) Then
		Items.ConnectionPageGroup.CurrentPage = Items.Page1CDocumentManagementIsUnavailable;
		Return False;
	EndIf;
	
	FormProcessedSuccessfully = True;
	
	Try
		
		If IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("3.0.10.20") Then
			
			Items.ConnectionPageGroup.CurrentPage = Items.Page1CDocumentManagementIsAvailable;
			
			SettingsOf1CDocumentManagement = IntegrationWith1CDocumentManagementCoreCached.GetSettings();
			TitleOfMessageInPreviewArea = SettingsOf1CDocumentManagement.TitleOfMessageInPreviewArea;
			AddWorkToDailyReportWhenCompletingTask =
				SettingsOf1CDocumentManagement.AddWorkToDailyReportWhenCompletingTask;
			ActualTaskExecutor = SettingsOf1CDocumentManagement.ActualTaskExecutor;
			If ActualTaskExecutor <> "taskPerformer" Then
				CurCurrentUserAndEmployees =
					IntegrationWith1CDocumentManagementCoreCached.Current1CDocumentManagementUser();
				IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
					ThisObject, CurCurrentUserAndEmployees[0], "CurrentUser");
			EndIf;
			
			ShowPDFUsing1C = SettingsOf1CDocumentManagement.ShowPDFUsing1C;
			If ShowPDFUsing1C Then
				IntegrationWith1CDocumentManagement3.OutputPDFDocumentToForm(ThisObject, "PDFGroup");
			EndIf;
			
			Items.Forward.Visible = SettingsOf1CDocumentManagement.UseTaskRedirection;
			
			UpdateWidthOfFormElements();
			
		Else
			
			Items.ConnectionPageGroup.CurrentPage = Items.VersionPageIsNotSupported;
			FormProcessedSuccessfully = False;
			
		EndIf;
		
	Except
		
		If IntegrationWith1CDocumentManagementCoreServerCall.NeedToProcessForm(ErrorInfo()) Then
			ProcessFormAccordingToServiceVersion();
		EndIf;
		
	EndTry;
	
	Return FormProcessedSuccessfully;
	
EndFunction

#EndRegion

#Region UpdateForm

&AtClient
Procedure UpdateForm(OutputIdleWindow = False, HideInterface = True, UpdateData1 = False)
	
	If UpdateData1 = False And ApplicationTree.GetItems().Count() > 0 Then
		Return;
	EndIf;
	
	If Not OutputIdleWindow And Not HideInterface Then
		Items.Page1CDocumentManagementIsAvailable.Enabled = False;
	EndIf;
	
	TimeConsumingOperation = IntegrationWith1CDocumentManagementCoreServerCall.GetObjectAsynchronously(
		UUID,
		Type,
		ID,
		"htmlView");
	NotificationParameters = New Structure("OutputIdleWindow, HideInterface",
		OutputIdleWindow,
		HideInterface);
	CallbackOnCompletion = New CallbackDescription("UpdateFormCompletion", ThisObject, NotificationParameters);
	IntegrationWith1CDocumentManagementCoreClient.ExecuteRequestAsynchronously(
		ThisObject,
		TimeConsumingOperation,
		CallbackOnCompletion,
		OutputIdleWindow,,
		HideInterface);
	
EndProcedure

&AtClient
Procedure UpdateFormCompletion(Result, NotificationParameters) Export
	
	If Not NotificationParameters.OutputIdleWindow And Not NotificationParameters.HideInterface Then
		Items.Page1CDocumentManagementIsAvailable.Enabled = True;
	EndIf;
	
	ProcessAForm = False;
	IntegrationWith1CDocumentManagementCoreClient.CheckForErrorsWhenUpdatingForm(
		ThisObject,
		Result,
		ProcessAForm);
	If ProcessAForm Then
		ProcessFormAccordingToServiceVersion();
	EndIf;
	
	If IntegrationWith1CDocumentManagementCoreClient.ActionCompleted(Result, ProcessAForm) Then
		ServerUpdateEnd(Result.ResultLongOperation);
		// Expand the application tree.
		TreeType = IntegrationWith1CDocumentManagement3Client.TreeType();
		TreeType.ThisIsApplicationTree = True;
		IntegrationWith1CDocumentManagement3Client.ExpandTheTree(
			TreeType,
			ApplicationTree.GetItems(),
			Items.ApplicationTree,
			StateOfApplicationTree);
		IsInitialized = True;
	ElsIf ProcessAForm Then
		ProcessFormAccordingToServiceVersion();
	EndIf;
	
EndProcedure

&AtServer
Procedure ServerUpdateEnd(TaskXDTOString)
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	XDTOTask = IntegrationWith1CDocumentManagementCore.StringInXDTOObject(Proxy, TaskXDTOString);
	ProcessResponseOfWebServiceToReceiptOfTask(XDTOTask);
	
EndProcedure

#EndRegion

#Region ActionOnTask

&AtClient
Procedure ActionOnTask(OperationType, TaskActionParameters = Undefined) Export
	
	If TaskActionParameters = Undefined Then
		TaskActionParameters = TaskActionParameters();
	EndIf;
	
	If OperationType.PerformConnectedTaskAction
			Or OperationType.PerformTemplateTaskAction
			Or OperationType.SelectTemplateForTask
			Or OperationType.CancelExecution Then
		ShowMessageBox(,NStr("vi = 'Chỉ có thể thực hiện thao tác này trong 1C:Document management';
							|ru = 'Данное действие можно выполнить только на стороне 1С:Документооборот';
							|en = 'You can perform this action only in 1C:Document Management'; fa = 'You can perform this action only in 1C:Document Management';
							|it = 'Данное действие можно выполнить только на стороне 1С:Документооборот';
							|pl = 'You can perform this action only in 1C:Document Management';
							|tr = 'Bu eylem sadece 1C:Document Management tarafında gerçekleştirilebilir'"));
		Return;
	EndIf;
	
	DataByTask = IntegrationWith1CDocumentManagement3Client.DataByTask(
		ThisObject,
		ID,
		Type,
		Title,
		TaskActionParameters.OperationParametersList);
	DataByTask.RequiredInteractiveAction = TaskActionParameters.RequiredInteractiveAction;
	
	Try
		LongTermOperationOnTask = IntegrationWith1CDocumentManagement3ServerCall.LongTermOperationOnTask(
			OperationType,
			DataByTask,
			UUID,
			TaskActionParameters.DataUpdateRequired);
	Except
		ErrorInfo = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		If IntegrationWith1CDocumentManagementCoreServerCall.NeedToProcessForm(ErrorInfo) Then
			ProcessFormAccordingToServiceVersion();
		EndIf;
	EndTry;
	
	NotificationParameters = New Structure("ID, Type, OperationType", ID, Type, OperationType);
	NotificationParameters.Insert("TaskActionParameters", TaskActionParameters);
	CallbackOnCompletion = New CallbackDescription(
		"ActionOnTaskCompletion",
		ThisObject,
		NotificationParameters);
	
	IntegrationWith1CDocumentManagementCoreClient.ExecuteRequestAsynchronously(
		ThisObject,
		LongTermOperationOnTask,
		CallbackOnCompletion,
		True,
		NStr("vi = 'Đang thực hiện thao tác đối với nhiệm vụ.';
			|ru = 'Выполняется действие над задачей.';
			|en = 'Executing the action on the task.'; fa = 'Executing the action on the task.';
			|it = 'Выполняется действие над задачей.';
			|pl = 'Executing the action on the task.';
			|tr = 'Görev üzerinde işlem gerçekleştirilmektedir.'"));
	
EndProcedure

&AtClient
Procedure ActionOnTaskCompletion(Result, NotificationParameters) Export
	
	ProcessAForm = False;
	If IntegrationWith1CDocumentManagementCoreClient.ActionCompleted(Result, ProcessAForm) Then
		UpdateError = "";
		ActionResult = ActionOnTaskOnServerEnds(Result.ResultLongOperation, UpdateError);
		If UpdateError <> "" Then
			IntegrationWith1CDocumentManagement3Client.ShowWarningFromBEFORE(,UpdateError);
		EndIf;
		RepeatedAction = New CallbackDescription(
			"ActionOnTask",
			ThisObject,
			NotificationParameters.TaskActionParameters);
		If IntegrationWith1CDocumentManagement3Client.InteractiveProcessingTriggered(
				ActionResult, NotificationParameters.OperationType, RepeatedAction) Then
			Return;
		EndIf;
		If ActionResult.Success Then
			// Expand the application tree.
			TreeType = IntegrationWith1CDocumentManagement3Client.TreeType();
			TreeType.ThisIsApplicationTree = True;
			IntegrationWith1CDocumentManagement3Client.ExpandTheTree(
				TreeType,
				ApplicationTree.GetItems(),
				Items.ApplicationTree,
				StateOfApplicationTree);
			Notify("Workflow_ActionOnTask", NotificationParameters, ThisObject);
		Else
			IntegrationWith1CDocumentManagement3Client.ShowWarningFromBEFORE(,ActionResult.WarningText);
		EndIf;
	ElsIf ProcessAForm Then
		ProcessFormAccordingToServiceVersion();
	EndIf;
	
	Items.ResultOfActionInText.ReadOnly = False;
	
EndProcedure

&AtServer
Function ActionOnTaskOnServerEnds(Val ResultOfActionIsString, UpdateError)
	
	DataForUpdate = Undefined;
	ActionResult = IntegrationWith1CDocumentManagement3.ResultOfCommandOnObject(
		ResultOfActionIsString,
		DataForUpdate);
	
	If ActionResult.Success And DataForUpdate <> Undefined Then
		Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
		If IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, DataForUpdate, "DMError") Then
			UpdateError = StrTemplate(
				NStr("vi = 'Khi cập nhật biểu mẫu đã xảy ra lỗi: 
					|%1';
					|ru = 'При обновлении формы возникла ошибка:
					|%1';
					|en = 'An error occurred when updating the form:
					|%1'; fa = 'An error occurred when updating the form:
					|%1';
					|it = 'При обновлении формы возникла ошибка:
					|%1';
					|pl = 'An error occurred when updating the form:
					|%1';
					|tr = 'Form güncellenirken hata oluştu:
					|%1'"),
				DataForUpdate.description);
		Else
			XDTOTask = DataForUpdate.objects[0];
			ProcessResponseOfWebServiceToReceiptOfTask(XDTOTask);
		EndIf;
	EndIf;
	
	Return ActionResult;
	
EndFunction

#EndRegion

#EndRegion