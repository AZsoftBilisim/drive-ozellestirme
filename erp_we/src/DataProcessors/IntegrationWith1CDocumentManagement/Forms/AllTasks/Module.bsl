#Region Variables

&AtClient
Var NumberOfActivatedLine;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("ExternalObject") Then
		If TypeOf(Parameters.ExternalObject) = Type("Structure") Then
			ExternalObject = Parameters.ExternalObject.presentation;
			ExternalObjectID = Parameters.ExternalObject.ID;
			ExternalObjectType = Parameters.ExternalObject.type;
			If Find(ExternalObjectType,"Document") <> 0
					Or ExternalObjectType = "DMFile"
					Or ExternalObjectType = "DMCorrespondent" Then
				Title = NStr("vi = 'Quy trình và nhiệm vụ';
							|ru = 'Процессы и задачи';
							|en = 'Processes and tasks'; fa = 'فرایندها و وظایف';
							|it = 'Processi e compiti';
							|pl = 'Procesy i zadania';
							|tr = 'Süreçler ve görevler'");
			ElsIf Find(ExternalObjectType,"BusinessProcess") <> 0 Then
				Title = NStr("vi = 'Nhiệm vụ quy trình %Object%';
							|ru = 'Задачи процесса %Object%';
							|en = '%Object% process tasks'; fa = '%Object% process tasks';
							|it = 'Compiti del processo %Object%';
							|pl = 'Zadania procesu %Object%';
							|tr = 'Süreç görevleri %Object%'");
				Title = StrReplace(Title, "%Object%", Parameters.ExternalObject.presentation);
			EndIf;
		EndIf;
	EndIf;
	
	ReferenceToExternalObject = Parameters.ReferenceToExternalObject;
	If ValueIsFilled(ReferenceToExternalObject) Then
		Title = NStr("vi = 'Nhiệm vụ theo ""%Object%""';
					|ru = 'Задачи по ""%Object%""';
					|en = 'Tasks by ""%Object%""'; fa = 'Tasks by ""%Object%""';
					|it = 'Compiti per ""%Object%""';
					|pl = 'Zadania według ""%Object%""';
					|tr = '""%Object%"" ile ilgili görevler'");
		Title = StrReplace(Title, "%Object%", Parameters.ExternalObject.name);
	EndIf;
	
	If ValueIsFilled(ExternalObjectID) Or ValueIsFilled(ReferenceToExternalObject) Then
		LoadTreeOfBusinessProcessesAndTasks();
	EndIf;
	
	// task completion results
	If Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.3.2.3") Then
		Items.TreeOfBusinessProcessesAndTasksCompleted2.Visible = True;
		Items.TreeOfBusinessProcessesAndTasksPicture.Visible = False;
	EndIf;
	// Acceptance of tasks for execution.
	If Not IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("1.2.7.3.CORP") Then
		Items.TreeOfBusinessProcessesAndTasksAcceptForExecution.Visible = False;
	EndIf;
	// Canceling the acceptance of tasks for execution.
	If Not IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("2.1.18.1.CORP") Then
		Items.TreeOfBusinessProcessesAndTasksCancelAcceptForExecution.Visible = False;
	EndIf;
	
	// conditional design
	SetConditionalAppearanceOfTree();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Recording_1CDocumentManagementBusinessProcess" Then
		DisclosedElements = New ValueList;
		GetDisclosedElements(
			Items.TreeOfBusinessProcessesAndTasks, TreeOfBusinessProcessesAndTasks.GetItems(), DisclosedElements);
		DisclosedElements.Add(Parameter.ID);
		LoadTreeOfBusinessProcessesAndTasks();
		SetExpansionOfTreeElements(
			Items.TreeOfBusinessProcessesAndTasks, TreeOfBusinessProcessesAndTasks, DisclosedElements);
		SetCurElementInTree(
			Items.TreeOfBusinessProcessesAndTasks, TreeOfBusinessProcessesAndTasks, Parameter.ID);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTreeOfBusinessProcessesAndTasks

&AtClient
Procedure TreeOfBusinessProcessesAndTasksOnActivateRow(Item)
	
	If NumberOfActivatedLine <> Item.CurrentRow Then
		
		NumberOfActivatedLine = Item.CurrentRow;
		TaskLine = Items.TreeOfBusinessProcessesAndTasks.CurrentData;
		If TaskLine = Undefined
			Or TaskLine.ObjectType <> "DMBusinessProcessTask"
			Or TaskLine.Completed2 Then
			
			Items.TreeOfBusinessProcessesAndTasksAcceptForExecution.Enabled = False;
			Items.TreeOfBusinessProcessesAndTasksCancelAcceptForExecution.Enabled = False;
		Else
			Items.TreeOfBusinessProcessesAndTasksAcceptForExecution.Enabled = Not TaskLine.AcceptedForExecution;
			Items.TreeOfBusinessProcessesAndTasksCancelAcceptForExecution.Enabled = TaskLine.AcceptedForExecution;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure TreeOfBusinessProcessesAndTasksSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	OpenCardExecute();
	
EndProcedure

&AtClient
Procedure TreeOfBusinessProcessesAndTasksBeforeRowChange(Item, Cancel)
	Cancel = True;
	OpenCardExecute();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OpenCard(Command)
	
	Modified = False;
	OpenCardExecute();
	
EndProcedure

&AtClient
Procedure UpdateList(Command)
	
	Modified = False;
	UpdateTaskListOnClient();
	
EndProcedure

&AtClient
Procedure AcceptForExecution(Command)
	
	Modified = False;
	AcceptTasksForExecution();
	
	If Items.TreeOfBusinessProcessesAndTasks.CurrentData <> Undefined Then
		Parameter = New Structure("ID", Items.TreeOfBusinessProcessesAndTasks.CurrentData.ObjectID);
		UpdateTaskListOnClient(Parameter);
	EndIf;
	
EndProcedure

&AtClient
Procedure CancelAcceptForExecution(Command)
	
	Modified = False;
	CancelAcceptTasksForExecution();
	
	If Items.TreeOfBusinessProcessesAndTasks.CurrentData <> Undefined Then
		Parameter = New Structure("ID", Items.TreeOfBusinessProcessesAndTasks.CurrentData.ObjectID);
		UpdateTaskListOnClient(Parameter);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearanceOfTree()
	
	If ConditionalAppearance.Items.Count() = 3 Then
		ItemForDelete = ConditionalAppearance.Items[2];
		ConditionalAppearance.Items.Delete(ItemForDelete);
	EndIf;
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("TreeOfBusinessProcessesAndTasks.TaskDueDate");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Filled;
	DataFilterItem.Use = True;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("TreeOfBusinessProcessesAndTasks.Completed2");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = False;
	DataFilterItem.Use = True;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("TreeOfBusinessProcessesAndTasks.TaskDueDate");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Less;
	DataFilterItem.RightValue = CurrentSessionDate();
	DataFilterItem.Use = True;
	
	NewItem = ConditionalAppearanceItem.Fields.Items.Add();
	NewItem.Field = New DataCompositionField("TreeOfBusinessProcessesAndTasksTaskDueDate");
		
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("TextColor");
	AppearanceColorItem.Value = Metadata.StyleItems.OverdueDataColor.Value;
	AppearanceColorItem.Use = True;
	
EndProcedure

&AtServer
Procedure BuildTaskTreeFromWebServiceResponse(TaskTreeRows, ResponseLines)
		
	For Each OneResponseString In ResponseLines Do
		Importance = 1;
		If OneResponseString.importance.objectID.ID = "Низкая" Then //@NON-NLS-1
			Importance = 0;
		ElsIf OneResponseString.importance.objectID.ID = "Обычная" Then //@NON-NLS-1
			Importance = 1;
		ElsIf OneResponseString.importance.objectID.ID = "Высокая" Then //@NON-NLS-1
			Importance = 2;
		EndIf;
		If Find(OneResponseString.objectID.type, "BusinessProcess") > 0
			And Find(OneResponseString.objectID.type, "Task") = 0 Then
			If Not (ValueIsFilled(ExternalObjectID) And ExternalObjectID = OneResponseString.objectID.ID) Then
				NewRow = TaskTreeRows.Add();
				NewRow.Importance = Importance;
				NewRow.Completed2 = ValueIsFilled(OneResponseString.endDate);
				NewRow.Description = OneResponseString.name;
				NewRow.StartDate = OneResponseString.beginDate;
				NewRow.Author = OneResponseString.author.name;
				NewRow.Type = 0;
				NewRow.ObjectType = OneResponseString.objectID.type;
				NewRow.ObjectID  = OneResponseString.objectID.ID;
				// task completion results
				If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.3.2.3") Then
					NewRow.Picture = IntegrationWith1CDocumentManagement.IndexOfCompletionTagImage(
						OneResponseString.completionMark);
				EndIf;
				BuildTaskTreeFromWebServiceResponse(NewRow.Rows, OneResponseString.tasks);
			Else
				BuildTaskTreeFromWebServiceResponse(TaskTreeRows, OneResponseString.tasks);
			EndIf;
		ElsIf Find(OneResponseString.objectID.type, "Task") > 0 Then
			If ThisIsServiceTask(OneResponseString) Then
				BuildTaskTreeFromWebServiceResponse(TaskTreeRows, OneResponseString.businessProcesses);
			Else
				NewRow = TaskTreeRows.Add();
				NewRow.Importance = Importance;
				NewRow.Completed2 = OneResponseString.executed;
				NewRow.Description = OneResponseString.name;
				NewRow.TaskDueDate = OneResponseString.dueDate;
				NewRow.StartDate = OneResponseString.beginDate;
				If OneResponseString.performer.IsSet("user") Then
					NewRow.Performer = OneResponseString.performer.user.name;
				ElsIf OneResponseString.performer.IsSet("role") Then
					NewRow.Performer = OneResponseString.performer.role.name;
					If OneResponseString.performer.IsSet("mainAddressingObject") Then
						NewRow.Performer = NewRow.Performer + ", "
							+ OneResponseString.performer.mainAddressingObject.name;
					EndIf;
					If OneResponseString.Performer.IsSet("secondaryAddressingObject") Then
						NewRow.Performer = NewRow.Performer + ", "
							+ OneResponseString.performer.secondaryAddressingObject.name;
					EndIf;
				EndIf;
				NewRow.Type = 1;
				NewRow.ObjectType = OneResponseString.objectID.type;
				NewRow.ObjectID = OneResponseString.objectID.ID;
				NewRow.OwnerType = OneResponseString.parentBusinessProcess.objectID.type;
				NewRow.OwnerID = OneResponseString.parentBusinessProcess.objectID.ID;
				NewRow.RoutePoint = OneResponseString.businessProcessStep;
				NewRow.AcceptedForExecution = OneResponseString.accepted;
				// task completion results
				If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.3.2.3") Then
					NewRow.Picture = IntegrationWith1CDocumentManagement.IndexOfCompletionTagImage(
						OneResponseString.executionMark);
				EndIf;
				BuildTaskTreeFromWebServiceResponse(NewRow.Rows, OneResponseString.businessProcesses);
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure OpenCardExecute()
	
	If Items.TreeOfBusinessProcessesAndTasks.CurrentData = Undefined Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreClient.OpenObject(
		Items.TreeOfBusinessProcessesAndTasks.CurrentData.ObjectType,
		Items.TreeOfBusinessProcessesAndTasks.CurrentData.ObjectID,
		Items.TreeOfBusinessProcessesAndTasks);
	
EndProcedure

&AtServer
Procedure LoadTreeOfBusinessProcessesAndTasks()
	
	// Tasks.
	If Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.2.6.2")
			Or IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("3.0.1.1") Then
		DataProcessors.IntegrationWith1CDocumentManagement.ProcessFormIfServiceVersionFunctionalityIsUnavailable(ThisObject);
		Items.TreeOfBusinessProcessesAndTasks.Visible = False;
		Return;
	EndIf;
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMGetTasksTreeRequest");
	Filter = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMGetTasksTreeQuery");
	SelectionOfBusinessProcesses = Filter.businessProcess; // XDTOList
	FilterDocuments = Filter.target; // XDTOList
	
	If Find(ExternalObjectType,"BusinessProcess")<>0 Then
		Process_ = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObject");
		Process_.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
			Proxy,
			ExternalObjectID,
			ExternalObjectType);
		Process_.name = "";
		SelectionOfBusinessProcesses.Add(Process_);
		
	ElsIf Find(ExternalObjectType, "Document") <> 0
			Or ExternalObjectType = "DMFile"
			Or ExternalObjectType = "DMCorrespondent" Then
		
		// Getting tasks by subject.
		If Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.2.7.3") Then
			DataProcessors.IntegrationWith1CDocumentManagement.ProcessFormIfServiceVersionFunctionalityIsUnavailable(ThisObject);
			Return;
		EndIf;
		SubjectOf = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy,"DMObject");
		SubjectOf.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
			Proxy,
			ExternalObjectID,
			ExternalObjectType);
		SubjectOf.name = "";
		FilterDocuments.Add(SubjectOf);
		
	EndIf;
	
	Query.query = Filter;
	
	Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Response);
	
	TasksTree = FormAttributeToValue("TreeOfBusinessProcessesAndTasks", Type("ValueTree"));
	TasksTree.Rows.Clear();
	BuildTaskTreeFromWebServiceResponse(TasksTree.Rows, Response.businessProcesses);
	ValueToFormAttribute(TasksTree, "TreeOfBusinessProcessesAndTasks");
	SetConditionalAppearanceOfTree();
	
EndProcedure

&AtClient
Procedure UpdateTaskListOnClient(Parameter = Undefined)
	
	DisclosedElements = New ValueList;
	GetDisclosedElements(
		Items.TreeOfBusinessProcessesAndTasks, TreeOfBusinessProcessesAndTasks.GetItems(), DisclosedElements);
	If ValueIsFilled(Parameter) Then
		DisclosedElements.Add(Parameter.ID);
	EndIf;
	LoadTreeOfBusinessProcessesAndTasks();
	SetExpansionOfTreeElements(
		Items.TreeOfBusinessProcessesAndTasks, TreeOfBusinessProcessesAndTasks, DisclosedElements);
	If ValueIsFilled(Parameter) Then
		SetCurElementInTree(Items.TreeOfBusinessProcessesAndTasks, TreeOfBusinessProcessesAndTasks, Parameter.ID);
	EndIf;
	
EndProcedure

&AtServer
Procedure AcceptTasksForExecution()
	
	RowsArray = Items.TreeOfBusinessProcessesAndTasks.SelectedRows;
	If RowsArray.Count() <> 0 Then
		TaskArray = New Array;
		For Each Item In RowsArray Do
			DataString1 = TreeOfBusinessProcessesAndTasks.FindByID(Item);
			If ValueIsFilled(DataString1.ObjectID) And DataString1.ObjectType = "DMBusinessProcessTask" Then
				TaskArray.Add(DataString1.ObjectID);
			EndIf;
		EndDo;
		Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
		IntegrationWith1CDocumentManagement.AcceptTaskForExecution(Proxy, TaskArray);
	EndIf;
	
EndProcedure

&AtServer
Procedure CancelAcceptTasksForExecution()
	
	RowsArray = Items.TreeOfBusinessProcessesAndTasks.SelectedRows;
	If RowsArray.Count() <> 0 Then
		TaskArray = New Array;
		For Each Item In RowsArray Do
			DataString1 = TreeOfBusinessProcessesAndTasks.FindByID(Item);
			If ValueIsFilled(DataString1.ObjectID) And DataString1.ObjectType = "DMBusinessProcessTask" Then
				TaskArray.Add(DataString1.ObjectID);
			EndIf;
		EndDo;
		Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
		IntegrationWith1CDocumentManagement.CancelAcceptTasksForExecution(Proxy, TaskArray);
	EndIf;
	
EndProcedure

&AtClient
Procedure GetDisclosedElements(TreeElement, ArrayOfStringsOfSameLevel, ListOfDisclosedElements)
	
	For Each SingleLevelString In ArrayOfStringsOfSameLevel Do
		ElementID = SingleLevelString.GetID();
		If TreeElement.Expanded(ElementID) <> Undefined
			And TreeElement.Expanded(ElementID) Then
			ListOfDisclosedElements.Add(SingleLevelString.ObjectID);
		EndIf;
		GetDisclosedElements(TreeElement, SingleLevelString.GetItems(), ListOfDisclosedElements);
	EndDo;
	
EndProcedure

&AtClient
Procedure SetExpansionOfTreeElements(TreeElement, TreeProps, ListOfItemsToDeploy)
	
	If ListOfItemsToDeploy <> Undefined Then
		For Each ListItem In ListOfItemsToDeploy Do
			IndexOf = -1;
			FindElementInTree(TreeOfBusinessProcessesAndTasks.GetItems(), ListItem.Value, IndexOf);
			If IndexOf > -1 Then
				If TreeProps.FindByID(IndexOf).GetItems().Count() > 0 Then
					TreeElement.Expand(TreeOfBusinessProcessesAndTasks.FindByID(IndexOf).GetID(), False);
				Else
					If TreeProps.FindByID(IndexOf).GetParent() <> Undefined Then
						TreeElement.Expand(TreeOfBusinessProcessesAndTasks.FindByID(IndexOf).GetParent().GetID(), False);
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Procedure FindElementInTree(CollectionOfElementsOfSameLevel, DesiredElement, IndexOf)
	
	If CollectionOfElementsOfSameLevel.Count() > 0 Then
		For Each TreeItem In CollectionOfElementsOfSameLevel Do
			If TreeItem.ObjectID = DesiredElement Then
				IndexOf = TreeItem.GetID();
			Else
				FindElementInTree(TreeItem.GetItems(), DesiredElement, IndexOf);
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Procedure SetCurElementInTree(TreeElement, TreeProps, Var_CurrentItem)
	
	If Var_CurrentItem <> Undefined Then
		IndexOf = -1;
		FindElementInTree(TreeProps.GetItems(), Var_CurrentItem, IndexOf);
		If IndexOf > -1 Then
			TreeElement.CurrentRow = IndexOf;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Function ThisIsServiceTask(Task)
	
	Service_ = False;
	
	If Task.parentBusinessProcess.objectID.type = "DMComplexBusinessProcess" Then
		If Task.businessProcessStep = "Выполнить все действия процесса" Then //@NON-NLS-1
			Service_ = True;
		EndIf;
	ElsIf Task.parentBusinessProcess.objectID.type = "DMBusinessProcessInternalDocumentProcessing"
			Or Task.parentBusinessProcess.objectID.type = "DMBusinessProcessIncomingDocumentProcessing"
			Or Task.parentBusinessProcess.objectID.type = "DMBusinessProcessOutgoingDocumentProcessing" Then
		Service_ = True;
	EndIf;
	
	Return Service_;
	
EndFunction

#EndRegion