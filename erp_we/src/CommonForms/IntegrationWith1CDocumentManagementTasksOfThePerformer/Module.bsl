#Region Variables

&AtClient
Var NumberOfActivatedLine;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCore.WhenCreatingFormsHostedOnDesktopOnServer(Cancel);
	If Cancel Then
		Return;
	EndIf;
	
	AutoRefresh = Common.CommonSettingsStorageLoad(
		"IntegrationWith1CDocumentManagement", "AutoRefresh", True);
	AutoRefreshPeriod = Common.CommonSettingsStorageLoad(
		"IntegrationWith1CDocumentManagement", "AutoRefreshPeriod", 900);
	
	Items.GroupPages.Enabled = False;
	Items.FooterGroup.Enabled = False;
	Items.AutoRefresh.Enabled = False;
	
	SetTaskAppearance(ConditionalAppearance);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "IntegrationWith1CDocumentManagement_SuccessfulConnection" And Source <> ThisObject Then
		WhenConnecting();
	EndIf;
	
	If EventName = "Recording_1CDocumentManagementTask" And Source = ThisObject Then
		UpdateTaskListPartially();
		ExpandTaskGroups();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	TestConnection();
	
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
Procedure CompletedOnChange(Item)
	
	Modified = False;
	RefreshTasksListOnServer();
	ExpandTaskGroups();
	
EndProcedure

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	If CurrentPage = Items.TaskGroupFromMe Then
		If Not TasksFromMeAreRead Then
			RefreshTasksListOnServer();
			ExpandTaskGroups();
			TasksFromMeAreRead = True;
		EndIf;
	ElsIf CurrentPage = Items.TaskGroupMe Then
		If Not TasksAreReadToMe Then
			RefreshTasksListOnServer();
			ExpandTaskGroups();
			TasksAreReadToMe = True;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTasksToMe

&AtClient
Procedure TasksToMeOnActivateRow(Item)
	
	If NumberOfActivatedLine <> Item.CurrentRow Then
		
		NumberOfActivatedLine = Item.CurrentRow;
		TaskLine = Items.TasksToMe.CurrentData;
		If TaskLine = Undefined Or TaskLine.Group Then
			Items.AcceptForExecution.Enabled = False;
			Items.TasksToMeContextMenuAcceptForExecution.Enabled = False;
			Items.CancelAcceptForExecution.Enabled = False;
			Items.TasksToMeContextMenuCancelAcceptForExecution.Enabled = False;
		Else
			Items.AcceptForExecution.Enabled = Not TaskLine.AcceptedForExecution;
			Items.TasksToMeContextMenuAcceptForExecution.Enabled = Not TaskLine.AcceptedForExecution;
			Items.CancelAcceptForExecution.Enabled = TaskLine.AcceptedForExecution;
			Items.TasksToMeContextMenuCancelAcceptForExecution.Enabled = TaskLine.AcceptedForExecution;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TasksToMeSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	Task = Items.TasksToMe.CurrentData;
	If Task <> Undefined Then
		If Not Task.Group Then
			FormParameters = New Structure;
			FormParameters.Insert("ID", Task.TaskID);
			FormParameters.Insert("type", Task.TaskType);
			OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.Task",
				FormParameters, ThisObject, Task.TaskID);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure TasksToMeBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)

	Cancel = True;
	
EndProcedure

&AtClient
Procedure TasksToMeBeforeDeleteRow(Item, Cancel)

	Cancel = True;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTasksFromMe
&AtClient
Procedure TasksFromMeSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	Task = Items.TasksFromMe.CurrentData;
	If Task <> Undefined Then
		If Not Task.Group Then
			FormParameters = New Structure;
			FormParameters.Insert("ID", Task.TaskID);
			FormParameters.Insert("type", Task.TaskType);
			OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.Task", FormParameters, ThisObject, Task.TaskID);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure TasksFromMeBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)

	Cancel = True;
	
EndProcedure

&AtClient
Procedure TasksFromMeBeforeDeleteRow(Item, Cancel)

	Cancel = True;
	
EndProcedure

&AtClient
Procedure TasksFromMeBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	
	Task = Items.TasksFromMe.CurrentData;
	If Task <> Undefined Then
		If Not Task.Group Then
			FormParameters = New Structure;
			FormParameters.Insert("ID", Task.TaskID);
			FormParameters.Insert("type", Task.TaskType);
			OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.Task", FormParameters, ThisObject, Task.TaskID);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Refresh(Command)
	
	Modified = False;
	RefreshTasksListOnServer();
	ExpandTaskGroups();
	
EndProcedure

&AtClient
Procedure OpenTask(Command)
	
	Modified = False;
	
	If Items.GroupPages.CurrentPage = Items.TaskGroupMe Then
		CurrentData = Items.TasksToMe.CurrentData;
	Else
		CurrentData = Items.TasksFromMe.CurrentData;
	EndIf;
	
	If CurrentData = Undefined Then
		Return;
	ElsIf CurrentData.Group Then
		Return;
	EndIf;
	
	If Not CurrentData.Group Then
		IntegrationWith1CDocumentManagementCoreClient.OpenObject(
			CurrentData.TaskType,
			CurrentData.TaskID,
			ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenArticle(Command)
	
	Modified = False;
	
	If Items.GroupPages.CurrentPage = Items.TaskGroupMe Then
		CurrentData = Items.TasksToMe.CurrentData;
	Else
		CurrentData = Items.TasksFromMe.CurrentData;
	EndIf;
	
	If CurrentData = Undefined Then
		Return;
	ElsIf CurrentData.Group Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreClient.OpenObject(
		CurrentData.SubjectOfType,
		CurrentData.SubjectOfID,
		ThisObject);

EndProcedure

&AtClient
Procedure OpenProcess(Command)
	
	Modified = False;
	
	If Items.GroupPages.CurrentPage = Items.TaskGroupMe Then
		CurrentData = Items.TasksToMe.CurrentData;
	Else
		CurrentData = Items.TasksFromMe.CurrentData;
	EndIf;
	
	If CurrentData = Undefined Then
		Return;
	ElsIf CurrentData.Group Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreClient.OpenObject(
		CurrentData.Process_Type,
		CurrentData.Process_ID,
		ThisObject);

EndProcedure

&AtClient
Procedure CreateProcess(Command)
	
	Modified = False;
	Notification = New CallbackDescription("CreateProcessCompletion", ThisObject);
	IntegrationWith1CDocumentManagementClient.CreateBusinessProcess(,, Notification);
	
EndProcedure

&AtClient
Procedure CreateEmail(Command)
	
	Modified = False;
	
	If Items.GroupPages.CurrentPage = Items.TaskGroupMe Then
		CurrentData = Items.TasksToMe.CurrentData;
	Else
		CurrentData = Items.TasksFromMe.CurrentData;
	EndIf;
	
	If Not AvailableTaskFunctionalityFromMe Then
		IntegrationWith1CDocumentManagementCoreClient.OpenObject("DMOutgoingEMail","", ThisObject);
	Else
		FormParameters = New Structure("SubjectOf", New Structure);
		
		FormParameters.SubjectOf.Insert("name", CurrentData.Task);
		FormParameters.SubjectOf.Insert("ID", CurrentData.TaskID);
		FormParameters.SubjectOf.Insert("type", CurrentData.TaskType);
		
		OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.Outgoing_Email",FormParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure AcceptForExecution(Command)
	
	AcceptTasksForExecution();
	ExpandTaskGroups();
	
EndProcedure

&AtClient
Procedure CancelAcceptForExecution(Command)
	
	CancelAcceptTasksForExecution();
	ExpandTaskGroups();
	
EndProcedure

&AtClient
Procedure GroupByImportance(Command)
	GroupByColumn("StringImportance");
EndProcedure

&AtClient
Procedure GroupByNoGroup(Command)
	GroupByColumn("");
EndProcedure

&AtClient
Procedure GroupByRoutePoint(Command)
	GroupByColumn("RoutePoint");
EndProcedure

&AtClient
Procedure GroupByAuthor(Command)
	GroupByColumn("Author");
EndProcedure

&AtClient
Procedure GroupBySubject(Command)
	GroupByColumn("SubjectOf");
EndProcedure

&AtClient
Procedure GroupByArtist(Command)
	GroupByColumn("Performer");
EndProcedure

&AtClient
Procedure AskAuthorQuestion(Command)
	
	Modified = False;
	
	If Items.TasksToMe.CurrentData = Undefined Then
		Return;
	ElsIf Items.TasksToMe.CurrentData.Group Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("ID", Items.TasksToMe.CurrentData.TaskID);
	FormParameters.Insert("type", Items.TasksToMe.CurrentData.TaskType);
	FormParameters.Insert("TypeOfQuestion", NStr("vi = 'Khác';
												|ru = 'Иное';
												|en = 'Other'; fa = 'سایر';
												|it = 'Altro';
												|pl = 'Other';
												|tr = 'Diğer'"));
	FormParameters.Insert("TypeOfQuestionID", "Иное"); //@NON-NLS-2
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.BusinessProcessIssueSolvingNewQuestion",
		FormParameters, ThisObject, Items.TasksToMe.CurrentData.TaskID);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure CreateProcessCompletion(Result, NotificationParameters) Export
	
	UpdateTaskListPartially();
	
EndProcedure

&AtClient
Procedure ExpandTaskGroups()
	
	If Items.GroupPages.CurrentPage = Items.TaskGroupMe Then
		Tree = TasksToMe;
		TreeElement_ = Items.TasksToMe;
	Else
		Tree = TasksFromMe;
		TreeElement_ = Items.TasksFromMe;
	EndIf;
	
	TreeItems = Tree.GetItems();
	
	For Each TreeItem In TreeItems Do
		If TreeItem.Group Then
			TreeElement_.Expand(TreeItem.GetID(), False);
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure GroupByColumn(ColumnName)
	
	Modified = False;
	GroupByColumnOnServer(ColumnName);
	ExpandTaskGroups();
	
EndProcedure

&AtServer
Procedure GroupByColumnOnServer(ColumnName)
	
	If Items.GroupPages.CurrentPage = Items.TaskGroupMe Then
		TaskTableLink = TaskTableMeLink;
		TaskListName = "TasksToMe";
		TaskList = TasksToMe;
		TaskGroupingModeForMe = ColumnName;
		GroupingMode = TaskGroupingModeForMe;
	Else
		TaskTableLink = TaskTableFromMeLink;
		TaskListName = "TasksFromMe";
		TaskList = TasksFromMe;
		TaskGroupingModeFromMe = ColumnName;
		GroupingMode = TaskGroupingModeFromMe;
	EndIf;
	
	If Not ValueIsFilled(TaskTableLink) Then
		Return;
	EndIf;
	
	CurrentTask = Items.Find(TaskListName).CurrentRow;
	If CurrentTask <> Undefined Then
		CurTaskLine = TaskList.FindByID(CurrentTask);
		If CurTaskLine = Undefined Then
			CurrentTask = Undefined;
		Else
			CurrentTask = CurTaskLine.TaskID;
		EndIf;
	EndIf;
	
	Tree = FormAttributeToValue(TaskListName); // ValueTree
	
	TaskTable_ = GetFromTempStorage(TaskTableLink); // ValueTable
	
	Tree.Rows.Clear();
	
	If ValueIsFilled(GroupingMode) Then
		DimensionsTable = TaskTable_.Copy();
		DimensionsTable.GroupBy(GroupingMode);
		For Each DimensionString In DimensionsTable Do
			TreeRow = Tree.Rows.Add();
			TreeRow.Task = DimensionString[GroupingMode];
			TreeRow.TaskImage = 2;
			TreeRow.Importance = 1;
			TreeRow.Group = True;
			GroupLines = TaskTable_.FindRows(New Structure(GroupingMode,DimensionString[GroupingMode]));
			For Each String In GroupLines Do
				ElementString = TreeRow.Rows.Add();
				FillPropertyValues(ElementString,String);
			EndDo;
			TreeRow.Rows.Sort("TaskDueDate DESC, Task");
		EndDo;
		Items[TaskListName].Representation = TableRepresentation.Tree;
		Tree.Rows.Sort("Task");
	Else
		For Each String In TaskTable_ Do
			TreeRow = Tree.Rows.Add();
			FillPropertyValues(TreeRow,String);
		EndDo;
		Items[TaskListName].Representation = TableRepresentation.List;
		Tree.Rows.Sort("TaskDueDate DESC, Task");
	EndIf;
	
	ValueToFormAttribute(Tree, TaskListName);
	SetCurrentRow(CurrentTask);
	
EndProcedure

&AtServer
Procedure SetCurrentRow(TaskID)
	
	If Items.GroupPages.CurrentPage = Items.TaskGroupMe Then
		TaskListName = "TasksToMe";
		TaskList = TasksToMe;
	Else
		TaskListName = "TasksFromMe";
		TaskList = TasksFromMe;
	EndIf;
	
	If ValueIsFilled(TaskID) Then
		If Items[TaskListName].Representation = TableRepresentation.List Then
			TaskLines_ = TaskList.GetItems();
			For Each TaskLine In TaskLines_ Do
				If TaskLine.TaskID = TaskID Then
					Items[TaskListName].CurrentRow = TaskLine.GetID();
					Break;
				EndIf;
			EndDo;
		Else
			For Each TreeGroup In TaskList.GetItems() Do
				TaskLines_ = TreeGroup.GetItems();
				For Each TaskLine In TaskLines_ Do
					If TaskLine.TaskID = TaskID Then
						Items[TaskListName].CurrentRow = TaskLine.GetID();
						Break;
					EndIf;
				EndDo;
			EndDo;
		EndIf;
	EndIf;
	
EndProcedure

// Checks the connection to the DO by displaying the authorization window, if necessary, and changing the form according to the result.
//
&AtClient
Procedure TestConnection()
	
	CallbackDescription = New CallbackDescription("TestConnectionCompletion", ThisObject);
	IntegrationWith1CDocumentManagementCoreClient.TestConnection(
		CallbackDescription,
		ThisObject,,
		False);
	
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
		ExpandTaskGroups();
#If Not WebClient Then
		If TaskFunctionalityIsAvailable Then
			Items.AutoRefresh.Enabled = True;
			If AutoRefresh Then
				AttachIdleHandler("AutoRefresh", AutoRefreshPeriod);
			EndIf;
		EndIf;
#EndIf
	EndIf;
	
EndProcedure

&AtServer
Function ProcessFormAccordingToServiceVersion()
	
	Title = NStr("vi = 'Quản lý văn bản: Nhiệm vụ của tôi';
				|ru = 'Документооборот: Мои задачи';
				|en = 'Document Management: My tasks'; fa = 'مدیریت اسناد: وظایف من';
				|it = 'Document Management: I miei compiti';
				|pl = 'Document Management: Moje zadania';
				|tr = 'İş akışı: Görevlerim'");
	
	ServiceVersion = IntegrationWith1CDocumentManagementCore.ServiceVersion();
	
	If Not IntegrationWith1CDocumentManagementCoreClientServer.ServiceIsAvailable(ServiceVersion) Then
		Items.FunctionalityGroupIsNotSupported.Visible = True;
		Items.AuthorizationVerificationGroup.Visible = True;
		Items.DecorationFunctionalityIsNotSupported.Title = NStr("vi = 'Không đủ quyền truy cập đến 1C:Document Management.';
																|ru = 'Нет доступа к 1С:Документообороту.';
																|en = 'No access to 1C:Document Management.'; fa = 'دسترسی به 1C:Document Management وجود ندارد.';
																|it = 'Non vi è accesso a 1C:Document Management.';
																|pl = 'Brak dostępu do 1C:Document Management.';
																|tr = '1C:Document Management''e erişilmiyor.'");
		Return False;
	EndIf;
	
	FormProcessedSuccessfully = True;
	
	Try
		
		Items.AuthorizationVerificationGroup.Visible = False;
		Items.FunctionalityGroupIsNotSupported.Visible = False;
		
		// Tasks
		If IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("1.2.6.2")
				And Not IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("3.0.1.1") Then
			Items.GroupPages.Enabled = True;
			Items.FooterGroup.Enabled = True;
			TaskFunctionalityIsAvailable = True;
			AvailableTaskFunctionalityFromMe
				= IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("1.3.2.3");
			RefreshTasksListOnServer();
		Else
			Items.GroupPages.Enabled = False;
			Items.FooterGroup.Enabled = False;
			TaskFunctionalityIsAvailable = False;
			AvailableTaskFunctionalityFromMe = False;
			DataProcessors.IntegrationWith1CDocumentManagement.ProcessFormIfServiceVersionFunctionalityIsUnavailable(ThisObject);
			Items.Completed.ReadOnly = True;
		EndIf;
		// solving issues
		If Not IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("1.2.7.3") Then
			Items.AskAuthorQuestion.Visible = False;
		EndIf;
		// Mail
		If Not IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("1.2.8.1.CORP") Then
			Items.CreateEmail.Visible = False;
			Items.CreateEmail2.Visible = False;
		EndIf;
		// Acceptance of tasks for execution.
		If Not IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("1.2.7.3.CORP") Then
			Items.AcceptForExecution.Visible = False;
			Items.TasksToMeContextMenuAcceptForExecution.Visible = False;
		EndIf;
		// Canceling the acceptance of tasks for execution.
		If Not IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("2.1.18.1.CORP") Then
			Items.CancelAcceptForExecution.Visible = False;
			Items.TasksToMeContextMenuCancelAcceptForExecution.Visible = False;
		EndIf;
		
		If Not AvailableTaskFunctionalityFromMe Then
			Items.TasksFromMe.Visible = False;
			Items.GroupPages.PagesRepresentation = FormPagesRepresentation.None;
		Else
			Items.TasksFromMe.Visible = True;
			Items.GroupPages.PagesRepresentation = FormPagesRepresentation.TabsOnTop;
		EndIf;
		
	Except
		
		If IntegrationWith1CDocumentManagementCoreServerCall.NeedToProcessForm(ErrorInfo()) Then
			ProcessFormAccordingToServiceVersion();
		EndIf;
		
	EndTry;
	
	Return FormProcessedSuccessfully;
	
EndFunction

&AtClient
Procedure AutoRefresh()
	
	RefreshTasksListOnServer();
	ExpandTaskGroups();
	
EndProcedure

&AtClient
Procedure SettingAutoupdate()
	
	FormParameters = New Structure;
	FormParameters.Insert("AutoRefresh", AutoRefresh);
	FormParameters.Insert("AutoRefreshPeriod", AutoRefreshPeriod);
	
	Notification = New CallbackDescription("SettingAutoupdateCompletion", ThisObject);
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagementCore.Form.SettingAutoupdate",
		FormParameters, ThisObject,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
	
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
	Item.Insert("Object", "IntegrationWith1CDocumentManagement");
	Item.Insert("Setting", "AutoRefresh");
	Item.Insert("Value", AutoRefresh);
	StructuresArray.Add(Item);
	
	Item = New Structure;
	Item.Insert("Object", "IntegrationWith1CDocumentManagement");
	Item.Insert("Setting", "AutoRefreshPeriod");
	Item.Insert("Value", AutoRefreshPeriod);
	StructuresArray.Add(Item);
	
	IntegrationWith1CDocumentManagementCoreClient.CommonSettingsStorageSaveArray(StructuresArray);
	
	If AutoRefresh Then
		AttachIdleHandler("AutoRefresh", AutoRefreshPeriod);
	EndIf;
	
EndProcedure

&AtServer
Procedure AcceptTasksForExecution()
	
	Modified = False;
	RowsArray = Items.TasksToMe.SelectedRows;
	If RowsArray.Count() <> 0 Then
		TaskArrayBefore = New Array;
		For Each Item In RowsArray Do
			TaskLine = TasksToMe.FindByID(Item);
			If ValueIsFilled(TaskLine.TaskID) Then
				TaskArrayBefore.Add(TaskLine.TaskID);
			EndIf;
		EndDo;
		If TaskArrayBefore.Count() > 0 Then
			Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
			IntegrationWith1CDocumentManagement.AcceptTaskForExecution(Proxy, TaskArrayBefore);
			UpdateTaskListPartiallyOnServer();
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure CancelAcceptTasksForExecution()
	
	Modified = False;
	RowsArray = Items.TasksToMe.SelectedRows;
	If RowsArray.Count() <> 0 Then
		TaskArrayBefore = New Array;
		For Each Item In RowsArray Do
			TaskLine = TasksToMe.FindByID(Item);
			If ValueIsFilled(TaskLine.TaskID) Then
				TaskArrayBefore.Add(TaskLine.TaskID);
			EndIf;
		EndDo;
		If TaskArrayBefore.Count() > 0 Then
			Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
			IntegrationWith1CDocumentManagement.CancelAcceptTasksForExecution(Proxy, TaskArrayBefore);
			UpdateTaskListPartiallyOnServer();
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetTaskAppearance(Var_ConditionalAppearance)
	
	// installing the registration for overdue tasks to me
	ConditionalAppearanceItem = Var_ConditionalAppearance.Items.Add();
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("TasksToMe.TaskDueDate");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Filled;
	DataFilterItem.Use = True;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("TasksToMe.TaskDueDate");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Less;
	DataFilterItem.RightValue = BegOfDay(CurrentSessionDate());
	DataFilterItem.Use = True;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("TasksToMe.Executed");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = False;
	DataFilterItem.Use = True;
	
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("TextColor");
	AppearanceColorItem.Value =  Metadata.StyleItems.OverdueDataColor.Value;
	AppearanceColorItem.Use = True;
	
	AppearanceAreaItem = ConditionalAppearanceItem.Fields.Items.Add();
	AppearanceAreaItem.Field = New DataCompositionField("TasksToMe");
	
	// installing the registration for overdue tasks from me
	ConditionalAppearanceItem = Var_ConditionalAppearance.Items.Add();
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("TasksFromMe.TaskDueDate");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Filled;
	DataFilterItem.Use = True;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("TasksFromMe.TaskDueDate");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Less;
	DataFilterItem.RightValue = BegOfDay(CurrentSessionDate());
	DataFilterItem.Use = True;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("TasksFromMe.Executed");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = False;
	DataFilterItem.Use = True;
	
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("TextColor");
	AppearanceColorItem.Value =  Metadata.StyleItems.OverdueDataColor.Value;
	AppearanceColorItem.Use = True;
	
	AppearanceAreaItem = ConditionalAppearanceItem.Fields.Items.Add();
	AppearanceAreaItem.Field = New DataCompositionField("TasksFromMeTaskDueDate");
	
EndProcedure

&AtClient
Procedure UpdateTaskListPartially()
	
	UpdateTaskListPartiallyOnServer();
	ExpandTaskGroups();
	
EndProcedure

&AtServerNoContext
Function GetTasksToMe(Proxy, Completed)
	
	ListOfConditions = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListQuery");
	FilterConditions = ListOfConditions.conditions; // XDTOList
	
	Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
	Condition.property = "byUser";
	Condition.value = True;
	FilterConditions.Add(Condition);
	
	Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
	Condition.property = "withExecuted";
	Condition.value = Completed;
	FilterConditions.Add(Condition);
	
	Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
	Condition.property = "withDelayed";
	Condition.value = False;
	FilterConditions.Add(Condition);
	
	Response = IntegrationWith1CDocumentManagementCore.FindListOfObjects(
		Proxy,
		"DMBusinessProcessTask",
		ListOfConditions);
	
	Return Response.items;
	
EndFunction

&AtServerNoContext
Function GetTasksFromMe(Proxy, Completed)
	
	ListOfConditions = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListQuery");
	FilterConditions = ListOfConditions.conditions; // XDTOList
	
	Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
	Condition.property = "author";
	Condition.value = "";
	FilterConditions.Add(Condition);
	
	Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
	Condition.property = "withExecuted";
	Condition.value = Completed;
	FilterConditions.Add(Condition);
	
	Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
	Condition.property = "withDelayed";
	Condition.value = False;
	FilterConditions.Add(Condition);
	
	Response = IntegrationWith1CDocumentManagementCore.FindListOfObjects(
		Proxy,
		"DMBusinessProcessTask",
		ListOfConditions);
	
	Return Response.items;
	
EndFunction

&AtServer
Procedure FillInTheTaskList(XDTOTasks)
	
	If Items.GroupPages.CurrentPage = Items.TaskGroupMe Then
		TaskListName =  "TasksToMe";
		GroupingMode = TaskGroupingModeForMe;
		CurrentTask = Items.TasksToMe.CurrentRow;
		If CurrentTask <> Undefined Then
			CurTaskLine = TasksToMe.FindByID(CurrentTask);
			If CurTaskLine = Undefined Then
				CurrentTask = Undefined;
			Else
				CurrentTask = CurTaskLine.TaskID;
			EndIf;
		EndIf;
	Else
		TaskListName =  "TasksFromMe";
		GroupingMode = TaskGroupingModeFromMe;
		CurrentTask = Items.TasksFromMe.CurrentRow;
		If CurrentTask <> Undefined Then
			CurTaskLine = TasksFromMe.FindByID(CurrentTask);
			If CurTaskLine = Undefined Then
				CurrentTask = Undefined;
			Else
				CurrentTask = CurTaskLine.TaskID;
			EndIf;
		EndIf;
	EndIf;
	
	Tree = FormAttributeToValue(TaskListName); // ValueTree
	
	TaskTable_ = New ValueTable;
	For Each Column In Tree.Columns Do
		TaskTable_.Columns.Add(Column.Name, Column.ValueType);
	EndDo;
	
	For Each XDTOTask In XDTOTasks Do
		TaskLine = TaskTable_.Add();
		FillInXDTOTaskLine(TaskLine, XDTOTask.object);
	EndDo;
	Tree.Rows.Clear();
	
	If ValueIsFilled(GroupingMode) Then
		Items[TaskListName].Representation = TableRepresentation.Tree;
		DimensionsTable = TaskTable_.Copy();
		DimensionsTable.GroupBy(GroupingMode);
		For Each DimensionString In DimensionsTable Do
			TreeRow = Tree.Rows.Add();
			TreeRow.Task = DimensionString[GroupingMode];
			TreeRow.TaskImage = 2;
			TreeRow.Importance = 1;
			TreeRow.Group = True;
			GroupLines = TaskTable_.FindRows(New Structure(GroupingMode,DimensionString[GroupingMode]));
			For Each String In GroupLines Do
				ElementString = TreeRow.Rows.Add();
				FillPropertyValues(ElementString,String);
				TreeRow.Rows.Sort("TaskDueDate DESC, Task");
			EndDo;
		EndDo;
		Tree.Rows.Sort("Task");
	Else
		Items[TaskListName].Representation = TableRepresentation.List;
		For Each String In TaskTable_ Do
			TreeRow = Tree.Rows.Add();
			FillPropertyValues(TreeRow,String);
		EndDo;
		Tree.Rows.Sort("TaskDueDate DESC, Task");
	EndIf;
	
	ValueToFormAttribute(Tree, TaskListName);
	
	If Items.GroupPages.CurrentPage = Items.TaskGroupMe Then
		TaskTableMeLink = PutToTempStorage(TaskTable_, UUID);
		TasksAreReadToMe = True;
	Else
		TaskTableFromMeLink = PutToTempStorage(TaskTable_, UUID);
		TasksFromMeAreRead = True;
	EndIf;
	
	SetCurrentRow(CurrentTask);
	
	FillSceneryWithTaskNumbers();
	
EndProcedure

&AtServer
Procedure FillSceneryWithTaskNumbers()
	
	If Items.GroupPages.CurrentPage = Items.TaskGroupMe Then
		TaskTableLink = TaskTableMeLink;
	Else
		Return;
	EndIf;
	
	Overdue = 0;
	NotAccepted = 0;
	CurrentDate = CurrentSessionDate();
	TaskTable_ = GetFromTempStorage(TaskTableLink); // ValueTable
	NotListOfCompletedTasks = TaskTable_.FindRows(New Structure("Executed", False));
	
	For Each TaskLine In NotListOfCompletedTasks Do
		If ValueIsFilled(TaskLine.TaskDueDate) And TaskLine.TaskDueDate < CurrentDate Then
			Overdue = Overdue + 1;
		EndIf;
		If Not TaskLine.AcceptedForExecution Then
			NotAccepted = NotAccepted + 1;
		EndIf;
	EndDo;
		
	Items.DecorationTotalNumberOfTasksToMe.Title = NotListOfCompletedTasks.Count();
	Items.DecorationNumberOfOverdueTasksToMe.Title = Overdue;
	Items.DecorationNumberOfRejectedTasksToMe.Title = NotAccepted;
	Items.DecorationSeparatorOfNumberOfTasksForMe1.Title = "/";
	Items.DecorationSeparatorNumberOfTasksI2.Title = "/";
	
EndProcedure

&AtServer
Procedure FillInXDTOTaskLine(TaskLine, XDTOTask)
	
	Importance = 1;
	If XDTOTask.importance.objectID.ID = "Низкая" Then //@NON-NLS-1
		Importance = 0;
	ElsIf XDTOTask.importance.objectID.ID = "Обычная" Then //@NON-NLS-1
		Importance = 1;
	ElsIf XDTOTask.importance.objectID.ID = "Высокая" Then //@NON-NLS-1
		Importance = 2;
	EndIf;
	
	TaskLine.Importance = Importance;
	TaskLine.StringImportance = XDTOTask.importance.name;
	TaskLine.TaskImage = ?(XDTOTask.executed,1,0);
	TaskLine.Executed = XDTOTask.executed;
	TaskLine.RoutePoint = XDTOTask.businessProcessStep;
	TaskLine.TaskDueDate = XDTOTask.dueDate;
	TaskLine.Saved = XDTOTask.beginDate;
	TaskLine.Author = XDTOTask.author.name;
	TaskLine.AcceptedForExecution = XDTOTask.accepted;
	
	ArtistXDTO = XDTOTask.performer;
	If ArtistXDTO.IsSet("user") Then
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(TaskLine, ArtistXDTO.user,"Performer")
	ElsIf ArtistXDTO.IsSet("role") Then
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(TaskLine, ArtistXDTO.role,"Performer")
	EndIf;
	
	FillInObjectDetails(TaskLine,XDTOTask.parentBusinessProcess,"Process_");
	FillInObjectDetails(TaskLine,XDTOTask.target,"SubjectOf");
	FillInObjectDetails(TaskLine,XDTOTask,"Task");
	
EndProcedure

&AtServer
Procedure RefreshTasksListOnServer()
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	If Items.GroupPages.CurrentPage = Items.TaskGroupMe Then
		XDTOTasks = GetTasksToMe(Proxy, Completed);
	Else
		XDTOTasks = GetTasksFromMe(Proxy, Completed);
	EndIf;
	FillInTheTaskList(XDTOTasks);
	
EndProcedure

&AtServer
Procedure UpdateTaskListPartiallyOnServer()
	
	If Items.GroupPages.CurrentPage = Items.TaskGroupMe Then
		TaskTableLink = TaskTableMeLink;
	Else
		TaskTableLink = TaskTableFromMeLink;
	EndIf;
	
	If Not ValueIsFilled(TaskTableLink) Then
		RefreshTasksListOnServer();
		Return;
	EndIf;
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	If Items.GroupPages.CurrentPage = Items.TaskGroupMe Then
		XDTOTasks = GetTasksToMe(Proxy, Completed);
	Else
		XDTOTasks = GetTasksFromMe(Proxy, Completed);
	EndIf;
	
	TaskTable_ = GetFromTempStorage(TaskTableLink); // ValueTable
	TasksToDelete = TaskTable_.UnloadColumn("TaskID");
	
	For Each XDTOTask In XDTOTasks Do
		TaskLines = TaskTable_.FindRows(New Structure("TaskID",XDTOTask.object.objectID.ID));
		If TaskLines.Count() > 0 Then
			TaskLine = TaskLines[0];
			TasksToDelete.Delete(TasksToDelete.Find(XDTOTask.object.objectID.ID));
		Else
			TaskLine = TaskTable_.Add();
		EndIf;
		FillInXDTOTaskLine(TaskLine,XDTOTask.object);
	EndDo;
	
	For Each TaskToDelete In TasksToDelete Do
		TaskLines = TaskTable_.FindRows(New Structure("TaskID", TaskToDelete));
		If TaskLines.Count() > 0 Then
			TaskTable_.Delete(TaskLines[0]);
		EndIf;
	EndDo;
	
	If Items.GroupPages.CurrentPage = Items.TaskGroupMe Then
		TaskTableMeLink = PutToTempStorage(TaskTable_, UUID);
		GroupByColumnOnServer(TaskGroupingModeForMe);
	Else
		TaskTableFromMeLink = PutToTempStorage(TaskTable_, UUID);
		GroupByColumnOnServer(TaskGroupingModeFromMe);
	EndIf;
	
	FillSceneryWithTaskNumbers();
	
EndProcedure

&AtServer
Procedure FillInObjectDetails(Receiver, Source, Var_AttributeName)
	
	If Source <> Undefined Then
		Receiver[Var_AttributeName] = Source.name;
		Receiver[Var_AttributeName + "ID"] = Source.objectID.ID;
		Receiver[Var_AttributeName + "Type"] = Source.objectID.type;
	EndIf;
	
EndProcedure

#EndRegion
