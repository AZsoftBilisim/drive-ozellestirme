#Region Variables

&AtClient
Var NumberOfActivatedLine;

#EndRegion

#Region FormEventHandlers

&AtClient
Procedure OnOpen(Cancel)
	
	NumberOfActivatedLine = Undefined;
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Tasks.
	If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.2.6.2")
			And Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("3.0.1.1") Then
		If Parameters.Property("ExternalObject") Then
			BusinessProcess = Parameters.ExternalObject.presentation;
			BusinessProcessID = Parameters.ExternalObject.ID;
			BusinessProcessType = Parameters.ExternalObject.type;
			SetVisibilityOfTaskColumns();
			RefreshTasksListOnServer();
		EndIf;
	Else
		DataProcessors.IntegrationWith1CDocumentManagement.ProcessFormIfServiceVersionFunctionalityIsUnavailable(ThisObject);
		Items.GroupCommandBar.Visible = False;
		Items.ProcessTasks.Visible = False;
	EndIf;
	
	// Acceptance of tasks for execution.
	If Not IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("1.2.7.3.CORP") Then
		Items.AcceptForExecution.Visible = False;
		Items.ProcessTasksContextMenuAcceptForExecution.Visible = False;
	EndIf;
	// Canceling the acceptance of tasks for execution.
	If Not IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("2.1.18.1.CORP") Then
		Items.CancelAcceptForExecution.Visible = False;
		Items.ProcessTasksContextMenuCancelAcceptForExecution.Visible = False;
	EndIf;
	
	SetTaskAppearance(ConditionalAppearance);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Recording_1CDocumentManagementTask" And Source = ThisObject Then
		RefreshTasksListOnServer();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTasks

&AtClient
Procedure ProcessTasksOnActivateRow(Item)
	
	If NumberOfActivatedLine <> Item.CurrentRow Then
		
		NumberOfActivatedLine = Item.CurrentRow;
		TaskLine = Items.ProcessTasks.CurrentData;
		If TaskLine = Undefined Or TaskLine.Group Or TaskLine.Executed Then
			Items.AcceptForExecution.Enabled = False;
			Items.ProcessTasksContextMenuAcceptForExecution.Enabled = False;
			Items.CancelAcceptForExecution.Enabled = False;
			Items.ProcessTasksContextMenuCancelAcceptForExecution.Enabled = False;
		Else
			Items.AcceptForExecution.Enabled = Not TaskLine.AcceptedForExecution;
			Items.ProcessTasksContextMenuAcceptForExecution.Enabled = Not TaskLine.AcceptedForExecution;
			Items.CancelAcceptForExecution.Enabled = TaskLine.AcceptedForExecution;
			Items.ProcessTasksContextMenuCancelAcceptForExecution.Enabled = TaskLine.AcceptedForExecution;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure TasksSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	If Items.ProcessTasks.CurrentData <> Undefined Then
		If Not Items.ProcessTasks.CurrentData.Group Then
			FormParameters = New Structure;
			FormParameters.Insert("ID", Items.ProcessTasks.CurrentData.TaskID);
			FormParameters.Insert("type", Items.ProcessTasks.CurrentData.TaskType);
			OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.Task",
				FormParameters, ThisObject, Items.ProcessTasks.CurrentData.TaskID);
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

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Refresh(Command)
	
	RefreshTasksListOnServer();
	
EndProcedure

&AtClient
Procedure OpenTask(Command)
	
	If Items.ProcessTasks.CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Not Items.ProcessTasks.CurrentData.Group Then
		FormParameters = New Structure;
		FormParameters.Insert("ID", Items.ProcessTasks.CurrentData.TaskID);
		FormParameters.Insert("type", Items.ProcessTasks.CurrentData.TaskType);
		FormParameters.Insert("ProcessType",Items.ProcessTasks.CurrentData.Process_Type);
		FormParameters.Insert("RoutePoint",Items.ProcessTasks.CurrentData.RoutePoint);
		OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.Task",
			FormParameters, ThisObject, Items.ProcessTasks.CurrentData.TaskID);
	EndIf;
	
EndProcedure

&AtClient
Procedure AcceptForExecution(Command)
	
	AcceptTasksForExecution();
	
EndProcedure

&AtClient
Procedure CancelAcceptForExecution(Command)
	
	CancelAcceptTasksForExecution();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetCurrentRow(TaskID)
	
	If ValueIsFilled(TaskID) Then
		If Items.ProcessTasks.Representation = TableRepresentation.List Then
			TaskLines_ = ProcessTasks.GetItems();
			For Each TaskLine In TaskLines_ Do
				If TaskLine.TaskID = TaskID Then
					Items.ProcessTasks.CurrentRow = TaskLine.GetID();
					Break;
				EndIf;
			EndDo;
		Else
			For Each TreeGroup In ProcessTasks.GetItems() Do
				TaskLines_ = TreeGroup.GetItems();
				For Each TaskLine In TaskLines_ Do
					If TaskLine.TaskID = TaskID Then
						Items.ProcessTasks.CurrentRow = TaskLine.GetID();
						Break;
					EndIf;
				EndDo;
			EndDo;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure AcceptTasksForExecution()
	
	RowsArray = Items.ProcessTasks.SelectedRows;
	If RowsArray.Count() <> 0 Then
		TaskArray = New Array;
		For Each Item In RowsArray Do
			If ValueIsFilled(ProcessTasks.FindByID(Item).TaskID) Then
				TaskArray.Add(ProcessTasks.FindByID(Item).TaskID);
			EndIf;
		EndDo;
		Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
		IntegrationWith1CDocumentManagement.AcceptTaskForExecution(Proxy, TaskArray);
		RefreshTasksListOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure CancelAcceptTasksForExecution()
	
	RowsArray = Items.ProcessTasks.SelectedRows;
	If RowsArray.Count() <> 0 Then
		TaskArray = New Array;
		For Each Item In RowsArray Do
			If ValueIsFilled(ProcessTasks.FindByID(Item).TaskID) Then
				TaskArray.Add(ProcessTasks.FindByID(Item).TaskID);
			EndIf;
		EndDo;
		Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
		IntegrationWith1CDocumentManagement.CancelAcceptTasksForExecution(Proxy, TaskArray);
		RefreshTasksListOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure SetTaskAppearance(Var_ConditionalAppearance)
	
	// setting up registration for overdue tasks
	ConditionalAppearanceItem = Var_ConditionalAppearance.Items.Add();
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("ProcessTasks.TaskDueDate");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Filled;
	DataFilterItem.Use = True;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("ProcessTasks.TaskDueDate");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Less;
	DataFilterItem.RightValue = EndOfDay(CurrentSessionDate());
	DataFilterItem.Use = True;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("ProcessTasks.Executed");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = False;
	DataFilterItem.Use = True;
	
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("TextColor");
	AppearanceColorItem.Value =  Metadata.StyleItems.OverdueDataColor.Value;
	AppearanceColorItem.Use = True;
	
	AppearanceAreaItem = ConditionalAppearanceItem.Fields.Items.Add();
	AppearanceAreaItem.Field = New DataCompositionField("ProcessTasksDueDate");
	
EndProcedure

&AtServerNoContext
Function GetProcessTasks(Proxy, Completed, BusinessProcessType, BusinessProcessID)
	
	ListOfConditions = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListQuery");
	FilterConditions = ListOfConditions.conditions; // XDTOList
	
	Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
	Condition.property = "byUser";
	Condition.value = False;
	FilterConditions.Add(Condition);
	
	Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
	Condition.property = "withExecuted";
	Condition.value = True;
	FilterConditions.Add(Condition);
	
	Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
	Condition.property = "businessProcess";
	Condition.value = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		BusinessProcessID,
		BusinessProcessType);
	FilterConditions.Add(Condition);
	
	Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
	Condition.property = "typed";
	Condition.value = True;
	FilterConditions.Add(Condition);
	
	Response = IntegrationWith1CDocumentManagementCore.FindListOfObjects(
		Proxy,
		"DMBusinessProcessTask",
		ListOfConditions);
	
	Return Response.items;
	
EndFunction

&AtServer
Procedure FillInTheTaskList(XDTOTasks)
	
	CurrentTask = Items.ProcessTasks.CurrentRow;
	If CurrentTask <> Undefined Then
		CurrentTask = ProcessTasks.FindByID(CurrentTask).TaskID;
	EndIf;
	
	Tree = FormAttributeToValue("ProcessTasks"); // ValueTree
	
	TaskTable_ = New ValueTable;
	For Each Column In Tree.Columns Do
		TaskTable_.Columns.Add(Column.Name, Column.ValueType);
	EndDo;
	
	For Each XDTOTask In XDTOTasks Do
		TaskLine = TaskTable_.Add();
		FillInIssueLine(TaskLine, XDTOTask.object);
	EndDo;
	
	Tree.Rows.Clear();
	
	If ValueIsFilled(GroupingMode) Then
		Items.ProcessTasks.Representation = TableRepresentation.Tree;
		DimensionsTable = TaskTable_.Copy();
		DimensionsTable.GroupBy(GroupingMode);
		For Each DimensionString In DimensionsTable Do
			TreeRow = Tree.Rows.Add();
			TreeRow.Task = DimensionString[GroupingMode];
			TreeRow.TaskImage = 2;
			TreeRow.Importance = 1;
			TreeRow.Group = True;
			GroupLines = TaskTable_.FindRows(
				New Structure(GroupingMode,DimensionString[GroupingMode]));
			For Each String In GroupLines Do
				ElementString = TreeRow.Rows.Add();
				FillPropertyValues(ElementString,String);
			EndDo;
		EndDo;
	Else
		Items.ProcessTasks.Representation = TableRepresentation.List;
		For Each String In TaskTable_ Do
			TreeRow = Tree.Rows.Add();
			FillPropertyValues(TreeRow,String);
		EndDo;
	EndIf;
	
	ValueToFormAttribute(Tree,"ProcessTasks");
	TaskTableLink = PutToTempStorage(TaskTable_,UUID);
	SetCurrentRow(CurrentTask);
	
EndProcedure

&AtServer
Procedure SetVisibilityOfTaskColumns()
	
	If BusinessProcessType = "DMBusinessProcessApproval"
		Or BusinessProcessType = "DMBusinessProcessConfirmation" Then
		Items.ProcessTasksTask.Visible = True;
		Items.ProcessTasksCycle.Visible = True;
		Items.ProcessTasksResult.Visible = True;
		Items.ProcessTasksReview.Visible = True;
		Items.ProcessTasksPerformer.Visible = True;
		
	ElsIf BusinessProcessType = "DMBusinessProcessPerformance"
		Or BusinessProcessType = "DMBusinessProcessOrder"
		Or BusinessProcessType = "DMBusinessProcessRegistration"
		Or BusinessProcessType = "DMBusinessProcessOutgoingDocumentProcessing"
		Or BusinessProcessType = "DMBusinessProcessInternalDocumentProcessing"
		Or BusinessProcessType = "DMBusinessProcessIncomingDocumentProcessing" Then
		Items.ProcessTasksTask.Visible = True;
		Items.ProcessTasksExecutorOnRight.Visible = True;
		Items.ProcessTasksExecuted.Visible = True;
		
	ElsIf BusinessProcessType = "DMBusinessProcessAcquaintance" Then
		Items.ProcessTasksPerformer.Visible = True;
		Items.ProcessTasksFamiliarized.Visible = True;
		
	ElsIf BusinessProcessType = "DMBusinessProcessConsideration" Then
		Items.ProcessTasksPerformer.Visible = True;
		Items.ProcessTasksTask.Visible = True;
		Items.ProcessTasksExecuted.Visible = True;
		
	ElsIf BusinessProcessType = "DMBusinessProcessIssuesSolution" Then
		Items.ProcessTasksTask.Visible = True;
		Items.ProcessTasksExecutorOnRight.Visible = True;
		Items.ProcessTasksReview.Visible = True;
		
	ElsIf BusinessProcessType = "DMBusinessProcessInvitation" Then
		Items.ProcessTasksPerformer.Visible = True;
		Items.ProcessTasksCycle.Visible = True;
		Items.ProcessTasksTask.Visible = True;
		Items.ProcessTasksResult.Visible = True;
		Items.ProcessTasksComment.Visible = True;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInIssueLine(TaskLine,XDTOTask)
	
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
	TaskLine.Number = XDTOTask.number;
	TaskLine.Date = XDTOTask.beginDate;
	TaskLine.Review = XDTOTask.executionComment;
	TaskLine.Comment = XDTOTask.executionComment;
	TaskLine.ExecutionDate = XDTOTask.endDate;
	FillInObjectDetails(TaskLine,XDTOTask.performer.user,"Performer");
	FillInObjectDetails(TaskLine,XDTOTask.parentBusinessProcess,"Process_");
	FillInObjectDetails(TaskLine,XDTOTask.target,"SubjectOf");
	FillInObjectDetails(TaskLine,XDTOTask,"Task");
	
	// Fill in the task lines by the type of business process
	If BusinessProcessType = "DMBusinessProcessApproval" Then
		TaskLine.Cycle = XDTOTask.iterationNumber;
		If XDTOTask.objectID.type = "DMBusinessProcessApprovalTaskApproval" Then
			FillInObjectDetails(TaskLine,XDTOTask.approvalResult,"Result");
		EndIf;
	ElsIf BusinessProcessType = "DMBusinessProcessConfirmation" Then
		TaskLine.Cycle = XDTOTask.iterationNumber;
		If XDTOTask.objectID.type = "DMBusinessProcessConfirmationTaskConfirmation" Then
			FillInObjectDetails(TaskLine,XDTOTask.confirmationResult,"Result");
		EndIf;
	ElsIf BusinessProcessType = "DMBusinessProcessInvitation" Then
		TaskLine.Cycle = XDTOTask.iterationNumber;
		If XDTOTask.objectID.type = "DMBusinessProcessInvitationTaskInvitation" Then
			FillInObjectDetails(TaskLine,XDTOTask.invitationResult,"Result");
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure RefreshTasksListOnServer()
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	If ValueIsFilled(BusinessProcessID) Then
		XDTOProcessTasks = GetProcessTasks(Proxy, Completed, BusinessProcessType, BusinessProcessID);
		FillInTheTaskList(XDTOProcessTasks);
	EndIf;
	
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