#Region Variables

&AtClient
Var KeyOfPreviousTaskLine;

&AtClient
Var CompositeIsSet;

&AtClient
Var ApplicationTreeRowKey;

&AtClient
Var StateOfApplicationTree;

&AtClient
Var SavedComments;

&AtClient
Var SavedTaskAction;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCore.WhenCreatingFormsHostedOnDesktopOnServer(Cancel);
	If Cancel Then
		Return;
	EndIf;
	
	ThisIsThinWindowsClient = Not IntegrationWith1CDocumentManagementCore.ApplicationIsWebClient()
		And Common.IsWindowsClient();
	PagesOfCreationCommandsBasedOn = PutToTempStorage(New Map, UUID);
	AbbreviatedNameOfConfiguration =
		IntegrationWith1CDocumentManagementCore.AbbreviatedNameOfConfiguration();
	
	DisplayArtist = True;
	DisplayLaborIntensity = False;
	
	FormKey = "IntegrationWith1CWorkflow3TasksForMe";
	
	AutoRefresh = Common.CommonSettingsStorageLoad(
		FormKey, "AutoRefresh", True);
	AutoRefreshPeriod = Common.CommonSettingsStorageLoad(
		FormKey, "AutoRefreshPeriod", 15); // Time in minutes.
	AutoDynamicListPageSize = Common.CommonSettingsStorageLoad(
		FormKey, "AutoDynamicListPageSize", True);
	DynamicListPageSize = Common.CommonSettingsStorageLoad(
		FormKey, "DynamicListPageSize", 20);
	FieldSortingDirection = Common.CommonSettingsStorageLoad(
		FormKey, "FieldSortingDirection", True);
	SortingField = Common.CommonSettingsStorageLoad(
		FormKey, "SortingField", "ListOfTaskActionsDate");
	If PossibleFieldsForSorting()[SortingField] = Undefined Then
		SortingField = "ListOfTaskActionsDate";
		FieldSortingDirection = True;
	EndIf;
	
	UpdateTaskCardDisplay();
	
	TotalPages = 1;
	CurrentPage = 1;
	UpdateDynamicListButtons();
	
	If SessionParameters.IntegrationWith1CDocumentManagementCurrentUser <> "" Then
		Title = StrTemplate(
			NStr("vi = 'Document Management: Nhiệm vụ đến (%1)';
				|ru = 'Документооборот: Задачи мне (%1)';
				|en = 'Document Management: My tasks (%1)'; fa = 'Document Management: My tasks (%1)';
				|it = 'Документооборот: Задачи мне (%1)';
				|pl = 'Document Management: My tasks (%1)';
				|tr = 'İş akışı: Benim için görevler (%1)'"),
			IntegrationWith1CDocumentManagementCoreCached.Current1CDocumentManagementUser()[0].name);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	KeyOfPreviousTaskLine = "";
	CompositeIsSet = 0;
	SavedComments = New Map;
	StateOfApplicationTree = New Map;
	
	TestConnection();
	
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
		SaveComment(Parameter.Text, Parameter.ID);
		CurTaskLine = ListOfTaskActionsCurrentData();
		If CurTaskLine <> Undefined
				And CurTaskLine.TaskActionID = Parameter.ID
				And CurTaskLine.TaskActionType = Parameter.Type Then
			ResultOfActionInText = Parameter.Text;
			DataVersionOfTaskAction = Parameter.DataVersionOfTaskAction;
		EndIf;
		TaskLine = StringByID(Parameter.ID, Parameter.Type);
		If TaskLine <> Undefined Then
			IntegrationWith1CDocumentManagement3ServerCall.UpdateTaskData(
				TaskLine.AdditionalDataAddress,
				Parameter.DataVersionOfTaskAction,
				Parameter.Text);
		EndIf;
		
	ElsIf EventName = "Workflow_ActionOnTask" Then
		If Source <> ThisObject
				And TypeOf(Parameter) = Type("Structure")
				And Parameter.Property("ID")
				And Parameter.Property("Type")
				And Parameter.Property("OperationType")
				And StringByID(Parameter.ID, Parameter.Type) <> Undefined Then
			If TypeOf(Source) = Type("ClientApplicationForm") And Source.FormOwner = ThisObject Then
				OutputIdleWindow = Parameter.OperationType.PerformTaskAction;
			Else
				OutputIdleWindow = False;
			EndIf;
			UpdateForm(OutputIdleWindow);
		EndIf;
		
	ElsIf EventName = "HTMLObjectPreviewReceived" Then
		If Not IntegrationWith1CDocumentManagementCoreClientServer.TheseAreNotificationParametersHTMLObjectPreviewReceived(
				Parameter) Then
			Return;
		EndIf;
		ProcessHTMLPreviewReceiptEvent(Parameter, Source);
		
	ElsIf EventName = "Recording_1CDocumentManagementFile" Then
		If DisplayingTaskCard = PredefinedValue("Enum.HowToDisplayReadingPane.DontDisplay")
				Or TypeOf(Parameter) <> Type("Structure")
				Or Not Parameter.Property("FileOperation")
				Or Not Parameter.Property("FileID")
				Or Not Parameter.Property("FileOwner")
				Or Not Parameter.Property("FileName")
				Or Not Parameter.Property("FormUniqueID")
				Or Not Parameter.FileOperation.InformFileListForm Then
			Return;
		EndIf;
		NeedUpdate = False;
		FoundIssueLines = New Array;
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
			NeedUpdate = UpdateAppByID(
				Parameter.FileOwner,
				AppUpdateOptions(),
				FoundIssueLines);
		EndIf;
		If NeedUpdate Then
			LinesOfNewFiles = New Array;
			If Parameter.FileOperation.CreatingFile Then
				For Each FoundTaskLine In FoundIssueLines Do
					NewFileLine = New Structure(
						"ApplicationPresentation, ApplicationID, ApplicationType, RowType, FileRoleID");
					NewFileLine.ApplicationPresentation = Parameter.FileName;
					NewFileLine.ApplicationID = Parameter.FileID;
					NewFileLine.ApplicationType = "DMFile";
					TaskActionString = ListOfTaskActions.FindByID(FoundTaskLine);
					NewFileLine.Insert("KeyOfFoundString", IssueLineKey(TaskActionString));
					LinesOfNewFiles.Add(NewFileLine);
				EndDo;
			EndIf;
			If Parameter.FormUniqueID = Undefined Then
				OutputIdleWindow = (Source = ThisObject);
			Else
				OutputIdleWindow = (UUID = Parameter.FormUniqueID);
			EndIf;
			UpdateForm(OutputIdleWindow,, LinesOfNewFiles);
		EndIf;
		
	ElsIf EventName = "DocumentManagement_AddingALink" Then
		If DisplayingTaskCard = PredefinedValue("Enum.HowToDisplayReadingPane.DontDisplay")
				Or TypeOf(Parameter) <> Type("Structure")
				Or Not Parameter.Property("ID")
				Or Not Parameter.Property("Type")
				Or Not Parameter.Property("Object") Then
			Return;
		EndIf;
		FoundIssueLines = New Array;
		AppUpdateOptions = AppUpdateOptions(Parameter.Type);
		AppUpdateOptions.AttributesForUpdate = New Structure("Ref, ApplicationPresentation",
			Parameter.Object,
			StrTemplate(NStr("vi = '%1, đối tượng %2';
							|ru = '%1, объект %2';
							|en = '%1, object %2'; fa = '%1, object %2';
							|it = '%1, объект %2';
							|pl = '%1, object %2';
							|tr = '%1, nesne %2'"), String(Parameter.Object), AbbreviatedNameOfConfiguration));
		AppUpdateOptions.CurrentRow = ListOfTaskActionsCurrentLine();
		UpdateComplete = UpdateAppByID(
			Parameter.ID,
			AppUpdateOptions,
			FoundIssueLines,
			True);
		For Each FoundTaskLine In FoundIssueLines Do
			TaskActionString = ListOfTaskActions.FindByID(FoundTaskLine);
			If TaskActionString <> Undefined Then
				TaskActionString.SuitableObjects = "";
				TaskActionString.KeyOfCreationCommandsPageBasedOn = "";
				DisplayCreationCommandsBasedOn(ListOfTaskActionsCurrentData());
			EndIf;
		EndDo;
		If UpdateComplete Then
			TreeType = IntegrationWith1CDocumentManagement3Client.TreeType();
			TreeType.ThisIsApplicationTree = True;
			IntegrationWith1CDocumentManagement3Client.ExpandTheTree(
				TreeType,
				ApplicationTree.GetItems(),
				Items.ApplicationTree,
				StateOfApplicationTree[IssueLineKey(ListOfTaskActionsCurrentData())]);
			// The refreshapplicationid method reassembles the tree on the server.
			// the expand tree method sets the Cur row of the tree.
		EndIf;
		
	ElsIf EventName = "DocumentManagement_DeletingALink" Then
		If DisplayingTaskCard = PredefinedValue("Enum.HowToDisplayReadingPane.DontDisplay")
				Or TypeOf(Parameter) <> Type("Structure")
				Or Not Parameter.Property("ID")
				Or Not Parameter.Property("Type")
				Or Not UpdateAppByID(Parameter.ID, AppUpdateOptions(Parameter.Type),, True) Then
			Return;
		EndIf;
		UpdateForm(False);
		
	ElsIf EventName = "Workflow_ActionWithProcessing" Then
		If TypeOf(Parameter) = Type("Structure")
				And Parameter.Property("DataProcessorData")
				And LineOnMainSubject(Parameter.DataProcessorData.SubjectOfID, Parameter.DataProcessorData.SubjectOfType)
					<> Undefined Then
			UpdateForm(False);
		EndIf;
		
	ElsIf EventName = "IntegrationWith1CWorkflow3_RuleWritten" Then
		UpdateForm(False);
		
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
Procedure SearchOnChange(Item)
	
	UpdateForm();
	
EndProcedure

&AtClient
Procedure ResultOfActionInTextTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	TaskLine = ListOfTaskActionsCurrentData();
	If TaskLine = Undefined Then
		Return;
	EndIf;
	
	If SavedComments[TaskLine.TaskActionID] = Text Then
		// The comment hasn't changed.
		Return;
	EndIf;
	
	SaveComment(Text, TaskLine.TaskActionID);
	SavedTaskAction = New Structure;
	SavedTaskAction.Insert("ID", TaskLine.TaskActionID);
	SavedTaskAction.Insert("Type", TaskLine.TaskActionType);
	SavedTaskAction.Insert("Text", Text);
	SavedTaskAction.Insert("DataVersionOfTaskAction", DataVersionOfTaskAction);
	
	AttachIdleHandler("SaveActionResult", 0.2, True);
	
	Notify("ChangedResultOfTextAction", SavedTaskAction, ThisObject);
	
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
	
	CurCurrentTaskLine = ListOfTaskActionsCurrentData();
	If CurCurrentTaskLine = Undefined Or Item.CurrentRow = Undefined Then
		Return;
	EndIf;
	
	NewKey = StrTemplate("%1_%2", CurCurrentTaskLine.TaskActionID, Item.CurrentRow);
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

#Region FormTableItemsEventHandlersListOfTaskActions

&AtClient
Procedure ListOfTaskActionsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	TaskLine = ListOfTaskActionsCurrentData();
	If TaskLine = Undefined Then
		Return;
	EndIf;
	
	DataByTask = IntegrationWith1CDocumentManagement3ClientServer.DataByTask(
		TaskLine.TaskActionID,
		TaskLine.TaskActionType,
		TaskLine.Title,
		TaskLine.URL);
	DataByTask.New = TaskLine.New;
	DataByTask.Overdue = TaskLine.Overdue;
	DataByTask.PresentationHTML = TaskLine.PresentationHTML;
	DataByTask.AdditionalDataAddress = TaskLine.AdditionalDataAddress;
	
	TreeType = IntegrationWith1CDocumentManagement3Client.TreeType();
	TreeType.ThisIsApplicationTree = True;
	CurCurrentStateOfTree = IntegrationWith1CDocumentManagement3Client.CurCurrentStateOfTree(
		TreeType,
		ApplicationTree.GetItems(),
		Items.ApplicationTree);
	
	FormParameters = New Structure;
	FormParameters.Insert("ID", TaskLine.TaskActionID);
	FormParameters.Insert("type", TaskLine.TaskActionType);
	FormParameters.Insert("DataByTask", DataByTask);
	FormParameters.Insert("SavedComment", SavedComments[TaskLine.TaskActionID]);
	FormParameters.Insert("StateOfApplicationTree", CurCurrentStateOfTree);
	FormParameters.Insert("MainSubjectID", TaskLine.MainSubjectID);
	FormParameters.Insert("MainSubjectType", TaskLine.MainSubjectType);
	FormParameters.Insert("SuitableObjects", TaskLine.SuitableObjects);
	
	OpenForm(
		"DataProcessor.IntegrationWith1CDocumentManagement3.Form.Task",
		FormParameters,
		ThisObject,
		TaskLine.TaskActionID);
	
EndProcedure

&AtClient
Procedure ListOfTaskActionsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure ListOfTaskActionsBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure ListOfTaskActionsOnActivateRow(Item)
	
	If Item.CurrentRow = Undefined Or Item.CurrentRow = CompositeIsSet Then
		Return;
	EndIf;
	CompositeIsSet = Item.CurrentRow;
	
	AttachIdleHandler("WhenActivatingTaskBar", 0.2, True);
	
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
Procedure Back(Command)
	
	CurrentPage = CurrentPage - 1;
	UpdateForm(False);
	
EndProcedure

&AtClient
Procedure GoForward(Command)
	
	CurrentPage = CurrentPage + 1;
	UpdateForm(False);
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	UpdateForm();
	
EndProcedure

&AtClient
Procedure UpdatePreviewCommand(Command)
	
	UpdatePreview1(True);
	
EndProcedure

&AtClient
Procedure PageChoice(Command)
	
	CallbackOnCompletion = New CallbackDescription("PageChoiceCompletion", ThisObject);
	IntegrationWith1CDocumentManagement3Client.SelectDynamicListPage(
		ThisObject,
		Command,
		CurrentPage,
		TotalPages,
		CallbackOnCompletion);
	
EndProcedure

&AtClient
Procedure PageChoiceCompletion(NewPage, AdditionalParameters) Export
	
	If NewPage = Undefined Then
		Return;
	EndIf;
	
	CurrentPage = NewPage;
	UpdateForm(False);
	
EndProcedure

&AtClient
Procedure SettingAutoupdate(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("AutoRefresh", AutoRefresh);
	FormParameters.Insert("AutoRefreshPeriod", AutoRefreshPeriod);
	FormParameters.Insert("InMinutes", True);
	
	Notification = New CallbackDescription("SettingAutoupdateCompletion", ThisObject);
	
	OpenForm(
		"DataProcessor.IntegrationWith1CDocumentManagementCore.Form.SettingAutoupdate",
		FormParameters,
		ThisObject,,,,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SettingAutoupdateCompletion(Result, Var_Parameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	AutoRefresh = Result.AutoRefresh;
	AutoRefreshPeriod = Result.AutoRefreshPeriod;
	
	DetachIdleHandler("AutoRefresh");
	
	StructuresArray = New Array;
	
	Item = New Structure;
	Item.Insert("Object", FormKey);
	Item.Insert("Setting", "AutoRefresh");
	Item.Insert("Value", AutoRefresh);
	StructuresArray.Add(Item);
	
	Item = New Structure;
	Item.Insert("Object", FormKey);
	Item.Insert("Setting", "AutoRefreshPeriod");
	Item.Insert("Value", AutoRefreshPeriod);
	StructuresArray.Add(Item);
	
	IntegrationWith1CDocumentManagementCoreClient.CommonSettingsStorageSaveArray(StructuresArray);
	
	If AutoRefresh Then
		AttachIdleHandler("AutoRefresh", AutoRefreshPeriod * 60);
	EndIf;
	
EndProcedure

&AtClient
Procedure TasksSettings(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("DisplayingTaskCard", DisplayingTaskCard);
	If AutoDynamicListPageSize Then
		FormParameters.Insert("DynamicListPageSize", 0);
	Else
		FormParameters.Insert("DynamicListPageSize", DynamicListPageSize);
	EndIf;
	
	Notification = New CallbackDescription("TasksSettingsCompletion", ThisObject);
	
	OpenForm(
		"DataProcessor.IntegrationWith1CDocumentManagement3.Form.TasksSettings",
		FormParameters,
		ThisObject,,,,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure TasksSettingsCompletion(Result, Var_Parameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	NeedToUpdateForm = False;
	
	If DisplayingTaskCard <> Result.DisplayingTaskCard Then
		NeedToUpdateForm =
			(DisplayingTaskCard = PredefinedValue("Enum.HowToDisplayReadingPane.DontDisplay"));
		DisplayingTaskCard = Result.DisplayingTaskCard;
	EndIf;
	
	If Result.DynamicListPageSize = 0 Then
		// Auto mode needs to be enabled.
		If AutoDynamicListPageSize = False Then
			// Before that, auto mode was turned off.
			AutoDynamicListPageSize = True;
			NewValueDynamicListPageSize = 20;
			DirectionOfPageResizing = Undefined;
		Else
			// Auto mode has already been turned on, we do not change anything.
			NewValueDynamicListPageSize = DynamicListPageSize;
		EndIf;
	Else
		// Auto mode must be turned off.
		AutoDynamicListPageSize = False;
		NewValueDynamicListPageSize = Result.DynamicListPageSize;
	EndIf;
	
	If DynamicListPageSize <> NewValueDynamicListPageSize Then
		NeedToUpdateForm = True;
		DynamicListPageSize = NewValueDynamicListPageSize;
	EndIf;
	
	If NeedToUpdateForm Then
		UpdateForm();
	EndIf;
	
	StructuresArray = New Array;
	
	Item = New Structure;
	Item.Insert("Object", FormKey);
	Item.Insert("Setting", "DisplayingTaskCard");
	Item.Insert("Value", DisplayingTaskCard);
	StructuresArray.Add(Item);
	
	Item = New Structure;
	Item.Insert("Object", FormKey);
	Item.Insert("Setting", "AutoDynamicListPageSize");
	Item.Insert("Value", AutoDynamicListPageSize);
	StructuresArray.Add(Item);
	
	Item = New Structure;
	Item.Insert("Object", FormKey);
	Item.Insert("Setting", "DynamicListPageSize");
	Item.Insert("Value", DynamicListPageSize);
	StructuresArray.Add(Item);
	
	IntegrationWith1CDocumentManagementCoreClient.CommonSettingsStorageSaveArray(StructuresArray);
	
	UpdateTaskCardDisplay();
	
EndProcedure

&AtClient
Procedure ArrangeListOfActionsTasksTitleInAscendingOrder(Command)
	
	OldSortingField = SortingField;
	SortingField = "ListOfTaskActionsTitle";
	FieldSortingDirection = False;
	IntegrationWith1CDocumentManagement3Client.ArrangeCommand(
		ThisObject,
		OldSortingField,
		SortingField,
		FieldSortingDirection,
		FormKey);
	UpdateForm();
	
EndProcedure

&AtClient
Procedure ArrangeListOfActionsTasksTitleInDescendingOrder(Command)
	
	OldSortingField = SortingField;
	SortingField = "ListOfTaskActionsTitle";
	FieldSortingDirection = True;
	IntegrationWith1CDocumentManagement3Client.ArrangeCommand(
		ThisObject,
		OldSortingField,
		SortingField,
		FieldSortingDirection,
		FormKey);
	UpdateForm();
	
EndProcedure

&AtClient
Procedure ArrangeListOfTaskActionsDateInAscendingOrder(Command)
	
	OldSortingField = SortingField;
	SortingField = "ListOfTaskActionsDate";
	FieldSortingDirection = False;
	IntegrationWith1CDocumentManagement3Client.ArrangeCommand(
		ThisObject,
		OldSortingField,
		SortingField,
		FieldSortingDirection,
		FormKey);
	UpdateForm();
	
EndProcedure

&AtClient
Procedure ArrangeListOfActionsTasksDateInDescendingOrder(Command)
	
	OldSortingField = SortingField;
	SortingField = "ListOfTaskActionsDate";
	FieldSortingDirection = True;
	IntegrationWith1CDocumentManagement3Client.ArrangeCommand(
		ThisObject,
		OldSortingField,
		SortingField,
		FieldSortingDirection,
		FormKey);
	UpdateForm();
	
EndProcedure

&AtClient
Procedure ArrangeListOfTaskActionsDueDateInAscendingOrder(Command)
	
	OldSortingField = SortingField;
	SortingField = "ListOfTaskActionsDueDate";
	FieldSortingDirection = False;
	IntegrationWith1CDocumentManagement3Client.ArrangeCommand(
		ThisObject,
		OldSortingField,
		SortingField,
		FieldSortingDirection,
		FormKey);
	UpdateForm();
	
EndProcedure

&AtClient
Procedure ArrangeListOfTaskActionsDueDateInDescendingOrder(Command)
	
	OldSortingField = SortingField;
	SortingField = "ListOfTaskActionsDueDate";
	FieldSortingDirection = True;
	IntegrationWith1CDocumentManagement3Client.ArrangeCommand(
		ThisObject,
		OldSortingField,
		SortingField,
		FieldSortingDirection,
		FormKey);
	UpdateForm();
	
EndProcedure

&AtClient
Procedure ArrangeListOfActionsTasksAuthorRowInAscendingOrder(Command)
	
	OldSortingField = SortingField;
	SortingField = "ListOfTaskActionsAuthorAsString";
	FieldSortingDirection = False;
	IntegrationWith1CDocumentManagement3Client.ArrangeCommand(
		ThisObject,
		OldSortingField,
		SortingField,
		FieldSortingDirection,
		FormKey);
	UpdateForm();
	
EndProcedure

&AtClient
Procedure ArrangeListOfActionsTasksAuthorInDescendingOrder(Command)
	
	OldSortingField = SortingField;
	SortingField = "ListOfTaskActionsAuthorAsString";
	FieldSortingDirection = True;
	IntegrationWith1CDocumentManagement3Client.ArrangeCommand(
		ThisObject,
		OldSortingField,
		SortingField,
		FieldSortingDirection,
		FormKey);
	UpdateForm();
	
EndProcedure

&AtClient
Procedure PerformTaskActionOption1(Command)
	
	OperationType = IntegrationWith1CDocumentManagementCoreClientServer.TypeOfOperationOnTask();
	OperationType.PerformTaskAction = True;
	TaskActionParameters = TaskActionParameters();
	TaskActionParameters.OperationParametersList = New Structure("ResultOfOptionNumber", "ResultOfOption1");
	ActionOnTask(OperationType, TaskActionParameters);
	
EndProcedure

&AtClient
Procedure PerformTaskActionOption2(Command)
	
	OperationType = IntegrationWith1CDocumentManagementCoreClientServer.TypeOfOperationOnTask();
	OperationType.PerformTaskAction = True;
	TaskActionParameters = TaskActionParameters();
	TaskActionParameters.OperationParametersList = New Structure("ResultOfOptionNumber", "ResultOfOption2");
	ActionOnTask(OperationType, TaskActionParameters);
	
EndProcedure

&AtClient
Procedure PerformTaskActionOption3(Command)
	
	OperationType = IntegrationWith1CDocumentManagementCoreClientServer.TypeOfOperationOnTask();
	OperationType.PerformTaskAction = True;
	TaskActionParameters = TaskActionParameters();
	TaskActionParameters.OperationParametersList = New Structure("ResultOfOptionNumber", "ResultOfOption3");
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
	
	CurrentData = ListOfTaskActionsCurrentData();
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagement3Client.Attachable_CreateLinkedObject(
		Command,
		CurrentData.MainSubjectID,
		CurrentData.MainSubjectType,
		UUID);
	
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
	
	CurrentData = ListOfTaskActionsCurrentData();
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Task", CurrentData.Title);
	FormParameters.Insert("TaskID", CurrentData.TaskActionID);
	FormParameters.Insert("TaskType", CurrentData.TaskActionType);
	FormParameters.Insert("UseIntegrationBefore3", True);
	OpenForm(
		"DataProcessor.IntegrationWith1CDocumentManagementCore.Form.TaskRedirecting",
		FormParameters);
	
EndProcedure

&AtClient
Procedure QuickSearch(Command)
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("QuickSearch", QuickSearch);
	OpeningParameters.Insert("QuickSearchChoiceLists", QuickSearchChoiceLists);
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("QuickSearch", QuickSearch);
	
	CallbackDescription = New CallbackDescription("SetUpQuickSearchEnd", ThisObject, HandlerParameters);
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement3.Form.QuickSearch",
		OpeningParameters,,,,,
		CallbackDescription);
	
EndProcedure

&AtClient
Procedure SetUpQuickSearchEnd(NewQuickSearch, AdditionalParameters) Export
	
	If TypeOf(NewQuickSearch) <> Type("FormDataCollection") Then
		Return;
	EndIf;
	
	NeedToUpdateForm = QuickSearchHasChanged(QuickSearch, NewQuickSearch);
	
	QuickSearch.Clear();
	For Each NewSearchString In NewQuickSearch Do
		QuickSearchString = QuickSearch.Add();
		FillPropertyValues(
			QuickSearchString,
			NewSearchString,
			IntegrationWith1CDocumentManagement3ClientServer.QuickSearchColumns());
	EndDo;
	
	QuickSearchForChangesAtClient(NeedToUpdateForm);
	
EndProcedure

&AtClient
Procedure ResetFilter(Command)
	
	ResetSelectionOnServer();
	
	SaveQuickSearch();
	
	UpdateForm();
	
EndProcedure

&AtClient
Procedure AddParticipants(Command)
	
	CurrentData = ListOfTaskActionsCurrentData();
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	FormParameters = New Structure("MainSubjectID, MainSubjectType",
		CurrentData.MainSubjectID,
		CurrentData.MainSubjectType);
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
Procedure AutoRefresh()
	
	UpdateForm(False);
	
EndProcedure

&AtClient
Procedure QuickSearchForChangesAtClient(NeedToUpdateForm)
	
	SaveQuickSearch();
	
	If NeedToUpdateForm Then
		UpdateForm();
	EndIf;
	
	UpdateQuickSearchPresentation();
	
EndProcedure

&AtClient
Procedure RestorePositionInList()
	
	For Each String In ListOfTaskActions Do
		
		If String.TaskActionID = CurrentRow Then
			Items.ListOfTaskActions.CurrentRow = String.GetID();
			Return;
		EndIf;
		
	EndDo;
	
	If NextRow = "" Then
		Return;
		
	ElsIf NextRow = "ListEnd" Then
		LastRowIndex = ListOfTaskActions.Count() - 1;
		Items.ListOfTaskActions.CurrentRow = ListOfTaskActions[LastRowIndex].GetID();
		Return;
		
	Else
		For Each String In ListOfTaskActions Do
			
			If String.TaskActionID = NextRow Then
				Items.ListOfTaskActions.CurrentRow = String.GetID();
				Return;
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

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
Procedure UpdateAutoDynamicListPageSize(BeginTime)
	
	If AutoDynamicListPageSize = False Then
		Return;
	EndIf;
	
	MinimumUpdateTime = 2; // Time in seconds.
	MaximumUpdateTime = 4; // Time in seconds.
	Step = 5; // Number of tasks.
	LowerBound = 5; // Number of tasks.
	UpperBound = 50; // Number of tasks.
	
	NewValueDynamicListPageSize = DynamicListPageSize;
	
	OperationTime_ = (CurrentUniversalDateInMilliseconds() - BeginTime) / 1000;
	
	If OperationTime_ > MaximumUpdateTime Then
		// You need to reduce the number of tasks on the page (if there is room to reduce).
		If DynamicListPageSize > LowerBound
				And TargetTimeForUpdatingListWasExceeded
				And (DirectionOfPageResizing = "Decrease"
					Or DirectionOfPageResizing = Undefined) Then
			NewValueDynamicListPageSize = DynamicListPageSize - Step;
			DirectionOfPageResizing = "Decrease";
			TargetTimeForUpdatingListWasExceeded = False;
		ElsIf Not TargetTimeForUpdatingListWasExceeded Then
			TargetTimeForUpdatingListWasExceeded = True;
		EndIf;
		
	Else
		TargetTimeForUpdatingListWasExceeded = False;
		If OperationTime_ < MinimumUpdateTime Then
			// You need to increase the number of tasks on the page (if the maximum number of tasks was received).
			If DynamicListPageSize < UpperBound
					And DynamicListPageSize = ListOfTaskActions.Count()
					And (DirectionOfPageResizing = "Increase"
						Or DirectionOfPageResizing = Undefined) Then
				NewValueDynamicListPageSize = DynamicListPageSize + Step;
				DirectionOfPageResizing = "Increase";
			EndIf;
		EndIf;
		
	EndIf;
	
	If DynamicListPageSize <> NewValueDynamicListPageSize Then
		DynamicListPageSize = NewValueDynamicListPageSize;
		Item = New Structure;
		Item.Insert("Object", FormKey);
		Item.Insert("Setting", "DynamicListPageSize");
		Item.Insert("Value", DynamicListPageSize);
		IntegrationWith1CDocumentManagementCoreClient.CommonSettingsStorageSaveArray(
			CommonClientServer.ValueInArray(Item));
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateImageOfArrangeCommand()
	
	For Each Popup In Items.OrganizeListOfTaskActionsSubmenu.ChildItems Do
		If Popup.Picture <> PictureLib.IsEmpty Then
			Popup.Picture = PictureLib.IsEmpty;
		EndIf;
		For Each ItemSubmenu In Popup.ChildItems Do
			If ItemSubmenu.Picture <> PictureLib.IsEmpty Then
				ItemSubmenu.Picture = PictureLib.IsEmpty;
			EndIf;
		EndDo;
	EndDo;
	
	If FieldSortingDirection = False Then
		HeadingDirection = "Ascending";
	Else
		HeadingDirection = "Descending";
	EndIf;
	
	Items["Order" + SortingField].Picture = PictureLib.AppearanceCheckBox;
	Items["Order" + SortingField + HeadingDirection].Picture = PictureLib.AppearanceCheckBox;
	
EndProcedure

&AtClient
Procedure UpdatePreview1(UpdateData1 = False, IgnoreMaxSize = False)
	
	If DisplayingTaskCard = PredefinedValue("Enum.HowToDisplayReadingPane.DontDisplay") Then
		Return;
	EndIf;
	
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
		CurCurrentTaskLine = ListOfTaskActionsCurrentData();
		If CurCurrentTaskLine <> Undefined Then
			PresentationHTML = CurCurrentTaskLine.PresentationHTML;
		Else
			PresentationHTML = IntegrationWith1CDocumentManagementCoreClientServer.MessageAboutAbsenceOfPreview(
				TitleOfMessageInPreviewArea);
		EndIf;
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
		HTMLMessage = IntegrationWith1CDocumentManagementCoreClientServer.PreviewMessage(
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
	
	CurCurrentTaskLine = ListOfTaskActionsCurrentData();
	If CurCurrentTaskLine = Undefined Then
		Return;
	EndIf;
	
	UpdatePreview1();
	
	// Save the Cur State of the application tree.
	TreeType = IntegrationWith1CDocumentManagement3Client.TreeType();
	TreeType.ThisIsApplicationTree = True;
	CurCurrentStateOfTree = IntegrationWith1CDocumentManagement3Client.CurCurrentStateOfTree(
		TreeType,
		ApplicationTree.GetItems(),
		Items.ApplicationTree);
	
	StateOfApplicationTree[IssueLineKey(CurCurrentTaskLine)] = CurCurrentStateOfTree;
	
EndProcedure

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
	ParametersOfUpdate.CurrentRow = ListOfTaskActionsCurrentLine();
	IntegrationWith1CDocumentManagementCoreClientServer.FillInNDPOfPpeStructure(
		ParametersOfUpdate.ASBS,
		Parameter);
	UpdateComplete = UpdateAppByID(Parameter.ID, ParametersOfUpdate);
	If UpdateComplete Then
		TreeType = IntegrationWith1CDocumentManagement3Client.TreeType();
		TreeType.ThisIsApplicationTree = True;
		IntegrationWith1CDocumentManagement3Client.ExpandTheTree(
			TreeType,
			ApplicationTree.GetItems(),
			Items.ApplicationTree,
			StateOfApplicationTree[IssueLineKey(ListOfTaskActionsCurrentData())]);
		// The refreshapplicationid method reassembles the tree on the server.
		// the expand tree method sets the Cur row of the tree,
		// and the preview update method will be implicitly called.
	EndIf;
	
EndProcedure

&AtClient
Procedure DisplayDataOnCurTask(LinesOfNewFiles = Undefined)
	
	TaskLine = ListOfTaskActionsCurrentData();
	If TaskLine = Undefined Then
		If ListOfTaskActions.Count() = 0 Then
			If Items.ThereAreOneTaskPagesAndSeveralPagesThatAreMissing.CurrentPage <> Items.NoIssuesPage Then
				Items.ThereAreOneTaskPagesAndSeveralPagesThatAreMissing.CurrentPage = Items.NoIssuesPage;
			EndIf;
			If Items.TeamPageGroup.CurrentPage <> Items.GroupTeamPage Then
				Items.TeamPageGroup.CurrentPage = Items.GroupTeamPage;
				Items.TeamPageGroup.Visible = False;
			EndIf;
			Items.TakeToWork.Visible = False;
			Items.TakeToWork.Enabled = False;
			Items.CancelTakingToWork.Visible = True;
			Items.CancelTakingToWork.Enabled = False;
			Items.FlagsSubmenu.Picture = PictureLib.IsEmptyFlag;
			UpdateWidthOfFormElements();
			Return;
		Else
			TaskLine = ListOfTaskActions[0];
		EndIf;
	EndIf;
	
	CurTaskLineKey = IssueLineKey(TaskLine);
	
	If Items.ThereAreOneTaskPagesAndSeveralPagesThatAreMissing.CurrentPage <> Items.PageOneTask Then
		Items.ThereAreOneTaskPagesAndSeveralPagesThatAreMissing.CurrentPage = Items.PageOneTask;
	EndIf;
	
	CurrentRow = TaskLine.TaskActionID;
	
	TotalRows = ListOfTaskActions.Count();
	If TotalRows = 1 Then
		If TotalPages = 1 Then
			// If there is only 1 task on a single page, there is no next one at all.
			NextRow = "";
		Else
			// If there is only one task on the page, but there are other pages, the next one will be the last task
			// on another page.
			NextRow = "ListEnd";
		EndIf;
		
	Else
		
		CurLineNumber = ListOfTaskActions.IndexOf(TaskLine) + 1;
		If CurLineNumber <> TotalRows Then
			// If the task is not the last in the list, we take the next task from the list on the page.
			NextRow = ListOfTaskActions[CurLineNumber].TaskActionID;
			
		Else
			
			If CurrentPage = TotalPages Then
				// If the task is the last in the list and this is the last page, the previous task will be next.
				NextRow = ListOfTaskActions[CurLineNumber - 2].TaskActionID;
				
			Else
				// If the task is the last in the list and there are other pages behind it, the first task
				// from the next page will be next.
				NextRow = "ListEnd";
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	TreeType = IntegrationWith1CDocumentManagement3Client.TreeType();
	TreeType.ThisIsApplicationTree = True;
	
	If Not IsBlankString(KeyOfPreviousTaskLine) Then
		// save the State of the tree of the previous task.
		CurCurrentStateOfTree = IntegrationWith1CDocumentManagement3Client.CurCurrentStateOfTree(
			TreeType,
			ApplicationTree.GetItems(),
			Items.ApplicationTree);
		
		StateOfApplicationTree[KeyOfPreviousTaskLine] = CurCurrentStateOfTree;
		If LinesOfNewFiles <> Undefined Then
			For Each NewFileLine In LinesOfNewFiles Do
				If StateOfApplicationTree[NewFileLine.KeyOfFoundString] <> Undefined Then
					StateOfApplicationTree[NewFileLine.KeyOfFoundString].KeyOfCurRowOfTree =
						IntegrationWith1CDocumentManagement3Client.TreeRowKey(TreeType, NewFileLine);
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	SavedComment = SavedComments[TaskLine.TaskActionID];
	DisplayAdditionalData(TaskLine.AdditionalDataAddress, SavedComment);
	
	If DisplayingTaskCard <> PredefinedValue("Enum.HowToDisplayReadingPane.DontDisplay") Then
		IntegrationWith1CDocumentManagement3Client.ExpandTheTree(
			TreeType,
			ApplicationTree.GetItems(),
			Items.ApplicationTree,
			StateOfApplicationTree[CurTaskLineKey]);
	EndIf;
	
	KeyOfPreviousTaskLine = CurTaskLineKey;
	
	DisplayCreationCommandsBasedOn(TaskLine);
	
EndProcedure

&AtClient
Procedure DisplayCreationCommandsBasedOn(TaskLine)
	
	If TaskLine = Undefined Then
		Return;
	EndIf;
	
	NewPage = Items["GroupTeamPage" + TaskLine.KeyOfCreationCommandsPageBasedOn];
	If Items.TeamPageGroup.CurrentPage <> NewPage Then
		Items.TeamPageGroup.CurrentPage = NewPage;
		Items.TeamPageGroup.Visible =
			(NewPage.ChildItems[0].ChildItems[0].ChildItems.Count() > 0);
	EndIf;
	
EndProcedure

&AtClient
Procedure WhenActivatingTaskBar()
	
	DisplayDataOnCurTask();
	
EndProcedure

&AtClient
Procedure SaveQuickSearch()
	
	Filter_Settings = New Array;
	For Each String In QuickSearch Do
		FilterSettings = New Structure(IntegrationWith1CDocumentManagement3ClientServer.QuickSearchColumns());
		FillPropertyValues(
			FilterSettings,
			String,
			IntegrationWith1CDocumentManagement3ClientServer.QuickSearchColumns());
		Filter_Settings.Add(FilterSettings);
	EndDo;
	
	PersonalSettings_ = New Structure;
	PersonalSettings_.Insert("Object", FormKey);
	PersonalSettings_.Insert("Setting", "QuickTaskSearchForMe");
	PersonalSettings_.Insert("Value", Filter_Settings);
	
	IntegrationWith1CDocumentManagementCoreClient.CommonSettingsStorageSaveArray(
		CommonClientServer.ValueInArray(PersonalSettings_));
	
EndProcedure

&AtClient
Procedure SaveComment(Text, ID)
	
	If Not IsBlankString(Text) Or SavedComments[ID] <> Undefined Then
		SavedComments[ID] = Text;
	EndIf;
	
EndProcedure

&AtClient
Procedure SaveActionResult()
	
	If Items.ResultOfActionInText.ReadOnly Or Not ValueIsFilled(SavedTaskAction) Then
		Return;
	EndIf;
	
	TaskLine = StringByID(SavedTaskAction.ID, SavedTaskAction.Type);
	If TaskLine = Undefined Then
		Return;
	EndIf;
	
	NewVersionOfTheData = IntegrationWith1CDocumentManagement3ServerCall.SaveActionResult(
		SavedTaskAction.Text,
		SavedTaskAction.ID,
		SavedTaskAction.DataVersionOfTaskAction,
		TaskLine.AdditionalDataAddress);
	If ValueIsFilled(NewVersionOfTheData)
			And SavedTaskAction.DataVersionOfTaskAction <> NewVersionOfTheData Then
		CurTaskLine = ListOfTaskActionsCurrentData();
		If CurTaskLine <> Undefined
				And CurTaskLine.TaskActionID = SavedTaskAction.ID
				And CurTaskLine.TaskActionType = SavedTaskAction.Type Then
			DataVersionOfTaskAction = NewVersionOfTheData;
		EndIf;
		SavedTaskAction.DataVersionOfTaskAction = NewVersionOfTheData;
		Notify("ChangedResultOfTextAction", SavedTaskAction, ThisObject);
	EndIf;
	
	SavedTaskAction = Undefined;
	
EndProcedure

&AtClient
Function ListOfTaskActionsCurrentLine()
	
	ListOfTaskActionsCurrentLine = Undefined;
	
	ListOfTaskActionsCurrentLine = Items.ListOfTaskActions.CurrentRow;
	If ListOfTaskActionsCurrentLine = Undefined Then
		If ListOfTaskActions.Count() > 0 Then
			ListOfTaskActionsCurrentLine = ListOfTaskActions[0].GetID();
			Items.ListOfTaskActions.CurrentRow = ListOfTaskActionsCurrentLine;
		EndIf;
	EndIf;
	
	Return ListOfTaskActionsCurrentLine;
	
EndFunction

&AtClient
Function ListOfTaskActionsCurrentData()
	
	ListOfTaskActionsCurrentData = Items.ListOfTaskActions.CurrentData;
	If ListOfTaskActionsCurrentData = Undefined Then
		If ListOfTaskActions.Count() > 0 Then
			ListOfTaskActionsCurrentData = ListOfTaskActions[0];
		EndIf;
	EndIf;
	
	Return ListOfTaskActionsCurrentData;
	
EndFunction

&AtClient
Function StringByID(TaskActionID, TaskActionType)
	
	For Each String In ListOfTaskActions Do
		
		If String.TaskActionID = TaskActionID And String.TaskActionType = TaskActionType Then
			Return String;
		EndIf;
		
	EndDo;
	
	Return Undefined;
	
EndFunction

&AtClient
Function LineOnMainSubject(MainSubjectID, MainSubjectType)
	
	For Each String In ListOfTaskActions Do
		
		If String.MainSubjectID = MainSubjectID And String.MainSubjectType = MainSubjectType Then
			Return String;
		EndIf;
		
	EndDo;
	
	Return Undefined;
	
EndFunction

&AtClient
Procedure SetAccessibilityOfControls(Var_Enabled)
	
	Items.ThereArePagesNoData.Enabled = Var_Enabled;
	Items.TeamPageGroup.Enabled = Var_Enabled;
	Items.Forward.Enabled = Var_Enabled;
	Items.TakeToWork.Enabled = Var_Enabled;
	Items.CommandPanelActionList.Enabled = Var_Enabled;
	Items.FormQuickSearch.Enabled = Var_Enabled;
	Items.GroupAddMembersSubtask.Enabled = Var_Enabled;
	
EndProcedure

#EndRegion

#Region ClientServer

&AtClientAtServerNoContext
Function PossibleFieldsForSorting()
	
	PossibleFieldsForSorting = New Map;
	PossibleFieldsForSorting.Insert("ListOfTaskActionsTitle", "title");
	PossibleFieldsForSorting.Insert("ListOfTaskActionsDate", "date");
	PossibleFieldsForSorting.Insert("ListOfTaskActionsDueDate", "term");
	PossibleFieldsForSorting.Insert("ListOfTaskActionsAuthorAsString", "authorPresentation");
	
	Return PossibleFieldsForSorting;
	
EndFunction

&AtClientAtServerNoContext
Function IssueLineKey(TaskBar)
	
	If TaskBar = Undefined Then
		Return "";
	EndIf;
	
	Return StrTemplate("%1_%2",
		TaskBar.TaskActionID,
		TaskBar.TaskActionType);
	
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

&AtClientAtServerNoContext
Function DisplayFilters(Search)
	
	DisplayFilters = New ValueList;
	If Not IsBlankString(Search) Then
		DisplayFilters.Add("%" + Search + "%", "title");
	EndIf;
	
	Return DisplayFilters;
	
EndFunction

#EndRegion

#Region Server

&AtServer
Function QuickSearchHasChanged(Val QuickSearch, Val NewQuickSearch)
	
	QuickSearchColumns = StrReplace(
		IntegrationWith1CDocumentManagement3ClientServer.QuickSearchColumns(),
		"Value, ",
		"");
	
	Return Not Common.IdenticalCollections(
		QuickSearch.Unload(, QuickSearchColumns),
		NewQuickSearch.Unload(, QuickSearchColumns));
	
EndFunction

&AtServer
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
		
		SubordinateApplications = AllApplicationsInValueTree(
			String.Rows,
			ApplicationID,
			ApplicationType,
			OnlyBasicSubjects);
		For Each FoundRow In SubordinateApplications Do
			Result.Add(FoundRow);
		EndDo;
		
	EndDo;
	
	Return Result;
	
EndFunction

&AtServer
Procedure AddFlagToSelectionList(Flag, FlagSelectionList)
	
	FlagData = IntegrationWith1CDocumentManagement3.FlagData(Flag);
	FlagSelectionList.Add(Flag, FlagData.Presentation,, FlagData.Picture);
	
EndProcedure

// Checks the relevance of the filter value.
//
// Parameters:
//   ChoiceList - ValueList of See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//   Value - String
//            - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//   ValueID - String
//   ValueType - String
//
// Returns:
//   Boolean
//
&AtServer
Function FilterValueIsOutdated(ChoiceList, Value, ValueID = "", ValueType = "")
	
	ValueIsOutdated = True;
	Var_156_ValueType = TypeOf(Value);
	
	For Each SelectionListItem In ChoiceList Do
		
		If TypeOf(SelectionListItem.Value) = Type("Structure") Then
			
			If Var_156_ValueType = Type("String") Then
				
				If SelectionListItem.Value.Description = Value
						And SelectionListItem.Value.ID = ValueID
						And SelectionListItem.Value.Type = ValueType Then
					ValueIsOutdated = False;
					Break;
				EndIf;
				
			ElsIf Var_156_ValueType = Type("Structure") Then
				
				If SelectionListItem.Value.Description = Value.Description
						And SelectionListItem.Value.ID = Value.ID
						And SelectionListItem.Value.Type = Value.Type Then
					ValueIsOutdated = False;
					Break;
				EndIf;
				
			EndIf;
			
		ElsIf TypeOf(SelectionListItem.Value) = Type("String") Then
			
			If Var_156_ValueType = Type("String") Then
				
				If SelectionListItem.Value = Value Then
					ValueIsOutdated = False;
					Break;
				EndIf;
				
			ElsIf Var_156_ValueType = Type("Structure") Then
				
				If SelectionListItem.Value = Value.Description Then
					ValueIsOutdated = False;
					Break;
				EndIf;
				
			EndIf;
			
		EndIf
		
	EndDo;
	
	Return ValueIsOutdated;
	
EndFunction

&AtServer
Procedure NewQuickSearchBar(Parameter, ParameterPresentation, Type, DefaultValue = "", Sort = "")
	
	NewRow = QuickSearch.Add();
	NewRow.Parameter = Parameter;
	NewRow.ParameterPresentation = ParameterPresentation;
	NewRow.Type = Type;
	NewRow.DefaultValue = DefaultValue;
	NewRow.DefaultValueID = "";
	NewRow.DefaultValueType = "";
	NewRow.Value = NewRow.DefaultValue;
	NewRow.ValueID = NewRow.DefaultValueID;
	NewRow.ValueType = NewRow.DefaultValueType;
	If ValueIsFilled(Sort) Then
		NewRow.Sort = Sort;
	Else
		NewRow.Sort = NewRow.ParameterPresentation;
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateDynamicListButtons()
	
	IntegrationWith1CDocumentManagement3ClientServer.UpdateDynamicListButtons(
		ThisObject,
		CurrentPage,
		TotalPages);
	For ButtonNumber = 1 To 9 Do
		PageItem = Items["Page" + ButtonNumber];
		If PageItem.Title = "..." Then
			Commands["Page" + ButtonNumber].ToolTip = NStr("vi = 'Chọn trang';
															|ru = 'Выбрать страницу';
															|en = 'Select a page'; fa = 'Select a page';
															|it = 'Выбрать страницу';
															|pl = 'Select a page';
															|tr = 'Sayfa seç'");
		Else
			Commands["Page" + ButtonNumber].ToolTip = StrTemplate(
				NStr("vi = 'Trang %1';
					|ru = 'Страница %1';
					|en = 'Page %1'; fa = 'Page %1';
					|it = 'Pagina %1';
					|pl = 'Strona %1';
					|tr = 'Sayfa %1'"), PageItem.Title);
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure UpdateTaskCardDisplay()
	
	Items.ListOfTaskActionsPerformerString.Visible = DisplayArtist;
	Items.ListOfTaskActionsDate.Visible = Not DisplayLaborIntensity;
	Items.ListOfTaskActionsLaborInput.Visible = DisplayLaborIntensity;
	
	DisplayingTaskCard = Common.CommonSettingsStorageLoad(
		FormKey,
		"DisplayingTaskCard",
		Enums.HowToDisplayReadingPane.Right);
	
	If DisplayingTaskCard = Enums.HowToDisplayReadingPane.Right Then
		
		Items.GroupList.HorizontalStretch = False;
		
		Items.Viewport.Visible = True;
		
		Items.ListOfTaskActionsAuthorAsString.HorizontalStretch = True;
		
		Items.ListOfTaskActionsGroupCenterColumn.Group =
			ColumnsGroup.Vertical;
		
		Items.ListOfTaskActionsGroupPriorityState.Group =
			ColumnsGroup.Vertical;
		
		Items.ListOfTaskActionsTitle.Height = 2;
		
		Items.Move(
			Items.ListOfTaskActionsPriorityImageIndex,
			Items.ListOfTaskActionsGroupSecondLine);
		Items.Move(
			Items.ListOfTaskActionsIndexOfStateImage,
			Items.ListOfTaskActionsGroupSecondLine);
		
		Items.Move(
			Items.ListOfTaskActionsThereAreSubtasks,
			Items.ListOfTaskActionsGroupSecondLine);
		Items.Move(
			Items.ListOfTaskActionsIndexOfControlImage,
			Items.ListOfTaskActionsGroupSecondLine);
		Items.Move(
			Items.ListOfTaskActionsIndexOfFlagImage,
			Items.ListOfTaskActionsGroupSecondLine);
		
		Items.Move(
			Items.ListOfTaskActionsAuthorAsString,
			Items.ListOfTaskActionsGroupThirdRow,
			Items.ListOfTaskActionsIsBlankString);
		Items.Move(
			Items.ListOfTaskActionsPerformerString,
			Items.ListOfTaskActionsGroupThirdRow,
			Items.ListOfTaskActionsIsBlankString);
		
		Items.ListOfTaskActionsIsBlankString.Visible = True;
		
	Else
		
		Items.GroupList.HorizontalStretch = True;
		
		Items.Viewport.Visible = False;
		
		Items.ListOfTaskActionsAuthorAsString.HorizontalStretch = False;
		
		Items.ListOfTaskActionsGroupCenterColumn.Group =
			ColumnsGroup.Horizontal;
		
		Items.ListOfTaskActionsGroupPriorityState.Group =
			ColumnsGroup.Horizontal;
		
		Items.ListOfTaskActionsTitle.Height = 1;
		
		Items.Move(
			Items.ListOfTaskActionsPriorityImageIndex,
			Items.ListOfTaskActionsGroupPriorityState);
		Items.Move(
			Items.ListOfTaskActionsIndexOfStateImage,
			Items.ListOfTaskActionsGroupPriorityState);
		
		Items.Move(
			Items.ListOfTaskActionsThereAreSubtasks,
			Items.ListOfTaskActions);
		Items.Move(
			Items.ListOfTaskActionsIndexOfControlImage,
			Items.ListOfTaskActions);
		Items.Move(
			Items.ListOfTaskActionsIndexOfFlagImage,
			Items.ListOfTaskActions);
		
		Items.Move(
			Items.ListOfTaskActionsAuthorAsString,
			Items.ListOfTaskActionsGroupSecondLine,
			Items.ListOfTaskActionsLaborInput);
		Items.Move(
			Items.ListOfTaskActionsPerformerString,
			Items.ListOfTaskActionsGroupSecondLine,
			Items.ListOfTaskActionsLaborInput);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateQuickSearchParameters(SettingsOf1CDocumentManagement, ReUpdateIsRequired)
	
	// Setting up quick search.
	QuickSearch.Clear();
	
	NewQuickSearchBar("State", NStr("vi = 'Trạng thái:';
									|ru = 'Состояние:';
									|en = 'State:'; fa = 'وضعیت:';
									|it = 'Состояние:';
									|pl = 'State:';
									|tr = 'Durum:'"), "String;ValueList");
	NewQuickSearchBar("Author", NStr("vi = 'Tác giả:';
									|ru = 'Автор:';
									|en = 'Author:'; fa = 'ایجادکننده:';
									|it = 'Автор:';
									|pl = 'Author:';
									|tr = 'Oluşturan:'"), "DMEmployee");
	If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("3.0.16.30") Then
		NewQuickSearchBar(
			"ApplicationKind", NStr("vi = 'Ứng dụng:';
									|ru = 'Приложение:';
									|en = 'Application:'; fa = 'Application:';
									|it = 'Приложение:';
									|pl = 'Application:';
									|tr = 'Uygulama:'"), "DMDocumentType;DMMeetingType;DMProjectType");
	EndIf;
	NewQuickSearchBar("ActionKind", NStr("vi = 'Dạng nhiệm vụ:';
										|ru = 'Вид задачи:';
										|en = 'Task kind:'; fa = 'Task kind:';
										|it = 'Вид задачи:';
										|pl = 'Task kind:';
										|tr = 'Görev türü:'"), "DMTaskActionType");
	NewQuickSearchBar("DateFrom1", NStr("vi = 'Ngày từ:';
										|ru = 'Дата с:';
										|en = 'Date from:'; fa = 'Date from:';
										|it = 'Дата с:';
										|pl = 'Date from:';
										|tr = 'Tarih başlangıcı:'"), "Date", Date(1,1,1), NStr("vi = 'Ngày';
																						|ru = 'Дата';
																						|en = 'Date'; fa = 'تاریخ';
																						|it = 'Дата';
																						|pl = 'Date';
																						|tr = 'Tarih'") + "1");
	NewQuickSearchBar("DateTo", NStr("vi = 'Ngày đến:';
									|ru = 'Дата по:';
									|en = 'Date to:'; fa = 'Date to:';
									|it = 'Дата по:';
									|pl = 'Date to:';
									|tr = 'Tarih bitişi:'"), "Date", Date(1,1,1), NStr("vi = 'Ngày';
																					|ru = 'Дата';
																					|en = 'Date'; fa = 'تاریخ';
																					|it = 'Дата';
																					|pl = 'Date';
																					|tr = 'Tarih'") + "2");
	NewQuickSearchBar("Performer", NStr("vi = 'Người thực hiện:';
										|ru = 'Исполнитель:';
										|en = 'Assignee:'; fa = 'مجری:';
										|it = 'Исполнитель:';
										|pl = 'Assignee:';
										|tr = 'Atanan:'"), "DMEmployee;DMCompleteRole");
	NewQuickSearchBar("Project", NStr("vi = 'Dự án:';
										|ru = 'Проект:';
										|en = 'Project:'; fa = 'Project:';
										|it = 'Проект:';
										|pl = 'Project:';
										|tr = 'Proje:'"), "DMProject");
	NewQuickSearchBar("Flag", NStr("vi = 'Cờ:';
									|ru = 'Флаг:';
									|en = 'Checkbox:'; fa = 'Checkbox:';
									|it = 'Флаг:';
									|pl = 'Checkbox:';
									|tr = 'Bayrak:'"), "String");
	
	QuickSearch.Sort("Sort");
	
	// Quick search selection lists.
	QuickSearchChoiceLists = New Structure;
	QuickSearchChoiceLists.Insert("State", StateSelectionList());
	QuickSearchChoiceLists.Insert("Flag", FlagSelectionList());
	QuickSearchChoiceLists.Insert("ActionKind", ListOfSelectedTypesOfActions());
	QuickSearchChoiceLists.Insert("Performer", PerformersChoiceList(SettingsOf1CDocumentManagement));
	
	// Previous quick search values.
	Filter_Settings = Common.CommonSettingsStorageLoad(
		FormKey,
		"QuickTaskSearchForMe",
		New Array);
	
	For Each Item In Filter_Settings Do
		
		If Not ValueIsFilled(Item.Value) Or TypeOf(Item) <> Type("Structure") Then
			Continue;
		EndIf;
		
		ChoiceList = Undefined;
		QuickSearchChoiceLists.Property(Item.Parameter, ChoiceList);
		If ChoiceList <> Undefined Then
			If TypeOf(Item.Value) = Type("ValueList") Then
				ValueIsOutdated = False;
				For Each ListItem In Item.Value Do
					If FilterValueIsOutdated(ChoiceList, ListItem.Value) Then
						ValueIsOutdated = True;
						Break;
					EndIf;
				EndDo;
				If ValueIsOutdated Then
					ReUpdateIsRequired = True;
					Continue;
				EndIf;
			Else
				ValueIsOutdated = FilterValueIsOutdated(
					ChoiceList,
					Item.Value,
					Item.ValueID,
					Item.ValueType);
				If ValueIsOutdated Then
					ReUpdateIsRequired = True;
					Continue;
				EndIf;
			EndIf;
		EndIf;
		
		For Each String In QuickSearch Do
			
			If String.Fixed Then
				Continue;
			EndIf;
			
			If String.Parameter = Item.Parameter Then
				FillPropertyValues(String, Item);
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure UpdateQuickSearchPresentation()
	
	PresentationOfFilter = "";
	PresentationOfFilter = IntegrationWith1CDocumentManagement3.UpdateQuickSearchPresentation(
		QuickSearch,
		Items.ResetFilter);
	
	ThereIsQuickSearch = (String(PresentationOfFilter) <> "");
	
	If ThereIsQuickSearch Then
		Items.FormQuickSearch.Visible = False;
		Items.FilterPanelGroup.Visible = True;
		Items.PresentationOfFilter.ToolTip = PresentationOfFilter;
	Else
		Items.FormQuickSearch.Visible = True;
		Items.FilterPanelGroup.Visible = False;
	EndIf;
	
	UpdateWidthOfFormElements();
	
EndProcedure

&AtServer
Function UpdateAppByID(Val ApplicationID, AppUpdateOptions, FoundIssueLines = Undefined,
		OnlyBasicSubjects = False)
	
	UpdateComplete = False;
	
	For Each String In ListOfTaskActions Do
		
		AdditionalInformationOnIssue = GetFromTempStorage(String.AdditionalDataAddress);
		
		If AdditionalInformationOnIssue = Undefined Then
			Continue;
		EndIf;
		
		FoundRows = AllApplicationsInValueTree(
			AdditionalInformationOnIssue.ApplicationTree.Rows,
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
				
				PutToTempStorage(
					AdditionalInformationOnIssue,
					String.AdditionalDataAddress);
			EndIf;
			
			If AppUpdateOptions.ReadingAttributes <> Undefined Then
				FillPropertyValues(AppUpdateOptions.ReadingAttributes, FoundRow);
			EndIf;
			
			If AppUpdateOptions.CurrentRow <> Undefined Then
				CurrentData = ListOfTaskActions.FindByID(AppUpdateOptions.CurrentRow);
				If CurrentData <> Undefined
						And CurrentData.TaskActionID = String.TaskActionID
						And CurrentData.TaskActionType = String.TaskActionType Then
					ValueToFormAttribute(AdditionalInformationOnIssue.ApplicationTree, "ApplicationTree");
				EndIf;
			EndIf;
			
			If FoundIssueLines <> Undefined Then
				FoundIssueLines.Add(String.GetID());
			EndIf;
			
			UpdateComplete = True;
			
		EndDo;
		
	EndDo;
	
	Return UpdateComplete;
	
EndFunction

&AtServer
Procedure RefreshTasksListOnServer(XDTOTasks, CurCurrentUserAndEmployees)
	
	ListOfTaskActions.Clear();
	
	For Each XDTOTask In XDTOTasks Do
		
		NewRow = ListOfTaskActions.Add();
		NewRow.TaskActionID = XDTOTask.objectID.id;
		NewRow.TaskActionType = XDTOTask.objectID.type;
		NewRow.URL = XDTOTask.objectID.navigationRef;
		
		MainSubject = IntegrationWith1CDocumentManagement3.MainSubjectOfTask(XDTOTask);
		NewRow.MainSubjectID = MainSubject.ID;
		NewRow.MainSubjectType = MainSubject.Type;
		
		NewRow.Title = XDTOTask.title;
		DescriptionOfReceivedUpdates = XDTOTask.descriptionOfReceivedUpdates;
		If ValueIsFilled(DescriptionOfReceivedUpdates) Then
			If DisplayingTaskCard = Enums.HowToDisplayReadingPane.Right Then
				NewRow.Title = NewRow.Title + Chars.LF + DescriptionOfReceivedUpdates;
			Else
				NewRow.Title = NewRow.Title + ", " + DescriptionOfReceivedUpdates;
			EndIf;
		EndIf;
		
		If Lower(XDTOTask.priority) = "high" Then
			NewRow.PriorityImageIndex = 2;
			
		ElsIf Lower(XDTOTask.priority) = "normal" Then
			NewRow.PriorityImageIndex = 1;
			
		ElsIf Lower(XDTOTask.priority) = "low" Then
			NewRow.PriorityImageIndex = 0;
			
		Else
			NewRow.PriorityImageIndex = -1;
			
		EndIf;
		
		NewRow.IndexOfControlImage = XDTOTask.monitoringState;
		NewRow.IndexOfStateImage = XDTOTask.actionState;
		FlagData = IntegrationWith1CDocumentManagement3.FlagData(XDTOTask.flag);
		NewRow.IndexOfFlagImage = FlagData.PictureIndex;
		
		NewRow.AuthorAsString = XDTOTask.authorPresentation;
		NewRow.PerformerString = XDTOTask.performerPresentation;
		
		If ValueIsFilled(XDTOTask.laboriousnessFrom) And ValueIsFilled(XDTOTask.laboriousnessUpTo) Then
			NewRow.LaborInput = StrTemplate(
				"%1-%2",
				XDTOTask.laboriousnessFrom,
				XDTOTask.laboriousnessUpTo);
				
		ElsIf ValueIsFilled(XDTOTask.laboriousnessFrom) Then
			NewRow.LaborInput = String(XDTOTask.laboriousnessFrom);
			
		Else
			NewRow.LaborInput = "              ";
			
		EndIf;
		
		NewRow.Date = XDTOTask.date;
		NewRow.DueDate = XDTOTask.term;
		NewRow.ThereAreSubtasks = XDTOTask.existSubtasks;
		NewRow.New = XDTOTask.new;
		NewRow.Overdue = XDTOTask.isOverdue;
		NewRow.PresentationHTML = XDTOTask.htmlView;
		
		AdditionalInformationOnIssue = IntegrationWith1CDocumentManagement3.AdditionalInformationOnIssue(
			XDTOTask,
			CurCurrentUserAndEmployees);
		NewRow.AdditionalDataAddress = PutToTempStorage(
			AdditionalInformationOnIssue,
			UUID);
		
		ThereIsAlreadyConnection = False;
		If AdditionalInformationOnIssue <> Undefined Then
			For Each ApplicationTreeLine In AdditionalInformationOnIssue.ApplicationTree.Rows Do
				If ValueIsFilled(ApplicationTreeLine.Ref) Then
					ThereIsAlreadyConnection = True;
					Break;
				EndIf;
			EndDo;
		EndIf;
		If ThereIsAlreadyConnection Then
			Continue;
		EndIf;
		
		// To build a list of creation commands based on an array of integration rules suitable for the task,
		// we also fill in the data ID and type of the main subject of the task.
		SuitableObjects = IntegrationWith1CDocumentManagement3.SuitableObjectsToCreateBasedOnTask(
			XDTOTask,
			AdditionalInformationOnIssue.ApplicationTree.Rows,
			NewRow.MainSubjectID,
			NewRow.MainSubjectType);
		NewRow.SuitableObjects = PutToTempStorage(SuitableObjects, UUID);
		
		If SuitableObjects.Count() > 0 Then
			// Each unique combination of rules corresponds to its own group of creation commands based on.
			// For optimization, if the appropriate rules match for different tasks, we will not create
			// a new group of teams on the form, but will use the previously created group.
			// The matching of the name of the page to a certain combination of suitable rules is stored in temporary
			// storage at the address of the pagecommandation.
			MatchingPages = GetFromTempStorage(PagesOfCreationCommandsBasedOn);
			PageMatchingKey = ValueToStringInternal(SuitableObjects);
			NewRow.KeyOfCreationCommandsPageBasedOn = MatchingPages[PageMatchingKey];
			If Not ValueIsFilled(NewRow.KeyOfCreationCommandsPageBasedOn) Then
				NewRow.KeyOfCreationCommandsPageBasedOn =
					IntegrationWith1CDocumentManagement3.NewPageOfCommandsToCreateBasedOnTask(
						ThisObject,
						SuitableObjects);
				MatchingPages[PageMatchingKey] = NewRow.KeyOfCreationCommandsPageBasedOn;
				PutToTempStorage(MatchingPages, PagesOfCreationCommandsBasedOn);
			EndIf;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure UpdateWidthOfFormElements()
	
	CommandPanelBasicCommandsWidth = 42;
	ShiftTakeToWork = 12;
	ShiftFormQuickSearch = 8;
	ShiftAddMembers = 8;
	ShiftRedirect = 4;
	
	Items.CommandPanelBasicCommands.Width = 42;
	If Not Items.TakeToWork.Visible Then
		CommandPanelBasicCommandsWidth = CommandPanelBasicCommandsWidth - ShiftTakeToWork;
	EndIf;
	If Not Items.FormQuickSearch.Visible Then
		CommandPanelBasicCommandsWidth = CommandPanelBasicCommandsWidth - ShiftFormQuickSearch;
	EndIf;
	If Not Items.AddParticipants.Visible Then
		CommandPanelBasicCommandsWidth = CommandPanelBasicCommandsWidth - ShiftAddMembers;
	EndIf;
	If Not Items.Forward.Visible Then
		CommandPanelBasicCommandsWidth = CommandPanelBasicCommandsWidth - ShiftRedirect;
	EndIf;
	Items.CommandPanelBasicCommands.Width = CommandPanelBasicCommandsWidth;
	
EndProcedure

&AtServer
Procedure HandleException(ErrorInfo)
	
	Items.ConnectionPageGroup.CurrentPage = Items.PageUpdateError;
	TextOfUpdateError = ErrorProcessing.BriefErrorDescription(ErrorInfo);
	If IntegrationWith1CDocumentManagementCoreServerCall.NeedToProcessForm(ErrorInfo) Then
		ProcessFormAccordingToServiceVersion();
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessWebServiceSResponseToReceivingListOfIssues(ResponseTaskList, SettingsOf1CDocumentManagement)
	
	TotalPages = ResponseTaskList.pageCount;
	
	If ResponseTaskList.descriptionOfTotals <> "" Then
		OldTitle = Items.ListOfTaskActionsTitle.Title;
		BeginningOfAddOn = StrFind(OldTitle, "(");
		If BeginningOfAddOn > 0 Then
			OldTitle = TrimAll(Left(OldTitle, BeginningOfAddOn - 1));
		EndIf;
		
		Items.ListOfTaskActionsTitle.Title = StrTemplate("%1 (%2)",
			OldTitle,
			ResponseTaskList.descriptionOfTotals)
	EndIf;
	
	If SettingsOf1CDocumentManagement.TasksAreAvailableToMe Then
		Items.ThereArePagesNoData.CurrentPage = Items.PageHasData;
	Else
		Items.ThereArePagesNoData.CurrentPage = Items.PageNoData;
		Return;
	EndIf;
	
	TitleOfMessageInPreviewArea = SettingsOf1CDocumentManagement.TitleOfMessageInPreviewArea;
	AddWorkToDailyReportWhenCompletingTask =
		SettingsOf1CDocumentManagement.AddWorkToDailyReportWhenCompletingTask;
	ActualTaskExecutor = SettingsOf1CDocumentManagement.ActualTaskExecutor;
	If ActualTaskExecutor <> "taskPerformer" Then
		CurCurrentUserAndEmployees =
			IntegrationWith1CDocumentManagementCoreCached.Current1CDocumentManagementUser();
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			ThisObject,
			CurCurrentUserAndEmployees[0],
			"CurrentUser");
	EndIf;
	
	RefreshTasksListOnServer(ResponseTaskList.objects, CurCurrentUserAndEmployees);
	UpdateDynamicListButtons();
	
EndProcedure

&AtServer
Procedure DisplayAdditionalData(Val AdditionalDataAddress, Val SavedComment)
	
	AdditionalInformationOnIssue = GetFromTempStorage(AdditionalDataAddress);
	
	If AdditionalInformationOnIssue = Undefined Then
		Items.ThereAreOneTaskPagesAndSeveralPagesThatAreMissing.CurrentPage = Items.ErrorPage;
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagement3.UpdateTaskScope(
		ThisObject,
		AdditionalInformationOnIssue.Scope,
		SavedComment);
	
	UpdateWidthOfFormElements();
	
	ValueToFormAttribute(AdditionalInformationOnIssue.ApplicationTree, "ApplicationTree");
	
EndProcedure

&AtServer
Function AppUpdateOptions(Val ApplicationType = Undefined)
	
	ParametersOfUpdate = New Structure;
	ParametersOfUpdate.Insert("ApplicationType", ApplicationType);
	ParametersOfUpdate.Insert("AttributesForUpdate", Undefined);
	ParametersOfUpdate.Insert("CurrentRow", Undefined);
	ParametersOfUpdate.Insert("ReadingAttributes", Undefined);
	
	ASBS = New Structure;
	IntegrationWith1CDocumentManagementCoreClientServer.AddPersonalData(ASBS);
	ParametersOfUpdate.Insert("ASBS", ASBS);
	
	Return ParametersOfUpdate;
	
EndFunction

&AtServer
Procedure ResetSelectionOnServer()
	
	IntegrationWith1CDocumentManagement3.ResetQuickSearch(QuickSearch, Items.ResetFilter);
	
	UpdateQuickSearchPresentation();
	
EndProcedure

&AtServer
Function ListOfSelectedTypesOfActions()
	
	ListOfSelectedTypesOfActions = New ValueList;
	For Each String In ListOfActionKinds Do
		Value = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
			String.ActionKindID,
			String.ActionKindType,
			String.ActionKind);
		ListOfSelectedTypesOfActions.Add(Value, Value.Description);
	EndDo;
	
	Return ListOfSelectedTypesOfActions;
	
EndFunction

&AtServer
Function PerformersChoiceList(SettingsOf1CDocumentManagement)
	
	PerformersChoiceList = New ValueList;
	For Each TaskExecutor In SettingsOf1CDocumentManagement.ListOfTaskExecutors Do
		PerformersChoiceList.Add(TaskExecutor, TaskExecutor.Description);
	EndDo;
	
	Return PerformersChoiceList;
	
EndFunction

&AtServer
Function StateSelectionList()
	
	StateSelectionList = New ValueList;
	
	// selections based on the Status of issues.
	Value = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
		"NotCompleted",
		"DMTaskStatusFilter",
		NStr("vi = 'Chưa thực hiện';
			|ru = 'Не выполненные';
			|en = 'Active tasks'; fa = 'وظایف فعال';
			|it = 'Non eseguiti';
			|pl = 'Nie wykonane';
			|tr = 'Gerçekleştirilmeyenler'"));
	StateSelectionList.Add(Value, Value.Description);
	Value = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
		"NotStarted",
		"DMTaskStatusFilter",
		NStr("vi = 'Chưa bắt đầu';
			|ru = 'Не начатые';
			|en = 'Not started'; fa = 'شروع‌نشده';
			|it = 'Не начатые';
			|pl = 'Not started';
			|tr = 'Başlatılmayanlar'"));
	StateSelectionList.Add(
		Value,
		New FormattedString(
			Value.Description,
			StyleFonts.FontTasksNotReceivedForExecution));
	Value = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
		"Overdue",
		"DMTaskStatusFilter",
		NStr("vi = 'Đã quá hạn';
			|ru = 'Просроченные';
			|en = 'Overdue'; fa = 'سررسیدگذشته';
			|it = 'Просроченные';
			|pl = 'Overdue';
			|tr = 'Vadesi geçenler'"));
	StateSelectionList.Add(
		Value,
		New FormattedString(
			Value.Description,,
			StyleColors.OverdueDataColor));
	
	// task States.
	Value = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
		"New",
		"DMTaskStatus",
		NStr("vi = 'Mới';
			|ru = 'Новая';
			|en = 'New'; fa = 'جدید';
			|it = 'Новая';
			|pl = 'New';
			|tr = 'Yeni'"));
	StateSelectionList.Add(Value, Value.Description);
	Value = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
		"InWork",
		"DMTaskStatus",
		NStr("vi = 'Đang làm việc';
			|ru = 'В работе';
			|en = 'In progress'; fa = 'در حال انجام';
			|it = 'In esecuzione';
			|pl = 'Wykonuje się';
			|tr = 'İşleniyor'"));
	StateSelectionList.Add(Value, Value.Description);
	
	StateSelectionList.Add(NStr("vi = 'Chọn nhiều...';
								|ru = 'Выбрать несколько...';
								|en = 'Select several items...'; fa = 'Select several items...';
								|it = 'Выбрать несколько...';
								|pl = 'Select several items...';
								|tr = 'Birden fazla seç...'"));
	
	Return StateSelectionList;
	
EndFunction

&AtServer
Function FlagSelectionList()
	
	FlagSelectionList = New ValueList;
	AddFlagToSelectionList("Red", FlagSelectionList);
	AddFlagToSelectionList("Blue", FlagSelectionList);
	AddFlagToSelectionList("Yellow", FlagSelectionList);
	AddFlagToSelectionList("Green", FlagSelectionList);
	AddFlagToSelectionList("Orange", FlagSelectionList);
	AddFlagToSelectionList("Purple", FlagSelectionList);
	
	Return FlagSelectionList;
	
EndFunction

&AtServer
Function ListOfIssuesRequest(Proxy)
	
	DisplayFilters = DisplayFilters(Search);
	
	If QuickSearch.Count() = 0 Then
		// When you first open the form, "Quick Search" has not yet been defined.
		// Let's take the stored value of the previous "Quick Search", if there is one.
		CurrentQuickSearch = Common.CommonSettingsStorageLoad(
			FormKey,
			"QuickTaskSearchForMe",
			New Array);
	Else
		CurrentQuickSearch = QuickSearch.Unload();
	EndIf;
	
	IntegrationWith1CDocumentManagement3.AddTaskSelectionFilters(Proxy, DisplayFilters, CurrentQuickSearch);
	
	Return IntegrationWith1CDocumentManagement3.ListOfIssuesRequest(
		Proxy,
		CurrentPage,
		DynamicListPageSize,
		PossibleFieldsForSorting()[SortingField],
		FieldSortingDirection,
		DisplayFilters,
		DisplayingTaskCard);
	
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
		UpdateForm(False, True);
#If Not WebClient Then
		If AutoRefresh Then
			AttachIdleHandler("AutoRefresh", AutoRefreshPeriod * 60);
		EndIf;
#EndIf
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
			
		Else
			
			Items.ConnectionPageGroup.CurrentPage = Items.VersionPageIsNotSupported;
			FormProcessedSuccessfully = False;
			
		EndIf;
		
		SettingsOf1CDocumentManagement = IntegrationWith1CDocumentManagementCoreCached.GetSettings();
		ShowPDFUsing1C = SettingsOf1CDocumentManagement.ShowPDFUsing1C;
		If ShowPDFUsing1C Then
			IntegrationWith1CDocumentManagement3.OutputPDFDocumentToForm(ThisObject, "PDFGroup");
		EndIf;
		
		Items.Forward.Visible = SettingsOf1CDocumentManagement.UseTaskRedirection;
		
	Except
		HandleException(ErrorInfo());
	EndTry;
	
	Return FormProcessedSuccessfully;
	
EndFunction

#EndRegion

#Region UpdateForm

&AtClient
Procedure UpdateForm(OutputIdleWindow = True, HideInterface = False, LinesOfNewFiles = Undefined)
	
	Measurement = Undefined;
	If CommonClient.SubsystemExists("StandardSubsystems.PerformanceMonitor") Then
		ModulePerformanceMonitorClient = CommonClient.CommonModule("PerformanceMonitorClient");
		Measurement = ModulePerformanceMonitorClient.StartTimeConsumingOperationMeasurement(
			"GettingListOfTasksFromWorkflow");
	EndIf;
	
	UpdateImageOfArrangeCommand();
	
	If Not OutputIdleWindow And Not HideInterface Then
		SetAccessibilityOfControls(False);
	EndIf;
	
	TimeConsumingOperation = StartUpdateAtServer();
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("LinesOfNewFiles", LinesOfNewFiles);
	NotificationParameters.Insert("Measurement", Measurement);
	NotificationParameters.Insert("BeginTime", CurrentUniversalDateInMilliseconds());
	CallbackOnCompletion = New CallbackDescription("UpdateFormCompletion", ThisObject, NotificationParameters);
	
	IntegrationWith1CDocumentManagementCoreClient.ExecuteRequestAsynchronously(
		ThisObject,
		TimeConsumingOperation,
		CallbackOnCompletion,
		OutputIdleWindow,
		NStr("vi = 'Nhận danh sách nhiệm vụ.';
			|ru = 'Получение списка задач.';
			|en = 'Get a task list.'; fa = 'Get a task list.';
			|it = 'Получение списка задач.';
			|pl = 'Get a task list.';
			|tr = 'Görev listesi alma.'"),
		HideInterface);
	
EndProcedure

&AtServer
Function StartUpdateAtServer()
	
	Try
		
		Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
		
		PackageQueries = New Array;
		
		PackageQueries.Add(ListOfIssuesRequest(Proxy));
		
		If SessionParameters.IntegrationWith1CDocumentManagementSettings = "" Then
			PackageQueries.Add(IntegrationWith1CDocumentManagementCore.GetRequestSettings(Proxy));
		EndIf;
		
		If SessionParameters.IntegrationWith1CDocumentManagementCurrentUser = "" Then
			PackageQueries.Add(
				IntegrationWith1CDocumentManagementCore.CurCurrentWorkflowUserRequest(Proxy));
		EndIf;
		
		If ListOfActionKinds.Count() = 0 Then
			PackageQueries.Add(
				IntegrationWith1CDocumentManagementCore.FindListOfObjectsRequest(Proxy, "DMTaskActionType"));
		EndIf;
		
		Return IntegrationWith1CDocumentManagementCore.ExecuteBatchRequestAsynchronously(
			Proxy,
			PackageQueries,
			UUID,
			NStr("vi = 'Nhận danh sách nhiệm vụ';
				|ru = 'Получение списка задач';
				|en = 'Get a task list'; fa = 'Get a task list';
				|it = 'Получение списка задач';
				|pl = 'Get a task list';
				|tr = 'Görev listesi alma'"),
			True);
		
	Except
		HandleException(ErrorInfo());
	EndTry;
	
EndFunction

&AtClient
Procedure UpdateFormCompletion(Result, NotificationParameters) Export
	
	If Not Items.ThereArePagesNoData.Enabled Then
		SetAccessibilityOfControls(True);
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
		Items.ListOfTaskActionsTitle.Title = NStr("vi = 'Nhiệm vụ';
													|ru = 'Задачи';
													|en = 'Tasks'; fa = 'وظایف';
													|it = 'Задачи';
													|pl = 'Tasks';
													|tr = 'Görevler'");
		IntegrationWith1CDocumentManagement3Client.UpdateSortingInCellHeader(
			ThisObject,
			SortingField,
			FieldSortingDirection);
		ReUpdateIsRequired = False;
		ServerUpdateEnd(Result.ResultLongOperation, ReUpdateIsRequired);
		RestorePositionInList();
		DisplayDataOnCurTask(NotificationParameters.LinesOfNewFiles);
		If ReUpdateIsRequired Then
			// If, when opening the form for the first time, a selection was set based on non-current values
			// of the "Quick Search" table, we will save the current values and perform a re-update.
			SaveQuickSearch();
			UpdateForm();
		EndIf;
		IsInitialized = True;
		UpdateAutoDynamicListPageSize(NotificationParameters.BeginTime);
		If NotificationParameters.Measurement <> Undefined Then
			ModulePerformanceMonitorClient = CommonClient.CommonModule("PerformanceMonitorClient");
			ModulePerformanceMonitorClient.EndTimeConsumingOperationMeasurement(
				NotificationParameters.Measurement,
				ListOfTaskActions.Count());
		EndIf;
	ElsIf ProcessAForm Then
		ProcessFormAccordingToServiceVersion();
	EndIf;
	
EndProcedure

&AtServer
Procedure ServerUpdateEnd(Val ResponseToPackageRequestsString, ReUpdateIsRequired)
	
	Try
		Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
		ResponseToPackageRequests = IntegrationWith1CDocumentManagementCore.StringInXDTOObject(
			Proxy,
			ResponseToPackageRequestsString);
	Except
		Items.ConnectionPageGroup.CurrentPage = Items.Page1CDocumentManagementIsUnavailable;
		Raise;
	EndTry;
	
	For QueryNumber = 1 To ResponseToPackageRequests.responses.Count() - 1 Do
		Response = ResponseToPackageRequests.responses[QueryNumber];
		If IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, Response, "DMGetSettingsResponse") Then
			SessionParameters.IntegrationWith1CDocumentManagementSettings =
				IntegrationWith1CDocumentManagementCore.XDTOObjectInString(Proxy, Response);
			
		ElsIf IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, Response, "DMGetCurrentUserResponse") Then
			SessionParameters.IntegrationWith1CDocumentManagementCurrentUser =
				IntegrationWith1CDocumentManagementCore.XDTOObjectInString(Proxy, Response);
			Title = StrTemplate(NStr("vi = 'Document Management: Nhiệm vụ đến (%1)';
									|ru = 'Документооборот: Задачи мне (%1)';
									|en = 'Document Management: My tasks (%1)'; fa = 'Document Management: My tasks (%1)';
									|it = 'Документооборот: Задачи мне (%1)';
									|pl = 'Document Management: My tasks (%1)';
									|tr = 'İş akışı: Benim için görevler (%1)'"), Response.user.name);
			
		ElsIf IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, Response, "DMGetObjectListResponse")
				And ListOfActionKinds.Count() = 0 Then
			For Each XDTODataObject In Response.items Do
				If XDTODataObject.object.objectID.type <> "DMTaskActionType" Then
					Continue;
				EndIf;
				NewRow = ListOfActionKinds.Add();
				NewRow.ActionKind = XDTODataObject.object.name;
				NewRow.ActionKindID = XDTODataObject.object.objectID.id;
				NewRow.ActionKindType = "DMTaskActionType";
			EndDo;
			ListOfActionKinds.Sort("ActionKind");
			
		EndIf;
	EndDo;
	
	SettingsOf1CDocumentManagement = IntegrationWith1CDocumentManagementCoreCached.GetSettings();
	
	ResponseTaskList = ResponseToPackageRequests.responses[0];
	ProcessWebServiceSResponseToReceivingListOfIssues(ResponseTaskList, SettingsOf1CDocumentManagement);
	
	UpdateQuickSearchParameters(SettingsOf1CDocumentManagement, ReUpdateIsRequired);
	UpdateQuickSearchPresentation();

	If Items.ConnectionPageGroup.CurrentPage = Items.PageUpdateError Then
		Items.ConnectionPageGroup.CurrentPage = Items.Page1CDocumentManagementIsAvailable;
	EndIf;
	
EndProcedure

#EndRegion

#Region ActionOnTask

&AtClient
Procedure ActionOnTask(OperationType, TaskActionParameters = Undefined) Export
	
	If TaskActionParameters = Undefined Then
		TaskActionParameters = TaskActionParameters();
	EndIf;
	
	CurrentData = ListOfTaskActionsCurrentData();
	If CurrentData = Undefined Then
		Return;
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
		CurrentData.TaskActionID,
		CurrentData.TaskActionType,
		CurrentData.Title,
		TaskActionParameters.OperationParametersList);
	DataByTask.RequiredInteractiveAction = TaskActionParameters.RequiredInteractiveAction;
	
	TaskListFormParameters = IntegrationWith1CDocumentManagement3ClientServer.TaskListFormParameters();
	TaskListFormParameters.CurrentPage = CurrentPage;
	TaskListFormParameters.DynamicListPageSize = DynamicListPageSize;
	TaskListFormParameters.SortingField = PossibleFieldsForSorting()[SortingField];
	TaskListFormParameters.FieldSortingDirection = FieldSortingDirection;
	TaskListFormParameters.DisplayingTaskCard = DisplayingTaskCard;
	TaskListFormParameters.DisplayFilters = DisplayFilters(Search);
	TaskListFormParameters.QuickSearch = QuickSearch;
	
	Try
		LongTermOperationOnTask = IntegrationWith1CDocumentManagement3ServerCall.LongTermOperationOnTask(
			OperationType,
			DataByTask,
			UUID,
			TaskActionParameters.DataUpdateRequired,
			True,
			TaskListFormParameters);
	Except
		ErrorInfo = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		If IntegrationWith1CDocumentManagementCoreServerCall.NeedToProcessForm(ErrorInfo) Then
			ProcessFormAccordingToServiceVersion();
		EndIf;
	EndTry;
	
	NotificationParameters = New Structure("ID, Type, OperationType",
		CurrentData.TaskActionID,
		CurrentData.TaskActionType,
		OperationType);
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
		Items.ListOfTaskActionsTitle.Title = NStr("vi = 'Nhiệm vụ';
													|ru = 'Задачи';
													|en = 'Tasks'; fa = 'وظایف';
													|it = 'Задачи';
													|pl = 'Tasks';
													|tr = 'Görevler'");
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
			RestorePositionInList();
			DisplayDataOnCurTask();
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
			SettingsOf1CDocumentManagement = IntegrationWith1CDocumentManagementCoreCached.GetSettings();
			ProcessWebServiceSResponseToReceivingListOfIssues(DataForUpdate, SettingsOf1CDocumentManagement);
		EndIf;
	EndIf;
	
	Return ActionResult;
	
EndFunction

#EndRegion

#EndRegion