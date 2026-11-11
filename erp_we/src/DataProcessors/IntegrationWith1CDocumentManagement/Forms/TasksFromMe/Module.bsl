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
	
	Items.MainGroup2.Enabled = False;
	Items.AutoRefresh.Enabled = False;
	
	SetTaskAppearance(ConditionalAppearance);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	TestConnection();
	
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
	
	If EventName = "Workflow_ActionOnTask"
			And TypeOf(Parameter) = Type("Structure")
			And Parameter.Property("ID")
			And Parameter.Property("Type")
			And StringByID(Parameter.ID, Parameter.Type, Tasks.GetItems()) <> Undefined Then
		Refresh(Undefined);
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

#EndRegion

#Region FormTableItemsEventHandlersTasks

&AtClient
Procedure TasksSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	Task = Items.Tasks.CurrentData;
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
Procedure TasksBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)

	Cancel = True;
	
EndProcedure

&AtClient
Procedure TasksBeforeDeleteRow(Item, Cancel)

	Cancel = True;
	
EndProcedure

&AtClient
Procedure TasksBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	
	Task = Items.Tasks.CurrentData;
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
	
	CurrentData = Items.Tasks.CurrentData;
	If CurrentData = Undefined Then
		Return;
	ElsIf CurrentData.Group Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreClient.OpenObject(
		CurrentData.TaskType, CurrentData.TaskID, ThisObject);
	
EndProcedure

&AtClient
Procedure OpenArticle(Command)
	
	Modified = False;
	
	CurrentData = Items.Tasks.CurrentData;
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
	
	CurrentData = Items.Tasks.CurrentData;
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
	
	CurrentData = Items.Tasks.CurrentData;
	If CurrentData = Undefined Then
		Return;
	ElsIf CurrentData.Group Then
		Return;
	EndIf;
	
	FormParameters = New Structure("SubjectOf", New Structure);
	
	FormParameters.SubjectOf.Insert("name", CurrentData.Task);
	FormParameters.SubjectOf.Insert("ID", CurrentData.TaskID);
	FormParameters.SubjectOf.Insert("type", CurrentData.TaskType);
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.Outgoing_Email", FormParameters);
	
EndProcedure

&AtClient
Procedure GroupByImportance(Command)
	
	GroupByColumn("StringImportance");
	
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
Procedure GroupByNoGroup(Command)
	
	GroupByColumn("");
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Function StringByID(TaskID, TaskType, RowsCollection)
	
	For Each String In RowsCollection Do
		
		If String.TaskID = TaskID And String.TaskType = TaskType Then
			Return String;
		EndIf;
		
		SubordinateRow = StringByID(TaskID, TaskType, String.GetItems());
		If SubordinateRow <> Undefined Then
			Return SubordinateRow;
		EndIf;
		
	EndDo;
	
	Return Undefined;
	
EndFunction

&AtClient
Procedure CreateProcessCompletion(Result, NotificationParameters) Export
	
	UpdateTaskListPartially();
	
EndProcedure

&AtClient
Procedure ExpandTaskGroups()
	
	TreeItems = Tasks.GetItems();
	For Each TreeItem In TreeItems Do
		If TreeItem.Group Then
			Items.Tasks.Expand(TreeItem.GetID(), False);
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
Procedure GroupByColumnOnServer(GroupingMode)
	
	If Not ValueIsFilled(TaskTableLink) Then
		Return;
	EndIf;
	
	CurrentTask = Items.Tasks.CurrentRow;
	If CurrentTask <> Undefined Then
		CurTaskLine = Tasks.FindByID(CurrentTask);
		If CurTaskLine = Undefined Then
			CurrentTask = Undefined;
		Else
			CurrentTask = CurTaskLine.TaskID;
		EndIf;
	EndIf;
	
	Tree = FormAttributeToValue("Tasks");
	
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
			GroupLines = TaskTable_.FindRows(New Structure(GroupingMode,
				DimensionString[GroupingMode]));
			For Each String In GroupLines Do
				ElementString = TreeRow.Rows.Add();
				FillPropertyValues(ElementString,String);
			EndDo;
			TreeRow.Rows.Sort("TaskDueDate DESC, Task");
		EndDo;
		Items.Tasks.Representation = TableRepresentation.Tree;
		Tree.Rows.Sort("Task");
	Else
		For Each String In TaskTable_ Do
			TreeRow = Tree.Rows.Add();
			FillPropertyValues(TreeRow,String);
		EndDo;
		Items.Tasks.Representation = TableRepresentation.List;
		Tree.Rows.Sort("TaskDueDate DESC, Task");
	EndIf;
	
	ValueToFormAttribute(Tree, "Tasks");
	SetCurrentRow(CurrentTask);

EndProcedure

&AtServer
Procedure SetCurrentRow(TaskID)
	
	If ValueIsFilled(TaskID) Then
		If Items.Tasks.Representation = TableRepresentation.List Then
			TaskLines_ = Tasks.GetItems();
			For Each TaskLine In TaskLines_ Do
				If TaskLine.TaskID = TaskID Then
					Items.Tasks.CurrentRow = TaskLine.GetID();
					Break;
				EndIf;
			EndDo;
		Else
			For Each TreeGroup In Tasks.GetItems() Do
				TaskLines_ = TreeGroup.GetItems();
				For Each TaskLine In TaskLines_ Do
					If TaskLine.TaskID = TaskID Then
						Items.Tasks.CurrentRow = TaskLine.GetID();
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
		ExpandTaskGroups();
#If Not WebClient Then
		If AvailableTaskFunctionalityFromMe Then
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
	
	Title = NStr("vi = 'Document Management: Nhiệm vụ đi';
				|ru = 'Документооборот: Задачи от меня';
				|en = 'Document Management: Tasks from me'; fa = 'Document Management: Tasks from me';
				|it = 'Документооборот: Задачи от меня';
				|pl = 'Document Management: zadania ode mnie';
				|tr = 'İş akışı: Benden görevler'");
	
	ServiceVersion = IntegrationWith1CDocumentManagementCore.ServiceVersion();
	
	If Not IntegrationWith1CDocumentManagementCoreClientServer.ServiceIsAvailable(ServiceVersion) Then
		Items.MainGroup2.Enabled = False;
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
		
		// Tasks.
		If IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("1.3.2.3")
				And Not IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("3.0.1.1") Then
			Items.MainGroup2.Enabled = True;
			AvailableTaskFunctionalityFromMe = True;
			RefreshTasksListOnServer();
		Else
			Items.MainGroup2.Enabled = False;
			AvailableTaskFunctionalityFromMe = False;
			DataProcessors.IntegrationWith1CDocumentManagement.ProcessFormIfServiceVersionFunctionalityIsUnavailable(ThisObject);
		EndIf;
		
		If Not IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("1.2.8.1.CORP") Then
			Items.CreateEmail.Visible = False;
		EndIf;
		
	Except
		
		If IntegrationWith1CDocumentManagementCoreServerCall.NeedToProcessForm(ErrorInfo()) Then
			ProcessFormAccordingToServiceVersion();
		EndIf;
		
	EndTry;
	
	Return FormProcessedSuccessfully;
	
EndFunction

&AtServer
Procedure SetTaskAppearance(Var_ConditionalAppearance)

	// Setting the design for the rejected tasks.
	ConditionalAppearanceItem = Var_ConditionalAppearance.Items.Add();
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("Tasks.AcceptedForExecution");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = False;
	DataFilterItem.Use = True;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("Tasks.Group");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = False;
	DataFilterItem.Use = True;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("Tasks.Executed");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = False;
	DataFilterItem.Use = True;
	
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("Font");
	AppearanceColorItem.Value = Metadata.StyleItems.FontTasksNotReceivedForExecution.Value;
	AppearanceColorItem.Use = True;
	
	AppearanceAreaItem = ConditionalAppearanceItem.Fields.Items.Add();
	AppearanceAreaItem.Field = New DataCompositionField("TasksTask");
	
	// Installation of registration for overdue tasks.
	ConditionalAppearanceItem = Var_ConditionalAppearance.Items.Add();
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("Tasks.TaskDueDate");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Filled;
	DataFilterItem.Use = True;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("Tasks.TaskDueDate");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Less;
	DataFilterItem.RightValue = BegOfDay(CurrentSessionDate());
	DataFilterItem.Use = True;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("Tasks.Executed");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = False;
	DataFilterItem.Use = True;
	
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("TextColor");
	AppearanceColorItem.Value = Metadata.StyleItems.OverdueDataColor.Value;
	AppearanceColorItem.Use = True;
	
	AppearanceAreaItem = ConditionalAppearanceItem.Fields.Items.Add();
	AppearanceAreaItem.Field = New DataCompositionField("TasksTaskDueDate");
	
EndProcedure

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

&AtClient
Procedure UpdateTaskListPartially()
	
	UpdateTaskListPartiallyOnServer();
	ExpandTaskGroups();
	
EndProcedure

&AtServerNoContext
Function GetIssues(Proxy, Completed)
	
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
	
	CurrentTask = Items.Tasks.CurrentRow;
	If CurrentTask <> Undefined Then
		CurTaskLine = Tasks.FindByID(CurrentTask);
		If CurTaskLine = Undefined Then
			CurrentTask = Undefined;
		Else
			CurrentTask = CurTaskLine.TaskID;
		EndIf;
	EndIf;
	
	Tree = FormAttributeToValue("Tasks"); // ValueTree
	
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
		Items.Tasks.Representation = TableRepresentation.Tree;
		DimensionsTable = TaskTable_.Copy();
		DimensionsTable.GroupBy(GroupingMode);
		For Each DimensionString In DimensionsTable Do
			TreeRow = Tree.Rows.Add();
			TreeRow.Task = DimensionString[GroupingMode];
			TreeRow.TaskImage = 2;
			TreeRow.Importance = 1;
			TreeRow.Group = True;
			GroupLines = TaskTable_.FindRows(New Structure(GroupingMode,
				DimensionString[GroupingMode]));
			For Each String In GroupLines Do
				ElementString = TreeRow.Rows.Add();
				FillPropertyValues(ElementString,String);
				TreeRow.Rows.Sort("TaskDueDate DESC, Task");
			EndDo;
		EndDo;
		Tree.Rows.Sort("Task");
	Else
		Items.Tasks.Representation = TableRepresentation.List;
		For Each String In TaskTable_ Do
			TreeRow = Tree.Rows.Add();
			FillPropertyValues(TreeRow,String);
		EndDo;
		Tree.Rows.Sort("TaskDueDate DESC, Task");
	EndIf;
	
	ValueToFormAttribute(Tree, "Tasks");
	
	TaskTableLink = PutToTempStorage(TaskTable_, UUID);
	
	SetCurrentRow(CurrentTask);
	
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
	TaskLine.LongDesc = XDTOTask.description;
	TaskLine.Executed = XDTOTask.executed;
	TaskLine.RoutePoint = XDTOTask.businessProcessStep;
	TaskLine.TaskDueDate = XDTOTask.dueDate;
	TaskLine.Saved = XDTOTask.beginDate;
	TaskLine.Author = XDTOTask.author.name;
	TaskLine.AcceptedForExecution = XDTOTask.accepted;
	
	ArtistXDTO = XDTOTask.performer;
	If ArtistXDTO.IsSet("user") Then
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(TaskLine,
			ArtistXDTO.user,"Performer")
	ElsIf ArtistXDTO.IsSet("role") Then
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(TaskLine,
			ArtistXDTO.role,"Performer")
	EndIf;
	
	FillInObjectDetails(TaskLine,XDTOTask.parentBusinessProcess,"Process_");
	FillInObjectDetails(TaskLine,XDTOTask.target,"SubjectOf");
	FillInObjectDetails(TaskLine,XDTOTask,"Task");
	
EndProcedure

&AtServer
Procedure RefreshTasksListOnServer()
	
	Try
		Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
		XDTOTasks = GetIssues(Proxy, False);
		FillInTheTaskList(XDTOTasks);
	Except
		If IntegrationWith1CDocumentManagementCoreServerCall.NeedToProcessForm(ErrorInfo()) Then
			ProcessFormAccordingToServiceVersion();
		EndIf;
	EndTry;
	
EndProcedure

&AtServer
Procedure UpdateTaskListPartiallyOnServer()

	If Not ValueIsFilled(TaskTableLink) Then
		RefreshTasksListOnServer();
		Return;
	EndIf;
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Try
		XDTOTasks = GetIssues(Proxy, False);
	Except
		If IntegrationWith1CDocumentManagementCoreServerCall.NeedToProcessForm(ErrorInfo()) Then
			ProcessFormAccordingToServiceVersion();
		EndIf;
		Return;
	EndTry;
	
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
		TaskLines = TaskTable_.FindRows(New Structure("TaskID",TaskToDelete));
		If TaskLines.Count() > 0 Then
			TaskTable_.Delete(TaskLines[0]);
		EndIf;
	EndDo;
	
	TaskTableLink = PutToTempStorage(TaskTable_, UUID);
	GroupByColumnOnServer(GroupingMode);
	
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